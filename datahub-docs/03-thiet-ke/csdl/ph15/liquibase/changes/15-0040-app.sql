--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0040-app.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0400-sandbox-app
CREATE TABLE ph15_portal.app (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_code            varchar(41)   NOT NULL,
  name                varchar(255)  NOT NULL,
  description         varchar(1000),
  owner_type          varchar(4)    NOT NULL,
  owner_account_id    uuid,
  owner_team_id       uuid,
  status              varchar(10)   NOT NULL DEFAULT 'ACTIVE',
  status_reason       varchar(1000),
  linked_system_code  varchar(64),
  daily_quota_override integer,
  last_used_at        timestamptz,
  archived_at         timestamptz,
  deleted_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app PRIMARY KEY (id),
  CONSTRAINT uq_app_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_app_code UNIQUE (tenant_id, app_code),
  CONSTRAINT fk_app_account FOREIGN KEY (owner_account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_app_team FOREIGN KEY (owner_team_id, tenant_id) REFERENCES ph15_portal.dev_team (id, tenant_id),
  CONSTRAINT ck_app_code CHECK (app_code ~ '^[a-z][a-z0-9-]{2,40}$'),
  CONSTRAINT ck_app_owner_type CHECK (owner_type IN ('USER', 'TEAM')),
  CONSTRAINT ck_app_owner CHECK ((owner_type = 'USER' AND owner_account_id IS NOT NULL AND owner_team_id IS NULL)
    OR (owner_type = 'TEAM' AND owner_team_id IS NOT NULL AND owner_account_id IS NULL)),
  CONSTRAINT ck_app_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'ARCHIVED')),
  CONSTRAINT ck_app_archived CHECK (status <> 'ARCHIVED' OR archived_at IS NOT NULL),
  CONSTRAINT ck_app_quota CHECK (daily_quota_override IS NULL OR daily_quota_override BETWEEN 100 AND 50000)
);
CREATE INDEX ix_app_owner_user ON ph15_portal.app (tenant_id, owner_account_id) WHERE deleted_at IS NULL AND owner_account_id IS NOT NULL;
CREATE INDEX ix_app_owner_team ON ph15_portal.app (tenant_id, owner_team_id) WHERE deleted_at IS NULL AND owner_team_id IS NOT NULL;
CREATE INDEX ix_app_idle ON ph15_portal.app (tenant_id, last_used_at) WHERE status = 'ACTIVE';
CREATE INDEX ix_app_purge ON ph15_portal.app (archived_at) WHERE status = 'ARCHIVED' AND deleted_at IS NULL;
CREATE TRIGGER tg_app_touch BEFORE UPDATE ON ph15_portal.app FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_app_immutable BEFORE UPDATE ON ph15_portal.app FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('app_code', 'owner_type', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.app');
COMMENT ON TABLE ph15_portal.app IS 'EN-15-08 Ứng dụng sandbox của một người hoặc một nhóm (FR-15-025, 026, 059). Không DELETE: appCode không dùng lại; xóa sau 30 ngày lưu trữ là đặt deleted_at (BR-15-007, BR-15-034).';
COMMENT ON COLUMN ph15_portal.app.linked_system_code IS 'Mã HTTT (PH-01) mà ứng dụng được giao để xem tham chiếu thông tin xác thực production (FR-15-032, BR-15-015); NULL = không giao. Cách giao chốt ở Q15-52.';
COMMENT ON COLUMN ph15_portal.app.daily_quota_override IS 'Hạn mức lượt thử mỗi ngày riêng của ứng dụng (100…50.000, trần của 15.try.rate-per-app-day); NULL = theo tham số tenant.';
--rollback DROP TABLE IF EXISTS ph15_portal.app CASCADE;

--changeset ph15:ph15-0410-app-member
CREATE TABLE ph15_portal.app_member (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  role                varchar(10)   NOT NULL DEFAULT 'DEVELOPER',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app_member PRIMARY KEY (id),
  CONSTRAINT uq_app_member UNIQUE (app_id, account_id),
  CONSTRAINT fk_app_member_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_app_member_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_app_member_role CHECK (role IN ('OWNER', 'DEVELOPER', 'VIEWER'))
);
CREATE INDEX ix_app_member_account ON ph15_portal.app_member (tenant_id, account_id);
CREATE TRIGGER tg_app_member_touch BEFORE UPDATE ON ph15_portal.app_member FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.app_member');
COMMENT ON TABLE ph15_portal.app_member IS 'Giao ứng dụng cho thành viên với vai trò OWNER, DEVELOPER, VIEWER; PERM-15-app và PERM-15-try chỉ áp trên ứng dụng mà người dùng là thành viên (FR-15-033, BR-15-009).';
--rollback DROP TABLE IF EXISTS ph15_portal.app_member CASCADE;

--changeset ph15:ph15-0420-sandbox-credential
CREATE TABLE ph15_portal.app_credential (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  kind                varchar(20)   NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  provisioning_state  varchar(14)   NOT NULL DEFAULT 'PENDING',
  client_id           varchar(128),
  keycloak_client_uuid varchar(64),
  key_prefix       char(8)       NOT NULL,
  key_hash         char(64),
  expires_at          timestamptz   NOT NULL,
  rotated_from_id     uuid,
  grace_until         timestamptz,
  revoked_at          timestamptz,
  revoke_reason       varchar(200),
  last_used_at        timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app_credential PRIMARY KEY (id),
  CONSTRAINT uq_app_credential_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_app_credential_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_app_credential_prev FOREIGN KEY (rotated_from_id, tenant_id) REFERENCES ph15_portal.app_credential (id, tenant_id),
  CONSTRAINT ck_app_credential_prov CHECK (provisioning_state IN ('PENDING', 'PROVISIONED', 'FAILED', 'DEPROVISIONING')),
  CONSTRAINT ck_app_credential_kind CHECK (kind IN ('CLIENT_CREDENTIALS', 'API_KEY')),
  CONSTRAINT ck_app_credential_status CHECK (status IN ('ACTIVE', 'ROTATING', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_app_credential_client CHECK ((kind = 'CLIENT_CREDENTIALS' AND client_id IS NOT NULL AND client_id ~ '^sbx-t[0-9]{2}-[a-z][a-z0-9-]{2,40}-[0-9]+$')
    OR (kind = 'API_KEY' AND client_id IS NULL AND key_hash IS NOT NULL AND key_hash ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_app_credential_ttl CHECK (expires_at <= created_at + interval '180 days'),
  CONSTRAINT ck_app_credential_revoked CHECK (status <> 'REVOKED' OR revoked_at IS NOT NULL),
  CONSTRAINT ck_app_credential_grace CHECK (status <> 'ROTATING' OR (grace_until IS NOT NULL AND grace_until <= updated_at + interval '72 hours' + interval '1 minute')),
  CONSTRAINT ck_app_credential_prefix CHECK (key_prefix ~ '^[A-Za-z0-9_-]{8}$'),
  CONSTRAINT ck_app_credential_active CHECK (status NOT IN ('ACTIVE', 'ROTATING') OR provisioning_state IN ('PENDING', 'PROVISIONED'))
);
CREATE UNIQUE INDEX uq_app_credential_client ON ph15_portal.app_credential (client_id) WHERE client_id IS NOT NULL;
CREATE UNIQUE INDEX uq_app_credential_prefix ON ph15_portal.app_credential (tenant_id, key_prefix) WHERE kind = 'API_KEY';
CREATE INDEX ix_app_credential_app ON ph15_portal.app_credential (tenant_id, app_id, status);
CREATE INDEX ix_app_credential_expiry ON ph15_portal.app_credential (expires_at) WHERE status IN ('ACTIVE', 'ROTATING');
CREATE TRIGGER tg_app_credential_touch BEFORE UPDATE ON ph15_portal.app_credential FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.app_credential');
COMMENT ON TABLE ph15_portal.app_credential IS 'EN-15-09 Thông tin xác thực sandbox: client_credentials ở realm dh-dev hoặc API key sandbox (FR-15-027…031). Không lưu bí mật, chỉ tiền tố 8 ký tự và băm (BR-15-011).';
COMMENT ON COLUMN ph15_portal.app_credential.key_hash IS 'HMAC-SHA256 (hex) của khóa API sandbox dhsk_… với pepper giữ ở OpenBao, để forward-auth đối chiếu; với client_credentials bí mật do Keycloak giữ nên cột để trống.';
COMMENT ON COLUMN ph15_portal.app_credential.provisioning_state IS 'Trạng thái saga cấp phát ở Keycloak realm dh-dev hoặc kho khóa: PENDING (đang tạo), PROVISIONED, FAILED (bù trừ), DEPROVISIONING (đang thu hồi); chỉ PENDING, PROVISIONED được xác thực.';
COMMENT ON COLUMN ph15_portal.app_credential.expires_at IS 'Tối đa 180 ngày kể từ lúc cấp (SEC-24); mặc định 15.cred.ttl-days = 90.';
COMMENT ON COLUMN ph15_portal.app_credential.grace_until IS 'Hết thời gian chuyển tiếp khi xoay vòng (≤ 72 giờ, 15.cred.rotate-grace-hours); sau mốc này bản ROTATING thành EXPIRED.';
--rollback DROP TABLE IF EXISTS ph15_portal.app_credential CASCADE;

--changeset ph15:ph15-0430-prod-credential-ref
CREATE TABLE ph15_portal.prod_credential_ref (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  system_code         varchar(64)   NOT NULL,
  client_id           varchar(128)  NOT NULL,
  auth_method         varchar(24)   NOT NULL,
  fingerprint_prefix  char(16),
  expires_at          timestamptz,
  status              varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  source_version      bigint        NOT NULL DEFAULT 0,
  synced_at           timestamptz   NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_prod_credential_ref PRIMARY KEY (id),
  CONSTRAINT uq_prod_credential_ref UNIQUE (tenant_id, system_code, client_id),
  CONSTRAINT ck_prod_credential_ref_method CHECK (auth_method IN ('tls_client_auth', 'private_key_jwt', 'client_secret_basic')),
  CONSTRAINT ck_prod_credential_ref_status CHECK (status IN ('ACTIVE', 'EXPIRING', 'REVOKED')),
  CONSTRAINT ck_prod_credential_ref_fp CHECK (fingerprint_prefix IS NULL OR fingerprint_prefix ~ '^[0-9a-f]{16}$')
);
CREATE INDEX ix_prod_credential_ref_system ON ph15_portal.prod_credential_ref (tenant_id, system_code);
CREATE TRIGGER tg_prod_credential_ref_touch BEFORE UPDATE ON ph15_portal.prod_credential_ref FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.prod_credential_ref');
COMMENT ON TABLE ph15_portal.prod_credential_ref IS 'EN-15-10 Tham chiếu thông tin xác thực production, bản sao chỉ đọc từ PH-01: không có cột bí mật; dấu vân tay chỉ 16 ký tự đầu (FR-15-032, BR-15-015).';
--rollback DROP TABLE IF EXISTS ph15_portal.prod_credential_ref CASCADE;
