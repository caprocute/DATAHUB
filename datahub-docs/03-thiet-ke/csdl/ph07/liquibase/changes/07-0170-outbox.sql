--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0170-outbox.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1700-outbox
-- Cấu trúc DD-11 + tenant_id. Ngoại lệ D00-01 §5.1: event_id là khóa chính,
-- không có updated_*/version (chỉ-thêm, Debezium đọc WAL).
CREATE TABLE ph07_rdm.outbox (
  event_id        uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  event_type      varchar(128)  NOT NULL,
  topic           varchar(249)  NOT NULL,
  aggregate_type  varchar(64)   NOT NULL,
  aggregate_id    text          NOT NULL,
  payload         jsonb         NOT NULL,
  trace_id        char(32)      NOT NULL,
  occurred_at     timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.rdm\.[a-z]+\.[a-z]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^(t[0-9]{2}|common)\.rdm\.[a-z]+\.[a-z]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_outbox_occurred ON ph07_rdm.outbox (occurred_at);
ALTER TABLE ph07_rdm.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
ALTER TABLE ph07_rdm.outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.outbox FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_outbox_select ON ph07_rdm.outbox FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_outbox_insert ON ph07_rdm.outbox FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_outbox_delete ON ph07_rdm.outbox FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.outbox IS 'EN-07-17 Outbox giao dịch (DD-11, SAD §7.3); Debezium EventRouter phát lên Kafka. Mẫu RLS P. Dọn dòng quá 3 ngày.';
COMMENT ON COLUMN ph07_rdm.outbox.event_type IS 'Dạng vn.datahub.rdm.{thực-thể}.{sự-kiện}.v{n}, ví dụ vn.datahub.rdm.catalog.published.v1.';
COMMENT ON COLUMN ph07_rdm.outbox.topic IS 'Dạng {tenant viết thường}.rdm.{thực-thể}.{sự-kiện}.v{n}; COMMON dùng tiền tố common.';
--rollback DROP TABLE IF EXISTS ph07_rdm.outbox CASCADE;
