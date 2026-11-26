-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national
-- Tệp 10: danh mục nền tảng và dịch vụ quốc gia, đặc tả, cung cấp lại, đối chiếu,
--         ảnh chụp cấu hình, luật định tuyến, duyệt bốn mắt, lệnh cho worker.
-- Chạy sau ph14_00_bootstrap.sql.
-- =============================================================================

\set ON_ERROR_STOP on
SET ROLE ph14_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 14-0010-catalog.sql
-- @changeset ph14-0100-national-platform
CREATE TABLE ph14_national.national_platform (
  id                       uuid          NOT NULL,
  tenant_id                varchar(16)   NOT NULL,
  code                     varchar(63)   NOT NULL,
  name                     varchar(200)  NOT NULL,
  platform_type            varchar(10)   NOT NULL,
  scope                    varchar(6)    NOT NULL DEFAULT 'TENANT',
  connection_code          varchar(63)   NOT NULL,
  auth_mode                varchar(20)   NOT NULL,
  spec_status              varchar(12)   NOT NULL DEFAULT 'OFFICIAL',
  default_timeout_ms       integer       NOT NULL DEFAULT 15000,
  owner_agency             varchar(200),
  state                    varchar(20)   NOT NULL DEFAULT 'DRAFT',
  state_reason             varchar(1000),
  tested_at                timestamptz,
  tested_connection_version integer,
  activation_requested_by  varchar(64),
  activation_requested_at  timestamptz,
  activated_by             varchar(64),
  activated_at             timestamptz,
  suspended_at             timestamptz,
  retired_at               timestamptz,
  security_hold            boolean       NOT NULL DEFAULT false,
  security_hold_at         timestamptz,
  security_hold_by         varchar(64),
  breaker_override         jsonb         NOT NULL DEFAULT '{}',
  created_at               timestamptz   NOT NULL DEFAULT now(),
  created_by               varchar(64)   NOT NULL,
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  updated_by               varchar(64)   NOT NULL,
  version                  integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_platform PRIMARY KEY (id),
  CONSTRAINT uq_national_platform_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_national_platform_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_national_platform_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_national_platform_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_national_platform_type CHECK (platform_type IN ('NDXP', 'NDOP', 'REGISTRY')),
  CONSTRAINT ck_national_platform_scope CHECK (scope IN ('TENANT', 'COMMON') AND ((scope = 'COMMON') = (tenant_id = 'COMMON'))),
  CONSTRAINT ck_national_platform_auth CHECK (auth_mode IN ('CLIENT_SECRET', 'PRIVATE_KEY_JWT', 'TLS_CLIENT_AUTH')),
  CONSTRAINT ck_national_platform_spec_status CHECK (spec_status IN ('OFFICIAL', 'PROVISIONAL')),
  CONSTRAINT ck_national_platform_timeout CHECK (default_timeout_ms BETWEEN 1000 AND 60000),
  CONSTRAINT ck_national_platform_state CHECK (state IN ('DRAFT', 'TESTED', 'PENDING_ACTIVATION', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_national_platform_tested CHECK (state = 'DRAFT' OR (tested_at IS NOT NULL AND tested_connection_version IS NOT NULL)),
  CONSTRAINT ck_national_platform_active CHECK (state NOT IN ('ACTIVE', 'SUSPENDED') OR (activated_by IS NOT NULL AND activated_at IS NOT NULL)),
  CONSTRAINT ck_national_platform_four_eyes CHECK (activated_by IS NULL OR (activation_requested_by IS NOT NULL AND activated_by <> activation_requested_by)),
  CONSTRAINT ck_national_platform_suspended CHECK ((state = 'SUSPENDED') = (suspended_at IS NOT NULL)),
  CONSTRAINT ck_national_platform_retired CHECK ((state = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_national_platform_hold CHECK (security_hold = (security_hold_at IS NOT NULL)),
  CONSTRAINT ck_national_platform_breaker CHECK (jsonb_typeof(breaker_override) = 'object'
                                                 AND NOT jsonb_path_exists(breaker_override, '$.* ? (@ != "FORCE_OPEN" && @ != "FORCE_CLOSED")'))
);
CREATE INDEX ix_national_platform_type_state ON ph14_national.national_platform (tenant_id, platform_type, state);
CREATE INDEX ix_national_platform_connection ON ph14_national.national_platform (tenant_id, connection_code);
CREATE INDEX ix_national_platform_name_trgm ON ph14_national.national_platform USING gin (lower(name) gin_trgm_ops);
CREATE TRIGGER tg_national_platform_touch BEFORE UPDATE ON ph14_national.national_platform FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CREATE TRIGGER tg_national_platform_retired BEFORE UPDATE ON ph14_national.national_platform FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_retired_final();
CALL ph14_national.p_enable_rls('ph14_national.national_platform', 'S');
COMMENT ON TABLE ph14_national.national_platform IS 'EN-14-01 Nền tảng quốc gia (NDXP, NDOP, REGISTRY) của một tenant hoặc của COMMON (FR-14-001, 002, 003). Địa chỉ và bí mật nằm ở kết nối PH-05 theo connection_code; mã bất biến, không dùng lại kể cả khi RETIRED.';
COMMENT ON COLUMN ph14_national.national_platform.connection_code IS 'Mã kết nối của PH-05 (schema ph05_adapter) cùng tenant; không khóa ngoại vì khác schema và khác đơn vị sở hữu, kiểm ở dịch vụ (BR-14-025).';
COMMENT ON COLUMN ph14_national.national_platform.scope IS 'COMMON chỉ khi tenant_id = COMMON (chỉ PA khai báo, BR-14-029).';
COMMENT ON COLUMN ph14_national.national_platform.spec_status IS 'PROVISIONAL: nền tảng đang dùng đặc tả tạm, giao diện hiển thị rõ (BR-14-025).';
COMMENT ON COLUMN ph14_national.national_platform.tested_at IS 'Lần kiểm tra kết nối đạt gần nhất; ACTIVE chỉ khi còn trong 24 giờ và khớp tested_connection_version (BR-14-022, ERR-14-008).';
COMMENT ON COLUMN ph14_national.national_platform.tested_connection_version IS 'Phiên bản cấu hình kết nối PH-05 lúc kiểm tra đạt (config_version).';
COMMENT ON COLUMN ph14_national.national_platform.activated_by IS 'Người duyệt bật; phải khác activation_requested_by (bốn mắt, ck_national_platform_four_eyes).';
COMMENT ON COLUMN ph14_national.national_platform.security_hold IS 'Cờ SECURITY_HOLD: từ chối lượt cần dữ liệu mới khi sự cố chữ ký dồn dập; chỉ cổng hoặc SO đặt, chỉ SO giải trừ khi không còn sự cố OPEN (BR-14-003, ERR-14-004).';
COMMENT ON COLUMN ph14_national.national_platform.breaker_override IS 'Cờ ép ngắt mạch theo nhóm dịch vụ, ví dụ {"LLTP":"FORCE_OPEN"}; cờ ép thắng trạng thái tự động (FR-14-038). Vào ảnh chụp cấu hình.';
-- @rollback DROP TABLE IF EXISTS ph14_national.national_platform CASCADE;

-- @changeset ph14-0110-national-service
CREATE TABLE ph14_national.national_service (
  id                       uuid          NOT NULL,
  tenant_id                varchar(16)   NOT NULL,
  platform_id              uuid          NOT NULL,
  code                     varchar(63)   NOT NULL,
  national_service_code    varchar(80)   NOT NULL,
  name                     varchar(200)  NOT NULL,
  service_group            varchar(10)   NOT NULL,
  direction                varchar(8)    NOT NULL DEFAULT 'OUTBOUND',
  protocol                 varchar(4)    NOT NULL,
  operation_type           varchar(5)    NOT NULL,
  idempotent               boolean,
  sensitivity              varchar(10)   NOT NULL,
  cacheable                boolean       NOT NULL DEFAULT false,
  cache_ttl_seconds        integer,
  stale_allowed            boolean       NOT NULL DEFAULT false,
  priority                 varchar(10)   NOT NULL DEFAULT 'NORMAL',
  signing_mode             varchar(8)    NOT NULL DEFAULT 'NONE',
  verify_mode              varchar(8)    NOT NULL DEFAULT 'NONE',
  purpose_required         boolean       NOT NULL,
  procedure_code_required  boolean       NOT NULL DEFAULT false,
  timeout_ms               integer,
  spec_url                 varchar(1000),
  reconcile_label          varchar(14)   NOT NULL DEFAULT 'UNKNOWN',
  reconciled_at            timestamptz,
  state                    varchar(10)   NOT NULL DEFAULT 'DRAFT',
  state_reason             varchar(1000),
  retired_at               timestamptz,
  legacy_ref               varchar(255),
  created_at               timestamptz   NOT NULL DEFAULT now(),
  created_by               varchar(64)   NOT NULL,
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  updated_by               varchar(64)   NOT NULL,
  version                  integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_service PRIMARY KEY (id),
  CONSTRAINT uq_national_service_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_national_service_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_national_service_national_code UNIQUE (tenant_id, platform_id, national_service_code, direction),
  CONSTRAINT fk_national_service_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_national_service_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_national_service_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_national_service_national_code CHECK (char_length(national_service_code) BETWEEN 1 AND 80),
  CONSTRAINT ck_national_service_group CHECK (service_group IN ('LLTP', 'HO_TICH', 'BHXH', 'DVQHNS', 'DKDN', 'VBQPPL', 'DMDC', 'OTHER')),
  CONSTRAINT ck_national_service_direction CHECK (direction IN ('OUTBOUND', 'INBOUND')),
  CONSTRAINT ck_national_service_protocol CHECK (protocol IN ('REST', 'SOAP')),
  CONSTRAINT ck_national_service_operation CHECK (operation_type IN ('READ', 'WRITE')),
  CONSTRAINT ck_national_service_idempotent CHECK (operation_type = 'READ' OR idempotent IS NOT NULL),
  CONSTRAINT ck_national_service_sensitivity CHECK (sensitivity IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_national_service_cache CHECK (NOT cacheable OR (sensitivity <> 'SENSITIVE' AND operation_type = 'READ' AND coalesce(cache_ttl_seconds, 0) BETWEEN 1 AND 86400)),
  CONSTRAINT ck_national_service_cache_ttl CHECK (cacheable OR cache_ttl_seconds IS NULL),
  CONSTRAINT ck_national_service_stale CHECK (NOT stale_allowed OR operation_type = 'READ'),
  CONSTRAINT ck_national_service_priority CHECK (priority IN ('ESSENTIAL', 'NORMAL', 'BACKGROUND')),
  CONSTRAINT ck_national_service_signing CHECK (signing_mode IN ('NONE', 'XMLDSIG', 'WSSE', 'JWS')),
  CONSTRAINT ck_national_service_verify CHECK (verify_mode IN ('NONE', 'XMLDSIG', 'WSSE', 'JWS')),
  CONSTRAINT ck_national_service_purpose CHECK (sensitivity NOT IN ('RESTRICTED', 'SENSITIVE') OR purpose_required),
  CONSTRAINT ck_national_service_procedure CHECK (NOT procedure_code_required OR purpose_required),
  CONSTRAINT ck_national_service_timeout CHECK (timeout_ms IS NULL OR timeout_ms BETWEEN 1000 AND 60000),
  CONSTRAINT ck_national_service_label CHECK (reconcile_label IN ('STILL', 'SPEC_CHANGED', 'DISCONTINUED', 'UNKNOWN')),
  CONSTRAINT ck_national_service_state CHECK (state IN ('DRAFT', 'ACTIVE', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_national_service_discontinued CHECK (reconcile_label <> 'DISCONTINUED' OR state IN ('DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_national_service_retired CHECK ((state = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE INDEX ix_national_service_platform_state ON ph14_national.national_service (tenant_id, platform_id, state);
CREATE INDEX ix_national_service_group_state ON ph14_national.national_service (tenant_id, service_group, state);
CREATE INDEX ix_national_service_label ON ph14_national.national_service (tenant_id, reconcile_label) WHERE reconcile_label <> 'STILL';
CREATE INDEX ix_national_service_name_trgm ON ph14_national.national_service USING gin (lower(name) gin_trgm_ops);
CREATE TRIGGER tg_national_service_touch BEFORE UPDATE ON ph14_national.national_service FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CREATE TRIGGER tg_national_service_retired BEFORE UPDATE ON ph14_national.national_service FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_retired_final();
CALL ph14_national.p_enable_rls('ph14_national.national_service', 'S');
COMMENT ON TABLE ph14_national.national_service IS 'EN-14-02 Dịch vụ quốc gia với chính sách đệm, ký số, ưu tiên, mức nhạy cảm (FR-14-004, 005, 006, 007). Dịch vụ thuộc nền tảng cùng tenant; dịch vụ COMMON do PA khai báo ở nền tảng COMMON.';
COMMENT ON COLUMN ph14_national.national_service.national_service_code IS 'Giá trị Service-code gửi trung ương; khác code (mã nội bộ bất biến).';
COMMENT ON COLUMN ph14_national.national_service.cacheable IS 'Không đệm dịch vụ SENSITIVE, thao tác WRITE (BR-14-014); cache_ttl_seconds ≤ 14.cache.max-ttl-seconds kiểm ở dịch vụ (ERR-14-036, ERR-14-038).';
COMMENT ON COLUMN ph14_national.national_service.purpose_required IS 'Bắt buộc với dịch vụ trả dữ liệu cá nhân (RESTRICTED trở lên, BR-14-008).';
COMMENT ON COLUMN ph14_national.national_service.reconcile_label IS 'Nhãn đối chiếu STILL, SPEC_CHANGED, DISCONTINUED, UNKNOWN; không phải trạng thái vòng đời (BR-14-024).';
COMMENT ON COLUMN ph14_national.national_service.legacy_ref IS 'Dòng trong phụ lục NGSP hệ cũ khi dịch vụ được nhập (FR-14-056); không chứa bí mật (BR-14-034).';
-- @rollback DROP TABLE IF EXISTS ph14_national.national_service CASCADE;

-- @changeset ph14-0120-service-spec splitStatements:false
CREATE TABLE ph14_national.service_spec (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  service_id            uuid          NOT NULL,
  spec_version          varchar(32)   NOT NULL,
  kind                  varchar(12)   NOT NULL,
  checksum              char(64)      NOT NULL,
  contract_version      varchar(16)   NOT NULL,
  breaking              boolean       NOT NULL DEFAULT false,
  content               text          NOT NULL,
  contract              jsonb         NOT NULL DEFAULT '{}',
  diff                  jsonb,
  source                varchar(6)    NOT NULL DEFAULT 'UPLOAD',
  source_url            varchar(1000),
  state                 varchar(10)   NOT NULL DEFAULT 'DRAFT',
  breaking_approved_by  varchar(64),
  activated_by          varchar(64),
  activated_at          timestamptz,
  superseded_at         timestamptz,
  note                  varchar(500),
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_spec PRIMARY KEY (id),
  CONSTRAINT uq_service_spec_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_service_spec_version UNIQUE (tenant_id, service_id, spec_version),
  CONSTRAINT fk_service_spec_service FOREIGN KEY (service_id, tenant_id) REFERENCES ph14_national.national_service (id, tenant_id),
  CONSTRAINT ck_service_spec_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_service_spec_version CHECK (spec_version ~ '^[0-9A-Za-z][0-9A-Za-z._-]{0,31}$'),
  CONSTRAINT ck_service_spec_kind CHECK (kind IN ('OPENAPI', 'WSDL', 'XSD', 'JSON_SCHEMA')),
  CONSTRAINT ck_service_spec_checksum CHECK (checksum ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_service_spec_contract_version CHECK (contract_version ~ '^[0-9]+\.[0-9]+$'),
  CONSTRAINT ck_service_spec_size CHECK (octet_length(content) BETWEEN 1 AND 5242880),
  CONSTRAINT ck_service_spec_contract CHECK (jsonb_typeof(contract) = 'object'),
  CONSTRAINT ck_service_spec_source CHECK (source IN ('UPLOAD', 'REMOTE')),
  CONSTRAINT ck_service_spec_state CHECK (state IN ('DRAFT', 'ACTIVE', 'SUPERSEDED')),
  CONSTRAINT ck_service_spec_breaking CHECK (NOT breaking OR state = 'DRAFT' OR breaking_approved_by IS NOT NULL),
  CONSTRAINT ck_service_spec_activated CHECK ((state IN ('ACTIVE', 'SUPERSEDED')) = (activated_at IS NOT NULL AND activated_by IS NOT NULL)),
  CONSTRAINT ck_service_spec_superseded CHECK ((state = 'SUPERSEDED') = (superseded_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_service_spec_one_active ON ph14_national.service_spec (tenant_id, service_id) WHERE state = 'ACTIVE';
CREATE INDEX ix_service_spec_service ON ph14_national.service_spec (tenant_id, service_id, created_at DESC);
CREATE OR REPLACE FUNCTION ph14_national.tg_service_spec_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  skip text[] := ARRAY['state', 'superseded_at', 'updated_at', 'updated_by', 'version'];
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.state <> 'DRAFT' THEN
      RAISE EXCEPTION 'Đặc tả % đã ACTIVE là bất biến, không xóa (ERR-14-010)', OLD.spec_version USING ERRCODE = '55000';
    END IF;
    RETURN OLD;
  END IF;
  IF OLD.state = 'SUPERSEDED' THEN
    RAISE EXCEPTION 'Đặc tả % đã SUPERSEDED, không sửa', OLD.spec_version USING ERRCODE = '55000';
  END IF;
  IF OLD.state = 'ACTIVE' THEN
    IF NEW.state <> 'SUPERSEDED' OR (to_jsonb(NEW) - skip) IS DISTINCT FROM (to_jsonb(OLD) - skip) THEN
      RAISE EXCEPTION 'Đặc tả % đã ACTIVE là bất biến, chỉ được chuyển SUPERSEDED (ERR-14-010)', OLD.spec_version USING ERRCODE = '55000';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_service_spec_frozen BEFORE UPDATE OR DELETE ON ph14_national.service_spec FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_service_spec_frozen();
CREATE TRIGGER tg_service_spec_touch BEFORE UPDATE ON ph14_national.service_spec FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.service_spec', 'S');
COMMENT ON TABLE ph14_national.service_spec IS 'EN-14-03 Đặc tả dịch vụ theo phiên bản, kèm hợp đồng (FR-14-008, 014). Bản ACTIVE bất biến, chỉ được chuyển SUPERSEDED (trigger tg_service_spec_frozen). Nội dung đặc tả (≤ 5 MB) lưu cùng để kích hoạt trong một giao dịch.';
COMMENT ON COLUMN ph14_national.service_spec.content IS 'Nội dung OpenAPI, WSDL, XSD hoặc JSON Schema đã quét mã độc và chặn XXE (FR-14-008); công khai về nghiệp vụ, không chứa bí mật.';
COMMENT ON COLUMN ph14_national.service_spec.contract IS 'Hợp đồng dịch vụ: thao tác, tham số vào, trường ra, mã lỗi, subjectKeyPaths, ignorePaths, operations[].cacheTtlSeconds, exposedFields (SDD §4.1).';
COMMENT ON COLUMN ph14_national.service_spec.contract_version IS 'Số chính.phụ của hợp đồng; thay đổi phá vỡ (breaking) phải tăng số chính (ERR-14-012).';
COMMENT ON COLUMN ph14_national.service_spec.breaking_approved_by IS 'Người có PERM-14-approve duyệt thay đổi phá vỡ trước khi kích hoạt.';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_service_spec_frozen() CASCADE; DROP TABLE IF EXISTS ph14_national.service_spec CASCADE;

-- @changeset ph14-0130-service-exposure
CREATE TABLE ph14_national.service_exposure (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  service_id          uuid          NOT NULL,
  api_code            varchar(64),
  path                varchar(255)  NOT NULL,
  contract_version    varchar(16)   NOT NULL,
  response_fields     text[]        NOT NULL,
  default_allocation  jsonb         NOT NULL DEFAULT '{}',
  requires_approval   boolean       NOT NULL DEFAULT true,
  description         varchar(1000),
  state               varchar(16)   NOT NULL DEFAULT 'DRAFT',
  state_reason        varchar(1000),
  request_id          uuid          NOT NULL,
  published_at        timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_exposure PRIMARY KEY (id),
  CONSTRAINT uq_service_exposure_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_service_exposure_service UNIQUE (tenant_id, service_id),
  CONSTRAINT uq_service_exposure_path UNIQUE (tenant_id, path),
  CONSTRAINT uq_service_exposure_api UNIQUE (tenant_id, api_code),
  CONSTRAINT fk_service_exposure_service FOREIGN KEY (service_id, tenant_id) REFERENCES ph14_national.national_service (id, tenant_id),
  CONSTRAINT ck_service_exposure_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_service_exposure_path CHECK (path ~ '^/quoc-gia/[a-z0-9][a-z0-9/-]{1,200}$'),
  CONSTRAINT ck_service_exposure_contract_version CHECK (contract_version ~ '^[0-9]+\.[0-9]+$'),
  CONSTRAINT ck_service_exposure_fields CHECK (cardinality(response_fields) BETWEEN 1 AND 200),
  CONSTRAINT ck_service_exposure_alloc CHECK (jsonb_typeof(default_allocation) = 'object'),
  CONSTRAINT ck_service_exposure_state CHECK (state IN ('DRAFT', 'PENDING_PUBLISH', 'FAILED_CREATE', 'ACTIVE', 'DEPRECATED')),
  CONSTRAINT ck_service_exposure_active CHECK (state <> 'ACTIVE' OR (api_code IS NOT NULL AND published_at IS NOT NULL))
);
CREATE TRIGGER tg_service_exposure_touch BEFORE UPDATE ON ph14_national.service_exposure FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.service_exposure', 'P');
COMMENT ON TABLE ph14_national.service_exposure IS 'EN-14-11 Cung cấp lại dịch vụ quốc gia thành API ở PH-02 (FR-14-009). Tối đa một cung cấp lại cho mỗi dịch vụ ở mỗi tenant; request_id là khóa chống trùng khi gọi PH-02 nên thử lại không tạo hai API nháp.';
COMMENT ON COLUMN ph14_national.service_exposure.response_fields IS 'Trường được phép trả cho HTTT (nguyên tắc tối thiểu hóa, BR-14-009); chỉ gồm trường có trong đặc tả.';
COMMENT ON COLUMN ph14_national.service_exposure.state IS 'FAILED_CREATE: PH-02 lỗi khi tạo API nháp, người dùng thử lại; PENDING_PUBLISH chờ sự kiện đã công bố của PH-02.';
-- @rollback DROP TABLE IF EXISTS ph14_national.service_exposure CASCADE;

-- @changeset ph14-0140-reconcile-run
CREATE TABLE ph14_national.reconcile_run (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  platform_id      uuid          NOT NULL,
  source           varchar(6)    NOT NULL,
  match_by         varchar(24)   NOT NULL DEFAULT 'NATIONAL_SERVICE_CODE',
  dry_run          boolean       NOT NULL DEFAULT true,
  state            varchar(8)    NOT NULL DEFAULT 'RUNNING',
  file_name        varchar(255),
  file_sha256      char(64),
  summary          jsonb         NOT NULL DEFAULT '{}',
  proposals        jsonb         NOT NULL DEFAULT '[]',
  applied_choices  jsonb,
  error_code       varchar(16),
  started_by       varchar(64)   NOT NULL,
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  applied_by       varchar(64),
  applied_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_reconcile_run PRIMARY KEY (id),
  CONSTRAINT uq_reconcile_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_reconcile_run_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_reconcile_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_reconcile_run_source CHECK (source IN ('FILE', 'REMOTE')),
  CONSTRAINT ck_reconcile_run_match CHECK (match_by IN ('NATIONAL_SERVICE_CODE', 'NAME')),
  CONSTRAINT ck_reconcile_run_state CHECK (state IN ('RUNNING', 'PREVIEW', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_reconcile_run_file CHECK (source = 'REMOTE' OR (file_name IS NOT NULL AND file_sha256 IS NOT NULL AND file_sha256 ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_reconcile_run_summary CHECK (jsonb_typeof(summary) = 'object' AND jsonb_typeof(proposals) = 'array'),
  CONSTRAINT ck_reconcile_run_finished CHECK ((state = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_reconcile_run_applied CHECK ((state = 'APPLIED') = (applied_by IS NOT NULL AND applied_at IS NOT NULL AND NOT dry_run))
);
CREATE UNIQUE INDEX uq_reconcile_run_open ON ph14_national.reconcile_run (tenant_id, platform_id) WHERE state = 'RUNNING';
CREATE INDEX ix_reconcile_run_platform ON ph14_national.reconcile_run (tenant_id, platform_id, started_at DESC);
CREATE TRIGGER tg_reconcile_run_touch BEFORE UPDATE ON ph14_national.reconcile_run FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.reconcile_run', 'P');
COMMENT ON TABLE ph14_national.reconcile_run IS 'Phiên đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP, kind SERVICE_RECONCILE của EN-14-10 (FR-14-007). Giữ 3 năm. Mỗi nền tảng tối đa một phiên RUNNING (ERR-14-026).';
COMMENT ON COLUMN ph14_national.reconcile_run.proposals IS 'Mảng đề xuất {nationalServiceCode, current, proposed, reason}; không chứa dữ liệu cá nhân.';
COMMENT ON COLUMN ph14_national.reconcile_run.dry_run IS 'true: chỉ báo cáo, không gán nhãn; APPLIED chỉ khi dry_run = false.';
-- @rollback DROP TABLE IF EXISTS ph14_national.reconcile_run CASCADE;

-- @changeset ph14-0150-config-revision
CREATE TABLE ph14_national.config_revision (
  id             uuid          NOT NULL,
  tenant_id      varchar(16)   NOT NULL,
  env            varchar(8)    NOT NULL,
  revision       bigint        NOT NULL DEFAULT 1,
  snapshot_hash  char(64),
  built_at       timestamptz,
  created_at     timestamptz   NOT NULL DEFAULT now(),
  created_by     varchar(64)   NOT NULL,
  updated_at     timestamptz   NOT NULL DEFAULT now(),
  updated_by     varchar(64)   NOT NULL,
  version        integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_config_revision PRIMARY KEY (id),
  CONSTRAINT uq_config_revision UNIQUE (tenant_id, env),
  CONSTRAINT ck_config_revision_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_config_revision_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_config_revision_rev CHECK (revision >= 1),
  CONSTRAINT ck_config_revision_hash CHECK (snapshot_hash IS NULL OR snapshot_hash ~ '^[0-9a-f]{64}$')
);
CREATE TRIGGER tg_config_revision_touch BEFORE UPDATE ON ph14_national.config_revision FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.config_revision', 'P');
COMMENT ON TABLE ph14_national.config_revision IS 'Số phiên bản ảnh chụp cấu hình của cổng, mỗi tenant và môi trường một dòng (FR-14-054, NFR-14-026). ConfigRevisionService.bump tăng revision trong cùng giao dịch với thay đổi bảng có mặt trong ảnh chụp; cổng bỏ sự kiện có revision nhỏ hơn bản đang giữ.';
COMMENT ON COLUMN ph14_national.config_revision.snapshot_hash IS 'SHA-256 của ảnh chụp đã phát; công việc đêm dựng lại và so để phát hiện chỗ quên bump (SDD §4.3).';
-- @rollback DROP TABLE IF EXISTS ph14_national.config_revision CASCADE;

-- @changeset ph14-0160-routing-rule
CREATE TABLE ph14_national.routing_rule (
  id                     uuid          NOT NULL,
  tenant_id              varchar(16)   NOT NULL,
  match_service_code     varchar(63),
  match_group            varchar(10),
  operation_type         varchar(5),
  primary_service_code   varchar(63)   NOT NULL,
  fallback_service_code  varchar(63),
  allow_fallback         boolean       NOT NULL DEFAULT false,
  priority               integer       NOT NULL,
  basis                  varchar(500)  NOT NULL,
  effective_from         timestamptz,
  state                  varchar(16)   NOT NULL DEFAULT 'DRAFT',
  requested_by           varchar(64),
  approved_by            varchar(64),
  approved_at            timestamptz,
  created_at             timestamptz   NOT NULL DEFAULT now(),
  created_by             varchar(64)   NOT NULL,
  updated_at             timestamptz   NOT NULL DEFAULT now(),
  updated_by             varchar(64)   NOT NULL,
  version                integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_routing_rule PRIMARY KEY (id),
  CONSTRAINT uq_routing_rule_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_routing_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_routing_rule_match CHECK ((match_service_code IS NOT NULL) <> (match_group IS NOT NULL)),
  CONSTRAINT ck_routing_rule_group CHECK (match_group IS NULL OR match_group IN ('LLTP', 'HO_TICH', 'BHXH', 'DVQHNS', 'DKDN', 'VBQPPL', 'DMDC', 'OTHER')),
  CONSTRAINT ck_routing_rule_operation CHECK ((match_group IS NULL) = (operation_type IS NULL) AND (operation_type IS NULL OR operation_type IN ('READ', 'WRITE'))),
  CONSTRAINT ck_routing_rule_priority CHECK (priority BETWEEN 1 AND 1000),
  CONSTRAINT ck_routing_rule_basis CHECK (char_length(basis) BETWEEN 10 AND 500),
  CONSTRAINT ck_routing_rule_fallback CHECK (allow_fallback = (fallback_service_code IS NOT NULL)),
  CONSTRAINT ck_routing_rule_fallback_read CHECK (NOT (allow_fallback AND operation_type = 'WRITE')),
  CONSTRAINT ck_routing_rule_fallback_distinct CHECK (fallback_service_code IS DISTINCT FROM primary_service_code),
  CONSTRAINT ck_routing_rule_state CHECK (state IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'DISABLED')),
  CONSTRAINT ck_routing_rule_four_eyes CHECK (state <> 'ACTIVE' OR (requested_by IS NOT NULL AND approved_by IS NOT NULL AND approved_by <> requested_by AND approved_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_routing_rule_active ON ph14_national.routing_rule
  (tenant_id, coalesce(match_service_code, ''), coalesce(match_group, ''), coalesce(operation_type, ''), priority) WHERE state = 'ACTIVE';
CREATE INDEX ix_routing_rule_state_priority ON ph14_national.routing_rule (tenant_id, state, priority DESC);
CREATE TRIGGER tg_routing_rule_touch BEFORE UPDATE ON ph14_national.routing_rule FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.routing_rule', 'P');
COMMENT ON TABLE ph14_national.routing_rule IS 'EN-14-04 Luật định tuyến tới nền tảng và dịch vụ đích (FR-14-012, 013). Số priority lớn là ưu tiên cao. Dịch vụ tham chiếu theo mã, không khóa ngoại, vì có thể là dịch vụ COMMON; kiểm ACTIVE và cùng nhóm ở dịch vụ (ERR-14-014, 015).';
COMMENT ON COLUMN ph14_national.routing_rule.allow_fallback IS 'Chuyển hướng dự phòng chỉ cho thao tác đọc (BR-14-023); khóa ở CSDL cho luật theo nhóm, luật theo dịch vụ kiểm thêm ở ứng dụng vì loại thao tác nằm ở national_service.';
COMMENT ON COLUMN ph14_national.routing_rule.basis IS 'Căn cứ văn bản hướng dẫn của trung ương, 10 đến 500 ký tự.';
COMMENT ON COLUMN ph14_national.routing_rule.requested_by IS 'Người đề nghị; ACTIVE chỉ khi approved_by khác người đề nghị (BR-14-022).';
-- @rollback DROP TABLE IF EXISTS ph14_national.routing_rule CASCADE;

-- @changeset ph14-0170-approval-request splitStatements:false
CREATE TABLE ph14_national.approval_request (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  request_type      varchar(32)   NOT NULL,
  object_type       varchar(24)   NOT NULL,
  object_code       varchar(128)  NOT NULL,
  summary           varchar(500),
  proposed_change   jsonb         NOT NULL,
  last_modified_by  varchar(64),
  requested_by      varchar(64)   NOT NULL,
  requested_at      timestamptz   NOT NULL DEFAULT now(),
  requester_mfa_at  timestamptz,
  reason            varchar(1000),
  status            varchar(10)   NOT NULL DEFAULT 'PENDING',
  decided_by        varchar(64),
  decided_at        timestamptz,
  approver_mfa_at   timestamptz,
  decision_note     varchar(1000),
  expires_at        timestamptz   NOT NULL,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_approval_request PRIMARY KEY (id),
  CONSTRAINT ck_approval_request_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_approval_request_type CHECK (request_type IN ('PLATFORM_ACTIVATE', 'ROUTING_RULE', 'QUOTA_PROD', 'CERT_ACTIVATE', 'SERVICE_RELAX_CONTROL',
                                                            'INBOUND_ENABLE', 'OPEN_DATA_FIRST_PUBLISH', 'SECURITY_PARAM_CHANGE')),
  CONSTRAINT ck_approval_request_object_type CHECK (object_type IN ('PLATFORM', 'ROUTING_RULE', 'QUOTA_POLICY', 'CERTIFICATE', 'TRUST_ANCHOR', 'SERVICE',
                                                                  'INBOUND_ENDPOINT', 'OPEN_DATASET', 'PARAMETER')),
  CONSTRAINT ck_approval_request_proposed CHECK (jsonb_typeof(proposed_change) = 'object'),
  CONSTRAINT ck_approval_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'CANCELLED')),
  CONSTRAINT ck_approval_request_expiry CHECK (expires_at > requested_at),
  CONSTRAINT ck_approval_request_decided CHECK ((status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_approval_request_four_eyes CHECK (decided_by IS NULL OR (decided_by <> requested_by AND decided_by IS DISTINCT FROM last_modified_by)),
  CONSTRAINT ck_approval_request_reject_note CHECK (status <> 'REJECTED' OR coalesce(char_length(decision_note), 0) >= 5),
  CONSTRAINT ck_approval_request_mfa CHECK (request_type <> 'CERT_ACTIVATE' OR status <> 'APPROVED' OR (requester_mfa_at IS NOT NULL AND approver_mfa_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_approval_request_pending ON ph14_national.approval_request (tenant_id, request_type, object_type, object_code) WHERE status = 'PENDING';
CREATE INDEX ix_approval_request_inbox ON ph14_national.approval_request (tenant_id, status, expires_at);
CREATE INDEX ix_approval_request_object ON ph14_national.approval_request (tenant_id, object_type, object_code, requested_at DESC);
CREATE OR REPLACE FUNCTION ph14_national.tg_approval_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'Yêu cầu duyệt không bị xóa' USING ERRCODE = '55000';
  END IF;
  IF OLD.status <> 'PENDING' THEN
    RAISE EXCEPTION 'Yêu cầu duyệt đã % không sửa được', OLD.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_approval_request_frozen BEFORE UPDATE OR DELETE ON ph14_national.approval_request FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_approval_frozen();
CREATE TRIGGER tg_approval_request_touch BEFORE UPDATE ON ph14_national.approval_request FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.approval_request', 'P');
COMMENT ON TABLE ph14_national.approval_request IS 'Đề nghị duyệt bốn mắt dùng chung cho tám loại thay đổi của BR-14-022 (ADR-046, FourEyesGuard). Người quyết định phải khác người đề nghị và người sửa gần nhất đối tượng; kích hoạt chứng thư cần cả hai xác thực nhiều yếu tố (BR-14-018). Đã quyết định thì bất biến.';
COMMENT ON COLUMN ph14_national.approval_request.proposed_change IS 'Thay đổi đề xuất (giá trị trước, sau của thuộc tính chính sách); không chứa bí mật.';
COMMENT ON COLUMN ph14_national.approval_request.last_modified_by IS 'Người sửa đối tượng gần nhất tại lúc đề nghị; so sánh theo mã người dùng, không theo vai trò (ERR-14-007).';
COMMENT ON COLUMN ph14_national.approval_request.expires_at IS 'Hết hạn sau 7 ngày kể từ requested_at (giả định theo ADR-046).';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_approval_frozen() CASCADE; DROP TABLE IF EXISTS ph14_national.approval_request CASCADE;

-- @changeset ph14-0180-worker-command
CREATE TABLE ph14_national.worker_command (
  id             uuid          NOT NULL,
  tenant_id      varchar(16)   NOT NULL,
  command_type   varchar(24)   NOT NULL,
  target_type    varchar(24)   NOT NULL,
  target_code    varchar(128)  NOT NULL,
  params         jsonb         NOT NULL DEFAULT '{}',
  state          varchar(10)   NOT NULL DEFAULT 'PENDING',
  requested_by   varchar(64)   NOT NULL,
  requested_at   timestamptz   NOT NULL DEFAULT now(),
  deadline_at    timestamptz   NOT NULL,
  finished_at    timestamptz,
  result         jsonb,
  error_code     varchar(16),
  trace_id       char(32),
  created_at     timestamptz   NOT NULL DEFAULT now(),
  created_by     varchar(64)   NOT NULL,
  updated_at     timestamptz   NOT NULL DEFAULT now(),
  updated_by     varchar(64)   NOT NULL,
  version        integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_worker_command PRIMARY KEY (id),
  CONSTRAINT ck_worker_command_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_worker_command_type CHECK (command_type IN ('probe', 'cert.selftest', 'token.test', 'sync.run', 'spec.fetch', 'catalog.fetch')),
  CONSTRAINT ck_worker_command_target CHECK (target_type IN ('PLATFORM', 'CERTIFICATE', 'SERVICE', 'SYNC_RUN')),
  CONSTRAINT ck_worker_command_state CHECK (state IN ('PENDING', 'DISPATCHED', 'SUCCEEDED', 'FAILED', 'TIMED_OUT')),
  CONSTRAINT ck_worker_command_deadline CHECK (deadline_at > requested_at),
  CONSTRAINT ck_worker_command_finished CHECK ((state IN ('SUCCEEDED', 'FAILED', 'TIMED_OUT')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_worker_command_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_worker_command_no_secret CHECK (NOT (params ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'passphrase'])
                                                AND (result IS NULL OR NOT (result ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'passphrase'])))
);
CREATE INDEX ix_worker_command_open ON ph14_national.worker_command (tenant_id, deadline_at) WHERE state IN ('PENDING', 'DISPATCHED');
CREATE INDEX ix_worker_command_target ON ph14_national.worker_command (tenant_id, target_type, target_code, command_type, requested_at DESC);
CREATE TRIGGER tg_worker_command_touch BEFORE UPDATE ON ph14_national.worker_command FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.worker_command', 'P');
COMMENT ON TABLE ph14_national.worker_command IS 'Lệnh dh-integration gửi vai trò worker của cổng (probe, cert.selftest, token.test, sync.run, spec.fetch, catalog.fetch) và kết quả (FR-14-002, 008, 043, 047). id là commandId, kết quả xử lý lũy đẳng theo id; quá deadline_at chuyển TIMED_OUT. Giữ 30 ngày (giả định), đếm giới hạn 14.test.max-per-hour.';
COMMENT ON COLUMN ph14_national.worker_command.result IS 'Kết quả từng bước (DNS, TCP, TLS, token, ký thử); không có giá trị bí mật, token (BR-14-005).';
-- @rollback DROP TABLE IF EXISTS ph14_national.worker_command CASCADE;

RESET ROLE;
