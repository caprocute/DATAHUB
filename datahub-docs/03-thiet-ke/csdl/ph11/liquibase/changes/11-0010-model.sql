--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0010-model.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0100-process-model
CREATE TABLE ph11_bpm.process_model (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  process_key        varchar(64) NOT NULL,
  name               varchar(200) NOT NULL,
  description        varchar(2000),
  group_code         varchar(32) NOT NULL DEFAULT 'KHAC',
  owner_org_code     varchar(32),
  default_due_value  integer,
  default_due_unit   varchar(16),
  allowed_starters   varchar(100)[] NOT NULL DEFAULT '{}',
  allow_manual_start boolean NOT NULL DEFAULT false,
  template_code      varchar(64),
  archived           boolean NOT NULL DEFAULT false,
  archive_reason     varchar(2000),
  latest_version     integer NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_model PRIMARY KEY (id),
  CONSTRAINT uq_process_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_process_model_key UNIQUE (tenant_id, process_key),
  CONSTRAINT uq_process_model_tid_key UNIQUE (tenant_id, id, process_key),
  CONSTRAINT ck_process_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_process_model_key CHECK (process_key ~ '^[A-Z][A-Z0-9_]{2,63}$'),
  CONSTRAINT ck_process_model_name CHECK (char_length(name) >= 3),
  CONSTRAINT ck_process_model_due CHECK ((default_due_value IS NULL) = (default_due_unit IS NULL)
    AND (default_due_value IS NULL OR (default_due_value BETWEEN 1 AND 3650 AND default_due_unit IN ('WORKING_DAY', 'WORKING_HOUR', 'CALENDAR_DAY', 'CALENDAR_HOUR')))),
  CONSTRAINT ck_process_model_archive CHECK (NOT archived OR archive_reason IS NOT NULL),
  CONSTRAINT ck_process_model_latest CHECK (latest_version >= 0)
);
CREATE INDEX ix_process_model_name ON ph11_bpm.process_model USING gin (name gin_trgm_ops);
CREATE INDEX ix_process_model_group ON ph11_bpm.process_model (tenant_id, group_code, archived);
CREATE TRIGGER tg_process_model_touch BEFORE UPDATE ON ph11_bpm.process_model FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_model_immutable BEFORE UPDATE ON ph11_bpm.process_model FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('process_key', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_model', 'P');
COMMENT ON TABLE ph11_bpm.process_model IS 'EN-11-01 Mô hình quy trình (FR-11-001, 002, 009). Khóa nghiệp vụ process_key ổn định qua các phiên bản (ví dụ LT_KHAI_SINH, DUYET_KET_NAP_HTTT); không xóa, chỉ archived kèm lý do. Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.process_model.process_key IS 'Khóa quy trình, duy nhất trong tenant; cũng là khóa định nghĩa quy trình khi triển khai lên Flowable.';
COMMENT ON COLUMN ph11_bpm.process_model.group_code IS 'Nhóm nghiệp vụ tự do để lọc (API: group), ví dụ TTHC_LIEN_THONG, DUYET_NOI_BO.';
COMMENT ON COLUMN ph11_bpm.process_model.default_due_value IS 'Hạn mặc định của phiên, kiểu T-DUE: giá trị (API defaultDue.value); đi cùng default_due_unit, cùng rỗng hoặc cùng có.';
COMMENT ON COLUMN ph11_bpm.process_model.default_due_unit IS 'Đơn vị hạn mặc định (DueUnit): WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR (API defaultDue.unit).';
COMMENT ON COLUMN ph11_bpm.process_model.allowed_starters IS 'Mã client hoặc HTTT được khởi tạo phiên qua API (FR-11-018); rỗng là chỉ vai trò có quyền PERM-11-instance.';
COMMENT ON COLUMN ph11_bpm.process_model.allow_manual_start IS 'Cho khởi tạo thủ công trên giao diện (FR-11-020).';
COMMENT ON COLUMN ph11_bpm.process_model.template_code IS 'Mẫu dùng chung đã dùng để tạo (tham chiếu logic tới process_template, không khóa ngoại vì mẫu có thể ở tenant COMMON).';
COMMENT ON COLUMN ph11_bpm.process_model.latest_version IS 'Số phiên bản lớn nhất đã tạo (0 khi chưa có); dịch vụ tăng khi tạo phiên bản mới.';
COMMENT ON COLUMN ph11_bpm.process_model.archive_reason IS 'Bắt buộc khi archived.';
--rollback DROP TABLE IF EXISTS ph11_bpm.process_model CASCADE;

--changeset ph11:ph11-0110-process-version
CREATE TABLE ph11_bpm.process_version (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  model_id              uuid NOT NULL,
  process_key           varchar(64) NOT NULL,
  version_no            integer NOT NULL,
  status                varchar(16) NOT NULL DEFAULT 'DRAFT',
  bpmn_xml              text NOT NULL,
  checksum              bytea NOT NULL,
  based_on              integer,
  change_summary        varchar(2000),
  validation_summary    jsonb,
  lock_owner            varchar(64),
  lock_until            timestamptz,
  deployment_id         varchar(64),
  process_definition_id varchar(128),
  published_at          timestamptz,
  deprecated_at         timestamptz,
  retired_at            timestamptz,
  retire_reason         varchar(2000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_version PRIMARY KEY (id),
  CONSTRAINT uq_process_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_process_version_no UNIQUE (tenant_id, process_key, version_no),
  CONSTRAINT ck_process_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_process_version_model FOREIGN KEY (tenant_id, model_id, process_key) REFERENCES ph11_bpm.process_model (tenant_id, id, process_key),
  CONSTRAINT ck_process_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_process_version_based CHECK (based_on IS NULL OR (based_on >= 1 AND based_on < version_no)),
  CONSTRAINT ck_process_version_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'PUBLISHED', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_process_version_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_process_version_size CHECK (octet_length(bpmn_xml) BETWEEN 1 AND 8388608),
  CONSTRAINT ck_process_version_validation CHECK (validation_summary IS NULL OR (jsonb_typeof(validation_summary) = 'object' AND validation_summary ? 'blocking')),
  CONSTRAINT ck_process_version_review CHECK (status IN ('DRAFT', 'RETIRED') OR (validation_summary IS NOT NULL AND validation_summary ->> 'blocking' = 'false')),
  CONSTRAINT ck_process_version_lock CHECK ((lock_owner IS NULL) = (lock_until IS NULL) AND (lock_owner IS NULL OR status = 'DRAFT')),
  CONSTRAINT ck_process_version_published CHECK (status NOT IN ('PUBLISHED', 'DEPRECATED') OR (published_at IS NOT NULL AND deployment_id IS NOT NULL AND process_definition_id IS NOT NULL)),
  CONSTRAINT ck_process_version_retired CHECK (status <> 'RETIRED' OR (retired_at IS NOT NULL AND char_length(retire_reason) >= 10))
);
CREATE UNIQUE INDEX uq_process_version_published ON ph11_bpm.process_version (tenant_id, model_id) WHERE status = 'PUBLISHED';
CREATE UNIQUE INDEX uq_process_version_deployment ON ph11_bpm.process_version (tenant_id, deployment_id) WHERE deployment_id IS NOT NULL;
CREATE UNIQUE INDEX uq_process_version_definition ON ph11_bpm.process_version (tenant_id, process_definition_id) WHERE process_definition_id IS NOT NULL;
CREATE INDEX ix_process_version_status ON ph11_bpm.process_version (tenant_id, status, process_key);
CREATE TRIGGER tg_process_version_touch BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_version_immutable BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('model_id', 'process_key', 'version_no', 'tenant_id');
CREATE TRIGGER tg_process_version_frozen BEFORE UPDATE ON ph11_bpm.process_version FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('IN_REVIEW,PUBLISHED,DEPRECATED,RETIRED', 'bpmn_xml', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_version', 'P');
COMMENT ON TABLE ph11_bpm.process_version IS 'EN-11-02 Phiên bản mô hình, chứa BPMN 2.0 XML và checksum (FR-11-003…010). Vòng đời DRAFT, IN_REVIEW, PUBLISHED, DEPRECATED, RETIRED; từ chối duyệt về DRAFT. Mỗi mô hình đúng một phiên bản PUBLISHED (phiên bản mới thay thì bản cũ thành DEPRECATED, phiên đang chạy vẫn chạy). Nội dung bất biến từ IN_REVIEW (BR-11-005). Chỉ PUBLISHED, DEPRECATED có deployment_id Flowable. Giữ vĩnh viễn (CV 631: truy vết phiên bản quy trình).';
COMMENT ON COLUMN ph11_bpm.process_version.model_id IS 'Mô hình cha; khóa ngoại kèm process_key để hai cột luôn khớp nhau.';
COMMENT ON COLUMN ph11_bpm.process_version.process_key IS 'Khử chuẩn từ process_model (ngoài FRS Phụ lục A), làm đích khóa ngoại của instance_index, migration_plan theo cặp (process_key, version_no).';
COMMENT ON COLUMN ph11_bpm.process_version.bpmn_xml IS 'Nội dung BPMN 2.0 XML, tối đa 8 MiB (trần của tham số 11.model.maxXmlKb); đã qua kiểm tra tĩnh phía máy chủ (FR-11-005, ADR 111).';
COMMENT ON COLUMN ph11_bpm.process_version.checksum IS 'SHA-256 của bpmn_xml (32 byte), dùng so sánh, xuất bằng chứng (BR-11-005, FR-11-064).';
COMMENT ON COLUMN ph11_bpm.process_version.based_on IS 'Số phiên bản làm gốc khi tạo nháp từ bản có sẵn.';
COMMENT ON COLUMN ph11_bpm.process_version.validation_summary IS 'Tóm tắt kiểm tra tĩnh gần nhất: blocking, errorCount, warningCount, checkedAt (API ValidationSummary); phải blocking = false trước khi gửi duyệt (FR-11-007).';
COMMENT ON COLUMN ph11_bpm.process_version.lock_owner IS 'Người đang giữ khóa soạn thảo (FR-11-003); chỉ bản DRAFT; hết hạn sau 11.designer.lockMinutes (lock_until).';
COMMENT ON COLUMN ph11_bpm.process_version.deployment_id IS 'Mã triển khai Flowable, ghi khi duyệt phát hành (FR-11-008).';
COMMENT ON COLUMN ph11_bpm.process_version.process_definition_id IS 'Mã định nghĩa quy trình Flowable (ACT_RE_PROCDEF.ID_) do lần triển khai tạo ra.';
--rollback DROP TABLE IF EXISTS ph11_bpm.process_version CASCADE;

--changeset ph11:ph11-0120-form-definition
CREATE TABLE ph11_bpm.form_definition (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  form_key             varchar(64) NOT NULL,
  version_no           integer NOT NULL DEFAULT 1,
  name                 varchar(200) NOT NULL,
  description          varchar(2000),
  status               varchar(16) NOT NULL DEFAULT 'DRAFT',
  schema               jsonb NOT NULL,
  ui_schema            jsonb NOT NULL DEFAULT '{}',
  decisions            varchar(24)[] NOT NULL DEFAULT '{COMPLETE}',
  field_classification jsonb NOT NULL DEFAULT '{}',
  checksum             bytea NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_form_definition PRIMARY KEY (id),
  CONSTRAINT uq_form_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_form_definition_no UNIQUE (tenant_id, form_key, version_no),
  CONSTRAINT ck_form_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_form_definition_key CHECK (form_key ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_form_definition_no CHECK (version_no >= 1),
  CONSTRAINT ck_form_definition_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_form_definition_schema CHECK (jsonb_typeof(schema) = 'object'),
  CONSTRAINT ck_form_definition_decisions CHECK (cardinality(decisions) >= 1 AND decisions <@ ARRAY['APPROVE', 'REJECT', 'RETURN', 'REQUEST_SUPPLEMENT', 'COMPLETE']::varchar[]),
  CONSTRAINT ck_form_definition_classification CHECK (jsonb_typeof(field_classification) = 'object'),
  CONSTRAINT ck_form_definition_checksum CHECK (octet_length(checksum) = 32)
);
CREATE UNIQUE INDEX uq_form_definition_published ON ph11_bpm.form_definition (tenant_id, form_key) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_form_definition_touch BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_form_definition_immutable BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('form_key', 'version_no', 'tenant_id');
CREATE TRIGGER tg_form_definition_frozen BEFORE UPDATE ON ph11_bpm.form_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'schema', 'ui_schema', 'decisions', 'field_classification', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.form_definition', 'P');
COMMENT ON TABLE ph11_bpm.form_definition IS 'EN-11-03 Biểu mẫu việc người dùng bằng JSON Schema (FR-11-012). Có phiên bản; mỗi form_key đúng một phiên bản PUBLISHED; PUBLISHED không đổi nội dung (BR-11-005; việc đang mở vẫn hiển thị đúng bản đã gắn). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.form_definition.schema IS 'JSON Schema (draft 2020-12) mô tả trường nhập; việc kiểm dữ liệu theo schema này khi hoàn thành việc (FR-11-038).';
COMMENT ON COLUMN ph11_bpm.form_definition.ui_schema IS 'Gợi ý bố cục, nhãn, thứ tự trường cho giao diện.';
COMMENT ON COLUMN ph11_bpm.form_definition.decisions IS 'Các quyết định cho phép khi hoàn thành việc (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE.';
COMMENT ON COLUMN ph11_bpm.form_definition.field_classification IS 'Phân loại dữ liệu từng trường (DataClass); trường SENSITIVE mã hóa khi lưu kết quả (BR-11-014).';
COMMENT ON COLUMN ph11_bpm.form_definition.checksum IS 'SHA-256 của schema, ui_schema, decisions (32 byte), chống sai lệch nội dung.';
--rollback DROP TABLE IF EXISTS ph11_bpm.form_definition CASCADE;

--changeset ph11:ph11-0130-service-intent
CREATE TABLE ph11_bpm.service_intent (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  intent_code     varchar(64) NOT NULL,
  name            varchar(200) NOT NULL,
  description     varchar(2000),
  status          varchar(16) NOT NULL DEFAULT 'ACTIVE',
  input_schema    jsonb,
  output_schema   jsonb,
  writes_external boolean NOT NULL DEFAULT false,
  business_errors jsonb NOT NULL DEFAULT '[]',
  bindings        jsonb NOT NULL DEFAULT '[]',
  timeout_seconds integer,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_service_intent PRIMARY KEY (id),
  CONSTRAINT uq_service_intent_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_service_intent_code UNIQUE (tenant_id, intent_code),
  CONSTRAINT ck_service_intent_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_service_intent_code CHECK (intent_code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_service_intent_status CHECK (status IN ('ACTIVE', 'DEPRECATED')),
  CONSTRAINT ck_service_intent_errors CHECK (jsonb_typeof(business_errors) = 'array'),
  CONSTRAINT ck_service_intent_bindings CHECK (jsonb_typeof(bindings) = 'array'),
  CONSTRAINT ck_service_intent_timeout CHECK (timeout_seconds IS NULL OR timeout_seconds BETWEEN 1 AND 604800)
);
CREATE TRIGGER tg_service_intent_touch BEFORE UPDATE ON ph11_bpm.service_intent FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_service_intent_immutable BEFORE UPDATE ON ph11_bpm.service_intent FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('intent_code', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.service_intent', 'P');
COMMENT ON TABLE ph11_bpm.service_intent IS 'EN-11-04 Ý định nghiệp vụ ánh xạ sang luồng PH-04 (FR-11-013, 028). Service task trong BPMN chỉ khai ý định (ví dụ guiTuPhap, BR-11-002); PH-11 gửi lệnh {tenant}.bpm.service.requested.v1, PH-04 thực thi (ADR 112). Phát hành mô hình yêu cầu mọi ý định được dùng đều ACTIVE có ánh xạ luồng ở môi trường đích (BR-11-003). Không xóa. Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.service_intent.input_schema IS 'JSON Schema của dữ liệu vào (API inputSchema); kiểm khi dựng lệnh (FR-11-028).';
COMMENT ON COLUMN ph11_bpm.service_intent.output_schema IS 'JSON Schema của kết quả (API outputSchema); kiểm khi nhận kết quả (FR-11-029).';
COMMENT ON COLUMN ph11_bpm.service_intent.writes_external IS 'Ý định ghi dữ liệu ra HTTT ngoài: bước dùng nó phải có bù trừ hoặc miễn đã duyệt (BR-11-008).';
COMMENT ON COLUMN ph11_bpm.service_intent.business_errors IS 'Mảng mã lỗi nghiệp vụ mà bước có thể ném BpmnError (API businessErrors).';
COMMENT ON COLUMN ph11_bpm.service_intent.bindings IS 'Mảng ánh xạ môi trường sang luồng PH-04: {environment (TEST, STAGING, PROD), flowCode, flowVersion}; mã luồng là tham chiếu logic liên phân hệ, kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph11_bpm.service_intent.timeout_seconds IS 'Thời gian chờ kết quả riêng của ý định (API timeoutSeconds); rỗng thì dùng tham số 11.service.defaultTimeoutMinutes; quá hạn mở sự cố SERVICE_TIMEOUT (FR-11-029).';
--rollback DROP TABLE IF EXISTS ph11_bpm.service_intent CASCADE;

--changeset ph11:ph11-0140-compensation-action
CREATE TABLE ph11_bpm.compensation_action (
  id                       uuid NOT NULL,
  tenant_id                varchar(16) NOT NULL,
  version_id               uuid NOT NULL,
  element_id               varchar(100) NOT NULL,
  policy                   varchar(16) NOT NULL DEFAULT 'AUTO',
  compensation_intent_code varchar(64),
  input_mapping            jsonb NOT NULL DEFAULT '{}',
  business_note            varchar(2000) NOT NULL,
  verify_intent_code       varchar(64),
  waiver_approved_by       varchar(64),
  created_at               timestamptz NOT NULL DEFAULT now(),
  created_by               varchar(64) NOT NULL,
  updated_at               timestamptz NOT NULL DEFAULT now(),
  updated_by               varchar(64) NOT NULL,
  version                  integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_compensation_action PRIMARY KEY (id),
  CONSTRAINT uq_compensation_action_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_compensation_action_step UNIQUE (tenant_id, version_id, element_id),
  CONSTRAINT ck_compensation_action_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_compensation_action_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT fk_compensation_action_intent FOREIGN KEY (tenant_id, compensation_intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT fk_compensation_action_verify FOREIGN KEY (tenant_id, verify_intent_code) REFERENCES ph11_bpm.service_intent (tenant_id, intent_code),
  CONSTRAINT ck_compensation_action_policy CHECK (policy IN ('AUTO', 'MANUAL', 'NONE_APPROVED')),
  CONSTRAINT ck_compensation_action_intent CHECK (policy <> 'AUTO' OR compensation_intent_code IS NOT NULL),
  CONSTRAINT ck_compensation_action_note CHECK (char_length(business_note) >= 20),
  CONSTRAINT ck_compensation_action_waiver CHECK (policy <> 'NONE_APPROVED' OR waiver_approved_by IS NOT NULL),
  CONSTRAINT ck_compensation_action_mapping CHECK (jsonb_typeof(input_mapping) = 'object')
);
CREATE TRIGGER tg_compensation_action_touch BEFORE UPDATE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_compensation_action_immutable BEFORE UPDATE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'element_id', 'tenant_id');
CREATE TRIGGER tg_compensation_action_child BEFORE INSERT OR UPDATE OR DELETE ON ph11_bpm.compensation_action FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_child_frozen();
CALL ph11_bpm.p_enable_rls('ph11_bpm.compensation_action', 'P');
COMMENT ON TABLE ph11_bpm.compensation_action IS 'EN-11-05 Hành động bù trừ theo bước của một phiên bản mô hình (FR-11-014, 051). Mỗi bước xuôi có tối đa một dòng; policy AUTO gọi ý định bù trừ, MANUAL chuyển việc xử lý thủ công, NONE_APPROVED là không bù trừ có miễn đã duyệt (BR-11-008, ví dụ không xóa khai sinh). Mọi dòng phải có ghi chú nghiệp vụ từ 20 ký tự (BR-11-009).';
COMMENT ON COLUMN ph11_bpm.compensation_action.element_id IS 'Id phần tử BPMN của bước xuôi cần bù trừ.';
COMMENT ON COLUMN ph11_bpm.compensation_action.compensation_intent_code IS 'Ý định bù trừ gửi PH-04; bắt buộc khi AUTO.';
COMMENT ON COLUMN ph11_bpm.compensation_action.input_mapping IS 'Ánh xạ dữ liệu vào cho lệnh bù trừ (API inputMapping).';
COMMENT ON COLUMN ph11_bpm.compensation_action.verify_intent_code IS 'Ý định kiểm tra hiệu lực bù trừ ở hệ thống đích, dùng khi đối soát (FR-11-054).';
COMMENT ON COLUMN ph11_bpm.compensation_action.waiver_approved_by IS 'Người có quyền duyệt miễn bù trừ; bắt buộc khi NONE_APPROVED (BR-11-008).';
--rollback DROP TABLE IF EXISTS ph11_bpm.compensation_action CASCADE;

--changeset ph11:ph11-0150-process-template
CREATE TABLE ph11_bpm.process_template (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL DEFAULT 'COMMON',
  template_code varchar(64) NOT NULL,
  version_no    integer NOT NULL DEFAULT 1,
  name          varchar(200) NOT NULL,
  description   varchar(2000),
  group_code    varchar(32) NOT NULL DEFAULT 'KHAC',
  status        varchar(16) NOT NULL DEFAULT 'DRAFT',
  source_xml    text NOT NULL,
  placeholders  jsonb NOT NULL DEFAULT '[]',
  checksum      bytea NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_process_template PRIMARY KEY (id),
  CONSTRAINT uq_process_template_no UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_process_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_process_template_code CHECK (template_code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_process_template_no CHECK (version_no >= 1),
  CONSTRAINT ck_process_template_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_process_template_placeholders CHECK (jsonb_typeof(placeholders) = 'array'),
  CONSTRAINT ck_process_template_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_process_template_size CHECK (octet_length(source_xml) BETWEEN 1 AND 8388608)
);
CREATE UNIQUE INDEX uq_process_template_published ON ph11_bpm.process_template (tenant_id, template_code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_process_template_touch BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_process_template_immutable BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('template_code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_process_template_frozen BEFORE UPDATE ON ph11_bpm.process_template FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'source_xml', 'placeholders', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.process_template', 'S');
COMMENT ON TABLE ph11_bpm.process_template IS 'EN-11-06 Mẫu quy trình dùng chung (FR-11-015). Mẫu nền tảng ở tenant COMMON chỉ PA ghi (phiên PLATFORM, BR-11-027); mọi tenant đọc được (mẫu S) và tự tạo mẫu riêng. Tạo mô hình từ mẫu là sao chép source_xml, mô hình chỉ lưu template_code. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn.';
COMMENT ON COLUMN ph11_bpm.process_template.placeholders IS 'Mảng tên chỗ giữ chỗ (ví dụ mã ý định, nhóm xử lý) người dùng phải điền khi tạo mô hình từ mẫu.';
--rollback DROP TABLE IF EXISTS ph11_bpm.process_template CASCADE;

--changeset ph11:ph11-0160-variable-definition
CREATE TABLE ph11_bpm.variable_definition (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  version_id        uuid NOT NULL,
  name              varchar(64) NOT NULL,
  type              varchar(12) NOT NULL DEFAULT 'STRING',
  required_at_start boolean NOT NULL DEFAULT false,
  data_class        varchar(16) NOT NULL DEFAULT 'INTERNAL',
  encrypt           boolean NOT NULL DEFAULT false,
  mask              boolean NOT NULL DEFAULT false,
  editable_by       varchar(16) NOT NULL DEFAULT 'NONE',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_variable_definition PRIMARY KEY (id),
  CONSTRAINT uq_variable_definition_name UNIQUE (tenant_id, version_id, name),
  CONSTRAINT ck_variable_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_variable_definition_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_variable_definition_name CHECK (name ~ '^[a-z][A-Za-z0-9]{1,63}$' AND name NOT IN ('businessKey', 'initiator', 'tenantId')),
  CONSTRAINT ck_variable_definition_type CHECK (type IN ('STRING', 'NUMBER', 'BOOLEAN', 'DATE', 'DATETIME', 'JSON', 'CODE_REF', 'FILE_REF')),
  CONSTRAINT ck_variable_definition_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_variable_definition_editable CHECK (editable_by IN ('NONE', 'TASK', 'ADMIN_CHANGE')),
  CONSTRAINT ck_variable_definition_sensitive CHECK (data_class <> 'SENSITIVE' OR (encrypt AND mask)),
  CONSTRAINT ck_variable_definition_restricted CHECK (data_class <> 'RESTRICTED' OR mask)
);
CREATE TRIGGER tg_variable_definition_touch BEFORE UPDATE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_variable_definition_immutable BEFORE UPDATE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'name', 'tenant_id');
CREATE TRIGGER tg_variable_definition_child BEFORE INSERT OR UPDATE OR DELETE ON ph11_bpm.variable_definition FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_child_frozen();
CALL ph11_bpm.p_enable_rls('ph11_bpm.variable_definition', 'P');
COMMENT ON TABLE ph11_bpm.variable_definition IS 'EN-11-07 Khai báo biến quy trình và phân loại dữ liệu (FR-11-016). RESTRICTED (hạn chế) phải che ở tiến độ và bản chiếu; SENSITIVE (nhạy cảm) phải mã hóa envelope trước khi vào engine và che, không bao giờ lộ ra tiến độ, sự kiện, nhật ký (BR-11-014, 015; CMP-LAW-04, 05).';
COMMENT ON COLUMN ph11_bpm.variable_definition.type IS 'Kiểu biến (VariableType): STRING, NUMBER, BOOLEAN, DATE, DATETIME, JSON, CODE_REF, FILE_REF.';
COMMENT ON COLUMN ph11_bpm.variable_definition.data_class IS 'Phân loại theo PH-09 (DataClass): PUBLIC, INTERNAL, RESTRICTED (HC), SENSITIVE (NC).';
COMMENT ON COLUMN ph11_bpm.variable_definition.encrypt IS 'Giá trị mã hóa envelope (OpenBao transit, ADR-032) và lưu ở engine dưới dạng tham chiếu bpm-secret; bắt buộc với SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.variable_definition.mask IS 'Che giá trị khi hiển thị cho người không có quyền xem rõ; bắt buộc với RESTRICTED, SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.variable_definition.editable_by IS 'Ai được sửa giá trị khi phiên chạy: NONE, TASK (qua việc), ADMIN_CHANGE (qua đề nghị instance_change, FR-11-025).';
--rollback DROP TABLE IF EXISTS ph11_bpm.variable_definition CASCADE;

--changeset ph11:ph11-0170-decision-table
CREATE TABLE ph11_bpm.decision_table (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  code        varchar(64) NOT NULL,
  version_no  integer NOT NULL DEFAULT 1,
  name        varchar(200) NOT NULL,
  status      varchar(16) NOT NULL DEFAULT 'DRAFT',
  hit_policy  varchar(8) NOT NULL DEFAULT 'UNIQUE',
  inputs      jsonb NOT NULL,
  outputs     jsonb NOT NULL,
  rules       jsonb NOT NULL DEFAULT '[]',
  checksum    bytea NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_decision_table PRIMARY KEY (id),
  CONSTRAINT uq_decision_table_no UNIQUE (tenant_id, code, version_no),
  CONSTRAINT ck_decision_table_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_decision_table_code CHECK (code ~ '^[A-Za-z][A-Za-z0-9_.-]{0,63}$'),
  CONSTRAINT ck_decision_table_no CHECK (version_no >= 1),
  CONSTRAINT ck_decision_table_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_decision_table_hit CHECK (hit_policy IN ('UNIQUE', 'FIRST')),
  CONSTRAINT ck_decision_table_shape CHECK (jsonb_typeof(inputs) = 'array' AND jsonb_array_length(inputs) >= 1 AND jsonb_typeof(outputs) = 'array' AND jsonb_array_length(outputs) >= 1 AND jsonb_typeof(rules) = 'array'),
  CONSTRAINT ck_decision_table_checksum CHECK (octet_length(checksum) = 32)
);
CREATE UNIQUE INDEX uq_decision_table_published ON ph11_bpm.decision_table (tenant_id, code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_decision_table_touch BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_decision_table_immutable BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('code', 'version_no', 'tenant_id');
CREATE TRIGGER tg_decision_table_frozen BEFORE UPDATE ON ph11_bpm.decision_table FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_frozen('PUBLISHED,RETIRED', 'inputs', 'outputs', 'rules', 'hit_policy', 'checksum');
CALL ph11_bpm.p_enable_rls('ph11_bpm.decision_table', 'P');
COMMENT ON TABLE ph11_bpm.decision_table IS 'EN-11-24 Bảng quyết định DMN đơn giản cho rẽ nhánh (FR-11-017, mức C). Chính sách trúng UNIQUE hoặc FIRST; lưu dạng inputs, outputs, rules, dịch vụ sinh DMN XML khi triển khai cùng phiên bản mô hình. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn theo phiên bản.';
COMMENT ON COLUMN ph11_bpm.decision_table.inputs IS 'Mảng biến đầu vào của bảng (tên biến, kiểu).';
COMMENT ON COLUMN ph11_bpm.decision_table.outputs IS 'Mảng biến đầu ra của bảng.';
COMMENT ON COLUMN ph11_bpm.decision_table.rules IS 'Mảng dòng quy tắc: điều kiện FEEL đơn giản theo từng đầu vào và giá trị đầu ra.';
COMMENT ON COLUMN ph11_bpm.decision_table.checksum IS 'SHA-256 của inputs, outputs, rules, hit_policy (32 byte).';
--rollback DROP TABLE IF EXISTS ph11_bpm.decision_table CASCADE;

--changeset ph11:ph11-0180-publish-request
CREATE TABLE ph11_bpm.publish_request (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  version_id    uuid NOT NULL,
  kind          varchar(12) NOT NULL DEFAULT 'PUBLISH',
  release_note  varchar(2000) NOT NULL,
  checksum      bytea NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'PENDING',
  requested_by  varchar(64) NOT NULL,
  requested_at  timestamptz NOT NULL DEFAULT now(),
  decided_by    varchar(64),
  decided_at    timestamptz,
  comment       varchar(2000),
  task_id       uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_publish_request PRIMARY KEY (id),
  CONSTRAINT uq_publish_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_publish_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_publish_request_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_publish_request_kind CHECK (kind IN ('PUBLISH', 'RESTORE', 'TEMPLATE')),
  CONSTRAINT ck_publish_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'DEPLOY_FAILED')),
  CONSTRAINT ck_publish_request_note CHECK (char_length(release_note) >= 10),
  CONSTRAINT ck_publish_request_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_publish_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_publish_request_decided CHECK (status NOT IN ('APPROVED', 'REJECTED', 'DEPLOY_FAILED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND char_length(btrim(comment)) >= 1)),
  CONSTRAINT ck_publish_request_reject CHECK (status <> 'REJECTED' OR char_length(comment) >= 20)
);
CREATE UNIQUE INDEX uq_publish_request_pending ON ph11_bpm.publish_request (tenant_id, version_id, kind) WHERE status = 'PENDING';
CREATE INDEX ix_publish_request_status ON ph11_bpm.publish_request (tenant_id, status, requested_at DESC);
CREATE TRIGGER tg_publish_request_touch BEFORE UPDATE ON ph11_bpm.publish_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_publish_request_immutable BEFORE UPDATE ON ph11_bpm.publish_request FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'kind', 'release_note', 'checksum', 'requested_by', 'requested_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.publish_request', 'P');
COMMENT ON TABLE ph11_bpm.publish_request IS 'EN-11-20 Yêu cầu duyệt phát hành, khôi phục hoặc đưa mẫu lên dùng chung (FR-11-007, 008), bốn mắt: người duyệt khác người gửi (BR-11-004, PERM-11-publish). Ghi chú thay đổi từ 10 ký tự; duyệt cần ý kiến, từ chối cần lý do từ 20 ký tự (BR-11-033). DEPLOY_FAILED khi duyệt xong nhưng triển khai lên engine lỗi. Mỗi phiên bản, mỗi loại yêu cầu chỉ một yêu cầu PENDING.';
COMMENT ON COLUMN ph11_bpm.publish_request.kind IS 'Loại yêu cầu (API kind): PUBLISH phát hành bản mới, RESTORE khôi phục bản đã ngừng dùng, TEMPLATE đưa lên mẫu dùng chung.';
COMMENT ON COLUMN ph11_bpm.publish_request.checksum IS 'SHA-256 BPMN XML tại lúc gửi; người duyệt xem đúng bản đã kiểm, nội dung đổi thì không còn khớp.';
COMMENT ON COLUMN ph11_bpm.publish_request.comment IS 'Ý kiến của người duyệt (bắt buộc khi quyết định); lý do từ 20 ký tự khi từ chối.';
COMMENT ON COLUMN ph11_bpm.publish_request.task_id IS 'Việc duyệt trong hộp việc (task_index.id, task_kind PUBLISH_REVIEW), tham chiếu logic.';
--rollback DROP TABLE IF EXISTS ph11_bpm.publish_request CASCADE;

--changeset ph11:ph11-0190-test-run
CREATE TABLE ph11_bpm.test_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  version_id         uuid NOT NULL,
  scenario           jsonb NOT NULL DEFAULT '{}',
  status             varchar(8) NOT NULL DEFAULT 'RUNNING',
  engine_instance_id varchar(64),
  result             jsonb,
  ended_at           timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_test_run PRIMARY KEY (id),
  CONSTRAINT uq_test_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_test_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_test_run_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph11_bpm.process_version (tenant_id, id),
  CONSTRAINT ck_test_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ABORTED')),
  CONSTRAINT ck_test_run_scenario CHECK (jsonb_typeof(scenario) = 'object'),
  CONSTRAINT ck_test_run_ended CHECK ((status = 'RUNNING') = (ended_at IS NULL)),
  CONSTRAINT ck_test_run_result CHECK (result IS NULL OR jsonb_typeof(result) = 'object')
);
CREATE INDEX ix_test_run_version ON ph11_bpm.test_run (tenant_id, version_id, created_at DESC);
CREATE INDEX ix_test_run_cleanup ON ph11_bpm.test_run (created_at);
CREATE TRIGGER tg_test_run_touch BEFORE UPDATE ON ph11_bpm.test_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_test_run_immutable BEFORE UPDATE ON ph11_bpm.test_run FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('version_id', 'scenario', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.test_run', 'P');
COMMENT ON TABLE ph11_bpm.test_run IS 'EN-11-26 Lần chạy thử một phiên bản nháp với service task giả lập (FR-11-011, API-11-025…027). Phiên chạy thử là dòng instance_index có start_channel TEST; không ghi outbox, không gửi lệnh PH-04, triển khai vào tenantId Flowable thử (BR-11-036). Kết quả (dòng thời gian, biến đã che, việc, Saga) ở result, đính kèm yêu cầu duyệt. Dọn sau 11.test.retentionDays ngày.';
COMMENT ON COLUMN ph11_bpm.test_run.scenario IS 'Kịch bản giả lập: kết quả cho từng service task (COMPLETE, BUSINESS_ERROR, TECHNICAL_ERROR, TIMEOUT), đồng hồ REAL hoặc ACCELERATED, tự hoàn thành việc.';
COMMENT ON COLUMN ph11_bpm.test_run.engine_instance_id IS 'Mã phiên chạy thử trong Flowable.';
COMMENT ON COLUMN ph11_bpm.test_run.result IS 'Kết quả chạy: timeline, variables (đã che), tasks, saga (API TestRun); không chứa giá trị SENSITIVE.';
--rollback DROP TABLE IF EXISTS ph11_bpm.test_run CASCADE;
