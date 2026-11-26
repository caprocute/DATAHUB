--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0010-classification.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0100-data-class
CREATE TABLE ph09_privacy.data_class (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  code           varchar(16) NOT NULL,
  rank           smallint NOT NULL,
  name           varchar(100) NOT NULL,
  log_policy     varchar(16) NOT NULL,
  display_policy varchar(16) NOT NULL,
  encrypt_at_app boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_class PRIMARY KEY (id),
  CONSTRAINT uq_data_class_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_data_class_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_data_class_code UNIQUE (tenant_id, code),
  CONSTRAINT uq_data_class_rank UNIQUE (tenant_id, rank),
  CONSTRAINT ck_data_class_code CHECK (code IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_data_class_rank CHECK (rank = CASE code WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 ELSE 4 END),
  CONSTRAINT ck_data_class_log CHECK (log_policy IN ('FULL', 'PARTIAL_MASK', 'NO_VALUE')),
  CONSTRAINT ck_data_class_display CHECK (display_policy IN ('FULL', 'MASK_BY_ROLE', 'MASK_DEFAULT')),
  CONSTRAINT ck_data_class_sensitive CHECK (code <> 'SENSITIVE' OR (log_policy = 'NO_VALUE' AND display_policy = 'MASK_DEFAULT' AND encrypt_at_app))
);
CREATE TRIGGER tg_data_class_touch BEFORE UPDATE ON ph09_privacy.data_class FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_data_class_immutable BEFORE UPDATE ON ph09_privacy.data_class FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'rank');
CALL ph09_privacy.p_enable_rls('ph09_privacy.data_class');
COMMENT ON TABLE ph09_privacy.data_class IS 'EN-09-01 Mức phân loại DD-08 (FR-09-001): PUBLIC, INTERNAL, RESTRICTED, SENSITIVE, thứ hạng 1 đến 4 theo bảng D03-07 3.2. SENSITIVE luôn NO_VALUE ở log, MASK_DEFAULT ở hiển thị, mã hóa ở ứng dụng (ERR-09-003). Mỗi tenant có bản nạp sẵn bốn dòng; không xóa.';
COMMENT ON COLUMN ph09_privacy.data_class.log_policy IS 'Cách ghi giá trị vào log vận hành (D03-07 3.2).';
COMMENT ON COLUMN ph09_privacy.data_class.encrypt_at_app IS 'Mã hóa envelope ở tầng ứng dụng (ADR-032).';
--rollback DROP TABLE IF EXISTS ph09_privacy.data_class CASCADE;

--changeset ph09:ph09-0110-block-label
CREATE TABLE ph09_privacy.block_label (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  label                varchar(16) NOT NULL DEFAULT 'STATE_SECRET',
  target_kind          varchar(16) NOT NULL,
  target_id            varchar(128) NOT NULL,
  legal_doc            varchar(255) NOT NULL,
  assigned_by          varchar(64) NOT NULL,
  release_requested_by varchar(64),
  release_requested_at timestamptz,
  release_doc          varchar(255),
  released_by          varchar(64),
  released_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_block_label PRIMARY KEY (id),
  CONSTRAINT ck_block_label_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_block_label_label CHECK (label IN ('STATE_SECRET')),
  CONSTRAINT ck_block_label_target CHECK (target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_block_label_release_req CHECK ((release_requested_by IS NULL) = (release_requested_at IS NULL) AND (release_requested_by IS NULL OR release_doc IS NOT NULL)),
  CONSTRAINT ck_block_label_released CHECK ((released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by)))
);
CREATE UNIQUE INDEX uq_block_label_active ON ph09_privacy.block_label (tenant_id, target_kind, target_id) WHERE released_at IS NULL;
CREATE TRIGGER tg_block_label_touch BEFORE UPDATE ON ph09_privacy.block_label FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_block_label_immutable BEFORE UPDATE ON ph09_privacy.block_label FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('target_kind', 'target_id', 'legal_doc', 'assigned_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.block_label');
COMMENT ON TABLE ph09_privacy.block_label IS 'EN-09-02 Nhãn chặn STATE_SECRET gắn vào phần tử hoặc hợp đồng (FR-09-007, BR-09-005). Gỡ nhãn cần văn bản giải mật và hai người khác nhau (ERR-09-019); không xóa dòng, gỡ ghi released_*. Mọi thao tác ghi kiểm toán, bị từ chối nếu không ghi được (BR-09-057).';
COMMENT ON COLUMN ph09_privacy.block_label.released_by IS 'Người duyệt gỡ, khác người đề nghị gỡ (BR-09-005).';
--rollback DROP TABLE IF EXISTS ph09_privacy.block_label CASCADE;

--changeset ph09:ph09-0120-personal-data-category
CREATE TABLE ph09_privacy.personal_data_category (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  code                 varchar(32) NOT NULL,
  name                 varchar(255) NOT NULL,
  personal_data_type   varchar(16) NOT NULL,
  legal_ref            varchar(16),
  default_class        varchar(16) NOT NULL,
  default_mask_pattern varchar(24),
  identifiability      varchar(16) NOT NULL DEFAULT 'NONE',
  builtin              boolean NOT NULL DEFAULT false,
  retired_at           timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_personal_data_category PRIMARY KEY (id),
  CONSTRAINT uq_personal_data_category_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_personal_data_category_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_personal_data_category_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_personal_data_category_code CHECK (code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_personal_data_category_type CHECK (personal_data_type IN ('BASIC', 'SENSITIVE')),
  CONSTRAINT ck_personal_data_category_legal CHECK (legal_ref IS NULL OR legal_ref ~ '^CMP-LAW-[0-9]{2}$'),
  CONSTRAINT ck_personal_data_category_class CHECK (default_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_personal_data_category_pattern CHECK (default_mask_pattern IS NULL OR default_mask_pattern IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_personal_data_category_ident CHECK (identifiability IN ('DIRECT', 'QUASI', 'SENSITIVE_ATTR', 'NONE')),
  CONSTRAINT ck_personal_data_category_sensitive CHECK (personal_data_type <> 'SENSITIVE' OR default_class = 'SENSITIVE')
);
CREATE TRIGGER tg_personal_data_category_touch BEFORE UPDATE ON ph09_privacy.personal_data_category FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_personal_data_category_immutable BEFORE UPDATE ON ph09_privacy.personal_data_category FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code', 'builtin');
CALL ph09_privacy.p_enable_rls('ph09_privacy.personal_data_category');
COMMENT ON TABLE ph09_privacy.personal_data_category IS 'EN-09-03 Loại dữ liệu cá nhân (FR-09-002): 9 loại cơ bản và 9 loại nhạy cảm của Luật 91/2025, NĐ 356/2025, nạp sẵn; tenant thêm loại mới. Loại SENSITIVE mặc định mức SENSITIVE; hạ loại cần bốn mắt (BR-09-002). Ngừng bằng retired_at.';
--rollback DROP TABLE IF EXISTS ph09_privacy.personal_data_category CASCADE;

--changeset ph09:ph09-0130-data-element
CREATE TABLE ph09_privacy.data_element (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  scope          varchar(16) NOT NULL,
  target         varchar(512) NOT NULL,
  owner_org_id   varchar(63) NOT NULL,
  contract_ref   varchar(255),
  declared_class varchar(16),
  source         varchar(16) NOT NULL,
  element_status varchar(12) NOT NULL DEFAULT 'ACTIVE',
  retired_at     timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_element PRIMARY KEY (id),
  CONSTRAINT uq_data_element_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_data_element_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_data_element_target UNIQUE (tenant_id, scope, target),
  CONSTRAINT ck_data_element_scope CHECK (scope IN ('INTERNAL_ENTITY', 'API_SCHEMA', 'EVENT_SCHEMA')),
  CONSTRAINT ck_data_element_declared CHECK (declared_class IS NULL OR declared_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_data_element_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_data_element_status CHECK (element_status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_data_element_retired CHECK ((element_status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE INDEX ix_data_element_owner ON ph09_privacy.data_element (tenant_id, owner_org_id, element_status);
CREATE INDEX ix_data_element_contract ON ph09_privacy.data_element (tenant_id, contract_ref) WHERE contract_ref IS NOT NULL;
CREATE INDEX ix_data_element_target_trgm ON ph09_privacy.data_element USING gin (lower(target) gin_trgm_ops);
CREATE TRIGGER tg_data_element_touch BEFORE UPDATE ON ph09_privacy.data_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_data_element_immutable BEFORE UPDATE ON ph09_privacy.data_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('scope', 'target');
CALL ph09_privacy.p_enable_rls('ph09_privacy.data_element');
COMMENT ON TABLE ph09_privacy.data_element IS 'EN-09-04 Phần tử dữ liệu (trường) đăng ký từ phân hệ, lược đồ API, topic, khai báo MVP (FR-09-003, BR-09-007). target là tên đầy đủ (ph06_mdm.CITIZEN.nationalId) hoặc JSON Pointer. Không xóa; ngừng bằng element_status RETIRED. Phân loại hiện hành ở element_classification.';
COMMENT ON COLUMN ph09_privacy.data_element.owner_org_id IS 'Mã tổ chức ở PH-01 (không khóa ngoại, khác schema); chỉ TA, SO, DO của tổ chức này xác nhận (BR-09-003).';
COMMENT ON COLUMN ph09_privacy.data_element.declared_class IS 'Mức khai báo trong mã (@Classified, x-dh-classification) khi nhập MVP (FR-09-003).';
--rollback DROP TABLE IF EXISTS ph09_privacy.data_element CASCADE;

--changeset ph09:ph09-0140-element-classification
CREATE TABLE ph09_privacy.element_classification (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  element_id         uuid NOT NULL,
  data_class         varchar(16) NOT NULL,
  personal_data_type varchar(16) NOT NULL DEFAULT 'NONE',
  category_code      varchar(32),
  identifiability    varchar(16) NOT NULL DEFAULT 'NONE',
  mask_pattern       varchar(24),
  never_reveal       boolean NOT NULL DEFAULT false,
  basis              varchar(255),
  status             varchar(12) NOT NULL DEFAULT 'PROPOSED',
  source             varchar(16) NOT NULL,
  confirmed_by       varchar(64),
  confirmed_at       timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_element_classification PRIMARY KEY (id),
  CONSTRAINT uq_element_classification_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_element_classification_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_element_classification_element UNIQUE (tenant_id, element_id),
  CONSTRAINT fk_element_classification_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT fk_element_classification_category FOREIGN KEY (tenant_id, category_code) REFERENCES ph09_privacy.personal_data_category (tenant_id, code),
  CONSTRAINT ck_element_classification_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_element_classification_type CHECK (personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE')),
  CONSTRAINT ck_element_classification_ident CHECK (identifiability IN ('DIRECT', 'QUASI', 'SENSITIVE_ATTR', 'NONE')),
  CONSTRAINT ck_element_classification_pattern CHECK (mask_pattern IS NULL OR mask_pattern IN ('KEEP_FIRST_N', 'KEEP_LAST_N', 'KEEP_FIRST_LAST', 'KEEP_FIRST_TOKEN', 'KEEP_DOMAIN', 'YEAR_ONLY', 'ADMIN_LEVEL')),
  CONSTRAINT ck_element_classification_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'REJECTED', 'SUPERSEDED')),
  CONSTRAINT ck_element_classification_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_element_classification_category CHECK ((personal_data_type = 'NONE') = (category_code IS NULL)),
  CONSTRAINT ck_element_classification_sensitive CHECK (personal_data_type <> 'SENSITIVE' OR data_class = 'SENSITIVE'),
  CONSTRAINT ck_element_classification_direct CHECK (identifiability NOT IN ('DIRECT', 'SENSITIVE_ATTR') OR personal_data_type <> 'NONE'),
  CONSTRAINT ck_element_classification_confirmed CHECK (status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL))
);
CREATE INDEX ix_element_classification_class ON ph09_privacy.element_classification (tenant_id, data_class, status);
CREATE INDEX ix_element_classification_category ON ph09_privacy.element_classification (tenant_id, category_code) WHERE category_code IS NOT NULL;
CREATE TRIGGER tg_element_classification_touch BEFORE UPDATE ON ph09_privacy.element_classification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_element_classification_immutable BEFORE UPDATE ON ph09_privacy.element_classification FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('element_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.element_classification');
COMMENT ON TABLE ph09_privacy.element_classification IS 'EN-09-05 Phân loại hiện hành của phần tử, một dòng mỗi phần tử (DD-09, FR-09-004). Chưa CONFIRMED thì xử lý như SENSITIVE (BR-09-001). Loại DLCN khác NONE phải có categoryCode; SENSITIVE kéo theo mức SENSITIVE. Đổi qua classification_change.';
COMMENT ON COLUMN ph09_privacy.element_classification.never_reveal IS 'Trường không có đường xem đầy đủ (BR-09-026).';
COMMENT ON COLUMN ph09_privacy.element_classification.mask_pattern IS 'Mẫu che mặc định của trường (MaskPatternKind).';
COMMENT ON COLUMN ph09_privacy.element_classification.basis IS 'Số văn bản căn cứ của phân loại.';
--rollback DROP TABLE IF EXISTS ph09_privacy.element_classification CASCADE;

--changeset ph09:ph09-0150-classification-change
CREATE TABLE ph09_privacy.classification_change (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  element_id              uuid NOT NULL,
  from_class              varchar(16),
  to_class                varchar(16) NOT NULL,
  from_personal_data_type varchar(16),
  to_personal_data_type   varchar(16) NOT NULL,
  proposed                jsonb NOT NULL,
  status                  varchar(12) NOT NULL DEFAULT 'PROPOSED',
  basis                   varchar(255),
  reason                  varchar(2000) NOT NULL,
  proposed_by             varchar(64) NOT NULL,
  confirmed_by            varchar(64),
  confirmed_at            timestamptz,
  confirmed_by_2          varchar(64),
  confirmed_at_2          timestamptz,
  reject_comment          varchar(2000),
  source                  varchar(16) NOT NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_classification_change PRIMARY KEY (id),
  CONSTRAINT uq_classification_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_classification_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_classification_change_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT ck_classification_change_class CHECK (to_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE') AND (from_class IS NULL OR from_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE'))),
  CONSTRAINT ck_classification_change_type CHECK (to_personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE') AND (from_personal_data_type IS NULL OR from_personal_data_type IN ('NONE', 'BASIC', 'SENSITIVE'))),
  CONSTRAINT ck_classification_change_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'REJECTED', 'SUPERSEDED')),
  CONSTRAINT ck_classification_change_source CHECK (source IN ('MANUAL', 'SCAN', 'DECLARATION', 'SCHEMA_IMPORT', 'MVP_IMPORT')),
  CONSTRAINT ck_classification_change_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_classification_change_four_eyes CHECK (confirmed_by IS NULL OR confirmed_by <> proposed_by),
  CONSTRAINT ck_classification_change_confirmed CHECK (status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)),
  CONSTRAINT ck_classification_change_downgrade CHECK (status <> 'CONFIRMED' OR from_class IS NULL OR ph09_privacy.class_rank(to_class) >= ph09_privacy.class_rank(from_class) OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_at_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)),
  CONSTRAINT ck_classification_change_type_down CHECK (status <> 'CONFIRMED' OR from_personal_data_type IS DISTINCT FROM 'SENSITIVE' OR to_personal_data_type = 'SENSITIVE' OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)),
  CONSTRAINT ck_classification_change_rejected CHECK (status <> 'REJECTED' OR COALESCE(char_length(reject_comment) >= 20, false))
);
CREATE INDEX ix_classification_change_element ON ph09_privacy.classification_change (tenant_id, element_id, created_at DESC);
CREATE INDEX ix_classification_change_open ON ph09_privacy.classification_change (tenant_id, status, created_at) WHERE status = 'PROPOSED';
CREATE TRIGGER tg_classification_change_touch BEFORE UPDATE ON ph09_privacy.classification_change FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_classification_change_immutable BEFORE UPDATE ON ph09_privacy.classification_change FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('element_id', 'from_class', 'to_class', 'proposed', 'proposed_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.classification_change');
COMMENT ON TABLE ph09_privacy.classification_change IS 'EN-09-06 Đề xuất, thay đổi phân loại (FR-09-004, 005, BR-09-002, 003, 007). Người xác nhận khác người đề xuất. Hạ mức hoặc hạ loại DLCN từ SENSITIVE cần số văn bản căn cứ và người xác nhận thứ hai khác hai người kia. Lịch sử tuyến tính, không sửa sau khi chốt.';
COMMENT ON COLUMN ph09_privacy.classification_change.proposed IS 'Trạng thái phân loại đề xuất (dataClass, personalDataType, categoryCode, identifiability, maskPattern, neverReveal).';
COMMENT ON COLUMN ph09_privacy.classification_change.confirmed_by_2 IS 'Người xác nhận thứ hai khi hạ mức (BR-09-002).';
--rollback DROP TABLE IF EXISTS ph09_privacy.classification_change CASCADE;

--changeset ph09:ph09-0160-detector-rule
CREATE TABLE ph09_privacy.detector_rule (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  detector_code        varchar(24) NOT NULL,
  name                 varchar(255) NOT NULL,
  pattern              varchar(500) NOT NULL,
  has_checksum         boolean NOT NULL DEFAULT false,
  confidence_threshold numeric(3,2) NOT NULL DEFAULT 0.80,
  enabled              boolean NOT NULL DEFAULT true,
  builtin              boolean NOT NULL DEFAULT false,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_detector_rule PRIMARY KEY (id),
  CONSTRAINT ck_detector_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_detector_rule_code UNIQUE (tenant_id, detector_code),
  CONSTRAINT ck_detector_rule_code CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_detector_rule_threshold CHECK (confidence_threshold BETWEEN 0.50 AND 0.99)
);
CREATE TRIGGER tg_detector_rule_touch BEFORE UPDATE ON ph09_privacy.detector_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_detector_rule_immutable BEFORE UPDATE ON ph09_privacy.detector_rule FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('detector_code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.detector_rule');
COMMENT ON TABLE ph09_privacy.detector_rule IS 'EN-09-07 Mẫu phát hiện DLCN (FR-09-005, ADR đề xuất 093): số định danh 12 chữ số, mã số thuế, thẻ (Luhn), điện thoại, thư điện tử, mã BHXH, gợi ý theo tên trường. Bộ mẫu và kiểm tổng, không dùng học máy ở đợt 2.';
COMMENT ON COLUMN ph09_privacy.detector_rule.pattern IS 'Biểu thức chính quy hoặc danh sách gợi ý tên trường; kiểm tổng (Luhn, mod 11) ở mã.';
--rollback DROP TABLE IF EXISTS ph09_privacy.detector_rule CASCADE;

--changeset ph09:ph09-0170-scan-run
CREATE TABLE ph09_privacy.scan_run (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  scope         jsonb NOT NULL,
  sample_rows   integer NOT NULL DEFAULT 10000,
  detectors     varchar(24)[] NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_by  varchar(64) NOT NULL,
  started_at    timestamptz,
  finished_at   timestamptz,
  suspect_count integer NOT NULL DEFAULT 0,
  error_code    varchar(10),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_scan_run PRIMARY KEY (id),
  CONSTRAINT uq_scan_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_scan_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_scan_run_rows CHECK (sample_rows BETWEEN 1000 AND 100000),
  CONSTRAINT ck_scan_run_detectors CHECK (cardinality(detectors) >= 1 AND detectors <@ ARRAY['NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT']::varchar[]),
  CONSTRAINT ck_scan_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_scan_run_finished CHECK (status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_scan_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$'),
  CONSTRAINT ck_scan_run_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_scan_run_suspect CHECK (suspect_count >= 0)
);
CREATE INDEX ix_scan_run_list ON ph09_privacy.scan_run (tenant_id, created_at DESC);
CREATE TRIGGER tg_scan_run_touch BEFORE UPDATE ON ph09_privacy.scan_run FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.scan_run');
COMMENT ON TABLE ph09_privacy.scan_run IS 'EN-09-08 Lượt quét phát hiện trường nghi DLCN (FR-09-005, NFR-09-009): phạm vi, số dòng mẫu, mẫu phát hiện, trạng thái ScanStatus. Chỉ đọc mẫu, không lưu giá trị mẫu (BR-09-025). Giữ 365 ngày.';
COMMENT ON COLUMN ph09_privacy.scan_run.scope IS 'Hệ thống, hợp đồng cần quét (FR-09-005).';
--rollback DROP TABLE IF EXISTS ph09_privacy.scan_run CASCADE;

--changeset ph09:ph09-0180-scan-finding
CREATE TABLE ph09_privacy.scan_finding (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  scan_id         uuid NOT NULL,
  element_id      uuid,
  target          varchar(512) NOT NULL,
  detector_code   varchar(24) NOT NULL,
  confidence      numeric(4,3) NOT NULL,
  hit_count       integer NOT NULL,
  status          varchar(16) NOT NULL DEFAULT 'OPEN',
  resolved_by     varchar(64),
  resolved_at     timestamptz,
  resolution_note varchar(2000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_scan_finding PRIMARY KEY (id),
  CONSTRAINT ck_scan_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_scan_finding_scan FOREIGN KEY (tenant_id, scan_id) REFERENCES ph09_privacy.scan_run (tenant_id, id),
  CONSTRAINT fk_scan_finding_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT uq_scan_finding_target UNIQUE (tenant_id, scan_id, target, detector_code),
  CONSTRAINT ck_scan_finding_detector CHECK (detector_code IN ('NATIONAL_ID_12', 'TAX_ID_10_13', 'BANK_CARD_LUHN', 'PHONE_VN', 'EMAIL', 'SOCIAL_INSURANCE_10', 'FIELD_NAME_HINT')),
  CONSTRAINT ck_scan_finding_confidence CHECK (confidence BETWEEN 0 AND 1 AND hit_count >= 0),
  CONSTRAINT ck_scan_finding_status CHECK (status IN ('OPEN', 'CONFIRMED_PII', 'EXCLUDED', 'CLASSIFIED')),
  CONSTRAINT ck_scan_finding_resolved CHECK (status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
);
CREATE INDEX ix_scan_finding_open ON ph09_privacy.scan_finding (tenant_id, status, confidence DESC) WHERE status = 'OPEN';
CREATE TRIGGER tg_scan_finding_touch BEFORE UPDATE ON ph09_privacy.scan_finding FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.scan_finding');
COMMENT ON TABLE ph09_privacy.scan_finding IS 'EN-09-09 Kết quả phát hiện một cột hoặc trường (FR-09-005, BR-09-006): mẫu khớp, độ tin cậy, trạng thái FindingStatus. Chỉ là gợi ý, không tự đổi phân loại. Chỉ lưu số lượt khớp, không lưu giá trị.';
--rollback DROP TABLE IF EXISTS ph09_privacy.scan_finding CASCADE;

--changeset ph09:ph09-0190-contract-level
CREATE TABLE ph09_privacy.contract_level (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  contract_kind varchar(8) NOT NULL,
  contract_id   varchar(128) NOT NULL,
  data_class    varchar(16) NOT NULL,
  provisional   boolean NOT NULL DEFAULT false,
  blocked       boolean NOT NULL DEFAULT false,
  element_count integer NOT NULL DEFAULT 0,
  computed_at   timestamptz NOT NULL DEFAULT now(),
  basis         jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_contract_level PRIMARY KEY (id),
  CONSTRAINT ck_contract_level_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_contract_level_contract UNIQUE (tenant_id, contract_kind, contract_id),
  CONSTRAINT ck_contract_level_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_contract_level_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_contract_level_count CHECK (element_count >= 0),
  CONSTRAINT ck_contract_level_provisional CHECK (NOT provisional OR data_class = 'SENSITIVE')
);
CREATE INDEX ix_contract_level_class ON ph09_privacy.contract_level (tenant_id, data_class);
CREATE TRIGGER tg_contract_level_touch BEFORE UPDATE ON ph09_privacy.contract_level FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.contract_level');
COMMENT ON TABLE ph09_privacy.contract_level IS 'EN-09-10 Mức phân loại tính được của hợp đồng API, topic, luồng (FR-09-006, BR-09-001, 004): mức cao nhất của các trường; provisional khi còn phần tử chưa CONFIRMED (tạm SENSITIVE); blocked khi có nhãn STATE_SECRET. Tính lại khi phân loại đổi (NFR-09-010).';
COMMENT ON COLUMN ph09_privacy.contract_level.basis IS 'Phần tử quyết định mức (mã phần tử, không giá trị).';
--rollback DROP TABLE IF EXISTS ph09_privacy.contract_level CASCADE;
