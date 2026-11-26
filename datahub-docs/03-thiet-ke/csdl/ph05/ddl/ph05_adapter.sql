-- =============================================================================
-- D03-03-PH05 · DDL schema ph05_adapter — PH-05 Bộ điều hợp và kết nối
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph05_adapter.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Không lưu giá trị bí mật ở bất kỳ bảng nào (BR-05-001): chỉ đường dẫn OpenBao suy ra
-- từ mã và số phiên bản. Thay bảng ph05.adapter của apps/adapter-mgr (W1); di trú ở
-- changeset ph05-9000 (cuối tệp, context migrate-w1).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 05-0000-bootstrap.sql
-- @changeset ph05-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph05_owner') THEN
    CREATE ROLE ph05_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph05_app') THEN
    CREATE ROLE ph05_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph05_readonly') THEN
    CREATE ROLE ph05_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph05-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph05_adapter AUTHORIZATION ph05_owner;
COMMENT ON SCHEMA ph05_adapter IS 'PH-05 Bộ điều hợp và kết nối: kết nối nguồn, giá trị môi trường, cấp, kiểm tra, sức khỏe, tài khoản CSDL cho luồng, bộ điều hợp, CDC, Kamelet. Không có giá trị bí mật. dh-integration kết nối bằng dh_integration_app (thành viên ph05_app).';
GRANT USAGE ON SCHEMA ph05_adapter TO ph05_app, ph05_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph05_adapter CASCADE;

SET ROLE ph05_owner;

-- @changeset ph05-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 05-0001-functions.sql
-- @changeset ph05-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph05_adapter.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph05_adapter.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph05_adapter.tg_touch();

-- @changeset ph05-0011-fn-rls splitStatements:false
-- Hai mẫu của D03-10, giống PH-04: 'P' riêng tenant; 'S' dùng chung (đọc thêm COMMON,
-- ghi COMMON chỉ khi app.tenant_id = 'PLATFORM').
CREATE OR REPLACE PROCEDURE ph05_adapter.p_enable_rls(p_table regclass, p_mode char)
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
COMMENT ON PROCEDURE ph05_adapter.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph05_adapter.p_enable_rls(regclass, char);

-- @changeset ph05-0012-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph05_adapter.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_months - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + make_interval(months => i), 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, (d + make_interval(months => i))::timestamptz,
                     (d + make_interval(months => i + 1))::timestamptz);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph05_adapter.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng; PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới. Dọn bằng DETACH, DROP dưới ph05_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph05_adapter.p_ensure_month_partitions(regclass, date, integer);

-- @changeset ph05-0013-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph05_adapter.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm (append-only)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph05_adapter.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng nhật ký (db_access_record, cdc_schema_change sau khi xử lý xong qua cột trạng thái riêng).';
-- @rollback DROP FUNCTION IF EXISTS ph05_adapter.tg_append_only();

-- @file 05-0010-connection.sql
-- @changeset ph05-0100-connection-type-setting
CREATE TABLE ph05_adapter.connection_type_setting (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  type_code        varchar(32)   NOT NULL,
  enabled          boolean       NOT NULL DEFAULT true,
  block_new        boolean       NOT NULL DEFAULT false,
  ceilings         jsonb         NOT NULL DEFAULT '{}',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_connection_type_setting PRIMARY KEY (id),
  CONSTRAINT uq_connection_type_setting UNIQUE (tenant_id, type_code),
  CONSTRAINT ck_connection_type_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_connection_type_setting_code CHECK (type_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_connection_type_setting_ceilings CHECK (jsonb_typeof(ceilings) = 'object')
);
CREATE TRIGGER tg_connection_type_setting_touch BEFORE UPDATE ON ph05_adapter.connection_type_setting FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.connection_type_setting', 'P');
COMMENT ON TABLE ph05_adapter.connection_type_setting IS 'EN-05-01 phần tenant: bật, tắt loại kết nối và trần tham số (FR-05-061). Danh mục loại đóng gói trong dh-integration (classpath conntypes/*.json), không lưu ở CSDL.';
COMMENT ON COLUMN ph05_adapter.connection_type_setting.block_new IS 'true: loại vẫn chạy cho kết nối đang có nhưng chặn tạo mới (tắt mềm).';
COMMENT ON COLUMN ph05_adapter.connection_type_setting.ceilings IS 'Trần tham số theo tenant, ví dụ {"timeoutMs":60000,"maxConcurrency":20}; chỉ thu hẹp trần nền tảng.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.connection_type_setting CASCADE;

-- @changeset ph05-0110-connection
CREATE TABLE ph05_adapter.connection (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  type_code        varchar(32)   NOT NULL,
  system_code      varchar(64)   NOT NULL,
  purpose          varchar(10)   NOT NULL,
  description      varchar(2000),
  owner            varchar(64)   NOT NULL,
  labels           varchar(32)[] NOT NULL DEFAULT '{}',
  status           varchar(10)   NOT NULL DEFAULT 'DRAFT',
  status_reason    varchar(1000),
  suspended_by_role varchar(4),
  config_version   integer       NOT NULL DEFAULT 1,
  legacy_ref       varchar(255),
  retired_at       timestamptz,
  secret_destroy_at timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_connection PRIMARY KEY (id),
  CONSTRAINT uq_connection_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_connection_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_connection_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_connection_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_connection_purpose CHECK (purpose IN ('READ', 'READ_WRITE')),
  CONSTRAINT ck_connection_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_connection_labels CHECK (cardinality(labels) <= 10),
  CONSTRAINT ck_connection_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE INDEX ix_connection_system ON ph05_adapter.connection (tenant_id, system_code);
CREATE INDEX ix_connection_type_status ON ph05_adapter.connection (tenant_id, type_code, status);
CREATE INDEX ix_connection_name_trgm ON ph05_adapter.connection USING gin (lower(name) gin_trgm_ops);
CREATE INDEX ix_connection_secret_destroy ON ph05_adapter.connection (secret_destroy_at) WHERE secret_destroy_at IS NOT NULL;
CREATE TRIGGER tg_connection_touch BEFORE UPDATE ON ph05_adapter.connection FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.connection', 'P');
COMMENT ON TABLE ph05_adapter.connection IS 'EN-05-02 Kết nối nguồn (FR-05-004). Mã bất biến, không dùng lại kể cả khi RETIRED (BR-05-004). Bí mật ở OpenBao kv/dh/{tenant}/conn/{code}/{env}.';
COMMENT ON COLUMN ph05_adapter.connection.system_code IS 'Mã HTTT ở PH-01 (bản sao system_replica); không khóa ngoại vì khác schema, kiểm ở dịch vụ.';
COMMENT ON COLUMN ph05_adapter.connection.suspended_by_role IS 'SO khi SO tạm ngừng: chỉ SO được tiếp tục (FR-05-008).';
COMMENT ON COLUMN ph05_adapter.connection.config_version IS 'Tăng mỗi lần đổi tham số hoặc bí mật ở bất kỳ môi trường; runtime bỏ qua sự kiện cũ hơn (lũy đẳng).';
COMMENT ON COLUMN ph05_adapter.connection.legacy_ref IS 'Vị trí trong hệ cũ (tệp Context XML, tên bean) khi tạo từ nhập hệ cũ (FR-05-016).';
COMMENT ON COLUMN ph05_adapter.connection.secret_destroy_at IS 'Hạn hủy bí mật = retired_at + 30 ngày (BR-05-012); SecretDestroyJob xử lý.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.connection CASCADE;

-- @changeset ph05-0120-connection-environment
CREATE TABLE ph05_adapter.connection_environment (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  connection_id      uuid          NOT NULL,
  env                varchar(8)    NOT NULL,
  params             jsonb         NOT NULL,
  params_hash        char(64)      NOT NULL,
  pending_params     jsonb,
  pending_params_hash char(64),
  secret_version     integer       NOT NULL DEFAULT 0,
  pending_secret_version integer,
  fallback_secret_version integer,
  secret_written_by  varchar(64),
  secret_written_at  timestamptz,
  status             varchar(16)   NOT NULL DEFAULT 'CONFIGURED',
  status_before_suspend varchar(16),
  last_passed_test_id uuid,
  last_passed_at     timestamptz,
  requested_by       varchar(64),
  requested_at       timestamptz,
  approved_by        varchar(64),
  approved_at        timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_connection_environment PRIMARY KEY (id),
  CONSTRAINT uq_connection_environment UNIQUE (tenant_id, connection_id, env),
  CONSTRAINT fk_connection_environment_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_connection_environment_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_connection_environment_status CHECK (status IN ('CONFIGURED', 'PENDING_APPROVAL', 'ENABLED', 'DISABLED')),
  CONSTRAINT ck_connection_environment_params CHECK (jsonb_typeof(params) = 'object'),
  CONSTRAINT ck_connection_environment_secret CHECK (secret_version >= 0),
  CONSTRAINT ck_connection_environment_enabled CHECK (status <> 'ENABLED' OR (last_passed_test_id IS NOT NULL AND secret_version > 0)),
  CONSTRAINT ck_connection_environment_prod_approval CHECK (env <> 'PROD' OR status <> 'ENABLED' OR approved_by IS NOT NULL),
  CONSTRAINT ck_connection_environment_four_eyes CHECK (approved_by IS NULL OR (approved_by <> requested_by AND approved_by IS DISTINCT FROM secret_written_by)),
  CONSTRAINT ck_connection_environment_no_secret_in_params CHECK (NOT (params ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'passphrase']))
);
CREATE INDEX ix_connection_environment_status ON ph05_adapter.connection_environment (tenant_id, env, status);
CREATE TRIGGER tg_connection_environment_touch BEFORE UPDATE ON ph05_adapter.connection_environment FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.connection_environment', 'P');
COMMENT ON TABLE ph05_adapter.connection_environment IS 'EN-05-03 Giá trị môi trường (FR-05-005, 006, 007). Tối đa ba dòng mỗi kết nối. Giá trị PROD đang ENABLED khi sửa giữ bản chờ ở pending_* (BR-05-010).';
COMMENT ON COLUMN ph05_adapter.connection_environment.params IS 'Tham số không bí mật, kiểm theo JSON Schema của loại kết nối. CHECK chặn khóa có tên bí mật phổ biến (lớp phụ, lớp chính ở dịch vụ).';
COMMENT ON COLUMN ph05_adapter.connection_environment.params_hash IS 'SHA-256 của params đã chuẩn hóa; lần kiểm tra lưu cùng giá trị để so khớp khi bật (BR-05-006).';
COMMENT ON COLUMN ph05_adapter.connection_environment.secret_version IS 'Phiên bản KV v2 ở OpenBao đang hiệu lực; 0 khi chưa khai báo bí mật.';
COMMENT ON COLUMN ph05_adapter.connection_environment.fallback_secret_version IS 'Phiên bản cũ còn dùng được trong thời gian chuyển tiếp xoay (BR-05-007).';
COMMENT ON COLUMN ph05_adapter.connection_environment.secret_written_by IS 'Người ghi bí mật gần nhất; người duyệt PROD phải khác (BR-05-009).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.connection_environment CASCADE;

-- @changeset ph05-0130-connection-grant
CREATE TABLE ph05_adapter.connection_grant (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  connection_id    uuid          NOT NULL,
  scope            varchar(10)   NOT NULL,
  target_code      varchar(63)   NOT NULL,
  environments     varchar(8)[]  NOT NULL,
  valid_until      date,
  reason           varchar(1000),
  revoked_at       timestamptz,
  revoked_by       varchar(64),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_connection_grant PRIMARY KEY (id),
  CONSTRAINT fk_connection_grant_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_connection_grant_scope CHECK (scope IN ('WORKSPACE', 'FLOW')),
  CONSTRAINT ck_connection_grant_envs CHECK (cardinality(environments) BETWEEN 1 AND 3 AND environments <@ ARRAY['TEST', 'STAGING', 'PROD']::varchar(8)[])
);
CREATE UNIQUE INDEX uq_connection_grant_active ON ph05_adapter.connection_grant (tenant_id, connection_id, scope, target_code) WHERE revoked_at IS NULL;
CREATE INDEX ix_connection_grant_target ON ph05_adapter.connection_grant (tenant_id, scope, target_code) WHERE revoked_at IS NULL;
CREATE TRIGGER tg_connection_grant_touch BEFORE UPDATE ON ph05_adapter.connection_grant FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.connection_grant', 'P');
COMMENT ON TABLE ph05_adapter.connection_grant IS 'EN-05-04 Cấp kết nối cho không gian làm việc hoặc luồng PH-04 (FR-05-009). Thu hồi giữ dòng (revoked_at) để kiểm toán.';
COMMENT ON COLUMN ph05_adapter.connection_grant.target_code IS 'Mã không gian (scope WORKSPACE) hoặc mã luồng (scope FLOW) ở schema ph04; kiểm qua FlowQueryApi.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.connection_grant CASCADE;

-- @changeset ph05-0140-connection-test
CREATE TABLE ph05_adapter.connection_test (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  connection_id    uuid          NOT NULL,
  env              varchar(8)    NOT NULL,
  kind             varchar(8)    NOT NULL DEFAULT 'MANUAL',
  status           varchar(8)    NOT NULL DEFAULT 'RUNNING',
  params_hash      char(64)      NOT NULL,
  secret_version   integer       NOT NULL,
  steps            jsonb         NOT NULL DEFAULT '[]',
  cause_code       varchar(32),
  latency_ms       integer,
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  expires_at       timestamptz,
  run_by           varchar(64)   NOT NULL,
  CONSTRAINT pk_connection_test PRIMARY KEY (id),
  CONSTRAINT fk_connection_test_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_connection_test_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_connection_test_kind CHECK (kind IN ('MANUAL', 'ROTATION', 'PRIVILEGE', 'CDC_PREREQ')),
  CONSTRAINT ck_connection_test_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED')),
  CONSTRAINT ck_connection_test_finished CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_connection_test_expires CHECK (status <> 'PASSED' OR expires_at = finished_at + interval '24 hours'),
  CONSTRAINT ck_connection_test_steps CHECK (jsonb_typeof(steps) = 'array')
);
CREATE INDEX ix_connection_test_conn ON ph05_adapter.connection_test (tenant_id, connection_id, env, started_at DESC);
CREATE INDEX ix_connection_test_running ON ph05_adapter.connection_test (started_at) WHERE status = 'RUNNING';
CALL ph05_adapter.p_enable_rls('ph05_adapter.connection_test', 'P');
COMMENT ON TABLE ph05_adapter.connection_test IS 'EN-05-05 Lần kiểm tra kết nối (FR-05-010, 025, 049). Giữ 1 năm (NFR-05-015), ConnectionTestRetentionJob dọn. Không có version: chỉ ProbeResultConsumer đổi trạng thái RUNNING → kết quả.';
COMMENT ON COLUMN ph05_adapter.connection_test.steps IS 'Mảng {name, status, durationMs, causeCode, hint}; hint là câu đã điền giá trị không bí mật.';
COMMENT ON COLUMN ph05_adapter.connection_test.kind IS 'MANUAL kiểm tra thường; ROTATION kiểm tra phiên bản mới khi xoay; PRIVILEGE kiểm quyền db-flow (FR-05-025); CDC_PREREQ điều kiện CDC (FR-05-049).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.connection_test CASCADE;

-- @changeset ph05-0150-secret-rotation
CREATE TABLE ph05_adapter.secret_rotation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  connection_id    uuid          NOT NULL,
  env              varchar(8)    NOT NULL,
  old_version      integer       NOT NULL,
  new_version      integer       NOT NULL,
  status           varchar(12)   NOT NULL DEFAULT 'TESTING',
  test_id          uuid,
  transition_until timestamptz,
  completed_at     timestamptz,
  reason           varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_secret_rotation PRIMARY KEY (id),
  CONSTRAINT fk_secret_rotation_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_secret_rotation_status CHECK (status IN ('TESTING', 'TRANSITION', 'COMPLETED', 'FAILED')),
  CONSTRAINT ck_secret_rotation_versions CHECK (new_version > old_version),
  CONSTRAINT ck_secret_rotation_transition CHECK (status <> 'TRANSITION' OR transition_until IS NOT NULL)
);
CREATE UNIQUE INDEX uq_secret_rotation_open ON ph05_adapter.secret_rotation (tenant_id, connection_id, env) WHERE status IN ('TESTING', 'TRANSITION');
CREATE INDEX ix_secret_rotation_due ON ph05_adapter.secret_rotation (transition_until) WHERE status = 'TRANSITION';
CREATE TRIGGER tg_secret_rotation_touch BEFORE UPDATE ON ph05_adapter.secret_rotation FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.secret_rotation', 'P');
COMMENT ON TABLE ph05_adapter.secret_rotation IS 'EN-05-07 Lần xoay bí mật (FR-05-012). Chỉ một lần mở mỗi (kết nối, môi trường): uq_secret_rotation_open hiện thực ERR-05-036.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.secret_rotation CASCADE;

-- @file 05-0020-health.sql
-- @changeset ph05-0200-health-sample
CREATE TABLE ph05_adapter.health_sample (
  tenant_id        varchar(16)   NOT NULL,
  object_kind      varchar(10)   NOT NULL,
  object_code      varchar(63)   NOT NULL,
  env              varchar(8)    NOT NULL,
  sampled_at       timestamptz   NOT NULL,
  granularity      varchar(4)    NOT NULL DEFAULT 'MIN',
  probe_ok         boolean,
  calls            integer       NOT NULL DEFAULT 0,
  transient_errors integer       NOT NULL DEFAULT 0,
  p95_ms           integer,
  pool_wait_p95_ms integer,
  level            varchar(10)   NOT NULL,
  CONSTRAINT pk_health_sample PRIMARY KEY (tenant_id, object_kind, object_code, env, granularity, sampled_at),
  CONSTRAINT ck_health_sample_kind CHECK (object_kind IN ('CONNECTION', 'ADAPTER')),
  CONSTRAINT ck_health_sample_gran CHECK (granularity IN ('MIN', 'HOUR')),
  CONSTRAINT ck_health_sample_level CHECK (level IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY', 'UNKNOWN'))
) PARTITION BY RANGE (sampled_at);
CALL ph05_adapter.p_ensure_month_partitions('ph05_adapter.health_sample', current_date - 31, 5);
CALL ph05_adapter.p_enable_rls('ph05_adapter.health_sample', 'P');
COMMENT ON TABLE ph05_adapter.health_sample IS 'EN-05-06 Mẫu sức khỏe mỗi phút (FR-05-019, 020). Sau 7 ngày gộp thành granularity HOUR; giữ 90 ngày (NFR-05-015), dọn bằng DETACH phân vùng tháng.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.health_sample CASCADE;

-- @changeset ph05-0210-health-state
CREATE TABLE ph05_adapter.health_state (
  tenant_id        varchar(16)   NOT NULL,
  object_kind      varchar(10)   NOT NULL,
  object_code      varchar(63)   NOT NULL,
  env              varchar(8)    NOT NULL,
  level            varchar(10)   NOT NULL DEFAULT 'UNKNOWN',
  reason_code      varchar(32),
  reason_detail    varchar(1000),
  candidate_level  varchar(10),
  candidate_count  smallint      NOT NULL DEFAULT 0,
  since            timestamptz   NOT NULL DEFAULT now(),
  evaluated_at     timestamptz   NOT NULL DEFAULT now(),
  consecutive_probe_failures smallint NOT NULL DEFAULT 0,
  CONSTRAINT pk_health_state PRIMARY KEY (tenant_id, object_kind, object_code, env),
  CONSTRAINT ck_health_state_kind CHECK (object_kind IN ('CONNECTION', 'ADAPTER')),
  CONSTRAINT ck_health_state_level CHECK (level IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY', 'UNKNOWN')),
  CONSTRAINT ck_health_state_candidate CHECK (candidate_level IS NULL OR candidate_level IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY', 'UNKNOWN'))
);
CREATE INDEX ix_health_state_level ON ph05_adapter.health_state (tenant_id, level) WHERE level IN ('DEGRADED', 'UNHEALTHY');
CALL ph05_adapter.p_enable_rls('ph05_adapter.health_state', 'P');
COMMENT ON TABLE ph05_adapter.health_state IS 'EN-05-06 Mức sức khỏe hiện tại (FR-05-021); candidate_* hiện thực chống dao động 2 chu kỳ (3 về HEALTHY). Lịch sử mức là sự kiện EVT-05-06.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.health_state CASCADE;

-- @changeset ph05-0220-health-baseline
CREATE TABLE ph05_adapter.health_baseline (
  tenant_id        varchar(16)   NOT NULL,
  object_kind      varchar(10)   NOT NULL,
  object_code      varchar(63)   NOT NULL,
  env              varchar(8)    NOT NULL,
  p95_ms_7d        integer       NOT NULL,
  computed_at      timestamptz   NOT NULL,
  CONSTRAINT pk_health_baseline PRIMARY KEY (tenant_id, object_kind, object_code, env)
);
CALL ph05_adapter.p_enable_rls('ph05_adapter.health_baseline', 'P');
COMMENT ON TABLE ph05_adapter.health_baseline IS 'Đường nền p95 7 ngày, tính lại 01:00 hằng đêm từ health_sample (FR-05-020: DEGRADED khi p95 > 2 lần đường nền).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.health_baseline CASCADE;

-- @file 05-0030-dbaccess.sql
-- @changeset ph05-0300-flow-db-account
CREATE TABLE ph05_adapter.flow_db_account (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  connection_id    uuid          NOT NULL,
  flow_code        varchar(63)   NOT NULL,
  env              varchar(8)    NOT NULL,
  access_mode      varchar(6)    NOT NULL,
  provisioning     varchar(8)    NOT NULL DEFAULT 'DYNAMIC',
  schemas          varchar(63)[] NOT NULL,
  tables           varchar(127)[] NOT NULL DEFAULT '{}',
  operations       varchar(8)[]  NOT NULL DEFAULT '{SELECT}',
  justification    varchar(2000) NOT NULL,
  owner_consent_ref varchar(255),
  status           varchar(10)   NOT NULL DEFAULT 'REQUESTED',
  openbao_role     varchar(63),
  valid_until      date,
  requested_by     varchar(64)   NOT NULL,
  consented_by     varchar(64),
  consented_at     timestamptz,
  approved_by      varchar(64),
  approved_at      timestamptz,
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  revoke_reason    varchar(1000),
  last_privilege_test_id uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_flow_db_account PRIMARY KEY (id),
  CONSTRAINT fk_flow_db_account_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id),
  CONSTRAINT ck_flow_db_account_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_flow_db_account_mode CHECK (access_mode IN ('READ', 'WRITE')),
  CONSTRAINT ck_flow_db_account_prov CHECK (provisioning IN ('DYNAMIC', 'STATIC')),
  CONSTRAINT ck_flow_db_account_status CHECK (status IN ('REQUESTED', 'CONSENTED', 'ISSUED', 'REJECTED', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_flow_db_account_ops CHECK (operations <@ ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']::varchar(8)[] AND cardinality(operations) >= 1),
  CONSTRAINT ck_flow_db_account_read_ops CHECK (access_mode = 'WRITE' OR operations = ARRAY['SELECT']::varchar(8)[]),
  CONSTRAINT ck_flow_db_account_write_tables CHECK (access_mode = 'READ' OR cardinality(tables) >= 1),
  CONSTRAINT ck_flow_db_account_write_until CHECK (access_mode = 'READ' OR (valid_until IS NOT NULL AND valid_until <= (created_at::date + 90))),
  CONSTRAINT ck_flow_db_account_write_consent CHECK (access_mode = 'READ' OR status IN ('REQUESTED', 'REJECTED') OR consented_by IS NOT NULL),
  CONSTRAINT ck_flow_db_account_four_eyes CHECK (approved_by IS NULL OR (approved_by <> requested_by AND approved_by IS DISTINCT FROM consented_by))
);
CREATE UNIQUE INDEX uq_flow_db_account_live ON ph05_adapter.flow_db_account (tenant_id, connection_id, flow_code, env, access_mode) WHERE status IN ('REQUESTED', 'CONSENTED', 'ISSUED');
CREATE INDEX ix_flow_db_account_flow ON ph05_adapter.flow_db_account (tenant_id, flow_code);
CREATE INDEX ix_flow_db_account_expiry ON ph05_adapter.flow_db_account (valid_until) WHERE status = 'ISSUED' AND valid_until IS NOT NULL;
CREATE TRIGGER tg_flow_db_account_touch BEFORE UPDATE ON ph05_adapter.flow_db_account FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.flow_db_account', 'P');
COMMENT ON TABLE ph05_adapter.flow_db_account IS 'EN-05-08 Tài khoản CSDL cho luồng (FR-05-023…028, ADR-067, Q359). Ghi cần SO đồng ý rồi IA duyệt, tối đa 90 ngày (BR-05-020).';
COMMENT ON COLUMN ph05_adapter.flow_db_account.openbao_role IS 'Tên role database engine dh-{tenant}-{flow}-{env} (cắt + băm 6 ký tự nếu > 63). NULL khi STATIC.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.flow_db_account CASCADE;

-- @changeset ph05-0310-db-access-record
CREATE TABLE ph05_adapter.db_access_record (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  connection_code  varchar(63)   NOT NULL,
  flow_code        varchar(63)   NOT NULL,
  flow_version     integer       NOT NULL,
  env              varchar(8)    NOT NULL,
  db_username      varchar(128)  NOT NULL,
  statement_hash   char(64)      NOT NULL,
  statement_kind   varchar(8)    NOT NULL,
  row_count        integer       NOT NULL,
  duration_ms      integer       NOT NULL,
  outcome          varchar(8)    NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL,
  received_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_db_access_record PRIMARY KEY (event_id, occurred_at),
  CONSTRAINT ck_db_access_record_kind CHECK (statement_kind IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CALL')),
  CONSTRAINT ck_db_access_record_outcome CHECK (outcome IN ('OK', 'DENIED', 'ERROR'))
) PARTITION BY RANGE (occurred_at);
CALL ph05_adapter.p_ensure_month_partitions('ph05_adapter.db_access_record', current_date - 31, 5);
CREATE INDEX ix_db_access_record_flow ON ph05_adapter.db_access_record (tenant_id, flow_code, occurred_at DESC);
CREATE INDEX ix_db_access_record_conn ON ph05_adapter.db_access_record (tenant_id, connection_code, occurred_at DESC);
CREATE TRIGGER tg_db_access_record_append BEFORE UPDATE OR DELETE ON ph05_adapter.db_access_record FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_append_only();
CALL ph05_adapter.p_enable_rls('ph05_adapter.db_access_record', 'P');
COMMENT ON TABLE ph05_adapter.db_access_record IS 'EN-05-09 Bản ghi truy cập CSDL từ runtime qua EVT-05-14 (FR-05-027). Chỉ thêm; 12 tháng trực tuyến, bản WORM 5 năm ở PH-13. Không có câu lệnh đầy đủ, chỉ băm.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.db_access_record CASCADE;

-- @file 05-0040-adapter.sql
-- @changeset ph05-0400-adapter
CREATE TABLE ph05_adapter.adapter (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  code             varchar(40)   NOT NULL,
  name             varchar(255)  NOT NULL,
  system_code      varchar(64)   NOT NULL,
  system_group     smallint      NOT NULL,
  protocol         varchar(10)   NOT NULL,
  connection_id    uuid          NOT NULL,
  description      varchar(2000),
  owner            varchar(64)   NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'DRAFT',
  status_reason    varchar(1000),
  effective_version_id uuid,
  legacy_ref       varchar(255),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_adapter PRIMARY KEY (id),
  CONSTRAINT uq_adapter_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_adapter_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_adapter_conn FOREIGN KEY (connection_id, tenant_id) REFERENCES ph05_adapter.connection (id, tenant_id),
  CONSTRAINT ck_adapter_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_adapter_code CHECK (code ~ '^[a-z][a-z0-9-]{2,39}$'),
  CONSTRAINT ck_adapter_group CHECK (system_group BETWEEN 1 AND 4),
  CONSTRAINT ck_adapter_protocol CHECK (protocol IN ('REST', 'SOAP', 'MESSAGING', 'FILE', 'DATABASE', 'MAIL', 'DIRECTORY', 'CDC')),
  CONSTRAINT ck_adapter_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_adapter_cdc_group CHECK (protocol <> 'CDC' OR system_group IN (3, 4)),
  CONSTRAINT ck_adapter_active_version CHECK (status IN ('DRAFT', 'RETIRED') OR effective_version_id IS NOT NULL)
);
CREATE INDEX ix_adapter_system ON ph05_adapter.adapter (tenant_id, system_code);
CREATE INDEX ix_adapter_conn ON ph05_adapter.adapter (tenant_id, connection_id);
CREATE INDEX ix_adapter_protocol_status ON ph05_adapter.adapter (tenant_id, protocol, status);
CREATE TRIGGER tg_adapter_touch BEFORE UPDATE ON ph05_adapter.adapter FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.adapter', 'P');
COMMENT ON TABLE ph05_adapter.adapter IS 'EN-05-10 Bộ điều hợp (FR-05-029…035). Kết nối phải cùng system_code (BR-05-015, kiểm ở dịch vụ).';
COMMENT ON COLUMN ph05_adapter.adapter.system_group IS 'Nhóm HTTT 1–4 theo FRS §2 (1 có API chuẩn … 4 chỉ có CSDL hoặc tệp).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.adapter CASCADE;

-- @changeset ph05-0410-adapter-version
CREATE TABLE ph05_adapter.adapter_version (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  adapter_id       uuid          NOT NULL,
  major            integer       NOT NULL,
  minor            integer       NOT NULL DEFAULT 0,
  status           varchar(12)   NOT NULL DEFAULT 'DRAFT',
  max_concurrency  integer       NOT NULL DEFAULT 10,
  acquire_timeout_ms integer     NOT NULL DEFAULT 2000,
  idle_timeout_seconds integer   NOT NULL DEFAULT 300,
  rate_limit       jsonb,
  spec_kind        varchar(8),
  spec_object_key  varchar(512),
  spec_hash        char(64),
  spec_fetched_at  timestamptz,
  content_hash     char(64),
  change_note      varchar(2000),
  last_test_id     uuid,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  approved_by      varchar(64),
  approved_at      timestamptz,
  reject_reason    varchar(2000),
  superseded_at    timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_adapter_version PRIMARY KEY (id),
  CONSTRAINT uq_adapter_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_adapter_version_no UNIQUE (tenant_id, adapter_id, major, minor),
  CONSTRAINT fk_adapter_version_adapter FOREIGN KEY (adapter_id, tenant_id) REFERENCES ph05_adapter.adapter (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_adapter_version_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'SUPERSEDED')),
  CONSTRAINT ck_adapter_version_no CHECK (major >= 1 AND minor >= 0),
  CONSTRAINT ck_adapter_version_conc CHECK (max_concurrency BETWEEN 1 AND 500),
  CONSTRAINT ck_adapter_version_spec CHECK (spec_kind IS NULL OR spec_kind IN ('OPENAPI', 'WSDL', 'XSD', 'CSV_HDR')),
  CONSTRAINT ck_adapter_version_four_eyes CHECK (approved_by IS NULL OR approved_by <> submitted_by),
  CONSTRAINT ck_adapter_version_approved CHECK (status NOT IN ('APPROVED', 'SUPERSEDED') OR (approved_by IS NOT NULL AND content_hash IS NOT NULL))
);
CREATE UNIQUE INDEX uq_adapter_version_one_draft ON ph05_adapter.adapter_version (tenant_id, adapter_id) WHERE status IN ('DRAFT', 'SUBMITTED');
CREATE UNIQUE INDEX uq_adapter_version_one_approved ON ph05_adapter.adapter_version (tenant_id, adapter_id) WHERE status = 'APPROVED';
CREATE TRIGGER tg_adapter_version_touch BEFORE UPDATE ON ph05_adapter.adapter_version FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.adapter_version', 'P');
COMMENT ON TABLE ph05_adapter.adapter_version IS 'EN-05-11 Phiên bản bộ điều hợp (FR-05-043, 044). Một bản nháp (DRAFT hoặc SUBMITTED) và một bản APPROVED mỗi bộ điều hợp (BR-05-016). Bất biến sau duyệt: trigger tg_adapter_version_frozen.';
COMMENT ON COLUMN ph05_adapter.adapter_version.spec_object_key IS 'Khóa tệp đặc tả đệm ở bucket dh-adapter-spec (Ceph RGW): {tenant}/{adapter}/{major}.{minor}/{hash}.';
COMMENT ON COLUMN ph05_adapter.adapter_version.content_hash IS 'SHA-256 của phiên bản và mọi thao tác đã chuẩn hóa; Kamelet sinh dẫn tới giá trị này.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.adapter_version CASCADE;

-- @changeset ph05-0411-adapter-version-frozen splitStatements:false
CREATE OR REPLACE FUNCTION ph05_adapter.tg_adapter_version_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status IN ('APPROVED', 'SUPERSEDED') THEN
    IF NEW.status = 'SUPERSEDED' AND OLD.status = 'APPROVED'
       AND (NEW.max_concurrency, NEW.content_hash, NEW.spec_hash, NEW.major, NEW.minor)
           IS NOT DISTINCT FROM (OLD.max_concurrency, OLD.content_hash, OLD.spec_hash, OLD.major, OLD.minor) THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Phiên bản bộ điều hợp % đã duyệt là bất biến', OLD.id USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_adapter_version_frozen BEFORE UPDATE ON ph05_adapter.adapter_version FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_adapter_version_frozen();
-- @rollback DROP TRIGGER IF EXISTS tg_adapter_version_frozen ON ph05_adapter.adapter_version; DROP FUNCTION IF EXISTS ph05_adapter.tg_adapter_version_frozen();

-- @changeset ph05-0412-adapter-effective-fk
ALTER TABLE ph05_adapter.adapter ADD CONSTRAINT fk_adapter_effective_version
  FOREIGN KEY (effective_version_id, tenant_id) REFERENCES ph05_adapter.adapter_version (id, tenant_id) DEFERRABLE INITIALLY DEFERRED;
-- @rollback ALTER TABLE ph05_adapter.adapter DROP CONSTRAINT IF EXISTS fk_adapter_effective_version;

-- @changeset ph05-0420-adapter-operation
CREATE TABLE ph05_adapter.adapter_operation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  adapter_version_id uuid        NOT NULL,
  code             varchar(41)   NOT NULL,
  title            varchar(255)  NOT NULL,
  direction        varchar(8)    NOT NULL,
  protocol_spec    jsonb         NOT NULL,
  request_format   varchar(12)   NOT NULL,
  response_format  varchar(12)   NOT NULL,
  request_schema_ref varchar(255),
  response_schema_ref varchar(255),
  normalization    jsonb         NOT NULL DEFAULT '{}',
  pagination       jsonb,
  timeout_ms       integer       NOT NULL DEFAULT 10000,
  idempotent       boolean       NOT NULL DEFAULT false,
  side_effect      varchar(8)    NOT NULL,
  sample_request   text,
  sample_response  text,
  kamelet_name     varchar(100),
  sort_order       smallint      NOT NULL DEFAULT 0,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_adapter_operation PRIMARY KEY (id),
  CONSTRAINT uq_adapter_operation_code UNIQUE (tenant_id, adapter_version_id, code),
  CONSTRAINT fk_adapter_operation_version FOREIGN KEY (adapter_version_id, tenant_id) REFERENCES ph05_adapter.adapter_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_adapter_operation_code CHECK (code ~ '^[a-z][a-z0-9-]{1,40}$'),
  CONSTRAINT ck_adapter_operation_dir CHECK (direction IN ('OUTBOUND', 'INBOUND')),
  CONSTRAINT ck_adapter_operation_fmt CHECK (request_format IN ('JSON', 'XML', 'SOAP', 'CSV', 'FIXED_WIDTH', 'BINARY', 'NONE')
                                     AND response_format IN ('JSON', 'XML', 'SOAP', 'CSV', 'FIXED_WIDTH', 'BINARY', 'NONE')),
  CONSTRAINT ck_adapter_operation_timeout CHECK (timeout_ms BETWEEN 100 AND 120000),
  CONSTRAINT ck_adapter_operation_side CHECK (side_effect IN ('NONE', 'READ', 'WRITE', 'EXTERNAL')),
  CONSTRAINT ck_adapter_operation_spec CHECK (jsonb_typeof(protocol_spec) = 'object'),
  CONSTRAINT ck_adapter_operation_samples CHECK (coalesce(octet_length(sample_request), 0) <= 1048576 AND coalesce(octet_length(sample_response), 0) <= 1048576)
);
CREATE TRIGGER tg_adapter_operation_touch BEFORE UPDATE ON ph05_adapter.adapter_operation FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.adapter_operation', 'P');
COMMENT ON TABLE ph05_adapter.adapter_operation IS 'EN-05-12 Thao tác của phiên bản bộ điều hợp (FR-05-036…041). Bất biến theo phiên bản cha: dịch vụ từ chối sửa khi phiên bản không ở DRAFT (ERR-05-017).';
COMMENT ON COLUMN ph05_adapter.adapter_operation.protocol_spec IS 'Tham số theo giao thức: REST {method, path, query, headers}; SOAP {wsdlOperation, soapAction}; SQL {statement, maxRows}; FILE {directory, includePattern, readyStrategy, recordMode}…';
COMMENT ON COLUMN ph05_adapter.adapter_operation.sample_response IS 'Bản tin mẫu đã che dữ liệu cá nhân (DH-MASK) trước khi lưu; dùng cho trình cấu hình và kiểm thử.';
COMMENT ON COLUMN ph05_adapter.adapter_operation.kamelet_name IS 'Tên Kamelet sinh {adapter}-{operation}-v{major}-{sink|source|action}, điền khi phiên bản được duyệt (FR-05-047).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.adapter_operation CASCADE;

-- @changeset ph05-0430-adapter-test
CREATE TABLE ph05_adapter.adapter_test (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  adapter_version_id uuid        NOT NULL,
  env              varchar(8)    NOT NULL,
  mode             varchar(8)    NOT NULL DEFAULT 'SINGLE',
  compare_with_version_id uuid,
  status           varchar(8)    NOT NULL DEFAULT 'RUNNING',
  results          jsonb         NOT NULL DEFAULT '[]',
  diff_summary     jsonb,
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  run_by           varchar(64)   NOT NULL,
  CONSTRAINT pk_adapter_test PRIMARY KEY (id),
  CONSTRAINT fk_adapter_test_version FOREIGN KEY (adapter_version_id, tenant_id) REFERENCES ph05_adapter.adapter_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_adapter_test_env CHECK (env IN ('TEST', 'STAGING')),
  CONSTRAINT ck_adapter_test_mode CHECK (mode IN ('SINGLE', 'COMPARE')),
  CONSTRAINT ck_adapter_test_compare CHECK ((mode = 'COMPARE') = (compare_with_version_id IS NOT NULL)),
  CONSTRAINT ck_adapter_test_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED')),
  CONSTRAINT ck_adapter_test_results CHECK (jsonb_typeof(results) = 'array')
);
CREATE INDEX ix_adapter_test_version ON ph05_adapter.adapter_test (tenant_id, adapter_version_id, started_at DESC);
CALL ph05_adapter.p_enable_rls('ph05_adapter.adapter_test', 'P');
COMMENT ON TABLE ph05_adapter.adapter_test IS 'EN-05-13 Kiểm thử bộ điều hợp và so sánh hai phiên bản (FR-05-045, 046). Không chạy ở PROD. results: mỗi thao tác {operation, status, latencyMs, outputPreview đã che, errors[]}. Giữ 90 ngày.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.adapter_test CASCADE;

-- @file 05-0050-cdc.sql
-- @changeset ph05-0500-cdc-config
CREATE TABLE ph05_adapter.cdc_config (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  adapter_id       uuid          NOT NULL,
  env              varchar(8)    NOT NULL,
  engine           varchar(10)   NOT NULL,
  tables           varchar(127)[] NOT NULL,
  column_excludes  varchar(255)[] NOT NULL DEFAULT '{}',
  column_hashes    varchar(255)[] NOT NULL DEFAULT '{}',
  snapshot_mode    varchar(16)   NOT NULL DEFAULT 'INITIAL',
  topic_prefix     varchar(200)  NOT NULL,
  connector_name   varchar(200)  NOT NULL,
  state            varchar(14)   NOT NULL DEFAULT 'STOPPED',
  state_reason     varchar(1000),
  last_position    varchar(255),
  position_at      timestamptz,
  lag_seconds      integer,
  snapshot_progress numeric(5,2),
  prereq_test_id   uuid,
  gitops_commit    char(40),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_cdc_config PRIMARY KEY (id),
  CONSTRAINT uq_cdc_config_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_cdc_config UNIQUE (tenant_id, adapter_id, env),
  CONSTRAINT uq_cdc_config_connector UNIQUE (connector_name),
  CONSTRAINT fk_cdc_config_adapter FOREIGN KEY (adapter_id, tenant_id) REFERENCES ph05_adapter.adapter (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_cdc_config_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_cdc_config_engine CHECK (engine IN ('POSTGRESQL', 'MYSQL', 'ORACLE', 'SQLSERVER')),
  CONSTRAINT ck_cdc_config_snapshot CHECK (snapshot_mode IN ('INITIAL', 'NO_DATA', 'WHEN_NEEDED')),
  CONSTRAINT ck_cdc_config_state CHECK (state IN ('STOPPED', 'SNAPSHOTTING', 'STREAMING', 'PAUSED', 'PAUSED_SCHEMA', 'FAILED')),
  CONSTRAINT ck_cdc_config_tables CHECK (cardinality(tables) BETWEEN 1 AND 500),
  CONSTRAINT ck_cdc_config_topic CHECK (topic_prefix ~ '^t[0-9]{2}\.cdc\.[a-z][a-z0-9-]{2,39}$'),
  CONSTRAINT ck_cdc_config_topic_tenant CHECK (split_part(topic_prefix, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_cdc_config_state ON ph05_adapter.cdc_config (tenant_id, state);
CREATE TRIGGER tg_cdc_config_touch BEFORE UPDATE ON ph05_adapter.cdc_config FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.cdc_config', 'P');
COMMENT ON TABLE ph05_adapter.cdc_config IS 'EN-05-14 Cấu hình CDC (FR-05-048…053, ADR-059). Trần số bảng theo 05.cdc.max-tables kiểm ở dịch vụ; CHECK 500 là trần cứng.';
COMMENT ON COLUMN ph05_adapter.cdc_config.last_position IS 'LSN (PostgreSQL), GTID (MySQL), SCN (Oracle), LSN (SQL Server) gần nhất KafkaConnectClient đọc được; offset thật ở topic nội bộ Kafka Connect.';
COMMENT ON COLUMN ph05_adapter.cdc_config.column_hashes IS 'Cột băm SHA-256 có muối theo tenant (muối ở OpenBao), ví dụ QLDD.CHU_SU_DUNG.DIEN_THOAI.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.cdc_config CASCADE;

-- @changeset ph05-0510-cdc-schema-change
CREATE TABLE ph05_adapter.cdc_schema_change (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  cdc_config_id    uuid          NOT NULL,
  table_name       varchar(127)  NOT NULL,
  change_kind      varchar(16)   NOT NULL,
  severity         varchar(10)   NOT NULL,
  ddl_text         text          NOT NULL,
  before_schema_id bigint,
  after_schema_id  bigint,
  source_position  varchar(255)  NOT NULL,
  detected_at      timestamptz   NOT NULL DEFAULT now(),
  status           varchar(10)   NOT NULL DEFAULT 'PENDING',
  resolution       varchar(16),
  resolution_detail jsonb,
  resolved_by      varchar(64),
  resolved_at      timestamptz,
  CONSTRAINT pk_cdc_schema_change PRIMARY KEY (id),
  CONSTRAINT fk_cdc_schema_change_cfg FOREIGN KEY (cdc_config_id, tenant_id) REFERENCES ph05_adapter.cdc_config (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_cdc_schema_change_kind CHECK (change_kind IN ('ADD_COLUMN', 'DROP_COLUMN', 'RENAME_COLUMN', 'ALTER_TYPE', 'ALTER_PK', 'DROP_TABLE', 'RENAME_TABLE', 'OTHER')),
  CONSTRAINT ck_cdc_schema_change_sev CHECK (severity IN ('COMPATIBLE', 'BREAKING')),
  CONSTRAINT ck_cdc_schema_change_status CHECK (status IN ('PENDING', 'RESOLVED', 'AUTO')),
  CONSTRAINT ck_cdc_schema_change_res CHECK (resolution IS NULL OR resolution IN ('ACCEPT', 'MAP_COLUMN', 'EXCLUDE_TABLE', 'RESNAPSHOT')),
  CONSTRAINT ck_cdc_schema_change_resolved CHECK ((status = 'RESOLVED') = (resolved_by IS NOT NULL AND resolution IS NOT NULL))
);
CREATE INDEX ix_cdc_schema_change_pending ON ph05_adapter.cdc_schema_change (tenant_id, cdc_config_id) WHERE status = 'PENDING';
CALL ph05_adapter.p_enable_rls('ph05_adapter.cdc_schema_change', 'P');
COMMENT ON TABLE ph05_adapter.cdc_schema_change IS 'EN-05-15 Thay đổi lược đồ CDC (FR-05-051). Giữ vĩnh viễn; chỉ cột status, resolution*, resolved_* được cập nhật (quyền cột ở tệp 05-0900-grants). COMPATIBLE ghi status AUTO.';
COMMENT ON COLUMN ph05_adapter.cdc_schema_change.ddl_text IS 'Câu DDL từ topic _schema-history của Debezium; không chứa dữ liệu nghiệp vụ.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.cdc_schema_change CASCADE;

-- @file 05-0060-kamelet.sql
-- @changeset ph05-0600-kamelet
CREATE TABLE ph05_adapter.kamelet (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  name             varchar(100)  NOT NULL,
  scope            varchar(8)    NOT NULL,
  type             varchar(8)    NOT NULL,
  group_code       varchar(32)   NOT NULL,
  title            varchar(255)  NOT NULL,
  owner            varchar(64)   NOT NULL,
  generated        boolean       NOT NULL DEFAULT false,
  source_adapter_id uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_kamelet PRIMARY KEY (id),
  CONSTRAINT uq_kamelet_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_kamelet_name UNIQUE (tenant_id, name),
  CONSTRAINT ck_kamelet_name CHECK (name ~ '^[a-z][a-z0-9-]{2,90}-(sink|source|action)$'),
  CONSTRAINT ck_kamelet_name_type CHECK (name LIKE '%-' || type),
  CONSTRAINT ck_kamelet_scope CHECK (scope IN ('BASE', 'COMMON', 'TENANT')),
  CONSTRAINT ck_kamelet_type CHECK (type IN ('source', 'sink', 'action')),
  CONSTRAINT ck_kamelet_scope_tenant CHECK ((scope IN ('BASE', 'COMMON')) = (tenant_id = 'COMMON')),
  CONSTRAINT ck_kamelet_base_prefix CHECK (scope <> 'BASE' OR name LIKE 'dh-%'),
  CONSTRAINT ck_kamelet_reserved_prefix CHECK (scope = 'BASE' OR name NOT LIKE 'dh-%'),
  CONSTRAINT ck_kamelet_generated CHECK (NOT generated OR (scope = 'TENANT' AND source_adapter_id IS NOT NULL))
);
CREATE TRIGGER tg_kamelet_touch BEFORE UPDATE ON ph05_adapter.kamelet FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.kamelet', 'S');
COMMENT ON TABLE ph05_adapter.kamelet IS 'EN-05-16 Kamelet (FR-05-054…060). BASE và COMMON nằm ở tenant COMMON, đọc được từ mọi tỉnh (RLS mẫu S); tỉnh chỉ ghi TENANT. Tên duy nhất trên BASE ∪ COMMON ∪ TENANT kiểm ở dịch vụ (KR-02) vì khác tenant_id.';
COMMENT ON COLUMN ph05_adapter.kamelet.generated IS 'true: sinh từ phiên bản bộ điều hợp đã duyệt, không qua bước duyệt riêng (BR-05-027).';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.kamelet CASCADE;

-- @changeset ph05-0610-kamelet-version
CREATE TABLE ph05_adapter.kamelet_version (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kamelet_id       uuid          NOT NULL,
  semver           varchar(20)   NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'DRAFT',
  yaml             text          NOT NULL,
  yaml_hash        char(64)      NOT NULL,
  parameters       jsonb         NOT NULL DEFAULT '[]',
  runtime_profiles varchar(16)[] NOT NULL,
  static_check     jsonb,
  static_check_passed boolean    NOT NULL DEFAULT false,
  source_adapter_version_id uuid,
  origin           varchar(10)   NOT NULL DEFAULT 'EDITOR',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  approved_by      varchar(64),
  approved_at      timestamptz,
  so_opinion_by    varchar(64),
  so_opinion       varchar(2000),
  reject_reason    varchar(2000),
  status_reason    varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_kamelet_version PRIMARY KEY (id),
  CONSTRAINT uq_kamelet_version UNIQUE (tenant_id, kamelet_id, semver),
  CONSTRAINT uq_kamelet_version_hash UNIQUE (tenant_id, yaml_hash),
  CONSTRAINT fk_kamelet_version_kamelet FOREIGN KEY (kamelet_id, tenant_id) REFERENCES ph05_adapter.kamelet (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_kamelet_version_semver CHECK (semver ~ '^(0|[1-9][0-9]{0,3})\.(0|[1-9][0-9]{0,3})\.(0|[1-9][0-9]{0,4})$'),
  CONSTRAINT ck_kamelet_version_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'DEPRECATED', 'WITHDRAWN')),
  CONSTRAINT ck_kamelet_version_size CHECK (octet_length(yaml) <= 262144),
  CONSTRAINT ck_kamelet_version_origin CHECK (origin IN ('EDITOR', 'DESIGNER', 'GENERATED', 'PLATFORM')),
  CONSTRAINT ck_kamelet_version_profiles CHECK (cardinality(runtime_profiles) >= 1
      AND runtime_profiles <@ ARRAY['core-native', 'files-native', 'soap-jvm', 'legacy-jvm', 'probe-jvm']::varchar(16)[]),
  CONSTRAINT ck_kamelet_version_submit CHECK (status = 'DRAFT' OR static_check_passed),
  CONSTRAINT ck_kamelet_version_four_eyes CHECK (approved_by IS NULL OR approved_by IS DISTINCT FROM submitted_by)
);
CREATE INDEX ix_kamelet_version_status ON ph05_adapter.kamelet_version (tenant_id, status);
CREATE TRIGGER tg_kamelet_version_touch BEFORE UPDATE ON ph05_adapter.kamelet_version FOR EACH ROW EXECUTE FUNCTION ph05_adapter.tg_touch();
CALL ph05_adapter.p_enable_rls('ph05_adapter.kamelet_version', 'S');
COMMENT ON TABLE ph05_adapter.kamelet_version IS 'EN-05-17 Phiên bản Kamelet (FR-05-055…058). YAML bất biến sau SUBMITTED (dịch vụ), băm duy nhất theo tenant để runtime tải theo băm (§5.5 SDD).';
COMMENT ON COLUMN ph05_adapter.kamelet_version.origin IS 'EDITOR soạn ở UI-05-16; DESIGNER phát hành từ trình thiết kế PH-04 đã được IA duyệt (không duyệt lại, BR-05-027); GENERATED sinh từ bộ điều hợp; PLATFORM Kamelet nền đóng cùng ảnh runtime.';
COMMENT ON COLUMN ph05_adapter.kamelet_version.static_check IS 'Kết quả KR-01…14 (SDD §4.9): [{rule, level, message, line}].';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.kamelet_version CASCADE;

-- @file 05-0070-misc.sql
-- @changeset ph05-0700-usage-ref
CREATE TABLE ph05_adapter.usage_ref (
  tenant_id        varchar(16)   NOT NULL,
  object_kind      varchar(10)   NOT NULL,
  object_code      varchar(100)  NOT NULL,
  flow_code        varchar(63)   NOT NULL,
  flow_version     integer       NOT NULL,
  env              varchar(8),
  keys_used        varchar(64)[] NOT NULL DEFAULT '{}',
  deployed         boolean       NOT NULL DEFAULT false,
  refreshed_at     timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_usage_ref PRIMARY KEY (tenant_id, object_kind, object_code, flow_code, flow_version),
  CONSTRAINT ck_usage_ref_kind CHECK (object_kind IN ('CONNECTION', 'ADAPTER', 'KAMELET'))
);
CREATE INDEX ix_usage_ref_flow ON ph05_adapter.usage_ref (tenant_id, flow_code);
CALL ph05_adapter.p_enable_rls('ph05_adapter.usage_ref', 'P');
COMMENT ON TABLE ph05_adapter.usage_ref IS 'Chỉ mục nơi dùng (FR-05-013): dựng từ API-05-031 (xác minh của PH-04) và sự kiện triển khai, phục vụ chặn ngừng dùng (ERR-05-010) và UI "Nơi dùng". Tính lại được hoàn toàn.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.usage_ref CASCADE;

-- @changeset ph05-0710-legacy-import-job
CREATE TABLE ph05_adapter.legacy_import_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  file_name        varchar(255)  NOT NULL,
  file_hash        char(64)      NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'SCANNING',
  findings         jsonb         NOT NULL DEFAULT '[]',
  proposals        jsonb         NOT NULL DEFAULT '[]',
  created_connections varchar(63)[] NOT NULL DEFAULT '{}',
  error_message    varchar(2000),
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  run_by           varchar(64)   NOT NULL,
  CONSTRAINT pk_legacy_import_job PRIMARY KEY (id),
  CONSTRAINT ck_legacy_import_job_status CHECK (status IN ('SCANNING', 'REVIEW', 'APPLIED', 'FAILED', 'CANCELLED'))
);
CREATE INDEX ix_legacy_import_job_tenant ON ph05_adapter.legacy_import_job (tenant_id, started_at DESC);
CALL ph05_adapter.p_enable_rls('ph05_adapter.legacy_import_job', 'P');
COMMENT ON TABLE ph05_adapter.legacy_import_job IS 'EN-05-18 Nhập kết nối hệ cũ (FR-05-016). Tệp gốc không lưu; findings giữ vị trí {file, line, column, key} thay cho giá trị bí mật (BR-05-025). Giữ 1 năm.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.legacy_import_job CASCADE;

-- @changeset ph05-0720-outbox
CREATE TABLE ph05_adapter.outbox (
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
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.adapter\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^(t[0-9]{2}|common)\.(adapter|audit)\.[a-z-]+(\.[a-z-]+)?\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey']))
);
CREATE INDEX ix_outbox_occurred ON ph05_adapter.outbox (occurred_at);
ALTER TABLE ph05_adapter.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph05_adapter.p_enable_rls('ph05_adapter.outbox', 'P');
COMMENT ON TABLE ph05_adapter.outbox IS 'Outbox (DD-11) cho EVT-05-01…12, 15 và kiểm toán gửi PH-13. Dòng tenant COMMON (phiên PLATFORM) cho EVT-05-09, 10 của Kamelet dùng chung, topic common.adapter.*. Dọn sau 3 ngày. EVT-05-13 do Kafka Connect, EVT-05-14 do runtime phát trực tiếp.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.outbox CASCADE;

-- @changeset ph05-0730-shedlock
CREATE TABLE ph05_adapter.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph05_adapter.shedlock IS 'Khóa tác vụ nền (HealthEvaluator, RotationFinisher, SecretDestroyJob, FlowAccountExpiryJob, PartitionMaintenanceJob); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph05_adapter.shedlock;

-- @file 05-0800-seed.sql
-- @changeset ph05-0800-seed-base-kamelets
INSERT INTO ph05_adapter.kamelet (id, tenant_id, name, scope, type, group_code, title, owner, created_by, updated_by)
SELECT md5('dh-kamelet:' || k.name)::uuid, 'COMMON', k.name, 'BASE', k.type, k.grp, k.title, 'platform', 'system:seed', 'system:seed'
FROM (VALUES
  ('dh-http-sink', 'sink', 'http', 'Gọi REST, HTTP'),
  ('dh-http-source', 'source', 'http', 'Nhận webhook'),
  ('dh-soap-sink', 'sink', 'soap', 'Gọi dịch vụ SOAP'),
  ('dh-sql-ro-source', 'source', 'sql', 'Đọc CSDL theo lịch'),
  ('dh-sql-ro-action', 'action', 'sql', 'Truy vấn CSDL chỉ đọc'),
  ('dh-sql-write-sink', 'sink', 'sql', 'Ghi CSDL có kiểm soát'),
  ('dh-sftp-source', 'source', 'file', 'Đọc tệp SFTP'),
  ('dh-sftp-sink', 'sink', 'file', 'Ghi tệp SFTP'),
  ('dh-ftps-source', 'source', 'file', 'Đọc tệp FTPS'),
  ('dh-ftps-sink', 'sink', 'file', 'Ghi tệp FTPS'),
  ('dh-smb-source', 'source', 'file', 'Đọc thư mục chia sẻ SMB'),
  ('dh-smb-sink', 'sink', 'file', 'Ghi thư mục chia sẻ SMB'),
  ('dh-jms-source', 'source', 'messaging', 'Nhận hàng đợi JMS'),
  ('dh-jms-sink', 'sink', 'messaging', 'Gửi hàng đợi JMS'),
  ('dh-amqp-source', 'source', 'messaging', 'Nhận AMQP'),
  ('dh-amqp-sink', 'sink', 'messaging', 'Gửi AMQP'),
  ('dh-mqtt-source', 'source', 'messaging', 'Nhận MQTT'),
  ('dh-mqtt-sink', 'sink', 'messaging', 'Gửi MQTT'),
  ('dh-kafka-ext-source', 'source', 'messaging', 'Nhận Kafka ngoài'),
  ('dh-kafka-ext-sink', 'sink', 'messaging', 'Gửi Kafka ngoài'),
  ('dh-mail-sink', 'sink', 'mail', 'Gửi thư'),
  ('dh-imap-source', 'source', 'mail', 'Nhận thư IMAP'),
  ('dh-ldap-action', 'action', 'directory', 'Tra cứu LDAP')
) AS k(name, type, grp, title)
ON CONFLICT (tenant_id, name) DO UPDATE SET title = EXCLUDED.title, group_code = EXCLUDED.group_code, updated_by = 'system:seed';
-- @rollback DELETE FROM ph05_adapter.kamelet WHERE tenant_id = 'COMMON' AND scope = 'BASE';

-- @file 05-0900-grants.sql
-- @changeset ph05-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph05_adapter TO ph05_app;
REVOKE UPDATE, DELETE ON ph05_adapter.db_access_record FROM ph05_app;   -- chỉ thêm
REVOKE UPDATE ON ph05_adapter.outbox FROM ph05_app;                     -- chỉ thêm, xóa khi dọn
REVOKE UPDATE, DELETE ON ph05_adapter.cdc_schema_change FROM ph05_app;
GRANT UPDATE (status, resolution, resolution_detail, resolved_by, resolved_at) ON ph05_adapter.cdc_schema_change TO ph05_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph05_adapter TO ph05_readonly;
REVOKE SELECT ON ph05_adapter.adapter_operation, ph05_adapter.kamelet_version FROM ph05_readonly;
GRANT SELECT (id, tenant_id, adapter_version_id, code, title, direction, request_format, response_format, timeout_ms, side_effect, kamelet_name)
  ON ph05_adapter.adapter_operation TO ph05_readonly;                     -- không đọc bản tin mẫu
GRANT SELECT (id, tenant_id, kamelet_id, semver, status, yaml_hash, runtime_profiles, origin, approved_by, approved_at)
  ON ph05_adapter.kamelet_version TO ph05_readonly;
GRANT EXECUTE ON PROCEDURE ph05_adapter.p_ensure_month_partitions(regclass, date, integer) TO ph05_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;

-- @file 05-9000-migrate-w1.sql
-- @changeset ph05-9000-migrate-w1 context:migrate-w1 splitStatements:false
-- Chuyển bảng ph05.adapter (apps/adapter-mgr, W1) sang kết nối nháp của tenant mặc định.
-- Mỗi dòng cũ thành một connection DRAFT loại http-rest; vault_path cũ không dùng
-- (đường dẫn mới suy từ mã); người dùng khai lại bí mật và kiểm tra trước khi bật.
DO $mig$
DECLARE
  v_tenant text := coalesce(current_setting('app.migrate_tenant', true), 'T01');
BEGIN
  IF to_regclass('ph05.adapter') IS NULL THEN
    RAISE NOTICE 'Không có bảng ph05.adapter W1, bỏ qua';
    RETURN;
  END IF;
  PERFORM set_config('app.tenant_id', v_tenant, true);
  INSERT INTO ph05_adapter.connection (id, tenant_id, code, name, type_code, system_code, purpose, description, owner, legacy_ref, created_by, updated_by)
  SELECT md5('w1:' || a.id)::uuid, v_tenant,
         left(regexp_replace(lower(a.id), '[^a-z0-9-]', '-', 'g'), 63),
         a.name, 'http-rest', 'CHUA-GAN', 'READ',
         'Chuyển từ ph05.adapter W1 (type=' || a.type || ')', 'system:migrate', 'w1:ph05.adapter/' || a.id,
         'system:migrate', 'system:migrate'
    FROM ph05.adapter a
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph05_adapter.connection_environment (id, tenant_id, connection_id, env, params, params_hash, created_by, updated_by)
  SELECT md5('w1env:' || a.id)::uuid, v_tenant, md5('w1:' || a.id)::uuid, 'TEST',
         jsonb_build_object('baseUrl', a.endpoint_url), encode(sha256(convert_to(jsonb_build_object('baseUrl', a.endpoint_url)::text, 'UTF8')), 'hex'),
         'system:migrate', 'system:migrate'
    FROM ph05.adapter a
  ON CONFLICT (tenant_id, connection_id, env) DO NOTHING;
  EXECUTE 'ALTER TABLE ph05.adapter RENAME TO adapter_legacy_w1';
END
$mig$;
-- @rollback ALTER TABLE IF EXISTS ph05.adapter_legacy_w1 RENAME TO adapter;
