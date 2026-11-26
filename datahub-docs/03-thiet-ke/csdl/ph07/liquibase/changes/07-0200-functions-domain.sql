--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0200-functions-domain.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-2000-fn-recompute-hierarchy splitStatements:false
-- Tính lại depth/path cho toàn bộ một phiên bản bằng một truy vấn đệ quy
-- (set-based), gọi sau mỗi lô ghi và trước validate/publish. Trả danh sách
-- vi phạm BR-07-014 để ứng dụng ánh xạ ERR-07-010/011.
CREATE OR REPLACE FUNCTION ph07_rdm.f_recompute_hierarchy(p_version_id uuid, p_base_version_id uuid DEFAULT NULL)
  RETURNS TABLE (problem text, item_code varchar)
  LANGUAGE plpgsql
AS $$
DECLARE
  v_max smallint;
BEGIN
  SELECT c.max_depth INTO v_max
    FROM ph07_rdm.catalog_version v JOIN ph07_rdm.catalog c ON c.id = v.catalog_id
   WHERE v.id = p_version_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ERR-07-006: không tìm thấy phiên bản %', p_version_id USING ERRCODE = 'no_data_found';
  END IF;

  WITH RECURSIVE t(id, code, depth, path) AS (
      SELECT a.id, a.code, a.depth, a.path FROM (
          SELECT i.id, i.code, 1 AS depth, ARRAY[]::text[] AS path
            FROM ph07_rdm.catalog_item i
           WHERE i.version_id = p_version_id AND i.parent_code IS NULL
          UNION ALL
          -- Bản ghi HYBRID treo dưới bản ghi của phiên bản gốc COMMON.
          SELECT i.id, i.code, b.depth + 1, b.path || b.code::text
            FROM ph07_rdm.catalog_item i
            JOIN ph07_rdm.catalog_item b ON b.version_id = p_base_version_id AND b.code = i.parent_code
           WHERE p_base_version_id IS NOT NULL AND i.version_id = p_version_id
             AND NOT EXISTS (SELECT 1 FROM ph07_rdm.catalog_item s
                              WHERE s.version_id = p_version_id AND s.code = i.parent_code)
      ) a
      UNION ALL
      SELECT c.id, c.code, t.depth + 1, t.path || t.code::text
        FROM t JOIN ph07_rdm.catalog_item c ON c.version_id = p_version_id AND c.parent_code = t.code
       WHERE t.depth <= 10
  )
  UPDATE ph07_rdm.catalog_item ci
     SET depth = t.depth, path = t.path
    FROM t
   WHERE ci.id = t.id AND t.depth <= 10
     AND (ci.depth <> t.depth OR ci.path <> t.path);

  RETURN QUERY
  WITH RECURSIVE t(id, code, depth) AS (
      SELECT a.id, a.code, a.depth FROM (
          SELECT i.id, i.code, 1 AS depth FROM ph07_rdm.catalog_item i
           WHERE i.version_id = p_version_id AND i.parent_code IS NULL
          UNION ALL
          SELECT i.id, i.code, b.depth + 1
            FROM ph07_rdm.catalog_item i
            JOIN ph07_rdm.catalog_item b ON b.version_id = p_base_version_id AND b.code = i.parent_code
           WHERE p_base_version_id IS NOT NULL AND i.version_id = p_version_id
             AND NOT EXISTS (SELECT 1 FROM ph07_rdm.catalog_item s
                              WHERE s.version_id = p_version_id AND s.code = i.parent_code)
      ) a
      UNION ALL
      SELECT c.id, c.code, t.depth + 1
        FROM t JOIN ph07_rdm.catalog_item c ON c.version_id = p_version_id AND c.parent_code = t.code
       WHERE t.depth <= 10
  )
  SELECT 'ORPHAN_OR_CYCLE'::text, i.code
    FROM ph07_rdm.catalog_item i
   WHERE i.version_id = p_version_id AND NOT EXISTS (SELECT 1 FROM t WHERE t.id = i.id)
  UNION ALL
  SELECT 'MAX_DEPTH_EXCEEDED'::text, t.code FROM t WHERE t.depth > v_max
  UNION ALL
  SELECT 'DEPRECATED_PARENT'::text, c.code
    FROM ph07_rdm.catalog_item c
    JOIN ph07_rdm.catalog_item p ON p.version_id = c.version_id AND p.code = c.parent_code
   WHERE c.version_id = p_version_id AND c.status = 'ACTIVE' AND p.status = 'DEPRECATED';
END
$$;
COMMENT ON FUNCTION ph07_rdm.f_recompute_hierarchy(uuid, uuid) IS 'Tính lại depth/path của một phiên bản DRAFT; trả vi phạm ORPHAN_OR_CYCLE, MAX_DEPTH_EXCEEDED, DEPRECATED_PARENT (BR-07-014).';
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_recompute_hierarchy(uuid, uuid);

--changeset ph07:ph07-2001-fn-refresh-admin-unit splitStatements:false
-- Làm mới bảng chiếu admin_unit (EN-07-18 = DD-07) từ một phiên bản DVHC vừa
-- phát hành; gọi trong CÙNG giao dịch phát hành, bởi tenant PLATFORM.
CREATE OR REPLACE FUNCTION ph07_rdm.f_refresh_admin_unit(p_version_id uuid, p_actor uuid)
  RETURNS integer
  LANGUAGE plpgsql
AS $$
DECLARE
  v_from  date;
  v_label text;
  v_n     integer := 0;
  v_c     integer;
BEGIN
  IF current_setting('app.tenant_id', false) <> 'PLATFORM' THEN
    RAISE EXCEPTION 'ERR-07-003: chỉ tenant PLATFORM làm mới admin_unit' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT v.effective_from, 'DVHC:' || v.version_no INTO v_from, v_label
    FROM ph07_rdm.catalog_version v JOIN ph07_rdm.catalog c ON c.id = v.catalog_id
   WHERE v.id = p_version_id AND c.tenant_id = 'COMMON' AND c.code = 'DVHC' AND v.status = 'PUBLISHED';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ERR-07-006: % không phải phiên bản DVHC đã phát hành', p_version_id USING ERRCODE = 'no_data_found';
  END IF;

  IF to_regclass('pg_temp.tmp_au') IS NOT NULL THEN
    DROP TABLE pg_temp.tmp_au;
  END IF;
  CREATE TEMP TABLE tmp_au ON COMMIT DROP AS
  SELECT x.* FROM (
    SELECT i.code, i.name, i.parent_code,
           i.attrs ->> 'level'     AS level,
           i.attrs ->> 'unit_type' AS unit_type,
           coalesce(i.valid_from, v_from) AS eff_from,
           coalesce(i.valid_to, CASE WHEN i.status = 'DEPRECATED' THEN v_from END) AS eff_to
      FROM ph07_rdm.catalog_item i
     WHERE i.version_id = p_version_id) x
   WHERE x.eff_to IS NULL OR x.eff_to > x.eff_from;

  -- 1a. Đơn vị đang mở nhưng bản ghi đã đóng trong phiên bản: đóng theo valid_to.
  UPDATE ph07_rdm.admin_unit au
     SET effective_to = t.eff_to, updated_by = p_actor
    FROM tmp_au t
   WHERE au.code = t.code AND au.effective_to IS NULL AND au.deleted_at IS NULL
     AND t.eff_to IS NOT NULL AND t.eff_to > au.effective_from;
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  -- 1b. Đơn vị đang mở không còn trong phiên bản mới: đóng tại effective_from.
  UPDATE ph07_rdm.admin_unit au
     SET effective_to = v_from, updated_by = p_actor
   WHERE au.effective_to IS NULL AND au.deleted_at IS NULL AND au.effective_from < v_from
     AND NOT EXISTS (SELECT 1 FROM tmp_au t WHERE t.code = au.code AND t.eff_to IS NULL);
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  -- 2. Đơn vị tiếp tục: cập nhật tên, cấp, loại (RENAME giữ nguyên id).
  UPDATE ph07_rdm.admin_unit au
     SET name = t.name, level = t.level, unit_type = t.unit_type,
         source_version = v_label, updated_by = p_actor
    FROM tmp_au t
   WHERE au.code = t.code AND t.eff_to IS NULL AND au.effective_to IS NULL AND au.deleted_at IS NULL
     AND (au.name, au.level, au.unit_type) IS DISTINCT FROM (t.name, t.level, t.unit_type);
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  -- 3. Đơn vị mới (hoặc khoảng lịch sử chưa có): thêm dòng.
  INSERT INTO ph07_rdm.admin_unit (id, tenant_id, code, name, level, unit_type, effective_from, effective_to,
                                   source_version, created_by, updated_by)
  SELECT ph07_rdm.f_uuid_v7(), 'COMMON', t.code, t.name, t.level, t.unit_type, t.eff_from, t.eff_to,
         v_label, p_actor, p_actor
    FROM tmp_au t
   WHERE NOT EXISTS (SELECT 1 FROM ph07_rdm.admin_unit au
                      WHERE au.code = t.code AND au.deleted_at IS NULL
                        AND daterange(au.effective_from, au.effective_to, '[)') && daterange(t.eff_from, t.eff_to, '[)'));
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  -- 4. Đơn vị cấp trên: cha có hiệu lực tại thời điểm tham chiếu của con.
  UPDATE ph07_rdm.admin_unit c
     SET parent_id = p.id, updated_by = p_actor
    FROM tmp_au t
    JOIN ph07_rdm.admin_unit p ON p.code = t.parent_code AND p.deleted_at IS NULL
   WHERE c.code = t.code AND c.deleted_at IS NULL
     AND daterange(c.effective_from, c.effective_to, '[)') && daterange(t.eff_from, t.eff_to, '[)')
     AND daterange(p.effective_from, p.effective_to, '[)')
         @> CASE WHEN c.effective_to IS NULL THEN greatest(c.effective_from, v_from) ELSE c.effective_from END
     AND c.parent_id IS DISTINCT FROM p.id;
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  UPDATE ph07_rdm.admin_unit c
     SET parent_id = NULL, updated_by = p_actor
    FROM tmp_au t
   WHERE c.code = t.code AND t.parent_code IS NULL AND c.parent_id IS NOT NULL
     AND c.effective_to IS NULL AND t.eff_to IS NULL AND c.deleted_at IS NULL;

  -- 5. Đơn vị kế thừa theo sự kiện sắp xếp của phiên bản.
  UPDATE ph07_rdm.admin_unit o
     SET successor_ids = s.ids, updated_by = p_actor
    FROM (SELECT f.code AS from_code, e.effective_date, jsonb_agg(DISTINCT n.id) AS ids
            FROM ph07_rdm.item_succession e
            CROSS JOIN LATERAL unnest(e.from_codes) AS f(code)
            JOIN ph07_rdm.admin_unit n
              ON n.code = ANY (e.to_codes) AND n.deleted_at IS NULL
             AND daterange(n.effective_from, n.effective_to, '[)') @> e.effective_date
           WHERE e.version_id = p_version_id
           GROUP BY f.code, e.effective_date) s
   WHERE o.code = s.from_code AND o.deleted_at IS NULL AND o.effective_to = s.effective_date
     AND o.successor_ids IS DISTINCT FROM s.ids;
  GET DIAGNOSTICS v_c = ROW_COUNT; v_n := v_n + v_c;

  RETURN v_n;
END
$$;
COMMENT ON FUNCTION ph07_rdm.f_refresh_admin_unit(uuid, uuid) IS 'Làm mới admin_unit từ phiên bản DVHC đã phát hành; giữ id ổn định cho đơn vị tiếp tục, đóng đơn vị bị sắp xếp, gán successor_ids. Trả số dòng thay đổi.';
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_refresh_admin_unit(uuid, uuid);

--changeset ph07:ph07-2002-fn-import-row-partitions splitStatements:false
-- Bảo trì phân vùng import_row: tạo trước p_days_ahead ngày, xóa phân vùng
-- cũ hơn p_keep_days ngày. SECURITY DEFINER (chạy quyền ph07_owner) để tác
-- vụ lịch của ứng dụng (ShedLock, 02:00) gọi được mà ph07_app không cần DDL.
CREATE OR REPLACE FUNCTION ph07_rdm.f_import_row_maintain(p_days_ahead integer DEFAULT 3, p_keep_days integer DEFAULT 8)
  RETURNS text[]
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_today date := (now() AT TIME ZONE 'UTC')::date;
  v_day   date;
  v_name  text;
  v_res   text[] := '{}';
  r       record;
BEGIN
  IF p_days_ahead NOT BETWEEN 1 AND 14 OR p_keep_days NOT BETWEEN 7 AND 60 THEN
    RAISE EXCEPTION 'Tham số ngoài miền cho phép' USING ERRCODE = 'invalid_parameter_value';
  END IF;
  FOR i IN 0 .. p_days_ahead LOOP
    v_day  := v_today + i;
    v_name := 'import_row_p' || to_char(v_day, 'YYYYMMDD');
    IF to_regclass('ph07_rdm.' || v_name) IS NULL THEN
      EXECUTE format('CREATE TABLE ph07_rdm.%I PARTITION OF ph07_rdm.import_row FOR VALUES FROM (%L) TO (%L)',
                     v_name, (v_day::timestamp AT TIME ZONE 'UTC'), ((v_day + 1)::timestamp AT TIME ZONE 'UTC'));
      v_res := v_res || ('+' || v_name);
    END IF;
  END LOOP;
  FOR r IN
    SELECT c.relname
      FROM pg_inherits h
      JOIN pg_class c ON c.oid = h.inhrelid
      JOIN pg_class p ON p.oid = h.inhparent
      JOIN pg_namespace n ON n.oid = p.relnamespace
     WHERE n.nspname = 'ph07_rdm' AND p.relname = 'import_row'
       AND c.relname ~ '^import_row_p[0-9]{8}$'
       AND to_date(substring(c.relname FROM 13), 'YYYYMMDD') < v_today - p_keep_days
  LOOP
    EXECUTE format('DROP TABLE ph07_rdm.%I', r.relname);
    v_res := v_res || ('-' || r.relname);
  END LOOP;
  DELETE FROM ph07_rdm.import_row_default WHERE created_at < (v_today - p_keep_days)::timestamp AT TIME ZONE 'UTC';
  RETURN v_res;
END
$$;
REVOKE ALL ON FUNCTION ph07_rdm.f_import_row_maintain(integer, integer) FROM PUBLIC;
COMMENT ON FUNCTION ph07_rdm.f_import_row_maintain(integer, integer) IS 'Tạo trước/xóa phân vùng ngày của import_row (lưu giữ 7 ngày + 1 ngày đệm). SECURITY DEFINER.';
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_import_row_maintain(integer, integer);

--changeset ph07:ph07-2003-import-row-initial-partitions
SELECT ph07_rdm.f_import_row_maintain(3, 8);
--rollback empty
