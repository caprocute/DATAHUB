--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0050-saga.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0500-saga-log
CREATE TABLE ph11_bpm.saga_log (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  instance_id      uuid NOT NULL,
  trigger          varchar(16) NOT NULL DEFAULT 'STEP_FAILURE',
  failed_element   varchar(100),
  error_code       varchar(32),
  status           varchar(10) NOT NULL DEFAULT 'RUNNING',
  total_steps      smallint NOT NULL DEFAULT 0,
  done_steps       smallint NOT NULL DEFAULT 0,
  failed_steps     smallint NOT NULL DEFAULT 0,
  started_at       timestamptz NOT NULL DEFAULT now(),
  ended_at         timestamptz,
  reconcile_state  varchar(8) NOT NULL DEFAULT 'NONE',
  reconciled_at    timestamptz,
  reconcile_note   varchar(2000),
  trace_id         char(32) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_log PRIMARY KEY (id),
  CONSTRAINT uq_saga_log_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_saga_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_log_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_saga_log_trigger CHECK (trigger IN ('STEP_FAILURE', 'INSTANCE_CANCEL', 'MANUAL')),
  CONSTRAINT ck_saga_log_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED')),
  CONSTRAINT ck_saga_log_ended CHECK ((status = 'RUNNING') = (ended_at IS NULL)),
  CONSTRAINT ck_saga_log_counts CHECK (total_steps >= 0 AND done_steps >= 0 AND failed_steps >= 0 AND done_steps + failed_steps <= total_steps),
  CONSTRAINT ck_saga_log_reconcile CHECK (reconcile_state IN ('NONE', 'PENDING', 'MATCHED', 'MISMATCH')),
  CONSTRAINT ck_saga_log_reconciled CHECK ((reconcile_state IN ('MATCHED', 'MISMATCH')) = (reconciled_at IS NOT NULL)),
  CONSTRAINT ck_saga_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE UNIQUE INDEX uq_saga_log_running ON ph11_bpm.saga_log (tenant_id, instance_id) WHERE status = 'RUNNING';
CREATE INDEX ix_saga_log_instance ON ph11_bpm.saga_log (tenant_id, instance_id, started_at DESC);
CREATE INDEX ix_saga_log_status ON ph11_bpm.saga_log (tenant_id, status, started_at DESC);
CREATE INDEX ix_saga_log_reconcile ON ph11_bpm.saga_log (tenant_id, reconcile_state) WHERE reconcile_state IN ('PENDING', 'MISMATCH');
CREATE TRIGGER tg_saga_log_touch BEFORE UPDATE ON ph11_bpm.saga_log FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_log_immutable BEFORE UPDATE ON ph11_bpm.saga_log FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'trigger', 'failed_element', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_log', 'P');
COMMENT ON TABLE ph11_bpm.saga_log IS 'EN-11-16 Nhật ký Saga bù trừ của một phiên (FR-11-051…054, ADR 113). Mỗi lần kích hoạt bù trừ (lỗi bước, hủy phiên, thủ công) một dòng; mỗi phiên tối đa một Saga RUNNING. PARTIAL là còn bước xử lý thủ công. Là bằng chứng đối soát khi cơ quan đã ghi nhận giao dịch: không xóa (quyền), giữ tối thiểu 5 năm (BR-11-025). Đối soát định kỳ đặt reconcile_state.';
COMMENT ON COLUMN ph11_bpm.saga_log.trigger IS 'CompensationTrigger: STEP_FAILURE bước lỗi không thử lại được; INSTANCE_CANCEL hủy phiên kèm bù trừ (FR-11-024); MANUAL do TA, TO kích hoạt (PERM-11-compensate).';
COMMENT ON COLUMN ph11_bpm.saga_log.failed_element IS 'Id phần tử BPMN gây lỗi (API failedElementId); rỗng với INSTANCE_CANCEL, MANUAL.';
COMMENT ON COLUMN ph11_bpm.saga_log.error_code IS 'Mã lỗi của bước gây Saga (ERR-11-xxx hoặc mã lỗi nghiệp vụ của ý định).';
COMMENT ON COLUMN ph11_bpm.saga_log.reconcile_state IS 'Đối soát với hệ thống đích (FR-11-054): NONE chưa cần, PENDING chờ, MATCHED khớp, MISMATCH lệch cần xử lý.';
--rollback DROP TABLE IF EXISTS ph11_bpm.saga_log CASCADE;

--changeset ph11:ph11-0510-saga-step
CREATE TABLE ph11_bpm.saga_step (
  id                       uuid NOT NULL,
  tenant_id                varchar(16) NOT NULL,
  saga_id                  uuid NOT NULL,
  seq                      smallint NOT NULL,
  forward_element_id       varchar(100) NOT NULL,
  compensation_intent_code varchar(64),
  policy                   varchar(16) NOT NULL,
  command_id               uuid,
  attempt                  smallint NOT NULL DEFAULT 0,
  status                   varchar(8) NOT NULL DEFAULT 'PENDING',
  response_code            varchar(32),
  evidence                 varchar(2000),
  resolved_by              varchar(64),
  last_error               varchar(2000),
  started_at               timestamptz,
  ended_at                 timestamptz,
  created_at               timestamptz NOT NULL DEFAULT now(),
  created_by               varchar(64) NOT NULL,
  updated_at               timestamptz NOT NULL DEFAULT now(),
  updated_by               varchar(64) NOT NULL,
  version                  integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_step PRIMARY KEY (id),
  CONSTRAINT uq_saga_step_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_saga_step_seq UNIQUE (tenant_id, saga_id, seq),
  CONSTRAINT ck_saga_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_step_saga FOREIGN KEY (tenant_id, saga_id) REFERENCES ph11_bpm.saga_log (tenant_id, id),
  CONSTRAINT ck_saga_step_policy CHECK (policy IN ('AUTO', 'MANUAL', 'NONE_APPROVED')),
  CONSTRAINT ck_saga_step_status CHECK (status IN ('PENDING', 'RUNNING', 'DONE', 'FAILED', 'MANUAL', 'SKIPPED')),
  CONSTRAINT ck_saga_step_seq CHECK (seq >= 1),
  CONSTRAINT ck_saga_step_attempt CHECK (attempt BETWEEN 0 AND 20),
  CONSTRAINT ck_saga_step_ended CHECK ((status IN ('DONE', 'FAILED', 'SKIPPED')) = (ended_at IS NOT NULL)),
  CONSTRAINT ck_saga_step_failed CHECK (status <> 'FAILED' OR last_error IS NOT NULL),
  CONSTRAINT ck_saga_step_manual CHECK (resolved_by IS NULL OR char_length(evidence) >= 20),
  CONSTRAINT ck_saga_step_skipped CHECK (status <> 'SKIPPED' OR policy = 'NONE_APPROVED' OR resolved_by IS NOT NULL),
  CONSTRAINT ck_saga_step_auto CHECK (policy <> 'AUTO' OR compensation_intent_code IS NOT NULL)
);
CREATE INDEX ix_saga_step_saga ON ph11_bpm.saga_step (tenant_id, saga_id, seq);
CREATE INDEX ix_saga_step_open ON ph11_bpm.saga_step (tenant_id, status) WHERE status IN ('RUNNING', 'FAILED', 'MANUAL');
CREATE UNIQUE INDEX uq_saga_step_command ON ph11_bpm.saga_step (tenant_id, command_id) WHERE command_id IS NOT NULL;
CREATE TRIGGER tg_saga_step_touch BEFORE UPDATE ON ph11_bpm.saga_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_step_immutable BEFORE UPDATE ON ph11_bpm.saga_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('saga_id', 'seq', 'forward_element_id', 'policy', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_step', 'P');
COMMENT ON TABLE ph11_bpm.saga_step IS 'EN-11-17 Bước bù trừ của một Saga, chạy ngược thứ tự hoàn thành (FR-11-051…053, BR-11-011). DONE chỉ sau khi ghi nhật ký (BR-11-013); MANUAL chờ xử lý tay và tạo việc MANUAL_COMPENSATION. Bước thủ công hoàn tất hoặc bỏ qua cần người xử lý và bằng chứng từ 20 ký tự, trừ policy NONE_APPROVED (đã được duyệt khi phát hành). Là bằng chứng đối soát: không xóa (quyền), giữ tối thiểu 5 năm.';
COMMENT ON COLUMN ph11_bpm.saga_step.seq IS 'Thứ tự thực hiện bù trừ, 1 là bước đầu tiên được bù trừ (bước xuôi hoàn thành gần nhất).';
COMMENT ON COLUMN ph11_bpm.saga_step.policy IS 'CompensationPolicy chụp từ compensation_action lúc kích hoạt Saga, để nhật ký không đổi dù cấu hình sau này đổi.';
COMMENT ON COLUMN ph11_bpm.saga_step.command_id IS 'Mã lệnh bù trừ gửi PH-04 (service.requested); kết quả tương quan theo mã này.';
COMMENT ON COLUMN ph11_bpm.saga_step.attempt IS 'Số lượt thử bù trừ đã chạy (tối đa 11.saga.maxRetries cộng lượt đầu).';
COMMENT ON COLUMN ph11_bpm.saga_step.response_code IS 'Mã phản hồi của hệ thống đích cho lệnh bù trừ.';
COMMENT ON COLUMN ph11_bpm.saga_step.evidence IS 'Bằng chứng bù trừ: mô tả, số văn bản, tham chiếu tệp; với xử lý tay hoặc bỏ qua là lý do và bằng chứng từ 20 ký tự (API-11-… ManualResolveBody, SkipBody).';
COMMENT ON COLUMN ph11_bpm.saga_step.resolved_by IS 'Người xử lý tay hoặc bỏ qua bước.';
COMMENT ON COLUMN ph11_bpm.saga_step.last_error IS 'Lỗi gần nhất của lượt thử (đã lược dữ liệu cá nhân); bắt buộc khi FAILED.';
--rollback DROP TABLE IF EXISTS ph11_bpm.saga_step CASCADE;
