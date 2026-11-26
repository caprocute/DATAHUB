--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0010-core.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0100-file-object
CREATE TABLE ph17_assist.file_object (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  bucket       varchar(64) NOT NULL,
  object_key   text NOT NULL,
  file_name    varchar(255) NOT NULL,
  content_type varchar(127) NOT NULL,
  size_bytes   bigint NOT NULL,
  sha256       char(64) NOT NULL,
  scan_status  varchar(16) NOT NULL DEFAULT 'PENDING',
  data_class   varchar(16) NOT NULL DEFAULT 'INTERNAL',
  purpose      varchar(24) NOT NULL,
  expires_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_file_object PRIMARY KEY (id),
  CONSTRAINT uq_file_object_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_file_object_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_file_object_key UNIQUE (bucket, object_key),
  CONSTRAINT ck_file_object_size CHECK (size_bytes >= 0),
  CONSTRAINT ck_file_object_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_file_object_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_file_object_class CHECK (data_class IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_file_object_purpose CHECK (purpose IN ('UPLOAD_SOURCE', 'COMMITMENT', 'COMPLIANCE_PACK', 'USAGE_REPORT')),
  CONSTRAINT ck_file_object_ctype CHECK (content_type IN ('application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/markdown', 'text/plain', 'application/zip', 'text/csv'))
);
CREATE INDEX ix_file_object_expires ON ph17_assist.file_object (expires_at) WHERE expires_at IS NOT NULL;
CREATE TRIGGER tg_file_object_touch BEFORE UPDATE ON ph17_assist.file_object FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_file_object_immutable BEFORE UPDATE ON ph17_assist.file_object FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('bucket', 'object_key', 'sha256', 'size_bytes');
CALL ph17_assist.p_enable_rls_common('ph17_assist.file_object');
COMMENT ON TABLE ph17_assist.file_object IS 'EN-17-39 Tham chiếu đối tượng tệp (DD-12) cho tài liệu tải lên (FR-17-020), hồ sơ cam kết nhà cung cấp (FR-17-003, 007) và gói bằng chứng tuân thủ (FR-17-057). Nội dung nằm ở kho đối tượng; chỉ tệp quét sạch (CLEAN) mới được dùng. Không bí mật, không nội dung hội thoại.';
COMMENT ON COLUMN ph17_assist.file_object.data_class IS 'Chỉ PUBLIC hoặc INTERNAL: PH-17 không nhận tệp mức cao hơn (BR-17-026, 030).';
COMMENT ON COLUMN ph17_assist.file_object.purpose IS 'UPLOAD_SOURCE tài liệu tải lên, COMMITMENT hồ sơ cam kết nhà cung cấp, COMPLIANCE_PACK gói bằng chứng, USAGE_REPORT báo cáo sử dụng.';
--rollback DROP TABLE IF EXISTS ph17_assist.file_object CASCADE;

--changeset ph17:ph17-0110-tenant-setting
CREATE TABLE ph17_assist.tenant_setting (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  setting_key   varchar(48) NOT NULL,
  value         jsonb NOT NULL,
  floor_value   jsonb,
  ceiling_value jsonb,
  four_eyes     boolean NOT NULL DEFAULT false,
  synced_at     timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('17.enabled', '17.feature.search', '17.feature.mapping', '17.feature.explain', '17.feature.roles', '17.model.external-allowed', '17.model.default-chat', '17.model.default-embed', '17.model.default-rerank', '17.model.fallback-enabled', '17.model.timeout-seconds', '17.quota.user-turns-per-day', '17.quota.user-turns-per-minute', '17.quota.warn-percent', '17.quota.du-calls-per-minute', '17.input.max-chars', '17.context.max-messages', '17.conversation.max-per-user', '17.rag.top-k', '17.rag.min-score', '17.rag.hybrid-weight-vector', '17.rag.chunk-overlap', '17.index.full-cron', '17.index.stale-days', '17.index.pause-purge-days', '17.upload.max-mb', '17.tool.max-calls-per-turn', '17.tool.timeout-seconds', '17.tool.max-depth', '17.mapping.sample-rows', '17.suggestion.ttl-hours', '17.explain.log-lines-max', '17.explain.trace-window-minutes', '17.log.retention-days', '17.log.access-reason-min-chars', '17.log.export-max-days', '17.breaker.error-rate', '17.breaker.open-seconds', '17.eval.min-score', '17.eval.regression-tolerance', '17.redteam.min-pass-rate', '17.feedback.sla-days', '17.quality.alert-drop-percent', '17.notice.reaccept-days', '17.model.first-token-timeout-seconds', '17.quota.tenant-tokens-per-day', '17.output.max-tokens', '17.rag.chunk-tokens', '17.report.cost-per-1k-tokens')),
  CONSTRAINT ck_tenant_setting_bounds CHECK (jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value))),
  CONSTRAINT ck_tenant_setting_retention_floor CHECK (setting_key <> '17.log.retention-days' OR (jsonb_typeof(value) = 'number' AND value >= '90'::jsonb)),
  CONSTRAINT ck_tenant_setting_redteam_floor CHECK (setting_key <> '17.redteam.min-pass-rate' OR value = '100'::jsonb)
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph17_assist.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph17_assist.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('setting_key');
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_setting');
COMMENT ON TABLE ph17_assist.tenant_setting IS 'EN-17-40 Bản chụp tham số 17.* của tenant (FRS 8.2, FR-17-059, BR-17-078). Nguồn chuẩn là PH-18 (DD-14); dh-assist đọc có đệm 30 giây và giữ bản chụp này để kiểm miền, sàn, trần khi ghi và để cổng phát hành đọc điểm tối thiểu. Khóa đổi bốn mắt đánh dấu four_eyes.';
COMMENT ON COLUMN ph17_assist.tenant_setting.synced_at IS 'Lần đồng bộ cuối từ PH-18 DD-14.';
--rollback DROP TABLE IF EXISTS ph17_assist.tenant_setting CASCADE;

--changeset ph17:ph17-0120-outbox-event
CREATE TABLE ph17_assist.outbox_event (
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
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('assist.config.changed.v1', 'assist.enablement.changed.v1', 'assist.kill-switch.changed.v1', 'assist.policy-change.decided.v1', 'assist.notice.published.v1', 'assist.provider.state-changed.v1', 'assist.model-version.state-changed.v1', 'assist.route.sync-requested.v1', 'assist.route.sync-completed.v1', 'assist.model.health-changed.v1', 'assist.breaker.state-changed.v1', 'assist.quota.threshold-reached.v1', 'assist.source.state-changed.v1', 'assist.index.completed.v1', 'assist.index.failed.v1', 'assist.index.purged.v1', 'assist.upload.state-changed.v1', 'assist.suggestion.decided.v1', 'assist.guardrail.violation-detected.v1', 'assist.prompt.state-changed.v1', 'assist.eval.run-completed.v1', 'assist.redteam.run-completed.v1', 'assist.feedback.submitted.v1', 'assist.quality.alert-raised.v1', 'assist.log.access-granted.v1', 'assist.export.ready.v1', 'assist.log.purged.v1', 'assist.process-suggestion.decided.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_content CHECK (NOT (payload ?| ARRAY['content', 'prompt', 'answer', 'question', 'text', 'chunk', 'embedding', 'secret', 'secret_ref', 'token', 'tokens', 'message', 'value', 'values']))
);
CREATE INDEX ix_outbox_event_occurred ON ph17_assist.outbox_event (occurred_at);
CALL ph17_assist.p_enable_rls('ph17_assist.outbox_event');
COMMENT ON TABLE ph17_assist.outbox_event IS 'EN-17-39 Outbox (DD-11, ADR-042) cho EVT-17-01…28. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm: CHECK chặn khóa nội dung hội thoại, đoạn tri thức, bí mật (BR-17-022, 073). Dọn sau 3 ngày.';
--rollback DROP TABLE IF EXISTS ph17_assist.outbox_event CASCADE;

--changeset ph17:ph17-0130-inbox-event
CREATE TABLE ph17_assist.inbox_event (
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
CREATE INDEX ix_inbox_event_received ON ph17_assist.inbox_event (received_at);
CALL ph17_assist.p_enable_rls('ph17_assist.inbox_event');
COMMENT ON TABLE ph17_assist.inbox_event IS 'EN-17-41 Inbox chống xử lý trùng cho sự kiện PH-17 tiêu thụ (at-least-once): catalog.api.*, rdm.catalog.*, integration.flow.*, event.publication.*, privacy.classification.changed, privacy.contract-level.changed, privacy.dataset.status-changed, gateway.snapshot.* (FRS 9.3b). Khóa (consumer, event_id). Dọn sau 7 ngày.';
--rollback DROP TABLE IF EXISTS ph17_assist.inbox_event CASCADE;
