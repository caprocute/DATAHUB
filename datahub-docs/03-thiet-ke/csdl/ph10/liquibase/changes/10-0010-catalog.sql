--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0010-catalog.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0100-comm-type
CREATE TABLE ph10_event.comm_type (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL DEFAULT 'COMMON',
  comm_type_code      varchar(32)   NOT NULL,
  name                varchar(255)  NOT NULL,
  direction           varchar(16)   NOT NULL,
  allowed_party_types varchar(32)[] NOT NULL,
  delivery_mode       varchar(16),
  legacy_code         varchar(64),
  enabled             boolean       NOT NULL DEFAULT true,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_comm_type PRIMARY KEY (id),
  CONSTRAINT uq_comm_type_code UNIQUE (comm_type_code),
  CONSTRAINT ck_comm_type_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_comm_type_code CHECK (comm_type_code IN ('HTTP_PUBLISH', 'KAFKA_NATIVE', 'INTERNAL_KAFKA', 'OUTBOX_CDC', 'DB_CDC', 'WEBHOOK_PUSH', 'HTTP_PULL', 'PULSAR_BRIDGE')),
  CONSTRAINT ck_comm_type_direction CHECK (direction IN ('PUBLISH', 'SUBSCRIBE', 'BOTH')),
  CONSTRAINT ck_comm_type_party CHECK (cardinality(allowed_party_types) >= 1 AND allowed_party_types <@ ARRAY['SYSTEM', 'FLOW', 'INTERNAL_SERVICE', 'LEGACY_BRIDGE']::varchar(32)[]),
  CONSTRAINT ck_comm_type_delivery CHECK (delivery_mode IS NULL OR delivery_mode IN ('PUSH', 'PULL_API', 'PULL_KAFKA', 'INTERNAL'))
);
CREATE TRIGGER tg_comm_type_touch BEFORE UPDATE ON ph10_event.comm_type FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.comm_type', 'S');
COMMENT ON TABLE ph10_event.comm_type IS 'EN-10-15 Kiểu giao tiếp (FR-10-060, LGC-HUB-014 type_of_comm). Danh mục nền tảng (tenant COMMON), seed 8 mã phụ lục A.2.8; tenant bật tắt ở comm_type_setting.';
COMMENT ON COLUMN ph10_event.comm_type.allowed_party_types IS 'partyType hợp lệ (A.2.8). PULSAR_BRIDGE: LEGACY_BRIDGE khi phát, INTERNAL_SERVICE khi nhận (cầu nối ngược).';
COMMENT ON COLUMN ph10_event.comm_type.delivery_mode IS 'deliveryMode tương ứng khi chiều nhận; NULL với mã chỉ phát.';
COMMENT ON COLUMN ph10_event.comm_type.legacy_code IS 'Mã type_of_comm của Hub cũ (giả định, Q10-01); dùng khi nhập PULSAR_HUB (FR-10-072).';
--rollback DROP TABLE IF EXISTS ph10_event.comm_type CASCADE;

--changeset ph10:ph10-0101-comm-type-setting
CREATE TABLE ph10_event.comm_type_setting (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  comm_type_code   varchar(32)   NOT NULL,
  enabled          boolean       NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_comm_type_setting PRIMARY KEY (id),
  CONSTRAINT uq_comm_type_setting UNIQUE (tenant_id, comm_type_code),
  CONSTRAINT fk_comm_type_setting_code FOREIGN KEY (comm_type_code) REFERENCES ph10_event.comm_type (comm_type_code),
  CONSTRAINT ck_comm_type_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$')
);
CREATE TRIGGER tg_comm_type_setting_touch BEFORE UPDATE ON ph10_event.comm_type_setting FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.comm_type_setting', 'P');
COMMENT ON TABLE ph10_event.comm_type_setting IS 'Phần tenant của EN-10-15: TA bật, tắt kiểu giao tiếp (FR-10-060). Không có dòng nghĩa là theo comm_type.enabled. Tắt không ảnh hưởng bên đang dùng, chỉ chặn tạo mới.';
--rollback DROP TABLE IF EXISTS ph10_event.comm_type_setting CASCADE;

--changeset ph10:ph10-0102-routing-mode
CREATE TABLE ph10_event.routing_mode (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL DEFAULT 'COMMON',
  routing_mode_code  varchar(32)   NOT NULL,
  name               varchar(255)  NOT NULL,
  ordering           varchar(255)  NOT NULL,
  legacy_code        varchar(64),
  enabled            boolean       NOT NULL DEFAULT true,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_routing_mode PRIMARY KEY (id),
  CONSTRAINT uq_routing_mode_code UNIQUE (routing_mode_code),
  CONSTRAINT ck_routing_mode_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_routing_mode_code CHECK (routing_mode_code IN ('KEY_HASH', 'ROUND_ROBIN', 'SINGLE_PARTITION'))
);
CREATE TRIGGER tg_routing_mode_touch BEFORE UPDATE ON ph10_event.routing_mode FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.routing_mode', 'S');
COMMENT ON TABLE ph10_event.routing_mode IS 'EN-10-16 Chế độ định tuyến (FR-10-061, LGC-HUB-014 routing_mode). Danh mục nền tảng, seed 3 mã phụ lục A.2.9.';
COMMENT ON COLUMN ph10_event.routing_mode.ordering IS 'Mô tả bảo đảm thứ tự (A.2.9: trong cùng khóa, không, toàn topic). Văn bản, FRS chưa đặt enum (đề nghị bổ sung §10).';
COMMENT ON COLUMN ph10_event.routing_mode.legacy_code IS 'Chế độ Pulsar tương ứng: CustomPartition, RoundRobinPartition, SinglePartition.';
--rollback DROP TABLE IF EXISTS ph10_event.routing_mode CASCADE;

--changeset ph10:ph10-0103-routing-mode-setting
CREATE TABLE ph10_event.routing_mode_setting (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  routing_mode_code  varchar(32)   NOT NULL,
  enabled            boolean       NOT NULL,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_routing_mode_setting PRIMARY KEY (id),
  CONSTRAINT uq_routing_mode_setting UNIQUE (tenant_id, routing_mode_code),
  CONSTRAINT fk_routing_mode_setting_code FOREIGN KEY (routing_mode_code) REFERENCES ph10_event.routing_mode (routing_mode_code),
  CONSTRAINT ck_routing_mode_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_routing_mode_setting_key_hash CHECK (routing_mode_code <> 'KEY_HASH' OR enabled)
);
CREATE TRIGGER tg_routing_mode_setting_touch BEFORE UPDATE ON ph10_event.routing_mode_setting FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.routing_mode_setting', 'P');
COMMENT ON TABLE ph10_event.routing_mode_setting IS 'Phần tenant của EN-10-16 (FR-10-061). KEY_HASH không tắt được vì topic orderingRequired cần nó (BR-10-006).';
--rollback DROP TABLE IF EXISTS ph10_event.routing_mode_setting CASCADE;

--changeset ph10:ph10-0104-tenant-event-quota
CREATE TABLE ph10_event.tenant_event_quota (
  id                         uuid          NOT NULL,
  tenant_id                  varchar(16)   NOT NULL,
  max_projects               integer       NOT NULL DEFAULT 200,
  max_topics                 integer       NOT NULL DEFAULT 500,
  max_partitions_total       integer       NOT NULL DEFAULT 3000,
  produce_bytes_per_second   bigint        NOT NULL DEFAULT 10485760,
  consume_bytes_per_second   bigint        NOT NULL DEFAULT 20971520,
  max_retention_hours        integer       NOT NULL DEFAULT 720,
  max_subscriptions          integer       NOT NULL DEFAULT 2000,
  max_push_workers_total     integer       NOT NULL DEFAULT 400,
  ceiling_set_by             varchar(64)   NOT NULL,
  created_at                 timestamptz   NOT NULL DEFAULT now(),
  created_by                 varchar(64)   NOT NULL,
  updated_at                 timestamptz   NOT NULL DEFAULT now(),
  updated_by                 varchar(64)   NOT NULL,
  version                    integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_event_quota PRIMARY KEY (id),
  CONSTRAINT uq_tenant_event_quota UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_event_quota_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_event_quota_ranges CHECK (
        max_projects BETWEEN 1 AND 5000 AND max_topics BETWEEN 1 AND 10000
    AND max_partitions_total BETWEEN 1 AND 50000
    AND produce_bytes_per_second >= 1048576 AND consume_bytes_per_second >= 1048576
    AND max_retention_hours BETWEEN 24 AND 2160 AND max_subscriptions BETWEEN 1 AND 50000
    AND max_push_workers_total BETWEEN 1 AND 5000)
);
CREATE TRIGGER tg_tenant_event_quota_touch BEFORE UPDATE ON ph10_event.tenant_event_quota FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.tenant_event_quota', 'P');
COMMENT ON TABLE ph10_event.tenant_event_quota IS 'EN-10-17 Hạn mức tenant (FR-10-062). PA đặt trần (miền A.5 10.quota.*), tạo khi khởi tạo tenant (FR-10-064). Mức dùng tính từ topic, subscription; phân bổ theo principal ghi ở publication, subscription (quota_bytes_per_second).';
COMMENT ON COLUMN ph10_event.tenant_event_quota.ceiling_set_by IS 'PA đặt trần gần nhất (không phải TA).';
--rollback DROP TABLE IF EXISTS ph10_event.tenant_event_quota CASCADE;
