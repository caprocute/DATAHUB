--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0060-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0600-incident
CREATE TABLE ph11_bpm.incident (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  type          varchar(24) NOT NULL,
  instance_id   uuid,
  element_id    varchar(100),
  job_id        varchar(64),
  message       varchar(2000),
  error_code    varchar(32),
  retries_done  smallint NOT NULL DEFAULT 0,
  trace_id      char(32) NOT NULL,
  status        varchar(8) NOT NULL DEFAULT 'OPEN',
  opened_at     timestamptz NOT NULL DEFAULT now(),
  resolved_at   timestamptz,
  handled_by    varchar(64),
  reason        varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident PRIMARY KEY (id),
  CONSTRAINT ck_incident_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_incident_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_incident_type CHECK (type IN ('JOB_FAILED', 'SERVICE_TIMEOUT', 'CORRELATION_FAILED', 'TIMER_FAILED', 'COMPENSATION_FAILED', 'STUCK_INSTANCE', 'ENGINE_ERROR', 'SUPPLEMENT_EXPIRED')),
  CONSTRAINT ck_incident_status CHECK (status IN ('OPEN', 'RETRYING', 'RESOLVED', 'IGNORED')),
  CONSTRAINT ck_incident_resolved CHECK ((status IN ('RESOLVED', 'IGNORED')) = (resolved_at IS NOT NULL AND handled_by IS NOT NULL)),
  CONSTRAINT ck_incident_reason CHECK (status <> 'IGNORED' OR char_length(reason) >= 20),
  CONSTRAINT ck_incident_retries CHECK (retries_done >= 0),
  CONSTRAINT ck_incident_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE UNIQUE INDEX uq_incident_open_job ON ph11_bpm.incident (tenant_id, job_id) WHERE job_id IS NOT NULL AND status IN ('OPEN', 'RETRYING');
CREATE INDEX ix_incident_status ON ph11_bpm.incident (tenant_id, status, type, opened_at DESC);
CREATE INDEX ix_incident_instance ON ph11_bpm.incident (tenant_id, instance_id) WHERE instance_id IS NOT NULL;
CREATE TRIGGER tg_incident_touch BEFORE UPDATE ON ph11_bpm.incident FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_incident_immutable BEFORE UPDATE ON ph11_bpm.incident FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('instance_id', 'type', 'job_id', 'opened_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.incident', 'P');
COMMENT ON TABLE ph11_bpm.incident IS 'EN-11-18 Sự cố engine và việc lỗi (FR-11-060, 061): job Flowable hết lần thử, service task hết hạn, thông điệp không tương quan được, hẹn giờ lỗi, bù trừ thất bại, phiên tắc, lỗi engine (IncidentType). Trạng thái IncidentStatus OPEN, RETRYING, RESOLVED, IGNORED; bỏ qua phải ghi lý do từ 20 ký tự. Một job lỗi chỉ một sự cố đang mở. Đẩy sự kiện EVT-11-16 khi mở.';
COMMENT ON COLUMN ph11_bpm.incident.type IS 'IncidentType: JOB_FAILED, SERVICE_TIMEOUT, CORRELATION_FAILED, TIMER_FAILED, COMPENSATION_FAILED, STUCK_INSTANCE, ENGINE_ERROR, SUPPLEMENT_EXPIRED (hết hạn bổ sung hồ sơ, FR-11-049, ERR-11-125).';
COMMENT ON COLUMN ph11_bpm.incident.job_id IS 'Mã job lỗi trong engine (ACT_RU_DEADLETTER_JOB.ID_); rỗng với sự cố không do job.';
COMMENT ON COLUMN ph11_bpm.incident.message IS 'Thông điệp lỗi đã lược dữ liệu cá nhân; không ghi giá trị biến.';
COMMENT ON COLUMN ph11_bpm.incident.retries_done IS 'Số lần thử lại thủ công và tự động đã thực hiện.';
COMMENT ON COLUMN ph11_bpm.incident.handled_by IS 'Người xử lý (thử lại thành công, giải quyết hoặc bỏ qua).';
COMMENT ON COLUMN ph11_bpm.incident.reason IS 'Lý do xử lý; bắt buộc từ 20 ký tự khi IGNORED.';
--rollback DROP TABLE IF EXISTS ph11_bpm.incident CASCADE;

--changeset ph11:ph11-0610-migration-plan
CREATE TABLE ph11_bpm.migration_plan (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  process_key      varchar(64) NOT NULL,
  from_version     integer NOT NULL,
  to_version       integer NOT NULL,
  filter           jsonb NOT NULL DEFAULT '{}',
  mappings         jsonb NOT NULL DEFAULT '[]',
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  approved_by      varchar(64),
  approved_at      timestamptz,
  decision_comment varchar(2000),
  summary          jsonb NOT NULL DEFAULT '{"total": 0, "migrated": 0, "failed": 0}',
  dry_run_report   jsonb,
  started_at       timestamptz,
  finished_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan PRIMARY KEY (id),
  CONSTRAINT ck_migration_plan_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_plan_from FOREIGN KEY (tenant_id, process_key, from_version) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT fk_migration_plan_to FOREIGN KEY (tenant_id, process_key, to_version) REFERENCES ph11_bpm.process_version (tenant_id, process_key, version_no),
  CONSTRAINT ck_migration_plan_versions CHECK (from_version <> to_version),
  CONSTRAINT ck_migration_plan_status CHECK (status IN ('DRAFT', 'VALIDATED', 'PENDING_APPROVAL', 'RUNNING', 'COMPLETED', 'PARTIAL', 'REJECTED')),
  CONSTRAINT ck_migration_plan_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_migration_plan_approved CHECK (status NOT IN ('RUNNING', 'COMPLETED', 'PARTIAL', 'REJECTED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_migration_plan_rejected CHECK (status <> 'REJECTED' OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_migration_plan_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_migration_plan_mappings CHECK (jsonb_typeof(mappings) = 'array'),
  CONSTRAINT ck_migration_plan_summary CHECK (jsonb_typeof(summary) = 'object' AND CASE WHEN (summary ->> 'total') ~ '^[0-9]{1,9}$' AND (summary ->> 'migrated') ~ '^[0-9]{1,9}$' AND (summary ->> 'failed') ~ '^[0-9]{1,9}$' THEN (summary ->> 'migrated')::bigint + (summary ->> 'failed')::bigint <= (summary ->> 'total')::bigint ELSE false END),
  CONSTRAINT ck_migration_plan_finished CHECK ((status IN ('COMPLETED', 'PARTIAL')) = (finished_at IS NOT NULL) OR status = 'REJECTED')
);
CREATE UNIQUE INDEX uq_migration_plan_running ON ph11_bpm.migration_plan (tenant_id, process_key) WHERE status = 'RUNNING';
CREATE INDEX ix_migration_plan_model ON ph11_bpm.migration_plan (tenant_id, process_key, created_at DESC);
CREATE TRIGGER tg_migration_plan_touch BEFORE UPDATE ON ph11_bpm.migration_plan FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_migration_plan_immutable BEFORE UPDATE ON ph11_bpm.migration_plan FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('process_key', 'from_version', 'to_version', 'requested_by', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.migration_plan', 'P');
COMMENT ON TABLE ph11_bpm.migration_plan IS 'EN-11-19 Kế hoạch di trú phiên sang phiên bản mô hình mới (FR-11-026, PERM-11-instance-admin). Bốn mắt (BR-11-021): người duyệt khác người lập; ánh xạ bước cũ sang bước mới (mappings), kiểm tra trước khi chạy (dry_run_report); mỗi mô hình chỉ một kế hoạch RUNNING; chạy theo lô 11.migration.batchSize. PARTIAL là còn phiên lỗi; từ chối cần ý kiến từ 20 ký tự. Lý do từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.migration_plan.process_key IS 'Khóa mô hình; cùng from_version, to_version tạo khóa ngoại tới process_version.';
COMMENT ON COLUMN ph11_bpm.migration_plan.filter IS 'Điều kiện chọn phiên (API instanceFilter: trạng thái, bước hiện tại); rỗng là mọi phiên đang chạy của phiên bản nguồn.';
COMMENT ON COLUMN ph11_bpm.migration_plan.mappings IS 'Mảng ánh xạ bước, mỗi phần tử {fromElementId, toElementId} (API MappingItem).';
COMMENT ON COLUMN ph11_bpm.migration_plan.approved_by IS 'Người quyết định (duyệt hoặc từ chối), khác requested_by.';
COMMENT ON COLUMN ph11_bpm.migration_plan.decision_comment IS 'Ý kiến của người quyết định; từ chối cần từ 20 ký tự.';
COMMENT ON COLUMN ph11_bpm.migration_plan.summary IS 'Kết quả chạy: {total, migrated, failed} (API MigrationSummary); migrated cộng failed không vượt total.';
COMMENT ON COLUMN ph11_bpm.migration_plan.dry_run_report IS 'Kết quả bước kiểm tra: số phiên hợp lệ, danh sách phiên không di trú được và lý do.';
--rollback DROP TABLE IF EXISTS ph11_bpm.migration_plan CASCADE;

--changeset ph11:ph11-0620-setting-validator splitStatements:false
-- Miền giá trị của 36 tham số 11.* theo FRS 8.2: số trong khoảng, chuỗi liệt kê, cron sáu trường, logic. Khóa ngoài danh sách bị từ chối.
CREATE OR REPLACE FUNCTION ph11_bpm.f_setting_valid(p_key text, p_value jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE AS $f$
  SELECT CASE
    WHEN jsonb_typeof(p_value) = 'number' THEN COALESCE((
      SELECT (p_value #>> '{}')::numeric BETWEEN r.lo AND r.hi
      FROM (VALUES ('11.task.dueSoonHours', 1, 72), ('11.task.bulkMax', 1, 2000), ('11.task.attachmentMaxMb', 1, 50),
                   ('11.delegation.maxDays', 1, 90), ('11.designer.lockMinutes', 5, 240), ('11.model.maxXmlKb', 256, 8192),
                   ('11.timer.minSeconds', 60, 3600), ('11.callActivity.maxDepth', 1, 5), ('11.service.defaultTimeoutMinutes', 1, 10080),
                   ('11.outbox.maxAttempts', 5, 100), ('11.instance.startRatePerClient', 1, 500), ('11.instance.stuckHours', 1, 720),
                   ('11.message.bufferMinutes', 0, 1440), ('11.migration.batchSize', 10, 1000), ('11.saga.maxRetries', 0, 10),
                   ('11.saga.retryBackoffSeconds', 30, 86400), ('11.due.scanMinutes', 1, 15), ('11.supplement.defaultDays', 1, 60),
                   ('11.bottleneck.minSamples', 10, 1000), ('11.bottleneck.factor', 1.2, 10), ('11.retention.instanceYears', 5, 20),
                   ('11.retention.sagaYears', 5, 20), ('11.retention.progressEventYears', 1, 10), ('11.retention.engineHistoryMonths', 3, 60),
                   ('11.test.retentionDays', 1, 30), ('11.ai.timeoutSeconds', 2, 30), ('11.progress.cacheSeconds', 0, 300),
                   ('11.designer.autosaveSeconds', 5, 300), ('11.task.draftDebounceSeconds', 1, 60), ('11.task.unmaskSeconds', 10, 300),
                   ('11.escalation.nextLevelHours', 1, 72)) AS r(k, lo, hi)
      WHERE r.k = p_key), false)
    WHEN jsonb_typeof(p_value) = 'boolean' THEN p_key = '11.supplement.resetDue'
    WHEN jsonb_typeof(p_value) = 'string' THEN CASE p_key
      WHEN '11.task.fallbackGroup' THEN char_length(p_value #>> '{}') BETWEEN 1 AND 64
      WHEN '11.due.receiveAfterHoursRule' THEN (p_value #>> '{}') IN ('NEXT_WORKING_START', 'SAME_DAY')
      WHEN '11.saga.reconcileCron' THEN (p_value #>> '{}') ~ '^\S+( \S+){5}$'
      WHEN '11.retention.cleanupCron' THEN (p_value #>> '{}') ~ '^\S+( \S+){5}$'
      ELSE false END
    ELSE false END
$f$;
COMMENT ON FUNCTION ph11_bpm.f_setting_valid(text, jsonb) IS 'Kiểm miền giá trị tham số 11.* theo FRS 8.2 (CHECK của tenant_setting); khóa ngoài danh sách 36 tham số bị từ chối.';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.f_setting_valid(text, jsonb);

--changeset ph11:ph11-0630-tenant-setting
CREATE TABLE ph11_bpm.tenant_setting (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  key        varchar(64) NOT NULL,
  value      jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, key),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_tenant_setting_key CHECK (key ~ '^11\.[a-z][A-Za-z]{1,30}\.[a-z][A-Za-z]{1,40}$'),
  CONSTRAINT ck_tenant_setting_value CHECK (ph11_bpm.f_setting_valid(key, value))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph11_bpm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph11_bpm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('key', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.tenant_setting', 'S');
COMMENT ON TABLE ph11_bpm.tenant_setting IS 'EN-11-23 Tham số phân hệ theo tenant, 36 khóa 11.* của FRS 8.2 (FR-11-062, 063), PERM-11-config. Giá trị jsonb đúng kiểu và đơn vị của FRS (ví dụ 11.service.defaultTimeoutMinutes là phút), miền giá trị kiểm bằng ph11_bpm.f_setting_valid. Dòng tenant COMMON là trần nền tảng do PA đặt (mẫu S: tenant đọc được); tham số tenant không vượt trần (BR-11-024, dịch vụ so khi lưu). Không xóa (quyền).';
COMMENT ON COLUMN ph11_bpm.tenant_setting.key IS 'Khóa dạng 11.{nhóm}.{tên}, ví dụ 11.task.dueSoonHours (API Setting.key).';
COMMENT ON COLUMN ph11_bpm.tenant_setting.value IS 'Giá trị JSON: số, chuỗi hoặc logic tùy khóa (API Setting.value).';
--rollback DROP TABLE IF EXISTS ph11_bpm.tenant_setting CASCADE;
