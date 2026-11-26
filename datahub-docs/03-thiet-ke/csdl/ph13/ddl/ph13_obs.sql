-- =============================================================================
-- D03-03-PH13 · DDL schema ph13_obs — PH-13 Giám sát và kiểm toán (nhóm quan sát)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph13_obs.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback.
--
-- Schema này chỉ giữ siêu dữ liệu cấu hình và vòng đời cảnh báo; KHÔNG giữ số liệu quan sát
-- (chỉ số ở Mimir, log ở Loki, vết ở Tempo, lượt gọi API ở ClickHouse) và KHÔNG giữ bí mật
-- (khóa kênh thông báo chỉ là đường dẫn OpenBao). Chủ duy nhất: module observability của dh-platform.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 13-1000-bootstrap.sql
-- @changeset ph13-1000-roles splitStatements:false context:bootstrap
DO $roles$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['ph13_owner', 'ph13_obs_app', 'ph13_readonly'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS %s', r,
                     CASE WHEN r = 'ph13_owner' THEN 'NOINHERIT' ELSE '' END);
    END IF;
  END LOOP;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph13-1001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph13_obs AUTHORIZATION ph13_owner;
COMMENT ON SCHEMA ph13_obs IS 'PH-13 nhóm quan sát: luật và runbook cảnh báo, cảnh báo và thao tác xử lý, lịch trực, kênh thông báo, luật phát hiện và cảnh báo an ninh, mục tiêu SIEM, bộ dashboard, truy vấn đã lưu, kiểm tra tổng hợp, cấu hình quan sát của tenant. Không giữ số liệu quan sát, không giữ bí mật. dh-platform kết nối bằng ph13_obs_app.';
GRANT USAGE ON SCHEMA ph13_obs TO ph13_obs_app, ph13_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph13_obs CASCADE;

SET ROLE ph13_owner;

-- @changeset ph13-1002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 13-1001-functions.sql
-- @changeset ph13-1010-fn-generic splitStatements:false
CREATE OR REPLACE FUNCTION ph13_obs.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';

CREATE OR REPLACE PROCEDURE ph13_obs.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := $r$(tenant_id = current_setting('app.tenant_id', false))$r$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, r, r);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, r);
END
$p$;
COMMENT ON PROCEDURE ph13_obs.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách mẫu P: tenant_id = app.tenant_id (D03-10). Chưa đặt biến phiên thì lỗi, đóng an toàn.';

CREATE OR REPLACE FUNCTION ph13_obs.tg_forbid_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % không cho xóa dòng (đổi trạng thái, mã không dùng lại, BR-13-031)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_forbid_delete() IS 'Chặn DELETE; mã bất biến và không dùng lại (BR-13-031).';

CREATE OR REPLACE FUNCTION ph13_obs.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_append_only() IS 'Chặn UPDATE trên bảng chỉ thêm (alert_action).';

CREATE OR REPLACE FUNCTION ph13_obs.tg_guard_retention() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE ts timestamptz := (to_jsonb(OLD) ->> TG_ARGV[0])::timestamptz;
BEGIN
  IF ts IS NULL OR ts > now() - TG_ARGV[1]::interval THEN
    RAISE EXCEPTION 'Bảng %: chỉ xóa dòng quá hạn lưu % (cột %)', TG_TABLE_NAME, TG_ARGV[1], TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN OLD;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_guard_retention() IS 'Chỉ cho xóa dòng quá hạn lưu (FRS §8.2).';

CREATE OR REPLACE FUNCTION ph13_obs.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE i int;
BEGIN
  FOR i IN 0 .. TG_NARGS - 1 LOOP
    IF to_jsonb(NEW) -> TG_ARGV[i] IS DISTINCT FROM to_jsonb(OLD) -> TG_ARGV[i] THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, TG_ARGV[i] USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_immutable() IS 'Chặn sửa các cột bất biến (đối số trigger).';

-- Luật, runbook phạm vi PLATFORM do StandardRuleCatalog nạp từ Git (SDD §4.16): chỉ giao dịch đặt app.rule_catalog = 'on' mới ghi được.
CREATE OR REPLACE FUNCTION ph13_obs.tg_platform_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF (TG_OP = 'INSERT' AND NEW.scope = 'PLATFORM') OR (TG_OP = 'UPDATE' AND (OLD.scope = 'PLATFORM' OR NEW.scope = 'PLATFORM')) THEN
    IF coalesce(current_setting('app.rule_catalog', true), '') <> 'on' THEN
      RAISE EXCEPTION 'Mục chuẩn nền tảng (scope=PLATFORM) của % không sửa, không tắt bởi tenant (ERR-13-019, BR-13-032)', TG_TABLE_NAME USING ERRCODE = '55000';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_platform_guard() IS 'Chặn ghi mục scope=PLATFORM trừ giao dịch của StandardRuleCatalog (app.rule_catalog = on).';
-- @rollback DROP FUNCTION IF EXISTS ph13_obs.tg_touch(), ph13_obs.tg_forbid_delete(), ph13_obs.tg_append_only(), ph13_obs.tg_guard_retention(), ph13_obs.tg_immutable(), ph13_obs.tg_platform_guard(); DROP PROCEDURE IF EXISTS ph13_obs.p_enable_rls(regclass);

-- @changeset ph13-1011-fn-params splitStatements:false
-- Miền hợp lệ của tham số 13.* (FRS §8.3). Khóa lạ hoặc giá trị ngoài miền làm CHECK thất bại (ERR-13-040).
CREATE OR REPLACE FUNCTION ph13_obs.fn_params_valid(p jsonb) RETURNS boolean
  LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  k text; v jsonb; lim record; ok boolean := true;
BEGIN
  IF jsonb_typeof(p) <> 'object' THEN RETURN false; END IF;
  FOR k, v IN SELECT * FROM jsonb_each(p) LOOP
    IF k IN ('13.alert.escalate-minutes', '13.office-hours', '13.audit.verify-cron') THEN
      IF jsonb_typeof(v) <> 'string' THEN RETURN false; END IF;
      IF k = '13.alert.escalate-minutes' AND (v #>> '{}') !~ '^[0-9]{1,2}(,[0-9]{1,2})?$' THEN RETURN false; END IF;
      CONTINUE;
    END IF;
    SELECT * INTO lim FROM (VALUES
      ('13.metrics.scrape-interval-seconds', 10, 60), ('13.trace.decision-wait-seconds', 10, 120),
      ('13.trace.success-sample-percent', 1, 100), ('13.trace.slow-percentile', 90, 99.9),
      ('13.series.max-active', 50000, 2000000), ('13.alert.eval-interval-seconds', 30, 300),
      ('13.alert.max-rules', 50, 2000), ('13.alert.silence-max-days', 1, 14),
      ('13.slo.data-plane-availability', 99.0, 99.99), ('13.slo.gateway-latency-p95-ms', 20, 200),
      ('13.probe.interval-seconds', 30, 300), ('13.audit.anchor-interval-minutes', 15, 240),
      ('13.audit.worm-batch-minutes', 1, 30), ('13.audit.worm-retention-years', 3, 10),
      ('13.audit.online-months', 12, 24), ('13.audit.query-max-records', 10000, 1000000),
      ('13.audit.export-max-records', 100000, 10000000), ('13.query.max-concurrent-per-user', 1, 10),
      ('13.query.timeout-seconds', 10, 120), ('13.live-tail.idle-minutes', 5, 60),
      ('13.export.link-ttl-minutes', 5, 60), ('13.siem.queue-max-mb', 256, 8192)
    ) AS t(key, lo, hi) WHERE t.key = k;
    IF NOT FOUND THEN RETURN false; END IF;
    IF jsonb_typeof(v) <> 'number' THEN RETURN false; END IF;
    IF (v #>> '{}')::numeric < lim.lo OR (v #>> '{}')::numeric > lim.hi THEN RETURN false; END IF;
  END LOOP;
  RETURN ok;
END
$f$;
COMMENT ON FUNCTION ph13_obs.fn_params_valid(jsonb) IS 'Kiểm khóa và miền của tham số 13.* theo FRS §8.3 (ví dụ 13.audit.worm-retention-years 3..10, BR-13-020).';

-- Ngưỡng luật phát hiện: threshold_limit = {"khóa": {"dir": "MAX"|"MIN", "bound": số}}.
CREATE OR REPLACE FUNCTION ph13_obs.fn_threshold_ok(thr jsonb, lim jsonb) RETURNS boolean
  LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE k text; s jsonb; v jsonb; b numeric;
BEGIN
  IF jsonb_typeof(thr) <> 'object' OR jsonb_typeof(lim) <> 'object' THEN RETURN false; END IF;
  FOR k, s IN SELECT * FROM jsonb_each(lim) LOOP
    v := thr -> k;
    IF v IS NULL OR jsonb_typeof(v) <> 'number' OR jsonb_typeof(s -> 'bound') <> 'number' THEN RETURN false; END IF;
    b := (s ->> 'bound')::numeric;
    IF s ->> 'dir' = 'MAX' AND (v #>> '{}')::numeric > b THEN RETURN false; END IF;
    IF s ->> 'dir' = 'MIN' AND (v #>> '{}')::numeric < b THEN RETURN false; END IF;
    IF s ->> 'dir' NOT IN ('MAX', 'MIN') THEN RETURN false; END IF;
  END LOOP;
  RETURN true;
END
$f$;
COMMENT ON FUNCTION ph13_obs.fn_threshold_ok(jsonb, jsonb) IS 'Ngưỡng hiện hành nằm trong biên cho phép (BR-13-025).';

CREATE OR REPLACE FUNCTION ph13_obs.fn_limit_ok(def jsonb, lim jsonb) RETURNS boolean
  LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE k text; s jsonb; d numeric; b numeric;
BEGIN
  IF jsonb_typeof(def) <> 'object' OR jsonb_typeof(lim) <> 'object' THEN RETURN false; END IF;
  FOR k, s IN SELECT * FROM jsonb_each(lim) LOOP
    IF def -> k IS NULL OR jsonb_typeof(def -> k) <> 'number' OR jsonb_typeof(s -> 'bound') <> 'number' THEN RETURN false; END IF;
    d := (def ->> k)::numeric; b := (s ->> 'bound')::numeric;
    IF s ->> 'dir' = 'MAX' AND NOT (b >= d AND b <= 2 * d) THEN RETURN false; END IF;
    IF s ->> 'dir' = 'MIN' AND NOT (b <= d AND b >= d / 2) THEN RETURN false; END IF;
    IF s ->> 'dir' NOT IN ('MAX', 'MIN') THEN RETURN false; END IF;
  END LOOP;
  RETURN true;
END
$f$;
COMMENT ON FUNCTION ph13_obs.fn_limit_ok(jsonb, jsonb) IS 'Biên chỉ được nới tối đa 2 lần ngưỡng mặc định (BR-13-025); siết tự do.';
-- @rollback DROP FUNCTION IF EXISTS ph13_obs.fn_params_valid(jsonb), ph13_obs.fn_threshold_ok(jsonb, jsonb), ph13_obs.fn_limit_ok(jsonb, jsonb);

-- @file 13-1010-config.sql
-- @changeset ph13-1100-tenant-obs-config splitStatements:false
CREATE TABLE ph13_obs.tenant_obs_config (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  scale            varchar(10)   NOT NULL DEFAULT 'QM-VUA',
  params           jsonb         NOT NULL DEFAULT '{}',
  quota            jsonb         NOT NULL DEFAULT '{}',
  provision_key    varchar(64),
  provision_hash   char(64),
  provision_state  jsonb         NOT NULL DEFAULT '{}',
  provisioned_at   timestamptz,
  grafana_org_id   bigint,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_obs_config PRIMARY KEY (id),
  CONSTRAINT uq_tenant_obs_config_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_obs_config_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_tenant_obs_config_scale CHECK (scale IN ('QM-NHO', 'QM-VUA', 'QM-LON', 'QM-CHUNG')),
  CONSTRAINT ck_tenant_obs_config_params CHECK (ph13_obs.fn_params_valid(params)),
  CONSTRAINT ck_tenant_obs_config_quota CHECK (jsonb_typeof(quota) = 'object'),
  CONSTRAINT ck_tenant_obs_config_state CHECK (jsonb_typeof(provision_state) = 'object' AND (provision_state - 'S1' - 'S2' - 'S3' - 'S4' - 'S5' - 'S6') = '{}'::jsonb),
  CONSTRAINT ck_tenant_obs_config_hash CHECK (provision_hash IS NULL OR provision_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_tenant_obs_config_provisioned CHECK (provisioned_at IS NULL OR (provision_key IS NOT NULL AND provision_state ?& ARRAY['S1', 'S2', 'S3', 'S4', 'S5', 'S6']))
);
CREATE TRIGGER tg_tenant_obs_config_touch BEFORE UPDATE ON ph13_obs.tenant_obs_config FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_tenant_obs_config_imm BEFORE UPDATE ON ph13_obs.tenant_obs_config FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'created_at');
CREATE TRIGGER tg_tenant_obs_config_nodel BEFORE DELETE ON ph13_obs.tenant_obs_config FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.tenant_obs_config');
COMMENT ON TABLE ph13_obs.tenant_obs_config IS 'EN-13-19 Cấu hình quan sát của tenant: tham số 13.*, hạn mức, sổ bước khởi tạo S1…S6 (FR-13-059, 061). Nguồn sự thật của OverridesReconciler; tham số kiểm miền ở CHECK (ERR-13-040).';
COMMENT ON COLUMN ph13_obs.tenant_obs_config.params IS 'Chỉ khóa 13.* theo FRS §8.3, giá trị trong miền; vắng khóa thì dùng mặc định của nền tảng.';
COMMENT ON COLUMN ph13_obs.tenant_obs_config.quota IS 'Hạn mức theo scale (số chuỗi, tốc độ nhận log, trace); không vượt trần của PA (ERR-13-041, kiểm ở dịch vụ).';
COMMENT ON COLUMN ph13_obs.tenant_obs_config.provision_state IS 'Sổ bước {"S1":{"status":"DONE","at":"…"},…}; gọi lại cùng provision_key chạy tiếp từ bước dở, khác provision_hash trả ERR-13-042.';
COMMENT ON COLUMN ph13_obs.tenant_obs_config.provisioned_at IS 'Đặt khi đủ S1…S6; null thì tenant chưa khởi tạo xong.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.tenant_obs_config CASCADE;

-- @file 13-1020-rules.sql
-- @changeset ph13-1200-runbook splitStatements:false
CREATE TABLE ph13_obs.runbook (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  runbook_code     varchar(64)   NOT NULL,
  title            varchar(255)  NOT NULL,
  scope            varchar(8)    NOT NULL DEFAULT 'TENANT',
  meaning          text          NOT NULL,
  first_checks     text          NOT NULL,
  common_causes    text          NOT NULL,
  remediation      text          NOT NULL,
  escalation_when  text          NOT NULL,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  source_revision  varchar(64),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_runbook PRIMARY KEY (id),
  CONSTRAINT uq_runbook_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_runbook_code UNIQUE (tenant_id, runbook_code),
  CONSTRAINT ck_runbook_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_runbook_code CHECK (runbook_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_runbook_scope CHECK (scope IN ('PLATFORM', 'TENANT')),
  -- BR-13-008: đủ năm mục, không rỗng.
  CONSTRAINT ck_runbook_five_sections CHECK (
    char_length(btrim(meaning)) BETWEEN 1 AND 4000 AND char_length(btrim(first_checks)) BETWEEN 1 AND 4000
    AND char_length(btrim(common_causes)) BETWEEN 1 AND 4000 AND char_length(btrim(remediation)) BETWEEN 1 AND 4000
    AND char_length(btrim(escalation_when)) BETWEEN 1 AND 4000),
  CONSTRAINT ck_runbook_status CHECK (status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_runbook_platform_source CHECK (scope <> 'PLATFORM' OR source_revision IS NOT NULL)
);
CREATE TRIGGER tg_runbook_touch BEFORE UPDATE ON ph13_obs.runbook FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_runbook_platform BEFORE INSERT OR UPDATE ON ph13_obs.runbook FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_platform_guard();
CREATE TRIGGER tg_runbook_imm BEFORE UPDATE ON ph13_obs.runbook FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'runbook_code', 'scope', 'created_at');
CREATE TRIGGER tg_runbook_nodel BEFORE DELETE ON ph13_obs.runbook FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.runbook');
COMMENT ON TABLE ph13_obs.runbook IS 'EN-13-08 Runbook năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên (FR-13-042, 043; BR-13-008). Xóa mềm (RETIRED), mã không dùng lại. Runbook scope=PLATFORM nhân bản từ Git cho từng tenant.';
COMMENT ON COLUMN ph13_obs.runbook.scope IS 'PLATFORM: runbook chuẩn nạp bởi StandardRuleCatalog, tenant không sửa; TENANT: do tenant tạo.';
COMMENT ON COLUMN ph13_obs.runbook.source_revision IS 'Mã commit của kho cấu hình Git cho runbook chuẩn (bắt buộc khi scope=PLATFORM).';
-- @rollback DROP TABLE IF EXISTS ph13_obs.runbook CASCADE;

-- @changeset ph13-1210-alert-rule splitStatements:false
CREATE TABLE ph13_obs.alert_rule (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  rule_code          varchar(64)   NOT NULL,
  name               varchar(255)  NOT NULL,
  description        varchar(2000),
  scope              varchar(8)    NOT NULL DEFAULT 'TENANT',
  expr               text          NOT NULL,
  expr_language      varchar(7)    NOT NULL DEFAULT 'PROMQL',
  for_seconds        integer       NOT NULL DEFAULT 300,
  eval_interval_seconds integer,
  severity           varchar(8)    NOT NULL,
  symptom            varchar(1000),
  resource_only      boolean       NOT NULL DEFAULT false,
  runbook_id         uuid          NOT NULL,
  notify_group       varchar(64),
  group_key_labels   varchar(32)[] NOT NULL DEFAULT '{}',
  status             varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  owner              varchar(64)   NOT NULL,
  source_revision    varchar(64),
  expr_hash          char(64)      NOT NULL,
  retired_at         timestamptz,
  retired_reason     varchar(500),
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_alert_rule PRIMARY KEY (id),
  CONSTRAINT uq_alert_rule_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_alert_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT fk_alert_rule_runbook FOREIGN KEY (runbook_id, tenant_id) REFERENCES ph13_obs.runbook (id, tenant_id),
  CONSTRAINT ck_alert_rule_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_alert_rule_code CHECK (rule_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_alert_rule_scope CHECK (scope IN ('PLATFORM', 'TENANT')),
  CONSTRAINT ck_alert_rule_expr CHECK (char_length(btrim(expr)) BETWEEN 1 AND 8000),
  CONSTRAINT ck_alert_rule_lang CHECK (expr_language IN ('PROMQL', 'LOGQL')),
  CONSTRAINT ck_alert_rule_for CHECK (for_seconds BETWEEN 0 AND 86400),
  CONSTRAINT ck_alert_rule_eval CHECK (eval_interval_seconds IS NULL OR eval_interval_seconds BETWEEN 30 AND 300),
  CONSTRAINT ck_alert_rule_severity CHECK (severity IN ('CRITICAL', 'WARNING', 'INFO')),
  -- BR-13-009: Nghiêm trọng phải có mô tả triệu chứng, và không dựa thuần vào tài nguyên.
  CONSTRAINT ck_alert_rule_critical_symptom CHECK (severity <> 'CRITICAL' OR char_length(btrim(coalesce(symptom, ''))) >= 1),
  CONSTRAINT ck_alert_rule_resource_only CHECK (NOT (resource_only AND severity = 'CRITICAL')),
  CONSTRAINT ck_alert_rule_status CHECK (status IN ('ACTIVE', 'DISABLED', 'RETIRED')),
  CONSTRAINT ck_alert_rule_group_labels CHECK (cardinality(group_key_labels) <= 6 AND NOT (group_key_labels && ARRAY['trace_id', 'user_id', 'client_ip', 'request_id']::varchar[])),
  CONSTRAINT ck_alert_rule_hash CHECK (expr_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_alert_rule_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL AND retired_reason IS NOT NULL)),
  CONSTRAINT ck_alert_rule_platform_source CHECK (scope <> 'PLATFORM' OR source_revision IS NOT NULL)
);
CREATE INDEX ix_alert_rule_status ON ph13_obs.alert_rule (tenant_id, status, severity);
CREATE INDEX ix_alert_rule_runbook ON ph13_obs.alert_rule (tenant_id, runbook_id);
CREATE OR REPLACE FUNCTION ph13_obs.tg_alert_rule_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE mx integer; n integer;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.scope = 'TENANT' THEN
      SELECT coalesce((SELECT (params ->> '13.alert.max-rules')::integer FROM ph13_obs.tenant_obs_config WHERE tenant_id = NEW.tenant_id), 500) INTO mx;
      SELECT count(*) INTO n FROM ph13_obs.alert_rule WHERE tenant_id = NEW.tenant_id AND scope = 'TENANT' AND status <> 'RETIRED';
      IF n >= mx THEN RAISE EXCEPTION 'Tenant % đã có % luật riêng, tối đa % (ERR-13-041)', NEW.tenant_id, n, mx USING ERRCODE = '23514'; END IF;
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.status = 'RETIRED' THEN
    RAISE EXCEPTION 'Luật % đã ngừng dùng, không sửa (mã không dùng lại, BR-13-031)', OLD.rule_code USING ERRCODE = '55000';
  END IF;
  IF NEW.status <> OLD.status AND NOT ((OLD.status = 'ACTIVE' AND NEW.status IN ('DISABLED', 'RETIRED')) OR (OLD.status = 'DISABLED' AND NEW.status IN ('ACTIVE', 'RETIRED'))) THEN
    RAISE EXCEPTION 'Không chuyển luật % từ % sang %', OLD.rule_code, OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_alert_rule_guard() IS 'Số luật riêng ≤ 13.alert.max-rules (mặc định 500); ACTIVE↔DISABLED, ACTIVE/DISABLED→RETIRED, RETIRED là cuối (FRS §4.5, BR-13-031).';
CREATE TRIGGER tg_alert_rule_touch BEFORE UPDATE ON ph13_obs.alert_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_alert_rule_platform BEFORE INSERT OR UPDATE ON ph13_obs.alert_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_platform_guard();
CREATE TRIGGER tg_alert_rule_guard BEFORE INSERT OR UPDATE ON ph13_obs.alert_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_alert_rule_guard();
CREATE TRIGGER tg_alert_rule_imm BEFORE UPDATE ON ph13_obs.alert_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'rule_code', 'scope', 'created_at');
CREATE TRIGGER tg_alert_rule_nodel BEFORE DELETE ON ph13_obs.alert_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.alert_rule');
COMMENT ON TABLE ph13_obs.alert_rule IS 'EN-13-07 Luật cảnh báo (PromQL, LogQL) kèm runbook bắt buộc (FR-13-042, 043, 044). Không có trạng thái nháp: runbook_id NOT NULL. Luật scope=PLATFORM nhân bản từ Git cho từng tenant, tenant không sửa, không tắt (BR-13-032). Xóa mềm, mã không dùng lại.';
COMMENT ON COLUMN ph13_obs.alert_rule.expr IS 'Biểu thức đã qua ExpressionGuard; nhãn tenant do RulePublisher ghi đè khi đẩy tới Ruler (BR-13-027).';
COMMENT ON COLUMN ph13_obs.alert_rule.symptom IS 'Mô tả triệu chứng người dùng; bắt buộc khi severity = CRITICAL (BR-13-009).';
COMMENT ON COLUMN ph13_obs.alert_rule.resource_only IS 'SeverityPolicy đặt true khi mọi chỉ số trong biểu thức thuộc nhóm tài nguyên thuần (CPU, bộ nhớ, đĩa); khi đó tối đa WARNING.';
COMMENT ON COLUMN ph13_obs.alert_rule.eval_interval_seconds IS 'Null: dùng 13.alert.eval-interval-seconds (30 giây).';
COMMENT ON COLUMN ph13_obs.alert_rule.group_key_labels IS 'Nhãn dùng gom nhóm (group_by của Alertmanager); cấm nhãn có số giá trị không giới hạn (BR-13-026).';
COMMENT ON COLUMN ph13_obs.alert_rule.expr_hash IS 'SHA-256 của biểu thức chuẩn hóa; RuleReconciler so với nhóm luật trong Mimir để tự lành (SDD §4.16).';
-- @rollback DROP TABLE IF EXISTS ph13_obs.alert_rule CASCADE; DROP FUNCTION IF EXISTS ph13_obs.tg_alert_rule_guard();

-- @file 13-1030-notify.sql
-- @changeset ph13-1300-notification-channel
CREATE TABLE ph13_obs.notification_channel (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  channel_code     varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  kind             varchar(7)    NOT NULL,
  target           varchar(512)  NOT NULL,
  secret_ref       varchar(255),
  external         boolean       NOT NULL DEFAULT false,
  enabled          boolean       NOT NULL DEFAULT true,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  last_test_at     timestamptz,
  last_test_ok     boolean,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_channel PRIMARY KEY (id),
  CONSTRAINT uq_notification_channel_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_notification_channel_code UNIQUE (tenant_id, channel_code),
  CONSTRAINT ck_notification_channel_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_notification_channel_code CHECK (channel_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_notification_channel_kind CHECK (kind IN ('EMAIL', 'SMS', 'WEBHOOK', 'INAPP')),
  CONSTRAINT ck_notification_channel_webhook CHECK (kind <> 'WEBHOOK' OR (target ~ '^https://[A-Za-z0-9.-]+(:[0-9]{2,5})?(/.*)?$' AND secret_ref IS NOT NULL)),
  CONSTRAINT ck_notification_channel_sms CHECK (kind <> 'SMS' OR target !~ '^\+?[0-9 ().-]{8,16}$'),
  CONSTRAINT ck_notification_channel_secret CHECK (secret_ref IS NULL OR secret_ref ~ '^kv/dh/[A-Za-z0-9/_-]+$'),
  CONSTRAINT ck_notification_channel_status CHECK (status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_notification_channel_test CHECK ((last_test_at IS NULL) = (last_test_ok IS NULL))
);
CREATE TRIGGER tg_notification_channel_touch BEFORE UPDATE ON ph13_obs.notification_channel FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_notification_channel_imm BEFORE UPDATE ON ph13_obs.notification_channel FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'channel_code', 'kind', 'created_at');
CREATE TRIGGER tg_notification_channel_nodel BEFORE DELETE ON ph13_obs.notification_channel FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.notification_channel');
COMMENT ON TABLE ph13_obs.notification_channel IS 'EN-13-13 Kênh gửi cảnh báo: thư, SMS, webhook, trong ứng dụng (FR-13-048). Bí mật (khóa ký webhook) ở OpenBao, bảng chỉ giữ đường dẫn secret_ref. Xóa mềm, mã không dùng lại.';
COMMENT ON COLUMN ph13_obs.notification_channel.target IS 'Hòm thư nhóm, URL HTTPS nằm trong danh sách FQDN của cổng thoát (SEC-16) hoặc mã nhóm; không lưu số điện thoại hay thư cá nhân (PH-18 phân giải từ mã người dùng).';
COMMENT ON COLUMN ph13_obs.notification_channel.external IS 'Kênh độc lập với hạ tầng của site (SMS qua nhà mạng, Q13-16); nhóm nhận Nghiêm trọng cần ít nhất một kênh external (BR-13-022, kiểm ở ScheduleValidator).';
COMMENT ON COLUMN ph13_obs.notification_channel.secret_ref IS 'Đường dẫn OpenBao kv/dh/...; bắt buộc với WEBHOOK (chữ ký webhook-signature, SEC-47).';
-- @rollback DROP TABLE IF EXISTS ph13_obs.notification_channel CASCADE;

-- @changeset ph13-1310-oncall-schedule
CREATE TABLE ph13_obs.oncall_schedule (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  schedule_code    varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  group_code       varchar(64)   NOT NULL,
  timezone         varchar(40)   NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  rotation         jsonb         NOT NULL,
  escalation_order jsonb         NOT NULL,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_oncall_schedule PRIMARY KEY (id),
  CONSTRAINT uq_oncall_schedule_code UNIQUE (tenant_id, schedule_code),
  CONSTRAINT ck_oncall_schedule_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_oncall_schedule_code CHECK (schedule_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_oncall_schedule_group CHECK (group_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_oncall_schedule_tz CHECK (timezone ~ '^[A-Za-z_]+(/[A-Za-z_+-]+)+$|^UTC$'),
  CONSTRAINT ck_oncall_schedule_rotation CHECK (jsonb_typeof(rotation) = 'array' AND jsonb_array_length(rotation) >= 1),
  CONSTRAINT ck_oncall_schedule_escalation CHECK (jsonb_typeof(escalation_order) = 'array' AND jsonb_array_length(escalation_order) BETWEEN 1 AND 3),
  CONSTRAINT ck_oncall_schedule_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_oncall_schedule_group ON ph13_obs.oncall_schedule (tenant_id, group_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_oncall_schedule_touch BEFORE UPDATE ON ph13_obs.oncall_schedule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_oncall_schedule_imm BEFORE UPDATE ON ph13_obs.oncall_schedule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'schedule_code', 'created_at');
CREATE TRIGGER tg_oncall_schedule_nodel BEFORE DELETE ON ph13_obs.oncall_schedule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.oncall_schedule');
COMMENT ON TABLE ph13_obs.oncall_schedule IS 'EN-13-12 Lịch trực theo nhóm nhận: ca theo thứ trong tuần, thứ tự leo thang, múi giờ (FR-13-048). Lịch hợp lệ (không hở giờ, không chồng ca, nhóm Nghiêm trọng đủ kênh) do ScheduleValidator kiểm trước khi lưu (ERR-13-034).';
COMMENT ON COLUMN ph13_obs.oncall_schedule.rotation IS 'Mảng ca [{"days":[1..7],"from":"HH:mm","to":"HH:mm","level1":"mã người dùng","level2":"…","level3":"…"}]; chỉ mã người dùng, không thông tin liên lạc.';
COMMENT ON COLUMN ph13_obs.oncall_schedule.escalation_order IS 'Tối đa 3 cấp [{"level":1,"channels":["mã kênh"]}…]; cấp 2 ở 15 phút, cấp 3 ở 30 phút theo 13.alert.escalate-minutes.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.oncall_schedule CASCADE;

-- @file 13-1040-alert.sql
-- @changeset ph13-1400-alert splitStatements:false
CREATE TABLE ph13_obs.alert (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  rule_code        varchar(64)   NOT NULL,
  fingerprint      varchar(64)   NOT NULL,
  status           varchar(12)   NOT NULL DEFAULT 'FIRING',
  severity         varchar(8)    NOT NULL,
  labels           jsonb         NOT NULL,
  summary          varchar(1000) NOT NULL,
  group_key        varchar(128)  NOT NULL,
  started_at       timestamptz   NOT NULL DEFAULT now(),
  ended_at         timestamptz,
  escalation_level smallint      NOT NULL DEFAULT 1,
  resolution       varchar(6),
  acknowledged_by  varchar(64),
  acknowledged_at  timestamptz,
  silence_until    timestamptz,
  silence_reason   varchar(500),
  silence_id       varchar(64),
  last_firing_at   timestamptz   NOT NULL DEFAULT now(),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_alert PRIMARY KEY (id),
  CONSTRAINT uq_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_alert_rule FOREIGN KEY (tenant_id, rule_code) REFERENCES ph13_obs.alert_rule (tenant_id, rule_code),
  CONSTRAINT ck_alert_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_alert_fingerprint CHECK (fingerprint ~ '^[0-9a-f]{16,64}$'),
  CONSTRAINT ck_alert_status CHECK (status IN ('FIRING', 'ACKNOWLEDGED', 'SILENCED', 'RESOLVED')),
  CONSTRAINT ck_alert_severity CHECK (severity IN ('CRITICAL', 'WARNING', 'INFO')),
  CONSTRAINT ck_alert_labels CHECK (jsonb_typeof(labels) = 'object' AND lower(labels ->> 'tenant') = lower(tenant_id)),
  CONSTRAINT ck_alert_escalation CHECK (escalation_level BETWEEN 1 AND 3 AND (escalation_level = 1 OR severity = 'CRITICAL')),
  CONSTRAINT ck_alert_resolution CHECK ((status = 'RESOLVED') = (resolution IS NOT NULL AND ended_at IS NOT NULL)),
  CONSTRAINT ck_alert_resolution_kind CHECK (resolution IS NULL OR resolution IN ('MANUAL', 'AUTO')),
  CONSTRAINT ck_alert_silence CHECK ((status = 'SILENCED') = (silence_until IS NOT NULL AND silence_reason IS NOT NULL)),
  CONSTRAINT ck_alert_ack CHECK (status <> 'ACKNOWLEDGED' OR (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)),
  CONSTRAINT ck_alert_time CHECK (ended_at IS NULL OR ended_at >= started_at)
);
CREATE UNIQUE INDEX ux_alert_open ON ph13_obs.alert (tenant_id, rule_code, fingerprint) WHERE status <> 'RESOLVED';
CREATE INDEX ix_alert_list ON ph13_obs.alert (tenant_id, status, severity, started_at DESC);
CREATE INDEX ix_alert_group ON ph13_obs.alert (tenant_id, group_key) WHERE status <> 'RESOLVED';
CREATE INDEX ix_alert_rule_time ON ph13_obs.alert (tenant_id, rule_code, started_at DESC);
CREATE INDEX ix_alert_escalation ON ph13_obs.alert (tenant_id, started_at) WHERE status = 'FIRING' AND severity = 'CRITICAL';
CREATE INDEX ix_alert_silence_expiry ON ph13_obs.alert (silence_until) WHERE status = 'SILENCED';
CREATE OR REPLACE FUNCTION ph13_obs.tg_alert_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE days numeric; lim interval;
BEGIN
  IF OLD.status = 'RESOLVED' THEN
    RAISE EXCEPTION 'Cảnh báo % đã đóng, không sửa (ERR-13-020)', OLD.id USING ERRCODE = '55000';
  END IF;
  IF NEW.status <> OLD.status AND NOT (
       (OLD.status = 'FIRING' AND NEW.status IN ('ACKNOWLEDGED', 'SILENCED', 'RESOLVED'))
    OR (OLD.status = 'ACKNOWLEDGED' AND NEW.status IN ('SILENCED', 'RESOLVED'))
    OR (OLD.status = 'SILENCED' AND NEW.status IN ('FIRING', 'RESOLVED'))) THEN
    RAISE EXCEPTION 'Không chuyển cảnh báo từ % sang % (ERR-13-020)', OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  IF NEW.status = 'SILENCED' AND (OLD.status <> 'SILENCED' OR NEW.silence_until IS DISTINCT FROM OLD.silence_until) THEN
    SELECT coalesce((SELECT (params ->> '13.alert.silence-max-days')::numeric FROM ph13_obs.tenant_obs_config WHERE tenant_id = NEW.tenant_id), 7) INTO days;
    lim := CASE WHEN NEW.severity = 'CRITICAL' THEN interval '24 hours' ELSE make_interval(days => days::int) END;
    IF NEW.silence_until <= now() OR NEW.silence_until > now() + lim THEN
      RAISE EXCEPTION 'Hạn tạm ẩn phải trong (bây giờ, bây giờ + %] (ERR-13-021, BR-13-021)', lim USING ERRCODE = '23514';
    END IF;
  END IF;
  IF NEW.escalation_level <> OLD.escalation_level THEN
    IF NEW.escalation_level <> OLD.escalation_level + 1 OR OLD.status <> 'FIRING' OR NEW.severity <> 'CRITICAL' THEN
      RAISE EXCEPTION 'Leo thang chỉ tăng từng cấp, cho cảnh báo CRITICAL đang FIRING (BR-13-022)' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_alert_guard() IS 'Bảng chuyển trạng thái cảnh báo (FRS §4.3), hạn tạm ẩn ≤ 13.alert.silence-max-days (Nghiêm trọng ≤ 24 giờ), leo thang từng cấp.';
CREATE TRIGGER tg_alert_touch BEFORE UPDATE ON ph13_obs.alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_alert_guard BEFORE UPDATE ON ph13_obs.alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_alert_guard();
CREATE TRIGGER tg_alert_imm BEFORE UPDATE ON ph13_obs.alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'rule_code', 'fingerprint', 'started_at', 'created_at');
CREATE TRIGGER tg_alert_ret BEFORE DELETE ON ph13_obs.alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('ended_at', '2 years');
ALTER TABLE ph13_obs.alert SET (fillfactor = 80, autovacuum_vacuum_scale_factor = 0.05);   -- cập nhật trạng thái, leo thang, tạm ẩn
CALL ph13_obs.p_enable_rls('ph13_obs.alert');
COMMENT ON TABLE ph13_obs.alert IS 'EN-13-09 Cảnh báo: một lần luật được thỏa; FIRING, ACKNOWLEDGED, SILENCED, RESOLVED (FR-13-044, 045, 047). Khóa tự nhiên (tenant, rule_code, fingerprint) chỉ một bản đang mở nên webhook Alertmanager lũy đẳng. Giữ 2 năm.';
COMMENT ON COLUMN ph13_obs.alert.fingerprint IS 'Dấu vân tay của Alertmanager cho tổ hợp nhãn; cùng luật, cùng fingerprint chỉ một cảnh báo mở.';
COMMENT ON COLUMN ph13_obs.alert.labels IS 'Nhãn chuẩn (mục 4.8 FRS); luôn có tenant khớp tenant_id (BR-13-027); không trace_id, user_id, client_ip.';
COMMENT ON COLUMN ph13_obs.alert.group_key IS 'Khóa gom nhóm: cùng nguyên nhân hiển thị và thông báo gộp (FR-13-045).';
COMMENT ON COLUMN ph13_obs.alert.escalation_level IS '1…3; thuộc tính, không phải trạng thái; chỉ CRITICAL leo thang (BR-13-022).';
COMMENT ON COLUMN ph13_obs.alert.silence_until IS 'Hạn tạm ẩn; trigger kiểm ≤ 13.alert.silence-max-days, CRITICAL ≤ 24 giờ (BR-13-021). Đặt null khi quay về FIRING.';
COMMENT ON COLUMN ph13_obs.alert.silence_id IS 'Mã silence ở Alertmanager để hủy khi đóng sớm.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.alert CASCADE; DROP FUNCTION IF EXISTS ph13_obs.tg_alert_guard();

-- @changeset ph13-1410-alert-action
CREATE TABLE ph13_obs.alert_action (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  alert_id         uuid          NOT NULL,
  action           varchar(8)    NOT NULL,
  actor            varchar(64)   NOT NULL,
  at               timestamptz   NOT NULL DEFAULT now(),
  cause            varchar(1000),
  measure          varchar(1000),
  outcome          varchar(9),
  silence_until    timestamptz,
  silence_id       varchar(64),
  reason           varchar(500),
  level_to         smallint,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_alert_action PRIMARY KEY (id),
  CONSTRAINT fk_alert_action_alert FOREIGN KEY (alert_id, tenant_id) REFERENCES ph13_obs.alert (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_alert_action_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_alert_action_kind CHECK (action IN ('ACK', 'RESOLVE', 'SILENCE', 'ESCALATE')),
  CONSTRAINT ck_alert_action_outcome CHECK (outcome IS NULL OR outcome IN ('FIXED', 'NO_ACTION', 'EXTERNAL')),
  -- BR-13-023: đóng thủ công cần nguyên nhân, hành động, kết quả; tác nhân system:* là đóng tự động.
  CONSTRAINT ck_alert_action_resolve CHECK (action <> 'RESOLVE' OR actor LIKE 'system:%'
        OR (char_length(btrim(coalesce(cause, ''))) >= 1 AND char_length(btrim(coalesce(measure, ''))) >= 1 AND outcome IS NOT NULL)),
  CONSTRAINT ck_alert_action_silence CHECK (action <> 'SILENCE' OR (silence_until IS NOT NULL AND char_length(btrim(coalesce(reason, ''))) >= 1)),
  CONSTRAINT ck_alert_action_escalate CHECK (action <> 'ESCALATE' OR level_to BETWEEN 2 AND 3)
);
CREATE INDEX ix_alert_action_alert ON ph13_obs.alert_action (tenant_id, alert_id, at);
CREATE INDEX ix_alert_action_actor ON ph13_obs.alert_action (tenant_id, actor, at DESC);
CREATE TRIGGER tg_alert_action_append BEFORE UPDATE ON ph13_obs.alert_action FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_append_only();
CREATE TRIGGER tg_alert_action_ret BEFORE DELETE ON ph13_obs.alert_action FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('at', '2 years');
CALL ph13_obs.p_enable_rls('ph13_obs.alert_action');
COMMENT ON TABLE ph13_obs.alert_action IS 'EN-13-11 Thao tác xử lý cảnh báo: xác nhận, đóng, tạm ẩn, leo thang; chỉ thêm, ghi cùng giao dịch với đổi trạng thái (FR-13-047). Giữ 2 năm; xóa theo cảnh báo khi hết hạn.';
COMMENT ON COLUMN ph13_obs.alert_action.outcome IS 'FIXED (đã khắc phục), NO_ACTION (báo giả, không cần làm gì), EXTERNAL (nguyên nhân bên ngoài); dùng tính tỷ lệ cảnh báo giả (FR-13-050).';
COMMENT ON COLUMN ph13_obs.alert_action.actor IS 'Mã người dùng, hoặc system:alertmanager, system:escalation cho thao tác tự động.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.alert_action CASCADE;

-- @file 13-1050-security.sql
-- @changeset ph13-1500-detection-rule splitStatements:false
CREATE TABLE ph13_obs.detection_rule (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  rule_code          varchar(40)   NOT NULL,
  name               varchar(255)  NOT NULL,
  source             varchar(40)   NOT NULL,
  impl               varchar(8)    NOT NULL DEFAULT 'RULER',
  threshold          jsonb         NOT NULL,
  threshold_default  jsonb         NOT NULL,
  threshold_limit    jsonb         NOT NULL DEFAULT '{}',
  severity           varchar(8)    NOT NULL,
  recipients         varchar(8)[]  NOT NULL DEFAULT '{SO}',
  enabled            boolean       NOT NULL DEFAULT true,
  can_disable        boolean       NOT NULL DEFAULT true,
  source_revision    varchar(64),
  tuned_by           varchar(64),
  tuned_at           timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_detection_rule PRIMARY KEY (id),
  CONSTRAINT uq_detection_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT ck_detection_rule_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_detection_rule_code CHECK (rule_code ~ '^(UC-SEC-[0-9]{2}|[A-Z][A-Z0-9-]{2,39})$'),
  CONSTRAINT ck_detection_rule_impl CHECK (impl IN ('RULER', 'ENGINE', 'BREAK')),
  CONSTRAINT ck_detection_rule_severity CHECK (severity IN ('CRITICAL', 'WARNING', 'INFO')),
  CONSTRAINT ck_detection_rule_recipients CHECK (cardinality(recipients) >= 1 AND recipients <@ ARRAY['SO', 'TA', 'PA', 'AU']::varchar[]),
  CONSTRAINT ck_detection_rule_json CHECK (jsonb_typeof(threshold) = 'object' AND jsonb_typeof(threshold_default) = 'object' AND jsonb_typeof(threshold_limit) = 'object'),
  -- BR-13-025: biên nới tối đa 2 lần mặc định; ngưỡng hiện hành nằm trong biên; luật không tắt thì không đổi ngưỡng.
  CONSTRAINT ck_detection_rule_limit CHECK (ph13_obs.fn_limit_ok(threshold_default, threshold_limit)),
  CONSTRAINT ck_detection_rule_threshold CHECK (ph13_obs.fn_threshold_ok(threshold, threshold_limit)),
  CONSTRAINT ck_detection_rule_fixed CHECK (can_disable OR (enabled AND threshold = threshold_default)),
  CONSTRAINT ck_detection_rule_tuned CHECK (threshold = threshold_default OR (tuned_by IS NOT NULL AND tuned_at IS NOT NULL))
);
CREATE INDEX ix_detection_rule_impl ON ph13_obs.detection_rule (tenant_id, impl) WHERE enabled;
CREATE TRIGGER tg_detection_rule_touch BEFORE UPDATE ON ph13_obs.detection_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_detection_rule_imm BEFORE UPDATE ON ph13_obs.detection_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'rule_code', 'source', 'impl', 'threshold_default', 'threshold_limit', 'can_disable', 'created_at');
CREATE TRIGGER tg_detection_rule_nodel BEFORE DELETE ON ph13_obs.detection_rule FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.detection_rule');
COMMENT ON TABLE ph13_obs.detection_rule IS 'EN-13-14 Luật phát hiện bất thường an ninh, nạp 25 luật UC-SEC-01…25 của D03-07 §7.5 cho từng tenant, kèm hai luật phụ của PH-13 (FR-13-051). Cán bộ ATTT chỉ tinh chỉnh threshold trong biên; thay đổi ghi kiểm toán (SECURITY.RULE.TUNE).';
COMMENT ON COLUMN ph13_obs.detection_rule.impl IS 'RULER: luật Mimir hoặc Loki Ruler; ENGINE: DetectionEngine truy vấn bản ghi kiểm toán; BREAK: UC-SEC-20 do BreakHandler phát thẳng (SDD §4.20).';
COMMENT ON COLUMN ph13_obs.detection_rule.threshold_limit IS '{"khóa":{"dir":"MAX"|"MIN","bound":số}}: MAX nới lên tới bound (≤ 2 lần mặc định), MIN nới xuống tới bound (≥ nửa mặc định); {} là luật "mọi sự kiện", không có ngưỡng số.';
COMMENT ON COLUMN ph13_obs.detection_rule.can_disable IS 'false cho luật mức Nghiêm trọng kiểu "mọi sự kiện": không tắt, không đổi ngưỡng (ck_detection_rule_fixed).';
COMMENT ON COLUMN ph13_obs.detection_rule.severity IS 'NT của D03-07 → CRITICAL; C, TB → WARNING (giả định, Q13-54).';
-- @rollback DROP TABLE IF EXISTS ph13_obs.detection_rule CASCADE;

-- @changeset ph13-1510-security-alert splitStatements:false
CREATE TABLE ph13_obs.security_alert (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  rule_code        varchar(40)   NOT NULL,
  status           varchar(12)   NOT NULL DEFAULT 'NEW',
  severity         varchar(8)    NOT NULL,
  subject          varchar(255)  NOT NULL,
  evidence         jsonb         NOT NULL DEFAULT '{}',
  occurrence_count integer       NOT NULL DEFAULT 1,
  detected_at      timestamptz   NOT NULL DEFAULT now(),
  last_seen_at     timestamptz   NOT NULL DEFAULT now(),
  assignee         varchar(64),
  acknowledged_at  timestamptz,
  verdict          varchar(18),
  verdict_note     varchar(1000),
  closed_by        varchar(64),
  closed_at        timestamptz,
  incident_ref     varchar(64),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_security_alert PRIMARY KEY (id),
  CONSTRAINT uq_security_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_security_alert_rule FOREIGN KEY (tenant_id, rule_code) REFERENCES ph13_obs.detection_rule (tenant_id, rule_code),
  CONSTRAINT ck_security_alert_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_security_alert_status CHECK (status IN ('NEW', 'ACKNOWLEDGED', 'CLOSED')),
  CONSTRAINT ck_security_alert_severity CHECK (severity IN ('CRITICAL', 'WARNING', 'INFO')),
  CONSTRAINT ck_security_alert_evidence CHECK (jsonb_typeof(evidence) = 'object' AND coalesce(jsonb_array_length(evidence -> 'auditIds'), 0) <= 100),
  CONSTRAINT ck_security_alert_count CHECK (occurrence_count >= 1),
  CONSTRAINT ck_security_alert_ack CHECK (status = 'NEW' OR assignee IS NOT NULL OR status = 'CLOSED'),
  CONSTRAINT ck_security_alert_verdict_kind CHECK (verdict IS NULL OR verdict IN ('CONFIRMED_INCIDENT', 'FALSE_POSITIVE', 'ACCEPTED_RISK')),
  -- BR-13-024: đóng cần một trong ba kết luận; chấp nhận rủi ro cần ghi chú.
  CONSTRAINT ck_security_alert_closed CHECK ((status = 'CLOSED') = (verdict IS NOT NULL AND closed_by IS NOT NULL AND closed_at IS NOT NULL)),
  CONSTRAINT ck_security_alert_accepted CHECK (verdict IS DISTINCT FROM 'ACCEPTED_RISK' OR char_length(btrim(coalesce(verdict_note, ''))) >= 1),
  CONSTRAINT ck_security_alert_incident CHECK (incident_ref IS NULL OR verdict = 'CONFIRMED_INCIDENT')
);
CREATE UNIQUE INDEX ux_security_alert_open ON ph13_obs.security_alert (tenant_id, rule_code, subject) WHERE status <> 'CLOSED';
CREATE INDEX ix_security_alert_list ON ph13_obs.security_alert (tenant_id, status, severity, detected_at DESC);
CREATE INDEX ix_security_alert_rule ON ph13_obs.security_alert (tenant_id, rule_code, detected_at DESC);
CREATE OR REPLACE FUNCTION ph13_obs.tg_security_alert_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status = 'CLOSED' THEN
    RAISE EXCEPTION 'Cảnh báo an ninh % đã đóng, không sửa (ERR-13-020)', OLD.id USING ERRCODE = '55000';
  END IF;
  IF NEW.status <> OLD.status AND NOT ((OLD.status = 'NEW' AND NEW.status IN ('ACKNOWLEDGED', 'CLOSED')) OR (OLD.status = 'ACKNOWLEDGED' AND NEW.status = 'CLOSED')) THEN
    RAISE EXCEPTION 'Không chuyển cảnh báo an ninh từ % sang %', OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_security_alert_guard() IS 'NEW→ACKNOWLEDGED→CLOSED hoặc NEW→CLOSED; CLOSED là cuối (FRS §4.4).';
CREATE TRIGGER tg_security_alert_touch BEFORE UPDATE ON ph13_obs.security_alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_security_alert_guard BEFORE UPDATE ON ph13_obs.security_alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_security_alert_guard();
CREATE TRIGGER tg_security_alert_imm BEFORE UPDATE ON ph13_obs.security_alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'rule_code', 'detected_at', 'created_at');
CREATE TRIGGER tg_security_alert_ret BEFORE DELETE ON ph13_obs.security_alert FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('closed_at', '3 years');
CALL ph13_obs.p_enable_rls('ph13_obs.security_alert');
COMMENT ON TABLE ph13_obs.security_alert IS 'EN-13-15 Cảnh báo an ninh do luật phát hiện sinh ra; NEW, ACKNOWLEDGED, CLOSED; đóng phải có kết luận (FR-13-052, 053; BR-13-024). Gom theo (luật, chủ thể) khi còn mở. Giữ 3 năm sau khi đóng.';
COMMENT ON COLUMN ph13_obs.security_alert.subject IS 'Chủ thể bị nghi (mã người dùng, client, mã HTTT, IP đã băm theo luật); không dữ liệu cá nhân thô.';
COMMENT ON COLUMN ph13_obs.security_alert.evidence IS 'Bằng chứng: số đếm, khoảng thời gian và tối đa 100 audit_id ở khóa auditIds; không chứa dữ liệu gốc (SDD §4.20).';
COMMENT ON COLUMN ph13_obs.security_alert.incident_ref IS 'Mã hồ sơ ứng cứu (D03-07 §8) khi kết luận CONFIRMED_INCIDENT.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.security_alert CASCADE; DROP FUNCTION IF EXISTS ph13_obs.tg_security_alert_guard();

-- @changeset ph13-1520-incident-report splitStatements:false
CREATE TABLE ph13_obs.incident_report (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  report_code       varchar(64)   NOT NULL,
  kind              varchar(12)   NOT NULL,
  template          varchar(64)   NOT NULL,
  security_alert_id uuid,
  content           jsonb         NOT NULL DEFAULT '{}',
  status            varchar(5)    NOT NULL DEFAULT 'DRAFT',
  detected_at       timestamptz   NOT NULL,
  deadline_at       timestamptz,
  finalized_at      timestamptz,
  finalized_by      varchar(64),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident_report PRIMARY KEY (id),
  CONSTRAINT uq_incident_report_code UNIQUE (tenant_id, report_code),
  CONSTRAINT fk_incident_report_alert FOREIGN KEY (security_alert_id, tenant_id) REFERENCES ph13_obs.security_alert (id, tenant_id),
  CONSTRAINT ck_incident_report_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_incident_report_kind CHECK (kind IN ('CYBER', 'DLCN_BREACH')),
  CONSTRAINT ck_incident_report_content CHECK (jsonb_typeof(content) = 'object'),
  CONSTRAINT ck_incident_report_status CHECK (status IN ('DRAFT', 'FINAL')),
  CONSTRAINT ck_incident_report_deadline CHECK ((kind = 'DLCN_BREACH') = (deadline_at IS NOT NULL) AND (deadline_at IS NULL OR deadline_at > detected_at)),
  CONSTRAINT ck_incident_report_final CHECK ((status = 'FINAL') = (finalized_at IS NOT NULL AND finalized_by IS NOT NULL))
);
CREATE INDEX ix_incident_report_deadline ON ph13_obs.incident_report (tenant_id, deadline_at) WHERE status = 'DRAFT' AND deadline_at IS NOT NULL;
CREATE OR REPLACE FUNCTION ph13_obs.tg_incident_report_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status = 'FINAL' THEN
    RAISE EXCEPTION 'Báo cáo sự cố % đã chốt (FINAL), không sửa', OLD.report_code USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_obs.tg_incident_report_guard() IS 'Báo cáo FINAL bất biến (giữ 5 năm, SEC-74).';
CREATE TRIGGER tg_incident_report_touch BEFORE UPDATE ON ph13_obs.incident_report FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_incident_report_guard BEFORE UPDATE ON ph13_obs.incident_report FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_incident_report_guard();
CREATE TRIGGER tg_incident_report_imm BEFORE UPDATE ON ph13_obs.incident_report FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'report_code', 'kind', 'detected_at', 'created_at');
CREATE TRIGGER tg_incident_report_ret BEFORE DELETE ON ph13_obs.incident_report FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('created_at', '5 years');
CALL ph13_obs.p_enable_rls('ph13_obs.incident_report');
COMMENT ON TABLE ph13_obs.incident_report IS 'EN-13-22 Báo cáo sự cố an ninh mạng và thông báo vi phạm dữ liệu cá nhân dạng nháp, dựng từ mẫu (FR-13-055, Đợt sau; cờ obs.incident-report.enabled tắt ở MVP). Việc gửi cho cơ quan do chủ quản thực hiện ngoài hệ thống (Q13-10). Giữ 5 năm.';
COMMENT ON COLUMN ph13_obs.incident_report.deadline_at IS 'Hạn 72 giờ kể từ detected_at cho DLCN_BREACH (SEC-75); null với CYBER.';
COMMENT ON COLUMN ph13_obs.incident_report.content IS 'Nội dung theo mẫu, đã loại dữ liệu cá nhân; không đính kèm bằng chứng gốc.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.incident_report CASCADE; DROP FUNCTION IF EXISTS ph13_obs.tg_incident_report_guard();

-- @file 13-1055-notification.sql
-- @changeset ph13-1420-alert-notification
CREATE TABLE ph13_obs.alert_notification (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  alert_id         uuid,
  security_alert_id uuid,
  channel_id       uuid          NOT NULL,
  channel_code     varchar(64)   NOT NULL,
  recipient        varchar(64)   NOT NULL,
  level            smallint      NOT NULL DEFAULT 1,
  status           varchar(7)    NOT NULL DEFAULT 'PENDING',
  attempt          smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  sent_at          timestamptz,
  error            varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_alert_notification PRIMARY KEY (id),
  CONSTRAINT fk_alert_notification_alert FOREIGN KEY (alert_id, tenant_id) REFERENCES ph13_obs.alert (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_alert_notification_security FOREIGN KEY (security_alert_id, tenant_id) REFERENCES ph13_obs.security_alert (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_alert_notification_channel FOREIGN KEY (channel_id, tenant_id) REFERENCES ph13_obs.notification_channel (id, tenant_id),
  CONSTRAINT ck_alert_notification_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_alert_notification_subject CHECK ((alert_id IS NULL) <> (security_alert_id IS NULL)),
  CONSTRAINT ck_alert_notification_level CHECK (level BETWEEN 1 AND 3),
  CONSTRAINT ck_alert_notification_status CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'SKIPPED')),
  CONSTRAINT ck_alert_notification_attempt CHECK (attempt >= 0 AND attempt <= 10),
  CONSTRAINT ck_alert_notification_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL)),
  CONSTRAINT ck_alert_notification_error CHECK (status NOT IN ('FAILED') OR error IS NOT NULL),
  -- Thư và SMS chỉ chứa mã cảnh báo, mức, tóm tắt, liên kết; recipient là mã người dùng hoặc nhóm, không địa chỉ liên lạc.
  CONSTRAINT ck_alert_notification_recipient CHECK (recipient !~ '@' AND recipient !~ '^\+?[0-9 ().-]{8,16}$')
);
CREATE INDEX ix_alert_notification_queue ON ph13_obs.alert_notification (tenant_id, next_attempt_at) WHERE status = 'PENDING';
CREATE UNIQUE INDEX ux_alert_notification ON ph13_obs.alert_notification (coalesce(alert_id, security_alert_id), channel_id, level, recipient);
CREATE INDEX ix_alert_notification_alert ON ph13_obs.alert_notification (tenant_id, alert_id) WHERE alert_id IS NOT NULL;
CREATE INDEX ix_alert_notification_security ON ph13_obs.alert_notification (tenant_id, security_alert_id) WHERE security_alert_id IS NOT NULL;
CREATE TRIGGER tg_alert_notification_touch BEFORE UPDATE ON ph13_obs.alert_notification FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_alert_notification_imm BEFORE UPDATE ON ph13_obs.alert_notification FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'alert_id', 'security_alert_id', 'channel_id', 'level', 'recipient', 'created_at');
CREATE TRIGGER tg_alert_notification_ret BEFORE DELETE ON ph13_obs.alert_notification FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('created_at', '2 years');
ALTER TABLE ph13_obs.alert_notification SET (fillfactor = 80, autovacuum_vacuum_scale_factor = 0.05);
CALL ph13_obs.p_enable_rls('ph13_obs.alert_notification');
COMMENT ON TABLE ph13_obs.alert_notification IS 'EN-13-10 Lượt gửi thông báo cho cảnh báo vận hành (alert_id) hoặc cảnh báo an ninh (security_alert_id), đúng một trong hai; ghi PENDING cùng giao dịch với cảnh báo, NotificationDispatcher lấy việc bằng FOR UPDATE SKIP LOCKED, thử lại 30 giây, 2 phút, 10 phút rồi chuyển kênh dự phòng (FR-13-046). Khóa lũy đẳng (cảnh báo, kênh, cấp, người nhận) bằng ux_alert_notification. Giữ 2 năm.';
COMMENT ON COLUMN ph13_obs.alert_notification.security_alert_id IS 'Cảnh báo an ninh được thông báo (mức Nghiêm trọng gửi SO ngay, TA sau 15 phút); null khi thông báo cho cảnh báo vận hành.';
COMMENT ON COLUMN ph13_obs.alert_notification.recipient IS 'Mã người dùng hoặc mã nhóm; không lưu địa chỉ thư hay số điện thoại (PH-18 phân giải khi gửi).';
COMMENT ON COLUMN ph13_obs.alert_notification.level IS 'Cấp leo thang 1…3 của lượt gửi.';
COMMENT ON COLUMN ph13_obs.alert_notification.error IS 'Mã lỗi và thông điệp ngắn (ERR-13-120); không chứa nội dung thông báo.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.alert_notification CASCADE;

-- @file 13-1060-misc.sql
-- @changeset ph13-1600-siem-target
CREATE TABLE ph13_obs.siem_target (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  target_code      varchar(64)   NOT NULL,
  name             varchar(255)  NOT NULL,
  protocol         varchar(10)   NOT NULL,
  endpoint         varchar(512)  NOT NULL,
  schema_kind      varchar(4)    NOT NULL DEFAULT 'ECS',
  purpose          varchar(9)    NOT NULL DEFAULT 'SIEM',
  filter           jsonb         NOT NULL DEFAULT '{}',
  basis_ref        varchar(255),
  enabled          boolean       NOT NULL DEFAULT true,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  last_ok_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_siem_target PRIMARY KEY (id),
  CONSTRAINT uq_siem_target_code UNIQUE (tenant_id, target_code),
  CONSTRAINT ck_siem_target_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_siem_target_code CHECK (target_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_siem_target_protocol CHECK (protocol IN ('SYSLOG_TLS', 'OTLP')),
  CONSTRAINT ck_siem_target_endpoint CHECK ((protocol = 'SYSLOG_TLS' AND endpoint ~ '^[A-Za-z0-9.-]+:[0-9]{2,5}$') OR (protocol = 'OTLP' AND endpoint ~ '^https://[A-Za-z0-9.-]+(:[0-9]{2,5})?(/.*)?$')),
  CONSTRAINT ck_siem_target_schema CHECK (schema_kind IN ('ECS', 'OCSF')),
  CONSTRAINT ck_siem_target_purpose CHECK (purpose IN ('SIEM', 'AUTHORITY')),
  CONSTRAINT ck_siem_target_filter CHECK (jsonb_typeof(filter) = 'object'),
  -- BR-13-034: điểm xuất cho cơ quan chuyên trách chỉ bật khi có số hiệu văn bản yêu cầu.
  CONSTRAINT ck_siem_target_authority CHECK (purpose <> 'AUTHORITY' OR NOT enabled OR char_length(btrim(coalesce(basis_ref, ''))) >= 1),
  CONSTRAINT ck_siem_target_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_siem_target_touch BEFORE UPDATE ON ph13_obs.siem_target FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_siem_target_imm BEFORE UPDATE ON ph13_obs.siem_target FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'target_code', 'protocol', 'purpose', 'created_at');
CREATE TRIGGER tg_siem_target_nodel BEFORE DELETE ON ph13_obs.siem_target FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.siem_target');
COMMENT ON TABLE ph13_obs.siem_target IS 'EN-13-16 Mục tiêu SIEM, SOC: giao thức, lược đồ ECS hoặc OCSF, bộ lọc (FR-13-054). Điểm xuất purpose=AUTHORITY (cơ quan chuyên trách) tắt mặc định, chỉ bật kèm basis_ref (BR-13-034). Xóa mềm, mã không dùng lại.';
COMMENT ON COLUMN ph13_obs.siem_target.endpoint IS 'host:port (SYSLOG_TLS, RFC 5424 trên TLS) hoặc URL HTTPS (OTLP); phải nằm trong danh sách FQDN của cổng thoát (SEC-16, kiểm ở dịch vụ, ERR-13-039).';
COMMENT ON COLUMN ph13_obs.siem_target.filter IS 'Bộ lọc loại dữ liệu cá nhân và nội dung Nhạy cảm theo danh sách khóa cho phép (SEC-66).';
COMMENT ON COLUMN ph13_obs.siem_target.basis_ref IS 'Số hiệu văn bản yêu cầu của cơ quan chuyên trách; bắt buộc khi bật purpose=AUTHORITY.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.siem_target CASCADE;

-- @changeset ph13-1610-dashboard-set
CREATE TABLE ph13_obs.dashboard_set (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  set_code         varchar(64)   NOT NULL,
  content_version  integer       NOT NULL DEFAULT 1,
  content_hash     char(64)      NOT NULL,
  grafana_org_id   bigint,
  status           varchar(11)   NOT NULL DEFAULT 'PENDING',
  source_revision  varchar(64),
  synced_at        timestamptz,
  last_error       varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dashboard_set PRIMARY KEY (id),
  CONSTRAINT uq_dashboard_set_code UNIQUE (tenant_id, set_code),
  CONSTRAINT ck_dashboard_set_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_dashboard_set_code CHECK (set_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_dashboard_set_version CHECK (content_version >= 1),
  CONSTRAINT ck_dashboard_set_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dashboard_set_status CHECK (status IN ('PENDING', 'SYNCED', 'SYNC_FAILED')),
  CONSTRAINT ck_dashboard_set_synced CHECK ((status = 'SYNCED') = (synced_at IS NOT NULL AND grafana_org_id IS NOT NULL)),
  CONSTRAINT ck_dashboard_set_error CHECK (status <> 'SYNC_FAILED' OR last_error IS NOT NULL)
);
CREATE TRIGGER tg_dashboard_set_touch BEFORE UPDATE ON ph13_obs.dashboard_set FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_dashboard_set_imm BEFORE UPDATE ON ph13_obs.dashboard_set FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'set_code', 'created_at');
CREATE TRIGGER tg_dashboard_set_nodel BEFORE DELETE ON ph13_obs.dashboard_set FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.dashboard_set');
COMMENT ON TABLE ph13_obs.dashboard_set IS 'EN-13-17 Bộ dashboard chuẩn khai báo bằng mã, nhân bản cho từng tenant ở tổ chức Grafana riêng (FR-13-041). Chỉ lưu trạng thái đồng bộ, không lưu số liệu hay nội dung panel.';
COMMENT ON COLUMN ph13_obs.dashboard_set.content_version IS 'Phiên bản nội dung bộ dashboard (không phải version khóa lạc quan).';
COMMENT ON COLUMN ph13_obs.dashboard_set.content_hash IS 'Băm nội dung bộ đã nhân bản; so với kho Git để phát hiện lệch.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.dashboard_set CASCADE;

-- @changeset ph13-1620-saved-query
CREATE TABLE ph13_obs.saved_query (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(6)    NOT NULL,
  name             varchar(120)  NOT NULL,
  query            jsonb         NOT NULL,
  shared           boolean       NOT NULL DEFAULT false,
  owner            varchar(64)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_saved_query PRIMARY KEY (id),
  CONSTRAINT uq_saved_query_name UNIQUE (tenant_id, owner, kind, name),
  CONSTRAINT ck_saved_query_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_saved_query_kind CHECK (kind IN ('LOG', 'AUDIT', 'ACCESS')),
  CONSTRAINT ck_saved_query_query CHECK (jsonb_typeof(query) = 'object' AND octet_length(query::text) <= 8192),
  CONSTRAINT ck_saved_query_name CHECK (char_length(btrim(name)) >= 1)
);
CREATE INDEX ix_saved_query_list ON ph13_obs.saved_query (tenant_id, kind, shared, owner);
CREATE TRIGGER tg_saved_query_touch BEFORE UPDATE ON ph13_obs.saved_query FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_saved_query_imm BEFORE UPDATE ON ph13_obs.saved_query FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'kind', 'owner', 'created_at');
CALL ph13_obs.p_enable_rls('ph13_obs.saved_query');
COMMENT ON TABLE ph13_obs.saved_query IS 'EN-13-18 Truy vấn đã lưu (bộ lọc tra log, kiểm toán, nhật ký truy cập) theo người dùng, có thể chia sẻ trong tenant (FR-13-026). Xóa cứng khi chủ sở hữu xóa. Không lưu dữ liệu kết quả.';
COMMENT ON COLUMN ph13_obs.saved_query.query IS 'Bộ lọc dạng danh sách trắng (không biểu thức tự do); không chứa số định danh người bị tra cứu (BR-13-005), nếu có thì lưu object_key_hmac.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.saved_query CASCADE;

-- @changeset ph13-1630-probe-definition
CREATE TABLE ph13_obs.probe_definition (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  probe_code       varchar(64)   NOT NULL,
  target_api       varchar(255)  NOT NULL,
  method           varchar(6)    NOT NULL DEFAULT 'GET',
  interval_seconds integer       NOT NULL DEFAULT 60,
  expected_status  smallint      NOT NULL DEFAULT 200,
  timeout_ms       integer       NOT NULL DEFAULT 5000,
  sample_params    jsonb         NOT NULL DEFAULT '{}',
  enabled          boolean       NOT NULL DEFAULT true,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_probe_definition PRIMARY KEY (id),
  CONSTRAINT uq_probe_definition_code UNIQUE (tenant_id, probe_code),
  CONSTRAINT ck_probe_definition_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_probe_definition_code CHECK (probe_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_probe_definition_api CHECK (target_api ~ '^/[A-Za-z0-9._~/{}:-]+$'),
  CONSTRAINT ck_probe_definition_method CHECK (method IN ('GET', 'HEAD', 'POST')),
  CONSTRAINT ck_probe_definition_interval CHECK (interval_seconds BETWEEN 30 AND 300),
  CONSTRAINT ck_probe_definition_status_code CHECK (expected_status BETWEEN 100 AND 599),
  CONSTRAINT ck_probe_definition_timeout CHECK (timeout_ms BETWEEN 500 AND 30000 AND timeout_ms < interval_seconds * 1000),
  CONSTRAINT ck_probe_definition_params CHECK (jsonb_typeof(sample_params) = 'object'),
  CONSTRAINT ck_probe_definition_state CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_probe_definition_touch BEFORE UPDATE ON ph13_obs.probe_definition FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_touch();
CREATE TRIGGER tg_probe_definition_imm BEFORE UPDATE ON ph13_obs.probe_definition FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_immutable('id', 'tenant_id', 'probe_code', 'created_at');
CREATE TRIGGER tg_probe_definition_nodel BEFORE DELETE ON ph13_obs.probe_definition FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_forbid_delete();
CALL ph13_obs.p_enable_rls('ph13_obs.probe_definition');
COMMENT ON TABLE ph13_obs.probe_definition IS 'EN-13-20 Định nghĩa kiểm tra tổng hợp: gọi API quan trọng của tenant mỗi 13.probe.interval-seconds qua đường biên ngoài với cờ x-dh-synthetic, đo thành công và độ trễ (FR-13-008). Kết quả ở chỉ số dh_probe_*, không lưu ở bảng.';
COMMENT ON COLUMN ph13_obs.probe_definition.sample_params IS 'Giá trị mẫu cố định cho tham số bắt buộc của API đích: dữ liệu thử, không phải dữ liệu thật.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.probe_definition CASCADE;

-- @changeset ph13-1640-pii-finding
CREATE TABLE ph13_obs.pii_finding (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  scan_date        date          NOT NULL,
  du_code          varchar(32)   NOT NULL,
  logger           varchar(255)  NOT NULL,
  pattern_code     varchar(16)   NOT NULL,
  occurrences      integer       NOT NULL,
  consecutive_days smallint      NOT NULL DEFAULT 1,
  quarantine       boolean       NOT NULL DEFAULT false,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_pii_finding PRIMARY KEY (id),
  CONSTRAINT uq_pii_finding UNIQUE (tenant_id, scan_date, du_code, logger, pattern_code),
  CONSTRAINT ck_pii_finding_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_pii_finding_du CHECK (du_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_pii_finding_pattern CHECK (pattern_code IN ('ID12', 'PHONE', 'EMAIL', 'CARD', 'KEY_NAME')),
  CONSTRAINT ck_pii_finding_count CHECK (occurrences >= 1 AND consecutive_days >= 1)
);
CREATE INDEX ix_pii_finding_date ON ph13_obs.pii_finding (tenant_id, scan_date DESC);
CREATE INDEX ix_pii_finding_du ON ph13_obs.pii_finding (tenant_id, du_code, scan_date DESC);
CREATE TRIGGER tg_pii_finding_ret BEFORE DELETE ON ph13_obs.pii_finding FOR EACH ROW EXECUTE FUNCTION ph13_obs.tg_guard_retention('created_at', '12 months');
CALL ph13_obs.p_enable_rls('ph13_obs.pii_finding');
COMMENT ON TABLE ph13_obs.pii_finding IS 'Kết quả quét dữ liệu cá nhân trong log hằng ngày 02:00: chỉ DU, logger, mã mẫu, số lần; KHÔNG lưu giá trị phát hiện (BR-13-011, NFR-13-021). Giữ 12 tháng. Tái phạm 3 ngày liên tiếp thì nâng CRITICAL và đề nghị quarantine.';
COMMENT ON COLUMN ph13_obs.pii_finding.pattern_code IS 'ID12 (số định danh 12 chữ số có kiểm cấu trúc), PHONE, EMAIL, CARD (qua Luhn), KEY_NAME (khóa tên nhạy cảm có giá trị khác ***).';
COMMENT ON COLUMN ph13_obs.pii_finding.quarantine IS 'Cờ obs.pii.quarantine theo DU do SO duyệt: cấu hình gateway loại log của DU khỏi kho tra cứu tới khi sửa.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.pii_finding CASCADE;

-- @changeset ph13-1650-detect-cursor
CREATE TABLE ph13_obs.detect_cursor (
  tenant_id        varchar(16)   NOT NULL,
  rule_code        varchar(40)   NOT NULL,
  processed_until  timestamptz   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_detect_cursor PRIMARY KEY (tenant_id, rule_code),
  CONSTRAINT fk_detect_cursor_rule FOREIGN KEY (tenant_id, rule_code) REFERENCES ph13_obs.detection_rule (tenant_id, rule_code),
  CONSTRAINT ck_detect_cursor_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$')
);
ALTER TABLE ph13_obs.detect_cursor SET (fillfactor = 70, autovacuum_vacuum_scale_factor = 0.02);
CALL ph13_obs.p_enable_rls('ph13_obs.detect_cursor');
COMMENT ON TABLE ph13_obs.detect_cursor IS 'Mốc đã xử lý của DetectionEngine theo (tenant, luật); sau gián đoạn chạy bù theo bước 5 phút từ mốc, tối đa 24 giờ (SDD §4.20). Bảng kỹ thuật, khóa tự nhiên.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.detect_cursor;

-- @changeset ph13-1700-obs-outbox
CREATE TABLE ph13_obs.outbox (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     text          NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_obs_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_obs_outbox_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_obs_outbox_type CHECK (event_type ~ '^EVT-13-[0-9]{2}$|^[a-z][a-zA-Z0-9.]{2,127}$'),
  CONSTRAINT ck_obs_outbox_topic CHECK (topic ~ '^[a-z0-9]+\.obs\.[a-z0-9.-]+\.v[0-9]+$'),
  CONSTRAINT ck_obs_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_obs_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_obs_outbox_no_secret CHECK (payload::text !~* '"(password|secret|clientsecret|apikey|privatekey|passphrase|token)"\s*:')
);
CREATE INDEX ix_obs_outbox_occurred ON ph13_obs.outbox (occurred_at);
CALL ph13_obs.p_enable_rls('ph13_obs.outbox');
COMMENT ON TABLE ph13_obs.outbox IS 'Hộp thư đi (DD-11) của module observability cho EVT-13-01…04, 10, 13, 14, ghi cùng giao dịch với đổi trạng thái; Debezium Outbox Router (QM-VUA, QM-LON) hoặc OutboxRelay (QM-NHO) đọc. Dọn sau 3 ngày. Chặn khóa bí mật trong payload.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.outbox;

-- @changeset ph13-1710-obs-shedlock
CREATE TABLE ph13_obs.shedlock (
  name             varchar(64)   NOT NULL,
  lock_until       timestamptz   NOT NULL,
  locked_at        timestamptz   NOT NULL,
  locked_by        varchar(255)  NOT NULL,
  CONSTRAINT pk_obs_shedlock PRIMARY KEY (name)
);
ALTER TABLE ph13_obs.shedlock SET (fillfactor = 70, autovacuum_vacuum_scale_factor = 0.02);
COMMENT ON TABLE ph13_obs.shedlock IS 'Khóa tác vụ nền của module observability (RuleReconciler, EscalationScheduler, NotificationDispatcher, DetectionEngine, PiiScanner, SyntheticProbeRunner, OverridesReconciler); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph13_obs.shedlock;

-- @file 13-1900-grants.sql
-- @changeset ph13-1990-grants-obs runAlways:true
GRANT SELECT, INSERT, UPDATE ON ph13_obs.tenant_obs_config, ph13_obs.runbook, ph13_obs.alert_rule, ph13_obs.notification_channel,
  ph13_obs.oncall_schedule, ph13_obs.detection_rule, ph13_obs.siem_target, ph13_obs.dashboard_set, ph13_obs.probe_definition TO ph13_obs_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph13_obs.alert, ph13_obs.alert_notification, ph13_obs.security_alert, ph13_obs.incident_report,
  ph13_obs.saved_query, ph13_obs.pii_finding, ph13_obs.detect_cursor, ph13_obs.outbox, ph13_obs.shedlock TO ph13_obs_app;
GRANT SELECT, INSERT, DELETE ON ph13_obs.alert_action TO ph13_obs_app;   -- chỉ thêm, xóa khi hết hạn lưu
GRANT SELECT ON ph13_obs.tenant_obs_config, ph13_obs.runbook, ph13_obs.alert_rule, ph13_obs.alert, ph13_obs.alert_action, ph13_obs.alert_notification,
  ph13_obs.notification_channel, ph13_obs.oncall_schedule, ph13_obs.detection_rule, ph13_obs.security_alert, ph13_obs.siem_target,
  ph13_obs.dashboard_set, ph13_obs.probe_definition, ph13_obs.pii_finding TO ph13_readonly;
-- Báo cáo đọc không thấy nội dung báo cáo sự cố, bộ lọc SIEM và đường dẫn bí mật kênh.
GRANT SELECT (id, tenant_id, report_code, kind, template, status, detected_at, deadline_at, finalized_at) ON ph13_obs.incident_report TO ph13_readonly;
REVOKE SELECT ON ph13_obs.notification_channel, ph13_obs.siem_target FROM ph13_readonly;
GRANT SELECT (id, tenant_id, channel_code, name, kind, external, enabled, status, last_test_at, last_test_ok) ON ph13_obs.notification_channel TO ph13_readonly;
GRANT SELECT (id, tenant_id, target_code, name, protocol, schema_kind, purpose, enabled, status, last_ok_at) ON ph13_obs.siem_target TO ph13_readonly;
-- @rollback -- Không thu hồi tự động.

-- @file 13-1950-seed.sql
-- @changeset ph13-1950-fn-seed-tenant splitStatements:false
-- Dữ liệu khởi tạo theo tenant (FR-13-059 bước S5, S6): cấu hình mặc định, kênh trong ứng dụng, 25 luật UC-SEC và hai luật phụ.
-- Gọi trong phiên đã đặt app.tenant_id = p_tenant; lũy đẳng (ON CONFLICT DO NOTHING).
CREATE OR REPLACE PROCEDURE ph13_obs.p_seed_tenant(p_tenant varchar, p_scale varchar DEFAULT 'QM-VUA')
  LANGUAGE plpgsql AS $p$
DECLARE
  v_all jsonb := '{"mode":"ALL"}';
BEGIN
  IF current_setting('app.tenant_id', false) <> p_tenant THEN
    RAISE EXCEPTION 'Phiên phải đặt app.tenant_id = % trước khi nạp dữ liệu khởi tạo', p_tenant USING ERRCODE = '42501';
  END IF;
  INSERT INTO ph13_obs.tenant_obs_config (id, tenant_id, scale, created_by, updated_by)
  VALUES (gen_random_uuid(), p_tenant, p_scale, 'system:seed', 'system:seed') ON CONFLICT (tenant_id) DO NOTHING;
  INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, created_by, updated_by)
  VALUES (gen_random_uuid(), p_tenant, 'inapp-default', 'Thông báo trong ứng dụng', 'INAPP', 'inapp', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, channel_code) DO NOTHING;
  INSERT INTO ph13_obs.detection_rule (id, tenant_id, rule_code, name, source, impl, threshold, threshold_default, threshold_limit, severity, recipients, can_disable, source_revision, created_by, updated_by)
  SELECT gen_random_uuid(), p_tenant, k.code, k.name, k.source, k.impl, k.thr, k.thr, k.lim, k.sev, k.rcp, k.can_disable, 'seed-0.1', 'system:seed', 'system:seed'
  FROM (VALUES
    ('UC-SEC-01', 'Đăng nhập sai hàng loạt từ một IP hoặc trên nhiều tài khoản', 'KEYCLOAK', 'RULER', '{"failPerIp5m":20,"distinctAccountsPerIp5m":10}'::jsonb, '{"failPerIp5m":{"dir":"MAX","bound":40},"distinctAccountsPerIp5m":{"dir":"MAX","bound":20}}'::jsonb, 'WARNING', '{SO}'::varchar[], true),
    ('UC-SEC-02', 'Đăng nhập thành công của quản trị từ ASN mới hoặc ngoài giờ', 'KEYCLOAK', 'RULER', '{"mode":"NEW_ASN_OR_OFFHOURS","offHoursFrom":22,"offHoursTo":6}'::jsonb, '{}'::jsonb, 'WARNING', '{SO}', true),
    ('UC-SEC-03', 'Tắt MFA, xóa yếu tố thứ hai, đặt lại mật khẩu quản trị', 'KEYCLOAK', 'RULER', v_all, '{}', 'WARNING', '{SO,TA}', true),
    ('UC-SEC-04', 'Sử dụng tài khoản break-glass', 'KEYCLOAK', 'RULER', v_all, '{}', 'CRITICAL', '{SO,TA}', false),
    ('UC-SEC-05', 'Gán vai trò quản trị hoặc vai trò nền tảng', 'KEYCLOAK', 'RULER', v_all, '{}', 'WARNING', '{SO}', true),
    ('UC-SEC-06', 'Token bị từ chối do sai cnf, aud hoặc iss không khớp tenant', 'APISIX', 'RULER', '{"deniedPerClient1m":5}', '{"deniedPerClient1m":{"dir":"MAX","bound":10}}', 'WARNING', '{SO}', true),
    ('UC-SEC-07', 'Client gọi từ IP mới hoặc vượt 5 lần lưu lượng trung bình 7 ngày', 'APISIX', 'RULER', '{"trafficMultiple7d":5}', '{"trafficMultiple7d":{"dir":"MAX","bound":10}}', 'WARNING', '{SO}', true),
    ('UC-SEC-08', 'Tỉ lệ 403, 404 cao của một chủ thể', 'APISIX', 'RULER', '{"deniedPer5m":50}', '{"deniedPer5m":{"dir":"MAX","bound":100}}', 'WARNING', '{SO}', true),
    ('UC-SEC-09', 'Từ chối do tenant không khớp (header, sự kiện Kafka, RLS)', 'DU', 'RULER', v_all, '{}', 'CRITICAL', '{SO,TA}', false),
    ('UC-SEC-10', 'Tra cứu CSDL quốc gia hàng loạt hoặc ngoài giờ', 'AUDIT', 'ENGINE', '{"distinctKeysPerHour":500,"offHoursMultiple":3}', '{"distinctKeysPerHour":{"dir":"MAX","bound":1000},"offHoursMultiple":{"dir":"MAX","bound":6}}', 'WARNING', '{SO}', true),
    ('UC-SEC-11', 'Xem đầy đủ dữ liệu Nhạy cảm nhiều lần', 'AUDIT', 'ENGINE', '{"revealPerHourPerUser":20}', '{"revealPerHourPerUser":{"dir":"MAX","bound":40}}', 'WARNING', '{SO}', true),
    ('UC-SEC-12', 'Xuất dữ liệu số lượng lớn', 'AUDIT', 'ENGINE', '{"rowsPerDayPerUser":100000}', '{"rowsPerDayPerUser":{"dir":"MAX","bound":200000}}', 'WARNING', '{SO}', true),
    ('UC-SEC-13', 'Callback thanh toán sai chữ ký hoặc MISMATCH số tiền', 'PAYMENT', 'RULER', '{"events":1}', '{"events":{"dir":"MAX","bound":2}}', 'WARNING', '{SO}', true),
    ('UC-SEC-14', 'Hoàn tiền vượt ngưỡng hoặc ngoài giờ', 'AUDIT', 'ENGINE', '{"mode":"TENANT_DAILY_LIMIT"}', '{}', 'WARNING', '{SO}', true),
    ('UC-SEC-15', 'WAF chặn tấn công tiêm hoặc tăng đột biến luật CRS', 'CORAZA', 'RULER', '{"blocksPer5mPerIp":100}', '{"blocksPer5mPerIp":{"dir":"MAX","bound":200}}', 'WARNING', '{SO}', true),
    ('UC-SEC-16', 'Lưu lượng bất thường tới biên (dấu hiệu DDoS)', 'APISIX', 'RULER', '{"peakMultiple5m":3}', '{"peakMultiple5m":{"dir":"MAX","bound":6}}', 'CRITICAL', '{SO,TA}', true),
    ('UC-SEC-17', 'Egress bị chặn từ pod ứng dụng', 'HUBBLE', 'RULER', '{"events":1}', '{"events":{"dir":"MAX","bound":2}}', 'WARNING', '{SO}', true),
    ('UC-SEC-18', 'Shell hoặc tiến trình lạ trong container', 'FALCO', 'RULER', v_all, '{}', 'CRITICAL', '{SO,TA}', false),
    ('UC-SEC-19', 'Pod bị Kyverno chặn vì ảnh không ký hoặc vi phạm PSS', 'KYVERNO', 'RULER', v_all, '{}', 'WARNING', '{SO}', true),
    ('UC-SEC-20', 'Đứt chuỗi băm nhật ký hoặc neo không khớp', 'PH13', 'BREAK', v_all, '{}', 'CRITICAL', '{SO,TA,PA}', false),
    ('UC-SEC-21', 'Lệch cấu hình so với Git (Argo CD OutOfSync do thay đổi tay)', 'ARGOCD', 'RULER', v_all, '{}', 'WARNING', '{SO}', true),
    ('UC-SEC-22', 'Truy cập Secret K8s, exec vào pod PROD, tạo ClusterRoleBinding', 'K8S_AUDIT', 'RULER', v_all, '{}', 'WARNING', '{SO}', true),
    ('UC-SEC-23', 'OpenBao: đăng nhập root, đổi chính sách, từ chối hàng loạt', 'OPENBAO', 'RULER', '{"rootLogin":1,"deniedPer5m":20}', '{"deniedPer5m":{"dir":"MAX","bound":40}}', 'CRITICAL', '{SO,TA,PA}', false),
    ('UC-SEC-24', 'Chứng thư sắp hết hạn hoặc bị thu hồi vẫn được dùng', 'CERT_MANAGER', 'RULER', '{"daysToExpiry":21}', '{"daysToExpiry":{"dir":"MIN","bound":11}}', 'WARNING', '{SO,TA}', true),
    ('UC-SEC-25', 'Truy cập liên tenant', 'AUDIT', 'ENGINE', v_all, '{}', 'WARNING', '{SO,TA}', true),
    ('OFFHOURS-SENSITIVE', 'Truy cập Nhạy cảm ngoài giờ hành chính (luật phụ của PH-13)', 'AUDIT', 'ENGINE', '{"eventsPerDay":5}', '{"eventsPerDay":{"dir":"MAX","bound":10}}', 'WARNING', '{SO}', true),
    ('DENIED-SPIKE', 'Từ chối tăng đột biến theo người thao tác (luật phụ của PH-13)', 'AUDIT', 'ENGINE', '{"deniedPer15m":30}', '{"deniedPer15m":{"dir":"MAX","bound":60}}', 'WARNING', '{SO}', true)
  ) AS k(code, name, source, impl, thr, lim, sev, rcp, can_disable)
  ON CONFLICT (tenant_id, rule_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph13_obs.p_seed_tenant(varchar, varchar) IS 'Nạp cấu hình mặc định, kênh INAPP, 25 luật UC-SEC và 2 luật phụ cho một tenant; ObsProvisioner gọi ở bước S5, S6 (lũy đẳng). Luật theo bản D03-07 §7.5; ngưỡng ở SDD §4.20.';
GRANT EXECUTE ON PROCEDURE ph13_obs.p_seed_tenant(varchar, varchar) TO ph13_obs_app;
-- @rollback DROP PROCEDURE IF EXISTS ph13_obs.p_seed_tenant(varchar, varchar);

RESET ROLE;
