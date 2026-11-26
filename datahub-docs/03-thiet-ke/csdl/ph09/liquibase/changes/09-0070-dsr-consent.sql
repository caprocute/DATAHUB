--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0070-dsr-consent.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0510-subject-request
CREATE TABLE ph09_privacy.subject_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  request_type          varchar(20) NOT NULL,
  status                varchar(12) NOT NULL DEFAULT 'RECEIVED',
  channel               varchar(16) NOT NULL,
  identifier_type       varchar(24) NOT NULL,
  subject_hash          bytea NOT NULL,
  identifier_enc        bytea NOT NULL,
  identifier_kid        varchar(64) NOT NULL,
  content_enc           bytea NOT NULL,
  content_kid           varchar(64) NOT NULL,
  idempotency_key       varchar(64) NOT NULL,
  received_at           timestamptz NOT NULL DEFAULT now(),
  due_at                timestamptz NOT NULL,
  overdue               boolean NOT NULL DEFAULT false,
  verified_at           timestamptz,
  assigned_to           varchar(64),
  outcome               varchar(10),
  refusal_basis         varchar(500),
  response_ref          varchar(512),
  responded_at          timestamptz,
  closed_at             timestamptz,
  reject_reason         varchar(2000),
  restriction_active    boolean NOT NULL DEFAULT false,
  restriction_lifted_at timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_request PRIMARY KEY (id),
  CONSTRAINT uq_subject_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_subject_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_subject_request_idem UNIQUE (tenant_id, idempotency_key),
  CONSTRAINT ck_subject_request_type CHECK (request_type IN ('ACCESS', 'RECTIFY', 'ERASE', 'RESTRICT', 'OBJECT', 'WITHDRAW_CONSENT', 'INFO')),
  CONSTRAINT ck_subject_request_status CHECK (status IN ('RECEIVED', 'VERIFYING', 'IN_PROGRESS', 'RESPONDED', 'CLOSED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT ck_subject_request_channel CHECK (channel IN ('PUBLIC_SERVICE', 'COUNTER', 'DOCUMENT', 'EMAIL')),
  CONSTRAINT ck_subject_request_idtype CHECK (identifier_type IN ('NATIONAL_ID', 'TAX_ID', 'SOCIAL_INSURANCE_ID', 'PHONE', 'EMAIL')),
  CONSTRAINT ck_subject_request_hash CHECK (octet_length(subject_hash) = 32),
  CONSTRAINT ck_subject_request_enc CHECK (octet_length(identifier_enc) >= 29 AND octet_length(content_enc) >= 29),
  CONSTRAINT ck_subject_request_due CHECK (due_at >= received_at),
  CONSTRAINT ck_subject_request_verified CHECK (status NOT IN ('IN_PROGRESS', 'RESPONDED', 'CLOSED') OR verified_at IS NOT NULL),
  CONSTRAINT ck_subject_request_outcome CHECK (outcome IS NULL OR outcome IN ('FULFILLED', 'PARTIAL', 'REFUSED')),
  CONSTRAINT ck_subject_request_responded CHECK (status NOT IN ('RESPONDED', 'CLOSED') OR (outcome IS NOT NULL AND responded_at IS NOT NULL)),
  CONSTRAINT ck_subject_request_refused CHECK (outcome IS DISTINCT FROM 'REFUSED' OR refusal_basis IS NOT NULL),
  CONSTRAINT ck_subject_request_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL)),
  CONSTRAINT ck_subject_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_subject_request_restriction CHECK (NOT restriction_active OR request_type = 'RESTRICT')
);
CREATE INDEX ix_subject_request_inbox ON ph09_privacy.subject_request (tenant_id, status, due_at);
CREATE INDEX ix_subject_request_subject ON ph09_privacy.subject_request (tenant_id, subject_hash);
CREATE INDEX ix_subject_request_restricted ON ph09_privacy.subject_request (tenant_id, subject_hash) WHERE restriction_active;
CREATE TRIGGER tg_subject_request_touch BEFORE UPDATE ON ph09_privacy.subject_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_subject_request_immutable BEFORE UPDATE ON ph09_privacy.subject_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_type', 'subject_hash', 'received_at', 'idempotency_key', 'identifier_enc');
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_request');
COMMENT ON TABLE ph09_privacy.subject_request IS 'EN-09-40 Yêu cầu của chủ thể dữ liệu (FR-09-045…050, BR-09-042…048, 061): loại DsrType, băm chủ thể HMAC theo khóa tenant, định danh và nội dung mã hóa envelope. Chưa xác minh thì không IN_PROGRESS (BR-09-042). Cờ overdue, cờ hạn chế xử lý; lưu 5 năm (BR-09-048); Idempotency-Key duy nhất.';
COMMENT ON COLUMN ph09_privacy.subject_request.subject_hash IS 'HMAC-SHA256 số định danh đã chuẩn hóa, khóa theo tenant (BR-09-045); tra bản ghi của chủ thể ở PH-06, PH-19, PH-13, PH-14.';
COMMENT ON COLUMN ph09_privacy.subject_request.identifier_enc IS 'Định danh rõ chỉ ở đây, mã hóa envelope (ADR-032).';
COMMENT ON COLUMN ph09_privacy.subject_request.content_enc IS 'Nội dung yêu cầu ≤ 4.000 ký tự, mã hóa envelope.';
COMMENT ON COLUMN ph09_privacy.subject_request.overdue IS 'Cờ, không phải trạng thái (FRS 4.5).';
COMMENT ON COLUMN ph09_privacy.subject_request.due_at IS 'Ngày làm việc theo 09.dsr.sla-days (Q09-02).';
--rollback DROP TABLE IF EXISTS ph09_privacy.subject_request CASCADE;

--changeset ph09:ph09-0520-subject-verification
CREATE TABLE ph09_privacy.subject_verification (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  request_id    uuid NOT NULL,
  method        varchar(20) NOT NULL,
  passed        boolean NOT NULL,
  evidence_hash bytea,
  evidence_ref  varchar(512),
  verified_by   varchar(64) NOT NULL,
  verified_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_verification PRIMARY KEY (id),
  CONSTRAINT ck_subject_verification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_subject_verification_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.subject_request (tenant_id, id),
  CONSTRAINT ck_subject_verification_method CHECK (method IN ('ID_DOCUMENT', 'OTP', 'VNEID', 'COUNTER_IN_PERSON')),
  CONSTRAINT ck_subject_verification_hash CHECK (evidence_hash IS NULL OR octet_length(evidence_hash) = 32),
  CONSTRAINT ck_subject_verification_evidence CHECK (NOT passed OR evidence_hash IS NOT NULL OR method IN ('VNEID', 'OTP'))
);
CREATE INDEX ix_subject_verification_request ON ph09_privacy.subject_verification (tenant_id, request_id, verified_at DESC);
CREATE TRIGGER tg_subject_verification_touch BEFORE UPDATE ON ph09_privacy.subject_verification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_subject_verification_immutable BEFORE UPDATE ON ph09_privacy.subject_verification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_id', 'method', 'passed');
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_verification');
COMMENT ON TABLE ph09_privacy.subject_verification IS 'EN-09-41 Kết quả xác minh danh tính chủ thể (FR-09-046, BR-09-042): phương pháp VerificationMethod, đạt hoặc không, bằng chứng chỉ lưu băm và tham chiếu Garage mã hóa. Người xác minh khác người nhận yêu cầu (kiểm ở dịch vụ).';
--rollback DROP TABLE IF EXISTS ph09_privacy.subject_verification CASCADE;

--changeset ph09:ph09-0530-subject-task
CREATE TABLE ph09_privacy.subject_task (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  request_id     uuid NOT NULL,
  target         varchar(16) NOT NULL,
  action         varchar(20) NOT NULL,
  status         varchar(10) NOT NULL DEFAULT 'OPEN',
  assignee       varchar(64),
  external_ref   varchar(255),
  result         jsonb,
  refusal_reason varchar(2000),
  done_at        timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_task PRIMARY KEY (id),
  CONSTRAINT ck_subject_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_subject_task_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.subject_request (tenant_id, id),
  CONSTRAINT ck_subject_task_target CHECK (target IN ('PH06_MASTER', 'PH19_PAYMENT', 'CONTROLLER', 'MANUAL')),
  CONSTRAINT ck_subject_task_action CHECK (action IN ('ACCESS', 'RECTIFY', 'ERASE', 'RESTRICT', 'OBJECT', 'WITHDRAW_CONSENT', 'INFO')),
  CONSTRAINT ck_subject_task_status CHECK (status IN ('OPEN', 'DONE', 'REFUSED', 'CANCELLED')),
  CONSTRAINT ck_subject_task_refused CHECK (status <> 'REFUSED' OR refusal_reason IS NOT NULL),
  CONSTRAINT ck_subject_task_done CHECK (status = 'OPEN' OR done_at IS NOT NULL)
);
CREATE INDEX ix_subject_task_request ON ph09_privacy.subject_task (tenant_id, request_id, status);
CREATE INDEX ix_subject_task_open ON ph09_privacy.subject_task (tenant_id, target, created_at) WHERE status = 'OPEN';
CREATE TRIGGER tg_subject_task_touch BEFORE UPDATE ON ph09_privacy.subject_task FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_task');
COMMENT ON TABLE ph09_privacy.subject_task IS 'EN-09-42 Tác vụ chuyển cho PH-06, PH-19, PH-13, PH-14 hoặc bên kiểm soát (FR-09-047, 048, BR-09-044, 046): đích DsrTarget, hành động theo DsrType, DsrTaskStatus. Kết quả chỉ số lượng và tham chiếu, không giá trị. Dữ liệu đi qua chuyển cho bên kiểm soát.';
--rollback DROP TABLE IF EXISTS ph09_privacy.subject_task CASCADE;

--changeset ph09:ph09-0540-consent-template
CREATE TABLE ph09_privacy.consent_template (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  template_code    varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  purpose_code     varchar(41) NOT NULL,
  data_scope       varchar(2000) NOT NULL,
  body_text        varchar(20000) NOT NULL,
  valid_days       integer,
  withdrawal_guide varchar(2000) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_consent_template PRIMARY KEY (id),
  CONSTRAINT uq_consent_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_consent_template_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_consent_template_code CHECK (template_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_consent_template_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_consent_template_valid CHECK (valid_days IS NULL OR valid_days BETWEEN 1 AND 3650),
  CONSTRAINT ck_consent_template_body CHECK (char_length(body_text) >= 20),
  CONSTRAINT uq_consent_template_version UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_consent_template_version CHECK (version_no >= 1),
  CONSTRAINT ck_consent_template_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_consent_template_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_consent_template_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_consent_template_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_consent_template_active ON ph09_privacy.consent_template (tenant_id, template_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_consent_template_touch BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_consent_template_immutable BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('template_code', 'version_no');
CREATE TRIGGER tg_consent_template_frozen BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('purpose_code', 'data_scope', 'body_text', 'valid_days', 'withdrawal_guide');
CALL ph09_privacy.p_enable_rls('ph09_privacy.consent_template');
COMMENT ON TABLE ph09_privacy.consent_template IS 'EN-09-43 Mẫu sự đồng ý theo phiên bản (FR-09-052, BR-09-049): nội dung, mục đích, dữ liệu xử lý, hạn hiệu lực, cách rút. Nội dung bất biến khi ACTIVE. Đồng ý chỉ là cơ sở cho tiện ích không bắt buộc, không là điều kiện của thủ tục hành chính.';
--rollback DROP TABLE IF EXISTS ph09_privacy.consent_template CASCADE;

--changeset ph09:ph09-0550-consent-record
CREATE TABLE ph09_privacy.consent_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  template_id       uuid NOT NULL,
  template_code     varchar(41) NOT NULL,
  template_version  integer NOT NULL,
  subject_hash      bytea NOT NULL,
  status            varchar(10) NOT NULL DEFAULT 'GIVEN',
  channel           varchar(10) NOT NULL,
  text_hash         bytea NOT NULL,
  given_at          timestamptz NOT NULL DEFAULT now(),
  evidence          jsonb NOT NULL DEFAULT '{}',
  recorded_by       varchar(64) NOT NULL,
  expires_at        timestamptz,
  withdrawn_at      timestamptz,
  withdrawn_channel varchar(10),
  withdrawn_by      varchar(64),
  withdraw_evidence jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_consent_record PRIMARY KEY (id),
  CONSTRAINT uq_consent_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_consent_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_consent_record_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph09_privacy.consent_template (tenant_id, id),
  CONSTRAINT ck_consent_record_status CHECK (status IN ('GIVEN', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_consent_record_channel CHECK (channel IN ('WEB', 'APP', 'COUNTER', 'DOCUMENT') AND (withdrawn_channel IS NULL OR withdrawn_channel IN ('WEB', 'APP', 'COUNTER', 'DOCUMENT'))),
  CONSTRAINT ck_consent_record_hash CHECK (octet_length(subject_hash) = 32 AND octet_length(text_hash) = 32),
  CONSTRAINT ck_consent_record_withdrawn CHECK ((status = 'WITHDRAWN') = (withdrawn_at IS NOT NULL AND withdrawn_channel IS NOT NULL AND withdrawn_by IS NOT NULL) AND (withdrawn_at IS NULL OR withdrawn_at >= given_at)),
  CONSTRAINT ck_consent_record_expired CHECK (status <> 'EXPIRED' OR (expires_at IS NOT NULL AND expires_at <= now() + interval '1 minute'))
);
CREATE UNIQUE INDEX uq_consent_record_given ON ph09_privacy.consent_record (tenant_id, template_code, subject_hash) WHERE status = 'GIVEN';
CREATE INDEX ix_consent_record_subject ON ph09_privacy.consent_record (tenant_id, subject_hash, given_at DESC);
CREATE TRIGGER tg_consent_record_touch BEFORE UPDATE ON ph09_privacy.consent_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_consent_record_immutable BEFORE UPDATE ON ph09_privacy.consent_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('template_id', 'template_code', 'template_version', 'subject_hash', 'text_hash', 'given_at', 'channel', 'recorded_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.consent_record');
COMMENT ON TABLE ph09_privacy.consent_record IS 'EN-09-44 Bản ghi đồng ý hoặc rút (FR-09-053, 054, BR-09-050, 051): băm chủ thể, mẫu và phiên bản, băm nội dung đã hiển thị, kênh, thời điểm, bằng chứng; rút ghi trên cùng dòng (withdrawn_*) và có hiệu lực trong 60 giây. Một đồng ý GIVEN mỗi (chủ thể, mẫu). Không xóa.';
COMMENT ON COLUMN ph09_privacy.consent_record.text_hash IS 'Băm nội dung mẫu đã hiển thị cho chủ thể (bằng chứng, BR-09-050).';
--rollback DROP TABLE IF EXISTS ph09_privacy.consent_record CASCADE;
