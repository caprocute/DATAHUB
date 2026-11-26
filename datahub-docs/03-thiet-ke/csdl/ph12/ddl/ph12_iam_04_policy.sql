-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam
-- Tệp 04: chính sách, phiên bản, ca kiểm thử, chạy khô, gói chính sách, xác nhận nạp
--         (nhóm FR-12-F; EN-12-12…14)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- Máy trạng thái phiên bản chính sách chốt ở CSDL theo ADR-069 (trigger tg_policy_version_guard).
-- =============================================================================

\set ON_ERROR_STOP on
RESET ROLE;
SET ROLE ph12_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 12-0080-policy.sql
-- @changeset ph12-0800-policy
CREATE TABLE ph12_iam.policy (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(64)   NOT NULL,
  scope            varchar(8)    NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  is_root          boolean       NOT NULL DEFAULT false,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy PRIMARY KEY (id),
  CONSTRAINT uq_policy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_policy_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_policy_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_policy_code CHECK (code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_policy_scope CHECK (scope IN ('PLATFORM', 'TENANT') AND (scope = 'PLATFORM') = (tenant_id = 'PLATFORM')),
  CONSTRAINT ck_policy_root CHECK (NOT is_root OR scope = 'PLATFORM')
);
CREATE TRIGGER tg_policy_touch BEFORE UPDATE ON ph12_iam.policy FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CREATE TRIGGER tg_policy_no_delete BEFORE DELETE ON ph12_iam.policy FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_no_delete();
CALL ph12_iam.p_enable_rls('ph12_iam.policy', 'P');
COMMENT ON TABLE ph12_iam.policy IS 'EN-12-12 (phần chính sách) Một mã chính sách Rego, ví dụ base-authz. Phạm vi PLATFORM (mọi tenant, tenant_id = PLATFORM) hoặc TENANT (một tỉnh, chỉ thêm luật chặt hơn, BR-12-007). Nội dung nằm ở policy_version. Chính sách gốc is_root không thu hồi được (ERR-12-027).';
COMMENT ON COLUMN ph12_iam.policy.is_root IS 'true với base-authz: gói gốc bảo đảm từ chối mặc định, từ chối thắng cho phép và cách ly tenant; không thu hồi, không quay lui về rỗng.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy CASCADE;

-- @changeset ph12-0810-policy-version
CREATE TABLE ph12_iam.policy_version (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  policy_id             uuid          NOT NULL,
  version_no            integer       NOT NULL,
  content               text          NOT NULL,
  content_hash          char(64)      NOT NULL,
  state                 varchar(18)   NOT NULL DEFAULT 'DRAFT',
  author                varchar(64)   NOT NULL,
  submitted_by          varchar(64),
  submitted_at          timestamptz,
  approved_by           varchar(64),
  approved_at           timestamptz,
  review_note           varchar(2000),
  high_impact_confirmed boolean       NOT NULL DEFAULT false,
  git_commit            char(40),
  bundle_revision       varchar(64),
  published_at          timestamptz,
  revoked_by            varchar(64),
  revoked_reason        varchar(1000),
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_version PRIMARY KEY (id),
  CONSTRAINT uq_policy_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_policy_version_no UNIQUE (policy_id, version_no),
  CONSTRAINT fk_policy_version_policy FOREIGN KEY (policy_id, tenant_id) REFERENCES ph12_iam.policy (id, tenant_id),
  CONSTRAINT ck_policy_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_policy_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_policy_version_content CHECK (octet_length(content) BETWEEN 1 AND 262144),
  CONSTRAINT ck_policy_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_policy_version_state CHECK (state IN ('DRAFT', 'PENDING_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'PUBLISHED', 'SUPERSEDED', 'REVOKED', 'DISCARDED')),
  CONSTRAINT ck_policy_version_submitted CHECK (state IN ('DRAFT', 'DISCARDED') OR (submitted_by IS NOT NULL AND submitted_at IS NOT NULL)),
  CONSTRAINT ck_policy_version_four_eyes CHECK (approved_by IS NULL OR (approved_by <> author AND approved_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_policy_version_approved CHECK (state NOT IN ('APPROVED', 'PUBLISHED', 'SUPERSEDED', 'REVOKED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_policy_version_published CHECK (state NOT IN ('PUBLISHED', 'SUPERSEDED') OR (bundle_revision IS NOT NULL AND published_at IS NOT NULL)),
  CONSTRAINT ck_policy_version_revoked CHECK (state <> 'REVOKED' OR (revoked_by IS NOT NULL AND revoked_reason IS NOT NULL)),
  CONSTRAINT ck_policy_version_commit CHECK (git_commit IS NULL OR git_commit ~ '^[0-9a-f]{40}$')
);
CREATE UNIQUE INDEX uq_policy_version_published ON ph12_iam.policy_version (tenant_id, policy_id) WHERE state = 'PUBLISHED';
CREATE INDEX ix_policy_version_state ON ph12_iam.policy_version (tenant_id, state, updated_at DESC);
CREATE INDEX ix_policy_version_pending ON ph12_iam.policy_version (tenant_id, submitted_at) WHERE state = 'PENDING_REVIEW';
CREATE INDEX ix_policy_version_hash ON ph12_iam.policy_version (content_hash);
CREATE TRIGGER tg_policy_version_touch BEFORE UPDATE ON ph12_iam.policy_version FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CREATE TRIGGER tg_policy_version_no_delete BEFORE DELETE ON ph12_iam.policy_version FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_no_delete();
CALL ph12_iam.p_enable_rls('ph12_iam.policy_version', 'P');
COMMENT ON TABLE ph12_iam.policy_version IS 'EN-12-12 Phiên bản chính sách Rego, bất biến sau khi gửi duyệt (nội dung chỉ sửa được ở DRAFT, CHANGES_REQUESTED). Máy trạng thái, điều kiện gửi duyệt (kiểm thử đạt, chạy khô đúng content_hash), bốn mắt và xác nhận tác động lớn đều chốt ở trigger tg_policy_version_guard (ADR-069, BR-12-008…010). Mỗi mã có đúng một PUBLISHED. Không xóa vật lý.';
COMMENT ON COLUMN ph12_iam.policy_version.content IS 'Mã Rego, tối đa 256 KiB (PolicyLinter kiểm trước khi chạm policy-runner).';
COMMENT ON COLUMN ph12_iam.policy_version.content_hash IS 'SHA-256 hex của content (UTF-8), do trigger tg_policy_version_hash tính; kết quả kiểm thử và chạy khô gắn với băm này nên sửa một ký tự là mất hiệu lực (BR-12-009).';
COMMENT ON COLUMN ph12_iam.policy_version.author IS 'Người soạn (tạo bản nháp); người đóng góp khác ở policy_version_contributor.';
COMMENT ON COLUMN ph12_iam.policy_version.high_impact_confirmed IS 'Người duyệt đã xác nhận bổ sung khi chạy khô đổi quá ngưỡng hoặc có trường hợp từ chối sang cho phép (BR-12-011, ERR-12-029).';
COMMENT ON COLUMN ph12_iam.policy_version.bundle_revision IS 'bundleRevision của gói đầu tiên chứa phiên bản này, ví dụ t68-20261126-0153; đặt khi PUBLISHED.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy_version CASCADE;

-- @changeset ph12-0815-policy-version-contributor
CREATE TABLE ph12_iam.policy_version_contributor (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  version_id       uuid          NOT NULL,
  user_ref         varchar(64)   NOT NULL,
  first_saved_at   timestamptz   NOT NULL DEFAULT now(),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_policy_version_contributor PRIMARY KEY (id),
  CONSTRAINT uq_policy_version_contributor UNIQUE (version_id, user_ref),
  CONSTRAINT fk_policy_version_contributor_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph12_iam.policy_version (id, tenant_id),
  CONSTRAINT ck_policy_version_contributor_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$')
);
CREATE TRIGGER tg_policy_version_contributor_append_only BEFORE UPDATE OR DELETE ON ph12_iam.policy_version_contributor
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_append_only();
CALL ph12_iam.p_enable_rls('ph12_iam.policy_version_contributor', 'P');
COMMENT ON TABLE ph12_iam.policy_version_contributor IS 'Người đóng góp mỗi phiên bản, ghi ở lần lưu nháp đầu tiên của từng người. Người duyệt không được nằm trong danh sách này (BR-12-008). Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy_version_contributor CASCADE;

-- @changeset ph12-0820-policy-test-case
CREATE TABLE ph12_iam.policy_test_case (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  policy_id        uuid          NOT NULL,
  name             varchar(255)  NOT NULL,
  kind             varchar(8)    NOT NULL,
  input            jsonb         NOT NULL,
  expected         jsonb         NOT NULL,
  description      varchar(2000),
  active           boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_test_case PRIMARY KEY (id),
  CONSTRAINT uq_policy_test_case UNIQUE (policy_id, name),
  CONSTRAINT fk_policy_test_case_policy FOREIGN KEY (policy_id, tenant_id) REFERENCES ph12_iam.policy (id, tenant_id),
  CONSTRAINT ck_policy_test_case_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_policy_test_case_kind CHECK (kind IN ('POSITIVE', 'NEGATIVE')),
  CONSTRAINT ck_policy_test_case_json CHECK (jsonb_typeof(input) = 'object' AND jsonb_typeof(expected) = 'object' AND expected ? 'allow' AND jsonb_typeof(expected -> 'allow') = 'boolean'),
  CONSTRAINT ck_policy_test_case_no_secret CHECK (NOT ph12_iam.f_json_has_secret_key(input)),
  CONSTRAINT ck_policy_test_case_size CHECK (pg_column_size(input) <= 65536)
);
CREATE INDEX ix_policy_test_case_policy ON ph12_iam.policy_test_case (tenant_id, policy_id) WHERE active;
CREATE TRIGGER tg_policy_test_case_touch BEFORE UPDATE ON ph12_iam.policy_test_case FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.policy_test_case', 'P');
COMMENT ON TABLE ph12_iam.policy_test_case IS 'EN-12-13 Ca kiểm thử của một chính sách (đầu vào input JSON, kết quả mong đợi {allow, reason}); mỗi luật mới cần ít nhất một ca dương (POSITIVE: mong allow) và một ca âm (NEGATIVE: mong từ chối) (FR-12-052). Bản sao ở Git dh-policies.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy_test_case CASCADE;

-- @changeset ph12-0830-policy-test-run
CREATE TABLE ph12_iam.policy_test_run (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  version_id           uuid          NOT NULL,
  content_hash         char(64)      NOT NULL,
  base_bundle_revision varchar(64)   NOT NULL,
  passed               boolean       NOT NULL,
  total_cases          integer       NOT NULL,
  positive_cases       integer       NOT NULL,
  negative_cases       integer       NOT NULL,
  failed_cases         integer       NOT NULL,
  coverage_pct         numeric(5,2)  NOT NULL,
  started_at           timestamptz   NOT NULL,
  finished_at          timestamptz   NOT NULL,
  runner_log_ref       varchar(512),
  trace_id             char(32)      NOT NULL,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  CONSTRAINT pk_policy_test_run PRIMARY KEY (id),
  CONSTRAINT fk_policy_test_run_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph12_iam.policy_version (id, tenant_id),
  CONSTRAINT ck_policy_test_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_policy_test_run_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_policy_test_run_counts CHECK (total_cases >= 0 AND positive_cases >= 0 AND negative_cases >= 0 AND failed_cases >= 0 AND failed_cases <= total_cases AND positive_cases + negative_cases <= total_cases),
  CONSTRAINT ck_policy_test_run_coverage CHECK (coverage_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_policy_test_run_passed CHECK (NOT passed OR (failed_cases = 0 AND positive_cases >= 1 AND negative_cases >= 1 AND coverage_pct >= 90)),
  CONSTRAINT ck_policy_test_run_time CHECK (finished_at >= started_at),
  CONSTRAINT ck_policy_test_run_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_policy_test_run_version ON ph12_iam.policy_test_run (tenant_id, version_id, content_hash, finished_at DESC);
CREATE TRIGGER tg_policy_test_run_append_only BEFORE UPDATE OR DELETE ON ph12_iam.policy_test_run
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_append_only();
CALL ph12_iam.p_enable_rls('ph12_iam.policy_test_run', 'P');
COMMENT ON TABLE ph12_iam.policy_test_run IS 'Kết quả một lần chạy opa test gắn với content_hash và bundleRevision của gói gốc (FR-12-052, BR-12-009). passed = true chỉ khi mọi ca đạt, có ít nhất một ca dương và một ca âm, độ phủ dòng ≥ 90% (CHECK ck_policy_test_run_passed, SEC-26). Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy_test_run CASCADE;

-- @changeset ph12-0840-policy-dryrun-report
CREATE TABLE ph12_iam.policy_dryrun_report (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  version_id           uuid          NOT NULL,
  content_hash         char(64)      NOT NULL,
  base_bundle_revision varchar(64)   NOT NULL,
  status               varchar(8)    NOT NULL DEFAULT 'RUNNING',
  window_from          timestamptz   NOT NULL,
  window_to            timestamptz   NOT NULL,
  sample_count         integer       NOT NULL DEFAULT 0,
  changed_count        integer       NOT NULL DEFAULT 0,
  deny_to_allow_count  integer       NOT NULL DEFAULT 0,
  allow_to_deny_count  integer       NOT NULL DEFAULT 0,
  change_threshold     numeric(4,3)  NOT NULL DEFAULT 0.200,
  changed_ratio        numeric(6,5)  GENERATED ALWAYS AS (CASE WHEN sample_count = 0 THEN 0 ELSE round(changed_count::numeric / sample_count, 5) END) STORED,
  small_sample         boolean       GENERATED ALWAYS AS (sample_count < 100) STORED,
  summary              jsonb         NOT NULL DEFAULT '{}',
  error_code           varchar(16),
  finished_at          timestamptz,
  purge_after          timestamptz   NOT NULL DEFAULT now() + interval '12 months',
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  CONSTRAINT pk_policy_dryrun_report PRIMARY KEY (id),
  CONSTRAINT fk_policy_dryrun_report_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph12_iam.policy_version (id, tenant_id),
  CONSTRAINT ck_policy_dryrun_report_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_policy_dryrun_report_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_policy_dryrun_report_status CHECK (status IN ('RUNNING', 'DONE', 'FAILED') AND (status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_policy_dryrun_report_window CHECK (window_to > window_from AND window_to <= window_from + interval '168 hours'),
  CONSTRAINT ck_policy_dryrun_report_counts CHECK (sample_count >= 0 AND changed_count BETWEEN 0 AND sample_count AND deny_to_allow_count + allow_to_deny_count <= changed_count),
  CONSTRAINT ck_policy_dryrun_report_threshold CHECK (change_threshold BETWEEN 0.05 AND 0.5),
  CONSTRAINT ck_policy_dryrun_report_summary CHECK (jsonb_typeof(summary) = 'object' AND NOT ph12_iam.f_json_has_secret_key(summary))
);
CREATE INDEX ix_policy_dryrun_report_version ON ph12_iam.policy_dryrun_report (tenant_id, version_id, content_hash, finished_at DESC);
CREATE INDEX ix_policy_dryrun_report_purge ON ph12_iam.policy_dryrun_report (purge_after);
CALL ph12_iam.p_enable_rls('ph12_iam.policy_dryrun_report', 'P');
COMMENT ON TABLE ph12_iam.policy_dryrun_report IS 'Báo cáo chạy khô trên lưu lượng thật gần đây (FR-12-053): số mẫu, tỷ lệ quyết định đổi (cột sinh changed_ratio), số ca từ chối sang cho phép (nới quyền), 20 ví dụ tiêu biểu trong summary. Mẫu đã che, không dữ liệu cá nhân (SEC-32, SEC-37). Giữ 12 tháng (NFR-12-030); sau khi DONE hoặc FAILED không sửa được.';
COMMENT ON COLUMN ph12_iam.policy_dryrun_report.change_threshold IS 'Ngưỡng 12.policy.dryrun.change-threshold tại thời điểm chạy (0,05…0,5, mặc định 0,2); vượt ngưỡng hoặc có deny_to_allow_count > 0 thì duyệt cần xác nhận bổ sung (BR-12-011).';
COMMENT ON COLUMN ph12_iam.policy_dryrun_report.small_sample IS 'Mẫu dưới 100 yêu cầu: báo "mẫu quá ít" nhưng vẫn cho gửi duyệt.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.policy_dryrun_report CASCADE;

-- @changeset ph12-0850-fn-policy splitStatements:false
-- Băm nội dung do CSDL tính để không ai gắn kết quả kiểm thử vào băm khác. Tên trigger băm bắt đầu bằng
-- "0hash" để chạy trước tg_policy_version_guard (trigger BEFORE chạy theo thứ tự tên).
CREATE OR REPLACE FUNCTION ph12_iam.tg_policy_version_hash() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.content_hash := encode(sha256(convert_to(NEW.content, 'UTF8')), 'hex');
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_policy_version_0hash BEFORE INSERT OR UPDATE OF content ON ph12_iam.policy_version
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_policy_version_hash();

CREATE OR REPLACE FUNCTION ph12_iam.tg_dryrun_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.status <> 'RUNNING' AND OLD.purge_after > now() THEN
      RAISE EXCEPTION 'Báo cáo chạy khô còn trong hạn lưu giữ 12 tháng, chưa xóa được' USING ERRCODE = 'P1299';
    END IF;
    RETURN OLD;
  END IF;
  IF OLD.status <> 'RUNNING' THEN
    RAISE EXCEPTION 'Báo cáo chạy khô đã kết thúc, không sửa được' USING ERRCODE = 'P1299';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_policy_dryrun_report_frozen BEFORE UPDATE OR DELETE ON ph12_iam.policy_dryrun_report
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_dryrun_frozen();

-- Máy trạng thái và điều kiện chuyển (FRS §4.5, SDD §8.1, ADR-069).
CREATE OR REPLACE FUNCTION ph12_iam.tg_policy_version_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  ok boolean;
  rep record;
  is_root boolean;
BEGIN
  IF NEW.content IS DISTINCT FROM OLD.content AND OLD.state NOT IN ('DRAFT', 'CHANGES_REQUESTED') THEN
    RAISE EXCEPTION 'Phiên bản % đã gửi duyệt, không sửa được nội dung', OLD.id USING ERRCODE = 'P1227';
  END IF;
  IF NEW.state = OLD.state THEN RETURN NEW; END IF;

  ok := (OLD.state, NEW.state) IN (
    ('DRAFT', 'PENDING_REVIEW'), ('DRAFT', 'DISCARDED'),
    ('PENDING_REVIEW', 'CHANGES_REQUESTED'), ('PENDING_REVIEW', 'APPROVED'),
    ('CHANGES_REQUESTED', 'DRAFT'),
    ('APPROVED', 'PUBLISHED'),
    ('PUBLISHED', 'SUPERSEDED'), ('PUBLISHED', 'REVOKED'));
  IF NOT ok THEN
    RAISE EXCEPTION 'Chuyển trạng thái phiên bản chính sách % sang % không hợp lệ', OLD.state, NEW.state USING ERRCODE = 'P1227';
  END IF;

  IF NEW.state = 'PENDING_REVIEW' THEN
    IF NOT EXISTS (SELECT 1 FROM ph12_iam.policy_test_run r
                    WHERE r.version_id = NEW.id AND r.tenant_id = NEW.tenant_id AND r.content_hash = NEW.content_hash AND r.passed) THEN
      RAISE EXCEPTION 'Chưa có kết quả kiểm thử đạt trên đúng nội dung hiện tại (BR-12-009)' USING ERRCODE = 'P1225';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ph12_iam.policy_dryrun_report d
                    WHERE d.version_id = NEW.id AND d.tenant_id = NEW.tenant_id AND d.content_hash = NEW.content_hash AND d.status = 'DONE') THEN
      RAISE EXCEPTION 'Chưa chạy khô trên đúng nội dung hiện tại (BR-12-009)' USING ERRCODE = 'P1226';
    END IF;
  END IF;

  IF NEW.state = 'APPROVED' THEN
    IF EXISTS (SELECT 1 FROM ph12_iam.policy_version_contributor c WHERE c.version_id = NEW.id AND c.tenant_id = NEW.tenant_id AND c.user_ref = NEW.approved_by) THEN
      RAISE EXCEPTION 'Người duyệt là người đóng góp của phiên bản (bốn mắt, BR-12-008)' USING ERRCODE = 'P1208';
    END IF;
    SELECT d.changed_ratio AS ratio, d.change_threshold AS thr, d.deny_to_allow_count AS d2a INTO rep
      FROM ph12_iam.policy_dryrun_report d
     WHERE d.version_id = NEW.id AND d.tenant_id = NEW.tenant_id AND d.content_hash = NEW.content_hash AND d.status = 'DONE'
     ORDER BY d.finished_at DESC LIMIT 1;
    IF FOUND AND (rep.ratio > rep.thr OR rep.d2a > 0) AND NOT NEW.high_impact_confirmed THEN
      RAISE EXCEPTION 'Chạy khô đổi quá ngưỡng hoặc có nới quyền: cần xác nhận bổ sung (BR-12-011)' USING ERRCODE = 'P1229';
    END IF;
  END IF;

  IF NEW.state = 'REVOKED' THEN
    SELECT p.is_root INTO is_root FROM ph12_iam.policy p WHERE p.id = NEW.policy_id AND p.tenant_id = NEW.tenant_id;
    IF is_root THEN
      RAISE EXCEPTION 'Không thu hồi được chính sách gốc' USING ERRCODE = 'P1227';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_policy_version_guard BEFORE UPDATE ON ph12_iam.policy_version
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_policy_version_guard();
COMMENT ON FUNCTION ph12_iam.tg_policy_version_guard() IS 'Chốt máy trạng thái phiên bản chính sách (ERR-12-027), điều kiện gửi duyệt (ERR-12-025, 026), bốn mắt với người đóng góp (ERR-12-008), xác nhận tác động lớn (ERR-12-029), cấm thu hồi chính sách gốc. Bản kiểm bundleRevision và xác thực mức 3 của người duyệt do dịch vụ làm.';
-- @rollback DROP TRIGGER IF EXISTS tg_policy_version_guard ON ph12_iam.policy_version; DROP TRIGGER IF EXISTS tg_policy_dryrun_report_frozen ON ph12_iam.policy_dryrun_report; DROP TRIGGER IF EXISTS tg_policy_version_0hash ON ph12_iam.policy_version; DROP FUNCTION IF EXISTS ph12_iam.tg_policy_version_guard(); DROP FUNCTION IF EXISTS ph12_iam.tg_dryrun_frozen(); DROP FUNCTION IF EXISTS ph12_iam.tg_policy_version_hash();

-- @file 12-0090-bundle.sql
-- @changeset ph12-0900-bundle-release
CREATE TABLE ph12_iam.bundle_release (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  bundle_kind      varchar(8)    NOT NULL,
  bundle_revision  varchar(64)   NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'BUILDING',
  digest           char(64),
  data_digest      char(64),
  size_bytes       bigint,
  policy_versions  jsonb         NOT NULL DEFAULT '[]',
  signing_kid      varchar(128),
  signed_at        timestamptz,
  object_key       varchar(512),
  published_at     timestamptz,
  rollback_of      uuid,
  failure_code     varchar(16),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_bundle_release PRIMARY KEY (id),
  CONSTRAINT uq_bundle_release_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_bundle_release_revision UNIQUE (tenant_id, bundle_revision),
  CONSTRAINT fk_bundle_release_rollback FOREIGN KEY (rollback_of, tenant_id) REFERENCES ph12_iam.bundle_release (id, tenant_id),
  CONSTRAINT ck_bundle_release_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_bundle_release_kind CHECK (bundle_kind IN ('PLATFORM', 'TENANT') AND (bundle_kind = 'PLATFORM') = (tenant_id = 'PLATFORM')),
  CONSTRAINT ck_bundle_release_revision CHECK (bundle_revision ~ '^[a-z0-9]+-[0-9]{8}-[0-9]{4,}$' AND split_part(bundle_revision, '-', 1) = lower(tenant_id)),
  CONSTRAINT ck_bundle_release_state CHECK (state IN ('BUILDING', 'SIGNED', 'PUBLISHED', 'SUPERSEDED', 'FAILED')),
  CONSTRAINT ck_bundle_release_digest CHECK ((digest IS NULL OR digest ~ '^[0-9a-f]{64}$') AND (data_digest IS NULL OR data_digest ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_bundle_release_size CHECK (size_bytes IS NULL OR size_bytes BETWEEN 1 AND 209715200),
  CONSTRAINT ck_bundle_release_signed CHECK (state IN ('BUILDING', 'FAILED') OR (digest IS NOT NULL AND signed_at IS NOT NULL AND signing_kid IS NOT NULL AND object_key IS NOT NULL)),
  CONSTRAINT ck_bundle_release_published CHECK (state NOT IN ('PUBLISHED', 'SUPERSEDED') OR published_at IS NOT NULL),
  CONSTRAINT ck_bundle_release_failed CHECK ((state = 'FAILED') = (failure_code IS NOT NULL)),
  CONSTRAINT ck_bundle_release_versions CHECK (jsonb_typeof(policy_versions) = 'array')
);
CREATE UNIQUE INDEX uq_bundle_release_published ON ph12_iam.bundle_release (tenant_id) WHERE state = 'PUBLISHED';
CREATE INDEX ix_bundle_release_digest ON ph12_iam.bundle_release (tenant_id, digest);
CREATE INDEX ix_bundle_release_state ON ph12_iam.bundle_release (tenant_id, state, created_at DESC);
CREATE TRIGGER tg_bundle_release_touch BEFORE UPDATE ON ph12_iam.bundle_release FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CREATE TRIGGER tg_bundle_release_no_delete BEFORE DELETE ON ph12_iam.bundle_release FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_no_delete();
CALL ph12_iam.p_enable_rls('ph12_iam.bundle_release', 'P');
COMMENT ON TABLE ph12_iam.bundle_release IS 'EN-12-14 Bản phát hành gói chính sách và dữ liệu cho OPA (FR-12-051, 054, 055). Hai loại: PLATFORM (Rego gốc, permissions, grants; tenant_id = PLATFORM) và TENANT (Rego riêng của tỉnh, assignments, org_tree, client_scopes, tenant_state; tenant_id = tỉnh). Mỗi tenant đúng một PUBLISHED. Quay lui dựng bản MỚI có revision mới với nội dung bản cũ (rollback_of), giữ chuỗi revision đơn điệu. Không xóa vật lý; thân gói ở bucket dh-platform-policy.';
COMMENT ON COLUMN ph12_iam.bundle_release.bundle_revision IS 'Dạng {tenant viết thường}-{yyyyMMdd}-{số thứ tự}, ví dụ t68-20261126-0153, platform-20261126-0007; nằm trong .manifest và đi vào mọi quyết định (khóa đệm của PEP).';
COMMENT ON COLUMN ph12_iam.bundle_release.digest IS 'SHA-256 hex của gói đã đóng (dựng tất định, cùng dữ liệu cùng băm); BundleBuilder bỏ qua phát hành khi không đổi.';
COMMENT ON COLUMN ph12_iam.bundle_release.size_bytes IS 'Kích thước gói; trần cứng 200 MiB của kho, ngưỡng cảnh báo 20 MiB (dh.iam.bundle.max-size) thì chia theo đơn vị.';
COMMENT ON COLUMN ph12_iam.bundle_release.signing_kid IS 'Mã khóa ký transit/sign/dh-policy-signing; OPA kiểm bằng khóa công khai trong cấu hình (SEC-36).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.bundle_release CASCADE;

-- @changeset ph12-0910-bundle-ack
CREATE TABLE ph12_iam.bundle_ack (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  release_id       uuid          NOT NULL,
  node_id          varchar(128)  NOT NULL,
  active_revision  varchar(64)   NOT NULL,
  acked_at         timestamptz   NOT NULL DEFAULT now(),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_bundle_ack PRIMARY KEY (id),
  CONSTRAINT uq_bundle_ack UNIQUE (release_id, node_id),
  CONSTRAINT fk_bundle_ack_release FOREIGN KEY (release_id, tenant_id) REFERENCES ph12_iam.bundle_release (id, tenant_id),
  CONSTRAINT ck_bundle_ack_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$')
);
CREATE INDEX ix_bundle_ack_time ON ph12_iam.bundle_ack (acked_at);
CALL ph12_iam.p_enable_rls('ph12_iam.bundle_ack', 'P');
ALTER TABLE ph12_iam.bundle_ack SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
COMMENT ON TABLE ph12_iam.bundle_ack IS 'Nút OPA đã nạp bản phát hành nào (plugin status của OPA, danh tính mTLS của pod). Cơ sở của chỉ số iam_policy_reload_seconds, tiến độ "n/m nút" và điều kiện APPROVED sang PUBLISHED (OPA đầu tiên xác nhận). Giữ 30 ngày. Bộ tiếp nhận ghi theo từng tenant của gói, không ghi chéo.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.bundle_ack CASCADE;
