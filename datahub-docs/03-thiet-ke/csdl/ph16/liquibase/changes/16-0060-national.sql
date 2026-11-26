--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0060-national.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0600-fn-submission-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_submission_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NOT ph16_kpi.f_setting_bool(NEW.tenant_id, '16.national.enabled', false) THEN
    RAISE EXCEPTION 'Gửi quốc gia chưa bật (16.national.enabled = false)' USING ERRCODE = '55000';
  END IF;
  IF NEW.state <> 'PENDING' THEN
    RAISE EXCEPTION 'Gói gửi quốc gia mới phải ở trạng thái PENDING' USING ERRCODE = '55000';
  END IF;
  IF NEW.submission_type = 'KPI_REPORT'
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_version v WHERE v.tenant_id = NEW.tenant_id AND v.id = NEW.report_version_id AND v.state = 'PUBLISHED') THEN
    RAISE EXCEPTION 'Chỉ gửi quốc gia phiên bản báo cáo đã công bố (PUBLISHED)' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_submission_gate() IS 'Cổng gửi quốc gia: tham số 16.national.enabled bật, gói mới ở PENDING, báo cáo phải PUBLISHED (FR-16-051).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_submission_gate();

--changeset ph16:ph16-0440-kpi-national-template
CREATE TABLE ph16_kpi.kpi_national_template (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  template_code   varchar(63) NOT NULL,
  version_no      integer NOT NULL DEFAULT 1,
  submission_type varchar(13) NOT NULL,
  name            varchar(255) NOT NULL,
  state           varchar(10) NOT NULL DEFAULT 'DRAFT',
  mapping         jsonb NOT NULL DEFAULT '{}',
  schema_ref      varchar(255),
  channel_ref     varchar(64) NOT NULL DEFAULT 'PH-14',
  effective_from  date,
  approved_by     varchar(64),
  activated_at    timestamptz,
  description     varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_national_template PRIMARY KEY (id),
  CONSTRAINT uq_kpi_national_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_national_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_national_template_version UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_kpi_national_template_code CHECK (template_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_national_template_no CHECK (version_no >= 1),
  CONSTRAINT ck_kpi_national_template_type CHECK (submission_type IN ('KPI_REPORT', 'ARCH_REGISTRY')),
  CONSTRAINT ck_kpi_national_template_state CHECK (state IN ('DRAFT', 'ACTIVE', 'SUPERSEDED')),
  CONSTRAINT ck_kpi_national_template_mapping CHECK (jsonb_typeof(mapping) = 'object'),
  CONSTRAINT ck_kpi_national_template_active CHECK (state = 'DRAFT' OR (activated_at IS NOT NULL AND approved_by IS NOT NULL))
);
CREATE UNIQUE INDEX uq_kpi_national_template_active ON ph16_kpi.kpi_national_template (tenant_id, template_code) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_kpi_national_template_touch BEFORE UPDATE ON ph16_kpi.kpi_national_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_national_template_immutable BEFORE UPDATE ON ph16_kpi.kpi_national_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'template_code', 'version_no', 'submission_type');
CREATE TRIGGER tg_kpi_national_template_frozen BEFORE UPDATE ON ph16_kpi.kpi_national_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'ACTIVE,SUPERSEDED', 'mapping', 'schema_ref', 'channel_ref', 'effective_from');
CREATE TRIGGER tg_kpi_national_template_transition BEFORE UPDATE ON ph16_kpi.kpi_national_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["ACTIVE"],"ACTIVE":["SUPERSEDED"]}');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_national_template');
COMMENT ON TABLE ph16_kpi.kpi_national_template IS 'EN-16-34 Mẫu gói quốc gia có phiên bản: cách ánh xạ chỉ tiêu hoặc sổ kiến trúc sang lược đồ của nền tảng quốc gia, là cấu hình ngoài vì khung quốc gia chưa ban hành (CMP-LAW-11 dự thảo, ADR đề xuất dải 160…164); kênh gửi là PH-14 (FR-16-050). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S).';
COMMENT ON COLUMN ph16_kpi.kpi_national_template.mapping IS 'Ánh xạ trường nội bộ sang lược đồ nền tảng quốc gia; thay đổi khi khung ban hành chỉ cần phiên bản mẫu mới, không đổi mã.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_national_template CASCADE;

--changeset ph16:ph16-0450-kpi-national-submission
CREATE TABLE ph16_kpi.kpi_national_submission (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  submission_type      varchar(13) NOT NULL,
  template_id          uuid NOT NULL,
  state                varchar(12) NOT NULL DEFAULT 'PENDING',
  report_version_id    uuid,
  report_code          varchar(63),
  report_version_no    integer,
  component_version_id uuid,
  component_code       varchar(63),
  version_label        varchar(32),
  content_hash         bytea NOT NULL,
  submitted_by         varchar(64) NOT NULL,
  attempt_count        smallint NOT NULL DEFAULT 0,
  sent_at              timestamptz,
  channel_ref          varchar(128),
  ack_ref              varchar(128),
  ack_at               timestamptz,
  last_error_code      varchar(11),
  last_error_detail    varchar(2000),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_national_submission PRIMARY KEY (id),
  CONSTRAINT uq_kpi_national_submission_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_national_submission_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_national_submission_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph16_kpi.kpi_national_template (tenant_id, id),
  CONSTRAINT fk_kpi_national_submission_report FOREIGN KEY (tenant_id, report_version_id) REFERENCES ph16_kpi.kpi_report_version (tenant_id, id),
  CONSTRAINT fk_kpi_national_submission_component FOREIGN KEY (tenant_id, component_version_id) REFERENCES ph16_kpi.kpi_arch_component_version (tenant_id, id),
  CONSTRAINT ck_kpi_national_submission_type CHECK (submission_type IN ('KPI_REPORT', 'ARCH_REGISTRY')),
  CONSTRAINT ck_kpi_national_submission_state CHECK (state IN ('PENDING', 'SENDING', 'SENT', 'ACKNOWLEDGED', 'REJECTED', 'FAILED')),
  CONSTRAINT ck_kpi_national_submission_subject CHECK ((submission_type = 'KPI_REPORT' AND report_version_id IS NOT NULL AND report_code IS NOT NULL AND report_version_no IS NOT NULL AND component_code IS NULL AND version_label IS NULL) OR (submission_type = 'ARCH_REGISTRY' AND component_version_id IS NOT NULL AND component_code IS NOT NULL AND version_label IS NOT NULL AND report_code IS NULL AND report_version_no IS NULL)),
  CONSTRAINT ck_kpi_national_submission_hash CHECK (octet_length(content_hash) = 32),
  CONSTRAINT ck_kpi_national_submission_attempt CHECK (attempt_count >= 0),
  CONSTRAINT ck_kpi_national_submission_sent CHECK (state NOT IN ('SENT', 'ACKNOWLEDGED', 'REJECTED') OR sent_at IS NOT NULL),
  CONSTRAINT ck_kpi_national_submission_ack CHECK (state <> 'ACKNOWLEDGED' OR (ack_at IS NOT NULL AND ack_ref IS NOT NULL)),
  CONSTRAINT ck_kpi_national_submission_failed CHECK (state NOT IN ('FAILED', 'REJECTED') OR last_error_code IS NOT NULL),
  CONSTRAINT ck_kpi_national_submission_error CHECK (last_error_code IS NULL OR last_error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE UNIQUE INDEX uq_kpi_national_submission_report ON ph16_kpi.kpi_national_submission (tenant_id, report_code, report_version_no) WHERE submission_type = 'KPI_REPORT';
CREATE UNIQUE INDEX uq_kpi_national_submission_arch ON ph16_kpi.kpi_national_submission (tenant_id, component_code, version_label, content_hash) WHERE submission_type = 'ARCH_REGISTRY';
CREATE INDEX ix_kpi_national_submission_state ON ph16_kpi.kpi_national_submission (tenant_id, state, updated_at DESC);
CREATE TRIGGER tg_kpi_national_submission_touch BEFORE UPDATE ON ph16_kpi.kpi_national_submission FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_national_submission_immutable BEFORE UPDATE ON ph16_kpi.kpi_national_submission FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'submission_type', 'template_id', 'report_version_id', 'report_code', 'report_version_no', 'component_version_id', 'component_code', 'version_label', 'content_hash', 'submitted_by');
CREATE TRIGGER tg_kpi_national_submission_transition BEFORE UPDATE ON ph16_kpi.kpi_national_submission FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"PENDING":["SENDING"],"SENDING":["SENT","FAILED"],"SENT":["ACKNOWLEDGED","REJECTED"],"FAILED":["SENDING"]}');
CREATE TRIGGER tg_kpi_national_submission_gate BEFORE INSERT ON ph16_kpi.kpi_national_submission FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_submission_gate();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_national_submission');
COMMENT ON TABLE ph16_kpi.kpi_national_submission IS 'EN-16-35 Gói gửi quốc gia: báo cáo chỉ tiêu (KPI_REPORT) hoặc sổ kiến trúc (ARCH_REGISTRY) gửi qua PH-14; PENDING, SENDING, SENT, ACKNOWLEDGED, REJECTED, FAILED; idempotent theo `report_code` + `report_version_no` hoặc `component_code` + `version_label` + `content_hash` (FR-16-051, 052, 054). Chỉ tạo khi `16.national.enabled` bật; báo cáo phải PUBLISHED.';
COMMENT ON COLUMN ph16_kpi.kpi_national_submission.channel_ref IS 'Mã giao dịch của PH-14 (EVT-14-11, 12); PH-16 không giữ thông tin xác thực quốc gia (OpenBao ở PH-14).';
COMMENT ON COLUMN ph16_kpi.kpi_national_submission.attempt_count IS 'Số lần gửi; không vượt 16.national.retry-max + 1 do dịch vụ kiểm.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_national_submission CASCADE;

--changeset ph16:ph16-0460-kpi-national-submission-log
CREATE TABLE ph16_kpi.kpi_national_submission_log (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  submission_id uuid NOT NULL,
  seq           integer NOT NULL,
  event_type    varchar(12) NOT NULL,
  state_after   varchar(12) NOT NULL,
  actor         varchar(64) NOT NULL,
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  request_hash  bytea,
  response_hash bytea,
  channel_ref   varchar(128),
  error_code    varchar(11),
  detail        varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_national_submission_log PRIMARY KEY (id),
  CONSTRAINT ck_kpi_national_submission_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_national_submission_log_seq UNIQUE (tenant_id, submission_id, seq),
  CONSTRAINT fk_kpi_national_submission_log_submission FOREIGN KEY (tenant_id, submission_id) REFERENCES ph16_kpi.kpi_national_submission (tenant_id, id),
  CONSTRAINT ck_kpi_national_submission_log_seq CHECK (seq >= 1),
  CONSTRAINT ck_kpi_national_submission_log_event CHECK (event_type IN ('CREATED', 'SENDING', 'SENT', 'ACKNOWLEDGED', 'REJECTED', 'FAILED', 'RETRY')),
  CONSTRAINT ck_kpi_national_submission_log_state CHECK (state_after IN ('PENDING', 'SENDING', 'SENT', 'ACKNOWLEDGED', 'REJECTED', 'FAILED')),
  CONSTRAINT ck_kpi_national_submission_log_req_hash CHECK (request_hash IS NULL OR octet_length(request_hash) = 32),
  CONSTRAINT ck_kpi_national_submission_log_resp_hash CHECK (response_hash IS NULL OR octet_length(response_hash) = 32),
  CONSTRAINT ck_kpi_national_submission_log_error CHECK (error_code IS NULL OR error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE INDEX ix_kpi_national_submission_log_time ON ph16_kpi.kpi_national_submission_log (tenant_id, occurred_at DESC);
CREATE TRIGGER tg_kpi_national_submission_log_touch BEFORE UPDATE ON ph16_kpi.kpi_national_submission_log FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_national_submission_log_append_only BEFORE UPDATE OR DELETE ON ph16_kpi.kpi_national_submission_log FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_append_only();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_national_submission_log');
COMMENT ON TABLE ph16_kpi.kpi_national_submission_log IS 'EN-16-36 Nhật ký nộp: bằng chứng từng bước gửi quốc gia (tạo, gửi, biên nhận, từ chối, lỗi, gửi lại) kèm băm yêu cầu, băm phản hồi, mã giao dịch PH-14. Chỉ thêm, không sửa, xóa kể cả chủ schema; giữ như báo cáo công bố (FR-16-053).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_national_submission_log CASCADE;
