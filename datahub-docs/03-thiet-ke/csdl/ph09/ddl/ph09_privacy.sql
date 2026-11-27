-- =============================================================================
-- D03-03-PH09 · DDL schema ph09_privacy — PH-09 Quyền riêng tư (bảo vệ dữ liệu cá nhân)
-- Phiên bản 0.2 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng và Phụ lục A của D02-03-PH09; sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d ph09_test -f ph09_privacy.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH09 phụ lục A. Định danh chủ thể chỉ ở dạng *_enc (envelope, OpenBao
-- transit, ADR-032) và *_hash (HMAC-SHA256 theo khóa tenant); không bảng ánh xạ bí danh (BR-09-030); sự kiện,
-- kiểm toán không mang giá trị DLCN (BR-09-025, 058). Đối tượng nghiệp vụ không xóa cứng: ph09_app bị thu hồi DELETE.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 09-0000-bootstrap.sql
-- @changeset ph09-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_owner') THEN
    CREATE ROLE ph09_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_app') THEN
    CREATE ROLE ph09_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_readonly') THEN
    CREATE ROLE ph09_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_decide') THEN
    CREATE ROLE ph09_decide NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph09-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph09_privacy AUTHORIZATION ph09_owner;
COMMENT ON SCHEMA ph09_privacy IS 'PH-09 Quyền riêng tư (dh-data, package vn.datahub.data.privacy): phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, chính sách che, giả danh hóa và ẩn danh hóa, lưu giữ, quyền chủ thể, đồng ý, DPIA, vi phạm DLCN. Không lưu giá trị DLCN rõ, không bảng ánh xạ bí danh.';
GRANT USAGE ON SCHEMA ph09_privacy TO ph09_app, ph09_readonly, ph09_decide;
-- @rollback DROP SCHEMA IF EXISTS ph09_privacy CASCADE;

SET ROLE ph09_owner;

-- @changeset ph09-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 09-0001-functions.sql
-- @changeset ph09-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_touch();

-- @changeset ph09-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, bằng chứng đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_immutable();

-- @changeset ph09-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký kiểm toán)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (privacy_audit_event). Dọn bằng DETACH, DROP phân vùng dưới ph09_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_append_only();

-- @changeset ph09-0013-fn-frozen splitStatements:false
-- Phiên bản ACTIVE hoặc SUPERSEDED bất biến nội dung (BR-09-011): chặn sửa cột nội dung (đối số).
CREATE OR REPLACE FUNCTION ph09_privacy.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  IF OLD.status IN ('ACTIVE', 'SUPERSEDED', 'SUBMITTED_A05') THEN
    FOREACH c IN ARRAY TG_ARGV LOOP
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Phiên bản % không sửa được cột % (BR-09-011)', OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_frozen() IS 'Hoạt động, chính sách che, lịch lưu giữ, mẫu đồng ý, DPIA, cấu hình ẩn danh đã ACTIVE không đổi nội dung; thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_frozen();

-- @changeset ph09-0014-fn-child-frozen splitStatements:false
-- Bảng con của đối tượng có phiên bản (liên kết, quy tắc che, dòng lịch lưu): chỉ ghi khi cha là DRAFT hoặc REJECTED.
-- Đối số: tên bảng cha, tên cột khóa ngoại tới cha.
CREATE OR REPLACE FUNCTION ph09_privacy.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent text := TG_ARGV[0];
  fkcol text := TG_ARGV[1];
  st text;
  rec jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN rec := to_jsonb(OLD); ELSE rec := to_jsonb(NEW); END IF;
  EXECUTE format('SELECT status FROM ph09_privacy.%I WHERE tenant_id = $1 AND id = $2::uuid', parent)
    INTO st USING rec ->> 'tenant_id', rec ->> fkcol;
  IF st IN ('ACTIVE', 'SUPERSEDED', 'PENDING_APPROVAL', 'RETIRED') THEN
    RAISE EXCEPTION 'Không sửa dòng con của % khi cha là % (BR-09-011)', parent, st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản cha đã gửi duyệt, ACTIVE, SUPERSEDED hoặc RETIRED (BR-09-011).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_child_frozen();

-- @changeset ph09-0015-fn-class-rank splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.class_rank(p_class text) RETURNS smallint
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE p_class WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 WHEN 'SENSITIVE' THEN 4 END::smallint
$f$;
COMMENT ON FUNCTION ph09_privacy.class_rank(text) IS 'Thứ hạng DataClass 1 đến 4 (DD-08) dùng trong CHECK hạ mức (BR-09-002).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.class_rank(text);

-- @changeset ph09-0016-fn-rls splitStatements:false
-- Một mẫu cho mọi bảng nghiệp vụ: chỉ thấy, ghi dòng của tenant phiên; tenant_id đúng dạng Tnn (không có dòng COMMON).
CREATE OR REPLACE PROCEDURE ph09_privacy.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003, BR-09-060).';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_enable_rls(regclass);

-- @changeset ph09-0017-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph09_privacy.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho usage_counter, privacy_audit_event. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph09_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_ensure_partitions(regclass, date, integer);

-- @changeset ph09-0018-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20): danh mục nạp sẵn, tham số 09.*, lịch lưu giữ của PH-09. Chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph09_privacy.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph09_privacy.data_class (id, tenant_id, code, rank, name, log_policy, display_policy, encrypt_at_app, created_by, updated_by)
  SELECT md5('ph09-class:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.r, s.n, s.l, s.d, s.e, 'system:seed', 'system:seed'
  FROM (VALUES ('PUBLIC', 1, 'Công khai', 'FULL', 'FULL', false), ('INTERNAL', 2, 'Nội bộ', 'FULL', 'FULL', false), ('RESTRICTED', 3, 'Hạn chế', 'PARTIAL_MASK', 'MASK_BY_ROLE', false), ('SENSITIVE', 4, 'Nhạy cảm', 'NO_VALUE', 'MASK_DEFAULT', true)) AS s(c, r, n, l, d, e)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.personal_data_category (id, tenant_id, code, name, personal_data_type, legal_ref, default_class, default_mask_pattern, identifiability, builtin, created_by, updated_by)
  SELECT md5('ph09-cat:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.t, s.l, s.k, s.m, s.i, true, 'system:seed', 'system:seed'
  FROM (VALUES ('FULL_NAME', 'Họ và tên', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_FIRST_TOKEN', 'DIRECT'), ('DATE_OF_BIRTH', 'Ngày tháng năm sinh', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'YEAR_ONLY', 'QUASI'), ('GENDER', 'Giới tính', 'BASIC', 'CMP-LAW-05', 'INTERNAL', NULL::varchar, 'QUASI'), ('NATIONAL_ID', 'Số định danh cá nhân', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('PHONE', 'Số điện thoại', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('EMAIL', 'Thư điện tử', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_DOMAIN', 'DIRECT'), ('ADDRESS', 'Địa chỉ', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'ADMIN_LEVEL', 'QUASI'), ('TAX_ID', 'Mã số thuế cá nhân', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('SOCIAL_INSURANCE_ID', 'Số bảo hiểm xã hội', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('HEALTH', 'Tình trạng sức khỏe', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('BIOMETRIC', 'Đặc điểm sinh trắc học', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'DIRECT'), ('GENETIC', 'Dữ liệu di truyền', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('POLITICAL_RELIGIOUS', 'Quan điểm chính trị, tôn giáo', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('CRIMINAL_RECORD', 'Tiền án, tiền sự', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('FINANCIAL_ACCOUNT', 'Tài khoản, thông tin tài chính', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', 'KEEP_LAST_N', 'DIRECT'), ('LOCATION_TRACKING', 'Vị trí, lịch sử di chuyển', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('MINOR', 'Dữ liệu của trẻ em', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('ETHNICITY', 'Nguồn gốc dân tộc, chủng tộc', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR')) AS s(c, n, t, l, k, m, i)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.detector_rule (id, tenant_id, detector_code, name, pattern, has_checksum, builtin, created_by, updated_by)
  SELECT md5('ph09-det:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.p, s.k, true, 'system:seed', 'system:seed'
  FROM (VALUES ('NATIONAL_ID_12', 'Số định danh 12 chữ số', '^[0-9]{12}$', true), ('TAX_ID_10_13', 'Mã số thuế 10 hoặc 13 chữ số', '^[0-9]{10}(-[0-9]{3})?$', true), ('BANK_CARD_LUHN', 'Số thẻ ngân hàng (Luhn)', '^[0-9]{13,19}$', true), ('PHONE_VN', 'Số điện thoại Việt Nam', '^(\+84|0)[0-9]{9}$', false), ('EMAIL', 'Thư điện tử', '^[^@\s]+@[^@\s]+\.[^@\s]+$', false), ('SOCIAL_INSURANCE_10', 'Số bảo hiểm xã hội 10 chữ số', '^[0-9]{10}$', true), ('FIELD_NAME_HINT', 'Gợi ý theo tên trường', '(?i)(cccd|cmnd|dienthoai|phone|email|diachi|hoten|ngaysinh|mst|bhxh|sdt)', false)) AS s(c, n, p, k)
  ON CONFLICT (tenant_id, detector_code) DO NOTHING;
  INSERT INTO ph09_privacy.legal_basis (id, tenant_id, code, basis_type, name, mandatory, rule, created_by, updated_by)
  SELECT md5('ph09-basis:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.c, s.n, s.m, s.r, 'system:seed', 'system:seed'
  FROM (VALUES ('CONSENT', 'Sự đồng ý', false, 'Chỉ cho tiện ích không bắt buộc; không là điều kiện của thủ tục hành chính (BR-09-049).'), ('STATE_TASK', 'Nhiệm vụ của cơ quan nhà nước', false, 'Cơ sở chính của cơ quan nhà nước (BR-09-009).'), ('LEGAL_OBLIGATION', 'Nghĩa vụ pháp lý', true, 'Có điều khoản pháp luật quy định bắt buộc.'), ('CONTRACT', 'Thực hiện hợp đồng', false, 'Cần cho việc thực hiện hợp đồng với chủ thể.'), ('VITAL_INTEREST', 'Bảo vệ lợi ích sống còn', false, 'Bảo vệ tính mạng, sức khỏe của chủ thể hoặc người khác.'), ('EMERGENCY_PUBLIC_INTEREST', 'Tình huống khẩn cấp, lợi ích công cộng', false, 'Theo quyết định của cơ quan có thẩm quyền.'), ('STATISTICS_RESEARCH', 'Thống kê, nghiên cứu', false, 'Dữ liệu đã giả danh hóa hoặc ẩn danh hóa.')) AS s(c, n, m, r)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.mask_type (id, tenant_id, code, mask_type, pattern_kind, name, default_params, reversible, builtin, created_by, updated_by)
  SELECT md5('ph09-mask:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.t, s.p, s.n, s.d::jsonb, s.r, true, 'system:seed', 'system:seed'
  FROM (VALUES ('NONE', 'NONE', NULL::varchar, 'Giữ nguyên', '{}', false), ('PARTIAL.KEEP_FIRST_N', 'PARTIAL', 'KEEP_FIRST_N', 'Giữ n ký tự đầu', '{"n": 3, "char": "*"}', false), ('PARTIAL.KEEP_LAST_N', 'PARTIAL', 'KEEP_LAST_N', 'Giữ n ký tự cuối', '{"n": 4, "char": "*"}', false), ('PARTIAL.KEEP_FIRST_LAST', 'PARTIAL', 'KEEP_FIRST_LAST', 'Giữ n ký tự đầu và m ký tự cuối', '{"n": 2, "m": 2, "char": "*"}', false), ('PARTIAL.KEEP_FIRST_TOKEN', 'PARTIAL', 'KEEP_FIRST_TOKEN', 'Giữ từ đầu của họ tên', '{"char": "*"}', false), ('PARTIAL.KEEP_DOMAIN', 'PARTIAL', 'KEEP_DOMAIN', 'Giữ tên miền thư điện tử', '{"char": "*"}', false), ('REPLACE', 'REPLACE', NULL::varchar, 'Thay bằng chuỗi cố định', '{"value": "[REDACTED]"}', false), ('KEYED_HASH', 'KEYED_HASH', NULL::varchar, 'Băm có khóa HMAC-SHA256', '{}', false), ('TOKENIZE', 'TOKENIZE', NULL::varchar, 'Token hóa đảo ngược qua transit', '{}', true), ('GENERALIZE.YEAR_ONLY', 'GENERALIZE', 'YEAR_ONLY', 'Chỉ giữ năm', '{}', false), ('GENERALIZE.ADMIN_LEVEL', 'GENERALIZE', 'ADMIN_LEVEL', 'Tổng quát hóa đến cấp hành chính', '{"level": "PROVINCE"}', false), ('DROP', 'DROP', NULL::varchar, 'Bỏ trường', '{}', false)) AS s(c, t, p, n, d, r)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.tenant_setting (id, tenant_id, setting_key, value, floor_value, ceiling_value, created_by, updated_by)
  SELECT md5('ph09-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, s.lo::jsonb, s.hi::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('09.scan.sample-rows', '10000', '1000', '100000'), ('09.scan.schedule-cron', '"0 2 * * 0"', NULL::text, NULL::text), ('09.scan.confidence', '0.8', '0.5', '0.99'), ('09.request.sla-days', '10', '3', '30'), ('09.grant.max-days', '365', '30', '730'), ('09.grant.renew-max', '3', '0', '10'), ('09.grant.expiring-notice-days', '30', '7', '90'), ('09.grant.require-restricted', 'false', NULL::text, NULL::text), ('09.bundle.debounce-seconds', '10', '1', '60'), ('09.bundle.valid-minutes', '60', '15', '240'), ('09.plan.cache-seconds', '300', '60', '300'), ('09.consent.cache-seconds', '60', '0', '60'), ('09.decision.cache-seconds', '15', '0', '15'), ('09.feature.dsr-ph11', 'false', NULL::text, NULL::text), ('09.feature.l-diversity', 'false', NULL::text, NULL::text), ('09.feature.auto-confirm-mvp', 'false', NULL::text, NULL::text), ('09.api.rate-user-per-min', '300', '60', '1200'), ('09.api.rate-du-per-sec', '2000', '500', '5000'), ('09.anomaly.quota-warn-percent', '80', '50', '95'), ('09.anomaly.bulk-threshold', '1000', '100', '100000'), ('09.anomaly.auto-suspend', 'false', NULL::text, NULL::text), ('09.mask.reveal-seconds', '60', '30', '60'), ('09.mask.reveal-max-per-hour', '20', '1', '50'), ('09.mask.reveal-alert-per-hour', '10', '1', '50'), ('09.log.scan-cron', '"0 3 * * *"', NULL::text, NULL::text), ('09.pseudo.key-rotate-days', '365', '90', '730'), ('09.pseudo.min-rotate-days', '30', '7', '90'), ('09.pseudo.destroy-delay-days', '30', '7', '90'), ('09.reid.approval-ttl-hours', '24', '1', '72'), ('09.reid.exec-window-minutes', '30', '5', '120'), ('09.anon.k-min', '10', '10', '100'), ('09.anon.risk-medium-above', '0.05', '0.01', '0.1'), ('09.anon.risk-high-above', '0.1', '0.05', '0.2'), ('09.ai.allow-restricted', 'false', NULL::text, NULL::text), ('09.retention.run-cron', '"0 1 * * *"', NULL::text, NULL::text), ('09.retention.overdue-days', '7', '1', '30'), ('09.shred.delay-days', '30', '7', '90'), ('09.dsr.sla-days', '10', '5', '30'), ('09.dsr.remind-days', '3', '1', '7'), ('09.breach.alert-hours', '[24, 48, 60]', NULL::text, NULL::text), ('09.dpia.review-months', '12', '3', '12'), ('09.audit.query-max-days', '90', '7', '366'), ('09.report.schedule-cron', '"0 6 1 * *"', NULL::text, NULL::text)) AS s(k, v, lo, hi)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph09_privacy.log_mask_config (id, tenant_id, patterns, created_by, updated_by)
  VALUES (md5('ph09-logmask:' || p_tenant)::uuid, p_tenant, ARRAY['NATIONAL_ID_12', 'PHONE_VN', 'BANK_CARD_LUHN', 'EMAIL'], 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id) DO NOTHING;
  -- Lịch lưu giữ của chính PH-09: tạo DRAFT, thêm dòng, rồi kích hoạt (người duyệt khác người soạn).
  INSERT INTO ph09_privacy.retention_schedule (id, tenant_id, schedule_code, version_no, status, description, created_by, updated_by)
  VALUES (md5('ph09-ret:' || p_tenant)::uuid, p_tenant, 'PH09-OWN', 1, 'DRAFT', 'Lịch lưu giữ của chính PH-09 (chương 7 D03-03-PH09)', 'system:seed', 'system:seed')
  ON CONFLICT DO NOTHING;
  INSERT INTO ph09_privacy.retention_schedule_line (id, tenant_id, schedule_id, entity, category, retain_days, action, owner, created_by, updated_by)
  SELECT md5('ph09-retline:' || p_tenant || ':' || s.e)::uuid, p_tenant, md5('ph09-ret:' || p_tenant)::uuid, s.e, s.c, s.d, s.a, s.o, 'system:seed', 'system:seed'
  FROM (VALUES ('subject_request', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('subject_verification', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('subject_task', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('consent_record', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('breach_case', NULL::varchar, 3650, 'ARCHIVE', 'SO'), ('breach_notification', NULL::varchar, 3650, 'ARCHIVE', 'SO'), ('reveal_grant', NULL::varchar, 365, 'DELETE', 'TA'), ('usage_counter', NULL::varchar, 400, 'DELETE', 'TA'), ('usage_anomaly', NULL::varchar, 730, 'ARCHIVE', 'SO'), ('scan_run', NULL::varchar, 365, 'DELETE', 'TA'), ('scan_finding', NULL::varchar, 365, 'DELETE', 'TA'), ('leak_finding', NULL::varchar, 365, 'DELETE', 'TA'), ('mask_simulation', NULL::varchar, 180, 'DELETE', 'TA'), ('privacy_audit_event', NULL::varchar, 395, 'ARCHIVE', 'SO'), ('policy_bundle', NULL::varchar, 90, 'DELETE', 'TA'), ('outbox_event', NULL::varchar, 3, 'DELETE', 'TA'), ('inbox_event', NULL::varchar, 7, 'DELETE', 'TA')) AS s(e, c, d, a, o)
  WHERE EXISTS (SELECT 1 FROM ph09_privacy.retention_schedule WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT')
  ON CONFLICT DO NOTHING;
  UPDATE ph09_privacy.retention_schedule SET status = 'ACTIVE', decided_by = 'system:policy', decided_at = now(), activated_at = now(), submitted_by = 'system:seed'
  WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT';
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant: 4 mức, 18 loại DLCN, 7 mẫu phát hiện, 7 cơ sở pháp lý, 12 kiểu che, 36 tham số 09.*, cấu hình log, lịch lưu giữ PH09-OWN.';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_seed_tenant(text);


-- @file 09-0010-classification.sql
-- @changeset ph09-0100-data-class
CREATE TABLE ph09_privacy.data_class (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  code           varchar(16) NOT NULL,
  rank           smallint NOT NULL,
  name           varchar(100) NOT NULL,
  log_policy     varchar(16) NOT NULL,
  display_policy varchar(16) NOT NULL,
  encrypt_at_app boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_class PRIMARY KEY (id),
  CONSTRAINT uq_data_class_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_data_class_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_data_class_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_data_class_rank UNIQUE (tenant_id, rank),
  CONSTRAINT ck_data_class_code CHECK (code IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_data_class_rank CHECK (rank = CASE code WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 ELSE 4 END),
  CONSTRAINT ck_data_class_log CHECK (log_policy IN ('FULL', 'PARTIAL_MASK', 'NO_VALUE')),
  CONSTRAINT ck_data_class_display CHECK (display_policy IN ('FULL', 'MASK_BY_ROLE', 'MASK_DEFAULT')),
  CONSTRAINT ck_data_class_sensitive CHECK (code <> 'SENSITIVE' OR (log_policy = 'NO_VALUE' AND display_policy = 'MASK_DEFAULT' AND encrypt_at_app))
);
CREATE TRIGGER tg_data_class_touch BEFORE UPDATE ON ph09_privacy.data_class FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_data_class_immutable BEFORE UPDATE ON ph09_privacy.data_class FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'rank');
CALL ph09_privacy.p_enable_rls('ph09_privacy.data_class');
COMMENT ON TABLE ph09_privacy.data_class IS 'EN-09-01 Mức phân loại DD-08 (FR-09-001): PUBLIC, INTERNAL, RESTRICTED, SENSITIVE, thứ hạng 1 đến 4 theo bảng D03-07 3.2. SENSITIVE luôn NO_VALUE ở log, MASK_DEFAULT ở hiển thị, mã hóa ở ứng dụng (ERR-09-003). Mỗi tenant có bản nạp sẵn bốn dòng; không xóa.';
COMMENT ON COLUMN ph09_privacy.data_class.log_policy IS 'Cách ghi giá trị vào log vận hành (D03-07 3.2).';
COMMENT ON COLUMN ph09_privacy.data_class.encrypt_at_app IS 'Mã hóa envelope ở tầng ứng dụng (ADR-032).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.data_class CASCADE;

-- @changeset ph09-0110-block-label
CREATE TABLE ph09_privacy.block_label (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  label                varchar(16) NOT NULL DEFAULT 'STATE_SECRET',
  target_kind          varchar(16) NOT NULL,
  target_id            varchar(128) NOT NULL,
  legal_doc            varchar(255) NOT NULL,
  assigned_by          varchar(64) NOT NULL,
  release_requested_by varchar(64),
  release_requested_at timestamptz,
  release_doc          varchar(255),
  released_by          varchar(64),
  released_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_block_label PRIMARY KEY (id),
  CONSTRAINT ck_block_label_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_block_label_label CHECK (label IN ('STATE_SECRET')),
  CONSTRAINT ck_block_label_target CHECK (target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_block_label_release_req CHECK ((release_requested_by IS NULL) = (release_requested_at IS NULL) AND (release_requested_by IS NULL OR release_doc IS NOT NULL)),
  CONSTRAINT ck_block_label_released CHECK ((released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by)))
);
CREATE UNIQUE INDEX uq_block_label_active ON ph09_privacy.block_label (tenant_id, target_kind, target_id) WHERE released_at IS NULL;
CREATE TRIGGER tg_block_label_touch BEFORE UPDATE ON ph09_privacy.block_label FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_block_label_immutable BEFORE UPDATE ON ph09_privacy.block_label FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('target_kind', 'target_id', 'legal_doc', 'assigned_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.block_label');
COMMENT ON TABLE ph09_privacy.block_label IS 'EN-09-02 Nhãn chặn STATE_SECRET gắn vào phần tử hoặc hợp đồng (FR-09-007, BR-09-005). Gỡ nhãn cần văn bản giải mật và hai người khác nhau (ERR-09-019); không xóa dòng, gỡ ghi released_*. Mọi thao tác ghi kiểm toán, bị từ chối nếu không ghi được (BR-09-057).';
COMMENT ON COLUMN ph09_privacy.block_label.released_by IS 'Người duyệt gỡ, khác người đề nghị gỡ (BR-09-005).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.block_label CASCADE;

-- @changeset ph09-0120-personal-data-category
CREATE TABLE ph09_privacy.personal_data_category (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  code                 varchar(32) NOT NULL,
  name                 varchar(255) NOT NULL,
  personal_data_type   varchar(16) NOT NULL,
  legal_ref            varchar(16),
  default_class        varchar(16) NOT NULL,
  default_mask_pattern varchar(24),
  identifiability      varchar(16) NOT NULL DEFAULT 'NONE',
  builtin              boolean NOT NULL DEFAULT false,
  retired_at           timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_personal_data_category PRIMARY KEY (id),
  CONSTRAINT uq_personal_data_category_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_personal_data_category_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_personal_data_category_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_personal_data_category_code CHECK (code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_personal_data_category_type CHECK (personal_data_type IN ('BASIC', 'SENSITIVE')),
  CONSTRAINT ck_personal_data_category_legal CHECK (legal_ref IS NULL OR legal_ref ~ '^CMP-LAW-[0-9]{2}$'),
  CONSTRAINT ck_personal_data_category_class CHECK (default_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_personal_data_category_pattern CHECK (default_mask_pattern IS NULL OR default_mask_pattern IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_personal_data_category_ident CHECK (identifiability IN ('DIRECT', 'QUASI', 'SENSITIVE_ATTR', 'NONE')),
  CONSTRAINT ck_personal_data_category_sensitive CHECK (personal_data_type <> 'SENSITIVE' OR default_class = 'SENSITIVE')
);
CREATE TRIGGER tg_personal_data_category_touch BEFORE UPDATE ON ph09_privacy.personal_data_category FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_personal_data_category_immutable BEFORE UPDATE ON ph09_privacy.personal_data_category FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'builtin');
CALL ph09_privacy.p_enable_rls('ph09_privacy.personal_data_category');
COMMENT ON TABLE ph09_privacy.personal_data_category IS 'EN-09-03 Loại dữ liệu cá nhân (FR-09-002): 9 loại cơ bản và 9 loại nhạy cảm của Luật 91/2025, NĐ 356/2025, nạp sẵn; tenant thêm loại mới. Loại SENSITIVE mặc định mức SENSITIVE; hạ loại cần bốn mắt (BR-09-002). Ngừng bằng retired_at.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.personal_data_category CASCADE;

-- @changeset ph09-0130-data-element
CREATE TABLE ph09_privacy.data_element (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  scope          varchar(16) NOT NULL,
  target         varchar(512) NOT NULL,
  owner_org_id   varchar(63) NOT NULL,
  contract_ref   varchar(255),
  declared_class varchar(16),
  source         varchar(16) NOT NULL,
  element_status varchar(12) NOT NULL DEFAULT 'ACTIVE',
  retired_at     timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_element PRIMARY KEY (id),
  CONSTRAINT uq_data_element_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_data_element_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_data_element_target UNIQUE (tenant_id, scope, target),
  CONSTRAINT ck_data_element_scope CHECK (scope IN ('INTERNAL_ENTITY', 'API_SCHEMA', 'EVENT_SCHEMA')),
  CONSTRAINT ck_data_element_declared CHECK (declared_class IS NULL OR declared_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_data_element_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_data_element_status CHECK (element_status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_data_element_retired CHECK ((element_status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE INDEX ix_data_element_owner ON ph09_privacy.data_element (tenant_id, owner_org_id, element_status);
CREATE INDEX ix_data_element_contract ON ph09_privacy.data_element (tenant_id, contract_ref) WHERE contract_ref IS NOT NULL;
CREATE INDEX ix_data_element_target_trgm ON ph09_privacy.data_element USING gin (lower(target) gin_trgm_ops);
CREATE TRIGGER tg_data_element_touch BEFORE UPDATE ON ph09_privacy.data_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_data_element_immutable BEFORE UPDATE ON ph09_privacy.data_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('scope', 'target');
CALL ph09_privacy.p_enable_rls('ph09_privacy.data_element');
COMMENT ON TABLE ph09_privacy.data_element IS 'EN-09-04 Phần tử dữ liệu (trường) đăng ký từ phân hệ, lược đồ API, topic, khai báo MVP (FR-09-003, BR-09-007). target là tên đầy đủ (ph06_mdm.CITIZEN.nationalId) hoặc JSON Pointer. Không xóa; ngừng bằng element_status RETIRED. Phân loại hiện hành ở element_classification.';
COMMENT ON COLUMN ph09_privacy.data_element.owner_org_id IS 'Mã tổ chức ở PH-01 (không khóa ngoại, khác schema); chỉ TA, SO, DO của tổ chức này xác nhận (BR-09-003).';
COMMENT ON COLUMN ph09_privacy.data_element.declared_class IS 'Mức khai báo trong mã (@Classified, x-dh-classification) khi nhập MVP (FR-09-003).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.data_element CASCADE;

-- @changeset ph09-0140-element-classification
CREATE TABLE ph09_privacy.element_classification (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  element_id         uuid NOT NULL,
  data_class         varchar(16) NOT NULL,
  personal_data_type varchar(16) NOT NULL DEFAULT 'NONE',
  category_code      varchar(32),
  identifiability    varchar(16) NOT NULL DEFAULT 'NONE',
  mask_pattern       varchar(24),
  never_reveal       boolean NOT NULL DEFAULT false,
  no_egress          boolean NOT NULL DEFAULT false,
  basis              varchar(255),
  status             varchar(12) NOT NULL DEFAULT 'PROPOSED',
  source             varchar(16) NOT NULL,
  confirmed_by       varchar(64),
  confirmed_at       timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_element_classification PRIMARY KEY (id),
  CONSTRAINT uq_element_classification_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_element_classification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_element_classification_element UNIQUE (tenant_id, element_id),
  CONSTRAINT fk_element_classification_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT fk_element_classification_category FOREIGN KEY (tenant_id, category_code) REFERENCES ph09_privacy.personal_data_category (tenant_id, code),
  CONSTRAINT ck_element_classification_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_element_classification_type CHECK (personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE')),
  CONSTRAINT ck_element_classification_ident CHECK (identifiability IN ('DIRECT', 'QUASI', 'SENSITIVE_ATTR', 'NONE')),
  CONSTRAINT ck_element_classification_pattern CHECK (mask_pattern IS NULL OR mask_pattern IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_element_classification_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'REJECTED', 'SUPERSEDED')),
  CONSTRAINT ck_element_classification_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_element_classification_category CHECK ((personal_data_type = 'NONE') = (category_code IS NULL)),
  CONSTRAINT ck_element_classification_sensitive CHECK (personal_data_type <> 'SENSITIVE' OR data_class = 'SENSITIVE'),
  CONSTRAINT ck_element_classification_direct CHECK (identifiability NOT IN ('DIRECT', 'SENSITIVE_ATTR') OR personal_data_type <> 'NONE'),
  CONSTRAINT ck_element_classification_confirmed CHECK (status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL))
);
CREATE INDEX ix_element_classification_class ON ph09_privacy.element_classification (tenant_id, data_class, status);
CREATE INDEX ix_element_classification_category ON ph09_privacy.element_classification (tenant_id, category_code) WHERE category_code IS NOT NULL;
CREATE TRIGGER tg_element_classification_touch BEFORE UPDATE ON ph09_privacy.element_classification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_element_classification_immutable BEFORE UPDATE ON ph09_privacy.element_classification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('element_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.element_classification');
COMMENT ON TABLE ph09_privacy.element_classification IS 'EN-09-05 Phân loại hiện hành của phần tử, một dòng mỗi phần tử (DD-09, FR-09-004). Chưa CONFIRMED thì xử lý như SENSITIVE (BR-09-001). Loại DLCN khác NONE phải có categoryCode; SENSITIVE kéo theo mức SENSITIVE. Đổi qua classification_change.';
COMMENT ON COLUMN ph09_privacy.element_classification.never_reveal IS 'Trường không có đường xem đầy đủ (BR-09-026).';
COMMENT ON COLUMN ph09_privacy.element_classification.no_egress IS 'Trường không được gửi ra ngoài tỉnh (BR-09-063, chủ đầu tư chốt 27/11/2026); bản chưa CONFIRMED xử lý như bật.';
COMMENT ON COLUMN ph09_privacy.element_classification.mask_pattern IS 'Mẫu che mặc định của trường (MaskPatternKind).';
COMMENT ON COLUMN ph09_privacy.element_classification.basis IS 'Số văn bản căn cứ của phân loại.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.element_classification CASCADE;

-- @changeset ph09-0150-classification-change
CREATE TABLE ph09_privacy.classification_change (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  element_id              uuid NOT NULL,
  from_class              varchar(16),
  to_class                varchar(16) NOT NULL,
  from_personal_data_type varchar(16),
  to_personal_data_type   varchar(16) NOT NULL,
  proposed                jsonb NOT NULL,
  status                  varchar(12) NOT NULL DEFAULT 'PROPOSED',
  basis                   varchar(255),
  reason                  varchar(2000) NOT NULL,
  proposed_by             varchar(64) NOT NULL,
  confirmed_by            varchar(64),
  confirmed_at            timestamptz,
  confirmed_by_2          varchar(64),
  confirmed_at_2          timestamptz,
  reject_comment          varchar(2000),
  source                  varchar(16) NOT NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_classification_change PRIMARY KEY (id),
  CONSTRAINT uq_classification_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_classification_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_classification_change_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT ck_classification_change_class CHECK (to_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE') AND (from_class IS NULL OR from_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE'))),
  CONSTRAINT ck_classification_change_type CHECK (to_personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE') AND (from_personal_data_type IS NULL OR from_personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE'))),
  CONSTRAINT ck_classification_change_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'REJECTED', 'SUPERSEDED')),
  CONSTRAINT ck_classification_change_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_classification_change_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_classification_change_four_eyes CHECK (confirmed_by IS NULL OR confirmed_by <> proposed_by),
  CONSTRAINT ck_classification_change_confirmed CHECK (status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)),
  CONSTRAINT ck_classification_change_downgrade CHECK (status <> 'CONFIRMED' OR from_class IS NULL OR ph09_privacy.class_rank(to_class) >= ph09_privacy.class_rank(from_class) OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_at_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)),
  CONSTRAINT ck_classification_change_type_down CHECK (status <> 'CONFIRMED' OR from_personal_data_type IS DISTINCT FROM 'SENSITIVE' OR to_personal_data_type = 'SENSITIVE' OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)),
  CONSTRAINT ck_classification_change_rejected CHECK (status <> 'REJECTED' OR COALESCE(char_length(reject_comment) >= 20, false))
);
CREATE INDEX ix_classification_change_element ON ph09_privacy.classification_change (tenant_id, element_id, created_at DESC);
CREATE INDEX ix_classification_change_open ON ph09_privacy.classification_change (tenant_id, status, created_at) WHERE status = 'PROPOSED';
CREATE TRIGGER tg_classification_change_touch BEFORE UPDATE ON ph09_privacy.classification_change FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_classification_change_immutable BEFORE UPDATE ON ph09_privacy.classification_change FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('element_id', 'from_class', 'to_class', 'proposed', 'proposed_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.classification_change');
COMMENT ON TABLE ph09_privacy.classification_change IS 'EN-09-06 Đề xuất, thay đổi phân loại (FR-09-004, 005, BR-09-002, 003, 007). Người xác nhận khác người đề xuất. Hạ mức hoặc hạ loại DLCN từ SENSITIVE cần số văn bản căn cứ và người xác nhận thứ hai khác hai người kia. Lịch sử tuyến tính, không sửa sau khi chốt.';
COMMENT ON COLUMN ph09_privacy.classification_change.proposed IS 'Trạng thái phân loại đề xuất (dataClass, personalDataType, categoryCode, identifiability, maskPattern, neverReveal, noEgress).';
COMMENT ON COLUMN ph09_privacy.classification_change.confirmed_by_2 IS 'Người xác nhận thứ hai khi hạ mức (BR-09-002).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.classification_change CASCADE;

-- @changeset ph09-0160-detector-rule
CREATE TABLE ph09_privacy.detector_rule (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  detector_code        varchar(24) NOT NULL,
  name                 varchar(255) NOT NULL,
  pattern              varchar(500) NOT NULL,
  has_checksum         boolean NOT NULL DEFAULT false,
  confidence_threshold numeric(3,2) NOT NULL DEFAULT 0.80,
  enabled              boolean NOT NULL DEFAULT true,
  builtin              boolean NOT NULL DEFAULT false,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_detector_rule PRIMARY KEY (id),
  CONSTRAINT ck_detector_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_detector_rule_code UNIQUE (tenant_id, detector_code),
  CONSTRAINT ck_detector_rule_code CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_detector_rule_threshold CHECK (confidence_threshold BETWEEN 0.50 AND 0.99)
);
CREATE TRIGGER tg_detector_rule_touch BEFORE UPDATE ON ph09_privacy.detector_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_detector_rule_immutable BEFORE UPDATE ON ph09_privacy.detector_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('detector_code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.detector_rule');
COMMENT ON TABLE ph09_privacy.detector_rule IS 'EN-09-07 Mẫu phát hiện DLCN (FR-09-005, ADR đề xuất 093): số định danh 12 chữ số, mã số thuế, thẻ (Luhn), điện thoại, thư điện tử, mã BHXH, gợi ý theo tên trường. Bộ mẫu và kiểm tổng, không dùng học máy ở đợt 2.';
COMMENT ON COLUMN ph09_privacy.detector_rule.pattern IS 'Biểu thức chính quy hoặc danh sách gợi ý tên trường; kiểm tổng (Luhn, mod 11) ở mã.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.detector_rule CASCADE;

-- @changeset ph09-0170-scan-run
CREATE TABLE ph09_privacy.scan_run (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  scope         jsonb NOT NULL,
  sample_rows   integer NOT NULL DEFAULT 10000,
  detectors     varchar(24)[] NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_by  varchar(64) NOT NULL,
  started_at    timestamptz,
  finished_at   timestamptz,
  suspect_count integer NOT NULL DEFAULT 0,
  error_code    varchar(10),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_scan_run PRIMARY KEY (id),
  CONSTRAINT uq_scan_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_scan_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_scan_run_rows CHECK (sample_rows BETWEEN 1000 AND 100000),
  CONSTRAINT ck_scan_run_detectors CHECK (cardinality(detectors) >= 1 AND detectors <@ ARRAY['NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT']::varchar[]),
  CONSTRAINT ck_scan_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_scan_run_finished CHECK (status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_scan_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$'),
  CONSTRAINT ck_scan_run_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_scan_run_suspect CHECK (suspect_count >= 0)
);
CREATE INDEX ix_scan_run_list ON ph09_privacy.scan_run (tenant_id, created_at DESC);
CREATE TRIGGER tg_scan_run_touch BEFORE UPDATE ON ph09_privacy.scan_run FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.scan_run');
COMMENT ON TABLE ph09_privacy.scan_run IS 'EN-09-08 Lượt quét phát hiện trường nghi DLCN (FR-09-005, NFR-09-009): phạm vi, số dòng mẫu, mẫu phát hiện, trạng thái ScanStatus. Chỉ đọc mẫu, không lưu giá trị mẫu (BR-09-025). Giữ 365 ngày.';
COMMENT ON COLUMN ph09_privacy.scan_run.scope IS 'Hệ thống, hợp đồng cần quét (FR-09-005).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.scan_run CASCADE;

-- @changeset ph09-0180-scan-finding
CREATE TABLE ph09_privacy.scan_finding (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  scan_id         uuid NOT NULL,
  element_id      uuid,
  target          varchar(512) NOT NULL,
  detector_code   varchar(24) NOT NULL,
  confidence      numeric(4,3) NOT NULL,
  hit_count       integer NOT NULL,
  status          varchar(16) NOT NULL DEFAULT 'OPEN',
  resolved_by     varchar(64),
  resolved_at     timestamptz,
  resolution_note varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_scan_finding PRIMARY KEY (id),
  CONSTRAINT ck_scan_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_scan_finding_scan FOREIGN KEY (tenant_id, scan_id) REFERENCES ph09_privacy.scan_run (tenant_id, id),
  CONSTRAINT fk_scan_finding_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT uq_scan_finding_target UNIQUE (tenant_id, scan_id, target, detector_code),
  CONSTRAINT ck_scan_finding_detector CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_scan_finding_confidence CHECK (confidence BETWEEN 0 AND 1 AND hit_count >= 0),
  CONSTRAINT ck_scan_finding_status CHECK (status IN ('OPEN', 'CONFIRMED_PII', 'EXCLUDED', 'CLASSIFIED')),
  CONSTRAINT ck_scan_finding_resolved CHECK (status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE INDEX ix_scan_finding_open ON ph09_privacy.scan_finding (tenant_id, status, confidence DESC) WHERE status = 'OPEN';
CREATE TRIGGER tg_scan_finding_touch BEFORE UPDATE ON ph09_privacy.scan_finding FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.scan_finding');
COMMENT ON TABLE ph09_privacy.scan_finding IS 'EN-09-09 Kết quả phát hiện một cột hoặc trường (FR-09-005, BR-09-006): mẫu khớp, độ tin cậy, trạng thái FindingStatus. Chỉ là gợi ý, không tự đổi phân loại. Chỉ lưu số lượt khớp, không lưu giá trị.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.scan_finding CASCADE;

-- @changeset ph09-0190-contract-level
CREATE TABLE ph09_privacy.contract_level (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  contract_kind varchar(8) NOT NULL,
  contract_id   varchar(128) NOT NULL,
  data_class    varchar(16) NOT NULL,
  provisional   boolean NOT NULL DEFAULT false,
  blocked       boolean NOT NULL DEFAULT false,
  element_count integer NOT NULL DEFAULT 0,
  computed_at   timestamptz NOT NULL DEFAULT now(),
  basis         jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_contract_level PRIMARY KEY (id),
  CONSTRAINT ck_contract_level_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_contract_level_contract UNIQUE (tenant_id, contract_kind, contract_id),
  CONSTRAINT ck_contract_level_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_contract_level_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_contract_level_count CHECK (element_count >= 0),
  CONSTRAINT ck_contract_level_provisional CHECK (NOT provisional OR data_class = 'SENSITIVE')
);
CREATE INDEX ix_contract_level_class ON ph09_privacy.contract_level (tenant_id, data_class);
CREATE TRIGGER tg_contract_level_touch BEFORE UPDATE ON ph09_privacy.contract_level FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.contract_level');
COMMENT ON TABLE ph09_privacy.contract_level IS 'EN-09-10 Mức phân loại tính được của hợp đồng API, topic, luồng (FR-09-006, BR-09-001, 004): mức cao nhất của các trường; provisional khi còn phần tử chưa CONFIRMED (tạm SENSITIVE); blocked khi có nhãn STATE_SECRET. Tính lại khi phân loại đổi (NFR-09-010).';
COMMENT ON COLUMN ph09_privacy.contract_level.basis IS 'Phần tử quyết định mức (mã phần tử, không giá trị).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.contract_level CASCADE;


-- @file 09-0020-ropa.sql
-- @changeset ph09-0200-legal-document
CREATE TABLE ph09_privacy.legal_document (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  doc_type       varchar(32) NOT NULL,
  number         varchar(64) NOT NULL,
  title          varchar(500) NOT NULL,
  issued_on      date NOT NULL,
  effective_from date NOT NULL,
  effective_to   date,
  cmp_law_code   varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_document PRIMARY KEY (id),
  CONSTRAINT uq_legal_document_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_document_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legal_document_number UNIQUE (tenant_id, doc_type, number),
  CONSTRAINT ck_legal_document_type CHECK (doc_type ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_legal_document_period CHECK (effective_from >= issued_on AND (effective_to IS NULL OR effective_to > effective_from)),
  CONSTRAINT ck_legal_document_law CHECK (cmp_law_code IS NULL OR cmp_law_code ~ '^CMP-LAW-[0-9]{2}$')
);
CREATE TRIGGER tg_legal_document_touch BEFORE UPDATE ON ph09_privacy.legal_document FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_document_immutable BEFORE UPDATE ON ph09_privacy.legal_document FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('doc_type', 'number');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_document');
COMMENT ON TABLE ph09_privacy.legal_document IS 'EN-09-14 Văn bản căn cứ (FR-09-012): loại, số, ngày ban hành, hiệu lực, liên kết CMP-LAW. Văn bản hết hiệu lực không dùng cho hoạt động mới (kiểm ở dịch vụ).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.legal_document CASCADE;

-- @changeset ph09-0210-legal-basis
CREATE TABLE ph09_privacy.legal_basis (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  code       varchar(32) NOT NULL,
  basis_type varchar(32) NOT NULL,
  name       varchar(255) NOT NULL,
  mandatory  boolean NOT NULL DEFAULT false,
  rule       varchar(2000),
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_basis PRIMARY KEY (id),
  CONSTRAINT uq_legal_basis_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_basis_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legal_basis_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_legal_basis_code CHECK (code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_legal_basis_type CHECK (basis_type IN ('CONSENT', 'STATE_TASK', 'LEGAL_OBLIGATION', 'CONTRACT', 'VITAL_INTEREST', 'EMERGENCY_PUBLIC_INTEREST', 'STATISTICS_RESEARCH'))
);
CREATE TRIGGER tg_legal_basis_touch BEFORE UPDATE ON ph09_privacy.legal_basis FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_basis_immutable BEFORE UPDATE ON ph09_privacy.legal_basis FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'basis_type');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_basis');
COMMENT ON TABLE ph09_privacy.legal_basis IS 'EN-09-13 Cơ sở pháp lý (FR-09-012, BR-09-009): bảy LegalBasisType nạp sẵn kèm quy tắc áp dụng. CONSENT chỉ cho tiện ích không bắt buộc; cơ quan nhà nước dùng STATE_TASK hoặc LEGAL_OBLIGATION.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.legal_basis CASCADE;

-- @changeset ph09-0220-processing-activity
CREATE TABLE ph09_privacy.processing_activity (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  code             varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  purpose_text     varchar(1000) NOT NULL,
  legal_basis_code varchar(32) NOT NULL,
  legal_doc_ids    uuid[] NOT NULL DEFAULT '{}',
  categories       varchar(32)[] NOT NULL,
  subject_groups   varchar(255)[] NOT NULL,
  recipients       varchar(255)[] NOT NULL DEFAULT '{}',
  retention        jsonb NOT NULL,
  controller_role  varchar(20) NOT NULL,
  measures         varchar(500)[] NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_processing_activity PRIMARY KEY (id),
  CONSTRAINT uq_processing_activity_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_processing_activity_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_processing_activity_code CHECK (code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_processing_activity_basis FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES ph09_privacy.legal_basis (tenant_id, code),
  CONSTRAINT ck_processing_activity_purpose CHECK (char_length(purpose_text) >= 20),
  CONSTRAINT ck_processing_activity_role CHECK (controller_role IN ('CONTROLLER', 'PROCESSOR', 'JOINT_CONTROLLER')),
  CONSTRAINT ck_processing_activity_retention CHECK (jsonb_typeof(retention) = 'object' AND retention->>'action' IN ('DELETE', 'PSEUDONYMIZE', 'ANONYMIZE', 'ARCHIVE') AND (retention ? 'months' OR retention ? 'endCondition')),
  CONSTRAINT ck_processing_activity_lists CHECK (cardinality(categories) >= 1 AND cardinality(subject_groups) >= 1 AND cardinality(measures) >= 1),
  CONSTRAINT uq_processing_activity_version UNIQUE (tenant_id, code, version_no),
  CONSTRAINT ck_processing_activity_version CHECK (version_no >= 1),
  CONSTRAINT ck_processing_activity_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_processing_activity_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_processing_activity_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_processing_activity_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_processing_activity_active ON ph09_privacy.processing_activity (tenant_id, code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_processing_activity_touch BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_processing_activity_immutable BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'version_no');
CREATE TRIGGER tg_processing_activity_frozen BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('purpose_text', 'legal_basis_code', 'categories', 'subject_groups', 'recipients', 'retention', 'controller_role', 'measures', 'legal_doc_ids');
CALL ph09_privacy.p_enable_rls('ph09_privacy.processing_activity');
COMMENT ON TABLE ph09_privacy.processing_activity IS 'EN-09-11 Hoạt động xử lý DLCN theo phiên bản (FR-09-009, 010, BR-09-009…012): mục đích, cơ sở pháp lý chính, loại dữ liệu, nhóm chủ thể, bên nhận, thời hạn lưu (số tháng hoặc điều kiện kết thúc cùng hành động), vai trò, biện pháp. ACTIVE không sửa tại chỗ, duyệt bốn mắt.';
COMMENT ON COLUMN ph09_privacy.processing_activity.categories IS 'Mã loại DLCN (personal_data_category.code); kiểm tồn tại ở dịch vụ khi gửi duyệt.';
COMMENT ON COLUMN ph09_privacy.processing_activity.legal_doc_ids IS 'Mã legal_document; mảng nên kiểm ở dịch vụ.';
COMMENT ON COLUMN ph09_privacy.processing_activity.retention IS '{months, endCondition, action}, action là RetentionAction (BR-09-012).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.processing_activity CASCADE;

-- @changeset ph09-0230-activity-link
CREATE TABLE ph09_privacy.activity_link (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  activity_id uuid NOT NULL,
  target_kind varchar(8) NOT NULL,
  target_id   varchar(128) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_activity_link PRIMARY KEY (id),
  CONSTRAINT ck_activity_link_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_activity_link_activity FOREIGN KEY (tenant_id, activity_id) REFERENCES ph09_privacy.processing_activity (tenant_id, id),
  CONSTRAINT uq_activity_link_target UNIQUE (tenant_id, activity_id, target_kind, target_id),
  CONSTRAINT ck_activity_link_kind CHECK (target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW'))
);
CREATE INDEX ix_activity_link_target ON ph09_privacy.activity_link (tenant_id, target_kind, target_id);
CREATE TRIGGER tg_activity_link_touch BEFORE UPDATE ON ph09_privacy.activity_link FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_activity_link_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.activity_link FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('processing_activity', 'activity_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.activity_link');
COMMENT ON TABLE ph09_privacy.activity_link IS 'EN-09-12 Liên kết hoạt động xử lý với phần tử, API, topic hoặc luồng (FR-09-011, BR-09-008). Chỉ sửa khi hoạt động ở DRAFT hoặc REJECTED (trigger). Mỗi trường DLCN CONFIRMED phải thuộc ít nhất một hoạt động ACTIVE (kiểm ở dịch vụ, SEC-37).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.activity_link CASCADE;


-- @file 09-0030-purpose.sql
-- @changeset ph09-0240-purpose
CREATE TABLE ph09_privacy.purpose (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  code               varchar(41) NOT NULL,
  name               varchar(255) NOT NULL,
  description        varchar(2000),
  legal_basis_code   varchar(32) NOT NULL,
  allowed_categories varchar(32)[] NOT NULL DEFAULT '{}',
  statutory          boolean NOT NULL DEFAULT false,
  max_days           integer NOT NULL DEFAULT 365,
  status             varchar(8) NOT NULL DEFAULT 'ACTIVE',
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose PRIMARY KEY (id),
  CONSTRAINT uq_purpose_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_purpose_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_purpose_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_purpose_basis FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES ph09_privacy.legal_basis (tenant_id, code),
  CONSTRAINT ck_purpose_code CHECK (code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT ck_purpose_days CHECK (max_days BETWEEN 1 AND 730),
  CONSTRAINT ck_purpose_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_purpose_touch BEFORE UPDATE ON ph09_privacy.purpose FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_purpose_immutable BEFORE UPDATE ON ph09_privacy.purpose FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose');
COMMENT ON TABLE ph09_privacy.purpose IS 'EN-09-15 Mục đích khai thác (FR-09-014, BR-09-015, 047): mã dạng TTHC-HO-TICH, THONG-KE, cơ sở pháp lý, loại DLCN được phép, cờ statutory (mục đích bắt buộc theo luật vẫn truy cập được khi chủ thể bị hạn chế), thời hạn tối đa. Trường được phép ở purpose_element.';
COMMENT ON COLUMN ph09_privacy.purpose.max_days IS 'Trần cứng 730 ngày; trần tenant 09.grant.max-days mặc định 365 (BR-09-015).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.purpose CASCADE;

-- @changeset ph09-0250-purpose-element
CREATE TABLE ph09_privacy.purpose_element (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  purpose_id uuid NOT NULL,
  element_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose_element PRIMARY KEY (id),
  CONSTRAINT ck_purpose_element_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_purpose_element_purpose FOREIGN KEY (tenant_id, purpose_id) REFERENCES ph09_privacy.purpose (tenant_id, id),
  CONSTRAINT fk_purpose_element_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT uq_purpose_element UNIQUE (tenant_id, purpose_id, element_id)
);
CREATE INDEX ix_purpose_element_element ON ph09_privacy.purpose_element (tenant_id, element_id);
CREATE TRIGGER tg_purpose_element_touch BEFORE UPDATE ON ph09_privacy.purpose_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose_element');
COMMENT ON TABLE ph09_privacy.purpose_element IS 'EN-09-52 Trường được phép theo mục đích, bảng con của Purpose (FR-09-014, BR-09-016): phạm vi tối đa mà một chấp thuận của mục đích đó được bao.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.purpose_element CASCADE;

-- @changeset ph09-0260-access-request
CREATE TABLE ph09_privacy.access_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  httt_id          varchar(63) NOT NULL,
  registration_ref varchar(63),
  purpose_code     varchar(41) NOT NULL,
  contract_kind    varchar(8) NOT NULL,
  contract_id      varchar(128) NOT NULL,
  fields           varchar(63)[] NOT NULL,
  expected_volume  integer NOT NULL,
  requested_days   integer NOT NULL,
  justification    varchar(2000) NOT NULL,
  owner_org_id     varchar(63) NOT NULL,
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  submitted_at     timestamptz,
  reviewer         varchar(64),
  decision         varchar(24),
  decision_reason  varchar(2000),
  decided_by       varchar(64),
  decided_at       timestamptz,
  due_at           timestamptz,
  request_kind     varchar(8) NOT NULL DEFAULT 'NEW',
  renews_grant_id  uuid,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_access_request PRIMARY KEY (id),
  CONSTRAINT uq_access_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_access_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_access_request_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_access_request_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_access_request_req_kind CHECK (request_kind IN ('NEW', 'RENEWAL')),
  CONSTRAINT ck_access_request_renews CHECK ((request_kind = 'RENEWAL') = (renews_grant_id IS NOT NULL)),
  CONSTRAINT ck_access_request_fields CHECK (cardinality(fields) >= 1),
  CONSTRAINT ck_access_request_volume CHECK (expected_volume BETWEEN 1 AND 10000000 AND requested_days BETWEEN 1 AND 730),
  CONSTRAINT ck_access_request_justification CHECK (char_length(justification) >= 20),
  CONSTRAINT ck_access_request_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEEDS_INFO', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT ck_access_request_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'APPROVE_WITH_CONDITIONS', 'REJECT')),
  CONSTRAINT ck_access_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> created_by),
  CONSTRAINT ck_access_request_decided CHECK ((status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL AND decision IS NOT NULL)),
  CONSTRAINT ck_access_request_outcome CHECK ((status <> 'APPROVED' OR decision IN ('APPROVE', 'APPROVE_WITH_CONDITIONS')) AND (status <> 'REJECTED' OR (decision = 'REJECT' AND COALESCE(char_length(decision_reason) >= 20, false)))),
  CONSTRAINT ck_access_request_submitted CHECK (status IN ('DRAFT', 'WITHDRAWN') OR submitted_at IS NOT NULL)
);
CREATE INDEX ix_access_request_inbox ON ph09_privacy.access_request (tenant_id, owner_org_id, status, due_at) WHERE status IN ('SUBMITTED', 'UNDER_REVIEW', 'NEEDS_INFO');
CREATE INDEX ix_access_request_httt ON ph09_privacy.access_request (tenant_id, httt_id, created_at DESC);
CREATE TRIGGER tg_access_request_touch BEFORE UPDATE ON ph09_privacy.access_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_access_request_immutable BEFORE UPDATE ON ph09_privacy.access_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('httt_id', 'purpose_code', 'contract_kind', 'contract_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.access_request');
COMMENT ON TABLE ph09_privacy.access_request IS 'EN-09-16 Yêu cầu khai thác của HTTT cho một mục đích (FR-09-015, 016, BR-09-013, 014, 016). Máy trạng thái AccessRequestStatus; chủ quản không duyệt yêu cầu do chính mình lập. Hợp đồng phải mức từ RESTRICTED (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph09_privacy.access_request.httt_id IS 'Mã HTTT ở PH-01 (không khóa ngoại).';
COMMENT ON COLUMN ph09_privacy.access_request.registration_ref IS 'Đăng ký sử dụng ở PH-02.';
COMMENT ON COLUMN ph09_privacy.access_request.owner_org_id IS 'Tổ chức chủ quản dữ liệu, đích hộp việc của DO.';
COMMENT ON COLUMN ph09_privacy.access_request.request_kind IS 'AccessRequestKind: NEW (mặc định) hoặc RENEWAL, yêu cầu gia hạn chấp thuận hiện có (FR-09-015).';
COMMENT ON COLUMN ph09_privacy.access_request.renews_grant_id IS 'Chấp thuận ACTIVE được gia hạn; bắt buộc khi RENEWAL, rỗng khi NEW; cùng HTTT và mục đích kiểm ở dịch vụ (FR-09-015, 016).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.access_request CASCADE;

-- @changeset ph09-0270-purpose-grant
CREATE TABLE ph09_privacy.purpose_grant (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  request_id         uuid NOT NULL,
  httt_id            varchar(63) NOT NULL,
  purpose_code       varchar(41) NOT NULL,
  contract_kind      varchar(8) NOT NULL,
  contract_id        varchar(128) NOT NULL,
  valid_from         timestamptz NOT NULL,
  valid_to           timestamptz NOT NULL,
  status             varchar(12) NOT NULL,
  fields             varchar(63)[] NOT NULL,
  quota_per_day      integer,
  renew_count        smallint NOT NULL DEFAULT 0,
  approved_by        varchar(64) NOT NULL,
  approved_at        timestamptz NOT NULL DEFAULT now(),
  suspended_at       timestamptz,
  suspend_reason     varchar(2000),
  revoked_by         varchar(64),
  revoked_at         timestamptz,
  revoke_reason      varchar(2000),
  expired_at         timestamptz,
  expiry_notified_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose_grant PRIMARY KEY (id),
  CONSTRAINT uq_purpose_grant_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_purpose_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_purpose_grant_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.access_request (tenant_id, id),
  CONSTRAINT fk_purpose_grant_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_purpose_grant_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_purpose_grant_period CHECK (valid_to > valid_from AND valid_to <= valid_from + interval '730 days'),
  CONSTRAINT ck_purpose_grant_status CHECK (status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_purpose_grant_fields CHECK (cardinality(fields) >= 1),
  CONSTRAINT ck_purpose_grant_quota CHECK (quota_per_day IS NULL OR quota_per_day BETWEEN 1 AND 100000000),
  CONSTRAINT ck_purpose_grant_renew CHECK (renew_count BETWEEN 0 AND 10),
  CONSTRAINT ck_purpose_grant_suspended CHECK (status <> 'SUSPENDED' OR (suspended_at IS NOT NULL AND suspend_reason IS NOT NULL)),
  CONSTRAINT ck_purpose_grant_revoked CHECK (status <> 'REVOKED' OR (revoked_by IS NOT NULL AND revoked_at IS NOT NULL AND COALESCE(char_length(revoke_reason) >= 20, false))),
  CONSTRAINT ck_purpose_grant_expired CHECK (status <> 'EXPIRED' OR expired_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_purpose_grant_live ON ph09_privacy.purpose_grant (tenant_id, httt_id, purpose_code, contract_kind, contract_id) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');
CREATE INDEX ix_purpose_grant_expiry ON ph09_privacy.purpose_grant (tenant_id, valid_to) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');
CREATE INDEX ix_purpose_grant_httt ON ph09_privacy.purpose_grant (tenant_id, httt_id, status);
CREATE TRIGGER tg_purpose_grant_touch BEFORE UPDATE ON ph09_privacy.purpose_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_purpose_grant_immutable BEFORE UPDATE ON ph09_privacy.purpose_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_id', 'httt_id', 'purpose_code', 'contract_kind', 'contract_id', 'approved_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose_grant');
COMMENT ON TABLE ph09_privacy.purpose_grant IS 'EN-09-17 Chấp thuận khai thác: bộ ba (HTTT, mục đích, hợp đồng), không chuyển nhượng (BR-09-013, FR-09-016, 017). Máy trạng thái GrantStatus; tối đa 3 lần gia hạn mặc định; thu hồi cần lý do 20 ký tự; một chấp thuận hiệu lực mỗi bộ ba. Nguồn của purpose_grants trong bundle OPA (FR-09-018).';
ALTER TABLE ph09_privacy.access_request ADD CONSTRAINT fk_access_request_renews FOREIGN KEY (tenant_id, renews_grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id);
-- @rollback DROP TABLE IF EXISTS ph09_privacy.purpose_grant CASCADE;

-- @changeset ph09-0280-grant-condition
CREATE TABLE ph09_privacy.grant_condition (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  grant_id       uuid NOT NULL,
  condition_type varchar(16) NOT NULL,
  params         jsonb NOT NULL DEFAULT '{}',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_grant_condition PRIMARY KEY (id),
  CONSTRAINT ck_grant_condition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_grant_condition_grant FOREIGN KEY (tenant_id, grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id),
  CONSTRAINT uq_grant_condition_type UNIQUE (tenant_id, grant_id, condition_type),
  CONSTRAINT ck_grant_condition_type CHECK (condition_type IN ('FIELD_SUBSET', 'DAILY_QUOTA', 'TIME_WINDOW', 'NO_EXPORT', 'MASK_REQUIRED')),
  CONSTRAINT ck_grant_condition_params CHECK (jsonb_typeof(params) = 'object')
);
CREATE TRIGGER tg_grant_condition_touch BEFORE UPDATE ON ph09_privacy.grant_condition FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.grant_condition');
COMMENT ON TABLE ph09_privacy.grant_condition IS 'EN-09-18 Điều kiện của chấp thuận (FR-09-016, BR-09-016): FIELD_SUBSET, DAILY_QUOTA, TIME_WINDOW, NO_EXPORT, MASK_REQUIRED, tham số jsonb. Ghi vào bundle OPA; mỗi loại tối đa một dòng mỗi chấp thuận.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.grant_condition CASCADE;

-- @changeset ph09-0290-policy-bundle
CREATE TABLE ph09_privacy.policy_bundle (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  bundle_no       bigint NOT NULL,
  content_hash    bytea NOT NULL,
  signature       bytea,
  signing_key_ref varchar(128),
  object_ref      varchar(512) NOT NULL,
  size_bytes      integer NOT NULL,
  counts          jsonb NOT NULL DEFAULT '{}',
  test_passed     boolean NOT NULL DEFAULT false,
  test_result     jsonb,
  published_at    timestamptz,
  valid_until     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_bundle PRIMARY KEY (id),
  CONSTRAINT uq_policy_bundle_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_policy_bundle_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_policy_bundle_no UNIQUE (tenant_id, bundle_no),
  CONSTRAINT ck_policy_bundle_hash CHECK (octet_length(content_hash) = 32),
  CONSTRAINT ck_policy_bundle_size CHECK (size_bytes BETWEEN 1 AND 5242880),
  CONSTRAINT ck_policy_bundle_published CHECK (published_at IS NULL OR (test_passed AND signature IS NOT NULL AND signing_key_ref IS NOT NULL AND valid_until IS NOT NULL)),
  CONSTRAINT ck_policy_bundle_valid CHECK (valid_until IS NULL OR (published_at IS NOT NULL AND valid_until > published_at AND valid_until <= published_at + interval '240 minutes'))
);
CREATE INDEX ix_policy_bundle_published ON ph09_privacy.policy_bundle (tenant_id, published_at DESC) WHERE published_at IS NOT NULL;
CREATE TRIGGER tg_policy_bundle_touch BEFORE UPDATE ON ph09_privacy.policy_bundle FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_policy_bundle_immutable BEFORE UPDATE ON ph09_privacy.policy_bundle FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('bundle_no', 'content_hash', 'object_ref');
CALL ph09_privacy.p_enable_rls('ph09_privacy.policy_bundle');
COMMENT ON TABLE ph09_privacy.policy_bundle IS 'EN-09-19 Bundle purpose_grants, mask_policies, classification_index đã ký (FR-09-018, BR-09-018): băm nội dung, chữ ký bằng khóa transit không xuất được, validUntil = phát hành cộng 60 phút mặc định, kết quả kiểm thử. Nội dung bundle ở Garage (object_ref), ≤ 5 MB. Chỉ phát hành khi kiểm thử đạt.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.policy_bundle CASCADE;

-- @changeset ph09-0300-usage-counter
CREATE TABLE ph09_privacy.usage_counter (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  bucket_at         timestamptz NOT NULL,
  httt_id           varchar(63) NOT NULL,
  purpose_code      varchar(41) NOT NULL,
  contract_kind     varchar(8) NOT NULL,
  contract_id       varchar(128) NOT NULL,
  reporter          varchar(64) NOT NULL,
  allowed_count     integer NOT NULL DEFAULT 0,
  denied_count      integer NOT NULL DEFAULT 0,
  off_purpose_count integer NOT NULL DEFAULT 0,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_usage_counter PRIMARY KEY (id, bucket_at),
  CONSTRAINT ck_usage_counter_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_usage_counter_key UNIQUE (tenant_id, httt_id, purpose_code, contract_kind, contract_id, reporter, bucket_at),
  CONSTRAINT ck_usage_counter_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_usage_counter_minute CHECK (bucket_at = date_trunc('minute', bucket_at)),
  CONSTRAINT ck_usage_counter_counts CHECK (allowed_count >= 0 AND denied_count >= 0 AND off_purpose_count >= 0)
) PARTITION BY RANGE (bucket_at);
CALL ph09_privacy.p_ensure_partitions('ph09_privacy.usage_counter', current_date, 3);
CREATE INDEX ix_usage_counter_purpose ON ph09_privacy.usage_counter (tenant_id, purpose_code, bucket_at DESC);
CALL ph09_privacy.p_enable_rls('ph09_privacy.usage_counter');
COMMENT ON TABLE ph09_privacy.usage_counter IS 'EN-09-20 Bộ đếm khai thác theo (HTTT, mục đích, hợp đồng, phút) do điểm thực thi báo (FR-09-019, 020, BR-09-020). Cập nhật cộng dồn (upsert); phân vùng tháng theo bucket_at; giữ 13 tháng. Không chứa giá trị dữ liệu.';
COMMENT ON COLUMN ph09_privacy.usage_counter.reporter IS 'Điểm thực thi báo số đếm (APISIX, PH-04, PH-06, PH-14, PH-19).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.usage_counter CASCADE;

-- @changeset ph09-0310-usage-anomaly
CREATE TABLE ph09_privacy.usage_anomaly (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  anomaly_type  varchar(16) NOT NULL,
  severity      varchar(8) NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'OPEN',
  httt_id       varchar(63) NOT NULL,
  purpose_code  varchar(41),
  contract_kind varchar(8),
  contract_id   varchar(128),
  grant_id      uuid,
  detected_at   timestamptz NOT NULL DEFAULT now(),
  window_from   timestamptz NOT NULL,
  window_to     timestamptz NOT NULL,
  observed      bigint NOT NULL,
  threshold     bigint,
  handled_by    varchar(64),
  handled_at    timestamptz,
  handle_note   varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_anomaly PRIMARY KEY (id),
  CONSTRAINT ck_usage_anomaly_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_usage_anomaly_grant FOREIGN KEY (tenant_id, grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id),
  CONSTRAINT ck_usage_anomaly_type CHECK (anomaly_type IN ('QUOTA_EXCEEDED', 'BULK_ACCESS', 'OFF_PURPOSE', 'OFF_HOURS', 'DORMANT_REUSE')),
  CONSTRAINT ck_usage_anomaly_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_usage_anomaly_status CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'DISMISSED', 'ESCALATED')),
  CONSTRAINT ck_usage_anomaly_kind CHECK (contract_kind IS NULL OR contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_usage_anomaly_window CHECK (window_to >= window_from AND observed >= 0),
  CONSTRAINT ck_usage_anomaly_handled CHECK (status = 'OPEN' OR (handled_by IS NOT NULL AND handled_at IS NOT NULL))
);
CREATE INDEX ix_usage_anomaly_open ON ph09_privacy.usage_anomaly (tenant_id, severity, detected_at DESC) WHERE status = 'OPEN';
CREATE INDEX ix_usage_anomaly_httt ON ph09_privacy.usage_anomaly (tenant_id, httt_id, detected_at DESC);
CREATE TRIGGER tg_usage_anomaly_touch BEFORE UPDATE ON ph09_privacy.usage_anomaly FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.usage_anomaly');
COMMENT ON TABLE ph09_privacy.usage_anomaly IS 'EN-09-21 Cảnh báo khai thác bất thường (FR-09-020, THR-51): AnomalyType, mức RiskLevel, trạng thái AnomalyStatus; phát hiện trong 5 phút (BR-09-020). Xử lý phải có người và thời điểm.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.usage_anomaly CASCADE;


-- @file 09-0040-masking.sql
-- @changeset ph09-0320-mask-type
CREATE TABLE ph09_privacy.mask_type (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  code           varchar(48) NOT NULL,
  mask_type      varchar(12) NOT NULL,
  pattern_kind   varchar(24),
  name           varchar(255) NOT NULL,
  default_params jsonb NOT NULL DEFAULT '{}',
  reversible     boolean NOT NULL DEFAULT false,
  builtin        boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_type PRIMARY KEY (id),
  CONSTRAINT uq_mask_type_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_type_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mask_type_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_mask_type_type CHECK (mask_type IN ('NONE', 'PARTIAL', 'REPLACE', 'KEYED_HASH', 'TOKENIZE', 'GENERALIZE', 'DROP')),
  CONSTRAINT ck_mask_type_pattern CHECK (pattern_kind IS NULL OR pattern_kind IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_mask_type_pairing CHECK ((mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL) AND (pattern_kind IS NULL OR (mask_type = 'PARTIAL') = (pattern_kind LIKE 'KEEP\_%'))),
  CONSTRAINT ck_mask_type_reversible CHECK (NOT reversible OR mask_type = 'TOKENIZE')
);
CREATE TRIGGER tg_mask_type_touch BEFORE UPDATE ON ph09_privacy.mask_type FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_type_immutable BEFORE UPDATE ON ph09_privacy.mask_type FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'mask_type', 'pattern_kind');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_type');
COMMENT ON TABLE ph09_privacy.mask_type IS 'EN-09-22 Kiểu che MaskType và mẫu che MaskPatternKind có tham số (FR-09-023, BR-09-021, 024): NONE, PARTIAL (KEEP_*), REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE (YEAR_ONLY, ADMIN_LEVEL), DROP. Nạp sẵn; tenant sửa tham số mặc định, thêm mẫu không đổi bộ kiểu.';
COMMENT ON COLUMN ph09_privacy.mask_type.default_params IS 'Tham số mặc định n, m, char, level (FR-09-023).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.mask_type CASCADE;

-- @changeset ph09-0330-mask-policy
CREATE TABLE ph09_privacy.mask_policy (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  policy_code          varchar(63) NOT NULL,
  version_no           integer NOT NULL,
  status               varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by         varchar(64),
  submitted_at         timestamptz,
  decided_by           varchar(64),
  decided_at           timestamptz,
  decision_comment     varchar(2000),
  activated_at         timestamptz,
  superseded_at        timestamptz,
  scope                varchar(8) NOT NULL DEFAULT 'TENANT',
  contract_kind        varchar(8),
  contract_id          varchar(128),
  description          varchar(2000),
  passed_simulation_id uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_policy PRIMARY KEY (id),
  CONSTRAINT uq_mask_policy_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_mask_policy_code CHECK (policy_code ~ '^[A-Za-z][A-Za-z0-9-]{2,62}$'),
  CONSTRAINT ck_mask_policy_scope CHECK (scope IN ('TENANT', 'CONTRACT') AND ((scope = 'CONTRACT') = (contract_id IS NOT NULL AND contract_kind IS NOT NULL))),
  CONSTRAINT ck_mask_policy_kind CHECK (contract_kind IS NULL OR contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_mask_policy_simulated CHECK (status NOT IN ('PENDING_APPROVAL', 'ACTIVE') OR passed_simulation_id IS NOT NULL),
  CONSTRAINT uq_mask_policy_version UNIQUE (tenant_id, policy_code, version_no),
  CONSTRAINT ck_mask_policy_version CHECK (version_no >= 1),
  CONSTRAINT ck_mask_policy_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_mask_policy_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_mask_policy_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_mask_policy_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_mask_policy_active ON ph09_privacy.mask_policy (tenant_id, policy_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_mask_policy_touch BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_policy_immutable BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('policy_code', 'version_no', 'scope', 'contract_id');
CREATE TRIGGER tg_mask_policy_frozen BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('passed_simulation_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_policy');
COMMENT ON TABLE ph09_privacy.mask_policy IS 'EN-09-23 Chính sách che theo phiên bản (FR-09-024, 026, BR-09-022, 023): phạm vi TENANT hoặc CONTRACT. Kích hoạt cần mô phỏng đạt (passed_simulation_id) và người duyệt khác người soạn (ADR-046). Quay lại bản cũ là tạo phiên bản mới.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.mask_policy CASCADE;

-- @changeset ph09-0340-mask-rule
CREATE TABLE ph09_privacy.mask_rule (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  policy_id     uuid NOT NULL,
  seq           smallint NOT NULL,
  priority      smallint NOT NULL DEFAULT 100,
  cond_class    varchar(16),
  cond_category varchar(32),
  cond_roles    varchar(16)[],
  cond_purpose  varchar(41),
  cond_channel  varchar(8),
  mask_type     varchar(12) NOT NULL,
  pattern_kind  varchar(24),
  params        jsonb NOT NULL DEFAULT '{}',
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_rule PRIMARY KEY (id),
  CONSTRAINT ck_mask_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_mask_rule_policy FOREIGN KEY (tenant_id, policy_id) REFERENCES ph09_privacy.mask_policy (tenant_id, id),
  CONSTRAINT uq_mask_rule_seq UNIQUE (tenant_id, policy_id, seq),
  CONSTRAINT ck_mask_rule_priority CHECK (priority BETWEEN 1 AND 999),
  CONSTRAINT ck_mask_rule_class CHECK (cond_class IS NULL OR cond_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_mask_rule_channel CHECK (cond_channel IS NULL OR cond_channel IN ('UI', 'API', 'EXPORT', 'LOG', 'FLOW')),
  CONSTRAINT ck_mask_rule_type CHECK (mask_type IN ('NONE', 'PARTIAL', 'REPLACE', 'KEYED_HASH', 'TOKENIZE', 'GENERALIZE', 'DROP')),
  CONSTRAINT ck_mask_rule_pattern CHECK (pattern_kind IS NULL OR pattern_kind IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_mask_rule_pairing CHECK ((mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL)),
  CONSTRAINT ck_mask_rule_sensitive CHECK (cond_class IS DISTINCT FROM 'SENSITIVE' OR mask_type <> 'NONE')
);
CREATE INDEX ix_mask_rule_policy ON ph09_privacy.mask_rule (tenant_id, policy_id, priority DESC);
CREATE TRIGGER tg_mask_rule_touch BEFORE UPDATE ON ph09_privacy.mask_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.mask_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('mask_policy', 'policy_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_rule');
COMMENT ON TABLE ph09_privacy.mask_rule IS 'EN-09-24 Quy tắc che trong chính sách (FR-09-024, BR-09-021, 022): điều kiện (mức, loại DLCN, vai trò, mục đích, kênh), kiểu che, tham số, độ ưu tiên; quy tắc cụ thể hơn thắng, trùng thì kiểu chặt hơn thắng. Mức SENSITIVE không được NONE. Chỉ sửa khi chính sách DRAFT hoặc REJECTED.';
COMMENT ON COLUMN ph09_privacy.mask_rule.cond_roles IS 'Mã vai trò viết tắt (PA, TA, DS, VW...); rỗng là mọi vai trò.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.mask_rule CASCADE;

-- @changeset ph09-0350-mask-simulation
CREATE TABLE ph09_privacy.mask_simulation (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  policy_id      uuid NOT NULL,
  policy_version integer NOT NULL,
  sample_ref     varchar(512) NOT NULL,
  sample_rows    integer NOT NULL,
  role           varchar(16),
  purpose_code   varchar(41),
  channel        varchar(8),
  result         jsonb NOT NULL DEFAULT '{}',
  passed         boolean NOT NULL DEFAULT false,
  run_by         varchar(64) NOT NULL,
  run_at         timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_simulation PRIMARY KEY (id),
  CONSTRAINT uq_mask_simulation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_simulation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_mask_simulation_policy FOREIGN KEY (tenant_id, policy_id) REFERENCES ph09_privacy.mask_policy (tenant_id, id),
  CONSTRAINT ck_mask_simulation_rows CHECK (sample_rows BETWEEN 1 AND 1000),
  CONSTRAINT ck_mask_simulation_channel CHECK (channel IS NULL OR channel IN ('UI', 'API', 'EXPORT', 'LOG', 'FLOW'))
);
CREATE INDEX ix_mask_simulation_policy ON ph09_privacy.mask_simulation (tenant_id, policy_id, run_at DESC);
CREATE TRIGGER tg_mask_simulation_touch BEFORE UPDATE ON ph09_privacy.mask_simulation FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_simulation_immutable BEFORE UPDATE ON ph09_privacy.mask_simulation FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('policy_id', 'policy_version', 'sample_ref', 'passed');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_simulation');
COMMENT ON TABLE ph09_privacy.mask_simulation IS 'EN-09-25 Lần mô phỏng chính sách che trên bộ mẫu dữ liệu giả ≤ 1.000 dòng (FR-09-025, NFR-09-023): bộ mẫu ở Garage, kết quả tóm tắt, passed. Không lưu giá trị mẫu trong bảng (BR-09-025).';
ALTER TABLE ph09_privacy.mask_policy ADD CONSTRAINT fk_mask_policy_simulation FOREIGN KEY (tenant_id, passed_simulation_id) REFERENCES ph09_privacy.mask_simulation (tenant_id, id);
-- @rollback DROP TABLE IF EXISTS ph09_privacy.mask_simulation CASCADE;

-- @changeset ph09-0360-reveal-grant
CREATE TABLE ph09_privacy.reveal_grant (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  requested_by varchar(64) NOT NULL,
  target_ref   varchar(255) NOT NULL,
  fields       varchar(63)[] NOT NULL,
  reason       varchar(2000) NOT NULL,
  status       varchar(8) NOT NULL DEFAULT 'ISSUED',
  issued_at    timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  verified_at  timestamptz,
  token_hash   bytea NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_reveal_grant PRIMARY KEY (id),
  CONSTRAINT ck_reveal_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_reveal_grant_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_reveal_grant_status CHECK (status IN ('ISSUED', 'VERIFIED', 'EXPIRED')),
  CONSTRAINT ck_reveal_grant_ttl CHECK (expires_at > issued_at AND expires_at <= issued_at + interval '60 seconds'),
  CONSTRAINT ck_reveal_grant_fields CHECK (cardinality(fields) BETWEEN 1 AND 50),
  CONSTRAINT ck_reveal_grant_hash CHECK (octet_length(token_hash) = 32),
  CONSTRAINT ck_reveal_grant_verified CHECK ((status = 'VERIFIED') = (verified_at IS NOT NULL))
);
CREATE INDEX ix_reveal_grant_user ON ph09_privacy.reveal_grant (tenant_id, requested_by, issued_at DESC);
CREATE TRIGGER tg_reveal_grant_touch BEFORE UPDATE ON ph09_privacy.reveal_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_reveal_grant_immutable BEFORE UPDATE ON ph09_privacy.reveal_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('requested_by', 'target_ref', 'fields', 'reason', 'issued_at', 'expires_at', 'token_hash');
CALL ph09_privacy.p_enable_rls('ph09_privacy.reveal_grant');
COMMENT ON TABLE ph09_privacy.reveal_grant IS 'EN-09-26 Phiếu xem giá trị đầy đủ (FR-09-029, BR-09-026): người xin, đối tượng, trường, lý do ≥ 20 ký tự, hết hạn đúng ≤ 60 giây, tối đa 20 lần mỗi giờ. Chỉ lưu băm phiếu; giá trị rõ không ghi đĩa; trường never_reveal bị chặn ở dịch vụ. Thao tác bị từ chối nếu không ghi được kiểm toán (BR-09-057).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.reveal_grant CASCADE;

-- @changeset ph09-0370-log-mask-config
CREATE TABLE ph09_privacy.log_mask_config (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  allow_attributes  varchar(63)[] NOT NULL DEFAULT '{}',
  patterns          varchar(24)[] NOT NULL,
  scan_window_hours smallint NOT NULL DEFAULT 24,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_log_mask_config PRIMARY KEY (id),
  CONSTRAINT ck_log_mask_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_log_mask_config_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_log_mask_config_patterns CHECK (cardinality(patterns) >= 1 AND patterns <@ ARRAY['NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT']::varchar[]),
  CONSTRAINT ck_log_mask_config_window CHECK (scan_window_hours BETWEEN 1 AND 168)
);
CREATE TRIGGER tg_log_mask_config_touch BEFORE UPDATE ON ph09_privacy.log_mask_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.log_mask_config');
COMMENT ON TABLE ph09_privacy.log_mask_config IS 'EN-09-27 Cấu hình che log, trace (FR-09-030, SEC-32): danh sách thuộc tính được phép, mẫu quét, cửa sổ quét. Một dòng mỗi tenant.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.log_mask_config CASCADE;

-- @changeset ph09-0380-leak-finding
CREATE TABLE ph09_privacy.leak_finding (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  source        varchar(128) NOT NULL,
  detector_code varchar(24) NOT NULL,
  match_count   integer NOT NULL,
  fingerprint   bytea NOT NULL,
  first_seen_at timestamptz NOT NULL,
  last_seen_at  timestamptz NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'OPEN',
  resolved_by   varchar(64),
  resolved_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_leak_finding PRIMARY KEY (id),
  CONSTRAINT ck_leak_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_leak_finding_fp UNIQUE (tenant_id, source, detector_code, fingerprint),
  CONSTRAINT ck_leak_finding_detector CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_leak_finding_status CHECK (status IN ('OPEN', 'CONFIRMED_PII', 'EXCLUDED', 'CLASSIFIED')),
  CONSTRAINT ck_leak_finding_count CHECK (match_count >= 1 AND last_seen_at >= first_seen_at AND octet_length(fingerprint) = 32),
  CONSTRAINT ck_leak_finding_resolved CHECK (status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE INDEX ix_leak_finding_open ON ph09_privacy.leak_finding (tenant_id, last_seen_at DESC) WHERE status = 'OPEN';
CREATE TRIGGER tg_leak_finding_touch BEFORE UPDATE ON ph09_privacy.leak_finding FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.leak_finding');
COMMENT ON TABLE ph09_privacy.leak_finding IS 'EN-09-28 Kết quả quét rò rỉ DLCN trong log, trace (FR-09-030, NFR-09-014): nguồn, mẫu khớp, số lần, dấu vân HMAC của vị trí. Không lưu đoạn log khớp. Trạng thái FindingStatus.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.leak_finding CASCADE;


-- @file 09-0050-pseudonym.sql
-- @changeset ph09-0390-pseudonym-domain
CREATE TABLE ph09_privacy.pseudonym_domain (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_code         varchar(41) NOT NULL,
  purpose_code        varchar(41) NOT NULL,
  method              varchar(16) NOT NULL,
  rotate_days         smallint NOT NULL DEFAULT 365,
  description         varchar(2000),
  status              varchar(12) NOT NULL DEFAULT 'ACTIVE',
  key_name            varchar(128) NOT NULL,
  current_key_version integer NOT NULL DEFAULT 1,
  last_rotated_at     timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_pseudonym_domain PRIMARY KEY (id),
  CONSTRAINT uq_pseudonym_domain_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_pseudonym_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_pseudonym_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT fk_pseudonym_domain_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_pseudonym_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT ck_pseudonym_domain_method CHECK (method IN ('HMAC_SHA256', 'TOKEN_TRANSIT')),
  CONSTRAINT ck_pseudonym_domain_rotate CHECK (rotate_days BETWEEN 90 AND 730),
  CONSTRAINT ck_pseudonym_domain_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_pseudonym_domain_version CHECK (current_key_version >= 1)
);
CREATE TRIGGER tg_pseudonym_domain_touch BEFORE UPDATE ON ph09_privacy.pseudonym_domain FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_pseudonym_domain_immutable BEFORE UPDATE ON ph09_privacy.pseudonym_domain FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_code', 'purpose_code', 'method', 'key_name');
CALL ph09_privacy.p_enable_rls('ph09_privacy.pseudonym_domain');
COMMENT ON TABLE ph09_privacy.pseudonym_domain IS 'EN-09-29 Miền giả danh hóa theo tenant và mục đích (FR-09-031, BR-09-028, 031): phương pháp PseudonymMethod, chu kỳ xoay 90 đến 730 ngày, trạng thái. Khóa riêng mỗi miền nên hai tập cho hai mục đích không nối được. Không có bảng ánh xạ bí danh (BR-09-030).';
COMMENT ON COLUMN ph09_privacy.pseudonym_domain.key_name IS 'Tên khóa transit OpenBao dh-{tenant}-pseudo-{miền}; không chứa vật liệu khóa.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.pseudonym_domain CASCADE;

-- @changeset ph09-0400-pseudonym-key
CREATE TABLE ph09_privacy.pseudonym_key (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_id            uuid NOT NULL,
  key_version          integer NOT NULL,
  status               varchar(12) NOT NULL DEFAULT 'ACTIVE',
  openbao_ref          varchar(255) NOT NULL,
  activated_at         timestamptz NOT NULL DEFAULT now(),
  disabled_at          timestamptz,
  destroy_requested_by varchar(64),
  destroy_approved_by  varchar(64),
  destroy_not_before   timestamptz,
  destroyed_at         timestamptz,
  reason               varchar(2000),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_pseudonym_key PRIMARY KEY (id),
  CONSTRAINT uq_pseudonym_key_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_pseudonym_key_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_pseudonym_key_domain FOREIGN KEY (tenant_id, domain_id) REFERENCES ph09_privacy.pseudonym_domain (tenant_id, id),
  CONSTRAINT uq_pseudonym_key_version UNIQUE (tenant_id, domain_id, key_version),
  CONSTRAINT ck_pseudonym_key_version CHECK (key_version >= 1),
  CONSTRAINT ck_pseudonym_key_status CHECK (status IN ('ACTIVE', 'DECRYPT_ONLY', 'DISABLED', 'DESTROYED')),
  CONSTRAINT ck_pseudonym_key_ref CHECK (openbao_ref ~ '^transit/keys/[a-z0-9-]+$'),
  CONSTRAINT ck_pseudonym_key_destroyed CHECK (status <> 'DESTROYED' OR (destroyed_at IS NOT NULL AND destroy_requested_by IS NOT NULL AND destroy_approved_by IS NOT NULL AND destroy_approved_by <> destroy_requested_by AND destroy_not_before IS NOT NULL AND destroyed_at >= destroy_not_before)),
  CONSTRAINT ck_pseudonym_key_disabled CHECK (status NOT IN ('DISABLED', 'DESTROYED') OR disabled_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_pseudonym_key_active ON ph09_privacy.pseudonym_key (tenant_id, domain_id) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_pseudonym_key_touch BEFORE UPDATE ON ph09_privacy.pseudonym_key FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_pseudonym_key_immutable BEFORE UPDATE ON ph09_privacy.pseudonym_key FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_id', 'key_version', 'openbao_ref');
CALL ph09_privacy.p_enable_rls('ph09_privacy.pseudonym_key');
COMMENT ON TABLE ph09_privacy.pseudonym_key IS 'EN-09-30 Siêu dữ liệu phiên bản khóa giả danh hóa (FR-09-034, BR-09-029, 033): ACTIVE, DECRYPT_ONLY, DISABLED, DESTROYED. Không chứa vật liệu khóa. Hủy cần hai người duyệt khác nhau và chờ ≥ 7 ngày; mỗi miền một phiên bản ACTIVE.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.pseudonym_key CASCADE;

-- @changeset ph09-0410-reidentification-request
CREATE TABLE ph09_privacy.reidentification_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_id           uuid NOT NULL,
  token_count         smallint NOT NULL,
  tokens_digest       bytea NOT NULL,
  purpose_code        varchar(41) NOT NULL,
  basis               varchar(500) NOT NULL,
  reason              varchar(2000) NOT NULL,
  status              varchar(12) NOT NULL DEFAULT 'PENDING_L1',
  requested_by        varchar(64) NOT NULL,
  mfa_verified        boolean NOT NULL DEFAULT false,
  l1_by               varchar(64),
  l1_at               timestamptz,
  l2_by               varchar(64),
  l2_at               timestamptz,
  approval_expires_at timestamptz NOT NULL,
  exec_deadline_at    timestamptz,
  executed_by         varchar(64),
  executed_at         timestamptz,
  reject_reason       varchar(2000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_reidentification_request PRIMARY KEY (id),
  CONSTRAINT ck_reidentification_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_reidentification_request_domain FOREIGN KEY (tenant_id, domain_id) REFERENCES ph09_privacy.pseudonym_domain (tenant_id, id),
  CONSTRAINT fk_reidentification_request_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_reidentification_request_count CHECK (token_count BETWEEN 1 AND 100 AND octet_length(tokens_digest) = 32),
  CONSTRAINT ck_reidentification_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_reidentification_request_status CHECK (status IN ('PENDING_L1', 'PENDING_L2', 'APPROVED', 'EXECUTED', 'REJECTED', 'EXPIRED')),
  CONSTRAINT ck_reidentification_request_l1 CHECK (l1_by IS NULL OR (l1_by <> requested_by AND l1_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_l2 CHECK (l2_by IS NULL OR (l1_by IS NOT NULL AND l2_by <> l1_by AND l2_by <> requested_by AND l2_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_approved CHECK (status NOT IN ('APPROVED', 'EXECUTED') OR (l1_by IS NOT NULL AND l2_by IS NOT NULL AND mfa_verified AND exec_deadline_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_executed CHECK (status <> 'EXECUTED' OR (executed_by IS NOT NULL AND executed_at IS NOT NULL AND executed_at <= exec_deadline_at)),
  CONSTRAINT ck_reidentification_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL)
);
CREATE INDEX ix_reidentification_request_open ON ph09_privacy.reidentification_request (tenant_id, status, created_at DESC) WHERE status IN ('PENDING_L1', 'PENDING_L2', 'APPROVED');
CREATE TRIGGER tg_reidentification_request_touch BEFORE UPDATE ON ph09_privacy.reidentification_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_reidentification_request_immutable BEFORE UPDATE ON ph09_privacy.reidentification_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_id', 'token_count', 'tokens_digest', 'purpose_code', 'basis', 'requested_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.reidentification_request');
COMMENT ON TABLE ph09_privacy.reidentification_request IS 'EN-09-31 Đề nghị khôi phục giá trị gốc từ token (FR-09-033, BR-09-032, 057): ≤ 100 giá trị, mục đích, căn cứ, MFA, hai cấp duyệt khác nhau và khác người đề nghị, hạn duyệt 24 giờ, cửa sổ thực hiện 30 phút. Không lưu token hay giá trị, chỉ số lượng và băm danh sách. Kiểm toán WORM vĩnh viễn.';
COMMENT ON COLUMN ph09_privacy.reidentification_request.tokens_digest IS 'Băm SHA-256 danh sách token để đối chiếu khi thực hiện; không lưu token.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.reidentification_request CASCADE;

-- @changeset ph09-0420-anonymization-config
CREATE TABLE ph09_privacy.anonymization_config (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  config_code      varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  privacy_model    varchar(16) NOT NULL DEFAULT 'K_ANONYMITY',
  k                smallint NOT NULL DEFAULT 10,
  l                smallint,
  rules            jsonb NOT NULL,
  hierarchies      jsonb NOT NULL DEFAULT '{}',
  purpose_code     varchar(41) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymization_config PRIMARY KEY (id),
  CONSTRAINT uq_anonymization_config_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymization_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_anonymization_config_code CHECK (config_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_anonymization_config_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymization_config_model CHECK (privacy_model IN ('K_ANONYMITY', 'L_DIVERSITY')),
  CONSTRAINT ck_anonymization_config_k CHECK (k BETWEEN 10 AND 100),
  CONSTRAINT ck_anonymization_config_l CHECK ((privacy_model = 'L_DIVERSITY') = (l IS NOT NULL) AND (l IS NULL OR l BETWEEN 2 AND k)),
  CONSTRAINT ck_anonymization_config_rules CHECK (jsonb_typeof(rules) = 'array' AND jsonb_array_length(rules) BETWEEN 1 AND 200),
  CONSTRAINT uq_anonymization_config_version UNIQUE (tenant_id, config_code, version_no),
  CONSTRAINT ck_anonymization_config_version CHECK (version_no >= 1),
  CONSTRAINT ck_anonymization_config_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_anonymization_config_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_anonymization_config_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_anonymization_config_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_anonymization_config_active ON ph09_privacy.anonymization_config (tenant_id, config_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_anonymization_config_touch BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_anonymization_config_immutable BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('config_code', 'version_no');
CREATE TRIGGER tg_anonymization_config_frozen BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('privacy_model', 'k', 'l', 'rules', 'hierarchies', 'purpose_code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymization_config');
COMMENT ON TABLE ph09_privacy.anonymization_config IS 'EN-09-32 Cấu hình ẩn danh hóa theo phiên bản (FR-09-035, BR-09-035, 036): k ≥ 10 (sàn 09.anon.k-min, SEC-38), l-đa dạng tùy chọn, quy tắc theo trường với AnonTransform, phân cấp tổng quát hóa, mục đích. Định danh trực tiếp bị loại, bán định danh được tổng quát hóa.';
COMMENT ON COLUMN ph09_privacy.anonymization_config.rules IS 'Mảng {field, transform, params}; transform là AnonTransform (kiểm ở dịch vụ khi gửi duyệt).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.anonymization_config CASCADE;

-- @changeset ph09-0430-anonymization-job
CREATE TABLE ph09_privacy.anonymization_job (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  config_id             uuid NOT NULL,
  source_ref            varchar(512) NOT NULL,
  purpose_code          varchar(41) NOT NULL,
  target                varchar(16),
  status                varchar(24) NOT NULL DEFAULT 'QUEUED',
  requested_by          varchar(64) NOT NULL,
  rows_before           bigint,
  rows_after            bigint,
  k_actual              smallint,
  generalization_rounds smallint NOT NULL DEFAULT 0,
  output_ref            varchar(512),
  started_at            timestamptz,
  finished_at           timestamptz,
  error_code            varchar(10),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymization_job PRIMARY KEY (id),
  CONSTRAINT uq_anonymization_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymization_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_anonymization_job_config FOREIGN KEY (tenant_id, config_id) REFERENCES ph09_privacy.anonymization_config (tenant_id, id),
  CONSTRAINT fk_anonymization_job_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymization_job_target CHECK (target IS NULL OR target IN ('AI_TRAINING', 'NON_PROD_TEST', 'OPEN_DATA')),
  CONSTRAINT ck_anonymization_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'AWAITING_RISK_REVIEW', 'COMPLETED', 'REJECTED_RISK', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_anonymization_job_rows CHECK (rows_before >= 0 AND rows_after >= 0 AND rows_after <= rows_before),
  CONSTRAINT ck_anonymization_job_keep CHECK (rows_before IS NULL OR rows_before = 0 OR rows_after IS NULL OR rows_after * 10 >= rows_before * 3 OR status IN ('REJECTED_RISK', 'FAILED', 'CANCELLED', 'RUNNING', 'QUEUED')),
  CONSTRAINT ck_anonymization_job_rounds CHECK (generalization_rounds BETWEEN 0 AND 3),
  CONSTRAINT ck_anonymization_job_k CHECK (k_actual IS NULL OR k_actual >= 1),
  CONSTRAINT ck_anonymization_job_done CHECK (status NOT IN ('COMPLETED') OR (k_actual >= 10 AND output_ref IS NOT NULL AND finished_at IS NOT NULL)),
  CONSTRAINT ck_anonymization_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$')
);
CREATE INDEX ix_anonymization_job_status ON ph09_privacy.anonymization_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_anonymization_job_touch BEFORE UPDATE ON ph09_privacy.anonymization_job FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymization_job');
COMMENT ON TABLE ph09_privacy.anonymization_job IS 'EN-09-33 Job ẩn danh hóa (FR-09-036, 038, BR-09-034, 035): tập nguồn, cấu hình, trạng thái AnonJobStatus, số bản ghi trước và sau (còn ≥ 30%), k thực tế, tối đa 3 vòng tổng quát hóa. Không lưu ánh xạ, không giữ khóa giải. Tập ra ở Garage mã hóa SSE-C.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.anonymization_job CASCADE;

-- @changeset ph09-0440-risk-report
CREATE TABLE ph09_privacy.risk_report (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  job_id            uuid,
  dataset_ref       varchar(512) NOT NULL,
  risk_model        varchar(12) NOT NULL,
  quasi_identifiers varchar(63)[] NOT NULL,
  k_actual          smallint NOT NULL,
  small_group_ratio numeric(6,5) NOT NULL,
  risk_value        numeric(6,5) NOT NULL,
  level             varchar(8) NOT NULL,
  risk_fields       varchar(63)[] NOT NULL DEFAULT '{}',
  recommendation    varchar(2000),
  computed_at       timestamptz NOT NULL DEFAULT now(),
  approved_by       varchar(64),
  approved_at       timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_risk_report PRIMARY KEY (id),
  CONSTRAINT uq_risk_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_risk_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_risk_report_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph09_privacy.anonymization_job (tenant_id, id),
  CONSTRAINT ck_risk_report_model CHECK (risk_model IN ('PROSECUTOR', 'JOURNALIST', 'MARKETER')),
  CONSTRAINT ck_risk_report_level CHECK (level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_risk_report_ratio CHECK (small_group_ratio BETWEEN 0 AND 1 AND risk_value BETWEEN 0 AND 1 AND k_actual >= 1),
  CONSTRAINT ck_risk_report_approval CHECK ((approved_by IS NULL) = (approved_at IS NULL))
);
CREATE INDEX ix_risk_report_job ON ph09_privacy.risk_report (tenant_id, job_id, computed_at DESC);
CREATE TRIGGER tg_risk_report_touch BEFORE UPDATE ON ph09_privacy.risk_report FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.risk_report');
COMMENT ON TABLE ph09_privacy.risk_report IS 'EN-09-34 Báo cáo rủi ro tái định danh (FR-09-037, BR-09-035): mô hình RiskModel, kActual, tỷ lệ nhóm nhỏ, mức RiskLevel (MEDIUM từ 0,05, HIGH từ 0,10 mặc định), trường gây rủi ro, khuyến nghị. Mức MEDIUM cần SO duyệt trước khi phát hành.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.risk_report CASCADE;

-- @changeset ph09-0450-anonymized-dataset
CREATE TABLE ph09_privacy.anonymized_dataset (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  job_id          uuid NOT NULL,
  risk_report_id  uuid NOT NULL,
  name            varchar(255) NOT NULL,
  storage_ref     varchar(512) NOT NULL,
  purpose_code    varchar(41) NOT NULL,
  target          varchar(16) NOT NULL,
  terms           jsonb NOT NULL,
  k_actual        smallint NOT NULL,
  risk_level      varchar(8) NOT NULL,
  approved_by     varchar(64),
  status          varchar(10) NOT NULL DEFAULT 'READY',
  expires_on      date,
  published_at    timestamptz,
  withdrawn_at    timestamptz,
  withdraw_reason varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymized_dataset PRIMARY KEY (id),
  CONSTRAINT uq_anonymized_dataset_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymized_dataset_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_anonymized_dataset_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph09_privacy.anonymization_job (tenant_id, id),
  CONSTRAINT fk_anonymized_dataset_risk_report FOREIGN KEY (tenant_id, risk_report_id) REFERENCES ph09_privacy.risk_report (tenant_id, id),
  CONSTRAINT fk_anonymized_dataset_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymized_dataset_target CHECK (target IN ('AI_TRAINING', 'NON_PROD_TEST', 'OPEN_DATA')),
  CONSTRAINT ck_anonymized_dataset_status CHECK (status IN ('READY', 'PUBLISHED', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_anonymized_dataset_risk CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_anonymized_dataset_terms CHECK (jsonb_typeof(terms) = 'object'),
  CONSTRAINT ck_anonymized_dataset_published CHECK (status <> 'PUBLISHED' OR (k_actual >= 10 AND risk_level <> 'HIGH' AND (risk_level <> 'MEDIUM' OR approved_by IS NOT NULL) AND published_at IS NOT NULL AND expires_on IS NOT NULL)),
  CONSTRAINT ck_anonymized_dataset_withdrawn CHECK (status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdraw_reason IS NOT NULL))
);
CREATE INDEX ix_anonymized_dataset_status ON ph09_privacy.anonymized_dataset (tenant_id, status, expires_on);
CREATE TRIGGER tg_anonymized_dataset_touch BEFORE UPDATE ON ph09_privacy.anonymized_dataset FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_anonymized_dataset_immutable BEFORE UPDATE ON ph09_privacy.anonymized_dataset FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('job_id', 'storage_ref', 'k_actual');
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymized_dataset');
COMMENT ON TABLE ph09_privacy.anonymized_dataset IS 'EN-09-35 Tập đã ẩn danh (FR-09-038, 039, BR-09-034, 035, 037): vị trí lưu, mục đích, điều kiện sử dụng (mục đích được phép, bên nhận, cấm tái định danh), hạn dùng, DatasetStatus. PUBLISHED cần k ≥ 10, rủi ro không HIGH, MEDIUM thì có người duyệt.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.anonymized_dataset CASCADE;


-- @file 09-0060-retention.sql
-- @changeset ph09-0460-retention-schedule
CREATE TABLE ph09_privacy.retention_schedule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  schedule_code    varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  description      varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_schedule PRIMARY KEY (id),
  CONSTRAINT uq_retention_schedule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_retention_schedule_code CHECK (schedule_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT uq_retention_schedule_version UNIQUE (tenant_id, schedule_code, version_no),
  CONSTRAINT ck_retention_schedule_version CHECK (version_no >= 1),
  CONSTRAINT ck_retention_schedule_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_retention_schedule_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_retention_schedule_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_retention_schedule_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_retention_schedule_active ON ph09_privacy.retention_schedule (tenant_id, schedule_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_retention_schedule_touch BEFORE UPDATE ON ph09_privacy.retention_schedule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_retention_schedule_immutable BEFORE UPDATE ON ph09_privacy.retention_schedule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('schedule_code', 'version_no');
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_schedule');
COMMENT ON TABLE ph09_privacy.retention_schedule IS 'EN-09-36 Lịch lưu giữ theo phiên bản (FR-09-040, BR-09-038): mỗi dòng ở retention_schedule_line. ACTIVE không sửa; duyệt bốn mắt. Chính sách lưu giữ của chính PH-09 là lịch PH09-OWN nạp sẵn (chương 7 của tập CSDL).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.retention_schedule CASCADE;

-- @changeset ph09-0470-retention-schedule-line
CREATE TABLE ph09_privacy.retention_schedule_line (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  schedule_id uuid NOT NULL,
  entity      varchar(128) NOT NULL,
  category    varchar(32),
  retain_days integer NOT NULL,
  action      varchar(12) NOT NULL,
  owner       varchar(64) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_schedule_line PRIMARY KEY (id),
  CONSTRAINT uq_retention_schedule_line_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_schedule_line_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_retention_schedule_line_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph09_privacy.retention_schedule (tenant_id, id),
  CONSTRAINT ck_retention_schedule_line_days CHECK (retain_days BETWEEN 1 AND 36500),
  CONSTRAINT ck_retention_schedule_line_action CHECK (action IN ('DELETE', 'PSEUDONYMIZE', 'ANONYMIZE', 'ARCHIVE'))
);
CREATE UNIQUE INDEX uq_retention_schedule_line ON ph09_privacy.retention_schedule_line (tenant_id, schedule_id, entity, COALESCE(category, '*'));
CREATE TRIGGER tg_retention_schedule_line_touch BEFORE UPDATE ON ph09_privacy.retention_schedule_line FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_retention_schedule_line_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.retention_schedule_line FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('retention_schedule', 'schedule_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_schedule_line');
COMMENT ON TABLE ph09_privacy.retention_schedule_line IS 'EN-09-53 Dòng lịch lưu giữ, bảng con của RetentionSchedule (FR-09-040): bảng hoặc loại dữ liệu, loại DLCN, số ngày lưu, hành động RetentionAction, người chịu trách nhiệm. Nhật ký kiểm toán WORM không thuộc lịch này (BR-09-038). Chỉ sửa khi lịch DRAFT hoặc REJECTED.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.retention_schedule_line CASCADE;

-- @changeset ph09-0480-retention-task
CREATE TABLE ph09_privacy.retention_task (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  schedule_id       uuid NOT NULL,
  line_id           uuid,
  entity            varchar(128) NOT NULL,
  run_date          date NOT NULL,
  dry_run           boolean NOT NULL DEFAULT false,
  status            varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_by      varchar(64) NOT NULL,
  started_at        timestamptz,
  finished_at       timestamptz,
  rows_scanned      bigint NOT NULL DEFAULT 0,
  rows_affected     bigint NOT NULL DEFAULT 0,
  rows_skipped_hold bigint NOT NULL DEFAULT 0,
  hold_ids          uuid[] NOT NULL DEFAULT '{}',
  skipped_reason    varchar(2000),
  error_code        varchar(10),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_task PRIMARY KEY (id),
  CONSTRAINT uq_retention_task_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_retention_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_retention_task_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph09_privacy.retention_schedule (tenant_id, id),
  CONSTRAINT fk_retention_task_line FOREIGN KEY (tenant_id, line_id) REFERENCES ph09_privacy.retention_schedule_line (tenant_id, id),
  CONSTRAINT ck_retention_task_status CHECK (status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_retention_task_rows CHECK (rows_scanned >= 0 AND rows_affected >= 0 AND rows_skipped_hold >= 0 AND rows_affected + rows_skipped_hold <= rows_scanned),
  CONSTRAINT ck_retention_task_hold CHECK (rows_skipped_hold = 0 OR cardinality(hold_ids) >= 1),
  CONSTRAINT ck_retention_task_finished CHECK (status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_retention_task_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$')
);
CREATE UNIQUE INDEX uq_retention_task_run ON ph09_privacy.retention_task (tenant_id, schedule_id, COALESCE(line_id, '00000000-0000-0000-0000-000000000000'::uuid), run_date) WHERE NOT dry_run;
CREATE INDEX ix_retention_task_status ON ph09_privacy.retention_task (tenant_id, status, run_date DESC);
CREATE TRIGGER tg_retention_task_touch BEFORE UPDATE ON ph09_privacy.retention_task FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.retention_task');
COMMENT ON TABLE ph09_privacy.retention_task IS 'EN-09-37 Tác vụ xóa hoặc giả danh hóa khi hết hạn (FR-09-041, 044, NFR-09-018): phạm vi, số bản ghi quét, xử lý, bỏ qua do giữ pháp lý (kèm hold_ids), kết quả. Chạy lại không nhân bản (khóa schedule_id, line_id, run_date).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.retention_task CASCADE;

-- @changeset ph09-0490-legal-hold
CREATE TABLE ph09_privacy.legal_hold (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  scope          jsonb NOT NULL,
  basis_doc      varchar(255) NOT NULL,
  basis_date     date NOT NULL,
  authority      varchar(255) NOT NULL,
  review_on      date NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'ACTIVE',
  placed_by      varchar(64) NOT NULL,
  released_by    varchar(64),
  released_at    timestamptz,
  release_reason varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_hold PRIMARY KEY (id),
  CONSTRAINT uq_legal_hold_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_hold_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legal_hold_scope CHECK (jsonb_typeof(scope) = 'object'),
  CONSTRAINT ck_legal_hold_status CHECK (status IN ('ACTIVE', 'RELEASED')),
  CONSTRAINT ck_legal_hold_review CHECK (review_on >= basis_date),
  CONSTRAINT ck_legal_hold_released CHECK ((status = 'RELEASED') = (released_by IS NOT NULL AND released_at IS NOT NULL AND release_reason IS NOT NULL))
);
CREATE INDEX ix_legal_hold_active ON ph09_privacy.legal_hold (tenant_id, review_on) WHERE status = 'ACTIVE';
CREATE INDEX ix_legal_hold_scope ON ph09_privacy.legal_hold USING gin (scope jsonb_path_ops) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_legal_hold_touch BEFORE UPDATE ON ph09_privacy.legal_hold FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_hold_immutable BEFORE UPDATE ON ph09_privacy.legal_hold FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('scope', 'basis_doc', 'basis_date', 'authority', 'placed_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_hold');
COMMENT ON TABLE ph09_privacy.legal_hold IS 'EN-09-38 Giữ pháp lý, tạm hoãn xóa (FR-09-042, BR-09-039): phạm vi (băm chủ thể, bảng, khoảng thời gian), số văn bản, cơ quan, ngày rà soát, LegalHoldStatus. Chặn mọi tác vụ xóa liên quan (ERR-09-058). Gỡ do người có quyền, có kiểm toán.';
COMMENT ON COLUMN ph09_privacy.legal_hold.scope IS '{subjectHashes[], entities[], from, to}; chỉ băm chủ thể, không định danh rõ.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.legal_hold CASCADE;

-- @changeset ph09-0500-tenant-shred-request
CREATE TABLE ph09_privacy.tenant_shred_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'REQUESTED',
  export_confirmed boolean NOT NULL DEFAULT false,
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  approver_1       varchar(64),
  approver_2       varchar(64),
  approved_at      timestamptz,
  wait_until       timestamptz,
  executed_at      timestamptz,
  kek_destroy_ref  varchar(255),
  cancelled_by     varchar(64),
  cancelled_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_shred_request PRIMARY KEY (id),
  CONSTRAINT ck_tenant_shred_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_shred_request_status CHECK (status IN ('REQUESTED', 'APPROVED', 'WAITING', 'EXECUTED', 'CANCELLED')),
  CONSTRAINT ck_tenant_shred_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_tenant_shred_request_approvers CHECK (approver_1 IS NULL OR (approver_1 <> requested_by AND (approver_2 IS NULL OR (approver_2 <> approver_1 AND approver_2 <> requested_by)))),
  CONSTRAINT ck_tenant_shred_request_approved CHECK (status NOT IN ('APPROVED', 'WAITING', 'EXECUTED') OR (export_confirmed AND approver_1 IS NOT NULL AND approver_2 IS NOT NULL AND approved_at IS NOT NULL AND wait_until >= approved_at + interval '7 days')),
  CONSTRAINT ck_tenant_shred_request_executed CHECK (status <> 'EXECUTED' OR (executed_at IS NOT NULL AND executed_at >= wait_until AND kek_destroy_ref IS NOT NULL)),
  CONSTRAINT ck_tenant_shred_request_cancelled CHECK ((status = 'CANCELLED') = (cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_tenant_shred_request_open ON ph09_privacy.tenant_shred_request (tenant_id) WHERE status IN ('REQUESTED', 'APPROVED', 'WAITING');
CREATE TRIGGER tg_tenant_shred_request_touch BEFORE UPDATE ON ph09_privacy.tenant_shred_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_tenant_shred_request_immutable BEFORE UPDATE ON ph09_privacy.tenant_shred_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('requested_by', 'reason');
CALL ph09_privacy.p_enable_rls('ph09_privacy.tenant_shred_request');
COMMENT ON TABLE ph09_privacy.tenant_shred_request IS 'EN-09-39 Đề nghị xóa mật mã tenant, hủy KEK dh-{tenant}-pii (FR-09-043, BR-09-041, 033): chỉ sau bàn giao dữ liệu theo PH-20, hai người duyệt khác nhau và khác người đề nghị, chờ ≥ 7 ngày, không hoàn tác. Một đề nghị đang mở mỗi tenant.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.tenant_shred_request CASCADE;


-- @file 09-0070-dsr-consent.sql
-- @changeset ph09-0510-subject-request
CREATE TABLE ph09_privacy.subject_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  request_type          varchar(20) NOT NULL,
  status                varchar(12) NOT NULL DEFAULT 'RECEIVED',
  channel               varchar(16) NOT NULL,
  identifier_type       varchar(24) NOT NULL,
  subject_hash          bytea NOT NULL,
  identifier_enc        bytea NOT NULL,
  identifier_kid        varchar(64) NOT NULL,
  content_enc           bytea NOT NULL,
  content_kid           varchar(64) NOT NULL,
  idempotency_key       varchar(64) NOT NULL,
  received_at           timestamptz NOT NULL DEFAULT now(),
  due_at                timestamptz NOT NULL,
  overdue               boolean NOT NULL DEFAULT false,
  verified_at           timestamptz,
  assigned_to           varchar(64),
  outcome               varchar(10),
  refusal_basis         varchar(500),
  response_ref          varchar(512),
  responded_at          timestamptz,
  closed_at             timestamptz,
  reject_reason         varchar(2000),
  restriction_active    boolean NOT NULL DEFAULT false,
  restriction_lifted_at timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_request PRIMARY KEY (id),
  CONSTRAINT uq_subject_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_subject_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_subject_request_idem UNIQUE (tenant_id, idempotency_key),
  CONSTRAINT ck_subject_request_type CHECK (request_type IN ('ACCESS', 'RECTIFY', 'ERASE', 'RESTRICT', 'OBJECT', 'WITHDRAW_CONSENT', 'INFO')),
  CONSTRAINT ck_subject_request_status CHECK (status IN ('RECEIVED', 'VERIFYING', 'IN_PROGRESS', 'RESPONDED', 'CLOSED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT ck_subject_request_channel CHECK (channel IN ('PUBLIC_SERVICE', 'COUNTER', 'DOCUMENT', 'EMAIL')),
  CONSTRAINT ck_subject_request_idtype CHECK (identifier_type IN ('NATIONAL_ID', 'TAX_ID', 'SOCIAL_INSURANCE_ID', 'PHONE', 'EMAIL')),
  CONSTRAINT ck_subject_request_hash CHECK (octet_length(subject_hash) = 32),
  CONSTRAINT ck_subject_request_enc CHECK (octet_length(identifier_enc) >= 29 AND octet_length(content_enc) >= 29),
  CONSTRAINT ck_subject_request_due CHECK (due_at >= received_at),
  CONSTRAINT ck_subject_request_verified CHECK (status NOT IN ('IN_PROGRESS', 'RESPONDED', 'CLOSED') OR verified_at IS NOT NULL),
  CONSTRAINT ck_subject_request_outcome CHECK (outcome IS NULL OR outcome IN ('FULFILLED', 'PARTIAL', 'REFUSED')),
  CONSTRAINT ck_subject_request_responded CHECK (status NOT IN ('RESPONDED', 'CLOSED') OR (outcome IS NOT NULL AND responded_at IS NOT NULL)),
  CONSTRAINT ck_subject_request_refused CHECK (outcome IS DISTINCT FROM 'REFUSED' OR refusal_basis IS NOT NULL),
  CONSTRAINT ck_subject_request_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL)),
  CONSTRAINT ck_subject_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_subject_request_restriction CHECK (NOT restriction_active OR request_type = 'RESTRICT')
);
CREATE INDEX ix_subject_request_inbox ON ph09_privacy.subject_request (tenant_id, status, due_at);
CREATE INDEX ix_subject_request_subject ON ph09_privacy.subject_request (tenant_id, subject_hash);
CREATE INDEX ix_subject_request_restricted ON ph09_privacy.subject_request (tenant_id, subject_hash) WHERE restriction_active;
CREATE TRIGGER tg_subject_request_touch BEFORE UPDATE ON ph09_privacy.subject_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_subject_request_immutable BEFORE UPDATE ON ph09_privacy.subject_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_type', 'subject_hash', 'received_at', 'idempotency_key', 'identifier_enc');
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_request');
COMMENT ON TABLE ph09_privacy.subject_request IS 'EN-09-40 Yêu cầu của chủ thể dữ liệu (FR-09-045…050, BR-09-042…048, 061): loại DsrType, băm chủ thể HMAC theo khóa tenant, định danh và nội dung mã hóa envelope. Chưa xác minh thì không IN_PROGRESS (BR-09-042). Cờ overdue, cờ hạn chế xử lý; lưu 5 năm (BR-09-048); Idempotency-Key duy nhất.';
COMMENT ON COLUMN ph09_privacy.subject_request.subject_hash IS 'HMAC-SHA256 số định danh đã chuẩn hóa, khóa theo tenant (BR-09-045); tra bản ghi của chủ thể ở PH-06, PH-19, PH-13, PH-14.';
COMMENT ON COLUMN ph09_privacy.subject_request.identifier_enc IS 'Định danh rõ chỉ ở đây, mã hóa envelope (ADR-032).';
COMMENT ON COLUMN ph09_privacy.subject_request.content_enc IS 'Nội dung yêu cầu ≤ 4.000 ký tự, mã hóa envelope.';
COMMENT ON COLUMN ph09_privacy.subject_request.overdue IS 'Cờ, không phải trạng thái (FRS 4.5).';
COMMENT ON COLUMN ph09_privacy.subject_request.due_at IS 'Ngày làm việc theo 09.dsr.sla-days (Q09-02).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.subject_request CASCADE;

-- @changeset ph09-0520-subject-verification
CREATE TABLE ph09_privacy.subject_verification (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  request_id    uuid NOT NULL,
  method        varchar(20) NOT NULL,
  passed        boolean NOT NULL,
  evidence_hash bytea,
  evidence_ref  varchar(512),
  verified_by   varchar(64) NOT NULL,
  verified_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_verification PRIMARY KEY (id),
  CONSTRAINT ck_subject_verification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_subject_verification_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.subject_request (tenant_id, id),
  CONSTRAINT ck_subject_verification_method CHECK (method IN ('ID_DOCUMENT', 'OTP', 'VNEID', 'COUNTER_IN_PERSON')),
  CONSTRAINT ck_subject_verification_hash CHECK (evidence_hash IS NULL OR octet_length(evidence_hash) = 32),
  CONSTRAINT ck_subject_verification_evidence CHECK (NOT passed OR evidence_hash IS NOT NULL OR method IN ('VNEID', 'OTP'))
);
CREATE INDEX ix_subject_verification_request ON ph09_privacy.subject_verification (tenant_id, request_id, verified_at DESC);
CREATE TRIGGER tg_subject_verification_touch BEFORE UPDATE ON ph09_privacy.subject_verification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_subject_verification_immutable BEFORE UPDATE ON ph09_privacy.subject_verification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_id', 'method', 'passed');
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_verification');
COMMENT ON TABLE ph09_privacy.subject_verification IS 'EN-09-41 Kết quả xác minh danh tính chủ thể (FR-09-046, BR-09-042): phương pháp VerificationMethod, đạt hoặc không, bằng chứng chỉ lưu băm và tham chiếu Garage mã hóa. Người xác minh khác người nhận yêu cầu (kiểm ở dịch vụ).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.subject_verification CASCADE;

-- @changeset ph09-0530-subject-task
CREATE TABLE ph09_privacy.subject_task (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  request_id     uuid NOT NULL,
  target         varchar(16) NOT NULL,
  action         varchar(20) NOT NULL,
  status         varchar(10) NOT NULL DEFAULT 'OPEN',
  assignee       varchar(64),
  external_ref   varchar(255),
  result         jsonb,
  refusal_reason varchar(2000),
  done_at        timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_task PRIMARY KEY (id),
  CONSTRAINT ck_subject_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_subject_task_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.subject_request (tenant_id, id),
  CONSTRAINT ck_subject_task_target CHECK (target IN ('PH06_MASTER', 'PH19_PAYMENT', 'CONTROLLER', 'MANUAL')),
  CONSTRAINT ck_subject_task_action CHECK (action IN ('ACCESS', 'RECTIFY', 'ERASE', 'RESTRICT', 'OBJECT', 'WITHDRAW_CONSENT', 'INFO')),
  CONSTRAINT ck_subject_task_status CHECK (status IN ('OPEN', 'DONE', 'REFUSED', 'CANCELLED')),
  CONSTRAINT ck_subject_task_refused CHECK (status <> 'REFUSED' OR refusal_reason IS NOT NULL),
  CONSTRAINT ck_subject_task_done CHECK (status = 'OPEN' OR done_at IS NOT NULL)
);
CREATE INDEX ix_subject_task_request ON ph09_privacy.subject_task (tenant_id, request_id, status);
CREATE INDEX ix_subject_task_open ON ph09_privacy.subject_task (tenant_id, target, created_at) WHERE status = 'OPEN';
CREATE TRIGGER tg_subject_task_touch BEFORE UPDATE ON ph09_privacy.subject_task FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.subject_task');
COMMENT ON TABLE ph09_privacy.subject_task IS 'EN-09-42 Tác vụ chuyển cho PH-06, PH-19, PH-13, PH-14 hoặc bên kiểm soát (FR-09-047, 048, BR-09-044, 046): đích DsrTarget, hành động theo DsrType, DsrTaskStatus. Kết quả chỉ số lượng và tham chiếu, không giá trị. Dữ liệu đi qua chuyển cho bên kiểm soát.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.subject_task CASCADE;

-- @changeset ph09-0540-consent-template
CREATE TABLE ph09_privacy.consent_template (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  template_code    varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  purpose_code     varchar(41) NOT NULL,
  data_scope       varchar(2000) NOT NULL,
  body_text        varchar(20000) NOT NULL,
  valid_days       integer,
  withdrawal_guide varchar(2000) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_consent_template PRIMARY KEY (id),
  CONSTRAINT uq_consent_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_consent_template_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_consent_template_code CHECK (template_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_consent_template_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_consent_template_valid CHECK (valid_days IS NULL OR valid_days BETWEEN 1 AND 3650),
  CONSTRAINT ck_consent_template_body CHECK (char_length(body_text) >= 20),
  CONSTRAINT uq_consent_template_version UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_consent_template_version CHECK (version_no >= 1),
  CONSTRAINT ck_consent_template_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_consent_template_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_consent_template_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_consent_template_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_consent_template_active ON ph09_privacy.consent_template (tenant_id, template_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_consent_template_touch BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_consent_template_immutable BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('template_code', 'version_no');
CREATE TRIGGER tg_consent_template_frozen BEFORE UPDATE ON ph09_privacy.consent_template FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('purpose_code', 'data_scope', 'body_text', 'valid_days', 'withdrawal_guide');
CALL ph09_privacy.p_enable_rls('ph09_privacy.consent_template');
COMMENT ON TABLE ph09_privacy.consent_template IS 'EN-09-43 Mẫu sự đồng ý theo phiên bản (FR-09-052, BR-09-049): nội dung, mục đích, dữ liệu xử lý, hạn hiệu lực, cách rút. Nội dung bất biến khi ACTIVE. Đồng ý chỉ là cơ sở cho tiện ích không bắt buộc, không là điều kiện của thủ tục hành chính.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.consent_template CASCADE;

-- @changeset ph09-0550-consent-record
CREATE TABLE ph09_privacy.consent_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  template_id       uuid NOT NULL,
  template_code     varchar(41) NOT NULL,
  template_version  integer NOT NULL,
  subject_hash      bytea NOT NULL,
  status            varchar(10) NOT NULL DEFAULT 'GIVEN',
  channel           varchar(10) NOT NULL,
  text_hash         bytea NOT NULL,
  given_at          timestamptz NOT NULL DEFAULT now(),
  evidence          jsonb NOT NULL DEFAULT '{}',
  recorded_by       varchar(64) NOT NULL,
  expires_at        timestamptz,
  withdrawn_at      timestamptz,
  withdrawn_channel varchar(10),
  withdrawn_by      varchar(64),
  withdraw_evidence jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_consent_record PRIMARY KEY (id),
  CONSTRAINT uq_consent_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_consent_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_consent_record_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph09_privacy.consent_template (tenant_id, id),
  CONSTRAINT ck_consent_record_status CHECK (status IN ('GIVEN', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_consent_record_channel CHECK (channel IN ('WEB', 'APP', 'COUNTER', 'DOCUMENT') AND (withdrawn_channel IS NULL OR withdrawn_channel IN ('WEB', 'APP', 'COUNTER', 'DOCUMENT'))),
  CONSTRAINT ck_consent_record_hash CHECK (octet_length(subject_hash) = 32 AND octet_length(text_hash) = 32),
  CONSTRAINT ck_consent_record_withdrawn CHECK ((status = 'WITHDRAWN') = (withdrawn_at IS NOT NULL AND withdrawn_channel IS NOT NULL AND withdrawn_by IS NOT NULL) AND (withdrawn_at IS NULL OR withdrawn_at >= given_at)),
  CONSTRAINT ck_consent_record_expired CHECK (status <> 'EXPIRED' OR (expires_at IS NOT NULL AND expires_at <= now() + interval '1 minute'))
);
CREATE UNIQUE INDEX uq_consent_record_given ON ph09_privacy.consent_record (tenant_id, template_code, subject_hash) WHERE status = 'GIVEN';
CREATE INDEX ix_consent_record_subject ON ph09_privacy.consent_record (tenant_id, subject_hash, given_at DESC);
CREATE TRIGGER tg_consent_record_touch BEFORE UPDATE ON ph09_privacy.consent_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_consent_record_immutable BEFORE UPDATE ON ph09_privacy.consent_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('template_id', 'template_code', 'template_version', 'subject_hash', 'text_hash', 'given_at', 'channel', 'recorded_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.consent_record');
COMMENT ON TABLE ph09_privacy.consent_record IS 'EN-09-44 Bản ghi đồng ý hoặc rút (FR-09-053, 054, BR-09-050, 051): băm chủ thể, mẫu và phiên bản, băm nội dung đã hiển thị, kênh, thời điểm, bằng chứng; rút ghi trên cùng dòng (withdrawn_*) và có hiệu lực trong 60 giây. Một đồng ý GIVEN mỗi (chủ thể, mẫu). Không xóa.';
COMMENT ON COLUMN ph09_privacy.consent_record.text_hash IS 'Băm nội dung mẫu đã hiển thị cho chủ thể (bằng chứng, BR-09-050).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.consent_record CASCADE;


-- @file 09-0080-dpia-breach.sql
-- @changeset ph09-0560-dpia-record
CREATE TABLE ph09_privacy.dpia_record (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  dpia_code        varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  activity_id      uuid NOT NULL,
  dpia_kind        varchar(16) NOT NULL,
  description      varchar(4000) NOT NULL,
  risks            jsonb NOT NULL,
  measures         jsonb NOT NULL,
  review_on        date NOT NULL,
  submitted_a05_at timestamptz,
  a05_ref          varchar(128),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dpia_record PRIMARY KEY (id),
  CONSTRAINT uq_dpia_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dpia_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dpia_record_code CHECK (dpia_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_dpia_record_activity FOREIGN KEY (tenant_id, activity_id) REFERENCES ph09_privacy.processing_activity (tenant_id, id),
  CONSTRAINT ck_dpia_record_kind CHECK (dpia_kind IN ('PROCESSING', 'CROSS_BORDER')),
  CONSTRAINT ck_dpia_record_risks CHECK (jsonb_typeof(risks) = 'array' AND jsonb_array_length(risks) >= 1 AND jsonb_typeof(measures) = 'array' AND jsonb_array_length(measures) >= 1),
  CONSTRAINT ck_dpia_record_a05 CHECK ((status = 'SUBMITTED_A05') = (submitted_a05_at IS NOT NULL)),
  CONSTRAINT uq_dpia_record_version UNIQUE (tenant_id, dpia_code, version_no),
  CONSTRAINT ck_dpia_record_version CHECK (version_no >= 1),
  CONSTRAINT ck_dpia_record_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED', 'SUBMITTED_A05')),
  CONSTRAINT ck_dpia_record_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_dpia_record_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_dpia_record_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_dpia_record_active ON ph09_privacy.dpia_record (tenant_id, dpia_code) WHERE status = 'ACTIVE';
CREATE INDEX ix_dpia_record_review ON ph09_privacy.dpia_record (tenant_id, review_on) WHERE status IN ('ACTIVE', 'SUBMITTED_A05');
CREATE TRIGGER tg_dpia_record_touch BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_dpia_record_immutable BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('dpia_code', 'version_no', 'activity_id');
CREATE TRIGGER tg_dpia_record_frozen BEFORE UPDATE ON ph09_privacy.dpia_record FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('dpia_kind', 'description', 'risks', 'measures', 'review_on');
CALL ph09_privacy.p_enable_rls('ph09_privacy.dpia_record');
COMMENT ON TABLE ph09_privacy.dpia_record IS 'EN-09-45 Hồ sơ đánh giá tác động xử lý DLCN theo phiên bản (FR-09-055…057, BR-09-052, 053): DpiaKind, hoạt động liên kết, rủi ro, biện pháp, hạn rà soát ≤ 12 tháng; trạng thái DpiaStatus gồm SUBMITTED_A05 khi đã gửi Cục A05. Nhắc trước 30 ngày.';
COMMENT ON COLUMN ph09_privacy.dpia_record.status IS 'VersionStatus cộng SUBMITTED_A05 (Phụ lục A, DpiaStatus).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.dpia_record CASCADE;

-- @changeset ph09-0570-breach-case
CREATE TABLE ph09_privacy.breach_case (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  detected_at            timestamptz NOT NULL,
  deadline_at            timestamptz NOT NULL,
  source                 varchar(16) NOT NULL,
  description            varchar(4000) NOT NULL,
  data_types             varchar(32)[] NOT NULL,
  estimated_subjects     integer,
  incident_ref           varchar(64),
  status                 varchar(12) NOT NULL DEFAULT 'REPORTED',
  severity               varchar(8),
  reported_by            varchar(64) NOT NULL,
  assessed_by            varchar(64),
  assessed_at            timestamptz,
  notified_a05_at        timestamptz,
  exempt_basis           varchar(2000),
  not_breach_reason      varchar(2000),
  not_breach_approved_by varchar(64),
  affected_ref           varchar(512),
  affected_count         integer,
  lessons                varchar(4000),
  closed_at              timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_case PRIMARY KEY (id),
  CONSTRAINT uq_breach_case_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_breach_case_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_breach_case_source CHECK (source IN ('PERSON', 'INCIDENT_PH18', 'AUDIT_PH13', 'ANOMALY')),
  CONSTRAINT ck_breach_case_status CHECK (status IN ('REPORTED', 'ASSESSING', 'NOT_A_BREACH', 'NOTIFYING', 'NOTIFIED', 'REMEDIATING', 'CLOSED')),
  CONSTRAINT ck_breach_case_severity CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_breach_case_types CHECK (cardinality(data_types) >= 1 AND data_types <@ ARRAY['FULL_NAME', 'DATE_OF_BIRTH', 'GENDER', 'NATIONAL_ID', 'PHONE', 'EMAIL', 'ADDRESS', 'TAX_ID', 'SOCIAL_INSURANCE_ID', 'HEALTH', 'BIOMETRIC', 'GENETIC', 'POLITICAL_RELIGIOUS', 'CRIMINAL_RECORD', 'FINANCIAL_ACCOUNT', 'LOCATION_TRACKING', 'MINOR', 'ETHNICITY']::varchar[]),
  CONSTRAINT ck_breach_case_clock CHECK (deadline_at = detected_at + interval '72 hours'),
  CONSTRAINT ck_breach_case_counts CHECK ((estimated_subjects IS NULL OR estimated_subjects >= 0) AND (affected_count IS NULL OR affected_count >= 0)),
  CONSTRAINT ck_breach_case_assessed CHECK (status IN ('REPORTED', 'ASSESSING') OR (assessed_by IS NOT NULL AND assessed_at IS NOT NULL)),
  CONSTRAINT ck_breach_case_notified CHECK (status NOT IN ('NOTIFIED', 'REMEDIATING', 'CLOSED') OR notified_a05_at IS NOT NULL OR exempt_basis IS NOT NULL),
  CONSTRAINT ck_breach_case_not_breach CHECK (status <> 'NOT_A_BREACH' OR (COALESCE(char_length(not_breach_reason) >= 20, false) AND not_breach_approved_by IS NOT NULL AND not_breach_approved_by <> assessed_by)),
  CONSTRAINT ck_breach_case_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL))
);
CREATE INDEX ix_breach_case_open ON ph09_privacy.breach_case (tenant_id, deadline_at) WHERE status NOT IN ('NOT_A_BREACH', 'CLOSED') AND notified_a05_at IS NULL;
CREATE INDEX ix_breach_case_detected ON ph09_privacy.breach_case (tenant_id, detected_at DESC);
CREATE TRIGGER tg_breach_case_touch BEFORE UPDATE ON ph09_privacy.breach_case FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_breach_case_immutable BEFORE UPDATE ON ph09_privacy.breach_case FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('detected_at', 'deadline_at', 'reported_by', 'source');
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_case');
COMMENT ON TABLE ph09_privacy.breach_case IS 'EN-09-46 Vụ việc vi phạm DLCN (FR-09-058…060, BR-09-054…056): BreachSource, BreachStatus, BreachSeverity, đồng hồ 72 giờ từ detected_at không dừng, hạn deadline_at cố định. Thông báo A05 hoặc căn cứ miễn trừ trước khi NOTIFIED trở đi; NOT_A_BREACH cần SO duyệt. Không chứa giá trị DLCN, chỉ số lượng, loại, băm.';
COMMENT ON COLUMN ph09_privacy.breach_case.affected_ref IS 'Danh sách băm chủ thể bị ảnh hưởng, tệp mã hóa ở Garage; không giữ định danh rõ (BR-09-056).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.breach_case CASCADE;

-- @changeset ph09-0580-breach-notification
CREATE TABLE ph09_privacy.breach_notification (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  case_id       uuid NOT NULL,
  recipient     varchar(12) NOT NULL,
  status        varchar(6) NOT NULL DEFAULT 'DRAFT',
  content       varchar(20000) NOT NULL,
  sent_at       timestamptz,
  sent_by       varchar(64),
  evidence_ref  varchar(512),
  evidence_hash bytea,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_notification PRIMARY KEY (id),
  CONSTRAINT ck_breach_notification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_breach_notification_case FOREIGN KEY (tenant_id, case_id) REFERENCES ph09_privacy.breach_case (tenant_id, id),
  CONSTRAINT ck_breach_notification_recipient CHECK (recipient IN ('A05', 'SUBJECT', 'CONTROLLER')),
  CONSTRAINT ck_breach_notification_status CHECK (status IN ('DRAFT', 'SENT')),
  CONSTRAINT ck_breach_notification_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL AND sent_by IS NOT NULL AND evidence_ref IS NOT NULL)),
  CONSTRAINT ck_breach_notification_hash CHECK (evidence_hash IS NULL OR octet_length(evidence_hash) = 32)
);
CREATE INDEX ix_breach_notification_case ON ph09_privacy.breach_notification (tenant_id, case_id, recipient);
CREATE TRIGGER tg_breach_notification_touch BEFORE UPDATE ON ph09_privacy.breach_notification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_notification');
COMMENT ON TABLE ph09_privacy.breach_notification IS 'EN-09-47 Thông báo vi phạm cho Cục A05, chủ thể hoặc bên kiểm soát (FR-09-059, BR-09-055): NotificationRecipient, nội dung không chứa DLCN, trạng thái NotificationStatus, bằng chứng gửi (băm và tham chiếu).';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.breach_notification CASCADE;

-- @changeset ph09-0590-breach-action
CREATE TABLE ph09_privacy.breach_action (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  case_id     uuid NOT NULL,
  is_lesson   boolean NOT NULL DEFAULT false,
  description varchar(2000) NOT NULL,
  owner       varchar(64) NOT NULL,
  due_on      date,
  done_at     timestamptz,
  result      varchar(2000),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_breach_action PRIMARY KEY (id),
  CONSTRAINT ck_breach_action_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_breach_action_case FOREIGN KEY (tenant_id, case_id) REFERENCES ph09_privacy.breach_case (tenant_id, id),
  CONSTRAINT ck_breach_action_lesson CHECK (NOT is_lesson OR (due_on IS NULL AND owner <> ''))
);
CREATE INDEX ix_breach_action_case ON ph09_privacy.breach_action (tenant_id, case_id);
CREATE TRIGGER tg_breach_action_touch BEFORE UPDATE ON ph09_privacy.breach_action FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.breach_action');
COMMENT ON TABLE ph09_privacy.breach_action IS 'EN-09-48 Biện pháp khắc phục và bài học của vụ việc (FR-09-060): người phụ trách, hạn, kết quả; is_lesson phân biệt bài học với biện pháp. Hoàn thành ghi done_at.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.breach_action CASCADE;


-- @file 09-0090-ops.sql
-- @changeset ph09-0600-privacy-audit-event
CREATE TABLE ph09_privacy.privacy_audit_event (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  actor        varchar(64) NOT NULL,
  action       varchar(64) NOT NULL,
  target_kind  varchar(32) NOT NULL,
  target_id    varchar(128),
  api_code     varchar(10),
  success      boolean NOT NULL,
  privileged   boolean NOT NULL DEFAULT false,
  details      jsonb,
  trace_id     char(32) NOT NULL,
  audit_ref    varchar(64),
  forwarded_at timestamptz,
  CONSTRAINT pk_privacy_audit_event PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_privacy_audit_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_privacy_audit_event_api CHECK (api_code IS NULL OR api_code ~ '^API-09-[0-9]{3}$'),
  CONSTRAINT ck_privacy_audit_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_privacy_audit_event_no_value CHECK (details IS NULL OR NOT (details ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'plaintext', 'token', 'tokens'])),
  CONSTRAINT ck_privacy_audit_event_forwarded CHECK (forwarded_at IS NULL OR audit_ref IS NOT NULL)
) PARTITION BY RANGE (occurred_at);
CALL ph09_privacy.p_ensure_partitions('ph09_privacy.privacy_audit_event', current_date, 3);
CREATE INDEX ix_privacy_audit_event_actor ON ph09_privacy.privacy_audit_event (tenant_id, actor, occurred_at DESC);
CREATE INDEX ix_privacy_audit_event_target ON ph09_privacy.privacy_audit_event (tenant_id, target_kind, target_id, occurred_at DESC);
CREATE INDEX ix_privacy_audit_event_pending ON ph09_privacy.privacy_audit_event (tenant_id, occurred_at) WHERE forwarded_at IS NULL;
CREATE TRIGGER tg_privacy_audit_event_append_only BEFORE UPDATE OR DELETE ON ph09_privacy.privacy_audit_event FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_append_only();
CALL ph09_privacy.p_enable_rls('ph09_privacy.privacy_audit_event');
COMMENT ON TABLE ph09_privacy.privacy_audit_event IS 'EN-09-49 Chỉ mục kiểm toán thao tác bảo vệ dữ liệu (FR-09-061, BR-09-057, 058, NFR-09-013): ai, thao tác, đối tượng, API-09, kết quả; chuyển bản ghi đầy đủ sang PH-13 (forwarded_at). Không ghi giá trị SENSITIVE. Chỉ thêm; phân vùng tháng; 13 tháng trực tuyến, bản gốc ở WORM của PH-13.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.privacy_audit_event CASCADE;

-- @changeset ph09-0610-compliance-report
CREATE TABLE ph09_privacy.compliance_report (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  period_from   date NOT NULL,
  period_to     date NOT NULL,
  sections      varchar(32)[] NOT NULL,
  report_format varchar(8) NOT NULL,
  metrics       jsonb NOT NULL,
  file_ref      varchar(512),
  file_sha256   char(64),
  generated_by  varchar(64) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compliance_report PRIMARY KEY (id),
  CONSTRAINT ck_compliance_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_compliance_report_period CHECK (period_to >= period_from),
  CONSTRAINT ck_compliance_report_format CHECK (report_format IN ('PDF', 'XLSX', 'DOCX')),
  CONSTRAINT ck_compliance_report_sections CHECK (cardinality(sections) >= 1),
  CONSTRAINT ck_compliance_report_sha CHECK (file_sha256 IS NULL OR file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_compliance_report_file CHECK ((file_ref IS NULL) = (file_sha256 IS NULL))
);
CREATE INDEX ix_compliance_report_period ON ph09_privacy.compliance_report (tenant_id, period_to DESC);
CREATE TRIGGER tg_compliance_report_touch BEFORE UPDATE ON ph09_privacy.compliance_report FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.compliance_report');
COMMENT ON TABLE ph09_privacy.compliance_report IS 'EN-09-50 Báo cáo tuân thủ theo kỳ (FR-09-062, 063): kỳ, các mục, chỉ số, tệp (Garage) và băm. Lập tự động theo 09.report.schedule-cron hoặc theo yêu cầu.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.compliance_report CASCADE;

-- @changeset ph09-0620-tenant-setting
CREATE TABLE ph09_privacy.tenant_setting (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  setting_key   varchar(48) NOT NULL,
  value         jsonb NOT NULL,
  floor_value   jsonb,
  ceiling_value jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('09.scan.sample-rows', '09.scan.schedule-cron', '09.scan.confidence', '09.request.sla-days', '09.grant.max-days', '09.grant.renew-max', '09.grant.expiring-notice-days', '09.grant.require-restricted', '09.bundle.debounce-seconds', '09.bundle.valid-minutes', '09.plan.cache-seconds', '09.consent.cache-seconds', '09.decision.cache-seconds', '09.feature.dsr-ph11', '09.feature.l-diversity', '09.feature.auto-confirm-mvp', '09.api.rate-user-per-min', '09.api.rate-du-per-sec', '09.anomaly.quota-warn-percent', '09.anomaly.bulk-threshold', '09.anomaly.auto-suspend', '09.mask.reveal-seconds', '09.mask.reveal-max-per-hour', '09.mask.reveal-alert-per-hour', '09.log.scan-cron', '09.pseudo.key-rotate-days', '09.pseudo.min-rotate-days', '09.pseudo.destroy-delay-days', '09.reid.approval-ttl-hours', '09.reid.exec-window-minutes', '09.anon.k-min', '09.anon.risk-medium-above', '09.anon.risk-high-above', '09.ai.allow-restricted', '09.retention.run-cron', '09.retention.overdue-days', '09.shred.delay-days', '09.dsr.sla-days', '09.dsr.remind-days', '09.breach.alert-hours', '09.dpia.review-months', '09.audit.query-max-days', '09.report.schedule-cron')),
  CONSTRAINT ck_tenant_setting_bounds CHECK (jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value)))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph09_privacy.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph09_privacy.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('setting_key');
CALL ph09_privacy.p_enable_rls('ph09_privacy.tenant_setting');
COMMENT ON TABLE ph09_privacy.tenant_setting IS 'EN-09-51 Tham số 09.* của tenant (FR-09-064, FRS 8.2, BR-09-059): khóa, giá trị jsonb, sàn và trần do PA đặt, người sửa là updated_by. Miền hợp lệ kiểm ở dịch vụ (ERR-09-078); CHECK giữ danh sách khóa và buộc giá trị số nằm trong sàn, trần.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.tenant_setting CASCADE;

-- @changeset ph09-0630-outbox-event
CREATE TABLE ph09_privacy.outbox_event (
  event_id       uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('privacy.classification.changed.v1', 'privacy.classification.scan-finished.v1', 'privacy.contract-level.changed.v1', 'privacy.activity.activated.v1', 'privacy.purpose-request.submitted.v1', 'privacy.purpose-grant.approved.v1', 'privacy.purpose-grant.suspended.v1', 'privacy.purpose-grant.revoked.v1', 'privacy.purpose-grant.expired.v1', 'privacy.purpose-grant.expiring.v1', 'privacy.bundle.published.v1', 'privacy.mask-policy.activated.v1', 'privacy.usage.anomaly-detected.v1', 'privacy.secret-label.blocked.v1', 'privacy.reveal.granted.v1', 'privacy.pseudonym-key.state-changed.v1', 'privacy.reidentification.executed.v1', 'privacy.dataset.status-changed.v1', 'privacy.retention.task-finished.v1', 'privacy.legal-hold.changed.v1', 'privacy.crypto-shred.completed.v1', 'privacy.dsr.received.v1', 'privacy.dsr.due-soon.v1', 'privacy.dsr.overdue.v1', 'privacy.dsr.closed.v1', 'privacy.dsr.restriction-changed.v1', 'privacy.consent.given.v1', 'privacy.consent.withdrawn.v1', 'privacy.dpia.review-due.v1', 'privacy.breach.recorded.v1', 'privacy.breach.deadline-near.v1', 'privacy.breach.notified.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'fullName', 'nationalId', 'phone', 'email', 'token', 'tokens', 'subjectIdentifier']))
);
CREATE INDEX ix_outbox_event_occurred ON ph09_privacy.outbox_event (occurred_at);
CALL ph09_privacy.p_enable_rls('ph09_privacy.outbox_event');
COMMENT ON TABLE ph09_privacy.outbox_event IS 'EN-09-54 Outbox (DD-11, ADR-042) cho EVT-09-01…32 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện không mang giá trị DLCN (BR-09-025): CHECK chặn khóa giá trị và định danh. Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.outbox_event CASCADE;

-- @changeset ph09-0640-inbox-event
CREATE TABLE ph09_privacy.inbox_event (
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     varchar(255) NOT NULL,
  source_topic varchar(249) NOT NULL,
  event_type   varchar(255) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  outcome      varchar(2000),
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph09_privacy.inbox_event (received_at);
CALL ph09_privacy.p_enable_rls('ph09_privacy.inbox_event');
COMMENT ON TABLE ph09_privacy.inbox_event IS 'EN-09-55 Inbox chống xử lý trùng cho sự kiện PH-09 tiêu thụ (at-least-once): đổi phân loại từ PH-06 (FR-06-004), sự kiện đăng ký HTTT PH-02, báo lượt khai thác PH-14, sự cố PH-18. Khóa (consumer, event_id). Dọn sau 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph09_privacy.inbox_event CASCADE;

-- @file 09-0900-grants.sql
-- @changeset ph09-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph09_privacy TO ph09_app;
-- Đối tượng nghiệp vụ không xóa cứng (nhãn, phân loại, hoạt động, chấp thuận, chính sách, khóa, yêu cầu chủ thể, đồng ý, vi phạm): chỉ dọn bảng tạm, bảng con DRAFT, bảng theo lịch lưu giữ.
REVOKE DELETE ON ph09_privacy.data_class, ph09_privacy.block_label, ph09_privacy.personal_data_category, ph09_privacy.data_element, ph09_privacy.element_classification, ph09_privacy.classification_change, ph09_privacy.detector_rule, ph09_privacy.contract_level, ph09_privacy.legal_document, ph09_privacy.legal_basis, ph09_privacy.processing_activity, ph09_privacy.purpose, ph09_privacy.access_request, ph09_privacy.purpose_grant, ph09_privacy.usage_anomaly, ph09_privacy.mask_type, ph09_privacy.mask_policy, ph09_privacy.log_mask_config, ph09_privacy.pseudonym_domain, ph09_privacy.pseudonym_key, ph09_privacy.reidentification_request, ph09_privacy.anonymization_config, ph09_privacy.anonymization_job, ph09_privacy.risk_report, ph09_privacy.anonymized_dataset, ph09_privacy.retention_schedule, ph09_privacy.retention_task, ph09_privacy.legal_hold, ph09_privacy.tenant_shred_request, ph09_privacy.subject_request, ph09_privacy.subject_verification, ph09_privacy.subject_task, ph09_privacy.consent_template, ph09_privacy.consent_record, ph09_privacy.dpia_record, ph09_privacy.breach_case, ph09_privacy.breach_notification, ph09_privacy.breach_action, ph09_privacy.privacy_audit_event, ph09_privacy.compliance_report, ph09_privacy.tenant_setting FROM ph09_app;
-- Nhật ký kiểm toán chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph09_owner.
REVOKE UPDATE, DELETE ON ph09_privacy.privacy_audit_event FROM ph09_app;
REVOKE UPDATE ON ph09_privacy.outbox_event FROM ph09_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph09_privacy TO ph09_readonly;
-- Báo cáo không đọc cột mã hóa của phiếu yêu cầu chủ thể, nội dung thông báo vi phạm.
REVOKE SELECT ON ph09_privacy.subject_request, ph09_privacy.breach_notification, ph09_privacy.reveal_grant FROM ph09_readonly;
GRANT SELECT (id, tenant_id, request_type, status, channel, identifier_type, received_at, due_at, overdue, verified_at, assigned_to, outcome, responded_at, closed_at, restriction_active)
  ON ph09_privacy.subject_request TO ph09_readonly;
-- Vai data plane /privacy/v1 (quyết định mục đích, kế hoạch che): chỉ đọc chính sách và chỉ mục, ghi bộ đếm; không đọc định danh chủ thể, bằng chứng, hồ sơ vi phạm.
GRANT SELECT ON ph09_privacy.data_class, ph09_privacy.data_element, ph09_privacy.element_classification, ph09_privacy.contract_level, ph09_privacy.purpose, ph09_privacy.purpose_element, ph09_privacy.purpose_grant, ph09_privacy.grant_condition, ph09_privacy.mask_type, ph09_privacy.mask_policy, ph09_privacy.mask_rule, ph09_privacy.policy_bundle, ph09_privacy.personal_data_category, ph09_privacy.block_label, ph09_privacy.legal_hold TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, restriction_active) ON ph09_privacy.subject_request TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, template_code, status, expires_at) ON ph09_privacy.consent_record TO ph09_decide;
GRANT SELECT, INSERT, UPDATE ON ph09_privacy.usage_counter TO ph09_decide;
GRANT INSERT ON ph09_privacy.privacy_audit_event TO ph09_decide;
GRANT EXECUTE ON PROCEDURE ph09_privacy.p_ensure_partitions(regclass, date, integer) TO ph09_app;
GRANT EXECUTE ON PROCEDURE ph09_privacy.p_seed_tenant(text) TO ph09_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
