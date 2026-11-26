--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0020-instance.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0200-instance-index
CREATE TABLE ph11_bpm.instance_index (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  engine_instance_id    varchar(64) NOT NULL,
  process_key           varchar(64) NOT NULL,
  version_no            integer NOT NULL,
  business_key          varchar(100) NOT NULL,
  idempotency_key       varchar(120),
  status                varchar(16) NOT NULL DEFAULT 'RUNNING',
  wait_state            varchar(16) NOT NULL DEFAULT 'NONE',
  current_elements      jsonb NOT NULL DEFAULT '[]',
  start_channel         varchar(16) NOT NULL DEFAULT 'API',
  initiator             varchar(64) NOT NULL,
  client_id             varchar(64),
  parent_instance_id    uuid,
  due_at                timestamptz,
  trace_id              char(32) NOT NULL,
  started_at            timestamptz NOT NULL DEFAULT now(),
  ended_at              timestamptz,
  is_test               boolean NOT NULL DEFAULT false,
  suspended_at          timestamptz,
  status_reason         varchar(2000),
  progress_percent      smallint NOT NULL DEFAULT 0,
  progress_public       jsonb NOT NULL DEFAULT '{}',
  migrated_from_version integer,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_instance_index PRIMARY KEY (id),
  CONSTRAINT uq_instance_index_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_instance_index_engine UNIQUE (tenant_id, engine_instance_id),
  CONSTRAINT uq_instance_index_idempotency UNIQUE (tenant_id, idempotency_key),
  CONSTRAINT ck_instance_index_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_index_version FOREIGN KEY (tenant_id, process_key, version_no) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT fk_instance_index_parent FOREIGN KEY (tenant_id, parent_instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_index_status CHECK (status IN ('RUNNING', 'SUSPENDED', 'COMPENSATING', 'COMPLETED', 'CANCELLED', 'COMPENSATED', 'FAILED')),
  CONSTRAINT ck_instance_index_wait CHECK (wait_state IN ('NONE', 'WAITING_USER', 'WAITING_SERVICE', 'WAITING_MESSAGE', 'WAITING_TIMER')),
  CONSTRAINT ck_instance_index_channel CHECK (start_channel IN ('API', 'EVENT', 'MANUAL', 'CALL_ACTIVITY', 'TIMER', 'TEST')),
  CONSTRAINT ck_instance_index_test CHECK (is_test = (start_channel = 'TEST')),
  CONSTRAINT ck_instance_index_call CHECK ((start_channel = 'CALL_ACTIVITY') = (parent_instance_id IS NOT NULL)),
  CONSTRAINT ck_instance_index_ended CHECK ((status IN ('COMPLETED', 'CANCELLED', 'COMPENSATED', 'FAILED')) = (ended_at IS NOT NULL)),
  CONSTRAINT ck_instance_index_suspended CHECK (status <> 'SUSPENDED' OR suspended_at IS NOT NULL),
  CONSTRAINT ck_instance_index_reason CHECK (status NOT IN ('CANCELLED', 'FAILED') OR char_length(status_reason) >= 10),
  CONSTRAINT ck_instance_index_progress CHECK (progress_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_instance_index_elements CHECK (jsonb_typeof(current_elements) = 'array'),
  CONSTRAINT ck_instance_index_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_instance_index_migrated CHECK (migrated_from_version IS NULL OR migrated_from_version <> version_no)
);
CREATE UNIQUE INDEX uq_instance_index_live_key ON ph11_bpm.instance_index (tenant_id, process_key, business_key) WHERE status IN ('RUNNING', 'SUSPENDED', 'COMPENSATING') AND NOT is_test;
CREATE INDEX ix_instance_index_list ON ph11_bpm.instance_index (tenant_id, status, started_at DESC);
CREATE INDEX ix_instance_index_model ON ph11_bpm.instance_index (tenant_id, process_key, version_no, status);
CREATE INDEX ix_instance_index_bkey ON ph11_bpm.instance_index (tenant_id, business_key);
CREATE INDEX ix_instance_index_parent ON ph11_bpm.instance_index (tenant_id, parent_instance_id) WHERE parent_instance_id IS NOT NULL;
CREATE INDEX ix_instance_index_ended ON ph11_bpm.instance_index (ended_at) WHERE ended_at IS NOT NULL;
CREATE INDEX ix_instance_index_test ON ph11_bpm.instance_index (started_at) WHERE is_test;
CREATE TRIGGER tg_instance_index_touch BEFORE UPDATE ON ph11_bpm.instance_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_instance_index_immutable BEFORE UPDATE ON ph11_bpm.instance_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('engine_instance_id', 'process_key', 'business_key', 'start_channel', 'initiator', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_index', 'P');
COMMENT ON TABLE ph11_bpm.instance_index IS 'EN-11-08 Bản chiếu phiên quy trình để liệt kê, tìm kiếm, tra tiến độ có RLS (FR-11-018…027, 055). Nguồn sự thật là engine (engine_instance_id). Một business_key (mã hồ sơ) chỉ một phiên đang sống mỗi mô hình, trừ phiên chạy thử (BR-11-007); idempotency_key chỉ một phiên. Không lưu giá trị biến; progress_public chỉ chứa dữ liệu đã che (BR-11-015).';
COMMENT ON COLUMN ph11_bpm.instance_index.engine_instance_id IS 'Mã phiên trong Flowable (ACT_RU_EXECUTION.PROC_INST_ID_).';
COMMENT ON COLUMN ph11_bpm.instance_index.process_key IS 'Khóa mô hình, cùng version_no tạo khóa ngoại tới process_version.';
COMMENT ON COLUMN ph11_bpm.instance_index.business_key IS 'Mã hồ sơ do bên gọi cung cấp, 3…100 ký tự, không chứa dữ liệu cá nhân; API tiến độ tra theo khóa này (kênh DVC).';
COMMENT ON COLUMN ph11_bpm.instance_index.idempotency_key IS 'Idempotency-Key khi khởi tạo, hiệu lực 24 giờ (BR-11-007): dịch vụ đặt NULL sau 24 giờ; trong cửa sổ, gọi lại trả phiên cũ (FR-11-018).';
COMMENT ON COLUMN ph11_bpm.instance_index.wait_state IS 'Trạng thái chờ (WaitState): NONE, WAITING_USER, WAITING_SERVICE, WAITING_MESSAGE, WAITING_TIMER.';
COMMENT ON COLUMN ph11_bpm.instance_index.current_elements IS 'Mảng id các phần tử BPMN đang chờ (API currentElements); cập nhật theo sự kiện của engine.';
COMMENT ON COLUMN ph11_bpm.instance_index.start_channel IS 'Kênh khởi tạo (StartChannel): API, EVENT, MANUAL, CALL_ACTIVITY (có parent_instance_id), TIMER, TEST (phiên chạy thử, is_test).';
COMMENT ON COLUMN ph11_bpm.instance_index.initiator IS 'Người hoặc tài khoản máy khởi tạo (PH-12).';
COMMENT ON COLUMN ph11_bpm.instance_index.client_id IS 'client_id OAuth của HTTT gọi khởi tạo (PH-01, PH-12), rỗng khi khởi tạo thủ công; dùng cho hạn mức 11.instance.startRatePerClient.';
COMMENT ON COLUMN ph11_bpm.instance_index.due_at IS 'Hạn của phiên, chép từ due_tracking để lọc và sắp xếp danh sách (FR-11-021).';
COMMENT ON COLUMN ph11_bpm.instance_index.status_reason IS 'Lý do hủy, tạm dừng hoặc thất bại; bắt buộc từ 10 ký tự khi CANCELLED, FAILED.';
COMMENT ON COLUMN ph11_bpm.instance_index.progress_percent IS 'Ước lượng phần trăm tiến độ cho kênh DVC (API percentEstimate).';
COMMENT ON COLUMN ph11_bpm.instance_index.progress_public IS 'Tiến độ hiển thị cho kênh DVC (publicName, trạng thái công khai), đã che dữ liệu RESTRICTED, SENSITIVE (BR-11-015, FR-11-055).';
COMMENT ON COLUMN ph11_bpm.instance_index.migrated_from_version IS 'Số phiên bản mô hình trước khi di trú (FR-11-026); rỗng nếu chưa di trú.';
--rollback DROP TABLE IF EXISTS ph11_bpm.instance_index CASCADE;

--changeset ph11:ph11-0210-instance-step
CREATE TABLE ph11_bpm.instance_step (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  started_at   timestamptz NOT NULL DEFAULT now(),
  instance_id  uuid NOT NULL,
  element_id   varchar(100) NOT NULL,
  element_name varchar(255),
  step_type    varchar(24) NOT NULL,
  status       varchar(12) NOT NULL DEFAULT 'ACTIVE',
  ended_at     timestamptz,
  duration_ms  bigint,
  actor        varchar(64),
  result_code  varchar(32),
  summary      jsonb NOT NULL DEFAULT '{}',
  trace_id     char(32) NOT NULL,
  CONSTRAINT pk_instance_step PRIMARY KEY (id, started_at),
  CONSTRAINT ck_instance_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_step_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_step_type CHECK (step_type IN ('START_EVENT', 'END_EVENT', 'USER_TASK', 'SERVICE_TASK', 'SEND_TASK', 'BUSINESS_RULE_TASK', 'EXCLUSIVE_GATEWAY', 'PARALLEL_GATEWAY', 'INCLUSIVE_GATEWAY', 'EVENT_BASED_GATEWAY', 'TIMER_EVENT', 'MESSAGE_EVENT', 'COMPENSATION_THROW', 'TIMER_BOUNDARY', 'ERROR_BOUNDARY', 'COMPENSATION_BOUNDARY', 'MESSAGE_BOUNDARY', 'SUB_PROCESS', 'CALL_ACTIVITY')),
  CONSTRAINT ck_instance_step_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'FAILED', 'CANCELLED', 'COMPENSATED')),
  CONSTRAINT ck_instance_step_ended CHECK ((status = 'ACTIVE') = (ended_at IS NULL)),
  CONSTRAINT ck_instance_step_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CONSTRAINT ck_instance_step_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (started_at);
CALL ph11_bpm.p_ensure_partitions('ph11_bpm.instance_step', current_date, 3);
CREATE INDEX ix_instance_step_instance ON ph11_bpm.instance_step (tenant_id, instance_id, started_at);
CREATE INDEX ix_instance_step_element ON ph11_bpm.instance_step (tenant_id, element_id, started_at DESC);
CREATE TRIGGER tg_instance_step_immutable BEFORE UPDATE ON ph11_bpm.instance_step FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'element_id', 'step_type', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_step', 'P');
COMMENT ON TABLE ph11_bpm.instance_step IS 'EN-11-28 Lịch sử bước của phiên (FR-11-022, 056, 057, 059, 064), giữ 5 năm, phân vùng tháng. Mỗi lần vào một phần tử BPMN một dòng, cập nhật khi ra. Là bằng chứng kiểm toán, nguồn dòng thời gian và tiến độ. Không chứa giá trị biến (summary đã che).';
COMMENT ON COLUMN ph11_bpm.instance_step.element_id IS 'Id phần tử trong BPMN.';
COMMENT ON COLUMN ph11_bpm.instance_step.step_type IS 'Loại phần tử BPMN (StepType, bảng 6.2-a của FRS).';
COMMENT ON COLUMN ph11_bpm.instance_step.actor IS 'Người xử lý với bước việc, rỗng với bước hệ thống.';
COMMENT ON COLUMN ph11_bpm.instance_step.result_code IS 'Kết quả ngắn: quyết định của việc (Decision), mã lỗi của service task.';
COMMENT ON COLUMN ph11_bpm.instance_step.summary IS 'Tóm tắt đã che dữ liệu cá nhân (không chứa giá trị biến RESTRICTED, SENSITIVE).';
--rollback DROP TABLE IF EXISTS ph11_bpm.instance_step CASCADE;

--changeset ph11:ph11-0220-service-call
CREATE TABLE ph11_bpm.service_call (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  command_id    uuid NOT NULL,
  instance_id   uuid NOT NULL,
  element_id    varchar(100) NOT NULL,
  intent_code   varchar(64) NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'REQUESTED',
  attempt       smallint NOT NULL DEFAULT 1,
  requested_at  timestamptz NOT NULL DEFAULT now(),
  timeout_at    timestamptz NOT NULL,
  completed_at  timestamptz,
  output_ref    varchar(255),
  error_kind    varchar(12),
  error_code    varchar(64),
  error_message varchar(2000),
  trace_id      char(32) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_call PRIMARY KEY (id),
  CONSTRAINT uq_service_call_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_service_call_command UNIQUE (tenant_id, command_id),
  CONSTRAINT ck_service_call_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_service_call_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT fk_service_call_intent FOREIGN KEY (tenant_id, intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT ck_service_call_status CHECK (status IN ('REQUESTED', 'COMPLETED', 'FAILED', 'TIMED_OUT', 'CANCELLED')),
  CONSTRAINT ck_service_call_kind CHECK (error_kind IS NULL OR error_kind IN ('BUSINESS', 'TECHNICAL')),
  CONSTRAINT ck_service_call_attempt CHECK (attempt BETWEEN 1 AND 100),
  CONSTRAINT ck_service_call_done CHECK ((status = 'REQUESTED') = (completed_at IS NULL)),
  CONSTRAINT ck_service_call_error CHECK (status <> 'FAILED' OR (error_kind IS NOT NULL AND error_code IS NOT NULL)),
  CONSTRAINT ck_service_call_timeout CHECK (status <> 'TIMED_OUT' OR error_code IS NOT NULL),
  CONSTRAINT ck_service_call_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_service_call_instance ON ph11_bpm.service_call (tenant_id, instance_id, element_id, requested_at);
CREATE INDEX ix_service_call_timeout ON ph11_bpm.service_call (timeout_at) WHERE status = 'REQUESTED';
CREATE TRIGGER tg_service_call_touch BEFORE UPDATE ON ph11_bpm.service_call FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_service_call_immutable BEFORE UPDATE ON ph11_bpm.service_call FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'element_id', 'intent_code', 'command_id', 'requested_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.service_call', 'P');
COMMENT ON TABLE ph11_bpm.service_call IS 'EN-11-25 Lệnh service task đã gửi tới PH-04 và kết quả nhận về (FR-11-028, 029, 060). Mỗi lệnh một dòng theo command_id (UUID v5 xác định theo tenant, processInstanceId, executionId, activityId, lần giao lệnh; BR-11-022); gửi lại cùng command_id thì tăng attempt, PH-04 chống trùng theo command_id. Kết quả từ {tenant}.bpm.service.completed.v1 hoặc .failed.v1 (EVT-11-18, 19) tương quan theo command_id; quá timeout_at thì tác vụ nền chuyển TIMED_OUT và mở sự cố SERVICE_TIMEOUT (ADR 112).';
COMMENT ON COLUMN ph11_bpm.service_call.command_id IS 'Mã lệnh (UUID) mang trong sự kiện service.requested và kết quả trả về; khóa tương quan, bảo đảm xử lý kết quả một lần.';
COMMENT ON COLUMN ph11_bpm.service_call.status IS 'ServiceCallStatus: REQUESTED, COMPLETED, FAILED (lỗi nghiệp vụ hoặc kỹ thuật), TIMED_OUT, CANCELLED.';
COMMENT ON COLUMN ph11_bpm.service_call.attempt IS 'Số lần gửi cùng command_id; tăng khi vận hành bấm gửi lại (FR-11-028).';
COMMENT ON COLUMN ph11_bpm.service_call.timeout_at IS 'Hạn chờ kết quả = requested_at + thời gian chờ của ý định hoặc 11.service.defaultTimeoutMinutes.';
COMMENT ON COLUMN ph11_bpm.service_call.output_ref IS 'Tham chiếu tới kết quả đã ghi vào biến phiên (tên biến hoặc bpm-secret); không chứa giá trị. Kết quả đầy đủ chỉ nằm ở biến quy trình trong engine.';
COMMENT ON COLUMN ph11_bpm.service_call.error_kind IS 'ErrorKind: BUSINESS (đi nhánh lỗi, Saga) hoặc TECHNICAL (thử lại, mở sự cố); bắt buộc khi FAILED.';
COMMENT ON COLUMN ph11_bpm.service_call.error_message IS 'Thông điệp lỗi đã lược dữ liệu cá nhân.';
--rollback DROP TABLE IF EXISTS ph11_bpm.service_call CASCADE;

--changeset ph11:ph11-0230-instance-change
CREATE TABLE ph11_bpm.instance_change (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  instance_id  uuid NOT NULL,
  type         varchar(16) NOT NULL,
  payload      jsonb NOT NULL DEFAULT '{}',
  reason       varchar(2000) NOT NULL,
  status       varchar(8) NOT NULL DEFAULT 'PENDING',
  requested_by varchar(64) NOT NULL,
  approved_by  varchar(64),
  applied_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_instance_change PRIMARY KEY (id),
  CONSTRAINT uq_instance_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_instance_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_instance_change_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_instance_change_type CHECK (type IN ('VARIABLE_UPDATE', 'MOVE_TOKEN')),
  CONSTRAINT ck_instance_change_status CHECK (status IN ('PENDING', 'APPLIED', 'REJECTED')),
  CONSTRAINT ck_instance_change_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_instance_change_reason CHECK (char_length(reason) >= CASE type WHEN 'MOVE_TOKEN' THEN 30 ELSE 20 END),
  CONSTRAINT ck_instance_change_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_instance_change_decided CHECK ((status = 'PENDING') = (approved_by IS NULL)),
  CONSTRAINT ck_instance_change_applied CHECK ((status = 'APPLIED') = (applied_at IS NOT NULL))
);
CREATE INDEX ix_instance_change_instance ON ph11_bpm.instance_change (tenant_id, instance_id, created_at DESC);
CREATE INDEX ix_instance_change_pending ON ph11_bpm.instance_change (tenant_id, created_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_instance_change_touch BEFORE UPDATE ON ph11_bpm.instance_change FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_instance_change_immutable BEFORE UPDATE ON ph11_bpm.instance_change FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'type', 'payload', 'reason', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.instance_change', 'P');
COMMENT ON TABLE ph11_bpm.instance_change IS 'EN-11-27 Đề nghị can thiệp phiên đang chạy: sửa biến (VARIABLE_UPDATE, FR-11-025) hoặc chuyển bước (MOVE_TOKEN, FR-11-027), API-11-059…062. Bốn mắt (BR-11-021): người duyệt khác người đề nghị; lý do từ 20 ký tự, chuyển bước từ 30. approved_by ghi người quyết định, kể cả khi REJECTED. Là bằng chứng kiểm toán: không xóa (quyền), giữ 5 năm sau khi phiên kết thúc.';
COMMENT ON COLUMN ph11_bpm.instance_change.type IS 'ChangeType: VARIABLE_UPDATE hoặc MOVE_TOKEN.';
COMMENT ON COLUMN ph11_bpm.instance_change.payload IS 'VARIABLE_UPDATE: danh sách {name, giá trị mới}, biến SENSITIVE chỉ ghi tham chiếu bpm-secret, không ghi giá trị rõ (BR-11-014); MOVE_TOKEN: fromElementIds, toElementId, skipCompensation.';
COMMENT ON COLUMN ph11_bpm.instance_change.status IS 'ChangeStatus: PENDING chờ duyệt, APPLIED đã áp dụng vào engine, REJECTED bị từ chối.';
COMMENT ON COLUMN ph11_bpm.instance_change.approved_by IS 'Người quyết định (duyệt hoặc từ chối), khác requested_by.';
--rollback DROP TABLE IF EXISTS ph11_bpm.instance_change CASCADE;
