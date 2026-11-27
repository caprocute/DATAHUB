# language: vi
# Sinh tự động từ D02-02/D02-03-PH05 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-05
Tính năng: PH-05 · Bộ điều hợp và kết nối

  # ---- EP-05-A · Loại kết nối

  @US-05-001 @FR-05-001 @M
  Kịch bản: US-05-001 dương · Liệt kê loại kết nối và lược đồ tham số
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở bước "Chọn loại" của màn tạo kết nối, hoặc trình thiết kế nạp danh sách loại khi khởi động
    Thì hệ thống trả `200`; danh sách loại: `typeCode`, tên, nhóm, mức hỗ trợ (`STABLE`, `PREVIEW`, `DEPRECATED`), `enabledInTenant`, lược đồ tham số (JSON Schema 2020-12), `secretKeys[]`, Kamelet giao thức, các bước kiểm tra, trần tham số của tenant

  @US-05-001 @FR-05-001 @M @âm
  Kịch bản: US-05-001 âm 1 · Mã loại không tồn tại khi gọi theo `typeCode`
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi mã loại không tồn tại khi gọi theo `typeCode`
    Thì hệ thống từ chối với ERR-05-001
    Và người dùng thấy thông báo "Không tìm thấy loại kết nối {mã}."

  @US-05-001 @FR-05-001 @M @âm
  Kịch bản: US-05-001 âm 2 · Tham số lọc sai miền giá trị
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số lọc sai miền giá trị
    Thì hệ thống từ chối với ERR-05-003

  # ---- EP-05-B · Kết nối nguồn và bí mật

  @US-05-002 @FR-05-002 @M
  Kịch bản: US-05-002 dương · Liệt kê, tìm kiếm và lọc kết nối nguồn
    Biết đã đăng nhập, chọn tenant
    Khi người dùng mở menu Tích hợp › Kết nối nguồn, hoặc thay đổi ô tìm kiếm, bộ lọc, trang
    Thì hệ thống trả `200`; `items[]`: mã, tên, loại, HTTT, trạng thái, môi trường `ENABLED`, sức khỏe từng môi trường, số nơi dùng, tuổi bí mật, cập nhật lần cuối; `page` (`nextCursor`, `limit`); `facets` đếm theo loại, trạng thái, sức khỏe

  @US-05-002 @FR-05-002 @M @âm
  Kịch bản: US-05-002 âm 1 · Tham số sai miền (ví dụ `limit` > 100)
    Biết đã đăng nhập, chọn tenant
    Khi tham số sai miền (ví dụ `limit` > 100)
    Thì hệ thống từ chối với ERR-05-003
    Và người dùng thấy thông báo "Giá trị lọc không hợp lệ: {tên tham số}."

  @US-05-002 @FR-05-002 @M @âm
  Kịch bản: US-05-002 âm 2 · Không có kết quả
    Biết đã đăng nhập, chọn tenant
    Khi không có kết quả
    Thì màn hình hiện trạng thái rỗng thông báo kèm nút thông báo; nếu tenant chưa có kết nối nào thì hiện hướng dẫn thông báo hoặc thông báo
    Và người dùng thấy thông báo "Không có kết nối khớp bộ lọc"

  @US-05-003 @FR-05-003 @M
  Kịch bản: US-05-003 dương · Xem chi tiết kết nối nguồn
    Biết kết nối thuộc tenant hiện hành
    Khi người dùng bấm vào một dòng ở danh sách, hoặc mở liên kết từ luồng, cảnh báo, việc chờ duyệt
    Thì hệ thống trả `200`; thông tin chung; ba giá trị môi trường với tham số không bí mật, `secretSet`, `secretVersion`, `secretUpdatedAt`, trạng thái, lần kiểm tra gần nhất; danh sách cấp; sức khỏe; số nơi dùng; tiêu đề `ETag`

  @US-05-003 @FR-05-003 @M @âm
  Kịch bản: US-05-003 âm 1 · Kết nối không tồn tại hoặc thuộc tenant khác
    Biết kết nối thuộc tenant hiện hành
    Khi kết nối không tồn tại hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-05-001
    Và người dùng thấy thông báo "Không tìm thấy kết nối {mã}."

  @US-05-004 @FR-05-004 @M
  Kịch bản: US-05-004 dương · Tạo kết nối nguồn
    Biết HTTT chủ quản ở trạng thái `ACTIVE` trong danh mục HTTT của PH-01; loại kết nối đang được bật ở tenant
    Khi người dùng bấm "+ Tạo kết nối" ở UI-05-01, chọn loại ở bước 1 và điền bước 2 "Thông tin chung" của trình hướng dẫn UI-05-03
    Thì hệ thống trả `201`; thân như FR-05-003; tiêu đề `Location`, `ETag`
    Và kết nối ở `DRAFT`; chưa dùng được trong luồng ngoài chế độ thiết kế
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-004 @FR-05-004 @M @âm
  Kịch bản: US-05-004 âm 1 · Mã sai mẫu
    Biết HTTT chủ quản ở trạng thái `ACTIVE` trong danh mục HTTT của PH-01; loại kết nối đang được bật ở tenant
    Khi mã sai mẫu
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Mã chỉ gồm chữ thường, số và dấu gạch ngang, 3–63 ký tự, bắt đầu bằng chữ."

  @US-05-004 @FR-05-004 @M @âm
  Kịch bản: US-05-004 âm 2 · Mã đã dùng
    Biết HTTT chủ quản ở trạng thái `ACTIVE` trong danh mục HTTT của PH-01; loại kết nối đang được bật ở tenant
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-05-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng (kể cả đối tượng đã ngừng dùng). Chọn mã khác."

  @US-05-005 @FR-05-005 @M
  Kịch bản: US-05-005 dương · Khai báo giá trị và bí mật theo môi trường
    Biết kết nối không ở `RETIRED`; môi trường thuộc `TEST`, `STAGING`, `PROD`
    Khi người dùng điền bước 3 của trình hướng dẫn tạo kết nối, hoặc bấm "Sửa" trên một môi trường ở tab Môi trường của UI-05-02
    Thì (a) `200` kèm giá trị môi trường mới; (b) `204` không thân
    Và giá trị môi trường ở `CONFIGURED`; phải kiểm tra đạt trước khi bật
    Và sự kiện được phát: EVT-05-02 khi tham số của giá trị đang bật ở TEST, STAGING thay đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-005 @FR-05-005 @M @âm
  Kịch bản: US-05-005 âm 1 · Tham số sai lược đồ hoặc khóa bí mật lạ
    Biết kết nối không ở `RETIRED`; môi trường thuộc `TEST`, `STAGING`, `PROD`
    Khi tham số sai lược đồ hoặc khóa bí mật lạ
    Thì hệ thống từ chối với ERR-05-003 (400)

  @US-05-005 @FR-05-005 @M @âm
  Kịch bản: US-05-005 âm 2 · Vượt trần tenant
    Biết kết nối không ở `RETIRED`; môi trường thuộc `TEST`, `STAGING`, `PROD`
    Khi vượt trần tenant
    Thì hệ thống từ chối với ERR-05-030 (422)
    Và người dùng thấy thông báo "Giá trị {tên} vượt mức tối đa {trần} của tỉnh."

  @US-05-006 @FR-05-006 @M
  Kịch bản: US-05-006 dương · Sửa thông tin kết nối
    Biết kết nối không ở `RETIRED`
    Khi người dùng bấm "Sửa" ở tab Tổng quan của UI-05-02
    Thì hệ thống trả `200`; kết nối sau khi sửa; `affectedUsages[]` (nơi dùng bị ảnh hưởng, FR-05-013); `ETag` mới
    Và phiên bản cấu hình của kết nối tăng một
    Và sự kiện được phát: EVT-05-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-006 @FR-05-006 @M @âm
  Kịch bản: US-05-006 âm 1 · Sửa mã, loại hoặc HTTT
    Biết kết nối không ở `RETIRED`
    Khi sửa mã, loại hoặc HTTT
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Không sửa được mã, loại, HTTT của kết nối. Tạo kết nối mới nếu cần đổi."

  @US-05-006 @FR-05-006 @M @âm
  Kịch bản: US-05-006 âm 2 · Xung đột phiên bản
    Biết kết nối không ở `RETIRED`
    Khi xung đột phiên bản
    Thì hệ thống từ chối với ERR-05-007 (412)

  @US-05-007 @FR-05-007 @M
  Kịch bản: US-05-007 dương · Bật, tắt giá trị môi trường và duyệt bật PROD
    Biết giá trị môi trường ở `CONFIGURED` hoặc `DISABLED`; có lần kiểm tra đạt trong 24 giờ trên đúng phiên bản tham số và bí mật hiện tại
    Khi người dùng bấm "Bật" hoặc "Xin bật PROD" ở tab Môi trường; IA mở việc "Duyệt bật PROD" trong "Việc của tôi"; người vận hành bấm "Tắt"
    Thì hệ thống trả `200`; giá trị môi trường với trạng thái mới (`ENABLED`, `PENDING_APPROVAL`, `CONFIGURED`, `DISABLED`)
    Và giá trị `ENABLED` dùng được ở runtime trong môi trường đó; hoặc `DISABLED` và mọi lượt gọi mới bị từ chối
    Và sự kiện được phát: EVT-05-01 (bật), EVT-05-04 (tắt, có `env`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-007 @FR-05-007 @M @âm
  Kịch bản: US-05-007 âm 1 · Chưa có kiểm tra đạt trong 24 giờ
    Biết giá trị môi trường ở `CONFIGURED` hoặc `DISABLED`; có lần kiểm tra đạt trong 24 giờ trên đúng phiên bản tham số và bí mật hiện tại
    Khi chưa có kiểm tra đạt trong 24 giờ
    Thì hệ thống từ chối với ERR-05-009 (409)
    Và người dùng thấy thông báo "Chưa có kiểm tra đạt trong 24 giờ trên đúng tham số và bí mật hiện tại."

  @US-05-007 @FR-05-007 @M @âm
  Kịch bản: US-05-007 âm 2 · Chuyển trạng thái không hợp lệ
    Biết giá trị môi trường ở `CONFIGURED` hoặc `DISABLED`; có lần kiểm tra đạt trong 24 giờ trên đúng phiên bản tham số và bí mật hiện tại
    Khi chuyển trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-05-008 (409)

  @US-05-008 @FR-05-008 @M
  Kịch bản: US-05-008 dương · Tạm ngừng, tiếp tục và ngừng dùng kết nối
    Biết tạm ngừng: kết nối `ACTIVE`
    Khi người dùng bấm "Tạm ngừng", "Tiếp tục" hoặc "Ngừng dùng" ở thanh tiêu đề UI-05-02
    Thì hệ thống trả `200`; kết nối với trạng thái mới
    Và trạng thái kết nối mới; runtime đã nhận sự kiện
    Và sự kiện được phát: EVT-05-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-008 @FR-05-008 @M @âm
  Kịch bản: US-05-008 âm 1 · Còn nơi dùng khi ngừng dùng
    Biết tạm ngừng: kết nối `ACTIVE`
    Khi còn nơi dùng khi ngừng dùng
    Thì hệ thống từ chối với ERR-05-010 (409)
    Và người dùng thấy thông báo "Còn {n} nơi đang dùng."

  @US-05-008 @FR-05-008 @M @âm
  Kịch bản: US-05-008 âm 2 · Chuyển trạng thái không hợp lệ (ví dụ tạm ngừng kết nối nháp)
    Biết tạm ngừng: kết nối `ACTIVE`
    Khi chuyển trạng thái không hợp lệ (ví dụ tạm ngừng kết nối nháp)
    Thì hệ thống từ chối với ERR-05-008 (409)

  @US-05-009 @FR-05-009 @M
  Kịch bản: US-05-009 dương · Cấp và thu hồi quyền sử dụng kết nối
    Biết kết nối không `RETIRED`; không gian làm việc hoặc luồng tồn tại ở PH-04
    Khi người dùng bấm "+ Cấp" ở tab Cấp sử dụng của UI-05-02, hoặc ở bước 5 của trình hướng dẫn tạo kết nối
    Thì hệ thống trả `201` cấp mới hoặc `200` cấp sẵn có; thu hồi `204`, kèm danh sách luồng bị ảnh hưởng
    Và có bản ghi cấp sử dụng; trình thiết kế của không gian thấy kết nối (FR-04-016)
    Và sự kiện được phát: EVT-05-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-009 @FR-05-009 @M @âm
  Kịch bản: US-05-009 âm 1 · Không gian hoặc luồng không tồn tại
    Biết kết nối không `RETIRED`; không gian làm việc hoặc luồng tồn tại ở PH-04
    Khi không gian hoặc luồng không tồn tại
    Thì hệ thống từ chối với ERR-05-033 (422)

  @US-05-009 @FR-05-009 @M @âm
  Kịch bản: US-05-009 âm 2 · Phạm vi không hợp lệ với loại kết nối
    Biết kết nối không `RETIRED`; không gian làm việc hoặc luồng tồn tại ở PH-04
    Khi phạm vi không hợp lệ với loại kết nối
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Kết nối CSDL cho luồng chỉ cấp được cho từng luồng."

  @US-05-010 @FR-05-010 @M
  Kịch bản: US-05-010 dương · Kiểm tra kết nối không tác dụng phụ, có hướng dẫn khắc phục
    Biết giá trị môi trường đã khai báo tham số; bí mật đã ghi nếu loại có khóa bí mật bắt buộc
    Khi người dùng bấm "Kiểm tra kết nối" ở UI-05-02 hoặc ở bước 4 của trình hướng dẫn tạo kết nối
    Thì hệ thống trả `202` kèm `testId`; kết quả (API-05-019, SSE): `PASSED` hoặc `FAILED`; `steps[]` (`name`, `status`, `durationMs`, `causeCode`, `hint`); `latencyMs`; `secretVersion` đã dùng; `expiresAt` (24 giờ sau)
    Và lần kiểm tra đạt là điều kiện để bật môi trường (FR-05-007) trong 24 giờ; kết quả lưu 1 năm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-010 @FR-05-010 @M @âm
  Kịch bản: US-05-010 âm 1 · Đang có lần kiểm tra chạy
    Biết giá trị môi trường đã khai báo tham số; bí mật đã ghi nếu loại có khóa bí mật bắt buộc
    Khi đang có lần kiểm tra chạy
    Thì hệ thống từ chối với ERR-05-018 (409)

  @US-05-010 @FR-05-010 @M @âm
  Kịch bản: US-05-010 âm 2 · Vượt 20 lần mỗi giờ
    Biết giá trị môi trường đã khai báo tham số; bí mật đã ghi nếu loại có khóa bí mật bắt buộc
    Khi vượt 20 lần mỗi giờ
    Thì hệ thống từ chối với ERR-05-019 (429)
    Và người dùng thấy thông báo "Đã chạy quá số lần kiểm tra cho phép. Thử lại sau {n} phút."

  @US-05-011 @FR-05-011 @M
  Kịch bản: US-05-011 dương · Bảo vệ bí mật: ghi một chiều, không hiển thị, không ghi log
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi mọi lệnh ghi, đọc, kiểm tra, xuất, nhập có liên quan tới kết nối
    Thì không ai, kể cả quản trị viên, lấy lại được bí mật từ Datahub; lộ bí mật chỉ có thể xảy ra ở phía HTTT

  @US-05-011 @FR-05-011 @M @âm
  Kịch bản: US-05-011 âm 1 · Bí mật gửi qua trường thường
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi bí mật gửi qua trường thường
    Thì hệ thống từ chối với ERR-05-006 (422)

  @US-05-011 @FR-05-011 @M @âm
  Kịch bản: US-05-011 âm 2 · Phát hiện bí mật trong log ở ca kiểm thử rò rỉ
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi phát hiện bí mật trong log ở ca kiểm thử rò rỉ
    Thì lỗi chặn phát hành (NFR-05-011)

  @US-05-012 @FR-05-012 @M
  Kịch bản: US-05-012 dương · Xoay vòng bí mật không gián đoạn
    Biết giá trị môi trường `ENABLED`; không có lần xoay khác đang trong thời gian chuyển tiếp
    Khi người dùng bấm "Xoay bí mật" ở UI-05-02; hoặc lịch xoay tới hạn
    Thì hệ thống trả `202`; bản ghi lần xoay (`rotationId`, trạng thái, phiên bản cũ và mới, thời điểm kết thúc chuyển tiếp)
    Và phiên bản bí mật hiện hành tăng một; tuổi bí mật về 0
    Và sự kiện được phát: EVT-05-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-012 @FR-05-012 @M @âm
  Kịch bản: US-05-012 âm 1 · Đang có lần xoay trong chuyển tiếp
    Biết giá trị môi trường `ENABLED`; không có lần xoay khác đang trong thời gian chuyển tiếp
    Khi đang có lần xoay trong chuyển tiếp
    Thì hệ thống từ chối với ERR-05-036 (409)
    Và người dùng thấy thông báo "Đang có lần xoay bí mật trong thời gian chuyển tiếp tới {thời điểm}."

  @US-05-012 @FR-05-012 @M @âm
  Kịch bản: US-05-012 âm 2 · Kho bí mật không khả dụng
    Biết giá trị môi trường `ENABLED`; không có lần xoay khác đang trong thời gian chuyển tiếp
    Khi kho bí mật không khả dụng
    Thì hệ thống từ chối với ERR-05-028 (503)

  @US-05-013 @FR-05-013 @M
  Kịch bản: US-05-013 dương · Xem nơi đang dùng kết nối và bộ điều hợp
    Biết kết nối thuộc tenant hiện hành
    Khi người dùng mở tab "Nơi dùng" ở UI-05-02; hoặc hệ thống tự gọi khi sửa (FR-05-006), ngừng dùng (FR-05-008)
    Thì hệ thống trả `200`; `items[]` (loại nơi dùng, mã, phiên bản, môi trường, liên kết); `partial` (`true` khi PH-04 không trả lời trong 2 giây)

  @US-05-013 @FR-05-013 @M @âm
  Kịch bản: US-05-013 âm 1 · PH-04 không trả lời trong 2 giây
    Biết kết nối thuộc tenant hiện hành
    Khi PH-04 không trả lời trong 2 giây
    Thì phản hồi có cờ `partial: true`; màn hình cảnh báo thông báo thay vì báo lỗi
    Và người dùng thấy thông báo "Danh sách luồng có thể chưa đủ"

  @US-05-014 @FR-05-014 @M
  Kịch bản: US-05-014 dương · Xác minh tham chiếu kết nối cho PH-04
    Biết token dịch vụ hợp lệ; tenant lấy từ token, không từ thân yêu cầu
    Khi PH-04 lưu, gửi duyệt hoặc phát hành một phiên bản luồng
    Thì hệ thống trả `200`; `results[]` (`status`, `code`, thông điệp nêu mã lỗi tương ứng ERR-05-001, 013, 014, 118, 003, 017, 120); `allOk`
    Và chỉ mục nơi dùng được cập nhật khi phát hành

  @US-05-014 @FR-05-014 @M @âm
  Kịch bản: US-05-014 âm 1 · Thân yêu cầu sai
    Biết token dịch vụ hợp lệ; tenant lấy từ token, không từ thân yêu cầu
    Khi thân yêu cầu sai
    Thì hệ thống từ chối với ERR-05-003 (400)

  @US-05-014 @FR-05-014 @M @âm
  Kịch bản: US-05-014 âm 2 · Token không có scope
    Biết token dịch vụ hợp lệ; tenant lấy từ token, không từ thân yêu cầu
    Khi token không có scope
    Thì hệ thống từ chối với ERR-05-012 (403)

  @US-05-015 @FR-05-015 @M
  Kịch bản: US-05-015 dương · Cung cấp cấu hình kết nối không bí mật cho runtime
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi runtime khởi động; nhận EVT-05-01, 02, 03, 04; hoặc mỗi 5 phút
    Thì hệ thống trả `200` tệp kê khai (mã, loại, tham số không bí mật, đường dẫn và phiên bản bí mật, giới hạn đồng thời, sức khỏe, cờ `blocked`) kèm `ETag`; hoặc `304`

  @US-05-015 @FR-05-015 @M @âm
  Kịch bản: US-05-015 âm 1 · Token không có scope
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi token không có scope
    Thì hệ thống từ chối với ERR-05-012 (403)

  @US-05-016 @FR-05-016 @M
  Kịch bản: US-05-016 dương · Xem lịch sử thay đổi
    Biết đối tượng thuộc tenant hiện hành
    Khi người dùng mở tab "Lịch sử" ở UI-05-02 hoặc UI-05-09
    Thì hệ thống trả `200`; `items[]`: thời điểm, người, hành động, trường đổi (cũ, mới), lý do; thêm IP, phiên với `PERM-05-audit-read`

  @US-05-017 @FR-05-017 @S
  Kịch bản: US-05-017 dương · Xuất danh sách kết nối
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi người dùng bấm "Xuất CSV" ở UI-05-01
    Thì hệ thống trả `200` tệp `text/csv; charset=utf-8` có BOM, ≤ 10.000 dòng, tên `ket-noi-nguon-{tenant}-{yyyyMMdd}.csv`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-017 @FR-05-017 @S @âm
  Kịch bản: US-05-017 âm 1 · Vượt 10.000 dòng
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi vượt 10.000 dòng
    Thì hệ thống từ chối và báo thông báo
    Và người dùng thấy thông báo "Danh sách quá lớn. Thu hẹp bộ lọc dưới 10.000 dòng."

  @US-05-018 @FR-05-018 @M
  Kịch bản: US-05-018 dương · Nhập ánh xạ kết nối từ hệ cũ
    Biết có gói xuất từ Bus cũ (bảng `Context`, `Context_file`) hoặc tệp `datasource.properties`
    Khi người dùng bấm "Nhập từ hệ cũ" ở UI-05-01
    Thì hệ thống trả `202` kèm `jobId`; kết quả phân tích (đề xuất, vị trí bí mật dạng rõ); sau xác nhận: danh sách kết nối nháp và tệp `connectionMap.json`
    Và kết nối nháp cần khai báo bí mật, kiểm tra, bật như kết nối mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-018 @FR-05-018 @M @âm
  Kịch bản: US-05-018 âm 1 · Tệp sai định dạng
    Biết có gói xuất từ Bus cũ (bảng `Context`, `Context_file`) hoặc tệp `datasource.properties`
    Khi tệp sai định dạng
    Thì hệ thống từ chối với ERR-05-024 (400)
    Và người dùng thấy thông báo "Tệp không đúng định dạng gói Bus hoặc vượt 20 MiB."

  @US-05-018 @FR-05-018 @M @âm
  Kịch bản: US-05-018 âm 2 · Có mã độc
    Biết có gói xuất từ Bus cũ (bảng `Context`, `Context_file`) hoặc tệp `datasource.properties`
    Khi có mã độc
    Thì hệ thống từ chối với ERR-05-034 (422)

  # ---- EP-05-C · Sức khỏe kết nối

  @US-05-019 @FR-05-019 @M
  Kịch bản: US-05-019 dương · Kiểm tra sức khỏe chủ động
    Biết giá trị môi trường ở trạng thái `ENABLED`; loại kết nối có thao tác thử (`probe` khác `NONE`)
    Khi theo chu kỳ `05.health.interval-seconds`: mặc định 60 giây ở PROD, 300 giây ở TEST và STAGING, tối thiểu 30 giây
    Thì mẫu thăm dò (kết quả, độ trễ, nguyên nhân) và hai chỉ số trên
    Và có mẫu thăm dò mới cho bộ đánh giá; không thay đổi dữ liệu ở HTTT

  @US-05-019 @FR-05-019 @M @âm
  Kịch bản: US-05-019 âm 1 · Lỗi `AUTH_FAILED` lần thứ hai liên tiếp
    Biết giá trị môi trường ở trạng thái `ENABLED`; loại kết nối có thao tác thử (`probe` khác `NONE`)
    Khi lỗi `AUTH_FAILED` lần thứ hai liên tiếp
    Thì hệ thống không thử xác thực lại, chuyển `UNHEALTHY` và dừng thăm dò xác thực tới khi bí mật đổi (BR-05-008)
    Và người dùng thấy thông báo "Xác thực thất bại hai lần liên tiếp. Đã tạm dừng thăm dò để tránh khóa tài khoản; cập nhật bí mật rồi chạy kiểm tra."

  @US-05-019 @FR-05-019 @M @âm
  Kịch bản: US-05-019 âm 2 · Bộ chạy `probe` không khả dụng
    Biết giá trị môi trường ở trạng thái `ENABLED`; loại kết nối có thao tác thử (`probe` khác `NONE`)
    Khi bộ chạy `probe` không khả dụng
    Thì không có mẫu mới; sau 15 phút mức thành `UNKNOWN` (FR-05-020)

  @US-05-020 @FR-05-020 @M
  Kịch bản: US-05-020 dương · Đánh giá sức khỏe thụ động từ lưu lượng thật
    Biết Kamelet giao thức phát chỉ số theo kết nối và thao tác: `dh_adapter_calls_total{result}`, `dh_adapter_call_duration_seconds`, `dh_adapter_pool_wait_seconds`
    Khi mỗi phút
    Thì mức đề xuất kèm lý do (chỉ số và ngưỡng bị vi phạm)

  @US-05-020 @FR-05-020 @M @âm
  Kịch bản: US-05-020 âm 1 · Prometheus không trả lời
    Biết Kamelet giao thức phát chỉ số theo kết nối và thao tác: `dh_adapter_calls_total{result}`, `dh_adapter_call_duration_seconds`, `dh_adapter_pool_wait_seconds`
    Khi Prometheus không trả lời
    Thì hệ thống giữ mức hiện tại, ghi cảnh báo nội bộ; sau 15 phút không đọc được, mức thành `UNKNOWN` và UI-05-07 hiện thông báo
    Và người dùng thấy thông báo "Chưa đánh giá được sức khỏe: hệ thống giám sát không phản hồi."

  @US-05-021 @FR-05-021 @M
  Kịch bản: US-05-021 dương · Cảnh báo và phát sự kiện khi đổi mức sức khỏe
    Biết FR-05-020 trả mức đề xuất khác mức hiện tại
    Khi mỗi chu kỳ đánh giá (1 phút)
    Thì hệ thống trả `HealthState` mới; EVT-05-06
    Và lịch sử mức được giữ 90 ngày
    Và sự kiện được phát: EVT-05-06

  @US-05-021 @FR-05-021 @M @âm
  Kịch bản: US-05-021 âm 1 · Kafka không nhận sự kiện
    Biết FR-05-020 trả mức đề xuất khác mức hiện tại
    Khi Kafka không nhận sự kiện
    Thì hệ thống ghi `HealthState` trước, đưa sự kiện vào hộp thư đi (outbox) và phát lại khi Kafka khả dụng; API-05-093 vẫn trả mức mới

  @US-05-022 @FR-05-022 @M
  Kịch bản: US-05-022 dương · Tổng quan sức khỏe
    Biết người dùng đăng nhập vào tenant
    Khi người dùng mở UI-05-07 từ menu "Kết nối · Sức khỏe"; màn tự làm mới mỗi 60 giây
    Thì hệ thống trả `200`, các khối số liệu nêu trên, kèm `asOf`

  # ---- EP-05-D · CSDL cho luồng (Q359)

  @US-05-023 @FR-05-023 @M
  Kịch bản: US-05-023 dương · Khai báo kết nối CSDL cho luồng
    Biết như FR-05-004; đơn vị chủ quản CSDL đã tạo tài khoản quản trị cho OpenBao theo kịch bản mẫu ở D03-03-PH05 (với `DYNAMIC`)
    Khi người dùng chọn loại "CSDL cho luồng (`db-flow`)" ở bước 1 của UI-05-03
    Thì hệ thống trả `201`, kết nối `db-flow` như FR-05-004
    Và kết nối `DRAFT`; với CSDL có RLS theo tenant, Kamelet `dh-sql-ro-source` sẽ đặt `rlsTenantSetting` bằng `SET LOCAL` trong mỗi giao dịch (FR-04-072 bước 4)
    Và sự kiện được phát: Như FR-05-004
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-023 @FR-05-023 @M @âm
  Kịch bản: US-05-023 âm 1 · Phạm vi chứa CSDL của Datahub
    Biết như FR-05-004; đơn vị chủ quản CSDL đã tạo tài khoản quản trị cho OpenBao theo kịch bản mẫu ở D03-03-PH05 (với `DYNAMIC`)
    Khi phạm vi chứa CSDL của Datahub
    Thì hệ thống từ chối với ERR-05-016 (422)
    Và người dùng thấy thông báo "Không được cấp quyền đọc CSDL quản trị của Datahub ({schema}). Bỏ schema này khỏi phạm vi."

  @US-05-023 @FR-05-023 @M @âm
  Kịch bản: US-05-023 âm 2 · Vượt trần
    Biết như FR-05-004; đơn vị chủ quản CSDL đã tạo tài khoản quản trị cho OpenBao theo kịch bản mẫu ở D03-03-PH05 (với `DYNAMIC`)
    Khi vượt trần
    Thì hệ thống từ chối với ERR-05-030 (422)
    Và người dùng thấy thông báo "Giá trị {tên} vượt trần {trần} của tỉnh."

  @US-05-024 @FR-05-024 @M
  Kịch bản: US-05-024 dương · Cấp tài khoản CSDL chỉ đọc theo luồng
    Biết kết nối `db-flow` có giá trị `ENABLED` ở môi trường yêu cầu; luồng tồn tại ở PH-04 và kết nối đã cấp cho luồng (FR-05-009)
    Khi người dùng bấm "Yêu cầu tài khoản chỉ đọc" ở UI-05-05
    Thì hệ thống trả `201`, tài khoản kèm trạng thái, cơ chế, phạm vi, tên role OpenBao
    Và luồng dùng `dh-sql-ro-source` với kết nối này nhận thông tin đăng nhập động lúc chạy
    Và sự kiện được phát: EVT-05-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-024 @FR-05-024 @M @âm
  Kịch bản: US-05-024 âm 1 · Phạm vi vượt
    Biết kết nối `db-flow` có giá trị `ENABLED` ở môi trường yêu cầu; luồng tồn tại ở PH-04 và kết nối đã cấp cho luồng (FR-05-009)
    Khi phạm vi vượt
    Thì hệ thống từ chối với ERR-05-027 (422)
    Và người dùng thấy thông báo "Bảng hoặc schema {tên} nằm ngoài phạm vi cho phép của kết nối."

  @US-05-024 @FR-05-024 @M @âm
  Kịch bản: US-05-024 âm 2 · Chưa cấp kết nối cho luồng
    Biết kết nối `db-flow` có giá trị `ENABLED` ở môi trường yêu cầu; luồng tồn tại ở PH-04 và kết nối đã cấp cho luồng (FR-05-009)
    Khi chưa cấp kết nối cho luồng
    Thì hệ thống từ chối với ERR-05-013 (422)
    Và người dùng thấy thông báo "Kết nối chưa được cấp cho luồng {mã}. Cấp ở tab Cấp sử dụng trước."

  @US-05-025 @FR-05-025 @M
  Kịch bản: US-05-025 dương · Kiểm tra quyền thực tế của tài khoản CSDL
    Biết giá trị môi trường của kết nối `db-flow` hoặc JDBC mục đích `READ` đã có bí mật
    Khi người dùng bấm "Kiểm tra quyền" ở UI-05-05; bước bắt buộc trước khi bật môi trường; tự động mỗi 24 giờ với giá trị đã bật
    Thì kết quả `PASSED` hoặc `FAILED`, danh sách quyền theo đối tượng, các quyền vi phạm
    Và kết quả kiểm tra quyền gắn với giá trị môi trường; `FAILED` chặn bật môi trường
    Và sự kiện được phát: EVT-05-06 khi đổi sức khỏe do `PRIVILEGE_DRIFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-025 @FR-05-025 @M @âm
  Kịch bản: US-05-025 âm 1 · Có quyền `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, DDL, `EXECUTE` trên thủ tục ngoài danh sách cho phép …
    Biết giá trị môi trường của kết nối `db-flow` hoặc JDBC mục đích `READ` đã có bí mật
    Khi có quyền `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, DDL, `EXECUTE` trên thủ tục ngoài danh sách cho phép, `BYPASSRLS` hoặc quyền quản trị
    Thì hệ thống từ chối với ERR-05-015 (422)
    Và người dùng thấy thông báo "Tài khoản khai là chỉ đọc nhưng có quyền ghi trên {bảng}. Đề nghị đơn vị chủ quản thu hồi quyền trước khi bật."

  @US-05-025 @FR-05-025 @M @âm
  Kịch bản: US-05-025 âm 2 · Có quyền trên schema ngoài `allowedSchemas`
    Biết giá trị môi trường của kết nối `db-flow` hoặc JDBC mục đích `READ` đã có bí mật
    Khi có quyền trên schema ngoài `allowedSchemas`
    Thì hệ thống từ chối với ERR-05-027 (422)
    Và người dùng thấy thông báo "Tài khoản thấy được schema {tên} ngoài phạm vi."

  @US-05-026 @FR-05-026 @M
  Kịch bản: US-05-026 dương · Đề nghị, đồng ý và duyệt mục đích ghi vào CSDL
    Biết kết nối `purpose = READ_WRITE`; CSDL đích là CSDL của HTTT thành viên, không phải CSDL của Datahub (BR-05-017)
    Khi IE bấm "Đề nghị quyền ghi" ở UI-05-05; SO và IA xử lý ở UI-05-17
    Thì tài khoản kèm trạng thái sau mỗi bước
    Và luồng được liệt kê có thể dùng `dh-sql-write-sink` với kết nối này (FR-05-014 bước 6)
    Và sự kiện được phát: EVT-05-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-026 @FR-05-026 @M @âm
  Kịch bản: US-05-026 âm 1 · Kết nối chỉ đọc
    Biết kết nối `purpose = READ_WRITE`; CSDL đích là CSDL của HTTT thành viên, không phải CSDL của Datahub (BR-05-017)
    Khi kết nối chỉ đọc
    Thì hệ thống từ chối với ERR-05-017 (409)
    Và người dùng thấy thông báo "Kết nối chỉ đọc không cho thao tác ghi. Đổi mục đích kết nối hoặc yêu cầu tài khoản ghi."

  @US-05-026 @FR-05-026 @M @âm
  Kịch bản: US-05-026 âm 2 · CSDL của Datahub
    Biết kết nối `purpose = READ_WRITE`; CSDL đích là CSDL của HTTT thành viên, không phải CSDL của Datahub (BR-05-017)
    Khi CSDL của Datahub
    Thì hệ thống từ chối với ERR-05-016 (422)
    Và người dùng thấy thông báo "Không được ghi vào CSDL của Datahub."

  @US-05-027 @FR-05-027 @M
  Kịch bản: US-05-027 dương · Kiểm toán truy cập CSDL của luồng
    Biết luồng dùng `dh-sql-ro-source`, `dh-sql-ro-action` hoặc `dh-sql-write-sink`
    Khi sau mỗi câu lệnh (ghi); người dùng mở tab Nhật ký truy cập ở UI-05-05 (tra cứu)
    Thì tra cứu: `200`, danh sách bản ghi có phân trang
    Và bản ghi bất biến, giữ 12 tháng trực tuyến và 5 năm WORM
    Và sự kiện được phát: EVT-05-14

  @US-05-027 @FR-05-027 @M @âm
  Kịch bản: US-05-027 âm 1 · Kafka không nhận EVT-05-14
    Biết luồng dùng `dh-sql-ro-source`, `dh-sql-ro-action` hoặc `dh-sql-write-sink`
    Khi Kafka không nhận EVT-05-14
    Thì Kamelet đệm cục bộ và phát lại; đệm đầy thì lượt chạy lỗi tạm thời, không chạy câu lệnh không được kiểm toán

  @US-05-028 @FR-05-028 @M
  Kịch bản: US-05-028 dương · Thu hồi tài khoản CSDL
    Biết tài khoản ở `ISSUED`
    Khi một trong bốn: người dùng bấm "Thu hồi" ở UI-05-05; luồng ngừng dùng ở PH-04 (tiêu thụ sự kiện ngừng dùng luồng); kết nối ngừng dùng; quyền ghi hết hạn
    Thì hệ thống trả `200`, tài khoản `REVOKED`
    Và sự kiện được phát: EVT-05-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-028 @FR-05-028 @M @âm
  Kịch bản: US-05-028 âm 1 · Thiếu lý do khi thu hồi thủ công
    Biết tài khoản ở `ISSUED`
    Khi thiếu lý do khi thu hồi thủ công
    Thì hệ thống từ chối với ERR-05-038 (400)
    Và người dùng thấy thông báo "Nhập lý do thu hồi."

  @US-05-028 @FR-05-028 @M @âm
  Kịch bản: US-05-028 âm 2 · OpenBao không khả dụng
    Biết tài khoản ở `ISSUED`
    Khi OpenBao không khả dụng
    Thì hệ thống từ chối với ERR-05-028 (503)
    Và người dùng thấy thông báo "Đã chặn tài khoản; việc xóa ở kho bí mật sẽ hoàn tất khi kho khả dụng."

  # ---- EP-05-E · Bộ điều hợp theo giao thức

  @US-05-029 @FR-05-029 @M
  Kịch bản: US-05-029 dương · Liệt kê bộ điều hợp kèm sức khỏe
    Biết người dùng đăng nhập vào tenant
    Khi người dùng mở UI-05-08 từ menu "Kết nối · Bộ điều hợp"
    Thì hệ thống trả `200`, trang kết quả, `facets`, bốn thẻ tổng

  @US-05-029 @FR-05-029 @M @âm
  Kịch bản: US-05-029 âm 1 · Tham số lọc sai
    Biết người dùng đăng nhập vào tenant
    Khi tham số lọc sai
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Bộ lọc {tên} không hợp lệ."

  @US-05-030 @FR-05-030 @M
  Kịch bản: US-05-030 dương · Xem chi tiết bộ điều hợp và phiên bản
    Biết bộ điều hợp thuộc tenant của người dùng
    Khi người dùng bấm một dòng ở UI-05-08, hoặc liên kết từ luồng, cảnh báo, việc duyệt
    Thì hệ thống trả `200`, chi tiết kèm `ETag`

  @US-05-030 @FR-05-030 @M @âm
  Kịch bản: US-05-030 âm 1 · Bộ điều hợp không tồn tại hoặc của tenant khác
    Biết bộ điều hợp thuộc tenant của người dùng
    Khi bộ điều hợp không tồn tại hoặc của tenant khác
    Thì hệ thống từ chối với ERR-05-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy bộ điều hợp {mã}."

  @US-05-031 @FR-05-031 @M
  Kịch bản: US-05-031 dương · Tạo và sửa bộ điều hợp
    Biết HTTT `ACTIVE` ở PH-01; kết nối dùng thuộc tenant, không `RETIRED`, cùng HTTT (BR-05-015)
    Khi người dùng bấm "+ Tạo bộ điều hợp" ở UI-05-08 (sửa: "Sửa thông tin" ở UI-05-09)
    Thì hệ thống trả `201` chi tiết bộ điều hợp, tiêu đề `Location`, `ETag`; sửa `200`
    Và bộ điều hợp `DRAFT`, chưa xuất hiện trong trình thiết kế
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-031 @FR-05-031 @M @âm
  Kịch bản: US-05-031 âm 1 · Mã đã dùng
    Biết HTTT `ACTIVE` ở PH-01; kết nối dùng thuộc tenant, không `RETIRED`, cùng HTTT (BR-05-015)
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-05-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng (kể cả đối tượng đã ngừng dùng). Chọn mã khác."

  @US-05-031 @FR-05-031 @M @âm
  Kịch bản: US-05-031 âm 2 · HTTT không hợp lệ
    Biết HTTT `ACTIVE` ở PH-01; kết nối dùng thuộc tenant, không `RETIRED`, cùng HTTT (BR-05-015)
    Khi HTTT không hợp lệ
    Thì hệ thống từ chối với ERR-05-005 (422)
    Và người dùng thấy thông báo "HTTT {mã} không tồn tại hoặc chưa ở trạng thái hoạt động trong danh mục HTTT."

  @US-05-032 @FR-05-032 @M
  Kịch bản: US-05-032 dương · Khai báo thao tác của bộ điều hợp
    Biết phiên bản ở `DRAFT`
    Khi người dùng bấm "+ Thao tác" ở UI-05-10
    Thì hệ thống trả `200` thao tác đã lưu; cảnh báo nếu thiếu lược đồ phản hồi
    Và phiên bản nháp có thao tác mới, cần kiểm thử lại trước khi gửi duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-032 @FR-05-032 @M @âm
  Kịch bản: US-05-032 âm 1 · Phiên bản không phải `DRAFT`
    Biết phiên bản ở `DRAFT`
    Khi phiên bản không phải `DRAFT`
    Thì hệ thống từ chối với ERR-05-008 (409)
    Và người dùng thấy thông báo "Phiên bản {n} đã gửi duyệt hoặc đã duyệt. Tạo phiên bản nháp mới để sửa."

  @US-05-032 @FR-05-032 @M @âm
  Kịch bản: US-05-032 âm 2 · Đặc tả giao thức sai
    Biết phiên bản ở `DRAFT`
    Khi đặc tả giao thức sai
    Thì hệ thống từ chối với ERR-05-032 (422)
    Và người dùng thấy thông báo "Đặc tả thao tác không hợp lệ: {danh sách trường sai}."

  @US-05-033 @FR-05-033 @M
  Kịch bản: US-05-033 dương · Bộ điều hợp REST/HTTP
    Biết phiên bản bộ điều hợp `APPROVED`; kết nối loại HTTP có giá trị `ENABLED` ở môi trường chạy
    Khi luồng đi tới chặng dùng Kamelet sinh của thao tác
    Thì thân JSON chuẩn; tiêu đề `dh-adapter-status`, `dh-adapter-pages`

  @US-05-033 @FR-05-033 @M @âm
  Kịch bản: US-05-033 âm 1 · `429`
    Biết phiên bản bộ điều hợp `APPROVED`; kết nối loại HTTP có giá trị `ENABLED` ở môi trường chạy
    Khi `429`
    Thì hệ thống từ chối với ERR-05-106

  @US-05-033 @FR-05-033 @M @âm
  Kịch bản: US-05-033 âm 2 · `4xx` khác
    Biết phiên bản bộ điều hợp `APPROVED`; kết nối loại HTTP có giá trị `ENABLED` ở môi trường chạy
    Khi `4xx` khác
    Thì lỗi nghiệp vụ, không thử lại; trả mã và thân lỗi của HTTT

  @US-05-034 @FR-05-034 @M
  Kịch bản: US-05-034 dương · Bộ điều hợp SOAP
    Biết như FR-05-033, kết nối loại SOAP
    Khi khai báo: người dùng tải WSDL ở UI-05-10. Chạy: luồng đi tới chặng dùng Kamelet sinh
    Thì thân JSON chuẩn
    Và sự kiện được phát: EVT-05-06 khi đổi sức khỏe do `WSDL_DRIFT`

  @US-05-034 @FR-05-034 @M @âm
  Kịch bản: US-05-034 âm 1 · `SOAP Fault`
    Biết như FR-05-033, kết nối loại SOAP
    Khi `SOAP Fault`
    Thì hệ thống từ chối với ERR-05-107

  @US-05-034 @FR-05-034 @M @âm
  Kịch bản: US-05-034 âm 2 · WSDL lệch ở thao tác đang dùng (đổi tên, đổi kiểu, thêm phần tử bắt buộc)
    Biết như FR-05-033, kết nối loại SOAP
    Khi WSDL lệch ở thao tác đang dùng (đổi tên, đổi kiểu, thêm phần tử bắt buộc)
    Thì ghi cảnh báo chi tiết theo thao tác, sức khỏe `DEGRADED` lý do `WSDL_DRIFT` (BR-05-023); UI-05-09 hiện thông báo
    Và người dùng thấy thông báo "WSDL của HTTT đã đổi ở thao tác {mã}. Xem khác biệt và cập nhật phiên bản nháp."

  @US-05-035 @FR-05-035 @M
  Kịch bản: US-05-035 dương · Bộ điều hợp hàng đợi bản tin (JMS, AMQP, MQTT, Kafka ngoài)
    Biết như FR-05-033, kết nối loại JMS, AMQP, MQTT hoặc `kafka-external`
    Khi `INBOUND`: luồng PH-04 đã phát hành dùng Kamelet nguồn của thao tác
    Thì bản tin JSON chuẩn kèm tiêu đề `dh-*` (`INBOUND`); xác nhận gửi (`OUTBOUND`)

  @US-05-035 @FR-05-035 @M @âm
  Kịch bản: US-05-035 âm 1 · Mất kết nối
    Biết như FR-05-033, kết nối loại JMS, AMQP, MQTT hoặc `kafka-external`
    Khi mất kết nối
    Thì hệ thống từ chối với ERR-05-114

  @US-05-035 @FR-05-035 @M @âm
  Kịch bản: US-05-035 âm 2 · Bản tin không giải mã được
    Biết như FR-05-033, kết nối loại JMS, AMQP, MQTT hoặc `kafka-external`
    Khi bản tin không giải mã được
    Thì chuyển hàng đợi lỗi của môi giới nếu có, ngược lại DLQ của PH-04

  @US-05-036 @FR-05-036 @M
  Kịch bản: US-05-036 dương · Bộ điều hợp tệp và SFTP, FTPS, thư mục chia sẻ
    Biết như FR-05-033, kết nối loại SFTP, FTPS hoặc thư mục chia sẻ
    Khi `POLL`: theo `schedule` hoặc `pollIntervalSeconds`
    Thì bản tin JSON chuẩn theo `recordMode`; tiêu đề `dh-file-name`, `dh-file-record`, `dh-file-checksum`
    Và tệp nguồn ở `archiveDirectory` hoặc `errorDirectory`

  @US-05-036 @FR-05-036 @M @âm
  Kịch bản: US-05-036 âm 1 · Tệp vượt `maxFileSizeMb`
    Biết như FR-05-033, kết nối loại SFTP, FTPS hoặc thư mục chia sẻ
    Khi tệp vượt `maxFileSizeMb`
    Thì chuyển `errorDirectory`

  @US-05-036 @FR-05-036 @M @âm
  Kịch bản: US-05-036 âm 2 · Tỷ lệ bản ghi lỗi vượt `maxErrorRatio` (mặc định 10%)
    Biết như FR-05-033, kết nối loại SFTP, FTPS hoặc thư mục chia sẻ
    Khi tỷ lệ bản ghi lỗi vượt `maxErrorRatio` (mặc định 10%)
    Thì hệ thống từ chối với ERR-05-113

  @US-05-037 @FR-05-037 @S
  Kịch bản: US-05-037 dương · Bộ điều hợp thư điện tử
    Biết như FR-05-033, kết nối loại `smtp` hoặc `imap`
    Khi gửi: luồng đi tới chặng gửi thư
    Thì gửi: mã thư của máy chủ
    Và thư đã xử lý nằm ở thư mục đã xử lý hoặc cách ly
    Và sự kiện được phát: Cảnh báo an ninh qua PH-13 khi có mã độc

  @US-05-037 @FR-05-037 @S @âm
  Kịch bản: US-05-037 âm 1 · Địa chỉ nhận ngoài miền cho phép
    Biết như FR-05-033, kết nối loại `smtp` hoặc `imap`
    Khi địa chỉ nhận ngoài miền cho phép
    Thì hệ thống từ chối với ERR-05-003
    Và người dùng thấy thông báo "Địa chỉ {địa chỉ} không thuộc miền được phép của bộ điều hợp."

  @US-05-038 @FR-05-038 @M
  Kịch bản: US-05-038 dương · Bộ điều hợp CSDL theo truy vấn khai báo
    Biết kết nối `db-flow` (FR-05-023); luồng có tài khoản `ISSUED` (FR-05-024)
    Khi khai báo: ở UI-05-10. Chạy: luồng gọi thao tác, hoặc theo `schedule` với `INBOUND` đọc định kỳ
    Thì mảng bản ghi JSON; tiêu đề `dh-rows`, `dh-truncated`
    Và mốc đọc cập nhật (nếu đọc định kỳ)
    Và sự kiện được phát: EVT-05-14 mỗi câu lệnh

  @US-05-038 @FR-05-038 @M @âm
  Kịch bản: US-05-038 âm 1 · Câu lệnh sai khi khai báo
    Biết kết nối `db-flow` (FR-05-023); luồng có tài khoản `ISSUED` (FR-05-024)
    Khi câu lệnh sai khi khai báo
    Thì hệ thống từ chối với ERR-05-032 (422)
    Và người dùng thấy thông báo "Câu lệnh không được phép: {lý do}. Chỉ dùng một câu SELECT với tham số :#tên."

  @US-05-038 @FR-05-038 @M @âm
  Kịch bản: US-05-038 âm 2 · Vượt `maxRows` khi `onTruncate
    Biết kết nối `db-flow` (FR-05-023); luồng có tài khoản `ISSUED` (FR-05-024)
    Khi vượt `maxRows` khi `onTruncate
    Thì hệ thống từ chối với ERR-05-111

  @US-05-039 @FR-05-039 @C
  Kịch bản: US-05-039 dương · Bộ điều hợp LDAP
    Biết như FR-05-033, kết nối loại LDAP
    Khi luồng đi tới chặng tra cứu
    Thì mảng bản ghi JSON

  @US-05-039 @FR-05-039 @C @âm
  Kịch bản: US-05-039 âm 1 · Khai báo thao tác ghi
    Biết như FR-05-033, kết nối loại LDAP
    Khi khai báo thao tác ghi
    Thì hệ thống từ chối với ERR-05-032 (422)
    Và người dùng thấy thông báo "Bộ điều hợp LDAP chỉ hỗ trợ tra cứu."

  @US-05-040 @FR-05-040 @M
  Kịch bản: US-05-040 dương · Chuyển đổi định dạng về JSON chuẩn
    Biết thao tác có `responseFormat` (và `requestFormat` với chiều ngược)
    Khi mỗi phản hồi của thao tác; hoặc người dùng bấm "Xem trước chuyển đổi" ở UI-05-10
    Thì JSON chuẩn; với xem trước: hai cột gốc và JSON, danh sách cảnh báo

  @US-05-040 @FR-05-040 @M @âm
  Kịch bản: US-05-040 âm 1 · Khai mã hóa `VNI`
    Biết thao tác có `responseFormat` (và `requestFormat` với chiều ngược)
    Khi khai mã hóa `VNI`
    Thì hệ thống từ chối với ERR-05-032 (422)
    Và người dùng thấy thông báo "Mã hóa VNI không được hỗ trợ. Đề nghị HTTT xuất UTF-8."

  @US-05-040 @FR-05-040 @M @âm
  Kịch bản: US-05-040 âm 2 · Kết quả sai lược đồ khi chạy
    Biết thao tác có `responseFormat` (và `requestFormat` với chiều ngược)
    Khi kết quả sai lược đồ khi chạy
    Thì hệ thống từ chối với ERR-05-108

  @US-05-041 @FR-05-041 @M
  Kịch bản: US-05-041 dương · Chuẩn hóa giá trị thiếu và giá trị đặc biệt
    Biết thao tác có bảng quy tắc `normalization`
    Khi sau bước chuyển đổi định dạng (FR-05-040), mỗi bản ghi
    Thì bản ghi đã chuẩn hóa; chỉ số thiếu theo trường

  @US-05-041 @FR-05-041 @M @âm
  Kịch bản: US-05-041 âm 1 · Bản tin đơn lẻ bị `REJECT`
    Biết thao tác có bảng quy tắc `normalization`
    Khi bản tin đơn lẻ bị `REJECT`
    Thì hệ thống từ chối với ERR-05-109

  @US-05-042 @FR-05-042 @M
  Kịch bản: US-05-042 dương · Nhóm kết nối và giới hạn đồng thời theo HTTT
    Biết phiên bản bộ điều hợp `APPROVED` có `maxConcurrency`
    Khi mỗi lượt gọi qua bộ điều hợp; mỗi khi số bản sao `dh-runtime` đổi
    Thì chỉ số `dh_adapter_pool_active`, `dh_adapter_pool_wait_seconds`, `dh_adapter_pool_exhausted_total`

  @US-05-042 @FR-05-042 @M @âm
  Kịch bản: US-05-042 âm 1 · Nhóm cạn
    Biết phiên bản bộ điều hợp `APPROVED` có `maxConcurrency`
    Khi nhóm cạn
    Thì hệ thống từ chối với ERR-05-105

  @US-05-043 @FR-05-043 @M
  Kịch bản: US-05-043 dương · Kiểm thử bộ điều hợp
    Biết phiên bản có ít nhất một thao tác; kết nối có giá trị ở môi trường kiểm thử
    Khi người dùng bấm "Kiểm thử" (một thao tác hoặc tất cả) ở UI-05-09 tab Kiểm thử hoặc UI-05-10
    Thì hệ thống trả `202` kèm `testId`; kết quả đọc ở API-05-053
    Và kết quả kiểm thử gắn với phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-043 @FR-05-043 @M @âm
  Kịch bản: US-05-043 âm 1 · Chọn PROD
    Biết phiên bản có ít nhất một thao tác; kết nối có giá trị ở môi trường kiểm thử
    Khi chọn PROD
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Không kiểm thử bộ điều hợp trên môi trường PROD."

  @US-05-043 @FR-05-043 @M @âm
  Kịch bản: US-05-043 âm 2 · Thao tác `WRITE` chưa xác nhận
    Biết phiên bản có ít nhất một thao tác; kết nối có giá trị ở môi trường kiểm thử
    Khi thao tác `WRITE` chưa xác nhận
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Cần xác nhận môi trường TEST của HTTT cho phép ghi thử."

  @US-05-044 @FR-05-044 @M
  Kịch bản: US-05-044 dương · Gửi duyệt, duyệt phiên bản; tạm dừng, tiếp tục, ngừng dùng bộ điều hợp
    Biết gửi duyệt: phiên bản `DRAFT`
    Khi các nút "Gửi duyệt", "Tạm dừng", "Tiếp tục", "Ngừng dùng" ở UI-05-09; "Duyệt", "Từ chối" ở UI-05-17
    Thì hệ thống trả `200`, phiên bản hoặc bộ điều hợp với trạng thái mới
    Và trạng thái phiên bản, bộ điều hợp và Kamelet sinh khớp nhau
    Và sự kiện được phát: EVT-05-07, EVT-05-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-044 @FR-05-044 @M @âm
  Kịch bản: US-05-044 âm 1 · Chuyển trạng thái không hợp lệ
    Biết gửi duyệt: phiên bản `DRAFT`
    Khi chuyển trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-05-008 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi phiên bản đang ở {trạng thái}."

  @US-05-044 @FR-05-044 @M @âm
  Kịch bản: US-05-044 âm 2 · Chưa kiểm thử đạt
    Biết gửi duyệt: phiên bản `DRAFT`
    Khi chưa kiểm thử đạt
    Thì hệ thống từ chối với ERR-05-009 (409)
    Và người dùng thấy thông báo "Chưa có kiểm thử đạt trong 24 giờ cho thao tác {mã}."

  @US-05-045 @FR-05-045 @S
  Kịch bản: US-05-045 dương · Phiên bản bộ điều hợp và chế độ so sánh
    Biết bộ điều hợp có phiên bản hiệu lực; với so sánh, bản nháp đã kiểm thử đạt
    Khi người dùng bấm "Tạo phiên bản mới" hoặc "So sánh trên lưu lượng thật" ở UI-05-09 tab Phiên bản
    Thì hệ thống trả `201` phiên bản nháp; so sánh `202` kèm `comparisonId`, kết quả ở API-05-064
    Và kết quả của phiên bản nháp không bao giờ trả cho luồng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-045 @FR-05-045 @S @âm
  Kịch bản: US-05-045 âm 1 · Đã có bản nháp
    Biết bộ điều hợp có phiên bản hiệu lực; với so sánh, bản nháp đã kiểm thử đạt
    Khi đã có bản nháp
    Thì hệ thống từ chối với ERR-05-008 (409)
    Và người dùng thấy thông báo "Bộ điều hợp đã có phiên bản nháp {n}. Mở bản đó để sửa."

  @US-05-046 @FR-05-046 @S
  Kịch bản: US-05-046 dương · Sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL
    Biết HTTT `ACTIVE`; có kết nối (nếu tải đặc tả qua URL)
    Khi người dùng bấm "Tạo từ đặc tả" ở UI-05-08, mở UI-05-11
    Thì hệ thống trả `201`, bộ điều hợp nháp với danh sách đề xuất cần xác nhận
    Và bộ điều hợp `DRAFT`; không tự sinh ánh xạ ngữ nghĩa (gợi ý ánh xạ trường là việc của DataMapper PH-04)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-046 @FR-05-046 @S @âm
  Kịch bản: US-05-046 âm 1 · Lỗi cú pháp hoặc không tải được
    Biết HTTT `ACTIVE`; có kết nối (nếu tải đặc tả qua URL)
    Khi lỗi cú pháp hoặc không tải được
    Thì hệ thống từ chối với ERR-05-023 (422)
    Và người dùng thấy thông báo "Không phân tích được đặc tả ở dòng {d}, cột {c}: {lý do}."

  @US-05-047 @FR-05-047 @M
  Kịch bản: US-05-047 dương · Đưa bộ điều hợp vào bảng thành phần của trình thiết kế
    Biết phiên bản bộ điều hợp vừa chuyển `APPROVED` (FR-05-044)
    Khi sự kiện duyệt phiên bản
    Thì Kamelet sinh trong catalog
    Và Kamelet sinh không sửa tay được
    Và sự kiện được phát: EVT-05-07 (phát ở FR-05-044)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-047 @FR-05-047 @M @âm
  Kịch bản: US-05-047 âm 1 · Sinh Kamelet thất bại kiểm tra tĩnh (lỗi nội bộ)
    Biết phiên bản bộ điều hợp vừa chuyển `APPROVED` (FR-05-044)
    Khi sinh Kamelet thất bại kiểm tra tĩnh (lỗi nội bộ)
    Thì phiên bản vẫn `APPROVED` nhưng catalog không cập nhật; hệ thống cảnh báo TA và IE: thông báo
    Và người dùng thấy thông báo "Không sinh được thành phần cho thao tác {mã}. Liên hệ quản trị."

  # ---- EP-05-F · CDC cho hệ di sản

  @US-05-048 @FR-05-048 @M
  Kịch bản: US-05-048 dương · Khai báo cấu hình CDC
    Biết bộ điều hợp `protocol = CDC`, `systemGroup` 3 hoặc 4; kết nối loại `cdc-debezium` có giá trị `ENABLED`
    Khi người dùng mở tab CDC ở UI-05-12 và bấm "Lưu cấu hình"
    Thì hệ thống trả `200`, cấu hình CDC kèm danh sách topic
    Và CDC `STOPPED`; topic và lược đồ đã đăng ký ở PH-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-048 @FR-05-048 @M @âm
  Kịch bản: US-05-048 âm 1 · Bảng ngoài phạm vi
    Biết bộ điều hợp `protocol = CDC`, `systemGroup` 3 hoặc 4; kết nối loại `cdc-debezium` có giá trị `ENABLED`
    Khi bảng ngoài phạm vi
    Thì hệ thống từ chối với ERR-05-027 (422)
    Và người dùng thấy thông báo "Bảng {tên} nằm ngoài phạm vi cho phép của kết nối."

  @US-05-048 @FR-05-048 @M @âm
  Kịch bản: US-05-048 âm 2 · Quá số bảng
    Biết bộ điều hợp `protocol = CDC`, `systemGroup` 3 hoặc 4; kết nối loại `cdc-debezium` có giá trị `ENABLED`
    Khi quá số bảng
    Thì hệ thống từ chối với ERR-05-030 (422)
    Và người dùng thấy thông báo "Vượt số bảng CDC tối đa {n} của tỉnh."

  @US-05-049 @FR-05-049 @M
  Kịch bản: US-05-049 dương · Kiểm tra điều kiện CDC ở CSDL nguồn
    Biết cấu hình CDC đã lưu (FR-05-048)
    Khi người dùng bấm "Kiểm tra điều kiện" ở UI-05-12; bắt buộc trong 24 giờ trước khi chạy
    Thì hệ thống trả `200`, danh sách mục kiểm tra với kết quả và hướng dẫn
    Và kết quả kiểm tra gắn với cấu hình CDC, có hiệu lực 24 giờ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-049 @FR-05-049 @M @âm
  Kịch bản: US-05-049 âm 1 · Có mục không đạt
    Biết cấu hình CDC đã lưu (FR-05-048)
    Khi có mục không đạt
    Thì hệ thống từ chối với ERR-05-025
    Và người dùng thấy thông báo "CSDL nguồn chưa đáp ứng điều kiện CDC: {mục}. Gửi hướng dẫn cho đơn vị chủ quản."

  @US-05-050 @FR-05-050 @M
  Kịch bản: US-05-050 dương · Chạy, tạm dừng, tiếp tục và dừng CDC
    Biết chạy: điều kiện CDC đạt trong 24 giờ (FR-05-049); bộ điều hợp có phiên bản `APPROVED`
    Khi các nút "Chạy", "Tạm dừng", "Tiếp tục", "Dừng hẳn" ở UI-05-12
    Thì hệ thống trả `202`, trạng thái CDC mới (khi connector xác nhận)
    Và trạng thái CDC và connector khớp nhau
    Và sự kiện được phát: EVT-05-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-050 @FR-05-050 @M @âm
  Kịch bản: US-05-050 âm 1 · Chưa kiểm tra điều kiện đạt
    Biết chạy: điều kiện CDC đạt trong 24 giờ (FR-05-049); bộ điều hợp có phiên bản `APPROVED`
    Khi chưa kiểm tra điều kiện đạt
    Thì hệ thống từ chối với ERR-05-009 (409)
    Và người dùng thấy thông báo "Chưa có kiểm tra điều kiện CDC đạt trong 24 giờ."

  @US-05-050 @FR-05-050 @M @âm
  Kịch bản: US-05-050 âm 2 · Tiếp tục khi còn thay đổi lược đồ chờ
    Biết chạy: điều kiện CDC đạt trong 24 giờ (FR-05-049); bộ điều hợp có phiên bản `APPROVED`
    Khi tiếp tục khi còn thay đổi lược đồ chờ
    Thì hệ thống từ chối với ERR-05-026 (409)
    Và người dùng thấy thông báo "Còn {n} thay đổi lược đồ chưa xử lý."

  @US-05-051 @FR-05-051 @M
  Kịch bản: US-05-051 dương · Giám sát và xử lý thay đổi lược đồ
    Biết CDC đang `SNAPSHOTTING` hoặc `STREAMING`
    Khi connector ghi bản ghi lịch sử lược đồ hoặc sự kiện thay đổi cấu trúc; người xử lý mở UI-05-13
    Thì danh sách thay đổi chờ (API-05-074); trạng thái sau xử lý
    Và lược đồ ở PH-10 khớp nguồn; topic `.v2` (nếu `ACCEPT`) đã đăng ký
    Và sự kiện được phát: EVT-05-11 khi phát hiện; EVT-05-12 khi trạng thái CDC đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-051 @FR-05-051 @M @âm
  Kịch bản: US-05-051 âm 1 · Tiếp tục khi còn thay đổi chờ
    Biết CDC đang `SNAPSHOTTING` hoặc `STREAMING`
    Khi tiếp tục khi còn thay đổi chờ
    Thì hệ thống từ chối với ERR-05-026 (409)
    Và người dùng thấy thông báo "Còn {n} thay đổi lược đồ chưa xử lý."

  @US-05-051 @FR-05-051 @M @âm
  Kịch bản: US-05-051 âm 2 · Ghi chú ngắn
    Biết CDC đang `SNAPSHOTTING` hoặc `STREAMING`
    Khi ghi chú ngắn
    Thì hệ thống từ chối với ERR-05-003 (400)
    Và người dùng thấy thông báo "Ghi chú tối thiểu 10 ký tự."

  @US-05-052 @FR-05-052 @M
  Kịch bản: US-05-052 dương · Theo dõi trạng thái CDC
    Biết bộ điều hợp có cấu hình CDC
    Khi người dùng mở UI-05-12; màn tự làm mới mỗi 30 giây
    Thì hệ thống trả `200`, các khối số liệu nêu trên
    Và sự kiện được phát: EVT-05-06 khi sức khỏe đổi do độ trễ

  @US-05-052 @FR-05-052 @M @âm
  Kịch bản: US-05-052 âm 1 · Độ trễ vượt `05.cdc.lag-alert-seconds` (mặc định 300)
    Biết bộ điều hợp có cấu hình CDC
    Khi độ trễ vượt `05.cdc.lag-alert-seconds` (mặc định 300)
    Thì sức khỏe `DEGRADED`; vượt 4 lần ngưỡng: `UNHEALTHY`

  @US-05-052 @FR-05-052 @M @âm
  Kịch bản: US-05-052 âm 2 · Kafka Connect không trả lời
    Biết bộ điều hợp có cấu hình CDC
    Khi Kafka Connect không trả lời
    Thì hệ thống từ chối với ERR-05-029 (503)
    Và người dùng thấy thông báo "Chưa lấy được trạng thái CDC. Số liệu là của lần tải trước lúc {thời điểm}."

  @US-05-053 @FR-05-053 @S
  Kịch bản: US-05-053 dương · Chụp ảnh lại dữ liệu nguồn
    Biết CDC `FAILED` do mất nhật ký (ERR-05-117), hoặc `STREAMING` khi người dùng cần nạp lại một số bảng
    Khi người dùng bấm "Chụp ảnh lại" ở UI-05-12, hoặc chọn `RESNAPSHOT` ở FR-05-051
    Thì hệ thống trả `202`, tiến độ chụp ảnh ở FR-05-052
    Và CDC về `STREAMING` sau khi chụp ảnh xong
    Và sự kiện được phát: EVT-05-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-053 @FR-05-053 @S @âm
  Kịch bản: US-05-053 âm 1 · Thiếu lý do
    Biết CDC `FAILED` do mất nhật ký (ERR-05-117), hoặc `STREAMING` khi người dùng cần nạp lại một số bảng
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-05-038 (400)
    Và người dùng thấy thông báo "Nhập lý do chụp ảnh lại."

  # ---- EP-05-G · Danh mục Kamelet được duyệt

  @US-05-054 @FR-05-054 @M
  Kịch bản: US-05-054 dương · Liệt kê danh mục Kamelet
    Biết người dùng đăng nhập vào tenant
    Khi người dùng mở UI-05-14 từ menu "Kết nối · Kamelet"
    Thì hệ thống trả `200`, trang kết quả kèm `facets`

  @US-05-054 @FR-05-054 @M @âm
  Kịch bản: US-05-054 âm 1 · Bộ lọc sai
    Biết người dùng đăng nhập vào tenant
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-05-003 (400)

  @US-05-055 @FR-05-055 @M
  Kịch bản: US-05-055 dương · Xem chi tiết Kamelet
    Biết Kamelet khả dụng với tenant
    Khi người dùng bấm một mục ở UI-05-14, hoặc liên kết từ trình thiết kế, việc duyệt
    Thì hệ thống trả `200`, chi tiết; YAML ở API-05-078

  @US-05-056 @FR-05-056 @M
  Kịch bản: US-05-056 dương · Soạn, kiểm tra tĩnh và gửi đăng ký Kamelet
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi người dùng soạn hoặc tải YAML ở UI-05-16 rồi bấm "Kiểm tra" và "Gửi duyệt"; hoặc PH-04 gửi từ trình thiết kế
    Thì phiên bản Kamelet và báo cáo kiểm tra: `findings[]` (mã quy tắc, mức, dòng, cột, thông điệp)
    Và `SUBMITTED` nằm trong hộp việc của IA
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-056 @FR-05-056 @M @âm
  Kịch bản: US-05-056 âm 1 · Tên trùng
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi tên trùng
    Thì hệ thống từ chối với ERR-05-002 (409)
    Và người dùng thấy thông báo "Tên {tên} đã được dùng. Chọn tên khác."

  @US-05-056 @FR-05-056 @M @âm
  Kịch bản: US-05-056 âm 2 · Vi phạm chính sách tĩnh
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi vi phạm chính sách tĩnh
    Thì hệ thống từ chối với ERR-05-020 (422)
    Và người dùng thấy thông báo "Kamelet vi phạm {n} quy tắc. Xem từng dòng trong báo cáo kiểm tra."

  @US-05-057 @FR-05-057 @M
  Kịch bản: US-05-057 dương · Duyệt hoặc từ chối Kamelet
    Biết phiên bản `SUBMITTED`
    Khi người duyệt mở việc ở UI-05-17
    Thì hệ thống trả `200`, phiên bản với trạng thái mới
    Và catalog đã làm mới
    Và sự kiện được phát: EVT-05-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-057 @FR-05-057 @M @âm
  Kịch bản: US-05-057 âm 1 · Bốn mắt
    Biết phiên bản `SUBMITTED`
    Khi bốn mắt
    Thì hệ thống từ chối với ERR-05-011 (403)
    Và người dùng thấy thông báo "Anh/chị là người gửi Kamelet này nên không được tự duyệt."

  @US-05-057 @FR-05-057 @M @âm
  Kịch bản: US-05-057 âm 2 · Kamelet `COMMON` chưa có ý kiến SO
    Biết phiên bản `SUBMITTED`
    Khi Kamelet `COMMON` chưa có ý kiến SO
    Thì hệ thống từ chối với ERR-05-017 (409)
    Và người dùng thấy thông báo "Cần ý kiến đồng ý của cán bộ ATTT trước khi duyệt Kamelet dùng chung."

  @US-05-058 @FR-05-058 @M
  Kịch bản: US-05-058 dương · Ngừng khuyến nghị và thu hồi Kamelet
    Biết phiên bản `APPROVED` (ngừng khuyến nghị) hoặc `APPROVED`, `DEPRECATED` (thu hồi)
    Khi người dùng bấm "Ngừng khuyến nghị" hoặc "Thu hồi" ở UI-05-15
    Thì hệ thống trả `200`, phiên bản với trạng thái mới, số luồng bị ảnh hưởng
    Và runtime báo ERR-05-120 khi nạp luồng dùng Kamelet đã thu hồi
    Và sự kiện được phát: EVT-05-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-058 @FR-05-058 @M @âm
  Kịch bản: US-05-058 âm 1 · Thiếu lý do
    Biết phiên bản `APPROVED` (ngừng khuyến nghị) hoặc `APPROVED`, `DEPRECATED` (thu hồi)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-05-038 (400)
    Và người dùng thấy thông báo "Nhập lý do thu hồi."

  @US-05-058 @FR-05-058 @M @âm
  Kịch bản: US-05-058 âm 2 · Tenant tỉnh thao tác trên Kamelet `COMMON`
    Biết phiên bản `APPROVED` (ngừng khuyến nghị) hoặc `APPROVED`, `DEPRECATED` (thu hồi)
    Khi tenant tỉnh thao tác trên Kamelet `COMMON`
    Thì hệ thống từ chối với ERR-05-040 (403)
    Và người dùng thấy thông báo "Kamelet dùng chung chỉ quản trị nền tảng được thu hồi."

  @US-05-059 @FR-05-059 @M
  Kịch bản: US-05-059 dương · Đồng bộ danh mục Kamelet với catalog trình thiết kế và runtime
    Biết có hồ sơ runtime mặc định và `runtime-manifest.json`
    Khi Kamelet đổi trạng thái (EVT-05-09, EVT-05-10); PH-04 nạp catalog; runtime nạp luồng; nền tảng nâng runtime
    Thì danh mục Kamelet có băm
    Và catalog trình thiết kế và runtime khớp nhau theo băm

  @US-05-059 @FR-05-059 @M @âm
  Kịch bản: US-05-059 âm 1 · Runtime yêu cầu băm không có
    Biết có hồ sơ runtime mặc định và `runtime-manifest.json`
    Khi runtime yêu cầu băm không có
    Thì `404`, runtime từ chối nạp luồng và báo lỗi cấu hình

  @US-05-059 @FR-05-059 @M @âm
  Kịch bản: US-05-059 âm 2 · Kamelet đã thu hồi
    Biết có hồ sơ runtime mặc định và `runtime-manifest.json`
    Khi Kamelet đã thu hồi
    Thì hệ thống từ chối với ERR-05-120

  @US-05-060 @FR-05-060 @S
  Kịch bản: US-05-060 dương · Đề xuất Kamelet của tỉnh thành dùng chung
    Biết phiên bản `APPROVED` của Kamelet `TENANT`
    Khi người dùng bấm "Đề xuất dùng chung" ở UI-05-15
    Thì hệ thống trả `202`, bản sao `SUBMITTED` ở `COMMON`
    Và Kamelet ở tỉnh đề xuất giữ nguyên tới khi chủ sở hữu chủ động chuyển
    Và sự kiện được phát: EVT-05-09 khi được duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-060 @FR-05-060 @S @âm
  Kịch bản: US-05-060 âm 1 · Phiên bản chưa `APPROVED`
    Biết phiên bản `APPROVED` của Kamelet `TENANT`
    Khi phiên bản chưa `APPROVED`
    Thì hệ thống từ chối với ERR-05-008 (409)
    Và người dùng thấy thông báo "Chỉ đề xuất được phiên bản đã duyệt."

  # ---- EP-05-H · Quản trị

  @US-05-061 @FR-05-061 @M
  Kịch bản: US-05-061 dương · Tham số phân hệ theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi người dùng mở trang Tham số PH-05 ở cấu hình tenant (PH-18)
    Thì hệ thống trả `200`, tham số mới kèm phiên bản cấu hình
    Và có phiên bản cấu hình mới ở PH-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-061 @FR-05-061 @M @âm
  Kịch bản: US-05-061 âm 1 · Tắt loại đang có kết nối `ACTIVE` mà không chọn `blockNew`
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tắt loại đang có kết nối `ACTIVE` mà không chọn `blockNew`
    Thì hệ thống từ chối với ERR-05-010 (409)
    Và người dùng thấy thông báo "Còn {n} kết nối đang dùng loại này. Chọn 'Chỉ chặn tạo mới' hoặc ngừng dùng các kết nối trước."

  @US-05-062 @FR-05-062 @S
  Kịch bản: US-05-062 dương · Báo cáo sử dụng kết nối và bộ điều hợp
    Biết có dữ liệu sử dụng của tháng
    Khi người dùng mở báo cáo ở UI-05-07 ("Báo cáo tháng") hoặc PH-16 gọi API
    Thì hệ thống trả `200` báo cáo; tệp CSV, XLSX
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-05-062 @FR-05-062 @S @âm
  Kịch bản: US-05-062 âm 1 · Tháng chưa có dữ liệu
    Biết có dữ liệu sử dụng của tháng
    Khi tháng chưa có dữ liệu
    Thì `200` với số liệu rỗng và ghi chú thông báo
    Và người dùng thấy thông báo "Chưa có dữ liệu cho tháng {tháng}."
