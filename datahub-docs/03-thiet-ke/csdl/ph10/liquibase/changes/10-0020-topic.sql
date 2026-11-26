--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0020-topic.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0200-event-project
CREATE TABLE ph10_event.event_project (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  project_code     varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  owner_org_code   varchar(63)   NOT NULL,
  owner_user       varchar(63)   NOT NULL,
  status           varchar(16)   NOT NULL DEFAULT 'ACTIVE',
  labels           varchar(63)[] NOT NULL DEFAULT '{}',
  archived_at      timestamptz,
  archive_reason   varchar(2000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_event_project PRIMARY KEY (id),
  CONSTRAINT uq_event_project_code UNIQUE (tenant_id, project_code),
  CONSTRAINT ck_event_project_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_event_project_code CHECK (project_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_event_project_reserved CHECK (project_code NOT IN ('moi', 'tong-quan', 'nhap', 'di-tru', 'ben-phat', 'ben-nhan')),
  CONSTRAINT ck_event_project_status CHECK (status IN ('ACTIVE', 'ARCHIVED')),
  CONSTRAINT ck_event_project_archived CHECK ((status = 'ARCHIVED') = (archived_at IS NOT NULL)
                                              AND (status <> 'ARCHIVED' OR archive_reason IS NOT NULL)),
  CONSTRAINT ck_event_project_labels CHECK (cardinality(labels) <= 10)
);
CREATE INDEX ix_event_project_status ON ph10_event.event_project (tenant_id, status);
CREATE INDEX ix_event_project_name_trgm ON ph10_event.event_project USING gin (lower(name) gin_trgm_ops);
CREATE INDEX ix_event_project_labels ON ph10_event.event_project USING gin (labels);
CREATE TRIGGER tg_event_project_touch BEFORE UPDATE ON ph10_event.event_project FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_event_project_immutable BEFORE UPDATE ON ph10_event.event_project FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('project_code', 'tenant_id');
CALL ph10_event.p_enable_rls('ph10_event.event_project', 'P');
COMMENT ON TABLE ph10_event.event_project IS 'EN-10-01 Dự án tích hợp (FR-10-001…006, LGC-HUB-008). Mã bất biến, không dùng lại kể cả khi ARCHIVED (BR-10-003): không xóa cứng. Dự án hệ thống cdc-{adapterCode} tự tạo khi PH-05 đăng ký topic CDC (FR-10-066).';
COMMENT ON COLUMN ph10_event.event_project.project_code IS 'T-CODE; không trùng từ dành riêng của route /tich-hop/du-an (A.6).';
COMMENT ON COLUMN ph10_event.event_project.owner_org_code IS 'Mã cơ quan chủ quản (PH-12, PH-20); không khóa ngoại vì khác schema.';
--rollback DROP TABLE IF EXISTS ph10_event.event_project CASCADE;

--changeset ph10:ph10-0210-topic
CREATE TABLE ph10_event.topic (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  topic_name            varchar(204)  NOT NULL,
  project_code          varchar(63),
  topic_kind            varchar(16)   NOT NULL,
  domain                varchar(63)   NOT NULL,
  entity                varchar(63)   NOT NULL,
  event_name            varchar(63)   NOT NULL,
  major_version         integer       NOT NULL,
  description           varchar(2000),
  partitions            integer       NOT NULL,
  replication_factor    smallint      NOT NULL DEFAULT 3,
  min_insync_replicas   smallint      NOT NULL DEFAULT 2,
  retention_hours       integer       NOT NULL,
  cleanup_policy        varchar(16)   NOT NULL DEFAULT 'DELETE',
  max_message_bytes     integer       NOT NULL DEFAULT 1048576,
  routing_mode          varchar(32)   NOT NULL,
  partition_key_field   varchar(255),
  ordering_required     boolean       NOT NULL DEFAULT false,
  data_class            varchar(16)   NOT NULL,
  status                varchar(20)   NOT NULL DEFAULT 'DRAFT',
  predecessor_topic     varchar(204),
  successor_topic       varchar(204),
  sunset_at             timestamptz,
  provisioning_commit   varchar(64),
  provisioning_error    varchar(2000),
  activated_at          timestamptz,
  retired_at            timestamptz,
  owner_service_code    varchar(32),
  source_ref            jsonb,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_topic PRIMARY KEY (id),
  CONSTRAINT uq_topic_name UNIQUE (tenant_id, topic_name),
  CONSTRAINT fk_topic_project FOREIGN KEY (tenant_id, project_code) REFERENCES ph10_event.event_project (tenant_id, project_code),
  CONSTRAINT fk_topic_routing_mode FOREIGN KEY (routing_mode) REFERENCES ph10_event.routing_mode (routing_mode_code),
  CONSTRAINT fk_topic_predecessor FOREIGN KEY (tenant_id, predecessor_topic) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT fk_topic_successor FOREIGN KEY (tenant_id, successor_topic) REFERENCES ph10_event.topic (tenant_id, topic_name) DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT ck_topic_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_topic_kind CHECK (topic_kind IN ('BUSINESS', 'CDC', 'SYSTEM', 'DLQ')),
  CONSTRAINT ck_topic_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'PROVISIONING', 'FAILED', 'ACTIVE', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_topic_data_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_topic_cleanup_policy CHECK (cleanup_policy IN ('DELETE', 'COMPACT', 'COMPACT_DELETE')),
  CONSTRAINT ck_topic_routing_mode CHECK (routing_mode IN ('KEY_HASH', 'ROUND_ROBIN', 'SINGLE_PARTITION')),
  CONSTRAINT ck_topic_service CHECK (owner_service_code IS NULL OR owner_service_code IN ('dh-connect', 'dh-integration', 'dh-runtime', 'dh-data', 'dh-platform', 'dh-payment', 'dh-assist', 'dh-portal', 'dh-cdc')),
  -- BR-10-002: tiền tố tenant, chữ thường; hậu tố .dlq chỉ cho topic DLQ
  CONSTRAINT ck_topic_prefix CHECK (split_part(topic_name, '.', 1) = ph10_event.f_topic_prefix(tenant_id)),
  CONSTRAINT ck_topic_name_business CHECK (topic_kind <> 'BUSINESS' OR (
        char_length(topic_name) <= 200
    AND topic_name ~ '^[a-z0-9]+\.[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2}\.v[1-9][0-9]*$'
    AND topic_name = ph10_event.f_topic_prefix(tenant_id) || '.' || domain || '.' || entity || '.' || event_name || '.v' || major_version)),
  CONSTRAINT ck_topic_name_machine CHECK (topic_kind NOT IN ('CDC', 'SYSTEM') OR (
        char_length(topic_name) <= 200
    AND topic_name ~ '^[a-z0-9]+(\.[a-z][a-z0-9-]*){2,4}\.v[1-9][0-9]*$'
    AND topic_name LIKE '%.v' || major_version)),
  CONSTRAINT ck_topic_name_dlq CHECK ((topic_kind = 'DLQ') = (topic_name LIKE '%.dlq')),
  CONSTRAINT ck_topic_reserved_domain CHECK (topic_kind <> 'BUSINESS' OR domain NOT IN ('event', 'cdc', 'audit', 'obs', 'integration', 'adapter', 'rdm', 'connect', 'payment', 'platform')),
  CONSTRAINT ck_topic_segments CHECK (domain ~ '^[a-z][a-z0-9-]*$' AND entity ~ '^[a-z][a-z0-9-]*$' AND event_name ~ '^[a-z][a-z0-9-]*$' AND major_version >= 1),
  -- BR-10-004, BR-10-006
  CONSTRAINT ck_topic_replication CHECK (replication_factor = 3 AND min_insync_replicas = 2),
  CONSTRAINT ck_topic_partitions CHECK (partitions BETWEEN 1 AND 200),
  CONSTRAINT ck_topic_retention CHECK (retention_hours BETWEEN 1 AND 2160),
  CONSTRAINT ck_topic_max_message CHECK (max_message_bytes BETWEEN 1024 AND 1048576),
  CONSTRAINT ck_topic_ordering CHECK (NOT ordering_required OR routing_mode IN ('KEY_HASH', 'SINGLE_PARTITION')),
  CONSTRAINT ck_topic_key_field CHECK (routing_mode <> 'KEY_HASH' OR partition_key_field IS NOT NULL),
  CONSTRAINT ck_topic_compact_key CHECK (cleanup_policy = 'DELETE' OR routing_mode = 'KEY_HASH'),
  CONSTRAINT ck_topic_project CHECK (topic_kind NOT IN ('BUSINESS', 'CDC') OR project_code IS NOT NULL),
  CONSTRAINT ck_topic_owner_service CHECK ((topic_kind IN ('CDC', 'SYSTEM')) = (owner_service_code IS NOT NULL)),
  CONSTRAINT ck_topic_activated CHECK (status NOT IN ('ACTIVE', 'DEPRECATED') OR activated_at IS NOT NULL),
  CONSTRAINT ck_topic_deprecated CHECK (status <> 'DEPRECATED' OR sunset_at IS NOT NULL),
  CONSTRAINT ck_topic_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_topic_failed CHECK (status <> 'FAILED' OR provisioning_error IS NOT NULL),
  CONSTRAINT ck_topic_commit CHECK (provisioning_commit IS NULL OR provisioning_commit ~ '^[0-9a-f]{7,64}$'),
  CONSTRAINT ck_topic_source_ref CHECK (source_ref IS NULL OR jsonb_typeof(source_ref) = 'object'),
  CONSTRAINT ck_topic_not_self CHECK (predecessor_topic IS DISTINCT FROM topic_name AND successor_topic IS DISTINCT FROM topic_name)
);
CREATE INDEX ix_topic_project ON ph10_event.topic (tenant_id, project_code, status);
CREATE INDEX ix_topic_kind_status ON ph10_event.topic (tenant_id, topic_kind, status);
CREATE INDEX ix_topic_domain ON ph10_event.topic (tenant_id, domain, entity);
CREATE INDEX ix_topic_name_trgm ON ph10_event.topic USING gin (topic_name gin_trgm_ops);
CREATE INDEX ix_topic_provisioning ON ph10_event.topic (updated_at) WHERE status = 'PROVISIONING';
CREATE INDEX ix_topic_sunset ON ph10_event.topic (sunset_at) WHERE status = 'DEPRECATED';
CREATE INDEX ix_topic_retired ON ph10_event.topic (retired_at) WHERE status = 'RETIRED';
CREATE TRIGGER tg_topic_touch BEFORE UPDATE ON ph10_event.topic FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_topic_immutable BEFORE UPDATE ON ph10_event.topic FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('topic_name', 'tenant_id', 'topic_kind', 'domain', 'entity', 'event_name', 'major_version', 'replication_factor', 'min_insync_replicas');
CALL ph10_event.p_enable_rls('ph10_event.topic', 'P');
COMMENT ON TABLE ph10_event.topic IS 'EN-10-02 Topic (FR-10-007…016, LGC-HUB-009). Tên bất biến, không dùng lại (BR-10-003); không xóa dòng, chỉ RETIRED. Topic DLQ {topicName}.dlq (topic_kind DLQ) tạo cùng topic gốc (BR-10-023). Topic nền tảng dh.* thuộc tenant COMMON (FR-10-067). Cấu hình cụm sinh vào dh-config-{tenant}/kafka/topics/{topicName}.yaml (ADR-072).';
COMMENT ON COLUMN ph10_event.topic.topic_name IS 'BR-10-002: ≤ 200 ký tự; topic DLQ thêm .dlq (≤ 204). Tiền tố tenant chữ thường hoặc dh.';
COMMENT ON COLUMN ph10_event.topic.project_code IS 'Bắt buộc với BUSINESS, CDC; NULL được với SYSTEM (theo DU) và DLQ (theo topic gốc).';
COMMENT ON COLUMN ph10_event.topic.partitions IS 'Chỉ tăng (BR-10-005, kiểm ở dịch vụ); trần 10.topic.max-partitions của tenant.';
COMMENT ON COLUMN ph10_event.topic.retention_hours IS 'Mặc định 10.topic.default-retention-hours; trần tenant_event_quota.max_retention_hours (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph10_event.topic.provisioning_commit IS 'SHA commit kho dh-config-{tenant} chứa KafkaTopic (ADR-072).';
COMMENT ON COLUMN ph10_event.topic.owner_service_code IS 'DU chủ (A.2.12) của topic CDC (dh-cdc), SYSTEM.';
COMMENT ON COLUMN ph10_event.topic.source_ref IS 'Nguồn đăng ký máy, ví dụ {"adapterCode":"dkkd-db","schema":"public","table":"doanh-nghiep"} của PH-05, hoặc {"legacyTopic":"persistent://..."} khi di trú.';
--rollback DROP TABLE IF EXISTS ph10_event.topic CASCADE;

--changeset ph10:ph10-0220-event-schema
CREATE TABLE ph10_event.event_schema (
  id                     uuid          NOT NULL,
  tenant_id              varchar(16)   NOT NULL,
  topic_name             varchar(204)  NOT NULL,
  schema_format          varchar(16)   NOT NULL,
  compatibility          varchar(24)   NOT NULL DEFAULT 'BACKWARD',
  apicurio_group_id      varchar(16)   NOT NULL,
  apicurio_artifact_id   varchar(204)  NOT NULL,
  latest_version_no      integer       NOT NULL DEFAULT 0,
  created_at             timestamptz   NOT NULL DEFAULT now(),
  created_by             varchar(64)   NOT NULL,
  updated_at             timestamptz   NOT NULL DEFAULT now(),
  updated_by             varchar(64)   NOT NULL,
  version                integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_event_schema PRIMARY KEY (id),
  CONSTRAINT uq_event_schema_topic UNIQUE (tenant_id, topic_name),
  CONSTRAINT fk_event_schema_topic FOREIGN KEY (tenant_id, topic_name) REFERENCES ph10_event.topic (tenant_id, topic_name),
  CONSTRAINT ck_event_schema_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_event_schema_format CHECK (schema_format IN ('AVRO', 'JSON_SCHEMA')),
  CONSTRAINT ck_event_schema_compatibility CHECK (compatibility IN ('BACKWARD', 'BACKWARD_TRANSITIVE', 'FORWARD', 'FORWARD_TRANSITIVE', 'FULL', 'FULL_TRANSITIVE', 'NONE')),
  -- ADR-070, A.8: groupId = tenant chữ thường (dh cho nền tảng), artifactId = topicName
  CONSTRAINT ck_event_schema_artifact CHECK (apicurio_group_id = ph10_event.f_topic_prefix(tenant_id) AND apicurio_artifact_id = topic_name),
  CONSTRAINT ck_event_schema_latest CHECK (latest_version_no >= 0)
);
CREATE TRIGGER tg_event_schema_touch BEFORE UPDATE ON ph10_event.event_schema FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_event_schema_immutable BEFORE UPDATE ON ph10_event.event_schema FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('topic_name', 'tenant_id', 'schema_format', 'apicurio_group_id', 'apicurio_artifact_id');
CALL ph10_event.p_enable_rls('ph10_event.event_schema', 'P');
COMMENT ON TABLE ph10_event.event_schema IS 'EN-10-03 Lược đồ giá trị, đúng một cho mỗi topic (BR-10-011, FR-10-017…023). Bản sao siêu dữ liệu của artifact Apicurio (ADR-070); Apicurio là nơi serde đọc, bảng này là nơi duyệt và truy vết.';
COMMENT ON COLUMN ph10_event.event_schema.compatibility IS 'Ánh xạ thẳng quy tắc COMPATIBILITY của Apicurio. NONE chỉ khi topic chưa từng ACTIVE (BR-10-012, trigger tg_event_schema_none).';
--rollback DROP TABLE IF EXISTS ph10_event.event_schema CASCADE;

--changeset ph10:ph10-0221-event-schema-none splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_event_schema_none() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.compatibility = 'NONE' AND EXISTS (
       SELECT 1 FROM ph10_event.topic t
        WHERE t.tenant_id = NEW.tenant_id AND t.topic_name = NEW.topic_name AND t.activated_at IS NOT NULL) THEN
    RAISE EXCEPTION 'Mức NONE chỉ cho topic chưa từng ACTIVE (BR-10-012, ERR-10-017)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_event_schema_none BEFORE INSERT OR UPDATE OF compatibility ON ph10_event.event_schema FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_event_schema_none();
--rollback DROP FUNCTION IF EXISTS ph10_event.tg_event_schema_none() CASCADE;

--changeset ph10:ph10-0230-schema-version
CREATE TABLE ph10_event.schema_version (
  id                     uuid          NOT NULL,
  tenant_id              varchar(16)   NOT NULL,
  topic_name             varchar(204)  NOT NULL,
  version_no             integer       NOT NULL,
  content                text          NOT NULL,
  content_hash           char(64)      NOT NULL,
  status                 varchar(20)   NOT NULL DEFAULT 'DRAFT',
  apicurio_global_id     bigint,
  apicurio_content_id    bigint,
  compatibility_report   jsonb,
  pii_findings           jsonb         NOT NULL DEFAULT '[]',
  change_note            varchar(2000),
  checked_at             timestamptz,
  enabled_at             timestamptz,
  created_at             timestamptz   NOT NULL DEFAULT now(),
  created_by             varchar(64)   NOT NULL,
  updated_at             timestamptz   NOT NULL DEFAULT now(),
  updated_by             varchar(64)   NOT NULL,
  version                integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_schema_version PRIMARY KEY (id),
  CONSTRAINT uq_schema_version_no UNIQUE (tenant_id, topic_name, version_no),
  CONSTRAINT fk_schema_version_schema FOREIGN KEY (tenant_id, topic_name) REFERENCES ph10_event.event_schema (tenant_id, topic_name),
  CONSTRAINT ck_schema_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_schema_version_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'ENABLED', 'DEPRECATED', 'DISABLED')),
  CONSTRAINT ck_schema_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_schema_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_schema_version_size CHECK (octet_length(content) <= 262144),
  CONSTRAINT ck_schema_version_enabled CHECK (status NOT IN ('ENABLED', 'DEPRECATED', 'DISABLED')
                                              OR (apicurio_global_id IS NOT NULL AND apicurio_content_id IS NOT NULL AND enabled_at IS NOT NULL)),
  CONSTRAINT ck_schema_version_checked CHECK (status IN ('DRAFT', 'REJECTED') OR checked_at IS NOT NULL),
  CONSTRAINT ck_schema_version_pii CHECK (jsonb_typeof(pii_findings) = 'array'
     AND NOT jsonb_path_exists(pii_findings, '$[*] ? (!(@.severity == "INFO" || @.severity == "WARNING" || @.severity == "BLOCKING"))')),
  CONSTRAINT ck_schema_version_report CHECK (compatibility_report IS NULL OR jsonb_typeof(compatibility_report) = 'object')
);
CREATE UNIQUE INDEX uq_schema_version_one_open ON ph10_event.schema_version (tenant_id, topic_name) WHERE status IN ('DRAFT', 'PENDING_APPROVAL');
CREATE INDEX ix_schema_version_status ON ph10_event.schema_version (tenant_id, topic_name, status);
CREATE INDEX ix_schema_version_global ON ph10_event.schema_version (apicurio_global_id) WHERE apicurio_global_id IS NOT NULL;
CREATE TRIGGER tg_schema_version_touch BEFORE UPDATE ON ph10_event.schema_version FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CREATE TRIGGER tg_schema_version_immutable BEFORE UPDATE ON ph10_event.schema_version FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_immutable('topic_name', 'tenant_id', 'version_no');
CALL ph10_event.p_enable_rls('ph10_event.schema_version', 'P');
COMMENT ON TABLE ph10_event.schema_version IS 'EN-10-04 Phiên bản lược đồ (FR-10-018…022). Một bản nháp hoặc chờ duyệt mỗi topic; nội dung bất biến từ ENABLED (BR-10-013, trigger tg_schema_version_frozen); chỉ chuyển ENABLED, DEPRECATED, DISABLED. Giữ vĩnh viễn.';
COMMENT ON COLUMN ph10_event.schema_version.content IS 'Văn bản lược đồ Avro (.avsc) hoặc JSON Schema; ≤ 256 KiB (giả định, Q10-53).';
COMMENT ON COLUMN ph10_event.schema_version.content_hash IS 'SHA-256 hex của nội dung chuẩn hóa; chống gửi trùng.';
COMMENT ON COLUMN ph10_event.schema_version.apicurio_global_id IS 'globalId Apicurio; serde ghi vào tiền tố bản tin, bộ giám sát tuân thủ đối chiếu (ERR-10-119).';
COMMENT ON COLUMN ph10_event.schema_version.pii_findings IS 'Mảng {field, reason, severity}; severity theo A.2.4 (INFO, WARNING, BLOCKING).';
--rollback DROP TABLE IF EXISTS ph10_event.schema_version CASCADE;

--changeset ph10:ph10-0231-schema-version-frozen splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_schema_version_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status IN ('ENABLED', 'DEPRECATED', 'DISABLED') THEN
    IF NEW.content IS DISTINCT FROM OLD.content OR NEW.content_hash IS DISTINCT FROM OLD.content_hash
       OR NEW.apicurio_global_id IS DISTINCT FROM OLD.apicurio_global_id THEN
      RAISE EXCEPTION 'Phiên bản lược đồ đã bật là bất biến (BR-10-013)' USING ERRCODE = '55000';
    END IF;
    IF NEW.status NOT IN ('ENABLED', 'DEPRECATED', 'DISABLED') THEN
      RAISE EXCEPTION 'Phiên bản đã bật không quay về %', NEW.status USING ERRCODE = '55000';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_schema_version_frozen BEFORE UPDATE ON ph10_event.schema_version FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_schema_version_frozen();
--rollback DROP FUNCTION IF EXISTS ph10_event.tg_schema_version_frozen() CASCADE;
