--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0030-account.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0300-dev-account
CREATE TABLE ph15_portal.dev_account (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  user_id             varchar(64)   NOT NULL,
  source              varchar(12)   NOT NULL,
  status              varchar(16)   NOT NULL,
  email               varchar(254),
  full_name           varchar(255)  NOT NULL,
  organization        varchar(255),
  contract_no         varchar(64),
  sponsor_unit        varchar(255),
  phone_enc           bytea,
  dek_wrapped         bytea,
  verification_token_hash char(64),
  verification_expires_at timestamptz,
  email_verified_at   timestamptz,
  approved_by         varchar(64),
  approved_at         timestamptz,
  decision_reason     varchar(1000),
  last_active_at      timestamptz,
  anonymized_at       timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_account PRIMARY KEY (id),
  CONSTRAINT uq_dev_account_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_account_user UNIQUE (tenant_id, user_id),
  CONSTRAINT ck_dev_account_source CHECK (source IN ('TENANT_SSO', 'DH_DEV')),
  CONSTRAINT ck_dev_account_status CHECK (status IN ('PENDING_EMAIL', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'LOCKED', 'DISABLED', 'EXPIRED', 'ERASED')),
  CONSTRAINT ck_dev_account_sso_state CHECK (source <> 'TENANT_SSO' OR status IN ('ACTIVE', 'LOCKED', 'DISABLED', 'ERASED')),
  CONSTRAINT ck_dev_account_email_case CHECK (email IS NULL OR email = lower(email)),
  CONSTRAINT ck_dev_account_email_erased CHECK (email IS NOT NULL OR status = 'ERASED'),
  CONSTRAINT ck_dev_account_approved CHECK (source <> 'DH_DEV' OR status NOT IN ('ACTIVE', 'LOCKED')
    OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND organization IS NOT NULL AND contract_no IS NOT NULL AND email_verified_at IS NOT NULL)),
  CONSTRAINT ck_dev_account_phone CHECK ((phone_enc IS NULL) = (dek_wrapped IS NULL)),
  CONSTRAINT ck_dev_account_token CHECK (verification_token_hash IS NULL OR verification_token_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dev_account_erased CHECK (status <> 'ERASED' OR (anonymized_at IS NOT NULL AND phone_enc IS NULL AND dek_wrapped IS NULL AND email IS NULL))
);
CREATE UNIQUE INDEX uq_dev_account_email ON ph15_portal.dev_account (tenant_id, source, email) WHERE email IS NOT NULL;
CREATE INDEX ix_dev_account_queue ON ph15_portal.dev_account (tenant_id, created_at) WHERE status = 'PENDING_APPROVAL';
CREATE INDEX ix_dev_account_idle ON ph15_portal.dev_account (tenant_id, last_active_at) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_dev_account_touch BEFORE UPDATE ON ph15_portal.dev_account FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_account');
COMMENT ON TABLE ph15_portal.dev_account IS 'EN-15-06 Tài khoản nhà phát triển: dh-dev (vòng đời đầy đủ) và bản ghi tạo khi cán bộ SSO đăng nhập lần đầu (FR-15-019…024, 058, 059).';
COMMENT ON COLUMN ph15_portal.dev_account.user_id IS 'Chủ thể (sub) của Keycloak: realm tenant hoặc realm dh-dev; mật khẩu và MFA do PH-12 giữ, cổng không lưu.';
COMMENT ON COLUMN ph15_portal.dev_account.phone_enc IS 'Điện thoại (tùy chọn) mã hóa envelope AES-256-GCM, DEK bọc bằng KEK transit/dh/{tenant}/portal/dev-kek (ADR-032); chỉ module portal giải mã khi quản trị mở hồ sơ.';
COMMENT ON COLUMN ph15_portal.dev_account.verification_token_hash IS 'SHA-256 của mã xác minh thư; hết hạn sau 24 giờ (BR-15-028), dùng một lần.';
COMMENT ON COLUMN ph15_portal.dev_account.anonymized_at IS 'Thời điểm ẩn danh (xóa theo yêu cầu hoặc sau 15.dev.anonymize-after-months); khi đó email, điện thoại bị xóa, họ tên thay bằng chuỗi cố định (BR-15-029).';
--rollback DROP TABLE IF EXISTS ph15_portal.dev_account CASCADE;

--changeset ph15:ph15-0310-dev-team
CREATE TABLE ph15_portal.dev_team (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  team_code           varchar(41)   NOT NULL,
  name                varchar(255)  NOT NULL,
  description         varchar(1000),
  deleted_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_team PRIMARY KEY (id),
  CONSTRAINT uq_dev_team_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_team_code UNIQUE (tenant_id, team_code),
  CONSTRAINT ck_dev_team_code CHECK (team_code ~ '^[a-z][a-z0-9-]{2,40}$')
);
CREATE TRIGGER tg_dev_team_touch BEFORE UPDATE ON ph15_portal.dev_team FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_dev_team_immutable BEFORE UPDATE ON ph15_portal.dev_team FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('team_code', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.dev_team');
COMMENT ON TABLE ph15_portal.dev_team IS 'EN-15-07 Nhóm phát triển (FR-15-022). Xóa mềm; teamCode không dùng lại (BR-15-007).';
--rollback DROP TABLE IF EXISTS ph15_portal.dev_team CASCADE;

--changeset ph15:ph15-0311-team-member
CREATE TABLE ph15_portal.dev_team_member (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  team_id             uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  role                varchar(10)   NOT NULL DEFAULT 'DEVELOPER',
  invite_status       varchar(10)   NOT NULL DEFAULT 'PENDING',
  invited_by          varchar(64),
  invite_expires_at   timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_team_member PRIMARY KEY (id),
  CONSTRAINT uq_dev_team_member UNIQUE (team_id, account_id),
  CONSTRAINT fk_dev_team_member_team FOREIGN KEY (team_id, tenant_id) REFERENCES ph15_portal.dev_team (id, tenant_id),
  CONSTRAINT fk_dev_team_member_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_dev_team_member_role CHECK (role IN ('OWNER', 'DEVELOPER', 'VIEWER')),
  CONSTRAINT ck_dev_team_member_invite CHECK (invite_status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED')),
  CONSTRAINT ck_dev_team_member_owner CHECK (role <> 'OWNER' OR invite_status = 'ACCEPTED')
);
CREATE INDEX ix_dev_team_member_account ON ph15_portal.dev_team_member (tenant_id, account_id) WHERE invite_status = 'ACCEPTED';
CREATE TRIGGER tg_dev_team_member_touch BEFORE UPDATE ON ph15_portal.dev_team_member FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_team_member');
COMMENT ON TABLE ph15_portal.dev_team_member IS 'EN-15-07 Thành viên nhóm và lời mời (PENDING, ACCEPTED, DECLINED, EXPIRED) với vai trò OWNER, DEVELOPER, VIEWER (FR-15-022, 033).';
--rollback DROP TABLE IF EXISTS ph15_portal.dev_team_member CASCADE;

--changeset ph15:ph15-0320-terms
CREATE TABLE ph15_portal.dev_terms (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  version_label       varchar(32)   NOT NULL,
  page_version_id     uuid          NOT NULL,
  content_hash        char(64)      NOT NULL,
  effective_from      timestamptz   NOT NULL,
  retired_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_terms PRIMARY KEY (id),
  CONSTRAINT uq_dev_terms_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_terms_label UNIQUE (tenant_id, version_label),
  CONSTRAINT fk_dev_terms_page FOREIGN KEY (page_version_id, tenant_id) REFERENCES ph15_portal.content_page_version (id, tenant_id),
  CONSTRAINT ck_dev_terms_hash CHECK (content_hash ~ '^[0-9a-f]{64}$')
);
CREATE TRIGGER tg_dev_terms_touch BEFORE UPDATE ON ph15_portal.dev_terms FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_terms');
COMMENT ON TABLE ph15_portal.dev_terms IS 'EN-15-16 Điều khoản sử dụng có phiên bản: tham chiếu phiên bản trang loại TERMS đã đăng; băm nội dung để chứng minh người dùng chấp nhận đúng văn bản (FR-15-023).';
--rollback DROP TABLE IF EXISTS ph15_portal.dev_terms CASCADE;

--changeset ph15:ph15-0321-terms-acceptance
CREATE TABLE ph15_portal.dev_terms_acceptance (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  terms_id            uuid          NOT NULL,
  accepted_at         timestamptz   NOT NULL DEFAULT now(),
  client_ip_hash      char(64),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_dev_terms_acceptance PRIMARY KEY (id),
  CONSTRAINT uq_dev_terms_acceptance UNIQUE (account_id, terms_id),
  CONSTRAINT fk_dev_terms_acceptance_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_dev_terms_acceptance_terms FOREIGN KEY (terms_id, tenant_id) REFERENCES ph15_portal.dev_terms (id, tenant_id),
  CONSTRAINT ck_dev_terms_acceptance_ip CHECK (client_ip_hash IS NULL OR client_ip_hash ~ '^[0-9a-f]{64}$')
);
CREATE TRIGGER tg_dev_terms_acceptance_ro BEFORE UPDATE OR DELETE ON ph15_portal.dev_terms_acceptance FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_append_only();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_terms_acceptance');
COMMENT ON TABLE ph15_portal.dev_terms_acceptance IS 'EN-15-16 Bằng chứng chấp nhận điều khoản theo người dùng; chỉ thêm, không sửa (BR-15-008). Địa chỉ IP chỉ lưu băm.';
--rollback DROP TABLE IF EXISTS ph15_portal.dev_terms_acceptance CASCADE;
