--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0040-masking.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0320-mask-type
CREATE TABLE ph09_privacy.mask_type (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  code           varchar(48) NOT NULL,
  mask_type      varchar(12) NOT NULL,
  pattern_kind   varchar(24),
  name           varchar(255) NOT NULL,
  default_params jsonb NOT NULL DEFAULT '{}',
  reversible     boolean NOT NULL DEFAULT false,
  builtin        boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_type PRIMARY KEY (id),
  CONSTRAINT uq_mask_type_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_type_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mask_type_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_mask_type_type CHECK (mask_type IN ('NONE', 'PARTIAL', 'REPLACE', 'KEYED_HASH', 'TOKENIZE', 'GENERALIZE', 'DROP')),
  CONSTRAINT ck_mask_type_pattern CHECK (pattern_kind IS NULL OR pattern_kind IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_mask_type_pairing CHECK ((mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL) AND (pattern_kind IS NULL OR (mask_type = 'PARTIAL') = (pattern_kind LIKE 'KEEP\_%'))),
  CONSTRAINT ck_mask_type_reversible CHECK (NOT reversible OR mask_type = 'TOKENIZE')
);
CREATE TRIGGER tg_mask_type_touch BEFORE UPDATE ON ph09_privacy.mask_type FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_type_immutable BEFORE UPDATE ON ph09_privacy.mask_type FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'mask_type', 'pattern_kind');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_type');
COMMENT ON TABLE ph09_privacy.mask_type IS 'EN-09-22 Kiểu che MaskType và mẫu che MaskPatternKind có tham số (FR-09-023, BR-09-021, 024): NONE, PARTIAL (KEEP_*), REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE (YEAR_ONLY, ADMIN_LEVEL), DROP. Nạp sẵn; tenant sửa tham số mặc định, thêm mẫu không đổi bộ kiểu.';
COMMENT ON COLUMN ph09_privacy.mask_type.default_params IS 'Tham số mặc định n, m, char, level (FR-09-023).';
--rollback DROP TABLE IF EXISTS ph09_privacy.mask_type CASCADE;

--changeset ph09:ph09-0330-mask-policy
CREATE TABLE ph09_privacy.mask_policy (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  policy_code          varchar(63) NOT NULL,
  version_no           integer NOT NULL,
  status               varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by         varchar(64),
  submitted_at         timestamptz,
  decided_by           varchar(64),
  decided_at           timestamptz,
  decision_comment     varchar(2000),
  activated_at         timestamptz,
  superseded_at        timestamptz,
  scope                varchar(8) NOT NULL DEFAULT 'TENANT',
  contract_kind        varchar(8),
  contract_id          varchar(128),
  description          varchar(2000),
  passed_simulation_id uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_policy PRIMARY KEY (id),
  CONSTRAINT uq_mask_policy_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_mask_policy_code CHECK (policy_code ~ '^[A-Za-z][A-Za-z0-9-]{2,62}$'),
  CONSTRAINT ck_mask_policy_scope CHECK (scope IN ('TENANT', 'CONTRACT') AND ((scope = 'CONTRACT') = (contract_id IS NOT NULL AND contract_kind IS NOT NULL))),
  CONSTRAINT ck_mask_policy_kind CHECK (contract_kind IS NULL OR contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_mask_policy_simulated CHECK (status NOT IN ('PENDING_APPROVAL', 'ACTIVE') OR passed_simulation_id IS NOT NULL),
  CONSTRAINT uq_mask_policy_version UNIQUE (tenant_id, policy_code, version_no),
  CONSTRAINT ck_mask_policy_version CHECK (version_no >= 1),
  CONSTRAINT ck_mask_policy_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_mask_policy_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_mask_policy_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_mask_policy_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_mask_policy_active ON ph09_privacy.mask_policy (tenant_id, policy_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_mask_policy_touch BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_policy_immutable BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('policy_code', 'version_no', 'scope', 'contract_id');
CREATE TRIGGER tg_mask_policy_frozen BEFORE UPDATE ON ph09_privacy.mask_policy FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('passed_simulation_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_policy');
COMMENT ON TABLE ph09_privacy.mask_policy IS 'EN-09-23 Chính sách che theo phiên bản (FR-09-024, 026, BR-09-022, 023): phạm vi TENANT hoặc CONTRACT. Kích hoạt cần mô phỏng đạt (passed_simulation_id) và người duyệt khác người soạn (ADR-046). Quay lại bản cũ là tạo phiên bản mới.';
--rollback DROP TABLE IF EXISTS ph09_privacy.mask_policy CASCADE;

--changeset ph09:ph09-0340-mask-rule
CREATE TABLE ph09_privacy.mask_rule (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  policy_id     uuid NOT NULL,
  seq           smallint NOT NULL,
  priority      smallint NOT NULL DEFAULT 100,
  cond_class    varchar(16),
  cond_category varchar(32),
  cond_roles    varchar(16)[],
  cond_purpose  varchar(41),
  cond_channel  varchar(8),
  mask_type     varchar(12) NOT NULL,
  pattern_kind  varchar(24),
  params        jsonb NOT NULL DEFAULT '{}',
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_rule PRIMARY KEY (id),
  CONSTRAINT ck_mask_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_mask_rule_policy FOREIGN KEY (tenant_id, policy_id) REFERENCES ph09_privacy.mask_policy (tenant_id, id),
  CONSTRAINT uq_mask_rule_seq UNIQUE (tenant_id, policy_id, seq),
  CONSTRAINT ck_mask_rule_priority CHECK (priority BETWEEN 1 AND 999),
  CONSTRAINT ck_mask_rule_class CHECK (cond_class IS NULL OR cond_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_mask_rule_channel CHECK (cond_channel IS NULL OR cond_channel IN ('UI', 'API', 'EXPORT', 'LOG', 'FLOW')),
  CONSTRAINT ck_mask_rule_type CHECK (mask_type IN ('NONE', 'PARTIAL', 'REPLACE', 'KEYED_HASH', 'TOKENIZE', 'GENERALIZE', 'DROP')),
  CONSTRAINT ck_mask_rule_pattern CHECK (pattern_kind IS NULL OR pattern_kind IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_mask_rule_pairing CHECK ((mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL)),
  CONSTRAINT ck_mask_rule_sensitive CHECK (cond_class IS DISTINCT FROM 'SENSITIVE' OR mask_type <> 'NONE')
);
CREATE INDEX ix_mask_rule_policy ON ph09_privacy.mask_rule (tenant_id, policy_id, priority DESC);
CREATE TRIGGER tg_mask_rule_touch BEFORE UPDATE ON ph09_privacy.mask_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.mask_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('mask_policy', 'policy_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_rule');
COMMENT ON TABLE ph09_privacy.mask_rule IS 'EN-09-24 Quy tắc che trong chính sách (FR-09-024, BR-09-021, 022): điều kiện (mức, loại DLCN, vai trò, mục đích, kênh), kiểu che, tham số, độ ưu tiên; quy tắc cụ thể hơn thắng, trùng thì kiểu chặt hơn thắng. Mức SENSITIVE không được NONE. Chỉ sửa khi chính sách DRAFT hoặc REJECTED.';
COMMENT ON COLUMN ph09_privacy.mask_rule.cond_roles IS 'Mã vai trò viết tắt (PA, TA, DS, VW...); rỗng là mọi vai trò.';
--rollback DROP TABLE IF EXISTS ph09_privacy.mask_rule CASCADE;

--changeset ph09:ph09-0350-mask-simulation
CREATE TABLE ph09_privacy.mask_simulation (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  policy_id      uuid NOT NULL,
  policy_version integer NOT NULL,
  sample_ref     varchar(512) NOT NULL,
  sample_rows    integer NOT NULL,
  role           varchar(16),
  purpose_code   varchar(41),
  channel        varchar(8),
  result         jsonb NOT NULL DEFAULT '{}',
  passed         boolean NOT NULL DEFAULT false,
  run_by         varchar(64) NOT NULL,
  run_at         timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mask_simulation PRIMARY KEY (id),
  CONSTRAINT uq_mask_simulation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_mask_simulation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_mask_simulation_policy FOREIGN KEY (tenant_id, policy_id) REFERENCES ph09_privacy.mask_policy (tenant_id, id),
  CONSTRAINT ck_mask_simulation_rows CHECK (sample_rows BETWEEN 1 AND 1000),
  CONSTRAINT ck_mask_simulation_channel CHECK (channel IS NULL OR channel IN ('UI', 'API', 'EXPORT', 'LOG', 'FLOW'))
);
CREATE INDEX ix_mask_simulation_policy ON ph09_privacy.mask_simulation (tenant_id, policy_id, run_at DESC);
CREATE TRIGGER tg_mask_simulation_touch BEFORE UPDATE ON ph09_privacy.mask_simulation FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_mask_simulation_immutable BEFORE UPDATE ON ph09_privacy.mask_simulation FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('policy_id', 'policy_version', 'sample_ref', 'passed');
CALL ph09_privacy.p_enable_rls('ph09_privacy.mask_simulation');
COMMENT ON TABLE ph09_privacy.mask_simulation IS 'EN-09-25 Lần mô phỏng chính sách che trên bộ mẫu dữ liệu giả ≤ 1.000 dòng (FR-09-025, NFR-09-023): bộ mẫu ở Garage, kết quả tóm tắt, passed. Không lưu giá trị mẫu trong bảng (BR-09-025).';
ALTER TABLE ph09_privacy.mask_policy ADD CONSTRAINT fk_mask_policy_simulation FOREIGN KEY (tenant_id, passed_simulation_id) REFERENCES ph09_privacy.mask_simulation (tenant_id, id);
--rollback DROP TABLE IF EXISTS ph09_privacy.mask_simulation CASCADE;

--changeset ph09:ph09-0360-reveal-grant
CREATE TABLE ph09_privacy.reveal_grant (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  requested_by varchar(64) NOT NULL,
  target_ref   varchar(255) NOT NULL,
  fields       varchar(63)[] NOT NULL,
  reason       varchar(2000) NOT NULL,
  status       varchar(8) NOT NULL DEFAULT 'ISSUED',
  issued_at    timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  verified_at  timestamptz,
  token_hash   bytea NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_reveal_grant PRIMARY KEY (id),
  CONSTRAINT ck_reveal_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_reveal_grant_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_reveal_grant_status CHECK (status IN ('ISSUED', 'VERIFIED', 'EXPIRED')),
  CONSTRAINT ck_reveal_grant_ttl CHECK (expires_at > issued_at AND expires_at <= issued_at + interval '60 seconds'),
  CONSTRAINT ck_reveal_grant_fields CHECK (cardinality(fields) BETWEEN 1 AND 50),
  CONSTRAINT ck_reveal_grant_hash CHECK (octet_length(token_hash) = 32),
  CONSTRAINT ck_reveal_grant_verified CHECK ((status = 'VERIFIED') = (verified_at IS NOT NULL))
);
CREATE INDEX ix_reveal_grant_user ON ph09_privacy.reveal_grant (tenant_id, requested_by, issued_at DESC);
CREATE TRIGGER tg_reveal_grant_touch BEFORE UPDATE ON ph09_privacy.reveal_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_reveal_grant_immutable BEFORE UPDATE ON ph09_privacy.reveal_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('requested_by', 'target_ref', 'fields', 'reason', 'issued_at', 'expires_at', 'token_hash');
CALL ph09_privacy.p_enable_rls('ph09_privacy.reveal_grant');
COMMENT ON TABLE ph09_privacy.reveal_grant IS 'EN-09-26 Phiếu xem giá trị đầy đủ (FR-09-029, BR-09-026): người xin, đối tượng, trường, lý do ≥ 20 ký tự, hết hạn đúng ≤ 60 giây, tối đa 20 lần mỗi giờ. Chỉ lưu băm phiếu; giá trị rõ không ghi đĩa; trường never_reveal bị chặn ở dịch vụ. Thao tác bị từ chối nếu không ghi được kiểm toán (BR-09-057).';
--rollback DROP TABLE IF EXISTS ph09_privacy.reveal_grant CASCADE;

--changeset ph09:ph09-0370-log-mask-config
CREATE TABLE ph09_privacy.log_mask_config (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  allow_attributes  varchar(63)[] NOT NULL DEFAULT '{}',
  patterns          varchar(24)[] NOT NULL,
  scan_window_hours smallint NOT NULL DEFAULT 24,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_log_mask_config PRIMARY KEY (id),
  CONSTRAINT ck_log_mask_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_log_mask_config_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_log_mask_config_patterns CHECK (cardinality(patterns) >= 1 AND patterns <@ ARRAY['NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT']::varchar[]),
  CONSTRAINT ck_log_mask_config_window CHECK (scan_window_hours BETWEEN 1 AND 168)
);
CREATE TRIGGER tg_log_mask_config_touch BEFORE UPDATE ON ph09_privacy.log_mask_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.log_mask_config');
COMMENT ON TABLE ph09_privacy.log_mask_config IS 'EN-09-27 Cấu hình che log, trace (FR-09-030, SEC-32): danh sách thuộc tính được phép, mẫu quét, cửa sổ quét. Một dòng mỗi tenant.';
--rollback DROP TABLE IF EXISTS ph09_privacy.log_mask_config CASCADE;

--changeset ph09:ph09-0380-leak-finding
CREATE TABLE ph09_privacy.leak_finding (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  source        varchar(128) NOT NULL,
  detector_code varchar(24) NOT NULL,
  match_count   integer NOT NULL,
  fingerprint   bytea NOT NULL,
  first_seen_at timestamptz NOT NULL,
  last_seen_at  timestamptz NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'OPEN',
  resolved_by   varchar(64),
  resolved_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_leak_finding PRIMARY KEY (id),
  CONSTRAINT ck_leak_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_leak_finding_fp UNIQUE (tenant_id, source, detector_code, fingerprint),
  CONSTRAINT ck_leak_finding_detector CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_leak_finding_status CHECK (status IN ('OPEN', 'CONFIRMED_PII', 'EXCLUDED', 'CLASSIFIED')),
  CONSTRAINT ck_leak_finding_count CHECK (match_count >= 1 AND last_seen_at >= first_seen_at AND octet_length(fingerprint) = 32),
  CONSTRAINT ck_leak_finding_resolved CHECK (status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE INDEX ix_leak_finding_open ON ph09_privacy.leak_finding (tenant_id, last_seen_at DESC) WHERE status = 'OPEN';
CREATE TRIGGER tg_leak_finding_touch BEFORE UPDATE ON ph09_privacy.leak_finding FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.leak_finding');
COMMENT ON TABLE ph09_privacy.leak_finding IS 'EN-09-28 Kết quả quét rò rỉ DLCN trong log, trace (FR-09-030, NFR-09-014): nguồn, mẫu khớp, số lần, dấu vân HMAC của vị trí. Không lưu đoạn log khớp. Trạng thái FindingStatus.';
--rollback DROP TABLE IF EXISTS ph09_privacy.leak_finding CASCADE;
