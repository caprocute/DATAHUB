--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0090-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0900-seed-fn splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.seed_tenant(p_tenant varchar, p_actor varchar) RETURNS void
  LANGUAGE plpgsql AS $f$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph15_portal.portal_setting (id, tenant_id, portal_name, greeting, created_by, updated_by)
  VALUES (gen_random_uuid(), p_tenant, 'Cổng nhà phát triển ' || p_tenant, 'Chào mừng đến Cổng nhà phát triển', p_actor, p_actor)
  ON CONFLICT (tenant_id) DO NOTHING;
  INSERT INTO ph15_portal.sync_state (tenant_id) VALUES (p_tenant) ON CONFLICT (tenant_id) DO NOTHING;
END
$f$;
COMMENT ON FUNCTION ph15_portal.seed_tenant(varchar, varchar) IS 'Khởi tạo dữ liệu nền cho tenant mới (sự kiện tenant.provisioned của PH-20): nhận diện cổng mặc định và trạng thái đồng bộ IDLE; lũy đẳng. Chạy dưới ph15_app của tenant đích.';
--rollback DROP FUNCTION IF EXISTS ph15_portal.seed_tenant(varchar, varchar);
