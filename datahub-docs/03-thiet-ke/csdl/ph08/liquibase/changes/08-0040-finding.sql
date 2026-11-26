--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0040-finding.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0270-dq-finding
CREATE TABLE ph08_dq.dq_finding (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  last_seen_at         timestamptz NOT NULL DEFAULT now(),
  asset_id             uuid NOT NULL,
  rule_id              uuid NOT NULL,
  dimension            varchar(16) NOT NULL,
  severity             varchar(8) NOT NULL,
  fingerprint          bytea NOT NULL,
  record_key_hash      bytea NOT NULL,
  record_key_masked    varchar(255),
  field_name           varchar(63),
  data_class           varchar(16) NOT NULL DEFAULT 'INTERNAL',
  value_mode           varchar(16) NOT NULL DEFAULT 'MASKED',
  masked_value         varchar(255),
  value_hash           bytea,
  expected_hint        varchar(255),
  status               varchar(16) NOT NULL DEFAULT 'OPEN',
  owner_org_code       varchar(63) NOT NULL,
  first_seen_at        timestamptz NOT NULL DEFAULT now(),
  first_scan_job_id    uuid NOT NULL,
  last_scan_job_id     uuid NOT NULL,
  seen_count           integer NOT NULL DEFAULT 1,
  resolved_at          timestamptz,
  resolved_scan_job_id uuid,
  issue_id             uuid,
  waiver_id            uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_finding PRIMARY KEY (id, last_seen_at),
  CONSTRAINT ck_dq_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_finding_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_finding_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_finding_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_finding_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_finding_status CHECK (status IN ('OPEN', 'IN_REMEDIATION', 'RESOLVED', 'WAIVED')),
  CONSTRAINT ck_dq_finding_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_finding_mode CHECK (value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')),
  CONSTRAINT ck_dq_finding_fingerprint CHECK (octet_length(fingerprint) = 32),
  CONSTRAINT ck_dq_finding_key_hash CHECK (octet_length(record_key_hash) = 32),
  CONSTRAINT ck_dq_finding_value_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_dq_finding_no_raw CHECK ((data_class <> 'SENSITIVE' OR (value_mode = 'HASH_ONLY' AND masked_value IS NULL AND record_key_masked IS NULL AND expected_hint IS NULL)) AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN') AND (value_mode <> 'HASH_ONLY' OR masked_value IS NULL)),
  CONSTRAINT ck_dq_finding_seen CHECK (seen_count >= 1 AND last_seen_at >= first_seen_at),
  CONSTRAINT ck_dq_finding_resolved CHECK ((status = 'RESOLVED') = (resolved_at IS NOT NULL)),
  CONSTRAINT ck_dq_finding_remediation CHECK (status <> 'IN_REMEDIATION' OR issue_id IS NOT NULL),
  CONSTRAINT ck_dq_finding_waived CHECK ((status = 'WAIVED') = (waiver_id IS NOT NULL))
) PARTITION BY RANGE (last_seen_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_finding', current_date, 3);
CREATE INDEX ix_dq_finding_asset ON ph08_dq.dq_finding (tenant_id, asset_id, status, last_seen_at DESC);
CREATE INDEX ix_dq_finding_rule ON ph08_dq.dq_finding (tenant_id, rule_id, status);
CREATE INDEX ix_dq_finding_open ON ph08_dq.dq_finding (tenant_id, status, severity, last_seen_at DESC) WHERE status IN ('OPEN', 'IN_REMEDIATION');
CREATE INDEX ix_dq_finding_fp ON ph08_dq.dq_finding (tenant_id, fingerprint);
CREATE INDEX ix_dq_finding_key ON ph08_dq.dq_finding (tenant_id, asset_id, record_key_hash);
CREATE INDEX ix_dq_finding_issue ON ph08_dq.dq_finding (tenant_id, issue_id) WHERE issue_id IS NOT NULL;
CREATE INDEX ix_dq_finding_owner ON ph08_dq.dq_finding (tenant_id, owner_org_code, status, severity);
CREATE INDEX ix_dq_finding_scan ON ph08_dq.dq_finding (tenant_id, last_scan_job_id);
CREATE TRIGGER tg_dq_finding_touch BEFORE UPDATE ON ph08_dq.dq_finding FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_finding_immutable BEFORE UPDATE ON ph08_dq.dq_finding FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_id', 'fingerprint', 'record_key_hash', 'first_seen_at', 'first_scan_job_id', 'data_class');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_finding');
COMMENT ON TABLE ph08_dq.dq_finding IS 'EN-08-17 Bản ghi lỗi: một dòng cho mỗi lỗi còn tồn tại, nhận dạng bằng dấu vân tay fingerprint (băm khóa bản ghi và mã quy tắc) để biết mới, còn, hết qua các kỳ (FR-08-036, 037, 038, 039). Không lưu giá trị gốc: chỉ masked_value (đã che) và value_hash (băm có khóa); trường Nhạy cảm chỉ có băm. Phân vùng tháng theo last_seen_at, mỗi lần thấy lại dòng chuyển sang phân vùng mới.';
COMMENT ON COLUMN ph08_dq.dq_finding.fingerprint IS 'HMAC-SHA256 (khóa riêng từng tenant) của asset, mã quy tắc, khóa bản ghi; ổn định qua các kỳ (ADR đề xuất dải 085-089).';
COMMENT ON COLUMN ph08_dq.dq_finding.record_key_hash IS 'Băm có khóa của khóa bản ghi nguồn; tra theo đối tượng mà không lộ khóa.';
COMMENT ON COLUMN ph08_dq.dq_finding.masked_value IS 'Giá trị đã che theo chính sách PH-09, tối đa 255 ký tự; luôn rỗng với trường SENSITIVE. Không bao giờ chứa giá trị gốc.';
COMMENT ON COLUMN ph08_dq.dq_finding.value_hash IS 'Băm có khóa của giá trị gốc để biết giá trị có đổi giữa hai kỳ mà không lưu bản rõ.';
COMMENT ON COLUMN ph08_dq.dq_finding.last_seen_at IS 'Khóa phân vùng; cập nhật mỗi lần lỗi được thấy lại nên dòng có thể chuyển phân vùng (row movement).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_finding CASCADE;

--changeset ph08:ph08-0280-dq-waiver
CREATE TABLE ph08_dq.dq_waiver (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  asset_id         uuid NOT NULL,
  rule_id          uuid,
  fingerprint      bytea,
  status           varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  valid_from       date,
  valid_to         date,
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  revoke_reason    varchar(2000),
  expired_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_waiver PRIMARY KEY (id),
  CONSTRAINT uq_dq_waiver_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_waiver_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_waiver_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_waiver_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_waiver_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'EXPIRED', 'REVOKED', 'REJECTED')),
  CONSTRAINT ck_dq_waiver_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_dq_waiver_fingerprint CHECK (fingerprint IS NULL OR octet_length(fingerprint) = 32),
  CONSTRAINT ck_dq_waiver_target CHECK (rule_id IS NOT NULL OR fingerprint IS NOT NULL),
  CONSTRAINT ck_dq_waiver_four_eyes CHECK (decided_by IS NULL OR requested_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_dq_waiver_period CHECK (valid_to IS NULL OR valid_from IS NULL OR (valid_to > valid_from AND valid_to <= valid_from + 366)),
  CONSTRAINT ck_dq_waiver_active CHECK (status NOT IN ('ACTIVE', 'EXPIRED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND valid_from IS NOT NULL AND valid_to IS NOT NULL)),
  CONSTRAINT ck_dq_waiver_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false)),
  CONSTRAINT ck_dq_waiver_revoke CHECK (status <> 'REVOKED' OR (revoked_by IS NOT NULL AND COALESCE(char_length(revoke_reason) >= 20, false)))
);
CREATE INDEX ix_dq_waiver_asset ON ph08_dq.dq_waiver (tenant_id, asset_id, status);
CREATE INDEX ix_dq_waiver_expiry ON ph08_dq.dq_waiver (valid_to) WHERE status = 'ACTIVE';
CREATE INDEX ix_dq_waiver_fp ON ph08_dq.dq_waiver (tenant_id, fingerprint) WHERE fingerprint IS NOT NULL AND status = 'ACTIVE';
CREATE TRIGGER tg_dq_waiver_touch BEFORE UPDATE ON ph08_dq.dq_waiver FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_waiver_immutable BEFORE UPDATE ON ph08_dq.dq_waiver FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_id', 'fingerprint', 'reason', 'requested_by');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_waiver');
COMMENT ON TABLE ph08_dq.dq_waiver IS 'EN-08-18 Ngoại lệ chấp nhận (waiver): cho phép bỏ qua một lỗi hoặc một quy tắc có thời hạn, DA duyệt, lý do tối thiểu 20 ký tự (FR-08-040). Hết hạn thì lỗi mở lại.';
COMMENT ON COLUMN ph08_dq.dq_waiver.valid_to IS 'Tối đa 366 ngày sau valid_from; thời hạn tối đa theo tham số 08.waiver.max-days kiểm ở dịch vụ.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_waiver CASCADE;
