--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0070-migration.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0700-manifest-import-job
CREATE TABLE ph10_event.manifest_import_job (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  job_code           varchar(63)   NOT NULL,
  source_kind        varchar(20)   NOT NULL,
  file_ref           varchar(512)  NOT NULL,
  status             varchar(16)   NOT NULL DEFAULT 'VALIDATING',
  validation_errors  jsonb         NOT NULL DEFAULT '[]',
  preview            jsonb         NOT NULL DEFAULT '[]',
  applied_at         timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_manifest_import_job PRIMARY KEY (id),
  CONSTRAINT uq_manifest_import_job_code UNIQUE (tenant_id, job_code),
  CONSTRAINT ck_manifest_import_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_manifest_import_job_code CHECK (job_code ~ '^imp-[0-9a-hjkmnp-tv-z]{26}$'),
  CONSTRAINT ck_manifest_import_job_source CHECK (source_kind IN ('EVENT_MANIFEST', 'PULSAR_HUB')),
  CONSTRAINT ck_manifest_import_job_status CHECK (status IN ('VALIDATING', 'PREVIEW', 'APPLYING', 'APPLIED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_manifest_import_job_applied CHECK ((status = 'APPLIED') = (applied_at IS NOT NULL)),
  CONSTRAINT ck_manifest_import_job_file CHECK (file_ref LIKE 's3://dh-event-import/' || lower(tenant_id) || '/%'),
  CONSTRAINT ck_manifest_import_job_preview CHECK (jsonb_typeof(preview) = 'array' AND jsonb_typeof(validation_errors) = 'array'
     AND NOT jsonb_path_exists(preview, '$[*] ? (!(@.changeKind == "CREATE" || @.changeKind == "UPDATE" || @.changeKind == "UNCHANGED" || @.changeKind == "CONFLICT" || @.changeKind == "SKIP"))'))
);
CREATE INDEX ix_manifest_import_job_status ON ph10_event.manifest_import_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_manifest_import_job_touch BEFORE UPDATE ON ph10_event.manifest_import_job FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.manifest_import_job', 'P');
COMMENT ON TABLE ph10_event.manifest_import_job IS 'EN-10-20 Tác vụ nhập khai báo (FR-10-071) và nhập kiểm kê Hub Pulsar (FR-10-072). Tệp ở Ceph RGW bucket dh-event-import, không lưu thân tệp trong CSDL. Giữ 5 năm với PULSAR_HUB (hồ sơ chuyển đổi), 1 năm với EVENT_MANIFEST.';
COMMENT ON COLUMN ph10_event.manifest_import_job.preview IS 'Mảng dòng xem trước {objectType, code, changeKind, diff}; changeKind theo A.2.13.';
--rollback DROP TABLE IF EXISTS ph10_event.manifest_import_job CASCADE;

--changeset ph10:ph10-0710-legacy-mapping
CREATE TABLE ph10_event.legacy_mapping (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  job_code         varchar(63)   NOT NULL,
  legacy_type      varchar(16)   NOT NULL,
  legacy_id        varchar(512)  NOT NULL,
  legacy_name      varchar(512),
  target_type      varchar(20),
  target_code      varchar(204),
  confidence       varchar(8)    NOT NULL,
  issues           jsonb         NOT NULL DEFAULT '[]',
  status           varchar(16)   NOT NULL DEFAULT 'PROPOSED',
  cut_over_at      timestamptz,
  rollback_until   timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_mapping PRIMARY KEY (id),
  CONSTRAINT uq_legacy_mapping_source UNIQUE (tenant_id, legacy_type, legacy_id),
  CONSTRAINT fk_legacy_mapping_job FOREIGN KEY (tenant_id, job_code) REFERENCES ph10_event.manifest_import_job (tenant_id, job_code),
  CONSTRAINT ck_legacy_mapping_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legacy_mapping_type CHECK (legacy_type IN ('PROJECT', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'PUBLICATION', 'SUBSCRIPTION')),
  CONSTRAINT ck_legacy_mapping_status CHECK (status IN ('PROPOSED', 'PLANNED', 'BRIDGING', 'CUT_OVER', 'ROLLED_BACK', 'CLOSED', 'SKIPPED')),
  CONSTRAINT ck_legacy_mapping_confidence CHECK (confidence IN ('HIGH', 'MEDIUM', 'LOW')),
  CONSTRAINT ck_legacy_mapping_target CHECK (status IN ('PROPOSED', 'SKIPPED') OR (target_type IS NOT NULL AND target_code IS NOT NULL)),
  CONSTRAINT ck_legacy_mapping_cut_over CHECK (status NOT IN ('CUT_OVER', 'CLOSED') OR (cut_over_at IS NOT NULL AND rollback_until > cut_over_at)),
  CONSTRAINT ck_legacy_mapping_issues CHECK (jsonb_typeof(issues) = 'array')
);
CREATE INDEX ix_legacy_mapping_job ON ph10_event.legacy_mapping (tenant_id, job_code, legacy_type);
CREATE INDEX ix_legacy_mapping_status ON ph10_event.legacy_mapping (tenant_id, legacy_type, status);
CREATE INDEX ix_legacy_mapping_target ON ph10_event.legacy_mapping (tenant_id, target_type, target_code) WHERE target_code IS NOT NULL;
CREATE INDEX ix_legacy_mapping_rollback_due ON ph10_event.legacy_mapping (rollback_until) WHERE status = 'CUT_OVER';
CREATE TRIGGER tg_legacy_mapping_touch BEFORE UPDATE ON ph10_event.legacy_mapping FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_legacy_mapping_immutable BEFORE UPDATE ON ph10_event.legacy_mapping FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('tenant_id', 'legacy_type', 'legacy_id');
CALL ph10_event.p_enable_rls('ph10_event.legacy_mapping', 'P');
COMMENT ON TABLE ph10_event.legacy_mapping IS 'EN-10-18 Ánh xạ di trú Hub Pulsar (FR-10-072, 075, 076; ADR-073). Một dòng mỗi đối tượng cũ; nhập lại cập nhật dòng (job_code trỏ lần nhập gần nhất), không tạo trùng. id chính là mappingId. Giữ 5 năm.';
COMMENT ON COLUMN ph10_event.legacy_mapping.legacy_id IS 'Khóa chính bảng cũ (project.id, publisher.id…) hoặc tên đầy đủ persistent://{tenant}/{namespace}/{topic} với TOPIC.';
COMMENT ON COLUMN ph10_event.legacy_mapping.target_type IS 'Loại đối tượng đích; FRS chưa đặt enum (đề nghị bổ sung §10). Tạm ghi cùng giá trị legacy_type, không CHECK.';
--rollback DROP TABLE IF EXISTS ph10_event.legacy_mapping CASCADE;

--changeset ph10:ph10-0720-migration-bridge
CREATE TABLE ph10_event.migration_bridge (
  id                         uuid          NOT NULL,
  tenant_id                  varchar(16)   NOT NULL,
  bridge_code                varchar(63)   NOT NULL,
  direction                  varchar(20)   NOT NULL,
  pulsar_topic               varchar(512)  NOT NULL,
  kafka_topic                varchar(204)  NOT NULL,
  pulsar_subscription_name   varchar(255)  NOT NULL DEFAULT 'dh-bridge',
  start_from                 varchar(16)   NOT NULL DEFAULT 'LATEST',
  status                     varchar(20)   NOT NULL DEFAULT 'PENDING_APPROVAL',
  expires_at                 timestamptz   NOT NULL,
  last_pulsar_message_id     varchar(255),
  bridged_count              bigint        NOT NULL DEFAULT 0,
  lag_seconds                integer,
  created_at                 timestamptz   NOT NULL DEFAULT now(),
  created_by                 varchar(64)   NOT NULL,
  updated_at                 timestamptz   NOT NULL DEFAULT now(),
  updated_by                 varchar(64)   NOT NULL,
  version                    integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_bridge PRIMARY KEY (id),
  CONSTRAINT uq_migration_bridge_code UNIQUE (tenant_id, bridge_code),
  CONSTRAINT fk_migration_bridge_topic FOREIGN KEY (tenant_id, kafka_topic) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT ck_migration_bridge_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_migration_bridge_code CHECK (bridge_code ~ '^brg-[0-9a-hjkmnp-tv-z]{26}$'),
  CONSTRAINT ck_migration_bridge_direction CHECK (direction IN ('PULSAR_TO_KAFKA', 'KAFKA_TO_PULSAR')),
  CONSTRAINT ck_migration_bridge_status CHECK (status IN ('PENDING_APPROVAL', 'RUNNING', 'STOPPED', 'ERROR', 'EXPIRED')),
  CONSTRAINT ck_migration_bridge_start CHECK (start_from IN ('LATEST', 'EARLIEST')),
  CONSTRAINT ck_migration_bridge_pulsar CHECK (pulsar_topic ~ '^(persistent|non-persistent)://[^/]+/[^/]+/.+$'),
  CONSTRAINT ck_migration_bridge_expiry CHECK (expires_at > created_at AND expires_at <= created_at + interval '365 days'),
  CONSTRAINT ck_migration_bridge_counts CHECK (bridged_count >= 0 AND (lag_seconds IS NULL OR lag_seconds >= 0))
);
-- BR-10-033, ERR-10-042: không hai cầu nối còn hiệu lực trên cùng cặp topic, kể cả ngược chiều
CREATE UNIQUE INDEX uq_migration_bridge_pair ON ph10_event.migration_bridge (tenant_id, kafka_topic, pulsar_topic) WHERE status IN ('PENDING_APPROVAL', 'RUNNING', 'ERROR');
CREATE INDEX ix_migration_bridge_expiry ON ph10_event.migration_bridge (expires_at) WHERE status = 'RUNNING';
CREATE TRIGGER tg_migration_bridge_touch BEFORE UPDATE ON ph10_event.migration_bridge FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_migration_bridge_immutable BEFORE UPDATE ON ph10_event.migration_bridge FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('bridge_code', 'tenant_id', 'direction', 'pulsar_topic', 'kafka_topic');
CALL ph10_event.p_enable_rls('ph10_event.migration_bridge', 'P');
COMMENT ON TABLE ph10_event.migration_bridge IS 'EN-10-19 Cầu nối di trú Pulsar, Kafka (FR-10-073, 074; ADR-073). Tạm thời, hạn ≤ 10.migration.bridge-max-days (trần 365 ngày ở CSDL). Tiến độ (last_pulsar_message_id, bridged_count, lag_seconds) do dh-runtime báo, cập nhật theo lô 30 giây.';
--rollback DROP TABLE IF EXISTS ph10_event.migration_bridge CASCADE;
