# Phần 2 của danh mục bảng (được sinh_ddl.py nạp bằng exec): vòng đời, sáp nhập, nhập tổ chức, phát hành, bảng kỹ thuật, dữ liệu nền.
# Không chạy riêng.

TRANS_MERGE = ('{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "DRAFT", "CANCELLED"], "APPROVED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"], '
               '"DRY_RUN": ["APPROVED", "TRANSFERRING", "FAILED", "CANCELLED"], "TRANSFERRING": ["CONFLICT_REVIEW", "IDENTITY_TRANSFER", "FAILED"], '
               '"CONFLICT_REVIEW": ["TRANSFERRING", "IDENTITY_TRANSFER", "CANCELLED"], "IDENTITY_TRANSFER": ["CUTOVER", "FAILED"], "CUTOVER": ["TRANSITION", "FAILED"], '
               '"TRANSITION": ["COMPLETED"], "FAILED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"]}')
TRANS_RELEASE = '{"DRAFT": ["PREVIEW", "WITHDRAWN"], "PREVIEW": ["STABLE", "DEPRECATED", "WITHDRAWN"], "STABLE": ["DEPRECATED", "WITHDRAWN"], "DEPRECATED": ["WITHDRAWN"]}'
OPEN_REQ = "'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING'"

# =============================================================== 20-0060-lifecycle.sql
F("20-0060-lifecycle.sql", "Đề nghị vòng đời có duyệt, lịch sử trạng thái, gói bàn giao dữ liệu")

T("lifecycle_request", "ctl",
  "EN-20-22 Đề nghị vòng đời có duyệt (FR-20-038…042): tạm ngừng, khôi phục, chấm dứt, đổi chế độ cách ly, hạ hạn mức. Chấm dứt, đổi cách ly, hạ hạn mức cần duyệt bốn mắt (người duyệt khác người đề nghị); mỗi (tenant, loại) tối đa một đề nghị đang mở. Mọi đề nghị có lý do và mã phiếu (SEC-85).",
  ["request_type varchar(20) ! # Loại: `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE`.",
   "status varchar(16) ! = 'DRAFT' # Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`.",
   "suspend_reason varchar(24) # Lý do tạm ngừng: `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER`; bắt buộc với `SUSPEND`.",
   "essential_api_allowed boolean ! = false # Cho phép API thiết yếu hoạt động khi tạm ngừng (`20.suspend.essential-api-allowed`).",
   "reason varchar(1000) ! # Lý do đề nghị (văn bản).",
   "ticket_code varchar(32) ! # Mã phiếu, căn cứ quyết định.",
   "requested_by varchar(64) ! # Người đề nghị.",
   "requested_at timestamptz ! = now() # Thời điểm đề nghị.",
   "approved_by varchar(64) # Người duyệt, khác người đề nghị.",
   "approved_at timestamptz # Thời điểm duyệt.",
   "decision_note varchar(1000) # Ghi chú quyết định, lý do từ chối.",
   "scheduled_at timestamptz # Thời điểm dự kiến thực hiện.",
   "cooling_until timestamptz # Hết thời gian chờ trước khi chấm dứt (`20.terminate.cooling-days`).",
   "target_isolation_mode varchar(24) # Chế độ cách ly đích khi `ISOLATION_CHANGE`.",
   "quota_change_id uuid # Đề nghị đổi hạn mức liên quan khi `QUOTA_DECREASE`.",
   "executed_at timestamptz # Thời điểm thực hiện xong."],
  ck=[en("request_type", "LifecycleRequestType"), en("status", "RequestStatus"), en("suspend_reason", "SuspendReason"),
      ("target_isolation", "target_isolation_mode IS NULL OR target_isolation_mode IN (%s)" % lst(ENUM["IsolationMode"])),
      ("four_eyes", "approved_by IS NULL OR approved_by <> requested_by"),
      ("suspend", "request_type <> 'SUSPEND' OR suspend_reason IS NOT NULL"),
      ("isolation", "request_type <> 'ISOLATION_CHANGE' OR target_isolation_mode IS NOT NULL"),
      ("quota", "request_type <> 'QUOTA_DECREASE' OR quota_change_id IS NOT NULL"),
      ("approved", "request_type NOT IN ('TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE') OR status NOT IN ('APPROVED', 'EXECUTING', 'DONE') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)"),
      ("done", "status <> 'DONE' OR executed_at IS NOT NULL")],
  fk=[cfk("quota_change_id", "quota_change_request", name="quota_change")],
  uqi=[("open", "tenant_id, request_type", "status IN (%s)" % OPEN_REQ)], ix=[("tenant_status", "tenant_id, status")],
  trg=[("transition", "UPDATE", "tg_transition", "'status', " + tj(TRANS_REQUEST)), ("immutable", "UPDATE", "tg_immutable", "'request_type', 'requested_by'")], nodel=True)

T("tenant_status_history", "ctl",
  "EN-20-23 Sự kiện vòng đời, lịch sử trạng thái tenant (FR-20-043): mỗi lần đổi `tenant.status` ghi một dòng kèm lý do, mã phiếu, đề nghị hoặc lần chạy saga liên quan. Chỉ thêm. Nhật ký kiểm toán chuỗi băm của tenant do PH-13 giữ; bảng này phục vụ hiển thị nhanh và đối chiếu.",
  ["from_status varchar(16) # Trạng thái trước (rỗng với lần khai báo đầu).",
   "to_status varchar(16) ! # Trạng thái sau.",
   "reason varchar(1000) # Lý do.",
   "ticket_code varchar(32) # Mã phiếu.",
   "request_id uuid # Đề nghị vòng đời liên quan.",
   "run_id uuid # Lần chạy saga liên quan.",
   "changed_by varchar(64) ! # Người hoặc tài khoản dịch vụ thực hiện.",
   "changed_at timestamptz ! = now() # Thời điểm đổi.",
   "trace_id char(32) # Mã vết phân tán."],
  ck=[en("from_status", "TenantStatus"), en("to_status", "TenantStatus"), ("changed", "from_status IS NULL OR from_status <> to_status"),
      ("trace", "trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'")],
  fk=[cfk("request_id", "lifecycle_request"), cfk("run_id", "provisioning_run")],
  ix=[("tenant_changed", "tenant_id, changed_at DESC")], append=True, nodel=True)

T("data_export_package", "ctl",
  "EN-20-24 Gói bàn giao dữ liệu tenant (FR-20-041): gói xuất khi chấm dứt, gồm các mục theo phân hệ; giữ `20.export.retention-days` ngày. Phát EVT-20-16 khi sẵn sàng.",
  ["request_id uuid # Đề nghị vòng đời chấm dứt phát sinh gói.",
   "status varchar(12) ! = 'REQUESTED' # Trạng thái: `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED`.",
   "file_id uuid # Tệp gói ở `file_object`.",
   "size_bytes bigint # Kích thước gói.",
   "sha256 char(64) # Mã băm SHA-256 của gói.",
   "item_count integer ! = 0 # Số mục theo phân hệ.",
   "ready_at timestamptz # Thời điểm sẵn sàng.",
   "delivered_at timestamptz # Thời điểm bàn giao.",
   "delivered_to varchar(255) # Người, đơn vị nhận bàn giao.",
   "expires_at timestamptz # Hạn giữ gói.",
   "requested_by varchar(64) ! # Người yêu cầu.",
   "error_message varchar(1000) # Thông điệp lỗi."],
  ck=[en("status", "ExportPackageStatus"), ("size", "size_bytes IS NULL OR size_bytes >= 0"), ("sha", "sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'"),
      ("ready", "status NOT IN ('READY', 'DELIVERED') OR (file_id IS NOT NULL AND sha256 IS NOT NULL)"),
      ("delivered", "status <> 'DELIVERED' OR (delivered_at IS NOT NULL AND delivered_to IS NOT NULL)"), ("items", "item_count >= 0")],
  fk=[cfk("request_id", "lifecycle_request"), cfk("file_id", "file_object")],
  uqi=[("open", "tenant_id", "status IN ('REQUESTED', 'COLLECTING')")], ix=[("tenant_status", "tenant_id, status")], nodel=True)

T("data_export_item", "ctl",
  "EN-20-24 Mục của gói bàn giao (FR-20-041): dữ liệu một phân hệ đóng gói riêng, có số dòng và mã băm để đối chiếu.",
  ["package_id uuid ! # Gói bàn giao chứa mục.",
   "module_code varchar(8) ! # Phân hệ có dữ liệu.",
   "item_type varchar(32) ! # Loại dữ liệu trong phân hệ (ví dụ `catalog`, `audit-chain`).",
   "status varchar(12) ! = 'PENDING' # Trạng thái: `PENDING`, `COLLECTING`, `DONE`, `FAILED`.",
   "row_count bigint # Số bản ghi.",
   "size_bytes bigint # Kích thước.",
   "sha256 char(64) # Mã băm SHA-256.",
   "file_id uuid # Tệp của mục.",
   "error_message varchar(1000) # Thông điệp lỗi."],
  ck=[en("status", "ExportItemStatus"), ("counts", "(row_count IS NULL OR row_count >= 0) AND (size_bytes IS NULL OR size_bytes >= 0)"),
      ("sha", "sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'"), ("done", "status <> 'DONE' OR sha256 IS NOT NULL")],
  uq=[("item", "package_id, module_code, item_type")],
  fk=[cfk("package_id", "data_export_package", ondelete="CASCADE"), sfk("module_code", "platform_module", "module_code", "module"), cfk("file_id", "file_object")], nodel=True)

# =============================================================== 20-0070-merge.sql
F("20-0070-merge.sql", "Sáp nhập tenant: kế hoạch, ánh xạ, lần chuyển theo phân hệ, xung đột")

T("merge_plan", "plat",
  "EN-20-25 Kế hoạch sáp nhập (FR-20-045, 051, 052): tenant nguồn sáp nhập vào tenant đích (D03-10 §5.4). Dữ liệu nền tảng; hai tenant bên tham gia đọc được kế hoạch của mình. Mỗi tenant nguồn tối đa một kế hoạch đang mở; duyệt bốn mắt (người duyệt khác người lập).",
  ["plan_code varchar(48) ! # Mã kế hoạch dạng `sap-nhap-t68-t69`, dùng ở route `/nen-tang/sap-nhap/{ma}`.",
   "name varchar(255) ! # Tên kế hoạch.",
   "status varchar(20) ! = 'DRAFT' # Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED`.",
   "source_tenant_code varchar(16) ! # Tenant nguồn (sẽ sang `MERGED`).",
   "target_tenant_code varchar(16) ! # Tenant đích nhận dữ liệu.",
   "legal_basis varchar(1000) ! # Căn cứ pháp lý của việc sắp xếp đơn vị hành chính.",
   "ticket_code varchar(32) # Mã phiếu.",
   "effective_date date # Ngày hiệu lực của việc sắp xếp.",
   "transition_months smallint ! = 6 # Thời gian chuyển tiếp, tháng (`20.merge.transition-months`, trần `20.merge.transition-max-months` kiểm ở dịch vụ).",
   "requested_by varchar(64) ! # Người lập kế hoạch.",
   "approved_by varchar(64) # Người duyệt, khác người lập.",
   "approved_at timestamptz # Thời điểm duyệt.",
   "dry_run_at timestamptz # Lần chạy thử gần nhất.",
   "started_at timestamptz # Bắt đầu chuyển dữ liệu.",
   "cutover_at timestamptz # Thời điểm nguồn sang `MERGED`, bật chuyển tiếp.",
   "transition_until date # Hết thời gian chuyển tiếp.",
   "completed_at timestamptz # Thời điểm kết thúc.",
   "cancel_reason varchar(1000) # Lý do hủy hoặc thất bại."],
  ck=[en("status", "MergeStatus"), ("code", "plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'"),
      ("source", "source_tenant_code ~ '^T[0-9]{2}$'"), ("target", "target_tenant_code ~ '^T[0-9]{2}$'"),
      ("distinct", "source_tenant_code <> target_tenant_code"), ("four_eyes", "approved_by IS NULL OR approved_by <> requested_by"),
      ("months", "transition_months BETWEEN 1 AND 24"),
      ("approved", "status NOT IN ('APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER', 'CUTOVER', 'TRANSITION', 'COMPLETED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)"),
      ("cutover", "status NOT IN ('CUTOVER', 'TRANSITION', 'COMPLETED') OR cutover_at IS NOT NULL"),
      ("completed", "status <> 'COMPLETED' OR completed_at IS NOT NULL")],
  uq=[("code", "plan_code")],
  fk=[("source", "(source_tenant_code) REFERENCES %s.tenant (code)" % S), ("target", "(target_tenant_code) REFERENCES %s.tenant (code)" % S)],
  uqi=[("open_source", "source_tenant_code", "status NOT IN ('COMPLETED', 'CANCELLED')")],
  ix=[("target", "target_tenant_code"), ("status", "status")],
  trg=[("transition", "UPDATE", "tg_transition", "'status', " + tj(TRANS_MERGE)), ("immutable", "UPDATE", "tg_immutable", "'plan_code', 'source_tenant_code', 'target_tenant_code'")],
  post=["CREATE POLICY merge_party_read ON %s.merge_plan FOR SELECT USING (current_setting('app.tenant_id', false) IN (source_tenant_code, target_tenant_code));" % S],
  nodel=True)

T("merge_mapping", "plat",
  "EN-20-26 Ánh xạ sáp nhập (FR-20-046): bảng ánh xạ tổ chức, HTTT, mã danh mục địa phương, đường dẫn API, người dùng, topic từ nguồn sang đích; dùng cho chuyển dữ liệu và định tuyến chuyển tiếp ở APISIX.",
  ["plan_id uuid ! # Kế hoạch sáp nhập.",
   "mapping_type varchar(16) ! # Loại: `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC`.",
   "source_ref varchar(255) ! # Mã, đường dẫn hoặc định danh ở tenant nguồn.",
   "target_ref varchar(255) # Mã, đường dẫn hoặc định danh tương ứng ở tenant đích.",
   "status varchar(10) ! = 'PROPOSED' # Trạng thái: `PROPOSED`, `CONFIRMED`, `CONFLICT`, `APPLIED`.",
   "note varchar(500) # Ghi chú."],
  ck=[en("mapping_type", "MergeMappingType"), en("status", "MappingStatus"), ("target", "status NOT IN ('CONFIRMED', 'APPLIED') OR target_ref IS NOT NULL")],
  uq=[("source", "plan_id, mapping_type, source_ref")], fk=[cfk("plan_id", "merge_plan", ondelete="CASCADE")], nodel=True)

T("merge_participant_run", "plat",
  "EN-20-27 Lần chuyển theo phân hệ (FR-20-047, 048): mỗi phân hệ có dữ liệu chạy từng pha (chạy thử, chuyển, định danh, chuyển tiếp, kiểm đếm) theo hợp đồng bên tham gia sáp nhập (ADR-202); PH-18 chạy công cụ chuyển, PH-20 điều phối.",
  ["plan_id uuid ! # Kế hoạch sáp nhập.",
   "module_code varchar(8) ! # Phân hệ tham gia.",
   "phase varchar(10) ! # Pha: `DRY_RUN`, `TRANSFER`, `IDENTITY`, `CUTOVER`, `VERIFY`.",
   "status varchar(10) ! = 'PENDING' # Trạng thái: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED`.",
   "attempt integer ! = 1 # Lần thử.",
   "exported_count bigint ! = 0 # Số bản ghi xuất từ nguồn.",
   "imported_count bigint ! = 0 # Số bản ghi nhập vào đích (giữ `id` gốc, ghi `origin_tenant_id`).",
   "verified_count bigint ! = 0 # Số bản ghi đã kiểm đếm khớp.",
   "conflict_count bigint ! = 0 # Số xung đột phát sinh.",
   "transfer_ref varchar(64) # Mã lệnh chuyển ở PH-18 (`/api/ops/v1/merge-transfers`).",
   "started_at timestamptz # Bắt đầu.",
   "finished_at timestamptz # Kết thúc.",
   "error_code varchar(16) # Mã lỗi.",
   "error_message varchar(1000) # Thông điệp lỗi."],
  ck=[en("phase", "ParticipantPhase"), en("status", "ParticipantStatus"), ("attempt", "attempt >= 1"),
      ("counts", "exported_count >= 0 AND imported_count >= 0 AND verified_count >= 0 AND conflict_count >= 0")],
  uq=[("phase", "plan_id, module_code, phase")],
  fk=[cfk("plan_id", "merge_plan", ondelete="CASCADE"), sfk("module_code", "platform_module", "module_code", "module")], nodel=True)

T("merge_conflict", "plat",
  "EN-20-28 Xung đột sáp nhập (FR-20-049): mã danh mục, đường dẫn API, người dùng trùng giữa nguồn và đích; cán bộ nghiệp vụ chọn cách xử lý (`ConflictResolution`).",
  ["plan_id uuid ! # Kế hoạch sáp nhập.",
   "participant_run_id uuid # Lần chuyển phát hiện xung đột.",
   "mapping_type varchar(16) ! # Loại đối tượng xung đột.",
   "source_ref varchar(255) ! # Đối tượng ở nguồn.",
   "target_ref varchar(255) # Đối tượng trùng ở đích.",
   "conflict_kind varchar(16) ! # Dạng: `DUPLICATE_CODE`, `DUPLICATE_PATH`, `DUPLICATE_USER`, `OTHER`.",
   "state varchar(10) ! = 'OPEN' # Trạng thái: `OPEN` hoặc `RESOLVED`.",
   "resolution varchar(16) # Cách xử lý: `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`.",
   "resolved_by varchar(64) # Người xử lý.",
   "resolved_at timestamptz # Thời điểm xử lý.",
   "resolution_note varchar(1000) # Ghi chú xử lý."],
  ck=[en("mapping_type", "MergeMappingType"), en("conflict_kind", "ConflictKind"), en("state", "ConflictState"), en("resolution", "ConflictResolution"),
      ("resolved", "state <> 'RESOLVED' OR (resolution IS NOT NULL AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)")],
  fk=[cfk("plan_id", "merge_plan", ondelete="CASCADE"), cfk("participant_run_id", "merge_participant_run", name="participant_run")],
  ix=[("plan_state", "plan_id, state")], nodel=True)

# =============================================================== 20-0075-orgimport.sql
F("20-0075-orgimport.sql", "Nhập tổ chức từ tệp: lô và dòng")

T("org_import_job", "own",
  "EN-20-30 Lô nhập tổ chức (FR-20-055): tệp Excel hoặc CSV, xem trước kết quả kiểm tra rồi mới áp dụng; số dòng tối đa `20.org.import-max-rows` kiểm ở dịch vụ; bản xem trước hết hạn.",
  ["file_id uuid ! # Tệp nhập ở `file_object`.",
   "format varchar(4) ! # Định dạng tệp: `XLSX` hoặc `CSV`.",
   "mode varchar(12) ! = 'CREATE_ONLY' # Chế độ: `CREATE_ONLY` (chỉ thêm mới) hoặc `UPSERT` (thêm hoặc cập nhật).",
   "status varchar(10) ! = 'UPLOADED' # Trạng thái: `UPLOADED`, `PREVIEWED`, `APPLYING`, `DONE`, `FAILED`, `CANCELLED`.",
   "total_rows integer ! = 0 # Tổng số dòng dữ liệu.",
   "valid_rows integer ! = 0 # Số dòng hợp lệ.",
   "error_rows integer ! = 0 # Số dòng lỗi.",
   "applied_rows integer ! = 0 # Số dòng đã áp dụng.",
   "preview_expires_at timestamptz # Hạn giữ bản xem trước.",
   "applied_at timestamptz # Thời điểm áp dụng xong.",
   "error_file_id uuid # Tệp liệt kê dòng lỗi để tải về sửa.",
   "error_message varchar(1000) # Thông điệp lỗi chung."],
  ck=[en("status", "ImportStatus"), en("mode", "ImportMode"), ("format", "format IN ('XLSX', 'CSV')"),
      ("rows", "total_rows >= 0 AND valid_rows >= 0 AND error_rows >= 0 AND applied_rows >= 0 AND valid_rows + error_rows <= total_rows AND applied_rows <= valid_rows"),
      ("done", "status <> 'DONE' OR applied_at IS NOT NULL")],
  fk=[cfk("file_id", "file_object"), cfk("error_file_id", "file_object", name="error_file")], ix=[("status", "tenant_id, status")], nodel=True)

T("org_import_row", "own",
  "EN-20-30 Dòng của lô nhập tổ chức (FR-20-055): nội dung từng dòng, hành động dự kiến và lỗi kiểm tra; dòng lỗi không được áp dụng.",
  ["job_id uuid ! # Lô nhập.",
   "row_no integer ! # Số thứ tự dòng trong tệp, bắt đầu từ 1.",
   "org_code varchar(64) # Mã tổ chức đọc được từ dòng.",
   "action varchar(8) ! = 'SKIP' # Hành động: `CREATE`, `UPDATE`, `SKIP`, `ERROR`.",
   "status varchar(8) ! = 'VALID' # Trạng thái: `VALID`, `ERROR`, `APPLIED`, `SKIPPED`.",
   "errors jsonb ! = '[]' # Danh sách lỗi kiểm tra (cột, mã lỗi, thông điệp).",
   "data jsonb ! # Nội dung dòng đã chuẩn hóa."],
  ck=[en("action", "ImportAction"), en("status", "ImportRowStatus"), ("row", "row_no >= 1"), ("errors", "jsonb_typeof(errors) = 'array' AND jsonb_typeof(data) = 'object'"),
      ("error_action", "status <> 'ERROR' OR action = 'ERROR'")],
  uq=[("row", "job_id, row_no")], fk=[cfk("job_id", "org_import_job", ondelete="CASCADE")], nodel=True)

# =============================================================== 20-0080-release.sql
F("20-0080-release.sql", "Phát hành sản phẩm: phiên bản, thành phần, kênh, bảo trì, nâng cấp, kiểm thử rò rỉ")

T("product_release", "platr",
  "EN-20-31 Phiên bản sản phẩm (FR-20-059, 060): danh mục phiên bản Datahub với ghi chú phát hành, qua `PREVIEW` rồi `STABLE` (ADR-203). Dữ liệu nền tảng, mọi tenant đọc được để xem phiên bản và ghi chú (FR-20-064).",
  ["version_code varchar(32) ! # Số phiên bản, dạng `1.0.0` hoặc `1.1.0-rc.1`.",
   "name varchar(255) # Tên bản phát hành.",
   "status varchar(12) ! = 'DRAFT' # Trạng thái: `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN`.",
   "release_notes text # Ghi chú phát hành (Markdown).",
   "breaking_change boolean ! = false # Có thay đổi phá vỡ tương thích.",
   "min_from_version varchar(32) # Phiên bản thấp nhất được nâng cấp thẳng lên bản này.",
   "preview_at timestamptz # Thời điểm sang kênh `PREVIEW`.",
   "stable_at timestamptz # Thời điểm sang kênh `STABLE` (sau thời gian chạy thử, `20.release.stable-soak-days`).",
   "deprecated_at timestamptz # Thời điểm ngừng khuyến nghị.",
   "withdrawn_at timestamptz # Thời điểm rút bản.",
   "withdrawn_reason varchar(1000) # Lý do rút bản."],
  ck=[en("status", "ReleaseStatus"), ("version", "version_code ~ '^[0-9]+\\.[0-9]+\\.[0-9]+(-[A-Za-z0-9.]+)?$'"),
      ("preview", "status NOT IN ('PREVIEW', 'STABLE', 'DEPRECATED') OR preview_at IS NOT NULL"),
      ("stable", "status <> 'STABLE' OR (stable_at IS NOT NULL AND preview_at IS NOT NULL AND stable_at >= preview_at)"),
      ("withdrawn", "status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdrawn_reason IS NOT NULL)")],
  uq=[("version", "version_code")],
  trg=[("transition", "UPDATE", "tg_transition", "'status', " + tj(TRANS_RELEASE)), ("immutable", "UPDATE", "tg_immutable", "'version_code'")], nodel=True)

T("release_component", "platr",
  "EN-20-31 Thành phần của phiên bản (FR-20-059): dịch vụ, giao diện, chart, schema CSDL, cấu hình thuộc một bản phát hành, kèm mã băm ảnh. Không chứa thông tin xác thực kho ảnh.",
  ["release_id uuid ! # Phiên bản sản phẩm.",
   "component_code varchar(64) ! # Mã thành phần, ví dụ `dh-platform`, `dh-console`, `ph20_tenant`.",
   "component_type varchar(10) ! # Loại: `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG`.",
   "image_ref varchar(255) # Tham chiếu ảnh, gói (không kèm thông tin xác thực).",
   "chart_version varchar(32) # Phiên bản Helm chart.",
   "digest varchar(71) # Mã băm ảnh `sha256:...`.",
   "migration_required boolean ! = false # Cần chạy migration CSDL khi nâng cấp."],
  ck=[en("component_type", "ComponentType"), ("digest", "digest IS NULL OR digest ~ '^sha256:[0-9a-f]{64}$'")],
  uq=[("component", "release_id, component_code")], fk=[cfk("release_id", "product_release", ondelete="CASCADE")], nodel=True)

T("tenant_release_subscription", "ctl",
  "EN-20-32 Đăng ký kênh phát hành của tenant (FR-20-060): tenant theo kênh `STABLE` hoặc `PREVIEW`, có thể ghim phiên bản, đánh dấu tenant thí điểm nhận bản trước (ADR-203). Một dòng mỗi tenant.",
  ["channel varchar(8) ! = 'STABLE' # Kênh: `STABLE` hoặc `PREVIEW`.",
   "pinned_release_id uuid # Phiên bản được ghim (không tự nâng cấp lên bản mới hơn).",
   "current_release_id uuid # Phiên bản đang chạy của tenant.",
   "is_pilot boolean ! = false # Tenant thí điểm, nhận bản `PREVIEW` và là nơi chạy thử đủ thời gian trước khi sang `STABLE`.",
   "subscribed_at timestamptz ! = now() # Thời điểm đăng ký kênh."],
  ck=[en("channel", "ReleaseChannel")],
  uq=[("tenant", "tenant_id")],
  fk=[sfk("pinned_release_id", "product_release", name="pinned_release"), sfk("current_release_id", "product_release", name="current_release")], nodel=True)

T("maintenance_window", "own",
  "EN-20-33 Cửa sổ bảo trì của tenant (FR-20-061, 063, 064): khung giờ định kỳ hoặc một lần mà nâng cấp được phép chạy; tỉnh tự khai báo, kế hoạch nâng cấp tôn trọng cửa sổ.",
  ["name varchar(255) ! # Tên cửa sổ.",
   "window_type varchar(10) ! = 'RECURRING' # Loại: `RECURRING` (hằng tuần) hoặc `ONE_OFF` (một lần).",
   "day_of_week smallint # Thứ trong tuần theo ISO, 1 là thứ Hai (cửa sổ `RECURRING`).",
   "start_time time # Giờ bắt đầu theo múi giờ của cửa sổ (cửa sổ `RECURRING`).",
   "duration_minutes integer ! = 120 # Thời lượng, phút.",
   "starts_at timestamptz # Bắt đầu (cửa sổ `ONE_OFF`).",
   "ends_at timestamptz # Kết thúc (cửa sổ `ONE_OFF`).",
   "timezone varchar(40) ! = 'Asia/Ho_Chi_Minh' # Múi giờ.",
   "enabled boolean ! = true # Cửa sổ đang áp dụng.",
   "note varchar(500) # Ghi chú."],
  ck=[en("window_type", "WindowType"), ("duration", "duration_minutes BETWEEN 15 AND 1440"), ("day", "day_of_week IS NULL OR day_of_week BETWEEN 1 AND 7"),
      ("recurring", "window_type <> 'RECURRING' OR (day_of_week IS NOT NULL AND start_time IS NOT NULL)"),
      ("one_off", "window_type <> 'ONE_OFF' OR (starts_at IS NOT NULL AND ends_at IS NOT NULL AND ends_at > starts_at)")],
  ix=[("enabled", "tenant_id, enabled")], nodel=True)

T("upgrade_plan", "plat",
  "EN-20-34 Kế hoạch nâng cấp theo sóng (FR-20-061, 062): đưa một phiên bản lên các tenant theo từng sóng; tự dừng khi tỷ lệ lỗi vượt `error_threshold_percent` (`20.release.wave-error-threshold-percent`).",
  ["plan_code varchar(48) ! # Mã kế hoạch, dạng `nang-cap-1-1-0`.",
   "release_id uuid ! # Phiên bản đích.",
   "channel varchar(8) ! = 'STABLE' # Kênh áp dụng: `STABLE` hoặc `PREVIEW`.",
   "status varchar(12) ! = 'DRAFT' # Trạng thái: `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED`.",
   "error_threshold_percent numeric(5,2) ! = 2 # Ngưỡng lỗi dừng sóng, phần trăm.",
   "scheduled_at timestamptz # Thời điểm bắt đầu dự kiến.",
   "started_at timestamptz # Bắt đầu thực tế.",
   "completed_at timestamptz # Kết thúc.",
   "pause_reason varchar(1000) # Lý do dừng.",
   "ticket_code varchar(32) # Mã phiếu thay đổi."],
  ck=[en("status", "UpgradePlanStatus"), en("channel", "ReleaseChannel"), ("code", "plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'"),
      ("threshold", "error_threshold_percent BETWEEN 0 AND 100"), ("running", "status NOT IN ('RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK') OR started_at IS NOT NULL")],
  uq=[("code", "plan_code")], fk=[cfk("release_id", "product_release")], ix=[("status", "status")],
  trg=[("immutable", "UPDATE", "tg_immutable", "'plan_code', 'release_id'")], nodel=True)

T("upgrade_wave", "plat",
  "EN-20-34 Sóng nâng cấp (FR-20-061, 062): nhóm tenant nâng cấp cùng lúc, thường sóng 1 là tenant thí điểm; dừng sóng tự động khi vượt ngưỡng lỗi.",
  ["plan_id uuid ! # Kế hoạch nâng cấp.",
   "wave_no smallint ! # Số thứ tự sóng, bắt đầu từ 1.",
   "name varchar(255) # Tên sóng.",
   "status varchar(10) ! = 'PENDING' # Trạng thái: `PENDING`, `RUNNING`, `PAUSED`, `DONE`, `STOPPED`.",
   "tenant_selector jsonb ! = '{}' # Điều kiện chọn tenant (danh sách mã, cờ thí điểm, hồ sơ quy mô).",
   "tenant_count integer ! = 0 # Số tenant trong sóng.",
   "planned_start timestamptz # Bắt đầu dự kiến.",
   "started_at timestamptz # Bắt đầu thực tế.",
   "finished_at timestamptz # Kết thúc.",
   "error_percent numeric(5,2) # Tỷ lệ lỗi hiện tại của sóng."],
  ck=[en("status", "WaveStatus"), ("wave", "wave_no >= 1"), ("selector", "jsonb_typeof(tenant_selector) = 'object'"), ("count", "tenant_count >= 0"),
      ("error", "error_percent IS NULL OR error_percent BETWEEN 0 AND 100")],
  uq=[("wave", "plan_id, wave_no")], fk=[cfk("plan_id", "upgrade_plan", ondelete="CASCADE")], nodel=True)

T("tenant_upgrade", "ctl",
  "EN-20-35 Nâng cấp theo tenant (FR-20-062, 064): trạng thái nâng cấp của từng tenant trong một sóng, gắn cửa sổ bảo trì; mỗi đổi trạng thái phát EVT-20-15.",
  ["plan_id uuid ! # Kế hoạch nâng cấp.",
   "wave_id uuid ! # Sóng chứa tenant.",
   "release_id uuid ! # Phiên bản đích.",
   "status varchar(12) ! = 'PENDING' # Trạng thái: `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED`.",
   "maintenance_window_id uuid # Cửa sổ bảo trì được dùng.",
   "scheduled_for timestamptz # Thời điểm dự kiến trong cửa sổ.",
   "started_at timestamptz # Bắt đầu nâng cấp.",
   "verified_at timestamptz # Kiểm tra sau nâng cấp xong.",
   "finished_at timestamptz # Kết thúc.",
   "attempt integer ! = 1 # Lần thử.",
   "rollback_release_id uuid # Phiên bản quay lui khi `ROLLED_BACK`.",
   "error_code varchar(16) # Mã lỗi.",
   "error_message varchar(1000) # Thông điệp lỗi."],
  ck=[en("status", "TenantUpgradeStatus"), ("attempt", "attempt >= 1"), ("done", "status <> 'DONE' OR finished_at IS NOT NULL"),
      ("rollback", "status <> 'ROLLED_BACK' OR rollback_release_id IS NOT NULL")],
  uq=[("wave", "wave_id, tenant_id")],
  fk=[sfk("plan_id", "upgrade_plan"), sfk("wave_id", "upgrade_wave"), sfk("release_id", "product_release"), cfk("maintenance_window_id", "maintenance_window", name="window"),
      sfk("rollback_release_id", "product_release", name="rollback_release")],
  ix=[("tenant_status", "tenant_id, status"), ("plan", "plan_id")], nodel=True)

T("leak_test_run", "plat",
  "EN-20-36 Lần kiểm thử rò rỉ chéo tenant (FR-20-070, SEC-87): chạy hằng đêm hoặc trước khi kích hoạt tenant mới; ghi số ca, số ca lỗi, danh sách lỗi. Ca lỗi là sự cố an ninh mức cao.",
  ["trigger_type varchar(14) ! = 'SCHEDULE' # Nguồn kích hoạt: `SCHEDULE`, `MANUAL`, `PRE_ACTIVATION`.",
   "status varchar(8) ! = 'RUNNING' # Trạng thái: `RUNNING`, `PASSED`, `FAILED`, `ERROR`.",
   "tenant_codes text[] ! = '{}' # Các tenant được kiểm trong lần chạy.",
   "tenants_tested integer ! = 0 # Số tenant đã kiểm.",
   "cases_total integer ! = 0 # Tổng số ca.",
   "cases_failed integer ! = 0 # Số ca phát hiện rò rỉ.",
   "failures jsonb ! = '[]' # Danh sách ca lỗi (tầng, bên đọc, bên bị đọc, mô tả), không chứa dữ liệu thật.",
   "report_file_id uuid # Tệp báo cáo chi tiết.",
   "started_at timestamptz ! = now() # Bắt đầu.",
   "finished_at timestamptz # Kết thúc."],
  ck=[en("trigger_type", "LeakTrigger"), en("status", "LeakStatus"), ("counts", "tenants_tested >= 0 AND cases_total >= 0 AND cases_failed >= 0 AND cases_failed <= cases_total"),
      ("failures", "jsonb_typeof(failures) = 'array'"), ("passed", "status <> 'PASSED' OR cases_failed = 0"), ("finished", "status = 'RUNNING' OR finished_at IS NOT NULL")],
  fk=[cfk("report_file_id", "file_object", name="report_file")], ix=[("started", "started_at DESC")], nodel=True)

# =============================================================== 20-0085-ops.sql
F("20-0085-ops.sql", "Bảng kỹ thuật: outbox, inbox, lũy đẳng")

T("outbox", "tech",
  "Hạ tầng, DD-11 Outbox (SAD 7.3) cho EVT-20-01…16 và bản ghi kiểm toán gửi PH-13: ghi cùng giao dịch với thay đổi, Debezium Outbox Event Router đọc WAL và phát Kafka. Sự kiện vòng đời đi trên `platform.*`, sự kiện tổ chức trên `{tenant}.tenant.org.changed.v1`. Dọn sau 3 ngày.",
  ["event_id uuid ! # Mã sự kiện, thành `id` của CloudEvent; bên nhận dùng để chống trùng.",
   "event_type varchar(128) ! # Kiểu sự kiện, ví dụ `vn.datahub.platform.tenant.created.v1`.",
   "topic varchar(128) ! # Topic Kafka theo D00-01 §6.",
   "aggregate_type varchar(32) ! # Loại thực thể gốc (`tenant`, `organization`, `merge_plan`…).",
   "aggregate_id uuid ! # Thực thể gốc, làm khóa phân vùng Kafka.",
   "payload jsonb ! # Nội dung theo schema đã đăng ký.",
   "trace_id char(32) ! # Mã vết phân tán.",
   "occurred_at timestamptz ! = now() # Thời điểm xảy ra.",
   "published_at timestamptz # Thời điểm đã phát (do Debezium hoặc job dọn đánh dấu)."],
  ck=[("topic", "topic IN (%s) OR topic = lower(tenant_id) || '.tenant.org.changed.v1'" % lst(TOPICS)), ("trace", "trace_id ~ '^[0-9a-f]{32}$'"),
      ("payload", "jsonb_typeof(payload) = 'object'")],
  ix=[("occurred", "occurred_at"), ("unpublished", "occurred_at", "published_at IS NULL")], bare=True, pk="event_id")

T("inbox_event", "tech",
  "Hạ tầng. Hộp nhận sự kiện từ phân hệ khác (EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11): khử trùng theo `(tenant_id, consumer, event_id)` để tiêu thụ lũy đẳng.",
  ["consumer varchar(64) ! # Tên bộ tiêu thụ trong PH-20.",
   "event_id uuid ! # Mã sự kiện nhận.",
   "source_topic varchar(128) ! # Topic nguồn.",
   "received_at timestamptz ! = now() # Thời điểm nhận.",
   "processed_at timestamptz # Thời điểm xử lý xong."],
  ix=[("received", "received_at")], bare=True, pk="tenant_id, consumer, event_id")

T("idempotency_key", "tech",
  "Hạ tầng. Kết quả yêu cầu ghi có tiêu đề `Idempotency-Key` (API công khai và saga: khóa `{runId}:{stepCode}`); giữ 24 giờ. Cột khóa tên `idempotency_ref` (tránh trùng tên cột nhạy cảm của công cụ quét).",
  ["client_id varchar(255) ! # Định danh máy khách gọi API.",
   "request_method varchar(8) ! # Phương thức HTTP.",
   "request_path varchar(512) ! # Đường dẫn yêu cầu.",
   "idempotency_ref varchar(128) ! # Giá trị tiêu đề `Idempotency-Key`.",
   "request_hash char(64) ! # Băm nội dung yêu cầu, phát hiện cùng khóa khác nội dung.",
   "state varchar(12) ! = 'IN_PROGRESS' # Trạng thái: `IN_PROGRESS` hoặc `COMPLETED`.",
   "resource_id uuid # Tài nguyên đã tạo.",
   "response_status smallint # Mã HTTP đã trả.",
   "response_body jsonb # Nội dung đã trả (đã che dữ liệu nhạy cảm).",
   "created_at timestamptz ! = now() # Thời điểm nhận yêu cầu đầu.",
   "completed_at timestamptz # Thời điểm hoàn tất.",
   "expires_at timestamptz ! # Hạn giữ."],
  ck=[("ref", "idempotency_ref ~ '^[A-Za-z0-9_:-]{16,128}$'"), en("state", "IdemState"), ("done", "state = 'IN_PROGRESS' OR response_status IS NOT NULL"),
      ("hash", "request_hash ~ '^[0-9a-f]{64}$'")],
  ix=[("expiry", "expires_at")], bare=True, pk="tenant_id, client_id, request_method, request_path, idempotency_ref")

# =============================================================== Dữ liệu nền (thay vào cuoi_ddl.sql)
MODULES = [
    ("PH-01", "Kết nạp HTTT", 1, "dh-connect", False, True), ("PH-02", "Danh mục dịch vụ", 1, "dh-connect", False, True),
    ("PH-03", "Cổng API", 1, "dh-connect", False, True), ("PH-04", "Lõi tích hợp và trình thiết kế luồng", 1, "dh-integration", False, True),
    ("PH-05", "Bộ điều hợp", 1, "dh-integration", False, True), ("PH-06", "Dữ liệu chủ", 3, "dh-data", False, False),
    ("PH-07", "Danh mục dùng chung", 1, "dh-data", False, True), ("PH-08", "Chất lượng dữ liệu", 3, "dh-data", False, False),
    ("PH-09", "Quyền riêng tư", 2, "dh-data", False, False), ("PH-10", "Sự kiện", 1, "dh-integration", False, True),
    ("PH-11", "Quy trình liên thông", 2, "dh-platform", False, False), ("PH-12", "Định danh và phân quyền", 1, "dh-platform", True, True),
    ("PH-13", "Giám sát và kiểm toán", 1, "dh-platform", True, True), ("PH-14", "Kết nối quốc gia", 1, "dh-runtime", False, True),
    ("PH-15", "Cổng nhà phát triển", 2, "dh-portal", False, False), ("PH-16", "Báo cáo chỉ tiêu", 3, "dh-platform", False, False),
    ("PH-17", "Trợ lý AI", 3, "dh-assist", False, False), ("PH-18", "Vận hành và xử lý lỗi", 1, "dh-platform", True, True),
    ("PH-19", "Thanh toán", 2, "dh-payment", False, False), ("PH-20", "Quản trị tenant và phát hành sản phẩm", 1, "dh-platform", True, True),
]
DEPS = [
    ("PH-01", "PH-12", "REQUIRED", "Cấp định danh ứng dụng cho HTTT"), ("PH-01", "PH-20", "REQUIRED", "Danh mục tổ chức chủ quản HTTT"),
    ("PH-02", "PH-01", "REQUIRED", "Dịch vụ thuộc HTTT thành viên"), ("PH-03", "PH-12", "REQUIRED", "Xác thực và phân quyền ở cổng"),
    ("PH-03", "PH-01", "REQUIRED", "Định danh ứng dụng gọi API"), ("PH-03", "PH-02", "REQUIRED", "Danh mục API công bố"),
    ("PH-04", "PH-05", "REQUIRED", "Luồng dùng bộ điều hợp"), ("PH-04", "PH-10", "REQUIRED", "Luồng phát nhận sự kiện"), ("PH-04", "PH-12", "REQUIRED", "Phân quyền thiết kế, phát hành luồng"),
    ("PH-05", "PH-12", "REQUIRED", "Bí mật kết nối do OpenBao, phân quyền"), ("PH-06", "PH-07", "REQUIRED", "Dùng danh mục dùng chung"),
    ("PH-06", "PH-10", "OPTIONAL", "Phát sự kiện bản ghi vàng"), ("PH-07", "PH-12", "REQUIRED", "Phân quyền danh mục"),
    ("PH-08", "PH-06", "REQUIRED", "Đo chất lượng dữ liệu chủ"), ("PH-08", "PH-07", "OPTIONAL", "Đối chiếu danh mục"),
    ("PH-09", "PH-12", "REQUIRED", "Phân quyền, người dùng"), ("PH-09", "PH-07", "OPTIONAL", "Phân loại theo danh mục"),
    ("PH-10", "PH-12", "REQUIRED", "Phân quyền topic, schema"), ("PH-11", "PH-12", "REQUIRED", "Người xử lý quy trình"),
    ("PH-11", "PH-10", "OPTIONAL", "Sự kiện quy trình"), ("PH-12", "PH-13", "REQUIRED", "Ghi nhật ký kiểm toán"), ("PH-13", "PH-12", "REQUIRED", "Phân quyền xem nhật ký"),
    ("PH-14", "PH-05", "REQUIRED", "Adapter dùng Kamelet"), ("PH-14", "PH-12", "REQUIRED", "Phân quyền kết nối quốc gia"),
    ("PH-15", "PH-02", "REQUIRED", "Tài liệu API từ danh mục dịch vụ"), ("PH-15", "PH-03", "REQUIRED", "Thử API qua cổng"),
    ("PH-16", "PH-13", "OPTIONAL", "Nguồn số liệu giám sát"), ("PH-17", "PH-12", "REQUIRED", "Quyền dùng trợ lý"), ("PH-17", "PH-09", "OPTIONAL", "Che dữ liệu cá nhân trong lời nhắc"),
    ("PH-18", "PH-12", "REQUIRED", "Phân quyền vận hành"), ("PH-18", "PH-13", "REQUIRED", "Nhật ký vận hành"),
    ("PH-19", "PH-03", "REQUIRED", "API thanh toán qua cổng"), ("PH-19", "PH-10", "REQUIRED", "Sự kiện giao dịch"), ("PH-19", "PH-12", "REQUIRED", "Phân quyền, đối tác"),
    ("PH-20", "PH-12", "REQUIRED", "Tạo realm khi khởi tạo tenant"), ("PH-20", "PH-13", "REQUIRED", "Chuỗi kiểm toán theo tenant"), ("PH-20", "PH-18", "OPTIONAL", "Tham số, thông báo"),
]
QUOTA = {"API_RPS": 500, "ACTIVE_FLOWS": 1000, "KAFKA_PRODUCE_MBPS": 10, "KAFKA_CONSUME_MBPS": 20, "OBJECT_STORAGE_GB": 500, "DATABASE_GB": 200, "USERS": 2000,
         "MEMBER_SYSTEMS": 300, "PUBLISHED_APIS": 2000, "TOPICS": 2000, "RUNTIME_CPU": 16, "RUNTIME_MEMORY_GB": 64}
STEPS = [("S01_RECORD", "PH-20", True), ("S02_CONFIG_REPO", "PH-20", True), ("S03_REALM", "PH-12", True), ("S04_SECRETS", "PH-20", True), ("S05_BUCKETS", "PH-20", True),
         ("S06_EVENTING", "PH-10", True), ("S07_DATABASE", "PH-20", False), ("S08_OBSERVABILITY", "PH-13", True), ("S09_GATEWAY", "PH-03", True),
         ("S10_INTEGRATION", "PH-04", True), ("S11_SEED_RDM", "PH-07", True), ("S12_SEED_MDM", "PH-06", False), ("S13_ORG_SEED", "PH-20", True),
         ("S14_KPI", "PH-16", False), ("S15_MODULES", "PH-20", True), ("S16_SMOKE", "PH-20", True), ("S17_ACTIVATE", "PH-20", True)]
ORGS = [("UBND", "Ủy ban nhân dân tỉnh", "PROVINCE_PC"), ("SO-NV", "Sở Nội vụ", "DEPARTMENT"), ("SO-TC", "Sở Tài chính", "DEPARTMENT"),
        ("SO-KHCN", "Sở Khoa học và Công nghệ", "DEPARTMENT"), ("SO-TP", "Sở Tư pháp", "DEPARTMENT"), ("SO-YT", "Sở Y tế", "DEPARTMENT")]


def sqlstr(s):
    return "'%s'" % s.replace("'", "''")


def seed_subst(tail):
    import json
    mods = ",\n    ".join("(%s, %s, %d, %s, %s, %s, %d)" % (sqlstr(c), sqlstr(n), w, sqlstr(du), str(core).lower(), str(de).lower(), i + 1)
                          for i, (c, n, w, du, core, de) in enumerate(MODULES))
    deps = ",\n    ".join("(%s, %s, %s, %s)" % (sqlstr(a), sqlstr(b), sqlstr(t), sqlstr(r)) for a, b, t, r in DEPS)
    quota = sqlstr(json.dumps(QUOTA, ensure_ascii=False))
    steps = sqlstr(json.dumps([{"stepCode": c, "executor": e, "required": r} for c, e, r in STEPS], ensure_ascii=False))
    orgs = sqlstr(json.dumps([{"code": c, "name": n, "orgType": t} for c, n, t in ORGS], ensure_ascii=False))
    return tail.replace("@@MODULES@@", mods).replace("@@DEPS@@", deps).replace("@@QUOTA@@", quota + "::jsonb").replace("@@STEPS@@", steps + "::jsonb").replace("@@ORGSEED@@", orgs + "::jsonb")
