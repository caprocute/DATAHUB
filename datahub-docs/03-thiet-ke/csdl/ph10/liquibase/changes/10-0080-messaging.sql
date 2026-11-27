--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0080-messaging.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0800-outbox-event
CREATE TABLE ph10_event.outbox_event (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     varchar(255)  NOT NULL,
  partition_key    varchar(255)  NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = ph10_event.f_topic_prefix(tenant_id)),
  -- A.7: đúng 16 topic EVT-10-01…16, cộng kiểm toán gửi PH-13
  CONSTRAINT ck_outbox_event_topic CHECK (
       substr(topic, length(split_part(topic, '.', 1)) + 2) IN (
         'event.topic.activated.v1', 'event.topic.changed.v1', 'event.topic.deprecated.v1', 'event.topic.retired.v1',
         'event.schema.version-enabled.v1', 'event.publication.activated.v1', 'event.publication.state-changed.v1',
         'event.subscription.activated.v1', 'event.subscription.state-changed.v1', 'event.subscription.lag-alerted.v1',
         'event.delivery.dead-lettered.v1', 'event.replay.completed.v1', 'event.signing-key.rotated.v1',
         'event.compliance.violated.v1', 'event.migration.cut-over.v1', 'event.bridge.state-changed.v1', 'audit.recorded.v1')),
  -- ce_type = vn.datahub.event.{thực-thể}.{sự-kiện} khớp topic (A.7)
  CONSTRAINT ck_outbox_event_type CHECK (
       (split_part(topic, '.', 2) = 'event' AND event_type = 'vn.datahub.event.' || split_part(topic, '.', 3) || '.' || split_part(topic, '.', 4))
    OR (split_part(topic, '.', 2) = 'audit' AND event_type = 'vn.datahub.audit.recorded')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  -- BR-10-027, FR-10-065: không bí mật ký, không nội dung sự kiện
  CONSTRAINT ck_outbox_event_no_secret CHECK (NOT (payload ?| ARRAY['secret', 'signingSecret', 'password', 'token', 'apiKey'])
                                              AND payload::text !~ 'whsec_')
);
CREATE INDEX ix_outbox_event_occurred ON ph10_event.outbox_event (occurred_at);
ALTER TABLE ph10_event.outbox_event SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph10_event.p_enable_rls('ph10_event.outbox_event', 'P');
COMMENT ON TABLE ph10_event.outbox_event IS 'Outbox (DD-11, SAD §7.3) cho EVT-10-01…16 và bản ghi kiểm toán gửi PH-13 ({tenant}.audit.recorded.v1). Ghi cùng giao dịch nghiệp vụ; Debezium Outbox Event Router (connector dh-integration-outbox) đọc WAL, định tuyến theo cột topic, khóa theo partition_key. Dọn sau 3 ngày.';
COMMENT ON COLUMN ph10_event.outbox_event.partition_key IS 'Khóa Kafka: topicName, subscriptionCode, publicationCode, replayCode, bridgeCode tùy sự kiện (§6.2).';
--rollback DROP TABLE IF EXISTS ph10_event.outbox_event CASCADE;

--changeset ph10:ph10-0810-inbox-event
CREATE TABLE ph10_event.inbox_event (
  tenant_id        varchar(16)   NOT NULL,
  consumer         varchar(64)   NOT NULL,
  event_id         varchar(255)  NOT NULL,
  source_topic     varchar(249)  NOT NULL,
  event_type       varchar(255)  NOT NULL,
  received_at      timestamptz   NOT NULL DEFAULT now(),
  processed_at     timestamptz,
  outcome          varchar(2000),
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = ph10_event.f_topic_prefix(tenant_id) OR (tenant_id = 'COMMON' AND split_part(source_topic, '.', 1) = 'platform'))
);
CREATE INDEX ix_inbox_event_received ON ph10_event.inbox_event (received_at);
CALL ph10_event.p_enable_rls('ph10_event.inbox_event', 'P');
COMMENT ON TABLE ph10_event.inbox_event IS 'Inbox chống xử lý trùng cho sự kiện PH-10 tiêu thụ (at-least-once): trạng thái HTTT PH-01, luồng PH-04 ngừng, CDC schema-changed PH-05 (FR-10-068), khởi tạo tenant PH-20. Ghi cùng giao dịch với tác dụng; khóa (consumer, event_id = ce id). Dọn sau 7 ngày. DlqWriter không dùng bảng này (lũy đẳng nhờ uq_dlq_entry_source).';
COMMENT ON COLUMN ph10_event.inbox_event.consumer IS 'Tên bộ tiêu thụ, ví dụ SystemStateConsumer, CdcSchemaChangedConsumer, TenantProvisionedConsumer.';
--rollback DROP TABLE IF EXISTS ph10_event.inbox_event CASCADE;

--changeset ph10:ph10-0820-shedlock
CREATE TABLE ph10_event.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph10_event.shedlock IS 'Khóa tác vụ nền (LagCollector, ApprovalExpiryJob, ProvisioningTimeoutJob, SigningKeyRotationJob, DlqPayloadPurgeJob, TopicDeleteJob, BridgeExpiryJob, MigrationReconcileJob, PartitionMaintenanceJob); bảng kỹ thuật không có tenant_id.';
--rollback DROP TABLE IF EXISTS ph10_event.shedlock;
