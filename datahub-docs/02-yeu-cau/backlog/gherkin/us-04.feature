# language: vi
# Sinh tự động từ D02-02/D02-03-PH04 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-04
Tính năng: PH-04 · Lõi tích hợp và trình thiết kế luồng

  # ---- EP-04-A · Không gian làm việc và quản lý luồng

  @US-04-001 @FR-04-001 @M
  Kịch bản: US-04-001 dương · Liệt kê luồng, tìm theo tên, endpoint, hệ nguồn, môi trường, đếm theo trạng thái
    Biết đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở menu "Tích hợp › Luồng", nhập ô tìm, chọn bộ lọc hoặc bấm một ô đếm trạng thái ở đầu UI-04-01
    Thì hệ thống trả `200`; trang kết quả `items[]` (mã, tên, loại tài nguyên, vận chuyển, đối ngoại/nội bộ, không gian làm việc, trạng thái tổng hợp, phiên bản đang chạy ở PROD, phiên bản mở và trạng thái của nó, HTTT nguồn, HTTT đích, endpoint chính …

  @US-04-001 @FR-04-001 @M @âm
  Kịch bản: US-04-001 âm 1 · Tham số sai kiểu, ngoài miền
    Biết đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số sai kiểu, ngoài miền
    Thì hệ thống từ chối với ERR-04-049 (400)
    Và người dùng thấy thông báo "Giá trị lọc không hợp lệ: {tham số}."

  @US-04-001 @FR-04-001 @M @âm
  Kịch bản: US-04-001 âm 2 · `limit` > 100
    Biết đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi `limit` > 100
    Thì hệ thống từ chối với ERR-04-026 (400)
    Và người dùng thấy thông báo "Mỗi trang tối đa 100 dòng."

  @US-04-002 @FR-04-002 @M
  Kịch bản: US-04-002 dương · Xem chi tiết luồng: thông tin, route, endpoint, thuộc tính, sơ đồ, mã nguồn, phiên bản, triển khai
    Biết luồng tồn tại trong tenant, người dùng thấy được theo mục 3.4
    Khi người dùng bấm tên luồng ở UI-04-01, mở liên kết trực tiếp, hoặc chọn phiên bản, môi trường trên tab Phiên bản
    Thì hệ thống trả `200`; thông tin luồng (mọi trường EN-04-02, chủ sở hữu, HTTT liên quan, nhãn, không gian làm việc); danh sách route trong phiên bản chọn (mã route, chặng đầu, số chặng, mô tả, `autoStartup`) …

  @US-04-002 @FR-04-002 @M @âm
  Kịch bản: US-04-002 âm 1 · Không tìm thấy luồng
    Biết luồng tồn tại trong tenant, người dùng thấy được theo mục 3.4
    Khi không tìm thấy luồng
    Thì hệ thống từ chối với ERR-04-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy luồng, hoặc bạn không có quyền xem luồng này."

  @US-04-002 @FR-04-002 @M @âm
  Kịch bản: US-04-002 âm 2 · Không tìm thấy phiên bản
    Biết luồng tồn tại trong tenant, người dùng thấy được theo mục 3.4
    Khi không tìm thấy phiên bản
    Thì hệ thống từ chối với ERR-04-004 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản v{n} của luồng này."

  @US-04-003 @FR-04-003 @M
  Kịch bản: US-04-003 dương · Tạo luồng mới từ luồng trống, khuôn mẫu, API trong danh mục dịch vụ hoặc tệp YAML
    Biết tenant hoạt động; không gian làm việc tồn tại
    Khi IE bấm "+ Tạo luồng" ở UI-04-01, chọn "Dùng khuôn này" ở UI-04-19, hoặc tạo luồng nháp từ báo cáo chuyển đổi ở UI-04-18
    Thì hệ thống trả `201 Created`, `Location: /api/integration/v1/flows/{code}`, thân là chi tiết luồng kèm `openVersionNo = 1`; ETag
    Và một `flow` trạng thái `DRAFT`; một `flow_version` số 1 trạng thái `DRAFT`, `origin` ghi nguồn khởi tạo; chỉ mục endpoint, route của phiên bản 1
    Và sự kiện được phát: EVT-04-01 `{tenant}.integration.flow.created.v1`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-003 @FR-04-003 @M @âm
  Kịch bản: US-04-003 âm 1 · Mã luồng trùng
    Biết tenant hoạt động; không gian làm việc tồn tại
    Khi mã luồng trùng
    Thì hệ thống từ chối với ERR-04-002 (409)
    Và người dùng thấy thông báo "Mã luồng"

  @US-04-003 @FR-04-003 @M @âm
  Kịch bản: US-04-003 âm 2 · Không có mức `EDIT` trên không gian làm việc
    Biết tenant hoạt động; không gian làm việc tồn tại
    Khi không có mức `EDIT` trên không gian làm việc
    Thì hệ thống từ chối với ERR-04-003 (403)
    Và người dùng thấy thông báo "Bạn chưa có quyền sửa trong không gian làm việc"

  @US-04-004 @FR-04-004 @M
  Kịch bản: US-04-004 dương · Cập nhật thông tin luồng
    Biết luồng tồn tại, không ở trạng thái `RETIRED`
    Khi người dùng bấm "Sửa thông tin" trên tab Tổng quan của UI-04-02
    Thì hệ thống trả `200` với chi tiết luồng, ETag mới
    Và thông tin luồng đổi; nếu `sourceSystem` hoặc `targetSystems` đổi làm luồng chuyển từ nội bộ sang đối ngoại thì phiên bản mở được kiểm tra lại với mức nghiêm ngặt của luồng đối ngoại
    Và sự kiện được phát: EVT-04-02 `flow.updated` với danh sách trường đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-004 @FR-04-004 @M @âm
  Kịch bản: US-04-004 âm 1 · ETag không khớp
    Biết luồng tồn tại, không ở trạng thái `RETIRED`
    Khi ETag không khớp
    Thì hệ thống từ chối với ERR-04-006 (412)
    Và người dùng thấy thông báo "{user} đã lưu phiên bản này lúc {time}. Thay đổi của bạn chưa được lưu."

  @US-04-004 @FR-04-004 @M @âm
  Kịch bản: US-04-004 âm 2 · Thiếu `If-Match`
    Biết luồng tồn tại, không ở trạng thái `RETIRED`
    Khi thiếu `If-Match`
    Thì hệ thống từ chối với ERR-04-007 (428)
    Và người dùng thấy thông báo "Thiếu thông tin phiên bản dữ liệu. Tải lại trang rồi thử lại."

  @US-04-005 @FR-04-005 @S
  Kịch bản: US-04-005 dương · Nhân bản luồng
    Biết luồng nguồn tồn tại; người dùng có mức `EDIT` trên không gian làm việc đích
    Khi người dùng bấm "Nhân bản" trên UI-04-02 hoặc trong menu dòng của UI-04-01
    Thì hệ thống trả `201` như FR-04-003, `origin = DUPLICATE`, `duplicatedFrom = {code, versionNo}`
    Và luồng mới `DRAFT`, phiên bản 1 là bản sao định nghĩa và bố cục; không sao chép triển khai, lần chạy thử, lịch sử duyệt, ca kiểm thử (ca kiểm thử sao chép khi `copyTests = true`)
    Và sự kiện được phát: EVT-04-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-005 @FR-04-005 @S @âm
  Kịch bản: US-04-005 âm 1 · Mã mới trùng
    Biết luồng nguồn tồn tại; người dùng có mức `EDIT` trên không gian làm việc đích
    Khi mã mới trùng
    Thì hệ thống từ chối với ERR-04-002 (409)
    Và người dùng thấy thông báo "Mã luồng"

  @US-04-006 @FR-04-006 @M
  Kịch bản: US-04-006 dương · Gỡ bỏ luồng có kiểm tra phụ thuộc, xóa bản nháp
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi người dùng bấm "Xóa bản nháp" hoặc "Gỡ luồng" trên UI-04-02
    Thì hệ thống trả `202 Accepted` với danh sách triển khai được yêu cầu gỡ (luồng đã phát hành); `204` (luồng chưa phát hành)
    Và chưa phát hành: `deleted_at` được đặt
    Và sự kiện được phát: EVT-04-09 `flow.retired`; EVT-04-06 cho từng môi trường
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-006 @FR-04-006 @M @âm
  Kịch bản: US-04-006 âm 1 · Còn phụ thuộc cứng
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi còn phụ thuộc cứng
    Thì hệ thống từ chối với ERR-04-017 (409)
    Và người dùng thấy thông báo "Luồng đang được dùng bởi {n} đối tượng. Gỡ các phụ thuộc trước."

  @US-04-006 @FR-04-006 @M @âm
  Kịch bản: US-04-006 âm 2 · Thiếu lý do khi gỡ
    Biết người dùng đã đăng nhập với vai trò kỹ sư tích hợp
    Khi thiếu lý do khi gỡ
    Thì hệ thống từ chối với ERR-04-025 (400)
    Và người dùng thấy thông báo "Vui lòng nhập lý do (ít nhất {min} ký tự)."

  @US-04-007 @FR-04-007 @S
  Kịch bản: US-04-007 dương · Quản lý không gian làm việc và thành viên
    Biết tenant hoạt động; với thêm thành viên, người dùng hoặc nhóm tồn tại ở PH-12
    Khi TA mở UI-04-21 và bấm "+ Tạo không gian làm việc", "Sửa", "Lưu trữ" hoặc tab Thành viên
    Thì hệ thống trả `200`/`201`; không gian làm việc và danh sách thành viên
    Và quyền hiệu lực của thành viên thay đổi ngay ở lượt gọi kế tiếp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-007 @FR-04-007 @S @âm
  Kịch bản: US-04-007 âm 1 · Mã trùng
    Biết tenant hoạt động; với thêm thành viên, người dùng hoặc nhóm tồn tại ở PH-12
    Khi mã trùng
    Thì hệ thống từ chối với ERR-04-028 (409)
    Và người dùng thấy thông báo "Mã không gian làm việc"

  # ---- EP-04-B · Trình thiết kế luồng

  @US-04-010 @FR-04-010 @M
  Kịch bản: US-04-010 dương · Mở trình thiết kế, phiên soạn thảo và cảnh báo người khác đang sửa
    Biết luồng tồn tại
    Khi người dùng bấm "Mở thiết kế" ở UI-04-01, UI-04-02, hoặc được chuyển tới sau khi tạo luồng
    Thì hệ thống trả `200`; định nghĩa của phiên bản mở (hoặc phiên bản được chọn ở chế độ chỉ đọc), bố cục sơ đồ, kết quả kiểm tra gần nhất, phiên bản catalog, danh sách người đang mở luồng, ETag phiên bản
    Và một phiên soạn thảo (EN-04-09) được tạo hoặc gia hạn cho người dùng, hết hạn sau 120 giây không có nhịp

  @US-04-010 @FR-04-010 @M @âm
  Kịch bản: US-04-010 âm 1 · Không tìm thấy luồng
    Biết luồng tồn tại
    Khi không tìm thấy luồng
    Thì hệ thống từ chối với ERR-04-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy luồng, hoặc bạn không có quyền xem luồng này."

  @US-04-011 @FR-04-011 @M
  Kịch bản: US-04-011 dương · Tạo phiên bản mới từ phiên bản đã có
    Biết luồng không có phiên bản mở; luồng không `RETIRED`
    Khi IE bấm "Tạo phiên bản mới" trên trình thiết kế ở chế độ chỉ đọc hoặc trên tab Phiên bản
    Thì hệ thống trả `201` với phiên bản mới `DRAFT`, `baseVersionNo`
    Và phiên bản mới sao chép định nghĩa, bố cục, ca kiểm thử liên kết của phiên bản gốc
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-011 @FR-04-011 @M @âm
  Kịch bản: US-04-011 âm 1 · Đã có phiên bản mở
    Biết luồng không có phiên bản mở; luồng không `RETIRED`
    Khi đã có phiên bản mở
    Thì hệ thống từ chối với ERR-04-016 (409)
    Và người dùng thấy thông báo "Luồng đã có bản nháp v{n} do {user} tạo."

  @US-04-011 @FR-04-011 @M @âm
  Kịch bản: US-04-011 âm 2 · Phiên bản gốc không tồn tại
    Biết luồng không có phiên bản mở; luồng không `RETIRED`
    Khi phiên bản gốc không tồn tại
    Thì hệ thống từ chối với ERR-04-004 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản v{n} của luồng này."

  @US-04-012 @FR-04-012 @M
  Kịch bản: US-04-012 dương · Bảng thành phần theo danh mục được phép, tìm kiếm và lọc theo vai trò chặng
    Biết trình thiết kế đang mở ở chế độ sửa; chỉ mục catalog của đúng `catalogVersion` đã tải
    Khi IE mở ngăn bảng thành phần, gõ ô tìm, chọn tab, hoặc bấm `＋` trên cạnh để chèn chặng
    Thì danh sách thành phần có tên Camel, tiêu đề tiếng Việt (nếu có), mô tả gốc, nhãn, biểu tượng nhóm, mức hỗ trợ (`stable`, `preview`, `deprecated`), mức native, cờ "cần kết nối PH-05", cờ "Kamelet tự viết của tenant"

  @US-04-012 @FR-04-012 @M @âm
  Kịch bản: US-04-012 âm 1 · Thành phần đã có trong luồng nhưng sau đó bị cấm
    Biết trình thiết kế đang mở ở chế độ sửa; chỉ mục catalog của đúng `catalogVersion` đã tải
    Khi thành phần đã có trong luồng nhưng sau đó bị cấm
    Thì hệ thống từ chối với ERR-04-011
    Và người dùng thấy thông báo "Không còn được phép"

  @US-04-012 @FR-04-012 @M @âm
  Kịch bản: US-04-012 âm 2 · Không tải được catalog
    Biết trình thiết kế đang mở ở chế độ sửa; chỉ mục catalog của đúng `catalogVersion` đã tải
    Khi không tải được catalog
    Thì hệ thống từ chối với ERR-04-047 (503)
    Và người dùng thấy thông báo "Danh mục thành phần tạm thời không tải được. Thử lại sau."

  @US-04-013 @FR-04-013 @M
  Kịch bản: US-04-013 dương · Thao tác trên sơ đồ: thêm, chèn, xóa, nối, rẽ nhánh, chọn nhiều, thu phóng, tự sắp xếp, hoàn tác
    Biết trình thiết kế mở ở chế độ sửa trên phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi IE kéo thả, bấm `＋` trên cạnh, dùng phím tắt (`Enter`, `Delete`, `Ctrl+D`, `Ctrl+Z`, `0`) hoặc menu chuột phải trên sơ đồ
    Thì cây tài nguyên Camel trong bộ nhớ trình duyệt và YAML sinh lại sau mỗi thay đổi
    Và chưa lưu lên máy chủ; chỉ báo trạng thái chuyển "Chưa lưu"

  @US-04-014 @FR-04-014 @M
  Kịch bản: US-04-014 dương · Cấu hình chặng bằng biểu mẫu sinh từ catalog, khôi phục giá trị gốc
    Biết một chặng hoặc route đang được chọn; lược đồ thành phần của `catalogVersion` hiện hành đã tải (API-04-071)
    Khi IE chọn chặng trên sơ đồ (Inspector) hoặc bấm "Mở rộng" để mở UI-04-05
    Thì giá trị tham số của chặng trên cây tài nguyên
    Và cây tài nguyên đổi, chưa lưu lên máy chủ

  @US-04-014 @FR-04-014 @M @âm
  Kịch bản: US-04-014 âm 1 · Lỗi kiểm tra tại chỗ không có mã máy chủ; khi lưu, lỗi lược đồ hiện là phát hiện VR-02 trong bảng Vấn đề (ERR-04-009 khi …
    Biết một chặng hoặc route đang được chọn; lược đồ thành phần của `catalogVersion` hiện hành đã tải (API-04-071)
    Khi lỗi kiểm tra tại chỗ không có mã máy chủ; khi lưu, lỗi lược đồ hiện là phát hiện VR-02 trong bảng Vấn đề (ERR-04-009 khi chặn gửi duyệt)
    Thì hệ thống từ chối với ERR-04-010 (422)
    Và người dùng thấy thông báo "Phát hiện giá trị giống bí mật ở chặng"

  @US-04-015 @FR-04-015 @M
  Kịch bản: US-04-015 dương · Trình soạn biểu thức có gợi ý, kiểm tra cú pháp và xem trước trên bản tin mẫu
    Biết trường đang soạn có kiểu biểu thức; có bản tin mẫu ghim (FR-04-022) nếu muốn xem trước
    Khi IE bấm vào trường biểu thức ở Inspector hoặc mở UI-04-06
    Thì biểu thức gán cho trường; kết quả xem trước; lỗi cú pháp
    Và cây tài nguyên đổi khi áp dụng; không lưu kết quả xem trước

  @US-04-015 @FR-04-015 @M @âm
  Kịch bản: US-04-015 âm 1 · Biểu thức không biên dịch được
    Biết trường đang soạn có kiểu biểu thức; có bản tin mẫu ghim (FR-04-022) nếu muốn xem trước
    Khi biểu thức không biên dịch được
    Thì hệ thống từ chối với ERR-04-037
    Và người dùng thấy thông báo "Biểu thức {language} có lỗi ở vị trí {pos}: {message}"

  @US-04-015 @FR-04-015 @M @âm
  Kịch bản: US-04-015 âm 2 · Bản tin mẫu vượt kích thước
    Biết trường đang soạn có kiểu biểu thức; có bản tin mẫu ghim (FR-04-022) nếu muốn xem trước
    Khi bản tin mẫu vượt kích thước
    Thì hệ thống từ chối với ERR-04-021 (413)
    Và người dùng thấy thông báo "Bản tin mẫu vượt {limit}."

  @US-04-016 @FR-04-016 @M
  Kịch bản: US-04-016 dương · Chọn kết nối PH-05 và tham chiếu bí mật thay vì nhập bí mật
    Biết chặng dùng thành phần có cờ "cần kết nối PH-05"
    Khi IE kéo thành phần cần kết nối vào sơ đồ (ô chọn mở tự động) hoặc bấm ô "Kết nối" trong biểu mẫu chặng
    Thì tham chiếu `{{conn:<mã>.<khóa>}}` trong tham số của chặng; tiêu đề hiển thị tên kết nối và trạng thái kiểm tra kết nối gần nhất
    Và cây tài nguyên chứa tham chiếu kết nối; chưa lưu

  @US-04-016 @FR-04-016 @M @âm
  Kịch bản: US-04-016 âm 1 · Kết nối không hợp lệ
    Biết chặng dùng thành phần có cờ "cần kết nối PH-05"
    Khi kết nối không hợp lệ
    Thì hệ thống từ chối với ERR-04-013
    Và người dùng thấy thông báo "Kết nối"

  @US-04-016 @FR-04-016 @M @âm
  Kịch bản: US-04-016 âm 2 · PH-05 không sẵn sàng
    Biết chặng dùng thành phần có cờ "cần kết nối PH-05"
    Khi PH-05 không sẵn sàng
    Thì hệ thống từ chối với ERR-04-047 (503)
    Và người dùng thấy thông báo "Chưa lấy được danh sách kết nối từ PH-05. Thử lại sau."

  @US-04-017 @FR-04-017 @M
  Kịch bản: US-04-017 dương · Đồng bộ hai chiều giữa sơ đồ, thuộc tính và YAML, không mất dữ liệu khi quay vòng
    Biết trình thiết kế đang mở
    Khi người dùng chọn chế độ Sơ đồ, YAML hoặc Chia đôi; sửa trên một trong hai phía
    Thì sơ đồ, Inspector và YAML luôn biểu diễn cùng một cây tài nguyên
    Và bố cục sơ đồ (vị trí, ghi chú dán, trạng thái thu gọn nhóm) lưu riêng (mục 4.4), không làm bẩn YAML

  @US-04-017 @FR-04-017 @M @âm
  Kịch bản: US-04-017 âm 1 · YAML lỗi cú pháp
    Biết trình thiết kế đang mở
    Khi YAML lỗi cú pháp
    Thì hệ thống từ chối với ERR-04-008 (422)
    Và người dùng thấy thông báo "YAML đang có lỗi, sơ đồ hiển thị phiên bản hợp lệ gần nhất"

  @US-04-018 @FR-04-018 @S
  Kịch bản: US-04-018 dương · Soạn Kamelet và gửi đăng ký Kamelet tự viết
    Biết luồng loại `KAMELET` đã tạo (FR-04-003)
    Khi IE mở luồng loại `KAMELET` trên UI-04-08
    Thì luồng loại `KAMELET`
    Và phiên bản Kamelet ở `DRAFT` cho tới khi được duyệt, phát hành
    Và sự kiện được phát: Theo nhóm D khi gửi duyệt, phát hành
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-018 @FR-04-018 @S @âm
  Kịch bản: US-04-018 âm 1 · Tên trùng Kamelet nền hoặc Kamelet tự viết khác trong tenant
    Biết luồng loại `KAMELET` đã tạo (FR-04-003)
    Khi tên trùng Kamelet nền hoặc Kamelet tự viết khác trong tenant
    Thì hệ thống từ chối với ERR-04-036 (409)
    Và người dùng thấy thông báo "Đã có Kamelet tên"

  @US-04-019 @FR-04-019 @S
  Kịch bản: US-04-019 dương · Soạn Pipe
    Biết luồng loại `PIPE` đã tạo
    Khi IE mở luồng loại `PIPE` trên UI-04-09
    Thì luồng loại `PIPE`
    Và phiên bản `DRAFT` được cập nhật khi lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-019 @FR-04-019 @S @âm
  Kịch bản: US-04-019 âm 1 · Kamelet sai loại ở vị trí
    Biết luồng loại `PIPE` đã tạo
    Khi Kamelet sai loại ở vị trí
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt."

  @US-04-020 @FR-04-020 @M
  Kịch bản: US-04-020 dương · Trình ánh xạ dữ liệu sinh biểu thức JQ
    Biết có lược đồ hoặc tài liệu mẫu cho nguồn và đích
    Khi IE thêm chặng `transform` và bấm "Mở trình ánh xạ" (UI-04-07)
    Thì một chặng `transform` (hoặc `setBody`) với biểu thức `jq` sinh ra; tệp mô tả ánh xạ `*.dhmap.json` lưu cùng phiên bản để mở lại trên trình ánh xạ
    Và cây tài nguyên và tệp ánh xạ của phiên bản mở được cập nhật khi lưu

  @US-04-020 @FR-04-020 @M @âm
  Kịch bản: US-04-020 âm 1 · Ánh xạ tới trường đích không tồn tại, vòng tham chiếu
    Biết có lược đồ hoặc tài liệu mẫu cho nguồn và đích
    Khi ánh xạ tới trường đích không tồn tại, vòng tham chiếu
    Thì hệ thống từ chối với ERR-04-038 (422)
    Và người dùng thấy thông báo "Ánh xạ tới trường"

  @US-04-020 @FR-04-020 @M @âm
  Kịch bản: US-04-020 âm 2 · Tài liệu mẫu vượt 1 MiB
    Biết có lược đồ hoặc tài liệu mẫu cho nguồn và đích
    Khi tài liệu mẫu vượt 1 MiB
    Thì hệ thống từ chối với ERR-04-021 (413)
    Và người dùng thấy thông báo "Bản tin mẫu vượt {limit}."

  @US-04-021 @FR-04-021 @S
  Kịch bản: US-04-021 dương · Bean, cấu hình cấp tệp và metadata
    Biết luồng đang mở ở chế độ sửa
    Khi IE chọn mục `beans`, `routeConfiguration` hoặc metadata trên thanh thực thể, mở UI-04-10
    Thì phần tử cấp tệp trong YAML
    Và cây tài nguyên đổi, lưu theo FR-04-024

  @US-04-021 @FR-04-021 @S @âm
  Kịch bản: US-04-021 âm 1 · Lớp bean không được phép
    Biết luồng đang mở ở chế độ sửa
    Khi lớp bean không được phép
    Thì hệ thống từ chối với ERR-04-011 (422)
    Và người dùng thấy thông báo "Thành phần"

  @US-04-022 @FR-04-022 @M
  Kịch bản: US-04-022 dương · Ghim bản tin mẫu theo chặng
    Biết chặng đang chọn trong phiên bản mở
    Khi IE bấm "Ghim bản tin mẫu" ở cột Vào của UI-04-05 hoặc ghim từ kết quả một lần chạy thử
    Thì bản tin mẫu gắn với chặng, dùng cho xem trước biểu thức và ánh xạ
    Và bản tin mẫu lưu cùng phiên bản, không có trong YAML chuẩn hóa và băm nội dung

  @US-04-022 @FR-04-022 @M @âm
  Kịch bản: US-04-022 âm 1 · Bản tin mẫu vượt 256 KiB
    Biết chặng đang chọn trong phiên bản mở
    Khi bản tin mẫu vượt 256 KiB
    Thì hệ thống từ chối với ERR-04-021 (413)
    Và người dùng thấy thông báo "Bản tin mẫu vượt {limit}."

  @US-04-023 @FR-04-023 @M
  Kịch bản: US-04-023 dương · Kiểm tra hợp lệ định nghĩa luồng
    Biết có định nghĩa YAML (đã lưu hoặc chưa lưu)
    Khi trình duyệt chạy sau mỗi thay đổi; máy chủ chạy khi lưu (`DESIGN`), gửi duyệt (`SUBMIT`), phát hành (`PUBLISH`); IE bấm "Kiểm tra" ở bảng Vấn đề
    Thì hệ thống trả `200`; `valid`, danh sách phát hiện `{code, severity ∈ ERROR, WARN, INFO, path, nodeId, message, ruleId}`
    Và kết quả kiểm tra gần nhất lưu kèm phiên bản (khi chạy ở máy chủ)

  @US-04-023 @FR-04-023 @M @âm
  Kịch bản: US-04-023 âm 1 · Còn lỗi
    Biết có định nghĩa YAML (đã lưu hoặc chưa lưu)
    Khi còn lỗi
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi {action}."

  @US-04-023 @FR-04-023 @M @âm
  Kịch bản: US-04-023 âm 2 · Bí mật viết thẳng
    Biết có định nghĩa YAML (đã lưu hoặc chưa lưu)
    Khi bí mật viết thẳng
    Thì hệ thống từ chối với ERR-04-010 (422)
    Và người dùng thấy thông báo "Phát hiện giá trị giống bí mật ở chặng"

  @US-04-024 @FR-04-024 @M
  Kịch bản: US-04-024 dương · Lưu bản nháp tự động, phát hiện xung đột, khôi phục phiên nháp
    Biết phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi trình duyệt tự lưu 30 giây sau thay đổi cuối; IE nhấn `Ctrl+S` hoặc bấm "Lưu"
    Thì hệ thống trả `200` với ETag mới, kết quả kiểm tra mức `DESIGN`, thời điểm lưu
    Và phiên bản mở được cập nhật; chỉ mục route, endpoint tính lại; người dùng được thêm vào danh sách người đóng góp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-024 @FR-04-024 @M @âm
  Kịch bản: US-04-024 âm 1 · Phiên bản không còn ở trạng thái sửa được
    Biết phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi phiên bản không còn ở trạng thái sửa được
    Thì hệ thống từ chối với ERR-04-005 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-04-024 @FR-04-024 @M @âm
  Kịch bản: US-04-024 âm 2 · ETag không khớp
    Biết phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi ETag không khớp
    Thì hệ thống từ chối với ERR-04-006 (412)
    Và người dùng thấy thông báo "{user} đã lưu phiên bản này lúc {time}. Thay đổi của bạn chưa được lưu."

  @US-04-025 @FR-04-025 @S
  Kịch bản: US-04-025 dương · Thư viện khuôn mẫu luồng
    Biết với tạo khuôn của tỉnh: có phiên bản luồng đã duyệt
    Khi IE mở UI-04-19 hoặc chọn "Từ khuôn mẫu" ở UI-04-03; TA bấm "Lưu thành khuôn mẫu" trên phiên bản đã duyệt
    Thì danh sách và chi tiết khuôn mẫu; định nghĩa đã điền tham số khi tạo luồng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-025 @FR-04-025 @S @âm
  Kịch bản: US-04-025 âm 1 · Khuôn không tồn tại hoặc không được phép
    Biết với tạo khuôn của tỉnh: có phiên bản luồng đã duyệt
    Khi khuôn không tồn tại hoặc không được phép
    Thì hệ thống từ chối với ERR-04-039 (404)
    Và người dùng thấy thông báo "Khuôn mẫu"

  @US-04-026 @FR-04-026 @C
  Kịch bản: US-04-026 dương · Ghi chú dán và luồng con dùng lại
    Biết trình thiết kế mở ở chế độ sửa; với luồng con ngoài tệp, luồng đích đã phát hành trong tenant
    Khi IE chọn "Thêm ghi chú" trên menu sơ đồ hoặc kéo chặng gọi `direct:` và chọn luồng con
    Thì ghi chú trong bố cục; chặng gọi luồng con trong cây tài nguyên
    Và bố cục và cây tài nguyên đổi, lưu theo FR-04-024

  @US-04-026 @FR-04-026 @C @âm
  Kịch bản: US-04-026 âm 1 · Tham chiếu tới route không tồn tại
    Biết trình thiết kế mở ở chế độ sửa; với luồng con ngoài tệp, luồng đích đã phát hành trong tenant
    Khi tham chiếu tới route không tồn tại
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt."

  @US-04-027 @FR-04-027 @M
  Kịch bản: US-04-027 dương · Tải xuống, nhập YAML và xuất gói luồng
    Biết phiên bản tồn tại; với nhập, phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi người dùng bấm "Tải xuống" hoặc "Nhập YAML" trên thanh công cụ trình thiết kế
    Thì tệp tải xuống tên `{flow}-v{n}.camel.yaml` hoặc `{flow}-v{n}.dhflow.zip`; với nhập, `200` và ETag mới
    Và tải xuống không đổi dữ liệu; nhập thay định nghĩa của phiên bản mở
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-027 @FR-04-027 @M @âm
  Kịch bản: US-04-027 âm 1 · YAML nhập lỗi cú pháp
    Biết phiên bản tồn tại; với nhập, phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi YAML nhập lỗi cú pháp
    Thì hệ thống từ chối với ERR-04-008 (422)
    Và người dùng thấy thông báo "YAML có lỗi cú pháp ở dòng {line}, cột {column}: {message}"

  @US-04-027 @FR-04-027 @M @âm
  Kịch bản: US-04-027 âm 2 · YAML nhập chứa bí mật
    Biết phiên bản tồn tại; với nhập, phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`
    Khi YAML nhập chứa bí mật
    Thì hệ thống từ chối với ERR-04-010 (422)

  # ---- EP-04-C · Chạy thử và ca kiểm thử

  @US-04-030 @FR-04-030 @M
  Kịch bản: US-04-030 dương · Chạy thử luồng trên sandbox với đích mô phỏng
    Biết phiên bản không có lỗi mức `ERROR` ở mức `DESIGN`; tenant chưa vượt hạn mức chạy thử đồng thời (`04.test.max-concurrent`, mặc định 5)
    Khi IE bấm "Chạy thử" trên UI-04-04 hoặc UI-04-11; bộ chạy ca kiểm thử gọi khi gửi duyệt (FR-04-040)
    Thì hệ thống trả `202 Accepted` với `runId`, sau đó kết quả qua API-04-042 hoặc luồng sự kiện máy chủ (SSE, API-04-099)
    Và một `test_run` và các `test_run_step`; phiên bản được đánh dấu "có lần chạy thử đạt" nếu `PASSED` ở chế độ không mô phỏng
    Và sự kiện được phát: EVT-04-10 `testrun.completed`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-030 @FR-04-030 @M @âm
  Kịch bản: US-04-030 âm 1 · Định nghĩa còn lỗi
    Biết phiên bản không có lỗi mức `ERROR` ở mức `DESIGN`; tenant chưa vượt hạn mức chạy thử đồng thời (`04.test.max-concurrent`, mặc định 5)
    Khi định nghĩa còn lỗi
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi chạy thử."

  @US-04-030 @FR-04-030 @M @âm
  Kịch bản: US-04-030 âm 2 · Vượt hạn mức đồng thời
    Biết phiên bản không có lỗi mức `ERROR` ở mức `DESIGN`; tenant chưa vượt hạn mức chạy thử đồng thời (`04.test.max-concurrent`, mặc định 5)
    Khi vượt hạn mức đồng thời
    Thì hệ thống từ chối với ERR-04-019
    Và người dùng thấy thông báo "Môi trường chạy thử đang bận hoặc chưa sẵn sàng (tỉnh đang có {n}/{max} lần chạy thử đồng thời). Thử lại sau ít phút."

  @US-04-031 @FR-04-031 @S
  Kịch bản: US-04-031 dương · Ca kiểm thử của luồng và bộ chạy
    Biết luồng `ROUTE` hoặc `PIPE` tồn tại
    Khi IE mở UI-04-13, bấm "+ Ca kiểm thử" hoặc "Lưu thành ca kiểm thử" từ một lần chạy thử
    Thì bộ ca lưu thành luồng loại `TEST` gắn với luồng đích, hoặc lưu kèm phiên bản
    Và ca kiểm thử lưu ở EN-04-15; ca xóa chuyển sang ngừng dùng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-031 @FR-04-031 @S @âm
  Kịch bản: US-04-031 âm 1 · Ca không có khẳng định
    Biết luồng `ROUTE` hoặc `PIPE` tồn tại
    Khi ca không có khẳng định
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi lưu."

  @US-04-032 @FR-04-032 @M
  Kịch bản: US-04-032 dương · Nhật ký chạy thử, xem lại, so sánh hai lần chạy, dọn nhật ký
    Biết luồng có ít nhất một lần chạy thử
    Khi người dùng mở UI-04-12, chọn một lần chạy hoặc chọn hai lần rồi bấm "So sánh"; tác vụ dọn chạy hằng ngày
    Thì danh sách lần chạy; chi tiết gồm sơ đồ thời gian từng chặng (waterfall), thân và tiêu đề trước, sau mỗi chặng (nếu có), `traceId` liên kết sang PH-13, phiên bản định nghĩa đã dùng; so sánh thời lượng từng chặng của hai lần chạy
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-032 @FR-04-032 @M @âm
  Kịch bản: US-04-032 âm 1 · Không tìm thấy lần chạy
    Biết luồng có ít nhất một lần chạy thử
    Khi không tìm thấy lần chạy
    Thì hệ thống từ chối với ERR-04-030 (404)

  @US-04-032 @FR-04-032 @M @âm
  Kịch bản: US-04-032 âm 2 · Xem thân lần chạy dữ liệu thật khi thiếu quyền
    Biết luồng có ít nhất một lần chạy thử
    Khi xem thân lần chạy dữ liệu thật khi thiếu quyền
    Thì hệ thống từ chối với ERR-04-045 (403)
    Và người dùng thấy thông báo "Bạn chưa có quyền xem dữ liệu thật của lần chạy thử này."

  @US-04-033 @FR-04-033 @M
  Kịch bản: US-04-033 dương · Phủ kết quả chạy thử và số liệu chạy thật lên sơ đồ
    Biết có lần chạy thử; với số liệu thật, phiên bản đang chạy và PH-13 sẵn sàng
    Khi lần chạy thử kết thúc; người dùng bật lớp phủ "Số liệu" ở chế độ chỉ đọc của phiên bản đang chạy
    Thì lớp phủ trên sơ đồ

  @US-04-033 @FR-04-033 @M @âm
  Kịch bản: US-04-033 âm 1 · PH-13 không sẵn sàng
    Biết có lần chạy thử; với số liệu thật, phiên bản đang chạy và PH-13 sẵn sàng
    Khi PH-13 không sẵn sàng
    Thì hệ thống từ chối với ERR-04-047 (503)
    Và người dùng thấy thông báo "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."

  # ---- EP-04-D · Duyệt, phát hành và triển khai

  @US-04-040 @FR-04-040 @M
  Kịch bản: US-04-040 dương · Gửi duyệt phiên bản
    Biết phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`; đã lưu (không còn thay đổi cục bộ)
    Khi IE bấm "Gửi duyệt" trên UI-04-04 và điền hộp gửi duyệt
    Thì hệ thống trả `200`; phiên bản `PENDING_REVIEW`; việc "Duyệt luồng" trong hộp "Việc của tôi" của người có quyền duyệt
    Và nội dung phiên bản bất biến; danh sách người đóng góp được chụp
    Và sự kiện được phát: EVT-04-03 `version.submitted`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-040 @FR-04-040 @M @âm
  Kịch bản: US-04-040 âm 1 · Còn lỗi kiểm tra
    Biết phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`; đã lưu (không còn thay đổi cục bộ)
    Khi còn lỗi kiểm tra
    Thì hệ thống từ chối với ERR-04-009 (422)
    Và người dùng thấy thông báo "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt."

  @US-04-040 @FR-04-040 @M @âm
  Kịch bản: US-04-040 âm 2 · Thiếu lần chạy thử đạt trên đúng băm
    Biết phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`; đã lưu (không còn thay đổi cục bộ)
    Khi thiếu lần chạy thử đạt trên đúng băm
    Thì hệ thống từ chối với ERR-04-014 (409)
    Và người dùng thấy thông báo "Chưa có lần chạy thử đạt (không mô phỏng) cho đúng nội dung đang gửi, hoặc còn ca kiểm thử chưa đạt."

  @US-04-041 @FR-04-041 @M
  Kịch bản: US-04-041 dương · Duyệt bốn mắt với so sánh YAML và so sánh sơ đồ
    Biết phiên bản `PENDING_REVIEW`
    Khi IA mở việc "Duyệt luồng" trong "Việc của tôi" hoặc hàng đợi UI-04-14
    Thì hệ thống trả `200`; phiên bản `APPROVED` hoặc `CHANGES_REQUESTED`
    Và quyết định, ý kiến, checklist, băm định nghĩa được duyệt lưu ở EN-04-05
    Và sự kiện được phát: EVT-04-04 `version.approved` hoặc EVT-04-05 `version.changes-requested`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-041 @FR-04-041 @M @âm
  Kịch bản: US-04-041 âm 1 · Tự duyệt
    Biết phiên bản `PENDING_REVIEW`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-04-015 (403)
    Và người dùng thấy thông báo "Bạn đã tạo, đóng góp hoặc gửi duyệt phiên bản này nên không thể tự duyệt. Cần một người duyệt khác."

  @US-04-041 @FR-04-041 @M @âm
  Kịch bản: US-04-041 âm 2 · Chưa xem so sánh
    Biết phiên bản `PENDING_REVIEW`
    Khi chưa xem so sánh
    Thì hệ thống từ chối với ERR-04-005 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-04-042 @FR-04-042 @M
  Kịch bản: US-04-042 dương · Phát hành qua GitOps và theo dõi tình trạng triển khai
    Biết phiên bản `APPROVED`; kiểm tra mức `PUBLISH` cho môi trường đích không có `ERROR`; không trong thời gian đóng băng thay đổi
    Khi duyệt ở FR-04-041 (mặc định), hoặc IA bấm "Phát hành" trên UI-04-15. Phát hành theo lịch (`scheduledAt`) thuộc đợt 2
    Thì hệ thống trả `202 Accepted` với `deploymentId`; tiến trình qua API-04-106 (SSE)
    Và một `deployment` `PENDING`; commit trong kho cấu hình
    Và sự kiện được phát: EVT-04-06 `deployment.requested`; sau đó EVT-04-07 `deployment.status-changed` mỗi lần trạng thái đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-042 @FR-04-042 @M @âm
  Kịch bản: US-04-042 âm 1 · Phiên bản chưa duyệt
    Biết phiên bản `APPROVED`; kiểm tra mức `PUBLISH` cho môi trường đích không có `ERROR`; không trong thời gian đóng băng thay đổi
    Khi phiên bản chưa duyệt
    Thì hệ thống từ chối với ERR-04-005 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-04-042 @FR-04-042 @M @âm
  Kịch bản: US-04-042 âm 2 · Chưa qua môi trường trước theo thứ tự
    Biết phiên bản `APPROVED`; kiểm tra mức `PUBLISH` cho môi trường đích không có `ERROR`; không trong thời gian đóng băng thay đổi
    Khi chưa qua môi trường trước theo thứ tự
    Thì hệ thống từ chối với ERR-04-023 (409)
    Và người dùng thấy thông báo "Phiên bản phải đồng bộ, khỏe ở {previousEnv} (và chạy ổn định đủ {minutes} phút) trước khi lên {env}, hoặc luồng chưa triển khai ở {env}."

  @US-04-043 @FR-04-043 @M
  Kịch bản: US-04-043 dương · So sánh hai phiên bản bất kỳ
    Biết cả hai phiên bản tồn tại
    Khi người dùng chọn hai phiên bản trên tab Phiên bản rồi bấm "So sánh", hoặc mở tab so sánh trên màn duyệt
    Thì hệ thống trả `200`; khác biệt YAML (unified hoặc hai cột), khác biệt cây (chặng thêm, xóa, đổi, di chuyển; tham số đổi theo chặng), tóm tắt (số chặng đổi, thành phần mới, kết nối mới, topic mới, điểm vào mới)

  @US-04-044 @FR-04-044 @M
  Kịch bản: US-04-044 dương · Quay lui về phiên bản trước
    Biết phiên bản đích từng được duyệt (`APPROVED` hoặc `SUPERSEDED`), cùng loại tài nguyên; kiểm tra mức `PUBLISH` hiện tại không có `ERROR` (thành phần có thể đã bị cấm, kết nối có thể đã bị thu hồi)
    Khi IA bấm "Quay lui" trên UI-04-15, hoặc nhận gợi ý quay lui sau phát hành (FR-04-042)
    Thì hệ thống trả `202` như FR-04-042
    Và phiên bản đang chạy chuyển `ROLLED_BACK`; phiên bản đích chạy lại
    Và sự kiện được phát: EVT-04-06, EVT-04-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-044 @FR-04-044 @M @âm
  Kịch bản: US-04-044 âm 1 · Phiên bản đích dùng thành phần đã bị cấm
    Biết phiên bản đích từng được duyệt (`APPROVED` hoặc `SUPERSEDED`), cùng loại tài nguyên; kiểm tra mức `PUBLISH` hiện tại không có `ERROR` (thành phần có thể đã bị cấm, kết nối có thể đã bị thu hồi)
    Khi phiên bản đích dùng thành phần đã bị cấm
    Thì hệ thống từ chối với ERR-04-040 (409)
    Và người dùng thấy thông báo "Không quay lui được về v{n} vì phiên bản đó dùng thành phần"

  @US-04-044 @FR-04-044 @M @âm
  Kịch bản: US-04-044 âm 2 · Thiếu lý do
    Biết phiên bản đích từng được duyệt (`APPROVED` hoặc `SUPERSEDED`), cùng loại tài nguyên; kiểm tra mức `PUBLISH` hiện tại không có `ERROR` (thành phần có thể đã bị cấm, kết nối có thể đã bị thu hồi)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-04-025 (400)

  @US-04-045 @FR-04-045 @S
  Kịch bản: US-04-045 dương · Thăng cấp phiên bản qua các môi trường
    Biết phiên bản `SYNCED` và khỏe ở môi trường trước theo `04.env.stages`; đã chạy ổn định ít nhất `04.env.soak-minutes` (mặc định 30 ở STAGING, 0 ở TEST)
    Khi người có quyền bấm "Thăng cấp lên {env}" trên UI-04-15
    Thì hệ thống trả `202` như FR-04-042
    Và một `deployment` mới ở môi trường đích
    Và sự kiện được phát: EVT-04-06, EVT-04-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-045 @FR-04-045 @S @âm
  Kịch bản: US-04-045 âm 1 · Chưa đủ điều kiện ở môi trường trước
    Biết phiên bản `SYNCED` và khỏe ở môi trường trước theo `04.env.stages`; đã chạy ổn định ít nhất `04.env.soak-minutes` (mặc định 30 ở STAGING, 0 ở TEST)
    Khi chưa đủ điều kiện ở môi trường trước
    Thì hệ thống từ chối với ERR-04-023 (409)
    Và người dùng thấy thông báo "Phiên bản phải đồng bộ, khỏe ở {previousEnv} (và chạy ổn định đủ {minutes} phút) trước khi lên {env}, hoặc luồng chưa triển khai ở {env}."

  # ---- EP-04-E · Vận hành luồng

  @US-04-050 @FR-04-050 @M
  Kịch bản: US-04-050 dương · Kích hoạt, tạm dừng, tiếp tục luồng và từng route có lý do
    Biết luồng có triển khai `SYNCED` ở môi trường chọn
    Khi người dùng bấm "Tạm dừng", "Tiếp tục" hoặc "Dừng khẩn" trên tab Triển khai của UI-04-02
    Thì hệ thống trả `202` với `commandId`; trạng thái lệnh qua API-04-107
    Và lệnh `RuntimeCommand` (EN-04-10); khi tất cả bản sao xác nhận, trạng thái mong muốn ghi vào kho cấu hình để lần đồng bộ sau không bật lại luồng
    Và sự kiện được phát: EVT-04-11 `runtime.command` (topic điều khiển), EVT-04-08 `flow.runtime-state-changed` khi đã xác nhận
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-050 @FR-04-050 @M @âm
  Kịch bản: US-04-050 âm 1 · Thiếu lý do
    Biết luồng có triển khai `SYNCED` ở môi trường chọn
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-04-025 (400)
    Và người dùng thấy thông báo "Vui lòng nhập lý do (ít nhất {min} ký tự)."

  @US-04-050 @FR-04-050 @M @âm
  Kịch bản: US-04-050 âm 2 · Luồng chưa triển khai ở môi trường
    Biết luồng có triển khai `SYNCED` ở môi trường chọn
    Khi luồng chưa triển khai ở môi trường
    Thì hệ thống từ chối với ERR-04-023 (409)

  @US-04-051 @FR-04-051 @M
  Kịch bản: US-04-051 dương · Xem tình trạng runtime của luồng
    Biết luồng có ít nhất một triển khai
    Khi người dùng mở tab Triển khai của UI-04-02; giao diện làm mới theo nhịp tim
    Thì hệ thống trả `200`; theo từng môi trường: phiên bản mong muốn và phiên bản đang chạy, băm, trạng thái đồng bộ, namespace, hồ sơ runtime, số bản sao đang chạy trên tổng, sức khỏe từng bản sao, trạng thái từng route (`Started`, `Suspended` …

  @US-04-052 @FR-04-052 @M
  Kịch bản: US-04-052 dương · Danh sách điểm kết nối của luồng và số liệu theo điểm kết nối
    Biết phiên bản có chỉ mục điểm kết nối (EN-04-04)
    Khi người dùng mở tab Điểm kết nối của UI-04-02 và chọn khoảng thời gian
    Thì hệ thống trả `200`; API này cũng là API đọc điểm vào REST của luồng mà PH-02 dùng khi khai backend loại `FLOW` (FR-02-022) …

  @US-04-053 @FR-04-053 @S
  Kịch bản: US-04-053 dương · Giám sát theo luồng nhúng từ PH-13
    Biết luồng có triển khai; PH-13 sẵn sàng
    Khi người dùng mở tab Giám sát của UI-04-02
    Thì bảng điều khiển nhúng

  @US-04-053 @FR-04-053 @S @âm
  Kịch bản: US-04-053 âm 1 · PH-13 không sẵn sàng
    Biết luồng có triển khai; PH-13 sẵn sàng
    Khi PH-13 không sẵn sàng
    Thì hệ thống từ chối với ERR-04-047 (503)
    Và người dùng thấy thông báo "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."

  # ---- EP-04-F · Data plane: khuôn mẫu route chuẩn

  @US-04-060 @FR-04-060 @M
  Kịch bản: US-04-060 dương · Khung chín chặng chuẩn và thư viện nền
    Biết hồ sơ runtime chứa `dh-runtime-lib` và `dh-runtime-kamelets`; luồng tham chiếu `routeConfigurationId: dh-default-config`
    Khi `FlowLoader` nạp luồng; mỗi exchange đi vào route của luồng
    Thì exchange đã qua đủ chặng; phản hồi cho bên gọi hoặc bản tin đã gửi đích
    Và chỉ số, vết, nhật ký kết nối của lượt được phát (FR-04-074)
    Và sự kiện được phát: EVT-04-14 (chặng `audit`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-060 @FR-04-060 @M @âm
  Kịch bản: US-04-060 âm 1 · Luồng đối ngoại thiếu chặng khi gửi duyệt
    Biết hồ sơ runtime chứa `dh-runtime-lib` và `dh-runtime-kamelets`; luồng tham chiếu `routeConfigurationId: dh-default-config`
    Khi luồng đối ngoại thiếu chặng khi gửi duyệt
    Thì hệ thống từ chối với ERR-04-012 (422)
    Và người dùng thấy thông báo "Luồng đối ngoại phải có đủ chín chặng chuẩn. Đang thiếu: {stages}."

  @US-04-061 @FR-04-061 @M
  Kịch bản: US-04-061 dương · Tiếp nhận đồng bộ HTTP và SOAP qua APISIX
    Biết luồng có điểm vào `platform-http` (REST) hoặc `cxf` (SOAP, chỉ hồ sơ JVM nếu native chưa hỗ trợ đủ) đang `Started`; APISIX đã định tuyến đường dẫn tới runtime
    Khi HTTT gửi yêu cầu HTTP, SOAP tới đường dẫn công bố; APISIX nội bộ (`apisix-int`) chuyển vào `dh-runtime`
    Thì phản hồi HTTP của luồng; tiêu đề `traceparent`
    Và exchange mang tiêu đề nội bộ bất biến cho các chặng sau
    Và sự kiện được phát: EVT-04-14 ở chặng `audit`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-061 @FR-04-061 @M @âm
  Kịch bản: US-04-061 âm 1 · Thân vượt giới hạn
    Biết luồng có điểm vào `platform-http` (REST) hoặc `cxf` (SOAP, chỉ hồ sơ JVM nếu native chưa hỗ trợ đủ) đang `Started`; APISIX đã định tuyến đường dẫn tới runtime
    Khi thân vượt giới hạn
    Thì hệ thống từ chối với ERR-04-107 (413)
    Và người dùng thấy thông báo "Bản tin vượt kích thước tối đa {limit} của dịch vụ."

  @US-04-061 @FR-04-061 @M @âm
  Kịch bản: US-04-061 âm 2 · Đường dẫn không khớp route
    Biết luồng có điểm vào `platform-http` (REST) hoặc `cxf` (SOAP, chỉ hồ sơ JVM nếu native chưa hỗ trợ đủ) đang `Started`; APISIX đã định tuyến đường dẫn tới runtime
    Khi đường dẫn không khớp route
    Thì hệ thống từ chối với ERR-04-111 (404)
    Và người dùng thấy thông báo "Không có dịch vụ tại đường dẫn này."

  @US-04-062 @FR-04-062 @M
  Kịch bản: US-04-062 dương · Tiếp nhận bất đồng bộ từ Kafka
    Biết topic đã đăng ký ở PH-10 và luồng có quyền subscribe (VR-10)
    Khi có bản tin mới trên topic, ví dụ `t68.hotich.khai-sinh.created.v1`
    Thì bản tin đã xử lý; offset được ghi nhận
    Và offset của nhóm tiêu thụ tiến lên sau khi xử lý xong
    Và sự kiện được phát: EVT-04-14; bản tin DLQ khi lỗi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-062 @FR-04-062 @M @âm
  Kịch bản: US-04-062 âm 1 · Không giải tuần tự được
    Biết topic đã đăng ký ở PH-10 và luồng có quyền subscribe (VR-10)
    Khi không giải tuần tự được
    Thì hệ thống từ chối với ERR-04-101
    Và người dùng thấy thông báo "Bản tin sai lược đồ {schemaRef}."

  @US-04-062 @FR-04-062 @M @âm
  Kịch bản: US-04-062 âm 2 · Lỗi xử lý ở chặng sau
    Biết topic đã đăng ký ở PH-10 và luồng có quyền subscribe (VR-10)
    Khi lỗi xử lý ở chặng sau
    Thì theo FR-04-070

  @US-04-063 @FR-04-063 @M
  Kịch bản: US-04-063 dương · Kiểm tra lược đồ bản tin
    Biết chặng `schema` khai `schemaRef` (mã lược đồ Apicurio hoặc PH-06) và `format`
    Khi bản tin tới chặng `schema`
    Thì bản tin hợp lệ có `dh-data-classes`; hoặc lỗi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-063 @FR-04-063 @M @âm
  Kịch bản: US-04-063 âm 1 · Sai lược đồ
    Biết chặng `schema` khai `schemaRef` (mã lược đồ Apicurio hoặc PH-06) và `format`
    Khi sai lược đồ
    Thì hệ thống từ chối với ERR-04-101, ERR-04-101 (400)
    Và người dùng thấy thông báo "Bản tin không đúng lược đồ {schemaRef}: {n} lỗi."

  @US-04-064 @FR-04-064 @M
  Kịch bản: US-04-064 dương · Ủy quyền qua OPA
    Biết OPA chạy cục bộ (sidecar hoặc dịch vụ trong namespace) với gói chính sách của tenant
    Khi bản tin tới chặng `authz`
    Thì bản tin có `dh-obligations`; hoặc lỗi 403
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-064 @FR-04-064 @M @âm
  Kịch bản: US-04-064 âm 1 · OPA từ chối, hoặc không phản hồi trong 200 ms (đóng an toàn)
    Biết OPA chạy cục bộ (sidecar hoặc dịch vụ trong namespace) với gói chính sách của tenant
    Khi OPA từ chối, hoặc không phản hồi trong 200 ms (đóng an toàn)
    Thì hệ thống từ chối với ERR-04-102 (403)
    Và người dùng thấy thông báo "Bên gọi không được phép dùng dịch vụ này cho mục đích đã khai."

  @US-04-065 @FR-04-065 @M
  Kịch bản: US-04-065 dương · Chuyển đổi, chuẩn hóa về CDM và chuyển mã qua PH-07
    Biết chặng `transform` có `jq` hoặc `mappingRef` (từ FR-04-020); ảnh chụp bảng ánh xạ PH-07 đã nạp
    Khi bản tin tới chặng `transform`
    Thì thân theo CDM hoặc định dạng đích

  @US-04-065 @FR-04-065 @M @âm
  Kịch bản: US-04-065 âm 1 · Lỗi chuyển đổi hoặc mã không có trong bảng với cấu hình `FAIL`
    Biết chặng `transform` có `jq` hoặc `mappingRef` (từ FR-04-020); ảnh chụp bảng ánh xạ PH-07 đã nạp
    Khi lỗi chuyển đổi hoặc mã không có trong bảng với cấu hình `FAIL`
    Thì hệ thống từ chối với ERR-04-108 (422)
    Và người dùng thấy thông báo "Không chuyển đổi được dữ liệu: {lý do ngắn}."

  @US-04-066 @FR-04-066 @M
  Kịch bản: US-04-066 dương · Làm giàu bản tin
    Biết chặng `enrich` khai `uri` (kết nối PH-05) hoặc `direct` (luồng con)
    Khi bản tin tới chặng `enrich`
    Thì thân đã bổ sung, hoặc có cờ `dh-enrich-partial`

  @US-04-066 @FR-04-066 @M @âm
  Kịch bản: US-04-066 âm 1 · Nguồn lỗi hoặc quá thời gian với `onError = FAIL`
    Biết chặng `enrich` khai `uri` (kết nối PH-05) hoặc `direct` (luồng con)
    Khi nguồn lỗi hoặc quá thời gian với `onError = FAIL`
    Thì hệ thống từ chối với ERR-04-108, ERR-04-108 (422)
    Và người dùng thấy thông báo "Không chuyển đổi được dữ liệu: {lý do ngắn}."

  @US-04-067 @FR-04-067 @M
  Kịch bản: US-04-067 dương · Che, giả danh dữ liệu cá nhân theo chính sách PH-09
    Biết có `dh-data-classes` (chặng `schema`) và `dh-obligations` (chặng `authz`); chính sách che của PH-09 đã nạp
    Khi bản tin tới chặng `respond` hoặc bất kỳ chặng gửi đích nào
    Thì phản hồi hoặc bản tin gửi đích đã che
    Và log và vết không bao giờ chứa giá trị trường phân loại Hạn chế hoặc Nhạy cảm (DD-08)

  @US-04-068 @FR-04-068 @M
  Kịch bản: US-04-068 dương · Định tuyến theo nội dung, tách, gộp, gọi song song, gửi đích
    Biết HTTT đích đã kết nạp và đang hoạt động ở PH-01 (kiểm ở VR, ERR-04-043); kết nối PH-05 bật ở môi trường
    Khi bản tin tới chặng `route` và `deliver`
    Thì phản hồi của hệ đích, hoặc kết quả gộp
    Và trạng thái gộp lưu bền vững tới khi hoàn tất

  @US-04-068 @FR-04-068 @M @âm
  Kịch bản: US-04-068 âm 1 · Theo FR-04-070
    Biết HTTT đích đã kết nạp và đang hoạt động ở PH-01 (kiểm ở VR, ERR-04-043); kết nối PH-05 bật ở môi trường
    Khi theo FR-04-070
    Thì hệ thống từ chối với ERR-04-103, ERR-04-104, ERR-04-105 (504)
    Và người dùng thấy thông báo "Hệ thống cung cấp dữ liệu không phản hồi kịp. Thử lại sau."

  @US-04-069 @FR-04-069 @M
  Kịch bản: US-04-069 dương · Phát sự kiện ra Kafka
    Biết topic đã đăng ký ở PH-10, luồng có quyền publish (VR-10)
    Khi bản tin tới bước gửi Kafka ở chặng `deliver`
    Thì bản tin trên topic `{tenant}.…v1`
    Và bản tin bền vững trên Kafka
    Và sự kiện được phát: Sự kiện nghiệp vụ của luồng trên topic đã đăng ký
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-069 @FR-04-069 @M @âm
  Kịch bản: US-04-069 âm 1 · Kafka không xác nhận
    Biết topic đã đăng ký ở PH-10, luồng có quyền publish (VR-10)
    Khi Kafka không xác nhận
    Thì hệ thống từ chối với ERR-04-104 (502)

  @US-04-070 @FR-04-070 @M
  Kịch bản: US-04-070 dương · Xử lý lỗi chuẩn: phân loại, thử lại, ngắt mạch, DLQ, dự phòng
    Biết luồng tham chiếu `dh-default-config` hoặc có `errorHandler` có DLQ tới PH-18 (VR-11)
    Khi một chặng ném ngoại lệ hoặc hệ đích trả mã lỗi
    Thì phản hồi lỗi RFC 9457 (đồng bộ) hoặc bản tin trên DLQ (bất đồng bộ)
    Và chỉ số `dh_flow_failures_total`, `dh_flow_dlq_total`, `dh_flow_circuit_state` được cập nhật
    Và sự kiện được phát: Bản tin DLQ trên `{tenant}.ops.dlq.v1`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-070 @FR-04-070 @M @âm
  Kịch bản: US-04-070 âm 1 · Mạch ngắt đang mở, không có nhánh dự phòng
    Biết luồng tham chiếu `dh-default-config` hoặc có `errorHandler` có DLQ tới PH-18 (VR-11)
    Khi mạch ngắt đang mở, không có nhánh dự phòng
    Thì hệ thống từ chối với ERR-04-105 (503)
    Và người dùng thấy thông báo "Hệ thống cung cấp dữ liệu đang tạm gián đoạn. Thử lại sau."

  @US-04-070 @FR-04-070 @M @âm
  Kịch bản: US-04-070 âm 2 · Hệ đích quá thời gian
    Biết luồng tham chiếu `dh-default-config` hoặc có `errorHandler` có DLQ tới PH-18 (VR-11)
    Khi hệ đích quá thời gian
    Thì hệ thống từ chối với ERR-04-103 (504)
    Và người dùng thấy thông báo "Hệ thống cung cấp dữ liệu không phản hồi kịp. Thử lại sau."

  @US-04-071 @FR-04-071 @M
  Kịch bản: US-04-071 dương · Chống trùng bản tin
    Biết luồng bất đồng bộ, hoặc luồng đồng bộ có khai báo khóa chống trùng (tiêu đề `Idempotency-Key` hoặc biểu thức trên thân)
    Khi chặng `receive` có tham số `idempotencyKey`
    Thì kết quả xử lý, kết quả đã lưu, hoặc lỗi 409
    Và khóa nằm trong Valkey tới hết TTL

  @US-04-071 @FR-04-071 @M @âm
  Kịch bản: US-04-071 âm 1 · Trùng khóa khi kết quả cũ không còn (hoặc vượt 64 KiB)
    Biết luồng bất đồng bộ, hoặc luồng đồng bộ có khai báo khóa chống trùng (tiêu đề `Idempotency-Key` hoặc biểu thức trên thân)
    Khi trùng khóa khi kết quả cũ không còn (hoặc vượt 64 KiB)
    Thì hệ thống từ chối với ERR-04-106 (409)
    Và người dùng thấy thông báo "Yêu cầu này đã được xử lý trước đó."

  @US-04-072 @FR-04-072 @M
  Kịch bản: US-04-072 dương · Truy cập CSDL trực tiếp có kiểm soát (Q359)
    Biết kết nối CSDL khai báo ở PH-05 với loại "CSDL cho luồng" (điều kiện 1 dưới đây); câu lệnh đã qua VR-13
    Khi Kamelet `dh-sql-ro-source` (nguồn định kỳ) chạy theo lịch, hoặc `dh-sql-ro-action` (tra cứu trong luồng) nhận bản tin
    Thì tập dòng đọc được (≤ `04.sql.max-rows`)
    Và tài khoản động hết hạn theo TTL; bản ghi kiểm toán ở cả CSDL và runtime
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-072 @FR-04-072 @M @âm
  Kịch bản: US-04-072 âm 1 · Câu lệnh vi phạm chính sách (kiểm tra hợp lệ lúc thiết kế, gửi duyệt)
    Biết kết nối CSDL khai báo ở PH-05 với loại "CSDL cho luồng" (điều kiện 1 dưới đây); câu lệnh đã qua VR-13
    Khi câu lệnh vi phạm chính sách (kiểm tra hợp lệ lúc thiết kế, gửi duyệt)
    Thì hệ thống từ chối với ERR-04-031 (422)
    Và người dùng thấy thông báo "Câu lệnh SQL ở chặng"

  @US-04-072 @FR-04-072 @M @âm
  Kịch bản: US-04-072 âm 2 · Kết nối không phải loại chỉ đọc cho luồng (kiểm tra hợp lệ)
    Biết kết nối CSDL khai báo ở PH-05 với loại "CSDL cho luồng" (điều kiện 1 dưới đây); câu lệnh đã qua VR-13
    Khi kết nối không phải loại chỉ đọc cho luồng (kiểm tra hợp lệ)
    Thì hệ thống từ chối với ERR-04-013 (422)
    Và người dùng thấy thông báo "Kết nối"

  @US-04-073 @FR-04-073 @M
  Kịch bản: US-04-073 dương · Ngữ cảnh tenant trên mỗi bản tin
    Biết luồng nạp bởi `FlowLoader` với nhãn `dh.gov.vn/tenant` trên ConfigMap
    Khi mỗi exchange đi vào luồng
    Thì exchange mang tenant bất biến
    Và sự kiện được phát: Cảnh báo an ninh tới PH-13 khi lệch
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-073 @FR-04-073 @M @âm
  Kịch bản: US-04-073 âm 1 · Bản tin lệch tenant
    Biết luồng nạp bởi `FlowLoader` với nhãn `dh.gov.vn/tenant` trên ConfigMap
    Khi bản tin lệch tenant
    Thì hệ thống từ chối với ERR-04-112 (500)
    Và người dùng thấy thông báo "Lỗi nội bộ khi xử lý yêu cầu. Mã truy vết {traceId}."

  @US-04-074 @FR-04-074 @M
  Kịch bản: US-04-074 dương · Vết, chỉ số, log và nhật ký kết nối
    Biết OpenTelemetry và Micrometer được cấu hình trong hồ sơ runtime
    Khi mỗi exchange; chặng `audit`
    Thì vết, chỉ số, log, nhật ký kết nối
    Và sự kiện được phát: EVT-04-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-075 @FR-04-075 @M
  Kịch bản: US-04-075 dương · Hồ sơ runtime, biên dịch native và chế độ JVM
    Biết hồ sơ có `runtime-manifest.json` (FR-04-081) trong ConfigMap `dh-runtime-manifests`
    Khi CI nền tảng dựng ảnh; FR-04-042 chọn hồ sơ khi phát hành
    Thì hồ sơ được gán ghi trong `flow.dh.yaml`
    Và nhật ký kiểm toán ghi nhận thao tác

  # ---- EP-04-G · Danh mục thành phần, di trú, kiểm toán, tham số

  @US-04-080 @FR-04-080 @M
  Kịch bản: US-04-080 dương · Danh mục thành phần và chính sách thành phần được phép
    Biết catalog của phiên bản runtime hiện hành đã phát hành (FR-04-081)
    Khi người dùng mở UI-04-17; PA, TA sửa chính sách; IE gửi "Đề xuất thành phần mới"
    Thì danh mục duyệt được theo loại, nhãn; chi tiết thành phần: mô tả gốc, cú pháp URI, bảng thuộc tính theo nhóm, mức hỗ trợ, `deprecated`, mức native (`SUPPORTED`, `JVM_ONLY`, `NOT_APPLICABLE`), phụ thuộc (tọa độ Maven với component …
    Và chính sách EN-04-11 cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-080 @FR-04-080 @M @âm
  Kịch bản: US-04-080 âm 1 · Thành phần không có trong catalog của phiên bản yêu cầu
    Biết catalog của phiên bản runtime hiện hành đã phát hành (FR-04-081)
    Khi thành phần không có trong catalog của phiên bản yêu cầu
    Thì hệ thống từ chối với ERR-04-035 (404)
    Và người dùng thấy thông báo "Thành phần"

  @US-04-080 @FR-04-080 @M @âm
  Kịch bản: US-04-080 âm 2 · TA mở rộng quá chính sách nền tảng
    Biết catalog của phiên bản runtime hiện hành đã phát hành (FR-04-081)
    Khi TA mở rộng quá chính sách nền tảng
    Thì hệ thống từ chối với ERR-04-045 (403)
    Và người dùng thấy thông báo "Bạn chưa có quyền mở rộng chính sách thành phần của nền tảng."

  @US-04-081 @FR-04-081 @M
  Kịch bản: US-04-081 dương · Khớp phiên bản catalog với runtime
    Biết mỗi hồ sơ runtime có `runtime-manifest.json`
    Khi CI của `dh-console`, `dh-integration` chạy; nền tảng nâng runtime
    Thì catalog khớp runtime; danh sách luồng cần kiểm tra lại
    Và `catalogVersion` hiện hành của tenant cập nhật; luồng ảnh hưởng được đánh dấu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-081 @FR-04-081 @M @âm
  Kịch bản: US-04-081 âm 1 · Lệch phiên bản ở CI
    Biết mỗi hồ sơ runtime có `runtime-manifest.json`
    Khi lệch phiên bản ở CI
    Thì hệ thống từ chối với ERR-04-042 (409)
    Và người dùng thấy thông báo "Luồng được soạn trên danh mục thành phần {old}, cũ hơn danh mục hiện hành {new}. Mở lại luồng để kiểm tra lại."

  @US-04-082 @FR-04-082 @M
  Kịch bản: US-04-082 dương · Chuyển luồng Camel XML của Bus cũ sang YAML
    Biết có tệp XML hoặc gói xuất của hệ cũ; không gian làm việc đích tồn tại
    Khi IE tải tệp lên UI-04-18 và bấm "Chuyển đổi"
    Thì hệ thống trả `202` với `jobId`; báo cáo chuyển đổi và luồng nháp mới (`origin = LEGACY_XML`)
    Và lượt chuyển (EN-04-23) lưu báo cáo; luồng nháp `DRAFT` nếu được tạo
    Và sự kiện được phát: EVT-04-01 khi tạo luồng nháp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-082 @FR-04-082 @M @âm
  Kịch bản: US-04-082 âm 1 · Tệp không phải Camel XML hoặc vượt kích thước
    Biết có tệp XML hoặc gói xuất của hệ cũ; không gian làm việc đích tồn tại
    Khi tệp không phải Camel XML hoặc vượt kích thước
    Thì hệ thống từ chối với ERR-04-032 (422)
    Và người dùng thấy thông báo "Tệp không phải Camel XML hợp lệ của hệ cũ hoặc vượt 2 MiB."

  @US-04-082 @FR-04-082 @M @âm
  Kịch bản: US-04-082 âm 2 · Không tìm thấy tác vụ chuyển đổi
    Biết có tệp XML hoặc gói xuất của hệ cũ; không gian làm việc đích tồn tại
    Khi không tìm thấy tác vụ chuyển đổi
    Thì hệ thống từ chối với ERR-04-030 (404)

  @US-04-083 @FR-04-083 @M
  Kịch bản: US-04-083 dương · Lịch sử thao tác và kiểm toán của luồng
    Biết luồng tồn tại; PH-13 sẵn sàng
    Khi người dùng mở tab Lịch sử của UI-04-02
    Thì hệ thống trả `200`; danh sách bản ghi kiểm toán đã lọc

  @US-04-083 @FR-04-083 @M @âm
  Kịch bản: US-04-083 âm 1 · PH-13 không sẵn sàng
    Biết luồng tồn tại; PH-13 sẵn sàng
    Khi PH-13 không sẵn sàng
    Thì hệ thống từ chối với ERR-04-047 (503)
    Và người dùng thấy thông báo "Chưa lấy được lịch sử từ hệ thống giám sát. Thử lại sau."

  @US-04-084 @FR-04-084 @S
  Kịch bản: US-04-084 dương · Tham số PH-04 theo tenant và đóng băng thay đổi
    Biết tenant hoạt động
    Khi TA mở UI-04-20 (màn tham số chung của PH-18) và sửa tham số, biến môi trường hoặc khoảng đóng băng
    Thì hệ thống trả `200`; tham số, biến môi trường, khoảng đóng băng hiện hành
    Và tham số mới có hiệu lực
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-04-084 @FR-04-084 @S @âm
  Kịch bản: US-04-084 âm 1 · Giá trị ngoài miền
    Biết tenant hoạt động
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-04-049 (400)
    Và người dùng thấy thông báo "Giá trị của {tham số} phải trong khoảng {min}…{max}."
