--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0080-govern.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0570-ai-system-record
CREATE TABLE ph17_assist.ai_system_record (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  record_code      varchar(32) NOT NULL,
  name             varchar(255) NOT NULL,
  purpose          text NOT NULL,
  model_summary    jsonb NOT NULL DEFAULT '[]',
  data_summary     jsonb NOT NULL DEFAULT '{}',
  risk_level       varchar(8) NOT NULL,
  risk_assessment  text NOT NULL,
  measures         text[] NOT NULL,
  responsible_user varchar(64) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'ACTIVE',
  last_review_at   timestamptz NOT NULL,
  next_review_due  date NOT NULL,
  legal_refs       varchar(16)[],
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ai_system_record PRIMARY KEY (id),
  CONSTRAINT ck_ai_system_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_ai_system_record_code UNIQUE (tenant_id, record_code),
  CONSTRAINT ck_ai_system_record_risk CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_ai_system_record_status CHECK (status IN ('ACTIVE', 'REVIEW_DUE', 'RETIRED')),
  CONSTRAINT ck_ai_system_record_review CHECK (next_review_due <= (last_review_at + interval '12 months')::date),
  CONSTRAINT ck_ai_system_record_measures CHECK (cardinality(measures) >= 1),
  CONSTRAINT ck_ai_system_record_code CHECK (record_code ~ '^AI-[A-Z0-9-]{2,28}$')
);
CREATE TRIGGER tg_ai_system_record_touch BEFORE UPDATE ON ph17_assist.ai_system_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_ai_system_record_immutable BEFORE UPDATE ON ph17_assist.ai_system_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('record_code');
CALL ph17_assist.p_enable_rls('ph17_assist.ai_system_record');
COMMENT ON TABLE ph17_assist.ai_system_record IS 'EN-17-35 Hồ sơ đăng ký hệ thống AI của tenant (FR-17-054; BR-17-072; Luật Công nghiệp công nghệ số 2025, chương trí tuệ nhân tạo, chưa đối chiếu Công báo): mục đích, mô hình, dữ liệu, rủi ro, biện pháp, người chịu trách nhiệm. Phần mô hình, dữ liệu tự cập nhật khi cấu hình đổi; rà soát mỗi 12 tháng và khi đổi mô hình.';
COMMENT ON COLUMN ph17_assist.ai_system_record.risk_level IS 'LOW, MEDIUM, HIGH (RiskLevel, Phụ lục A).';
COMMENT ON COLUMN ph17_assist.ai_system_record.next_review_due IS 'Không quá 12 tháng sau lần rà soát cuối (BR-17-072).';
--rollback DROP TABLE IF EXISTS ph17_assist.ai_system_record CASCADE;

--changeset ph17:ph17-0580-log-access-grant
CREATE TABLE ph17_assist.log_access_grant (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  grantee         varchar(64) NOT NULL,
  grantee_role    varchar(10) NOT NULL,
  reason          varchar(2000) NOT NULL,
  scope_kind      varchar(12) NOT NULL,
  conversation_id uuid,
  range_from      timestamptz,
  range_to        timestamptz,
  granted_at      timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz NOT NULL,
  state           varchar(8) NOT NULL DEFAULT 'ACTIVE',
  access_count    integer NOT NULL DEFAULT 0,
  revoked_at      timestamptz,
  revoked_by      varchar(64),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_log_access_grant PRIMARY KEY (id),
  CONSTRAINT uq_log_access_grant_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_log_access_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_log_access_grant_role CHECK (grantee_role IN ('SO', 'AUDITOR')),
  CONSTRAINT ck_log_access_grant_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_log_access_grant_scope CHECK (scope_kind IN ('CONVERSATION', 'RANGE')),
  CONSTRAINT ck_log_access_grant_scope_fields CHECK ((scope_kind = 'CONVERSATION' AND conversation_id IS NOT NULL AND range_from IS NULL AND range_to IS NULL) OR (scope_kind = 'RANGE' AND conversation_id IS NULL AND range_from IS NOT NULL AND range_to IS NOT NULL AND range_to > range_from AND range_to <= range_from + interval '92 days')),
  CONSTRAINT ck_log_access_grant_ttl CHECK (expires_at > granted_at AND expires_at <= granted_at + interval '60 minutes'),
  CONSTRAINT ck_log_access_grant_state CHECK (state IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_log_access_grant_count CHECK (access_count >= 0),
  CONSTRAINT ck_log_access_grant_revoked CHECK ((state = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_by IS NOT NULL))
);
CREATE INDEX ix_log_access_grant_grantee ON ph17_assist.log_access_grant (tenant_id, grantee, state, expires_at);
CREATE TRIGGER tg_log_access_grant_touch BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_log_access_grant_immutable BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('grantee', 'grantee_role', 'reason', 'scope_kind', 'conversation_id', 'range_from', 'range_to', 'granted_at', 'expires_at');
CREATE TRIGGER tg_log_access_grant_fsm_state BEFORE UPDATE ON ph17_assist.log_access_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'ACTIVE>EXPIRED,ACTIVE>REVOKED');
CALL ph17_assist.p_enable_rls('ph17_assist.log_access_grant');
COMMENT ON TABLE ph17_assist.log_access_grant IS 'EN-17-36 Phiếu truy cập nhật ký hội thoại có lý do (FR-17-056; BR-17-074, 075): chỉ SO, AUDITOR; lý do từ 20 ký tự; phạm vi một hội thoại hoặc khoảng không quá 92 ngày; hiệu lực tối đa 60 phút. Mỗi lần xem tăng access_count và ghi kiểm toán ở PH-13. Mở khóa RLS của conversation, message.';
COMMENT ON COLUMN ph17_assist.log_access_grant.conversation_id IS 'Tham chiếu logic tới conversation (không khóa ngoại: hội thoại có thể bị xóa theo hạn lưu).';
--rollback DROP TABLE IF EXISTS ph17_assist.log_access_grant CASCADE;

--changeset ph17:ph17-0590-compliance-export
CREATE TABLE ph17_assist.compliance_export (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  export_kind           varchar(16) NOT NULL,
  state                 varchar(10) NOT NULL DEFAULT 'GENERATING',
  requested_by          varchar(64) NOT NULL,
  period_from           date,
  period_to             date,
  file_id               uuid,
  sha256                char(64),
  signature_ref         varchar(255),
  expires_at            timestamptz,
  contains_conversation boolean NOT NULL DEFAULT false,
  error_code            varchar(16),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_export PRIMARY KEY (id),
  CONSTRAINT uq_compliance_export_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_compliance_export_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_compliance_export_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT ck_compliance_export_kind CHECK (export_kind IN ('COMPLIANCE_PACK', 'USAGE_REPORT')),
  CONSTRAINT ck_compliance_export_state CHECK (state IN ('GENERATING', 'READY', 'EXPIRED', 'FAILED')),
  CONSTRAINT ck_compliance_export_no_content CHECK (NOT contains_conversation),
  CONSTRAINT ck_compliance_export_period CHECK (period_to IS NULL OR period_from IS NULL OR (period_to >= period_from AND period_to <= period_from + 92)),
  CONSTRAINT ck_compliance_export_ready CHECK (state NOT IN ('READY') OR (file_id IS NOT NULL AND sha256 IS NOT NULL AND signature_ref IS NOT NULL AND expires_at IS NOT NULL)),
  CONSTRAINT ck_compliance_export_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_compliance_export_failed CHECK (state <> 'FAILED' OR error_code IS NOT NULL)
);
CREATE INDEX ix_compliance_export_state ON ph17_assist.compliance_export (tenant_id, state, created_at DESC);
CREATE TRIGGER tg_compliance_export_touch BEFORE UPDATE ON ph17_assist.compliance_export FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_compliance_export_fsm_state BEFORE UPDATE ON ph17_assist.compliance_export FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'GENERATING>READY,GENERATING>FAILED,READY>EXPIRED');
CALL ph17_assist.p_enable_rls('ph17_assist.compliance_export');
COMMENT ON TABLE ph17_assist.compliance_export IS 'EN-17-37 Gói bằng chứng tuân thủ và báo cáo sử dụng đã tạo (FR-17-057, 058; BR-17-076, 077): cấu hình, mô hình và phiên bản, kết quả đánh giá, ca đỏ, sổ đăng ký; KHÔNG chứa nội dung hội thoại. Có băm và chữ ký OpenBao; hết hạn tải thì EXPIRED (ERR-17-081).';
COMMENT ON COLUMN ph17_assist.compliance_export.signature_ref IS 'Tham chiếu chữ ký OpenBao transit; không chứa khóa.';
COMMENT ON COLUMN ph17_assist.compliance_export.contains_conversation IS 'Luôn sai: gói không mang nội dung hội thoại.';
--rollback DROP TABLE IF EXISTS ph17_assist.compliance_export CASCADE;
