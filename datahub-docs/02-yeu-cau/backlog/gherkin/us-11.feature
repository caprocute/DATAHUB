# language: vi
# Sinh tự động từ D02-02/D02-03-PH11 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-11
Tính năng: PH-11 · Quy trình liên thông

  # ---- EP-11-A · Mô hình quy trình

  @US-11-001 @FR-11-001 @M
  Kịch bản: US-11-001 dương · Liệt kê, tìm kiếm mô hình quy trình
    Biết người dùng đã đăng nhập, chọn tenant (FR-00-004)
    Khi mở menu "Quy trình › Mô hình quy trình" (`/quy-trinh/mo-hinh`)
    Thì hệ thống trả `200`; `items[]` (`processKey`, `name`, `group`, `latestVersion`, `latestStatus`, `publishedVersion`, `runningInstances`, `updatedAt`), `page`, `size`, `totalElements`, `facets`

  @US-11-001 @FR-11-001 @M @âm
  Kịch bản: US-11-001 âm 1 · Tham số sai
    Biết người dùng đã đăng nhập, chọn tenant (FR-00-004)
    Khi tham số sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Điều kiện lọc không hợp lệ: {trường}. Kiểm tra lại giá trị."

  @US-11-002 @FR-11-002 @M
  Kịch bản: US-11-002 dương · Tạo mô hình quy trình
    Biết mã `processKey` chưa dùng trong tenant; với "từ mẫu", mẫu ở `PUBLISHED`
    Khi bấm "+ Tạo mô hình" ở UI-11-01
    Thì hệ thống trả `201`; `processKey`, `version` = 1, `status` = `DRAFT`, `validation` (tóm tắt kiểm tra tĩnh); `Location`, `ETag`
    Và một mô hình, một phiên bản `DRAFT`; khóa soạn thảo thuộc người tạo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-002 @FR-11-002 @M @âm
  Kịch bản: US-11-002 âm 1 · Mã đã dùng
    Biết mã `processKey` chưa dùng trong tenant; với "từ mẫu", mẫu ở `PUBLISHED`
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-11-002 (409)
    Và người dùng thấy thông báo "Mã quy trình {processKey} đã được dùng. Chọn mã khác."

  @US-11-002 @FR-11-002 @M @âm
  Kịch bản: US-11-002 âm 2 · Mã sai mẫu
    Biết mã `processKey` chưa dùng trong tenant; với "từ mẫu", mẫu ở `PUBLISHED`
    Khi mã sai mẫu
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Mã quy trình chỉ gồm chữ in hoa, số và dấu gạch dưới, 3 đến 64 ký tự."

  @US-11-003 @FR-11-003 @M
  Kịch bản: US-11-003 dương · Thiết kế sơ đồ BPMN 2.0 trên trình thiết kế
    Biết phiên bản `DRAFT`; người dùng giữ khóa soạn thảo hoặc khóa đang trống
    Khi mở UI-11-04 từ UI-11-01 hoặc UI-11-03
    Thì hệ thống trả `200`; `version`, `checksum`, `ETag` mới, `validation` (danh sách lỗi theo `elementId`)
    Và phiên bản vẫn `DRAFT`; `updatedBy`, `checksum` đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-003 @FR-11-003 @M @âm
  Kịch bản: US-11-003 âm 1 · Người khác giữ khóa
    Biết phiên bản `DRAFT`; người dùng giữ khóa soạn thảo hoặc khóa đang trống
    Khi người khác giữ khóa
    Thì hệ thống từ chối với ERR-11-016 (409)
    Và người dùng thấy thông báo "{người} đang sửa bản nháp này từ {giờ}. Bạn đang ở chế độ chỉ xem."

  @US-11-003 @FR-11-003 @M @âm
  Kịch bản: US-11-003 âm 2 · Xung đột phiên bản
    Biết phiên bản `DRAFT`; người dùng giữ khóa soạn thảo hoặc khóa đang trống
    Khi xung đột phiên bản
    Thì hệ thống từ chối với ERR-11-004 (409)
    Và người dùng thấy thông báo "Bản nháp đã được lưu ở nơi khác. Tải lại để xem bản mới, phần chưa lưu được giữ trong bộ nhớ tạm."

  @US-11-004 @FR-11-004 @M
  Kịch bản: US-11-004 dương · Cấu hình thuộc tính bước
    Biết phiên bản `DRAFT`, người dùng giữ khóa soạn thảo
    Khi chọn một phần tử trên khung vẽ; bảng thuộc tính bên phải mở theo loại phần tử
    Thì hệ thống trả `200`; phần tử đã cập nhật, `ETag`, `validation` của phần tử
    Và XML nháp có thuộc tính mới; phiên bản vẫn `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-004 @FR-11-004 @M @âm
  Kịch bản: US-11-004 âm 1 · Ý định không tồn tại hoặc `DEPRECATED`
    Biết phiên bản `DRAFT`, người dùng giữ khóa soạn thảo
    Khi ý định không tồn tại hoặc `DEPRECATED`
    Thì hệ thống từ chối với ERR-11-011 (422)
    Và người dùng thấy thông báo "Ý định {intentCode} không tồn tại hoặc đã ngừng dùng. Chọn ý định khác ở danh mục."

  @US-11-004 @FR-11-004 @M @âm
  Kịch bản: US-11-004 âm 2 · Biểu mẫu không có
    Biết phiên bản `DRAFT`, người dùng giữ khóa soạn thảo
    Khi biểu mẫu không có
    Thì hệ thống từ chối với ERR-11-014 (422)
    Và người dùng thấy thông báo "Biểu mẫu {formKey} chưa được phát hành."

  @US-11-005 @FR-11-005 @M
  Kịch bản: US-11-005 dương · Kiểm tra tĩnh mô hình
    Biết phiên bản tồn tại
    Khi lưu nháp (nhanh, chỉ phần tử đổi), bấm "Kiểm tra" (đầy đủ), gửi duyệt, triển khai (đầy đủ, bắt buộc)
    Thì hệ thống trả `200`; `blocking`, `errors[]` {`ruleCode`, `severity`, `elementId`, `message`}, `checkedAt`
    Và `process_version.validationSummary` cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-005 @FR-11-005 @M @âm
  Kịch bản: US-11-005 âm 1 · Danh mục luồng PH-04 không trả lời trong 5 s
    Biết phiên bản tồn tại
    Khi danh mục luồng PH-04 không trả lời trong 5 s
    Thì hệ thống từ chối với ERR-11-012 (422)
    Và người dùng thấy thông báo "Chưa kiểm được ánh xạ luồng"

  @US-11-006 @FR-11-006 @M
  Kịch bản: US-11-006 dương · Quản lý phiên bản nháp, so sánh hai phiên bản
    Biết mô hình tồn tại; tạo nháp khi mô hình chưa có bản `DRAFT` hoặc `IN_REVIEW` khác
    Khi thẻ "Phiên bản" ở UI-11-03: "Tạo bản nháp từ phiên bản này", "So sánh"
    Thì hệ thống trả `201` khi tạo nháp (`version`, `ETag`); `200` khi so sánh: `added[]`, `removed[]`, `changed[]` {`elementId`, `fields[]` {`path`, `before`, `after`}}, `variables`, `compensations`, `xmlLeft`, `xmlRight`
    Và có thêm một phiên bản `DRAFT` (khi tạo); so sánh không đổi dữ liệu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-006 @FR-11-006 @M @âm
  Kịch bản: US-11-006 âm 1 · Đã có nháp
    Biết mô hình tồn tại; tạo nháp khi mô hình chưa có bản `DRAFT` hoặc `IN_REVIEW` khác
    Khi đã có nháp
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Mô hình đang có bản nháp v{n} của {người}. Mở bản đó hoặc xóa trước khi tạo bản mới."

  @US-11-006 @FR-11-006 @M @âm
  Kịch bản: US-11-006 âm 2 · Phiên bản không có
    Biết mô hình tồn tại; tạo nháp khi mô hình chưa có bản `DRAFT` hoặc `IN_REVIEW` khác
    Khi phiên bản không có
    Thì hệ thống từ chối với ERR-11-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản v{n} của {processKey}."

  @US-11-007 @FR-11-007 @M
  Kịch bản: US-11-007 dương · Gửi duyệt phát hành mô hình
    Biết phiên bản `DRAFT`; người gửi giữ khóa soạn thảo hoặc khóa trống
    Khi bấm "Gửi duyệt" ở UI-11-04 hoặc UI-11-03
    Thì hệ thống trả `202`; `publishRequestId`, `status` = `PENDING`, `taskId` việc duyệt
    Và phiên bản `IN_REVIEW`; có `publish_request` `PENDING`
    Và sự kiện được phát: EVT-11-08 (việc duyệt)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-007 @FR-11-007 @M @âm
  Kịch bản: US-11-007 âm 1 · Còn lỗi kiểm tra
    Biết phiên bản `DRAFT`; người gửi giữ khóa soạn thảo hoặc khóa trống
    Khi còn lỗi kiểm tra
    Thì hệ thống từ chối với ERR-11-010 (422)
    Và người dùng thấy thông báo "Mô hình còn {n} lỗi phải sửa trước khi gửi duyệt. Xem ngăn Kết quả kiểm tra."

  @US-11-007 @FR-11-007 @M @âm
  Kịch bản: US-11-007 âm 2 · Thiếu ghi chú
    Biết phiên bản `DRAFT`; người gửi giữ khóa soạn thảo hoặc khóa trống
    Khi thiếu ghi chú
    Thì hệ thống từ chối với ERR-11-007 (422)
    Và người dùng thấy thông báo "Nhập ghi chú thay đổi (tối thiểu 10 ký tự) để người duyệt biết bản này khác gì."

  @US-11-008 @FR-11-008 @M
  Kịch bản: US-11-008 dương · Duyệt hoặc từ chối phát hành, triển khai lên engine
    Biết `publish_request` `PENDING`, phiên bản `IN_REVIEW`
    Khi mở việc duyệt từ hộp "Việc của tôi" (UI-11-07)
    Thì hệ thống trả `200`; `publishRequestId`, `status`, `version`, `deploymentId`, `publishedAt`
    Và đúng một phiên bản `PUBLISHED` cho mỗi mô hình; định nghĩa trong engine thuộc đúng `tenantId`
    Và sự kiện được phát: EVT-11-01 khi duyệt; EVT-11-10 (việc duyệt hoàn thành)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-008 @FR-11-008 @M @âm
  Kịch bản: US-11-008 âm 1 · Tự duyệt
    Biết `publish_request` `PENDING`, phiên bản `IN_REVIEW`
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-11-005 (403)
    Và người dùng thấy thông báo "Anh/chị đã gửi hoặc sửa bản này nên không được tự duyệt."

  @US-11-008 @FR-11-008 @M @âm
  Kịch bản: US-11-008 âm 2 · Thiếu ý kiến
    Biết `publish_request` `PENDING`, phiên bản `IN_REVIEW`
    Khi thiếu ý kiến
    Thì hệ thống từ chối với ERR-11-007 (422)
    Và người dùng thấy thông báo "Nhập ý kiến duyệt; khi từ chối, nêu lý do tối thiểu 20 ký tự."

  @US-11-009 @FR-11-009 @M
  Kịch bản: US-11-009 dương · Ngừng dùng, thu hồi phiên bản
    Biết phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi thẻ "Phiên bản" ở UI-11-03: "Ngừng dùng", "Thu hồi", "Khôi phục"
    Thì hệ thống trả `200`; `version`, `status`, `runningInstances`; `RESTORE` trả `202` kèm `publishRequestId`
    Và phiên bản `DEPRECATED` hoặc `RETIRED`
    Và sự kiện được phát: EVT-11-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-009 @FR-11-009 @M @âm
  Kịch bản: US-11-009 âm 1 · Còn phiên chạy
    Biết phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi còn phiên chạy
    Thì hệ thống từ chối với ERR-11-037 (409)
    Và người dùng thấy thông báo "Phiên bản còn {n} hồ sơ đang xử lý. Chờ kết thúc hoặc di trú sang phiên bản mới (UI-11-14)."

  @US-11-009 @FR-11-009 @M @âm
  Kịch bản: US-11-009 âm 2 · Ngừng bản duy nhất
    Biết phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi ngừng bản duy nhất
    Thì hệ thống từ chối với ERR-11-038 (422)
    Và người dùng thấy thông báo "Đây là phiên bản duy nhất đang phát hành; sau khi ngừng, kênh DVC không tạo được hồ sơ mới. Xác nhận để tiếp tục."

  @US-11-010 @FR-11-010 @M
  Kịch bản: US-11-010 dương · Nhập, xuất tệp BPMN 2.0 XML và gói quy trình
    Biết nhập vào mô hình mới hoặc tạo nháp cho mô hình có sẵn chưa có nháp
    Khi UI-11-02 "Nhập tệp"; UI-11-03 "Xuất" (BPMN XML, SVG, gói `.zip`)
    Thì hệ thống trả `201` khi nhập (`processKey`, `version`, `report` {`removed[]`, `warnings[]`, `missingIntents[]`}); `200` tệp khi xuất (`Content-Disposition`)
    Và có phiên bản `DRAFT` mới khi nhập
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-010 @FR-11-010 @M @âm
  Kịch bản: US-11-010 âm 1 · XML sai chuẩn
    Biết nhập vào mô hình mới hoặc tạo nháp cho mô hình có sẵn chưa có nháp
    Khi XML sai chuẩn
    Thì hệ thống từ chối với ERR-11-008 (400)
    Và người dùng thấy thông báo "Tệp không đúng BPMN 2.0 tại dòng {dòng}: {mô tả}."

  @US-11-010 @FR-11-010 @M @âm
  Kịch bản: US-11-010 âm 2 · Tệp quá lớn
    Biết nhập vào mô hình mới hoặc tạo nháp cho mô hình có sẵn chưa có nháp
    Khi tệp quá lớn
    Thì hệ thống từ chối với ERR-11-009 (413)
    Và người dùng thấy thông báo "Tệp vượt {n} KB."

  @US-11-011 @FR-11-011 @S
  Kịch bản: US-11-011 dương · Chạy thử mô hình với service task giả lập
    Biết phiên bản `DRAFT` hoặc `IN_REVIEW` không còn lỗi `ERROR`
    Khi bấm "Chạy thử" ở UI-11-04, mở UI-11-06
    Thì hệ thống trả `201`; `testRunId`, `status`; API-11-026 trả `timeline[]`, `variables`, `tasks[]`, `saga`
    Và `test_run` kết thúc; định nghĩa và phiên thử dọn sau `11.test.retentionDays`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-011 @FR-11-011 @S @âm
  Kịch bản: US-11-011 âm 1 · Thiếu kịch bản cho service task
    Biết phiên bản `DRAFT` hoặc `IN_REVIEW` không còn lỗi `ERROR`
    Khi thiếu kịch bản cho service task
    Thì hệ thống từ chối với ERR-11-042 (422)
    Và người dùng thấy thông báo "Chưa có kết quả giả lập cho bước {tên}. Nhập kết quả hoặc chọn mặc định Hoàn thành."

  # ---- EP-11-B · Tài nguyên quy trình

  @US-11-012 @FR-11-012 @M
  Kịch bản: US-11-012 dương · Quản lý biểu mẫu việc người dùng
    Biết mã `formKey` chưa dùng khi tạo; sửa chỉ trên phiên bản `DRAFT`
    Khi UI-11-08: "+ Biểu mẫu", chọn biểu mẫu để sửa, "Xem trước", "Phát hành"
    Thì hệ thống trả `201` hoặc `200`; `formKey`, `version`, `status`, `ETag`
    Và phiên bản biểu mẫu `DRAFT` hoặc `PUBLISHED`; mô hình gắn `formKey` dùng phiên bản `PUBLISHED` mới nhất tại thời điểm phát hành mô hình (ghi cố định trong phiên bản mô hình)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-012 @FR-11-012 @M @âm
  Kịch bản: US-11-012 âm 1 · Schema sai
    Biết mã `formKey` chưa dùng khi tạo; sửa chỉ trên phiên bản `DRAFT`
    Khi schema sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Biểu mẫu không hợp lệ tại {đường dẫn}: {mô tả}."

  @US-11-012 @FR-11-012 @M @âm
  Kịch bản: US-11-012 âm 2 · Trùng mã
    Biết mã `formKey` chưa dùng khi tạo; sửa chỉ trên phiên bản `DRAFT`
    Khi trùng mã
    Thì hệ thống từ chối với ERR-11-002 (409)
    Và người dùng thấy thông báo "Mã biểu mẫu {formKey} đã có."

  @US-11-013 @FR-11-013 @M
  Kịch bản: US-11-013 dương · Đăng ký ý định nghiệp vụ và ánh xạ sang luồng PH-04
    Biết luồng PH-04 đích tồn tại ở danh mục luồng của tenant
    Khi UI-11-09 thẻ "Ý định": "+ Ý định", sửa, "Ngừng dùng"
    Thì hệ thống trả `201`; `intentCode`, `status`, `bindings[]`
    Và `service_intent` có ánh xạ theo môi trường
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-013 @FR-11-013 @M @âm
  Kịch bản: US-11-013 âm 1 · Luồng chưa phát hành ở môi trường chính thức
    Biết luồng PH-04 đích tồn tại ở danh mục luồng của tenant
    Khi luồng chưa phát hành ở môi trường chính thức
    Thì hệ thống từ chối với ERR-11-012 (422)
    Và người dùng thấy thông báo "Luồng {flowCode} chưa được phát hành ở môi trường {env}. Phát hành luồng ở PH-04 trước."

  @US-11-013 @FR-11-013 @M @âm
  Kịch bản: US-11-013 âm 2 · Hợp đồng không khớp
    Biết luồng PH-04 đích tồn tại ở danh mục luồng của tenant
    Khi hợp đồng không khớp
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Trường {tên} của ý định không có ở đầu vào luồng {flowCode}."

  @US-11-014 @FR-11-014 @M
  Kịch bản: US-11-014 dương · Đăng ký hành động bù trừ theo bước
    Biết phiên bản `DRAFT`; bước xuôi là service task có ý định
    Khi bảng thuộc tính bước ở UI-11-04 nhóm "Bù trừ", hoặc UI-11-09 thẻ "Bù trừ"
    Thì hệ thống trả `200`; danh sách `compensation_action` của phiên bản
    Và XML và `compensation_action` đồng bộ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-014 @FR-11-014 @M @âm
  Kịch bản: US-11-014 âm 1 · Bù trừ trỏ chính bước xuôi
    Biết phiên bản `DRAFT`; bước xuôi là service task có ý định
    Khi bù trừ trỏ chính bước xuôi
    Thì hệ thống từ chối với ERR-11-044 (422)
    Và người dùng thấy thông báo "Hành động bù trừ phải khác hành động của bước {tên}."

  @US-11-014 @FR-11-014 @M @âm
  Kịch bản: US-11-014 âm 2 · Thiếu ghi chú
    Biết phiên bản `DRAFT`; bước xuôi là service task có ý định
    Khi thiếu ghi chú
    Thì hệ thống từ chối với ERR-11-007 (422)
    Và người dùng thấy thông báo "Nhập ghi chú nghiệp vụ giải thích cách bù trừ (tối thiểu 20 ký tự)."

  @US-11-015 @FR-11-015 @S
  Kịch bản: US-11-015 dương · Quản lý mẫu quy trình dùng chung
    Biết có phiên bản mô hình nguồn không còn lỗi `ERROR`
    Khi UI-11-10: "+ Mẫu từ mô hình", "Phát hành mẫu"
    Thì hệ thống trả `201`; `templateCode`, `status`
    Và mẫu `DRAFT`, `PUBLISHED` hoặc `RETIRED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-015 @FR-11-015 @S @âm
  Kịch bản: US-11-015 âm 1 · Tỉnh sửa mẫu `COMMON`
    Biết có phiên bản mô hình nguồn không còn lỗi `ERROR`
    Khi tỉnh sửa mẫu `COMMON`
    Thì hệ thống từ chối với ERR-11-036 (403)
    Và người dùng thấy thông báo "Mẫu dùng chung chỉ quản trị nền tảng được sửa. Sao chép thành mô hình của tỉnh để chỉnh."

  @US-11-016 @FR-11-016 @M
  Kịch bản: US-11-016 dương · Khai báo biến quy trình và phân loại dữ liệu
    Biết phiên bản `DRAFT`
    Khi UI-11-04 thẻ "Biến"
    Thì hệ thống trả `200`; `variables[]`
    Và `variable_definition` đồng bộ với phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-016 @FR-11-016 @M @âm
  Kịch bản: US-11-016 âm 1 · Bỏ mã hóa biến `SENSITIVE`
    Biết phiên bản `DRAFT`
    Khi bỏ mã hóa biến `SENSITIVE`
    Thì hệ thống từ chối với ERR-11-015 (422)
    Và người dùng thấy thông báo "Biến {tên} chứa dữ liệu nhạy cảm nên bắt buộc mã hóa."

  @US-11-016 @FR-11-016 @M @âm
  Kịch bản: US-11-016 âm 2 · Trùng tên biến hệ thống
    Biết phiên bản `DRAFT`
    Khi trùng tên biến hệ thống
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Tên {tên} là biến hệ thống, chọn tên khác."

  @US-11-017 @FR-11-017 @C
  Kịch bản: US-11-017 dương · Bảng quyết định DMN đơn giản cho rẽ nhánh
    Biết biến đầu vào của bảng đã khai báo
    Khi UI-11-04: chọn `BUSINESS_RULE_TASK`, "Mở bảng quyết định"
    Thì hệ thống trả `200`; bảng và kết quả thử
    Và `decision_table` có phiên bản; triển khai cùng phiên bản mô hình
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-017 @FR-11-017 @C @âm
  Kịch bản: US-11-017 âm 1 · Quy tắc chồng lấn
    Biết biến đầu vào của bảng đã khai báo
    Khi quy tắc chồng lấn
    Thì hệ thống từ chối với ERR-11-040 (422)
    Và người dùng thấy thông báo "Dòng {a} và {b} cùng khớp một trường hợp trong khi chính sách là UNIQUE."

  # ---- EP-11-C · Phiên quy trình

  @US-11-018 @FR-11-018 @M
  Kịch bản: US-11-018 dương · Khởi tạo phiên qua API
    Biết mô hình có phiên bản `PUBLISHED`; CSDL sẵn sàng
    Khi `POST /instances` từ hệ thống gọi
    Thì hệ thống trả `201` (hoặc `200` khi trùng); `instanceId`, `processKey`, `version`, `businessKey`, `status` = `RUNNING`, `dueAt`, `progressUrl`; `Location`
    Và phiên `RUNNING`, bước đầu đã lên lịch job; không có phiên nửa vời khi lỗi
    Và sự kiện được phát: EVT-11-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-018 @FR-11-018 @M @âm
  Kịch bản: US-11-018 âm 1 · Không có bản phát hành
    Biết mô hình có phiên bản `PUBLISHED`; CSDL sẵn sàng
    Khi không có bản phát hành
    Thì hệ thống từ chối với ERR-11-017 (422)
    Và người dùng thấy thông báo "Quy trình {processKey} chưa có phiên bản đang phát hành."

  @US-11-018 @FR-11-018 @M @âm
  Kịch bản: US-11-018 âm 2 · Biến sai
    Biết mô hình có phiên bản `PUBLISHED`; CSDL sẵn sàng
    Khi biến sai
    Thì hệ thống từ chối với ERR-11-019 (422)
    Và người dùng thấy thông báo "Thiếu hoặc sai kiểu biến: {danh sách}."

  @US-11-019 @FR-11-019 @S
  Kịch bản: US-11-019 dương · Khởi tạo phiên từ sự kiện PH-10
    Biết mô hình có `START_EVENT` loại thông điệp gắn topic PH-10 đã đăng ký và ánh xạ trường sự kiện → biến, `businessKey`
    Khi bản tin đến topic đã gắn
    Thì hồ sơ bắt đầu được điều phối ngay khi tiếp nhận
    Và phiên `RUNNING` hoặc bản tin trong DLQ
    Và sự kiện được phát: EVT-11-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-019 @FR-11-019 @S @âm
  Kịch bản: US-11-019 âm 1 · Bản tin không hợp lệ
    Biết mô hình có `START_EVENT` loại thông điệp gắn topic PH-10 đã đăng ký và ánh xạ trường sự kiện → biến, `businessKey`
    Khi bản tin không hợp lệ
    Thì hệ thống từ chối với ERR-11-120
    Và người dùng thấy thông báo "Sự kiện {id} từ {topic} không tạo được phiên: {mô tả}."

  @US-11-020 @FR-11-020 @S
  Kịch bản: US-11-020 dương · Khởi tạo phiên thủ công trên giao diện
    Biết mô hình có phiên bản `PUBLISHED`, cờ `allowManualStart`
    Khi UI-11-13 "Khởi tạo phiên"
    Thì hệ thống trả `201`; như FR-11-018
    Và phiên `RUNNING`
    Và sự kiện được phát: EVT-11-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-020 @FR-11-020 @S @âm
  Kịch bản: US-11-020 âm 1 · Mô hình không cho khởi tạo tay
    Biết mô hình có phiên bản `PUBLISHED`, cờ `allowManualStart`
    Khi mô hình không cho khởi tạo tay
    Thì hệ thống từ chối với ERR-11-020 (403)
    Và người dùng thấy thông báo "Quy trình {tên} chỉ khởi tạo từ hệ thống tiếp nhận."

  @US-11-021 @FR-11-021 @M
  Kịch bản: US-11-021 dương · Liệt kê, tìm kiếm phiên
    Biết đăng nhập, chọn tenant
    Khi mở `/quy-trinh/phien`, hoặc bấm thẻ chỉ số ở UI-11-19
    Thì hệ thống trả `200`; `items[]` (`instanceId`, `businessKey`, `processKey`, `version`, `status`, `waitState`, `currentElements[]`, `dueAt`, `dueStatus`, `startedAt`, `incidentCount`), `page`, `totalElements`

  @US-11-021 @FR-11-021 @M @âm
  Kịch bản: US-11-021 âm 1 · Tham số sai
    Biết đăng nhập, chọn tenant
    Khi tham số sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Điều kiện lọc không hợp lệ: {trường}."

  @US-11-022 @FR-11-022 @M
  Kịch bản: US-11-022 dương · Xem chi tiết phiên
    Biết phiên thuộc tenant và phạm vi
    Khi bấm một dòng ở UI-11-11, liên kết từ việc, sự cố, cảnh báo
    Thì hệ thống trả `200`; `instance`, `diagram` {`xml`, `elementStates[]`}, `timeline[]`, `variables[]`, `tasks[]`, `serviceCalls[]`, `saga`, `incidents[]`, `due`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-022 @FR-11-022 @M @âm
  Kịch bản: US-11-022 âm 1 · Ngoài phạm vi
    Biết phiên thuộc tenant và phạm vi
    Khi ngoài phạm vi
    Thì hệ thống từ chối với ERR-11-034 (403)
    Và người dùng thấy thông báo "Anh/chị không có quyền xem hồ sơ này."

  @US-11-022 @FR-11-022 @M @âm
  Kịch bản: US-11-022 âm 2 · Không có
    Biết phiên thuộc tenant và phạm vi
    Khi không có
    Thì hệ thống từ chối với ERR-11-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên {id}."

  @US-11-023 @FR-11-023 @M
  Kịch bản: US-11-023 dương · Tạm dừng, tiếp tục phiên
    Biết tạm dừng: `RUNNING`
    Khi UI-11-12 "Tạm dừng", "Tiếp tục"
    Thì hệ thống trả `200`; `status`, `suspendedAt` hoặc `resumedAt`
    Và `SUSPENDED` hoặc `RUNNING`
    Và sự kiện được phát: EVT-11-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-023 @FR-11-023 @M @âm
  Kịch bản: US-11-023 âm 1 · Sai trạng thái
    Biết tạm dừng: `RUNNING`
    Khi sai trạng thái
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Phiên đang ở trạng thái {trạng thái}, không thể {thao tác}."

  @US-11-023 @FR-11-023 @M @âm
  Kịch bản: US-11-023 âm 2 · Đang bù trừ
    Biết tạm dừng: `RUNNING`
    Khi đang bù trừ
    Thì hệ thống từ chối với ERR-11-030 (409)
    Và người dùng thấy thông báo "Phiên đang bù trừ, chờ Saga kết thúc."

  @US-11-024 @FR-11-024 @M
  Kịch bản: US-11-024 dương · Hủy phiên kèm bù trừ tùy chọn
    Biết phiên `RUNNING` hoặc `SUSPENDED`
    Khi UI-11-12 "Hủy phiên"; API từ HTTT một cửa khi công dân rút hồ sơ
    Thì hệ thống trả `202` khi chạy bù trừ (`AUTO` có bước cần bù; `sagaId`); `200` khi hủy ngay (`NONE` hoặc không có bước cần bù)
    Và `CANCELLED`, hoặc `COMPENSATING` rồi `COMPENSATED`/`FAILED`
    Và sự kiện được phát: EVT-11-06; EVT-11-13 khi bù trừ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-024 @FR-11-024 @M @âm
  Kịch bản: US-11-024 âm 1 · Phiên đã kết thúc
    Biết phiên `RUNNING` hoặc `SUSPENDED`
    Khi phiên đã kết thúc
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Phiên đã {trạng thái}, không hủy được."

  @US-11-024 @FR-11-024 @M @âm
  Kịch bản: US-11-024 âm 2 · Bỏ bù trừ không đủ quyền
    Biết phiên `RUNNING` hoặc `SUSPENDED`
    Khi bỏ bù trừ không đủ quyền
    Thì hệ thống từ chối với ERR-00-403 (403)
    Và người dùng thấy thông báo "Chỉ quản trị tỉnh được hủy mà không bù trừ."

  @US-11-025 @FR-11-025 @S
  Kịch bản: US-11-025 dương · Sửa biến phiên có kiểm soát
    Biết phiên `RUNNING` hoặc `SUSPENDED`; biến có `editableBy = ADMIN_CHANGE`
    Khi UI-11-12 thẻ Biến "Đề nghị sửa"
    Thì hệ thống trả `202` (`changeId`); `200` khi duyệt
    Và biến đổi; `instance_change` `APPLIED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-025 @FR-11-025 @S @âm
  Kịch bản: US-11-025 âm 1 · Biến không cho sửa
    Biết phiên `RUNNING` hoặc `SUSPENDED`; biến có `editableBy = ADMIN_CHANGE`
    Khi biến không cho sửa
    Thì hệ thống từ chối với ERR-11-033 (422)
    Và người dùng thấy thông báo "Biến {tên} không được sửa sau khi khởi tạo."

  @US-11-026 @FR-11-026 @S
  Kịch bản: US-11-026 dương · Di trú phiên sang phiên bản mô hình mới
    Biết phiên bản đích `PUBLISHED` cùng mô hình
    Khi UI-11-14 trình hướng dẫn bốn bước
    Thì hệ thống trả `202`; `planId`, `status`, `summary` {`total`, `migrated`, `failed`}
    Và `instance_index.version` cập nhật cho phiên thành công
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-026 @FR-11-026 @S @âm
  Kịch bản: US-11-026 âm 1 · Bước không ánh xạ
    Biết phiên bản đích `PUBLISHED` cùng mô hình
    Khi bước không ánh xạ
    Thì hệ thống từ chối với ERR-11-031 (422)
    Và người dùng thấy thông báo "Còn {n} bước đang có phiên mà chưa ánh xạ sang phiên bản mới: {danh sách}."

  @US-11-027 @FR-11-027 @S
  Kịch bản: US-11-027 dương · Chuyển phiên tới bước khác
    Biết phiên `RUNNING` hoặc `SUSPENDED`; không `COMPENSATING`
    Khi UI-11-12 chọn bước trên sơ đồ, "Đề nghị chuyển bước"
    Thì hệ thống trả `202`; `changeId`
    Và token ở bước đích; `instance_change` `APPLIED`
    Và sự kiện được phát: EVT-11-04 với `manual = true`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-027 @FR-11-027 @S @âm
  Kịch bản: US-11-027 âm 1 · Bước đích sai
    Biết phiên `RUNNING` hoặc `SUSPENDED`; không `COMPENSATING`
    Khi bước đích sai
    Thì hệ thống từ chối với ERR-11-032 (422)
    Và người dùng thấy thông báo "Không chuyển được tới bước {tên}: {lý do}."

  # ---- EP-11-D · Bước tự động

  @US-11-028 @FR-11-028 @M
  Kịch bản: US-11-028 dương · Gửi lệnh thực thi service task tới PH-04
    Biết phiên `RUNNING`; ý định `ACTIVE`, có ánh xạ luồng ở môi trường hiện hành
    Khi token đến `SERVICE_TASK` (`flowable:triggerable="true"`, `flowable:async="true"`)
    Thì PH-04 nhận đúng một lệnh nghiệp vụ; người xem phiên thấy bước "Đang chờ {publicName}"
    Và `service_call` `REQUESTED`; phiên `waitState = WAITING_SERVICE`
    Và sự kiện được phát: EVT-11-17

  @US-11-028 @FR-11-028 @M @âm
  Kịch bản: US-11-028 âm 1 · Không đẩy được Kafka
    Biết phiên `RUNNING`; ý định `ACTIVE`, có ánh xạ luồng ở môi trường hiện hành
    Khi không đẩy được Kafka
    Thì hệ thống từ chối với ERR-11-101
    Và người dùng thấy thông báo "Không gửi được lệnh {intentCode} của hồ sơ {businessKey} sau {n} lần."

  @US-11-028 @FR-11-028 @M @âm
  Kịch bản: US-11-028 âm 2 · Gửi lại lệnh đã đóng
    Biết phiên `RUNNING`; ý định `ACTIVE`, có ánh xạ luồng ở môi trường hiện hành
    Khi gửi lại lệnh đã đóng
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Lệnh {commandId} đã có kết quả, không gửi lại."

  @US-11-029 @FR-11-029 @M
  Kịch bản: US-11-029 dương · Nhận kết quả, lỗi service task và tương quan
    Biết `service_call` `REQUESTED`
    Khi bản tin trên `{tenant}.bpm.service.completed.v1` hoặc `.failed.v1`; hẹn giờ `timeoutAt`
    Thì phiên đi tiếp ngay khi cơ quan trả kết quả; lỗi được đưa về nhánh đúng
    Và `service_call` `COMPLETED`, `FAILED` hoặc `TIMED_OUT`
    Và sự kiện được phát: EVT-11-04; EVT-11-13 khi mở Saga; EVT-11-16 khi mở sự cố

  @US-11-029 @FR-11-029 @M @âm
  Kịch bản: US-11-029 âm 1 · Kết quả không tương quan
    Biết `service_call` `REQUESTED`
    Khi kết quả không tương quan
    Thì hệ thống từ chối với ERR-11-103
    Và người dùng thấy thông báo "Kết quả {commandId} không khớp lệnh nào đang chờ."

  @US-11-029 @FR-11-029 @M @âm
  Kịch bản: US-11-029 âm 2 · Quá hạn chờ
    Biết `service_call` `REQUESTED`
    Khi quá hạn chờ
    Thì hệ thống từ chối với ERR-11-102
    Và người dùng thấy thông báo "Bước {publicName} của hồ sơ {businessKey} chờ PH-04 quá {n} phút."

  @US-11-030 @FR-11-030 @M
  Kịch bản: US-11-030 dương · Chờ thông điệp, sự kiện
    Biết phiên có execution chờ `MESSAGE_EVENT` hoặc `MESSAGE_BOUNDARY` với `messageName`
    Khi `POST /messages`, hoặc bản tin trên topic gắn thông điệp
    Thì hệ thống trả `202`; `instanceId`, `delivered` (có, đệm)
    Và execution đi tiếp; `waitState` cập nhật
    Và sự kiện được phát: EVT-11-04

  @US-11-030 @FR-11-030 @M @âm
  Kịch bản: US-11-030 âm 1 · Không có phiên chờ
    Biết phiên có execution chờ `MESSAGE_EVENT` hoặc `MESSAGE_BOUNDARY` với `messageName`
    Khi không có phiên chờ
    Thì hệ thống từ chối với ERR-11-049 (404)
    Và người dùng thấy thông báo "Không có hồ sơ {businessKey} đang chờ thông điệp {messageName}."

  @US-11-030 @FR-11-030 @M @âm
  Kịch bản: US-11-030 âm 2 · Chờ quá hạn (hẹn giờ biên)
    Biết phiên có execution chờ `MESSAGE_EVENT` hoặc `MESSAGE_BOUNDARY` với `messageName`
    Khi chờ quá hạn (hẹn giờ biên)
    Thì hệ thống từ chối với ERR-11-109
    Và người dùng thấy thông báo "Hết thời gian chờ {messageName}."

  @US-11-031 @FR-11-031 @M
  Kịch bản: US-11-031 dương · Hẹn giờ khởi tạo, trung gian, biên
    Biết phần tử hẹn giờ có biểu thức ISO 8601 hợp lệ, ≥ `11.timer.minSeconds`
    Khi token đến hẹn giờ trung gian hoặc bước có hẹn giờ biên; định nghĩa có `START_EVENT` hẹn giờ được phát hành
    Thì quy trình tự đi tiếp hoặc tự nhắc đúng giờ hành chính
    Và job timer xóa sau khi chạy (trừ chu kỳ)
    Và sự kiện được phát: EVT-11-04 khi bước đi tiếp

  @US-11-031 @FR-11-031 @M @âm
  Kịch bản: US-11-031 âm 1 · Timer lỗi
    Biết phần tử hẹn giờ có biểu thức ISO 8601 hợp lệ, ≥ `11.timer.minSeconds`
    Khi timer lỗi
    Thì hệ thống từ chối với ERR-11-108
    Và người dùng thấy thông báo "Hẹn giờ {tên} của hồ sơ {businessKey} không chạy được: {mô tả}."

  @US-11-032 @FR-11-032 @S
  Kịch bản: US-11-032 dương · Gửi thông báo từ quy trình
    Biết `SEND_TASK` có `templateCode`, `audience`
    Khi token đến `SEND_TASK`
    Thì người liên quan được báo đúng lúc
    Và yêu cầu thông báo trong outbox
    Và sự kiện được phát: EVT-11-20

  @US-11-032 @FR-11-032 @S @âm
  Kịch bản: US-11-032 âm 1 · Kênh lỗi
    Biết `SEND_TASK` có `templateCode`, `audience`
    Khi kênh lỗi
    Thì hệ thống từ chối với ERR-11-123
    Và người dùng thấy thông báo "Thông báo {templateCode} của hồ sơ {businessKey} chưa gửi được."

  @US-11-033 @FR-11-033 @S
  Kịch bản: US-11-033 dương · Gọi quy trình con
    Biết mô hình được gọi có phiên bản `PUBLISHED` cùng tenant; không gọi vòng
    Khi token đến `CALL_ACTIVITY`
    Thì quy trình con dùng chung, sửa một chỗ
    Và phiên con kết thúc trước khi cha qua bước
    Và sự kiện được phát: EVT-11-03, EVT-11-05 của phiên con (có `parentInstanceId`)

  @US-11-033 @FR-11-033 @S @âm
  Kịch bản: US-11-033 âm 1 · Không có bản phát hành
    Biết mô hình được gọi có phiên bản `PUBLISHED` cùng tenant; không gọi vòng
    Khi không có bản phát hành
    Thì hệ thống từ chối với ERR-11-118
    Và người dùng thấy thông báo "Không gọi được quy trình con {calledProcessKey}: chưa có phiên bản phát hành."

  # ---- EP-11-E · Việc người dùng

  @US-11-034 @FR-11-034 @M
  Kịch bản: US-11-034 dương · Tạo việc và phân công
    Biết bước có `assignment` hợp lệ
    Khi token đến `USER_TASK`
    Thì cán bộ hoặc nhóm thấy việc mới trong hộp việc
    Và việc `UNASSIGNED` hoặc `ASSIGNED`; phiên `waitState = WAITING_USER`
    Và sự kiện được phát: EVT-11-08, EVT-11-09

  @US-11-034 @FR-11-034 @M @âm
  Kịch bản: US-11-034 âm 1 · Không có ứng viên
    Biết bước có `assignment` hợp lệ
    Khi không có ứng viên
    Thì hệ thống từ chối với ERR-11-113
    Và người dùng thấy thông báo "Việc {tên} của hồ sơ {businessKey} không có người nhận hợp lệ, đã chuyển nhóm {nhóm}."

  @US-11-035 @FR-11-035 @M
  Kịch bản: US-11-035 dương · Đăng ký việc vào hộp "Việc của tôi"
    Biết việc được tạo, đổi người nhận, hoàn thành hoặc hủy
    Khi EVT-11-08, 09, 10 trong nội bộ DU; hộp việc gọi API cung cấp việc
    Thì hệ thống trả `200` của API-11-125: `items[]` như đầu vào, không có giá trị biến
    Và mục hộp việc khớp `task_index`

  @US-11-035 @FR-11-035 @M @âm
  Kịch bản: US-11-035 âm 1 · Đăng ký thất bại
    Biết việc được tạo, đổi người nhận, hoàn thành hoặc hủy
    Khi đăng ký thất bại
    Thì hệ thống từ chối với ERR-11-114
    Và người dùng thấy thông báo "Việc {taskId} chưa vào hộp Việc của tôi, đang thử lại."

  @US-11-036 @FR-11-036 @M
  Kịch bản: US-11-036 dương · Nhận việc, trả lại việc
    Biết nhận: việc `UNASSIGNED`, người dùng là ứng viên
    Khi "Nhận việc" ở hộp việc hoặc UI-11-15; "Trả lại việc"
    Thì hệ thống trả `200`; `status`, `assignee`
    Và `ASSIGNED` hoặc `UNASSIGNED`
    Và sự kiện được phát: EVT-11-09

  @US-11-036 @FR-11-036 @M @âm
  Kịch bản: US-11-036 âm 1 · Đã có người nhận
    Biết nhận: việc `UNASSIGNED`, người dùng là ứng viên
    Khi đã có người nhận
    Thì hệ thống từ chối với ERR-11-021 (409)
    Và người dùng thấy thông báo "Việc đã được {người} nhận lúc {giờ}."

  @US-11-036 @FR-11-036 @M @âm
  Kịch bản: US-11-036 âm 2 · Không phải ứng viên
    Biết nhận: việc `UNASSIGNED`, người dùng là ứng viên
    Khi không phải ứng viên
    Thì hệ thống từ chối với ERR-11-022 (403)
    Và người dùng thấy thông báo "Anh/chị không thuộc nhóm được giao việc này."

  @US-11-037 @FR-11-037 @M
  Kịch bản: US-11-037 dương · Xem chi tiết việc và hồ sơ liên quan
    Biết việc thuộc phạm vi người xem
    Khi bấm việc trong hộp việc, mở `/viec-cua-toi/{ma-viec}` (UI-11-15)
    Thì hệ thống trả `200`; `task`, `form`, `data`, `history[]`, `comments[]`, `attachments[]`, `due`, `allowedActions[]`, `draft`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-037 @FR-11-037 @M @âm
  Kịch bản: US-11-037 âm 1 · Không trong phạm vi
    Biết việc thuộc phạm vi người xem
    Khi không trong phạm vi
    Thì hệ thống từ chối với ERR-11-022 (403)
    Và người dùng thấy thông báo "Anh/chị không được giao việc này."

  @US-11-037 @FR-11-037 @M @âm
  Kịch bản: US-11-037 âm 2 · Việc đã kết thúc
    Biết việc thuộc phạm vi người xem
    Khi việc đã kết thúc
    Thì trả `200` chỉ đọc, nhãn thông báo
    Và người dùng thấy thông báo "Đã hoàn thành bởi {người} lúc {giờ}"

  @US-11-038 @FR-11-038 @M
  Kịch bản: US-11-038 dương · Hoàn thành việc với biểu mẫu, ý kiến, quyết định
    Biết việc `ASSIGNED` hoặc `DELEGATED` cho người thao tác; phiên `RUNNING`
    Khi bấm nút quyết định ở UI-11-15
    Thì hệ thống trả `200`; `taskId`, `status` = `COMPLETED`, `nextTasks[]` (việc tiếp theo của chính người dùng nếu có)
    Và việc `COMPLETED`; hạn việc đóng
    Và sự kiện được phát: EVT-11-10, EVT-11-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-038 @FR-11-038 @M @âm
  Kịch bản: US-11-038 âm 1 · Dữ liệu biểu mẫu sai
    Biết việc `ASSIGNED` hoặc `DELEGATED` cho người thao tác; phiên `RUNNING`
    Khi dữ liệu biểu mẫu sai
    Thì hệ thống từ chối với ERR-11-023 (422)
    Và người dùng thấy thông báo "Kiểm tra lại: {danh sách trường và lỗi}."

  @US-11-038 @FR-11-038 @M @âm
  Kịch bản: US-11-038 âm 2 · Không phải người nhận
    Biết việc `ASSIGNED` hoặc `DELEGATED` cho người thao tác; phiên `RUNNING`
    Khi không phải người nhận
    Thì hệ thống từ chối với ERR-11-022 (403)
    Và người dùng thấy thông báo "Việc này đang do {người} xử lý."

  @US-11-039 @FR-11-039 @S
  Kịch bản: US-11-039 dương · Lưu nháp kết quả việc
    Biết việc `ASSIGNED` hoặc `DELEGATED` cho người thao tác
    Khi "Lưu nháp" hoặc tự lưu mỗi 60 s ở UI-11-15
    Thì hệ thống trả `200`; `savedAt`, `ETag`
    Và nháp lưu; việc không đổi trạng thái

  @US-11-039 @FR-11-039 @S @âm
  Kịch bản: US-11-039 âm 1 · Nháp cũ hơn bản đã lưu
    Biết việc `ASSIGNED` hoặc `DELEGATED` cho người thao tác
    Khi nháp cũ hơn bản đã lưu
    Thì hệ thống từ chối với ERR-11-004 (409)
    Và người dùng thấy thông báo "Nháp đã được lưu ở cửa sổ khác. Tải lại để tiếp tục."

  @US-11-040 @FR-11-040 @M
  Kịch bản: US-11-040 dương · Chuyển việc cho người khác
    Biết việc `ASSIGNED`
    Khi "Chuyển việc" ở UI-11-15
    Thì hệ thống trả `200`; `assignee`
    Và `ASSIGNED` cho người mới; hạn việc giữ nguyên
    Và sự kiện được phát: EVT-11-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-040 @FR-11-040 @M @âm
  Kịch bản: US-11-040 âm 1 · Người nhận không hợp lệ
    Biết việc `ASSIGNED`
    Khi người nhận không hợp lệ
    Thì hệ thống từ chối với ERR-11-024 (422)
    Và người dùng thấy thông báo "Không chuyển được cho {người}: {lý do}."

  @US-11-041 @FR-11-041 @S
  Kịch bản: US-11-041 dương · Ủy quyền khi vắng mặt
    Biết người nhận ủy quyền cùng tenant, còn hoạt động
    Khi UI-11-17 "+ Ủy quyền"
    Thì hệ thống trả `201`; `delegationId`, `status`
    Và `delegation` theo vòng đời; việc gắn `delegatedFrom`
    Và sự kiện được phát: EVT-11-09 cho mỗi việc chuyển
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-041 @FR-11-041 @S @âm
  Kịch bản: US-11-041 âm 1 · Ủy quyền không hợp lệ
    Biết người nhận ủy quyền cùng tenant, còn hoạt động
    Khi ủy quyền không hợp lệ
    Thì hệ thống từ chối với ERR-11-025 (422)
    Và người dùng thấy thông báo "Ủy quyền không hợp lệ: {chồng lấn, quá {n} ngày, ủy quyền vòng}."

  @US-11-042 @FR-11-042 @S
  Kịch bản: US-11-042 dương · Phân công lại hàng loạt
    Biết việc chưa kết thúc
    Khi UI-11-16: lọc, chọn, "Giao lại"
    Thì hệ thống trả `202`; `jobId`; kết quả `{succeeded, skipped[]}`
    Và việc đổi người nhận
    Và sự kiện được phát: EVT-11-09 mỗi việc
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-042 @FR-11-042 @S @âm
  Kịch bản: US-11-042 âm 1 · Quá giới hạn
    Biết việc chưa kết thúc
    Khi quá giới hạn
    Thì hệ thống từ chối với ERR-11-050 (422)
    Và người dùng thấy thông báo "Mỗi lần giao lại tối đa {n} việc. Thu hẹp bộ lọc."

  @US-11-043 @FR-11-043 @S
  Kịch bản: US-11-043 dương · Đính kèm tệp, trao đổi ý kiến trên việc
    Biết việc chưa kết thúc (ý kiến sau khi xong chỉ đọc)
    Khi thẻ "Ý kiến", "Tệp" ở UI-11-15
    Thì hệ thống trả `201`; ý kiến hoặc tệp
    Và ý kiến, tệp thuộc phiên, giữ theo chính sách lưu giữ phiên
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-043 @FR-11-043 @S @âm
  Kịch bản: US-11-043 âm 1 · Tệp không hợp lệ
    Biết việc chưa kết thúc (ý kiến sau khi xong chỉ đọc)
    Khi tệp không hợp lệ
    Thì hệ thống từ chối với ERR-11-027
    Và người dùng thấy thông báo "Tệp {tên} không được chấp nhận: {quá {n} MB, loại không cho phép, không an toàn}."

  @US-11-044 @FR-11-044 @M
  Kịch bản: US-11-044 dương · Trả về bước trước, yêu cầu bổ sung hồ sơ
    Biết bước cấu hình `allowReturnTo[]` (trả về) hoặc `allowSupplement` (bổ sung)
    Khi nút "Trả về", "Yêu cầu bổ sung" ở UI-11-15
    Thì hệ thống trả `200`; `status`, `pausedDueAt` khi bổ sung
    Và token ở bước đích hoặc bước chờ bổ sung; `due_tracking` `PAUSED`
    Và sự kiện được phát: EVT-11-10, EVT-11-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-044 @FR-11-044 @M @âm
  Kịch bản: US-11-044 âm 1 · Bước đích không cho phép
    Biết bước cấu hình `allowReturnTo[]` (trả về) hoặc `allowSupplement` (bổ sung)
    Khi bước đích không cho phép
    Thì hệ thống từ chối với ERR-11-026 (422)
    Và người dùng thấy thông báo "Không trả về được bước {tên}. Chỉ trả về: {danh sách}."

  @US-11-044 @FR-11-044 @M @âm
  Kịch bản: US-11-044 âm 2 · Thiếu ý kiến
    Biết bước cấu hình `allowReturnTo[]` (trả về) hoặc `allowSupplement` (bổ sung)
    Khi thiếu ý kiến
    Thì hệ thống từ chối với ERR-11-007 (422)
    Và người dùng thấy thông báo "Nêu rõ nội dung cần sửa hoặc bổ sung (tối thiểu 20 ký tự)."

  # ---- EP-11-F · Hạn xử lý

  @US-11-045 @FR-11-045 @M
  Kịch bản: US-11-045 dương · Quản lý lịch làm việc theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-11-18: chọn năm, sửa ngày, "Nhập từ lịch quốc gia"
    Thì hệ thống trả `200`; lịch năm, `recalculatedDues`
    Và lịch năm có hiệu lực; hạn chưa đóng được tính lại
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-045 @FR-11-045 @M @âm
  Kịch bản: US-11-045 âm 1 · Lịch sai
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi lịch sai
    Thì hệ thống từ chối với ERR-11-028 (422)
    Và người dùng thấy thông báo "Lịch không hợp lệ: {ngày trùng, giờ chồng, ngày ngoài năm}."

  @US-11-046 @FR-11-046 @M
  Kịch bản: US-11-046 dương · Tính hạn xử lý theo ngày làm việc cho phiên và việc
    Biết mô hình hoặc bước có `due`
    Khi khởi tạo phiên (hạn phiên), tạo việc (hạn việc), tiếp tục sau tạm dừng, đổi lịch
    Thì hệ thống trả `dueAt`, `dueSoonAt`; với tính thử `200` và `explain[]` (ngày bỏ qua và lý do)
    Và `due_tracking` mở

  @US-11-046 @FR-11-046 @M @âm
  Kịch bản: US-11-046 âm 1 · Thiếu lịch năm
    Biết mô hình hoặc bước có `due`
    Khi thiếu lịch năm
    Thì hệ thống từ chối với ERR-11-116
    Và người dùng thấy thông báo "Năm {năm} chưa có lịch làm việc; hạn đang tính theo lịch mặc định."

  @US-11-047 @FR-11-047 @M
  Kịch bản: US-11-047 dương · Nhắc hạn trước hạn
    Biết `due_tracking` `ON_TIME`, chưa đóng, không `PAUSED`
    Khi bộ quét hạn chạy mỗi `11.due.scanMinutes` phút, chọn bản ghi có `dueSoonAt` ≤ bây giờ
    Thì cán bộ được nhắc trước hạn
    Và `DUE_SOON`
    Và sự kiện được phát: EVT-11-11

  @US-11-047 @FR-11-047 @M @âm
  Kịch bản: US-11-047 âm 1 · Không gửi được thông báo
    Biết `due_tracking` `ON_TIME`, chưa đóng, không `PAUSED`
    Khi không gửi được thông báo
    Thì hệ thống từ chối với ERR-11-123
    Và người dùng thấy thông báo "Nhắc hạn việc {taskId} chưa gửi được."

  @US-11-048 @FR-11-048 @M
  Kịch bản: US-11-048 dương · Xử lý quá hạn, leo thang
    Biết `due_tracking` chưa đóng, không `PAUSED`, `dueAt` ≤ bây giờ
    Khi bộ quét hạn
    Thì quá hạn được nhìn thấy và có người chịu trách nhiệm xử lý
    Và `OVERDUE`, `escalationLevel` tăng
    Và sự kiện được phát: EVT-11-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-048 @FR-11-048 @M @âm
  Kịch bản: US-11-048 âm 1 · Không tìm được lãnh đạo đơn vị
    Biết `due_tracking` chưa đóng, không `PAUSED`, `dueAt` ≤ bây giờ
    Khi không tìm được lãnh đạo đơn vị
    Thì hệ thống từ chối với ERR-11-113
    Và người dùng thấy thông báo "Không xác định được lãnh đạo đơn vị {đơn vị} để báo quá hạn."

  @US-11-049 @FR-11-049 @M
  Kịch bản: US-11-049 dương · Tạm dừng tính hạn khi chờ bổ sung
    Biết phiên vào bước chờ bổ sung (FR-11-044) hoặc tạm dừng có `pauseDue` (FR-11-023)
    Khi vào hoặc ra khỏi trạng thái chờ
    Thì API-11-089: `202`; `instanceId`, `dueAt` mới
    Và `due_tracking` có `pausedDuration` cập nhật
    Và sự kiện được phát: EVT-11-04 (`displayStatus` đổi)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-049 @FR-11-049 @M @âm
  Kịch bản: US-11-049 âm 1 · Hết `deadline` bổ sung mà chưa nhận bổ sung
    Biết phiên vào bước chờ bổ sung (FR-11-044) hoặc tạm dừng có `pauseDue` (FR-11-023)
    Khi hết `deadline` bổ sung mà chưa nhận bổ sung
    Thì hệ thống từ chối với ERR-11-125

  @US-11-049 @FR-11-049 @M @âm
  Kịch bản: US-11-049 âm 2 · Phiên không chờ bổ sung
    Biết phiên vào bước chờ bổ sung (FR-11-044) hoặc tạm dừng có `pauseDue` (FR-11-023)
    Khi phiên không chờ bổ sung
    Thì hệ thống từ chối với ERR-11-049 (404)
    Và người dùng thấy thông báo "Hồ sơ {businessKey} hiện không chờ bổ sung."

  @US-11-050 @FR-11-050 @S
  Kịch bản: US-11-050 dương · Báo cáo đúng hạn, trễ hạn
    Biết có `due_tracking` đã đóng trong khoảng
    Khi UI-11-22
    Thì hệ thống trả `200`; `rows[]` {`key`, `met`, `missed`, `overdueOpen`, `onTimeRate`, `p50Hours`, `p90Hours`}
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-050 @FR-11-050 @S @âm
  Kịch bản: US-11-050 âm 1 · Khoảng quá dài
    Biết có `due_tracking` đã đóng trong khoảng
    Khi khoảng quá dài
    Thì hệ thống từ chối với ERR-11-039 (422)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa 366 ngày."

  # ---- EP-11-G · Saga bù trừ

  @US-11-051 @FR-11-051 @M
  Kịch bản: US-11-051 dương · Điều phối bù trừ khi lỗi bước
    Biết có bước đã xong có `compensation_action`
    Khi lỗi nghiệp vụ không có biên bắt (FR-11-029), `COMPENSATION_THROW` trong mô hình, hủy kèm bù trừ (FR-11-024), "Kích hoạt bù trừ" ở UI-11-12
    Thì thủ công: `202`; `sagaId`, `steps[]`
    Và phiên `COMPENSATED` hoặc `FAILED`
    Và sự kiện được phát: EVT-11-13, EVT-11-14 hoặc EVT-11-15, EVT-11-17 cho mỗi lệnh bù trừ, EVT-11-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-051 @FR-11-051 @M @âm
  Kịch bản: US-11-051 âm 1 · Đang bù trừ
    Biết có bước đã xong có `compensation_action`
    Khi đang bù trừ
    Thì hệ thống từ chối với ERR-11-030 (409)
    Và người dùng thấy thông báo "Phiên đang bù trừ."

  @US-11-051 @FR-11-051 @M @âm
  Kịch bản: US-11-051 âm 2 · Không có gì để bù trừ
    Biết có bước đã xong có `compensation_action`
    Khi không có gì để bù trừ
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Hồ sơ chưa có bước nào cần bù trừ."

  @US-11-052 @FR-11-052 @M
  Kịch bản: US-11-052 dương · Theo dõi nhật ký Saga
    Biết có `saga_log`
    Khi UI-11-21; thẻ Bù trừ ở UI-11-12
    Thì hệ thống trả `200`; `items[]` {`sagaId`, `businessKey`, `trigger`, `status`, `stepCount`, `manualCount`, `startedAt`, `endedAt`}
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-052 @FR-11-052 @M @âm
  Kịch bản: US-11-052 âm 1 · Tham số sai
    Biết có `saga_log`
    Khi tham số sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Điều kiện lọc không hợp lệ: {trường}."

  @US-11-053 @FR-11-053 @M
  Kịch bản: US-11-053 dương · Xử lý bù trừ thất bại
    Biết `saga_step` `MANUAL`
    Khi việc `MANUAL_COMPENSATION` trong hộp việc của TO; UI-11-21
    Thì hệ thống trả `200`; `stepStatus`, `sagaStatus`
    Và bước `RUNNING`, `DONE` hoặc `SKIPPED`
    Và sự kiện được phát: EVT-11-14 khi Saga xong
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-053 @FR-11-053 @M @âm
  Kịch bản: US-11-053 âm 1 · Bước không ở thủ công
    Biết `saga_step` `MANUAL`
    Khi bước không ở thủ công
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Bước bù trừ này không chờ xử lý thủ công."

  @US-11-053 @FR-11-053 @M @âm
  Kịch bản: US-11-053 âm 2 · Tự duyệt bỏ qua
    Biết `saga_step` `MANUAL`
    Khi tự duyệt bỏ qua
    Thì hệ thống từ chối với ERR-11-005 (403)
    Và người dùng thấy thông báo "Người đề nghị bỏ qua không được tự duyệt."

  @US-11-054 @FR-11-054 @S
  Kịch bản: US-11-054 dương · Đối soát bù trừ định kỳ
    Biết ý định bù trừ có `verifyIntentCode` (ý định tra trạng thái)
    Khi lịch `11.saga.reconcileCron` (mặc định 02:00 hằng ngày); "Chạy đối soát" ở UI-11-21
    Thì hệ thống trả `202`; `reconciliationId`; kết quả {`checked`, `mismatched`}
    Và bản ghi đối soát
    Và sự kiện được phát: EVT-11-16 khi lệch
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-054 @FR-11-054 @S @âm
  Kịch bản: US-11-054 âm 1 · Lệch
    Biết ý định bù trừ có `verifyIntentCode` (ý định tra trạng thái)
    Khi lệch
    Thì hệ thống từ chối với ERR-11-121
    Và người dùng thấy thông báo "Đối soát phát hiện {n} bù trừ chưa có hiệu lực ở {cơ quan}."

  # ---- EP-11-H · Tiến độ

  @US-11-055 @FR-11-055 @M
  Kịch bản: US-11-055 dương · Cung cấp tiến độ hồ sơ cho kênh DVC
    Biết phiên tồn tại, do client cùng tenant tạo hoặc client được cấp đọc mô hình đó
    Khi `GET /progress/{businessKey}`
    Thì hệ thống trả `200`; xem ví dụ; `Cache-Control: max-age=30`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-055 @FR-11-055 @M @âm
  Kịch bản: US-11-055 âm 1 · Không có hoặc không được phép
    Biết phiên tồn tại, do client cùng tenant tạo hoặc client được cấp đọc mô hình đó
    Khi không có hoặc không được phép
    Thì hệ thống từ chối với ERR-11-035 (404)
    Và người dùng thấy thông báo "Không tìm thấy hồ sơ {businessKey}."

  @US-11-056 @FR-11-056 @M
  Kịch bản: US-11-056 dương · Phát sự kiện tiến độ
    Biết topic `{tenant}.bpm.*` đã đăng ký ở PH-10 (FR-10-067)
    Khi chuyển trạng thái phiên, việc, bước có `publicName` hoặc cờ `emitProgress`
    Thì sự kiện trên Kafka
    Và `outbox_event` `SENT`
    Và sự kiện được phát: EVT-11-03…07

  @US-11-056 @FR-11-056 @M @âm
  Kịch bản: US-11-056 âm 1 · Outbox tồn đọng
    Biết topic `{tenant}.bpm.*` đã đăng ký ở PH-10 (FR-10-067)
    Khi outbox tồn đọng
    Thì hệ thống từ chối với ERR-11-117
    Và người dùng thấy thông báo "Có {n} sự kiện chưa gửi quá {m} phút."

  @US-11-057 @FR-11-057 @M
  Kịch bản: US-11-057 dương · Tra lịch sử bước phục vụ kiểm toán
    Biết phiên còn trong thời hạn lưu giữ
    Khi UI-11-12 thẻ "Lịch sử đầy đủ"; "Xuất bằng chứng"
    Thì hệ thống trả `200`; `events[]` {`at`, `elementId`, `name`, `type`, `actor`, `decision`, `comment`, `durationWorkingHours`}; tệp khi xuất
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-057 @FR-11-057 @M @âm
  Kịch bản: US-11-057 âm 1 · Phiên quá hạn lưu giữ
    Biết phiên còn trong thời hạn lưu giữ
    Khi phiên quá hạn lưu giữ
    Thì hệ thống từ chối với ERR-11-001 (410)
    Và người dùng thấy thông báo "Lịch sử hồ sơ {businessKey} đã hết thời hạn lưu giữ."

  # ---- EP-11-I · Giám sát

  @US-11-058 @FR-11-058 @M
  Kịch bản: US-11-058 dương · Bảng điều khiển giám sát quy trình
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mở `/quy-trinh/giam-sat`
    Thì hệ thống trả `200`; `cards[]`, `trends[]`, `bottlenecks[]`

  @US-11-058 @FR-11-058 @M @âm
  Kịch bản: US-11-058 âm 1 · Tham số sai
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tham số sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Khoảng thời gian không hợp lệ."

  @US-11-059 @FR-11-059 @S
  Kịch bản: US-11-059 dương · Phát hiện tắc nghẽn bước
    Biết mô hình có ít nhất `11.bottleneck.minSamples` phiên đã qua bước trong 30 ngày
    Khi tác vụ mỗi 15 phút
    Thì API-11-108: `200`; `items[]` {`processKey`, `elementId`, `waiting`, `p95Hours`, `oldestHours`}
    Và sự cố mở cho phiên tắc
    Và sự kiện được phát: EVT-11-16

  @US-11-059 @FR-11-059 @S @âm
  Kịch bản: US-11-059 âm 1 · Phiên tắc
    Biết mô hình có ít nhất `11.bottleneck.minSamples` phiên đã qua bước trong 30 ngày
    Khi phiên tắc
    Thì hệ thống từ chối với ERR-11-115
    Và người dùng thấy thông báo "{n} hồ sơ chờ ở bước {tên} quá {m} giờ."

  @US-11-060 @FR-11-060 @M
  Kịch bản: US-11-060 dương · Quản lý sự cố engine và thử lại
    Biết có `incident` `OPEN`
    Khi UI-11-20; cảnh báo
    Thì hệ thống trả `200`; `results[]` {`incidentId`, `status`}
    Và sự cố `RETRYING`, `RESOLVED` hoặc `IGNORED`
    Và sự kiện được phát: EVT-11-16 khi mở; không phát khi đóng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-060 @FR-11-060 @M @âm
  Kịch bản: US-11-060 âm 1 · Sự cố đã đóng
    Biết có `incident` `OPEN`
    Khi sự cố đã đóng
    Thì hệ thống từ chối với ERR-11-006 (409)
    Và người dùng thấy thông báo "Sự cố đã được xử lý."

  @US-11-060 @FR-11-060 @M @âm
  Kịch bản: US-11-060 âm 2 · Job lỗi tiếp
    Biết có `incident` `OPEN`
    Khi job lỗi tiếp
    Thì hệ thống từ chối với ERR-11-107
    Và người dùng thấy thông báo "Thử lại không thành công: {mô tả}."

  @US-11-061 @FR-11-061 @M
  Kịch bản: US-11-061 dương · Chỉ số và cảnh báo vận hành
    Biết PH-13 sẵn sàng nhận OpenTelemetry
    Khi liên tục; UI-11-23 thẻ "Cảnh báo"
    Thì hệ thống trả `200`; quy tắc đã lưu
    Và quy tắc có hiệu lực ở PH-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-061 @FR-11-061 @M @âm
  Kịch bản: US-11-061 âm 1 · Ngưỡng ngoài miền
    Biết PH-13 sẵn sàng nhận OpenTelemetry
    Khi ngưỡng ngoài miền
    Thì hệ thống từ chối với ERR-11-029 (422)
    Và người dùng thấy thông báo "Ngưỡng {tên} phải trong khoảng {min}…{max}."

  # ---- EP-11-J · Quản trị

  @US-11-062 @FR-11-062 @M
  Kịch bản: US-11-062 dương · Cấu hình tham số 11.* theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-11-23 thẻ "Tham số"
    Thì hệ thống trả `200`; `settings[]`
    Và `tenant_setting` cập nhật; giá trị cũ trong lịch sử
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-062 @FR-11-062 @M @âm
  Kịch bản: US-11-062 âm 1 · Ngoài miền
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ngoài miền
    Thì hệ thống từ chối với ERR-11-029 (422)
    Và người dùng thấy thông báo "{key} phải trong khoảng {min}…{max} (trần nền tảng {trần})."

  @US-11-063 @FR-11-063 @M
  Kịch bản: US-11-063 dương · Lưu giữ, dọn lịch sử phiên
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi lịch `11.retention.cleanupCron` (mặc định 01:00); UI-11-23 thẻ "Lưu giữ"
    Thì hệ thống trả `200` khi sửa chính sách; báo cáo dọn {`purgedEngine`, `purgedBusiness`, `held`}
    Và bảng lịch sử giảm; chính sách cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-063 @FR-11-063 @M @âm
  Kịch bản: US-11-063 âm 1 · Dọn phiên đang giữ pháp lý (thao tác tay)
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dọn phiên đang giữ pháp lý (thao tác tay)
    Thì hệ thống từ chối với ERR-11-047 (409)
    Và người dùng thấy thông báo "Hồ sơ {businessKey} đang được giữ theo yêu cầu pháp lý."

  @US-11-063 @FR-11-063 @M @âm
  Kịch bản: US-11-063 âm 2 · Dọn lỗi
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dọn lỗi
    Thì hệ thống từ chối với ERR-11-122
    Và người dùng thấy thông báo "Dọn lịch sử lỗi ở lô {n}: {mô tả}."

  @US-11-064 @FR-11-064 @M
  Kịch bản: US-11-064 dương · Xuất bằng chứng tuân thủ BPMN 2.0
    Biết quy trình mẫu `MAU_TUAN_THU_BPMN` (liên thông rút gọn hai cơ quan) được cài sẵn ở môi trường thử
    Khi UI-11-23 thẻ "Tuân thủ": "Chạy mẫu và xuất bằng chứng"
    Thì hệ thống trả `202`; `evidencePackId`; tải gói qua API-11-122 (`409` ERR-11-006 khi gói chưa dựng xong); danh sách lần chạy mẫu ở API-11-137
    Và gói bằng chứng lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-064 @FR-11-064 @M @âm
  Kịch bản: US-11-064 âm 1 · Khoảng thống kê quá dài
    Biết quy trình mẫu `MAU_TUAN_THU_BPMN` (liên thông rút gọn hai cơ quan) được cài sẵn ở môi trường thử
    Khi khoảng thống kê quá dài
    Thì hệ thống từ chối với ERR-11-039 (422)
    Và người dùng thấy thông báo "Khoảng thống kê tối đa 12 tháng."

  @US-11-065 @FR-11-065 @M
  Kịch bản: US-11-065 dương · Xem nhật ký kiểm toán phân hệ
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-11-23 thẻ "Nhật ký"
    Thì hệ thống trả `200`; `items[]` {`at`, `actor`, `action`, `objectType`, `objectId`, `detail`, `hashRef`}
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-065 @FR-11-065 @M @âm
  Kịch bản: US-11-065 âm 1 · Tham số sai
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tham số sai
    Thì hệ thống từ chối với ERR-11-003 (400)
    Và người dùng thấy thông báo "Điều kiện lọc không hợp lệ: {trường}."

  @US-11-066 @FR-11-066 @C
  Kịch bản: US-11-066 dương · Gợi ý xử lý việc bằng AI
    Biết mô hình bật `aiAssist` cho bước; tenant bật PH-17
    Khi bấm "Gợi ý" ở UI-11-15
    Thì hệ thống trả `200`; `suggestions[]` {`field`, `value`, `rationale`}
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-11-066 @FR-11-066 @C @âm
  Kịch bản: US-11-066 âm 1 · PH-17 không trả lời
    Biết mô hình bật `aiAssist` cho bước; tenant bật PH-17
    Khi PH-17 không trả lời
    Thì hệ thống từ chối với ERR-11-124
    Và người dùng thấy thông báo "Chưa lấy được gợi ý, anh/chị tiếp tục xử lý như bình thường."
