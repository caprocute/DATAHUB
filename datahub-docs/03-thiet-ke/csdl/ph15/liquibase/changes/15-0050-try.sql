--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0050-try.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0500-try-run
CREATE TABLE ph15_portal.try_run (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  api_id            uuid          NOT NULL,
  version_no          varchar(32)   NOT NULL,
  method              varchar(7)    NOT NULL,
  path_template       varchar(512)  NOT NULL,
  environment         varchar(10)   NOT NULL,
  sandbox_mode        varchar(8),
  result              varchar(14)   NOT NULL,
  http_status         smallint,
  latency_ms          integer,
  trace_id            char(32)      NOT NULL,
  request_snapshot    jsonb,
  executed_at         timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_try_run PRIMARY KEY (id, executed_at),
  CONSTRAINT fk_try_run_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_try_run_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_try_run_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_try_run_method CHECK (method IN ('GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_try_run_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_try_run_mode CHECK (sandbox_mode IS NULL OR sandbox_mode IN ('MOCK', 'BACKEND')),
  CONSTRAINT ck_try_run_result CHECK (result IN ('OK', 'UPSTREAM_ERROR', 'DENIED', 'THROTTLED', 'TIMEOUT')),
  CONSTRAINT ck_try_run_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_try_run_latency CHECK (latency_ms IS NULL OR latency_ms >= 0),
  CONSTRAINT ck_try_run_prod CHECK (environment <> 'PRODUCTION' OR (method IN ('GET', 'HEAD') AND request_snapshot IS NULL AND sandbox_mode IS NULL)),
  CONSTRAINT ck_try_run_sandbox CHECK (environment <> 'SANDBOX' OR sandbox_mode IS NOT NULL OR result = 'DENIED'),
  CONSTRAINT ck_try_run_snapshot CHECK (request_snapshot IS NULL OR (jsonb_typeof(request_snapshot) = 'object' AND octet_length(request_snapshot::text) <= 16384))
) PARTITION BY RANGE (executed_at);
CREATE INDEX ix_try_run_account ON ph15_portal.try_run (tenant_id, account_id, executed_at DESC);
CREATE INDEX ix_try_run_app ON ph15_portal.try_run (tenant_id, app_id, executed_at DESC);
CREATE INDEX ix_try_run_entry ON ph15_portal.try_run (tenant_id, api_id, executed_at DESC);
CREATE INDEX ix_try_run_trace ON ph15_portal.try_run (trace_id);
CALL ph15_portal.p_enable_rls('ph15_portal.try_run');
CALL ph15_portal.p_ensure_month_partitions('ph15_portal.try_run', DATE '2026-11-01', 6);
COMMENT ON TABLE ph15_portal.try_run IS 'EN-15-11 Lượt thử API (FR-15-035, 040, 043): siêu dữ liệu và, với SANDBOX, bản yêu cầu đã quét PII-15 để gửi lại. Không thân phản hồi, không tiêu đề xác thực (BR-15-024). Phân vùng tháng (ADR-047).';
COMMENT ON COLUMN ph15_portal.try_run.id IS 'tryId, cũng là giá trị tiêu đề X-DH-Try-Id (BR-15-026); UUID v7.';
COMMENT ON COLUMN ph15_portal.try_run.request_snapshot IS 'Chỉ lượt SANDBOX: phương thức, tham số, thân tổng hợp ≤ 16 KB đã qua bộ luật PII-15; PRODUCTION luôn NULL (không lưu thân).';
COMMENT ON COLUMN ph15_portal.try_run.path_template IS 'Đường dẫn dạng mẫu /ho-tich/{id}, không chứa giá trị thật của tham số đường dẫn.';
--rollback DROP TABLE IF EXISTS ph15_portal.try_run CASCADE;

--changeset ph15:ph15-0510-request-collection
CREATE TABLE ph15_portal.try_collection (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  name                varchar(128)  NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_try_collection PRIMARY KEY (id),
  CONSTRAINT uq_try_collection_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_try_collection_name UNIQUE (account_id, name),
  CONSTRAINT fk_try_collection_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id)
);
CREATE TRIGGER tg_try_collection_touch BEFORE UPDATE ON ph15_portal.try_collection FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.try_collection');
COMMENT ON TABLE ph15_portal.try_collection IS 'EN-15-12 Bộ sưu tập yêu cầu của người dùng, tối đa 50 bộ (trigger tg_collection_limit; ERR-15-003). Chia sẻ cho nhóm là Đợt 3 (Q15-12).';
--rollback DROP TABLE IF EXISTS ph15_portal.try_collection CASCADE;

--changeset ph15:ph15-0511-collection-item
CREATE TABLE ph15_portal.try_collection_item (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  collection_id       uuid          NOT NULL,
  api_id            uuid,
  position            integer       NOT NULL DEFAULT 0,
  name                varchar(128)  NOT NULL,
  request_spec        jsonb         NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_try_collection_item PRIMARY KEY (id),
  CONSTRAINT fk_try_collection_item_collection FOREIGN KEY (collection_id, tenant_id) REFERENCES ph15_portal.try_collection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_try_collection_item_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_try_collection_item_spec CHECK (jsonb_typeof(request_spec) = 'object' AND octet_length(request_spec::text) <= 16384)
);
CREATE INDEX ix_try_collection_item_collection ON ph15_portal.try_collection_item (tenant_id, collection_id, position);
CREATE TRIGGER tg_try_collection_item_touch BEFORE UPDATE ON ph15_portal.try_collection_item FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.try_collection_item');
COMMENT ON TABLE ph15_portal.try_collection_item IS 'Yêu cầu mẫu trong bộ sưu tập, tối đa 100 mỗi bộ và 16 KB mỗi yêu cầu (FR-15-040, Phụ lục A.6); chỉ nội dung tổng hợp đã quét PII-15.';
--rollback DROP TABLE IF EXISTS ph15_portal.try_collection_item CASCADE;

--changeset ph15:ph15-0512-collection-limits splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_collection_limit() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE n integer;
BEGIN
  IF TG_TABLE_NAME = 'try_collection' THEN
    SELECT count(*) INTO n FROM ph15_portal.try_collection WHERE account_id = NEW.account_id;
    IF n >= 50 THEN RAISE EXCEPTION 'Đã đạt số bộ sưu tập tối đa (50)' USING ERRCODE = 'P1503'; END IF;
  ELSE
    SELECT count(*) INTO n FROM ph15_portal.try_collection_item WHERE collection_id = NEW.collection_id;
    IF n >= 100 THEN RAISE EXCEPTION 'Đã đạt số yêu cầu tối đa trong bộ sưu tập (100)' USING ERRCODE = 'P1503'; END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_collection_limit() IS 'Chốt chặn giới hạn 50 bộ sưu tập mỗi người và 100 yêu cầu mỗi bộ (ứng dụng kiểm trước, ERR-15-003).';
CREATE TRIGGER tg_try_collection_limit BEFORE INSERT ON ph15_portal.try_collection FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_collection_limit();
CREATE TRIGGER tg_try_collection_item_limit BEFORE INSERT ON ph15_portal.try_collection_item FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_collection_limit();
--rollback DROP TRIGGER IF EXISTS tg_try_collection_limit ON ph15_portal.try_collection; DROP TRIGGER IF EXISTS tg_try_collection_item_limit ON ph15_portal.try_collection_item; DROP FUNCTION IF EXISTS ph15_portal.tg_collection_limit();
