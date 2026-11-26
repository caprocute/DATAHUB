-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam
-- Tệp 03: liên kết định danh ngoài, client HTTT, tài khoản dịch vụ, danh sách chặn,
--         nút cổng, realm, sáp nhập (nhóm FR-12-C, D, E; EN-12-08…10, 18…20)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- =============================================================================

\set ON_ERROR_STOP on
RESET ROLE;
SET ROLE ph12_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 12-0040-federation.sql
-- @changeset ph12-0400-fn-checks splitStatements:false
-- Hàm kiểm tra dùng trong CHECK: danh sách URL chuyển hướng, danh sách scope.
CREATE OR REPLACE FUNCTION ph12_iam.f_urls_ok(p_urls text[]) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT p_urls IS NOT NULL AND cardinality(p_urls) BETWEEN 1 AND 20
     AND NOT EXISTS (SELECT 1 FROM unnest(p_urls) u WHERE u !~ '^https://[^*[:space:]]+$' OR char_length(u) > 2000)
$f$;
COMMENT ON FUNCTION ph12_iam.f_urls_ok(text[]) IS 'true nếu mọi URL là https, không ký tự đại diện, không khoảng trắng (SAML ACS, redirect URI: FR-12-025, ERR-12-033).';
CREATE OR REPLACE FUNCTION ph12_iam.f_scopes_ok(p_scopes text[]) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT p_scopes IS NOT NULL AND cardinality(p_scopes) BETWEEN 1 AND 200
     AND NOT EXISTS (SELECT 1 FROM unnest(p_scopes) s WHERE s !~ '^[a-z][a-z0-9-]*:[A-Za-z0-9:._*-]{1,200}$')
$f$;
COMMENT ON FUNCTION ph12_iam.f_scopes_ok(text[]) IS 'true nếu mọi scope có dạng {loại}:{giá trị}, ví dụ iam:decide, event:replay (scope máy nội bộ, BR-12-025).';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.f_scopes_ok(text[]); DROP FUNCTION IF EXISTS ph12_iam.f_urls_ok(text[]);

-- @changeset ph12-0410-federation
CREATE TABLE ph12_iam.federation (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  code               varchar(40)   NOT NULL,
  name               varchar(255)  NOT NULL,
  kind               varchar(4)    NOT NULL,
  url                varchar(2048) NOT NULL,
  base_dn            varchar(512)  NOT NULL,
  user_filter        varchar(512),
  bind_dn            varchar(512)  NOT NULL,
  secret_ref         varchar(255)  NOT NULL,
  ca_ref             varchar(255),
  attribute_map      jsonb         NOT NULL DEFAULT '{}',
  edit_mode          varchar(10)   NOT NULL DEFAULT 'READ_ONLY',
  force_mfa          boolean       NOT NULL DEFAULT false,
  sync_changed_hours smallint      NOT NULL DEFAULT 4,
  state              varchar(16)   NOT NULL DEFAULT 'DRAFT',
  test_result        jsonb         NOT NULL DEFAULT '{}',
  tests_passed_at    timestamptz,
  proposed_by        varchar(64),
  approved_by        varchar(64),
  approved_at        timestamptz,
  last_sync_at       timestamptz,
  last_sync_status   varchar(8),
  last_sync_users    integer,
  disabled_reason    varchar(1000),
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_federation PRIMARY KEY (id),
  CONSTRAINT uq_federation_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_federation_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_federation_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_federation_code CHECK (code ~ '^[a-z][a-z0-9-]{2,39}$'),
  CONSTRAINT ck_federation_kind CHECK (kind IN ('LDAP', 'AD')),
  CONSTRAINT ck_federation_ldaps CHECK (url ~ '^ldaps://[^/[:space:]]+(:[0-9]{2,5})?/?$'),
  CONSTRAINT ck_federation_secret_ref CHECK (secret_ref ~ '^kv/dh/[a-z0-9]+/iam/ldap/[a-z][a-z0-9-]+$'),
  CONSTRAINT ck_federation_attr CHECK (jsonb_typeof(attribute_map) = 'object' AND NOT ph12_iam.f_json_has_secret_key(attribute_map)),
  CONSTRAINT ck_federation_edit_mode CHECK (edit_mode = 'READ_ONLY'),
  CONSTRAINT ck_federation_sync_hours CHECK (sync_changed_hours BETWEEN 1 AND 24),
  CONSTRAINT ck_federation_state CHECK (state IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'DISABLED')),
  CONSTRAINT ck_federation_tests CHECK (state IN ('DRAFT', 'DISABLED') OR tests_passed_at IS NOT NULL),
  CONSTRAINT ck_federation_four_eyes CHECK (approved_by IS NULL OR approved_by IS DISTINCT FROM proposed_by),
  CONSTRAINT ck_federation_active CHECK (state <> 'ACTIVE' OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_federation_sync_status CHECK (last_sync_status IS NULL OR last_sync_status IN ('OK', 'PARTIAL', 'FAILED'))
);
CREATE INDEX ix_federation_state ON ph12_iam.federation (tenant_id, state);
CREATE TRIGGER tg_federation_touch BEFORE UPDATE ON ph12_iam.federation FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.federation', 'P');
ALTER TABLE ph12_iam.user_account ADD CONSTRAINT fk_user_account_federation
  FOREIGN KEY (federation_id, tenant_id) REFERENCES ph12_iam.federation (id, tenant_id);
COMMENT ON TABLE ph12_iam.federation IS 'EN-12-18 (phần LDAP, AD) Liên kết thư mục của tỉnh (FR-12-026): DRAFT, PENDING_APPROVAL, ACTIVE, DISABLED. Chỉ LDAPS, chỉ-đọc, ba kiểm tra (kết nối, bind, mẫu 5 người dùng) đạt mới gửi duyệt, SO khác TA duyệt (PERM-12-approve, BR-12-029).';
COMMENT ON COLUMN ph12_iam.federation.secret_ref IS 'Đường OpenBao kv/dh/{tenant viết thường}/iam/ldap/{code} của bí mật bind; ghi một chiều, không lưu giá trị (BR-12-045).';
COMMENT ON COLUMN ph12_iam.federation.test_result IS 'Kết quả ba kiểm tra {connect, bind, sample} kèm thời điểm; không có mật khẩu hay bản ghi người dùng.';
COMMENT ON COLUMN ph12_iam.federation.force_mfa IS 'true: mọi người dùng nguồn này có mfa_level >= 2, dùng khi chính sách mật khẩu LDAP yếu hơn SEC-22 (đề xuất Q12-11).';
-- @rollback ALTER TABLE ph12_iam.user_account DROP CONSTRAINT IF EXISTS fk_user_account_federation; DROP TABLE IF EXISTS ph12_iam.federation CASCADE;

-- @changeset ph12-0420-saml-client
CREATE TABLE ph12_iam.saml_client (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  entity_id           varchar(512)  NOT NULL,
  name                varchar(255)  NOT NULL,
  acs_urls            text[]        NOT NULL,
  metadata_ref        varchar(512),
  metadata_sha256     char(64),
  name_id_format      varchar(16)   NOT NULL DEFAULT 'persistent',
  signature_algorithm varchar(12)   NOT NULL DEFAULT 'RSA_SHA256',
  assertion_lifespan_s integer      NOT NULL DEFAULT 300,
  keycloak_client_id  uuid,
  state               varchar(16)   NOT NULL DEFAULT 'DRAFT',
  proposed_by         varchar(64),
  approved_by         varchar(64),
  approved_at         timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_saml_client PRIMARY KEY (id),
  CONSTRAINT uq_saml_client_entity UNIQUE (tenant_id, entity_id),
  CONSTRAINT ck_saml_client_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_saml_client_urls CHECK (ph12_iam.f_urls_ok(acs_urls)),
  CONSTRAINT ck_saml_client_hash CHECK (metadata_sha256 IS NULL OR metadata_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_saml_client_nameid CHECK (name_id_format = 'persistent'),
  CONSTRAINT ck_saml_client_sig CHECK (signature_algorithm IN ('RSA_SHA256', 'RSA_SHA512')),
  CONSTRAINT ck_saml_client_lifespan CHECK (assertion_lifespan_s BETWEEN 60 AND 300),
  CONSTRAINT ck_saml_client_state CHECK (state IN ('DRAFT', 'PENDING_APPROVAL', 'ENABLED', 'DISABLED')),
  CONSTRAINT ck_saml_client_four_eyes CHECK (approved_by IS NULL OR approved_by IS DISTINCT FROM proposed_by),
  CONSTRAINT ck_saml_client_enabled CHECK (state <> 'ENABLED' OR (approved_by IS NOT NULL AND keycloak_client_id IS NOT NULL))
);
CREATE TRIGGER tg_saml_client_touch BEFORE UPDATE ON ph12_iam.saml_client FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.saml_client', 'P');
COMMENT ON TABLE ph12_iam.saml_client IS 'EN-12-18 (phần SAML) Ứng dụng SAML 2 cũ dùng chung phiên SSO với OIDC (FR-12-025). Siêu dữ liệu nhận bằng tệp tải lên, không tự tải URL (SSRF, SEC-45); redirect URI https, cấm ký tự đại diện; chữ ký SHA-256 bắt buộc; SO duyệt mới ENABLED.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.saml_client CASCADE;

-- @changeset ph12-0430-vneid-link
CREATE TABLE ph12_iam.vneid_link (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  user_id          uuid          NOT NULL,
  subject_hash     char(64)      NOT NULL,
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  linked_at        timestamptz   NOT NULL DEFAULT now(),
  unlinked_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_vneid_link PRIMARY KEY (id),
  CONSTRAINT fk_vneid_link_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_vneid_link_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_vneid_link_hash CHECK (subject_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_vneid_link_state CHECK (state IN ('ACTIVE', 'UNLINKED') AND (state = 'UNLINKED') = (unlinked_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_vneid_link_subject ON ph12_iam.vneid_link (tenant_id, subject_hash) WHERE state = 'ACTIVE';
CREATE UNIQUE INDEX uq_vneid_link_user ON ph12_iam.vneid_link (tenant_id, user_id) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_vneid_link_touch BEFORE UPDATE ON ph12_iam.vneid_link FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.vneid_link', 'P');
COMMENT ON TABLE ph12_iam.vneid_link IS 'EN-12-18 (phần VNeID) Liên kết người dùng với định danh điện tử, Đợt 2 (FR-12-028). Chỉ lưu băm HMAC-SHA256 có khóa của định danh, không lưu số định danh rõ (BR-12-045, Luật BVDLCN); chỉ liên kết vào tài khoản có sẵn, không tự tạo (BR-12-029); một định danh một tài khoản (ERR-12-034).';
COMMENT ON COLUMN ph12_iam.vneid_link.subject_hash IS 'HMAC-SHA256 hex của sub do VNeID cấp, khóa ở OpenBao (kv/dh/{tenant}/iam/vneid-hmac); đạt ở Q12-02.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.vneid_link CASCADE;

-- @file 12-0050-client.sql
-- @changeset ph12-0500-client
CREATE TABLE ph12_iam.client (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  client_id            varchar(64)   NOT NULL,
  kind                 varchar(8)    NOT NULL DEFAULT 'SYSTEM',
  system_code          varchar(64),
  app_ref              varchar(64),
  org_code             varchar(64)   NOT NULL,
  name                 varchar(255)  NOT NULL,
  auth_method          varchar(16)   NOT NULL,
  contract_level       varchar(10)   NOT NULL,
  state                varchar(12)   NOT NULL DEFAULT 'PROVISIONING',
  credential_ready     boolean       NOT NULL DEFAULT false,
  suspended_reason     varchar(1000),
  suspended_auto       boolean       NOT NULL DEFAULT false,
  revoked_at           timestamptz,
  revoked_reason       varchar(1000),
  last_used_at         timestamptz,
  secret_expires_at    timestamptz,
  cert_thumbprint      char(64),
  keycloak_client_id   uuid,
  provision_key        varchar(128),
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  updated_by           varchar(64)   NOT NULL,
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_client PRIMARY KEY (id),
  CONSTRAINT uq_client_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_client_client_id UNIQUE (tenant_id, client_id),
  CONSTRAINT ck_client_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_client_client_id CHECK (client_id ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_client_kind CHECK (kind IN ('SYSTEM', 'SANDBOX')),
  CONSTRAINT ck_client_owner CHECK ((kind = 'SYSTEM' AND system_code IS NOT NULL AND app_ref IS NULL) OR (kind = 'SANDBOX' AND app_ref IS NOT NULL AND system_code IS NULL)),
  CONSTRAINT ck_client_sandbox_level CHECK (kind <> 'SANDBOX' OR contract_level = 'PUBLIC'),
  CONSTRAINT ck_client_auth CHECK (auth_method IN ('MTLS', 'PRIVATE_KEY_JWT', 'CLIENT_SECRET')),
  CONSTRAINT ck_client_level CHECK (contract_level IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_client_level_auth CHECK (contract_level IN ('PUBLIC', 'INTERNAL') OR auth_method <> 'CLIENT_SECRET'),
  CONSTRAINT ck_client_sensitive_mtls CHECK (contract_level <> 'SENSITIVE' OR auth_method = 'MTLS'),
  CONSTRAINT ck_client_state CHECK (state IN ('PROVISIONING', 'ENABLED', 'SUSPENDED', 'REVOKED', 'FAILED')),
  CONSTRAINT ck_client_suspended CHECK (state <> 'SUSPENDED' OR suspended_reason IS NOT NULL),
  CONSTRAINT ck_client_revoked CHECK ((state = 'REVOKED') = (revoked_at IS NOT NULL) AND (state <> 'REVOKED' OR revoked_reason IS NOT NULL)),
  CONSTRAINT ck_client_enabled CHECK (state NOT IN ('ENABLED', 'SUSPENDED') OR keycloak_client_id IS NOT NULL),
  CONSTRAINT ck_client_thumbprint CHECK (cert_thumbprint IS NULL OR cert_thumbprint ~ '^[0-9a-f]{64}$')
);
CREATE UNIQUE INDEX uq_client_system ON ph12_iam.client (tenant_id, system_code) WHERE system_code IS NOT NULL AND state <> 'REVOKED';
CREATE UNIQUE INDEX uq_client_provision_key ON ph12_iam.client (tenant_id, provision_key) WHERE provision_key IS NOT NULL;
CREATE INDEX ix_client_state ON ph12_iam.client (tenant_id, state, auth_method);
CREATE INDEX ix_client_inactivity ON ph12_iam.client (tenant_id, last_used_at) WHERE state = 'ENABLED';
CREATE INDEX ix_client_org ON ph12_iam.client (tenant_id, org_code);
CREATE TRIGGER tg_client_touch BEFORE UPDATE ON ph12_iam.client FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CREATE TRIGGER tg_client_no_delete BEFORE DELETE ON ph12_iam.client FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_no_delete();
CALL ph12_iam.p_enable_rls('ph12_iam.client', 'P');
COMMENT ON TABLE ph12_iam.client IS 'EN-12-08 Danh tính máy của một HTTT (kind SYSTEM, cấp qua PH-01) hoặc ứng dụng sandbox (SANDBOX, PH-15, Đợt 2). Một client đang sống cho mỗi HTTT (BR-12-024, ERR-12-018); phương thức xác thực không thấp hơn mức hợp đồng: Hạn chế trở lên cấm client_secret, Nhạy cảm bắt buộc mTLS. Không xóa vật lý; REVOKED vĩnh viễn, mã client không dùng lại.';
COMMENT ON COLUMN ph12_iam.client.client_id IS 'clientId ở Keycloak: mã HTTT viết thường; client cấp lại sau khi REVOKED mang hậu tố -r{n} vì mã cũ không dùng lại (Q12-53).';
COMMENT ON COLUMN ph12_iam.client.system_code IS 'Mã HTTT ở PH-01; không khóa ngoại vì khác schema.';
COMMENT ON COLUMN ph12_iam.client.credential_ready IS 'false khi mTLS hoặc private_key_jwt chưa có chứng thư, khóa công khai: client ENABLED nhưng chưa cấp token được (FR-12-033).';
COMMENT ON COLUMN ph12_iam.client.cert_thumbprint IS 'SHA-256 hex của chứng thư hiện hành, để APISIX đối chiếu cnf.x5t#S256 (EVT-12-08); bản gốc ở client_credential.';
COMMENT ON COLUMN ph12_iam.client.provision_key IS 'Idempotency-Key của lời gọi cấp client từ saga PH-01; cùng khóa thì tìm lại client dở (SDD §4.8).';
COMMENT ON COLUMN ph12_iam.client.suspended_auto IS 'true khi hệ thống tự tạm ngừng vì 90 ngày không gọi: tiếp tục cần đầu mối xác nhận (ERR-12-020).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.client CASCADE;

-- @changeset ph12-0510-client-scope
CREATE TABLE ph12_iam.client_scope (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  client_pk        uuid          NOT NULL,
  scope            varchar(255)  NOT NULL,
  source           varchar(8)    NOT NULL,
  source_ref       varchar(128),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_client_scope PRIMARY KEY (id),
  CONSTRAINT uq_client_scope UNIQUE (client_pk, scope),
  CONSTRAINT fk_client_scope_client FOREIGN KEY (client_pk, tenant_id) REFERENCES ph12_iam.client (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_client_scope_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_client_scope_source CHECK (source IN ('PH-02', 'PH-07', 'PH-09', 'PH-10', 'PH-19', 'INTERNAL')),
  CONSTRAINT ck_client_scope_prefix CHECK (
    (source = 'PH-02' AND scope ~ '^api:[^:[:space:]]+:[^:[:space:]]+$')
    OR (source = 'PH-09' AND scope ~ '^purpose:[a-z0-9_.-]+$')
    OR (source = 'PH-10' AND scope ~ '^topic:[a-z0-9._-]+:(publish|subscribe)$')
    OR (source = 'PH-07' AND scope ~ '^rdm:[a-z-]+$')
    OR (source = 'PH-19' AND scope ~ '^payment:[a-z-]+$')
    OR (source = 'INTERNAL' AND scope ~ '^(iam|event):[a-z-]+$'))
);
CREATE INDEX ix_client_scope_source ON ph12_iam.client_scope (tenant_id, client_pk, source);
CALL ph12_iam.p_enable_rls('ph12_iam.client_scope', 'P');
COMMENT ON TABLE ph12_iam.client_scope IS 'EN-12-09 Scope của client, mỗi dòng gắn nguồn duyệt (FR-12-036). CHECK bảo đảm mỗi nguồn chỉ đặt đúng loại scope của mình: PH-02 api:, PH-09 purpose:, PH-10 topic:, PH-07 rdm:, PH-19 payment:; scope iam:, event: là INTERNAL (BR-12-025, ERR-12-019). Thay theo nguồn bằng ScopeSynchronizer.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.client_scope CASCADE;

-- @changeset ph12-0520-client-credential
CREATE TABLE ph12_iam.client_credential (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  client_pk        uuid          NOT NULL,
  kind             varchar(8)    NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'ACTIVE',
  thumbprint       char(64),
  subject_dn       varchar(1024),
  kid              varchar(128),
  key_alg          varchar(16),
  not_before       timestamptz,
  not_after        timestamptz,
  wrap_accessor    varchar(128),
  transition_until timestamptz,
  retired_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_client_credential PRIMARY KEY (id),
  CONSTRAINT fk_client_credential_client FOREIGN KEY (client_pk, tenant_id) REFERENCES ph12_iam.client (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_client_credential_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_client_credential_kind CHECK (kind IN ('CERT', 'JWKS_KEY', 'SECRET')),
  CONSTRAINT ck_client_credential_state CHECK (state IN ('ACTIVE', 'TRANSITION', 'RETIRED') AND (state = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_client_credential_cert CHECK (kind <> 'CERT' OR (thumbprint ~ '^[0-9a-f]{64}$' AND subject_dn IS NOT NULL AND not_before IS NOT NULL AND not_after > not_before)),
  CONSTRAINT ck_client_credential_jwks CHECK (kind <> 'JWKS_KEY' OR (kid IS NOT NULL AND key_alg IN ('ES256', 'ES384', 'RS256'))),
  CONSTRAINT ck_client_credential_secret CHECK (kind <> 'SECRET' OR (not_after IS NOT NULL AND not_after <= created_at + interval '180 days' AND thumbprint IS NULL)),
  CONSTRAINT ck_client_credential_transition CHECK (state <> 'TRANSITION' OR transition_until IS NOT NULL)
);
CREATE UNIQUE INDEX uq_client_credential_current ON ph12_iam.client_credential (client_pk, kind, state) WHERE state IN ('ACTIVE', 'TRANSITION');
CREATE UNIQUE INDEX uq_client_credential_thumb ON ph12_iam.client_credential (tenant_id, thumbprint) WHERE thumbprint IS NOT NULL AND state <> 'RETIRED';
CREATE INDEX ix_client_credential_expiry ON ph12_iam.client_credential (not_after) WHERE state <> 'RETIRED';
CREATE TRIGGER tg_client_credential_touch BEFORE UPDATE ON ph12_iam.client_credential FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.client_credential', 'P');
COMMENT ON TABLE ph12_iam.client_credential IS 'Siêu dữ liệu thông tin xác thực của client: chứng thư mTLS (dấu vân tay), khóa công khai (kid), bí mật chia sẻ (chỉ hạn và wrap_accessor). KHÔNG chứa bí mật hay khóa riêng (BR-12-023, NFR-12-020). Bí mật hết hạn ≤ 180 ngày; hai dòng ACTIVE và TRANSITION cùng loại trong lúc xoay (FR-12-034).';
COMMENT ON COLUMN ph12_iam.client_credential.wrap_accessor IS 'Accessor của token bọc OpenBao (sys/wrapping/lookup) để tra tình trạng giao bí mật mà không mở được bí mật; không phải wrappingToken.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.client_credential CASCADE;

-- @changeset ph12-0530-service-account
CREATE TABLE ph12_iam.service_account (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  account_code     varchar(48)   NOT NULL,
  du_code          varchar(32)   NOT NULL,
  description      varchar(1000),
  scopes           text[]        NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'PENDING',
  declaration_ref  varchar(255)  NOT NULL,
  approved_by      varchar(64),
  kid              varchar(128),
  key_rotated_at   timestamptz,
  rotate_due_at    timestamptz,
  keycloak_client_id uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_account PRIMARY KEY (id),
  CONSTRAINT uq_service_account_code UNIQUE (tenant_id, account_code),
  CONSTRAINT ck_service_account_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_service_account_code CHECK (account_code ~ '^[a-z][a-z0-9-]{2,47}$'),
  CONSTRAINT ck_service_account_du CHECK (du_code ~ '^(dh-[a-z]+|apisix|keycloak|opa)$'),
  CONSTRAINT ck_service_account_scopes CHECK (ph12_iam.f_scopes_ok(scopes)),
  CONSTRAINT ck_service_account_state CHECK (state IN ('PENDING', 'ENABLED', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_service_account_enabled CHECK (state = 'PENDING' OR (approved_by IS NOT NULL AND approved_by <> created_by)),
  CONSTRAINT ck_service_account_rotation CHECK (rotate_due_at IS NULL OR key_rotated_at IS NULL OR rotate_due_at <= key_rotated_at + interval '90 days')
);
CREATE TRIGGER tg_service_account_touch BEFORE UPDATE ON ph12_iam.service_account FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.service_account', 'P');
COMMENT ON TABLE ph12_iam.service_account IS 'EN-12-10 Tài khoản dịch vụ của đơn vị triển khai ở realm dh-platform (FR-12-037), tenant PLATFORM. Khai báo ở kho cấu hình qua yêu cầu hợp nhất có người duyệt thứ hai; xác thực private_key_jwt bằng khóa ký ở OpenBao transit (khóa riêng không rời OpenBao), xoay 90 ngày.';
COMMENT ON COLUMN ph12_iam.service_account.scopes IS 'Scope máy nội bộ: iam:client-provision, iam:dev-client, iam:realm-provision, iam:revocation-read, iam:directory-read, iam:decide, iam:policy-data-read và scope nội bộ của PH khác (event:*).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.service_account CASCADE;

-- @file 12-0060-revocation.sql
-- @changeset ph12-0600-revocation-feed-version
CREATE TABLE ph12_iam.revocation_feed_version (
  id               smallint      NOT NULL,
  version          bigint        NOT NULL DEFAULT 0,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_revocation_feed_version PRIMARY KEY (id),
  CONSTRAINT ck_revocation_feed_version_single CHECK (id = 1)
);
INSERT INTO ph12_iam.revocation_feed_version (id, version) VALUES (1, 0);
COMMENT ON TABLE ph12_iam.revocation_feed_version IS 'Bộ đếm phiên bản toàn cục của danh sách chặn (ETag của API-12-079). Một dòng duy nhất, không có tenant_id và không bật RLS vì chỉ là số thứ tự, không chứa dữ liệu nghiệp vụ; trigger của revocation_entry tăng sau mỗi thay đổi.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.revocation_feed_version;

-- @changeset ph12-0610-revocation-entry
CREATE TABLE ph12_iam.revocation_entry (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(6)    NOT NULL,
  value            varchar(128)  NOT NULL,
  not_before       timestamptz   NOT NULL DEFAULT now(),
  block_all        boolean       NOT NULL DEFAULT true,
  expires_at       timestamptz,
  reason           varchar(1000) NOT NULL,
  keycloak_confirmed_at timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_revocation_entry PRIMARY KEY (id),
  CONSTRAINT ck_revocation_entry_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_revocation_entry_kind CHECK (kind IN ('SUB', 'CLIENT', 'JTI')),
  CONSTRAINT ck_revocation_entry_value CHECK (char_length(value) BETWEEN 3 AND 128 AND value !~ '[[:space:]]'),
  CONSTRAINT ck_revocation_entry_reason CHECK (char_length(btrim(reason)) >= 5),
  CONSTRAINT ck_revocation_entry_expiry CHECK ((block_all AND expires_at IS NULL) OR (NOT block_all AND expires_at IS NOT NULL AND keycloak_confirmed_at IS NOT NULL)),
  CONSTRAINT ck_revocation_entry_no_self CHECK (kind <> 'SUB' OR value <> created_by)
);
CREATE UNIQUE INDEX uq_revocation_entry_blocking ON ph12_iam.revocation_entry (tenant_id, kind, value) WHERE block_all;
CREATE INDEX ix_revocation_entry_lookup ON ph12_iam.revocation_entry (tenant_id, kind, value, not_before DESC);
CREATE INDEX ix_revocation_entry_expiry ON ph12_iam.revocation_entry (expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX ix_revocation_entry_unconfirmed ON ph12_iam.revocation_entry (created_at) WHERE block_all;
CREATE TRIGGER tg_revocation_entry_touch BEFORE UPDATE ON ph12_iam.revocation_entry FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.revocation_entry', 'P');
COMMENT ON TABLE ph12_iam.revocation_entry IS 'EN-12-19 Danh sách chặn: SUB (người dùng, mọi token có iat < not_before), CLIENT (theo azp), JTI (một token, RFC 7009). Ghi TRƯỚC khi chạm Keycloak với block_all = true; khi Keycloak xác nhận hạ cờ và đặt hạn 330 giây (FR-12-040, BR-12-028, EVT-12-05). Hiệu lực tại cổng ≤ 60 giây (NFR-12-005).';
COMMENT ON COLUMN ph12_iam.revocation_entry.block_all IS 'true: từ chối mọi token của chủ thể bất kể iat vì Keycloak chưa xác nhận vô hiệu (chủ thể còn xin được token mới). Khi hạ cờ phải có expires_at và keycloak_confirmed_at.';
COMMENT ON COLUMN ph12_iam.revocation_entry.expires_at IS 'Hạn giữ sau khi Keycloak xác nhận = lúc xác nhận + 330 giây (token 300 giây cộng dung sai 30 giây); rỗng khi còn block_all.';
COMMENT ON COLUMN ph12_iam.revocation_entry.created_by IS 'Người thu hồi; với kind SUB khác chủ thể bị thu hồi (BR-12-033, ERR-12-013).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.revocation_entry CASCADE;

-- @changeset ph12-0615-fn-revocation-bump splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_revocation_bump() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  UPDATE ph12_iam.revocation_feed_version SET version = version + 1, updated_at = now() WHERE id = 1;
  RETURN NULL;
END
$f$;
CREATE TRIGGER tg_revocation_entry_bump AFTER INSERT OR UPDATE OR DELETE ON ph12_iam.revocation_entry
  FOR EACH STATEMENT EXECUTE FUNCTION ph12_iam.tg_revocation_bump();
COMMENT ON FUNCTION ph12_iam.tg_revocation_bump() IS 'Tăng phiên bản danh sách chặn sau mỗi lệnh ghi (cổng so If-None-Match với phiên bản này).';
-- @rollback DROP TRIGGER IF EXISTS tg_revocation_entry_bump ON ph12_iam.revocation_entry; DROP FUNCTION IF EXISTS ph12_iam.tg_revocation_bump();

-- @changeset ph12-0620-node-heartbeat
CREATE TABLE ph12_iam.node_heartbeat (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL DEFAULT 'COMMON',
  node_id            varchar(128)  NOT NULL,
  node_kind          varchar(8)    NOT NULL,
  applied_revocation bigint        NOT NULL DEFAULT 0,
  bundle_revisions   jsonb         NOT NULL DEFAULT '{}',
  first_seen_at      timestamptz   NOT NULL DEFAULT now(),
  last_seen_at       timestamptz   NOT NULL DEFAULT now(),
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_node_heartbeat PRIMARY KEY (id),
  CONSTRAINT uq_node_heartbeat_node UNIQUE (node_id),
  CONSTRAINT ck_node_heartbeat_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_node_heartbeat_kind CHECK (node_kind IN ('APISIX', 'DU', 'OPA')),
  CONSTRAINT ck_node_heartbeat_bundles CHECK (jsonb_typeof(bundle_revisions) = 'object')
);
CREATE INDEX ix_node_heartbeat_seen ON ph12_iam.node_heartbeat (node_kind, last_seen_at DESC);
CREATE TRIGGER tg_node_heartbeat_touch BEFORE UPDATE ON ph12_iam.node_heartbeat FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.node_heartbeat', 'S');
COMMENT ON TABLE ph12_iam.node_heartbeat IS 'Phiên bản danh sách chặn và bản gói mà từng nút cổng, DU, OPA đã áp (tiêu đề X-DH-Applied-Version, plugin status của OPA). Dùng chung (COMMON): quản trị tỉnh thấy "đã áp dụng ở n/m nút cổng"; chỉ phiên PLATFORM ghi. Nút im lặng quá 60 giây kể từ phiên bản mới thì cảnh báo nghiêm trọng.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.node_heartbeat CASCADE;

-- @file 12-0070-realm.sql
-- @changeset ph12-0700-realm-state
CREATE TABLE ph12_iam.realm_state (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  tenant_code           varchar(16)   NOT NULL,
  realm_name            varchar(40)   NOT NULL,
  state                 varchar(12)   NOT NULL DEFAULT 'PROVISIONING',
  template_version      varchar(32),
  git_commit            char(40),
  drift_status          varchar(8)    NOT NULL DEFAULT 'UNKNOWN',
  drift_fields          jsonb         NOT NULL DEFAULT '[]',
  baseline_hash         char(64),
  baseline_snapshot     jsonb,
  baseline_at           timestamptz,
  last_check_at         timestamptz,
  last_apply_at         timestamptz,
  hold_reason           varchar(1000),
  hold_by               varchar(64),
  hold_until            timestamptz,
  state_reason          varchar(1000),
  signing_key_rotated_at timestamptz,
  provisioned_at        timestamptz,
  deleted_at            timestamptz,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_realm_state PRIMARY KEY (id),
  CONSTRAINT uq_realm_state_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_realm_state_tenant UNIQUE (tenant_code),
  CONSTRAINT uq_realm_state_realm UNIQUE (realm_name),
  CONSTRAINT ck_realm_state_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_realm_state_code CHECK (tenant_code ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_realm_state_name CHECK (realm_name = ph12_iam.f_realm_name(tenant_code)),
  CONSTRAINT ck_realm_state_state CHECK (state IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'READ_ONLY', 'DELETED')),
  CONSTRAINT ck_realm_state_drift CHECK (drift_status IN ('UNKNOWN', 'IN_SYNC', 'DRIFTED', 'HELD') AND jsonb_typeof(drift_fields) = 'array'),
  CONSTRAINT ck_realm_state_hold CHECK ((drift_status = 'HELD') = (hold_reason IS NOT NULL AND hold_by IS NOT NULL AND hold_until IS NOT NULL)),
  CONSTRAINT ck_realm_state_commit CHECK (git_commit IS NULL OR git_commit ~ '^[0-9a-f]{40}$'),
  CONSTRAINT ck_realm_state_baseline CHECK (baseline_hash IS NULL OR baseline_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_realm_state_active CHECK (state = 'PROVISIONING' OR provisioned_at IS NOT NULL),
  CONSTRAINT ck_realm_state_deleted CHECK ((state = 'DELETED') = (deleted_at IS NOT NULL)),
  CONSTRAINT ck_realm_state_reason CHECK (state NOT IN ('SUSPENDED', 'READ_ONLY', 'DELETED') OR state_reason IS NOT NULL)
);
CREATE INDEX ix_realm_state_drift ON ph12_iam.realm_state (drift_status) WHERE drift_status IN ('DRIFTED', 'HELD');
CREATE TRIGGER tg_realm_state_touch BEFORE UPDATE ON ph12_iam.realm_state FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.realm_state', 'P');
COMMENT ON TABLE ph12_iam.realm_state IS 'EN-12-20 Trạng thái realm Keycloak của từng tenant (FR-12-041…043): PROVISIONING, ACTIVE, SUSPENDED, READ_ONLY, DELETED. Dữ liệu của nền tảng nên tenant_id luôn là PLATFORM, tenant mà realm phục vụ nằm ở tenant_code; chỉ PA (PERM-12-realm-admin) thao tác. Cấu hình bảo mật chỉ đổi qua GitOps (BR-12-038).';
COMMENT ON COLUMN ph12_iam.realm_state.baseline_snapshot IS 'Bản chụp chuẩn hóa (chỉ trường bảo mật cho phép) lập sau mỗi lần áp mẫu, dùng so lệch hằng giờ (SDD §4.10); không chứa bí mật hay người dùng.';
COMMENT ON COLUMN ph12_iam.realm_state.drift_status IS 'IN_SYNC khớp mẫu Git; DRIFTED lệch, tự áp lại sau 15 phút nếu 12.realm.auto-reconcile; HELD giữ tạm có lý do, người xác nhận và hạn.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.realm_state CASCADE;

-- @changeset ph12-0710-realm-provision-step
CREATE TABLE ph12_iam.realm_provision_step (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  realm_id         uuid          NOT NULL,
  step_code        varchar(24)   NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'RUNNING',
  idempotency_key  varchar(128)  NOT NULL,
  error_code       varchar(16),
  detail           jsonb         NOT NULL DEFAULT '{}',
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_realm_provision_step PRIMARY KEY (id),
  CONSTRAINT uq_realm_provision_step UNIQUE (realm_id, step_code),
  CONSTRAINT fk_realm_provision_step_realm FOREIGN KEY (realm_id, tenant_id) REFERENCES ph12_iam.realm_state (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_realm_provision_step_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_realm_provision_step_code CHECK (step_code IN ('TEMPLATE_APPLIED', 'KEYS_AND_CLIENTS', 'SECRETS_WRITTEN', 'ROLES', 'BROKER', 'FIRST_ADMIN', 'BUNDLE_SEEDED', 'ACTIVE')),
  CONSTRAINT ck_realm_provision_step_status CHECK (status IN ('RUNNING', 'DONE', 'FAILED') AND (status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_realm_provision_step_detail CHECK (jsonb_typeof(detail) = 'object' AND NOT ph12_iam.f_json_has_secret_key(detail))
);
CALL ph12_iam.p_enable_rls('ph12_iam.realm_provision_step', 'P');
COMMENT ON TABLE ph12_iam.realm_provision_step IS 'Bước đã làm của saga tạo realm (FR-12-041). Gọi lại cùng khóa lũy đẳng thì tiếp tục từ bước dở; tám bước theo SDD §4.10. detail không chứa bí mật (bí mật ghi một chiều vào OpenBao).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.realm_provision_step CASCADE;

-- @changeset ph12-0720-tenant-merge-step
CREATE TABLE ph12_iam.tenant_merge_step (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  merge_code       varchar(40)   NOT NULL,
  source_tenant    varchar(16)   NOT NULL,
  target_tenant    varchar(16)   NOT NULL,
  source_user_id   uuid          NOT NULL,
  target_user_id   uuid,
  status           varchar(8)    NOT NULL DEFAULT 'PLANNED',
  conflict_type    varchar(24),
  role_mapping     jsonb         NOT NULL DEFAULT '{}',
  detail           jsonb         NOT NULL DEFAULT '{}',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_merge_step PRIMARY KEY (id),
  CONSTRAINT uq_tenant_merge_step UNIQUE (merge_code, source_user_id),
  CONSTRAINT ck_tenant_merge_step_tenant CHECK (tenant_id = 'PLATFORM' AND source_tenant ~ '^T[0-9]{2}$' AND target_tenant ~ '^T[0-9]{2}$' AND source_tenant <> target_tenant),
  CONSTRAINT ck_tenant_merge_step_status CHECK (status IN ('PLANNED', 'CONFLICT', 'DONE', 'FAILED')),
  CONSTRAINT ck_tenant_merge_step_conflict CHECK (conflict_type IS NULL OR conflict_type IN ('USERNAME', 'EMAIL', 'ROLE_MISSING', 'ORG_UNMAPPED')),
  CONSTRAINT ck_tenant_merge_step_done CHECK (status <> 'DONE' OR target_user_id IS NOT NULL),
  CONSTRAINT ck_tenant_merge_step_json CHECK (jsonb_typeof(role_mapping) = 'object' AND jsonb_typeof(detail) = 'object' AND NOT ph12_iam.f_json_has_secret_key(detail))
);
CREATE INDEX ix_tenant_merge_step_status ON ph12_iam.tenant_merge_step (merge_code, status);
CREATE TRIGGER tg_tenant_merge_step_touch BEFORE UPDATE ON ph12_iam.tenant_merge_step FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.tenant_merge_step', 'P');
COMMENT ON TABLE ph12_iam.tenant_merge_step IS 'Chuyển định danh khi sáp nhập tenant (FR-12-019, Đợt 2): mỗi người dùng nguồn là một bước lũy đẳng nên chạy lại không tạo trùng. Dữ liệu điều phối của nền tảng nên tenant_id là PLATFORM; người dùng nguồn và đích ở hai tenant khác nhau nên không có khóa ngoại tới user_account.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.tenant_merge_step CASCADE;
