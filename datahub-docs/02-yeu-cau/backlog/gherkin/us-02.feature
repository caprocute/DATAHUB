# language: vi
# Sinh tự động từ D02-02/D02-03-PH02 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-02
Tính năng: PH-02 · Danh mục dịch vụ

  # ---- EP-02-A · Danh mục và tra cứu

  @US-02-001 @FR-02-001 @M
  Kịch bản: US-02-001 dương · Liệt kê API trong danh mục, lọc, sắp xếp
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở menu "Kết nối & API → Danh mục API" (`/ket-noi/api`)
    Thì hệ thống trả `200`; `items[]` gồm `apiCode`, tên, HTTT cung cấp, đơn vị chủ quản, `dataClass`, `visibility`, `origin`, phiên bản mới nhất và trạng thái, số bên đăng ký `ACTIVE`, chỉ báo SLA kỳ gần nhất, cờ cảnh báo …

  @US-02-001 @FR-02-001 @M @âm
  Kịch bản: US-02-001 âm 1 · Tham số lọc sai miền giá trị hoặc `size` quá lớn
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số lọc sai miền giá trị hoặc `size` quá lớn
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Bộ lọc không hợp lệ: {tên trường}."

  @US-02-001 @FR-02-001 @M @âm
  Kịch bản: US-02-001 âm 2 · Không có API khớp
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi không có API khớp
    Thì trả `200` với danh sách rỗng; màn hình hiện thông báo kèm nút thông báo
    Và người dùng thấy thông báo "Chưa có API nào khớp bộ lọc."

  @US-02-002 @FR-02-002 @M
  Kịch bản: US-02-002 dương · Xem chi tiết API
    Biết API tồn tại trong tenant hiện hành và người dùng được xem (BR-02-039)
    Khi người dùng bấm một dòng ở UI-02-01, hoặc mở trực tiếp `/ket-noi/api/{ma-api}`
    Thì hệ thống trả `200`, `ETag`; chi tiết API kèm `versions[]` (số hiệu, trạng thái, `sunsetAt`, kế nhiệm), thông tin phiên bản được chọn (đường dẫn công bố, backend tóm tắt, gói tóm tắt, SLA cam kết và thực tế, số đăng ký theo trạng thái) …

  @US-02-002 @FR-02-002 @M @âm
  Kịch bản: US-02-002 âm 1 · API không có hoặc thuộc tenant khác
    Biết API tồn tại trong tenant hiện hành và người dùng được xem (BR-02-039)
    Khi API không có hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-02-001
    Và người dùng thấy thông báo "không tồn tại"

  @US-02-002 @FR-02-002 @M @âm
  Kịch bản: US-02-002 âm 2 · Người dùng không được xem phiên bản nháp của đơn vị khác
    Biết API tồn tại trong tenant hiện hành và người dùng được xem (BR-02-039)
    Khi người dùng không được xem phiên bản nháp của đơn vị khác
    Thì bị ẩn, không báo lỗi (BR-02-039)

  @US-02-003 @FR-02-003 @M
  Kịch bản: US-02-003 dương · Tìm kiếm toàn văn danh mục
    Biết người dùng đã đăng nhập, đã chọn tenant
    Khi người dùng gõ vào ô tìm kiếm ở UI-02-01 (sau 300 ms ngừng gõ), hoặc gọi API tìm kiếm
    Thì hệ thống trả `200`; `items[]` như FR-02-001 kèm `highlights`, `score`; `suggestions[]` khi rỗng; `degraded`

  @US-02-003 @FR-02-003 @M @âm
  Kịch bản: US-02-003 âm 1 · `q` rỗng hoặc chỉ có ký tự đặc biệt
    Biết người dùng đã đăng nhập, đã chọn tenant
    Khi `q` rỗng hoặc chỉ có ký tự đặc biệt
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Nhập ít nhất 2 ký tự để tìm."

  @US-02-003 @FR-02-003 @M @âm
  Kịch bản: US-02-003 âm 2 · Chỉ mục đang dựng lại
    Biết người dùng đã đăng nhập, đã chọn tenant
    Khi chỉ mục đang dựng lại
    Thì chuyển sang tìm theo mã, tên bằng `ILIKE`; kết quả kèm cờ `degraded = true`, màn hình báo thông báo
    Và người dùng thấy thông báo "Đang cập nhật chỉ mục, kết quả có thể chưa đầy đủ."

  @US-02-004 @FR-02-004 @M
  Kịch bản: US-02-004 dương · Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển theo mức hiển thị
    Biết có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi cổng nhà phát triển hoặc HTTT gọi `GET /catalog/apis`; người dùng mở danh mục ở PH-15
    Thì hệ thống trả `200` hoặc `304`; `items[]`, `removed[]`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `Cache-Control: private, max-age=300` (giá trị `public` chỉ với tập `PUBLIC`)

  @US-02-004 @FR-02-004 @M @âm
  Kịch bản: US-02-004 âm 1 · Token thiếu hoặc không có scope `catalog:read`
    Biết có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi token thiếu hoặc không có scope `catalog:read`
    Thì hệ thống từ chối với ERR-02-014

  @US-02-004 @FR-02-004 @M @âm
  Kịch bản: US-02-004 âm 2 · API không thuộc tập được phép thấy
    Biết có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi API không thuộc tập được phép thấy
    Thì hệ thống từ chối với ERR-02-001 (404)

  @US-02-005 @FR-02-005 @M
  Kịch bản: US-02-005 dương · Xem đường dẫn sử dụng và mẫu gọi API
    Biết phiên bản có context-path (FR-02-024); để thấy đường dẫn môi trường thật phiên bản phải `PUBLISHED`
    Khi người dùng mở tab Tổng quan, khối "Cách gọi API", của UI-02-02
    Thì hệ thống trả `200`; `baseUrl`, `operations[]` (phương thức, đường dẫn, mô tả, phạm vi), `tokenUrl`, `scopes[]`, `samples[]` (`curl`, `javascript`, `java`)

  @US-02-005 @FR-02-005 @M @âm
  Kịch bản: US-02-005 âm 1 · Phiên bản chưa `PUBLISHED` khi yêu cầu môi trường `PROD`
    Biết phiên bản có context-path (FR-02-024); để thấy đường dẫn môi trường thật phiên bản phải `PUBLISHED`
    Khi phiên bản chưa `PUBLISHED` khi yêu cầu môi trường `PROD`
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "API chưa được công bố nên chưa có đường dẫn môi trường thật."

  @US-02-005 @FR-02-005 @M @âm
  Kịch bản: US-02-005 âm 2 · Phiên bản chưa có context-path
    Biết phiên bản có context-path (FR-02-024); để thấy đường dẫn môi trường thật phiên bản phải `PUBLISHED`
    Khi phiên bản chưa có context-path
    Thì hệ thống từ chối với ERR-02-019 (422)
    Và người dùng thấy thông báo "Chưa đặt đường dẫn công bố cho phiên bản này."

  @US-02-006 @FR-02-006 @M
  Kịch bản: US-02-006 dương · Tải đặc tả OpenAPI đã công bố
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED`; riêng chủ quản, TA, CA tải được cả phiên bản `DRAFT`, `PENDING`
    Khi người dùng bấm "Tải đặc tả" ở UI-02-02; PH-04 gọi để sinh luồng từ API
    Thì hệ thống trả `200`; thân là tài liệu OpenAPI; tiêu đề `Content-Disposition`, `ETag`, `Content-Type: application/yaml` hoặc `application/json`

  @US-02-006 @FR-02-006 @M @âm
  Kịch bản: US-02-006 âm 1 · Băm không khớp (tệp bị hỏng ở kho)
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED`; riêng chủ quản, TA, CA tải được cả phiên bản `DRAFT`, `PENDING`
    Khi băm không khớp (tệp bị hỏng ở kho)
    Thì hệ thống từ chối với ERR-02-034 (503)
    Và người dùng thấy thông báo "Không đọc được đặc tả, hãy thử lại sau hoặc báo quản trị."

  @US-02-006 @FR-02-006 @M @âm
  Kịch bản: US-02-006 âm 2 · Phiên bản không có hoặc không được xem
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED`; riêng chủ quản, TA, CA tải được cả phiên bản `DRAFT`, `PENDING`
    Khi phiên bản không có hoặc không được xem
    Thì hệ thống từ chối với ERR-02-001 (404)

  @US-02-007 @FR-02-007 @M
  Kịch bản: US-02-007 dương · Phân loại và gắn thẻ API
    Biết API tồn tại; người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi người dùng sửa khối "Phân loại" ở UI-02-02 hoặc ở bước 1 của UI-02-03
    Thì hệ thống trả `200`, `ETag` mới; thông tin API sau cập nhật
    Và thuộc tính phân loại của API cập nhật; chỉ mục tìm kiếm cập nhật trong 1 phút
    Và sự kiện được phát: EVT-02-02 (`api.updated`, `changedFields`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-007 @FR-02-007 @M @âm
  Kịch bản: US-02-007 âm 1 · `stateSecret = true`
    Biết API tồn tại; người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi `stateSecret = true`
    Thì hệ thống từ chối với ERR-02-016 (422)
    Và người dùng thấy thông báo "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub."

  @US-02-007 @FR-02-007 @M @âm
  Kịch bản: US-02-007 âm 2 · Nâng mức khi còn gói không phù hợp
    Biết API tồn tại; người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi nâng mức khi còn gói không phù hợp
    Thì hệ thống từ chối với ERR-02-022 (422)
    Và người dùng thấy thông báo "Mức phân loại mới yêu cầu xác thực mạnh hơn. Gói {mã gói} cần được đổi trước."

  @US-02-008 @FR-02-008 @S
  Kịch bản: US-02-008 dương · Quản lý bộ phân loại và thẻ
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi quản trị mở UI-02-14 (cây phân loại kèm bảng API trong nhóm)
    Thì hệ thống trả `201` (thêm, tiêu đề `Location`), `200` (sửa, gộp), `204` (xóa)
    Và bộ phân loại cập nhật; các API đã gộp mang nhóm mới
    Và sự kiện được phát: EVT-02-02 cho từng API đổi nhóm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-008 @FR-02-008 @S @âm
  Kịch bản: US-02-008 âm 1 · Mã nhóm trùng
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mã nhóm trùng
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "Mã nhóm {mã} đã được dùng. Chọn mã khác."

  @US-02-009 @FR-02-009 @S
  Kịch bản: US-02-009 dương · Hiển thị dịch vụ sự kiện (topic) trong danh mục
    Biết PH-10 đã triển khai; topic `ACTIVE`
    Khi PH-02 nhận EVT-10-01, 03, 04 của PH-10; hoặc người dùng chọn bộ lọc "Dịch vụ sự kiện" ở UI-02-01
    Thì hệ thống trả `200`; mục danh mục loại `EVENT` gồm `topicName`, mô tả, trạng thái, `dataClass`, HTTT phát, liên kết sang PH-10
    Và mục danh mục loại `EVENT` đồng bộ với trạng thái topic ở PH-10

  @US-02-009 @FR-02-009 @S @âm
  Kịch bản: US-02-009 âm 1 · PH-10 không khả dụng khi lấy chi tiết
    Biết PH-10 đã triển khai; topic `ACTIVE`
    Khi PH-10 không khả dụng khi lấy chi tiết
    Thì hệ thống từ chối với ERR-02-034
    Và người dùng thấy thông báo "Chưa cập nhật lúc {thời điểm}"

  # ---- EP-02-B · Đăng ký API và nạp đặc tả

  @US-02-010 @FR-02-010 @M
  Kịch bản: US-02-010 dương · Đăng ký API mới bằng trình hướng dẫn
    Biết HTTT cung cấp `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; loại API được tenant bật
    Khi người dùng bấm "+ Đăng ký API" ở UI-02-01, mở UI-02-03 (`/ket-noi/api/moi`)
    Thì hệ thống trả `201`, tiêu đề `Location`, `ETag`; chi tiết API và phiên bản `DRAFT`: `apiCode`, `versionNo`, `status = DRAFT`, `specId`, kết quả kiểm tra tóm tắt, `allowedActions[]`
    Và API và phiên bản `DRAFT` được tạo; đặc tả lưu ở kho đối tượng, băm lưu ở CSDL; chưa có route ở gateway
    Và sự kiện được phát: EVT-02-01 (`api.registered`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-010 @FR-02-010 @M @âm
  Kịch bản: US-02-010 âm 1 · Mã API đã dùng
    Biết HTTT cung cấp `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; loại API được tenant bật
    Khi mã API đã dùng
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng (kể cả API đã xóa). Chọn mã khác."

  @US-02-010 @FR-02-010 @M @âm
  Kịch bản: US-02-010 âm 2 · HTTT cung cấp không `ACTIVE`
    Biết HTTT cung cấp `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; loại API được tenant bật
    Khi HTTT cung cấp không `ACTIVE`
    Thì hệ thống từ chối với ERR-02-004 (422)
    Và người dùng thấy thông báo "HTTT {mã} chưa được kết nạp hoặc không ở trạng thái hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước."

  @US-02-011 @FR-02-011 @M
  Kịch bản: US-02-011 dương · Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL
    Biết phiên bản ở `DRAFT` (hoặc đang ở bước 2 của trình hướng dẫn FR-02-010)
    Khi người dùng chọn "Tải tệp", "Dán nội dung" hoặc "Nhập từ URL" ở bước 2 của UI-02-03, hoặc ở tab Phiên bản của UI-02-02
    Thì hệ thống trả `200`; `specId`, `sha256`, `sizeBytes`, `openapiVersion`, `operationCount`, `converted`, tóm tắt kiểm tra `{errors, warnings, infos}`
    Và đặc tả của phiên bản `DRAFT` được thay; kết quả kiểm tra cũ bị đánh dấu lỗi thời; bản chưa duyệt không giữ vĩnh viễn, nhưng bản đã nộp duyệt thì giữ (BR-02-014)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-011 @FR-02-011 @M @âm
  Kịch bản: US-02-011 âm 1 · URL không truy cập được hoặc không cho phép
    Biết phiên bản ở `DRAFT` (hoặc đang ở bước 2 của trình hướng dẫn FR-02-010)
    Khi URL không truy cập được hoặc không cho phép
    Thì hệ thống từ chối với ERR-02-010 (422)
    Và người dùng thấy thông báo "Không tải được đặc tả từ địa chỉ này (địa chỉ không nằm trong danh sách cho phép hoặc không phản hồi)."

  @US-02-011 @FR-02-011 @M @âm
  Kịch bản: US-02-011 âm 2 · Sai cú pháp
    Biết phiên bản ở `DRAFT` (hoặc đang ở bước 2 của trình hướng dẫn FR-02-010)
    Khi sai cú pháp
    Thì hệ thống từ chối với ERR-02-005 (422)
    Và người dùng thấy thông báo "Đặc tả sai cú pháp ở dòng {n}, cột {m}: {mô tả}."

  @US-02-012 @FR-02-012 @S
  Kịch bản: US-02-012 dương · Đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi
    Biết đặc tả có `source = URL` và `autoRefresh = true`; phiên bản ở bất kỳ trạng thái nào trừ `RETIRED`
    Khi lịch mỗi `02.spec.url-refresh-hours` giờ (mặc định 24); hoặc người dùng bấm "Đồng bộ ngay"
    Thì hệ thống trả `202` (bấm tay) kèm `operationId`; kết quả: `unchanged`, hoặc `changed` kèm `diffSummary`, `breakingCount`
    Và `lastCheckedAt` cập nhật; có thể có một "đề xuất cập nhật" chờ chủ dịch vụ
    Và sự kiện được phát: EVT-02-07 (`version.spec-source-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-012 @FR-02-012 @S @âm
  Kịch bản: US-02-012 âm 1 · URL bị chặn bởi egress hoặc trả lỗi
    Biết đặc tả có `source = URL` và `autoRefresh = true`; phiên bản ở bất kỳ trạng thái nào trừ `RETIRED`
    Khi URL bị chặn bởi egress hoặc trả lỗi
    Thì hệ thống từ chối với ERR-02-010 (422)
    Và người dùng thấy thông báo "Không tải được đặc tả từ địa chỉ này."

  @US-02-013 @FR-02-013 @M
  Kịch bản: US-02-013 dương · Tự đăng ký API từ luồng REST của PH-04
    Biết luồng có `rest` DSL và đã được duyệt phát hành ở PH-04; HTTT cung cấp (HTTT sở hữu luồng) `ACTIVE`
    Khi sự kiện EVT-04-04 (`version.approved`) và EVT-04-07 (`deployment.status-changed` sang `SYNCED`) của PH-04 cho luồng có điểm vào REST
    Thì luồng REST của PH-04 xuất hiện trong danh mục như một API, đi cùng quy trình công bố như mọi API
    Và API `origin = FLOW` có phiên bản `DRAFT` kèm backend `FLOW`; chưa có route ở gateway cho tới khi công bố
    Và sự kiện được phát: EVT-02-01, EVT-02-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-013 @FR-02-013 @M @âm
  Kịch bản: US-02-013 âm 1 · Mã luồng trùng một API nhập tay có sẵn
    Biết luồng có `rest` DSL và đã được duyệt phát hành ở PH-04; HTTT cung cấp (HTTT sở hữu luồng) `ACTIVE`
    Khi mã luồng trùng một API nhập tay có sẵn
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "API {mã} đã có, chọn Liên kết với luồng hoặc đổi mã."

  @US-02-013 @FR-02-013 @M @âm
  Kịch bản: US-02-013 âm 2 · Không đọc được đặc tả từ PH-04
    Biết luồng có `rest` DSL và đã được duyệt phát hành ở PH-04; HTTT cung cấp (HTTT sở hữu luồng) `ACTIVE`
    Khi không đọc được đặc tả từ PH-04
    Thì hệ thống từ chối với ERR-02-034 (503)

  @US-02-014 @FR-02-014 @M
  Kịch bản: US-02-014 dương · Sửa thông tin API và đặc tả khi còn bản nháp
    Biết API tồn tại, người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi người dùng bấm "Sửa" ở UI-02-02 hoặc sửa các trường ở UI-02-03
    Thì hệ thống trả `200`, `ETag` mới; API sau cập nhật
    Và bản ghi cập nhật; kết quả kiểm tra đặc tả (nếu đặc tả đổi) đánh dấu lỗi thời
    Và sự kiện được phát: EVT-02-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-014 @FR-02-014 @M @âm
  Kịch bản: US-02-014 âm 1 · Sửa trường hợp đồng của phiên bản đã công bố
    Biết API tồn tại, người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi sửa trường hợp đồng của phiên bản đã công bố
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Phiên bản đã công bố không sửa được đặc tả. Tạo phiên bản mới."

  @US-02-014 @FR-02-014 @M @âm
  Kịch bản: US-02-014 âm 2 · `ETag` lệch
    Biết API tồn tại, người dùng thuộc tổ chức chủ quản (hoặc là TA)
    Khi `ETag` lệch
    Thì hệ thống từ chối với ERR-02-015 (412)
    Và người dùng thấy thông báo "Thông tin vừa được người khác thay đổi. Tải lại để xem."

  @US-02-015 @FR-02-015 @S
  Kịch bản: US-02-015 dương · Cung cấp mẫu đặc tả và quy ước viết API
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi người dùng bấm "Tải mẫu đặc tả" hoặc "Xem quy ước" ở bước 2 của UI-02-03
    Thì hệ thống trả `200`; tệp mẫu YAML kèm `Content-Disposition`; hoặc trang quy ước (HTML) ở giao diện

  @US-02-015 @FR-02-015 @S @âm
  Kịch bản: US-02-015 âm 1 · Loại mẫu không có
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi loại mẫu không có
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Loại mẫu không hợp lệ."

  # ---- EP-02-C · Kiểm tra đặc tả

  @US-02-016 @FR-02-016 @M
  Kịch bản: US-02-016 dương · Kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1
    Biết phiên bản có đặc tả (FR-02-011)
    Khi sau khi nạp hoặc sửa đặc tả; khi gửi duyệt (FR-02-034 kiểm tra lại); khi người dùng bấm "Kiểm tra lại"
    Thì hệ thống trả `200`; `valid`, `summary {errors, warnings, infos}`, `findings[]` (`layer`, `severity`, `ruleId`, `location`, `message`, `hint`), `checkedAt`, `specSha256`
    Và kết quả kiểm tra lớp `STANDARD` của đặc tả được ghi; phát hiện cũ đã sửa được đánh dấu `resolved` thay vì xóa
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-016 @FR-02-016 @M @âm
  Kịch bản: US-02-016 âm 1 · Có lỗi lớp 1
    Biết phiên bản có đặc tả (FR-02-011)
    Khi có lỗi lớp 1
    Thì hệ thống từ chối với ERR-02-006 (422)
    Và người dùng thấy thông báo "Đặc tả còn {n} lỗi. Sửa các lỗi dưới đây rồi kiểm tra lại."

  @US-02-016 @FR-02-016 @M @âm
  Kịch bản: US-02-016 âm 2 · Đặc tả không đọc được
    Biết phiên bản có đặc tả (FR-02-011)
    Khi đặc tả không đọc được
    Thì hệ thống từ chối với ERR-02-005 (422)
    Và người dùng thấy thông báo "Đặc tả sai cú pháp ở dòng {n}, cột {m}."

  @US-02-017 @FR-02-017 @M
  Kịch bản: US-02-017 dương · Kiểm tra đặc tả lớp 2: quy ước nền tảng
    Biết đặc tả đạt lớp 1 (nếu lớp 1 còn lỗi, chỉ chạy các luật không phụ thuộc cấu trúc)
    Khi ngay sau FR-02-016, khi gửi duyệt, và khi bấm "Kiểm tra lại"
    Thì hệ thống trả `200`; như FR-02-016 với `layer = CONVENTION`; mỗi phát hiện có `ruleId`, `severity`, `status` (`OPEN`, `RESOLVED`, `ACKNOWLEDGED`), `hint`, đường dẫn tài liệu quy ước
    Và kết quả kiểm tra lớp `CONVENTION` được ghi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-017 @FR-02-017 @M @âm
  Kịch bản: US-02-017 âm 1 · Còn phát hiện `ERROR` khi gửi duyệt
    Biết đặc tả đạt lớp 1 (nếu lớp 1 còn lỗi, chỉ chạy các luật không phụ thuộc cấu trúc)
    Khi còn phát hiện `ERROR` khi gửi duyệt
    Thì hệ thống từ chối với ERR-02-007 (422)
    Và người dùng thấy thông báo "Đặc tả còn {n} lỗi theo quy ước nền tảng. Mở kết quả kiểm tra để xem hướng dẫn sửa."

  @US-02-017 @FR-02-017 @M @âm
  Kịch bản: US-02-017 âm 2 · Luật cấu hình sai (không giải được)
    Biết đặc tả đạt lớp 1 (nếu lớp 1 còn lỗi, chỉ chạy các luật không phụ thuộc cấu trúc)
    Khi luật cấu hình sai (không giải được)
    Thì hệ thống từ chối với ERR-02-034

  @US-02-018 @FR-02-018 @M
  Kịch bản: US-02-018 dương · Quét bí mật và dữ liệu cá nhân thật trong đặc tả
    Biết phiên bản có đặc tả
    Khi cùng lúc FR-02-016, 017; luôn chạy lại khi gửi duyệt và khi duyệt
    Thì hệ thống trả `200`; `findings[]` lớp `SECRET` (`ruleId = SCAN-02-nn`, `location`, `maskedTail`, `status`)
    Và kết quả quét ghi vào bảng kết quả kiểm tra; không lưu chuỗi khớp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-018 @FR-02-018 @M @âm
  Kịch bản: US-02-018 âm 1 · Phát hiện bí mật
    Biết phiên bản có đặc tả
    Khi phát hiện bí mật
    Thì hệ thống từ chối với ERR-02-008 (422)
    Và người dùng thấy thông báo "Đặc tả có giá trị giống khóa hoặc dữ liệu cá nhân thật tại {vị trí}. Thay bằng giá trị giữ chỗ rồi kiểm tra lại."

  @US-02-018 @FR-02-018 @M @âm
  Kịch bản: US-02-018 âm 2 · Đặc tả sạch nhưng bộ quét lỗi
    Biết phiên bản có đặc tả
    Khi đặc tả sạch nhưng bộ quét lỗi
    Thì hệ thống từ chối với ERR-02-034 (503)
    Và người dùng thấy thông báo "Chưa quét được bí mật, tạm không gửi duyệt được."

  @US-02-019 @FR-02-019 @M
  Kịch bản: US-02-019 dương · Kiểm tra đặc tả không lưu (xem trước khi gõ)
    Biết người dùng đã đăng nhập và có `PERM-02-create`
    Khi trình soạn thảo ở UI-02-03 gọi sau 800 ms ngừng gõ; hoặc lệnh gọi API từ công cụ ngoài
    Thì hệ thống trả `200`; `valid`, `canContinue`, `summary`, `findings[]`

  @US-02-019 @FR-02-019 @M @âm
  Kịch bản: US-02-019 âm 1 · Vượt giới hạn tần suất
    Biết người dùng đã đăng nhập và có `PERM-02-create`
    Khi vượt giới hạn tần suất
    Thì hệ thống từ chối với ERR-02-036 (429)
    Và người dùng thấy thông báo "Đã kiểm tra quá nhiều lần. Thử lại sau {n} giây."

  @US-02-019 @FR-02-019 @M @âm
  Kịch bản: US-02-019 âm 2 · Quá lớn
    Biết người dùng đã đăng nhập và có `PERM-02-create`
    Khi quá lớn
    Thì hệ thống từ chối với ERR-02-009 (413)
    Và người dùng thấy thông báo "Đặc tả vượt 10 MiB."

  @US-02-020 @FR-02-020 @S
  Kịch bản: US-02-020 dương · Phát hiện API trùng chức năng
    Biết phiên bản có đặc tả đã đạt lớp 1
    Khi ở bước 3 của UI-02-03; khi gửi duyệt; khi mở màn duyệt (UI-02-10)
    Thì hệ thống trả `200`; `duplicates[]` gồm `apiCode`, `score`, `reasons[]`, chủ quản, trạng thái
    Và quyết định của người duyệt gắn vào yêu cầu duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-020 @FR-02-020 @S @âm
  Kịch bản: US-02-020 âm 1 · Không có API gần giống
    Biết phiên bản có đặc tả đã đạt lớp 1
    Khi không có API gần giống
    Thì trả danh sách rỗng, không cảnh báo

  @US-02-021 @FR-02-021 @S
  Kịch bản: US-02-021 dương · Quản lý bộ luật kiểm tra quy ước
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi quản trị mở UI-02-15 "Bộ luật kiểm tra"
    Thì hệ thống trả `200`; bộ luật hiệu lực với `rulesetVersion`
    Và bộ luật hiệu lực của tenant có số phiên bản mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-021 @FR-02-021 @S @âm
  Kịch bản: US-02-021 âm 1 · Cố tắt luật cấu trúc
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi cố tắt luật cấu trúc
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Luật {mã} là luật bắt buộc, không thể tắt hoặc hạ mức."

  # ---- EP-02-D · Backend, đường dẫn và khung route

  @US-02-022 @FR-02-022 @M
  Kịch bản: US-02-022 dương · Khai báo backend của API
    Biết phiên bản `DRAFT`; với loại `SYSTEM`, kết nối PH-05 đã được cấp cho API; với loại `FLOW`, luồng đã có điểm vào REST ở PH-04
    Khi người dùng bấm "+ Thêm backend" ở tab Backend của UI-02-02, hoặc ở bước 4 của UI-02-03
    Thì hệ thống trả `201`, tiêu đề `Location`; chi tiết backend: `backendCode`, loại, `targetRef`, `weight`, `status`, cấu hình mặc định
    Và backend lưu, gắn với phiên bản; chưa ảnh hưởng gateway cho tới khi công bố (hoặc duyệt thay đổi)
    Và sự kiện được phát: EVT-02-02 (`changedFields = backends`) khi phiên bản đã công bố
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-022 @FR-02-022 @M @âm
  Kịch bản: US-02-022 âm 1 · Kết nối hoặc luồng không tồn tại hoặc khác HTTT
    Biết phiên bản `DRAFT`; với loại `SYSTEM`, kết nối PH-05 đã được cấp cho API; với loại `FLOW`, luồng đã có điểm vào REST ở PH-04
    Khi kết nối hoặc luồng không tồn tại hoặc khác HTTT
    Thì hệ thống từ chối với ERR-02-020 (422)
    Và người dùng thấy thông báo "Backend không hợp lệ: {lý do}."

  @US-02-022 @FR-02-022 @M @âm
  Kịch bản: US-02-022 âm 2 · Đích ngoài danh sách cho phép
    Biết phiên bản `DRAFT`; với loại `SYSTEM`, kết nối PH-05 đã được cấp cho API; với loại `FLOW`, luồng đã có điểm vào REST ở PH-04
    Khi đích ngoài danh sách cho phép
    Thì hệ thống từ chối với ERR-02-020 (422)
    Và người dùng thấy thông báo "Đích {máy chủ} chưa có trong danh sách đích cho phép. Đề nghị quản trị tenant bổ sung."

  @US-02-023 @FR-02-023 @M
  Kịch bản: US-02-023 dương · Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe backend
    Biết phiên bản `DRAFT` có ít nhất một backend (FR-02-022)
    Khi người dùng sửa khối "Cân bằng tải và sức khỏe" ở tab Backend của UI-02-02
    Thì hệ thống trả `200`, `ETag` mới; cấu hình backend sau cập nhật
    Và cấu hình backend lưu; chờ công bố để có hiệu lực
    Và sự kiện được phát: EVT-02-02 khi phiên bản đã công bố
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-023 @FR-02-023 @M @âm
  Kịch bản: US-02-023 âm 1 · Giá trị ngoài miền
    Biết phiên bản `DRAFT` có ít nhất một backend (FR-02-022)
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Giá trị {tên trường} nằm ngoài khoảng cho phép {a}…{b}."

  @US-02-023 @FR-02-023 @M @âm
  Kịch bản: US-02-023 âm 2 · Vượt trần tenant
    Biết phiên bản `DRAFT` có ít nhất một backend (FR-02-022)
    Khi vượt trần tenant
    Thì hệ thống từ chối với ERR-02-040 (422)
    Và người dùng thấy thông báo "Thời gian chờ vượt trần {n} ms của tỉnh."

  @US-02-024 @FR-02-024 @M
  Kịch bản: US-02-024 dương · Quản lý context-path và kiểm tra trùng
    Biết phiên bản `DRAFT`; API đã có nhóm
    Khi hệ thống tự đề xuất khi tạo phiên bản; người dùng bấm "Đổi đường dẫn" hoặc gõ ở bước 1 của UI-02-03 (kiểm tra ngay khi gõ)
    Thì hệ thống trả `200`; `contextPath`, `available`, `conflicts[]` (khi kiểm tra); khi lưu: `200` với phiên bản sau cập nhật
    Và `contextPath` lưu, chưa tạo route cho tới khi công bố
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-024 @FR-02-024 @M @âm
  Kịch bản: US-02-024 âm 1 · Trùng hoặc xung đột
    Biết phiên bản `DRAFT`; API đã có nhóm
    Khi trùng hoặc xung đột
    Thì hệ thống từ chối với ERR-02-019 (422)
    Và người dùng thấy thông báo "Đường dẫn {đường dẫn} đã được dùng hoặc xung đột với {đường dẫn khác}."

  @US-02-024 @FR-02-024 @M @âm
  Kịch bản: US-02-024 âm 2 · Sai quy ước
    Biết phiên bản `DRAFT`; API đã có nhóm
    Khi sai quy ước
    Thì hệ thống từ chối với ERR-02-019 (422)
    Và người dùng thấy thông báo "Đường dẫn phải dạng /{nhóm}/{mã API}/v{số chính}, chữ thường, gạch ngang."

  @US-02-025 @FR-02-025 @S
  Kịch bản: US-02-025 dương · Xem sức khỏe backend
    Biết phiên bản `PUBLISHED`, `SUSPENDED` hoặc `DEPRECATED`; PH-03 đang chạy
    Khi người dùng mở tab Backend của UI-02-02 (làm mới 30 giây)
    Thì hệ thống trả `200`; `overall`, `backends[]` (`backendCode`, `status`, `since`, `errorRate`, `p95Ms`, nút), `asOf`

  @US-02-025 @FR-02-025 @S @âm
  Kịch bản: US-02-025 âm 1 · PH-03 không khả dụng
    Biết phiên bản `PUBLISHED`, `SUSPENDED` hoặc `DEPRECATED`; PH-03 đang chạy
    Khi PH-03 không khả dụng
    Thì hệ thống từ chối với ERR-02-034 (503)
    Và người dùng thấy thông báo "Chưa lấy được trạng thái từ cổng API. Thử lại sau."

  @US-02-026 @FR-02-026 @M
  Kịch bản: US-02-026 dương · Sinh khung route cho PH-04 từ đặc tả
    Biết phiên bản `DRAFT` đạt lớp 1; người dùng chọn không gian làm việc PH-04 mà mình có quyền; PH-04 khả dụng
    Khi người dùng bấm "Tạo luồng từ API này" ở tab Backend của UI-02-02
    Thì hệ thống trả `202` kèm `operationId`; khi xong: `flowCode`, `designerUrl`, `generatedRoutes`, `pendingFill` (số chỗ cần điền)
    Và luồng nháp được tạo ở PH-04; backend `FLOW` ở trạng thái `PLACEHOLDER`
    Và sự kiện được phát: EVT-02-02 (`changedFields = backends`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-026 @FR-02-026 @M @âm
  Kịch bản: US-02-026 âm 1 · PH-04 không khả dụng
    Biết phiên bản `DRAFT` đạt lớp 1; người dùng chọn không gian làm việc PH-04 mà mình có quyền; PH-04 khả dụng
    Khi PH-04 không khả dụng
    Thì hệ thống từ chối với ERR-02-034 (503)
    Và người dùng thấy thông báo "Chưa tạo được luồng vì phân hệ Tích hợp chưa sẵn sàng. Yêu cầu đã được xếp hàng."

  @US-02-026 @FR-02-026 @M @âm
  Kịch bản: US-02-026 âm 2 · `flowCode` đã dùng
    Biết phiên bản `DRAFT` đạt lớp 1; người dùng chọn không gian làm việc PH-04 mà mình có quyền; PH-04 khả dụng
    Khi `flowCode` đã dùng
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "Mã luồng {mã} đã được dùng. Chọn mã khác."

  # ---- EP-02-E · Gói sử dụng

  @US-02-027 @FR-02-027 @M
  Kịch bản: US-02-027 dương · Tạo gói sử dụng: thông tin và điều kiện truy cập
    Biết phiên bản ở `DRAFT` hoặc `PUBLISHED` (gói mới thêm cho phiên bản đã công bố đi qua duyệt, FR-02-030); chưa vượt số gói tối đa mỗi phiên bản (mặc định 10)
    Khi người dùng bấm "+ Tạo gói" ở tab Gói sử dụng của UI-02-02 hoặc ở UI-02-06, mở UI-02-07
    Thì hệ thống trả `201`, tiêu đề `Location`, `ETag`; chi tiết gói: `planCode`, `status = STAGING`, `audience`, `autoApprove`, `validityMonths`, các trường chờ khai (xác thực, hạn mức)
    Và gói `STAGING` được tạo; chưa nhận đăng ký, chưa có cấu hình ở gateway
    Và sự kiện được phát: EVT-02-08 (`plan.state-changed`, trạng thái đầu `STAGING`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-027 @FR-02-027 @M @âm
  Kịch bản: US-02-027 âm 1 · Mã gói đã dùng
    Biết phiên bản ở `DRAFT` hoặc `PUBLISHED` (gói mới thêm cho phiên bản đã công bố đi qua duyệt, FR-02-030); chưa vượt số gói tối đa mỗi phiên bản (mặc định 10)
    Khi mã gói đã dùng
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "Mã gói {mã} đã được dùng. Chọn mã khác."

  @US-02-027 @FR-02-027 @M @âm
  Kịch bản: US-02-027 âm 2 · Vượt số gói tối đa
    Biết phiên bản ở `DRAFT` hoặc `PUBLISHED` (gói mới thêm cho phiên bản đã công bố đi qua duyệt, FR-02-030); chưa vượt số gói tối đa mỗi phiên bản (mặc định 10)
    Khi vượt số gói tối đa
    Thì hệ thống từ chối với ERR-02-040 (422)
    Và người dùng thấy thông báo "Phiên bản đã đạt số gói tối đa ({n})."

  @US-02-028 @FR-02-028 @M
  Kịch bản: US-02-028 dương · Chọn kiểu xác thực của gói
    Biết gói `STAGING` (gói `PUBLISHED` đổi xác thực theo BR-02-017: chỉ nâng mức mạnh hơn bằng gói mới)
    Khi người dùng chọn kiểu xác thực ở phần "Bảo mật" của UI-02-07
    Thì hệ thống trả `200`, `ETag` mới; gói với `authType`, `scopeTemplate`, `operationScopes[]`
    Và `authType` lưu; khuôn phạm vi gắn với gói
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-028 @FR-02-028 @M @âm
  Kịch bản: US-02-028 âm 1 · Kiểu xác thực không phù hợp mức phân loại
    Biết gói `STAGING` (gói `PUBLISHED` đổi xác thực theo BR-02-017: chỉ nâng mức mạnh hơn bằng gói mới)
    Khi kiểu xác thực không phù hợp mức phân loại
    Thì hệ thống từ chối với ERR-02-022 (422)
    Và người dùng thấy thông báo "Dữ liệu mức {mức} yêu cầu xác thực {kiểu tối thiểu}. Chọn kiểu mạnh hơn."

  @US-02-028 @FR-02-028 @M @âm
  Kịch bản: US-02-028 âm 2 · `KEYLESS` cho API không phải `PUBLIC` hoặc mức hiển thị không phải `PUBLIC`
    Biết gói `STAGING` (gói `PUBLISHED` đổi xác thực theo BR-02-017: chỉ nâng mức mạnh hơn bằng gói mới)
    Khi `KEYLESS` cho API không phải `PUBLIC` hoặc mức hiển thị không phải `PUBLIC`
    Thì hệ thống từ chối với ERR-02-022 (422)
    Và người dùng thấy thông báo "Chỉ API dữ liệu công khai mới được gọi không cần xác thực."

  @US-02-029 @FR-02-029 @M
  Kịch bản: US-02-029 dương · Khai báo hạn mức và đường dẫn cho phép của gói
    Biết gói `STAGING`; đặc tả của phiên bản đã đạt lớp 1
    Khi người dùng nhập phần "Hạn mức và đường dẫn" ở UI-02-07
    Thì hệ thống trả `200`, `ETag` mới; gói với khai báo hạn mức, thao tác, cờ cảnh báo SLA
    Và khai báo lưu; chưa có hiệu lực ở gateway cho tới khi công bố
    Và sự kiện được phát: EVT-02-08 chỉ khi gói đã `PUBLISHED` (`changedFields`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-029 @FR-02-029 @M @âm
  Kịch bản: US-02-029 âm 1 · Giá trị sai thứ tự
    Biết gói `STAGING`; đặc tả của phiên bản đã đạt lớp 1
    Khi giá trị sai thứ tự
    Thì hệ thống từ chối với ERR-02-023 (422)
    Và người dùng thấy thông báo "Hạn mức không hợp lý: {mô tả}."

  @US-02-029 @FR-02-029 @M @âm
  Kịch bản: US-02-029 âm 2 · Thao tác không có trong đặc tả
    Biết gói `STAGING`; đặc tả của phiên bản đã đạt lớp 1
    Khi thao tác không có trong đặc tả
    Thì hệ thống từ chối với ERR-02-037 (422)
    Và người dùng thấy thông báo "Thao tác {operationId} không có trong đặc tả."

  @US-02-030 @FR-02-030 @M
  Kịch bản: US-02-030 dương · Công bố gói (STAGING sang PUBLISHED)
    Biết gói `STAGING` đã khai đủ xác thực và hạn mức; phiên bản `PUBLISHED`, hoặc `PENDING` trong cùng đợt duyệt
    Khi người dùng bấm "Gửi duyệt gói" ở UI-02-06, hoặc hệ thống chuyển cùng phiên bản khi FR-02-035 duyệt
    Thì hệ thống trả `202` khi gửi (`reviewRequestId`); `200` khi duyệt; gói với `status = PUBLISHED`
    Và gói `PUBLISHED`; cấu hình gói có ở gateway
    Và sự kiện được phát: EVT-02-08 (`plan.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-030 @FR-02-030 @M @âm
  Kịch bản: US-02-030 âm 1 · Gói chưa đủ điều kiện
    Biết gói `STAGING` đã khai đủ xác thực và hạn mức; phiên bản `PUBLISHED`, hoặc `PENDING` trong cùng đợt duyệt
    Khi gói chưa đủ điều kiện
    Thì hệ thống từ chối với ERR-02-012 (409)
    Và người dùng thấy thông báo "Gói còn thiếu: {danh sách}."

  @US-02-030 @FR-02-030 @M @âm
  Kịch bản: US-02-030 âm 2 · Người gửi tự duyệt
    Biết gói `STAGING` đã khai đủ xác thực và hạn mức; phiên bản `PUBLISHED`, hoặc `PENDING` trong cùng đợt duyệt
    Khi người gửi tự duyệt
    Thì hệ thống từ chối với ERR-02-013 (403)
    Và người dùng thấy thông báo "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."

  @US-02-031 @FR-02-031 @M
  Kịch bản: US-02-031 dương · Ngừng khuyến nghị gói
    Biết gói `PUBLISHED`
    Khi người dùng bấm "Ngừng khuyến nghị" ở UI-02-06
    Thì hệ thống trả `202` khi gửi; `200` khi duyệt; gói `DEPRECATED` kèm `successorPlanCode`, `sunsetAt`, số bên chưa chuyển
    Và gói `DEPRECATED`; cấu hình gateway thêm tiêu đề cảnh báo cho lượt gọi theo gói
    Và sự kiện được phát: EVT-02-08; EVT-02-12 (`change.notice-issued`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-031 @FR-02-031 @M @âm
  Kịch bản: US-02-031 âm 1 · Gói không `PUBLISHED`
    Biết gói `PUBLISHED`
    Khi gói không `PUBLISHED`
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Chỉ gói đang công bố mới ngừng khuyến nghị được."

  @US-02-031 @FR-02-031 @M @âm
  Kịch bản: US-02-031 âm 2 · Hạn quá ngắn khi còn đăng ký
    Biết gói `PUBLISHED`
    Khi hạn quá ngắn khi còn đăng ký
    Thì hệ thống từ chối với ERR-02-031 (422)
    Và người dùng thấy thông báo "Hạn chuyển đổi tối thiểu {n} ngày kể từ hôm nay."

  @US-02-032 @FR-02-032 @M
  Kịch bản: US-02-032 dương · Đóng gói
    Biết gói `STAGING` (hủy) hoặc `DEPRECATED` (đóng) và không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-019)
    Khi người dùng bấm "Hủy gói" hoặc "Đóng gói" ở UI-02-06
    Thì hệ thống trả `204` (hủy gói nháp); `202` rồi `200` (đóng gói qua duyệt); gói `CLOSED`
    Và gói `CLOSED` hoặc xóa mềm; cấu hình gói đã gỡ ở gateway
    Và sự kiện được phát: EVT-02-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-032 @FR-02-032 @M @âm
  Kịch bản: US-02-032 âm 1 · Còn đăng ký đang hiệu lực
    Biết gói `STAGING` (hủy) hoặc `DEPRECATED` (đóng) và không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-019)
    Khi còn đăng ký đang hiệu lực
    Thì hệ thống từ chối với ERR-02-024 (409)
    Và người dùng thấy thông báo "Còn {n} đăng ký đang dùng gói này. Chuyển hoặc thu hồi trước khi đóng."

  @US-02-032 @FR-02-032 @M @âm
  Kịch bản: US-02-032 âm 2 · Gói đang `PUBLISHED`
    Biết gói `STAGING` (hủy) hoặc `DEPRECATED` (đóng) và không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-019)
    Khi gói đang `PUBLISHED`
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Ngừng khuyến nghị gói trước khi đóng."

  @US-02-033 @FR-02-033 @S
  Kịch bản: US-02-033 dương · Sao chép gói sang phiên bản mới
    Biết phiên bản đích `DRAFT`; phiên bản nguồn cùng API
    Khi hệ thống đề xuất khi tạo phiên bản (FR-02-042); hoặc người dùng bấm "Sao chép gói từ phiên bản khác" ở UI-02-06
    Thì hệ thống trả `201`; `plans[]` mới tạo với `warnings[]`
    Và gói `STAGING` mới ở phiên bản đích
    Và sự kiện được phát: EVT-02-08 cho từng gói
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-033 @FR-02-033 @S @âm
  Kịch bản: US-02-033 âm 1 · Mã gói trùng ở phiên bản đích
    Biết phiên bản đích `DRAFT`; phiên bản nguồn cùng API
    Khi mã gói trùng ở phiên bản đích
    Thì hệ thống từ chối với ERR-02-002 (409)
    Và người dùng thấy thông báo "Phiên bản đích đã có gói {mã}. Bỏ chọn hoặc đổi mã."

  # ---- EP-02-F · Vòng đời, duyệt và phiên bản

  @US-02-034 @FR-02-034 @M
  Kịch bản: US-02-034 dương · Gửi duyệt công bố API
    Biết phiên bản `DRAFT`
    Khi người dùng bấm "Gửi duyệt" ở UI-02-02, hoặc "Lưu và gửi duyệt" ở UI-02-03
    Thì hệ thống trả `202`, `reviewRequestId`; phiên bản `PENDING`, `ETag` mới
    Và phiên bản `PENDING`; yêu cầu duyệt `PENDING`; đặc tả, backend, gói, SLA bị khóa đến khi có quyết định
    Và sự kiện được phát: EVT-02-04 (`version.submitted`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-034 @FR-02-034 @M @âm
  Kịch bản: US-02-034 âm 1 · Đặc tả còn lỗi
    Biết phiên bản `DRAFT`
    Khi đặc tả còn lỗi
    Thì hệ thống từ chối với ERR-02-006, ERR-02-007, ERR-02-008 (422)
    Và người dùng thấy thông báo "Đặc tả còn lỗi, mở kết quả kiểm tra để xem hướng dẫn sửa."

  @US-02-034 @FR-02-034 @M @âm
  Kịch bản: US-02-034 âm 2 · Thiếu điều kiện
    Biết phiên bản `DRAFT`
    Khi thiếu điều kiện
    Thì hệ thống từ chối với ERR-02-012 (409)
    Và người dùng thấy thông báo "Chưa đủ điều kiện gửi duyệt: {danh sách}."

  @US-02-035 @FR-02-035 @M
  Kịch bản: US-02-035 dương · Duyệt hoặc từ chối công bố (bốn mắt)
    Biết có yêu cầu duyệt ở trạng thái `PENDING`; loại yêu cầu thuộc `VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, `PLAN_CLOSE`, `SUBSCRIPTION_RENEW`
    Khi người duyệt mở yêu cầu từ "Việc của tôi" (UI-02-10, `/viec-cua-toi`)
    Thì hệ thống trả `200`; yêu cầu duyệt với `decision`, `decidedBy`, `decidedAt`; đối tượng sau hành động (nếu duyệt, ví dụ phiên bản `PENDING` chuyển sang bước công bố)
    Và yêu cầu duyệt `APPROVED` hoặc `REJECTED`; đối tượng chuyển theo hành động, nếu bị trả lại thì về `DRAFT` hoặc `STAGING`
    Và sự kiện được phát: Tùy loại: EVT-02-05, EVT-02-06, EVT-02-08, EVT-02-11 (xem từng FR liên quan)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-035 @FR-02-035 @M @âm
  Kịch bản: US-02-035 âm 1 · Vi phạm bốn mắt
    Biết có yêu cầu duyệt ở trạng thái `PENDING`; loại yêu cầu thuộc `VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, `PLAN_CLOSE`, `SUBSCRIPTION_RENEW`
    Khi vi phạm bốn mắt
    Thì hệ thống từ chối với ERR-02-013 (403)
    Và người dùng thấy thông báo "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."

  @US-02-035 @FR-02-035 @M @âm
  Kịch bản: US-02-035 âm 2 · Từ chối không có lý do
    Biết có yêu cầu duyệt ở trạng thái `PENDING`; loại yêu cầu thuộc `VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, `PLAN_CLOSE`, `SUBSCRIPTION_RENEW`
    Khi từ chối không có lý do
    Thì hệ thống từ chối với ERR-02-041 (400)
    Và người dùng thấy thông báo "Cần nêu lý do khi trả lại."

  @US-02-036 @FR-02-036 @M
  Kịch bản: US-02-036 dương · Công bố API ra gateway và danh mục
    Biết chế độ môi trường thật: yêu cầu duyệt đủ quyết định `APPROVE`
    Khi sau quyết định duyệt cuối của FR-02-035; hoặc người dùng bấm "Thử trên TEST"; hoặc TO bấm "Thử lại công bố" (API-02-047)
    Thì hệ thống trả `200` (đã công bố) hoặc `202` (đang đẩy cấu hình): `status`, `publishedAt`, `gatewayConfigVersion`, `publishedUrl`
    Và phiên bản `PUBLISHED`; route, upstream, consumer có ở gateway; bản ghi đồng bộ quốc gia đã xếp (nếu có); phiên bản cũ cùng số chính (nếu có) đã `RETIRED`
    Và sự kiện được phát: EVT-02-05 (`version.published`); EVT-02-06 cho phiên bản cũ (nếu `RETIRED`); EVT-02-12 (thông báo bên khai thác khi có phiên bản thay thế)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-036 @FR-02-036 @M @âm
  Kịch bản: US-02-036 âm 1 · PH-03 hoặc APISIX không xác nhận trong 30 giây
    Biết chế độ môi trường thật: yêu cầu duyệt đủ quyết định `APPROVE`
    Khi PH-03 hoặc APISIX không xác nhận trong 30 giây
    Thì hệ thống từ chối với ERR-02-033 (503)
    Và người dùng thấy thông báo "Cổng API chưa nhận cấu hình, hệ thống đang thử lại."

  @US-02-036 @FR-02-036 @M @âm
  Kịch bản: US-02-036 âm 2 · Xung đột context-path phát sinh sau khi duyệt
    Biết chế độ môi trường thật: yêu cầu duyệt đủ quyết định `APPROVE`
    Khi xung đột context-path phát sinh sau khi duyệt
    Thì hệ thống từ chối với ERR-02-019 (422)

  @US-02-037 @FR-02-037 @M
  Kịch bản: US-02-037 dương · Tạm ngừng và tiếp tục API
    Biết phiên bản `PUBLISHED` (tạm ngừng) hoặc `SUSPENDED` (tiếp tục)
    Khi người dùng bấm "Tạm ngừng" hoặc "Tiếp tục" ở UI-02-02
    Thì hệ thống trả `200`; phiên bản `SUSPENDED` hoặc `PUBLISHED`, `suspendDeadline`
    Và trạng thái đổi; cấu hình gateway cập nhật; đăng ký không đổi
    Và sự kiện được phát: EVT-02-06 (`version.state-changed`); EVT-02-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-037 @FR-02-037 @M @âm
  Kịch bản: US-02-037 âm 1 · Phiên bản không `PUBLISHED`
    Biết phiên bản `PUBLISHED` (tạm ngừng) hoặc `SUSPENDED` (tiếp tục)
    Khi phiên bản không `PUBLISHED`
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Chỉ API đang công bố mới tạm ngừng được."

  @US-02-037 @FR-02-037 @M @âm
  Kịch bản: US-02-037 âm 2 · Thiếu lý do
    Biết phiên bản `PUBLISHED` (tạm ngừng) hoặc `SUSPENDED` (tiếp tục)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-02-041 (400)
    Và người dùng thấy thông báo "Cần nêu lý do tạm ngừng."

  @US-02-038 @FR-02-038 @M
  Kịch bản: US-02-038 dương · Ngừng khuyến nghị API có lộ trình
    Biết phiên bản `PUBLISHED` hoặc `SUSPENDED`
    Khi người dùng bấm "Ngừng khuyến nghị" ở UI-02-02, mở UI-02-13 (lộ trình ngừng dùng)
    Thì hệ thống trả `202` khi gửi (`reviewRequestId`); `200` khi duyệt; phiên bản `DEPRECATED` kèm `sunsetAt`, `successorVersionNo`, số bên chưa chuyển
    Và phiên bản `DEPRECATED` có lộ trình; gói `DEPRECATED`; lịch nhắc đã đặt
    Và sự kiện được phát: EVT-02-06; EVT-02-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-038 @FR-02-038 @M @âm
  Kịch bản: US-02-038 âm 1 · Thiếu kế nhiệm mà không xác nhận
    Biết phiên bản `PUBLISHED` hoặc `SUSPENDED`
    Khi thiếu kế nhiệm mà không xác nhận
    Thì hệ thống từ chối với ERR-02-032 (422)
    Và người dùng thấy thông báo "Chưa có phiên bản kế nhiệm. Chọn phiên bản kế nhiệm hoặc xác nhận ngừng hẳn dịch vụ."

  @US-02-038 @FR-02-038 @M @âm
  Kịch bản: US-02-038 âm 2 · Hạn quá ngắn
    Biết phiên bản `PUBLISHED` hoặc `SUSPENDED`
    Khi hạn quá ngắn
    Thì hệ thống từ chối với ERR-02-031 (422)
    Và người dùng thấy thông báo "Hạn chuyển đổi tối thiểu {n} ngày. Chọn ngày muộn hơn {ngày}."

  @US-02-039 @FR-02-039 @M
  Kịch bản: US-02-039 dương · Ngừng hẳn API
    Biết phiên bản `DEPRECATED` đã tới hạn `sunsetAt` hoặc người đề nghị chọn ngừng sớm; hoặc phiên bản `DRAFT` (hủy nháp)
    Khi hệ thống đưa ra đề nghị khi tới hạn `sunsetAt`; hoặc người dùng bấm "Ngừng hẳn" ở UI-02-13; hoặc "Hủy bản nháp" ở UI-02-02
    Thì hệ thống trả `202` khi gửi; `200` khi duyệt; phiên bản `RETIRED`
    Và phiên bản `RETIRED`; route, consumer đã gỡ; gói `CLOSED`; context-path được giữ chỗ; đặc tả giữ vĩnh viễn
    Và sự kiện được phát: EVT-02-06; EVT-02-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-039 @FR-02-039 @M @âm
  Kịch bản: US-02-039 âm 1 · Còn đăng ký hiệu lực
    Biết phiên bản `DEPRECATED` đã tới hạn `sunsetAt` hoặc người đề nghị chọn ngừng sớm; hoặc phiên bản `DRAFT` (hủy nháp)
    Khi còn đăng ký hiệu lực
    Thì hệ thống từ chối với ERR-02-030 (409)
    Và người dùng thấy thông báo "Còn {n} bên đang dùng phiên bản này. Chuyển hoặc thu hồi đăng ký trước, hoặc lùi hạn ngừng."

  @US-02-039 @FR-02-039 @M @âm
  Kịch bản: US-02-039 âm 2 · Phiên bản không `DEPRECATED` hoặc `DRAFT`
    Biết phiên bản `DEPRECATED` đã tới hạn `sunsetAt` hoặc người đề nghị chọn ngừng sớm; hoặc phiên bản `DRAFT` (hủy nháp)
    Khi phiên bản không `DEPRECATED` hoặc `DRAFT`
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Chỉ phiên bản đã ngừng khuyến nghị mới ngừng hẳn được."

  @US-02-040 @FR-02-040 @M
  Kịch bản: US-02-040 dương · Xóa API
    Biết mọi phiên bản của API ở `DRAFT` hoặc `RETIRED`; không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-020)
    Khi người dùng bấm "Xóa API" ở UI-02-02 (menu "⋯")
    Thì hệ thống trả `204`
    Và API xóa mềm; mã giữ chỗ; thông báo rút danh mục quốc gia đã xếp
    Và sự kiện được phát: EVT-02-03 (`api.deleted`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-040 @FR-02-040 @M @âm
  Kịch bản: US-02-040 âm 1 · Còn phiên bản đang chạy hoặc còn đăng ký
    Biết mọi phiên bản của API ở `DRAFT` hoặc `RETIRED`; không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-020)
    Khi còn phiên bản đang chạy hoặc còn đăng ký
    Thì hệ thống từ chối với ERR-02-030 (409)
    Và người dùng thấy thông báo "API còn phiên bản đang phục vụ hoặc còn {n} bên đăng ký. Ngừng dùng có báo trước trước khi xóa."

  @US-02-040 @FR-02-040 @M @âm
  Kịch bản: US-02-040 âm 2 · Gõ sai mã xác nhận
    Biết mọi phiên bản của API ở `DRAFT` hoặc `RETIRED`; không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-020)
    Khi gõ sai mã xác nhận
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Mã xác nhận không khớp."

  @US-02-041 @FR-02-041 @M
  Kịch bản: US-02-041 dương · Đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` (với phiên bản nháp, mức hiển thị chỉ là dự định)
    Khi người dùng sửa khối "Hiển thị" ở UI-02-02
    Thì hệ thống trả `200`; API với `visibility`, `portalPublished`; hoặc `202` khi chờ duyệt nâng mức
    Và `visibility`, `portalPublished` cập nhật; đồng bộ quốc gia xếp hàng khi cần
    Và sự kiện được phát: EVT-02-02 (`changedFields = visibility, portalPublished`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-041 @FR-02-041 @M @âm
  Kịch bản: US-02-041 âm 1 · Mức không phù hợp mức phân loại
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` (với phiên bản nháp, mức hiển thị chỉ là dự định)
    Khi mức không phù hợp mức phân loại
    Thì hệ thống từ chối với ERR-02-043 (422)
    Và người dùng thấy thông báo "Mức hiển thị {mức} không phù hợp với dữ liệu mức {phân loại}."

  @US-02-041 @FR-02-041 @M @âm
  Kịch bản: US-02-041 âm 2 · Nâng mức khi thiếu lý do
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` (với phiên bản nháp, mức hiển thị chỉ là dự định)
    Khi nâng mức khi thiếu lý do
    Thì hệ thống từ chối với ERR-02-041 (400)
    Và người dùng thấy thông báo "Cần nêu lý do nâng mức hiển thị."

  @US-02-042 @FR-02-042 @M
  Kịch bản: US-02-042 dương · Tạo phiên bản mới
    Biết API có phiên bản nguồn ở trạng thái `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED`; không có phiên bản `DRAFT` hoặc `PENDING` khác của API (mỗi API chỉ một bản đang soạn)
    Khi người dùng bấm "Tạo phiên bản mới" ở tab Phiên bản của UI-02-02
    Thì hệ thống trả `201`, tiêu đề `Location`; phiên bản mới `DRAFT` kèm các thành phần đã sao chép
    Và phiên bản `DRAFT` mới; phiên bản nguồn không đổi
    Và sự kiện được phát: EVT-02-02 (`changedFields = versions`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-042 @FR-02-042 @M @âm
  Kịch bản: US-02-042 âm 1 · Đã có bản nháp khác
    Biết API có phiên bản nguồn ở trạng thái `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED`; không có phiên bản `DRAFT` hoặc `PENDING` khác của API (mỗi API chỉ một bản đang soạn)
    Khi đã có bản nháp khác
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "API đã có phiên bản đang soạn {số}. Hoàn tất hoặc hủy bản đó trước."

  @US-02-042 @FR-02-042 @M @âm
  Kịch bản: US-02-042 âm 2 · Số hiệu không hợp lệ hoặc không tăng
    Biết API có phiên bản nguồn ở trạng thái `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED`; không có phiên bản `DRAFT` hoặc `PENDING` khác của API (mỗi API chỉ một bản đang soạn)
    Khi số hiệu không hợp lệ hoặc không tăng
    Thì hệ thống từ chối với ERR-02-018 (422)
    Và người dùng thấy thông báo "Số phiên bản phải dạng MAJOR.MINOR.PATCH và lớn hơn {số hiện có}."

  @US-02-043 @FR-02-043 @M
  Kịch bản: US-02-043 dương · So sánh phiên bản và phân loại thay đổi phá vỡ
    Biết hai phiên bản của cùng API đều có đặc tả đạt lớp 1
    Khi người dùng mở UI-02-05 (`/ket-noi/api/{ma}/so-sanh?tu=&den=`); hệ thống tự chạy khi gửi duyệt (FR-02-034 bước 4)
    Thì hệ thống trả `200`; `breaking`, `versionViolation`, `suggestedVersion`, `changes[]` (`class`, `kind`, `location`, `description`, `impact`), `uncertainCount`
    Và kết quả so sánh gắn với cặp phiên bản (giữ cùng yêu cầu duyệt)

  @US-02-043 @FR-02-043 @M @âm
  Kịch bản: US-02-043 âm 1 · Một trong hai phiên bản không có hoặc không có đặc tả hợp lệ
    Biết hai phiên bản của cùng API đều có đặc tả đạt lớp 1
    Khi một trong hai phiên bản không có hoặc không có đặc tả hợp lệ
    Thì hệ thống từ chối với ERR-02-001, ERR-02-006 (404)
    Và người dùng thấy thông báo "Cần đặc tả hợp lệ ở cả hai phiên bản để so sánh."

  @US-02-043 @FR-02-043 @M @âm
  Kịch bản: US-02-043 âm 2 · So sánh quá lâu (đặc tả rất lớn)
    Biết hai phiên bản của cùng API đều có đặc tả đạt lớp 1
    Khi so sánh quá lâu (đặc tả rất lớn)
    Thì hệ thống từ chối với ERR-02-035

  @US-02-044 @FR-02-044 @M
  Kịch bản: US-02-044 dương · Phân tích tác động của thay đổi tới bên khai thác
    Biết phiên bản có đăng ký hoặc lượt gọi; PH-13 sẵn sàng (nếu không, chỉ có phần đăng ký)
    Khi người dùng mở khối "Bên bị ảnh hưởng" ở UI-02-05, UI-02-13 hoặc ở bước duyệt UI-02-10; hệ thống tự gọi khi gửi duyệt ngừng khuyến nghị, ngừng hẳn
    Thì hệ thống trả `200`; `summary {registered, active, callers, affected}`, `affected[]` (`systemCode`, `orgCode`, `planCode`, `calls`, `errorRate`, `operations[]`, `contact`), `recommendation`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-044 @FR-02-044 @M @âm
  Kịch bản: US-02-044 âm 1 · PH-13 không khả dụng
    Biết phiên bản có đăng ký hoặc lượt gọi; PH-13 sẵn sàng (nếu không, chỉ có phần đăng ký)
    Khi PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-02-034 (503)
    Và người dùng thấy thông báo "Chưa có số lượt gọi; hiển thị theo đăng ký."

  @US-02-044 @FR-02-044 @M @âm
  Kịch bản: US-02-044 âm 2 · Phiên bản không có đăng ký
    Biết phiên bản có đăng ký hoặc lượt gọi; PH-13 sẵn sàng (nếu không, chỉ có phần đăng ký)
    Khi phiên bản không có đăng ký
    Thì trả danh sách rỗng, thông báo thông báo
    Và người dùng thấy thông báo "Chưa có bên nào đăng ký phiên bản này."

  @US-02-045 @FR-02-045 @S
  Kịch bản: US-02-045 dương · Chuyển chủ quản API
    Biết API chưa xóa; HTTT và đơn vị đích tồn tại và `ACTIVE` ở PH-01
    Khi TA chọn "Chuyển chủ quản" ở menu "⋯" của UI-02-02
    Thì hệ thống trả `200`; API với chủ quản mới và danh sách việc cần rà soát
    Và chủ quản đổi; quyền của SV theo đơn vị mới
    Và sự kiện được phát: EVT-02-02 (`changedFields = ownerOrgCode, providerSystemCode`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-045 @FR-02-045 @S @âm
  Kịch bản: US-02-045 âm 1 · HTTT hoặc đơn vị đích không hợp lệ
    Biết API chưa xóa; HTTT và đơn vị đích tồn tại và `ACTIVE` ở PH-01
    Khi HTTT hoặc đơn vị đích không hợp lệ
    Thì hệ thống từ chối với ERR-02-004 (422)
    Và người dùng thấy thông báo "HTTT hoặc đơn vị đích không tồn tại hoặc chưa hoạt động."

  # ---- EP-02-G · Đăng ký sử dụng

  @US-02-046 @FR-02-046 @M
  Kịch bản: US-02-046 dương · Gửi đăng ký sử dụng API
    Biết HTTT khai thác `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; phiên bản API `PUBLISHED` (hoặc `DEPRECATED` có cảnh báo) và gói `PUBLISHED` có HTTT trong đối tượng được xin
    Khi người dùng bấm "Đăng ký sử dụng" ở UI-02-01 hoặc UI-02-02, mở UI-02-09
    Thì hệ thống trả `201`, tiêu đề `Location`; đăng ký với `status` (`PENDING` hoặc `ACTIVE`), `reviewRequestId`, `warnings[]`
    Và đăng ký `PENDING` kèm yêu cầu duyệt, hoặc `ACTIVE` kèm tiến trình cấp phạm vi
    Và sự kiện được phát: EVT-02-09 (`subscription.requested`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-046 @FR-02-046 @M @âm
  Kịch bản: US-02-046 âm 1 · HTTT chưa kết nối hoặc không hoạt động
    Biết HTTT khai thác `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; phiên bản API `PUBLISHED` (hoặc `DEPRECATED` có cảnh báo) và gói `PUBLISHED` có HTTT trong đối tượng được xin
    Khi HTTT chưa kết nối hoặc không hoạt động
    Thì hệ thống từ chối với ERR-02-026 (422)
    Và người dùng thấy thông báo "HTTT {mã} chưa được kết nạp hoặc không hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước."

  @US-02-046 @FR-02-046 @M @âm
  Kịch bản: US-02-046 âm 2 · Gói không nhận đăng ký
    Biết HTTT khai thác `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; phiên bản API `PUBLISHED` (hoặc `DEPRECATED` có cảnh báo) và gói `PUBLISHED` có HTTT trong đối tượng được xin
    Khi gói không nhận đăng ký
    Thì hệ thống từ chối với ERR-02-025 (409)
    Và người dùng thấy thông báo "Gói {mã} không nhận đăng ký mới. Chọn gói khác."

  @US-02-047 @FR-02-047 @M
  Kịch bản: US-02-047 dương · Duyệt hoặc từ chối đăng ký sử dụng
    Biết đăng ký `PENDING`; yêu cầu duyệt loại `SUBSCRIPTION`
    Khi người duyệt mở yêu cầu từ "Việc của tôi" (UI-02-10), hoặc từ tab Đăng ký của UI-02-02
    Thì hệ thống trả `200`; đăng ký với `status`, `decidedBy`, `expiresAt`, `grantStatus` (`PENDING`, `GRANTED`)
    Và đăng ký `ACTIVE` hoặc `REJECTED`; yêu cầu duyệt đóng
    Và sự kiện được phát: EVT-02-10 (`subscription.activated`) khi duyệt và cấp thành công; EVT-02-11 khi từ chối
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-047 @FR-02-047 @M @âm
  Kịch bản: US-02-047 âm 1 · Vi phạm bốn mắt
    Biết đăng ký `PENDING`; yêu cầu duyệt loại `SUBSCRIPTION`
    Khi vi phạm bốn mắt
    Thì hệ thống từ chối với ERR-02-013 (403)
    Và người dùng thấy thông báo "Bạn là người gửi đăng ký này nên không được tự duyệt."

  @US-02-047 @FR-02-047 @M @âm
  Kịch bản: US-02-047 âm 2 · Từ chối không có lý do
    Biết đăng ký `PENDING`; yêu cầu duyệt loại `SUBSCRIPTION`
    Khi từ chối không có lý do
    Thì hệ thống từ chối với ERR-02-041 (400)
    Và người dùng thấy thông báo "Cần nêu lý do từ chối."

  @US-02-048 @FR-02-048 @M
  Kịch bản: US-02-048 dương · Cấp phạm vi truy cập theo đăng ký đã duyệt
    Biết đăng ký `ACTIVE` chưa có `grantStatus = GRANTED`; HTTT khai thác có định danh máy ở PH-01 (client Keycloak, và chứng thư với `OAUTH2_MTLS`)
    Khi sau FR-02-047 duyệt, hoặc tự duyệt ở FR-02-046; khi TO bấm "Cấp lại" (API-02-068)
    Thì hệ thống trả `200` hoặc `202`; `grantStatus`, `scopes[]`, `grantedAt`, `failures[]`
    Và phạm vi gắn ở Keycloak; consumer gắn ở gateway; đăng ký `GRANTED`
    Và sự kiện được phát: EVT-02-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-048 @FR-02-048 @M @âm
  Kịch bản: US-02-048 âm 1 · HTTT chưa có định danh máy
    Biết đăng ký `ACTIVE` chưa có `grantStatus = GRANTED`; HTTT khai thác có định danh máy ở PH-01 (client Keycloak, và chứng thư với `OAUTH2_MTLS`)
    Khi HTTT chưa có định danh máy
    Thì `AWAITING_CREDENTIAL` (không phải lỗi), thông báo cho OR; tiếp tục tự động khi PH-01 cấp xong

  @US-02-048 @FR-02-048 @M @âm
  Kịch bản: US-02-048 âm 2 · PH-12 hoặc PH-03 không khả dụng
    Biết đăng ký `ACTIVE` chưa có `grantStatus = GRANTED`; HTTT khai thác có định danh máy ở PH-01 (client Keycloak, và chứng thư với `OAUTH2_MTLS`)
    Khi PH-12 hoặc PH-03 không khả dụng
    Thì hệ thống từ chối với ERR-02-033, ERR-02-034 (503)
    Và người dùng thấy thông báo "Quyền của HTTT đang được cấp, thử lại sau ít phút."

  @US-02-049 @FR-02-049 @M
  Kịch bản: US-02-049 dương · Xem đăng ký theo API
    Biết API tồn tại và người dùng xem được
    Khi người dùng mở tab Đăng ký của UI-02-02
    Thì hệ thống trả `200`; `items[]` (`subscriptionId`, `systemCode`, đơn vị, `planCode`, `status`, `grantStatus`, `activatedAt`, `expiresAt`, `calls30d`, `lastCallAt`), `facets`, `page`, `size`, `totalElements`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-049 @FR-02-049 @M @âm
  Kịch bản: US-02-049 âm 1 · API không có hoặc thuộc tenant khác
    Biết API tồn tại và người dùng xem được
    Khi API không có hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-02-001 (404)

  @US-02-049 @FR-02-049 @M @âm
  Kịch bản: US-02-049 âm 2 · PH-13 không khả dụng
    Biết API tồn tại và người dùng xem được
    Khi PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-02-034
    Và người dùng thấy thông báo "Chưa có số liệu"

  @US-02-050 @FR-02-050 @M
  Kịch bản: US-02-050 dương · Xem đăng ký theo HTTT
    Biết HTTT tồn tại ở PH-01
    Khi người dùng mở menu "Kết nối & API → Đăng ký sử dụng" (`/ket-noi/dang-ky`), hoặc tab "API đang dùng" ở chi tiết HTTT (PH-01)
    Thì hệ thống trả `200`; `items[]` như FR-02-049 kèm `apiName`, `versionNo`, `versionStatus`, `sunsetAt`, `successorVersionNo`, `allowedActions[]`; `facets`

  @US-02-050 @FR-02-050 @M @âm
  Kịch bản: US-02-050 âm 1 · HTTT không thuộc tập được xem
    Biết HTTT tồn tại ở PH-01
    Khi HTTT không thuộc tập được xem
    Thì hệ thống từ chối với ERR-02-001 (404)

  @US-02-050 @FR-02-050 @M @âm
  Kịch bản: US-02-050 âm 2 · Tham số lọc sai
    Biết HTTT tồn tại ở PH-01
    Khi tham số lọc sai
    Thì hệ thống từ chối với ERR-02-003 (400)

  @US-02-051 @FR-02-051 @M
  Kịch bản: US-02-051 dương · Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký
    Biết đăng ký `ACTIVE` hoặc `SUSPENDED` (tiếp tục, thu hồi); `ACTIVE` hoặc `PENDING` (hủy)
    Khi người dùng bấm "Tạm ngừng", "Tiếp tục", "Thu hồi" hoặc "Hủy đăng ký" ở UI-02-08 hoặc tab Đăng ký của UI-02-02
    Thì hệ thống trả `200`; đăng ký với `status` mới, `grantStatus`
    Và đăng ký đổi trạng thái; consumer, phạm vi cập nhật
    Và sự kiện được phát: EVT-02-11 (`subscription.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-051 @FR-02-051 @M @âm
  Kịch bản: US-02-051 âm 1 · Trạng thái không hợp lệ
    Biết đăng ký `ACTIVE` hoặc `SUSPENDED` (tiếp tục, thu hồi); `ACTIVE` hoặc `PENDING` (hủy)
    Khi trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-02-011 (409)
    Và người dùng thấy thông báo "Không thực hiện được ở trạng thái {trạng thái} hiện tại."

  @US-02-051 @FR-02-051 @M @âm
  Kịch bản: US-02-051 âm 2 · Thiếu lý do
    Biết đăng ký `ACTIVE` hoặc `SUSPENDED` (tiếp tục, thu hồi); `ACTIVE` hoặc `PENDING` (hủy)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-02-041 (400)
    Và người dùng thấy thông báo "Cần nêu lý do."

  @US-02-052 @FR-02-052 @S
  Kịch bản: US-02-052 dương · Gia hạn và rà soát định kỳ đăng ký
    Biết đăng ký `ACTIVE` có `expiresAt`; tham số `02.subscription.review-months` > 0
    Khi lịch hằng ngày 06:00 giờ Việt Nam; hoặc người dùng bấm "Gia hạn" ở UI-02-08
    Thì hệ thống trả `200`; đăng ký với `expiresAt` mới, `renewedAt`, hoặc `202` khi chờ duyệt
    Và `expiresAt` cập nhật hoặc đăng ký `EXPIRED`
    Và sự kiện được phát: EVT-02-11 khi `EXPIRED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-052 @FR-02-052 @S @âm
  Kịch bản: US-02-052 âm 1 · HTTT không còn `ACTIVE`
    Biết đăng ký `ACTIVE` có `expiresAt`; tham số `02.subscription.review-months` > 0
    Khi HTTT không còn `ACTIVE`
    Thì hệ thống từ chối với ERR-02-026 (422)
    Và người dùng thấy thông báo "HTTT {mã} không còn hoạt động nên không gia hạn được."

  # ---- EP-02-H · Đồng bộ danh mục quốc gia

  @US-02-053 @FR-02-053 @M
  Kịch bản: US-02-053 dương · Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14
    Biết có phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED` của API có mức hiển thị `NATIONAL`, `PUBLIC` và `dataClass` khác `SENSITIVE`; PH-14 đã cấu hình kết nối tới Nền tảng quốc gia của tenant
    Khi EVT-02-05, 06 (công bố, đổi trạng thái); EVT-02-02 (đổi mô tả, mức hiển thị, chủ quản); lịch `02.sync.cron` (mặc định `0 0 2 * * *` giờ Việt Nam); người dùng bấm "Đồng bộ ngay" ở UI-02-12
    Thì hệ thống trả `202` kèm `syncRunId` khi chạy tay; kết quả: số bản ghi theo trạng thái; bản ghi đồng bộ có `status`, `payloadHash`, `nationalRef`, `rejectReason`
    Và bản ghi đồng bộ cập nhật; danh mục quốc gia có hoặc rút mục tương ứng
    Và sự kiện được phát: EVT-02-14 (`national-sync.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-053 @FR-02-053 @M @âm
  Kịch bản: US-02-053 âm 1 · PH-14 hoặc Nền tảng quốc gia không khả dụng
    Biết có phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED` của API có mức hiển thị `NATIONAL`, `PUBLIC` và `dataClass` khác `SENSITIVE`; PH-14 đã cấu hình kết nối tới Nền tảng quốc gia của tenant
    Khi PH-14 hoặc Nền tảng quốc gia không khả dụng
    Thì hệ thống từ chối với ERR-02-034 (503)

  @US-02-053 @FR-02-053 @M @âm
  Kịch bản: US-02-053 âm 2 · Nền tảng quốc gia từ chối một dịch vụ
    Biết có phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED` của API có mức hiển thị `NATIONAL`, `PUBLIC` và `dataClass` khác `SENSITIVE`; PH-14 đã cấu hình kết nối tới Nền tảng quốc gia của tenant
    Khi nền tảng quốc gia từ chối một dịch vụ
    Thì bản ghi `REJECTED` kèm lý do; thông báo
    Và người dùng thấy thông báo "Nền tảng quốc gia từ chối API {mã}: {lý do}. Sửa thông tin rồi gửi lại."

  @US-02-054 @FR-02-054 @M
  Kịch bản: US-02-054 dương · Theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn
    Biết có bản ghi đồng bộ
    Khi người dùng mở UI-02-12 (`/ket-noi/dong-bo-quoc-gia`); hoặc lịch kiểm tra quá hạn mỗi giờ
    Thì hệ thống trả `200`; `summary {acked, queued, failed, rejected, overdue}`, `lastSuccessAt`, `items[]` (`syncId`, `apiCode`, `versionNo`, `action`, `status`, `attempts`, `reason`, `updatedAt`)
    Và bản ghi mới `QUEUED` khi thử lại; cảnh báo quá hạn đang bật khi còn API quá hạn
    Và sự kiện được phát: EVT-02-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-054 @FR-02-054 @M @âm
  Kịch bản: US-02-054 âm 1 · API chưa đủ điều kiện khi gửi lại
    Biết có bản ghi đồng bộ
    Khi API chưa đủ điều kiện khi gửi lại
    Thì hệ thống từ chối với ERR-02-044 (409)
    Và người dùng thấy thông báo "API {mã} chưa đủ điều kiện đồng bộ quốc gia."

  @US-02-054 @FR-02-054 @M @âm
  Kịch bản: US-02-054 âm 2 · Đang có lần gửi
    Biết có bản ghi đồng bộ
    Khi đang có lần gửi
    Thì hệ thống từ chối với ERR-02-035 (409)
    Và người dùng thấy thông báo "Đang đồng bộ API này."

  # ---- EP-02-I · Cam kết chất lượng, thông báo và thống kê

  @US-02-055 @FR-02-055 @M
  Kịch bản: US-02-055 dương · Khai báo cam kết chất lượng dịch vụ (SLA)
    Biết phiên bản `DRAFT` (khai lần đầu) hoặc `PUBLISHED`, `SUSPENDED`, `DEPRECATED` (sửa)
    Khi người dùng sửa khối "Cam kết chất lượng" ở UI-02-02 tab SLA, hoặc bước 4 của UI-02-03
    Thì hệ thống trả `200`, `ETag` mới; cam kết hiện hành, cam kết chờ hiệu lực (nếu có) kèm `effectiveFrom`
    Và cam kết lưu; lịch sử cam kết thêm một dòng
    Và sự kiện được phát: EVT-02-02 (`changedFields = sla`); EVT-02-12 khi cam kết kém đi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-055 @FR-02-055 @M @âm
  Kịch bản: US-02-055 âm 1 · Giá trị ngoài miền
    Biết phiên bản `DRAFT` (khai lần đầu) hoặc `PUBLISHED`, `SUSPENDED`, `DEPRECATED` (sửa)
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Giá trị {tên trường} nằm ngoài khoảng cho phép."

  @US-02-055 @FR-02-055 @M @âm
  Kịch bản: US-02-055 âm 2 · Sửa khi phiên bản `PENDING`
    Biết phiên bản `DRAFT` (khai lần đầu) hoặc `PUBLISHED`, `SUSPENDED`, `DEPRECATED` (sửa)
    Khi sửa khi phiên bản `PENDING`
    Thì hệ thống từ chối với ERR-02-038 (409)
    Và người dùng thấy thông báo "Phiên bản đang chờ duyệt, không sửa được."

  @US-02-056 @FR-02-056 @M
  Kịch bản: US-02-056 dương · Đối chiếu SLA thực tế, báo cáo tuân thủ
    Biết phiên bản có cam kết SLA và đã `PUBLISHED` ít nhất một phần của kỳ
    Khi lịch ngày 1 hằng tháng lúc 02:00 giờ Việt Nam chốt kỳ trước; tính tạm theo ngày cho kỳ hiện tại lúc 03:00; người dùng mở UI-02-11
    Thì hệ thống trả `200`; `periods[]` (`period`, `committed`, `actual`, `met`, `status`, `consecutiveBreaches`), `compliance` (tỷ lệ kỳ đạt 12 tháng), `asOf`
    Và kỳ tuân thủ ghi vào bảng; cờ cảnh báo cập nhật
    Và sự kiện được phát: EVT-02-13 (`sla.period-closed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-056 @FR-02-056 @M @âm
  Kịch bản: US-02-056 âm 1 · PH-13 không khả dụng khi chốt kỳ
    Biết phiên bản có cam kết SLA và đã `PUBLISHED` ít nhất một phần của kỳ
    Khi PH-13 không khả dụng khi chốt kỳ
    Thì hệ thống từ chối với ERR-02-034 (503)

  @US-02-056 @FR-02-056 @M @âm
  Kịch bản: US-02-056 âm 2 · Phiên bản không có cam kết
    Biết phiên bản có cam kết SLA và đã `PUBLISHED` ít nhất một phần của kỳ
    Khi phiên bản không có cam kết
    Thì bỏ qua, không phải lỗi (không đủ điều kiện gửi duyệt nên hiếm)

  @US-02-057 @FR-02-057 @M
  Kịch bản: US-02-057 dương · Thông báo thay đổi cho bên khai thác
    Biết có sự kiện thuộc các loại theo bảng ở FR gốc; có ít nhất một bên nhận
    Khi hệ thống nhận các sự kiện FR-02-031, 036, 037, 038, 039, 041, 055; hoặc SV bấm "Gửi thông báo" ở UI-02-13
    Thì hệ thống trả `202`; `noticeId`, số bên nhận, trạng thái theo kênh; chi tiết: danh sách bên nhận kèm trạng thái
    Và bản ghi thông báo và trạng thái gửi theo từng bên nhận được lưu 2 năm
    Và sự kiện được phát: EVT-02-12 (`change.notice-issued`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-057 @FR-02-057 @M @âm
  Kịch bản: US-02-057 âm 1 · Không có bên nhận
    Biết có sự kiện thuộc các loại theo bảng ở FR gốc; có ít nhất một bên nhận
    Khi không có bên nhận
    Thì bỏ qua, ghi `NO_RECIPIENTS`; không phải lỗi

  @US-02-057 @FR-02-057 @M @âm
  Kịch bản: US-02-057 âm 2 · Gửi thư thất bại hoặc không có đầu mối
    Biết có sự kiện thuộc các loại theo bảng ở FR gốc; có ít nhất một bên nhận
    Khi gửi thư thất bại hoặc không có đầu mối
    Thì hệ thống từ chối với ERR-02-034
    Và người dùng thấy thông báo "Không gửi được thư tới {HTTT}."

  @US-02-058 @FR-02-058 @S
  Kịch bản: US-02-058 dương · Thống kê sử dụng dịch vụ
    Biết phiên bản đã từng `PUBLISHED`; PH-13 có số đo
    Khi người dùng mở tab Thống kê ở UI-02-02 hoặc UI-02-11; PH-16 gọi định kỳ
    Thì hệ thống trả `200`; `series[]` (`time`, `calls`, `consumers`, `errorRate4xx`, `errorRate5xx`, `p95Ms`), `topConsumers[]`, `unused`, `trend`

  @US-02-058 @FR-02-058 @S @âm
  Kịch bản: US-02-058 âm 1 · PH-13 không khả dụng
    Biết phiên bản đã từng `PUBLISHED`; PH-13 có số đo
    Khi PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-02-034
    Và người dùng thấy thông báo "Số liệu cập nhật lúc {thời điểm}."

  # ---- EP-02-J · Tích hợp và quản trị

  @US-02-059 @FR-02-059 @M
  Kịch bản: US-02-059 dương · Cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15
    Biết tài khoản dịch vụ của phân hệ gọi đã được cấp scope tương ứng khi triển khai
    Khi PH-03 khi cần dựng ảnh chụp cấu hình (sau EVT-02-05, 06, 08, 10, 11 hoặc đối soát); PH-15 khi nạp danh mục; PH-04 khi tạo luồng từ API; PH-13, PH-16 theo lịch
    Thì hệ thống trả `200` hoặc `304`; bộ dữ liệu theo giao diện; tiêu đề `ETag`, `X-DH-Source-Version`

  @US-02-059 @FR-02-059 @M @âm
  Kịch bản: US-02-059 âm 1 · Thiếu scope hoặc sai danh tính
    Biết tài khoản dịch vụ của phân hệ gọi đã được cấp scope tương ứng khi triển khai
    Khi thiếu scope hoặc sai danh tính
    Thì hệ thống từ chối với ERR-02-014 (403)

  @US-02-059 @FR-02-059 @M @âm
  Kịch bản: US-02-059 âm 2 · Môi trường không hợp lệ
    Biết tài khoản dịch vụ của phân hệ gọi đã được cấp scope tương ứng khi triển khai
    Khi môi trường không hợp lệ
    Thì hệ thống từ chối với ERR-02-003 (400)

  @US-02-060 @FR-02-060 @C
  Kịch bản: US-02-060 dương · Đối soát cấu hình công bố với gateway
    Biết PH-03 cho biết số phiên bản và băm cấu hình đã nạp của từng môi trường
    Khi lịch mỗi 5 phút; hoặc người dùng bấm "Đối soát ngay" ở UI-02-17
    Thì hệ thống trả `200`; `inSync`, `drifts[]` (`kind`, `apiCode`, `versionNo`, `detail`), `gatewayConfigVersion`, `expectedVersion`; chạy tay: `202`
    Và bản ghi đối soát lưu 90 ngày; cảnh báo mở khi còn lệch
    Và sự kiện được phát: EVT-02-15 (`gateway.drift-detected`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-060 @FR-02-060 @C @âm
  Kịch bản: US-02-060 âm 1 · PH-03 không khả dụng
    Biết PH-03 cho biết số phiên bản và băm cấu hình đã nạp của từng môi trường
    Khi PH-03 không khả dụng
    Thì hệ thống từ chối với ERR-02-034 (503)

  @US-02-061 @FR-02-061 @M
  Kịch bản: US-02-061 dương · Di trú API, gói, đăng ký từ APIM cũ
    Biết tệp xuất từ APIM cũ (JSON của các API, plan, subscription và danh sách Application); bảng ánh xạ Application cũ sang HTTT mới (`applicationMap`) đã chuẩn bị với PH-01
    Khi người dùng bấm "Nhập từ APIM cũ" ở UI-02-16
    Thì hệ thống trả `201` (xác nhận) kèm `importId`; báo cáo `{apis, plans, subscriptions, created, skipped, issues[], checksum}`; bản xem trước `200`
    Và API, gói, đăng ký mới được tạo ở `DRAFT`, `STAGING`, `SUSPENDED`; bản ghi nhập lưu vĩnh viễn
    Và sự kiện được phát: EVT-02-01 cho từng API tạo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-061 @FR-02-061 @M @âm
  Kịch bản: US-02-061 âm 1 · Tệp sai định dạng
    Biết tệp xuất từ APIM cũ (JSON của các API, plan, subscription và danh sách Application); bảng ánh xạ Application cũ sang HTTT mới (`applicationMap`) đã chuẩn bị với PH-01
    Khi tệp sai định dạng
    Thì hệ thống từ chối với ERR-02-045 (400)
    Và người dùng thấy thông báo "Tệp không phải gói xuất APIM hợp lệ: {lý do}."

  @US-02-061 @FR-02-061 @M @âm
  Kịch bản: US-02-061 âm 2 · Tệp quá lớn
    Biết tệp xuất từ APIM cũ (JSON của các API, plan, subscription và danh sách Application); bảng ánh xạ Application cũ sang HTTT mới (`applicationMap`) đã chuẩn bị với PH-01
    Khi tệp quá lớn
    Thì hệ thống từ chối với ERR-02-009 (413)
    Và người dùng thấy thông báo "Tệp vượt 50 MiB."

  @US-02-062 @FR-02-062 @M
  Kịch bản: US-02-062 dương · Cấu hình tham số của phân hệ
    Biết PH-18 khả dụng (hoặc đọc giá trị mặc định đã đệm)
    Khi quản trị mở UI-02-17 "Cài đặt phân hệ"
    Thì hệ thống trả `200`; danh sách tham số với giá trị hiệu lực (`GET`), hoặc tham số vừa sửa với `effectiveAt`
    Và giá trị mới ở PH-18; PH-02 áp dụng sau khi đệm hết hạn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-02-062 @FR-02-062 @M @âm
  Kịch bản: US-02-062 âm 1 · Giá trị ngoài miền
    Biết PH-18 khả dụng (hoặc đọc giá trị mặc định đã đệm)
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-02-003 (400)
    Và người dùng thấy thông báo "Giá trị {tham số} phải nằm trong {a}…{b}."

  @US-02-062 @FR-02-062 @M @âm
  Kịch bản: US-02-062 âm 2 · Vượt trần
    Biết PH-18 khả dụng (hoặc đọc giá trị mặc định đã đệm)
    Khi vượt trần
    Thì hệ thống từ chối với ERR-02-040 (422)
    Và người dùng thấy thông báo "Giá trị vượt trần {giá trị} do nền tảng đặt."
