-- =============================================================================
-- D03-03-PH19 · DDL schema ph19_payment — PH-19 Thanh toán điện tử
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo · Nhóm phân hệ PH-19
--
-- Mục đích: tạo đầy đủ schema ph19_payment trên cụm pg-payment (PostgreSQL 18,
-- tương thích 16). Chạy độc lập (phát triển):
--   psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph19_payment.sql
-- Môi trường thật: vai trò đăng nhập do CloudNativePG tạo; phần còn lại chạy qua
-- Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback như PH-04.
-- Phân hệ mới, không thay bảng nào của mã hiện tại.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 19-0000-bootstrap.sql
-- @changeset ph19-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph19_owner') THEN
    CREATE ROLE ph19_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph19_app') THEN
    CREATE ROLE ph19_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph19_readonly') THEN
    CREATE ROLE ph19_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph19-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph19_payment AUTHORIZATION ph19_owner;
COMMENT ON SCHEMA ph19_payment IS 'PH-19 Thanh toán: NCC, dịch vụ, đối tác, giao dịch, IPN, hoàn tiền, đối soát, phê duyệt, webhook, cấu hình, di trú. Chủ ph19_owner; dh-payment kết nối bằng dh_payment_app (thành viên ph19_app, không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph19_payment TO ph19_app, ph19_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph19_payment CASCADE;

SET ROLE ph19_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 19-0001-functions.sql
-- @changeset ph19-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph19_payment.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph19_payment.tg_touch() IS 'Cập nhật updated_at và tăng version (ETag) khi ứng dụng không tự tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph19_payment.tg_touch();

-- @changeset ph19-0011-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph19_payment.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % là chỉ-ghi-thêm (BR-19-030): không được %', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'P1930';
END
$f$;
COMMENT ON FUNCTION ph19_payment.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng bất biến (BR-19-030, NFR-19-016). Dọn dữ liệu hết hạn bằng DETACH PARTITION dưới ph19_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph19_payment.tg_append_only();

-- @changeset ph19-0012-fn-rls splitStatements:false
-- Mẫu P của D03-10: đọc, ghi khi tenant_id = app.tenant_id. PH-19 không có dữ liệu COMMON.
CREATE OR REPLACE PROCEDURE ph19_payment.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_all ON %s FOR ALL USING %s WITH CHECK %s', n, t, w, w);
END
$p$;
COMMENT ON PROCEDURE ph19_payment.p_enable_rls(regclass) IS 'Bật FORCE RLS và một chính sách FOR ALL theo tenant (D03-10, ADR-003).';
-- @rollback DROP PROCEDURE IF EXISTS ph19_payment.p_enable_rls(regclass);

-- @changeset ph19-0013-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph19_payment.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_months - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + make_interval(months => i), 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, (d + make_interval(months => i))::timestamptz,
                     (d + make_interval(months => i + 1))::timestamptz);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph19_payment.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng (ADR-047). Tác vụ PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới.';
-- @rollback DROP PROCEDURE IF EXISTS ph19_payment.p_ensure_month_partitions(regclass, date, integer);

-- @file 19-0010-provider.sql
-- @changeset ph19-0100-provider
CREATE TABLE ph19_payment.payment_provider (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  code                 varchar(64)   NOT NULL,
  name                 varchar(255)  NOT NULL,
  adapter_type         varchar(16)   NOT NULL,
  status               varchar(24)   NOT NULL DEFAULT 'DRAFT',
  health_status        varchar(10)   NOT NULL DEFAULT 'UNKNOWN',
  health_checked_at    timestamptz,
  circuit_state        varchar(10)   NOT NULL DEFAULT 'CLOSED',
  sandbox_base_url     varchar(2048),
  production_base_url  varchar(2048),
  connection_key_hash  varchar(64)   NOT NULL,
  merchant_ref         varchar(64),
  refund_mode          varchar(8)    NOT NULL DEFAULT 'MANUAL',
  effective_from       date,
  tech_contact_name    varchar(255),
  tech_contact_phone   varchar(20),
  tech_contact_email   varchar(254),
  biz_contact_name     varchar(255),
  biz_contact_phone    varchar(20),
  biz_contact_email    varchar(254),
  capabilities         jsonb         NOT NULL DEFAULT '{}',
  pending_change       jsonb,
  result_mapping_version integer     NOT NULL DEFAULT 0,
  activated_at         timestamptz,
  retired_at           timestamptz,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  updated_by           varchar(64)   NOT NULL,
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_payment_provider PRIMARY KEY (id),
  CONSTRAINT uq_payment_provider_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_payment_provider_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_payment_provider_conn_key UNIQUE (connection_key_hash),
  CONSTRAINT ck_payment_provider_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_payment_provider_code CHECK (code ~ '^[A-Z][A-Z0-9_-]{1,63}$'),
  CONSTRAINT ck_payment_provider_adapter CHECK (adapter_type IN ('PAYGOV', 'MOCK')),
  CONSTRAINT ck_payment_provider_status CHECK (status IN ('DRAFT', 'PENDING_ACTIVATION', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_payment_provider_health CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'DOWN')),
  CONSTRAINT ck_payment_provider_circuit CHECK (circuit_state IN ('CLOSED', 'OPEN', 'HALF_OPEN')),
  CONSTRAINT ck_payment_provider_refund CHECK (refund_mode IN ('API', 'MANUAL')),
  CONSTRAINT ck_payment_provider_url CHECK (coalesce(sandbox_base_url, 'https://') ~ '^https://' AND coalesce(production_base_url, 'https://') ~ '^https://'),
  CONSTRAINT ck_payment_provider_caps CHECK (jsonb_typeof(capabilities) = 'object'),
  CONSTRAINT ck_payment_provider_active CHECK (status NOT IN ('ACTIVE', 'SUSPENDED', 'RETIRED') OR activated_at IS NOT NULL)
);
CREATE TRIGGER tg_payment_provider_touch BEFORE UPDATE ON ph19_payment.payment_provider FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.payment_provider');
COMMENT ON TABLE ph19_payment.payment_provider IS 'EN-19-01 Nhà cung cấp thanh toán (FR-19-001…011). Hệ cũ: payment_provider.';
COMMENT ON COLUMN ph19_payment.payment_provider.connection_key_hash IS 'SHA-256 hex của connectionKey hiện hành (32 ký tự Base32 Crockford, 160 bit) trong đường dẫn callback; nguyên văn ở OpenBao (ADR-045). Khung gọi cột này connection_key. Tra cứu khi nhận callback đi qua callback_route.';
COMMENT ON COLUMN ph19_payment.payment_provider.result_mapping_version IS 'Phiên bản bảng ánh xạ mã kết quả hiện hành (FR-19-069); 0 = chưa có.';
COMMENT ON COLUMN ph19_payment.payment_provider.capabilities IS 'ProviderCapabilities của adapter: cancel, refund, partialRefund, refundIpn, reconSource, returnSigned, mtls, queryRatePerSecond.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_provider CASCADE;

-- @changeset ph19-0105-callback-route
CREATE TABLE ph19_payment.callback_route (
  connection_key_hash  varchar(64)   NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  provider_id          uuid          NOT NULL,
  adapter_type         varchar(16)   NOT NULL,
  valid_until          timestamptz,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_callback_route PRIMARY KEY (connection_key_hash),
  CONSTRAINT fk_callback_route_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_callback_route_hash CHECK (connection_key_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_callback_route_provider ON ph19_payment.callback_route (tenant_id, provider_id);
COMMENT ON TABLE ph19_payment.callback_route IS 'Bảng định tuyến callback (ADR-045): sha256(connectionKey) → tenant, NCC. KHÔNG bật RLS vì phải tra trước khi biết tenant; chỉ chứa băm, không chứa dữ liệu nghiệp vụ. Xoay khóa: khóa cũ có valid_until = lúc xoay + 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.callback_route;

-- @changeset ph19-0110-provider-credential
CREATE TABLE ph19_payment.provider_credential (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  provider_id       uuid          NOT NULL,
  environment       varchar(10)   NOT NULL,
  purpose           varchar(20)   NOT NULL,
  secret_ref        varchar(512)  NOT NULL,
  fingerprint       varchar(128),
  algorithm         varchar(32),
  valid_from        timestamptz,
  valid_to          timestamptz,
  credential_status varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  transition_until  timestamptz,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_provider_credential PRIMARY KEY (id),
  CONSTRAINT fk_provider_credential_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_provider_credential_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_provider_credential_purpose CHECK (purpose IN ('SIGNING_KEY', 'VERIFY_CERT', 'MTLS_CLIENT_CERT', 'API_CREDENTIAL')),
  CONSTRAINT ck_provider_credential_status CHECK (credential_status IN ('ACTIVE', 'NEXT', 'RETIRED')),
  CONSTRAINT ck_provider_credential_ref CHECK (secret_ref ~ '^(kv|transit)/dh/[a-z0-9]+/payment/'),
  CONSTRAINT ck_provider_credential_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from)
);
CREATE UNIQUE INDEX uq_provider_credential_current ON ph19_payment.provider_credential (tenant_id, provider_id, environment, purpose, credential_status)
  WHERE credential_status IN ('ACTIVE', 'NEXT');
CREATE INDEX ix_provider_credential_expiry ON ph19_payment.provider_credential (tenant_id, valid_to) WHERE credential_status <> 'RETIRED';
CREATE TRIGGER tg_provider_credential_touch BEFORE UPDATE ON ph19_payment.provider_credential FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.provider_credential');
COMMENT ON TABLE ph19_payment.provider_credential IS 'EN-19-02 Tham chiếu bí mật NCC theo môi trường, mục đích; không chứa giá trị bí mật (NFR-19-022, FR-19-002, 012).';
COMMENT ON COLUMN ph19_payment.provider_credential.secret_ref IS 'Đường OpenBao kv/dh/{tenant viết thường}/payment/... hoặc transit/dh/{tenant}/payment/...';
-- @rollback DROP TABLE IF EXISTS ph19_payment.provider_credential CASCADE;

-- @changeset ph19-0120-provider-check-run
CREATE TABLE ph19_payment.provider_check_run (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  provider_id         uuid          NOT NULL,
  check_type          varchar(20)   NOT NULL,
  environment         varchar(10)   NOT NULL,
  result              varchar(20)   NOT NULL DEFAULT 'RUNNING',
  steps               jsonb         NOT NULL DEFAULT '[]',
  test_transaction_id uuid,
  started_at          timestamptz   NOT NULL DEFAULT now(),
  finished_at         timestamptz,
  started_by          varchar(64)   NOT NULL,
  trace_id            char(32)      NOT NULL,
  CONSTRAINT pk_provider_check_run PRIMARY KEY (id),
  CONSTRAINT fk_provider_check_run_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_provider_check_run_type CHECK (check_type IN ('CONNECTION', 'TEST_TRANSACTION')),
  CONSTRAINT ck_provider_check_run_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_provider_check_run_result CHECK (result IN ('RUNNING', 'PASSED', 'PASSED_WITHOUT_IPN', 'FAILED')),
  CONSTRAINT ck_provider_check_run_steps CHECK (jsonb_typeof(steps) = 'array')
);
CREATE INDEX ix_provider_check_run_latest ON ph19_payment.provider_check_run (tenant_id, provider_id, check_type, environment, started_at DESC);
CALL ph19_payment.p_enable_rls('ph19_payment.provider_check_run');
COMMENT ON TABLE ph19_payment.provider_check_run IS 'EN-19-03 Lần kiểm tra kết nối, giao dịch thử; bằng chứng checklist kích hoạt BR-19-010.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.provider_check_run CASCADE;

-- @changeset ph19-0130-provider-result-mapping
CREATE TABLE ph19_payment.provider_result_mapping (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  provider_id      uuid          NOT NULL,
  mapping_version  integer       NOT NULL,
  operation        varchar(12)   NOT NULL,
  provider_code    varchar(64)   NOT NULL,
  outcome          varchar(10)   NOT NULL,
  is_final         boolean       NOT NULL,
  reason_code      varchar(64),
  message_vi       varchar(500)  NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'DRAFT',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_provider_result_mapping PRIMARY KEY (id),
  CONSTRAINT uq_provider_result_mapping UNIQUE (tenant_id, provider_id, mapping_version, operation, provider_code),
  CONSTRAINT fk_provider_result_mapping_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_provider_result_mapping_op CHECK (operation IN ('INIT', 'IPN', 'QUERY', 'CANCEL', 'REFUND', 'REFUND_IPN', 'RECON')),
  CONSTRAINT ck_provider_result_mapping_outcome CHECK (outcome IN ('SUCCEEDED', 'FAILED', 'PENDING', 'UNKNOWN')),
  CONSTRAINT ck_provider_result_mapping_final CHECK (outcome <> 'SUCCEEDED' OR is_final),
  CONSTRAINT ck_provider_result_mapping_version CHECK (mapping_version >= 1),
  CONSTRAINT ck_provider_result_mapping_status CHECK (status IN ('DRAFT', 'ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_provider_result_mapping_active ON ph19_payment.provider_result_mapping (tenant_id, provider_id, operation, provider_code) WHERE status = 'ACTIVE';
CREATE OR REPLACE FUNCTION ph19_payment.tg_result_mapping_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.status = 'DRAFT' THEN RETURN OLD; END IF;
    RAISE EXCEPTION 'Phiên bản ánh xạ đã dùng là bất biến (FR-19-069)' USING ERRCODE = 'P1930';
  END IF;
  IF (NEW.status, OLD.status) NOT IN (('ACTIVE', 'DRAFT'), ('RETIRED', 'ACTIVE'))
     OR row(NEW.provider_id, NEW.mapping_version, NEW.operation, NEW.provider_code, NEW.outcome, NEW.is_final, NEW.reason_code, NEW.message_vi)
        IS DISTINCT FROM row(OLD.provider_id, OLD.mapping_version, OLD.operation, OLD.provider_code, OLD.outcome, OLD.is_final, OLD.reason_code, OLD.message_vi) THEN
    RAISE EXCEPTION 'Chỉ được đổi trạng thái DRAFT→ACTIVE→RETIRED của dòng ánh xạ' USING ERRCODE = 'P1930';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_provider_result_mapping_guard BEFORE UPDATE OR DELETE ON ph19_payment.provider_result_mapping FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_result_mapping_guard();
CALL ph19_payment.p_enable_rls('ph19_payment.provider_result_mapping');
COMMENT ON TABLE ph19_payment.provider_result_mapping IS 'EN-19-26 (đề xuất) Bảng ánh xạ mã kết quả NCC → kết cục nội bộ, có phiên bản (FR-19-069, GĐ-03). Mỗi phiên bản là bộ dòng đầy đủ; nội dung bất biến, chỉ trạng thái đi DRAFT → ACTIVE → RETIRED; bản nháp bị từ chối được xóa.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.provider_result_mapping CASCADE;

-- @changeset ph19-0140-provider-unmapped-code
CREATE TABLE ph19_payment.provider_unmapped_code (
  tenant_id        varchar(16)   NOT NULL,
  provider_id      uuid          NOT NULL,
  operation        varchar(12)   NOT NULL,
  provider_code    varchar(64)   NOT NULL,
  seen_count       bigint        NOT NULL DEFAULT 1,
  first_seen_at    timestamptz   NOT NULL DEFAULT now(),
  last_seen_at     timestamptz   NOT NULL DEFAULT now(),
  sample_message   varchar(500),
  CONSTRAINT pk_provider_unmapped_code PRIMARY KEY (tenant_id, provider_id, operation, provider_code),
  CONSTRAINT fk_provider_unmapped_code_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id) ON DELETE CASCADE
);
CALL ph19_payment.p_enable_rls('ph19_payment.provider_unmapped_code');
COMMENT ON TABLE ph19_payment.provider_unmapped_code IS 'Mã kết quả đã gặp nhưng chưa có trong bảng ánh xạ hiện hành (UI-19-04 tab Ánh xạ mã).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.provider_unmapped_code CASCADE;

-- @file 19-0020-catalog.sql
-- @changeset ph19-0200-service-group
CREATE TABLE ph19_payment.payment_service_group (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  sector_code      varchar(64),
  description      varchar(4000),
  display_order    integer       NOT NULL DEFAULT 0,
  catalog_invalid  boolean       NOT NULL DEFAULT false,
  deleted_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_payment_service_group PRIMARY KEY (id),
  CONSTRAINT uq_payment_service_group_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_payment_service_group_code CHECK (code ~ '^[A-Z][A-Z0-9_-]{1,63}$')
);
CREATE UNIQUE INDEX uq_payment_service_group_code ON ph19_payment.payment_service_group (tenant_id, code) WHERE deleted_at IS NULL;
CREATE TRIGGER tg_payment_service_group_touch BEFORE UPDATE ON ph19_payment.payment_service_group FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.payment_service_group');
COMMENT ON TABLE ph19_payment.payment_service_group IS 'EN-19-04 Nhóm dịch vụ (FR-19-013). Hệ cũ: payment_service_group (lĩnh vực giao dịch).';
COMMENT ON COLUMN ph19_payment.payment_service_group.sector_code IS 'Mã DM_LINH_VUC_TTHC của PH-07.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_service_group CASCADE;

-- @changeset ph19-0210-service
CREATE TABLE ph19_payment.payment_service (
  id                     uuid          NOT NULL,
  tenant_id              varchar(16)   NOT NULL,
  code                   varchar(64)   NOT NULL,
  name                   varchar(255)  NOT NULL,
  group_id               uuid          NOT NULL,
  provider_id            uuid          NOT NULL,
  status                 varchar(10)   NOT NULL DEFAULT 'DRAFT',
  fee_type_code          varchar(64)   NOT NULL,
  collecting_agency_code varchar(64)   NOT NULL,
  procedure_code         varchar(64),
  beneficiary_ref        varchar(64),
  min_amount             numeric(19,0) NOT NULL,
  max_amount             numeric(19,0) NOT NULL,
  expiry_minutes         integer,
  catalog_invalid        boolean       NOT NULL DEFAULT false,
  description            varchar(4000),
  created_at             timestamptz   NOT NULL DEFAULT now(),
  created_by             varchar(64)   NOT NULL,
  updated_at             timestamptz   NOT NULL DEFAULT now(),
  updated_by             varchar(64)   NOT NULL,
  version                integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_payment_service PRIMARY KEY (id),
  CONSTRAINT uq_payment_service_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_payment_service_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_payment_service_group FOREIGN KEY (group_id, tenant_id) REFERENCES ph19_payment.payment_service_group (id, tenant_id),
  CONSTRAINT fk_payment_service_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id),
  CONSTRAINT ck_payment_service_code CHECK (code ~ '^[A-Z][A-Z0-9_-]{1,63}$'),
  CONSTRAINT ck_payment_service_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_payment_service_amount CHECK (min_amount > 0 AND max_amount >= min_amount AND max_amount <= 999999999999),
  CONSTRAINT ck_payment_service_expiry CHECK (expiry_minutes IS NULL OR expiry_minutes BETWEEN 5 AND 1440)
);
CREATE INDEX ix_payment_service_group ON ph19_payment.payment_service (tenant_id, group_id, status);
CREATE INDEX ix_payment_service_provider ON ph19_payment.payment_service (tenant_id, provider_id, status);
CREATE TRIGGER tg_payment_service_touch BEFORE UPDATE ON ph19_payment.payment_service FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.payment_service');
COMMENT ON TABLE ph19_payment.payment_service IS 'EN-19-05 Dịch vụ thanh toán (FR-19-014…016). Một dịch vụ gắn đúng một NCC (BR-19-008).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_service CASCADE;

-- @file 19-0030-partner.sql
-- @changeset ph19-0300-partner
CREATE TABLE ph19_payment.payment_partner (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  code                 varchar(64)   NOT NULL,
  name                 varchar(255)  NOT NULL,
  status               varchar(20)   NOT NULL DEFAULT 'DRAFT',
  routing_mode         varchar(8)    NOT NULL DEFAULT 'LEGACY',
  agency_code          varchar(64)   NOT NULL,
  member_system_id     uuid,
  legacy_app_code      varchar(255),
  allowed_return_urls  jsonb         NOT NULL DEFAULT '[]',
  is_internal_test     boolean       NOT NULL DEFAULT false,
  tech_contact_name    varchar(255),
  tech_contact_phone   varchar(20),
  tech_contact_email   varchar(254),
  biz_contact_name     varchar(255),
  biz_contact_phone    varchar(20),
  biz_contact_email    varchar(254),
  terminated_at        timestamptz,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  updated_by           varchar(64)   NOT NULL,
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_payment_partner PRIMARY KEY (id),
  CONSTRAINT uq_payment_partner_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_payment_partner_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_payment_partner_code CHECK (code ~ '^([A-Z][A-Z0-9_-]{1,63}|__TEST__)$'),
  CONSTRAINT ck_payment_partner_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED', 'TERMINATED')),
  CONSTRAINT ck_payment_partner_routing CHECK (routing_mode IN ('LEGACY', 'SHADOW', 'DATAHUB')),
  CONSTRAINT ck_payment_partner_urls CHECK (jsonb_typeof(allowed_return_urls) = 'array'),
  CONSTRAINT ck_payment_partner_test CHECK (is_internal_test = (code = '__TEST__'))
);
CREATE UNIQUE INDEX uq_payment_partner_legacy ON ph19_payment.payment_partner (tenant_id, legacy_app_code) WHERE legacy_app_code IS NOT NULL;
CREATE TRIGGER tg_payment_partner_touch BEFORE UPDATE ON ph19_payment.payment_partner FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.payment_partner');
COMMENT ON TABLE ph19_payment.payment_partner IS 'EN-19-06 Đối tác (HTTT thu tiền qua PH-19) (FR-19-017, 018, 066). Hệ cũ: payment_partner. Đối tác ẩn __TEST__ chứa giao dịch thử (BR-19-033).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_partner CASCADE;

-- @changeset ph19-0310-partner-client
CREATE TABLE ph19_payment.partner_client (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  partner_id        uuid          NOT NULL,
  idp_client_id     varchar(255)  NOT NULL,
  auth_method       varchar(16)   NOT NULL,
  cert_fingerprint  varchar(128),
  expires_at        timestamptz,
  revoked_at        timestamptz,
  revoked_by        varchar(64),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  CONSTRAINT pk_partner_client PRIMARY KEY (id),
  CONSTRAINT uq_partner_client UNIQUE (tenant_id, idp_client_id),
  CONSTRAINT fk_partner_client_partner FOREIGN KEY (partner_id, tenant_id) REFERENCES ph19_payment.payment_partner (id, tenant_id),
  CONSTRAINT ck_partner_client_method CHECK (auth_method IN ('MTLS', 'PRIVATE_KEY_JWT')),
  CONSTRAINT ck_partner_client_mtls CHECK (auth_method <> 'MTLS' OR cert_fingerprint IS NOT NULL)
);
CREATE INDEX ix_partner_client_partner ON ph19_payment.partner_client (tenant_id, partner_id);
CALL ph19_payment.p_enable_rls('ph19_payment.partner_client');
COMMENT ON TABLE ph19_payment.partner_client IS 'EN-19-07 Client máy-máy tại PH-12 của đối tác (FR-19-019).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.partner_client CASCADE;

-- @changeset ph19-0320-partner-service-grant
CREATE TABLE ph19_payment.partner_service_grant (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  partner_id         uuid          NOT NULL,
  service_id         uuid          NOT NULL,
  max_amount_per_txn numeric(19,0),
  daily_txn_limit    integer,
  daily_amount_limit numeric(19,0),
  valid_from         timestamptz,
  valid_to           timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_partner_service_grant PRIMARY KEY (id),
  CONSTRAINT uq_partner_service_grant UNIQUE (tenant_id, partner_id, service_id),
  CONSTRAINT fk_partner_service_grant_partner FOREIGN KEY (partner_id, tenant_id) REFERENCES ph19_payment.payment_partner (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_partner_service_grant_service FOREIGN KEY (service_id, tenant_id) REFERENCES ph19_payment.payment_service (id, tenant_id),
  CONSTRAINT ck_partner_service_grant_limits CHECK (coalesce(max_amount_per_txn, 1) > 0 AND coalesce(daily_txn_limit, 1) > 0 AND coalesce(daily_amount_limit, 1) > 0),
  CONSTRAINT ck_partner_service_grant_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from)
);
CREATE TRIGGER tg_partner_service_grant_touch BEFORE UPDATE ON ph19_payment.partner_service_grant FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.partner_service_grant');
COMMENT ON TABLE ph19_payment.partner_service_grant IS 'EN-19-08 Gán dịch vụ và hạn mức cho đối tác (FR-19-020, BR-19-005).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.partner_service_grant CASCADE;

-- @changeset ph19-0330-partner-webhook-endpoint
CREATE TABLE ph19_payment.partner_webhook_endpoint (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  partner_id        uuid          NOT NULL,
  url               varchar(2048) NOT NULL,
  event_types       jsonb         NOT NULL,
  secret_ref        varchar(512)  NOT NULL,
  next_secret_ref   varchar(512),
  secret_transition_until timestamptz,
  endpoint_status   varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  last_test_ok_at   timestamptz,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_partner_webhook_endpoint PRIMARY KEY (id),
  CONSTRAINT uq_partner_webhook_endpoint_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_partner_webhook_endpoint_partner FOREIGN KEY (partner_id, tenant_id) REFERENCES ph19_payment.payment_partner (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_partner_webhook_endpoint_url CHECK (url ~ '^https://'),
  CONSTRAINT ck_partner_webhook_endpoint_types CHECK (jsonb_typeof(event_types) = 'array' AND jsonb_array_length(event_types) > 0),
  CONSTRAINT ck_partner_webhook_endpoint_status CHECK (endpoint_status IN ('ACTIVE', 'DISABLED'))
);
CREATE TRIGGER tg_partner_webhook_endpoint_touch BEFORE UPDATE ON ph19_payment.partner_webhook_endpoint FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.partner_webhook_endpoint');
COMMENT ON TABLE ph19_payment.partner_webhook_endpoint IS 'EN-19-09 Đầu nhận webhook của đối tác (FR-19-021). Địa chỉ nội bộ bị chặn ở ứng dụng (ERR-19-044).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.partner_webhook_endpoint CASCADE;

-- @changeset ph19-0340-partner-quota-usage
CREATE TABLE ph19_payment.partner_quota_usage (
  tenant_id       varchar(16)   NOT NULL,
  partner_id      uuid          NOT NULL,
  service_id      uuid          NOT NULL,
  business_date   date          NOT NULL,
  txn_count       integer       NOT NULL DEFAULT 0,
  amount_total    numeric(19,0) NOT NULL DEFAULT 0,
  reconciled_at   timestamptz,
  CONSTRAINT pk_partner_quota_usage PRIMARY KEY (tenant_id, partner_id, service_id, business_date),
  CONSTRAINT ck_partner_quota_usage_nonneg CHECK (txn_count >= 0 AND amount_total >= 0)
);
CALL ph19_payment.p_enable_rls('ph19_payment.partner_quota_usage');
COMMENT ON TABLE ph19_payment.partner_quota_usage IS 'Bộ đếm hạn mức ngày dự phòng và đối chiếu của bộ đếm Valkey (BR-19-005, SDD §5.5).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.partner_quota_usage CASCADE;

-- @file 19-0040-transaction.sql
-- @changeset ph19-0400-transaction-code-index
CREATE TABLE ph19_payment.transaction_code_index (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  transaction_code   varchar(32)   NOT NULL,
  created_at         timestamptz   NOT NULL,
  CONSTRAINT pk_transaction_code_index PRIMARY KEY (id),
  CONSTRAINT uq_transaction_code_index_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_transaction_code_index_code UNIQUE (transaction_code),
  CONSTRAINT ck_transaction_code_index_code CHECK (transaction_code ~ '^T[0-9]{2}[0-9]{6}[0-9A-HJKMNP-TV-Z]{10}$')
);
CREATE TRIGGER tg_transaction_code_index_ro BEFORE UPDATE OR DELETE ON ph19_payment.transaction_code_index FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.transaction_code_index');
COMMENT ON TABLE ph19_payment.transaction_code_index IS 'Mỏ neo không phân vùng của giao dịch: mã duy nhất toàn cục (BR-19-002) và đích khóa ngoại cho bảng khác (bảng giao dịch phân vùng không làm đích FK theo id được).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.transaction_code_index CASCADE;

-- @changeset ph19-0410-transaction
CREATE TABLE ph19_payment.payment_transaction (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  transaction_code      varchar(32)   NOT NULL,
  partner_id            uuid          NOT NULL,
  service_id            uuid          NOT NULL,
  provider_id           uuid          NOT NULL,
  partner_order_id      varchar(64)   NOT NULL,
  status                varchar(20)   NOT NULL DEFAULT 'CREATED',
  recon_status          varchar(12)   NOT NULL DEFAULT 'UNRECONCILED',
  amount                numeric(19,0) NOT NULL,
  refunded_amount       numeric(19,0) NOT NULL DEFAULT 0,
  currency              varchar(3)    NOT NULL DEFAULT 'VND',
  description           varchar(255)  NOT NULL,
  payer_name_enc        bytea,
  payer_id_no_enc       bytea,
  payer_phone_enc       bytea,
  payer_email_enc       bytea,
  payer_dek_wrapped     bytea,
  payer_name_masked     varchar(255),
  payer_phone_masked    varchar(20),
  payer_search_hash     varchar(64),
  payer_phone_hash      varchar(64),
  payer_id_no_hash      varchar(64),
  return_url            varchar(2048) NOT NULL,
  payment_url           varchar(2048),
  provider_reference    varchar(128),
  provider_result_code  varchar(64),
  mapping_version       integer,
  reason_code           varchar(64),
  channel_code          varchar(64),
  bank_code             varchar(64),
  procedure_code        varchar(64),
  metadata              jsonb         NOT NULL DEFAULT '{}',
  expires_at            timestamptz   NOT NULL,
  paid_at               timestamptz,
  finalized_at          timestamptz,
  is_test               boolean       NOT NULL DEFAULT false,
  is_shadow             boolean       NOT NULL DEFAULT false,
  is_migrated           boolean       NOT NULL DEFAULT false,
  late_paid             boolean       NOT NULL DEFAULT false,
  init_uncertain        boolean       NOT NULL DEFAULT false,
  needs_reconciliation  boolean       NOT NULL DEFAULT false,
  next_poll_at          timestamptz,
  poll_count            integer       NOT NULL DEFAULT 0,
  client_ip             inet,
  legacy_code           varchar(64),
  sequence              integer       NOT NULL DEFAULT 1,
  trace_id              char(32)      NOT NULL,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_payment_transaction PRIMARY KEY (id, created_at),
  CONSTRAINT fk_payment_transaction_anchor FOREIGN KEY (id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id),
  CONSTRAINT fk_payment_transaction_partner FOREIGN KEY (partner_id, tenant_id) REFERENCES ph19_payment.payment_partner (id, tenant_id),
  CONSTRAINT fk_payment_transaction_service FOREIGN KEY (service_id, tenant_id) REFERENCES ph19_payment.payment_service (id, tenant_id),
  CONSTRAINT fk_payment_transaction_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id),
  CONSTRAINT ck_payment_transaction_status CHECK (status IN ('CREATED', 'PENDING', 'SUCCEEDED', 'FAILED', 'EXPIRED', 'CANCELLED', 'PARTIALLY_REFUNDED', 'REFUNDED')),
  CONSTRAINT ck_payment_transaction_recon CHECK (recon_status IN ('UNRECONCILED', 'MATCHED', 'MISMATCHED')),
  CONSTRAINT ck_payment_transaction_amount CHECK (amount > 0 AND amount <= 999999999999),
  CONSTRAINT ck_payment_transaction_refunded CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
  CONSTRAINT ck_payment_transaction_refund_status CHECK (
    (status = 'REFUNDED') = (refunded_amount = amount)
    AND (status <> 'PARTIALLY_REFUNDED' OR (refunded_amount > 0 AND refunded_amount < amount))),
  CONSTRAINT ck_payment_transaction_currency CHECK (currency = 'VND'),
  CONSTRAINT ck_payment_transaction_paid CHECK (status NOT IN ('SUCCEEDED', 'PARTIALLY_REFUNDED', 'REFUNDED') OR paid_at IS NOT NULL),
  CONSTRAINT ck_payment_transaction_return CHECK (return_url ~ '^https://'),
  CONSTRAINT ck_payment_transaction_meta CHECK (jsonb_typeof(metadata) = 'object'),
  CONSTRAINT ck_payment_transaction_flags CHECK (NOT (is_test AND is_shadow))
) PARTITION BY RANGE (created_at);
CREATE INDEX ix_payment_transaction_code ON ph19_payment.payment_transaction (transaction_code);
CREATE INDEX ix_payment_transaction_order ON ph19_payment.payment_transaction (tenant_id, partner_id, partner_order_id);
CREATE INDEX ix_payment_transaction_provider_ref ON ph19_payment.payment_transaction (tenant_id, provider_id, provider_reference) WHERE provider_reference IS NOT NULL;
CREATE INDEX ix_payment_transaction_poll ON ph19_payment.payment_transaction (tenant_id, status, next_poll_at) WHERE next_poll_at IS NOT NULL;
CREATE INDEX ix_payment_transaction_created ON ph19_payment.payment_transaction (tenant_id, created_at DESC, id);
CREATE INDEX ix_payment_transaction_status ON ph19_payment.payment_transaction (tenant_id, status, created_at DESC);
CREATE INDEX ix_payment_transaction_service ON ph19_payment.payment_transaction (tenant_id, service_id, created_at DESC);
CREATE INDEX ix_payment_transaction_paid ON ph19_payment.payment_transaction (tenant_id, provider_id, paid_at) WHERE paid_at IS NOT NULL;
CREATE INDEX ix_payment_transaction_payer_name ON ph19_payment.payment_transaction (tenant_id, payer_search_hash) WHERE payer_search_hash IS NOT NULL;
CREATE INDEX ix_payment_transaction_payer_phone ON ph19_payment.payment_transaction (tenant_id, payer_phone_hash) WHERE payer_phone_hash IS NOT NULL;
CREATE INDEX ix_payment_transaction_payer_id ON ph19_payment.payment_transaction (tenant_id, payer_id_no_hash) WHERE payer_id_no_hash IS NOT NULL;
CREATE INDEX ix_payment_transaction_recon ON ph19_payment.payment_transaction (tenant_id, provider_id, created_at) WHERE needs_reconciliation;
CREATE TRIGGER tg_payment_transaction_touch BEFORE UPDATE ON ph19_payment.payment_transaction FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.payment_transaction');
COMMENT ON TABLE ph19_payment.payment_transaction IS 'EN-19-10 Giao dịch thanh toán, phân vùng tháng theo created_at (ADR-047). Hệ cũ: payment_transaction (amount int(10), pay_date chuỗi).';
COMMENT ON COLUMN ph19_payment.payment_transaction.recon_status IS 'Trạng thái đối soát (GĐ-03): UNRECONCILED = Chưa đối soát, MATCHED = Khớp, MISMATCHED = Lệch.';
COMMENT ON COLUMN ph19_payment.payment_transaction.payer_dek_wrapped IS 'Khóa dữ liệu AES-256-GCM của giao dịch, bọc bằng transit/dh/{tenant}/payment/payer-kek (ADR-048).';
COMMENT ON COLUMN ph19_payment.payment_transaction.payer_search_hash IS 'HMAC-SHA256 họ tên chuẩn hóa (khóa transit payer-search của tenant).';
COMMENT ON COLUMN ph19_payment.payment_transaction.mapping_version IS 'Phiên bản bảng ánh xạ đã dùng để chốt kết quả gần nhất (FR-19-069).';
COMMENT ON COLUMN ph19_payment.payment_transaction.sequence IS 'Số thứ tự thông báo, tăng mỗi lần chuyển trạng thái (BR-19-021).';
COMMENT ON COLUMN ph19_payment.payment_transaction.legacy_code IS 'Mã giao dịch hệ cũ khi is_migrated (FR-19-065).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_transaction CASCADE;

-- @changeset ph19-0411-transaction-partitions
CALL ph19_payment.p_ensure_month_partitions('ph19_payment.payment_transaction', DATE '2021-01-01', 76);
-- 2021-01 … 2027-04: đủ cho dữ liệu di trú từ 2021 và 5 tháng tới; PartitionMaintenanceJob tạo tiếp.
-- @rollback -- Gỡ theo bảng cha.

-- @changeset ph19-0420-order-guard
CREATE TABLE ph19_payment.transaction_order_guard (
  tenant_id         varchar(16)   NOT NULL,
  partner_id        uuid          NOT NULL,
  partner_order_id  varchar(64)   NOT NULL,
  transaction_id    uuid          NOT NULL,
  guarded_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_transaction_order_guard PRIMARY KEY (tenant_id, partner_id, partner_order_id),
  CONSTRAINT fk_transaction_order_guard_txn FOREIGN KEY (transaction_id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id)
);
CALL ph19_payment.p_enable_rls('ph19_payment.transaction_order_guard');
COMMENT ON TABLE ph19_payment.transaction_order_guard IS 'BR-19-007: mỗi mã hồ sơ của đối tác có tối đa một giao dịch CREATED, PENDING, SUCCEEDED, PARTIALLY_REFUNDED, REFUNDED. Dòng bị xóa khi giao dịch về FAILED, EXPIRED, CANCELLED (SDD §5.3).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.transaction_order_guard CASCADE;

-- @changeset ph19-0430-transaction-event
CREATE TABLE ph19_payment.transaction_event (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  transaction_id   uuid          NOT NULL,
  sequence         integer       NOT NULL,
  from_status      varchar(20),
  to_status        varchar(20)   NOT NULL,
  source           varchar(24)   NOT NULL,
  source_ref_id    uuid,
  provider_result_code varchar(64),
  mapping_version  integer,
  reason           varchar(1000),
  actor_id         varchar(64),
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  trace_id         char(32)      NOT NULL,
  CONSTRAINT pk_transaction_event PRIMARY KEY (id, occurred_at),
  CONSTRAINT fk_transaction_event_txn FOREIGN KEY (transaction_id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id),
  CONSTRAINT ck_transaction_event_source CHECK (source IN ('PARTNER_API', 'PROVIDER_INIT', 'IPN', 'POLL', 'MANUAL_SYNC', 'USER', 'EXPIRY_JOB', 'DISCREPANCY_RESOLUTION', 'REFUND', 'MIGRATION')),
  CONSTRAINT ck_transaction_event_to CHECK (to_status IN ('CREATED', 'PENDING', 'SUCCEEDED', 'FAILED', 'EXPIRED', 'CANCELLED', 'PARTIALLY_REFUNDED', 'REFUNDED'))
) PARTITION BY RANGE (occurred_at);
CREATE INDEX ix_transaction_event_txn ON ph19_payment.transaction_event (tenant_id, transaction_id, sequence);
CREATE TRIGGER tg_transaction_event_ro BEFORE UPDATE OR DELETE ON ph19_payment.transaction_event FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.transaction_event');
CALL ph19_payment.p_ensure_month_partitions('ph19_payment.transaction_event', DATE '2021-01-01', 76);
COMMENT ON TABLE ph19_payment.transaction_event IS 'EN-19-11 Lịch sử trạng thái giao dịch, bất biến (FR-19-028, BR-19-030), phân vùng tháng.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.transaction_event CASCADE;

-- @changeset ph19-0440-idempotency
CREATE TABLE ph19_payment.idempotency_record (
  tenant_id         varchar(16)   NOT NULL,
  client_id         varchar(255)  NOT NULL,
  request_method    varchar(8)    NOT NULL,
  request_path      varchar(512)  NOT NULL,
  idempotency_key   varchar(64)   NOT NULL,
  request_hash      varchar(64)   NOT NULL,
  state             varchar(12)   NOT NULL DEFAULT 'IN_PROGRESS',
  resource_id       uuid,
  response_status   smallint,
  response_body     jsonb,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  completed_at      timestamptz,
  expires_at        timestamptz   NOT NULL,
  CONSTRAINT pk_idempotency_record PRIMARY KEY (tenant_id, client_id, request_method, request_path, idempotency_key),
  CONSTRAINT ck_idempotency_record_key CHECK (idempotency_key ~ '^[A-Za-z0-9_-]{16,64}$'),
  CONSTRAINT ck_idempotency_record_state CHECK (state IN ('IN_PROGRESS', 'COMPLETED')),
  CONSTRAINT ck_idempotency_record_done CHECK (state = 'IN_PROGRESS' OR response_status IS NOT NULL)
);
CREATE INDEX ix_idempotency_record_expiry ON ph19_payment.idempotency_record (expires_at);
CALL ph19_payment.p_enable_rls('ph19_payment.idempotency_record');
COMMENT ON TABLE ph19_payment.idempotency_record IS 'EN-19-12 Kết quả yêu cầu ghi có Idempotency-Key (BR-19-006, ADR-041); giữ 24 giờ.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.idempotency_record CASCADE;

-- @changeset ph19-0450-transaction-adjustment
CREATE TABLE ph19_payment.transaction_adjustment (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  transaction_id   uuid          NOT NULL,
  kind             varchar(24)   NOT NULL,
  amount_delta     numeric(19,0) NOT NULL,
  discrepancy_id   uuid          NOT NULL,
  note             varchar(2000) NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_transaction_adjustment PRIMARY KEY (id),
  CONSTRAINT fk_transaction_adjustment_txn FOREIGN KEY (transaction_id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id),
  CONSTRAINT ck_transaction_adjustment_kind CHECK (kind IN ('PAYMENT_AMOUNT', 'REFUND_AMOUNT'))
);
CREATE INDEX ix_transaction_adjustment_txn ON ph19_payment.transaction_adjustment (tenant_id, transaction_id);
CREATE TRIGGER tg_transaction_adjustment_ro BEFORE UPDATE OR DELETE ON ph19_payment.transaction_adjustment FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.transaction_adjustment');
COMMENT ON TABLE ph19_payment.transaction_adjustment IS 'Bản ghi bù khi chấp nhận số liệu NCC (FR-19-046 ACCEPT_PROVIDER_FIGURE, BR-19-030); số tiền gốc không sửa.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.transaction_adjustment CASCADE;

-- @file 19-0050-callback-log.sql
-- @changeset ph19-0500-callback-inbox
CREATE TABLE ph19_payment.callback_inbox (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  provider_id         uuid          NOT NULL,
  callback_type       varchar(12)   NOT NULL,
  received_at         timestamptz   NOT NULL DEFAULT now(),
  source_ip           inet          NOT NULL,
  raw_headers         jsonb         NOT NULL,
  raw_body            text          NOT NULL,
  raw_hash            varchar(64)   NOT NULL,
  nonce               varchar(128),
  provider_reference  varchar(128),
  transaction_code    varchar(32),
  provider_result_code varchar(64),
  verification_result varchar(16)   NOT NULL,
  processing_status   varchar(12)   NOT NULL,
  quarantine_reason   varchar(20),
  processing_error    varchar(2000),
  processed_at        timestamptz,
  attempt_count       integer       NOT NULL DEFAULT 0,
  next_attempt_at     timestamptz,
  mapping_version     integer,
  transaction_id      uuid,
  refund_request_id   uuid,
  trace_id            char(32)      NOT NULL,
  CONSTRAINT pk_callback_inbox PRIMARY KEY (id, received_at),
  CONSTRAINT fk_callback_inbox_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id),
  CONSTRAINT ck_callback_inbox_type CHECK (callback_type IN ('PAYMENT', 'REFUND', 'RECON_NOTICE')),
  CONSTRAINT ck_callback_inbox_verify CHECK (verification_result IN ('VERIFIED', 'BAD_SIGNATURE', 'EXPIRED', 'REPLAYED', 'SOURCE_DENIED', 'MALFORMED', 'TENANT_MISMATCH')),
  CONSTRAINT ck_callback_inbox_status CHECK (processing_status IN ('RECEIVED', 'PROCESSED', 'DUPLICATE', 'QUARANTINED', 'FAILED', 'REJECTED')),
  CONSTRAINT ck_callback_inbox_quarantine CHECK ((processing_status = 'QUARANTINED') = (quarantine_reason IS NOT NULL)),
  CONSTRAINT ck_callback_inbox_reason CHECK (quarantine_reason IS NULL OR quarantine_reason IN ('AMOUNT_MISMATCH', 'REF_MISMATCH', 'NOT_FOUND', 'UNMAPPED_CODE', 'CONFLICT_FINAL')),
  CONSTRAINT ck_callback_inbox_rejected CHECK (verification_result = 'VERIFIED' OR processing_status IN ('REJECTED', 'DUPLICATE'))
) PARTITION BY RANGE (received_at);
CREATE INDEX ix_callback_inbox_work ON ph19_payment.callback_inbox (processing_status, received_at) WHERE processing_status IN ('RECEIVED', 'FAILED');
CREATE INDEX ix_callback_inbox_txn ON ph19_payment.callback_inbox (tenant_id, transaction_code);
CREATE INDEX ix_callback_inbox_nonce ON ph19_payment.callback_inbox (tenant_id, provider_id, nonce) WHERE nonce IS NOT NULL;
CREATE INDEX ix_callback_inbox_list ON ph19_payment.callback_inbox (tenant_id, received_at DESC);
CREATE OR REPLACE FUNCTION ph19_payment.tg_callback_inbox_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'callback_inbox là chỉ-ghi-thêm (BR-19-030)' USING ERRCODE = 'P1930';
  END IF;
  IF NEW.raw_body IS DISTINCT FROM OLD.raw_body OR NEW.raw_headers IS DISTINCT FROM OLD.raw_headers
     OR NEW.raw_hash IS DISTINCT FROM OLD.raw_hash OR NEW.received_at IS DISTINCT FROM OLD.received_at
     OR NEW.verification_result IS DISTINCT FROM OLD.verification_result THEN
    RAISE EXCEPTION 'Phần nguyên văn của IPN là bất biến (NFR-19-016)' USING ERRCODE = 'P1930';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_callback_inbox_guard BEFORE UPDATE OR DELETE ON ph19_payment.callback_inbox FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_callback_inbox_guard();
CALL ph19_payment.p_enable_rls('ph19_payment.callback_inbox');
CALL ph19_payment.p_ensure_month_partitions('ph19_payment.callback_inbox', DATE '2026-01-01', 16);
COMMENT ON TABLE ph19_payment.callback_inbox IS 'EN-19-13 Hộp nhận IPN, kể cả bị từ chối (FR-19-029…032, ADR-042). Phần nguyên văn bất biến; phần xử lý cập nhật được.';
COMMENT ON COLUMN ph19_payment.callback_inbox.nonce IS 'Duy nhất theo (tenant, provider, nonce) — kiểm ở Valkey SET NX và ở ứng dụng trước khi chèn (bảng phân vùng không đặt được ràng buộc duy nhất không chứa khóa phân vùng).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.callback_inbox CASCADE;

-- @changeset ph19-0505-callback-nonce
CREATE TABLE ph19_payment.callback_nonce (
  tenant_id     varchar(16)   NOT NULL,
  provider_id   uuid          NOT NULL,
  nonce         varchar(128)  NOT NULL,
  raw_hash      varchar(64)   NOT NULL,
  seen_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_callback_nonce PRIMARY KEY (tenant_id, provider_id, nonce)
);
CREATE INDEX ix_callback_nonce_seen ON ph19_payment.callback_nonce (seen_at);
CALL ph19_payment.p_enable_rls('ph19_payment.callback_nonce');
COMMENT ON TABLE ph19_payment.callback_nonce IS 'Lớp chống phát lại thứ hai (sau Valkey) cho nonce IPN; giữ 7 ngày (FR-19-029 bước 5).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.callback_nonce CASCADE;

-- @changeset ph19-0510-integration-log
CREATE TABLE ph19_payment.integration_log (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  direction             varchar(12)   NOT NULL,
  operation             varchar(12)   NOT NULL,
  provider_id           uuid,
  partner_id            uuid,
  transaction_id        uuid,
  refund_request_id     uuid,
  webhook_delivery_id   uuid,
  attempt_no            integer,
  http_status           smallint,
  result_code           varchar(64),
  latency_ms            integer       NOT NULL,
  request_size          integer,
  response_size         integer,
  request_body_masked   jsonb,
  response_body_masked  jsonb,
  occurred_at           timestamptz   NOT NULL DEFAULT now(),
  trace_id              char(32)      NOT NULL,
  CONSTRAINT pk_integration_log PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_integration_log_dir CHECK (direction IN ('OUT_PROVIDER', 'IN_PROVIDER', 'IN_PARTNER', 'OUT_PARTNER')),
  CONSTRAINT ck_integration_log_op CHECK (operation IN ('INIT', 'QUERY', 'CANCEL', 'REFUND', 'RECON_FETCH', 'HEALTH', 'IPN', 'RETURN', 'CREATE', 'READ', 'WEBHOOK')),
  CONSTRAINT ck_integration_log_latency CHECK (latency_ms >= 0)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX ix_integration_log_list ON ph19_payment.integration_log (tenant_id, occurred_at DESC);
CREATE INDEX ix_integration_log_txn ON ph19_payment.integration_log (tenant_id, transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX ix_integration_log_trace ON ph19_payment.integration_log (trace_id);
CREATE TRIGGER tg_integration_log_ro BEFORE UPDATE OR DELETE ON ph19_payment.integration_log FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.integration_log');
CALL ph19_payment.p_ensure_month_partitions('ph19_payment.integration_log', DATE '2026-01-01', 16);
COMMENT ON TABLE ph19_payment.integration_log IS 'EN-19-14 Nhật ký tích hợp (FR-19-054): online 12 tháng rồi DETACH, nén, chuyển kho đối tượng giữ 5 năm (NFR-19-015).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.integration_log CASCADE;

-- @file 19-0060-file-job.sql
-- @changeset ph19-0600-background-job
CREATE TABLE ph19_payment.background_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  job_type         varchar(20)   NOT NULL,
  parameters       jsonb         NOT NULL,
  job_status       varchar(10)   NOT NULL DEFAULT 'QUEUED',
  progress_pct     smallint      NOT NULL DEFAULT 0,
  result_summary   jsonb,
  result_file_id   uuid,
  error_message    varchar(2000),
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  started_at       timestamptz,
  finished_at      timestamptz,
  heartbeat_at     timestamptz,
  trace_id         char(32)      NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_background_job PRIMARY KEY (id),
  CONSTRAINT uq_background_job_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_background_job_type CHECK (job_type IN ('TRANSACTION_EXPORT', 'REPORT_EXPORT', 'RECON_MINUTES', 'MIGRATION_IMPORT', 'MIGRATION_COMPARE')),
  CONSTRAINT ck_background_job_status CHECK (job_status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_background_job_progress CHECK (progress_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_background_job_params CHECK (jsonb_typeof(parameters) = 'object')
);
CREATE INDEX ix_background_job_queue ON ph19_payment.background_job (job_status, requested_at) WHERE job_status IN ('QUEUED', 'RUNNING');
CREATE INDEX ix_background_job_list ON ph19_payment.background_job (tenant_id, job_type, requested_at DESC);
CREATE TRIGGER tg_background_job_touch BEFORE UPDATE ON ph19_payment.background_job FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.background_job');
COMMENT ON TABLE ph19_payment.background_job IS 'EN-19-24 Tác vụ nền: xuất giao dịch, xuất báo cáo, biên bản đối soát, nhập và đối chiếu di trú (FR-19-048, 052, 058, 065, 068). Bộ chạy lấy việc bằng FOR UPDATE SKIP LOCKED.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.background_job CASCADE;

-- @changeset ph19-0610-stored-file
CREATE TABLE ph19_payment.stored_file (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  purpose          varchar(20)   NOT NULL,
  owner_type       varchar(32),
  owner_id         uuid,
  bucket           varchar(63)   NOT NULL,
  object_key       varchar(1024) NOT NULL,
  file_name        varchar(255)  NOT NULL,
  content_type     varchar(127)  NOT NULL,
  size_bytes       bigint        NOT NULL,
  sha256           varchar(64)   NOT NULL,
  scan_status      varchar(10)   NOT NULL DEFAULT 'PENDING',
  retention_until  date,
  worm             boolean       NOT NULL DEFAULT false,
  superseded_by    uuid,
  expires_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_stored_file PRIMARY KEY (id),
  CONSTRAINT uq_stored_file_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_stored_file_object UNIQUE (bucket, object_key),
  CONSTRAINT fk_stored_file_superseded FOREIGN KEY (superseded_by, tenant_id) REFERENCES ph19_payment.stored_file (id, tenant_id),
  CONSTRAINT ck_stored_file_purpose CHECK (purpose IN ('RECON_SOURCE', 'RECON_MINUTES', 'EXPORT', 'REPORT', 'REFUND_VOUCHER', 'ATTACHMENT', 'MIGRATION_REPORT')),
  CONSTRAINT ck_stored_file_bucket CHECK (bucket ~ '^dh-t[0-9]{2}-payment(-worm)?$' AND worm = (bucket ~ '-worm$')),
  CONSTRAINT ck_stored_file_size CHECK (size_bytes >= 0),
  CONSTRAINT ck_stored_file_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_stored_file_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED', 'SKIPPED')),
  CONSTRAINT ck_stored_file_worm CHECK (NOT worm OR retention_until IS NOT NULL)
);
CREATE INDEX ix_stored_file_owner ON ph19_payment.stored_file (tenant_id, owner_type, owner_id);
CREATE INDEX ix_stored_file_expiry ON ph19_payment.stored_file (expires_at) WHERE expires_at IS NOT NULL;
CALL ph19_payment.p_enable_rls('ph19_payment.stored_file');
COMMENT ON TABLE ph19_payment.stored_file IS 'EN-19-23 Siêu dữ liệu tệp trong dh-{tenant}-payment (Garage) hoặc dh-{tenant}-payment-worm (Ceph RGW Object Lock).';
COMMENT ON COLUMN ph19_payment.stored_file.superseded_by IS 'Biên bản mới thay biên bản này khi phiên được mở lại (FR-19-047); biên bản cũ giữ nguyên trong WORM.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.stored_file CASCADE;

-- @changeset ph19-0620-job-file-fk
ALTER TABLE ph19_payment.background_job
  ADD CONSTRAINT fk_background_job_file FOREIGN KEY (result_file_id, tenant_id) REFERENCES ph19_payment.stored_file (id, tenant_id);
-- @rollback ALTER TABLE ph19_payment.background_job DROP CONSTRAINT IF EXISTS fk_background_job_file;

-- @file 19-0070-approval-refund.sql
-- @changeset ph19-0700-approval
CREATE TABLE ph19_payment.approval_request (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  approval_type        varchar(24)   NOT NULL,
  target_type          varchar(32)   NOT NULL,
  target_id            uuid          NOT NULL,
  payload              jsonb         NOT NULL,
  required_approvals   smallint      NOT NULL DEFAULT 1,
  status               varchar(10)   NOT NULL DEFAULT 'PENDING',
  requested_by         varchar(64)   NOT NULL,
  requested_at         timestamptz   NOT NULL DEFAULT now(),
  request_note         varchar(2000),
  first_approver_id    varchar(64),
  first_decided_at     timestamptz,
  second_approver_id   varchar(64),
  second_decided_at    timestamptz,
  decided_by           varchar(64),
  decision_note        varchar(2000),
  expires_at           timestamptz   NOT NULL,
  closed_at            timestamptz,
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_approval_request PRIMARY KEY (id),
  CONSTRAINT uq_approval_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_approval_request_type CHECK (approval_type IN ('PROVIDER_ACTIVATE', 'PROVIDER_RETIRE', 'PARTNER_ONBOARD', 'PARTNER_TERMINATE', 'REFUND', 'DISCREPANCY_RESOLUTION', 'RECON_REOPEN', 'ROUTING_MODE_CHANGE', 'RESULT_MAPPING_CHANGE')),
  CONSTRAINT ck_approval_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_approval_request_levels CHECK (required_approvals IN (1, 2)),
  CONSTRAINT ck_approval_request_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_approval_request_sod1 CHECK (first_approver_id IS NULL OR first_approver_id <> requested_by),
  CONSTRAINT ck_approval_request_sod2 CHECK (second_approver_id IS NULL OR second_approver_id NOT IN (requested_by, first_approver_id)),
  CONSTRAINT ck_approval_request_order CHECK (second_approver_id IS NULL OR (first_approver_id IS NOT NULL AND required_approvals = 2)),
  CONSTRAINT ck_approval_request_approved CHECK (status <> 'APPROVED'
     OR (required_approvals = 1 AND first_approver_id IS NOT NULL)
     OR (required_approvals = 2 AND second_approver_id IS NOT NULL)),
  CONSTRAINT ck_approval_request_reject_note CHECK (status <> 'REJECTED' OR decision_note IS NOT NULL)
);
CREATE UNIQUE INDEX uq_approval_request_pending ON ph19_payment.approval_request (tenant_id, target_type, target_id, approval_type) WHERE status = 'PENDING';
CREATE INDEX ix_approval_request_inbox ON ph19_payment.approval_request (tenant_id, status, approval_type, requested_at DESC);
CREATE INDEX ix_approval_request_expiry ON ph19_payment.approval_request (expires_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_approval_request_touch BEFORE UPDATE ON ph19_payment.approval_request FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.approval_request');
COMMENT ON TABLE ph19_payment.approval_request IS 'EN-19-16 Đề nghị phê duyệt bốn mắt dùng chung (ADR-046, BR-19-011). Tách nhiệm được CHECK ở CSDL, ngoài kiểm tra ở ứng dụng (ERR-19-033).';
COMMENT ON COLUMN ph19_payment.approval_request.payload IS 'Nội dung đề nghị và ảnh chụp bằng chứng lúc lập: checklist kích hoạt, số tiền hoàn, cách xử lý chênh lệch, bảng khác biệt ánh xạ, version đối tượng đích.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.approval_request CASCADE;

-- @changeset ph19-0710-refund
CREATE TABLE ph19_payment.refund_request (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  refund_code          varchar(32)   NOT NULL,
  transaction_id       uuid          NOT NULL,
  partner_id           uuid          NOT NULL,
  requested_by_type    varchar(8)    NOT NULL,
  requested_by         varchar(64)   NOT NULL,
  partner_refund_id    varchar(64),
  amount               numeric(19,0) NOT NULL,
  status               varchar(24)   NOT NULL DEFAULT 'PENDING_APPROVAL',
  mode                 varchar(8)    NOT NULL,
  reason_code          varchar(64)   NOT NULL,
  reason_text          varchar(2000),
  bank_code            varchar(64),
  account_no_enc       bytea,
  account_no_masked    varchar(32),
  provider_refund_ref  varchar(128),
  provider_result_code varchar(64),
  voucher_no           varchar(64),
  voucher_date         date,
  voucher_file_id      uuid,
  execution_count      integer       NOT NULL DEFAULT 0,
  approval_id          uuid,
  discrepancy_id       uuid,
  completed_at         timestamptz,
  is_migrated          boolean       NOT NULL DEFAULT false,
  trace_id             char(32)      NOT NULL,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_refund_request PRIMARY KEY (id),
  CONSTRAINT uq_refund_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_refund_request_code UNIQUE (refund_code),
  CONSTRAINT fk_refund_request_txn FOREIGN KEY (transaction_id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id),
  CONSTRAINT fk_refund_request_partner FOREIGN KEY (partner_id, tenant_id) REFERENCES ph19_payment.payment_partner (id, tenant_id),
  CONSTRAINT fk_refund_request_approval FOREIGN KEY (approval_id, tenant_id) REFERENCES ph19_payment.approval_request (id, tenant_id),
  CONSTRAINT fk_refund_request_voucher FOREIGN KEY (voucher_file_id, tenant_id) REFERENCES ph19_payment.stored_file (id, tenant_id),
  CONSTRAINT ck_refund_request_code CHECK (refund_code ~ '^R[0-9A-HJKMNP-TV-Z]{14}$'),
  CONSTRAINT ck_refund_request_by CHECK (requested_by_type IN ('USER', 'PARTNER')),
  CONSTRAINT ck_refund_request_partner_id CHECK (requested_by_type <> 'PARTNER' OR partner_refund_id IS NOT NULL),
  CONSTRAINT ck_refund_request_amount CHECK (amount > 0),
  CONSTRAINT ck_refund_request_status CHECK (status IN ('PENDING_APPROVAL', 'PENDING_SECOND_APPROVAL', 'APPROVED', 'PROCESSING', 'AWAITING_MANUAL', 'SUCCEEDED', 'FAILED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_refund_request_mode CHECK (mode IN ('API', 'MANUAL')),
  CONSTRAINT ck_refund_request_exec CHECK (execution_count BETWEEN 0 AND 3),
  CONSTRAINT ck_refund_request_voucher CHECK (NOT (status = 'SUCCEEDED' AND mode = 'MANUAL' AND NOT is_migrated) OR (voucher_no IS NOT NULL AND voucher_date IS NOT NULL)),
  CONSTRAINT ck_refund_request_done CHECK (status <> 'SUCCEEDED' OR completed_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_refund_request_open ON ph19_payment.refund_request (tenant_id, transaction_id)
  WHERE status NOT IN ('SUCCEEDED', 'REJECTED', 'CANCELLED', 'FAILED');
CREATE UNIQUE INDEX uq_refund_request_partner_ref ON ph19_payment.refund_request (tenant_id, partner_id, partner_refund_id) WHERE partner_refund_id IS NOT NULL;
CREATE INDEX ix_refund_request_list ON ph19_payment.refund_request (tenant_id, status, created_at DESC);
CREATE INDEX ix_refund_request_done ON ph19_payment.refund_request (tenant_id, completed_at) WHERE status = 'SUCCEEDED';
CREATE INDEX ix_refund_request_provider_ref ON ph19_payment.refund_request (tenant_id, provider_refund_ref) WHERE provider_refund_ref IS NOT NULL;
CREATE TRIGGER tg_refund_request_touch BEFORE UPDATE ON ph19_payment.refund_request FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.refund_request');
COMMENT ON TABLE ph19_payment.refund_request IS 'EN-19-15 Yêu cầu hoàn tiền (FR-19-038…041). Tối đa một yêu cầu chưa kết thúc mỗi giao dịch (BR-19-022); FAILED tính là kết thúc tạm, thực thi lại thì mở lại qua kiểm tra ở ứng dụng.';
COMMENT ON COLUMN ph19_payment.refund_request.refund_code IS 'R + 10 ký tự cuối mã giao dịch + 4 ký tự Base32 ngẫu nhiên (SDD §10).';
COMMENT ON COLUMN ph19_payment.refund_request.account_no_enc IS 'Số tài khoản nhận hoàn khi hoàn thủ công, mã hóa bằng DEK của giao dịch (ADR-048).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.refund_request CASCADE;

-- @file 19-0080-recon.sql
-- @changeset ph19-0800-recon-session
CREATE TABLE ph19_payment.reconciliation_session (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  provider_id        uuid          NOT NULL,
  business_date      date          NOT NULL,
  status             varchar(16)   NOT NULL DEFAULT 'SCHEDULED',
  run_no             integer       NOT NULL DEFAULT 1,
  source_type        varchar(12),
  source_file_id     uuid,
  dh_count           integer,
  provider_count     integer,
  dh_amount          numeric(19,0),
  provider_amount    numeric(19,0),
  matched_count      integer,
  discrepancy_count  integer,
  collect_attempts   integer       NOT NULL DEFAULT 0,
  next_collect_at    timestamptz,
  last_error         varchar(2000),
  closing_job_id     uuid,
  closed_at          timestamptz,
  closed_by          varchar(64),
  minutes_file_id    uuid,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_reconciliation_session PRIMARY KEY (id),
  CONSTRAINT uq_reconciliation_session_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_reconciliation_session_day UNIQUE (tenant_id, provider_id, business_date),
  CONSTRAINT fk_reconciliation_session_provider FOREIGN KEY (provider_id, tenant_id) REFERENCES ph19_payment.payment_provider (id, tenant_id),
  CONSTRAINT fk_reconciliation_session_source FOREIGN KEY (source_file_id, tenant_id) REFERENCES ph19_payment.stored_file (id, tenant_id),
  CONSTRAINT fk_reconciliation_session_minutes FOREIGN KEY (minutes_file_id, tenant_id) REFERENCES ph19_payment.stored_file (id, tenant_id),
  CONSTRAINT fk_reconciliation_session_job FOREIGN KEY (closing_job_id, tenant_id) REFERENCES ph19_payment.background_job (id, tenant_id),
  CONSTRAINT ck_reconciliation_session_status CHECK (status IN ('SCHEDULED', 'COLLECTING', 'WAITING_DATA', 'MATCHING', 'IN_REVIEW', 'READY_TO_CLOSE', 'CLOSED', 'REOPEN_PENDING', 'FAILED')),
  CONSTRAINT ck_reconciliation_session_source CHECK (source_type IS NULL OR source_type IN ('API', 'FILE_FETCH', 'FILE_UPLOAD')),
  CONSTRAINT ck_reconciliation_session_run CHECK (run_no >= 1),
  CONSTRAINT ck_reconciliation_session_closed CHECK (status NOT IN ('CLOSED', 'REOPEN_PENDING') OR (closed_at IS NOT NULL AND minutes_file_id IS NOT NULL))
);
CREATE INDEX ix_reconciliation_session_list ON ph19_payment.reconciliation_session (tenant_id, business_date DESC, provider_id);
CREATE INDEX ix_reconciliation_session_work ON ph19_payment.reconciliation_session (status, next_collect_at) WHERE status IN ('SCHEDULED', 'WAITING_DATA', 'FAILED');
CREATE TRIGGER tg_reconciliation_session_touch BEFORE UPDATE ON ph19_payment.reconciliation_session FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.reconciliation_session');
COMMENT ON TABLE ph19_payment.reconciliation_session IS 'EN-19-17 Phiên đối soát một NCC một ngày giao dịch giờ Việt Nam (FR-19-042, 043, 047, 048, BR-19-025). closing_job_id khác NULL khi đang sinh biên bản (trạng thái con CLOSING).';
-- @rollback DROP TABLE IF EXISTS ph19_payment.reconciliation_session CASCADE;

-- @changeset ph19-0810-recon-provider-line
CREATE TABLE ph19_payment.recon_provider_line (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  session_id          uuid          NOT NULL,
  run_no              integer       NOT NULL,
  line_no             integer       NOT NULL,
  kind                varchar(8)    NOT NULL,
  provider_reference  varchar(128),
  transaction_code    varchar(32),
  refund_ref          varchar(128),
  amount              numeric(19,0) NOT NULL,
  provider_status_code varchar(64)  NOT NULL,
  outcome             varchar(10)   NOT NULL,
  paid_at             timestamptz,
  CONSTRAINT pk_recon_provider_line PRIMARY KEY (id),
  CONSTRAINT uq_recon_provider_line UNIQUE (session_id, run_no, line_no),
  CONSTRAINT fk_recon_provider_line_session FOREIGN KEY (session_id, tenant_id) REFERENCES ph19_payment.reconciliation_session (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_recon_provider_line_kind CHECK (kind IN ('PAYMENT', 'REFUND')),
  CONSTRAINT ck_recon_provider_line_outcome CHECK (outcome IN ('SUCCEEDED', 'FAILED', 'PENDING', 'UNKNOWN')),
  CONSTRAINT ck_recon_provider_line_ref CHECK (provider_reference IS NOT NULL OR transaction_code IS NOT NULL)
);
CREATE INDEX ix_recon_provider_line_ref ON ph19_payment.recon_provider_line (session_id, run_no, provider_reference);
CREATE INDEX ix_recon_provider_line_code ON ph19_payment.recon_provider_line (session_id, run_no, transaction_code);
CALL ph19_payment.p_enable_rls('ph19_payment.recon_provider_line');
COMMENT ON TABLE ph19_payment.recon_provider_line IS 'Dòng phía NCC đã chuẩn hóa của một lần chạy (SDD §11.1). Bảng làm việc: xóa lần chạy cũ sau khi phiên CLOSED 90 ngày; nguồn gốc vẫn ở tệp RECON_SOURCE trong WORM.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.recon_provider_line CASCADE;

-- @changeset ph19-0820-discrepancy
CREATE TABLE ph19_payment.discrepancy (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  discrepancy_code   varchar(32)   NOT NULL,
  session_id         uuid          NOT NULL,
  type               varchar(24)   NOT NULL,
  status             varchar(16)   NOT NULL DEFAULT 'OPEN',
  transaction_id     uuid,
  refund_request_id  uuid,
  callback_id        uuid,
  provider_reference varchar(128),
  dh_amount          numeric(19,0),
  provider_amount    numeric(19,0),
  assignee_id        varchar(64),
  due_at             timestamptz   NOT NULL,
  escalation_ref     varchar(128),
  notes              jsonb         NOT NULL DEFAULT '[]',
  proposed_resolution varchar(32),
  resolution_type    varchar(32),
  resolution_note    varchar(2000),
  approval_id        uuid,
  detected_at        timestamptz   NOT NULL DEFAULT now(),
  resolved_at        timestamptz,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_discrepancy PRIMARY KEY (id),
  CONSTRAINT uq_discrepancy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_discrepancy_code UNIQUE (tenant_id, discrepancy_code),
  CONSTRAINT fk_discrepancy_session FOREIGN KEY (session_id, tenant_id) REFERENCES ph19_payment.reconciliation_session (id, tenant_id),
  CONSTRAINT fk_discrepancy_txn FOREIGN KEY (transaction_id, tenant_id) REFERENCES ph19_payment.transaction_code_index (id, tenant_id),
  CONSTRAINT fk_discrepancy_refund FOREIGN KEY (refund_request_id, tenant_id) REFERENCES ph19_payment.refund_request (id, tenant_id),
  CONSTRAINT fk_discrepancy_approval FOREIGN KEY (approval_id, tenant_id) REFERENCES ph19_payment.approval_request (id, tenant_id),
  CONSTRAINT ck_discrepancy_type CHECK (type IN ('MISSING_AT_PROVIDER', 'MISSING_AT_DATAHUB', 'STATUS_MISMATCH', 'AMOUNT_MISMATCH', 'DUPLICATE', 'LATE_PAYMENT', 'REFUND_MISMATCH', 'ORPHAN_CALLBACK')),
  CONSTRAINT ck_discrepancy_status CHECK (status IN ('OPEN', 'INVESTIGATING', 'ESCALATED', 'PROPOSED', 'RESOLVED')),
  CONSTRAINT ck_discrepancy_resolution CHECK (coalesce(resolution_type, proposed_resolution, 'X') IN ('X', 'UPDATE_STATUS_FROM_PROVIDER', 'CREATE_REFUND', 'ACCEPT_PROVIDER_FIGURE', 'NO_ACTION', 'AUTO_MATCHED')
     AND coalesce(proposed_resolution, 'X') <> 'AUTO_MATCHED'),
  CONSTRAINT ck_discrepancy_resolved CHECK ((status = 'RESOLVED') = (resolution_type IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT ck_discrepancy_noaction CHECK (resolution_type IS DISTINCT FROM 'NO_ACTION' OR resolution_note IS NOT NULL),
  CONSTRAINT ck_discrepancy_notes CHECK (jsonb_typeof(notes) = 'array')
);
CREATE INDEX ix_discrepancy_session ON ph19_payment.discrepancy (tenant_id, session_id, status);
CREATE INDEX ix_discrepancy_open ON ph19_payment.discrepancy (tenant_id, status, due_at) WHERE status <> 'RESOLVED';
CREATE INDEX ix_discrepancy_txn ON ph19_payment.discrepancy (tenant_id, transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX ix_discrepancy_assignee ON ph19_payment.discrepancy (tenant_id, assignee_id) WHERE status <> 'RESOLVED';
CREATE OR REPLACE FUNCTION ph19_payment.tg_discrepancy_notes_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF jsonb_array_length(NEW.notes) < jsonb_array_length(OLD.notes)
     OR (jsonb_array_length(OLD.notes) > 0
         AND (SELECT jsonb_agg(e ORDER BY o) FROM jsonb_array_elements(NEW.notes) WITH ORDINALITY AS t(e, o) WHERE o <= jsonb_array_length(OLD.notes))
             IS DISTINCT FROM OLD.notes) THEN
    RAISE EXCEPTION 'Ghi chú chênh lệch chỉ được nối thêm (FR-19-045)' USING ERRCODE = 'P1930';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_discrepancy_notes_guard BEFORE UPDATE OF notes ON ph19_payment.discrepancy FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_discrepancy_notes_guard();
CREATE TRIGGER tg_discrepancy_touch BEFORE UPDATE ON ph19_payment.discrepancy FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CREATE TRIGGER tg_discrepancy_no_delete BEFORE DELETE ON ph19_payment.discrepancy FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.discrepancy');
COMMENT ON TABLE ph19_payment.discrepancy IS 'EN-19-19 Bản ghi chênh lệch (FR-19-031, 044, 045, 046, BR-19-028). Không xóa; ghi chú chỉ nối thêm.';
COMMENT ON COLUMN ph19_payment.discrepancy.notes IS 'Mảng {at, by, text, attachmentIds[]} theo thời gian; nối thêm bằng ph19_payment.append_discrepancy_note().';
-- @rollback DROP TABLE IF EXISTS ph19_payment.discrepancy CASCADE;

-- @changeset ph19-0821-fn-append-note splitStatements:false
CREATE OR REPLACE FUNCTION ph19_payment.append_discrepancy_note(p_id uuid, p_by varchar, p_text varchar, p_attachments uuid[] DEFAULT '{}')
  RETURNS integer LANGUAGE sql AS $f$
  UPDATE ph19_payment.discrepancy
     SET notes = notes || jsonb_build_array(jsonb_build_object('at', now(), 'by', p_by, 'text', p_text, 'attachmentIds', to_jsonb(p_attachments))),
         version = version + 1
   WHERE id = p_id AND tenant_id = current_setting('app.tenant_id', false)
  RETURNING jsonb_array_length(notes);
$f$;
COMMENT ON FUNCTION ph19_payment.append_discrepancy_note(uuid, varchar, varchar, uuid[]) IS 'Nối một ghi chú vào discrepancy.notes; trả số ghi chú sau khi nối (NULL nếu không thấy bản ghi trong tenant).';
-- @rollback DROP FUNCTION IF EXISTS ph19_payment.append_discrepancy_note(uuid, varchar, varchar, uuid[]);

-- @changeset ph19-0830-recon-item
CREATE TABLE ph19_payment.reconciliation_item (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  session_id          uuid          NOT NULL,
  run_no              integer       NOT NULL,
  item_kind           varchar(8)    NOT NULL,
  transaction_id      uuid,
  refund_request_id   uuid,
  provider_line_id    uuid,
  transaction_code    varchar(32),
  provider_reference  varchar(128),
  dh_amount           numeric(19,0),
  provider_amount     numeric(19,0),
  dh_status           varchar(32),
  provider_status     varchar(32),
  match_result        varchar(20)   NOT NULL,
  discrepancy_id      uuid,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_reconciliation_item PRIMARY KEY (id),
  CONSTRAINT fk_reconciliation_item_session FOREIGN KEY (session_id, tenant_id) REFERENCES ph19_payment.reconciliation_session (id, tenant_id),
  CONSTRAINT fk_reconciliation_item_discrepancy FOREIGN KEY (discrepancy_id, tenant_id) REFERENCES ph19_payment.discrepancy (id, tenant_id),
  CONSTRAINT ck_reconciliation_item_kind CHECK (item_kind IN ('PAYMENT', 'REFUND')),
  CONSTRAINT ck_reconciliation_item_result CHECK (match_result IN ('MATCHED', 'MISMATCHED', 'MISSING_DH', 'MISSING_PROVIDER')),
  CONSTRAINT ck_reconciliation_item_side CHECK (transaction_id IS NOT NULL OR refund_request_id IS NOT NULL OR provider_line_id IS NOT NULL)
);
CREATE INDEX ix_reconciliation_item_run ON ph19_payment.reconciliation_item (tenant_id, session_id, run_no, match_result);
CREATE INDEX ix_reconciliation_item_txn ON ph19_payment.reconciliation_item (tenant_id, transaction_id) WHERE transaction_id IS NOT NULL;
CREATE TRIGGER tg_reconciliation_item_ro BEFORE UPDATE OR DELETE ON ph19_payment.reconciliation_item FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.reconciliation_item');
COMMENT ON TABLE ph19_payment.reconciliation_item IS 'EN-19-18 Dòng so khớp của một lần chạy (FR-19-044); chỉ-ghi-thêm theo run_no. match_result MISMATCHED gom AMOUNT_MISMATCH, STATUS_MISMATCH; loại chi tiết nằm ở discrepancy.type.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.reconciliation_item CASCADE;

-- @changeset ph19-0840-approval-fk
ALTER TABLE ph19_payment.refund_request
  ADD CONSTRAINT fk_refund_request_discrepancy FOREIGN KEY (discrepancy_id, tenant_id) REFERENCES ph19_payment.discrepancy (id, tenant_id);
-- @rollback ALTER TABLE ph19_payment.refund_request DROP CONSTRAINT IF EXISTS fk_refund_request_discrepancy;

-- @changeset ph19-0850-adjustment-fk
ALTER TABLE ph19_payment.transaction_adjustment
  ADD CONSTRAINT fk_transaction_adjustment_discrepancy FOREIGN KEY (discrepancy_id, tenant_id) REFERENCES ph19_payment.discrepancy (id, tenant_id);
-- @rollback ALTER TABLE ph19_payment.transaction_adjustment DROP CONSTRAINT IF EXISTS fk_transaction_adjustment_discrepancy;

-- @file 19-0090-messaging.sql
-- @changeset ph19-0900-outbox
CREATE TABLE ph19_payment.outbox_event (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  aggregate_type    varchar(64)   NOT NULL,
  aggregate_id      uuid          NOT NULL,
  event_type        varchar(64)   NOT NULL,
  topic             varchar(255)  NOT NULL,
  partition_key     varchar(128)  NOT NULL,
  headers           jsonb         NOT NULL DEFAULT '{}',
  payload           jsonb         NOT NULL,
  occurred_at       timestamptz   NOT NULL DEFAULT now(),
  published_at      timestamptz,
  publish_attempts  integer       NOT NULL DEFAULT 0,
  last_error        varchar(1000),
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^t[0-9]{2}\.(payment|audit)\.[a-z0-9.-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_event_payload CHECK (jsonb_typeof(payload) = 'object')
);
CREATE INDEX ix_outbox_event_unpublished ON ph19_payment.outbox_event (occurred_at) WHERE published_at IS NULL;
CREATE INDEX ix_outbox_event_published ON ph19_payment.outbox_event (published_at) WHERE published_at IS NOT NULL;
CALL ph19_payment.p_enable_rls('ph19_payment.outbox_event');
COMMENT ON TABLE ph19_payment.outbox_event IS 'EN-19-21 Transactional outbox (ADR-042): sự kiện Kafka, bản ghi kiểm toán. Debezium đọc WAL (publication ph19_outbox) hoặc OutboxRelay đọc SKIP LOCKED; xóa sau 7 ngày kể từ published_at.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.outbox_event CASCADE;

-- @changeset ph19-0910-webhook-delivery
CREATE TABLE ph19_payment.webhook_delivery (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  endpoint_id       uuid          NOT NULL,
  partner_id        uuid          NOT NULL,
  event_id          uuid          NOT NULL,
  event_type        varchar(64)   NOT NULL,
  transaction_id    uuid,
  sequence          integer,
  payload           jsonb         NOT NULL,
  status            varchar(16)   NOT NULL DEFAULT 'PENDING',
  attempt_count     integer       NOT NULL DEFAULT 0,
  manual_resend_count integer     NOT NULL DEFAULT 0,
  next_attempt_at   timestamptz   NOT NULL DEFAULT now(),
  last_http_status  smallint,
  last_error        varchar(1000),
  delivered_at      timestamptz,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_webhook_delivery PRIMARY KEY (id),
  CONSTRAINT uq_webhook_delivery_event UNIQUE (tenant_id, endpoint_id, event_id),
  CONSTRAINT fk_webhook_delivery_endpoint FOREIGN KEY (endpoint_id, tenant_id) REFERENCES ph19_payment.partner_webhook_endpoint (id, tenant_id),
  CONSTRAINT ck_webhook_delivery_status CHECK (status IN ('PENDING', 'SENDING', 'DELIVERED', 'RETRY_SCHEDULED', 'EXHAUSTED', 'CANCELLED')),
  CONSTRAINT ck_webhook_delivery_done CHECK ((status = 'DELIVERED') = (delivered_at IS NOT NULL)),
  CONSTRAINT ck_webhook_delivery_attempts CHECK (attempt_count >= 0 AND manual_resend_count >= 0)
);
CREATE INDEX ix_webhook_delivery_due ON ph19_payment.webhook_delivery (next_attempt_at) WHERE status IN ('PENDING', 'RETRY_SCHEDULED');
CREATE INDEX ix_webhook_delivery_list ON ph19_payment.webhook_delivery (tenant_id, partner_id, created_at DESC);
CREATE INDEX ix_webhook_delivery_txn ON ph19_payment.webhook_delivery (tenant_id, transaction_id) WHERE transaction_id IS NOT NULL;
CREATE TRIGGER tg_webhook_delivery_touch BEFORE UPDATE ON ph19_payment.webhook_delivery FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_touch();
CALL ph19_payment.p_enable_rls('ph19_payment.webhook_delivery');
COMMENT ON TABLE ph19_payment.webhook_delivery IS 'EN-19-20 Gửi một sự kiện tới một đầu nhận (FR-19-060, 062). Gửi lại thủ công đưa EXHAUSTED về PENDING trên chính dòng này, giữ event_id. Giữ 90 ngày.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.webhook_delivery CASCADE;

-- @changeset ph19-0920-notification-feed
CREATE TABLE ph19_payment.notification_feed (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  partner_id        uuid          NOT NULL,
  event_type        varchar(64)   NOT NULL,
  transaction_id    uuid,
  payload           jsonb         NOT NULL,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_notification_feed PRIMARY KEY (id)
);
CREATE INDEX ix_notification_feed_cursor ON ph19_payment.notification_feed (tenant_id, partner_id, id);
CREATE INDEX ix_notification_feed_age ON ph19_payment.notification_feed (created_at);
CALL ph19_payment.p_enable_rls('ph19_payment.notification_feed');
COMMENT ON TABLE ph19_payment.notification_feed IS 'Luồng thông báo kéo cho đối tác (API-19-109, A-19-10). id là UUIDv7 nên tăng theo thời gian, dùng làm con trỏ after; giữ 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.notification_feed CASCADE;

-- @file 19-0100-config-stats-migration.sql
-- @changeset ph19-1000-tenant-config
CREATE TABLE ph19_payment.tenant_payment_config (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  config_version    integer       NOT NULL,
  effective_from    timestamptz   NOT NULL,
  settings          jsonb         NOT NULL,
  module_enabled    boolean       NOT NULL DEFAULT false,
  change_note       varchar(2000),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  CONSTRAINT pk_tenant_payment_config PRIMARY KEY (id),
  CONSTRAINT uq_tenant_payment_config_version UNIQUE (tenant_id, config_version),
  CONSTRAINT ck_tenant_payment_config_version CHECK (config_version >= 1),
  CONSTRAINT ck_tenant_payment_config_settings CHECK (jsonb_typeof(settings) = 'object')
);
CREATE INDEX ix_tenant_payment_config_effective ON ph19_payment.tenant_payment_config (tenant_id, effective_from DESC);
CREATE TRIGGER tg_tenant_payment_config_ro BEFORE UPDATE OR DELETE ON ph19_payment.tenant_payment_config FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_append_only();
CALL ph19_payment.p_enable_rls('ph19_payment.tenant_payment_config');
COMMENT ON TABLE ph19_payment.tenant_payment_config IS 'EN-19-22 Phiên bản cấu hình thanh toán của tenant (FR-19-063, 064). Bất biến; phiên bản hiệu lực là effective_from lớn nhất ≤ now(). Khóa settings là tham số 19.* của FRS §7.1.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.tenant_payment_config CASCADE;

-- @changeset ph19-1010-stats-hourly
CREATE TABLE ph19_payment.payment_stats_hourly (
  tenant_id         varchar(16)   NOT NULL,
  hour_vn           timestamp     NOT NULL,
  provider_id       uuid          NOT NULL,
  service_id        uuid          NOT NULL,
  partner_id        uuid          NOT NULL,
  status            varchar(20)   NOT NULL,
  txn_count         bigint        NOT NULL DEFAULT 0,
  amount            numeric(21,0) NOT NULL DEFAULT 0,
  refunded_amount   numeric(21,0) NOT NULL DEFAULT 0,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_payment_stats_hourly PRIMARY KEY (tenant_id, hour_vn, provider_id, service_id, partner_id, status),
  CONSTRAINT ck_payment_stats_hourly_hour CHECK (date_trunc('hour', hour_vn) = hour_vn)
);
CREATE INDEX ix_payment_stats_hourly_range ON ph19_payment.payment_stats_hourly (tenant_id, hour_vn);
CALL ph19_payment.p_enable_rls('ph19_payment.payment_stats_hourly');
COMMENT ON TABLE ph19_payment.payment_stats_hourly IS 'Số liệu tổng hợp theo giờ Việt Nam (SDD §8.3, NFR-19-006). StatsAggregator cộng dồn bằng INSERT … ON CONFLICT DO UPDATE; không tính giao dịch thử, bóng.';
COMMENT ON COLUMN ph19_payment.payment_stats_hourly.hour_vn IS 'Đầu giờ theo Asia/Ho_Chi_Minh, không múi giờ (T-TS giờ địa phương), để gộp ngày, tháng không phụ thuộc phiên.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.payment_stats_hourly CASCADE;

-- @changeset ph19-1020-stats-cursor
CREATE TABLE ph19_payment.stats_cursor (
  tenant_id         varchar(16)   NOT NULL,
  last_event_id     uuid,
  last_occurred_at  timestamptz,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_stats_cursor PRIMARY KEY (tenant_id)
);
CALL ph19_payment.p_enable_rls('ph19_payment.stats_cursor');
COMMENT ON TABLE ph19_payment.stats_cursor IS 'Con trỏ outbox cuối StatsAggregator đã cộng dồn.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.stats_cursor CASCADE;

-- @changeset ph19-1030-legacy-mapping
CREATE TABLE ph19_payment.legacy_mapping (
  tenant_id         varchar(16)   NOT NULL,
  legacy_table      varchar(64)   NOT NULL,
  legacy_key        varchar(255)  NOT NULL,
  target_type       varchar(32)   NOT NULL,
  target_id         uuid          NOT NULL,
  source_hash       varchar(64)   NOT NULL,
  job_id            uuid          NOT NULL,
  first_imported_at timestamptz   NOT NULL DEFAULT now(),
  last_imported_at  timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_legacy_mapping PRIMARY KEY (tenant_id, legacy_table, legacy_key),
  CONSTRAINT fk_legacy_mapping_job FOREIGN KEY (job_id, tenant_id) REFERENCES ph19_payment.background_job (id, tenant_id),
  CONSTRAINT ck_legacy_mapping_table CHECK (legacy_table IN ('payment_provider', 'payment_service_group', 'payment_service', 'payment_partner', 'payment_transaction')),
  CONSTRAINT ck_legacy_mapping_target CHECK (target_type IN ('PROVIDER', 'SERVICE_GROUP', 'SERVICE', 'PARTNER', 'TRANSACTION', 'REFUND'))
);
CREATE INDEX ix_legacy_mapping_target ON ph19_payment.legacy_mapping (tenant_id, target_type, target_id);
CREATE OR REPLACE FUNCTION ph19_payment.tg_legacy_mapping_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' OR NEW.target_id IS DISTINCT FROM OLD.target_id OR NEW.target_type IS DISTINCT FROM OLD.target_type THEN
    RAISE EXCEPTION 'legacy_mapping: không đổi đích, không xóa (FR-19-065)' USING ERRCODE = 'P1930';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_legacy_mapping_guard BEFORE UPDATE OR DELETE ON ph19_payment.legacy_mapping FOR EACH ROW EXECUTE FUNCTION ph19_payment.tg_legacy_mapping_guard();
CALL ph19_payment.p_enable_rls('ph19_payment.legacy_mapping');
COMMENT ON TABLE ph19_payment.legacy_mapping IS 'EN-19-25 Ánh xạ khóa hệ cũ → bản ghi mới (FR-19-065, 068). Chạy lại: cùng khóa thì cập nhật source_hash, last_imported_at, job_id; không bao giờ đổi đích.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.legacy_mapping CASCADE;

-- @changeset ph19-1040-shedlock
CREATE TABLE ph19_payment.shedlock (
  name        varchar(64)   NOT NULL,
  lock_until  timestamptz   NOT NULL,
  locked_at   timestamptz   NOT NULL,
  locked_by   varchar(255)  NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph19_payment.shedlock IS 'Khóa tác vụ lịch của ShedLock. Không có tenant_id (tên khóa chứa mã tenant, ví dụ recon-session:T68); không bật RLS.';
-- @rollback DROP TABLE IF EXISTS ph19_payment.shedlock;

-- @file 19-0110-seed.sql
-- @changeset ph19-1100-fn-seed-paygov-mapping splitStatements:false
-- Nạp bảng ánh xạ PayGov mặc định (giả định, SDD §7.3) phiên bản 1 cho một NCC. Gọi khi khởi tạo tenant (FR-19-064)
-- hoặc khi tạo NCC adapter PAYGOV; chạy trong phiên đã SET app.tenant_id.
CREATE OR REPLACE FUNCTION ph19_payment.seed_paygov_mapping(p_provider uuid, p_actor varchar)
  RETURNS integer LANGUAGE plpgsql AS $f$
DECLARE
  n integer;
  t varchar := current_setting('app.tenant_id', false);
BEGIN
  IF EXISTS (SELECT 1 FROM ph19_payment.provider_result_mapping WHERE provider_id = p_provider) THEN
    RETURN 0;
  END IF;
  INSERT INTO ph19_payment.provider_result_mapping
    (id, tenant_id, provider_id, mapping_version, operation, provider_code, outcome, is_final, reason_code, message_vi, status, created_by)
  SELECT gen_random_uuid(), t, p_provider, 1, v.op, v.code, v.outcome, v.fin, v.reason, v.msg, 'ACTIVE', p_actor
  FROM (VALUES
    ('INIT','00','SUCCEEDED',true ,NULL,'Đã tạo yêu cầu thanh toán'),
    ('INIT','09','FAILED'   ,true ,'SERVICE_NOT_REGISTERED','Dịch vụ chưa đăng ký với nền tảng thanh toán'),
    ('INIT','11','FAILED'   ,true ,'INVALID_REQUEST','Yêu cầu thanh toán không hợp lệ'),
    ('INIT','13','FAILED'   ,true ,'DUPLICATE_ORDER','Mã giao dịch đã tồn tại ở nền tảng thanh toán'),
    ('INIT','97','UNKNOWN'  ,false,'SIGNATURE_ERROR','Lỗi chữ ký, chờ xác minh'),
    ('INIT','99','UNKNOWN'  ,false,'PROVIDER_ERROR','Lỗi của nền tảng thanh toán, chờ xác minh'),
    ('IPN','00','SUCCEEDED' ,true ,NULL,'Thanh toán thành công'),
    ('IPN','01','PENDING'   ,false,'PROCESSING','Giao dịch đang được xử lý'),
    ('IPN','02','FAILED'    ,true ,'PAYMENT_FAILED','Thanh toán không thành công'),
    ('IPN','04','FAILED'    ,true ,'PAYER_CANCELLED','Người nộp hủy thanh toán'),
    ('IPN','05','FAILED'    ,true ,'PAYMENT_TIMEOUT','Quá thời gian thanh toán'),
    ('IPN','06','FAILED'    ,true ,'INSUFFICIENT_FUNDS','Tài khoản không đủ số dư'),
    ('IPN','07','UNKNOWN'   ,false,'SUSPECTED_FRAUD','Giao dịch nghi vấn, chờ xác minh'),
    ('QUERY','00','SUCCEEDED',true ,NULL,'Thanh toán thành công'),
    ('QUERY','01','PENDING' ,false,'PROCESSING','Giao dịch đang được xử lý'),
    ('QUERY','02','FAILED'  ,true ,'PAYMENT_FAILED','Thanh toán không thành công'),
    ('QUERY','04','FAILED'  ,true ,'PAYER_CANCELLED','Người nộp hủy thanh toán'),
    ('QUERY','05','FAILED'  ,true ,'PAYMENT_TIMEOUT','Quá thời gian thanh toán'),
    ('QUERY','06','FAILED'  ,true ,'INSUFFICIENT_FUNDS','Tài khoản không đủ số dư'),
    ('QUERY','07','UNKNOWN' ,false,'SUSPECTED_FRAUD','Giao dịch nghi vấn, chờ xác minh'),
    ('QUERY','91','PENDING' ,false,'NOT_FOUND_AT_PROVIDER','Nền tảng chưa ghi nhận giao dịch'),
    ('QUERY','99','UNKNOWN' ,false,'PROVIDER_ERROR','Lỗi của nền tảng thanh toán'),
    ('CANCEL','00','SUCCEEDED',true,NULL,'Đã hủy tại nền tảng'),
    ('REFUND','00','SUCCEEDED',true,NULL,'Hoàn tiền thành công'),
    ('REFUND','01','PENDING',false,'REFUND_PROCESSING','Đang xử lý hoàn tiền'),
    ('REFUND','02','FAILED' ,true ,'REFUND_FAILED','Hoàn tiền không thành công'),
    ('REFUND_IPN','00','SUCCEEDED',true,NULL,'Hoàn tiền thành công'),
    ('REFUND_IPN','01','PENDING',false,'REFUND_PROCESSING','Đang xử lý hoàn tiền'),
    ('REFUND_IPN','02','FAILED' ,true ,'REFUND_FAILED','Hoàn tiền không thành công'),
    ('RECON','00','SUCCEEDED',true ,NULL,'Dòng đối soát thành công'),
    ('RECON','02','FAILED'  ,true ,'PAYMENT_FAILED','Dòng đối soát thất bại')
  ) AS v(op, code, outcome, fin, reason, msg);
  GET DIAGNOSTICS n = ROW_COUNT;
  UPDATE ph19_payment.payment_provider SET result_mapping_version = 1, updated_by = p_actor WHERE id = p_provider;
  RETURN n;
END
$f$;
COMMENT ON FUNCTION ph19_payment.seed_paygov_mapping(uuid, varchar) IS 'Nạp 31 dòng ánh xạ PayGov mặc định (giả định, SDD §7.3; thay khi có trả lời OQ-19-05). Bỏ qua nếu NCC đã có ánh xạ.';
-- @rollback DROP FUNCTION IF EXISTS ph19_payment.seed_paygov_mapping(uuid, varchar);

-- @file 19-0120-grants.sql
-- @changeset ph19-1200-grants
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph19_payment TO ph19_app;
REVOKE UPDATE, DELETE ON ph19_payment.transaction_event, ph19_payment.integration_log, ph19_payment.reconciliation_item,
  ph19_payment.transaction_adjustment, ph19_payment.transaction_code_index, ph19_payment.tenant_payment_config FROM ph19_app;
REVOKE DELETE ON ph19_payment.callback_inbox, ph19_payment.discrepancy, ph19_payment.legacy_mapping, ph19_payment.approval_request,
  ph19_payment.refund_request, ph19_payment.payment_transaction, ph19_payment.payment_provider, ph19_payment.payment_partner FROM ph19_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph19_payment TO ph19_readonly;
REVOKE SELECT ON ph19_payment.provider_credential, ph19_payment.idempotency_record, ph19_payment.shedlock, ph19_payment.callback_route FROM ph19_readonly;
GRANT EXECUTE ON FUNCTION ph19_payment.append_discrepancy_note(uuid, varchar, varchar, uuid[]), ph19_payment.seed_paygov_mapping(uuid, varchar) TO ph19_app;
-- @rollback REVOKE ALL ON ALL TABLES IN SCHEMA ph19_payment FROM ph19_app, ph19_readonly;

RESET ROLE;
RESET app.tenant_id;
