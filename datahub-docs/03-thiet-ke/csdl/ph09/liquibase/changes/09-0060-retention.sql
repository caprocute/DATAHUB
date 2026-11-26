--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0060-retention.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0460-retention-schedule
CREATE TABLE ph09_privacy.retention_schedule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  schedule_code    varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  description      varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_schedule PRIMARY KEY (id),
  CONSTRAINT uq_retention_schedule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_retention_schedule_code CHECK (schedule_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT uq_retention_schedule_version UNIQUE (tenant_id, schedule_code, version_no),
  CONSTRAINT ck_retention_schedule_version CHECK (version_no >= 1),
  CONSTRAINT ck_retention_schedule_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_retention_schedule_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_retention_schedule_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_retention_schedule_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_retention_schedule_active ON ph09_privacy.retention_schedule (tenant_id, schedule_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_retention_schedule_touch BEFORE UPDATE ON ph09_privacy.retention_schedule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_retention_schedule_immutable BEFORE UPDATE ON ph09_privacy.retention_schedule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('schedule_code', 'version_no');
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_schedule');
COMMENT ON TABLE ph09_privacy.retention_schedule IS 'EN-09-36 Lịch lưu giữ theo phiên bản (FR-09-040, BR-09-038): mỗi dòng ở retention_schedule_line. ACTIVE không sửa; duyệt bốn mắt. Chính sách lưu giữ của chính PH-09 là lịch PH09-OWN nạp sẵn (chương 7 của tập CSDL).';
--rollback DROP TABLE IF EXISTS ph09_privacy.retention_schedule CASCADE;

--changeset ph09:ph09-0470-retention-schedule-line
CREATE TABLE ph09_privacy.retention_schedule_line (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  schedule_id uuid NOT NULL,
  entity      varchar(128) NOT NULL,
  category    varchar(32),
  retain_days integer NOT NULL,
  action      varchar(12) NOT NULL,
  owner       varchar(64) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_schedule_line PRIMARY KEY (id),
  CONSTRAINT uq_retention_schedule_line_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_schedule_line_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_retention_schedule_line_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph09_privacy.retention_schedule (tenant_id, id),
  CONSTRAINT ck_retention_schedule_line_days CHECK (retain_days BETWEEN 1 AND 36500),
  CONSTRAINT ck_retention_schedule_line_action CHECK (action IN ('DELETE', 'PSEUDONYMIZE', 'ANONYMIZE', 'ARCHIVE'))
);
CREATE UNIQUE INDEX uq_retention_schedule_line ON ph09_privacy.retention_schedule_line (tenant_id, schedule_id, entity, COALESCE(category, '*'));
CREATE TRIGGER tg_retention_schedule_line_touch BEFORE UPDATE ON ph09_privacy.retention_schedule_line FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_retention_schedule_line_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.retention_schedule_line FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('retention_schedule', 'schedule_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_schedule_line');
COMMENT ON TABLE ph09_privacy.retention_schedule_line IS 'EN-09-36 Dòng lịch lưu giữ (FR-09-040): bảng hoặc loại dữ liệu, loại DLCN, số ngày lưu, hành động RetentionAction, người chịu trách nhiệm. Nhật ký kiểm toán WORM không thuộc lịch này (BR-09-038). Chỉ sửa khi lịch DRAFT hoặc REJECTED.';
--rollback DROP TABLE IF EXISTS ph09_privacy.retention_schedule_line CASCADE;

--changeset ph09:ph09-0480-retention-task
CREATE TABLE ph09_privacy.retention_task (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  schedule_id       uuid NOT NULL,
  line_id           uuid,
  entity            varchar(128) NOT NULL,
  run_date          date NOT NULL,
  dry_run           boolean NOT NULL DEFAULT false,
  status            varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_by      varchar(64) NOT NULL,
  started_at        timestamptz,
  finished_at       timestamptz,
  rows_scanned      bigint NOT NULL DEFAULT 0,
  rows_affected     bigint NOT NULL DEFAULT 0,
  rows_skipped_hold bigint NOT NULL DEFAULT 0,
  hold_ids          uuid[] NOT NULL DEFAULT '{}',
  skipped_reason    varchar(2000),
  error_code        varchar(10),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_task PRIMARY KEY (id),
  CONSTRAINT uq_retention_task_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_retention_task_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph09_privacy.retention_schedule (tenant_id, id),
  CONSTRAINT fk_retention_task_line FOREIGN KEY (tenant_id, line_id) REFERENCES ph09_privacy.retention_schedule_line (tenant_id, id),
  CONSTRAINT ck_retention_task_status CHECK (status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_retention_task_rows CHECK (rows_scanned >= 0 AND rows_affected >= 0 AND rows_skipped_hold >= 0 AND rows_affected + rows_skipped_hold <= rows_scanned),
  CONSTRAINT ck_retention_task_hold CHECK (rows_skipped_hold = 0 OR cardinality(hold_ids) >= 1),
  CONSTRAINT ck_retention_task_finished CHECK (status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_retention_task_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$')
);
CREATE UNIQUE INDEX uq_retention_task_run ON ph09_privacy.retention_task (tenant_id, schedule_id, COALESCE(line_id, '00000000-0000-0000-0000-000000000000'::uuid), run_date) WHERE NOT dry_run;
CREATE INDEX ix_retention_task_status ON ph09_privacy.retention_task (tenant_id, status, run_date DESC);
CREATE TRIGGER tg_retention_task_touch BEFORE UPDATE ON ph09_privacy.retention_task FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_task');
COMMENT ON TABLE ph09_privacy.retention_task IS 'EN-09-37 Tác vụ xóa hoặc giả danh hóa khi hết hạn (FR-09-041, 044, NFR-09-018): phạm vi, số bản ghi quét, xử lý, bỏ qua do giữ pháp lý (kèm hold_ids), kết quả. Chạy lại không nhân bản (khóa schedule_id, line_id, run_date).';
--rollback DROP TABLE IF EXISTS ph09_privacy.retention_task CASCADE;

--changeset ph09:ph09-0490-legal-hold
CREATE TABLE ph09_privacy.legal_hold (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  scope          jsonb NOT NULL,
  basis_doc      varchar(255) NOT NULL,
  basis_date     date NOT NULL,
  authority      varchar(255) NOT NULL,
  review_on      date NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'ACTIVE',
  placed_by      varchar(64) NOT NULL,
  released_by    varchar(64),
  released_at    timestamptz,
  release_reason varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_hold PRIMARY KEY (id),
  CONSTRAINT uq_legal_hold_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_hold_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legal_hold_scope CHECK (jsonb_typeof(scope) = 'object'),
  CONSTRAINT ck_legal_hold_status CHECK (status IN ('ACTIVE', 'RELEASED')),
  CONSTRAINT ck_legal_hold_review CHECK (review_on >= basis_date),
  CONSTRAINT ck_legal_hold_released CHECK ((status = 'RELEASED') = (released_by IS NOT NULL AND released_at IS NOT NULL AND release_reason IS NOT NULL))
);
CREATE INDEX ix_legal_hold_active ON ph09_privacy.legal_hold (tenant_id, review_on) WHERE status = 'ACTIVE';
CREATE INDEX ix_legal_hold_scope ON ph09_privacy.legal_hold USING gin (scope jsonb_path_ops) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_legal_hold_touch BEFORE UPDATE ON ph09_privacy.legal_hold FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_hold_immutable BEFORE UPDATE ON ph09_privacy.legal_hold FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('scope', 'basis_doc', 'basis_date', 'authority', 'placed_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_hold');
COMMENT ON TABLE ph09_privacy.legal_hold IS 'EN-09-38 Giữ pháp lý, tạm hoãn xóa (FR-09-042, BR-09-039): phạm vi (băm chủ thể, bảng, khoảng thời gian), số văn bản, cơ quan, ngày rà soát, LegalHoldStatus. Chặn mọi tác vụ xóa liên quan (ERR-09-058). Gỡ do người có quyền, có kiểm toán.';
COMMENT ON COLUMN ph09_privacy.legal_hold.scope IS '{subjectHashes[], entities[], from, to}; chỉ băm chủ thể, không định danh rõ.';
--rollback DROP TABLE IF EXISTS ph09_privacy.legal_hold CASCADE;

--changeset ph09:ph09-0500-tenant-shred-request
CREATE TABLE ph09_privacy.tenant_shred_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'REQUESTED',
  export_confirmed boolean NOT NULL DEFAULT false,
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  approver_1       varchar(64),
  approver_2       varchar(64),
  approved_at      timestamptz,
  wait_until       timestamptz,
  executed_at      timestamptz,
  kek_destroy_ref  varchar(255),
  cancelled_by     varchar(64),
  cancelled_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_shred_request PRIMARY KEY (id),
  CONSTRAINT ck_tenant_shred_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_shred_request_status CHECK (status IN ('REQUESTED', 'APPROVED', 'WAITING', 'EXECUTED', 'CANCELLED')),
  CONSTRAINT ck_tenant_shred_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_tenant_shred_request_approvers CHECK (approver_1 IS NULL OR (approver_1 <> requested_by AND (approver_2 IS NULL OR (approver_2 <> approver_1 AND approver_2 <> requested_by)))),
  CONSTRAINT ck_tenant_shred_request_approved CHECK (status NOT IN ('APPROVED', 'WAITING', 'EXECUTED') OR (export_confirmed AND approver_1 IS NOT NULL AND approver_2 IS NOT NULL AND approved_at IS NOT NULL AND wait_until >= approved_at + interval '7 days')),
  CONSTRAINT ck_tenant_shred_request_executed CHECK (status <> 'EXECUTED' OR (executed_at IS NOT NULL AND executed_at >= wait_until AND kek_destroy_ref IS NOT NULL)),
  CONSTRAINT ck_tenant_shred_request_cancelled CHECK ((status = 'CANCELLED') = (cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_tenant_shred_request_open ON ph09_privacy.tenant_shred_request (tenant_id) WHERE status IN ('REQUESTED', 'APPROVED', 'WAITING');
CREATE TRIGGER tg_tenant_shred_request_touch BEFORE UPDATE ON ph09_privacy.tenant_shred_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_tenant_shred_request_immutable BEFORE UPDATE ON ph09_privacy.tenant_shred_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('requested_by', 'reason');
CALL ph09_privacy.p_enable_rls('ph09_privacy.tenant_shred_request');
COMMENT ON TABLE ph09_privacy.tenant_shred_request IS 'EN-09-39 Đề nghị xóa mật mã tenant, hủy KEK dh-{tenant}-pii (FR-09-043, BR-09-041, 033): chỉ sau bàn giao dữ liệu theo PH-20, hai người duyệt khác nhau và khác người đề nghị, chờ ≥ 7 ngày, không hoàn tác. Một đề nghị đang mở mỗi tenant.';
--rollback DROP TABLE IF EXISTS ph09_privacy.tenant_shred_request CASCADE;
