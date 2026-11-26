--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0060-dlq.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0600-replay-request
CREATE TABLE ph10_event.replay_request (
  id                   uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  replay_code          varchar(63)   NOT NULL,
  subscription_code    varchar(63)   NOT NULL,
  replay_mode          varchar(20)   NOT NULL,
  range_type           varchar(16)   NOT NULL,
  from_time            timestamptz,
  to_time              timestamptz,
  partitions           jsonb,
  dlq_entry_ids        uuid[],
  target_endpoint_url  varchar(2048),
  rate_per_second      integer       NOT NULL DEFAULT 2000,
  estimated_records    bigint,
  delivered_records    bigint        NOT NULL DEFAULT 0,
  failed_records       bigint        NOT NULL DEFAULT 0,
  previous_offsets     jsonb,
  reason               varchar(2000) NOT NULL,
  status               varchar(20)   NOT NULL DEFAULT 'PENDING_APPROVAL',
  started_at           timestamptz,
  finished_at          timestamptz,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  created_by           varchar(64)   NOT NULL,
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  updated_by           varchar(64)   NOT NULL,
  version              integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_replay_request PRIMARY KEY (id),
  CONSTRAINT uq_replay_request_code UNIQUE (tenant_id, replay_code),
  CONSTRAINT fk_replay_request_subscription FOREIGN KEY (tenant_id, subscription_code) REFERENCES ph10_event.subscription (tenant_id, subscription_code),
  CONSTRAINT ck_replay_request_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_replay_request_code CHECK (replay_code ~ '^rpl-[0-9a-hjkmnp-tv-z]{26}$'),
  CONSTRAINT ck_replay_request_status CHECK (status IN ('PENDING_APPROVAL', 'REJECTED', 'APPROVED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_replay_request_mode CHECK (replay_mode IN ('REDELIVER_RANGE', 'RESET_OFFSET', 'DLQ_ENTRIES')),
  CONSTRAINT ck_replay_request_range_type CHECK (range_type IN ('OFFSET', 'TIME', 'ENTRIES')),
  CONSTRAINT ck_replay_request_range CHECK (
       (replay_mode = 'DLQ_ENTRIES' AND range_type = 'ENTRIES' AND cardinality(dlq_entry_ids) BETWEEN 1 AND 1000)
    OR (replay_mode <> 'DLQ_ENTRIES' AND range_type = 'TIME' AND from_time IS NOT NULL AND (to_time IS NULL OR to_time > from_time))
    OR (replay_mode <> 'DLQ_ENTRIES' AND range_type = 'OFFSET' AND jsonb_typeof(partitions) = 'array' AND jsonb_array_length(partitions) >= 1)),
  CONSTRAINT ck_replay_request_target CHECK (target_endpoint_url IS NULL OR target_endpoint_url ~ '^https://'),
  CONSTRAINT ck_replay_request_rate CHECK (rate_per_second BETWEEN 10 AND 10000),
  CONSTRAINT ck_replay_request_estimated CHECK (estimated_records IS NULL OR estimated_records BETWEEN 0 AND 10000000),
  CONSTRAINT ck_replay_request_progress CHECK (delivered_records >= 0 AND failed_records >= 0),
  CONSTRAINT ck_replay_request_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_replay_request_reset CHECK (replay_mode <> 'RESET_OFFSET' OR status NOT IN ('RUNNING', 'COMPLETED') OR previous_offsets IS NOT NULL),
  CONSTRAINT ck_replay_request_started CHECK (status NOT IN ('RUNNING', 'COMPLETED', 'FAILED') OR started_at IS NOT NULL),
  CONSTRAINT ck_replay_request_finished CHECK ((status IN ('COMPLETED', 'FAILED', 'CANCELLED', 'REJECTED')) = (finished_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_replay_request_running ON ph10_event.replay_request (tenant_id, subscription_code) WHERE status IN ('APPROVED', 'RUNNING');
CREATE INDEX ix_replay_request_sub ON ph10_event.replay_request (tenant_id, subscription_code, created_at DESC);
CREATE INDEX ix_replay_request_status ON ph10_event.replay_request (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_replay_request_touch BEFORE UPDATE ON ph10_event.replay_request FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_replay_request_immutable BEFORE UPDATE ON ph10_event.replay_request FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('replay_code', 'tenant_id', 'subscription_code', 'replay_mode', 'range_type', 'from_time', 'to_time', 'partitions', 'dlq_entry_ids', 'reason', 'created_by');
CALL ph10_event.p_enable_rls('ph10_event.replay_request', 'P');
COMMENT ON TABLE ph10_event.replay_request IS 'EN-10-13 Lượt phát lại (FR-10-051…053). Phạm vi bất biến sau khi tạo; một lượt APPROVED hoặc RUNNING mỗi subscription. Lý do bắt buộc (BR-10-028). Nhóm tiêu thụ dh-replay-{tenant}-{replayCode}. Giữ 3 năm (nhật ký phát lại).';
COMMENT ON COLUMN ph10_event.replay_request.partitions IS 'Mảng {partition, fromOffset, toOffset} khi rangeType = OFFSET.';
COMMENT ON COLUMN ph10_event.replay_request.previous_offsets IS 'Offset đã commit của nhóm trước khi RESET_OFFSET, để quay lại (FR-10-053).';
--rollback DROP TABLE IF EXISTS ph10_event.replay_request CASCADE;

--changeset ph10:ph10-0610-dlq-entry
CREATE TABLE ph10_event.dlq_entry (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  subscription_code  varchar(63),
  source_topic       varchar(204)  NOT NULL,
  source_partition   integer,
  source_offset      bigint,
  event_id           varchar(255),
  event_type         varchar(255),
  event_subject      varchar(255),
  origin             varchar(20)   NOT NULL,
  error_code         varchar(16)   NOT NULL,
  error_detail       varchar(2000),
  attempts           integer       NOT NULL DEFAULT 1,
  first_failed_at    timestamptz   NOT NULL,
  last_failed_at     timestamptz   NOT NULL,
  status             varchar(20)   NOT NULL DEFAULT 'NEW',
  resolved_by        varchar(64),
  resolved_at        timestamptz,
  resolve_reason     varchar(2000),
  replay_code        varchar(63),
  payload_ref        varchar(255),
  payload_purged_at  timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_entry PRIMARY KEY (id),
  CONSTRAINT fk_dlq_entry_subscription FOREIGN KEY (tenant_id, subscription_code) REFERENCES ph10_event.subscription (tenant_id, subscription_code),
  CONSTRAINT fk_dlq_entry_topic FOREIGN KEY (tenant_id, source_topic) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT fk_dlq_entry_replay FOREIGN KEY (tenant_id, replay_code) REFERENCES ph10_event.replay_request (tenant_id, replay_code),
  CONSTRAINT ck_dlq_entry_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_dlq_entry_status CHECK (status IN ('NEW', 'REPLAY_PENDING', 'REPLAYED', 'DISCARDED', 'PURGED')),
  CONSTRAINT ck_dlq_entry_origin CHECK (origin IN ('PUSH', 'PULL_NACK', 'EXTERNAL_REPORT', 'REPLAY', 'BRIDGE')),
  CONSTRAINT ck_dlq_entry_code CHECK (error_code ~ '^ERR-10-[01][0-9]{2}$'),
  CONSTRAINT ck_dlq_entry_source CHECK (origin = 'BRIDGE' OR (subscription_code IS NOT NULL AND source_partition >= 0 AND source_offset >= 0)),
  CONSTRAINT ck_dlq_entry_bridge CHECK (origin <> 'BRIDGE' OR event_id IS NOT NULL),
  CONSTRAINT ck_dlq_entry_times CHECK (last_failed_at >= first_failed_at AND attempts >= 1),
  CONSTRAINT ck_dlq_entry_replay_code CHECK (status <> 'REPLAY_PENDING' OR replay_code IS NOT NULL),
  CONSTRAINT ck_dlq_entry_resolved CHECK ((status IN ('REPLAYED', 'DISCARDED', 'PURGED')) = (resolved_at IS NOT NULL)
                                          AND (status <> 'DISCARDED' OR (resolved_by IS NOT NULL AND resolve_reason IS NOT NULL))),
  CONSTRAINT ck_dlq_entry_purged CHECK ((status = 'PURGED') = (payload_purged_at IS NOT NULL) AND (status <> 'PURGED' OR payload_ref IS NULL)),
  CONSTRAINT ck_dlq_entry_payload_ref CHECK (payload_ref IS NULL OR payload_ref = 'pg:dlq_payload/' || id::text)
);
CREATE UNIQUE INDEX uq_dlq_entry_source ON ph10_event.dlq_entry (tenant_id, subscription_code, source_topic, source_partition, source_offset) WHERE origin <> 'BRIDGE';
CREATE UNIQUE INDEX uq_dlq_entry_bridge ON ph10_event.dlq_entry (tenant_id, source_topic, event_id) WHERE origin = 'BRIDGE';
CREATE INDEX ix_dlq_entry_new ON ph10_event.dlq_entry (tenant_id, subscription_code, first_failed_at) WHERE status = 'NEW';
CREATE INDEX ix_dlq_entry_topic ON ph10_event.dlq_entry (tenant_id, source_topic, status, first_failed_at DESC);
CREATE INDEX ix_dlq_entry_error ON ph10_event.dlq_entry (tenant_id, error_code, first_failed_at DESC);
CREATE INDEX ix_dlq_entry_event ON ph10_event.dlq_entry (tenant_id, event_id) WHERE event_id IS NOT NULL;
CREATE INDEX ix_dlq_entry_subject ON ph10_event.dlq_entry (tenant_id, event_subject) WHERE event_subject IS NOT NULL;
CREATE INDEX ix_dlq_entry_replay ON ph10_event.dlq_entry (tenant_id, replay_code) WHERE replay_code IS NOT NULL;
CREATE INDEX ix_dlq_entry_purge_due ON ph10_event.dlq_entry (resolved_at) WHERE status IN ('REPLAYED', 'DISCARDED');
CREATE TRIGGER tg_dlq_entry_touch BEFORE UPDATE ON ph10_event.dlq_entry FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_dlq_entry_immutable BEFORE UPDATE ON ph10_event.dlq_entry FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('tenant_id', 'subscription_code', 'source_topic', 'source_partition', 'source_offset', 'event_id', 'origin', 'first_failed_at');
CALL ph10_event.p_enable_rls('ph10_event.dlq_entry', 'P');
COMMENT ON TABLE ph10_event.dlq_entry IS 'EN-10-12 Mục DLQ, nguồn sự thật của DLQ tầng sự kiện (FR-10-049, 050; BR-10-024; ADR-071). DlqWriter tiêu thụ {topicName}.dlq, upsert theo (subscription, topic, partition, offset) nên chạy lại không nhân đôi. id chính là dlqEntryId (UUIDv7). NEW giữ vô thời hạn; siêu dữ liệu giữ 1 năm sau khi xử lý.';
COMMENT ON COLUMN ph10_event.dlq_entry.subscription_code IS 'NULL chỉ với origin BRIDGE (lỗi chuyển bản tin của cầu nối, ERR-10-118); đề nghị FRS bổ sung bridgeCode (§9.2).';
COMMENT ON COLUMN ph10_event.dlq_entry.payload_ref IS 'pg:dlq_payload/{dlqEntryId}; NULL sau khi dọn nội dung (PURGED).';
--rollback DROP TABLE IF EXISTS ph10_event.dlq_entry CASCADE;

--changeset ph10:ph10-0611-dlq-payload
CREATE TABLE ph10_event.dlq_payload (
  dlq_entry_id         uuid          NOT NULL,
  tenant_id            varchar(16)   NOT NULL,
  record_key           bytea,
  headers              jsonb         NOT NULL DEFAULT '{}',
  value                bytea         NOT NULL,
  transit_key_version  integer,
  size_bytes           integer       NOT NULL,
  content_hash         char(64)      NOT NULL,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_dlq_payload PRIMARY KEY (dlq_entry_id),
  CONSTRAINT fk_dlq_payload_entry FOREIGN KEY (dlq_entry_id) REFERENCES ph10_event.dlq_entry (id) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_payload_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_dlq_payload_size CHECK (size_bytes BETWEEN 0 AND 1048576 AND octet_length(value) <= 1468006),
  CONSTRAINT ck_dlq_payload_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_payload_headers CHECK (jsonb_typeof(headers) = 'object' AND NOT (headers ?| ARRAY['authorization', 'Authorization'])),
  CONSTRAINT ck_dlq_payload_transit CHECK (transit_key_version IS NULL OR transit_key_version >= 1)
);
ALTER TABLE ph10_event.dlq_payload ALTER COLUMN value SET STORAGE EXTERNAL;
CALL ph10_event.p_enable_rls('ph10_event.dlq_payload', 'P');
COMMENT ON TABLE ph10_event.dlq_payload IS 'Nội dung bản tin gốc của mục DLQ (FR-10-049 bước 2), tách khỏi dlq_entry để quyền đọc riêng (ph10_readonly không đọc) và dọn riêng (DlqPayloadPurgeJob xóa dòng sau 10.dlq.payload-retention-days-after-resolve). Không có cột sửa: chỉ thêm, xóa.';
COMMENT ON COLUMN ph10_event.dlq_payload.value IS 'Giá trị nhị phân nguyên vẹn; với topic RESTRICTED, SENSITIVE là bản mã OpenBao transit/dh-{tenant}-event-dlq (vault:v{n}:..., tăng khoảng 4/3 do base64).';
COMMENT ON COLUMN ph10_event.dlq_payload.transit_key_version IS 'Phiên bản khóa transit đã mã hóa; NULL khi topic PUBLIC, INTERNAL (chỉ mã hóa mức đĩa của pg-core).';
COMMENT ON COLUMN ph10_event.dlq_payload.headers IS 'Tiêu đề Kafka (ce_*, dh_dlq_*) dạng chuỗi; không giữ tiêu đề Authorization.';
--rollback DROP TABLE IF EXISTS ph10_event.dlq_payload CASCADE;

--changeset ph10:ph10-0620-lag-sample
CREATE TABLE ph10_event.lag_sample (
  tenant_id          varchar(16)   NOT NULL,
  subscription_code  varchar(63)   NOT NULL,
  consumer_group     varchar(255)  NOT NULL,
  sampled_at         timestamptz   NOT NULL,
  partition          integer       NOT NULL,
  lag_records        bigint        NOT NULL,
  lag_seconds        integer       NOT NULL,
  committed_offset   bigint,
  end_offset         bigint        NOT NULL,
  CONSTRAINT pk_lag_sample PRIMARY KEY (tenant_id, subscription_code, partition, sampled_at),
  CONSTRAINT ck_lag_sample_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_lag_sample_values CHECK (partition >= 0 AND lag_records >= 0 AND lag_seconds >= 0 AND end_offset >= 0
                                         AND (lag_records > 0 OR lag_seconds = 0))
) PARTITION BY RANGE (sampled_at);
CREATE INDEX ix_lag_sample_time ON ph10_event.lag_sample (tenant_id, sampled_at DESC);
CALL ph10_event.p_ensure_partitions('ph10_event.lag_sample', current_date - 1, 4, 'day');
CALL ph10_event.p_enable_rls('ph10_event.lag_sample', 'P');
COMMENT ON TABLE ph10_event.lag_sample IS 'EN-10-14 Mẫu lag thô theo phân vùng, chu kỳ 10.lag.collect-interval-seconds (FR-10-054). Giữ 48 giờ: phân vùng ngày, DROP phân vùng cũ hơn 2 ngày. Khóa tự nhiên (§1.3).';
--rollback DROP TABLE IF EXISTS ph10_event.lag_sample CASCADE;

--changeset ph10:ph10-0621-lag-sample-5m
CREATE TABLE ph10_event.lag_sample_5m (
  tenant_id          varchar(16)   NOT NULL,
  subscription_code  varchar(63)   NOT NULL,
  window_start       timestamptz   NOT NULL,
  lag_records        bigint        NOT NULL,
  lag_seconds        integer       NOT NULL,
  alert_state        varchar(16)   NOT NULL,
  CONSTRAINT pk_lag_sample_5m PRIMARY KEY (tenant_id, subscription_code, window_start),
  CONSTRAINT ck_lag_sample_5m_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_lag_sample_5m_alert_state CHECK (alert_state IN ('OK', 'WARNING', 'CRITICAL', 'STALLED')),
  CONSTRAINT ck_lag_sample_5m_window CHECK (extract(epoch FROM window_start)::bigint % 300 = 0)
) PARTITION BY RANGE (window_start);
CALL ph10_event.p_ensure_partitions('ph10_event.lag_sample_5m', current_date, 4, 'month');
CALL ph10_event.p_enable_rls('ph10_event.lag_sample_5m', 'P');
COMMENT ON TABLE ph10_event.lag_sample_5m IS 'Gộp 5 phút của lag_sample theo subscription (giá trị lớn nhất qua các phân vùng và trong cửa sổ), cho biểu đồ xu hướng UI-10-17. Giữ 90 ngày. Bảng kỹ thuật FRS chưa đặt tên (đề nghị bổ sung §9.2).';
--rollback DROP TABLE IF EXISTS ph10_event.lag_sample_5m CASCADE;
