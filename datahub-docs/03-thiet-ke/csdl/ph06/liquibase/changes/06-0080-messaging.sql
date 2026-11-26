--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0080-messaging.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0500-outbox-event
CREATE TABLE ph06_mdm.outbox_event (
  event_id       uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('mdm.golden.created.v1', 'mdm.golden.updated.v1', 'mdm.golden.merged.v1', 'mdm.golden.split.v1', 'mdm.golden.retired.v1', 'mdm.golden.restored.v1', 'mdm.candidate.ingested.v1', 'mdm.steward.item-created.v1', 'mdm.job.finished.v1', 'mdm.model.activated.v1', 'mdm.ruleset.activated.v1', 'mdm.national-sync.discrepancy-detected.v1', 'mdm.national-sync.paused.v1', 'mdm.xref.changed.v1', 'mdm.source-correction.requested.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'attributes', 'identifier', 'identifierValue', 'name', 'dateOfBirth']))
);
CREATE INDEX ix_outbox_event_occurred ON ph06_mdm.outbox_event (occurred_at);
CALL ph06_mdm.p_enable_rls('ph06_mdm.outbox_event');
COMMENT ON TABLE ph06_mdm.outbox_event IS 'Outbox (DD-11, SAD 7.3) cho EVT-06-01…15 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL, định tuyến theo topic. Sự kiện không chứa giá trị thuộc tính (BR-06-012): CHECK chặn khóa value, attributes, identifier. Dọn sau 3 ngày.';
--rollback DROP TABLE IF EXISTS ph06_mdm.outbox_event CASCADE;

--changeset ph06:ph06-0510-inbox-event
CREATE TABLE ph06_mdm.inbox_event (
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     varchar(255) NOT NULL,
  source_topic varchar(249) NOT NULL,
  event_type   varchar(255) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  outcome      varchar(2000),
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph06_mdm.inbox_event (received_at);
CALL ph06_mdm.p_enable_rls('ph06_mdm.inbox_event');
COMMENT ON TABLE ph06_mdm.inbox_event IS 'Inbox chống xử lý trùng cho sự kiện PH-06 tiêu thụ (at-least-once): trạng thái HTTT PH-01 (FR-06-008), thay đổi quốc gia từ PH-14 (FR-06-053), sự kiện nguồn PH-10 (FR-06-012). Khóa (consumer, event_id). Dọn sau 7 ngày.';
--rollback DROP TABLE IF EXISTS ph06_mdm.inbox_event CASCADE;

--changeset ph06:ph06-0520-shedlock
CREATE TABLE ph06_mdm.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph06_mdm.shedlock IS 'Khóa tác vụ nền (CandidateNormalizer, MatchJobScheduler, SteerQueueEscalator, SyncScheduler, RetentionPurgeJob, PartitionMaintenanceJob, OutboxCleaner, ExportExpiryJob); bảng kỹ thuật của ShedLock, không có tenant_id.';
--rollback DROP TABLE IF EXISTS ph06_mdm.shedlock CASCADE;
