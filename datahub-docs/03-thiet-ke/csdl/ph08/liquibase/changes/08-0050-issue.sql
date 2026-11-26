--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0050-issue.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0290-dq-issue
CREATE TABLE ph08_dq.dq_issue (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  issue_code              varchar(24) NOT NULL,
  asset_id                uuid NOT NULL,
  rule_id                 uuid,
  group_key               varchar(160) NOT NULL,
  title                   varchar(255) NOT NULL,
  description             varchar(4000),
  severity                varchar(8) NOT NULL,
  finding_count           integer NOT NULL DEFAULT 0,
  owner_org_code          varchar(63) NOT NULL,
  assignee                varchar(64),
  status                  varchar(12) NOT NULL DEFAULT 'OPEN',
  sla_days                smallint NOT NULL,
  sla_due_at              timestamptz NOT NULL,
  escalation_level        smallint NOT NULL DEFAULT 0,
  escalated_at            timestamptz,
  assigned_at             timestamptz,
  fixed_at                timestamptz,
  fix_note                varchar(2000),
  verified_at             timestamptz,
  verify_scan_job_id      uuid,
  reopen_count            smallint NOT NULL DEFAULT 0,
  reject_reason           varchar(2000),
  steward_item_ref        uuid,
  forwarded_to_steward_at timestamptz,
  cancel_reason           varchar(2000),
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_issue PRIMARY KEY (id),
  CONSTRAINT uq_dq_issue_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_issue_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_issue_code UNIQUE (tenant_id, issue_code),
  CONSTRAINT fk_dq_issue_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_issue_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT fk_dq_issue_verify FOREIGN KEY (tenant_id, verify_scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_issue_code CHECK (issue_code ~ '^DQ-[0-9]{4}-[0-9]{6}$'),
  CONSTRAINT ck_dq_issue_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_issue_status CHECK (status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_dq_issue_sla CHECK (sla_days BETWEEN 1 AND 365),
  CONSTRAINT ck_dq_issue_assigned CHECK (status NOT IN ('ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED') OR assigned_at IS NOT NULL),
  CONSTRAINT ck_dq_issue_fixed CHECK (status NOT IN ('FIXED', 'VERIFIED') OR fixed_at IS NOT NULL),
  CONSTRAINT ck_dq_issue_verified CHECK ((status = 'VERIFIED') = (verified_at IS NOT NULL AND verify_scan_job_id IS NOT NULL)),
  CONSTRAINT ck_dq_issue_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(reject_reason) >= 20, false)),
  CONSTRAINT ck_dq_issue_cancel CHECK (status <> 'CANCELLED' OR COALESCE(char_length(cancel_reason) >= 20, false)),
  CONSTRAINT ck_dq_issue_count CHECK (finding_count >= 0 AND reopen_count >= 0 AND escalation_level BETWEEN 0 AND 3)
);
CREATE UNIQUE INDEX uq_dq_issue_open_group ON ph08_dq.dq_issue (tenant_id, group_key) WHERE status NOT IN ('VERIFIED', 'REJECTED', 'CANCELLED');
CREATE INDEX ix_dq_issue_inbox ON ph08_dq.dq_issue (tenant_id, owner_org_code, status, sla_due_at);
CREATE INDEX ix_dq_issue_assignee ON ph08_dq.dq_issue (tenant_id, assignee, status) WHERE assignee IS NOT NULL;
CREATE INDEX ix_dq_issue_sla ON ph08_dq.dq_issue (sla_due_at) WHERE status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'REOPENED');
CREATE INDEX ix_dq_issue_asset ON ph08_dq.dq_issue (tenant_id, asset_id, status);
CREATE TRIGGER tg_dq_issue_touch BEFORE UPDATE ON ph08_dq.dq_issue FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_issue_immutable BEFORE UPDATE ON ph08_dq.dq_issue FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'issue_code', 'asset_id', 'rule_id', 'group_key', 'severity', 'owner_org_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_issue');
COMMENT ON TABLE ph08_dq.dq_issue IS 'EN-08-19 Phiếu khắc phục: nhóm lỗi của một đối tượng và quy tắc giao cho tổ chức chủ quản, hạn xử lý theo mức nghiêm trọng (CRITICAL 5 ngày làm việc, MAJOR 15, MINOR 30, giả định), vòng đời OPEN đến VERIFIED (FR-08-041…046). PH-08 không sửa dữ liệu nguồn; lỗi bản ghi vàng chuyển sang hàng đợi steward PH-06.';
COMMENT ON COLUMN ph08_dq.dq_issue.group_key IS 'asset_code | rule_code | owner_org_code; mỗi nhóm một phiếu đang mở (chỉ mục duy nhất một phần).';
COMMENT ON COLUMN ph08_dq.dq_issue.steward_item_ref IS 'Mã mục hàng đợi steward PH-06 khi lỗi ở bản ghi vàng (FR-08-046); kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph08_dq.dq_issue.verify_scan_job_id IS 'Lần đo lại kiểm chứng (trigger VERIFY); phiếu VERIFIED bắt buộc có (FR-08-044).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_issue CASCADE;

--changeset ph08:ph08-0300-dq-issue-activity
CREATE TABLE ph08_dq.dq_issue_activity (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  issue_id      uuid NOT NULL,
  activity_type varchar(24) NOT NULL,
  actor         varchar(64) NOT NULL,
  from_status   varchar(12),
  to_status     varchar(12),
  comment       varchar(4000),
  payload       jsonb NOT NULL DEFAULT '{}',
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_issue_activity PRIMARY KEY (id),
  CONSTRAINT ck_dq_issue_activity_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_issue_activity_issue FOREIGN KEY (tenant_id, issue_id) REFERENCES ph08_dq.dq_issue (tenant_id, id),
  CONSTRAINT ck_dq_issue_activity_type CHECK (activity_type IN ('CREATED', 'ASSIGNED', 'COMMENTED', 'STATUS_CHANGED', 'ESCALATED', 'TRANSFERRED', 'FORWARDED_STEWARD', 'REJECTED', 'VERIFIED', 'REOPENED', 'CANCELLED')),
  CONSTRAINT ck_dq_issue_activity_status CHECK ((from_status IS NULL OR from_status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED')) AND (to_status IS NULL OR to_status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED'))),
  CONSTRAINT ck_dq_issue_activity_change CHECK (activity_type <> 'STATUS_CHANGED' OR (from_status IS NOT NULL AND to_status IS NOT NULL AND from_status <> to_status))
);
CREATE INDEX ix_dq_issue_activity_issue ON ph08_dq.dq_issue_activity (tenant_id, issue_id, occurred_at);
CREATE TRIGGER tg_dq_issue_activity_touch BEFORE UPDATE ON ph08_dq.dq_issue_activity FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_issue_activity_append_only BEFORE UPDATE OR DELETE ON ph08_dq.dq_issue_activity FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_append_only();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_issue_activity');
COMMENT ON TABLE ph08_dq.dq_issue_activity IS 'EN-08-20 Hoạt động trên phiếu khắc phục: tạo, phân công, bình luận, đổi trạng thái, leo thang, chuyển steward, xác nhận (FR-08-043, 045). Chỉ thêm, không sửa, không xóa.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_issue_activity CASCADE;
