-- =============================================================================
-- D03-03-PH11 · DDL schema ph11_bpm — PH-11 Quy trình liên thông (BPM)
-- Phiên bản 0.4 · 2026-11-26 · Dự thảo (đồng bộ FRS D02-03-PH11 Phụ lục A)
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph11_bpm.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Hai schema:
--   ph11_bpm       lớp nghiệp vụ LGSP (tệp này): mô hình, phiên bản, chạy thử, bản chiếu phiên và việc, can thiệp phiên,
--                  hạn, Saga, đề nghị bỏ qua bù trừ, giữ pháp lý, lần chạy mẫu tuân thủ, sự cố, outbox, inbox. RLS theo tenant_id.
--   ph11_flowable  bảng engine Flowable 7.x (ACT_RE_*, ACT_RU_*, ACT_HI_*, ACT_ID_*, FLW_*): do Flowable tự tạo
--                  và nâng cấp bằng tài khoản ph11_engine, KHÔNG viết DDL ở đây (ADR 110). Tệp này chỉ tạo schema
--                  rỗng, vai trò và quyền. Không RLS; cô lập tenant bằng tenantId của Flowable, chỉ truy cập qua
--                  dịch vụ PH-11. Cấu hình engine, history level audit, dọn lịch sử: D03-03-PH11 mục 6.1.
--
-- Nguồn chuẩn: D02-03-PH11 FRS. Giá trị enum theo Phụ lục A.1, tên cột theo Phụ lục A.2 (snake_case của tên trường API camelCase),
-- khóa tham số theo 8.2. Cột, bảng ngoài FRS được ghi "ngoài FRS Phụ lục A" trong COMMENT và đề nghị bổ sung ở D03-03-PH11 mục 9.2.
-- Bản chiếu phiên, việc là bản sao có RLS để truy vấn, báo cáo, tra tiến độ; nguồn sự thật về trạng thái thực thi
-- là engine. Biến quy trình nhạy cảm (NC) chỉ nằm ở engine dạng mã hóa, không vào bản chiếu (BR-11 về biến).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 11-0000-bootstrap.sql
-- @changeset ph11-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_owner') THEN
    CREATE ROLE ph11_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_app') THEN
    CREATE ROLE ph11_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_readonly') THEN
    CREATE ROLE ph11_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_engine') THEN
    CREATE ROLE ph11_engine NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph11-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph11_bpm AUTHORIZATION ph11_owner;
COMMENT ON SCHEMA ph11_bpm IS 'PH-11 Quy trình liên thông (dh-platform, package vn.datahub.platform.bpm): mô hình và phiên bản BPMN, chạy thử, biểu mẫu, ý định nghiệp vụ, bù trừ, bản chiếu phiên và việc, can thiệp phiên, ủy quyền, lịch làm việc, hạn, Saga, sự cố, outbox, inbox. Engine Flowable nằm ở schema ph11_flowable.';
GRANT USAGE ON SCHEMA ph11_bpm TO ph11_app, ph11_readonly;
-- Schema engine: Flowable tự tạo bảng ACT_*, FLW_* khi khởi động (databaseSchemaUpdate), nên chỉ tạo vỏ và cấp quyền cho ph11_engine.
CREATE SCHEMA IF NOT EXISTS ph11_flowable AUTHORIZATION ph11_engine;
COMMENT ON SCHEMA ph11_flowable IS 'Bảng engine Flowable 7.x (ACT_*, FLW_*), do Flowable tự tạo bằng tài khoản ph11_engine; không RLS, cô lập bằng tenantId của Flowable; chỉ dịch vụ PH-11 truy cập; history level audit; dọn lịch sử theo chính sách lưu giữ (ADR 110).';
-- @rollback DROP SCHEMA IF EXISTS ph11_bpm CASCADE;

SET ROLE ph11_owner;

-- @changeset ph11-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 11-0001-functions.sql
-- @changeset ph11-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_touch();

-- @changeset ph11-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph11_bpm.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, mốc thời gian đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_immutable();

-- @changeset ph11-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (task_comment).';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_append_only();

-- @changeset ph11-0013-fn-frozen splitStatements:false
-- Nội dung phiên bản bất biến khi không còn là bản nháp. Tham số đầu: danh sách trạng thái đóng băng, cách nhau dấu phẩy;
-- các tham số sau: cột nội dung. Chuyển trạng thái (ví dụ từ chối về DRAFT) không đổi nội dung nên được phép.
CREATE OR REPLACE FUNCTION ph11_bpm.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  i integer;
  c text;
BEGIN
  IF OLD.status = ANY (string_to_array(TG_ARGV[0], ',')) THEN
    FOR i IN 1 .. TG_NARGS - 1 LOOP
      c := TG_ARGV[i];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION '%: không sửa cột % khi trạng thái %', TG_TABLE_NAME, c, OLD.status USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_frozen() IS 'Phiên bản mô hình, biểu mẫu, bảng quyết định đã gửi duyệt, phát hành hoặc ngừng dùng không đổi nội dung; thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_frozen();

-- @changeset ph11-0014-fn-child-frozen splitStatements:false
-- Dòng con của phiên bản mô hình (biến, hành động bù trừ): chỉ thêm, sửa, xóa khi phiên bản cha còn DRAFT.
CREATE OR REPLACE FUNCTION ph11_bpm.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
  tn text;
  vid uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; vid := OLD.version_id;
  ELSE
    tn := NEW.tenant_id; vid := NEW.version_id;
  END IF;
  SELECT status INTO st FROM ph11_bpm.process_version WHERE tenant_id = tn AND id = vid;
  IF st IS NOT NULL AND st <> 'DRAFT' THEN
    RAISE EXCEPTION 'Phiên bản % đang %: không sửa nội dung con (%)', vid, st, TG_TABLE_NAME USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản mô hình cha không còn là DRAFT.';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_child_frozen();

-- @changeset ph11-0015-fn-rls splitStatements:false
-- Hai mẫu như PH-04, 05, 10: 'P' riêng tenant (dòng COMMON chỉ phiên PLATFORM đọc, ghi);
-- 'S' dùng chung (tenant đọc thêm dòng COMMON, chỉ phiên PLATFORM ghi COMMON).
CREATE OR REPLACE PROCEDURE ph11_bpm.p_enable_rls(p_table regclass, p_mode char)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
            OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))$w$;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  r := CASE p_mode WHEN 'S' THEN $r$(tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'))$r$ ELSE w END;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph11_bpm.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10 §4, ADR-003).';
-- @rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_enable_rls(regclass, char);

-- @changeset ph11-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph11_bpm.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
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
COMMENT ON PROCEDURE ph11_bpm.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho instance_step. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph11_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_ensure_partitions(regclass, date, integer);

-- @file 11-0010-model.sql
-- @changeset ph11-0100-process-model
CREATE TABLE ph11_bpm.process_model (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  process_key        varchar(64) NOT NULL,
  name               varchar(200) NOT NULL,
  description        varchar(2000),
  group_code         varchar(32) NOT NULL DEFAULT 'KHAC',
  owner_org_code     varchar(32),
  default_due_value  integer,
  default_due_unit   varchar(16),
  allowed_starters   varchar(100)[] NOT NULL DEFAULT '{}',
  allow_manual_start boolean NOT NULL DEFAULT false,
  template_code      varchar(64),
  archived           boolean NOT NULL DEFAULT false,
  archive_reason     varchar(2000),
  latest_version     integer NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_model PRIMARY KEY (id),
  CONSTRAINT uq_process_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_process_model_key UNIQUE (tenant_id, process_key),
  CONSTRAINT uq_process_model_tid_key UNIQUE (tenant_id, id, process_key),
  CONSTRAINT ck_process_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_process_model_key CHECK (process_key ~ '^[A-Z][A-Z0-9_]{2,63}$'),
  CONSTRAINT ck_process_model_name CHECK (char_length(name) >= 3),
  CONSTRAINT ck_process_model_due CHECK ((default_due_value IS NULL) = (default_due_unit IS NULL)
    AND (default_due_value IS NULL OR (default_due_value BETWEEN 1 AND 3650 AND default_due_unit IN ('WORKING_DAY', 'WORKING_HOUR', 'CALENDAR_DAY', 'CALENDAR_HOUR')))),
  CONSTRAINT ck_process_model_archive CHECK (NOT archived OR archive_reason IS NOT NULL),
  CONSTRAINT ck_process_model_latest CHECK (latest_version >= 0)
);
CREATE INDEX ix_process_model_name ON ph11_bpm.process_model USING gin (name gin_trgm_ops);
CREATE INDEX ix_process_model_group ON ph11_bpm.process_model (tenant_id, group_code, archived);
CREATE TRIGGER tg_process_model_touch BEFORE UPDATE ON ph11_bpm.process_model FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_model_immutable BEFORE UPDATE ON ph11_bpm.process_model FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('process_key', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_model', 'P');
COMMENT ON TABLE ph11_bpm.process_model IS 'EN-11-01 Mô hình quy trình (FR-11-001, 002, 009). Khóa nghiệp vụ process_key ổn định qua các phiên bản (ví dụ LT_KHAI_SINH, DUYET_KET_NAP_HTTT); không xóa, chỉ archived kèm lý do. Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.process_model.process_key IS 'Khóa quy trình, duy nhất trong tenant; cũng là khóa định nghĩa quy trình khi triển khai lên Flowable.';
COMMENT ON COLUMN ph11_bpm.process_model.group_code IS 'Nhóm nghiệp vụ tự do để lọc (API: group), ví dụ TTHC_LIEN_THONG, DUYET_NOI_BO.';
COMMENT ON COLUMN ph11_bpm.process_model.default_due_value IS 'Hạn mặc định của phiên, kiểu T-DUE: giá trị (API defaultDue.value); đi cùng default_due_unit, cùng rỗng hoặc cùng có.';
COMMENT ON COLUMN ph11_bpm.process_model.default_due_unit IS 'Đơn vị hạn mặc định (DueUnit): WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR (API defaultDue.unit).';
COMMENT ON COLUMN ph11_bpm.process_model.allowed_starters IS 'Mã client hoặc HTTT được khởi tạo phiên qua API (FR-11-018); rỗng là chỉ vai trò có quyền PERM-11-instance.';
COMMENT ON COLUMN ph11_bpm.process_model.allow_manual_start IS 'Cho khởi tạo thủ công trên giao diện (FR-11-020).';
COMMENT ON COLUMN ph11_bpm.process_model.template_code IS 'Mẫu dùng chung đã dùng để tạo (tham chiếu logic tới process_template, không khóa ngoại vì mẫu có thể ở tenant COMMON).';
COMMENT ON COLUMN ph11_bpm.process_model.latest_version IS 'Số phiên bản lớn nhất đã tạo (0 khi chưa có); dịch vụ tăng khi tạo phiên bản mới.';
COMMENT ON COLUMN ph11_bpm.process_model.archive_reason IS 'Bắt buộc khi archived.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.process_model CASCADE;

-- @changeset ph11-0110-process-version
CREATE TABLE ph11_bpm.process_version (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  model_id              uuid NOT NULL,
  process_key           varchar(64) NOT NULL,
  version_no            integer NOT NULL,
  status                varchar(16) NOT NULL DEFAULT 'DRAFT',
  bpmn_xml              text NOT NULL,
  checksum              bytea NOT NULL,
  based_on              integer,
  change_summary        varchar(2000),
  validation_summary    jsonb,
  lock_owner            varchar(64),
  lock_until            timestamptz,
  deployment_id         varchar(64),
  process_definition_id varchar(128),
  published_at          timestamptz,
  deprecated_at         timestamptz,
  retired_at            timestamptz,
  retire_reason         varchar(2000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_version PRIMARY KEY (id),
  CONSTRAINT uq_process_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_process_version_no UNIQUE (tenant_id, process_key, version_no),
  CONSTRAINT ck_process_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_process_version_model FOREIGN KEY (tenant_id, model_id, process_key) REFERENCES ph11_bpm.process_model (tenant_id, id, process_key),
  CONSTRAINT ck_process_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_process_version_based CHECK (based_on IS NULL OR (based_on >= 1 AND based_on < version_no)),
  CONSTRAINT ck_process_version_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'PUBLISHED', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_process_version_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_process_version_size CHECK (octet_length(bpmn_xml) BETWEEN 1 AND 8388608),
  CONSTRAINT ck_process_version_validation CHECK (validation_summary IS NULL OR (jsonb_typeof(validation_summary) = 'object' AND validation_summary ? 'blocking')),
  CONSTRAINT ck_process_version_review CHECK (status IN ('DRAFT', 'RETIRED') OR (validation_summary IS NOT NULL AND validation_summary ->> 'blocking' = 'false')),
  CONSTRAINT ck_process_version_lock CHECK ((lock_owner IS NULL) = (lock_until IS NULL) AND (lock_owner IS NULL OR status = 'DRAFT')),
  CONSTRAINT ck_process_version_published CHECK (status NOT IN ('PUBLISHED', 'DEPRECATED') OR (published_at IS NOT NULL AND deployment_id IS NOT NULL AND process_definition_id IS NOT NULL)),
  CONSTRAINT ck_process_version_retired CHECK (status <> 'RETIRED' OR (retired_at IS NOT NULL AND char_length(retire_reason) >= 10))
);
CREATE UNIQUE INDEX uq_process_version_published ON ph11_bpm.process_version (tenant_id, model_id) WHERE status = 'PUBLISHED';
CREATE UNIQUE INDEX uq_process_version_deployment ON ph11_bpm.process_version (tenant_id, deployment_id) WHERE deployment_id IS NOT NULL;
CREATE UNIQUE INDEX uq_process_version_definition ON ph11_bpm.process_version (tenant_id, process_definition_id) WHERE process_definition_id IS NOT NULL;
CREATE INDEX ix_process_version_status ON ph11_bpm.process_version (tenant_id, status, process_key);
CREATE TRIGGER tg_process_version_touch BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_version_immutable BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('model_id', 'process_key', 'version_no', 'tenant_id');
CREATE TRIGGER tg_process_version_frozen BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('IN_REVIEW,PUBLISHED,DEPRECATED,RETIRED', 'bpmn_xml', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_version', 'P');
COMMENT ON TABLE ph11_bpm.process_version IS 'EN-11-02 Phiên bản mô hình, chứa BPMN 2.0 XML và checksum (FR-11-003…010). Vòng đời DRAFT, IN_REVIEW, PUBLISHED, DEPRECATED, RETIRED; từ chối duyệt về DRAFT. Mỗi mô hình đúng một phiên bản PUBLISHED (phiên bản mới thay thì bản cũ thành DEPRECATED, phiên đang chạy vẫn chạy). Nội dung bất biến từ IN_REVIEW (BR-11-005). Chỉ PUBLISHED, DEPRECATED có deployment_id Flowable. Giữ vĩnh viễn (CV 631: truy vết phiên bản quy trình).';
COMMENT ON COLUMN ph11_bpm.process_version.model_id IS 'Mô hình cha; khóa ngoại kèm process_key để hai cột luôn khớp nhau.';
COMMENT ON COLUMN ph11_bpm.process_version.process_key IS 'Khử chuẩn từ process_model (ngoài FRS Phụ lục A), làm đích khóa ngoại của instance_index, migration_plan theo cặp (process_key, version_no).';
COMMENT ON COLUMN ph11_bpm.process_version.bpmn_xml IS 'Nội dung BPMN 2.0 XML, tối đa 8 MiB (trần của tham số 11.model.maxXmlKb); đã qua kiểm tra tĩnh phía máy chủ (FR-11-005, ADR 111).';
COMMENT ON COLUMN ph11_bpm.process_version.checksum IS 'SHA-256 của bpmn_xml (32 byte), dùng so sánh, xuất bằng chứng (BR-11-005, FR-11-064).';
COMMENT ON COLUMN ph11_bpm.process_version.based_on IS 'Số phiên bản làm gốc khi tạo nháp từ bản có sẵn.';
COMMENT ON COLUMN ph11_bpm.process_version.validation_summary IS 'Tóm tắt kiểm tra tĩnh gần nhất: blocking, errorCount, warningCount, checkedAt (API ValidationSummary); phải blocking = false trước khi gửi duyệt (FR-11-007).';
COMMENT ON COLUMN ph11_bpm.process_version.lock_owner IS 'Người đang giữ khóa soạn thảo (FR-11-003); chỉ bản DRAFT; hết hạn sau 11.designer.lockMinutes (lock_until).';
COMMENT ON COLUMN ph11_bpm.process_version.deployment_id IS 'Mã triển khai Flowable, ghi khi duyệt phát hành (FR-11-008).';
COMMENT ON COLUMN ph11_bpm.process_version.process_definition_id IS 'Mã định nghĩa quy trình Flowable (ACT_RE_PROCDEF.ID_) do lần triển khai tạo ra.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.process_version CASCADE;

-- @changeset ph11-0120-form-definition
CREATE TABLE ph11_bpm.form_definition (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  form_key             varchar(64) NOT NULL,
  version_no           integer NOT NULL DEFAULT 1,
  name                 varchar(200) NOT NULL,
  description          varchar(2000),
  status               varchar(16) NOT NULL DEFAULT 'DRAFT',
  schema               jsonb NOT NULL,
  ui_schema            jsonb NOT NULL DEFAULT '{}',
  decisions            varchar(24)[] NOT NULL DEFAULT '{COMPLETE}',
  field_classification jsonb NOT NULL DEFAULT '{}',
  checksum             bytea NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_form_definition PRIMARY KEY (id),
  CONSTRAINT uq_form_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_form_definition_no UNIQUE (tenant_id, form_key, version_no),
  CONSTRAINT ck_form_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_form_definition_key CHECK (form_key ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_form_definition_no CHECK (version_no >= 1),
  CONSTRAINT ck_form_definition_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_form_definition_schema CHECK (jsonb_typeof(schema) = 'object'),
  CONSTRAINT ck_form_definition_decisions CHECK (cardinality(decisions) >= 1 AND decisions <@ ARRAY['APPROVE', 'REJECT', 'RETURN', 'REQUEST_SUPPLEMENT', 'COMPLETE']::varchar[]),
  CONSTRAINT ck_form_definition_classification CHECK (jsonb_typeof(field_classification) = 'object'),
  CONSTRAINT ck_form_definition_checksum CHECK (octet_length(checksum) = 32)
);
CREATE UNIQUE INDEX uq_form_definition_published ON ph11_bpm.form_definition (tenant_id, form_key) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_form_definition_touch BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_form_definition_immutable BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('form_key', 'version_no', 'tenant_id');
CREATE TRIGGER tg_form_definition_frozen BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'schema', 'ui_schema', 'decisions', 'field_classification', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.form_definition', 'P');
COMMENT ON TABLE ph11_bpm.form_definition IS 'EN-11-03 Biểu mẫu việc người dùng bằng JSON Schema (FR-11-012). Có phiên bản; mỗi form_key đúng một phiên bản PUBLISHED; PUBLISHED không đổi nội dung (BR-11-005; việc đang mở vẫn hiển thị đúng bản đã gắn). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.form_definition.schema IS 'JSON Schema (draft 2020-12) mô tả trường nhập; việc kiểm dữ liệu theo schema này khi hoàn thành việc (FR-11-038).';
COMMENT ON COLUMN ph11_bpm.form_definition.ui_schema IS 'Gợi ý bố cục, nhãn, thứ tự trường cho giao diện.';
COMMENT ON COLUMN ph11_bpm.form_definition.decisions IS 'Các quyết định cho phép khi hoàn thành việc (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE.';
COMMENT ON COLUMN ph11_bpm.form_definition.field_classification IS 'Phân loại dữ liệu từng trường (DataClass); trường SENSITIVE mã hóa khi lưu kết quả (BR-11-014).';
COMMENT ON COLUMN ph11_bpm.form_definition.checksum IS 'SHA-256 của schema, ui_schema, decisions (32 byte), chống sai lệch nội dung.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.form_definition CASCADE;

-- @changeset ph11-0130-service-intent
CREATE TABLE ph11_bpm.service_intent (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  intent_code     varchar(64) NOT NULL,
  name            varchar(200) NOT NULL,
  description     varchar(2000),
  status          varchar(16) NOT NULL DEFAULT 'ACTIVE',
  input_schema    jsonb,
  output_schema   jsonb,
  writes_external boolean NOT NULL DEFAULT false,
  business_errors jsonb NOT NULL DEFAULT '[]',
  bindings        jsonb NOT NULL DEFAULT '[]',
  timeout_seconds integer,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_intent PRIMARY KEY (id),
  CONSTRAINT uq_service_intent_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_service_intent_code UNIQUE (tenant_id, intent_code),
  CONSTRAINT ck_service_intent_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_service_intent_code CHECK (intent_code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_service_intent_status CHECK (status IN ('ACTIVE', 'DEPRECATED')),
  CONSTRAINT ck_service_intent_errors CHECK (jsonb_typeof(business_errors) = 'array'),
  CONSTRAINT ck_service_intent_bindings CHECK (jsonb_typeof(bindings) = 'array'),
  CONSTRAINT ck_service_intent_timeout CHECK (timeout_seconds IS NULL OR timeout_seconds BETWEEN 1 AND 604800)
);
CREATE TRIGGER tg_service_intent_touch BEFORE UPDATE ON ph11_bpm.service_intent FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_service_intent_immutable BEFORE UPDATE ON ph11_bpm.service_intent FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('intent_code', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.service_intent', 'P');
COMMENT ON TABLE ph11_bpm.service_intent IS 'EN-11-04 Ý định nghiệp vụ ánh xạ sang luồng PH-04 (FR-11-013, 028). Service task trong BPMN chỉ khai ý định (ví dụ guiTuPhap, BR-11-002); PH-11 gửi lệnh {tenant}.bpm.service.requested.v1, PH-04 thực thi (ADR 112). Phát hành mô hình yêu cầu mọi ý định được dùng đều ACTIVE có ánh xạ luồng ở môi trường đích (BR-11-003). Không xóa. Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.service_intent.input_schema IS 'JSON Schema của dữ liệu vào (API inputSchema); kiểm khi dựng lệnh (FR-11-028).';
COMMENT ON COLUMN ph11_bpm.service_intent.output_schema IS 'JSON Schema của kết quả (API outputSchema); kiểm khi nhận kết quả (FR-11-029).';
COMMENT ON COLUMN ph11_bpm.service_intent.writes_external IS 'Ý định ghi dữ liệu ra HTTT ngoài: bước dùng nó phải có bù trừ hoặc miễn đã duyệt (BR-11-008).';
COMMENT ON COLUMN ph11_bpm.service_intent.business_errors IS 'Mảng mã lỗi nghiệp vụ mà bước có thể ném BpmnError (API businessErrors).';
COMMENT ON COLUMN ph11_bpm.service_intent.bindings IS 'Mảng ánh xạ môi trường sang luồng PH-04: {environment (TEST, STAGING, PROD), flowCode, flowVersion}; mã luồng là tham chiếu logic liên phân hệ, kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph11_bpm.service_intent.timeout_seconds IS 'Thời gian chờ kết quả riêng của ý định (API timeoutSeconds); rỗng thì dùng tham số 11.service.defaultTimeoutMinutes; quá hạn mở sự cố SERVICE_TIMEOUT (FR-11-029).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.service_intent CASCADE;

-- @changeset ph11-0140-compensation-action
CREATE TABLE ph11_bpm.compensation_action (
  id                       uuid NOT NULL,
  tenant_id                varchar(16) NOT NULL,
  version_id               uuid NOT NULL,
  element_id               varchar(100) NOT NULL,
  policy                   varchar(16) NOT NULL DEFAULT 'AUTO',
  compensation_intent_code varchar(64),
  input_mapping            jsonb NOT NULL DEFAULT '{}',
  business_note            varchar(2000) NOT NULL,
  verify_intent_code       varchar(64),
  waiver_approved_by       varchar(64),
  created_at               timestamptz NOT NULL DEFAULT now(),
  created_by               varchar(64) NOT NULL,
  updated_at               timestamptz NOT NULL DEFAULT now(),
  updated_by               varchar(64) NOT NULL,
  version                  integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compensation_action PRIMARY KEY (id),
  CONSTRAINT uq_compensation_action_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_compensation_action_step UNIQUE (tenant_id, version_id, element_id),
  CONSTRAINT ck_compensation_action_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_compensation_action_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT fk_compensation_action_intent FOREIGN KEY (tenant_id, compensation_intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT fk_compensation_action_verify FOREIGN KEY (tenant_id, verify_intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT ck_compensation_action_policy CHECK (policy IN ('AUTO', 'MANUAL', 'NONE_APPROVED')),
  CONSTRAINT ck_compensation_action_intent CHECK (policy <> 'AUTO' OR compensation_intent_code IS NOT NULL),
  CONSTRAINT ck_compensation_action_note CHECK (char_length(business_note) >= 20),
  CONSTRAINT ck_compensation_action_waiver CHECK (policy <> 'NONE_APPROVED' OR waiver_approved_by IS NOT NULL),
  CONSTRAINT ck_compensation_action_mapping CHECK (jsonb_typeof(input_mapping) = 'object')
);
CREATE TRIGGER tg_compensation_action_touch BEFORE UPDATE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_compensation_action_immutable BEFORE UPDATE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'element_id', 'tenant_id');
CREATE TRIGGER tg_compensation_action_child BEFORE INSERT OR UPDATE OR DELETE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_child_frozen();
CALL ph11_bpm.p_enable_rls('ph11_bpm.compensation_action', 'P');
COMMENT ON TABLE ph11_bpm.compensation_action IS 'EN-11-05 Hành động bù trừ theo bước của một phiên bản mô hình (FR-11-014, 051). Mỗi bước xuôi có tối đa một dòng; policy AUTO gọi ý định bù trừ, MANUAL chuyển việc xử lý thủ công, NONE_APPROVED là không bù trừ có miễn đã duyệt (BR-11-008, ví dụ không xóa khai sinh). Mọi dòng phải có ghi chú nghiệp vụ từ 20 ký tự (BR-11-009).';
COMMENT ON COLUMN ph11_bpm.compensation_action.element_id IS 'Id phần tử BPMN của bước xuôi cần bù trừ.';
COMMENT ON COLUMN ph11_bpm.compensation_action.compensation_intent_code IS 'Ý định bù trừ gửi PH-04; bắt buộc khi AUTO.';
COMMENT ON COLUMN ph11_bpm.compensation_action.input_mapping IS 'Ánh xạ dữ liệu vào cho lệnh bù trừ (API inputMapping).';
COMMENT ON COLUMN ph11_bpm.compensation_action.verify_intent_code IS 'Ý định kiểm tra hiệu lực bù trừ ở hệ thống đích, dùng khi đối soát (FR-11-054).';
COMMENT ON COLUMN ph11_bpm.compensation_action.waiver_approved_by IS 'Người có quyền duyệt miễn bù trừ; bắt buộc khi NONE_APPROVED (BR-11-008).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.compensation_action CASCADE;

-- @changeset ph11-0150-process-template
CREATE TABLE ph11_bpm.process_template (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL DEFAULT 'COMMON',
  template_code varchar(64) NOT NULL,
  version_no    integer NOT NULL DEFAULT 1,
  name          varchar(200) NOT NULL,
  description   varchar(2000),
  group_code    varchar(32) NOT NULL DEFAULT 'KHAC',
  status        varchar(16) NOT NULL DEFAULT 'DRAFT',
  source_xml    text NOT NULL,
  placeholders  jsonb NOT NULL DEFAULT '[]',
  checksum      bytea NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_template PRIMARY KEY (id),
  CONSTRAINT uq_process_template_no UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_process_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_process_template_code CHECK (template_code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_process_template_no CHECK (version_no >= 1),
  CONSTRAINT ck_process_template_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_process_template_placeholders CHECK (jsonb_typeof(placeholders) = 'array'),
  CONSTRAINT ck_process_template_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_process_template_size CHECK (octet_length(source_xml) BETWEEN 1 AND 8388608)
);
CREATE UNIQUE INDEX uq_process_template_published ON ph11_bpm.process_template (tenant_id, template_code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_process_template_touch BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_template_immutable BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('template_code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_process_template_frozen BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'source_xml', 'placeholders', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_template', 'S');
COMMENT ON TABLE ph11_bpm.process_template IS 'EN-11-06 Mẫu quy trình dùng chung (FR-11-015). Mẫu nền tảng ở tenant COMMON chỉ PA ghi (phiên PLATFORM, BR-11-027); mọi tenant đọc được (mẫu S) và tự tạo mẫu riêng. Tạo mô hình từ mẫu là sao chép source_xml, mô hình chỉ lưu template_code. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.process_template.placeholders IS 'Mảng tên chỗ giữ chỗ (ví dụ mã ý định, nhóm xử lý) người dùng phải điền khi tạo mô hình từ mẫu.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.process_template CASCADE;

-- @changeset ph11-0160-variable-definition
CREATE TABLE ph11_bpm.variable_definition (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  version_id        uuid NOT NULL,
  name              varchar(64) NOT NULL,
  type              varchar(12) NOT NULL DEFAULT 'STRING',
  required_at_start boolean NOT NULL DEFAULT false,
  data_class        varchar(16) NOT NULL DEFAULT 'INTERNAL',
  encrypt           boolean NOT NULL DEFAULT false,
  mask              boolean NOT NULL DEFAULT false,
  editable_by       varchar(16) NOT NULL DEFAULT 'NONE',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_variable_definition PRIMARY KEY (id),
  CONSTRAINT uq_variable_definition_name UNIQUE (tenant_id, version_id, name),
  CONSTRAINT ck_variable_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_variable_definition_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_variable_definition_name CHECK (name ~ '^[a-z][A-Za-z0-9]{1,63}$' AND name NOT IN ('businessKey', 'initiator', 'tenantId')),
  CONSTRAINT ck_variable_definition_type CHECK (type IN ('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'DATETIME', 'JSON', 'CODE_REF', 'FILE_REF')),
  CONSTRAINT ck_variable_definition_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_variable_definition_editable CHECK (editable_by IN ('NONE', 'TASK', 'ADMIN_CHANGE')),
  CONSTRAINT ck_variable_definition_sensitive CHECK (data_class <> 'SENSITIVE' OR (encrypt AND mask)),
  CONSTRAINT ck_variable_definition_restricted CHECK (data_class <> 'RESTRICTED' OR mask)
);
CREATE TRIGGER tg_variable_definition_touch BEFORE UPDATE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_variable_definition_immutable BEFORE UPDATE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'name', 'tenant_id');
CREATE TRIGGER tg_variable_definition_child BEFORE INSERT OR UPDATE OR DELETE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_child_frozen();
CALL ph11_bpm.p_enable_rls('ph11_bpm.variable_definition', 'P');
COMMENT ON TABLE ph11_bpm.variable_definition IS 'EN-11-07 Khai báo biến quy trình và phân loại dữ liệu (FR-11-016). RESTRICTED (hạn chế) phải che ở tiến độ và bản chiếu; SENSITIVE (nhạy cảm) phải mã hóa envelope trước khi vào engine và che, không bao giờ lộ ra tiến độ, sự kiện, nhật ký (BR-11-014, 015; CMP-LAW-04, 05).';
COMMENT ON COLUMN ph11_bpm.variable_definition.type IS 'Kiểu biến (VariableType): STRING, NUMBER, BOOLEAN, DATE, DATETIME, JSON, CODE_REF, FILE_REF.';
COMMENT ON COLUMN ph11_bpm.variable_definition.data_class IS 'Phân loại theo PH-09 (DataClass): PUBLIC, INTERNAL, RESTRICTED (HC), SENSITIVE (NC).';
COMMENT ON COLUMN ph11_bpm.variable_definition.encrypt IS 'Giá trị mã hóa envelope (OpenBao transit, ADR-032) và lưu ở engine dưới dạng tham chiếu bpm-secret; bắt buộc với SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.variable_definition.mask IS 'Che giá trị khi hiển thị cho người không có quyền xem rõ; bắt buộc với RESTRICTED, SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.variable_definition.editable_by IS 'Ai được sửa giá trị khi phiên chạy: NONE, TASK (qua việc), ADMIN_CHANGE (qua đề nghị instance_change, FR-11-025).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.variable_definition CASCADE;

-- @changeset ph11-0170-decision-table
CREATE TABLE ph11_bpm.decision_table (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  code        varchar(64) NOT NULL,
  version_no  integer NOT NULL DEFAULT 1,
  name        varchar(200) NOT NULL,
  status      varchar(16) NOT NULL DEFAULT 'DRAFT',
  hit_policy  varchar(8) NOT NULL DEFAULT 'UNIQUE',
  inputs      jsonb NOT NULL,
  outputs     jsonb NOT NULL,
  rules       jsonb NOT NULL DEFAULT '[]',
  checksum    bytea NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_decision_table PRIMARY KEY (id),
  CONSTRAINT uq_decision_table_no UNIQUE (tenant_id, code, version_no),
  CONSTRAINT ck_decision_table_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_decision_table_code CHECK (code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_decision_table_no CHECK (version_no >= 1),
  CONSTRAINT ck_decision_table_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_decision_table_hit CHECK (hit_policy IN ('UNIQUE', 'FIRST')),
  CONSTRAINT ck_decision_table_shape CHECK (jsonb_typeof(inputs) = 'array' AND jsonb_array_length(inputs) >= 1 AND jsonb_typeof(outputs) = 'array' AND jsonb_array_length(outputs) >= 1 AND jsonb_typeof(rules) = 'array'),
  CONSTRAINT ck_decision_table_checksum CHECK (octet_length(checksum) = 32)
);
CREATE UNIQUE INDEX uq_decision_table_published ON ph11_bpm.decision_table (tenant_id, code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_decision_table_touch BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_decision_table_immutable BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_decision_table_frozen BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'inputs', 'outputs', 'rules', 'hit_policy', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.decision_table', 'P');
COMMENT ON TABLE ph11_bpm.decision_table IS 'EN-11-24 Bảng quyết định DMN đơn giản cho rẽ nhánh (FR-11-017, mức C). Chính sách trúng UNIQUE hoặc FIRST; lưu dạng inputs, outputs, rules, dịch vụ sinh DMN XML khi triển khai cùng phiên bản mô hình. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn theo phiên bản.';
COMMENT ON COLUMN ph11_bpm.decision_table.inputs IS 'Mảng biến đầu vào của bảng (tên biến, kiểu).';
COMMENT ON COLUMN ph11_bpm.decision_table.outputs IS 'Mảng biến đầu ra của bảng.';
COMMENT ON COLUMN ph11_bpm.decision_table.rules IS 'Mảng dòng quy tắc: điều kiện FEEL đơn giản theo từng đầu vào và giá trị đầu ra.';
COMMENT ON COLUMN ph11_bpm.decision_table.checksum IS 'SHA-256 của inputs, outputs, rules, hit_policy (32 byte).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.decision_table CASCADE;

-- @changeset ph11-0180-publish-request
CREATE TABLE ph11_bpm.publish_request (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  version_id    uuid NOT NULL,
  kind          varchar(12) NOT NULL DEFAULT 'PUBLISH',
  release_note  varchar(2000) NOT NULL,
  checksum      bytea NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'PENDING',
  requested_by  varchar(64) NOT NULL,
  requested_at  timestamptz NOT NULL DEFAULT now(),
  decided_by    varchar(64),
  decided_at    timestamptz,
  comment       varchar(2000),
  task_id       uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_publish_request PRIMARY KEY (id),
  CONSTRAINT uq_publish_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_publish_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_publish_request_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_publish_request_kind CHECK (kind IN ('PUBLISH', 'RESTORE', 'TEMPLATE')),
  CONSTRAINT ck_publish_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'DEPLOY_FAILED')),
  CONSTRAINT ck_publish_request_note CHECK (char_length(release_note) >= 10),
  CONSTRAINT ck_publish_request_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_publish_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_publish_request_decided CHECK (status NOT IN ('APPROVED', 'REJECTED', 'DEPLOY_FAILED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND char_length(btrim(comment)) >= 1)),
  CONSTRAINT ck_publish_request_reject CHECK (status <> 'REJECTED' OR char_length(comment) >= 20)
);
CREATE UNIQUE INDEX uq_publish_request_pending ON ph11_bpm.publish_request (tenant_id, version_id, kind) WHERE status = 'PENDING';
CREATE INDEX ix_publish_request_status ON ph11_bpm.publish_request (tenant_id, status, requested_at DESC);
CREATE TRIGGER tg_publish_request_touch BEFORE UPDATE ON ph11_bpm.publish_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_publish_request_immutable BEFORE UPDATE ON ph11_bpm.publish_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'kind', 'release_note', 'checksum', 'requested_by', 'requested_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.publish_request', 'P');
COMMENT ON TABLE ph11_bpm.publish_request IS 'EN-11-20 Yêu cầu duyệt phát hành, khôi phục hoặc đưa mẫu lên dùng chung (FR-11-007, 008), bốn mắt: người duyệt khác người gửi (BR-11-004, PERM-11-publish). Ghi chú thay đổi từ 10 ký tự; duyệt cần ý kiến, từ chối cần lý do từ 20 ký tự (BR-11-033). DEPLOY_FAILED khi duyệt xong nhưng triển khai lên engine lỗi. Mỗi phiên bản, mỗi loại yêu cầu chỉ một yêu cầu PENDING.';
COMMENT ON COLUMN ph11_bpm.publish_request.kind IS 'Loại yêu cầu (API kind): PUBLISH phát hành bản mới, RESTORE khôi phục bản đã ngừng dùng, TEMPLATE đưa lên mẫu dùng chung.';
COMMENT ON COLUMN ph11_bpm.publish_request.checksum IS 'SHA-256 BPMN XML tại lúc gửi; người duyệt xem đúng bản đã kiểm, nội dung đổi thì không còn khớp.';
COMMENT ON COLUMN ph11_bpm.publish_request.comment IS 'Ý kiến của người duyệt (bắt buộc khi quyết định); lý do từ 20 ký tự khi từ chối.';
COMMENT ON COLUMN ph11_bpm.publish_request.task_id IS 'Việc duyệt trong hộp việc (task_index.id, task_kind PUBLISH_REVIEW), tham chiếu logic.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.publish_request CASCADE;

-- @changeset ph11-0190-test-run
CREATE TABLE ph11_bpm.test_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  version_id         uuid NOT NULL,
  scenario           jsonb NOT NULL DEFAULT '{}',
  status             varchar(8) NOT NULL DEFAULT 'RUNNING',
  engine_instance_id varchar(64),
  result             jsonb,
  ended_at           timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_test_run PRIMARY KEY (id),
  CONSTRAINT uq_test_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_test_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_test_run_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_test_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ABORTED')),
  CONSTRAINT ck_test_run_scenario CHECK (jsonb_typeof(scenario) = 'object'),
  CONSTRAINT ck_test_run_ended CHECK ((status = 'RUNNING') = (ended_at IS NULL)),
  CONSTRAINT ck_test_run_result CHECK (result IS NULL OR jsonb_typeof(result) = 'object')
);
CREATE INDEX ix_test_run_version ON ph11_bpm.test_run (tenant_id, version_id, created_at DESC);
CREATE INDEX ix_test_run_cleanup ON ph11_bpm.test_run (created_at);
CREATE TRIGGER tg_test_run_touch BEFORE UPDATE ON ph11_bpm.test_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_test_run_immutable BEFORE UPDATE ON ph11_bpm.test_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'scenario', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.test_run', 'P');
COMMENT ON TABLE ph11_bpm.test_run IS 'EN-11-26 Lần chạy thử một phiên bản nháp với service task giả lập (FR-11-011, API-11-025…027). Phiên chạy thử là dòng instance_index có start_channel TEST; không ghi outbox, không gửi lệnh PH-04, triển khai vào tenantId Flowable thử (BR-11-036). Kết quả (dòng thời gian, biến đã che, việc, Saga) ở result, đính kèm yêu cầu duyệt. Dọn sau 11.test.retentionDays ngày.';
COMMENT ON COLUMN ph11_bpm.test_run.scenario IS 'Kịch bản giả lập: kết quả cho từng service task (COMPLETE, BUSINESS_ERROR, TECHNICAL_ERROR, TIMEOUT), đồng hồ REAL hoặc ACCELERATED, tự hoàn thành việc.';
COMMENT ON COLUMN ph11_bpm.test_run.engine_instance_id IS 'Mã phiên chạy thử trong Flowable.';
COMMENT ON COLUMN ph11_bpm.test_run.result IS 'Kết quả chạy: timeline, variables (đã che), tasks, saga (API TestRun); không chứa giá trị SENSITIVE.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.test_run CASCADE;

-- @file 11-0020-instance.sql
-- @changeset ph11-0200-instance-index
CREATE TABLE ph11_bpm.instance_index (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  engine_instance_id    varchar(64) NOT NULL,
  process_key           varchar(64) NOT NULL,
  version_no            integer NOT NULL,
  business_key          varchar(100) NOT NULL,
  idempotency_key       varchar(120),
  status                varchar(16) NOT NULL DEFAULT 'RUNNING',
  wait_state            varchar(16) NOT NULL DEFAULT 'NONE',
  current_elements      jsonb NOT NULL DEFAULT '[]',
  start_channel         varchar(16) NOT NULL DEFAULT 'API',
  initiator             varchar(64) NOT NULL,
  client_id             varchar(64),
  parent_instance_id    uuid,
  due_at                timestamptz,
  trace_id              char(32) NOT NULL,
  started_at            timestamptz NOT NULL DEFAULT now(),
  ended_at              timestamptz,
  is_test               boolean NOT NULL DEFAULT false,
  suspended_at          timestamptz,
  status_reason         varchar(2000),
  progress_percent      smallint NOT NULL DEFAULT 0,
  progress_public       jsonb NOT NULL DEFAULT '{}',
  migrated_from_version integer,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_instance_index PRIMARY KEY (id),
  CONSTRAINT uq_instance_index_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_instance_index_engine UNIQUE (tenant_id, engine_instance_id),
  CONSTRAINT uq_instance_index_idempotency UNIQUE (tenant_id, idempotency_key),
  CONSTRAINT ck_instance_index_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_index_version FOREIGN KEY (tenant_id, process_key, version_no) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT fk_instance_index_parent FOREIGN KEY (tenant_id, parent_instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_index_status CHECK (status IN ('RUNNING', 'SUSPENDED', 'COMPENSATING', 'COMPLETED', 'CANCELLED', 'COMPENSATED', 'FAILED')),
  CONSTRAINT ck_instance_index_wait CHECK (wait_state IN ('NONE', 'WAITING_USER', 'WAITING_SERVICE', 'WAITING_MESSAGE', 'WAITING_TIMER')),
  CONSTRAINT ck_instance_index_channel CHECK (start_channel IN ('API', 'EVENT', 'MANUAL', 'CALL_ACTIVITY', 'TIMER', 'TEST')),
  CONSTRAINT ck_instance_index_test CHECK (is_test = (start_channel = 'TEST')),
  CONSTRAINT ck_instance_index_call CHECK ((start_channel = 'CALL_ACTIVITY') = (parent_instance_id IS NOT NULL)),
  CONSTRAINT ck_instance_index_ended CHECK ((status IN ('COMPLETED', 'CANCELLED', 'COMPENSATED', 'FAILED')) = (ended_at IS NOT NULL)),
  CONSTRAINT ck_instance_index_suspended CHECK (status <> 'SUSPENDED' OR suspended_at IS NOT NULL),
  CONSTRAINT ck_instance_index_reason CHECK (status NOT IN ('CANCELLED', 'FAILED') OR char_length(status_reason) >= 10),
  CONSTRAINT ck_instance_index_progress CHECK (progress_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_instance_index_elements CHECK (jsonb_typeof(current_elements) = 'array'),
  CONSTRAINT ck_instance_index_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_instance_index_migrated CHECK (migrated_from_version IS NULL OR migrated_from_version <> version_no)
);
CREATE UNIQUE INDEX uq_instance_index_live_key ON ph11_bpm.instance_index (tenant_id, process_key, business_key) WHERE status IN ('RUNNING', 'SUSPENDED', 'COMPENSATING') AND NOT is_test;
CREATE INDEX ix_instance_index_list ON ph11_bpm.instance_index (tenant_id, status, started_at DESC);
CREATE INDEX ix_instance_index_model ON ph11_bpm.instance_index (tenant_id, process_key, version_no, status);
CREATE INDEX ix_instance_index_bkey ON ph11_bpm.instance_index (tenant_id, business_key);
CREATE INDEX ix_instance_index_parent ON ph11_bpm.instance_index (tenant_id, parent_instance_id) WHERE parent_instance_id IS NOT NULL;
CREATE INDEX ix_instance_index_ended ON ph11_bpm.instance_index (ended_at) WHERE ended_at IS NOT NULL;
CREATE INDEX ix_instance_index_test ON ph11_bpm.instance_index (started_at) WHERE is_test;
CREATE TRIGGER tg_instance_index_touch BEFORE UPDATE ON ph11_bpm.instance_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_instance_index_immutable BEFORE UPDATE ON ph11_bpm.instance_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('engine_instance_id', 'process_key', 'business_key', 'start_channel', 'initiator', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_index', 'P');
COMMENT ON TABLE ph11_bpm.instance_index IS 'EN-11-08 Bản chiếu phiên quy trình để liệt kê, tìm kiếm, tra tiến độ có RLS (FR-11-018…027, 055). Nguồn sự thật là engine (engine_instance_id). Một business_key (mã hồ sơ) chỉ một phiên đang sống mỗi mô hình, trừ phiên chạy thử (BR-11-007); idempotency_key chỉ một phiên. Không lưu giá trị biến; progress_public chỉ chứa dữ liệu đã che (BR-11-015).';
COMMENT ON COLUMN ph11_bpm.instance_index.engine_instance_id IS 'Mã phiên trong Flowable (ACT_RU_EXECUTION.PROC_INST_ID_).';
COMMENT ON COLUMN ph11_bpm.instance_index.process_key IS 'Khóa mô hình, cùng version_no tạo khóa ngoại tới process_version.';
COMMENT ON COLUMN ph11_bpm.instance_index.business_key IS 'Mã hồ sơ do bên gọi cung cấp, 3…100 ký tự, không chứa dữ liệu cá nhân; API tiến độ tra theo khóa này (kênh DVC).';
COMMENT ON COLUMN ph11_bpm.instance_index.idempotency_key IS 'Idempotency-Key khi khởi tạo, hiệu lực 24 giờ (BR-11-007): dịch vụ đặt NULL sau 24 giờ; trong cửa sổ, gọi lại trả phiên cũ (FR-11-018).';
COMMENT ON COLUMN ph11_bpm.instance_index.wait_state IS 'Trạng thái chờ (WaitState): NONE, WAITING_USER, WAITING_SERVICE, WAITING_MESSAGE, WAITING_TIMER.';
COMMENT ON COLUMN ph11_bpm.instance_index.current_elements IS 'Mảng id các phần tử BPMN đang chờ (API currentElements); cập nhật theo sự kiện của engine.';
COMMENT ON COLUMN ph11_bpm.instance_index.start_channel IS 'Kênh khởi tạo (StartChannel): API, EVENT, MANUAL, CALL_ACTIVITY (có parent_instance_id), TIMER, TEST (phiên chạy thử, is_test).';
COMMENT ON COLUMN ph11_bpm.instance_index.initiator IS 'Người hoặc tài khoản máy khởi tạo (PH-12).';
COMMENT ON COLUMN ph11_bpm.instance_index.client_id IS 'client_id OAuth của HTTT gọi khởi tạo (PH-01, PH-12), rỗng khi khởi tạo thủ công; dùng cho hạn mức 11.instance.startRatePerClient.';
COMMENT ON COLUMN ph11_bpm.instance_index.due_at IS 'Hạn của phiên, chép từ due_tracking để lọc và sắp xếp danh sách (FR-11-021).';
COMMENT ON COLUMN ph11_bpm.instance_index.status_reason IS 'Lý do hủy, tạm dừng hoặc thất bại; bắt buộc từ 10 ký tự khi CANCELLED, FAILED.';
COMMENT ON COLUMN ph11_bpm.instance_index.progress_percent IS 'Ước lượng phần trăm tiến độ cho kênh DVC (API percentEstimate).';
COMMENT ON COLUMN ph11_bpm.instance_index.progress_public IS 'Tiến độ hiển thị cho kênh DVC (publicName, trạng thái công khai), đã che dữ liệu RESTRICTED, SENSITIVE (BR-11-015, FR-11-055).';
COMMENT ON COLUMN ph11_bpm.instance_index.migrated_from_version IS 'Số phiên bản mô hình trước khi di trú (FR-11-026); rỗng nếu chưa di trú.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.instance_index CASCADE;

-- @changeset ph11-0210-instance-step
CREATE TABLE ph11_bpm.instance_step (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  started_at   timestamptz NOT NULL DEFAULT now(),
  instance_id  uuid NOT NULL,
  element_id   varchar(100) NOT NULL,
  element_name varchar(255),
  step_type    varchar(24) NOT NULL,
  status       varchar(12) NOT NULL DEFAULT 'ACTIVE',
  ended_at     timestamptz,
  duration_ms  bigint,
  actor        varchar(64),
  result_code  varchar(32),
  summary      jsonb NOT NULL DEFAULT '{}',
  trace_id     char(32) NOT NULL,
  CONSTRAINT pk_instance_step PRIMARY KEY (id, started_at),
  CONSTRAINT ck_instance_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_step_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_step_type CHECK (step_type IN ('START_EVENT', 'END_EVENT', 'USER_TASK', 'SERVICE_TASK', 'SEND_TASK', 'BUSINESS_RULE_TASK', 'EXCLUSIVE_GATEWAY', 'PARALLEL_GATEWAY', 'INCLUSIVE_GATEWAY', 'EVENT_BASED_GATEWAY', 'TIMER_EVENT', 'MESSAGE_EVENT', 'COMPENSATION_THROW', 'TIMER_BOUNDARY', 'ERROR_BOUNDARY', 'COMPENSATION_BOUNDARY', 'MESSAGE_BOUNDARY', 'SUB_PROCESS', 'CALL_ACTIVITY')),
  CONSTRAINT ck_instance_step_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'FAILED', 'CANCELLED', 'COMPENSATED')),
  CONSTRAINT ck_instance_step_ended CHECK ((status = 'ACTIVE') = (ended_at IS NULL)),
  CONSTRAINT ck_instance_step_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CONSTRAINT ck_instance_step_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (started_at);
CALL ph11_bpm.p_ensure_partitions('ph11_bpm.instance_step', current_date, 3);
CREATE INDEX ix_instance_step_instance ON ph11_bpm.instance_step (tenant_id, instance_id, started_at);
CREATE INDEX ix_instance_step_element ON ph11_bpm.instance_step (tenant_id, element_id, started_at DESC);
CREATE TRIGGER tg_instance_step_immutable BEFORE UPDATE ON ph11_bpm.instance_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'element_id', 'step_type', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_step', 'P');
COMMENT ON TABLE ph11_bpm.instance_step IS 'EN-11-28 Lịch sử bước của phiên (FR-11-022, 056, 057, 059, 064), giữ 5 năm, phân vùng tháng. Mỗi lần vào một phần tử BPMN một dòng, cập nhật khi ra. Là bằng chứng kiểm toán, nguồn dòng thời gian và tiến độ. Không chứa giá trị biến (summary đã che).';
COMMENT ON COLUMN ph11_bpm.instance_step.element_id IS 'Id phần tử trong BPMN.';
COMMENT ON COLUMN ph11_bpm.instance_step.step_type IS 'Loại phần tử BPMN (StepType, bảng 6.2-a của FRS).';
COMMENT ON COLUMN ph11_bpm.instance_step.actor IS 'Người xử lý với bước việc, rỗng với bước hệ thống.';
COMMENT ON COLUMN ph11_bpm.instance_step.result_code IS 'Kết quả ngắn: quyết định của việc (Decision), mã lỗi của service task.';
COMMENT ON COLUMN ph11_bpm.instance_step.summary IS 'Tóm tắt đã che dữ liệu cá nhân (không chứa giá trị biến RESTRICTED, SENSITIVE).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.instance_step CASCADE;

-- @changeset ph11-0220-service-call
CREATE TABLE ph11_bpm.service_call (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  command_id    uuid NOT NULL,
  instance_id   uuid NOT NULL,
  element_id    varchar(100) NOT NULL,
  intent_code   varchar(64) NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'REQUESTED',
  attempt       smallint NOT NULL DEFAULT 1,
  requested_at  timestamptz NOT NULL DEFAULT now(),
  timeout_at    timestamptz NOT NULL,
  completed_at  timestamptz,
  output_ref    varchar(255),
  error_kind    varchar(12),
  error_code    varchar(64),
  error_message varchar(2000),
  trace_id      char(32) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_call PRIMARY KEY (id),
  CONSTRAINT uq_service_call_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_service_call_command UNIQUE (tenant_id, command_id),
  CONSTRAINT ck_service_call_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_service_call_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT fk_service_call_intent FOREIGN KEY (tenant_id, intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT ck_service_call_status CHECK (status IN ('REQUESTED', 'COMPLETED', 'FAILED', 'TIMED_OUT', 'CANCELLED')),
  CONSTRAINT ck_service_call_kind CHECK (error_kind IS NULL OR error_kind IN ('BUSINESS', 'TECHNICAL')),
  CONSTRAINT ck_service_call_attempt CHECK (attempt BETWEEN 1 AND 100),
  CONSTRAINT ck_service_call_done CHECK ((status = 'REQUESTED') = (completed_at IS NULL)),
  CONSTRAINT ck_service_call_error CHECK (status <> 'FAILED' OR (error_kind IS NOT NULL AND error_code IS NOT NULL)),
  CONSTRAINT ck_service_call_timeout CHECK (status <> 'TIMED_OUT' OR error_code IS NOT NULL),
  CONSTRAINT ck_service_call_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_service_call_instance ON ph11_bpm.service_call (tenant_id, instance_id, element_id, requested_at);
CREATE INDEX ix_service_call_timeout ON ph11_bpm.service_call (timeout_at) WHERE status = 'REQUESTED';
CREATE TRIGGER tg_service_call_touch BEFORE UPDATE ON ph11_bpm.service_call FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_service_call_immutable BEFORE UPDATE ON ph11_bpm.service_call FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'element_id', 'intent_code', 'command_id', 'requested_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.service_call', 'P');
COMMENT ON TABLE ph11_bpm.service_call IS 'EN-11-25 Lệnh service task đã gửi tới PH-04 và kết quả nhận về (FR-11-028, 029, 060). Mỗi lệnh một dòng theo command_id (UUID v5 xác định theo tenant, processInstanceId, executionId, activityId, lần giao lệnh; BR-11-022); gửi lại cùng command_id thì tăng attempt, PH-04 chống trùng theo command_id. Kết quả từ {tenant}.bpm.service.completed.v1 hoặc .failed.v1 (EVT-11-18, 19) tương quan theo command_id; quá timeout_at thì tác vụ nền chuyển TIMED_OUT và mở sự cố SERVICE_TIMEOUT (ADR 112).';
COMMENT ON COLUMN ph11_bpm.service_call.command_id IS 'Mã lệnh (UUID) mang trong sự kiện service.requested và kết quả trả về; khóa tương quan, bảo đảm xử lý kết quả một lần.';
COMMENT ON COLUMN ph11_bpm.service_call.status IS 'ServiceCallStatus: REQUESTED, COMPLETED, FAILED (lỗi nghiệp vụ hoặc kỹ thuật), TIMED_OUT, CANCELLED.';
COMMENT ON COLUMN ph11_bpm.service_call.attempt IS 'Số lần gửi cùng command_id; tăng khi vận hành bấm gửi lại (FR-11-028).';
COMMENT ON COLUMN ph11_bpm.service_call.timeout_at IS 'Hạn chờ kết quả = requested_at + thời gian chờ của ý định hoặc 11.service.defaultTimeoutMinutes.';
COMMENT ON COLUMN ph11_bpm.service_call.output_ref IS 'Tham chiếu tới kết quả đã ghi vào biến phiên (tên biến hoặc bpm-secret); không chứa giá trị. Kết quả đầy đủ chỉ nằm ở biến quy trình trong engine.';
COMMENT ON COLUMN ph11_bpm.service_call.error_kind IS 'ErrorKind: BUSINESS (đi nhánh lỗi, Saga) hoặc TECHNICAL (thử lại, mở sự cố); bắt buộc khi FAILED.';
COMMENT ON COLUMN ph11_bpm.service_call.error_message IS 'Thông điệp lỗi đã lược dữ liệu cá nhân.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.service_call CASCADE;

-- @changeset ph11-0230-instance-change
CREATE TABLE ph11_bpm.instance_change (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  instance_id  uuid NOT NULL,
  type         varchar(16) NOT NULL,
  payload      jsonb NOT NULL DEFAULT '{}',
  reason       varchar(2000) NOT NULL,
  status       varchar(8) NOT NULL DEFAULT 'PENDING',
  requested_by varchar(64) NOT NULL,
  approved_by  varchar(64),
  applied_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_instance_change PRIMARY KEY (id),
  CONSTRAINT uq_instance_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_instance_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_change_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_change_type CHECK (type IN ('VARIABLE_UPDATE', 'MOVE_TOKEN')),
  CONSTRAINT ck_instance_change_status CHECK (status IN ('PENDING', 'APPLIED', 'REJECTED')),
  CONSTRAINT ck_instance_change_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_instance_change_reason CHECK (char_length(reason) >= CASE type WHEN 'MOVE_TOKEN' THEN 30 ELSE 20 END),
  CONSTRAINT ck_instance_change_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_instance_change_decided CHECK ((status = 'PENDING') = (approved_by IS NULL)),
  CONSTRAINT ck_instance_change_applied CHECK ((status = 'APPLIED') = (applied_at IS NOT NULL))
);
CREATE INDEX ix_instance_change_instance ON ph11_bpm.instance_change (tenant_id, instance_id, created_at DESC);
CREATE INDEX ix_instance_change_pending ON ph11_bpm.instance_change (tenant_id, created_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_instance_change_touch BEFORE UPDATE ON ph11_bpm.instance_change FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_instance_change_immutable BEFORE UPDATE ON ph11_bpm.instance_change FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'type', 'payload', 'reason', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_change', 'P');
COMMENT ON TABLE ph11_bpm.instance_change IS 'EN-11-27 Đề nghị can thiệp phiên đang chạy: sửa biến (VARIABLE_UPDATE, FR-11-025) hoặc chuyển bước (MOVE_TOKEN, FR-11-027), API-11-059…062. Bốn mắt (BR-11-021): người duyệt khác người đề nghị; lý do từ 20 ký tự, chuyển bước từ 30. approved_by ghi người quyết định, kể cả khi REJECTED. Là bằng chứng kiểm toán: không xóa (quyền), giữ 5 năm sau khi phiên kết thúc.';
COMMENT ON COLUMN ph11_bpm.instance_change.type IS 'ChangeType: VARIABLE_UPDATE hoặc MOVE_TOKEN.';
COMMENT ON COLUMN ph11_bpm.instance_change.payload IS 'VARIABLE_UPDATE: danh sách {name, giá trị mới}, biến SENSITIVE chỉ ghi tham chiếu bpm-secret, không ghi giá trị rõ (BR-11-014); MOVE_TOKEN: fromElementIds, toElementId, skipCompensation.';
COMMENT ON COLUMN ph11_bpm.instance_change.status IS 'ChangeStatus: PENDING chờ duyệt, APPLIED đã áp dụng vào engine, REJECTED bị từ chối.';
COMMENT ON COLUMN ph11_bpm.instance_change.approved_by IS 'Người quyết định (duyệt hoặc từ chối), khác requested_by.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.instance_change CASCADE;

-- @file 11-0030-task.sql
-- @changeset ph11-0300-task-index
CREATE TABLE ph11_bpm.task_index (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  engine_task_id    varchar(64) NOT NULL,
  instance_id       uuid NOT NULL,
  element_id        varchar(100) NOT NULL,
  task_kind         varchar(24) NOT NULL DEFAULT 'STANDARD',
  name              varchar(255) NOT NULL,
  status            varchar(12) NOT NULL DEFAULT 'UNASSIGNED',
  assignee          varchar(64),
  candidates        varchar(100)[] NOT NULL DEFAULT '{}',
  delegated_from    varchar(64),
  form_key          varchar(64),
  form_version      integer,
  priority          smallint NOT NULL DEFAULT 50,
  due_at            timestamptz,
  claimed_at        timestamptz,
  closed_at         timestamptz,
  draft             jsonb,
  decision          varchar(24),
  decision_comment  varchar(4000),
  completed_by      varchar(64),
  ai_assisted       boolean NOT NULL DEFAULT false,
  result_data       jsonb,
  result_enc        bytea,
  result_kid        varchar(64),
  inbox_item_id     uuid,
  trace_id          char(32) NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_index PRIMARY KEY (id),
  CONSTRAINT uq_task_index_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_task_index_engine UNIQUE (tenant_id, engine_task_id),
  CONSTRAINT ck_task_index_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_index_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_index_kind CHECK (task_kind IN ('STANDARD', 'APPROVAL', 'PUBLISH_REVIEW', 'MANUAL_COMPENSATION', 'INCIDENT_HANDLING')),
  CONSTRAINT ck_task_index_status CHECK (status IN ('UNASSIGNED', 'ASSIGNED', 'DELEGATED', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_task_index_assignee CHECK ((status = 'UNASSIGNED') = (assignee IS NULL) OR status IN ('COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_task_index_candidates CHECK (status <> 'UNASSIGNED' OR cardinality(candidates) > 0),
  CONSTRAINT ck_task_index_delegated CHECK (status <> 'DELEGATED' OR (delegated_from IS NOT NULL AND delegated_from <> assignee)),
  CONSTRAINT ck_task_index_closed CHECK ((status IN ('COMPLETED', 'CANCELLED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_task_index_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT', 'RETURN', 'REQUEST_SUPPLEMENT', 'COMPLETE')),
  CONSTRAINT ck_task_index_completed CHECK (status <> 'COMPLETED' OR (decision IS NOT NULL AND completed_by IS NOT NULL)),
  CONSTRAINT ck_task_index_comment CHECK (decision IS NULL OR decision IN ('APPROVE', 'COMPLETE') OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_task_index_priority CHECK (priority BETWEEN 0 AND 100),
  CONSTRAINT ck_task_index_form CHECK ((form_key IS NULL) = (form_version IS NULL)),
  CONSTRAINT ck_task_index_enc CHECK (result_enc IS NULL OR (result_kid IS NOT NULL AND octet_length(result_enc) BETWEEN 29 AND 1048576)),
  CONSTRAINT ck_task_index_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_task_index_assignee ON ph11_bpm.task_index (tenant_id, assignee, status, due_at) WHERE status IN ('ASSIGNED', 'DELEGATED');
CREATE INDEX ix_task_index_candidates ON ph11_bpm.task_index USING gin (candidates) WHERE status = 'UNASSIGNED';
CREATE INDEX ix_task_index_instance ON ph11_bpm.task_index (tenant_id, instance_id);
CREATE INDEX ix_task_index_due ON ph11_bpm.task_index (tenant_id, due_at) WHERE closed_at IS NULL AND due_at IS NOT NULL;
CREATE TRIGGER tg_task_index_touch BEFORE UPDATE ON ph11_bpm.task_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_task_index_immutable BEFORE UPDATE ON ph11_bpm.task_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('engine_task_id', 'instance_id', 'element_id', 'task_kind', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_index', 'P');
COMMENT ON TABLE ph11_bpm.task_index IS 'EN-11-09 Bản chiếu việc người dùng cho hộp "Việc của tôi" (FR-11-034…044, FR-00-070). Nguồn sự thật là engine (engine_task_id). Việc giao qua ủy quyền giữ người gốc ở delegated_from. Từ chối, trả về, yêu cầu bổ sung bắt buộc ý kiến từ 20 ký tự (BR-11-033). Kết quả biểu mẫu: phần không nhạy cảm ở result_data, phần SENSITIVE chỉ ở result_enc (mã hóa envelope).';
COMMENT ON COLUMN ph11_bpm.task_index.task_kind IS 'TaskKind: STANDARD, APPROVAL, PUBLISH_REVIEW (duyệt phát hành, publish_request), MANUAL_COMPENSATION (xử lý bù trừ thủ công, saga_step), INCIDENT_HANDLING (xử lý sự cố).';
COMMENT ON COLUMN ph11_bpm.task_index.candidates IS 'Ứng viên nhận việc: mã người dùng, hoặc nhóm dạng group:{mã nhóm}; đơn vị được khai triển thành thành viên tại lúc tạo việc và chỉ chụp lại một lần (BR-11-037). Việc UNASSIGNED hiện cho các ứng viên; GIN phục vụ hộp việc.';
COMMENT ON COLUMN ph11_bpm.task_index.delegated_from IS 'Người được giao gốc khi việc DELEGATED (ủy quyền, FR-11-041); assignee là người đang xử lý.';
COMMENT ON COLUMN ph11_bpm.task_index.form_version IS 'Phiên bản biểu mẫu đã gắn lúc tạo việc, để hiển thị đúng bản dù biểu mẫu có phiên bản mới.';
COMMENT ON COLUMN ph11_bpm.task_index.draft IS 'Bản nháp kết quả (FR-11-039), chỉ trường không nhạy cảm; trường SENSITIVE không lưu nháp.';
COMMENT ON COLUMN ph11_bpm.task_index.decision IS 'Quyết định khi hoàn thành (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE.';
COMMENT ON COLUMN ph11_bpm.task_index.completed_by IS 'Người hoàn thành thực tế (người nhận hoặc người được ủy quyền, BR-11-016).';
COMMENT ON COLUMN ph11_bpm.task_index.ai_assisted IS 'Có dùng gợi ý AI của PH-17 khi xử lý (BR-11-029, FR-11-066).';
COMMENT ON COLUMN ph11_bpm.task_index.result_enc IS 'Phần SENSITIVE của kết quả, mã hóa envelope (OpenBao transit); result_kid ghi khóa.';
COMMENT ON COLUMN ph11_bpm.task_index.inbox_item_id IS 'Mã mục trong hộp việc chung (FR-00-070), tham chiếu logic.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.task_index CASCADE;

-- @changeset ph11-0310-task-comment
CREATE TABLE ph11_bpm.task_comment (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  task_id     uuid NOT NULL,
  instance_id uuid NOT NULL,
  author      varchar(64) NOT NULL,
  kind        varchar(8) NOT NULL DEFAULT 'COMMENT',
  text        varchar(4000) NOT NULL,
  mentions    varchar(64)[] NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  CONSTRAINT pk_task_comment PRIMARY KEY (id),
  CONSTRAINT ck_task_comment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_comment_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT fk_task_comment_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_comment_kind CHECK (kind IN ('COMMENT', 'OPINION', 'SYSTEM')),
  CONSTRAINT ck_task_comment_text CHECK (char_length(btrim(text)) >= 1)
);
CREATE INDEX ix_task_comment_task ON ph11_bpm.task_comment (tenant_id, task_id, created_at);
CREATE INDEX ix_task_comment_instance ON ph11_bpm.task_comment (tenant_id, instance_id, created_at);
CREATE TRIGGER tg_task_comment_append_only BEFORE UPDATE OR DELETE ON ph11_bpm.task_comment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_append_only();
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_comment', 'P');
COMMENT ON TABLE ph11_bpm.task_comment IS 'EN-11-10 Ý kiến, trao đổi trên việc (FR-11-043, 038). Chỉ thêm, không sửa, xóa (trigger, quyền): ý kiến là một phần của hồ sơ xử lý. kind OPINION là ý kiến chính thức khi hoàn thành việc, SYSTEM là ghi chú tự sinh (giao lại, trả về).';
COMMENT ON COLUMN ph11_bpm.task_comment.text IS 'Nội dung ý kiến, 1…4.000 ký tự (FR-11-043); không chứa giá trị biến SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.task_comment.mentions IS 'Mã người dùng được nhắc tên (API mentions).';
COMMENT ON COLUMN ph11_bpm.task_comment.instance_id IS 'Phiên của việc (khử chuẩn để xem toàn bộ trao đổi theo hồ sơ).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.task_comment CASCADE;

-- @changeset ph11-0320-task-attachment
CREATE TABLE ph11_bpm.task_attachment (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  task_id       uuid NOT NULL,
  instance_id   uuid NOT NULL,
  file_name     varchar(255) NOT NULL,
  content_type  varchar(127) NOT NULL,
  size          bigint NOT NULL,
  checksum      bytea NOT NULL,
  object_ref    varchar(512) NOT NULL,
  data_class    varchar(16) NOT NULL DEFAULT 'INTERNAL',
  scan_status   varchar(8) NOT NULL DEFAULT 'PENDING',
  removed_at    timestamptz,
  removed_by    varchar(64),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_attachment PRIMARY KEY (id),
  CONSTRAINT uq_task_attachment_ref UNIQUE (tenant_id, object_ref),
  CONSTRAINT ck_task_attachment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_attachment_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT fk_task_attachment_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_attachment_size CHECK (size BETWEEN 1 AND 52428800),
  CONSTRAINT ck_task_attachment_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_task_attachment_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_task_attachment_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_task_attachment_removed CHECK ((removed_at IS NULL) = (removed_by IS NULL))
);
CREATE INDEX ix_task_attachment_task ON ph11_bpm.task_attachment (tenant_id, task_id) WHERE removed_at IS NULL;
CREATE INDEX ix_task_attachment_instance ON ph11_bpm.task_attachment (tenant_id, instance_id);
CREATE TRIGGER tg_task_attachment_touch BEFORE UPDATE ON ph11_bpm.task_attachment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_task_attachment_immutable BEFORE UPDATE ON ph11_bpm.task_attachment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('task_id', 'file_name', 'size', 'checksum', 'object_ref', 'data_class', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_attachment', 'P');
COMMENT ON TABLE ph11_bpm.task_attachment IS 'EN-11-11 Tệp đính kèm việc (FR-11-043). Nội dung tệp ở Ceph RGW (object_ref, mã hóa phía máy chủ), bảng chỉ giữ siêu dữ liệu và SHA-256; tối đa 50 MiB mỗi tệp (trần của 11.task.attachmentMaxMb); chỉ tệp CLEAN sau quét mới tải được. Gỡ tệp là đánh dấu removed_at, không xóa dòng.';
COMMENT ON COLUMN ph11_bpm.task_attachment.size IS 'Kích thước tệp tính bằng byte (API size).';
COMMENT ON COLUMN ph11_bpm.task_attachment.checksum IS 'SHA-256 nội dung tệp (32 byte).';
COMMENT ON COLUMN ph11_bpm.task_attachment.object_ref IS 'Khóa đối tượng trên Ceph RGW: bpm/{tenant}/{instanceId}/{attachmentId}.';
COMMENT ON COLUMN ph11_bpm.task_attachment.data_class IS 'Phân loại dữ liệu do người tải khai (DataClass); tệp SENSITIVE chỉ người có quyền xem rõ mới tải được.';
COMMENT ON COLUMN ph11_bpm.task_attachment.scan_status IS 'Kết quả quét mã độc: PENDING, CLEAN, INFECTED (INFECTED bị chặn tải, báo người dùng).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.task_attachment CASCADE;

-- @changeset ph11-0330-delegation
CREATE TABLE ph11_bpm.delegation (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  from_user        varchar(64) NOT NULL,
  to_user          varchar(64) NOT NULL,
  valid_from       timestamptz NOT NULL,
  valid_to         timestamptz NOT NULL,
  scope            jsonb NOT NULL DEFAULT '{"all": true}',
  scope_key        varchar(512) GENERATED ALWAYS AS (CASE WHEN scope ? 'processKeys' THEN scope ->> 'processKeys' ELSE '*' END) STORED,
  include_existing boolean NOT NULL DEFAULT false,
  status           varchar(12) NOT NULL DEFAULT 'SCHEDULED',
  reason           varchar(2000),
  revoked_at       timestamptz,
  revoked_by       varchar(64),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_delegation PRIMARY KEY (id),
  CONSTRAINT ck_delegation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_delegation_status CHECK (status IN ('SCHEDULED', 'ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_delegation_distinct CHECK (from_user <> to_user),
  CONSTRAINT ck_delegation_period CHECK (valid_to > valid_from AND valid_to <= valid_from + interval '90 days'),
  CONSTRAINT ck_delegation_scope CHECK (jsonb_typeof(scope) = 'object' AND (scope ? 'all' OR scope ? 'processKeys')),
  CONSTRAINT ck_delegation_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_by IS NOT NULL)),
  CONSTRAINT ex_delegation_overlap EXCLUDE USING gist (tenant_id WITH =, from_user WITH =, scope_key WITH =, tstzrange(valid_from, valid_to) WITH &&) WHERE (status IN ('SCHEDULED', 'ACTIVE'))
);
CREATE INDEX ix_delegation_to_user ON ph11_bpm.delegation (tenant_id, to_user, valid_from, valid_to) WHERE status IN ('SCHEDULED', 'ACTIVE');
CREATE TRIGGER tg_delegation_touch BEFORE UPDATE ON ph11_bpm.delegation FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_delegation_immutable BEFORE UPDATE ON ph11_bpm.delegation FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('from_user', 'to_user', 'scope', 'valid_from', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.delegation', 'P');
COMMENT ON TABLE ph11_bpm.delegation IS 'EN-11-12 Ủy quyền xử lý việc khi vắng mặt (FR-11-041). Người ủy quyền giao toàn bộ việc (scope {"all": true}) hoặc việc của một số mô hình (scope {"processKeys": [...]}) cho người nhận trong khoảng thời gian tối đa 90 ngày (trần của 11.delegation.maxDays); hai ủy quyền SCHEDULED hoặc ACTIVE của cùng người, cùng phạm vi không chồng thời gian (EXCLUDE). Hết hạn do tác vụ nền; thu hồi sớm ghi revoked_*.';
COMMENT ON COLUMN ph11_bpm.delegation.from_user IS 'Mã người dùng ủy quyền (PH-12).';
COMMENT ON COLUMN ph11_bpm.delegation.to_user IS 'Mã người dùng nhận ủy quyền, cùng tenant (BR-11-020).';
COMMENT ON COLUMN ph11_bpm.delegation.scope IS 'Phạm vi (API scope): {"all": true} mọi mô hình, hoặc {"processKeys": [mã mô hình...]}.';
COMMENT ON COLUMN ph11_bpm.delegation.scope_key IS 'Cột sinh từ scope để so phạm vi trong ràng buộc loại trừ chồng thời gian: * hoặc chuỗi processKeys.';
COMMENT ON COLUMN ph11_bpm.delegation.include_existing IS 'Chuyển cả việc đang giữ sang người nhận khi ủy quyền có hiệu lực.';
COMMENT ON COLUMN ph11_bpm.delegation.valid_to IS 'Hết hiệu lực; không quá 90 ngày sau valid_from. Tham số 11.delegation.maxDays của tenant có thể chặt hơn, kiểm ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.delegation CASCADE;

-- @file 11-0040-sla.sql
-- @changeset ph11-0400-business-calendar
CREATE TABLE ph11_bpm.business_calendar (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  year           smallint NOT NULL,
  work_week      varchar(3)[] NOT NULL DEFAULT '{MON,TUE,WED,THU,FRI}',
  work_hours     jsonb NOT NULL DEFAULT '{"start": "07:30", "end": "17:00", "breakStart": "11:30", "breakEnd": "13:30"}',
  inherited_from varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_business_calendar PRIMARY KEY (id),
  CONSTRAINT uq_business_calendar_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_business_calendar_year UNIQUE (tenant_id, year),
  CONSTRAINT ck_business_calendar_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_business_calendar_year CHECK (year BETWEEN 2000 AND 2100),
  CONSTRAINT ck_business_calendar_week CHECK (cardinality(work_week) BETWEEN 1 AND 7 AND work_week <@ ARRAY['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']::varchar[]),
  CONSTRAINT ck_business_calendar_hours CHECK (jsonb_typeof(work_hours) = 'object' AND work_hours ?& ARRAY['start', 'end'] AND (work_hours ->> 'start') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' AND (work_hours ->> 'end') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' AND (work_hours ->> 'end') > (work_hours ->> 'start')),
  CONSTRAINT ck_business_calendar_break CHECK (((work_hours ? 'breakStart') = (work_hours ? 'breakEnd')) AND (NOT (work_hours ? 'breakStart') OR ((work_hours ->> 'breakEnd') > (work_hours ->> 'breakStart') AND (work_hours ->> 'breakStart') >= (work_hours ->> 'start') AND (work_hours ->> 'breakEnd') <= (work_hours ->> 'end')))),
  CONSTRAINT ck_business_calendar_inherited CHECK (inherited_from IS NULL OR (inherited_from = 'COMMON' AND tenant_id <> 'COMMON'))
);
CREATE TRIGGER tg_business_calendar_touch BEFORE UPDATE ON ph11_bpm.business_calendar FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_business_calendar_immutable BEFORE UPDATE ON ph11_bpm.business_calendar FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('year', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.business_calendar', 'S');
COMMENT ON TABLE ph11_bpm.business_calendar IS 'EN-11-13 Lịch làm việc của tenant theo năm (FR-11-045, ADR 114): thứ làm việc trong tuần, giờ làm việc, nghỉ trưa, múi giờ cố định Asia/Ho_Chi_Minh (BR-11-017). Mỗi tenant một dòng mỗi năm; PA khai lịch nền quốc gia ở tenant COMMON (mẫu S: tenant đọc được), tenant chưa khai năm nào thì dịch vụ dùng lịch COMMON hoặc lịch mặc định và ghi ERR-11-116. Không xóa (due_tracking tính theo lịch).';
COMMENT ON COLUMN ph11_bpm.business_calendar.year IS 'Năm dương lịch của lịch.';
COMMENT ON COLUMN ph11_bpm.business_calendar.work_week IS 'Các thứ làm việc trong tuần (API workDays): MON, TUE, WED, THU, FRI, SAT, SUN; mặc định thứ Hai đến thứ Sáu.';
COMMENT ON COLUMN ph11_bpm.business_calendar.work_hours IS 'Giờ làm việc (API workHours): start, end, breakStart, breakEnd dạng HH:MM; breakStart và breakEnd cùng có hoặc cùng không, nằm trong khoảng start đến end. Mặc định 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30.';
COMMENT ON COLUMN ph11_bpm.business_calendar.inherited_from IS 'COMMON khi lịch năm này sao chép từ lịch nền quốc gia ("Nhập từ lịch quốc gia"); rỗng khi tenant tự khai.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.business_calendar CASCADE;

-- @changeset ph11-0410-calendar-day
CREATE TABLE ph11_bpm.calendar_day (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  calendar_id uuid NOT NULL,
  date        date NOT NULL,
  type        varchar(16) NOT NULL,
  name        varchar(255) NOT NULL,
  legal_ref   varchar(255),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_calendar_day PRIMARY KEY (id),
  CONSTRAINT uq_calendar_day_date UNIQUE (tenant_id, calendar_id, date),
  CONSTRAINT ck_calendar_day_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_calendar_day_calendar FOREIGN KEY (tenant_id, calendar_id) REFERENCES ph11_bpm.business_calendar (tenant_id, id),
  CONSTRAINT ck_calendar_day_type CHECK (type IN ('HOLIDAY', 'MAKEUP_WORKDAY', 'SPECIAL_OFF'))
);
CREATE INDEX ix_calendar_day_date ON ph11_bpm.calendar_day (tenant_id, date);
CREATE TRIGGER tg_calendar_day_touch BEFORE UPDATE ON ph11_bpm.calendar_day FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_calendar_day_immutable BEFORE UPDATE ON ph11_bpm.calendar_day FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('calendar_id', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.calendar_day', 'S');
COMMENT ON TABLE ph11_bpm.calendar_day IS 'EN-11-14 Ngày nghỉ lễ (HOLIDAY), ngày làm bù (MAKEUP_WORKDAY, rơi vào ngày không làm việc trong tuần) và ngày nghỉ đột xuất (SPECIAL_OFF) của một lịch năm (FR-11-045, CalendarDayType). Mỗi ngày một dòng trong một lịch; ngày phải thuộc năm của lịch (dịch vụ kiểm, ERR-11-028). legal_ref ghi văn bản (ví dụ quyết định nghỉ Tết của Thủ tướng). Cùng mẫu S với business_calendar: ngày lễ nền quốc gia ở COMMON. Sửa, xóa ngày có kiểm toán.';
COMMENT ON COLUMN ph11_bpm.calendar_day.date IS 'Ngày dương lịch (API date).';
COMMENT ON COLUMN ph11_bpm.calendar_day.type IS 'CalendarDayType: HOLIDAY, MAKEUP_WORKDAY, SPECIAL_OFF.';
COMMENT ON COLUMN ph11_bpm.calendar_day.legal_ref IS 'Số, ngày văn bản quy định nghỉ hoặc làm bù.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.calendar_day CASCADE;

-- @changeset ph11-0420-due-tracking
CREATE TABLE ph11_bpm.due_tracking (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  subject              varchar(8) NOT NULL,
  subject_id           uuid NOT NULL,
  instance_id          uuid NOT NULL,
  task_id              uuid GENERATED ALWAYS AS (CASE WHEN subject = 'TASK' THEN subject_id END) STORED,
  due_value            integer NOT NULL,
  due_unit             varchar(16) NOT NULL,
  start_at             timestamptz NOT NULL,
  due_at               timestamptz NOT NULL,
  due_soon_at          timestamptz,
  status               varchar(8) NOT NULL DEFAULT 'ON_TIME',
  paused_at            timestamptz,
  pause_reason         varchar(24),
  paused_duration      interval NOT NULL DEFAULT '0',
  escalation_level     smallint NOT NULL DEFAULT 0,
  due_soon_notified_at timestamptz,
  overdue_notified_at  timestamptz,
  result               varchar(8),
  closed_at            timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_due_tracking PRIMARY KEY (id),
  CONSTRAINT ck_due_tracking_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_due_tracking_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT fk_due_tracking_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT ck_due_tracking_subject CHECK (subject IN ('INSTANCE', 'TASK') AND (subject <> 'INSTANCE' OR subject_id = instance_id)),
  CONSTRAINT ck_due_tracking_unit CHECK (due_unit IN ('WORKING_DAY', 'WORKING_HOUR', 'CALENDAR_DAY', 'CALENDAR_HOUR') AND due_value BETWEEN 1 AND 3650),
  CONSTRAINT ck_due_tracking_status CHECK (status IN ('ON_TIME', 'DUE_SOON', 'OVERDUE', 'PAUSED')),
  CONSTRAINT ck_due_tracking_pause CHECK ((status = 'PAUSED') = (paused_at IS NOT NULL) AND (paused_at IS NULL OR pause_reason IS NOT NULL)),
  CONSTRAINT ck_due_tracking_reason CHECK (pause_reason IS NULL OR pause_reason IN ('WAITING_SUPPLEMENT', 'LEGAL_SUSPENSION')),
  CONSTRAINT ck_due_tracking_due CHECK (due_at > start_at AND (due_soon_at IS NULL OR (due_soon_at >= start_at AND due_soon_at <= due_at))),
  CONSTRAINT ck_due_tracking_paused_duration CHECK (paused_duration >= interval '0'),
  CONSTRAINT ck_due_tracking_level CHECK (escalation_level BETWEEN 0 AND 3),
  CONSTRAINT ck_due_tracking_result CHECK (result IS NULL OR result IN ('MET', 'MISSED')),
  CONSTRAINT ck_due_tracking_closed CHECK ((closed_at IS NULL) = (result IS NULL))
);
CREATE UNIQUE INDEX uq_due_tracking_subject ON ph11_bpm.due_tracking (tenant_id, subject, subject_id);
CREATE INDEX ix_due_tracking_instance ON ph11_bpm.due_tracking (tenant_id, instance_id);
CREATE INDEX ix_due_tracking_scan ON ph11_bpm.due_tracking (due_at) WHERE closed_at IS NULL AND status <> 'PAUSED';
CREATE INDEX ix_due_tracking_report ON ph11_bpm.due_tracking (tenant_id, subject, closed_at) WHERE closed_at IS NOT NULL;
CREATE TRIGGER tg_due_tracking_touch BEFORE UPDATE ON ph11_bpm.due_tracking FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_due_tracking_immutable BEFORE UPDATE ON ph11_bpm.due_tracking FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('subject', 'subject_id', 'instance_id', 'start_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.due_tracking', 'P');
COMMENT ON TABLE ph11_bpm.due_tracking IS 'EN-11-15 Theo dõi hạn xử lý của phiên và của việc (FR-11-046…050, ADR 114). Hạn due_at tính theo lịch làm việc của tenant (BR-11-017); PAUSED khi chờ bổ sung hoặc tạm dừng pháp lý, cộng dồn paused_duration và dời due_at khi tiếp tục (BR-11-018). Tác vụ nền quét theo due_at, ghi mốc nhắc và mức leo thang một lần (BR-11-019). Khi đóng ghi closed_at và result (MET, MISSED) để báo cáo đúng hạn, trễ hạn.';
COMMENT ON COLUMN ph11_bpm.due_tracking.subject IS 'DueSubject: INSTANCE hạn cả phiên (subject_id là mã phiên), TASK hạn một việc (subject_id là mã việc).';
COMMENT ON COLUMN ph11_bpm.due_tracking.subject_id IS 'Mã phiên (instance_index.id) hoặc mã việc (task_index.id) theo subject.';
COMMENT ON COLUMN ph11_bpm.due_tracking.instance_id IS 'Phiên chứa đối tượng bị theo dõi (với INSTANCE bằng subject_id), giữ khóa ngoại và lọc theo phiên.';
COMMENT ON COLUMN ph11_bpm.due_tracking.task_id IS 'Cột sinh: bằng subject_id khi subject = TASK, để có khóa ngoại tới task_index.';
COMMENT ON COLUMN ph11_bpm.due_tracking.due_value IS 'Số lượng của hạn (T-DUE, 1…3.650), lưu để tính lại hạn khi lịch đổi (FR-11-045).';
COMMENT ON COLUMN ph11_bpm.due_tracking.due_unit IS 'DueUnit: WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR.';
COMMENT ON COLUMN ph11_bpm.due_tracking.pause_reason IS 'PauseReason: WAITING_SUPPLEMENT (chờ bổ sung hồ sơ), LEGAL_SUSPENSION (tạm dừng theo quy định).';
COMMENT ON COLUMN ph11_bpm.due_tracking.paused_duration IS 'Tổng thời gian đã tạm dừng tính hạn, quy theo giờ làm việc (API pausedDuration).';
COMMENT ON COLUMN ph11_bpm.due_tracking.escalation_level IS 'Mức leo thang đã gửi: 0 chưa, 1 người quản lý trực tiếp, 2 lãnh đạo đơn vị, 3 quản trị tenant (EscalationAction ghi ở chính sách bước).';
COMMENT ON COLUMN ph11_bpm.due_tracking.result IS 'DueResult khi đóng: MET hoàn thành trong hạn, MISSED sau hạn; rỗng khi còn mở.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.due_tracking CASCADE;

-- @file 11-0050-saga.sql
-- @changeset ph11-0500-saga-log
CREATE TABLE ph11_bpm.saga_log (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  instance_id      uuid NOT NULL,
  trigger          varchar(16) NOT NULL DEFAULT 'STEP_FAILURE',
  failed_element   varchar(100),
  error_code       varchar(32),
  status           varchar(10) NOT NULL DEFAULT 'RUNNING',
  total_steps      smallint NOT NULL DEFAULT 0,
  done_steps       smallint NOT NULL DEFAULT 0,
  failed_steps     smallint NOT NULL DEFAULT 0,
  started_at       timestamptz NOT NULL DEFAULT now(),
  ended_at         timestamptz,
  reconcile_state  varchar(8) NOT NULL DEFAULT 'NONE',
  reconciled_at    timestamptz,
  reconcile_note   varchar(2000),
  trace_id         char(32) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_log PRIMARY KEY (id),
  CONSTRAINT uq_saga_log_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_saga_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_log_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_saga_log_trigger CHECK (trigger IN ('STEP_FAILURE', 'INSTANCE_CANCEL', 'MANUAL')),
  CONSTRAINT ck_saga_log_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED')),
  CONSTRAINT ck_saga_log_ended CHECK ((status = 'RUNNING') = (ended_at IS NULL)),
  CONSTRAINT ck_saga_log_counts CHECK (total_steps >= 0 AND done_steps >= 0 AND failed_steps >= 0 AND done_steps + failed_steps <= total_steps),
  CONSTRAINT ck_saga_log_reconcile CHECK (reconcile_state IN ('NONE', 'PENDING', 'MATCHED', 'MISMATCH')),
  CONSTRAINT ck_saga_log_reconciled CHECK ((reconcile_state IN ('MATCHED', 'MISMATCH')) = (reconciled_at IS NOT NULL)),
  CONSTRAINT ck_saga_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE UNIQUE INDEX uq_saga_log_running ON ph11_bpm.saga_log (tenant_id, instance_id) WHERE status = 'RUNNING';
CREATE INDEX ix_saga_log_instance ON ph11_bpm.saga_log (tenant_id, instance_id, started_at DESC);
CREATE INDEX ix_saga_log_status ON ph11_bpm.saga_log (tenant_id, status, started_at DESC);
CREATE INDEX ix_saga_log_reconcile ON ph11_bpm.saga_log (tenant_id, reconcile_state) WHERE reconcile_state IN ('PENDING', 'MISMATCH');
CREATE TRIGGER tg_saga_log_touch BEFORE UPDATE ON ph11_bpm.saga_log FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_log_immutable BEFORE UPDATE ON ph11_bpm.saga_log FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'trigger', 'failed_element', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_log', 'P');
COMMENT ON TABLE ph11_bpm.saga_log IS 'EN-11-16 Nhật ký Saga bù trừ của một phiên (FR-11-051…054, ADR 113). Mỗi lần kích hoạt bù trừ (lỗi bước, hủy phiên, thủ công) một dòng; mỗi phiên tối đa một Saga RUNNING. PARTIAL là còn bước xử lý thủ công. Là bằng chứng đối soát khi cơ quan đã ghi nhận giao dịch: không xóa (quyền), giữ tối thiểu 5 năm (BR-11-025). Đối soát định kỳ đặt reconcile_state.';
COMMENT ON COLUMN ph11_bpm.saga_log.trigger IS 'CompensationTrigger: STEP_FAILURE bước lỗi không thử lại được; INSTANCE_CANCEL hủy phiên kèm bù trừ (FR-11-024); MANUAL do TA, TO kích hoạt (PERM-11-compensate).';
COMMENT ON COLUMN ph11_bpm.saga_log.failed_element IS 'Id phần tử BPMN gây lỗi (API failedElementId); rỗng với INSTANCE_CANCEL, MANUAL.';
COMMENT ON COLUMN ph11_bpm.saga_log.error_code IS 'Mã lỗi của bước gây Saga (ERR-11-xxx hoặc mã lỗi nghiệp vụ của ý định).';
COMMENT ON COLUMN ph11_bpm.saga_log.reconcile_state IS 'Đối soát với hệ thống đích (FR-11-054): NONE chưa cần, PENDING chờ, MATCHED khớp, MISMATCH lệch cần xử lý.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.saga_log CASCADE;

-- @changeset ph11-0510-saga-step
CREATE TABLE ph11_bpm.saga_step (
  id                       uuid NOT NULL,
  tenant_id                varchar(16) NOT NULL,
  saga_id                  uuid NOT NULL,
  seq                      smallint NOT NULL,
  forward_element_id       varchar(100) NOT NULL,
  compensation_intent_code varchar(64),
  policy                   varchar(16) NOT NULL,
  command_id               uuid,
  attempt                  smallint NOT NULL DEFAULT 0,
  status                   varchar(8) NOT NULL DEFAULT 'PENDING',
  response_code            varchar(32),
  evidence                 varchar(2000),
  resolved_by              varchar(64),
  last_error               varchar(2000),
  started_at               timestamptz,
  ended_at                 timestamptz,
  created_at               timestamptz NOT NULL DEFAULT now(),
  created_by               varchar(64) NOT NULL,
  updated_at               timestamptz NOT NULL DEFAULT now(),
  updated_by               varchar(64) NOT NULL,
  version                  integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_step PRIMARY KEY (id),
  CONSTRAINT uq_saga_step_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_saga_step_seq UNIQUE (tenant_id, saga_id, seq),
  CONSTRAINT ck_saga_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_step_saga FOREIGN KEY (tenant_id, saga_id) REFERENCES ph11_bpm.saga_log (tenant_id, id),
  CONSTRAINT ck_saga_step_policy CHECK (policy IN ('AUTO', 'MANUAL', 'NONE_APPROVED')),
  CONSTRAINT ck_saga_step_status CHECK (status IN ('PENDING', 'RUNNING', 'DONE', 'FAILED', 'MANUAL', 'SKIPPED')),
  CONSTRAINT ck_saga_step_seq CHECK (seq >= 1),
  CONSTRAINT ck_saga_step_attempt CHECK (attempt BETWEEN 0 AND 20),
  CONSTRAINT ck_saga_step_ended CHECK ((status IN ('DONE', 'FAILED', 'SKIPPED')) = (ended_at IS NOT NULL)),
  CONSTRAINT ck_saga_step_failed CHECK (status <> 'FAILED' OR last_error IS NOT NULL),
  CONSTRAINT ck_saga_step_manual CHECK (resolved_by IS NULL OR char_length(evidence) >= 20),
  CONSTRAINT ck_saga_step_skipped CHECK (status <> 'SKIPPED' OR policy = 'NONE_APPROVED' OR resolved_by IS NOT NULL),
  CONSTRAINT ck_saga_step_auto CHECK (policy <> 'AUTO' OR compensation_intent_code IS NOT NULL)
);
CREATE INDEX ix_saga_step_saga ON ph11_bpm.saga_step (tenant_id, saga_id, seq);
CREATE INDEX ix_saga_step_open ON ph11_bpm.saga_step (tenant_id, status) WHERE status IN ('RUNNING', 'FAILED', 'MANUAL');
CREATE UNIQUE INDEX uq_saga_step_command ON ph11_bpm.saga_step (tenant_id, command_id) WHERE command_id IS NOT NULL;
CREATE TRIGGER tg_saga_step_touch BEFORE UPDATE ON ph11_bpm.saga_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_step_immutable BEFORE UPDATE ON ph11_bpm.saga_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('saga_id', 'seq', 'forward_element_id', 'policy', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_step', 'P');
COMMENT ON TABLE ph11_bpm.saga_step IS 'EN-11-17 Bước bù trừ của một Saga, chạy ngược thứ tự hoàn thành (FR-11-051…053, BR-11-011). DONE chỉ sau khi ghi nhật ký (BR-11-013); MANUAL chờ xử lý tay và tạo việc MANUAL_COMPENSATION. Bước thủ công hoàn tất hoặc bỏ qua cần người xử lý và bằng chứng từ 20 ký tự, trừ policy NONE_APPROVED (đã được duyệt khi phát hành). Là bằng chứng đối soát: không xóa (quyền), giữ tối thiểu 5 năm.';
COMMENT ON COLUMN ph11_bpm.saga_step.seq IS 'Thứ tự thực hiện bù trừ, 1 là bước đầu tiên được bù trừ (bước xuôi hoàn thành gần nhất).';
COMMENT ON COLUMN ph11_bpm.saga_step.policy IS 'CompensationPolicy chụp từ compensation_action lúc kích hoạt Saga, để nhật ký không đổi dù cấu hình sau này đổi.';
COMMENT ON COLUMN ph11_bpm.saga_step.command_id IS 'Mã lệnh bù trừ gửi PH-04 (service.requested); kết quả tương quan theo mã này.';
COMMENT ON COLUMN ph11_bpm.saga_step.attempt IS 'Số lượt thử bù trừ đã chạy (tối đa 11.saga.maxRetries cộng lượt đầu).';
COMMENT ON COLUMN ph11_bpm.saga_step.response_code IS 'Mã phản hồi của hệ thống đích cho lệnh bù trừ.';
COMMENT ON COLUMN ph11_bpm.saga_step.evidence IS 'Bằng chứng bù trừ: mô tả, số văn bản, tham chiếu tệp; với xử lý tay hoặc bỏ qua là lý do và bằng chứng từ 20 ký tự (API-11-… ManualResolveBody, SkipBody).';
COMMENT ON COLUMN ph11_bpm.saga_step.resolved_by IS 'Người xử lý tay hoặc bỏ qua bước.';
COMMENT ON COLUMN ph11_bpm.saga_step.last_error IS 'Lỗi gần nhất của lượt thử (đã lược dữ liệu cá nhân); bắt buộc khi FAILED.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.saga_step CASCADE;

-- @file 11-0060-ops.sql
-- @changeset ph11-0600-incident
CREATE TABLE ph11_bpm.incident (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  type          varchar(24) NOT NULL,
  instance_id   uuid,
  element_id    varchar(100),
  job_id        varchar(64),
  message       varchar(2000),
  error_code    varchar(32),
  retries_done  smallint NOT NULL DEFAULT 0,
  trace_id      char(32) NOT NULL,
  status        varchar(8) NOT NULL DEFAULT 'OPEN',
  opened_at     timestamptz NOT NULL DEFAULT now(),
  resolved_at   timestamptz,
  handled_by    varchar(64),
  reason        varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident PRIMARY KEY (id),
  CONSTRAINT ck_incident_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_incident_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_incident_type CHECK (type IN ('JOB_FAILED', 'SERVICE_TIMEOUT', 'CORRELATION_FAILED', 'TIMER_FAILED', 'COMPENSATION_FAILED', 'STUCK_INSTANCE', 'ENGINE_ERROR', 'SUPPLEMENT_EXPIRED')),
  CONSTRAINT ck_incident_status CHECK (status IN ('OPEN', 'RETRYING', 'RESOLVED', 'IGNORED')),
  CONSTRAINT ck_incident_resolved CHECK ((status IN ('RESOLVED', 'IGNORED')) = (resolved_at IS NOT NULL AND handled_by IS NOT NULL)),
  CONSTRAINT ck_incident_reason CHECK (status <> 'IGNORED' OR char_length(reason) >= 20),
  CONSTRAINT ck_incident_retries CHECK (retries_done >= 0),
  CONSTRAINT ck_incident_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE UNIQUE INDEX uq_incident_open_job ON ph11_bpm.incident (tenant_id, job_id) WHERE job_id IS NOT NULL AND status IN ('OPEN', 'RETRYING');
CREATE INDEX ix_incident_status ON ph11_bpm.incident (tenant_id, status, type, opened_at DESC);
CREATE INDEX ix_incident_instance ON ph11_bpm.incident (tenant_id, instance_id) WHERE instance_id IS NOT NULL;
CREATE TRIGGER tg_incident_touch BEFORE UPDATE ON ph11_bpm.incident FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_incident_immutable BEFORE UPDATE ON ph11_bpm.incident FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'type', 'job_id', 'opened_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.incident', 'P');
COMMENT ON TABLE ph11_bpm.incident IS 'EN-11-18 Sự cố engine và việc lỗi (FR-11-060, 061): job Flowable hết lần thử, service task hết hạn, thông điệp không tương quan được, hẹn giờ lỗi, bù trừ thất bại, phiên tắc, lỗi engine (IncidentType). Trạng thái IncidentStatus OPEN, RETRYING, RESOLVED, IGNORED; bỏ qua phải ghi lý do từ 20 ký tự. Một job lỗi chỉ một sự cố đang mở. Đẩy sự kiện EVT-11-16 khi mở.';
COMMENT ON COLUMN ph11_bpm.incident.type IS 'IncidentType: JOB_FAILED, SERVICE_TIMEOUT, CORRELATION_FAILED, TIMER_FAILED, COMPENSATION_FAILED, STUCK_INSTANCE, ENGINE_ERROR, SUPPLEMENT_EXPIRED (hết hạn bổ sung hồ sơ, FR-11-049, ERR-11-125).';
COMMENT ON COLUMN ph11_bpm.incident.job_id IS 'Mã job lỗi trong engine (ACT_RU_DEADLETTER_JOB.ID_); rỗng với sự cố không do job.';
COMMENT ON COLUMN ph11_bpm.incident.message IS 'Thông điệp lỗi đã lược dữ liệu cá nhân; không ghi giá trị biến.';
COMMENT ON COLUMN ph11_bpm.incident.retries_done IS 'Số lần thử lại thủ công và tự động đã thực hiện.';
COMMENT ON COLUMN ph11_bpm.incident.handled_by IS 'Người xử lý (thử lại thành công, giải quyết hoặc bỏ qua).';
COMMENT ON COLUMN ph11_bpm.incident.reason IS 'Lý do xử lý; bắt buộc từ 20 ký tự khi IGNORED.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.incident CASCADE;

-- @changeset ph11-0610-migration-plan
CREATE TABLE ph11_bpm.migration_plan (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  process_key      varchar(64) NOT NULL,
  from_version     integer NOT NULL,
  to_version       integer NOT NULL,
  filter           jsonb NOT NULL DEFAULT '{}',
  mappings         jsonb NOT NULL DEFAULT '[]',
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  approved_by      varchar(64),
  approved_at      timestamptz,
  decision_comment varchar(2000),
  summary          jsonb NOT NULL DEFAULT '{"total": 0, "migrated": 0, "failed": 0}',
  dry_run_report   jsonb,
  started_at       timestamptz,
  finished_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan PRIMARY KEY (id),
  CONSTRAINT ck_migration_plan_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_plan_from FOREIGN KEY (tenant_id, process_key, from_version) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT fk_migration_plan_to FOREIGN KEY (tenant_id, process_key, to_version) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT ck_migration_plan_versions CHECK (from_version <> to_version),
  CONSTRAINT ck_migration_plan_status CHECK (status IN ('DRAFT', 'VALIDATED', 'PENDING_APPROVAL', 'RUNNING', 'COMPLETED', 'PARTIAL', 'REJECTED')),
  CONSTRAINT ck_migration_plan_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_migration_plan_approved CHECK (status NOT IN ('RUNNING', 'COMPLETED', 'PARTIAL', 'REJECTED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_migration_plan_rejected CHECK (status <> 'REJECTED' OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_migration_plan_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_migration_plan_mappings CHECK (jsonb_typeof(mappings) = 'array'),
  CONSTRAINT ck_migration_plan_summary CHECK (jsonb_typeof(summary) = 'object' AND CASE WHEN (summary ->> 'total') ~ '^[0-9]{1,9}$' AND (summary ->> 'migrated') ~ '^[0-9]{1,9}$' AND (summary ->> 'failed') ~ '^[0-9]{1,9}$' THEN (summary ->> 'migrated')::bigint + (summary ->> 'failed')::bigint <= (summary ->> 'total')::bigint ELSE false END),
  CONSTRAINT ck_migration_plan_finished CHECK ((status IN ('COMPLETED', 'PARTIAL')) = (finished_at IS NOT NULL) OR status = 'REJECTED')
);
CREATE UNIQUE INDEX uq_migration_plan_running ON ph11_bpm.migration_plan (tenant_id, process_key) WHERE status = 'RUNNING';
CREATE INDEX ix_migration_plan_model ON ph11_bpm.migration_plan (tenant_id, process_key, created_at DESC);
CREATE TRIGGER tg_migration_plan_touch BEFORE UPDATE ON ph11_bpm.migration_plan FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_migration_plan_immutable BEFORE UPDATE ON ph11_bpm.migration_plan FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('process_key', 'from_version', 'to_version', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.migration_plan', 'P');
COMMENT ON TABLE ph11_bpm.migration_plan IS 'EN-11-19 Kế hoạch di trú phiên sang phiên bản mô hình mới (FR-11-026, PERM-11-instance-admin). Bốn mắt (BR-11-021): người duyệt khác người lập; ánh xạ bước cũ sang bước mới (mappings), kiểm tra trước khi chạy (dry_run_report); mỗi mô hình chỉ một kế hoạch RUNNING; chạy theo lô 11.migration.batchSize. PARTIAL là còn phiên lỗi; từ chối cần ý kiến từ 20 ký tự. Lý do từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.migration_plan.process_key IS 'Khóa mô hình; cùng from_version, to_version tạo khóa ngoại tới process_version.';
COMMENT ON COLUMN ph11_bpm.migration_plan.filter IS 'Điều kiện chọn phiên (API instanceFilter: trạng thái, bước hiện tại); rỗng là mọi phiên đang chạy của phiên bản nguồn.';
COMMENT ON COLUMN ph11_bpm.migration_plan.mappings IS 'Mảng ánh xạ bước, mỗi phần tử {fromElementId, toElementId} (API MappingItem).';
COMMENT ON COLUMN ph11_bpm.migration_plan.approved_by IS 'Người quyết định (duyệt hoặc từ chối), khác requested_by.';
COMMENT ON COLUMN ph11_bpm.migration_plan.decision_comment IS 'Ý kiến của người quyết định; từ chối cần từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.migration_plan.summary IS 'Kết quả chạy: {total, migrated, failed} (API MigrationSummary); migrated cộng failed không vượt total.';
COMMENT ON COLUMN ph11_bpm.migration_plan.dry_run_report IS 'Kết quả bước kiểm tra: số phiên hợp lệ, danh sách phiên không di trú được và lý do.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.migration_plan CASCADE;

-- @changeset ph11-0620-setting-validator splitStatements:false
-- Miền giá trị của 36 tham số 11.* theo FRS 8.2: số trong khoảng, chuỗi liệt kê, cron sáu trường, logic. Khóa ngoài danh sách bị từ chối.
CREATE OR REPLACE FUNCTION ph11_bpm.f_setting_valid(p_key text, p_value jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE AS $f$
  SELECT CASE
    WHEN jsonb_typeof(p_value) = 'number' THEN COALESCE((
      SELECT (p_value #>> '{}')::numeric BETWEEN r.lo AND r.hi
      FROM (VALUES ('11.task.dueSoonHours', 1, 72), ('11.task.bulkMax', 1, 2000), ('11.task.attachmentMaxMb', 1, 50),
                   ('11.delegation.maxDays', 1, 90), ('11.designer.lockMinutes', 5, 240), ('11.model.maxXmlKb', 256, 8192),
                   ('11.timer.minSeconds', 60, 3600), ('11.callActivity.maxDepth', 1, 5), ('11.service.defaultTimeoutMinutes', 1, 10080),
                   ('11.outbox.maxAttempts', 5, 100), ('11.instance.startRatePerClient', 1, 500), ('11.instance.stuckHours', 1, 720),
                   ('11.message.bufferMinutes', 0, 1440), ('11.migration.batchSize', 10, 1000), ('11.saga.maxRetries', 0, 10),
                   ('11.saga.retryBackoffSeconds', 30, 86400), ('11.due.scanMinutes', 1, 15), ('11.supplement.defaultDays', 1, 60),
                   ('11.bottleneck.minSamples', 10, 1000), ('11.bottleneck.factor', 1.2, 10), ('11.retention.instanceYears', 5, 20),
                   ('11.retention.sagaYears', 5, 20), ('11.retention.progressEventYears', 1, 10), ('11.retention.engineHistoryMonths', 3, 60),
                   ('11.test.retentionDays', 1, 30), ('11.ai.timeoutSeconds', 2, 30), ('11.progress.cacheSeconds', 0, 300),
                   ('11.designer.autosaveSeconds', 5, 300), ('11.task.draftDebounceSeconds', 1, 60), ('11.task.unmaskSeconds', 10, 300),
                   ('11.escalation.nextLevelHours', 1, 72)) AS r(k, lo, hi)
      WHERE r.k = p_key), false)
    WHEN jsonb_typeof(p_value) = 'boolean' THEN p_key = '11.supplement.resetDue'
    WHEN jsonb_typeof(p_value) = 'string' THEN CASE p_key
      WHEN '11.task.fallbackGroup' THEN char_length(p_value #>> '{}') BETWEEN 1 AND 64
      WHEN '11.due.receiveAfterHoursRule' THEN (p_value #>> '{}') IN ('NEXT_WORKING_START', 'SAME_DAY')
      WHEN '11.saga.reconcileCron' THEN (p_value #>> '{}') ~ '^\S+( \S+){5}$'
      WHEN '11.retention.cleanupCron' THEN (p_value #>> '{}') ~ '^\S+( \S+){5}$'
      ELSE false END
    ELSE false END
$f$;
COMMENT ON FUNCTION ph11_bpm.f_setting_valid(text, jsonb) IS 'Kiểm miền giá trị tham số 11.* theo FRS 8.2 (CHECK của tenant_setting); khóa ngoài danh sách 36 tham số bị từ chối.';
-- @rollback DROP FUNCTION IF EXISTS ph11_bpm.f_setting_valid(text, jsonb);

-- @changeset ph11-0630-tenant-setting
CREATE TABLE ph11_bpm.tenant_setting (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  key        varchar(64) NOT NULL,
  value      jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, key),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_tenant_setting_key CHECK (key ~ '^11\.[a-z][A-Za-z]{1,30}\.[a-z][A-Za-z]{1,40}$'),
  CONSTRAINT ck_tenant_setting_value CHECK (ph11_bpm.f_setting_valid(key, value))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph11_bpm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph11_bpm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('key', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.tenant_setting', 'S');
COMMENT ON TABLE ph11_bpm.tenant_setting IS 'EN-11-23 Tham số phân hệ theo tenant, 36 khóa 11.* của FRS 8.2 (FR-11-062, 063), PERM-11-config. Giá trị jsonb đúng kiểu và đơn vị của FRS (ví dụ 11.service.defaultTimeoutMinutes là phút), miền giá trị kiểm bằng ph11_bpm.f_setting_valid. Dòng tenant COMMON là trần nền tảng do PA đặt (mẫu S: tenant đọc được); tham số tenant không vượt trần (BR-11-024, dịch vụ so khi lưu). Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.tenant_setting.key IS 'Khóa dạng 11.{nhóm}.{tên}, ví dụ 11.task.dueSoonHours (API Setting.key).';
COMMENT ON COLUMN ph11_bpm.tenant_setting.value IS 'Giá trị JSON: số, chuỗi hoặc logic tùy khóa (API Setting.value).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.tenant_setting CASCADE;

-- @file 11-0070-messaging.sql
-- @changeset ph11-0700-outbox-event
CREATE TABLE ph11_bpm.outbox_event (
  event_id       uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'PENDING',
  attempts       smallint NOT NULL DEFAULT 0,
  sent_at        timestamptz,
  last_error     varchar(1000),
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('bpm.model.published.v1', 'bpm.model.retired.v1', 'bpm.instance.started.v1', 'bpm.instance.step.completed.v1', 'bpm.instance.completed.v1', 'bpm.instance.cancelled.v1', 'bpm.instance.suspended.v1', 'bpm.task.created.v1', 'bpm.task.assigned.v1', 'bpm.task.completed.v1', 'bpm.task.due-soon.v1', 'bpm.task.overdue.v1', 'bpm.saga.compensation.started.v1', 'bpm.saga.compensation.completed.v1', 'bpm.saga.compensation.failed.v1', 'bpm.incident.opened.v1', 'bpm.service.requested.v1', 'bpm.notification.requested.v1', 'bpm.audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_status CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
  CONSTRAINT ck_outbox_event_attempts CHECK (attempts BETWEEN 0 AND 100),
  CONSTRAINT ck_outbox_event_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL)),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['variables', 'formData', 'values', 'resultData', 'identifier', 'nationalId', 'fullName', 'dateOfBirth']))
);
CREATE INDEX ix_outbox_event_pending ON ph11_bpm.outbox_event (occurred_at) WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX ix_outbox_event_occurred ON ph11_bpm.outbox_event (occurred_at);
CREATE TRIGGER tg_outbox_event_immutable BEFORE UPDATE ON ph11_bpm.outbox_event FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('event_id', 'tenant_id', 'event_type', 'topic', 'aggregate_type', 'aggregate_id', 'partition_key', 'payload', 'occurred_at');
CALL ph11_bpm.p_enable_rls('ph11_bpm.outbox_event', 'P');
COMMENT ON TABLE ph11_bpm.outbox_event IS 'EN-11-21 Outbox (ADR-042, SAD 7.3; FR-11-028, 032, 056, 065) cho EVT-11-01…17, EVT-11-20, EVT-11-21 (bản ghi kiểm toán gửi PH-13). Ghi cùng giao dịch với thay đổi trạng thái (BR-11-023); bộ chuyển outbox đẩy lên Kafka, định tuyến theo topic, cập nhật status và attempts; quá 11.outbox.maxAttempts thì mở sự cố (ERR-11-101). Gồm cả lệnh service.requested tới PH-04 (ADR 112). Nội dung sự kiện bất biến sau khi ghi; không chứa giá trị biến, dữ liệu biểu mẫu hay định danh cá nhân: CHECK chặn các khóa đó ở cấp cao nhất.';
COMMENT ON COLUMN ph11_bpm.outbox_event.status IS 'Trạng thái đẩy: PENDING chờ đẩy, SENT đã đẩy, FAILED quá lượt thử; OutboxStatus của FRS Phụ lục A.';
COMMENT ON COLUMN ph11_bpm.outbox_event.attempts IS 'Số lần đã đẩy lên Kafka.';
COMMENT ON COLUMN ph11_bpm.outbox_event.partition_key IS 'Khóa phân vùng Kafka: businessKey (mọi sự kiện tiến độ) hoặc processKey (EVT-11-01, 02).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.outbox_event CASCADE;

-- @changeset ph11-0710-inbox-message
CREATE TABLE ph11_bpm.inbox_message (
  tenant_id       varchar(16) NOT NULL,
  consumer        varchar(64) NOT NULL,
  message_id      varchar(255) NOT NULL,
  source          varchar(249) NOT NULL,
  event_type      varchar(255) NOT NULL,
  correlation_key varchar(120),
  business_key    varchar(100),
  payload         jsonb,
  status          varchar(12) NOT NULL DEFAULT 'RECEIVED',
  attempts        smallint NOT NULL DEFAULT 0,
  received_at     timestamptz NOT NULL DEFAULT now(),
  processed_at    timestamptz,
  expires_at      timestamptz,
  outcome         varchar(2000),
  CONSTRAINT pk_inbox_message PRIMARY KEY (tenant_id, consumer, message_id),
  CONSTRAINT ck_inbox_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_message_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_message_prefix CHECK (split_part(source, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_inbox_message_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'UNCORRELATED', 'FAILED')),
  CONSTRAINT ck_inbox_message_processed CHECK ((status IN ('PROCESSED', 'FAILED')) = (processed_at IS NOT NULL)),
  CONSTRAINT ck_inbox_message_attempts CHECK (attempts BETWEEN 0 AND 20),
  CONSTRAINT ck_inbox_message_no_value CHECK (payload IS NULL OR NOT (payload ?| ARRAY['variables', 'formData', 'values', 'identifier', 'nationalId', 'fullName', 'dateOfBirth']))
);
CREATE INDEX ix_inbox_message_received ON ph11_bpm.inbox_message (received_at);
CREATE INDEX ix_inbox_message_waiting ON ph11_bpm.inbox_message (tenant_id, correlation_key) WHERE status = 'UNCORRELATED';
CALL ph11_bpm.p_enable_rls('ph11_bpm.inbox_message', 'P');
COMMENT ON TABLE ph11_bpm.inbox_message IS 'EN-11-22 Inbox chống xử lý trùng và giữ thông điệp chưa tương quan (at-least-once): kết quả service task từ PH-04 (EVT-11-18, 19), sự kiện khởi tạo, thông điệp từ PH-10 cho message catch (FR-11-019, 029, 030; BR-11-022). Khóa (consumer, message_id). Thông điệp đến trước khi phiên tới bước chờ giữ ở UNCORRELATED đến expires_at (11.message.bufferMinutes) rồi mở sự cố CORRELATION_FAILED.';
COMMENT ON COLUMN ph11_bpm.inbox_message.source IS 'Topic Kafka nguồn của thông điệp, tiền tố là tenant viết thường (FRS: source).';
COMMENT ON COLUMN ph11_bpm.inbox_message.status IS 'Trạng thái xử lý: RECEIVED, PROCESSED, UNCORRELATED (chờ phiên), FAILED; InboxStatus của FRS Phụ lục A.';
COMMENT ON COLUMN ph11_bpm.inbox_message.payload IS 'Nội dung đã lược; không chứa khóa biến, biểu mẫu, định danh cá nhân (CHECK). Dữ liệu cá nhân của thông điệp không được giữ ở đây.';
COMMENT ON COLUMN ph11_bpm.inbox_message.expires_at IS 'Hạn giữ khi UNCORRELATED; quá hạn không tương quan được thì mở sự cố.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.inbox_message CASCADE;

-- @changeset ph11-0720-shedlock
CREATE TABLE ph11_bpm.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph11_bpm.shedlock IS 'Khóa tác vụ nền (DueScanner, TimerCatchUp, InboxReaper, OutboxCleaner, SagaReconciler, RetentionPurgeJob, PartitionMaintenanceJob, DelegationExpirer); bảng kỹ thuật của ShedLock, không có tenant_id. Bảng ngoài FRS Phụ lục A, hạ tầng.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.shedlock CASCADE;

-- @file 11-0075-compliance.sql
-- @changeset ph11-0730-saga-skip-request
CREATE TABLE ph11_bpm.saga_skip_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  saga_id          uuid NOT NULL,
  step_id          uuid NOT NULL,
  reason           varchar(2000) NOT NULL,
  evidence         jsonb NOT NULL DEFAULT '[]',
  requested_by     varchar(64) NOT NULL,
  status           varchar(8) NOT NULL DEFAULT 'PENDING',
  task_id          uuid,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_skip_request PRIMARY KEY (id),
  CONSTRAINT uq_saga_skip_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_saga_skip_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_skip_request_saga FOREIGN KEY (tenant_id, saga_id) REFERENCES ph11_bpm.saga_log (tenant_id, id),
  CONSTRAINT fk_saga_skip_request_step FOREIGN KEY (tenant_id, step_id) REFERENCES ph11_bpm.saga_step (tenant_id, id),
  CONSTRAINT fk_saga_skip_request_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT ck_saga_skip_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  CONSTRAINT ck_saga_skip_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_saga_skip_request_evidence CHECK (jsonb_typeof(evidence) = 'array'),
  CONSTRAINT ck_saga_skip_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_saga_skip_request_decided CHECK ((status = 'PENDING') = (decided_by IS NULL AND decided_at IS NULL)),
  CONSTRAINT ck_saga_skip_request_reject CHECK (status <> 'REJECTED' OR char_length(decision_comment) >= 20)
);
CREATE UNIQUE INDEX uq_saga_skip_request_pending ON ph11_bpm.saga_skip_request (tenant_id, step_id) WHERE status = 'PENDING';
CREATE INDEX ix_saga_skip_request_step ON ph11_bpm.saga_skip_request (tenant_id, step_id, created_at DESC);
CREATE INDEX ix_saga_skip_request_open ON ph11_bpm.saga_skip_request (tenant_id, created_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_saga_skip_request_touch BEFORE UPDATE ON ph11_bpm.saga_skip_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_skip_request_immutable BEFORE UPDATE ON ph11_bpm.saga_skip_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('saga_id', 'step_id', 'reason', 'evidence', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_skip_request', 'P');
COMMENT ON TABLE ph11_bpm.saga_skip_request IS 'Ngoài FRS, đề nghị EN-11-29. Đề nghị bỏ qua một bước bù trừ thủ công (FR-11-053, API-11-101, 132, 133). Bốn mắt (BR-11-012, ERR-11-005): người duyệt hoặc từ chối khác người đề nghị. Bước saga_step vẫn MANUAL đến khi được duyệt (thành SKIPPED, resolved_by là người duyệt); từ chối đưa bước về MANUAL. Mỗi bước tối đa một đề nghị PENDING; đề nghị bị từ chối giữ lại làm bằng chứng. Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.step_id IS 'Bước bù trừ được đề nghị bỏ qua; cùng saga_id tạo khóa ngoại tới saga_step, saga_log.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.reason IS 'Lý do đề nghị (API SkipBody.reason), từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.evidence IS 'Mảng bằng chứng, mỗi phần tử {note, docNumber, objectRef, confirmedBy} (API ManualEvidence); tệp ở Ceph RGW, chỉ lưu tham chiếu.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.requested_by IS 'Người đề nghị (TA hoặc TO có PERM-11-compensate); không được tự duyệt.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.status IS 'SkipRequestStatus: PENDING chờ duyệt, APPROVED đã duyệt (bước SKIPPED), REJECTED bị từ chối (bước về MANUAL).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.task_id IS 'Việc MANUAL_COMPENSATION giao cho TA khác để duyệt (API SkipRequested.taskId).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.decided_by IS 'Người duyệt hoặc từ chối, khác requested_by.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.decision_comment IS 'Ý kiến người quyết định (API CommentBody, RejectBody); từ chối cần từ 20 ký tự (ERR-11-007).';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.saga_skip_request CASCADE;

-- @changeset ph11-0740-legal-hold
CREATE TABLE ph11_bpm.legal_hold (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  business_key     varchar(100) NOT NULL,
  reason           varchar(2000) NOT NULL,
  hold_until       timestamptz,
  released_at      timestamptz,
  released_by      varchar(64),
  release_reason   varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_hold PRIMARY KEY (id),
  CONSTRAINT uq_legal_hold_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_hold_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legal_hold_key CHECK (char_length(business_key) >= 3),
  CONSTRAINT ck_legal_hold_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_legal_hold_until CHECK (hold_until IS NULL OR hold_until > created_at),
  CONSTRAINT ck_legal_hold_release CHECK ((released_at IS NULL) = (released_by IS NULL) AND (released_at IS NULL) = (release_reason IS NULL)),
  CONSTRAINT ck_legal_hold_release_reason CHECK (release_reason IS NULL OR char_length(release_reason) >= 10)
);
CREATE UNIQUE INDEX uq_legal_hold_active ON ph11_bpm.legal_hold (tenant_id, business_key) WHERE released_at IS NULL;
CREATE INDEX ix_legal_hold_key ON ph11_bpm.legal_hold (tenant_id, business_key, created_at DESC);
CREATE TRIGGER tg_legal_hold_touch BEFORE UPDATE ON ph11_bpm.legal_hold FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_legal_hold_immutable BEFORE UPDATE ON ph11_bpm.legal_hold FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('business_key', 'reason', 'hold_until', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.legal_hold', 'P');
COMMENT ON TABLE ph11_bpm.legal_hold IS 'Ngoài FRS, đề nghị EN-11-30. Giữ pháp lý theo mã hồ sơ (FR-11-054, 063, API-11-120, 134, 135, PERM-11-config): hồ sơ đang giữ không bị dọn lịch sử engine hay bản nghiệp vụ (ERR-11-047, BR-11-025) đến khi gỡ hoặc hết hold_until. Mỗi business_key tối đa một giữ đang hiệu lực; giữ đã gỡ giữ lại làm bằng chứng, không xóa (quyền). Không khóa ngoại tới instance_index vì giữ có thể đặt trước phiên.';
COMMENT ON COLUMN ph11_bpm.legal_hold.business_key IS 'Mã hồ sơ cần giữ (API businessKey, 3…100 ký tự), khớp instance_index.business_key; không chứa dữ liệu cá nhân.';
COMMENT ON COLUMN ph11_bpm.legal_hold.reason IS 'Căn cứ pháp lý (API reason), từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.legal_hold.hold_until IS 'Hạn giữ (API holdUntil); rỗng là giữ đến khi gỡ.';
COMMENT ON COLUMN ph11_bpm.legal_hold.released_at IS 'Thời điểm gỡ giữ (API releasedAt); rỗng là còn hiệu lực. Cùng released_by, release_reason: cả ba có hoặc cả ba rỗng.';
COMMENT ON COLUMN ph11_bpm.legal_hold.released_by IS 'Người gỡ giữ (API releasedBy).';
COMMENT ON COLUMN ph11_bpm.legal_hold.release_reason IS 'Lý do gỡ (API releaseReason, ReasonBody), từ 10 ký tự.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.legal_hold CASCADE;

-- @changeset ph11-0750-compliance-sample-run
CREATE TABLE ph11_bpm.compliance_sample_run (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  evidence_pack_id uuid NOT NULL,
  environment      varchar(8) NOT NULL,
  status           varchar(8) NOT NULL DEFAULT 'RUNNING',
  requested_by     varchar(64) NOT NULL,
  include_models   jsonb NOT NULL DEFAULT '[]',
  period_from      timestamptz,
  period_to        timestamptz,
  engine_instance_id varchar(64),
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  checksum         bytea,
  pack_ref         varchar(500),
  result           jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_sample_run PRIMARY KEY (id),
  CONSTRAINT uq_compliance_sample_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_compliance_sample_run_pack UNIQUE (tenant_id, evidence_pack_id),
  CONSTRAINT ck_compliance_sample_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_compliance_sample_run_env CHECK (environment IN ('TEST', 'STAGING')),
  CONSTRAINT ck_compliance_sample_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ABORTED')),
  CONSTRAINT ck_compliance_sample_run_models CHECK (jsonb_typeof(include_models) = 'array'),
  CONSTRAINT ck_compliance_sample_run_period CHECK ((period_from IS NULL) = (period_to IS NULL) AND (period_from IS NULL OR (period_to > period_from AND period_to - period_from <= interval '366 days'))),
  CONSTRAINT ck_compliance_sample_run_ended CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_compliance_sample_run_checksum CHECK (checksum IS NULL OR octet_length(checksum) = 32),
  CONSTRAINT ck_compliance_sample_run_pack CHECK (status NOT IN ('PASSED', 'FAILED') OR (checksum IS NOT NULL AND pack_ref IS NOT NULL)),
  CONSTRAINT ck_compliance_sample_run_result CHECK (result IS NULL OR jsonb_typeof(result) = 'object')
);
CREATE INDEX ix_compliance_sample_run_list ON ph11_bpm.compliance_sample_run (tenant_id, environment, started_at DESC);
CREATE TRIGGER tg_compliance_sample_run_touch BEFORE UPDATE ON ph11_bpm.compliance_sample_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_compliance_sample_run_immutable BEFORE UPDATE ON ph11_bpm.compliance_sample_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('evidence_pack_id', 'environment', 'requested_by', 'include_models', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.compliance_sample_run', 'P');
COMMENT ON TABLE ph11_bpm.compliance_sample_run IS 'Ngoài FRS, đề nghị EN-11-31. Lần chạy mẫu tuân thủ BPMN 2.0 và gói bằng chứng (FR-11-064, API-11-121, 122, 137): mô hình MAU_TUAN_THU_BPMN chạy trên TEST hoặc STAGING, gói PDF và JSON có băm lưu ở Ceph RGW. Khác test_run (chạy thử mô hình nháp). Khoảng thống kê tối đa 366 ngày (ERR-11-039). Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.evidence_pack_id IS 'Mã gói bằng chứng (API evidencePackId) dùng tải gói qua API-11-122; duy nhất trong tenant.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.environment IS 'Môi trường chạy mẫu (API environment). FR-11-064 chỉ nhận TEST, STAGING (Environment của FRS có thêm PROD).';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.status IS 'TestRunStatus: RUNNING đang chạy, PASSED đạt, FAILED chưa đạt, ABORTED dừng giữa chừng.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.include_models IS 'Mảng khóa mô hình thật đính kèm thống kê (API includeModels), mỗi phần tử theo mẫu process_key.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.period_from IS 'Đầu khoảng thống kê (API from); cùng period_to hoặc cả hai rỗng.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.engine_instance_id IS 'Mã phiên mẫu trong Flowable.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.checksum IS 'SHA-256 gói bằng chứng, đúng 32 byte (API checksum, dạng hex); bắt buộc khi PASSED, FAILED.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.pack_ref IS 'Khóa đối tượng của gói ở Ceph RGW; bắt buộc khi PASSED, FAILED.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.result IS 'Biên bản chạy: phần tử BPMN 2.0 đã thực thi, phiên bản Flowable, lỗi khi FAILED.';
-- @rollback DROP TABLE IF EXISTS ph11_bpm.compliance_sample_run CASCADE;

-- @file 11-0800-seed.sql
-- @changeset ph11-0800-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: 36 tham số 11.* mặc định theo FRS 8.2 (đúng khóa, kiểu, đơn vị), lịch làm việc mặc định cho năm hiện tại và năm sau
-- (thứ Hai đến thứ Sáu, 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30). Ngày nghỉ lễ do TA nhập hoặc nhập từ lịch quốc gia (FR-11-045).
CREATE OR REPLACE PROCEDURE ph11_bpm.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
DECLARE
  y integer := extract(year FROM now() AT TIME ZONE 'Asia/Ho_Chi_Minh');
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by)
  SELECT md5('ph11-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('11.task.dueSoonHours', '8'), ('11.task.fallbackGroup', '"VAN_HANH_QUY_TRINH"'), ('11.task.bulkMax', '500'),
               ('11.task.attachmentMaxMb', '20'), ('11.delegation.maxDays', '30'), ('11.designer.lockMinutes', '30'),
               ('11.model.maxXmlKb', '2048'), ('11.timer.minSeconds', '60'), ('11.callActivity.maxDepth', '3'),
               ('11.service.defaultTimeoutMinutes', '2880'), ('11.outbox.maxAttempts', '20'), ('11.instance.startRatePerClient', '50'),
               ('11.instance.stuckHours', '72'), ('11.message.bufferMinutes', '60'), ('11.migration.batchSize', '100'),
               ('11.saga.maxRetries', '3'), ('11.saga.retryBackoffSeconds', '300'), ('11.saga.reconcileCron', '"0 0 2 * * *"'),
               ('11.due.scanMinutes', '1'), ('11.due.receiveAfterHoursRule', '"NEXT_WORKING_START"'), ('11.supplement.defaultDays', '15'),
               ('11.supplement.resetDue', 'false'), ('11.bottleneck.minSamples', '30'), ('11.bottleneck.factor', '2.0'),
               ('11.retention.instanceYears', '5'), ('11.retention.sagaYears', '5'), ('11.retention.progressEventYears', '2'),
               ('11.retention.engineHistoryMonths', '12'), ('11.retention.cleanupCron', '"0 0 1 * * *"'), ('11.test.retentionDays', '7'),
               ('11.ai.timeoutSeconds', '10'), ('11.progress.cacheSeconds', '30'), ('11.designer.autosaveSeconds', '30'),
               ('11.task.draftDebounceSeconds', '5'), ('11.task.unmaskSeconds', '60'), ('11.escalation.nextLevelHours', '4')) AS s(k, v)
  ON CONFLICT (tenant_id, key) DO NOTHING;
  INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by)
  SELECT md5('ph11-calendar:' || p_tenant || ':' || yy)::uuid, p_tenant, yy, 'system:seed', 'system:seed'
  FROM generate_series(y, y + 1) AS yy
  ON CONFLICT (tenant_id, year) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph11_bpm.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 36 tham số 11.* mặc định theo FRS 8.2, lịch làm việc năm hiện tại và năm sau. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_seed_tenant(text);

-- @changeset ph11-0810-seed-common-template splitStatements:false
-- Mẫu nền tảng ở tenant COMMON (FR-11-015): duyệt một cấp, một việc người dùng. Ghi bằng phiên PLATFORM.
DO $seed$
DECLARE
  x text := '<?xml version="1.0" encoding="UTF-8"?><definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" targetNamespace="https://datahub.vn/bpm/template"><process id="DUYET_MOT_CAP" name="Duyệt một cấp" isExecutable="true"><startEvent id="batDau"/><sequenceFlow id="f1" sourceRef="batDau" targetRef="duyet"/><userTask id="duyet" name="Duyệt hồ sơ"/><sequenceFlow id="f2" sourceRef="duyet" targetRef="ketThuc"/><endEvent id="ketThuc"/></process></definitions>';
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph11_bpm.process_template (id, tenant_id, template_code, version_no, name, description, group_code, status, source_xml, checksum, created_by, updated_by)
  VALUES (md5('ph11-template:COMMON:DUYET_MOT_CAP:1')::uuid, 'COMMON', 'DUYET_MOT_CAP', 1, 'Duyệt một cấp',
          'Mẫu tối thiểu: một việc duyệt giữa sự kiện bắt đầu và kết thúc; dùng làm điểm xuất phát khi tạo mô hình.', 'DUYET_NOI_BO', 'PUBLISHED',
          x, sha256(convert_to(x, 'UTF8')), 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$seed$;
-- @rollback DELETE FROM ph11_bpm.process_template WHERE tenant_id = 'COMMON' AND template_code = 'DUYET_MOT_CAP';

-- @file 11-0900-grants.sql
-- @changeset ph11-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph11_bpm TO ph11_app;
-- Cấu hình, phiên bản, bằng chứng phê duyệt, can thiệp phiên và nhật ký Saga không xóa cứng; chỉ dọn bản chiếu, bảng trung gian, chạy thử và ngày lịch theo chính sách lưu giữ.
REVOKE DELETE ON ph11_bpm.process_model, ph11_bpm.process_version, ph11_bpm.form_definition, ph11_bpm.service_intent, ph11_bpm.compensation_action,
  ph11_bpm.process_template, ph11_bpm.variable_definition, ph11_bpm.decision_table, ph11_bpm.publish_request, ph11_bpm.migration_plan,
  ph11_bpm.instance_change, ph11_bpm.business_calendar, ph11_bpm.saga_log, ph11_bpm.saga_step, ph11_bpm.tenant_setting,
  ph11_bpm.delegation, ph11_bpm.saga_skip_request, ph11_bpm.legal_hold, ph11_bpm.compliance_sample_run FROM ph11_app;
-- Bảng chỉ thêm: ý kiến trên việc không sửa, không xóa (trigger là lớp chặn thứ hai); lịch sử bước dọn bằng DETACH phân vùng dưới ph11_owner.
REVOKE UPDATE, DELETE ON ph11_bpm.task_comment FROM ph11_app;
REVOKE DELETE ON ph11_bpm.instance_step FROM ph11_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph11_bpm TO ph11_readonly;
-- Báo cáo không đọc kết quả biểu mẫu, nháp, ý kiến, tệp đính kèm, thông điệp nhận, nội dung đề nghị can thiệp và kết quả chạy thử: thu hồi ở bảng nhạy cảm rồi cấp lại theo cột an toàn.
REVOKE SELECT ON ph11_bpm.task_index, ph11_bpm.task_comment, ph11_bpm.task_attachment, ph11_bpm.inbox_message, ph11_bpm.instance_change, ph11_bpm.test_run FROM ph11_readonly;
GRANT SELECT (id, tenant_id, engine_task_id, instance_id, element_id, task_kind, name, form_key, status, assignee, priority, due_at, claimed_at, closed_at, decision, created_at, updated_at)
  ON ph11_bpm.task_index TO ph11_readonly;
GRANT EXECUTE ON PROCEDURE ph11_bpm.p_ensure_partitions(regclass, date, integer) TO ph11_app;
GRANT EXECUTE ON PROCEDURE ph11_bpm.p_seed_tenant(text) TO ph11_app;
-- Engine Flowable: ph11_engine là chủ schema ph11_flowable nên toàn quyền; schema mới không cấp gì cho PUBLIC, ph11_app và ph11_readonly không truy cập.
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
