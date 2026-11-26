-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national
-- Tệp 40: đồng bộ, sổ giao dịch, mức dùng, sức khỏe, cảnh báo bất thường, chạy song song,
--         nhập hệ cũ, outbox, khóa tác vụ.
-- Các bảng khối lượng lớn (national_transaction, usage_hourly, health_sample, parallel_sample)
-- phân vùng theo tháng; dữ liệu do cổng sinh ra đến qua Kafka, dh-integration ghi lũy đẳng.
-- Chạy sau ph14_30_quota_inbound.sql.
-- =============================================================================

\set ON_ERROR_STOP on
SET ROLE ph14_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 14-0040-sync.sql
-- @changeset ph14-0400-sync-run
CREATE TABLE ph14_national.sync_run (
  id            uuid          NOT NULL,
  tenant_id     varchar(16)   NOT NULL,
  platform_id   uuid          NOT NULL,
  kind          varchar(16)   NOT NULL,
  trigger_kind  varchar(10)   NOT NULL,
  state         varchar(24)   NOT NULL DEFAULT 'PLANNED',
  dry_run       boolean       NOT NULL DEFAULT false,
  only_changed  boolean       NOT NULL DEFAULT true,
  batch_ref     varchar(255),
  command_id    uuid,
  retry_of      uuid,
  attempt       smallint      NOT NULL DEFAULT 1,
  sent          integer       NOT NULL DEFAULT 0,
  accepted      integer       NOT NULL DEFAULT 0,
  rejected      integer       NOT NULL DEFAULT 0,
  pending       integer       NOT NULL DEFAULT 0,
  error_count   integer       NOT NULL DEFAULT 0,
  error_summary varchar(1000),
  triggered_by  varchar(64)   NOT NULL,
  started_at    timestamptz,
  finished_at   timestamptz,
  created_at    timestamptz   NOT NULL DEFAULT now(),
  created_by    varchar(64)   NOT NULL,
  updated_at    timestamptz   NOT NULL DEFAULT now(),
  updated_by    varchar(64)   NOT NULL,
  version       integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_run PRIMARY KEY (id),
  CONSTRAINT uq_sync_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_sync_run_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_sync_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sync_run_kind CHECK (kind IN ('SERVICE_CATALOG', 'MASTER_DATA', 'OPEN_DATA')),
  CONSTRAINT ck_sync_run_trigger CHECK (trigger_kind IN ('SCHEDULE', 'EVENT', 'MANUAL', 'RETRY')),
  CONSTRAINT ck_sync_run_state CHECK (state IN ('PLANNED', 'RUNNING', 'COMPLETED', 'COMPLETED_WITH_ERRORS', 'FAILED')),
  CONSTRAINT ck_sync_run_batch CHECK (batch_ref IS NULL OR batch_ref LIKE (lower(tenant_id) || '/%')),
  CONSTRAINT ck_sync_run_counts CHECK (sent >= 0 AND accepted >= 0 AND rejected >= 0 AND pending >= 0 AND error_count >= 0 AND error_count <= rejected),
  CONSTRAINT ck_sync_run_reconcile CHECK (state NOT IN ('COMPLETED', 'COMPLETED_WITH_ERRORS') OR sent = accepted + rejected + pending),
  CONSTRAINT ck_sync_run_completed CHECK (state <> 'COMPLETED' OR (rejected = 0 AND pending = 0)),
  CONSTRAINT ck_sync_run_retry CHECK ((trigger_kind = 'RETRY') = (retry_of IS NOT NULL) AND attempt >= 1),
  CONSTRAINT ck_sync_run_finished CHECK ((state IN ('COMPLETED', 'COMPLETED_WITH_ERRORS', 'FAILED')) = (finished_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_sync_run_open ON ph14_national.sync_run (tenant_id, kind) WHERE state IN ('PLANNED', 'RUNNING');
CREATE INDEX ix_sync_run_kind ON ph14_national.sync_run (tenant_id, kind, created_at DESC);
CREATE INDEX ix_sync_run_success ON ph14_national.sync_run (tenant_id, kind, finished_at DESC) WHERE state IN ('COMPLETED', 'COMPLETED_WITH_ERRORS');
CREATE TRIGGER tg_sync_run_touch BEFORE UPDATE ON ph14_national.sync_run FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.sync_run', 'P');
COMMENT ON TABLE ph14_national.sync_run IS 'EN-14-10 Phiên đồng bộ danh mục dịch vụ, dữ liệu chủ, dữ liệu mở (FR-14-043, 044, 045, 046). Mỗi (tenant, loại) tối đa một phiên chưa kết thúc (ERR-14-026). Đối soát: gửi = nhận + từ chối + chờ; error_count là phần lỗi kỹ thuật nằm trong rejected. Giữ 3 năm. Phiên đối chiếu danh mục (SERVICE_RECONCILE) lưu ở reconcile_run.';
COMMENT ON COLUMN ph14_national.sync_run.batch_ref IS 'Khóa đối tượng lô bản ghi trong bucket dh-nat-sync, bắt đầu bằng tiền tố tenant.';
COMMENT ON COLUMN ph14_national.sync_run.retry_of IS 'Phiên gốc khi thử lại chỉ các bản ghi lỗi (tối đa 14.sync.max-retries).';
-- @rollback DROP TABLE IF EXISTS ph14_national.sync_run CASCADE;

-- @changeset ph14-0410-sync-record
CREATE TABLE ph14_national.sync_record (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  run_id           uuid          NOT NULL,
  record_kind      varchar(14)   NOT NULL,
  record_ref       varchar(128)  NOT NULL,
  content_hash     char(64)      NOT NULL,
  outcome          varchar(16)   NOT NULL DEFAULT 'PENDING',
  receipt_ref      varchar(128),
  error_code       varchar(16),
  error_message    varchar(500),
  attempts         smallint      NOT NULL DEFAULT 0,
  last_attempt_at  timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_record PRIMARY KEY (id),
  CONSTRAINT uq_sync_record UNIQUE (tenant_id, run_id, record_ref),
  CONSTRAINT fk_sync_record_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph14_national.sync_run (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_sync_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sync_record_kind CHECK (record_kind IN ('SERVICE', 'MASTER_RECORD', 'DATASET')),
  CONSTRAINT ck_sync_record_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_sync_record_outcome CHECK (outcome IN ('PENDING', 'ACCEPTED', 'REJECTED', 'REJECTED_LOCAL', 'ERROR')),
  CONSTRAINT ck_sync_record_attempts CHECK (attempts >= 0)
);
CREATE INDEX ix_sync_record_outcome ON ph14_national.sync_record (tenant_id, run_id, outcome) WHERE outcome <> 'ACCEPTED';
CREATE INDEX ix_sync_record_ref ON ph14_national.sync_record (tenant_id, record_kind, record_ref, created_at DESC);
CREATE TRIGGER tg_sync_record_touch BEFORE UPDATE ON ph14_national.sync_record FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.sync_record', 'P');
COMMENT ON TABLE ph14_national.sync_record IS 'Kết quả từng bản ghi trong một phiên đồng bộ: nhận, từ chối, lỗi, kèm biên nhận để đối soát (FR-14-043, 046). content_hash dùng chọn bản ghi mới hoặc đổi (onlyChanged). Xóa theo phiên khi quá 3 năm.';
COMMENT ON COLUMN ph14_national.sync_record.record_ref IS 'Mã dịch vụ chia sẻ, khóa bản ghi dữ liệu chủ hoặc mã tập dữ liệu mở; không chứa dữ liệu cá nhân.';
-- @rollback DROP TABLE IF EXISTS ph14_national.sync_record CASCADE;

-- @file 14-0041-transaction.sql
-- @changeset ph14-0420-national-transaction splitStatements:false
-- Hạng tiến trình của giao dịch chiều ra: RECEIVED 10 < SENT 20 < TIMEOUT 30 < UNKNOWN_RESULT 40 < trạng thái cuối 90 (SDD §8.1).
-- Dùng cả cho cột sinh và cho trigger vì giá trị cột sinh chưa được tính khi BEFORE UPDATE chạy.
CREATE OR REPLACE FUNCTION ph14_national.f_txn_rank(p_state text) RETURNS smallint
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT (CASE p_state WHEN 'RECEIVED' THEN 10 WHEN 'SENT' THEN 20 WHEN 'TIMEOUT' THEN 30 WHEN 'UNKNOWN_RESULT' THEN 40 ELSE 90 END)::smallint
$f$;
COMMENT ON FUNCTION ph14_national.f_txn_rank(text) IS 'Hạng tiến trình của trạng thái giao dịch; bản ghi hạng thấp hơn đến muộn bị bỏ.';
CREATE TABLE ph14_national.national_transaction (
  tenant_id         varchar(16)   NOT NULL,
  transaction_code  varchar(40)   NOT NULL,
  started_at        timestamptz   NOT NULL,
  direction         varchar(8)    NOT NULL,
  platform_code     varchar(63)   NOT NULL,
  service_code      varchar(63)   NOT NULL,
  operation         varchar(63),
  operation_type    varchar(5)    NOT NULL,
  system_code       varchar(64)   NOT NULL,
  purpose_code      varchar(64),
  procedure_code    varchar(64),
  case_code         varchar(128),
  state             varchar(20)   NOT NULL,
  state_rank        smallint      GENERATED ALWAYS AS (ph14_national.f_txn_rank(state)) STORED,
  from_cache        boolean       NOT NULL DEFAULT false,
  stale             boolean       NOT NULL DEFAULT false,
  routed_via        varchar(63),
  duration_ms       integer,
  error_code        varchar(16),
  cert_code         varchar(63),
  sign_result       varchar(6)    NOT NULL DEFAULT 'NA',
  verify_result     varchar(6)    NOT NULL DEFAULT 'NA',
  trace_id          char(32)      NOT NULL,
  payload_ref       varchar(255),
  payload_hash      char(64),
  lookup_key_hash   char(64),
  idempotency_key   varchar(64),
  finished_at       timestamptz,
  ingested_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_national_transaction PRIMARY KEY (tenant_id, transaction_code, started_at),
  CONSTRAINT ck_national_transaction_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_national_transaction_code CHECK (transaction_code ~ '^[A-Za-z0-9-]{10,40}$'),
  CONSTRAINT ck_national_transaction_direction CHECK (direction IN ('OUTBOUND', 'INBOUND')),
  CONSTRAINT ck_national_transaction_optype CHECK (operation_type IN ('READ', 'WRITE')),
  CONSTRAINT ck_national_transaction_state CHECK (state IN ('RECEIVED', 'REJECTED', 'COMPLETED_CACHE', 'QUOTA_EXCEEDED', 'SENT', 'SUCCEEDED', 'FAILED',
                                                            'TIMEOUT', 'SIGNATURE_FAILED', 'UNKNOWN_RESULT')),
  CONSTRAINT ck_national_transaction_unknown CHECK (state <> 'UNKNOWN_RESULT' OR operation_type = 'WRITE'),
  CONSTRAINT ck_national_transaction_cache CHECK ((state = 'COMPLETED_CACHE') = from_cache AND (NOT stale OR from_cache) AND (NOT from_cache OR operation_type = 'READ')),
  CONSTRAINT ck_national_transaction_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CONSTRAINT ck_national_transaction_sign CHECK (sign_result IN ('NA', 'OK', 'FAILED') AND verify_result IN ('NA', 'OK', 'FAILED')),
  CONSTRAINT ck_national_transaction_sigfail CHECK (state <> 'SIGNATURE_FAILED' OR verify_result = 'FAILED'),
  CONSTRAINT ck_national_transaction_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_national_transaction_payload CHECK ((payload_ref IS NULL) = (payload_hash IS NULL)
                                                    AND (payload_ref IS NULL OR payload_ref LIKE (lower(tenant_id) || '/%'))
                                                    AND (payload_hash IS NULL OR payload_hash ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_national_transaction_lookup CHECK (lookup_key_hash IS NULL OR lookup_key_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_national_transaction_finished CHECK ((state_rank >= 90 OR (state = 'TIMEOUT' AND operation_type = 'READ')) = (finished_at IS NOT NULL))
) PARTITION BY RANGE (started_at);
CALL ph14_national.p_ensure_month_partitions('ph14_national.national_transaction', current_date - 31, 5);
CREATE INDEX ix_national_transaction_started ON ph14_national.national_transaction (tenant_id, started_at DESC);
CREATE INDEX ix_national_transaction_code ON ph14_national.national_transaction (tenant_id, transaction_code);
CREATE INDEX ix_national_transaction_system ON ph14_national.national_transaction (tenant_id, system_code, started_at DESC);
CREATE INDEX ix_national_transaction_service ON ph14_national.national_transaction (tenant_id, service_code, started_at DESC);
CREATE INDEX ix_national_transaction_case ON ph14_national.national_transaction (tenant_id, case_code, started_at DESC) WHERE case_code IS NOT NULL;
CREATE INDEX ix_national_transaction_unknown ON ph14_national.national_transaction (tenant_id, started_at) WHERE state = 'UNKNOWN_RESULT';
CREATE INDEX ix_national_transaction_lookup ON ph14_national.national_transaction (tenant_id, system_code, started_at DESC) INCLUDE (lookup_key_hash) WHERE lookup_key_hash IS NOT NULL;
CREATE INDEX ix_national_transaction_trace ON ph14_national.national_transaction (trace_id);
CREATE OR REPLACE FUNCTION ph14_national.tg_transaction_forward() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'Sổ giao dịch không cho xóa dòng; hết hạn thì tháo phân vùng (BR-14-020)' USING ERRCODE = '55000';
  END IF;
  IF ph14_national.f_txn_rank(NEW.state) <= OLD.state_rank THEN
    RAISE EXCEPTION 'Giao dịch % chỉ chuyển trạng thái tiến (% sang %)', OLD.transaction_code, OLD.state, NEW.state USING ERRCODE = '55000';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['state', 'state_rank', 'from_cache', 'stale', 'routed_via', 'duration_ms', 'error_code', 'cert_code', 'sign_result',
                            'verify_result', 'payload_ref', 'payload_hash', 'finished_at', 'ingested_at'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['state', 'state_rank', 'from_cache', 'stale', 'routed_via', 'duration_ms', 'error_code', 'cert_code', 'sign_result',
                            'verify_result', 'payload_ref', 'payload_hash', 'finished_at', 'ingested_at']) THEN
    RAISE EXCEPTION 'Giao dịch %: chỉ các cột kết quả được cập nhật, định danh và mục đích bất biến', OLD.transaction_code USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_national_transaction_forward BEFORE UPDATE OR DELETE ON ph14_national.national_transaction FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_transaction_forward();
CALL ph14_national.p_enable_rls('ph14_national.national_transaction', 'P');
COMMENT ON TABLE ph14_national.national_transaction IS 'EN-14-08 Sổ giao dịch quốc gia: mỗi lượt gọi ra hoặc nhận vào một dòng với mã đối soát, mục đích, mã hồ sơ, kết quả ký, xác minh (FR-14-010, 049, 050, 051, 052; BR-14-020). Chỉ siêu dữ liệu, không có nội dung hay định danh thô (BR-14-021). Phân vùng tháng theo started_at; 12 tháng trực tuyến rồi xuất WORM 5 năm trước khi tháo phân vùng (SEC-62). Không xóa dòng; chỉ chuyển trạng thái tiến (UPSERT của LedgerConsumer).';
COMMENT ON COLUMN ph14_national.national_transaction.transaction_code IS 'Mã giao dịch duy nhất, gửi trung ương làm mã đối soát; cùng started_at ổn định qua mọi bản ghi của giao dịch nên làm khóa UPSERT.';
COMMENT ON COLUMN ph14_national.national_transaction.system_code IS 'HTTT của tỉnh gọi (chiều ra) hoặc mã đơn vị gửi của trung ương (chiều vào); lấy từ token, không từ nội dung yêu cầu (BR-14-007).';
COMMENT ON COLUMN ph14_national.national_transaction.state_rank IS 'Hạng tiến trình sinh từ state (RECEIVED 10 < SENT 20 < TIMEOUT 30 < UNKNOWN_RESULT 40 < trạng thái cuối 90); bản ghi hạng thấp hơn đến muộn bị bỏ.';
COMMENT ON COLUMN ph14_national.national_transaction.lookup_key_hash IS 'HMAC-SHA256 định danh đối tượng được tra bằng khóa tenant, để đếm đối tượng khác nhau mà không lưu định danh (SEC-60, THR-54, FR-14-053); không cấp cho ph14_readonly.';
COMMENT ON COLUMN ph14_national.national_transaction.payload_ref IS 'Khóa đối tượng nội dung mã hóa ở dh-nat-payload dạng {tenant}/{yyyy}/{MM}/{code}.req.enc; rỗng khi không lưu hoặc hàng đệm đầy (ERR-14-031).';
COMMENT ON COLUMN ph14_national.national_transaction.stale IS 'true: phục vụ từ dữ liệu đệm quá hạn có cờ (BR-14-016); chỉ khi from_cache.';
-- @rollback DROP TABLE IF EXISTS ph14_national.national_transaction CASCADE; DROP FUNCTION IF EXISTS ph14_national.tg_transaction_forward(); DROP FUNCTION IF EXISTS ph14_national.f_txn_rank(text);

-- @changeset ph14-0430-usage-hourly
CREATE TABLE ph14_national.usage_hourly (
  tenant_id         varchar(16)   NOT NULL,
  hour_start        timestamptz   NOT NULL,
  system_code       varchar(64)   NOT NULL,
  service_code      varchar(63)   NOT NULL,
  purpose_code      varchar(64)   NOT NULL DEFAULT '',
  outcome           varchar(20)   NOT NULL,
  from_cache        boolean       NOT NULL DEFAULT false,
  calls             bigint        NOT NULL DEFAULT 0,
  stale_calls       bigint        NOT NULL DEFAULT 0,
  duration_sum_ms   bigint        NOT NULL DEFAULT 0,
  duration_max_ms   integer       NOT NULL DEFAULT 0,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_usage_hourly PRIMARY KEY (tenant_id, hour_start, system_code, service_code, purpose_code, outcome, from_cache),
  CONSTRAINT ck_usage_hourly_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_usage_hourly_hour CHECK (hour_start = date_trunc('hour', hour_start)),
  CONSTRAINT ck_usage_hourly_outcome CHECK (outcome IN ('REJECTED', 'COMPLETED_CACHE', 'QUOTA_EXCEEDED', 'SUCCEEDED', 'FAILED', 'TIMEOUT', 'SIGNATURE_FAILED', 'UNKNOWN_RESULT')),
  CONSTRAINT ck_usage_hourly_counts CHECK (calls >= 0 AND stale_calls >= 0 AND stale_calls <= calls AND duration_sum_ms >= 0 AND duration_max_ms >= 0)
) PARTITION BY RANGE (hour_start);
CALL ph14_national.p_ensure_month_partitions('ph14_national.usage_hourly', current_date - 31, 5);
CREATE INDEX ix_usage_hourly_system ON ph14_national.usage_hourly (tenant_id, system_code, hour_start DESC);
CREATE INDEX ix_usage_hourly_service ON ph14_national.usage_hourly (tenant_id, service_code, hour_start DESC);
CALL ph14_national.p_enable_rls('ph14_national.usage_hourly', 'P');
COMMENT ON TABLE ph14_national.usage_hourly IS 'Tổng hợp lượt gọi theo (giờ, HTTT, dịch vụ, mục đích, kết quả, nguồn đệm) cho báo cáo sử dụng và đường chuẩn phát hiện bất thường (FR-14-052, 053, 057). UsageAggregator chỉ cộng khi dòng giao dịch vừa được chèn nên đúng cả khi Kafka giao lại. Phân vùng tháng, giữ 24 tháng (giả định, khớp mức dùng hạn mức 2 năm NFR-14-021).';
COMMENT ON COLUMN ph14_national.usage_hourly.purpose_code IS 'Chuỗi rỗng khi lượt không khai mục đích (bị từ chối); là một phần khóa nên không dùng NULL.';
-- @rollback DROP TABLE IF EXISTS ph14_national.usage_hourly CASCADE;

-- @file 14-0042-health.sql
-- @changeset ph14-0440-health-sample
CREATE TABLE ph14_national.health_sample (
  tenant_id            varchar(16)   NOT NULL,
  platform_id          uuid          NOT NULL,
  env                  varchar(8)    NOT NULL,
  granularity          varchar(6)    NOT NULL DEFAULT 'MINUTE',
  probe_kind           varchar(8)    NOT NULL,
  sampled_at           timestamptz   NOT NULL,
  ok                   boolean       NOT NULL,
  level                varchar(10)   NOT NULL,
  failed_step          varchar(5),
  dns_ms               integer,
  tcp_ms               integer,
  tls_ms               integer,
  token_ms             integer,
  deep_ms              integer,
  tls_server_not_after timestamptz,
  calls_ok             integer       NOT NULL DEFAULT 0,
  calls_error          integer       NOT NULL DEFAULT 0,
  p95_ms               integer,
  CONSTRAINT pk_health_sample PRIMARY KEY (tenant_id, platform_id, env, granularity, probe_kind, sampled_at),
  CONSTRAINT ck_health_sample_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_health_sample_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_health_sample_granularity CHECK (granularity IN ('MINUTE', 'HOUR')),
  CONSTRAINT ck_health_sample_kind CHECK (probe_kind IN ('ACTIVE', 'PASSIVE', 'MANUAL')),
  CONSTRAINT ck_health_sample_level CHECK (level IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY', 'UNKNOWN')),
  CONSTRAINT ck_health_sample_step CHECK (failed_step IS NULL OR failed_step IN ('DNS', 'TCP', 'TLS', 'TOKEN', 'DEEP')),
  CONSTRAINT ck_health_sample_ok CHECK (ok = (failed_step IS NULL)),
  CONSTRAINT ck_health_sample_counts CHECK (calls_ok >= 0 AND calls_error >= 0)
) PARTITION BY RANGE (sampled_at);
CALL ph14_national.p_ensure_month_partitions('ph14_national.health_sample', current_date - 31, 5);
CALL ph14_national.p_enable_rls('ph14_national.health_sample', 'P');
COMMENT ON TABLE ph14_national.health_sample IS 'Mẫu kiểm tra kết nối chủ động, thụ động hoặc thủ công theo từng bước DNS, TCP, TLS, token, deep (FR-14-047, 048). Giữ 90 ngày, gộp theo giờ (granularity HOUR) sau 7 ngày bởi HealthRollupJob; DETACH phân vùng quá hạn. Không có bí mật hay token.';
COMMENT ON COLUMN ph14_national.health_sample.tls_server_not_after IS 'Hạn chứng thư máy chủ của nền tảng quan sát ở bước TLS, để cảnh báo trước khi trung ương đổi chứng thư.';
-- @rollback DROP TABLE IF EXISTS ph14_national.health_sample CASCADE;

-- @changeset ph14-0450-health-state
CREATE TABLE ph14_national.health_state (
  tenant_id            varchar(16)   NOT NULL,
  platform_id          uuid          NOT NULL,
  env                  varchar(8)    NOT NULL,
  level                varchar(10)   NOT NULL DEFAULT 'UNKNOWN',
  since_at             timestamptz   NOT NULL DEFAULT now(),
  last_probe_at        timestamptz,
  last_ok_at           timestamptz,
  consecutive_failures smallint      NOT NULL DEFAULT 0,
  reason               varchar(255),
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_health_state PRIMARY KEY (tenant_id, platform_id, env),
  CONSTRAINT fk_health_state_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_health_state_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_health_state_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_health_state_level CHECK (level IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY', 'UNKNOWN')),
  CONSTRAINT ck_health_state_failures CHECK (consecutive_failures >= 0)
);
CALL ph14_national.p_enable_rls('ph14_national.health_state', 'P');
COMMENT ON TABLE ph14_national.health_state IS 'Mức sức khỏe hiện hành của mỗi (nền tảng, môi trường) do HealthStateStore ghi từ kết quả của worker (FR-14-047, 048); chống dao động bằng consecutive_failures (hai chu kỳ để xuống UNHEALTHY, một chu kỳ để lên). Dùng cho UI-14-01, 02.';
-- @rollback DROP TABLE IF EXISTS ph14_national.health_state CASCADE;

-- @changeset ph14-0460-platform-outage
CREATE TABLE ph14_national.platform_outage (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  platform_id       uuid          NOT NULL,
  env               varchar(8)    NOT NULL,
  cause             varchar(14)   NOT NULL,
  started_at        timestamptz   NOT NULL,
  ended_at          timestamptz,
  duration_seconds  integer       GENERATED ALWAYS AS (extract(epoch FROM (ended_at - started_at))::integer) STORED,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_platform_outage PRIMARY KEY (id),
  CONSTRAINT fk_platform_outage_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_platform_outage_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_platform_outage_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_platform_outage_cause CHECK (cause IN ('PROBE', 'PASSIVE', 'SECURITY_HOLD', 'MANUAL_SUSPEND')),
  CONSTRAINT ck_platform_outage_range CHECK (ended_at IS NULL OR ended_at >= started_at)
);
CREATE UNIQUE INDEX uq_platform_outage_open ON ph14_national.platform_outage (tenant_id, platform_id, env, cause) WHERE ended_at IS NULL;
CREATE INDEX ix_platform_outage_platform ON ph14_national.platform_outage (tenant_id, platform_id, env, started_at DESC);
CALL ph14_national.p_enable_rls('ph14_national.platform_outage', 'P');
COMMENT ON TABLE ph14_national.platform_outage IS 'Khoảng gián đoạn của nền tảng (OutageRecorder) để tính sẵn sàng 99,9% (NFR-14-008) và báo cáo cho lãnh đạo (FR-14-048). Thời gian nền tảng quốc gia ngừng không tính vào chỉ tiêu của Datahub. Giữ 3 năm (giả định).';
-- @rollback DROP TABLE IF EXISTS ph14_national.platform_outage CASCADE;

-- @file 14-0043-anomaly.sql
-- @changeset ph14-0470-anomaly-alert
CREATE TABLE ph14_national.anomaly_alert (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  system_code      varchar(64)   NOT NULL,
  service_code     varchar(63)   NOT NULL,
  rule             varchar(16)   NOT NULL,
  window_start     timestamptz   NOT NULL,
  window_end       timestamptz   NOT NULL,
  evidence         jsonb         NOT NULL DEFAULT '{}',
  state            varchar(8)    NOT NULL DEFAULT 'OPEN',
  decision         varchar(24),
  decision_reason  varchar(1000),
  decided_by       varchar(64),
  decided_at       timestamptz,
  detected_at      timestamptz   NOT NULL DEFAULT now(),
  notified_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_anomaly_alert PRIMARY KEY (id),
  CONSTRAINT uq_anomaly_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_anomaly_alert_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_anomaly_alert_rule CHECK (rule IN ('MASS_LOOKUP', 'OFF_HOURS', 'SPIKE', 'CASE_FANOUT')),
  CONSTRAINT ck_anomaly_alert_window CHECK (window_end > window_start),
  CONSTRAINT ck_anomaly_alert_evidence CHECK (jsonb_typeof(evidence) = 'object' AND NOT (evidence ?| ARRAY['subject', 'citizenId', 'idNumber', 'payload', 'lookupKey'])),
  CONSTRAINT ck_anomaly_alert_state CHECK (state IN ('OPEN', 'RESOLVED')),
  CONSTRAINT ck_anomaly_alert_decision CHECK (decision IS NULL OR decision IN ('CONFIRMED_LEGITIMATE', 'REVOKE_REQUESTED', 'SERVICE_BLOCKED')),
  CONSTRAINT ck_anomaly_alert_resolved CHECK ((state = 'RESOLVED') = (decision IS NOT NULL AND decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_anomaly_alert_reason CHECK (state <> 'RESOLVED' OR coalesce(char_length(decision_reason), 0) >= 10)
);
CREATE UNIQUE INDEX uq_anomaly_alert_open ON ph14_national.anomaly_alert (tenant_id, system_code, service_code, rule) WHERE state = 'OPEN';
CREATE INDEX ix_anomaly_alert_time ON ph14_national.anomaly_alert (tenant_id, detected_at DESC);
CREATE TRIGGER tg_anomaly_alert_immutable BEFORE UPDATE ON ph14_national.anomaly_alert FOR EACH ROW
  EXECUTE FUNCTION ph14_national.tg_immutable('system_code', 'service_code', 'rule', 'window_start', 'window_end', 'detected_at');
CREATE TRIGGER tg_anomaly_alert_nodelete BEFORE DELETE ON ph14_national.anomaly_alert FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_no_delete();
CREATE TRIGGER tg_anomaly_alert_touch BEFORE UPDATE ON ph14_national.anomaly_alert FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.anomaly_alert', 'P');
COMMENT ON TABLE ph14_national.anomaly_alert IS 'EN-14-14 Cảnh báo khai thác bất thường: tra hàng loạt, ngoài giờ, tăng đột biến, một hồ sơ tra nhiều đối tượng (FR-14-053, THR-51). Mỗi (HTTT, dịch vụ, luật) tối đa một cảnh báo OPEN. Kết thúc cần quyết định và lý do ≥ 10 ký tự (ERR-14-003). Giữ 5 năm, không xóa. Bằng chứng chỉ gồm số liệu và mã giao dịch mẫu, không có định danh đối tượng.';
COMMENT ON COLUMN ph14_national.anomaly_alert.evidence IS 'Số liệu tóm tắt và danh sách mã giao dịch mẫu; CHECK chặn các khóa định danh thô.';
-- @rollback DROP TABLE IF EXISTS ph14_national.anomaly_alert CASCADE;

-- @changeset ph14-0480-anomaly-waiver
CREATE TABLE ph14_national.anomaly_waiver (
  id            uuid          NOT NULL,
  tenant_id     varchar(16)   NOT NULL,
  system_code   varchar(64)   NOT NULL,
  service_code  varchar(63)   NOT NULL,
  valid_from    timestamptz   NOT NULL,
  valid_to      timestamptz   NOT NULL,
  reason        varchar(500)  NOT NULL,
  created_at    timestamptz   NOT NULL DEFAULT now(),
  created_by    varchar(64)   NOT NULL,
  updated_at    timestamptz   NOT NULL DEFAULT now(),
  updated_by    varchar(64)   NOT NULL,
  version       integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_anomaly_waiver PRIMARY KEY (id),
  CONSTRAINT ck_anomaly_waiver_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_anomaly_waiver_range CHECK (valid_to > valid_from AND valid_to - valid_from <= interval '31 days'),
  CONSTRAINT ck_anomaly_waiver_reason CHECK (char_length(reason) >= 10)
);
CREATE INDEX ix_anomaly_waiver_scope ON ph14_national.anomaly_waiver (tenant_id, system_code, service_code, valid_to);
CREATE TRIGGER tg_anomaly_waiver_touch BEFORE UPDATE ON ph14_national.anomaly_waiver FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.anomaly_waiver', 'P');
COMMENT ON TABLE ph14_national.anomaly_waiver IS 'Cửa sổ "đã báo trước" do TA khai để luật phát hiện bỏ qua, ví dụ đợt đối chiếu cuối tháng (FR-14-053). Tối đa 31 ngày mỗi cửa sổ (giả định), có lý do.';
-- @rollback DROP TABLE IF EXISTS ph14_national.anomaly_waiver CASCADE;

-- @changeset ph14-0490-access-block
CREATE TABLE ph14_national.access_block (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  system_code      varchar(64)   NOT NULL,
  service_code     varchar(63)   NOT NULL,
  reason           varchar(1000) NOT NULL,
  source_alert_id  uuid,
  expires_at       timestamptz   NOT NULL,
  lifted_by        varchar(64),
  lifted_at        timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_access_block PRIMARY KEY (id),
  CONSTRAINT fk_access_block_alert FOREIGN KEY (source_alert_id, tenant_id) REFERENCES ph14_national.anomaly_alert (id, tenant_id),
  CONSTRAINT ck_access_block_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_access_block_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_access_block_expiry CHECK (expires_at > created_at),
  CONSTRAINT ck_access_block_lifted CHECK ((lifted_at IS NULL) = (lifted_by IS NULL))
);
CREATE UNIQUE INDEX uq_access_block_active ON ph14_national.access_block (tenant_id, system_code, service_code) WHERE lifted_at IS NULL;
CREATE TRIGGER tg_access_block_touch BEFORE UPDATE ON ph14_national.access_block FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.access_block', 'P');
COMMENT ON TABLE ph14_national.access_block IS 'Danh sách chặn blocks[] của ảnh chụp cấu hình: quyết định "tạm dừng dịch vụ cho HTTT đó" của SO khi xử lý cảnh báo; PurposeStage từ chối lượt khớp với ERR-14-106 sau tối đa 30 giây (FR-14-053). Hết hạn tự động theo expires_at; mỗi (HTTT, dịch vụ) tối đa một mục đang hiệu lực.';
-- @rollback DROP TABLE IF EXISTS ph14_national.access_block CASCADE;

-- @file 14-0044-transition.sql
-- @changeset ph14-0500-parallel-run splitStatements:false
CREATE TABLE ph14_national.parallel_run (
  id                           uuid          NOT NULL,
  tenant_id                    varchar(16)   NOT NULL,
  service_code                 varchar(63)   NOT NULL,
  sample_ratio                 numeric(5,4)  NOT NULL DEFAULT 0.1,
  ignore_fields                text[]        NOT NULL DEFAULT '{}',
  observation_source           varchar(10)   NOT NULL DEFAULT 'PH04_FLOW',
  state                        varchar(8)    NOT NULL DEFAULT 'RUNNING',
  start_at                     timestamptz   NOT NULL DEFAULT now(),
  samples                      bigint        NOT NULL DEFAULT 0,
  matched                      bigint        NOT NULL DEFAULT 0,
  match_ratio                  numeric       GENERATED ALWAYS AS (CASE WHEN samples > 0 THEN round(matched::numeric / samples, 5) END) STORED,
  consecutive_ok_days          smallint      NOT NULL DEFAULT 0,
  ready_for_cutover            boolean       NOT NULL DEFAULT false,
  ready_at                     timestamptz,
  old_key_revocation_confirmed boolean       NOT NULL DEFAULT false,
  closed_by                    varchar(64),
  closed_at                    timestamptz,
  close_reason                 varchar(500),
  created_at                   timestamptz   NOT NULL DEFAULT now(),
  created_by                   varchar(64)   NOT NULL,
  updated_at                   timestamptz   NOT NULL DEFAULT now(),
  updated_by                   varchar(64)   NOT NULL,
  version                      integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_parallel_run PRIMARY KEY (id),
  CONSTRAINT uq_parallel_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_parallel_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_parallel_run_ratio CHECK (sample_ratio BETWEEN 0.01 AND 1),
  CONSTRAINT ck_parallel_run_source CHECK (observation_source IN ('PH04_FLOW')),
  CONSTRAINT ck_parallel_run_state CHECK (state IN ('RUNNING', 'STOPPED', 'CLOSED')),
  CONSTRAINT ck_parallel_run_counts CHECK (samples >= 0 AND matched >= 0 AND matched <= samples AND consecutive_ok_days >= 0),
  CONSTRAINT ck_parallel_run_ready CHECK (NOT ready_for_cutover OR (samples >= 100 AND ready_at IS NOT NULL)),
  CONSTRAINT ck_parallel_run_closed CHECK ((state = 'CLOSED') = (closed_by IS NOT NULL AND closed_at IS NOT NULL)),
  CONSTRAINT ck_parallel_run_revocation CHECK (state <> 'CLOSED' OR old_key_revocation_confirmed)
);
CREATE UNIQUE INDEX uq_parallel_run_running ON ph14_national.parallel_run (tenant_id, service_code) WHERE state = 'RUNNING';
CREATE INDEX ix_parallel_run_service ON ph14_national.parallel_run (tenant_id, service_code, start_at DESC);
CREATE OR REPLACE FUNCTION ph14_national.tg_parallel_run_read_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_type varchar;
BEGIN
  SELECT s.operation_type INTO v_type FROM ph14_national.national_service s
   WHERE s.code = NEW.service_code AND s.tenant_id IN (NEW.tenant_id, 'COMMON') ORDER BY (s.tenant_id = NEW.tenant_id) DESC LIMIT 1;
  IF v_type IS DISTINCT FROM 'READ' THEN
    RAISE EXCEPTION 'Chỉ chạy song song cho dịch vụ thao tác đọc (ERR-14-033, BR-14-033): %', NEW.service_code USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_parallel_run_read_only BEFORE INSERT ON ph14_national.parallel_run FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_parallel_run_read_only();
CREATE TRIGGER tg_parallel_run_touch BEFORE UPDATE ON ph14_national.parallel_run FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.parallel_run', 'P');
COMMENT ON TABLE ph14_national.parallel_run IS 'EN-14-15 Phiên chạy song song đường mới với kết nối NGSP cũ, chỉ thao tác đọc (FR-14-055, BR-14-033). Mỗi dịch vụ tối đa một phiên RUNNING. Đóng phiên chỉ khi đã xác nhận thu hồi khóa cũ ở trung ương (BR-14-034, ERR-14-004). Khác biệt chỉ để cảnh báo, không bao giờ tự sửa kết quả.';
COMMENT ON COLUMN ph14_national.parallel_run.match_ratio IS 'Tỷ lệ khớp = matched / samples, cột sinh tự động; ngưỡng 14.parallel.match-ratio xét ở ParallelRunService theo từng ngày.';
COMMENT ON COLUMN ph14_national.parallel_run.ready_for_cutover IS 'Đạt tỷ lệ khớp liên tục 14.parallel.min-days ngày với ≥ 14.parallel.min-samples mẫu (CSDL chỉ chặn dưới 100 mẫu, bằng cận dưới của tham số).';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_parallel_run_read_only() CASCADE; DROP TABLE IF EXISTS ph14_national.parallel_run CASCADE;

-- @changeset ph14-0510-parallel-sample
CREATE TABLE ph14_national.parallel_sample (
  tenant_id    varchar(16)   NOT NULL,
  run_id       uuid          NOT NULL,
  sample_id    uuid          NOT NULL,
  sampled_at   timestamptz   NOT NULL,
  outcome      varchar(10)   NOT NULL,
  diff_paths   text[]        NOT NULL DEFAULT '{}',
  new_hash     char(64),
  old_hash     char(64),
  trace_id     char(32),
  CONSTRAINT pk_parallel_sample PRIMARY KEY (tenant_id, run_id, sample_id, sampled_at),
  CONSTRAINT fk_parallel_sample_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph14_national.parallel_run (id, tenant_id),
  CONSTRAINT ck_parallel_sample_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_parallel_sample_outcome CHECK (outcome IN ('MATCH', 'DIFF', 'ERROR_NEW', 'ERROR_OLD', 'ERROR_BOTH')),
  CONSTRAINT ck_parallel_sample_diff CHECK ((outcome = 'DIFF') = (cardinality(diff_paths) > 0)),
  CONSTRAINT ck_parallel_sample_hash CHECK ((new_hash IS NULL OR new_hash ~ '^[0-9a-f]{64}$') AND (old_hash IS NULL OR old_hash ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_parallel_sample_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (sampled_at);
CALL ph14_national.p_ensure_month_partitions('ph14_national.parallel_sample', current_date - 31, 5);
CREATE INDEX ix_parallel_sample_run ON ph14_national.parallel_sample (tenant_id, run_id, sampled_at DESC);
CALL ph14_national.p_enable_rls('ph14_national.parallel_sample', 'P');
COMMENT ON TABLE ph14_national.parallel_sample IS 'Mẫu so sánh hai đường: khớp, khác ở trường nào, lỗi một bên (FR-14-055). Chỉ lưu băm trường và đường dẫn trường khác nhau, không bao giờ lưu nội dung dữ liệu cá nhân (SDD §4.19). Giữ 90 ngày, dọn bằng DETACH phân vùng.';
-- @rollback DROP TABLE IF EXISTS ph14_national.parallel_sample CASCADE;

-- @changeset ph14-0520-legacy-import
CREATE TABLE ph14_national.legacy_import (
  id             uuid          NOT NULL,
  tenant_id      varchar(16)   NOT NULL,
  platform_id    uuid          NOT NULL,
  file_name      varchar(255)  NOT NULL,
  file_sha256    char(64)      NOT NULL,
  mode           varchar(7)    NOT NULL,
  on_duplicate   varchar(16)   NOT NULL DEFAULT 'SKIP',
  state          varchar(10)   NOT NULL,
  rows_total     integer       NOT NULL DEFAULT 0,
  rows_created   integer       NOT NULL DEFAULT 0,
  rows_skipped   integer       NOT NULL DEFAULT 0,
  rows_error     integer       NOT NULL DEFAULT 0,
  findings       jsonb         NOT NULL DEFAULT '{}',
  imported_by    varchar(64)   NOT NULL,
  created_at     timestamptz   NOT NULL DEFAULT now(),
  created_by     varchar(64)   NOT NULL,
  updated_at     timestamptz   NOT NULL DEFAULT now(),
  updated_by     varchar(64)   NOT NULL,
  version        integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_import PRIMARY KEY (id),
  CONSTRAINT fk_legacy_import_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_legacy_import_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legacy_import_hash CHECK (file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_legacy_import_mode CHECK (mode IN ('PREVIEW', 'APPLY')),
  CONSTRAINT ck_legacy_import_duplicate CHECK (on_duplicate IN ('SKIP', 'OVERWRITE_DRAFT')),
  CONSTRAINT ck_legacy_import_state CHECK (state IN ('PREVIEWED', 'APPLIED', 'REJECTED')),
  CONSTRAINT ck_legacy_import_counts CHECK (rows_total >= 0 AND rows_created >= 0 AND rows_skipped >= 0 AND rows_error >= 0 AND rows_created + rows_skipped + rows_error <= rows_total),
  CONSTRAINT ck_legacy_import_all_or_nothing CHECK ((state = 'APPLIED') = (mode = 'APPLY' AND rows_error = 0)),
  CONSTRAINT ck_legacy_import_findings CHECK (jsonb_typeof(findings) = 'object')
);
CREATE INDEX ix_legacy_import_platform ON ph14_national.legacy_import (tenant_id, platform_id, created_at DESC);
CREATE TRIGGER tg_legacy_import_touch BEFORE UPDATE ON ph14_national.legacy_import FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.legacy_import', 'P');
COMMENT ON TABLE ph14_national.legacy_import IS 'Lần nhập cấu hình dịch vụ từ phụ lục NGSP của hệ cũ (CSV, XLSX), tất cả hoặc không: một dòng sai thì không dịch vụ nào được tạo (FR-14-056, ERR-14-032). findings ghi vị trí (dòng, cột) cột chứa bí mật đã bỏ qua, không bao giờ ghi giá trị (BR-14-034). Giữ 3 năm (giả định).';
COMMENT ON COLUMN ph14_national.legacy_import.state IS 'APPLIED khi mode APPLY và rows_error = 0 (ck_legacy_import_all_or_nothing); REJECTED khi APPLY có dòng lỗi.';
-- @rollback DROP TABLE IF EXISTS ph14_national.legacy_import CASCADE;

-- @file 14-0045-platform.sql
-- @changeset ph14-0600-outbox
CREATE TABLE ph14_national.outbox (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     text          NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.national\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^(t[0-9]{2}|common)\.national\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'passphrase', 'payload', 'body']))
);
CREATE INDEX ix_outbox_occurred ON ph14_national.outbox (occurred_at);
ALTER TABLE ph14_national.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph14_national.p_enable_rls('ph14_national.outbox', 'P');
COMMENT ON TABLE ph14_national.outbox IS 'Outbox (DD-11) cho EVT-14-01…06, 08, 09, 12, 13, 14, 16 và lệnh cho worker (worker.command), ghi cùng giao dịch với thay đổi miền (SDD §8.2). Debezium của pg-core hoặc bộ quét 500 ms đẩy lên Kafka; khóa phân vùng là mã đối tượng. Dọn sau 3 ngày. EVT-14-07, 10, 11, 15, 17 do cổng phát qua LedgerSpool, không qua bảng này. Payload không chứa bí mật, nội dung bản tin.';
COMMENT ON COLUMN ph14_national.outbox.topic IS 'Dạng {tenant}.national.{thực-thể}.{sự-kiện}.v{n} chữ thường; tiền tố phải khớp tenant (ck_outbox_topic_tenant, SEC-82).';
-- @rollback DROP TABLE IF EXISTS ph14_national.outbox CASCADE;

-- @changeset ph14-0610-shedlock
CREATE TABLE ph14_national.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph14_national.shedlock IS 'Khóa tác vụ nền của ShedLock (CertificateExpiryJob, CrlRefresher, SyncScheduler, ComplianceWatcher, AnomalyDetector, HealthRollupJob, PartitionMaintenanceJob, PayloadRetentionApplier, QuotaForecaster); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph14_national.shedlock;

RESET ROLE;
