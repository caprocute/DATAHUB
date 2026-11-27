--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0020-param.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0120-param-namespace splitStatements:false
CREATE TABLE ph18_ops.param_namespace (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  code              varchar(32) NOT NULL,
  owner_module      varchar(8) NOT NULL,
  title             varchar(255) NOT NULL,
  description       text,
  approval_owner    varchar(8) NOT NULL DEFAULT 'PH18',
  cache_ttl_seconds integer NOT NULL DEFAULT 60,
  status            varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_namespace PRIMARY KEY (id),
  CONSTRAINT uq_param_namespace_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_namespace_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT uq_param_namespace_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_param_namespace_code CHECK (code ~ '^[a-z0-9]+(\.[a-z0-9-]+)*$' AND code <> '19'),
  CONSTRAINT ck_param_namespace_owner CHECK (owner_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_param_namespace_approval CHECK (approval_owner ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_param_namespace_ttl CHECK (cache_ttl_seconds BETWEEN 1 AND 60),
  CONSTRAINT ck_param_namespace_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_param_namespace_touch BEFORE UPDATE ON ph18_ops.param_namespace FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_namespace_immutable BEFORE UPDATE ON ph18_ops.param_namespace FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('code');
CALL ph18_ops.p_enable_rls('ph18_ops.param_namespace', true);
COMMENT ON TABLE ph18_ops.param_namespace IS 'EN-18-01 Không gian tên tham số do từng PH đăng ký khi khởi động (onboarding, 00, 02, 04, 05, 07.rdm, 10, 12, 14, 15, 17, 18, 20, ff; mở cho 06, 08, 09, 11, 13, 16; 19 do PH-19 tự giữ). Chỉ dòng COMMON. approval_owner khác PH18 thì PH đó tự giữ bốn mắt (PH-14, PH-17).';
COMMENT ON COLUMN ph18_ops.param_namespace.cache_ttl_seconds IS 'Thời gian đệm tối đa ở PH đọc; trần 60 giây theo NFR-00-052 và CC-CFG-04.';
COMMENT ON COLUMN ph18_ops.param_namespace.approval_owner IS 'PH giữ quy trình bốn mắt cho tham số ★ của không gian tên này; mặc định PH18.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_namespace CASCADE;

--changeset ph18:ph18-0130-param-definition splitStatements:false
CREATE TABLE ph18_ops.param_definition (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  namespace_code   varchar(32) NOT NULL,
  param_key        varchar(128) NOT NULL,
  value_type       varchar(16) NOT NULL,
  default_value    jsonb NOT NULL,
  json_schema      jsonb NOT NULL DEFAULT '{}',
  min_value        numeric,
  max_value        numeric,
  allowed_values   jsonb,
  platform_ceiling jsonb,
  unit             varchar(16),
  level            varchar(8) NOT NULL DEFAULT 'TENANT',
  security_flag    boolean NOT NULL DEFAULT false,
  display_group    varchar(64),
  display_order    integer NOT NULL DEFAULT 100,
  label            varchar(255) NOT NULL,
  description      text,
  deprecated_at    timestamptz,
  removal_date     date,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_definition PRIMARY KEY (id),
  CONSTRAINT uq_param_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_definition_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT uq_param_definition_key UNIQUE (tenant_id, param_key),
  CONSTRAINT fk_param_definition_namespace FOREIGN KEY (tenant_id, namespace_code) REFERENCES ph18_ops.param_namespace (tenant_id, code),
  CONSTRAINT ck_param_definition_key CHECK (param_key ~ '^[a-z0-9]+(\.[A-Za-z0-9-]+)+$' AND left(param_key, char_length(namespace_code) + 1) = namespace_code || '.'),
  CONSTRAINT ck_param_definition_type CHECK (value_type IN ('BOOLEAN', 'INTEGER', 'DECIMAL', 'STRING', 'ENUM', 'DURATION', 'CRON', 'TIME_RANGE', 'JSON', 'LIST_STRING', 'LIST_HOST')),
  CONSTRAINT ck_param_definition_level CHECK (level IN ('PLATFORM', 'TENANT')),
  CONSTRAINT ck_param_definition_range CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
  CONSTRAINT ck_param_definition_allowed CHECK (allowed_values IS NULL OR jsonb_typeof(allowed_values) = 'array'),
  CONSTRAINT ck_param_definition_enum CHECK (value_type <> 'ENUM' OR allowed_values IS NOT NULL),
  CONSTRAINT ck_param_definition_removal CHECK (removal_date IS NULL OR deprecated_at IS NOT NULL)
);
CREATE INDEX ix_param_definition_group ON ph18_ops.param_definition (namespace_code, display_group, display_order);
CREATE TRIGGER tg_param_definition_touch BEFORE UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_definition_immutable BEFORE UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('param_key', 'namespace_code', 'value_type');
CREATE TRIGGER tg_param_definition_validate BEFORE INSERT OR UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_definition_check();
CALL ph18_ops.p_enable_rls('ph18_ops.param_definition', true);
COMMENT ON TABLE ph18_ops.param_definition IS 'EN-18-02 Lược đồ một khóa tham số (DD-14 schema): kiểu, mặc định, miền, trần nền tảng, mức PLATFORM hay TENANT, cờ bảo mật ★, nhóm hiển thị. Chỉ dòng COMMON; PH sở hữu đăng ký qua scope ops:param-register. Khóa có ngày gỡ thì vẫn đọc được tới removal_date.';
COMMENT ON COLUMN ph18_ops.param_definition.level IS 'PLATFORM: chỉ PA ghi giá trị (dòng COMMON), tenant chỉ đọc; TENANT: tenant ghi đè trong miền và trần.';
COMMENT ON COLUMN ph18_ops.param_definition.platform_ceiling IS 'Trần nền tảng: giá trị tenant không vượt (số: không lớn hơn; danh sách: là tập con).';
COMMENT ON COLUMN ph18_ops.param_definition.security_flag IS 'Tham số ★ bảo mật: đổi cần bốn mắt (param_change_request) do approval_owner của không gian tên giữ.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_definition CASCADE;

--changeset ph18:ph18-0140-param-change-request splitStatements:false
CREATE TABLE ph18_ops.param_change_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  definition_id         uuid NOT NULL,
  param_key             varchar(128) NOT NULL,
  proposed_value        jsonb NOT NULL,
  current_value         jsonb,
  reason                text NOT NULL,
  status                varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  requested_by          varchar(64) NOT NULL,
  requested_at          timestamptz NOT NULL DEFAULT now(),
  decided_by            varchar(64),
  decided_at            timestamptz,
  decision_note         varchar(1000),
  expires_at            timestamptz NOT NULL,
  approval_owner        varchar(8) NOT NULL DEFAULT 'PH18',
  external_approval_ref varchar(128),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_change_request PRIMARY KEY (id),
  CONSTRAINT uq_param_change_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_change_request_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_param_change_request_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT ck_param_change_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_param_change_request_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_param_change_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_param_change_request_decided CHECK (status IN ('PENDING_APPROVAL', 'EXPIRED', 'CANCELLED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL) OR external_approval_ref IS NOT NULL),
  CONSTRAINT ck_param_change_request_owner CHECK (approval_owner ~ '^PH[0-9]{2}$')
);
CREATE UNIQUE INDEX uq_param_change_request_pending ON ph18_ops.param_change_request (tenant_id, param_key) WHERE status = 'PENDING_APPROVAL';
CREATE INDEX ix_param_change_request_status ON ph18_ops.param_change_request (tenant_id, status, requested_at);
CREATE TRIGGER tg_param_change_request_touch BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_change_request_immutable BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'proposed_value', 'requested_by', 'reason');
CREATE TRIGGER tg_param_change_request_fsm_status BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,PENDING_APPROVAL>EXPIRED');
CREATE TRIGGER tg_param_change_request_value BEFORE INSERT ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_value_check('proposed_value');
CALL ph18_ops.p_enable_rls('ph18_ops.param_change_request', true);
COMMENT ON TABLE ph18_ops.param_change_request IS 'EN-18-05 Đề nghị đổi tham số ★ chờ duyệt bốn mắt: giá trị đề xuất, giá trị hiện tại, lý do; người duyệt khác người đề nghị. Mỗi khóa chỉ một đề nghị PENDING_APPROVAL mỗi tenant. PH tự giữ bốn mắt (PH-14, PH-17) ghi external_approval_ref thay cho duyệt ở PH-18.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_change_request CASCADE;

--changeset ph18:ph18-0150-param-value splitStatements:false
CREATE TABLE ph18_ops.param_value (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  definition_id      uuid NOT NULL,
  param_key          varchar(128) NOT NULL,
  value              jsonb NOT NULL,
  scope              varchar(8) NOT NULL,
  current_version_no integer NOT NULL DEFAULT 1,
  effective_from     timestamptz NOT NULL DEFAULT now(),
  source             varchar(16) NOT NULL DEFAULT 'UI',
  changed_reason     varchar(1000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_value PRIMARY KEY (id),
  CONSTRAINT uq_param_value_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_value_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_param_value_key UNIQUE (tenant_id, param_key),
  CONSTRAINT fk_param_value_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT ck_param_value_scope CHECK (scope IN ('PLATFORM', 'TENANT') AND (scope = 'PLATFORM') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_param_value_version_no CHECK (current_version_no >= 1),
  CONSTRAINT ck_param_value_source CHECK (source IN ('UI', 'API', 'SEED_TENANT', 'BUNDLE', 'ROLLBACK', 'REGISTER'))
);
CREATE INDEX ix_param_value_definition ON ph18_ops.param_value (definition_id);
CREATE TRIGGER tg_param_value_touch BEFORE UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_value_immutable BEFORE UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'scope');
CREATE TRIGGER tg_param_value_validate BEFORE INSERT OR UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_value_check('value');
CALL ph18_ops.p_enable_rls('ph18_ops.param_value', true);
COMMENT ON TABLE ph18_ops.param_value IS 'EN-18-03 Giá trị hiện hành của một khóa theo tenant (DD-14 value, scope). Dòng COMMON scope PLATFORM là giá trị nền tảng; dòng Tnn scope TENANT là ghi đè. Trigger kiểm kiểu, miền, danh sách cho phép, trần nền tảng và mức PLATFORM theo param_definition. Ghi có If-Match (version).';
COMMENT ON COLUMN ph18_ops.param_value.source IS 'SEED_TENANT: PH-20 ghi mặc định khi khởi tạo tenant (chỉ khóa chưa có); BUNDLE: nhập gói tham số; ROLLBACK: khôi phục phiên bản cũ.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_value CASCADE;

--changeset ph18:ph18-0160-param-value-version splitStatements:false
CREATE TABLE ph18_ops.param_value_version (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  definition_id          uuid NOT NULL,
  param_key              varchar(128) NOT NULL,
  version_no             integer NOT NULL,
  value                  jsonb NOT NULL,
  previous_value         jsonb,
  status                 varchar(20) NOT NULL,
  reason                 varchar(1000),
  change_request_id      uuid,
  rollback_of_version_no integer,
  effective_from         timestamptz NOT NULL DEFAULT now(),
  superseded_at          timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_value_version PRIMARY KEY (id),
  CONSTRAINT uq_param_value_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_value_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_param_value_version_no UNIQUE (tenant_id, param_key, version_no),
  CONSTRAINT fk_param_value_version_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT fk_param_value_version_change_request FOREIGN KEY (tenant_id, change_request_id) REFERENCES ph18_ops.param_change_request (tenant_id, id),
  CONSTRAINT ck_param_value_version_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_param_value_version_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_param_value_version_superseded CHECK ((status = 'SUPERSEDED') = (superseded_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_param_value_version_active ON ph18_ops.param_value_version (tenant_id, param_key) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_param_value_version_touch BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_value_version_immutable BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'version_no', 'value', 'previous_value', 'change_request_id', 'effective_from');
CREATE TRIGGER tg_param_value_version_fsm_status BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>ACTIVE,PENDING_APPROVAL>REJECTED,ACTIVE>SUPERSEDED');
CREATE TRIGGER tg_param_value_version_no_delete BEFORE DELETE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_no_delete();
CALL ph18_ops.p_enable_rls('ph18_ops.param_value_version', true);
COMMENT ON TABLE ph18_ops.param_value_version IS 'EN-18-04 Lịch sử phiên bản giá trị tham số (DD-14 có phiên bản): mỗi lần ghi thêm một dòng; nội dung bất biến, chỉ trạng thái chuyển PENDING_APPROVAL sang ACTIVE hoặc REJECTED, ACTIVE sang SUPERSEDED. Mỗi khóa một phiên bản ACTIVE. Không xóa; giữ 18.param.history-retention-years.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_value_version CASCADE;

--changeset ph18:ph18-0170-feature-flag splitStatements:false
CREATE TABLE ph18_ops.feature_flag (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  flag_key        varchar(128) NOT NULL,
  module          varchar(8) NOT NULL,
  owner           varchar(64) NOT NULL,
  description     text NOT NULL,
  enabled         boolean NOT NULL DEFAULT false,
  rollout_percent smallint NOT NULL DEFAULT 100,
  removal_date    date NOT NULL,
  status          varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_feature_flag PRIMARY KEY (id),
  CONSTRAINT uq_feature_flag_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_feature_flag_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_feature_flag_key UNIQUE (tenant_id, flag_key),
  CONSTRAINT ck_feature_flag_key CHECK (flag_key ~ '^ff\.[a-z0-9-]+\.[a-z0-9-]+$'),
  CONSTRAINT ck_feature_flag_module CHECK (module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_feature_flag_rollout CHECK (rollout_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_feature_flag_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_feature_flag_removal ON ph18_ops.feature_flag (removal_date) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_feature_flag_touch BEFORE UPDATE ON ph18_ops.feature_flag FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_feature_flag_immutable BEFORE UPDATE ON ph18_ops.feature_flag FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('flag_key', 'module');
CALL ph18_ops.p_enable_rls('ph18_ops.feature_flag', true);
COMMENT ON TABLE ph18_ops.feature_flag IS 'EN-18-06 Cờ tính năng ff.{module}.{tính-năng} theo tenant (QT-BR-03, CC-CFG-04): chủ sở hữu, ngày gỡ bắt buộc. Dòng COMMON là mặc định nền tảng, dòng Tnn ghi đè. Hiệu lực ≤ 60 giây qua sự kiện đổi.';
--rollback DROP TABLE IF EXISTS ph18_ops.feature_flag CASCADE;

--changeset ph18:ph18-0180-egress-allowlist-entry splitStatements:false
CREATE TABLE ph18_ops.egress_allowlist_entry (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  host           varchar(253) NOT NULL,
  port           integer NOT NULL DEFAULT 443,
  scheme         varchar(8) NOT NULL DEFAULT 'https',
  purpose_module varchar(8) NOT NULL,
  purpose        varchar(255) NOT NULL,
  enabled        boolean NOT NULL DEFAULT false,
  approved_by    varchar(64),
  approved_at    timestamptz,
  expires_at     timestamptz,
  revoked_at     timestamptz,
  revoked_by     varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_egress_allowlist_entry PRIMARY KEY (id),
  CONSTRAINT uq_egress_allowlist_entry_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_egress_allowlist_entry_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_egress_allowlist_entry_host UNIQUE (tenant_id, host, port, purpose_module),
  CONSTRAINT ck_egress_allowlist_entry_host CHECK (host ~ '^(\*\.)?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'),
  CONSTRAINT ck_egress_allowlist_entry_port CHECK (port BETWEEN 1 AND 65535),
  CONSTRAINT ck_egress_allowlist_entry_scheme CHECK (scheme = 'https'),
  CONSTRAINT ck_egress_allowlist_entry_module CHECK (purpose_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_egress_allowlist_entry_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_egress_allowlist_entry_enabled CHECK (NOT enabled OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND revoked_at IS NULL))
);
CREATE TRIGGER tg_egress_allowlist_entry_touch BEFORE UPDATE ON ph18_ops.egress_allowlist_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_egress_allowlist_entry_immutable BEFORE UPDATE ON ph18_ops.egress_allowlist_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('host', 'port', 'purpose_module');
CALL ph18_ops.p_enable_rls('ph18_ops.egress_allowlist_entry', false);
COMMENT ON TABLE ph18_ops.egress_allowlist_entry IS 'EN-18-07 Danh sách đích egress cho phép theo tenant (kiểu LIST<HOST>, giải Q15-10): máy đích HTTPS, cổng, PH dùng (PH-15 backend thử và kho Git, PH-13 webhook). Không nhận địa chỉ IP trần; duyệt bốn mắt trước khi hiệu lực; PH dùng vẫn kiểm lại khi gọi và chặn dải nội bộ.';
--rollback DROP TABLE IF EXISTS ph18_ops.egress_allowlist_entry CASCADE;

--changeset ph18:ph18-0190-param-bundle splitStatements:false
CREATE TABLE ph18_ops.param_bundle (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  bundle_code   varchar(64) NOT NULL,
  direction     varchar(8) NOT NULL,
  source_env    varchar(8) NOT NULL,
  target_env    varchar(8),
  namespaces    varchar(32)[] NOT NULL,
  item_count    integer NOT NULL DEFAULT 0,
  sha256        char(64),
  bucket        varchar(63),
  object_key    text,
  diff_summary  jsonb,
  status        varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by   varchar(64),
  approved_at   timestamptz,
  applied_at    timestamptz,
  error_message varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_bundle PRIMARY KEY (id),
  CONSTRAINT uq_param_bundle_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_bundle_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_param_bundle_code UNIQUE (tenant_id, bundle_code),
  CONSTRAINT ck_param_bundle_direction CHECK (direction IN ('EXPORT', 'IMPORT')),
  CONSTRAINT ck_param_bundle_env CHECK (source_env IN ('DEV', 'TEST', 'STAGING', 'PROD') AND (target_env IS NULL OR target_env IN ('DEV', 'TEST', 'STAGING', 'PROD'))),
  CONSTRAINT ck_param_bundle_status CHECK (status IN ('DRAFT', 'VALIDATED', 'PENDING_APPROVAL', 'APPLIED', 'FAILED', 'REJECTED')),
  CONSTRAINT ck_param_bundle_count CHECK (item_count >= 0),
  CONSTRAINT ck_param_bundle_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_param_bundle_bucket CHECK (bucket IS NULL OR bucket = 'dh-' || lower(tenant_id) || '-ops'),
  CONSTRAINT ck_param_bundle_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_param_bundle_applied CHECK (status <> 'APPLIED' OR direction = 'EXPORT' OR approved_by IS NOT NULL)
);
CREATE TRIGGER tg_param_bundle_touch BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_bundle_immutable BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('bundle_code', 'direction');
CREATE TRIGGER tg_param_bundle_fsm_status BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>VALIDATED,DRAFT>FAILED,VALIDATED>PENDING_APPROVAL,VALIDATED>APPLIED,PENDING_APPROVAL>APPLIED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>FAILED,VALIDATED>FAILED');
CALL ph18_ops.p_enable_rls('ph18_ops.param_bundle', false);
COMMENT ON TABLE ph18_ops.param_bundle IS 'EN-18-08 Gói tham số xuất nhập giữa môi trường (DEV, TEST, STAGING, PROD): danh sách không gian tên, số khóa, tổng kiểm tra, khác biệt so với đích. Tệp gói ở Garage bucket dh-{tenant}-ops, không chứa tham số ★ ở dạng rõ (chỉ khóa, cần nhập lại). Áp gói cần bốn mắt.';
--rollback DROP TABLE IF EXISTS ph18_ops.param_bundle CASCADE;
