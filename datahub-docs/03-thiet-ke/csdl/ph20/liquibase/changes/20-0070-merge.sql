--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0070-merge.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0390-merge-plan
CREATE TABLE ph20_tenant.merge_plan (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_code              varchar(48)    NOT NULL,
  name                   varchar(255)   NOT NULL,
  status                 varchar(20)    NOT NULL DEFAULT 'DRAFT',
  source_tenant_code     varchar(16)    NOT NULL,
  target_tenant_code     varchar(16)    NOT NULL,
  legal_basis            varchar(1000)  NOT NULL,
  ticket_code            varchar(32),
  effective_date         date,
  transition_months      smallint       NOT NULL DEFAULT 6,
  requested_by           varchar(64)    NOT NULL,
  approved_by            varchar(64),
  approved_at            timestamptz,
  dry_run_at             timestamptz,
  started_at             timestamptz,
  cutover_at             timestamptz,
  transition_until       date,
  completed_at           timestamptz,
  cancel_reason          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_plan PRIMARY KEY (id),
  CONSTRAINT uq_merge_plan_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_plan_code UNIQUE (plan_code),
  CONSTRAINT ck_merge_plan_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_plan_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER', 'CUTOVER', 'TRANSITION', 'COMPLETED', 'CANCELLED', 'FAILED')),
  CONSTRAINT ck_merge_plan_code CHECK (plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'),
  CONSTRAINT ck_merge_plan_source CHECK (source_tenant_code ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_merge_plan_target CHECK (target_tenant_code ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_merge_plan_distinct CHECK (source_tenant_code <> target_tenant_code),
  CONSTRAINT ck_merge_plan_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_merge_plan_months CHECK (transition_months BETWEEN 1 AND 24),
  CONSTRAINT ck_merge_plan_approved CHECK (status NOT IN ('APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER', 'CUTOVER', 'TRANSITION', 'COMPLETED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_merge_plan_cutover CHECK (status NOT IN ('CUTOVER', 'TRANSITION', 'COMPLETED') OR cutover_at IS NOT NULL),
  CONSTRAINT ck_merge_plan_completed CHECK (status <> 'COMPLETED' OR completed_at IS NOT NULL),
  CONSTRAINT fk_merge_plan_source FOREIGN KEY (source_tenant_code) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_merge_plan_target FOREIGN KEY (target_tenant_code) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_merge_plan_open_source ON ph20_tenant.merge_plan (source_tenant_code) WHERE status NOT IN ('COMPLETED', 'CANCELLED');
CREATE INDEX ix_merge_plan_target ON ph20_tenant.merge_plan (target_tenant_code);
CREATE INDEX ix_merge_plan_status ON ph20_tenant.merge_plan (status);
CREATE TRIGGER tg_merge_plan_touch BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_merge_plan_transition BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "DRAFT", "CANCELLED"], "APPROVED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"], "DRY_RUN": ["APPROVED", "TRANSFERRING", "FAILED", "CANCELLED"], "TRANSFERRING": ["CONFLICT_REVIEW", "IDENTITY_TRANSFER", "FAILED"], "CONFLICT_REVIEW": ["TRANSFERRING", "IDENTITY_TRANSFER", "CANCELLED"], "IDENTITY_TRANSFER": ["CUTOVER", "FAILED"], "CUTOVER": ["TRANSITION", "FAILED"], "TRANSITION": ["COMPLETED"], "FAILED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"]}');
CREATE TRIGGER tg_merge_plan_immutable BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('plan_code', 'source_tenant_code', 'target_tenant_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_plan', 'PLAT');
CREATE POLICY merge_party_read ON ph20_tenant.merge_plan FOR SELECT USING (current_setting('app.tenant_id', false) IN (source_tenant_code, target_tenant_code));
COMMENT ON TABLE ph20_tenant.merge_plan IS 'EN-20-25 Kế hoạch sáp nhập (FR-20-045, 051, 052): tenant nguồn sáp nhập vào tenant đích (D03-10 §5.4). Dữ liệu nền tảng; hai tenant bên tham gia đọc được kế hoạch của mình. Mỗi tenant nguồn tối đa một kế hoạch đang mở; duyệt bốn mắt (người duyệt khác người lập).';
COMMENT ON COLUMN ph20_tenant.merge_plan.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_plan.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_plan.plan_code IS 'Mã kế hoạch dạng `sap-nhap-t68-t69`, dùng ở route `/nen-tang/sap-nhap/{ma}`.';
COMMENT ON COLUMN ph20_tenant.merge_plan.name IS 'Tên kế hoạch.';
COMMENT ON COLUMN ph20_tenant.merge_plan.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.merge_plan.source_tenant_code IS 'Tenant nguồn (sẽ sang `MERGED`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.target_tenant_code IS 'Tenant đích nhận dữ liệu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.legal_basis IS 'Căn cứ pháp lý của việc sắp xếp đơn vị hành chính.';
COMMENT ON COLUMN ph20_tenant.merge_plan.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.effective_date IS 'Ngày hiệu lực của việc sắp xếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.transition_months IS 'Thời gian chuyển tiếp, tháng (`20.merge.transition-months`, trần `20.merge.transition-max-months` kiểm ở dịch vụ).';
COMMENT ON COLUMN ph20_tenant.merge_plan.requested_by IS 'Người lập kế hoạch.';
COMMENT ON COLUMN ph20_tenant.merge_plan.approved_by IS 'Người duyệt, khác người lập.';
COMMENT ON COLUMN ph20_tenant.merge_plan.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.merge_plan.dry_run_at IS 'Lần chạy thử gần nhất.';
COMMENT ON COLUMN ph20_tenant.merge_plan.started_at IS 'Bắt đầu chuyển dữ liệu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.cutover_at IS 'Thời điểm nguồn sang `MERGED`, bật chuyển tiếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.transition_until IS 'Hết thời gian chuyển tiếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.completed_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.merge_plan.cancel_reason IS 'Lý do hủy hoặc thất bại.';
COMMENT ON COLUMN ph20_tenant.merge_plan.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_plan.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_plan.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.merge_plan CASCADE;

--changeset ph20:ph20-0400-merge-mapping
CREATE TABLE ph20_tenant.merge_mapping (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  mapping_type           varchar(16)    NOT NULL,
  source_ref             varchar(255)   NOT NULL,
  target_ref             varchar(255),
  status                 varchar(10)    NOT NULL DEFAULT 'PROPOSED',
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_mapping PRIMARY KEY (id),
  CONSTRAINT uq_merge_mapping_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_mapping_source UNIQUE (plan_id, mapping_type, source_ref),
  CONSTRAINT ck_merge_mapping_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_mapping_mapping_type CHECK (mapping_type IN ('ORGANIZATION', 'MEMBER_SYSTEM', 'CATALOG_CODE', 'API_CONTEXT_PATH', 'USER', 'TOPIC')),
  CONSTRAINT ck_merge_mapping_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'CONFLICT', 'APPLIED')),
  CONSTRAINT ck_merge_mapping_target CHECK (status NOT IN ('CONFIRMED', 'APPLIED') OR target_ref IS NOT NULL),
  CONSTRAINT fk_merge_mapping_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_merge_mapping_fk_plan ON ph20_tenant.merge_mapping (tenant_id, plan_id);
CREATE TRIGGER tg_merge_mapping_touch BEFORE UPDATE ON ph20_tenant.merge_mapping FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_mapping', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_mapping IS 'EN-20-26 Ánh xạ sáp nhập (FR-20-046): bảng ánh xạ tổ chức, HTTT, mã danh mục địa phương, đường dẫn API, người dùng, topic từ nguồn sang đích; dùng cho chuyển dữ liệu và định tuyến chuyển tiếp ở APISIX.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.mapping_type IS 'Loại: `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC`.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.source_ref IS 'Mã, đường dẫn hoặc định danh ở tenant nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.target_ref IS 'Mã, đường dẫn hoặc định danh tương ứng ở tenant đích.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.status IS 'Trạng thái: `PROPOSED`, `CONFIRMED`, `CONFLICT`, `APPLIED`.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.merge_mapping CASCADE;

--changeset ph20:ph20-0410-merge-participant-run
CREATE TABLE ph20_tenant.merge_participant_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  module_code            varchar(8)     NOT NULL,
  phase                  varchar(10)    NOT NULL,
  status                 varchar(10)    NOT NULL DEFAULT 'PENDING',
  attempt                integer        NOT NULL DEFAULT 1,
  exported_count         bigint         NOT NULL DEFAULT 0,
  imported_count         bigint         NOT NULL DEFAULT 0,
  verified_count         bigint         NOT NULL DEFAULT 0,
  conflict_count         bigint         NOT NULL DEFAULT 0,
  transfer_ref           varchar(64),
  started_at             timestamptz,
  finished_at            timestamptz,
  error_code             varchar(16),
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_participant_run PRIMARY KEY (id),
  CONSTRAINT uq_merge_participant_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_participant_run_phase UNIQUE (plan_id, module_code, phase),
  CONSTRAINT ck_merge_participant_run_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_participant_run_phase CHECK (phase IN ('DRY_RUN', 'TRANSFER', 'IDENTITY', 'CUTOVER', 'VERIFY')),
  CONSTRAINT ck_merge_participant_run_status CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED')),
  CONSTRAINT ck_merge_participant_run_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_merge_participant_run_counts CHECK (exported_count >= 0 AND imported_count >= 0 AND verified_count >= 0 AND conflict_count >= 0),
  CONSTRAINT fk_merge_participant_run_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_merge_participant_run_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_merge_participant_run_fk_plan ON ph20_tenant.merge_participant_run (tenant_id, plan_id);
CREATE TRIGGER tg_merge_participant_run_touch BEFORE UPDATE ON ph20_tenant.merge_participant_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_participant_run', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_participant_run IS 'EN-20-27 Lần chuyển theo phân hệ (FR-20-047, 048): mỗi phân hệ có dữ liệu chạy từng pha (chạy thử, chuyển, định danh, chuyển tiếp, kiểm đếm) theo hợp đồng bên tham gia sáp nhập (ADR-202); PH-18 chạy công cụ chuyển, PH-20 điều phối.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.module_code IS 'Phân hệ tham gia.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.phase IS 'Pha: `DRY_RUN`, `TRANSFER`, `IDENTITY`, `CUTOVER`, `VERIFY`.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.status IS 'Trạng thái: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.attempt IS 'Lần thử.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.exported_count IS 'Số bản ghi xuất từ nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.imported_count IS 'Số bản ghi nhập vào đích (giữ `id` gốc, ghi `origin_tenant_id`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.verified_count IS 'Số bản ghi đã kiểm đếm khớp.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.conflict_count IS 'Số xung đột phát sinh.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.transfer_ref IS 'Mã lệnh chuyển ở PH-18 (`/api/ops/v1/merge-transfers`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.started_at IS 'Bắt đầu.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.merge_participant_run CASCADE;

--changeset ph20:ph20-0420-merge-conflict
CREATE TABLE ph20_tenant.merge_conflict (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  participant_run_id     uuid,
  mapping_type           varchar(16)    NOT NULL,
  source_ref             varchar(255)   NOT NULL,
  target_ref             varchar(255),
  conflict_kind          varchar(16)    NOT NULL,
  state                  varchar(10)    NOT NULL DEFAULT 'OPEN',
  resolution             varchar(16),
  resolved_by            varchar(64),
  resolved_at            timestamptz,
  resolution_note        varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_conflict PRIMARY KEY (id),
  CONSTRAINT uq_merge_conflict_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_merge_conflict_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_conflict_mapping_type CHECK (mapping_type IN ('ORGANIZATION', 'MEMBER_SYSTEM', 'CATALOG_CODE', 'API_CONTEXT_PATH', 'USER', 'TOPIC')),
  CONSTRAINT ck_merge_conflict_conflict_kind CHECK (conflict_kind IN ('DUPLICATE_CODE', 'DUPLICATE_PATH', 'DUPLICATE_USER', 'OTHER')),
  CONSTRAINT ck_merge_conflict_state CHECK (state IN ('OPEN', 'RESOLVED')),
  CONSTRAINT ck_merge_conflict_resolution CHECK (resolution IN ('KEEP_TARGET', 'KEEP_SOURCE', 'RENAME_SOURCE', 'MERGE_ITEMS', 'SKIP')),
  CONSTRAINT ck_merge_conflict_resolved CHECK (state <> 'RESOLVED' OR (resolution IS NOT NULL AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT fk_merge_conflict_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_merge_conflict_participant_run FOREIGN KEY (participant_run_id, tenant_id) REFERENCES ph20_tenant.merge_participant_run (id, tenant_id)
);
CREATE INDEX ix_merge_conflict_plan_state ON ph20_tenant.merge_conflict (plan_id, state);
CREATE INDEX ix_merge_conflict_fk_plan ON ph20_tenant.merge_conflict (tenant_id, plan_id);
CREATE INDEX ix_merge_conflict_fk_participant_run ON ph20_tenant.merge_conflict (tenant_id, participant_run_id);
CREATE TRIGGER tg_merge_conflict_touch BEFORE UPDATE ON ph20_tenant.merge_conflict FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_conflict', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_conflict IS 'EN-20-28 Xung đột sáp nhập (FR-20-049): mã danh mục, đường dẫn API, người dùng trùng giữa nguồn và đích; cán bộ nghiệp vụ chọn cách xử lý (`ConflictResolution`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.participant_run_id IS 'Lần chuyển phát hiện xung đột.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.mapping_type IS 'Loại đối tượng xung đột.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.source_ref IS 'Đối tượng ở nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.target_ref IS 'Đối tượng trùng ở đích.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.conflict_kind IS 'Dạng: `DUPLICATE_CODE`, `DUPLICATE_PATH`, `DUPLICATE_USER`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.state IS 'Trạng thái: `OPEN` hoặc `RESOLVED`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolution IS 'Cách xử lý: `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolved_by IS 'Người xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolved_at IS 'Thời điểm xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolution_note IS 'Ghi chú xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.merge_conflict CASCADE;
