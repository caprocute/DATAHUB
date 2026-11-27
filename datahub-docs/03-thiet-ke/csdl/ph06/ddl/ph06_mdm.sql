-- =============================================================================
-- D03-03-PH06 · DDL schema ph06_mdm — PH-06 Dữ liệu chủ (Master Data Management)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng và Phụ lục A của D02-03-PH06; sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph06_mdm.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH06 phụ lục A. Số định danh, giá trị SENSITIVE: chỉ *_enc (envelope,
-- OpenBao transit, ADR-032) kèm *_hash (HMAC-SHA256) để đối sánh xác định, không bản rõ (BR-06-016, NFR-06-016).
-- Bản ghi vàng không bị xóa (BR-06-007): vai trò ph06_app không có DELETE trên bảng nghiệp vụ.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 06-0000-bootstrap.sql
-- @changeset ph06-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_owner') THEN
    CREATE ROLE ph06_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_app') THEN
    CREATE ROLE ph06_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_readonly') THEN
    CREATE ROLE ph06_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_splink') THEN
    CREATE ROLE ph06_splink NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph06-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE SCHEMA IF NOT EXISTS ph06_mdm AUTHORIZATION ph06_owner;
COMMENT ON SCHEMA ph06_mdm IS 'PH-06 Dữ liệu chủ (dh-data, package vn.datahub.data.mdm): domain, nguồn, ứng viên, đối sánh, hàng đợi, bản ghi vàng, liên kết chéo, lịch sử, nguồn gốc, đồng bộ quốc gia, yêu cầu chủ thể, nhật ký truy cập. Số định danh và giá trị SENSITIVE chỉ ở dạng mã hóa envelope và HMAC.';
GRANT USAGE ON SCHEMA ph06_mdm TO ph06_app, ph06_readonly, ph06_splink;
-- @rollback DROP SCHEMA IF EXISTS ph06_mdm CASCADE;

SET ROLE ph06_owner;

-- @changeset ph06-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 06-0001-functions.sql
-- @changeset ph06-0010-fn-touch splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_touch();

-- @changeset ph06-0011-fn-immutable splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_immutable();

-- @changeset ph06-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, lịch sử)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (golden_history, attribute_lineage, access_log, processing_log). Dọn bằng DETACH, DROP phân vùng dưới ph06_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_append_only();

-- @changeset ph06-0013-fn-frozen splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_frozen();

-- @changeset ph06-0014-fn-child-frozen splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_child_frozen();

-- @changeset ph06-0015-fn-rls splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_enable_rls(regclass);

-- @changeset ph06-0016-fn-partitions splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_ensure_partitions(regclass, date, integer);

-- @changeset ph06-0017-fn-seed-tenant splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_seed_tenant(text);


-- @file 06-0010-model.sql
-- @changeset ph06-0100-mdm-domain
CREATE TABLE ph06_mdm.mdm_domain (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  name             varchar(255) NOT NULL,
  description      varchar(2000),
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  baseline         boolean NOT NULL DEFAULT false,
  baseline_package varchar(32),
  status_reason    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mdm_domain PRIMARY KEY (id),
  CONSTRAINT ck_mdm_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mdm_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT ck_mdm_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_mdm_domain_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_mdm_domain_reason CHECK (status NOT IN ('SUSPENDED', 'RETIRED') OR status_reason IS NOT NULL)
);
CREATE TRIGGER tg_mdm_domain_touch BEFORE UPDATE ON ph06_mdm.mdm_domain FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_mdm_domain_immutable BEFORE UPDATE ON ph06_mdm.mdm_domain FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'tenant_id', 'baseline');
CALL ph06_mdm.p_enable_rls('ph06_mdm.mdm_domain');
COMMENT ON TABLE ph06_mdm.mdm_domain IS 'EN-06-07 Domain dữ liệu chủ (FR-06-001, 006, 007): CITIZEN, ORGANIZATION, ADDRESS và domain tỉnh tự tạo (FR-06-002). Trạng thái DomainStatus. Không xóa; ngừng cần không còn bản ghi vàng ACTIVE (ERR-06-011). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph06_mdm.mdm_domain.baseline IS 'Có khi cài từ gói domain nền (FR-06-007); gói nền do PA phát hành.';
COMMENT ON COLUMN ph06_mdm.mdm_domain.status_reason IS 'Bắt buộc khi SUSPENDED hoặc RETIRED.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.mdm_domain CASCADE;

-- @changeset ph06-0110-domain-model
CREATE TABLE ph06_mdm.domain_model (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  normalization    jsonb NOT NULL DEFAULT '{}',
  compat_level     varchar(16),
  diff_summary     jsonb,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  submit_comment   varchar(2000),
  decision         varchar(8),
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
  CONSTRAINT pk_domain_model PRIMARY KEY (id),
  CONSTRAINT uq_domain_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_domain_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_domain_model_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_domain_model_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_domain_model_version CHECK (version_no >= 1),
  CONSTRAINT ck_domain_model_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_domain_model_compat CHECK (compat_level IS NULL OR compat_level IN ('NON_BREAKING', 'BREAKING')),
  CONSTRAINT ck_domain_model_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_domain_model_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_domain_model_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE')),
  CONSTRAINT ck_domain_model_reject CHECK (decision IS DISTINCT FROM 'REJECT' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_domain_model_active ON ph06_mdm.domain_model (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_domain_model_touch BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_domain_model_immutable BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_domain_model_frozen BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_frozen('normalization');
CALL ph06_mdm.p_enable_rls('ph06_mdm.domain_model');
COMMENT ON TABLE ph06_mdm.domain_model IS 'EN-06-07 Phiên bản mô hình domain (FR-06-002, 005, 006, BR-06-017). Máy trạng thái 4.6 không có TESTING. Mỗi domain đúng một phiên bản ACTIVE; ACTIVE không sửa nội dung, kể cả thuộc tính và khóa con. Duyệt bốn mắt (BR-06-004).';
COMMENT ON COLUMN ph06_mdm.domain_model.normalization IS 'Quy tắc chuẩn hóa theo thuộc tính (FR-06-014, 015), JSON có phiên bản.';
COMMENT ON COLUMN ph06_mdm.domain_model.decision_comment IS 'Từ chối bắt buộc ≥ 20 ký tự (FR-06-006).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.domain_model CASCADE;

-- @changeset ph06-0120-model-attribute
CREATE TABLE ph06_mdm.model_attribute (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  version_no            integer NOT NULL,
  attribute_name        varchar(63) NOT NULL,
  label                 varchar(255) NOT NULL,
  attribute_type        varchar(16) NOT NULL,
  code_list_ref         varchar(63),
  required              boolean NOT NULL DEFAULT false,
  multi_valued          boolean NOT NULL DEFAULT false,
  critical              boolean NOT NULL DEFAULT false,
  matchable             boolean NOT NULL DEFAULT false,
  data_class            varchar(16) NOT NULL DEFAULT 'INTERNAL',
  classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED',
  personal_data         boolean NOT NULL DEFAULT false,
  legal_basis           varchar(2000),
  sort_order            smallint NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_attribute PRIMARY KEY (id),
  CONSTRAINT ck_model_attribute_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_model_attribute_name UNIQUE (tenant_id, domain_code, version_no, attribute_name),
  CONSTRAINT fk_model_attribute_model FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.domain_model (tenant_id, domain_code, version_no),
  CONSTRAINT ck_model_attribute_name CHECK (attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_model_attribute_type CHECK (attribute_type IN ('STRING', 'NAME_VN', 'DATE', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'CODE_REF', 'ADDRESS_REF', 'IDENTIFIER', 'PHONE', 'EMAIL')),
  CONSTRAINT ck_model_attribute_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_model_attribute_classification CHECK (classification_status IN ('PROPOSED', 'CONFIRMED')),
  CONSTRAINT ck_model_attribute_personal CHECK ((NOT personal_data OR legal_basis IS NOT NULL) AND (data_class <> 'SENSITIVE' OR personal_data)),
  CONSTRAINT ck_model_attribute_coderef CHECK ((attribute_type = 'CODE_REF') = (code_list_ref IS NOT NULL))
);
CREATE TRIGGER tg_model_attribute_touch BEFORE UPDATE ON ph06_mdm.model_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_model_attribute_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.model_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('domain_model');
CALL ph06_mdm.p_enable_rls('ph06_mdm.model_attribute');
COMMENT ON TABLE ph06_mdm.model_attribute IS 'EN-06-07 Thuộc tính của một phiên bản mô hình (FR-06-002, 004). Giá trị DataClass, ClassificationStatus; thuộc tính DLCN cần phân loại CONFIRMED trước khi kích hoạt (BR-06-016, kiểm ở dịch vụ, ERR-06-010). Phiên bản ACTIVE chặn thêm, sửa, xóa (trigger).';
COMMENT ON COLUMN ph06_mdm.model_attribute.data_class IS 'Phân loại theo DD-08; SENSITIVE bắt buộc personal_data.';
COMMENT ON COLUMN ph06_mdm.model_attribute.matchable IS 'Dùng được trong quy tắc đối sánh (FR-06-018).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.model_attribute CASCADE;

-- @changeset ph06-0130-identifier-rule
CREATE TABLE ph06_mdm.identifier_rule (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_code         varchar(32) NOT NULL,
  version_no          integer NOT NULL,
  identifier_type     varchar(16) NOT NULL,
  attribute_name      varchar(63) NOT NULL,
  validator           varchar(16) NOT NULL,
  pattern             varchar(500),
  deterministic       boolean NOT NULL DEFAULT false,
  unique_among_active boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_identifier_rule PRIMARY KEY (id),
  CONSTRAINT ck_identifier_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_identifier_rule UNIQUE (tenant_id, domain_code, version_no, identifier_type),
  CONSTRAINT fk_identifier_rule_model FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.domain_model (tenant_id, domain_code, version_no),
  CONSTRAINT ck_identifier_rule_type CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_identifier_rule_validator CHECK (validator IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'DVHC_CODE', 'REGEX')),
  CONSTRAINT ck_identifier_rule_regex CHECK ((validator = 'REGEX') = (pattern IS NOT NULL))
);
CREATE TRIGGER tg_identifier_rule_touch BEFORE UPDATE ON ph06_mdm.identifier_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_identifier_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.identifier_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('domain_model');
CALL ph06_mdm.p_enable_rls('ph06_mdm.identifier_rule');
COMMENT ON TABLE ph06_mdm.identifier_rule IS 'EN-06-07 Khóa định danh và bộ kiểm tra của phiên bản mô hình (FR-06-003, BR-06-001). Mỗi domain cần ít nhất một khóa hoặc tổ hợp đối sánh (ERR-06-009, kiểm ở dịch vụ khi gửi duyệt).';
COMMENT ON COLUMN ph06_mdm.identifier_rule.validator IS 'Danh sách ở đầu vào FR-06-003; chữ số kiểm tra theo Q06-09.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.identifier_rule CASCADE;

-- @changeset ph06-0140-mdm-source
CREATE TABLE ph06_mdm.mdm_source (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_code     varchar(32) NOT NULL,
  name            varchar(255) NOT NULL,
  system_code     varchar(63),
  source_kind     varchar(24) NOT NULL,
  status          varchar(16) NOT NULL DEFAULT 'DRAFT',
  domains         varchar(32)[] NOT NULL,
  channels        varchar(16)[] NOT NULL,
  attribute_scope varchar(63)[] NOT NULL DEFAULT '{}',
  owner_org_code  varchar(63) NOT NULL,
  trust_level     smallint NOT NULL DEFAULT 3,
  status_reason   varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mdm_source PRIMARY KEY (id),
  CONSTRAINT ck_mdm_source_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mdm_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_mdm_source_code CHECK (source_code ~ '^[A-Z][A-Z0-9-]{2,31}$'),
  CONSTRAINT ck_mdm_source_kind CHECK (source_kind IN ('NATIONAL_DB', 'SECTOR_AUTHORITATIVE', 'SECTOR_RELATED', 'SECTOR_OTHER', 'MANUAL_ENTRY', 'FILE_BATCH')),
  CONSTRAINT ck_mdm_source_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_mdm_source_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['API', 'FLOW', 'EVENT', 'FILE', 'NATIONAL_SYNC']::varchar[]),
  CONSTRAINT ck_mdm_source_domains CHECK (cardinality(domains) >= 1),
  CONSTRAINT ck_mdm_source_trust CHECK (trust_level BETWEEN 1 AND 5),
  CONSTRAINT ck_mdm_source_system CHECK (source_kind IN ('MANUAL_ENTRY', 'FILE_BATCH', 'NATIONAL_DB') OR system_code IS NOT NULL)
);
CREATE TRIGGER tg_mdm_source_touch BEFORE UPDATE ON ph06_mdm.mdm_source FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_mdm_source_immutable BEFORE UPDATE ON ph06_mdm.mdm_source FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('source_code', 'tenant_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.mdm_source');
COMMENT ON TABLE ph06_mdm.mdm_source IS 'EN-06-08 Nguồn dữ liệu chủ gắn HTTT (FR-06-008, BR-06-032). trust_level 1…5; nguồn NATIONAL_DB chỉ nhận qua PH-14, không kết nối thẳng. Chỉ nguồn ACTIVE cho domain mới được nạp (ERR-06-014).';
COMMENT ON COLUMN ph06_mdm.mdm_source.system_code IS 'Mã HTTT ở PH-01 (không khóa ngoại, khác schema); HTTT phải ACTIVE khi đăng ký (ERR-06-012).';
COMMENT ON COLUMN ph06_mdm.mdm_source.domains IS 'Mã domain ACTIVE được phép gửi; kiểm ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.mdm_source CASCADE;

-- @changeset ph06-0150-source-priority-proposal
CREATE TABLE ph06_mdm.source_priority_proposal (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  entries          jsonb NOT NULL,
  approval_ref     varchar(255) NOT NULL,
  justification    varchar(2000) NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  proposed_by      varchar(64) NOT NULL,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_priority_proposal PRIMARY KEY (id),
  CONSTRAINT uq_source_priority_proposal_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_source_priority_proposal_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_priority_proposal_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_source_priority_proposal_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'REJECTED')),
  CONSTRAINT ck_source_priority_proposal_four_eyes CHECK (decided_by IS NULL OR proposed_by IS NULL OR decided_by <> proposed_by),
  CONSTRAINT ck_source_priority_proposal_entries CHECK (jsonb_typeof(entries) = 'array' AND jsonb_array_length(entries) BETWEEN 1 AND 500),
  CONSTRAINT ck_source_priority_proposal_decided CHECK ((status = 'PENDING_APPROVAL') = (decided_by IS NULL))
);
CREATE TRIGGER tg_source_priority_proposal_touch BEFORE UPDATE ON ph06_mdm.source_priority_proposal FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_source_priority_proposal_immutable BEFORE UPDATE ON ph06_mdm.source_priority_proposal FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'entries', 'approval_ref', 'proposed_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_priority_proposal');
COMMENT ON TABLE ph06_mdm.source_priority_proposal IS 'EN-06-04, EN-06-22 Đề nghị thứ tự ưu tiên nguồn chờ duyệt (FR-06-009, BR-06-004). Cần căn cứ văn bản approval_ref; DA duyệt khác người đề nghị (ERR-06-005, 013).';
COMMENT ON COLUMN ph06_mdm.source_priority_proposal.entries IS 'Mảng {sourceCode, attribute, priority} theo FR-06-009; áp vào source_priority khi duyệt.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.source_priority_proposal CASCADE;

-- @changeset ph06-0160-source-priority
CREATE TABLE ph06_mdm.source_priority (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  source_code    varchar(32) NOT NULL,
  attribute_name varchar(63) NOT NULL DEFAULT '*',
  priority       smallint NOT NULL,
  approval_ref   varchar(255) NOT NULL,
  proposal_id    uuid NOT NULL,
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_priority PRIMARY KEY (id),
  CONSTRAINT ck_source_priority_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_priority_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT fk_source_priority_proposal FOREIGN KEY (tenant_id, proposal_id) REFERENCES ph06_mdm.source_priority_proposal (tenant_id, id),
  CONSTRAINT ck_source_priority_priority CHECK (priority BETWEEN 1 AND 99),
  CONSTRAINT ck_source_priority_attr CHECK (attribute_name = '*' OR attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_source_priority_period CHECK (effective_to IS NULL OR effective_to > effective_from)
);
CREATE UNIQUE INDEX uq_source_priority_current ON ph06_mdm.source_priority (tenant_id, domain_code, source_code, attribute_name) WHERE effective_to IS NULL;
CREATE INDEX ix_source_priority_domain ON ph06_mdm.source_priority (tenant_id, domain_code, attribute_name, priority) WHERE effective_to IS NULL;
CREATE TRIGGER tg_source_priority_touch BEFORE UPDATE ON ph06_mdm.source_priority FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_priority');
COMMENT ON TABLE ph06_mdm.source_priority IS 'EN-06-04 Mức ưu tiên nguồn theo domain và thuộc tính đang hiệu lực (FR-06-009, 033). attribute_name = ''*'' là mọi thuộc tính. Nguồn quốc gia luôn ưu tiên 1 với thuộc tính thẩm quyền quốc gia (BR-06-003). Bản cũ đóng bằng effective_to.';
COMMENT ON COLUMN ph06_mdm.source_priority.priority IS '1 cao nhất … 99 (FR-06-009).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.source_priority CASCADE;


-- @file 06-0020-ingest.sql
-- @changeset ph06-0170-candidate-file
CREATE TABLE ph06_mdm.candidate_file (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  source_code    varchar(32) NOT NULL,
  file_name      varchar(255) NOT NULL,
  size_bytes     bigint NOT NULL,
  row_count      integer,
  object_ref     varchar(512) NOT NULL,
  sha256         char(64) NOT NULL,
  column_mapping jsonb NOT NULL DEFAULT '{}',
  preview        jsonb,
  previewed_at   timestamptz,
  confirmed_by   varchar(64),
  confirmed_at   timestamptz,
  job_id         uuid,
  expires_at     timestamptz NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_candidate_file PRIMARY KEY (id),
  CONSTRAINT ck_candidate_file_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_candidate_file_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_candidate_file_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_candidate_file_size CHECK (size_bytes BETWEEN 1 AND 52428800 AND (row_count IS NULL OR row_count BETWEEN 0 AND 200000)),
  CONSTRAINT ck_candidate_file_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_candidate_file_confirm CHECK ((confirmed_at IS NULL) = (confirmed_by IS NULL))
);
CREATE INDEX ix_candidate_file_domain ON ph06_mdm.candidate_file (tenant_id, domain_code, created_at DESC);
CREATE TRIGGER tg_candidate_file_touch BEFORE UPDATE ON ph06_mdm.candidate_file FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_candidate_file_immutable BEFORE UPDATE ON ph06_mdm.candidate_file FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'source_code', 'sha256');
CALL ph06_mdm.p_enable_rls('ph06_mdm.candidate_file');
COMMENT ON TABLE ph06_mdm.candidate_file IS 'EN-06-25 FR-06-013 Tệp lô nạp ứng viên: tải lên, xem trước, xác nhận. Tệp ≤ 50 MB, ≤ 200.000 dòng (ERR-06-018, 019). Nội dung tệp nằm ở Ceph RGW (object_ref), không trong PostgreSQL; báo cáo xem trước ở preview jsonb, không chứa giá trị SENSITIVE.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.candidate_file CASCADE;

-- @changeset ph06-0180-source-record-head
CREATE TABLE ph06_mdm.source_record_head (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  domain_code            varchar(32) NOT NULL,
  source_code            varchar(32) NOT NULL,
  source_key             varchar(120) NOT NULL,
  last_version           bigint NOT NULL,
  last_candidate_id      uuid NOT NULL,
  last_source_updated_at timestamptz NOT NULL,
  deleted                boolean NOT NULL DEFAULT false,
  golden_id              uuid,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_record_head PRIMARY KEY (id),
  CONSTRAINT ck_source_record_head_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_source_record_head UNIQUE (tenant_id, domain_code, source_code, source_key),
  CONSTRAINT fk_source_record_head_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_record_head_version CHECK (last_version >= 0)
);
CREATE INDEX ix_source_record_head_golden ON ph06_mdm.source_record_head (tenant_id, golden_id) WHERE golden_id IS NOT NULL;
CREATE TRIGGER tg_source_record_head_touch BEFORE UPDATE ON ph06_mdm.source_record_head FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_record_head');
COMMENT ON TABLE ph06_mdm.source_record_head IS 'EN-06-26 FR-06-016 Trạng thái mới nhất của mỗi bản ghi nguồn (sourceCode, sourceKey): phiên bản cao nhất đã nhận, ứng viên cuối, bản ghi vàng đang liên kết. Thực thi BR-06-028 (xử lý một lần theo sourceVersion) và BR-06-029 (bản đến trễ không ghi đè); là bảng nhỏ, khóa duy nhất không phải phân vùng.';
COMMENT ON COLUMN ph06_mdm.source_record_head.golden_id IS 'Bản ghi vàng đang liên kết; tham chiếu logic để không khóa chéo khi hợp nhất.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.source_record_head CASCADE;

-- @changeset ph06-0190-candidate-record
CREATE TABLE ph06_mdm.candidate_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  received_at       timestamptz NOT NULL DEFAULT now(),
  domain_code       varchar(32) NOT NULL,
  source_code       varchar(32) NOT NULL,
  source_key        varchar(120) NOT NULL,
  source_version    bigint NOT NULL,
  source_updated_at timestamptz NOT NULL,
  operation         varchar(8) NOT NULL,
  channel           varchar(16) NOT NULL,
  status            varchar(24) NOT NULL DEFAULT 'RECEIVED',
  model_version     integer,
  raw_enc           bytea,
  raw_kid           varchar(64),
  attrs_norm        jsonb,
  name_norm         varchar(255),
  birth_year        smallint,
  admin_unit_code   varchar(16),
  identifier_type   varchar(16),
  identifier_status varchar(20),
  identifier_hash   bytea,
  block_keys        varchar(72)[],
  warnings          varchar(24)[] NOT NULL DEFAULT '{}',
  attribute_count   smallint NOT NULL DEFAULT 0,
  golden_id         uuid,
  match_outcome     varchar(16),
  file_id           uuid,
  flow_code         varchar(63),
  exchange_id       varchar(64),
  idempotency_key   varchar(128),
  reject_code       varchar(16),
  reject_detail     varchar(2000),
  processed_at      timestamptz,
  CONSTRAINT pk_candidate_record PRIMARY KEY (id, received_at),
  CONSTRAINT ck_candidate_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_candidate_record_op CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
  CONSTRAINT ck_candidate_record_channel CHECK (channel IN ('API', 'FLOW', 'EVENT', 'FILE', 'NATIONAL_SYNC')),
  CONSTRAINT ck_candidate_record_status CHECK (status IN ('RECEIVED', 'REJECTED', 'DUPLICATE', 'SUPERSEDED', 'NORMALIZATION_PENDING', 'NORMALIZED', 'QUEUED', 'LINKED', 'DISCARDED')),
  CONSTRAINT ck_candidate_record_idstatus CHECK (identifier_status IS NULL OR identifier_status IN ('VALID', 'INVALID_FORMAT', 'INVALID_CHECKSUM', 'PLACEHOLDER', 'MISSING')),
  CONSTRAINT ck_candidate_record_idtype CHECK (identifier_type IS NULL OR identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_candidate_record_outcome CHECK (match_outcome IS NULL OR match_outcome IN ('MATCH', 'POSSIBLE_MATCH', 'NO_MATCH', 'CONFLICT')),
  CONSTRAINT ck_candidate_record_warnings CHECK (warnings <@ ARRAY['IDENTIFIER_INVALID', 'DATE_PLACEHOLDER', 'ADMIN_UNIT_UNKNOWN', 'ADMIN_UNIT_SPLIT', 'ADMIN_UNIT_CONVERTED', 'CODE_UNMAPPED', 'ADDRESS_UNPARSED']::varchar[]),
  CONSTRAINT ck_candidate_record_hash CHECK (identifier_hash IS NULL OR octet_length(identifier_hash) = 32),
  CONSTRAINT ck_candidate_record_raw CHECK (raw_enc IS NULL OR (raw_kid IS NOT NULL AND octet_length(raw_enc) BETWEEN 29 AND 1048576)),
  CONSTRAINT ck_candidate_record_reject CHECK (status <> 'REJECTED' OR COALESCE(reject_code ~ '^ERR-06-0[0-9]{2}$' OR reject_code = 'DQ_GATE', false)),
  CONSTRAINT ck_candidate_record_birth CHECK (birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100),
  CONSTRAINT ck_candidate_record_key CHECK (char_length(source_key) >= 1)
) PARTITION BY RANGE (received_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.candidate_record', current_date, 3);
CREATE INDEX ix_candidate_record_queue ON ph06_mdm.candidate_record (tenant_id, domain_code, status, received_at);
CREATE INDEX ix_candidate_record_source ON ph06_mdm.candidate_record (tenant_id, source_code, source_key, source_version);
CREATE INDEX ix_candidate_record_idhash ON ph06_mdm.candidate_record (tenant_id, domain_code, identifier_hash) WHERE identifier_hash IS NOT NULL;
CREATE INDEX ix_candidate_record_blocks ON ph06_mdm.candidate_record USING gin (block_keys);
CREATE INDEX ix_candidate_record_name_trgm ON ph06_mdm.candidate_record USING gin (name_norm gin_trgm_ops);
CREATE INDEX ix_candidate_record_golden ON ph06_mdm.candidate_record (tenant_id, golden_id) WHERE golden_id IS NOT NULL;
CALL ph06_mdm.p_enable_rls('ph06_mdm.candidate_record');
COMMENT ON TABLE ph06_mdm.candidate_record IS 'EN-06-09 Bản ghi ứng viên nhận từ nguồn (FR-06-010…017). Dữ liệu gốc mã hóa envelope ở raw_enc; số định danh chỉ ở dạng HMAC identifier_hash; khóa gom nhóm là HMAC (BR-06-016). Phân vùng tháng theo received_at; giữ 365 ngày sau xử lý (retention_policy, khớp SRS cũ), sau đó ẩn danh hóa raw_enc.';
COMMENT ON COLUMN ph06_mdm.candidate_record.raw_enc IS 'Bản ghi gốc, mã hóa envelope (ADR-032); NULL sau khi dọn lưu giữ.';
COMMENT ON COLUMN ph06_mdm.candidate_record.reject_code IS 'Mã ERR-06-0nn, hoặc DQ_GATE khi cổng chất lượng PH-08 từ chối (FR-06-010, FR-08-035).';
COMMENT ON COLUMN ph06_mdm.candidate_record.identifier_hash IS 'HMAC-SHA256 của số định danh đã chuẩn hóa; dùng đối sánh xác định (FR-06-020).';
COMMENT ON COLUMN ph06_mdm.candidate_record.block_keys IS 'Khóa gom nhóm dạng HMAC có tiền tố tên khóa (FR-06-019).';
COMMENT ON COLUMN ph06_mdm.candidate_record.name_norm IS 'Họ tên không dấu, chữ thường (pg_trgm, FR-06-021).';
COMMENT ON COLUMN ph06_mdm.candidate_record.golden_id IS 'Bản ghi vàng liên kết; không khóa ngoại để giữ khi bảng vàng đổi.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.candidate_record CASCADE;


-- @file 06-0030-match.sql
-- @changeset ph06-0200-evaluation-report
CREATE TABLE ph06_mdm.evaluation_report (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  rule_set_version integer NOT NULL,
  label_set_code   varchar(63) NOT NULL,
  pair_count       integer NOT NULL,
  precision_pct    numeric(6,3) NOT NULL,
  recall_pct       numeric(6,3) NOT NULL,
  verdict          varchar(8) NOT NULL,
  job_id           uuid,
  confusion        jsonb NOT NULL DEFAULT '{}',
  evaluated_at     timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_evaluation_report PRIMARY KEY (id),
  CONSTRAINT uq_evaluation_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_evaluation_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_evaluation_report_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_evaluation_report_verdict CHECK (verdict IN ('PASSED', 'FAILED')),
  CONSTRAINT ck_evaluation_report_pct CHECK (precision_pct BETWEEN 0 AND 100 AND recall_pct BETWEEN 0 AND 100 AND pair_count >= 0),
  CONSTRAINT ck_evaluation_report_pass CHECK (verdict <> 'PASSED' OR (pair_count >= 1000 AND precision_pct >= 99.9 AND recall_pct >= 98))
);
CREATE INDEX ix_evaluation_report_rule ON ph06_mdm.evaluation_report (tenant_id, domain_code, rule_set_version, evaluated_at DESC);
CREATE TRIGGER tg_evaluation_report_touch BEFORE UPDATE ON ph06_mdm.evaluation_report FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.evaluation_report');
COMMENT ON TABLE ph06_mdm.evaluation_report IS 'EN-06-23 FR-06-026 Báo cáo đánh giá chính xác (precision, recall) của một phiên bản bộ quy tắc trên tập nhãn (BR-06-021). Là căn cứ kích hoạt bộ quy tắc; tham chiếu bộ quy tắc theo (domain_code, rule_set_version) để tránh vòng khóa ngoại.';
COMMENT ON COLUMN ph06_mdm.evaluation_report.verdict IS 'PASSED chỉ khi ≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98% (BR-06-021).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.evaluation_report CASCADE;

-- @changeset ph06-0210-match-rule-set
CREATE TABLE ph06_mdm.match_rule_set (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_code          varchar(32) NOT NULL,
  version_no           integer NOT NULL,
  status               varchar(20) NOT NULL DEFAULT 'DRAFT',
  blocking_keys        jsonb NOT NULL DEFAULT '[]',
  auto_merge_threshold numeric(3,2) NOT NULL DEFAULT 0.95,
  review_threshold     numeric(3,2) NOT NULL DEFAULT 0.60,
  auto_merge_enabled   boolean NOT NULL DEFAULT false,
  min_attributes       smallint NOT NULL DEFAULT 3,
  splink_params        jsonb,
  evaluation_report_id uuid,
  submitted_by         varchar(64),
  submitted_at         timestamptz,
  decision             varchar(8),
  decided_by           varchar(64),
  decided_at           timestamptz,
  decision_comment     varchar(2000),
  activated_at         timestamptz,
  superseded_at        timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_match_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_match_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_match_rule_set_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_match_rule_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_match_rule_set_eval FOREIGN KEY (tenant_id, evaluation_report_id) REFERENCES ph06_mdm.evaluation_report (tenant_id, id),
  CONSTRAINT ck_match_rule_set_status CHECK (status IN ('DRAFT', 'TESTING', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_match_rule_set_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_match_rule_set_threshold CHECK (auto_merge_threshold >= 0.90 AND review_threshold >= 0 AND auto_merge_threshold - review_threshold >= 0.10),
  CONSTRAINT ck_match_rule_set_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_match_rule_set_active CHECK (status <> 'ACTIVE' OR (evaluation_report_id IS NOT NULL AND decision = 'APPROVE' AND activated_at IS NOT NULL)),
  CONSTRAINT ck_match_rule_set_minattr CHECK (min_attributes BETWEEN 1 AND 20)
);
CREATE UNIQUE INDEX uq_match_rule_set_active ON ph06_mdm.match_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_match_rule_set_touch BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_rule_set_immutable BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no');
CREATE TRIGGER tg_match_rule_set_frozen BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_frozen('blocking_keys', 'auto_merge_threshold', 'review_threshold', 'min_attributes', 'splink_params');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_rule_set');
COMMENT ON TABLE ph06_mdm.match_rule_set IS 'EN-06-10 Phiên bản bộ quy tắc đối sánh (FR-06-018, 019, 023). Ngưỡng ba vùng chốt ở CHECK (BR-06-020); ACTIVE phải có báo cáo đánh giá đạt (BR-06-021) và bất biến nội dung (BR-06-017). Duyệt bốn mắt.';
COMMENT ON COLUMN ph06_mdm.match_rule_set.blocking_keys IS 'Biểu thức khóa gom nhóm, ví dụ prefix(nameAscii.given,3)+year(dateOfBirth) (FR-06-019).';
COMMENT ON COLUMN ph06_mdm.match_rule_set.splink_params IS 'Tham số m, u của Splink sau huấn luyện (FR-06-022).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.match_rule_set CASCADE;

-- @changeset ph06-0220-match-rule
CREATE TABLE ph06_mdm.match_rule (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  version_no     integer NOT NULL,
  seq            smallint NOT NULL,
  rule_type      varchar(16) NOT NULL,
  attribute_name varchar(63) NOT NULL,
  comparator     varchar(16) NOT NULL,
  weight         numeric(5,4),
  params         jsonb NOT NULL DEFAULT '{}',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_rule PRIMARY KEY (id),
  CONSTRAINT ck_match_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_match_rule_seq UNIQUE (tenant_id, domain_code, version_no, seq),
  CONSTRAINT fk_match_rule_set FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.match_rule_set (tenant_id, domain_code, version_no),
  CONSTRAINT ck_match_rule_type CHECK (rule_type IN ('DETERMINISTIC', 'PROBABILISTIC', 'EXCLUSION')),
  CONSTRAINT ck_match_rule_comparator CHECK (comparator IN ('EXACT', 'TRIGRAM', 'JARO_WINKLER', 'NAME_VN', 'DATE_TOLERANCE', 'ADMIN_UNIT', 'PHONE')),
  CONSTRAINT ck_match_rule_weight CHECK (weight IS NULL OR weight BETWEEN 0 AND 1),
  CONSTRAINT ck_match_rule_prob CHECK (rule_type <> 'PROBABILISTIC' OR weight IS NOT NULL)
);
CREATE TRIGGER tg_match_rule_touch BEFORE UPDATE ON ph06_mdm.match_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.match_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('match_rule_set');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_rule');
COMMENT ON TABLE ph06_mdm.match_rule IS 'EN-06-10 Quy tắc con của bộ quy tắc: xác định, xác suất, loại trừ (FR-06-018). Quy tắc EXCLUSION cho khóa định danh khác nhau không tắt được (BR-06-006). Tổng trọng số PROBABILISTIC bằng 1,00 kiểm ở dịch vụ khi gửi duyệt.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.match_rule CASCADE;

-- @changeset ph06-0230-match-job
CREATE TABLE ph06_mdm.match_job (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL DEFAULT '*',
  job_type         varchar(24) NOT NULL,
  status           varchar(24) NOT NULL DEFAULT 'QUEUED',
  scope            varchar(24),
  since            timestamptz,
  train_only       boolean NOT NULL DEFAULT false,
  dry_run          boolean NOT NULL DEFAULT false,
  rule_set_version integer,
  requested_by     varchar(64) NOT NULL,
  parent_job_id    uuid,
  counts           jsonb NOT NULL DEFAULT '{}',
  parameters       jsonb,
  k8s_job_name     varchar(63),
  started_at       timestamptz,
  finished_at      timestamptz,
  confirmed_by     varchar(64),
  confirmed_at     timestamptz,
  cancel_reason    varchar(2000),
  error_code       varchar(16),
  error_detail     varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_job PRIMARY KEY (id),
  CONSTRAINT uq_match_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_match_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_match_job_domain CHECK (domain_code = '*' OR domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_match_job_type CHECK (job_type IN ('BATCH_MATCH', 'RULE_DRY_RUN', 'ACCURACY_EVAL', 'SURVIVORSHIP_REAPPLY', 'REENCRYPT', 'FILE_INGEST', 'EXPORT', 'NATIONAL_SYNC_DOWN', 'NATIONAL_SYNC_UP', 'NATIONAL_RECONCILE', 'RETENTION_PURGE')),
  CONSTRAINT ck_match_job_status CHECK (status IN ('QUEUED', 'PREPARING', 'RUNNING', 'AWAITING_CONFIRMATION', 'APPLYING', 'SUCCEEDED', 'PARTIALLY_SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_match_job_scope CHECK (scope IS NULL OR scope IN ('GOLDEN_VS_GOLDEN', 'CANDIDATES_SINCE', 'FULL_INITIAL')),
  CONSTRAINT ck_match_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-06-1[0-9]{2}$'),
  CONSTRAINT ck_match_job_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_match_job_cancel CHECK (status <> 'CANCELLED' OR cancel_reason IS NOT NULL),
  CONSTRAINT ck_match_job_confirm CHECK (confirmed_by IS NULL OR confirmed_by <> requested_by),
  CONSTRAINT ck_match_job_finished CHECK (status NOT IN ('SUCCEEDED', 'PARTIALLY_SUCCEEDED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_match_job_running ON ph06_mdm.match_job (tenant_id, domain_code, job_type) WHERE status IN ('QUEUED', 'PREPARING', 'RUNNING', 'AWAITING_CONFIRMATION', 'APPLYING');
CREATE INDEX ix_match_job_list ON ph06_mdm.match_job (tenant_id, created_at DESC);
CREATE TRIGGER tg_match_job_touch BEFORE UPDATE ON ph06_mdm.match_job FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_job_immutable BEFORE UPDATE ON ph06_mdm.match_job FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('job_type', 'domain_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_job');
COMMENT ON TABLE ph06_mdm.match_job IS 'EN-06-12 Job theo lô và job nền (FR-06-022, 056): đối sánh Splink, chạy thử, đánh giá, áp lại sống sót, mã hóa lại, nạp tệp, xuất, đồng bộ quốc gia, dọn lưu giữ. Máy trạng thái 4.5. Một job đang chạy mỗi (domain, loại) (ERR-06-025). Job lô vượt safety-ratio dừng ở AWAITING_CONFIRMATION (BR-06-022).';
COMMENT ON COLUMN ph06_mdm.match_job.confirmed_by IS 'DA xác nhận job vượt ngưỡng an toàn, khác người yêu cầu.';
COMMENT ON COLUMN ph06_mdm.match_job.counts IS 'input, pairs, match, possible, noMatch, applied, skipped (FR-06-022).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.match_job CASCADE;

-- @changeset ph06-0240-job-schedule
CREATE TABLE ph06_mdm.job_schedule (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  job_type             varchar(24) NOT NULL,
  cron                 varchar(64) NOT NULL,
  enabled              boolean NOT NULL DEFAULT true,
  params               jsonb NOT NULL DEFAULT '{}',
  max_duration_minutes integer NOT NULL DEFAULT 240,
  next_run_at          timestamptz,
  last_run_at          timestamptz,
  last_job_id          uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_job_schedule PRIMARY KEY (id),
  CONSTRAINT ck_job_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_job_schedule_type UNIQUE (tenant_id, job_type),
  CONSTRAINT ck_job_schedule_type CHECK (job_type IN ('BATCH_MATCH', 'RULE_DRY_RUN', 'ACCURACY_EVAL', 'SURVIVORSHIP_REAPPLY', 'REENCRYPT', 'FILE_INGEST', 'EXPORT', 'NATIONAL_SYNC_DOWN', 'NATIONAL_SYNC_UP', 'NATIONAL_RECONCILE', 'RETENTION_PURGE')),
  CONSTRAINT ck_job_schedule_duration CHECK (max_duration_minutes BETWEEN 5 AND 1440),
  CONSTRAINT ck_job_schedule_cron CHECK (cron ~ '^[0-9*/,-]+( [0-9*/,?LW#-]+){4,5}$')
);
CREATE TRIGGER tg_job_schedule_touch BEFORE UPDATE ON ph06_mdm.job_schedule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_job_schedule_immutable BEFORE UPDATE ON ph06_mdm.job_schedule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('job_type');
CALL ph06_mdm.p_enable_rls('ph06_mdm.job_schedule');
COMMENT ON TABLE ph06_mdm.job_schedule IS 'EN-06-24 FR-06-056 Lịch job tự động theo loại (cron giờ Việt Nam). Mỗi tenant một dòng cho mỗi JobType; ScheduleJob (ShedLock) đọc next_run_at.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.job_schedule CASCADE;

-- @changeset ph06-0250-match-staging
CREATE TABLE ph06_mdm.match_staging (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  job_id         uuid NOT NULL,
  candidate_id   uuid,
  golden_id      uuid,
  source_version bigint,
  fields         jsonb NOT NULL,
  block_keys     varchar(72)[] NOT NULL DEFAULT '{}',
  exported_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_match_staging PRIMARY KEY (id),
  CONSTRAINT ck_match_staging_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_match_staging_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph06_mdm.match_job (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_match_staging_ref CHECK ((candidate_id IS NULL) <> (golden_id IS NULL))
);
CREATE INDEX ix_match_staging_job ON ph06_mdm.match_staging (tenant_id, job_id);
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_staging');
COMMENT ON TABLE ph06_mdm.match_staging IS 'EN-06-27 FR-06-022 Bảng trung gian xuất cho Job K8s Splink đọc (SAD: đối sánh lô qua staging). Chỉ chứa trường chuẩn hóa không SENSITIVE và HMAC; xóa sau job (retention 7 ngày, BR-06-031). Job Splink đọc bằng vai trò ph06_splink (chỉ SELECT match_staging, chỉ INSERT match_result), không ghi thẳng vào bản ghi vàng.';
COMMENT ON COLUMN ph06_mdm.match_staging.fields IS 'Thuộc tính chuẩn hóa; trường SENSITIVE chỉ dạng HMAC, không bao giờ bản rõ (BR-06-016).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.match_staging CASCADE;

-- @changeset ph06-0260-match-result
CREATE TABLE ph06_mdm.match_result (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  scored_at            timestamptz NOT NULL DEFAULT now(),
  domain_code          varchar(32) NOT NULL,
  left_candidate_id    uuid,
  left_golden_id       uuid,
  right_golden_id      uuid NOT NULL,
  method               varchar(24) NOT NULL,
  outcome              varchar(16) NOT NULL,
  score                numeric(5,4),
  attribute_scores     jsonb NOT NULL DEFAULT '{}',
  rule_set_version     integer,
  job_id               uuid,
  queue_item_id        uuid,
  applied              boolean NOT NULL DEFAULT false,
  applied_operation_id uuid,
  skip_code            varchar(16),
  CONSTRAINT pk_match_result PRIMARY KEY (id, scored_at),
  CONSTRAINT ck_match_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_match_result_method CHECK (method IN ('DETERMINISTIC', 'PROBABILISTIC_ONLINE', 'PROBABILISTIC_BATCH', 'MANUAL', 'NATIONAL_SYNC')),
  CONSTRAINT ck_match_result_outcome CHECK (outcome IN ('MATCH', 'POSSIBLE_MATCH', 'NO_MATCH', 'CONFLICT')),
  CONSTRAINT ck_match_result_left CHECK ((left_candidate_id IS NULL) <> (left_golden_id IS NULL)),
  CONSTRAINT ck_match_result_score CHECK (score IS NULL OR score BETWEEN 0 AND 1),
  CONSTRAINT ck_match_result_skip CHECK (skip_code IS NULL OR skip_code = 'ERR-06-104'),
  CONSTRAINT ck_match_result_deterministic CHECK (method <> 'DETERMINISTIC' OR score = 1)
) PARTITION BY RANGE (scored_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.match_result', current_date, 3);
CREATE INDEX ix_match_result_candidate ON ph06_mdm.match_result (tenant_id, left_candidate_id) WHERE left_candidate_id IS NOT NULL;
CREATE INDEX ix_match_result_golden ON ph06_mdm.match_result (tenant_id, right_golden_id, scored_at DESC);
CREATE INDEX ix_match_result_job ON ph06_mdm.match_result (tenant_id, job_id) WHERE job_id IS NOT NULL;
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_result');
COMMENT ON TABLE ph06_mdm.match_result IS 'EN-06-11 Kết quả đối sánh một cặp (ứng viên hoặc bản ghi vàng với bản ghi vàng) (FR-06-020…023). Lưu điểm từng thuộc tính theo ComparisonLevel để giải thích. Phân vùng tháng theo scored_at; giữ 2 năm để hiệu chỉnh thuật toán (SRS cũ 4.3).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.match_result CASCADE;

-- @changeset ph06-0270-label-set
CREATE TABLE ph06_mdm.label_set (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  label_set_code varchar(63) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  purpose        varchar(16) NOT NULL,
  description    varchar(2000),
  pair_count     integer NOT NULL DEFAULT 0,
  locked         boolean NOT NULL DEFAULT false,
  locked_at      timestamptz,
  locked_by      varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_label_set PRIMARY KEY (id),
  CONSTRAINT uq_label_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_label_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_label_set_code UNIQUE (tenant_id, label_set_code),
  CONSTRAINT fk_label_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_label_set_code CHECK (label_set_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_label_set_purpose CHECK (purpose IN ('EVALUATION', 'TRAINING')),
  CONSTRAINT ck_label_set_count CHECK (pair_count >= 0),
  CONSTRAINT ck_label_set_locked CHECK (locked = (locked_at IS NOT NULL AND locked_by IS NOT NULL))
);
CREATE TRIGGER tg_label_set_touch BEFORE UPDATE ON ph06_mdm.label_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_label_set_immutable BEFORE UPDATE ON ph06_mdm.label_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('label_set_code', 'domain_code', 'purpose');
CALL ph06_mdm.p_enable_rls('ph06_mdm.label_set');
COMMENT ON TABLE ph06_mdm.label_set IS 'EN-06-15 Tập nhãn kiểm chứng (FR-06-025): EVALUATION để đo precision, recall; TRAINING để huấn luyện Splink. Nghiệm thu cần ≥ 10.000 cặp (NFR-06-008).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.label_set CASCADE;

-- @changeset ph06-0280-label-pair
CREATE TABLE ph06_mdm.label_pair (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  label_set_id   uuid NOT NULL,
  left_id        uuid NOT NULL,
  right_id       uuid NOT NULL,
  label          varchar(8) NOT NULL,
  labeled_by     varchar(64) NOT NULL,
  source_item_id uuid,
  snapshot_enc   bytea,
  snapshot_kid   varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_label_pair PRIMARY KEY (id),
  CONSTRAINT ck_label_pair_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_label_pair UNIQUE (tenant_id, label_set_id, left_id, right_id),
  CONSTRAINT fk_label_pair_set FOREIGN KEY (tenant_id, label_set_id) REFERENCES ph06_mdm.label_set (tenant_id, id),
  CONSTRAINT ck_label_pair_label CHECK (label IN ('MATCH', 'NO_MATCH')),
  CONSTRAINT ck_label_pair_order CHECK (left_id < right_id),
  CONSTRAINT ck_label_pair_snapshot CHECK (snapshot_enc IS NULL OR snapshot_kid IS NOT NULL)
);
CREATE TRIGGER tg_label_pair_touch BEFORE UPDATE ON ph06_mdm.label_pair FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_label_pair_immutable BEFORE UPDATE ON ph06_mdm.label_pair FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('label_set_id', 'left_id', 'right_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.label_pair');
COMMENT ON TABLE ph06_mdm.label_pair IS 'EN-06-15 Cặp có nhãn MATCH, NO_MATCH của tập nhãn (FR-06-025, 030 addToLabelSet). Hai đầu theo thứ tự chuẩn left_id < right_id; ảnh chụp thuộc tính hai bên mã hóa để đánh giá lặp lại ổn định.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.label_pair CASCADE;


-- @file 06-0040-steward.sql
-- @changeset ph06-0290-steward-item
CREATE TABLE ph06_mdm.steward_item (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  reason            varchar(24) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'OPEN',
  risk_level        varchar(4) NOT NULL DEFAULT 'LOW',
  priority          smallint NOT NULL DEFAULT 50,
  left_candidate_id uuid,
  left_golden_id    uuid,
  right_golden_id   uuid,
  match_result_id   uuid,
  score             numeric(5,4),
  attribute_scores  jsonb NOT NULL DEFAULT '{}',
  source_codes      varchar(32)[] NOT NULL DEFAULT '{}',
  assignee          varchar(64),
  claimed_at        timestamptz,
  hold_until        timestamptz,
  due_at            timestamptz NOT NULL,
  escalated_at      timestamptz,
  defer_until       timestamptz,
  decision          varchar(8),
  decision_reason   varchar(2000),
  decided_by        varchar(64),
  decided_at        timestamptz,
  survivor_id       uuid,
  approval_decision varchar(8),
  approved_by       varchar(64),
  approved_at       timestamptz,
  approval_comment  varchar(2000),
  operation_id      uuid,
  cancel_reason     varchar(500),
  reopen_count      smallint NOT NULL DEFAULT 0,
  reopened_at       timestamptz,
  reopened_by       varchar(64),
  reopen_reason     varchar(2000),
  decision_history  jsonb NOT NULL DEFAULT '[]',
  dq_context        jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_steward_item PRIMARY KEY (id),
  CONSTRAINT uq_steward_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_steward_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_steward_item_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_steward_item_reason CHECK (reason IN ('POSSIBLE_MATCH', 'MULTIPLE_CANDIDATES', 'INSUFFICIENT_ATTRIBUTES', 'CRITICAL_CONFLICT', 'IDENTIFIER_CONFLICT', 'ORPHANED', 'TIMEOUT', 'DQ_FINDING')),
  CONSTRAINT ck_steward_item_status CHECK (status IN ('OPEN', 'ASSIGNED', 'DEFERRED', 'PENDING_APPROVAL', 'RESOLVED', 'CANCELLED')),
  CONSTRAINT ck_steward_item_risk CHECK (risk_level IN ('LOW', 'HIGH')),
  CONSTRAINT ck_steward_item_decision CHECK (decision IS NULL OR decision IN ('MATCH', 'NO_MATCH', 'DEFER')),
  CONSTRAINT ck_steward_item_approval CHECK (approval_decision IS NULL OR approval_decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_steward_item_priority CHECK (priority BETWEEN 1 AND 100),
  CONSTRAINT ck_steward_item_left CHECK ((left_candidate_id IS NULL) <> (left_golden_id IS NULL) OR status = 'CANCELLED'),
  CONSTRAINT ck_steward_item_reason20 CHECK (decision_reason IS NULL OR char_length(decision_reason) >= 20),
  CONSTRAINT ck_steward_item_four_eyes CHECK (approved_by IS NULL OR decided_by IS NULL OR approved_by <> decided_by),
  CONSTRAINT ck_steward_item_pending CHECK (status <> 'PENDING_APPROVAL' OR (decision = 'MATCH' AND risk_level = 'HIGH' AND decided_by IS NOT NULL)),
  CONSTRAINT ck_steward_item_resolved CHECK (status <> 'RESOLVED' OR (decision IN ('MATCH', 'NO_MATCH') AND decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_steward_item_assigned CHECK (status NOT IN ('ASSIGNED', 'PENDING_APPROVAL') OR assignee IS NOT NULL),
  CONSTRAINT ck_steward_item_defer CHECK ((status = 'DEFERRED') = (defer_until IS NOT NULL)),
  CONSTRAINT ck_steward_item_dq CHECK (reason <> 'DQ_FINDING' OR (left_golden_id IS NOT NULL AND right_golden_id IS NULL AND dq_context IS NOT NULL AND decision IS DISTINCT FROM 'MATCH')),
  CONSTRAINT ck_steward_item_dqctx CHECK (dq_context IS NULL OR reason = 'DQ_FINDING')
);
CREATE UNIQUE INDEX uq_steward_item_open_pair ON ph06_mdm.steward_item (tenant_id, domain_code, COALESCE(left_candidate_id, left_golden_id), right_golden_id) WHERE status NOT IN ('RESOLVED', 'CANCELLED') AND right_golden_id IS NOT NULL;
CREATE UNIQUE INDEX uq_steward_item_open_dq ON ph06_mdm.steward_item (tenant_id, domain_code, left_golden_id) WHERE reason = 'DQ_FINDING' AND status NOT IN ('RESOLVED', 'CANCELLED');
CREATE INDEX ix_steward_item_queue ON ph06_mdm.steward_item (tenant_id, domain_code, status, priority DESC, due_at);
CREATE INDEX ix_steward_item_assignee ON ph06_mdm.steward_item (tenant_id, assignee, status) WHERE assignee IS NOT NULL;
CREATE INDEX ix_steward_item_nomatch ON ph06_mdm.steward_item (tenant_id, domain_code, left_golden_id, right_golden_id) WHERE decision = 'NO_MATCH' AND status = 'RESOLVED';
CREATE TRIGGER tg_steward_item_touch BEFORE UPDATE ON ph06_mdm.steward_item FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_steward_item_immutable BEFORE UPDATE ON ph06_mdm.steward_item FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'left_candidate_id', 'left_golden_id', 'right_golden_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.steward_item');
COMMENT ON TABLE ph06_mdm.steward_item IS 'EN-06-05 Mục hàng đợi người quản lý dữ liệu (FR-06-027…032). Máy trạng thái 4.4. Quyết định cần lý do ≥ 20 ký tự (BR-06-008); MATCH rủi ro cao chờ DA duyệt khác người quyết định (BR-06-019, ERR-06-005). Mỗi cặp một mục mở.';
COMMENT ON COLUMN ph06_mdm.steward_item.hold_until IS 'Hết hạn giữ 30 phút (06.queue.hold-minutes) thì trả OPEN.';
COMMENT ON COLUMN ph06_mdm.steward_item.left_golden_id IS 'Cặp NO_MATCH đã RESOLVED là liên kết âm (BR-06-023): không đề xuất lại; chỉ mục ix_steward_item_nomatch. Mục DQ_FINDING chỉ có left_golden_id.';
COMMENT ON COLUMN ph06_mdm.steward_item.dq_context IS 'Chỉ cho lý do DQ_FINDING (PH-08, API-06-126): ruleCodes, suggestedAction, findingIds, note; mỗi goldenId một mục mở (uq_steward_item_open_dq).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.steward_item CASCADE;


-- @file 06-0050-golden.sql
-- @changeset ph06-0300-golden-record
CREATE TABLE ph06_mdm.golden_record (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  domain_code        varchar(32) NOT NULL,
  model_version      integer NOT NULL,
  status             varchar(8) NOT NULL DEFAULT 'ACTIVE',
  merged_into        uuid,
  confidence         numeric(5,4),
  display_name       varchar(255),
  name_norm          varchar(255),
  birth_year         smallint,
  admin_unit_code    varchar(16),
  link_count         integer NOT NULL DEFAULT 0,
  block_keys         varchar(72)[] NOT NULL DEFAULT '{}',
  restricted         boolean NOT NULL DEFAULT false,
  lock_reason        varchar(500),
  retire_reason      varchar(16),
  retire_note        varchar(2000),
  retired_at         timestamptz,
  retired_by         varchar(64),
  national_synced_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 1,
  CONSTRAINT pk_golden_record PRIMARY KEY (id),
  CONSTRAINT uq_golden_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_golden_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_record_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_golden_record_merged FOREIGN KEY (tenant_id, merged_into) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_record_status CHECK (status IN ('ACTIVE', 'LOCKED', 'MERGED', 'RETIRED')),
  CONSTRAINT ck_golden_record_merged CHECK ((status = 'MERGED') = (merged_into IS NOT NULL) AND merged_into IS DISTINCT FROM id),
  CONSTRAINT ck_golden_record_retired CHECK ((status = 'RETIRED') = (retire_reason IS NOT NULL)),
  CONSTRAINT ck_golden_record_retire CHECK (retire_reason IS NULL OR retire_reason IN ('ORPHANED', 'DISSOLVED', 'DECEASED', 'TEST_DATA', 'OTHER')),
  CONSTRAINT ck_golden_record_locked CHECK (status <> 'LOCKED' OR lock_reason IS NOT NULL),
  CONSTRAINT ck_golden_record_restricted CHECK (NOT restricted OR status = 'LOCKED'),
  CONSTRAINT ck_golden_record_confidence CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  CONSTRAINT ck_golden_record_birth CHECK (birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100)
);
CREATE INDEX ix_golden_record_domain ON ph06_mdm.golden_record (tenant_id, domain_code, status);
CREATE INDEX ix_golden_record_name_trgm ON ph06_mdm.golden_record USING gin (domain_code, name_norm gin_trgm_ops);
CREATE INDEX ix_golden_record_blocks ON ph06_mdm.golden_record USING gin (block_keys);
CREATE INDEX ix_golden_record_area ON ph06_mdm.golden_record (tenant_id, domain_code, admin_unit_code, birth_year) WHERE status = 'ACTIVE';
CREATE INDEX ix_golden_record_merged ON ph06_mdm.golden_record (tenant_id, merged_into) WHERE merged_into IS NOT NULL;
CREATE TRIGGER tg_golden_record_touch BEFORE UPDATE ON ph06_mdm.golden_record FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_record_immutable BEFORE UPDATE ON ph06_mdm.golden_record FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_record');
COMMENT ON TABLE ph06_mdm.golden_record IS 'EN-06-01 Bản ghi vàng (FR-06-034…042). goldenId là id (UUIDv7); version bắt đầu 1 và tăng mỗi thay đổi, là số phiên bản trong lịch sử. Không xóa (BR-06-007): chỉ MERGED hoặc RETIRED. Cột display_name, name_norm, birth_year, admin_unit_code là bản sao có chỉ mục để tìm nhanh bằng pg_trgm.';
COMMENT ON COLUMN ph06_mdm.golden_record.model_version IS 'Phiên bản mô hình domain áp khi tạo hoặc cập nhật gần nhất.';
COMMENT ON COLUMN ph06_mdm.golden_record.name_norm IS 'Họ tên hoặc tên tổ chức không dấu, chữ thường; chỉ mục GIN gin_trgm_ops (cần btree_gin cho domain_code).';
COMMENT ON COLUMN ph06_mdm.golden_record.version IS 'Phiên bản bản ghi vàng, ETag; ghi ảnh chụp golden_history trước khi tăng (BR-06-005).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.golden_record CASCADE;

-- @changeset ph06-0310-golden-attribute
CREATE TABLE ph06_mdm.golden_attribute (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  golden_id          uuid NOT NULL,
  attribute_name     varchar(63) NOT NULL,
  seq                smallint NOT NULL DEFAULT 0,
  data_class         varchar(16) NOT NULL,
  value_json         jsonb,
  value_enc          bytea,
  value_kid          varchar(64),
  value_hash         bytea,
  source_code        varchar(32) NOT NULL,
  source_key         varchar(120),
  source_updated_at  timestamptz,
  strategy           varchar(24) NOT NULL,
  confidence         numeric(5,4),
  manual_valid_until timestamptz,
  national_authority boolean NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_attribute PRIMARY KEY (id),
  CONSTRAINT ck_golden_attribute_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_golden_attribute UNIQUE (tenant_id, golden_id, attribute_name, seq),
  CONSTRAINT fk_golden_attribute_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_attribute_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_golden_attribute_strategy CHECK (strategy IN ('NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE')),
  CONSTRAINT ck_golden_attribute_name CHECK (attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_golden_attribute_sensitive CHECK ((data_class = 'SENSITIVE' AND value_json IS NULL AND value_enc IS NOT NULL AND value_hash IS NOT NULL AND value_kid IS NOT NULL) OR (data_class <> 'SENSITIVE' AND value_enc IS NULL AND value_hash IS NULL)),
  CONSTRAINT ck_golden_attribute_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_golden_attribute_manual CHECK (strategy <> 'MANUAL_OVERRIDE' OR manual_valid_until IS NOT NULL),
  CONSTRAINT ck_golden_attribute_authority CHECK (NOT national_authority OR strategy = 'NATIONAL_AUTHORITY')
);
CREATE INDEX ix_golden_attribute_hash ON ph06_mdm.golden_attribute (tenant_id, attribute_name, value_hash) WHERE value_hash IS NOT NULL;
CREATE INDEX ix_golden_attribute_source ON ph06_mdm.golden_attribute (tenant_id, source_code, source_key);
CREATE TRIGGER tg_golden_attribute_touch BEFORE UPDATE ON ph06_mdm.golden_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_attribute');
COMMENT ON TABLE ph06_mdm.golden_attribute IS 'EN-06-02 Giá trị thuộc tính vàng kèm nguồn ở cấp thuộc tính (FR-06-034, 035, BR-06-009). SENSITIVE chỉ ở value_enc kèm value_hash, không ở value_json (CHECK, NFR-06-016). Thuộc tính đa trị dùng seq. Sửa tay tạm thời có hạn manual_valid_until (BR-06-014).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.value_hash IS 'HMAC-SHA256 giá trị đã chuẩn hóa; đối sánh bằng, không giải mã (BR-06-016).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.manual_valid_until IS 'Sửa tay có hạn ≤ 90 ngày, mặc định 30 (FR-06-036).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.national_authority IS 'Thuộc tính thẩm quyền quốc gia: không sửa tay (BR-06-025).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.golden_attribute CASCADE;

-- @changeset ph06-0320-golden-identifier
CREATE TABLE ph06_mdm.golden_identifier (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  golden_id       uuid NOT NULL,
  domain_code     varchar(32) NOT NULL,
  identifier_type varchar(16) NOT NULL,
  value_hash      bytea NOT NULL,
  value_enc       bytea NOT NULL,
  value_kid       varchar(64) NOT NULL,
  active          boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_identifier PRIMARY KEY (id),
  CONSTRAINT ck_golden_identifier_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_identifier_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_identifier_type CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_golden_identifier_hash CHECK (octet_length(value_hash) = 32)
);
CREATE UNIQUE INDEX uq_golden_identifier_active ON ph06_mdm.golden_identifier (tenant_id, domain_code, identifier_type, value_hash) WHERE active;
CREATE INDEX ix_golden_identifier_golden ON ph06_mdm.golden_identifier (tenant_id, golden_id);
CREATE TRIGGER tg_golden_identifier_touch BEFORE UPDATE ON ph06_mdm.golden_identifier FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_identifier_immutable BEFORE UPDATE ON ph06_mdm.golden_identifier FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('golden_id', 'domain_code', 'identifier_type', 'value_hash');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_identifier');
COMMENT ON TABLE ph06_mdm.golden_identifier IS 'EN-06-02, EN-06-28 Chỉ mục số định danh của bản ghi vàng (FR-06-020, 046, BR-06-001, 006). Một giá trị định danh hiệu lực chỉ thuộc một bản ghi vàng trong domain (chỉ mục duy nhất một phần), nên hai bản ghi vàng cùng CCCD không tồn tại (ERR-06-112 là lỗi bất biến). Giá trị rõ không lưu; value_enc mã hóa envelope, value_hash HMAC.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.golden_identifier CASCADE;

-- @changeset ph06-0330-source-xref
CREATE TABLE ph06_mdm.source_xref (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_code          varchar(32) NOT NULL,
  golden_id            uuid NOT NULL,
  source_code          varchar(32) NOT NULL,
  source_key           varchar(120) NOT NULL,
  status               varchar(8) NOT NULL DEFAULT 'ACTIVE',
  match_method         varchar(24) NOT NULL,
  score                numeric(5,4),
  candidate_id         uuid,
  confirmed_by_steward boolean NOT NULL DEFAULT false,
  linked_by            varchar(64) NOT NULL,
  linked_at            timestamptz NOT NULL DEFAULT now(),
  detached_at          timestamptz,
  detached_by          varchar(64),
  detach_reason        varchar(16),
  detach_note          varchar(2000),
  moved_to_golden_id   uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_xref PRIMARY KEY (id),
  CONSTRAINT uq_source_xref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_source_xref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_xref_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT fk_source_xref_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_xref_status CHECK (status IN ('ACTIVE', 'DETACHED', 'MOVED')),
  CONSTRAINT ck_source_xref_method CHECK (match_method IN ('DETERMINISTIC', 'PROBABILISTIC_ONLINE', 'PROBABILISTIC_BATCH', 'MANUAL', 'NATIONAL_SYNC')),
  CONSTRAINT ck_source_xref_detach CHECK (detach_reason IS NULL OR detach_reason IN ('MANUAL', 'SOURCE_DELETED', 'SPLIT')),
  CONSTRAINT ck_source_xref_detached CHECK ((status = 'ACTIVE') = (detached_at IS NULL AND detach_reason IS NULL AND moved_to_golden_id IS NULL) OR (status = 'MOVED' AND detached_at IS NOT NULL)),
  CONSTRAINT ck_source_xref_moved CHECK ((status = 'MOVED') = (moved_to_golden_id IS NOT NULL)),
  CONSTRAINT ck_source_xref_manual CHECK (detach_reason IS DISTINCT FROM 'MANUAL' OR COALESCE(char_length(detach_note) >= 20, false))
);
CREATE UNIQUE INDEX uq_source_xref_active ON ph06_mdm.source_xref (tenant_id, domain_code, source_code, source_key) WHERE status = 'ACTIVE';
CREATE INDEX ix_source_xref_golden ON ph06_mdm.source_xref (tenant_id, golden_id, status);
CREATE TRIGGER tg_source_xref_touch BEFORE UPDATE ON ph06_mdm.source_xref FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_source_xref_immutable BEFORE UPDATE ON ph06_mdm.source_xref FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'source_code', 'source_key');
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_xref');
COMMENT ON TABLE ph06_mdm.source_xref IS 'EN-06-03 Liên kết chéo nguồn (sourceCode, sourceKey) với bản ghi vàng (FR-06-044, 045, BR-06-018). Một bản ghi nguồn chỉ có một liên kết ACTIVE tại một thời điểm (chỉ mục duy nhất một phần). Gỡ ghi lý do; liên kết do người xác nhận không bị tự tách (BR-06-023).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.source_xref CASCADE;

-- @changeset ph06-0340-golden-operation
CREATE TABLE ph06_mdm.golden_operation (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  change_type       varchar(24) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'APPLIED',
  risk_level        varchar(4) NOT NULL DEFAULT 'LOW',
  golden_ids        uuid[] NOT NULL,
  survivor_id       uuid,
  result_golden_ids uuid[] NOT NULL DEFAULT '{}',
  reason            varchar(2000) NOT NULL,
  evidence_ref      varchar(255),
  payload           jsonb NOT NULL DEFAULT '{}',
  requested_by      varchar(64) NOT NULL,
  requested_at      timestamptz NOT NULL DEFAULT now(),
  decision          varchar(8),
  approved_by       varchar(64),
  approved_at       timestamptz,
  decision_comment  varchar(2000),
  applied_at        timestamptz,
  undo_of           uuid,
  batch_job_id      uuid,
  source_item_id    uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_operation PRIMARY KEY (id),
  CONSTRAINT uq_golden_operation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_golden_operation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_operation_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_golden_operation_undo FOREIGN KEY (tenant_id, undo_of) REFERENCES ph06_mdm.golden_operation (tenant_id, id),
  CONSTRAINT ck_golden_operation_type CHECK (change_type IN ('CREATE', 'UPDATE', 'MANUAL_EDIT', 'MERGE', 'SPLIT', 'UNDO', 'RETIRE', 'RESTORE', 'NATIONAL_SYNC', 'SURVIVORSHIP_REAPPLY', 'DSR_CORRECTION', 'XREF_DETACH')),
  CONSTRAINT ck_golden_operation_status CHECK (status IN ('PENDING_APPROVAL', 'APPLIED', 'REJECTED', 'UNDONE')),
  CONSTRAINT ck_golden_operation_risk CHECK (risk_level IN ('LOW', 'HIGH')),
  CONSTRAINT ck_golden_operation_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_golden_operation_reason20 CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_golden_operation_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_golden_operation_pending CHECK (status <> 'PENDING_APPROVAL' OR risk_level = 'HIGH'),
  CONSTRAINT ck_golden_operation_applied CHECK (status NOT IN ('APPLIED', 'UNDONE') OR applied_at IS NOT NULL),
  CONSTRAINT ck_golden_operation_undo CHECK ((change_type = 'UNDO') = (undo_of IS NOT NULL)),
  CONSTRAINT ck_golden_operation_merge CHECK (change_type <> 'MERGE' OR (cardinality(golden_ids) BETWEEN 2 AND 10 AND survivor_id IS NOT NULL))
);
CREATE INDEX ix_golden_operation_golden ON ph06_mdm.golden_operation USING gin (golden_ids);
CREATE INDEX ix_golden_operation_pending ON ph06_mdm.golden_operation (tenant_id, domain_code, requested_at) WHERE status = 'PENDING_APPROVAL';
CREATE UNIQUE INDEX uq_golden_operation_undo ON ph06_mdm.golden_operation (tenant_id, undo_of) WHERE undo_of IS NOT NULL AND status <> 'REJECTED';
CREATE TRIGGER tg_golden_operation_touch BEFORE UPDATE ON ph06_mdm.golden_operation FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_operation_immutable BEFORE UPDATE ON ph06_mdm.golden_operation FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'change_type', 'golden_ids', 'reason', 'requested_by', 'requested_at', 'undo_of');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_operation');
COMMENT ON TABLE ph06_mdm.golden_operation IS 'EN-06-13 Thao tác trên bản ghi vàng: hợp nhất, tách, sửa tay, hoàn tác, ngừng, khôi phục, áp lại sống sót (FR-06-036…042). Mọi thay đổi bản ghi vàng đi qua một thao tác (BR-06-005). Lý do ≥ 20 ký tự (BR-06-008); rủi ro cao chờ DA duyệt khác người yêu cầu (BR-06-019). Hoàn tác là thao tác mới trỏ undo_of, không xóa lịch sử (BR-06-024).';
COMMENT ON COLUMN ph06_mdm.golden_operation.batch_job_id IS 'batchOperationId của job lô (NFR, tiêu chí 9).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.golden_operation CASCADE;

-- @changeset ph06-0350-golden-history
CREATE TABLE ph06_mdm.golden_history (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  changed_at         timestamptz NOT NULL DEFAULT now(),
  golden_id          uuid NOT NULL,
  version_no         integer NOT NULL,
  change_type        varchar(24) NOT NULL,
  operation_id       uuid,
  snapshot_enc       bytea NOT NULL,
  snapshot_kid       varchar(64) NOT NULL,
  snapshot_sha256    bytea NOT NULL,
  changed_attributes varchar(63)[] NOT NULL DEFAULT '{}',
  changed_by         varchar(64) NOT NULL,
  CONSTRAINT pk_golden_history PRIMARY KEY (id, changed_at),
  CONSTRAINT ck_golden_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_history_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_history_type CHECK (change_type IN ('CREATE', 'UPDATE', 'MANUAL_EDIT', 'MERGE', 'SPLIT', 'UNDO', 'RETIRE', 'RESTORE', 'NATIONAL_SYNC', 'SURVIVORSHIP_REAPPLY', 'DSR_CORRECTION', 'XREF_DETACH')),
  CONSTRAINT ck_golden_history_sha CHECK (octet_length(snapshot_sha256) = 32),
  CONSTRAINT ck_golden_history_version CHECK (version_no >= 1),
  CONSTRAINT ck_golden_history_snapshot CHECK (octet_length(snapshot_enc) BETWEEN 29 AND 4194304)
) PARTITION BY RANGE (changed_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.golden_history', current_date, 3);
CREATE INDEX ix_golden_history_golden ON ph06_mdm.golden_history (tenant_id, golden_id, version_no DESC);
CREATE INDEX ix_golden_history_operation ON ph06_mdm.golden_history (tenant_id, operation_id) WHERE operation_id IS NOT NULL;
CREATE TRIGGER tg_golden_history_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.golden_history FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_history');
COMMENT ON TABLE ph06_mdm.golden_history IS 'EN-06-06 Ảnh chụp đầy đủ bản ghi vàng (thuộc tính, liên kết) trước mỗi thay đổi, cùng giao dịch (BR-06-005). Phục vụ xem phiên bản, so sánh, hoàn tác. snapshot_enc mã hóa envelope vì chứa DLCN. Chỉ thêm, không sửa (trigger). Phân vùng tháng theo changed_at; chuyển lưu trữ lạnh sau 5 năm, không xóa (BR-06-007, SRS cũ: vĩnh viễn).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.golden_history CASCADE;

-- @changeset ph06-0360-attribute-lineage
CREATE TABLE ph06_mdm.attribute_lineage (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  recorded_at       timestamptz NOT NULL DEFAULT now(),
  golden_id         uuid NOT NULL,
  golden_version    integer NOT NULL,
  attribute_name    varchar(63) NOT NULL,
  seq               smallint NOT NULL DEFAULT 0,
  operation_id      uuid,
  source_code       varchar(32) NOT NULL,
  source_key        varchar(120),
  source_version    bigint,
  source_updated_at timestamptz,
  strategy          varchar(24) NOT NULL,
  selected          boolean NOT NULL DEFAULT true,
  data_class        varchar(16) NOT NULL,
  value_enc         bytea,
  value_kid         varchar(64),
  value_hash        bytea,
  CONSTRAINT pk_attribute_lineage PRIMARY KEY (id, recorded_at),
  CONSTRAINT ck_attribute_lineage_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_attribute_lineage_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_attribute_lineage_strategy CHECK (strategy IN ('NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE')),
  CONSTRAINT ck_attribute_lineage_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_attribute_lineage_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_attribute_lineage_enc CHECK (value_enc IS NULL OR value_kid IS NOT NULL)
) PARTITION BY RANGE (recorded_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.attribute_lineage', current_date, 3);
CREATE INDEX ix_attribute_lineage_golden ON ph06_mdm.attribute_lineage (tenant_id, golden_id, attribute_name, recorded_at DESC);
CREATE TRIGGER tg_attribute_lineage_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.attribute_lineage FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.attribute_lineage');
COMMENT ON TABLE ph06_mdm.attribute_lineage IS 'EN-06-14 Lịch sử giá trị và nguồn của từng thuộc tính vàng (FR-06-043, BR-06-009): giá trị nào, từ nguồn nào, chiến lược nào chọn, lúc nào. Giá trị mã hóa envelope; value_hash để so khớp. Chỉ thêm. Phân vùng tháng theo recorded_at; chuyển lưu trữ lạnh sau 5 năm, không xóa.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.attribute_lineage CASCADE;

-- @changeset ph06-0370-survivorship-rule-set
CREATE TABLE ph06_mdm.survivorship_rule_set (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  comment          varchar(2000),
  approval_ref     varchar(255),
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decision         varchar(8),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_survivorship_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_survivorship_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_survivorship_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_survivorship_rule_set_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_survivorship_rule_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_survivorship_rule_set_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_survivorship_rule_set_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_survivorship_rule_set_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_survivorship_rule_set_active CHECK (status <> 'ACTIVE' OR (decision = 'APPROVE' AND activated_at IS NOT NULL AND approval_ref IS NOT NULL))
);
CREATE UNIQUE INDEX uq_survivorship_rule_set_active ON ph06_mdm.survivorship_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_survivorship_rule_set_touch BEFORE UPDATE ON ph06_mdm.survivorship_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_survivorship_rule_set_immutable BEFORE UPDATE ON ph06_mdm.survivorship_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no');
CALL ph06_mdm.p_enable_rls('ph06_mdm.survivorship_rule_set');
COMMENT ON TABLE ph06_mdm.survivorship_rule_set IS 'EN-06-17 Phiên bản bộ quy tắc sống sót của domain (FR-06-033, 042). Vòng đời 4.6 (không TESTING); một phiên bản ACTIVE mỗi domain; duyệt bốn mắt có căn cứ văn bản (BR-06-004).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.survivorship_rule_set CASCADE;

-- @changeset ph06-0380-survivorship-rule
CREATE TABLE ph06_mdm.survivorship_rule (
  id                         uuid NOT NULL,
  tenant_id                  varchar(16) NOT NULL,
  domain_code                varchar(32) NOT NULL,
  version_no                 integer NOT NULL,
  attribute_name             varchar(63) NOT NULL,
  strategies                 varchar(24)[] NOT NULL,
  critical_conflict_to_queue boolean NOT NULL DEFAULT false,
  national_authority         boolean NOT NULL DEFAULT false,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  created_by                 varchar(64) NOT NULL,
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  updated_by                 varchar(64) NOT NULL,
  version                    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_survivorship_rule PRIMARY KEY (id),
  CONSTRAINT ck_survivorship_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_survivorship_rule_attr UNIQUE (tenant_id, domain_code, version_no, attribute_name),
  CONSTRAINT fk_survivorship_rule_set FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.survivorship_rule_set (tenant_id, domain_code, version_no),
  CONSTRAINT ck_survivorship_rule_strategies CHECK (cardinality(strategies) BETWEEN 1 AND 7 AND strategies <@ ARRAY['NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE']::varchar[]),
  CONSTRAINT ck_survivorship_rule_authority CHECK (NOT national_authority OR strategies[1] = 'NATIONAL_AUTHORITY')
);
CREATE TRIGGER tg_survivorship_rule_touch BEFORE UPDATE ON ph06_mdm.survivorship_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_survivorship_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.survivorship_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('survivorship_rule_set');
CALL ph06_mdm.p_enable_rls('ph06_mdm.survivorship_rule');
COMMENT ON TABLE ph06_mdm.survivorship_rule IS 'EN-06-17 Chiến lược sống sót theo thuộc tính trong một phiên bản (FR-06-033). strategies là chuỗi SurvivorshipStrategy theo thứ tự áp; thuộc tính thẩm quyền quốc gia bắt đầu bằng NATIONAL_AUTHORITY (BR-06-003, 025).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.survivorship_rule CASCADE;


-- @file 06-0060-serve.sql
-- @changeset ph06-0390-update-subscription
CREATE TABLE ph06_mdm.update_subscription (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  system_code            varchar(63) NOT NULL,
  domain_code            varchar(32) NOT NULL,
  scope                  varchar(16) NOT NULL,
  event_types            varchar(32)[] NOT NULL,
  delivery               varchar(4) NOT NULL,
  purpose_code           varchar(63) NOT NULL,
  status                 varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  ph10_subscription_code varchar(63),
  requested_by           varchar(64) NOT NULL,
  approved_by            varchar(64),
  approved_at            timestamptz,
  status_reason          varchar(2000),
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_update_subscription PRIMARY KEY (id),
  CONSTRAINT ck_update_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_update_subscription_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_update_subscription_scope CHECK (scope IN ('LINKED_ONLY', 'DOMAIN')),
  CONSTRAINT ck_update_subscription_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_update_subscription_delivery CHECK (delivery IN ('PUSH', 'PULL')),
  CONSTRAINT ck_update_subscription_events CHECK (cardinality(event_types) >= 1),
  CONSTRAINT ck_update_subscription_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_update_subscription_active CHECK (status NOT IN ('ACTIVE') OR approved_by IS NOT NULL)
);
CREATE UNIQUE INDEX uq_update_subscription_live ON ph06_mdm.update_subscription (tenant_id, system_code, domain_code, scope) WHERE status <> 'REVOKED';
CREATE TRIGGER tg_update_subscription_touch BEFORE UPDATE ON ph06_mdm.update_subscription FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_update_subscription_immutable BEFORE UPDATE ON ph06_mdm.update_subscription FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('system_code', 'domain_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.update_subscription');
COMMENT ON TABLE ph06_mdm.update_subscription IS 'EN-06-18 Đăng ký nhận cập nhật bản ghi vàng của HTTT (FR-06-051). Cần mục đích khai thác đã được PH-09 chấp thuận (ERR-06-043). Kênh giao qua đăng ký PH-10 (ph10_subscription_code). Duyệt bốn mắt.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.update_subscription CASCADE;

-- @changeset ph06-0400-export-request
CREATE TABLE ph06_mdm.export_request (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  filter            jsonb NOT NULL DEFAULT '{}',
  fields            varchar(63)[] NOT NULL,
  format            varchar(8) NOT NULL,
  purpose_code      varchar(63) NOT NULL,
  legal_basis       varchar(2000) NOT NULL,
  recipient         varchar(255) NOT NULL,
  pseudonymize      boolean NOT NULL DEFAULT false,
  status            varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  row_count         integer,
  requested_by      varchar(64) NOT NULL,
  owner_approved_by varchar(64),
  owner_approved_at timestamptz,
  approved_by       varchar(64),
  approved_at       timestamptz,
  reject_reason     varchar(2000),
  file_ref          varchar(512),
  file_sha256       char(64),
  watermark_id      varchar(64),
  ready_at          timestamptz,
  expires_at        timestamptz,
  downloaded_at     timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_export_request PRIMARY KEY (id),
  CONSTRAINT uq_export_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_export_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_export_request_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_export_request_format CHECK (format IN ('CSV', 'XLSX', 'JSONL')),
  CONSTRAINT ck_export_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'GENERATING', 'READY', 'EXPIRED')),
  CONSTRAINT ck_export_request_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_export_request_owner CHECK (owner_approved_by IS NULL OR owner_approved_by <> requested_by),
  CONSTRAINT ck_export_request_approved CHECK (status NOT IN ('APPROVED', 'GENERATING', 'READY') OR (approved_by IS NOT NULL AND owner_approved_by IS NOT NULL)),
  CONSTRAINT ck_export_request_ready CHECK (status <> 'READY' OR (file_ref IS NOT NULL AND file_sha256 IS NOT NULL AND watermark_id IS NOT NULL AND expires_at IS NOT NULL)),
  CONSTRAINT ck_export_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_export_request_rows CHECK (row_count IS NULL OR row_count BETWEEN 0 AND 1000000)
);
CREATE INDEX ix_export_request_status ON ph06_mdm.export_request (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_export_request_touch BEFORE UPDATE ON ph06_mdm.export_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_export_request_immutable BEFORE UPDATE ON ph06_mdm.export_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'filter', 'fields', 'format', 'purpose_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.export_request');
COMMENT ON TABLE ph06_mdm.export_request IS 'EN-06-19 Yêu cầu xuất dữ liệu chủ có duyệt (FR-06-049, BR-06-027): cần chấp thuận của DO các nguồn liên quan và DA; tệp mã hóa, có thủy vân, hạn tải 24 giờ. Tệp ở Ceph RGW (file_ref), không trong PostgreSQL. Giới hạn dòng theo 06.export.max-rows (ERR-06-041).';
COMMENT ON COLUMN ph06_mdm.export_request.expires_at IS 'ready_at + 24 giờ (BR-06-027); sau đó EXPIRED, ERR-06-042.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.export_request CASCADE;

-- @changeset ph06-0410-national-sync-state
CREATE TABLE ph06_mdm.national_sync_state (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  domain_code   varchar(32) NOT NULL,
  state         varchar(8) NOT NULL DEFAULT 'RUNNING',
  paused_reason varchar(2000),
  paused_at     timestamptz,
  paused_by     varchar(64),
  last_run_id   uuid,
  last_ratio    numeric(6,5),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_state PRIMARY KEY (id),
  CONSTRAINT ck_national_sync_state_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_national_sync_state_domain UNIQUE (tenant_id, domain_code),
  CONSTRAINT fk_national_sync_state_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_national_sync_state_state CHECK (state IN ('RUNNING', 'PAUSED')),
  CONSTRAINT ck_national_sync_state_paused CHECK ((state = 'PAUSED') = (paused_at IS NOT NULL AND paused_reason IS NOT NULL)),
  CONSTRAINT ck_national_sync_state_ratio CHECK (last_ratio IS NULL OR last_ratio BETWEEN 0 AND 1)
);
CREATE TRIGGER tg_national_sync_state_touch BEFORE UPDATE ON ph06_mdm.national_sync_state FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_national_sync_state_immutable BEFORE UPDATE ON ph06_mdm.national_sync_state FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code');
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_sync_state');
COMMENT ON TABLE ph06_mdm.national_sync_state IS 'EN-06-29 FR-06-053, 054 Trạng thái đồng bộ quốc gia mỗi domain: RUNNING hoặc PAUSED. Lệch > 06.sync.pause-ratio tạm dừng tự động (BR-06-011, ERR-06-107); tiếp tục cần người có PERM-06-sync.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.national_sync_state CASCADE;

-- @changeset ph06-0420-national-sync-run
CREATE TABLE ph06_mdm.national_sync_run (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  direction         varchar(12) NOT NULL,
  job_id            uuid,
  scope             jsonb NOT NULL DEFAULT '{}',
  checked_count     integer NOT NULL DEFAULT 0,
  discrepancy_count integer NOT NULL DEFAULT 0,
  applied_count     integer NOT NULL DEFAULT 0,
  ratio             numeric(6,5),
  paused            boolean NOT NULL DEFAULT false,
  ph14_ref          varchar(64),
  requested_by      varchar(64) NOT NULL,
  started_at        timestamptz NOT NULL DEFAULT now(),
  finished_at       timestamptz,
  error_code        varchar(16),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_run PRIMARY KEY (id),
  CONSTRAINT uq_national_sync_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_national_sync_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_national_sync_run_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_national_sync_run_direction CHECK (direction IN ('DOWN', 'UP', 'RECONCILE')),
  CONSTRAINT ck_national_sync_run_counts CHECK (checked_count >= 0 AND discrepancy_count >= 0 AND applied_count >= 0 AND discrepancy_count <= checked_count),
  CONSTRAINT ck_national_sync_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-06-10[6-8]$'),
  CONSTRAINT ck_national_sync_run_ratio CHECK (ratio IS NULL OR ratio BETWEEN 0 AND 1)
);
CREATE INDEX ix_national_sync_run_domain ON ph06_mdm.national_sync_run (tenant_id, domain_code, started_at DESC);
CREATE TRIGGER tg_national_sync_run_touch BEFORE UPDATE ON ph06_mdm.national_sync_run FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_sync_run');
COMMENT ON TABLE ph06_mdm.national_sync_run IS 'EN-06-16 Nhật ký một lượt đồng bộ với CSDL tổng hợp quốc gia qua PH-14 (FR-06-053). Tỷ lệ lệch ratio so với ngưỡng BR-06-011. PH-06 không gọi trực tiếp CSDL quốc gia (BR-06-032); ph14_ref là mã giao dịch PH-14.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.national_sync_run CASCADE;

-- @changeset ph06-0430-national-discrepancy
CREATE TABLE ph06_mdm.national_discrepancy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  run_id         uuid NOT NULL,
  domain_code    varchar(32) NOT NULL,
  golden_id      uuid NOT NULL,
  attribute_name varchar(63) NOT NULL,
  severity       varchar(8) NOT NULL,
  status         varchar(24) NOT NULL DEFAULT 'OPEN',
  local_enc      bytea,
  national_enc   bytea,
  value_kid      varchar(64),
  local_hash     bytea,
  national_hash  bytea,
  resolution     varchar(24),
  resolved_by    varchar(64),
  resolved_at    timestamptz,
  resolve_reason varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_discrepancy PRIMARY KEY (id),
  CONSTRAINT ck_national_discrepancy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_national_discrepancy_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph06_mdm.national_sync_run (tenant_id, id),
  CONSTRAINT fk_national_discrepancy_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_national_discrepancy_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_national_discrepancy_status CHECK (status IN ('OPEN', 'ACCEPTED_NATIONAL', 'KEPT_LOCAL', 'REPORTED_TO_NATIONAL', 'IGNORED')),
  CONSTRAINT ck_national_discrepancy_resolution CHECK (resolution IS NULL OR resolution IN ('ACCEPT_NATIONAL', 'KEEP_LOCAL', 'REPORT_TO_NATIONAL', 'IGNORE')),
  CONSTRAINT ck_national_discrepancy_resolved CHECK ((status = 'OPEN') = (resolution IS NULL AND resolved_by IS NULL)),
  CONSTRAINT ck_national_discrepancy_hash CHECK ((local_hash IS NULL OR octet_length(local_hash) = 32) AND (national_hash IS NULL OR octet_length(national_hash) = 32)),
  CONSTRAINT ck_national_discrepancy_enc CHECK ((local_enc IS NULL AND national_enc IS NULL) OR value_kid IS NOT NULL)
);
CREATE UNIQUE INDEX uq_national_discrepancy_open ON ph06_mdm.national_discrepancy (tenant_id, golden_id, attribute_name) WHERE status = 'OPEN';
CREATE INDEX ix_national_discrepancy_run ON ph06_mdm.national_discrepancy (tenant_id, run_id, severity);
CREATE TRIGGER tg_national_discrepancy_touch BEFORE UPDATE ON ph06_mdm.national_discrepancy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_national_discrepancy_immutable BEFORE UPDATE ON ph06_mdm.national_discrepancy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('run_id', 'golden_id', 'attribute_name');
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_discrepancy');
COMMENT ON TABLE ph06_mdm.national_discrepancy IS 'EN-06-30 FR-06-053, 054 Lệch giữa bản ghi vàng và CSDL quốc gia trên thuộc tính đồng bộ. Giá trị hai phía mã hóa envelope kèm HMAC. Một lệch OPEN mỗi (bản ghi vàng, thuộc tính). Thuộc tính thẩm quyền quốc gia không giữ giá trị địa phương khi lệch (BR-06-025).';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.national_discrepancy CASCADE;

-- @changeset ph06-0440-source-correction
CREATE TABLE ph06_mdm.source_correction (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  golden_id      uuid NOT NULL,
  attribute_name varchar(63) NOT NULL,
  source_code    varchar(32) NOT NULL,
  source_key     varchar(120),
  origin         varchar(24) NOT NULL,
  origin_ref     uuid,
  due_at         timestamptz NOT NULL,
  closed_at      timestamptz,
  closed_by      varchar(64),
  close_note     varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_correction PRIMARY KEY (id),
  CONSTRAINT ck_source_correction_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_correction_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT fk_source_correction_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_correction_origin CHECK (origin IN ('MANUAL_EDIT', 'NATIONAL_SYNC', 'DSR_CORRECTION')),
  CONSTRAINT ck_source_correction_closed CHECK ((closed_at IS NULL) = (closed_by IS NULL))
);
CREATE INDEX ix_source_correction_open ON ph06_mdm.source_correction (tenant_id, source_code, due_at) WHERE closed_at IS NULL;
CREATE TRIGGER tg_source_correction_touch BEFORE UPDATE ON ph06_mdm.source_correction FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_correction');
COMMENT ON TABLE ph06_mdm.source_correction IS 'EN-06-31 BR-06-014, EVT-06-15 Yêu cầu sửa tại nguồn: phát sinh khi sửa tay bản ghi vàng (FR-06-036), yêu cầu sửa của chủ thể (FR-06-058) hoặc lệch quốc gia (FR-06-054). Dữ liệu sai phải sửa ở nguồn; sửa tay ở bản ghi vàng chỉ tạm thời.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.source_correction CASCADE;


-- @file 06-0070-ops.sql
-- @changeset ph06-0450-subject-request
CREATE TABLE ph06_mdm.subject_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  request_type          varchar(16) NOT NULL,
  status                varchar(24) NOT NULL DEFAULT 'RECEIVED',
  identifier_type       varchar(16) NOT NULL,
  subject_enc           bytea NOT NULL,
  subject_kid           varchar(64) NOT NULL,
  subject_hash          bytea NOT NULL,
  verification_ref      varchar(255) NOT NULL,
  details_enc           bytea,
  channel               varchar(32) NOT NULL,
  received_at           timestamptz NOT NULL,
  due_at                timestamptz NOT NULL,
  golden_id             uuid,
  forwarded_source_code varchar(32),
  handled_by            varchar(64),
  completed_at          timestamptz,
  result_ref            varchar(512),
  reject_reason         varchar(2000),
  lifted_at             timestamptz,
  lifted_by             varchar(64),
  lift_reason           varchar(2000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_request PRIMARY KEY (id),
  CONSTRAINT ck_subject_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_subject_request_type CHECK (request_type IN ('ACCESS', 'RECTIFICATION', 'RESTRICTION')),
  CONSTRAINT ck_subject_request_status CHECK (status IN ('RECEIVED', 'IN_PROGRESS', 'FORWARDED_TO_SOURCE', 'COMPLETED', 'REJECTED')),
  CONSTRAINT ck_subject_request_idtype CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_subject_request_hash CHECK (octet_length(subject_hash) = 32),
  CONSTRAINT ck_subject_request_due CHECK (due_at >= received_at),
  CONSTRAINT ck_subject_request_completed CHECK (status NOT IN ('COMPLETED', 'REJECTED') OR completed_at IS NOT NULL),
  CONSTRAINT ck_subject_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_subject_request_lifted CHECK ((lifted_at IS NULL) = (lifted_by IS NULL) AND (lifted_at IS NULL) = (lift_reason IS NULL) AND (lifted_at IS NULL OR (request_type = 'RESTRICTION' AND status = 'COMPLETED' AND char_length(lift_reason) >= 20))),
  CONSTRAINT ck_subject_request_forward CHECK (status <> 'FORWARDED_TO_SOURCE' OR forwarded_source_code IS NOT NULL)
);
CREATE INDEX ix_subject_request_status ON ph06_mdm.subject_request (tenant_id, status, due_at);
CREATE INDEX ix_subject_request_subject ON ph06_mdm.subject_request (tenant_id, subject_hash);
CREATE TRIGGER tg_subject_request_touch BEFORE UPDATE ON ph06_mdm.subject_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_subject_request_immutable BEFORE UPDATE ON ph06_mdm.subject_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('request_type', 'subject_hash', 'received_at');
CALL ph06_mdm.p_enable_rls('ph06_mdm.subject_request');
COMMENT ON TABLE ph06_mdm.subject_request IS 'EN-06-20 Yêu cầu của chủ thể dữ liệu: biết, sửa, hạn chế (FR-06-058, BR-06-030; Luật BVDLCN, NĐ 356/2025). Số định danh chủ thể mã hóa envelope kèm HMAC để tra bản ghi vàng. Trả lời trong 06.dsr.sla-days (Q06-01); sửa thực hiện tại nguồn (BR-06-014). Yêu cầu hạn chế chuyển bản ghi vàng sang LOCKED.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.subject_request CASCADE;

-- @changeset ph06-0460-access-log
CREATE TABLE ph06_mdm.access_log (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  accessed_at        timestamptz NOT NULL DEFAULT now(),
  actor              varchar(64) NOT NULL,
  system_code        varchar(63),
  domain_code        varchar(32) NOT NULL,
  golden_id          uuid,
  api_code           varchar(10) NOT NULL,
  purpose_code       varchar(63),
  attributes         varchar(63)[] NOT NULL DEFAULT '{}',
  unmasked           varchar(63)[] NOT NULL DEFAULT '{}',
  unmask_reason      varchar(500),
  result_count       integer NOT NULL DEFAULT 1,
  criteria_hash      bytea,
  bulk_flag          boolean NOT NULL DEFAULT false,
  trace_id           char(32) NOT NULL,
  gateway_request_id varchar(64),
  CONSTRAINT pk_access_log PRIMARY KEY (id, accessed_at),
  CONSTRAINT ck_access_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_access_log_api CHECK (api_code ~ '^API-06-[0-9]{3}$'),
  CONSTRAINT ck_access_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_access_log_criteria CHECK (criteria_hash IS NULL OR octet_length(criteria_hash) = 32),
  CONSTRAINT ck_access_log_unmask CHECK (cardinality(unmasked) = 0 OR COALESCE(char_length(unmask_reason) >= 20, false)),
  CONSTRAINT ck_access_log_count CHECK (result_count >= 0)
) PARTITION BY RANGE (accessed_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.access_log', current_date, 3);
CREATE INDEX ix_access_log_golden ON ph06_mdm.access_log (tenant_id, golden_id, accessed_at DESC) WHERE golden_id IS NOT NULL;
CREATE INDEX ix_access_log_actor ON ph06_mdm.access_log (tenant_id, actor, accessed_at DESC);
CREATE INDEX ix_access_log_system ON ph06_mdm.access_log (tenant_id, system_code, purpose_code, accessed_at DESC) WHERE system_code IS NOT NULL;
CREATE TRIGGER tg_access_log_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.access_log FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.access_log');
COMMENT ON TABLE ph06_mdm.access_log IS 'EN-06-21 Nhật ký truy cập dữ liệu chủ: ai, tra bản ghi nào, mục đích gì, trả thuộc tính nào (FR-06-057, BR-06-010, NFR-06-015). Không ghi được thì không trả dữ liệu (ERR-06-039). Chỉ thêm, trigger chặn sửa, xóa (RB-06-04); không chứa giá trị thuộc tính. Phân vùng tháng; 12 tháng trực tuyến, 5 năm WORM (BR-06-031).';
COMMENT ON COLUMN ph06_mdm.access_log.gateway_request_id IS 'Mã yêu cầu của APISIX để đối chiếu số lượt (NFR-06-015).';
COMMENT ON COLUMN ph06_mdm.access_log.criteria_hash IS 'HMAC tiêu chí tìm kiếm; không lưu tiêu chí rõ.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.access_log CASCADE;

-- @changeset ph06-0470-processing-log
CREATE TABLE ph06_mdm.processing_log (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  logged_at    timestamptz NOT NULL DEFAULT now(),
  level        varchar(5) NOT NULL,
  component    varchar(32) NOT NULL,
  job_id       uuid,
  candidate_id uuid,
  domain_code  varchar(32),
  code         varchar(16),
  message      varchar(1000) NOT NULL,
  details      jsonb,
  trace_id     char(32),
  CONSTRAINT pk_processing_log PRIMARY KEY (id, logged_at),
  CONSTRAINT ck_processing_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_processing_log_level CHECK (level IN ('INFO', 'WARN', 'ERROR')),
  CONSTRAINT ck_processing_log_code CHECK (code IS NULL OR code ~ '^ERR-06-[01][0-9]{2}$'),
  CONSTRAINT ck_processing_log_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (logged_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.processing_log', current_date, 3);
CREATE INDEX ix_processing_log_job ON ph06_mdm.processing_log (tenant_id, job_id, logged_at) WHERE job_id IS NOT NULL;
CREATE INDEX ix_processing_log_level ON ph06_mdm.processing_log (tenant_id, level, logged_at DESC);
CREATE TRIGGER tg_processing_log_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.processing_log FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.processing_log');
COMMENT ON TABLE ph06_mdm.processing_log IS 'EN-06-32 FR-06-057 Nhật ký xử lý (job, ứng viên, đồng bộ, dọn lưu giữ) cho vận hành: mức, mã lỗi ERR-06-1nn, thông điệp ngắn, chi tiết đã che DLCN. Chỉ thêm; phân vùng tháng theo logged_at; giữ 90 ngày.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.processing_log CASCADE;

-- @changeset ph06-0480-retention-policy
CREATE TABLE ph06_mdm.retention_policy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  object_type    varchar(24) NOT NULL,
  retention_days integer NOT NULL,
  action         varchar(16) NOT NULL,
  legal_hold     boolean NOT NULL DEFAULT false,
  hold_reason    varchar(2000),
  last_purge_at  timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_policy PRIMARY KEY (id),
  CONSTRAINT ck_retention_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_retention_policy_type UNIQUE (tenant_id, object_type),
  CONSTRAINT ck_retention_policy_type CHECK (object_type IN ('candidate_record', 'match_result', 'match_staging', 'golden_history', 'attribute_lineage', 'access_log', 'processing_log', 'export_request', 'subject_request', 'steward_item')),
  CONSTRAINT ck_retention_policy_action CHECK (action IN ('DELETE', 'ANONYMIZE', 'ARCHIVE_COLD')),
  CONSTRAINT ck_retention_policy_days CHECK (retention_days >= 7 AND (object_type <> 'access_log' OR retention_days >= 365)),
  CONSTRAINT ck_retention_policy_hold CHECK (NOT legal_hold OR hold_reason IS NOT NULL)
);
CREATE TRIGGER tg_retention_policy_touch BEFORE UPDATE ON ph06_mdm.retention_policy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_retention_policy_immutable BEFORE UPDATE ON ph06_mdm.retention_policy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('object_type');
CALL ph06_mdm.p_enable_rls('ph06_mdm.retention_policy');
COMMENT ON TABLE ph06_mdm.retention_policy IS 'EN-06-33 FR-06-059 Chính sách lưu giữ theo loại đối tượng (BR-06-031). Nhật ký truy cập tối thiểu 365 ngày trực tuyến (ERR-06-049); legal_hold chặn dọn (ERR-06-114). retention_days = 0 không cho phép.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.retention_policy CASCADE;

-- @changeset ph06-0490-tenant-setting
CREATE TABLE ph06_mdm.tenant_setting (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  setting_key varchar(48) NOT NULL,
  value       jsonb NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('06.queue.sla-days', '06.queue.max-open', '06.queue.escalate-after-days', '06.queue.hold-minutes', '06.match.auto-disable-on-fail', '06.batch.safety-ratio', '06.undo.window-days', '06.export.max-rows', '06.access.bulk-threshold', '06.ingest.rate-per-source', '06.sync.pause-ratio', '06.sync.up-attributes', '06.dsr.sla-days', '06.mask.reveal-seconds', '06.ingest.max-file-mb', '06.ingest.max-rows', '06.batch.max-hours', '06.match.timeout-ms', '06.sync.reconcile-batch-size', '06.xref.batch-max', '06.queue.reopen-hours', '06.queue.reason-templates'))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph06_mdm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph06_mdm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('setting_key');
CALL ph06_mdm.p_enable_rls('ph06_mdm.tenant_setting');
COMMENT ON TABLE ph06_mdm.tenant_setting IS 'EN-06-34 FR-06-060 Tham số phân hệ theo tenant (FRS 8.2, khóa 06.*). Giá trị jsonb; miền kiểm ở dịch vụ (ERR-06-047), CHECK chỉ giữ danh sách khóa hợp lệ. Khóa thiếu thì dùng mặc định của FRS.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.tenant_setting CASCADE;


-- @file 06-0080-messaging.sql
-- @changeset ph06-0500-outbox-event
CREATE TABLE ph06_mdm.outbox_event (
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
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('mdm.golden.created.v1', 'mdm.golden.updated.v1', 'mdm.golden.merged.v1', 'mdm.golden.split.v1', 'mdm.golden.retired.v1', 'mdm.golden.restored.v1', 'mdm.candidate.ingested.v1', 'mdm.steward.item-created.v1', 'mdm.job.finished.v1', 'mdm.model.activated.v1', 'mdm.ruleset.activated.v1', 'mdm.national-sync.discrepancy-detected.v1', 'mdm.national-sync.paused.v1', 'mdm.xref.changed.v1', 'mdm.source-correction.requested.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'attributes', 'identifier', 'identifierValue', 'name', 'dateOfBirth']))
);
CREATE INDEX ix_outbox_event_occurred ON ph06_mdm.outbox_event (occurred_at);
CALL ph06_mdm.p_enable_rls('ph06_mdm.outbox_event');
COMMENT ON TABLE ph06_mdm.outbox_event IS 'Outbox (DD-11, SAD 7.3) cho EVT-06-01…15 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL, định tuyến theo topic. Sự kiện không chứa giá trị thuộc tính (BR-06-012): CHECK chặn khóa value, attributes, identifier. Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.outbox_event CASCADE;

-- @changeset ph06-0510-inbox-event
CREATE TABLE ph06_mdm.inbox_event (
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
CREATE INDEX ix_inbox_event_received ON ph06_mdm.inbox_event (received_at);
CALL ph06_mdm.p_enable_rls('ph06_mdm.inbox_event');
COMMENT ON TABLE ph06_mdm.inbox_event IS 'Inbox chống xử lý trùng cho sự kiện PH-06 tiêu thụ (at-least-once): trạng thái HTTT PH-01 (FR-06-008), thay đổi quốc gia từ PH-14 (FR-06-053), sự kiện nguồn PH-10 (FR-06-012). Khóa (consumer, event_id). Dọn sau 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.inbox_event CASCADE;

-- @changeset ph06-0520-shedlock
CREATE TABLE ph06_mdm.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph06_mdm.shedlock IS 'Khóa tác vụ nền (CandidateNormalizer, MatchJobScheduler, SteerQueueEscalator, SyncScheduler, RetentionPurgeJob, PartitionMaintenanceJob, OutboxCleaner, ExportExpiryJob); bảng kỹ thuật của ShedLock, không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph06_mdm.shedlock CASCADE;

-- @file 06-0900-grants.sql
-- @changeset ph06-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_app;
-- Bản ghi vàng và đối tượng nghiệp vụ không xóa cứng (BR-06-007): chỉ dọn bảng trung gian, nhật ký quá hạn theo retention_policy.
REVOKE DELETE ON ph06_mdm.mdm_domain, ph06_mdm.domain_model, ph06_mdm.model_attribute, ph06_mdm.identifier_rule, ph06_mdm.mdm_source,
  ph06_mdm.source_priority_proposal, ph06_mdm.source_priority, ph06_mdm.match_rule_set, ph06_mdm.match_rule, ph06_mdm.evaluation_report,
  ph06_mdm.golden_record, ph06_mdm.golden_attribute, ph06_mdm.golden_identifier, ph06_mdm.source_xref, ph06_mdm.golden_operation,
  ph06_mdm.survivorship_rule_set, ph06_mdm.survivorship_rule, ph06_mdm.steward_item, ph06_mdm.update_subscription, ph06_mdm.export_request,
  ph06_mdm.national_sync_state, ph06_mdm.national_sync_run, ph06_mdm.national_discrepancy, ph06_mdm.source_correction, ph06_mdm.subject_request,
  ph06_mdm.label_set, ph06_mdm.job_schedule, ph06_mdm.retention_policy, ph06_mdm.tenant_setting, ph06_mdm.match_job FROM ph06_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph06_owner.
REVOKE UPDATE, DELETE ON ph06_mdm.golden_history, ph06_mdm.attribute_lineage, ph06_mdm.access_log, ph06_mdm.processing_log FROM ph06_app;
REVOKE UPDATE ON ph06_mdm.outbox_event FROM ph06_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_readonly;
-- Báo cáo, Job Splink không đọc dữ liệu mã hóa và nhật ký truy cập: cột *_enc bị thu hồi ở bảng nhạy cảm.
REVOKE SELECT ON ph06_mdm.access_log, ph06_mdm.golden_history, ph06_mdm.subject_request, ph06_mdm.golden_identifier FROM ph06_readonly;
GRANT SELECT (id, tenant_id, accessed_at, actor, system_code, domain_code, golden_id, api_code, purpose_code, result_count, bulk_flag, trace_id)
  ON ph06_mdm.access_log TO ph06_readonly;
-- Vai Job Splink (FR-06-022): chỉ đọc match_staging, chỉ thêm match_result; không đọc bảng nào khác.
GRANT SELECT ON ph06_mdm.match_staging TO ph06_splink;
GRANT INSERT ON ph06_mdm.match_result TO ph06_splink;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_ensure_partitions(regclass, date, integer) TO ph06_app;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_seed_tenant(text) TO ph06_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
