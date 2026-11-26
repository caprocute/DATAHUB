--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0070-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0380-dq-export-request
CREATE TABLE ph08_dq.dq_export_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  kind                varchar(10) NOT NULL DEFAULT 'FINDINGS',
  report_code         varchar(24),
  asset_id            uuid,
  filter              jsonb NOT NULL DEFAULT '{}',
  format              varchar(4) NOT NULL DEFAULT 'CSV',
  status              varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  contains_restricted boolean NOT NULL DEFAULT false,
  requested_by        varchar(64) NOT NULL,
  decided_by          varchar(64),
  decided_at          timestamptz,
  decision_comment    varchar(2000),
  row_count           bigint,
  object_key          varchar(512),
  content_sha256      bytea,
  watermark_id        varchar(64),
  expires_at          timestamptz,
  download_count      integer NOT NULL DEFAULT 0,
  error_code          varchar(16),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_export_request PRIMARY KEY (id),
  CONSTRAINT uq_dq_export_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_export_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_export_request_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_export_request_report FOREIGN KEY (tenant_id, report_code) REFERENCES ph08_dq.dq_report (tenant_id, report_code),
  CONSTRAINT ck_dq_export_request_format CHECK (format IN ('CSV', 'XLSX', 'PDF')),
  CONSTRAINT ck_dq_export_request_kind CHECK (kind IN ('FINDINGS', 'REPORT') AND (kind = 'REPORT') = (report_code IS NOT NULL) AND (format <> 'PDF' OR kind = 'REPORT')),
  CONSTRAINT ck_dq_export_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'READY', 'FAILED', 'EXPIRED', 'REJECTED')),
  CONSTRAINT ck_dq_export_request_four_eyes CHECK (decided_by IS NULL OR requested_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_dq_export_request_approval CHECK (NOT contains_restricted OR status IN ('PENDING_APPROVAL', 'REJECTED') OR decided_by IS NOT NULL),
  CONSTRAINT ck_dq_export_request_ready CHECK (status <> 'READY' OR (object_key IS NOT NULL AND expires_at IS NOT NULL AND watermark_id IS NOT NULL AND content_sha256 IS NOT NULL)),
  CONSTRAINT ck_dq_export_request_hash CHECK (content_sha256 IS NULL OR octet_length(content_sha256) = 32),
  CONSTRAINT ck_dq_export_request_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_export_request_status ON ph08_dq.dq_export_request (tenant_id, status, created_at DESC);
CREATE INDEX ix_dq_export_request_expiry ON ph08_dq.dq_export_request (expires_at) WHERE status = 'READY';
CREATE TRIGGER tg_dq_export_request_touch BEFORE UPDATE ON ph08_dq.dq_export_request FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_export_request');
COMMENT ON TABLE ph08_dq.dq_export_request IS 'EN-08-29 Yêu cầu xuất bản ghi lỗi ra CSV hoặc XLSX trên Ceph RGW; khi có trường Nhạy cảm hoặc Hạn chế cần DO chấp thuận khác người yêu cầu (FR-08-039). Tệp có hạn tải và thủy vân.';
COMMENT ON COLUMN ph08_dq.dq_export_request.kind IS 'FINDINGS: xuất bản ghi lỗi (FR-08-039, cần DO chấp thuận khi có trường Hạn chế, Nhạy cảm); REPORT: xuất báo cáo PDF, XLSX (FR-08-055, API-08-116).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_export_request CASCADE;

--changeset ph08:ph08-0390-dq-tenant-setting
CREATE TABLE ph08_dq.dq_tenant_setting (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  setting_key varchar(64) NOT NULL,
  value       jsonb NOT NULL,
  description varchar(500),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_dq_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_dq_tenant_setting_key CHECK (setting_key IN ('08.scan.default-cron', '08.scan.timezone', '08.scan.window', '08.scan.min-interval-hours', '08.scan.max-duration-hours', '08.scan.queue-timeout-hours', '08.scan.duplicate-policy', '08.scan.manual-per-hour', '08.scan.max-concurrent-per-connection', '08.scan.heartbeat-timeout-seconds', '08.scan.task-max-attempts', '08.scan.min-coverage', '08.scan.task-size', '08.incremental.batch-window-minutes', '08.profile.on-activate', '08.profile.max-columns', '08.dryrun.max-rows', '08.rule.sql-predicate-enabled', '08.rdm.snapshot-max-items', '08.score.dimension-method', '08.trend.stable-band', '08.trend.degraded-alert', '08.finding.max-per-scan', '08.finding.max-per-rule-task', '08.finding.retention-months', '08.snapshot.retention-years', '08.report.official-retention-years', '08.report.auto-draft', '08.annual.snapshot-method', '08.issue.sla-days', '08.issue.auto-open-critical', '08.issue.escalate-after-overdue-days', '08.verify.wait-mdm-minutes', '08.verify.wait-source-minutes', '08.waiver.max-days', '08.inline.timeout-ms', '08.inline.default-mode', '08.inline.on-dependency-failure', '08.inline.persist-findings', '08.alert.repeat-hours', '08.export.link-hours', '08.benchmark.opt-in', '08.benchmark.min-group'))
);
CREATE TRIGGER tg_dq_tenant_setting_touch BEFORE UPDATE ON ph08_dq.dq_tenant_setting FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_tenant_setting');
COMMENT ON TABLE ph08_dq.dq_tenant_setting IS 'EN-08-26 Tham số chất lượng theo tenant: 43 khóa 08.* của FRS mục 8.2 (lịch đo, cửa sổ, mẫu, kích thước tác vụ, thời gian chờ, hạn SLA, hạn ngoại lệ, chế độ kiểm tra trực tuyến) (FR-08-058). Chỉ nhận các khóa đã khai báo; ngưỡng điểm và trọng số nằm ở dq_weight_config.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_tenant_setting CASCADE;

--changeset ph08:ph08-0400-dq-retention-policy
CREATE TABLE ph08_dq.dq_retention_policy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  object_type    varchar(40) NOT NULL,
  retention_days integer NOT NULL,
  action         varchar(16) NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_retention_policy PRIMARY KEY (id),
  CONSTRAINT ck_dq_retention_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_retention_policy UNIQUE (tenant_id, object_type),
  CONSTRAINT ck_dq_retention_policy_object CHECK (object_type IN ('dq_finding', 'dq_rule_result', 'dq_inline_stat', 'dq_scan_task', 'dq_profile_column', 'dq_score_snapshot', 'dq_issue', 'dq_alert', 'dq_report', 'dq_export_request', 'outbox_event', 'inbox_event')),
  CONSTRAINT ck_dq_retention_policy_action CHECK (action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')),
  CONSTRAINT ck_dq_retention_policy_days CHECK (retention_days >= 1 AND (object_type NOT IN ('dq_score_snapshot', 'dq_report') OR retention_days >= 1095))
);
CREATE TRIGGER tg_dq_retention_policy_touch BEFORE UPDATE ON ph08_dq.dq_retention_policy FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_retention_policy');
COMMENT ON TABLE ph08_dq.dq_retention_policy IS 'EN-08-30 Chính sách lưu giữ và dọn dữ liệu đo theo loại đối tượng: số ngày giữ và hành động (xóa phân vùng, xóa dòng, lưu lạnh) (FR-08-059). Bản ghi lỗi giữ mặc định 13 tháng (395 ngày), có thể đổi theo tenant.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_retention_policy CASCADE;

--changeset ph08:ph08-0410-dq-retention-run
CREATE TABLE ph08_dq.dq_retention_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  object_type        varchar(40) NOT NULL,
  action             varchar(16) NOT NULL,
  status             varchar(10) NOT NULL DEFAULT 'RUNNING',
  dry_run            boolean NOT NULL DEFAULT false,
  requested_by       varchar(64) NOT NULL,
  cutoff_at          timestamptz,
  started_at         timestamptz NOT NULL DEFAULT now(),
  finished_at        timestamptz,
  rows_affected      bigint NOT NULL DEFAULT 0,
  partitions_dropped integer NOT NULL DEFAULT 0,
  error_code         varchar(16),
  error_message      varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_retention_run PRIMARY KEY (id),
  CONSTRAINT uq_dq_retention_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_retention_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dq_retention_run_object CHECK (object_type IN ('dq_finding', 'dq_rule_result', 'dq_inline_stat', 'dq_scan_task', 'dq_profile_column', 'dq_score_snapshot', 'dq_issue', 'dq_alert', 'dq_report', 'dq_export_request', 'outbox_event', 'inbox_event')),
  CONSTRAINT ck_dq_retention_run_action CHECK (action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')),
  CONSTRAINT ck_dq_retention_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_dq_retention_run_done CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_retention_run_counts CHECK (rows_affected >= 0 AND partitions_dropped >= 0),
  CONSTRAINT ck_dq_retention_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_retention_run_started ON ph08_dq.dq_retention_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_dq_retention_run_touch BEFORE UPDATE ON ph08_dq.dq_retention_run FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_retention_run');
COMMENT ON TABLE ph08_dq.dq_retention_run IS 'EN-08-30 Lịch sử chạy dọn dữ liệu đo theo chính sách lưu giữ: loại dữ liệu, hành động, số dòng và phân vùng đã dọn, chạy xem trước hay chạy thật (FR-08-059, API-08-125, 126).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_retention_run CASCADE;

--changeset ph08:ph08-0420-outbox-event
CREATE TABLE ph08_dq.outbox_event (
  tenant_id      varchar(16) NOT NULL,
  event_id       uuid NOT NULL,
  topic          varchar(128) NOT NULL,
  aggregate_type varchar(32) NOT NULL,
  aggregate_id   uuid NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  published_at   timestamptz,
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('dq.ruleset.activated.v1', 'dq.scan.completed.v1', 'dq.scan.failed.v1', 'dq.score.degraded.v1', 'dq.score.threshold-breached.v1', 'dq.finding.opened.v1', 'dq.issue.created.v1', 'dq.issue.status-changed.v1', 'dq.issue.verified.v1', 'dq.waiver.approved.v1', 'dq.report.published.v1', 'dq.alert.fired.v1', 'dq.check.failed.v1', 'dq.kpi.published.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'maskedValue', 'valueHash', 'record', 'recordKey', 'fields']))
);
CREATE INDEX ix_outbox_event_occurred ON ph08_dq.outbox_event (occurred_at);
CALL ph08_dq.p_enable_rls('ph08_dq.outbox_event');
COMMENT ON TABLE ph08_dq.outbox_event IS 'EN-08-27 Outbox (SAD 7.3) cho EVT-08-01…14 và bản ghi kiểm toán gửi PH-13 (FR-08-057, 060). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic. Sự kiện không chứa giá trị bản ghi lỗi: CHECK chặn các khóa value, maskedValue, record. Dọn sau 3 ngày.';
--rollback DROP TABLE IF EXISTS ph08_dq.outbox_event CASCADE;

--changeset ph08:ph08-0430-inbox-event
CREATE TABLE ph08_dq.inbox_event (
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     uuid NOT NULL,
  source_topic varchar(128) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph08_dq.inbox_event (received_at);
CALL ph08_dq.p_enable_rls('ph08_dq.inbox_event');
COMMENT ON TABLE ph08_dq.inbox_event IS 'EN-08-28 Khử trùng sự kiện nhận: EVT-06-01, 02, 03, 04, 10 của PH-06 và sự kiện phát hành danh mục của PH-07, tiêu thụ lũy đẳng theo event_id (FR-08-025). Dọn sau 30 ngày.';
--rollback DROP TABLE IF EXISTS ph08_dq.inbox_event CASCADE;

--changeset ph08:ph08-0440-shedlock
CREATE TABLE ph08_dq.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph08_dq.shedlock IS 'Bảng kỹ thuật của thư viện ShedLock cho các job Quartz (lập lịch đo, dọn, duy trì phân vùng); không chứa dữ liệu nghiệp vụ.';
--rollback DROP TABLE IF EXISTS ph08_dq.shedlock CASCADE;
