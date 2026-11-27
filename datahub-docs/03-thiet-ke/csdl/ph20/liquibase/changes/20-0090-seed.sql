--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0090-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0910-fn-seed-platform splitStatements:false
-- Dữ liệu nền: hai tenant đặc biệt, danh mục 20 phân hệ cùng phụ thuộc chính, mẫu khởi tạo `tinh-chuan`. Chạy dưới phiên PLATFORM, chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph20_tenant.p_seed_platform()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph20_tenant.tenant (id, code, kind, name, short_name, status, isolation_mode, realm, activated_at, config_path, created_by, updated_by)
  VALUES (md5('ph20-tenant:PLATFORM')::uuid, 'PLATFORM', 'PLATFORM', 'Nền tảng Datahub (control plane)', 'Nền tảng', 'ACTIVE', 'SHARED', 'dh-platform', now(), 'tenants/PLATFORM/', 'system:seed', 'system:seed'),
         (md5('ph20-tenant:COMMON')::uuid, 'COMMON', 'COMMON', 'Dữ liệu dùng chung toàn quốc', 'Dùng chung', 'ACTIVE', 'SHARED', NULL, now(), 'tenants/COMMON/', 'system:seed', 'system:seed')
  ON CONFLICT (code) DO NOTHING;
  INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, is_core, default_enabled, status, display_order, created_by, updated_by)
  SELECT md5('ph20-module:' || m.c)::uuid, 'PLATFORM', m.c, m.n, m.w, m.du, m.core, m.def, 'AVAILABLE', m.o, 'system:seed', 'system:seed'
  FROM (VALUES ('PH-01', 'Kết nạp HTTT', 1, 'dh-connect', false, true, 1),
    ('PH-02', 'Danh mục dịch vụ', 1, 'dh-connect', false, true, 2),
    ('PH-03', 'Cổng API', 1, 'dh-connect', false, true, 3),
    ('PH-04', 'Lõi tích hợp và trình thiết kế luồng', 1, 'dh-integration', false, true, 4),
    ('PH-05', 'Bộ điều hợp', 1, 'dh-integration', false, true, 5),
    ('PH-06', 'Dữ liệu chủ', 3, 'dh-data', false, false, 6),
    ('PH-07', 'Danh mục dùng chung', 1, 'dh-data', false, true, 7),
    ('PH-08', 'Chất lượng dữ liệu', 3, 'dh-data', false, false, 8),
    ('PH-09', 'Quyền riêng tư', 2, 'dh-data', false, false, 9),
    ('PH-10', 'Sự kiện', 1, 'dh-integration', false, true, 10),
    ('PH-11', 'Quy trình liên thông', 2, 'dh-platform', false, false, 11),
    ('PH-12', 'Định danh và phân quyền', 1, 'dh-platform', true, true, 12),
    ('PH-13', 'Giám sát và kiểm toán', 1, 'dh-platform', true, true, 13),
    ('PH-14', 'Kết nối quốc gia', 1, 'dh-runtime', false, true, 14),
    ('PH-15', 'Cổng nhà phát triển', 2, 'dh-portal', false, false, 15),
    ('PH-16', 'Báo cáo chỉ tiêu', 3, 'dh-platform', false, false, 16),
    ('PH-17', 'Trợ lý AI', 3, 'dh-assist', false, false, 17),
    ('PH-18', 'Vận hành và xử lý lỗi', 1, 'dh-platform', true, true, 18),
    ('PH-19', 'Thanh toán', 2, 'dh-payment', false, false, 19),
    ('PH-20', 'Quản trị tenant và phát hành sản phẩm', 1, 'dh-platform', true, true, 20)) AS m(c, n, w, du, core, def, o)
  ON CONFLICT (module_code) DO NOTHING;
  INSERT INTO ph20_tenant.module_dependency (id, tenant_id, module_code, depends_on_code, dependency_type, reason, created_by, updated_by)
  SELECT md5('ph20-dep:' || d.a || ':' || d.b)::uuid, 'PLATFORM', d.a, d.b, d.t, d.r, 'system:seed', 'system:seed'
  FROM (VALUES ('PH-01', 'PH-12', 'REQUIRED', 'Cấp định danh ứng dụng cho HTTT'),
    ('PH-01', 'PH-20', 'REQUIRED', 'Danh mục tổ chức chủ quản HTTT'),
    ('PH-02', 'PH-01', 'REQUIRED', 'Dịch vụ thuộc HTTT thành viên'),
    ('PH-03', 'PH-12', 'REQUIRED', 'Xác thực và phân quyền ở cổng'),
    ('PH-03', 'PH-01', 'REQUIRED', 'Định danh ứng dụng gọi API'),
    ('PH-03', 'PH-02', 'REQUIRED', 'Danh mục API công bố'),
    ('PH-04', 'PH-05', 'REQUIRED', 'Luồng dùng bộ điều hợp'),
    ('PH-04', 'PH-10', 'REQUIRED', 'Luồng phát nhận sự kiện'),
    ('PH-04', 'PH-12', 'REQUIRED', 'Phân quyền thiết kế, phát hành luồng'),
    ('PH-05', 'PH-12', 'REQUIRED', 'Bí mật kết nối do OpenBao, phân quyền'),
    ('PH-06', 'PH-07', 'REQUIRED', 'Dùng danh mục dùng chung'),
    ('PH-06', 'PH-10', 'OPTIONAL', 'Phát sự kiện bản ghi vàng'),
    ('PH-07', 'PH-12', 'REQUIRED', 'Phân quyền danh mục'),
    ('PH-08', 'PH-06', 'REQUIRED', 'Đo chất lượng dữ liệu chủ'),
    ('PH-08', 'PH-07', 'OPTIONAL', 'Đối chiếu danh mục'),
    ('PH-09', 'PH-12', 'REQUIRED', 'Phân quyền, người dùng'),
    ('PH-09', 'PH-07', 'OPTIONAL', 'Phân loại theo danh mục'),
    ('PH-10', 'PH-12', 'REQUIRED', 'Phân quyền topic, schema'),
    ('PH-11', 'PH-12', 'REQUIRED', 'Người xử lý quy trình'),
    ('PH-11', 'PH-10', 'OPTIONAL', 'Sự kiện quy trình'),
    ('PH-12', 'PH-13', 'REQUIRED', 'Ghi nhật ký kiểm toán'),
    ('PH-13', 'PH-12', 'REQUIRED', 'Phân quyền xem nhật ký'),
    ('PH-14', 'PH-05', 'REQUIRED', 'Adapter dùng Kamelet'),
    ('PH-14', 'PH-12', 'REQUIRED', 'Phân quyền kết nối quốc gia'),
    ('PH-15', 'PH-02', 'REQUIRED', 'Tài liệu API từ danh mục dịch vụ'),
    ('PH-15', 'PH-03', 'REQUIRED', 'Thử API qua cổng'),
    ('PH-16', 'PH-13', 'OPTIONAL', 'Nguồn số liệu giám sát'),
    ('PH-17', 'PH-12', 'REQUIRED', 'Quyền dùng trợ lý'),
    ('PH-17', 'PH-09', 'OPTIONAL', 'Che dữ liệu cá nhân trong lời nhắc'),
    ('PH-18', 'PH-12', 'REQUIRED', 'Phân quyền vận hành'),
    ('PH-18', 'PH-13', 'REQUIRED', 'Nhật ký vận hành'),
    ('PH-19', 'PH-03', 'REQUIRED', 'API thanh toán qua cổng'),
    ('PH-19', 'PH-10', 'REQUIRED', 'Sự kiện giao dịch'),
    ('PH-19', 'PH-12', 'REQUIRED', 'Phân quyền, đối tác'),
    ('PH-20', 'PH-12', 'REQUIRED', 'Tạo realm khi khởi tạo tenant'),
    ('PH-20', 'PH-13', 'REQUIRED', 'Chuỗi kiểm toán theo tenant'),
    ('PH-20', 'PH-18', 'OPTIONAL', 'Tham số, thông báo')) AS d(a, b, t, r)
  ON CONFLICT (module_code, depends_on_code) DO NOTHING;
  INSERT INTO ph20_tenant.provisioning_template (id, tenant_id, template_code, version_no, name, description, status, default_isolation_mode, deployment_profile,
                                                 default_quota, default_modules, step_plan, default_settings, org_seed, activated_at, created_by, updated_by)
  VALUES (md5('ph20-template:tinh-chuan:1')::uuid, 'PLATFORM', 'tinh-chuan', 1, 'Tỉnh quy mô vừa (GĐ-01)',
          'Mẫu khởi tạo mặc định cho tỉnh quy mô vừa: khoảng 200 HTTT, chế độ SHARED, hồ sơ triển khai HT-A, mười hai phân hệ MVP, bộ hạn mức theo D03-10 §5.3 cộng năm hạn mức bổ sung (giả định).',
          'PUBLISHED', 'SHARED', 'HT-A',
          '{"API_RPS": 500, "ACTIVE_FLOWS": 1000, "KAFKA_PRODUCE_MBPS": 10, "KAFKA_CONSUME_MBPS": 20, "OBJECT_STORAGE_GB": 500, "DATABASE_GB": 200, "USERS": 2000, "MEMBER_SYSTEMS": 300, "PUBLISHED_APIS": 2000, "TOPICS": 2000, "RUNTIME_CPU": 16, "RUNTIME_MEMORY_GB": 64}'::jsonb,
          '{PH-01,PH-02,PH-03,PH-04,PH-05,PH-07,PH-10,PH-12,PH-13,PH-14,PH-18,PH-20}',
          '[{"stepCode": "S01_RECORD", "executor": "PH-20", "required": true}, {"stepCode": "S02_CONFIG_REPO", "executor": "PH-20", "required": true}, {"stepCode": "S03_REALM", "executor": "PH-12", "required": true}, {"stepCode": "S04_SECRETS", "executor": "PH-20", "required": true}, {"stepCode": "S05_BUCKETS", "executor": "PH-20", "required": true}, {"stepCode": "S06_EVENTING", "executor": "PH-10", "required": true}, {"stepCode": "S07_DATABASE", "executor": "PH-20", "required": false}, {"stepCode": "S08_OBSERVABILITY", "executor": "PH-13", "required": true}, {"stepCode": "S09_GATEWAY", "executor": "PH-03", "required": true}, {"stepCode": "S10_INTEGRATION", "executor": "PH-04", "required": true}, {"stepCode": "S11_SEED_RDM", "executor": "PH-07", "required": true}, {"stepCode": "S12_SEED_MDM", "executor": "PH-06", "required": false}, {"stepCode": "S13_ORG_SEED", "executor": "PH-20", "required": true}, {"stepCode": "S14_KPI", "executor": "PH-16", "required": false}, {"stepCode": "S15_MODULES", "executor": "PH-20", "required": true}, {"stepCode": "S16_SMOKE", "executor": "PH-20", "required": true}, {"stepCode": "S17_ACTIVATE", "executor": "PH-20", "required": true}]'::jsonb,
          '{"idleSessionMinutes": 30, "mfaRequired": true, "locale": "vi-VN", "timezone": "Asia/Ho_Chi_Minh"}',
          '[{"code": "UBND", "name": "Ủy ban nhân dân tỉnh", "orgType": "PROVINCE_PC"}, {"code": "SO-NV", "name": "Sở Nội vụ", "orgType": "DEPARTMENT"}, {"code": "SO-TC", "name": "Sở Tài chính", "orgType": "DEPARTMENT"}, {"code": "SO-KHCN", "name": "Sở Khoa học và Công nghệ", "orgType": "DEPARTMENT"}, {"code": "SO-TP", "name": "Sở Tư pháp", "orgType": "DEPARTMENT"}, {"code": "SO-YT", "name": "Sở Y tế", "orgType": "DEPARTMENT"}]'::jsonb,
          now(), 'system:seed', 'system:seed')
  ON CONFLICT (template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_seed_platform() IS 'Nạp dữ liệu nền PH-20: tenant PLATFORM và COMMON, 20 phân hệ cùng phụ thuộc chính, mẫu khởi tạo `tinh-chuan`. Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_seed_platform();

--changeset ph20:ph20-0920-fn-init-quota splitStatements:false
-- Bước S01_RECORD của saga: sao chép hạn mức mặc định từ mẫu khởi tạo của tenant sang tenant_quota. Chạy dưới phiên PLATFORM (ph20_platform_app).
CREATE OR REPLACE PROCEDURE ph20_tenant.p_init_tenant_quota(p_tenant text, p_actor text)
  LANGUAGE plpgsql AS $p$
BEGIN
  INSERT INTO ph20_tenant.tenant_quota (id, tenant_id, resource_code, limit_value, unit, source, effective_from, push_status, created_by, updated_by)
  SELECT md5('ph20-quota:' || p_tenant || ':' || e.res)::uuid, p_tenant, e.res, e.val::numeric,
         CASE e.res WHEN 'API_RPS' THEN 'rps' WHEN 'ACTIVE_FLOWS' THEN 'flow' WHEN 'KAFKA_PRODUCE_MBPS' THEN 'MB/s' WHEN 'KAFKA_CONSUME_MBPS' THEN 'MB/s'
                    WHEN 'OBJECT_STORAGE_GB' THEN 'GB' WHEN 'DATABASE_GB' THEN 'GB' WHEN 'USERS' THEN 'user' WHEN 'MEMBER_SYSTEMS' THEN 'system'
                    WHEN 'PUBLISHED_APIS' THEN 'api' WHEN 'TOPICS' THEN 'topic' WHEN 'RUNTIME_CPU' THEN 'vCPU' ELSE 'GB' END,
         'TEMPLATE', now(), 'PENDING', p_actor, p_actor
  FROM ph20_tenant.tenant t
  JOIN ph20_tenant.provisioning_template pt ON pt.id = t.template_id
  CROSS JOIN LATERAL jsonb_each_text(pt.default_quota) AS e(res, val)
  WHERE t.code = p_tenant
  ON CONFLICT (tenant_id, resource_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_init_tenant_quota(text, text) IS 'Sao chép 12 hạn mức mặc định từ mẫu khởi tạo sang tenant_quota (bước S01_RECORD, FR-20-001, FR-20-026). Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_init_tenant_quota(text, text);

--changeset ph20:ph20-0930-seed-run
CALL ph20_tenant.p_seed_platform();
--rollback DELETE FROM ph20_tenant.provisioning_template WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.module_dependency WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.platform_module WHERE tenant_id = 'PLATFORM'; ALTER TABLE ph20_tenant.tenant DISABLE TRIGGER USER; DELETE FROM ph20_tenant.tenant WHERE code IN ('PLATFORM', 'COMMON'); ALTER TABLE ph20_tenant.tenant ENABLE TRIGGER USER;
