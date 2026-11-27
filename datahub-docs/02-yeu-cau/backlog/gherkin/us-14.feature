# language: vi
# Sinh tự động từ D02-02/D02-03-PH14 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-14
Tính năng: PH-14 · Kết nối quốc gia

  # ---- EP-14-A · Nền tảng và danh mục dịch vụ quốc gia

  @US-14-001 @FR-14-001 @M
  Kịch bản: US-14-001 dương · Liệt kê nền tảng quốc gia, trạng thái và mức sức khỏe
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở UI-14-02, hoặc bấm một thẻ tổng ở đầu trang để lọc nhanh
    Thì hệ thống trả `200`; `items[]` (`platformCode`, `name`, `type`, `scope`, `state`, `specStatus`, `health`, `quotaMaxRatio`, `certDaysRemaining`, `updatedAt`), `page`, `size`, `totalElements`, `facets`

  @US-14-001 @FR-14-001 @M @âm
  Kịch bản: US-14-001 âm 1 · `size` lớn hơn 100
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi `size` lớn hơn 100
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Số dòng mỗi trang tối đa 100."

  @US-14-001 @FR-14-001 @M @âm
  Kịch bản: US-14-001 âm 2 · Chưa chọn tenant
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi chưa chọn tenant
    Thì lỗi chung FR-00-004; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Hãy chọn tỉnh làm việc ở thanh trên."

  @US-14-002 @FR-14-002 @M
  Kịch bản: US-14-002 dương · Khai báo nền tảng quốc gia và gắn kết nối PH-05
    Biết kết nối loại `oauth2-client`, `mtls-client` hoặc `http` đã được tạo ở PH-05 (FR-05-004) và các môi trường cần dùng đã có giá trị; địa chỉ đích nằm trong danh sách egress của tenant (BR-05-013 của PH-05)
    Khi người dùng bấm "+ Khai báo nền tảng" ở UI-14-02 và đi qua trình hướng dẫn UI-14-03
    Thì hệ thống trả `201`, chi tiết nền tảng; tiêu đề `Location`, `ETag`
    Và nền tảng ở `DRAFT`, chưa nhận lưu lượng
    Và sự kiện được phát: EVT-14-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-002 @FR-14-002 @M @âm
  Kịch bản: US-14-002 âm 1 · Mã đã dùng
    Biết kết nối loại `oauth2-client`, `mtls-client` hoặc `http` đã được tạo ở PH-05 (FR-05-004) và các môi trường cần dùng đã có giá trị; địa chỉ đích nằm trong danh sách egress của tenant (BR-05-013 của PH-05)
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-14-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng (kể cả nền tảng đã ngừng dùng). Chọn mã khác."

  @US-14-002 @FR-14-002 @M @âm
  Kịch bản: US-14-002 âm 2 · Kết nối không tồn tại hoặc không đúng loại
    Biết kết nối loại `oauth2-client`, `mtls-client` hoặc `http` đã được tạo ở PH-05 (FR-05-004) và các môi trường cần dùng đã có giá trị; địa chỉ đích nằm trong danh sách egress của tenant (BR-05-013 của PH-05)
    Khi kết nối không tồn tại hoặc không đúng loại
    Thì hệ thống từ chối với ERR-14-005 (422)
    Và người dùng thấy thông báo "Kết nối {mã} không tồn tại hoặc loại không phù hợp với cách xác thực đã chọn."

  @US-14-003 @FR-14-003 @M
  Kịch bản: US-14-003 dương · Bật, tạm ngừng, tiếp tục và ngừng dùng nền tảng
    Biết bật: nền tảng ở `TESTED`, kiểm tra kết nối đạt trong 24 giờ trên đúng phiên bản kết nối; nếu có dịch vụ yêu cầu ký thì có chứng thư `ACTIVE` đúng mục đích
    Khi người dùng bấm "Gửi duyệt bật", "Duyệt", "Tạm ngừng", "Tiếp tục" hoặc "Ngừng dùng" ở UI-14-02, UI-14-03 hoặc duyệt trong "Việc của tôi" (UI-14-17)
    Thì hệ thống trả `200` hoặc `202` (khi chờ duyệt); `state`, `pendingApprovalId`, `ETag` mới
    Và trạng thái nền tảng đúng máy trạng thái ở mục 4.3; dịch vụ của nền tảng bị `SUSPENDED` từ chối lượt mới (ERR-14-117)
    Và sự kiện được phát: EVT-14-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-003 @FR-14-003 @M @âm
  Kịch bản: US-14-003 âm 1 · Người duyệt trùng người đề nghị
    Biết bật: nền tảng ở `TESTED`, kiểm tra kết nối đạt trong 24 giờ trên đúng phiên bản kết nối; nếu có dịch vụ yêu cầu ký thì có chứng thư `ACTIVE` đúng mục đích
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-14-007 (403)
    Và người dùng thấy thông báo "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."

  @US-14-003 @FR-14-003 @M @âm
  Kịch bản: US-14-003 âm 2 · Chưa kiểm tra kết nối trong 24 giờ
    Biết bật: nền tảng ở `TESTED`, kiểm tra kết nối đạt trong 24 giờ trên đúng phiên bản kết nối; nếu có dịch vụ yêu cầu ký thì có chứng thư `ACTIVE` đúng mục đích
    Khi chưa kiểm tra kết nối trong 24 giờ
    Thì hệ thống từ chối với ERR-14-008 (422)
    Và người dùng thấy thông báo "Hãy chạy kiểm tra kết nối đạt trong 24 giờ gần đây trước khi gửi duyệt."

  @US-14-004 @FR-14-004 @M
  Kịch bản: US-14-004 dương · Liệt kê và tìm dịch vụ quốc gia
    Biết người dùng đã chọn tenant
    Khi người dùng mở UI-14-04 hoặc đổi bộ lọc
    Thì hệ thống trả `200`; `items[]` (`serviceCode`, `nationalServiceCode`, `name`, `group`, `platformCode`, `state`, `label`, `priority`, `sensitivity`, `exposed`, `calls24h`, `errorRatio24h`), `page`, `size`, `totalElements`, `facets`

  @US-14-004 @FR-14-004 @M @âm
  Kịch bản: US-14-004 âm 1 · Giá trị lọc ngoài miền
    Biết người dùng đã chọn tenant
    Khi giá trị lọc ngoài miền
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Giá trị lọc không hợp lệ: {tên trường}."

  @US-14-005 @FR-14-005 @M
  Kịch bản: US-14-005 dương · Khai báo và sửa dịch vụ quốc gia
    Biết nền tảng đích tồn tại và không `RETIRED`
    Khi người dùng bấm "+ Khai báo dịch vụ" ở UI-14-04, hoặc "Sửa" ở UI-14-05; hoặc chấp nhận một đề xuất từ đối chiếu danh mục (FR-14-007)
    Thì hệ thống trả `201` khi tạo, `200` khi sửa; chi tiết dịch vụ; `Location`, `ETag`
    Và dịch vụ ở `DRAFT` (khi tạo) hoặc giữ trạng thái cũ (khi sửa); cấu hình nạp nóng
    Và sự kiện được phát: EVT-14-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-005 @FR-14-005 @M @âm
  Kịch bản: US-14-005 âm 1 · Mã đã dùng
    Biết nền tảng đích tồn tại và không `RETIRED`
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-14-002 (409)
    Và người dùng thấy thông báo "Mã dịch vụ {mã} đã được dùng (kể cả dịch vụ đã ngừng). Chọn mã khác."

  @US-14-005 @FR-14-005 @M @âm
  Kịch bản: US-14-005 âm 2 · Cấu hình tự mâu thuẫn
    Biết nền tảng đích tồn tại và không `RETIRED`
    Khi cấu hình tự mâu thuẫn
    Thì hệ thống từ chối với ERR-14-038 (422)
    Và người dùng thấy thông báo "Dịch vụ mức Nhạy cảm hoặc dịch vụ ghi không được bật đệm."

  @US-14-006 @FR-14-006 @M
  Kịch bản: US-14-006 dương · Xem chi tiết dịch vụ, hợp đồng và nhãn đối chiếu
    Biết dịch vụ tồn tại trong tenant hoặc là dịch vụ `COMMON`
    Khi người dùng bấm một dịch vụ ở UI-14-04 hoặc theo liên kết từ giao dịch, cảnh báo
    Thì hệ thống trả `200`; chi tiết dịch vụ, `specs[]`, `label`, `labelAt`, `metrics`, `exposure`, `ETag`

  @US-14-006 @FR-14-006 @M @âm
  Kịch bản: US-14-006 âm 1 · Dịch vụ không tồn tại hoặc thuộc tenant khác
    Biết dịch vụ tồn tại trong tenant hoặc là dịch vụ `COMMON`
    Khi dịch vụ không tồn tại hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-14-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy dịch vụ {mã}."

  @US-14-007 @FR-14-007 @M
  Kịch bản: US-14-007 dương · Đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP
    Biết có nguồn danh mục hiện hành: tệp (JSON, CSV, XLSX) từ trung ương, hoặc nền tảng hỗ trợ thao tác liệt kê dịch vụ
    Khi người dùng bấm "Đối chiếu danh mục" ở UI-14-06 và chọn nguồn
    Thì hệ thống trả `201` phiên đối chiếu; sau đó `200` với `proposals[]` (`nationalServiceCode`, `current`, `proposed`, `reason`) và `summary` (số Còn, Đổi đặc tả, Ngừng, thêm mới)
    Và nhãn đối chiếu của dịch vụ được cập nhật theo lựa chọn; phiên được lưu 3 năm
    Và sự kiện được phát: EVT-14-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-007 @FR-14-007 @M @âm
  Kịch bản: US-14-007 âm 1 · Tệp không đọc được hoặc thiếu cột bắt buộc
    Biết có nguồn danh mục hiện hành: tệp (JSON, CSV, XLSX) từ trung ương, hoặc nền tảng hỗ trợ thao tác liệt kê dịch vụ
    Khi tệp không đọc được hoặc thiếu cột bắt buộc
    Thì hệ thống từ chối với ERR-14-032 (422)
    Và người dùng thấy thông báo "Dòng {n}, cột {tên}: {lý do}. Tệp chưa được áp dụng."

  @US-14-007 @FR-14-007 @M @âm
  Kịch bản: US-14-007 âm 2 · Đã có phiên đối chiếu đang chạy cho nền tảng
    Biết có nguồn danh mục hiện hành: tệp (JSON, CSV, XLSX) từ trung ương, hoặc nền tảng hỗ trợ thao tác liệt kê dịch vụ
    Khi đã có phiên đối chiếu đang chạy cho nền tảng
    Thì hệ thống từ chối với ERR-14-026 (409)
    Và người dùng thấy thông báo "Đang có phiên đối chiếu cho nền tảng này. Chờ phiên đó xong."

  @US-14-008 @FR-14-008 @M
  Kịch bản: US-14-008 dương · Nạp đặc tả dịch vụ có phiên bản và phát hiện lệch
    Biết dịch vụ tồn tại ở `DRAFT`, `ACTIVE` hoặc `DEPRECATED`
    Khi người dùng bấm "Nạp đặc tả" ở UI-14-05; hoặc bộ chạy kiểm tra lấy `specUrl` mỗi 24 giờ
    Thì hệ thống trả `201`; phiên bản đặc tả, `diff`, `breaking`, `state`
    Và có đúng một phiên bản `ACTIVE` cho mỗi dịch vụ đã kích hoạt; phiên bản đã `ACTIVE` bất biến
    Và sự kiện được phát: EVT-14-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-008 @FR-14-008 @M @âm
  Kịch bản: US-14-008 âm 1 · Tệp không phải đặc tả hợp lệ hoặc vượt giới hạn
    Biết dịch vụ tồn tại ở `DRAFT`, `ACTIVE` hoặc `DEPRECATED`
    Khi tệp không phải đặc tả hợp lệ hoặc vượt giới hạn
    Thì hệ thống từ chối với ERR-14-011 (422)
    Và người dùng thấy thông báo "Tệp đặc tả không đọc được: {lý do}."

  @US-14-008 @FR-14-008 @M @âm
  Kịch bản: US-14-008 âm 2 · Trùng số phiên bản khác nội dung
    Biết dịch vụ tồn tại ở `DRAFT`, `ACTIVE` hoặc `DEPRECATED`
    Khi trùng số phiên bản khác nội dung
    Thì hệ thống từ chối với ERR-14-010 (409)
    Và người dùng thấy thông báo "Phiên bản {số} đã tồn tại với nội dung khác. Dùng số phiên bản mới."

  @US-14-009 @FR-14-009 @M
  Kịch bản: US-14-009 dương · Cung cấp lại dịch vụ quốc gia cho HTTT của tỉnh
    Biết dịch vụ `ACTIVE` với đặc tả `ACTIVE`; chưa có cung cấp lại cho dịch vụ này ở tenant
    Khi người dùng bấm "Cung cấp lại cho HTTT" ở tab "Cung cấp lại" của UI-14-05
    Thì hệ thống trả `201`; `exposure` (`apiCode`, `path`, `contractVersion`, `state = PENDING_PUBLISH`)
    Và mỗi dịch vụ có tối đa một cung cấp lại ở mỗi tenant; trường trả về bị giới hạn theo hợp đồng
    Và sự kiện được phát: EVT-14-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-009 @FR-14-009 @M @âm
  Kịch bản: US-14-009 âm 1 · Dịch vụ chưa sẵn sàng hoặc đường dẫn xung đột
    Biết dịch vụ `ACTIVE` với đặc tả `ACTIVE`; chưa có cung cấp lại cho dịch vụ này ở tenant
    Khi dịch vụ chưa sẵn sàng hoặc đường dẫn xung đột
    Thì hệ thống từ chối với ERR-14-025 (422)
    Và người dùng thấy thông báo "Dịch vụ {mã} chưa đủ điều kiện cung cấp lại: {lý do}."

  @US-14-009 @FR-14-009 @M @âm
  Kịch bản: US-14-009 âm 2 · PH-02 không khả dụng
    Biết dịch vụ `ACTIVE` với đặc tả `ACTIVE`; chưa có cung cấp lại cho dịch vụ này ở tenant
    Khi PH-02 không khả dụng
    Thì hệ thống từ chối với ERR-14-027 (502)
    Và người dùng thấy thông báo "Danh mục dịch vụ chưa phản hồi. Thử lại sau ít phút."

  # ---- EP-14-B · Gọi dịch vụ và định tuyến

  @US-14-010 @FR-14-010 @M
  Kịch bản: US-14-010 dương · Gọi dịch vụ quốc gia qua điểm gọi chung
    Biết HTTT đã đăng ký sử dụng API quốc gia ở PH-02 và được duyệt (FR-14-009); dịch vụ và nền tảng `ACTIVE`; token Datahub còn hạn
    Khi HTTT gọi API-14-075 (hoặc API cung cấp lại tương ứng) qua APISIX; luồng PH-04 gọi Kamelet `dh-national-invoke`
    Thì hệ thống trả `200`; `transactionCode`, `platformCode`, `data`, `meta` (`fromCache`, `cacheAgeSeconds`, `stale`, `signatureVerified`, `dataTime`, `durationMs`); tiêu đề `X-DH-Transaction`, `X-DH-Cache` (`HIT`, `MISS`, `STALE`)
    Và có một giao dịch ở trạng thái cuối; hạn mức đã trừ nếu gọi thật; đệm đã cập nhật nếu được phép
    Và sự kiện được phát: EVT-14-11 (siêu dữ liệu giao dịch, không nội dung); EVT-14-07 khi chạm ngưỡng hạn mức; EVT-14-06 khi chữ ký sai
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-010 @FR-14-010 @M @âm
  Kịch bản: US-14-010 âm 1 · Hết hạn mức
    Biết HTTT đã đăng ký sử dụng API quốc gia ở PH-02 và được duyệt (FR-14-009); dịch vụ và nền tảng `ACTIVE`; token Datahub còn hạn
    Khi hết hạn mức
    Thì hệ thống từ chối với ERR-14-104 (429)
    Và người dùng thấy thông báo "Đã dùng hết hạn mức truy vấn {dịch vụ}. Bộ đếm đặt lại lúc {thời điểm}."

  @US-14-010 @FR-14-010 @M @âm
  Kịch bản: US-14-010 âm 2 · Nền tảng không phản hồi, đang ngắt mạch, không có đệm
    Biết HTTT đã đăng ký sử dụng API quốc gia ở PH-02 và được duyệt (FR-14-009); dịch vụ và nền tảng `ACTIVE`; token Datahub còn hạn
    Khi nền tảng không phản hồi, đang ngắt mạch, không có đệm
    Thì hệ thống từ chối với ERR-14-103 (503)
    Và người dùng thấy thông báo "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút."

  @US-14-011 @FR-14-011 @M
  Kịch bản: US-14-011 dương · Kiểm tra mục đích khai thác và ủy quyền theo mục đích
    Biết HTTT có đăng ký sử dụng dịch vụ còn hiệu lực ở PH-02; danh mục mục đích khai thác và danh mục thủ tục hành chính có mặt ở PH-07
    Khi bước 3 của FR-14-010, FR-14-016 và FR-14-040 (chiều vào)
    Thì quyết định `ALLOW` hoặc `DENY` kèm `reason`; không phải API riêng, thể hiện qua kết quả của FR-14-010
    Và giao dịch mang `purposeCode`, `procedureCode`, `caseCode`, quyết định; lượt bị từ chối có trạng thái `REJECTED`
    Và sự kiện được phát: EVT-14-11 (kèm quyết định); EVT-14-16 khi mẫu hình bất thường (FR-14-053)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-011 @FR-14-011 @M @âm
  Kịch bản: US-14-011 âm 1 · HTTT không được phép hoặc mục đích không hợp lệ
    Biết HTTT có đăng ký sử dụng dịch vụ còn hiệu lực ở PH-02; danh mục mục đích khai thác và danh mục thủ tục hành chính có mặt ở PH-07
    Khi HTTT không được phép hoặc mục đích không hợp lệ
    Thì hệ thống từ chối với ERR-14-106 (403)
    Và người dùng thấy thông báo "HTTT {mã} không được phép gọi dịch vụ này vì mục đích đã nêu. Kiểm tra đăng ký sử dụng ở danh mục dịch vụ."

  @US-14-011 @FR-14-011 @M @âm
  Kịch bản: US-14-011 âm 2 · Thiếu mã hồ sơ hoặc mã thủ tục
    Biết HTTT có đăng ký sử dụng dịch vụ còn hiệu lực ở PH-02; danh mục mục đích khai thác và danh mục thủ tục hành chính có mặt ở PH-07
    Khi thiếu mã hồ sơ hoặc mã thủ tục
    Thì hệ thống từ chối với ERR-14-107 (422)
    Và người dùng thấy thông báo "Dịch vụ này yêu cầu mã thủ tục và mã hồ sơ. Bổ sung rồi gọi lại."

  @US-14-012 @FR-14-012 @M
  Kịch bản: US-14-012 dương · Định tuyến tới nền tảng và dịch vụ đích
    Biết có ít nhất một luật `ACTIVE` khớp lượt gọi
    Khi bước 6 của FR-14-010
    Thì đích đã chọn (`serviceCode`, `platformCode`, `routedVia`: `PRIMARY` hoặc `FALLBACK`); không phải API riêng
    Và giao dịch ghi `routedVia`; mỗi lần chuyển hướng tăng chỉ số `national_fallback_total`
    Và sự kiện được phát: EVT-14-03 khi luật đổi (ở FR-14-013); chuyển hướng ghi vào EVT-14-11

  @US-14-012 @FR-14-012 @M @âm
  Kịch bản: US-14-012 âm 1 · Không có luật khớp
    Biết có ít nhất một luật `ACTIVE` khớp lượt gọi
    Khi không có luật khớp
    Thì hệ thống từ chối với ERR-14-105 (422)
    Và người dùng thấy thông báo "Chưa cấu hình đường đi cho dịch vụ {mã}. Liên hệ quản trị tỉnh để bổ sung luật định tuyến."

  @US-14-012 @FR-14-012 @M @âm
  Kịch bản: US-14-012 âm 2 · Cả đích chính và dự phòng không khả dụng, không có đệm
    Biết có ít nhất một luật `ACTIVE` khớp lượt gọi
    Khi cả đích chính và dự phòng không khả dụng, không có đệm
    Thì hệ thống từ chối với ERR-14-103 (503)
    Và người dùng thấy thông báo "Nền tảng quốc gia tạm thời không phản hồi. Hãy gọi lại sau ít phút."

  @US-14-013 @FR-14-013 @M
  Kịch bản: US-14-013 dương · Quản lý bảng định tuyến
    Biết dịch vụ đích tồn tại và `ACTIVE`
    Khi người dùng bấm "+ Thêm luật" hoặc "Sửa" ở UI-14-07, hoặc chạy "Mô phỏng"
    Thì hệ thống trả `201` hoặc `200`; luật và `state`; `202` khi chờ duyệt
    Và luật `ACTIVE` đã nạp ở mọi bản sao cổng
    Và sự kiện được phát: EVT-14-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-013 @FR-14-013 @M @âm
  Kịch bản: US-14-013 âm 1 · Trùng luật
    Biết dịch vụ đích tồn tại và `ACTIVE`
    Khi trùng luật
    Thì hệ thống từ chối với ERR-14-013 (409)
    Và người dùng thấy thông báo "Đã có luật cùng điều kiện và cùng mức ưu tiên. Đổi mức ưu tiên hoặc sửa luật đó."

  @US-14-013 @FR-14-013 @M @âm
  Kịch bản: US-14-013 âm 2 · Đích chưa bật
    Biết dịch vụ đích tồn tại và `ACTIVE`
    Khi đích chưa bật
    Thì hệ thống từ chối với ERR-14-014 (422)
    Và người dùng thấy thông báo "Dịch vụ đích {mã} chưa ở trạng thái hoạt động."

  @US-14-014 @FR-14-014 @M
  Kịch bản: US-14-014 dương · Chuyển đổi bản tin theo hợp đồng dịch vụ
    Biết dịch vụ có đặc tả `ACTIVE`
    Khi bước 4 và bước 7, 9 của FR-14-010
    Thì bản tin đúng giao thức (nội bộ) hoặc JSON chuẩn (cho bên gọi)

  @US-14-014 @FR-14-014 @M @âm
  Kịch bản: US-14-014 âm 1 · Bản tin không đúng lược đồ
    Biết dịch vụ có đặc tả `ACTIVE`
    Khi bản tin không đúng lược đồ
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Dữ liệu gửi đi không đúng mẫu của dịch vụ: {danh sách trường}."

  @US-14-014 @FR-14-014 @M @âm
  Kịch bản: US-14-014 âm 2 · Phản hồi sai cấu trúc
    Biết dịch vụ có đặc tả `ACTIVE`
    Khi phản hồi sai cấu trúc
    Thì hệ thống từ chối với ERR-14-128 (502)
    Và người dùng thấy thông báo "Phản hồi từ nền tảng quốc gia không đúng cấu trúc. Sự cố đã được ghi nhận."

  @US-14-015 @FR-14-015 @M
  Kịch bản: US-14-015 dương · Phân loại và chuẩn hóa lỗi từ quốc gia
    Biết có phản hồi hoặc lỗi từ nền tảng
    Khi bước 8 của FR-14-010
    Thì lỗi RFC 9457 có `category`, `retryable`, `upstreamCode`, `transactionCode`
    Và giao dịch có loại lỗi; không thử lại lỗi nghiệp vụ

  @US-14-015 @FR-14-015 @M @âm
  Kịch bản: US-14-015 âm 1 · Lỗi nghiệp vụ của trung ương
    Biết có phản hồi hoặc lỗi từ nền tảng
    Khi lỗi nghiệp vụ của trung ương
    Thì hệ thống từ chối với ERR-14-102
    Và người dùng thấy thông báo "Nền tảng quốc gia từ chối yêu cầu: {lý do đã che}."

  @US-14-015 @FR-14-015 @M @âm
  Kịch bản: US-14-015 âm 2 · Phản hồi sai cấu trúc
    Biết có phản hồi hoặc lỗi từ nền tảng
    Khi phản hồi sai cấu trúc
    Thì hệ thống từ chối với ERR-14-128 (502)

  @US-14-016 @FR-14-016 @M
  Kịch bản: US-14-016 dương · Gọi bất đồng bộ qua hàng chờ
    Biết dịch vụ `ACTIVE`; bên gọi có `Idempotency-Key`
    Khi HTTT gọi API-14-076; hoặc FR-14-010 chuyển vào hàng chờ khi nền tảng đang ngắt mạch và dịch vụ cho phép gọi chậm
    Thì hệ thống trả `202`; `requestId`, `state = QUEUED`, `statusUrl`; tiêu đề `Location`
    Và yêu cầu ở một trạng thái cuối trong 72 giờ hoặc bị hủy; không có gửi trùng
    Và sự kiện được phát: EVT-14-11 khi hoàn tất; EVT-14-10 khi hàng chờ tích lũy do ngắt mạch
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-016 @FR-14-016 @M @âm
  Kịch bản: US-14-016 âm 1 · Hàng chờ đầy
    Biết dịch vụ `ACTIVE`; bên gọi có `Idempotency-Key`
    Khi hàng chờ đầy
    Thì hệ thống từ chối với ERR-14-118 (503)
    Và người dùng thấy thông báo "Hàng chờ gửi quốc gia đang đầy. Thử lại sau ít phút."

  @US-14-016 @FR-14-016 @M @âm
  Kịch bản: US-14-016 âm 2 · Trùng `Idempotency-Key` nhưng khác nội dung
    Biết dịch vụ `ACTIVE`; bên gọi có `Idempotency-Key`
    Khi trùng `Idempotency-Key` nhưng khác nội dung
    Thì hệ thống từ chối với ERR-14-116 (409)
    Và người dùng thấy thông báo "Khóa chống trùng đã dùng cho yêu cầu khác nội dung."

  # ---- EP-14-C · Bộ điều hợp theo nhóm dịch vụ

  @US-14-017 @FR-14-017 @M
  Kịch bản: US-14-017 dương · Bộ điều hợp tư pháp: lý lịch tư pháp
    Biết có dịch vụ nhóm `LLTP` `ACTIVE` với đặc tả `ACTIVE`; HTTT đã đăng ký sử dụng và có mục đích hợp lệ (FR-14-011)
    Khi HTTT gọi API-14-075 với dịch vụ nhóm `LLTP` và một `operation` ở bảng thao tác bên dưới
    Thì hệ thống trả `200` với `items[]` hoặc `item`, `meta`; thao tác ghi trả `200` hoặc `202` kèm `transactionCode`
    Và dữ liệu lý lịch tư pháp (mức `SENSITIVE`) không được đệm; giao dịch ghi đầy đủ
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-017 @FR-14-017 @M @âm
  Kịch bản: US-14-017 âm 1 · Không tìm thấy hồ sơ
    Biết có dịch vụ nhóm `LLTP` `ACTIVE` với đặc tả `ACTIVE`; HTTT đã đăng ký sử dụng và có mục đích hợp lệ (FR-14-011)
    Khi không tìm thấy hồ sơ
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy hồ sơ lý lịch tư pháp {mã}."

  @US-14-017 @FR-14-017 @M @âm
  Kịch bản: US-14-017 âm 2 · Khoảng thời gian quá rộng
    Biết có dịch vụ nhóm `LLTP` `ACTIVE` với đặc tả `ACTIVE`; HTTT đã đăng ký sử dụng và có mục đích hợp lệ (FR-14-011)
    Khi khoảng thời gian quá rộng
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Khoảng thời gian tra tối đa 31 ngày mỗi lượt."

  @US-14-018 @FR-14-018 @M
  Kịch bản: US-14-018 dương · Bộ điều hợp tư pháp: hộ tịch
    Biết dịch vụ nhóm `HO_TICH` `ACTIVE`; HTTT đã đăng ký sử dụng, mục đích và mã hồ sơ hợp lệ
    Khi HTTT gọi API-14-075 (đọc) hoặc API-14-076 (đăng ký) với một `operation` ở bảng thao tác bên dưới
    Thì hệ thống trả `200` hoặc `202`; `item` (mã hồ sơ, trạng thái), `transactionCode`
    Và hộ tịch (`SENSITIVE`) không đệm; mỗi sự kiện đăng ký có đúng một giao dịch ghi thành công hoặc một giao dịch `UNKNOWN_RESULT` đang đối soát
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-018 @FR-14-018 @M @âm
  Kịch bản: US-14-018 âm 1 · Trùng khóa chống trùng, khác nội dung
    Biết dịch vụ nhóm `HO_TICH` `ACTIVE`; HTTT đã đăng ký sử dụng, mục đích và mã hồ sơ hợp lệ
    Khi trùng khóa chống trùng, khác nội dung
    Thì hệ thống từ chối với ERR-14-116 (409)
    Và người dùng thấy thông báo "Khóa chống trùng đã dùng cho yêu cầu khác nội dung."

  @US-14-018 @FR-14-018 @M @âm
  Kịch bản: US-14-018 âm 2 · Sự kiện sai loại hoặc thiếu trường
    Biết dịch vụ nhóm `HO_TICH` `ACTIVE`; HTTT đã đăng ký sử dụng, mục đích và mã hồ sơ hợp lệ
    Khi sự kiện sai loại hoặc thiếu trường
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Dữ liệu đăng ký hộ tịch thiếu hoặc sai: {danh sách trường}."

  @US-14-019 @FR-14-019 @M
  Kịch bản: US-14-019 dương · Bộ điều hợp bảo hiểm xã hội
    Biết dịch vụ nhóm `BHXH` `ACTIVE`; HTTT có mục đích hợp lệ trong sổ hoạt động xử lý ở PH-09
    Khi HTTT gọi API-14-075 với một `operation` ở bảng thao tác bên dưới
    Thì hệ thống trả `200`; `items[]` hoặc `item`, `meta`
    Và dữ liệu chỉ đệm khi chính sách cho phép và có hạn ngắn; nhật ký ghi số bản ghi trả về
    Và sự kiện được phát: EVT-14-11; EVT-14-16 khi vượt ngưỡng tra cứu (FR-14-053)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-019 @FR-14-019 @M @âm
  Kịch bản: US-14-019 âm 1 · Không đủ tiêu chí tìm
    Biết dịch vụ nhóm `BHXH` `ACTIVE`; HTTT có mục đích hợp lệ trong sổ hoạt động xử lý ở PH-09
    Khi không đủ tiêu chí tìm
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Cần ít nhất hai tiêu chí định danh để tìm mã số bảo hiểm xã hội."

  @US-14-019 @FR-14-019 @M @âm
  Kịch bản: US-14-019 âm 2 · Không tìm thấy
    Biết dịch vụ nhóm `BHXH` `ACTIVE`; HTTT có mục đích hợp lệ trong sổ hoạt động xử lý ở PH-09
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy dữ liệu bảo hiểm xã hội phù hợp."

  @US-14-020 @FR-14-020 @M
  Kịch bản: US-14-020 dương · Bộ điều hợp hồ sơ thủ tục cấp mã số ĐVQHNS
    Biết dịch vụ nhóm `DVQHNS` `ACTIVE`
    Khi HTTT hoặc luồng gọi API-14-075 với một `operation` ở bảng thao tác bên dưới; luồng đồng bộ định kỳ chạy theo lịch ở PH-04
    Thì hệ thống trả `200`; `items[]` kèm `watermark`, hoặc `item`
    Và chỉ đọc; giao dịch ghi nhận ưu tiên nền
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-020 @FR-14-020 @M @âm
  Kịch bản: US-14-020 âm 1 · Khoảng thời gian quá rộng hoặc vượt số trang
    Biết dịch vụ nhóm `DVQHNS` `ACTIVE`
    Khi khoảng thời gian quá rộng hoặc vượt số trang
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa 31 ngày, số trang tối đa {n}. Chia nhỏ khoảng tra."

  @US-14-020 @FR-14-020 @M @âm
  Kịch bản: US-14-020 âm 2 · Không tìm thấy hồ sơ
    Biết dịch vụ nhóm `DVQHNS` `ACTIVE`
    Khi không tìm thấy hồ sơ
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy hồ sơ {mã}."

  @US-14-021 @FR-14-021 @M
  Kịch bản: US-14-021 dương · Bộ điều hợp đăng ký doanh nghiệp
    Biết dịch vụ nhóm `DKDN` `ACTIVE`
    Khi HTTT gọi API-14-075 với một `operation` ở bảng thao tác bên dưới
    Thì hệ thống trả `200`; `item` hoặc `items[]`, `meta`
    Và chỉ đọc; đệm cập nhật theo chính sách
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-021 @FR-14-021 @M @âm
  Kịch bản: US-14-021 âm 1 · Mã số doanh nghiệp sai mẫu
    Biết dịch vụ nhóm `DKDN` `ACTIVE`
    Khi mã số doanh nghiệp sai mẫu
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Mã số doanh nghiệp gồm 10 hoặc 13 chữ số."

  @US-14-021 @FR-14-021 @M @âm
  Kịch bản: US-14-021 âm 2 · Không tìm thấy
    Biết dịch vụ nhóm `DKDN` `ACTIVE`
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy doanh nghiệp có mã số {mã}."

  @US-14-022 @FR-14-022 @M
  Kịch bản: US-14-022 dương · Bộ điều hợp văn bản quy phạm pháp luật
    Biết dịch vụ nhóm `VBQPPL` `ACTIVE`
    Khi HTTT gọi API-14-075 với một `operation` ở bảng thao tác bên dưới
    Thì hệ thống trả `200`; `items[]` hoặc `item`, `meta`
    Và chỉ đọc
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-022 @FR-14-022 @M @âm
  Kịch bản: US-14-022 âm 1 · Từ khóa rỗng hoặc quá dài
    Biết dịch vụ nhóm `VBQPPL` `ACTIVE`
    Khi từ khóa rỗng hoặc quá dài
    Thì hệ thống từ chối với ERR-14-108 (422)
    Và người dùng thấy thông báo "Từ khóa tìm kiếm từ 1 đến 200 ký tự."

  @US-14-022 @FR-14-022 @M @âm
  Kịch bản: US-14-022 âm 2 · Không tìm thấy văn bản
    Biết dịch vụ nhóm `VBQPPL` `ACTIVE`
    Khi không tìm thấy văn bản
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy văn bản {mã}."

  @US-14-023 @FR-14-023 @M
  Kịch bản: US-14-023 dương · Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07
    Biết dịch vụ nhóm `DMDC` `ACTIVE` ở nền tảng `NDXP` của tenant hoặc của `COMMON`; PH-07 có lịch đồng bộ hoặc người dùng yêu cầu đồng bộ
    Khi bộ lập lịch hoặc người dùng của PH-07 gọi API-14-079…083 qua mesh nội bộ
    Thì hệ thống trả `200` với `items[]`, `remoteVersion`, `nextPage`; hoặc `304`; hoặc `202` với `proposalId`
    Và giao dịch mức `BACKGROUND` ghi đủ; không có dữ liệu danh mục lưu ở PH-14
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-023 @FR-14-023 @M @âm
  Kịch bản: US-14-023 âm 1 · Không phải PH-07 hoặc thiếu scope
    Biết dịch vụ nhóm `DMDC` `ACTIVE` ở nền tảng `NDXP` của tenant hoặc của `COMMON`; PH-07 có lịch đồng bộ hoặc người dùng yêu cầu đồng bộ
    Khi không phải PH-07 hoặc thiếu scope
    Thì hệ thống trả 403 theo FR-00; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Chỉ phân hệ Danh mục dùng chung được gọi cổng này."

  @US-14-023 @FR-14-023 @M @âm
  Kịch bản: US-14-023 âm 2 · Danh mục không tồn tại ở nguồn
    Biết dịch vụ nhóm `DMDC` `ACTIVE` ở nền tảng `NDXP` của tenant hoặc của `COMMON`; PH-07 có lịch đồng bộ hoặc người dùng yêu cầu đồng bộ
    Khi danh mục không tồn tại ở nguồn
    Thì hệ thống từ chối với ERR-14-102 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục {mã} trên nền tảng quốc gia."

  # ---- EP-14-D · Xác thực, chữ ký số và chứng thư

  @US-14-024 @FR-14-024 @M
  Kịch bản: US-14-024 dương · Lấy và làm mới token OAuth 2.1 của nền tảng
    Biết nền tảng có kết nối PH-05 với thông tin xác thực đã đặt cho môi trường đang chạy (chưa đặt: ERR-14-034)
    Khi cổng cần token (chưa có hoặc còn dưới `14.token.refresh-before-seconds`), hoặc người dùng bấm "Thử lấy token" ở UI-14-03
    Thì nội bộ: token trong bộ nhớ
    Và token không nằm ở nơi nào ngoài bộ nhớ cổng; lỗi xác thực được đếm ở `national_token_errors_total`
    Và sự kiện được phát: EVT-14-15 khi đổi sức khỏe nền tảng do lỗi xác thực
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-024 @FR-14-024 @M @âm
  Kịch bản: US-14-024 âm 1 · Thông tin xác thực chưa đặt
    Biết nền tảng có kết nối PH-05 với thông tin xác thực đã đặt cho môi trường đang chạy (chưa đặt: ERR-14-034)
    Khi thông tin xác thực chưa đặt
    Thì hệ thống từ chối với ERR-14-034 (422)
    Và người dùng thấy thông báo "Chưa có thông tin xác thực cho nền tảng này ở môi trường {môi trường}. Khai ở kết nối {mã} trong phân hệ Bộ điều hợp."

  @US-14-024 @FR-14-024 @M @âm
  Kịch bản: US-14-024 âm 2 · Nền tảng từ chối (401, `invalid_client`)
    Biết nền tảng có kết nối PH-05 với thông tin xác thực đã đặt cho môi trường đang chạy (chưa đặt: ERR-14-034)
    Khi nền tảng từ chối (401, `invalid_client`)
    Thì hệ thống từ chối với ERR-14-114 (502)
    Và người dùng thấy thông báo "Nền tảng quốc gia từ chối thông tin xác thực của tỉnh. Kiểm tra với đơn vị quản lý nền tảng."

  @US-14-025 @FR-14-025 @M
  Kịch bản: US-14-025 dương · Xoay vòng và cấp lại thông tin xác thực
    Biết nền tảng `ACTIVE` hoặc `TESTED`; người vận hành đã nhận được thông tin xác thực mới từ đơn vị quản lý nền tảng ở trung ương (việc này nằm ngoài hệ thống)
    Khi hệ thống nhắc khi bí mật quá 76 ngày (cảnh báo trước hạn 90 ngày 14 ngày); hoặc người dùng bấm "Xoay thông tin xác thực" ở UI-14-03; hoặc SO buộc xoay khi có sự cố
    Thì hệ thống trả `200`; `rotationState` (`PENDING_VERIFY`, `OVERLAP`, `AWAITING_REVOCATION`, `DONE`), thời điểm từng bước
    Và một bộ thông tin xác thực hiệu lực; tuổi bí mật đặt lại; bí mật cũ không còn dùng được
    Và sự kiện được phát: EVT-14-01 (đổi trạng thái xoay)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-025 @FR-14-025 @M @âm
  Kịch bản: US-14-025 âm 1 · Giá trị mới bị nền tảng từ chối
    Biết nền tảng `ACTIVE` hoặc `TESTED`; người vận hành đã nhận được thông tin xác thực mới từ đơn vị quản lý nền tảng ở trung ương (việc này nằm ngoài hệ thống)
    Khi giá trị mới bị nền tảng từ chối
    Thì hệ thống từ chối với ERR-14-114 (502)
    Và người dùng thấy thông báo "Thông tin xác thực mới bị nền tảng từ chối. Giữ nguyên thông tin cũ."

  @US-14-025 @FR-14-025 @M @âm
  Kịch bản: US-14-025 âm 2 · Chưa đặt giá trị chờ ở PH-05
    Biết nền tảng `ACTIVE` hoặc `TESTED`; người vận hành đã nhận được thông tin xác thực mới từ đơn vị quản lý nền tảng ở trung ương (việc này nằm ngoài hệ thống)
    Khi chưa đặt giá trị chờ ở PH-05
    Thì hệ thống từ chối với ERR-14-034 (422)
    Và người dùng thấy thông báo "Hãy nhập thông tin xác thực mới ở kết nối {mã} trước."

  @US-14-026 @FR-14-026 @M
  Kịch bản: US-14-026 dương · Ký số bản tin gửi đi
    Biết dịch vụ có `signingMode` khác `NONE`; có chứng thư `ACTIVE` hoặc `EXPIRING` đúng mục đích `SIGNING` hoặc `BOTH`; OpenBao `transit` sẵn sàng
    Khi bước 7 của FR-14-010 và của bộ điều hợp chiều vào khi dựng phản hồi (FR-14-041)
    Thì bản tin đã ký (nội bộ), `certCode` đã dùng ghi vào giao dịch
    Và giao dịch ghi `certCode` và băm; nhật ký OpenBao ghi yêu cầu ký
    Và sự kiện được phát: EVT-14-04 khi chặn do chứng thư; EVT-14-11 qua giao dịch
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-026 @FR-14-026 @M @âm
  Kịch bản: US-14-026 âm 1 · Không ký được (OpenBao lỗi, không có chứng thư dùng được, thuật toán không hỗ trợ)
    Biết dịch vụ có `signingMode` khác `NONE`; có chứng thư `ACTIVE` hoặc `EXPIRING` đúng mục đích `SIGNING` hoặc `BOTH`; OpenBao `transit` sẵn sàng
    Khi không ký được (OpenBao lỗi, không có chứng thư dùng được, thuật toán không hỗ trợ)
    Thì hệ thống từ chối với ERR-14-112 (503)
    Và người dùng thấy thông báo "Chưa ký được bản tin nên chưa gửi. Hệ thống sẽ gửi lại khi sẵn sàng."

  @US-14-026 @FR-14-026 @M @âm
  Kịch bản: US-14-026 âm 2 · Chứng thư hết hạn hoặc bị thu hồi, không có chứng thư thay thế
    Biết dịch vụ có `signingMode` khác `NONE`; có chứng thư `ACTIVE` hoặc `EXPIRING` đúng mục đích `SIGNING` hoặc `BOTH`; OpenBao `transit` sẵn sàng
    Khi chứng thư hết hạn hoặc bị thu hồi, không có chứng thư thay thế
    Thì hệ thống từ chối với ERR-14-113 (503)
    Và người dùng thấy thông báo "Chứng thư ký số đã hết hạn nên kết nối quốc gia tạm dừng. Liên hệ cán bộ an toàn thông tin."

  @US-14-027 @FR-14-027 @M
  Kịch bản: US-14-027 dương · Xác minh chữ ký phản hồi
    Biết dịch vụ có `verifyMode` khác `NONE`; chuỗi tin cậy và danh sách thu hồi đã nạp (FR-14-030)
    Khi bước 8 của FR-14-010 và bước xác minh của FR-14-040 (chiều vào)
    Thì kết quả `VERIFIED` hoặc từ chối kèm loại lỗi; không trả dữ liệu khi từ chối
    Và giao dịch ghi kết quả xác minh; sự cố chữ ký được mở khi từ chối
    Và sự kiện được phát: EVT-14-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-027 @FR-14-027 @M @âm
  Kịch bản: US-14-027 âm 1 · Chữ ký không khớp
    Biết dịch vụ có `verifyMode` khác `NONE`; chuỗi tin cậy và danh sách thu hồi đã nạp (FR-14-030)
    Khi chữ ký không khớp
    Thì hệ thống từ chối với ERR-14-109 (502)
    Và người dùng thấy thông báo "Không thể tin cậy dữ liệu nhận được. Sự cố đã được ghi nhận và báo cán bộ an toàn thông tin."

  @US-14-027 @FR-14-027 @M @âm
  Kịch bản: US-14-027 âm 2 · Chứng thư không thuộc chuỗi tin cậy hoặc bị thu hồi
    Biết dịch vụ có `verifyMode` khác `NONE`; chuỗi tin cậy và danh sách thu hồi đã nạp (FR-14-030)
    Khi chứng thư không thuộc chuỗi tin cậy hoặc bị thu hồi
    Thì hệ thống từ chối với ERR-14-110 (502)
    Và người dùng thấy thông báo "Chứng thư của nền tảng quốc gia không đáng tin. Sự cố đã được ghi nhận."

  @US-14-028 @FR-14-028 @M
  Kịch bản: US-14-028 dương · Nạp và kích hoạt chứng thư số
    Biết khóa riêng đã được tạo hoặc nhập (BYOK) trong OpenBao `transit` theo quy trình ATTT, có `keyRef`; chứng thư công khai đã được cơ quan cấp phát hành
    Khi SO bấm "Nạp chứng thư" ở UI-14-08
    Thì hệ thống trả `201` khi nạp; `200` hoặc `202` khi yêu cầu, duyệt; chi tiết chứng thư (không có khóa)
    Và mỗi mục đích có tối đa một chứng thư `ACTIVE` mới nhất, chứng thư cũ `SUPERSEDED` hoặc `EXPIRING`
    Và sự kiện được phát: EVT-14-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-028 @FR-14-028 @M @âm
  Kịch bản: US-14-028 âm 1 · Tệp không đọc được hoặc không đúng chuỗi
    Biết khóa riêng đã được tạo hoặc nhập (BYOK) trong OpenBao `transit` theo quy trình ATTT, có `keyRef`; chứng thư công khai đã được cơ quan cấp phát hành
    Khi tệp không đọc được hoặc không đúng chuỗi
    Thì hệ thống từ chối với ERR-14-019 (422)
    Và người dùng thấy thông báo "Chứng thư không đọc được hoặc không thuộc chuỗi tin cậy đã cấu hình."

  @US-14-028 @FR-14-028 @M @âm
  Kịch bản: US-14-028 âm 2 · Không khớp khóa
    Biết khóa riêng đã được tạo hoặc nhập (BYOK) trong OpenBao `transit` theo quy trình ATTT, có `keyRef`; chứng thư công khai đã được cơ quan cấp phát hành
    Khi không khớp khóa
    Thì hệ thống từ chối với ERR-14-020 (422)
    Và người dùng thấy thông báo "Chứng thư không khớp với khóa {keyRef} trong kho bí mật."

  @US-14-029 @FR-14-029 @M
  Kịch bản: US-14-029 dương · Theo dõi hạn chứng thư, cảnh báo và chuyển tiếp
    Biết có ít nhất một chứng thư ở trạng thái từ `UPLOADED` trở đi
    Khi bộ chạy kiểm tra chạy hằng ngày lúc 06:00 giờ Việt Nam và khi khởi động; SO bấm "Thu hồi" ở UI-14-08
    Thì danh sách chứng thư với `daysRemaining`, `state`; `200` khi thu hồi
    Và trạng thái chứng thư đúng máy trạng thái ở mục 4.5; chứng thư hết hạn vẫn lưu để xác minh giao dịch cũ
    Và sự kiện được phát: EVT-14-05; EVT-14-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-029 @FR-14-029 @M @âm
  Kịch bản: US-14-029 âm 1 · Xóa chứng thư còn giao dịch cần xác minh
    Biết có ít nhất một chứng thư ở trạng thái từ `UPLOADED` trở đi
    Khi xóa chứng thư còn giao dịch cần xác minh
    Thì hệ thống từ chối với ERR-14-022 (409)
    Và người dùng thấy thông báo "Chứng thư này còn được dùng để xác minh giao dịch trong thời hạn lưu nên không xóa được."

  @US-14-029 @FR-14-029 @M @âm
  Kịch bản: US-14-029 âm 2 · Thu hồi chứng thư ở trạng thái cuối
    Biết có ít nhất một chứng thư ở trạng thái từ `UPLOADED` trở đi
    Khi thu hồi chứng thư ở trạng thái cuối
    Thì hệ thống từ chối với ERR-14-004 (409)
    Và người dùng thấy thông báo "Chứng thư đã hết hạn, bị thu hồi hoặc được thay thế."

  @US-14-030 @FR-14-030 @M
  Kịch bản: US-14-030 dương · Cập nhật chuỗi tin cậy và danh sách thu hồi
    Biết có ít nhất một neo tin cậy đã cấu hình cho nền tảng
    Khi bộ chạy kiểm tra làm mới mỗi `14.trust.refresh-hours` (mặc định 24 giờ); SO bấm "Làm mới ngay" ở UI-14-08
    Thì hệ thống trả `200`; `trustAnchors[]`, `crlLastRefreshedAt`, `crlAgeSeconds`
    Và mọi bản sao cổng dùng cùng chuỗi tin cậy và CRL trong vòng 30 giây
    Và sự kiện được phát: EVT-14-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-030 @FR-14-030 @M @âm
  Kịch bản: US-14-030 âm 1 · Không tải được CRL liên tục
    Biết có ít nhất một neo tin cậy đã cấu hình cho nền tảng
    Khi không tải được CRL liên tục
    Thì cảnh báo vận hành, không có mã lỗi cho người dùng; chỉ số `national_crl_age_seconds` tăng

  @US-14-030 @FR-14-030 @M @âm
  Kịch bản: US-14-030 âm 2 · Tệp neo không hợp lệ
    Biết có ít nhất một neo tin cậy đã cấu hình cho nền tảng
    Khi tệp neo không hợp lệ
    Thì hệ thống từ chối với ERR-14-019 (422)
    Và người dùng thấy thông báo "Chứng thư neo không đọc được."

  @US-14-031 @FR-14-031 @M
  Kịch bản: US-14-031 dương · Xử lý sự cố chữ ký như sự cố an ninh
    Biết FR-14-027 hoặc FR-14-040 vừa từ chối một bản tin vì lý do chữ ký
    Khi tự động khi xác minh thất bại; SO mở màn UI-14-14
    Thì hệ thống trả `200`; sự cố với `state`, `classification`, `conclusion`; danh sách sự cố có lọc
    Và sự cố được giữ 5 năm; dữ liệu của giao dịch lỗi không được dùng
    Và sự kiện được phát: EVT-14-06; EVT-14-01 khi vào hoặc ra `SECURITY_HOLD`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-031 @FR-14-031 @M @âm
  Kịch bản: US-14-031 âm 1 · Kết thúc mà chưa nhập kết luận
    Biết FR-14-027 hoặc FR-14-040 vừa từ chối một bản tin vì lý do chữ ký
    Khi kết thúc mà chưa nhập kết luận
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Nhập kết luận xử lý trước khi kết thúc sự cố."

  @US-14-031 @FR-14-031 @M @âm
  Kịch bản: US-14-031 âm 2 · Giải trừ giữ an ninh khi vẫn còn sự cố mở
    Biết FR-14-027 hoặc FR-14-040 vừa từ chối một bản tin vì lý do chữ ký
    Khi giải trừ giữ an ninh khi vẫn còn sự cố mở
    Thì hệ thống từ chối với ERR-14-004 (409)
    Và người dùng thấy thông báo "Còn sự cố chữ ký chưa xác nhận. Xử lý trước khi giải trừ."

  # ---- EP-14-E · Hạn mức, đệm và chịu lỗi

  @US-14-032 @FR-14-032 @M
  Kịch bản: US-14-032 dương · Khai báo hạn mức do trung ương áp
    Biết nền tảng (và dịch vụ nếu khai theo dịch vụ) tồn tại
    Khi TA bấm "+ Hạn mức" hoặc "Sửa" ở UI-14-09
    Thì hệ thống trả `201` hoặc `200`; hạn mức với `state`; `202` khi chờ duyệt
    Và mỗi (phạm vi, chu kỳ) có đúng một hạn mức `ACTIVE`; lịch sử giữ vĩnh viễn
    Và sự kiện được phát: EVT-14-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-032 @FR-14-032 @M @âm
  Kịch bản: US-14-032 âm 1 · Thiếu căn cứ
    Biết nền tảng (và dịch vụ nếu khai theo dịch vụ) tồn tại
    Khi thiếu căn cứ
    Thì hệ thống từ chối với ERR-14-016 (422)
    Và người dùng thấy thông báo "Nhập căn cứ văn bản của hạn mức (số, ngày, trích yếu)."

  @US-14-032 @FR-14-032 @M @âm
  Kịch bản: US-14-032 âm 2 · Giới hạn không hợp lệ
    Biết nền tảng (và dịch vụ nếu khai theo dịch vụ) tồn tại
    Khi giới hạn không hợp lệ
    Thì hệ thống từ chối với ERR-14-017 (422)
    Và người dùng thấy thông báo "Giới hạn phải là số nguyên lớn hơn 0 và chu kỳ là giờ, ngày hoặc tháng."

  @US-14-033 @FR-14-033 @M
  Kịch bản: US-14-033 dương · Đếm hạn mức, kiểm tra trước mỗi lượt gọi và cảnh báo ngưỡng
    Biết có hạn mức `ACTIVE` áp cho lượt gọi (nếu không có hạn mức nào thì không chặn nhưng vẫn đếm)
    Khi bước 6 của FR-14-010, trước khi gửi ra ngoài; mỗi lần thử lại cũng đi qua bước này
    Thì nội bộ: cho phép hoặc từ chối; ra ngoài: `GET` tình trạng với `used`, `limit`, `ratio`, `level` (`OK`, `INFO`, `WARNING`, `CRITICAL`), `resetAt`
    Và bộ đếm chính xác theo nguyên tắc ít nhất một, hoàn lại khi chưa gửi; mức dùng lưu 2 năm
    Và sự kiện được phát: EVT-14-07

  @US-14-033 @FR-14-033 @M @âm
  Kịch bản: US-14-033 âm 1 · Hết hạn mức
    Biết có hạn mức `ACTIVE` áp cho lượt gọi (nếu không có hạn mức nào thì không chặn nhưng vẫn đếm)
    Khi hết hạn mức
    Thì hệ thống từ chối với ERR-14-104 (429)
    Và người dùng thấy thông báo "Đã dùng hết hạn mức {dịch vụ hoặc nền tảng}: {đã dùng} trên {giới hạn} lượt mỗi {chu kỳ}. Bộ đếm đặt lại lúc {thời điểm}."

  @US-14-034 @FR-14-034 @M
  Kịch bản: US-14-034 dương · Phân bổ hạn mức theo HTTT và ưu tiên dịch vụ thiết yếu
    Biết hạn mức nền tảng hoặc dịch vụ `ACTIVE` (FR-14-032); HTTT có đăng ký sử dụng dịch vụ
    Khi TA bấm "Phân bổ" ở UI-14-09; cổng áp dụng ở bước 6 của FR-14-010
    Thì hệ thống trả `200`; phân bổ theo HTTT; lỗi 429 kèm `scope` (`SYSTEM`, `SERVICE`, `PLATFORM`) và `reason` (`EXHAUSTED`, `DEFERRED`)
    Và mọi lượt gọi gắn với một phân bổ; không có phân bổ vượt hạn mức
    Và sự kiện được phát: EVT-14-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-034 @FR-14-034 @M @âm
  Kịch bản: US-14-034 âm 1 · Tổng phân bổ vượt hạn mức
    Biết hạn mức nền tảng hoặc dịch vụ `ACTIVE` (FR-14-032); HTTT có đăng ký sử dụng dịch vụ
    Khi tổng phân bổ vượt hạn mức
    Thì hệ thống từ chối với ERR-14-018 (422)
    Và người dùng thấy thông báo "Tổng phân bổ ({tổng}) vượt hạn mức {giới hạn}. Giảm phân bổ của một HTTT."

  @US-14-034 @FR-14-034 @M @âm
  Kịch bản: US-14-034 âm 2 · HTTT hết phân bổ
    Biết hạn mức nền tảng hoặc dịch vụ `ACTIVE` (FR-14-032); HTTT có đăng ký sử dụng dịch vụ
    Khi HTTT hết phân bổ
    Thì hệ thống từ chối với ERR-14-104 (429)
    Và người dùng thấy thông báo "HTTT {mã} đã dùng hết phần hạn mức được giao. Liên hệ quản trị tỉnh để điều chỉnh."

  @US-14-035 @FR-14-035 @M
  Kịch bản: US-14-035 dương · Đệm phản hồi theo loại dữ liệu
    Biết dịch vụ `cacheable = true` với `cacheTtlSeconds`; Valkey sẵn sàng
    Khi bước 5 và bước 9 của FR-14-010
    Thì tiêu đề `X-DH-Cache: HIT/MISS/STALE`; `meta.fromCache`, `meta.cacheAgeSeconds`
    Và đệm chỉ chứa phản hồi hợp lệ, cô lập theo tenant, không chứa dữ liệu mức `SENSITIVE`

  @US-14-035 @FR-14-035 @M @âm
  Kịch bản: US-14-035 âm 1 · Lỗi, kể cả lỗi nghiệp vụ, không được đệm; không có mã lỗi riêng
    Biết dịch vụ `cacheable = true` với `cacheTtlSeconds`; Valkey sẵn sàng
    Khi lỗi, kể cả lỗi nghiệp vụ, không được đệm; không có mã lỗi riêng
    Thì hệ thống từ chối thao tác

  @US-14-035 @FR-14-035 @M @âm
  Kịch bản: US-14-035 âm 2 · Bên gọi đặt `freshData = true` khi hết hạn mức
    Biết dịch vụ `cacheable = true` với `cacheTtlSeconds`; Valkey sẵn sàng
    Khi bên gọi đặt `freshData = true` khi hết hạn mức
    Thì hệ thống từ chối với ERR-14-104 (429)
    Và người dùng thấy thông báo "gọi lại với dữ liệu đệm"

  @US-14-036 @FR-14-036 @S
  Kịch bản: US-14-036 dương · Vô hiệu đệm
    Biết dịch vụ tồn tại; đệm có thể trống
    Khi người dùng bấm "Vô hiệu đệm" ở UI-14-09; FR-14-042 nhận thông báo thay đổi; FR-14-008 kích hoạt đặc tả mới; giảm `cacheTtlSeconds` ở FR-14-005
    Thì hệ thống trả `200`; `invalidated` (số khóa), `scope`
    Và đệm của phạm vi đã xóa; chỉ số trúng đệm giảm tạm thời là bình thường
    Và sự kiện được phát: EVT-14-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-036 @FR-14-036 @S @âm
  Kịch bản: US-14-036 âm 1 · Phạm vi `ALL` bởi người không phải TA
    Biết dịch vụ tồn tại; đệm có thể trống
    Khi phạm vi `ALL` bởi người không phải TA
    Thì hệ thống trả 403 theo FR-00; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Chỉ quản trị tỉnh được xóa toàn bộ đệm."

  @US-14-037 @FR-14-037 @M
  Kịch bản: US-14-037 dương · Dùng dữ liệu đệm quá hạn có cờ
    Biết dịch vụ `cacheable` và `staleAllowed = true`; có mục đệm quá hạn mềm nhưng còn trong thời hạn cứng
    Khi bước 6, 7 của FR-14-010 khi ERR-14-104, ERR-14-103, ERR-14-101 hoặc ERR-14-115 xảy ra
    Thì hệ thống trả `200` kèm `meta.stale = true`; hoặc lỗi gốc
    Và giao dịch ghi `stale = true` và tuổi dữ liệu; cảnh báo cho TO nếu tỷ lệ phục vụ dữ liệu cũ vượt 10% trong 15 phút
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-037 @FR-14-037 @M @âm
  Kịch bản: US-14-037 âm 1 · Không có đệm phù hợp
    Biết dịch vụ `cacheable` và `staleAllowed = true`; có mục đệm quá hạn mềm nhưng còn trong thời hạn cứng
    Khi không có đệm phù hợp
    Thì hệ thống từ chối với ERR-14-104, ERR-14-103
    Và người dùng thấy thông báo "Nền tảng quốc gia chưa phản hồi và chưa có dữ liệu lưu tạm phù hợp. Thử lại sau."

  @US-14-038 @FR-14-038 @M
  Kịch bản: US-14-038 dương · Ngắt mạch và thử lại
    Biết nền tảng `ACTIVE`
    Khi mỗi lượt gửi ra nền tảng; người dùng bấm "Ép mở" hoặc "Ép đóng" ở UI-14-01
    Thì nội bộ; ép đóng, mở trả `200` với `breakerState`
    Và trạng thái ngắt mạch theo từng (nền tảng, nhóm dịch vụ), đồng bộ giữa các bản sao qua Valkey
    Và sự kiện được phát: EVT-14-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-038 @FR-14-038 @M @âm
  Kịch bản: US-14-038 âm 1 · Nền tảng đang ngắt mạch, không có đệm, không có dự phòng
    Biết nền tảng `ACTIVE`
    Khi nền tảng đang ngắt mạch, không có đệm, không có dự phòng
    Thì hệ thống từ chối với ERR-14-103 (503)
    Và người dùng thấy thông báo "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút."

  @US-14-038 @FR-14-038 @M @âm
  Kịch bản: US-14-038 âm 2 · Lỗi xác thực
    Biết nền tảng `ACTIVE`
    Khi lỗi xác thực
    Thì không thử lại quá một lần trong 5 phút (BR-14-031)

  # ---- EP-14-F · Chiều vào

  @US-14-039 @FR-14-039 @M
  Kịch bản: US-14-039 dương · Đăng ký điểm cuối chiều vào và nguồn được phép
    Biết nền tảng đã `ACTIVE`; luồng PH-04 xử lý đã phát hành; tỉnh có văn bản của trung ương nêu chứng thư và mã đơn vị gửi của nền tảng
    Khi TA bấm "+ Điểm cuối chiều vào" ở UI-14-10
    Thì hệ thống trả `201`; điểm cuối với `url`, `state`
    Và mỗi điểm cuối gắn một tenant; tuyến APISIX nạp xong mới nhận lưu lượng
    Và sự kiện được phát: EVT-14-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-039 @FR-14-039 @M @âm
  Kịch bản: US-14-039 âm 1 · Mã hoặc đường dẫn trùng
    Biết nền tảng đã `ACTIVE`; luồng PH-04 xử lý đã phát hành; tỉnh có văn bản của trung ương nêu chứng thư và mã đơn vị gửi của nền tảng
    Khi mã hoặc đường dẫn trùng
    Thì hệ thống từ chối với ERR-14-023 (409)
    Và người dùng thấy thông báo "Mã hoặc đường dẫn điểm cuối đã được dùng."

  @US-14-039 @FR-14-039 @M @âm
  Kịch bản: US-14-039 âm 2 · Danh sách nguồn rỗng
    Biết nền tảng đã `ACTIVE`; luồng PH-04 xử lý đã phát hành; tỉnh có văn bản của trung ương nêu chứng thư và mã đơn vị gửi của nền tảng
    Khi danh sách nguồn rỗng
    Thì hệ thống từ chối với ERR-14-024 (422)
    Và người dùng thấy thông báo "Khai báo ít nhất một nguồn được phép gọi vào."

  @US-14-040 @FR-14-040 @M
  Kịch bản: US-14-040 dương · Tiếp nhận yêu cầu từ nền tảng quốc gia
    Biết điểm cuối `ACTIVE`; nguồn được phép; chứng thư của nguồn thuộc chuỗi tin cậy (FR-14-030)
    Khi nền tảng quốc gia gọi `POST /inbound/v1/{endpointCode}/{serviceCode}` qua vùng biên
    Thì chuyển tiếp cho FR-14-041; khi từ chối: lỗi nêu trên, nhanh (NFR-14-016)
    Và giao dịch `INBOUND` được ghi, kể cả khi từ chối (trạng thái `REJECTED`)
    Và sự kiện được phát: EVT-14-11; EVT-14-06 khi lỗi chữ ký
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-040 @FR-14-040 @M @âm
  Kịch bản: US-14-040 âm 1 · Chứng thư mTLS không hợp lệ
    Biết điểm cuối `ACTIVE`; nguồn được phép; chứng thư của nguồn thuộc chuỗi tin cậy (FR-14-030)
    Khi chứng thư mTLS không hợp lệ
    Thì hệ thống từ chối với ERR-14-120 (401)
    Và người dùng thấy thông báo "Chứng thư của nguồn gọi không hợp lệ."

  @US-14-040 @FR-14-040 @M @âm
  Kịch bản: US-14-040 âm 2 · Nguồn không được phép
    Biết điểm cuối `ACTIVE`; nguồn được phép; chứng thư của nguồn thuộc chuỗi tin cậy (FR-14-030)
    Khi nguồn không được phép
    Thì hệ thống từ chối với ERR-14-119 (403)
    Và người dùng thấy thông báo "Nguồn gọi không được phép với dịch vụ này."

  @US-14-041 @FR-14-041 @M
  Kịch bản: US-14-041 dương · Chuyển cho luồng PH-04 và trả phản hồi có ký
    Biết FR-14-040 đã xác minh bản tin; ánh xạ dịch vụ sang luồng có hiệu lực
    Khi cuối FR-14-040
    Thì hệ thống trả `200` hoặc `202` hoặc lỗi theo định dạng; phản hồi có chữ ký
    Và giao dịch `INBOUND` ở trạng thái cuối; không dữ liệu xử lý dở
    Và sự kiện được phát: EVT-14-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-041 @FR-14-041 @M @âm
  Kịch bản: US-14-041 âm 1 · Luồng xử lý lỗi hoặc quá hạn
    Biết FR-14-040 đã xác minh bản tin; ánh xạ dịch vụ sang luồng có hiệu lực
    Khi luồng xử lý lỗi hoặc quá hạn
    Thì hệ thống từ chối với ERR-14-124 (502)

  @US-14-041 @FR-14-041 @M @âm
  Kịch bản: US-14-041 âm 2 · Luồng chưa phát hành hoặc bị tạm dừng
    Biết FR-14-040 đã xác minh bản tin; ánh xạ dịch vụ sang luồng có hiệu lực
    Khi luồng chưa phát hành hoặc bị tạm dừng
    Thì hệ thống từ chối với ERR-14-124 (502)
    Và người dùng thấy thông báo "Dịch vụ tạm thời chưa nhận xử lý."

  @US-14-042 @FR-14-042 @S
  Kịch bản: US-14-042 dương · Tiếp nhận thông báo thay đổi từ quốc gia
    Biết điểm cuối `ACTIVE` có dịch vụ chiều vào loại `NOTIFICATION`; nguồn được phép
    Khi nền tảng gọi `POST /inbound/v1/{endpointCode}/notifications`
    Thì hệ thống trả `202` kèm biên nhận
    Và đệm liên quan đã xóa; sự kiện đã phát
    Và sự kiện được phát: EVT-14-17; EVT-14-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-042 @FR-14-042 @S @âm
  Kịch bản: US-14-042 âm 1 · Loại thông báo sai hoặc thiếu trường
    Biết điểm cuối `ACTIVE` có dịch vụ chiều vào loại `NOTIFICATION`; nguồn được phép
    Khi loại thông báo sai hoặc thiếu trường
    Thì hệ thống từ chối với ERR-14-121 (400)
    Và người dùng thấy thông báo "Thông báo không đúng định dạng."

  # ---- EP-14-G · Đồng bộ

  @US-14-043 @FR-14-043 @M
  Kịch bản: US-14-043 dương · Đồng bộ danh mục dịch vụ lên Bộ
    Biết có nền tảng loại `REGISTRY` `ACTIVE`; định dạng đăng ký của hệ thống nhận đã cấu hình (Q14-05)
    Khi lịch `14.sync.catalog-cron` (mặc định `0 0 2 * * *` giờ Việt Nam); sự kiện PH-02 có dịch vụ chia sẻ mới `PUBLISHED`; người dùng bấm "Đồng bộ ngay" ở UI-14-11
    Thì hệ thống trả `202` khi chạy tay; phiên `runId`, `state`, `sent`, `accepted`, `rejected`, `pending`
    Và mỗi dịch vụ chia sẻ `PUBLISHED` có trạng thái đăng ký; phiên được giữ 3 năm
    Và sự kiện được phát: EVT-14-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-043 @FR-14-043 @M @âm
  Kịch bản: US-14-043 âm 1 · Hệ thống của Bộ không khả dụng
    Biết có nền tảng loại `REGISTRY` `ACTIVE`; định dạng đăng ký của hệ thống nhận đã cấu hình (Q14-05)
    Khi hệ thống của Bộ không khả dụng
    Thì hệ thống từ chối với ERR-14-103 (503)
    Và người dùng thấy thông báo "Hệ thống đăng ký của Bộ chưa phản hồi. Hệ thống sẽ thử lại tự động."

  @US-14-043 @FR-14-043 @M @âm
  Kịch bản: US-14-043 âm 2 · Quá `14.sync.stale-alert-days` ngày (mặc định 7) không đồng bộ thành công
    Biết có nền tảng loại `REGISTRY` `ACTIVE`; định dạng đăng ký của hệ thống nhận đã cấu hình (Q14-05)
    Khi quá `14.sync.stale-alert-days` ngày (mặc định 7) không đồng bộ thành công
    Thì cảnh báo tuân thủ cho TA, SO và lãnh đạo (BR-14-026); người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Đã {n} ngày chưa đăng ký được danh mục dịch vụ lên hệ thống của Bộ."

  @US-14-044 @FR-14-044 @S
  Kịch bản: US-14-044 dương · Cầu nối đồng bộ dữ liệu chủ hai chiều
    Biết PH-06 đã đưa vào dùng; ánh xạ ngữ nghĩa ở PH-07 đủ cho tập trường cần gửi; PH-09 đã phân loại trường
    Khi PH-06 gọi API-14-056 theo lịch hoặc theo thay đổi; hoặc nền tảng quốc gia thông báo cập nhật (FR-14-042)
    Thì hệ thống trả `202`; `runId`, `state`, thống kê đối soát
    Và mỗi lô có đối soát; bản ghi lệch được báo cho PH-06
    Và sự kiện được phát: EVT-14-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-044 @FR-14-044 @S @âm
  Kịch bản: US-14-044 âm 1 · Thiếu ánh xạ ở PH-07
    Biết PH-06 đã đưa vào dùng; ánh xạ ngữ nghĩa ở PH-07 đủ cho tập trường cần gửi; PH-09 đã phân loại trường
    Khi thiếu ánh xạ ở PH-07
    Thì hệ thống từ chối với ERR-14-125 (422)
    Và người dùng thấy thông báo "Lô dữ liệu chủ có trường chưa ánh xạ sang từ điển quốc gia: {danh sách}. Bổ sung ánh xạ ở phân hệ Danh mục dùng chung."

  @US-14-045 @FR-14-045 @S
  Kịch bản: US-14-045 dương · Công bố dữ liệu mở lên NDOP
    Biết có nền tảng loại `NDOP` `ACTIVE` (có thể ở `specStatus = PROVISIONAL`); tập dữ liệu nguồn ở mức `PUBLIC`
    Khi TA bấm "+ Tập dữ liệu mở" ở UI-14-11, hoặc lịch cập nhật của tập đã duyệt
    Thì hệ thống trả `202`; `runId`, `datasetState`
    Và mỗi tập có phiên bản công bố và biên nhận
    Và sự kiện được phát: EVT-14-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-045 @FR-14-045 @S @âm
  Kịch bản: US-14-045 âm 1 · Nguồn có dữ liệu bị cấm
    Biết có nền tảng loại `NDOP` `ACTIVE` (có thể ở `specStatus = PROVISIONAL`); tập dữ liệu nguồn ở mức `PUBLIC`
    Khi nguồn có dữ liệu bị cấm
    Thì hệ thống từ chối với ERR-14-126 (403)
    Và người dùng thấy thông báo "Nguồn chứa trường không được công bố: {danh sách}. Loại trường đó khỏi tập dữ liệu mở."

  @US-14-046 @FR-14-046 @M
  Kịch bản: US-14-046 dương · Theo dõi trạng thái đồng bộ, xử lý lỗi và lệch
    Biết có ít nhất một phiên đồng bộ
    Khi người dùng mở UI-14-11 hoặc theo liên kết từ cảnh báo
    Thì hệ thống trả `200`; danh sách phiên, chi tiết phiên với `items[]`; `202` khi thử lại
    Và phiên con liên kết phiên gốc; báo cáo xuất được
    Và sự kiện được phát: EVT-14-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-046 @FR-14-046 @M @âm
  Kịch bản: US-14-046 âm 1 · Có phiên cùng loại đang chạy
    Biết có ít nhất một phiên đồng bộ
    Khi có phiên cùng loại đang chạy
    Thì hệ thống từ chối với ERR-14-026 (409)
    Và người dùng thấy thông báo "Đang có phiên cùng loại chạy. Chờ phiên đó xong rồi thử lại."

  @US-14-046 @FR-14-046 @M @âm
  Kịch bản: US-14-046 âm 2 · Quá số lần thử lại
    Biết có ít nhất một phiên đồng bộ
    Khi quá số lần thử lại
    Thì hệ thống từ chối với ERR-14-004 (409)
    Và người dùng thấy thông báo "Bản ghi đã thử lại tối đa {n} lần. Xử lý thủ công hoặc ghi nhận."

  # ---- EP-14-H · Giám sát, nhật ký và đối soát

  @US-14-047 @FR-14-047 @M
  Kịch bản: US-14-047 dương · Kiểm tra kết nối chủ động
    Biết nền tảng ở trạng thái từ `DRAFT` trở đi; địa chỉ nằm trong egress
    Khi bộ chạy kiểm tra mỗi `14.health.interval-seconds` (mặc định 60 giây ở môi trường thật, 300 giây ở môi trường khác); người dùng bấm "Kiểm tra kết nối" ở UI-14-02 hoặc UI-14-03
    Thì hệ thống trả `200`; `steps[]` (`name`, `result`, `durationMs`, `hint`), `health`, `checkedAt`
    Và mẫu sức khỏe được lưu 90 ngày (gộp theo giờ sau 7 ngày); thời gian gián đoạn được ghi
    Và sự kiện được phát: EVT-14-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-047 @FR-14-047 @M @âm
  Kịch bản: US-14-047 âm 1 · Vượt số lần kiểm tra tay mỗi giờ
    Biết nền tảng ở trạng thái từ `DRAFT` trở đi; địa chỉ nằm trong egress
    Khi vượt số lần kiểm tra tay mỗi giờ
    Thì hệ thống từ chối với ERR-14-029 (429)
    Và người dùng thấy thông báo "Đã kiểm tra quá {n} lần trong một giờ. Thử lại sau {phút} phút."

  @US-14-047 @FR-14-047 @M @âm
  Kịch bản: US-14-047 âm 2 · Địa chỉ ngoài danh sách egress
    Biết nền tảng ở trạng thái từ `DRAFT` trở đi; địa chỉ nằm trong egress
    Khi địa chỉ ngoài danh sách egress
    Thì kết quả `EGRESS_DENIED` (không phải lỗi HTTP); người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Địa chỉ chưa được phép đi ra ngoài. Đề nghị quản trị tỉnh bổ sung vào danh sách đích."

  @US-14-048 @FR-14-048 @M
  Kịch bản: US-14-048 dương · Tổng quan kết nối quốc gia
    Biết người dùng đã chọn tenant
    Khi người dùng mở UI-14-01 (trang đầu của phân hệ); màn tự làm mới mỗi 30 giây
    Thì hệ thống trả `200`; `platforms[]`, `kpis`, `quotas[]` (kèm `forecastExhaustAt`), `alerts[]`

  @US-14-048 @FR-14-048 @M @âm
  Kịch bản: US-14-048 âm 1 · Kho chỉ số không phản hồi
    Biết người dùng đã chọn tenant
    Khi kho chỉ số không phản hồi
    Thì không có mã lỗi riêng; vùng biểu đồ hiển thị thông báo
    Và người dùng thấy thông báo "Chưa lấy được số liệu lưu lượng. Thử lại sau."

  @US-14-049 @FR-14-049 @M
  Kịch bản: US-14-049 dương · Tra cứu và đối soát giao dịch
    Biết có giao dịch trong khoảng tra
    Khi người dùng mở UI-14-12, nhập mã vào ô tra nhanh hoặc đặt bộ lọc
    Thì hệ thống trả `200`; danh sách `items[]` hoặc chi tiết giao dịch; `ETag` cho chi tiết
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-049 @FR-14-049 @M @âm
  Kịch bản: US-14-049 âm 1 · Không tìm thấy giao dịch hoặc thuộc tenant khác
    Biết có giao dịch trong khoảng tra
    Khi không tìm thấy giao dịch hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-14-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy giao dịch {mã}."

  @US-14-049 @FR-14-049 @M @âm
  Kịch bản: US-14-049 âm 2 · Khoảng thời gian quá rộng
    Biết có giao dịch trong khoảng tra
    Khi khoảng thời gian quá rộng
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tra tối đa 92 ngày."

  @US-14-050 @FR-14-050 @M
  Kịch bản: US-14-050 dương · Xem nội dung bản tin đầy đủ có lý do
    Biết giao dịch còn nội dung lưu (trong `14.txn.payload-retention-days`, mặc định 30 ngày); người dùng đã xác thực nhiều yếu tố trong phiên
    Khi SO bấm "Xem nội dung đầy đủ" ở chi tiết giao dịch (UI-14-12)
    Thì hệ thống trả `200`; `payload` (đã giải mã, chỉ trong phản hồi này), `expiresInSeconds = 60`
    Và có bản ghi kiểm toán không xóa được; nội dung không được lưu vào nhật ký thường hay bộ nhớ đệm trình duyệt
    Và sự kiện được phát: EVT-14-16 khi vượt ngưỡng xem trong ngày
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-050 @FR-14-050 @M @âm
  Kịch bản: US-14-050 âm 1 · Chưa xác thực lại
    Biết giao dịch còn nội dung lưu (trong `14.txn.payload-retention-days`, mặc định 30 ngày); người dùng đã xác thực nhiều yếu tố trong phiên
    Khi chưa xác thực lại
    Thì hệ thống từ chối với ERR-14-030 (403)
    Và người dùng thấy thông báo "Cần xác thực lại bằng yếu tố thứ hai để xem nội dung đầy đủ."

  @US-14-050 @FR-14-050 @M @âm
  Kịch bản: US-14-050 âm 2 · Nội dung đã hết hạn lưu hoặc không được lưu
    Biết giao dịch còn nội dung lưu (trong `14.txn.payload-retention-days`, mặc định 30 ngày); người dùng đã xác thực nhiều yếu tố trong phiên
    Khi nội dung đã hết hạn lưu hoặc không được lưu
    Thì hệ thống từ chối với ERR-14-031 (404)
    Và người dùng thấy thông báo "Nội dung bản tin đã quá thời hạn lưu hoặc tỉnh không bật lưu nội dung."

  @US-14-051 @FR-14-051 @S
  Kịch bản: US-14-051 dương · Xuất bằng chứng giao dịch
    Biết các giao dịch cần xuất tồn tại trong tenant
    Khi SO chọn giao dịch ở UI-14-12 và bấm "Xuất bằng chứng"
    Thì hệ thống trả `202` hoặc `200`; liên kết tải, `expiresAt`, `signatureRef`
    Và tệp xuất tự xóa sau 24 giờ; việc xuất được ghi kiểm toán
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-051 @FR-14-051 @S @âm
  Kịch bản: US-14-051 âm 1 · Quá 100 giao dịch
    Biết các giao dịch cần xuất tồn tại trong tenant
    Khi quá 100 giao dịch
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Mỗi lần xuất tối đa 100 giao dịch."

  @US-14-052 @FR-14-052 @M
  Kịch bản: US-14-052 dương · Nhật ký khai thác theo HTTT và báo cáo sử dụng
    Biết có giao dịch trong khoảng báo cáo
    Khi người dùng mở UI-14-13 và chọn khoảng thời gian, nhóm theo
    Thì hệ thống trả `200`; `rows[]` (`group`, `calls`, `cacheHits`, `errorRatio`, `records`, `quotaShare`); tệp xuất khi yêu cầu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-052 @FR-14-052 @M @âm
  Kịch bản: US-14-052 âm 1 · Khoảng thời gian quá rộng
    Biết có giao dịch trong khoảng báo cáo
    Khi khoảng thời gian quá rộng
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Khoảng thời gian báo cáo tối đa 92 ngày."

  @US-14-052 @FR-14-052 @M @âm
  Kịch bản: US-14-052 âm 2 · Tổng hợp chưa sẵn sàng cho giờ hiện tại
    Biết có giao dịch trong khoảng báo cáo
    Khi tổng hợp chưa sẵn sàng cho giờ hiện tại
    Thì hiển thị ghi chú thông báo; không có mã lỗi
    Và người dùng thấy thông báo "Số liệu giờ hiện tại đang được tổng hợp"

  @US-14-053 @FR-14-053 @S
  Kịch bản: US-14-053 dương · Cảnh báo bất thường khai thác
    Biết có dữ liệu `usage_hourly` ít nhất 7 ngày để có đường chuẩn
    Khi bộ phân tích chạy mỗi 15 phút; SO mở UI-14-13
    Thì hệ thống trả `200`; danh sách cảnh báo; chi tiết với `evidence`, `state`, `decision`
    Và mỗi cảnh báo có quyết định; cảnh báo giữ 5 năm
    Và sự kiện được phát: EVT-14-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-053 @FR-14-053 @S @âm
  Kịch bản: US-14-053 âm 1 · Kết thúc cảnh báo mà chưa nhập lý do
    Biết có dữ liệu `usage_hourly` ít nhất 7 ngày để có đường chuẩn
    Khi kết thúc cảnh báo mà chưa nhập lý do
    Thì hệ thống từ chối với ERR-14-003 (400)
    Và người dùng thấy thông báo "Nhập lý do khi xác nhận hợp lệ hoặc đề nghị thu hồi."

  # ---- EP-14-I · Quản trị và chuyển đổi

  @US-14-054 @FR-14-054 @M
  Kịch bản: US-14-054 dương · Tham số phân hệ theo tenant
    Biết PH-18 sẵn sàng (nếu không, dùng bản đệm 60 giây rồi giá trị mặc định)
    Khi TA mở UI-14-16 và bấm "Sửa"
    Thì hệ thống trả `200`; `settings[]` (`key`, `value`, `default`, `range`, `security`); `202` khi chờ duyệt
    Và giá trị mới có hiệu lực trong 30 giây; lịch sử thay đổi xem được
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-054 @FR-14-054 @M @âm
  Kịch bản: US-14-054 âm 1 · Giá trị ngoài miền hoặc mâu thuẫn
    Biết PH-18 sẵn sàng (nếu không, dùng bản đệm 60 giây rồi giá trị mặc định)
    Khi giá trị ngoài miền hoặc mâu thuẫn
    Thì hệ thống từ chối với ERR-14-036 (422)
    Và người dùng thấy thông báo "Giá trị của {khóa} phải nằm trong {miền}."

  @US-14-054 @FR-14-054 @M @âm
  Kịch bản: US-14-054 âm 2 · Người duyệt trùng người sửa
    Biết PH-18 sẵn sàng (nếu không, dùng bản đệm 60 giây rồi giá trị mặc định)
    Khi người duyệt trùng người sửa
    Thì hệ thống từ chối với ERR-14-007 (403)
    Và người dùng thấy thông báo "Bạn không thể tự duyệt thay đổi tham số do mình sửa."

  @US-14-055 @FR-14-055 @S
  Kịch bản: US-14-055 dương · Chạy song song với kết nối NGSP cũ và đối chiếu
    Biết dịch vụ mới `ACTIVE` ở PH-14; thông tin xác thực mới đã cấp (không dùng khóa của hệ cũ)
    Khi TA mở UI-14-15 và bấm "Bắt đầu chạy song song" cho một dịch vụ
    Thì hệ thống trả `201` phiên; `200` với `matchRatio`, `samples`, `differences[]`, `readyForCutover`
    Và mẫu và khác biệt lưu 90 ngày; đóng phiên chỉ khi đã xác nhận thu hồi khóa cũ
    Và sự kiện được phát: EVT-14-12 (kết thúc phiên)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-055 @FR-14-055 @S @âm
  Kịch bản: US-14-055 âm 1 · Dịch vụ là thao tác ghi
    Biết dịch vụ mới `ACTIVE` ở PH-14; thông tin xác thực mới đã cấp (không dùng khóa của hệ cũ)
    Khi dịch vụ là thao tác ghi
    Thì hệ thống từ chối với ERR-14-033 (409)
    Và người dùng thấy thông báo "Chỉ chạy song song cho thao tác đọc, để không ghi trùng lên hệ thống quốc gia."

  @US-14-056 @FR-14-056 @S
  Kịch bản: US-14-056 dương · Nhập cấu hình dịch vụ từ hệ cũ
    Biết có tệp đã chuẩn bị theo mẫu: mã cũ, tên, `Service-code`, nhóm, loại thao tác
    Khi IE bấm "Nhập từ hệ cũ" ở UI-14-15
    Thì hệ thống trả `200` (xem trước) hoặc `201` (ghi); báo cáo `created`, `skipped`, `duplicates`, `secretsFound[]` (chỉ vị trí), `legacyMap` (tải về)
    Và dịch vụ ở `DRAFT`; không bí mật nào được lưu; tệp tải lên bị xóa sau xử lý
    Và sự kiện được phát: EVT-14-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-056 @FR-14-056 @S @âm
  Kịch bản: US-14-056 âm 1 · Tệp không hợp lệ
    Biết có tệp đã chuẩn bị theo mẫu: mã cũ, tên, `Service-code`, nhóm, loại thao tác
    Khi tệp không hợp lệ
    Thì hệ thống từ chối với ERR-14-032 (422)
    Và người dùng thấy thông báo "Dòng {n}, cột {tên}: {lý do}. Chưa có dữ liệu nào được nhập."

  @US-14-057 @FR-14-057 @C
  Kịch bản: US-14-057 dương · Báo cáo hạn mức và hiệu quả đệm
    Biết có dữ liệu `quota_usage` và `usage_hourly` trong kỳ báo cáo
    Khi hằng tháng theo lịch (ngày 01, 07:00), hoặc người dùng bấm "Lập báo cáo" ở UI-14-13
    Thì hệ thống trả `202` rồi `200`; liên kết tải, `expiresAt`
    Và báo cáo lưu 30 ngày; không thay đổi dữ liệu nguồn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-14-057 @FR-14-057 @C @âm
  Kịch bản: US-14-057 âm 1 · Không có dữ liệu trong kỳ
    Biết có dữ liệu `quota_usage` và `usage_hourly` trong kỳ báo cáo
    Khi không có dữ liệu trong kỳ
    Thì hệ thống từ chối với ERR-14-001 (404)
    Và người dùng thấy thông báo "Chưa có dữ liệu sử dụng trong kỳ này."
