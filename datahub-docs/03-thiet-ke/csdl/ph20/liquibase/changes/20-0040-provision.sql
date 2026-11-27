--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0040-provision.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0260-provisioning-run
CREATE TABLE ph20_tenant.provisioning_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_kind               varchar(16)    NOT NULL DEFAULT 'INITIAL',
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  template_id            uuid,
  isolation_mode         varchar(24)    NOT NULL DEFAULT 'SHARED',
  attempt                integer        NOT NULL DEFAULT 1,
  current_step_code      varchar(20),
  started_at             timestamptz,
  finished_at            timestamptz,
  duration_seconds       integer,
  error_code             varchar(16),
  error_message          varchar(1000),
  requested_by           varchar(64)    NOT NULL,
  trace_id               char(32),
  kpi_reported_at        timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_run PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_provisioning_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_provisioning_run_status CHECK (status IN ('PENDING', 'RUNNING', 'WAITING', 'FAILED', 'COMPENSATING', 'COMPENSATED', 'SUCCEEDED', 'CANCELLED')),
  CONSTRAINT ck_provisioning_run_run_kind CHECK (run_kind IN ('INITIAL', 'SUPPLEMENT', 'ISOLATION_CHANGE')),
  CONSTRAINT ck_provisioning_run_isolation_mode CHECK (isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_provisioning_run_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_provisioning_run_step CHECK (current_step_code IS NULL OR current_step_code IN ('S01_RECORD', 'S02_CONFIG_REPO', 'S03_REALM', 'S04_SECRETS', 'S05_BUCKETS', 'S06_EVENTING', 'S07_DATABASE', 'S08_OBSERVABILITY', 'S09_GATEWAY', 'S10_INTEGRATION', 'S11_SEED_RDM', 'S12_SEED_MDM', 'S13_ORG_SEED', 'S14_KPI', 'S15_MODULES', 'S16_SMOKE', 'S17_ACTIVATE')),
  CONSTRAINT ck_provisioning_run_finished CHECK (status NOT IN ('SUCCEEDED', 'COMPENSATED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_provisioning_run_duration CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  CONSTRAINT ck_provisioning_run_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT fk_provisioning_run_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_provisioning_run_template FOREIGN KEY (template_id) REFERENCES ph20_tenant.provisioning_template (id)
);
CREATE UNIQUE INDEX uq_provisioning_run_active ON ph20_tenant.provisioning_run (tenant_id) WHERE status IN ('PENDING', 'RUNNING', 'WAITING', 'COMPENSATING');
CREATE INDEX ix_provisioning_run_tenant_started ON ph20_tenant.provisioning_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_provisioning_run_touch BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_run_immutable BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('run_kind');
CREATE TRIGGER tg_provisioning_run_transition BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"PENDING": ["RUNNING", "CANCELLED"], "RUNNING": ["WAITING", "FAILED", "COMPENSATING", "SUCCEEDED", "CANCELLED"], "WAITING": ["RUNNING", "FAILED", "COMPENSATING"], "FAILED": ["RUNNING", "COMPENSATING", "CANCELLED"], "COMPENSATING": ["COMPENSATED", "FAILED"]}');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_run', 'CTL');
COMMENT ON TABLE ph20_tenant.provisioning_run IS 'EN-20-10 Lần chạy saga (FR-20-008…011, 016, 017): khởi tạo ban đầu, khởi tạo bổ sung, đổi chế độ cách ly. Mỗi tenant tối đa một lần chạy đang hoạt động (PENDING, RUNNING, WAITING, COMPENSATING). Saga điều phối trên PostgreSQL (ADR 200), có khóa ShedLock ở dịch vụ.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.run_kind IS 'Loại lần chạy: `INITIAL`, `SUPPLEMENT`, `ISOLATION_CHANGE`.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.status IS 'Trạng thái: `PENDING`, `RUNNING`, `WAITING`, `FAILED`, `COMPENSATING`, `COMPENSATED`, `SUCCEEDED`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.template_id IS 'Phiên bản mẫu khởi tạo dùng cho lần chạy.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.isolation_mode IS 'Chế độ cách ly của lần chạy (quyết định bước S07).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.attempt IS 'Lần thử (tăng khi thử lại từ bước lỗi).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.current_step_code IS 'Bước đang chạy hoặc dừng ở lỗi.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.started_at IS 'Thời điểm bắt đầu.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.finished_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.duration_seconds IS 'Thời gian khởi tạo, giây (KPI-12, FR-20-014).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.error_code IS 'Mã lỗi `ERR-20-*` khi thất bại.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.error_message IS 'Thông điệp lỗi đã che dữ liệu nhạy cảm.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.requested_by IS 'Người, hoặc tài khoản dịch vụ, khởi chạy.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.trace_id IS 'Mã vết phân tán (W3C).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.kpi_reported_at IS 'Thời điểm đẩy thời gian khởi tạo sang PH-16 (API-16-030).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_run CASCADE;

--changeset ph20:ph20-0270-provisioning-step
CREATE TABLE ph20_tenant.provisioning_step (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_id                 uuid           NOT NULL,
  step_code              varchar(20)    NOT NULL,
  step_order             smallint       NOT NULL,
  status                 varchar(16)    NOT NULL DEFAULT 'PENDING',
  executor               varchar(16)    NOT NULL,
  is_async               boolean        NOT NULL DEFAULT false,
  attempt                integer        NOT NULL DEFAULT 1,
  idempotency_ref        varchar(64)    NOT NULL,
  started_at             timestamptz,
  reported_at            timestamptz,
  finished_at            timestamptz,
  timeout_at             timestamptz,
  error_code             varchar(16),
  error_message          varchar(1000),
  detail                 jsonb          NOT NULL DEFAULT '{}',
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_step PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_step_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_provisioning_step_step UNIQUE (run_id, step_code),
  CONSTRAINT ck_provisioning_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_provisioning_step_status CHECK (status IN ('PENDING', 'RUNNING', 'WAITING_REPORT', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'COMPENSATING', 'COMPENSATED')),
  CONSTRAINT ck_provisioning_step_code CHECK (step_code IN ('S01_RECORD', 'S02_CONFIG_REPO', 'S03_REALM', 'S04_SECRETS', 'S05_BUCKETS', 'S06_EVENTING', 'S07_DATABASE', 'S08_OBSERVABILITY', 'S09_GATEWAY', 'S10_INTEGRATION', 'S11_SEED_RDM', 'S12_SEED_MDM', 'S13_ORG_SEED', 'S14_KPI', 'S15_MODULES', 'S16_SMOKE', 'S17_ACTIVATE')),
  CONSTRAINT ck_provisioning_step_order CHECK (step_order BETWEEN 1 AND 17),
  CONSTRAINT ck_provisioning_step_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_provisioning_step_idem CHECK (idempotency_ref ~ '^[0-9a-f-]{36}:S[0-9]{2}_[A-Z_]+$'),
  CONSTRAINT ck_provisioning_step_detail CHECK (jsonb_typeof(detail) = 'object'),
  CONSTRAINT fk_provisioning_step_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_provisioning_step_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_provisioning_step_waiting ON ph20_tenant.provisioning_step (timeout_at) WHERE status = 'WAITING_REPORT';
CREATE INDEX ix_provisioning_step_fk_run ON ph20_tenant.provisioning_step (tenant_id, run_id);
CREATE TRIGGER tg_provisioning_step_touch BEFORE UPDATE ON ph20_tenant.provisioning_step FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_step_immutable BEFORE UPDATE ON ph20_tenant.provisioning_step FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('run_id', 'step_code', 'idempotency_ref');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_step', 'CTL');
COMMENT ON TABLE ph20_tenant.provisioning_step IS 'EN-20-11 Bước saga (FR-20-009, 010, 011): sổ bước của một lần chạy, 17 mã bước `S01_RECORD`…`S17_ACTIVATE`; bước bất đồng bộ chờ phân hệ báo qua `:report`. Lũy đẳng theo `idempotency_ref = {runId}:{stepCode}`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.run_id IS 'Lần chạy chứa bước.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.step_code IS 'Mã bước `S01_RECORD`…`S17_ACTIVATE` (brief mục 4.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.step_order IS 'Thứ tự thực hiện, 1 đến 17.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.status IS 'Trạng thái: `PENDING`, `RUNNING`, `WAITING_REPORT`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `COMPENSATING`, `COMPENSATED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.executor IS 'Bên thực hiện, ví dụ `PH-12`, `PH-20`, `PH-10`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.is_async IS 'Bước chờ phân hệ báo kết quả bất đồng bộ (S06, S09, S10, S12, S15).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.attempt IS 'Số lần thử của bước.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.idempotency_ref IS 'Khóa lũy đẳng `{runId}:{stepCode}` gửi cho bên thực hiện.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.started_at IS 'Thời điểm bắt đầu.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.reported_at IS 'Thời điểm bên thực hiện báo kết quả.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.finished_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.timeout_at IS 'Hạn chờ báo cáo (`20.provision.step-timeout-minutes`), quá hạn thì `FAILED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.error_message IS 'Thông điệp lỗi đã che dữ liệu nhạy cảm.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.detail IS 'Chi tiết kết quả (tên tài nguyên đã tạo, không chứa bí mật), dùng cho bù trừ.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_step CASCADE;

--changeset ph20:ph20-0280-smoke-test-result
CREATE TABLE ph20_tenant.smoke_test_result (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_id                 uuid           NOT NULL,
  check_code             varchar(24)    NOT NULL,
  result                 varchar(8)     NOT NULL,
  duration_ms            integer,
  detail                 jsonb          NOT NULL DEFAULT '{}',
  executed_at            timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_smoke_test_result PRIMARY KEY (id),
  CONSTRAINT uq_smoke_test_result_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_smoke_test_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_smoke_test_result_check_code CHECK (check_code IN ('LOGIN_ADMIN', 'API_SAMPLE', 'EVENT_SAMPLE', 'CROSS_TENANT_LEAK')),
  CONSTRAINT ck_smoke_test_result_result CHECK (result IN ('PASS', 'FAIL', 'SKIPPED')),
  CONSTRAINT ck_smoke_test_result_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CONSTRAINT ck_smoke_test_result_detail CHECK (jsonb_typeof(detail) = 'object'),
  CONSTRAINT fk_smoke_test_result_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_smoke_test_result_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id)
);
CREATE INDEX ix_smoke_test_result_executed ON ph20_tenant.smoke_test_result (tenant_id, executed_at DESC);
CREATE INDEX ix_smoke_test_result_fk_run ON ph20_tenant.smoke_test_result (tenant_id, run_id);
CREATE TRIGGER tg_smoke_test_result_touch BEFORE UPDATE ON ph20_tenant.smoke_test_result FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_smoke_test_result_append_only BEFORE UPDATE OR DELETE ON ph20_tenant.smoke_test_result FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_append_only();
CALL ph20_tenant.p_enable_rls('ph20_tenant.smoke_test_result', 'CTL');
COMMENT ON TABLE ph20_tenant.smoke_test_result IS 'EN-20-12 Kết quả kiểm tra khói (FR-20-012): đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo tenant (bước S16). Chỉ thêm; tenant chưa qua kiểm tra khói không được `ACTIVE`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.run_id IS 'Lần chạy saga.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.check_code IS 'Ca kiểm tra: `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.result IS 'Kết quả: `PASS`, `FAIL`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.duration_ms IS 'Thời gian chạy, mili giây.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.detail IS 'Chi tiết (mã trạng thái, thông điệp đã che).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.executed_at IS 'Thời điểm chạy.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.smoke_test_result CASCADE;
