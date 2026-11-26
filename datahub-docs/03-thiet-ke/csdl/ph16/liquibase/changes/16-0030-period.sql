--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0030-period.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0300-fn-period-open splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_period_open() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
BEGIN
  SELECT state INTO st FROM ph16_kpi.kpi_reporting_period WHERE tenant_id = NEW.tenant_id AND id = NEW.period_id;
  IF st = 'CLOSED' THEN
    RAISE EXCEPTION 'Kỳ đã chốt (CLOSED): không ghi giá trị, điểm nhóm; mở lại kỳ có lý do trước' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_period_open() IS 'Chặn ghi giá trị chỉ tiêu, điểm nhóm vào kỳ đã chốt (FR-16-024).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_period_open();

--changeset ph16:ph16-0301-fn-manual-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_manual_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.state <> 'DRAFT' THEN
      RAISE EXCEPTION 'Số liệu tay mới phải ở trạng thái DRAFT' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.state = 'SUBMITTED' AND OLD.state <> 'SUBMITTED'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.manual.evidence-required', true)
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_manual_evidence WHERE tenant_id = NEW.tenant_id AND manual_value_id = NEW.id) THEN
    RAISE EXCEPTION 'Gửi xác nhận cần bằng chứng (16.manual.evidence-required = true)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_manual_gate() IS 'Số liệu tay: tạo ở DRAFT; gửi xác nhận phải có bằng chứng khi tham số 16.manual.evidence-required bật (FR-16-014).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_manual_gate();

--changeset ph16:ph16-0180-kpi-reporting-period
CREATE TABLE ph16_kpi.kpi_reporting_period (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  period_code            varchar(16) NOT NULL,
  period_type            varchar(8) NOT NULL,
  start_date             date NOT NULL,
  end_date               date NOT NULL,
  state                  varchar(10) NOT NULL DEFAULT 'OPEN',
  close_due_date         date,
  closed_by              varchar(64),
  closed_at              timestamptz,
  reopen_reason          varchar(2000),
  reopened_by            varchar(64),
  reopened_at            timestamptz,
  reopen_count           smallint NOT NULL DEFAULT 0,
  recompute_requested_at timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_reporting_period PRIMARY KEY (id),
  CONSTRAINT uq_kpi_reporting_period_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_reporting_period_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_reporting_period_code UNIQUE (tenant_id, period_code),
  CONSTRAINT ck_kpi_reporting_period_type CHECK (period_type IN ('MONTH', 'QUARTER', 'YEAR')),
  CONSTRAINT ck_kpi_reporting_period_code CHECK ((period_type = 'MONTH' AND period_code ~ '^M-[0-9]{4}-(0[1-9]|1[0-2])$') OR (period_type = 'QUARTER' AND period_code ~ '^Q-[0-9]{4}-Q[1-4]$') OR (period_type = 'YEAR' AND period_code ~ '^Y-[0-9]{4}$')),
  CONSTRAINT ck_kpi_reporting_period_dates CHECK (end_date >= start_date),
  CONSTRAINT ck_kpi_reporting_period_state CHECK (state IN ('OPEN', 'COLLECTING', 'COMPUTED', 'CLOSED', 'REOPENED')),
  CONSTRAINT ck_kpi_reporting_period_closed CHECK (state <> 'CLOSED' OR (closed_by IS NOT NULL AND closed_at IS NOT NULL)),
  CONSTRAINT ck_kpi_reporting_period_reopened CHECK (state <> 'REOPENED' OR (COALESCE(char_length(reopen_reason) >= 50, false) AND reopened_by IS NOT NULL AND reopened_at IS NOT NULL AND reopen_count >= 1))
);
CREATE INDEX ix_kpi_reporting_period_start ON ph16_kpi.kpi_reporting_period (tenant_id, period_type, start_date DESC);
CREATE TRIGGER tg_kpi_reporting_period_touch BEFORE UPDATE ON ph16_kpi.kpi_reporting_period FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_reporting_period_immutable BEFORE UPDATE ON ph16_kpi.kpi_reporting_period FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'period_code', 'period_type', 'start_date', 'end_date');
CREATE TRIGGER tg_kpi_reporting_period_transition BEFORE UPDATE ON ph16_kpi.kpi_reporting_period FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"OPEN":["COLLECTING"],"COLLECTING":["COMPUTED"],"COMPUTED":["CLOSED"],"CLOSED":["REOPENED"],"REOPENED":["COMPUTED","CLOSED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_reporting_period');
COMMENT ON TABLE ph16_kpi.kpi_reporting_period IS 'EN-16-14 Kỳ báo cáo tháng, quý, năm mã `M-2026-10`, `Q-2026-Q3`, `Y-2026`; vòng đời OPEN, COLLECTING, COMPUTED, CLOSED, REOPENED. Kỳ CLOSED không nhận giá trị mới; mở lại phải có lý do và người mở (FR-16-017, 024).';
COMMENT ON COLUMN ph16_kpi.kpi_reporting_period.close_due_date IS 'Ngày dự kiến chốt, theo tham số 16.period.close-day (mặc định ngày 5 của tháng sau).';
COMMENT ON COLUMN ph16_kpi.kpi_reporting_period.reopen_reason IS 'Lý do mở lại từ 50 ký tự (BR-16-011, ERR-16-007).';
COMMENT ON COLUMN ph16_kpi.kpi_reporting_period.recompute_requested_at IS 'Mốc yêu cầu tính lại đầu tiên trong cửa sổ 16.late-data.debounce-minutes; bộ quét tạo lần LATE_DATA khi quá cửa sổ rồi đặt về NULL (FR-16-023).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_reporting_period CASCADE;

--changeset ph16:ph16-0190-kpi-manual-value
CREATE TABLE ph16_kpi.kpi_manual_value (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  indicator_id     uuid NOT NULL,
  period_id        uuid NOT NULL,
  variable_name    varchar(63) NOT NULL DEFAULT 'value',
  value            numeric(24,6) NOT NULL,
  unit             varchar(32),
  state            varchar(9) NOT NULL DEFAULT 'DRAFT',
  entered_by       varchar(64) NOT NULL,
  entered_at       timestamptz NOT NULL DEFAULT now(),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  note             varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_manual_value PRIMARY KEY (id),
  CONSTRAINT uq_kpi_manual_value_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_manual_value_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_manual_value_indicator FOREIGN KEY (tenant_id, indicator_id) REFERENCES ph16_kpi.kpi_indicator (tenant_id, id),
  CONSTRAINT fk_kpi_manual_value_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT ck_kpi_manual_value_state CHECK (state IN ('DRAFT', 'SUBMITTED', 'ACCEPTED', 'REJECTED')),
  CONSTRAINT ck_kpi_manual_value_four_eyes CHECK (decided_by IS NULL OR entered_by IS NULL OR decided_by <> entered_by),
  CONSTRAINT ck_kpi_manual_value_submitted CHECK (state = 'DRAFT' OR submitted_at IS NOT NULL),
  CONSTRAINT ck_kpi_manual_value_decided CHECK (state NOT IN ('ACCEPTED', 'REJECTED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_kpi_manual_value_rejected CHECK (state <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_kpi_manual_value_open ON ph16_kpi.kpi_manual_value (tenant_id, indicator_id, period_id, variable_name) WHERE state <> 'REJECTED';
CREATE INDEX ix_kpi_manual_value_inbox ON ph16_kpi.kpi_manual_value (tenant_id, state, submitted_at) WHERE state = 'SUBMITTED';
CREATE TRIGGER tg_kpi_manual_value_touch BEFORE UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_manual_value_immutable BEFORE UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'indicator_id', 'period_id', 'variable_name', 'entered_by');
CREATE TRIGGER tg_kpi_manual_value_frozen BEFORE UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'SUBMITTED,ACCEPTED,REJECTED', 'value', 'unit');
CREATE TRIGGER tg_kpi_manual_value_transition BEFORE UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["SUBMITTED"],"SUBMITTED":["ACCEPTED","REJECTED","DRAFT"],"REJECTED":["DRAFT"]}');
CREATE TRIGGER tg_kpi_manual_value_gate BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_manual_gate();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_manual_value');
COMMENT ON TABLE ph16_kpi.kpi_manual_value IS 'EN-16-11 Số liệu nhập tay cho chỉ tiêu đo MANUAL hoặc MIXED: DRAFT, SUBMITTED, ACCEPTED, REJECTED; người nhập khác người xác nhận (FR-16-014, 015). Gửi xác nhận cần bằng chứng khi `16.manual.evidence-required` bật. Số liệu đã gửi hoặc đã quyết định không đổi giá trị.';
COMMENT ON COLUMN ph16_kpi.kpi_manual_value.variable_name IS 'Tên biến trong công thức CEL mà số liệu tay cung cấp; mặc định `value` cho chỉ tiêu một biến.';
COMMENT ON COLUMN ph16_kpi.kpi_manual_value.decided_by IS 'Người xác nhận; CHECK ck_kpi_manual_value_four_eyes buộc khác `entered_by` (cặp loại trừ, PERM-16-manual).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_manual_value CASCADE;

--changeset ph16:ph16-0200-kpi-manual-evidence
CREATE TABLE ph16_kpi.kpi_manual_evidence (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  manual_value_id uuid NOT NULL,
  evidence_type   varchar(15) NOT NULL,
  object_ref      varchar(512),
  file_name       varchar(255),
  content_hash    bytea,
  document_no     varchar(64),
  document_date   date,
  description     varchar(2000),
  uploaded_by     varchar(64) NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_manual_evidence PRIMARY KEY (id),
  CONSTRAINT ck_kpi_manual_evidence_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_manual_evidence_manual FOREIGN KEY (tenant_id, manual_value_id) REFERENCES ph16_kpi.kpi_manual_value (tenant_id, id),
  CONSTRAINT ck_kpi_manual_evidence_type CHECK (evidence_type IN ('FILE', 'DOCUMENT_NUMBER')),
  CONSTRAINT ck_kpi_manual_evidence_file CHECK (evidence_type <> 'FILE' OR (object_ref IS NOT NULL AND file_name IS NOT NULL AND content_hash IS NOT NULL)),
  CONSTRAINT ck_kpi_manual_evidence_doc CHECK (evidence_type <> 'DOCUMENT_NUMBER' OR (document_no IS NOT NULL AND document_date IS NOT NULL)),
  CONSTRAINT ck_kpi_manual_evidence_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32)
);
CREATE INDEX ix_kpi_manual_evidence_value ON ph16_kpi.kpi_manual_evidence (tenant_id, manual_value_id);
CREATE TRIGGER tg_kpi_manual_evidence_touch BEFORE UPDATE ON ph16_kpi.kpi_manual_evidence FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_manual_evidence_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph16_kpi.kpi_manual_evidence FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_child_frozen('kpi_manual_value', 'manual_value_id', 'DRAFT');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_manual_evidence');
COMMENT ON TABLE ph16_kpi.kpi_manual_evidence IS 'EN-16-12 Bằng chứng của số liệu nhập tay: tệp đính kèm (Ceph RGW, kèm SHA-256) hoặc số và ngày văn bản (FR-16-014). Chỉ thêm, sửa, xóa khi số liệu cha còn DRAFT; sau khi gửi xác nhận là bằng chứng cố định.';
COMMENT ON COLUMN ph16_kpi.kpi_manual_evidence.object_ref IS 'Đường dẫn đối tượng trên Ceph RGW (bucket kpi-evidence); không lưu tệp trong PostgreSQL.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_manual_evidence CASCADE;

--changeset ph16:ph16-0210-kpi-manual-import
CREATE TABLE ph16_kpi.kpi_manual_import (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  file_name      varchar(255) NOT NULL,
  object_ref     varchar(512) NOT NULL,
  content_hash   bytea NOT NULL,
  row_total      integer NOT NULL,
  valid_count    integer NOT NULL DEFAULT 0,
  invalid_count  integer NOT NULL DEFAULT 0,
  imported_count integer NOT NULL DEFAULT 0,
  uploaded_by    varchar(64) NOT NULL,
  expires_at     timestamptz NOT NULL,
  committed_by   varchar(64),
  committed_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_manual_import PRIMARY KEY (id),
  CONSTRAINT uq_kpi_manual_import_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_manual_import_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_kpi_manual_import_rows CHECK (row_total BETWEEN 1 AND 2000 AND valid_count >= 0 AND invalid_count >= 0 AND valid_count + invalid_count <= row_total AND imported_count BETWEEN 0 AND valid_count),
  CONSTRAINT ck_kpi_manual_import_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32),
  CONSTRAINT ck_kpi_manual_import_expiry CHECK (expires_at > created_at AND expires_at <= created_at + interval '24 hours'),
  CONSTRAINT ck_kpi_manual_import_committed CHECK ((committed_at IS NULL) = (committed_by IS NULL) AND (committed_at IS NULL OR imported_count >= 1))
);
CREATE INDEX ix_kpi_manual_import_expiry ON ph16_kpi.kpi_manual_import (expires_at) WHERE committed_at IS NULL;
CREATE TRIGGER tg_kpi_manual_import_touch BEFORE UPDATE ON ph16_kpi.kpi_manual_import FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_manual_import_immutable BEFORE UPDATE ON ph16_kpi.kpi_manual_import FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'file_name', 'object_ref', 'content_hash', 'row_total', 'uploaded_by', 'expires_at');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_manual_import');
COMMENT ON TABLE ph16_kpi.kpi_manual_import IS 'EN-16-13 Lần nhập số liệu tay từ tệp XLSX theo mẫu (≤ 2.000 dòng): tệp gốc, mã băm, số dòng hợp lệ, lỗi, đã ghi; bản xem trước giữ 24 giờ rồi dọn (FR-16-014). Ghi các dòng hợp lệ tạo số liệu tay DRAFT.';
COMMENT ON COLUMN ph16_kpi.kpi_manual_import.object_ref IS 'Tệp XLSX gốc trên Ceph RGW (bucket kpi-evidence, tiền tố imports/); xóa cùng bản ghi khi quá expires_at.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_manual_import CASCADE;

--changeset ph16:ph16-0220-kpi-manual-import-row
CREATE TABLE ph16_kpi.kpi_manual_import_row (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  import_id       uuid NOT NULL,
  row_no          integer NOT NULL,
  indicator_code  varchar(63),
  period_code     varchar(16),
  value           numeric(24,6),
  row_status      varchar(8) NOT NULL,
  error_code      varchar(11),
  detail          varchar(500),
  manual_value_id uuid,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_manual_import_row PRIMARY KEY (id),
  CONSTRAINT ck_kpi_manual_import_row_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_manual_import_row_no UNIQUE (tenant_id, import_id, row_no),
  CONSTRAINT fk_kpi_manual_import_row_import FOREIGN KEY (tenant_id, import_id) REFERENCES ph16_kpi.kpi_manual_import (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_kpi_manual_import_row_manual FOREIGN KEY (tenant_id, manual_value_id) REFERENCES ph16_kpi.kpi_manual_value (tenant_id, id),
  CONSTRAINT ck_kpi_manual_import_row_no CHECK (row_no BETWEEN 1 AND 2000),
  CONSTRAINT ck_kpi_manual_import_row_status CHECK (row_status IN ('VALID', 'INVALID', 'IMPORTED')),
  CONSTRAINT ck_kpi_manual_import_row_invalid CHECK ((row_status = 'INVALID') = (error_code IS NOT NULL)),
  CONSTRAINT ck_kpi_manual_import_row_imported CHECK ((row_status = 'IMPORTED') = (manual_value_id IS NOT NULL)),
  CONSTRAINT ck_kpi_manual_import_row_error CHECK (error_code IS NULL OR error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE TRIGGER tg_kpi_manual_import_row_touch BEFORE UPDATE ON ph16_kpi.kpi_manual_import_row FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_manual_import_row_immutable BEFORE UPDATE ON ph16_kpi.kpi_manual_import_row FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'import_id', 'row_no', 'indicator_code', 'period_code', 'value');
CREATE TRIGGER tg_kpi_manual_import_row_transition BEFORE UPDATE ON ph16_kpi.kpi_manual_import_row FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('row_status', '{"VALID":["IMPORTED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_manual_import_row');
COMMENT ON TABLE ph16_kpi.kpi_manual_import_row IS 'EN-16-13 Dòng của lần nhập tệp: chỉ tiêu, kỳ, giá trị đọc được, kết quả kiểm VALID, INVALID (kèm mã lỗi) hoặc IMPORTED khi đã thành số liệu tay (FR-16-014). Bản xem trước UI-16-07 đọc bảng này.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_manual_import_row CASCADE;

--changeset ph16:ph16-0230-kpi-aggregation-run
CREATE TABLE ph16_kpi.kpi_aggregation_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  period_id          uuid NOT NULL,
  run_no             integer NOT NULL,
  run_trigger        varchar(9) NOT NULL,
  state              varchar(9) NOT NULL DEFAULT 'QUEUED',
  requested_by       varchar(64) NOT NULL,
  reason             varchar(2000),
  started_at         timestamptz,
  finished_at        timestamptz,
  completeness       numeric(5,4),
  flags              text[] NOT NULL DEFAULT '{}',
  indicator_total    smallint NOT NULL DEFAULT 0,
  indicator_computed smallint NOT NULL DEFAULT 0,
  idempotency_ref    varchar(128),
  error_code         varchar(11),
  error_message      varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_aggregation_run PRIMARY KEY (id),
  CONSTRAINT uq_kpi_aggregation_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_aggregation_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_aggregation_run_no UNIQUE (tenant_id, period_id, run_no),
  CONSTRAINT fk_kpi_aggregation_run_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT ck_kpi_aggregation_run_no CHECK (run_no >= 1),
  CONSTRAINT ck_kpi_aggregation_run_trigger CHECK (run_trigger IN ('SCHEDULE', 'MANUAL', 'RECOMPUTE', 'LATE_DATA')),
  CONSTRAINT ck_kpi_aggregation_run_state CHECK (state IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_kpi_aggregation_run_flags CHECK (flags <@ ARRAY['MISSING_SOURCE', 'STALE_SOURCE', 'MANUAL_PENDING', 'FORMULA_ERROR']::text[]),
  CONSTRAINT ck_kpi_aggregation_run_completeness CHECK (completeness IS NULL OR (completeness >= 0 AND completeness <= 1)),
  CONSTRAINT ck_kpi_aggregation_run_counts CHECK (indicator_total >= 0 AND indicator_computed >= 0 AND indicator_computed <= indicator_total),
  CONSTRAINT ck_kpi_aggregation_run_done CHECK (state NOT IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_kpi_aggregation_run_result CHECK (state NOT IN ('SUCCEEDED', 'PARTIAL') OR completeness IS NOT NULL),
  CONSTRAINT ck_kpi_aggregation_run_partial CHECK (state <> 'PARTIAL' OR (cardinality(flags) > 0 OR completeness < 1)),
  CONSTRAINT ck_kpi_aggregation_run_failed CHECK (state <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_kpi_aggregation_run_reason CHECK (run_trigger NOT IN ('RECOMPUTE', 'LATE_DATA') OR COALESCE(char_length(reason) >= 20, false)),
  CONSTRAINT ck_kpi_aggregation_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE UNIQUE INDEX uq_kpi_aggregation_run_active ON ph16_kpi.kpi_aggregation_run (tenant_id, period_id) WHERE state IN ('QUEUED', 'RUNNING');
CREATE UNIQUE INDEX uq_kpi_aggregation_run_idem ON ph16_kpi.kpi_aggregation_run (tenant_id, idempotency_ref) WHERE idempotency_ref IS NOT NULL;
CREATE INDEX ix_kpi_aggregation_run_state ON ph16_kpi.kpi_aggregation_run (tenant_id, state, started_at DESC);
CREATE TRIGGER tg_kpi_aggregation_run_touch BEFORE UPDATE ON ph16_kpi.kpi_aggregation_run FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_aggregation_run_immutable BEFORE UPDATE ON ph16_kpi.kpi_aggregation_run FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'period_id', 'run_no', 'run_trigger', 'requested_by');
CREATE TRIGGER tg_kpi_aggregation_run_transition BEFORE UPDATE ON ph16_kpi.kpi_aggregation_run FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"QUEUED":["RUNNING","CANCELLED"],"RUNNING":["SUCCEEDED","PARTIAL","FAILED","CANCELLED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_aggregation_run');
COMMENT ON TABLE ph16_kpi.kpi_aggregation_run IS 'EN-16-15 Lần tổng hợp: một lần tính mọi chỉ tiêu của một kỳ, theo lịch, thủ công, tính lại hoặc do số liệu trễ; ghi độ đầy đủ, cờ thiếu nguồn, số chỉ tiêu có số (FR-16-018, 020, 023, 042). SUCCEEDED, PARTIAL, FAILED, CANCELLED là trạng thái cuối. Mỗi kỳ tối đa một lần đang QUEUED hoặc RUNNING.';
COMMENT ON COLUMN ph16_kpi.kpi_aggregation_run.idempotency_ref IS 'Chống chạy lặp theo lịch, ví dụ `agg:M-2026-10:2026-11-05`; NULL với lần chạy tay.';
COMMENT ON COLUMN ph16_kpi.kpi_aggregation_run.flags IS 'Cờ: MISSING_SOURCE, STALE_SOURCE, MANUAL_PENDING, FORMULA_ERROR.';
COMMENT ON COLUMN ph16_kpi.kpi_aggregation_run.completeness IS 'Tỷ lệ chỉ tiêu có số trên tổng số chỉ tiêu đang ACTIVE của kỳ (0…1).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_aggregation_run CASCADE;

--changeset ph16:ph16-0240-kpi-indicator-value
CREATE TABLE ph16_kpi.kpi_indicator_value (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  period_id         uuid NOT NULL,
  period_code       varchar(16) NOT NULL,
  period_start      date NOT NULL,
  run_id            uuid NOT NULL,
  indicator_id      uuid NOT NULL,
  indicator_code    varchar(63) NOT NULL,
  group_code        varchar(16) NOT NULL,
  version_id        uuid NOT NULL,
  value             numeric(24,6),
  status            varchar(9) NOT NULL,
  completeness      varchar(9) NOT NULL,
  delta             numeric(24,6),
  delta_yoy         numeric(24,6),
  trend             varchar(8),
  is_current        boolean NOT NULL DEFAULT true,
  missing_variables text[] NOT NULL DEFAULT '{}',
  computed_at       timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_indicator_value PRIMARY KEY (id, period_start),
  CONSTRAINT ck_kpi_indicator_value_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_indicator_value_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT fk_kpi_indicator_value_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph16_kpi.kpi_aggregation_run (tenant_id, id),
  CONSTRAINT fk_kpi_indicator_value_indicator FOREIGN KEY (tenant_id, indicator_id) REFERENCES ph16_kpi.kpi_indicator (tenant_id, id),
  CONSTRAINT fk_kpi_indicator_value_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph16_kpi.kpi_indicator_version (tenant_id, id),
  CONSTRAINT ck_kpi_indicator_value_status CHECK (status IN ('ON_TRACK', 'AT_RISK', 'OFF_TRACK', 'NO_DATA')),
  CONSTRAINT ck_kpi_indicator_value_completeness CHECK (completeness IN ('COMPLETE', 'PARTIAL', 'NO_DATA')),
  CONSTRAINT ck_kpi_indicator_value_trend CHECK (trend IS NULL OR trend IN ('UP', 'DOWN', 'FLAT')),
  CONSTRAINT ck_kpi_indicator_value_no_data CHECK ((completeness = 'NO_DATA') = (value IS NULL) AND (completeness = 'NO_DATA') = (status = 'NO_DATA')),
  CONSTRAINT ck_kpi_indicator_value_period_code CHECK (period_code ~ '^(M-[0-9]{4}-[0-9]{2}|Q-[0-9]{4}-Q[1-4]|Y-[0-9]{4})$'),
  CONSTRAINT ck_kpi_indicator_value_group CHECK (group_code IN ('KET_NOI', 'CHIA_SE', 'DU_LIEU', 'VAN_HANH', 'KIEN_TRUC')),
  CONSTRAINT ck_kpi_indicator_value_missing CHECK (completeness <> 'PARTIAL' OR cardinality(missing_variables) > 0)
) PARTITION BY RANGE (period_start);
CALL ph16_kpi.p_ensure_partitions('ph16_kpi.kpi_indicator_value', date '2026-01-01', 24);
CREATE UNIQUE INDEX uq_kpi_indicator_value_run ON ph16_kpi.kpi_indicator_value (tenant_id, run_id, indicator_id, period_start);
CREATE UNIQUE INDEX uq_kpi_indicator_value_current ON ph16_kpi.kpi_indicator_value (tenant_id, period_id, indicator_id, period_start) WHERE is_current;
CREATE INDEX ix_kpi_indicator_value_series ON ph16_kpi.kpi_indicator_value (tenant_id, indicator_id, period_start DESC) WHERE is_current;
CREATE INDEX ix_kpi_indicator_value_status ON ph16_kpi.kpi_indicator_value (tenant_id, period_id, status) WHERE is_current;
CREATE TRIGGER tg_kpi_indicator_value_touch BEFORE UPDATE ON ph16_kpi.kpi_indicator_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_indicator_value_immutable BEFORE UPDATE ON ph16_kpi.kpi_indicator_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'period_id', 'period_code', 'period_start', 'run_id', 'indicator_id', 'indicator_code', 'version_id');
CREATE TRIGGER tg_kpi_indicator_value_period BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_indicator_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_period_open();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_indicator_value');
COMMENT ON TABLE ph16_kpi.kpi_indicator_value IS 'EN-16-16 Giá trị chỉ tiêu theo kỳ và lần tổng hợp: số, trạng thái so mục tiêu và ngưỡng (ON_TRACK, AT_RISK, OFF_TRACK, NO_DATA), độ đầy đủ (COMPLETE, PARTIAL, NO_DATA), chênh lệch so kỳ trước và cùng kỳ năm trước, xu hướng; ghi phiên bản công thức đã dùng (FR-16-019, 021, 022, 035, 037, 039, 040, 041). Phân vùng tháng theo `period_start`. Kỳ CLOSED không nhận giá trị mới.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_value.is_current IS 'Dòng của lần tổng hợp mới nhất cho (kỳ, chỉ tiêu); tính lại đặt dòng cũ về false. Mỗi (kỳ, chỉ tiêu) một dòng hiện hành.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_value.version_id IS 'Phiên bản công thức có hiệu lực lúc tính; cùng `kpi_value_lineage` làm dòng truy nguồn.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_value.period_start IS 'Khóa phân vùng: ngày bắt đầu của kỳ (kỳ quý, năm nằm ở phân vùng tháng đầu).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_value.missing_variables IS 'Tên biến thiếu quan sát khi PARTIAL (fail-soft, không bịa số).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_indicator_value CASCADE;

--changeset ph16:ph16-0250-kpi-value-lineage
CREATE TABLE ph16_kpi.kpi_value_lineage (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  value_id         uuid NOT NULL,
  period_start     date NOT NULL,
  run_id           uuid NOT NULL,
  seq              smallint NOT NULL,
  variable_name    varchar(63) NOT NULL,
  source_kind      varchar(12) NOT NULL,
  metric_code      varchar(128),
  observation_id   uuid,
  manual_value_id  uuid,
  ref_indicator_id uuid,
  ref_value_id     uuid,
  used_value       numeric(24,6),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_value_lineage PRIMARY KEY (id, period_start),
  CONSTRAINT ck_kpi_value_lineage_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_value_lineage_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph16_kpi.kpi_aggregation_run (tenant_id, id),
  CONSTRAINT fk_kpi_value_lineage_manual FOREIGN KEY (tenant_id, manual_value_id) REFERENCES ph16_kpi.kpi_manual_value (tenant_id, id),
  CONSTRAINT fk_kpi_value_lineage_ref FOREIGN KEY (tenant_id, ref_indicator_id) REFERENCES ph16_kpi.kpi_indicator (tenant_id, id),
  CONSTRAINT ck_kpi_value_lineage_seq CHECK (seq >= 1),
  CONSTRAINT ck_kpi_value_lineage_kind CHECK (source_kind IN ('OBSERVATION', 'MANUAL_VALUE', 'INDICATOR', 'PERIOD_VALUE')),
  CONSTRAINT ck_kpi_value_lineage_ref_one CHECK ((source_kind = 'OBSERVATION') = (observation_id IS NOT NULL) AND (source_kind = 'MANUAL_VALUE') = (manual_value_id IS NOT NULL) AND (source_kind = 'INDICATOR') = (ref_indicator_id IS NOT NULL) AND (source_kind = 'PERIOD_VALUE') = (ref_value_id IS NOT NULL)),
  CONSTRAINT ck_kpi_value_lineage_metric CHECK (metric_code IS NULL OR metric_code ~ '^ph[0-9]{2}\.[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*$')
) PARTITION BY RANGE (period_start);
CALL ph16_kpi.p_ensure_partitions('ph16_kpi.kpi_value_lineage', date '2026-01-01', 24);
CREATE UNIQUE INDEX uq_kpi_value_lineage_seq ON ph16_kpi.kpi_value_lineage (tenant_id, value_id, seq, period_start);
CREATE INDEX ix_kpi_value_lineage_obs ON ph16_kpi.kpi_value_lineage (tenant_id, observation_id) WHERE observation_id IS NOT NULL;
CREATE TRIGGER tg_kpi_value_lineage_touch BEFORE UPDATE ON ph16_kpi.kpi_value_lineage FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_value_lineage_append_only BEFORE UPDATE OR DELETE ON ph16_kpi.kpi_value_lineage FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_append_only();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_value_lineage');
COMMENT ON TABLE ph16_kpi.kpi_value_lineage IS 'EN-16-16 Dòng truy nguồn: mỗi biến công thức dùng cho một giá trị chỉ tiêu trỏ tới quan sát, số liệu nhập tay hoặc chỉ tiêu khác, kèm giá trị đã dùng (FR-16-019, 039). Chỉ thêm; phân vùng tháng theo `period_start`; tham chiếu tới giá trị và quan sát là logic vì bảng đích phân vùng.';
COMMENT ON COLUMN ph16_kpi.kpi_value_lineage.value_id IS 'Giá trị chỉ tiêu `kpi_indicator_value.id` (tham chiếu logic, bảng đích phân vùng).';
COMMENT ON COLUMN ph16_kpi.kpi_value_lineage.observation_id IS 'Quan sát `kpi_observation.id` (tham chiếu logic, bảng đích phân vùng).';
COMMENT ON COLUMN ph16_kpi.kpi_value_lineage.ref_value_id IS 'Giá trị chỉ tiêu của kỳ con (tháng) dùng để gộp lên kỳ quý, năm (tham chiếu logic).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_value_lineage CASCADE;

--changeset ph16:ph16-0260-kpi-group-score
CREATE TABLE ph16_kpi.kpi_group_score (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  period_id            uuid NOT NULL,
  run_id               uuid NOT NULL,
  group_code           varchar(16) NOT NULL,
  score                numeric(6,2),
  weight               numeric(5,2) NOT NULL,
  indicator_total      smallint NOT NULL,
  indicator_with_value smallint NOT NULL,
  completeness         varchar(9) NOT NULL,
  delta                numeric(6,2),
  trend                varchar(8),
  is_current           boolean NOT NULL DEFAULT true,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_group_score PRIMARY KEY (id),
  CONSTRAINT ck_kpi_group_score_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_group_score_run UNIQUE (tenant_id, run_id, group_code),
  CONSTRAINT fk_kpi_group_score_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT fk_kpi_group_score_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph16_kpi.kpi_aggregation_run (tenant_id, id),
  CONSTRAINT fk_kpi_group_score_group FOREIGN KEY (tenant_id, group_code) REFERENCES ph16_kpi.kpi_indicator_group (tenant_id, group_code),
  CONSTRAINT ck_kpi_group_score_score CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  CONSTRAINT ck_kpi_group_score_weight CHECK (weight >= 0 AND weight <= 100),
  CONSTRAINT ck_kpi_group_score_counts CHECK (indicator_total >= 0 AND indicator_with_value >= 0 AND indicator_with_value <= indicator_total),
  CONSTRAINT ck_kpi_group_score_completeness CHECK (completeness IN ('COMPLETE', 'PARTIAL', 'NO_DATA')),
  CONSTRAINT ck_kpi_group_score_complete CHECK ((completeness = 'COMPLETE') = (indicator_with_value = indicator_total AND indicator_total > 0) AND (completeness = 'NO_DATA') = (score IS NULL)),
  CONSTRAINT ck_kpi_group_score_trend CHECK (trend IS NULL OR trend IN ('UP', 'DOWN', 'FLAT'))
);
CREATE UNIQUE INDEX uq_kpi_group_score_current ON ph16_kpi.kpi_group_score (tenant_id, period_id, group_code) WHERE is_current;
CREATE INDEX ix_kpi_group_score_series ON ph16_kpi.kpi_group_score (tenant_id, group_code, period_id) WHERE is_current;
CREATE TRIGGER tg_kpi_group_score_touch BEFORE UPDATE ON ph16_kpi.kpi_group_score FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_group_score_immutable BEFORE UPDATE ON ph16_kpi.kpi_group_score FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'period_id', 'run_id', 'group_code');
CREATE TRIGGER tg_kpi_group_score_period BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_group_score FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_period_open();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_group_score');
COMMENT ON TABLE ph16_kpi.kpi_group_score IS 'EN-16-17 Điểm nhóm theo kỳ và lần tổng hợp: điểm 0…100 từ các chỉ tiêu của nhóm theo trọng số, số chỉ tiêu có số, độ đầy đủ, xu hướng và chênh lệch so kỳ trước (FR-16-007, 022, 038). Kỳ CLOSED không nhận điểm mới.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_group_score CASCADE;
