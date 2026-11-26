-- =============================================================================
-- D03-03-PH17 · DDL schema ph17_assist, PH-17 Trợ lý AI và quản trị AI
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng và Phụ lục A của D02-03-PH17; sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d ph17_test -f ph17_assist.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH17 phụ lục A. Không lưu bí mật nhà cung cấp (chỉ secret_ref tới OpenBao, BR-17-011),
-- không lưu nội dung chưa che (BR-17-073), vết lời gọi không có nội dung (BR-17-022). pgvector có điều kiện: CI chạy postgres:16
-- không có extension nên cột embedding là real[]; môi trường thật (pg-core, pgvector 0.8) tự đổi sang vector(1024) và HNSW.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 17-0000-bootstrap.sql
-- @changeset ph17-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_owner') THEN
    CREATE ROLE ph17_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_app') THEN
    CREATE ROLE ph17_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_platform') THEN
    CREATE ROLE ph17_platform NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_infer') THEN
    CREATE ROLE ph17_infer NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_job') THEN
    CREATE ROLE ph17_job NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_readonly') THEN
    CREATE ROLE ph17_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  GRANT ph17_app TO ph17_job;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph17-0001-schema splitStatements:false context:bootstrap
-- pgvector có điều kiện: CI (postgres:16) không có extension; môi trường thật có (ADR-170, pgvector 0.8).
DO $ext$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'vector') THEN
    CREATE EXTENSION IF NOT EXISTS vector;
  ELSE
    RAISE NOTICE 'Không có pgvector: cột embedding giữ real[] (chỉ để CI).';
  END IF;
END
$ext$;
CREATE SCHEMA IF NOT EXISTS ph17_assist AUTHORIZATION ph17_owner;
COMMENT ON SCHEMA ph17_assist IS 'PH-17 Trợ lý AI và quản trị AI (dh-assist, package vn.datahub.assist): chính sách bật tắt theo tenant, sổ mô hình, cổng mô hình, kho tri thức và chỉ mục vector, hội thoại đã che, công cụ chỉ đọc, bộ lọc, đánh giá và ca đỏ, nhật ký, bằng chứng tuân thủ. Không lưu bí mật nhà cung cấp, không lưu nội dung chưa che.';
GRANT USAGE ON SCHEMA ph17_assist TO ph17_app, ph17_platform, ph17_infer, ph17_job, ph17_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph17_assist CASCADE;

SET ROLE ph17_owner;

-- @changeset ph17-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 17-0001-functions.sql
-- @changeset ph17-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag, BR-17-087).';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_touch();

-- @changeset ph17-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph17_assist.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, bằng chứng đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_immutable();

-- @changeset ph17-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, vết)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (invocation_log, model_health_probe, notice_acceptance, knowledge_deletion). Dọn bằng DETACH, DROP phân vùng dưới ph17_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_append_only();

-- @changeset ph17-0013-fn-frozen splitStatements:false
-- Phiên bản ở trạng thái đã chốt không đổi nội dung: đối số đầu là danh sách trạng thái (ngăn cách bằng dấu phẩy), các đối số sau là tên cột.
CREATE OR REPLACE FUNCTION ph17_assist.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text[] := string_to_array(TG_ARGV[0], ',');
  i integer;
BEGIN
  IF (to_jsonb(OLD) ->> 'status') = ANY (st) THEN
    FOR i IN 1 .. array_length(TG_ARGV, 1) - 1 LOOP
      IF (to_jsonb(NEW) -> TG_ARGV[i]) IS DISTINCT FROM (to_jsonb(OLD) -> TG_ARGV[i]) THEN
        RAISE EXCEPTION 'Đối tượng ở trạng thái % không sửa được cột % (tạo phiên bản mới)', OLD.status, TG_ARGV[i] USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_frozen() IS 'Điều khoản đã công bố, phiên bản mô hình từ EVALUATING, phiên bản prompt từ PENDING_APPROVAL không đổi nội dung (ERR-17-024, 040).';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_frozen();

-- @changeset ph17-0014-fn-transition splitStatements:false
-- Chuyển trạng thái chỉ theo máy trạng thái của FRS 4.3 đến 4.7: đối số một là tên cột, đối số hai là danh sách 'TỪ>ĐẾN' ngăn cách bằng dấu phẩy.
CREATE OR REPLACE FUNCTION ph17_assist.tg_transition() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  o text := to_jsonb(OLD) ->> TG_ARGV[0];
  n text := to_jsonb(NEW) ->> TG_ARGV[0];
BEGIN
  IF o IS DISTINCT FROM n AND NOT (COALESCE(o, '') || '>' || COALESCE(n, '')) = ANY (string_to_array(TG_ARGV[1], ',')) THEN
    RAISE EXCEPTION 'ERR-17-006: % không chuyển được từ % sang % (cột %)', TG_TABLE_NAME, o, n, TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_transition() IS 'Cưỡng chế máy trạng thái: tenant_policy, model_version, model_provider, model_route, knowledge_document, suggestion, prompt_version, policy_change và các bảng có vòng đời.';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_transition();

-- @changeset ph17-0015-fn-helpers splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.fn_ctx_ok(p_ctx jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT jsonb_typeof(p_ctx) = 'object'
     AND NOT EXISTS (SELECT 1 FROM jsonb_object_keys(p_ctx) k WHERE k NOT IN ('route', 'objectId', 'errorCode', 'tab'))
$f$;
COMMENT ON FUNCTION ph17_assist.fn_ctx_ok(jsonb) IS 'Ngữ cảnh màn hình chỉ gồm route, objectId, errorCode, tab; không giá trị dữ liệu (BR-17-032).';

CREATE OR REPLACE FUNCTION ph17_assist.fn_log_grant_ok(p_conv uuid, p_created timestamptz) RETURNS boolean
  LANGUAGE plpgsql STABLE AS $f$
BEGIN
  RETURN EXISTS (SELECT 1 FROM ph17_assist.log_access_grant g
                 WHERE g.tenant_id = current_setting('app.tenant_id', true) AND g.grantee = current_setting('app.user_id', true)
                   AND g.state = 'ACTIVE' AND g.expires_at > now()
                   AND ((g.scope_kind = 'CONVERSATION' AND g.conversation_id = p_conv)
                     OR (g.scope_kind = 'RANGE' AND p_created >= g.range_from AND p_created < g.range_to)));
END
$f$;
COMMENT ON FUNCTION ph17_assist.fn_log_grant_ok(uuid, timestamptz) IS 'Người đang đăng nhập (app.user_id) có phiếu truy cập nhật ký còn hiệu lực cho hội thoại hoặc khoảng thời gian (BR-17-074); mở khóa RLS theo người dùng của conversation, message.';

CREATE OR REPLACE FUNCTION ph17_assist.fn_setting_num(p_tenant text, p_key text, p_default numeric) RETURNS numeric
  LANGUAGE plpgsql STABLE AS $f$
DECLARE
  v numeric;
BEGIN
  SELECT (value #>> '{}')::numeric INTO v FROM ph17_assist.tenant_setting WHERE tenant_id = p_tenant AND setting_key = p_key;
  RETURN COALESCE(v, p_default);
END
$f$;
COMMENT ON FUNCTION ph17_assist.fn_setting_num(text, text, numeric) IS 'Đọc tham số số 17.* của tenant từ bản chụp, thiếu thì dùng mặc định (BR-17-078).';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.fn_setting_num(text, text, numeric); DROP FUNCTION IF EXISTS ph17_assist.fn_log_grant_ok(uuid, timestamptz); DROP FUNCTION IF EXISTS ph17_assist.fn_ctx_ok(jsonb);

-- @changeset ph17-0016-fn-rls splitStatements:false
-- Ba mẫu RLS. Đọc: tenant của phiên (và COMMON với bảng dùng chung). Ghi: chỉ dòng của tenant Tnn; dòng COMMON chỉ vai ph17_platform khi phiên app.tenant_id = COMMON.
CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003, BR-17-086).';

CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls_common(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := $w$(tenant_id = current_setting('app.tenant_id', false) OR tenant_id = 'COMMON')$w$;
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
  c text := $w$(tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'COMMON')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_platform ON %s FOR ALL TO ph17_platform USING %s WITH CHECK %s', n, t, c, c);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls_common(regclass) IS 'Như p_enable_rls, thêm đọc dòng COMMON cho mọi tenant và chính sách ghi dòng COMMON riêng cho vai ph17_platform (PA khai báo nhà cung cấp, mô hình, ca đỏ, nguồn dùng chung).';

CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls_user(p_table regclass, p_grant text, p_job_delete text)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
  u text := $w$(user_id = current_setting('app.user_id', true))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING (%s AND (%s OR %s))', n, t, w, u, p_grant);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK (%s AND %s)', n, t, w, u);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING (%s AND %s) WITH CHECK (%s AND %s)', n, t, w, u, w, u);
  EXECUTE format('CREATE POLICY rls_%s_job_select ON %s FOR SELECT TO ph17_job USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_job_delete ON %s FOR DELETE TO ph17_job USING (%s AND (%s))', n, t, w, p_job_delete);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls_user(regclass, text, text) IS 'RLS theo tenant và người dùng (BR-17-033): chỉ chủ dòng đọc, ghi; người có phiếu truy cập còn hiệu lực đọc được; vai ph17_job đọc và xóa dòng hết hạn theo lịch lưu giữ.';
-- @rollback DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls_user(regclass, text, text); DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls_common(regclass); DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls(regclass);

-- @changeset ph17-0017-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph17_assist.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
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
COMMENT ON PROCEDURE ph17_assist.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho invocation_log, model_health_probe. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph17_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph17_assist.p_ensure_partitions(regclass, date, integer);

-- @changeset ph17-0018-fn-release-gate splitStatements:false
-- Cổng phát hành (BR-17-015, 064, 066 đến 068): APPROVED hoặc ACTIVE chỉ khi lượt đánh giá chuẩn đạt, lượt ca đỏ không lọt và bộ ca đỏ có từ 50 ca đang hoạt động.
CREATE OR REPLACE FUNCTION ph17_assist.tg_release_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  ev record;
  rt record;
  n integer;
  min_score numeric;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status OR NEW.status NOT IN ('APPROVED', 'ACTIVE') THEN
    RETURN NEW;
  END IF;
  min_score := ph17_assist.fn_setting_num(NEW.tenant_id, '17.eval.min-score', 0.80);
  SELECT * INTO ev FROM ph17_assist.eval_run
   WHERE id = NEW.eval_run_id AND tenant_id = NEW.tenant_id AND run_kind = 'EVAL' AND subject_id = NEW.id;
  IF NOT FOUND OR ev.status <> 'PASSED' OR ev.cases_total < 30 OR ev.score < min_score THEN
    RAISE EXCEPTION 'ERR-17-072: chưa đạt cổng phát hành, đánh giá chuẩn chưa đạt ngưỡng %', min_score USING ERRCODE = '23514';
  END IF;
  SELECT * INTO rt FROM ph17_assist.eval_run
   WHERE id = NEW.redteam_run_id AND tenant_id = NEW.tenant_id AND run_kind = 'REDTEAM' AND subject_id = NEW.id;
  IF NOT FOUND OR rt.status <> 'PASSED' OR rt.cases_leaked <> 0 OR rt.pass_rate <> 100 THEN
    RAISE EXCEPTION 'ERR-17-073: ca đỏ chưa bị chặn hết nên không phát hành được' USING ERRCODE = '23514';
  END IF;
  SELECT count(*) INTO n FROM ph17_assist.redteam_case WHERE tenant_id IN (NEW.tenant_id, 'COMMON') AND status = 'ACTIVE';
  IF n < 50 THEN
    RAISE EXCEPTION 'ERR-17-075: bộ ca đỏ cần tối thiểu 50 ca đang hoạt động (hiện có %)', n USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_release_gate() IS 'Cổng phát hành của phiên bản mô hình (APPROVED) và phiên bản prompt (ACTIVE).';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_release_gate();

-- @changeset ph17-0019-fn-tenant-model splitStatements:false
-- Bật phiên bản cho tenant (BR-17-004, 017, 018): phiên bản APPROVED, mô hình ngoài cần chính sách cho phép, danh sách trắng và nhà cung cấp ACTIVE; dự phòng cùng loại, đã duyệt, không từ nội bộ sang ngoài.
CREATE OR REPLACE FUNCTION ph17_assist.tg_tenant_model_rules() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_status text; v_kind text; v_pk text; v_pst text;
  f_status text; f_kind text; f_pk text;
BEGIN
  SELECT mv.status, m.model_kind, p.provider_kind, p.status INTO v_status, v_kind, v_pk, v_pst
    FROM ph17_assist.model_version mv JOIN ph17_assist.model m ON m.id = mv.model_id JOIN ph17_assist.model_provider p ON p.id = m.provider_id
   WHERE mv.id = NEW.version_id;
  IF NEW.enabled THEN
    IF v_status IS DISTINCT FROM 'APPROVED' THEN
      RAISE EXCEPTION 'ERR-17-030: phiên bản mô hình chưa được duyệt nên chưa dùng được' USING ERRCODE = '23514';
    END IF;
    IF v_kind <> NEW.model_kind THEN
      RAISE EXCEPTION 'ERR-17-003: model_kind không khớp loại của mô hình' USING ERRCODE = '23514';
    END IF;
    IF v_pk = 'EXTERNAL' THEN
      IF v_pst <> 'ACTIVE' OR NOT EXISTS (SELECT 1 FROM ph17_assist.tenant_policy WHERE tenant_id = NEW.tenant_id AND external_allowed) THEN
        RAISE EXCEPTION 'ERR-17-016: mô hình ngoài chưa được phép (chính sách tenant hoặc nhà cung cấp chưa đủ điều kiện)' USING ERRCODE = '23514';
      END IF;
      IF NOT EXISTS (SELECT 1 FROM ph17_assist.provider_grant g JOIN ph17_assist.model m ON m.provider_id = g.provider_id JOIN ph17_assist.model_version mv ON mv.model_id = m.id
                      WHERE g.tenant_id = NEW.tenant_id AND mv.id = NEW.version_id AND g.revoked_at IS NULL AND (g.effective_to IS NULL OR g.effective_to >= current_date)) THEN
        RAISE EXCEPTION 'ERR-17-017: nhà cung cấp chưa nằm trong danh sách trắng của tenant' USING ERRCODE = '23514';
      END IF;
    END IF;
  END IF;
  IF NEW.fallback_version_id IS NOT NULL THEN
    SELECT mv.status, m.model_kind, p.provider_kind INTO f_status, f_kind, f_pk
      FROM ph17_assist.model_version mv JOIN ph17_assist.model m ON m.id = mv.model_id JOIN ph17_assist.model_provider p ON p.id = m.provider_id
     WHERE mv.id = NEW.fallback_version_id;
    IF f_status IS DISTINCT FROM 'APPROVED' OR f_kind <> v_kind OR (v_pk = 'INTERNAL' AND f_pk = 'EXTERNAL') THEN
      RAISE EXCEPTION 'ERR-17-034: dự phòng phải cùng loại, đã duyệt và không chuyển từ nội bộ sang ngoài' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_tenant_model_rules() IS 'Quy tắc bật mô hình cho tenant và chọn dự phòng.';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_tenant_model_rules();

-- @changeset ph17-0020-fn-chunk splitStatements:false
-- Đoạn chỉ vào chỉ mục khi tài liệu mức PUBLIC hoặc INTERNAL (BR-17-026); tài liệu bị bỏ, xóa hoặc đổi sang mức cao hơn thì xóa vật lý hết đoạn trong cùng giao dịch (BR-17-029).
CREATE OR REPLACE FUNCTION ph17_assist.tg_chunk_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  d_class text; d_status text;
BEGIN
  SELECT class_level, index_status INTO d_class, d_status FROM ph17_assist.knowledge_document WHERE tenant_id = NEW.tenant_id AND id = NEW.document_id;
  IF d_class IS NULL OR d_class NOT IN ('PUBLIC', 'INTERNAL') OR d_status IN ('DELETED', 'SKIPPED_CLASS') THEN
    RAISE EXCEPTION 'ERR-17-043: tài liệu mức % không được lập chỉ mục', COALESCE(d_class, 'chưa xác định') USING ERRCODE = '23514';
  END IF;
  IF NEW.class_level <> d_class THEN
    RAISE EXCEPTION 'ERR-17-043: class_level của đoạn phải bằng mức hiện hành của tài liệu (%)', d_class USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;

CREATE OR REPLACE FUNCTION ph17_assist.tg_doc_purge_chunks() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  n integer;
BEGIN
  IF NEW.index_status IN ('DELETED', 'SKIPPED_CLASS')
     OR (NEW.class_level IS DISTINCT FROM OLD.class_level AND (NEW.class_level IS NULL OR NEW.class_level NOT IN ('PUBLIC', 'INTERNAL'))) THEN
    DELETE FROM ph17_assist.knowledge_chunk WHERE tenant_id = OLD.tenant_id AND document_id = OLD.id;
    GET DIAGNOSTICS n = ROW_COUNT;
    NEW.chunk_count := 0;
    IF n > 0 THEN
      INSERT INTO ph17_assist.knowledge_deletion (id, tenant_id, source_id, document_id, reason, chunks_deleted, trigger_ref, created_by, updated_by)
      VALUES (gen_random_uuid(), OLD.tenant_id, OLD.source_id, OLD.id, COALESCE(NEW.delete_reason, 'CLASS_CHANGED'), n, 'db-trigger', NEW.updated_by, NEW.updated_by);
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_doc_purge_chunks() IS 'Xóa lan truyền ở mức CSDL: tài liệu DELETED, SKIPPED_CLASS hoặc mức không còn PUBLIC, INTERNAL thì không còn đoạn nào.';
-- @rollback DROP FUNCTION IF EXISTS ph17_assist.tg_doc_purge_chunks(); DROP FUNCTION IF EXISTS ph17_assist.tg_chunk_gate();

-- @changeset ph17-0021-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20): chính sách DISABLED, năng lực, công cụ, bộ lọc dựng sẵn, danh sách trắng liên kết, tham số 17.*, câu hỏi mẫu. Chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph17_assist.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph17_assist.tenant_policy (id, tenant_id, created_by, updated_by) VALUES (md5('ph17-policy:' || p_tenant)::uuid, p_tenant, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id) DO NOTHING;
  INSERT INTO ph17_assist.capability_policy (id, tenant_id, capability, role_group, enabled, created_by, updated_by)
  SELECT md5('ph17-cap:' || p_tenant || ':' || c)::uuid, p_tenant, c, 'ALL_READERS', false, 'system:seed', 'system:seed' FROM unnest(ARRAY['SEARCH', 'MAPPING', 'EXPLAIN']) c
  ON CONFLICT (tenant_id, capability, role_group) DO NOTHING;
  INSERT INTO ph17_assist.tool_definition (id, tenant_id, tool_code, name, target_module, target_ref, scope, capabilities, created_by, updated_by)
  SELECT md5('ph17-tool:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.m, s.r, s.s, s.k::varchar[], 'system:seed', 'system:seed'
  FROM (VALUES ('SEARCH_API', 'Tìm mô tả API trong danh mục dịch vụ', 'PH02', 'catalog.search-apis', 'catalog:read', '{SEARCH}'), ('LOOKUP_CATALOG', 'Tra danh mục dùng chung', 'PH07', 'rdm.lookup-catalog', 'rdm:read', '{SEARCH,MAPPING}'), ('VIEW_FLOW', 'Xem mô tả luồng tích hợp', 'PH04', 'integration.get-flow', 'integration:read', '{SEARCH,EXPLAIN}'), ('VIEW_MAPPING_SCHEMA', 'Xem lược đồ ánh xạ của luồng', 'PH04', 'integration.get-mapping-schema', 'integration:read', '{MAPPING}'), ('VIEW_TOPIC', 'Xem mô tả topic sự kiện đã công bố', 'PH10', 'event.get-topic', 'event:read', '{SEARCH}'), ('FETCH_LOGS', 'Lấy log theo phạm vi quyền người dùng', 'PH13', 'observability.query-logs', 'observability:read', '{EXPLAIN}'), ('FETCH_TRACE', 'Lấy vết theo trace_id', 'PH13', 'observability.get-trace', 'observability:read', '{EXPLAIN}'), ('VIEW_DLQ_MESSAGE', 'Xem bản tin hàng đợi lỗi', 'PH18', 'ops.get-dlq-message', 'ops:read', '{EXPLAIN}'), ('GET_FIELD_CLASS', 'Tra phân loại trường dữ liệu', 'PH09', 'privacy.get-field-classification', 'privacy:read', '{MAPPING,EXPLAIN}')) AS s(c, n, m, r, s, k)
  ON CONFLICT (tenant_id, tool_code) DO NOTHING;
  INSERT INTO ph17_assist.guardrail_rule (id, tenant_id, rule_code, guardrail_kind, action, category, pattern_kind, pattern, description, builtin, created_by, updated_by)
  SELECT md5('ph17-guard:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.k, s.a, s.g, s.t, s.p, s.d, true, 'system:seed', 'system:seed'
  FROM (VALUES ('GR-IN-INJECT-001', 'INPUT', 'BLOCK', 'PROMPT_INJECTION', 'DETECTOR', 'injection-classifier', 'Bộ phân loại dấu hiệu tiêm lệnh và đòi bỏ chỉ dẫn hệ thống'), ('GR-IN-FORBID-001', 'INPUT', 'BLOCK', 'FORBIDDEN', 'KEYWORD', 'danh-sach-noi-dung-cam', 'Danh sách nội dung cấm theo chính sách tỉnh'), ('GR-IN-PII-ID12', 'INPUT', 'MASK', 'PII', 'REGEX', '\b[0-9]{12}\b', 'Che số định danh 12 chữ số người dùng tự dán'), ('GR-IN-PII-PHONE', 'INPUT', 'MASK', 'PII', 'REGEX', '(\+84|0)[0-9]{9}\b', 'Che số điện thoại Việt Nam'), ('GR-IN-PII-SENS', 'INPUT', 'BLOCK', 'FORBIDDEN', 'DETECTOR', 'sensitive-pii', 'Từ chối khi có DLCN nhạy cảm (ERR-17-066)'), ('GR-OUT-PII-ID12', 'OUTPUT', 'MASK', 'PII', 'REGEX', '\b[0-9]{12}\b', 'Che mẫu số định danh ở đầu ra'), ('GR-OUT-SECRET-PEM', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', 'BEGIN [A-Z ]*PRIVATE KEY', 'Chặn dạng khóa riêng'), ('GR-OUT-SECRET-BEARER', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', '(?i)bearer\s+[A-Za-z0-9._~+/=-]{20,}', 'Chặn chuỗi mang tiền tố Bearer'), ('GR-OUT-SECRET-CONN', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', '(?i)(jdbc|postgres(ql)?|mongodb)://[^\s]*:[^\s@]*@', 'Chặn chuỗi kết nối có mật khẩu'), ('GR-OUT-LINK-EXT', 'OUTPUT', 'MASK', 'LINK', 'REGEX', 'https?://', 'Bỏ liên kết ngoài danh sách trắng route nội bộ (BR-17-037)')) AS s(c, k, a, g, t, p, d)
  ON CONFLICT (tenant_id, rule_code) DO NOTHING;
  INSERT INTO ph17_assist.link_allowlist (id, tenant_id, route_prefix, note, created_by, updated_by) VALUES (md5('ph17-link:' || p_tenant)::uuid, p_tenant, '/', 'Mọi route nội bộ của cổng Datahub', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, route_prefix) DO NOTHING;
  INSERT INTO ph17_assist.tenant_setting (id, tenant_id, setting_key, value, floor_value, ceiling_value, four_eyes, created_by, updated_by)
  SELECT md5('ph17-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, s.lo::jsonb, s.hi::jsonb, s.f, 'system:seed', 'system:seed'
  FROM (VALUES ('17.enabled', 'false', NULL::text, NULL::text, true), ('17.feature.search', 'false', NULL::text, NULL::text, false), ('17.feature.mapping', 'false', NULL::text, NULL::text, false), ('17.feature.explain', 'false', NULL::text, NULL::text, false), ('17.feature.roles', '"ALL_READERS"', NULL::text, NULL::text, false), ('17.model.external-allowed', 'false', NULL::text, NULL::text, true), ('17.model.default-chat', '""', NULL::text, NULL::text, false), ('17.model.default-embed', '""', NULL::text, NULL::text, false), ('17.model.default-rerank', '""', NULL::text, NULL::text, false), ('17.model.fallback-enabled', 'true', NULL::text, NULL::text, false), ('17.model.timeout-seconds', '60', '10', '120', false), ('17.model.first-token-timeout-seconds', '10', '3', '30', false), ('17.quota.user-turns-per-day', '200', '10', '1000', false), ('17.quota.user-turns-per-minute', '10', '2', '30', false), ('17.quota.tenant-tokens-per-day', '2000000', '100000', '50000000', false), ('17.quota.warn-percent', '80', '50', '95', false), ('17.quota.du-calls-per-minute', '120', '10', '1000', false), ('17.input.max-chars', '4000', '500', '8000', false), ('17.output.max-tokens', '1500', '200', '4000', false), ('17.context.max-messages', '20', '4', '50', false), ('17.conversation.max-per-user', '200', '20', '1000', false), ('17.rag.top-k', '8', '3', '20', false), ('17.rag.min-score', '0.55', '0.3', '0.9', false), ('17.rag.hybrid-weight-vector', '0.6', '0', '1', false), ('17.rag.chunk-tokens', '400', '150', '800', false), ('17.rag.chunk-overlap', '50', '0', '200', false), ('17.index.full-cron', '"0 3 * * 0"', NULL::text, NULL::text, false), ('17.index.stale-days', '7', '1', '30', false), ('17.index.pause-purge-days', '30', '7', '180', false), ('17.upload.max-mb', '20', '1', '50', false), ('17.tool.max-calls-per-turn', '5', '1', '10', false), ('17.tool.timeout-seconds', '10', '3', '30', false), ('17.tool.max-depth', '3', '1', '5', false), ('17.mapping.sample-rows', '3', '0', '10', false), ('17.suggestion.ttl-hours', '24', '1', '72', false), ('17.explain.log-lines-max', '200', '20', '500', false), ('17.explain.trace-window-minutes', '60', '5', '240', false), ('17.log.retention-days', '90', '90', '365', true), ('17.log.access-reason-min-chars', '20', '20', '200', false), ('17.log.export-max-days', '31', '1', '92', false), ('17.breaker.error-rate', '50', '20', '90', false), ('17.breaker.open-seconds', '30', '10', '300', false), ('17.eval.min-score', '0.8', '0.5', '0.99', false), ('17.eval.regression-tolerance', '0.03', '0', '0.1', false), ('17.redteam.min-pass-rate', '100', '100', '100', false), ('17.feedback.sla-days', '5', '1', '30', false), ('17.quality.alert-drop-percent', '10', '5', '50', false), ('17.notice.reaccept-days', '365', '30', '730', false), ('17.report.cost-per-1k-tokens', '0', '0', '1000', false)) AS s(k, v, lo, hi, f)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph17_assist.suggested_question (id, tenant_id, question_text, route_pattern, capability, sort_no, created_by, updated_by)
  SELECT md5('ph17-q:' || p_tenant || ':' || s.q)::uuid, p_tenant, s.q, s.r, s.c, 100, 'system:seed', 'system:seed'
  FROM (VALUES ('Tìm API tra cứu danh mục hành chính', '/dich-vu', 'SEARCH'), ('Dịch vụ nào cung cấp dữ liệu dân cư', '/dich-vu', 'SEARCH'), ('Gợi ý ánh xạ trường nguồn sang đích', '/tich-hop/*', 'MAPPING'), ('Gợi ý ánh xạ mã địa phương sang danh mục chuẩn', '/danh-muc/*', 'MAPPING'), ('Giải thích mã lỗi đang hiển thị', '/*', 'EXPLAIN'), ('Vì sao bản tin này vào hàng đợi lỗi', '/van-hanh/*', 'EXPLAIN')) AS s(q, r, c)
  ON CONFLICT DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant: tenant_policy DISABLED, 3 năng lực, 9 công cụ chỉ đọc, 10 quy tắc lọc, 1 route trắng, 49 tham số 17.*, 6 câu hỏi mẫu.';
-- @rollback DROP PROCEDURE IF EXISTS ph17_assist.p_seed_tenant(text);


-- @file 17-0010-core.sql
-- @changeset ph17-0100-file-object
CREATE TABLE ph17_assist.file_object (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  bucket       varchar(64) NOT NULL,
  object_key   text NOT NULL,
  file_name    varchar(255) NOT NULL,
  content_type varchar(127) NOT NULL,
  size_bytes   bigint NOT NULL,
  sha256       char(64) NOT NULL,
  scan_status  varchar(16) NOT NULL DEFAULT 'PENDING',
  data_class   varchar(16) NOT NULL DEFAULT 'INTERNAL',
  purpose      varchar(24) NOT NULL,
  expires_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_file_object PRIMARY KEY (id),
  CONSTRAINT uq_file_object_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_file_object_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_file_object_key UNIQUE (bucket, object_key),
  CONSTRAINT ck_file_object_size CHECK (size_bytes >= 0),
  CONSTRAINT ck_file_object_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_file_object_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_file_object_class CHECK (data_class IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_file_object_purpose CHECK (purpose IN ('UPLOAD_SOURCE', 'COMMITMENT', 'COMPLIANCE_PACK', 'USAGE_REPORT')),
  CONSTRAINT ck_file_object_ctype CHECK (content_type IN ('application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/markdown', 'text/plain', 'application/zip', 'text/csv'))
);
CREATE INDEX ix_file_object_expires ON ph17_assist.file_object (expires_at) WHERE expires_at IS NOT NULL;
CREATE TRIGGER tg_file_object_touch BEFORE UPDATE ON ph17_assist.file_object FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_file_object_immutable BEFORE UPDATE ON ph17_assist.file_object FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('bucket', 'object_key', 'sha256', 'size_bytes');
CALL ph17_assist.p_enable_rls_common('ph17_assist.file_object');
COMMENT ON TABLE ph17_assist.file_object IS 'EN-17-39 Tham chiếu đối tượng tệp (DD-12) cho tài liệu tải lên (FR-17-020), hồ sơ cam kết nhà cung cấp (FR-17-003, 007) và gói bằng chứng tuân thủ (FR-17-057). Nội dung nằm ở kho đối tượng; chỉ tệp quét sạch (CLEAN) mới được dùng. Không bí mật, không nội dung hội thoại.';
COMMENT ON COLUMN ph17_assist.file_object.data_class IS 'Chỉ PUBLIC hoặc INTERNAL: PH-17 không nhận tệp mức cao hơn (BR-17-026, 030).';
COMMENT ON COLUMN ph17_assist.file_object.purpose IS 'UPLOAD_SOURCE tài liệu tải lên, COMMITMENT hồ sơ cam kết nhà cung cấp, COMPLIANCE_PACK gói bằng chứng, USAGE_REPORT báo cáo sử dụng.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.file_object CASCADE;

-- @changeset ph17-0110-tenant-setting
CREATE TABLE ph17_assist.tenant_setting (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  setting_key   varchar(48) NOT NULL,
  value         jsonb NOT NULL,
  floor_value   jsonb,
  ceiling_value jsonb,
  four_eyes     boolean NOT NULL DEFAULT false,
  synced_at     timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('17.enabled', '17.feature.search', '17.feature.mapping', '17.feature.explain', '17.feature.roles', '17.model.external-allowed', '17.model.default-chat', '17.model.default-embed', '17.model.default-rerank', '17.model.fallback-enabled', '17.model.timeout-seconds', '17.quota.user-turns-per-day', '17.quota.user-turns-per-minute', '17.quota.warn-percent', '17.quota.du-calls-per-minute', '17.input.max-chars', '17.context.max-messages', '17.conversation.max-per-user', '17.rag.top-k', '17.rag.min-score', '17.rag.hybrid-weight-vector', '17.rag.chunk-overlap', '17.index.full-cron', '17.index.stale-days', '17.index.pause-purge-days', '17.upload.max-mb', '17.tool.max-calls-per-turn', '17.tool.timeout-seconds', '17.tool.max-depth', '17.mapping.sample-rows', '17.suggestion.ttl-hours', '17.explain.log-lines-max', '17.explain.trace-window-minutes', '17.log.retention-days', '17.log.access-reason-min-chars', '17.log.export-max-days', '17.breaker.error-rate', '17.breaker.open-seconds', '17.eval.min-score', '17.eval.regression-tolerance', '17.redteam.min-pass-rate', '17.feedback.sla-days', '17.quality.alert-drop-percent', '17.notice.reaccept-days', '17.model.first-token-timeout-seconds', '17.quota.tenant-tokens-per-day', '17.output.max-tokens', '17.rag.chunk-tokens', '17.report.cost-per-1k-tokens')),
  CONSTRAINT ck_tenant_setting_bounds CHECK (jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value))),
  CONSTRAINT ck_tenant_setting_retention_floor CHECK (setting_key <> '17.log.retention-days' OR (jsonb_typeof(value) = 'number' AND value >= '90'::jsonb)),
  CONSTRAINT ck_tenant_setting_redteam_floor CHECK (setting_key <> '17.redteam.min-pass-rate' OR value = '100'::jsonb)
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph17_assist.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph17_assist.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('setting_key');
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_setting');
COMMENT ON TABLE ph17_assist.tenant_setting IS 'EN-17-40 Bản chụp tham số 17.* của tenant (FRS 8.2, FR-17-059, BR-17-078). Nguồn chuẩn là PH-18 (DD-14); dh-assist đọc có đệm 30 giây và giữ bản chụp này để kiểm miền, sàn, trần khi ghi và để cổng phát hành đọc điểm tối thiểu. Khóa đổi bốn mắt đánh dấu four_eyes.';
COMMENT ON COLUMN ph17_assist.tenant_setting.synced_at IS 'Lần đồng bộ cuối từ PH-18 DD-14.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.tenant_setting CASCADE;

-- @changeset ph17-0120-outbox-event
CREATE TABLE ph17_assist.outbox_event (
  event_id       uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('assist.config.changed.v1', 'assist.enablement.changed.v1', 'assist.kill-switch.changed.v1', 'assist.policy-change.decided.v1', 'assist.notice.published.v1', 'assist.provider.state-changed.v1', 'assist.model-version.state-changed.v1', 'assist.route.sync-requested.v1', 'assist.route.sync-completed.v1', 'assist.model.health-changed.v1', 'assist.breaker.state-changed.v1', 'assist.quota.threshold-reached.v1', 'assist.source.state-changed.v1', 'assist.index.completed.v1', 'assist.index.failed.v1', 'assist.index.purged.v1', 'assist.upload.state-changed.v1', 'assist.suggestion.decided.v1', 'assist.guardrail.violation-detected.v1', 'assist.prompt.state-changed.v1', 'assist.eval.run-completed.v1', 'assist.redteam.run-completed.v1', 'assist.feedback.submitted.v1', 'assist.quality.alert-raised.v1', 'assist.log.access-granted.v1', 'assist.export.ready.v1', 'assist.log.purged.v1', 'assist.process-suggestion.decided.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_content CHECK (NOT (payload ?| ARRAY['content', 'prompt', 'answer', 'question', 'text', 'chunk', 'embedding', 'secret', 'secret_ref', 'token', 'tokens', 'message', 'value', 'values']))
);
CREATE INDEX ix_outbox_event_occurred ON ph17_assist.outbox_event (occurred_at);
CALL ph17_assist.p_enable_rls('ph17_assist.outbox_event');
COMMENT ON TABLE ph17_assist.outbox_event IS 'EN-17-39 Outbox (DD-11, ADR-042) cho EVT-17-01…28. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm: CHECK chặn khóa nội dung hội thoại, đoạn tri thức, bí mật (BR-17-022, 073). Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.outbox_event CASCADE;

-- @changeset ph17-0130-inbox-event
CREATE TABLE ph17_assist.inbox_event (
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     varchar(255) NOT NULL,
  source_topic varchar(249) NOT NULL,
  event_type   varchar(255) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  outcome      varchar(2000),
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph17_assist.inbox_event (received_at);
CALL ph17_assist.p_enable_rls('ph17_assist.inbox_event');
COMMENT ON TABLE ph17_assist.inbox_event IS 'EN-17-41 Inbox chống xử lý trùng cho sự kiện PH-17 tiêu thụ (at-least-once): catalog.api.*, rdm.catalog.*, integration.flow.*, event.publication.*, privacy.classification.changed, privacy.contract-level.changed, privacy.dataset.status-changed, gateway.snapshot.* (FRS 9.3b). Khóa (consumer, event_id). Dọn sau 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.inbox_event CASCADE;


-- @file 17-0020-policy.sql
-- @changeset ph17-0140-ai-notice
CREATE TABLE ph17_assist.ai_notice (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  version_no   integer NOT NULL,
  title        varchar(255) NOT NULL,
  body_text    text NOT NULL,
  locale       varchar(8) NOT NULL DEFAULT 'vi',
  status       varchar(12) NOT NULL DEFAULT 'DRAFT',
  published_at timestamptz,
  published_by varchar(64),
  retired_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ai_notice PRIMARY KEY (id),
  CONSTRAINT uq_ai_notice_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_ai_notice_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_ai_notice_version UNIQUE (tenant_id, version_no),
  CONSTRAINT ck_ai_notice_version CHECK (version_no >= 1),
  CONSTRAINT ck_ai_notice_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_ai_notice_published CHECK ((status = 'DRAFT') OR (published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_ai_notice_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_ai_notice_current ON ph17_assist.ai_notice (tenant_id) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_ai_notice_touch BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_ai_notice_frozen BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_frozen('PUBLISHED,RETIRED', 'title', 'body_text', 'locale', 'version_no');
CREATE TRIGGER tg_ai_notice_fsm_status BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>PUBLISHED,PUBLISHED>RETIRED');
CALL ph17_assist.p_enable_rls('ph17_assist.ai_notice');
COMMENT ON TABLE ph17_assist.ai_notice IS 'EN-17-05 Phiên bản điều khoản và thông báo minh bạch dùng AI (FR-17-005, BR-17-007). Phiên bản đã công bố (PUBLISHED) không sửa nội dung (ERR-17-024); công bố bản mới thì bản cũ chuyển RETIRED. Người dùng xác nhận bản đang PUBLISHED.';
COMMENT ON COLUMN ph17_assist.ai_notice.status IS 'DRAFT, PUBLISHED, RETIRED (NoticeStatus, Phụ lục A).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.ai_notice CASCADE;

-- @changeset ph17-0150-notice-acceptance
CREATE TABLE ph17_assist.notice_acceptance (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  notice_id   uuid NOT NULL,
  user_id     varchar(64) NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notice_acceptance PRIMARY KEY (id),
  CONSTRAINT ck_notice_acceptance_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_notice_acceptance_notice FOREIGN KEY (tenant_id, notice_id) REFERENCES ph17_assist.ai_notice (tenant_id, id),
  CONSTRAINT uq_notice_acceptance_user UNIQUE (tenant_id, notice_id, user_id)
);
CREATE INDEX ix_notice_acceptance_user ON ph17_assist.notice_acceptance (tenant_id, user_id, accepted_at DESC);
CREATE TRIGGER tg_notice_acceptance_touch BEFORE UPDATE ON ph17_assist.notice_acceptance FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_notice_acceptance_append_only BEFORE UPDATE OR DELETE ON ph17_assist.notice_acceptance FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls('ph17_assist.notice_acceptance');
COMMENT ON TABLE ph17_assist.notice_acceptance IS 'EN-17-06 Người dùng đã xác nhận phiên bản điều khoản nào, lúc nào (FR-17-005, BR-17-007). Chỉ thêm. Hết 17.notice.reaccept-days hoặc có phiên bản mới thì xác nhận lại bằng dòng mới.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.notice_acceptance CASCADE;

-- @changeset ph17-0160-policy-change
CREATE TABLE ph17_assist.policy_change (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  change_type      varchar(16) NOT NULL,
  state            varchar(12) NOT NULL DEFAULT 'PENDING',
  payload          jsonb NOT NULL DEFAULT '{}',
  reason           varchar(2000) NOT NULL,
  decision_no      varchar(64),
  requested_by     varchar(64) NOT NULL,
  requested_at     timestamptz NOT NULL DEFAULT now(),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  expires_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_change PRIMARY KEY (id),
  CONSTRAINT uq_policy_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_policy_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_policy_change_type CHECK (change_type IN ('ENABLE', 'EXTERNAL_ON', 'RESUME', 'SENSITIVE_PARAM')),
  CONSTRAINT ck_policy_change_state CHECK (state IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_policy_change_four_eyes CHECK (decided_by IS NULL OR (decided_by <> requested_by)),
  CONSTRAINT ck_policy_change_decided CHECK ((state IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_policy_change_reject CHECK (state <> 'REJECTED' OR char_length(COALESCE(decision_comment, '')) >= 20),
  CONSTRAINT ck_policy_change_enable CHECK (change_type NOT IN ('ENABLE', 'RESUME') OR (decision_no IS NOT NULL AND char_length(reason) >= 20)),
  CONSTRAINT ck_policy_change_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_policy_change_payload CHECK (payload::text !~* '(bearer |openbao://|private key|password)')
);
CREATE UNIQUE INDEX uq_policy_change_pending ON ph17_assist.policy_change (tenant_id, change_type) WHERE state = 'PENDING';
CREATE INDEX ix_policy_change_state ON ph17_assist.policy_change (tenant_id, state, requested_at DESC);
CREATE TRIGGER tg_policy_change_touch BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_policy_change_fsm_state BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'PENDING>APPROVED,PENDING>REJECTED,PENDING>CANCELLED,PENDING>EXPIRED');
CREATE TRIGGER tg_policy_change_immutable BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('change_type', 'requested_by', 'reason');
CALL ph17_assist.p_enable_rls('ph17_assist.policy_change');
COMMENT ON TABLE ph17_assist.policy_change IS 'EN-17-02 Đề nghị đổi chính sách cần bốn mắt (FR-17-001, 003, 006, 059; BR-17-002, 004, 008, 010): ENABLE, EXTERNAL_ON, RESUME, SENSITIVE_PARAM. Người duyệt khác người đề nghị (ERR-17-005); mỗi loại chỉ một đề nghị PENDING (ERR-17-013); bật cần số quyết định và lý do (ERR-17-014).';
COMMENT ON COLUMN ph17_assist.policy_change.decision_no IS 'Số quyết định của lãnh đạo tỉnh (bắt buộc khi ENABLE, RESUME).';
COMMENT ON COLUMN ph17_assist.policy_change.payload IS 'Giá trị đề nghị (ví dụ khóa 17.* và giá trị mới); không bí mật.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.policy_change CASCADE;

-- @changeset ph17-0170-tenant-policy
CREATE TABLE ph17_assist.tenant_policy (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  assist_state       varchar(12) NOT NULL DEFAULT 'DISABLED',
  enable_decision_no varchar(64),
  enable_reason      varchar(2000),
  enabled_change_id  uuid,
  enabled_at         timestamptz,
  enabled_by         varchar(64),
  disabled_at        timestamptz,
  external_allowed   boolean NOT NULL DEFAULT false,
  external_change_id uuid,
  current_notice_id  uuid,
  killed_at          timestamptz,
  killed_by          varchar(64),
  kill_reason        varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_policy PRIMARY KEY (id),
  CONSTRAINT uq_tenant_policy_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_policy_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_policy_state CHECK (assist_state IN ('DISABLED', 'ENABLED', 'KILLED')),
  CONSTRAINT fk_tenant_policy_enabled_change FOREIGN KEY (tenant_id, enabled_change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT fk_tenant_policy_external_change FOREIGN KEY (tenant_id, external_change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT fk_tenant_policy_current_notice FOREIGN KEY (tenant_id, current_notice_id) REFERENCES ph17_assist.ai_notice (tenant_id, id),
  CONSTRAINT ck_tenant_policy_enabled CHECK (assist_state <> 'ENABLED' OR (enable_decision_no IS NOT NULL AND enabled_at IS NOT NULL AND enabled_by IS NOT NULL AND enabled_change_id IS NOT NULL)),
  CONSTRAINT ck_tenant_policy_killed CHECK ((assist_state = 'KILLED') = (killed_at IS NOT NULL)),
  CONSTRAINT ck_tenant_policy_external CHECK (NOT external_allowed OR external_change_id IS NOT NULL)
);
CREATE TRIGGER tg_tenant_policy_touch BEFORE UPDATE ON ph17_assist.tenant_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_policy_fsm_assist_state BEFORE UPDATE ON ph17_assist.tenant_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('assist_state', 'DISABLED>ENABLED,ENABLED>DISABLED,ENABLED>KILLED,DISABLED>KILLED,KILLED>DISABLED');
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_policy');
COMMENT ON TABLE ph17_assist.tenant_policy IS 'EN-17-01 Chính sách của tenant, một dòng mỗi tenant (FR-17-001, 003, 006; BR-17-001, 002, 004, 008). assist_state DISABLED mặc định; ENABLED cần số quyết định; KILLED chỉ gỡ về DISABLED (máy trạng thái FRS 4.7). Cho phép mô hình ngoài cần đề nghị EXTERNAL_ON đã duyệt.';
COMMENT ON COLUMN ph17_assist.tenant_policy.enabled_change_id IS 'Đề nghị ENABLE đã duyệt bốn mắt (BR-17-002).';
COMMENT ON COLUMN ph17_assist.tenant_policy.external_change_id IS 'Đề nghị EXTERNAL_ON đã duyệt bốn mắt (BR-17-004).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.tenant_policy CASCADE;

-- @changeset ph17-0180-capability-policy
CREATE TABLE ph17_assist.capability_policy (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  capability varchar(16) NOT NULL,
  role_group varchar(32) NOT NULL DEFAULT 'ALL_READERS',
  enabled    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_capability_policy PRIMARY KEY (id),
  CONSTRAINT ck_capability_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_capability_policy UNIQUE (tenant_id, capability, role_group),
  CONSTRAINT ck_capability_policy_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_capability_policy_role_group CHECK (role_group ~ '^[A-Z][A-Z0-9_]{1,31}$')
);
CREATE TRIGGER tg_capability_policy_touch BEFORE UPDATE ON ph17_assist.capability_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.capability_policy');
COMMENT ON TABLE ph17_assist.capability_policy IS 'EN-17-03 Năng lực bật cho từng nhóm vai trò (FR-17-002, BR-17-003): SEARCH, MAPPING, EXPLAIN. Dùng được khi trợ lý bật, 17.feature.* bật và nhóm vai trò được phép (ERR-17-011).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.capability_policy CASCADE;

-- @changeset ph17-0190-quota-usage
CREATE TABLE ph17_assist.quota_usage (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  usage_date       date NOT NULL,
  scope_kind       varchar(8) NOT NULL,
  subject_ref      varchar(64) NOT NULL,
  capability       varchar(24) NOT NULL DEFAULT 'ALL',
  model_version_id uuid,
  turns            integer NOT NULL DEFAULT 0,
  blocked_turns    integer NOT NULL DEFAULT 0,
  tokens_in        bigint NOT NULL DEFAULT 0,
  tokens_out       bigint NOT NULL DEFAULT 0,
  est_cost         numeric(14,2) NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_usage PRIMARY KEY (id),
  CONSTRAINT ck_quota_usage_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_usage_scope CHECK (scope_kind IN ('USER', 'TENANT', 'DU')),
  CONSTRAINT ck_quota_usage_counts CHECK (turns >= 0 AND blocked_turns >= 0 AND tokens_in >= 0 AND tokens_out >= 0 AND est_cost >= 0),
  CONSTRAINT ck_quota_usage_capability CHECK (capability = 'ALL' OR capability IN ('SEARCH', 'MAPPING', 'EXPLAIN') OR capability IN ('CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK'))
);
CREATE UNIQUE INDEX uq_quota_usage_bucket ON ph17_assist.quota_usage (tenant_id, usage_date, scope_kind, subject_ref, capability, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX ix_quota_usage_date ON ph17_assist.quota_usage (usage_date);
CREATE TRIGGER tg_quota_usage_touch BEFORE UPDATE ON ph17_assist.quota_usage FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.quota_usage');
COMMENT ON TABLE ph17_assist.quota_usage IS 'EN-17-07 Số lượt và token đã dùng theo ngày (FR-17-004, 058; BR-17-005, 024): theo người dùng, theo tenant, theo DU gọi data plane. dh-assist cộng dồn trước và sau lời gọi mô hình; vượt hạn mức thì 429 không gọi mô hình. Giữ 400 ngày.';
COMMENT ON COLUMN ph17_assist.quota_usage.subject_ref IS 'Mã người dùng (sub), mã tenant hoặc mã DU gọi; không tên người.';
COMMENT ON COLUMN ph17_assist.quota_usage.est_cost IS 'Ước tính token nhân đơn giá phiên bản (BR-17-024), không dùng thanh toán.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.quota_usage CASCADE;

-- @changeset ph17-0200-kill-switch-record
CREATE TABLE ph17_assist.kill_switch_record (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  scope                varchar(8) NOT NULL,
  target_tenants       varchar(16)[],
  reason               varchar(2000) NOT NULL,
  activated_by         varchar(64) NOT NULL,
  activated_at         timestamptz NOT NULL DEFAULT now(),
  propagated_at        timestamptz,
  release_requested_by varchar(64),
  release_requested_at timestamptz,
  release_reason       varchar(2000),
  released_by          varchar(64),
  released_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kill_switch_record PRIMARY KEY (id),
  CONSTRAINT ck_kill_switch_record_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_kill_switch_record_scope CHECK (scope IN ('TENANT', 'PLATFORM')),
  CONSTRAINT ck_kill_switch_record_scope_tenant CHECK ((scope = 'PLATFORM') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_kill_switch_record_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_kill_switch_record_release_req CHECK ((release_requested_by IS NULL) = (release_requested_at IS NULL)),
  CONSTRAINT ck_kill_switch_record_released CHECK ((released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by))),
  CONSTRAINT ck_kill_switch_record_propagation CHECK (propagated_at IS NULL OR propagated_at <= activated_at + interval '60 seconds')
);
CREATE UNIQUE INDEX uq_kill_switch_active ON ph17_assist.kill_switch_record (tenant_id, scope) WHERE released_at IS NULL;
CREATE TRIGGER tg_kill_switch_record_touch BEFORE UPDATE ON ph17_assist.kill_switch_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_kill_switch_record_immutable BEFORE UPDATE ON ph17_assist.kill_switch_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('scope', 'reason', 'activated_by', 'activated_at');
CALL ph17_assist.p_enable_rls_common('ph17_assist.kill_switch_record');
COMMENT ON TABLE ph17_assist.kill_switch_record IS 'EN-17-08 Một lần tắt khẩn (FR-17-006, BR-17-008): phạm vi TENANT hoặc PLATFORM (tenant_id COMMON), lý do, người kích hoạt. Chỉ cần lý do để tắt; gỡ cần người đề nghị và người duyệt khác nhau. Gỡ đưa tenant về DISABLED, không tự ENABLED.';
COMMENT ON COLUMN ph17_assist.kill_switch_record.propagated_at IS 'Thời điểm mọi thành phần xác nhận đã chặn; chỉ tiêu ≤ 60 giây (NFR-17-004).';
COMMENT ON COLUMN ph17_assist.kill_switch_record.target_tenants IS 'Nhóm tenant của lần tắt nền tảng; NULL là toàn bộ.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.kill_switch_record CASCADE;


-- @file 17-0030-model.sql
-- @changeset ph17-0210-model-provider
CREATE TABLE ph17_assist.model_provider (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  provider_code       varchar(32) NOT NULL,
  name                varchar(255) NOT NULL,
  provider_kind       varchar(8) NOT NULL,
  protocol            varchar(24) NOT NULL DEFAULT 'OPENAI_COMPATIBLE',
  endpoint_url        varchar(512) NOT NULL,
  data_region         varchar(8) NOT NULL DEFAULT 'VN',
  secret_ref          varchar(255),
  status              varchar(12) NOT NULL DEFAULT 'DRAFT',
  commitment_valid_to date,
  suspended_reason    varchar(2000),
  retired_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_provider PRIMARY KEY (id),
  CONSTRAINT ck_model_provider_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_model_provider_code UNIQUE (tenant_id, provider_code),
  CONSTRAINT ck_model_provider_common CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_model_provider_code CHECK (provider_code ~ '^[A-Z][A-Z0-9-]{2,31}$'),
  CONSTRAINT ck_model_provider_kind CHECK (provider_kind IN ('INTERNAL', 'EXTERNAL')),
  CONSTRAINT ck_model_provider_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_model_provider_protocol CHECK (protocol IN ('OPENAI_COMPATIBLE', 'ANTHROPIC_MESSAGES', 'CUSTOM_HTTP')),
  CONSTRAINT ck_model_provider_secret_ref CHECK (secret_ref IS NULL OR secret_ref ~ '^openbao://kv/[A-Za-z0-9/_.-]{3,200}$'),
  CONSTRAINT ck_model_provider_external_https CHECK (provider_kind <> 'EXTERNAL' OR (endpoint_url ~ '^https://[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{2,5})?(/.*)?$' AND endpoint_url !~ '^https://[0-9.]+([:/]|$)' AND endpoint_url !~ '(localhost|169\.254|\.internal|\.local)')),
  CONSTRAINT ck_model_provider_external_region CHECK (provider_kind <> 'EXTERNAL' OR (data_region = 'VN' AND secret_ref IS NOT NULL)),
  CONSTRAINT ck_model_provider_external_active CHECK (provider_kind <> 'EXTERNAL' OR status NOT IN ('ACTIVE') OR commitment_valid_to IS NOT NULL),
  CONSTRAINT ck_model_provider_suspended CHECK (status <> 'SUSPENDED' OR suspended_reason IS NOT NULL),
  CONSTRAINT ck_model_provider_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE TRIGGER tg_model_provider_touch BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_provider_immutable BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_code', 'provider_kind');
CREATE TRIGGER tg_model_provider_fsm_status BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>ACTIVE,ACTIVE>SUSPENDED,SUSPENDED>ACTIVE,ACTIVE>RETIRED,SUSPENDED>RETIRED,DRAFT>RETIRED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_provider');
COMMENT ON TABLE ph17_assist.model_provider IS 'EN-17-09 Nhà cung cấp mô hình dùng chung do PA khai báo, tenant_id COMMON (FR-17-007; BR-17-011, 012, 013). INTERNAL (vLLM trong cụm) hoặc EXTERNAL: điểm cuối HTTPS theo tên miền, vùng lưu dữ liệu VN, có secret_ref tới OpenBao, không lưu bí mật. ACTIVE với EXTERNAL cần cam kết còn hiệu lực.';
COMMENT ON COLUMN ph17_assist.model_provider.secret_ref IS 'Tham chiếu OpenBao dạng openbao://kv/... ; không lưu giá trị bí mật (BR-17-011).';
COMMENT ON COLUMN ph17_assist.model_provider.data_region IS 'Vùng lưu dữ liệu của nhà cung cấp; EXTERNAL phải là VN (SEC-49, Luật An ninh mạng 116/2025).';
COMMENT ON COLUMN ph17_assist.model_provider.commitment_valid_to IS 'Ngày hết hạn của cam kết hiện hành (bản sao từ provider_commitment); hết hạn thì tự SUSPENDED (BR-17-013).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model_provider CASCADE;

-- @changeset ph17-0220-provider-commitment
CREATE TABLE ph17_assist.provider_commitment (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  provider_id      uuid NOT NULL,
  doc_no           varchar(64) NOT NULL,
  doc_date         date NOT NULL,
  valid_from       date NOT NULL,
  valid_to         date NOT NULL,
  domestic_storage boolean NOT NULL,
  no_training      boolean NOT NULL,
  file_id          uuid NOT NULL,
  state            varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_provider_commitment PRIMARY KEY (id),
  CONSTRAINT ck_provider_commitment_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_provider_commitment_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id),
  CONSTRAINT fk_provider_commitment_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT ck_provider_commitment_pledge CHECK (domestic_storage AND no_training),
  CONSTRAINT ck_provider_commitment_period CHECK (valid_to > valid_from),
  CONSTRAINT ck_provider_commitment_state CHECK (state IN ('ACTIVE', 'EXPIRED', 'SUPERSEDED'))
);
CREATE INDEX ix_provider_commitment_provider ON ph17_assist.provider_commitment (provider_id, valid_to DESC);
CREATE TRIGGER tg_provider_commitment_touch BEFORE UPDATE ON ph17_assist.provider_commitment FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_provider_commitment_immutable BEFORE UPDATE ON ph17_assist.provider_commitment FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_id', 'doc_no', 'file_id');
CALL ph17_assist.p_enable_rls_common('ph17_assist.provider_commitment');
COMMENT ON TABLE ph17_assist.provider_commitment IS 'EN-17-42 (FR-17-003, 007; BR-17-013). Cam kết của nhà cung cấp ngoài về lưu dữ liệu trong nước và không dùng dữ liệu huấn luyện: số văn bản, tệp đính kèm, hiệu lực. Cả hai cam kết phải đúng (ERR-17-026).';
COMMENT ON COLUMN ph17_assist.provider_commitment.state IS 'ACTIVE, EXPIRED, SUPERSEDED (CommitmentState, Phụ lục A).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.provider_commitment CASCADE;

-- @changeset ph17-0230-model
CREATE TABLE ph17_assist.model (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  model_code   varchar(64) NOT NULL,
  name         varchar(255) NOT NULL,
  model_kind   varchar(12) NOT NULL,
  scope        varchar(8) NOT NULL,
  provider_id  uuid NOT NULL,
  capabilities varchar(24)[] NOT NULL,
  description  varchar(2000),
  retired_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model PRIMARY KEY (id),
  CONSTRAINT uq_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_model_code UNIQUE (tenant_id, model_code),
  CONSTRAINT ck_model_code CHECK (model_code ~ '^[a-z0-9][a-z0-9._-]{2,63}$'),
  CONSTRAINT ck_model_kind CHECK (model_kind IN ('CHAT', 'EMBEDDING', 'RERANK')),
  CONSTRAINT ck_model_scope CHECK (scope IN ('COMMON', 'TENANT')),
  CONSTRAINT ck_model_scope_tenant CHECK ((scope = 'COMMON') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_model_caps CHECK (cardinality(capabilities) >= 1 AND capabilities <@ ARRAY['SEARCH', 'MAPPING', 'EXPLAIN', 'CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK']::varchar[]),
  CONSTRAINT ck_model_kind_caps CHECK ((model_kind <> 'EMBEDDING' OR capabilities = ARRAY['EMBED']::varchar[]) AND (model_kind <> 'RERANK' OR capabilities = ARRAY['RERANK']::varchar[])),
  CONSTRAINT fk_model_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id)
);
CREATE TRIGGER tg_model_touch BEFORE UPDATE ON ph17_assist.model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_immutable BEFORE UPDATE ON ph17_assist.model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('model_code', 'model_kind', 'scope', 'provider_id');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model');
COMMENT ON TABLE ph17_assist.model IS 'EN-17-10 Mô hình: CHAT, EMBEDDING, RERANK; phạm vi COMMON (PA khai báo, tenant_id COMMON) hoặc TENANT (FR-17-008). Một nhà cung cấp có nhiều mô hình; năng lực hỗ trợ gồm SEARCH, MAPPING, EXPLAIN và nhiệm vụ data plane.';
COMMENT ON COLUMN ph17_assist.model.capabilities IS 'SEARCH, MAPPING, EXPLAIN (Capability) và CLASSIFY_TEXT, EXTRACT_FIELDS, SUGGEST_STEP (data plane, BR-17-082), EMBED, RERANK (ModelCapability, Phụ lục A).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model CASCADE;

-- @changeset ph17-0240-model-version
CREATE TABLE ph17_assist.model_version (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  model_id         uuid NOT NULL,
  version_no       integer NOT NULL,
  version_label    varchar(64) NOT NULL,
  upstream_name    varchar(128) NOT NULL,
  status           varchar(12) NOT NULL DEFAULT 'DRAFT',
  context_tokens   integer NOT NULL,
  embedding_dim    smallint,
  price_in_per_1k  numeric(12,4) NOT NULL DEFAULT 0,
  price_out_per_1k numeric(12,4) NOT NULL DEFAULT 0,
  gen_params       jsonb NOT NULL DEFAULT '{}',
  eval_run_id      uuid,
  redteam_run_id   uuid,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  approved_at      timestamptz,
  retired_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_version PRIMARY KEY (id),
  CONSTRAINT uq_model_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_model_version_model FOREIGN KEY (tenant_id, model_id) REFERENCES ph17_assist.model (tenant_id, id),
  CONSTRAINT uq_model_version_no UNIQUE (tenant_id, model_id, version_no),
  CONSTRAINT ck_model_version_version CHECK (version_no >= 1),
  CONSTRAINT ck_model_version_status CHECK (status IN ('DRAFT', 'EVALUATING', 'APPROVED', 'RETIRED')),
  CONSTRAINT ck_model_version_context CHECK (context_tokens BETWEEN 256 AND 2000000),
  CONSTRAINT ck_model_version_dim CHECK (embedding_dim IS NULL OR embedding_dim BETWEEN 64 AND 4096),
  CONSTRAINT ck_model_version_price CHECK (price_in_per_1k >= 0 AND price_out_per_1k >= 0),
  CONSTRAINT ck_model_version_params CHECK (gen_params::text !~* '(bearer |openbao://|password|api[_-]?key)'),
  CONSTRAINT ck_model_version_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_model_version_approved CHECK (status <> 'APPROVED' OR (decided_by IS NOT NULL AND approved_at IS NOT NULL AND eval_run_id IS NOT NULL AND redteam_run_id IS NOT NULL)),
  CONSTRAINT ck_model_version_reject CHECK (decision_comment IS NULL OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_model_version_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_model_version_submitted CHECK (status NOT IN ('EVALUATING', 'APPROVED') OR submitted_by IS NOT NULL)
);
CREATE INDEX ix_model_version_status ON ph17_assist.model_version (tenant_id, status);
CREATE TRIGGER tg_model_version_touch BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_version_immutable BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('model_id', 'version_no');
CREATE TRIGGER tg_model_version_frozen BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_frozen('EVALUATING,APPROVED,RETIRED', 'version_label', 'upstream_name', 'context_tokens', 'embedding_dim', 'price_in_per_1k', 'price_out_per_1k', 'gen_params');
CREATE TRIGGER tg_model_version_fsm_status BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>EVALUATING,EVALUATING>DRAFT,EVALUATING>APPROVED,APPROVED>RETIRED,DRAFT>RETIRED');
CREATE TRIGGER tg_model_version_gate BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_release_gate('MODEL');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_version');
COMMENT ON TABLE ph17_assist.model_version IS 'EN-17-11 Phiên bản mô hình, đối tượng được duyệt (FR-17-008, 009; BR-14, 15, 16, 24). DRAFT, EVALUATING, APPROVED, RETIRED (FRS 4.3); chỉ APPROVED định tuyến được. Duyệt bốn mắt và qua cổng phát hành: đánh giá chuẩn đạt, ca đỏ 100%, bộ ca đỏ từ 50 ca đang hoạt động. Nội dung khóa từ EVALUATING.';
COMMENT ON COLUMN ph17_assist.model_version.embedding_dim IS 'Số chiều vector của mô hình nhúng (1024 theo mặc định); chỉ EMBEDDING có giá trị.';
COMMENT ON COLUMN ph17_assist.model_version.eval_run_id IS 'Lượt đánh giá chuẩn đạt ngưỡng 17.eval.min-score (BR-17-015).';
COMMENT ON COLUMN ph17_assist.model_version.redteam_run_id IS 'Lượt bộ ca đỏ không lọt ca nào (BR-17-067).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model_version CASCADE;

-- @changeset ph17-0250-model-route
CREATE TABLE ph17_assist.model_route (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  version_id      uuid NOT NULL,
  route_ref       varchar(128) NOT NULL,
  egress_host     varchar(255) NOT NULL,
  priority        smallint NOT NULL DEFAULT 0,
  status          varchar(10) NOT NULL DEFAULT 'PENDING',
  snapshot_ref    varchar(128),
  last_synced_at  timestamptz,
  drift           boolean NOT NULL DEFAULT false,
  last_error_code varchar(16),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_route PRIMARY KEY (id),
  CONSTRAINT uq_model_route_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_route_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_model_route_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph17_assist.model_version (tenant_id, id),
  CONSTRAINT uq_model_route_priority UNIQUE (tenant_id, version_id, priority),
  CONSTRAINT uq_model_route_ref UNIQUE (tenant_id, route_ref),
  CONSTRAINT ck_model_route_status CHECK (status IN ('PENDING', 'SYNCED', 'FAILED', 'DISABLED')),
  CONSTRAINT ck_model_route_priority CHECK (priority BETWEEN 0 AND 9),
  CONSTRAINT ck_model_route_host CHECK (egress_host !~ '^[0-9.]+$' AND (egress_host ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' OR egress_host ~ '^[a-z0-9-]+\.svc(\.cluster\.local)?$')),
  CONSTRAINT ck_model_route_synced CHECK (status <> 'SYNCED' OR (snapshot_ref IS NOT NULL AND last_synced_at IS NOT NULL))
);
CREATE TRIGGER tg_model_route_touch BEFORE UPDATE ON ph17_assist.model_route FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_route_fsm_status BEFORE UPDATE ON ph17_assist.model_route FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PENDING>SYNCED,PENDING>FAILED,SYNCED>PENDING,FAILED>PENDING,PENDING>DISABLED,SYNCED>DISABLED,FAILED>DISABLED,DISABLED>PENDING');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_route');
COMMENT ON TABLE ph17_assist.model_route IS 'EN-17-12 Tuyến từ phiên bản mô hình tới đích egress APISIX ai-proxy (FR-17-010, 011; BR-17-018, 019, 020). priority 0 là tuyến chính, lớn hơn là dự phòng. PH-03 áp cấu hình; tuyến chưa SYNCED thì mô hình chưa gọi được.';
COMMENT ON COLUMN ph17_assist.model_route.egress_host IS 'Tên miền trong nước đã khai báo (EXTERNAL) hoặc tên dịch vụ trong cụm (INTERNAL); không IP trần (BR-17-012).';
COMMENT ON COLUMN ph17_assist.model_route.drift IS 'Cấu hình thực ở APISIX lệch cấu hình mong muốn (BR-17-020).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model_route CASCADE;

-- @changeset ph17-0260-route-sync-run
CREATE TABLE ph17_assist.route_sync_run (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'PENDING',
  route_count      integer NOT NULL DEFAULT 0,
  request_event_id uuid,
  result_event_id  uuid,
  snapshot_ref     varchar(128),
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  error_code       varchar(16),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_route_sync_run PRIMARY KEY (id),
  CONSTRAINT ck_route_sync_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_route_sync_run_status CHECK (status IN ('PENDING', 'SYNCED', 'FAILED', 'DISABLED')),
  CONSTRAINT ck_route_sync_run_count CHECK (route_count >= 0),
  CONSTRAINT ck_route_sync_run_finished CHECK ((status IN ('SYNCED', 'FAILED')) = (finished_at IS NOT NULL))
);
CREATE INDEX ix_route_sync_run_started ON ph17_assist.route_sync_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_route_sync_run_touch BEFORE UPDATE ON ph17_assist.route_sync_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_route_sync_run_fsm_status BEFORE UPDATE ON ph17_assist.route_sync_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PENDING>SYNCED,PENDING>FAILED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.route_sync_run');
COMMENT ON TABLE ph17_assist.route_sync_run IS 'EN-17-13 Một lượt đồng bộ cấu hình tuyến sang PH-03 và kết quả (FR-17-011): phát EVT-17-08, nhận EVT-17-09 (gateway.snapshot.published hoặc rejected). Bản ghi chỉ mang mã và số đếm.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.route_sync_run CASCADE;

-- @changeset ph17-0270-tenant-model
CREATE TABLE ph17_assist.tenant_model (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  version_id          uuid NOT NULL,
  model_kind          varchar(12) NOT NULL,
  enabled             boolean NOT NULL DEFAULT false,
  is_default          boolean NOT NULL DEFAULT false,
  fallback_version_id uuid,
  enabled_by          varchar(64),
  enabled_at          timestamptz,
  disabled_at         timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_model PRIMARY KEY (id),
  CONSTRAINT ck_tenant_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_tenant_model_version FOREIGN KEY (version_id) REFERENCES ph17_assist.model_version (id),
  CONSTRAINT uq_tenant_model_version UNIQUE (tenant_id, version_id),
  CONSTRAINT ck_tenant_model_kind CHECK (model_kind IN ('CHAT', 'EMBEDDING', 'RERANK')),
  CONSTRAINT ck_tenant_model_default CHECK (NOT is_default OR enabled),
  CONSTRAINT ck_tenant_model_fallback CHECK (fallback_version_id IS NULL OR fallback_version_id <> version_id),
  CONSTRAINT ck_tenant_model_enabled CHECK (NOT enabled OR (enabled_by IS NOT NULL AND enabled_at IS NOT NULL)),
  CONSTRAINT fk_tenant_model_fallback_version FOREIGN KEY (fallback_version_id) REFERENCES ph17_assist.model_version (id)
);
CREATE UNIQUE INDEX uq_tenant_model_default ON ph17_assist.tenant_model (tenant_id, model_kind) WHERE is_default AND enabled;
CREATE TRIGGER tg_tenant_model_touch BEFORE UPDATE ON ph17_assist.tenant_model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_model_rules BEFORE INSERT OR UPDATE ON ph17_assist.tenant_model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_tenant_model_rules();
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_model');
COMMENT ON TABLE ph17_assist.tenant_model IS 'EN-17-43 (FR-17-010; BR-17-004, 017, 018). Phiên bản mô hình tenant đã bật, mô hình mặc định và dự phòng theo loại. Bật được khi phiên bản APPROVED; nhà cung cấp EXTERNAL cần chính sách cho phép và danh sách trắng; dự phòng cùng loại, đã duyệt, không từ INTERNAL sang EXTERNAL (ERR-17-016, 017, 030, 034).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.tenant_model CASCADE;

-- @changeset ph17-0280-provider-grant
CREATE TABLE ph17_assist.provider_grant (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  provider_id    uuid NOT NULL,
  change_id      uuid NOT NULL,
  granted_by     varchar(64) NOT NULL,
  effective_from date NOT NULL DEFAULT current_date,
  effective_to   date,
  revoked_at     timestamptz,
  revoked_by     varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_provider_grant PRIMARY KEY (id),
  CONSTRAINT ck_provider_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_provider_grant_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id),
  CONSTRAINT fk_provider_grant_change FOREIGN KEY (tenant_id, change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT ck_provider_grant_period CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CONSTRAINT ck_provider_grant_revoked CHECK ((revoked_at IS NULL) = (revoked_by IS NULL))
);
CREATE UNIQUE INDEX uq_provider_grant_active ON ph17_assist.provider_grant (tenant_id, provider_id) WHERE revoked_at IS NULL;
CREATE TRIGGER tg_provider_grant_touch BEFORE UPDATE ON ph17_assist.provider_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_provider_grant_immutable BEFORE UPDATE ON ph17_assist.provider_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_id', 'change_id', 'granted_by');
CALL ph17_assist.p_enable_rls('ph17_assist.provider_grant');
COMMENT ON TABLE ph17_assist.provider_grant IS 'EN-17-04 Nhà cung cấp ngoài trong danh sách trắng của tenant (FR-17-003; BR-17-004). Chỉ thêm khi có đề nghị EXTERNAL_ON đã duyệt; gỡ ghi revoked_at, không xóa dòng. Mỗi nhà cung cấp một dòng còn hiệu lực.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.provider_grant CASCADE;

-- @changeset ph17-0290-invocation-log
CREATE TABLE ph17_assist.invocation_log (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  capability       varchar(24) NOT NULL,
  model_version_id uuid NOT NULL,
  route_id         uuid,
  caller_kind      varchar(4) NOT NULL,
  caller_ref       varchar(64) NOT NULL,
  message_id       uuid,
  request_ref      varchar(64) NOT NULL,
  tokens_in        integer NOT NULL DEFAULT 0,
  tokens_out       integer NOT NULL DEFAULT 0,
  latency_ms       integer NOT NULL,
  first_token_ms   integer,
  result           varchar(10) NOT NULL,
  error_code       varchar(16),
  fallback_from_id uuid,
  est_cost         numeric(14,4) NOT NULL DEFAULT 0,
  trace_id         char(32) NOT NULL,
  CONSTRAINT pk_invocation_log PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_invocation_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_invocation_log_caller CHECK (caller_kind IN ('USER', 'DU')),
  CONSTRAINT ck_invocation_log_result CHECK (result IN ('OK', 'TIMEOUT', 'ERROR', 'BLOCKED', 'FALLBACK')),
  CONSTRAINT ck_invocation_log_counts CHECK (tokens_in >= 0 AND tokens_out >= 0 AND latency_ms >= 0 AND est_cost >= 0),
  CONSTRAINT ck_invocation_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_invocation_log_fallback CHECK ((result = 'FALLBACK') = (fallback_from_id IS NOT NULL)),
  CONSTRAINT ck_invocation_log_error CHECK (result IN ('OK', 'FALLBACK') OR error_code IS NOT NULL OR result = 'BLOCKED')
) PARTITION BY RANGE (occurred_at);
CALL ph17_assist.p_ensure_partitions('ph17_assist.invocation_log', current_date, 3);
CREATE INDEX ix_invocation_log_model ON ph17_assist.invocation_log (tenant_id, model_version_id, occurred_at DESC);
CREATE INDEX ix_invocation_log_caller ON ph17_assist.invocation_log (tenant_id, caller_kind, caller_ref, occurred_at DESC);
CREATE INDEX ix_invocation_log_message ON ph17_assist.invocation_log (tenant_id, message_id) WHERE message_id IS NOT NULL;
CREATE TRIGGER tg_invocation_log_append_only BEFORE UPDATE OR DELETE ON ph17_assist.invocation_log FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls('ph17_assist.invocation_log');
COMMENT ON TABLE ph17_assist.invocation_log IS 'EN-17-14 Vết một lời gọi mô hình (FR-17-013; BR-17-022, 024, NFR-17-026): mô hình, phiên bản, năng lực, token vào ra, độ trễ, kết quả, người gọi. Không có cột nội dung (nội dung ở message đã che). Chỉ thêm; phân vùng tháng; giữ 13 tháng (giả định, Q17-50).';
COMMENT ON COLUMN ph17_assist.invocation_log.message_id IS 'Tham chiếu logic tới message (không khóa ngoại: nhật ký tồn tại lâu hơn hội thoại).';
COMMENT ON COLUMN ph17_assist.invocation_log.caller_ref IS 'Mã người dùng (sub) hoặc mã DU gọi data plane.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.invocation_log CASCADE;

-- @changeset ph17-0300-model-health-probe
CREATE TABLE ph17_assist.model_health_probe (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  probed_at            timestamptz NOT NULL DEFAULT now(),
  version_id           uuid NOT NULL,
  probe_kind           varchar(10) NOT NULL DEFAULT 'SCHEDULED',
  state                varchar(14) NOT NULL,
  latency_ms           integer,
  consecutive_failures smallint NOT NULL DEFAULT 0,
  consecutive_ok       smallint NOT NULL DEFAULT 0,
  error_code           varchar(16),
  CONSTRAINT pk_model_health_probe PRIMARY KEY (id, probed_at),
  CONSTRAINT ck_model_health_probe_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_model_health_probe_kind CHECK (probe_kind IN ('SCHEDULED', 'MANUAL')),
  CONSTRAINT ck_model_health_probe_state CHECK (state IN ('HEALTHY', 'DEGRADED', 'DOWN', 'BREAKER_OPEN')),
  CONSTRAINT ck_model_health_probe_counts CHECK (consecutive_failures >= 0 AND consecutive_ok >= 0),
  CONSTRAINT ck_model_health_probe_down CHECK (state <> 'DOWN' OR consecutive_failures >= 3)
) PARTITION BY RANGE (probed_at);
CALL ph17_assist.p_ensure_partitions('ph17_assist.model_health_probe', current_date, 3);
CREATE INDEX ix_model_health_probe_version ON ph17_assist.model_health_probe (tenant_id, version_id, probed_at DESC);
CREATE TRIGGER tg_model_health_probe_append_only BEFORE UPDATE OR DELETE ON ph17_assist.model_health_probe FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_health_probe');
COMMENT ON TABLE ph17_assist.model_health_probe IS 'EN-17-15 Kết quả thăm dò sức khỏe mô hình (FR-17-014; BR-17-023): ba lần lỗi liên tiếp thì DOWN và mở cầu dao, hai lần đạt liên tiếp mới trở lại. Chỉ thêm; phân vùng tháng; giữ 3 tháng.';
COMMENT ON COLUMN ph17_assist.model_health_probe.state IS 'HEALTHY, DEGRADED, DOWN, BREAKER_OPEN theo Phụ lục A; FRS 9.3 và BR-17-023 còn dùng UP (Đề nghị đồng bộ).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model_health_probe CASCADE;

-- @changeset ph17-0310-model-breaker
CREATE TABLE ph17_assist.model_breaker (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  version_id    uuid NOT NULL,
  breaker_state varchar(10) NOT NULL DEFAULT 'CLOSED',
  error_rate    numeric(5,2),
  opened_at     timestamptz,
  retry_at      timestamptz,
  reset_by      varchar(64),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_breaker PRIMARY KEY (id),
  CONSTRAINT ck_model_breaker_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_model_breaker_version UNIQUE (tenant_id, version_id),
  CONSTRAINT ck_model_breaker_state CHECK (breaker_state IN ('CLOSED', 'OPEN', 'HALF_OPEN')),
  CONSTRAINT ck_model_breaker_rate CHECK (error_rate IS NULL OR error_rate BETWEEN 0 AND 100),
  CONSTRAINT ck_model_breaker_open CHECK (breaker_state = 'CLOSED' OR opened_at IS NOT NULL)
);
CREATE TRIGGER tg_model_breaker_touch BEFORE UPDATE ON ph17_assist.model_breaker FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.model_breaker');
COMMENT ON TABLE ph17_assist.model_breaker IS 'EN-17-44 (FR-17-012, 014; BR-17-021). Trạng thái cầu dao hiện hành của mỗi phiên bản mô hình: mở khi tỷ lệ lỗi vượt 17.breaker.error-rate trong cửa sổ 30 giây, tự thử lại sau 17.breaker.open-seconds; đóng thủ công qua API-17-055.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.model_breaker CASCADE;


-- @file 17-0040-knowledge.sql
-- @changeset ph17-0320-knowledge-source
CREATE TABLE ph17_assist.knowledge_source (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_code     varchar(64) NOT NULL,
  source_type     varchar(16) NOT NULL,
  name            varchar(255) NOT NULL,
  source_state    varchar(8) NOT NULL DEFAULT 'ACTIVE',
  owner_org_id    varchar(63),
  schedule_cron   varchar(64),
  config          jsonb NOT NULL DEFAULT '{}',
  last_indexed_at timestamptz,
  paused_at       timestamptz,
  retired_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_source PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_knowledge_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_knowledge_source_code CHECK (source_code ~ '^[A-Z][A-Z0-9-]{2,63}$'),
  CONSTRAINT ck_knowledge_source_type CHECK (source_type IN ('API_SPEC', 'RDM_CATALOG', 'FLOW', 'TOPIC', 'ERROR_CODE', 'GUIDE', 'UPLOAD')),
  CONSTRAINT ck_knowledge_source_state CHECK (source_state IN ('ACTIVE', 'PAUSED', 'RETIRED')),
  CONSTRAINT ck_knowledge_source_paused CHECK ((source_state = 'PAUSED') = (paused_at IS NOT NULL)),
  CONSTRAINT ck_knowledge_source_retired CHECK ((source_state = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_knowledge_source_config CHECK (config::text !~* '(bearer |openbao://|password)')
);
CREATE INDEX ix_knowledge_source_type ON ph17_assist.knowledge_source (tenant_id, source_type, source_state);
CREATE TRIGGER tg_knowledge_source_touch BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_source_immutable BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('source_code', 'source_type');
CREATE TRIGGER tg_knowledge_source_fsm_source_state BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('source_state', 'ACTIVE>PAUSED,PAUSED>ACTIVE,ACTIVE>RETIRED,PAUSED>RETIRED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_source');
COMMENT ON TABLE ph17_assist.knowledge_source IS 'EN-17-16 Nguồn tri thức (FR-17-015, 021; BR-17-025, 031): API_SPEC, RDM_CATALOG, FLOW, TOPIC, ERROR_CODE, GUIDE, UPLOAD. Thuộc một tenant hoặc COMMON do PA quản. Chỉ lập chỉ mục siêu dữ liệu và tài liệu, không bản ghi nghiệp vụ. Tạm dừng và ngừng giữ lịch sử.';
COMMENT ON COLUMN ph17_assist.knowledge_source.source_type IS 'Phụ lục A dùng ERROR_CODE và GUIDE; BR-17-025 viết ERR_CATALOG và OPS_GUIDE (Đề nghị đồng bộ).';
COMMENT ON COLUMN ph17_assist.knowledge_source.source_state IS 'ACTIVE, PAUSED, RETIRED (FRS 4.4; SourceState, Phụ lục A).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.knowledge_source CASCADE;

-- @changeset ph17-0330-knowledge-document
CREATE TABLE ph17_assist.knowledge_document (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_id        uuid NOT NULL,
  external_ref     varchar(512) NOT NULL,
  title            varchar(500) NOT NULL,
  class_level      varchar(16),
  class_checked_at timestamptz,
  index_status     varchar(16) NOT NULL DEFAULT 'PENDING',
  content_hash     char(64),
  chunk_count      integer NOT NULL DEFAULT 0,
  skip_reason      varchar(255),
  failure_count    smallint NOT NULL DEFAULT 0,
  last_error_code  varchar(16),
  indexed_at       timestamptz,
  delete_reason    varchar(16),
  owner_org_id     varchar(63),
  file_id          uuid,
  upload_status    varchar(20),
  declared_class   varchar(16),
  uploaded_by      varchar(64),
  approved_by      varchar(64),
  approved_at      timestamptz,
  reject_reason    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_document PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_document_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_document_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_knowledge_document_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT fk_knowledge_document_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT uq_knowledge_document_ref UNIQUE (tenant_id, source_id, external_ref),
  CONSTRAINT ck_knowledge_document_class CHECK (class_level IS NULL OR class_level IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_knowledge_document_status CHECK (index_status IN ('PENDING', 'CLASSIFYING', 'INDEXED', 'SKIPPED_CLASS', 'FAILED', 'DELETED')),
  CONSTRAINT ck_knowledge_document_indexed_class CHECK (index_status <> 'INDEXED' OR class_level IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_document_skipped CHECK (index_status <> 'SKIPPED_CLASS' OR skip_reason IS NOT NULL),
  CONSTRAINT ck_knowledge_document_failed CHECK (index_status <> 'FAILED' OR (failure_count >= 3 AND last_error_code IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_chunks CHECK (chunk_count >= 0 AND (index_status = 'INDEXED' OR chunk_count = 0)),
  CONSTRAINT ck_knowledge_document_hash CHECK (content_hash IS NULL OR content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_knowledge_document_deleted CHECK ((index_status = 'DELETED') = (delete_reason IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_delete_reason CHECK (delete_reason IS NULL OR delete_reason IN ('SOURCE_DELETED', 'REVOKED', 'CLASS_CHANGED', 'SOURCE_RETIRED', 'UPLOAD_STOPPED', 'PURGE')),
  CONSTRAINT ck_knowledge_document_upload CHECK (upload_status IS NULL OR upload_status IN ('UPLOADED', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'STOPPED')),
  CONSTRAINT ck_knowledge_document_declared CHECK (declared_class IS NULL OR declared_class IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_document_upload_fields CHECK (upload_status IS NULL OR (file_id IS NOT NULL AND declared_class IS NOT NULL AND uploaded_by IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_upload_gate CHECK (upload_status IS NULL OR upload_status = 'APPROVED' OR index_status NOT IN ('CLASSIFYING', 'INDEXED')),
  CONSTRAINT ck_knowledge_document_approved CHECK (upload_status <> 'APPROVED' OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND approved_by <> uploaded_by)),
  CONSTRAINT ck_knowledge_document_rejected CHECK (upload_status <> 'REJECTED' OR char_length(COALESCE(reject_reason, '')) >= 20)
);
CREATE INDEX ix_knowledge_document_source ON ph17_assist.knowledge_document (tenant_id, source_id, index_status);
CREATE INDEX ix_knowledge_document_skipped ON ph17_assist.knowledge_document (tenant_id, source_id) WHERE index_status = 'SKIPPED_CLASS';
CREATE INDEX ix_knowledge_document_upload ON ph17_assist.knowledge_document (tenant_id, upload_status) WHERE upload_status IS NOT NULL;
CREATE TRIGGER tg_knowledge_document_touch BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_document_immutable BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('source_id', 'external_ref');
CREATE TRIGGER tg_knowledge_document_fsm_index_status BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('index_status', 'PENDING>CLASSIFYING,CLASSIFYING>INDEXED,CLASSIFYING>SKIPPED_CLASS,PENDING>FAILED,CLASSIFYING>FAILED,INDEXED>PENDING,INDEXED>DELETED,SKIPPED_CLASS>PENDING,FAILED>PENDING');
CREATE TRIGGER tg_knowledge_document_fsm_upload_status BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('upload_status', 'UPLOADED>PENDING_APPROVAL,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,APPROVED>STOPPED,UPLOADED>STOPPED,REJECTED>UPLOADED');
CREATE TRIGGER tg_knowledge_document_purge BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_doc_purge_chunks();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_document');
COMMENT ON TABLE ph17_assist.knowledge_document IS 'EN-17-17 Tài liệu hoặc đối tượng trong nguồn tri thức (FR-17-016…021; BR-17-026, 028, 029, 030). index_status theo máy trạng thái FRS 4.4; chỉ INDEXED khi mức PUBLIC hoặc INTERNAL; SKIPPED_CLASS, DELETED xóa hết đoạn ngay trong giao dịch. Tài liệu tải lên đi qua upload_status và duyệt bốn mắt.';
COMMENT ON COLUMN ph17_assist.knowledge_document.class_level IS 'Mức phân loại do PH-09 trả (DD-08); NULL là chưa xác định, xử lý như không được lập chỉ mục (đóng an toàn).';
COMMENT ON COLUMN ph17_assist.knowledge_document.upload_status IS 'UPLOADED, PENDING_APPROVAL, APPROVED, REJECTED, STOPPED theo Phụ lục A; FRS 4.4 còn nêu DRAFT, RETIRED (Đề nghị đồng bộ).';
COMMENT ON COLUMN ph17_assist.knowledge_document.delete_reason IS 'Lý do xóa vật lý đoạn; DB tự chép sang knowledge_deletion.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.knowledge_document CASCADE;

-- @changeset ph17-0340-knowledge-chunk
CREATE TABLE ph17_assist.knowledge_chunk (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_id        uuid NOT NULL,
  document_id      uuid NOT NULL,
  chunk_no         integer NOT NULL,
  content          text NOT NULL,
  content_norm     text NOT NULL,
  content_tsv      tsvector GENERATED ALWAYS AS (to_tsvector('simple', content_norm)) STORED,
  embedding        real[] NOT NULL,
  embed_version_id uuid NOT NULL,
  class_level      varchar(16) NOT NULL,
  acl              jsonb NOT NULL,
  content_hash     char(64) NOT NULL,
  token_count      integer NOT NULL,
  object_ref       varchar(512),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_chunk PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_chunk_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_chunk_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_knowledge_chunk_document FOREIGN KEY (tenant_id, document_id) REFERENCES ph17_assist.knowledge_document (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_knowledge_chunk_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT fk_knowledge_chunk_embed_version FOREIGN KEY (embed_version_id) REFERENCES ph17_assist.model_version (id),
  CONSTRAINT uq_knowledge_chunk_no UNIQUE (tenant_id, document_id, chunk_no, embed_version_id),
  CONSTRAINT ck_knowledge_chunk_class CHECK (class_level IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_chunk_no CHECK (chunk_no >= 0 AND token_count BETWEEN 1 AND 2000),
  CONSTRAINT ck_knowledge_chunk_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_knowledge_chunk_acl CHECK (jsonb_typeof(acl) = 'object' AND acl ->> 'visibility' IN ('TENANT', 'ORG', 'ROLE') AND (acl ->> 'visibility' <> 'ORG' OR jsonb_array_length(COALESCE(acl -> 'orgIds', '[]'::jsonb)) >= 1)),
  CONSTRAINT ck_knowledge_chunk_content CHECK (char_length(content) BETWEEN 1 AND 20000)
);
CREATE INDEX ix_knowledge_chunk_source ON ph17_assist.knowledge_chunk (tenant_id, source_id);
CREATE INDEX ix_knowledge_chunk_embed ON ph17_assist.knowledge_chunk (tenant_id, embed_version_id);
CREATE INDEX ix_knowledge_chunk_hash ON ph17_assist.knowledge_chunk (tenant_id, content_hash);
CREATE INDEX ix_knowledge_chunk_tsv ON ph17_assist.knowledge_chunk USING gin (content_tsv);
CREATE TRIGGER tg_knowledge_chunk_touch BEFORE UPDATE ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_chunk_immutable BEFORE UPDATE ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('document_id', 'embed_version_id', 'content_hash');
CREATE TRIGGER tg_knowledge_chunk_gate BEFORE INSERT ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_chunk_gate();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_chunk');
COMMENT ON TABLE ph17_assist.knowledge_chunk IS 'EN-17-18 Đoạn tri thức đã nhúng (FR-17-018, 019, 023, 024; BR-17-016, 026, 027, 034). Mỗi đoạn có tenant_id, nguồn, phạm vi quyền đọc acl, class_level chỉ PUBLIC hoặc INTERNAL, embed_model_version_id, content_hash. embedding là vector(1024) khi có pgvector (ADR-170); trên CI chỉ real[]. Đoạn COMMON chỉ đọc với tenant.';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.embedding IS 'vector(1024) khi có pgvector (đổi kiểu và chỉ mục HNSW vector_cosine_ops ở bước 17-0031-pgvector); real[] chỉ để CI trên postgres:16 không có pgvector.';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.content_norm IS 'Nội dung không dấu, chữ thường, dùng cho tìm từ khóa (tsvector cấu hình simple).';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.acl IS 'Phạm vi quyền đọc: visibility TENANT, ORG (orgIds) hoặc ROLE (roles); truy hồi lọc theo acl rồi xác minh quyền người hỏi (BR-17-035).';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.embed_version_id IS 'Phiên bản mô hình nhúng; không trộn vector của hai phiên bản trong một truy hồi (BR-17-016).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.knowledge_chunk CASCADE;

-- @changeset ph17-0350-index-job
CREATE TABLE ph17_assist.index_job (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  source_id      uuid,
  document_id    uuid,
  job_kind       varchar(8) NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'QUEUED',
  trigger_ref    varchar(128) NOT NULL,
  attempt        smallint NOT NULL DEFAULT 1,
  docs_added     integer NOT NULL DEFAULT 0,
  docs_deleted   integer NOT NULL DEFAULT 0,
  docs_skipped   integer NOT NULL DEFAULT 0,
  docs_failed    integer NOT NULL DEFAULT 0,
  chunks_added   integer NOT NULL DEFAULT 0,
  chunks_deleted integer NOT NULL DEFAULT 0,
  started_at     timestamptz,
  finished_at    timestamptz,
  error_code     varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_index_job PRIMARY KEY (id),
  CONSTRAINT uq_index_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_index_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_index_job_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT ck_index_job_kind CHECK (job_kind IN ('EVENT', 'FULL', 'DELETE')),
  CONSTRAINT ck_index_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'DONE', 'FAILED')),
  CONSTRAINT ck_index_job_attempt CHECK (attempt BETWEEN 1 AND 3),
  CONSTRAINT ck_index_job_counts CHECK (docs_added >= 0 AND docs_deleted >= 0 AND docs_skipped >= 0 AND docs_failed >= 0 AND chunks_added >= 0 AND chunks_deleted >= 0),
  CONSTRAINT ck_index_job_finished CHECK ((status IN ('DONE', 'FAILED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_index_job_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_index_job_scope CHECK (source_id IS NOT NULL OR job_kind = 'FULL')
);
CREATE UNIQUE INDEX uq_index_job_full_running ON ph17_assist.index_job (tenant_id, source_id) WHERE job_kind = 'FULL' AND status IN ('QUEUED', 'RUNNING') AND source_id IS NOT NULL;
CREATE INDEX ix_index_job_source ON ph17_assist.index_job (tenant_id, source_id, created_at DESC);
CREATE INDEX ix_index_job_status ON ph17_assist.index_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_index_job_touch BEFORE UPDATE ON ph17_assist.index_job FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_index_job_fsm_status BEFORE UPDATE ON ph17_assist.index_job FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'QUEUED>RUNNING,RUNNING>DONE,RUNNING>FAILED,QUEUED>FAILED');
CALL ph17_assist.p_enable_rls('ph17_assist.index_job');
COMMENT ON TABLE ph17_assist.index_job IS 'EN-17-19 Lượt lập chỉ mục: theo sự kiện (EVENT), toàn bộ (FULL), xóa (DELETE) (FR-17-017, 021; BR-17-028). Lỗi thử lại ba lần có lùi mũ rồi FAILED, không chặn nguồn khác. Một nguồn chỉ một lượt FULL đang chạy (ERR-17-044).';
COMMENT ON COLUMN ph17_assist.index_job.trigger_ref IS 'Mã sự kiện nguồn (event_id), CRON hoặc mã người yêu cầu.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.index_job CASCADE;

-- @changeset ph17-0360-knowledge-deletion
CREATE TABLE ph17_assist.knowledge_deletion (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  source_id      uuid,
  document_id    uuid,
  reason         varchar(16) NOT NULL,
  chunks_deleted integer NOT NULL,
  trigger_ref    varchar(128),
  requested_at   timestamptz NOT NULL DEFAULT now(),
  completed_at   timestamptz NOT NULL DEFAULT now(),
  latency_ms     integer,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_deletion PRIMARY KEY (id),
  CONSTRAINT ck_knowledge_deletion_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_knowledge_deletion_reason CHECK (reason IN ('SOURCE_DELETED', 'REVOKED', 'CLASS_CHANGED', 'SOURCE_RETIRED', 'UPLOAD_STOPPED', 'PURGE')),
  CONSTRAINT ck_knowledge_deletion_count CHECK (chunks_deleted >= 0),
  CONSTRAINT ck_knowledge_deletion_time CHECK (completed_at >= requested_at)
);
CREATE INDEX ix_knowledge_deletion_doc ON ph17_assist.knowledge_deletion (tenant_id, document_id, completed_at DESC);
CREATE TRIGGER tg_knowledge_deletion_touch BEFORE UPDATE ON ph17_assist.knowledge_deletion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_deletion_append_only BEFORE UPDATE OR DELETE ON ph17_assist.knowledge_deletion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_deletion');
COMMENT ON TABLE ph17_assist.knowledge_deletion IS 'EN-17-45 (FR-17-019; BR-17-029). Nhật ký xóa lan truyền đoạn khỏi chỉ mục: mỗi lần xóa ghi lý do, số đoạn, độ trễ để chứng minh ≤ 60 giây (đổi phân loại, thu hồi) hoặc ≤ 5 phút (xóa nguồn). Chỉ thêm; không chứa nội dung đoạn.';
COMMENT ON COLUMN ph17_assist.knowledge_deletion.document_id IS 'Tham chiếu logic (tài liệu có thể đã bị xóa vật lý).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.knowledge_deletion CASCADE;


-- @file 17-0045-pgvector.sql
-- @changeset ph17-0350-pgvector splitStatements:false
-- Có pgvector: đổi embedding sang vector(1024) và dựng chỉ mục HNSW theo cosine (ADR-170, NFR-17-025). Không có (CI): giữ real[].
DO $vec$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
    EXECUTE 'ALTER TABLE ph17_assist.knowledge_chunk ALTER COLUMN embedding TYPE vector(1024) USING embedding::vector(1024)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS ix_knowledge_chunk_embedding ON ph17_assist.knowledge_chunk USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)';
  ELSE
    RAISE NOTICE 'Không có pgvector: embedding giữ real[] (chỉ để CI, ADR-170).';
  END IF;
END
$vec$;
-- @rollback -- Không đổi kiểu ngược khi rollback.


-- @file 17-0050-chat.sql
-- @changeset ph17-0370-conversation
CREATE TABLE ph17_assist.conversation (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  user_id            varchar(64) NOT NULL,
  title              varchar(200),
  state              varchar(16) NOT NULL DEFAULT 'ACTIVE',
  screen_context     jsonb NOT NULL DEFAULT '{}',
  message_count      integer NOT NULL DEFAULT 0,
  last_message_at    timestamptz,
  expires_at         timestamptz NOT NULL,
  deleted_by_user_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_conversation PRIMARY KEY (id),
  CONSTRAINT uq_conversation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_conversation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_conversation_state CHECK (state IN ('ACTIVE', 'DELETED_BY_USER', 'EXPIRED')),
  CONSTRAINT ck_conversation_ctx CHECK (ph17_assist.fn_ctx_ok(screen_context)),
  CONSTRAINT ck_conversation_retention CHECK (expires_at >= created_at + interval '90 days'),
  CONSTRAINT ck_conversation_deleted CHECK ((state = 'DELETED_BY_USER') = (deleted_by_user_at IS NOT NULL)),
  CONSTRAINT ck_conversation_count CHECK (message_count >= 0)
);
CREATE INDEX ix_conversation_user ON ph17_assist.conversation (tenant_id, user_id, last_message_at DESC) WHERE state = 'ACTIVE';
CREATE INDEX ix_conversation_expires ON ph17_assist.conversation (tenant_id, expires_at);
CREATE TRIGGER tg_conversation_touch BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_conversation_immutable BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('user_id');
CREATE TRIGGER tg_conversation_fsm_state BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'ACTIVE>DELETED_BY_USER,ACTIVE>EXPIRED');
CALL ph17_assist.p_enable_rls_user('ph17_assist.conversation', 'ph17_assist.fn_log_grant_ok(id, created_at)', 'expires_at <= now()');
COMMENT ON TABLE ph17_assist.conversation IS 'EN-17-20 Hội thoại của một người dùng (FR-17-022, 027; BR-17-032, 033, 039). RLS theo người dùng: chỉ chủ hội thoại đọc; SO và AUDITOR đọc khi có phiếu truy cập còn hiệu lực. expires_at tối thiểu 90 ngày; xóa vật lý chỉ khi hết hạn. Ngữ cảnh màn hình chỉ có route, mã đối tượng, mã lỗi, tab.';
COMMENT ON COLUMN ph17_assist.conversation.screen_context IS 'Chỉ khóa route, objectId, errorCode, tab; không giá trị dữ liệu đang hiển thị (BR-17-032, fn_ctx_ok).';
COMMENT ON COLUMN ph17_assist.conversation.expires_at IS 'Hạn xóa vật lý = created_at cộng 17.log.retention-days ngày, sàn 90.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.conversation CASCADE;

-- @changeset ph17-0380-message
CREATE TABLE ph17_assist.message (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  conversation_id   uuid NOT NULL,
  user_id           varchar(64) NOT NULL,
  seq               integer NOT NULL,
  role              varchar(10) NOT NULL,
  content_masked    text NOT NULL,
  masked            boolean NOT NULL DEFAULT true,
  redaction_count   integer NOT NULL DEFAULT 0,
  outcome           varchar(16),
  capability        varchar(16),
  model_version_id  uuid,
  prompt_version_id uuid,
  tokens_in         integer,
  tokens_out        integer,
  truncated         boolean NOT NULL DEFAULT false,
  guardrail_codes   varchar(48)[],
  dedup_id          uuid,
  latency_ms        integer,
  trace_id          char(32),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_message PRIMARY KEY (id),
  CONSTRAINT uq_message_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_message_conversation FOREIGN KEY (tenant_id, conversation_id) REFERENCES ph17_assist.conversation (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_message_seq UNIQUE (tenant_id, conversation_id, seq),
  CONSTRAINT ck_message_role CHECK (role IN ('USER', 'ASSISTANT', 'TOOL')),
  CONSTRAINT ck_message_outcome CHECK (outcome IS NULL OR outcome IN ('ANSWERED', 'NO_SOURCE', 'BLOCKED_INPUT', 'BLOCKED_OUTPUT', 'QUOTA', 'CANCELLED', 'ERROR')),
  CONSTRAINT ck_message_outcome_role CHECK ((role = 'ASSISTANT') = (outcome IS NOT NULL)),
  CONSTRAINT ck_message_masked CHECK (masked),
  CONSTRAINT ck_message_seq CHECK (seq >= 1),
  CONSTRAINT ck_message_size CHECK (char_length(content_masked) <= 40000),
  CONSTRAINT ck_message_capability CHECK (capability IS NULL OR capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_message_counts CHECK (redaction_count >= 0 AND COALESCE(tokens_in, 0) >= 0 AND COALESCE(tokens_out, 0) >= 0),
  CONSTRAINT ck_message_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_message_no_secret CHECK (content_masked !~* '(bearer +[a-z0-9._~+/=-]{20,}|begin [a-z ]*private key)')
);
CREATE UNIQUE INDEX uq_message_dedup ON ph17_assist.message (tenant_id, conversation_id, dedup_id) WHERE dedup_id IS NOT NULL;
CREATE INDEX ix_message_conversation ON ph17_assist.message (tenant_id, conversation_id, seq);
CREATE INDEX ix_message_outcome ON ph17_assist.message (tenant_id, created_at, outcome) WHERE role = 'ASSISTANT';
CREATE TRIGGER tg_message_touch BEFORE UPDATE ON ph17_assist.message FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_message_immutable BEFORE UPDATE ON ph17_assist.message FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('conversation_id', 'user_id', 'seq', 'role', 'content_masked');
CALL ph17_assist.p_enable_rls_user('ph17_assist.message', 'ph17_assist.fn_log_grant_ok(conversation_id, created_at)', 'false');
COMMENT ON TABLE ph17_assist.message IS 'EN-17-21 Tin nhắn người dùng, trợ lý, công cụ ĐÃ CHE trước khi lưu (FR-17-022…027, 055; BR-17-073). Không lưu token, không lưu nội dung chưa che (cờ masked luôn đúng). outcome ghi kết quả câu trả lời; dedup_id chống gửi trùng trong 5 phút (BR-17-087). RLS theo người dùng.';
COMMENT ON COLUMN ph17_assist.message.masked IS 'Luôn đúng: tầng ứng dụng che DLCN, bí mật trước khi ghi (FR-17-041, 045, 046).';
COMMENT ON COLUMN ph17_assist.message.dedup_id IS 'Từ tiêu đề Idempotency-Key; hiệu lực chống trùng 5 phút do tầng ứng dụng kiểm.';
COMMENT ON COLUMN ph17_assist.message.guardrail_codes IS 'Mã quy tắc bộ lọc đã kích hoạt (guardrail_rule.rule_code).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.message CASCADE;

-- @changeset ph17-0390-citation
CREATE TABLE ph17_assist.citation (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  message_id uuid NOT NULL,
  user_id    varchar(64) NOT NULL,
  rank       smallint NOT NULL,
  chunk_id   uuid,
  source_id  uuid,
  object_ref varchar(512) NOT NULL,
  link_route varchar(512) NOT NULL,
  score      numeric(5,4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_citation PRIMARY KEY (id),
  CONSTRAINT ck_citation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_citation_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph17_assist.message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_citation_rank UNIQUE (tenant_id, message_id, rank),
  CONSTRAINT ck_citation_rank CHECK (rank >= 1),
  CONSTRAINT ck_citation_route CHECK (link_route ~ '^/[A-Za-z0-9/_.:~%@!$&=+,;-]*(\?[A-Za-z0-9/_.:~%@!$&=+,;-]*)?(#[A-Za-z0-9_.-]*)?$' AND link_route !~ '^//'),
  CONSTRAINT ck_citation_score CHECK (score BETWEEN 0 AND 1)
);
CREATE INDEX ix_citation_message ON ph17_assist.citation (tenant_id, message_id);
CREATE TRIGGER tg_citation_touch BEFORE UPDATE ON ph17_assist.citation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.citation', 'false', 'false');
COMMENT ON TABLE ph17_assist.citation IS 'EN-17-22 Trích dẫn của một câu trả lời (FR-17-025; BR-17-036, 037): đoạn, đối tượng, liên kết nội bộ, điểm. Liên kết chỉ là route nội bộ của cổng Datahub; liên kết ngoài bị bỏ. chunk_id là tham chiếu logic vì đoạn có thể bị xóa lan truyền.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.citation CASCADE;

-- @changeset ph17-0400-tool-definition
CREATE TABLE ph17_assist.tool_definition (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  tool_code       varchar(32) NOT NULL,
  name            varchar(255) NOT NULL,
  target_module   varchar(8) NOT NULL,
  target_ref      varchar(128) NOT NULL,
  scope           varchar(64) NOT NULL,
  capabilities    varchar(16)[] NOT NULL,
  enabled         boolean NOT NULL DEFAULT false,
  read_only       boolean NOT NULL DEFAULT true,
  timeout_seconds smallint,
  enabled_by      varchar(64),
  enabled_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tool_definition PRIMARY KEY (id),
  CONSTRAINT uq_tool_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tool_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tool_definition_code UNIQUE (tenant_id, tool_code),
  CONSTRAINT ck_tool_definition_code CHECK (tool_code ~ '^[A-Z][A-Z0-9_]{2,31}$'),
  CONSTRAINT ck_tool_definition_module CHECK (target_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_tool_definition_read_only CHECK (read_only),
  CONSTRAINT ck_tool_definition_scope CHECK (scope ~ '^[a-z0-9-]+:read$'),
  CONSTRAINT ck_tool_definition_caps CHECK (cardinality(capabilities) >= 1 AND capabilities <@ ARRAY['SEARCH', 'MAPPING', 'EXPLAIN']::varchar[]),
  CONSTRAINT ck_tool_definition_timeout CHECK (timeout_seconds IS NULL OR timeout_seconds BETWEEN 3 AND 30),
  CONSTRAINT ck_tool_definition_enabled CHECK (NOT enabled OR (enabled_by IS NOT NULL AND enabled_at IS NOT NULL))
);
CREATE TRIGGER tg_tool_definition_touch BEFORE UPDATE ON ph17_assist.tool_definition FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tool_definition_immutable BEFORE UPDATE ON ph17_assist.tool_definition FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('tool_code', 'target_module', 'target_ref', 'scope', 'read_only');
CALL ph17_assist.p_enable_rls('ph17_assist.tool_definition');
COMMENT ON TABLE ph17_assist.tool_definition IS 'EN-17-23 Công cụ của trợ lý (FR-17-042, 047; BR-17-056, 057): danh mục cố định theo mã nguồn, mỗi tenant chỉ bật hoặc tắt. read_only luôn đúng, scope luôn kết thúc :read, không có công cụ ghi; gọi bằng token của người dùng qua token exchange RFC 8693, không quyền riêng của dh-assist.';
COMMENT ON COLUMN ph17_assist.tool_definition.target_ref IS 'Tên thao tác đọc của phân hệ đích (ví dụ catalog.search-apis); ánh xạ sang mã API-nn khi phân hệ đích công bố (Q17-51).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.tool_definition CASCADE;

-- @changeset ph17-0410-tool-call
CREATE TABLE ph17_assist.tool_call (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  message_id     uuid NOT NULL,
  user_id        varchar(64) NOT NULL,
  tool_code      varchar(32) NOT NULL,
  depth          smallint NOT NULL DEFAULT 1,
  args_masked    jsonb NOT NULL DEFAULT '{}',
  result_summary varchar(4000),
  outcome        varchar(8) NOT NULL,
  duration_ms    integer NOT NULL,
  error_code     varchar(16),
  act_subject    varchar(16) NOT NULL DEFAULT 'dh-assist',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tool_call PRIMARY KEY (id),
  CONSTRAINT ck_tool_call_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_tool_call_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph17_assist.message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_tool_call_depth CHECK (depth BETWEEN 1 AND 5),
  CONSTRAINT ck_tool_call_outcome CHECK (outcome IN ('OK', 'TIMEOUT', 'DENIED', 'ERROR')),
  CONSTRAINT ck_tool_call_act CHECK (act_subject = 'dh-assist'),
  CONSTRAINT ck_tool_call_duration CHECK (duration_ms >= 0),
  CONSTRAINT ck_tool_call_no_token CHECK (args_masked::text !~* '(bearer |access_token|refresh_token)')
);
CREATE INDEX ix_tool_call_message ON ph17_assist.tool_call (tenant_id, message_id);
CREATE INDEX ix_tool_call_tool ON ph17_assist.tool_call (tenant_id, tool_code, created_at DESC);
CREATE TRIGGER tg_tool_call_touch BEFORE UPDATE ON ph17_assist.tool_call FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.tool_call', 'false', 'false');
COMMENT ON TABLE ph17_assist.tool_call IS 'EN-17-24 Một lần gọi công cụ trong lượt (FR-17-043, 047; BR-17-047, 057, 061): tham số đã che, tóm tắt kết quả, thời gian, mã lỗi. Không lưu token trao đổi; act_subject luôn dh-assist. Độ sâu 1…5. RLS theo người dùng.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.tool_call CASCADE;

-- @changeset ph17-0420-suggestion
CREATE TABLE ph17_assist.suggestion (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  user_id                 varchar(64) NOT NULL,
  kind                    varchar(18) NOT NULL,
  status                  varchar(10) NOT NULL DEFAULT 'PROPOSED',
  conversation_id         uuid,
  message_id              uuid,
  host_module             varchar(8),
  host_ref                varchar(255),
  host_etag               varchar(128),
  payload                 jsonb NOT NULL,
  confidence              numeric(3,2) NOT NULL,
  rationale               varchar(4000) NOT NULL,
  diff_masked             jsonb,
  human_decision_required boolean NOT NULL DEFAULT true,
  expires_at              timestamptz NOT NULL,
  decided_by              varchar(64),
  decided_at              timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suggestion PRIMARY KEY (id),
  CONSTRAINT uq_suggestion_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_suggestion_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suggestion_kind CHECK (kind IN ('FIELD_MAPPING', 'CODE_MAPPING', 'REMEDIATION', 'BPM_STEP', 'INCIDENT_SUMMARY')),
  CONSTRAINT ck_suggestion_status CHECK (status IN ('PROPOSED', 'ACCEPTED', 'EDITED', 'REJECTED', 'EXPIRED')),
  CONSTRAINT ck_suggestion_confidence CHECK (confidence BETWEEN 0 AND 1),
  CONSTRAINT ck_suggestion_host CHECK (host_module IS NULL OR host_module IN ('PH04', 'PH07', 'PH11', 'PH18')),
  CONSTRAINT ck_suggestion_human CHECK (human_decision_required),
  CONSTRAINT ck_suggestion_decided CHECK ((status IN ('ACCEPTED', 'EDITED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_suggestion_edited CHECK (status <> 'EDITED' OR diff_masked IS NOT NULL),
  CONSTRAINT ck_suggestion_applied CHECK (status NOT IN ('ACCEPTED', 'EDITED') OR (host_module IS NOT NULL AND host_ref IS NOT NULL AND host_etag IS NOT NULL)),
  CONSTRAINT ck_suggestion_no_apply CHECK (kind NOT IN ('REMEDIATION', 'INCIDENT_SUMMARY') OR status IN ('PROPOSED', 'EXPIRED', 'REJECTED')),
  CONSTRAINT ck_suggestion_ttl CHECK (expires_at > created_at)
);
CREATE INDEX ix_suggestion_user ON ph17_assist.suggestion (tenant_id, user_id, created_at DESC);
CREATE INDEX ix_suggestion_status ON ph17_assist.suggestion (tenant_id, status, expires_at);
CREATE INDEX ix_suggestion_host ON ph17_assist.suggestion (tenant_id, host_module, host_ref);
CREATE TRIGGER tg_suggestion_touch BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_suggestion_immutable BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('user_id', 'kind', 'payload', 'confidence', 'host_etag');
CREATE TRIGGER tg_suggestion_fsm_status BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PROPOSED>ACCEPTED,PROPOSED>EDITED,PROPOSED>REJECTED,PROPOSED>EXPIRED');
CALL ph17_assist.p_enable_rls_user('ph17_assist.suggestion', 'false', 'false');
COMMENT ON TABLE ph17_assist.suggestion IS 'EN-17-25 Gợi ý của trợ lý (FR-17-030…035, 061; BR-17-043…049, 083): ánh xạ trường, mã, khắc phục, bước quy trình, tóm tắt. PROPOSED, ACCEPTED, EDITED, REJECTED, EXPIRED theo FRS 4.5; chỉ ghi vào phân hệ chủ bằng quyền người dùng; khắc phục và tóm tắt không có áp dụng. Gợi ý bước quy trình luôn cần người quyết định.';
COMMENT ON COLUMN ph17_assist.suggestion.host_etag IS 'ETag của bản nháp ở phân hệ chủ lúc tạo thẻ; bản nháp đổi thì ERR-17-056 (BR-17-048).';
COMMENT ON COLUMN ph17_assist.suggestion.diff_masked IS 'Phần khác biệt đã che khi người dùng sửa (EDITED), chỉ để đo chất lượng, không huấn luyện (BR-17-049).';
COMMENT ON COLUMN ph17_assist.suggestion.payload IS 'Nội dung đề xuất (biểu thức JQ, mã chuẩn, danh sách kiểm); không giá trị dữ liệu thật (BR-17-043).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.suggestion CASCADE;

-- @changeset ph17-0430-explanation
CREATE TABLE ph17_assist.explanation (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  user_id           varchar(64) NOT NULL,
  kind              varchar(16) NOT NULL,
  subject_ref       varchar(255) NOT NULL,
  content_masked    text NOT NULL,
  masked            boolean NOT NULL DEFAULT true,
  sources           jsonb NOT NULL DEFAULT '[]',
  model_version_id  uuid,
  prompt_version_id uuid,
  expires_at        timestamptz NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_explanation PRIMARY KEY (id),
  CONSTRAINT ck_explanation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_explanation_kind CHECK (kind IN ('ERROR_CODE', 'TRACE', 'DLQ_MESSAGE', 'REMEDIATION', 'INCIDENT_SUMMARY')),
  CONSTRAINT ck_explanation_masked CHECK (masked),
  CONSTRAINT ck_explanation_ttl CHECK (expires_at > created_at)
);
CREATE INDEX ix_explanation_user ON ph17_assist.explanation (tenant_id, user_id, created_at DESC);
CREATE TRIGGER tg_explanation_touch BEFORE UPDATE ON ph17_assist.explanation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.explanation', 'false', 'expires_at <= now()');
COMMENT ON TABLE ph17_assist.explanation IS 'EN-17-46 (FR-17-036…040, API-17-113…118). Một lần giải thích mã lỗi, trace_id, bản tin DLQ, danh sách kiểm khắc phục hoặc tóm tắt sự cố: nội dung ĐÃ CHE, nguồn trích, mô hình và prompt dùng. Lấy lại được tới hết hạn (API-17-116). RLS theo người dùng.';
COMMENT ON COLUMN ph17_assist.explanation.kind IS 'Đề nghị bổ sung ExplanationKind vào Phụ lục A.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.explanation CASCADE;

-- @changeset ph17-0440-suggested-question
CREATE TABLE ph17_assist.suggested_question (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  question_text varchar(300) NOT NULL,
  route_pattern varchar(255) NOT NULL,
  role_group    varchar(32) NOT NULL DEFAULT 'ALL_READERS',
  capability    varchar(16) NOT NULL,
  enabled       boolean NOT NULL DEFAULT true,
  sort_no       smallint NOT NULL DEFAULT 100,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suggested_question PRIMARY KEY (id),
  CONSTRAINT ck_suggested_question_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suggested_question_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_suggested_question_route CHECK (route_pattern ~ '^/[A-Za-z0-9/_*:{}-]*$'),
  CONSTRAINT ck_suggested_question_text CHECK (char_length(question_text) >= 5)
);
CREATE INDEX ix_suggested_question_route ON ph17_assist.suggested_question (tenant_id, capability, enabled, route_pattern);
CREATE TRIGGER tg_suggested_question_touch BEFORE UPDATE ON ph17_assist.suggested_question FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.suggested_question');
COMMENT ON TABLE ph17_assist.suggested_question IS 'EN-17-47 (FR-17-028; BR-17-040). Danh mục câu hỏi mẫu theo route và nhóm vai trò, không sinh bằng mô hình; chỉ hiện câu thuộc năng lực đang bật. TA thêm, sửa, ngừng.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.suggested_question CASCADE;


-- @file 17-0060-guard.sql
-- @changeset ph17-0450-guardrail-rule
CREATE TABLE ph17_assist.guardrail_rule (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  rule_code      varchar(48) NOT NULL,
  guardrail_kind varchar(8) NOT NULL,
  action         varchar(8) NOT NULL,
  category       varchar(20) NOT NULL,
  pattern_kind   varchar(10) NOT NULL,
  pattern        text NOT NULL,
  description    varchar(1000),
  enabled        boolean NOT NULL DEFAULT true,
  builtin        boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_guardrail_rule PRIMARY KEY (id),
  CONSTRAINT uq_guardrail_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_guardrail_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_guardrail_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT ck_guardrail_rule_code CHECK (rule_code ~ '^GR-(IN|OUT)-[A-Z0-9-]{3,40}$'),
  CONSTRAINT ck_guardrail_rule_kind CHECK (guardrail_kind IN ('INPUT', 'OUTPUT')),
  CONSTRAINT ck_guardrail_rule_action CHECK (action IN ('BLOCK', 'MASK', 'WARN')),
  CONSTRAINT ck_guardrail_rule_category CHECK (category IN ('PROMPT_INJECTION', 'FORBIDDEN', 'PII', 'SECRET', 'LINK')),
  CONSTRAINT ck_guardrail_rule_pattern_kind CHECK (pattern_kind IN ('REGEX', 'KEYWORD', 'DETECTOR')),
  CONSTRAINT ck_guardrail_rule_kind_code CHECK ((guardrail_kind = 'INPUT') = (rule_code LIKE 'GR-IN-%')),
  CONSTRAINT ck_guardrail_rule_secret_blocks CHECK (category <> 'SECRET' OR (guardrail_kind = 'OUTPUT' AND action = 'BLOCK')),
  CONSTRAINT ck_guardrail_rule_inject_blocks CHECK (category NOT IN ('PROMPT_INJECTION', 'FORBIDDEN') OR (guardrail_kind = 'INPUT' AND action = 'BLOCK')),
  CONSTRAINT ck_guardrail_rule_pattern CHECK (char_length(pattern) BETWEEN 1 AND 4000)
);
CREATE INDEX ix_guardrail_rule_kind ON ph17_assist.guardrail_rule (tenant_id, guardrail_kind, enabled);
CREATE TRIGGER tg_guardrail_rule_touch BEFORE UPDATE ON ph17_assist.guardrail_rule FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_guardrail_rule_immutable BEFORE UPDATE ON ph17_assist.guardrail_rule FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('rule_code', 'guardrail_kind', 'builtin');
CALL ph17_assist.p_enable_rls('ph17_assist.guardrail_rule');
COMMENT ON TABLE ph17_assist.guardrail_rule IS 'EN-17-38 Quy tắc bộ lọc vào hoặc ra (FR-17-044…046; BR-17-059, 060, 063): loại INPUT hoặc OUTPUT, mẫu (REGEX, KEYWORD hoặc bộ phát hiện), hành động BLOCK, MASK, WARN. Quy tắc dựng sẵn (builtin) không xóa, không đổi mã; chỉ tắt, bật có kiểm toán.';
COMMENT ON COLUMN ph17_assist.guardrail_rule.pattern IS 'REGEX hoặc từ khóa; với DETECTOR là mã bộ phát hiện (injection-classifier, sensitive-pii). Mẫu bí mật chỉ mô tả dạng, không giá trị thật.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.guardrail_rule CASCADE;

-- @changeset ph17-0460-link-allowlist
CREATE TABLE ph17_assist.link_allowlist (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  route_prefix varchar(255) NOT NULL,
  enabled      boolean NOT NULL DEFAULT true,
  note         varchar(255),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_link_allowlist PRIMARY KEY (id),
  CONSTRAINT ck_link_allowlist_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_link_allowlist_prefix UNIQUE (tenant_id, route_prefix),
  CONSTRAINT ck_link_allowlist_route CHECK (route_prefix ~ '^/[A-Za-z0-9/_.-]*$')
);
CREATE TRIGGER tg_link_allowlist_touch BEFORE UPDATE ON ph17_assist.link_allowlist FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.link_allowlist');
COMMENT ON TABLE ph17_assist.link_allowlist IS 'EN-17-48 (FR-17-046; BR-17-037). Danh sách trắng route nội bộ của cổng Datahub được phép xuất hiện trong câu trả lời; liên kết ngoài danh sách bị bỏ và ghi nhật ký lọc.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.link_allowlist CASCADE;


-- @file 17-0070-eval.sql
-- @changeset ph17-0470-prompt-template
CREATE TABLE ph17_assist.prompt_template (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  template_code varchar(48) NOT NULL,
  capability    varchar(16) NOT NULL,
  name          varchar(255) NOT NULL,
  description   varchar(2000),
  retired_at    timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_prompt_template PRIMARY KEY (id),
  CONSTRAINT uq_prompt_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_prompt_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_prompt_template_code UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_prompt_template_code CHECK (template_code ~ '^[A-Z][A-Z0-9-]{2,47}$'),
  CONSTRAINT ck_prompt_template_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN'))
);
CREATE TRIGGER tg_prompt_template_touch BEFORE UPDATE ON ph17_assist.prompt_template FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_prompt_template_immutable BEFORE UPDATE ON ph17_assist.prompt_template FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('template_code', 'capability');
CALL ph17_assist.p_enable_rls_common('ph17_assist.prompt_template');
COMMENT ON TABLE ph17_assist.prompt_template IS 'EN-17-26 Mẫu chỉ dẫn hệ thống (system prompt) theo năng lực (FR-17-049; BR-17-064). Mẫu là vỏ; nội dung nằm ở prompt_version. Mẫu dùng chung do PA quản có tenant_id COMMON.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.prompt_template CASCADE;

-- @changeset ph17-0480-prompt-version
CREATE TABLE ph17_assist.prompt_version (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  template_id      uuid NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  content_text     text NOT NULL,
  content_hash     char(64) NOT NULL,
  eval_run_id      uuid,
  redteam_run_id   uuid,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_prompt_version PRIMARY KEY (id),
  CONSTRAINT uq_prompt_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_prompt_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_prompt_version_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph17_assist.prompt_template (tenant_id, id),
  CONSTRAINT uq_prompt_version_no UNIQUE (tenant_id, template_id, version_no),
  CONSTRAINT ck_prompt_version_version CHECK (version_no >= 1),
  CONSTRAINT ck_prompt_version_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_prompt_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_prompt_version_content CHECK (char_length(content_text) BETWEEN 20 AND 20000 AND content_text !~ '([0-9]{1,3}\.){3}[0-9]{1,3}' AND content_text !~* '(openbao://|bearer +[a-z0-9._-]{10,}|password *[:=])'),
  CONSTRAINT ck_prompt_version_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_prompt_version_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL AND eval_run_id IS NOT NULL AND redteam_run_id IS NOT NULL)),
  CONSTRAINT ck_prompt_version_reject CHECK (status <> 'REJECTED' OR char_length(COALESCE(decision_comment, '')) >= 20),
  CONSTRAINT ck_prompt_version_superseded CHECK ((status = 'SUPERSEDED') = (superseded_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_prompt_version_active ON ph17_assist.prompt_version (tenant_id, template_id) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_prompt_version_touch BEFORE UPDATE ON ph17_assist.prompt_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_prompt_version_immutable BEFORE UPDATE ON ph17_assist.prompt_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('template_id', 'version_no');
CREATE TRIGGER tg_prompt_version_frozen BEFORE UPDATE ON ph17_assist.prompt_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_frozen('PENDING_APPROVAL,ACTIVE,SUPERSEDED,REJECTED,RETIRED', 'content_text', 'content_hash');
CREATE TRIGGER tg_prompt_version_fsm_status BEFORE UPDATE ON ph17_assist.prompt_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>PENDING_APPROVAL,PENDING_APPROVAL>DRAFT,PENDING_APPROVAL>ACTIVE,PENDING_APPROVAL>REJECTED,ACTIVE>SUPERSEDED,ACTIVE>RETIRED');
CREATE TRIGGER tg_prompt_version_gate BEFORE UPDATE ON ph17_assist.prompt_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_release_gate('PROMPT');
CALL ph17_assist.p_enable_rls_common('ph17_assist.prompt_version');
COMMENT ON TABLE ph17_assist.prompt_version IS 'EN-17-27 Phiên bản chỉ dẫn hệ thống (FR-17-049; BR-17-064, 065; FRS 4.6). DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, REJECTED, RETIRED; mỗi mẫu đúng một bản ACTIVE; duyệt bốn mắt; kích hoạt cần đánh giá đạt và ca đỏ 100% (cổng phát hành). Nội dung khóa từ PENDING_APPROVAL; không địa chỉ IP, không tham chiếu bí mật.';
COMMENT ON COLUMN ph17_assist.prompt_version.content_text IS 'Chỉ dẫn hệ thống; kiểm tĩnh khi lưu (ERR-17-071). Quay lại bản trước là tạo phiên bản mới có nội dung bản cũ (FRS 4.6).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.prompt_version CASCADE;

-- @changeset ph17-0490-eval-set
CREATE TABLE ph17_assist.eval_set (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  set_code    varchar(48) NOT NULL,
  capability  varchar(16) NOT NULL,
  name        varchar(255) NOT NULL,
  description varchar(2000),
  min_cases   smallint NOT NULL DEFAULT 30,
  retired_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_eval_set PRIMARY KEY (id),
  CONSTRAINT uq_eval_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_eval_set_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_eval_set_code UNIQUE (tenant_id, set_code),
  CONSTRAINT ck_eval_set_code CHECK (set_code ~ '^[A-Z][A-Z0-9-]{2,47}$'),
  CONSTRAINT ck_eval_set_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_eval_set_min CHECK (min_cases >= 30)
);
CREATE TRIGGER tg_eval_set_touch BEFORE UPDATE ON ph17_assist.eval_set FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_eval_set_immutable BEFORE UPDATE ON ph17_assist.eval_set FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('set_code', 'capability');
CALL ph17_assist.p_enable_rls_common('ph17_assist.eval_set');
COMMENT ON TABLE ph17_assist.eval_set IS 'EN-17-28 Bộ đánh giá chuẩn theo năng lực (FR-17-050, 062; BR-17-066): gồm dữ liệu tổng hợp hoặc siêu dữ liệu công khai, tối thiểu 30 ca; tự chạy khi đổi mô hình, mô hình nhúng, prompt, tham số truy hồi.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.eval_set CASCADE;

-- @changeset ph17-0500-eval-dataset-link
CREATE TABLE ph17_assist.eval_dataset_link (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  eval_set_id  uuid NOT NULL,
  dataset_ref  varchar(128) NOT NULL,
  k_actual     integer NOT NULL,
  released_at  timestamptz NOT NULL,
  expires_at   timestamptz,
  linked_by    varchar(64) NOT NULL,
  withdrawn_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_eval_dataset_link PRIMARY KEY (id),
  CONSTRAINT uq_eval_dataset_link_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_eval_dataset_link_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_eval_dataset_link_eval_set FOREIGN KEY (tenant_id, eval_set_id) REFERENCES ph17_assist.eval_set (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_eval_dataset_link UNIQUE (tenant_id, eval_set_id, dataset_ref),
  CONSTRAINT ck_eval_dataset_link_k CHECK (k_actual >= 10),
  CONSTRAINT ck_eval_dataset_link_expiry CHECK (expires_at IS NULL OR expires_at > released_at)
);
CREATE TRIGGER tg_eval_dataset_link_touch BEFORE UPDATE ON ph17_assist.eval_dataset_link FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_eval_dataset_link_immutable BEFORE UPDATE ON ph17_assist.eval_dataset_link FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('eval_set_id', 'dataset_ref', 'k_actual');
CALL ph17_assist.p_enable_rls('ph17_assist.eval_dataset_link');
COMMENT ON TABLE ph17_assist.eval_dataset_link IS 'EN-17-28 (EvalDatasetLink) Gắn tập dữ liệu ẩn danh đã phát hành của PH-09 vào bộ đánh giá (FR-17-062; BR-17-084). Chỉ tập RELEASED với k tối thiểu 10; tập hết hạn hoặc rút lại thì gỡ liên kết và xóa kết quả đã tạo. Chỉ dùng đánh giá, hiệu chuẩn; không huấn luyện.';
COMMENT ON COLUMN ph17_assist.eval_dataset_link.dataset_ref IS 'Mã tập ẩn danh ở PH-09 (EVT-09-18, API-09-137); không chứa dữ liệu.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.eval_dataset_link CASCADE;

-- @changeset ph17-0510-eval-case
CREATE TABLE ph17_assist.eval_case (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  eval_set_id     uuid NOT NULL,
  case_no         integer NOT NULL,
  input_text      text NOT NULL,
  expected        jsonb NOT NULL,
  criteria        jsonb NOT NULL DEFAULT '{}',
  input_origin    varchar(16) NOT NULL,
  dataset_link_id uuid,
  retired_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_eval_case PRIMARY KEY (id),
  CONSTRAINT uq_eval_case_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_eval_case_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_eval_case_eval_set FOREIGN KEY (tenant_id, eval_set_id) REFERENCES ph17_assist.eval_set (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_eval_case_no UNIQUE (tenant_id, eval_set_id, case_no),
  CONSTRAINT ck_eval_case_origin CHECK (input_origin IN ('SYNTHETIC', 'PUBLIC_METADATA', 'ANON_DATASET')),
  CONSTRAINT ck_eval_case_dataset CHECK ((input_origin = 'ANON_DATASET') = (dataset_link_id IS NOT NULL)),
  CONSTRAINT fk_eval_case_dataset_link FOREIGN KEY (tenant_id, dataset_link_id) REFERENCES ph17_assist.eval_dataset_link (tenant_id, id),
  CONSTRAINT ck_eval_case_no CHECK (case_no >= 1)
);
CREATE TRIGGER tg_eval_case_touch BEFORE UPDATE ON ph17_assist.eval_case FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_eval_case_immutable BEFORE UPDATE ON ph17_assist.eval_case FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('eval_set_id', 'case_no');
CALL ph17_assist.p_enable_rls_common('ph17_assist.eval_case');
COMMENT ON TABLE ph17_assist.eval_case IS 'EN-17-29 Ca đánh giá (FR-17-050; BR-17-066): đầu vào tổng hợp hoặc siêu dữ liệu công khai, đáp án mong đợi, tiêu chí chấm. Ngừng bằng retired_at, không xóa để giữ lịch sử điểm.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.eval_case CASCADE;

-- @changeset ph17-0520-eval-run
CREATE TABLE ph17_assist.eval_run (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  run_kind         varchar(8) NOT NULL,
  eval_set_id      uuid,
  subject_type     varchar(16) NOT NULL,
  subject_id       uuid,
  status           varchar(8) NOT NULL DEFAULT 'QUEUED',
  trigger_kind     varchar(16) NOT NULL,
  cases_total      integer NOT NULL DEFAULT 0,
  cases_passed     integer NOT NULL DEFAULT 0,
  cases_leaked     integer NOT NULL DEFAULT 0,
  score            numeric(5,4),
  pass_rate        numeric(5,2),
  baseline_run_id  uuid,
  regression_delta numeric(5,4),
  ci_ref           varchar(255),
  started_at       timestamptz,
  finished_at      timestamptz,
  error_code       varchar(16),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_eval_run PRIMARY KEY (id),
  CONSTRAINT uq_eval_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_eval_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_eval_run_kind CHECK (run_kind IN ('EVAL', 'REDTEAM')),
  CONSTRAINT ck_eval_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'PASSED', 'FAILED', 'ERROR')),
  CONSTRAINT ck_eval_run_subject CHECK (subject_type IN ('MODEL_VERSION', 'PROMPT_VERSION', 'EMBED_VERSION', 'RAG_PARAMS', 'GUARDRAIL_CODE')),
  CONSTRAINT ck_eval_run_trigger CHECK (trigger_kind IN ('MODEL_CHANGE', 'PROMPT_CHANGE', 'EMBED_CHANGE', 'RAG_PARAMS', 'CODE_CHANGE', 'MANUAL', 'SCHEDULE')),
  CONSTRAINT ck_eval_run_counts CHECK (cases_total >= 0 AND cases_passed BETWEEN 0 AND cases_total AND cases_leaked BETWEEN 0 AND cases_total),
  CONSTRAINT ck_eval_run_score CHECK (score IS NULL OR score BETWEEN 0 AND 1),
  CONSTRAINT ck_eval_run_rate CHECK (pass_rate IS NULL OR pass_rate BETWEEN 0 AND 100),
  CONSTRAINT ck_eval_run_set CHECK (run_kind = 'REDTEAM' OR eval_set_id IS NOT NULL),
  CONSTRAINT ck_eval_run_finished CHECK ((status IN ('PASSED', 'FAILED', 'ERROR')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_eval_run_passed_eval CHECK (status <> 'PASSED' OR run_kind <> 'EVAL' OR (cases_total >= 30 AND score IS NOT NULL)),
  CONSTRAINT ck_eval_run_passed_redteam CHECK (status <> 'PASSED' OR run_kind <> 'REDTEAM' OR (cases_total >= 50 AND cases_leaked = 0 AND cases_passed = cases_total AND pass_rate = 100)),
  CONSTRAINT ck_eval_run_error CHECK (status <> 'ERROR' OR error_code IS NOT NULL),
  CONSTRAINT fk_eval_run_eval_set FOREIGN KEY (tenant_id, eval_set_id) REFERENCES ph17_assist.eval_set (tenant_id, id)
);
CREATE INDEX ix_eval_run_subject ON ph17_assist.eval_run (tenant_id, subject_type, subject_id, created_at DESC);
CREATE UNIQUE INDEX uq_eval_run_running ON ph17_assist.eval_run (tenant_id, run_kind, subject_type, subject_id) WHERE status IN ('QUEUED', 'RUNNING') AND subject_id IS NOT NULL;
CREATE TRIGGER tg_eval_run_touch BEFORE UPDATE ON ph17_assist.eval_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_eval_run_immutable BEFORE UPDATE ON ph17_assist.eval_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('run_kind', 'subject_type', 'subject_id');
CREATE TRIGGER tg_eval_run_fsm_status BEFORE UPDATE ON ph17_assist.eval_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'QUEUED>RUNNING,RUNNING>PASSED,RUNNING>FAILED,RUNNING>ERROR,QUEUED>ERROR');
CALL ph17_assist.p_enable_rls_common('ph17_assist.eval_run');
COMMENT ON TABLE ph17_assist.eval_run IS 'EN-17-30 Một lượt chạy bộ đánh giá hoặc bộ ca đỏ cho một đối tượng (FR-17-050, 051; BR-17-066…068): mô hình, prompt, mô hình nhúng, tham số truy hồi, mã bộ lọc. PASSED cần đủ số ca; ca đỏ PASSED chỉ khi 0 ca lọt và 100% bị chặn; hồi quy so với lượt trước ghi regression_delta.';
COMMENT ON COLUMN ph17_assist.eval_run.subject_id IS 'Mã phiên bản mô hình, prompt hoặc nhúng; NULL với tham số truy hồi, mã bộ lọc (ghi subject_type).';
COMMENT ON COLUMN ph17_assist.eval_run.ci_ref IS 'Mã lượt CI đã chạy bộ ca đỏ khi đổi mã bộ lọc, công cụ, prompt (BR-17-068).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.eval_run CASCADE;

-- @changeset ph17-0530-eval-result
CREATE TABLE ph17_assist.eval_result (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid NOT NULL,
  case_kind       varchar(8) NOT NULL,
  case_ref        uuid NOT NULL,
  passed          boolean NOT NULL,
  score           numeric(5,4),
  blocked         boolean,
  detail_masked   varchar(4000),
  latency_ms      integer,
  dataset_link_id uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_eval_result PRIMARY KEY (id),
  CONSTRAINT ck_eval_result_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_eval_result_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph17_assist.eval_run (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_eval_result_case UNIQUE (tenant_id, run_id, case_ref),
  CONSTRAINT ck_eval_result_kind CHECK (case_kind IN ('EVAL', 'REDTEAM')),
  CONSTRAINT ck_eval_result_blocked CHECK ((case_kind = 'REDTEAM') = (blocked IS NOT NULL)),
  CONSTRAINT ck_eval_result_redteam_pass CHECK (case_kind <> 'REDTEAM' OR passed = blocked),
  CONSTRAINT ck_eval_result_score CHECK (score IS NULL OR score BETWEEN 0 AND 1)
);
CREATE INDEX ix_eval_result_run ON ph17_assist.eval_result (tenant_id, run_id, passed);
CREATE INDEX ix_eval_result_dataset ON ph17_assist.eval_result (tenant_id, dataset_link_id) WHERE dataset_link_id IS NOT NULL;
CREATE TRIGGER tg_eval_result_touch BEFORE UPDATE ON ph17_assist.eval_result FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_common('ph17_assist.eval_result');
COMMENT ON TABLE ph17_assist.eval_result IS 'EN-17-31 Kết quả từng ca của một lượt chạy (FR-17-050, 051): đạt hay không, điểm, nội dung đã che, ca đỏ có bị chặn không. Không lưu dữ liệu thật; tập ẩn danh hết hạn thì xóa kết quả liên quan (BR-17-084).';
COMMENT ON COLUMN ph17_assist.eval_result.dataset_link_id IS 'Có khi ca lấy từ tập ẩn danh PH-09; gỡ tập thì xóa các dòng này (API-17-186).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.eval_result CASCADE;

-- @changeset ph17-0540-redteam-case
CREATE TABLE ph17_assist.redteam_case (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  case_code          varchar(32) NOT NULL,
  category           varchar(20) NOT NULL,
  attack_text        text NOT NULL,
  expected_behavior  varchar(8) NOT NULL DEFAULT 'BLOCK',
  status             varchar(8) NOT NULL DEFAULT 'ACTIVE',
  origin             varchar(10) NOT NULL DEFAULT 'SEED',
  source_feedback_id uuid,
  retired_at         timestamptz,
  retired_reason     varchar(1000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_redteam_case PRIMARY KEY (id),
  CONSTRAINT uq_redteam_case_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_redteam_case_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_redteam_case_code UNIQUE (tenant_id, case_code),
  CONSTRAINT ck_redteam_case_code CHECK (case_code ~ '^RT-[A-Z0-9-]{3,28}$'),
  CONSTRAINT ck_redteam_case_category CHECK (category IN ('INDIRECT_INJECTION', 'TOOL_ABUSE', 'PII_LEAK', 'CROSS_TENANT', 'SECRET_LEAK', 'JAILBREAK')),
  CONSTRAINT ck_redteam_case_expected CHECK (expected_behavior = 'BLOCK'),
  CONSTRAINT ck_redteam_case_status CHECK (status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_redteam_case_origin CHECK (origin IN ('SEED', 'INCIDENT', 'FEEDBACK')),
  CONSTRAINT ck_redteam_case_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL AND retired_reason IS NOT NULL)),
  CONSTRAINT ck_redteam_case_attack CHECK (char_length(attack_text) >= 5 AND attack_text !~* '(bearer +[a-z0-9._-]{20,}|begin [a-z ]*private key)')
);
CREATE INDEX ix_redteam_case_status ON ph17_assist.redteam_case (tenant_id, status, category);
CREATE TRIGGER tg_redteam_case_touch BEFORE UPDATE ON ph17_assist.redteam_case FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_redteam_case_immutable BEFORE UPDATE ON ph17_assist.redteam_case FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('case_code', 'category', 'attack_text', 'expected_behavior');
CREATE TRIGGER tg_redteam_case_fsm_status BEFORE UPDATE ON ph17_assist.redteam_case FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'ACTIVE>RETIRED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.redteam_case');
COMMENT ON TABLE ph17_assist.redteam_case IS 'EN-17-32 Ca đỏ tiêm lệnh (FR-17-051; BR-17-063, 067, 068): nhóm tấn công, nội dung tấn công TỔNG HỢP, hành vi mong đợi luôn là chặn. Tối thiểu 50 ca đang hoạt động; ca đã có không xóa, không sửa nội dung, chỉ ngừng (ACTIVE sang RETIRED). Ca mới từ sự cố hoặc phản hồi được bổ sung.';
COMMENT ON COLUMN ph17_assist.redteam_case.attack_text IS 'Nội dung tấn công tổng hợp; không dữ liệu thật, không bí mật thật (BR-17-067).';
COMMENT ON COLUMN ph17_assist.redteam_case.status IS 'ACTIVE, RETIRED (trạng thái nội bộ của thiết kế, không phải enum FRS).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.redteam_case CASCADE;

-- @changeset ph17-0550-feedback
CREATE TABLE ph17_assist.feedback (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  message_id        uuid NOT NULL,
  user_id           varchar(64) NOT NULL,
  kind              varchar(12) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'NEW',
  reason_masked     varchar(4000),
  redteam_candidate boolean GENERATED ALWAYS AS (kind = 'UNSAFE') STORED,
  assigned_to       varchar(64),
  assigned_at       timestamptz,
  due_at            timestamptz NOT NULL,
  closed_at         timestamptz,
  resolution        varchar(2000),
  promoted_case_id  uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_feedback PRIMARY KEY (id),
  CONSTRAINT uq_feedback_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_feedback_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_feedback_user_message UNIQUE (tenant_id, message_id, user_id),
  CONSTRAINT ck_feedback_kind CHECK (kind IN ('HELPFUL', 'NOT_HELPFUL', 'WRONG', 'UNSAFE')),
  CONSTRAINT ck_feedback_status CHECK (status IN ('NEW', 'ASSIGNED', 'CLOSED', 'PROMOTED_TO_REDTEAM')),
  CONSTRAINT ck_feedback_reason CHECK (kind NOT IN ('WRONG', 'UNSAFE') OR char_length(COALESCE(reason_masked, '')) >= 10),
  CONSTRAINT ck_feedback_assigned CHECK (status <> 'ASSIGNED' OR assigned_to IS NOT NULL),
  CONSTRAINT ck_feedback_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL)),
  CONSTRAINT ck_feedback_promoted CHECK ((status = 'PROMOTED_TO_REDTEAM') = (promoted_case_id IS NOT NULL)),
  CONSTRAINT ck_feedback_due CHECK (due_at > created_at)
);
CREATE INDEX ix_feedback_queue ON ph17_assist.feedback (tenant_id, status, due_at);
CREATE INDEX ix_feedback_message ON ph17_assist.feedback (tenant_id, message_id);
CREATE TRIGGER tg_feedback_touch BEFORE UPDATE ON ph17_assist.feedback FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_feedback_immutable BEFORE UPDATE ON ph17_assist.feedback FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('message_id', 'user_id', 'kind');
CREATE TRIGGER tg_feedback_fsm_status BEFORE UPDATE ON ph17_assist.feedback FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'NEW>ASSIGNED,ASSIGNED>CLOSED,NEW>CLOSED,ASSIGNED>PROMOTED_TO_REDTEAM,NEW>PROMOTED_TO_REDTEAM');
CALL ph17_assist.p_enable_rls('ph17_assist.feedback');
COMMENT ON TABLE ph17_assist.feedback IS 'EN-17-33 Phản hồi của người dùng cho một câu trả lời (FR-17-052; BR-17-069, 070): HELPFUL, NOT_HELPFUL, WRONG, UNSAFE; mỗi người một lần cho mỗi câu trả lời (ERR-17-077). WRONG và UNSAFE cần lý do đã che; UNSAFE tự thành ứng viên ca đỏ. Hạn xử lý 17.feedback.sla-days.';
COMMENT ON COLUMN ph17_assist.feedback.message_id IS 'Tham chiếu logic tới message (message bị xóa theo hạn lưu thì phản hồi vẫn còn để đo chất lượng).';
COMMENT ON COLUMN ph17_assist.feedback.due_at IS 'created_at cộng 17.feedback.sla-days ngày làm việc.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.feedback CASCADE;

-- @changeset ph17-0560-quality-metric
CREATE TABLE ph17_assist.quality_metric (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  metric_date       date NOT NULL,
  period            varchar(4) NOT NULL,
  capability        varchar(16) NOT NULL,
  model_version_id  uuid,
  prompt_version_id uuid,
  metric_code       varchar(24) NOT NULL,
  value             numeric(12,4) NOT NULL,
  sample_count      integer NOT NULL,
  baseline_value    numeric(12,4),
  alert             boolean NOT NULL DEFAULT false,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_quality_metric PRIMARY KEY (id),
  CONSTRAINT ck_quality_metric_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quality_metric_period CHECK (period IN ('DAY', 'WEEK')),
  CONSTRAINT ck_quality_metric_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_quality_metric_code CHECK (metric_code IN ('CITED_RATE', 'NO_SOURCE_RATE', 'ACCEPT_RATE', 'EVAL_SCORE', 'HELPFUL_RATE', 'BLOCKED_RATE', 'LATENCY_P95_MS')),
  CONSTRAINT ck_quality_metric_sample CHECK (sample_count >= 0)
);
CREATE UNIQUE INDEX uq_quality_metric_bucket ON ph17_assist.quality_metric (tenant_id, metric_date, period, capability, metric_code, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(prompt_version_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX ix_quality_metric_alert ON ph17_assist.quality_metric (tenant_id, metric_date DESC) WHERE alert;
CREATE TRIGGER tg_quality_metric_touch BEFORE UPDATE ON ph17_assist.quality_metric FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.quality_metric');
COMMENT ON TABLE ph17_assist.quality_metric IS 'EN-17-34 Chỉ số chất lượng theo ngày, tuần, năng lực, mô hình, phiên bản prompt (FR-17-053; BR-17-071): tỷ lệ có trích dẫn, tỷ lệ không tìm thấy, tỷ lệ chấp nhận gợi ý, điểm đánh giá, tỷ lệ hữu ích. Sụt quá 17.quality.alert-drop-percent so với 7 ngày trước thì cảnh báo PH-13. Chỉ số tổng hợp, không nội dung.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.quality_metric CASCADE;


-- @file 17-0080-govern.sql
-- @changeset ph17-0570-ai-system-record
CREATE TABLE ph17_assist.ai_system_record (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  record_code      varchar(32) NOT NULL,
  name             varchar(255) NOT NULL,
  purpose          text NOT NULL,
  model_summary    jsonb NOT NULL DEFAULT '[]',
  data_summary     jsonb NOT NULL DEFAULT '{}',
  risk_level       varchar(8) NOT NULL,
  risk_assessment  text NOT NULL,
  measures         text[] NOT NULL,
  responsible_user varchar(64) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'ACTIVE',
  last_review_at   timestamptz NOT NULL,
  next_review_due  date NOT NULL,
  legal_refs       varchar(16)[],
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ai_system_record PRIMARY KEY (id),
  CONSTRAINT ck_ai_system_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_ai_system_record_code UNIQUE (tenant_id, record_code),
  CONSTRAINT ck_ai_system_record_risk CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_ai_system_record_status CHECK (status IN ('ACTIVE', 'REVIEW_DUE', 'RETIRED')),
  CONSTRAINT ck_ai_system_record_review CHECK (next_review_due <= (last_review_at + interval '12 months')::date),
  CONSTRAINT ck_ai_system_record_measures CHECK (cardinality(measures) >= 1),
  CONSTRAINT ck_ai_system_record_code CHECK (record_code ~ '^AI-[A-Z0-9-]{2,28}$')
);
CREATE TRIGGER tg_ai_system_record_touch BEFORE UPDATE ON ph17_assist.ai_system_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_ai_system_record_immutable BEFORE UPDATE ON ph17_assist.ai_system_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('record_code');
CALL ph17_assist.p_enable_rls('ph17_assist.ai_system_record');
COMMENT ON TABLE ph17_assist.ai_system_record IS 'EN-17-35 Hồ sơ đăng ký hệ thống AI của tenant (FR-17-054; BR-17-072; Luật Công nghiệp công nghệ số 2025, chương trí tuệ nhân tạo, chưa đối chiếu Công báo): mục đích, mô hình, dữ liệu, rủi ro, biện pháp, người chịu trách nhiệm. Phần mô hình, dữ liệu tự cập nhật khi cấu hình đổi; rà soát mỗi 12 tháng và khi đổi mô hình.';
COMMENT ON COLUMN ph17_assist.ai_system_record.risk_level IS 'LOW, MEDIUM, HIGH (RiskLevel, Phụ lục A).';
COMMENT ON COLUMN ph17_assist.ai_system_record.next_review_due IS 'Không quá 12 tháng sau lần rà soát cuối (BR-17-072).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.ai_system_record CASCADE;

-- @changeset ph17-0580-log-access-grant
CREATE TABLE ph17_assist.log_access_grant (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  grantee         varchar(64) NOT NULL,
  grantee_role    varchar(10) NOT NULL,
  reason          varchar(2000) NOT NULL,
  scope_kind      varchar(12) NOT NULL,
  conversation_id uuid,
  range_from      timestamptz,
  range_to        timestamptz,
  granted_at      timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz NOT NULL,
  state           varchar(8) NOT NULL DEFAULT 'ACTIVE',
  access_count    integer NOT NULL DEFAULT 0,
  revoked_at      timestamptz,
  revoked_by      varchar(64),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_log_access_grant PRIMARY KEY (id),
  CONSTRAINT uq_log_access_grant_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_log_access_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_log_access_grant_role CHECK (grantee_role IN ('SO', 'AUDITOR')),
  CONSTRAINT ck_log_access_grant_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_log_access_grant_scope CHECK (scope_kind IN ('CONVERSATION', 'RANGE')),
  CONSTRAINT ck_log_access_grant_scope_fields CHECK ((scope_kind = 'CONVERSATION' AND conversation_id IS NOT NULL AND range_from IS NULL AND range_to IS NULL) OR (scope_kind = 'RANGE' AND conversation_id IS NULL AND range_from IS NOT NULL AND range_to IS NOT NULL AND range_to > range_from AND range_to <= range_from + interval '92 days')),
  CONSTRAINT ck_log_access_grant_ttl CHECK (expires_at > granted_at AND expires_at <= granted_at + interval '60 minutes'),
  CONSTRAINT ck_log_access_grant_state CHECK (state IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_log_access_grant_count CHECK (access_count >= 0),
  CONSTRAINT ck_log_access_grant_revoked CHECK ((state = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_by IS NOT NULL))
);
CREATE INDEX ix_log_access_grant_grantee ON ph17_assist.log_access_grant (tenant_id, grantee, state, expires_at);
CREATE TRIGGER tg_log_access_grant_touch BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_log_access_grant_immutable BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('grantee', 'grantee_role', 'reason', 'scope_kind', 'conversation_id', 'range_from', 'range_to', 'granted_at', 'expires_at');
CREATE TRIGGER tg_log_access_grant_fsm_state BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'ACTIVE>EXPIRED,ACTIVE>REVOKED');
CALL ph17_assist.p_enable_rls('ph17_assist.log_access_grant');
COMMENT ON TABLE ph17_assist.log_access_grant IS 'EN-17-36 Phiếu truy cập nhật ký hội thoại có lý do (FR-17-056; BR-17-074, 075): chỉ SO, AUDITOR; lý do từ 20 ký tự; phạm vi một hội thoại hoặc khoảng không quá 92 ngày; hiệu lực tối đa 60 phút. Mỗi lần xem tăng access_count và ghi kiểm toán ở PH-13. Mở khóa RLS của conversation, message.';
COMMENT ON COLUMN ph17_assist.log_access_grant.conversation_id IS 'Tham chiếu logic tới conversation (không khóa ngoại: hội thoại có thể bị xóa theo hạn lưu).';
-- @rollback DROP TABLE IF EXISTS ph17_assist.log_access_grant CASCADE;

-- @changeset ph17-0590-compliance-export
CREATE TABLE ph17_assist.compliance_export (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  export_kind           varchar(16) NOT NULL,
  state                 varchar(10) NOT NULL DEFAULT 'GENERATING',
  requested_by          varchar(64) NOT NULL,
  period_from           date,
  period_to             date,
  file_id               uuid,
  sha256                char(64),
  signature_ref         varchar(255),
  expires_at            timestamptz,
  contains_conversation boolean NOT NULL DEFAULT false,
  error_code            varchar(16),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_export PRIMARY KEY (id),
  CONSTRAINT uq_compliance_export_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_compliance_export_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_compliance_export_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT ck_compliance_export_kind CHECK (export_kind IN ('COMPLIANCE_PACK', 'USAGE_REPORT')),
  CONSTRAINT ck_compliance_export_state CHECK (state IN ('GENERATING', 'READY', 'EXPIRED', 'FAILED')),
  CONSTRAINT ck_compliance_export_no_content CHECK (NOT contains_conversation),
  CONSTRAINT ck_compliance_export_period CHECK (period_to IS NULL OR period_from IS NULL OR (period_to >= period_from AND period_to <= period_from + 92)),
  CONSTRAINT ck_compliance_export_ready CHECK (state NOT IN ('READY') OR (file_id IS NOT NULL AND sha256 IS NOT NULL AND signature_ref IS NOT NULL AND expires_at IS NOT NULL)),
  CONSTRAINT ck_compliance_export_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_compliance_export_failed CHECK (state <> 'FAILED' OR error_code IS NOT NULL)
);
CREATE INDEX ix_compliance_export_state ON ph17_assist.compliance_export (tenant_id, state, created_at DESC);
CREATE TRIGGER tg_compliance_export_touch BEFORE UPDATE ON ph17_assist.compliance_export FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_compliance_export_fsm_state BEFORE UPDATE ON ph17_assist.compliance_export FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'GENERATING>READY,GENERATING>FAILED,READY>EXPIRED');
CALL ph17_assist.p_enable_rls('ph17_assist.compliance_export');
COMMENT ON TABLE ph17_assist.compliance_export IS 'EN-17-37 Gói bằng chứng tuân thủ và báo cáo sử dụng đã tạo (FR-17-057, 058; BR-17-076, 077): cấu hình, mô hình và phiên bản, kết quả đánh giá, ca đỏ, sổ đăng ký; KHÔNG chứa nội dung hội thoại. Có băm và chữ ký OpenBao; hết hạn tải thì EXPIRED (ERR-17-081).';
COMMENT ON COLUMN ph17_assist.compliance_export.signature_ref IS 'Tham chiếu chữ ký OpenBao transit; không chứa khóa.';
COMMENT ON COLUMN ph17_assist.compliance_export.contains_conversation IS 'Luôn sai: gói không mang nội dung hội thoại.';
-- @rollback DROP TABLE IF EXISTS ph17_assist.compliance_export CASCADE;

-- @file 17-0900-grants.sql
-- @changeset ph17-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph17_assist TO ph17_app;
-- Đối tượng nghiệp vụ không xóa cứng (chính sách, mô hình, phiên bản, ca đỏ, phản hồi, phiếu, gói bằng chứng, hội thoại): chỉ dọn dữ liệu tạm và đoạn tri thức.
REVOKE DELETE ON ph17_assist.file_object, ph17_assist.tenant_setting, ph17_assist.ai_notice, ph17_assist.policy_change, ph17_assist.tenant_policy, ph17_assist.capability_policy, ph17_assist.kill_switch_record, ph17_assist.model_provider, ph17_assist.provider_commitment, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.route_sync_run, ph17_assist.tenant_model, ph17_assist.provider_grant, ph17_assist.model_breaker, ph17_assist.knowledge_source, ph17_assist.index_job, ph17_assist.tool_definition, ph17_assist.suggested_question, ph17_assist.guardrail_rule, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.eval_set, ph17_assist.eval_dataset_link, ph17_assist.eval_case, ph17_assist.eval_run, ph17_assist.redteam_case, ph17_assist.feedback, ph17_assist.quality_metric, ph17_assist.ai_system_record, ph17_assist.log_access_grant, ph17_assist.compliance_export, ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation, ph17_assist.suggestion FROM ph17_app;
-- Vết, nhật ký, xác nhận điều khoản: chỉ thêm (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph17_owner.
REVOKE UPDATE, DELETE ON ph17_assist.invocation_log, ph17_assist.model_health_probe, ph17_assist.notice_acceptance, ph17_assist.knowledge_deletion FROM ph17_app;
REVOKE UPDATE ON ph17_assist.outbox_event FROM ph17_app;
-- Vai job: đọc, xóa hội thoại và dòng con hết hạn (lịch lưu giữ), dọn bộ đếm; RLS theo hạn ở p_enable_rls_user.
GRANT SELECT, DELETE ON ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation TO ph17_job;
GRANT DELETE ON ph17_assist.quota_usage, ph17_assist.model_health_probe TO ph17_job;
-- Vai nền tảng (PA): ghi dòng COMMON của bảng dùng chung; không đọc bảng của tenant.
GRANT SELECT, INSERT, UPDATE ON ph17_assist.model_provider, ph17_assist.provider_commitment, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.route_sync_run, ph17_assist.kill_switch_record, ph17_assist.knowledge_source, ph17_assist.knowledge_document, ph17_assist.knowledge_chunk, ph17_assist.knowledge_deletion, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.eval_set, ph17_assist.eval_case, ph17_assist.eval_run, ph17_assist.eval_result, ph17_assist.redteam_case, ph17_assist.file_object, ph17_assist.model_health_probe TO ph17_platform;
GRANT DELETE ON ph17_assist.knowledge_chunk, ph17_assist.knowledge_document, ph17_assist.eval_result TO ph17_platform;
REVOKE UPDATE, DELETE ON ph17_assist.knowledge_deletion, ph17_assist.model_health_probe FROM ph17_platform;
GRANT SELECT ON ph17_assist.tenant_setting TO ph17_platform;
-- Vai data plane /assist/v1 (DU gọi, mTLS): đọc cấu hình, ghi vết và bộ đếm, tạo gợi ý bước quy trình; không đọc hội thoại, đoạn tri thức, nhật ký.
GRANT SELECT ON ph17_assist.tenant_policy, ph17_assist.capability_policy, ph17_assist.tenant_model, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.model_provider, ph17_assist.model_breaker, ph17_assist.tenant_setting, ph17_assist.kill_switch_record, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.guardrail_rule, ph17_assist.link_allowlist, ph17_assist.tool_definition TO ph17_infer;
GRANT INSERT ON ph17_assist.invocation_log TO ph17_infer;
GRANT SELECT, INSERT, UPDATE ON ph17_assist.quota_usage TO ph17_infer;
GRANT SELECT, INSERT, UPDATE ON ph17_assist.suggestion TO ph17_infer;
GRANT INSERT ON ph17_assist.outbox_event TO ph17_infer;
-- Báo cáo: đọc mọi bảng trừ hội thoại và nội dung; phản hồi chỉ cột không có lý do đã che.
GRANT SELECT ON ALL TABLES IN SCHEMA ph17_assist TO ph17_readonly;
REVOKE SELECT ON ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation, ph17_assist.suggestion, ph17_assist.feedback, ph17_assist.knowledge_chunk FROM ph17_readonly;
GRANT SELECT (id, tenant_id, message_id, kind, status, due_at, closed_at, created_at) ON ph17_assist.feedback TO ph17_readonly;
GRANT SELECT (id, tenant_id, source_id, document_id, chunk_no, class_level, embed_version_id, token_count, created_at) ON ph17_assist.knowledge_chunk TO ph17_readonly;
GRANT EXECUTE ON PROCEDURE ph17_assist.p_ensure_partitions(regclass, date, integer) TO ph17_app, ph17_job;
GRANT EXECUTE ON PROCEDURE ph17_assist.p_seed_tenant(text) TO ph17_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
