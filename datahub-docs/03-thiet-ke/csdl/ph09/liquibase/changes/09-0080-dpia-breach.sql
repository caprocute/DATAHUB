--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0080-dpia-breach.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0560-dpia-record
CREATE TABLE ph09_privacy.dpia_record (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  dpia_code        varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  activity_id      uuid NOT NULL,
  dpia_kind        varchar(16) NOT NULL,
  description      varchar(4000) NOT NULL,
  risks            jsonb NOT NULL,
  measures         jsonb NOT NULL,
  review_on        date NOT NULL,
  submitted_a05_at timestamptz,
  a05_ref          varchar(128),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dpia_record PRIMARY KEY (id),
  CONSTRAINT uq_dpia_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dpia_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dpia_record_code CHECK (dpia_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_dpia_record_activity FOREIGN KEY (tenant_id, activity_id) REFERENCES ph09_privacy.processing_activity (tenant_id, id),
  CONSTRAINT ck_dpia_record_kind CHECK (dpia_kind IN ('PROCESSING', 'CROSS_BORDER')),
  CONSTRAINT ck_dpia_record_risks CHECK (jsonb_typeof(risks) = 'array' AND jsonb_array_length(risks) >= 1 AND jsonb_typeof(measures) = 'array' AND jsonb_array_length(measures) >= 1),
  CONSTRAINT ck_dpia_record_a05 CHECK ((status = 'SUBMITTED_A05') = (submitted_a05_at IS NOT NULL)),
  CONSTRAINT uq_dpia_record_version UNIQUE (tenant_id, dpia_code, version_no),
  CONSTRAINT ck_dpia_record_version CHECK (version_no >= 1),
  CONSTRAINT ck_dpia_record_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED', 'SUBMITTED_A05')),
  CONSTRAINT ck_dpia_record_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_dpia_record_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_dpia_record_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_dpia_record_active ON ph09_privacy.dpia_record (tenant_id, dpia_code) WHERE status = 'ACTIVE';
CREATE INDEX ix_dpia_record_review ON ph09_privacy.dpia_record (tenant_id, review_on) WHERE status IN ('ACTIVE', 'SUBMITTED_A05');
CREATE TRIGGER tg_dpia_record_touch BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_dpia_record_immutable BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('dpia_code', 'version_no', 'activity_id');
CREATE TRIGGER tg_dpia_record_frozen BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('dpia_kind', 'description', 'risks', 'measures', 'review_on');
CALL ph09_privacy.p_enable_rls('ph09_privacy.dpia_record');
COMMENT ON TABLE ph09_privacy.dpia_record IS 'EN-09-45 Hồ sơ đánh giá tác động xử lý DLCN theo phiên bản (FR-09-055…057, BR-09-052, 053): DpiaKind, hoạt động liên kết, rủi ro, biện pháp, hạn rà soát ≤ 12 tháng; trạng thái DpiaStatus gồm SUBMITTED_A05 khi đã gửi Cục A05. Nhắc trước 30 ngày.';
COMMENT ON COLUMN ph09_privacy.dpia_record.status IS 'VersionStatus cộng SUBMITTED_A05 (Phụ lục A, DpiaStatus).';
--rollback DROP TABLE IF EXISTS ph09_privacy.dpia_record CASCADE;

--changeset ph09:ph09-0570-breach-case
CREATE TABLE ph09_privacy.breach_case (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  detected_at            timestamptz NOT NULL,
  deadline_at            timestamptz NOT NULL,
  source                 varchar(16) NOT NULL,
  description            varchar(4000) NOT NULL,
  data_types             varchar(32)[] NOT NULL,
  estimated_subjects     integer,
  incident_ref           varchar(64),
  status                 varchar(12) NOT NULL DEFAULT 'REPORTED',
  severity               varchar(8),
  reported_by            varchar(64) NOT NULL,
  assessed_by            varchar(64),
  assessed_at            timestamptz,
  notified_a05_at        timestamptz,
  exempt_basis           varchar(2000),
  not_breach_reason      varchar(2000),
  not_breach_approved_by varchar(64),
  affected_ref           varchar(512),
  affected_count         integer,
  lessons                varchar(4000),
  closed_at              timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_case PRIMARY KEY (id),
  CONSTRAINT uq_breach_case_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_breach_case_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_breach_case_source CHECK (source IN ('PERSON', 'INCIDENT_PH18', 'AUDIT_PH13', 'ANOMALY')),
  CONSTRAINT ck_breach_case_status CHECK (status IN ('REPORTED', 'ASSESSING', 'NOT_A_BREACH', 'NOTIFYING', 'NOTIFIED', 'REMEDIATING', 'CLOSED')),
  CONSTRAINT ck_breach_case_severity CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_breach_case_types CHECK (cardinality(data_types) >= 1 AND data_types <@ ARRAY['FULL_NAME', 'DATE_OF_BIRTH', 'GENDER', 'NATIONAL_ID', 'PHONE', 'EMAIL', 'ADDRESS', 'TAX_ID', 'SOCIAL_INSURANCE_ID', 'HEALTH', 'BIOMETRIC', 'GENETIC', 'POLITICAL_RELIGIOUS', 'CRIMINAL_RECORD', 'FINANCIAL_ACCOUNT', 'LOCATION_TRACKING', 'MINOR', 'ETHNICITY']::varchar[]),
  CONSTRAINT ck_breach_case_clock CHECK (deadline_at = detected_at + interval '72 hours'),
  CONSTRAINT ck_breach_case_counts CHECK ((estimated_subjects IS NULL OR estimated_subjects >= 0) AND (affected_count IS NULL OR affected_count >= 0)),
  CONSTRAINT ck_breach_case_assessed CHECK (status IN ('REPORTED', 'ASSESSING') OR (assessed_by IS NOT NULL AND assessed_at IS NOT NULL)),
  CONSTRAINT ck_breach_case_notified CHECK (status NOT IN ('NOTIFIED', 'REMEDIATING', 'CLOSED') OR notified_a05_at IS NOT NULL OR exempt_basis IS NOT NULL),
  CONSTRAINT ck_breach_case_not_breach CHECK (status <> 'NOT_A_BREACH' OR (COALESCE(char_length(not_breach_reason) >= 20, false) AND not_breach_approved_by IS NOT NULL AND not_breach_approved_by <> assessed_by)),
  CONSTRAINT ck_breach_case_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL))
);
CREATE INDEX ix_breach_case_open ON ph09_privacy.breach_case (tenant_id, deadline_at) WHERE status NOT IN ('NOT_A_BREACH', 'CLOSED') AND notified_a05_at IS NULL;
CREATE INDEX ix_breach_case_detected ON ph09_privacy.breach_case (tenant_id, detected_at DESC);
CREATE TRIGGER tg_breach_case_touch BEFORE UPDATE ON ph09_privacy.breach_case FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_breach_case_immutable BEFORE UPDATE ON ph09_privacy.breach_case FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('detected_at', 'deadline_at', 'reported_by', 'source');
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_case');
COMMENT ON TABLE ph09_privacy.breach_case IS 'EN-09-46 Vụ việc vi phạm DLCN (FR-09-058…060, BR-09-054…056): BreachSource, BreachStatus, BreachSeverity, đồng hồ 72 giờ từ detected_at không dừng, hạn deadline_at cố định. Thông báo A05 hoặc căn cứ miễn trừ trước khi NOTIFIED trở đi; NOT_A_BREACH cần SO duyệt. Không chứa giá trị DLCN, chỉ số lượng, loại, băm.';
COMMENT ON COLUMN ph09_privacy.breach_case.affected_ref IS 'Danh sách băm chủ thể bị ảnh hưởng, tệp mã hóa ở Garage; không giữ định danh rõ (BR-09-056).';
--rollback DROP TABLE IF EXISTS ph09_privacy.breach_case CASCADE;

--changeset ph09:ph09-0580-breach-notification
CREATE TABLE ph09_privacy.breach_notification (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  case_id       uuid NOT NULL,
  recipient     varchar(12) NOT NULL,
  status        varchar(6) NOT NULL DEFAULT 'DRAFT',
  content       varchar(20000) NOT NULL,
  sent_at       timestamptz,
  sent_by       varchar(64),
  evidence_ref  varchar(512),
  evidence_hash bytea,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_notification PRIMARY KEY (id),
  CONSTRAINT ck_breach_notification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_breach_notification_case FOREIGN KEY (tenant_id, case_id) REFERENCES ph09_privacy.breach_case (tenant_id, id),
  CONSTRAINT ck_breach_notification_recipient CHECK (recipient IN ('A05', 'SUBJECT', 'CONTROLLER')),
  CONSTRAINT ck_breach_notification_status CHECK (status IN ('DRAFT', 'SENT')),
  CONSTRAINT ck_breach_notification_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL AND sent_by IS NOT NULL AND evidence_ref IS NOT NULL)),
  CONSTRAINT ck_breach_notification_hash CHECK (evidence_hash IS NULL OR octet_length(evidence_hash) = 32)
);
CREATE INDEX ix_breach_notification_case ON ph09_privacy.breach_notification (tenant_id, case_id, recipient);
CREATE TRIGGER tg_breach_notification_touch BEFORE UPDATE ON ph09_privacy.breach_notification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_notification');
COMMENT ON TABLE ph09_privacy.breach_notification IS 'EN-09-47 Thông báo vi phạm cho Cục A05, chủ thể hoặc bên kiểm soát (FR-09-059, BR-09-055): NotificationRecipient, nội dung không chứa DLCN, trạng thái NotificationStatus, bằng chứng gửi (băm và tham chiếu).';
--rollback DROP TABLE IF EXISTS ph09_privacy.breach_notification CASCADE;

--changeset ph09:ph09-0590-breach-action
CREATE TABLE ph09_privacy.breach_action (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  case_id     uuid NOT NULL,
  is_lesson   boolean NOT NULL DEFAULT false,
  description varchar(2000) NOT NULL,
  owner       varchar(64) NOT NULL,
  due_on      date,
  done_at     timestamptz,
  result      varchar(2000),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_action PRIMARY KEY (id),
  CONSTRAINT ck_breach_action_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_breach_action_case FOREIGN KEY (tenant_id, case_id) REFERENCES ph09_privacy.breach_case (tenant_id, id),
  CONSTRAINT ck_breach_action_lesson CHECK (NOT is_lesson OR (due_on IS NULL AND owner <> ''))
);
CREATE INDEX ix_breach_action_case ON ph09_privacy.breach_action (tenant_id, case_id);
CREATE TRIGGER tg_breach_action_touch BEFORE UPDATE ON ph09_privacy.breach_action FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_action');
COMMENT ON TABLE ph09_privacy.breach_action IS 'EN-09-48 Biện pháp khắc phục và bài học của vụ việc (FR-09-060): người phụ trách, hạn, kết quả; is_lesson phân biệt bài học với biện pháp. Hoàn thành ghi done_at.';
--rollback DROP TABLE IF EXISTS ph09_privacy.breach_action CASCADE;
