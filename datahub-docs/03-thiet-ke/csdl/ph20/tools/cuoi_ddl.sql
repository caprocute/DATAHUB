-- @file 20-0090-seed.sql
-- @changeset ph20-0910-fn-seed-platform splitStatements:false
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
  FROM (VALUES @@MODULES@@) AS m(c, n, w, du, core, def, o)
  ON CONFLICT (module_code) DO NOTHING;
  INSERT INTO ph20_tenant.module_dependency (id, tenant_id, module_code, depends_on_code, dependency_type, reason, created_by, updated_by)
  SELECT md5('ph20-dep:' || d.a || ':' || d.b)::uuid, 'PLATFORM', d.a, d.b, d.t, d.r, 'system:seed', 'system:seed'
  FROM (VALUES @@DEPS@@) AS d(a, b, t, r)
  ON CONFLICT (module_code, depends_on_code) DO NOTHING;
  INSERT INTO ph20_tenant.provisioning_template (id, tenant_id, template_code, version_no, name, description, status, default_isolation_mode, deployment_profile,
                                                 default_quota, default_modules, step_plan, default_settings, org_seed, activated_at, created_by, updated_by)
  VALUES (md5('ph20-template:tinh-chuan:1')::uuid, 'PLATFORM', 'tinh-chuan', 1, 'Tỉnh quy mô vừa (GĐ-01)',
          'Mẫu khởi tạo mặc định cho tỉnh quy mô vừa: khoảng 200 HTTT, chế độ SHARED, hồ sơ triển khai HT-A, mười hai phân hệ MVP, bộ hạn mức theo D03-10 §5.3 cộng năm hạn mức bổ sung (giả định).',
          'PUBLISHED', 'SHARED', 'HT-A',
          @@QUOTA@@,
          '{PH-01,PH-02,PH-03,PH-04,PH-05,PH-07,PH-10,PH-12,PH-13,PH-14,PH-18,PH-20}',
          @@STEPS@@,
          '{"idleSessionMinutes": 30, "mfaRequired": true, "locale": "vi-VN", "timezone": "Asia/Ho_Chi_Minh"}',
          @@ORGSEED@@,
          now(), 'system:seed', 'system:seed')
  ON CONFLICT (template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_seed_platform() IS 'Nạp dữ liệu nền PH-20: tenant PLATFORM và COMMON, 20 phân hệ cùng phụ thuộc chính, mẫu khởi tạo `tinh-chuan`. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_seed_platform();

-- @changeset ph20-0920-fn-init-quota splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_init_tenant_quota(text, text);

-- @changeset ph20-0930-seed-run
CALL ph20_tenant.p_seed_platform();
-- @rollback DELETE FROM ph20_tenant.provisioning_template WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.module_dependency WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.platform_module WHERE tenant_id = 'PLATFORM'; ALTER TABLE ph20_tenant.tenant DISABLE TRIGGER USER; DELETE FROM ph20_tenant.tenant WHERE code IN ('PLATFORM', 'COMMON'); ALTER TABLE ph20_tenant.tenant ENABLE TRIGGER USER;

-- @file 20-0900-grants.sql
-- @changeset ph20-0990-grants runAlways:true
@@GRANTS@@
REVOKE EXECUTE ON PROCEDURE ph20_tenant.p_seed_platform(), ph20_tenant.p_init_tenant_quota(text, text), ph20_tenant.p_ensure_partitions(regclass, date, integer) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph20_tenant.p_init_tenant_quota(text, text) TO ph20_platform_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
