--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0020-ropa.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0200-legal-document
CREATE TABLE ph09_privacy.legal_document (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  doc_type       varchar(32) NOT NULL,
  number         varchar(64) NOT NULL,
  title          varchar(500) NOT NULL,
  issued_on      date NOT NULL,
  effective_from date NOT NULL,
  effective_to   date,
  cmp_law_code   varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_document PRIMARY KEY (id),
  CONSTRAINT uq_legal_document_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_document_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legal_document_number UNIQUE (tenant_id, doc_type, number),
  CONSTRAINT ck_legal_document_type CHECK (doc_type ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_legal_document_period CHECK (effective_from >= issued_on AND (effective_to IS NULL OR effective_to > effective_from)),
  CONSTRAINT ck_legal_document_law CHECK (cmp_law_code IS NULL OR cmp_law_code ~ '^CMP-LAW-[0-9]{2}$')
);
CREATE TRIGGER tg_legal_document_touch BEFORE UPDATE ON ph09_privacy.legal_document FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_document_immutable BEFORE UPDATE ON ph09_privacy.legal_document FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('doc_type', 'number');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_document');
COMMENT ON TABLE ph09_privacy.legal_document IS 'EN-09-14 Văn bản căn cứ (FR-09-012): loại, số, ngày ban hành, hiệu lực, liên kết CMP-LAW. Văn bản hết hiệu lực không dùng cho hoạt động mới (kiểm ở dịch vụ).';
--rollback DROP TABLE IF EXISTS ph09_privacy.legal_document CASCADE;

--changeset ph09:ph09-0210-legal-basis
CREATE TABLE ph09_privacy.legal_basis (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  code       varchar(32) NOT NULL,
  basis_type varchar(32) NOT NULL,
  name       varchar(255) NOT NULL,
  mandatory  boolean NOT NULL DEFAULT false,
  rule       varchar(2000),
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legal_basis PRIMARY KEY (id),
  CONSTRAINT uq_legal_basis_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legal_basis_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legal_basis_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_legal_basis_code CHECK (code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_legal_basis_type CHECK (basis_type IN ('CONSENT', 'STATE_TASK', 'LEGAL_OBLIGATION', 'CONTRACT', 'VITAL_INTEREST', 'EMERGENCY_PUBLIC_INTEREST', 'STATISTICS_RESEARCH'))
);
CREATE TRIGGER tg_legal_basis_touch BEFORE UPDATE ON ph09_privacy.legal_basis FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_legal_basis_immutable BEFORE UPDATE ON ph09_privacy.legal_basis FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'basis_type');
CALL ph09_privacy.p_enable_rls('ph09_privacy.legal_basis');
COMMENT ON TABLE ph09_privacy.legal_basis IS 'EN-09-13 Cơ sở pháp lý (FR-09-012, BR-09-009): bảy LegalBasisType nạp sẵn kèm quy tắc áp dụng. CONSENT chỉ cho tiện ích không bắt buộc; cơ quan nhà nước dùng STATE_TASK hoặc LEGAL_OBLIGATION.';
--rollback DROP TABLE IF EXISTS ph09_privacy.legal_basis CASCADE;

--changeset ph09:ph09-0220-processing-activity
CREATE TABLE ph09_privacy.processing_activity (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  code             varchar(41) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  purpose_text     varchar(1000) NOT NULL,
  legal_basis_code varchar(32) NOT NULL,
  legal_doc_ids    uuid[] NOT NULL DEFAULT '{}',
  categories       varchar(32)[] NOT NULL,
  subject_groups   varchar(255)[] NOT NULL,
  recipients       varchar(255)[] NOT NULL DEFAULT '{}',
  retention        jsonb NOT NULL,
  controller_role  varchar(20) NOT NULL,
  measures         varchar(500)[] NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_processing_activity PRIMARY KEY (id),
  CONSTRAINT uq_processing_activity_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_processing_activity_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_processing_activity_code CHECK (code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT fk_processing_activity_basis FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES ph09_privacy.legal_basis (tenant_id, code),
  CONSTRAINT ck_processing_activity_purpose CHECK (char_length(purpose_text) >= 20),
  CONSTRAINT ck_processing_activity_role CHECK (controller_role IN ('CONTROLLER', 'PROCESSOR', 'JOINT_CONTROLLER')),
  CONSTRAINT ck_processing_activity_retention CHECK (jsonb_typeof(retention) = 'object' AND retention->>'action' IN ('DELETE', 'PSEUDONYMIZE', 'ANONYMIZE', 'ARCHIVE') AND (retention ? 'months' OR retention ? 'endCondition')),
  CONSTRAINT ck_processing_activity_lists CHECK (cardinality(categories) >= 1 AND cardinality(subject_groups) >= 1 AND cardinality(measures) >= 1),
  CONSTRAINT uq_processing_activity_version UNIQUE (tenant_id, code, version_no),
  CONSTRAINT ck_processing_activity_version CHECK (version_no >= 1),
  CONSTRAINT ck_processing_activity_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'RETIRED')),
  CONSTRAINT ck_processing_activity_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_processing_activity_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)),
  CONSTRAINT ck_processing_activity_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_processing_activity_active ON ph09_privacy.processing_activity (tenant_id, code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_processing_activity_touch BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_processing_activity_immutable BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'version_no');
CREATE TRIGGER tg_processing_activity_frozen BEFORE UPDATE ON ph09_privacy.processing_activity FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_frozen('purpose_text', 'legal_basis_code', 'categories', 'subject_groups', 'recipients', 'retention', 'controller_role', 'measures', 'legal_doc_ids');
CALL ph09_privacy.p_enable_rls('ph09_privacy.processing_activity');
COMMENT ON TABLE ph09_privacy.processing_activity IS 'EN-09-11 Hoạt động xử lý DLCN theo phiên bản (FR-09-009, 010, BR-09-009…012): mục đích, cơ sở pháp lý chính, loại dữ liệu, nhóm chủ thể, bên nhận, thời hạn lưu (số tháng hoặc điều kiện kết thúc cùng hành động), vai trò, biện pháp. ACTIVE không sửa tại chỗ, duyệt bốn mắt.';
COMMENT ON COLUMN ph09_privacy.processing_activity.categories IS 'Mã loại DLCN (personal_data_category.code); kiểm tồn tại ở dịch vụ khi gửi duyệt.';
COMMENT ON COLUMN ph09_privacy.processing_activity.legal_doc_ids IS 'Mã legal_document; mảng nên kiểm ở dịch vụ.';
COMMENT ON COLUMN ph09_privacy.processing_activity.retention IS '{months, endCondition, action}, action là RetentionAction (BR-09-012).';
--rollback DROP TABLE IF EXISTS ph09_privacy.processing_activity CASCADE;

--changeset ph09:ph09-0230-activity-link
CREATE TABLE ph09_privacy.activity_link (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  activity_id uuid NOT NULL,
  target_kind varchar(8) NOT NULL,
  target_id   varchar(128) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_activity_link PRIMARY KEY (id),
  CONSTRAINT ck_activity_link_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_activity_link_activity FOREIGN KEY (tenant_id, activity_id) REFERENCES ph09_privacy.processing_activity (tenant_id, id),
  CONSTRAINT uq_activity_link_target UNIQUE (tenant_id, activity_id, target_kind, target_id),
  CONSTRAINT ck_activity_link_kind CHECK (target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW'))
);
CREATE INDEX ix_activity_link_target ON ph09_privacy.activity_link (tenant_id, target_kind, target_id);
CREATE TRIGGER tg_activity_link_touch BEFORE UPDATE ON ph09_privacy.activity_link FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_activity_link_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph09_privacy.activity_link FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_child_frozen('processing_activity', 'activity_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.activity_link');
COMMENT ON TABLE ph09_privacy.activity_link IS 'EN-09-12 Liên kết hoạt động xử lý với phần tử, API, topic hoặc luồng (FR-09-011, BR-09-008). Chỉ sửa khi hoạt động ở DRAFT hoặc REJECTED (trigger). Mỗi trường DLCN CONFIRMED phải thuộc ít nhất một hoạt động ACTIVE (kiểm ở dịch vụ, SEC-37).';
--rollback DROP TABLE IF EXISTS ph09_privacy.activity_link CASCADE;
