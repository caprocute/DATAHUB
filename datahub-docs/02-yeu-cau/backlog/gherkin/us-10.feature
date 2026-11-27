# language: vi
# Sinh tự động từ D02-02/D02-03-PH10 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-10
Tính năng: PH-10 · Sự kiện

  # ---- EP-10-A · Dự án tích hợp

  @US-10-001 @FR-10-001 @M
  Kịch bản: US-10-001 dương · Liệt kê, tìm kiếm và lọc dự án tích hợp
    Biết đã chọn tenant làm việc (FR-00-004)
    Khi người dùng mở menu "Tích hợp › Dự án" (UI-10-02) hoặc đổi bộ lọc, ô tìm, trang, cột sắp xếp
    Thì hệ thống trả `200`: `items[]` gồm `projectCode`, `name`, `ownerOrgCode`, `status`, `topicCount`, `publisherCount`, `subscriberCount`, `maxLagSeconds`, `updatedAt`; `page`, `size`, `totalElements`, `facets`

  @US-10-001 @FR-10-001 @M @âm
  Kịch bản: US-10-001 âm 1 · Tham số sai miền
    Biết đã chọn tenant làm việc (FR-00-004)
    Khi tham số sai miền
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."

  @US-10-002 @FR-10-002 @M
  Kịch bản: US-10-002 dương · Xem chi tiết dự án
    Biết dự án tồn tại trong tenant
    Khi người dùng bấm một dòng ở UI-10-02 hoặc mở đường dẫn `/tich-hop/du-an/{projectCode}`
    Thì hệ thống trả `200`, chi tiết dự án; tiêu đề `ETag`

  @US-10-002 @FR-10-002 @M @âm
  Kịch bản: US-10-002 âm 1 · Không tìm thấy
    Biết dự án tồn tại trong tenant
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy dự án {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-10-003 @FR-10-003 @M
  Kịch bản: US-10-003 dương · Tạo dự án tích hợp
    Biết tenant `ACTIVE`; không vượt `10.quota.max-projects`
    Khi người dùng bấm "+ Tạo dự án" ở UI-10-02, điền biểu mẫu UI-10-04 rồi bấm "Lưu"
    Thì hệ thống trả `201`, thân như FR-10-002; tiêu đề `Location`, `ETag`
    Và dự án `ACTIVE`, chưa có topic
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-003 @FR-10-003 @M @âm
  Kịch bản: US-10-003 âm 1 · Mã sai mẫu hoặc trùng từ dành riêng
    Biết tenant `ACTIVE`; không vượt `10.quota.max-projects`
    Khi mã sai mẫu hoặc trùng từ dành riêng
    Thì hệ thống từ chối với ERR-10-003 (400)
    Và người dùng thấy thông báo "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."

  @US-10-003 @FR-10-003 @M @âm
  Kịch bản: US-10-003 âm 2 · Mã trùng
    Biết tenant `ACTIVE`; không vượt `10.quota.max-projects`
    Khi mã trùng
    Thì hệ thống từ chối với ERR-10-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."

  @US-10-004 @FR-10-004 @M
  Kịch bản: US-10-004 dương · Sửa dự án
    Biết dự án `ACTIVE`
    Khi người dùng bấm "Sửa" ở UI-10-03, đổi trường ở UI-10-04 rồi bấm "Lưu"
    Thì hệ thống trả `200`, chi tiết dự án; `ETag`
    Và dự án giữ mã và trạng thái, thông tin mô tả đã đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-004 @FR-10-004 @M @âm
  Kịch bản: US-10-004 âm 1 · Gửi kèm `projectCode` khác
    Biết dự án `ACTIVE`
    Khi gửi kèm `projectCode` khác
    Thì hệ thống từ chối với ERR-10-003 (400)
    Và người dùng thấy thông báo "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."

  @US-10-004 @FR-10-004 @M @âm
  Kịch bản: US-10-004 âm 2 · Dự án đã lưu trữ
    Biết dự án `ACTIVE`
    Khi dự án đã lưu trữ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi dự án đang ở trạng thái Đã lưu trữ."

  @US-10-005 @FR-10-005 @M
  Kịch bản: US-10-005 dương · Lưu trữ và khôi phục dự án
    Biết lưu trữ: dự án `ACTIVE`, không còn topic ở `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED`
    Khi người dùng bấm "Lưu trữ" hoặc "Khôi phục" ở UI-10-02, UI-10-03 và xác nhận
    Thì hệ thống trả `200`, dự án với trạng thái mới
    Và `ARCHIVED`: không nhận topic mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-005 @FR-10-005 @M @âm
  Kịch bản: US-10-005 âm 1 · Còn topic đang hoạt động
    Biết lưu trữ: dự án `ACTIVE`, không còn topic ở `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED`
    Khi còn topic đang hoạt động
    Thì hệ thống từ chối với ERR-10-010 (409)
    Và người dùng thấy thông báo "Còn {n} đối tượng phụ thuộc."

  @US-10-005 @FR-10-005 @M @âm
  Kịch bản: US-10-005 âm 2 · Thiếu lý do
    Biết lưu trữ: dự án `ACTIVE`, không còn topic ở `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  # ---- EP-10-B · Topic

  @US-10-006 @FR-10-006 @M
  Kịch bản: US-10-006 dương · Liệt kê, tìm kiếm và lọc topic
    Biết đã chọn tenant làm việc
    Khi người dùng mở "Tích hợp › Topic" (UI-10-05) hoặc đổi bộ lọc
    Thì hệ thống trả `200`: mỗi dòng `topicName`, `projectCode`, `topicKind`, `status`, `partitions`, `retentionHours`, `cleanupPolicy`, `routingMode`, `dataClass`, `latestSchemaVersion`, `publicationCount`, `subscriptionCount`, `inRatePerMinute` …

  @US-10-006 @FR-10-006 @M @âm
  Kịch bản: US-10-006 âm 1 · Tham số sai
    Biết đã chọn tenant làm việc
    Khi tham số sai
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."

  @US-10-007 @FR-10-007 @M
  Kịch bản: US-10-007 dương · Xem chi tiết topic
    Biết topic tồn tại trong tenant
    Khi người dùng bấm một dòng ở UI-10-05 hoặc mở `/tich-hop/topic/{topicName}`
    Thì hệ thống trả `200`, chi tiết topic; `ETag`

  @US-10-007 @FR-10-007 @M @âm
  Kịch bản: US-10-007 âm 1 · Không tìm thấy
    Biết topic tồn tại trong tenant
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy topic {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-10-008 @FR-10-008 @M
  Kịch bản: US-10-008 dương · Tạo topic và gửi duyệt
    Biết dự án `ACTIVE`; tenant chưa vượt `maxTopics`, `maxPartitionsTotal`
    Khi người dùng hoàn tất trình hướng dẫn UI-10-07 hoặc Drawer tạo nhanh ở UI-10-03 và bấm "Tạo" hoặc "Tạo và gửi duyệt"
    Thì hệ thống trả `201`, thân như FR-10-007 kèm `approvalRequestCode` nếu đã gửi duyệt
    Và topic `DRAFT` hoặc `PENDING_APPROVAL`; chưa có trên cụm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-008 @FR-10-008 @M @âm
  Kịch bản: US-10-008 âm 1 · Tên sai quy ước hoặc miền dành riêng
    Biết dự án `ACTIVE`; tenant chưa vượt `maxTopics`, `maxPartitionsTotal`
    Khi tên sai quy ước hoặc miền dành riêng
    Thì hệ thống từ chối với ERR-10-004 (422)
    Và người dùng thấy thông báo "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."

  @US-10-008 @FR-10-008 @M @âm
  Kịch bản: US-10-008 âm 2 · Tên trùng
    Biết dự án `ACTIVE`; tenant chưa vượt `maxTopics`, `maxPartitionsTotal`
    Khi tên trùng
    Thì hệ thống từ chối với ERR-10-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."

  @US-10-009 @FR-10-009 @M
  Kịch bản: US-10-009 dương · Duyệt tạo topic và cấp phát trên cụm
    Biết yêu cầu `TOPIC_CREATE` ở `PENDING`
    Khi người duyệt mở yêu cầu ở UI-10-13 (từ "Việc của tôi") và bấm "Duyệt" hoặc "Từ chối"
    Thì hệ thống trả `200`, yêu cầu duyệt với trạng thái mới; topic `PROVISIONING`
    Và topic `PROVISIONING` rồi `ACTIVE` trong ≤ 3 phút ở p95 (NFR-10-008); có topic DLQ
    Và sự kiện được phát: EVT-10-01 khi `ACTIVE`; EVT-10-05 cho phiên bản lược đồ 1
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-009 @FR-10-009 @M @âm
  Kịch bản: US-10-009 âm 1 · Người duyệt là người tạo hoặc người gửi
    Biết yêu cầu `TOPIC_CREATE` ở `PENDING`
    Khi người duyệt là người tạo hoặc người gửi
    Thì hệ thống từ chối với ERR-10-008 (403)
    Và người dùng thấy thông báo "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

  @US-10-009 @FR-10-009 @M @âm
  Kịch bản: US-10-009 âm 2 · Thiếu ý kiến hoặc xác nhận dữ liệu cá nhân
    Biết yêu cầu `TOPIC_CREATE` ở `PENDING`
    Khi thiếu ý kiến hoặc xác nhận dữ liệu cá nhân
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-010 @FR-10-010 @M
  Kịch bản: US-10-010 dương · Theo dõi cấp phát và xử lý cấp phát thất bại
    Biết có đối tượng `PROVISIONING` hoặc `FAILED`; đối chiếu định kỳ áp cho topic `ACTIVE`
    Khi lịch: mỗi 10 giây cho đối tượng `PROVISIONING`, mỗi 10 phút đối chiếu toàn bộ topic `ACTIVE`
    Thì thử lại, hủy: `200`, topic với trạng thái mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-010 @FR-10-010 @M @âm
  Kịch bản: US-10-010 âm 1 · Lệnh trên đối tượng đang cấp phát hoặc cấp phát lỗi
    Biết có đối tượng `PROVISIONING` hoặc `FAILED`; đối chiếu định kỳ áp cho topic `ACTIVE`
    Khi lệnh trên đối tượng đang cấp phát hoặc cấp phát lỗi
    Thì hệ thống từ chối với ERR-10-038 (409)
    Và người dùng thấy thông báo "Đối tượng đang cấp phát hoặc cấp phát lỗi."

  @US-10-010 @FR-10-010 @M @âm
  Kịch bản: US-10-010 âm 2 · Thử lại, hủy khi không ở `FAILED`
    Biết có đối tượng `PROVISIONING` hoặc `FAILED`; đối chiếu định kỳ áp cho topic `ACTIVE`
    Khi thử lại, hủy khi không ở `FAILED`
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi topic đang ở trạng thái {nhãn trạng thái}."

  @US-10-011 @FR-10-011 @M
  Kịch bản: US-10-011 dương · Tăng số phân vùng của topic đang hoạt động
    Biết topic `ACTIVE`; `routingMode` khác `SINGLE_PARTITION`
    Khi người dùng bấm "Đổi cấu hình" ở tab Cấu hình của UI-10-06, nhập số phân vùng mới và gửi
    Thì hệ thống trả `202`, yêu cầu duyệt; sau khi áp dụng, topic với `partitions` mới
    Và topic có nhiều phân vùng hơn; subscription đang chạy tự nhận phân vùng mới qua tái cân bằng
    Và sự kiện được phát: EVT-10-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-011 @FR-10-011 @M @âm
  Kịch bản: US-10-011 âm 1 · Giảm phân vùng
    Biết topic `ACTIVE`; `routingMode` khác `SINGLE_PARTITION`
    Khi giảm phân vùng
    Thì hệ thống từ chối với ERR-10-013 (422)
    Và người dùng thấy thông báo "Không giảm được số phân vùng. Chỉ được tăng."

  @US-10-011 @FR-10-011 @M @âm
  Kịch bản: US-10-011 âm 2 · Thiếu xác nhận tác động thứ tự
    Biết topic `ACTIVE`; `routingMode` khác `SINGLE_PARTITION`
    Khi thiếu xác nhận tác động thứ tự
    Thì hệ thống từ chối với ERR-10-014 (409)
    Và người dùng thấy thông báo "Tăng phân vùng làm đổi phân vùng của khóa; thứ tự giữa sự kiện cũ và mới của cùng khóa không còn bảo đảm. Đánh dấu xác nhận để tiếp tục."

  @US-10-012 @FR-10-012 @M
  Kịch bản: US-10-012 dương · Thay đổi lưu giữ và chính sách dọn (compaction)
    Biết topic `ACTIVE` hoặc `DEPRECATED`
    Khi người dùng bấm "Đổi cấu hình" ở tab Cấu hình của UI-10-06
    Thì hệ thống trả `200` (áp dụng ngay) hoặc `202` (yêu cầu duyệt) kèm danh sách subscription bị ảnh hưởng
    Và topic áp dụng cấu hình mới sau khi Strimzi báo sẵn sàng
    Và sự kiện được phát: EVT-10-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-012 @FR-10-012 @M @âm
  Kịch bản: US-10-012 âm 1 · Vượt trần
    Biết topic `ACTIVE` hoặc `DEPRECATED`
    Khi vượt trần
    Thì hệ thống từ chối với ERR-10-012 (422)
    Và người dùng thấy thông báo "Giá trị ngoài miền cho phép ({min} đến {max})."

  @US-10-012 @FR-10-012 @M @âm
  Kịch bản: US-10-012 âm 2 · Topic không ở trạng thái hợp lệ
    Biết topic `ACTIVE` hoặc `DEPRECATED`
    Khi topic không ở trạng thái hợp lệ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi topic đang ở trạng thái {nhãn trạng thái}."

  @US-10-013 @FR-10-013 @M
  Kịch bản: US-10-013 dương · Chế độ định tuyến và khóa phân vùng
    Biết chế độ đích được bật ở danh mục (FR-10-061)
    Khi khai báo ở bước Định tuyến của UI-10-07; đổi ở tab Cấu hình của UI-10-06. Mỗi lượt phát áp dụng chế độ đã khai báo
    Thì topic với `routingMode`, `partitionKeyField`
    Và cổng sự kiện và Kamelet áp dụng cấu hình mới sau ≤ 60 giây (EVT-10-02)
    Và sự kiện được phát: EVT-10-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-013 @FR-10-013 @M @âm
  Kịch bản: US-10-013 âm 1 · Tổ hợp không hợp lệ
    Biết chế độ đích được bật ở danh mục (FR-10-061)
    Khi tổ hợp không hợp lệ
    Thì hệ thống từ chối với ERR-10-046 (422)
    Và người dùng thấy thông báo "Chế độ định tuyến này cần trường khóa phân vùng, hoặc không giữ được thứ tự."

  @US-10-013 @FR-10-013 @M @âm
  Kịch bản: US-10-013 âm 2 · Đổi chiều phá vỡ
    Biết chế độ đích được bật ở danh mục (FR-10-061)
    Khi đổi chiều phá vỡ
    Thì hệ thống từ chối với ERR-10-047 (409)
    Và người dùng thấy thông báo "Thay đổi này phá vỡ bên nhận hiện có; cần tạo phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại."

  @US-10-014 @FR-10-014 @M
  Kịch bản: US-10-014 dương · Ngừng khuyến nghị và ngừng dùng topic
    Biết ngừng khuyến nghị: topic `ACTIVE`
    Khi người dùng bấm "Ngừng khuyến nghị" hoặc "Ngừng dùng" ở UI-10-06; hệ thống tự đề nghị khi tới `sunsetAt`
    Thì hệ thống trả `200`, topic với trạng thái mới; hoặc `202` kèm yêu cầu duyệt
    Và `DEPRECATED`: hoạt động bình thường với quan hệ cũ
    Và sự kiện được phát: EVT-10-03, EVT-10-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-014 @FR-10-014 @M @âm
  Kịch bản: US-10-014 âm 1 · Muốn ngừng ngay khi còn phụ thuộc mà không qua duyệt
    Biết ngừng khuyến nghị: topic `ACTIVE`
    Khi muốn ngừng ngay khi còn phụ thuộc mà không qua duyệt
    Thì hệ thống từ chối với ERR-10-010 (409)
    Và người dùng thấy thông báo "Còn {n} đối tượng phụ thuộc."

  @US-10-014 @FR-10-014 @M @âm
  Kịch bản: US-10-014 âm 2 · Trạng thái không hợp lệ
    Biết ngừng khuyến nghị: topic `ACTIVE`
    Khi trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi topic đang ở trạng thái {nhãn trạng thái}."

  @US-10-015 @FR-10-015 @M
  Kịch bản: US-10-015 dương · Tạo phiên bản chính mới của topic khi thay đổi phá vỡ
    Biết topic nguồn `ACTIVE`; chưa có topic kế nhiệm ở trạng thái khác `RETIRED`
    Khi người dùng bấm "Tạo phiên bản mới" ở UI-10-06, hoặc nút cùng tên trong kết quả kiểm tra tương thích không đạt (FR-10-018); PH-05 gọi dạng máy (FR-10-068)
    Thì hệ thống trả `201`, topic mới `DRAFT` hoặc `PENDING_APPROVAL`
    Và hai topic song song tới `sunsetAt`
    Và sự kiện được phát: EVT-10-01 (topic mới), EVT-10-03 (topic cũ)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-015 @FR-10-015 @M @âm
  Kịch bản: US-10-015 âm 1 · Đã có topic kế nhiệm
    Biết topic nguồn `ACTIVE`; chưa có topic kế nhiệm ở trạng thái khác `RETIRED`
    Khi đã có topic kế nhiệm
    Thì hệ thống từ chối với ERR-10-047 (409)
    Và người dùng thấy thông báo "Thay đổi này phá vỡ bên nhận hiện có; cần tạo phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại."

  @US-10-015 @FR-10-015 @M @âm
  Kịch bản: US-10-015 âm 2 · Các lỗi kiểm tra tên, cấu hình, lược đồ như FR-10-008
    Biết topic nguồn `ACTIVE`; chưa có topic kế nhiệm ở trạng thái khác `RETIRED`
    Khi các lỗi kiểm tra tên, cấu hình, lược đồ như FR-10-008
    Thì hệ thống từ chối thao tác

  @US-10-016 @FR-10-016 @S
  Kịch bản: US-10-016 dương · Theo dõi chuyển đổi bên nhận sang phiên bản topic mới
    Biết topic `DEPRECATED` có topic kế nhiệm
    Khi người dùng mở tab Chuyển đổi phiên bản ở UI-10-06 hoặc thẻ "topic sắp hết hạn" ở UI-10-01; lịch nhắc trước `sunsetAt` 14 và 3 ngày
    Thì hệ thống trả `200`, bảng chuyển đổi

  @US-10-016 @FR-10-016 @S @âm
  Kịch bản: US-10-016 âm 1 · Không tìm thấy topic
    Biết topic `DEPRECATED` có topic kế nhiệm
    Khi không tìm thấy topic
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy topic {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  # ---- EP-10-C · Lược đồ sự kiện

  @US-10-017 @FR-10-017 @M
  Kịch bản: US-10-017 dương · Soạn và kiểm tra lược đồ
    Biết topic không `RETIRED`; không có phiên bản khác `PENDING_APPROVAL` cho cùng topic
    Khi người dùng soạn ở UI-10-08 (hoặc bước Lược đồ của UI-10-07) và bấm "Kiểm tra" hoặc "Lưu nháp"
    Thì hệ thống trả `201` hoặc `200`, phiên bản `DRAFT` kèm danh sách lỗi, cảnh báo
    Và nháp chưa ảnh hưởng tới bên phát, bên nhận
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-017 @FR-10-017 @M @âm
  Kịch bản: US-10-017 âm 1 · Cú pháp sai
    Biết topic không `RETIRED`; không có phiên bản khác `PENDING_APPROVAL` cho cùng topic
    Khi cú pháp sai
    Thì hệ thống từ chối với ERR-10-015 (422)
    Và người dùng thấy thông báo "Lược đồ sai cú pháp ở dòng {d}, cột {c}: {thông điệp}."

  @US-10-017 @FR-10-017 @M @âm
  Kịch bản: US-10-017 âm 2 · Thiếu trường khóa
    Biết topic không `RETIRED`; không có phiên bản khác `PENDING_APPROVAL` cho cùng topic
    Khi thiếu trường khóa
    Thì hệ thống từ chối với ERR-10-017 (422)
    Và người dùng thấy thông báo "Lược đồ thiếu trường khóa phân vùng '{trường}' hoặc trường này không phải chuỗi, số, hoặc cho phép null."

  @US-10-018 @FR-10-018 @M
  Kịch bản: US-10-018 dương · Kiểm tra tương thích với các phiên bản đã có
    Biết topic đã có ít nhất một phiên bản `ENABLED`
    Khi người dùng bấm "Kiểm tra tương thích" ở UI-10-08; FR-10-019 chạy lại khi gửi duyệt
    Thì hệ thống trả `200`, `compatibilityReport`

  @US-10-018 @FR-10-018 @M @âm
  Kịch bản: US-10-018 âm 1 · Không tương thích khi gửi duyệt
    Biết topic đã có ít nhất một phiên bản `ENABLED`
    Khi không tương thích khi gửi duyệt
    Thì hệ thống từ chối với ERR-10-016 (409)
    Và người dùng thấy thông báo "Lược đồ không tương thích theo mức {mức}."

  @US-10-018 @FR-10-018 @M @âm
  Kịch bản: US-10-018 âm 2 · Apicurio không khả dụng
    Biết topic đã có ít nhất một phiên bản `ENABLED`
    Khi Apicurio không khả dụng
    Thì hệ thống từ chối với ERR-10-029 (503)
    Và người dùng thấy thông báo "Dịch vụ Apicurio tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  @US-10-019 @FR-10-019 @M
  Kịch bản: US-10-019 dương · Gửi duyệt và duyệt phiên bản lược đồ
    Biết phiên bản `DRAFT` đạt FR-10-017 và FR-10-018 trong 24 giờ trên đúng nội dung (băm)
    Khi người soạn bấm "Gửi duyệt" ở UI-10-08; người duyệt quyết định ở UI-10-13
    Thì hệ thống trả `200`, phiên bản với trạng thái mới, `apicurioGlobalId`
    Và bên nhận cũ tiếp tục đọc được theo mức tương thích
    Và sự kiện được phát: EVT-10-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-019 @FR-10-019 @M @âm
  Kịch bản: US-10-019 âm 1 · Bốn mắt
    Biết phiên bản `DRAFT` đạt FR-10-017 và FR-10-018 trong 24 giờ trên đúng nội dung (băm)
    Khi bốn mắt
    Thì hệ thống từ chối với ERR-10-008 (403)
    Và người dùng thấy thông báo "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

  @US-10-019 @FR-10-019 @M @âm
  Kịch bản: US-10-019 âm 2 · Không tương thích
    Biết phiên bản `DRAFT` đạt FR-10-017 và FR-10-018 trong 24 giờ trên đúng nội dung (băm)
    Khi không tương thích
    Thì hệ thống từ chối với ERR-10-016 (409)
    Và người dùng thấy thông báo "Lược đồ không tương thích theo mức {mức}."

  @US-10-020 @FR-10-020 @M
  Kịch bản: US-10-020 dương · Xem lịch sử phiên bản, so sánh và tải lược đồ
    Biết topic có lược đồ
    Khi người dùng mở tab Lược đồ ở UI-10-06 hoặc màn UI-10-08, chọn hai phiên bản để so sánh, bấm "Tải"
    Thì hệ thống trả `200`, danh sách phiên bản, nội dung, khác biệt (`SchemaDiffChange`, A.2.15)

  @US-10-020 @FR-10-020 @M @âm
  Kịch bản: US-10-020 âm 1 · Không tìm thấy phiên bản
    Biết topic có lược đồ
    Khi không tìm thấy phiên bản
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản lược đồ {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-10-021 @FR-10-021 @M
  Kịch bản: US-10-021 dương · Đặt mức tương thích của lược đồ
    Biết topic không `RETIRED`
    Khi người dùng chọn mức mới ở UI-10-08 và gửi đề nghị
    Thì hệ thống trả `202`, yêu cầu duyệt; sau khi duyệt, lược đồ với `compatibility` mới
    Và mọi phiên bản sau kiểm tra theo mức mới
    Và sự kiện được phát: EVT-10-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-021 @FR-10-021 @M @âm
  Kịch bản: US-10-021 âm 1 · `NONE` trên topic đã hoạt động
    Biết topic không `RETIRED`
    Khi `NONE` trên topic đã hoạt động
    Thì hệ thống từ chối với ERR-10-019 (422)
    Và người dùng thấy thông báo "Mức 'Không kiểm tra' chỉ dùng cho topic chưa từng hoạt động."

  @US-10-021 @FR-10-021 @M @âm
  Kịch bản: US-10-021 âm 2 · Phiên bản hiện có không thỏa mức mới
    Biết topic không `RETIRED`
    Khi phiên bản hiện có không thỏa mức mới
    Thì hệ thống từ chối với ERR-10-016 (409)
    Và người dùng thấy thông báo "Lược đồ không tương thích theo mức {mức}."

  @US-10-022 @FR-10-022 @S
  Kịch bản: US-10-022 dương · Ngừng khuyến nghị và vô hiệu phiên bản lược đồ
    Biết phiên bản `ENABLED` không phải mới nhất (ngừng khuyến nghị); phiên bản `DEPRECATED` (vô hiệu)
    Khi người dùng bấm "Ngừng khuyến nghị" hoặc "Vô hiệu" trên một phiên bản ở UI-10-08
    Thì hệ thống trả `200` (ngừng khuyến nghị) hoặc `202` (yêu cầu vô hiệu)
    Và `DISABLED` không giải mã được nữa và không quay lại `ENABLED`
    Và sự kiện được phát: EVT-10-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-022 @FR-10-022 @S @âm
  Kịch bản: US-10-022 âm 1 · Vô hiệu phiên bản mới nhất hoặc còn bản tin trong lưu giữ
    Biết phiên bản `ENABLED` không phải mới nhất (ngừng khuyến nghị); phiên bản `DEPRECATED` (vô hiệu)
    Khi vô hiệu phiên bản mới nhất hoặc còn bản tin trong lưu giữ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi phiên bản lược đồ đang ở trạng thái {nhãn trạng thái}."

  @US-10-023 @FR-10-023 @S
  Kịch bản: US-10-023 dương · Giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp
    Biết topic có publication của bên phát qua listener `external` hoặc `internal`
    Khi chạy liên tục theo tỷ lệ lấy mẫu; người dùng mở tab tuân thủ ở UI-10-06
    Thì API-10-031: số vi phạm theo publication, loại vi phạm, mẫu `ce_id`
    Và sự kiện được phát: EVT-10-14

  @US-10-023 @FR-10-023 @S @âm
  Kịch bản: US-10-023 âm 1 · Bản tin không có định danh lược đồ hợp lệ
    Biết topic có publication của bên phát qua listener `external` hoặc `internal`
    Khi bản tin không có định danh lược đồ hợp lệ
    Thì hệ thống từ chối với ERR-10-119
    Và người dùng thấy thông báo "Bản tin không có định danh lược đồ."

  @US-10-024 @FR-10-024 @S
  Kịch bản: US-10-024 dương · Cung cấp tra cứu lược đồ cho bên ngoài
    Biết publication hoặc subscription `ACTIVE`
    Khi serde của HTTT gọi đường chỉ đọc; người dùng bấm "Tải lược đồ" hoặc xem mã mẫu ở tab Cách kết nối của UI-10-06
    Thì hệ thống trả `200`, nội dung lược đồ theo định dạng Apicurio

  @US-10-024 @FR-10-024 @S @âm
  Kịch bản: US-10-024 âm 1 · Thiếu scope
    Biết publication hoặc subscription `ACTIVE`
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-10-102 (403)
    Và người dùng thấy thông báo "Token chưa có quyền publish hoặc subscribe trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."

  # ---- EP-10-D · Bên phát và bên nhận

  @US-10-025 @FR-10-025 @M
  Kịch bản: US-10-025 dương · Liệt kê bên phát và bên nhận
    Biết đã chọn tenant làm việc
    Khi người dùng mở UI-10-09 (bên phát) hoặc UI-10-10 (bên nhận), đổi bộ lọc hoặc bấm một dòng
    Thì hệ thống trả `200`, danh sách hoặc chi tiết

  @US-10-025 @FR-10-025 @M @âm
  Kịch bản: US-10-025 âm 1 · Tham số sai
    Biết đã chọn tenant làm việc
    Khi tham số sai
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."

  @US-10-025 @FR-10-025 @M @âm
  Kịch bản: US-10-025 âm 2 · Chi tiết không tìm thấy
    Biết đã chọn tenant làm việc
    Khi chi tiết không tìm thấy
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy bên phát {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-10-026 @FR-10-026 @M
  Kịch bản: US-10-026 dương · Đăng ký bên phát
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi người dùng bấm "+ Đăng ký bên phát" ở UI-10-09, điền biểu mẫu và bấm "Lưu"
    Thì hệ thống trả `201`, bên phát
    Và bên phát `ACTIVE`, chưa có publication
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-026 @FR-10-026 @M @âm
  Kịch bản: US-10-026 âm 1 · Mã trùng
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi mã trùng
    Thì hệ thống từ chối với ERR-10-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."

  @US-10-026 @FR-10-026 @M @âm
  Kịch bản: US-10-026 âm 2 · HTTT không `ACTIVE`
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi HTTT không `ACTIVE`
    Thì hệ thống từ chối với ERR-10-021 (422)
    Và người dùng thấy thông báo "HTTT {mã} không tồn tại hoặc chưa ở trạng thái hoạt động ở PH-01."

  @US-10-027 @FR-10-027 @M
  Kịch bản: US-10-027 dương · Đăng ký bên nhận
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi người dùng bấm "+ Đăng ký bên nhận" ở UI-10-10; PH-04 tạo tự động bên `FLOW` khi luồng có điểm vào Kafka (FR-10-069)
    Thì hệ thống trả `201`, bên nhận
    Và bên nhận `ACTIVE`, chưa có subscription
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-027 @FR-10-027 @M @âm
  Kịch bản: US-10-027 âm 1 · Mã trùng
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi mã trùng
    Thì hệ thống từ chối với ERR-10-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."

  @US-10-027 @FR-10-027 @M @âm
  Kịch bản: US-10-027 âm 2 · HTTT, luồng, DU không hợp lệ
    Biết đối tượng gắn tồn tại và hợp lệ ở phân hệ nguồn
    Khi HTTT, luồng, DU không hợp lệ
    Thì hệ thống từ chối với ERR-10-021 (422)
    Và người dùng thấy thông báo "HTTT {mã} không tồn tại hoặc chưa ở trạng thái hoạt động ở PH-01."

  @US-10-028 @FR-10-028 @M
  Kịch bản: US-10-028 dương · Sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận
    Biết bên không `RETIRED`; tạm ngừng từ `ACTIVE`, tiếp tục từ `SUSPENDED`
    Khi người dùng bấm "Sửa", "Tạm ngừng", "Tiếp tục" hoặc "Ngừng dùng" ở UI-10-09, UI-10-10
    Thì hệ thống trả `200`, bên với trạng thái mới và danh sách quan hệ bị ảnh hưởng
    Và `SUSPENDED`: giữ khai báo, không có quyền
    Và sự kiện được phát: EVT-10-07, EVT-10-09 cho từng quan hệ bị ảnh hưởng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-028 @FR-10-028 @M @âm
  Kịch bản: US-10-028 âm 1 · Đổi trường bất biến
    Biết bên không `RETIRED`; tạm ngừng từ `ACTIVE`, tiếp tục từ `SUSPENDED`
    Khi đổi trường bất biến
    Thì hệ thống từ chối với ERR-10-003 (400)
    Và người dùng thấy thông báo "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."

  @US-10-028 @FR-10-028 @M @âm
  Kịch bản: US-10-028 âm 2 · Thiếu lý do
    Biết bên không `RETIRED`; tạm ngừng từ `ACTIVE`, tiếp tục từ `SUSPENDED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-029 @FR-10-029 @M
  Kịch bản: US-10-029 dương · Đồng bộ trạng thái với PH-01 và PH-04
    Biết bên tham gia gắn HTTT hoặc luồng
    Khi sự kiện đổi trạng thái HTTT của PH-01 (giả định `{tenant}.connect.system.state-changed.v1`, Q10-17); EVT-04-09 `{tenant}.integration.flow.retired.v1` của PH-04; lịch đối chiếu mỗi giờ
    Thì cán bộ thấy bên tham gia chuyển "Tạm ngừng" với lý do "Theo PH-01" ngay sau khi HTTT bị tạm ngừng
    Và trạng thái bên khớp phân hệ nguồn sau ≤ 60 giây hoặc sau chu kỳ đối chiếu
    Và sự kiện được phát: EVT-10-07, EVT-10-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-029 @FR-10-029 @M @âm
  Kịch bản: US-10-029 âm 1 · PH-01 hoặc PH-04 không khả dụng khi đối chiếu
    Biết bên tham gia gắn HTTT hoặc luồng
    Khi PH-01 hoặc PH-04 không khả dụng khi đối chiếu
    Thì hệ thống từ chối với ERR-10-029
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  # ---- EP-10-E · Publication và phát sự kiện

  @US-10-030 @FR-10-030 @M
  Kịch bản: US-10-030 dương · Đề nghị publication
    Biết bên phát `ACTIVE`; topic `ACTIVE`
    Khi người dùng bấm "Đề nghị phát lên topic" ở UI-10-09 hoặc tab Publication của UI-10-06
    Thì hệ thống trả `201`, publication và `approvalRequestCode`
    Và publication `PENDING_APPROVAL`, chưa có scope, ACL
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-030 @FR-10-030 @M @âm
  Kịch bản: US-10-030 âm 1 · Topic hoặc bên không nhận quan hệ mới
    Biết bên phát `ACTIVE`; topic `ACTIVE`
    Khi topic hoặc bên không nhận quan hệ mới
    Thì hệ thống từ chối với ERR-10-025 (422)
    Và người dùng thấy thông báo "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

  @US-10-030 @FR-10-030 @M @âm
  Kịch bản: US-10-030 âm 2 · Đã có publication cho cặp
    Biết bên phát `ACTIVE`; topic `ACTIVE`
    Khi đã có publication cho cặp
    Thì hệ thống từ chối với ERR-10-024 (409)
    Và người dùng thấy thông báo "Đã có quan hệ cho cặp này: {mô tả}."

  @US-10-031 @FR-10-031 @M
  Kịch bản: US-10-031 dương · Duyệt publication, cấp scope OAuth và ACL Kafka
    Biết publication `PENDING_APPROVAL`; topic `ACTIVE`; bên phát `ACTIVE`
    Khi người duyệt mở yêu cầu ở UI-10-13 và bấm "Duyệt" hoặc "Từ chối"
    Thì hệ thống trả `200`, publication `ACTIVE` với `grantedScope`, `aclRef`
    Và bên phát phát được trong ≤ 2 phút (NFR-10-008); token cũ không có scope phải lấy token mới (token máy 5 phút)
    Và sự kiện được phát: EVT-10-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-031 @FR-10-031 @M @âm
  Kịch bản: US-10-031 âm 1 · Bốn mắt
    Biết publication `PENDING_APPROVAL`; topic `ACTIVE`; bên phát `ACTIVE`
    Khi bốn mắt
    Thì hệ thống từ chối với ERR-10-008 (403)
    Và người dùng thấy thông báo "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

  @US-10-031 @FR-10-031 @M @âm
  Kịch bản: US-10-031 âm 2 · Topic, bên phát không còn hợp lệ
    Biết publication `PENDING_APPROVAL`; topic `ACTIVE`; bên phát `ACTIVE`
    Khi topic, bên phát không còn hợp lệ
    Thì hệ thống từ chối với ERR-10-025 (422)
    Và người dùng thấy thông báo "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

  @US-10-032 @FR-10-032 @M
  Kịch bản: US-10-032 dương · Tạm ngừng, tiếp tục và thu hồi publication
    Biết tạm ngừng, thu hồi: publication `ACTIVE` hoặc `SUSPENDED`; tiếp tục: `SUSPENDED`
    Khi người dùng bấm "Tạm ngừng", "Tiếp tục" hoặc "Thu hồi" ở UI-10-09 hoặc tab Publication của UI-10-06
    Thì hệ thống trả `200`, publication với trạng thái mới
    Và `SUSPENDED` giữ khai báo; `REVOKED` không tiếp tục được, muốn phát phải đề nghị mới
    Và sự kiện được phát: EVT-10-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-032 @FR-10-032 @M @âm
  Kịch bản: US-10-032 âm 1 · Thiếu lý do
    Biết tạm ngừng, thu hồi: publication `ACTIVE` hoặc `SUSPENDED`; tiếp tục: `SUSPENDED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-032 @FR-10-032 @M @âm
  Kịch bản: US-10-032 âm 2 · Trạng thái không hợp lệ
    Biết tạm ngừng, thu hồi: publication `ACTIVE` hoặc `SUSPENDED`; tiếp tục: `SUSPENDED`
    Khi trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi publication đang ở trạng thái {nhãn trạng thái}."

  @US-10-033 @FR-10-033 @M
  Kịch bản: US-10-033 dương · Phát sự kiện qua API phát
    Biết topic `ACTIVE` hoặc `DEPRECATED`; HTTT gọi qua APISIX (`apisix-ext` hoặc `apisix-int`)
    Khi HTTT gọi `POST /event/v1/topics/{topicName}/events` (API-10-079)
    Thì hệ thống trả `202 Accepted`: `results[]` gồm `id`, `partition`, `offset`, `schemaVersion`
    Và sự kiện ghi bền ở ít nhất hai bản sao
    Và sự kiện được phát: Chính sự kiện nghiệp vụ

  @US-10-033 @FR-10-033 @M @âm
  Kịch bản: US-10-033 âm 1 · Token không hợp lệ
    Biết topic `ACTIVE` hoặc `DEPRECATED`; HTTT gọi qua APISIX (`apisix-ext` hoặc `apisix-int`)
    Khi token không hợp lệ
    Thì hệ thống từ chối với ERR-10-101 (401)
    Và người dùng thấy thông báo "Token truy cập không hợp lệ hoặc đã hết hạn. Lấy token mới rồi gửi lại."

  @US-10-033 @FR-10-033 @M @âm
  Kịch bản: US-10-033 âm 2 · Thiếu scope, publication không `ACTIVE`
    Biết topic `ACTIVE` hoặc `DEPRECATED`; HTTT gọi qua APISIX (`apisix-ext` hoặc `apisix-int`)
    Khi thiếu scope, publication không `ACTIVE`
    Thì hệ thống từ chối với ERR-10-102 (403)
    Và người dùng thấy thông báo "Token chưa có quyền publish trên topic {tên}, hoặc publication không ở trạng thái hoạt động."

  @US-10-034 @FR-10-034 @M
  Kịch bản: US-10-034 dương · Phát sự kiện trực tiếp qua Kafka
    Biết ACL `WRITE` đã cấp (FR-10-031)
    Khi producer của bên phát ghi bản tin lên topic
    Thì xác nhận ghi của Kafka cho producer
    Và bản tin ghi bền ở ít nhất hai bản sao
    Và sự kiện được phát: Chính sự kiện nghiệp vụ

  @US-10-034 @FR-10-034 @M @âm
  Kịch bản: US-10-034 âm 1 · Kafka từ chối do ACL, hạn mức
    Biết ACL `WRITE` đã cấp (FR-10-031)
    Khi Kafka từ chối do ACL, hạn mức
    Thì hệ thống từ chối với ERR-10-120
    Và người dùng thấy thông báo "Kafka từ chối do ACL, hạn mức. Kiểm tra quyền và hạn mức của principal."

  @US-10-034 @FR-10-034 @M @âm
  Kịch bản: US-10-034 âm 2 · Bản tin không có định danh lược đồ
    Biết ACL `WRITE` đã cấp (FR-10-031)
    Khi bản tin không có định danh lược đồ
    Thì hệ thống từ chối với ERR-10-119
    Và người dùng thấy thông báo "Bản tin không có định danh lược đồ."

  # ---- EP-10-F · Subscription và giao nhận

  @US-10-035 @FR-10-035 @M
  Kịch bản: US-10-035 dương · Đề nghị subscription
    Biết bên nhận `ACTIVE`; topic `ACTIVE`; tenant chưa vượt `maxSubscriptions`
    Khi người dùng hoàn tất trình hướng dẫn UI-10-11 và bấm "Gửi duyệt"
    Thì hệ thống trả `201`, subscription và `approvalRequestCode`
    Và chưa có nhóm tiêu thụ, chưa nhận sự kiện
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-035 @FR-10-035 @M @âm
  Kịch bản: US-10-035 âm 1 · Đã có subscription cho cặp
    Biết bên nhận `ACTIVE`; topic `ACTIVE`; tenant chưa vượt `maxSubscriptions`
    Khi đã có subscription cho cặp
    Thì hệ thống từ chối với ERR-10-024 (409)
    Và người dùng thấy thông báo "Đã có quan hệ cho cặp này: {mô tả}."

  @US-10-035 @FR-10-035 @M @âm
  Kịch bản: US-10-035 âm 2 · Topic, bên nhận không nhận quan hệ mới
    Biết bên nhận `ACTIVE`; topic `ACTIVE`; tenant chưa vượt `maxSubscriptions`
    Khi topic, bên nhận không nhận quan hệ mới
    Thì hệ thống từ chối với ERR-10-025 (422)
    Và người dùng thấy thông báo "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

  @US-10-036 @FR-10-036 @M
  Kịch bản: US-10-036 dương · Xác minh endpoint webhook
    Biết subscription `PUSH`; `endpointUrl` hợp lệ theo BR-10-026
    Khi người dùng bấm "Xác minh" ở UI-10-11; hệ thống tự chạy khi đề nghị, sửa `endpointUrl`; TA bấm "Miễn xác minh"
    Thì hệ thống trả `200`, kết quả từng bước (`VerificationStep`, A.2.15)
    Và kết quả xác minh có hiệu lực 24 giờ cho việc duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-036 @FR-10-036 @M @âm
  Kịch bản: US-10-036 âm 1 · Xác minh thất bại
    Biết subscription `PUSH`; `endpointUrl` hợp lệ theo BR-10-026
    Khi xác minh thất bại
    Thì hệ thống từ chối với ERR-10-027 (422)
    Và người dùng thấy thông báo "Xác minh địa chỉ nhận chưa đạt hoặc đã quá 24 giờ."

  @US-10-036 @FR-10-036 @M @âm
  Kịch bản: US-10-036 âm 2 · `waiverUntil` quá 180 ngày
    Biết subscription `PUSH`; `endpointUrl` hợp lệ theo BR-10-026
    Khi `waiverUntil` quá 180 ngày
    Thì hệ thống từ chối với ERR-10-012 (422)
    Và người dùng thấy thông báo "Giá trị ngoài miền cho phép ({min} đến {max})."

  @US-10-037 @FR-10-037 @M
  Kịch bản: US-10-037 dương · Duyệt subscription và cấp phát nhóm tiêu thụ
    Biết subscription `PENDING_APPROVAL`; endpoint xác minh trong 24 giờ nếu `PUSH`
    Khi người duyệt bấm "Duyệt" hoặc "Từ chối" ở UI-10-13
    Thì hệ thống trả `200`, subscription `ACTIVE`
    Và sự kiện bắt đầu được giao trong ≤ 2 phút (NFR-10-008)
    Và sự kiện được phát: EVT-10-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-037 @FR-10-037 @M @âm
  Kịch bản: US-10-037 âm 1 · Bốn mắt
    Biết subscription `PENDING_APPROVAL`; endpoint xác minh trong 24 giờ nếu `PUSH`
    Khi bốn mắt
    Thì hệ thống từ chối với ERR-10-008 (403)
    Và người dùng thấy thông báo "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

  @US-10-037 @FR-10-037 @M @âm
  Kịch bản: US-10-037 âm 2 · Topic, bên nhận không hợp lệ
    Biết subscription `PENDING_APPROVAL`; endpoint xác minh trong 24 giờ nếu `PUSH`
    Khi topic, bên nhận không hợp lệ
    Thì hệ thống từ chối với ERR-10-025 (422)
    Và người dùng thấy thông báo "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

  @US-10-038 @FR-10-038 @M
  Kịch bản: US-10-038 dương · Giao nhận ĐẨY: webhook ký HMAC
    Biết subscription `PUSH` ở `ACTIVE`
    Khi có bản tin mới trên topic sau vị trí đã commit của nhóm tiêu thụ
    Thì lượt `POST` tới HTTT
    Và mỗi sự kiện được giao ít nhất một lần hoặc nằm trong DLQ
    Và sự kiện được phát: EVT-10-11 khi có mục DLQ mới

  @US-10-038 @FR-10-038 @M @âm
  Kịch bản: US-10-038 âm 1 · Quá thời gian
    Biết subscription `PUSH` ở `ACTIVE`
    Khi quá thời gian
    Thì hệ thống từ chối với ERR-10-111
    Và người dùng thấy thông báo "Quá thời gian chờ. Đầu nhận chậm; tăng thời gian chờ hoặc giảm số worker."

  @US-10-038 @FR-10-038 @M @âm
  Kịch bản: US-10-038 âm 2 · Đầu nhận lỗi tạm thời
    Biết subscription `PUSH` ở `ACTIVE`
    Khi đầu nhận lỗi tạm thời
    Thì hệ thống từ chối với ERR-10-112
    Và người dùng thấy thông báo "Đầu nhận lỗi tạm thời (5xx, 408, 425, 429). Kiểm tra tình trạng HTTT nhận."

  @US-10-039 @FR-10-039 @M
  Kịch bản: US-10-039 dương · Thử lại giãn dần và chính sách khi thất bại
    Biết lượt giao ĐẨY gặp lỗi tạm thời (FR-10-038 bước 6)
    Khi lỗi tạm thời của một lượt giao; tỷ lệ lỗi của subscription vượt ngưỡng
    Thì TO nhận cảnh báo "Đầu nhận lỗi" và thấy lý do tạm ngừng trên UI-10-12
    Và sự kiện được phát: EVT-10-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-039 @FR-10-039 @M @âm
  Kịch bản: US-10-039 âm 1 · Tiếp tục subscription đang `SUSPENDED` do hệ thống mà thiếu lý do
    Biết lượt giao ĐẨY gặp lỗi tạm thời (FR-10-038 bước 6)
    Khi tiếp tục subscription đang `SUSPENDED` do hệ thống mà thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-039 @FR-10-039 @M @âm
  Kịch bản: US-10-039 âm 2 · Lỗi đầu nhận từng lượt
    Biết lượt giao ĐẨY gặp lỗi tạm thời (FR-10-038 bước 6)
    Khi lỗi đầu nhận từng lượt
    Thì hệ thống từ chối với ERR-10-111
    Và người dùng thấy thông báo "Quá thời gian chờ. Đầu nhận chậm; tăng thời gian chờ hoặc giảm số worker."

  @US-10-040 @FR-10-040 @M
  Kịch bản: US-10-040 dương · Điểm bắt đầu và offset bắt đầu
    Biết nhóm tiêu thụ chưa từng được tạo
    Khi người dùng chọn ở bước Điểm bắt đầu của UI-10-11; hệ thống áp dụng ở FR-10-037 bước 4
    Thì vị trí khởi tạo theo phân vùng trên chi tiết subscription
    Và nhóm tiêu thụ có vị trí trước khi giao
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-040 @FR-10-040 @M @âm
  Kịch bản: US-10-040 âm 1 · `startAt` ngoài lưu giữ
    Biết nhóm tiêu thụ chưa từng được tạo
    Khi `startAt` ngoài lưu giữ
    Thì hệ thống từ chối với ERR-10-031 (422)
    Và người dùng thấy thông báo "Thời điểm bắt đầu phải trong khoảng lưu giữ của topic: từ {thời điểm sớm nhất}."

  @US-10-041 @FR-10-041 @M
  Kịch bản: US-10-041 dương · Tạm dừng, tiếp tục subscription
    Biết tạm dừng: `ACTIVE`
    Khi người dùng bấm "Tạm dừng" hoặc "Tiếp tục" ở UI-10-12
    Thì hệ thống trả `200`, subscription với trạng thái mới
    Và vị trí đọc giữ nguyên; sự kiện mới tích lũy trong lưu giữ
    Và sự kiện được phát: EVT-10-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-041 @FR-10-041 @M @âm
  Kịch bản: US-10-041 âm 1 · Subscription nội bộ
    Biết tạm dừng: `ACTIVE`
    Khi subscription nội bộ
    Thì hệ thống từ chối với ERR-10-052 (422)
    Và người dùng thấy thông báo "Thao tác không áp dụng cho đăng ký nhận nội bộ; điều khiển ở luồng PH-04."

  @US-10-041 @FR-10-041 @M @âm
  Kịch bản: US-10-041 âm 2 · Trạng thái không hợp lệ
    Biết tạm dừng: `ACTIVE`
    Khi trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi subscription đang ở trạng thái {nhãn trạng thái}."

  @US-10-042 @FR-10-042 @M
  Kịch bản: US-10-042 dương · Xoay khóa ký webhook
    Biết subscription `PUSH` chưa `REVOKED`
    Khi người dùng bấm "Xoay khóa" hoặc "Thu hồi khẩn" ở tab Khóa ký của UI-10-12; nhắc xoay khi khóa quá `10.push.key-max-age-days`
    Thì hệ thống trả `200`, `keyId` mới; bí mật chỉ ở API-10-120
    Và đúng một khóa `ACTIVE`, tối đa một `PREVIOUS`
    Và sự kiện được phát: EVT-10-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-042 @FR-10-042 @M @âm
  Kịch bản: US-10-042 âm 1 · OpenBao không khả dụng
    Biết subscription `PUSH` chưa `REVOKED`
    Khi OpenBao không khả dụng
    Thì hệ thống từ chối với ERR-10-029 (503)
    Và người dùng thấy thông báo "Dịch vụ OpenBao tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  @US-10-042 @FR-10-042 @M @âm
  Kịch bản: US-10-042 âm 2 · Subscription không phải `PUSH`
    Biết subscription `PUSH` chưa `REVOKED`
    Khi subscription không phải `PUSH`
    Thì hệ thống từ chối với ERR-10-052, ERR-10-006 (422)
    Và người dùng thấy thông báo "Thao tác không áp dụng cho đăng ký nhận nội bộ; điều khiển ở luồng PH-04."

  @US-10-043 @FR-10-043 @M
  Kịch bản: US-10-043 dương · Giao nhận KÉO qua API
    Biết subscription `PULL_API` ở `ACTIVE`
    Khi HTTT gọi API-10-080 (kéo), API-10-081 (ack), API-10-082 (nack)
    Thì hệ thống trả `200` lô sự kiện và cursor, `204` khi rỗng; ack, nack trả `204`
    Và vị trí đọc chỉ tiến khi có ack
    Và sự kiện được phát: EVT-10-11 khi nack đưa vào DLQ

  @US-10-043 @FR-10-043 @M @âm
  Kịch bản: US-10-043 âm 1 · ERR-10-101 (401)
    Biết subscription `PULL_API` ở `ACTIVE`
    Khi ERR-10-101 (401)
    Thì hệ thống từ chối với ERR-10-101

  @US-10-043 @FR-10-043 @M @âm
  Kịch bản: US-10-043 âm 2 · ERR-10-102 (403)
    Biết subscription `PULL_API` ở `ACTIVE`
    Khi ERR-10-102 (403)
    Thì hệ thống từ chối với ERR-10-102

  @US-10-044 @FR-10-044 @S
  Kịch bản: US-10-044 dương · Giao nhận KÉO qua Kafka listener ngoài
    Biết tenant bật `10.external-kafka.enabled` (PA bật theo đề nghị của TA, vì cần mở cổng 9093 qua mạng TSLCD, D03-09 §3.3); subscription `PULL_KAFKA` `ACTIVE`
    Khi consumer của HTTT kết nối listener `external`
    Thì bản tin Kafka cho consumer
    Và vị trí đọc do bên nhận commit
    Và sự kiện được phát: EVT-10-11 khi bên nhận ghi DLQ qua API-10-083

  @US-10-044 @FR-10-044 @S @âm
  Kịch bản: US-10-044 âm 1 · ACL hoặc hạn mức từ chối
    Biết tenant bật `10.external-kafka.enabled` (PA bật theo đề nghị của TA, vì cần mở cổng 9093 qua mạng TSLCD, D03-09 §3.3); subscription `PULL_KAFKA` `ACTIVE`
    Khi ACL hoặc hạn mức từ chối
    Thì hệ thống từ chối với ERR-10-120
    Và người dùng thấy thông báo "Kafka từ chối do ACL, hạn mức. Kiểm tra quyền và hạn mức của principal."

  @US-10-045 @FR-10-045 @M
  Kịch bản: US-10-045 dương · Giao nhận nội bộ cho luồng và DU
    Biết subscription `INTERNAL` `ACTIVE`
    Khi luồng hoặc DU khởi động consumer
    Thì cán bộ thấy luồng, DU trên sơ đồ và bảng lag như mọi bên nhận

  @US-10-045 @FR-10-045 @M @âm
  Kịch bản: US-10-045 âm 1 · Tạm dừng, tiếp tục từ PH-10
    Biết subscription `INTERNAL` `ACTIVE`
    Khi tạm dừng, tiếp tục từ PH-10
    Thì hệ thống từ chối với ERR-10-052 (422)
    Và người dùng thấy thông báo "Thao tác không áp dụng cho đăng ký nhận nội bộ; điều khiển ở luồng PH-04."

  @US-10-046 @FR-10-046 @M
  Kịch bản: US-10-046 dương · Sửa tham số subscription
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED`
    Khi người dùng bấm "Sửa" ở UI-10-12 và lưu
    Thì hệ thống trả `200` (áp dụng ngay) hoặc `202` (chờ duyệt)
    Và sự kiện được phát: EVT-10-09 khi thay đổi có hiệu lực
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-046 @FR-10-046 @M @âm
  Kịch bản: US-10-046 âm 1 · Số worker vượt
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED`
    Khi số worker vượt
    Thì hệ thống từ chối với ERR-10-030 (422)
    Và người dùng thấy thông báo "Số worker tối đa {n} (bằng số phân vùng của topic hoặc trần của tenant)."

  @US-10-046 @FR-10-046 @M @âm
  Kịch bản: US-10-046 âm 2 · URL không hợp lệ
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED`
    Khi URL không hợp lệ
    Thì hệ thống từ chối với ERR-10-026 (422)
    Và người dùng thấy thông báo "Địa chỉ nhận không hợp lệ: chỉ nhận HTTPS, tên miền trong danh sách egress, không trỏ địa chỉ nội bộ."

  @US-10-047 @FR-10-047 @M
  Kịch bản: US-10-047 dương · Thu hồi subscription
    Biết subscription chưa `REVOKED`
    Khi người dùng bấm "Thu hồi" ở UI-10-12; FR-10-014, 028, 029 gọi khi dọn
    Thì hệ thống trả `200`, subscription `REVOKED`
    Và sự kiện được phát: EVT-10-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-047 @FR-10-047 @M @âm
  Kịch bản: US-10-047 âm 1 · Thiếu lý do
    Biết subscription chưa `REVOKED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-047 @FR-10-047 @M @âm
  Kịch bản: US-10-047 âm 2 · Đã thu hồi, hoặc phát lại mục DLQ của subscription đã thu hồi
    Biết subscription chưa `REVOKED`
    Khi đã thu hồi, hoặc phát lại mục DLQ của subscription đã thu hồi
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi subscription đang ở trạng thái Đã thu hồi."

  @US-10-048 @FR-10-048 @C
  Kịch bản: US-10-048 dương · Lọc sự kiện và gộp lô khi đẩy
    Biết subscription `PUSH` hoặc `PULL_API`
    Khi người dùng khai bộ lọc, gộp lô khi đề nghị hoặc sửa subscription
    Thì hệ thống trả `200`, subscription với bộ lọc, gộp lô
    Và như FR-10-046
    Và sự kiện được phát: EVT-10-09

  @US-10-048 @FR-10-048 @C @âm
  Kịch bản: US-10-048 âm 1 · Tham số ngoài miền
    Biết subscription `PUSH` hoặc `PULL_API`
    Khi tham số ngoài miền
    Thì hệ thống từ chối với ERR-10-012 (422)
    Và người dùng thấy thông báo "Giá trị ngoài miền cho phép ({min} đến {max})."

  # ---- EP-10-G · DLQ tầng sự kiện và phát lại

  @US-10-049 @FR-10-049 @M
  Kịch bản: US-10-049 dương · Chuyển sự kiện giao thất bại vào DLQ tầng sự kiện
    Biết sự kiện hết lượt thử, lỗi vĩnh viễn, không giải tuần tự được, hoặc bị nack
    Khi FR-10-038, 039, 043 kết luận lượt giao thất bại; bên nhận gọi API-10-083
    Thì mục DLQ `NEW`
    Và sự kiện được phát: EVT-10-11

  @US-10-049 @FR-10-049 @M @âm
  Kịch bản: US-10-049 âm 1 · Topic DLQ không ghi được
    Biết sự kiện hết lượt thử, lỗi vĩnh viễn, không giải tuần tự được, hoặc bị nack
    Khi topic DLQ không ghi được
    Thì hệ thống từ chối với ERR-10-029
    Và người dùng thấy thông báo "Dịch vụ Kafka tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  @US-10-050 @FR-10-050 @M
  Kịch bản: US-10-050 dương · Tra cứu, xem và loại bỏ mục DLQ
    Biết có mục DLQ
    Khi người dùng mở UI-10-15, lọc, mở một mục, bấm "Xem nội dung" hoặc "Loại bỏ"
    Thì hệ thống trả `200`, danh sách, siêu dữ liệu, nội dung; loại bỏ trả số mục đã xử lý
    Và mục loại bỏ ở `DISCARDED`, nội dung xóa sau `10.dlq.payload-retention-days-after-resolve`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-050 @FR-10-050 @M @âm
  Kịch bản: US-10-050 âm 1 · Mục đã xử lý
    Biết có mục DLQ
    Khi mục đã xử lý
    Thì hệ thống từ chối với ERR-10-036 (409)
    Và người dùng thấy thông báo "Mục DLQ đã được xử lý bởi {người} lúc {giờ}."

  @US-10-050 @FR-10-050 @M @âm
  Kịch bản: US-10-050 âm 2 · Thiếu lý do
    Biết có mục DLQ
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-051 @FR-10-051 @M
  Kịch bản: US-10-051 dương · Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian
    Biết subscription `ACTIVE`, `PAUSED` hoặc `SUSPENDED`; không có lượt khác `APPROVED`, `RUNNING` cho subscription
    Khi người dùng bấm "Phát lại" ở UI-10-12 hoặc UI-10-16, điền khoảng và gửi
    Thì hệ thống trả `201`, lượt phát lại và yêu cầu duyệt
    Và chờ thực thi (FR-10-052)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-051 @FR-10-051 @M @âm
  Kịch bản: US-10-051 âm 1 · Chưa tạm dừng khi đặt lại offset
    Biết subscription `ACTIVE`, `PAUSED` hoặc `SUSPENDED`; không có lượt khác `APPROVED`, `RUNNING` cho subscription
    Khi chưa tạm dừng khi đặt lại offset
    Thì hệ thống từ chối với ERR-10-032 (409)
    Và người dùng thấy thông báo "Cần tạm dừng đăng ký nhận trước khi đặt lại vị trí đọc."

  @US-10-051 @FR-10-051 @M @âm
  Kịch bản: US-10-051 âm 2 · Ngoài lưu giữ
    Biết subscription `ACTIVE`, `PAUSED` hoặc `SUSPENDED`; không có lượt khác `APPROVED`, `RUNNING` cho subscription
    Khi ngoài lưu giữ
    Thì hệ thống từ chối với ERR-10-033 (422)
    Và người dùng thấy thông báo "Khoảng phát lại ngoài dữ liệu còn giữ. Khoảng còn dữ liệu: {từ} đến {đến}."

  @US-10-052 @FR-10-052 @M
  Kịch bản: US-10-052 dương · Thực thi, theo dõi và hủy lượt phát lại
    Biết lượt `APPROVED`
    Khi bộ phát lại nhận việc (API-10-087); người dùng bấm "Hủy" ở UI-10-16
    Thì hệ thống trả `200`, lượt với tiến độ (API-10-063, 104)
    Và bên nhận đã nhận lại khoảng; lỗi cuối nằm trong DLQ
    Và sự kiện được phát: EVT-10-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-052 @FR-10-052 @M @âm
  Kịch bản: US-10-052 âm 1 · Subscription không còn `PAUSED` khi đặt lại
    Biết lượt `APPROVED`
    Khi subscription không còn `PAUSED` khi đặt lại
    Thì hệ thống từ chối với ERR-10-032 (409)
    Và người dùng thấy thông báo "Cần tạm dừng đăng ký nhận trước khi đặt lại vị trí đọc."

  @US-10-052 @FR-10-052 @M @âm
  Kịch bản: US-10-052 âm 2 · Hủy lượt đã kết thúc
    Biết lượt `APPROVED`
    Khi hủy lượt đã kết thúc
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi lượt phát lại đang ở trạng thái {nhãn trạng thái}."

  @US-10-053 @FR-10-053 @M
  Kịch bản: US-10-053 dương · Phát lại mục DLQ
    Biết mục `NEW` của subscription chưa `REVOKED`
    Khi người dùng chọn mục ở UI-10-15 và bấm "Phát lại"
    Thì hệ thống trả `201`, lượt phát lại
    Và mục `REPLAYED` hoặc `NEW`
    Và sự kiện được phát: EVT-10-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-053 @FR-10-053 @M @âm
  Kịch bản: US-10-053 âm 1 · Mục đã xử lý
    Biết mục `NEW` của subscription chưa `REVOKED`
    Khi mục đã xử lý
    Thì hệ thống từ chối với ERR-10-036 (409)
    Và người dùng thấy thông báo "Mục DLQ đã được xử lý bởi {người} lúc {giờ}."

  @US-10-053 @FR-10-053 @M @âm
  Kịch bản: US-10-053 âm 2 · Subscription đã thu hồi
    Biết mục `NEW` của subscription chưa `REVOKED`
    Khi subscription đã thu hồi
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi subscription đang ở trạng thái Đã thu hồi."

  # ---- EP-10-H · Giám sát, dashboard và sơ đồ

  @US-10-054 @FR-10-054 @M
  Kịch bản: US-10-054 dương · Thu thập consumer lag
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED` (gồm `dh-flow-*`, `dh-ext-*`)
    Khi lịch mỗi `10.lag.collect-interval-seconds`; người dùng mở tab Lag ở UI-10-12 hoặc UI-10-17
    Thì API-10-055: lag theo phân vùng và tổng
    Và có mẫu lag mới mỗi chu kỳ

  @US-10-054 @FR-10-054 @M @âm
  Kịch bản: US-10-054 âm 1 · Ngừng thu quá 3 chu kỳ
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED` (gồm `dh-flow-*`, `dh-ext-*`)
    Khi ngừng thu quá 3 chu kỳ
    Thì cảnh báo vận hành; giao diện hiện dải thông báo
    Và người dùng thấy thông báo "Số liệu độ trễ đã cũ {n} phút."

  @US-10-054 @FR-10-054 @M @âm
  Kịch bản: US-10-054 âm 2 · Kafka Admin không khả dụng
    Biết subscription `ACTIVE`, `PAUSED`, `SUSPENDED` (gồm `dh-flow-*`, `dh-ext-*`)
    Khi Kafka Admin không khả dụng
    Thì hệ thống từ chối với ERR-10-029
    Và người dùng thấy thông báo "Dịch vụ Kafka Admin tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  @US-10-055 @FR-10-055 @M
  Kịch bản: US-10-055 dương · Cảnh báo lag và nhóm tiêu thụ ngừng tiến
    Biết có mẫu lag (FR-10-054)
    Khi mỗi chu kỳ thu lag; TO bấm "Xác nhận cảnh báo" ở UI-10-17
    Thì API-10-056 trả `200`
    Và `alertState` phản ánh mẫu mới nhất
    Và sự kiện được phát: EVT-10-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-055 @FR-10-055 @M @âm
  Kịch bản: US-10-055 âm 1 · Xác nhận khi `alertState = OK`
    Biết có mẫu lag (FR-10-054)
    Khi xác nhận khi `alertState = OK`
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi subscription đang ở trạng thái Bình thường."

  @US-10-056 @FR-10-056 @M
  Kịch bản: US-10-056 dương · Thống kê giao nhận và lượt giao gần đây
    Biết subscription đã có lượt giao
    Khi người dùng mở tab Thống kê, Lượt lỗi, Worker ở UI-10-12
    Thì hệ thống trả `200`, thống kê và lượt lỗi

  @US-10-056 @FR-10-056 @M @âm
  Kịch bản: US-10-056 âm 1 · Cửa sổ sai
    Biết subscription đã có lượt giao
    Khi cửa sổ sai
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."

  @US-10-057 @FR-10-057 @M
  Kịch bản: US-10-057 dương · Dashboard sự kiện
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi người dùng mở UI-10-01; tự làm mới 30 giây
    Thì hệ thống trả `200`, các khối số liệu

  @US-10-057 @FR-10-057 @M @âm
  Kịch bản: US-10-057 âm 1 · Dự án không tồn tại
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi dự án không tồn tại
    Thì hệ thống từ chối với ERR-10-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy dự án {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-10-058 @FR-10-058 @M
  Kịch bản: US-10-058 dương · Sơ đồ kết nối tương tác
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi người dùng mở UI-10-14 hoặc tab Sơ đồ ở UI-10-03
    Thì hệ thống trả `200`: `nodes[]` (`id`, `kind`, `code`, `label`, `status`, chỉ số), `edges[]` (`from`, `to`, `kind`, `code`, `status`, `deliveryMode`, `lagSeconds`, `ratePerMinute`)

  @US-10-058 @FR-10-058 @M @âm
  Kịch bản: US-10-058 âm 1 · Quá số nút
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi quá số nút
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Sơ đồ có hơn {n} nút. Chọn một dự án, một topic hoặc một HTTT để thu hẹp."

  @US-10-059 @FR-10-059 @M
  Kịch bản: US-10-059 dương · Xuất số liệu sang PH-13
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi liên tục theo chu kỳ của OpenTelemetry
    Thì chuỗi chỉ số ở PH-13

  @US-10-059 @FR-10-059 @M @âm
  Kịch bản: US-10-059 âm 1 · PH-13 không nhận
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi PH-13 không nhận
    Thì bộ xuất giữ đệm và thử lại; người vận hành thấy dải thông báo trên UI-10-01
    Và người dùng thấy thông báo "Chưa lấy được số liệu lưu lượng từ PH-13."

  # ---- EP-10-I · Danh mục cấu hình, hạn mức, đa tenant, kiểm toán

  @US-10-060 @FR-10-060 @M
  Kịch bản: US-10-060 dương · Danh mục kiểu giao tiếp
    Biết danh mục nền tảng đã nạp
    Khi TA gạt công tắc ở tab Danh mục của UI-10-18
    Thì hệ thống trả `200`, mục đã cập nhật
    Và đối tượng đã có không đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-060 @FR-10-060 @M @âm
  Kịch bản: US-10-060 âm 1 · Mục đang dùng
    Biết danh mục nền tảng đã nạp
    Khi mục đang dùng
    Thì hệ thống từ chối với ERR-10-043 (422)
    Và người dùng thấy thông báo "Không tắt được mục đang có {n} bên tham gia hoặc topic dùng."

  @US-10-060 @FR-10-060 @M @âm
  Kịch bản: US-10-060 âm 2 · Thiếu quyền
    Biết danh mục nền tảng đã nạp
    Khi thiếu quyền
    Thì hệ thống từ chối với ERR-10-054 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant."

  @US-10-061 @FR-10-061 @M
  Kịch bản: US-10-061 dương · Danh mục chế độ định tuyến
    Biết danh mục nền tảng đã nạp
    Khi TA gạt công tắc ở UI-10-18
    Thì hệ thống trả `200`
    Và `KEY_HASH` luôn bật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-061 @FR-10-061 @M @âm
  Kịch bản: US-10-061 âm 1 · Chế độ đang dùng hoặc là `KEY_HASH`
    Biết danh mục nền tảng đã nạp
    Khi chế độ đang dùng hoặc là `KEY_HASH`
    Thì hệ thống từ chối với ERR-10-043 (422)
    Và người dùng thấy thông báo "Không tắt được mục đang có {n} bên tham gia hoặc topic dùng."

  @US-10-062 @FR-10-062 @M
  Kịch bản: US-10-062 dương · Hạn mức theo tenant và phân bổ cho bên tham gia
    Biết tenant `ACTIVE`
    Khi PA sửa trần ở UI-10-18 tab Hạn mức; mỗi thao tác tạo, duyệt ở control plane
    Thì hệ thống trả `200`, hạn mức và mức dùng
    Và tổng hạn mức principal ≤ trần tenant
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-062 @FR-10-062 @M @âm
  Kịch bản: US-10-062 âm 1 · Vượt hạn mức
    Biết tenant `ACTIVE`
    Khi vượt hạn mức
    Thì hệ thống từ chối với ERR-10-011 (422)
    Và người dùng thấy thông báo "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."

  @US-10-062 @FR-10-062 @M @âm
  Kịch bản: US-10-062 âm 2 · Trần ngoài miền
    Biết tenant `ACTIVE`
    Khi trần ngoài miền
    Thì hệ thống từ chối với ERR-10-012 (422)
    Và người dùng thấy thông báo "Giá trị ngoài miền cho phép ({min} đến {max})."

  @US-10-063 @FR-10-063 @M
  Kịch bản: US-10-063 dương · Tham số phân hệ theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi TA sửa ở tab Tham số của UI-10-18
    Thì hệ thống trả `200`
    Và đối tượng cũ giữ cấu hình trừ tham số "áp dụng ngay"
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-063 @FR-10-063 @M @âm
  Kịch bản: US-10-063 âm 1 · Ngoài miền
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ngoài miền
    Thì hệ thống từ chối với ERR-10-012 (422)
    Và người dùng thấy thông báo "Giá trị ngoài miền cho phép ({min} đến {max})."

  @US-10-063 @FR-10-063 @M @âm
  Kịch bản: US-10-063 âm 2 · Thiếu lý do
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-10-009 (400)
    Và người dùng thấy thông báo "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

  @US-10-064 @FR-10-064 @M
  Kịch bản: US-10-064 dương · Cách ly đa tenant trên trục sự kiện
    Biết tenant đã có mã
    Khi mọi thao tác tạo, cấp phát; lịch chạy bộ kiểm thử rò rỉ; PH-20 khởi tạo tenant
    Thì tenant chỉ thấy tài nguyên của mình
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-064 @FR-10-064 @M @âm
  Kịch bản: US-10-064 âm 1 · Tiền tố sai
    Biết tenant đã có mã
    Khi tiền tố sai
    Thì hệ thống từ chối với ERR-10-005 (422)
    Và người dùng thấy thông báo "Tiền tố tenant của topic không khớp tenant đang làm việc."

  @US-10-064 @FR-10-064 @M @âm
  Kịch bản: US-10-064 âm 2 · Kiểm thử rò rỉ không bị từ chối
    Biết tenant đã có mã
    Khi kiểm thử rò rỉ không bị từ chối
    Thì hệ thống báo sự cố an ninh SEV-1 ở PH-13, không hiện cho người dùng tenant

  @US-10-065 @FR-10-065 @M
  Kịch bản: US-10-065 dương · Kiểm toán và lịch sử thay đổi
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi mọi thao tác ghi ở FR-10-003…053, 060…075
    Thì bản ghi kiểm toán ở PH-13
    Và nhật ký phát lại giữ 3 năm (kế thừa SRS repo §4.3)

  @US-10-065 @FR-10-065 @M @âm
  Kịch bản: US-10-065 âm 1 · PH-13 không nhận
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi PH-13 không nhận
    Thì outbox giữ và gửi lại, thao tác gốc không bị chặn

  # ---- EP-10-J · Đăng ký máy với máy

  @US-10-066 @FR-10-066 @M
  Kịch bản: US-10-066 dương · Đăng ký topic hộ PH-05 cho CDC
    Biết cấu hình CDC đã lưu ở PH-05
    Khi PH-05 gọi `POST /api/event/v1/topics` với `topicKind = CDC`
    Thì hệ thống trả `202` (mới) hoặc `200` (đã có), thân là topic
    Và topic `ACTIVE` sau cấp phát; subscription của luồng, HTTT tới topic này đi theo quy trình bình thường (có duyệt)
    Và sự kiện được phát: EVT-10-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-066 @FR-10-066 @M @âm
  Kịch bản: US-10-066 âm 1 · Tên sai, miền sai
    Biết cấu hình CDC đã lưu ở PH-05
    Khi tên sai, miền sai
    Thì hệ thống từ chối với ERR-10-004 (422)
    Và người dùng thấy thông báo "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."

  @US-10-066 @FR-10-066 @M @âm
  Kịch bản: US-10-066 âm 2 · Tiền tố sai
    Biết cấu hình CDC đã lưu ở PH-05
    Khi tiền tố sai
    Thì hệ thống từ chối với ERR-10-005 (422)
    Và người dùng thấy thông báo "Tiền tố tenant của topic không khớp tenant đang làm việc."

  @US-10-067 @FR-10-067 @M
  Kịch bản: US-10-067 dương · Đăng ký topic cho DU nội bộ và topic nền tảng
    Biết tenant đã khởi tạo (FR-10-064) hoặc DU mới được triển khai
    Khi bộ khai báo topic đi cùng gói triển khai gọi API-10-009 (idempotent)
    Thì hệ thống trả `202` hoặc `200`
    Và người dùng vẫn đề nghị subscription cho HTTT, luồng tới topic này như topic thường
    Và sự kiện được phát: EVT-10-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-067 @FR-10-067 @M @âm
  Kịch bản: US-10-067 âm 1 · Người dùng đăng ký miền dành riêng
    Biết tenant đã khởi tạo (FR-10-064) hoặc DU mới được triển khai
    Khi người dùng đăng ký miền dành riêng
    Thì hệ thống từ chối với ERR-10-004 (422)
    Và người dùng thấy thông báo "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."

  @US-10-067 @FR-10-067 @M @âm
  Kịch bản: US-10-067 âm 2 · Người dùng sửa cấu hình topic `SYSTEM`, `CDC` ngoài mô tả
    Biết tenant đã khởi tạo (FR-10-064) hoặc DU mới được triển khai
    Khi người dùng sửa cấu hình topic `SYSTEM`, `CDC` ngoài mô tả
    Thì hệ thống từ chối với ERR-10-045 (422)
    Và người dùng thấy thông báo "Topic CDC, hệ thống chỉ do dịch vụ chủ quản ({dịch vụ}) sửa."

  @US-10-068 @FR-10-068 @M
  Kịch bản: US-10-068 dương · Xử lý thông báo thay đổi lược đồ CDC
    Biết topic CDC `ACTIVE` (FR-10-066)
    Khi sự kiện trên `{tenant}.adapter.cdc.schema-changed.v1`
    Thì phiên bản lược đồ hoặc topic mới
    Và topic cũ `DEPRECATED` khi có `.v{n+1}`
    Và sự kiện được phát: EVT-10-05, EVT-10-02 (phiên bản lược đồ mới); EVT-10-03 (topic cũ `DEPRECATED`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-068 @FR-10-068 @M @âm
  Kịch bản: US-10-068 âm 1 · Không tương thích
    Biết topic CDC `ACTIVE` (FR-10-066)
    Khi không tương thích
    Thì hệ thống từ chối với ERR-10-016 (409)
    Và người dùng thấy thông báo "Lược đồ không tương thích theo mức {mức}."

  @US-10-069 @FR-10-069 @M
  Kịch bản: US-10-069 dương · Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi PH-04 kiểm luồng, mở bảng chọn topic hoặc kỹ sư chọn topic trong trình thiết kế
    Thì kết quả kiểm từng bộ; danh sách topic
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-069 @FR-10-069 @M @âm
  Kịch bản: US-10-069 âm 1 · Không kiểm được
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi không kiểm được
    Thì hệ thống từ chối với ERR-10-029 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

  # ---- EP-10-K · Xuất nhập khai báo và di trú từ Pulsar

  @US-10-070 @FR-10-070 @S
  Kịch bản: US-10-070 dương · Xuất khai báo
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi người dùng bấm "Xuất khai báo" ở UI-10-02
    Thì tệp `EventManifest`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-070 @FR-10-070 @S @âm
  Kịch bản: US-10-070 âm 1 · Phạm vi sai
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi phạm vi sai
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."

  @US-10-071 @FR-10-071 @C
  Kịch bản: US-10-071 dương · Nhập khai báo có xem trước
    Biết có tệp xuất từ FR-10-070
    Khi người dùng tải tệp ở UI-10-19
    Thì tác vụ nhập và bản xem trước
    Và mọi topic, publication, subscription vẫn qua duyệt bốn mắt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-071 @FR-10-071 @C @âm
  Kịch bản: US-10-071 âm 1 · Tệp sai
    Biết có tệp xuất từ FR-10-070
    Khi tệp sai
    Thì hệ thống từ chối với ERR-10-040 (422)
    Và người dùng thấy thông báo "Tệp sai cấu trúc hoặc phiên bản định dạng."

  @US-10-072 @FR-10-072 @M
  Kịch bản: US-10-072 dương · Nhập kiểm kê Pulsar và lập ánh xạ
    Biết có bản xuất CSDL cấu hình Hub cũ (bảng project, topic, publisher, subscriber, publication, subscription, `type_of_comm`, `routing_mode`) và danh sách topic Pulsar (`pulsar-admin topics list`, `stats`) theo mẫu tải về (FR-00-033)
    Khi TA tải tệp nén ở UI-10-20
    Thì tác vụ nhập, danh sách ánh xạ, báo cáo
    Và chưa có lưu lượng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-072 @FR-10-072 @M @âm
  Kịch bản: US-10-072 âm 1 · Tệp sai
    Biết có bản xuất CSDL cấu hình Hub cũ (bảng project, topic, publisher, subscriber, publication, subscription, `type_of_comm`, `routing_mode`) và danh sách topic Pulsar (`pulsar-admin topics list`, `stats`) theo mẫu tải về (FR-00-033)
    Khi tệp sai
    Thì hệ thống từ chối với ERR-10-040 (422)
    Và người dùng thấy thông báo "Tệp sai cấu trúc hoặc phiên bản định dạng."

  @US-10-072 @FR-10-072 @M @âm
  Kịch bản: US-10-072 âm 2 · Ánh xạ sai
    Biết có bản xuất CSDL cấu hình Hub cũ (bảng project, topic, publisher, subscriber, publication, subscription, `type_of_comm`, `routing_mode`) và danh sách topic Pulsar (`pulsar-admin topics list`, `stats`) theo mẫu tải về (FR-00-033)
    Khi ánh xạ sai
    Thì hệ thống từ chối với ERR-10-041 (422)
    Và người dùng thấy thông báo "Ánh xạ không hợp lệ: {lý do}."

  @US-10-073 @FR-10-073 @M
  Kịch bản: US-10-073 dương · Cầu nối Pulsar sang Kafka tạm thời
    Biết ánh xạ topic `PLANNED`; topic Kafka đích `ACTIVE`; kết nối nguồn Pulsar khai báo ở PH-05 (bí mật ở OpenBao)
    Khi TA bấm "Tạo cầu nối" ở UI-10-20
    Thì hệ thống trả `MigrationBridge` `RUNNING`, ánh xạ `BRIDGING`
    Và subscriber cũ vẫn nhận từ Pulsar
    Và sự kiện được phát: EVT-10-16; EVT-10-15 khi chuyển hẳn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-073 @FR-10-073 @M @âm
  Kịch bản: US-10-073 âm 1 · Ánh xạ sai
    Biết ánh xạ topic `PLANNED`; topic Kafka đích `ACTIVE`; kết nối nguồn Pulsar khai báo ở PH-05 (bí mật ở OpenBao)
    Khi ánh xạ sai
    Thì hệ thống từ chối với ERR-10-041 (422)
    Và người dùng thấy thông báo "Ánh xạ không hợp lệ: {lý do}."

  @US-10-073 @FR-10-073 @M @âm
  Kịch bản: US-10-073 âm 2 · Đã có cầu nối
    Biết ánh xạ topic `PLANNED`; topic Kafka đích `ACTIVE`; kết nối nguồn Pulsar khai báo ở PH-05 (bí mật ở OpenBao)
    Khi đã có cầu nối
    Thì hệ thống từ chối với ERR-10-042 (409)
    Và người dùng thấy thông báo "Đã có cầu nối cho topic này hoặc cầu nối ngược chiều đang chạy."

  @US-10-074 @FR-10-074 @S
  Kịch bản: US-10-074 dương · Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ chưa chuyển
    Biết bên phát của topic đã chuyển sang phát thẳng lên Datahub
    Khi TA tạo cầu nối chiều `KAFKA_TO_PULSAR` ở UI-10-20
    Thì hệ thống trả `MigrationBridge` chiều ngược `RUNNING`
    Và sự kiện được phát: EVT-10-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-074 @FR-10-074 @S @âm
  Kịch bản: US-10-074 âm 1 · Đã có cầu nối ngược chiều
    Biết bên phát của topic đã chuyển sang phát thẳng lên Datahub
    Khi đã có cầu nối ngược chiều
    Thì hệ thống từ chối với ERR-10-042 (409)
    Và người dùng thấy thông báo "Đã có cầu nối cho topic này hoặc cầu nối ngược chiều đang chạy."

  @US-10-075 @FR-10-075 @M
  Kịch bản: US-10-075 dương · Đối chiếu, chuyển hẳn và quay lui
    Biết ánh xạ `BRIDGING`
    Khi lịch mỗi giờ; TA bấm "Chuyển hẳn" hoặc "Quay lui" ở UI-10-20
    Thì báo cáo đối chiếu; ánh xạ `CUT_OVER`, `ROLLED_BACK` hoặc `CLOSED`
    Và sự kiện được phát: EVT-10-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-10-075 @FR-10-075 @M @âm
  Kịch bản: US-10-075 âm 1 · Chưa đủ điều kiện chuyển hẳn
    Biết ánh xạ `BRIDGING`
    Khi chưa đủ điều kiện chuyển hẳn
    Thì hệ thống từ chối với ERR-10-006 (409)
    Và người dùng thấy thông báo "Không thực hiện được khi ánh xạ đang ở trạng thái {nhãn trạng thái}."

  @US-10-075 @FR-10-075 @M @âm
  Kịch bản: US-10-075 âm 2 · Tự duyệt
    Biết ánh xạ `BRIDGING`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-10-008 (403)
    Và người dùng thấy thông báo "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

  @US-10-076 @FR-10-076 @S
  Kịch bản: US-10-076 dương · Báo cáo tiến độ di trú
    Biết có ánh xạ di trú
    Khi người dùng mở tab Tiến độ ở UI-10-20
    Thì bảng tiến độ, tệp Excel

  @US-10-076 @FR-10-076 @S @âm
  Kịch bản: US-10-076 âm 1 · Bộ lọc sai
    Biết có ánh xạ di trú
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-10-049 (400)
    Và người dùng thấy thông báo "Điều kiện truy vấn không hợp lệ."
