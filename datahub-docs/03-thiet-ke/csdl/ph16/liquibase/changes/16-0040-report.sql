--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0040-report.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0400-fn-report-gate splitStatements:false
-- Cổng nghiệp vụ của phiên bản báo cáo: tạo ở DRAFT; duyệt bốn mắt theo tham số 16.report.four-eyes; công bố cần chữ ký số khớp mã băm khi 16.report.signing bật.
CREATE OR REPLACE FUNCTION ph16_kpi.f_report_version_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.state <> 'DRAFT' THEN
      RAISE EXCEPTION 'Phiên bản báo cáo mới phải ở trạng thái DRAFT' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.state = 'APPROVED' AND OLD.state = 'IN_REVIEW'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.four-eyes', true)
     AND NEW.approved_by IS NOT DISTINCT FROM NEW.prepared_by THEN
    RAISE EXCEPTION 'Bốn mắt: người duyệt phải khác người lập báo cáo (16.report.four-eyes)' USING ERRCODE = '23514';
  END IF;
  IF NEW.state = 'PUBLISHED' AND OLD.state = 'APPROVED'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.signing', true)
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_signature s
                      WHERE s.tenant_id = NEW.tenant_id AND s.report_version_id = NEW.id AND s.signed_hash = NEW.content_hash) THEN
    RAISE EXCEPTION 'Công bố cần chữ ký số khớp mã băm nội dung (16.report.signing)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_report_version_gate() IS 'Cổng nghiệp vụ phiên bản báo cáo (FR-16-028, 029).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_report_version_gate();

--changeset ph16:ph16-0401-fn-report-sync splitStatements:false
-- Báo cáo (đầu) phản chiếu trạng thái phiên bản mới nhất và nhớ phiên bản đang công bố.
CREATE OR REPLACE FUNCTION ph16_kpi.f_report_sync() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  UPDATE ph16_kpi.kpi_report r
     SET state = CASE WHEN NEW.version_no >= r.current_version_no THEN NEW.state ELSE r.state END,
         current_version_no = GREATEST(r.current_version_no, NEW.version_no),
         published_version_no = CASE WHEN NEW.state = 'PUBLISHED' THEN NEW.version_no
                                     WHEN NEW.state IN ('SUPERSEDED', 'WITHDRAWN') AND r.published_version_no = NEW.version_no THEN NULL
                                     ELSE r.published_version_no END
   WHERE r.tenant_id = NEW.tenant_id AND r.id = NEW.report_id;
  RETURN NULL;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_report_sync() IS 'Đồng bộ kpi_report.state, current_version_no, published_version_no từ kpi_report_version.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_report_sync();

--changeset ph16:ph16-0402-fn-approval-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_approval_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.action = 'APPROVE' AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.four-eyes', true)
     AND EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_version v WHERE v.tenant_id = NEW.tenant_id AND v.id = NEW.report_version_id AND v.prepared_by = NEW.actor) THEN
    RAISE EXCEPTION 'Bốn mắt: người lập không được ghi hành động APPROVE cho báo cáo của mình' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_approval_gate() IS 'Cặp loại trừ: người lập báo cáo khác người duyệt cùng báo cáo (D02-08).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_approval_gate();

--changeset ph16:ph16-0250-kpi-report-template
CREATE TABLE ph16_kpi.kpi_report_template (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  template_code varchar(63) NOT NULL,
  version_no    integer NOT NULL DEFAULT 1,
  name          varchar(255) NOT NULL,
  state         varchar(8) NOT NULL DEFAULT 'DRAFT',
  sections      text[] NOT NULL,
  formats       text[] NOT NULL DEFAULT '{PDF}',
  layout        jsonb NOT NULL DEFAULT '{}',
  description   varchar(2000),
  activated_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_report_template PRIMARY KEY (id),
  CONSTRAINT uq_kpi_report_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_report_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_report_template_version UNIQUE (tenant_id, template_code, version_no),
  CONSTRAINT ck_kpi_report_template_code CHECK (template_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_report_template_no CHECK (version_no >= 1),
  CONSTRAINT ck_kpi_report_template_state CHECK (state IN ('DRAFT', 'ACTIVE', 'RETIRED')),
  CONSTRAINT ck_kpi_report_template_sections CHECK (cardinality(sections) >= 1 AND sections <@ ARRAY['SUMMARY', 'GROUP', 'INDICATOR_TABLE', 'CHART', 'NARRATIVE', 'ANNEX']::text[]),
  CONSTRAINT ck_kpi_report_template_formats CHECK (cardinality(formats) >= 1 AND formats <@ ARRAY['PDF', 'XLSX', 'CSV', 'JSON']::text[]),
  CONSTRAINT ck_kpi_report_template_layout CHECK (jsonb_typeof(layout) = 'object'),
  CONSTRAINT ck_kpi_report_template_active CHECK (state = 'DRAFT' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_kpi_report_template_active ON ph16_kpi.kpi_report_template (tenant_id, template_code) WHERE state = 'ACTIVE';
CREATE TRIGGER tg_kpi_report_template_touch BEFORE UPDATE ON ph16_kpi.kpi_report_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_report_template_immutable BEFORE UPDATE ON ph16_kpi.kpi_report_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'template_code', 'version_no');
CREATE TRIGGER tg_kpi_report_template_frozen BEFORE UPDATE ON ph16_kpi.kpi_report_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'ACTIVE,RETIRED', 'name', 'sections', 'formats', 'layout');
CREATE TRIGGER tg_kpi_report_template_transition BEFORE UPDATE ON ph16_kpi.kpi_report_template FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["ACTIVE","RETIRED"],"ACTIVE":["RETIRED"]}');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_report_template');
COMMENT ON TABLE ph16_kpi.kpi_report_template IS 'EN-16-19 Mẫu báo cáo có phiên bản: bố cục phần (SUMMARY, GROUP, INDICATOR_TABLE, CHART, NARRATIVE, ANNEX), định dạng xuất (PDF, XLSX, CSV, JSON) và cấu hình bố cục (FR-16-025). Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_report_template CASCADE;

--changeset ph16:ph16-0260-kpi-report
CREATE TABLE ph16_kpi.kpi_report (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  report_code          varchar(63) NOT NULL,
  report_type          varchar(8) NOT NULL,
  title                varchar(255) NOT NULL,
  period_id            uuid,
  range_from           date,
  range_to             date,
  template_id          uuid NOT NULL,
  state                varchar(17) NOT NULL DEFAULT 'DRAFT',
  current_version_no   integer NOT NULL DEFAULT 1,
  published_version_no integer,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_report PRIMARY KEY (id),
  CONSTRAINT uq_kpi_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_report_code UNIQUE (tenant_id, report_code),
  CONSTRAINT fk_kpi_report_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT fk_kpi_report_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph16_kpi.kpi_report_template (tenant_id, id),
  CONSTRAINT ck_kpi_report_code CHECK (report_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_report_type CHECK (report_type IN ('PERIODIC', 'AD_HOC', 'NATIONAL')),
  CONSTRAINT ck_kpi_report_state CHECK (state IN ('DRAFT', 'IN_REVIEW', 'APPROVED', 'PUBLISHED', 'CHANGES_REQUESTED', 'SUPERSEDED', 'WITHDRAWN')),
  CONSTRAINT ck_kpi_report_scope CHECK ((report_type IN ('PERIODIC', 'NATIONAL') AND period_id IS NOT NULL) OR (report_type = 'AD_HOC' AND range_from IS NOT NULL AND range_to IS NOT NULL AND range_from <= range_to)),
  CONSTRAINT ck_kpi_report_versions CHECK (current_version_no >= 1 AND (published_version_no IS NULL OR published_version_no <= current_version_no))
);
CREATE INDEX ix_kpi_report_period ON ph16_kpi.kpi_report (tenant_id, report_type, period_id);
CREATE INDEX ix_kpi_report_state ON ph16_kpi.kpi_report (tenant_id, state, updated_at DESC);
CREATE TRIGGER tg_kpi_report_touch BEFORE UPDATE ON ph16_kpi.kpi_report FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_report_immutable BEFORE UPDATE ON ph16_kpi.kpi_report FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'report_code', 'report_type', 'period_id');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_report');
COMMENT ON TABLE ph16_kpi.kpi_report IS 'EN-16-20 Báo cáo (phần đầu): mã `bc-thang-2026-10`, loại PERIODIC, AD_HOC, NATIONAL, kỳ hoặc khoảng thời gian, mẫu; phản chiếu trạng thái phiên bản mới nhất và nhớ phiên bản đang công bố (FR-16-026, 031, 032). Nội dung nằm ở `kpi_report_version`; đính chính tạo phiên bản mới, không sửa bản đã công bố.';
COMMENT ON COLUMN ph16_kpi.kpi_report.state IS 'Bản sao trạng thái của phiên bản mới nhất, do trigger `tg_kpi_report_version_sync` cập nhật; nguồn chuẩn là `kpi_report_version.state`.';
COMMENT ON COLUMN ph16_kpi.kpi_report.published_version_no IS 'Phiên bản đang PUBLISHED (NULL nếu chưa công bố hoặc đã SUPERSEDED, WITHDRAWN).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_report CASCADE;

--changeset ph16:ph16-0270-kpi-report-version
CREATE TABLE ph16_kpi.kpi_report_version (
  id                       uuid NOT NULL,
  tenant_id                varchar(16) NOT NULL,
  report_id                uuid NOT NULL,
  version_no               integer NOT NULL,
  state                    varchar(17) NOT NULL DEFAULT 'DRAFT',
  template_id              uuid NOT NULL,
  run_id                   uuid,
  snapshot                 jsonb NOT NULL DEFAULT '{}',
  narrative                jsonb NOT NULL DEFAULT '{}',
  completeness             varchar(9) NOT NULL DEFAULT 'COMPLETE',
  missing_mandatory        boolean NOT NULL DEFAULT false,
  prepared_by              varchar(64) NOT NULL,
  prepared_at              timestamptz NOT NULL DEFAULT now(),
  submitted_at             timestamptz,
  approved_by              varchar(64),
  approved_at              timestamptz,
  published_by             varchar(64),
  published_at             timestamptz,
  content_hash             bytea,
  object_ref               varchar(512),
  retain_until             date,
  correction_of_version_no integer,
  correction_reason        varchar(2000),
  decision_comment         varchar(2000),
  withdrawn_by             varchar(64),
  withdrawn_at             timestamptz,
  withdraw_reason          varchar(2000),
  created_at               timestamptz NOT NULL DEFAULT now(),
  created_by               varchar(64) NOT NULL,
  updated_at               timestamptz NOT NULL DEFAULT now(),
  updated_by               varchar(64) NOT NULL,
  version                  integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_report_version PRIMARY KEY (id),
  CONSTRAINT uq_kpi_report_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_report_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_report_version_no UNIQUE (tenant_id, report_id, version_no),
  CONSTRAINT fk_kpi_report_version_report FOREIGN KEY (tenant_id, report_id) REFERENCES ph16_kpi.kpi_report (tenant_id, id),
  CONSTRAINT fk_kpi_report_version_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph16_kpi.kpi_report_template (tenant_id, id),
  CONSTRAINT fk_kpi_report_version_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph16_kpi.kpi_aggregation_run (tenant_id, id),
  CONSTRAINT ck_kpi_report_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_kpi_report_version_state CHECK (state IN ('DRAFT', 'IN_REVIEW', 'APPROVED', 'PUBLISHED', 'CHANGES_REQUESTED', 'SUPERSEDED', 'WITHDRAWN')),
  CONSTRAINT ck_kpi_report_version_completeness CHECK (completeness IN ('COMPLETE', 'PARTIAL', 'NO_DATA')),
  CONSTRAINT ck_kpi_report_version_snapshot CHECK (jsonb_typeof(snapshot) = 'object' AND jsonb_typeof(narrative) = 'object'),
  CONSTRAINT ck_kpi_report_version_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32),
  CONSTRAINT ck_kpi_report_version_review CHECK (state IN ('DRAFT', 'CHANGES_REQUESTED') OR submitted_at IS NOT NULL),
  CONSTRAINT ck_kpi_report_version_approved CHECK (state NOT IN ('APPROVED', 'PUBLISHED', 'SUPERSEDED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_kpi_report_version_published CHECK (state NOT IN ('PUBLISHED', 'SUPERSEDED') OR (published_by IS NOT NULL AND published_at IS NOT NULL AND content_hash IS NOT NULL AND object_ref IS NOT NULL AND retain_until IS NOT NULL)),
  CONSTRAINT ck_kpi_report_version_mandatory CHECK (state <> 'PUBLISHED' OR NOT missing_mandatory),
  CONSTRAINT ck_kpi_report_version_correction CHECK ((correction_of_version_no IS NULL) = (correction_reason IS NULL) AND (correction_of_version_no IS NULL OR correction_of_version_no < version_no)),
  CONSTRAINT ck_kpi_report_version_correction_reason CHECK (correction_reason IS NULL OR char_length(correction_reason) >= 20),
  CONSTRAINT ck_kpi_report_version_withdrawn CHECK (state <> 'WITHDRAWN' OR (withdrawn_by IS NOT NULL AND withdrawn_at IS NOT NULL AND COALESCE(char_length(withdraw_reason) >= 20, false))),
  CONSTRAINT ck_kpi_report_version_changes CHECK (state <> 'CHANGES_REQUESTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_kpi_report_version_published ON ph16_kpi.kpi_report_version (tenant_id, report_id) WHERE state = 'PUBLISHED';
CREATE INDEX ix_kpi_report_version_inbox ON ph16_kpi.kpi_report_version (tenant_id, state, submitted_at) WHERE state IN ('IN_REVIEW', 'APPROVED');
CREATE INDEX ix_kpi_report_version_published ON ph16_kpi.kpi_report_version (tenant_id, published_at DESC) WHERE state = 'PUBLISHED';
CREATE TRIGGER tg_kpi_report_version_touch BEFORE UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_report_version_immutable BEFORE UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'report_id', 'version_no', 'prepared_by');
CREATE TRIGGER tg_kpi_report_version_frozen_review BEFORE UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'IN_REVIEW,APPROVED', 'template_id', 'run_id', 'snapshot', 'narrative', 'completeness', 'missing_mandatory');
CREATE TRIGGER tg_kpi_report_version_frozen BEFORE UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'PUBLISHED,SUPERSEDED,WITHDRAWN', 'template_id', 'run_id', 'snapshot', 'narrative', 'completeness', 'missing_mandatory', 'submitted_at', 'approved_by', 'approved_at', 'published_by', 'published_at', 'content_hash', 'object_ref', 'retain_until', 'correction_of_version_no', 'correction_reason');
CREATE TRIGGER tg_kpi_report_version_transition BEFORE UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["IN_REVIEW"],"IN_REVIEW":["APPROVED","CHANGES_REQUESTED"],"CHANGES_REQUESTED":["DRAFT"],"APPROVED":["PUBLISHED","DRAFT"],"PUBLISHED":["SUPERSEDED","WITHDRAWN"]}');
CREATE TRIGGER tg_kpi_report_version_no_delete BEFORE DELETE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_no_delete_state('state', 'APPROVED,PUBLISHED,SUPERSEDED,WITHDRAWN');
CREATE TRIGGER tg_kpi_report_version_gate BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_report_version_gate();
CREATE TRIGGER tg_kpi_report_version_sync AFTER INSERT OR UPDATE OF state ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_report_sync();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_report_version');
COMMENT ON TABLE ph16_kpi.kpi_report_version IS 'EN-16-21, EN-16-22 Phiên bản báo cáo: ảnh chụp giá trị chỉ tiêu, thuyết minh, mẫu, lần tổng hợp nguồn; vòng đời DRAFT, IN_REVIEW, APPROVED, PUBLISHED, CHANGES_REQUESTED, SUPERSEDED, WITHDRAWN (FR-16-026, 027, 028, 029, 030). Khi PUBLISHED bất biến bằng trigger: nội dung, mã băm, tệp PDF ký số (lưu WORM, giữ theo `16.report.retention-years`) không đổi; đính chính bằng phiên bản mới. Người duyệt khác người lập.';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.snapshot IS 'Ảnh chụp bất biến: giá trị, trạng thái, điểm nhóm, phiên bản công thức của từng chỉ tiêu tại thời điểm gửi duyệt; không đọc lại bảng giá trị khi xem bản đã công bố.';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.content_hash IS 'SHA-256 (32 byte) của tệp PDF công bố; chữ ký số trong `kpi_report_signature.signed_hash` phải trùng.';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.object_ref IS 'Đối tượng PDF ký số trên Ceph RGW (WORM, ADR đề xuất dải 160…164); không lưu tệp trong PostgreSQL.';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.retain_until IS 'Ngày hết hạn giữ = ngày công bố + 16.report.retention-years (mặc định 10 năm).';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.prepared_by IS 'Người lập; `approved_by` phải khác khi 16.report.four-eyes bật (trigger `tg_kpi_report_version_gate`).';
COMMENT ON COLUMN ph16_kpi.kpi_report_version.missing_mandatory IS 'Còn chỉ tiêu bắt buộc thiếu nguồn: CHECK ck_kpi_report_version_mandatory chặn công bố.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_report_version CASCADE;

--changeset ph16:ph16-0280-kpi-report-approval
CREATE TABLE ph16_kpi.kpi_report_approval (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  report_version_id uuid NOT NULL,
  action            varchar(15) NOT NULL,
  actor             varchar(64) NOT NULL,
  acted_at          timestamptz NOT NULL DEFAULT now(),
  comment           varchar(2000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_report_approval PRIMARY KEY (id),
  CONSTRAINT ck_kpi_report_approval_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_report_approval_version FOREIGN KEY (tenant_id, report_version_id) REFERENCES ph16_kpi.kpi_report_version (tenant_id, id),
  CONSTRAINT ck_kpi_report_approval_action CHECK (action IN ('SUBMIT', 'REQUEST_CHANGES', 'APPROVE', 'PUBLISH', 'WITHDRAW', 'CORRECT')),
  CONSTRAINT ck_kpi_report_approval_comment CHECK (action NOT IN ('REQUEST_CHANGES', 'WITHDRAW', 'CORRECT') OR COALESCE(char_length(comment) >= 20, false))
);
CREATE INDEX ix_kpi_report_approval_version ON ph16_kpi.kpi_report_approval (tenant_id, report_version_id, acted_at);
CREATE TRIGGER tg_kpi_report_approval_touch BEFORE UPDATE ON ph16_kpi.kpi_report_approval FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_report_approval_append_only BEFORE UPDATE OR DELETE ON ph16_kpi.kpi_report_approval FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_append_only();
CREATE TRIGGER tg_kpi_report_approval_gate BEFORE INSERT ON ph16_kpi.kpi_report_approval FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_approval_gate();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_report_approval');
COMMENT ON TABLE ph16_kpi.kpi_report_approval IS 'EN-16-21 Nhật ký duyệt báo cáo: mỗi hành động SUBMIT, REQUEST_CHANGES, APPROVE, PUBLISH, WITHDRAW, CORRECT của một phiên bản, kèm người làm và ý kiến (FR-16-028, 029, 030). Chỉ thêm. Người lập báo cáo không ghi được APPROVE cho báo cáo của mình khi 16.report.four-eyes bật.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_report_approval CASCADE;

--changeset ph16:ph16-0290-kpi-report-signature
CREATE TABLE ph16_kpi.kpi_report_signature (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  report_version_id  uuid NOT NULL,
  signer             varchar(64) NOT NULL,
  signed_at          timestamptz NOT NULL DEFAULT now(),
  signature_format   varchar(16) NOT NULL DEFAULT 'PDF_SIGNED',
  certificate_serial varchar(64) NOT NULL,
  signature_ref      varchar(512) NOT NULL,
  signed_hash        bytea NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_report_signature PRIMARY KEY (id),
  CONSTRAINT ck_kpi_report_signature_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_report_signature_version FOREIGN KEY (tenant_id, report_version_id) REFERENCES ph16_kpi.kpi_report_version (tenant_id, id),
  CONSTRAINT ck_kpi_report_signature_format CHECK (signature_format IN ('PDF_SIGNED', 'DETACHED')),
  CONSTRAINT ck_kpi_report_signature_hash CHECK (octet_length(signed_hash) = 32)
);
CREATE INDEX ix_kpi_report_signature_version ON ph16_kpi.kpi_report_signature (tenant_id, report_version_id, signed_at);
CREATE TRIGGER tg_kpi_report_signature_touch BEFORE UPDATE ON ph16_kpi.kpi_report_signature FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_report_signature_append_only BEFORE UPDATE OR DELETE ON ph16_kpi.kpi_report_signature FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_append_only();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_report_signature');
COMMENT ON TABLE ph16_kpi.kpi_report_signature IS 'EN-16-21 Chữ ký số của bản công bố: người ký, thời điểm, định dạng, số sê-ri chứng thư, tham chiếu tệp ký và mã băm đã ký (FR-16-029, 036). Chỉ thêm; mã băm đã ký phải trùng `content_hash` của phiên bản khi công bố.';
COMMENT ON COLUMN ph16_kpi.kpi_report_signature.signature_ref IS 'Đối tượng chữ ký hoặc PDF đã ký trên Ceph RGW; khóa ký nằm ở PH-12 (OpenBao), PH-16 không giữ.';
COMMENT ON COLUMN ph16_kpi.kpi_report_signature.certificate_serial IS 'Số sê-ri chứng thư số của người ký (ký số theo NĐ 30/2020 do PH-12 thực hiện).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_report_signature CASCADE;

--changeset ph16:ph16-0300-kpi-distribution
CREATE TABLE ph16_kpi.kpi_distribution (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  distribution_code varchar(63) NOT NULL,
  name              varchar(255) NOT NULL,
  report_type       varchar(8) NOT NULL DEFAULT 'PERIODIC',
  period_type       varchar(8),
  formats           text[] NOT NULL DEFAULT '{PDF}',
  recipients        jsonb NOT NULL DEFAULT '[]',
  send_on_publish   boolean NOT NULL DEFAULT true,
  enabled           boolean NOT NULL DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_distribution PRIMARY KEY (id),
  CONSTRAINT uq_kpi_distribution_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_distribution_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_distribution_code UNIQUE (tenant_id, distribution_code),
  CONSTRAINT ck_kpi_distribution_code CHECK (distribution_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_distribution_type CHECK (report_type IN ('PERIODIC', 'AD_HOC', 'NATIONAL')),
  CONSTRAINT ck_kpi_distribution_period CHECK (period_type IS NULL OR period_type IN ('MONTH', 'QUARTER', 'YEAR')),
  CONSTRAINT ck_kpi_distribution_formats CHECK (cardinality(formats) >= 1 AND formats <@ ARRAY['PDF', 'XLSX', 'CSV', 'JSON']::text[]),
  CONSTRAINT ck_kpi_distribution_recipients CHECK (jsonb_typeof(recipients) = 'array' AND jsonb_array_length(recipients) <= 500)
);
CREATE TRIGGER tg_kpi_distribution_touch BEFORE UPDATE ON ph16_kpi.kpi_distribution FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_distribution_immutable BEFORE UPDATE ON ph16_kpi.kpi_distribution FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'distribution_code');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_distribution');
COMMENT ON TABLE ph16_kpi.kpi_distribution IS 'EN-16-24 Danh sách phân phối báo cáo: người nhận (người dùng, nhóm, thư điện tử công vụ qua kênh thông báo PH-13), định dạng, loại báo cáo và kỳ gửi theo lịch (FR-16-034).';
COMMENT ON COLUMN ph16_kpi.kpi_distribution.recipients IS 'Mảng {type: USER|GROUP|EMAIL, ref}; thư điện tử chỉ địa chỉ công vụ; gửi qua PH-13, PH-16 không giữ cấu hình thư.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_distribution CASCADE;

--changeset ph16:ph16-0310-kpi-delivery
CREATE TABLE ph16_kpi.kpi_delivery (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  report_version_id uuid NOT NULL,
  distribution_id   uuid NOT NULL,
  recipient_type    varchar(5) NOT NULL,
  recipient_ref     varchar(255) NOT NULL,
  format            varchar(4) NOT NULL DEFAULT 'PDF',
  state             varchar(7) NOT NULL DEFAULT 'PENDING',
  attempt           smallint NOT NULL DEFAULT 0,
  last_attempt_at   timestamptz,
  sent_at           timestamptz,
  error_code        varchar(11),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_delivery PRIMARY KEY (id),
  CONSTRAINT ck_kpi_delivery_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_delivery_recipient UNIQUE (tenant_id, report_version_id, distribution_id, recipient_type, recipient_ref, format),
  CONSTRAINT fk_kpi_delivery_version FOREIGN KEY (tenant_id, report_version_id) REFERENCES ph16_kpi.kpi_report_version (tenant_id, id),
  CONSTRAINT fk_kpi_delivery_distribution FOREIGN KEY (tenant_id, distribution_id) REFERENCES ph16_kpi.kpi_distribution (tenant_id, id),
  CONSTRAINT ck_kpi_delivery_recipient CHECK (recipient_type IN ('USER', 'GROUP', 'EMAIL')),
  CONSTRAINT ck_kpi_delivery_format CHECK (format IN ('PDF', 'XLSX', 'CSV', 'JSON')),
  CONSTRAINT ck_kpi_delivery_state CHECK (state IN ('PENDING', 'SENT', 'FAILED')),
  CONSTRAINT ck_kpi_delivery_attempt CHECK (attempt >= 0),
  CONSTRAINT ck_kpi_delivery_sent CHECK (state <> 'SENT' OR sent_at IS NOT NULL),
  CONSTRAINT ck_kpi_delivery_failed CHECK (state <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_kpi_delivery_error CHECK (error_code IS NULL OR error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE INDEX ix_kpi_delivery_pending ON ph16_kpi.kpi_delivery (tenant_id, state, created_at) WHERE state <> 'SENT';
CREATE TRIGGER tg_kpi_delivery_touch BEFORE UPDATE ON ph16_kpi.kpi_delivery FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_delivery_immutable BEFORE UPDATE ON ph16_kpi.kpi_delivery FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'report_version_id', 'distribution_id', 'recipient_type', 'recipient_ref', 'format');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_delivery');
COMMENT ON TABLE ph16_kpi.kpi_delivery IS 'EN-16-25 Lần giao báo cáo: mỗi người nhận, định dạng của một phiên bản đã công bố qua một danh sách phân phối; theo dõi PENDING, SENT, FAILED và số lần thử (FR-16-034).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_delivery CASCADE;

--changeset ph16:ph16-0320-kpi-export-job
CREATE TABLE ph16_kpi.kpi_export_job (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  subject_type      varchar(15) NOT NULL,
  report_version_id uuid,
  period_id         uuid,
  format            varchar(4) NOT NULL,
  filter            jsonb NOT NULL DEFAULT '{}',
  state             varchar(9) NOT NULL DEFAULT 'QUEUED',
  requested_by      varchar(64) NOT NULL,
  started_at        timestamptz,
  finished_at       timestamptz,
  row_count         bigint,
  object_ref        varchar(512),
  content_hash      bytea,
  expires_at        timestamptz,
  download_count    integer NOT NULL DEFAULT 0,
  error_code        varchar(11),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_export_job PRIMARY KEY (id),
  CONSTRAINT uq_kpi_export_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_export_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_export_job_version FOREIGN KEY (tenant_id, report_version_id) REFERENCES ph16_kpi.kpi_report_version (tenant_id, id),
  CONSTRAINT fk_kpi_export_job_period FOREIGN KEY (tenant_id, period_id) REFERENCES ph16_kpi.kpi_reporting_period (tenant_id, id),
  CONSTRAINT ck_kpi_export_job_subject CHECK (subject_type IN ('REPORT_VERSION', 'INDICATOR_TABLE', 'ARCH_REGISTRY') AND (subject_type <> 'REPORT_VERSION' OR report_version_id IS NOT NULL) AND (subject_type <> 'INDICATOR_TABLE' OR period_id IS NOT NULL)),
  CONSTRAINT ck_kpi_export_job_format CHECK (format IN ('PDF', 'XLSX', 'CSV', 'JSON')),
  CONSTRAINT ck_kpi_export_job_state CHECK (state IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_kpi_export_job_rows CHECK (row_count IS NULL OR row_count >= 0),
  CONSTRAINT ck_kpi_export_job_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32),
  CONSTRAINT ck_kpi_export_job_ready CHECK (state NOT IN ('SUCCEEDED', 'EXPIRED') OR (object_ref IS NOT NULL AND content_hash IS NOT NULL AND expires_at IS NOT NULL AND finished_at IS NOT NULL)),
  CONSTRAINT ck_kpi_export_job_failed CHECK (state <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_kpi_export_job_downloads CHECK (download_count >= 0),
  CONSTRAINT ck_kpi_export_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-16-[0-9]{3}$')
);
CREATE INDEX ix_kpi_export_job_state ON ph16_kpi.kpi_export_job (tenant_id, state, created_at DESC);
CREATE INDEX ix_kpi_export_job_expiry ON ph16_kpi.kpi_export_job (expires_at) WHERE state = 'SUCCEEDED';
CREATE TRIGGER tg_kpi_export_job_touch BEFORE UPDATE ON ph16_kpi.kpi_export_job FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_export_job_immutable BEFORE UPDATE ON ph16_kpi.kpi_export_job FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'subject_type', 'report_version_id', 'period_id', 'format', 'requested_by');
CREATE TRIGGER tg_kpi_export_job_transition BEFORE UPDATE ON ph16_kpi.kpi_export_job FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"QUEUED":["RUNNING","FAILED"],"RUNNING":["SUCCEEDED","FAILED"],"SUCCEEDED":["EXPIRED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_export_job');
COMMENT ON TABLE ph16_kpi.kpi_export_job IS 'EN-16-23 Lệnh xuất: xuất bản báo cáo, bảng chỉ tiêu của kỳ hoặc sổ kiến trúc ra PDF, XLSX, CSV, JSON lên Ceph RGW; QUEUED, RUNNING, SUCCEEDED, FAILED, EXPIRED; liên kết tải hết hạn sau `16.export.link-hours` (FR-16-033, 036, 049).';
COMMENT ON COLUMN ph16_kpi.kpi_export_job.row_count IS 'Không vượt 16.export.max-rows (mặc định 100000) do dịch vụ kiểm.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_export_job CASCADE;
