-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam
-- Tệp 05: cảnh báo, báo cáo ngày, đối soát Keycloak, khóa lũy đẳng, outbox, khóa tác vụ
--         (nhóm FR-12-G, H và hạ tầng; EN-12-16)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- Nhật ký quyết định ủy quyền (EN-12-15) và sự kiện xác thực KHÔNG nằm ở PostgreSQL: Loki 12 tháng và chuỗi
-- kiểm toán PH-13 (WORM 5 năm, ADR-031, FRS §11.2).
-- =============================================================================

\set ON_ERROR_STOP on
RESET ROLE;
SET ROLE ph12_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 12-0100-alert.sql
-- @changeset ph12-1000-alert
CREATE TABLE ph12_iam.alert (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  rule_code        varchar(5)    NOT NULL,
  severity         varchar(8)    NOT NULL,
  subject_kind     varchar(8)    NOT NULL,
  subject_ref      varchar(255)  NOT NULL,
  dedup_key        varchar(255)  NOT NULL,
  detail           jsonb         NOT NULL DEFAULT '{}',
  occurrences      integer       NOT NULL DEFAULT 1,
  first_seen_at    timestamptz   NOT NULL DEFAULT now(),
  last_seen_at     timestamptz   NOT NULL DEFAULT now(),
  state            varchar(12)   NOT NULL DEFAULT 'OPEN',
  notified_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_alert PRIMARY KEY (id),
  CONSTRAINT uq_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_alert_dedup UNIQUE (tenant_id, dedup_key),
  CONSTRAINT ck_alert_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_alert_rule CHECK (rule_code ~ '^AN-0[1-9]$'),
  CONSTRAINT ck_alert_severity CHECK (severity IN ('MEDIUM', 'HIGH', 'CRITICAL')
    AND severity = CASE
      WHEN rule_code IN ('AN-05', 'AN-06', 'AN-08') THEN 'CRITICAL'
      WHEN rule_code IN ('AN-01', 'AN-02', 'AN-07') THEN 'HIGH'
      ELSE 'MEDIUM' END),
  CONSTRAINT ck_alert_subject CHECK (subject_kind IN ('USER', 'CLIENT', 'IP', 'REALM', 'ROLE')),
  CONSTRAINT ck_alert_state CHECK (state IN ('OPEN', 'ACKNOWLEDGED')),
  CONSTRAINT ck_alert_seen CHECK (occurrences >= 1 AND last_seen_at >= first_seen_at),
  CONSTRAINT ck_alert_detail CHECK (jsonb_typeof(detail) = 'object' AND NOT ph12_iam.f_json_has_secret_key(detail))
);
CREATE INDEX ix_alert_open ON ph12_iam.alert (tenant_id, severity, last_seen_at DESC) WHERE state = 'OPEN';
CREATE INDEX ix_alert_subject ON ph12_iam.alert (tenant_id, subject_kind, subject_ref, last_seen_at DESC);
CREATE INDEX ix_alert_time ON ph12_iam.alert (tenant_id, first_seen_at DESC);
CREATE TRIGGER tg_alert_touch BEFORE UPDATE ON ph12_iam.alert FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.alert', 'P');
COMMENT ON TABLE ph12_iam.alert IS 'EN-12-16 Cảnh báo an ninh do chín luật AN-01…AN-09 phát (FR-12-059, EVT-12-14). dedup_key = luật|đối tượng|ô thời gian 30 phút nên cùng sự việc trong 30 phút chỉ một dòng (tăng occurrences). Mức nghiêm trọng cố định theo luật (CHECK): AN-05, 06, 08 nghiêm trọng; AN-01, 02, 07 cao; AN-03, 04, 09 trung bình. detail chỉ có số đo và mã, không dữ liệu cá nhân hay bí mật.';
COMMENT ON COLUMN ph12_iam.alert.subject_ref IS 'Mã người dùng, clientId, địa chỉ IP (đã băm một phần theo SEC-32 khi hiển thị), tên realm hoặc mã vai trò, tùy subject_kind.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.alert CASCADE;

-- @changeset ph12-1010-alert-ack
CREATE TABLE ph12_iam.alert_ack (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  alert_id         uuid          NOT NULL,
  acked_by         varchar(64)   NOT NULL,
  acked_at         timestamptz   NOT NULL DEFAULT now(),
  note             varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_alert_ack PRIMARY KEY (id),
  CONSTRAINT uq_alert_ack_alert UNIQUE (alert_id),
  CONSTRAINT fk_alert_ack_alert FOREIGN KEY (alert_id, tenant_id) REFERENCES ph12_iam.alert (id, tenant_id),
  CONSTRAINT ck_alert_ack_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$')
);
CREATE TRIGGER tg_alert_ack_append_only BEFORE UPDATE OR DELETE ON ph12_iam.alert_ack
  FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_append_only();
CALL ph12_iam.p_enable_rls('ph12_iam.alert_ack', 'P');
COMMENT ON TABLE ph12_iam.alert_ack IS 'Xác nhận cảnh báo (PERM-12-alert): người xác nhận, thời điểm, ghi chú. Chỉ thêm, mỗi cảnh báo một xác nhận; dịch vụ đặt alert.state = ACKNOWLEDGED cùng giao dịch.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.alert_ack CASCADE;

-- @changeset ph12-1020-account-report-daily
CREATE TABLE ph12_iam.account_report_daily (
  tenant_id          varchar(16)   NOT NULL,
  report_date        date          NOT NULL,
  users_total        integer       NOT NULL,
  users_active       integer       NOT NULL,
  users_pending      integer       NOT NULL,
  users_locked       integer       NOT NULL,
  users_blocked      integer       NOT NULL,
  users_disabled     integer       NOT NULL,
  never_logged_in    integer       NOT NULL DEFAULT 0,
  inactive_30d       integer       NOT NULL DEFAULT 0,
  inactive_45d       integer       NOT NULL DEFAULT 0,
  admin_accounts     integer       NOT NULL DEFAULT 0,
  disabled_by_inactivity integer   NOT NULL DEFAULT 0,
  by_org             jsonb         NOT NULL DEFAULT '{}',
  purge_after        timestamptz   NOT NULL,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_account_report_daily PRIMARY KEY (tenant_id, report_date),
  CONSTRAINT ck_account_report_daily_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_account_report_daily_counts CHECK (users_total = users_active + users_pending + users_locked + users_blocked + users_disabled
    AND never_logged_in >= 0 AND inactive_30d >= 0 AND inactive_45d <= inactive_30d AND admin_accounts >= 0 AND disabled_by_inactivity >= 0),
  CONSTRAINT ck_account_report_daily_org CHECK (jsonb_typeof(by_org) = 'object')
);
CREATE INDEX ix_account_report_daily_purge ON ph12_iam.account_report_daily (purge_after);
CALL ph12_iam.p_enable_rls('ph12_iam.account_report_daily', 'P');
COMMENT ON TABLE ph12_iam.account_report_daily IS 'Báo cáo tình trạng tài khoản theo ngày (FR-12-060, chạy 01:30): đếm theo trạng thái, nhóm ngày không đăng nhập, số tài khoản quản trị. Khóa tự nhiên (tenant_id, report_date), tính lại được nên ghi đè khi chạy lại. Giữ 24 tháng (NFR-12-030): purge_after = report_date + 24 tháng.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.account_report_daily CASCADE;

-- @changeset ph12-1030-mfa-coverage-daily
CREATE TABLE ph12_iam.mfa_coverage_daily (
  tenant_id          varchar(16)   NOT NULL,
  report_date        date          NOT NULL,
  required_users     integer       NOT NULL,
  enrolled_users     integer       NOT NULL,
  coverage_ratio     numeric(6,5)  GENERATED ALWAYS AS (CASE WHEN required_users = 0 THEN 1 ELSE round(enrolled_users::numeric / required_users, 5) END) STORED,
  admin_required     integer       NOT NULL DEFAULT 0,
  admin_webauthn     integer       NOT NULL DEFAULT 0,
  sampled_users      integer       NOT NULL DEFAULT 0,
  sample_mismatch    integer       NOT NULL DEFAULT 0,
  checked_at         timestamptz,
  purge_after        timestamptz   NOT NULL,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_mfa_coverage_daily PRIMARY KEY (tenant_id, report_date),
  CONSTRAINT ck_mfa_coverage_daily_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_mfa_coverage_daily_counts CHECK (required_users >= 0 AND enrolled_users BETWEEN 0 AND required_users
    AND admin_required >= 0 AND admin_webauthn BETWEEN 0 AND admin_required AND sampled_users >= 0 AND sample_mismatch BETWEEN 0 AND sampled_users)
);
CREATE INDEX ix_mfa_coverage_daily_purge ON ph12_iam.mfa_coverage_daily (purge_after);
CALL ph12_iam.p_enable_rls('ph12_iam.mfa_coverage_daily', 'P');
COMMENT ON TABLE ph12_iam.mfa_coverage_daily IS 'Tỷ lệ tài khoản thuộc nhóm mfa-required đã đăng ký yếu tố thứ hai (FR-12-060, BR-12-015); đối chiếu mẫu hằng tuần với Keycloak để chống lệch (sample_mismatch). Mục tiêu 100%, quản trị nền tảng và quản trị tỉnh chỉ WebAuthn (admin_webauthn = admin_required). Giữ 24 tháng.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.mfa_coverage_daily CASCADE;

-- @file 12-0110-tech.sql
-- @changeset ph12-1100-sync-task
CREATE TABLE ph12_iam.sync_task (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  task_type        varchar(24)   NOT NULL,
  target_kind      varchar(12)   NOT NULL,
  target_id        uuid          NOT NULL,
  payload          jsonb         NOT NULL DEFAULT '{}',
  status           varchar(8)    NOT NULL DEFAULT 'PENDING',
  attempts         smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  last_error       varchar(1000),
  done_at          timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_task PRIMARY KEY (id),
  CONSTRAINT ck_sync_task_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_sync_task_type CHECK (task_type IN ('CREATE_USER', 'UPDATE_USER', 'SET_ROLES', 'DISABLE_USER', 'REVOKE_KEYCLOAK', 'CREATE_CLIENT', 'UPDATE_CLIENT', 'SUSPEND_CLIENT', 'APPLY_REALM', 'APPLY_FEDERATION')),
  CONSTRAINT ck_sync_task_target CHECK (target_kind IN ('USER', 'CLIENT', 'REALM', 'FEDERATION', 'REVOCATION')),
  CONSTRAINT ck_sync_task_status CHECK (status IN ('PENDING', 'RUNNING', 'DONE', 'FAILED') AND (status = 'DONE') = (done_at IS NOT NULL)),
  CONSTRAINT ck_sync_task_attempts CHECK (attempts BETWEEN 0 AND 20),
  CONSTRAINT ck_sync_task_payload CHECK (jsonb_typeof(payload) = 'object' AND NOT ph12_iam.f_json_has_secret_key(payload))
);
CREATE UNIQUE INDEX uq_sync_task_open ON ph12_iam.sync_task (tenant_id, task_type, target_id) WHERE status IN ('PENDING', 'RUNNING');
CREATE INDEX ix_sync_task_due ON ph12_iam.sync_task (next_attempt_at) WHERE status IN ('PENDING', 'RUNNING');
CREATE INDEX ix_sync_task_done ON ph12_iam.sync_task (done_at) WHERE status = 'DONE';
CREATE TRIGGER tg_sync_task_touch BEFORE UPDATE ON ph12_iam.sync_task FOR EACH ROW EXECUTE FUNCTION ph12_iam.tg_touch();
CALL ph12_iam.p_enable_rls('ph12_iam.sync_task', 'P');
ALTER TABLE ph12_iam.sync_task SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
COMMENT ON TABLE ph12_iam.sync_task IS 'Ý định ghi sang Keycloak, ghi cùng giao dịch với thay đổi ở ph12_iam rồi SyncReconciler thực hiện và phát lại lũy đẳng (mẫu "ghi ý định trước, thực hiện sau", SDD §4.2, §8.4). Mỗi (loại, đối tượng) một việc đang mở. payload không chứa bí mật; thu hồi vẫn ghi revocation_entry trước (SDD §4.9). Việc DONE xóa sau 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.sync_task CASCADE;

-- @changeset ph12-1110-idempotency-key
CREATE TABLE ph12_iam.idempotency_key (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  idem_key         varchar(128)  NOT NULL,
  method           varchar(8)    NOT NULL,
  path             varchar(255)  NOT NULL,
  body_hash        char(64)      NOT NULL,
  state            varchar(10)   NOT NULL DEFAULT 'PROCESSING',
  response_status  smallint,
  response_body    jsonb,
  resource_ref     varchar(255),
  expires_at       timestamptz   NOT NULL DEFAULT now() + interval '24 hours',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_idempotency_key PRIMARY KEY (id),
  CONSTRAINT uq_idempotency_key UNIQUE (tenant_id, idem_key),
  CONSTRAINT ck_idempotency_key_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_idempotency_key_key CHECK (char_length(idem_key) BETWEEN 8 AND 128),
  CONSTRAINT ck_idempotency_key_method CHECK (method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_idempotency_key_hash CHECK (body_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_key_state CHECK (state IN ('PROCESSING', 'DONE') AND (state = 'DONE') = (response_status IS NOT NULL)),
  CONSTRAINT ck_idempotency_key_response CHECK (response_body IS NULL OR NOT ph12_iam.f_json_has_secret_key(response_body))
);
CREATE INDEX ix_idempotency_key_expiry ON ph12_iam.idempotency_key (expires_at);
CALL ph12_iam.p_enable_rls('ph12_iam.idempotency_key', 'P');
ALTER TABLE ph12_iam.idempotency_key SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
COMMENT ON TABLE ph12_iam.idempotency_key IS 'Khóa lũy đẳng của API ghi (ADR-041): giữ băm thân và phản hồi 24 giờ; cùng khóa khác thân là ERR-12-045 (422). Với saga của PH-01, PH-20 khóa còn là khóa tìm lại tiến trình dở. response_body bị CHECK chặn khóa bí mật: phản hồi cấp client chỉ được lưu dạng handoverId, không có wrappingToken (BR-12-023).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.idempotency_key CASCADE;

-- @changeset ph12-1120-outbox
CREATE TABLE ph12_iam.outbox (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(12)   NOT NULL,
  aggregate_type   varchar(32)   NOT NULL,
  aggregate_id     uuid          NOT NULL,
  topic            varchar(255)  NOT NULL,
  partition_key    varchar(128)  NOT NULL,
  headers          jsonb         NOT NULL DEFAULT '{}',
  payload          jsonb         NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^EVT-12-(0[1-9]|1[0-5])$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^[a-z0-9]+\.iam\.[a-z-]+\.[a-z-]+\.v[0-9]+$' AND split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_json CHECK (jsonb_typeof(headers) = 'object' AND jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_outbox_no_secret CHECK (NOT ph12_iam.f_json_has_secret_key(payload) AND NOT ph12_iam.f_json_has_secret_key(headers))
);
CREATE INDEX ix_outbox_created ON ph12_iam.outbox (created_at);
CALL ph12_iam.p_enable_rls('ph12_iam.outbox', 'P');
ALTER TABLE ph12_iam.outbox SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
COMMENT ON TABLE ph12_iam.outbox IS 'Hộp thư đi (ADR-042, DD-11): EVT-12-01…15 ghi cùng giao dịch với thay đổi trạng thái; Debezium outbox router phát lên Kafka dạng CloudEvents (EVT-12-16 do Keycloak phát trực tiếp, không qua đây). Topic mang đúng mã tenant viết thường (platform cho tenant nền tảng, D03-10 §3) và payload không có khóa bí mật. Xóa sau 3 ngày.';
COMMENT ON COLUMN ph12_iam.outbox.partition_key IS 'Khóa phân vùng giữ thứ tự theo đối tượng: userId, clientId, policyCode, grantId, exceptionId, tenantCode hoặc alertId (SDD §8.2).';
-- @rollback DROP TABLE IF EXISTS ph12_iam.outbox CASCADE;

-- @changeset ph12-1130-shedlock
CREATE TABLE ph12_iam.shedlock (
  name             varchar(64)   NOT NULL,
  lock_until       timestamptz   NOT NULL,
  locked_at        timestamptz   NOT NULL,
  locked_by        varchar(255)  NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph12_iam.shedlock IS 'Bảng kỹ thuật của thư viện ShedLock cho tác vụ định kỳ (InactivityJob 02:00, AssignmentExpiryJob, GrantExpiryJob, SyncReconciler, DriftDetector, RecertScheduler, báo cáo ngày). Không có dữ liệu nghiệp vụ nên không có tenant_id và không bật RLS.';
-- @rollback DROP TABLE IF EXISTS ph12_iam.shedlock;
