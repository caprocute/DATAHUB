--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0090-report.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0660-ops-report splitStatements:false
CREATE TABLE ph18_ops.ops_report (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  report_kind        varchar(12) NOT NULL,
  period_kind        varchar(8) NOT NULL,
  period_from        date NOT NULL,
  period_to          date NOT NULL,
  status             varchar(24) NOT NULL DEFAULT 'QUEUED',
  metrics            jsonb NOT NULL DEFAULT '{}',
  bucket             varchar(63),
  object_key         text,
  sha256             char(64),
  generated_at       timestamptz,
  published_event_id uuid,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ops_report PRIMARY KEY (id),
  CONSTRAINT uq_ops_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_ops_report_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_ops_report_period UNIQUE (tenant_id, report_kind, period_kind, period_from),
  CONSTRAINT ck_ops_report_kind CHECK (report_kind IN ('DLQ', 'BACKUP', 'MIGRATION', 'INCIDENT', 'PARAMETER', 'SUMMARY')),
  CONSTRAINT ck_ops_report_period CHECK (period_kind IN ('DAY', 'WEEK', 'MONTH', 'QUARTER') AND period_to >= period_from),
  CONSTRAINT ck_ops_report_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_ops_report_bucket CHECK (bucket IS NULL OR bucket = 'dh-' || lower(tenant_id) || '-ops' OR (tenant_id = 'COMMON' AND bucket = 'dh-common-ops')),
  CONSTRAINT ck_ops_report_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_ops_report_done CHECK (status <> 'SUCCEEDED' OR generated_at IS NOT NULL)
);
CREATE TRIGGER tg_ops_report_touch BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_ops_report_immutable BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('report_kind', 'period_kind', 'period_from', 'period_to');
CREATE TRIGGER tg_ops_report_fsm_status BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,FAILED>QUEUED');
CALL ph18_ops.p_enable_rls('ph18_ops.ops_report', false);
COMMENT ON TABLE ph18_ops.ops_report IS 'EN-18-54 Báo cáo vận hành định kỳ (DLQ, sao lưu, di trú, sự cố, tham số, tổng hợp) gửi PH-16 qua sự kiện: kỳ, chỉ số tổng hợp, tệp ở Garage bucket dh-{tenant}-ops, tổng kiểm tra. Mỗi loại, kỳ một báo cáo; dòng COMMON là báo cáo nền tảng.';
--rollback DROP TABLE IF EXISTS ph18_ops.ops_report CASCADE;
