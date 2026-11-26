--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0030-party.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0300-publisher
CREATE TABLE ph10_event.publisher (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  publisher_code   varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  party_type       varchar(20)   NOT NULL,
  system_code      varchar(63),
  flow_code        varchar(63),
  service_code     varchar(32),
  comm_type        varchar(32)   NOT NULL,
  reference_key    varchar(255),
  client_id        varchar(255),
  kafka_principal  varchar(255),
  status           varchar(16)   NOT NULL DEFAULT 'ACTIVE',
  suspend_source   varchar(20),
  suspend_reason   varchar(1000),
  last_active_at   timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_publisher PRIMARY KEY (id),
  CONSTRAINT uq_publisher_code UNIQUE (tenant_id, publisher_code),
  CONSTRAINT fk_publisher_comm_type FOREIGN KEY (comm_type) REFERENCES ph10_event.comm_type (comm_type_code),
  CONSTRAINT ck_publisher_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_publisher_code CHECK (publisher_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_publisher_party_type CHECK (party_type IN ('SYSTEM', 'FLOW', 'INTERNAL_SERVICE', 'LEGACY_BRIDGE')),
  CONSTRAINT ck_publisher_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_publisher_suspend_source CHECK (suspend_source IS NULL OR suspend_source IN ('MANUAL', 'SECURITY', 'PH01', 'CIRCUIT_BREAKER', 'DELIVERY_BLOCKED')),
  CONSTRAINT ck_publisher_suspend_blocked CHECK (suspend_source IS DISTINCT FROM 'DELIVERY_BLOCKED'),
  CONSTRAINT ck_publisher_suspended CHECK ((status = 'SUSPENDED') = (suspend_source IS NOT NULL)),
  CONSTRAINT ck_publisher_service CHECK (service_code IS NULL OR service_code IN ('dh-connect', 'dh-integration', 'dh-runtime', 'dh-data', 'dh-platform', 'dh-payment', 'dh-assist', 'dh-portal', 'dh-cdc')),
  -- BR-10-017, A.2.8: tổ hợp partyType và commType chiều phát
  CONSTRAINT ck_publisher_combo CHECK (
       (party_type = 'SYSTEM' AND system_code IS NOT NULL AND flow_code IS NULL AND service_code IS NULL AND comm_type IN ('HTTP_PUBLISH', 'KAFKA_NATIVE'))
    OR (party_type = 'FLOW' AND flow_code IS NOT NULL AND service_code IS NULL AND comm_type = 'INTERNAL_KAFKA')
    OR (party_type = 'INTERNAL_SERVICE' AND service_code IS NOT NULL AND flow_code IS NULL AND comm_type IN ('INTERNAL_KAFKA', 'OUTBOX_CDC', 'DB_CDC'))
    OR (party_type = 'LEGACY_BRIDGE' AND comm_type = 'PULSAR_BRIDGE')),
  CONSTRAINT ck_publisher_principal CHECK (kafka_principal IS NULL OR kafka_principal ~ '^User:')
);
CREATE INDEX ix_publisher_system ON ph10_event.publisher (tenant_id, system_code) WHERE system_code IS NOT NULL;
CREATE INDEX ix_publisher_flow ON ph10_event.publisher (tenant_id, flow_code) WHERE flow_code IS NOT NULL;
CREATE INDEX ix_publisher_client ON ph10_event.publisher (tenant_id, client_id) WHERE client_id IS NOT NULL;
CREATE INDEX ix_publisher_reference ON ph10_event.publisher (tenant_id, reference_key) WHERE reference_key IS NOT NULL;
CREATE INDEX ix_publisher_name_trgm ON ph10_event.publisher USING gin (lower(name) gin_trgm_ops);
CREATE TRIGGER tg_publisher_touch BEFORE UPDATE ON ph10_event.publisher FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_publisher_immutable BEFORE UPDATE ON ph10_event.publisher FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('publisher_code', 'tenant_id', 'party_type');
CALL ph10_event.p_enable_rls('ph10_event.publisher', 'P');
COMMENT ON TABLE ph10_event.publisher IS 'EN-10-05 Bên phát (FR-10-024, 026, 028, 029, LGC-HUB-010). SYSTEM phải là HTTT thành viên PH-01 (kiểm ở dịch vụ qua bản sao system_replica của PH-01). LEGACY_BRIDGE do cầu nối di trú tạo (FR-10-073).';
COMMENT ON COLUMN ph10_event.publisher.reference_key IS 'Khóa tham chiếu kế thừa hệ cũ; dùng ghép ánh xạ khi nhập PULSAR_HUB (FR-10-072).';
COMMENT ON COLUMN ph10_event.publisher.client_id IS 'Client Keycloak của HTTT (claim azp) cho principal User:{clientId}.';
COMMENT ON COLUMN ph10_event.publisher.kafka_principal IS 'Principal Kafka theo A.8; sinh KafkaUser dh-config-{tenant}/kafka/users/{principal}.yaml.';
COMMENT ON COLUMN ph10_event.publisher.last_active_at IS 'Lần phát gần nhất, cập nhật theo lô từ chỉ số (không mỗi bản tin).';
--rollback DROP TABLE IF EXISTS ph10_event.publisher CASCADE;

--changeset ph10:ph10-0310-subscriber
CREATE TABLE ph10_event.subscriber (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  subscriber_code  varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  party_type       varchar(20)   NOT NULL,
  system_code      varchar(63),
  flow_code        varchar(63),
  service_code     varchar(32),
  comm_type        varchar(32)   NOT NULL,
  reference_key    varchar(255),
  client_id        varchar(255),
  kafka_principal  varchar(255),
  status           varchar(16)   NOT NULL DEFAULT 'ACTIVE',
  suspend_source   varchar(20),
  suspend_reason   varchar(1000),
  last_active_at   timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_subscriber PRIMARY KEY (id),
  CONSTRAINT uq_subscriber_code UNIQUE (tenant_id, subscriber_code),
  CONSTRAINT fk_subscriber_comm_type FOREIGN KEY (comm_type) REFERENCES ph10_event.comm_type (comm_type_code),
  CONSTRAINT ck_subscriber_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_subscriber_code CHECK (subscriber_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_subscriber_party_type CHECK (party_type IN ('SYSTEM', 'FLOW', 'INTERNAL_SERVICE')),
  CONSTRAINT ck_subscriber_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_subscriber_suspend_source CHECK (suspend_source IS NULL OR suspend_source IN ('MANUAL', 'SECURITY', 'PH01', 'CIRCUIT_BREAKER', 'DELIVERY_BLOCKED')),
  CONSTRAINT ck_subscriber_suspend_blocked CHECK (suspend_source IS DISTINCT FROM 'DELIVERY_BLOCKED'),
  CONSTRAINT ck_subscriber_suspended CHECK ((status = 'SUSPENDED') = (suspend_source IS NOT NULL)),
  CONSTRAINT ck_subscriber_service CHECK (service_code IS NULL OR service_code IN ('dh-connect', 'dh-integration', 'dh-runtime', 'dh-data', 'dh-platform', 'dh-payment', 'dh-assist', 'dh-portal', 'dh-cdc')),
  -- BR-10-017, A.2.8: tổ hợp chiều nhận; LEGACY_BRIDGE chỉ là bên phát
  CONSTRAINT ck_subscriber_combo CHECK (
       (party_type = 'SYSTEM' AND system_code IS NOT NULL AND flow_code IS NULL AND service_code IS NULL AND comm_type IN ('KAFKA_NATIVE', 'WEBHOOK_PUSH', 'HTTP_PULL'))
    OR (party_type = 'FLOW' AND flow_code IS NOT NULL AND service_code IS NULL AND comm_type = 'INTERNAL_KAFKA')
    OR (party_type = 'INTERNAL_SERVICE' AND service_code IS NOT NULL AND flow_code IS NULL AND comm_type IN ('INTERNAL_KAFKA', 'PULSAR_BRIDGE'))),
  CONSTRAINT ck_subscriber_principal CHECK (kafka_principal IS NULL OR kafka_principal ~ '^User:')
);
CREATE INDEX ix_subscriber_system ON ph10_event.subscriber (tenant_id, system_code) WHERE system_code IS NOT NULL;
CREATE INDEX ix_subscriber_flow ON ph10_event.subscriber (tenant_id, flow_code) WHERE flow_code IS NOT NULL;
CREATE INDEX ix_subscriber_client ON ph10_event.subscriber (tenant_id, client_id) WHERE client_id IS NOT NULL;
CREATE INDEX ix_subscriber_reference ON ph10_event.subscriber (tenant_id, reference_key) WHERE reference_key IS NOT NULL;
CREATE INDEX ix_subscriber_name_trgm ON ph10_event.subscriber USING gin (lower(name) gin_trgm_ops);
CREATE TRIGGER tg_subscriber_touch BEFORE UPDATE ON ph10_event.subscriber FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_subscriber_immutable BEFORE UPDATE ON ph10_event.subscriber FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('subscriber_code', 'tenant_id', 'party_type');
CALL ph10_event.p_enable_rls('ph10_event.subscriber', 'P');
COMMENT ON TABLE ph10_event.subscriber IS 'EN-10-06 Bên nhận (FR-10-025…029, LGC-HUB-011). Cờ "là luồng" của hệ cũ thành party_type = FLOW; isFlow chỉ suy ra ở API, không lưu.';
COMMENT ON COLUMN ph10_event.subscriber.flow_code IS 'Mã luồng PH-04 khi FLOW; không khóa ngoại sang ph04 (khác module), kiểm qua FlowQueryApi.';
--rollback DROP TABLE IF EXISTS ph10_event.subscriber CASCADE;
