# language: vi
# Sinh tự động từ D02-02/D02-03-PH09 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-09
Tính năng: PH-09 · Quyền riêng tư

  # ---- EP-09-A · Phân loại dữ liệu

  @US-09-001 @FR-09-001 @M
  Kịch bản: US-09-001 dương · Quản lý danh mục mức phân loại và nhãn chặn bí mật nhà nước
    Biết tenant đã khởi tạo (BP-08); bốn mức được nạp sẵn
    Khi mở tab "Mức phân loại" ở UI-09-02 hoặc nạp lúc khởi tạo tenant
    Thì hệ thống trả `200`; danh sách mức kèm `rank`, `fieldCount`, `ETag`
    Và danh mục có phiên bản mới; không đổi phân loại của trường
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-001 @FR-09-001 @M @âm
  Kịch bản: US-09-001 âm 1 · Ngừng mức hoặc đổi `code`, `rank` của bốn mức cố định
    Biết tenant đã khởi tạo (BP-08); bốn mức được nạp sẵn
    Khi ngừng mức hoặc đổi `code`, `rank` của bốn mức cố định
    Thì hệ thống từ chối với ERR-09-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."

  @US-09-001 @FR-09-001 @M @âm
  Kịch bản: US-09-001 âm 2 · Sửa lệch phiên bản
    Biết tenant đã khởi tạo (BP-08); bốn mức được nạp sẵn
    Khi sửa lệch phiên bản
    Thì hệ thống từ chối với ERR-09-004 (409)
    Và người dùng thấy thông báo "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới."

  @US-09-002 @FR-09-002 @M
  Kịch bản: US-09-002 dương · Quản lý danh mục loại dữ liệu cá nhân
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mở tab "Loại dữ liệu cá nhân" ở UI-09-02, hoặc nạp gói nền lúc khởi tạo tenant
    Thì hệ thống trả `201` hoặc `200`; loại kèm `fieldCount`
    Và loại mới chọn được ở FR-09-004; không đổi phân loại hiện có
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-002 @FR-09-002 @M @âm
  Kịch bản: US-09-002 âm 1 · Mã trùng
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mã trùng
    Thì hệ thống từ chối với ERR-09-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-09-002 @FR-09-002 @M @âm
  Kịch bản: US-09-002 âm 2 · Ngừng loại đang được trường dùng
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ngừng loại đang được trường dùng
    Thì hệ thống từ chối với ERR-09-011 (409)
    Và người dùng thấy thông báo "Mục {mã} đang được {n} trường sử dụng nên không ngừng được."

  @US-09-003 @FR-09-003 @M
  Kịch bản: US-09-003 dương · Đăng ký phần tử dữ liệu từ phân hệ, lược đồ API, topic và khai báo MVP
    Biết đích đăng ký thuộc tenant; với khai báo MVP, kho mã đã quét
    Khi phân hệ gọi đăng ký khi đăng ký hoặc đổi hợp đồng; người dùng nhập lược đồ ở UI-09-02; chạy di trú khai báo MVP một lần khi bật PH-09
    Thì hệ thống trả `202` cho lô hoặc `201`; số phần tử `created`, `updated`, `rejected`
    Và mỗi phần tử có `ElementClassification` ở `PROPOSED`; mức hợp đồng liên quan tính lại
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-003 @FR-09-003 @M @âm
  Kịch bản: US-09-003 âm 1 · Phần tử trùng khi đăng ký đơn
    Biết đích đăng ký thuộc tenant; với khai báo MVP, kho mã đã quét
    Khi phần tử trùng khi đăng ký đơn
    Thì hệ thống từ chối với ERR-09-014 (409)
    Và người dùng thấy thông báo "Phần tử {đích} đã được đăng ký."

  @US-09-003 @FR-09-003 @M @âm
  Kịch bản: US-09-003 âm 2 · Lược đồ không đọc được
    Biết đích đăng ký thuộc tenant; với khai báo MVP, kho mã đã quét
    Khi lược đồ không đọc được
    Thì hệ thống từ chối với ERR-09-015 (422)
    Và người dùng thấy thông báo "Không đọc được lược đồ: {lý do}."

  @US-09-004 @FR-09-004 @M
  Kịch bản: US-09-004 dương · Đề xuất, xác nhận phân loại trường (hạ mức cần bốn mắt)
    Biết phần tử đã đăng ký (FR-09-003)
    Khi người dùng bấm "Đề xuất phân loại" ở UI-09-03 hoặc "Xác nhận" ở UI-09-02; PH-06 đăng ký phân loại thuộc tính ở `PROPOSED` (FR-06-004)
    Thì hệ thống trả `200`; phân loại kèm `classificationStatus`, `version`
    Và một dòng `CONFIRMED` cho mỗi phần tử; lịch sử đầy đủ
    Và sự kiện được phát: EVT-09-01; EVT-09-03 khi mức hợp đồng đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-004 @FR-09-004 @M @âm
  Kịch bản: US-09-004 âm 1 · Người xác nhận ngoài tổ chức sở hữu
    Biết phần tử đã đăng ký (FR-09-003)
    Khi người xác nhận ngoài tổ chức sở hữu
    Thì hệ thống từ chối với ERR-09-008 (403)
    Và người dùng thấy thông báo "Bạn chỉ thao tác được trên dữ liệu thuộc tổ chức của mình."

  @US-09-004 @FR-09-004 @M @âm
  Kịch bản: US-09-004 âm 2 · Trường DLCN thiếu loại hoặc loại không khớp mức khi xác nhận
    Biết phần tử đã đăng ký (FR-09-003)
    Khi trường DLCN thiếu loại hoặc loại không khớp mức khi xác nhận
    Thì hệ thống từ chối với ERR-09-012 (422)
    Và người dùng thấy thông báo "Trường {tên} là dữ liệu cá nhân, cần chọn loại dữ liệu cá nhân phù hợp."

  @US-09-005 @FR-09-005 @S
  Kịch bản: US-09-005 dương · Quét phát hiện trường nghi dữ liệu cá nhân chưa phân loại
    Biết có phần tử chưa `CONFIRMED` hoặc lược đồ mô tả tên cột; nguồn quét có tài khoản chỉ đọc (PH-06, bảng nghiệp vụ DU)
    Khi bấm "Quét" ở UI-09-04 hoặc lịch `09.scan.schedule-cron`
    Thì hệ thống trả `202`; `scanId`; kết quả `findings[]` có `column`, `detector`, `matchRate`
    Và quét không đổi phân loại
    Và sự kiện được phát: EVT-09-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-005 @FR-09-005 @S @âm
  Kịch bản: US-09-005 âm 1 · Nguồn quét không khả dụng
    Biết có phần tử chưa `CONFIRMED` hoặc lược đồ mô tả tên cột; nguồn quét có tài khoản chỉ đọc (PH-06, bảng nghiệp vụ DU)
    Khi nguồn quét không khả dụng
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-006 @FR-09-006 @M
  Kịch bản: US-09-006 dương · Tính và công bố mức phân loại của hợp đồng API, topic, luồng
    Biết hợp đồng có phần tử đã đăng ký
    Khi đăng ký hoặc đổi hợp đồng; phân loại đổi (FR-09-004); gọi tính lại
    Thì hệ thống trả `200`; `{kind, contractId, level, provisional, fieldCounts, computedAt}`
    Và mức cập nhật trong 60 giây sau đổi phân loại (NFR-09-010)
    Và sự kiện được phát: EVT-09-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-006 @FR-09-006 @M @âm
  Kịch bản: US-09-006 âm 1 · Không thấy hợp đồng
    Biết hợp đồng có phần tử đã đăng ký
    Khi không thấy hợp đồng
    Thì hệ thống từ chối với ERR-09-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã}."

  @US-09-006 @FR-09-006 @M @âm
  Kịch bản: US-09-006 âm 2 · Phân hệ gọi tới không khả dụng
    Biết hợp đồng có phần tử đã đăng ký
    Khi phân hệ gọi tới không khả dụng
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-007 @FR-09-007 @M
  Kịch bản: US-09-007 dương · Chặn dữ liệu bí mật nhà nước đi qua Datahub
    Biết nhãn `STATE_SECRET` nạp ở FR-09-001; danh mục nhãn của tenant do cán bộ bảo vệ bí mật nhà nước cung cấp (Q09-06)
    Khi gán nhãn ở UI-09-03; bản tin vào chặng `schema` của PH-04 hoặc PH-14 gọi kiểm tra
    Thì kiểm tra: `200` với `{blocked:false}` hoặc `403` ERR-09-101 không nêu chi tiết; với `egressScope` là `OUT_OF_PROVINCE` thêm `egressBlocked`, `egressBlockedFields[]`, p95 ≤ 200 ms (NFR-09-027)
    Và nhãn có hiệu lực trong chỉ mục phân loại ≤ 60 giây
    Và sự kiện được phát: EVT-09-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-007 @FR-09-007 @M @âm
  Kịch bản: US-09-007 âm 1 · Có nhãn khi đăng ký
    Biết nhãn `STATE_SECRET` nạp ở FR-09-001; danh mục nhãn của tenant do cán bộ bảo vệ bí mật nhà nước cung cấp (Q09-06)
    Khi có nhãn khi đăng ký
    Thì hệ thống từ chối với ERR-09-018 (422)
    Và người dùng thấy thông báo "Dữ liệu mang nhãn bí mật nhà nước không được đưa vào Datahub."

  @US-09-007 @FR-09-007 @M @âm
  Kịch bản: US-09-007 âm 2 · Chặn trên đường dữ liệu
    Biết nhãn `STATE_SECRET` nạp ở FR-09-001; danh mục nhãn của tenant do cán bộ bảo vệ bí mật nhà nước cung cấp (Q09-06)
    Khi chặn trên đường dữ liệu
    Thì hệ thống từ chối với ERR-09-101 (403)
    Và người dùng thấy thông báo "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."

  @US-09-008 @FR-09-008 @S
  Kịch bản: US-09-008 dương · Tra cứu, xuất danh mục phân loại và lịch sử thay đổi
    Biết có phần tử đã đăng ký
    Khi lọc ở UI-09-02, bấm "Xuất" hoặc mở tab "Lịch sử" ở UI-09-03
    Thì hệ thống trả `200` danh sách; xuất `202` với `exportId`, tải trong 24 giờ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-008 @FR-09-008 @S @âm
  Kịch bản: US-09-008 âm 1 · Khoảng thời gian quá lớn
    Biết có phần tử đã đăng ký
    Khi khoảng thời gian quá lớn
    Thì hệ thống từ chối với ERR-09-036 (422)
    Và người dùng thấy thông báo "Chọn khoảng thời gian tối đa 12 tháng."

  # ---- EP-09-B · Sổ hoạt động xử lý dữ liệu cá nhân

  @US-09-009 @FR-09-009 @M
  Kịch bản: US-09-009 dương · Lập hoạt động xử lý dữ liệu cá nhân
    Biết danh mục loại DLCN (FR-09-002) và cơ sở pháp lý (FR-09-012) đã có
    Khi bấm "Thêm hoạt động xử lý" ở UI-09-05
    Thì hệ thống trả `201`; hoạt động kèm `activityId`, `version`, `status`
    Và `ProcessingActivity` phiên bản 1 `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-009 @FR-09-009 @M @âm
  Kịch bản: US-09-009 âm 1 · Mã trùng
    Biết danh mục loại DLCN (FR-09-002) và cơ sở pháp lý (FR-09-012) đã có
    Khi mã trùng
    Thì hệ thống từ chối với ERR-09-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-09-009 @FR-09-009 @M @âm
  Kịch bản: US-09-009 âm 2 · Thiếu mục bắt buộc
    Biết danh mục loại DLCN (FR-09-002) và cơ sở pháp lý (FR-09-012) đã có
    Khi thiếu mục bắt buộc
    Thì hệ thống từ chối với ERR-09-020 (422)
    Và người dùng thấy thông báo "Hoạt động xử lý còn thiếu: {danh sách mục}."

  @US-09-010 @FR-09-010 @M
  Kịch bản: US-09-010 dương · Duyệt, phiên bản hóa hoạt động xử lý
    Biết hoạt động `DRAFT` đầy đủ mục
    Khi bấm "Gửi duyệt" hoặc "Duyệt" ở UI-09-05
    Thì hệ thống trả `200`; hoạt động kèm `status`, `version`, `approvedBy`
    Và mỗi hoạt động có tối đa một phiên bản `ACTIVE`
    Và sự kiện được phát: EVT-09-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-010 @FR-09-010 @M @âm
  Kịch bản: US-09-010 âm 1 · Ngừng hoạt động còn liên kết
    Biết hoạt động `DRAFT` đầy đủ mục
    Khi ngừng hoạt động còn liên kết
    Thì hệ thống từ chối với ERR-09-022 (409)
    Và người dùng thấy thông báo "Hoạt động còn {n} liên kết đang hiệu lực. Gỡ liên kết trước khi ngừng."

  @US-09-010 @FR-09-010 @M @âm
  Kịch bản: US-09-010 âm 2 · Thiếu lý do
    Biết hoạt động `DRAFT` đầy đủ mục
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-09-007 (422)
    Và người dùng thấy thông báo "Nhập lý do tối thiểu 20 ký tự."

  @US-09-011 @FR-09-011 @M
  Kịch bản: US-09-011 dương · Liên kết hoạt động xử lý với trường, API, topic, luồng
    Biết hoạt động tồn tại; phần tử, hợp đồng đã đăng ký
    Khi tab "Liên kết" ở UI-09-06; thẻ cảnh báo "trường chưa thuộc hoạt động" ở UI-09-05
    Thì hệ thống trả `200`; danh sách liên kết, `uncoveredCount`
    Và liên kết thuộc phiên bản hoạt động, không sửa tại chỗ khi `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-011 @FR-09-011 @M @âm
  Kịch bản: US-09-011 âm 1 · Còn trường chưa thuộc hoạt động khi kích hoạt hợp đồng
    Biết hoạt động tồn tại; phần tử, hợp đồng đã đăng ký
    Khi còn trường chưa thuộc hoạt động khi kích hoạt hợp đồng
    Thì hệ thống từ chối với ERR-09-023 (422)
    Và người dùng thấy thông báo "Có {n} trường dữ liệu cá nhân chưa thuộc hoạt động xử lý nào."

  @US-09-011 @FR-09-011 @M @âm
  Kịch bản: US-09-011 âm 2 · Đối tượng không có
    Biết hoạt động tồn tại; phần tử, hợp đồng đã đăng ký
    Khi đối tượng không có
    Thì hệ thống từ chối với ERR-09-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã}."

  @US-09-012 @FR-09-012 @M
  Kịch bản: US-09-012 dương · Quản lý danh mục cơ sở pháp lý và căn cứ văn bản
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tab "Cơ sở pháp lý" ở UI-09-07
    Thì hệ thống trả `201` hoặc `200`
    Và hoạt động liên quan có cờ `needsReview` khi văn bản hết hiệu lực
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-012 @FR-09-012 @M @âm
  Kịch bản: US-09-012 âm 1 · Mã trùng
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mã trùng
    Thì hệ thống từ chối với ERR-09-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-09-012 @FR-09-012 @M @âm
  Kịch bản: US-09-012 âm 2 · Văn bản không còn hiệu lực khi chọn
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi văn bản không còn hiệu lực khi chọn
    Thì hệ thống từ chối với ERR-09-021 (422)
    Và người dùng thấy thông báo "Văn bản căn cứ {mã} không còn hiệu lực. Chọn căn cứ khác."

  @US-09-013 @FR-09-013 @S
  Kịch bản: US-09-013 dương · Xuất sổ hoạt động xử lý theo mẫu
    Biết có hoạt động `ACTIVE`
    Khi bấm "Xuất sổ" ở UI-09-05
    Thì hệ thống trả `202`; `exportId`; tệp khi xong
    Và bản ghi xuất lưu 24 giờ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-013 @FR-09-013 @S @âm
  Kịch bản: US-09-013 âm 1 · Mẫu không có
    Biết có hoạt động `ACTIVE`
    Khi mẫu không có
    Thì hệ thống từ chối với ERR-09-025 (422)
    Và người dùng thấy thông báo "Mẫu xuất {mã} không tồn tại."

  # ---- EP-09-C · Mục đích và chấp thuận khai thác

  @US-09-014 @FR-09-014 @M
  Kịch bản: US-09-014 dương · Quản lý danh mục mục đích khai thác
    Biết cơ sở pháp lý có sẵn (FR-09-012)
    Khi tab "Mục đích" ở UI-09-07
    Thì hệ thống trả `201` hoặc `200`
    Và mục đích `ACTIVE` chọn được ở FR-09-015
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-014 @FR-09-014 @M @âm
  Kịch bản: US-09-014 âm 1 · Ngừng mục đích còn chấp thuận hiệu lực
    Biết cơ sở pháp lý có sẵn (FR-09-012)
    Khi ngừng mục đích còn chấp thuận hiệu lực
    Thì hệ thống từ chối với ERR-09-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-09-014 @FR-09-014 @M @âm
  Kịch bản: US-09-014 âm 2 · Mã trùng
    Biết cơ sở pháp lý có sẵn (FR-09-012)
    Khi mã trùng
    Thì hệ thống từ chối với ERR-09-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-09-015 @FR-09-015 @M
  Kịch bản: US-09-015 dương · Lập yêu cầu khai thác theo mục đích
    Biết HTTT `ACTIVE` ở PH-01; có đăng ký sử dụng ở PH-02; mục đích `ACTIVE`
    Khi bấm "Lập yêu cầu" ở UI-09-08
    Thì hệ thống trả `201`; yêu cầu kèm `requestId`, `status`
    Và `AccessRequest` ở `SUBMITTED`
    Và sự kiện được phát: EVT-09-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-015 @FR-09-015 @M @âm
  Kịch bản: US-09-015 âm 1 · HTTT chưa hoạt động
    Biết HTTT `ACTIVE` ở PH-01; có đăng ký sử dụng ở PH-02; mục đích `ACTIVE`
    Khi HTTT chưa hoạt động
    Thì hệ thống từ chối với ERR-09-027 (422)
    Và người dùng thấy thông báo "HTTT {mã} chưa hoạt động hoặc chưa có đăng ký sử dụng hợp lệ."

  @US-09-015 @FR-09-015 @M @âm
  Kịch bản: US-09-015 âm 2 · Trường ngoài phạm vi
    Biết HTTT `ACTIVE` ở PH-01; có đăng ký sử dụng ở PH-02; mục đích `ACTIVE`
    Khi trường ngoài phạm vi
    Thì hệ thống từ chối với ERR-09-028 (422)
    Và người dùng thấy thông báo "Trường {tên} nằm ngoài phạm vi của mục đích {mã}."

  @US-09-016 @FR-09-016 @M
  Kịch bản: US-09-016 dương · Thẩm định, chấp thuận có điều kiện hoặc từ chối yêu cầu khai thác
    Biết yêu cầu `SUBMITTED` hoặc `UNDER_REVIEW`
    Khi mở việc ở UI-09-09 (hộp việc chấp thuận)
    Thì hệ thống trả `200`; yêu cầu kèm `grantId` khi chấp thuận
    Và chấp thuận ghi vào bundle kế tiếp
    Và sự kiện được phát: EVT-09-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-016 @FR-09-016 @M @âm
  Kịch bản: US-09-016 âm 1 · Duyệt yêu cầu của chính mình
    Biết yêu cầu `SUBMITTED` hoặc `UNDER_REVIEW`
    Khi duyệt yêu cầu của chính mình
    Thì hệ thống từ chối với ERR-09-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

  @US-09-016 @FR-09-016 @M @âm
  Kịch bản: US-09-016 âm 2 · Ngoài tổ chức
    Biết yêu cầu `SUBMITTED` hoặc `UNDER_REVIEW`
    Khi ngoài tổ chức
    Thì hệ thống từ chối với ERR-09-008 (403)
    Và người dùng thấy thông báo "Bạn chỉ thao tác được trên dữ liệu thuộc tổ chức của mình."

  @US-09-017 @FR-09-017 @M
  Kịch bản: US-09-017 dương · Gia hạn, sửa, tạm dừng, thu hồi chấp thuận và tự hết hạn
    Biết chấp thuận ở `ACTIVE` hoặc `SUSPENDED`
    Khi hành động ở UI-09-09 hoặc UI-09-08; việc định kỳ mỗi 5 phút
    Thì hệ thống trả `200`; chấp thuận kèm `status`, `revision`
    Và bundle chứa phiên bản chấp thuận mới
    Và sự kiện được phát: EVT-09-06, EVT-09-07, EVT-09-08, EVT-09-09, EVT-09-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-017 @FR-09-017 @M @âm
  Kịch bản: US-09-017 âm 1 · Gia hạn quá số lần
    Biết chấp thuận ở `ACTIVE` hoặc `SUSPENDED`
    Khi gia hạn quá số lần
    Thì hệ thống từ chối với ERR-09-031 (422)
    Và người dùng thấy thông báo "Chấp thuận đã gia hạn tối đa {n} lần. Lập yêu cầu mới."

  @US-09-017 @FR-09-017 @M @âm
  Kịch bản: US-09-017 âm 2 · Thao tác sai trạng thái
    Biết chấp thuận ở `ACTIVE` hoặc `SUSPENDED`
    Khi thao tác sai trạng thái
    Thì hệ thống từ chối với ERR-09-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-09-018 @FR-09-018 @M
  Kịch bản: US-09-018 dương · Đồng bộ chấp thuận và chính sách sang bundle OPA có ký
    Biết OpenBao transit khả dụng; kho `dh-policies` có Rego đã kiểm thử
    Khi sự kiện đổi chấp thuận, chính sách che, phân loại; làm mới định kỳ 30 phút; bấm phát hành
    Thì hệ thống trả `200`; `{bundleId, signedAt, validUntil, sizeBytes, loadedBy[]}`
    Và bundle bất biến, giữ 90 ngày
    Và sự kiện được phát: EVT-09-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-018 @FR-09-018 @M @âm
  Kịch bản: US-09-018 âm 1 · OpenBao không khả dụng
    Biết OpenBao transit khả dụng; kho `dh-policies` có Rego đã kiểm thử
    Khi OpenBao không khả dụng
    Thì hệ thống từ chối với ERR-09-032 (503)
    Và người dùng thấy thông báo "Chưa ký được gói chính sách vì OpenBao không khả dụng. Gói cũ vẫn có hiệu lực."

  @US-09-018 @FR-09-018 @M @âm
  Kịch bản: US-09-018 âm 2 · Bundle không qua kiểm thử
    Biết OpenBao transit khả dụng; kho `dh-policies` có Rego đã kiểm thử
    Khi bundle không qua kiểm thử
    Thì hệ thống từ chối với ERR-09-033 (422)
    Và người dùng thấy thông báo "Gói chính sách không qua kiểm thử: {lỗi}. Không phát hành."

  @US-09-019 @FR-09-019 @M
  Kịch bản: US-09-019 dương · Quyết định mục đích trực tuyến cho điểm thực thi (data plane)
    Biết bundle hiện hành đã nạp ở PH-09; bên gọi có SPIFFE ID hợp lệ
    Khi mỗi lời gọi tới hợp đồng mức `RESTRICTED` trở lên khi điểm thực thi cần quyết định
    Thì hệ thống trả `200` với `decision` `ALLOW` hoặc `DENY` (không dùng HTTP lỗi cho DENY)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-019 @FR-09-019 @M @âm
  Kịch bản: US-09-019 âm 1 · Thiếu mục đích
    Biết bundle hiện hành đã nạp ở PH-09; bên gọi có SPIFFE ID hợp lệ
    Khi thiếu mục đích
    Thì hệ thống từ chối với ERR-09-103 (400)
    Và người dùng thấy thông báo "Thiếu mã mục đích hợp lệ trong yêu cầu."

  @US-09-019 @FR-09-019 @M @âm
  Kịch bản: US-09-019 âm 2 · Không có chấp thuận
    Biết bundle hiện hành đã nạp ở PH-09; bên gọi có SPIFFE ID hợp lệ
    Khi không có chấp thuận
    Thì hệ thống từ chối với ERR-09-102 (403)
    Và người dùng thấy thông báo "Không có chấp thuận mục đích còn hiệu lực cho yêu cầu này."

  @US-09-020 @FR-09-020 @S
  Kịch bản: US-09-020 dương · Phát hiện khai thác vượt mục đích, vượt hạn ngạch
    Biết điểm thực thi báo lượt khai thác (`usage-events:report`)
    Khi mỗi phút quét bộ đếm; sự kiện DENY liên tiếp
    Thì hệ thống trả `200`; danh sách cảnh báo
    Và cảnh báo có trạng thái xử lý
    Và sự kiện được phát: EVT-09-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-020 @FR-09-020 @S @âm
  Kịch bản: US-09-020 âm 1 · Ngưỡng sai
    Biết điểm thực thi báo lượt khai thác (`usage-events:report`)
    Khi ngưỡng sai
    Thì hệ thống từ chối với ERR-09-034 (422)
    Và người dùng thấy thông báo "Ngưỡng cảnh báo không hợp lệ."

  @US-09-021 @FR-09-021 @S
  Kịch bản: US-09-021 dương · Báo cáo khai thác theo mục đích
    Biết có bộ đếm khai thác
    Khi mở UI-09-09 tab "Báo cáo" hoặc xuất báo cáo
    Thì hệ thống trả `200`; bảng và chuỗi thời gian
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-021 @FR-09-021 @S @âm
  Kịch bản: US-09-021 âm 1 · Khoảng quá lớn
    Biết có bộ đếm khai thác
    Khi khoảng quá lớn
    Thì hệ thống từ chối với ERR-09-036 (422)
    Và người dùng thấy thông báo "Chọn khoảng thời gian tối đa 12 tháng."

  @US-09-022 @FR-09-022 @M
  Kịch bản: US-09-022 dương · Chặn kích hoạt hợp đồng mức Nhạy cảm khi chưa có mục đích và chấp thuận
    Biết mức hợp đồng đã tính (FR-09-006)
    Khi công bố hợp đồng ở PH-02, đăng ký sử dụng, kích hoạt luồng ở PH-04
    Thì hệ thống trả `200` `{allowed:false, missing:["CONFIRMED_CLASSIFICATION","ACTIVE_ACTIVITY","ACTIVE_GRANT"]}`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-022 @FR-09-022 @M @âm
  Kịch bản: US-09-022 âm 1 · Thiếu điều kiện
    Biết mức hợp đồng đã tính (FR-09-006)
    Khi thiếu điều kiện
    Thì hệ thống từ chối với ERR-09-035 (422)
    Và người dùng thấy thông báo "Hợp đồng {mã} chứa dữ liệu Nhạy cảm, cần mục đích và chấp thuận của chủ quản trước khi kích hoạt."

  @US-09-022 @FR-09-022 @M @âm
  Kịch bản: US-09-022 âm 2 · PH-09 không khả dụng
    Biết mức hợp đồng đã tính (FR-09-006)
    Khi PH-09 không khả dụng
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  # ---- EP-09-D · Chính sách che

  @US-09-023 @FR-09-023 @M
  Kịch bản: US-09-023 dương · Quản lý kiểu che và mẫu che
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mở UI-09-10 tab "Kiểu che"
    Thì hệ thống trả `200`; danh sách kiểu và mẫu
    Và mẫu có phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-023 @FR-09-023 @M @âm
  Kịch bản: US-09-023 âm 1 · Kiểu che không hợp kiểu dữ liệu
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi kiểu che không hợp kiểu dữ liệu
    Thì hệ thống từ chối với ERR-09-037 (422)
    Và người dùng thấy thông báo "Kiểu che {kiểu} không áp dụng được cho trường kiểu {kiểu dữ liệu}."

  @US-09-024 @FR-09-024 @M
  Kịch bản: US-09-024 dương · Soạn chính sách che theo mức, loại dữ liệu cá nhân, vai trò, mục đích, kênh
    Biết kiểu che có sẵn (FR-09-023); danh mục phân loại có dữ liệu
    Khi bấm "Tạo chính sách" hoặc "Sửa" ở UI-09-10
    Thì hệ thống trả `201` hoặc `200`; chính sách kèm `version`, số quy tắc
    Và chưa có hiệu lực cho tới khi `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-024 @FR-09-024 @M @âm
  Kịch bản: US-09-024 âm 1 · Quy tắc xung đột
    Biết kiểu che có sẵn (FR-09-023); danh mục phân loại có dữ liệu
    Khi quy tắc xung đột
    Thì hệ thống từ chối với ERR-09-038 (422)
    Và người dùng thấy thông báo "Chính sách có quy tắc trùng ưu tiên hoặc thiếu quy tắc mặc định cho mức Nhạy cảm."

  @US-09-024 @FR-09-024 @M @âm
  Kịch bản: US-09-024 âm 2 · Sửa phiên bản không phải nháp
    Biết kiểu che có sẵn (FR-09-023); danh mục phân loại có dữ liệu
    Khi sửa phiên bản không phải nháp
    Thì hệ thống từ chối với ERR-09-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-09-025 @FR-09-025 @S
  Kịch bản: US-09-025 dương · Mô phỏng chính sách che trên dữ liệu mẫu
    Biết có bản nháp chính sách
    Khi bấm "Mô phỏng" ở UI-09-11
    Thì hệ thống trả `200`; `{rows, diff, simulationId, result}`
    Và bản ghi mô phỏng không chứa dữ liệu mẫu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-025 @FR-09-025 @S @âm
  Kịch bản: US-09-025 âm 1 · Mẫu quá lớn
    Biết có bản nháp chính sách
    Khi mẫu quá lớn
    Thì hệ thống từ chối với ERR-09-039 (413)
    Và người dùng thấy thông báo "Dữ liệu mẫu tối đa 1.000 dòng."

  @US-09-026 @FR-09-026 @M
  Kịch bản: US-09-026 dương · Duyệt, phát hành, phiên bản hóa chính sách che
    Biết bản nháp có mô phỏng `PASSED`
    Khi bấm "Gửi duyệt", "Duyệt", "Quay lại" ở UI-09-10
    Thì hệ thống trả `200`; `status`, `version`, `activatedAt`
    Và một phiên bản `ACTIVE` mỗi chính sách
    Và sự kiện được phát: EVT-09-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-026 @FR-09-026 @M @âm
  Kịch bản: US-09-026 âm 1 · Chưa mô phỏng
    Biết bản nháp có mô phỏng `PASSED`
    Khi chưa mô phỏng
    Thì hệ thống từ chối với ERR-09-040 (422)
    Và người dùng thấy thông báo "Cần mô phỏng đạt trên bộ dữ liệu mẫu trước khi gửi duyệt."

  @US-09-026 @FR-09-026 @M @âm
  Kịch bản: US-09-026 âm 2 · Tự duyệt
    Biết bản nháp có mô phỏng `PASSED`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-09-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

  @US-09-027 @FR-09-027 @M
  Kịch bản: US-09-027 dương · Trả kế hoạch che trực tuyến cho điểm thực thi, đệm và đóng an toàn
    Biết có chính sách `ACTIVE` hoặc chính sách mặc định
    Khi điểm thực thi cần che một phản hồi, bản ghi hoặc tệp
    Thì hệ thống trả `200` hoặc `304`; kế hoạch như trên
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-027 @FR-09-027 @M @âm
  Kịch bản: US-09-027 âm 1 · Chưa lập được kế hoạch
    Biết có chính sách `ACTIVE` hoặc chính sách mặc định
    Khi chưa lập được kế hoạch
    Thì hệ thống từ chối với ERR-09-105 (503)
    Và người dùng thấy thông báo "Chưa lập được kế hoạch che, đang dùng chế độ đóng an toàn."

  @US-09-027 @FR-09-027 @M @âm
  Kịch bản: US-09-027 âm 2 · Bên gọi không được phép
    Biết có chính sách `ACTIVE` hoặc chính sách mặc định
    Khi bên gọi không được phép
    Thì hệ thống từ chối với ERR-09-111 (403)
    Và người dùng thấy thông báo "Bên gọi không được phép dùng API quyền riêng tư."

  @US-09-028 @FR-09-028 @M
  Kịch bản: US-09-028 dương · Áp che bản tin cho luồng PH-04
    Biết có `dh-data-classes` ở chặng `schema` và `dh-obligations` ở chặng `authz` (FR-04-067)
    Khi bản tin tới chặng `respond`
    Thì hệ thống trả `200`; bản tin đã che; p95 ≤ 30 ms (NFR-09-003)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-028 @FR-09-028 @M @âm
  Kịch bản: US-09-028 âm 1 · Bản tin quá lớn
    Biết có `dh-data-classes` ở chặng `schema` và `dh-obligations` ở chặng `authz` (FR-04-067)
    Khi bản tin quá lớn
    Thì hệ thống từ chối với ERR-09-107 (413)
    Và người dùng thấy thông báo "Bản tin hoặc lô vượt giới hạn cho phép."

  @US-09-028 @FR-09-028 @M @âm
  Kịch bản: US-09-028 âm 2 · Không ghi được vết
    Biết có `dh-data-classes` ở chặng `schema` và `dh-obligations` ở chặng `authz` (FR-04-067)
    Khi không ghi được vết
    Thì hệ thống từ chối với ERR-09-110 (503)
    Và người dùng thấy thông báo "Không ghi được nhật ký thao tác che, thao tác bị từ chối."

  @US-09-029 @FR-09-029 @M
  Kịch bản: US-09-029 dương · Xem giá trị đầy đủ có lý do trong 60 giây
    Biết người dùng có quyền ở phạm vi đối tượng; trường không đánh dấu `neverReveal`
    Khi bấm "Xem đầy đủ" ở màn của phân hệ chứa dữ liệu; hộp thoại dùng chung UI-09-22
    Thì hệ thống trả `201`; `{grantId, token, status, issuedAt, expiresAt, serverTime, remainingThisHour, value}`; `value` chỉ có ở đây
    Và giá trị rõ không ghi đĩa, không vào log
    Và sự kiện được phát: EVT-09-15 khi số lần xem của một người trong giờ đạt `09.mask.reveal-alert-per-hour`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-029 @FR-09-029 @M @âm
  Kịch bản: US-09-029 âm 1 · Không ghi được vết
    Biết người dùng có quyền ở phạm vi đối tượng; trường không đánh dấu `neverReveal`
    Khi không ghi được vết
    Thì hệ thống từ chối với ERR-09-010 (503)
    Và người dùng thấy thông báo "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."

  @US-09-029 @FR-09-029 @M @âm
  Kịch bản: US-09-029 âm 2 · Phiếu hết hạn khi xác thực
    Biết người dùng có quyền ở phạm vi đối tượng; trường không đánh dấu `neverReveal`
    Khi phiếu hết hạn khi xác thực
    Thì hệ thống từ chối với ERR-09-112 (403)
    Và người dùng thấy thông báo "Phiếu xem giá trị đầy đủ không hợp lệ hoặc đã hết hạn."

  @US-09-030 @FR-09-030 @M
  Kịch bản: US-09-030 dương · Cấu hình che cho log, trace và quét rò rỉ dữ liệu cá nhân trong log
    Biết có chỉ mục phân loại; Loki, OTel Collector hoạt động
    Khi sửa cấu hình ở UI-09-10 tab "Log"; lịch `09.log.scan-cron`; bấm "Quét ngay"
    Thì hệ thống trả `200`; kết quả quét `{findings, byService}`
    Và cấu hình có phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-030 @FR-09-030 @M @âm
  Kịch bản: US-09-030 âm 1 · Cấu hình sai
    Biết có chỉ mục phân loại; Loki, OTel Collector hoạt động
    Khi cấu hình sai
    Thì hệ thống từ chối với ERR-09-044 (422)
    Và người dùng thấy thông báo "Cấu hình che log không hợp lệ: {lý do}."

  @US-09-030 @FR-09-030 @M @âm
  Kịch bản: US-09-030 âm 2 · Loki không khả dụng
    Biết có chỉ mục phân loại; Loki, OTel Collector hoạt động
    Khi Loki không khả dụng
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  # ---- EP-09-E · Giả danh hóa và ẩn danh hóa

  @US-09-031 @FR-09-031 @M
  Kịch bản: US-09-031 dương · Quản lý miền giả danh hóa theo tenant và mục đích
    Biết OpenBao transit khả dụng; mục đích tồn tại (FR-09-014)
    Khi bấm "Tạo miền" ở UI-09-12
    Thì hệ thống trả `201`; miền kèm `keyVersion`
    Và `PseudonymDomain` `ACTIVE`
    Và sự kiện được phát: EVT-09-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-031 @FR-09-031 @M @âm
  Kịch bản: US-09-031 âm 1 · Miền trùng
    Biết OpenBao transit khả dụng; mục đích tồn tại (FR-09-014)
    Khi miền trùng
    Thì hệ thống từ chối với ERR-09-045 (409)
    Và người dùng thấy thông báo "Đã có miền giả danh cho mục đích này."

  @US-09-031 @FR-09-031 @M @âm
  Kịch bản: US-09-031 âm 2 · OpenBao lỗi
    Biết OpenBao transit khả dụng; mục đích tồn tại (FR-09-014)
    Khi OpenBao lỗi
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-032 @FR-09-032 @M
  Kịch bản: US-09-032 dương · Giả danh hóa giá trị bằng HMAC hoặc token
    Biết miền `ACTIVE`
    Khi bước giả danh của luồng hoặc job chuẩn bị dữ liệu (FR-09-038)
    Thì hệ thống trả `200`; `{items[], keyVersion}`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-032 @FR-09-032 @M @âm
  Kịch bản: US-09-032 âm 1 · OpenBao lỗi
    Biết miền `ACTIVE`
    Khi OpenBao lỗi
    Thì hệ thống từ chối với ERR-09-108 (503)
    Và người dùng thấy thông báo "Không băm có khóa hoặc token hóa được vì OpenBao không khả dụng."

  @US-09-032 @FR-09-032 @M @âm
  Kịch bản: US-09-032 âm 2 · Không ghi được vết
    Biết miền `ACTIVE`
    Khi không ghi được vết
    Thì hệ thống từ chối với ERR-09-110 (503)
    Và người dùng thấy thông báo "Không ghi được nhật ký thao tác che, thao tác bị từ chối."

  @US-09-033 @FR-09-033 @S
  Kịch bản: US-09-033 dương · Khôi phục giá trị gốc từ token (đặc quyền, hai người duyệt)
    Biết miền `TOKEN_TRANSIT`; khóa còn phiên bản giải được
    Khi bấm "Đề nghị khôi phục" ở UI-09-13
    Thì hệ thống trả `200`; kết quả hiển thị tức thời, không lưu
    Và đề nghị `EXECUTED`; nhật ký khôi phục lưu vĩnh viễn
    Và sự kiện được phát: EVT-09-17
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-033 @FR-09-033 @S @âm
  Kịch bản: US-09-033 âm 1 · Miền HMAC
    Biết miền `TOKEN_TRANSIT`; khóa còn phiên bản giải được
    Khi miền HMAC
    Thì hệ thống từ chối với ERR-09-048 (422)
    Và người dùng thấy thông báo "Miền {mã} dùng HMAC không đảo ngược, không khôi phục được giá trị gốc."

  @US-09-034 @FR-09-034 @M
  Kịch bản: US-09-034 dương · Quản lý vòng đời khóa giả danh hóa trên OpenBao
    Biết miền tồn tại
    Khi hành động ở UI-09-12; lịch xoay theo `09.pseudo.key-rotate-days` (365)
    Thì hệ thống trả `200`; khóa kèm `keyVersion`, `status`
    Và phiên bản cũ vẫn giải được trừ khi `DESTROYED`
    Và sự kiện được phát: EVT-09-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-034 @FR-09-034 @M @âm
  Kịch bản: US-09-034 âm 1 · Xoay quá sớm
    Biết miền tồn tại
    Khi xoay quá sớm
    Thì hệ thống từ chối với ERR-09-047 (409)
    Và người dùng thấy thông báo "Vừa xoay khóa gần đây. Chờ tối thiểu {n} ngày."

  @US-09-034 @FR-09-034 @M @âm
  Kịch bản: US-09-034 âm 2 · Hủy khóa còn dùng
    Biết miền tồn tại
    Khi hủy khóa còn dùng
    Thì hệ thống từ chối với ERR-09-046 (409)
    Và người dùng thấy thông báo "Khóa còn được sử dụng, chưa hủy được."

  @US-09-035 @FR-09-035 @S
  Kịch bản: US-09-035 dương · Cấu hình ẩn danh hóa
    Biết phần tử của thực thể đã phân loại `CONFIRMED` kèm `identifiability`
    Khi bấm "Tạo cấu hình" ở UI-09-14
    Thì hệ thống trả `201` hoặc `200`
    Và cấu hình `ACTIVE` dùng được ở FR-09-036
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-035 @FR-09-035 @S @âm
  Kịch bản: US-09-035 âm 1 · k thấp
    Biết phần tử của thực thể đã phân loại `CONFIRMED` kèm `identifiability`
    Khi k thấp
    Thì hệ thống từ chối với ERR-09-051 (422)
    Và người dùng thấy thông báo "Ngưỡng k phải từ {n} trở lên."

  @US-09-036 @FR-09-036 @S
  Kịch bản: US-09-036 dương · Ẩn danh hóa tập dữ liệu với k tối thiểu 10
    Biết cấu hình `ACTIVE`; nguồn là bảng hoặc tệp được chủ quản cho phép
    Khi bấm "Chạy" ở UI-09-14
    Thì hệ thống trả `202`; `jobId`; job kèm `kActual`, số bản ghi trước và sau
    Và job `AWAITING_RISK_REVIEW` hoặc `COMPLETED` hoặc `REJECTED_RISK`
    Và sự kiện được phát: EVT-09-18 khi tập thay đổi trạng thái
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-036 @FR-09-036 @S @âm
  Kịch bản: US-09-036 âm 1 · Không đạt k sau ba vòng hoặc tập quá nhỏ
    Biết cấu hình `ACTIVE`; nguồn là bảng hoặc tệp được chủ quản cho phép
    Khi không đạt k sau ba vòng hoặc tập quá nhỏ
    Thì hệ thống từ chối với ERR-09-054 (422)
    Và người dùng thấy thông báo "Sau xử lý chỉ còn {x}% bản ghi, dữ liệu không còn giá trị thống kê."

  @US-09-037 @FR-09-037 @S
  Kịch bản: US-09-037 dương · Đánh giá rủi ro tái định danh
    Biết có tập đã ẩn danh hoặc tập có sẵn cần đánh giá
    Khi hết bước ẩn danh hóa; bấm "Đánh giá rủi ro"
    Thì hệ thống trả `200`; `{level, kActual, smallGroupRate, fields[], recommendation}`
    Và `RiskReport` gắn job hoặc tập
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-037 @FR-09-037 @S @âm
  Kịch bản: US-09-037 âm 1 · Rủi ro cao
    Biết có tập đã ẩn danh hoặc tập có sẵn cần đánh giá
    Khi rủi ro cao
    Thì hệ thống từ chối với ERR-09-053 (422)
    Và người dùng thấy thông báo "Rủi ro tái định danh cao, không phát hành. Xem khuyến nghị của báo cáo."

  @US-09-038 @FR-09-038 @M
  Kịch bản: US-09-038 dương · Chuẩn bị dữ liệu cho AI và môi trường không phải PROD
    Biết nguồn đã phân loại đủ
    Khi bấm "Chuẩn bị dữ liệu" ở UI-09-14 hoặc PH-17 gọi
    Thì hệ thống trả `202`; `preparationId`
    Và tập có nguồn gốc truy vết
    Và sự kiện được phát: EVT-09-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-038 @FR-09-038 @M @âm
  Kịch bản: US-09-038 âm 1 · Mục tiêu không cho phép
    Biết nguồn đã phân loại đủ
    Khi mục tiêu không cho phép
    Thì hệ thống từ chối với ERR-09-055 (422)
    Và người dùng thấy thông báo "Mục đích {mã} không cho phép dùng dữ liệu có trường Nhạy cảm."

  @US-09-038 @FR-09-038 @M @âm
  Kịch bản: US-09-038 âm 2 · `RESTRICTED` cho AI khi cờ tắt
    Biết nguồn đã phân loại đủ
    Khi `RESTRICTED` cho AI khi cờ tắt
    Thì hệ thống từ chối với ERR-09-082 (422)
    Và người dùng thấy thông báo "Dữ liệu Hạn chế chưa được phép dùng cho AI. Đề nghị TA bật tham số 09.ai.allow-restricted."

  @US-09-039 @FR-09-039 @C
  Kịch bản: US-09-039 dương · Quản lý tập dữ liệu đã ẩn danh và điều kiện sử dụng
    Biết tập `READY` với rủi ro không `HIGH`
    Khi hành động ở UI-09-14 tab "Tập dữ liệu"
    Thì hệ thống trả `200`
    Và trạng thái tập cập nhật
    Và sự kiện được phát: EVT-09-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-039 @FR-09-039 @C @âm
  Kịch bản: US-09-039 âm 1 · Sửa tập đã phát hành
    Biết tập `READY` với rủi ro không `HIGH`
    Khi sửa tập đã phát hành
    Thì hệ thống từ chối với ERR-09-056 (409)
    Và người dùng thấy thông báo "Tập dữ liệu đã phát hành, không sửa được. Rút lại để tạo tập mới."

  # ---- EP-09-F · Lưu giữ và xóa

  @US-09-040 @FR-09-040 @M
  Kịch bản: US-09-040 dương · Lập lịch lưu giữ theo bảng và loại dữ liệu
    Biết hoạt động xử lý có thời hạn lưu (FR-09-011)
    Khi bấm "Tạo lịch" ở UI-09-15
    Thì hệ thống trả `201` hoặc `200`
    Và lịch có phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-040 @FR-09-040 @M @âm
  Kịch bản: US-09-040 âm 1 · Thiếu quy tắc cho bảng DLCN
    Biết hoạt động xử lý có thời hạn lưu (FR-09-011)
    Khi thiếu quy tắc cho bảng DLCN
    Thì hệ thống từ chối với ERR-09-057 (422)
    Và người dùng thấy thông báo "Bảng {tên} chứa dữ liệu cá nhân nhưng chưa có thời hạn lưu."

  @US-09-041 @FR-09-041 @M
  Kịch bản: US-09-041 dương · Tác vụ xóa hoặc giả danh hóa khi hết hạn và báo cáo
    Biết lịch `ACTIVE`
    Khi lịch `09.retention.run-cron`; bấm "Chạy ngay" hoặc "Chạy thử"
    Thì hệ thống trả `202` (chạy), `200` (chạy thử)
    Và tác vụ `COMPLETED` kèm số bản ghi
    Và sự kiện được phát: EVT-09-19
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-041 @FR-09-041 @M @âm
  Kịch bản: US-09-041 âm 1 · Bảng đang có tác vụ
    Biết lịch `ACTIVE`
    Khi bảng đang có tác vụ
    Thì hệ thống từ chối với ERR-09-061 (409)
    Và người dùng thấy thông báo "Tác vụ xóa đang chạy, không chạy chồng."

  @US-09-041 @FR-09-041 @M @âm
  Kịch bản: US-09-041 âm 2 · Phân hệ sở hữu lỗi
    Biết lịch `ACTIVE`
    Khi phân hệ sở hữu lỗi
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-042 @FR-09-042 @M
  Kịch bản: US-09-042 dương · Giữ pháp lý (tạm hoãn xóa)
    Biết có văn bản căn cứ
    Khi bấm "Đặt giữ" ở UI-09-15
    Thì hệ thống trả `201`; `holdId`
    Và phạm vi giữ có hiệu lực cho mọi tác vụ
    Và sự kiện được phát: EVT-09-20
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-042 @FR-09-042 @M @âm
  Kịch bản: US-09-042 âm 1 · Thiếu căn cứ
    Biết có văn bản căn cứ
    Khi thiếu căn cứ
    Thì hệ thống từ chối với ERR-09-059 (422)
    Và người dùng thấy thông báo "Giữ pháp lý cần số văn bản và cơ quan yêu cầu."

  @US-09-042 @FR-09-042 @M @âm
  Kịch bản: US-09-042 âm 2 · Gỡ giữ đã gỡ
    Biết có văn bản căn cứ
    Khi gỡ giữ đã gỡ
    Thì hệ thống từ chối với ERR-09-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-09-043 @FR-09-043 @M
  Kịch bản: US-09-043 dương · Xóa mật mã khi chấm dứt tenant
    Biết PH-02 xác nhận tenant chấm dứt; hết hạn chờ; không còn giữ pháp lý
    Khi PH-02 gọi hoặc bấm "Đề nghị xóa mật mã"
    Thì hệ thống trả `202`
    Và khóa `DESTROYED`
    Và sự kiện được phát: EVT-09-21
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-043 @FR-09-043 @M @âm
  Kịch bản: US-09-043 âm 1 · Chưa đủ điều kiện
    Biết PH-02 xác nhận tenant chấm dứt; hết hạn chờ; không còn giữ pháp lý
    Khi chưa đủ điều kiện
    Thì hệ thống từ chối với ERR-09-060 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện xóa mật mã tenant: {lý do}."

  @US-09-043 @FR-09-043 @M @âm
  Kịch bản: US-09-043 âm 2 · Còn giữ pháp lý
    Biết PH-02 xác nhận tenant chấm dứt; hết hạn chờ; không còn giữ pháp lý
    Khi còn giữ pháp lý
    Thì hệ thống từ chối với ERR-09-058 (409)
    Và người dùng thấy thông báo "Dữ liệu đang bị giữ pháp lý, không xóa được cho đến khi gỡ giữ."

  @US-09-044 @FR-09-044 @S
  Kịch bản: US-09-044 dương · Báo cáo tuân thủ thời hạn lưu
    Biết có lịch `ACTIVE`
    Khi mở UI-09-15 tab "Báo cáo"
    Thì hệ thống trả `200`; bảng số liệu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-044 @FR-09-044 @S @âm
  Kịch bản: US-09-044 âm 1 · Khoảng thời gian sai
    Biết có lịch `ACTIVE`
    Khi khoảng thời gian sai
    Thì hệ thống từ chối với ERR-09-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."

  # ---- EP-09-G · Quyền của chủ thể dữ liệu

  @US-09-045 @FR-09-045 @M
  Kịch bản: US-09-045 dương · Tiếp nhận yêu cầu của chủ thể dữ liệu
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi bấm "Tiếp nhận" ở UI-09-16 hoặc cổng gọi API
    Thì hệ thống trả `201`; `{requestId, dueAt}`
    Và đồng hồ chạy
    Và sự kiện được phát: EVT-09-22
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-045 @FR-09-045 @M @âm
  Kịch bản: US-09-045 âm 1 · Yêu cầu trùng
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi yêu cầu trùng
    Thì hệ thống từ chối với ERR-09-064 (409)
    Và người dùng thấy thông báo "Chủ thể đã có yêu cầu cùng loại đang xử lý."

  @US-09-046 @FR-09-046 @M
  Kịch bản: US-09-046 dương · Xác minh danh tính chủ thể
    Biết yêu cầu `RECEIVED`
    Khi bấm "Xác minh" ở UI-09-16
    Thì hệ thống trả `200`
    Và trạng thái cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-046 @FR-09-046 @M @âm
  Kịch bản: US-09-046 âm 1 · Chưa xác minh mà tra cứu
    Biết yêu cầu `RECEIVED`
    Khi chưa xác minh mà tra cứu
    Thì hệ thống từ chối với ERR-09-063 (422)
    Và người dùng thấy thông báo "Chưa xác minh danh tính chủ thể. Hoàn tất xác minh trước khi xử lý."

  @US-09-046 @FR-09-046 @M @âm
  Kịch bản: US-09-046 âm 2 · Không phải chủ thể
    Biết yêu cầu `RECEIVED`
    Khi không phải chủ thể
    Thì hệ thống từ chối với ERR-09-065 (403)
    Và người dùng thấy thông báo "Người gửi chưa chứng minh là chủ thể hoặc người đại diện hợp pháp."

  @US-09-047 @FR-09-047 @M
  Kịch bản: US-09-047 dương · Tra cứu dữ liệu về chủ thể theo băm định danh
    Biết yêu cầu `IN_PROGRESS`
    Khi bấm "Tra cứu" ở UI-09-16
    Thì hệ thống trả `200`; `findings[]`
    Và kết quả gắn yêu cầu, không chứa giá trị
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-047 @FR-09-047 @M @âm
  Kịch bản: US-09-047 âm 1 · Nguồn không đăng ký
    Biết yêu cầu `IN_PROGRESS`
    Khi nguồn không đăng ký
    Thì hệ thống từ chối với ERR-09-066 (502)
    Và người dùng thấy thông báo "Chưa chuyển được yêu cầu tới {đích}. Hệ thống sẽ thử lại."

  @US-09-047 @FR-09-047 @M @âm
  Kịch bản: US-09-047 âm 2 · Chưa xác minh
    Biết yêu cầu `IN_PROGRESS`
    Khi chưa xác minh
    Thì hệ thống từ chối với ERR-09-063 (422)
    Và người dùng thấy thông báo "Chưa xác minh danh tính chủ thể. Hoàn tất xác minh trước khi xử lý."

  @US-09-048 @FR-09-048 @M
  Kịch bản: US-09-048 dương · Phân công, chuyển xử lý cho PH-06, PH-19 hoặc bên kiểm soát
    Biết có kết quả tra cứu
    Khi bấm "Giao tác vụ" ở UI-09-16
    Thì hệ thống trả `201`
    Và tác vụ theo dõi được
    Và sự kiện được phát: EVT-09-26 khi đổi hạn chế xử lý
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-048 @FR-09-048 @M @âm
  Kịch bản: US-09-048 âm 1 · Còn tác vụ mở khi đóng
    Biết có kết quả tra cứu
    Khi còn tác vụ mở khi đóng
    Thì hệ thống từ chối với ERR-09-067 (422)
    Và người dùng thấy thông báo "Còn {n} tác vụ chưa hoàn tất, chưa đóng được yêu cầu."

  @US-09-048 @FR-09-048 @M @âm
  Kịch bản: US-09-048 âm 2 · Phân hệ đích lỗi
    Biết có kết quả tra cứu
    Khi phân hệ đích lỗi
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-049 @FR-09-049 @M
  Kịch bản: US-09-049 dương · Theo dõi hạn xử lý, nhắc và quá hạn
    Biết có yêu cầu đang mở
    Khi lịch mỗi giờ; mở UI-09-16 tab "Sắp đến hạn"
    Thì hệ thống trả `200`; danh sách yêu cầu theo mức khẩn
    Và cờ `overdue` cập nhật
    Và sự kiện được phát: EVT-09-23, EVT-09-24
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-049 @FR-09-049 @M @âm
  Kịch bản: US-09-049 âm 1 · Gia hạn thiếu lý do
    Biết có yêu cầu đang mở
    Khi gia hạn thiếu lý do
    Thì hệ thống từ chối với ERR-09-007 (422)
    Và người dùng thấy thông báo "Nhập lý do tối thiểu 20 ký tự."

  @US-09-050 @FR-09-050 @M
  Kịch bản: US-09-050 dương · Trả lời chủ thể, đóng yêu cầu, lưu bằng chứng
    Biết mọi tác vụ con xong hoặc có căn cứ từ chối
    Khi bấm "Trả lời" rồi "Đóng" ở UI-09-16
    Thì hệ thống trả `200`
    Và yêu cầu `CLOSED`
    Và sự kiện được phát: EVT-09-25
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-050 @FR-09-050 @M @âm
  Kịch bản: US-09-050 âm 1 · Trả lời thiếu căn cứ từ chối
    Biết mọi tác vụ con xong hoặc có căn cứ từ chối
    Khi trả lời thiếu căn cứ từ chối
    Thì hệ thống từ chối với ERR-09-068 (422)
    Và người dùng thấy thông báo "Câu trả lời thiếu kết quả hoặc bằng chứng đính kèm."

  @US-09-051 @FR-09-051 @S
  Kịch bản: US-09-051 dương · Báo cáo ai đã truy cập dữ liệu của chủ thể
    Biết yêu cầu loại `ACCESS` đã xác minh
    Khi bấm "Lập báo cáo truy cập" ở UI-09-16
    Thì hệ thống trả `202`; báo cáo tải qua `access-report`
    Và báo cáo gắn yêu cầu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-051 @FR-09-051 @S @âm
  Kịch bản: US-09-051 âm 1 · Nhật ký lỗi
    Biết yêu cầu loại `ACCESS` đã xác minh
    Khi nhật ký lỗi
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  # ---- EP-09-H · Sự đồng ý

  @US-09-052 @FR-09-052 @M
  Kịch bản: US-09-052 dương · Quản lý mẫu sự đồng ý
    Biết hoạt động xử lý có cơ sở là đồng ý
    Khi bấm "Tạo mẫu" ở UI-09-17
    Thì hệ thống trả `201` hoặc `200`
    Và mẫu có phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-052 @FR-09-052 @M @âm
  Kịch bản: US-09-052 âm 1 · Mẫu thiếu nội dung
    Biết hoạt động xử lý có cơ sở là đồng ý
    Khi mẫu thiếu nội dung
    Thì hệ thống từ chối với ERR-09-069 (422)
    Và người dùng thấy thông báo "Mẫu đồng ý cần nêu mục đích cụ thể, dữ liệu xử lý và cách rút lại."

  @US-09-052 @FR-09-052 @M @âm
  Kịch bản: US-09-052 âm 2 · Ngừng mẫu đang dùng
    Biết hoạt động xử lý có cơ sở là đồng ý
    Khi ngừng mẫu đang dùng
    Thì hệ thống từ chối với ERR-09-070 (409)
    Và người dùng thấy thông báo "Mẫu đã có người đồng ý. Tạo phiên bản mới thay vì sửa."

  @US-09-053 @FR-09-053 @M
  Kịch bản: US-09-053 dương · Ghi nhận, rút sự đồng ý và lưu bằng chứng
    Biết mẫu `ACTIVE`
    Khi tiện ích hoặc cán bộ gọi `POST /consents`
    Thì hệ thống trả `201` hoặc `200`
    Và trạng thái đồng ý cập nhật
    Và sự kiện được phát: EVT-09-27, EVT-09-28
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-053 @FR-09-053 @M @âm
  Kịch bản: US-09-053 âm 1 · Thiếu bằng chứng
    Biết mẫu `ACTIVE`
    Khi thiếu bằng chứng
    Thì hệ thống từ chối với ERR-09-071 (422)
    Và người dùng thấy thông báo "Thiếu bằng chứng đồng ý: kênh, thời điểm, phiên bản mẫu."

  @US-09-053 @FR-09-053 @M @âm
  Kịch bản: US-09-053 âm 2 · Đồng ý không tồn tại
    Biết mẫu `ACTIVE`
    Khi đồng ý không tồn tại
    Thì hệ thống từ chối với ERR-09-072 (409)
    Và người dùng thấy thông báo "Sự đồng ý đã được rút hoặc hết hiệu lực."

  @US-09-054 @FR-09-054 @C
  Kịch bản: US-09-054 dương · Tra cứu trạng thái đồng ý cho tiện ích không bắt buộc
    Biết có đồng ý hoặc mẫu
    Khi tiện ích gọi `consents:check`
    Thì hệ thống trả `200`; p95 ≤ 50 ms (NFR-09-001)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-054 @FR-09-054 @C @âm
  Kịch bản: US-09-054 âm 1 · Vượt hạn mức
    Biết có đồng ý hoặc mẫu
    Khi vượt hạn mức
    Thì hệ thống từ chối với ERR-09-113 (429)
    Và người dùng thấy thông báo "Vượt hạn mức gọi API quyền riêng tư."

  # ---- EP-09-I · Đánh giá tác động xử lý dữ liệu cá nhân

  @US-09-055 @FR-09-055 @M
  Kịch bản: US-09-055 dương · Lập hồ sơ đánh giá tác động xử lý dữ liệu cá nhân
    Biết hoạt động xử lý tồn tại
    Khi bấm "Tạo hồ sơ" ở UI-09-18
    Thì hệ thống trả `201`
    Và hồ sơ `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-055 @FR-09-055 @M @âm
  Kịch bản: US-09-055 âm 1 · Hồ sơ thiếu mục
    Biết hoạt động xử lý tồn tại
    Khi hồ sơ thiếu mục
    Thì hệ thống từ chối với ERR-09-073 (422)
    Và người dùng thấy thông báo "Hồ sơ đánh giá tác động còn thiếu: {mục}."

  @US-09-056 @FR-09-056 @M
  Kịch bản: US-09-056 dương · Duyệt, phiên bản hóa, nhắc cập nhật hồ sơ đánh giá tác động
    Biết hồ sơ `DRAFT`
    Khi bấm "Gửi duyệt", "Duyệt"; lịch hằng ngày
    Thì hệ thống trả `200`
    Và phiên bản `ACTIVE` duy nhất
    Và sự kiện được phát: EVT-09-29
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-056 @FR-09-056 @M @âm
  Kịch bản: US-09-056 âm 1 · Tự duyệt
    Biết hồ sơ `DRAFT`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-09-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

  @US-09-057 @FR-09-057 @C
  Kịch bản: US-09-057 dương · Xuất hồ sơ đánh giá tác động gửi Cục A05
    Biết hồ sơ `ACTIVE`
    Khi bấm "Xuất cho A05" ở UI-09-18
    Thì hệ thống trả `202`
    Và hồ sơ ghi `submittedAt`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-057 @FR-09-057 @C @âm
  Kịch bản: US-09-057 âm 1 · Hồ sơ chưa duyệt
    Biết hồ sơ `ACTIVE`
    Khi hồ sơ chưa duyệt
    Thì hệ thống từ chối với ERR-09-074 (409)
    Và người dùng thấy thông báo "Hồ sơ chưa được duyệt, chưa xuất gửi Cục A05 được."

  # ---- EP-09-J · Vi phạm dữ liệu cá nhân

  @US-09-058 @FR-09-058 @M
  Kịch bản: US-09-058 dương · Ghi nhận vi phạm dữ liệu cá nhân và đánh giá ảnh hưởng
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi bấm "Ghi nhận vi phạm" ở UI-09-19; cảnh báo từ PH-18 hoặc EVT-09-13
    Thì hệ thống trả `201`
    Và `REPORTED` hoặc `ASSESSING`
    Và sự kiện được phát: EVT-09-30
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-058 @FR-09-058 @M @âm
  Kịch bản: US-09-058 âm 1 · Đóng khi chưa đánh giá
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi đóng khi chưa đánh giá
    Thì hệ thống từ chối với ERR-09-076 (409)
    Và người dùng thấy thông báo "Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ."

  @US-09-059 @FR-09-059 @M
  Kịch bản: US-09-059 dương · Đồng hồ 72 giờ, thông báo Cục A05 và chủ thể
    Biết vụ việc `ASSESSING` kết luận cần thông báo
    Khi cảnh báo đồng hồ 24, 48, 60 giờ; bấm "Soạn thông báo"
    Thì hệ thống trả `201`; thông báo `DRAFT`, rồi `SENT`
    Và đồng hồ dừng khi `NOTIFIED`
    Và sự kiện được phát: EVT-09-31, EVT-09-32
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-059 @FR-09-059 @M @âm
  Kịch bản: US-09-059 âm 1 · Thiếu căn cứ miễn thông báo
    Biết vụ việc `ASSESSING` kết luận cần thông báo
    Khi thiếu căn cứ miễn thông báo
    Thì hệ thống từ chối với ERR-09-077 (422)
    Và người dùng thấy thông báo "Không thông báo chủ thể cần nêu căn cứ miễn trừ và lý do."

  @US-09-059 @FR-09-059 @M @âm
  Kịch bản: US-09-059 âm 2 · Vụ việc đã đóng
    Biết vụ việc `ASSESSING` kết luận cần thông báo
    Khi vụ việc đã đóng
    Thì hệ thống từ chối với ERR-09-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-09-060 @FR-09-060 @M
  Kịch bản: US-09-060 dương · Hồ sơ vi phạm, khắc phục và bài học
    Biết vụ việc đã `NOTIFIED` hoặc miễn thông báo có căn cứ
    Khi hành động ở UI-09-19 tab "Khắc phục"
    Thì hệ thống trả `200`
    Và `CLOSED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-060 @FR-09-060 @M @âm
  Kịch bản: US-09-060 âm 1 · Đóng khi còn biện pháp mở
    Biết vụ việc đã `NOTIFIED` hoặc miễn thông báo có căn cứ
    Khi đóng khi còn biện pháp mở
    Thì hệ thống từ chối với ERR-09-076 (409)
    Và người dùng thấy thông báo "Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ."

  # ---- EP-09-K · Kiểm toán, báo cáo và cấu hình

  @US-09-061 @FR-09-061 @M
  Kịch bản: US-09-061 dương · Ghi vết thao tác bảo vệ dữ liệu
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi mở UI-09-20
    Thì hệ thống trả `200` hoặc `202`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-061 @FR-09-061 @M @âm
  Kịch bản: US-09-061 âm 1 · Khoảng thời gian vượt `09.audit.query-max-days`
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi khoảng thời gian vượt `09.audit.query-max-days`
    Thì hệ thống từ chối với ERR-09-079 (422)
    Và người dùng thấy thông báo "Chọn khoảng thời gian tối đa {n} ngày."

  @US-09-062 @FR-09-062 @S
  Kịch bản: US-09-062 dương · Bảng điều khiển tuân thủ quyền riêng tư
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi mở UI-09-01
    Thì hệ thống trả `200`

  @US-09-062 @FR-09-062 @S @âm
  Kịch bản: US-09-062 âm 1 · Nguồn số liệu lỗi
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi nguồn số liệu lỗi
    Thì hệ thống từ chối với ERR-09-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-09-063 @FR-09-063 @C
  Kịch bản: US-09-063 dương · Báo cáo tuân thủ định kỳ
    Biết có số liệu kỳ
    Khi lịch hoặc bấm "Lập báo cáo"
    Thì hệ thống trả `202`
    Và báo cáo lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-063 @FR-09-063 @C @âm
  Kịch bản: US-09-063 âm 1 · Lịch sai
    Biết có số liệu kỳ
    Khi lịch sai
    Thì hệ thống từ chối với ERR-09-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."

  @US-09-064 @FR-09-064 @M
  Kịch bản: US-09-064 dương · Cấu hình tham số PH-09 của tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi sửa ở UI-09-21
    Thì hệ thống trả `200`
    Và có lịch sử
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-09-064 @FR-09-064 @M @âm
  Kịch bản: US-09-064 âm 1 · Giá trị ngoài miền
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-09-078 (422)
    Và người dùng thấy thông báo "Giá trị của {khóa} ngoài miền cho phép {miền}."

  @US-09-064 @FR-09-064 @M @âm
  Kịch bản: US-09-064 âm 2 · Xung đột phiên bản
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi xung đột phiên bản
    Thì hệ thống từ chối với ERR-09-004 (409)
    Và người dùng thấy thông báo "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới."
