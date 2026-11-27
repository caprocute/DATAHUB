-- =============================================================================
-- D03-03-PH02 · Tệp 20: kiểm tra đặc tả, backend, gói sử dụng
-- Chạy sau ph02_10_catalog.sql (cùng phiên, đang SET ROLE ph02_owner).
-- =============================================================================

-- @file 02-0020-lint-backend-plan.sql
-- @changeset ph02-0200-lint-rule
CREATE TABLE ph02_catalog.lint_rule (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  rule_id          varchar(16)   NOT NULL,
  layer            varchar(10)   NOT NULL,
  default_severity varchar(7)    NOT NULL,
  adjust_policy    varchar(10)   NOT NULL DEFAULT 'NONE',
  adjustable       boolean       GENERATED ALWAYS AS (adjust_policy <> 'NONE') STORED,
  title            varchar(500)  NOT NULL,
  hint             varchar(1000),
  pattern          text,
  enabled          boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_lint_rule PRIMARY KEY (id),
  CONSTRAINT uq_lint_rule_id UNIQUE (rule_id),
  CONSTRAINT ck_lint_rule_common CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_lint_rule_code CHECK (rule_id ~ '^(LINT|SCAN)-02-[0-9]{2}$'),
  CONSTRAINT ck_lint_rule_layer CHECK (layer IN ('STANDARD', 'CONVENTION', 'SECRET')),
  CONSTRAINT ck_lint_rule_layer_code CHECK ((layer = 'SECRET') = (rule_id LIKE 'SCAN-%')),
  CONSTRAINT ck_lint_rule_severity CHECK (default_severity IN ('ERROR', 'WARNING', 'INFO')),
  CONSTRAINT ck_lint_rule_policy CHECK (adjust_policy IN ('NONE', 'RAISE', 'LOWER_LANG')),
  CONSTRAINT ck_lint_rule_secret_fixed CHECK (layer <> 'SECRET' OR (default_severity = 'ERROR' AND adjust_policy = 'NONE' AND pattern IS NOT NULL))
);
CREATE TRIGGER tg_lint_rule_touch BEFORE UPDATE ON ph02_catalog.lint_rule FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.lint_rule', 'S');
COMMENT ON TABLE ph02_catalog.lint_rule IS 'EN-02-13 Bộ luật kiểm tra đặc tả: 15 luật quy ước LINT-02-01…15 (lớp 2) và 9 mẫu quét bí mật SCAN-02-01…09 (FR-02-017, 018, 021). Dùng chung toàn nền tảng (tenant COMMON, mẫu S): tỉnh đọc, không ghi; PA ghi phiên PLATFORM. Mẫu quét bí mật chỉ đọc và không hạ mức (UI-02-15).';
COMMENT ON COLUMN ph02_catalog.lint_rule.adjust_policy IS 'NONE: luật cấu trúc, không chỉnh ở tenant; RAISE: tenant chỉ nâng WARNING thành ERROR; LOWER_LANG: riêng LINT-02-02, tenant hạ phần cảnh báo ngôn ngữ (FRS ghi chú FR-02-021).';
COMMENT ON COLUMN ph02_catalog.lint_rule.pattern IS 'Biểu thức quét của mẫu SCAN; bắt buộc cho lớp SECRET. Chỉ đọc qua giao diện, thay đổi qua bản phát hành sau duyệt của Cán bộ ATTT (Q02-11).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.lint_rule CASCADE;

-- @changeset ph02-0210-lint-rule-override
CREATE TABLE ph02_catalog.lint_rule_override (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  rule_id          varchar(16)   NOT NULL,
  severity         varchar(7)    NOT NULL,
  reason           varchar(1000) NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_lint_rule_override PRIMARY KEY (id),
  CONSTRAINT uq_lint_rule_override UNIQUE (tenant_id, rule_id),
  CONSTRAINT fk_lint_rule_override_rule FOREIGN KEY (rule_id) REFERENCES ph02_catalog.lint_rule (rule_id),
  CONSTRAINT ck_lint_rule_override_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_lint_rule_override_severity CHECK (severity IN ('ERROR', 'WARNING', 'INFO')),
  CONSTRAINT ck_lint_rule_override_reason CHECK (length(btrim(reason)) > 0)
);
CREATE TRIGGER tg_lint_rule_override_touch BEFORE UPDATE ON ph02_catalog.lint_rule_override FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.lint_rule_override', 'P');
COMMENT ON TABLE ph02_catalog.lint_rule_override IS 'Mức hiệu lực của luật theo tenant (FR-02-021). Chỉ ghi được cho luật có adjust_policy khác NONE và đúng chiều cho phép (trigger tg_lint_rule_override_policy); ghi kiểm toán giá trị trước, sau ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.lint_rule_override CASCADE;

-- @changeset ph02-0211-lint-rule-override-policy splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_lint_rule_override_policy() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  r ph02_catalog.lint_rule%ROWTYPE;
BEGIN
  SELECT * INTO r FROM ph02_catalog.lint_rule WHERE rule_id = NEW.rule_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Luật % không tồn tại', NEW.rule_id USING ERRCODE = '23503';
  END IF;
  IF r.adjust_policy = 'NONE' THEN
    RAISE EXCEPTION 'Luật % là luật cấu trúc, không chỉnh mức ở tenant (FR-02-021)', NEW.rule_id USING ERRCODE = '23514';
  END IF;
  IF r.adjust_policy = 'RAISE' AND NEW.severity <> 'ERROR' THEN
    RAISE EXCEPTION 'Luật % chỉ được nâng lên ERROR ở tenant', NEW.rule_id USING ERRCODE = '23514';
  END IF;
  IF r.adjust_policy = 'LOWER_LANG' AND NEW.severity = 'INFO' THEN
    RAISE EXCEPTION 'Luật % chỉ được đặt ERROR hoặc WARNING', NEW.rule_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_lint_rule_override_policy BEFORE INSERT OR UPDATE OF severity, rule_id ON ph02_catalog.lint_rule_override FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_lint_rule_override_policy();
-- @rollback DROP TRIGGER IF EXISTS tg_lint_rule_override_policy ON ph02_catalog.lint_rule_override; DROP FUNCTION IF EXISTS ph02_catalog.tg_lint_rule_override_policy();

-- @changeset ph02-0220-lint-finding
CREATE TABLE ph02_catalog.lint_finding (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  spec_id          uuid          NOT NULL,
  run_id           uuid          NOT NULL,
  layer            varchar(10)   NOT NULL,
  severity         varchar(7)    NOT NULL,
  rule_id          varchar(16)   NOT NULL,
  location         varchar(512),
  message          varchar(1000) NOT NULL,
  hint             varchar(1000),
  fingerprint      char(16),
  status           varchar(12)   NOT NULL DEFAULT 'OPEN',
  acknowledged_by  varchar(64),
  acknowledged_at  timestamptz,
  acknowledge_reason varchar(1000),
  dispute_requested boolean     NOT NULL DEFAULT false,
  dispute_reason   varchar(1000),
  dispute_requested_by varchar(64),
  checked_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_lint_finding PRIMARY KEY (id, checked_at),
  CONSTRAINT fk_lint_finding_spec FOREIGN KEY (spec_id, tenant_id) REFERENCES ph02_catalog.api_spec (id, tenant_id),
  CONSTRAINT ck_lint_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_lint_finding_layer CHECK (layer IN ('STANDARD', 'CONVENTION', 'SECRET')),
  CONSTRAINT ck_lint_finding_severity CHECK (severity IN ('ERROR', 'WARNING', 'INFO')),
  CONSTRAINT ck_lint_finding_status CHECK (status IN ('OPEN', 'RESOLVED', 'ACKNOWLEDGED')),
  CONSTRAINT ck_lint_finding_secret CHECK (layer <> 'SECRET' OR (severity = 'ERROR' AND fingerprint IS NOT NULL)),
  CONSTRAINT ck_lint_finding_ack CHECK ((status = 'ACKNOWLEDGED') = (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL AND length(btrim(coalesce(acknowledge_reason, ''))) > 0)),
  CONSTRAINT ck_lint_finding_dispute CHECK (dispute_requested = (dispute_requested_by IS NOT NULL AND length(btrim(coalesce(dispute_reason, ''))) > 0)),
  CONSTRAINT ck_lint_finding_fingerprint CHECK (fingerprint IS NULL OR fingerprint ~ '^[0-9a-f]{16}$')
) PARTITION BY RANGE (checked_at);
CREATE INDEX ix_lint_finding_spec ON ph02_catalog.lint_finding (tenant_id, spec_id, severity) WHERE status = 'OPEN';
CREATE INDEX ix_lint_finding_version ON ph02_catalog.lint_finding (tenant_id, api_version_id, checked_at DESC);
CREATE INDEX ix_lint_finding_run ON ph02_catalog.lint_finding (tenant_id, run_id);
CALL ph02_catalog.p_enable_rls('ph02_catalog.lint_finding', 'P');
CALL ph02_catalog.p_ensure_month_partitions('ph02_catalog.lint_finding', now()::date, 4);
COMMENT ON TABLE ph02_catalog.lint_finding IS 'EN-02-04 Phát hiện của một lần kiểm tra đặc tả persist: lớp, mức, mã luật, vị trí, hướng dẫn (FR-02-016…018). KHÔNG lưu chuỗi khớp của bộ quét bí mật, chỉ dấu vân tay 16 ký tự hex của băm có muối (NFR-02-012, FR-02-018). Phân vùng tháng theo checked_at, giữ 1 năm (NFR-02-017). Chế độ PREVIEW không ghi gì.';
COMMENT ON COLUMN ph02_catalog.lint_finding.fingerprint IS 'Dấu vân tay (16 ký tự đầu của HMAC-SHA256 có muối theo tenant) của chuỗi khớp, để nhận ra cùng một bí mật ở lần quét sau mà không giữ giá trị.';
COMMENT ON COLUMN ph02_catalog.lint_finding.dispute_requested IS 'Người dùng đề nghị coi phát hiện là "không phải bí mật" (API-02-093); phát hiện vẫn OPEN và vẫn chặn gửi duyệt cho tới khi SO xác nhận ở API-02-094.';
COMMENT ON COLUMN ph02_catalog.lint_finding.dispute_reason IS 'Lý do đề nghị không phải bí mật (API-02-093); bắt buộc khi dispute_requested = true.';
COMMENT ON COLUMN ph02_catalog.lint_finding.dispute_requested_by IS 'Người gửi đề nghị không phải bí mật (API-02-093).';
COMMENT ON COLUMN ph02_catalog.lint_finding.status IS 'OPEN, RESOLVED (lần quét sau không còn), ACKNOWLEDGED (người dùng xác nhận không phải bí mật, ghi người và lý do; SECRET cần TA, kiểm ở dịch vụ).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.lint_finding CASCADE;

-- @changeset ph02-0230-backend
CREATE TABLE ph02_catalog.backend (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  backend_code     varchar(32)   NOT NULL,
  kind             varchar(6)    NOT NULL,
  target_ref       jsonb         NOT NULL,
  weight           smallint      NOT NULL DEFAULT 100,
  timeout_ms       integer       NOT NULL DEFAULT 10000,
  retries          smallint      NOT NULL DEFAULT 0,
  lb_type          varchar(12)   NOT NULL DEFAULT 'roundrobin',
  health_check     jsonb         NOT NULL DEFAULT '{}',
  status           varchar(11)   NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_backend PRIMARY KEY (id),
  CONSTRAINT uq_backend_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_backend_code UNIQUE (api_version_id, backend_code),
  CONSTRAINT fk_backend_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_backend_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_backend_code CHECK (backend_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_backend_kind CHECK (kind IN ('SYSTEM', 'FLOW')),
  CONSTRAINT ck_backend_target_shape CHECK (jsonb_typeof(target_ref) = 'object'
    AND ((kind = 'SYSTEM' AND target_ref ?& ARRAY['connectionCode', 'basePath'])
      OR (kind = 'FLOW' AND target_ref ?& ARRAY['flowCode', 'environment']))),
  CONSTRAINT ck_backend_no_free_url CHECK (NOT (target_ref ?| ARRAY['url', 'uri', 'host', 'address', 'ip'])),
  CONSTRAINT ck_backend_weight CHECK (weight BETWEEN 0 AND 100),
  CONSTRAINT ck_backend_timeout CHECK (timeout_ms BETWEEN 100 AND 120000),
  CONSTRAINT ck_backend_retries CHECK (retries BETWEEN 0 AND 3),
  CONSTRAINT ck_backend_lb CHECK (lb_type IN ('roundrobin', 'chash')),
  CONSTRAINT ck_backend_status CHECK (status IN ('PLACEHOLDER', 'ACTIVE', 'DISABLED')),
  CONSTRAINT ck_backend_placeholder CHECK (status <> 'PLACEHOLDER' OR kind = 'FLOW'),
  CONSTRAINT ck_backend_health CHECK (jsonb_typeof(health_check) = 'object')
);
CREATE INDEX ix_backend_version ON ph02_catalog.backend (tenant_id, api_version_id, status);
CREATE INDEX ix_backend_flow ON ph02_catalog.backend ((target_ref ->> 'flowCode')) WHERE kind = 'FLOW';
CREATE INDEX ix_backend_connection ON ph02_catalog.backend ((target_ref ->> 'connectionCode')) WHERE kind = 'SYSTEM';
CREATE TRIGGER tg_backend_touch BEFORE UPDATE ON ph02_catalog.backend FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.backend', 'P');
COMMENT ON TABLE ph02_catalog.backend IS 'EN-02-05 Backend của phiên bản (FR-02-022…025). Không có trường URL tự do: SYSTEM trỏ kết nối PH-05 {connectionCode, basePath}, FLOW trỏ luồng PH-04 {flowCode, environment}; nhờ vậy BR-02-023 (đích trong danh sách cho phép, TLS ≥ 1.2, không địa chỉ nội bộ) đúng theo cấu trúc (CHECK ck_backend_no_free_url). Tổng trọng số > 0 và tối thiểu một backend ACTIVE kiểm ở SubmissionGate (BR-02-024).';
COMMENT ON COLUMN ph02_catalog.backend.status IS 'PLACEHOLDER: khung luồng đã sinh ở PH-04 nhưng luồng chưa phát hành, chưa tính ACTIVE; chuyển ACTIVE khi nhận EVT-04-07 (FR-02-026).';
COMMENT ON COLUMN ph02_catalog.backend.timeout_ms IS 'Trần cứng 120.000 ms; trần theo tenant 02.backend.max-timeout-ms (mặc định 60.000) kiểm ở TargetPolicy.';
COMMENT ON COLUMN ph02_catalog.backend.health_check IS 'Kiểm tra sức khỏe chủ động và ngắt thụ động: {path, intervalSeconds, healthy, unhealthy}; PH-03 dịch sang cấu hình APISIX.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.backend CASCADE;

-- @changeset ph02-0240-plan
CREATE TABLE ph02_catalog.plan (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  plan_code        varchar(32)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  status           varchar(10)   NOT NULL DEFAULT 'STAGING',
  auth_type        varchar(14)   NOT NULL,
  auth_rank        smallint      GENERATED ALWAYS AS (CASE auth_type WHEN 'KEYLESS' THEN 0 WHEN 'API_KEY' THEN 1 WHEN 'OAUTH2_SECRET' THEN 2 WHEN 'OAUTH2_PKJWT' THEN 3 ELSE 4 END) STORED,
  needs_auth_upgrade boolean     NOT NULL DEFAULT false,
  auto_approve     boolean       NOT NULL DEFAULT false,
  audience         jsonb         NOT NULL DEFAULT '{"mode":"ALL"}',
  limits           jsonb         NOT NULL DEFAULT '{}',
  unit_price_vnd   numeric(19,0) NOT NULL DEFAULT 0,
  cloned_from_plan_id uuid,
  published_at     timestamptz,
  closed_at        timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_plan PRIMARY KEY (id),
  CONSTRAINT uq_plan_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_plan_id_version UNIQUE (id, api_version_id, tenant_id),
  CONSTRAINT uq_plan_code UNIQUE (api_version_id, plan_code),
  CONSTRAINT fk_plan_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT fk_plan_cloned FOREIGN KEY (cloned_from_plan_id, tenant_id) REFERENCES ph02_catalog.plan (id, tenant_id),
  CONSTRAINT ck_plan_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_plan_code CHECK (plan_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_plan_status CHECK (status IN ('STAGING', 'PUBLISHED', 'DEPRECATED', 'CLOSED')),
  CONSTRAINT ck_plan_auth CHECK (auth_type IN ('KEYLESS', 'API_KEY', 'OAUTH2_SECRET', 'OAUTH2_PKJWT', 'OAUTH2_MTLS')),
  CONSTRAINT ck_plan_audience CHECK (jsonb_typeof(audience) = 'object'),
  CONSTRAINT ck_plan_limits CHECK (jsonb_typeof(limits) = 'object'),
  CONSTRAINT ck_plan_price CHECK (unit_price_vnd >= 0),
  CONSTRAINT ck_plan_published CHECK (status = 'STAGING' OR status = 'CLOSED' OR published_at IS NOT NULL),
  CONSTRAINT ck_plan_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL))
);
CREATE INDEX ix_plan_version ON ph02_catalog.plan (tenant_id, api_version_id, status);
CREATE INDEX ix_plan_needs_upgrade ON ph02_catalog.plan (tenant_id) WHERE needs_auth_upgrade;
CREATE TRIGGER tg_plan_touch BEFORE UPDATE ON ph02_catalog.plan FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.plan', 'P');
COMMENT ON TABLE ph02_catalog.plan IS 'EN-02-06 Gói sử dụng (Plan) của phiên bản: kiểu xác thực, hạn mức, đối tượng được xin, tự duyệt (FR-02-027…033). Bốn trạng thái STAGING, PUBLISHED, DEPRECATED, CLOSED giữ từ hệ cũ (LGC-APIM-009). Kiểu xác thực tối thiểu theo mức phân loại được chốt ở trigger tg_plan_auth_policy (BR-02-016, SEC-24).';
COMMENT ON COLUMN ph02_catalog.plan.auth_type IS 'KEYLESS, API_KEY, OAUTH2_SECRET, OAUTH2_PKJWT, OAUTH2_MTLS. KEYLESS chỉ với dữ liệu và mức hiển thị PUBLIC; RESTRICTED chỉ PKJWT hoặc MTLS; SENSITIVE chỉ MTLS.';
COMMENT ON COLUMN ph02_catalog.plan.auth_rank IS 'Hạng số của auth_type (0…4), cột sinh tự động, so với hạng yêu cầu tối thiểu của api.data_class_rank.';
COMMENT ON COLUMN ph02_catalog.plan.needs_auth_upgrade IS 'Gói không còn hợp lệ sau khi API nâng mức phân loại, hoặc gói nhập từ hệ cũ vi phạm: đánh dấu "Cần nâng xác thực" thay vì chặn nhập; chặn gửi duyệt cho tới khi sửa (SDD 4.6).';
COMMENT ON COLUMN ph02_catalog.plan.audience IS 'Điều kiện đăng ký: {"mode":"ALL"} hoặc {"mode":"GROUPS","groups":[mã nhóm HTTT ở PH-01]} (ERR-02-028).';
COMMENT ON COLUMN ph02_catalog.plan.limits IS 'Hạn mức: {perSecond, perMinute, perHour, perDay, burst, concurrent}; PH-03 thực thi. Hạ hạn mức ở gói PUBLISHED là thay đổi không tương thích (BR-02-017).';
COMMENT ON COLUMN ph02_catalog.plan.unit_price_vnd IS 'T-MONEY, chỉ là thông tin hiển thị, mặc định 0; mọi việc thu phí thuộc PH-19 (BR-02-040, Q02-09).';
COMMENT ON COLUMN ph02_catalog.plan.cloned_from_plan_id IS 'Gói nguồn khi sao chép sang phiên bản mới (FR-02-033); mã gói giữ nguyên để BR-02-035 kiểm được bằng mã.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.plan CASCADE;

-- @changeset ph02-0241-plan-auth-policy splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_plan_auth_policy() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_rank smallint;
  v_vis  varchar(8);
  v_need smallint;
  v_auth smallint;
BEGIN
  IF NEW.needs_auth_upgrade OR NEW.status IN ('DEPRECATED', 'CLOSED') THEN
    RETURN NEW;
  END IF;
  SELECT a.data_class_rank, a.visibility INTO v_rank, v_vis
    FROM ph02_catalog.api_version v
    JOIN ph02_catalog.api a ON a.id = v.api_id AND a.tenant_id = v.tenant_id
   WHERE v.id = NEW.api_version_id AND v.tenant_id = NEW.tenant_id;
  IF NOT FOUND THEN
    RETURN NEW;  -- khóa ngoại báo lỗi
  END IF;
  v_need := CASE v_rank WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 2 THEN 3 ELSE 4 END;
  -- Cột sinh auth_rank chưa có giá trị trong trigger BEFORE: tính lại từ auth_type
  v_auth := CASE NEW.auth_type WHEN 'KEYLESS' THEN 0 WHEN 'API_KEY' THEN 1 WHEN 'OAUTH2_SECRET' THEN 2 WHEN 'OAUTH2_PKJWT' THEN 3 ELSE 4 END;
  IF v_auth < v_need THEN
    RAISE EXCEPTION 'Kiểu xác thực % yếu hơn mức tối thiểu của mức phân loại dữ liệu (BR-02-016, ERR-02-022)', NEW.auth_type USING ERRCODE = '23514';
  END IF;
  IF NEW.auth_type = 'KEYLESS' AND v_vis <> 'PUBLIC' THEN
    RAISE EXCEPTION 'KEYLESS chỉ với API có mức hiển thị PUBLIC (BR-02-016, ERR-02-022)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_plan_auth_policy BEFORE INSERT OR UPDATE OF auth_type, needs_auth_upgrade, status ON ph02_catalog.plan FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_plan_auth_policy();
COMMENT ON FUNCTION ph02_catalog.tg_plan_auth_policy() IS 'Chốt chặn BR-02-016: so hạng của auth_type (cùng công thức với cột sinh plan.auth_rank) với hạng tối thiểu theo api.data_class_rank (0→KEYLESS, 1→API_KEY, 2→PKJWT, 3→MTLS); bỏ qua gói đã đánh dấu needs_auth_upgrade và gói DEPRECATED, CLOSED. Tác vụ đêm kiểm lại khi API đổi mức phân loại.';
-- @rollback DROP TRIGGER IF EXISTS tg_plan_auth_policy ON ph02_catalog.plan; DROP FUNCTION IF EXISTS ph02_catalog.tg_plan_auth_policy();

-- @changeset ph02-0250-plan-operation-scope
CREATE TABLE ph02_catalog.plan_operation_scope (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  plan_id          uuid          NOT NULL,
  operation_id     varchar(128)  NOT NULL,
  limits           jsonb,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_plan_operation_scope PRIMARY KEY (id),
  CONSTRAINT uq_plan_operation_scope UNIQUE (plan_id, operation_id),
  CONSTRAINT fk_plan_operation_scope_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph02_catalog.plan (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_plan_operation_scope_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_plan_operation_scope_limits CHECK (limits IS NULL OR jsonb_typeof(limits) = 'object')
);
CALL ph02_catalog.p_enable_rls('ph02_catalog.plan_operation_scope', 'P');
COMMENT ON TABLE ph02_catalog.plan_operation_scope IS 'Thao tác cho phép của gói và hạn mức riêng từng thao tác (FR-02-029). Không có dòng thì gói cho phép mọi thao tác. operation_id là khóa chuỗi, không khóa ngoại, vì đặc tả đổi khi DRAFT; thao tác không có trong đặc tả bị từ chối ở dịch vụ (ERR-02-037).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.plan_operation_scope CASCADE;
