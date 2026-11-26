--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0070-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0430-kpi-tenant-setting
CREATE TABLE ph16_kpi.kpi_tenant_setting (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  param_code  varchar(64) NOT NULL,
  value       jsonb NOT NULL,
  description varchar(500),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_kpi_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_tenant_setting_code UNIQUE (tenant_id, param_code),
  CONSTRAINT ck_kpi_tenant_setting_code CHECK (param_code IN ('16.period.types', '16.period.close-day', '16.aggregate.cron', '16.aggregate.timeout-minutes', '16.source.stale-hours', '16.source.fail-after', '16.late-data.recompute', '16.manual.evidence-required', '16.report.four-eyes', '16.report.signing', '16.report.retention-years', '16.observation.retention-months', '16.export.link-hours', '16.export.max-rows', '16.national.enabled', '16.national.retry-max', '16.compare.min-tenants', '16.compliance.waiver-max-days')),
  CONSTRAINT ck_kpi_tenant_setting_type CHECK (CASE WHEN param_code IN ('16.late-data.recompute', '16.manual.evidence-required', '16.report.four-eyes', '16.report.signing', '16.national.enabled') THEN jsonb_typeof(value) = 'boolean' WHEN param_code IN ('16.period.close-day', '16.aggregate.timeout-minutes', '16.source.stale-hours', '16.source.fail-after', '16.report.retention-years', '16.observation.retention-months', '16.export.link-hours', '16.export.max-rows', '16.national.retry-max', '16.compare.min-tenants', '16.compliance.waiver-max-days') THEN jsonb_typeof(value) = 'number' ELSE jsonb_typeof(value) = 'string' END)
);
CREATE TRIGGER tg_kpi_tenant_setting_touch BEFORE UPDATE ON ph16_kpi.kpi_tenant_setting FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_tenant_setting_immutable BEFORE UPDATE ON ph16_kpi.kpi_tenant_setting FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'param_code');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_tenant_setting');
COMMENT ON TABLE ph16_kpi.kpi_tenant_setting IS 'EN-16-39 Tham số phân hệ theo tenant: 18 tham số 16.* (kỳ, lịch tổng hợp, độ tươi nguồn, bằng chứng số liệu tay, bốn mắt, ký số, lưu giữ, xuất, gửi quốc gia, so sánh, hạn miễn trừ) (FR-16-055, 057). Chỉ nhận mã đã khai báo, kiểu giá trị đúng theo mã; trigger của các bảng khác đọc tham số này.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_tenant_setting CASCADE;

--changeset ph16:ph16-0440-outbox-event
CREATE TABLE ph16_kpi.outbox_event (
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
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('kpi.indicator.activated.v1', 'kpi.indicator.retired.v1', 'kpi.source.state-changed.v1', 'kpi.manual-value.decided.v1', 'kpi.period.computed.v1', 'kpi.indicator.status-changed.v1', 'kpi.report.submitted.v1', 'kpi.report.published.v1', 'kpi.report.state-changed.v1', 'kpi.arch-component.changed.v1', 'kpi.arch-compliance.assessed.v1', 'kpi.national-submission.state-changed.v1', 'kpi.export.completed.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_payload CHECK (jsonb_typeof(payload) = 'object')
);
CREATE INDEX ix_outbox_event_occurred ON ph16_kpi.outbox_event (occurred_at);
CALL ph16_kpi.p_enable_rls('ph16_kpi.outbox_event');
COMMENT ON TABLE ph16_kpi.outbox_event IS 'Hạ tầng. Outbox (SAD 7.3) cho EVT-16-01…13 và bản ghi kiểm toán gửi PH-13 (FR-16-056, 058). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic `{tenant}.kpi.{thực-thể}.{sự-kiện}.v1`. Dọn sau 3 ngày.';
--rollback DROP TABLE IF EXISTS ph16_kpi.outbox_event CASCADE;

--changeset ph16:ph16-0450-inbox-event
CREATE TABLE ph16_kpi.inbox_event (
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
CREATE INDEX ix_inbox_event_received ON ph16_kpi.inbox_event (received_at);
CALL ph16_kpi.p_enable_rls('ph16_kpi.inbox_event');
COMMENT ON TABLE ph16_kpi.inbox_event IS 'Hạ tầng. Khử trùng sự kiện nhận: sự kiện của phân hệ nguồn (EVT-01-03, EVT-02-05, EVT-04-07, EVT-08-14, EVT-10-01, EVT-14-12, EVT-19-07…) tiêu thụ lũy đẳng theo event_id cho tự đăng ký sổ kiến trúc và nhận quan sát (FR-16-010, 044). Dọn sau 30 ngày.';
--rollback DROP TABLE IF EXISTS ph16_kpi.inbox_event CASCADE;
