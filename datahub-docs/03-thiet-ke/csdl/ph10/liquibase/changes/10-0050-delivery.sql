--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0050-delivery.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0500-delivery-stat
CREATE TABLE ph10_event.delivery_stat (
  tenant_id               varchar(16)   NOT NULL,
  subscription_code       varchar(63)   NOT NULL,
  window_start            timestamptz   NOT NULL,
  success_count           integer       NOT NULL DEFAULT 0,
  transient_error_count   integer       NOT NULL DEFAULT 0,
  retry_count             integer       NOT NULL DEFAULT 0,
  dead_letter_count       integer       NOT NULL DEFAULT 0,
  latency_p50_ms          integer,
  latency_p95_ms          integer,
  CONSTRAINT pk_delivery_stat PRIMARY KEY (tenant_id, subscription_code, window_start),
  CONSTRAINT ck_delivery_stat_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_delivery_stat_window CHECK (extract(second FROM window_start) = 0),
  CONSTRAINT ck_delivery_stat_counts CHECK (success_count >= 0 AND transient_error_count >= 0 AND retry_count >= 0 AND dead_letter_count >= 0),
  CONSTRAINT ck_delivery_stat_latency CHECK (latency_p50_ms IS NULL OR latency_p95_ms IS NULL OR latency_p95_ms >= latency_p50_ms)
) PARTITION BY RANGE (window_start);
CALL ph10_event.p_ensure_partitions('ph10_event.delivery_stat', current_date, 4, 'month');
CALL ph10_event.p_enable_rls('ph10_event.delivery_stat', 'P');
COMMENT ON TABLE ph10_event.delivery_stat IS 'EN-10-11 Thống kê giao nhận theo subscription, cửa sổ 1 phút (FR-10-056). Bộ giao nhận và cổng kéo gửi chỉ số; DeliveryStatConsumer ghi upsert. Khóa tự nhiên, không id (§1.3). Giữ 90 ngày, phân vùng tháng.';
--rollback DROP TABLE IF EXISTS ph10_event.delivery_stat CASCADE;

--changeset ph10:ph10-0510-delivery-failure
CREATE TABLE ph10_event.delivery_failure (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  subscription_code  varchar(63)   NOT NULL,
  occurred_at        timestamptz   NOT NULL,
  partition          integer       NOT NULL,
  record_offset      bigint        NOT NULL,
  event_id           varchar(255),
  http_status        smallint,
  error_code         varchar(16)   NOT NULL,
  failure_class      varchar(16)   NOT NULL,
  attempt            integer       NOT NULL,
  response_snippet   varchar(1024),
  CONSTRAINT pk_delivery_failure PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_delivery_failure_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_delivery_failure_class CHECK (failure_class IN ('TRANSIENT', 'PERMANENT', 'DESERIALIZATION', 'SECURITY')),
  CONSTRAINT ck_delivery_failure_code CHECK (error_code ~ '^ERR-10-[01][0-9]{2}$'),
  CONSTRAINT ck_delivery_failure_http CHECK (http_status IS NULL OR http_status BETWEEN 100 AND 599),
  CONSTRAINT ck_delivery_failure_attempt CHECK (attempt >= 1 AND partition >= 0 AND record_offset >= 0)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX ix_delivery_failure_sub ON ph10_event.delivery_failure (tenant_id, subscription_code, occurred_at DESC);
CREATE INDEX ix_delivery_failure_event ON ph10_event.delivery_failure (tenant_id, event_id) WHERE event_id IS NOT NULL;
CALL ph10_event.p_ensure_partitions('ph10_event.delivery_failure', current_date, 3, 'month');
CALL ph10_event.p_enable_rls('ph10_event.delivery_failure', 'P');
COMMENT ON TABLE ph10_event.delivery_failure IS 'EN-10-11 Lượt giao lỗi (FR-10-056, tab Lỗi gần đây UI-10-12). Chỉ thêm; giữ 30 ngày (DETACH phân vùng tháng quá hạn, tối đa 2 tháng trực tuyến).';
COMMENT ON COLUMN ph10_event.delivery_failure.record_offset IS 'Trường API offset; đổi tên vì OFFSET là từ khóa dành riêng của SQL (§1.3).';
COMMENT ON COLUMN ph10_event.delivery_failure.response_snippet IS '≤ 1 KiB đầu thân phản hồi của bên nhận, đã che theo mẫu bí mật; không chứa nội dung sự kiện.';
--rollback DROP TABLE IF EXISTS ph10_event.delivery_failure CASCADE;
