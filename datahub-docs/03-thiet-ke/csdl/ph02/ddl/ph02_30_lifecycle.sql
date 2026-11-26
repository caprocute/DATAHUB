-- =============================================================================
-- D03-03-PH02 · Tệp 30: vòng đời, duyệt bốn mắt, đăng ký sử dụng, cấp quyền
-- Chạy sau ph02_20_lint_backend_plan.sql (cùng phiên, đang SET ROLE ph02_owner).
-- =============================================================================

-- @file 02-0030-lifecycle.sql
-- @changeset ph02-0300-subscription
CREATE TABLE ph02_catalog.subscription (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  plan_id          uuid          NOT NULL,
  api_version_id   uuid          NOT NULL,
  system_code      varchar(64)   NOT NULL,
  requester_org_code varchar(64) NOT NULL,
  purpose          varchar(1000) NOT NULL,
  expected_volume  varchar(500)  NOT NULL,
  data_class       varchar(10)   NOT NULL,
  personal_data    boolean       NOT NULL DEFAULT false,
  legal_basis      varchar(1000),
  status           varchar(10)   NOT NULL DEFAULT 'PENDING',
  reason_code      varchar(40),
  status_reason    varchar(1000),
  grant_status     varchar(20)   NOT NULL DEFAULT 'NONE',
  scopes           varchar(200)[] NOT NULL DEFAULT '{}',
  scope_operations varchar(128)[] NOT NULL DEFAULT '{}',
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  decided_by       varchar(64),
  decided_at       timestamptz,
  granted_at       timestamptz,
  expires_at       timestamptz,
  next_review_at   timestamptz,
  legacy_id        varchar(128),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_subscription PRIMARY KEY (id),
  CONSTRAINT uq_subscription_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id, api_version_id, tenant_id) REFERENCES ph02_catalog.plan (id, api_version_id, tenant_id),
  CONSTRAINT ck_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_subscription_data_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_subscription_status CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'REJECTED', 'CANCELLED', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_subscription_grant CHECK (grant_status IN ('NONE', 'AWAITING_CREDENTIAL', 'GRANTING', 'GRANTED', 'FAILED', 'DETACH_PENDING')),
  CONSTRAINT ck_subscription_grant_pending CHECK (status NOT IN ('PENDING', 'REJECTED') OR grant_status = 'NONE'),
  CONSTRAINT ck_subscription_purpose CHECK (length(btrim(purpose)) > 0 AND length(btrim(expected_volume)) > 0),
  CONSTRAINT ck_subscription_legal_basis CHECK ((data_class IN ('PUBLIC', 'INTERNAL') AND NOT personal_data) OR length(btrim(coalesce(legal_basis, ''))) > 0),
  CONSTRAINT ck_subscription_scopes CHECK (cardinality(scopes) <= 50),
  CONSTRAINT ck_subscription_scope_ops CHECK (cardinality(scope_operations) <= 50),
  CONSTRAINT ck_subscription_decided CHECK (status NOT IN ('ACTIVE', 'REJECTED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_subscription_four_eyes CHECK (decided_by IS NULL OR decided_by LIKE 'system:%' OR decided_by <> requested_by),
  CONSTRAINT ck_subscription_reject_reason CHECK (status <> 'REJECTED' OR length(btrim(coalesce(status_reason, ''))) > 0)
);
CREATE UNIQUE INDEX uq_subscription_one_effective ON ph02_catalog.subscription (tenant_id, system_code, api_version_id)
  WHERE status IN ('PENDING', 'ACTIVE', 'SUSPENDED');
CREATE UNIQUE INDEX uq_subscription_legacy_id ON ph02_catalog.subscription (tenant_id, legacy_id) WHERE legacy_id IS NOT NULL;
CREATE INDEX ix_subscription_plan ON ph02_catalog.subscription (tenant_id, plan_id, status);
CREATE INDEX ix_subscription_system ON ph02_catalog.subscription (tenant_id, system_code, status);
CREATE INDEX ix_subscription_version ON ph02_catalog.subscription (tenant_id, api_version_id, status);
CREATE INDEX ix_subscription_expiry ON ph02_catalog.subscription (expires_at) WHERE status = 'ACTIVE' AND expires_at IS NOT NULL;
CREATE INDEX ix_subscription_review ON ph02_catalog.subscription (next_review_at) WHERE status = 'ACTIVE' AND next_review_at IS NOT NULL;
CREATE INDEX ix_subscription_awaiting ON ph02_catalog.subscription (tenant_id, system_code) WHERE grant_status = 'AWAITING_CREDENTIAL';
CREATE TRIGGER tg_subscription_touch BEFORE UPDATE ON ph02_catalog.subscription FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.subscription', 'P');
COMMENT ON TABLE ph02_catalog.subscription IS 'EN-02-07 Đăng ký sử dụng của HTTT cho một gói (FR-02-046…052). Mỗi HTTT chỉ một đăng ký hiệu lực (PENDING, ACTIVE, SUSPENDED) cho một phiên bản (uq_subscription_one_effective, BR-02-027). Khóa ngoại ba cột (plan_id, api_version_id, tenant_id) bảo đảm đăng ký khớp phiên bản của gói. Phạm vi truy cập sinh tự động, không có đường cấp tay (BR-02-025).';
COMMENT ON COLUMN ph02_catalog.subscription.system_code IS 'Mã HTTT khai thác ở PH-01 (bản sao); kiểm ACTIVE, thuộc tổ chức người gửi, thuộc nhóm của gói ở dịch vụ (ERR-02-026, 028).';
COMMENT ON COLUMN ph02_catalog.subscription.data_class IS 'Bản chụp mức phân loại của API lúc gửi đăng ký, để quy tắc duyệt và căn cứ pháp lý không đổi theo thay đổi sau.';
COMMENT ON COLUMN ph02_catalog.subscription.legal_basis IS 'Căn cứ pháp lý khi dữ liệu cá nhân hoặc từ mức Hạn chế (BR-02-012, CMP-LAW-05); CHECK ck_subscription_legal_basis.';
COMMENT ON COLUMN ph02_catalog.subscription.reason_code IS 'Mã lý do máy đọc được của trạng thái hiện tại, ví dụ MIGRATED_AWAITING_CREDENTIAL (BR-02-036), SYSTEM_SUSPENDED, SYSTEM_REVOKED, EXPIRED_REVIEW.';
COMMENT ON COLUMN ph02_catalog.subscription.grant_status IS 'Tiến độ cấp quyền thật (saga ở grant_job): AWAITING_CREDENTIAL là chờ định danh máy ở PH-01, không phải lỗi; DETACH_PENDING là đã thu hồi nhưng PH-12 chưa gỡ phạm vi.';
COMMENT ON COLUMN ph02_catalog.subscription.scopes IS 'Phạm vi api:{apiCode}:{planCode} và api:{apiCode}:{planCode}:{operationId}; tối đa 50 (Q02-24).';
COMMENT ON COLUMN ph02_catalog.subscription.decided_by IS 'Người duyệt hoặc system:auto-approve khi tự duyệt (BR-02-026); phải khác requested_by (bốn mắt, ck_subscription_four_eyes).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.subscription CASCADE;

-- @changeset ph02-0310-subscription-state-history
CREATE TABLE ph02_catalog.subscription_state_history (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  subscription_id  uuid          NOT NULL,
  from_status      varchar(10),
  to_status        varchar(10)   NOT NULL,
  command          varchar(24)   NOT NULL,
  reason_code      varchar(40),
  reason           varchar(1000) NOT NULL,
  trace_id         char(32),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_subscription_state_history PRIMARY KEY (id),
  CONSTRAINT fk_subscription_state_history_sub FOREIGN KEY (subscription_id, tenant_id) REFERENCES ph02_catalog.subscription (id, tenant_id),
  CONSTRAINT ck_subscription_state_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_subscription_state_history_reason CHECK (length(btrim(reason)) > 0),
  CONSTRAINT ck_subscription_state_history_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_subscription_state_history_sub ON ph02_catalog.subscription_state_history (tenant_id, subscription_id, created_at);
CREATE TRIGGER tg_subscription_state_history_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.subscription_state_history FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.subscription_state_history', 'P');
COMMENT ON TABLE ph02_catalog.subscription_state_history IS 'Lịch sử chuyển trạng thái đăng ký: trước, sau, người, lý do bắt buộc (BR-02-028). Chỉ thêm, giữ vĩnh viễn làm bằng chứng ai đã dùng API nào (FRS §4.5, NFR-02-017). Hiển thị ở tab Lịch sử.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.subscription_state_history CASCADE;

-- @changeset ph02-0320-version-state-history
CREATE TABLE ph02_catalog.version_state_history (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  from_status      varchar(10),
  to_status        varchar(10)   NOT NULL,
  command          varchar(24)   NOT NULL,
  reason_code      varchar(40),
  reason           varchar(1000) NOT NULL,
  trace_id         char(32),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_version_state_history PRIMARY KEY (id),
  CONSTRAINT fk_version_state_history_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_version_state_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_version_state_history_reason CHECK (length(btrim(reason)) > 0),
  CONSTRAINT ck_version_state_history_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_version_state_history_version ON ph02_catalog.version_state_history (tenant_id, api_version_id, created_at);
CREATE TRIGGER tg_version_state_history_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.version_state_history FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.version_state_history', 'P');
COMMENT ON TABLE ph02_catalog.version_state_history IS 'Lịch sử chuyển trạng thái phiên bản API: trước, sau, người, lý do bắt buộc (BR-02-028). Chỉ thêm, giữ vĩnh viễn (NFR-02-017). SLA đọc bảng này để trừ các khoảng SUSPENDED do quyết định quản lý (SDD 4.12).';
COMMENT ON COLUMN ph02_catalog.version_state_history.command IS 'register, submit, withdraw, reject, approve, publish, suspend, resume, deprecate, retire, supersede, discard.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.version_state_history CASCADE;

-- @changeset ph02-0330-grant-job
CREATE TABLE ph02_catalog.grant_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  subscription_id  uuid          NOT NULL,
  kind             varchar(6)    NOT NULL DEFAULT 'ATTACH',
  generation       integer       NOT NULL DEFAULT 1,
  step             varchar(16)   NOT NULL DEFAULT 'CREDENTIAL_CHECK',
  status           varchar(20)   NOT NULL DEFAULT 'NEW',
  attempts         smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  last_error_code  varchar(16),
  cleanup_mark     boolean       NOT NULL DEFAULT false,
  finished_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_grant_job PRIMARY KEY (id),
  CONSTRAINT uq_grant_job_generation UNIQUE (subscription_id, kind, generation),
  CONSTRAINT fk_grant_job_sub FOREIGN KEY (subscription_id, tenant_id) REFERENCES ph02_catalog.subscription (id, tenant_id),
  CONSTRAINT ck_grant_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_grant_job_kind CHECK (kind IN ('ATTACH', 'DETACH')),
  CONSTRAINT ck_grant_job_step CHECK (step IN ('CREDENTIAL_CHECK', 'SCOPE_ATTACH', 'GATEWAY_APPLY', 'GRANTED', 'SCOPE_DETACH')),
  CONSTRAINT ck_grant_job_status CHECK (status IN ('NEW', 'RUNNING', 'AWAITING_CREDENTIAL', 'GRANTED', 'FAILED_RETRY', 'FAILED', 'DETACHING', 'CANCELLED')),
  CONSTRAINT ck_grant_job_attempts CHECK (attempts BETWEEN 0 AND 5),
  CONSTRAINT ck_grant_job_finished CHECK ((status IN ('GRANTED', 'FAILED', 'CANCELLED')) = (finished_at IS NOT NULL))
);
CREATE INDEX ix_grant_job_due ON ph02_catalog.grant_job (next_attempt_at) WHERE status IN ('NEW', 'FAILED_RETRY', 'DETACHING');
CREATE INDEX ix_grant_job_awaiting ON ph02_catalog.grant_job (tenant_id, subscription_id) WHERE status = 'AWAITING_CREDENTIAL';
CREATE INDEX ix_grant_job_cleanup ON ph02_catalog.grant_job (tenant_id) WHERE cleanup_mark AND status = 'FAILED';
CREATE TRIGGER tg_grant_job_touch BEFORE UPDATE ON ph02_catalog.grant_job FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.grant_job', 'P');
COMMENT ON TABLE ph02_catalog.grant_job IS 'Saga bền cấp phạm vi và thu hồi (SDD 4.9): CREDENTIAL_CHECK → SCOPE_ATTACH (PH-12) → GATEWAY_APPLY (PH-03) → GRANTED. Mỗi bước lũy đẳng theo khóa grant:{subscriptionId}:{generation}:{bước}; thử lại lùi dần tối đa 5 lần trong 15 phút (attempts ≤ 5). Worker lấy việc bằng FOR UPDATE SKIP LOCKED.';
COMMENT ON COLUMN ph02_catalog.grant_job.cleanup_mark IS 'Phần đã gắn thành công của saga thất bại, không tự gỡ; GrantJanitor dọn khi TO chọn Cấp lại hoặc Hủy cấp.';
COMMENT ON COLUMN ph02_catalog.grant_job.generation IS 'Số lần cấp lại; mỗi lần "Cấp lại" tạo dòng mới thay vì sửa dòng đã FAILED.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.grant_job CASCADE;

-- @changeset ph02-0340-review-request
CREATE TABLE ph02_catalog.review_request (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(14)   NOT NULL,
  subject_kind     varchar(12)   NOT NULL,
  subject_id       uuid          NOT NULL,
  api_version_id   uuid,
  status           varchar(9)    NOT NULL DEFAULT 'OPEN',
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  required_approvals smallint    NOT NULL DEFAULT 1,
  spec_sha256      char(64),
  payload          jsonb         NOT NULL DEFAULT '{}',
  comment          varchar(1000),
  due_at           timestamptz,
  overdue_notified_at timestamptz,
  decided_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_review_request PRIMARY KEY (id),
  CONSTRAINT uq_review_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_review_request_requester UNIQUE (id, requested_by, tenant_id),
  CONSTRAINT fk_review_request_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_review_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_review_request_kind CHECK (kind IN ('PUBLISH', 'DEPRECATE', 'RETIRE', 'PLAN_PUBLISH', 'PLAN_DEPRECATE', 'VISIBILITY', 'SUBSCRIBE')),
  CONSTRAINT ck_review_request_subject CHECK (
    (kind IN ('PUBLISH', 'DEPRECATE', 'RETIRE') AND subject_kind = 'API_VERSION')
    OR (kind IN ('PLAN_PUBLISH', 'PLAN_DEPRECATE') AND subject_kind = 'PLAN')
    OR (kind = 'SUBSCRIBE' AND subject_kind = 'SUBSCRIPTION')
    OR (kind = 'VISIBILITY' AND subject_kind = 'API')),
  CONSTRAINT ck_review_request_version CHECK (kind = 'VISIBILITY' OR api_version_id IS NOT NULL),
  CONSTRAINT ck_review_request_status CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT ck_review_request_approvals CHECK (required_approvals IN (1, 2)),
  CONSTRAINT ck_review_request_decided CHECK ((status = 'OPEN') = (decided_at IS NULL)),
  CONSTRAINT ck_review_request_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_review_request_spec CHECK (spec_sha256 IS NULL OR spec_sha256 ~ '^[0-9a-f]{64}$')
);
CREATE UNIQUE INDEX uq_review_request_one_open ON ph02_catalog.review_request (tenant_id, subject_kind, subject_id) WHERE status = 'OPEN';
CREATE INDEX ix_review_request_inbox ON ph02_catalog.review_request (tenant_id, kind, requested_at) WHERE status = 'OPEN';
CREATE INDEX ix_review_request_overdue ON ph02_catalog.review_request (due_at) WHERE status = 'OPEN' AND overdue_notified_at IS NULL;
CREATE INDEX ix_review_request_version ON ph02_catalog.review_request (tenant_id, api_version_id);
CREATE TRIGGER tg_review_request_touch BEFORE UPDATE ON ph02_catalog.review_request FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.review_request', 'P');
COMMENT ON TABLE ph02_catalog.review_request IS 'EN-02-09 Yêu cầu duyệt: công bố, ngừng khuyến nghị, ngừng hẳn, công bố và ngừng gói, nâng mức hiển thị, đăng ký sử dụng (FR-02-030, 034, 035, 038, 039, 041, 047). Một yêu cầu OPEN mỗi đối tượng (uq_review_request_one_open). Chuyển sang APPROVED chỉ khi đủ chữ ký (tg_review_request_approve_gate): API SENSITIVE cần hai người CA và TA khác nhau (BR-02-008).';
COMMENT ON COLUMN ph02_catalog.review_request.required_approvals IS '1, hoặc 2 với API SENSITIVE (xác nhận của CA và TA là hai người khác nhau).';
COMMENT ON COLUMN ph02_catalog.review_request.spec_sha256 IS 'Băm đặc tả lúc gửi duyệt; lệch lúc duyệt thì đưa về DRAFT (ERR-02-015).';
COMMENT ON COLUMN ph02_catalog.review_request.payload IS 'Tham số của yêu cầu: sunsetAt, successorVersionId, urgentReason (DEPRECATE); visibility đích (VISIBILITY).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.review_request CASCADE;

-- @changeset ph02-0350-version-contributor
CREATE TABLE ph02_catalog.version_contributor (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  contributor_role varchar(12)   NOT NULL,
  user_id          varchar(64)   NOT NULL,
  acted_at         timestamptz   NOT NULL DEFAULT now(),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_version_contributor PRIMARY KEY (id),
  CONSTRAINT uq_version_contributor UNIQUE (api_version_id, contributor_role),
  CONSTRAINT fk_version_contributor_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_version_contributor_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_version_contributor_role CHECK (contributor_role IN ('CREATOR', 'SPEC_EDITOR', 'PLAN_EDITOR', 'SUBMITTER'))
);
CREATE TRIGGER tg_version_contributor_touch BEFORE UPDATE ON ph02_catalog.version_contributor FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.version_contributor', 'P');
COMMENT ON TABLE ph02_catalog.version_contributor IS 'Người tạo, người sửa gần nhất đặc tả, người sửa gần nhất gói và người gửi duyệt của phiên bản, để ReviewPolicy so theo định danh người dùng, không theo vai trò (BR-02-008, ADR-046). Mỗi vai trò một dòng được ghi đè khi có người sửa mới.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.version_contributor CASCADE;

-- @changeset ph02-0360-review-decision
CREATE TABLE ph02_catalog.review_decision (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  review_request_id uuid         NOT NULL,
  requested_by     varchar(64)   NOT NULL,
  decision         varchar(7)    NOT NULL,
  decided_by       varchar(64)   NOT NULL,
  decider_role     varchar(2)    NOT NULL,
  comment          varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_review_decision PRIMARY KEY (id),
  CONSTRAINT uq_review_decision_person UNIQUE (review_request_id, decided_by),
  CONSTRAINT fk_review_decision_request FOREIGN KEY (review_request_id, requested_by, tenant_id) REFERENCES ph02_catalog.review_request (id, requested_by, tenant_id),
  CONSTRAINT ck_review_decision_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_review_decision_value CHECK (decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_review_decision_role CHECK (decider_role IN ('CA', 'TA', 'SV')),
  CONSTRAINT ck_review_decision_four_eyes CHECK (decided_by <> requested_by),
  CONSTRAINT ck_review_decision_reject_comment CHECK (decision <> 'REJECT' OR length(btrim(coalesce(comment, ''))) > 0)
);
CREATE INDEX ix_review_decision_request ON ph02_catalog.review_decision (tenant_id, review_request_id);
CREATE TRIGGER tg_review_decision_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.review_decision FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.review_decision', 'P');
COMMENT ON TABLE ph02_catalog.review_decision IS 'Quyết định của từng người trên yêu cầu duyệt, mỗi người một quyết định (uq_review_decision_person). Bốn mắt chốt ở CSDL: người duyệt khác người gửi (khóa ngoại ba cột kèm ck_review_decision_four_eyes), khác người sửa đặc tả hoặc gói gần nhất, SV không duyệt công bố hay vòng đời (trigger tg_review_decision_independent, BR-02-008). Chỉ thêm.';
COMMENT ON COLUMN ph02_catalog.review_decision.requested_by IS 'Sao từ review_request.requested_by qua khóa ngoại ba cột; làm cho CHECK so sánh người duyệt với người gửi thực hiện được trong một bảng.';
COMMENT ON COLUMN ph02_catalog.review_decision.decider_role IS 'Vai trò người duyệt lúc quyết định: CA người duyệt dịch vụ, TA quản trị tenant, SV chủ dịch vụ (chỉ được duyệt đăng ký dưới mức Hạn chế).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.review_decision CASCADE;

-- @changeset ph02-0361-review-decision-independent splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_review_decision_independent() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  rq ph02_catalog.review_request%ROWTYPE;
BEGIN
  SELECT * INTO rq FROM ph02_catalog.review_request WHERE id = NEW.review_request_id AND tenant_id = NEW.tenant_id;
  IF NOT FOUND THEN
    RETURN NEW;  -- khóa ngoại báo lỗi
  END IF;
  IF rq.status <> 'OPEN' THEN
    RAISE EXCEPTION 'Yêu cầu duyệt % không còn OPEN', rq.id USING ERRCODE = '55000';
  END IF;
  IF rq.kind <> 'SUBSCRIBE' AND NEW.decider_role = 'SV' THEN
    RAISE EXCEPTION 'SV không giữ vai trò duyệt công bố hoặc vòng đời (BR-02-008, ERR-02-013)' USING ERRCODE = '23514';
  END IF;
  IF rq.kind IN ('PUBLISH', 'DEPRECATE', 'RETIRE', 'PLAN_PUBLISH', 'PLAN_DEPRECATE') AND EXISTS (
       SELECT 1 FROM ph02_catalog.version_contributor c
        WHERE c.api_version_id = rq.api_version_id AND c.tenant_id = NEW.tenant_id
          AND c.contributor_role IN ('SPEC_EDITOR', 'PLAN_EDITOR', 'SUBMITTER')
          AND c.user_id = NEW.decided_by) THEN
    RAISE EXCEPTION 'Người duyệt không được là người gửi hoặc người sửa gần nhất đặc tả, gói (BR-02-008, ERR-02-013)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_review_decision_independent BEFORE INSERT ON ph02_catalog.review_decision FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_review_decision_independent();
-- @rollback DROP TRIGGER IF EXISTS tg_review_decision_independent ON ph02_catalog.review_decision; DROP FUNCTION IF EXISTS ph02_catalog.tg_review_decision_independent();

-- @changeset ph02-0362-review-request-approve-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_review_request_approve_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  n_approve integer;
  has_ca boolean;
  has_ta boolean;
BEGIN
  IF NEW.status = 'APPROVED' AND OLD.status IS DISTINCT FROM 'APPROVED' THEN
    SELECT count(DISTINCT decided_by), bool_or(decider_role = 'CA'), bool_or(decider_role = 'TA')
      INTO n_approve, has_ca, has_ta
      FROM ph02_catalog.review_decision
     WHERE review_request_id = NEW.id AND tenant_id = NEW.tenant_id AND decision = 'APPROVE';
    IF coalesce(n_approve, 0) < NEW.required_approvals THEN
      RAISE EXCEPTION 'Yêu cầu duyệt % chưa đủ % quyết định APPROVE (BR-02-008)', NEW.id, NEW.required_approvals USING ERRCODE = '23514';
    END IF;
    IF NEW.required_approvals = 2 AND NOT (coalesce(has_ca, false) AND coalesce(has_ta, false)) THEN
      RAISE EXCEPTION 'API SENSITIVE cần cả CA và TA là hai người khác nhau (BR-02-008)' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF OLD.status <> 'OPEN' AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'Yêu cầu duyệt đã kết thúc không đổi trạng thái được' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_review_request_approve_gate BEFORE UPDATE OF status ON ph02_catalog.review_request FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_review_request_approve_gate();
-- @rollback DROP TRIGGER IF EXISTS tg_review_request_approve_gate ON ph02_catalog.review_request; DROP FUNCTION IF EXISTS ph02_catalog.tg_review_request_approve_gate();

-- @changeset ph02-0370-deprecation-reminder
CREATE TABLE ph02_catalog.deprecation_reminder (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  days_before      smallint      NOT NULL,
  due_at           timestamptz   NOT NULL,
  status           varchar(9)    NOT NULL DEFAULT 'SCHEDULED',
  sent_at          timestamptz,
  notice_id        uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_deprecation_reminder PRIMARY KEY (id),
  CONSTRAINT uq_deprecation_reminder UNIQUE (api_version_id, days_before),
  CONSTRAINT fk_deprecation_reminder_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_deprecation_reminder_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_deprecation_reminder_days CHECK (days_before BETWEEN 1 AND 720),
  CONSTRAINT ck_deprecation_reminder_status CHECK (status IN ('SCHEDULED', 'SENT', 'SKIPPED')),
  CONSTRAINT ck_deprecation_reminder_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL))
);
CREATE INDEX ix_deprecation_reminder_due ON ph02_catalog.deprecation_reminder (due_at) WHERE status = 'SCHEDULED';
CREATE TRIGGER tg_deprecation_reminder_touch BEFORE UPDATE ON ph02_catalog.deprecation_reminder FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.deprecation_reminder', 'P');
COMMENT ON TABLE ph02_catalog.deprecation_reminder IS 'Mốc nhắc trước hạn ngừng hẳn theo 02.deprecation.reminders (mặc định 90, 30, 7 ngày; BR-02-004, FR-02-038, 057). Tạo khi phiên bản sang DEPRECATED; mốc đã qua lúc tạo ghi SKIPPED.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.deprecation_reminder CASCADE;
