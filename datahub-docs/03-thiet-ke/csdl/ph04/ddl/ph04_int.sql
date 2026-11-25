-- =============================================================================
-- D03-03-PH04 · DDL schema ph04 — PH-04 Lõi tích hợp và trình thiết kế luồng
-- Phiên bản 0.1 · 2026-11-25 · Dự thảo · Nhóm phân hệ PH-04
--
-- Mục đích: tạo đầy đủ schema ph04 trên pg-core (PostgreSQL 18, tương thích 16).
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph04_int.sql
-- Môi trường thật: vai trò đăng nhập do CloudNativePG tạo; phần còn lại chạy qua
-- Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback như PH-07
-- (công cụ ../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Thay thế bảng hiện có ph04.route, route_version, route_test_run,
-- route_test_run_stage (changelog 003-w2-routes, 006-d-route-test-run của
-- apps/control). Di trú dữ liệu ở changeset ph04-9000 (cuối tệp).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 04-0000-bootstrap.sql
-- @changeset ph04-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph04_owner') THEN
    CREATE ROLE ph04_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph04_app') THEN
    CREATE ROLE ph04_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph04_readonly') THEN
    CREATE ROLE ph04_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph04-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph04 AUTHORIZATION ph04_owner;
COMMENT ON SCHEMA ph04 IS 'PH-04 Lõi tích hợp: không gian làm việc, luồng, phiên bản, chạy thử, duyệt, triển khai, lệnh runtime, chính sách thành phần. Chủ ph04_owner; dh-integration kết nối bằng dh_integration_app (thành viên ph04_app, không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph04 TO ph04_app, ph04_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph04 CASCADE;

SET ROLE ph04_owner;

-- @changeset ph04-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 04-0001-functions.sql
-- @changeset ph04-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph04.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph04.tg_touch() IS 'Cập nhật updated_at và tăng version (khóa lạc quan, ETag) khi ứng dụng không tự tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph04.tg_touch();

-- @changeset ph04-0011-fn-rls splitStatements:false
-- Gắn chính sách RLS theo hai mẫu của D03-10:
--   'P' riêng: đọc, ghi khi tenant_id = app.tenant_id (tỉnh T{nn}).
--   'S' dùng chung: đọc thêm dòng COMMON; ghi dòng COMMON chỉ khi app.tenant_id = 'PLATFORM'.
-- Gọi một lần cho mỗi bảng; chính sách sinh ra có tên rls_{bảng}_{thao tác}.
CREATE OR REPLACE PROCEDURE ph04.p_enable_rls(p_table regclass, p_mode char)
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
COMMENT ON PROCEDURE ph04.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và tạo 4 chính sách theo mẫu P hoặc S (D03-10, D03-03-PH04 §1.2).';
-- @rollback DROP PROCEDURE IF EXISTS ph04.p_enable_rls(regclass, char);

-- @file 04-0010-workspace.sql
-- @changeset ph04-0100-workspace
CREATE TABLE ph04.workspace (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(4000),
  owner_org_code   varchar(64),
  status           varchar(16)   NOT NULL DEFAULT 'ACTIVE',
  legacy_project_id bigint,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_workspace PRIMARY KEY (id),
  CONSTRAINT uq_workspace_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_workspace_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_workspace_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_workspace_code CHECK (code ~ '^([a-z][a-z0-9-]{1,62}|DEFAULT)$'),
  CONSTRAINT ck_workspace_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);
CREATE TRIGGER tg_workspace_touch BEFORE UPDATE ON ph04.workspace FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.workspace', 'P');
COMMENT ON TABLE ph04.workspace IS 'EN-04-01 Không gian làm việc (FR-04-007); thay Project của Bus cũ. Mỗi tenant có sẵn DEFAULT.';
COMMENT ON COLUMN ph04.workspace.legacy_project_id IS 'Project.id của Bus cũ khi di trú; dùng đối soát, không dùng cho nghiệp vụ.';
-- @rollback DROP TABLE IF EXISTS ph04.workspace CASCADE;

-- @changeset ph04-0110-workspace-member
CREATE TABLE ph04.workspace_member (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  workspace_id     uuid          NOT NULL,
  principal_type   varchar(8)    NOT NULL,
  principal_id     varchar(128)  NOT NULL,
  access_level     varchar(10)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_workspace_member PRIMARY KEY (id),
  CONSTRAINT uq_workspace_member UNIQUE (tenant_id, workspace_id, principal_type, principal_id),
  CONSTRAINT fk_workspace_member_ws FOREIGN KEY (workspace_id, tenant_id) REFERENCES ph04.workspace (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_workspace_member_type CHECK (principal_type IN ('USER', 'GROUP')),
  CONSTRAINT ck_workspace_member_level CHECK (access_level IN ('VIEW', 'EDIT', 'MAINTAIN'))
);
CREATE INDEX ix_workspace_member_principal ON ph04.workspace_member (tenant_id, principal_type, principal_id);
CREATE TRIGGER tg_workspace_member_touch BEFORE UPDATE ON ph04.workspace_member FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.workspace_member', 'P');
COMMENT ON TABLE ph04.workspace_member IS 'EN-04-12 Thành viên không gian: người dùng hoặc nhóm PH-12 với mức VIEW, EDIT, MAINTAIN; thay Project_group.access_level.';
-- @rollback DROP TABLE IF EXISTS ph04.workspace_member CASCADE;

-- @file 04-0020-flow.sql
-- @changeset ph04-0200-flow
CREATE TABLE ph04.flow (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  workspace_id     uuid          NOT NULL,
  code             varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(4000),
  resource_kind    varchar(8)    NOT NULL,
  transport        varchar(10)   NOT NULL DEFAULT 'SYNC',
  exposure         varchar(10)   NOT NULL DEFAULT 'INTERNAL',
  status           varchar(12)   NOT NULL DEFAULT 'DRAFT',
  source_system    varchar(64),
  target_systems   varchar(64)[] NOT NULL DEFAULT '{}',
  labels           jsonb         NOT NULL DEFAULT '{}',
  legal_basis_ref  varchar(128),
  origin           varchar(12)   NOT NULL,
  cloned_from_id   uuid,
  template_code    varchar(64),
  emergency_paused boolean       NOT NULL DEFAULT false,
  retired_at       timestamptz,
  retired_by       varchar(64),
  retire_reason    varchar(1000),
  code_released_at timestamptz,
  legacy_context_id bigint,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_flow PRIMARY KEY (id),
  CONSTRAINT uq_flow_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_flow_workspace FOREIGN KEY (workspace_id, tenant_id) REFERENCES ph04.workspace (id, tenant_id),
  CONSTRAINT ck_flow_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_flow_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_flow_kind CHECK (resource_kind IN ('ROUTE', 'KAMELET', 'PIPE', 'TEST')),
  CONSTRAINT ck_flow_transport CHECK (transport IN ('SYNC', 'ASYNC', 'SCHEDULED', 'MIXED')),
  CONSTRAINT ck_flow_exposure CHECK (exposure IN ('EXTERNAL', 'INTERNAL')),
  CONSTRAINT ck_flow_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'APPROVED', 'ACTIVE', 'PAUSED', 'DEGRADED', 'RETIRED')),
  CONSTRAINT ck_flow_origin CHECK (origin IN ('BLANK', 'TEMPLATE', 'OPENAPI', 'YAML_FILE', 'CLONE', 'LEGACY_XML')),
  CONSTRAINT ck_flow_labels CHECK (jsonb_typeof(labels) = 'object'),
  CONSTRAINT ck_flow_targets CHECK (cardinality(target_systems) <= 20),
  CONSTRAINT ck_flow_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
-- BR-04-001: mã duy nhất trong tenant; mã của luồng đã gỡ được giải phóng sau 30 ngày
-- (tác vụ nền đặt code_released_at), nên chỉ mục duy nhất loại các dòng đó.
CREATE UNIQUE INDEX uq_flow_code_live ON ph04.flow (tenant_id, code) WHERE code_released_at IS NULL;
CREATE INDEX ix_flow_workspace ON ph04.flow (tenant_id, workspace_id, status);
CREATE INDEX ix_flow_updated ON ph04.flow (tenant_id, updated_at DESC, id);
CREATE INDEX ix_flow_search ON ph04.flow USING gin ((lower(code || ' ' || name || ' ' || coalesce(description, ''))) public.gin_trgm_ops);
CREATE INDEX ix_flow_labels ON ph04.flow USING gin (labels jsonb_path_ops);
CREATE TRIGGER tg_flow_touch BEFORE UPDATE ON ph04.flow FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.flow', 'P');
COMMENT ON TABLE ph04.flow IS 'EN-04-02 Luồng tích hợp (FR-04-001…006); thay Context của Bus cũ.';
COMMENT ON COLUMN ph04.flow.status IS 'Trạng thái tổng hợp, tính lại sau sự kiện phiên bản, triển khai, lệnh (D03-02-PH04 §9.2).';
COMMENT ON COLUMN ph04.flow.transport IS 'Suy ra từ chặng đầu; người dùng không sửa.';
COMMENT ON COLUMN ph04.flow.legacy_context_id IS 'Context.id của Bus cũ khi di trú.';
-- @rollback DROP TABLE IF EXISTS ph04.flow CASCADE;

-- @changeset ph04-0210-flow-version
CREATE TABLE ph04.flow_version (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  flow_id             uuid          NOT NULL,
  version_no          integer       NOT NULL,
  status              varchar(18)   NOT NULL DEFAULT 'DRAFT',
  definition_yaml     text          NOT NULL,
  canonical_yaml      text,
  content_hash        char(71)      NOT NULL,
  canvas_layout       jsonb         NOT NULL DEFAULT '{}',
  samples             jsonb         NOT NULL DEFAULT '{}',
  catalog_version     varchar(64)   NOT NULL,
  last_validation     jsonb,
  needs_revalidation  boolean       NOT NULL DEFAULT false,
  components          text[]        NOT NULL DEFAULT '{}',
  runtime_profile     varchar(32),
  change_note         varchar(2000),
  based_on_version_no integer,
  submitted_hash      char(71),
  submitted_at        timestamptz,
  submitted_by        varchar(64),
  approved_at         timestamptz,
  approved_by         varchar(64),
  discarded_at        timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_flow_version PRIMARY KEY (id),
  CONSTRAINT uq_flow_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_flow_version_no UNIQUE (tenant_id, flow_id, version_no),
  CONSTRAINT fk_flow_version_flow FOREIGN KEY (flow_id, tenant_id) REFERENCES ph04.flow (id, tenant_id),
  CONSTRAINT ck_flow_version_status CHECK (status IN ('DRAFT', 'CHANGES_REQUESTED', 'PENDING_REVIEW', 'APPROVED', 'SUPERSEDED', 'ROLLED_BACK', 'DISCARDED')),
  CONSTRAINT ck_flow_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_flow_version_size CHECK (octet_length(definition_yaml) <= 524288),
  CONSTRAINT ck_flow_version_samples_size CHECK (pg_column_size(samples) <= 4194304),
  CONSTRAINT ck_flow_version_hash CHECK (content_hash ~ '^sha256:[0-9a-f]{64}$'),
  CONSTRAINT ck_flow_version_submitted CHECK (status NOT IN ('PENDING_REVIEW', 'APPROVED', 'SUPERSEDED', 'ROLLED_BACK') OR (submitted_hash IS NOT NULL AND submitted_by IS NOT NULL)),
  CONSTRAINT ck_flow_version_approved CHECK (status NOT IN ('APPROVED', 'SUPERSEDED', 'ROLLED_BACK') OR (approved_by IS NOT NULL AND content_hash = submitted_hash))
);
-- BR-04-016: tối đa một phiên bản mở mỗi luồng.
CREATE UNIQUE INDEX uq_flow_version_open ON ph04.flow_version (tenant_id, flow_id) WHERE status IN ('DRAFT', 'CHANGES_REQUESTED');
CREATE INDEX ix_flow_version_review ON ph04.flow_version (tenant_id, submitted_at) WHERE status = 'PENDING_REVIEW';
CREATE INDEX ix_flow_version_components ON ph04.flow_version USING gin (components);
CREATE INDEX ix_flow_version_revalidate ON ph04.flow_version (tenant_id) WHERE needs_revalidation;
CREATE TRIGGER tg_flow_version_touch BEFORE UPDATE ON ph04.flow_version FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.flow_version', 'P');
COMMENT ON TABLE ph04.flow_version IS 'EN-04-03 Phiên bản luồng (FR-04-010, 011, 024; ADR-069). Nội dung bất biến từ PENDING_REVIEW (trigger tg_flow_version_immutable).';
COMMENT ON COLUMN ph04.flow_version.canvas_layout IS 'Bố cục sơ đồ, ghi chú dán, nhóm; không vào YAML triển khai (BR-04-007).';
COMMENT ON COLUMN ph04.flow_version.samples IS 'Bản tin mẫu theo id chặng, mỗi bản ≤ 256 KiB; không vào YAML (BR-04-007).';
COMMENT ON COLUMN ph04.flow_version.content_hash IS 'sha256 của YAML chuẩn hóa và *.jq (D03-02-PH04 §6.2); điều kiện chạy thử đạt gắn với băm này (BR-04-004).';
COMMENT ON COLUMN ph04.flow_version.components IS 'Tên thành phần Camel dùng trong định nghĩa; phục vụ chọn hồ sơ runtime, VR-04, đánh dấu khi chính sách đổi.';
-- @rollback DROP TABLE IF EXISTS ph04.flow_version CASCADE;

-- @changeset ph04-0211-flow-version-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph04.tg_flow_version_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status NOT IN ('DRAFT', 'CHANGES_REQUESTED')
     AND (NEW.definition_yaml IS DISTINCT FROM OLD.definition_yaml
          OR NEW.content_hash IS DISTINCT FROM OLD.content_hash
          OR NEW.samples IS DISTINCT FROM OLD.samples) THEN
    RAISE EXCEPTION 'flow_version % ở trạng thái % là bất biến (BR-04-016)', OLD.id, OLD.status
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_flow_version_immutable BEFORE UPDATE ON ph04.flow_version
  FOR EACH ROW EXECUTE FUNCTION ph04.tg_flow_version_immutable();
-- @rollback DROP TRIGGER IF EXISTS tg_flow_version_immutable ON ph04.flow_version; DROP FUNCTION IF EXISTS ph04.tg_flow_version_immutable();

-- @changeset ph04-0220-contributor
CREATE TABLE ph04.flow_version_contributor (
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  user_id          varchar(64)   NOT NULL,
  first_at         timestamptz   NOT NULL DEFAULT now(),
  last_at          timestamptz   NOT NULL DEFAULT now(),
  save_count       integer       NOT NULL DEFAULT 1,
  CONSTRAINT pk_flow_version_contributor PRIMARY KEY (tenant_id, flow_version_id, user_id),
  CONSTRAINT fk_contributor_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE
);
CALL ph04.p_enable_rls('ph04.flow_version_contributor', 'P');
COMMENT ON TABLE ph04.flow_version_contributor IS 'EN-04-13 Người đóng góp phiên bản; dùng cho bốn mắt (BR-04-005, GAP-04-06). Ngoại lệ D00-01: khóa tự nhiên, không có id.';
-- @rollback DROP TABLE IF EXISTS ph04.flow_version_contributor CASCADE;

-- @changeset ph04-0230-mapping
CREATE TABLE ph04.flow_mapping (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  name             varchar(128)  NOT NULL,
  node_id          varchar(128),
  dhmap            jsonb         NOT NULL,
  jq               text          NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_flow_mapping PRIMARY KEY (id),
  CONSTRAINT uq_flow_mapping_name UNIQUE (tenant_id, flow_version_id, name),
  CONSTRAINT fk_flow_mapping_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_flow_mapping_name CHECK (name ~ '^[a-z0-9][a-z0-9-]{0,127}$'),
  CONSTRAINT ck_flow_mapping_format CHECK (dhmap ->> 'format' = 'dhmap/1')
);
CREATE TRIGGER tg_flow_mapping_touch BEFORE UPDATE ON ph04.flow_mapping FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.flow_mapping', 'P');
COMMENT ON TABLE ph04.flow_mapping IS 'EN-04-14 Ánh xạ dữ liệu *.dhmap.json và JQ sinh ra (FR-04-020, ADR-066). Chỉ jq vào kho cấu hình.';
-- @rollback DROP TABLE IF EXISTS ph04.flow_mapping CASCADE;

-- @file 04-0030-index.sql
-- @changeset ph04-0300-route-index
CREATE TABLE ph04.flow_route_index (
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  route_id         varchar(128)  NOT NULL,
  from_uri         varchar(2048) NOT NULL,
  from_scheme      varchar(64)   NOT NULL,
  description      varchar(1000),
  step_count       integer       NOT NULL,
  CONSTRAINT pk_flow_route_index PRIMARY KEY (tenant_id, flow_version_id, route_id),
  CONSTRAINT fk_route_index_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_route_index_route ON ph04.flow_route_index (tenant_id, route_id);
CALL ph04.p_enable_rls('ph04.flow_route_index', 'P');
COMMENT ON TABLE ph04.flow_route_index IS 'EN-04-04a Chỉ mục route tính khi lưu (FR-04-001, 002; VR-08). URI đã che tham số nhạy cảm.';
-- @rollback DROP TABLE IF EXISTS ph04.flow_route_index CASCADE;

-- @changeset ph04-0310-endpoint-index
CREATE TABLE ph04.flow_endpoint_index (
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  node_id          varchar(128)  NOT NULL,
  direction        varchar(4)    NOT NULL,
  scheme           varchar(64)   NOT NULL,
  uri_masked       varchar(2048) NOT NULL,
  http_method      varchar(8),
  http_path        varchar(1024),
  connection_code  varchar(64),
  topic            varchar(249),
  CONSTRAINT pk_flow_endpoint_index PRIMARY KEY (tenant_id, flow_version_id, node_id),
  CONSTRAINT fk_endpoint_index_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_endpoint_direction CHECK (direction IN ('IN', 'OUT'))
);
CREATE INDEX ix_endpoint_index_uri ON ph04.flow_endpoint_index USING gin (lower(uri_masked) public.gin_trgm_ops);
CREATE INDEX ix_endpoint_index_path ON ph04.flow_endpoint_index (tenant_id, http_method, http_path) WHERE http_path IS NOT NULL;
CREATE INDEX ix_endpoint_index_conn ON ph04.flow_endpoint_index (tenant_id, connection_code) WHERE connection_code IS NOT NULL;
CREATE INDEX ix_endpoint_index_topic ON ph04.flow_endpoint_index (tenant_id, topic) WHERE topic IS NOT NULL;
CALL ph04.p_enable_rls('ph04.flow_endpoint_index', 'P');
COMMENT ON TABLE ph04.flow_endpoint_index IS 'EN-04-04b Chỉ mục điểm kết nối (FR-04-001 lọc endpoint, FR-04-052; VR-18; FlowQueryApi.flowsUsingConnection, flowsUsingTopic).';
-- @rollback DROP TABLE IF EXISTS ph04.flow_endpoint_index CASCADE;

-- @changeset ph04-0320-reference
CREATE TABLE ph04.flow_reference (
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  ref_type         varchar(12)   NOT NULL,
  ref_key          varchar(255)  NOT NULL,
  hard             boolean       NOT NULL,
  CONSTRAINT pk_flow_reference PRIMARY KEY (tenant_id, flow_version_id, ref_type, ref_key),
  CONSTRAINT fk_flow_reference_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_flow_reference_type CHECK (ref_type IN ('DIRECT', 'KAMELET', 'CONNECTION', 'TOPIC', 'SCHEMA', 'CODE_MAP', 'API', 'BEAN_CLASS'))
);
CREATE INDEX ix_flow_reference_key ON ph04.flow_reference (tenant_id, ref_type, ref_key);
CALL ph04.p_enable_rls('ph04.flow_reference', 'P');
COMMENT ON TABLE ph04.flow_reference IS 'EN-04-04c Tham chiếu ra ngoài của phiên bản; tính phụ thuộc (API-04-016), chặn gỡ khi còn phụ thuộc cứng (FR-04-006).';
-- @rollback DROP TABLE IF EXISTS ph04.flow_reference CASCADE;

-- @file 04-0040-review.sql
-- @changeset ph04-0400-review
CREATE TABLE ph04.review (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  action           varchar(16)   NOT NULL,
  actor            varchar(64)   NOT NULL,
  content_hash     char(71)      NOT NULL,
  comment          varchar(4000),
  checklist        jsonb,
  node_comments    jsonb         NOT NULL DEFAULT '[]',
  diff_viewed_at   timestamptz,
  reauth_at        timestamptz,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_review PRIMARY KEY (id),
  CONSTRAINT fk_review_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id),
  CONSTRAINT ck_review_action CHECK (action IN ('SUBMIT', 'WITHDRAW', 'APPROVE', 'REQUEST_CHANGES', 'DIFF_VIEWED')),
  CONSTRAINT ck_review_comment CHECK (action NOT IN ('REQUEST_CHANGES', 'WITHDRAW') OR length(comment) >= 10)
);
CREATE INDEX ix_review_version ON ph04.review (tenant_id, flow_version_id, occurred_at);
CALL ph04.p_enable_rls('ph04.review', 'P');
COMMENT ON TABLE ph04.review IS 'EN-04-05 Nhật ký gửi, rút, duyệt, yêu cầu sửa của phiên bản (FR-04-040, 041, 043). Chỉ thêm, không sửa; ngoại lệ D00-01: không có updated_*.';
-- @rollback DROP TABLE IF EXISTS ph04.review CASCADE;

-- @file 04-0050-deployment.sql
-- @changeset ph04-0500-deployment
CREATE TABLE ph04.deployment (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_id          uuid          NOT NULL,
  flow_version_id  uuid          NOT NULL,
  environment      varchar(8)    NOT NULL,
  kind             varchar(10)   NOT NULL,
  desired_state    varchar(8)    NOT NULL DEFAULT 'RUNNING',
  paused_routes    varchar(128)[] NOT NULL DEFAULT '{}',
  sync_status      varchar(12)   NOT NULL DEFAULT 'PENDING',
  health_status    varchar(8)    NOT NULL DEFAULT 'UNKNOWN',
  runtime_profile  varchar(32)   NOT NULL,
  replicas         smallint      NOT NULL DEFAULT 3,
  git_branch       varchar(64),
  git_commit       char(40),
  git_mr_ref       varchar(255),
  note             varchar(1000),
  reason           varchar(1000),
  error_code       varchar(16),
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  synced_at        timestamptz,
  current          boolean       NOT NULL DEFAULT false,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_deployment PRIMARY KEY (id),
  CONSTRAINT uq_deployment_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_deployment_flow FOREIGN KEY (flow_id, tenant_id) REFERENCES ph04.flow (id, tenant_id),
  CONSTRAINT fk_deployment_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id),
  CONSTRAINT ck_deployment_env CHECK (environment IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_deployment_kind CHECK (kind IN ('RELEASE', 'PROMOTE', 'ROLLBACK', 'RETIRE')),
  CONSTRAINT ck_deployment_desired CHECK (desired_state IN ('RUNNING', 'PAUSED', 'REMOVED')),
  CONSTRAINT ck_deployment_sync CHECK (sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'OUT_OF_SYNC', 'FAILED')),
  CONSTRAINT ck_deployment_health CHECK (health_status IN ('HEALTHY', 'DEGRADED', 'DOWN', 'UNKNOWN')),
  CONSTRAINT ck_deployment_replicas CHECK (replicas BETWEEN 1 AND 20),
  CONSTRAINT ck_deployment_reason CHECK (kind <> 'ROLLBACK' OR length(reason) >= 10)
);
-- Mỗi luồng mỗi môi trường có đúng một triển khai hiện hành.
CREATE UNIQUE INDEX uq_deployment_current ON ph04.deployment (tenant_id, flow_id, environment) WHERE current;
CREATE INDEX ix_deployment_flow ON ph04.deployment (tenant_id, flow_id, requested_at DESC);
CREATE INDEX ix_deployment_pending ON ph04.deployment (tenant_id, sync_status) WHERE sync_status IN ('PENDING', 'SYNCING', 'OUT_OF_SYNC');
CREATE TRIGGER tg_deployment_touch BEFORE UPDATE ON ph04.deployment FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.deployment', 'P');
COMMENT ON TABLE ph04.deployment IS 'EN-04-06 Triển khai phiên bản lên môi trường (FR-04-042, 044, 045); trạng thái mong muốn của lệnh điều khiển (FR-04-050).';
COMMENT ON COLUMN ph04.deployment.current IS 'true với triển khai đang là mong muốn của môi trường; triển khai mới SYNCED thì bản cũ chuyển false.';
-- @rollback DROP TABLE IF EXISTS ph04.deployment CASCADE;

-- @file 04-0060-test.sql
-- @changeset ph04-0600-test-case
CREATE TABLE ph04.test_case (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_id          uuid          NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(2000),
  mode             varchar(12)   NOT NULL DEFAULT 'MOCK',
  input_body       text,
  input_headers    jsonb         NOT NULL DEFAULT '{}',
  from_node_id     varchar(128),
  mocks            jsonb         NOT NULL DEFAULT '{}',
  assertions       jsonb         NOT NULL,
  timeout_seconds  smallint      NOT NULL DEFAULT 30,
  active           boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_test_case PRIMARY KEY (id),
  CONSTRAINT uq_test_case_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_test_case_name UNIQUE (tenant_id, flow_id, name),
  CONSTRAINT fk_test_case_flow FOREIGN KEY (flow_id, tenant_id) REFERENCES ph04.flow (id, tenant_id),
  CONSTRAINT ck_test_case_mode CHECK (mode IN ('MOCK', 'SANDBOX_LIVE')),
  CONSTRAINT ck_test_case_body CHECK (input_body IS NULL OR octet_length(input_body) <= 262144),
  CONSTRAINT ck_test_case_assert CHECK (jsonb_typeof(assertions) = 'array' AND jsonb_array_length(assertions) BETWEEN 1 AND 20),
  CONSTRAINT ck_test_case_timeout CHECK (timeout_seconds BETWEEN 1 AND 120)
);
CREATE TRIGGER tg_test_case_touch BEFORE UPDATE ON ph04.test_case FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.test_case', 'P');
COMMENT ON TABLE ph04.test_case IS 'EN-04-15 Ca kiểm thử của luồng (FR-04-031); đi cùng luồng qua các phiên bản, ghi vào kho cấu hình tests/cases.dh.yaml. VR-20: ≥ 1 khẳng định.';
-- @rollback DROP TABLE IF EXISTS ph04.test_case CASCADE;

-- @changeset ph04-0610-test-run
CREATE TABLE ph04.test_run (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_version_id  uuid          NOT NULL,
  test_case_id     uuid,
  definition_hash  char(71)      NOT NULL,
  mode             varchar(12)   NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'QUEUED',
  runtime_profile  varchar(32),
  from_node_id     varchar(128),
  capture_bodies   boolean       NOT NULL DEFAULT false,
  timeout_seconds  smallint      NOT NULL,
  request_meta     jsonb         NOT NULL DEFAULT '{}',
  assertion_results jsonb,
  error_code       varchar(16),
  error_summary    varchar(1000),
  hung_node_id     varchar(128),
  duration_ms      integer,
  trace_id         char(32),
  sandbox_replica  varchar(128),
  idempotency_key  varchar(128),
  run_by           varchar(64)   NOT NULL,
  queued_at        timestamptz   NOT NULL DEFAULT now(),
  started_at       timestamptz,
  finished_at      timestamptz,
  bodies_expire_at timestamptz,
  CONSTRAINT pk_test_run PRIMARY KEY (id),
  CONSTRAINT uq_test_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_test_run_version FOREIGN KEY (flow_version_id, tenant_id) REFERENCES ph04.flow_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_test_run_case FOREIGN KEY (test_case_id, tenant_id) REFERENCES ph04.test_case (id, tenant_id) ON DELETE SET NULL (test_case_id),
  CONSTRAINT ck_test_run_mode CHECK (mode IN ('MOCK', 'SANDBOX_LIVE', 'SIMULATED')),
  CONSTRAINT ck_test_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'PASSED', 'FAILED', 'TIMED_OUT', 'CANCELLED', 'SIMULATED')),
  CONSTRAINT ck_test_run_sim CHECK ((mode = 'SIMULATED') = (status = 'SIMULATED')),
  CONSTRAINT ck_test_run_timeout CHECK (timeout_seconds BETWEEN 1 AND 120)
);
CREATE INDEX ix_test_run_version ON ph04.test_run (tenant_id, flow_version_id, queued_at DESC);
CREATE INDEX ix_test_run_passed ON ph04.test_run (tenant_id, flow_version_id, definition_hash, test_case_id) WHERE status = 'PASSED';
CREATE INDEX ix_test_run_active ON ph04.test_run (tenant_id) WHERE status IN ('QUEUED', 'RUNNING');
CREATE INDEX ix_test_run_retention ON ph04.test_run (queued_at);
CALL ph04.p_enable_rls('ph04.test_run', 'P');
COMMENT ON TABLE ph04.test_run IS 'EN-04-07 Lần chạy thử (FR-04-030, 032). Giữ 04.test.retention-days (90); thân bản tin ở Ceph RGW dh-int-testrun, xóa sau 04.test.body-retention-days (7).';
COMMENT ON COLUMN ph04.test_run.request_meta IS 'Tiêu đề (đã che), kích thước thân, khẳng định của lần chạy; không chứa thân.';
-- @rollback DROP TABLE IF EXISTS ph04.test_run CASCADE;

-- @changeset ph04-0620-test-run-step
CREATE TABLE ph04.test_run_step (
  tenant_id        varchar(16)   NOT NULL,
  test_run_id      uuid          NOT NULL,
  seq_no           integer       NOT NULL,
  node_id          varchar(128)  NOT NULL,
  route_id         varchar(128),
  stage            varchar(16),
  status           varchar(10)   NOT NULL,
  offset_ms        integer       NOT NULL,
  duration_ms      integer       NOT NULL,
  headers_masked   jsonb,
  body_in_preview  text,
  body_out_preview text,
  body_object_key  varchar(512),
  error_class      varchar(16),
  error_text       varchar(1000),
  CONSTRAINT pk_test_run_step PRIMARY KEY (tenant_id, test_run_id, seq_no),
  CONSTRAINT fk_test_run_step_run FOREIGN KEY (test_run_id, tenant_id) REFERENCES ph04.test_run (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_test_run_step_status CHECK (status IN ('OK', 'FAILED', 'SKIPPED', 'HUNG')),
  CONSTRAINT ck_test_run_step_stage CHECK (stage IS NULL OR stage IN ('receive', 'schema', 'authz', 'transform', 'enrich', 'route', 'deliver', 'audit', 'respond')),
  CONSTRAINT ck_test_run_step_preview CHECK (coalesce(octet_length(body_in_preview), 0) <= 65536 AND coalesce(octet_length(body_out_preview), 0) <= 65536)
);
CALL ph04.p_enable_rls('ph04.test_run_step', 'P');
COMMENT ON TABLE ph04.test_run_step IS 'EN-04-08 Vết từng chặng của lần chạy thử, kể cả SKIPPED (FR-04-030). Xem trước thân đã che, ≤ 64 KiB (BR-04-013).';
-- @rollback DROP TABLE IF EXISTS ph04.test_run_step CASCADE;

-- @file 04-0070-runtime.sql
-- @changeset ph04-0700-runtime-command
CREATE TABLE ph04.runtime_command (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  flow_id          uuid          NOT NULL,
  deployment_id    uuid          NOT NULL,
  environment      varchar(8)    NOT NULL,
  action           varchar(16)   NOT NULL,
  scope            varchar(8)    NOT NULL,
  route_ids        varchar(128)[] NOT NULL DEFAULT '{}',
  drain            boolean       NOT NULL DEFAULT true,
  reason           varchar(1000) NOT NULL,
  incident_ref     varchar(128),
  status           varchar(12)   NOT NULL DEFAULT 'ISSUED',
  expected_replicas smallint     NOT NULL,
  acked_replicas   smallint      NOT NULL DEFAULT 0,
  key_id           varchar(64)   NOT NULL,
  signature        varchar(128)  NOT NULL,
  issued_by        varchar(64)   NOT NULL,
  issued_at        timestamptz   NOT NULL DEFAULT now(),
  expires_at       timestamptz   NOT NULL,
  acknowledged_at  timestamptz,
  git_commit       char(40),
  reconciled_at    timestamptz,
  CONSTRAINT pk_runtime_command PRIMARY KEY (id),
  CONSTRAINT uq_runtime_command_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_runtime_command_flow FOREIGN KEY (flow_id, tenant_id) REFERENCES ph04.flow (id, tenant_id),
  CONSTRAINT fk_runtime_command_dep FOREIGN KEY (deployment_id, tenant_id) REFERENCES ph04.deployment (id, tenant_id),
  CONSTRAINT ck_runtime_command_action CHECK (action IN ('PAUSE', 'RESUME', 'EMERGENCY_STOP')),
  CONSTRAINT ck_runtime_command_scope CHECK (scope IN ('FLOW', 'ROUTES')),
  CONSTRAINT ck_runtime_command_routes CHECK ((scope = 'ROUTES') = (cardinality(route_ids) > 0)),
  CONSTRAINT ck_runtime_command_status CHECK (status IN ('ISSUED', 'DELIVERED', 'ACKNOWLEDGED', 'PARTIAL', 'REJECTED', 'RECONCILED')),
  CONSTRAINT ck_runtime_command_reason CHECK (length(reason) BETWEEN 10 AND 1000),
  CONSTRAINT ck_runtime_command_expiry CHECK (expires_at > issued_at AND expires_at <= issued_at + interval '5 minutes')
);
CREATE INDEX ix_runtime_command_flow ON ph04.runtime_command (tenant_id, flow_id, issued_at DESC);
CREATE INDEX ix_runtime_command_open ON ph04.runtime_command (tenant_id, status) WHERE status IN ('ISSUED', 'DELIVERED', 'PARTIAL', 'ACKNOWLEDGED');
CALL ph04.p_enable_rls('ph04.runtime_command', 'P');
COMMENT ON TABLE ph04.runtime_command IS 'EN-04-10 Lệnh điều khiển runtime có ký Ed25519 (FR-04-050, ADR-065). Lý do chỉ lưu ở đây và kiểm toán, không đi lên topic.';
-- @rollback DROP TABLE IF EXISTS ph04.runtime_command CASCADE;

-- @changeset ph04-0710-command-ack
CREATE TABLE ph04.command_ack (
  tenant_id        varchar(16)   NOT NULL,
  command_id       uuid          NOT NULL,
  replica          varchar(128)  NOT NULL,
  result           varchar(10)   NOT NULL,
  reason           varchar(32),
  acked_at         timestamptz   NOT NULL,
  CONSTRAINT pk_command_ack PRIMARY KEY (tenant_id, command_id, replica),
  CONSTRAINT fk_command_ack_cmd FOREIGN KEY (command_id, tenant_id) REFERENCES ph04.runtime_command (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_command_ack_result CHECK (result IN ('APPLIED', 'REJECTED')),
  CONSTRAINT ck_command_ack_reason CHECK (reason IS NULL OR reason IN ('EXPIRED', 'BAD_SIGNATURE', 'TENANT_MISMATCH', 'UNKNOWN_FLOW', 'DUPLICATE'))
);
CALL ph04.p_enable_rls('ph04.command_ack', 'P');
COMMENT ON TABLE ph04.command_ack IS 'EN-04-16 Xác nhận lệnh từ từng bản sao runtime (EVT-04-13).';
-- @rollback DROP TABLE IF EXISTS ph04.command_ack CASCADE;

-- @changeset ph04-0720-heartbeat
CREATE TABLE ph04.heartbeat_latest (
  tenant_id        varchar(16)   NOT NULL,
  flow_code        varchar(63)   NOT NULL,
  environment      varchar(8)    NOT NULL,
  replica          varchar(128)  NOT NULL,
  profile          varchar(32)   NOT NULL,
  namespace        varchar(63)   NOT NULL,
  version_no       integer       NOT NULL,
  content_hash     char(71)      NOT NULL,
  flow_state       varchar(12)   NOT NULL,
  load_error       varchar(1000),
  routes           jsonb         NOT NULL,
  image_digest     char(71),
  lib_version      varchar(32),
  seen_at          timestamptz   NOT NULL,
  CONSTRAINT pk_heartbeat_latest PRIMARY KEY (tenant_id, flow_code, environment, replica),
  CONSTRAINT ck_heartbeat_env CHECK (environment IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_heartbeat_state CHECK (flow_state IN ('STARTED', 'SUSPENDED', 'FAILED', 'LOADING'))
);
CREATE INDEX ix_heartbeat_seen ON ph04.heartbeat_latest (seen_at);
CALL ph04.p_enable_rls('ph04.heartbeat_latest', 'P');
COMMENT ON TABLE ph04.heartbeat_latest IS 'EN-04-17 Nhịp tim mới nhất của mỗi bản sao cho mỗi luồng (EVT-04-12); chỉ giữ bản mới nhất (UPSERT), lịch sử ở Prometheus. Dòng quá 10 phút bị dọn.';
-- @rollback DROP TABLE IF EXISTS ph04.heartbeat_latest CASCADE;

-- @file 04-0080-catalog.sql
-- @changeset ph04-0800-component-policy
CREATE TABLE ph04.component_policy (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  component_kind   varchar(12)   NOT NULL,
  component_name   varchar(128)  NOT NULL,
  decision         varchar(12)   NOT NULL,
  reason           varchar(1000) NOT NULL,
  approved_by_so   varchar(64),
  policy_version   integer       NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_component_policy PRIMARY KEY (id),
  CONSTRAINT uq_component_policy UNIQUE (tenant_id, component_kind, component_name),
  CONSTRAINT ck_component_policy_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_component_policy_kind CHECK (component_kind IN ('COMPONENT', 'EIP', 'KAMELET', 'DATAFORMAT', 'LANGUAGE', 'BEAN_CLASS')),
  CONSTRAINT ck_component_policy_decision CHECK (decision IN ('ALLOWED', 'PER_FLOW', 'DENIED')),
  -- Tenant chỉ thu hẹp: dòng của tỉnh không được là ALLOWED (FR-04-080).
  CONSTRAINT ck_component_policy_narrow CHECK (tenant_id = 'COMMON' OR decision <> 'ALLOWED')
);
CREATE TRIGGER tg_component_policy_touch BEFORE UPDATE ON ph04.component_policy FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.component_policy', 'S');
COMMENT ON TABLE ph04.component_policy IS 'EN-04-11 Chính sách thành phần: dòng COMMON là chính sách nền do PA đặt; dòng của tỉnh chỉ thu hẹp (PER_FLOW, DENIED). Không có dòng nghĩa là theo mặc định của nhóm (FR-04-080).';
-- @rollback DROP TABLE IF EXISTS ph04.component_policy CASCADE;

-- @changeset ph04-0810-component-proposal
CREATE TABLE ph04.component_proposal (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  component_kind   varchar(12)   NOT NULL,
  component_name   varchar(128)  NOT NULL,
  proposal_type    varchar(12)   NOT NULL,
  justification    varchar(4000) NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'OPEN',
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_note    varchar(2000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_component_proposal PRIMARY KEY (id),
  CONSTRAINT ck_component_proposal_type CHECK (proposal_type IN ('ALLOW', 'NEW_COMPONENT')),
  CONSTRAINT ck_component_proposal_status CHECK (status IN ('OPEN', 'ACCEPTED', 'REJECTED', 'WITHDRAWN'))
);
CREATE TRIGGER tg_component_proposal_touch BEFORE UPDATE ON ph04.component_proposal FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.component_proposal', 'P');
COMMENT ON TABLE ph04.component_proposal IS 'EN-04-18 Đề xuất cho phép, bổ sung thành phần (API-04-074). PA đọc liên tenant qua hàng đợi của PH-18 (sự kiện), không qua bảng.';
-- @rollback DROP TABLE IF EXISTS ph04.component_proposal CASCADE;

-- @changeset ph04-0820-template
CREATE TABLE ph04.template (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(4000),
  category         varchar(32)   NOT NULL,
  resource_kind    varchar(8)    NOT NULL DEFAULT 'ROUTE',
  body_yaml        text          NOT NULL,
  param_schema     jsonb         NOT NULL,
  catalog_version  varchar(64)   NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_template PRIMARY KEY (id),
  CONSTRAINT uq_template_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_template_code CHECK (code ~ '^tpl-[a-z0-9-]{2,60}$'),
  CONSTRAINT ck_template_status CHECK (status IN ('ACTIVE', 'DEPRECATED'))
);
CREATE TRIGGER tg_template_touch BEFORE UPDATE ON ph04.template FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.template', 'S');
COMMENT ON TABLE ph04.template IS 'EN-04-19 Khuôn mẫu luồng (FR-04-025): tám khuôn nền COMMON (tpl-standard-9…) và khuôn riêng của tỉnh.';
-- @rollback DROP TABLE IF EXISTS ph04.template CASCADE;

-- @changeset ph04-0830-palette-rule
CREATE TABLE ph04.palette_group_rule (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  rules_version    integer       NOT NULL,
  document         jsonb         NOT NULL,
  active           boolean       NOT NULL DEFAULT false,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_palette_group_rule PRIMARY KEY (id),
  CONSTRAINT uq_palette_group_rule UNIQUE (tenant_id, rules_version),
  CONSTRAINT ck_palette_tenant CHECK (tenant_id = 'COMMON')
);
CREATE UNIQUE INDEX uq_palette_active ON ph04.palette_group_rule (tenant_id) WHERE active;
CREATE TRIGGER tg_palette_touch BEFORE UPDATE ON ph04.palette_group_rule FOR EACH ROW EXECUTE FUNCTION ph04.tg_touch();
CALL ph04.p_enable_rls('ph04.palette_group_rule', 'S');
COMMENT ON TABLE ph04.palette_group_rule IS 'EN-04-20 Tài liệu palette-groups.json (D03-02-PH04 §6.3); một bản active.';
-- @rollback DROP TABLE IF EXISTS ph04.palette_group_rule CASCADE;

-- @changeset ph04-0840-catalog-change
CREATE TABLE ph04.catalog_change (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  from_version     varchar(64)   NOT NULL,
  to_version       varchar(64)   NOT NULL,
  component_kind   varchar(12)   NOT NULL,
  component_name   varchar(128)  NOT NULL,
  property_name    varchar(128),
  change_type      varchar(12)   NOT NULL,
  detail           jsonb,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_catalog_change PRIMARY KEY (id),
  CONSTRAINT ck_catalog_change_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_catalog_change_type CHECK (change_type IN ('REMOVED', 'RENAMED', 'TYPE_CHANGED', 'DEFAULT_CHANGED', 'DEPRECATED', 'ADDED'))
);
CREATE INDEX ix_catalog_change_ver ON ph04.catalog_change (from_version, to_version);
CALL ph04.p_enable_rls('ph04.catalog_change', 'S');
COMMENT ON TABLE ph04.catalog_change IS 'EN-04-21 Khác biệt catalog giữa hai phiên bản runtime (FR-04-081, UC-04-22).';
-- @rollback DROP TABLE IF EXISTS ph04.catalog_change CASCADE;

-- @file 04-0090-misc.sql
-- @changeset ph04-0900-external-system
CREATE TABLE ph04.external_system (
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  status           varchar(12)   NOT NULL,
  is_member        boolean       NOT NULL,
  source_event_id  uuid          NOT NULL,
  synced_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_external_system PRIMARY KEY (tenant_id, code)
);
CALL ph04.p_enable_rls('ph04.external_system', 'P');
COMMENT ON TABLE ph04.external_system IS 'EN-04-22 Bản sao đọc HTTT đã kết nạp của PH-01 (sự kiện); xác định luồng đối ngoại, kiểm ERR-04-043.';
-- @rollback DROP TABLE IF EXISTS ph04.external_system CASCADE;

-- @changeset ph04-0910-legacy-import
CREATE TABLE ph04.legacy_import_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  workspace_id     uuid          NOT NULL,
  file_name        varchar(255)  NOT NULL,
  file_sha256      char(64)      NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'RUNNING',
  report           jsonb,
  created_flow_ids uuid[]        NOT NULL DEFAULT '{}',
  error_code       varchar(16),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  finished_at      timestamptz,
  CONSTRAINT pk_legacy_import_job PRIMARY KEY (id),
  CONSTRAINT fk_legacy_import_ws FOREIGN KEY (workspace_id, tenant_id) REFERENCES ph04.workspace (id, tenant_id),
  CONSTRAINT ck_legacy_import_status CHECK (status IN ('RUNNING', 'COMPLETED', 'FAILED'))
);
CALL ph04.p_enable_rls('ph04.legacy_import_job', 'P');
COMMENT ON TABLE ph04.legacy_import_job IS 'EN-04-23 Lượt chuyển Camel XML của Bus cũ (FR-04-082). Tệp gốc không lưu sau khi chuyển; báo cáo không chứa mật khẩu.';
-- @rollback DROP TABLE IF EXISTS ph04.legacy_import_job CASCADE;

-- @changeset ph04-0920-outbox
CREATE TABLE ph04.outbox (
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
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.integration\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^t[0-9]{2}\.(integration|audit)\.[a-z-]+(\.[a-z-]+)?\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_outbox_occurred ON ph04.outbox (occurred_at);
ALTER TABLE ph04.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph04.p_enable_rls('ph04.outbox', 'P');
COMMENT ON TABLE ph04.outbox IS 'EN-04-24 Outbox (DD-11) cho EVT-04-01…10 và kiểm toán gửi PH-13; Debezium EventRouter. Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph04.outbox CASCADE;

-- @changeset ph04-0930-shedlock
CREATE TABLE ph04.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph04.shedlock IS 'Khóa tác vụ nền (ShedLock); bảng kỹ thuật không có tenant_id, không chứa dữ liệu nghiệp vụ.';
-- @rollback DROP TABLE IF EXISTS ph04.shedlock;

-- @file 04-0900-grants.sql
-- @changeset ph04-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph04 TO ph04_app;
REVOKE UPDATE, DELETE ON ph04.review FROM ph04_app;              -- chỉ thêm
REVOKE UPDATE ON ph04.outbox FROM ph04_app;                      -- chỉ thêm, xóa khi dọn
REVOKE INSERT, UPDATE, DELETE ON ph04.catalog_change FROM ph04_app;
GRANT INSERT ON ph04.catalog_change TO ph04_app;                 -- CatalogUpgradeJob ghi dưới PLATFORM
GRANT SELECT ON ALL TABLES IN SCHEMA ph04 TO ph04_readonly;
REVOKE SELECT ON ph04.flow_version, ph04.test_run_step FROM ph04_readonly;  -- nội dung luồng, xem trước bản tin
GRANT SELECT (id, tenant_id, flow_id, version_no, status, content_hash, catalog_version, change_note,
              submitted_at, submitted_by, approved_at, approved_by, created_at, created_by)
  ON ph04.flow_version TO ph04_readonly;
GRANT EXECUTE ON PROCEDURE ph04.p_enable_rls(regclass, char) TO ph04_owner;
-- @rollback -- Không cần.

-- @file 04-9000-migrate-legacy-tables.sql
-- @changeset ph04-9000-migrate splitStatements:false context:migrate-w2
-- Di trú từ bảng của apps/control (ph04.route…, không có tenant_id) sang bảng mới.
-- Chạy một lần với tham số tenant đích của dữ liệu thử nghiệm (T68 ở môi trường phát triển).
-- Trạng thái cũ TESTING bị bỏ (ADR-069): ánh xạ về DRAFT. PUBLISHED → APPROVED, không tạo
-- triển khai (GitOps cũ không nạp được runtime, GAP-04-03); phát hành lại qua luồng mới.
-- Đã chạy thử trên PostgreSQL 16 ngày 25/11/2026 với dữ liệu giả.
DO $mig$
DECLARE
  v_tenant varchar(16) := coalesce(current_setting('dh.migrate.tenant', true), 'T68');
  v_ws uuid;
BEGIN
  IF to_regclass('ph04.route') IS NULL THEN
    RAISE NOTICE 'Không có bảng cũ ph04.route, bỏ qua di trú';
    RETURN;
  END IF;
  PERFORM set_config('app.tenant_id', v_tenant, true);
  INSERT INTO ph04.workspace (id, tenant_id, code, name, created_by, updated_by)
    VALUES (gen_random_uuid(), v_tenant, 'DEFAULT', 'Mặc định', 'system:migrate', 'system:migrate')
    ON CONFLICT (tenant_id, code) DO NOTHING;
  SELECT id INTO v_ws FROM ph04.workspace WHERE tenant_id = v_tenant AND code = 'DEFAULT';
  INSERT INTO ph04.flow (id, tenant_id, workspace_id, code, name, resource_kind, transport, exposure,
                         status, source_system, target_systems, origin, created_at, created_by, updated_at, updated_by)
  SELECT r.route_id, v_tenant, v_ws, r.route_code, r.title, 'ROUTE',
         CASE r.route_type WHEN 'ASYNC' THEN 'ASYNC' ELSE 'SYNC' END,
         CASE WHEN r.target_system IS NULL THEN 'INTERNAL' ELSE 'EXTERNAL' END,
         CASE r.status WHEN 'PAUSED' THEN 'PAUSED' WHEN 'PUBLISHED' THEN 'APPROVED' ELSE 'DRAFT' END,
         r.source_system, CASE WHEN r.target_system IS NULL THEN '{}' ELSE ARRAY[r.target_system] END,
         'YAML_FILE', r.created_at, r.created_by, r.updated_at, coalesce(r.updated_by, r.created_by)
  FROM ph04.route r;
  -- Phiên bản: content_hash tạm bằng sha256 của YAML thô; dh-integration tính lại khi khởi động
  -- (needs_revalidation = true) theo YamlCanonicalizer.
  INSERT INTO ph04.flow_version (id, tenant_id, flow_id, version_no, status, definition_yaml, content_hash,
                                 catalog_version, needs_revalidation, submitted_hash, submitted_by, submitted_at,
                                 approved_by, approved_at, created_at, created_by, updated_at, updated_by)
  SELECT v.version_id, v_tenant, v.route_id, v.version_no,
         CASE v.status WHEN 'PUBLISHED' THEN 'APPROVED' WHEN 'PENDING_REVIEW' THEN 'PENDING_REVIEW' ELSE 'DRAFT' END,
         v.definition_yaml,
         'sha256:' || encode(sha256(convert_to(v.definition_yaml, 'UTF8')), 'hex'),
         'camel-quarkus-3.33.1', true,
         CASE WHEN v.status IN ('PUBLISHED', 'PENDING_REVIEW') THEN 'sha256:' || encode(sha256(convert_to(v.definition_yaml, 'UTF8')), 'hex') END,
         CASE WHEN v.status IN ('PUBLISHED', 'PENDING_REVIEW') THEN v.created_by END,
         CASE WHEN v.status IN ('PUBLISHED', 'PENDING_REVIEW') THEN v.updated_at END,
         CASE WHEN v.status = 'PUBLISHED' THEN 'system:migrate' END,
         CASE WHEN v.status = 'PUBLISHED' THEN v.updated_at END,
         v.created_at, v.created_by, v.updated_at, v.created_by
  FROM ph04.route_version v;
  -- Lần chạy thử cũ là mô phỏng (GAP-04-04): chuyển với mode/status SIMULATED để không thỏa BR-04-004.
  INSERT INTO ph04.test_run (id, tenant_id, flow_version_id, definition_hash, mode, status, timeout_seconds,
                             duration_ms, trace_id, run_by, queued_at, finished_at)
  SELECT t.run_id, v_tenant, fv.id, fv.content_hash, 'SIMULATED', 'SIMULATED', 30, t.duration_ms,
         CASE WHEN t.trace_id ~ '^[0-9a-f]{32}$' THEN t.trace_id END, t.run_by, t.run_at, t.run_at
  FROM ph04.route_test_run t
  JOIN ph04.flow_version fv ON fv.flow_id = t.route_id AND fv.version_no = t.version_no;
  ALTER TABLE ph04.route RENAME TO route_legacy_w2;
  ALTER TABLE ph04.route_version RENAME TO route_version_legacy_w2;
  ALTER TABLE ph04.route_test_run RENAME TO route_test_run_legacy_w2;
  ALTER TABLE ph04.route_test_run_stage RENAME TO route_test_run_stage_legacy_w2;
END
$mig$;
-- @rollback -- Đổi tên ngược bốn bảng *_legacy_w2 bằng tay; dữ liệu mới không xóa tự động.

RESET ROLE;
