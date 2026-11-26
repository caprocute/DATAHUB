-- =============================================================================
-- D03-03-PH13 · DDL schema ph13_audit — PH-13 Giám sát và kiểm toán (nhóm kiểm toán)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph13_audit.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Nguyên tắc (FRS PH-13 §4.7, BR-13-002, BR-13-017, BR-13-019, SDD §4.4):
--  * Mỗi tenant một chuỗi băm; audit_event chỉ thêm (trigger chặn UPDATE, DELETE, TRUNCATE).
--  * Đầu chuỗi (audit_chain) chỉ nhích khi các bản ghi mới liền kề, nối đúng prev_hash.
--  * Mọi bản ghi phải được đầu chuỗi bao phủ khi cam kết (constraint trigger hoãn).
--  * Vai trò ứng dụng chỉ INSERT, SELECT trên audit_event, audit_anchor; không DDL.
--  * Chỉ thủ tục p_archive_partition (DEFINER, chỉ ph13_archive gọi được) mới tách phân vùng cũ.
-- Chạy trước ph13_obs.sql hoặc sau đều được: hai tệp độc lập, cùng tạo vai trò theo kiểu idempotent.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 13-0000-bootstrap.sql
-- @changeset ph13-0000-roles splitStatements:false context:bootstrap
DO $roles$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['ph13_owner', 'ph13_app', 'ph13_verify', 'ph13_archive', 'ph13_obs_app', 'ph13_readonly'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS %s', r,
                     CASE WHEN r = 'ph13_owner' THEN 'NOINHERIT' ELSE '' END);
    END IF;
  END LOOP;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph13-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE SCHEMA IF NOT EXISTS ph13_audit AUTHORIZATION ph13_owner;
COMMENT ON SCHEMA ph13_audit IS 'PH-13 nhóm kiểm toán: chuỗi băm theo tenant, bản ghi kiểm toán chỉ thêm (phân vùng tháng), neo ký, lô WORM, xác minh toàn vẹn, xuất bằng chứng, đối chiếu số lượng, cách ly. Chủ duy nhất: module audit của dh-platform (ph13_app, ph13_verify, ph13_archive, cấp động bởi OpenBao).';
GRANT USAGE ON SCHEMA ph13_audit TO ph13_app, ph13_verify, ph13_archive, ph13_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph13_audit CASCADE;

SET ROLE ph13_owner;

-- @changeset ph13-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 13-0001-functions.sql
-- @changeset ph13-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph13_audit.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.tg_touch();

-- @changeset ph13-0011-fn-rls splitStatements:false
-- Hai mẫu: 'P' riêng tenant (đọc, ghi dòng của tenant phiên); 'S' dùng chung (mọi tenant đọc dòng PLATFORM,
-- chỉ phiên PLATFORM mới ghi). Biến app.tenant_id không đặt thì current_setting(..., false) báo lỗi: đóng an toàn.
CREATE OR REPLACE PROCEDURE ph13_audit.p_enable_rls(p_table regclass, p_mode char DEFAULT 'P')
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text; w text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  IF p_mode = 'P' THEN
    r := $r$(tenant_id = current_setting('app.tenant_id', false))$r$;
    w := r;
  ELSE
    r := $r$(tenant_id IN (current_setting('app.tenant_id', false), 'PLATFORM'))$r$;
    w := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id = 'PLATFORM')$w$;
  END IF;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph13_audit.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph13_audit.p_enable_rls(regclass, char);

-- @changeset ph13-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph13_audit.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm (append-only, BR-13-002)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_append_only() IS 'Chặn UPDATE, DELETE, TRUNCATE trên bảng nhật ký bất biến.';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.tg_append_only();

-- @changeset ph13-0013-fn-forbid-delete splitStatements:false
CREATE OR REPLACE FUNCTION ph13_audit.tg_forbid_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % không cho xóa dòng (đổi trạng thái thay vì xóa)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_forbid_delete() IS 'Chặn DELETE; dòng đổi trạng thái thay vì xóa.';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.tg_forbid_delete();

-- @changeset ph13-0014-fn-guard-retention splitStatements:false
-- Chỉ cho xóa dòng đã quá thời hạn lưu: tg_guard_retention(cột_thời_điểm, khoảng). Cột rỗng coi như chưa hết hạn.
CREATE OR REPLACE FUNCTION ph13_audit.tg_guard_retention() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE ts timestamptz := (to_jsonb(OLD) ->> TG_ARGV[0])::timestamptz;
BEGIN
  IF ts IS NULL OR ts > now() - TG_ARGV[1]::interval THEN
    RAISE EXCEPTION 'Bảng %: chỉ xóa dòng quá hạn lưu % (cột %)', TG_TABLE_NAME, TG_ARGV[1], TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN OLD;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_guard_retention() IS 'Chỉ cho xóa dòng quá hạn lưu (NFR-13-019, FRS §8.2).';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.tg_guard_retention();

-- @changeset ph13-0015-fn-immutable splitStatements:false
-- tg_immutable(cột...): không cho đổi các cột liệt kê (mã, tenant, băm khởi đầu...).
CREATE OR REPLACE FUNCTION ph13_audit.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph13_audit.tg_immutable() IS 'Chặn sửa các cột bất biến (đối số trigger).';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.tg_immutable();

-- @changeset ph13-0016-fn-hash splitStatements:false
CREATE OR REPLACE FUNCTION ph13_audit.fn_hash(p_prev text, p_canonical text) RETURNS text
  LANGUAGE sql IMMUTABLE AS $f$
  SELECT encode(sha256(convert_to(p_prev, 'UTF8') || convert_to(p_canonical, 'UTF8')), 'hex')
$f$;
COMMENT ON FUNCTION ph13_audit.fn_hash(text, text) IS 'hash = SHA-256(prev_hash ‖ canonical_json) dạng thập lục phân; canonical_json là JCS do ứng dụng dựng (SDD §4.4). Dùng cho bộ vector và đối chiếu bằng SQL.';
-- @rollback DROP FUNCTION IF EXISTS ph13_audit.fn_hash(text, text);

-- @file 13-0010-chain.sql
-- @changeset ph13-0100-audit-signing-key
CREATE TABLE ph13_audit.audit_signing_key (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  key_version      integer       NOT NULL,
  algorithm        varchar(16)   NOT NULL DEFAULT 'ECDSA-P256',
  key_name         varchar(64)   NOT NULL DEFAULT 'dh-audit-sign',
  public_key_pem   text          NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  activated_at     timestamptz   NOT NULL DEFAULT now(),
  retired_at       timestamptz,
  worm_object      varchar(512),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_signing_key PRIMARY KEY (id),
  CONSTRAINT uq_audit_signing_key_version UNIQUE (key_version),
  CONSTRAINT ck_audit_signing_key_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_audit_signing_key_version CHECK (key_version >= 1),
  CONSTRAINT ck_audit_signing_key_alg CHECK (algorithm IN ('ECDSA-P256')),
  CONSTRAINT ck_audit_signing_key_status CHECK (status IN ('ACTIVE', 'ROTATED')),
  CONSTRAINT ck_audit_signing_key_pem CHECK (public_key_pem LIKE '-----BEGIN PUBLIC KEY-----%'),
  CONSTRAINT ck_audit_signing_key_retired CHECK ((status = 'ROTATED') = (retired_at IS NOT NULL))
);
CREATE UNIQUE INDEX ux_audit_signing_key_active ON ph13_audit.audit_signing_key (key_name) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_audit_signing_key_touch BEFORE UPDATE ON ph13_audit.audit_signing_key FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_signing_key_imm BEFORE UPDATE ON ph13_audit.audit_signing_key FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'key_version', 'algorithm', 'key_name', 'public_key_pem', 'activated_at');
CREATE TRIGGER tg_audit_signing_key_nodel BEFORE DELETE ON ph13_audit.audit_signing_key FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_signing_key', 'S');
COMMENT ON TABLE ph13_audit.audit_signing_key IS 'Khóa công khai của khóa ký neo và gói bằng chứng dh-audit-sign theo phiên bản (SDD §4.5, Q13-13). Vì là khóa của nền tảng, tenant_id luôn là PLATFORM; mọi tenant đọc được để xác minh, chỉ phiên PLATFORM ghi. Khóa riêng ở OpenBao Transit, không xuất.';
COMMENT ON COLUMN ph13_audit.audit_signing_key.key_version IS 'Số phiên bản của khóa ở OpenBao; neo mang key_version để kiểm lại bằng khóa công khai cũ.';
COMMENT ON COLUMN ph13_audit.audit_signing_key.worm_object IS 'Đối tượng keys/dh-audit-sign.json ở WORM chứa khóa công khai, để xác minh không phụ thuộc OpenBao.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_signing_key CASCADE;

-- @changeset ph13-0110-audit-chain
CREATE TABLE ph13_audit.audit_chain (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  genesis_hash     char(64)      NOT NULL,
  head_seq         bigint        NOT NULL DEFAULT 0,
  head_hash        char(64)      NOT NULL,
  last_recorded_at timestamptz,
  status           varchar(8)    NOT NULL DEFAULT 'OPEN',
  integrity        varchar(8)    NOT NULL DEFAULT 'OK',
  suspect_from_seq bigint,
  suspect_since    timestamptz,
  closed_at        timestamptz,
  closed_reason    varchar(500),
  merged_into      varchar(16),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_chain PRIMARY KEY (id),
  CONSTRAINT uq_audit_chain_tenant UNIQUE (tenant_id),
  CONSTRAINT uq_audit_chain_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_audit_chain_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_chain_genesis CHECK (genesis_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_chain_head_hash CHECK (head_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_chain_head CHECK (head_seq >= 0 AND (head_seq > 0 OR head_hash = genesis_hash)),
  CONSTRAINT ck_audit_chain_last_recorded CHECK ((head_seq = 0) = (last_recorded_at IS NULL)),
  CONSTRAINT ck_audit_chain_status CHECK (status IN ('OPEN', 'CLOSED')),
  CONSTRAINT ck_audit_chain_integrity CHECK (integrity IN ('OK', 'SUSPECT')),
  CONSTRAINT ck_audit_chain_suspect CHECK ((integrity = 'SUSPECT') = (suspect_from_seq IS NOT NULL AND suspect_since IS NOT NULL)),
  CONSTRAINT ck_audit_chain_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL AND closed_reason IS NOT NULL)),
  CONSTRAINT ck_audit_chain_merged CHECK (merged_into IS NULL OR (status = 'CLOSED' AND merged_into ~ '^T[0-9]{2}$'))
);
CREATE TRIGGER tg_audit_chain_touch BEFORE UPDATE ON ph13_audit.audit_chain FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_chain_imm BEFORE UPDATE ON ph13_audit.audit_chain FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'genesis_hash', 'created_at');
CREATE TRIGGER tg_audit_chain_nodel BEFORE DELETE ON ph13_audit.audit_chain FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
ALTER TABLE ph13_audit.audit_chain SET (fillfactor = 70, autovacuum_vacuum_scale_factor = 0.02);   -- cập nhật mỗi lô: chừa chỗ cho HOT
CALL ph13_audit.p_enable_rls('ph13_audit.audit_chain', 'P');
COMMENT ON TABLE ph13_audit.audit_chain IS 'EN-13-03 Chuỗi kiểm toán, mỗi tenant một dòng (tenant PLATFORM cũng có chuỗi riêng). Đầu chuỗi chỉ nhích qua trigger tg_audit_chain_guard (FR-13-011, 059, 060). Không xóa dòng.';
COMMENT ON COLUMN ph13_audit.audit_chain.genesis_hash IS 'SHA-256("genesis:" ‖ mã tenant ‖ thời điểm ‖ nonce); prev_hash của bản ghi đầu tiên.';
COMMENT ON COLUMN ph13_audit.audit_chain.head_seq IS 'seq của bản ghi cuối; 0 khi chuỗi chưa có bản ghi. Chỉ tăng.';
COMMENT ON COLUMN ph13_audit.audit_chain.last_recorded_at IS 'recorded_at của bản ghi cuối; không lùi (giữ phân vùng đơn điệu), làm cận cắt phân vùng cho truy vấn.';
COMMENT ON COLUMN ph13_audit.audit_chain.integrity IS 'OK hoặc SUSPECT (đứt chuỗi, neo lệch, TamperProbe); tách khỏi status vì chuỗi OPEN vẫn nhận bản ghi khi SUSPECT (FR-13-015).';
COMMENT ON COLUMN ph13_audit.audit_chain.merged_into IS 'Tenant đích khi tenant nguồn sáp nhập; chuỗi nguồn không gộp vật lý (FR-13-060).';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_chain CASCADE;

-- @changeset ph13-0120-audit-event splitStatements:false
CREATE TABLE ph13_audit.audit_event (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  seq                bigint        NOT NULL,
  occurred_at        timestamptz   NOT NULL,
  recorded_at        timestamptz   NOT NULL,
  actor_type         varchar(6)    NOT NULL,
  actor_id           varchar(128)  NOT NULL,
  actor_name         varchar(255)  NOT NULL,
  actor_home_tenant  varchar(16),
  source_ip          varchar(45)   NOT NULL,
  user_agent         varchar(512)  NOT NULL,
  session_hash       char(64),
  action             varchar(96)   NOT NULL,
  object_type        varchar(64)   NOT NULL,
  object_id          varchar(128)  NOT NULL,
  object_key_hmac    char(64),
  before             jsonb,
  after              jsonb,
  outcome            varchar(7)    NOT NULL,
  error_code         varchar(32),
  reason             varchar(500),
  purpose            varchar(64),
  trace_id           char(32)      NOT NULL,
  source_du          varchar(32)   NOT NULL,
  clock_skew         boolean       NOT NULL DEFAULT false,
  hash_version       smallint      NOT NULL DEFAULT 1,
  prev_hash          char(64)      NOT NULL,
  hash               char(64)      NOT NULL,
  CONSTRAINT pk_audit_event PRIMARY KEY (tenant_id, seq, recorded_at),
  CONSTRAINT ck_audit_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_event_home_tenant CHECK (actor_home_tenant IS NULL OR actor_home_tenant ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_event_seq CHECK (seq >= 1),
  CONSTRAINT ck_audit_event_actor_type CHECK (actor_type IN ('USER', 'CLIENT', 'SYSTEM')),
  CONSTRAINT ck_audit_event_system_actor CHECK (actor_type <> 'SYSTEM' OR actor_id LIKE 'system:%'),
  CONSTRAINT ck_audit_event_action CHECK (action ~ '^[A-Z][A-Z0-9_]*(\.[A-Z0-9_]+)+$'),
  CONSTRAINT ck_audit_event_outcome CHECK (outcome IN ('SUCCESS', 'DENIED', 'FAILED')),
  CONSTRAINT ck_audit_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_audit_event_hashes CHECK (prev_hash ~ '^[0-9a-f]{64}$' AND hash ~ '^[0-9a-f]{64}$' AND hash <> prev_hash),
  CONSTRAINT ck_audit_event_hmac CHECK (object_key_hmac IS NULL OR object_key_hmac ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_event_session CHECK (session_hash IS NULL OR session_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_event_json_shape CHECK ((before IS NULL OR jsonb_typeof(before) = 'object') AND (after IS NULL OR jsonb_typeof(after) = 'object')),
  CONSTRAINT ck_audit_event_json_size CHECK (octet_length(coalesce(before::text, '')) <= 65536 AND octet_length(coalesce(after::text, '')) <= 65536),
  -- Lớp phòng thủ thứ hai cho BR-13-035: khóa có tên bí mật phải mang giá trị đã che "***".
  CONSTRAINT ck_audit_event_no_secret CHECK (
    coalesce(before::text, '') !~* '"(password|secret|clientsecret|apikey|privatekey|passphrase|token)"\s*:\s*"(?!\*\*\*")'
    AND coalesce(after::text, '') !~* '"(password|secret|clientsecret|apikey|privatekey|passphrase|token)"\s*:\s*"(?!\*\*\*")'),
  CONSTRAINT ck_audit_event_reason CHECK (reason IS NULL OR char_length(btrim(reason)) >= 1)
) PARTITION BY RANGE (recorded_at);
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_event CASCADE;

-- @changeset ph13-0121-audit-event-partitions splitStatements:false
-- Phân vùng tháng theo múi giờ Asia/Ho_Chi_Minh (giả định, Q13-50). SECURITY DEFINER để ph13_app (PartitionManager)
-- tạo phân vùng mà không cần quyền DDL; phân vùng thuộc ph13_owner và không cấp quyền riêng cho ai (chỉ truy cập qua bảng cha).
CREATE OR REPLACE PROCEDURE ph13_audit.p_ensure_month_partitions(p_from date, p_months integer)
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
  lo timestamptz;
  hi timestamptz;
BEGIN
  IF p_months < 1 OR p_months > 24 THEN RAISE EXCEPTION 'p_months phải trong 1..24'; END IF;
  FOR i IN 0 .. p_months - 1 LOOP
    part := 'audit_event_' || to_char(d + make_interval(months => i), 'YYYYMM');
    lo := ((d + make_interval(months => i))::timestamp) AT TIME ZONE 'Asia/Ho_Chi_Minh';
    hi := ((d + make_interval(months => i + 1))::timestamp) AT TIME ZONE 'Asia/Ho_Chi_Minh';
    IF to_regclass('ph13_audit.' || part) IS NULL THEN
      EXECUTE format('CREATE TABLE ph13_audit.%I PARTITION OF ph13_audit.audit_event FOR VALUES FROM (%L) TO (%L)', part, lo, hi);
      EXECUTE format('REVOKE ALL ON ph13_audit.%I FROM PUBLIC', part);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph13_audit.p_ensure_month_partitions(date, integer) IS 'Tạo phân vùng tháng audit_event (cận Asia/Ho_Chi_Minh); PartitionManager gọi hằng ngày để luôn có 3 tháng tới (FR-13-018). Không cấp quyền trực tiếp trên phân vùng.';
CALL ph13_audit.p_ensure_month_partitions((current_date - interval '1 month')::date, 6);
-- @rollback DROP PROCEDURE IF EXISTS ph13_audit.p_ensure_month_partitions(date, integer);

-- @changeset ph13-0122-audit-event-indexes
CREATE INDEX ix_audit_event_time ON ph13_audit.audit_event (tenant_id, recorded_at DESC, seq DESC);
CREATE INDEX ix_audit_event_object ON ph13_audit.audit_event (tenant_id, object_type, object_id, recorded_at DESC);
CREATE INDEX ix_audit_event_actor ON ph13_audit.audit_event (tenant_id, actor_id, recorded_at DESC);
CREATE INDEX ix_audit_event_action ON ph13_audit.audit_event (tenant_id, action, recorded_at DESC);
CREATE INDEX ix_audit_event_trace ON ph13_audit.audit_event (tenant_id, trace_id);
CREATE INDEX ix_audit_event_keyhmac ON ph13_audit.audit_event (tenant_id, object_key_hmac, recorded_at DESC) WHERE object_key_hmac IS NOT NULL;
CREATE INDEX ix_audit_event_id ON ph13_audit.audit_event (tenant_id, id);
CREATE INDEX ix_audit_event_source ON ph13_audit.audit_event (tenant_id, source_du, occurred_at);
CREATE INDEX ix_audit_event_session ON ph13_audit.audit_event (tenant_id, session_hash) WHERE session_hash IS NOT NULL;
-- @rollback DROP INDEX IF EXISTS ph13_audit.ix_audit_event_time, ph13_audit.ix_audit_event_object, ph13_audit.ix_audit_event_actor, ph13_audit.ix_audit_event_action, ph13_audit.ix_audit_event_trace, ph13_audit.ix_audit_event_keyhmac, ph13_audit.ix_audit_event_id, ph13_audit.ix_audit_event_source, ph13_audit.ix_audit_event_session;

-- @changeset ph13-0123-audit-event-guards splitStatements:false
-- (1) Chỉ thêm. (2) Mọi bản ghi phải được đầu chuỗi bao phủ khi cam kết. (3) Đầu chuỗi chỉ nhích khi bản ghi mới liền kề, nối đúng.
CREATE TRIGGER tg_audit_event_append BEFORE UPDATE OR DELETE ON ph13_audit.audit_event FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_append_only();
CREATE TRIGGER tg_audit_event_truncate BEFORE TRUNCATE ON ph13_audit.audit_event FOR EACH STATEMENT EXECUTE FUNCTION ph13_audit.tg_append_only();

CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_event_covered() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ph13_audit.audit_chain c WHERE c.tenant_id = NEW.tenant_id AND c.head_seq >= NEW.seq) THEN
    RAISE EXCEPTION 'Bản ghi seq=% của % chưa được đầu chuỗi bao phủ khi cam kết (ERR-13-106)', NEW.seq, NEW.tenant_id USING ERRCODE = '23514';
  END IF;
  RETURN NULL;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_event_covered() IS 'Constraint trigger hoãn: bản ghi chỉ cam kết khi audit_chain.head_seq đã bao phủ seq của nó (không có bản ghi mồ côi ngoài chuỗi).';
CREATE CONSTRAINT TRIGGER tg_audit_event_covered AFTER INSERT ON ph13_audit.audit_event
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_event_covered();

CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_chain_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  lo timestamptz := coalesce(OLD.last_recorded_at, '-infinity');
  n bigint;
BEGIN
  IF OLD.status = 'CLOSED' AND NEW.status <> 'CLOSED' THEN
    RAISE EXCEPTION 'Chuỗi % đã đóng, không mở lại (ERR-13-043)', OLD.tenant_id USING ERRCODE = '55000';
  END IF;
  IF NEW.head_seq < OLD.head_seq THEN
    RAISE EXCEPTION 'head_seq của chuỗi % không được giảm (% -> %)', OLD.tenant_id, OLD.head_seq, NEW.head_seq USING ERRCODE = '55000';
  END IF;
  IF NEW.head_seq = OLD.head_seq THEN
    IF NEW.head_hash <> OLD.head_hash OR NEW.last_recorded_at IS DISTINCT FROM OLD.last_recorded_at THEN
      RAISE EXCEPTION 'Không đổi head_hash khi head_seq giữ nguyên' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.status = 'CLOSED' THEN
    RAISE EXCEPTION 'Chuỗi % đã đóng, không nhận bản ghi (ERR-13-043)', OLD.tenant_id USING ERRCODE = '55000';
  END IF;
  IF NEW.last_recorded_at IS NULL OR NEW.last_recorded_at < lo THEN
    RAISE EXCEPTION 'last_recorded_at không được lùi' USING ERRCODE = '55000';
  END IF;
  -- Liền kề, không khoảng trống, không trùng seq trong đoạn mới.
  SELECT count(*) INTO n FROM ph13_audit.audit_event e
   WHERE e.tenant_id = NEW.tenant_id AND e.recorded_at >= lo AND e.recorded_at <= NEW.last_recorded_at AND e.seq > OLD.head_seq AND e.seq <= NEW.head_seq;
  IF n <> NEW.head_seq - OLD.head_seq THEN
    RAISE EXCEPTION 'Đoạn seq (%..%] của % có % bản ghi, cần % (khoảng trống hoặc trùng seq)', OLD.head_seq, NEW.head_seq, NEW.tenant_id, n, NEW.head_seq - OLD.head_seq USING ERRCODE = '23514';
  END IF;
  -- Bản ghi đầu đoạn nối đúng đầu chuỗi cũ; mỗi bản ghi nối đúng bản trước.
  IF NOT EXISTS (SELECT 1 FROM ph13_audit.audit_event e WHERE e.tenant_id = NEW.tenant_id AND e.recorded_at >= lo AND e.recorded_at <= NEW.last_recorded_at
                  AND e.seq = OLD.head_seq + 1 AND e.prev_hash = OLD.head_hash) THEN
    RAISE EXCEPTION 'Bản ghi seq=% của % không nối đúng head_hash cũ', OLD.head_seq + 1, NEW.tenant_id USING ERRCODE = '23514';
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT e.prev_hash, lag(e.hash) OVER (ORDER BY e.seq) AS ph
      FROM ph13_audit.audit_event e
     WHERE e.tenant_id = NEW.tenant_id AND e.recorded_at >= lo AND e.recorded_at <= NEW.last_recorded_at AND e.seq > OLD.head_seq AND e.seq <= NEW.head_seq) x
   WHERE x.ph IS NOT NULL AND x.prev_hash <> x.ph;
  IF n <> 0 THEN
    RAISE EXCEPTION 'Có % bản ghi không nối đúng bản liền trước trong đoạn (%..%] của %', n, OLD.head_seq, NEW.head_seq, NEW.tenant_id USING ERRCODE = '23514';
  END IF;
  -- Bản ghi cuối khớp head_hash và last_recorded_at.
  IF NOT EXISTS (SELECT 1 FROM ph13_audit.audit_event e WHERE e.tenant_id = NEW.tenant_id AND e.recorded_at = NEW.last_recorded_at
                  AND e.seq = NEW.head_seq AND e.hash = NEW.head_hash) THEN
    RAISE EXCEPTION 'head_hash/last_recorded_at không khớp bản ghi seq=% của %', NEW.head_seq, NEW.tenant_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_chain_guard() IS 'Đầu chuỗi chỉ nhích khi các bản ghi mới liền kề, nối đúng prev_hash, bản cuối khớp head_hash; chuỗi CLOSED không nhận bản ghi (BR-13-002, FR-13-011).';
CREATE TRIGGER tg_audit_chain_guard BEFORE UPDATE ON ph13_audit.audit_chain FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_chain_guard();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_event', 'P');
COMMENT ON TABLE ph13_audit.audit_event IS 'EN-13-01 Bản ghi kiểm toán, chỉ thêm, phân vùng tháng theo recorded_at; trực tuyến 12 tháng, WORM 5 năm (FR-13-010, 011, 018). seq liên tục theo tenant, hash nối chuỗi; PH-13 gán seq, recorded_at, source_du, prev_hash, hash.';
COMMENT ON COLUMN ph13_audit.audit_event.id IS 'UUID v7 do DU sinh; khử trùng theo (tenant_id, id) với cận recorded_at (SDD §4.3), không ràng buộc duy nhất vì bảng phân vùng theo recorded_at.';
COMMENT ON COLUMN ph13_audit.audit_event.seq IS 'Liên tục trong chuỗi tenant, không khoảng trống; trigger tg_audit_chain_guard kiểm khi đầu chuỗi nhích.';
COMMENT ON COLUMN ph13_audit.audit_event.recorded_at IS 'Giờ ghi vào bảng, quyết định phân vùng; không lùi theo tenant (ChainWriter dùng max(now, last_recorded_at)).';
COMMENT ON COLUMN ph13_audit.audit_event.object_key_hmac IS 'HMAC-SHA256 theo khóa tenant dh-{tenant}-audit-hmac của khóa nghiệp vụ nhạy cảm (số định danh); không bao giờ lưu số định danh thật (BR-13-005).';
COMMENT ON COLUMN ph13_audit.audit_event.before IS 'Giá trị trước đã che theo D03-07 §3.2; ck_audit_event_no_secret chặn khóa bí mật mang giá trị chưa che (BR-13-035).';
COMMENT ON COLUMN ph13_audit.audit_event.source_du IS 'DU nguồn do PH-13 điền theo chứng thư của bên gửi; dùng đối chiếu số lượng (FR-13-017).';
COMMENT ON COLUMN ph13_audit.audit_event.clock_skew IS 'true khi occurred_at lệch giờ PH-13 quá 2 giây về tương lai (ERR-13-126); vẫn ghi.';
COMMENT ON COLUMN ph13_audit.audit_event.hash_version IS 'Phiên bản thuật toán dựng bản ghi chuẩn tắc (v trong R, SDD §4.4); hiện là 1.';
COMMENT ON COLUMN ph13_audit.audit_event.hash IS 'hash = SHA-256(prev_hash ‖ JCS(R)), R gồm mọi cột trừ hash, kèm hash_version (SDD §4.4).';
-- @rollback DROP TRIGGER IF EXISTS tg_audit_chain_guard ON ph13_audit.audit_chain; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_chain_guard(); DROP FUNCTION IF EXISTS ph13_audit.tg_audit_event_covered() CASCADE;

-- @file 13-0020-anchor.sql
-- @changeset ph13-0200-audit-anchor splitStatements:false
CREATE TABLE ph13_audit.audit_anchor (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  seq_last         bigint        NOT NULL,
  hash_last        char(64)      NOT NULL,
  anchored_at      timestamptz   NOT NULL,
  kind             varchar(8)    NOT NULL DEFAULT 'PERIODIC',
  key_version      integer       NOT NULL,
  payload_digest   char(64)      NOT NULL,
  signature        text          NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_audit_anchor PRIMARY KEY (id),
  CONSTRAINT uq_audit_anchor_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_audit_anchor_time UNIQUE (tenant_id, anchored_at),
  CONSTRAINT fk_audit_anchor_key FOREIGN KEY (key_version) REFERENCES ph13_audit.audit_signing_key (key_version),
  CONSTRAINT ck_audit_anchor_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_anchor_seq CHECK (seq_last >= 0),
  CONSTRAINT ck_audit_anchor_hash CHECK (hash_last ~ '^[0-9a-f]{64}$' AND payload_digest ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_anchor_kind CHECK (kind IN ('PERIODIC', 'BOUNDARY', 'FINAL')),
  CONSTRAINT ck_audit_anchor_signature CHECK (char_length(signature) BETWEEN 40 AND 4096)
);
CREATE INDEX ix_audit_anchor_seq ON ph13_audit.audit_anchor (tenant_id, seq_last DESC);
CREATE INDEX ix_audit_anchor_kind ON ph13_audit.audit_anchor (tenant_id, kind, anchored_at DESC) WHERE kind <> 'PERIODIC';
CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_anchor_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE prev bigint; head bigint; fin boolean;
BEGIN
  SELECT max(seq_last), bool_or(kind = 'FINAL') INTO prev, fin FROM ph13_audit.audit_anchor WHERE tenant_id = NEW.tenant_id;
  IF fin THEN RAISE EXCEPTION 'Chuỗi % đã có neo cuối FINAL, không thêm neo' , NEW.tenant_id USING ERRCODE = '55000'; END IF;
  IF prev IS NOT NULL AND NEW.seq_last < prev THEN
    RAISE EXCEPTION 'seq_last của neo không được giảm (% < %)', NEW.seq_last, prev USING ERRCODE = '23514';
  END IF;
  SELECT head_seq INTO head FROM ph13_audit.audit_chain WHERE tenant_id = NEW.tenant_id;
  IF head IS NULL OR NEW.seq_last > head THEN
    RAISE EXCEPTION 'Neo trỏ seq % vượt đầu chuỗi % của %', NEW.seq_last, head, NEW.tenant_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_anchor_guard() IS 'Neo không lùi, không vượt đầu chuỗi, không thêm sau neo FINAL (BR-13-013, SDD §4.5).';
CREATE TRIGGER tg_audit_anchor_guard BEFORE INSERT ON ph13_audit.audit_anchor FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_anchor_guard();
CREATE TRIGGER tg_audit_anchor_append BEFORE UPDATE OR DELETE ON ph13_audit.audit_anchor FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_append_only();
CREATE TRIGGER tg_audit_anchor_truncate BEFORE TRUNCATE ON ph13_audit.audit_anchor FOR EACH STATEMENT EXECUTE FUNCTION ph13_audit.tg_append_only();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_anchor', 'P');
COMMENT ON TABLE ph13_audit.audit_anchor IS 'EN-13-02 Neo toàn vẹn: tóm tắt {tenant, seq cuối, hash cuối, thời điểm} ký bằng dh-audit-sign mỗi giờ; chỉ thêm, giữ vĩnh viễn (FR-13-012). Nơi công bố (WORM, SIEM) ở audit_anchor_publish để bảng này thuần chỉ-thêm.';
COMMENT ON COLUMN ph13_audit.audit_anchor.kind IS 'PERIODIC (hằng giờ), BOUNDARY (ranh giới phân vùng tháng, điểm xuất phát sau lưu trữ), FINAL (neo cuối khi đóng chuỗi).';
COMMENT ON COLUMN ph13_audit.audit_anchor.payload_digest IS 'SHA-256("datahub-audit-anchor-v1\n" ‖ tải JCS); tiền tố tên miền để chữ ký neo không dùng lại cho gói bằng chứng.';
COMMENT ON COLUMN ph13_audit.audit_anchor.signature IS 'Chữ ký ASN.1 (base64) từ transit/sign/dh-audit-sign/sha2-256, prehashed.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_anchor CASCADE; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_anchor_guard();

-- @changeset ph13-0210-audit-anchor-publish
CREATE TABLE ph13_audit.audit_anchor_publish (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  anchor_id        uuid          NOT NULL,
  worm_object      varchar(512),
  worm_written_at  timestamptz,
  worm_pending     boolean       NOT NULL DEFAULT true,
  siem_target_code varchar(64),
  siem_ack_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_anchor_publish PRIMARY KEY (id),
  CONSTRAINT uq_audit_anchor_publish_anchor UNIQUE (anchor_id),
  CONSTRAINT fk_audit_anchor_publish_anchor FOREIGN KEY (anchor_id, tenant_id) REFERENCES ph13_audit.audit_anchor (id, tenant_id),
  CONSTRAINT ck_audit_anchor_publish_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_anchor_publish_worm CHECK (worm_pending = (worm_object IS NULL)),
  CONSTRAINT ck_audit_anchor_publish_worm_time CHECK ((worm_object IS NULL) = (worm_written_at IS NULL)),
  CONSTRAINT ck_audit_anchor_publish_siem CHECK (siem_ack_at IS NULL OR siem_target_code IS NOT NULL)
);
CREATE INDEX ix_audit_anchor_publish_pending ON ph13_audit.audit_anchor_publish (tenant_id, created_at) WHERE worm_pending;
CREATE TRIGGER tg_audit_anchor_publish_touch BEFORE UPDATE ON ph13_audit.audit_anchor_publish FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_anchor_publish_imm BEFORE UPDATE ON ph13_audit.audit_anchor_publish FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'anchor_id');
CREATE TRIGGER tg_audit_anchor_publish_nodel BEFORE DELETE ON ph13_audit.audit_anchor_publish FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_anchor_publish', 'P');
COMMENT ON TABLE ph13_audit.audit_anchor_publish IS 'Nơi công bố của neo: đối tượng anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json ở WORM và xác nhận của SIEM (EN-13-02 cột worm_object, siem_ack_at; FR-13-012, BR-13-013). Neo vẫn hợp lệ khi chưa công bố (worm_pending).';
COMMENT ON COLUMN ph13_audit.audit_anchor_publish.worm_pending IS 'true khi chưa ghi được WORM (ERR-13-108); neo vẫn có ở bảng audit_anchor.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_anchor_publish CASCADE;

-- @file 13-0030-worm.sql
-- @changeset ph13-0300-audit-worm-batch splitStatements:false
CREATE TABLE ph13_audit.audit_worm_batch (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  seq_from         bigint        NOT NULL,
  seq_to           bigint        NOT NULL,
  record_count     integer       NOT NULL,
  object_key       varchar(512)  NOT NULL,
  manifest_key     varchar(512)  NOT NULL,
  sha256           char(64)      NOT NULL,
  prev_batch_sha256 char(64),
  etag             varchar(128),
  size_bytes       bigint        NOT NULL,
  retain_until     timestamptz   NOT NULL,
  verified_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_audit_worm_batch PRIMARY KEY (id),
  CONSTRAINT uq_audit_worm_batch_object UNIQUE (tenant_id, object_key),
  CONSTRAINT uq_audit_worm_batch_from UNIQUE (tenant_id, seq_from),
  CONSTRAINT ex_audit_worm_batch_range EXCLUDE USING gist (tenant_id WITH =, int8range(seq_from, seq_to, '[]') WITH &&),
  CONSTRAINT ck_audit_worm_batch_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_worm_batch_range CHECK (seq_from >= 1 AND seq_to >= seq_from),
  CONSTRAINT ck_audit_worm_batch_count CHECK (record_count = seq_to - seq_from + 1 AND record_count <= 50000),
  CONSTRAINT ck_audit_worm_batch_sha CHECK (sha256 ~ '^[0-9a-f]{64}$' AND (prev_batch_sha256 IS NULL OR prev_batch_sha256 ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_audit_worm_batch_first CHECK ((seq_from = 1) = (prev_batch_sha256 IS NULL)),
  CONSTRAINT ck_audit_worm_batch_size CHECK (size_bytes > 0),
  CONSTRAINT ck_audit_worm_batch_key CHECK (object_key ~ '^audit/[A-Za-z0-9]+/[0-9]{4}/[0-9]{2}/[0-9]{2}/[0-9]+-[0-9]+\.jsonl\.zst$')
);
CREATE INDEX ix_audit_worm_batch_unverified ON ph13_audit.audit_worm_batch (tenant_id, seq_from) WHERE verified_at IS NULL;
CREATE INDEX ix_audit_worm_batch_retain ON ph13_audit.audit_worm_batch (retain_until);
CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_worm_batch_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE prev_to bigint; head bigint;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT max(seq_to) INTO prev_to FROM ph13_audit.audit_worm_batch WHERE tenant_id = NEW.tenant_id;
    IF NEW.seq_from <> coalesce(prev_to, 0) + 1 THEN
      RAISE EXCEPTION 'Lô WORM của % phải bắt đầu ở seq % (liền kề lô trước), nhận %', NEW.tenant_id, coalesce(prev_to, 0) + 1, NEW.seq_from USING ERRCODE = '23514';
    END IF;
    SELECT head_seq INTO head FROM ph13_audit.audit_chain WHERE tenant_id = NEW.tenant_id;
    IF head IS NULL OR NEW.seq_to > head THEN
      RAISE EXCEPTION 'Lô WORM vượt đầu chuỗi (% > %)', NEW.seq_to, head USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
  END IF;
  -- UPDATE: chỉ verified_at, etag, retain_until (chỉ kéo dài, BR-13-020).
  IF NEW.retain_until < OLD.retain_until THEN
    RAISE EXCEPTION 'retain_until chỉ được kéo dài, không rút ngắn (BR-13-020)' USING ERRCODE = '55000';
  END IF;
  IF OLD.verified_at IS NOT NULL AND NEW.verified_at IS DISTINCT FROM OLD.verified_at AND NEW.verified_at < OLD.verified_at THEN
    RAISE EXCEPTION 'verified_at không được lùi' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_worm_batch_guard() IS 'Lô WORM liền kề không chồng, không vượt đầu chuỗi; retain_until chỉ kéo dài (BR-13-013, 020).';
CREATE TRIGGER tg_audit_worm_batch_guard BEFORE INSERT OR UPDATE ON ph13_audit.audit_worm_batch FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_worm_batch_guard();
CREATE TRIGGER tg_audit_worm_batch_imm BEFORE UPDATE ON ph13_audit.audit_worm_batch FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'seq_from', 'seq_to', 'record_count', 'object_key', 'manifest_key', 'sha256', 'prev_batch_sha256', 'size_bytes', 'created_at');
CREATE TRIGGER tg_audit_worm_batch_nodel BEFORE DELETE ON ph13_audit.audit_worm_batch FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_worm_batch', 'P');
COMMENT ON TABLE ph13_audit.audit_worm_batch IS 'Lô JSON Lines nén zstd đã sao sang WORM (Ceph RGW, Object Lock COMPLIANCE) mỗi 13.audit.worm-batch-minutes (FR-13-013). Dải seq liền kề không chồng; các lô nối nhau bằng prev_batch_sha256 thành chuỗi thứ hai. Siêu dữ liệu giữ cả sau khi đối tượng hết hạn khóa.';
COMMENT ON COLUMN ph13_audit.audit_worm_batch.sha256 IS 'Băm của tệp lô; trùng manifest.sha256 trên WORM.';
COMMENT ON COLUMN ph13_audit.audit_worm_batch.etag IS 'ETag do kho trả; đối chiếu bằng HeadObject trước khi ghi verified_at (Q13-23 nếu RGW mã hóa làm ETag không còn là MD5).';
COMMENT ON COLUMN ph13_audit.audit_worm_batch.retain_until IS 'Hạn Object Lock = ngày ghi + 13.audit.worm-retention-years; chỉ kéo dài (RetentionExtender).';
COMMENT ON COLUMN ph13_audit.audit_worm_batch.verified_at IS 'Thời điểm HeadObject đối chiếu ETag khớp; null thì lô chưa đủ điều kiện cho phân vùng SEALED.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_worm_batch CASCADE; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_worm_batch_guard();

-- @file 13-0040-verify-export.sql
-- @changeset ph13-0400-audit-verification splitStatements:false
CREATE TABLE ph13_audit.audit_verification (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  scope            varchar(10)   NOT NULL,
  worm_mode        varchar(6)    NOT NULL DEFAULT 'SAMPLE',
  from_seq         bigint        NOT NULL,
  to_seq           bigint        NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'RUNNING',
  first_break_seq  bigint,
  break_kind       varchar(32),
  checked_count    bigint        NOT NULL DEFAULT 0,
  worm_check       varchar(12),
  requested_by     varchar(64)   NOT NULL,
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_verification PRIMARY KEY (id),
  CONSTRAINT uq_audit_verification_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_audit_verification_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_verification_scope CHECK (scope IN ('DAILY', 'ON_DEMAND')),
  CONSTRAINT ck_audit_verification_worm_mode CHECK (worm_mode IN ('SAMPLE', 'FULL', 'NONE')),
  CONSTRAINT ck_audit_verification_range CHECK (from_seq >= 0 AND to_seq >= from_seq),
  CONSTRAINT ck_audit_verification_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED')),
  CONSTRAINT ck_audit_verification_break CHECK ((status = 'FAILED') = (first_break_seq IS NOT NULL AND break_kind IS NOT NULL)),
  CONSTRAINT ck_audit_verification_break_kind CHECK (break_kind IS NULL OR break_kind IN ('HASH_MISMATCH', 'SEQ_GAP', 'ANCHOR_SIGNATURE_INVALID', 'ANCHOR_MISMATCH', 'WORM_MISMATCH')),
  CONSTRAINT ck_audit_verification_finished CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_audit_verification_worm_check CHECK (worm_check IS NULL OR worm_check IN ('FULL', 'SAMPLE', 'NONE', 'UNAVAILABLE')),
  CONSTRAINT ck_audit_verification_passed_worm CHECK (status <> 'PASSED' OR worm_check IS NOT NULL),
  CONSTRAINT ck_audit_verification_count CHECK (checked_count >= 0)
);
CREATE UNIQUE INDEX ux_audit_verification_running ON ph13_audit.audit_verification (tenant_id) WHERE status = 'RUNNING';
CREATE INDEX ix_audit_verification_tenant ON ph13_audit.audit_verification (tenant_id, started_at DESC);
CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_verification_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status <> 'RUNNING' THEN
    RAISE EXCEPTION 'Kết quả xác minh % đã chốt (%), không sửa', OLD.id, OLD.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_verification_guard() IS 'Lượt xác minh đã PASSED hoặc FAILED là bất biến.';
CREATE TRIGGER tg_audit_verification_touch BEFORE UPDATE ON ph13_audit.audit_verification FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_verification_guard BEFORE UPDATE ON ph13_audit.audit_verification FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_verification_guard();
CREATE TRIGGER tg_audit_verification_imm BEFORE UPDATE ON ph13_audit.audit_verification FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'scope', 'from_seq', 'requested_by', 'started_at');
CREATE TRIGGER tg_audit_verification_ret BEFORE DELETE ON ph13_audit.audit_verification FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_guard_retention('started_at', '5 years');
CALL ph13_audit.p_enable_rls('ph13_audit.audit_verification', 'P');
COMMENT ON TABLE ph13_audit.audit_verification IS 'EN-13-04 Lượt xác minh toàn vẹn chuỗi, theo lịch (DAILY) hoặc theo yêu cầu (ON_DEMAND); giữ 5 năm (FR-14, SDD §4.7). Mỗi tenant một lượt RUNNING (ERR-13-032).';
COMMENT ON COLUMN ph13_audit.audit_verification.first_break_seq IS 'seq nhỏ nhất bị đứt khi FAILED; vị trí đứt đầu tiên (FR-13-014, 015).';
COMMENT ON COLUMN ph13_audit.audit_verification.worm_check IS 'FULL (so đủ), SAMPLE (so mẫu 1%), NONE, UNAVAILABLE (WORM không đọc được: không báo đạt hoàn toàn).';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_verification CASCADE; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_verification_guard();

-- @changeset ph13-0410-audit-export splitStatements:false
CREATE TABLE ph13_audit.audit_export (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  filter             jsonb         NOT NULL,
  scope_hash         char(64)      NOT NULL,
  reason             varchar(500)  NOT NULL,
  basis              varchar(500)  NOT NULL,
  reauth_at          timestamptz   NOT NULL,
  status             varchar(10)   NOT NULL DEFAULT 'REQUESTED',
  record_count       bigint,
  file_object        varchar(512),
  file_hash          char(64),
  signature          text,
  manifest_signature text,
  key_version        integer,
  expires_at         timestamptz,
  requested_by       varchar(64)   NOT NULL,
  started_at         timestamptz,
  finished_at        timestamptz,
  cancelled_at       timestamptz,
  error_code         varchar(16),
  download_count     integer       NOT NULL DEFAULT 0,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_export PRIMARY KEY (id),
  CONSTRAINT uq_audit_export_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_audit_export_key FOREIGN KEY (key_version) REFERENCES ph13_audit.audit_signing_key (key_version),
  CONSTRAINT ck_audit_export_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_export_filter CHECK (jsonb_typeof(filter) = 'object'),
  CONSTRAINT ck_audit_export_scope_hash CHECK (scope_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_export_reason CHECK (char_length(btrim(reason)) BETWEEN 10 AND 500),
  CONSTRAINT ck_audit_export_basis CHECK (char_length(btrim(basis)) BETWEEN 10 AND 500),
  CONSTRAINT ck_audit_export_status CHECK (status IN ('REQUESTED', 'RUNNING', 'READY', 'FAILED', 'EXPIRED', 'CANCELLED')),
  CONSTRAINT ck_audit_export_count CHECK (record_count IS NULL OR (record_count >= 0 AND record_count <= 10000000)),
  CONSTRAINT ck_audit_export_file_hash CHECK (file_hash IS NULL OR file_hash ~ '^[0-9a-f]{64}$'),
  -- BR-13-014: chỉ READY (hoặc EXPIRED sau READY) khi đã ký cả gói lẫn bảng kê; không để lại tệp chưa ký.
  CONSTRAINT ck_audit_export_ready CHECK (status NOT IN ('READY') OR (record_count IS NOT NULL AND file_object IS NOT NULL AND file_hash IS NOT NULL
        AND signature IS NOT NULL AND manifest_signature IS NOT NULL AND key_version IS NOT NULL AND expires_at IS NOT NULL)),
  CONSTRAINT ck_audit_export_no_orphan_file CHECK (file_object IS NULL OR (signature IS NOT NULL AND manifest_signature IS NOT NULL)),
  CONSTRAINT ck_audit_export_failed CHECK (status <> 'FAILED' OR (file_object IS NULL AND error_code IS NOT NULL)),
  CONSTRAINT ck_audit_export_cancelled CHECK ((status = 'CANCELLED') = (cancelled_at IS NOT NULL)),
  CONSTRAINT ck_audit_export_download CHECK (download_count >= 0)
);
CREATE UNIQUE INDEX ux_audit_export_active ON ph13_audit.audit_export (tenant_id, scope_hash) WHERE status IN ('REQUESTED', 'RUNNING');
CREATE INDEX ix_audit_export_queue ON ph13_audit.audit_export (created_at) WHERE status = 'REQUESTED';
CREATE INDEX ix_audit_export_expiry ON ph13_audit.audit_export (expires_at) WHERE status = 'READY';
CREATE INDEX ix_audit_export_tenant ON ph13_audit.audit_export (tenant_id, created_at DESC);
CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_export_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.status <> OLD.status AND NOT (
       (OLD.status = 'REQUESTED' AND NEW.status IN ('RUNNING', 'CANCELLED'))
    OR (OLD.status = 'RUNNING' AND NEW.status IN ('READY', 'FAILED'))
    OR (OLD.status = 'READY' AND NEW.status = 'EXPIRED')) THEN
    RAISE EXCEPTION 'Không chuyển yêu cầu xuất % từ % sang % (ERR-13-020)', OLD.id, OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  IF OLD.status IN ('FAILED', 'EXPIRED', 'CANCELLED') THEN
    RAISE EXCEPTION 'Yêu cầu xuất % ở trạng thái cuối %, không sửa', OLD.id, OLD.status USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_export_guard() IS 'Bảng chuyển trạng thái yêu cầu xuất bằng chứng (FRS §4.6, SDD §8.1).';
CREATE TRIGGER tg_audit_export_touch BEFORE UPDATE ON ph13_audit.audit_export FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_export_guard BEFORE UPDATE ON ph13_audit.audit_export FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_export_guard();
CREATE TRIGGER tg_audit_export_imm BEFORE UPDATE ON ph13_audit.audit_export FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'filter', 'scope_hash', 'reason', 'basis', 'reauth_at', 'requested_by');
CREATE TRIGGER tg_audit_export_ret BEFORE DELETE ON ph13_audit.audit_export FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_guard_retention('created_at', '5 years');
CALL ph13_audit.p_enable_rls('ph13_audit.audit_export', 'P');
COMMENT ON TABLE ph13_audit.audit_export IS 'EN-13-05 Yêu cầu xuất bằng chứng kiểm toán ký số, chạy nền (FR-13-024). Siêu dữ liệu giữ 5 năm, tệp 7 ngày. Không hai yêu cầu cùng scope_hash đang chạy (ux_audit_export_active); READY chỉ khi đã ký.';
COMMENT ON COLUMN ph13_audit.audit_export.scope_hash IS 'SHA-256 của bộ lọc đã chuẩn hóa; khóa lũy đẳng chống chạy trùng.';
COMMENT ON COLUMN ph13_audit.audit_export.basis IS 'Căn cứ pháp lý, số hiệu yêu cầu của cơ quan hoặc kế hoạch thanh tra; bắt buộc (BR-13-007).';
COMMENT ON COLUMN ph13_audit.audit_export.reauth_at IS 'Thời điểm xác thực lại phiên (step-up) trước khi nhận yêu cầu (BR-13-029).';
COMMENT ON COLUMN ph13_audit.audit_export.signature IS 'Chữ ký số của gói; kèm manifest_signature là hai chữ ký bắt buộc để READY (SDD §8.1).';
COMMENT ON COLUMN ph13_audit.audit_export.file_object IS 'exports/{tenant}/{exportId}.zip ở bucket tạm; xóa sau 7 ngày, EXPIRED.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_export CASCADE; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_export_guard();

-- @file 13-0050-reconcile-partition.sql
-- @changeset ph13-0500-audit-reconciliation
CREATE TABLE ph13_audit.audit_reconciliation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  du_code          varchar(32)   NOT NULL,
  day              date          NOT NULL,
  emitted          bigint,
  received         bigint        NOT NULL DEFAULT 0,
  quarantined      bigint        NOT NULL DEFAULT 0,
  diff             bigint        GENERATED ALWAYS AS (emitted - received - quarantined) STORED,
  status           varchar(10)   NOT NULL DEFAULT 'PENDING',
  recheck_count    smallint      NOT NULL DEFAULT 0,
  checked_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_reconciliation PRIMARY KEY (id),
  CONSTRAINT uq_audit_reconciliation UNIQUE (tenant_id, du_code, day),
  CONSTRAINT ck_audit_reconciliation_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_reconciliation_du CHECK (du_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_audit_reconciliation_counts CHECK ((emitted IS NULL OR emitted >= 0) AND received >= 0 AND quarantined >= 0),
  CONSTRAINT ck_audit_reconciliation_status CHECK (status IN ('PENDING', 'MATCH', 'MISMATCH', 'SURPLUS', 'NO_COUNTER')),
  -- BR-13-001: MATCH chỉ khi chênh lệch bằng 0; MISMATCH khi thiếu; SURPLUS khi thừa.
  CONSTRAINT ck_audit_reconciliation_match CHECK (status <> 'MATCH' OR diff = 0),
  CONSTRAINT ck_audit_reconciliation_mismatch CHECK (status <> 'MISMATCH' OR diff > 0),
  CONSTRAINT ck_audit_reconciliation_surplus CHECK (status <> 'SURPLUS' OR diff < 0),
  CONSTRAINT ck_audit_reconciliation_nocounter CHECK ((status = 'NO_COUNTER') = (emitted IS NULL)),
  CONSTRAINT ck_audit_reconciliation_recheck CHECK (recheck_count >= 0)
);
CREATE INDEX ix_audit_reconciliation_bad ON ph13_audit.audit_reconciliation (tenant_id, day DESC) WHERE status IN ('MISMATCH', 'SURPLUS', 'NO_COUNTER');
CREATE TRIGGER tg_audit_reconciliation_touch BEFORE UPDATE ON ph13_audit.audit_reconciliation FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_reconciliation_imm BEFORE UPDATE ON ph13_audit.audit_reconciliation FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'du_code', 'day');
CREATE TRIGGER tg_audit_reconciliation_ret BEFORE DELETE ON ph13_audit.audit_reconciliation FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_guard_retention('created_at', '5 years');
CALL ph13_audit.p_enable_rls('ph13_audit.audit_reconciliation', 'P');
COMMENT ON TABLE ph13_audit.audit_reconciliation IS 'EN-13-06 Đối chiếu hằng ngày số bản ghi DU báo phát (dh_audit_emitted_day) với số PH-13 nhận theo (DU, tenant, ngày Asia/Ho_Chi_Minh); giữ 5 năm (FR-13-017). diff = emitted - received - quarantined.';
COMMENT ON COLUMN ph13_audit.audit_reconciliation.emitted IS 'Bộ đếm của DU; null khi DU không xuất bộ đếm (NO_COUNTER).';
COMMENT ON COLUMN ph13_audit.audit_reconciliation.quarantined IS 'Số bản ghi cùng điều kiện đang ở audit_quarantine, tính là đã nhận (SDD §4.8).';
COMMENT ON COLUMN ph13_audit.audit_reconciliation.recheck_count IS 'Số lần đếm lại sau 2 giờ khi diff > 0 trước khi kết luận MISMATCH.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_reconciliation CASCADE;

-- @changeset ph13-0510-audit-partition splitStatements:false
CREATE TABLE ph13_audit.audit_partition (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL DEFAULT 'PLATFORM',
  month            date          NOT NULL,
  partition_name   varchar(63)   NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'OPEN',
  record_count     bigint        NOT NULL DEFAULT 0,
  sealed_at        timestamptz,
  worm_verified_at timestamptz,
  archive_after    date,
  archived_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_partition PRIMARY KEY (id),
  CONSTRAINT uq_audit_partition_month UNIQUE (tenant_id, month),
  CONSTRAINT ck_audit_partition_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_audit_partition_month CHECK (month = date_trunc('month', month)::date),
  CONSTRAINT ck_audit_partition_name CHECK (partition_name = 'audit_event_' || to_char(month, 'YYYYMM')),
  CONSTRAINT ck_audit_partition_status CHECK (status IN ('OPEN', 'SEALED', 'ARCHIVED')),
  CONSTRAINT ck_audit_partition_count CHECK (record_count >= 0),
  CONSTRAINT ck_audit_partition_sealed CHECK ((status = 'OPEN') = (sealed_at IS NULL)),
  CONSTRAINT ck_audit_partition_archived CHECK ((status = 'ARCHIVED') = (archived_at IS NOT NULL)),
  CONSTRAINT ck_audit_partition_archived_worm CHECK (status <> 'ARCHIVED' OR (worm_verified_at IS NOT NULL AND archive_after IS NOT NULL))
);
CREATE OR REPLACE FUNCTION ph13_audit.tg_audit_partition_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.status <> OLD.status AND NOT ((OLD.status = 'OPEN' AND NEW.status = 'SEALED') OR (OLD.status = 'SEALED' AND NEW.status = 'ARCHIVED')) THEN
    RAISE EXCEPTION 'Phân vùng % không chuyển từ % sang %', OLD.partition_name, OLD.status, NEW.status USING ERRCODE = '55000';
  END IF;
  IF OLD.status = 'ARCHIVED' THEN
    RAISE EXCEPTION 'Phân vùng % đã lưu trữ, không sửa', OLD.partition_name USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph13_audit.tg_audit_partition_guard() IS 'OPEN -> SEALED -> ARCHIVED, một chiều (FRS §4.7).';
CREATE TRIGGER tg_audit_partition_touch BEFORE UPDATE ON ph13_audit.audit_partition FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_partition_guard BEFORE UPDATE ON ph13_audit.audit_partition FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_audit_partition_guard();
CREATE TRIGGER tg_audit_partition_imm BEFORE UPDATE ON ph13_audit.audit_partition FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'month', 'partition_name');
CREATE TRIGGER tg_audit_partition_nodel BEFORE DELETE ON ph13_audit.audit_partition FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_partition', 'P');
COMMENT ON TABLE ph13_audit.audit_partition IS 'EN-13-21 Vòng đời phân vùng tháng của audit_event: OPEN, SEALED, ARCHIVED (FR-13-018). Dòng chung cho mọi tenant nên tenant_id = PLATFORM; chỉ phiên PLATFORM (PartitionManager) đọc, ghi.';
COMMENT ON COLUMN ph13_audit.audit_partition.archive_after IS 'Ngày sớm nhất được lưu trữ = hết tháng + max(13.audit.online-months của mọi tenant có bản ghi) (SDD §6); ứng dụng tính, p_archive_partition kiểm.';
COMMENT ON COLUMN ph13_audit.audit_partition.worm_verified_at IS 'Thời điểm ArchiveService.preflight xác minh mọi lô WORM của dải seq khớp băm; điều kiện để ARCHIVED.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_partition CASCADE; DROP FUNCTION IF EXISTS ph13_audit.tg_audit_partition_guard();

-- @changeset ph13-0520-fn-archive-partition splitStatements:false
-- Đường duy nhất để một phân vùng audit_event rời bảng trực tuyến (BR-13-002 ngoại lệ có biên bản).
-- DEFINER (chủ ph13_owner); chỉ ph13_archive có EXECUTE. Dùng DETACH thường vì DETACH ... CONCURRENTLY không chạy được trong hàm (Q13-51).
CREATE OR REPLACE PROCEDURE ph13_audit.p_archive_partition(p_month date)
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $p$
DECLARE
  m date := date_trunc('month', p_month)::date;
  part text := 'audit_event_' || to_char(m, 'YYYYMM');
  r record;
  prev_tenant text := current_setting('app.tenant_id', true);
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  SELECT * INTO r FROM ph13_audit.audit_partition WHERE tenant_id = 'PLATFORM' AND month = m FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Không có phân vùng % trong audit_partition (ERR-13-125)', part USING ERRCODE = '23514'; END IF;
  IF r.status <> 'SEALED' THEN RAISE EXCEPTION 'Phân vùng % ở trạng thái %, chỉ lưu trữ khi SEALED (ERR-13-125)', part, r.status USING ERRCODE = '23514'; END IF;
  IF r.worm_verified_at IS NULL THEN RAISE EXCEPTION 'Phân vùng % chưa xác minh bản WORM (ERR-13-125)', part USING ERRCODE = '23514'; END IF;
  IF r.archive_after IS NULL OR r.archive_after > current_date THEN
    RAISE EXCEPTION 'Phân vùng % chưa đến hạn lưu trữ (archive_after=%)', part, r.archive_after USING ERRCODE = '23514';
  END IF;
  EXECUTE format('ALTER TABLE ph13_audit.audit_event DETACH PARTITION ph13_audit.%I', part);
  EXECUTE format('DROP TABLE ph13_audit.%I', part);
  UPDATE ph13_audit.audit_partition SET status = 'ARCHIVED', archived_at = now(), updated_by = 'system:ph13_archive' WHERE id = r.id;
  PERFORM set_config('app.tenant_id', coalesce(prev_tenant, ''), true);
END
$p$;
COMMENT ON PROCEDURE ph13_audit.p_archive_partition(date) IS 'Tách và xóa phân vùng tháng đã SEALED, đã xác minh WORM, đã đến hạn; ghi ARCHIVED. Chỉ ph13_archive gọi được (TTL 15 phút, SDD §4.8). Ứng dụng ghi AUDIT.PARTITION.ARCHIVE sau khi gọi.';
REVOKE ALL ON PROCEDURE ph13_audit.p_archive_partition(date) FROM PUBLIC;
REVOKE ALL ON PROCEDURE ph13_audit.p_ensure_month_partitions(date, integer) FROM PUBLIC;
-- @rollback DROP PROCEDURE IF EXISTS ph13_audit.p_archive_partition(date);

-- @file 13-0060-ingest.sql
-- @changeset ph13-0600-audit-quarantine
CREATE TABLE ph13_audit.audit_quarantine (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  du_code          varchar(32)   NOT NULL,
  topic            varchar(249)  NOT NULL,
  kafka_partition  integer,
  kafka_offset     bigint,
  record_id        uuid,
  reason           varchar(20)   NOT NULL,
  error_code       varchar(16)   NOT NULL,
  payload_sha256   char(64)      NOT NULL,
  raw_payload      bytea         NOT NULL,
  status           varchar(11)   NOT NULL DEFAULT 'PENDING',
  resolved_by      varchar(64),
  resolved_at      timestamptz,
  purge_after      timestamptz   NOT NULL DEFAULT now() + interval '90 days',
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_quarantine PRIMARY KEY (id),
  CONSTRAINT ck_audit_quarantine_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_quarantine_reason CHECK (reason IN ('UNPARSABLE', 'SCHEMA_INVALID', 'SOURCE_UNAUTHORIZED', 'TENANT_MISMATCH', 'SENSITIVE_VALUE', 'CHAIN_CLOSED')),
  CONSTRAINT ck_audit_quarantine_error CHECK (error_code ~ '^ERR-13-[0-9]{3}$'),
  CONSTRAINT ck_audit_quarantine_sha CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_audit_quarantine_size CHECK (octet_length(raw_payload) BETWEEN 1 AND 1048576),
  CONSTRAINT ck_audit_quarantine_status CHECK (status IN ('PENDING', 'RESUBMITTED', 'DISMISSED')),
  CONSTRAINT ck_audit_quarantine_resolved CHECK ((status = 'PENDING') = (resolved_at IS NULL AND resolved_by IS NULL)),
  CONSTRAINT ck_audit_quarantine_record CHECK (reason = 'UNPARSABLE' OR record_id IS NOT NULL)
);
CREATE INDEX ix_audit_quarantine_pending ON ph13_audit.audit_quarantine (tenant_id, du_code, created_at DESC) WHERE status = 'PENDING';
CREATE INDEX ix_audit_quarantine_record ON ph13_audit.audit_quarantine (tenant_id, record_id) WHERE record_id IS NOT NULL;
CREATE INDEX ix_audit_quarantine_purge ON ph13_audit.audit_quarantine (purge_after);
CREATE TRIGGER tg_audit_quarantine_touch BEFORE UPDATE ON ph13_audit.audit_quarantine FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_quarantine_imm BEFORE UPDATE ON ph13_audit.audit_quarantine FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'du_code', 'topic', 'reason', 'error_code', 'payload_sha256', 'raw_payload', 'created_at');
CREATE TRIGGER tg_audit_quarantine_ret BEFORE DELETE ON ph13_audit.audit_quarantine FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_guard_retention('purge_after', '0 seconds');
CALL ph13_audit.p_enable_rls('ph13_audit.audit_quarantine', 'P');
COMMENT ON TABLE ph13_audit.audit_quarantine IS 'Kho cách ly bản ghi kiểm toán không đạt kiểm tra tiếp nhận; giữ nguyên văn, không bao giờ bỏ (FR-13-010, SDD §4.3). Có thể chứa giá trị Nhạy cảm (ERR-13-105) nên raw_payload không cấp cho ph13_readonly; xóa khi quá purge_after.';
COMMENT ON COLUMN ph13_audit.audit_quarantine.raw_payload IS 'Nguyên văn bytes; không phân tích được thì lưu thô (UNPARSABLE) vì kênh kiểm toán không có hàng đợi thư chết. Tối đa 1 MB.';
COMMENT ON COLUMN ph13_audit.audit_quarantine.record_id IS 'id (UUID v7) của bản ghi khi đọc được; DU sửa rồi gửi lại cùng id, khử trùng chỉ xét audit_event nên không bị chặn.';
COMMENT ON COLUMN ph13_audit.audit_quarantine.purge_after IS 'Hạn giữ mặc định 90 ngày (giả định, Q13-53); chỉ xóa được sau hạn này.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_quarantine CASCADE;

-- @changeset ph13-0610-audit-source-grant
CREATE TABLE ph13_audit.audit_source_grant (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  du_code          varchar(32)   NOT NULL,
  key_id           varchar(64)   NOT NULL,
  status           varchar(7)    NOT NULL DEFAULT 'ACTIVE',
  granted_by       varchar(64)   NOT NULL,
  revoked_at       timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_audit_source_grant PRIMARY KEY (id),
  CONSTRAINT uq_audit_source_grant UNIQUE (tenant_id, du_code),
  CONSTRAINT ck_audit_source_grant_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_source_grant_du CHECK (du_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_audit_source_grant_status CHECK (status IN ('ACTIVE', 'REVOKED')),
  CONSTRAINT ck_audit_source_grant_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL))
);
CREATE TRIGGER tg_audit_source_grant_touch BEFORE UPDATE ON ph13_audit.audit_source_grant FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_touch();
CREATE TRIGGER tg_audit_source_grant_imm BEFORE UPDATE ON ph13_audit.audit_source_grant FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_immutable('id', 'tenant_id', 'du_code');
CREATE TRIGGER tg_audit_source_grant_nodel BEFORE DELETE ON ph13_audit.audit_source_grant FOR EACH ROW EXECUTE FUNCTION ph13_audit.tg_forbid_delete();
CALL ph13_audit.p_enable_rls('ph13_audit.audit_source_grant', 'P');
COMMENT ON TABLE ph13_audit.audit_source_grant IS 'Cặp (DU, tenant) được phép gửi bản ghi kiểm toán; bộ tiếp nhận kiểm bước 1 (ERR-13-103, UC-SEC-09). Không xóa, thu hồi bằng REVOKED.';
COMMENT ON COLUMN ph13_audit.audit_source_grant.key_id IS 'dh-kid của khóa HMAC nguồn ở OpenBao (chỉ định danh, không chứa khóa).';
-- @rollback DROP TABLE IF EXISTS ph13_audit.audit_source_grant CASCADE;

-- @file 13-0070-misc.sql
-- @changeset ph13-0700-audit-outbox
CREATE TABLE ph13_audit.outbox (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     text          NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_audit_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_audit_outbox_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|PLATFORM)$'),
  CONSTRAINT ck_audit_outbox_type CHECK (event_type ~ '^EVT-13-[0-9]{2}$|^[a-z][a-zA-Z0-9.]{2,127}$'),
  CONSTRAINT ck_audit_outbox_topic CHECK (topic ~ '^[a-z0-9]+\.obs\.[a-z0-9.-]+\.v[0-9]+$'),
  CONSTRAINT ck_audit_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_audit_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_audit_outbox_occurred ON ph13_audit.outbox (occurred_at);
CALL ph13_audit.p_enable_rls('ph13_audit.outbox', 'P');
COMMENT ON TABLE ph13_audit.outbox IS 'Hộp thư đi (DD-11) của module audit cho EVT-13-05…09, 11, 12, ghi cùng giao dịch với đổi trạng thái; Debezium Outbox Router hoặc OutboxRelay đọc. Dọn sau 3 ngày. Bản ghi kiểm toán của DU không đi qua bảng này mà qua audit_outbox ở schema của DU (ADR-042).';
-- @rollback DROP TABLE IF EXISTS ph13_audit.outbox CASCADE;

-- @changeset ph13-0710-audit-shedlock
CREATE TABLE ph13_audit.shedlock (
  name             varchar(64)   NOT NULL,
  lock_until       timestamptz   NOT NULL,
  locked_at        timestamptz   NOT NULL,
  locked_by        varchar(255)  NOT NULL,
  CONSTRAINT pk_audit_shedlock PRIMARY KEY (name)
);
ALTER TABLE ph13_audit.shedlock SET (fillfactor = 70, autovacuum_vacuum_scale_factor = 0.02);
COMMENT ON TABLE ph13_audit.shedlock IS 'Khóa tác vụ nền của module audit (AnchorScheduler, WormBatchWriter, VerificationService, ReconciliationService, PartitionManager); bảng kỹ thuật không có tenant_id.';
-- @rollback DROP TABLE IF EXISTS ph13_audit.shedlock;

-- @file 13-0900-grants.sql
-- @changeset ph13-0990-grants-audit runAlways:true
-- Cấp quyền theo bảng, không dùng ALL TABLES để không lọt quyền vào phân vùng.
GRANT SELECT, INSERT ON ph13_audit.audit_event TO ph13_app;
GRANT SELECT, INSERT ON ph13_audit.audit_anchor TO ph13_app;
GRANT SELECT, INSERT, UPDATE (head_seq, head_hash, last_recorded_at, status, integrity, suspect_from_seq, suspect_since, closed_at, closed_reason, merged_into, updated_at, updated_by, version)
  ON ph13_audit.audit_chain TO ph13_app;
GRANT INSERT (id, tenant_id, genesis_hash, head_seq, head_hash, created_by, updated_by) ON ph13_audit.audit_chain TO ph13_app;
GRANT SELECT, INSERT ON ph13_audit.audit_signing_key TO ph13_app;
GRANT UPDATE (status, retired_at, worm_object, updated_at, updated_by, version) ON ph13_audit.audit_signing_key TO ph13_app;
GRANT SELECT, INSERT, UPDATE (worm_object, worm_written_at, worm_pending, siem_target_code, siem_ack_at, updated_at, updated_by, version)
  ON ph13_audit.audit_anchor_publish TO ph13_app;
GRANT SELECT, INSERT, UPDATE (verified_at, etag, retain_until) ON ph13_audit.audit_worm_batch TO ph13_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph13_audit.audit_verification, ph13_audit.audit_export, ph13_audit.audit_reconciliation,
  ph13_audit.audit_quarantine, ph13_audit.outbox, ph13_audit.shedlock TO ph13_app;
GRANT SELECT, INSERT, UPDATE ON ph13_audit.audit_partition, ph13_audit.audit_source_grant TO ph13_app;
GRANT EXECUTE ON PROCEDURE ph13_audit.p_ensure_month_partitions(date, integer) TO ph13_app;
-- Kiểm tra toàn vẹn và truy vấn nặng đọc bản sao: chỉ SELECT.
GRANT SELECT ON ph13_audit.audit_event, ph13_audit.audit_chain, ph13_audit.audit_anchor, ph13_audit.audit_anchor_publish,
  ph13_audit.audit_signing_key, ph13_audit.audit_worm_batch, ph13_audit.audit_verification, ph13_audit.audit_partition TO ph13_verify;
-- Lưu trữ: chỉ gọi thủ tục DEFINER, không quyền bảng.
GRANT EXECUTE ON PROCEDURE ph13_audit.p_archive_partition(date) TO ph13_archive;
-- Báo cáo đọc: không đọc bản gốc cách ly.
GRANT SELECT ON ph13_audit.audit_chain, ph13_audit.audit_anchor, ph13_audit.audit_verification, ph13_audit.audit_reconciliation,
  ph13_audit.audit_partition, ph13_audit.audit_worm_batch TO ph13_readonly;
GRANT SELECT (id, tenant_id, du_code, topic, record_id, reason, error_code, payload_sha256, status, resolved_by, resolved_at, purge_after, created_at)
  ON ph13_audit.audit_quarantine TO ph13_readonly;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;

-- @file 13-0950-seed.sql
-- @changeset ph13-0950-seed-partitions context:seed
-- Dòng audit_partition cho các phân vùng vừa tạo (phiên PLATFORM). Chuỗi PLATFORM và khóa ký do ObsProvisioner dựng khi cài nền tảng.
SET ROLE ph13_owner;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph13_audit.audit_partition (id, tenant_id, month, partition_name, status, sealed_at, created_by, updated_by)
SELECT md5('audit_partition:' || to_char(c.relname_month, 'YYYYMM'))::uuid, 'PLATFORM', c.relname_month, 'audit_event_' || to_char(c.relname_month, 'YYYYMM'),
       CASE WHEN c.relname_month < date_trunc('month', current_date)::date THEN 'SEALED' ELSE 'OPEN' END,
       CASE WHEN c.relname_month < date_trunc('month', current_date)::date THEN now() END, 'system:seed', 'system:seed'
  FROM (SELECT to_date(substring(c.relname FROM 13 FOR 6), 'YYYYMM') AS relname_month
          FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ph13_audit' AND c.relname ~ '^audit_event_[0-9]{6}$') c
ON CONFLICT (tenant_id, month) DO NOTHING;
RESET ROLE;
-- @rollback DELETE FROM ph13_audit.audit_partition WHERE created_by = 'system:seed';
