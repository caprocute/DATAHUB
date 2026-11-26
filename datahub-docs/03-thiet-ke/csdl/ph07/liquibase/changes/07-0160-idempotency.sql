--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0160-idempotency.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1600-idempotency-key
-- EN-07-16 Khóa chống trùng (D03-02-PH07 §4.8.3). Lưu ở PostgreSQL, ghi trong
-- cùng giao dịch với thao tác để "đã thực hiện" và "đã ghi khóa" không lệch.
CREATE TABLE ph07_rdm.idempotency_key (
  tenant_id        varchar(16)   NOT NULL,
  principal        varchar(128)  NOT NULL,
  operation        varchar(16)   NOT NULL,
  key              varchar(128)  NOT NULL,
  request_hash     char(64)      NOT NULL,
  status           varchar(16)   NOT NULL DEFAULT 'IN_PROGRESS',
  response_status  smallint,
  response_body    jsonb,
  resource_ref     text,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  expires_at       timestamptz   NOT NULL DEFAULT now() + interval '24 hours',
  CONSTRAINT pk_idempotency_key PRIMARY KEY (tenant_id, principal, operation, key),
  CONSTRAINT ck_idempotency_key_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON|PLATFORM)$'),
  CONSTRAINT ck_idempotency_key_len CHECK (char_length(key) BETWEEN 16 AND 128),
  CONSTRAINT ck_idempotency_key_op CHECK (operation ~ '^API-07-[0-9]{3}$'),
  CONSTRAINT ck_idempotency_key_hash CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_key_status CHECK (status IN ('IN_PROGRESS','COMPLETED')),
  CONSTRAINT ck_idempotency_key_body CHECK (response_body IS NULL OR pg_column_size(response_body) <= 65536)
);
CREATE INDEX ix_idempotency_key_expires ON ph07_rdm.idempotency_key (expires_at);
ALTER TABLE ph07_rdm.idempotency_key ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.idempotency_key FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_idempotency_key_all ON ph07_rdm.idempotency_key FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', false))
  WITH CHECK (tenant_id = current_setting('app.tenant_id', false));
COMMENT ON TABLE ph07_rdm.idempotency_key IS 'EN-07-16 Khóa Idempotency-Key của lệnh tạo (16…128 ký tự, giữ 24 giờ); cùng khóa khác request_hash trả ERR-07-022. Dọn theo expires_at mỗi giờ. RLS theo đúng tenant phiên (kể cả PLATFORM).';
--rollback DROP TABLE IF EXISTS ph07_rdm.idempotency_key CASCADE;

--changeset ph07:ph07-1610-shedlock
-- Khóa lịch của bộ lập lịch (ShedLock, ADR-057): mỗi tác vụ định kỳ chỉ chạy
-- trên một pod. Bảng kỹ thuật, không chứa dữ liệu tenant nên không bật RLS.
CREATE TABLE ph07_rdm.shedlock (
  name        varchar(64)   NOT NULL,
  lock_until  timestamptz   NOT NULL,
  locked_at   timestamptz   NOT NULL,
  locked_by   varchar(255)  NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph07_rdm.shedlock IS 'Khóa ShedLock cho tác vụ định kỳ của PH-07 (quét lịch đồng bộ, dọn bảng tạm, hết hạn tác vụ, tự chuyển hiệu lực). Không chứa dữ liệu nghiệp vụ.';
--rollback DROP TABLE IF EXISTS ph07_rdm.shedlock CASCADE;
