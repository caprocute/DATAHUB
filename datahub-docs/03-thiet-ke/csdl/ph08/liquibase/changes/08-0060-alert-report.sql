--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0060-alert-report.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0340-dq-alert-rule
CREATE TABLE ph08_dq.dq_alert_rule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  alert_rule_code  varchar(63) NOT NULL,
  name             varchar(255) NOT NULL,
  domain_code      varchar(32),
  asset_id         uuid,
  condition_type   varchar(24) NOT NULL,
  dimension        varchar(16),
  threshold        numeric(8,3),
  severity         varchar(8) NOT NULL DEFAULT 'MEDIUM',
  channels         jsonb NOT NULL DEFAULT '[]',
  recipients       jsonb NOT NULL DEFAULT '[]',
  cooldown_minutes integer NOT NULL DEFAULT 60,
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_alert_rule PRIMARY KEY (id),
  CONSTRAINT uq_dq_alert_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_alert_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_alert_rule_code UNIQUE (tenant_id, alert_rule_code),
  CONSTRAINT fk_dq_alert_rule_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_alert_rule_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_alert_rule_code CHECK (alert_rule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_alert_rule_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_alert_rule_condition CHECK (condition_type IN ('SCORE_BELOW', 'SCORE_DROP', 'SCAN_FAILED', 'INCOMPLETE_DIMENSIONS', 'ISSUE_OVERDUE', 'INLINE_FAIL_RATE', 'NEW_CRITICAL_FINDINGS')),
  CONSTRAINT ck_dq_alert_rule_dimension CHECK (dimension IS NULL OR dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_alert_rule_severity CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
  CONSTRAINT ck_dq_alert_rule_threshold CHECK (condition_type NOT IN ('SCORE_BELOW', 'SCORE_DROP', 'INLINE_FAIL_RATE') OR threshold IS NOT NULL),
  CONSTRAINT ck_dq_alert_rule_cooldown CHECK (cooldown_minutes BETWEEN 1 AND 10080)
);
CREATE INDEX ix_dq_alert_rule_scope ON ph08_dq.dq_alert_rule (tenant_id, condition_type) WHERE enabled;
CREATE TRIGGER tg_dq_alert_rule_touch BEFORE UPDATE ON ph08_dq.dq_alert_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_alert_rule');
COMMENT ON TABLE ph08_dq.dq_alert_rule IS 'EN-08-21 Quy tắc cảnh báo: điều kiện điểm thấp, điểm giảm, lần đo thất bại, thiếu chiều, phiếu quá hạn, tỷ lệ lỗi trực tuyến, lỗi CRITICAL mới; kênh gửi qua PH-13 (FR-08-047, 048).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_alert_rule CASCADE;

--changeset ph08:ph08-0350-dq-alert
CREATE TABLE ph08_dq.dq_alert (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  alert_rule_id    uuid NOT NULL,
  asset_id         uuid,
  scan_job_id      uuid,
  snapshot_id      uuid,
  severity         varchar(8) NOT NULL,
  status           varchar(14) NOT NULL DEFAULT 'FIRING',
  dedup_key        varchar(160) NOT NULL,
  message          varchar(1000) NOT NULL,
  fired_at         timestamptz NOT NULL DEFAULT now(),
  notified_at      timestamptz,
  notification_ref varchar(64),
  acknowledged_by  varchar(64),
  acknowledged_at  timestamptz,
  silenced_until   timestamptz,
  silence_reason   varchar(500),
  resolved_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_alert PRIMARY KEY (id),
  CONSTRAINT uq_dq_alert_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_alert_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_alert_rule FOREIGN KEY (tenant_id, alert_rule_id) REFERENCES ph08_dq.dq_alert_rule (tenant_id, id),
  CONSTRAINT fk_dq_alert_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_alert_severity CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
  CONSTRAINT ck_dq_alert_status CHECK (status IN ('FIRING', 'ACKNOWLEDGED', 'RESOLVED', 'SILENCED')),
  CONSTRAINT ck_dq_alert_ack CHECK (status <> 'ACKNOWLEDGED' OR (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)),
  CONSTRAINT ck_dq_alert_silence CHECK (status <> 'SILENCED' OR (silenced_until IS NOT NULL AND COALESCE(char_length(silence_reason) >= 20, false))),
  CONSTRAINT ck_dq_alert_resolved CHECK ((status = 'RESOLVED') = (resolved_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_dq_alert_open ON ph08_dq.dq_alert (tenant_id, dedup_key) WHERE status IN ('FIRING', 'ACKNOWLEDGED', 'SILENCED');
CREATE UNIQUE INDEX uq_dq_alert_unresolved ON ph08_dq.dq_alert (tenant_id, alert_rule_id, COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE status <> 'RESOLVED';
CREATE INDEX ix_dq_alert_status ON ph08_dq.dq_alert (tenant_id, status, fired_at DESC);
CREATE INDEX ix_dq_alert_asset ON ph08_dq.dq_alert (tenant_id, asset_id, fired_at DESC) WHERE asset_id IS NOT NULL;
CREATE TRIGGER tg_dq_alert_touch BEFORE UPDATE ON ph08_dq.dq_alert FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_alert');
COMMENT ON TABLE ph08_dq.dq_alert IS 'EN-08-22 Cảnh báo đã phát: trạng thái FIRING, ACKNOWLEDGED, RESOLVED, SILENCED, khóa chống trùng, tham chiếu thông báo PH-13 (FR-08-048, 049).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_alert CASCADE;

--changeset ph08:ph08-0360-dq-report
CREATE TABLE ph08_dq.dq_report (
  id                        uuid NOT NULL,
  tenant_id                 varchar(16) NOT NULL,
  report_code               varchar(24) NOT NULL,
  report_type               varchar(10) NOT NULL,
  period_code               varchar(7) NOT NULL,
  title                     varchar(255) NOT NULL,
  status                    varchar(10) NOT NULL DEFAULT 'DRAFT',
  scope                     jsonb NOT NULL DEFAULT '{}',
  summary                   jsonb NOT NULL DEFAULT '{}',
  snapshot_count            integer NOT NULL DEFAULT 0,
  incomplete_snapshot_count integer NOT NULL DEFAULT 0,
  generated_at              timestamptz,
  submitted_by              varchar(64),
  submitted_at              timestamptz,
  reviewed_by               varchar(64),
  reviewed_at               timestamptz,
  review_comment            varchar(2000),
  published_by              varchar(64),
  published_at              timestamptz,
  withdrawn_reason          varchar(2000),
  pdf_object_key            varchar(512),
  xlsx_object_key           varchar(512),
  content_sha256            bytea,
  signed                    boolean NOT NULL DEFAULT false,
  signature_ref             varchar(255),
  created_at                timestamptz NOT NULL DEFAULT now(),
  created_by                varchar(64) NOT NULL,
  updated_at                timestamptz NOT NULL DEFAULT now(),
  updated_by                varchar(64) NOT NULL,
  version                   integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_report PRIMARY KEY (id),
  CONSTRAINT uq_dq_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_report_code UNIQUE (tenant_id, report_code),
  CONSTRAINT ck_dq_report_code CHECK (report_code ~ '^BC-DQ-[0-9]{4}-[A-Z0-9]{2,4}-T[0-9]{2}(-R[0-9]{1,2})?$'),
  CONSTRAINT ck_dq_report_type CHECK (report_type IN ('PERIODIC', 'ANNUAL', 'AD_HOC')),
  CONSTRAINT ck_dq_report_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'PUBLISHED', 'WITHDRAWN')),
  CONSTRAINT ck_dq_report_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$' AND (report_type <> 'ANNUAL' OR period_code ~ '^[0-9]{4}$')),
  CONSTRAINT ck_dq_report_hash CHECK (content_sha256 IS NULL OR octet_length(content_sha256) = 32),
  CONSTRAINT ck_dq_report_annual_full CHECK (report_type <> 'ANNUAL' OR incomplete_snapshot_count = 0),
  CONSTRAINT ck_dq_report_four_eyes CHECK (reviewed_by IS NULL OR submitted_by IS NULL OR reviewed_by <> submitted_by),
  CONSTRAINT ck_dq_report_publisher CHECK (published_by IS NULL OR submitted_by IS NULL OR published_by <> submitted_by),
  CONSTRAINT ck_dq_report_published CHECK (status <> 'PUBLISHED' OR (published_at IS NOT NULL AND published_by IS NOT NULL AND reviewed_by IS NOT NULL AND content_sha256 IS NOT NULL AND pdf_object_key IS NOT NULL)),
  CONSTRAINT ck_dq_report_withdrawn CHECK (status <> 'WITHDRAWN' OR COALESCE(char_length(withdrawn_reason) >= 20, false)),
  CONSTRAINT ck_dq_report_signed CHECK (NOT signed OR signature_ref IS NOT NULL),
  CONSTRAINT ck_dq_report_counts CHECK (snapshot_count >= 0 AND incomplete_snapshot_count >= 0 AND incomplete_snapshot_count <= snapshot_count)
);
CREATE INDEX ix_dq_report_period ON ph08_dq.dq_report (tenant_id, report_type, period_code, status);
CREATE INDEX ix_dq_report_published ON ph08_dq.dq_report (tenant_id, published_at DESC) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_dq_report_touch BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_report_immutable BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'report_code', 'report_type', 'period_code');
CREATE TRIGGER tg_dq_report_frozen BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('PUBLISHED,WITHDRAWN', 'scope', 'summary', 'snapshot_count', 'incomplete_snapshot_count', 'content_sha256', 'pdf_object_key', 'xlsx_object_key');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_report');
COMMENT ON TABLE ph08_dq.dq_report IS 'EN-08-23 Báo cáo chất lượng: kỳ (tháng), chính thức hằng năm, theo yêu cầu; soạn, duyệt bốn mắt, công bố; tệp PDF, XLSX trên Ceph RGW kèm SHA-256, ký số tùy chọn (FR-08-052…056). Báo cáo ANNUAL không được dựa trên snapshot thiếu chiều. Đã công bố thì bất biến.';
COMMENT ON COLUMN ph08_dq.dq_report.summary IS 'Số liệu tổng hợp (điểm theo miền, theo tổ chức, xu hướng); không chứa giá trị bản ghi.';
COMMENT ON COLUMN ph08_dq.dq_report.pdf_object_key IS 'Khóa đối tượng trên Ceph RGW, bucket dq-reports; không lưu tệp trong PostgreSQL.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_report CASCADE;

--changeset ph08:ph08-0370-dq-report-subscription
CREATE TABLE ph08_dq.dq_report_subscription (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  report_type    varchar(10) NOT NULL,
  domain_code    varchar(32),
  recipient_type varchar(8) NOT NULL,
  recipient_ref  varchar(128) NOT NULL,
  format         varchar(4) NOT NULL DEFAULT 'PDF',
  enabled        boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_report_subscription PRIMARY KEY (id),
  CONSTRAINT ck_dq_report_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_report_subscription_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_report_subscription_type CHECK (report_type IN ('PERIODIC', 'ANNUAL', 'AD_HOC')),
  CONSTRAINT ck_dq_report_subscription_recipient CHECK (recipient_type IN ('USER', 'ROLE', 'ORG')),
  CONSTRAINT ck_dq_report_subscription_format CHECK (format IN ('PDF', 'XLSX'))
);
CREATE UNIQUE INDEX uq_dq_report_subscription ON ph08_dq.dq_report_subscription (tenant_id, report_type, COALESCE(domain_code, ''), recipient_type, recipient_ref, format);
CREATE TRIGGER tg_dq_report_subscription_touch BEFORE UPDATE ON ph08_dq.dq_report_subscription FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_report_subscription');
COMMENT ON TABLE ph08_dq.dq_report_subscription IS 'EN-08-24 Đăng ký nhận báo cáo: người dùng, vai trò hoặc tổ chức nhận báo cáo công bố qua PH-13 (FR-08-056).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_report_subscription CASCADE;
