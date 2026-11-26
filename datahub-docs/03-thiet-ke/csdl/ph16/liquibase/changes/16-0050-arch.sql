--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0050-arch.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0350-kpi-arch-component
CREATE TABLE ph16_kpi.kpi_arch_component (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  component_code        varchar(63) NOT NULL,
  name                  varchar(255) NOT NULL,
  component_type        varchar(16) NOT NULL,
  lifecycle             varchar(10) NOT NULL DEFAULT 'PLANNED',
  ops_status            varchar(8) NOT NULL DEFAULT 'UNKNOWN',
  ops_updated_at        timestamptz,
  origin                varchar(6) NOT NULL DEFAULT 'MANUAL',
  owner_org_code        varchar(63),
  source_phase          varchar(5),
  source_ref            varchar(255),
  current_version_label varchar(32),
  compliance_level      varchar(13) NOT NULL DEFAULT 'NOT_ASSESSED',
  last_synced_at        timestamptz,
  orphaned              boolean NOT NULL DEFAULT false,
  retire_reason         varchar(2000),
  description           varchar(2000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_arch_component PRIMARY KEY (id),
  CONSTRAINT uq_kpi_arch_component_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_arch_component_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_arch_component_code UNIQUE (tenant_id, component_code),
  CONSTRAINT ck_kpi_arch_component_code CHECK (component_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_arch_component_type CHECK (component_type IN ('HTTT', 'API', 'FLOW', 'TOPIC', 'ADAPTER', 'PLATFORM_SERVICE', 'NATIONAL_LINK')),
  CONSTRAINT ck_kpi_arch_component_lifecycle CHECK (lifecycle IN ('PLANNED', 'ACTIVE', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_kpi_arch_component_ops CHECK (ops_status IN ('UP', 'DEGRADED', 'DOWN', 'UNKNOWN')),
  CONSTRAINT ck_kpi_arch_component_origin CHECK (origin IN ('AUTO', 'MANUAL') AND (origin <> 'AUTO' OR source_phase IS NOT NULL)),
  CONSTRAINT ck_kpi_arch_component_phase CHECK (source_phase IS NULL OR source_phase ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_kpi_arch_component_owner CHECK (owner_org_code IS NULL OR owner_org_code ~ '^[A-Za-z0-9][A-Za-z0-9._-]{1,62}$'),
  CONSTRAINT ck_kpi_arch_component_compliance CHECK (compliance_level IN ('NOT_ASSESSED', 'COMPLIANT', 'PARTIAL', 'NON_COMPLIANT', 'EXEMPTED')),
  CONSTRAINT ck_kpi_arch_component_retire CHECK (lifecycle <> 'RETIRED' OR COALESCE(char_length(retire_reason) >= 20, false))
);
CREATE INDEX ix_kpi_arch_component_type ON ph16_kpi.kpi_arch_component (tenant_id, component_type, lifecycle);
CREATE INDEX ix_kpi_arch_component_compliance ON ph16_kpi.kpi_arch_component (tenant_id, compliance_level, lifecycle);
CREATE INDEX ix_kpi_arch_component_orphan ON ph16_kpi.kpi_arch_component (tenant_id, last_synced_at) WHERE origin = 'AUTO';
CREATE TRIGGER tg_kpi_arch_component_touch BEFORE UPDATE ON ph16_kpi.kpi_arch_component FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_arch_component_immutable BEFORE UPDATE ON ph16_kpi.kpi_arch_component FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'component_code', 'component_type');
CREATE TRIGGER tg_kpi_arch_component_transition BEFORE UPDATE ON ph16_kpi.kpi_arch_component FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('lifecycle', '{"PLANNED":["ACTIVE","RETIRED"],"ACTIVE":["DEPRECATED","RETIRED"],"DEPRECATED":["ACTIVE","RETIRED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_arch_component');
COMMENT ON TABLE ph16_kpi.kpi_arch_component IS 'EN-16-26 Thành phần kiến trúc của sổ kiến trúc: HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền tảng, liên kết quốc gia; vòng đời PLANNED, ACTIVE, DEPRECATED, RETIRED, trạng thái vận hành UP, DEGRADED, DOWN, UNKNOWN, nguồn gốc AUTO hoặc MANUAL, mức tuân thủ hiện hành (FR-16-043, 044, 045, 046, 048). Không xóa, chỉ ngừng.';
COMMENT ON COLUMN ph16_kpi.kpi_arch_component.origin IS 'AUTO: tự đăng ký từ sự kiện phân hệ nguồn hoặc `arch.register`; MANUAL: khai báo tay (FR-16-045).';
COMMENT ON COLUMN ph16_kpi.kpi_arch_component.orphaned IS 'Đối chiếu với phân hệ nguồn thấy thành phần AUTO không còn ở nguồn (FR-16-048).';
COMMENT ON COLUMN ph16_kpi.kpi_arch_component.compliance_level IS 'Bản sao mức của đánh giá CONFIRMED mới nhất hoặc EXEMPTED khi có miễn trừ hiệu lực; nguồn chuẩn ở `kpi_compliance_assessment`.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_arch_component CASCADE;

--changeset ph16:ph16-0360-kpi-arch-component-version
CREATE TABLE ph16_kpi.kpi_arch_component_version (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  component_id  uuid NOT NULL,
  version_label varchar(32) NOT NULL,
  lifecycle     varchar(10) NOT NULL DEFAULT 'PLANNED',
  released_on   date,
  spec_ref      varchar(255),
  content_hash  bytea,
  origin        varchar(6) NOT NULL DEFAULT 'MANUAL',
  change_note   varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_arch_component_version PRIMARY KEY (id),
  CONSTRAINT uq_kpi_arch_component_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_arch_component_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_arch_component_version UNIQUE (tenant_id, component_id, version_label),
  CONSTRAINT fk_kpi_arch_component_version_component FOREIGN KEY (tenant_id, component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT ck_kpi_arch_component_version_label CHECK (version_label ~ '^[0-9A-Za-z][0-9A-Za-z._+-]{0,31}$'),
  CONSTRAINT ck_kpi_arch_component_version_lifecycle CHECK (lifecycle IN ('PLANNED', 'ACTIVE', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_kpi_arch_component_version_origin CHECK (origin IN ('AUTO', 'MANUAL')),
  CONSTRAINT ck_kpi_arch_component_version_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32)
);
CREATE TRIGGER tg_kpi_arch_component_version_touch BEFORE UPDATE ON ph16_kpi.kpi_arch_component_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_arch_component_version_immutable BEFORE UPDATE ON ph16_kpi.kpi_arch_component_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'component_id', 'version_label');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_arch_component_version');
COMMENT ON TABLE ph16_kpi.kpi_arch_component_version IS 'EN-16-27 Phiên bản thành phần kiến trúc: nhãn phiên bản, trạng thái vòng đời của phiên bản, ngày phát hành, mã băm nội dung mô tả dùng cho gói gửi quốc gia (FR-16-045, 052).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_arch_component_version CASCADE;

--changeset ph16:ph16-0370-kpi-arch-dependency
CREATE TABLE ph16_kpi.kpi_arch_dependency (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  from_component_id uuid NOT NULL,
  to_component_id   uuid NOT NULL,
  dependency_type   varchar(10) NOT NULL,
  origin            varchar(6) NOT NULL DEFAULT 'MANUAL',
  removed           boolean NOT NULL DEFAULT false,
  description       varchar(2000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_arch_dependency PRIMARY KEY (id),
  CONSTRAINT ck_kpi_arch_dependency_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_arch_dependency UNIQUE (tenant_id, from_component_id, to_component_id, dependency_type),
  CONSTRAINT fk_kpi_arch_dependency_from FOREIGN KEY (tenant_id, from_component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT fk_kpi_arch_dependency_to FOREIGN KEY (tenant_id, to_component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT ck_kpi_arch_dependency_self CHECK (from_component_id <> to_component_id),
  CONSTRAINT ck_kpi_arch_dependency_type CHECK (dependency_type IN ('CALLS', 'PUBLISHES', 'SUBSCRIBES', 'HOSTS', 'DEPENDS_ON')),
  CONSTRAINT ck_kpi_arch_dependency_origin CHECK (origin IN ('AUTO', 'MANUAL'))
);
CREATE INDEX ix_kpi_arch_dependency_to ON ph16_kpi.kpi_arch_dependency (tenant_id, to_component_id) WHERE NOT removed;
CREATE TRIGGER tg_kpi_arch_dependency_touch BEFORE UPDATE ON ph16_kpi.kpi_arch_dependency FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_arch_dependency_immutable BEFORE UPDATE ON ph16_kpi.kpi_arch_dependency FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'from_component_id', 'to_component_id', 'dependency_type');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_arch_dependency');
COMMENT ON TABLE ph16_kpi.kpi_arch_dependency IS 'EN-16-28 Phụ thuộc giữa hai thành phần: gọi, phát, đăng ký nhận, chạy trên, phụ thuộc; phục vụ sơ đồ phụ thuộc và phân tích ảnh hưởng (FR-16-045, 049). Gỡ phụ thuộc bằng cờ `removed`, không xóa dòng.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_arch_dependency CASCADE;

--changeset ph16:ph16-0380-kpi-arch-reconciliation
CREATE TABLE ph16_kpi.kpi_arch_reconciliation (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  state           varchar(9) NOT NULL DEFAULT 'RUNNING',
  component_types text[] NOT NULL DEFAULT '{}',
  started_by      varchar(64) NOT NULL,
  started_at      timestamptz NOT NULL DEFAULT now(),
  finished_at     timestamptz,
  item_count      integer NOT NULL DEFAULT 0,
  skipped_phases  text[] NOT NULL DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_arch_reconciliation PRIMARY KEY (id),
  CONSTRAINT uq_kpi_arch_reconciliation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_arch_reconciliation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_kpi_arch_reconciliation_state CHECK (state IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED')),
  CONSTRAINT ck_kpi_arch_reconciliation_types CHECK (component_types <@ ARRAY['HTTT', 'API', 'FLOW', 'TOPIC', 'ADAPTER', 'PLATFORM_SERVICE', 'NATIONAL_LINK']::text[]),
  CONSTRAINT ck_kpi_arch_reconciliation_finished CHECK ((state = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_kpi_arch_reconciliation_partial CHECK (state <> 'PARTIAL' OR cardinality(skipped_phases) >= 1),
  CONSTRAINT ck_kpi_arch_reconciliation_count CHECK (item_count >= 0)
);
CREATE UNIQUE INDEX uq_kpi_arch_reconciliation_running ON ph16_kpi.kpi_arch_reconciliation (tenant_id) WHERE state = 'RUNNING';
CREATE INDEX ix_kpi_arch_reconciliation_time ON ph16_kpi.kpi_arch_reconciliation (tenant_id, started_at DESC);
CREATE TRIGGER tg_kpi_arch_reconciliation_touch BEFORE UPDATE ON ph16_kpi.kpi_arch_reconciliation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_arch_reconciliation_immutable BEFORE UPDATE ON ph16_kpi.kpi_arch_reconciliation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'component_types', 'started_by', 'started_at');
CREATE TRIGGER tg_kpi_arch_reconciliation_transition BEFORE UPDATE ON ph16_kpi.kpi_arch_reconciliation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"RUNNING":["SUCCEEDED","PARTIAL","FAILED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_arch_reconciliation');
COMMENT ON TABLE ph16_kpi.kpi_arch_reconciliation IS 'EN-16-33 Lần đối chiếu sổ kiến trúc với phân hệ nguồn (hằng tuần hoặc chạy tay): RUNNING, SUCCEEDED, PARTIAL (có phân hệ không trả lời), FAILED; mỗi tenant tối đa một lần đang chạy (ERR-16-056) (FR-16-048).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_arch_reconciliation CASCADE;

--changeset ph16:ph16-0390-kpi-arch-recon-item
CREATE TABLE ph16_kpi.kpi_arch_recon_item (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  recon_id          uuid NOT NULL,
  item_kind         varchar(8) NOT NULL,
  component_code    varchar(63) NOT NULL,
  component_id      uuid,
  source_phase      varchar(5) NOT NULL,
  source_ref        varchar(255),
  diff              jsonb NOT NULL DEFAULT '{}',
  resolution        varchar(10) NOT NULL DEFAULT 'OPEN',
  resolution_reason varchar(2000),
  resolved_by       varchar(64),
  resolved_at       timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_arch_recon_item PRIMARY KEY (id),
  CONSTRAINT ck_kpi_arch_recon_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_arch_recon_item UNIQUE (tenant_id, recon_id, item_kind, component_code),
  CONSTRAINT fk_kpi_arch_recon_item_recon FOREIGN KEY (tenant_id, recon_id) REFERENCES ph16_kpi.kpi_arch_reconciliation (tenant_id, id),
  CONSTRAINT fk_kpi_arch_recon_item_component FOREIGN KEY (tenant_id, component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT ck_kpi_arch_recon_item_kind CHECK (item_kind IN ('MISSING', 'ORPHAN', 'MISMATCH')),
  CONSTRAINT ck_kpi_arch_recon_item_resolution CHECK (resolution IN ('OPEN', 'REGISTERED', 'RETIRED', 'UPDATED', 'IGNORED')),
  CONSTRAINT ck_kpi_arch_recon_item_phase CHECK (source_phase ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_kpi_arch_recon_item_orphan CHECK (item_kind = 'MISSING' OR component_id IS NOT NULL),
  CONSTRAINT ck_kpi_arch_recon_item_diff CHECK (jsonb_typeof(diff) = 'object'),
  CONSTRAINT ck_kpi_arch_recon_item_resolved CHECK ((resolution = 'OPEN') = (resolved_by IS NULL AND resolved_at IS NULL)),
  CONSTRAINT ck_kpi_arch_recon_item_ignored CHECK (resolution <> 'IGNORED' OR COALESCE(char_length(resolution_reason) >= 20, false))
);
CREATE INDEX ix_kpi_arch_recon_item_open ON ph16_kpi.kpi_arch_recon_item (tenant_id, recon_id) WHERE resolution = 'OPEN';
CREATE TRIGGER tg_kpi_arch_recon_item_touch BEFORE UPDATE ON ph16_kpi.kpi_arch_recon_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_arch_recon_item_immutable BEFORE UPDATE ON ph16_kpi.kpi_arch_recon_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'recon_id', 'item_kind', 'component_code', 'source_phase', 'source_ref', 'diff');
CREATE TRIGGER tg_kpi_arch_recon_item_transition BEFORE UPDATE ON ph16_kpi.kpi_arch_recon_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('resolution', '{"OPEN":["REGISTERED","RETIRED","UPDATED","IGNORED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_arch_recon_item');
COMMENT ON TABLE ph16_kpi.kpi_arch_recon_item IS 'EN-16-33 Mục lệch của lần đối chiếu: MISSING (nguồn có, sổ không), ORPHAN (sổ có, nguồn không), MISMATCH (vòng đời, phiên bản khác); xử lý OPEN, REGISTERED, RETIRED, UPDATED hoặc IGNORED kèm lý do (FR-16-048, ERR-16-120).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_arch_recon_item CASCADE;

--changeset ph16:ph16-0400-kpi-compliance-criterion
CREATE TABLE ph16_kpi.kpi_compliance_criterion (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  criterion_code varchar(32) NOT NULL,
  version_no     integer NOT NULL DEFAULT 1,
  name           varchar(255) NOT NULL,
  description    varchar(2000),
  applies_to     text[] NOT NULL,
  mandatory      boolean NOT NULL DEFAULT false,
  weight         numeric(5,4) NOT NULL DEFAULT 1.0000,
  framework_ref  varchar(64),
  state          varchar(10) NOT NULL DEFAULT 'DRAFT',
  activated_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_compliance_criterion PRIMARY KEY (id),
  CONSTRAINT uq_kpi_compliance_criterion_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_criterion_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_compliance_criterion_version UNIQUE (tenant_id, criterion_code, version_no),
  CONSTRAINT ck_kpi_compliance_criterion_code CHECK (criterion_code ~ '^[A-Z][A-Z0-9-]{2,31}$'),
  CONSTRAINT ck_kpi_compliance_criterion_no CHECK (version_no >= 1),
  CONSTRAINT ck_kpi_compliance_criterion_applies CHECK (cardinality(applies_to) >= 1 AND applies_to <@ ARRAY['HTTT', 'API', 'FLOW', 'TOPIC', 'ADAPTER', 'PLATFORM_SERVICE', 'NATIONAL_LINK']::text[]),
  CONSTRAINT ck_kpi_compliance_criterion_weight CHECK (weight >= 0 AND weight <= 1),
  CONSTRAINT ck_kpi_compliance_criterion_state CHECK (state IN ('DRAFT', 'ACTIVE', 'SUPERSEDED')),
  CONSTRAINT ck_kpi_compliance_criterion_active CHECK (state = 'DRAFT' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_kpi_compliance_criterion_active ON ph16_kpi.kpi_compliance_criterion (tenant_id, criterion_code) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_kpi_compliance_criterion_touch BEFORE UPDATE ON ph16_kpi.kpi_compliance_criterion FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_compliance_criterion_immutable BEFORE UPDATE ON ph16_kpi.kpi_compliance_criterion FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'criterion_code', 'version_no');
CREATE TRIGGER tg_kpi_compliance_criterion_frozen BEFORE UPDATE ON ph16_kpi.kpi_compliance_criterion FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'ACTIVE,SUPERSEDED', 'applies_to', 'mandatory', 'weight', 'framework_ref');
CREATE TRIGGER tg_kpi_compliance_criterion_transition BEFORE UPDATE ON ph16_kpi.kpi_compliance_criterion FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["ACTIVE"],"ACTIVE":["SUPERSEDED"]}');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_compliance_criterion');
COMMENT ON TABLE ph16_kpi.kpi_compliance_criterion IS 'EN-16-29, EN-16-30 Tiêu chí tuân thủ kiến trúc: bộ tiêu chí cấu hình có phiên bản, áp cho loại thành phần, có trọng số và cờ bắt buộc; bộ mẫu COMMON theo Khung kiến trúc CPĐT 3.0 (CMP-LAW-10) và dự thảo Khung kiến trúc tổng thể quốc gia số (CMP-LAW-11) khi ban hành (FR-16-047). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON mọi tenant đọc được (mẫu RLS S).';
COMMENT ON COLUMN ph16_kpi.kpi_compliance_criterion.framework_ref IS 'Mã CMP-LAW hoặc điều khoản khung kiến trúc nếu có; để NULL khi tiêu chí tối thiểu của sổ chưa đối chiếu khung (Q16-53).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_compliance_criterion CASCADE;

--changeset ph16:ph16-0410-kpi-compliance-assessment
CREATE TABLE ph16_kpi.kpi_compliance_assessment (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  component_id         uuid NOT NULL,
  component_version_id uuid,
  state                varchar(9) NOT NULL DEFAULT 'DRAFT',
  level_result         varchar(13),
  score                numeric(5,2),
  summary              varchar(4000),
  assessed_by          varchar(64) NOT NULL,
  assessed_at          timestamptz NOT NULL DEFAULT now(),
  submitted_at         timestamptz,
  confirmed_by         varchar(64),
  confirmed_at         timestamptz,
  decision_comment     varchar(2000),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_compliance_assessment PRIMARY KEY (id),
  CONSTRAINT uq_kpi_compliance_assessment_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_assessment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_compliance_assessment_component FOREIGN KEY (tenant_id, component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT fk_kpi_compliance_assessment_version FOREIGN KEY (tenant_id, component_version_id) REFERENCES ph16_kpi.kpi_arch_component_version (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_assessment_state CHECK (state IN ('DRAFT', 'SUBMITTED', 'CONFIRMED', 'REJECTED')),
  CONSTRAINT ck_kpi_compliance_assessment_level CHECK (level_result IS NULL OR level_result IN ('COMPLIANT', 'PARTIAL', 'NON_COMPLIANT')),
  CONSTRAINT ck_kpi_compliance_assessment_score CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  CONSTRAINT ck_kpi_compliance_assessment_four_eyes CHECK (confirmed_by IS NULL OR assessed_by IS NULL OR confirmed_by <> assessed_by),
  CONSTRAINT ck_kpi_compliance_assessment_submitted CHECK (state = 'DRAFT' OR (submitted_at IS NOT NULL AND level_result IS NOT NULL)),
  CONSTRAINT ck_kpi_compliance_assessment_confirmed CHECK (state <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)),
  CONSTRAINT ck_kpi_compliance_assessment_rejected CHECK (state <> 'REJECTED' OR (confirmed_by IS NOT NULL AND COALESCE(char_length(decision_comment) >= 20, false)))
);
CREATE INDEX ix_kpi_compliance_assessment_component ON ph16_kpi.kpi_compliance_assessment (tenant_id, component_id, state, confirmed_at DESC);
CREATE INDEX ix_kpi_compliance_assessment_inbox ON ph16_kpi.kpi_compliance_assessment (tenant_id, submitted_at) WHERE state = 'SUBMITTED';
CREATE TRIGGER tg_kpi_compliance_assessment_touch BEFORE UPDATE ON ph16_kpi.kpi_compliance_assessment FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_compliance_assessment_immutable BEFORE UPDATE ON ph16_kpi.kpi_compliance_assessment FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'component_id', 'assessed_by');
CREATE TRIGGER tg_kpi_compliance_assessment_frozen BEFORE UPDATE ON ph16_kpi.kpi_compliance_assessment FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'CONFIRMED,REJECTED', 'component_version_id', 'level_result', 'score', 'summary', 'assessed_at', 'submitted_at');
CREATE TRIGGER tg_kpi_compliance_assessment_transition BEFORE UPDATE ON ph16_kpi.kpi_compliance_assessment FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["SUBMITTED"],"SUBMITTED":["CONFIRMED","REJECTED","DRAFT"],"REJECTED":["DRAFT"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_compliance_assessment');
COMMENT ON TABLE ph16_kpi.kpi_compliance_assessment IS 'EN-16-31 Đánh giá tuân thủ một thành phần (hoặc một phiên bản) theo bộ tiêu chí: DRAFT, SUBMITTED, CONFIRMED, REJECTED, kết quả COMPLIANT, PARTIAL, NON_COMPLIANT; người xác nhận khác người đánh giá (FR-16-047). CONFIRMED và REJECTED không đổi nội dung.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_compliance_assessment CASCADE;

--changeset ph16:ph16-0420-kpi-compliance-item
CREATE TABLE ph16_kpi.kpi_compliance_item (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  assessment_id uuid NOT NULL,
  criterion_id  uuid NOT NULL,
  result        varchar(4) NOT NULL,
  evidence_ref  varchar(512),
  note          varchar(2000),
  item_score    numeric(5,2),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_compliance_item PRIMARY KEY (id),
  CONSTRAINT ck_kpi_compliance_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_compliance_item UNIQUE (tenant_id, assessment_id, criterion_id),
  CONSTRAINT fk_kpi_compliance_item_assessment FOREIGN KEY (tenant_id, assessment_id) REFERENCES ph16_kpi.kpi_compliance_assessment (tenant_id, id),
  CONSTRAINT fk_kpi_compliance_item_criterion FOREIGN KEY (tenant_id, criterion_id) REFERENCES ph16_kpi.kpi_compliance_criterion (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_item_result CHECK (result IN ('PASS', 'FAIL', 'NA')),
  CONSTRAINT ck_kpi_compliance_item_score CHECK (item_score IS NULL OR (item_score >= 0 AND item_score <= 100)),
  CONSTRAINT ck_kpi_compliance_item_note CHECK (result NOT IN ('FAIL', 'NA') OR COALESCE(char_length(note) >= 20, false))
);
CREATE TRIGGER tg_kpi_compliance_item_touch BEFORE UPDATE ON ph16_kpi.kpi_compliance_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_compliance_item_immutable BEFORE UPDATE ON ph16_kpi.kpi_compliance_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'assessment_id', 'criterion_id');
CREATE TRIGGER tg_kpi_compliance_item_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph16_kpi.kpi_compliance_item FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_child_frozen('kpi_compliance_assessment', 'assessment_id', 'DRAFT');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_compliance_item');
COMMENT ON TABLE ph16_kpi.kpi_compliance_item IS 'EN-16-31 Mục đánh giá: kết quả từng tiêu chí của một đánh giá PASS (đạt), FAIL (không đạt), NA (không áp dụng) kèm bằng chứng và ghi chú (FR-16-047). Chỉ sửa khi đánh giá còn DRAFT.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_compliance_item CASCADE;

--changeset ph16:ph16-0430-kpi-compliance-waiver
CREATE TABLE ph16_kpi.kpi_compliance_waiver (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  component_id     uuid NOT NULL,
  criterion_id     uuid,
  reason           varchar(2000) NOT NULL,
  valid_from       date NOT NULL,
  valid_to         date NOT NULL,
  state            varchar(16) NOT NULL DEFAULT 'PENDING_APPROVAL',
  requested_by     varchar(64) NOT NULL,
  approved_by      varchar(64),
  approved_at      timestamptz,
  decision_comment varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_compliance_waiver PRIMARY KEY (id),
  CONSTRAINT uq_kpi_compliance_waiver_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_waiver_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_compliance_waiver_component FOREIGN KEY (tenant_id, component_id) REFERENCES ph16_kpi.kpi_arch_component (tenant_id, id),
  CONSTRAINT fk_kpi_compliance_waiver_criterion FOREIGN KEY (tenant_id, criterion_id) REFERENCES ph16_kpi.kpi_compliance_criterion (tenant_id, id),
  CONSTRAINT ck_kpi_compliance_waiver_state CHECK (state IN ('PENDING_APPROVAL', 'ACTIVE', 'EXPIRED', 'REVOKED', 'REJECTED')),
  CONSTRAINT ck_kpi_compliance_waiver_period CHECK (valid_to > valid_from AND valid_to - valid_from <= 366),
  CONSTRAINT ck_kpi_compliance_waiver_reason CHECK (char_length(reason) >= 50),
  CONSTRAINT ck_kpi_compliance_waiver_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_kpi_compliance_waiver_active CHECK (state NOT IN ('ACTIVE', 'EXPIRED', 'REVOKED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_kpi_compliance_waiver_decision CHECK (state NOT IN ('REJECTED', 'REVOKED') OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE INDEX ix_kpi_compliance_waiver_component ON ph16_kpi.kpi_compliance_waiver (tenant_id, component_id, state);
CREATE INDEX ix_kpi_compliance_waiver_expiry ON ph16_kpi.kpi_compliance_waiver (tenant_id, valid_to) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_kpi_compliance_waiver_touch BEFORE UPDATE ON ph16_kpi.kpi_compliance_waiver FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_compliance_waiver_immutable BEFORE UPDATE ON ph16_kpi.kpi_compliance_waiver FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'component_id', 'criterion_id', 'requested_by');
CREATE TRIGGER tg_kpi_compliance_waiver_frozen BEFORE UPDATE ON ph16_kpi.kpi_compliance_waiver FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'ACTIVE,EXPIRED,REVOKED,REJECTED', 'reason', 'valid_from', 'valid_to');
CREATE TRIGGER tg_kpi_compliance_waiver_transition BEFORE UPDATE ON ph16_kpi.kpi_compliance_waiver FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"PENDING_APPROVAL":["ACTIVE","REJECTED"],"ACTIVE":["EXPIRED","REVOKED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_compliance_waiver');
COMMENT ON TABLE ph16_kpi.kpi_compliance_waiver IS 'EN-16-32 Miễn trừ có hạn: miễn một tiêu chí (hoặc toàn bộ) cho một thành phần, lý do từ 50 ký tự, hạn không quá 366 ngày (tham số 16.compliance.waiver-max-days mặc định 180 ngày do dịch vụ kiểm), người duyệt khác người đề nghị (FR-16-047). PENDING_APPROVAL, ACTIVE, EXPIRED, REVOKED, REJECTED.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_compliance_waiver CASCADE;
