--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0075-compliance.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0730-saga-skip-request
CREATE TABLE ph11_bpm.saga_skip_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  saga_id          uuid NOT NULL,
  step_id          uuid NOT NULL,
  reason           varchar(2000) NOT NULL,
  evidence         jsonb NOT NULL DEFAULT '[]',
  requested_by     varchar(64) NOT NULL,
  status           varchar(8) NOT NULL DEFAULT 'PENDING',
  task_id          uuid,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_saga_skip_request PRIMARY KEY (id),
  CONSTRAINT uq_saga_skip_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_saga_skip_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_saga_skip_request_saga FOREIGN KEY (tenant_id, saga_id) REFERENCES ph11_bpm.saga_log (tenant_id, id),
  CONSTRAINT fk_saga_skip_request_step FOREIGN KEY (tenant_id, step_id) REFERENCES ph11_bpm.saga_step (tenant_id, id),
  CONSTRAINT fk_saga_skip_request_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT ck_saga_skip_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  CONSTRAINT ck_saga_skip_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_saga_skip_request_evidence CHECK (jsonb_typeof(evidence) = 'array'),
  CONSTRAINT ck_saga_skip_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_saga_skip_request_decided CHECK ((status = 'PENDING') = (decided_by IS NULL AND decided_at IS NULL)),
  CONSTRAINT ck_saga_skip_request_reject CHECK (status <> 'REJECTED' OR char_length(decision_comment) >= 20)
);
CREATE UNIQUE INDEX uq_saga_skip_request_pending ON ph11_bpm.saga_skip_request (tenant_id, step_id) WHERE status = 'PENDING';
CREATE INDEX ix_saga_skip_request_step ON ph11_bpm.saga_skip_request (tenant_id, step_id, created_at DESC);
CREATE INDEX ix_saga_skip_request_open ON ph11_bpm.saga_skip_request (tenant_id, created_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_saga_skip_request_touch BEFORE UPDATE ON ph11_bpm.saga_skip_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_saga_skip_request_immutable BEFORE UPDATE ON ph11_bpm.saga_skip_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('saga_id', 'step_id', 'reason', 'evidence', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.saga_skip_request', 'P');
COMMENT ON TABLE ph11_bpm.saga_skip_request IS 'Ngoài FRS, đề nghị EN-11-29. Đề nghị bỏ qua một bước bù trừ thủ công (FR-11-053, API-11-101, 132, 133). Bốn mắt (BR-11-012, ERR-11-005): người duyệt hoặc từ chối khác người đề nghị. Bước saga_step vẫn MANUAL đến khi được duyệt (thành SKIPPED, resolved_by là người duyệt); từ chối đưa bước về MANUAL. Mỗi bước tối đa một đề nghị PENDING; đề nghị bị từ chối giữ lại làm bằng chứng. Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.step_id IS 'Bước bù trừ được đề nghị bỏ qua; cùng saga_id tạo khóa ngoại tới saga_step, saga_log.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.reason IS 'Lý do đề nghị (API SkipBody.reason), từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.evidence IS 'Mảng bằng chứng, mỗi phần tử {note, docNumber, objectRef, confirmedBy} (API ManualEvidence); tệp ở Ceph RGW, chỉ lưu tham chiếu.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.requested_by IS 'Người đề nghị (TA hoặc TO có PERM-11-compensate); không được tự duyệt.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.status IS 'SkipRequestStatus: PENDING chờ duyệt, APPROVED đã duyệt (bước SKIPPED), REJECTED bị từ chối (bước về MANUAL).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.task_id IS 'Việc MANUAL_COMPENSATION giao cho TA khác để duyệt (API SkipRequested.taskId).';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.decided_by IS 'Người duyệt hoặc từ chối, khác requested_by.';
COMMENT ON COLUMN ph11_bpm.saga_skip_request.decision_comment IS 'Ý kiến người quyết định (API CommentBody, RejectBody); từ chối cần từ 20 ký tự (ERR-11-007).';
--rollback DROP TABLE IF EXISTS ph11_bpm.saga_skip_request CASCADE;

--changeset ph11:ph11-0740-legal-hold
CREATE TABLE ph11_bpm.legal_hold (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  business_key     varchar(100) NOT NULL,
  reason           varchar(2000) NOT NULL,
  hold_until       timestamptz,
  released_at      timestamptz,
  released_by      varchar(64),
  release_reason   varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_hold PRIMARY KEY (id),
  CONSTRAINT uq_legal_hold_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_hold_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legal_hold_key CHECK (char_length(business_key) >= 3),
  CONSTRAINT ck_legal_hold_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_legal_hold_until CHECK (hold_until IS NULL OR hold_until > created_at),
  CONSTRAINT ck_legal_hold_release CHECK ((released_at IS NULL) = (released_by IS NULL) AND (released_at IS NULL) = (release_reason IS NULL)),
  CONSTRAINT ck_legal_hold_release_reason CHECK (release_reason IS NULL OR char_length(release_reason) >= 10)
);
CREATE UNIQUE INDEX uq_legal_hold_active ON ph11_bpm.legal_hold (tenant_id, business_key) WHERE released_at IS NULL;
CREATE INDEX ix_legal_hold_key ON ph11_bpm.legal_hold (tenant_id, business_key, created_at DESC);
CREATE TRIGGER tg_legal_hold_touch BEFORE UPDATE ON ph11_bpm.legal_hold FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_legal_hold_immutable BEFORE UPDATE ON ph11_bpm.legal_hold FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('business_key', 'reason', 'hold_until', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.legal_hold', 'P');
COMMENT ON TABLE ph11_bpm.legal_hold IS 'Ngoài FRS, đề nghị EN-11-30. Giữ pháp lý theo mã hồ sơ (FR-11-054, 063, API-11-120, 134, 135, PERM-11-config): hồ sơ đang giữ không bị dọn lịch sử engine hay bản nghiệp vụ (ERR-11-047, BR-11-025) đến khi gỡ hoặc hết hold_until. Mỗi business_key tối đa một giữ đang hiệu lực; giữ đã gỡ giữ lại làm bằng chứng, không xóa (quyền). Không khóa ngoại tới instance_index vì giữ có thể đặt trước phiên.';
COMMENT ON COLUMN ph11_bpm.legal_hold.business_key IS 'Mã hồ sơ cần giữ (API businessKey, 3…100 ký tự), khớp instance_index.business_key; không chứa dữ liệu cá nhân.';
COMMENT ON COLUMN ph11_bpm.legal_hold.reason IS 'Căn cứ pháp lý (API reason), từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.legal_hold.hold_until IS 'Hạn giữ (API holdUntil); rỗng là giữ đến khi gỡ.';
COMMENT ON COLUMN ph11_bpm.legal_hold.released_at IS 'Thời điểm gỡ giữ (API releasedAt); rỗng là còn hiệu lực. Cùng released_by, release_reason: cả ba có hoặc cả ba rỗng.';
COMMENT ON COLUMN ph11_bpm.legal_hold.released_by IS 'Người gỡ giữ (API releasedBy).';
COMMENT ON COLUMN ph11_bpm.legal_hold.release_reason IS 'Lý do gỡ (API releaseReason, ReasonBody), từ 10 ký tự.';
--rollback DROP TABLE IF EXISTS ph11_bpm.legal_hold CASCADE;

--changeset ph11:ph11-0750-compliance-sample-run
CREATE TABLE ph11_bpm.compliance_sample_run (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  evidence_pack_id uuid NOT NULL,
  environment      varchar(8) NOT NULL,
  status           varchar(8) NOT NULL DEFAULT 'RUNNING',
  requested_by     varchar(64) NOT NULL,
  include_models   jsonb NOT NULL DEFAULT '[]',
  period_from      timestamptz,
  period_to        timestamptz,
  engine_instance_id varchar(64),
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  checksum         bytea,
  pack_ref         varchar(500),
  result           jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_sample_run PRIMARY KEY (id),
  CONSTRAINT uq_compliance_sample_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_compliance_sample_run_pack UNIQUE (tenant_id, evidence_pack_id),
  CONSTRAINT ck_compliance_sample_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_compliance_sample_run_env CHECK (environment IN ('TEST', 'STAGING')),
  CONSTRAINT ck_compliance_sample_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ABORTED')),
  CONSTRAINT ck_compliance_sample_run_models CHECK (jsonb_typeof(include_models) = 'array'),
  CONSTRAINT ck_compliance_sample_run_period CHECK ((period_from IS NULL) = (period_to IS NULL) AND (period_from IS NULL OR (period_to > period_from AND period_to - period_from <= interval '366 days'))),
  CONSTRAINT ck_compliance_sample_run_ended CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_compliance_sample_run_checksum CHECK (checksum IS NULL OR octet_length(checksum) = 32),
  CONSTRAINT ck_compliance_sample_run_pack CHECK (status NOT IN ('PASSED', 'FAILED') OR (checksum IS NOT NULL AND pack_ref IS NOT NULL)),
  CONSTRAINT ck_compliance_sample_run_result CHECK (result IS NULL OR jsonb_typeof(result) = 'object')
);
CREATE INDEX ix_compliance_sample_run_list ON ph11_bpm.compliance_sample_run (tenant_id, environment, started_at DESC);
CREATE TRIGGER tg_compliance_sample_run_touch BEFORE UPDATE ON ph11_bpm.compliance_sample_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_compliance_sample_run_immutable BEFORE UPDATE ON ph11_bpm.compliance_sample_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('evidence_pack_id', 'environment', 'requested_by', 'include_models', 'started_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.compliance_sample_run', 'P');
COMMENT ON TABLE ph11_bpm.compliance_sample_run IS 'Ngoài FRS, đề nghị EN-11-31. Lần chạy mẫu tuân thủ BPMN 2.0 và gói bằng chứng (FR-11-064, API-11-121, 122, 137): mô hình MAU_TUAN_THU_BPMN chạy trên TEST hoặc STAGING, gói PDF và JSON có băm lưu ở Ceph RGW. Khác test_run (chạy thử mô hình nháp). Khoảng thống kê tối đa 366 ngày (ERR-11-039). Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.evidence_pack_id IS 'Mã gói bằng chứng (API evidencePackId) dùng tải gói qua API-11-122; duy nhất trong tenant.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.environment IS 'Môi trường chạy mẫu (API environment). FR-11-064 chỉ nhận TEST, STAGING (Environment của FRS có thêm PROD).';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.status IS 'TestRunStatus: RUNNING đang chạy, PASSED đạt, FAILED chưa đạt, ABORTED dừng giữa chừng.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.include_models IS 'Mảng khóa mô hình thật đính kèm thống kê (API includeModels), mỗi phần tử theo mẫu process_key.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.period_from IS 'Đầu khoảng thống kê (API from); cùng period_to hoặc cả hai rỗng.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.engine_instance_id IS 'Mã phiên mẫu trong Flowable.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.checksum IS 'SHA-256 gói bằng chứng, đúng 32 byte (API checksum, dạng hex); bắt buộc khi PASSED, FAILED.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.pack_ref IS 'Khóa đối tượng của gói ở Ceph RGW; bắt buộc khi PASSED, FAILED.';
COMMENT ON COLUMN ph11_bpm.compliance_sample_run.result IS 'Biên bản chạy: phần tử BPMN 2.0 đã thực thi, phiên bản Flowable, lỗi khi FAILED.';
--rollback DROP TABLE IF EXISTS ph11_bpm.compliance_sample_run CASCADE;
