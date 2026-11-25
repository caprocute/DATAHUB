--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0190-guards.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1900-guard-version splitStatements:false
-- Bảo vệ tầng CSDL cho BR-07-006 (phiên bản đã phát hành bất biến) và máy
-- trạng thái phiên bản. Ứng dụng vẫn kiểm tra trước và trả ERR-07-004; trigger
-- là lớp phòng thủ thứ hai, chặn cả lỗi lập trình lẫn thao tác tay.
CREATE OR REPLACE FUNCTION ph07_rdm.tg_catalog_version_guard()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
DECLARE
  -- Cột được phép đổi trên phiên bản PUBLISHED.
  c_mutable constant text[] := ARRAY['effective_to','snapshot_uri','updated_at','updated_by','version'];
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status <> 'DRAFT' THEN
      RAISE EXCEPTION 'ERR-07-004: phiên bản mới phải ở trạng thái DRAFT (nhận %)', NEW.status
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.status NOT IN ('DRAFT','DISCARDED') THEN
      RAISE EXCEPTION 'ERR-07-004: không xóa được phiên bản % ở trạng thái %', OLD.id, OLD.status
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN OLD;
  END IF;

  -- UPDATE
  IF OLD.status = 'PUBLISHED' THEN
    IF (to_jsonb(NEW) - c_mutable) IS DISTINCT FROM (to_jsonb(OLD) - c_mutable) THEN
      RAISE EXCEPTION 'BR-07-006: phiên bản % đã phát hành là bất biến', OLD.id
        USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.effective_to IS NOT NULL AND NEW.effective_to IS DISTINCT FROM OLD.effective_to THEN
      RAISE EXCEPTION 'BR-07-007: effective_to của phiên bản % đã được chốt', OLD.id
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
       (OLD.status = 'DRAFT'     AND NEW.status IN ('IN_REVIEW','PUBLISHED','DISCARDED'))
    OR (OLD.status = 'IN_REVIEW' AND NEW.status IN ('DRAFT','APPROVED'))
    OR (OLD.status = 'APPROVED'  AND NEW.status IN ('PUBLISHED'))) THEN
    RAISE EXCEPTION 'ERR-07-004: không chuyển phiên bản % từ % sang %', OLD.id, OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.status = 'DISCARDED' THEN
    RAISE EXCEPTION 'ERR-07-004: phiên bản % đã hủy', OLD.id USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END
$$;
CREATE TRIGGER tg_catalog_version_guard
  BEFORE INSERT OR UPDATE OR DELETE ON ph07_rdm.catalog_version
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_catalog_version_guard();
COMMENT ON FUNCTION ph07_rdm.tg_catalog_version_guard() IS 'Chặn sửa phiên bản PUBLISHED (trừ effective_to một lần, snapshot_uri) và chuyển trạng thái sai máy trạng thái.';
--rollback DROP TRIGGER IF EXISTS tg_catalog_version_guard ON ph07_rdm.catalog_version;
--rollback DROP FUNCTION IF EXISTS ph07_rdm.tg_catalog_version_guard();

--changeset ph07:ph07-1901-guard-content splitStatements:false
-- Nội dung phiên bản (thuộc tính, bản ghi, sự kiện sắp xếp) chỉ được ghi khi
-- phiên bản ở DRAFT; được xóa khi DRAFT hoặc DISCARDED (dọn bản nháp đã hủy).
CREATE OR REPLACE FUNCTION ph07_rdm.tg_version_content_guard()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
DECLARE
  v_version_id uuid;
  v_status     text;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.version_id IS DISTINCT FROM OLD.version_id THEN
    RAISE EXCEPTION 'ERR-07-004: không chuyển bản ghi sang phiên bản khác' USING ERRCODE = 'check_violation';
  END IF;
  v_version_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.version_id ELSE NEW.version_id END;
  SELECT status INTO v_status FROM ph07_rdm.catalog_version WHERE id = v_version_id;
  IF NOT FOUND THEN
    -- Phiên bản cha đang bị xóa (ON DELETE CASCADE) hoặc không tồn tại (FK sẽ báo lỗi).
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;
  IF v_status = 'DRAFT' OR (TG_OP = 'DELETE' AND v_status = 'DISCARDED') THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;
  RAISE EXCEPTION 'ERR-07-004: phiên bản % ở trạng thái %, không sửa được nội dung (%.%)',
    v_version_id, v_status, TG_TABLE_NAME, TG_OP USING ERRCODE = 'check_violation';
END
$$;
CREATE TRIGGER tg_attribute_def_guard BEFORE INSERT OR UPDATE OR DELETE ON ph07_rdm.attribute_def
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_version_content_guard();
CREATE TRIGGER tg_catalog_item_guard BEFORE INSERT OR UPDATE OR DELETE ON ph07_rdm.catalog_item
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_version_content_guard();
CREATE TRIGGER tg_item_succession_guard BEFORE INSERT OR UPDATE OR DELETE ON ph07_rdm.item_succession
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_version_content_guard();
COMMENT ON FUNCTION ph07_rdm.tg_version_content_guard() IS 'Chỉ cho ghi nội dung khi phiên bản DRAFT (BR-07-006); xóa khi DRAFT/DISCARDED.';
--rollback DROP TRIGGER IF EXISTS tg_attribute_def_guard ON ph07_rdm.attribute_def;
--rollback DROP TRIGGER IF EXISTS tg_catalog_item_guard ON ph07_rdm.catalog_item;
--rollback DROP TRIGGER IF EXISTS tg_item_succession_guard ON ph07_rdm.item_succession;
--rollback DROP FUNCTION IF EXISTS ph07_rdm.tg_version_content_guard();
