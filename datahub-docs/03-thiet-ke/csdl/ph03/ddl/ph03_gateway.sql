-- =============================================================================
-- D03-03-PH03 · DDL schema ph03_gateway — PH-03 Cổng API (mặt phẳng điều khiển ở dh-connect)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph03_gateway.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Phạm vi: dữ liệu của mặt phẳng điều khiển (route, upstream, consumer, chính sách chiếu từ gói,
-- ngoại lệ WAF, ảnh chụp cấu hình, yêu cầu thay đổi bốn mắt, tham số gw.*...). Mặt phẳng dữ liệu
-- (APISIX) KHÔNG kết nối schema này: nút chỉ đọc ảnh chụp ở bucket/Git và khóa Valkey (SDD §3.4).
-- Không lưu bí mật: không khóa riêng chứng thư, không client_secret, không khóa API dạng rõ (BR-03-007,
-- SEC-24); chỉ vân tay, băm và đường dẫn OpenBao.
-- Phân hệ mới, không thay bảng nào của mã hiện tại (repo chưa có schema ph03).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 03-0000-bootstrap.sql
-- @changeset ph03-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph03_owner') THEN
    CREATE ROLE ph03_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph03_app') THEN
    CREATE ROLE ph03_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph03_readonly') THEN
    CREATE ROLE ph03_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph03-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph03_gateway AUTHORIZATION ph03_owner;
COMMENT ON SCHEMA ph03_gateway IS 'PH-03 Cổng API, mặt phẳng điều khiển: route, upstream, consumer, chính sách chiếu từ gói, ngoại lệ WAF, ảnh chụp cấu hình, yêu cầu thay đổi, tham số gw.*. Không có bí mật. dh-connect kết nối bằng dh_connect_app (thành viên ph03_app); APISIX không kết nối.';
GRANT USAGE ON SCHEMA ph03_gateway TO ph03_app, ph03_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph03_gateway CASCADE;

SET ROLE ph03_owner;

-- @changeset ph03-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 03-0001-functions.sql
-- @changeset ph03-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph03_gateway.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_touch();

-- @changeset ph03-0011-fn-rls splitStatements:false
-- Hai mẫu của D03-10, giống PH-04, PH-05: 'P' riêng tenant (dòng COMMON chỉ phiên PLATFORM thấy và ghi);
-- 'S' dùng chung (mọi tenant đọc thêm dòng COMMON, chỉ phiên PLATFORM ghi COMMON).
CREATE OR REPLACE PROCEDURE ph03_gateway.p_enable_rls(p_table regclass, p_mode char)
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
COMMENT ON PROCEDURE ph03_gateway.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph03_gateway.p_enable_rls(regclass, char);

-- @changeset ph03-0013-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm (append-only)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph03_gateway.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng nhật ký (route_state_event).';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_append_only();

-- @changeset ph03-0014-fn-no-delete splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Không xóa cứng dòng của % (xóa mềm hoặc chuyển trạng thái; mã không dùng lại, BR-03-029)', TG_TABLE_NAME
    USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph03_gateway.tg_no_delete() IS 'Chặn DELETE trên bảng có mã bất biến, không dùng lại (BR-03-029).';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_no_delete();

-- @changeset ph03-0015-fn-write-once splitStatements:false
-- Cột liệt kê ở TG_ARGV, khi đã có giá trị thì không đổi được; NULL đi sang có giá trị thì được (ví dụ số phiên bản cấp lúc ký).
CREATE OR REPLACE FUNCTION ph03_gateway.tg_write_once() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
  o jsonb := to_jsonb(OLD);
  n jsonb := to_jsonb(NEW);
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (o -> c) IS NOT NULL AND (o -> c) <> 'null'::jsonb AND (o -> c) IS DISTINCT FROM (n -> c) THEN
      RAISE EXCEPTION 'Cột %.% đã ghi, không được sửa', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph03_gateway.tg_write_once() IS 'Khóa các cột bất biến sau khi đã có giá trị (mã route, mã consumer, nội dung ảnh chụp đã ký).';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_write_once();

-- @changeset ph03-0016-state-transition
-- Bảng tham chiếu kỹ thuật (không tenant, ứng dụng chỉ đọc): các cặp chuyển trạng thái hợp lệ của tám máy trạng thái lưu ở PostgreSQL (SDD §8.1).
CREATE TABLE ph03_gateway.state_transition (
  entity      varchar(32) NOT NULL,
  from_state  varchar(16) NOT NULL,
  to_state    varchar(16) NOT NULL,
  command     varchar(64) NOT NULL,
  note        varchar(255),
  CONSTRAINT pk_state_transition PRIMARY KEY (entity, from_state, to_state),
  CONSTRAINT ck_state_transition_distinct CHECK (from_state <> to_state)
);
COMMENT ON TABLE ph03_gateway.state_transition IS 'Bảng tham chiếu các cặp chuyển trạng thái hợp lệ; trigger tg_state_guard tra bảng này khi UPDATE cột state (FRS §4.3–4.5, SDD §8.1). Thêm cặp là một changeset mới.';
INSERT INTO ph03_gateway.state_transition (entity, from_state, to_state, command, note) VALUES
  ('ROUTE', 'PENDING', 'ACTIVE', 'applied', 'Ảnh chụp chứa route được nút nạp (NodeStateEvaluator)'),
  ('ROUTE', 'ACTIVE', 'STOPPED', 'stop', 'FR-03-036'),
  ('ROUTE', 'STOPPED', 'ACTIVE', 'start', 'FR-03-036'),
  ('ROUTE', 'ACTIVE', 'SUSPENDED', 'suspend', 'FR-03-047'),
  ('ROUTE', 'SUSPENDED', 'ACTIVE', 'resume', 'FR-03-047'),
  ('ROUTE', 'ACTIVE', 'SUNSET', 'sunsetAt', 'FR-03-035; ExpiryScheduler'),
  ('ROUTE', 'STOPPED', 'RETIRED', 'retire', 'PH-02 ngừng dùng'),
  ('ROUTE', 'SUNSET', 'RETIRED', 'retire', 'Quá gw.sunset.retainDays'),
  ('ROUTE', 'PENDING', 'RETIRED', 'retire', 'Mở rộng so với FRS §4.3: API bị gỡ trước khi có ảnh chụp chứa route (Q03-51)'),
  ('CONSUMER', 'ACTIVE', 'SUSPENDED', 'suspend', 'FR-03-046, 047'),
  ('CONSUMER', 'SUSPENDED', 'ACTIVE', 'resume', 'FR-03-046, 047'),
  ('CONSUMER', 'ACTIVE', 'DELETED', 'delete', 'Xóa mềm; không còn đăng ký hiệu lực (ERR-03-017)'),
  ('CONSUMER', 'SUSPENDED', 'DELETED', 'delete', 'Xóa mềm'),
  ('WAF_EXCEPTION', 'REQUESTED', 'ACTIVE', 'approve', 'FR-03-007; người duyệt khác người đề nghị'),
  ('WAF_EXCEPTION', 'REQUESTED', 'REJECTED', 'reject', 'FR-03-007'),
  ('WAF_EXCEPTION', 'ACTIVE', 'EXPIRING', 'warn', 'Còn gw.waf.exception.warnDays ngày'),
  ('WAF_EXCEPTION', 'ACTIVE', 'EXPIRED', 'expire', 'Hết hạn'),
  ('WAF_EXCEPTION', 'EXPIRING', 'EXPIRED', 'expire', 'Hết hạn'),
  ('WAF_EXCEPTION', 'ACTIVE', 'REVOKED', 'revoke', 'SO thu hồi'),
  ('WAF_EXCEPTION', 'EXPIRING', 'REVOKED', 'revoke', 'SO thu hồi'),
  ('WAF_PATCH', 'REQUESTED', 'ACTIVE', 'approve', 'FR-03-008'),
  ('WAF_PATCH', 'REQUESTED', 'REJECTED', 'reject', 'FR-03-008'),
  ('WAF_PATCH', 'ACTIVE', 'EXPIRING', 'warn', 'Cùng quy tắc ngoại lệ WAF'),
  ('WAF_PATCH', 'ACTIVE', 'EXPIRED', 'expire', 'Hết hạn'),
  ('WAF_PATCH', 'EXPIRING', 'EXPIRED', 'expire', 'Hết hạn'),
  ('WAF_PATCH', 'ACTIVE', 'REVOKED', 'revoke', 'SO thu hồi'),
  ('WAF_PATCH', 'EXPIRING', 'REVOKED', 'revoke', 'SO thu hồi'),
  ('SNAPSHOT', 'BUILT', 'REJECTED', 'validate', 'FR-03-040 có lỗi mức LỖI'),
  ('SNAPSHOT', 'BUILT', 'SIGNED', 'sign', 'FR-03-041'),
  ('SNAPSHOT', 'SIGNED', 'PUBLISHED', 'publish', 'FR-03-042'),
  ('SNAPSHOT', 'PUBLISHED', 'APPLIED', 'applied', 'Mọi nút IN_SYNC'),
  ('SNAPSHOT', 'PUBLISHED', 'PARTIAL', 'lagging', 'Có nút chưa nạp quá gw.node.lagSeconds'),
  ('SNAPSHOT', 'PARTIAL', 'APPLIED', 'applied', 'Nút còn lại nạp xong'),
  ('SNAPSHOT', 'APPLIED', 'SUPERSEDED', 'supersede', 'Có bản mới hơn được nạp'),
  ('SNAPSHOT', 'PARTIAL', 'SUPERSEDED', 'supersede', 'Có bản mới hơn'),
  ('SNAPSHOT', 'PUBLISHED', 'SUPERSEDED', 'supersede', 'Mở rộng so với FRS §4.5: bản mới hơn được phát khi chưa có nút báo (Q03-51)'),
  ('CHANGE_REQUEST', 'PENDING', 'APPROVED', 'approve', 'FourEyesGuard'),
  ('CHANGE_REQUEST', 'PENDING', 'REJECTED', 'reject', 'Có ý kiến'),
  ('CHANGE_REQUEST', 'PENDING', 'EXPIRED', 'expire', 'Quá 14 ngày (giả định)'),
  ('EMERGENCY_BLOCK', 'ACTIVE', 'LIFTED', 'resume', 'FR-03-047; có lý do'),
  ('TENANT_REDIRECT', 'ACTIVE', 'ENDED', 'end', 'endAt đến hoặc kết thúc sớm'),
  ('TLS_EXCEPTION', 'ACTIVE', 'ENDED', 'end', 'Đến hạn hoặc thu hồi'),
  ('TENANT_HOLD', 'ACTIVE', 'RELEASED', 'release', 'Bỏ giữ sau quay lui'),
  ('IMPORT_JOB', 'UPLOADED', 'SCANNED', 'scan', 'LegacyBundleScanner'),
  ('IMPORT_JOB', 'UPLOADED', 'FAILED', 'scan', 'Gói hỏng hoặc chứa bí mật (ERR-03-020)'),
  ('IMPORT_JOB', 'SCANNED', 'PROPOSED', 'map', 'Sinh cấu hình nháp'),
  ('IMPORT_JOB', 'PROPOSED', 'APPLIED', 'apply', 'Tạo dữ liệu nguồn ở PH-02, PH-01');
-- @rollback DROP TABLE IF EXISTS ph03_gateway.state_transition;

-- @changeset ph03-0017-fn-state-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_state_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.state IS DISTINCT FROM OLD.state AND NOT EXISTS (
       SELECT 1 FROM ph03_gateway.state_transition t
        WHERE t.entity = TG_ARGV[0] AND t.from_state = OLD.state AND t.to_state = NEW.state) THEN
    RAISE EXCEPTION 'Chuyển trạng thái % → % không hợp lệ cho %', OLD.state, NEW.state, TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph03_gateway.tg_state_guard() IS 'Chặn chuyển trạng thái ngoài bảng state_transition; TG_ARGV[0] là tên máy trạng thái.';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_state_guard();

-- @file 03-0010-change-request.sql
-- @changeset ph03-0100-change-request
CREATE TABLE ph03_gateway.change_request (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  change_type      varchar(24)   NOT NULL,
  target_type      varchar(12)   NOT NULL,
  target_code      varchar(127)  NOT NULL,
  payload          jsonb         NOT NULL DEFAULT '{}',
  reason           varchar(1000) NOT NULL,
  urgent           boolean       NOT NULL DEFAULT false,
  state            varchar(10)   NOT NULL DEFAULT 'PENDING',
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_note    varchar(1000),
  substitute_approval boolean    NOT NULL DEFAULT false,
  expires_at       timestamptz   NOT NULL DEFAULT (now() + interval '14 days'),
  applied_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_change_request PRIMARY KEY (id),
  CONSTRAINT uq_change_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_change_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_change_request_type CHECK (change_type IN ('WAF_MODE', 'ROUTE_EXPOSURE_EXT', 'TENANT_LIMIT_DECREASE')),
  CONSTRAINT ck_change_request_target CHECK (target_type IN ('TENANT', 'ROUTE')),
  CONSTRAINT ck_change_request_state CHECK (state IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED')),
  CONSTRAINT ck_change_request_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_change_request_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_change_request_decision CHECK ((state IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_change_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_change_request_rejected_note CHECK (state <> 'REJECTED' OR decision_note IS NOT NULL),
  CONSTRAINT ck_change_request_substitute CHECK (NOT substitute_approval OR state = 'APPROVED'),
  CONSTRAINT ck_change_request_applied CHECK (applied_at IS NULL OR state = 'APPROVED')
);
CREATE UNIQUE INDEX uq_change_request_pending ON ph03_gateway.change_request (tenant_id, change_type, target_type, target_code) WHERE state = 'PENDING';
CREATE INDEX ix_change_request_inbox ON ph03_gateway.change_request (tenant_id, state, requested_at DESC);
CREATE INDEX ix_change_request_expiry ON ph03_gateway.change_request (expires_at) WHERE state = 'PENDING';
CREATE TRIGGER tg_change_request_touch BEFORE UPDATE ON ph03_gateway.change_request FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_change_request_state BEFORE UPDATE ON ph03_gateway.change_request FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('CHANGE_REQUEST');
CREATE TRIGGER tg_change_request_once BEFORE UPDATE ON ph03_gateway.change_request FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('change_type', 'target_type', 'target_code', 'requested_by', 'requested_at', 'payload');
CREATE TRIGGER tg_change_request_nodelete BEFORE DELETE ON ph03_gateway.change_request FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.change_request', 'P');
COMMENT ON TABLE ph03_gateway.change_request IS 'EN-03-15 Yêu cầu thay đổi bốn mắt: đổi chế độ WAF, mở route ra cửa Internet, hạ hạn mức toàn tenant (FR-03-006, 023, 038; BR-03-019). Người duyệt khác người đề nghị, so theo tài khoản. Ngoại lệ và luật vá WAF có máy trạng thái riêng.';
COMMENT ON COLUMN ph03_gateway.change_request.target_code IS 'Mã route khi target_type = ROUTE; mã tenant khi TENANT.';
COMMENT ON COLUMN ph03_gateway.change_request.payload IS 'Giá trị mong muốn, ví dụ {"mode":"BLOCK"} hoặc {"perSecond":300}; không chứa bí mật.';
COMMENT ON COLUMN ph03_gateway.change_request.urgent IS 'Hạ WAF về DETECT khi có sự cố cảnh báo giả diện rộng: vẫn bốn mắt nhưng đánh dấu khẩn (FR-03-006).';
COMMENT ON COLUMN ph03_gateway.change_request.substitute_approval IS 'true khi PA duyệt thay vì tenant chỉ có một SO (gw.approval.substitute, Q03-02); kiểm toán ghi "duyệt thay".';
COMMENT ON COLUMN ph03_gateway.change_request.expires_at IS 'Hết hạn chờ sau 14 ngày (giả định, cơ sở: tránh việc treo vô hạn, SDD §8.1).';
COMMENT ON COLUMN ph03_gateway.change_request.applied_at IS 'Thời điểm bộ xử lý (ChangeHandlerRegistry) áp thay đổi; thay đổi chỉ vào gateway khi ảnh chụp mới được nạp.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.change_request CASCADE;

-- @file 03-0020-routing.sql
-- @changeset ph03-0200-edge-host
CREATE TABLE ph03_gateway.edge_host (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  host_pattern     varchar(253)  NOT NULL,
  purpose          varchar(3)    NOT NULL DEFAULT 'API',
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_edge_host PRIMARY KEY (id),
  CONSTRAINT uq_edge_host_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_edge_host_pattern UNIQUE (host_pattern),
  CONSTRAINT ck_edge_host_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_edge_host_pattern CHECK (host_pattern ~ '^(\*\.)?[a-z0-9]([a-z0-9.-]{0,250}[a-z0-9])?$'),
  CONSTRAINT ck_edge_host_purpose CHECK (purpose IN ('API', 'UI')),
  CONSTRAINT ck_edge_host_state CHECK (state IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_edge_host_touch BEFORE UPDATE ON ph03_gateway.edge_host FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_edge_host_once BEFORE UPDATE ON ph03_gateway.edge_host FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('host_pattern', 'tenant_id');
CREATE TRIGGER tg_edge_host_nodelete BEFORE DELETE ON ph03_gateway.edge_host FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.edge_host', 'P');
COMMENT ON TABLE ph03_gateway.edge_host IS 'Gắn host với đúng một tenant (BR-03-026): khóa duy nhất toàn cục trên host_pattern, route chỉ trỏ tới host cùng tenant bằng khóa ngoại kèm tenant_id. Không dùng lại host đã gỡ (BR-03-029). Dẫn xuất từ FR-03-013, 028, 037, 038 (không có EN riêng ở FRS §4.2, đề nghị EN-03-16).';
COMMENT ON COLUMN ph03_gateway.edge_host.host_pattern IS 'Tên miền chữ thường, có thể bắt đầu bằng *. (ví dụ t68.api.datahub.gov.vn).';
COMMENT ON COLUMN ph03_gateway.edge_host.purpose IS 'API: API máy (giới hạn IP gw.ip.apiReqPerSecond, mức hoang tưởng gw.waf.paranoia.api); UI: đường dẫn giao diện.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.edge_host CASCADE;

-- @changeset ph03-0210-upstream
CREATE TABLE ph03_gateway.upstream (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  upstream_code    varchar(127)  NOT NULL,
  name             varchar(255)  NOT NULL,
  scheme           varchar(5)    NOT NULL DEFAULT 'https',
  balancer         varchar(10)   NOT NULL DEFAULT 'roundrobin',
  chash_key        varchar(64),
  tls_verify       boolean       NOT NULL DEFAULT true,
  retries          smallint      NOT NULL DEFAULT 1,
  connect_timeout_ms integer     NOT NULL DEFAULT 3000,
  read_timeout_ms  integer       NOT NULL DEFAULT 10000,
  health_check     jsonb         NOT NULL DEFAULT '{}',
  breaker          jsonb         NOT NULL DEFAULT '{}',
  retired_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_upstream PRIMARY KEY (id),
  CONSTRAINT uq_upstream_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_upstream_code UNIQUE (tenant_id, upstream_code),
  CONSTRAINT ck_upstream_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_upstream_code CHECK (upstream_code ~ '^[a-z][a-z0-9.-]{2,126}$'),
  CONSTRAINT ck_upstream_scheme CHECK (scheme IN ('http', 'https', 'grpc')),
  CONSTRAINT ck_upstream_balancer CHECK (balancer IN ('roundrobin', 'chash')),
  CONSTRAINT ck_upstream_chash CHECK ((balancer = 'chash') = (chash_key IS NOT NULL)),
  CONSTRAINT ck_upstream_retries CHECK (retries BETWEEN 0 AND 5),
  CONSTRAINT ck_upstream_timeouts CHECK (connect_timeout_ms BETWEEN 100 AND 30000 AND read_timeout_ms BETWEEN 100 AND 30000),
  CONSTRAINT ck_upstream_health_check CHECK (jsonb_typeof(health_check) = 'object'),
  CONSTRAINT ck_upstream_breaker CHECK (jsonb_typeof(breaker) = 'object')
);
CREATE TRIGGER tg_upstream_touch BEFORE UPDATE ON ph03_gateway.upstream FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.upstream', 'P');
COMMENT ON TABLE ph03_gateway.upstream IS 'EN-03-02 Upstream: nhóm backend dùng chung cho nhiều route (FR-03-029, 030, 031). Thời hạn chờ tối đa 30.000 ms (CV 631).';
COMMENT ON COLUMN ph03_gateway.upstream.health_check IS 'Kiểm tra sức khỏe: {"active":{"path":"/health","intervalSeconds":5,"timeoutMs":1000,"healthyStatuses":[200]},"passive":{"failures":3,"statuses":[500,502,503,504]},"failThreshold":3,"successThreshold":2}.';
COMMENT ON COLUMN ph03_gateway.upstream.breaker IS 'Ngắt mạch: {"failures":5,"openSeconds":10,"halfOpenProbes":1,"unhealthyStatuses":[500,502,503,504]} (FR-03-031).';
COMMENT ON COLUMN ph03_gateway.upstream.chash_key IS 'Khóa băm khi balancer = chash (route cần dính phiên), ví dụ header:x-session.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.upstream CASCADE;

-- @changeset ph03-0211-upstream-node
CREATE TABLE ph03_gateway.upstream_node (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  upstream_id      uuid          NOT NULL,
  host             varchar(253)  NOT NULL,
  port             integer       NOT NULL,
  weight           integer       NOT NULL DEFAULT 1,
  enabled          boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_upstream_node PRIMARY KEY (id),
  CONSTRAINT uq_upstream_node UNIQUE (tenant_id, upstream_id, host, port),
  CONSTRAINT fk_upstream_node_upstream FOREIGN KEY (upstream_id, tenant_id) REFERENCES ph03_gateway.upstream (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_upstream_node_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_upstream_node_port CHECK (port BETWEEN 1 AND 65535),
  CONSTRAINT ck_upstream_node_weight CHECK (weight BETWEEN 0 AND 100),
  CONSTRAINT ck_upstream_node_host CHECK (host ~ '^[A-Za-z0-9]([A-Za-z0-9.:-]{0,250}[A-Za-z0-9])?$'),
  CONSTRAINT ck_upstream_node_host_safe CHECK (lower(host) !~ '^(localhost|127\.|0\.0\.0\.0|169\.254\.|::1$|0:0:0:0:0:0:0:1$)')
);
CREATE TRIGGER tg_upstream_node_touch BEFORE UPDATE ON ph03_gateway.upstream_node FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.upstream_node', 'P');
COMMENT ON TABLE ph03_gateway.upstream_node IS 'EN-03-02 (nút của upstream): địa chỉ, cổng, trọng số. Chặn địa chỉ loopback và link-local ở CSDL như lớp thứ hai của CHK-10 (chống SSRF, SEC-43); dải quản trị Z7 do bộ kiểm tra ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.upstream_node CASCADE;

-- @changeset ph03-0220-route
CREATE TABLE ph03_gateway.route (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  route_code       varchar(127)  NOT NULL,
  api_code         varchar(127)  NOT NULL,
  api_version      varchar(8)    NOT NULL,
  host_id          uuid          NOT NULL,
  path_pattern     varchar(512)  NOT NULL,
  methods          varchar(7)[]  NOT NULL,
  priority         integer       NOT NULL DEFAULT 0,
  exposure         varchar(3)    NOT NULL DEFAULT 'INT',
  exposure_request_id uuid,
  ip_allow_cidrs   cidr[]        NOT NULL DEFAULT '{}',
  upstream_id      uuid          NOT NULL,
  policy_set_code  varchar(64),
  data_class       varchar(10)   NOT NULL,
  required_scopes  varchar(64)[] NOT NULL DEFAULT '{}',
  require_mtls     boolean       NOT NULL DEFAULT false,
  body_max_bytes   integer       NOT NULL DEFAULT 1048576,
  waf_paranoia     smallint,
  cors             jsonb         NOT NULL DEFAULT '{}',
  openapi_ref      varchar(255),
  opa_policy       varchar(255),
  critical         boolean       NOT NULL DEFAULT false,
  deprecated_at    timestamptz,
  sunset_at        timestamptz,
  successor_route_code varchar(127),
  state            varchar(10)   NOT NULL DEFAULT 'PENDING',
  state_reason     varchar(500),
  state_changed_at timestamptz   NOT NULL DEFAULT now(),
  state_changed_by varchar(64),
  source_version   bigint        NOT NULL DEFAULT 0,
  retired_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_route PRIMARY KEY (id),
  CONSTRAINT uq_route_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_route_code UNIQUE (tenant_id, route_code),
  CONSTRAINT fk_route_host FOREIGN KEY (host_id, tenant_id) REFERENCES ph03_gateway.edge_host (id, tenant_id),
  CONSTRAINT fk_route_upstream FOREIGN KEY (upstream_id, tenant_id) REFERENCES ph03_gateway.upstream (id, tenant_id),
  CONSTRAINT fk_route_exposure_request FOREIGN KEY (exposure_request_id, tenant_id) REFERENCES ph03_gateway.change_request (id, tenant_id),
  CONSTRAINT ck_route_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_route_code CHECK (route_code ~ '^[a-z][a-z0-9-]*(\.[a-z0-9-]+)*\.v[0-9]{1,3}$'),
  CONSTRAINT ck_route_api_version CHECK (api_version ~ '^v[0-9]{1,3}$'),
  CONSTRAINT ck_route_path CHECK (path_pattern ~ '^/[^ ]*$'),
  CONSTRAINT ck_route_methods CHECK (cardinality(methods) BETWEEN 1 AND 9 AND methods <@ ARRAY['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS', 'CONNECT', 'TRACE']::varchar[]),
  CONSTRAINT ck_route_priority CHECK (priority BETWEEN 0 AND 1000),
  CONSTRAINT ck_route_exposure CHECK (exposure IN ('INT', 'EXT')),
  CONSTRAINT ck_route_exposure_ext CHECK (exposure = 'INT' OR exposure_request_id IS NOT NULL),
  CONSTRAINT ck_route_ip_allow CHECK (cardinality(ip_allow_cidrs) = 0 OR exposure = 'EXT'),
  CONSTRAINT ck_route_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_route_sensitive_mtls CHECK (data_class <> 'SENSITIVE' OR require_mtls),
  CONSTRAINT ck_route_scopes CHECK (cardinality(required_scopes) <= 20),
  CONSTRAINT ck_route_body CHECK (body_max_bytes BETWEEN 1024 AND 10485760),
  CONSTRAINT ck_route_paranoia CHECK (waf_paranoia IS NULL OR waf_paranoia BETWEEN 1 AND 3),
  CONSTRAINT ck_route_cors CHECK (jsonb_typeof(cors) = 'object' AND NOT (coalesce(cors -> 'allowedOrigins', '[]'::jsonb) ? '*')),
  CONSTRAINT ck_route_state CHECK (state IN ('PENDING', 'ACTIVE', 'STOPPED', 'SUSPENDED', 'SUNSET', 'RETIRED')),
  CONSTRAINT ck_route_state_reason CHECK (state NOT IN ('STOPPED', 'SUSPENDED') OR coalesce(char_length(state_reason), 0) BETWEEN 10 AND 500),
  CONSTRAINT ck_route_retired CHECK ((state = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_route_sunset CHECK (sunset_at IS NULL OR deprecated_at IS NULL OR sunset_at >= deprecated_at + interval '180 days'),
  CONSTRAINT ck_route_sunset_state CHECK (state <> 'SUNSET' OR sunset_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_route_host_path ON ph03_gateway.route (host_id, path_pattern, methods) WHERE state <> 'RETIRED';
CREATE INDEX ix_route_state ON ph03_gateway.route (tenant_id, state);
CREATE INDEX ix_route_api ON ph03_gateway.route (tenant_id, api_code, api_version);
CREATE INDEX ix_route_upstream ON ph03_gateway.route (tenant_id, upstream_id);
CREATE INDEX ix_route_ext ON ph03_gateway.route (tenant_id) WHERE exposure = 'EXT' AND state <> 'RETIRED';
CREATE INDEX ix_route_sunset ON ph03_gateway.route (sunset_at) WHERE sunset_at IS NOT NULL AND state = 'ACTIVE';
CREATE TRIGGER tg_route_touch BEFORE UPDATE ON ph03_gateway.route FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_route_state BEFORE UPDATE ON ph03_gateway.route FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('ROUTE');
CREATE TRIGGER tg_route_once BEFORE UPDATE ON ph03_gateway.route FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('route_code', 'api_code', 'api_version', 'host_id');
CREATE TRIGGER tg_route_nodelete BEFORE DELETE ON ph03_gateway.route FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.route', 'P');
COMMENT ON TABLE ph03_gateway.route IS 'EN-03-01 Route: trạng thái thực thi của một API đã công bố ở PH-02 (FR-03-028, 035, 036, 038, 039). Mã bất biến, không dùng lại kể cả khi RETIRED (BR-03-029); chuyển trạng thái theo bảng state_transition.';
COMMENT ON COLUMN ph03_gateway.route.route_code IS 'Mã API ở PH-02 kèm phiên bản, ví dụ tra-cuu-cong-dan.v1; duy nhất trong tenant.';
COMMENT ON COLUMN ph03_gateway.route.path_pattern IS 'Mẫu đường dẫn đã chuẩn hóa, ví dụ /ho-tich/v1/*; hai route cùng host, đường dẫn, phương thức không cùng tồn tại (CHK-05).';
COMMENT ON COLUMN ph03_gateway.route.exposure IS 'INT: chỉ nạp ở apisix-int; EXT: nạp thêm ở apisix-ext, chỉ khi có yêu cầu thay đổi ROUTE_EXPOSURE_EXT đã duyệt (BR-03-015, trigger tg_route_ext_guard).';
COMMENT ON COLUMN ph03_gateway.route.exposure_request_id IS 'Yêu cầu thay đổi đã duyệt cho việc mở ra Internet; bắt buộc khi exposure = EXT.';
COMMENT ON COLUMN ph03_gateway.route.ip_allow_cidrs IS 'Dải IP cố định được phép khi route EXT (ví dụ dải nhà cung cấp thanh toán); đi vào dh-ip-block của route.';
COMMENT ON COLUMN ph03_gateway.route.data_class IS 'Mức phân loại dữ liệu của API (SEC-24): SENSITIVE bắt buộc require_mtls (BR-03-004).';
COMMENT ON COLUMN ph03_gateway.route.cors IS '{"allowedOrigins":[...],"allowedMethods":[...],"allowedHeaders":[...],"exposedHeaders":[...],"allowCredentials":false,"maxAgeSeconds":600}; cấm ký tự đại diện * ở allowedOrigins (BR-03-012).';
COMMENT ON COLUMN ph03_gateway.route.openapi_ref IS 'Tham chiếu lược đồ OpenAPI đã duyệt ở PH-02 (CHK-02); thiếu thì route không được phát (BR-03-014).';
COMMENT ON COLUMN ph03_gateway.route.opa_policy IS 'Gói chính sách OPA, ví dụ dh/authz/ho_tich/allow (CHK-03).';
COMMENT ON COLUMN ph03_gateway.route.critical IS 'API quan trọng: có kiểm tra tổng hợp mỗi phút (FR-03-053).';
COMMENT ON COLUMN ph03_gateway.route.sunset_at IS 'Ngày kết thúc phiên bản; cách deprecated_at tối thiểu 180 ngày (BR-03-030, CHK-11).';
COMMENT ON COLUMN ph03_gateway.route.state_reason IS 'Lý do 10…500 ký tự khi STOPPED hoặc SUSPENDED (FR-03-036, 047).';
COMMENT ON COLUMN ph03_gateway.route.source_version IS 'Phiên bản bản ghi nguồn ở PH-02 đã chiếu vào; lũy đẳng khi nhận lại sự kiện cũ.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.route CASCADE;

-- @changeset ph03-0221-route-ext-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_route_ext_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.exposure = 'EXT' AND (TG_OP = 'INSERT' OR OLD.exposure IS DISTINCT FROM 'EXT'
                               OR OLD.exposure_request_id IS DISTINCT FROM NEW.exposure_request_id) THEN
    IF NOT EXISTS (SELECT 1 FROM ph03_gateway.change_request c
                    WHERE c.id = NEW.exposure_request_id AND c.tenant_id = NEW.tenant_id
                      AND c.change_type = 'ROUTE_EXPOSURE_EXT' AND c.state = 'APPROVED'
                      AND c.target_type = 'ROUTE' AND c.target_code = NEW.route_code) THEN
      RAISE EXCEPTION 'Mở route % ra cửa Internet cần yêu cầu thay đổi ROUTE_EXPOSURE_EXT đã duyệt (BR-03-015)', NEW.route_code
        USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_route_ext_guard BEFORE INSERT OR UPDATE OF exposure, exposure_request_id ON ph03_gateway.route FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_route_ext_guard();
COMMENT ON FUNCTION ph03_gateway.tg_route_ext_guard() IS 'Route EXT phải trỏ tới yêu cầu thay đổi ROUTE_EXPOSURE_EXT trạng thái APPROVED của đúng route (BR-03-015, BR-03-019).';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_route_ext_guard() CASCADE;

-- @changeset ph03-0222-route-state-event
CREATE TABLE ph03_gateway.route_state_event (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  route_id         uuid          NOT NULL,
  from_state       varchar(10),
  to_state         varchar(10)   NOT NULL,
  reason           varchar(500),
  actor            varchar(64)   NOT NULL,
  source           varchar(10)   NOT NULL DEFAULT 'API',
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_route_state_event PRIMARY KEY (id),
  CONSTRAINT fk_route_state_event_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT ck_route_state_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_route_state_event_state CHECK (to_state IN ('PENDING', 'ACTIVE', 'STOPPED', 'SUSPENDED', 'SUNSET', 'RETIRED')),
  CONSTRAINT ck_route_state_event_source CHECK (source IN ('API', 'SYSTEM', 'SNAPSHOT', 'IMPORT')),
  CONSTRAINT ck_route_state_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_route_state_event_route ON ph03_gateway.route_state_event (tenant_id, route_id, occurred_at DESC);
CREATE TRIGGER tg_route_state_event_append BEFORE UPDATE OR DELETE ON ph03_gateway.route_state_event FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_append_only();
CALL ph03_gateway.p_enable_rls('ph03_gateway.route_state_event', 'P');
COMMENT ON TABLE ph03_gateway.route_state_event IS 'Lịch sử trạng thái thực thi của route, chỉ thêm (UI-03-02, FR-03-036, 047). Bản kiểm toán đầy đủ đi qua outbox tới PH-13; bảng này phục vụ hiển thị nhanh.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.route_state_event CASCADE;

-- @file 03-0030-consumer.sql
-- @changeset ph03-0300-consumer
CREATE TABLE ph03_gateway.consumer (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  consumer_code    varchar(63)   NOT NULL,
  system_code      varchar(64)   NOT NULL,
  auth_method      varchar(8)    NOT NULL,
  priority_group   varchar(9)    NOT NULL DEFAULT 'NORMAL',
  trusted_source   boolean       NOT NULL DEFAULT false,
  trusted_approved_by varchar(64),
  state            varchar(9)    NOT NULL DEFAULT 'ACTIVE',
  state_reason     varchar(500),
  consumer_version integer       NOT NULL DEFAULT 1,
  legacy_ref       varchar(255),
  deleted_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_consumer PRIMARY KEY (id),
  CONSTRAINT uq_consumer_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_consumer_code UNIQUE (tenant_id, consumer_code),
  CONSTRAINT ck_consumer_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_consumer_code CHECK (consumer_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_consumer_auth CHECK (auth_method IN ('OAUTH2', 'MTLS', 'API_KEY')),
  CONSTRAINT ck_consumer_priority CHECK (priority_group IN ('ESSENTIAL', 'NORMAL', 'LOW')),
  CONSTRAINT ck_consumer_trusted CHECK (NOT trusted_source OR trusted_approved_by IS NOT NULL),
  CONSTRAINT ck_consumer_state CHECK (state IN ('ACTIVE', 'SUSPENDED', 'DELETED')),
  CONSTRAINT ck_consumer_deleted CHECK ((state = 'DELETED') = (deleted_at IS NOT NULL)),
  CONSTRAINT ck_consumer_version CHECK (consumer_version >= 1)
);
CREATE INDEX ix_consumer_system ON ph03_gateway.consumer (tenant_id, system_code);
CREATE INDEX ix_consumer_state ON ph03_gateway.consumer (tenant_id, state);
CREATE TRIGGER tg_consumer_touch BEFORE UPDATE ON ph03_gateway.consumer FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_consumer_state BEFORE UPDATE ON ph03_gateway.consumer FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('CONSUMER');
CREATE TRIGGER tg_consumer_once BEFORE UPDATE ON ph03_gateway.consumer FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('consumer_code', 'system_code');
CREATE TRIGGER tg_consumer_nodelete BEFORE DELETE ON ph03_gateway.consumer FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.consumer', 'P');
COMMENT ON TABLE ph03_gateway.consumer IS 'EN-03-03 Consumer: hình chiếu trên gateway của một client của HTTT (FR-03-046). Không có trường bí mật (SEC-24); mã trùng clientId ở Keycloak, bất biến và không dùng lại (BR-03-029).';
COMMENT ON COLUMN ph03_gateway.consumer.system_code IS 'Mã HTTT ở PH-01 (bản sao); không khóa ngoại vì khác schema, kiểm ở dịch vụ.';
COMMENT ON COLUMN ph03_gateway.consumer.priority_group IS 'ESSENTIAL được nới tần suất và không bị điều tiết khi backend yếu (BR-03-009).';
COMMENT ON COLUMN ph03_gateway.consumer.trusted_source IS 'true miễn giới hạn theo IP (gw.ip.trustedCidrs); chỉ SO duyệt, bắt buộc có trusted_approved_by.';
COMMENT ON COLUMN ph03_gateway.consumer.consumer_version IS 'Tăng mỗi lần ghi consumer hoặc thông tin xác thực công khai; NodeStateEvaluator so với builtFrom để tính syncState cho saga (SDD §4.13).';
COMMENT ON COLUMN ph03_gateway.consumer.legacy_ref IS 'Vị trí trong gateway cũ khi tạo từ nhập hệ cũ (FR-03-059).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.consumer CASCADE;

-- @changeset ph03-0310-consumer-credential
CREATE TABLE ph03_gateway.consumer_credential (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  consumer_id      uuid          NOT NULL,
  kind             varchar(8)    NOT NULL,
  slot             smallint      NOT NULL DEFAULT 1,
  cert_thumbprint  char(64),
  cert_subject     varchar(255),
  cert_not_after   timestamptz,
  api_key_hash     char(64),
  api_key_not_after timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_consumer_credential PRIMARY KEY (id),
  CONSTRAINT uq_consumer_credential_slot UNIQUE (tenant_id, consumer_id, kind, slot),
  CONSTRAINT fk_consumer_credential_consumer FOREIGN KEY (consumer_id, tenant_id) REFERENCES ph03_gateway.consumer (id, tenant_id),
  CONSTRAINT ck_consumer_credential_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_consumer_credential_kind CHECK (kind IN ('CERT', 'API_KEY')),
  CONSTRAINT ck_consumer_credential_slot CHECK (slot BETWEEN 1 AND 2),
  CONSTRAINT ck_consumer_credential_cert CHECK (kind <> 'CERT' OR (cert_thumbprint ~ '^[0-9a-f]{64}$' AND cert_not_after IS NOT NULL AND api_key_hash IS NULL AND api_key_not_after IS NULL)),
  CONSTRAINT ck_consumer_credential_key CHECK (kind <> 'API_KEY' OR (api_key_hash ~ '^[0-9a-f]{64}$' AND api_key_not_after IS NOT NULL AND cert_thumbprint IS NULL AND cert_not_after IS NULL AND cert_subject IS NULL)),
  CONSTRAINT ck_consumer_credential_key_ttl CHECK (api_key_not_after IS NULL OR api_key_not_after <= created_at + interval '180 days')
);
CREATE UNIQUE INDEX uq_consumer_credential_thumb ON ph03_gateway.consumer_credential (cert_thumbprint) WHERE cert_thumbprint IS NOT NULL;
CREATE UNIQUE INDEX uq_consumer_credential_keyhash ON ph03_gateway.consumer_credential (api_key_hash) WHERE api_key_hash IS NOT NULL;
CREATE INDEX ix_consumer_credential_expiry ON ph03_gateway.consumer_credential (least(cert_not_after, api_key_not_after));
CREATE TRIGGER tg_consumer_credential_touch BEFORE UPDATE ON ph03_gateway.consumer_credential FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.consumer_credential', 'P');
COMMENT ON TABLE ph03_gateway.consumer_credential IS 'EN-03-04 Thông tin xác thực công khai của consumer: vân tay chứng thư (tối đa 2 ô khi xoay) hoặc băm khóa API cho giai đoạn chuyển đổi (SEC-24). Không lưu khóa dạng rõ, không lưu client_secret (FR-03-046).';
COMMENT ON COLUMN ph03_gateway.consumer_credential.cert_thumbprint IS 'SHA-256 dạng hex 64 ký tự của chứng thư khách; duy nhất toàn cục vì gateway tra theo vân tay (FR-03-014).';
COMMENT ON COLUMN ph03_gateway.consumer_credential.api_key_hash IS 'SHA-256 hex của khóa API; hạn tối đa 180 ngày kể từ lúc tạo.';
COMMENT ON COLUMN ph03_gateway.consumer_credential.slot IS 'Ô 1 hoặc 2: tối đa hai vân tay cùng lúc khi xoay chứng thư (vân tay thứ ba bị từ chối).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.consumer_credential CASCADE;

-- @changeset ph03-0320-idempotency-key
CREATE TABLE ph03_gateway.idempotency_key (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  operation        varchar(64)   NOT NULL,
  idem_key         varchar(128)  NOT NULL,
  request_hash     char(64)      NOT NULL,
  response_status  smallint      NOT NULL,
  response_body    jsonb,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  expires_at       timestamptz   NOT NULL DEFAULT (now() + interval '24 hours'),
  CONSTRAINT pk_idempotency_key PRIMARY KEY (id),
  CONSTRAINT uq_idempotency_key UNIQUE (tenant_id, operation, idem_key),
  CONSTRAINT ck_idempotency_key_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_idempotency_key_status CHECK (response_status BETWEEN 100 AND 599),
  CONSTRAINT ck_idempotency_key_expiry CHECK (expires_at > created_at AND expires_at <= created_at + interval '48 hours'),
  CONSTRAINT ck_idempotency_key_no_secret CHECK (response_body IS NULL OR NOT (response_body ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'privateKey']))
);
CREATE INDEX ix_idempotency_key_expiry ON ph03_gateway.idempotency_key (expires_at);
CALL ph03_gateway.p_enable_rls('ph03_gateway.idempotency_key', 'P');
COMMENT ON TABLE ph03_gateway.idempotency_key IS 'Khóa lũy đẳng của lệnh ghi consumer (Idempotency-Key, giữ 24 giờ): cùng khóa cùng thân trả đúng phản hồi cũ, cùng khóa khác thân trả ERR-03-003 (SDD §4.13). Saga PH-01 thử lại không sinh bản sao.';
COMMENT ON COLUMN ph03_gateway.idempotency_key.request_hash IS 'SHA-256 hex của thân đã chuẩn hóa.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.idempotency_key CASCADE;

-- @changeset ph03-0330-revoked-token
CREATE TABLE ph03_gateway.revoked_token (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(3)    NOT NULL,
  jti              varchar(128),
  sub              varchar(128),
  not_before       timestamptz,
  token_expires_at timestamptz   NOT NULL,
  reason           varchar(500)  NOT NULL,
  revoked_by       varchar(64)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_revoked_token PRIMARY KEY (id),
  CONSTRAINT ck_revoked_token_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_revoked_token_kind CHECK (kind IN ('JTI', 'SUB')),
  CONSTRAINT ck_revoked_token_fields CHECK ((kind = 'JTI' AND jti IS NOT NULL AND sub IS NULL AND not_before IS NULL)
                                         OR (kind = 'SUB' AND sub IS NOT NULL AND jti IS NULL AND not_before IS NOT NULL)),
  CONSTRAINT ck_revoked_token_reason CHECK (char_length(reason) >= 3),
  CONSTRAINT ck_revoked_token_expiry CHECK (token_expires_at > created_at - interval '1 minute')
);
CREATE UNIQUE INDEX uq_revoked_token_jti ON ph03_gateway.revoked_token (tenant_id, jti) WHERE kind = 'JTI';
CREATE UNIQUE INDEX uq_revoked_token_sub ON ph03_gateway.revoked_token (tenant_id, sub) WHERE kind = 'SUB';
CREATE INDEX ix_revoked_token_expiry ON ph03_gateway.revoked_token (token_expires_at);
CALL ph03_gateway.p_enable_rls('ph03_gateway.revoked_token', 'P');
COMMENT ON TABLE ph03_gateway.revoked_token IS 'Bản ghi bền của thu hồi token để ValkeyRebuilder dựng lại khóa {T}:revoked:* khi Valkey mất (FR-03-018, SDD §4.12). Thu hồi theo jti hoặc theo sub (kèm notBefore). Dọn khi token đã hết hạn cộng 60 giây; chỉ chứa định danh token, không chứa token.';
COMMENT ON COLUMN ph03_gateway.revoked_token.not_before IS 'Với kind = SUB: token của sub có iat nhỏ hơn mốc này bị chặn; token cấp mới sau khi xoay khóa client dùng lại được.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.revoked_token CASCADE;

-- @changeset ph03-0340-emergency-block
CREATE TABLE ph03_gateway.emergency_block (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  target_type      varchar(8)    NOT NULL,
  route_id         uuid,
  consumer_id      uuid,
  target_code      varchar(127)  NOT NULL,
  reason           varchar(500)  NOT NULL,
  state            varchar(6)    NOT NULL DEFAULT 'ACTIVE',
  lifted_by        varchar(64),
  lifted_at        timestamptz,
  lift_reason      varchar(500),
  reminded_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_emergency_block PRIMARY KEY (id),
  CONSTRAINT fk_emergency_block_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT fk_emergency_block_consumer FOREIGN KEY (consumer_id, tenant_id) REFERENCES ph03_gateway.consumer (id, tenant_id),
  CONSTRAINT ck_emergency_block_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_emergency_block_target CHECK (target_type IN ('ROUTE', 'CONSUMER')),
  CONSTRAINT ck_emergency_block_target_ref CHECK ((target_type = 'ROUTE' AND route_id IS NOT NULL AND consumer_id IS NULL)
                                              OR (target_type = 'CONSUMER' AND consumer_id IS NOT NULL AND route_id IS NULL)),
  CONSTRAINT ck_emergency_block_reason CHECK (char_length(reason) BETWEEN 10 AND 500),
  CONSTRAINT ck_emergency_block_state CHECK (state IN ('ACTIVE', 'LIFTED')),
  CONSTRAINT ck_emergency_block_lift CHECK ((state = 'LIFTED') = (lifted_at IS NOT NULL AND lifted_by IS NOT NULL AND coalesce(char_length(lift_reason), 0) >= 10))
);
CREATE UNIQUE INDEX uq_emergency_block_active ON ph03_gateway.emergency_block (tenant_id, target_type, target_code) WHERE state = 'ACTIVE';
CREATE INDEX ix_emergency_block_reminder ON ph03_gateway.emergency_block (created_at) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_emergency_block_touch BEFORE UPDATE ON ph03_gateway.emergency_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_emergency_block_state BEFORE UPDATE ON ph03_gateway.emergency_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('EMERGENCY_BLOCK');
CREATE TRIGGER tg_emergency_block_once BEFORE UPDATE ON ph03_gateway.emergency_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('target_type', 'target_code', 'route_id', 'consumer_id', 'reason');
CREATE TRIGGER tg_emergency_block_nodelete BEFORE DELETE ON ph03_gateway.emergency_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.emergency_block', 'P');
COMMENT ON TABLE ph03_gateway.emergency_block IS 'EN-03-12 Lệnh tạm ngừng khẩn cấp route hoặc consumer (FR-03-047). Một khối đang hoạt động cho mỗi đối tượng; mở lại ghi lifted_at, lifted_by và lý do. Là bản bền của khóa Valkey {T}:kill:* (đường nhanh chỉ để thêm chặn).';
COMMENT ON COLUMN ph03_gateway.emergency_block.reminded_at IS 'Lần nhắc SO và TA gần nhất; sau 4 giờ chưa mở lại thì nhắc (đề xuất Q03-46 của UC).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.emergency_block CASCADE;

-- @file 03-0040-policy.sql
-- @changeset ph03-0400-plan-policy
CREATE TABLE ph03_gateway.plan_policy (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  policy_code      varchar(127)  NOT NULL,
  plan_code        varchar(64)   NOT NULL,
  api_code         varchar(127)  NOT NULL,
  security_mode    varchar(8)    NOT NULL,
  rate_limits      jsonb         NOT NULL DEFAULT '{}',
  quotas           jsonb         NOT NULL DEFAULT '{}',
  path_allow       text[]        NOT NULL DEFAULT '{}',
  path_deny        text[]        NOT NULL DEFAULT '{}',
  state            varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  source_version   bigint        NOT NULL DEFAULT 0,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_plan_policy PRIMARY KEY (id),
  CONSTRAINT uq_plan_policy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_plan_policy_code UNIQUE (tenant_id, policy_code),
  CONSTRAINT ck_plan_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_plan_policy_mode CHECK (security_mode IN ('KEYLESS', 'API_KEY', 'OAUTH2', 'MTLS')),
  CONSTRAINT ck_plan_policy_rate CHECK (jsonb_typeof(rate_limits) = 'object' AND (rate_limits - 'second' - 'minute') = '{}'::jsonb),
  CONSTRAINT ck_plan_policy_quota CHECK (jsonb_typeof(quotas) = 'object' AND (quotas - 'hour' - 'day' - 'month') = '{}'::jsonb),
  CONSTRAINT ck_plan_policy_paths CHECK (cardinality(path_allow) <= 200 AND cardinality(path_deny) <= 200),
  CONSTRAINT ck_plan_policy_state CHECK (state IN ('ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_plan_policy_api ON ph03_gateway.plan_policy (tenant_id, api_code);
CREATE TRIGGER tg_plan_policy_touch BEFORE UPDATE ON ph03_gateway.plan_policy FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.plan_policy', 'P');
COMMENT ON TABLE ph03_gateway.plan_policy IS 'EN-03-05 Chính sách chiếu từ gói sử dụng của PH-02: phương thức bảo mật, hạn mức giây và phút, hạn ngạch giờ, ngày, tháng, danh sách đường dẫn cho phép và chặn (FR-03-015, 020, 021, 022). PH-02 là nguồn sự thật; PH-03 chỉ giữ bản chiếu để sinh cấu hình.';
COMMENT ON COLUMN ph03_gateway.plan_policy.rate_limits IS 'Chỉ khóa second, minute, ví dụ {"second":20,"minute":600} (LGC-APIM-012).';
COMMENT ON COLUMN ph03_gateway.plan_policy.quotas IS 'Chỉ khóa hour, day, month, ví dụ {"hour":20000,"day":200000} (LGC-APIM-013); chỉ để bảo vệ hệ thống và thống kê, không tính tiền (BR-03-020).';
COMMENT ON COLUMN ph03_gateway.plan_policy.security_mode IS 'KEYLESS chỉ cho API dữ liệu mở: kiểm ở CHK-06, không kiểm ở CSDL vì cần data_class của route.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.plan_policy CASCADE;

-- @changeset ph03-0410-subscription-ref
CREATE TABLE ph03_gateway.subscription_ref (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  consumer_id      uuid          NOT NULL,
  route_id         uuid          NOT NULL,
  plan_policy_id   uuid          NOT NULL,
  state            varchar(9)    NOT NULL DEFAULT 'ACTIVE',
  valid_from       timestamptz   NOT NULL DEFAULT now(),
  valid_to         timestamptz,
  source_ref       varchar(64)   NOT NULL,
  source_version   bigint        NOT NULL DEFAULT 0,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_subscription_ref PRIMARY KEY (id),
  CONSTRAINT uq_subscription_ref UNIQUE (tenant_id, consumer_id, route_id),
  CONSTRAINT fk_subscription_ref_consumer FOREIGN KEY (consumer_id, tenant_id) REFERENCES ph03_gateway.consumer (id, tenant_id),
  CONSTRAINT fk_subscription_ref_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT fk_subscription_ref_policy FOREIGN KEY (plan_policy_id, tenant_id) REFERENCES ph03_gateway.plan_policy (id, tenant_id),
  CONSTRAINT ck_subscription_ref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_subscription_ref_state CHECK (state IN ('ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_subscription_ref_window CHECK (valid_to IS NULL OR valid_to > valid_from)
);
CREATE INDEX ix_subscription_ref_route ON ph03_gateway.subscription_ref (tenant_id, route_id, state);
CREATE INDEX ix_subscription_ref_consumer ON ph03_gateway.subscription_ref (tenant_id, consumer_id);
CREATE INDEX ix_subscription_ref_expiry ON ph03_gateway.subscription_ref (valid_to) WHERE valid_to IS NOT NULL AND state = 'ACTIVE';
CREATE TRIGGER tg_subscription_ref_touch BEFORE UPDATE ON ph03_gateway.subscription_ref FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.subscription_ref', 'P');
COMMENT ON TABLE ph03_gateway.subscription_ref IS 'Bản chiếu đăng ký sử dụng của PH-02 (consumer x route x gói) cho FR-03-016: gateway chỉ cho consumer có đăng ký hiệu lực đi qua (dh-auth.allowedConsumers). Hết hạn (valid_to) do ExpiryScheduler chuyển EXPIRED. Dẫn xuất, đề nghị EN-03-17.';
COMMENT ON COLUMN ph03_gateway.subscription_ref.source_ref IS 'Mã đăng ký ở PH-02, khóa lũy đẳng khi nhận lại sự kiện.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.subscription_ref CASCADE;

-- @changeset ph03-0420-rate-limit-override
CREATE TABLE ph03_gateway.rate_limit_override (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  scope            varchar(14)   NOT NULL,
  consumer_id      uuid,
  route_id         uuid,
  window_seconds   integer       NOT NULL,
  limit_value      bigint        NOT NULL,
  burst_percent    smallint      NOT NULL DEFAULT 0,
  reason           varchar(500)  NOT NULL,
  expires_at       timestamptz,
  change_request_id uuid,
  retired_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_rate_limit_override PRIMARY KEY (id),
  CONSTRAINT fk_rate_limit_override_consumer FOREIGN KEY (consumer_id, tenant_id) REFERENCES ph03_gateway.consumer (id, tenant_id),
  CONSTRAINT fk_rate_limit_override_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT fk_rate_limit_override_request FOREIGN KEY (change_request_id, tenant_id) REFERENCES ph03_gateway.change_request (id, tenant_id),
  CONSTRAINT ck_rate_limit_override_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_rate_limit_override_scope CHECK (scope IN ('CONSUMER', 'CONSUMER_ROUTE', 'ROUTE', 'TENANT')),
  CONSTRAINT ck_rate_limit_override_target CHECK (
       (scope = 'CONSUMER'       AND consumer_id IS NOT NULL AND route_id IS NULL)
    OR (scope = 'CONSUMER_ROUTE' AND consumer_id IS NOT NULL AND route_id IS NOT NULL)
    OR (scope = 'ROUTE'          AND consumer_id IS NULL     AND route_id IS NOT NULL)
    OR (scope = 'TENANT'         AND consumer_id IS NULL     AND route_id IS NULL)),
  CONSTRAINT ck_rate_limit_override_window CHECK (window_seconds IN (1, 60, 3600, 86400, 2592000)),
  CONSTRAINT ck_rate_limit_override_tenant_window CHECK (scope <> 'TENANT' OR window_seconds = 1),
  CONSTRAINT ck_rate_limit_override_limit CHECK (limit_value > 0),
  CONSTRAINT ck_rate_limit_override_burst CHECK (burst_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_rate_limit_override_reason CHECK (char_length(reason) >= 10)
);
CREATE UNIQUE INDEX uq_rate_limit_override_live ON ph03_gateway.rate_limit_override (tenant_id, scope, consumer_id, route_id, window_seconds) NULLS NOT DISTINCT WHERE retired_at IS NULL;
CREATE INDEX ix_rate_limit_override_route ON ph03_gateway.rate_limit_override (tenant_id, route_id) WHERE retired_at IS NULL;
CREATE INDEX ix_rate_limit_override_expiry ON ph03_gateway.rate_limit_override (expires_at) WHERE expires_at IS NOT NULL AND retired_at IS NULL;
CREATE TRIGGER tg_rate_limit_override_touch BEFORE UPDATE ON ph03_gateway.rate_limit_override FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_rate_limit_override_nodelete BEFORE DELETE ON ph03_gateway.rate_limit_override FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.rate_limit_override', 'P');
COMMENT ON TABLE ph03_gateway.rate_limit_override IS 'EN-03-06 Ghi đè hạn mức theo bốn phạm vi CONSUMER, CONSUMER_ROUTE, ROUTE, TENANT (FR-03-023, 024). Thứ tự ưu tiên giải ở bộ tổng hợp (SDD §4.4). Hạn mức toàn tenant (scope TENANT, cửa sổ 1 giây) là nơi lưu gw.tenantRateLimit.perSecond và burst; hạ thấp cần change_request đã duyệt (BR-03-019).';
COMMENT ON COLUMN ph03_gateway.rate_limit_override.window_seconds IS '1 giây, 60 giây, 3600 (giờ), 86400 (ngày), 2592000 (tháng 30 ngày).';
COMMENT ON COLUMN ph03_gateway.rate_limit_override.burst_percent IS 'Dung sai đột biến theo phần trăm (gw.tenantRateLimit.burst mặc định 20%).';
COMMENT ON COLUMN ph03_gateway.rate_limit_override.retired_at IS 'Gỡ là xóa mềm (BR-03-029); chỉ một ghi đè đang hiệu lực cho mỗi bộ (phạm vi, consumer, route, cửa sổ).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.rate_limit_override CASCADE;

-- @changeset ph03-0430-policy-template-setting
CREATE TABLE ph03_gateway.policy_template_setting (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  template_code    varchar(64)   NOT NULL,
  template_version varchar(16)   NOT NULL,
  enabled          boolean       NOT NULL DEFAULT true,
  params           jsonb         NOT NULL DEFAULT '{}',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_template_setting PRIMARY KEY (id),
  CONSTRAINT uq_policy_template_setting UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_policy_template_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_policy_template_setting_code CHECK (template_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_policy_template_setting_version CHECK (template_version ~ '^[0-9]+\.[0-9]+(\.[0-9]+)?$'),
  CONSTRAINT ck_policy_template_setting_params CHECK (jsonb_typeof(params) = 'object')
);
CREATE TRIGGER tg_policy_template_setting_touch BEFORE UPDATE ON ph03_gateway.policy_template_setting FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.policy_template_setting', 'P');
COMMENT ON TABLE ph03_gateway.policy_template_setting IS 'Bật, tắt và tham số hóa mẫu chính sách gateway được duyệt sẵn theo tenant (FR-03-048). Danh mục mẫu và plugin cho phép đi cùng bản phát hành (PluginTemplateRegistry), không lưu ở CSDL; không có đường tải plugin hay mã Lua của tenant (BR-03-017). Dẫn xuất, đề nghị EN-03-18.';
COMMENT ON COLUMN ph03_gateway.policy_template_setting.params IS 'Tham số chỉnh trong miền mẫu cho phép: hạn mức mặc định, mức hoang tưởng, thời hạn chờ.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.policy_template_setting CASCADE;

-- @file 03-0050-edge.sql
-- @changeset ph03-0500-waf-exception
CREATE TABLE ph03_gateway.waf_exception (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  route_id         uuid          NOT NULL,
  rule_id          varchar(8)    NOT NULL,
  reason           varchar(1000) NOT NULL,
  state            varchar(9)    NOT NULL DEFAULT 'REQUESTED',
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  approved_by      varchar(64),
  approved_at      timestamptz,
  decision_note    varchar(1000),
  expires_at       timestamptz   NOT NULL,
  expiring_notified_at timestamptz,
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  revoke_reason    varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_waf_exception PRIMARY KEY (id),
  CONSTRAINT fk_waf_exception_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT ck_waf_exception_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_waf_exception_rule CHECK (rule_id ~ '^[0-9]{6,8}$'),
  CONSTRAINT ck_waf_exception_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_waf_exception_state CHECK (state IN ('REQUESTED', 'ACTIVE', 'EXPIRING', 'REJECTED', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_waf_exception_ttl CHECK (expires_at > requested_at AND expires_at <= requested_at + interval '90 days'),
  CONSTRAINT ck_waf_exception_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_waf_exception_approved CHECK (state NOT IN ('ACTIVE', 'EXPIRING') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_waf_exception_rejected CHECK (state <> 'REJECTED' OR (approved_by IS NOT NULL AND decision_note IS NOT NULL)),
  CONSTRAINT ck_waf_exception_revoked CHECK ((state = 'REVOKED') = (revoked_by IS NOT NULL AND revoked_at IS NOT NULL AND coalesce(char_length(revoke_reason), 0) >= 10))
);
CREATE UNIQUE INDEX uq_waf_exception_live ON ph03_gateway.waf_exception (tenant_id, route_id, rule_id) WHERE state IN ('REQUESTED', 'ACTIVE', 'EXPIRING');
CREATE INDEX ix_waf_exception_route ON ph03_gateway.waf_exception (tenant_id, route_id, state);
CREATE INDEX ix_waf_exception_expiry ON ph03_gateway.waf_exception (expires_at) WHERE state IN ('ACTIVE', 'EXPIRING');
CREATE TRIGGER tg_waf_exception_touch BEFORE UPDATE ON ph03_gateway.waf_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_waf_exception_state BEFORE UPDATE ON ph03_gateway.waf_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('WAF_EXCEPTION');
CREATE TRIGGER tg_waf_exception_once BEFORE UPDATE ON ph03_gateway.waf_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('route_id', 'rule_id', 'requested_by', 'requested_at', 'expires_at', 'reason');
CREATE TRIGGER tg_waf_exception_nodelete BEFORE DELETE ON ph03_gateway.waf_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.waf_exception', 'P');
COMMENT ON TABLE ph03_gateway.waf_exception IS 'EN-03-07 Ngoại lệ luật WAF có thời hạn (FR-03-007): bỏ qua một mã luật CRS cho một route. Có lý do, hạn tối đa 90 ngày, người duyệt khác người đề nghị (BR-03-006, BR-03-019); không có ngoại lệ vĩnh viễn, không gia hạn tự động (muốn kéo dài phải đề nghị lại).';
COMMENT ON COLUMN ph03_gateway.waf_exception.rule_id IS 'Mã luật OWASP CRS (6 đến 8 chữ số, ví dụ 942100); tồn tại trong CRS đang dùng do dịch vụ kiểm (ERR-03-009).';
COMMENT ON COLUMN ph03_gateway.waf_exception.expires_at IS 'Hết hạn tuyệt đối, tối đa requested_at + 90 ngày (gw.waf.exception.maxDays có thể đặt thấp hơn); bất biến sau khi đề nghị.';
COMMENT ON COLUMN ph03_gateway.waf_exception.expiring_notified_at IS 'Lần phát EVT-03-06 (còn gw.waf.exception.warnDays ngày).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.waf_exception CASCADE;

-- @changeset ph03-0510-waf-virtual-patch
CREATE TABLE ph03_gateway.waf_virtual_patch (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  patch_code       varchar(64)   NOT NULL,
  scope            varchar(8)    NOT NULL,
  route_id         uuid,
  rule_text        text          NOT NULL,
  reason           varchar(1000) NOT NULL,
  state            varchar(9)    NOT NULL DEFAULT 'REQUESTED',
  requested_by     varchar(64)   NOT NULL,
  requested_at     timestamptz   NOT NULL DEFAULT now(),
  approved_by      varchar(64),
  approved_at      timestamptz,
  decision_note    varchar(1000),
  expires_at       timestamptz   NOT NULL,
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  revoke_reason    varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_waf_virtual_patch PRIMARY KEY (id),
  CONSTRAINT uq_waf_virtual_patch_code UNIQUE (tenant_id, patch_code),
  CONSTRAINT fk_waf_virtual_patch_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT ck_waf_virtual_patch_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_waf_virtual_patch_code CHECK (patch_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_waf_virtual_patch_scope CHECK ((scope = 'PLATFORM' AND tenant_id = 'COMMON' AND route_id IS NULL)
                                            OR (scope = 'TENANT' AND tenant_id <> 'COMMON' AND route_id IS NULL)
                                            OR (scope = 'ROUTE' AND tenant_id <> 'COMMON' AND route_id IS NOT NULL)),
  CONSTRAINT ck_waf_virtual_patch_rule CHECK (char_length(rule_text) BETWEEN 10 AND 4000),
  CONSTRAINT ck_waf_virtual_patch_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_waf_virtual_patch_state CHECK (state IN ('REQUESTED', 'ACTIVE', 'EXPIRING', 'REJECTED', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_waf_virtual_patch_ttl CHECK (expires_at > requested_at AND expires_at <= requested_at + interval '90 days'),
  CONSTRAINT ck_waf_virtual_patch_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_waf_virtual_patch_approved CHECK (state NOT IN ('ACTIVE', 'EXPIRING') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_waf_virtual_patch_revoked CHECK ((state = 'REVOKED') = (revoked_by IS NOT NULL AND revoked_at IS NOT NULL AND coalesce(char_length(revoke_reason), 0) >= 10))
);
CREATE INDEX ix_waf_virtual_patch_live ON ph03_gateway.waf_virtual_patch (tenant_id, state) WHERE state IN ('REQUESTED', 'ACTIVE', 'EXPIRING');
CREATE INDEX ix_waf_virtual_patch_expiry ON ph03_gateway.waf_virtual_patch (expires_at) WHERE state IN ('ACTIVE', 'EXPIRING');
CREATE TRIGGER tg_waf_virtual_patch_touch BEFORE UPDATE ON ph03_gateway.waf_virtual_patch FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_waf_virtual_patch_state BEFORE UPDATE ON ph03_gateway.waf_virtual_patch FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('WAF_PATCH');
CREATE TRIGGER tg_waf_virtual_patch_once BEFORE UPDATE ON ph03_gateway.waf_virtual_patch FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('patch_code', 'scope', 'route_id', 'rule_text', 'requested_by', 'requested_at', 'expires_at');
CREATE TRIGGER tg_waf_virtual_patch_nodelete BEFORE DELETE ON ph03_gateway.waf_virtual_patch FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.waf_virtual_patch', 'S');
COMMENT ON TABLE ph03_gateway.waf_virtual_patch IS 'EN-03-08 Luật vá ảo WAF khẩn cấp khi có lỗ hổng chưa có bản vá (FR-03-008, mức S, Đợt 2). Cùng quy tắc ngoại lệ: lý do, hạn tối đa 90 ngày, bốn mắt. Phạm vi PLATFORM lưu ở tenant COMMON (mọi tenant đọc, chỉ PLATFORM ghi); phạm vi TENANT, ROUTE lưu ở tenant của mình.';
COMMENT ON COLUMN ph03_gateway.waf_virtual_patch.rule_text IS 'Luật SecLang của Coraza, 10…4000 ký tự; được CHK-01 kiểm cú pháp trước khi phát; không chứa dữ liệu bí mật.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.waf_virtual_patch CASCADE;

-- @changeset ph03-0520-waf-mode
CREATE TABLE ph03_gateway.waf_mode (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  scope_kind       varchar(6)    NOT NULL DEFAULT 'TENANT',
  route_id         uuid,
  mode             varchar(6)    NOT NULL DEFAULT 'DETECT',
  detect_since     timestamptz   NOT NULL DEFAULT now(),
  blocked_at       timestamptz,
  change_request_id uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_waf_mode PRIMARY KEY (id),
  CONSTRAINT fk_waf_mode_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT fk_waf_mode_request FOREIGN KEY (change_request_id, tenant_id) REFERENCES ph03_gateway.change_request (id, tenant_id),
  CONSTRAINT ck_waf_mode_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_waf_mode_scope CHECK ((scope_kind = 'TENANT' AND route_id IS NULL) OR (scope_kind = 'ROUTE' AND route_id IS NOT NULL)),
  CONSTRAINT ck_waf_mode_mode CHECK (mode IN ('DETECT', 'BLOCK')),
  CONSTRAINT ck_waf_mode_block CHECK ((mode = 'BLOCK') = (blocked_at IS NOT NULL AND change_request_id IS NOT NULL)),
  CONSTRAINT ck_waf_mode_detect_period CHECK (mode <> 'BLOCK' OR tenant_id ~ '^T9[0-9]$' OR blocked_at >= detect_since + interval '14 days')
);
CREATE UNIQUE INDEX uq_waf_mode_scope ON ph03_gateway.waf_mode (tenant_id, scope_kind, route_id) NULLS NOT DISTINCT;
CREATE TRIGGER tg_waf_mode_touch BEFORE UPDATE ON ph03_gateway.waf_mode FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_waf_mode_nodelete BEFORE DELETE ON ph03_gateway.waf_mode FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.waf_mode', 'P');
COMMENT ON TABLE ph03_gateway.waf_mode IS 'Chế độ WAF theo phạm vi TENANT hoặc một route (gw.waf.mode, FR-03-006). Khóa lưu thật của tham số có bốn mắt: đổi sang BLOCK cần change_request WAF_MODE đã duyệt và đã chạy DETECT liên tục tối thiểu 14 ngày (ERR-03-027; tenant kiểm thử T90…T99 được miễn). Tự hạ ở nút (dh-waf-guard) không đổi bảng này.';
COMMENT ON COLUMN ph03_gateway.waf_mode.detect_since IS 'Bắt đầu chuỗi ngày liên tục ở DETECT của phạm vi; đặt lại khi hạ từ BLOCK về DETECT.';
COMMENT ON COLUMN ph03_gateway.waf_mode.blocked_at IS 'Thời điểm chuyển sang BLOCK; NULL khi DETECT.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.waf_mode CASCADE;

-- @changeset ph03-0521-waf-mode-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph03_gateway.tg_waf_mode_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.mode = 'BLOCK' AND NOT EXISTS (
       SELECT 1 FROM ph03_gateway.change_request c
        WHERE c.id = NEW.change_request_id AND c.tenant_id = NEW.tenant_id
          AND c.change_type = 'WAF_MODE' AND c.state = 'APPROVED') THEN
    RAISE EXCEPTION 'Chuyển WAF sang BLOCK cần yêu cầu thay đổi WAF_MODE đã duyệt (BR-03-019)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_waf_mode_guard BEFORE INSERT OR UPDATE OF mode, change_request_id ON ph03_gateway.waf_mode FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_waf_mode_guard();
COMMENT ON FUNCTION ph03_gateway.tg_waf_mode_guard() IS 'BLOCK phải trỏ tới change_request WAF_MODE trạng thái APPROVED.';
-- @rollback DROP FUNCTION IF EXISTS ph03_gateway.tg_waf_mode_guard() CASCADE;

-- @changeset ph03-0530-ip-block
CREATE TABLE ph03_gateway.ip_block (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  cidr             cidr          NOT NULL,
  source           varchar(6)    NOT NULL,
  reason           varchar(500)  NOT NULL,
  expires_at       timestamptz,
  retired_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_ip_block PRIMARY KEY (id),
  CONSTRAINT ck_ip_block_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_ip_block_source CHECK (source IN ('AUTO', 'MANUAL')),
  CONSTRAINT ck_ip_block_width CHECK ((family(cidr) = 4 AND masklen(cidr) >= 16) OR (family(cidr) = 6 AND masklen(cidr) >= 48)),
  CONSTRAINT ck_ip_block_auto_expiry CHECK (source <> 'AUTO' OR expires_at IS NOT NULL),
  CONSTRAINT ck_ip_block_reason CHECK (char_length(reason) >= 3)
);
CREATE UNIQUE INDEX uq_ip_block_live ON ph03_gateway.ip_block (tenant_id, cidr) WHERE retired_at IS NULL;
CREATE INDEX ix_ip_block_expiry ON ph03_gateway.ip_block (expires_at) WHERE expires_at IS NOT NULL AND retired_at IS NULL;
CREATE TRIGGER tg_ip_block_touch BEFORE UPDATE ON ph03_gateway.ip_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_ip_block_nodelete BEFORE DELETE ON ph03_gateway.ip_block FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.ip_block', 'P');
COMMENT ON TABLE ph03_gateway.ip_block IS 'EN-03-14 Địa chỉ nguồn bị chặn (FR-03-004): danh sách chặn tay do PA, TA khai (đi vào plugin_metadata của dh-ip-block) và bản ghi chặn tự động do nút báo (AUTO có hạn). Chặn tự động chạy cục bộ ở pod, không phụ thuộc kho nào. Không chặn dải rộng hơn /16 (IPv4) hoặc /48 (IPv6) (giả định chống chặn nhầm cả sở).';
COMMENT ON COLUMN ph03_gateway.ip_block.cidr IS 'Dải bị chặn; không thuộc gw.ip.trustedCidrs và dải hạ tầng nền tảng (ERR-03-024, kiểm ở dịch vụ).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.ip_block CASCADE;

-- @changeset ph03-0540-edge-certificate
CREATE TABLE ph03_gateway.edge_certificate (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  cert_code        varchar(64)   NOT NULL,
  subject          varchar(255)  NOT NULL,
  hosts            varchar(253)[] NOT NULL,
  issuer           varchar(255)  NOT NULL,
  fingerprint      char(64)      NOT NULL,
  not_before       timestamptz   NOT NULL,
  not_after        timestamptz   NOT NULL,
  source           varchar(12)   NOT NULL,
  secret_ref       varchar(255)  NOT NULL,
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  warned_30d_at    timestamptz,
  warned_7d_at     timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_edge_certificate PRIMARY KEY (id),
  CONSTRAINT uq_edge_certificate_code UNIQUE (tenant_id, cert_code),
  CONSTRAINT uq_edge_certificate_fp UNIQUE (tenant_id, fingerprint),
  CONSTRAINT ck_edge_certificate_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_edge_certificate_code CHECK (cert_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_edge_certificate_hosts CHECK (cardinality(hosts) BETWEEN 1 AND 100),
  CONSTRAINT ck_edge_certificate_fp CHECK (fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_edge_certificate_validity CHECK (not_after > not_before),
  CONSTRAINT ck_edge_certificate_source CHECK (source IN ('CERT_MANAGER', 'MANUAL')),
  CONSTRAINT ck_edge_certificate_state CHECK (state IN ('ACTIVE', 'EXPIRING', 'EXPIRED', 'REPLACED')),
  CONSTRAINT ck_edge_certificate_ref CHECK (secret_ref ~ '^[A-Za-z0-9/_.{}-]+$' AND secret_ref NOT ILIKE '%PRIVATE%')
);
CREATE INDEX ix_edge_certificate_expiry ON ph03_gateway.edge_certificate (not_after) WHERE state IN ('ACTIVE', 'EXPIRING');
CREATE TRIGGER tg_edge_certificate_touch BEFORE UPDATE ON ph03_gateway.edge_certificate FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_edge_certificate_once BEFORE UPDATE ON ph03_gateway.edge_certificate FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('cert_code', 'fingerprint', 'not_after', 'secret_ref');
CALL ph03_gateway.p_enable_rls('ph03_gateway.edge_certificate', 'S');
COMMENT ON TABLE ph03_gateway.edge_certificate IS 'EN-03-11 Siêu dữ liệu chứng thư TLS biên (FR-03-049): chủ thể, host, hạn, vân tay, nhà phát hành. Khóa riêng chỉ ở OpenBao (secret_ref là đường dẫn, không phải khóa). Chứng thư dùng chung (ví dụ *.datahub.gov.vn) ở tenant COMMON, mọi tenant đọc, chỉ PLATFORM ghi. Gia hạn thay bằng chứng thư mới và đánh REPLACED, không sửa vân tay.';
COMMENT ON COLUMN ph03_gateway.edge_certificate.secret_ref IS 'Đường dẫn OpenBao hoặc tên Secret chứa khóa riêng, ví dụ kv/dh/common/edge-cert/wildcard; bị chặn nếu chứa chữ PRIVATE (phòng dán nhầm khóa).';
COMMENT ON COLUMN ph03_gateway.edge_certificate.warned_30d_at IS 'Lần phát EVT-03-08 mức Cao (còn dưới 30 ngày); 7 ngày là mức Nghiêm trọng (warned_7d_at).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.edge_certificate CASCADE;

-- @changeset ph03-0541-client-ca
CREATE TABLE ph03_gateway.client_ca (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  ca_code          varchar(64)   NOT NULL,
  subject          varchar(255)  NOT NULL,
  fingerprint      char(64)      NOT NULL,
  not_after        timestamptz   NOT NULL,
  public_pem       text          NOT NULL,
  crl_url          varchar(512),
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_client_ca PRIMARY KEY (id),
  CONSTRAINT uq_client_ca_code UNIQUE (tenant_id, ca_code),
  CONSTRAINT uq_client_ca_fp UNIQUE (tenant_id, fingerprint),
  CONSTRAINT ck_client_ca_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_client_ca_code CHECK (ca_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_client_ca_fp CHECK (fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_client_ca_pem CHECK (public_pem LIKE '-----BEGIN CERTIFICATE-----%' AND public_pem NOT ILIKE '%PRIVATE KEY%'),
  CONSTRAINT ck_client_ca_crl CHECK (crl_url IS NULL OR crl_url ~ '^https?://'),
  CONSTRAINT ck_client_ca_state CHECK (state IN ('ACTIVE', 'DISABLED', 'EXPIRED'))
);
CREATE TRIGGER tg_client_ca_touch BEFORE UPDATE ON ph03_gateway.client_ca FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_client_ca_once BEFORE UPDATE ON ph03_gateway.client_ca FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('ca_code', 'fingerprint', 'public_pem');
CALL ph03_gateway.p_enable_rls('ph03_gateway.client_ca', 'S');
COMMENT ON TABLE ph03_gateway.client_ca IS 'Bộ CA tin cậy để xác minh chứng thư khách mTLS (FR-03-002, FR-03-049 bước 6): CA HTTT của Datahub (OpenBao PKI) ở COMMON, CA do tỉnh chấp nhận ở tenant. Chỉ chứa chứng thư công khai của CA; thay đổi bộ CA đi theo ảnh chụp có kiểm tra hợp lệ. Dẫn xuất, đề nghị EN-03-19.';
COMMENT ON COLUMN ph03_gateway.client_ca.public_pem IS 'Chứng thư CA dạng PEM (công khai); bị chặn nếu chứa PRIVATE KEY.';
COMMENT ON COLUMN ph03_gateway.client_ca.crl_url IS 'Địa chỉ CRL làm mới mỗi giờ (FR-03-002).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.client_ca CASCADE;

-- @changeset ph03-0550-tls-exception
CREATE TABLE ph03_gateway.tls_exception (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  host_id          uuid          NOT NULL,
  reason           varchar(1000) NOT NULL,
  state            varchar(6)    NOT NULL DEFAULT 'ACTIVE',
  expires_at       timestamptz   NOT NULL,
  ended_by         varchar(64),
  ended_at         timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tls_exception PRIMARY KEY (id),
  CONSTRAINT fk_tls_exception_host FOREIGN KEY (host_id, tenant_id) REFERENCES ph03_gateway.edge_host (id, tenant_id),
  CONSTRAINT ck_tls_exception_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_tls_exception_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_tls_exception_state CHECK (state IN ('ACTIVE', 'ENDED')),
  CONSTRAINT ck_tls_exception_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '180 days'),
  CONSTRAINT ck_tls_exception_ended CHECK ((state = 'ENDED') = (ended_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_tls_exception_active ON ph03_gateway.tls_exception (tenant_id, host_id) WHERE state = 'ACTIVE';
CREATE INDEX ix_tls_exception_expiry ON ph03_gateway.tls_exception (expires_at) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_tls_exception_touch BEFORE UPDATE ON ph03_gateway.tls_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_tls_exception_state BEFORE UPDATE ON ph03_gateway.tls_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('TLS_EXCEPTION');
CREATE TRIGGER tg_tls_exception_once BEFORE UPDATE ON ph03_gateway.tls_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('host_id', 'expires_at', 'reason');
CREATE TRIGGER tg_tls_exception_nodelete BEFORE DELETE ON ph03_gateway.tls_exception FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.tls_exception', 'P');
COMMENT ON TABLE ph03_gateway.tls_exception IS 'Ngoại lệ cho phép TLS 1.2 trên một host chuyên dụng (FR-03-001, BR-03-003): có lý do, hạn tối đa 180 ngày, PA tạo; không bao giờ dưới TLS 1.2. Không phải EN của FRS §4.2 (đề nghị EN-03-20).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.tls_exception CASCADE;

-- @changeset ph03-0560-tenant-redirect
CREATE TABLE ph03_gateway.tenant_redirect (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  from_tenant      varchar(16)   NOT NULL,
  to_tenant        varchar(16)   NOT NULL,
  start_at         timestamptz   NOT NULL DEFAULT now(),
  end_at           timestamptz   NOT NULL,
  state            varchar(6)    NOT NULL DEFAULT 'ACTIVE',
  reason           varchar(500),
  ended_by         varchar(64),
  ended_at         timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_redirect PRIMARY KEY (id),
  CONSTRAINT ck_tenant_redirect_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' AND tenant_id = to_tenant),
  CONSTRAINT ck_tenant_redirect_from CHECK (from_tenant ~ '^T[0-9]{2}$' AND from_tenant <> to_tenant),
  CONSTRAINT ck_tenant_redirect_window CHECK (end_at > start_at AND end_at <= start_at + interval '365 days'),
  CONSTRAINT ck_tenant_redirect_state CHECK (state IN ('ACTIVE', 'ENDED')),
  CONSTRAINT ck_tenant_redirect_ended CHECK ((state = 'ENDED') = (ended_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_tenant_redirect_active ON ph03_gateway.tenant_redirect (from_tenant) WHERE state = 'ACTIVE';
CREATE INDEX ix_tenant_redirect_end ON ph03_gateway.tenant_redirect (end_at) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_tenant_redirect_touch BEFORE UPDATE ON ph03_gateway.tenant_redirect FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_tenant_redirect_state BEFORE UPDATE ON ph03_gateway.tenant_redirect FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('TENANT_REDIRECT');
CREATE TRIGGER tg_tenant_redirect_once BEFORE UPDATE ON ph03_gateway.tenant_redirect FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('from_tenant', 'to_tenant', 'start_at');
CREATE TRIGGER tg_tenant_redirect_nodelete BEFORE DELETE ON ph03_gateway.tenant_redirect FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.tenant_redirect', 'P');
COMMENT ON TABLE ph03_gateway.tenant_redirect IS 'EN-03-13 Chuyển tiếp lượt gọi của tenant đã sáp nhập sang tenant đích (FR-03-037, D03-10 §5.4). Dòng thuộc tenant đích (tenant_id = to_tenant, ADR-003); tenant nguồn ở trạng thái MERGED nên không còn phiên. Mặc định 180 ngày (gw.redirect.defaultDays), tối đa 365; mỗi tenant nguồn chỉ một chuyển tiếp đang chạy.';
COMMENT ON COLUMN ph03_gateway.tenant_redirect.from_tenant IS 'Tenant nguồn (MERGED); token của tenant này bị từ chối ERR-03-106 kèm hướng dẫn nhận thông tin xác thực mới.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.tenant_redirect CASCADE;

-- @file 03-0060-snapshot.sql
-- @changeset ph03-0600-snapshot-counter
CREATE TABLE ph03_gateway.snapshot_counter (
  site             varchar(8)    NOT NULL,
  last_issued      bigint        NOT NULL DEFAULT 0,
  last_published   bigint        NOT NULL DEFAULT 0,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_snapshot_counter PRIMARY KEY (site),
  CONSTRAINT ck_snapshot_counter_site CHECK (site ~ '^[a-z][a-z0-9]{1,7}$'),
  CONSTRAINT ck_snapshot_counter_order CHECK (last_published <= last_issued AND last_issued >= 0)
);
CREATE OR REPLACE FUNCTION ph03_gateway.tg_counter_monotonic() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.last_issued < OLD.last_issued OR NEW.last_published < OLD.last_published THEN
    RAISE EXCEPTION 'Số phiên bản ảnh chụp chỉ tăng, không lùi (BR-03-018)' USING ERRCODE = '55000';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_snapshot_counter_monotonic BEFORE UPDATE ON ph03_gateway.snapshot_counter FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_counter_monotonic();
CREATE TRIGGER tg_snapshot_counter_nodelete BEFORE DELETE ON ph03_gateway.snapshot_counter FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
COMMENT ON TABLE ph03_gateway.snapshot_counter IS 'Bộ đếm số phiên bản ảnh chụp, một dòng mỗi site (SnapshotCounter, SDD §4.10). Cấp số bằng SELECT … FOR UPDATE ngay trước bước ký để không trùng, không lùi kể cả khi hai bản sao dh-connect cùng chạy. Bảng kỹ thuật toàn nền tảng, không có tenant_id (chỉ chứa số).';
COMMENT ON COLUMN ph03_gateway.snapshot_counter.last_issued IS 'Số lớn nhất đã cấp; khoảng trống chỉ có khi ký thất bại sau khi cấp (nút chỉ yêu cầu "lớn hơn").';
COMMENT ON COLUMN ph03_gateway.snapshot_counter.last_published IS 'Số lớn nhất đã phát; ảnh chụp có số nhỏ hơn bị bỏ (ERR-03-006). Khi chuyển site (DR) site mới bắt đầu từ số lớn nhất đã biết cộng gw.snapshot.drGap.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.snapshot_counter CASCADE;

-- @changeset ph03-0610-config-snapshot
CREATE TABLE ph03_gateway.config_snapshot (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  site             varchar(8)    NOT NULL,
  scope            varchar(8)    NOT NULL,
  snapshot_version bigint,
  state            varchar(10)   NOT NULL DEFAULT 'BUILT',
  trigger_type     varchar(10)   NOT NULL,
  content_hash     char(64)      NOT NULL,
  manifest_hash    char(64),
  signature_key_id varchar(64),
  built_from       jsonb         NOT NULL DEFAULT '[]',
  route_count      integer       NOT NULL DEFAULT 0,
  size_bytes       bigint        NOT NULL DEFAULT 0,
  bucket_prefix    varchar(255),
  git_commit       char(40),
  git_pending      boolean       NOT NULL DEFAULT false,
  rollback_of_version bigint,
  reject_summary   varchar(500),
  requested_by     varchar(64)   NOT NULL,
  built_at         timestamptz   NOT NULL DEFAULT now(),
  signed_at        timestamptz,
  published_at     timestamptz,
  applied_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_config_snapshot PRIMARY KEY (id),
  CONSTRAINT uq_config_snapshot_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_config_snapshot_version UNIQUE (site, snapshot_version),
  CONSTRAINT ck_config_snapshot_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_config_snapshot_site CHECK (site ~ '^[a-z][a-z0-9]{1,7}$'),
  CONSTRAINT ck_config_snapshot_scope CHECK ((scope = 'PLATFORM') = (tenant_id = 'COMMON') AND scope IN ('TENANT', 'PLATFORM')),
  CONSTRAINT ck_config_snapshot_state CHECK (state IN ('BUILT', 'REJECTED', 'SIGNED', 'PUBLISHED', 'APPLIED', 'PARTIAL', 'SUPERSEDED')),
  CONSTRAINT ck_config_snapshot_trigger CHECK (trigger_type IN ('EVENT', 'RECONCILE', 'MANUAL', 'ROLLBACK', 'EXPIRY', 'EMERGENCY', 'RELEASE')),
  CONSTRAINT ck_config_snapshot_hash CHECK (content_hash ~ '^[0-9a-f]{64}$' AND (manifest_hash IS NULL OR manifest_hash ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_config_snapshot_version CHECK (snapshot_version IS NULL OR snapshot_version > 0),
  CONSTRAINT ck_config_snapshot_signed CHECK (state IN ('BUILT', 'REJECTED') OR (snapshot_version IS NOT NULL AND manifest_hash IS NOT NULL AND signature_key_id IS NOT NULL AND signed_at IS NOT NULL)),
  CONSTRAINT ck_config_snapshot_unsigned CHECK (state NOT IN ('BUILT', 'REJECTED') OR (signed_at IS NULL AND published_at IS NULL)),
  CONSTRAINT ck_config_snapshot_published CHECK (state NOT IN ('PUBLISHED', 'APPLIED', 'PARTIAL') OR published_at IS NOT NULL),
  CONSTRAINT ck_config_snapshot_applied CHECK (state <> 'APPLIED' OR applied_at IS NOT NULL),
  CONSTRAINT ck_config_snapshot_rejected CHECK (state <> 'REJECTED' OR reject_summary IS NOT NULL),
  CONSTRAINT ck_config_snapshot_rollback CHECK (rollback_of_version IS NULL OR (trigger_type = 'ROLLBACK' AND (snapshot_version IS NULL OR rollback_of_version < snapshot_version))),
  CONSTRAINT ck_config_snapshot_built_from CHECK (jsonb_typeof(built_from) = 'array'),
  CONSTRAINT ck_config_snapshot_counts CHECK (route_count >= 0 AND size_bytes >= 0)
);
CREATE INDEX ix_config_snapshot_tenant ON ph03_gateway.config_snapshot (tenant_id, built_at DESC);
CREATE INDEX ix_config_snapshot_open ON ph03_gateway.config_snapshot (site, state) WHERE state IN ('SIGNED', 'PUBLISHED', 'PARTIAL');
CREATE INDEX ix_config_snapshot_git ON ph03_gateway.config_snapshot (site, snapshot_version) WHERE git_pending;
CREATE TRIGGER tg_config_snapshot_touch BEFORE UPDATE ON ph03_gateway.config_snapshot FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_config_snapshot_state BEFORE UPDATE ON ph03_gateway.config_snapshot FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('SNAPSHOT');
CREATE TRIGGER tg_config_snapshot_once BEFORE UPDATE ON ph03_gateway.config_snapshot FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_write_once('site', 'scope', 'content_hash', 'manifest_hash', 'snapshot_version', 'signature_key_id', 'built_from', 'rollback_of_version', 'signed_at');
CREATE TRIGGER tg_config_snapshot_nodelete BEFORE DELETE ON ph03_gateway.config_snapshot FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.config_snapshot', 'P');
COMMENT ON TABLE ph03_gateway.config_snapshot IS 'EN-03-09 Siêu dữ liệu ảnh chụp cấu hình (FR-03-039…044): nội dung ở Git và bucket dh-platform-gateway, bảng chỉ giữ phiên bản, băm, chữ ký, trạng thái. Mỗi dòng là một lần tổng hợp của một tenant (tenant_id) trên một site; số phiên bản tăng đơn điệu theo site, chỉ cấp ngay trước khi ký. Nội dung đã ký bất biến; quay lui sinh dòng mới (BR-03-018).';
COMMENT ON COLUMN ph03_gateway.config_snapshot.snapshot_version IS 'NULL khi BUILT hoặc REJECTED (chưa cấp số); bắt buộc từ SIGNED. Duy nhất theo site.';
COMMENT ON COLUMN ph03_gateway.config_snapshot.scope IS 'TENANT: mảnh của một tenant; PLATFORM: phần dùng chung ở tenant COMMON (global_rules, plugin_configs, plugin_metadata, ssls).';
COMMENT ON COLUMN ph03_gateway.config_snapshot.content_hash IS 'SHA-256 của bản ghép đã chuẩn hóa (YAML chính tắc); tổng hợp là hàm thuần nên cùng đầu vào cùng băm, trùng băm bản đang chạy thì không phát (NO_CHANGE, không tạo dòng).';
COMMENT ON COLUMN ph03_gateway.config_snapshot.manifest_hash IS 'SHA-256 của manifest.json chuẩn hóa, là thứ được ký (ECDSA P-256 qua OpenBao transit).';
COMMENT ON COLUMN ph03_gateway.config_snapshot.signature_key_id IS 'Khóa ký dạng dh-gateway-snapshot:3 (xoay 12 tháng); không lưu chữ ký, chữ ký nằm ở manifest.sig.';
COMMENT ON COLUMN ph03_gateway.config_snapshot.built_from IS 'Con trỏ nguồn đã dùng, ví dụ [{"source":"catalog","cursor":"e-1204455"}]; dùng tính syncState của consumer.';
COMMENT ON COLUMN ph03_gateway.config_snapshot.git_pending IS 'true khi đã ghi bucket nhưng commit Git lỗi, đang xếp hàng thử lại tới 1 giờ.';
COMMENT ON COLUMN ph03_gateway.config_snapshot.rollback_of_version IS 'Phiên bản cũ được sao nội dung khi quay lui; ảnh chụp mới luôn mang số lớn hơn.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.config_snapshot CASCADE;

-- @changeset ph03-0620-snapshot-violation
CREATE TABLE ph03_gateway.snapshot_violation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  snapshot_id      uuid          NOT NULL,
  rule_id          varchar(8)    NOT NULL,
  level            varchar(7)    NOT NULL,
  object_ref       varchar(255),
  error_code       varchar(10),
  message          varchar(1000) NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_snapshot_violation PRIMARY KEY (id),
  CONSTRAINT fk_snapshot_violation_snapshot FOREIGN KEY (snapshot_id, tenant_id) REFERENCES ph03_gateway.config_snapshot (id, tenant_id),
  CONSTRAINT ck_snapshot_violation_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_snapshot_violation_rule CHECK (rule_id ~ '^CHK-[0-9]{2}$'),
  CONSTRAINT ck_snapshot_violation_level CHECK (level IN ('ERROR', 'WARNING')),
  CONSTRAINT ck_snapshot_violation_error CHECK (error_code IS NULL OR error_code ~ '^ERR-03-[0-9]{3}$')
);
CREATE INDEX ix_snapshot_violation_snapshot ON ph03_gateway.snapshot_violation (tenant_id, snapshot_id, level);
CREATE TRIGGER tg_snapshot_violation_append BEFORE UPDATE ON ph03_gateway.snapshot_violation FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_append_only();
CALL ph03_gateway.p_enable_rls('ph03_gateway.snapshot_violation', 'P');
COMMENT ON TABLE ph03_gateway.snapshot_violation IS 'Kết quả kiểm tra hợp lệ gắn với ảnh chụp (ValidationReport, FR-03-040): mỗi vi phạm quy tắc CHK-nn mức ERROR (từ chối cả ảnh chụp) hoặc WARNING (không chặn). Thông điệp không chứa giá trị cấu hình nhạy cảm; chỉ thêm, xóa theo ảnh chụp khi dọn.';
COMMENT ON COLUMN ph03_gateway.snapshot_violation.object_ref IS 'Đối tượng vi phạm, ví dụ route:tra-cuu-ho-tich.v1.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.snapshot_violation CASCADE;

-- @changeset ph03-0630-tenant-hold
CREATE TABLE ph03_gateway.tenant_hold (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  reason           varchar(500)  NOT NULL,
  rollback_snapshot_id uuid,
  hold_until       timestamptz   NOT NULL,
  state            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  released_by      varchar(64),
  released_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_hold PRIMARY KEY (id),
  CONSTRAINT fk_tenant_hold_snapshot FOREIGN KEY (rollback_snapshot_id, tenant_id) REFERENCES ph03_gateway.config_snapshot (id, tenant_id),
  CONSTRAINT ck_tenant_hold_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_hold_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_tenant_hold_window CHECK (hold_until > created_at AND hold_until <= created_at + interval '168 hours'),
  CONSTRAINT ck_tenant_hold_state CHECK (state IN ('ACTIVE', 'RELEASED')),
  CONSTRAINT ck_tenant_hold_released CHECK ((state = 'RELEASED') = (released_at IS NOT NULL AND released_by IS NOT NULL))
);
CREATE UNIQUE INDEX uq_tenant_hold_active ON ph03_gateway.tenant_hold (tenant_id) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_tenant_hold_touch BEFORE UPDATE ON ph03_gateway.tenant_hold FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_tenant_hold_state BEFORE UPDATE ON ph03_gateway.tenant_hold FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('TENANT_HOLD');
CREATE TRIGGER tg_tenant_hold_nodelete BEFORE DELETE ON ph03_gateway.tenant_hold FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.tenant_hold', 'P');
COMMENT ON TABLE ph03_gateway.tenant_hold IS 'Bảng giữ tổng hợp tự động sau quay lui (HoldService, FR-03-044): trong thời gian giữ BuildCoordinator xếp hàng sự kiện, không tổng hợp. Mặc định gw.rollback.holdHours = 24, tối đa 168 giờ; hết hạn mà chưa bỏ giữ thì cảnh báo, không tự bỏ. Một giữ đang hoạt động mỗi tenant.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.tenant_hold CASCADE;

-- @changeset ph03-0640-source-cursor
CREATE TABLE ph03_gateway.source_cursor (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  source           varchar(12)   NOT NULL,
  last_cursor      varchar(64)   NOT NULL,
  last_synced_at   timestamptz   NOT NULL DEFAULT now(),
  stale_since      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_cursor PRIMARY KEY (id),
  CONSTRAINT uq_source_cursor UNIQUE (tenant_id, source),
  CONSTRAINT ck_source_cursor_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_source_cursor_source CHECK (source IN ('CATALOG', 'ONBOARDING', 'IAM', 'TENANT_MGMT'))
);
CREATE TRIGGER tg_source_cursor_touch BEFORE UPDATE ON ph03_gateway.source_cursor FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.source_cursor', 'P');
COMMENT ON TABLE ph03_gateway.source_cursor IS 'Con trỏ nguồn đã chiếu vào PH-03 theo tenant: PH-02 (CATALOG), PH-01 (ONBOARDING), PH-12 (IAM), PH-20 (TENANT_MGMT). Tác vụ đối chiếu 5 phút so con trỏ này với nguồn để bắt sự kiện bị lỡ; nguồn không trả quá 24 giờ thì cảnh báo, dùng bản chiếu gần nhất (SDD §4.8).';
COMMENT ON COLUMN ph03_gateway.source_cursor.stale_since IS 'Thời điểm nguồn bắt đầu không trả lời; dh_gateway_source_stale_seconds.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.source_cursor CASCADE;

-- @file 03-0070-params.sql
-- @changeset ph03-0700-param-definition
CREATE TABLE ph03_gateway.param_definition (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'COMMON',
  param_key        varchar(64)   NOT NULL,
  value_type       varchar(10)   NOT NULL,
  default_value    jsonb         NOT NULL,
  min_value        numeric,
  max_value        numeric,
  allowed_values   text[],
  unit             varchar(16),
  four_eyes        varchar(11)   NOT NULL DEFAULT 'NONE',
  managed_in       varchar(32),
  description      varchar(500)  NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_definition PRIMARY KEY (id),
  CONSTRAINT uq_param_definition_key UNIQUE (param_key),
  CONSTRAINT ck_param_definition_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_param_definition_key CHECK (param_key ~ '^gw\.[A-Za-z0-9.]+$'),
  CONSTRAINT ck_param_definition_type CHECK (value_type IN ('INT', 'DECIMAL', 'BYTES', 'PERCENT', 'BOOL', 'ENUM', 'CIDR_LIST')),
  CONSTRAINT ck_param_definition_range CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
  CONSTRAINT ck_param_definition_enum CHECK ((value_type = 'ENUM') = (allowed_values IS NOT NULL)),
  CONSTRAINT ck_param_definition_four_eyes CHECK (four_eyes IN ('NONE', 'ALWAYS', 'ON_DECREASE')),
  CONSTRAINT ck_param_definition_managed CHECK (managed_in IS NULL OR managed_in IN ('waf_mode', 'rate_limit_override'))
);
CREATE TRIGGER tg_param_definition_touch BEFORE UPDATE ON ph03_gateway.param_definition FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_param_definition_nodelete BEFORE DELETE ON ph03_gateway.param_definition FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_no_delete();
CALL ph03_gateway.p_enable_rls('ph03_gateway.param_definition', 'S');
COMMENT ON TABLE ph03_gateway.param_definition IS 'Mô tả tham số gw.* của FRS §8.2: kiểu, mặc định, miền, có bốn mắt hay không (SDD §4.16 "bảng mô tả tham số"). Danh mục toàn nền tảng ở tenant COMMON: mọi tenant đọc, chỉ phiên PLATFORM ghi. Miền là giới hạn nền tảng; trần hợp đồng của tenant (PH-20) do dịch vụ kiểm (ERR-03-018).';
COMMENT ON COLUMN ph03_gateway.param_definition.four_eyes IS 'NONE; ALWAYS: đổi cần change_request đã duyệt; ON_DECREASE: chỉ khi hạ thấp (gw.tenantRateLimit.perSecond).';
COMMENT ON COLUMN ph03_gateway.param_definition.managed_in IS 'Khác NULL: giá trị của tenant lưu ở bảng được nêu (waf_mode, rate_limit_override) chứ không ở tenant_param.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.param_definition CASCADE;

-- @changeset ph03-0710-tenant-param
CREATE TABLE ph03_gateway.tenant_param (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  param_key        varchar(64)   NOT NULL,
  param_value      jsonb         NOT NULL,
  change_request_id uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_param PRIMARY KEY (id),
  CONSTRAINT uq_tenant_param UNIQUE (tenant_id, param_key),
  CONSTRAINT fk_tenant_param_def FOREIGN KEY (param_key) REFERENCES ph03_gateway.param_definition (param_key),
  CONSTRAINT fk_tenant_param_request FOREIGN KEY (change_request_id, tenant_id) REFERENCES ph03_gateway.change_request (id, tenant_id),
  CONSTRAINT ck_tenant_param_tenant CHECK (tenant_id ~ '^T[0-9]{2}$')
);
CREATE OR REPLACE FUNCTION ph03_gateway.tg_tenant_param_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  d ph03_gateway.param_definition%ROWTYPE;
  v numeric;
  e jsonb;
BEGIN
  SELECT * INTO d FROM ph03_gateway.param_definition WHERE param_key = NEW.param_key;
  IF d.managed_in IS NOT NULL THEN
    RAISE EXCEPTION 'Tham số % lưu ở bảng %, không lưu ở tenant_param', NEW.param_key, d.managed_in USING ERRCODE = '23514';
  END IF;
  IF d.value_type IN ('INT', 'DECIMAL', 'BYTES', 'PERCENT') THEN
    IF jsonb_typeof(NEW.param_value) <> 'number' THEN
      RAISE EXCEPTION 'Tham số % phải là số', NEW.param_key USING ERRCODE = '23514';
    END IF;
    v := (NEW.param_value #>> '{}')::numeric;
    IF d.value_type <> 'DECIMAL' AND v <> trunc(v) THEN
      RAISE EXCEPTION 'Tham số % phải là số nguyên', NEW.param_key USING ERRCODE = '23514';
    END IF;
    IF (d.min_value IS NOT NULL AND v < d.min_value) OR (d.max_value IS NOT NULL AND v > d.max_value) THEN
      RAISE EXCEPTION 'Tham số % ngoài miền cho phép [%, %]', NEW.param_key, d.min_value, d.max_value USING ERRCODE = '23514';
    END IF;
  ELSIF d.value_type = 'BOOL' THEN
    IF jsonb_typeof(NEW.param_value) <> 'boolean' THEN
      RAISE EXCEPTION 'Tham số % phải là true hoặc false', NEW.param_key USING ERRCODE = '23514';
    END IF;
  ELSIF d.value_type = 'ENUM' THEN
    IF jsonb_typeof(NEW.param_value) <> 'string' OR NOT ((NEW.param_value #>> '{}') = ANY (d.allowed_values)) THEN
      RAISE EXCEPTION 'Tham số % chỉ nhận một trong %', NEW.param_key, d.allowed_values USING ERRCODE = '23514';
    END IF;
  ELSIF d.value_type = 'CIDR_LIST' THEN
    IF jsonb_typeof(NEW.param_value) <> 'array' THEN
      RAISE EXCEPTION 'Tham số % phải là danh sách CIDR', NEW.param_key USING ERRCODE = '23514';
    END IF;
    FOR e IN SELECT jsonb_array_elements(NEW.param_value) LOOP
      IF jsonb_typeof(e) <> 'string' OR (e #>> '{}') !~ '^[0-9a-fA-F:.]+/[0-9]{1,3}$' THEN
        RAISE EXCEPTION 'Phần tử CIDR không hợp lệ ở tham số %', NEW.param_key USING ERRCODE = '23514';
      END IF;
    END LOOP;
  END IF;
  IF d.four_eyes = 'ALWAYS' AND NEW.change_request_id IS NULL THEN
    RAISE EXCEPTION 'Tham số % cần yêu cầu thay đổi đã duyệt (BR-03-019)', NEW.param_key USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_tenant_param_guard BEFORE INSERT OR UPDATE ON ph03_gateway.tenant_param FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_tenant_param_guard();
CREATE TRIGGER tg_tenant_param_touch BEFORE UPDATE ON ph03_gateway.tenant_param FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.tenant_param', 'P');
COMMENT ON TABLE ph03_gateway.tenant_param IS 'Giá trị tham số gw.* ghi đè mặc định theo tenant (FR-03-056). Trigger tg_tenant_param_guard kiểm kiểu, miền theo param_definition; tham số có bốn mắt phải mang change_request_id; tham số lưu ở bảng khác (managed_in) bị từ chối. Không có dòng nghĩa là dùng mặc định.';
COMMENT ON COLUMN ph03_gateway.tenant_param.param_value IS 'Giá trị JSON đúng kiểu: số, true/false, chuỗi ENUM hoặc mảng CIDR; trần hợp đồng PH-20 do dịch vụ kiểm.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.tenant_param CASCADE;

-- @file 03-0080-ops.sql
-- @changeset ph03-0800-synthetic-check
CREATE TABLE ph03_gateway.synthetic_check (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  check_code       varchar(63)   NOT NULL,
  route_id         uuid          NOT NULL,
  method           varchar(7)    NOT NULL DEFAULT 'GET',
  path             varchar(512)  NOT NULL,
  expected_status  integer[]     NOT NULL DEFAULT '{200}',
  expected_body_jsonpath varchar(255),
  timeout_ms       integer       NOT NULL DEFAULT 10000,
  interval_seconds integer       NOT NULL DEFAULT 60,
  enabled          boolean       NOT NULL DEFAULT true,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_synthetic_check PRIMARY KEY (id),
  CONSTRAINT uq_synthetic_check_code UNIQUE (tenant_id, check_code),
  CONSTRAINT fk_synthetic_check_route FOREIGN KEY (route_id, tenant_id) REFERENCES ph03_gateway.route (id, tenant_id),
  CONSTRAINT ck_synthetic_check_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_synthetic_check_code CHECK (check_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_synthetic_check_method CHECK (method IN ('GET', 'HEAD', 'OPTIONS')),
  CONSTRAINT ck_synthetic_check_path CHECK (path ~ '^/[^?# ]*$'),
  CONSTRAINT ck_synthetic_check_status CHECK (cardinality(expected_status) BETWEEN 1 AND 10 AND 100 <= ALL (expected_status) AND 599 >= ALL (expected_status)),
  CONSTRAINT ck_synthetic_check_timeout CHECK (timeout_ms BETWEEN 100 AND 30000),
  CONSTRAINT ck_synthetic_check_interval CHECK (interval_seconds BETWEEN 30 AND 3600)
);
CREATE TRIGGER tg_synthetic_check_touch BEFORE UPDATE ON ph03_gateway.synthetic_check FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CALL ph03_gateway.p_enable_rls('ph03_gateway.synthetic_check', 'P');
COMMENT ON TABLE ph03_gateway.synthetic_check IS 'Cấu hình kiểm tra tổng hợp cho API quan trọng (FR-03-053, BR-03-027): gọi qua địa chỉ thật của cửa vào bằng consumer dh-synthetic-{tenant}, mỗi phút. Chỉ phương thức đọc; lượt gọi mang tiêu đề đánh dấu, không tính hạn mức của HTTT thật và bị loại khỏi báo cáo. Kết quả nằm ở Mimir (dh_gateway_synthetic_up), không lưu bảng.';
COMMENT ON COLUMN ph03_gateway.synthetic_check.path IS 'Đường dẫn thật, không có chuỗi truy vấn (tham số truy vấn có thể là dữ liệu cá nhân).';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.synthetic_check CASCADE;

-- @changeset ph03-0810-legacy-import-job
CREATE TABLE ph03_gateway.legacy_import_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  file_name        varchar(255)  NOT NULL,
  file_sha256      char(64)      NOT NULL,
  size_bytes       bigint        NOT NULL,
  mapping_mode     varchar(12)   NOT NULL DEFAULT 'PROPOSE_ONLY',
  state            varchar(8)    NOT NULL DEFAULT 'UPLOADED',
  findings         jsonb         NOT NULL DEFAULT '[]',
  summary          jsonb         NOT NULL DEFAULT '{}',
  requested_by     varchar(64)   NOT NULL,
  scanned_at       timestamptz,
  applied_by       varchar(64),
  applied_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_import_job PRIMARY KEY (id),
  CONSTRAINT ck_legacy_import_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legacy_import_job_sha CHECK (file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_legacy_import_job_size CHECK (size_bytes BETWEEN 1 AND 52428800),
  CONSTRAINT ck_legacy_import_job_mode CHECK (mapping_mode IN ('PROPOSE_ONLY', 'APPLY')),
  CONSTRAINT ck_legacy_import_job_state CHECK (state IN ('UPLOADED', 'SCANNED', 'PROPOSED', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_legacy_import_job_findings CHECK (jsonb_typeof(findings) = 'array' AND jsonb_typeof(summary) = 'object'),
  CONSTRAINT ck_legacy_import_job_applied CHECK ((state = 'APPLIED') = (applied_at IS NOT NULL AND applied_by IS NOT NULL)),
  CONSTRAINT ck_legacy_import_job_four_eyes CHECK (applied_by IS NULL OR mapping_mode = 'APPLY')
);
CREATE INDEX ix_legacy_import_job_tenant ON ph03_gateway.legacy_import_job (tenant_id, created_at DESC);
CREATE TRIGGER tg_legacy_import_job_touch BEFORE UPDATE ON ph03_gateway.legacy_import_job FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_touch();
CREATE TRIGGER tg_legacy_import_job_state BEFORE UPDATE ON ph03_gateway.legacy_import_job FOR EACH ROW EXECUTE FUNCTION ph03_gateway.tg_state_guard('IMPORT_JOB');
CALL ph03_gateway.p_enable_rls('ph03_gateway.legacy_import_job', 'P');
COMMENT ON TABLE ph03_gateway.legacy_import_job IS 'Lần nhập cấu hình từ gateway cũ (FR-03-059): gói xuất tối đa 50 MiB được LegacyBundleScanner chỉ đọc dữ liệu (không thực thi, từ chối trường bí mật), ánh xạ thành cấu hình nháp. Nội dung gói không lưu ở bảng, chỉ băm, kích thước và báo cáo; áp dụng nháp là thao tác riêng tạo dữ liệu nguồn ở PH-02, PH-01 chứ không ghi thẳng vào ảnh chụp.';
COMMENT ON COLUMN ph03_gateway.legacy_import_job.findings IS 'Danh sách mục không ánh xạ được hoặc cảnh báo, mỗi mục {path, code, message}; không chép giá trị bí mật (chỉ vị trí).';
COMMENT ON COLUMN ph03_gateway.legacy_import_job.summary IS 'Số lượng theo loại: {"apis":{"found":40,"mapped":37},"plans":{...},"applications":{...},"subscriptions":{...}}.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.legacy_import_job CASCADE;

-- @changeset ph03-0820-outbox
CREATE TABLE ph03_gateway.outbox (
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
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.gateway\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^(t[0-9]{2}|common)\.(gateway|audit)\.[a-z-]+(\.[a-z-]+)?\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'passphrase', 'authorization']))
);
CREATE INDEX ix_outbox_occurred ON ph03_gateway.outbox (occurred_at);
ALTER TABLE ph03_gateway.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph03_gateway.p_enable_rls('ph03_gateway.outbox', 'P');
COMMENT ON TABLE ph03_gateway.outbox IS 'Outbox (DD-11, ADR-042) cho EVT-03-01…08, 10…12 và bản ghi kiểm toán gửi PH-13, ghi cùng giao dịch với thay đổi trạng thái; Debezium đẩy lên topic {tenant}.gateway.*, khóa phân vùng là mã đối tượng. EVT-03-09 do APISIX phát qua kafka-logger (không qua bảng này). Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.outbox CASCADE;

-- @changeset ph03-0830-shedlock
CREATE TABLE ph03_gateway.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph03_gateway.shedlock IS 'Khóa tác vụ nền (ExpiryScheduler, tác vụ đối chiếu 5 phút, ValkeyRebuilder, CertificateService mỗi giờ, NodeStateEvaluator); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph03_gateway.shedlock;

-- @file 03-0800-seed.sql
-- @changeset ph03-0900-seed-params runOnChange:true
-- 66 tham số gw.* của FRS §8.2 (và gw.approval.substitute của SDD §4.14); chạy dưới app.tenant_id = 'PLATFORM', lũy đẳng.
INSERT INTO ph03_gateway.param_definition (id, tenant_id, param_key, value_type, default_value, min_value, max_value, allowed_values, unit, four_eyes, managed_in, description, created_by, updated_by)
SELECT md5('ph03-param:' || k)::uuid, 'COMMON', k, t, dv::jsonb, lo, hi, av, un, fe, mi, ds, 'system:seed', 'system:seed'
FROM (VALUES
  ('gw.ip.maxConnections', 'INT', '100', 10, 1000, NULL::text[], 'kết nối', 'NONE', NULL, 'Số kết nối đồng thời tối đa mỗi địa chỉ nguồn (FR-03-003)'),
  ('gw.ip.uiReqPerSecond', 'INT', '50', 5, 500, NULL, 'yêu cầu/giây', 'NONE', NULL, 'Yêu cầu/giây/IP cho đường dẫn giao diện'),
  ('gw.ip.apiReqPerSecond', 'INT', '200', 20, 2000, NULL, 'yêu cầu/giây', 'NONE', NULL, 'Yêu cầu/giây/IP cho API máy (giả định, Q03-05)'),
  ('gw.ip.burst', 'INT', '2', 1, 10, NULL, 'hệ số', 'NONE', NULL, 'Hệ số dung sai đột biến theo IP'),
  ('gw.ip.trustedCidrs', 'CIDR_LIST', '[]', NULL, NULL, NULL, NULL, 'NONE', NULL, 'Địa chỉ miễn giới hạn theo IP (mặc định dải giám sát và NDXP do tenant khai); SO duyệt'),
  ('gw.ip.headerTimeoutSeconds', 'INT', '10', 5, 60, NULL, 'giây', 'NONE', NULL, 'Thời hạn đọc tiêu đề (chống kết nối chậm)'),
  ('gw.ip.bodyTimeoutSeconds', 'INT', '30', 5, 60, NULL, 'giây', 'NONE', NULL, 'Thời hạn đọc thân (chống kết nối chậm)'),
  ('gw.ip.autoBlock.threshold', 'INT', '10', 3, 100, NULL, 'lần', 'NONE', NULL, 'Số lần vi phạm trong 60 giây để tự chặn (FR-03-004)'),
  ('gw.ip.autoBlock.minutes', 'INT', '15', 1, 1440, NULL, 'phút', 'NONE', NULL, 'Thời gian chặn tự động'),
  ('gw.body.maxBytes', 'BYTES', '1048576', 1024, 10485760, NULL, 'byte', 'NONE', NULL, 'Kích thước thân tối đa mỗi route, mặc định 1 MiB (FR-03-009)'),
  ('gw.json.maxDepth', 'INT', '32', 8, 64, NULL, 'mức', 'NONE', NULL, 'Độ sâu JSON tối đa'),
  ('gw.json.maxArrayItems', 'INT', '10000', 100, 100000, NULL, 'phần tử', 'NONE', NULL, 'Số phần tử mảng JSON tối đa'),
  ('gw.waf.mode', 'ENUM', '"DETECT"', NULL, NULL, ARRAY['DETECT', 'BLOCK'], NULL, 'ALWAYS', 'waf_mode', 'Chế độ WAF; lưu ở bảng waf_mode, đổi ở FR-03-006 (có bốn mắt)'),
  ('gw.waf.paranoia.ui', 'INT', '2', 1, 3, NULL, 'mức', 'NONE', NULL, 'Mức hoang tưởng CRS cho đường dẫn giao diện'),
  ('gw.waf.paranoia.api', 'INT', '1', 1, 3, NULL, 'mức', 'NONE', NULL, 'Mức hoang tưởng CRS cho API máy'),
  ('gw.waf.anomalyThreshold', 'INT', '5', 3, 15, NULL, 'điểm', 'NONE', NULL, 'Ngưỡng điểm bất thường để chặn'),
  ('gw.waf.bodyScanBytes', 'BYTES', '131072', 16384, 1048576, NULL, 'byte', 'NONE', NULL, 'Phần thân được WAF quét, mặc định 128 KiB (giả định)'),
  ('gw.waf.fpReviewMax', 'INT', '20', 0, 200, NULL, 'cảnh báo', 'NONE', NULL, 'Số cảnh báo giả chưa xử lý tối đa để được chuyển sang BLOCK (giả định)'),
  ('gw.waf.degradeP99Ms', 'INT', '15', 5, 100, NULL, 'ms', 'NONE', NULL, 'p99 thời gian WAF để tự hạ về DETECT (FR-03-006)'),
  ('gw.waf.exception.maxDays', 'INT', '90', 1, 90, NULL, 'ngày', 'NONE', NULL, 'Hạn tối đa ngoại lệ WAF (BR-03-006)'),
  ('gw.waf.exception.warnDays', 'INT', '7', 1, 30, NULL, 'ngày', 'NONE', NULL, 'Số ngày báo ngoại lệ sắp hết hạn'),
  ('gw.tls.exceptionMaxDays', 'INT', '180', 1, 180, NULL, 'ngày', 'NONE', NULL, 'Hạn tối đa ngoại lệ TLS 1.2 (FR-03-001)'),
  ('gw.jwks.refreshMinutes', 'INT', '10', 1, 60, NULL, 'phút', 'NONE', NULL, 'Chu kỳ làm mới JWKS'),
  ('gw.jwks.maxStaleHours', 'INT', '24', 1, 24, NULL, 'giờ', 'NONE', NULL, 'Thời gian dùng bộ đệm JWKS khi không làm mới được'),
  ('gw.jwks.kidRefreshMinIntervalSeconds', 'INT', '30', 10, 300, NULL, 'giây', 'NONE', NULL, 'Khoảng tối thiểu giữa hai lần làm mới do kid lạ'),
  ('gw.jwt.clockSkewSeconds', 'INT', '30', 0, 60, NULL, 'giây', 'NONE', NULL, 'Dung sai đồng hồ khi kiểm exp, nbf (SEC-25)'),
  ('gw.opa.timeoutMs', 'INT', '50', 10, 200, NULL, 'ms', 'NONE', NULL, 'Thời hạn chờ OPA (giả định)'),
  ('gw.rate.essentialFactor', 'DECIMAL', '1.5', 1, 3, NULL, 'hệ số', 'NONE', NULL, 'Hệ số nới tần suất cho nhóm ESSENTIAL (BR-03-009)'),
  ('gw.quota.warnPercent', 'PERCENT', '80', 50, 95, NULL, '%', 'NONE', NULL, 'Ngưỡng cảnh báo hạn ngạch'),
  ('gw.quota.essentialOverrunPercent', 'PERCENT', '20', 0, 100, NULL, '%', 'NONE', NULL, 'Mức vượt hạn ngạch cho phép của nhóm ESSENTIAL'),
  ('gw.tenantRateLimit.perSecond', 'INT', '500', 10, NULL, NULL, 'lượt/giây', 'ON_DECREASE', 'rate_limit_override', 'Hạn mức toàn tenant; lưu ở rate_limit_override (scope TENANT), hạ thấp cần bốn mắt (FR-03-023); trần hợp đồng theo PH-20'),
  ('gw.tenantRateLimit.burst', 'PERCENT', '20', 0, 100, NULL, '%', 'NONE', 'rate_limit_override', 'Dung sai đột biến của hạn mức tenant; lưu ở rate_limit_override.burst_percent'),
  ('gw.degrade.localDivisorMode', 'ENUM', '"REPLICAS"', NULL, NULL, ARRAY['REPLICAS', 'NONE'], NULL, 'NONE', NULL, 'Cách chia hạn mức khi Valkey mất (FR-03-026)'),
  ('gw.throttle.errorRatePercent', 'PERCENT', '20', 5, 80, NULL, '%', 'NONE', NULL, 'Ngưỡng tỉ lệ lỗi backend để điều tiết (FR-03-027)'),
  ('gw.throttle.latencyFactor', 'INT', '3', 2, 10, NULL, 'lần', 'NONE', NULL, 'Hệ số độ trễ backend để điều tiết'),
  ('gw.upstream.healthcheck.intervalSeconds', 'INT', '5', 1, 60, NULL, 'giây', 'NONE', NULL, 'Chu kỳ kiểm tra sức khỏe chủ động (FR-03-030)'),
  ('gw.upstream.failThreshold', 'INT', '3', 1, 10, NULL, 'lần', 'NONE', NULL, 'Số lần lỗi để loại nút'),
  ('gw.upstream.successThreshold', 'INT', '2', 1, 10, NULL, 'lần', 'NONE', NULL, 'Số lần đạt để đưa nút lại'),
  ('gw.upstream.timeout.connectMs', 'INT', '3000', 100, 30000, NULL, 'ms', 'NONE', NULL, 'Thời hạn chờ kết nối mặc định; trần 30.000 ms (CV 631)'),
  ('gw.upstream.timeout.readMs', 'INT', '10000', 100, 30000, NULL, 'ms', 'NONE', NULL, 'Thời hạn chờ đọc mặc định; trần 30.000 ms (CV 631)'),
  ('gw.breaker.failures', 'INT', '5', 2, 50, NULL, 'lần', 'NONE', NULL, 'Số lần lỗi liên tiếp để mở mạch (FR-03-031)'),
  ('gw.breaker.openSeconds', 'INT', '10', 5, 60, NULL, 'giây', 'NONE', NULL, 'Thời gian mở mạch trước khi thăm dò'),
  ('gw.ws.idleTimeoutSeconds', 'INT', '120', 10, 3600, NULL, 'giây', 'NONE', NULL, 'Thời gian rỗi tối đa của WebSocket (FR-03-033)'),
  ('gw.ws.maxMessageBytes', 'BYTES', '1048576', 4096, 16777216, NULL, 'byte', 'NONE', NULL, 'Kích thước tối đa một thông điệp WebSocket'),
  ('gw.ws.maxPerConsumer', 'INT', '50', 1, 500, NULL, 'kết nối', 'NONE', NULL, 'Số kết nối WebSocket tối đa mỗi consumer'),
  ('gw.trace.successSampling', 'DECIMAL', '0.05', 0.01, 1, NULL, 'tỉ lệ', 'NONE', NULL, 'Tỉ lệ lấy mẫu vết thành công; vết lỗi luôn giữ 100%'),
  ('gw.sunset.minDays', 'INT', '180', 180, 720, NULL, 'ngày', 'NONE', NULL, 'Hạn tối thiểu giữ phiên bản cũ sau khi công bố ngừng dùng (BR-03-030)'),
  ('gw.sunset.retainDays', 'INT', '30', 0, 180, NULL, 'ngày', 'NONE', NULL, 'Giữ thêm sau SUNSET trước khi RETIRED'),
  ('gw.redirect.defaultDays', 'INT', '180', 30, 365, NULL, 'ngày', 'NONE', NULL, 'Thời gian chuyển tiếp tenant sáp nhập (FR-03-037)'),
  ('gw.snapshot.debounceSeconds', 'INT', '3', 0, 30, NULL, 'giây', 'NONE', NULL, 'Gom sự kiện trước khi tổng hợp'),
  ('gw.reconcile.minutes', 'INT', '5', 1, 60, NULL, 'phút', 'NONE', NULL, 'Chu kỳ đối chiếu định kỳ'),
  ('gw.snapshot.retain', 'INT', '50', 10, 500, NULL, 'phiên bản', 'NONE', NULL, 'Số ảnh chụp giữ ở bucket'),
  ('gw.snapshot.maxBytes', 'BYTES', '20971520', 1048576, 104857600, NULL, 'byte', 'NONE', NULL, 'Kích thước tối đa ảnh chụp, mặc định 20 MiB (giả định)'),
  ('gw.snapshot.isolateBadRoute', 'BOOL', 'false', NULL, NULL, NULL, NULL, 'NONE', NULL, 'Cô lập route lỗi thay vì từ chối cả ảnh chụp'),
  ('gw.snapshot.drGap', 'INT', '1000', 100, 100000, NULL, 'phiên bản', 'NONE', NULL, 'Khoảng an toàn số phiên bản khi chuyển site'),
  ('gw.sync.pollSeconds', 'INT', '5', 1, 60, NULL, 'giây', 'NONE', NULL, 'Chu kỳ bộ đồng bộ kiểm tra con trỏ current'),
  ('gw.rollback.holdHours', 'INT', '24', 1, 168, NULL, 'giờ', 'NONE', NULL, 'Thời gian giữ tổng hợp tự động sau quay lui (FR-03-044)'),
  ('gw.node.lagSeconds', 'INT', '60', 10, 600, NULL, 'giây', 'NONE', NULL, 'Ngưỡng nút LAGGING'),
  ('gw.node.unknownSeconds', 'INT', '120', 10, 600, NULL, 'giây', 'NONE', NULL, 'Ngưỡng nút UNKNOWN'),
  ('gw.emergency.propagateSeconds', 'INT', '30', 5, 60, NULL, 'giây', 'NONE', NULL, 'Mục tiêu hiệu lực tạm ngừng khẩn cấp'),
  ('gw.cert.renewDays', 'INT', '30', 7, 60, NULL, 'ngày', 'NONE', NULL, 'Số ngày trước hạn tự động gia hạn chứng thư'),
  ('gw.cert.warnDays', 'INT', '30', 7, 60, NULL, 'ngày', 'NONE', NULL, 'Số ngày trước hạn cảnh báo (7 ngày là Nghiêm trọng)'),
  ('gw.accessLog.bufferMiB', 'INT', '1024', 128, 4096, NULL, 'MiB', 'NONE', NULL, 'Bộ đệm đĩa của nhật ký lượt gọi mỗi pod'),
  ('gw.accessLog.export.maxRows', 'INT', '100000', 1000, 500000, NULL, 'dòng', 'NONE', NULL, 'Số dòng tối đa mỗi lần xuất nhật ký'),
  ('gw.metrics.maxConsumerLabels', 'INT', '500', 50, 5000, NULL, 'nhãn', 'NONE', NULL, 'Số giá trị nhãn consumer tối đa của chỉ số (giả định, Q03-08)'),
  ('gw.approval.substitute', 'BOOL', 'false', NULL, NULL, NULL, NULL, 'NONE', NULL, 'Cho PA duyệt thay khi tenant có dưới hai SO, kiểm toán ghi "duyệt thay" (Q03-02, SDD §4.14)')
) AS p(k, t, dv, lo, hi, av, un, fe, mi, ds)
ON CONFLICT (param_key) DO UPDATE SET default_value = EXCLUDED.default_value, min_value = EXCLUDED.min_value,
  max_value = EXCLUDED.max_value, allowed_values = EXCLUDED.allowed_values, description = EXCLUDED.description, updated_by = 'system:seed';
-- @rollback DELETE FROM ph03_gateway.param_definition WHERE created_by = 'system:seed';

-- @changeset ph03-0910-seed-site-counter runOnChange:true
INSERT INTO ph03_gateway.snapshot_counter (site) VALUES ('dc1'), ('dc2') ON CONFLICT (site) DO NOTHING;
-- @rollback DELETE FROM ph03_gateway.snapshot_counter WHERE last_issued = 0;

-- @file 03-0900-grants.sql
-- @changeset ph03-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph03_gateway TO ph03_app;
-- Mã bất biến, không dùng lại: chỉ xóa mềm (BR-03-029); trigger tg_no_delete là lớp thứ hai.
REVOKE DELETE ON ph03_gateway.route, ph03_gateway.consumer, ph03_gateway.edge_host, ph03_gateway.waf_exception,
  ph03_gateway.waf_virtual_patch, ph03_gateway.waf_mode, ph03_gateway.ip_block, ph03_gateway.emergency_block,
  ph03_gateway.tenant_redirect, ph03_gateway.tls_exception, ph03_gateway.rate_limit_override,
  ph03_gateway.change_request, ph03_gateway.config_snapshot, ph03_gateway.tenant_hold,
  ph03_gateway.param_definition, ph03_gateway.snapshot_counter FROM ph03_app;
REVOKE UPDATE, DELETE ON ph03_gateway.route_state_event FROM ph03_app;      -- chỉ thêm
REVOKE UPDATE ON ph03_gateway.snapshot_violation, ph03_gateway.outbox, ph03_gateway.revoked_token, ph03_gateway.idempotency_key FROM ph03_app;
REVOKE INSERT, UPDATE, DELETE ON ph03_gateway.state_transition FROM ph03_app;   -- đổi bằng changeset
REVOKE INSERT, DELETE ON ph03_gateway.snapshot_counter FROM ph03_app;          -- một dòng mỗi site, chỉ tăng
GRANT SELECT ON ALL TABLES IN SCHEMA ph03_gateway TO ph03_readonly;
REVOKE SELECT ON ph03_gateway.waf_virtual_patch, ph03_gateway.idempotency_key, ph03_gateway.client_ca FROM ph03_readonly;
GRANT SELECT (id, tenant_id, patch_code, scope, route_id, reason, state, requested_by, requested_at, approved_by, approved_at, expires_at, created_at, updated_at, version)
  ON ph03_gateway.waf_virtual_patch TO ph03_readonly;                         -- không đọc nội dung luật vá
GRANT SELECT (id, tenant_id, operation, request_hash, response_status, created_at, expires_at)
  ON ph03_gateway.idempotency_key TO ph03_readonly;
GRANT SELECT (id, tenant_id, ca_code, subject, fingerprint, not_after, crl_url, state, version)
  ON ph03_gateway.client_ca TO ph03_readonly;
GRANT EXECUTE ON FUNCTION ph03_gateway.tg_touch(), ph03_gateway.tg_append_only(), ph03_gateway.tg_no_delete(),
  ph03_gateway.tg_write_once(), ph03_gateway.tg_state_guard() TO ph03_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
