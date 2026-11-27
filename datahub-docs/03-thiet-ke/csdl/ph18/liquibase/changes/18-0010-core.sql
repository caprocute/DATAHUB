--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0010-core.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0100-outbox-event splitStatements:false
CREATE TABLE ph18_ops.outbox_event (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32),
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  published_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^[a-z0-9]+\.ops\.[a-z0-9-]+(\.[a-z0-9-]+)*\.v[0-9]+$'),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_content CHECK (NOT (payload ?| ARRAY['payload', 'payloadInline', 'value', 'values', 'email', 'phone', 'address', 'params']))
);
CREATE INDEX ix_outbox_event_occurred ON ph18_ops.outbox_event (occurred_at);
CREATE TRIGGER tg_outbox_event_touch BEFORE UPDATE ON ph18_ops.outbox_event FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.outbox_event', false);
COMMENT ON TABLE ph18_ops.outbox_event IS 'Bảng kỹ thuật (không có mã EN). Outbox (DD-11, ADR-042) cho sự kiện {tenant}.ops.*.v1 của PH-18: ops.param.changed, ops.dlq.threshold-crossed, ops.notification.bounced, ops.tenant.restored, sự cố, báo cáo vận hành. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm; CHECK chặn khóa payload DLQ, giá trị tham số, địa chỉ người nhận. Dọn sau 18.outbox.retention-days.';
--rollback DROP TABLE IF EXISTS ph18_ops.outbox_event CASCADE;

--changeset ph18:ph18-0110-inbox-event splitStatements:false
CREATE TABLE ph18_ops.inbox_event (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     varchar(255) NOT NULL,
  source_topic varchar(249) NOT NULL,
  event_type   varchar(255) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  outcome      varchar(2000),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_inbox_event PRIMARY KEY (id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_inbox_event_consumer UNIQUE (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) IN (lower(tenant_id), 'platform'))
);
CREATE INDEX ix_inbox_event_received ON ph18_ops.inbox_event (received_at);
CREATE TRIGGER tg_inbox_event_touch BEFORE UPDATE ON ph18_ops.inbox_event FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.inbox_event', false);
COMMENT ON TABLE ph18_ops.inbox_event IS 'Bảng kỹ thuật (không có mã EN). Inbox khử trùng sự kiện PH-18 tiêu thụ (at-least-once): topic DLQ {tenant}.ops.dlq.v1 (khóa dlqKey, cửa sổ 18.dlq.dedup-window-days), sự kiện các PH sinh thông báo và việc (hợp đồng §1.3), EVT-10-11, 12, 15, 16, EVT-13-04, 05, sự kiện platform.tenant.* của PH-20. Khóa (consumer, event_id).';
--rollback DROP TABLE IF EXISTS ph18_ops.inbox_event CASCADE;
