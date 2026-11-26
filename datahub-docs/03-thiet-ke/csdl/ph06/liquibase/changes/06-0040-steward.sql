--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0040-steward.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0290-steward-item
CREATE TABLE ph06_mdm.steward_item (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  reason            varchar(24) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'OPEN',
  risk_level        varchar(4) NOT NULL DEFAULT 'LOW',
  priority          smallint NOT NULL DEFAULT 50,
  left_candidate_id uuid,
  left_golden_id    uuid,
  right_golden_id   uuid,
  match_result_id   uuid,
  score             numeric(5,4),
  attribute_scores  jsonb NOT NULL DEFAULT '{}',
  source_codes      varchar(32)[] NOT NULL DEFAULT '{}',
  assignee          varchar(64),
  claimed_at        timestamptz,
  hold_until        timestamptz,
  due_at            timestamptz NOT NULL,
  escalated_at      timestamptz,
  defer_until       timestamptz,
  decision          varchar(8),
  decision_reason   varchar(2000),
  decided_by        varchar(64),
  decided_at        timestamptz,
  survivor_id       uuid,
  approval_decision varchar(8),
  approved_by       varchar(64),
  approved_at       timestamptz,
  approval_comment  varchar(2000),
  operation_id      uuid,
  cancel_reason     varchar(500),
  reopen_count      smallint NOT NULL DEFAULT 0,
  reopened_at       timestamptz,
  reopened_by       varchar(64),
  reopen_reason     varchar(2000),
  decision_history  jsonb NOT NULL DEFAULT '[]',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_steward_item PRIMARY KEY (id),
  CONSTRAINT uq_steward_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_steward_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_steward_item_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_steward_item_reason CHECK (reason IN ('POSSIBLE_MATCH', 'MULTIPLE_CANDIDATES', 'INSUFFICIENT_ATTRIBUTES', 'CRITICAL_CONFLICT', 'IDENTIFIER_CONFLICT', 'ORPHANED', 'TIMEOUT')),
  CONSTRAINT ck_steward_item_status CHECK (status IN ('OPEN', 'ASSIGNED', 'DEFERRED', 'PENDING_APPROVAL', 'RESOLVED', 'CANCELLED')),
  CONSTRAINT ck_steward_item_risk CHECK (risk_level IN ('LOW', 'HIGH')),
  CONSTRAINT ck_steward_item_decision CHECK (decision IS NULL OR decision IN ('MATCH', 'NO_MATCH', 'DEFER')),
  CONSTRAINT ck_steward_item_approval CHECK (approval_decision IS NULL OR approval_decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_steward_item_priority CHECK (priority BETWEEN 1 AND 100),
  CONSTRAINT ck_steward_item_left CHECK ((left_candidate_id IS NULL) <> (left_golden_id IS NULL) OR status = 'CANCELLED'),
  CONSTRAINT ck_steward_item_reason20 CHECK (decision_reason IS NULL OR char_length(decision_reason) >= 20),
  CONSTRAINT ck_steward_item_four_eyes CHECK (approved_by IS NULL OR decided_by IS NULL OR approved_by <> decided_by),
  CONSTRAINT ck_steward_item_pending CHECK (status <> 'PENDING_APPROVAL' OR (decision = 'MATCH' AND risk_level = 'HIGH' AND decided_by IS NOT NULL)),
  CONSTRAINT ck_steward_item_resolved CHECK (status <> 'RESOLVED' OR (decision IN ('MATCH', 'NO_MATCH') AND decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_steward_item_assigned CHECK (status NOT IN ('ASSIGNED', 'PENDING_APPROVAL') OR assignee IS NOT NULL),
  CONSTRAINT ck_steward_item_defer CHECK ((status = 'DEFERRED') = (defer_until IS NOT NULL))
);
CREATE UNIQUE INDEX uq_steward_item_open_pair ON ph06_mdm.steward_item (tenant_id, domain_code, COALESCE(left_candidate_id, left_golden_id), right_golden_id) WHERE status NOT IN ('RESOLVED', 'CANCELLED') AND right_golden_id IS NOT NULL;
CREATE INDEX ix_steward_item_queue ON ph06_mdm.steward_item (tenant_id, domain_code, status, priority DESC, due_at);
CREATE INDEX ix_steward_item_assignee ON ph06_mdm.steward_item (tenant_id, assignee, status) WHERE assignee IS NOT NULL;
CREATE INDEX ix_steward_item_nomatch ON ph06_mdm.steward_item (tenant_id, domain_code, left_golden_id, right_golden_id) WHERE decision = 'NO_MATCH' AND status = 'RESOLVED';
CREATE TRIGGER tg_steward_item_touch BEFORE UPDATE ON ph06_mdm.steward_item FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_steward_item_immutable BEFORE UPDATE ON ph06_mdm.steward_item FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'left_candidate_id', 'left_golden_id', 'right_golden_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.steward_item');
COMMENT ON TABLE ph06_mdm.steward_item IS 'EN-06-05 Mục hàng đợi người quản lý dữ liệu (FR-06-027…032). Máy trạng thái 4.4. Quyết định cần lý do ≥ 20 ký tự (BR-06-008); MATCH rủi ro cao chờ DA duyệt khác người quyết định (BR-06-019, ERR-06-005). Mỗi cặp một mục mở.';
COMMENT ON COLUMN ph06_mdm.steward_item.hold_until IS 'Hết hạn giữ 30 phút (06.queue.hold-minutes) thì trả OPEN.';
COMMENT ON COLUMN ph06_mdm.steward_item.left_golden_id IS 'Cặp NO_MATCH đã RESOLVED là liên kết âm (BR-06-023): không đề xuất lại; chỉ mục ix_steward_item_nomatch.';
--rollback DROP TABLE IF EXISTS ph06_mdm.steward_item CASCADE;
