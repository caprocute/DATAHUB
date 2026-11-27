-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national
-- Tệp 30: hạn mức và mức dùng, thống kê đệm, yêu cầu bất đồng bộ, chiều vào.
-- Bộ đếm nóng nằm ở Valkey; bảng ở đây là chính sách, ảnh chụp mức dùng và hồ sơ.
-- Chạy sau ph14_20_trust.sql.
-- =============================================================================

\set ON_ERROR_STOP on
SET ROLE ph14_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 14-0030-quota.sql
-- @changeset ph14-0300-quota-policy
CREATE TABLE ph14_national.quota_policy (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  platform_id      uuid          NOT NULL,
  service_code     varchar(63),
  period           varchar(5)    NOT NULL,
  env              varchar(8)    NOT NULL DEFAULT 'PROD',
  limit_count      bigint        NOT NULL,
  basis_document   varchar(500)  NOT NULL,
  effective_from   timestamptz   NOT NULL DEFAULT now(),
  state            varchar(16)   NOT NULL DEFAULT 'DRAFT',
  requested_by     varchar(64),
  approved_by      varchar(64),
  approved_at      timestamptz,
  superseded_at    timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_policy PRIMARY KEY (id),
  CONSTRAINT uq_quota_policy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_quota_policy_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_quota_policy_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_quota_policy_period CHECK (period IN ('HOUR', 'DAY', 'MONTH')),
  CONSTRAINT ck_quota_policy_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_quota_policy_limit CHECK (limit_count BETWEEN 1 AND 2000000000),
  CONSTRAINT ck_quota_policy_basis CHECK (char_length(basis_document) BETWEEN 10 AND 500),
  CONSTRAINT ck_quota_policy_state CHECK (state IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED')),
  CONSTRAINT ck_quota_policy_superseded CHECK ((state = 'SUPERSEDED') = (superseded_at IS NOT NULL)),
  CONSTRAINT ck_quota_policy_four_eyes CHECK (state NOT IN ('ACTIVE', 'SUPERSEDED') OR env <> 'PROD'
                                              OR (requested_by IS NOT NULL AND approved_by IS NOT NULL AND approved_by <> requested_by AND approved_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_quota_policy_active ON ph14_national.quota_policy
  (tenant_id, platform_id, coalesce(service_code, ''), period, env) WHERE state = 'ACTIVE';
CREATE INDEX ix_quota_policy_platform ON ph14_national.quota_policy (tenant_id, platform_id, state);
CREATE TRIGGER tg_quota_policy_touch BEFORE UPDATE ON ph14_national.quota_policy FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.quota_policy', 'P');
COMMENT ON TABLE ph14_national.quota_policy IS 'EN-14-06 Hạn mức truy vấn do trung ương áp theo nền tảng hoặc dịch vụ và chu kỳ (FR-14-032, 033). Phải có căn cứ văn bản (BR-14-011); ở môi trường thật cần người thứ hai duyệt (BR-14-022). Bộ đếm lượt dùng ở Valkey.';
COMMENT ON COLUMN ph14_national.quota_policy.service_code IS 'Rỗng: áp cho cả nền tảng. Tham chiếu theo mã, không khóa ngoại.';
COMMENT ON COLUMN ph14_national.quota_policy.basis_document IS 'Số, ngày, trích yếu văn bản thông báo hạn mức, 10 đến 500 ký tự.';
-- @rollback DROP TABLE IF EXISTS ph14_national.quota_policy CASCADE;

-- @changeset ph14-0310-quota-allocation splitStatements:false
CREATE TABLE ph14_national.quota_allocation (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  policy_id         uuid          NOT NULL,
  system_code       varchar(64)   NOT NULL,
  service_code      varchar(63)   NOT NULL,
  limit_count       bigint,
  unlimited         boolean       NOT NULL DEFAULT false,
  share_of_reserve  numeric(5,4)  NOT NULL DEFAULT 0,
  note              varchar(500),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_allocation PRIMARY KEY (id),
  CONSTRAINT uq_quota_allocation UNIQUE (tenant_id, policy_id, system_code, service_code),
  CONSTRAINT fk_quota_allocation_policy FOREIGN KEY (policy_id, tenant_id) REFERENCES ph14_national.quota_policy (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_quota_allocation_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_quota_allocation_limit CHECK (unlimited = (limit_count IS NULL) AND (limit_count IS NULL OR limit_count >= 0)),
  CONSTRAINT ck_quota_allocation_share CHECK (share_of_reserve BETWEEN 0 AND 1)
);
CREATE INDEX ix_quota_allocation_system ON ph14_national.quota_allocation (tenant_id, system_code);
CREATE OR REPLACE FUNCTION ph14_national.tg_quota_allocation_sum() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_limit bigint;
  v_sum   bigint;
BEGIN
  SELECT limit_count INTO v_limit FROM ph14_national.quota_policy WHERE id = NEW.policy_id AND tenant_id = NEW.tenant_id;
  SELECT coalesce(sum(limit_count), 0) INTO v_sum FROM ph14_national.quota_allocation WHERE policy_id = NEW.policy_id AND tenant_id = NEW.tenant_id;
  IF v_sum > v_limit THEN
    RAISE EXCEPTION 'Tổng phân bổ % vượt hạn mức % của chính sách % (ERR-14-018)', v_sum, v_limit, NEW.policy_id USING ERRCODE = '23514';
  END IF;
  RETURN NULL;
END
$f$;
CREATE CONSTRAINT TRIGGER tg_quota_allocation_sum AFTER INSERT OR UPDATE ON ph14_national.quota_allocation
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_quota_allocation_sum();
-- Hạ hạn mức xuống dưới tổng đã phân bổ cũng bị chặn (kiểm cuối giao dịch).
CREATE OR REPLACE FUNCTION ph14_national.tg_quota_policy_limit() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_sum bigint;
BEGIN
  SELECT coalesce(sum(limit_count), 0) INTO v_sum FROM ph14_national.quota_allocation WHERE policy_id = NEW.id AND tenant_id = NEW.tenant_id;
  IF v_sum > NEW.limit_count THEN
    RAISE EXCEPTION 'Hạn mức % thấp hơn tổng phân bổ % của chính sách % (ERR-14-018)', NEW.limit_count, v_sum, NEW.id USING ERRCODE = '23514';
  END IF;
  RETURN NULL;
END
$f$;
CREATE CONSTRAINT TRIGGER tg_quota_policy_limit AFTER UPDATE OF limit_count ON ph14_national.quota_policy
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_quota_policy_limit();
CREATE TRIGGER tg_quota_allocation_touch BEFORE UPDATE ON ph14_national.quota_allocation FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.quota_allocation', 'P');
COMMENT ON TABLE ph14_national.quota_allocation IS 'EN-14-07 Phần hạn mức Datahub chia cho từng HTTT theo dịch vụ (FR-14-034). Trigger hoãn đến cuối giao dịch bảo đảm tổng phân bổ hữu hạn không vượt hạn mức của chính sách (ERR-14-018); phân bổ UNLIMITED chỉ bị chặn bởi hạn mức toàn cục.';
COMMENT ON COLUMN ph14_national.quota_allocation.share_of_reserve IS 'Tỷ lệ HTTT được hưởng trong phần dự phòng chưa phân bổ (0 đến 1).';
COMMENT ON COLUMN ph14_national.quota_allocation.unlimited IS 'true khi limit_count rỗng: HTTT không bị trần riêng (dịch vụ ESSENTIAL, Q14-24).';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_quota_policy_limit() CASCADE; DROP FUNCTION IF EXISTS ph14_national.tg_quota_allocation_sum() CASCADE; DROP TABLE IF EXISTS ph14_national.quota_allocation CASCADE;

-- @changeset ph14-0320-quota-usage
CREATE TABLE ph14_national.quota_usage (
  tenant_id           varchar(16)   NOT NULL,
  platform_id         uuid          NOT NULL,
  env                 varchar(8)    NOT NULL,
  service_key         varchar(63)   NOT NULL DEFAULT '',
  period              varchar(5)    NOT NULL,
  bucket_start        timestamptz   NOT NULL,
  used                bigint        NOT NULL DEFAULT 0,
  denied              bigint        NOT NULL DEFAULT 0,
  limit_snapshot      bigint,
  reset_at            timestamptz   NOT NULL,
  last_warned_level   smallint      NOT NULL DEFAULT 0,
  synced_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_quota_usage PRIMARY KEY (tenant_id, platform_id, env, service_key, period, bucket_start),
  CONSTRAINT ck_quota_usage_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_quota_usage_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_quota_usage_period CHECK (period IN ('HOUR', 'DAY', 'MONTH')),
  CONSTRAINT ck_quota_usage_counts CHECK (used >= 0 AND denied >= 0),
  CONSTRAINT ck_quota_usage_reset CHECK (reset_at > bucket_start),
  CONSTRAINT ck_quota_usage_level CHECK (last_warned_level BETWEEN 0 AND 3)
) PARTITION BY RANGE (bucket_start);
CALL ph14_national.p_ensure_month_partitions('ph14_national.quota_usage', current_date - 31, 5);
CREATE INDEX ix_quota_usage_platform ON ph14_national.quota_usage (tenant_id, platform_id, bucket_start DESC);
CALL ph14_national.p_enable_rls('ph14_national.quota_usage', 'P');
COMMENT ON TABLE ph14_national.quota_usage IS 'Ảnh chụp mức dùng hạn mức theo chu kỳ, cập nhật từ chủ đề quota.usage (FR-14-033, 057). Khóa tự nhiên, upsert nhận giá trị lớn hơn. Phân vùng tháng, giữ 2 năm (NFR-14-021). Số liệu nóng ở Valkey; bảng này phục vụ báo cáo, dự báo cạn và đối soát.';
COMMENT ON COLUMN ph14_national.quota_usage.service_key IS 'Mã dịch vụ; chuỗi rỗng là bộ đếm cả nền tảng.';
COMMENT ON COLUMN ph14_national.quota_usage.last_warned_level IS 'Ngưỡng cảnh báo đã phát trong chu kỳ: 0 chưa, 1 là 70%, 2 là 85%, 3 là 95% (14.quota.warn-levels); tránh phát EVT-14-07 lặp.';
COMMENT ON COLUMN ph14_national.quota_usage.limit_snapshot IS 'Hạn mức hiệu lực lúc ghi; giữ để báo cáo đúng khi hạn mức đổi sau đó.';
-- @rollback DROP TABLE IF EXISTS ph14_national.quota_usage CASCADE;

-- @changeset ph14-0330-cache-stats
CREATE TABLE ph14_national.cache_stats (
  tenant_id       varchar(16)   NOT NULL,
  service_code    varchar(63)   NOT NULL,
  hour_start      timestamptz   NOT NULL,
  hits            bigint        NOT NULL DEFAULT 0,
  misses          bigint        NOT NULL DEFAULT 0,
  stale_served    bigint        NOT NULL DEFAULT 0,
  invalidations   integer       NOT NULL DEFAULT 0,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_cache_stats PRIMARY KEY (tenant_id, service_code, hour_start),
  CONSTRAINT ck_cache_stats_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_cache_stats_counts CHECK (hits >= 0 AND misses >= 0 AND stale_served >= 0 AND invalidations >= 0),
  CONSTRAINT ck_cache_stats_hour CHECK (hour_start = date_trunc('hour', hour_start))
) PARTITION BY RANGE (hour_start);
CALL ph14_national.p_ensure_month_partitions('ph14_national.cache_stats', current_date - 31, 5);
CALL ph14_national.p_enable_rls('ph14_national.cache_stats', 'P');
COMMENT ON TABLE ph14_national.cache_stats IS 'Thống kê đệm tổng hợp theo giờ và dịch vụ, ghi từ EVT-14-11 (FR-14-035, 036, 037, 057). Phân vùng tháng, giữ 13 tháng (đủ so sánh cùng kỳ năm trước; chủ đầu tư chốt 27/11/2026). Tỷ lệ trúng đệm = hits / (hits + misses) (NFR-14-005).';
-- @rollback DROP TABLE IF EXISTS ph14_national.cache_stats CASCADE;

-- @file 14-0031-async-inbound.sql
-- @changeset ph14-0340-async-request
CREATE TABLE ph14_national.async_request (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  service_code        varchar(63)   NOT NULL,
  operation           varchar(63),
  system_code         varchar(64)   NOT NULL,
  purpose_code        varchar(64),
  procedure_code      varchar(64),
  case_code           varchar(128),
  priority            varchar(10)   NOT NULL,
  state               varchar(16)   NOT NULL DEFAULT 'QUEUED',
  attempts            smallint      NOT NULL DEFAULT 0,
  idempotency_key     char(26)      NOT NULL,
  payload_hash        char(64)      NOT NULL,
  transaction_code    varchar(40),
  result_ref          varchar(255),
  error_code          varchar(16),
  accepted_at         timestamptz   NOT NULL DEFAULT now(),
  not_before          timestamptz,
  expires_at          timestamptz   NOT NULL,
  last_attempt_at     timestamptz,
  finished_at         timestamptz,
  cancelled_by        varchar(64),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_async_request PRIMARY KEY (id),
  CONSTRAINT uq_async_request_idempotency UNIQUE (tenant_id, system_code, idempotency_key),
  CONSTRAINT ck_async_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_async_request_priority CHECK (priority IN ('ESSENTIAL', 'NORMAL', 'BACKGROUND')),
  CONSTRAINT ck_async_request_state CHECK (state IN ('QUEUED', 'SENDING', 'SUCCEEDED', 'FAILED', 'UNKNOWN_RESULT', 'CANCELLED')),
  CONSTRAINT ck_async_request_key CHECK (idempotency_key ~ '^[0-9A-HJKMNP-TV-Z]{26}$'),
  CONSTRAINT ck_async_request_hash CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_async_request_attempts CHECK (attempts >= 0),
  CONSTRAINT ck_async_request_expiry CHECK (expires_at > accepted_at),
  CONSTRAINT ck_async_request_final CHECK ((state IN ('SUCCEEDED', 'FAILED', 'CANCELLED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_async_request_cancelled CHECK (state <> 'CANCELLED' OR cancelled_by IS NOT NULL),
  CONSTRAINT ck_async_request_result_ref CHECK (result_ref IS NULL OR result_ref LIKE (lower(tenant_id) || '/async/%'))
);
CREATE INDEX ix_async_request_open ON ph14_national.async_request (tenant_id, state, accepted_at) WHERE state IN ('QUEUED', 'SENDING');
CREATE INDEX ix_async_request_unknown ON ph14_national.async_request (tenant_id, accepted_at) WHERE state = 'UNKNOWN_RESULT';
CREATE INDEX ix_async_request_system ON ph14_national.async_request (tenant_id, system_code, accepted_at DESC);
CREATE INDEX ix_async_request_expiry ON ph14_national.async_request (finished_at) WHERE finished_at IS NOT NULL;
CREATE TRIGGER tg_async_request_touch BEFORE UPDATE ON ph14_national.async_request FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.async_request', 'P');
COMMENT ON TABLE ph14_national.async_request IS 'EN-14-13 Yêu cầu gọi bất đồng bộ (FR-14-016, 038). Kafka là nguồn sự thật của việc chấp nhận, bảng là bản dẫn xuất do AsyncStateConsumer ghi lũy đẳng theo id. Thao tác ghi bắt buộc Idempotency-Key ULID (BR-14-030). Giữ 90 ngày sau khi kết thúc (chủ đầu tư chốt 27/11/2026), siêu dữ liệu giao dịch nằm ở national_transaction 5 năm.';
COMMENT ON COLUMN ph14_national.async_request.id IS 'requestId trả cho HTTT; khóa Kafka của hàng chờ.';
COMMENT ON COLUMN ph14_national.async_request.payload_hash IS 'SHA-256 nội dung yêu cầu để phát hiện cùng khóa khác nội dung (ERR-14-116); không lưu nội dung.';
COMMENT ON COLUMN ph14_national.async_request.result_ref IS 'Khóa đối tượng kết quả mã hóa trong dh-nat-payload dạng {tenant}/async/{id}.res.enc, giữ 72 giờ.';
COMMENT ON COLUMN ph14_national.async_request.state IS 'UNKNOWN_RESULT: quá hạn chờ với thao tác ghi, không tự gửi lại mà đối soát trước (BR-14-030).';
-- @rollback DROP TABLE IF EXISTS ph14_national.async_request CASCADE;

-- @changeset ph14-0350-inbound-endpoint
CREATE TABLE ph14_national.inbound_endpoint (
  id                       uuid          NOT NULL,
  tenant_id                varchar(16)   NOT NULL,
  code                     varchar(63)   NOT NULL,
  platform_id              uuid          NOT NULL,
  path                     varchar(80)   GENERATED ALWAYS AS ('/inbound/v1/' || code) STORED,
  signature_required       boolean       NOT NULL DEFAULT true,
  unsigned_reason          varchar(500),
  unsigned_approved_by     varchar(64),
  rate_limit_per_second    integer,
  max_message_kb           integer       NOT NULL DEFAULT 512,
  state                    varchar(20)   NOT NULL DEFAULT 'DRAFT',
  state_reason             varchar(1000),
  activation_requested_by  varchar(64),
  activation_approved_by   varchar(64),
  activation_approved_at   timestamptz,
  retired_at               timestamptz,
  created_at               timestamptz   NOT NULL DEFAULT now(),
  created_by               varchar(64)   NOT NULL,
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  updated_by               varchar(64)   NOT NULL,
  version                  integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_inbound_endpoint PRIMARY KEY (id),
  CONSTRAINT uq_inbound_endpoint_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_inbound_endpoint_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_inbound_endpoint_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_inbound_endpoint_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbound_endpoint_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$' AND code LIKE ('%-' || lower(tenant_id))),
  CONSTRAINT ck_inbound_endpoint_unsigned CHECK (signature_required OR (coalesce(char_length(unsigned_reason), 0) >= 10 AND unsigned_approved_by IS NOT NULL)),
  CONSTRAINT ck_inbound_endpoint_rate CHECK (rate_limit_per_second IS NULL OR rate_limit_per_second BETWEEN 1 AND 500),
  CONSTRAINT ck_inbound_endpoint_size CHECK (max_message_kb BETWEEN 1 AND 2048),
  CONSTRAINT ck_inbound_endpoint_state CHECK (state IN ('DRAFT', 'PENDING_ACTIVATION', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_inbound_endpoint_active CHECK (state NOT IN ('ACTIVE', 'SUSPENDED') OR (activation_approved_by IS NOT NULL AND activation_approved_at IS NOT NULL)),
  CONSTRAINT ck_inbound_endpoint_four_eyes CHECK (activation_approved_by IS NULL OR (activation_requested_by IS NOT NULL AND activation_approved_by <> activation_requested_by)),
  CONSTRAINT ck_inbound_endpoint_retired CHECK ((state = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE INDEX ix_inbound_endpoint_platform ON ph14_national.inbound_endpoint (tenant_id, platform_id, state);
CREATE TRIGGER tg_inbound_endpoint_touch BEFORE UPDATE ON ph14_national.inbound_endpoint FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CREATE TRIGGER tg_inbound_endpoint_retired BEFORE UPDATE ON ph14_national.inbound_endpoint FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_retired_final();
CALL ph14_national.p_enable_rls('ph14_national.inbound_endpoint', 'P');
COMMENT ON TABLE ph14_national.inbound_endpoint IS 'EN-14-09 Điểm cuối chiều vào do tenant đăng ký với trung ương (FR-14-039, 040, 041). Mã bắt buộc kết thúc bằng -{tenant} nên duy nhất toàn cụm mà không cần chỉ mục chéo tenant: tenant được xác định từ điểm cuối, không từ nội dung bản tin (BR-14-027).';
COMMENT ON COLUMN ph14_national.inbound_endpoint.path IS 'Đường dẫn công bố /inbound/v1/{code}; cột sinh tự động.';
COMMENT ON COLUMN ph14_national.inbound_endpoint.signature_required IS 'false chỉ khi SO đồng ý và có lý do ≥ 10 ký tự (ck_inbound_endpoint_unsigned).';
-- @rollback DROP TABLE IF EXISTS ph14_national.inbound_endpoint CASCADE;

-- @changeset ph14-0360-allowed-sender
CREATE TABLE ph14_national.allowed_sender (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  endpoint_id       uuid          NOT NULL,
  sender_code       varchar(64)   NOT NULL,
  cert_fingerprint  char(64)      NOT NULL,
  service_codes     text[]        NOT NULL,
  enabled           boolean       NOT NULL DEFAULT true,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_allowed_sender PRIMARY KEY (id),
  CONSTRAINT uq_allowed_sender_code UNIQUE (tenant_id, endpoint_id, sender_code),
  CONSTRAINT uq_allowed_sender_fingerprint UNIQUE (tenant_id, endpoint_id, cert_fingerprint),
  CONSTRAINT fk_allowed_sender_endpoint FOREIGN KEY (endpoint_id, tenant_id) REFERENCES ph14_national.inbound_endpoint (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_allowed_sender_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_allowed_sender_fingerprint CHECK (cert_fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_allowed_sender_services CHECK (cardinality(service_codes) BETWEEN 1 AND 100)
);
CREATE TRIGGER tg_allowed_sender_touch BEFORE UPDATE ON ph14_national.allowed_sender FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.allowed_sender', 'P');
COMMENT ON TABLE ph14_national.allowed_sender IS 'Nguồn được phép gọi vào một điểm cuối: mã đơn vị gửi theo văn bản trung ương, vân tay SHA-256 chứng thư mTLS, danh sách dịch vụ INBOUND được gọi (FR-14-039). Danh sách đi vào ảnh chụp và bộ lọc ở APISIX (EVT-14-13).';
COMMENT ON COLUMN ph14_national.allowed_sender.service_codes IS 'Mã dịch vụ direction = INBOUND; kiểm tồn tại ở dịch vụ, không khóa ngoại mảng.';
-- @rollback DROP TABLE IF EXISTS ph14_national.allowed_sender CASCADE;

-- @changeset ph14-0370-inbound-route splitStatements:false
CREATE TABLE ph14_national.inbound_route (
  id           uuid          NOT NULL,
  tenant_id    varchar(16)   NOT NULL,
  endpoint_id  uuid          NOT NULL,
  service_code varchar(63)   NOT NULL,
  flow_code    varchar(63)   NOT NULL,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  created_by   varchar(64)   NOT NULL,
  updated_at   timestamptz   NOT NULL DEFAULT now(),
  updated_by   varchar(64)   NOT NULL,
  version      integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_inbound_route PRIMARY KEY (id),
  CONSTRAINT uq_inbound_route UNIQUE (tenant_id, endpoint_id, service_code),
  CONSTRAINT fk_inbound_route_endpoint FOREIGN KEY (endpoint_id, tenant_id) REFERENCES ph14_national.inbound_endpoint (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_inbound_route_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbound_route_flow CHECK (flow_code ~ '^[a-z][a-z0-9-]{2,62}$')
);
CREATE TRIGGER tg_inbound_route_touch BEFORE UPDATE ON ph14_national.inbound_route FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.inbound_route', 'P');
COMMENT ON TABLE ph14_national.inbound_route IS 'Ánh xạ (điểm cuối, dịch vụ chiều vào) tới luồng PH-04 đã phát hành (FR-14-041). flow_code tham chiếu theo mã sang schema của PH-04, không khóa ngoại; kiểm đã phát hành ở dịch vụ (ERR-14-039).';

-- Điểm cuối chỉ được ACTIVE khi có ít nhất một nguồn được phép đang bật và một tuyến luồng (BR-14-027, ERR-14-024, 039).
CREATE OR REPLACE FUNCTION ph14_national.tg_inbound_endpoint_enable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.state = 'ACTIVE' AND OLD.state IS DISTINCT FROM 'ACTIVE' THEN
    IF NOT EXISTS (SELECT 1 FROM ph14_national.allowed_sender s WHERE s.endpoint_id = NEW.id AND s.tenant_id = NEW.tenant_id AND s.enabled) THEN
      RAISE EXCEPTION 'Điểm cuối % cần ít nhất một nguồn được phép đang bật (ERR-14-024)', NEW.code USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ph14_national.inbound_route r WHERE r.endpoint_id = NEW.id AND r.tenant_id = NEW.tenant_id) THEN
      RAISE EXCEPTION 'Điểm cuối % cần ít nhất một tuyến tới luồng PH-04 (ERR-14-039)', NEW.code USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_inbound_endpoint_enable BEFORE UPDATE OF state ON ph14_national.inbound_endpoint FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_inbound_endpoint_enable();
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_inbound_endpoint_enable() CASCADE; DROP TABLE IF EXISTS ph14_national.inbound_route CASCADE;

RESET ROLE;
