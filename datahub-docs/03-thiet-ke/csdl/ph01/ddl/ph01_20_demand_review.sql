-- =============================================================================
-- D03-03-PH01 · Tệp 20: nhu cầu khai thác, trần phạm vi, bước thẩm định.
-- Chạy sau ph01_10_member.sql.
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0020-demand-review.sql
-- @changeset ph01-0200-data-demand
CREATE TABLE ph01_onboarding.data_demand (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  member_system_id    uuid          NOT NULL,
  origin              varchar(10)   NOT NULL DEFAULT 'ONBOARDING',
  change_request_id   uuid,
  direction           varchar(7)    NOT NULL,
  data_type           varchar(64)   NOT NULL,
  scope_requested     varchar(200)  NOT NULL,
  classification      varchar(10)   NOT NULL,
  purpose             varchar(500)  NOT NULL,
  legal_doc_no        varchar(120),
  legal_issued_on     date,
  legal_issuer        varchar(255),
  legal_valid_until   date,
  legal_attachment_id uuid,
  verdict             varchar(8),
  scope_approved      varchar(200),
  opinion             varchar(2000),
  reviewer_id         varchar(64),
  reviewed_at         timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_demand PRIMARY KEY (id),
  CONSTRAINT uq_data_demand_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_data_demand_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_data_demand_change FOREIGN KEY (change_request_id, tenant_id) REFERENCES ph01_onboarding.change_request (id, tenant_id),
  CONSTRAINT fk_data_demand_attachment FOREIGN KEY (legal_attachment_id, tenant_id) REFERENCES ph01_onboarding.attachment (id, tenant_id),
  CONSTRAINT ck_data_demand_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_data_demand_origin CHECK (origin IN ('ONBOARDING', 'EXPANSION') AND ((origin = 'EXPANSION') = (change_request_id IS NOT NULL))),
  CONSTRAINT ck_data_demand_direction CHECK (direction IN ('CONSUME', 'PROVIDE')),
  CONSTRAINT ck_data_demand_type CHECK (data_type ~ '^[A-Z][A-Z0-9_]{1,63}$'),
  CONSTRAINT ck_data_demand_class CHECK (classification IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_data_demand_legal_issued CHECK (legal_issued_on IS NULL OR legal_issued_on <= CURRENT_DATE),
  CONSTRAINT ck_data_demand_legal_valid CHECK (legal_valid_until IS NULL OR legal_issued_on IS NULL OR legal_valid_until >= legal_issued_on),
  CONSTRAINT ck_data_demand_verdict CHECK (verdict IS NULL OR verdict IN ('APPROVED', 'NARROWED', 'REJECTED')),
  CONSTRAINT ck_data_demand_verdict_who CHECK ((verdict IS NULL) = (reviewer_id IS NULL AND reviewed_at IS NULL)),
  CONSTRAINT ck_data_demand_scope CHECK ((verdict IN ('APPROVED', 'NARROWED')) = (scope_approved IS NOT NULL)),
  CONSTRAINT ck_data_demand_opinion CHECK (verdict IS NULL OR verdict = 'APPROVED' OR coalesce(char_length(opinion), 0) >= 1)
);
CREATE UNIQUE INDEX uq_data_demand_type ON ph01_onboarding.data_demand (tenant_id, member_system_id, direction, data_type, coalesce(change_request_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX ix_data_demand_system ON ph01_onboarding.data_demand (tenant_id, member_system_id);
CREATE INDEX ix_data_demand_pending ON ph01_onboarding.data_demand (tenant_id, member_system_id) WHERE verdict IS NULL;
CREATE INDEX ix_data_demand_attachment ON ph01_onboarding.data_demand (legal_attachment_id) WHERE legal_attachment_id IS NOT NULL;
CREATE TRIGGER tg_data_demand_touch BEFORE UPDATE ON ph01_onboarding.data_demand FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CREATE TRIGGER tg_data_demand_draft_delete BEFORE DELETE ON ph01_onboarding.data_demand FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_draft_only_delete('member_system_id');
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.data_demand', 'P');
COMMENT ON TABLE ph01_onboarding.data_demand IS 'EN-01-03 Nhu cầu khai thác: mỗi dòng một loại dữ liệu và chiều CONSUME hoặc PROVIDE kèm căn cứ pháp lý và kết luận thẩm định riêng; quyền theo dòng, không theo hồ sơ (FR-01-007, FR-01-014, FR-01-035; BR-01-001, 003, 004).';
COMMENT ON COLUMN ph01_onboarding.data_demand.origin IS 'ONBOARDING (khi kết nạp) hoặc EXPANSION (đề nghị mở rộng trần sau kết nạp, kèm change_request_id loại FULL).';
COMMENT ON COLUMN ph01_onboarding.data_demand.data_type IS 'Mã loại dữ liệu trong danh mục của tenant (PH-07, Q01-16); dữ liệu thuộc danh mục bí mật nhà nước bị chặn ở dịch vụ trước khi ghi (BR-01-004), mức phân loại không có giá trị bí mật nhà nước.';
COMMENT ON COLUMN ph01_onboarding.data_demand.legal_doc_no IS 'Số, ký hiệu văn bản căn cứ; bắt buộc đủ bốn thông tin căn cứ cho dòng CONSUME khi nộp (BR-01-001, kiểm ở fn_assert_submittable).';
COMMENT ON COLUMN ph01_onboarding.data_demand.legal_valid_until IS 'Hiệu lực căn cứ đến ngày; NULL là không thời hạn; LegalValidityChecker dùng (FR-01-043, BR-01-015).';
COMMENT ON COLUMN ph01_onboarding.data_demand.legal_attachment_id IS 'Tài liệu loại LEGAL_BASIS cùng hồ sơ (khóa ngoại kèm tenant).';
COMMENT ON COLUMN ph01_onboarding.data_demand.verdict IS 'Kết luận mục: APPROVED, NARROWED (kèm scope_approved), REJECTED (kèm ý kiến); NARROWED phải là tập con của scope_requested, kiểm ở dịch vụ (ERR-01-018, 019, Q01-50).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.data_demand CASCADE;

-- @changeset ph01-0210-scope-ceiling splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_scope_ceiling_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE d ph01_onboarding.data_demand%ROWTYPE;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.source_demand_id IS NOT NULL THEN
      SELECT * INTO d FROM ph01_onboarding.data_demand WHERE id = NEW.source_demand_id;
      IF NOT FOUND OR d.verdict NOT IN ('APPROVED', 'NARROWED') OR d.member_system_id <> NEW.member_system_id
         OR d.direction <> NEW.direction OR d.data_type <> NEW.data_type
         OR d.scope_approved IS DISTINCT FROM NEW.scope_approved THEN
        RAISE EXCEPTION 'Trần phạm vi phải bằng đúng nhu cầu được chấp thuận hoặc thu hẹp (BR-01-003)' USING ERRCODE = '23514';
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.tenant_id <> OLD.tenant_id OR NEW.member_system_id <> OLD.member_system_id OR NEW.direction <> OLD.direction
     OR NEW.data_type <> OLD.data_type OR NEW.source_demand_id IS DISTINCT FROM OLD.source_demand_id THEN
    RAISE EXCEPTION 'Danh tính của trần phạm vi bất biến (BR-01-012)' USING ERRCODE = '23514';
  END IF;
  IF ph01_onboarding.fn_rank(NEW.classification) > ph01_onboarding.fn_rank(OLD.classification) THEN
    RAISE EXCEPTION 'Trần phạm vi không tự nâng mức phân loại; mở rộng qua thẩm định pháp lý lại (BR-01-012, ERR-01-037)' USING ERRCODE = '23514';
  END IF;
  IF OLD.status = 'REVOKED' THEN
    RAISE EXCEPTION 'Trần phạm vi đã thu hồi không sửa được' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_scope_ceiling_guard() IS 'Trần sinh đúng từ nhu cầu được duyệt; danh tính bất biến; không nâng mức phân loại; REVOKED là cuối (BR-01-003, BR-01-012).';

CREATE TABLE ph01_onboarding.scope_ceiling (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  member_system_id    uuid          NOT NULL,
  source_demand_id    uuid,
  direction           varchar(7)    NOT NULL,
  data_type           varchar(64)   NOT NULL,
  scope_approved      varchar(200)  NOT NULL,
  classification      varchar(10)   NOT NULL,
  legal_doc_no        varchar(120),
  legal_issued_on     date,
  legal_issuer        varchar(255),
  legal_valid_until   date,
  legal_attachment_id uuid,
  status              varchar(9)    NOT NULL DEFAULT 'ACTIVE',
  suspend_reason      varchar(16),
  revoked_at          timestamptz,
  revoked_reason      varchar(1000),
  in_use              boolean       NOT NULL DEFAULT false,
  last_used_at        timestamptz,
  usage_checked_at    timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_scope_ceiling PRIMARY KEY (id),
  CONSTRAINT uq_scope_ceiling_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_scope_ceiling_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_scope_ceiling_demand FOREIGN KEY (source_demand_id, tenant_id) REFERENCES ph01_onboarding.data_demand (id, tenant_id),
  CONSTRAINT fk_scope_ceiling_attachment FOREIGN KEY (legal_attachment_id, tenant_id) REFERENCES ph01_onboarding.attachment (id, tenant_id),
  CONSTRAINT ck_scope_ceiling_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_scope_ceiling_direction CHECK (direction IN ('CONSUME', 'PROVIDE')),
  CONSTRAINT ck_scope_ceiling_class CHECK (classification IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_scope_ceiling_legal CHECK (direction = 'PROVIDE' OR (legal_doc_no IS NOT NULL AND legal_issued_on IS NOT NULL AND legal_issuer IS NOT NULL)),
  CONSTRAINT ck_scope_ceiling_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_scope_ceiling_suspend CHECK ((status = 'SUSPENDED') = (suspend_reason IS NOT NULL)
                                         AND (suspend_reason IS NULL OR suspend_reason IN ('LEGAL_EXPIRED', 'ACCESS_REVIEW', 'MEMBER_SUSPENDED', 'MANUAL'))),
  CONSTRAINT ck_scope_ceiling_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_reason IS NOT NULL))
);
CREATE UNIQUE INDEX uq_scope_ceiling_open ON ph01_onboarding.scope_ceiling (tenant_id, member_system_id, direction, data_type) WHERE status <> 'REVOKED';
CREATE INDEX ix_scope_ceiling_system ON ph01_onboarding.scope_ceiling (tenant_id, member_system_id, status);
CREATE INDEX ix_scope_ceiling_legal ON ph01_onboarding.scope_ceiling (legal_valid_until) WHERE status = 'ACTIVE' AND legal_valid_until IS NOT NULL;
CREATE INDEX ix_scope_ceiling_unused ON ph01_onboarding.scope_ceiling (tenant_id, last_used_at NULLS FIRST) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_scope_ceiling_guard BEFORE INSERT OR UPDATE ON ph01_onboarding.scope_ceiling FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_scope_ceiling_guard();
CREATE TRIGGER tg_scope_ceiling_touch BEFORE UPDATE ON ph01_onboarding.scope_ceiling FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.scope_ceiling', 'P');
COMMENT ON TABLE ph01_onboarding.scope_ceiling IS 'EN-01-04 Trần phạm vi: giới hạn trên cho đăng ký sử dụng ở PH-02 và scope của định danh; sinh từ nhu cầu được duyệt, chỉ thu hẹp hoặc đóng (FR-01-018, 035, 042, 043; BR-01-003, 012, 015). Thay PHAM_VI_DUOC_CAP của hệ cũ.';
COMMENT ON COLUMN ph01_onboarding.scope_ceiling.scope_approved IS 'Phạm vi được duyệt (văn bản ≤ 200 ký tự); bằng scope_approved của nhu cầu nguồn khi tạo (tg_scope_ceiling_guard); thu hẹp là sửa cột này ở dịch vụ (Q01-50).';
COMMENT ON COLUMN ph01_onboarding.scope_ceiling.suspend_reason IS 'LEGAL_EXPIRED (căn cứ hết hiệu lực, BR-01-015), ACCESS_REVIEW, MEMBER_SUSPENDED, MANUAL; khác NULL khi và chỉ khi SUSPENDED.';
COMMENT ON COLUMN ph01_onboarding.scope_ceiling.in_use IS 'Có đăng ký sử dụng đang hoạt động ở PH-02; do tổng hợp mức dùng cập nhật (FR-01-040).';
COMMENT ON COLUMN ph01_onboarding.scope_ceiling.last_used_at IS 'Lần dùng gần nhất theo PH-13; căn cứ đề xuất thu hồi khi không dùng quá accessReview.unusedDays.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.scope_ceiling CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_scope_ceiling_guard();

-- @changeset ph01-0220-review-step splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_review_step_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  m record;
  v_ignore text[] := ARRAY['updated_at', 'updated_by', 'version'];
BEGIN
  SELECT created_by, submitted_by INTO m FROM ph01_onboarding.member_system WHERE id = NEW.member_system_id;
  IF NEW.assignee_id IS NOT NULL AND (NEW.assignee_id = m.created_by OR NEW.assignee_id IS NOT DISTINCT FROM m.submitted_by) THEN
    RAISE EXCEPTION 'Người lập hoặc nộp hồ sơ không được thẩm định hồ sơ đó (BR-01-017, ERR-01-017)' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF NEW.member_system_id <> OLD.member_system_id OR NEW.revision_no <> OLD.revision_no OR NEW.step_type <> OLD.step_type THEN
      RAISE EXCEPTION 'Bước thẩm định không đổi hồ sơ, vòng nộp, loại bước' USING ERRCODE = '23514';
    END IF;
    IF OLD.status NOT IN ('OPEN', 'CONSULTING') AND (to_jsonb(NEW) - v_ignore) IS DISTINCT FROM (to_jsonb(OLD) - v_ignore) THEN
      RAISE EXCEPTION 'Bước thẩm định đã kết thúc là bất biến, kết luận một lần mỗi vòng nộp (ERR-01-020)' USING ERRCODE = '55000';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_review_step_guard() IS 'Bốn mắt giữa người lập, người nộp và người thẩm định; bước đã kết thúc bất biến (BR-01-017, ERR-01-017, 020).';

CREATE TABLE ph01_onboarding.review_step (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  revision_no       integer       NOT NULL,
  step_type         varchar(9)    NOT NULL,
  status            varchar(9)    NOT NULL DEFAULT 'OPEN',
  assignee_id       varchar(64),
  assigned_by       varchar(64),
  assigned_at       timestamptz,
  result            varchar(4),
  opinion           varchar(4000),
  input_hash        char(64),
  carried_from_id   uuid,
  started_at        timestamptz   NOT NULL DEFAULT now(),
  due_at            timestamptz   NOT NULL,
  paused_millis     bigint        NOT NULL DEFAULT 0,
  paused_at         timestamptz,
  consulting_with   varchar(64),
  consult_question  varchar(2000),
  escalated_at      timestamptz,
  finished_at       timestamptz,
  finished_by       varchar(64),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_review_step PRIMARY KEY (id),
  CONSTRAINT uq_review_step_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_review_step_round UNIQUE (tenant_id, member_system_id, revision_no, step_type),
  CONSTRAINT fk_review_step_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_review_step_carried FOREIGN KEY (carried_from_id, tenant_id) REFERENCES ph01_onboarding.review_step (id, tenant_id),
  CONSTRAINT ck_review_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_review_step_revision CHECK (revision_no >= 1),
  CONSTRAINT ck_review_step_type CHECK (step_type IN ('TECHNICAL', 'LEGAL', 'SECURITY')),
  CONSTRAINT ck_review_step_status CHECK (status IN ('OPEN', 'CONSULTING', 'DONE', 'RETURNED', 'WITHDRAWN', 'CARRIED')),
  CONSTRAINT ck_review_step_result CHECK ((status IN ('DONE', 'CARRIED')) = (result IS NOT NULL) AND (result IS NULL OR result IN ('PASS', 'FAIL'))),
  CONSTRAINT ck_review_step_fail_opinion CHECK (result IS DISTINCT FROM 'FAIL' OR coalesce(char_length(opinion), 0) >= 1),
  CONSTRAINT ck_review_step_finished CHECK ((status IN ('OPEN', 'CONSULTING')) = (finished_at IS NULL)),
  CONSTRAINT ck_review_step_finisher CHECK (status NOT IN ('DONE', 'CARRIED') OR (finished_by IS NOT NULL AND finished_by = assignee_id)),
  CONSTRAINT ck_review_step_carried CHECK ((status = 'CARRIED') = (carried_from_id IS NOT NULL)),
  CONSTRAINT ck_review_step_assign CHECK ((assignee_id IS NULL) = (assigned_by IS NULL AND assigned_at IS NULL)),
  CONSTRAINT ck_review_step_paused CHECK (paused_millis >= 0 AND (status = 'CONSULTING') = (paused_at IS NOT NULL AND consulting_with IS NOT NULL)),
  CONSTRAINT ck_review_step_due CHECK (due_at > started_at),
  CONSTRAINT ck_review_step_hash CHECK (input_hash IS NULL OR input_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_review_step_assignee ON ph01_onboarding.review_step (tenant_id, assignee_id) WHERE status IN ('OPEN', 'CONSULTING');
CREATE INDEX ix_review_step_due ON ph01_onboarding.review_step (tenant_id, due_at) WHERE status = 'OPEN';
CREATE INDEX ix_review_step_system ON ph01_onboarding.review_step (tenant_id, member_system_id, revision_no);
CREATE TRIGGER tg_review_step_guard BEFORE INSERT OR UPDATE ON ph01_onboarding.review_step FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_review_step_guard();
CREATE TRIGGER tg_review_step_touch BEFORE UPDATE ON ph01_onboarding.review_step FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.review_step', 'P');
COMMENT ON TABLE ph01_onboarding.review_step IS 'EN-01-07 Bước thẩm định song song TECHNICAL, LEGAL, SECURITY mỗi vòng nộp; kết luận một lần, giữ vĩnh viễn (FR-01-013, 014, 016, 017; BR-01-017, 032).';
COMMENT ON COLUMN ph01_onboarding.review_step.revision_no IS 'Vòng nộp (member_system.revision_no lúc tạo bước); nộp lại tạo ba bước mới, bước có input_hash trùng được sao chép kết luận (CARRIED).';
COMMENT ON COLUMN ph01_onboarding.review_step.assignee_id IS 'Người được phân công (NULL là chờ phân công); khác người lập và người nộp hồ sơ (tg_review_step_guard).';
COMMENT ON COLUMN ph01_onboarding.review_step.input_hash IS 'SHA-256 của lát dữ liệu liên quan tới bước, để quyết định sao chép kết luận khi nộp lại (BR-01-032).';
COMMENT ON COLUMN ph01_onboarding.review_step.paused_millis IS 'Thời gian đồng hồ hạn bị dừng cộng dồn (tham vấn, chờ đơn vị bổ sung); dueAt được dời tương ứng.';
COMMENT ON COLUMN ph01_onboarding.review_step.status IS 'OPEN (chờ phân công hoặc đang làm), CONSULTING (tham vấn, đồng hồ dừng), DONE, RETURNED (trả bổ sung), WITHDRAWN (đơn vị rút hồ sơ), CARRIED (sao chép kết luận từ vòng trước).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.review_step CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_review_step_guard();
