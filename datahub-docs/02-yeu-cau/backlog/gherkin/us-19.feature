# language: vi
# Sinh tự động từ D02-02/D02-03-PH19 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-19
Tính năng: PH-19 · Thanh toán điện tử

  # ---- EP-19-A · Nhà cung cấp thanh toán

  @US-19-001 @FR-19-001 @M
  Kịch bản: US-19-001 dương · Khai báo nhà cung cấp
    Biết phân hệ bật cho tenant; loại adapter đã được cài trên nền tảng (`ROLE-PLATFORM_ADMIN` cài, danh sách đọc từ cấu hình triển khai)
    Khi quản trị thanh toán bấm "Thêm nhà cung cấp" ở UI-19-03, điền biểu mẫu UI-19-05 rồi bấm "Lưu"
    Thì bản ghi NCC `DRAFT` với `id`, `connectionKey` (chỉ hiển thị dạng che `ab12…9f`, xem đầy đủ cần `credential-manage`), ETag; bảng ánh xạ mã kết quả mặc định của adapter (FR-19-069)
    Và `status = DRAFT`, `health_status = UNKNOWN`, `circuit_state = CLOSED`, `capabilities` lấy từ khai báo của adapter

  @US-19-001 @FR-19-001 @M @âm
  Kịch bản: US-19-001 âm 1 · Trường sai định dạng, thiếu trường bắt buộc
    Biết phân hệ bật cho tenant; loại adapter đã được cài trên nền tảng (`ROLE-PLATFORM_ADMIN` cài, danh sách đọc từ cấu hình triển khai)
    Khi trường sai định dạng, thiếu trường bắt buộc
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-001 @FR-19-001 @M @âm
  Kịch bản: US-19-001 âm 2 · Mã đã tồn tại
    Biết phân hệ bật cho tenant; loại adapter đã được cài trên nền tảng (`ROLE-PLATFORM_ADMIN` cài, danh sách đọc từ cấu hình triển khai)
    Khi mã đã tồn tại
    Thì hệ thống từ chối với ERR-19-038 (409)
    Và người dùng thấy thông báo "{code}"

  @US-19-002 @FR-19-002 @M
  Kịch bản: US-19-002 dương · Gắn thông tin xác thực nhà cung cấp
    Biết NCC ở `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; bí mật đã có tại đường dẫn OpenBao `kv/dh/{tenant}/payment/{providerCode}/{environment}/{purpose}`
    Khi người dùng mở tab "Thông tin xác thực" của UI-19-04, chọn môi trường, bấm "Gắn tham chiếu" và nhập đường dẫn OpenBao cho từng mục đích
    Thì danh sách tham chiếu theo môi trường và mục đích: `secretRef`, `fingerprint`, `validFrom`, `validTo`, `credentialStatus`, số ngày còn hạn; không bao giờ có giá trị bí mật
    Và với NCC `DRAFT`: bản ghi `ACTIVE` mới thay bản cũ (bản cũ `RETIRED`)

  @US-19-002 @FR-19-002 @M @âm
  Kịch bản: US-19-002 âm 1 · Đường dẫn sai tenant, sai định dạng
    Biết NCC ở `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; bí mật đã có tại đường dẫn OpenBao `kv/dh/{tenant}/payment/{providerCode}/{environment}/{purpose}`
    Khi đường dẫn sai tenant, sai định dạng
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-002 @FR-19-002 @M @âm
  Kịch bản: US-19-002 âm 2 · Bí mật không tồn tại, chứng thư hết hạn hoặc sắp hết hạn
    Biết NCC ở `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; bí mật đã có tại đường dẫn OpenBao `kv/dh/{tenant}/payment/{providerCode}/{environment}/{purpose}`
    Khi bí mật không tồn tại, chứng thư hết hạn hoặc sắp hết hạn
    Thì hệ thống từ chối với ERR-19-022 (422)
    Và người dùng thấy thông báo "Thông tin xác thực môi trường {environment} còn thiếu hoặc đã hết hạn: {items}."

  @US-19-003 @FR-19-003 @M
  Kịch bản: US-19-003 dương · Kiểm tra kết nối nhà cung cấp
    Biết NCC không ở `RETIRED`; có đủ tham chiếu bí mật bắt buộc của môi trường được chọn (FR-19-002)
    Khi người dùng bấm "Kiểm tra kết nối" ở bước 1 của trình hướng dẫn UI-19-06 hoặc ở UI-19-04; hệ thống tự gọi khi có `pending_change` và người dùng chọn "Kiểm tra ngay"
    Thì bản ghi `provider_check_run` loại `CONNECTION` với `steps[]`: `DNS`, `TLS_HANDSHAKE` (phiên bản, bộ mã, hạn chứng thư máy chủ), `MTLS` (nếu dùng), `AUTH` (xác thực API), `PING` (gọi API kiểm tra của adapter) …
    Và khi đạt và có `pending_change`: áp thay đổi kết nối (BR-19-026)

  @US-19-003 @FR-19-003 @M @âm
  Kịch bản: US-19-003 âm 1 · Thiếu hoặc hết hạn thông tin xác thực bắt buộc
    Biết NCC không ở `RETIRED`; có đủ tham chiếu bí mật bắt buộc của môi trường được chọn (FR-19-002)
    Khi thiếu hoặc hết hạn thông tin xác thực bắt buộc
    Thì hệ thống từ chối với ERR-19-022 (422)
    Và người dùng thấy thông báo "Thông tin xác thực môi trường {environment} còn thiếu hoặc đã hết hạn: {items}."

  @US-19-003 @FR-19-003 @M @âm
  Kịch bản: US-19-003 âm 2 · NCC `RETIRED`
    Biết NCC không ở `RETIRED`; có đủ tham chiếu bí mật bắt buộc của môi trường được chọn (FR-19-002)
    Khi NCC `RETIRED`
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-004 @FR-19-004 @M
  Kịch bản: US-19-004 dương · Thực hiện giao dịch thử
    Biết NCC `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; kiểm tra kết nối của cùng môi trường đạt trong 24 giờ gần nhất
    Khi người dùng bấm "Chạy giao dịch thử" ở bước 2 của trình hướng dẫn UI-19-06
    Thì hệ thống trả `provider_check_run` loại `TEST_TRANSACTION` gắn `test_transaction_id`; `paymentUrl` để người kiểm thử mở và thanh toán trên trang thử của NCC; các bước `INIT`, `PAYER_REDIRECT`, `IPN_RECEIVED`, `IPN_VERIFIED`, `QUERY_CONFIRMED`
    Và giao dịch có `is_test = true`, thuộc đối tác kỹ thuật ẩn `__TEST__` của tenant, không tính vào dashboard, báo cáo, hạn mức, đối soát chính thức (BR-19-033)
    Và sự kiện được phát: Sự kiện giao dịch được phát với cờ `isTest = true` để PH-16 lọc

  @US-19-004 @FR-19-004 @M @âm
  Kịch bản: US-19-004 âm 1 · Kiểm tra kết nối chưa đạt trong 24 giờ
    Biết NCC `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; kiểm tra kết nối của cùng môi trường đạt trong 24 giờ gần nhất
    Khi kiểm tra kết nối chưa đạt trong 24 giờ
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-004 @FR-19-004 @M @âm
  Kịch bản: US-19-004 âm 2 · Số tiền ngoài 1.000…100.000 đ
    Biết NCC `DRAFT`, `ACTIVE` hoặc `SUSPENDED`; kiểm tra kết nối của cùng môi trường đạt trong 24 giờ gần nhất
    Khi số tiền ngoài 1.000…100.000 đ
    Thì hệ thống từ chối với ERR-19-010 (422)
    Và người dùng thấy thông báo "Số tiền {amount} không hợp lệ. Số tiền phải là số nguyên dương, tính bằng đồng, không vượt trần cho phép."

  @US-19-005 @FR-19-005 @M
  Kịch bản: US-19-005 dương · Kích hoạt nhà cung cấp có phê duyệt
    Biết NCC `DRAFT`; checklist kích hoạt đạt (BR-19-010)
    Khi quản trị thanh toán bấm "Gửi đề nghị kích hoạt" ở bước 3 của UI-19-06; người phê duyệt mở đề nghị ở UI-19-13 và bấm "Duyệt", "Từ chối"; người lập có thể bấm "Rút"
    Thì hệ thống trả `approval_request` loại `PROVIDER_ACTIVATE` với `payload.checklist` (ảnh chụp bốn điều kiện kèm mã lần kiểm tra, thời điểm, kết quả)
    Và lập đề nghị: NCC `PENDING_ACTIVATION`, không sửa được địa chỉ, thông tin xác thực
    Và sự kiện được phát: EVT-19-01 khi NCC đổi trạng thái

  @US-19-005 @FR-19-005 @M @âm
  Kịch bản: US-19-005 âm 1 · Checklist không đạt khi lập hoặc khi duyệt
    Biết NCC `DRAFT`; checklist kích hoạt đạt (BR-19-010)
    Khi checklist không đạt khi lập hoặc khi duyệt
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-005 @FR-19-005 @M @âm
  Kịch bản: US-19-005 âm 2 · Người duyệt trùng người lập
    Biết NCC `DRAFT`; checklist kích hoạt đạt (BR-19-010)
    Khi người duyệt trùng người lập
    Thì hệ thống từ chối với ERR-19-033 (403)
    Và người dùng thấy thông báo "Bạn đã {role} đề nghị này nên không thể quyết định. Cần một người khác (tách nhiệm)."

  @US-19-006 @FR-19-006 @M
  Kịch bản: US-19-006 dương · Tạm dừng và mở lại nhà cung cấp
    Biết tạm dừng: NCC `ACTIVE`
    Khi người dùng bấm "Tạm dừng" hoặc "Mở lại" ở UI-19-04, chọn mã lý do và nhập lý do
    Thì NCC với trạng thái mới, ETag mới
    Và khi `SUSPENDED`: yêu cầu tạo giao dịch mới cho mọi dịch vụ của NCC bị từ chối với ERR-19-017 trước khi ghi CSDL; IPN, truy vấn chủ động, hủy, hoàn tiền đang dở và đối soát vẫn chạy; kiểm tra sức khỏe vẫn chạy
    Và sự kiện được phát: EVT-19-01; Khi `reasonCode = SECURITY` phát thêm sự kiện an ninh tới PH-13

  @US-19-006 @FR-19-006 @M @âm
  Kịch bản: US-19-006 âm 1 · Trạng thái không cho phép
    Biết tạm dừng: NCC `ACTIVE`
    Khi trạng thái không cho phép
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-006 @FR-19-006 @M @âm
  Kịch bản: US-19-006 âm 2 · Mở lại khi chưa kiểm tra kết nối trong 1 giờ
    Biết tạm dừng: NCC `ACTIVE`
    Khi mở lại khi chưa kiểm tra kết nối trong 1 giờ
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-007 @FR-19-007 @M
  Kịch bản: US-19-007 dương · Danh sách, tìm kiếm, sắp xếp nhà cung cấp
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở mục "Nhà cung cấp" trên menu Thanh toán (UI-19-03), gõ từ khóa hoặc chọn bộ lọc
    Thì hệ thống trả `items[]`: `id`, `code`, `name`, `adapterType`, `status`, `healthStatus`, `circuitState`, `effectiveFrom`, số dịch vụ `ACTIVE`, số giao dịch hôm nay, ngày hết hạn chứng thư sớm nhất, `hasPendingChange`, `allowedActions` …

  @US-19-007 @FR-19-007 @M @âm
  Kịch bản: US-19-007 âm 1 · Thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-008 @FR-19-008 @M
  Kịch bản: US-19-008 dương · Xem chi tiết nhà cung cấp
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng bấm vào tên một nhà cung cấp ở UI-19-03 hoặc mở đường dẫn trực tiếp tới UI-19-04
    Thì mọi trường của EN-19-01 (trừ `connectionKey` đầy đủ); `capabilities`; `pendingChange` (nếu có); sức khỏe gồm `healthStatus`, `healthCheckedAt`, `circuitState`, tỷ lệ lỗi và độ trễ p95 trong 15 phút; danh sách dịch vụ gắn NCC …

  @US-19-008 @FR-19-008 @M @âm
  Kịch bản: US-19-008 âm 1 · Tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác) …
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác); không phân biệt hai trường hợp để không lộ thông tin
    Thì hệ thống từ chối với ERR-19-020 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu, hoặc bạn không có quyền xem."

  @US-19-009 @FR-19-009 @M
  Kịch bản: US-19-009 dương · Chỉnh sửa nhà cung cấp
    Biết NCC không ở `PENDING_ACTIVATION`, `RETIRED`; `If-Match` khớp
    Khi người dùng bấm "Sửa" ở UI-19-04, sửa trường ở UI-19-05 rồi bấm "Lưu"
    Thì NCC sau sửa, ETag mới; khi có thay đổi kết nối của NCC `ACTIVE`, `SUSPENDED`: khối `pendingChange` và thông báo "Cần kiểm tra kết nối để áp dụng"
    Và NCC `DRAFT`: mọi trường đã áp

  @US-19-009 @FR-19-009 @M @âm
  Kịch bản: US-19-009 âm 1 · Sửa trường bất biến
    Biết NCC không ở `PENDING_ACTIVATION`, `RETIRED`; `If-Match` khớp
    Khi sửa trường bất biến
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-009 @FR-19-009 @M @âm
  Kịch bản: US-19-009 âm 2 · NCC `PENDING_ACTIVATION`, `RETIRED`
    Biết NCC không ở `PENDING_ACTIVATION`, `RETIRED`; `If-Match` khớp
    Khi NCC `PENDING_ACTIVATION`, `RETIRED`
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-010 @FR-19-010 @M
  Kịch bản: US-19-010 dương · Xóa hoặc ngừng hẳn nhà cung cấp
    Biết xóa: NCC `DRAFT`, không có giao dịch nào kể cả giao dịch thử
    Khi người dùng chọn "Xóa" (NCC bản nháp) hoặc "Đề nghị ngừng hẳn" (NCC đã dùng) ở UI-19-03, UI-19-04; người phê duyệt quyết định ở UI-19-13
    Thì xóa: `204`
    Và xóa: bản ghi NCC, tham chiếu bí mật, bảng ánh xạ, lần kiểm tra bị xóa (không có dữ liệu giao dịch phụ thuộc)
    Và sự kiện được phát: EVT-19-01 khi `RETIRED`; EVT-19-03 cho từng dịch vụ bị ngừng theo

  @US-19-010 @FR-19-010 @M @âm
  Kịch bản: US-19-010 âm 1 · Xóa NCC không ở `DRAFT`
    Biết xóa: NCC `DRAFT`, không có giao dịch nào kể cả giao dịch thử
    Khi xóa NCC không ở `DRAFT`
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-010 @FR-19-010 @M @âm
  Kịch bản: US-19-010 âm 2 · Xóa NCC đã có giao dịch
    Biết xóa: NCC `DRAFT`, không có giao dịch nào kể cả giao dịch thử
    Khi xóa NCC đã có giao dịch
    Thì hệ thống từ chối với ERR-19-037 (409)
    Và người dùng thấy thông báo "Không thể xóa vì đã có dữ liệu phụ thuộc ({dependents}). Dùng"

  @US-19-011 @FR-19-011 @M
  Kịch bản: US-19-011 dương · Giám sát sức khỏe và cảnh báo lỗi kết nối
    Biết NCC `ACTIVE` hoặc `SUSPENDED`
    Khi bộ lập lịch chạy thăm dò mỗi `19.provider.health-interval-seconds` (mặc định 60 giây); mỗi lời gọi thật tới NCC cập nhật cửa sổ thống kê 5 phút
    Thì hệ thống trả `health_status`, `health_checked_at`, `circuit_state` cập nhật; metric `payment_provider_health`, `payment_provider_call_duration`, `payment_provider_errors_total`; cảnh báo PH-13
    Và `health_status`, `health_checked_at`, `circuit_state` của NCC phản ánh lần đánh giá gần nhất; trạng thái mạch đồng bộ trên mọi bản sao qua Valkey
    Và sự kiện được phát: EVT-19-02 khi `health_status` hoặc `circuit_state` đổi

  @US-19-011 @FR-19-011 @M @âm
  Kịch bản: US-19-011 âm 1 · Không giữ được khóa lập lịch
    Biết NCC `ACTIVE` hoặc `SUSPENDED`
    Khi không giữ được khóa lập lịch
    Thì bản sao khác giữ khóa; thăm dò không trùng lặp

  @US-19-011 @FR-19-011 @M @âm
  Kịch bản: US-19-011 âm 2 · Valkey không sẵn sàng
    Biết NCC `ACTIVE` hoặc `SUSPENDED`
    Khi Valkey không sẵn sàng
    Thì mỗi bản sao tự tính mạch ngắt cục bộ; cảnh báo thông báo của PH-13
    Và người dùng thấy thông báo "Valkey ngừng"

  @US-19-012 @FR-19-012 @S
  Kịch bản: US-19-012 dương · Xoay khóa và chứng thư nhà cung cấp
    Biết NCC `ACTIVE` hoặc `SUSPENDED`; bản `ACTIVE` của mục đích cần xoay tồn tại; bí mật mới đã nạp vào OpenBao
    Khi cán bộ ATTT bấm "Xoay khóa" tại một dòng tham chiếu ở tab "Thông tin xác thực" của UI-19-04, thường sau khi nhận cảnh báo nhắc hạn
    Thì bản `NEXT` với `valid_from`, dấu vân tay; lịch chuyển tiếp
    Và trong thời gian chuyển tiếp: IPN được xác minh bằng cả chứng thư `ACTIVE` và `NEXT` (`VERIFY_CERT`); lời gọi ra dùng khóa `NEXT` sau khi kiểm tra kết nối đạt (`SIGNING_KEY`, `MTLS_CLIENT_CERT`)

  @US-19-012 @FR-19-012 @S @âm
  Kịch bản: US-19-012 âm 1 · Đã có bản `NEXT` của cùng mục đích
    Biết NCC `ACTIVE` hoặc `SUSPENDED`; bản `ACTIVE` của mục đích cần xoay tồn tại; bí mật mới đã nạp vào OpenBao
    Khi đã có bản `NEXT` của cùng mục đích
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-069 @FR-19-069 @M
  Kịch bản: US-19-069 dương · Quản lý bảng ánh xạ mã kết quả nhà cung cấp (đề xuất)
    Biết NCC không ở `RETIRED`
    Khi quản trị thanh toán bấm "Đề nghị thay đổi" ở tab "Ánh xạ mã" của UI-19-04; người phê duyệt quyết định ở UI-19-13. Việc tra bảng chạy mỗi khi adapter nhận một kết quả
    Thì bảng ánh xạ phiên bản hiện hành; lịch sử phiên bản; đề nghị `RESULT_MAPPING_CHANGE` kèm bảng so sánh trước – sau
    Và khi duyệt: tạo `mapping_version` mới có hiệu lực ngay; mọi kết quả nhận sau thời điểm đó dùng phiên bản mới; bản ghi IPN và giao dịch lưu phiên bản ánh xạ đã dùng để truy vết

  @US-19-069 @FR-19-069 @M @âm
  Kịch bản: US-19-069 âm 1 · Dòng trùng, dòng `SUCCEEDED` không phải kết quả cuối
    Biết NCC không ở `RETIRED`
    Khi dòng trùng, dòng `SUCCEEDED` không phải kết quả cuối
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-069 @FR-19-069 @M @âm
  Kịch bản: US-19-069 âm 2 · Đã có đề nghị đổi ánh xạ `PENDING` cho NCC
    Biết NCC không ở `RETIRED`
    Khi đã có đề nghị đổi ánh xạ `PENDING` cho NCC
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  # ---- EP-19-B · Nhóm dịch vụ và dịch vụ thanh toán

  @US-19-013 @FR-19-013 @M
  Kịch bản: US-19-013 dương · Quản lý nhóm dịch vụ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán mở UI-19-07, bấm "Thêm nhóm", "Sửa" hoặc "Xóa"; biểu mẫu ở UI-19-08
    Thì nhóm kèm số dịch vụ theo trạng thái; danh sách có `q`, `sectorCode`, sắp xếp `displayOrder`, `name`
    Và xóa là xóa mềm (`deleted_at`); mã của nhóm đã xóa được dùng lại

  @US-19-013 @FR-19-013 @M @âm
  Kịch bản: US-19-013 âm 1 · Mã trùng
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi mã trùng
    Thì hệ thống từ chối với ERR-19-038 (409)
    Và người dùng thấy thông báo "{code}"

  @US-19-013 @FR-19-013 @M @âm
  Kịch bản: US-19-013 âm 2 · Mã lĩnh vực không hợp lệ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi mã lĩnh vực không hợp lệ
    Thì hệ thống từ chối với ERR-19-039 (422)
    Và người dùng thấy thông báo "Mã danh mục"

  @US-19-014 @FR-19-014 @M
  Kịch bản: US-19-014 dương · Quản lý dịch vụ thanh toán
    Biết nhóm dịch vụ và NCC tồn tại; NCC không `RETIRED`
    Khi quản trị thanh toán bấm "Thêm dịch vụ" hoặc "Sửa" ở UI-19-09, điền biểu mẫu UI-19-10 rồi bấm "Lưu"
    Thì dịch vụ `DRAFT` (tạo), dịch vụ sau sửa; danh sách có lọc `q`, `groupId`, `providerId`, `status`, `feeTypeCode`, `collectingAgencyCode`, `catalogInvalid`
    Và tạo: dịch vụ `DRAFT`

  @US-19-014 @FR-19-014 @M @âm
  Kịch bản: US-19-014 âm 1 · Khoảng số tiền sai
    Biết nhóm dịch vụ và NCC tồn tại; NCC không `RETIRED`
    Khi khoảng số tiền sai
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-014 @FR-19-014 @M @âm
  Kịch bản: US-19-014 âm 2 · Mã trùng
    Biết nhóm dịch vụ và NCC tồn tại; NCC không `RETIRED`
    Khi mã trùng
    Thì hệ thống từ chối với ERR-19-038 (409)
    Và người dùng thấy thông báo "{code}"

  @US-19-015 @FR-19-015 @M
  Kịch bản: US-19-015 dương · Điều khiển vòng đời dịch vụ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Kích hoạt", "Tạm dừng", "Mở lại", "Ngừng hẳn" hoặc "Xóa" ở UI-19-09, UI-19-10; có thể chọn nhiều dòng để tạm dừng hàng loạt
    Thì dịch vụ với trạng thái mới và ETag mới; xóa trả `204`
    Và `ACTIVE`: đối tác được gán tạo được giao dịch
    Và sự kiện được phát: EVT-19-03

  @US-19-015 @FR-19-015 @M @âm
  Kịch bản: US-19-015 âm 1 · Kích hoạt khi NCC không `ACTIVE`, mã danh mục hết hiệu lực, thiếu tài khoản thụ hưởng
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kích hoạt khi NCC không `ACTIVE`, mã danh mục hết hiệu lực, thiếu tài khoản thụ hưởng
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-015 @FR-19-015 @M @âm
  Kịch bản: US-19-015 âm 2 · Ngừng hẳn khi còn việc dở
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi ngừng hẳn khi còn việc dở
    Thì hệ thống từ chối với ERR-19-036 (409)
    Và người dùng thấy thông báo "Còn {pendingTransactions} giao dịch đang dở và {openSessions} phiên đối soát chưa chốt."

  @US-19-016 @FR-19-016 @S
  Kịch bản: US-19-016 dương · Kiểm tra và đồng bộ mã danh mục PH-07
    Biết danh mục cần tra thuộc danh sách 11 danh mục ở khung §1.5; module danh mục PH-07 đã nạp gói nền cho tenant
    Khi biểu mẫu UI-19-08, UI-19-10 gọi tra cứu khi người dùng gõ vào ô mã danh mục; FR-19-013, 014, 017 gọi kiểm tra khi ghi; sự kiện `{tenant}.rdm.catalog.published.v1` của PH-07 kích hoạt việc rà cờ
    Thì API-19-028 trả mục của 11 danh mục ở khung §1.5 (mã, tên, hiệu lực), có tìm kiếm; cờ `catalog_invalid` trên dịch vụ và nhóm
    Và mã đã ghi trong cấu hình là mã còn hiệu lực tại thời điểm ghi; nhóm, dịch vụ dùng mã bị ngừng có `catalog_invalid = true` cho tới khi được sửa
    Và sự kiện được phát: Khi bật cờ: cảnh báo PH-13 cho quản trị thanh toán; EVT-19-03 với `catalogInvalid = true`

  @US-19-016 @FR-19-016 @S @âm
  Kịch bản: US-19-016 âm 1 · Mã PH-07 không tồn tại hoặc hết hiệu lực; hoặc PH-07 không kiểm tra được khi tạo mới (khung §1.5)
    Biết danh mục cần tra thuộc danh sách 11 danh mục ở khung §1.5; module danh mục PH-07 đã nạp gói nền cho tenant
    Khi mã PH-07 không tồn tại hoặc hết hiệu lực; hoặc PH-07 không kiểm tra được khi tạo mới (khung §1.5)
    Thì hệ thống từ chối với ERR-19-039 (422)
    Và người dùng thấy thông báo "Mã danh mục"

  # ---- EP-19-C · Đối tác và thông tin xác thực

  @US-19-017 @FR-19-017 @M
  Kịch bản: US-19-017 dương · Quản lý hồ sơ đối tác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Thêm đối tác" ở UI-19-11 hoặc "Sửa" ở tab "Hồ sơ" của UI-19-12
    Thì đối tác `DRAFT` (tạo) với `routingMode = LEGACY` nếu có `legacyAppCode`, ngược lại `DATAHUB`; chi tiết gồm hồ sơ, số client còn hiệu lực, dịch vụ được gán, đầu nhận webhook, chế độ định tuyến, số giao dịch 30 ngày
    Và tạo: đối tác `DRAFT`, `routingMode` = `LEGACY` (có `legacyAppCode`) hoặc `DATAHUB`

  @US-19-017 @FR-19-017 @M @âm
  Kịch bản: US-19-017 âm 1 · Địa chỉ quay về sai
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi địa chỉ quay về sai
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-017 @FR-19-017 @M @âm
  Kịch bản: US-19-017 âm 2 · Mã hoặc `legacyAppCode` trùng
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi mã hoặc `legacyAppCode` trùng
    Thì hệ thống từ chối với ERR-19-038 (409)
    Và người dùng thấy thông báo "{code}"

  @US-19-018 @FR-19-018 @M
  Kịch bản: US-19-018 dương · Điều khiển vòng đời đối tác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Gửi duyệt", "Tạm dừng", "Mở lại" hoặc "Đề nghị chấm dứt" ở UI-19-12; người phê duyệt quyết định ở UI-19-13
    Thì đề nghị: `201` kèm `approval_request` (`PARTNER_ONBOARD` hoặc `PARTNER_TERMINATE`); tạm dừng, mở lại: đối tác với trạng thái mới, ETag mới
    Và `ACTIVE`: tạo được giao dịch
    Và sự kiện được phát: EVT-19-04

  @US-19-018 @FR-19-018 @M @âm
  Kịch bản: US-19-018 âm 1 · Thiếu điều kiện gửi duyệt
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thiếu điều kiện gửi duyệt
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-018 @FR-19-018 @M @âm
  Kịch bản: US-19-018 âm 2 · Chuyển trạng thái không hợp lệ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi chuyển trạng thái không hợp lệ
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-019 @FR-19-019 @M
  Kịch bản: US-19-019 dương · Cấp và thu hồi client của đối tác
    Biết đối tác `DRAFT`, `PENDING_APPROVAL`, `ACTIVE` hoặc `SUSPENDED`
    Khi người dùng bấm "Cấp client" hoặc "Thu hồi" ở tab "Client" của UI-19-12
    Thì hệ thống trả `idpClientId`, `authMethod`, dấu vân tay chứng thư, `expiresAt`; hướng dẫn lấy token (URL token của realm `dh-{tenant}`)
    Và client tại PH-12 có vai trò `ROLE-PARTNER_SYSTEM` và claim `partner_id`; thu hồi có hiệu lực ≤ 60 giây (NFR-19-019)

  @US-19-019 @FR-19-019 @M @âm
  Kịch bản: US-19-019 âm 1 · Khóa, chứng thư không hợp lệ
    Biết đối tác `DRAFT`, `PENDING_APPROVAL`, `ACTIVE` hoặc `SUSPENDED`
    Khi khóa, chứng thư không hợp lệ
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-019 @FR-19-019 @M @âm
  Kịch bản: US-19-019 âm 2 · Đối tác `TERMINATED`
    Biết đối tác `DRAFT`, `PENDING_APPROVAL`, `ACTIVE` hoặc `SUSPENDED`
    Khi đối tác `TERMINATED`
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-020 @FR-19-020 @M
  Kịch bản: US-19-020 dương · Gán dịch vụ và hạn mức cho đối tác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Gán dịch vụ" hoặc sửa hạn mức ở tab "Dịch vụ và hạn mức" của UI-19-12
    Thì danh sách gán kèm hạn mức đã dùng trong ngày (từ bộ đếm Valkey)
    Và gán có hiệu lực ngay; bỏ gán không ảnh hưởng giao dịch đã tạo

  @US-19-020 @FR-19-020 @M @âm
  Kịch bản: US-19-020 âm 1 · Mã dịch vụ không có trong tenant
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi mã dịch vụ không có trong tenant
    Thì hệ thống từ chối với ERR-19-007 (404)
    Và người dùng thấy thông báo "Không tìm thấy dịch vụ thanh toán mã"

  @US-19-020 @FR-19-020 @M @âm
  Kịch bản: US-19-020 âm 2 · Thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-021 @FR-19-021 @M
  Kịch bản: US-19-021 dương · Cấu hình webhook của đối tác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Thêm đầu nhận", "Gửi thử", "Xoay bí mật" hoặc "Vô hiệu" ở tab "Webhook" của UI-19-12
    Thì đầu nhận với `endpointStatus`; **bí mật ký hiển thị đúng một lần** khi tạo và khi xoay (≥ 256 bit, tiền tố `whsec_`), sau đó chỉ còn 4 ký tự cuối
    Và bí mật nằm ở OpenBao `kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}`; CSDL lưu tham chiếu

  @US-19-021 @FR-19-021 @M @âm
  Kịch bản: US-19-021 âm 1 · Địa chỉ không hợp lệ hoặc nội bộ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi địa chỉ không hợp lệ hoặc nội bộ
    Thì hệ thống từ chối với ERR-19-044 (422)
    Và người dùng thấy thông báo "Địa chỉ webhook phải dùng https và không trỏ tới mạng nội bộ."

  @US-19-021 @FR-19-021 @M @âm
  Kịch bản: US-19-021 âm 2 · Loại sự kiện không hỗ trợ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi loại sự kiện không hỗ trợ
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  # ---- EP-19-D · Giao dịch thanh toán và kết nối PayGov

  @US-19-022 @FR-19-022 @M
  Kịch bản: US-19-022 dương · Tạo giao dịch thanh toán
    Biết client hợp lệ, chưa bị thu hồi; đối tác `ACTIVE` ở chế độ `DATAHUB` hoặc `SHADOW`
    Khi HTTT đối tác gọi API-19-101 `POST /api/payment-partner/v1/payments` khi hồ sơ của người nộp phát sinh nghĩa vụ thanh toán
    Thì hệ thống trả 201 với `transactionCode`, `status` (`PENDING`, hoặc `CREATED` khi khởi tạo chưa xác định), `paymentUrl`, `expiresAt`, `amount`, `serviceCode`, `partnerOrderId`, `createdAt`; header `Location`, `Idempotent-Replayed` khi trả lại
    Và giao dịch ghi trong `pg-payment` với `transaction_event` đầu tiên (`→ CREATED`, nguồn `PARTNER_API`); bộ đếm hạn mức ngày tăng
    Và sự kiện được phát: EVT-19-05

  @US-19-022 @FR-19-022 @M @âm
  Kịch bản: US-19-022 âm 1 · Yêu cầu vi phạm một trong 15 bước kiểm tra của FR-19-023
    Biết client hợp lệ, chưa bị thu hồi; đối tác `ACTIVE` ở chế độ `DATAHUB` hoặc `SHADOW`
    Khi yêu cầu vi phạm một trong 15 bước kiểm tra của FR-19-023
    Thì hệ thống từ chối với ERR-19-001, ERR-19-049

  @US-19-022 @FR-19-022 @M @âm
  Kịch bản: US-19-022 âm 2 · Mạch ngắt mở, NCC tạm dừng
    Biết client hợp lệ, chưa bị thu hồi; đối tác `ACTIVE` ở chế độ `DATAHUB` hoặc `SHADOW`
    Khi mạch ngắt mở, NCC tạm dừng
    Thì hệ thống từ chối với ERR-19-017
    Và người dùng thấy thông báo "Kênh thanh toán"

  @US-19-023 @FR-19-023 @M
  Kịch bản: US-19-023 dương · Kiểm tra hợp lệ yêu cầu thanh toán
    Biết yêu cầu đã qua xác thực ở PH-03; ngữ cảnh tenant và đối tác đã xác định từ token client
    Khi FR-19-022 gọi bên trong cho mỗi yêu cầu tạo giao dịch, trước khi ghi bất kỳ dữ liệu nào
    Thì chấp nhận, hoặc đúng một lỗi RFC 9457 (lỗi định dạng ở bước 5 có thể kèm nhiều phần tử `errors`)

  @US-19-023 @FR-19-023 @M @âm
  Kịch bản: US-19-023 âm 1 · PH-20 chưa bật hoặc đã tạm ngừng PH-19 cho tenant (FR-19-064)
    Biết yêu cầu đã qua xác thực ở PH-03; ngữ cảnh tenant và đối tác đã xác định từ token client
    Khi PH-20 chưa bật hoặc đã tạm ngừng PH-19 cho tenant (FR-19-064)
    Thì hệ thống từ chối với ERR-19-049 (503)
    Và người dùng thấy thông báo "Phân hệ thanh toán đang tạm ngừng cho tỉnh."

  @US-19-023 @FR-19-023 @M @âm
  Kịch bản: US-19-023 âm 2 · Đối tác `DRAFT`, `PENDING_APPROVAL`, `SUSPENDED` hoặc `TERMINATED` gọi API tạo giao dịch, hoàn tiền
    Biết yêu cầu đã qua xác thực ở PH-03; ngữ cảnh tenant và đối tác đã xác định từ token client
    Khi đối tác `DRAFT`, `PENDING_APPROVAL`, `SUSPENDED` hoặc `TERMINATED` gọi API tạo giao dịch, hoàn tiền
    Thì hệ thống từ chối với ERR-19-005 (403)
    Và người dùng thấy thông báo "Đối tác"

  @US-19-024 @FR-19-024 @M
  Kịch bản: US-19-024 dương · Khởi tạo thanh toán tại nhà cung cấp qua adapter
    Biết giao dịch ở `CREATED`; NCC của dịch vụ `ACTIVE`; có tham chiếu bí mật `ACTIVE` của môi trường cần gọi
    Khi FR-19-022 gọi ngay sau khi giao dịch `CREATED` đã ghi CSDL; FR-19-004 gọi cho giao dịch thử
    Thì một trong ba kết cục: `ACCEPTED` (có `providerReference`, `paymentUrl`), `REJECTED` (mã kết quả NCC), `UNCERTAIN` (timeout, 5xx, mất kết nối)
    Và `ACCEPTED` → `PENDING`, đặt `next_poll_at` theo BR-19-016. `REJECTED` → `FAILED`, trừ lại hạn mức
    Và sự kiện được phát: EVT-19-06 (`ACCEPTED`), EVT-19-08 (`REJECTED`)

  @US-19-024 @FR-19-024 @M @âm
  Kịch bản: US-19-024 âm 1 · NCC từ chối rõ ràng
    Biết giao dịch ở `CREATED`; NCC của dịch vụ `ACTIVE`; có tham chiếu bí mật `ACTIVE` của môi trường cần gọi
    Khi NCC từ chối rõ ràng
    Thì hệ thống từ chối với ERR-19-018 (502)
    Và người dùng thấy thông báo "Nhà cung cấp từ chối khởi tạo thanh toán, lý do"

  @US-19-024 @FR-19-024 @M @âm
  Kịch bản: US-19-024 âm 2 · Timeout, 5xx, lỗi mạng, mã chưa biết
    Biết giao dịch ở `CREATED`; NCC của dịch vụ `ACTIVE`; có tham chiếu bí mật `ACTIVE` của môi trường cần gọi
    Khi timeout, 5xx, lỗi mạng, mã chưa biết
    Thì hệ thống từ chối với ERR-19-019 (504)
    Và người dùng thấy thông báo "Chưa xác định được kết quả tại nhà cung cấp. Hệ thống sẽ tự truy vấn lại."

  @US-19-025 @FR-19-025 @M
  Kịch bản: US-19-025 dương · Xử lý người nộp quay về
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi PayGov chuyển trình duyệt của người nộp về `/api/payment-callback/v1/paygov/{connectionKey}/return` sau khi người nộp thanh toán hoặc bỏ dở
    Thì trang UI-19-28 hiển thị kết quả **theo trạng thái trong CSDL** (không theo tham số), sau 5 giây tự chuyển về `returnUrl` của đối tác kèm `transactionCode`, `status`, `ts`, `sig`

  @US-19-025 @FR-19-025 @M @âm
  Kịch bản: US-19-025 âm 1 · `connectionKey` không tồn tại
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi `connectionKey` không tồn tại
    Thì HTTP 404; trang kết quả hiển thị thông báo
    Và người dùng thấy thông báo "Trang lỗi chung"

  @US-19-025 @FR-19-025 @M @âm
  Kịch bản: US-19-025 âm 2 · Sai chữ ký tham số
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi sai chữ ký tham số
    Thì HTTP 400; trang kết quả hiển thị thông báo
    Và người dùng thấy thông báo "Thông báo không xác nhận được, không chuyển hướng tới đối tác"

  @US-19-026 @FR-19-026 @S
  Kịch bản: US-19-026 dương · Hủy giao dịch chưa thanh toán
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi HTTT đối tác gọi API-19-104; cán bộ tra cứu bấm "Hủy giao dịch" ở UI-19-15 và nhập lý do
    Thì giao dịch `CANCELLED`, hoặc 200 với giao dịch giữ `PENDING` khi đang chờ NCC xác nhận
    Và giao dịch `CANCELLED` với `transaction_event` nguồn `PARTNER_API` hoặc `USER`, hoặc giữ `PENDING` khi chờ NCC xác nhận hủy
    Và sự kiện được phát: EVT-19-09 kèm `cancelledBy` (`PARTNER`, `USER`)

  @US-19-026 @FR-19-026 @S @âm
  Kịch bản: US-19-026 âm 1 · Thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-027 @FR-19-027 @M
  Kịch bản: US-19-027 dương · Tự động hết hạn giao dịch
    Biết giao dịch `CREATED` hoặc `PENDING` có `expires_at + 30 phút ≤ now`
    Khi tác vụ nền chạy mỗi phút
    Thì số giao dịch đã chuyển `EXPIRED`, số giao dịch được xác định thành công ở truy vấn cuối, số giao dịch giữ nguyên; metric của tác vụ
    Và giao dịch quá hạn không có kết quả thành công chuyển `EXPIRED`; quá 72 giờ không xác định được thì `EXPIRED` kèm `needs_reconciliation = true`
    Và sự kiện được phát: EVT-19-10

  @US-19-027 @FR-19-027 @M @âm
  Kịch bản: US-19-027 âm 1 · NCC không trả lời truy vấn cuối hoặc trả mã `UNKNOWN`
    Biết giao dịch `CREATED` hoặc `PENDING` có `expires_at + 30 phút ≤ now`
    Khi NCC không trả lời truy vấn cuối hoặc trả mã `UNKNOWN`
    Thì không phải lỗi API; giao dịch giữ nguyên trạng thái và được thử lại theo lịch BR-19-016, người vận hành thấy số giao dịch chờ xác định trên UI-19-02

  @US-19-027 @FR-19-027 @M @âm
  Kịch bản: US-19-027 âm 2 · Tác vụ không chạy (bản sao dừng)
    Biết giao dịch `CREATED` hoặc `PENDING` có `expires_at + 30 phút ≤ now`
    Khi tác vụ không chạy (bản sao dừng)
    Thì không phải lỗi API; bản sao khác nhận lượt sau nhờ `SKIP LOCKED`, PH-13 cảnh báo khi tuổi giao dịch quá hạn chưa xử lý vượt 10 phút

  @US-19-028 @FR-19-028 @M
  Kịch bản: US-19-028 dương · Ghi lịch sử trạng thái bất biến
    Biết cặp (trạng thái cũ, trạng thái mới) có trong bảng chuyển trạng thái khung §7.4
    Khi mọi chức năng đổi trạng thái giao dịch (FR-19-022, 024, 026, 027, 030, 036, 037, 041, 046) gọi hàm miền `TransactionStateMachine.transition`
    Thì một dòng `transaction_event` mới; `sequence` của giao dịch tăng 1; bản ghi chuỗi băm hằng ngày lưu kho WORM
    Và mỗi lần `payment_transaction.status` đổi có đúng một dòng `transaction_event` ghi trong cùng giao dịch CSDL; tăng `sequence` của giao dịch

  @US-19-028 @FR-19-028 @M @âm
  Kịch bản: US-19-028 âm 1 · Thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Biết cặp (trạng thái cũ, trạng thái mới) có trong bảng chuyển trạng thái khung §7.4
    Khi thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  # ---- EP-19-E · Nhận kết quả thanh toán (IPN)

  @US-19-029 @FR-19-029 @M
  Kịch bản: US-19-029 dương · Tiếp nhận và xác minh IPN
    Biết NCC ứng với `connectionKey` tồn tại, không `RETIRED`; danh sách IP và chứng thư `VERIFY_CERT` của NCC đã cấu hình
    Khi máy chủ PayGov gọi `POST /api/payment-callback/v1/paygov/{connectionKey}/ipn` (API-19-201), hoặc API-19-203 cho IPN hoàn tiền, API-19-204 cho thông báo đối soát
    Thì phản hồi cho NCC theo đặc tả NCC (giả định: HTTP 200 với thân xác nhận; OQ-19-03); bản ghi `callback_inbox`
    Và mọi IPN, kể cả bị từ chối, có một dòng `callback_inbox` với `verification_result`; IPN `VERIFIED` ở `processing_status = RECEIVED` chờ xử lý
    Và sự kiện được phát: IPN bị từ chối: sự kiện an ninh tới PH-13, metric `payment_callback_rejected_total{reason}`

  @US-19-029 @FR-19-029 @M @âm
  Kịch bản: US-19-029 âm 1 · IP nguồn hoặc chứng thư mTLS không thuộc danh sách cho phép; `connectionKey` không tồn tại
    Biết NCC ứng với `connectionKey` tồn tại, không `RETIRED`; danh sách IP và chứng thư `VERIFY_CERT` của NCC đã cấu hình
    Khi IP nguồn hoặc chứng thư mTLS không thuộc danh sách cho phép; `connectionKey` không tồn tại
    Thì hệ thống từ chối với ERR-19-027 (403)
    Và người dùng thấy thông báo "Nguồn gửi thông báo kết quả (IPN) không được phép, địa chỉ IP hoặc chứng thư không có trong danh sách cho phép."

  @US-19-029 @FR-19-029 @M @âm
  Kịch bản: US-19-029 âm 2 · Thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Biết NCC ứng với `connectionKey` tồn tại, không `RETIRED`; danh sách IP và chứng thư `VERIFY_CERT` của NCC đã cấu hình
    Khi thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-030 @FR-19-030 @M
  Kịch bản: US-19-030 dương · Xử lý IPN đúng một lần
    Biết bản ghi `callback_inbox` `VERIFIED` ở `processing_status = RECEIVED`
    Khi hàng đợi nội bộ do FR-19-029 kích hoạt; tác vụ quét hộp nhận mỗi 10 giây cho bản ghi `RECEIVED` còn sót
    Thì inbox `PROCESSED`, `DUPLICATE`, `QUARANTINED` hoặc `FAILED`; giao dịch chuyển trạng thái khi hợp lệ
    Và inbox ở `PROCESSED`, `DUPLICATE`, `QUARANTINED` hoặc `FAILED`; giao dịch ở trạng thái mới khi hợp lệ, kèm `transaction_event` nguồn `IPN` và outbox webhook
    Và sự kiện được phát: EVT-19-07 hoặc 08; Webhook (FR-19-060) qua outbox

  @US-19-030 @FR-19-030 @M @âm
  Kịch bản: US-19-030 âm 1 · Lỗi kỹ thuật khi xử lý (CSDL, giải mã) quá 5 lần
    Biết bản ghi `callback_inbox` `VERIFIED` ở `processing_status = RECEIVED`
    Khi lỗi kỹ thuật khi xử lý (CSDL, giải mã) quá 5 lần
    Thì không phải lỗi API; inbox `FAILED`, bản tin chuyển DLQ của PH-18, PH-13 cảnh báo người vận hành; cán bộ xử lý lại ở UI-19-16 (FR-19-032)

  @US-19-030 @FR-19-030 @M @âm
  Kịch bản: US-19-030 âm 2 · IPN hợp lệ nhưng sai số tiền, sai tham chiếu, không tìm thấy giao dịch hoặc trái trạng thái (BR-19-015) …
    Biết bản ghi `callback_inbox` `VERIFIED` ở `processing_status = RECEIVED`
    Khi IPN hợp lệ nhưng sai số tiền, sai tham chiếu, không tìm thấy giao dịch hoặc trái trạng thái (BR-19-015); NCC nhận phản hồi đã tiếp nhận, mã này chỉ ghi nội bộ
    Thì hệ thống từ chối với ERR-19-028 (200)
    Và người dùng thấy thông báo "Thông báo kết quả (IPN) đã được tiếp nhận nhưng bị cách ly để xem xét, lý do"

  @US-19-031 @FR-19-031 @M
  Kịch bản: US-19-031 dương · Cách ly IPN bất thường
    Biết bản ghi hộp nhận `VERIFIED` rơi vào nhánh cách ly của FR-19-030
    Khi FR-19-030 gặp một nhánh cách ly theo bảng của nó, hoặc không tìm thấy giao dịch cho IPN
    Thì bản ghi chênh lệch `OPEN` (loại, `callback_id`, số tiền hai phía, `due_at`, ngày giao dịch); bản ghi hộp nhận `QUARANTINED`
    Và inbox `QUARANTINED` với `processing_error`; bản ghi chênh lệch `OPEN` gắn phiên đối soát của ngày giao dịch (tạo phiên `SCHEDULED` nếu chưa có); phiên đang `READY_TO_CLOSE` quay về `IN_REVIEW`
    Và sự kiện được phát: EVT-19-17; Cảnh báo PH-13 mức cao với `AMOUNT_MISMATCH`, `ORPHAN_CALLBACK`

  @US-19-031 @FR-19-031 @M @âm
  Kịch bản: US-19-031 âm 1 · IPN thứ hai cho cùng `callback_id`
    Biết bản ghi hộp nhận `VERIFIED` rơi vào nhánh cách ly của FR-19-030
    Khi IPN thứ hai cho cùng `callback_id`
    Thì không phải lỗi API; khóa duy nhất theo `callback_id` bảo đảm không sinh chênh lệch thứ hai

  @US-19-031 @FR-19-031 @M @âm
  Kịch bản: US-19-031 âm 2 · Chưa có phiên đối soát cho ngày giao dịch
    Biết bản ghi hộp nhận `VERIFIED` rơi vào nhánh cách ly của FR-19-030
    Khi chưa có phiên đối soát cho ngày giao dịch
    Thì không phải lỗi; hệ thống tạo phiên `SCHEDULED` để gắn chênh lệch

  @US-19-032 @FR-19-032 @S
  Kịch bản: US-19-032 dương · Xem và xử lý lại IPN
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi cán bộ mở UI-19-16 hoặc tab "IPN" của UI-19-15, lọc danh sách, mở chi tiết; bấm "Xử lý lại" ở một bản ghi đủ điều kiện
    Thì danh sách; chi tiết gồm header và thân nguyên văn đã che (giá trị chữ ký rút gọn, dữ liệu cá nhân che theo BR-19-031), các lần xử lý, liên kết giao dịch, chênh lệch
    Và xem: không đổi dữ liệu

  @US-19-032 @FR-19-032 @S @âm
  Kịch bản: US-19-032 âm 1 · Xử lý lại IPN bị từ chối ở lớp xác minh hoặc không ở trạng thái cho phép
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi xử lý lại IPN bị từ chối ở lớp xác minh hoặc không ở trạng thái cho phép
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  # ---- EP-19-F · Lũy đẳng và chống trùng

  @US-19-033 @FR-19-033 @M
  Kịch bản: US-19-033 dương · Bảo đảm idempotency theo Idempotency-Key
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi mọi `POST` của nhóm API đối tác (API-19-101, 104, 105); `POST` tạo mới của nhóm quản trị khi có header `Idempotency-Key`
    Thì phản hồi gốc của lần xử lý đầu (khi trả lại) kèm `Idempotent-Replayed: true`, hoặc lỗi ERR-19-003, ERR-19-004
    Và mỗi bộ (tenant, client, method, path, key) có tối đa một bản ghi trong 24 giờ

  @US-19-033 @FR-19-033 @M @âm
  Kịch bản: US-19-033 âm 1 · Yêu cầu trước với cùng khóa chưa xong
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi yêu cầu trước với cùng khóa chưa xong
    Thì hệ thống từ chối với ERR-19-004 (409)
    Và người dùng thấy thông báo "Yêu cầu cùng khóa chống trùng đang được xử lý. Chờ kết quả rồi mới gửi lại."

  @US-19-033 @FR-19-033 @M @âm
  Kịch bản: US-19-033 âm 2 · Cùng khóa nhưng băm nội dung khác bản ghi cũ
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi cùng khóa nhưng băm nội dung khác bản ghi cũ
    Thì hệ thống từ chối với ERR-19-003 (422)
    Và người dùng thấy thông báo "Khóa chống trùng"

  @US-19-034 @FR-19-034 @M
  Kịch bản: US-19-034 dương · Chống trùng theo mã đơn hàng của đối tác
    Biết yêu cầu tạo giao dịch đã qua bước 1…13 của FR-19-023
    Khi bước 14 của FR-19-023 và lệnh ghi giao dịch của FR-19-022
    Thì chấp nhận, hoặc ERR-19-015 kèm `existingTransactionCode`, `existingStatus`

  @US-19-034 @FR-19-034 @M @âm
  Kịch bản: US-19-034 âm 1 · Trùng `partner_order_id` theo BR-19-007; `detail` kèm mã giao dịch hiện có
    Biết yêu cầu tạo giao dịch đã qua bước 1…13 của FR-19-023
    Khi trùng `partner_order_id` theo BR-19-007; `detail` kèm mã giao dịch hiện có
    Thì hệ thống từ chối với ERR-19-015 (409)
    Và người dùng thấy thông báo "Mã đơn hàng"

  # ---- EP-19-G · Truy vấn và đồng bộ trạng thái

  @US-19-035 @FR-19-035 @M
  Kịch bản: US-19-035 dương · Đối tác truy vấn trạng thái giao dịch
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi HTTT đối tác gọi API-19-102 (một giao dịch) hoặc API-19-103 (theo mã đơn hàng)
    Thì hệ thống trả `transactionCode`, `partnerOrderId`, `serviceCode`, `status`, `reconStatus`, `amount`, `refundedAmount`, `currency`, `createdAt`, `expiresAt`, `paidAt`, `providerCode`, `providerReference`, `channelCode`, `bankCode`, `latePaid` …

  @US-19-035 @FR-19-035 @M @âm
  Kịch bản: US-19-035 âm 1 · Tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác) …
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác); không phân biệt hai trường hợp để không lộ thông tin
    Thì hệ thống từ chối với ERR-19-020 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu, hoặc bạn không có quyền xem."

  @US-19-036 @FR-19-036 @M
  Kịch bản: US-19-036 dương · Chủ động truy vấn nhà cung cấp cho giao dịch treo
    Biết giao dịch `PENDING`, hoặc `CREATED` có `init_uncertain`; `next_poll_at ≤ now`; `is_shadow = false`; NCC có năng lực truy vấn
    Khi tác vụ nền chạy mỗi 30 giây; FR-19-025 và FR-19-027 có thể đặt `next_poll_at = now` để truy vấn sớm
    Thì kết quả truy vấn đã dịch cho từng giao dịch; `next_poll_at` mới; metric số lượt truy vấn, tỷ lệ xác định được
    Và kết quả truy vấn được áp như IPN (bảng của FR-19-030) với `source = POLL`
    Và sự kiện được phát: EVT-19-07, EVT-19-08 khi kết quả truy vấn làm giao dịch đổi trạng thái (phát qua FR-19-030)

  @US-19-036 @FR-19-036 @M @âm
  Kịch bản: US-19-036 âm 1 · NCC không trả lời trong 5 giây hoặc vượt giới hạn tần suất
    Biết giao dịch `PENDING`, hoặc `CREATED` có `init_uncertain`; `next_poll_at ≤ now`; `is_shadow = false`; NCC có năng lực truy vấn
    Khi NCC không trả lời trong 5 giây hoặc vượt giới hạn tần suất
    Thì không phải lỗi API; lần truy vấn ghi nhật ký tích hợp, giao dịch giữ nguyên và chờ mốc kế tiếp; tỷ lệ lỗi cao làm suy giảm sức khỏe NCC (FR-19-011) và hiện trên UI-19-02

  @US-19-036 @FR-19-036 @M @âm
  Kịch bản: US-19-036 âm 2 · Mạch ngắt của NCC đang mở
    Biết giao dịch `PENDING`, hoặc `CREATED` có `init_uncertain`; `next_poll_at ≤ now`; `is_shadow = false`; NCC có năng lực truy vấn
    Khi mạch ngắt của NCC đang mở
    Thì không phải lỗi API; lượt truy vấn vẫn chạy với bulkhead riêng theo BR-19-013, kết quả lỗi không làm đổi trạng thái giao dịch

  @US-19-037 @FR-19-037 @S
  Kịch bản: US-19-037 dương · Đồng bộ trạng thái thủ công
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi cán bộ bấm "Đồng bộ với NCC" ở UI-19-15 và nhập lý do
    Thì kết quả truy vấn đã dịch (kết cục, mã NCC, số tiền, thời điểm), trạng thái giao dịch trước và sau
    Và giao dịch đổi trạng thái khi kết quả hợp lệ (nguồn `MANUAL_SYNC`), hoặc không đổi; bộ đếm tần suất đồng bộ của giao dịch tăng

  @US-19-037 @FR-19-037 @S @âm
  Kịch bản: US-19-037 âm 1 · Giao dịch `REFUNDED`
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi giao dịch `REFUNDED`
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  # ---- EP-19-H · Hoàn tiền

  @US-19-038 @FR-19-038 @M
  Kịch bản: US-19-038 dương · Lập yêu cầu hoàn tiền
    Biết tenant bật hoàn tiền (`19.refund.enabled = true`); giao dịch `SUCCEEDED` hoặc `PARTIALLY_REFUNDED`, `is_test = false`, `is_shadow = false`, còn trong hạn hoàn
    Khi kế toán bấm "Lập yêu cầu hoàn" ở UI-19-15 hoặc UI-19-17 (mở biểu mẫu UI-19-18); HTTT đối tác gọi API-19-105
    Thì yêu cầu hoàn `PENDING_APPROVAL` với `refundCode` (mẫu `R` + mã giao dịch rút gọn + 4 ký tự, duy nhất toàn cục), `approvalLevel` cần (1 hoặc 2), `mode` dự kiến
    Và yêu cầu hoàn `PENDING_APPROVAL` cùng `approval_request` loại `REFUND`; giao dịch gốc không đổi trạng thái cho tới khi hoàn thành công
    Và sự kiện được phát: EVT-19-11

  @US-19-038 @FR-19-038 @M @âm
  Kịch bản: US-19-038 âm 1 · Tenant tắt hoàn tiền
    Biết tenant bật hoàn tiền (`19.refund.enabled = true`); giao dịch `SUCCEEDED` hoặc `PARTIALLY_REFUNDED`, `is_test = false`, `is_shadow = false`, còn trong hạn hoàn
    Khi tenant tắt hoàn tiền
    Thì hệ thống từ chối với ERR-19-032 (422)
    Và người dùng thấy thông báo "Hoàn tiền chưa được bật cho tỉnh, hoặc chế độ thực hiện không phù hợp."

  @US-19-038 @FR-19-038 @M @âm
  Kịch bản: US-19-038 âm 2 · Giao dịch không đủ điều kiện
    Biết tenant bật hoàn tiền (`19.refund.enabled = true`); giao dịch `SUCCEEDED` hoặc `PARTIALLY_REFUNDED`, `is_test = false`, `is_shadow = false`, còn trong hạn hoàn
    Khi giao dịch không đủ điều kiện
    Thì hệ thống từ chối với ERR-19-029 (409)
    Và người dùng thấy thông báo "Giao dịch không đủ điều kiện hoàn tiền: {reasonLabel}."

  @US-19-039 @FR-19-039 @M
  Kịch bản: US-19-039 dương · Phê duyệt hoặc từ chối hoàn tiền
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người phê duyệt mở đề nghị loại "Hoàn tiền" ở UI-19-13 hoặc UI-19-18 và bấm "Duyệt" hoặc "Từ chối"
    Thì đề nghị ở trạng thái mới; yêu cầu hoàn `APPROVED`, `PENDING_SECOND_APPROVAL` hoặc `REJECTED`
    Và một cấp: `APPROVED`
    Và sự kiện được phát: EVT-19-12 khi `APPROVED` hoặc `REJECTED`

  @US-19-039 @FR-19-039 @M @âm
  Kịch bản: US-19-039 âm 1 · Người duyệt trùng người lập, trùng người duyệt cấp trước, hoặc người xác nhận hoàn thủ công trùng người duyệt (mục 3.3)
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người duyệt trùng người lập, trùng người duyệt cấp trước, hoặc người xác nhận hoàn thủ công trùng người duyệt (mục 3.3)
    Thì hệ thống từ chối với ERR-19-033 (403)
    Và người dùng thấy thông báo "Bạn đã {role} đề nghị này nên không thể quyết định. Cần một người khác (tách nhiệm)."

  @US-19-039 @FR-19-039 @M @âm
  Kịch bản: US-19-039 âm 2 · Trạng thái không phải `SUCCEEDED`/`PARTIALLY_REFUNDED`, là giao dịch thử, hoặc đang có yêu cầu hoàn chưa kết thúc
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi trạng thái không phải `SUCCEEDED`/`PARTIALLY_REFUNDED`, là giao dịch thử, hoặc đang có yêu cầu hoàn chưa kết thúc
    Thì hệ thống từ chối với ERR-19-029 (409)
    Và người dùng thấy thông báo "Giao dịch không đủ điều kiện hoàn tiền: {reasonLabel}."

  @US-19-040 @FR-19-040 @M
  Kịch bản: US-19-040 dương · Thực thi hoàn tiền
    Biết yêu cầu hoàn `APPROVED` (thực thi tự động), `FAILED` (thực hiện lại, chuyển thủ công) hoặc `AWAITING_MANUAL` (xác nhận thủ công)
    Khi hệ thống tự chạy ngay sau khi yêu cầu `APPROVED`; kế toán bấm "Thực hiện lại", "Chuyển thủ công" hoặc "Xác nhận đã hoàn" ở UI-19-18
    Thì yêu cầu hoàn ở trạng thái mới (`PROCESSING`, `AWAITING_MANUAL`, `SUCCEEDED`, `FAILED`); với `CONFIRM_MANUAL`: chứng từ đã gắn
    Và xem theo bảng ở FR gốc
    Và sự kiện được phát: EVT-19-13 hoặc EVT-19-14 khi yêu cầu đạt kết quả cuối (phát qua FR-19-041)

  @US-19-040 @FR-19-040 @M @âm
  Kịch bản: US-19-040 âm 1 · Hành động không hợp lệ ở trạng thái hiện tại
    Biết yêu cầu hoàn `APPROVED` (thực thi tự động), `FAILED` (thực hiện lại, chuyển thủ công) hoặc `AWAITING_MANUAL` (xác nhận thủ công)
    Khi hành động không hợp lệ ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-040 @FR-19-040 @M @âm
  Kịch bản: US-19-040 âm 2 · Hết lượt thực thi lại
    Biết yêu cầu hoàn `APPROVED` (thực thi tự động), `FAILED` (thực hiện lại, chuyển thủ công) hoặc `AWAITING_MANUAL` (xác nhận thủ công)
    Khi hết lượt thực thi lại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-041 @FR-19-041 @M
  Kịch bản: US-19-041 dương · Theo dõi kết quả hoàn tiền
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở UI-19-17 (danh sách) hoặc UI-19-18 (chi tiết); đối tác gọi API-19-106; kết quả hoàn đến từ IPN hoàn, truy vấn hoặc ghi nhận thủ công
    Thì danh sách lọc theo `status[]`, `mode`, `reasonCode`, khoảng ngày lập, khoảng số tiền, `transactionCode`, người lập; chi tiết gồm giao dịch gốc, các cấp duyệt, các lần thực thi, chứng từ, nhật ký trao đổi
    Và xem: không đổi dữ liệu
    Và sự kiện được phát: EVT-19-13, 14

  @US-19-041 @FR-19-041 @M @âm
  Kịch bản: US-19-041 âm 1 · Yêu cầu hoàn không thuộc tenant hoặc của đối tác khác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi yêu cầu hoàn không thuộc tenant hoặc của đối tác khác
    Thì hệ thống từ chối với ERR-19-020 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu, hoặc bạn không có quyền xem."

  # ---- EP-19-I · Đối soát và chênh lệch

  @US-19-042 @FR-19-042 @M
  Kịch bản: US-19-042 dương · Lập lịch và khởi tạo phiên đối soát
    Biết NCC `ACTIVE` hoặc `SUSPENDED`; ngày giao dịch trước hôm nay và không trước ngày kích hoạt NCC
    Khi tác vụ nền chạy lúc `19.recon.cutoff-time` (mặc định 06:00 giờ Việt Nam) hằng ngày; kế toán bấm "Tạo phiên thủ công" ở UI-19-19
    Thì phiên `SCHEDULED` với `run_no = 1`, `next_collect_at`
    Và phiên `SCHEDULED` với `run_no = 1` cho (NCC, ngày); phiên được chuyển ngay sang thu thập (FR-19-043)

  @US-19-042 @FR-19-042 @M @âm
  Kịch bản: US-19-042 âm 1 · Tạo phiên cho (NCC, ngày) đã có phiên
    Biết NCC `ACTIVE` hoặc `SUSPENDED`; ngày giao dịch trước hôm nay và không trước ngày kích hoạt NCC
    Khi tạo phiên cho (NCC, ngày) đã có phiên
    Thì hệ thống từ chối với ERR-19-040 (409)
    Và người dùng thấy thông báo "Đã có phiên đối soát cho {provider} ngày {date}."

  @US-19-043 @FR-19-043 @M
  Kịch bản: US-19-043 dương · Thu thập dữ liệu đối soát của nhà cung cấp
    Biết phiên ở `SCHEDULED`, `WAITING_DATA` hoặc `FAILED`; adapter của NCC khai `capabilities.reconSource`
    Khi FR-19-042 chuyển phiên sang thu thập; lịch thu lại mỗi 30 phút khi chưa có dữ liệu; thông báo dữ liệu sẵn sàng của NCC (API-19-204); kế toán bấm "Tải file đối soát" ở UI-19-20
    Thì tệp gốc lưu `dh-{tenant}-payment` (Garage) với `stored_file` mục đích `RECON_SOURCE`; tập dòng chuẩn hóa của NCC
    Và hợp lệ → `MATCHING`; NCC chưa có dữ liệu, tệp sai định dạng, sai mã băm, sai NCC, sai ngày → `WAITING_DATA` kèm lỗi; lỗi kỹ thuật 3 lần → `FAILED`

  @US-19-043 @FR-19-043 @M @âm
  Kịch bản: US-19-043 âm 1 · Tệp sai định dạng, sai mã băm, sai NCC, sai ngày
    Biết phiên ở `SCHEDULED`, `WAITING_DATA` hoặc `FAILED`; adapter của NCC khai `capabilities.reconSource`
    Khi tệp sai định dạng, sai mã băm, sai NCC, sai ngày
    Thì hệ thống từ chối với ERR-19-041
    Và người dùng thấy thông báo "File đối soát không hợp lệ: {reasonLabel}."

  @US-19-043 @FR-19-043 @M @âm
  Kịch bản: US-19-043 âm 2 · Phiên đã `CLOSED`
    Biết phiên ở `SCHEDULED`, `WAITING_DATA` hoặc `FAILED`; adapter của NCC khai `capabilities.reconSource`
    Khi phiên đã `CLOSED`
    Thì hệ thống từ chối với ERR-19-043 (409)
    Và người dùng thấy thông báo "Phiên đối soát đã chốt, không thể thay đổi."

  @US-19-044 @FR-19-044 @M
  Kịch bản: US-19-044 dương · So khớp tự động
    Biết phiên ở `MATCHING` với tập dòng chuẩn của NCC đã nạp
    Khi FR-19-043 chuyển phiên sang `MATCHING`; kế toán bấm "Chạy lại so khớp" ở UI-19-20 (API-19-066)
    Thì các dòng `reconciliation_item` của lần chạy; tổng số lượng và tổng tiền hai phía; chênh lệch mới; `recon_status` của giao dịch
    Và 0 dòng lệch → `READY_TO_CLOSE`; có dòng lệch → `IN_REVIEW`
    Và sự kiện được phát: EVT-19-15 khi so khớp xong; EVT-19-17 cho mỗi chênh lệch mới; EVT-19-18 cho chênh lệch tự khớp

  @US-19-044 @FR-19-044 @M @âm
  Kịch bản: US-19-044 âm 1 · Phiên đã `CLOSED`
    Biết phiên ở `MATCHING` với tập dòng chuẩn của NCC đã nạp
    Khi phiên đã `CLOSED`
    Thì hệ thống từ chối với ERR-19-043 (409)
    Và người dùng thấy thông báo "Phiên đối soát đã chốt, không thể thay đổi."

  @US-19-044 @FR-19-044 @M @âm
  Kịch bản: US-19-044 âm 2 · Tỷ lệ khớp tự động dưới 99,9% (KPI-94)
    Biết phiên ở `MATCHING` với tập dòng chuẩn của NCC đã nạp
    Khi tỷ lệ khớp tự động dưới 99,9% (KPI-94)
    Thì không phải lỗi API; phiên vẫn hoàn tất, hệ thống cảnh báo kế toán trưởng qua PH-13 và hiện tỷ lệ trên UI-19-20

  @US-19-045 @FR-19-045 @M
  Kịch bản: US-19-045 dương · Quản lý bản ghi chênh lệch
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kế toán mở UI-19-21 (danh sách chênh lệch) hoặc UI-19-22 (chi tiết), bấm "Nhận việc", "Giao việc", "Chuyển NCC", "NCC đã trả lời" hoặc "Thêm ghi chú"; tác vụ hằng ngày tính tuổi chênh lệch
    Thì danh sách lọc theo `type[]`, `status[]`, `providerId`, `businessDate` (khoảng), tuổi (ngày làm việc), `assigneeId`, `overdue` …
    Và chênh lệch ở trạng thái mới (`INVESTIGATING`, `ESCALATED`) hoặc giữ nguyên với ghi chú mới chỉ thêm; `assigneeId` cập nhật khi giao, nhận

  @US-19-045 @FR-19-045 @M @âm
  Kịch bản: US-19-045 âm 1 · Hành động không hợp lệ ở trạng thái hiện tại của chênh lệch (khung §7.7)
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi hành động không hợp lệ ở trạng thái hiện tại của chênh lệch (khung §7.7)
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-045 @FR-19-045 @M @âm
  Kịch bản: US-19-045 âm 2 · Chênh lệch thuộc phiên đã `CLOSED`
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi chênh lệch thuộc phiên đã `CLOSED`
    Thì hệ thống từ chối với ERR-19-043 (409)
    Và người dùng thấy thông báo "Phiên đối soát đã chốt, không thể thay đổi."

  @US-19-046 @FR-19-046 @M
  Kịch bản: US-19-046 dương · Đề xuất và phê duyệt xử lý chênh lệch
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kế toán bấm "Đề xuất xử lý" ở UI-19-22; người phê duyệt quyết định ở UI-19-13
    Thì đề xuất: `201` kèm `approval_request` loại `DISCREPANCY_RESOLUTION`, chênh lệch `PROPOSED`
    Và duyệt → hệ thống thực thi cách xử lý trong một giao dịch CSDL, chênh lệch `RESOLVED`; phiên `IN_REVIEW` → `READY_TO_CLOSE` khi chênh lệch cuối cùng đóng
    Và sự kiện được phát: EVT-19-18

  @US-19-046 @FR-19-046 @M @âm
  Kịch bản: US-19-046 âm 1 · Người duyệt trùng người lập, trùng người duyệt cấp trước, hoặc người xác nhận hoàn thủ công trùng người duyệt (mục 3.3)
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người duyệt trùng người lập, trùng người duyệt cấp trước, hoặc người xác nhận hoàn thủ công trùng người duyệt (mục 3.3)
    Thì hệ thống từ chối với ERR-19-033 (403)
    Và người dùng thấy thông báo "Bạn đã {role} đề nghị này nên không thể quyết định. Cần một người khác (tách nhiệm)."

  @US-19-046 @FR-19-046 @M @âm
  Kịch bản: US-19-046 âm 2 · `If-Match` không khớp `version` hiện tại
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi `If-Match` không khớp `version` hiện tại
    Thì hệ thống từ chối với ERR-19-045 (412)
    Và người dùng thấy thông báo "{actor} đã thay đổi dữ liệu này lúc {time}. Thay đổi của bạn chưa được lưu."

  @US-19-047 @FR-19-047 @M
  Kịch bản: US-19-047 dương · Chốt và mở lại phiên đối soát
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kế toán bấm "Chốt phiên" ở UI-19-20; kế toán bấm "Đề nghị mở lại" ở phiên đã chốt; người phê duyệt quyết định ở UI-19-13
    Thì chốt: phiên `CLOSED` kèm mã biên bản và mã băm
    Và chốt: phiên `CLOSED` bất biến, sinh biên bản (FR-19-048)
    Và sự kiện được phát: EVT-19-16 khi chốt

  @US-19-047 @FR-19-047 @M @âm
  Kịch bản: US-19-047 âm 1 · Chốt phiên khi còn chênh lệch chưa `RESOLVED`
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi chốt phiên khi còn chênh lệch chưa `RESOLVED`
    Thì hệ thống từ chối với ERR-19-042 (409)
    Và người dùng thấy thông báo "Còn {count} chênh lệch chưa xử lý."

  @US-19-047 @FR-19-047 @M @âm
  Kịch bản: US-19-047 âm 2 · Thay đổi dữ liệu của phiên `CLOSED`
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thay đổi dữ liệu của phiên `CLOSED`
    Thì hệ thống từ chối với ERR-19-043 (409)
    Và người dùng thấy thông báo "Phiên đối soát đã chốt, không thể thay đổi."

  @US-19-048 @FR-19-048 @S
  Kịch bản: US-19-048 dương · Xuất biên bản và cung cấp kết quả đối soát
    Biết phiên đối soát ở `CLOSED` (kết quả cho đối tác chỉ có sau khi phiên chốt)
    Khi FR-19-047 sinh biên bản khi chốt phiên; kế toán, kiểm toán viên bấm "Tải biên bản" ở UI-19-20; đối tác gọi API-19-107
    Thì biên bản PDF (theo thể thức NĐ 30/2020, có ô ký của bên lập, bên kiểm tra, đại diện đơn vị chủ trì đối soát theo OQ-19-18) và XLSX (chi tiết dòng); mã băm SHA-256 in trên biên bản; tệp lưu bucket WORM với `retention_until` theo NFR-19-014
    Và biên bản và tệp chi tiết nằm ở bucket WORM, không xóa được tới `retention_until`; phiên trỏ tới tệp biên bản
    Và sự kiện được phát: EVT-19-16 (phát khi chốt ở FR-19-047, mang `minutesFileSha256`)

  @US-19-048 @FR-19-048 @S @âm
  Kịch bản: US-19-048 âm 1 · Tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác) …
    Biết phiên đối soát ở `CLOSED` (kết quả cho đối tác chỉ có sau khi phiên chốt)
    Khi tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác); không phân biệt hai trường hợp để không lộ thông tin
    Thì hệ thống từ chối với ERR-19-020 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu, hoặc bạn không có quyền xem."

  # ---- EP-19-J · Tra cứu giao dịch

  @US-19-049 @FR-19-049 @M
  Kịch bản: US-19-049 dương · Danh sách giao dịch, tìm theo từ khóa
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở UI-19-14 và gõ từ khóa vào ô tìm kiếm
    Thì trang dữ liệu: mã giao dịch, mã đơn hàng, dịch vụ, lĩnh vực, đối tác, NCC, người nộp (đã che), số tiền, trạng thái, `recon_status`, thời điểm tạo, thời điểm thanh toán; tổng số dòng (chính xác tới 10.000, trên đó trả `totalApprox = true`)

  @US-19-049 @FR-19-049 @M @âm
  Kịch bản: US-19-049 âm 1 · Khoảng thời gian vượt 400 ngày
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi khoảng thời gian vượt 400 ngày
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-050 @FR-19-050 @M
  Kịch bản: US-19-050 dương · Tra cứu nâng cao
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở khối "Bộ lọc nâng cao" ở UI-19-14, chọn tiêu chí và bấm "Áp dụng"
    Thì trang kết quả như FR-19-049

  @US-19-050 @FR-19-050 @M @âm
  Kịch bản: US-19-050 âm 1 · Thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-051 @FR-19-051 @M
  Kịch bản: US-19-051 dương · Xem chi tiết giao dịch
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng bấm vào một dòng ở UI-19-14, mở đường dẫn tới UI-19-15, hoặc bấm "Hiện đầy đủ" ở khối người nộp
    Thì toàn bộ thuộc tính giao dịch; dòng thời gian trạng thái (`transaction_event`); các IPN (`callback_inbox`); các lần truy vấn NCC và trao đổi (`integration_log`); các lượt webhook; yêu cầu hoàn; chênh lệch; `trace_id`

  @US-19-051 @FR-19-051 @M @âm
  Kịch bản: US-19-051 âm 1 · Tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác) …
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác); không phân biệt hai trường hợp để không lộ thông tin
    Thì hệ thống từ chối với ERR-19-020 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu, hoặc bạn không có quyền xem."

  @US-19-052 @FR-19-052 @S
  Kịch bản: US-19-052 dương · Xuất danh sách giao dịch
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng bấm "Xuất" ở UI-19-14, chọn định dạng, cột và xác nhận
    Thì tác vụ nền `background_job` loại `TRANSACTION_EXPORT`, trạng thái `QUEUED` → `RUNNING` → `SUCCEEDED`/`FAILED`; tệp lưu bucket `dh-{tenant}-payment` với đường tải có hạn 24 giờ, chỉ người tạo tải được
    Và tác vụ nền ở trạng thái cuối; tệp tồn tại trong bucket và tự xóa sau 7 ngày

  @US-19-052 @FR-19-052 @S @âm
  Kịch bản: US-19-052 âm 1 · Người dùng đã có 3 tác vụ xuất đang chạy
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng đã có 3 tác vụ xuất đang chạy
    Thì hệ thống từ chối với ERR-19-048 (429)
    Và người dùng thấy thông báo "Bạn thao tác quá nhanh. Thử lại sau {retryAfter} giây."

  # ---- EP-19-K · Nhật ký và kiểm toán

  @US-19-053 @FR-19-053 @M
  Kịch bản: US-19-053 dương · Ghi nhật ký kiểm toán
    Biết thao tác nghiệp vụ đang chạy trong một giao dịch CSDL
    Khi mọi FR ghi dữ liệu, quyết định phê duyệt, xem dữ liệu cá nhân bỏ che, xem nguyên văn IPN, tải tệp xuất; cả thao tác bị từ chối quyền
    Thì bản ghi kiểm toán gửi PH-13 qua sự kiện `audit.recorded.v1` (định dạng chung của D03-07)
    Và mỗi thao tác cần kiểm toán có đúng một bản ghi trong outbox cùng giao dịch CSDL; PH-13 lưu online 12 tháng, WORM 5 năm
    Và sự kiện được phát: `audit.recorded.v1` tới PH-13 (không phải EVT-19)

  @US-19-053 @FR-19-053 @M @âm
  Kịch bản: US-19-053 âm 1 · Không ghi được bản ghi kiểm toán vào outbox
    Biết thao tác nghiệp vụ đang chạy trong một giao dịch CSDL
    Khi không ghi được bản ghi kiểm toán vào outbox
    Thì hệ thống từ chối với ERR-19-050 (503)
    Và người dùng thấy thông báo "Không ghi được nhật ký kiểm toán nên thao tác đã bị hủy. Thử lại sau ít phút."

  @US-19-053 @FR-19-053 @M @âm
  Kịch bản: US-19-053 âm 2 · PH-13 không nhận bản ghi
    Biết thao tác nghiệp vụ đang chạy trong một giao dịch CSDL
    Khi PH-13 không nhận bản ghi
    Thì không phải lỗi API; bản ghi nằm lại outbox và được chuyển khi PH-13 phục hồi, PH-13 cảnh báo độ trễ outbox cho người vận hành

  @US-19-054 @FR-19-054 @M
  Kịch bản: US-19-054 dương · Nhật ký tích hợp giao dịch
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở UI-19-23, chọn bộ lọc; mọi lời gọi vào, ra của PH-19 ghi một dòng nhật ký
    Thì danh sách và chi tiết: thời điểm, hướng, thao tác, đối tượng, mã kết quả, độ trễ, kích thước, nội dung yêu cầu và phản hồi đã che (tối đa 64 KB mỗi phía, phần thừa cắt kèm dấu cắt)
    Và xem: không thay đổi dữ liệu

  @US-19-054 @FR-19-054 @M @âm
  Kịch bản: US-19-054 âm 1 · Khoảng thời gian vượt 31 ngày
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi khoảng thời gian vượt 31 ngày
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-055 @FR-19-055 @S
  Kịch bản: US-19-055 dương · Liên kết truy vết đầu-cuối
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi mỗi yêu cầu vào PH-19 qua APISIX; người dùng bấm "Mở vết" ở UI-19-15 hoặc UI-19-23
    Thì hệ thống trả `trace_id` trên giao dịch, `transaction_event`, `callback_inbox`, `integration_log`, `webhook_delivery`, `outbox_event`; liên kết sang màn vết của PH-13
    Và mọi bản ghi liên quan tới giao dịch mang cùng `trace_id`

  @US-19-055 @FR-19-055 @S @âm
  Kịch bản: US-19-055 âm 1 · NCC không chấp nhận header truy vết
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi NCC không chấp nhận header truy vết
    Thì không phải lỗi; `trace_id` vẫn lưu ở phía PH-19 và nhật ký tích hợp, vết dừng ở ranh giới gọi ra

  # ---- EP-19-L · Dashboard, báo cáo, chỉ số

  @US-19-056 @FR-19-056 @M
  Kịch bản: US-19-056 dương · Dashboard tổng quan
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở trang đầu của phân hệ Thanh toán (UI-19-01); trang tự làm mới mỗi 60 giây khi tab đang mở
    Thì thẻ chỉ số, biểu đồ và bảng, chi tiết theo bảng ở FR gốc

  @US-19-056 @FR-19-056 @M @âm
  Kịch bản: US-19-056 âm 1 · Bảng tổng hợp chậm cập nhật quá 60 giây
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi bảng tổng hợp chậm cập nhật quá 60 giây
    Thì không phải lỗi API; số liệu vẫn hiện kèm nhãn thông báo để người xem biết độ trễ, PH-13 cảnh báo khi backlog outbox vượt ngưỡng
    Và người dùng thấy thông báo "cập nhật lúc hh:mm:ss"

  @US-19-057 @FR-19-057 @M
  Kịch bản: US-19-057 dương · Dashboard kênh thanh toán
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở UI-19-02 từ menu Thanh toán
    Thì một thẻ cho mỗi NCC: tên, ngày hiệu lực, đầu mối, trạng thái vòng đời, số dịch vụ, biểu đồ số giao dịch theo ngày trong 30 ngày (của hệ cũ) …

  @US-19-057 @FR-19-057 @M @âm
  Kịch bản: US-19-057 âm 1 · Không có NCC nào trong tenant
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi không có NCC nào trong tenant
    Thì HTTP 200; trang hiện trạng thái rỗng kèm nút thông báo cho người có quyền
    Và người dùng thấy thông báo "Thêm nhà cung cấp"

  @US-19-058 @FR-19-058 @S
  Kịch bản: US-19-058 dương · Báo cáo định kỳ và xuất
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng mở UI-19-25, chọn mẫu báo cáo, kỳ và bộ lọc, bấm "Xem" hoặc "Xuất"
    Thì số liệu báo cáo theo mẫu; tệp XLSX hoặc PDF có quốc hiệu, tên đơn vị, kỳ báo cáo, người lập, ngày lập
    Và xem: không thay đổi dữ liệu

  @US-19-058 @FR-19-058 @S @âm
  Kịch bản: US-19-058 âm 1 · Kết quả vượt giới hạn xuất
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kết quả vượt giới hạn xuất
    Thì hệ thống từ chối với ERR-19-047 (422)
    Và người dùng thấy thông báo "Kết quả có {count} dòng, vượt giới hạn xuất {max}. Thu hẹp bộ lọc."

  @US-19-059 @FR-19-059 @M
  Kịch bản: US-19-059 dương · Phát chỉ số vận hành và cảnh báo
    Biết phân hệ đã bật cho tenant; PH-13 sẵn sàng nhận chỉ số
    Khi mọi FR cập nhật chỉ số khi xử lý; FR-19-064 nạp luật cảnh báo vào PH-13 khi bật phân hệ cho tenant
    Thì chuỗi chỉ số với nhãn không chứa mã giao dịch hay dữ liệu cá nhân; cảnh báo ở PH-13

  @US-19-059 @FR-19-059 @M @âm
  Kịch bản: US-19-059 âm 1 · PH-13 không thu được chỉ số
    Biết phân hệ đã bật cho tenant; PH-13 sẵn sàng nhận chỉ số
    Khi PH-13 không thu được chỉ số
    Thì không phải lỗi API; PH-19 vẫn chạy bình thường, cảnh báo thông báo của chính PH-13 báo người vận hành
    Và người dùng thấy thông báo "mất chỉ số"

  # ---- EP-19-M · Thông báo và sự kiện

  @US-19-060 @FR-19-060 @M
  Kịch bản: US-19-060 dương · Gửi webhook kết quả có ký
    Biết đối tác có đầu nhận webhook `ACTIVE` đăng ký loại sự kiện tương ứng; bí mật ký có ở OpenBao
    Khi bản ghi mới trong `outbox_event` thuộc loại sự kiện mà đầu nhận của đối tác đăng ký; lịch thử lại `next_attempt_at`
    Thì hệ thống trả `webhook_delivery` cho mỗi (sự kiện, địa chỉ webhook đăng ký loại sự kiện đó)
    Và mỗi (sự kiện, đầu nhận) có một `webhook_delivery` ở `DELIVERED`, `RETRY_SCHEDULED`, `EXHAUSTED` hoặc `CANCELLED`

  @US-19-060 @FR-19-060 @M @âm
  Kịch bản: US-19-060 âm 1 · Đối tác trả mã khác 2xx hoặc quá thời gian chờ
    Biết đối tác có đầu nhận webhook `ACTIVE` đăng ký loại sự kiện tương ứng; bí mật ký có ở OpenBao
    Khi đối tác trả mã khác 2xx hoặc quá thời gian chờ
    Thì không phải lỗi API; lượt gửi `RETRY_SCHEDULED`, hết lịch thì `EXHAUSTED` và PH-13 cảnh báo người phụ trách đối tác, hiện ở UI-19-24

  @US-19-060 @FR-19-060 @M @âm
  Kịch bản: US-19-060 âm 2 · Địa chỉ phân giải tới địa chỉ nội bộ tại thời điểm gửi
    Biết đối tác có đầu nhận webhook `ACTIVE` đăng ký loại sự kiện tương ứng; bí mật ký có ở OpenBao
    Khi địa chỉ phân giải tới địa chỉ nội bộ tại thời điểm gửi
    Thì hệ thống từ chối với ERR-19-044
    Và người dùng thấy thông báo "Địa chỉ webhook phải dùng https và không trỏ tới mạng nội bộ."

  @US-19-061 @FR-19-061 @M
  Kịch bản: US-19-061 dương · Phát sự kiện qua outbox
    Biết thay đổi trạng thái được ghi trong một giao dịch CSDL của `pg-payment`
    Khi mọi thay đổi trạng thái của các thực thể có sự kiện EVT-19-01…18
    Thì sự kiện CloudEvents trên topic `{tenant}.payment.{entity}.{event}.v1` với khóa phân vùng theo khung §10.4
    Và bản ghi outbox đã phát được đánh dấu và xóa sau 7 ngày
    Và sự kiện được phát: EVT-19-01…18

  @US-19-061 @FR-19-061 @M @âm
  Kịch bản: US-19-061 âm 1 · Kafka không sẵn sàng
    Biết thay đổi trạng thái được ghi trong một giao dịch CSDL của `pg-payment`
    Khi Kafka không sẵn sàng
    Thì không phải lỗi API; sự kiện nằm lại outbox và được phát khi Kafka phục hồi (NFR-19-013), PH-13 cảnh báo khi `payment_outbox_backlog` vượt 1.000 trong 5 phút

  @US-19-061 @FR-19-061 @M @âm
  Kịch bản: US-19-061 âm 2 · Lược đồ sự kiện không tương thích `BACKWARD` ở Apicurio
    Biết thay đổi trạng thái được ghi trong một giao dịch CSDL của `pg-payment`
    Khi lược đồ sự kiện không tương thích `BACKWARD` ở Apicurio
    Thì không phải lỗi API; bộ phát từ chối phát, ghi lỗi và cảnh báo đội vận hành, sự kiện giữ trong outbox

  @US-19-062 @FR-19-062 @S
  Kịch bản: US-19-062 dương · Theo dõi và gửi lại webhook
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi cán bộ mở UI-19-24, lọc và bấm "Gửi lại" cho một hoặc nhiều lượt; đối tác gọi API-19-109
    Thì danh sách; chi tiết từng lần thử (thời điểm, mã HTTP, độ trễ, 2 KB đầu của phản hồi, lỗi mạng)
    Và lượt gửi lại chuyển `EXHAUSTED` → `PENDING`, số thứ tự lần thử tiếp tục tăng, chữ ký tính lại theo thời điểm gửi

  @US-19-062 @FR-19-062 @S @âm
  Kịch bản: US-19-062 âm 1 · Thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  # ---- EP-19-N · Cấu hình tenant

  @US-19-063 @FR-19-063 @M
  Kịch bản: US-19-063 dương · Cấu hình thanh toán của tenant
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán mở UI-19-26, sửa giá trị, chọn ngày hiệu lực và bấm "Lưu phiên bản mới"
    Thì phiên bản cấu hình mới (số phiên bản tăng dần), phiên bản đang hiệu lực, lịch sử
    Và một `tenant_payment_config` phiên bản mới; phiên bản đã có hiệu lực không đổi

  @US-19-063 @FR-19-063 @M @âm
  Kịch bản: US-19-063 âm 1 · Thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài
    Thì hệ thống từ chối với ERR-19-001 (400)
    Và người dùng thấy thông báo "Thông tin nhập chưa hợp lệ. Kiểm tra các ô được đánh dấu."

  @US-19-064 @FR-19-064 @M
  Kịch bản: US-19-064 dương · Khởi tạo và tạm ngừng phân hệ theo tenant
    Biết tenant tồn tại ở PH-20; với bật lần đầu: chưa có `tenant_payment_config`
    Khi PH-20 phát sự kiện `tenant.module-enabled.v1` hoặc `tenant.module-disabled.v1` khi quản trị tenant bật, tắt gói phân hệ
    Thì hệ thống trả `tenant_payment_config` với `module_enabled` và `provisioning_state`; tài nguyên hạ tầng của tenant
    Và bật: tenant có đủ tài nguyên của PH-19 và cấu hình mặc định

  @US-19-064 @FR-19-064 @M @âm
  Kịch bản: US-19-064 âm 1 · Tạo một tài nguyên hạ tầng thất bại (Strimzi, Ceph, OpenBao, APISIX)
    Biết tenant tồn tại ở PH-20; với bật lần đầu: chưa có `tenant_payment_config`
    Khi tạo một tài nguyên hạ tầng thất bại (Strimzi, Ceph, OpenBao, APISIX)
    Thì không phải lỗi API; `provisioning_state` ghi bước lỗi, hệ thống thử lại và PH-13 cảnh báo quản trị nền tảng; phân hệ chưa bật cho tới khi đủ

  @US-19-064 @FR-19-064 @M @âm
  Kịch bản: US-19-064 âm 2 · Gọi API ghi tạo mới khi phân hệ đã tắt
    Biết tenant tồn tại ở PH-20; với bật lần đầu: chưa có `tenant_payment_config`
    Khi gọi API ghi tạo mới khi phân hệ đã tắt
    Thì hệ thống từ chối với ERR-19-049 (503)
    Và người dùng thấy thông báo "Phân hệ thanh toán đang tạm ngừng cho tỉnh."

  # ---- EP-19-O · Di trú và chạy song song

  @US-19-065 @FR-19-065 @M
  Kịch bản: US-19-065 dương · Nhập danh mục và giao dịch lịch sử từ hệ cũ
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán tạo lần chạy di trú ở UI-19-27 và bấm "Chạy thử" hoặc "Chạy thật"
    Thì tác vụ nền `background_job` loại `MIGRATION_IMPORT` (hoặc `MIGRATION_COMPARE` ở FR-19-068) với số dòng đọc, nhập mới, cập nhật, bỏ qua, lỗi; tệp báo cáo dòng lỗi (CSV)
    Và chạy thật: bản ghi mới có `is_migrated = true` và `legacy_mapping` tương ứng; giao dịch nhập không phát sự kiện, không gửi webhook, không tính hạn mức; dữ liệu người nộp đã mã hóa

  @US-19-065 @FR-19-065 @M @âm
  Kịch bản: US-19-065 âm 1 · Một dòng nguồn không chuyển đổi được (số tiền vượt kiểu, ngày sai định dạng, thiếu khóa)
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi một dòng nguồn không chuyển đổi được (số tiền vượt kiểu, ngày sai định dạng, thiếu khóa)
    Thì không phải lỗi API; dòng được ghi vào báo cáo dòng lỗi CSV, lô vẫn chạy tiếp; người dùng tải báo cáo ở UI-19-27 (API-19-088)

  @US-19-065 @FR-19-065 @M @âm
  Kịch bản: US-19-065 âm 2 · Kết nối nguồn chỉ đọc không mở được
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi kết nối nguồn chỉ đọc không mở được
    Thì không phải lỗi API; tác vụ `FAILED` kèm lý do hiện ở UI-19-27, PH-13 cảnh báo đội di trú

  @US-19-066 @FR-19-066 @M
  Kịch bản: US-19-066 dương · Chuyển chế độ định tuyến theo đối tác
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi quản trị thanh toán bấm "Đề nghị đổi chế độ" ở UI-19-12 hoặc UI-19-27; người phê duyệt quyết định ở UI-19-13
    Thì hệ thống trả `201` kèm đề nghị; sau duyệt: đối tác với `routingMode` mới
    Và sau duyệt: `payment_partner.routing_mode` đổi; EVT-19-04 phát để PH-03 cập nhật tuyến APISIX trong ≤ 60 giây
    Và sự kiện được phát: EVT-19-04

  @US-19-066 @FR-19-066 @M @âm
  Kịch bản: US-19-066 âm 1 · Sang `DATAHUB` khi lần đối chiếu gần nhất trong 7 ngày chưa đạt hoặc chưa đủ 7 ngày bóng
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi sang `DATAHUB` khi lần đối chiếu gần nhất trong 7 ngày chưa đạt hoặc chưa đủ 7 ngày bóng
    Thì hệ thống từ chối với ERR-19-035 (422)
    Và người dùng thấy thông báo "Checklist kích hoạt chưa đạt: {items}."

  @US-19-066 @FR-19-066 @M @âm
  Kịch bản: US-19-066 âm 2 · Thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi thao tác không được máy trạng thái (khung §7) cho phép ở trạng thái hiện tại
    Thì hệ thống từ chối với ERR-19-021 (409)
    Và người dùng thấy thông báo "{object} đang ở trạng thái"

  @US-19-067 @FR-19-067 @C
  Kịch bản: US-19-067 dương · Lớp tương thích API hệ cũ
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi HTTT đối tác gọi đường dẫn theo hợp đồng API hệ cũ (API-19-110)
    Thì phản hồi theo định dạng hệ cũ kèm `Deprecation`, `Sunset`
    Và như FR-19-022, 035 tương ứng
    Và sự kiện được phát: Như FR-19-022 (EVT-19-05…08)

  @US-19-067 @FR-19-067 @C @âm
  Kịch bản: US-19-067 âm 1 · Lỗi nghiệp vụ của API mới (ERR-19-001…019)
    Biết client của đối tác hợp lệ tại PH-12 và mang quyền nêu trên; đối tác `ACTIVE`; phân hệ đã bật cho tenant (FR-19-064)
    Khi lỗi nghiệp vụ của API mới (ERR-19-001…019)
    Thì hệ thống từ chối với ERR-19-001

  @US-19-068 @FR-19-068 @M
  Kịch bản: US-19-068 dương · Đối chiếu sau di trú
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi người dùng tạo lần đối chiếu ở UI-19-27 và bấm "Bắt đầu"
    Thì bảng so sánh theo tháng và theo đối tác: số lượng, tổng tiền, phân bố trạng thái hai bên; danh sách từng bản ghi lệch (CSV); kết luận `PASSED`/`FAILED` theo ngưỡng của BR-19-034
    Và tác vụ `MIGRATION_COMPARE` ở trạng thái cuối với kết luận `PASSED` hoặc `FAILED`; tệp danh sách lệch lưu bucket

  @US-19-068 @FR-19-068 @M @âm
  Kịch bản: US-19-068 âm 1 · Nguồn hệ cũ không đọc được
    Biết người dùng đã đăng nhập, chọn tenant làm việc và có quyền nêu ở mục Tác nhân, quyền; phân hệ đã bật cho tenant (FR-19-064)
    Khi nguồn hệ cũ không đọc được
    Thì không phải lỗi API; tác vụ `FAILED` kèm lý do ở UI-19-27, PH-13 cảnh báo đội di trú
