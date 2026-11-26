--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0010-model.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0100-mdm-domain
CREATE TABLE ph06_mdm.mdm_domain (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  name             varchar(255) NOT NULL,
  description      varchar(2000),
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  baseline         boolean NOT NULL DEFAULT false,
  baseline_package varchar(32),
  status_reason    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mdm_domain PRIMARY KEY (id),
  CONSTRAINT ck_mdm_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mdm_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT ck_mdm_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_mdm_domain_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_mdm_domain_reason CHECK (status NOT IN ('SUSPENDED', 'RETIRED') OR status_reason IS NOT NULL)
);
CREATE TRIGGER tg_mdm_domain_touch BEFORE UPDATE ON ph06_mdm.mdm_domain FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_mdm_domain_immutable BEFORE UPDATE ON ph06_mdm.mdm_domain FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'tenant_id', 'baseline');
CALL ph06_mdm.p_enable_rls('ph06_mdm.mdm_domain');
COMMENT ON TABLE ph06_mdm.mdm_domain IS 'EN-06-07 Domain dữ liệu chủ (FR-06-001, 006, 007): CITIZEN, ORGANIZATION, ADDRESS và domain tỉnh tự tạo (FR-06-002). Trạng thái DomainStatus. Không xóa; ngừng cần không còn bản ghi vàng ACTIVE (ERR-06-011). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph06_mdm.mdm_domain.baseline IS 'Có khi cài từ gói domain nền (FR-06-007); gói nền do PA phát hành.';
COMMENT ON COLUMN ph06_mdm.mdm_domain.status_reason IS 'Bắt buộc khi SUSPENDED hoặc RETIRED.';
--rollback DROP TABLE IF EXISTS ph06_mdm.mdm_domain CASCADE;

--changeset ph06:ph06-0110-domain-model
CREATE TABLE ph06_mdm.domain_model (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  normalization    jsonb NOT NULL DEFAULT '{}',
  compat_level     varchar(16),
  diff_summary     jsonb,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  submit_comment   varchar(2000),
  decision         varchar(8),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_domain_model PRIMARY KEY (id),
  CONSTRAINT uq_domain_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_domain_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_domain_model_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_domain_model_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_domain_model_version CHECK (version_no >= 1),
  CONSTRAINT ck_domain_model_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_domain_model_compat CHECK (compat_level IS NULL OR compat_level IN ('NON_BREAKING', 'BREAKING')),
  CONSTRAINT ck_domain_model_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_domain_model_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_domain_model_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE')),
  CONSTRAINT ck_domain_model_reject CHECK (decision IS DISTINCT FROM 'REJECT' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_domain_model_active ON ph06_mdm.domain_model (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_domain_model_touch BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_domain_model_immutable BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_domain_model_frozen BEFORE UPDATE ON ph06_mdm.domain_model FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_frozen('normalization');
CALL ph06_mdm.p_enable_rls('ph06_mdm.domain_model');
COMMENT ON TABLE ph06_mdm.domain_model IS 'EN-06-07 Phiên bản mô hình domain (FR-06-002, 005, 006, BR-06-017). Máy trạng thái 4.6 không có TESTING. Mỗi domain đúng một phiên bản ACTIVE; ACTIVE không sửa nội dung, kể cả thuộc tính và khóa con. Duyệt bốn mắt (BR-06-004).';
COMMENT ON COLUMN ph06_mdm.domain_model.normalization IS 'Quy tắc chuẩn hóa theo thuộc tính (FR-06-014, 015), JSON có phiên bản.';
COMMENT ON COLUMN ph06_mdm.domain_model.decision_comment IS 'Từ chối bắt buộc ≥ 20 ký tự (FR-06-006).';
--rollback DROP TABLE IF EXISTS ph06_mdm.domain_model CASCADE;

--changeset ph06:ph06-0120-model-attribute
CREATE TABLE ph06_mdm.model_attribute (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  version_no            integer NOT NULL,
  attribute_name        varchar(63) NOT NULL,
  label                 varchar(255) NOT NULL,
  attribute_type        varchar(16) NOT NULL,
  code_list_ref         varchar(63),
  required              boolean NOT NULL DEFAULT false,
  multi_valued          boolean NOT NULL DEFAULT false,
  critical              boolean NOT NULL DEFAULT false,
  matchable             boolean NOT NULL DEFAULT false,
  data_class            varchar(16) NOT NULL DEFAULT 'INTERNAL',
  classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED',
  personal_data         boolean NOT NULL DEFAULT false,
  legal_basis           varchar(2000),
  sort_order            smallint NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_attribute PRIMARY KEY (id),
  CONSTRAINT ck_model_attribute_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_model_attribute_name UNIQUE (tenant_id, domain_code, version_no, attribute_name),
  CONSTRAINT fk_model_attribute_model FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.domain_model (tenant_id, domain_code, version_no),
  CONSTRAINT ck_model_attribute_name CHECK (attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_model_attribute_type CHECK (attribute_type IN ('STRING', 'NAME_VN', 'DATE', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'CODE_REF', 'ADDRESS_REF', 'IDENTIFIER', 'PHONE', 'EMAIL')),
  CONSTRAINT ck_model_attribute_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_model_attribute_classification CHECK (classification_status IN ('PROPOSED', 'CONFIRMED')),
  CONSTRAINT ck_model_attribute_personal CHECK ((NOT personal_data OR legal_basis IS NOT NULL) AND (data_class <> 'SENSITIVE' OR personal_data)),
  CONSTRAINT ck_model_attribute_coderef CHECK ((attribute_type = 'CODE_REF') = (code_list_ref IS NOT NULL))
);
CREATE TRIGGER tg_model_attribute_touch BEFORE UPDATE ON ph06_mdm.model_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_model_attribute_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.model_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('domain_model');
CALL ph06_mdm.p_enable_rls('ph06_mdm.model_attribute');
COMMENT ON TABLE ph06_mdm.model_attribute IS 'EN-06-07 Thuộc tính của một phiên bản mô hình (FR-06-002, 004). Giá trị DataClass, ClassificationStatus; thuộc tính DLCN cần phân loại CONFIRMED trước khi kích hoạt (BR-06-016, kiểm ở dịch vụ, ERR-06-010). Phiên bản ACTIVE chặn thêm, sửa, xóa (trigger).';
COMMENT ON COLUMN ph06_mdm.model_attribute.data_class IS 'Phân loại theo DD-08; SENSITIVE bắt buộc personal_data.';
COMMENT ON COLUMN ph06_mdm.model_attribute.matchable IS 'Dùng được trong quy tắc đối sánh (FR-06-018).';
--rollback DROP TABLE IF EXISTS ph06_mdm.model_attribute CASCADE;

--changeset ph06:ph06-0130-identifier-rule
CREATE TABLE ph06_mdm.identifier_rule (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  domain_code         varchar(32) NOT NULL,
  version_no          integer NOT NULL,
  identifier_type     varchar(16) NOT NULL,
  attribute_name      varchar(63) NOT NULL,
  validator           varchar(16) NOT NULL,
  pattern             varchar(500),
  deterministic       boolean NOT NULL DEFAULT false,
  unique_among_active boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_identifier_rule PRIMARY KEY (id),
  CONSTRAINT ck_identifier_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_identifier_rule UNIQUE (tenant_id, domain_code, version_no, identifier_type),
  CONSTRAINT fk_identifier_rule_model FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.domain_model (tenant_id, domain_code, version_no),
  CONSTRAINT ck_identifier_rule_type CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_identifier_rule_validator CHECK (validator IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'DVHC_CODE', 'REGEX')),
  CONSTRAINT ck_identifier_rule_regex CHECK ((validator = 'REGEX') = (pattern IS NOT NULL))
);
CREATE TRIGGER tg_identifier_rule_touch BEFORE UPDATE ON ph06_mdm.identifier_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_identifier_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.identifier_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('domain_model');
CALL ph06_mdm.p_enable_rls('ph06_mdm.identifier_rule');
COMMENT ON TABLE ph06_mdm.identifier_rule IS 'EN-06-07 Khóa định danh và bộ kiểm tra của phiên bản mô hình (FR-06-003, BR-06-001). Mỗi domain cần ít nhất một khóa hoặc tổ hợp đối sánh (ERR-06-009, kiểm ở dịch vụ khi gửi duyệt).';
COMMENT ON COLUMN ph06_mdm.identifier_rule.validator IS 'Danh sách ở đầu vào FR-06-003; chữ số kiểm tra theo Q06-09.';
--rollback DROP TABLE IF EXISTS ph06_mdm.identifier_rule CASCADE;

--changeset ph06:ph06-0140-mdm-source
CREATE TABLE ph06_mdm.mdm_source (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_code     varchar(32) NOT NULL,
  name            varchar(255) NOT NULL,
  system_code     varchar(63),
  source_kind     varchar(24) NOT NULL,
  status          varchar(16) NOT NULL DEFAULT 'DRAFT',
  domains         varchar(32)[] NOT NULL,
  channels        varchar(16)[] NOT NULL,
  attribute_scope varchar(63)[] NOT NULL DEFAULT '{}',
  owner_org_code  varchar(63) NOT NULL,
  trust_level     smallint NOT NULL DEFAULT 3,
  status_reason   varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_mdm_source PRIMARY KEY (id),
  CONSTRAINT ck_mdm_source_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_mdm_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_mdm_source_code CHECK (source_code ~ '^[A-Z][A-Z0-9-]{2,31}$'),
  CONSTRAINT ck_mdm_source_kind CHECK (source_kind IN ('NATIONAL_DB', 'SECTOR_AUTHORITATIVE', 'SECTOR_RELATED', 'SECTOR_OTHER', 'MANUAL_ENTRY', 'FILE_BATCH')),
  CONSTRAINT ck_mdm_source_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_mdm_source_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['API', 'FLOW', 'EVENT', 'FILE', 'NATIONAL_SYNC']::varchar[]),
  CONSTRAINT ck_mdm_source_domains CHECK (cardinality(domains) >= 1),
  CONSTRAINT ck_mdm_source_trust CHECK (trust_level BETWEEN 1 AND 5),
  CONSTRAINT ck_mdm_source_system CHECK (source_kind IN ('MANUAL_ENTRY', 'FILE_BATCH', 'NATIONAL_DB') OR system_code IS NOT NULL)
);
CREATE TRIGGER tg_mdm_source_touch BEFORE UPDATE ON ph06_mdm.mdm_source FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_mdm_source_immutable BEFORE UPDATE ON ph06_mdm.mdm_source FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('source_code', 'tenant_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.mdm_source');
COMMENT ON TABLE ph06_mdm.mdm_source IS 'EN-06-08 Nguồn dữ liệu chủ gắn HTTT (FR-06-008, BR-06-032). trust_level 1…5; nguồn NATIONAL_DB chỉ nhận qua PH-14, không kết nối thẳng. Chỉ nguồn ACTIVE cho domain mới được nạp (ERR-06-014).';
COMMENT ON COLUMN ph06_mdm.mdm_source.system_code IS 'Mã HTTT ở PH-01 (không khóa ngoại, khác schema); HTTT phải ACTIVE khi đăng ký (ERR-06-012).';
COMMENT ON COLUMN ph06_mdm.mdm_source.domains IS 'Mã domain ACTIVE được phép gửi; kiểm ở dịch vụ.';
--rollback DROP TABLE IF EXISTS ph06_mdm.mdm_source CASCADE;

--changeset ph06:ph06-0150-source-priority-proposal
CREATE TABLE ph06_mdm.source_priority_proposal (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  entries          jsonb NOT NULL,
  approval_ref     varchar(255) NOT NULL,
  justification    varchar(2000) NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  proposed_by      varchar(64) NOT NULL,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_priority_proposal PRIMARY KEY (id),
  CONSTRAINT uq_source_priority_proposal_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_source_priority_proposal_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_priority_proposal_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_source_priority_proposal_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'REJECTED')),
  CONSTRAINT ck_source_priority_proposal_four_eyes CHECK (decided_by IS NULL OR proposed_by IS NULL OR decided_by <> proposed_by),
  CONSTRAINT ck_source_priority_proposal_entries CHECK (jsonb_typeof(entries) = 'array' AND jsonb_array_length(entries) BETWEEN 1 AND 500),
  CONSTRAINT ck_source_priority_proposal_decided CHECK ((status = 'PENDING_APPROVAL') = (decided_by IS NULL))
);
CREATE TRIGGER tg_source_priority_proposal_touch BEFORE UPDATE ON ph06_mdm.source_priority_proposal FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_source_priority_proposal_immutable BEFORE UPDATE ON ph06_mdm.source_priority_proposal FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'entries', 'approval_ref', 'proposed_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_priority_proposal');
COMMENT ON TABLE ph06_mdm.source_priority_proposal IS 'EN-06-04, EN-06-22 Đề nghị thứ tự ưu tiên nguồn chờ duyệt (FR-06-009, BR-06-004). Cần căn cứ văn bản approval_ref; DA duyệt khác người đề nghị (ERR-06-005, 013).';
COMMENT ON COLUMN ph06_mdm.source_priority_proposal.entries IS 'Mảng {sourceCode, attribute, priority} theo FR-06-009; áp vào source_priority khi duyệt.';
--rollback DROP TABLE IF EXISTS ph06_mdm.source_priority_proposal CASCADE;

--changeset ph06:ph06-0160-source-priority
CREATE TABLE ph06_mdm.source_priority (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  source_code    varchar(32) NOT NULL,
  attribute_name varchar(63) NOT NULL DEFAULT '*',
  priority       smallint NOT NULL,
  approval_ref   varchar(255) NOT NULL,
  proposal_id    uuid NOT NULL,
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_priority PRIMARY KEY (id),
  CONSTRAINT ck_source_priority_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_priority_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT fk_source_priority_proposal FOREIGN KEY (tenant_id, proposal_id) REFERENCES ph06_mdm.source_priority_proposal (tenant_id, id),
  CONSTRAINT ck_source_priority_priority CHECK (priority BETWEEN 1 AND 99),
  CONSTRAINT ck_source_priority_attr CHECK (attribute_name = '*' OR attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_source_priority_period CHECK (effective_to IS NULL OR effective_to > effective_from)
);
CREATE UNIQUE INDEX uq_source_priority_current ON ph06_mdm.source_priority (tenant_id, domain_code, source_code, attribute_name) WHERE effective_to IS NULL;
CREATE INDEX ix_source_priority_domain ON ph06_mdm.source_priority (tenant_id, domain_code, attribute_name, priority) WHERE effective_to IS NULL;
CREATE TRIGGER tg_source_priority_touch BEFORE UPDATE ON ph06_mdm.source_priority FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_priority');
COMMENT ON TABLE ph06_mdm.source_priority IS 'EN-06-04 Mức ưu tiên nguồn theo domain và thuộc tính đang hiệu lực (FR-06-009, 033). attribute_name = ''*'' là mọi thuộc tính. Nguồn quốc gia luôn ưu tiên 1 với thuộc tính thẩm quyền quốc gia (BR-06-003). Bản cũ đóng bằng effective_to.';
COMMENT ON COLUMN ph06_mdm.source_priority.priority IS '1 cao nhất … 99 (FR-06-009).';
--rollback DROP TABLE IF EXISTS ph06_mdm.source_priority CASCADE;
