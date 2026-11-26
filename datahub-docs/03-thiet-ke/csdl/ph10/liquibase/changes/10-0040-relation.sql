--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0040-relation.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0400-publication
CREATE TABLE ph10_event.publication (
  id                        uuid          NOT NULL,
  tenant_id                 varchar(16)   NOT NULL,
  publication_code          varchar(63)   NOT NULL,
  publisher_code            varchar(63)   NOT NULL,
  topic_name                varchar(204)  NOT NULL,
  purpose                   varchar(2000) NOT NULL,
  expected_rate_per_minute  integer,
  quota_bytes_per_second    bigint,
  status                    varchar(20)   NOT NULL DEFAULT 'PENDING_APPROVAL',
  granted_scope             varchar(255),
  acl_ref                   varchar(512),
  suspend_source            varchar(20),
  approved_by               varchar(64),
  approved_at               timestamptz,
  revoked_at                timestamptz,
  created_at                timestamptz   NOT NULL DEFAULT now(),
  created_by                varchar(64)   NOT NULL,
  updated_at                timestamptz   NOT NULL DEFAULT now(),
  updated_by                varchar(64)   NOT NULL,
  version                   integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_publication PRIMARY KEY (id),
  CONSTRAINT uq_publication_code UNIQUE (tenant_id, publication_code),
  CONSTRAINT fk_publication_publisher FOREIGN KEY (tenant_id, publisher_code) REFERENCES ph10_event.publisher (tenant_id, publisher_code),
  CONSTRAINT fk_publication_topic FOREIGN KEY (tenant_id, topic_name) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT ck_publication_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_publication_code CHECK (publication_code ~ '^pub-[0-9a-hjkmnp-tv-z]{26}$'),
  CONSTRAINT ck_publication_status CHECK (status IN ('PENDING_APPROVAL', 'REJECTED', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_publication_suspend_source CHECK (suspend_source IS NULL OR suspend_source IN ('MANUAL', 'SECURITY', 'PH01', 'CIRCUIT_BREAKER', 'DELIVERY_BLOCKED')),
  CONSTRAINT ck_publication_suspend_blocked CHECK (suspend_source IS DISTINCT FROM 'DELIVERY_BLOCKED'),
  CONSTRAINT ck_publication_suspended CHECK ((status = 'SUSPENDED') = (suspend_source IS NOT NULL)),
  CONSTRAINT ck_publication_approved CHECK (status NOT IN ('ACTIVE', 'SUSPENDED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_publication_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_publication_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL)),
  -- BR-10-020: scope chỉ khi ACTIVE; đúng mẫu topic:{topicName}:publish
  CONSTRAINT ck_publication_scope CHECK (granted_scope IS NULL OR (status = 'ACTIVE' AND granted_scope = 'topic:' || topic_name || ':publish')),
  CONSTRAINT ck_publication_quota CHECK (quota_bytes_per_second IS NULL OR quota_bytes_per_second >= 262144),
  CONSTRAINT ck_publication_rate CHECK (expected_rate_per_minute IS NULL OR expected_rate_per_minute >= 0)
);
CREATE UNIQUE INDEX uq_publication_open ON ph10_event.publication (tenant_id, publisher_code, topic_name) WHERE status IN ('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED');
CREATE INDEX ix_publication_topic ON ph10_event.publication (tenant_id, topic_name, status);
CREATE INDEX ix_publication_publisher ON ph10_event.publication (tenant_id, publisher_code, status);
CREATE TRIGGER tg_publication_touch BEFORE UPDATE ON ph10_event.publication FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_publication_immutable BEFORE UPDATE ON ph10_event.publication FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('publication_code', 'tenant_id', 'publisher_code', 'topic_name');
CALL ph10_event.p_enable_rls('ph10_event.publication', 'P');
COMMENT ON TABLE ph10_event.publication IS 'EN-10-07 Publication (FR-10-030…032, LGC-HUB-012). Duy nhất theo cặp bên phát, topic khi còn hiệu lực; dòng REJECTED, REVOKED giữ lại để truy vết. Duyệt qua approval_request PUBLICATION; tự duyệt ghi approved_by = system:auto (BR-10-031).';
COMMENT ON COLUMN ph10_event.publication.granted_scope IS 'Scope OAuth cấp cho HTTT (SYSTEM); NULL với FLOW, INTERNAL_SERVICE vì đi listener internal (BR-10-018).';
COMMENT ON COLUMN ph10_event.publication.acl_ref IS 'Đường dẫn tài nguyên KafkaUser trong dh-config-{tenant} chứa ACL WRITE literal trên topic.';
COMMENT ON COLUMN ph10_event.publication.quota_bytes_per_second IS 'Phần hạn mức sản xuất phân bổ cho principal (FR-10-062), tối thiểu 256 KiB/s; tổng không vượt trần tenant (BR-10-029, kiểm ở dịch vụ).';
--rollback DROP TABLE IF EXISTS ph10_event.publication CASCADE;

--changeset ph10:ph10-0410-subscription
CREATE TABLE ph10_event.subscription (
  id                      uuid          NOT NULL,
  tenant_id               varchar(16)   NOT NULL,
  subscription_code       varchar(63)   NOT NULL,
  subscriber_code         varchar(63)   NOT NULL,
  topic_name              varchar(204)  NOT NULL,
  delivery_mode           varchar(16)   NOT NULL,
  purpose                 varchar(2000) NOT NULL,
  legal_basis             varchar(2000),
  consumer_group          varchar(255)  NOT NULL,
  start_position          varchar(16)   NOT NULL DEFAULT 'LATEST',
  start_at                timestamptz,
  status                  varchar(20)   NOT NULL DEFAULT 'PENDING_APPROVAL',
  suspend_source          varchar(20),
  suspend_reason          varchar(1000),
  lag_warn_seconds        integer       NOT NULL DEFAULT 300,
  lag_critical_seconds    integer       NOT NULL DEFAULT 1800,
  alert_state             varchar(16)   NOT NULL DEFAULT 'OK',
  alert_acknowledged_by   varchar(64),
  alert_acknowledged_at   timestamptz,
  alert_ack_note          varchar(1000),
  approved_by             varchar(64),
  approved_at             timestamptz,
  push                    jsonb,
  pull                    jsonb,
  quota_bytes_per_second  bigint,
  created_at              timestamptz   NOT NULL DEFAULT now(),
  created_by              varchar(64)   NOT NULL,
  updated_at              timestamptz   NOT NULL DEFAULT now(),
  updated_by              varchar(64)   NOT NULL,
  version                 integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_subscription PRIMARY KEY (id),
  CONSTRAINT uq_subscription_code UNIQUE (tenant_id, subscription_code),
  CONSTRAINT uq_subscription_group UNIQUE (consumer_group),
  CONSTRAINT fk_subscription_subscriber FOREIGN KEY (tenant_id, subscriber_code) REFERENCES ph10_event.subscriber (tenant_id, subscriber_code),
  CONSTRAINT fk_subscription_topic FOREIGN KEY (tenant_id, topic_name) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT ck_subscription_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_subscription_code CHECK (subscription_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_subscription_status CHECK (status IN ('PENDING_APPROVAL', 'REJECTED', 'PROVISIONING', 'FAILED', 'ACTIVE', 'PAUSED', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_subscription_delivery_mode CHECK (delivery_mode IN ('PUSH', 'PULL_API', 'PULL_KAFKA', 'INTERNAL')),
  CONSTRAINT ck_subscription_start_position CHECK (start_position IN ('LATEST', 'EARLIEST', 'TIMESTAMP')),
  CONSTRAINT ck_subscription_start_at CHECK ((start_position = 'TIMESTAMP') = (start_at IS NOT NULL)),
  CONSTRAINT ck_subscription_alert_state CHECK (alert_state IN ('OK', 'WARNING', 'CRITICAL', 'STALLED')),
  CONSTRAINT ck_subscription_alert_ack CHECK ((alert_acknowledged_by IS NULL) = (alert_acknowledged_at IS NULL) AND (alert_ack_note IS NULL OR alert_acknowledged_by IS NOT NULL)),
  CONSTRAINT ck_subscription_suspend_source CHECK (suspend_source IS NULL OR suspend_source IN ('MANUAL', 'SECURITY', 'PH01', 'CIRCUIT_BREAKER', 'DELIVERY_BLOCKED')),
  CONSTRAINT ck_subscription_suspended CHECK ((status = 'SUSPENDED') = (suspend_source IS NOT NULL)),
  CONSTRAINT ck_subscription_approved CHECK (status NOT IN ('PROVISIONING', 'ACTIVE', 'PAUSED', 'SUSPENDED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_subscription_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_subscription_lag CHECK (lag_warn_seconds BETWEEN 30 AND 86400 AND lag_critical_seconds BETWEEN 60 AND 604800 AND lag_critical_seconds > lag_warn_seconds),
  CONSTRAINT ck_subscription_quota CHECK (quota_bytes_per_second IS NULL OR quota_bytes_per_second >= 262144),
  -- A.8: tên nhóm tiêu thụ theo chế độ, chứa tenant (BR-10-022, FR-10-064c)
  CONSTRAINT ck_subscription_group_name CHECK (
       (delivery_mode IN ('PUSH', 'PULL_API') AND consumer_group = 'dh-sub-' || ph10_event.f_topic_prefix(tenant_id) || '-' || subscription_code)
    OR (delivery_mode = 'PULL_KAFKA' AND consumer_group = 'dh-ext-' || ph10_event.f_topic_prefix(tenant_id) || '-' || subscription_code)
    OR (delivery_mode = 'INTERNAL' AND (consumer_group LIKE 'dh-flow-' || ph10_event.f_topic_prefix(tenant_id) || '-%'
                                        OR consumer_group ~ ('^dh-svc-dh-[a-z]+-' || ph10_event.f_topic_prefix(tenant_id) || '$')
                                        OR consumer_group LIKE 'dh-bridge-' || ph10_event.f_topic_prefix(tenant_id) || '-brg-%'))),
  -- Cấu hình đẩy chỉ có ở PUSH; kéo API chỉ ở PULL_API (A.3)
  CONSTRAINT ck_subscription_push_presence CHECK ((delivery_mode = 'PUSH') = (push IS NOT NULL)),
  CONSTRAINT ck_subscription_pull_presence CHECK (pull IS NULL OR delivery_mode = 'PULL_API'),
  CONSTRAINT ck_subscription_push CHECK (push IS NULL OR (
        jsonb_typeof(push) = 'object'
    AND push ->> 'endpointUrl' ~ '^https://[^/@\s]+(/[^\s]*)?$'
    AND (push ->> 'workerCount')::int BETWEEN 1 AND 64
    AND (push ->> 'maxRetries')::int BETWEEN 0 AND 50
    AND (push ->> 'timeoutMs')::int BETWEEN 1000 AND 30000
    AND push ->> 'failurePolicy' IN ('DEAD_LETTER', 'BLOCK')
    AND push ->> 'payloadFormat' IN ('CLOUDEVENTS_STRUCTURED', 'CLOUDEVENTS_BINARY')
    AND jsonb_typeof(push -> 'retryBackoff') = 'object'
    AND NOT (push ?| ARRAY['secret', 'signingSecret', 'password', 'token', 'apiKey'])
    AND (NOT push ? 'endpointVerification' OR push #>> '{endpointVerification,result}' IN ('PASSED', 'FAILED', 'WAIVED')))),
  CONSTRAINT ck_subscription_pull CHECK (pull IS NULL OR (
        jsonb_typeof(pull) = 'object'
    AND (pull ->> 'maxBatch')::int BETWEEN 1 AND 1000
    AND (pull ->> 'leaseSeconds')::int BETWEEN 10 AND 300)),
  CONSTRAINT ck_subscription_legal_basis CHECK (legal_basis IS NULL OR char_length(legal_basis) >= 5)
);
CREATE UNIQUE INDEX uq_subscription_open ON ph10_event.subscription (tenant_id, subscriber_code, topic_name) WHERE status NOT IN ('REJECTED', 'REVOKED');
CREATE INDEX ix_subscription_topic ON ph10_event.subscription (tenant_id, topic_name, status);
CREATE INDEX ix_subscription_subscriber ON ph10_event.subscription (tenant_id, subscriber_code, status);
CREATE INDEX ix_subscription_alert ON ph10_event.subscription (tenant_id, alert_state) WHERE alert_state <> 'OK';
CREATE INDEX ix_subscription_lag_collect ON ph10_event.subscription (tenant_id) INCLUDE (subscription_code, consumer_group, topic_name) WHERE status IN ('ACTIVE', 'PAUSED', 'SUSPENDED');
CREATE TRIGGER tg_subscription_touch BEFORE UPDATE ON ph10_event.subscription FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_subscription_immutable BEFORE UPDATE ON ph10_event.subscription FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('subscription_code', 'tenant_id', 'subscriber_code', 'topic_name', 'delivery_mode', 'consumer_group');
CALL ph10_event.p_enable_rls('ph10_event.subscription', 'P');
COMMENT ON TABLE ph10_event.subscription IS 'EN-10-08 Subscription (FR-10-035…048, LGC-HUB-013). Duy nhất theo cặp bên nhận, topic khi còn hiệu lực. deliveryMode khớp commType của bên nhận (BR-10-017, trigger tg_subscription_combo). Nhóm tiêu thụ theo A.8, bất biến.';
COMMENT ON COLUMN ph10_event.subscription.legal_basis IS 'Căn cứ pháp lý, bắt buộc với topic RESTRICTED, SENSITIVE (BR-10-019, trigger tg_subscription_combo).';
COMMENT ON COLUMN ph10_event.subscription.alert_acknowledged_by IS 'Người xác nhận cảnh báo lag (FR-10-055); tắt thông báo lặp 4 giờ, xóa cùng alert_acknowledged_at, alert_ack_note khi alert_state đổi mức.';
COMMENT ON COLUMN ph10_event.subscription.alert_state IS 'Trạng thái lag gần nhất do bộ thu lag cập nhật (FR-10-054, 055); đổi trạng thái phát EVT-10-10.';
COMMENT ON COLUMN ph10_event.subscription.push IS 'JSON A.3: endpointUrl (HTTPS), workerCount (≤ số phân vùng, BR-10-025), maxRetries, retryBackoff{initialMs,multiplier,maxMs}, timeoutMs, failurePolicy, payloadFormat, endpointVerifiedAt, verificationWaiverUntil, endpointVerification{result}. Không chứa bí mật.';
COMMENT ON COLUMN ph10_event.subscription.pull IS 'JSON A.3: maxBatch (≤ 10.pull.max-batch), leaseSeconds.';
--rollback DROP TABLE IF EXISTS ph10_event.subscription CASCADE;

--changeset ph10:ph10-0411-subscription-combo splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_subscription_combo() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_comm text; v_class text; v_parts int; v_topic_status text;
BEGIN
  SELECT s.comm_type INTO v_comm FROM ph10_event.subscriber s
   WHERE s.tenant_id = NEW.tenant_id AND s.subscriber_code = NEW.subscriber_code;
  IF NOT (   (v_comm = 'WEBHOOK_PUSH' AND NEW.delivery_mode = 'PUSH')
          OR (v_comm = 'HTTP_PULL' AND NEW.delivery_mode = 'PULL_API')
          OR (v_comm = 'KAFKA_NATIVE' AND NEW.delivery_mode = 'PULL_KAFKA')
          OR (v_comm IN ('INTERNAL_KAFKA', 'PULSAR_BRIDGE') AND NEW.delivery_mode = 'INTERNAL')) THEN
    RAISE EXCEPTION 'deliveryMode % không hợp với commType % (BR-10-017)', NEW.delivery_mode, v_comm USING ERRCODE = '23514';
  END IF;
  SELECT t.data_class, t.partitions, t.status INTO v_class, v_parts, v_topic_status FROM ph10_event.topic t
   WHERE t.tenant_id = NEW.tenant_id AND t.topic_name = NEW.topic_name;
  IF v_class IN ('RESTRICTED', 'SENSITIVE') AND NEW.legal_basis IS NULL THEN
    RAISE EXCEPTION 'Topic % cần căn cứ pháp lý (BR-10-019)', v_class USING ERRCODE = '23514';
  END IF;
  IF NEW.push IS NOT NULL AND (NEW.push ->> 'workerCount')::int > v_parts THEN
    RAISE EXCEPTION 'workerCount vượt số phân vùng % (BR-10-025)', v_parts USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'INSERT' AND v_topic_status IN ('DEPRECATED', 'RETIRED', 'FAILED') THEN
    RAISE EXCEPTION 'Topic % không nhận subscription mới (BR-10-016)', v_topic_status USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_subscription_combo BEFORE INSERT OR UPDATE OF delivery_mode, legal_basis, push ON ph10_event.subscription FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_subscription_combo();
--rollback DROP FUNCTION IF EXISTS ph10_event.tg_subscription_combo() CASCADE;

--changeset ph10:ph10-0420-signing-key
CREATE TABLE ph10_event.signing_key (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  subscription_code  varchar(63)   NOT NULL,
  key_id             varchar(64)   NOT NULL,
  secret_ref         varchar(255)  NOT NULL,
  status             varchar(16)   NOT NULL DEFAULT 'ACTIVE',
  activated_at       timestamptz   NOT NULL,
  previous_until     timestamptz,
  revoked_at         timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_signing_key PRIMARY KEY (id),
  CONSTRAINT uq_signing_key_kid UNIQUE (tenant_id, subscription_code, key_id),
  CONSTRAINT fk_signing_key_subscription FOREIGN KEY (tenant_id, subscription_code) REFERENCES ph10_event.subscription (tenant_id, subscription_code),
  CONSTRAINT ck_signing_key_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_signing_key_status CHECK (status IN ('ACTIVE', 'PREVIOUS', 'REVOKED')),
  CONSTRAINT ck_signing_key_kid CHECK (key_id ~ '^[a-z0-9][a-z0-9-]{2,63}$' AND key_id !~ '^whsec'),
  -- BR-10-027: chỉ đường dẫn OpenBao (A.8), không bao giờ là giá trị khóa
  CONSTRAINT ck_signing_key_secret_ref CHECK (secret_ref = 'kv/dh/' || ph10_event.f_topic_prefix(tenant_id) || '/event/subscriptions/' || subscription_code || '/signing'),
  CONSTRAINT ck_signing_key_previous CHECK (status = 'REVOKED' OR (status = 'PREVIOUS') = (previous_until IS NOT NULL)),
  CONSTRAINT ck_signing_key_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_signing_key_active ON ph10_event.signing_key (tenant_id, subscription_code) WHERE status = 'ACTIVE';
CREATE UNIQUE INDEX uq_signing_key_previous ON ph10_event.signing_key (tenant_id, subscription_code) WHERE status = 'PREVIOUS';
CREATE INDEX ix_signing_key_previous_due ON ph10_event.signing_key (previous_until) WHERE status = 'PREVIOUS';
CREATE INDEX ix_signing_key_age ON ph10_event.signing_key (activated_at) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_signing_key_touch BEFORE UPDATE ON ph10_event.signing_key FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_signing_key_immutable BEFORE UPDATE ON ph10_event.signing_key FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('tenant_id', 'subscription_code', 'key_id', 'secret_ref', 'activated_at');
CALL ph10_event.p_enable_rls('ph10_event.signing_key', 'P');
COMMENT ON TABLE ph10_event.signing_key IS 'EN-10-09 Khóa ký webhook (FR-10-042, ADR-044, ADR-071). Một ACTIVE và tối đa một PREVIOUS mỗi subscription (xoay khóa có chồng lấn 10.push.key-rotation-overlap-days). Giá trị whsec_ chỉ ở OpenBao KV v2; phiên bản KV ứng với key_id.';
COMMENT ON COLUMN ph10_event.signing_key.key_id IS 'Mã khóa gửi ở tiêu đề X-Datahub-Key-Id; không phải bí mật, không được bắt đầu bằng whsec.';
COMMENT ON COLUMN ph10_event.signing_key.secret_ref IS 'Đường dẫn OpenBao kv/dh/{tenant}/event/subscriptions/{subscriptionCode}/signing (A.8); CHECK buộc đúng mẫu nên không chứa được giá trị khóa.';
COMMENT ON COLUMN ph10_event.signing_key.previous_until IS 'Hết chồng lấn: sau thời điểm này bộ giao nhận chỉ ký bằng khóa ACTIVE; SigningKeyRotationJob chuyển REVOKED.';
--rollback DROP TABLE IF EXISTS ph10_event.signing_key CASCADE;

--changeset ph10:ph10-0430-approval-request
CREATE TABLE ph10_event.approval_request (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  request_code       varchar(63)   NOT NULL,
  request_type       varchar(20)   NOT NULL,
  target_type        varchar(20)   NOT NULL,
  target_code        varchar(255)  NOT NULL,
  payload_diff       jsonb         NOT NULL DEFAULT '{}',
  checks             jsonb         NOT NULL DEFAULT '[]',
  status             varchar(16)   NOT NULL DEFAULT 'PENDING',
  requested_by       varchar(64)   NOT NULL,
  requested_at       timestamptz   NOT NULL DEFAULT now(),
  decided_by         varchar(64),
  decided_at         timestamptz,
  decision_comment   varchar(2000),
  auto_approved      boolean       NOT NULL DEFAULT false,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_approval_request PRIMARY KEY (id),
  CONSTRAINT uq_approval_request_code UNIQUE (tenant_id, request_code),
  CONSTRAINT ck_approval_request_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_approval_request_code CHECK (request_code ~ '^apr-[0-9a-hjkmnp-tv-z]{26}$'),
  CONSTRAINT ck_approval_request_type CHECK (request_type IN ('TOPIC_CREATE', 'TOPIC_CHANGE', 'TOPIC_RETIRE', 'SCHEMA_VERSION', 'PUBLICATION', 'SUBSCRIPTION', 'REPLAY', 'BRIDGE', 'CUTOVER')),
  CONSTRAINT ck_approval_request_target_type CHECK (target_type IN ('TOPIC', 'SCHEMA_VERSION', 'PUBLICATION', 'SUBSCRIPTION', 'REPLAY', 'BRIDGE', 'MAPPING')),
  CONSTRAINT ck_approval_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_approval_request_pair CHECK (
       (request_type IN ('TOPIC_CREATE', 'TOPIC_CHANGE', 'TOPIC_RETIRE') AND target_type = 'TOPIC')
    OR (request_type = 'CUTOVER' AND target_type = 'MAPPING')
    OR (request_type NOT IN ('TOPIC_CREATE', 'TOPIC_CHANGE', 'TOPIC_RETIRE', 'CUTOVER') AND target_type = request_type)),
  CONSTRAINT ck_approval_request_decided CHECK ((status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_approval_request_reject_reason CHECK (status <> 'REJECTED' OR decision_comment IS NOT NULL),
  -- BR-10-010 bốn mắt; BR-10-031 tự duyệt ghi system:auto
  CONSTRAINT ck_approval_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_approval_request_auto CHECK (auto_approved = (decided_by IS NOT DISTINCT FROM 'system:auto')
                                             AND (NOT auto_approved OR status = 'APPROVED')),
  CONSTRAINT ck_approval_request_json CHECK (jsonb_typeof(payload_diff) = 'object' AND jsonb_typeof(checks) = 'array')
);
CREATE UNIQUE INDEX uq_approval_request_pending ON ph10_event.approval_request (tenant_id, target_type, target_code, request_type) WHERE status = 'PENDING';
CREATE INDEX ix_approval_request_inbox ON ph10_event.approval_request (tenant_id, status, request_type, requested_at DESC);
CREATE INDEX ix_approval_request_target ON ph10_event.approval_request (tenant_id, target_type, target_code, requested_at DESC);
CREATE INDEX ix_approval_request_expire ON ph10_event.approval_request (requested_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_approval_request_touch BEFORE UPDATE ON ph10_event.approval_request FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_approval_request_immutable BEFORE UPDATE ON ph10_event.approval_request FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('request_code', 'tenant_id', 'request_type', 'target_type', 'target_code', 'requested_by', 'requested_at', 'payload_diff');
CALL ph10_event.p_enable_rls('ph10_event.approval_request', 'P');
COMMENT ON TABLE ph10_event.approval_request IS 'EN-10-10 Yêu cầu duyệt chung 9 requestType (A.2.10), đổ vào Việc của tôi (UI-10-13, FR-00-070). Một yêu cầu PENDING mỗi đối tượng và loại. PENDING quá 10.approval.expire-days chuyển EXPIRED (ApprovalExpiryJob). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph10_event.approval_request.target_code IS 'topicName, publicationCode, subscriptionCode, replayCode, bridgeCode, mappingId; SCHEMA_VERSION dạng {topicName}@{versionNo}.';
COMMENT ON COLUMN ph10_event.approval_request.checks IS 'Kết quả kiểm tra tự động khi gửi duyệt (tương thích, PII, hạn mức, cấp độ ATTT).';
--rollback DROP TABLE IF EXISTS ph10_event.approval_request CASCADE;
