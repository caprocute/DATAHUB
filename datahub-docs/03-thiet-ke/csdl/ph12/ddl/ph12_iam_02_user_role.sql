-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam
-- Tệp 02: người dùng, nhập hàng loạt, gán vai trò, tách nhiệm vụ, nhóm, vai trò tùy biến,
--         quyền có thời hạn, rà soát quyền (nhóm FR-12-A, B; EN-12-01…05, 11, 17)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- =============================================================================

\set ON_ERROR_STOP on
RESET ROLE;
SET ROLE ph12_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 12-0010-user.sql
-- @changeset ph12-0100-user-account
CREATE TABLE ph12_iam.user_account (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  keycloak_id       uuid,
  username          varchar(80)   NOT NULL,
  full_name         varchar(255)  NOT NULL,
  email             varchar(254)  NOT NULL,
  org_code          varchar(64)   NOT NULL,
  title             varchar(255),
  manager_user_id   uuid,
  auth_source       varchar(8)    NOT NULL DEFAULT 'LOCAL',
  federation_id     uuid,
  state             varchar(20)   NOT NULL DEFAULT 'PENDING_ACTIVATION',
  disabled_reason   varchar(40),
  disabled_note     varchar(1000),
  mfa_level         smallint      NOT NULL DEFAULT 1,
  sync_state        varchar(8)    NOT NULL DEFAULT 'PENDING',
  activated_at      timestamptz,
  last_login_at     timestamptz,
  disabled_at       timestamptz,
  origin_tenant_id  varchar(16),
  origin_user_id    uuid,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_user_account PRIMARY KEY (id),
  CONSTRAINT uq_user_account_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_user_account_keycloak UNIQUE (tenant_id, keycloak_id),
  CONSTRAINT fk_user_account_manager FOREIGN KEY (manager_user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_user_account_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_user_account_username CHECK (username ~ '^[a-z0-9][a-z0-9._-]{2,79}$'),
  CONSTRAINT ck_user_account_email CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  CONSTRAINT ck_user_account_state CHECK (state IN ('PENDING_ACTIVATION', 'ACTIVE', 'LOCKED', 'BLOCKED', 'DISABLED')),
  CONSTRAINT ck_user_account_auth_source CHECK (auth_source IN ('LOCAL', 'LDAP')),
  CONSTRAINT ck_user_account_federation CHECK ((auth_source = 'LDAP') = (federation_id IS NOT NULL)),
  CONSTRAINT ck_user_account_mfa CHECK (mfa_level BETWEEN 1 AND 3),
  CONSTRAINT ck_user_account_sync CHECK (sync_state IN ('PENDING', 'SYNCED', 'FAILED') AND (sync_state <> 'SYNCED' OR keycloak_id IS NOT NULL)),
  CONSTRAINT ck_user_account_disabled CHECK ((state = 'DISABLED') = (disabled_at IS NOT NULL) AND (state <> 'DISABLED' OR disabled_reason IS NOT NULL)),
  CONSTRAINT ck_user_account_activated CHECK (state IN ('PENDING_ACTIVATION', 'DISABLED') OR activated_at IS NOT NULL),
  CONSTRAINT ck_user_account_manager CHECK (manager_user_id IS DISTINCT FROM id),
  CONSTRAINT ck_user_account_origin CHECK ((origin_tenant_id IS NULL) = (origin_user_id IS NULL) AND origin_tenant_id IS DISTINCT FROM tenant_id)
);
CREATE UNIQUE INDEX uq_user_account_username ON ph12_iam.user_account (tenant_id, lower(username));
CREATE UNIQUE INDEX uq_user_account_email ON ph12_iam.user_account (tenant_id, lower(email));
CREATE INDEX ix_user_account_org_state ON ph12_iam.user_account (tenant_id, org_code, state);
CREATE INDEX ix_user_account_inactivity ON ph12_iam.user_account (tenant_id, last_login_at) WHERE state = 'ACTIVE';
CREATE INDEX ix_user_account_pending ON ph12_iam.user_account (tenant_id, created_at) WHERE state = 'PENDING_ACTIVATION';
CREATE INDEX ix_user_account_sync ON ph12_iam.user_account (tenant_id, updated_at) WHERE sync_state <> 'SYNCED';
CREATE INDEX ix_user_account_manager ON ph12_iam.user_account (tenant_id, manager_user_id) WHERE manager_user_id IS NOT NULL;
CREATE INDEX ix_user_account_name_trgm ON ph12_iam.user_account USING gin (lower(full_name) gin_trgm_ops);
CREATE TRIGGER tg_user_account_touch BEFORE UPDATE ON ph12_iam.user_account FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CREATE TRIGGER tg_user_account_no_delete BEFORE DELETE ON ph12_iam.user_account FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_no_delete();
CALL ph12_iam.p_enable_rls('ph12_iam.user_account', 'P');
COMMENT ON TABLE ph12_iam.user_account IS 'EN-12-01 Bản chiếu người dùng (FR-12-001…010). Keycloak là nguồn sự thật của thông tin đăng nhập; bảng giữ phần nghiệp vụ. Không xóa vật lý, kết thúc là DISABLED (BR-12-035).';
COMMENT ON COLUMN ph12_iam.user_account.keycloak_id IS 'Mã người dùng ở Keycloak; rỗng khi sync_state = PENDING (ghi ý định trước, tạo ở Keycloak sau, SDD §4.2).';
COMMENT ON COLUMN ph12_iam.user_account.org_code IS 'Mã đơn vị ở PH-07; không khóa ngoại vì khác schema, kiểm ở dịch vụ (ERR-12-004).';
COMMENT ON COLUMN ph12_iam.user_account.state IS 'Năm trạng thái của FRS §4.3. LOCKED, BLOCKED do Keycloak quyết định, cập nhật qua EVT-12-16.';
COMMENT ON COLUMN ph12_iam.user_account.mfa_level IS 'Mức xác thực yêu cầu (thuộc tính dh_mfa_level ở Keycloak): 1 mật khẩu, 2 cộng TOTP hoặc WebAuthn, 3 WebAuthn. Lấy mức cao nhất của vai trò mfaRequired.';
COMMENT ON COLUMN ph12_iam.user_account.last_login_at IS 'Lấy từ sự kiện đăng nhập (EVT-12-16); nguồn của tác vụ tự vô hiệu 45 ngày (FR-12-008).';
COMMENT ON COLUMN ph12_iam.user_account.disabled_reason IS 'Mã lý do vô hiệu: MANUAL, INACTIVE_45D, INACTIVE_30D_ADMIN, NEVER_ACTIVATED, LDAP_REMOVED, MERGED.';
COMMENT ON COLUMN ph12_iam.user_account.origin_tenant_id IS 'Tenant nguồn khi người dùng được chuyển do sáp nhập (FR-12-019); cùng origin_user_id.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.user_account CASCADE;

-- @changeset ph12-0110-user-import
CREATE TABLE ph12_iam.user_import (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  file_name        varchar(255)  NOT NULL,
  file_ref         varchar(512),
  file_sha256      char(64)      NOT NULL,
  file_purge_at    timestamptz   NOT NULL,
  status           varchar(12)   NOT NULL DEFAULT 'PREVIEW',
  role_mapping     jsonb         NOT NULL DEFAULT '{}',
  total_rows       integer       NOT NULL DEFAULT 0,
  ok_rows          integer       NOT NULL DEFAULT 0,
  warn_rows        integer       NOT NULL DEFAULT 0,
  error_rows       integer       NOT NULL DEFAULT 0,
  created_rows     integer       NOT NULL DEFAULT 0,
  failed_rows      integer       NOT NULL DEFAULT 0,
  confirmed_by     varchar(64),
  confirmed_at     timestamptz,
  finished_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_user_import PRIMARY KEY (id),
  CONSTRAINT uq_user_import_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_user_import_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_user_import_status CHECK (status IN ('PREVIEW', 'CONFIRMED', 'RUNNING', 'DONE', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_user_import_hash CHECK (file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_user_import_rows CHECK (total_rows BETWEEN 0 AND 20000 AND ok_rows + warn_rows + error_rows <= total_rows AND created_rows + failed_rows <= ok_rows + warn_rows),
  CONSTRAINT ck_user_import_mapping CHECK (jsonb_typeof(role_mapping) = 'object'),
  CONSTRAINT ck_user_import_confirm CHECK (status IN ('PREVIEW', 'EXPIRED') OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL))
);
CREATE INDEX ix_user_import_status ON ph12_iam.user_import (tenant_id, status, created_at DESC);
CREATE INDEX ix_user_import_purge ON ph12_iam.user_import (file_purge_at) WHERE file_ref IS NOT NULL;
CREATE TRIGGER tg_user_import_touch BEFORE UPDATE ON ph12_iam.user_import FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.user_import', 'P');
COMMENT ON TABLE ph12_iam.user_import IS 'Lần nhập người dùng hàng loạt hai pha (FR-12-009, BR-12-043): xem trước rồi xác nhận. Tệp gốc ở kho đối tượng, xóa sau 24 giờ; tối đa 20.000 dòng (trần của 12.import.max-rows).';
COMMENT ON COLUMN ph12_iam.user_import.file_ref IS 'Khóa đối tượng của tệp gốc trong bucket dh-iam-import; đặt NULL sau khi xóa (file_purge_at = tạo + 24 giờ).';
COMMENT ON COLUMN ph12_iam.user_import.role_mapping IS 'Ánh xạ vai trò hệ cũ sang vai trò chuẩn của lần nhập này, khởi tạo từ legacy_role_map, TA sửa được (FRS §11.4).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.user_import CASCADE;

-- @changeset ph12-0120-user-import-row
CREATE TABLE ph12_iam.user_import_row (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  import_id        uuid          NOT NULL,
  row_no           integer       NOT NULL,
  raw              jsonb         NOT NULL,
  result           varchar(8)    NOT NULL,
  messages         jsonb         NOT NULL DEFAULT '[]',
  user_id          uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_user_import_row PRIMARY KEY (id),
  CONSTRAINT uq_user_import_row UNIQUE (import_id, row_no),
  CONSTRAINT fk_user_import_row_import FOREIGN KEY (import_id, tenant_id) REFERENCES ph12_iam.user_import (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_user_import_row_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_user_import_row_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_user_import_row_result CHECK (result IN ('OK', 'WARN', 'ERROR', 'CREATED', 'FAILED')),
  CONSTRAINT ck_user_import_row_no CHECK (row_no BETWEEN 1 AND 20000),
  CONSTRAINT ck_user_import_row_messages CHECK (jsonb_typeof(messages) = 'array'),
  CONSTRAINT ck_user_import_row_no_secret CHECK (jsonb_typeof(raw) = 'object' AND NOT ph12_iam.f_json_has_secret_key(raw))
);
CREATE INDEX ix_user_import_row_result ON ph12_iam.user_import_row (tenant_id, import_id, result);
CALL ph12_iam.p_enable_rls('ph12_iam.user_import_row', 'P');
COMMENT ON TABLE ph12_iam.user_import_row IS 'Từng dòng của tệp nhập với kết quả kiểm tra (OK, WARN, ERROR) rồi kết quả tạo (CREATED, FAILED). Không nhận mật khẩu qua tệp: cột raw bị CHECK chặn khóa tên bí mật (BR-12-043, BR-12-045).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.user_import_row CASCADE;

-- @file 12-0020-role.sql
-- @changeset ph12-0200-sod-pair
CREATE TABLE ph12_iam.sod_pair (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  role_a           varchar(64)   NOT NULL,
  role_b           varchar(64)   NOT NULL,
  allow_exception  boolean       NOT NULL DEFAULT true,
  reason           varchar(500)  NOT NULL,
  source_ref       varchar(64)   NOT NULL DEFAULT 'D02-08 §4',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sod_pair PRIMARY KEY (id),
  CONSTRAINT uq_sod_pair UNIQUE (role_a, role_b),
  CONSTRAINT ck_sod_pair_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_sod_pair_order CHECK (role_a < role_b),
  CONSTRAINT ck_sod_pair_role CHECK (role_a ~ '^[A-Z][A-Z0-9_]{2,63}$' AND role_b ~ '^[A-Z][A-Z0-9_]{2,63}$')
);
CREATE TRIGGER tg_sod_pair_touch BEFORE UPDATE ON ph12_iam.sod_pair FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.sod_pair', 'S');
COMMENT ON TABLE ph12_iam.sod_pair IS 'Cặp vai trò xung đột của D02-08 §4, sinh từ ma trận khi phát hành (FR-12-051, BR-12-030). Dùng chung mọi tenant (COMMON), chỉ PLATFORM ghi. Cặp có AUDITOR với vai trò ghi của PH-19 có allow_exception = false.';
COMMENT ON COLUMN ph12_iam.sod_pair.role_a IS 'Mã vai trò bỏ tiền tố ROLE-, role_a < role_b theo thứ tự chữ cái để tra một chiều.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.sod_pair CASCADE;

-- @changeset ph12-0205-legacy-role-map
CREATE TABLE ph12_iam.legacy_role_map (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  legacy_role      varchar(64)   NOT NULL,
  role_code        varchar(64),
  source           varchar(16)   NOT NULL,
  note             varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_role_map PRIMARY KEY (id),
  CONSTRAINT uq_legacy_role_map UNIQUE (legacy_role),
  CONSTRAINT ck_legacy_role_map_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_legacy_role_map_source CHECK (source IN ('SRS_REPO', 'COMPOSE_REALM', 'MIDPOINT')),
  CONSTRAINT ck_legacy_role_map_role CHECK (role_code IS NULL OR role_code ~ '^[A-Z][A-Z0-9_]{2,63}$')
);
CREATE TRIGGER tg_legacy_role_map_touch BEFORE UPDATE ON ph12_iam.legacy_role_map FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.legacy_role_map', 'S');
COMMENT ON TABLE ph12_iam.legacy_role_map IS 'Ánh xạ mặc định vai trò hệ cũ sang vai trò chuẩn D02-08 (FRS §11.4), đầu vào của nhập người dùng (FR-12-009, ERR-12-036) và di trú (D06-01). role_code rỗng nghĩa là chưa có vai trò tương ứng (Q12-05).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.legacy_role_map CASCADE;

-- @changeset ph12-0210-role-assignment splitStatements:false
CREATE TABLE ph12_iam.role_assignment (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  user_id          uuid          NOT NULL,
  role_code        varchar(64)   NOT NULL,
  scope_type       varchar(10)   NOT NULL DEFAULT 'TENANT',
  scope_ref        varchar(64),
  valid_from       timestamptz   NOT NULL DEFAULT now(),
  valid_to         timestamptz,
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  source           varchar(8)    NOT NULL DEFAULT 'MANUAL',
  reason           varchar(1000),
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_role_assignment PRIMARY KEY (id),
  CONSTRAINT uq_role_assignment_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_role_assignment_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_role_assignment_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_role_assignment_role CHECK (role_code ~ '^[A-Z][A-Z0-9_]{2,63}$'),
  CONSTRAINT ck_role_assignment_machine CHECK (role_code <> 'PARTNER_SYSTEM'),
  CONSTRAINT ck_role_assignment_platform CHECK (role_code NOT LIKE 'PLATFORM\_%' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_role_assignment_scope CHECK (scope_type IN ('TENANT', 'ORG', 'WORKSPACE') AND (scope_type = 'TENANT') = (scope_ref IS NULL)),
  CONSTRAINT ck_role_assignment_state CHECK (state IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_role_assignment_source CHECK (source IN ('MANUAL', 'IMPORT', 'RECERT', 'SYSTEM', 'MERGE')),
  CONSTRAINT ck_role_assignment_valid CHECK (valid_to IS NULL OR valid_to > valid_from),
  CONSTRAINT ck_role_assignment_revoked CHECK ((state = 'REVOKED') = (revoked_at IS NOT NULL) AND (state <> 'REVOKED' OR revoked_by IS NOT NULL)),
  CONSTRAINT ck_role_assignment_no_self CHECK (created_by <> user_id::text AND revoked_by IS DISTINCT FROM user_id::text)
);
CREATE UNIQUE INDEX uq_role_assignment_active ON ph12_iam.role_assignment (tenant_id, user_id, role_code, scope_type, coalesce(scope_ref, ''))
  WHERE state = 'ACTIVE';
CREATE INDEX ix_role_assignment_user ON ph12_iam.role_assignment (tenant_id, user_id, state);
CREATE INDEX ix_role_assignment_role ON ph12_iam.role_assignment (tenant_id, role_code) WHERE state = 'ACTIVE';
CREATE INDEX ix_role_assignment_expiry ON ph12_iam.role_assignment (valid_to) WHERE state = 'ACTIVE' AND valid_to IS NOT NULL;
CREATE TRIGGER tg_role_assignment_touch BEFORE UPDATE ON ph12_iam.role_assignment FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.role_assignment', 'P');
COMMENT ON TABLE ph12_iam.role_assignment IS 'EN-12-02 Gán vai trò chuẩn cho người dùng, có phạm vi (TENANT, ORG, WORKSPACE) và thời hạn (FR-12-012). Cặp xung đột bị trigger tg_role_assignment_sod chặn (BR-12-030); tenant còn ít nhất một TENANT_ADMIN (BR-12-033). Vai trò chỉ gán cho người, không gán cho nhóm (BR-12-039).';
COMMENT ON COLUMN ph12_iam.role_assignment.role_code IS 'Mã vai trò chuẩn bỏ tiền tố ROLE-, ví dụ TENANT_ADMIN; hoặc vai trò tùy biến CUSTOM_* (custom_role.code). Danh mục 22 vai trò chuẩn nằm ở roles.json sinh từ D02-08, không lưu bảng.';
COMMENT ON COLUMN ph12_iam.role_assignment.scope_ref IS 'Mã đơn vị (ORG, cùng cây con) hoặc mã không gian làm việc của PH-04 (WORKSPACE); rỗng khi phạm vi TENANT.';
COMMENT ON COLUMN ph12_iam.role_assignment.created_by IS 'Người gán (assignedBy); khác người nhận vai trò (BR-12-033).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.role_assignment CASCADE;

-- @changeset ph12-0215-fn-last-admin splitStatements:false
-- Mỗi tenant luôn còn ít nhất một TENANT_ADMIN hoạt động (BR-12-033, ERR-12-046).
-- Khóa tư vấn theo tenant để hai giao dịch gỡ đồng thời không cùng thấy "còn người kia".
CREATE OR REPLACE FUNCTION ph12_iam.f_other_active_admins(p_tenant text, p_exclude_user uuid, p_exclude_assignment uuid) RETURNS integer
  LANGUAGE sql STABLE AS $f$
  SELECT count(*)::integer
    FROM ph12_iam.role_assignment a
    JOIN ph12_iam.user_account u ON u.id = a.user_id AND u.tenant_id = a.tenant_id
   WHERE a.tenant_id = p_tenant AND a.role_code = 'TENANT_ADMIN' AND a.state = 'ACTIVE'
     AND (a.valid_to IS NULL OR a.valid_to > now())
     AND a.id IS DISTINCT FROM p_exclude_assignment
     AND u.id IS DISTINCT FROM p_exclude_user
     AND u.state IN ('ACTIVE', 'LOCKED', 'PENDING_ACTIVATION')
$f$;

CREATE OR REPLACE FUNCTION ph12_iam.tg_role_assignment_last_admin() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.role_code = 'TENANT_ADMIN' AND OLD.state = 'ACTIVE' AND OLD.tenant_id <> 'PLATFORM'
     AND (TG_OP = 'DELETE' OR NEW.state <> 'ACTIVE') THEN
    PERFORM pg_advisory_xact_lock(hashtextextended('ph12:last-admin:' || OLD.tenant_id, 0));
    IF ph12_iam.f_other_active_admins(OLD.tenant_id, NULL, OLD.id) = 0 THEN
      RAISE EXCEPTION 'Không thể gỡ quản trị tỉnh cuối cùng của tenant %', OLD.tenant_id USING ERRCODE = 'P1246';
    END IF;
  END IF;
  RETURN CASE TG_OP WHEN 'DELETE' THEN OLD ELSE NEW END;
END
$f$;

CREATE OR REPLACE FUNCTION ph12_iam.tg_user_account_last_admin() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.state = 'DISABLED' AND OLD.state <> 'DISABLED' AND NEW.tenant_id <> 'PLATFORM'
     AND EXISTS (SELECT 1 FROM ph12_iam.role_assignment a
                  WHERE a.tenant_id = NEW.tenant_id AND a.user_id = NEW.id AND a.role_code = 'TENANT_ADMIN' AND a.state = 'ACTIVE') THEN
    PERFORM pg_advisory_xact_lock(hashtextextended('ph12:last-admin:' || NEW.tenant_id, 0));
    IF ph12_iam.f_other_active_admins(NEW.tenant_id, NEW.id, NULL) = 0 THEN
      RAISE EXCEPTION 'Không thể vô hiệu quản trị tỉnh cuối cùng của tenant %', NEW.tenant_id USING ERRCODE = 'P1246';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_role_assignment_last_admin BEFORE UPDATE OF state OR DELETE ON ph12_iam.role_assignment
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_role_assignment_last_admin();
CREATE TRIGGER tg_user_account_last_admin BEFORE UPDATE OF state ON ph12_iam.user_account
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_user_account_last_admin();
COMMENT ON FUNCTION ph12_iam.tg_role_assignment_last_admin() IS 'Chặn gỡ, hết hạn, thu hồi gán TENANT_ADMIN cuối cùng (ERR-12-046); hết hạn tự động của người cuối cùng thất bại và để lại cảnh báo cho tác vụ AssignmentExpiryJob.';
-- @rollback DROP TRIGGER IF EXISTS tg_user_account_last_admin ON ph12_iam.user_account; DROP TRIGGER IF EXISTS tg_role_assignment_last_admin ON ph12_iam.role_assignment; DROP FUNCTION IF EXISTS ph12_iam.tg_user_account_last_admin(); DROP FUNCTION IF EXISTS ph12_iam.tg_role_assignment_last_admin(); DROP FUNCTION IF EXISTS ph12_iam.f_other_active_admins(text, uuid, uuid);

-- @changeset ph12-0220-sod-exception
CREATE TABLE ph12_iam.sod_exception (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  user_id          uuid          NOT NULL,
  role_a           varchar(64)   NOT NULL,
  role_b           varchar(64)   NOT NULL,
  reason           varchar(2000) NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'REQUESTED',
  expires_at       timestamptz   NOT NULL,
  proposed_by      varchar(64)   NOT NULL,
  approved_by      varchar(64),
  decided_at       timestamptz,
  decision_note    varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sod_exception PRIMARY KEY (id),
  CONSTRAINT fk_sod_exception_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT fk_sod_exception_pair FOREIGN KEY (role_a, role_b) REFERENCES ph12_iam.sod_pair (role_a, role_b),
  CONSTRAINT ck_sod_exception_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_sod_exception_state CHECK (state IN ('REQUESTED', 'ACTIVE', 'REJECTED', 'CANCELLED', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_sod_exception_reason CHECK (char_length(reason) >= 30),
  CONSTRAINT ck_sod_exception_max_days CHECK (expires_at > created_at AND expires_at <= created_at + interval '90 days'),
  CONSTRAINT ck_sod_exception_four_eyes CHECK (approved_by IS NULL OR approved_by <> proposed_by),
  CONSTRAINT ck_sod_exception_decided CHECK ((state IN ('ACTIVE', 'REJECTED', 'REVOKED')) = (approved_by IS NOT NULL AND decided_at IS NOT NULL) OR state IN ('CANCELLED', 'EXPIRED'))
);
CREATE UNIQUE INDEX uq_sod_exception_open ON ph12_iam.sod_exception (tenant_id, user_id, role_a, role_b) WHERE state IN ('REQUESTED', 'ACTIVE');
CREATE INDEX ix_sod_exception_expiry ON ph12_iam.sod_exception (expires_at) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_sod_exception_touch BEFORE UPDATE ON ph12_iam.sod_exception FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.sod_exception', 'P');
COMMENT ON TABLE ph12_iam.sod_exception IS 'EN-12-03 Ngoại lệ tách nhiệm vụ: TA đề nghị, SO duyệt (khác người), lý do ≥ 30 ký tự, tối đa 90 ngày, tự gỡ khi hết hạn (FR-12-013, BR-12-030, EVT-12-12).';
COMMENT ON COLUMN ph12_iam.sod_exception.role_a IS 'Cặp vai trò theo thứ tự chữ cái, khóa ngoại tới sod_pair; trigger tg_sod_exception_guard từ chối cặp có allow_exception = false.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.sod_exception CASCADE;

-- @changeset ph12-0225-fn-sod splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_sod_exception_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ph12_iam.sod_pair p WHERE p.role_a = NEW.role_a AND p.role_b = NEW.role_b AND p.allow_exception) THEN
    RAISE EXCEPTION 'Cặp vai trò % và % không cho phép ngoại lệ tách nhiệm vụ', NEW.role_a, NEW.role_b USING ERRCODE = 'P1210';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_sod_exception_guard BEFORE INSERT ON ph12_iam.sod_exception FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_sod_exception_guard();

CREATE OR REPLACE FUNCTION ph12_iam.tg_role_assignment_sod() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  clash record;
BEGIN
  IF NEW.state <> 'ACTIVE' THEN RETURN NEW; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('ph12:sod:' || NEW.tenant_id || ':' || NEW.user_id::text, 0));
  SELECT a.role_code AS other_role INTO clash
    FROM ph12_iam.role_assignment a
    JOIN ph12_iam.sod_pair p ON p.role_a = LEAST(a.role_code, NEW.role_code) AND p.role_b = GREATEST(a.role_code, NEW.role_code)
   WHERE a.tenant_id = NEW.tenant_id AND a.user_id = NEW.user_id AND a.state = 'ACTIVE' AND a.id <> NEW.id
     AND (a.valid_to IS NULL OR a.valid_to > now())
     AND NOT EXISTS (SELECT 1 FROM ph12_iam.sod_exception e
                      WHERE e.tenant_id = NEW.tenant_id AND e.user_id = NEW.user_id AND e.state = 'ACTIVE' AND e.expires_at > now()
                        AND e.role_a = p.role_a AND e.role_b = p.role_b)
   LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'Cặp vai trò xung đột: % và % (tách nhiệm vụ, BR-12-030)', clash.other_role, NEW.role_code USING ERRCODE = 'P1209';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_role_assignment_sod BEFORE INSERT OR UPDATE OF state, role_code ON ph12_iam.role_assignment
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_role_assignment_sod();
COMMENT ON FUNCTION ph12_iam.tg_role_assignment_sod() IS 'Chặn gán cặp vai trò xung đột trừ khi có ngoại lệ ACTIVE còn hạn (BR-12-030, ERR-12-009). Khóa tư vấn theo người dùng để hai giao dịch gán đồng thời không cùng qua được.';
-- @rollback DROP TRIGGER IF EXISTS tg_role_assignment_sod ON ph12_iam.role_assignment; DROP TRIGGER IF EXISTS tg_sod_exception_guard ON ph12_iam.sod_exception; DROP FUNCTION IF EXISTS ph12_iam.tg_role_assignment_sod(); DROP FUNCTION IF EXISTS ph12_iam.tg_sod_exception_guard();

-- @changeset ph12-0230-org-group
CREATE TABLE ph12_iam.org_group (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(40)   NOT NULL,
  name             varchar(255)  NOT NULL,
  type             varchar(8)    NOT NULL DEFAULT 'CUSTOM',
  org_code         varchar(64),
  parent_id        uuid,
  path             ltree         NOT NULL,
  active           boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_org_group PRIMARY KEY (id),
  CONSTRAINT uq_org_group_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_org_group_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_org_group_path UNIQUE (tenant_id, path),
  CONSTRAINT fk_org_group_parent FOREIGN KEY (parent_id, tenant_id) REFERENCES ph12_iam.org_group (id, tenant_id),
  CONSTRAINT ck_org_group_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_org_group_code CHECK (code ~ '^[A-Z0-9_]{1,40}$'),
  CONSTRAINT ck_org_group_type CHECK (type IN ('ORG', 'CUSTOM') AND (type = 'ORG') = (org_code IS NOT NULL)),
  CONSTRAINT ck_org_group_parent CHECK (parent_id IS DISTINCT FROM id)
);
CREATE UNIQUE INDEX uq_org_group_org_code ON ph12_iam.org_group (tenant_id, org_code) WHERE org_code IS NOT NULL;
CREATE INDEX ix_org_group_path ON ph12_iam.org_group USING gist (path);
CREATE INDEX ix_org_group_parent ON ph12_iam.org_group (tenant_id, parent_id);
CREATE TRIGGER tg_org_group_touch BEFORE UPDATE ON ph12_iam.org_group FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.org_group', 'P');
COMMENT ON TABLE ph12_iam.org_group IS 'EN-12-04 Nhóm và đơn vị tổ chức theo cây (FR-12-014). path là ltree do trigger tính từ cha và mã; cấm vòng lặp (BR-12-039). Phạm vi ORG của gán vai trò hiểu là mọi nhóm có path <@ path của đơn vị.';
COMMENT ON COLUMN ph12_iam.org_group.path IS 'Đường đi ltree gốc → nút, nhãn là mã nhóm; trigger tg_org_group_path đặt, tg_org_group_subtree cập nhật cây con khi đổi cha.';
COMMENT ON COLUMN ph12_iam.org_group.org_code IS 'Mã đơn vị ở PH-07 khi type = ORG (đồng bộ từ danh mục, FR-12-010); rỗng với nhóm tùy biến.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.org_group CASCADE;

-- @changeset ph12-0231-fn-org-group splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_org_group_path() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent_path ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path := text2ltree(NEW.code);
  ELSE
    SELECT g.path INTO parent_path FROM ph12_iam.org_group g WHERE g.id = NEW.parent_id AND g.tenant_id = NEW.tenant_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Nhóm cha % không tồn tại trong tenant %', NEW.parent_id, NEW.tenant_id USING ERRCODE = 'P1210';
    END IF;
    IF TG_OP = 'UPDATE' AND parent_path <@ OLD.path THEN
      RAISE EXCEPTION 'Đổi cha tạo vòng lặp nhóm (BR-12-039)' USING ERRCODE = 'P1212';
    END IF;
    NEW.path := parent_path || text2ltree(NEW.code);
  END IF;
  RETURN NEW;
END
$f$;
CREATE OR REPLACE FUNCTION ph12_iam.tg_org_group_subtree() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.path IS DISTINCT FROM OLD.path THEN
    UPDATE ph12_iam.org_group g
       SET path = NEW.path || subpath(g.path, nlevel(OLD.path))
     WHERE g.tenant_id = NEW.tenant_id AND g.path <@ OLD.path AND g.id <> NEW.id;
  END IF;
  RETURN NULL;
END
$f$;
CREATE TRIGGER tg_org_group_path BEFORE INSERT OR UPDATE OF parent_id, code ON ph12_iam.org_group
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_org_group_path();
CREATE TRIGGER tg_org_group_subtree AFTER UPDATE OF parent_id, code ON ph12_iam.org_group
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_org_group_subtree();
COMMENT ON FUNCTION ph12_iam.tg_org_group_path() IS 'Tính path ltree từ nhóm cha; đổi cha vào chính cây con của nút thì lỗi vòng lặp (ERR-12-012).';
-- @rollback DROP TRIGGER IF EXISTS tg_org_group_subtree ON ph12_iam.org_group; DROP TRIGGER IF EXISTS tg_org_group_path ON ph12_iam.org_group; DROP FUNCTION IF EXISTS ph12_iam.tg_org_group_subtree(); DROP FUNCTION IF EXISTS ph12_iam.tg_org_group_path();

-- @changeset ph12-0235-org-group-member
CREATE TABLE ph12_iam.org_group_member (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  group_id         uuid          NOT NULL,
  user_id          uuid          NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_org_group_member PRIMARY KEY (id),
  CONSTRAINT uq_org_group_member UNIQUE (group_id, user_id),
  CONSTRAINT fk_org_group_member_group FOREIGN KEY (group_id, tenant_id) REFERENCES ph12_iam.org_group (id, tenant_id),
  CONSTRAINT fk_org_group_member_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_org_group_member_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$')
);
CREATE INDEX ix_org_group_member_user ON ph12_iam.org_group_member (tenant_id, user_id);
CALL ph12_iam.p_enable_rls('ph12_iam.org_group_member', 'P');
COMMENT ON TABLE ph12_iam.org_group_member IS 'Thành viên của nhóm (FR-12-014). Nhóm còn thành viên không xóa được (ERR-12-011); vai trò không gán cho nhóm.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.org_group_member CASCADE;

-- @changeset ph12-0240-custom-role
CREATE TABLE ph12_iam.custom_role (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  state            varchar(14)   NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  approved_by      varchar(64),
  approved_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_custom_role PRIMARY KEY (id),
  CONSTRAINT uq_custom_role_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_custom_role_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_custom_role_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_custom_role_code CHECK (code ~ '^CUSTOM_[A-Z0-9_]{2,56}$'),
  CONSTRAINT ck_custom_role_state CHECK (state IN ('DRAFT', 'PENDING_REVIEW', 'ACTIVE', 'DISABLED')),
  CONSTRAINT ck_custom_role_four_eyes CHECK (approved_by IS NULL OR (approved_by <> created_by AND approved_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_custom_role_active CHECK (state <> 'ACTIVE' OR (approved_by IS NOT NULL AND approved_at IS NOT NULL))
);
CREATE TRIGGER tg_custom_role_touch BEFORE UPDATE ON ph12_iam.custom_role FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.custom_role', 'P');
COMMENT ON TABLE ph12_iam.custom_role IS 'EN-12-05 Vai trò tùy biến của tenant (FR-12-015, Đợt 2): chỉ cấu từ quyền đã có, bốn mắt (BR-07, BR-12-008). Tenant PLATFORM không có vai trò tùy biến. Mã bắt buộc tiền tố CUSTOM_ để không trùng vai trò chuẩn.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.custom_role CASCADE;

-- @changeset ph12-0245-custom-role-permission
CREATE TABLE ph12_iam.custom_role_permission (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  custom_role_id   uuid          NOT NULL,
  permission_code  varchar(64)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_custom_role_permission PRIMARY KEY (id),
  CONSTRAINT uq_custom_role_permission UNIQUE (custom_role_id, permission_code),
  CONSTRAINT fk_custom_role_permission_role FOREIGN KEY (custom_role_id, tenant_id) REFERENCES ph12_iam.custom_role (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_custom_role_permission_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_custom_role_permission_code CHECK (permission_code ~ '^PERM-[0-9]{2}-[a-z][a-z0-9-]*$')
);
CALL ph12_iam.p_enable_rls('ph12_iam.custom_role_permission', 'P');
COMMENT ON TABLE ph12_iam.custom_role_permission IS 'Quyền PERM-{PH}-{động từ} trong vai trò tùy biến. Quyền phải có trong D02-08 và không đặc quyền (BR-12-007): dịch vụ kiểm theo permissions.json, CSDL chỉ kiểm định dạng.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.custom_role_permission CASCADE;

-- @file 12-0030-grant.sql
-- @changeset ph12-0300-privileged-grant
CREATE TABLE ph12_iam.privileged_grant (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  user_id          uuid          NOT NULL,
  role_code        varchar(64)   NOT NULL,
  target_tenant    varchar(16)   NOT NULL,
  reason           varchar(2000) NOT NULL,
  ticket_ref       varchar(64)   NOT NULL,
  requested_hours  smallint      NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'REQUESTED',
  requested_by     varchar(64)   NOT NULL,
  approved_by      varchar(64),
  starts_at        timestamptz,
  expires_at       timestamptz,
  decided_at       timestamptz,
  decision_note    varchar(1000),
  revoked_by       varchar(64),
  revoked_reason   varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_privileged_grant PRIMARY KEY (id),
  CONSTRAINT uq_privileged_grant_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_privileged_grant_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_privileged_grant_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$' AND target_tenant ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_privileged_grant_cross CHECK (target_tenant = tenant_id OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_privileged_grant_role CHECK (role_code ~ '^[A-Z][A-Z0-9_]{2,63}$'),
  CONSTRAINT ck_privileged_grant_hours CHECK (requested_hours BETWEEN 1 AND 4),
  CONSTRAINT ck_privileged_grant_state CHECK (state IN ('REQUESTED', 'ACTIVE', 'REJECTED', 'CANCELLED', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_privileged_grant_ticket CHECK (ticket_ref ~ '^[A-Za-z0-9][A-Za-z0-9._#/-]{2,63}$'),
  CONSTRAINT ck_privileged_grant_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_privileged_grant_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_privileged_grant_window CHECK (state NOT IN ('ACTIVE', 'EXPIRED', 'REVOKED') OR (starts_at IS NOT NULL AND expires_at IS NOT NULL AND approved_by IS NOT NULL)),
  CONSTRAINT ck_privileged_grant_max CHECK (starts_at IS NULL OR expires_at IS NULL OR (expires_at > starts_at AND expires_at <= starts_at + interval '4 hours')),
  CONSTRAINT ck_privileged_grant_revoked CHECK (state <> 'REVOKED' OR (revoked_by IS NOT NULL AND revoked_reason IS NOT NULL))
);
CREATE INDEX ix_privileged_grant_target ON ph12_iam.privileged_grant (target_tenant, state, expires_at);
CREATE INDEX ix_privileged_grant_user ON ph12_iam.privileged_grant (tenant_id, user_id, state);
CREATE INDEX ix_privileged_grant_expiry ON ph12_iam.privileged_grant (expires_at) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_privileged_grant_touch BEFORE UPDATE ON ph12_iam.privileged_grant FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.privileged_grant', 'G');
COMMENT ON TABLE ph12_iam.privileged_grant IS 'EN-12-11 Quyền có thời hạn: vai trò đặc quyền hoặc truy cập tenant khác, tối đa 4 giờ, mã phiếu, người duyệt thứ hai (FR-12-017, BR-12-032, EVT-12-11). Dòng ACTIVE vào gói dữ liệu platform (grants); OPA kiểm hạn ở mọi quyết định. RLS mẫu G: quản trị tỉnh bị truy cập đọc được dòng có target_tenant của mình.';
COMMENT ON COLUMN ph12_iam.privileged_grant.tenant_id IS 'Tenant của người nhận quyền (PLATFORM với nhân sự nền tảng); khóa ngoại kép tới user_account.';
COMMENT ON COLUMN ph12_iam.privileged_grant.target_tenant IS 'Tenant được truy cập; khác tenant_id chỉ khi người nhận thuộc PLATFORM (BR-12-031). Mẫu G cho tenant này đọc dòng.';
COMMENT ON COLUMN ph12_iam.privileged_grant.ticket_ref IS 'Mã phiếu hỗ trợ; ở bản này chỉ kiểm định dạng (Q12-15 của FRS).';
COMMENT ON COLUMN ph12_iam.privileged_grant.requested_hours IS 'Số giờ đề nghị 1…4, trần cứng 4 giờ; tham số 12.jit.max-hours có thể thu hẹp.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.privileged_grant CASCADE;

-- @changeset ph12-0310-recert-campaign
CREATE TABLE ph12_iam.recert_campaign (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(40)   NOT NULL,
  kind             varchar(8)    NOT NULL,
  scope_ref        varchar(64),
  state            varchar(8)    NOT NULL DEFAULT 'OPEN',
  opens_at         timestamptz   NOT NULL DEFAULT now(),
  due_at           timestamptz   NOT NULL,
  closed_at        timestamptz,
  total_items      integer       NOT NULL DEFAULT 0,
  kept_items       integer       NOT NULL DEFAULT 0,
  revoked_items    integer       NOT NULL DEFAULT 0,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_recert_campaign PRIMARY KEY (id),
  CONSTRAINT uq_recert_campaign_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_recert_campaign_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_recert_campaign_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_recert_campaign_kind CHECK (kind IN ('ADMIN', 'OTHER')),
  CONSTRAINT ck_recert_campaign_state CHECK (state IN ('OPEN', 'CLOSED')),
  CONSTRAINT ck_recert_campaign_due CHECK (due_at > opens_at AND due_at <= opens_at + interval '30 days'),
  CONSTRAINT ck_recert_campaign_closed CHECK ((state = 'CLOSED') = (closed_at IS NOT NULL)),
  CONSTRAINT ck_recert_campaign_counts CHECK (kept_items + revoked_items <= total_items)
);
CREATE UNIQUE INDEX uq_recert_campaign_open ON ph12_iam.recert_campaign (tenant_id, kind, coalesce(scope_ref, '')) WHERE state = 'OPEN';
CREATE TRIGGER tg_recert_campaign_touch BEFORE UPDATE ON ph12_iam.recert_campaign FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.recert_campaign', 'P');
COMMENT ON TABLE ph12_iam.recert_campaign IS 'EN-12-17 Chiến dịch rà soát quyền định kỳ (FR-12-018, Đợt 2). Một chiến dịch mở cho mỗi (loại, phạm vi) (ERR-12-031). Hạn trả lời tối đa 30 ngày, mặc định 14 (12.recert.deadline-days).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.recert_campaign CASCADE;

-- @changeset ph12-0320-recert-item
CREATE TABLE ph12_iam.recert_item (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  campaign_id      uuid          NOT NULL,
  user_id          uuid          NOT NULL,
  assignment_id    uuid          NOT NULL,
  reviewer_user_id uuid          NOT NULL,
  decision         varchar(10)   NOT NULL DEFAULT 'PENDING',
  decided_at       timestamptz,
  note             varchar(1000),
  last_reminded_at timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_recert_item PRIMARY KEY (id),
  CONSTRAINT uq_recert_item UNIQUE (campaign_id, assignment_id),
  CONSTRAINT fk_recert_item_campaign FOREIGN KEY (campaign_id, tenant_id) REFERENCES ph12_iam.recert_campaign (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_recert_item_user FOREIGN KEY (user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT fk_recert_item_assignment FOREIGN KEY (assignment_id, tenant_id) REFERENCES ph12_iam.role_assignment (id, tenant_id),
  CONSTRAINT fk_recert_item_reviewer FOREIGN KEY (reviewer_user_id, tenant_id) REFERENCES ph12_iam.user_account (id, tenant_id),
  CONSTRAINT ck_recert_item_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_recert_item_decision CHECK (decision IN ('PENDING', 'KEEP', 'REVOKE', 'AUTO_REVOKE')),
  CONSTRAINT ck_recert_item_no_self CHECK (reviewer_user_id <> user_id),
  CONSTRAINT ck_recert_item_decided CHECK ((decision = 'PENDING') = (decided_at IS NULL))
);
CREATE INDEX ix_recert_item_reviewer ON ph12_iam.recert_item (tenant_id, reviewer_user_id) WHERE decision = 'PENDING';
CREATE INDEX ix_recert_item_campaign ON ph12_iam.recert_item (tenant_id, campaign_id, decision);
CREATE TRIGGER tg_recert_item_touch BEFORE UPDATE ON ph12_iam.recert_item FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.recert_item', 'P');
COMMENT ON TABLE ph12_iam.recert_item IS 'Từng gán vai trò cần rà soát và quyết định của người quản lý trực tiếp (hoặc TA, SO của đơn vị, Q12-08). Không tự rà quyền của mình (BR-12-044); quá hạn không trả lời thì AUTO_REVOKE và gỡ gán.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.recert_item CASCADE;
