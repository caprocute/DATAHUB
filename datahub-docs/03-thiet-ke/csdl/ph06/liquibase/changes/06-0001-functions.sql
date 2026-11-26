--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag; số phiên bản bản ghi vàng).';
--rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_touch();

--changeset ph06:ph06-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, nội dung đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_immutable();

--changeset ph06:ph06-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, lịch sử)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (golden_history, attribute_lineage, access_log, processing_log). Dọn bằng DETACH, DROP phân vùng dưới ph06_owner.';
--rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_append_only();

--changeset ph06:ph06-0013-fn-frozen splitStatements:false
-- Phiên bản ACTIVE bất biến (BR-06-017): chặn sửa cột nội dung (đối số) khi dòng cũ đang ACTIVE hoặc SUPERSEDED.
CREATE OR REPLACE FUNCTION ph06_mdm.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  IF OLD.status IN ('ACTIVE', 'SUPERSEDED') THEN
    FOREACH c IN ARRAY TG_ARGV LOOP
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Phiên bản % không sửa được cột % (BR-06-017)', OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_frozen() IS 'Phiên bản mô hình, bộ quy tắc đã ACTIVE hoặc SUPERSEDED không đổi nội dung (BR-06-017); thay đổi cần phiên bản mới.';
--rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_frozen();

--changeset ph06:ph06-0014-fn-child-frozen splitStatements:false
-- Bảng con của phiên bản (thuộc tính, khóa định danh, quy tắc con): chỉ ghi khi phiên bản cha là DRAFT, TESTING hoặc REJECTED.
-- Tham số: tên bảng cha, tên cột trạng thái cha mặc định 'status'.
CREATE OR REPLACE FUNCTION ph06_mdm.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent text := TG_ARGV[0];
  st text;
  tn text;
  dc text;
  vn integer;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; dc := OLD.domain_code; vn := OLD.version_no;
  ELSE
    tn := NEW.tenant_id; dc := NEW.domain_code; vn := NEW.version_no;
  END IF;
  EXECUTE format('SELECT status FROM ph06_mdm.%I WHERE tenant_id = $1 AND domain_code = $2 AND version_no = $3', parent)
    INTO st USING tn, dc, vn;
  IF st IN ('ACTIVE', 'SUPERSEDED', 'PENDING_APPROVAL') THEN
    RAISE EXCEPTION 'Phiên bản % của %: không sửa nội dung con khi % (BR-06-017)', vn, parent, st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản cha đã gửi duyệt, ACTIVE hoặc SUPERSEDED (BR-06-017).';
--rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_child_frozen();

--changeset ph06:ph06-0015-fn-rls splitStatements:false
-- Một mẫu cho mọi bảng nghiệp vụ: chỉ thấy, ghi dòng của tenant phiên; tenant_id đúng dạng Tnn (không có dòng COMMON, mỗi tenant tự cài gói domain nền).
CREATE OR REPLACE PROCEDURE ph06_mdm.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003).';
--rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_enable_rls(regclass);

--changeset ph06:ph06-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph06_mdm.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho candidate_record, match_result, golden_history, attribute_lineage, access_log, processing_log. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph06_owner.';
--rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_ensure_partitions(regclass, date, integer);

--changeset ph06:ph06-0017-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (BP-08): tham số mặc định FRS 8.2, chính sách lưu giữ, lịch job. Domain nền cài qua FR-06-007 (gói do ứng dụng quản).
CREATE OR REPLACE PROCEDURE ph06_mdm.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph06_mdm.tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by)
  SELECT md5('ph06-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('06.queue.sla-days', '7'), ('06.queue.max-open', '500'), ('06.queue.escalate-after-days', '14'), ('06.queue.hold-minutes', '30'),
               ('06.match.auto-disable-on-fail', 'true'), ('06.batch.safety-ratio', '0.05'), ('06.undo.window-days', '90'),
               ('06.export.max-rows', '100000'), ('06.access.bulk-threshold', '100'), ('06.ingest.rate-per-source', '6000'),
               ('06.sync.pause-ratio', '0.05'), ('06.sync.up-attributes', '[]'), ('06.dsr.sla-days', '10'),
               ('06.mask.reveal-seconds', '60'), ('06.ingest.max-file-mb', '50'), ('06.ingest.max-rows', '200000'), ('06.batch.max-hours', '4'), ('06.match.timeout-ms', '800'), ('06.sync.reconcile-batch-size', '1000'), ('06.xref.batch-max', '500'), ('06.queue.reopen-hours', '24')) AS s(k, v)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph06_mdm.retention_policy (id, tenant_id, object_type, retention_days, action, created_by, updated_by)
  SELECT md5('ph06-retention:' || p_tenant || ':' || r.t)::uuid, p_tenant, r.t, r.d, r.a, 'system:seed', 'system:seed'
  FROM (VALUES ('candidate_record', 365, 'ANONYMIZE'), ('match_result', 730, 'DELETE'), ('match_staging', 7, 'DELETE'),
               ('golden_history', 1825, 'ARCHIVE_COLD'), ('attribute_lineage', 1825, 'ARCHIVE_COLD'), ('access_log', 365, 'ARCHIVE_COLD'),
               ('processing_log', 90, 'DELETE'), ('export_request', 90, 'DELETE'), ('subject_request', 1825, 'ARCHIVE_COLD'),
               ('steward_item', 730, 'ARCHIVE_COLD')) AS r(t, d, a)
  ON CONFLICT (tenant_id, object_type) DO NOTHING;
  INSERT INTO ph06_mdm.job_schedule (id, tenant_id, job_type, cron, enabled, created_by, updated_by)
  SELECT md5('ph06-schedule:' || p_tenant || ':' || j.t)::uuid, p_tenant, j.t, j.c, j.e, 'system:seed', 'system:seed'
  FROM (VALUES ('BATCH_MATCH', '0 0 2 * * *', true), ('ACCURACY_EVAL', '0 0 3 1 * *', true), ('NATIONAL_SYNC_DOWN', '0 */15 * * * *', true),
               ('NATIONAL_RECONCILE', '0 0 1 * * 0', true), ('RETENTION_PURGE', '0 30 3 * * *', true)) AS j(t, c, e)
  ON CONFLICT (tenant_id, job_type) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): tham số 06.* mặc định, 10 chính sách lưu giữ, 5 lịch job. Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_seed_tenant(text);
