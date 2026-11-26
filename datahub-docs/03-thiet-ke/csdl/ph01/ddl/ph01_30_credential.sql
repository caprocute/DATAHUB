-- =============================================================================
-- D03-03-PH01 · Tệp 30: định danh ứng dụng, bàn giao, kiểm thử SANDBOX, saga cấp định danh, cắt quyền.
-- Chạy sau ph01_20_demand_review.sql.
-- Không có cột nào chứa bí mật hay liên kết gốc (BR-01-005, BR-01-007): chỉ secret_ref, số phiên bản,
-- dấu vân tay, giá trị băm và mã bọc đã mã hóa bằng khóa transit (wrap_token_sealed).
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0030-credential.sql
-- @changeset ph01-0300-app-credential splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_app_credential_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE m record;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT status, sandbox_passed_at INTO m FROM ph01_onboarding.member_system WHERE id = NEW.member_system_id;
    IF NOT FOUND OR m.status NOT IN ('APPROVED', 'ACTIVE') THEN
      RAISE EXCEPTION 'Chỉ cấp định danh cho HTTT đã được phê duyệt hoặc đang hoạt động (FR-01-020)' USING ERRCODE = '23514';
    END IF;
    IF NEW.environment = 'PRODUCTION' AND m.sandbox_passed_at IS NULL THEN
      RAISE EXCEPTION 'Chưa qua kiểm thử SANDBOX, không cấp định danh PRODUCTION (BR-01-008, ERR-01-031)' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.tenant_id <> OLD.tenant_id OR NEW.member_system_id <> OLD.member_system_id OR NEW.environment <> OLD.environment
     OR NEW.auth_method <> OLD.auth_method OR NEW.client_id <> OLD.client_id OR NEW.issued_at <> OLD.issued_at THEN
    RAISE EXCEPTION 'Danh tính của định danh ứng dụng bất biến; muốn đổi phải cấp định danh mới' USING ERRCODE = '23514';
  END IF;
  IF OLD.secret_ref IS NOT NULL AND NEW.secret_ref IS DISTINCT FROM OLD.secret_ref THEN
    RAISE EXCEPTION 'secret_ref bất biến (đường dẫn suy ra từ mã HTTT và môi trường)' USING ERRCODE = '23514';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
       (OLD.status, NEW.status) IN (VALUES ('PENDING', 'ACTIVE'), ('PENDING', 'REVOKED'), ('ACTIVE', 'ROTATING'), ('ACTIVE', 'REVOKED'),
                                           ('ACTIVE', 'EXPIRED'), ('ROTATING', 'ACTIVE'), ('ROTATING', 'REVOKED'))
       OR (OLD.status = 'REVOKED' AND NEW.status = 'ACTIVE' AND OLD.revoke_reversible)) THEN
    RAISE EXCEPTION 'Chuyển trạng thái định danh % → % không hợp lệ (ERR-01-005)', OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_app_credential_guard() IS 'Điều kiện cấp (HTTT đã duyệt, PRODUCTION cần SANDBOX đạt), danh tính bất biến, bảng chuyển trạng thái; REVOKED chỉ bật lại được khi revoke_reversible.';

CREATE TABLE ph01_onboarding.app_credential (
  id                      uuid          NOT NULL,
  tenant_id               varchar(16)   NOT NULL,
  member_system_id        uuid          NOT NULL,
  environment             varchar(10)   NOT NULL,
  auth_method             varchar(15)   NOT NULL,
  client_id               varchar(128)  NOT NULL,
  secret_ref              varchar(255),
  secret_version          integer,
  previous_secret_version integer,
  cert_fingerprint        char(64),
  jwks_ref                varchar(255),
  granted_scopes          varchar(100)[] NOT NULL DEFAULT '{}',
  status                  varchar(8)    NOT NULL DEFAULT 'PENDING',
  saga_id                 uuid,
  issued_at               timestamptz   NOT NULL DEFAULT now(),
  expires_at              timestamptz   NOT NULL,
  secret_issued_at        timestamptz,
  secret_expires_at       timestamptz,
  last_used_at            timestamptz,
  rotation_started_at     timestamptz,
  rotation_ends_at        timestamptz,
  revoked_at              timestamptz,
  revoked_by              varchar(64),
  revoked_reason          varchar(1000),
  revoke_reversible       boolean       NOT NULL DEFAULT false,
  created_at              timestamptz   NOT NULL DEFAULT now(),
  created_by              varchar(64)   NOT NULL,
  updated_at              timestamptz   NOT NULL DEFAULT now(),
  updated_by              varchar(64)   NOT NULL,
  version                 integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app_credential PRIMARY KEY (id),
  CONSTRAINT uq_app_credential_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_app_credential_client UNIQUE (tenant_id, client_id),
  CONSTRAINT fk_app_credential_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT ck_app_credential_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_app_credential_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_app_credential_method CHECK (auth_method IN ('CLIENT_SECRET', 'PRIVATE_KEY_JWT', 'MTLS', 'API_KEY')),
  CONSTRAINT ck_app_credential_client_id CHECK (client_id ~ '^[a-z0-9][a-z0-9._-]{2,127}$' AND left(client_id, 4) = lower(tenant_id) || '-'),
  CONSTRAINT ck_app_credential_secret_ref CHECK (secret_ref IS NULL OR
        (secret_ref ~ '^kv/dh/t[0-9]{2}/clients/[A-Z][A-Z0-9-]{2,63}/(sandbox|production)$'
         AND split_part(secret_ref, '/', 3) = lower(tenant_id)
         AND split_part(secret_ref, '/', 6) = lower(environment))),
  CONSTRAINT ck_app_credential_secret_method CHECK (auth_method IN ('CLIENT_SECRET', 'API_KEY') OR (secret_ref IS NULL AND secret_version IS NULL AND secret_expires_at IS NULL)),
  CONSTRAINT ck_app_credential_secret_live CHECK (status NOT IN ('ACTIVE', 'ROTATING') OR auth_method NOT IN ('CLIENT_SECRET', 'API_KEY')
        OR (secret_ref IS NOT NULL AND secret_version >= 1 AND secret_issued_at IS NOT NULL AND secret_expires_at IS NOT NULL)),
  CONSTRAINT ck_app_credential_secret_ttl CHECK (secret_expires_at IS NULL
        OR (secret_issued_at IS NOT NULL AND secret_expires_at > secret_issued_at AND secret_expires_at <= secret_issued_at + interval '180 days')),
  CONSTRAINT ck_app_credential_cert CHECK (cert_fingerprint IS NULL OR (auth_method = 'MTLS' AND cert_fingerprint ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_app_credential_jwks CHECK (jwks_ref IS NULL OR auth_method = 'PRIVATE_KEY_JWT'),
  CONSTRAINT ck_app_credential_status CHECK (status IN ('PENDING', 'ACTIVE', 'ROTATING', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_app_credential_expiry CHECK (expires_at > issued_at AND expires_at <= issued_at + interval '12 months'),
  CONSTRAINT ck_app_credential_rotation CHECK ((status = 'ROTATING') = (rotation_ends_at IS NOT NULL)
        AND (rotation_ends_at IS NULL OR (rotation_started_at IS NOT NULL AND rotation_ends_at >= rotation_started_at AND rotation_ends_at <= rotation_started_at + interval '14 days'))),
  CONSTRAINT ck_app_credential_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_by IS NOT NULL AND revoked_reason IS NOT NULL)
        AND (revoked_reason IS NULL OR char_length(revoked_reason) >= 10)),
  CONSTRAINT ck_app_credential_reversible CHECK (NOT revoke_reversible OR status = 'REVOKED'),
  CONSTRAINT ck_app_credential_scopes_new CHECK (status <> 'PENDING' OR cardinality(granted_scopes) = 0)
);
CREATE UNIQUE INDEX uq_app_credential_live ON ph01_onboarding.app_credential (tenant_id, member_system_id, environment) WHERE status IN ('PENDING', 'ACTIVE', 'ROTATING');
CREATE INDEX ix_app_credential_system ON ph01_onboarding.app_credential (tenant_id, member_system_id, environment);
CREATE INDEX ix_app_credential_expiry ON ph01_onboarding.app_credential (expires_at) WHERE status IN ('ACTIVE', 'ROTATING');
CREATE INDEX ix_app_credential_secret_expiry ON ph01_onboarding.app_credential (secret_expires_at) WHERE status IN ('ACTIVE', 'ROTATING') AND secret_expires_at IS NOT NULL;
CREATE INDEX ix_app_credential_rotation ON ph01_onboarding.app_credential (rotation_ends_at) WHERE status = 'ROTATING';
CREATE INDEX ix_app_credential_inactive ON ph01_onboarding.app_credential (tenant_id, last_used_at NULLS FIRST) WHERE status = 'ACTIVE' AND environment = 'PRODUCTION';
CREATE TRIGGER tg_app_credential_guard BEFORE INSERT OR UPDATE ON ph01_onboarding.app_credential FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_app_credential_guard();
CREATE TRIGGER tg_app_credential_touch BEFORE UPDATE ON ph01_onboarding.app_credential FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.app_credential', 'P');
COMMENT ON TABLE ph01_onboarding.app_credential IS 'EN-01-08 Định danh ứng dụng (DD-05) theo môi trường SANDBOX hoặc PRODUCTION. KHÔNG lưu bí mật, khóa riêng (BR-01-007): chỉ secret_ref (đường dẫn OpenBao), số phiên bản, dấu vân tay chứng thư (FR-01-020…028).';
COMMENT ON COLUMN ph01_onboarding.app_credential.client_id IS 'Client ID Keycloak, tên {tenant}-{systemCode}-sbx hoặc -prd chữ thường; duy nhất trong tenant (realm), phải mở đầu bằng mã tenant (SEC-82).';
COMMENT ON COLUMN ph01_onboarding.app_credential.secret_ref IS 'Đường dẫn OpenBao kv/dh/{tenant}/clients/{systemCode}/{env}; ràng buộc khớp mẫu nên không thể ghi giá trị bí mật vào cột này (BR-01-007).';
COMMENT ON COLUMN ph01_onboarding.app_credential.secret_version IS 'Số phiên bản bí mật hiện hành ở OpenBao; previous_secret_version là phiên bản cũ trong thời gian chuyển tiếp xoay vòng (BR-01-021).';
COMMENT ON COLUMN ph01_onboarding.app_credential.cert_fingerprint IS 'SHA-256 chứng thư máy khách (hex thường), chỉ với MTLS.';
COMMENT ON COLUMN ph01_onboarding.app_credential.jwks_ref IS 'Tham chiếu tập khóa công khai đã đăng ký ở PH-12, chỉ với PRIVATE_KEY_JWT.';
COMMENT ON COLUMN ph01_onboarding.app_credential.granted_scopes IS 'Scope dữ liệu đã gán; rỗng khi mới cấp (BR-01-003), nằm trong trần phạm vi và đăng ký đã duyệt ở PH-02 (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph01_onboarding.app_credential.status IS 'PENDING (trạng thái kỹ thuật của bước RECORD trong saga, thêm so với D02-07), ACTIVE, ROTATING, REVOKED, EXPIRED.';
COMMENT ON COLUMN ph01_onboarding.app_credential.expires_at IS 'Hạn định danh tối đa 12 tháng từ lúc cấp (DD-05, BR-01-020); secret_expires_at tối đa 180 ngày từ secret_issued_at (SEC-24).';
COMMENT ON COLUMN ph01_onboarding.app_credential.revoke_reversible IS 'true khi bị vô hiệu vì không hoạt động 90 ngày và bật lại được (BR-01-022); các lý do khác không hoàn tác.';
COMMENT ON COLUMN ph01_onboarding.app_credential.saga_id IS 'Saga cấp định danh (provisioning_saga.id) tạo ra bản ghi; không khóa ngoại để tránh vòng phụ thuộc.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.app_credential CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_app_credential_guard();

-- @changeset ph01-0310-handover splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_handover_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c record; k record; m record;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT member_system_id, auth_method INTO c FROM ph01_onboarding.app_credential WHERE id = NEW.credential_id;
    SELECT member_system_id, contact_type, user_account_id, status INTO k FROM ph01_onboarding.contact WHERE id = NEW.recipient_contact_id;
    SELECT status INTO m FROM ph01_onboarding.member_system WHERE id = NEW.member_system_id;
    IF c.member_system_id IS DISTINCT FROM NEW.member_system_id OR k.member_system_id IS DISTINCT FROM NEW.member_system_id THEN
      RAISE EXCEPTION 'Định danh và người nhận phải thuộc cùng HTTT với bàn giao' USING ERRCODE = '23514';
    END IF;
    IF k.contact_type <> 'TECHNICAL' OR k.status <> 'ACTIVE' THEN
      RAISE EXCEPTION 'Chỉ bàn giao cho đầu mối kỹ thuật đang hoạt động (FR-01-022)' USING ERRCODE = '23514';
    END IF;
    IF k.user_account_id IS NULL THEN
      RAISE EXCEPTION 'Đầu mối chưa có tài khoản, không bàn giao được (ERR-01-003)' USING ERRCODE = '23514';
    END IF;
    IF m.status = 'SUSPENDED' THEN
      RAISE EXCEPTION 'HTTT đang tạm ngừng, không tạo bàn giao mới (ERR-01-048)' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.tenant_id <> OLD.tenant_id OR NEW.member_system_id <> OLD.member_system_id OR NEW.credential_id <> OLD.credential_id
     OR NEW.recipient_contact_id <> OLD.recipient_contact_id OR NEW.link_hash <> OLD.link_hash OR NEW.expires_at <> OLD.expires_at THEN
    RAISE EXCEPTION 'Liên kết, người nhận, hạn của bàn giao bất biến (BR-01-006)' USING ERRCODE = '23514';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status AND NOT ((OLD.status, NEW.status) IN (VALUES
       ('PENDING', 'OPENING'), ('PENDING', 'EXPIRED'), ('PENDING', 'CANCELLED'),
       ('OPENING', 'OPENED'), ('OPENING', 'PENDING'), ('OPENING', 'CANCELLED'))) THEN
    RAISE EXCEPTION 'Chuyển trạng thái bàn giao % → % không hợp lệ; mở đúng một lần (BR-01-006)', OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  IF OLD.status IN ('OPENED', 'EXPIRED', 'CANCELLED') AND NEW.status = OLD.status AND NEW.failed_attempts <> OLD.failed_attempts THEN
    RAISE EXCEPTION 'Bàn giao đã kết thúc không đổi nữa' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_handover_guard() IS 'Người nhận là đầu mối kỹ thuật có tài khoản của đúng HTTT; liên kết, hạn bất biến; bảng chuyển trạng thái, mở đúng một lần (BR-01-005, BR-01-006).';

CREATE TABLE ph01_onboarding.handover (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  member_system_id      uuid          NOT NULL,
  credential_id         uuid          NOT NULL,
  recipient_contact_id  uuid          NOT NULL,
  link_hash             char(64)      NOT NULL,
  wrap_accessor         varchar(128),
  wrap_token_sealed     text,
  status                varchar(9)    NOT NULL DEFAULT 'PENDING',
  cancel_reason         varchar(16),
  failed_attempts       smallint      NOT NULL DEFAULT 0,
  expires_at            timestamptz   NOT NULL,
  opened_at             timestamptz,
  opened_by             varchar(64),
  opened_ip             inet,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_handover PRIMARY KEY (id),
  CONSTRAINT uq_handover_link UNIQUE (link_hash),
  CONSTRAINT fk_handover_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_handover_credential FOREIGN KEY (credential_id, tenant_id) REFERENCES ph01_onboarding.app_credential (id, tenant_id),
  CONSTRAINT fk_handover_recipient FOREIGN KEY (recipient_contact_id, tenant_id) REFERENCES ph01_onboarding.contact (id, tenant_id),
  CONSTRAINT ck_handover_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_handover_hash CHECK (link_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_handover_status CHECK (status IN ('PENDING', 'OPENING', 'OPENED', 'EXPIRED', 'CANCELLED')),
  CONSTRAINT ck_handover_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '72 hours'),
  CONSTRAINT ck_handover_attempts CHECK (failed_attempts BETWEEN 0 AND 10),
  CONSTRAINT ck_handover_cancel CHECK ((status = 'CANCELLED') = (cancel_reason IS NOT NULL)
        AND (cancel_reason IS NULL OR cancel_reason IN ('REPLACED', 'ROTATED', 'REVOKED', 'LOCKED', 'OPEN_INTERRUPTED', 'LINK_LEAKED', 'SUSPENDED', 'OTHER'))),
  CONSTRAINT ck_handover_opened CHECK ((status = 'OPENED') = (opened_at IS NOT NULL AND opened_by IS NOT NULL AND opened_ip IS NOT NULL)),
  CONSTRAINT ck_handover_sealed CHECK (status IN ('PENDING', 'OPENING') OR wrap_token_sealed IS NULL),
  CONSTRAINT ck_handover_wrap_pair CHECK (status <> 'PENDING' OR ((wrap_token_sealed IS NULL) = (wrap_accessor IS NULL)))
);
CREATE UNIQUE INDEX uq_handover_pending ON ph01_onboarding.handover (tenant_id, credential_id) WHERE status IN ('PENDING', 'OPENING');
CREATE INDEX ix_handover_due ON ph01_onboarding.handover (expires_at) WHERE status = 'PENDING';
CREATE INDEX ix_handover_opening ON ph01_onboarding.handover (updated_at) WHERE status = 'OPENING';
CREATE INDEX ix_handover_system ON ph01_onboarding.handover (tenant_id, member_system_id, created_at DESC);
CREATE TRIGGER tg_handover_guard BEFORE INSERT OR UPDATE ON ph01_onboarding.handover FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_handover_guard();
CREATE TRIGGER tg_handover_touch BEFORE UPDATE ON ph01_onboarding.handover FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.handover', 'P');
COMMENT ON TABLE ph01_onboarding.handover IS 'EN-01-09 Bàn giao thông tin xác thực một lần qua bọc phản hồi OpenBao (FR-01-022; BR-01-005, 006). Không lưu liên kết gốc: chỉ SHA-256 của liên kết, accessor và mã bọc đã mã hóa bằng khóa transit dh-{tenant}-handover. Giữ 3 năm.';
COMMENT ON COLUMN ph01_onboarding.handover.link_hash IS 'SHA-256 (hex) của mã liên kết 256 bit; duy nhất toàn bảng; không có cột chứa liên kết gốc (NFR-01-010).';
COMMENT ON COLUMN ph01_onboarding.handover.wrap_token_sealed IS 'Mã bọc OpenBao mã hóa bằng transit (AAD gồm tenant_id và id), chỉ tồn tại khi PENDING hoặc OPENING, đặt NULL ngay khi rời hai trạng thái đó (ck_handover_sealed). Cột thêm so với EN-01-09 (Q01-21).';
COMMENT ON COLUMN ph01_onboarding.handover.status IS 'PENDING, OPENING (trạng thái kỹ thuật chiếm chỗ bằng UPDATE có điều kiện, chặn hai người mở đồng thời), OPENED, EXPIRED, CANCELLED.';
COMMENT ON COLUMN ph01_onboarding.handover.expires_at IS 'Hạn liên kết, mặc định created_at cộng handover.ttlHours (24 giờ); trần cứng 72 giờ (NFR-01-010).';
COMMENT ON COLUMN ph01_onboarding.handover.failed_attempts IS 'Số lần mở sai người; chạm handover.maxFailedOpens (mặc định 5, trần 10) thì CANCELLED với LOCKED (ERR-01-026).';
COMMENT ON COLUMN ph01_onboarding.handover.cancel_reason IS 'REPLACED (tạo lại), ROTATED, REVOKED, SUSPENDED, LOCKED, OPEN_INTERRUPTED (tiến trình chết lúc mở, phải xoay vòng), LINK_LEAKED (mã bọc đã bị dùng), OTHER.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.handover CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_handover_guard();

-- @changeset ph01-0320-sandbox-test
CREATE TABLE ph01_onboarding.sandbox_test (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  credential_id     uuid,
  source            varchar(8)    NOT NULL,
  observed_at       timestamptz   NOT NULL,
  auth_ok           boolean       NOT NULL,
  api_ok            boolean       NOT NULL,
  call_count        integer       NOT NULL DEFAULT 0,
  success_count     integer       NOT NULL DEFAULT 0,
  error_detail      varchar(2000),
  received_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_sandbox_test PRIMARY KEY (id),
  CONSTRAINT fk_sandbox_test_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_sandbox_test_credential FOREIGN KEY (credential_id, tenant_id) REFERENCES ph01_onboarding.app_credential (id, tenant_id),
  CONSTRAINT ck_sandbox_test_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sandbox_test_source CHECK (source IN ('PH03', 'PH13', 'MANUAL')),
  CONSTRAINT ck_sandbox_test_counts CHECK (call_count >= 0 AND success_count BETWEEN 0 AND call_count),
  CONSTRAINT ck_sandbox_test_error CHECK (error_detail IS NULL OR error_detail !~* 'secret|password|bearer\s')
);
CREATE INDEX ix_sandbox_test_system ON ph01_onboarding.sandbox_test (tenant_id, member_system_id, observed_at DESC);
CREATE INDEX ix_sandbox_test_retention ON ph01_onboarding.sandbox_test (observed_at);
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.sandbox_test', 'P');
COMMENT ON TABLE ph01_onboarding.sandbox_test IS 'EN-01-10 Kết quả kiểm thử SANDBOX nhận từ PH-03, PH-13, chỉ thêm; giữ 1 năm rồi dọn theo lô (FR-01-023, NFR-01-022). Ước 1 triệu dòng mỗi năm ở tỉnh vừa, chưa phân vùng (SDD §11.3).';
COMMENT ON COLUMN ph01_onboarding.sandbox_test.success_count IS 'Số lượt gọi API thành công trong khoảng quan sát; so với sandbox.requiredSuccessfulCalls để quyết định đạt (FR-01-023).';
COMMENT ON COLUMN ph01_onboarding.sandbox_test.error_detail IS 'Chi tiết lỗi đã che; ràng buộc chặn từ khóa bí mật như lớp phòng thủ thứ hai (NFR-01-009).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.sandbox_test CASCADE;

-- @file 01-0031-saga.sql
-- @changeset ph01-0330-provisioning-saga
CREATE TABLE ph01_onboarding.provisioning_saga (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  environment       varchar(10)   NOT NULL,
  complete_with     varchar(8)    NOT NULL DEFAULT 'NONE',
  state             varchar(12)   NOT NULL DEFAULT 'PENDING',
  attempt           integer       NOT NULL DEFAULT 0,
  next_run_at       timestamptz   NOT NULL DEFAULT now(),
  started_at        timestamptz   NOT NULL DEFAULT now(),
  deadline_at       timestamptz   NOT NULL,
  finished_at       timestamptz,
  credential_id     uuid,
  async_callback    boolean       NOT NULL DEFAULT false,
  last_error_code   varchar(16),
  last_error_detail varchar(1000),
  requested_by      varchar(64)   NOT NULL,
  trace_id          char(32)      NOT NULL,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_saga PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_saga_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_provisioning_saga_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_provisioning_saga_credential FOREIGN KEY (credential_id, tenant_id) REFERENCES ph01_onboarding.app_credential (id, tenant_id),
  CONSTRAINT ck_provisioning_saga_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_provisioning_saga_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_provisioning_saga_complete CHECK (complete_with IN ('NONE', 'ACTIVATE') AND (complete_with = 'NONE' OR environment = 'PRODUCTION')),
  CONSTRAINT ck_provisioning_saga_state CHECK (state IN ('PENDING', 'RUNNING', 'WAITING_RETRY', 'COMPENSATING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_provisioning_saga_attempt CHECK (attempt >= 0),
  CONSTRAINT ck_provisioning_saga_deadline CHECK (deadline_at > started_at),
  CONSTRAINT ck_provisioning_saga_finished CHECK ((state IN ('SUCCEEDED', 'FAILED', 'CANCELLED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_provisioning_saga_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_provisioning_saga_error CHECK (last_error_detail IS NULL OR last_error_detail !~* 'secret|password|bearer\s')
);
CREATE UNIQUE INDEX uq_provisioning_saga_running ON ph01_onboarding.provisioning_saga (tenant_id, member_system_id, environment)
  WHERE state IN ('PENDING', 'RUNNING', 'WAITING_RETRY', 'COMPENSATING');
CREATE INDEX ix_provisioning_saga_due ON ph01_onboarding.provisioning_saga (tenant_id, next_run_at) WHERE state IN ('PENDING', 'WAITING_RETRY');
CREATE INDEX ix_provisioning_saga_system ON ph01_onboarding.provisioning_saga (tenant_id, member_system_id, started_at DESC);
CREATE TRIGGER tg_provisioning_saga_touch BEFORE UPDATE ON ph01_onboarding.provisioning_saga FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.provisioning_saga', 'P');
COMMENT ON TABLE ph01_onboarding.provisioning_saga IS 'Saga cấp định danh bền trong CSDL (FR-01-020, 024; NFR-01-004): bộ chạy lấy việc bằng FOR UPDATE SKIP LOCKED, id là sagaId bất biến dùng làm khóa lũy đẳng cho PH-12, PH-03. Chèn cùng giao dịch với phê duyệt. Mỗi (HTTT, môi trường) tối đa một saga đang chạy.';
COMMENT ON COLUMN ph01_onboarding.provisioning_saga.complete_with IS 'ACTIVATE: bước FINALIZE của saga PRODUCTION chuyển HTTT APPROVED → ACTIVE trong cùng giao dịch cục bộ (SDD §4.6).';
COMMENT ON COLUMN ph01_onboarding.provisioning_saga.next_run_at IS 'Lịch thử lại lùi 1, 2, 4, 8, 15 phút rồi mỗi 15 phút tới deadline_at (started_at cộng 24 giờ).';
COMMENT ON COLUMN ph01_onboarding.provisioning_saga.state IS 'PENDING, RUNNING, WAITING_RETRY, COMPENSATING, SUCCEEDED, FAILED (quá hạn hoặc lỗi nghiệp vụ không tự khỏi, đặt provision_stage = PROVISION_FAILED), CANCELLED.';
COMMENT ON COLUMN ph01_onboarding.provisioning_saga.last_error_detail IS 'Mô tả lỗi đã che; không chứa bí mật (ràng buộc chặn từ khóa).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.provisioning_saga CASCADE;

-- @changeset ph01-0340-saga-step
CREATE TABLE ph01_onboarding.saga_step (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  saga_id          uuid          NOT NULL,
  step_name        varchar(8)    NOT NULL,
  step_no          smallint      NOT NULL,
  status           varchar(11)   NOT NULL DEFAULT 'PENDING',
  attempt          integer       NOT NULL DEFAULT 0,
  idempotency_key  varchar(80)   NOT NULL,
  external_ref     varchar(255),
  started_at       timestamptz,
  accepted_until   timestamptz,
  finished_at      timestamptz,
  compensated_at   timestamptz,
  error_code       varchar(16),
  error_detail     varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_step PRIMARY KEY (id),
  CONSTRAINT uq_saga_step UNIQUE (tenant_id, saga_id, step_name),
  CONSTRAINT fk_saga_step_saga FOREIGN KEY (saga_id, tenant_id) REFERENCES ph01_onboarding.provisioning_saga (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_saga_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_saga_step_name CHECK ((step_name, step_no) IN (('RECORD', 1), ('CLIENT', 2), ('CONSUMER', 3), ('FINALIZE', 4), ('HANDOVER', 5))),
  CONSTRAINT ck_saga_step_status CHECK (status IN ('PENDING', 'RUNNING', 'ACCEPTED', 'DONE', 'FAILED', 'COMPENSATED', 'SKIPPED')),
  CONSTRAINT ck_saga_step_idem CHECK (idempotency_key = saga_id::text || ':' || step_name),
  CONSTRAINT ck_saga_step_running CHECK (status NOT IN ('RUNNING', 'ACCEPTED') OR started_at IS NOT NULL),
  CONSTRAINT ck_saga_step_accepted CHECK ((status = 'ACCEPTED') = (accepted_until IS NOT NULL)),
  CONSTRAINT ck_saga_step_compensated CHECK ((status = 'COMPENSATED') = (compensated_at IS NOT NULL)),
  CONSTRAINT ck_saga_step_error CHECK (error_detail IS NULL OR error_detail !~* 'secret|password|bearer\s')
);
CREATE INDEX ix_saga_step_stale ON ph01_onboarding.saga_step (started_at) WHERE status = 'RUNNING';
CREATE INDEX ix_saga_step_accepted ON ph01_onboarding.saga_step (accepted_until) WHERE status = 'ACCEPTED';
CREATE TRIGGER tg_saga_step_touch BEFORE UPDATE ON ph01_onboarding.saga_step FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.saga_step', 'P');
COMMENT ON TABLE ph01_onboarding.saga_step IS 'Bước của saga: RECORD, CLIENT, CONSUMER, FINALIZE, HANDOVER, mỗi bước một dòng, lũy đẳng bằng idempotency_key = sagaId:bước (FR-01-020). Bước RUNNING quá 60 giây được bộ chạy gọi lại với cùng khóa; ACCEPTED chờ callback tối đa 5 phút (giả định).';
COMMENT ON COLUMN ph01_onboarding.saga_step.external_ref IS 'Mã đối tượng đã tạo ở hệ ngoài (clientId của PH-12, consumerId của PH-03); không phải bí mật, dùng để bù trừ.';
COMMENT ON COLUMN ph01_onboarding.saga_step.status IS 'PENDING, RUNNING, ACCEPTED (chờ callback), DONE, FAILED, COMPENSATED (đã bù trừ), SKIPPED (bước chưa tạo gì nên bù trừ bỏ qua).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.saga_step CASCADE;

-- @changeset ph01-0350-enforcement-task
CREATE TABLE ph01_onboarding.enforcement_task (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  enforcement_id    uuid          NOT NULL,
  mode              varchar(9)    NOT NULL,
  trigger_source    varchar(16)   NOT NULL,
  seq               smallint      NOT NULL,
  task_type         varchar(16)   NOT NULL,
  client_ids        varchar(128)[] NOT NULL,
  status            varchar(7)    NOT NULL DEFAULT 'PENDING',
  attempt           integer       NOT NULL DEFAULT 0,
  next_run_at       timestamptz   NOT NULL DEFAULT now(),
  idempotency_key   varchar(80)   NOT NULL,
  started_at        timestamptz,
  finished_at       timestamptz,
  last_error_code   varchar(16),
  last_error_detail varchar(1000),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_enforcement_task PRIMARY KEY (id),
  CONSTRAINT uq_enforcement_task UNIQUE (tenant_id, enforcement_id, task_type),
  CONSTRAINT fk_enforcement_task_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT ck_enforcement_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_enforcement_task_mode CHECK (mode IN ('SUSPEND', 'RESUME', 'TERMINATE', 'REVOKE')),
  CONSTRAINT ck_enforcement_task_source CHECK (trigger_source IN ('LIFECYCLE', 'EMERGENCY', 'EXPIRY', 'LEGAL', 'INACTIVITY', 'REVIEW', 'CREDENTIAL')),
  CONSTRAINT ck_enforcement_task_order CHECK (
        (mode <> 'RESUME' AND (task_type, seq) IN (('BLOCK_GATEWAY', 1), ('DISABLE_CLIENTS', 2), ('REVOKE_TOKENS', 3), ('DISABLE_CONSUMER', 4)))
     OR (mode = 'RESUME' AND (task_type, seq) IN (('ENABLE_CONSUMER', 1), ('ENABLE_CLIENTS', 2), ('UNBLOCK_GATEWAY', 3)))),
  CONSTRAINT ck_enforcement_task_clients CHECK (cardinality(client_ids) BETWEEN 1 AND 20),
  CONSTRAINT ck_enforcement_task_status CHECK (status IN ('PENDING', 'RUNNING', 'DONE')),
  CONSTRAINT ck_enforcement_task_attempt CHECK (attempt >= 0),
  CONSTRAINT ck_enforcement_task_idem CHECK (idempotency_key = enforcement_id::text || ':' || task_type),
  CONSTRAINT ck_enforcement_task_done CHECK ((status = 'DONE') = (finished_at IS NOT NULL)),
  CONSTRAINT ck_enforcement_task_error CHECK (last_error_detail IS NULL OR last_error_detail !~* 'secret|password|bearer\s')
);
CREATE INDEX ix_enforcement_task_due ON ph01_onboarding.enforcement_task (tenant_id, next_run_at) WHERE status IN ('PENDING', 'RUNNING');
CREATE INDEX ix_enforcement_task_system ON ph01_onboarding.enforcement_task (tenant_id, member_system_id, created_at DESC);
CREATE INDEX ix_enforcement_task_group ON ph01_onboarding.enforcement_task (tenant_id, enforcement_id, seq);
CREATE TRIGGER tg_enforcement_task_touch BEFORE UPDATE ON ph01_onboarding.enforcement_task FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.enforcement_task', 'P');
COMMENT ON TABLE ph01_onboarding.enforcement_task IS 'Việc cắt quyền có thứ tự: chặn cổng, vô hiệu client, thu hồi token, vô hiệu consumer; chiều khôi phục đi ngược (FR-01-029…032, 037; BR-01-023; NFR-01-008 ≤ 60 giây). Lập cùng giao dịch với lệnh đặt trạng thái; thử lại tới khi xong, không hoàn tác trạng thái.';
COMMENT ON COLUMN ph01_onboarding.enforcement_task.enforcement_id IS 'Mã nhóm bốn (hoặc ba) việc của một lệnh; cùng nhóm cùng mode.';
COMMENT ON COLUMN ph01_onboarding.enforcement_task.client_ids IS 'Tập client cố định tại thời điểm lập việc, để lũy đẳng và không đổi khi đang chạy (SDD §4.10).';
COMMENT ON COLUMN ph01_onboarding.enforcement_task.seq IS 'Thứ tự thực hiện: mode khác RESUME gồm 1 BLOCK_GATEWAY, 2 DISABLE_CLIENTS, 3 REVOKE_TOKENS, 4 DISABLE_CONSUMER; RESUME gồm 1 ENABLE_CONSUMER, 2 ENABLE_CLIENTS, 3 UNBLOCK_GATEWAY (ck_enforcement_task_order).';
COMMENT ON COLUMN ph01_onboarding.enforcement_task.next_run_at IS 'Lịch thử lại 10, 20, 40, 60 giây rồi giữ 60 giây; quá 60 giây còn PENDING thì cảnh báo SO.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.enforcement_task CASCADE;
