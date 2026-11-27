# language: vi
# Sinh tự động từ D02-02/D02-03-PH20 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-20
Tính năng: PH-20 · Quản trị tenant và phát hành sản phẩm

  # ---- EP-20-A · Hồ sơ tenant

  @US-20-001 @FR-20-001 @M
  Kịch bản: US-20-001 dương · Khai báo tenant mới
    Biết người dùng ở tenant `PLATFORM`, đã xác thực WebAuthn; danh mục ĐVHC `COMMON` của PH-07 sẵn sàng; có ít nhất một mẫu khởi tạo `PUBLISHED` (FR-20-015)
    Khi bấm "+ Khai báo tenant" ở UI-20-01, đi qua năm bước wizard UI-20-02 rồi bấm "Lưu khai báo" hoặc "Lưu và khởi tạo"
    Thì hệ thống trả `201`; `tenantCode`, `status = PROVISIONING`, `realm`, `readiness` (kết quả FR-20-007), `ETag`; tiêu đề `Location: /api/platform/v1/tenants/T68`
    Và có bản ghi DD-01, đầu mối EN-20-03, hạn mức dự kiến EN-20-13 theo mẫu và hồ sơ quy mô; chưa có tài nguyên ở hệ khác; không phát sự kiện (EVT-20-01 chỉ phát ở bước `S05` của saga)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-001 @FR-20-001 @M @âm
  Kịch bản: US-20-001 âm 1 · Mã sai mẫu hoặc trường sai miền
    Biết người dùng ở tenant `PLATFORM`, đã xác thực WebAuthn; danh mục ĐVHC `COMMON` của PH-07 sẵn sàng; có ít nhất một mẫu khởi tạo `PUBLISHED` (FR-20-015)
    Khi mã sai mẫu hoặc trường sai miền
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-001 @FR-20-001 @M @âm
  Kịch bản: US-20-001 âm 2 · Mã đã dùng
    Biết người dùng ở tenant `PLATFORM`, đã xác thực WebAuthn; danh mục ĐVHC `COMMON` của PH-07 sẵn sàng; có ít nhất một mẫu khởi tạo `PUBLISHED` (FR-20-015)
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-002 @FR-20-002 @M
  Kịch bản: US-20-002 dương · Liệt kê, tìm, lọc tenant toàn nền tảng
    Biết người dùng ở tenant `PLATFORM`
    Khi mở UI-20-01 hoặc đổi bộ lọc, sắp xếp, trang
    Thì hệ thống trả `200`; `items[]` (`tenantCode`, `name`, `kind`, `status`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `currentVersion`, `channel`, `lastRun` {`runId`, `status`, `failedStep`}, `openAlerts`, `activatedAt`), `page`, `size` …

  @US-20-002 @FR-20-002 @M @âm
  Kịch bản: US-20-002 âm 1 · Tham số sai miền
    Biết người dùng ở tenant `PLATFORM`
    Khi tham số sai miền
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-002 @FR-20-002 @M @âm
  Kịch bản: US-20-002 âm 2 · `size` > 200
    Biết người dùng ở tenant `PLATFORM`
    Khi `size` > 200
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-003 @FR-20-003 @M
  Kịch bản: US-20-003 dương · Xem chi tiết tenant
    Biết tenant tồn tại
    Khi bấm một dòng ở UI-20-01 hoặc mở trực tiếp `/nen-tang/tenant/T68`
    Thì hệ thống trả `200`; các khối đã nêu, `allowedActions[]`, `ETag` của bản ghi tenant

  @US-20-003 @FR-20-003 @M @âm
  Kịch bản: US-20-003 âm 1 · Không có tenant
    Biết tenant tồn tại
    Khi không có tenant
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-003 @FR-20-003 @M @âm
  Kịch bản: US-20-003 âm 2 · `include` sai
    Biết tenant tồn tại
    Khi `include` sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-004 @FR-20-004 @M
  Kịch bản: US-20-004 dương · Sửa hồ sơ hành chính của tenant
    Biết tenant ở `PROVISIONING`, `FAILED`, `ACTIVE` hoặc `SUSPENDED`; không phải tenant đặc biệt
    Khi bấm "Sửa hồ sơ" ở UI-20-03 tab Tổng quan
    Thì hệ thống trả `200`; bản ghi tenant mới, `ETag` mới, `configVersionNo`
    Và DD-01 cập nhật, `version` tăng; có phiên bản cấu hình mới
    Và sự kiện được phát: EVT-20-09 (`changeKind = TENANT_PROFILE`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-004 @FR-20-004 @M @âm
  Kịch bản: US-20-004 âm 1 · Sửa thuộc tính bất biến
    Biết tenant ở `PROVISIONING`, `FAILED`, `ACTIVE` hoặc `SUSPENDED`; không phải tenant đặc biệt
    Khi sửa thuộc tính bất biến
    Thì hệ thống từ chối với ERR-20-068 (422)
    Và người dùng thấy thông báo "Không đổi được {thuộc tính} của tenant sau khi khai báo."

  @US-20-004 @FR-20-004 @M @âm
  Kịch bản: US-20-004 âm 2 · Tenant đặc biệt
    Biết tenant ở `PROVISIONING`, `FAILED`, `ACTIVE` hoặc `SUSPENDED`; không phải tenant đặc biệt
    Khi tenant đặc biệt
    Thì hệ thống từ chối với ERR-20-010 (403)
    Và người dùng thấy thông báo "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."

  @US-20-005 @FR-20-005 @S
  Kịch bản: US-20-005 dương · Quản lý đầu mối và hợp đồng dịch vụ của tenant
    Biết tenant không ở `DECOMMISSIONED`
    Khi tab "Hợp đồng và đầu mối" ở UI-20-03: "+ Đầu mối", "Sửa", "Ngừng"; "+ Hợp đồng", "Gia hạn"
    Thì hệ thống trả `201` khi thêm, `200` khi sửa; bản ghi đầu mối hoặc hợp đồng, `ETag`
    Và EN-20-03, EN-20-04 cập nhật; đầu mối ngừng không còn nhận thông báo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-005 @FR-20-005 @S @âm
  Kịch bản: US-20-005 âm 1 · Định dạng sai
    Biết tenant không ở `DECOMMISSIONED`
    Khi định dạng sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-006 @FR-20-006 @M
  Kịch bản: US-20-006 dương · Bảo vệ tenant đặc biệt PLATFORM và COMMON
    Biết hai bản ghi `PLATFORM`, `COMMON` được tạo bằng migration nền (Liquibase changeset `ph20-seed-special-tenants`), `kind` tương ứng, `status = ACTIVE`
    Khi bất kỳ lệnh ghi nào trên bản ghi tenant hoặc thực thể con có `tenantCode` thuộc hai mã này
    Thì hệ thống trả `403` với thân RFC 9457
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-006 @FR-20-006 @M @âm
  Kịch bản: US-20-006 âm 1 · Lệnh ghi trên tenant đặc biệt
    Biết hai bản ghi `PLATFORM`, `COMMON` được tạo bằng migration nền (Liquibase changeset `ph20-seed-special-tenants`), `kind` tương ứng, `status = ACTIVE`
    Khi lệnh ghi trên tenant đặc biệt
    Thì hệ thống từ chối với ERR-20-010 (403)
    Và người dùng thấy thông báo "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."

  @US-20-006 @FR-20-006 @M @âm
  Kịch bản: US-20-006 âm 2 · Trigger CSDL chặn (lỗi lập trình lọt qua lớp ứng dụng)
    Biết hai bản ghi `PLATFORM`, `COMMON` được tạo bằng migration nền (Liquibase changeset `ph20-seed-special-tenants`), `kind` tương ứng, `status = ACTIVE`
    Khi trigger CSDL chặn (lỗi lập trình lọt qua lớp ứng dụng)
    Thì hệ thống từ chối với ERR-20-010 (403)
    Và người dùng thấy thông báo "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."

  @US-20-007 @FR-20-007 @M
  Kịch bản: US-20-007 dương · Kiểm tra sẵn sàng trước khởi tạo
    Biết có hồ sơ khai báo (chưa lưu: API-20-005; đã lưu: API-20-006)
    Khi bước "Rà soát" của UI-20-02; nút "Kiểm tra lại" ở UI-20-04; tự động trong FR-20-008 bước 2
    Thì hệ thống trả `200`; `ready`, `checkedAt`, `items[]` (`checkCode`, `result`, `message`, `errorCode`, `hint`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-007 @FR-20-007 @M @âm
  Kịch bản: US-20-007 âm 1 · Có mục `BLOCKER` khi gọi từ FR-20-008
    Biết có hồ sơ khai báo (chưa lưu: API-20-005; đã lưu: API-20-006)
    Khi có mục `BLOCKER` khi gọi từ FR-20-008
    Thì hệ thống từ chối với ERR-20-017 (422)
    Và người dùng thấy thông báo "Kiểm tra sẵn sàng chưa đạt: {số} mục cần xử lý."

  @US-20-007 @FR-20-007 @M @âm
  Kịch bản: US-20-007 âm 2 · Vượt sức chứa (mục `CAPACITY`)
    Biết có hồ sơ khai báo (chưa lưu: API-20-005; đã lưu: API-20-006)
    Khi vượt sức chứa (mục `CAPACITY`)
    Thì hệ thống từ chối với ERR-20-013 (422)
    Và người dùng thấy thông báo "Nền tảng đã đạt sức chứa {số} tenant. Liên hệ vận hành hạ tầng để mở rộng."

  # ---- EP-20-B · Saga khởi tạo

  @US-20-008 @FR-20-008 @M
  Kịch bản: US-20-008 dương · Chạy saga khởi tạo tenant
    Biết tenant `PROVISIONING` (lần chạy `INITIAL`) hoặc `ACTIVE` (lần chạy `SUPPLEMENT`, FR-20-016); không có lần chạy khác chưa kết thúc (BR-20-006); kiểm tra sẵn sàng đạt
    Khi bấm "Khởi tạo" ở UI-20-03 hoặc "Lưu và khởi tạo" ở UI-20-02; hoặc FR-20-016 tạo lần chạy `SUPPLEMENT`
    Thì hệ thống trả `202`; `runId`, `status = PENDING`, `steps[]` (mã, thứ tự, trạng thái ban đầu); tiêu đề `Location: /api/platform/v1/provisioning-runs/{runId}`
    Và lần chạy `SUCCEEDED` và tenant `ACTIVE`; hoặc `FAILED` với tài nguyên đã tạo được giữ nguyên để thử lại
    Và sự kiện được phát: EVT-20-01 (sau `S05`), EVT-20-07 (từng phân hệ ở `S15`), EVT-20-02 (khi `FAILED`), EVT-20-03 (ở `S17`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-008 @FR-20-008 @M @âm
  Kịch bản: US-20-008 âm 1 · Tenant không ở trạng thái cho phép
    Biết tenant `PROVISIONING` (lần chạy `INITIAL`) hoặc `ACTIVE` (lần chạy `SUPPLEMENT`, FR-20-016); không có lần chạy khác chưa kết thúc (BR-20-006); kiểm tra sẵn sàng đạt
    Khi tenant không ở trạng thái cho phép
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-008 @FR-20-008 @M @âm
  Kịch bản: US-20-008 âm 2 · Đã có lần chạy dang dở
    Biết tenant `PROVISIONING` (lần chạy `INITIAL`) hoặc `ACTIVE` (lần chạy `SUPPLEMENT`, FR-20-016); không có lần chạy khác chưa kết thúc (BR-20-006); kiểm tra sẵn sàng đạt
    Khi đã có lần chạy dang dở
    Thì hệ thống từ chối với ERR-20-016 (409)
    Và người dùng thấy thông báo "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc."

  @US-20-009 @FR-20-009 @M
  Kịch bản: US-20-009 dương · Theo dõi tiến độ saga thời gian thực
    Biết có ít nhất một lần chạy
    Khi mở UI-20-04; giao diện mở luồng SSE
    Thì hệ thống trả `200`; lần chạy (`runId`, `runKind`, `status`, `startedAt`, `elapsedSeconds`, `etaSeconds`, `attempt`), `steps[]` (`stepCode`, `order`, `executor`, `mode`, `status`, `attempt`, `durationSeconds`, `errorCode`, `errorDetail`, `outputRef`) …

  @US-20-009 @FR-20-009 @M @âm
  Kịch bản: US-20-009 âm 1 · Không có lần chạy
    Biết có ít nhất một lần chạy
    Khi không có lần chạy
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-009 @FR-20-009 @M @âm
  Kịch bản: US-20-009 âm 2 · Tham số lọc sai
    Biết có ít nhất một lần chạy
    Khi tham số lọc sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-010 @FR-20-010 @M
  Kịch bản: US-20-010 dương · Thử lại saga từ bước lỗi
    Biết lần chạy `FAILED`; tenant `FAILED` (lần chạy `INITIAL`) hoặc `ACTIVE` (`SUPPLEMENT`)
    Khi bấm "Thử lại từ bước lỗi" ở đầu UI-20-04, "Thử lại bước" trên một dòng, hoặc "Bỏ qua bước" với bước không bắt buộc
    Thì hệ thống trả `202`; lần chạy với `status = RUNNING`, `attempt` mới
    Và lần chạy `RUNNING`; bước được thử lại `RUNNING` hoặc `SKIPPED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-010 @FR-20-010 @M @âm
  Kịch bản: US-20-010 âm 1 · Lần chạy không ở `FAILED`
    Biết lần chạy `FAILED`; tenant `FAILED` (lần chạy `INITIAL`) hoặc `ACTIVE` (`SUPPLEMENT`)
    Khi lần chạy không ở `FAILED`
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-010 @FR-20-010 @M @âm
  Kịch bản: US-20-010 âm 2 · Bước không ở `FAILED` hoặc không bỏ qua được
    Biết lần chạy `FAILED`; tenant `FAILED` (lần chạy `INITIAL`) hoặc `ACTIVE` (`SUPPLEMENT`)
    Khi bước không ở `FAILED` hoặc không bỏ qua được
    Thì hệ thống từ chối với ERR-20-018 (409)
    Và người dùng thấy thông báo "Không thể thử lại bước {bước}: {lý do}."

  @US-20-011 @FR-20-011 @M
  Kịch bản: US-20-011 dương · Bù trừ và hủy khởi tạo
    Biết lần chạy `FAILED` (bù trừ hoặc hủy), hoặc `PENDING` (hủy ngay, chưa có gì để bù); tenant chưa từng `ACTIVE` với lần chạy `INITIAL`
    Khi bấm "Bù trừ" hoặc "Hủy khởi tạo" ở UI-20-04; `CMP-ConfirmDialog` yêu cầu gõ lại mã tenant
    Thì hệ thống trả `202`; lần chạy `COMPENSATING`; danh sách bước sẽ bù
    Và lần chạy `COMPENSATED` hoặc `CANCELLED`; tenant `DECOMMISSIONED` khi hủy
    Và sự kiện được phát: EVT-20-04 (`DECOMMISSIONED`, `cause = PROVISIONING_CANCELLED`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-011 @FR-20-011 @M @âm
  Kịch bản: US-20-011 âm 1 · Trạng thái không cho bù
    Biết lần chạy `FAILED` (bù trừ hoặc hủy), hoặc `PENDING` (hủy ngay, chưa có gì để bù); tenant chưa từng `ACTIVE` với lần chạy `INITIAL`
    Khi trạng thái không cho bù
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-011 @FR-20-011 @M @âm
  Kịch bản: US-20-011 âm 2 · Tenant đã từng hoạt động
    Biết lần chạy `FAILED` (bù trừ hoặc hủy), hoặc `PENDING` (hủy ngay, chưa có gì để bù); tenant chưa từng `ACTIVE` với lần chạy `INITIAL`
    Khi tenant đã từng hoạt động
    Thì hệ thống từ chối với ERR-20-019 (409)
    Và người dùng thấy thông báo "Không thể bù trừ: {lý do}."

  @US-20-012 @FR-20-012 @M
  Kịch bản: US-20-012 dương · Kiểm tra khói sau khởi tạo
    Biết các bước `S01`…`S15` `SUCCEEDED` hoặc `SKIPPED`; `20.smoke.enabled = true`; ca `CROSS_TENANT_LEAK` cần tenant kiểm thử `T99` đang `ACTIVE` ở môi trường
    Khi bộ thực thi tới `S16_SMOKE`; hoặc PA bấm "Chạy lại kiểm tra khói" ở UI-20-04
    Thì hệ thống trả `202` khi chạy lại; kết quả trong chi tiết lần chạy (`smokeResults[]` gồm `case`, `result`, `durationMs`, `evidence`)
    Và EN-20-12 có kết quả; không còn tài khoản tạm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-012 @FR-20-012 @M @âm
  Kịch bản: US-20-012 âm 1 · Một ca lỗi (runtime)
    Biết các bước `S01`…`S15` `SUCCEEDED` hoặc `SKIPPED`; `20.smoke.enabled = true`; ca `CROSS_TENANT_LEAK` cần tenant kiểm thử `T99` đang `ACTIVE` ở môi trường
    Khi một ca lỗi (runtime)
    Thì hệ thống từ chối với ERR-20-117
    Và người dùng thấy thông báo "Ca kiểm tra khói {ca} lỗi: {chi tiết}."

  @US-20-012 @FR-20-012 @M @âm
  Kịch bản: US-20-012 âm 2 · Ca `CROSS_TENANT_LEAK` trả khác `404`
    Biết các bước `S01`…`S15` `SUCCEEDED` hoặc `SKIPPED`; `20.smoke.enabled = true`; ca `CROSS_TENANT_LEAK` cần tenant kiểm thử `T99` đang `ACTIVE` ở môi trường
    Khi ca `CROSS_TENANT_LEAK` trả khác `404`
    Thì hệ thống từ chối với ERR-20-111
    Và người dùng thấy thông báo "Phát hiện rò rỉ chéo tenant ở {API}."

  @US-20-013 @FR-20-013 @M
  Kịch bản: US-20-013 dương · Kích hoạt tenant và bàn giao cho quản trị tỉnh
    Biết `S16_SMOKE` `SUCCEEDED` (hoặc `SKIPPED` với tenant kiểm thử); tenant có ít nhất hai đầu mối `TENANT_ADMIN` và ít nhất hai tài khoản `ROLE-TENANT_ADMIN` đang hoạt động ở realm (kiểm bằng `GET /users` của PH-12 lọc `roleCode` và `state` …
    Khi bộ thực thi tới `S17_ACTIVATE`; hoặc PA bấm "Kích hoạt" ở UI-20-04 khi mẫu yêu cầu kích hoạt tay (ví dụ chờ lễ khai trương)
    Thì hệ thống trả `200`; tenant `ACTIVE`, `activatedAt`, `handoverDelivery` (`SENT`, `FAILED`)
    Và tenant `ACTIVE`; lần chạy `SUCCEEDED`
    Và sự kiện được phát: EVT-20-03; EVT-20-04 (`PROVISIONING` → `ACTIVE`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-013 @FR-20-013 @M @âm
  Kịch bản: US-20-013 âm 1 · Kiểm tra khói chưa đạt
    Biết `S16_SMOKE` `SUCCEEDED` (hoặc `SKIPPED` với tenant kiểm thử); tenant có ít nhất hai đầu mối `TENANT_ADMIN` và ít nhất hai tài khoản `ROLE-TENANT_ADMIN` đang hoạt động ở realm (kiểm bằng `GET /users` của PH-12 lọc `roleCode` và `state` …
    Khi kiểm tra khói chưa đạt
    Thì hệ thống từ chối với ERR-20-020 (422)
    Và người dùng thấy thông báo "Kiểm tra khói chưa đạt ({số} ca lỗi). Không thể kích hoạt tenant."

  @US-20-013 @FR-20-013 @M @âm
  Kịch bản: US-20-013 âm 2 · Chưa đủ hai quản trị tỉnh
    Biết `S16_SMOKE` `SUCCEEDED` (hoặc `SKIPPED` với tenant kiểm thử); tenant có ít nhất hai đầu mối `TENANT_ADMIN` và ít nhất hai tài khoản `ROLE-TENANT_ADMIN` đang hoạt động ở realm (kiểm bằng `GET /users` của PH-12 lọc `roleCode` và `state` …
    Khi chưa đủ hai quản trị tỉnh
    Thì hệ thống từ chối với ERR-20-021 (422)
    Và người dùng thấy thông báo "Cần đủ đầu mối {vai trò} trước khi {thao tác}."

  @US-20-014 @FR-20-014 @S
  Kịch bản: US-20-014 dương · Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16
    Biết tenant vừa `ACTIVE` qua lần chạy `INITIAL`; PH-16 có thể chưa bật (Đợt 3)
    Khi FR-20-013 bước 5; PA mở tab "Thời gian khởi tạo" ở UI-20-20
    Thì API-20-024 trả `200` với `items[]` (`tenantCode`, `provisionMinutes`, `leadTimeWorkingHours`, `slowestStep`), `median`, `p95`
    Và có số đo lưu tại PH-20; quan sát được PH-16 nhận đúng một lần

  @US-20-014 @FR-20-014 @S @âm
  Kịch bản: US-20-014 âm 1 · PH-16 trả lỗi lược đồ (runtime)
    Biết tenant vừa `ACTIVE` qua lần chạy `INITIAL`; PH-16 có thể chưa bật (Đợt 3)
    Khi PH-16 trả lỗi lược đồ (runtime)
    Thì hệ thống từ chối với ERR-20-107
    Và người dùng thấy thông báo "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}."

  @US-20-015 @FR-20-015 @S
  Kịch bản: US-20-015 dương · Quản lý mẫu khởi tạo có phiên bản
    Biết danh mục phân hệ (FR-20-033) có sẵn
    Khi UI-20-21: "+ Mẫu", "Tạo phiên bản mới", "Sửa", "Phát hành", "Ngừng", "So sánh"
    Thì hệ thống trả `201`, `200`; mẫu và phiên bản (`templateCode`, `version`, `state`, `contentHash`, `ETag`)
    Và EN-20-09 cập nhật; tối đa một phiên bản `DRAFT` mỗi mẫu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-015 @FR-20-015 @S @âm
  Kịch bản: US-20-015 âm 1 · Mã trùng
    Biết danh mục phân hệ (FR-20-033) có sẵn
    Khi mã trùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-016 @FR-20-016 @S
  Kịch bản: US-20-016 dương · Khởi tạo bổ sung cho tenant đang hoạt động
    Biết có bước hoặc phân hệ mà một số tenant `ACTIVE` chưa có (so phiên bản sổ bước của lần chạy gần nhất với sổ bước hiện hành)
    Khi UI-20-04 (theo tenant) hoặc nút "Khởi tạo bổ sung hàng loạt" ở UI-20-20
    Thì hệ thống trả `200` cho xem trước (`candidates[]`, `excluded[]` kèm lý do); `202` khi tạo đợt (`planId`, `runIds[]`)
    Và mỗi tenant có lần chạy `SUPPLEMENT` mới, `SUCCEEDED` hoặc `FAILED`
    Và sự kiện được phát: EVT-20-07 cho phân hệ được bổ sung
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-016 @FR-20-016 @S @âm
  Kịch bản: US-20-016 âm 1 · Không tenant nào cần bổ sung
    Biết có bước hoặc phân hệ mà một số tenant `ACTIVE` chưa có (so phiên bản sổ bước của lần chạy gần nhất với sổ bước hiện hành)
    Khi không tenant nào cần bổ sung
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-017 @FR-20-017 @S
  Kịch bản: US-20-017 dương · Khởi tạo tenant chế độ DEDICATED_CLUSTER
    Biết cụm đích có Argo CD, CloudNativePG, Kafka, Ceph hoặc kho S3 tương đương, Keycloak, OpenBao theo D03-09; có kết nối mạng một chiều từ cụm tỉnh tới kho Git phát hành
    Khi "+ Đăng ký cụm" ở UI-20-21 tab Cụm; chọn cụm ở bước 2 của UI-20-02; "Sinh gói cấu hình" ở UI-20-03
    Thì hệ thống trả `201` khi đăng ký cụm; `200` kết quả kiểm; `202` khi sinh gói (`bundleId`, liên kết tải có hạn 24 giờ, `sha256`)
    Và cụm `VERIFIED`; tenant như FR-20-008
    Và sự kiện được phát: Như FR-20-008
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-017 @FR-20-017 @S @âm
  Kịch bản: US-20-017 âm 1 · Cụm không đạt
    Biết cụm đích có Argo CD, CloudNativePG, Kafka, Ceph hoặc kho S3 tương đương, Keycloak, OpenBao theo D03-09; có kết nối mạng một chiều từ cụm tỉnh tới kho Git phát hành
    Khi cụm không đạt
    Thì hệ thống từ chối với ERR-20-064 (422)
    Và người dùng thấy thông báo "Cụm {mã} chưa đạt yêu cầu: {danh sách thiếu}."

  # ---- EP-20-C · Cấu hình

  @US-20-018 @FR-20-018 @M
  Kịch bản: US-20-018 dương · Cài đặt tỉnh do quản trị tỉnh tự quản
    Biết tenant `ACTIVE` (`SUSPENDED`, `MERGED` chỉ đọc)
    Khi mở UI-20-12, sửa, bấm "Lưu"
    Thì hệ thống trả `200`; cài đặt mới, `ETag`, `configVersionNo`
    Và EN-20-06 cập nhật; có phiên bản cấu hình mới
    Và sự kiện được phát: EVT-20-09 (`changeKind = TENANT_SETTINGS`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-018 @FR-20-018 @M @âm
  Kịch bản: US-20-018 âm 1 · Vượt giới hạn nền tảng
    Biết tenant `ACTIVE` (`SUSPENDED`, `MERGED` chỉ đọc)
    Khi vượt giới hạn nền tảng
    Thì hệ thống từ chối với ERR-20-023 (422)
    Và người dùng thấy thông báo "{Thiết lập} vượt giới hạn của nền tảng ({giới hạn})."

  @US-20-018 @FR-20-018 @M @âm
  Kịch bản: US-20-018 âm 2 · Tenant tạm ngừng hoặc đã sáp nhập
    Biết tenant `ACTIVE` (`SUSPENDED`, `MERGED` chỉ đọc)
    Khi tenant tạm ngừng hoặc đã sáp nhập
    Thì hệ thống từ chối với ERR-20-001, ERR-20-115 (403)
    Và người dùng thấy thông báo "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."

  @US-20-019 @FR-20-019 @M
  Kịch bản: US-20-019 dương · Cấu hình nền tảng của tenant
    Biết tenant không `DECOMMISSIONED`
    Khi UI-20-03 tab "Cấu hình nền tảng", "Sửa"
    Thì hệ thống trả `200`; cấu hình mới, `ETag`, `configVersionNo`, `syncStatus`
    Và EN-20-05 cập nhật
    Và sự kiện được phát: EVT-20-09 (`changeKind = PLATFORM_CONFIG`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-019 @FR-20-019 @M @âm
  Kịch bản: US-20-019 âm 1 · Host, tiền tố trùng
    Biết tenant không `DECOMMISSIONED`
    Khi host, tiền tố trùng
    Thì hệ thống từ chối với ERR-20-067 (409)
    Và người dùng thấy thông báo "Tên miền hoặc tiền tố {giá trị} đã được tenant khác dùng."

  @US-20-019 @FR-20-019 @M @âm
  Kịch bản: US-20-019 âm 2 · Đổi realm
    Biết tenant không `DECOMMISSIONED`
    Khi đổi realm
    Thì hệ thống từ chối với ERR-20-068 (422)
    Và người dùng thấy thông báo "Không đổi được {thuộc tính} của tenant sau khi khai báo."

  @US-20-020 @FR-20-020 @M
  Kịch bản: US-20-020 dương · Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống
    Biết kho `dh-tenant-config` truy cập được; khóa ký ở OpenBao
    Khi một FR ghi cấu hình gọi `ConfigWriter.apply(tenant, files, reason)` trong cùng giao dịch nghiệp vụ (qua outbox)
    Thì nội bộ; trạng thái hiện trong API-20-039 (`configVersionNo`, `commitSha`, `syncStatus`, `appliedAt`)
    Và EN-20-07 có bản ghi mới
    Và sự kiện được phát: EVT-20-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-020 @FR-20-020 @M @âm
  Kịch bản: US-20-020 âm 1 · Không đẩy được lên Git
    Biết kho `dh-tenant-config` truy cập được; khóa ký ở OpenBao
    Khi không đẩy được lên Git
    Thì hệ thống từ chối với ERR-20-024 (502)
    Và người dùng thấy thông báo "Không ghi được cấu hình vào kho GitOps. Thử lại sau, nếu lặp lại báo vận hành nền tảng."

  @US-20-020 @FR-20-020 @M @âm
  Kịch bản: US-20-020 âm 2 · Cấu hình đang lệch chưa đối chiếu
    Biết kho `dh-tenant-config` truy cập được; khóa ký ở OpenBao
    Khi cấu hình đang lệch chưa đối chiếu
    Thì hệ thống từ chối với ERR-20-025 (409)
    Và người dùng thấy thông báo "Cấu hình tenant {mã} đang lệch chưa xử lý. Đối chiếu trước khi sửa."

  @US-20-021 @FR-20-021 @S
  Kịch bản: US-20-021 dương · Lịch sử, so sánh, khôi phục phiên bản cấu hình
    Biết tenant có từ hai phiên bản cấu hình
    Khi UI-20-17 tab "Phiên bản": chọn hai phiên bản, "So sánh"; "Khôi phục phiên bản này"
    Thì hệ thống trả `200` danh sách, khác biệt; `202` khi khôi phục (`configVersionNo` mới)
    Và khôi phục tạo phiên bản mới có `restoredFrom`
    Và sự kiện được phát: EVT-20-09 khi khôi phục
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-021 @FR-20-021 @S @âm
  Kịch bản: US-20-021 âm 1 · Không khôi phục được
    Biết tenant có từ hai phiên bản cấu hình
    Khi không khôi phục được
    Thì hệ thống từ chối với ERR-20-026 (422)
    Và người dùng thấy thông báo "Không khôi phục được phiên bản cấu hình {n}: {lý do}."

  @US-20-022 @FR-20-022 @S
  Kịch bản: US-20-022 dương · Phát hiện lệch cấu hình và đối chiếu định kỳ
    Biết tenant `ACTIVE`, `SUSPENDED` hoặc `MERGING`
    Khi mỗi `20.drift.check-interval` (PT1H); PA bấm "Đối chiếu ngay" ở UI-20-17
    Thì hệ thống trả `200` danh sách lệch; `202` khi đối chiếu ngay, xử lý
    Và EN-20-08 cập nhật; Git và thực tế khớp sau xử lý
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-022 @FR-20-022 @S @âm
  Kịch bản: US-20-022 âm 1 · `ACCEPT` với khóa an ninh
    Biết tenant `ACTIVE`, `SUSPENDED` hoặc `MERGING`
    Khi `ACCEPT` với khóa an ninh
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-023 @FR-20-023 @M
  Kịch bản: US-20-023 dương · Chính sách tiếp nhận truy cập liên tenant của tỉnh
    Biết tenant `ACTIVE`; chính sách mặc định tạo ở `S01_RECORD` (`allowRead = true`, `allowWrite = false`, `requirePriorApproval = false`, `maxHours = 4`, báo `TENANT_ADMIN`, `SECURITY`)
    Khi UI-20-22 tab "Chính sách", "Sửa", "Lưu"
    Thì hệ thống trả `200`; chính sách, `ETag`
    Và EN-20-29 cập nhật
    Và sự kiện được phát: EVT-20-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-023 @FR-20-023 @M @âm
  Kịch bản: US-20-023 âm 1 · Vượt trần
    Biết tenant `ACTIVE`; chính sách mặc định tạo ở `S01_RECORD` (`allowRead = true`, `allowWrite = false`, `requirePriorApproval = false`, `maxHours = 4`, báo `TENANT_ADMIN`, `SECURITY`)
    Khi vượt trần
    Thì hệ thống từ chối với ERR-20-027 (422)
    Và người dùng thấy thông báo "Thời hạn truy cập liên tenant tối đa là {giờ} giờ."

  @US-20-023 @FR-20-023 @M @âm
  Kịch bản: US-20-023 âm 2 · Người nhận không hợp lệ
    Biết tenant `ACTIVE`; chính sách mặc định tạo ở `S01_RECORD` (`allowRead = true`, `allowWrite = false`, `requirePriorApproval = false`, `maxHours = 4`, báo `TENANT_ADMIN`, `SECURITY`)
    Khi người nhận không hợp lệ
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-024 @FR-20-024 @S
  Kịch bản: US-20-024 dương · Xem nhật ký truy cập liên tenant vào tỉnh
    Biết có phiên liên tenant đã ghi ở PH-12 và kiểm toán ở PH-13
    Khi UI-20-22 tab "Nhật ký"
    Thì hệ thống trả `200`; `items[]`, `page`, `totalElements`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-024 @FR-20-024 @S @âm
  Kịch bản: US-20-024 âm 1 · Khoảng thời gian vượt tối đa
    Biết có phiên liên tenant đã ghi ở PH-12 và kiểm toán ở PH-13
    Khi khoảng thời gian vượt tối đa
    Thì hệ thống từ chối với ERR-20-032 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa là {số} ngày."

  @US-20-025 @FR-20-025 @S
  Kịch bản: US-20-025 dương · Chuyển chế độ cách ly của tenant
    Biết tenant `ACTIVE`; không có kế hoạch sáp nhập, nâng cấp đang chạy
    Khi UI-20-03 tab "Cấu hình nền tảng", "Đổi chế độ cách ly"
    Thì hệ thống trả `201` đề nghị; `202` khi thực hiện (`runId`)
    Và `isolation_mode` mới; cấu hình nền tảng phiên bản mới
    Và sự kiện được phát: EVT-20-09 (`changeKind = ISOLATION_MODE`); EVT-20-04 khi chuyển chỉ đọc và trở lại
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-025 @FR-20-025 @S @âm
  Kịch bản: US-20-025 âm 1 · Chuyển không hợp lệ
    Biết tenant `ACTIVE`; không có kế hoạch sáp nhập, nâng cấp đang chạy
    Khi chuyển không hợp lệ
    Thì hệ thống từ chối với ERR-20-028 (422)
    Và người dùng thấy thông báo "Không chuyển được từ chế độ {từ} sang {tới}: {lý do}."

  # ---- EP-20-D · Hạn mức, sử dụng

  @US-20-026 @FR-20-026 @M
  Kịch bản: US-20-026 dương · Đặt hạn mức hợp đồng của tenant
    Biết tenant không `DECOMMISSIONED`; hạn mức mặc định đã có từ mẫu ở `S01_RECORD`
    Khi UI-20-05 "Sửa hạn mức"
    Thì hệ thống trả `200`; `items[]` (`resource`, `contractValue`, `platformCeiling`, `overrideValue`, `effectiveValue`, `lastUsage`), `ETag`
    Và EN-20-13 cập nhật
    Và sự kiện được phát: EVT-20-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-026 @FR-20-026 @M @âm
  Kịch bản: US-20-026 âm 1 · Ngoài miền, vượt trần
    Biết tenant không `DECOMMISSIONED`; hạn mức mặc định đã có từ mẫu ở `S01_RECORD`
    Khi ngoài miền, vượt trần
    Thì hệ thống từ chối với ERR-20-029 (422)
    Và người dùng thấy thông báo "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."

  @US-20-026 @FR-20-026 @M @âm
  Kịch bản: US-20-026 âm 2 · Hạ dưới mức đang dùng
    Biết tenant không `DECOMMISSIONED`; hạn mức mặc định đã có từ mẫu ở `S01_RECORD`
    Khi hạ dưới mức đang dùng
    Thì hệ thống từ chối với ERR-20-030 (422)
    Và người dùng thấy thông báo "Hạ hạn mức {tài nguyên} xuống {giá trị} thấp hơn mức đang dùng {dùng} cần được duyệt."

  @US-20-027 @FR-20-027 @M
  Kịch bản: US-20-027 dương · Đổi hạn mức có duyệt và đẩy xuống nơi thực thi
    Biết tenant `ACTIVE` hoặc `SUSPENDED`
    Khi UI-20-05 "Đề nghị đổi hạn mức"; PA khác duyệt ở UI-20-05 của chính tenant; hộp duyệt toàn nền tảng ở UI-20-08 chỉ gồm đề nghị vòng đời (API-20-073), không gồm đề nghị đổi hạn mức
    Thì hệ thống trả `201` đề nghị; `200` khi duyệt, từ chối; `appliedTargets[]` (nơi, thời điểm xác nhận)
    Và EN-20-14 `DONE` hoặc `REJECTED`; EN-20-13 cập nhật
    Và sự kiện được phát: EVT-20-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-027 @FR-20-027 @M @âm
  Kịch bản: US-20-027 âm 1 · Tự duyệt
    Biết tenant `ACTIVE` hoặc `SUSPENDED`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-20-007 (403)
    Và người dùng thấy thông báo "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."

  @US-20-027 @FR-20-027 @M @âm
  Kịch bản: US-20-027 âm 2 · Giá trị ngoài miền
    Biết tenant `ACTIVE` hoặc `SUSPENDED`
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-20-029 (422)
    Và người dùng thấy thông báo "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."

  @US-20-028 @FR-20-028 @M
  Kịch bản: US-20-028 dương · Thu thập sử dụng tài nguyên theo tenant
    Biết Mimir có chỉ số gắn nhãn `tenant`; API thống kê của PH-01, PH-02, PH-04, PH-10, PH-12 sẵn sàng; RGW admin API
    Khi mỗi `20.usage.snapshot-interval` (PT1H), phút thứ 5 của giờ
    Thì nội bộ; chỉ số `dh_tenant_usage_ratio{tenant,resource}`
    Và EN-20-16 có dòng mới; dữ liệu giữ `20.usage.retention-months` tháng, phân vùng cũ được xóa theo tháng

  @US-20-028 @FR-20-028 @M @âm
  Kịch bản: US-20-028 âm 1 · Nguồn thiếu quá 3 giờ liên tiếp (runtime)
    Biết Mimir có chỉ số gắn nhãn `tenant`; API thống kê của PH-01, PH-02, PH-04, PH-10, PH-12 sẵn sàng; RGW admin API
    Khi nguồn thiếu quá 3 giờ liên tiếp (runtime)
    Thì hệ thống từ chối với ERR-20-110
    Và người dùng thấy thông báo "Thiếu số liệu sử dụng {tài nguyên} của {tenant} từ {giờ}."

  @US-20-028 @FR-20-028 @M @âm
  Kịch bản: US-20-028 âm 2 · Mimir không khả dụng
    Biết Mimir có chỉ số gắn nhãn `tenant`; API thống kê của PH-01, PH-02, PH-04, PH-10, PH-12 sẵn sàng; RGW admin API
    Khi Mimir không khả dụng
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-029 @FR-20-029 @M
  Kịch bản: US-20-029 dương · Cảnh báo ngưỡng hạn mức 80% và 100%
    Biết có ảnh chụp mới (FR-20-028)
    Khi FR-20-028 bước 4; EVT-13-14 `{tenant}.obs.capacity.warning.v1` từ PH-13
    Thì API-20-058 `200` danh sách; API-20-059 `200`
    Và EN-20-17 cập nhật
    Và sự kiện được phát: EVT-20-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-029 @FR-20-029 @M @âm
  Kịch bản: US-20-029 âm 1 · Xác nhận cảnh báo đã `RESOLVED`
    Biết có ảnh chụp mới (FR-20-028)
    Khi xác nhận cảnh báo đã `RESOLVED`
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-029 @FR-20-029 @M @âm
  Kịch bản: US-20-029 âm 2 · Không có cảnh báo
    Biết có ảnh chụp mới (FR-20-028)
    Khi không có cảnh báo
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-030 @FR-20-030 @M
  Kịch bản: US-20-030 dương · Xem sử dụng tài nguyên của tỉnh và toàn nền tảng
    Biết có ảnh chụp
    Khi mở UI-20-06 (nền tảng) hoặc UI-20-13 (tỉnh), chọn khoảng
    Thì hệ thống trả `200`; `series[]` (`resource`, `points[]` {`t`, `value`, `peak`, `limit`, `percent`, `quality`}), `ranking[]` (nền tảng)

  @US-20-030 @FR-20-030 @M @âm
  Kịch bản: US-20-030 âm 1 · Khoảng vượt tối đa
    Biết có ảnh chụp
    Khi khoảng vượt tối đa
    Thì hệ thống từ chối với ERR-20-032 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa là {số} ngày."

  @US-20-030 @FR-20-030 @M @âm
  Kịch bản: US-20-030 âm 2 · Tham số sai
    Biết có ảnh chụp
    Khi tham số sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-031 @FR-20-031 @S
  Kịch bản: US-20-031 dương · Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp
    Biết kỳ đã kết thúc
    Khi UI-20-06 "Lập báo cáo"; lịch tự lập ngày 2 hằng tháng cho kỳ tháng trước
    Thì hệ thống trả `202` (`reportId`); API-20-062 trả tệp
    Và EN-20-37 `READY`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-031 @FR-20-031 @S @âm
  Kịch bản: US-20-031 âm 1 · Kỳ chưa kết thúc hoặc định dạng sai
    Biết kỳ đã kết thúc
    Khi kỳ chưa kết thúc hoặc định dạng sai
    Thì hệ thống từ chối với ERR-20-066 (422)
    Và người dùng thấy thông báo "Không lập được báo cáo sử dụng: {lý do}."

  @US-20-032 @FR-20-032 @S
  Kịch bản: US-20-032 dương · Ghi đè hạn mức tạm thời có thời hạn
    Biết tenant `ACTIVE`
    Khi UI-20-05 "Ghi đè tạm thời"; "Thu hồi"
    Thì hệ thống trả `201`; ghi đè (`overrideId`, `status`, `effectiveValue`)
    Và EN-20-15 cập nhật
    Và sự kiện được phát: EVT-20-05 (bắt đầu, kết thúc)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-032 @FR-20-032 @S @âm
  Kịch bản: US-20-032 âm 1 · Quá số ngày
    Biết tenant `ACTIVE`
    Khi quá số ngày
    Thì hệ thống từ chối với ERR-20-031 (422)
    Và người dùng thấy thông báo "Ghi đè hạn mức tối đa {số} ngày."

  # ---- EP-20-E · Phân hệ, tính năng

  @US-20-033 @FR-20-033 @M
  Kịch bản: US-20-033 dương · Danh mục phân hệ của nền tảng và ma trận phụ thuộc
    Biết danh mục được nạp bằng migration nền và cập nhật theo phiên bản sản phẩm (FR-20-059)
    Khi UI-20-07 tab "Danh mục phân hệ"
    Thì hệ thống trả `200`; `items[]` (`moduleCode`, `name`, `core`, `wave`, `asyncProvision`, `mergeParticipant`, `exportParticipant`, `dependsOn[]`, `featureFlags[]`, `tenantCounts`)

  @US-20-033 @FR-20-033 @M @âm
  Kịch bản: US-20-033 âm 1 · Tham số sai
    Biết danh mục được nạp bằng migration nền và cập nhật theo phiên bản sản phẩm (FR-20-059)
    Khi tham số sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-033 @FR-20-033 @M @âm
  Kịch bản: US-20-033 âm 2 · Danh mục chưa nạp (lỗi triển khai)
    Biết danh mục được nạp bằng migration nền và cập nhật theo phiên bản sản phẩm (FR-20-059)
    Khi danh mục chưa nạp (lỗi triển khai)
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-034 @FR-20-034 @M
  Kịch bản: US-20-034 dương · Bật phân hệ cho tenant
    Biết tenant `ACTIVE`; phân hệ có trong bản đang chạy của tenant; phân hệ ở `DISABLED` hoặc `FAILED`
    Khi UI-20-07 tab "Phân hệ của tenant", "Bật"
    Thì hệ thống trả `202`; `moduleCode`, `state = ENABLING`, `runId`
    Và EN-20-20 cập nhật
    Và sự kiện được phát: EVT-20-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-034 @FR-20-034 @M @âm
  Kịch bản: US-20-034 âm 1 · Thiếu phụ thuộc
    Biết tenant `ACTIVE`; phân hệ có trong bản đang chạy của tenant; phân hệ ở `DISABLED` hoặc `FAILED`
    Khi thiếu phụ thuộc
    Thì hệ thống từ chối với ERR-20-033 (422)
    Và người dùng thấy thông báo "Phân hệ {phân hệ} cần {phụ thuộc} được bật trước."

  @US-20-034 @FR-20-034 @M @âm
  Kịch bản: US-20-034 âm 2 · Phiên bản đang chạy chưa có phân hệ
    Biết tenant `ACTIVE`; phân hệ có trong bản đang chạy của tenant; phân hệ ở `DISABLED` hoặc `FAILED`
    Khi phiên bản đang chạy chưa có phân hệ
    Thì hệ thống từ chối với ERR-20-055 (422)
    Và người dùng thấy thông báo "Phiên bản {phiên bản} không dùng được cho thao tác này: {lý do}."

  @US-20-035 @FR-20-035 @M
  Kịch bản: US-20-035 dương · Tắt, tạm ngừng phân hệ cho tenant
    Biết phân hệ `ENABLED` (tạm ngừng, tắt) hoặc `SUSPENDED` (tiếp tục, tắt); không phải phân hệ lõi
    Khi UI-20-07 "Tạm ngừng", "Tiếp tục", "Tắt" (hộp `CMP-ConfirmDialog` nêu hệ quả)
    Thì hệ thống trả `202`; phân hệ với trạng thái mới
    Và EN-20-20 cập nhật
    Và sự kiện được phát: EVT-20-08; EVT-20-07 khi tiếp tục
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-035 @FR-20-035 @M @âm
  Kịch bản: US-20-035 âm 1 · Phân hệ lõi
    Biết phân hệ `ENABLED` (tạm ngừng, tắt) hoặc `SUSPENDED` (tiếp tục, tắt); không phải phân hệ lõi
    Khi phân hệ lõi
    Thì hệ thống từ chối với ERR-20-035 (403)
    Và người dùng thấy thông báo "Phân hệ {phân hệ} là phân hệ lõi, không tắt được."

  @US-20-035 @FR-20-035 @M @âm
  Kịch bản: US-20-035 âm 2 · Đang bị phụ thuộc
    Biết phân hệ `ENABLED` (tạm ngừng, tắt) hoặc `SUSPENDED` (tiếp tục, tắt); không phải phân hệ lõi
    Khi đang bị phụ thuộc
    Thì hệ thống từ chối với ERR-20-034 (409)
    Và người dùng thấy thông báo "Phân hệ {phân hệ} đang được {danh sách} dùng. Tắt các phân hệ đó trước."

  @US-20-036 @FR-20-036 @S
  Kịch bản: US-20-036 dương · Cờ tính năng theo tenant
    Biết cờ có trong danh mục cờ của phân hệ (EN-20-18 `featureFlags[]`); phân hệ `ENABLED`
    Khi UI-20-07 tab "Cờ tính năng", công tắc
    Thì hệ thống trả `200`; cờ, `ETag`
    Và EN-20-21 cập nhật
    Và sự kiện được phát: EVT-20-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-036 @FR-20-036 @S @âm
  Kịch bản: US-20-036 âm 1 · Cờ không hợp lệ
    Biết cờ có trong danh mục cờ của phân hệ (EN-20-18 `featureFlags[]`); phân hệ `ENABLED`
    Khi cờ không hợp lệ
    Thì hệ thống từ chối với ERR-20-036 (422)
    Và người dùng thấy thông báo "Cờ {cờ} không áp dụng được: {lý do}."

  @US-20-037 @FR-20-037 @M
  Kịch bản: US-20-037 dương · Cung cấp trạng thái phân hệ cho menu và giao diện
    Biết người dùng có token của realm tỉnh
    Khi `dh-console` tải sau đăng nhập và mỗi 5 phút; khi nhận thông báo đẩy có `EVT-20-04`, `EVT-20-07`, `EVT-20-08`
    Thì hệ thống trả `200`; `tenantCode`, `status`, `readOnly`, `modules[]` (`moduleCode`, `state`), `featureFlags`, `banner` {`type`, `message`, `until`, `link`}, `currentVersion`

  @US-20-037 @FR-20-037 @M @âm
  Kịch bản: US-20-037 âm 1 · Token không có tenant hợp lệ
    Biết người dùng có token của realm tỉnh
    Khi token không có tenant hợp lệ
    Thì hệ thống từ chối với ERR-00-401 (401)
    Và người dùng thấy thông báo "Phiên đăng nhập đã hết hạn. Đăng nhập lại."

  @US-20-037 @FR-20-037 @M @âm
  Kịch bản: US-20-037 âm 2 · Tenant `DECOMMISSIONED`
    Biết người dùng có token của realm tỉnh
    Khi tenant `DECOMMISSIONED`
    Thì hệ thống từ chối với ERR-20-102 (410)
    Và người dùng thấy thông báo "Tỉnh đã chấm dứt sử dụng Datahub."

  # ---- EP-20-F · Vòng đời

  @US-20-038 @FR-20-038 @M
  Kịch bản: US-20-038 dương · Tạm ngừng tenant
    Biết tenant `ACTIVE`; không có kế hoạch sáp nhập ở `TRANSFERRING` trở đi
    Khi UI-20-08 "Tạm ngừng"
    Thì hệ thống trả `202`; `requestId`, tenant `SUSPENDED` khi xong
    Và tenant `SUSPENDED`; EN-20-22 `DONE`
    Và sự kiện được phát: EVT-20-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-038 @FR-20-038 @M @âm
  Kịch bản: US-20-038 âm 1 · Trạng thái không phù hợp
    Biết tenant `ACTIVE`; không có kế hoạch sáp nhập ở `TRANSFERRING` trở đi
    Khi trạng thái không phù hợp
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-038 @FR-20-038 @M @âm
  Kịch bản: US-20-038 âm 2 · Thiếu lý do, phiếu
    Biết tenant `ACTIVE`; không có kế hoạch sáp nhập ở `TRANSFERRING` trở đi
    Khi thiếu lý do, phiếu
    Thì hệ thống từ chối với ERR-20-008 (422)
    Và người dùng thấy thông báo "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."

  @US-20-039 @FR-20-039 @M
  Kịch bản: US-20-039 dương · Khôi phục tenant
    Biết tenant `SUSPENDED`; không có đề nghị `TERMINATE` ở `APPROVED`
    Khi UI-20-08 "Khôi phục"
    Thì hệ thống trả `202`; `requestId`
    Và tenant `ACTIVE`
    Và sự kiện được phát: EVT-20-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-039 @FR-20-039 @M @âm
  Kịch bản: US-20-039 âm 1 · Trạng thái không phù hợp
    Biết tenant `SUSPENDED`; không có đề nghị `TERMINATE` ở `APPROVED`
    Khi trạng thái không phù hợp
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-039 @FR-20-039 @M @âm
  Kịch bản: US-20-039 âm 2 · Đang có đề nghị chấm dứt đã duyệt
    Biết tenant `SUSPENDED`; không có đề nghị `TERMINATE` ở `APPROVED`
    Khi đang có đề nghị chấm dứt đã duyệt
    Thì hệ thống từ chối với ERR-20-037 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."

  @US-20-040 @FR-20-040 @M
  Kịch bản: US-20-040 dương · Đề nghị và duyệt chấm dứt tenant
    Biết tenant `SUSPENDED` (BR-20-019)
    Khi UI-20-08 "Đề nghị chấm dứt"; hộp duyệt UI-20-08 tab "Chờ duyệt"
    Thì hệ thống trả `201` đề nghị; `200` khi gửi, duyệt, từ chối, rút
    Và EN-20-22 `APPROVED` hoặc `REJECTED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-040 @FR-20-040 @M @âm
  Kịch bản: US-20-040 âm 1 · Tenant chưa tạm ngừng
    Biết tenant `SUSPENDED` (BR-20-019)
    Khi tenant chưa tạm ngừng
    Thì hệ thống từ chối với ERR-20-037 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."

  @US-20-040 @FR-20-040 @M @âm
  Kịch bản: US-20-040 âm 2 · Tự duyệt
    Biết tenant `SUSPENDED` (BR-20-019)
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-20-007 (403)
    Và người dùng thấy thông báo "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."

  @US-20-041 @FR-20-041 @M
  Kịch bản: US-20-041 dương · Xuất gói bàn giao dữ liệu tenant
    Biết tenant `SUSPENDED` hoặc `MERGED`; đề nghị `TERMINATE` `APPROVED` hoặc PA yêu cầu chủ động
    Khi UI-20-08 "Xuất gói bàn giao"; tự động sau FR-20-040 bước 4
    Thì hệ thống trả `202` khi yêu cầu; `200` chi tiết gói (`status`, `items[]` theo phân hệ, `manifestSha256`, `downloadUrl` khi cấp)
    Và EN-20-24 `DELIVERED`
    Và sự kiện được phát: EVT-20-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-041 @FR-20-041 @M @âm
  Kịch bản: US-20-041 âm 1 · Liên kết sau khi gói hết hạn
    Biết tenant `SUSPENDED` hoặc `MERGED`; đề nghị `TERMINATE` `APPROVED` hoặc PA yêu cầu chủ động
    Khi liên kết sau khi gói hết hạn
    Thì hệ thống từ chối với ERR-20-039 (410)
    Và người dùng thấy thông báo "Gói bàn giao {mã} đã hết hạn lưu. Lập gói mới."

  @US-20-041 @FR-20-041 @M @âm
  Kịch bản: US-20-041 âm 2 · Phân hệ báo lỗi hoặc quá 24 giờ (runtime)
    Biết tenant `SUSPENDED` hoặc `MERGED`; đề nghị `TERMINATE` `APPROVED` hoặc PA yêu cầu chủ động
    Khi phân hệ báo lỗi hoặc quá 24 giờ (runtime)
    Thì hệ thống từ chối với ERR-20-107

  @US-20-042 @FR-20-042 @M
  Kịch bản: US-20-042 dương · Thực hiện chấm dứt tenant
    Biết đề nghị `TERMINATE` `APPROVED`; gói bàn giao `DELIVERED` hoặc `exportRequired = false` có văn bản; đã hết thời gian nguội; tenant `SUSPENDED`
    Khi UI-20-08 "Thực hiện chấm dứt" (gõ lại mã tenant); hoặc tự động tại `plannedAt`
    Thì hệ thống trả `202`; `requestId`, tiến độ theo bước
    Và tenant `DECOMMISSIONED`
    Và sự kiện được phát: EVT-20-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-042 @FR-20-042 @M @âm
  Kịch bản: US-20-042 âm 1 · Chưa đủ điều kiện
    Biết đề nghị `TERMINATE` `APPROVED`; gói bàn giao `DELIVERED` hoặc `exportRequired = false` có văn bản; đã hết thời gian nguội; tenant `SUSPENDED`
    Khi chưa đủ điều kiện
    Thì hệ thống từ chối với ERR-20-037 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."

  @US-20-042 @FR-20-042 @M @âm
  Kịch bản: US-20-042 âm 2 · Chưa hết thời gian nguội
    Biết đề nghị `TERMINATE` `APPROVED`; gói bàn giao `DELIVERED` hoặc `exportRequired = false` có văn bản; đã hết thời gian nguội; tenant `SUSPENDED`
    Khi chưa hết thời gian nguội
    Thì hệ thống từ chối với ERR-20-038 (422)
    Và người dùng thấy thông báo "Chưa hết thời gian chờ {số} ngày kể từ khi tạm ngừng (đến {ngày})."

  @US-20-043 @FR-20-043 @M
  Kịch bản: US-20-043 dương · Lịch sử vòng đời và quyết định
    Biết tenant tồn tại
    Khi UI-20-03 tab "Lịch sử vòng đời"
    Thì hệ thống trả `200`; `items[]` (`from`, `to`, `at`, `cause` {`type`, `id`}, `actor`, `decisionDocNo`)

  @US-20-043 @FR-20-043 @M @âm
  Kịch bản: US-20-043 âm 1 · Không có tenant
    Biết tenant tồn tại
    Khi không có tenant
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-043 @FR-20-043 @M @âm
  Kịch bản: US-20-043 âm 2 · Tham số sai
    Biết tenant tồn tại
    Khi tham số sai
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-044 @FR-20-044 @M
  Kịch bản: US-20-044 dương · Thông báo thay đổi trạng thái tenant
    Biết có đầu mối đang hoạt động
    Khi ghi EN-20-23 mới (mọi chuyển trạng thái); hẹn giờ tạm ngừng, chấm dứt, cutover còn 7 ngày và 1 ngày
    Thì nội bộ; trạng thái gửi ở API-20-085
    Và lịch sử có kết quả gửi

  @US-20-044 @FR-20-044 @M @âm
  Kịch bản: US-20-044 âm 1 · PH-18 không khả dụng
    Biết có đầu mối đang hoạt động
    Khi PH-18 không khả dụng
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-044 @FR-20-044 @M @âm
  Kịch bản: US-20-044 âm 2 · Không còn đầu mối hoạt động
    Biết có đầu mối đang hoạt động
    Khi không còn đầu mối hoạt động
    Thì hệ thống từ chối với ERR-20-021 (422)
    Và người dùng thấy thông báo "Cần đủ đầu mối {vai trò} trước khi {thao tác}."

  # ---- EP-20-G · Sáp nhập

  @US-20-045 @FR-20-045 @M
  Kịch bản: US-20-045 dương · Lập kế hoạch sáp nhập
    Biết tenant nguồn và đích `ACTIVE`, không thuộc kế hoạch khác chưa kết thúc; tenant đích có thể vừa khởi tạo (FR-20-008)
    Khi UI-20-11 "+ Kế hoạch sáp nhập", wizard UI-20-09 (nguồn đích, căn cứ, ánh xạ, chạy thử, gửi duyệt); PA khác duyệt ở UI-20-09
    Thì hệ thống trả `201`; kế hoạch (`mergePlanId`, `status`, `ETag`); `200` cho các hành động
    Và EN-20-25 `APPROVED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-045 @FR-20-045 @M @âm
  Kịch bản: US-20-045 âm 1 · Kế hoạch không hợp lệ
    Biết tenant nguồn và đích `ACTIVE`, không thuộc kế hoạch khác chưa kết thúc; tenant đích có thể vừa khởi tạo (FR-20-008)
    Khi kế hoạch không hợp lệ
    Thì hệ thống từ chối với ERR-20-040 (422)
    Và người dùng thấy thông báo "Kế hoạch sáp nhập không hợp lệ: {lý do}."

  @US-20-045 @FR-20-045 @M @âm
  Kịch bản: US-20-045 âm 2 · Tenant thuộc kế hoạch khác
    Biết tenant nguồn và đích `ACTIVE`, không thuộc kế hoạch khác chưa kết thúc; tenant đích có thể vừa khởi tạo (FR-20-008)
    Khi tenant thuộc kế hoạch khác
    Thì hệ thống từ chối với ERR-20-041 (409)
    Và người dùng thấy thông báo "Tenant {mã} đang thuộc kế hoạch sáp nhập {kế hoạch}."

  @US-20-046 @FR-20-046 @M
  Kịch bản: US-20-046 dương · Lập bảng ánh xạ sáp nhập
    Biết kế hoạch `DRAFT`
    Khi bước "Ánh xạ" của UI-20-09: "Gợi ý tự động", sửa từng dòng
    Thì hệ thống trả `200`; `items[]` (`mappingId`, `mappingType`, `sourceCode`, `targetCode`, `action`, `origin`, `required`), `summary` theo loại
    Và EN-20-26 cập nhật; chạy thử cũ bị đánh dấu cũ khi ánh xạ đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-046 @FR-20-046 @M @âm
  Kịch bản: US-20-046 âm 1 · Còn dòng bắt buộc chưa quyết
    Biết kế hoạch `DRAFT`
    Khi còn dòng bắt buộc chưa quyết
    Thì hệ thống từ chối với ERR-20-042 (422)
    Và người dùng thấy thông báo "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định."

  @US-20-046 @FR-20-046 @M @âm
  Kịch bản: US-20-046 âm 2 · Mã đích trùng
    Biết kế hoạch `DRAFT`
    Khi mã đích trùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-047 @FR-20-047 @M
  Kịch bản: US-20-047 dương · Chạy thử sáp nhập
    Biết kế hoạch `DRAFT`; không còn dòng ánh xạ bắt buộc chưa quyết
    Khi UI-20-09 bước "Chạy thử", UI-20-10 "Chạy thử lại"
    Thì hệ thống trả `202`; kết quả trong API-20-088 (`dryRun` {`result`, `modules[]` {`module`, `records`, `conflicts`, `estimatedMinutes`}, `mappingHash`})
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-047 @FR-20-047 @M @âm
  Kịch bản: US-20-047 âm 1 · Ánh xạ chưa đủ
    Biết kế hoạch `DRAFT`; không còn dòng ánh xạ bắt buộc chưa quyết
    Khi ánh xạ chưa đủ
    Thì hệ thống từ chối với ERR-20-042 (422)
    Và người dùng thấy thông báo "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định."

  @US-20-047 @FR-20-047 @M @âm
  Kịch bản: US-20-047 âm 2 · Đang chạy thử
    Biết kế hoạch `DRAFT`; không còn dòng ánh xạ bắt buộc chưa quyết
    Khi đang chạy thử
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-048 @FR-20-048 @M
  Kịch bản: US-20-048 dương · Điều phối chuyển dữ liệu theo phân hệ
    Biết kế hoạch `APPROVED`; đã tới `effectiveDate` hoặc PA chọn chạy sớm có lý do
    Khi UI-20-10 "Bắt đầu chuyển"
    Thì hệ thống trả `202`; kế hoạch `TRANSFERRING`; API-20-099 trả tiến độ theo phân hệ
    Và dữ liệu ở đích có `origin_tenant_id`; nguồn vẫn đầy đủ
    Và sự kiện được phát: EVT-20-10; EVT-20-04 (`MERGING`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-048 @FR-20-048 @M @âm
  Kịch bản: US-20-048 âm 1 · Chạy thử cũ
    Biết kế hoạch `APPROVED`; đã tới `effectiveDate` hoặc PA chọn chạy sớm có lý do
    Khi chạy thử cũ
    Thì hệ thống từ chối với ERR-20-043 (422)
    Và người dùng thấy thông báo "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành."

  @US-20-048 @FR-20-048 @M @âm
  Kịch bản: US-20-048 âm 2 · Trạng thái không phù hợp
    Biết kế hoạch `APPROVED`; đã tới `effectiveDate` hoặc PA chọn chạy sớm có lý do
    Khi trạng thái không phù hợp
    Thì hệ thống từ chối với ERR-20-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-20-049 @FR-20-049 @M
  Kịch bản: US-20-049 dương · Xử lý xung đột sáp nhập
    Biết kế hoạch `CONFLICT_REVIEW` hoặc `TRANSFERRING` có xung đột mở
    Khi UI-20-10 tab "Xung đột": chọn cách xử lý từng dòng hoặc hàng loạt
    Thì hệ thống trả `200`; xung đột đã quyết; tổng số còn mở
    Và EN-20-28 có `resolution`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-049 @FR-20-049 @M @âm
  Kịch bản: US-20-049 âm 1 · Cách xử lý không hợp lệ
    Biết kế hoạch `CONFLICT_REVIEW` hoặc `TRANSFERRING` có xung đột mở
    Khi cách xử lý không hợp lệ
    Thì hệ thống từ chối với ERR-20-004 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-20-049 @FR-20-049 @M @âm
  Kịch bản: US-20-049 âm 2 · Mã mới trùng
    Biết kế hoạch `CONFLICT_REVIEW` hoặc `TRANSFERRING` có xung đột mở
    Khi mã mới trùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-050 @FR-20-050 @M
  Kịch bản: US-20-050 dương · Chuyển định danh và cấp song song thông tin xác thực HTTT
    Biết kế hoạch `IDENTITY_TRANSFER`; không còn xung đột mở
    Khi UI-20-10 "Chuyển định danh"
    Thì hệ thống trả `202`; API-20-105 trả `items[]` (`memberSystemCode`, `newClientId`, `status`, `lastCallOld`, `lastCallNew`)
    Và người dùng, client mới ở realm đích
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-050 @FR-20-050 @M @âm
  Kịch bản: US-20-050 âm 1 · Còn xung đột
    Biết kế hoạch `IDENTITY_TRANSFER`; không còn xung đột mở
    Khi còn xung đột
    Thì hệ thống từ chối với ERR-20-044 (409)
    Và người dùng thấy thông báo "Còn {số} xung đột sáp nhập chưa xử lý."

  @US-20-050 @FR-20-050 @M @âm
  Kịch bản: US-20-050 âm 2 · PH-12 lỗi
    Biết kế hoạch `IDENTITY_TRANSFER`; không còn xung đột mở
    Khi PH-12 lỗi
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-051 @FR-20-051 @M
  Kịch bản: US-20-051 dương · Chuyển tiếp lượt gọi và chuyển tenant nguồn sang MERGED
    Biết kế hoạch `IDENTITY_TRANSFER` xong; mọi phân hệ `SUCCEEDED`; không còn xung đột; trong cửa sổ bảo trì của cả hai tỉnh
    Khi UI-20-10 "Thực hiện cutover" (gõ lại mã kế hoạch)
    Thì hệ thống trả `202`; kế hoạch `TRANSITION`, `transitionEndsAt`
    Và nguồn `MERGED`
    Và sự kiện được phát: EVT-20-11; EVT-20-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-051 @FR-20-051 @M @âm
  Kịch bản: US-20-051 âm 1 · Còn xung đột
    Biết kế hoạch `IDENTITY_TRANSFER` xong; mọi phân hệ `SUCCEEDED`; không còn xung đột; trong cửa sổ bảo trì của cả hai tỉnh
    Khi còn xung đột
    Thì hệ thống từ chối với ERR-20-044 (409)
    Và người dùng thấy thông báo "Còn {số} xung đột sáp nhập chưa xử lý."

  @US-20-051 @FR-20-051 @M @âm
  Kịch bản: US-20-051 âm 2 · Ngoài cửa sổ bảo trì
    Biết kế hoạch `IDENTITY_TRANSFER` xong; mọi phân hệ `SUCCEEDED`; không còn xung đột; trong cửa sổ bảo trì của cả hai tỉnh
    Khi ngoài cửa sổ bảo trì
    Thì hệ thống từ chối với ERR-20-059 (422)
    Và người dùng thấy thông báo "Cửa sổ bảo trì không hợp lệ: {lý do}."

  @US-20-052 @FR-20-052 @M
  Kịch bản: US-20-052 dương · Kết thúc sáp nhập sau thời gian chuyển tiếp
    Biết kế hoạch `TRANSITION`
    Khi tự động tại `transitionEndsAt`; UI-20-10 "Gia hạn", "Kết thúc ngay"
    Thì hệ thống trả `200` gia hạn; `202` kết thúc
    Và nguồn `DECOMMISSIONED`; kế hoạch `COMPLETED`
    Và sự kiện được phát: EVT-20-12; EVT-20-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-052 @FR-20-052 @M @âm
  Kịch bản: US-20-052 âm 1 · Kết thúc sớm khi còn HTTT dùng thông tin cũ
    Biết kế hoạch `TRANSITION`
    Khi kết thúc sớm khi còn HTTT dùng thông tin cũ
    Thì hệ thống từ chối với ERR-20-046 (409)
    Và người dùng thấy thông báo "Chưa hết thời gian chuyển tiếp (đến {ngày}) và còn {số} HTTT dùng địa chỉ cũ."

  @US-20-052 @FR-20-052 @M @âm
  Kịch bản: US-20-052 âm 2 · Gia hạn quá tối đa
    Biết kế hoạch `TRANSITION`
    Khi gia hạn quá tối đa
    Thì hệ thống từ chối với ERR-20-045 (422)
    Và người dùng thấy thông báo "Thời gian chuyển tiếp tối đa {số} tháng."

  # ---- EP-20-H · Tổ chức

  @US-20-053 @FR-20-053 @M
  Kịch bản: US-20-053 dương · Quản lý danh mục tổ chức
    Biết tenant `ACTIVE`; tổ chức gieo từ `S13_ORG_SEED`
    Khi UI-20-14 (cây + bảng), "+ Tổ chức"; UI-20-15 xem, sửa
    Thì hệ thống trả `201`, `200`; tổ chức, `ETag`; danh sách `items[]` hoặc `tree[]`
    Và EN-20-02 cập nhật
    Và sự kiện được phát: EVT-20-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-053 @FR-20-053 @M @âm
  Kịch bản: US-20-053 âm 1 · Mã trùng
    Biết tenant `ACTIVE`; tổ chức gieo từ `S13_ORG_SEED`
    Khi mã trùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-053 @FR-20-053 @M @âm
  Kịch bản: US-20-053 âm 2 · Cây chu trình, cha không hợp lệ
    Biết tenant `ACTIVE`; tổ chức gieo từ `S13_ORG_SEED`
    Khi cây chu trình, cha không hợp lệ
    Thì hệ thống từ chối với ERR-20-047 (422)
    Và người dùng thấy thông báo "Tổ chức cấp trên {mã} không hợp lệ: {lý do}."

  @US-20-054 @FR-20-054 @M
  Kịch bản: US-20-054 dương · Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa
    Biết tổ chức `ACTIVE` hoặc `INACTIVE`
    Khi UI-20-15 "Ngừng", "Hoạt động lại", "Giải thể", "Sáp nhập vào…"; UI-20-14 chọn nhiều tổ chức, "Sáp nhập"
    Thì hệ thống trả `200`; tổ chức mới trạng thái; danh sách tổ chức con đã chuyển cha
    Và EN-20-02 cập nhật, lịch sử giữ
    Và sự kiện được phát: EVT-20-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-054 @FR-20-054 @M @âm
  Kịch bản: US-20-054 âm 1 · Còn tham chiếu thiếu kế thừa
    Biết tổ chức `ACTIVE` hoặc `INACTIVE`
    Khi còn tham chiếu thiếu kế thừa
    Thì hệ thống từ chối với ERR-20-049 (409)
    Và người dùng thấy thông báo "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."

  @US-20-054 @FR-20-054 @M @âm
  Kịch bản: US-20-054 âm 2 · Kế thừa không hợp lệ
    Biết tổ chức `ACTIVE` hoặc `INACTIVE`
    Khi kế thừa không hợp lệ
    Thì hệ thống từ chối với ERR-20-048 (422)
    Và người dùng thấy thông báo "Tổ chức kế thừa {mã} không hợp lệ: {lý do}."

  @US-20-055 @FR-20-055 @M
  Kịch bản: US-20-055 dương · Nhập tổ chức từ Excel, CSV có xem trước và xuất
    Biết tenant `ACTIVE`
    Khi UI-20-16 tải tệp; "Tải tệp mẫu"; UI-20-14 "Xuất"
    Thì hệ thống trả `202` (`importId`); API-20-154 trả `rows[]` (`rowNo`, `action`, `errors[]`), `summary`
    Và EN-20-30 `CONFIRMED`; EN-20-02 cập nhật
    Và sự kiện được phát: EVT-20-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-055 @FR-20-055 @M @âm
  Kịch bản: US-20-055 âm 1 · Tệp sai định dạng, quá dòng
    Biết tenant `ACTIVE`
    Khi tệp sai định dạng, quá dòng
    Thì hệ thống từ chối với ERR-20-050 (422)
    Và người dùng thấy thông báo "Tệp nhập không hợp lệ: {lý do}."

  @US-20-055 @FR-20-055 @M @âm
  Kịch bản: US-20-055 âm 2 · Còn dòng lỗi khi xác nhận
    Biết tenant `ACTIVE`
    Khi còn dòng lỗi khi xác nhận
    Thì hệ thống từ chối với ERR-20-051 (422)
    Và người dùng thấy thông báo "Còn {số} dòng lỗi. Sửa tệp rồi tải lại."

  @US-20-056 @FR-20-056 @S
  Kịch bản: US-20-056 dương · Đồng bộ tổ chức khi sắp xếp đơn vị hành chính
    Biết tổ chức `COMMUNE_PC` có `adminUnitId` trỏ tới ĐVHC bị sắp xếp
    Khi EVT-07-10; TA mở UI-20-14 tab "Đề xuất đồng bộ"
    Thì hệ thống trả `200`; `proposals[]`; kết quả áp
    Và đề xuất `APPLIED` hoặc `DISMISSED`
    Và sự kiện được phát: EVT-20-13 khi áp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-056 @FR-20-056 @S @âm
  Kịch bản: US-20-056 âm 1 · Áp khi còn tham chiếu chưa có kế thừa hợp lệ
    Biết tổ chức `COMMUNE_PC` có `adminUnitId` trỏ tới ĐVHC bị sắp xếp
    Khi áp khi còn tham chiếu chưa có kế thừa hợp lệ
    Thì hệ thống từ chối với ERR-20-049 (409)
    Và người dùng thấy thông báo "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."

  @US-20-057 @FR-20-057 @M
  Kịch bản: US-20-057 dương · API đọc tổ chức cho phân hệ khác
    Biết tenant ngữ cảnh `ACTIVE`, `SUSPENDED`, `MERGING` hoặc `MERGED`
    Khi lời gọi của phân hệ
    Thì hệ thống trả `200`; `items[]` (`orgCode`, `name`, `orgType`, `parentCode`, `adminUnitId`, `status`, `isDataOwner`, `effectiveFrom`, `effectiveTo`, `successorCode`, `resolvedSuccessor`)

  @US-20-057 @FR-20-057 @M @âm
  Kịch bản: US-20-057 âm 1 · Thiếu scope
    Biết tenant ngữ cảnh `ACTIVE`, `SUSPENDED`, `MERGING` hoặc `MERGED`
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-20-104 (403)
    Và người dùng thấy thông báo "Tài khoản dịch vụ không có quyền {scope}."

  @US-20-057 @FR-20-057 @M @âm
  Kịch bản: US-20-057 âm 2 · Không có tổ chức
    Biết tenant ngữ cảnh `ACTIVE`, `SUSPENDED`, `MERGING` hoặc `MERGED`
    Khi không có tổ chức
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-058 @FR-20-058 @S
  Kịch bản: US-20-058 dương · Đánh dấu và tra cứu tổ chức chủ quản dữ liệu
    Biết tổ chức `ACTIVE`
    Khi UI-20-15 công tắc "Chủ quản dữ liệu"; UI-20-14 lọc "Chủ quản dữ liệu"
    Thì hệ thống trả `200`; tổ chức, `ETag`
    Và EN-20-02 cập nhật
    Và sự kiện được phát: EVT-20-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-058 @FR-20-058 @S @âm
  Kịch bản: US-20-058 âm 1 · Còn đối tượng được giao
    Biết tổ chức `ACTIVE`
    Khi còn đối tượng được giao
    Thì hệ thống từ chối với ERR-20-049 (409)
    Và người dùng thấy thông báo "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."

  # ---- EP-20-I · Phát hành sản phẩm

  @US-20-059 @FR-20-059 @M
  Kịch bản: US-20-059 dương · Danh mục phiên bản sản phẩm
    Biết ảnh đã qua pipeline CI, có chữ ký cosign và SBOM
    Khi UI-20-18 "+ Phiên bản"; CI gọi API-20-110 với tài khoản máy
    Thì hệ thống trả `201`, `200`; phiên bản, `ETag`
    Và EN-20-31 cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-059 @FR-20-059 @M @âm
  Kịch bản: US-20-059 âm 1 · Phiên bản không hợp lệ
    Biết ảnh đã qua pipeline CI, có chữ ký cosign và SBOM
    Khi phiên bản không hợp lệ
    Thì hệ thống từ chối với ERR-20-053 (422)
    Và người dùng thấy thông báo "Phiên bản sản phẩm {phiên bản} không hợp lệ: {lý do}."

  @US-20-059 @FR-20-059 @M @âm
  Kịch bản: US-20-059 âm 2 · Trùng
    Biết ảnh đã qua pipeline CI, có chữ ký cosign và SBOM
    Khi trùng
    Thì hệ thống từ chối với ERR-20-003 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."

  @US-20-060 @FR-20-060 @M
  Kịch bản: US-20-060 dương · Kênh phát hành và đăng ký kênh của tenant
    Biết phiên bản `DRAFT` (để `PREVIEW`) hoặc `PREVIEW` (để `STABLE`)
    Khi UI-20-18 "Đưa lên PREVIEW", "Nâng lên STABLE"; UI-20-03 tab Phát hành "Đổi kênh"
    Thì hệ thống trả `200`
    Và EN-20-31, EN-20-32 cập nhật
    Và sự kiện được phát: EVT-20-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-060 @FR-20-060 @M @âm
  Kịch bản: US-20-060 âm 1 · Chưa đủ thí điểm
    Biết phiên bản `DRAFT` (để `PREVIEW`) hoặc `PREVIEW` (để `STABLE`)
    Khi chưa đủ thí điểm
    Thì hệ thống từ chối với ERR-20-054 (422)
    Và người dùng thấy thông báo "Phiên bản {phiên bản} mới thí điểm {số} ngày, cần tối thiểu {ngưỡng} ngày và không có sự cố mức 1."

  @US-20-060 @FR-20-060 @M @âm
  Kịch bản: US-20-060 âm 2 · Đổi kênh khi đang nâng cấp
    Biết phiên bản `DRAFT` (để `PREVIEW`) hoặc `PREVIEW` (để `STABLE`)
    Khi đổi kênh khi đang nâng cấp
    Thì hệ thống từ chối với ERR-20-061 (409)
    Và người dùng thấy thông báo "Tenant {mã} đang có kế hoạch nâng cấp {kế hoạch}. Đổi kênh sau khi kế hoạch kết thúc."

  @US-20-061 @FR-20-061 @M
  Kịch bản: US-20-061 dương · Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì
    Biết phiên bản `STABLE` (hoặc `PREVIEW` với tenant kênh `PREVIEW`); tenant đích chạy bản ≥ `minFromVersion`
    Khi UI-20-19 "+ Kế hoạch nâng cấp"
    Thì hệ thống trả `201`; kế hoạch, lịch từng tenant
    Và EN-20-34 `SCHEDULED`; EN-20-35 `PENDING`
    Và sự kiện được phát: EVT-20-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-061 @FR-20-061 @M @âm
  Kịch bản: US-20-061 âm 1 · Kế hoạch không hợp lệ
    Biết phiên bản `STABLE` (hoặc `PREVIEW` với tenant kênh `PREVIEW`); tenant đích chạy bản ≥ `minFromVersion`
    Khi kế hoạch không hợp lệ
    Thì hệ thống từ chối với ERR-20-056 (422)
    Và người dùng thấy thông báo "Kế hoạch nâng cấp không hợp lệ: {lý do}."

  @US-20-061 @FR-20-061 @M @âm
  Kịch bản: US-20-061 âm 2 · Cửa sổ sai
    Biết phiên bản `STABLE` (hoặc `PREVIEW` với tenant kênh `PREVIEW`); tenant đích chạy bản ≥ `minFromVersion`
    Khi cửa sổ sai
    Thì hệ thống từ chối với ERR-20-059 (422)
    Và người dùng thấy thông báo "Cửa sổ bảo trì không hợp lệ: {lý do}."

  @US-20-062 @FR-20-062 @S
  Kịch bản: US-20-062 dương · Theo dõi nâng cấp, dừng sóng, quay lui
    Biết kế hoạch `SCHEDULED` hoặc `RUNNING`
    Khi tới giờ cửa sổ; UI-20-19 "Dừng", "Tiếp tục", "Quay lui", "Thử lại"
    Thì hệ thống trả `200`; tiến độ theo tenant
    Và EN-20-34, EN-20-35 cập nhật
    Và sự kiện được phát: EVT-20-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-062 @FR-20-062 @S @âm
  Kịch bản: US-20-062 âm 1 · Tiếp tục khi sóng dừng do ngưỡng
    Biết kế hoạch `SCHEDULED` hoặc `RUNNING`
    Khi tiếp tục khi sóng dừng do ngưỡng
    Thì hệ thống từ chối với ERR-20-057 (409)
    Và người dùng thấy thông báo "Sóng {sóng} đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."

  @US-20-063 @FR-20-063 @S
  Kịch bản: US-20-063 dương · Thông báo phát hành và lịch bảo trì tới tỉnh
    Biết kế hoạch `SCHEDULED`
    Khi lên lịch; trước giờ 72 giờ và 2 giờ; PA "Gửi thông báo"
    Thì hệ thống trả `202`
    Và lịch sử thông báo lưu ở EN-20-34
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-063 @FR-20-063 @S @âm
  Kịch bản: US-20-063 âm 1 · PH-18 lỗi
    Biết kế hoạch `SCHEDULED`
    Khi PH-18 lỗi
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-064 @FR-20-064 @S
  Kịch bản: US-20-064 dương · Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh
    Biết tenant `ACTIVE` hoặc `SUSPENDED`
    Khi UI-20-12 tab "Phiên bản và bảo trì"
    Thì hệ thống trả `200`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-064 @FR-20-064 @S @âm
  Kịch bản: US-20-064 âm 1 · Cửa sổ sai
    Biết tenant `ACTIVE` hoặc `SUSPENDED`
    Khi cửa sổ sai
    Thì hệ thống từ chối với ERR-20-059 (422)
    Và người dùng thấy thông báo "Cửa sổ bảo trì không hợp lệ: {lý do}."

  # ---- EP-20-J · Dịch vụ cho phân hệ khác và quản trị

  @US-20-065 @FR-20-065 @M
  Kịch bản: US-20-065 dương · Registry tenant cho phân hệ khác
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi lời gọi của phân hệ, thư viện `dh-tenant-client`
    Thì hệ thống trả `200`; `items[]` (`tenantCode`, `tenantId`, `status`, `isolationMode`, `realm`, `hosts[]`, `apiPrefix`, `modules[]`, `quota`, `configVersion`)

  @US-20-065 @FR-20-065 @M @âm
  Kịch bản: US-20-065 âm 1 · Thiếu scope
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-20-104 (403)
    Và người dùng thấy thông báo "Tài khoản dịch vụ không có quyền {scope}."

  @US-20-065 @FR-20-065 @M @âm
  Kịch bản: US-20-065 âm 2 · Không có tenant
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi không có tenant
    Thì hệ thống từ chối với ERR-20-002 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-20-066 @FR-20-066 @M
  Kịch bản: US-20-066 dương · Thực thi trạng thái tenant ở data plane và control plane
    Biết registry khả dụng hoặc đệm còn hạn
    Khi mỗi yêu cầu vào DU hoặc gateway
    Thì phản hồi lỗi chuẩn D00-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-066 @FR-20-066 @M @âm
  Kịch bản: US-20-066 âm 1 · Tạm ngừng
    Biết registry khả dụng hoặc đệm còn hạn
    Khi tạm ngừng
    Thì hệ thống từ chối với ERR-20-001 (403)
    Và người dùng thấy thông báo "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."

  @US-20-066 @FR-20-066 @M @âm
  Kịch bản: US-20-066 âm 2 · Phân hệ chưa bật
    Biết registry khả dụng hoặc đệm còn hạn
    Khi phân hệ chưa bật
    Thì hệ thống từ chối với ERR-20-103 (503)
    Và người dùng thấy thông báo "Chức năng này chưa được bật cho tỉnh."

  @US-20-067 @FR-20-067 @S
  Kịch bản: US-20-067 dương · Bảng điều khiển nền tảng đa tenant
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi UI-20-20
    Thì hệ thống trả `200`

  @US-20-067 @FR-20-067 @S @âm
  Kịch bản: US-20-067 âm 1 · Nguồn chỉ số lỗi
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi nguồn chỉ số lỗi
    Thì hệ thống từ chối với ERR-20-062
    Và người dùng thấy thông báo "Không có số liệu"

  @US-20-068 @FR-20-068 @M
  Kịch bản: US-20-068 dương · Nhật ký kiểm toán thao tác PH-20
    Biết bản ghi đã ghi vào PH-13
    Khi UI-20-03 tab "Kiểm toán"; `CMP-AuditTimeline`
    Thì hệ thống trả `200`; `items[]`

  @US-20-068 @FR-20-068 @M @âm
  Kịch bản: US-20-068 âm 1 · Khoảng thời gian quá dài
    Biết bản ghi đã ghi vào PH-13
    Khi khoảng thời gian quá dài
    Thì hệ thống từ chối với ERR-20-032 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa là {số} ngày."

  @US-20-068 @FR-20-068 @M @âm
  Kịch bản: US-20-068 âm 2 · PH-13 lỗi
    Biết bản ghi đã ghi vào PH-13
    Khi PH-13 lỗi
    Thì hệ thống từ chối với ERR-20-062 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-20-069 @FR-20-069 @M
  Kịch bản: US-20-069 dương · Tham số 20.* của phân hệ
    Biết PH-18 khả dụng khi khởi động (có giá trị mặc định dự phòng)
    Khi khởi động DU; EVT tham số đổi từ PH-18; màn xem tham số
    Thì hệ thống trả `200`
    Và giá trị áp mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-069 @FR-20-069 @M @âm
  Kịch bản: US-20-069 âm 1 · Giá trị ngoài miền
    Biết PH-18 khả dụng khi khởi động (có giá trị mặc định dự phòng)
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-20-060 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}."

  @US-20-069 @FR-20-069 @M @âm
  Kịch bản: US-20-069 âm 2 · Tắt kiểm tra khói khi có tenant thật (BR-20-004)
    Biết PH-18 khả dụng khi khởi động (có giá trị mặc định dự phòng)
    Khi tắt kiểm tra khói khi có tenant thật (BR-20-004)
    Thì hệ thống từ chối với ERR-20-060 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}."

  @US-20-070 @FR-20-070 @S
  Kịch bản: US-20-070 dương · Điều phối kiểm thử rò rỉ chéo tenant định kỳ
    Biết có ít nhất hai tenant kiểm thử `ACTIVE` trong T90…T99
    Khi lịch; UI-20-20 "Chạy ngay"
    Thì hệ thống trả `202`; kết quả từng ca
    Và EN-20-36 có kết quả
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-20-070 @FR-20-070 @S @âm
  Kịch bản: US-20-070 âm 1 · Tenant không phải kiểm thử
    Biết có ít nhất hai tenant kiểm thử `ACTIVE` trong T90…T99
    Khi tenant không phải kiểm thử
    Thì hệ thống từ chối với ERR-20-065 (422)
    Và người dùng thấy thông báo "Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."
