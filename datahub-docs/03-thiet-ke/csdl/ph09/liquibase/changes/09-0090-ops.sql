--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0090-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0600-privacy-audit-event
CREATE TABLE ph09_privacy.privacy_audit_event (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  actor        varchar(64) NOT NULL,
  action       varchar(64) NOT NULL,
  target_kind  varchar(32) NOT NULL,
  target_id    varchar(128),
  api_code     varchar(10),
  success      boolean NOT NULL,
  privileged   boolean NOT NULL DEFAULT false,
  details      jsonb,
  trace_id     char(32) NOT NULL,
  audit_ref    varchar(64),
  forwarded_at timestamptz,
  CONSTRAINT pk_privacy_audit_event PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_privacy_audit_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_privacy_audit_event_api CHECK (api_code IS NULL OR api_code ~ '^API-09-[0-9]{3}$'),
  CONSTRAINT ck_privacy_audit_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_privacy_audit_event_no_value CHECK (details IS NULL OR NOT (details ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'plaintext', 'token', 'tokens'])),
  CONSTRAINT ck_privacy_audit_event_forwarded CHECK (forwarded_at IS NULL OR audit_ref IS NOT NULL)
) PARTITION BY RANGE (occurred_at);
CALL ph09_privacy.p_ensure_partitions('ph09_privacy.privacy_audit_event', current_date, 3);
CREATE INDEX ix_privacy_audit_event_actor ON ph09_privacy.privacy_audit_event (tenant_id, actor, occurred_at DESC);
CREATE INDEX ix_privacy_audit_event_target ON ph09_privacy.privacy_audit_event (tenant_id, target_kind, target_id, occurred_at DESC);
CREATE INDEX ix_privacy_audit_event_pending ON ph09_privacy.privacy_audit_event (tenant_id, occurred_at) WHERE forwarded_at IS NULL;
CREATE TRIGGER tg_privacy_audit_event_append_only BEFORE UPDATE OR DELETE ON ph09_privacy.privacy_audit_event FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_append_only();
CALL ph09_privacy.p_enable_rls('ph09_privacy.privacy_audit_event');
COMMENT ON TABLE ph09_privacy.privacy_audit_event IS 'EN-09-49 Chỉ mục kiểm toán thao tác bảo vệ dữ liệu (FR-09-061, BR-09-057, 058, NFR-09-013): ai, thao tác, đối tượng, API-09, kết quả; chuyển bản ghi đầy đủ sang PH-13 (forwarded_at). Không ghi giá trị SENSITIVE. Chỉ thêm; phân vùng tháng; 13 tháng trực tuyến, bản gốc ở WORM của PH-13.';
--rollback DROP TABLE IF EXISTS ph09_privacy.privacy_audit_event CASCADE;

--changeset ph09:ph09-0610-compliance-report
CREATE TABLE ph09_privacy.compliance_report (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  period_from   date NOT NULL,
  period_to     date NOT NULL,
  sections      varchar(32)[] NOT NULL,
  report_format varchar(8) NOT NULL,
  metrics       jsonb NOT NULL,
  file_ref      varchar(512),
  file_sha256   char(64),
  generated_by  varchar(64) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_report PRIMARY KEY (id),
  CONSTRAINT ck_compliance_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_compliance_report_period CHECK (period_to >= period_from),
  CONSTRAINT ck_compliance_report_format CHECK (report_format IN ('PDF', 'XLSX', 'DOCX')),
  CONSTRAINT ck_compliance_report_sections CHECK (cardinality(sections) >= 1),
  CONSTRAINT ck_compliance_report_sha CHECK (file_sha256 IS NULL OR file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_compliance_report_file CHECK ((file_ref IS NULL) = (file_sha256 IS NULL))
);
CREATE INDEX ix_compliance_report_period ON ph09_privacy.compliance_report (tenant_id, period_to DESC);
CREATE TRIGGER tg_compliance_report_touch BEFORE UPDATE ON ph09_privacy.compliance_report FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.compliance_report');
COMMENT ON TABLE ph09_privacy.compliance_report IS 'EN-09-50 Báo cáo tuân thủ theo kỳ (FR-09-062, 063): kỳ, các mục, chỉ số, tệp (Garage) và băm. Lập tự động theo 09.report.schedule-cron hoặc theo yêu cầu.';
--rollback DROP TABLE IF EXISTS ph09_privacy.compliance_report CASCADE;

--changeset ph09:ph09-0620-tenant-setting
CREATE TABLE ph09_privacy.tenant_setting (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  setting_key   varchar(48) NOT NULL,
  value         jsonb NOT NULL,
  floor_value   jsonb,
  ceiling_value jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('09.scan.sample-rows', '09.scan.schedule-cron', '09.scan.confidence', '09.request.sla-days', '09.grant.max-days', '09.grant.renew-max', '09.grant.expiring-notice-days', '09.grant.require-restricted', '09.bundle.debounce-seconds', '09.bundle.valid-minutes', '09.plan.cache-seconds', '09.consent.cache-seconds', '09.anomaly.quota-warn-percent', '09.anomaly.bulk-threshold', '09.anomaly.auto-suspend', '09.mask.reveal-seconds', '09.mask.reveal-max-per-hour', '09.log.scan-cron', '09.pseudo.key-rotate-days', '09.pseudo.min-rotate-days', '09.pseudo.destroy-delay-days', '09.reid.approval-ttl-hours', '09.reid.exec-window-minutes', '09.anon.k-min', '09.anon.risk-medium-above', '09.anon.risk-high-above', '09.ai.allow-restricted', '09.retention.run-cron', '09.retention.overdue-days', '09.shred.delay-days', '09.dsr.sla-days', '09.dsr.remind-days', '09.breach.alert-hours', '09.dpia.review-months', '09.audit.query-max-days', '09.report.schedule-cron')),
  CONSTRAINT ck_tenant_setting_bounds CHECK (jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value)))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph09_privacy.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph09_privacy.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('setting_key');
CALL ph09_privacy.p_enable_rls('ph09_privacy.tenant_setting');
COMMENT ON TABLE ph09_privacy.tenant_setting IS 'EN-09-51 Tham số 09.* của tenant (FR-09-064, FRS 8.2, BR-09-059): khóa, giá trị jsonb, sàn và trần do PA đặt, người sửa là updated_by. Miền hợp lệ kiểm ở dịch vụ (ERR-09-078); CHECK giữ danh sách khóa và buộc giá trị số nằm trong sàn, trần.';
--rollback DROP TABLE IF EXISTS ph09_privacy.tenant_setting CASCADE;

--changeset ph09:ph09-0630-outbox-event
CREATE TABLE ph09_privacy.outbox_event (
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
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('privacy.classification.changed.v1', 'privacy.classification.scan-finished.v1', 'privacy.contract-level.changed.v1', 'privacy.activity.activated.v1', 'privacy.purpose-request.submitted.v1', 'privacy.purpose-grant.approved.v1', 'privacy.purpose-grant.suspended.v1', 'privacy.purpose-grant.revoked.v1', 'privacy.purpose-grant.expired.v1', 'privacy.purpose-grant.expiring.v1', 'privacy.bundle.published.v1', 'privacy.mask-policy.activated.v1', 'privacy.usage.anomaly-detected.v1', 'privacy.secret-label.blocked.v1', 'privacy.reveal.granted.v1', 'privacy.pseudonym-key.state-changed.v1', 'privacy.reidentification.executed.v1', 'privacy.dataset.status-changed.v1', 'privacy.retention.task-finished.v1', 'privacy.legal-hold.changed.v1', 'privacy.crypto-shred.completed.v1', 'privacy.dsr.received.v1', 'privacy.dsr.due-soon.v1', 'privacy.dsr.overdue.v1', 'privacy.dsr.closed.v1', 'privacy.dsr.restriction-changed.v1', 'privacy.consent.given.v1', 'privacy.consent.withdrawn.v1', 'privacy.dpia.review-due.v1', 'privacy.breach.recorded.v1', 'privacy.breach.deadline-near.v1', 'privacy.breach.notified.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'fullName', 'nationalId', 'phone', 'email', 'token', 'tokens', 'subjectIdentifier']))
);
CREATE INDEX ix_outbox_event_occurred ON ph09_privacy.outbox_event (occurred_at);
CALL ph09_privacy.p_enable_rls('ph09_privacy.outbox_event');
COMMENT ON TABLE ph09_privacy.outbox_event IS 'Outbox (DD-11, ADR-042) cho EVT-09-01…32 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện không mang giá trị DLCN (BR-09-025): CHECK chặn khóa giá trị và định danh. Dọn sau 3 ngày.';
--rollback DROP TABLE IF EXISTS ph09_privacy.outbox_event CASCADE;

--changeset ph09:ph09-0640-inbox-event
CREATE TABLE ph09_privacy.inbox_event (
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
CREATE INDEX ix_inbox_event_received ON ph09_privacy.inbox_event (received_at);
CALL ph09_privacy.p_enable_rls('ph09_privacy.inbox_event');
COMMENT ON TABLE ph09_privacy.inbox_event IS 'Inbox chống xử lý trùng cho sự kiện PH-09 tiêu thụ (at-least-once): đổi phân loại từ PH-06 (FR-06-004), sự kiện đăng ký HTTT PH-02, báo lượt khai thác PH-14, sự cố PH-18. Khóa (consumer, event_id). Dọn sau 7 ngày.';
--rollback DROP TABLE IF EXISTS ph09_privacy.inbox_event CASCADE;
