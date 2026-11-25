--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0060-item-succession.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0600-item-succession
CREATE TABLE ph07_rdm.item_succession (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  catalog_id      uuid          NOT NULL,
  version_id      uuid          NOT NULL,
  event_type      varchar(32)   NOT NULL,
  from_codes      text[]        NOT NULL DEFAULT '{}',
  to_codes        text[]        NOT NULL DEFAULT '{}',
  effective_date  date          NOT NULL,
  legal_basis     text          NOT NULL,
  note            text,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_item_succession PRIMARY KEY (id),
  CONSTRAINT fk_item_succession_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_item_succession_catalog FOREIGN KEY (catalog_id, tenant_id)
    REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_item_succession_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_item_succession_type CHECK (event_type IN ('MERGE','SPLIT','RENAME','ABOLISH','ESTABLISH','RECODE')),
  CONSTRAINT ck_item_succession_legal CHECK (length(btrim(legal_basis)) > 0),
  -- Bản số theo loại sự kiện (BR-07-021).
  CONSTRAINT ck_item_succession_cardinality CHECK (
       (event_type = 'MERGE'     AND cardinality(from_codes) >= 2 AND cardinality(to_codes) = 1)
    OR (event_type = 'SPLIT'     AND cardinality(from_codes) >= 1 AND cardinality(to_codes) >= 2)
    OR (event_type = 'RENAME'    AND cardinality(from_codes) = 1  AND to_codes = from_codes)
    OR (event_type = 'RECODE'    AND cardinality(from_codes) = 1  AND cardinality(to_codes) = 1 AND to_codes <> from_codes)
    OR (event_type = 'ABOLISH'   AND cardinality(from_codes) >= 1 AND cardinality(to_codes) = 0)
    OR (event_type = 'ESTABLISH' AND cardinality(from_codes) = 0  AND cardinality(to_codes) >= 1))
);
CREATE INDEX ix_item_succession_version ON ph07_rdm.item_succession (version_id, effective_date);
-- Chuyển mã cũ sang mới: from_codes @> ARRAY[$code]; tra ngược: to_codes @> ARRAY[$code].
CREATE INDEX ix_item_succession_from ON ph07_rdm.item_succession USING gin (from_codes);
CREATE INDEX ix_item_succession_to   ON ph07_rdm.item_succession USING gin (to_codes);
CREATE INDEX ix_item_succession_catalog ON ph07_rdm.item_succession (catalog_id, effective_date);
CREATE TRIGGER tg_item_succession_touch BEFORE UPDATE ON ph07_rdm.item_succession
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.item_succession ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.item_succession FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_item_succession_select ON ph07_rdm.item_succession FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_item_succession_insert ON ph07_rdm.item_succession FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_item_succession_update ON ph07_rdm.item_succession FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_item_succession_delete ON ph07_rdm.item_succession FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.item_succession IS 'EN-07-06 Sự kiện kế thừa bản ghi (sắp xếp ĐVHC): nhiều-nhiều, có căn cứ pháp lý và ngày hiệu lực (FR-07-045, ADR-055). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.item_succession.version_id IS 'Phiên bản ghi nhận sự kiện; bất biến cùng phiên bản khi phát hành.';
COMMENT ON COLUMN ph07_rdm.item_succession.from_codes IS 'Mã đơn vị trước sự kiện.';
COMMENT ON COLUMN ph07_rdm.item_succession.to_codes IS 'Mã đơn vị sau sự kiện.';
--rollback DROP TABLE IF EXISTS ph07_rdm.item_succession CASCADE;
