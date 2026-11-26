-- =============================================================================
-- D03-03-PH10 · DDL schema ph10_event — PH-10 Sự kiện
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph10_event.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH10 phụ lục A. Cột là snake_case của tên trường
-- API; ngoại lệ ghi ở D03-03-PH10 §1.3 (offset là từ khóa SQL nên cột là record_offset).
-- Không lưu giá trị bí mật ký webhook (BR-10-027): chỉ đường dẫn OpenBao (secret_ref).
-- Nội dung mục DLQ của topic RESTRICTED, SENSITIVE mã hóa ở ứng dụng bằng OpenBao transit.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 10-0000-bootstrap.sql
-- @changeset ph10-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_owner') THEN
    CREATE ROLE ph10_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_app') THEN
    CREATE ROLE ph10_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_readonly') THEN
    CREATE ROLE ph10_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph10-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph10_event AUTHORIZATION ph10_owner;
COMMENT ON SCHEMA ph10_event IS 'PH-10 Sự kiện (control plane trong dh-integration, package vn.datahub.integration.event): dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription, khóa ký, duyệt, DLQ, phát lại, lag, danh mục, hạn mức, di trú Pulsar. Không có giá trị bí mật.';
GRANT USAGE ON SCHEMA ph10_event TO ph10_app, ph10_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph10_event CASCADE;

SET ROLE ph10_owner;

-- @changeset ph10-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 10-0001-functions.sql
-- @changeset ph10-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph10_event.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph10_event.tg_touch();

-- @changeset ph10-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến (BR-10-003)', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph10_event.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, tên topic, khóa tham chiếu (BR-10-003).';
-- @rollback DROP FUNCTION IF EXISTS ph10_event.tg_immutable();

-- @changeset ph10-0012-fn-rls splitStatements:false
-- Hai mẫu như PH-04, PH-05: 'P' riêng tenant (dòng COMMON chỉ phiên PLATFORM đọc, ghi);
-- 'S' dùng chung (tenant đọc thêm dòng COMMON, chỉ phiên PLATFORM ghi COMMON).
CREATE OR REPLACE PROCEDURE ph10_event.p_enable_rls(p_table regclass, p_mode char)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
            OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))$w$;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  r := CASE p_mode WHEN 'S' THEN $r$(tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'))$r$ ELSE w END;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph10_event.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10 §4).';
-- @rollback DROP PROCEDURE IF EXISTS ph10_event.p_enable_rls(regclass, char);

-- @changeset ph10-0013-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph10_event.p_ensure_partitions(p_table regclass, p_from date, p_count integer, p_unit text)
  LANGUAGE plpgsql AS $p$
DECLARE
  step interval := CASE p_unit WHEN 'day' THEN interval '1 day' WHEN 'month' THEN interval '1 month' END;
  d timestamptz := date_trunc(p_unit, p_from::timestamptz);
  i integer;
  part text;
BEGIN
  IF step IS NULL THEN RAISE EXCEPTION 'p_unit phải là day hoặc month'; END IF;
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text,
                   to_char(d + step * i, CASE p_unit WHEN 'day' THEN 'YYYYMMDD' ELSE 'YYYYMM' END));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + step * i, d + step * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph10_event.p_ensure_partitions(regclass, date, integer, text) IS 'Tạo trước phân vùng ngày (lag_sample) hoặc tháng (delivery_stat, delivery_failure, lag_sample_5m). PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph10_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph10_event.p_ensure_partitions(regclass, date, integer, text);

-- @changeset ph10-0014-fn-helpers splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.f_topic_prefix(p_tenant text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE WHEN p_tenant = 'COMMON' THEN 'dh' ELSE lower(p_tenant) END
$f$;
COMMENT ON FUNCTION ph10_event.f_topic_prefix(text) IS 'Tiền tố topic của tenant: t68 cho T68, dh cho COMMON (topic nền tảng, FR-10-067).';
-- @rollback DROP FUNCTION IF EXISTS ph10_event.f_topic_prefix(text);

-- @file 10-0010-catalog.sql
-- @changeset ph10-0100-comm-type
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
-- @rollback DROP TABLE IF EXISTS ph10_event.comm_type CASCADE;

-- @changeset ph10-0101-comm-type-setting
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
-- @rollback DROP TABLE IF EXISTS ph10_event.comm_type_setting CASCADE;

-- @changeset ph10-0102-routing-mode
CREATE TABLE ph10_event.routing_mode (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL DEFAULT 'COMMON',
  routing_mode_code  varchar(32)   NOT NULL,
  name               varchar(255)  NOT NULL,
  ordering           varchar(16)   NOT NULL,
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
  CONSTRAINT ck_routing_mode_code CHECK (routing_mode_code IN ('KEY_HASH', 'ROUND_ROBIN', 'SINGLE_PARTITION')),
  CONSTRAINT ck_routing_mode_ordering CHECK (ordering IN ('PER_KEY', 'NONE', 'TOTAL'))
);
CREATE TRIGGER tg_routing_mode_touch BEFORE UPDATE ON ph10_event.routing_mode FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_touch();
CALL ph10_event.p_enable_rls('ph10_event.routing_mode', 'S');
COMMENT ON TABLE ph10_event.routing_mode IS 'EN-10-16 Chế độ định tuyến (FR-10-061, LGC-HUB-014 routing_mode). Danh mục nền tảng, seed 3 mã phụ lục A.2.9.';
COMMENT ON COLUMN ph10_event.routing_mode.ordering IS 'Bảo đảm thứ tự (A.2.9): PER_KEY trong cùng khóa, NONE không bảo đảm, TOTAL toàn topic.';
COMMENT ON COLUMN ph10_event.routing_mode.legacy_code IS 'Chế độ Pulsar tương ứng: CustomPartition, RoundRobinPartition, SinglePartition.';
-- @rollback DROP TABLE IF EXISTS ph10_event.routing_mode CASCADE;

-- @changeset ph10-0103-routing-mode-setting
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
-- @rollback DROP TABLE IF EXISTS ph10_event.routing_mode_setting CASCADE;

-- @changeset ph10-0104-tenant-event-quota
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
-- @rollback DROP TABLE IF EXISTS ph10_event.tenant_event_quota CASCADE;

-- @file 10-0020-topic.sql
-- @changeset ph10-0200-event-project
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
-- @rollback DROP TABLE IF EXISTS ph10_event.event_project CASCADE;

-- @changeset ph10-0210-topic
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
-- @rollback DROP TABLE IF EXISTS ph10_event.topic CASCADE;

-- @changeset ph10-0220-event-schema
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
-- @rollback DROP TABLE IF EXISTS ph10_event.event_schema CASCADE;

-- @changeset ph10-0221-event-schema-none splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_event_schema_none() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.compatibility = 'NONE' AND EXISTS (
       SELECT 1 FROM ph10_event.topic t
        WHERE t.tenant_id = NEW.tenant_id AND t.topic_name = NEW.topic_name AND t.activated_at IS NOT NULL) THEN
    RAISE EXCEPTION 'Mức NONE chỉ cho topic chưa từng ACTIVE (BR-10-012, ERR-10-019)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_event_schema_none BEFORE INSERT OR UPDATE OF compatibility ON ph10_event.event_schema FOR EACH ROW EXECUTE FUNCTION ph10_event.tg_event_schema_none();
-- @rollback DROP FUNCTION IF EXISTS ph10_event.tg_event_schema_none() CASCADE;

-- @changeset ph10-0230-schema-version
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
-- @rollback DROP TABLE IF EXISTS ph10_event.schema_version CASCADE;

-- @changeset ph10-0231-schema-version-frozen splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph10_event.tg_schema_version_frozen() CASCADE;

-- @file 10-0030-party.sql
-- @changeset ph10-0300-publisher
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
-- @rollback DROP TABLE IF EXISTS ph10_event.publisher CASCADE;

-- @changeset ph10-0310-subscriber
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
-- @rollback DROP TABLE IF EXISTS ph10_event.subscriber CASCADE;

-- @file 10-0040-relation.sql
-- @changeset ph10-0400-publication
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
-- @rollback DROP TABLE IF EXISTS ph10_event.publication CASCADE;

-- @changeset ph10-0410-subscription
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
-- @rollback DROP TABLE IF EXISTS ph10_event.subscription CASCADE;

-- @changeset ph10-0411-subscription-combo splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph10_event.tg_subscription_combo() CASCADE;

-- @changeset ph10-0420-signing-key
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
-- @rollback DROP TABLE IF EXISTS ph10_event.signing_key CASCADE;

-- @changeset ph10-0430-approval-request
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
-- @rollback DROP TABLE IF EXISTS ph10_event.approval_request CASCADE;

-- @file 10-0050-delivery.sql
-- @changeset ph10-0500-delivery-stat
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
-- @rollback DROP TABLE IF EXISTS ph10_event.delivery_stat CASCADE;

-- @changeset ph10-0510-delivery-failure
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
-- @rollback DROP TABLE IF EXISTS ph10_event.delivery_failure CASCADE;

-- @file 10-0060-dlq.sql
-- @changeset ph10-0600-replay-request
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
-- @rollback DROP TABLE IF EXISTS ph10_event.replay_request CASCADE;

-- @changeset ph10-0610-dlq-entry
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
  bridge_code        varchar(63),
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
  CONSTRAINT ck_dlq_entry_bridge_code CHECK ((origin = 'BRIDGE') = (bridge_code IS NOT NULL) AND (bridge_code IS NULL OR (bridge_code ~ '^brg-[0-9a-hjkmnp-tv-z]{26}$' AND subscription_code IS NULL))),
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
COMMENT ON COLUMN ph10_event.dlq_entry.subscription_code IS 'NULL chỉ với origin BRIDGE (lỗi chuyển bản tin của cầu nối, ERR-10-118); khi đó bridge_code xác định cầu nối.';
COMMENT ON COLUMN ph10_event.dlq_entry.bridge_code IS 'Mã cầu nối khi origin BRIDGE (A.3, tiêu đề dh_dlq_bridge). Không có khóa ngoại vì migration_bridge tạo sau; ứng dụng kiểm tồn tại';
COMMENT ON COLUMN ph10_event.dlq_entry.payload_ref IS 'pg:dlq_payload/{dlqEntryId}; NULL sau khi dọn nội dung (PURGED).';
-- @rollback DROP TABLE IF EXISTS ph10_event.dlq_entry CASCADE;

-- @changeset ph10-0611-dlq-payload
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
-- @rollback DROP TABLE IF EXISTS ph10_event.dlq_payload CASCADE;

-- @changeset ph10-0620-lag-sample
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
-- @rollback DROP TABLE IF EXISTS ph10_event.lag_sample CASCADE;

-- @changeset ph10-0621-lag-sample-5m
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
COMMENT ON TABLE ph10_event.lag_sample_5m IS 'Gộp 5 phút của lag_sample theo subscription (giá trị lớn nhất qua các phân vùng và trong cửa sổ), cho biểu đồ xu hướng UI-10-17. Giữ 90 ngày. Bảng kỹ thuật ghi ở FRS A.3.';
-- @rollback DROP TABLE IF EXISTS ph10_event.lag_sample_5m CASCADE;

-- @file 10-0070-migration.sql
-- @changeset ph10-0700-manifest-import-job
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
-- @rollback DROP TABLE IF EXISTS ph10_event.manifest_import_job CASCADE;

-- @changeset ph10-0710-legacy-mapping
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
  CONSTRAINT ck_legacy_mapping_target_type CHECK (target_type IS NULL OR target_type IN ('PROJECT', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'PUBLICATION', 'SUBSCRIPTION')),
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
COMMENT ON COLUMN ph10_event.legacy_mapping.target_type IS 'Loại đối tượng Datahub đích (A.2.14 LegacyMapping.targetType); subscriber "là luồng" vẫn là SUBSCRIBER với party_type FLOW.';
-- @rollback DROP TABLE IF EXISTS ph10_event.legacy_mapping CASCADE;

-- @changeset ph10-0720-migration-bridge
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
  CONSTRAINT ck_migration_bridge_status CHECK (status IN ('PENDING_APPROVAL', 'REJECTED', 'RUNNING', 'STOPPED', 'ERROR', 'EXPIRED')),
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
-- @rollback DROP TABLE IF EXISTS ph10_event.migration_bridge CASCADE;

-- @file 10-0080-messaging.sql
-- @changeset ph10-0800-outbox-event
CREATE TABLE ph10_event.outbox_event (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     varchar(255)  NOT NULL,
  partition_key    varchar(255)  NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = ph10_event.f_topic_prefix(tenant_id)),
  -- A.7: đúng 16 topic EVT-10-01…16, cộng kiểm toán gửi PH-13
  CONSTRAINT ck_outbox_event_topic CHECK (
       substr(topic, length(split_part(topic, '.', 1)) + 2) IN (
         'event.topic.activated.v1', 'event.topic.changed.v1', 'event.topic.deprecated.v1', 'event.topic.retired.v1',
         'event.schema.version-enabled.v1', 'event.publication.activated.v1', 'event.publication.state-changed.v1',
         'event.subscription.activated.v1', 'event.subscription.state-changed.v1', 'event.subscription.lag-alerted.v1',
         'event.delivery.dead-lettered.v1', 'event.replay.completed.v1', 'event.signing-key.rotated.v1',
         'event.compliance.violated.v1', 'event.migration.cut-over.v1', 'event.bridge.state-changed.v1', 'audit.recorded.v1')),
  -- ce_type = vn.datahub.event.{thực-thể}.{sự-kiện} khớp topic (A.7)
  CONSTRAINT ck_outbox_event_type CHECK (
       (split_part(topic, '.', 2) = 'event' AND event_type = 'vn.datahub.event.' || split_part(topic, '.', 3) || '.' || split_part(topic, '.', 4))
    OR (split_part(topic, '.', 2) = 'audit' AND event_type = 'vn.datahub.audit.recorded')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  -- BR-10-027, FR-10-065: không bí mật ký, không nội dung sự kiện
  CONSTRAINT ck_outbox_event_no_secret CHECK (NOT (payload ?| ARRAY['secret', 'signingSecret', 'password', 'token', 'apiKey'])
                                              AND payload::text !~ 'whsec_')
);
CREATE INDEX ix_outbox_event_occurred ON ph10_event.outbox_event (occurred_at);
ALTER TABLE ph10_event.outbox_event SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph10_event.p_enable_rls('ph10_event.outbox_event', 'P');
COMMENT ON TABLE ph10_event.outbox_event IS 'Outbox (DD-11, SAD §7.3) cho EVT-10-01…16 và bản ghi kiểm toán gửi PH-13 ({tenant}.audit.recorded.v1). Ghi cùng giao dịch nghiệp vụ; Debezium Outbox Event Router (connector dh-integration-outbox) đọc WAL, định tuyến theo cột topic, khóa theo partition_key. Dọn sau 3 ngày.';
COMMENT ON COLUMN ph10_event.outbox_event.partition_key IS 'Khóa Kafka: topicName, subscriptionCode, publicationCode, replayCode, bridgeCode tùy sự kiện (§6.2).';
-- @rollback DROP TABLE IF EXISTS ph10_event.outbox_event CASCADE;

-- @changeset ph10-0810-inbox-event
CREATE TABLE ph10_event.inbox_event (
  tenant_id        varchar(16)   NOT NULL,
  consumer         varchar(64)   NOT NULL,
  event_id         varchar(255)  NOT NULL,
  source_topic     varchar(249)  NOT NULL,
  event_type       varchar(255)  NOT NULL,
  received_at      timestamptz   NOT NULL DEFAULT now(),
  processed_at     timestamptz,
  outcome          varchar(2000),
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = ph10_event.f_topic_prefix(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph10_event.inbox_event (received_at);
CALL ph10_event.p_enable_rls('ph10_event.inbox_event', 'P');
COMMENT ON TABLE ph10_event.inbox_event IS 'Inbox chống xử lý trùng cho sự kiện PH-10 tiêu thụ (at-least-once): trạng thái HTTT PH-01, luồng PH-04 ngừng, CDC schema-changed PH-05 (FR-10-068), khởi tạo tenant PH-20. Ghi cùng giao dịch với tác dụng; khóa (consumer, event_id = ce id). Dọn sau 7 ngày. DlqWriter không dùng bảng này (lũy đẳng nhờ uq_dlq_entry_source).';
COMMENT ON COLUMN ph10_event.inbox_event.consumer IS 'Tên bộ tiêu thụ, ví dụ SystemStateConsumer, CdcSchemaChangedConsumer, TenantProvisionedConsumer.';
-- @rollback DROP TABLE IF EXISTS ph10_event.inbox_event CASCADE;

-- @changeset ph10-0820-shedlock
CREATE TABLE ph10_event.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph10_event.shedlock IS 'Khóa tác vụ nền (LagCollector, ApprovalExpiryJob, ProvisioningTimeoutJob, SigningKeyRotationJob, DlqPayloadPurgeJob, TopicDeleteJob, BridgeExpiryJob, MigrationReconcileJob, PartitionMaintenanceJob); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph10_event.shedlock;

-- @file 10-0800-seed.sql
-- @changeset ph10-0900-seed-catalog
INSERT INTO ph10_event.comm_type (id, tenant_id, comm_type_code, name, direction, allowed_party_types, delivery_mode, legacy_code, created_by, updated_by)
SELECT md5('dh-comm-type:' || c.code)::uuid, 'COMMON', c.code, c.name, c.dir, c.parties::varchar(32)[], c.dm, c.legacy, 'system:seed', 'system:seed'
FROM (VALUES
  ('HTTP_PUBLISH',   'Phát qua API HTTP',  'PUBLISH',   '{SYSTEM}',                         NULL,         'REST'),
  ('KAFKA_NATIVE',   'Kafka trực tiếp',    'BOTH',      '{SYSTEM}',                         'PULL_KAFKA', 'PULSAR_CLIENT'),
  ('INTERNAL_KAFKA', 'Kafka nội bộ',       'BOTH',      '{FLOW,INTERNAL_SERVICE}',          'INTERNAL',   'ROUTE'),
  ('OUTBOX_CDC',     'Outbox của DU',      'PUBLISH',   '{INTERNAL_SERVICE}',               NULL,         NULL),
  ('DB_CDC',         'CDC CSDL (PH-05)',   'PUBLISH',   '{INTERNAL_SERVICE}',               NULL,         NULL),
  ('WEBHOOK_PUSH',   'Nhận đẩy webhook',   'SUBSCRIBE', '{SYSTEM}',                         'PUSH',       'HTTP_PUSH'),
  ('HTTP_PULL',      'Kéo qua API HTTP',   'SUBSCRIBE', '{SYSTEM}',                         'PULL_API',   NULL),
  ('PULSAR_BRIDGE',  'Cầu nối Pulsar',     'BOTH',      '{LEGACY_BRIDGE,INTERNAL_SERVICE}', 'INTERNAL',   NULL)
) AS c(code, name, dir, parties, dm, legacy)
ON CONFLICT (comm_type_code) DO UPDATE SET name = EXCLUDED.name, direction = EXCLUDED.direction,
  allowed_party_types = EXCLUDED.allowed_party_types, delivery_mode = EXCLUDED.delivery_mode,
  legacy_code = EXCLUDED.legacy_code, updated_by = 'system:seed';
INSERT INTO ph10_event.routing_mode (id, tenant_id, routing_mode_code, name, ordering, legacy_code, created_by, updated_by)
SELECT md5('dh-routing-mode:' || r.code)::uuid, 'COMMON', r.code, r.name, r.ord, r.legacy, 'system:seed', 'system:seed'
FROM (VALUES
  ('KEY_HASH',         'Theo khóa (băm)', 'PER_KEY',         'CustomPartition'),
  ('ROUND_ROBIN',      'Chia đều',        'NONE',            'RoundRobinPartition'),
  ('SINGLE_PARTITION', 'Một phân vùng',   'TOTAL',           'SinglePartition')
) AS r(code, name, ord, legacy)
ON CONFLICT (routing_mode_code) DO UPDATE SET name = EXCLUDED.name, ordering = EXCLUDED.ordering,
  legacy_code = EXCLUDED.legacy_code, updated_by = 'system:seed';
-- @rollback -- Dữ liệu nền idempotent, không rollback.

-- @file 10-0900-grants.sql
-- @changeset ph10-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph10_event TO ph10_app;
REVOKE INSERT, UPDATE, DELETE ON ph10_event.comm_type, ph10_event.routing_mode FROM ph10_app;
GRANT UPDATE (enabled, updated_at, updated_by, version) ON ph10_event.comm_type, ph10_event.routing_mode TO ph10_app;  -- PA bật tắt toàn quốc
REVOKE UPDATE ON ph10_event.outbox_event, ph10_event.delivery_failure, ph10_event.dlq_payload FROM ph10_app;            -- chỉ thêm, xóa khi dọn
REVOKE DELETE ON ph10_event.event_project, ph10_event.topic, ph10_event.event_schema, ph10_event.schema_version,
  ph10_event.publisher, ph10_event.subscriber, ph10_event.publication, ph10_event.subscription,
  ph10_event.signing_key, ph10_event.approval_request, ph10_event.replay_request, ph10_event.legacy_mapping,
  ph10_event.migration_bridge FROM ph10_app;                                                                            -- BR-10-003: không xóa cứng
GRANT SELECT ON ALL TABLES IN SCHEMA ph10_event TO ph10_readonly;
REVOKE SELECT ON ph10_event.dlq_payload FROM ph10_readonly;                                                             -- không đọc nội dung sự kiện
REVOKE SELECT ON ph10_event.delivery_failure FROM ph10_readonly;
GRANT SELECT (id, tenant_id, subscription_code, occurred_at, partition, record_offset, event_id, http_status, error_code, failure_class, attempt)
  ON ph10_event.delivery_failure TO ph10_readonly;                                                                      -- không đọc thân phản hồi
GRANT EXECUTE ON PROCEDURE ph10_event.p_ensure_partitions(regclass, date, integer, text) TO ph10_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
