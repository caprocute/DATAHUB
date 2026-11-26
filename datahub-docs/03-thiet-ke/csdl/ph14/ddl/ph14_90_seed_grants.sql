-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national
-- Tệp 90: dữ liệu khởi tạo, quyền theo vai trò.
-- Chạy cuối cùng, sau ph14_40_operations.sql.
-- =============================================================================

\set ON_ERROR_STOP on
SET ROLE ph14_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 14-0800-seed.sql
-- @changeset ph14-0800-seed-common-config
-- Số phiên bản cấu hình của tenant COMMON (cổng dùng chung toàn quốc). Mỗi tenant tỉnh được
-- ConfigRevisionService tạo hai dòng TEST và PROD khi tenant được cấp phát (PH-20).
INSERT INTO ph14_national.config_revision (id, tenant_id, env, revision, created_by, updated_by)
SELECT md5('ph14-config-revision:COMMON:' || e)::uuid, 'COMMON', e, 1, 'system:seed', 'system:seed'
FROM unnest(ARRAY['TEST', 'PROD']) AS e
ON CONFLICT (tenant_id, env) DO NOTHING;
-- @rollback DELETE FROM ph14_national.config_revision WHERE tenant_id = 'COMMON' AND created_by = 'system:seed';

-- @changeset ph14-0810-seed-demo-t90 context:demo splitStatements:false
-- Bộ mẫu cho môi trường phát triển và kiểm thử: tenant T90 (dải T90…T99 dành cho kiểm thử, D00-04 §3),
-- một nền tảng NDXP đặc tả tạm kèm bảy dịch vụ đại diện bảy nhóm với chính sách mặc định theo SDD §4.6.
-- Giá trị chính sách là giả định cho tới khi Q14-01 (đặc tả NDXP) được trả lời. Không chạy ở môi trường thật.
DO $seed$
BEGIN
  PERFORM set_config('app.tenant_id', 'T90', true);
  INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, scope, connection_code, auth_mode, spec_status, owner_agency, created_by, updated_by)
  VALUES (md5('ph14-platform:T90:ndxp-t90')::uuid, 'T90', 'ndxp-t90', 'NDXP của tenant kiểm thử T90', 'NDXP', 'TENANT', 'ndxp-oauth-t90',
          'PRIVATE_KEY_JWT', 'PROVISIONAL', 'Cục Chuyển đổi số quốc gia', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, code) DO NOTHING;

  INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type, idempotent,
                                              sensitivity, cacheable, cache_ttl_seconds, stale_allowed, priority, signing_mode, verify_mode,
                                              purpose_required, procedure_code_required, created_by, updated_by)
  SELECT md5('ph14-service:T90:' || s.code)::uuid, 'T90', md5('ph14-platform:T90:ndxp-t90')::uuid, s.code, s.nat, s.name, s.grp, s.proto, s.op, s.idem,
         s.sens, s.cache, s.ttl, s.stale, s.prio, s.sign, s.sign, s.purpose, s.proc, 'system:seed', 'system:seed'
  FROM (VALUES
    ('lltp-tra-trang-thai',        'LLTP_TRA_TRANG_THAI',        'Tra trạng thái hồ sơ lý lịch tư pháp', 'LLTP',    'REST', 'READ',  NULL::boolean, 'SENSITIVE',  false, NULL::int, false, 'ESSENTIAL',  'JWS',    true,  true),
    ('hotich-dang-ky-khai-sinh',   'HOTICH_DANG_KY_KHAI_SINH',   'Đăng ký khai sinh',                    'HO_TICH', 'SOAP', 'WRITE', false,        'SENSITIVE',  false, NULL,      false, 'ESSENTIAL',  'XMLDSIG', true,  true),
    ('bhxh-tra-ho-gia-dinh',       'BHXH_TRA_HO_GIA_DINH',       'Tra hộ gia đình theo mã số BHXH',      'BHXH',    'REST', 'READ',  NULL,         'RESTRICTED', true,  300,       false, 'NORMAL',     'JWS',    true,  true),
    ('dvqhns-ds-ho-so-theo-ngay',  'DVQHNS_DS_HO_SO_THEO_NGAY',  'Danh sách hồ sơ cấp mã ĐVQHNS theo khoảng', 'DVQHNS', 'REST', 'READ', NULL,       'INTERNAL',   false, NULL,      false, 'BACKGROUND', 'JWS',    false, false),
    ('dkdn-du-lieu-doanh-nghiep',  'DKDN_DU_LIEU_DOANH_NGHIEP',  'Dữ liệu mới nhất của doanh nghiệp',    'DKDN',    'REST', 'READ',  NULL,         'INTERNAL',   true,  3600,      true,  'NORMAL',     'JWS',    false, false),
    ('vbqppl-tim-kiem',            'VBQPPL_TIM_KIEM',            'Tìm kiếm văn bản quy phạm pháp luật',  'VBQPPL',  'REST', 'READ',  NULL,         'PUBLIC',     true,  3600,      true,  'NORMAL',     'NONE',   false, false),
    ('dmdc-lay-du-lieu',           'DMDC_LAY_DU_LIEU',           'Lấy dữ liệu danh mục dùng chung',      'DMDC',    'REST', 'READ',  NULL,         'PUBLIC',     false, NULL,      false, 'BACKGROUND', 'JWS',    false, false)
  ) AS s(code, nat, name, grp, proto, op, idem, sens, cache, ttl, stale, prio, sign, purpose, proc)
  ON CONFLICT (tenant_id, code) DO NOTHING;

  INSERT INTO ph14_national.config_revision (id, tenant_id, env, revision, created_by, updated_by)
  SELECT md5('ph14-config-revision:T90:' || e)::uuid, 'T90', e, 1, 'system:seed', 'system:seed'
  FROM unnest(ARRAY['TEST', 'PROD']) AS e
  ON CONFLICT (tenant_id, env) DO NOTHING;
END
$seed$;
-- @rollback DELETE FROM ph14_national.national_service WHERE tenant_id = 'T90' AND created_by = 'system:seed'; DELETE FROM ph14_national.national_platform WHERE tenant_id = 'T90' AND created_by = 'system:seed';

-- @file 14-0900-grants.sql
-- @changeset ph14-0990-grants runAlways:true splitStatements:false
-- Quyền cấp trên bảng cha, không cấp trên phân vùng: truy vấn qua bảng cha chỉ kiểm quyền của bảng cha,
-- nên phân vùng mới không cần cấp lại và không ai đọc thẳng phân vùng để vòng quyền theo cột.
DO $grants$
DECLARE
  r record;
  cols text;
BEGIN
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph14_national TO ph14_app;
  GRANT SELECT ON ALL TABLES IN SCHEMA ph14_national TO ph14_readonly;

  -- Phân vùng: thu hồi mọi quyền của vai trò ứng dụng và báo cáo.
  FOR r IN SELECT c.oid::regclass AS t FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'ph14_national' AND c.relispartition AND c.relkind = 'r' LOOP
    EXECUTE format('REVOKE ALL ON %s FROM ph14_app, ph14_readonly', r.t);
  END LOOP;

  -- Chỉ thêm, không xóa: sổ giao dịch, chứng thư, neo tin cậy, sự cố, cảnh báo, yêu cầu duyệt.
  REVOKE DELETE ON ph14_national.national_transaction, ph14_national.national_certificate, ph14_national.trust_anchor,
                   ph14_national.signature_incident, ph14_national.anomaly_alert, ph14_national.approval_request FROM ph14_app;
  REVOKE UPDATE ON ph14_national.outbox FROM ph14_app;

  -- ph14_readonly không đọc: nội dung đặc tả (lớn, chỉ cần cho cổng), lookup_key_hash (tương quan đối tượng tra).
  REVOKE SELECT ON ph14_national.service_spec, ph14_national.national_transaction FROM ph14_readonly;
  FOR r IN SELECT * FROM (VALUES ('service_spec', 'content'), ('national_transaction', 'lookup_key_hash')) AS v(tbl, hidden) LOOP
    SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum) INTO cols
      FROM pg_attribute a
     WHERE a.attrelid = ('ph14_national.' || r.tbl)::regclass AND a.attnum > 0 AND NOT a.attisdropped AND a.attname <> r.hidden;
    EXECUTE format('GRANT SELECT (%s) ON ph14_national.%I TO ph14_readonly', cols, r.tbl);
  END LOOP;
END
$grants$;

-- Phân vùng mới do PartitionMaintenanceJob của dh_integration_app tạo: thủ tục chạy với quyền chủ sở hữu.
ALTER PROCEDURE ph14_national.p_ensure_month_partitions(regclass, date, integer) SECURITY DEFINER SET search_path = pg_catalog, pg_temp;
REVOKE EXECUTE ON PROCEDURE ph14_national.p_ensure_month_partitions(regclass, date, integer) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE ph14_national.p_enable_rls(regclass, char) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph14_national.p_ensure_month_partitions(regclass, date, integer) TO ph14_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
