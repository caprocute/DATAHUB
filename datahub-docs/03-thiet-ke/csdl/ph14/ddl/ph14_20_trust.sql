-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national
-- Tệp 20: thông tin xác thực (trạng thái xoay), chứng thư số, chuỗi tin cậy và CRL,
--         sự cố chữ ký. Không có khóa riêng, không có giá trị bí mật (BR-04, BR-05).
-- Chạy sau ph14_10_catalog.sql.
-- =============================================================================

\set ON_ERROR_STOP on
SET ROLE ph14_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 14-0020-trust.sql
-- @changeset ph14-0200-fn-immutable splitStatements:false
-- Chặn đổi cột bất biến: tham số là tên cột; dùng cho chứng thư, neo tin cậy, sự cố chữ ký.
CREATE OR REPLACE FUNCTION ph14_national.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến sau khi tạo', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph14_national.tg_immutable() IS 'Trigger dùng chung: TG_ARGV là danh sách cột không được đổi sau INSERT.';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_immutable();

-- @changeset ph14-0210-credential-rotation
CREATE TABLE ph14_national.credential_rotation (
  id                      uuid          NOT NULL,
  tenant_id               varchar(16)   NOT NULL,
  platform_id             uuid          NOT NULL,
  env                     varchar(8)    NOT NULL,
  trigger_kind            varchar(12)   NOT NULL DEFAULT 'SCHEDULED',
  state                   varchar(24)   NOT NULL DEFAULT 'AWAITING_PENDING_VALUE',
  reason                  varchar(500),
  started_by              varchar(64)   NOT NULL,
  started_at              timestamptz   NOT NULL DEFAULT now(),
  pending_secret_version  integer,
  tested_at               timestamptz,
  switched_by             varchar(64),
  switched_at             timestamptz,
  overlap_until           timestamptz,
  revocation_receipt      varchar(500),
  revocation_confirmed_by varchar(64),
  revocation_confirmed_at timestamptz,
  done_at                 timestamptz,
  cancel_reason           varchar(500),
  created_at              timestamptz   NOT NULL DEFAULT now(),
  created_by              varchar(64)   NOT NULL,
  updated_at              timestamptz   NOT NULL DEFAULT now(),
  updated_by              varchar(64)   NOT NULL,
  version                 integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_credential_rotation PRIMARY KEY (id),
  CONSTRAINT fk_credential_rotation_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_credential_rotation_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_credential_rotation_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_credential_rotation_trigger CHECK (trigger_kind IN ('SCHEDULED', 'ON_DEMAND', 'COMPROMISE')),
  CONSTRAINT ck_credential_rotation_state CHECK (state IN ('AWAITING_PENDING_VALUE', 'PENDING_VERIFY', 'OVERLAP', 'AWAITING_REVOCATION', 'DONE', 'CANCELLED')),
  CONSTRAINT ck_credential_rotation_pending CHECK (state IN ('AWAITING_PENDING_VALUE', 'CANCELLED') OR pending_secret_version IS NOT NULL),
  CONSTRAINT ck_credential_rotation_overlap CHECK (state NOT IN ('OVERLAP', 'AWAITING_REVOCATION', 'DONE')
                                                    OR (tested_at IS NOT NULL AND switched_at IS NOT NULL AND overlap_until IS NOT NULL AND overlap_until > switched_at)),
  CONSTRAINT ck_credential_rotation_done CHECK ((state = 'DONE') = (done_at IS NOT NULL)),
  CONSTRAINT ck_credential_rotation_receipt CHECK (state <> 'DONE' OR (coalesce(char_length(revocation_receipt), 0) >= 5 AND revocation_confirmed_by IS NOT NULL AND revocation_confirmed_at IS NOT NULL)),
  CONSTRAINT ck_credential_rotation_cancel CHECK ((state = 'CANCELLED') = (cancel_reason IS NOT NULL))
);
CREATE UNIQUE INDEX uq_credential_rotation_open ON ph14_national.credential_rotation (tenant_id, platform_id, env) WHERE state NOT IN ('DONE', 'CANCELLED');
CREATE INDEX ix_credential_rotation_platform ON ph14_national.credential_rotation (tenant_id, platform_id, started_at DESC);
CREATE INDEX ix_credential_rotation_overlap ON ph14_national.credential_rotation (overlap_until) WHERE state = 'OVERLAP';
CREATE TRIGGER tg_credential_rotation_touch BEFORE UPDATE ON ph14_national.credential_rotation FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.credential_rotation', 'P');
COMMENT ON TABLE ph14_national.credential_rotation IS 'Trạng thái xoay vòng thông tin xác thực với nền tảng quốc gia, mỗi (nền tảng, môi trường) tối đa một lần xoay mở (FR-14-024, 025). Giá trị bí mật chỉ ở OpenBao qua PH-05; bảng chỉ lưu số phiên bản chờ và biên nhận thu hồi (BR-14-005, BR-14-034). Giữ vĩnh viễn để truy vết.';
COMMENT ON COLUMN ph14_national.credential_rotation.pending_secret_version IS 'Số phiên bản bí mật chờ ở PH-05 (OpenBao kv); không phải giá trị bí mật.';
COMMENT ON COLUMN ph14_national.credential_rotation.overlap_until IS 'Hết cửa sổ chuyển tiếp = switched_at + 14.secret.overlap-hours (mặc định 24 giờ).';
COMMENT ON COLUMN ph14_national.credential_rotation.revocation_receipt IS 'Số biên nhận hoặc văn bản xác nhận trung ương đã thu hồi khóa cũ; bắt buộc để DONE, và để đóng chạy song song (ERR-14-004).';
-- @rollback DROP TABLE IF EXISTS ph14_national.credential_rotation CASCADE;

-- @changeset ph14-0220-national-certificate
CREATE TABLE ph14_national.national_certificate (
  id                       uuid          NOT NULL,
  tenant_id                varchar(16)   NOT NULL,
  code                     varchar(63)   NOT NULL,
  platform_id              uuid,
  purpose                  varchar(10)   NOT NULL,
  subject                  varchar(500)  NOT NULL,
  issuer                   varchar(500)  NOT NULL,
  serial_number            varchar(64)   NOT NULL,
  fingerprint_sha256       char(64)      NOT NULL,
  not_before               timestamptz   NOT NULL,
  not_after                timestamptz   NOT NULL,
  key_ref                  varchar(255)  NOT NULL,
  public_chain             text          NOT NULL,
  state                    varchar(20)   NOT NULL DEFAULT 'UPLOADED',
  note                     varchar(500),
  uploaded_by              varchar(64)   NOT NULL,
  activation_requested_by  varchar(64),
  activation_requested_at  timestamptz,
  activation_approved_by   varchar(64),
  activation_approved_at   timestamptz,
  supersede_at             timestamptz,
  last_warned_days         integer,
  revoked_at               timestamptz,
  revoked_by               varchar(64),
  revoked_reason           varchar(500),
  created_at               timestamptz   NOT NULL DEFAULT now(),
  created_by               varchar(64)   NOT NULL,
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  updated_by               varchar(64)   NOT NULL,
  version                  integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_certificate PRIMARY KEY (id),
  CONSTRAINT uq_national_certificate_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_national_certificate_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_national_certificate_fingerprint UNIQUE (tenant_id, fingerprint_sha256),
  CONSTRAINT fk_national_certificate_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_national_certificate_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_national_certificate_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_national_certificate_purpose CHECK (purpose IN ('SIGNING', 'TLS_CLIENT', 'BOTH')),
  CONSTRAINT ck_national_certificate_fingerprint CHECK (fingerprint_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_national_certificate_validity CHECK (not_after > not_before),
  CONSTRAINT ck_national_certificate_key_ref CHECK (key_ref ~ ('^transit/keys/dh-' || lower(tenant_id) || '-[a-z0-9-]+$')),
  CONSTRAINT ck_national_certificate_no_private_key CHECK (public_chain NOT LIKE '%PRIVATE KEY%' AND octet_length(public_chain) <= 65536),
  CONSTRAINT ck_national_certificate_state CHECK (state IN ('UPLOADED', 'PENDING_ACTIVATION', 'ACTIVE', 'EXPIRING', 'EXPIRED', 'SUPERSEDED', 'REVOKED')),
  CONSTRAINT ck_national_certificate_requested CHECK (state <> 'PENDING_ACTIVATION' OR (activation_requested_by IS NOT NULL AND activation_requested_at IS NOT NULL)),
  CONSTRAINT ck_national_certificate_approved CHECK (state NOT IN ('ACTIVE', 'EXPIRING', 'EXPIRED', 'SUPERSEDED', 'REVOKED')
                                                      OR (activation_approved_by IS NOT NULL AND activation_approved_at IS NOT NULL)),
  CONSTRAINT ck_national_certificate_four_eyes CHECK (activation_approved_by IS NULL OR (activation_requested_by IS NOT NULL AND activation_approved_by <> activation_requested_by)),
  CONSTRAINT ck_national_certificate_supersede CHECK (supersede_at IS NULL OR state IN ('ACTIVE', 'EXPIRING', 'SUPERSEDED')),
  CONSTRAINT ck_national_certificate_revoked CHECK ((state = 'REVOKED') = (revoked_at IS NOT NULL) AND (state <> 'REVOKED' OR (revoked_by IS NOT NULL AND coalesce(char_length(revoked_reason), 0) >= 5)))
);
CREATE UNIQUE INDEX uq_national_certificate_signing ON ph14_national.national_certificate
  (tenant_id, coalesce(platform_id, '00000000-0000-0000-0000-000000000000'::uuid))
  WHERE state IN ('ACTIVE', 'EXPIRING') AND supersede_at IS NULL AND purpose IN ('SIGNING', 'BOTH');
CREATE UNIQUE INDEX uq_national_certificate_tls ON ph14_national.national_certificate
  (tenant_id, coalesce(platform_id, '00000000-0000-0000-0000-000000000000'::uuid))
  WHERE state IN ('ACTIVE', 'EXPIRING') AND supersede_at IS NULL AND purpose IN ('TLS_CLIENT', 'BOTH');
CREATE INDEX ix_national_certificate_expiry ON ph14_national.national_certificate (not_after) WHERE state IN ('ACTIVE', 'EXPIRING');
CREATE INDEX ix_national_certificate_platform ON ph14_national.national_certificate (tenant_id, platform_id, state);
CREATE TRIGGER tg_national_certificate_immutable BEFORE UPDATE ON ph14_national.national_certificate FOR EACH ROW
  EXECUTE FUNCTION ph14_national.tg_immutable('code', 'platform_id', 'purpose', 'subject', 'issuer', 'serial_number', 'fingerprint_sha256', 'not_before', 'not_after', 'key_ref', 'public_chain');
CREATE TRIGGER tg_national_certificate_nodelete BEFORE DELETE ON ph14_national.national_certificate FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_no_delete();
CREATE TRIGGER tg_national_certificate_touch BEFORE UPDATE ON ph14_national.national_certificate FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.national_certificate', 'P');
COMMENT ON TABLE ph14_national.national_certificate IS 'EN-14-05 Chứng thư số chuyên dùng công vụ để ký bản tin hoặc xác thực TLS khách (FR-14-026, 028, 029). Chỉ lưu chuỗi công khai và keyRef tới OpenBao transit; không có khóa riêng (BR-14-004). Không xóa chứng thư, kể cả đã hết hạn (BR-14-019).';
COMMENT ON COLUMN ph14_national.national_certificate.platform_id IS 'Rỗng: chứng thư dùng chung cho mọi nền tảng của tenant (FR-14-028).';
COMMENT ON COLUMN ph14_national.national_certificate.key_ref IS 'Tham chiếu khóa transit của đúng tenant, dạng transit/keys/dh-{tenant}-… ; ck_national_certificate_key_ref chặn trỏ sang khóa tenant khác (SEC-88).';
COMMENT ON COLUMN ph14_national.national_certificate.public_chain IS 'Chứng thư và chuỗi trung gian dạng PEM, ≤ 64 KB; CHECK chặn khối PRIVATE KEY lọt vào.';
COMMENT ON COLUMN ph14_national.national_certificate.supersede_at IS 'Thời điểm sẽ SUPERSEDED khi chứng thư mới cùng mục đích kích hoạt (= lúc kích hoạt + 14.cert.overlap-hours); trong lúc chờ chỉ dùng để xác minh, không ký (BR-14-017).';
COMMENT ON COLUMN ph14_national.national_certificate.last_warned_days IS 'Mốc cảnh báo hạn đã gửi gần nhất (60, 30 hoặc 7 ngày) để CertificateExpiryJob không gửi trùng.';
-- @rollback DROP TABLE IF EXISTS ph14_national.national_certificate CASCADE;

-- @changeset ph14-0230-trust-anchor
CREATE TABLE ph14_national.trust_anchor (
  id                       uuid          NOT NULL,
  tenant_id                varchar(16)   NOT NULL,
  code                     varchar(63)   NOT NULL,
  platform_id              uuid,
  name                     varchar(200)  NOT NULL,
  anchor_kind              varchar(12)   NOT NULL,
  subject                  varchar(500)  NOT NULL,
  issuer                   varchar(500)  NOT NULL,
  fingerprint_sha256       char(64)      NOT NULL,
  not_after                timestamptz   NOT NULL,
  pem                      text          NOT NULL,
  crl_url                  varchar(1000),
  ocsp_url                 varchar(1000),
  crl_ref                  varchar(255),
  crl_sha256               char(64),
  crl_this_update          timestamptz,
  crl_next_update          timestamptz,
  crl_refreshed_at         timestamptz,
  state                    varchar(20)   NOT NULL DEFAULT 'UPLOADED',
  uploaded_by              varchar(64)   NOT NULL,
  activation_requested_by  varchar(64),
  activation_approved_by   varchar(64),
  activation_approved_at   timestamptz,
  note                     varchar(500),
  created_at               timestamptz   NOT NULL DEFAULT now(),
  created_by               varchar(64)   NOT NULL,
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  updated_by               varchar(64)   NOT NULL,
  version                  integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_trust_anchor PRIMARY KEY (id),
  CONSTRAINT uq_trust_anchor_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_trust_anchor_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_trust_anchor_fingerprint UNIQUE (tenant_id, fingerprint_sha256),
  CONSTRAINT fk_trust_anchor_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_trust_anchor_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_trust_anchor_code CHECK (code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_trust_anchor_kind CHECK (anchor_kind IN ('ROOT', 'INTERMEDIATE')),
  CONSTRAINT ck_trust_anchor_fingerprint CHECK (fingerprint_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_trust_anchor_pem CHECK (pem NOT LIKE '%PRIVATE KEY%' AND octet_length(pem) <= 65536),
  CONSTRAINT ck_trust_anchor_state CHECK (state IN ('UPLOADED', 'PENDING_ACTIVATION', 'ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_trust_anchor_requested CHECK (state <> 'PENDING_ACTIVATION' OR activation_requested_by IS NOT NULL),
  CONSTRAINT ck_trust_anchor_approved CHECK (state NOT IN ('ACTIVE', 'EXPIRED', 'REVOKED') OR (activation_approved_by IS NOT NULL AND activation_approved_at IS NOT NULL)),
  CONSTRAINT ck_trust_anchor_four_eyes CHECK (activation_approved_by IS NULL OR (activation_requested_by IS NOT NULL AND activation_approved_by <> activation_requested_by)),
  CONSTRAINT ck_trust_anchor_crl CHECK (crl_next_update IS NULL OR (crl_this_update IS NOT NULL AND crl_next_update > crl_this_update)),
  CONSTRAINT ck_trust_anchor_crl_ref CHECK (crl_ref IS NULL OR (crl_ref LIKE (lower(tenant_id) || '/%') AND crl_sha256 IS NOT NULL AND crl_sha256 ~ '^[0-9a-f]{64}$'))
);
CREATE INDEX ix_trust_anchor_state ON ph14_national.trust_anchor (tenant_id, state, not_after);
CREATE INDEX ix_trust_anchor_crl_next ON ph14_national.trust_anchor (crl_next_update) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_trust_anchor_immutable BEFORE UPDATE ON ph14_national.trust_anchor FOR EACH ROW
  EXECUTE FUNCTION ph14_national.tg_immutable('code', 'platform_id', 'anchor_kind', 'subject', 'issuer', 'fingerprint_sha256', 'not_after', 'pem');
CREATE TRIGGER tg_trust_anchor_nodelete BEFORE DELETE ON ph14_national.trust_anchor FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_no_delete();
CREATE TRIGGER tg_trust_anchor_touch BEFORE UPDATE ON ph14_national.trust_anchor FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.trust_anchor', 'P');
COMMENT ON TABLE ph14_national.trust_anchor IS 'Chuỗi tin cậy: chứng thư gốc, trung gian của trung ương dùng xác minh phản hồi, kèm siêu dữ liệu CRL (FR-14-027, 030). Thay đổi neo cần bốn mắt (BR-14-018). Tệp CRL nằm ở bucket dh-nat-trust, bảng chỉ giữ khóa đối tượng và băm.';
COMMENT ON COLUMN ph14_national.trust_anchor.crl_ref IS 'Khóa đối tượng CRL ở bucket dh-nat-trust, bắt đầu bằng tiền tố tenant chữ thường.';
COMMENT ON COLUMN ph14_national.trust_anchor.crl_next_update IS 'nextUpdate của CRL; quá 14.crl.max-age-days thì cảnh báo mức cao, và theo 14.crl.fail-mode HARD thì từ chối xác minh.';
-- @rollback DROP TABLE IF EXISTS ph14_national.trust_anchor CASCADE;

-- @changeset ph14-0240-signature-incident
CREATE TABLE ph14_national.signature_incident (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  platform_id        uuid          NOT NULL,
  kind               varchar(20)   NOT NULL,
  direction          varchar(8)    NOT NULL,
  transaction_code   varchar(40),
  service_code       varchar(63),
  cert_fingerprint   char(64),
  detail             jsonb         NOT NULL DEFAULT '{}',
  state              varchar(12)   NOT NULL DEFAULT 'OPEN',
  assignee           varchar(64),
  classification     varchar(24),
  action_taken       varchar(24),
  conclusion         varchar(1000),
  hold_applied       boolean       NOT NULL DEFAULT false,
  detected_at        timestamptz   NOT NULL DEFAULT now(),
  acknowledged_by    varchar(64),
  acknowledged_at    timestamptz,
  resolved_by        varchar(64),
  resolved_at        timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         varchar(64)   NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         varchar(64)   NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_signature_incident PRIMARY KEY (id),
  CONSTRAINT uq_signature_incident_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_signature_incident_platform FOREIGN KEY (platform_id, tenant_id) REFERENCES ph14_national.national_platform (id, tenant_id),
  CONSTRAINT ck_signature_incident_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_signature_incident_kind CHECK (kind IN ('SIGNATURE_MISMATCH', 'UNTRUSTED_CHAIN', 'REVOKED_CERT', 'STALE_TIMESTAMP', 'REPLAY')),
  CONSTRAINT ck_signature_incident_direction CHECK (direction IN ('OUTBOUND', 'INBOUND')),
  CONSTRAINT ck_signature_incident_fingerprint CHECK (cert_fingerprint IS NULL OR cert_fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_signature_incident_detail CHECK (jsonb_typeof(detail) = 'object' AND NOT (detail ?| ARRAY['payload', 'body', 'password', 'secret', 'token', 'privateKey'])),
  CONSTRAINT ck_signature_incident_state CHECK (state IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED')),
  CONSTRAINT ck_signature_incident_classification CHECK (classification IS NULL OR classification IN ('CONFIG_ERROR', 'CERT_ROTATED_BY_CENTER', 'SUSPECTED_ATTACK')),
  CONSTRAINT ck_signature_incident_action CHECK (action_taken IS NULL OR action_taken IN ('REFRESH_TRUST', 'KEEP_BLOCK', 'OPEN_SECURITY_INCIDENT')),
  CONSTRAINT ck_signature_incident_ack CHECK (state = 'OPEN' OR (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)),
  CONSTRAINT ck_signature_incident_resolved CHECK ((state = 'RESOLVED') = (resolved_by IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT ck_signature_incident_conclusion CHECK (state <> 'RESOLVED' OR coalesce(char_length(conclusion), 0) >= 10)
);
CREATE INDEX ix_signature_incident_platform ON ph14_national.signature_incident (tenant_id, platform_id, detected_at DESC);
CREATE INDEX ix_signature_incident_open ON ph14_national.signature_incident (tenant_id, platform_id) WHERE state = 'OPEN';
CREATE INDEX ix_signature_incident_unresolved ON ph14_national.signature_incident (tenant_id, detected_at) WHERE state <> 'RESOLVED';
CREATE INDEX ix_signature_incident_txn ON ph14_national.signature_incident (tenant_id, transaction_code) WHERE transaction_code IS NOT NULL;
CREATE TRIGGER tg_signature_incident_immutable BEFORE UPDATE ON ph14_national.signature_incident FOR EACH ROW
  EXECUTE FUNCTION ph14_national.tg_immutable('platform_id', 'kind', 'direction', 'transaction_code', 'cert_fingerprint', 'detected_at');
CREATE TRIGGER tg_signature_incident_nodelete BEFORE DELETE ON ph14_national.signature_incident FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_no_delete();
CREATE TRIGGER tg_signature_incident_touch BEFORE UPDATE ON ph14_national.signature_incident FOR EACH ROW EXECUTE FUNCTION ph14_national.tg_touch();
CALL ph14_national.p_enable_rls('ph14_national.signature_incident', 'P');
COMMENT ON TABLE ph14_national.signature_incident IS 'EN-14-12 Sự cố chữ ký, chuỗi tin cậy, thời điểm ký hoặc phát lại: xử lý như sự cố an ninh (FR-14-027, 031, 040, BR-14-003). Giữ 5 năm, không xóa. Giải trừ SECURITY_HOLD chỉ khi không còn dòng OPEN (ERR-14-004).';
COMMENT ON COLUMN ph14_national.signature_incident.detail IS 'Dấu vết kỹ thuật đã che (mã lỗi thư viện, vị trí phần tử XML); không có thân bản tin, khóa hay chữ ký thô (BR-14-021).';
COMMENT ON COLUMN ph14_national.signature_incident.conclusion IS 'Kết luận xử lý, tối thiểu 10 ký tự để RESOLVED (ERR-14-003).';
-- @rollback DROP TABLE IF EXISTS ph14_national.signature_incident CASCADE;

RESET ROLE;
