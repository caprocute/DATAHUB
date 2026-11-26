--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0050-pseudonym.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0390-pseudonym-domain
CREATE TABLE ph09_privacy.pseudonym_domain (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_code         varchar(41) NOT NULL,
  purpose_code        varchar(41) NOT NULL,
  method              varchar(16) NOT NULL,
  rotate_days         smallint NOT NULL DEFAULT 365,
  description         varchar(2000),
  status              varchar(12) NOT NULL DEFAULT 'ACTIVE',
  key_name            varchar(128) NOT NULL,
  current_key_version integer NOT NULL DEFAULT 1,
  last_rotated_at     timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_pseudonym_domain PRIMARY KEY (id),
  CONSTRAINT uq_pseudonym_domain_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_pseudonym_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_pseudonym_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT fk_pseudonym_domain_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_pseudonym_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT ck_pseudonym_domain_method CHECK (method IN ('HMAC_SHA256', 'TOKEN_TRANSIT')),
  CONSTRAINT ck_pseudonym_domain_rotate CHECK (rotate_days BETWEEN 90 AND 730),
  CONSTRAINT ck_pseudonym_domain_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_pseudonym_domain_version CHECK (current_key_version >= 1)
);
CREATE TRIGGER tg_pseudonym_domain_touch BEFORE UPDATE ON ph09_privacy.pseudonym_domain FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_pseudonym_domain_immutable BEFORE UPDATE ON ph09_privacy.pseudonym_domain FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_code', 'purpose_code', 'method', 'key_name');
CALL ph09_privacy.p_enable_rls('ph09_privacy.pseudonym_domain');
COMMENT ON TABLE ph09_privacy.pseudonym_domain IS 'EN-09-29 Miền giả danh hóa theo tenant và mục đích (FR-09-031, BR-09-028, 031): phương pháp PseudonymMethod, chu kỳ xoay 90 đến 730 ngày, trạng thái. Khóa riêng mỗi miền nên hai tập cho hai mục đích không nối được. Không có bảng ánh xạ bí danh (BR-09-030).';
COMMENT ON COLUMN ph09_privacy.pseudonym_domain.key_name IS 'Tên khóa transit OpenBao dh-{tenant}-pseudo-{miền}; không chứa vật liệu khóa.';
--rollback DROP TABLE IF EXISTS ph09_privacy.pseudonym_domain CASCADE;

--changeset ph09:ph09-0400-pseudonym-key
CREATE TABLE ph09_privacy.pseudonym_key (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_id            uuid NOT NULL,
  key_version          integer NOT NULL,
  status               varchar(12) NOT NULL DEFAULT 'ACTIVE',
  openbao_ref          varchar(255) NOT NULL,
  activated_at         timestamptz NOT NULL DEFAULT now(),
  disabled_at          timestamptz,
  destroy_requested_by varchar(64),
  destroy_approved_by  varchar(64),
  destroy_not_before   timestamptz,
  destroyed_at         timestamptz,
  reason               varchar(2000),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_pseudonym_key PRIMARY KEY (id),
  CONSTRAINT uq_pseudonym_key_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_pseudonym_key_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_pseudonym_key_domain FOREIGN KEY (tenant_id, domain_id) REFERENCES ph09_privacy.pseudonym_domain (tenant_id, id),
  CONSTRAINT uq_pseudonym_key_version UNIQUE (tenant_id, domain_id, key_version),
  CONSTRAINT ck_pseudonym_key_version CHECK (key_version >= 1),
  CONSTRAINT ck_pseudonym_key_status CHECK (status IN ('ACTIVE', 'DECRYPT_ONLY', 'DISABLED', 'DESTROYED')),
  CONSTRAINT ck_pseudonym_key_ref CHECK (openbao_ref ~ '^transit/keys/[a-z0-9-]+$'),
  CONSTRAINT ck_pseudonym_key_destroyed CHECK (status <> 'DESTROYED' OR (destroyed_at IS NOT NULL AND destroy_requested_by IS NOT NULL AND destroy_approved_by IS NOT NULL AND destroy_approved_by <> destroy_requested_by AND destroy_not_before IS NOT NULL AND destroyed_at >= destroy_not_before)),
  CONSTRAINT ck_pseudonym_key_disabled CHECK (status NOT IN ('DISABLED', 'DESTROYED') OR disabled_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_pseudonym_key_active ON ph09_privacy.pseudonym_key (tenant_id, domain_id) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_pseudonym_key_touch BEFORE UPDATE ON ph09_privacy.pseudonym_key FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_pseudonym_key_immutable BEFORE UPDATE ON ph09_privacy.pseudonym_key FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_id', 'key_version', 'openbao_ref');
CALL ph09_privacy.p_enable_rls('ph09_privacy.pseudonym_key');
COMMENT ON TABLE ph09_privacy.pseudonym_key IS 'EN-09-30 Siêu dữ liệu phiên bản khóa giả danh hóa (FR-09-034, BR-09-029, 033): ACTIVE, DECRYPT_ONLY, DISABLED, DESTROYED. Không chứa vật liệu khóa. Hủy cần hai người duyệt khác nhau và chờ ≥ 7 ngày; mỗi miền một phiên bản ACTIVE.';
--rollback DROP TABLE IF EXISTS ph09_privacy.pseudonym_key CASCADE;

--changeset ph09:ph09-0410-reidentification-request
CREATE TABLE ph09_privacy.reidentification_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_id           uuid NOT NULL,
  token_count         smallint NOT NULL,
  tokens_digest       bytea NOT NULL,
  purpose_code        varchar(41) NOT NULL,
  basis               varchar(500) NOT NULL,
  reason              varchar(2000) NOT NULL,
  status              varchar(12) NOT NULL DEFAULT 'PENDING_L1',
  requested_by        varchar(64) NOT NULL,
  mfa_verified        boolean NOT NULL DEFAULT false,
  l1_by               varchar(64),
  l1_at               timestamptz,
  l2_by               varchar(64),
  l2_at               timestamptz,
  approval_expires_at timestamptz NOT NULL,
  exec_deadline_at    timestamptz,
  executed_by         varchar(64),
  executed_at         timestamptz,
  reject_reason       varchar(2000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_reidentification_request PRIMARY KEY (id),
  CONSTRAINT ck_reidentification_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_reidentification_request_domain FOREIGN KEY (tenant_id, domain_id) REFERENCES ph09_privacy.pseudonym_domain (tenant_id, id),
  CONSTRAINT fk_reidentification_request_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_reidentification_request_count CHECK (token_count BETWEEN 1 AND 100 AND octet_length(tokens_digest) = 32),
  CONSTRAINT ck_reidentification_request_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_reidentification_request_status CHECK (status IN ('PENDING_L1', 'PENDING_L2', 'APPROVED', 'EXECUTED', 'REJECTED', 'EXPIRED')),
  CONSTRAINT ck_reidentification_request_l1 CHECK (l1_by IS NULL OR (l1_by <> requested_by AND l1_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_l2 CHECK (l2_by IS NULL OR (l1_by IS NOT NULL AND l2_by <> l1_by AND l2_by <> requested_by AND l2_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_approved CHECK (status NOT IN ('APPROVED', 'EXECUTED') OR (l1_by IS NOT NULL AND l2_by IS NOT NULL AND mfa_verified AND exec_deadline_at IS NOT NULL)),
  CONSTRAINT ck_reidentification_request_executed CHECK (status <> 'EXECUTED' OR (executed_by IS NOT NULL AND executed_at IS NOT NULL AND executed_at <= exec_deadline_at)),
  CONSTRAINT ck_reidentification_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL)
);
CREATE INDEX ix_reidentification_request_open ON ph09_privacy.reidentification_request (tenant_id, status, created_at DESC) WHERE status IN ('PENDING_L1', 'PENDING_L2', 'APPROVED');
CREATE TRIGGER tg_reidentification_request_touch BEFORE UPDATE ON ph09_privacy.reidentification_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_reidentification_request_immutable BEFORE UPDATE ON ph09_privacy.reidentification_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('domain_id', 'token_count', 'tokens_digest', 'purpose_code', 'basis', 'requested_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.reidentification_request');
COMMENT ON TABLE ph09_privacy.reidentification_request IS 'EN-09-31 Đề nghị khôi phục giá trị gốc từ token (FR-09-033, BR-09-032, 057): ≤ 100 giá trị, mục đích, căn cứ, MFA, hai cấp duyệt khác nhau và khác người đề nghị, hạn duyệt 24 giờ, cửa sổ thực hiện 30 phút. Không lưu token hay giá trị, chỉ số lượng và băm danh sách. Kiểm toán WORM vĩnh viễn.';
COMMENT ON COLUMN ph09_privacy.reidentification_request.tokens_digest IS 'Băm SHA-256 danh sách token để đối chiếu khi thực hiện; không lưu token.';
--rollback DROP TABLE IF EXISTS ph09_privacy.reidentification_request CASCADE;

--changeset ph09:ph09-0420-anonymization-config
CREATE TABLE ph09_privacy.anonymization_config (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  config_code      varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  privacy_model    varchar(16) NOT NULL DEFAULT 'K_ANONYMITY',
  k                smallint NOT NULL DEFAULT 10,
  l                smallint,
  rules            jsonb NOT NULL,
  hierarchies      jsonb NOT NULL DEFAULT '{}',
  purpose_code     varchar(41) NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymization_config PRIMARY KEY (id),
  CONSTRAINT uq_anonymization_config_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymization_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_anonymization_config_code CHECK (config_code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_anonymization_config_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymization_config_model CHECK (privacy_model IN ('K_ANONYMITY', 'L_DIVERSITY')),
  CONSTRAINT ck_anonymization_config_k CHECK (k BETWEEN 10 AND 100),
  CONSTRAINT ck_anonymization_config_l CHECK ((privacy_model = 'L_DIVERSITY') = (l IS NOT NULL) AND (l IS NULL OR l BETWEEN 2 AND k)),
  CONSTRAINT ck_anonymization_config_rules CHECK (jsonb_typeof(rules) = 'array' AND jsonb_array_length(rules) BETWEEN 1 AND 200),
  CONSTRAINT uq_anonymization_config_version UNIQUE (tenant_id, config_code, version_no),
  CONSTRAINT ck_anonymization_config_version CHECK (version_no >= 1),
  CONSTRAINT ck_anonymization_config_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_anonymization_config_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_anonymization_config_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_anonymization_config_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_anonymization_config_active ON ph09_privacy.anonymization_config (tenant_id, config_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_anonymization_config_touch BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_anonymization_config_immutable BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('config_code', 'version_no');
CREATE TRIGGER tg_anonymization_config_frozen BEFORE UPDATE ON ph09_privacy.anonymization_config FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('privacy_model', 'k', 'l', 'rules', 'hierarchies', 'purpose_code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymization_config');
COMMENT ON TABLE ph09_privacy.anonymization_config IS 'EN-09-32 Cấu hình ẩn danh hóa theo phiên bản (FR-09-035, BR-09-035, 036): k ≥ 10 (sàn 09.anon.k-min, SEC-38), l-đa dạng tùy chọn, quy tắc theo trường với AnonTransform, phân cấp tổng quát hóa, mục đích. Định danh trực tiếp bị loại, bán định danh được tổng quát hóa.';
COMMENT ON COLUMN ph09_privacy.anonymization_config.rules IS 'Mảng {field, transform, params}; transform là AnonTransform (kiểm ở dịch vụ khi gửi duyệt).';
--rollback DROP TABLE IF EXISTS ph09_privacy.anonymization_config CASCADE;

--changeset ph09:ph09-0430-anonymization-job
CREATE TABLE ph09_privacy.anonymization_job (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  config_id             uuid NOT NULL,
  source_ref            varchar(512) NOT NULL,
  purpose_code          varchar(41) NOT NULL,
  target                varchar(16),
  status                varchar(24) NOT NULL DEFAULT 'QUEUED',
  requested_by          varchar(64) NOT NULL,
  rows_before           bigint,
  rows_after            bigint,
  k_actual              smallint,
  generalization_rounds smallint NOT NULL DEFAULT 0,
  output_ref            varchar(512),
  started_at            timestamptz,
  finished_at           timestamptz,
  error_code            varchar(10),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymization_job PRIMARY KEY (id),
  CONSTRAINT uq_anonymization_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymization_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_anonymization_job_config FOREIGN KEY (tenant_id, config_id) REFERENCES ph09_privacy.anonymization_config (tenant_id, id),
  CONSTRAINT fk_anonymization_job_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymization_job_target CHECK (target IS NULL OR target IN ('AI_TRAINING', 'NON_PROD_TEST', 'OPEN_DATA')),
  CONSTRAINT ck_anonymization_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'AWAITING_RISK_REVIEW', 'COMPLETED', 'REJECTED_RISK', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_anonymization_job_rows CHECK (rows_before >= 0 AND rows_after >= 0 AND rows_after <= rows_before),
  CONSTRAINT ck_anonymization_job_keep CHECK (rows_before IS NULL OR rows_before = 0 OR rows_after IS NULL OR rows_after * 10 >= rows_before * 3 OR status IN ('REJECTED_RISK', 'FAILED', 'CANCELLED', 'RUNNING', 'QUEUED')),
  CONSTRAINT ck_anonymization_job_rounds CHECK (generalization_rounds BETWEEN 0 AND 3),
  CONSTRAINT ck_anonymization_job_k CHECK (k_actual IS NULL OR k_actual >= 1),
  CONSTRAINT ck_anonymization_job_done CHECK (status NOT IN ('COMPLETED') OR (k_actual >= 10 AND output_ref IS NOT NULL AND finished_at IS NOT NULL)),
  CONSTRAINT ck_anonymization_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$')
);
CREATE INDEX ix_anonymization_job_status ON ph09_privacy.anonymization_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_anonymization_job_touch BEFORE UPDATE ON ph09_privacy.anonymization_job FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymization_job');
COMMENT ON TABLE ph09_privacy.anonymization_job IS 'EN-09-33 Job ẩn danh hóa (FR-09-036, 038, BR-09-034, 035): tập nguồn, cấu hình, trạng thái AnonJobStatus, số bản ghi trước và sau (còn ≥ 30%), k thực tế, tối đa 3 vòng tổng quát hóa. Không lưu ánh xạ, không giữ khóa giải. Tập ra ở Garage mã hóa SSE-C.';
--rollback DROP TABLE IF EXISTS ph09_privacy.anonymization_job CASCADE;

--changeset ph09:ph09-0440-risk-report
CREATE TABLE ph09_privacy.risk_report (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  job_id            uuid,
  dataset_ref       varchar(512) NOT NULL,
  risk_model        varchar(12) NOT NULL,
  quasi_identifiers varchar(63)[] NOT NULL,
  k_actual          smallint NOT NULL,
  small_group_ratio numeric(6,5) NOT NULL,
  risk_value        numeric(6,5) NOT NULL,
  level             varchar(8) NOT NULL,
  risk_fields       varchar(63)[] NOT NULL DEFAULT '{}',
  recommendation    varchar(2000),
  computed_at       timestamptz NOT NULL DEFAULT now(),
  approved_by       varchar(64),
  approved_at       timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_risk_report PRIMARY KEY (id),
  CONSTRAINT uq_risk_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_risk_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_risk_report_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph09_privacy.anonymization_job (tenant_id, id),
  CONSTRAINT ck_risk_report_model CHECK (risk_model IN ('PROSECUTOR', 'JOURNALIST', 'MARKETER')),
  CONSTRAINT ck_risk_report_level CHECK (level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_risk_report_ratio CHECK (small_group_ratio BETWEEN 0 AND 1 AND risk_value BETWEEN 0 AND 1 AND k_actual >= 1),
  CONSTRAINT ck_risk_report_approval CHECK ((approved_by IS NULL) = (approved_at IS NULL))
);
CREATE INDEX ix_risk_report_job ON ph09_privacy.risk_report (tenant_id, job_id, computed_at DESC);
CREATE TRIGGER tg_risk_report_touch BEFORE UPDATE ON ph09_privacy.risk_report FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.risk_report');
COMMENT ON TABLE ph09_privacy.risk_report IS 'EN-09-34 Báo cáo rủi ro tái định danh (FR-09-037, BR-09-035): mô hình RiskModel, kActual, tỷ lệ nhóm nhỏ, mức RiskLevel (MEDIUM từ 0,05, HIGH từ 0,10 mặc định), trường gây rủi ro, khuyến nghị. Mức MEDIUM cần SO duyệt trước khi phát hành.';
--rollback DROP TABLE IF EXISTS ph09_privacy.risk_report CASCADE;

--changeset ph09:ph09-0450-anonymized-dataset
CREATE TABLE ph09_privacy.anonymized_dataset (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  job_id          uuid NOT NULL,
  risk_report_id  uuid NOT NULL,
  name            varchar(255) NOT NULL,
  storage_ref     varchar(512) NOT NULL,
  purpose_code    varchar(41) NOT NULL,
  target          varchar(16) NOT NULL,
  terms           jsonb NOT NULL,
  k_actual        smallint NOT NULL,
  risk_level      varchar(8) NOT NULL,
  approved_by     varchar(64),
  status          varchar(10) NOT NULL DEFAULT 'READY',
  expires_on      date,
  published_at    timestamptz,
  withdrawn_at    timestamptz,
  withdraw_reason varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_anonymized_dataset PRIMARY KEY (id),
  CONSTRAINT uq_anonymized_dataset_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_anonymized_dataset_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_anonymized_dataset_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph09_privacy.anonymization_job (tenant_id, id),
  CONSTRAINT fk_anonymized_dataset_risk_report FOREIGN KEY (tenant_id, risk_report_id) REFERENCES ph09_privacy.risk_report (tenant_id, id),
  CONSTRAINT fk_anonymized_dataset_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_anonymized_dataset_target CHECK (target IN ('AI_TRAINING', 'NON_PROD_TEST', 'OPEN_DATA')),
  CONSTRAINT ck_anonymized_dataset_status CHECK (status IN ('READY', 'PUBLISHED', 'WITHDRAWN', 'EXPIRED')),
  CONSTRAINT ck_anonymized_dataset_risk CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_anonymized_dataset_terms CHECK (jsonb_typeof(terms) = 'object'),
  CONSTRAINT ck_anonymized_dataset_published CHECK (status <> 'PUBLISHED' OR (k_actual >= 10 AND risk_level <> 'HIGH' AND (risk_level <> 'MEDIUM' OR approved_by IS NOT NULL) AND published_at IS NOT NULL AND expires_on IS NOT NULL)),
  CONSTRAINT ck_anonymized_dataset_withdrawn CHECK (status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdraw_reason IS NOT NULL))
);
CREATE INDEX ix_anonymized_dataset_status ON ph09_privacy.anonymized_dataset (tenant_id, status, expires_on);
CREATE TRIGGER tg_anonymized_dataset_touch BEFORE UPDATE ON ph09_privacy.anonymized_dataset FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_anonymized_dataset_immutable BEFORE UPDATE ON ph09_privacy.anonymized_dataset FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('job_id', 'storage_ref', 'k_actual');
CALL ph09_privacy.p_enable_rls('ph09_privacy.anonymized_dataset');
COMMENT ON TABLE ph09_privacy.anonymized_dataset IS 'EN-09-35 Tập đã ẩn danh (FR-09-038, 039, BR-09-034, 035, 037): vị trí lưu, mục đích, điều kiện sử dụng (mục đích được phép, bên nhận, cấm tái định danh), hạn dùng, DatasetStatus. PUBLISHED cần k ≥ 10, rủi ro không HIGH, MEDIUM thì có người duyệt.';
--rollback DROP TABLE IF EXISTS ph09_privacy.anonymized_dataset CASCADE;
