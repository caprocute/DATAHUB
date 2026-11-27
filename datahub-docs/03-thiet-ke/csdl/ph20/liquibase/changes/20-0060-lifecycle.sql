--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0060-lifecycle.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0350-lifecycle-request
CREATE TABLE ph20_tenant.lifecycle_request (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  request_type           varchar(20)    NOT NULL,
  status                 varchar(16)    NOT NULL DEFAULT 'DRAFT',
  suspend_reason         varchar(24),
  essential_api_allowed  boolean        NOT NULL DEFAULT false,
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  requested_at           timestamptz    NOT NULL DEFAULT now(),
  approved_by            varchar(64),
  approved_at            timestamptz,
  decision_note          varchar(1000),
  scheduled_at           timestamptz,
  cooling_until          timestamptz,
  target_isolation_mode  varchar(24),
  quota_change_id        uuid,
  executed_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_lifecycle_request PRIMARY KEY (id),
  CONSTRAINT uq_lifecycle_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_lifecycle_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_lifecycle_request_request_type CHECK (request_type IN ('SUSPEND', 'RESUME', 'TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE')),
  CONSTRAINT ck_lifecycle_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'EXECUTING', 'DONE', 'CANCELLED')),
  CONSTRAINT ck_lifecycle_request_suspend_reason CHECK (suspend_reason IN ('MANAGEMENT_DECISION', 'SECURITY_INCIDENT', 'CONTRACT_EXPIRED', 'TENANT_REQUEST', 'OTHER')),
  CONSTRAINT ck_lifecycle_request_target_isolation CHECK (target_isolation_mode IS NULL OR target_isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_lifecycle_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_lifecycle_request_suspend CHECK (request_type <> 'SUSPEND' OR suspend_reason IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_isolation CHECK (request_type <> 'ISOLATION_CHANGE' OR target_isolation_mode IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_quota CHECK (request_type <> 'QUOTA_DECREASE' OR quota_change_id IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_approved CHECK (request_type NOT IN ('TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE') OR status NOT IN ('APPROVED', 'EXECUTING', 'DONE') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_lifecycle_request_done CHECK (status <> 'DONE' OR executed_at IS NOT NULL),
  CONSTRAINT fk_lifecycle_request_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_lifecycle_request_quota_change FOREIGN KEY (quota_change_id, tenant_id) REFERENCES ph20_tenant.quota_change_request (id, tenant_id)
);
CREATE UNIQUE INDEX uq_lifecycle_request_open ON ph20_tenant.lifecycle_request (tenant_id, request_type) WHERE status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING');
CREATE INDEX ix_lifecycle_request_tenant_status ON ph20_tenant.lifecycle_request (tenant_id, status);
CREATE INDEX ix_lifecycle_request_fk_quota_change ON ph20_tenant.lifecycle_request (tenant_id, quota_change_id);
CREATE TRIGGER tg_lifecycle_request_touch BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_lifecycle_request_transition BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "REJECTED", "CANCELLED", "DRAFT"], "APPROVED": ["EXECUTING", "CANCELLED"], "EXECUTING": ["DONE", "APPROVED"]}');
CREATE TRIGGER tg_lifecycle_request_immutable BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('request_type', 'requested_by');
CALL ph20_tenant.p_enable_rls('ph20_tenant.lifecycle_request', 'CTL');
COMMENT ON TABLE ph20_tenant.lifecycle_request IS 'EN-20-22 Đề nghị vòng đời có duyệt (FR-20-038…042): tạm ngừng, khôi phục, chấm dứt, đổi chế độ cách ly, hạ hạn mức. Chấm dứt, đổi cách ly, hạ hạn mức cần duyệt bốn mắt (người duyệt khác người đề nghị); mỗi (tenant, loại) tối đa một đề nghị đang mở. Mọi đề nghị có lý do và mã phiếu (SEC-85).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.request_type IS 'Loại: `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.suspend_reason IS 'Lý do tạm ngừng: `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER`; bắt buộc với `SUSPEND`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.essential_api_allowed IS 'Cho phép API thiết yếu hoạt động khi tạm ngừng (`20.suspend.essential-api-allowed`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.reason IS 'Lý do đề nghị (văn bản).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.ticket_code IS 'Mã phiếu, căn cứ quyết định.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.requested_at IS 'Thời điểm đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.decision_note IS 'Ghi chú quyết định, lý do từ chối.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.scheduled_at IS 'Thời điểm dự kiến thực hiện.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.cooling_until IS 'Hết thời gian chờ trước khi chấm dứt (`20.terminate.cooling-days`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.target_isolation_mode IS 'Chế độ cách ly đích khi `ISOLATION_CHANGE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.quota_change_id IS 'Đề nghị đổi hạn mức liên quan khi `QUOTA_DECREASE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.executed_at IS 'Thời điểm thực hiện xong.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.lifecycle_request CASCADE;

--changeset ph20:ph20-0360-tenant-status-history
CREATE TABLE ph20_tenant.tenant_status_history (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  from_status            varchar(16),
  to_status              varchar(16)    NOT NULL,
  reason                 varchar(1000),
  ticket_code            varchar(32),
  request_id             uuid,
  run_id                 uuid,
  changed_by             varchar(64)    NOT NULL,
  changed_at             timestamptz    NOT NULL DEFAULT now(),
  trace_id               char(32),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_status_history PRIMARY KEY (id),
  CONSTRAINT uq_tenant_status_history_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_tenant_status_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_status_history_from_status CHECK (from_status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')),
  CONSTRAINT ck_tenant_status_history_to_status CHECK (to_status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')),
  CONSTRAINT ck_tenant_status_history_changed CHECK (from_status IS NULL OR from_status <> to_status),
  CONSTRAINT ck_tenant_status_history_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT fk_tenant_status_history_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_status_history_request FOREIGN KEY (request_id, tenant_id) REFERENCES ph20_tenant.lifecycle_request (id, tenant_id),
  CONSTRAINT fk_tenant_status_history_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id)
);
CREATE INDEX ix_tenant_status_history_tenant_changed ON ph20_tenant.tenant_status_history (tenant_id, changed_at DESC);
CREATE INDEX ix_tenant_status_history_fk_request ON ph20_tenant.tenant_status_history (tenant_id, request_id);
CREATE INDEX ix_tenant_status_history_fk_run ON ph20_tenant.tenant_status_history (tenant_id, run_id);
CREATE TRIGGER tg_tenant_status_history_touch BEFORE UPDATE ON ph20_tenant.tenant_status_history FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_tenant_status_history_append_only BEFORE UPDATE OR DELETE ON ph20_tenant.tenant_status_history FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_append_only();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_status_history', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_status_history IS 'EN-20-23 Sự kiện vòng đời, lịch sử trạng thái tenant (FR-20-043): mỗi lần đổi `tenant.status` ghi một dòng kèm lý do, mã phiếu, đề nghị hoặc lần chạy saga liên quan. Chỉ thêm. Nhật ký kiểm toán chuỗi băm của tenant do PH-13 giữ; bảng này phục vụ hiển thị nhanh và đối chiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.from_status IS 'Trạng thái trước (rỗng với lần khai báo đầu).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.to_status IS 'Trạng thái sau.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.reason IS 'Lý do.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.request_id IS 'Đề nghị vòng đời liên quan.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.run_id IS 'Lần chạy saga liên quan.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.changed_by IS 'Người hoặc tài khoản dịch vụ thực hiện.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.changed_at IS 'Thời điểm đổi.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.trace_id IS 'Mã vết phân tán.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_status_history CASCADE;

--changeset ph20:ph20-0370-data-export-package
CREATE TABLE ph20_tenant.data_export_package (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  request_id             uuid,
  status                 varchar(12)    NOT NULL DEFAULT 'REQUESTED',
  file_id                uuid,
  size_bytes             bigint,
  sha256                 char(64),
  item_count             integer        NOT NULL DEFAULT 0,
  ready_at               timestamptz,
  delivered_at           timestamptz,
  delivered_to           varchar(255),
  expires_at             timestamptz,
  requested_by           varchar(64)    NOT NULL,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_export_package PRIMARY KEY (id),
  CONSTRAINT uq_data_export_package_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_data_export_package_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_data_export_package_status CHECK (status IN ('REQUESTED', 'COLLECTING', 'READY', 'DELIVERED', 'EXPIRED', 'FAILED')),
  CONSTRAINT ck_data_export_package_size CHECK (size_bytes IS NULL OR size_bytes >= 0),
  CONSTRAINT ck_data_export_package_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_data_export_package_ready CHECK (status NOT IN ('READY', 'DELIVERED') OR (file_id IS NOT NULL AND sha256 IS NOT NULL)),
  CONSTRAINT ck_data_export_package_delivered CHECK (status <> 'DELIVERED' OR (delivered_at IS NOT NULL AND delivered_to IS NOT NULL)),
  CONSTRAINT ck_data_export_package_items CHECK (item_count >= 0),
  CONSTRAINT fk_data_export_package_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_data_export_package_request FOREIGN KEY (request_id, tenant_id) REFERENCES ph20_tenant.lifecycle_request (id, tenant_id),
  CONSTRAINT fk_data_export_package_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE UNIQUE INDEX uq_data_export_package_open ON ph20_tenant.data_export_package (tenant_id) WHERE status IN ('REQUESTED', 'COLLECTING');
CREATE INDEX ix_data_export_package_tenant_status ON ph20_tenant.data_export_package (tenant_id, status);
CREATE INDEX ix_data_export_package_fk_request ON ph20_tenant.data_export_package (tenant_id, request_id);
CREATE INDEX ix_data_export_package_fk_file ON ph20_tenant.data_export_package (tenant_id, file_id);
CREATE TRIGGER tg_data_export_package_touch BEFORE UPDATE ON ph20_tenant.data_export_package FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.data_export_package', 'CTL');
COMMENT ON TABLE ph20_tenant.data_export_package IS 'EN-20-24 Gói bàn giao dữ liệu tenant (FR-20-041): gói xuất khi chấm dứt, gồm các mục theo phân hệ; giữ `20.export.retention-days` ngày. Phát EVT-20-16 khi sẵn sàng.';
COMMENT ON COLUMN ph20_tenant.data_export_package.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.data_export_package.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.data_export_package.request_id IS 'Đề nghị vòng đời chấm dứt phát sinh gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.status IS 'Trạng thái: `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.data_export_package.file_id IS 'Tệp gói ở `file_object`.';
COMMENT ON COLUMN ph20_tenant.data_export_package.size_bytes IS 'Kích thước gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.sha256 IS 'Mã băm SHA-256 của gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.item_count IS 'Số mục theo phân hệ.';
COMMENT ON COLUMN ph20_tenant.data_export_package.ready_at IS 'Thời điểm sẵn sàng.';
COMMENT ON COLUMN ph20_tenant.data_export_package.delivered_at IS 'Thời điểm bàn giao.';
COMMENT ON COLUMN ph20_tenant.data_export_package.delivered_to IS 'Người, đơn vị nhận bàn giao.';
COMMENT ON COLUMN ph20_tenant.data_export_package.expires_at IS 'Hạn giữ gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.requested_by IS 'Người yêu cầu.';
COMMENT ON COLUMN ph20_tenant.data_export_package.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.data_export_package.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.data_export_package.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.data_export_package.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.data_export_package.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.data_export_package.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.data_export_package CASCADE;

--changeset ph20:ph20-0380-data-export-item
CREATE TABLE ph20_tenant.data_export_item (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  package_id             uuid           NOT NULL,
  module_code            varchar(8)     NOT NULL,
  item_type              varchar(32)    NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  row_count              bigint,
  size_bytes             bigint,
  sha256                 char(64),
  file_id                uuid,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_export_item PRIMARY KEY (id),
  CONSTRAINT uq_data_export_item_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_data_export_item_item UNIQUE (package_id, module_code, item_type),
  CONSTRAINT ck_data_export_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_data_export_item_status CHECK (status IN ('PENDING', 'COLLECTING', 'DONE', 'FAILED')),
  CONSTRAINT ck_data_export_item_counts CHECK ((row_count IS NULL OR row_count >= 0) AND (size_bytes IS NULL OR size_bytes >= 0)),
  CONSTRAINT ck_data_export_item_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_data_export_item_done CHECK (status <> 'DONE' OR sha256 IS NOT NULL),
  CONSTRAINT fk_data_export_item_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_data_export_item_package FOREIGN KEY (package_id, tenant_id) REFERENCES ph20_tenant.data_export_package (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_data_export_item_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code),
  CONSTRAINT fk_data_export_item_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_data_export_item_fk_package ON ph20_tenant.data_export_item (tenant_id, package_id);
CREATE INDEX ix_data_export_item_fk_file ON ph20_tenant.data_export_item (tenant_id, file_id);
CREATE TRIGGER tg_data_export_item_touch BEFORE UPDATE ON ph20_tenant.data_export_item FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.data_export_item', 'CTL');
COMMENT ON TABLE ph20_tenant.data_export_item IS 'EN-20-24 Mục của gói bàn giao (FR-20-041): dữ liệu một phân hệ đóng gói riêng, có số dòng và mã băm để đối chiếu.';
COMMENT ON COLUMN ph20_tenant.data_export_item.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.data_export_item.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.data_export_item.package_id IS 'Gói bàn giao chứa mục.';
COMMENT ON COLUMN ph20_tenant.data_export_item.module_code IS 'Phân hệ có dữ liệu.';
COMMENT ON COLUMN ph20_tenant.data_export_item.item_type IS 'Loại dữ liệu trong phân hệ (ví dụ `catalog`, `audit-chain`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.status IS 'Trạng thái: `PENDING`, `COLLECTING`, `DONE`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.data_export_item.row_count IS 'Số bản ghi.';
COMMENT ON COLUMN ph20_tenant.data_export_item.size_bytes IS 'Kích thước.';
COMMENT ON COLUMN ph20_tenant.data_export_item.sha256 IS 'Mã băm SHA-256.';
COMMENT ON COLUMN ph20_tenant.data_export_item.file_id IS 'Tệp của mục.';
COMMENT ON COLUMN ph20_tenant.data_export_item.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.data_export_item.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.data_export_item.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.data_export_item.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.data_export_item CASCADE;
