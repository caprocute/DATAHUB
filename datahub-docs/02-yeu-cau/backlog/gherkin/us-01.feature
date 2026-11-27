# language: vi
# Sinh tự động từ D02-02/D02-03-PH01 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-01
Tính năng: PH-01 · Kết nạp hệ thống thông tin

  # ---- EP-01-A · Hồ sơ HTTT và đầu mối

  @US-01-001 @FR-01-001 @M
  Kịch bản: US-01-001 dương · Liệt kê, tìm kiếm, lọc HTTT thành viên
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở menu Kết nối & API › Hệ thống thành viên, hoặc đổi ô tìm kiếm, bộ lọc, trang, sắp xếp
    Thì hệ thống trả `200`; `items[]`: `code`, `name`, `ownerOrg{id, name}`, `status`, `reviewStage`, `group`, `roles[]`, `securityLevel`, `scopeCount`, `calls30d` (từ PH-13, rỗng nếu PH-13 không khả dụng), `lastReviewAt`, `flags[]`, `updatedAt` …

  @US-01-001 @FR-01-001 @M @âm
  Kịch bản: US-01-001 âm 1 · Tham số lọc sai miền
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số lọc sai miền
    Thì hệ thống từ chối với ERR-01-003 (400)
    Và người dùng thấy thông báo "Giá trị bộ lọc {tên} không hợp lệ."

  @US-01-001 @FR-01-001 @M @âm
  Kịch bản: US-01-001 âm 2 · Không có kết quả
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi không có kết quả
    Thì trả danh sách rỗng, màn hình hiện thông báo
    Và người dùng thấy thông báo "Không có hệ thống nào khớp. Bỏ bớt bộ lọc hoặc bấm + Tạo hồ sơ."

  @US-01-002 @FR-01-002 @M
  Kịch bản: US-01-002 dương · Xem chi tiết HTTT thành viên
    Biết người dùng đã đăng nhập, chọn tenant; HTTT tồn tại trong tenant
    Khi người dùng bấm một dòng ở danh sách hoặc mở đường dẫn `/ket-noi/he-thong/{ma}`
    Thì hệ thống trả `200`; HTTT đầy đủ thuộc tính DD-03, `technicalProfile`, `dataDemands[]`, `ceiling[]`, `contacts[]`, `credentials[]` (không bí mật), `allowedActions[]`; tiêu đề `ETag`

  @US-01-002 @FR-01-002 @M @âm
  Kịch bản: US-01-002 âm 1 · Không thấy HTTT
    Biết người dùng đã đăng nhập, chọn tenant; HTTT tồn tại trong tenant
    Khi không thấy HTTT
    Thì hệ thống từ chối với ERR-01-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy hệ thống {mã}."

  @US-01-002 @FR-01-002 @M @âm
  Kịch bản: US-01-002 âm 2 · PH-02 không khả dụng khi tải tab "API đang dùng"
    Biết người dùng đã đăng nhập, chọn tenant; HTTT tồn tại trong tenant
    Khi PH-02 không khả dụng khi tải tab "API đang dùng"
    Thì hệ thống từ chối với ERR-01-046
    Và người dùng thấy thông báo "Chưa tải được danh sách API. Thử lại sau."

  @US-01-003 @FR-01-003 @M
  Kịch bản: US-01-003 dương · Tạo hồ sơ kết nạp nháp
    Biết người dùng đã đăng nhập, chọn tenant; tổ chức chủ quản có trong danh mục tổ chức của PH-20 và đang hoạt động
    Khi người dùng bấm "+ Tạo hồ sơ" ở UI-01-03, bước 1 của trình hướng dẫn UI-01-01
    Thì hệ thống trả `201`; HTTT ở `DRAFT` với `applicationNo`, `revisionNo`; tiêu đề `Location`, `ETag`
    Và có một HTTT `DRAFT`; chưa có định danh, chưa thẩm định; mã HTTT đã bị giữ
    Và sự kiện được phát: EVT-01-03 (chuyển `∅ → DRAFT`; không gửi tới PH-10 vì chưa là HTTT hoạt động)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-003 @FR-01-003 @M @âm
  Kịch bản: US-01-003 âm 1 · Mã đã dùng
    Biết người dùng đã đăng nhập, chọn tenant; tổ chức chủ quản có trong danh mục tổ chức của PH-20 và đang hoạt động
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-01-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng (kể cả hệ thống đã chấm dứt). Chọn mã khác."

  @US-01-003 @FR-01-003 @M @âm
  Kịch bản: US-01-003 âm 2 · Tổ chức không tồn tại hoặc ngừng hoạt động
    Biết người dùng đã đăng nhập, chọn tenant; tổ chức chủ quản có trong danh mục tổ chức của PH-20 và đang hoạt động
    Khi tổ chức không tồn tại hoặc ngừng hoạt động
    Thì hệ thống từ chối với ERR-01-004 (422)
    Và người dùng thấy thông báo "Tổ chức chủ quản không có trong danh mục hoặc đã ngừng hoạt động. Liên hệ quản trị tỉnh."

  @US-01-004 @FR-01-004 @M
  Kịch bản: US-01-004 dương · Sửa hồ sơ nháp, tự lưu
    Biết HTTT ở `DRAFT` (kể cả hồ sơ bị trả bổ sung)
    Khi người dùng sửa một trường ở UI-01-01, bấm "Lưu nháp", hoặc bộ tự lưu 30 giây chạy khi có thay đổi
    Thì hệ thống trả `200`; hồ sơ đã cập nhật; `ETag`, `savedAt`
    Và hồ sơ `DRAFT` mang nội dung mới nhất; `updatedAt` mới; bộ đếm hạn giữ nháp (90 ngày) tính lại
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-004 @FR-01-004 @M @âm
  Kịch bản: US-01-004 âm 1 · Hồ sơ không còn `DRAFT`
    Biết HTTT ở `DRAFT` (kể cả hồ sơ bị trả bổ sung)
    Khi hồ sơ không còn `DRAFT`
    Thì hệ thống từ chối với ERR-01-005 (409)
    Và người dùng thấy thông báo "Hồ sơ đã nộp, không sửa được. Dùng Rút hồ sơ nếu cần sửa."

  @US-01-004 @FR-01-004 @M @âm
  Kịch bản: US-01-004 âm 2 · Người khác đã sửa
    Biết HTTT ở `DRAFT` (kể cả hồ sơ bị trả bổ sung)
    Khi người khác đã sửa
    Thì hệ thống từ chối với ERR-01-007 (412)
    Và người dùng thấy thông báo "Hồ sơ vừa được {tên} cập nhật lúc {giờ}. Xem khác biệt để quyết định giữ bản nào."

  @US-01-005 @FR-01-005 @M
  Kịch bản: US-01-005 dương · Đính kèm, xem, xóa tài liệu hồ sơ
    Biết HTTT ở `DRAFT` (tải lên, xóa); bất kỳ trạng thái (xem)
    Khi người dùng kéo thả tệp vào khu tải tài liệu, hoặc bấm tên tài liệu để xem
    Thì hệ thống trả `201` với `attachmentId`, `kind`, `fileName`, `sizeBytes`, `sha256`, `scanStatus`; xem tệp: `200` hoặc `302` tới liên kết ký
    Và siêu dữ liệu ở `ph01_onboarding.file_object`; nội dung ở kho đối tượng, mã hóa khi lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-005 @FR-01-005 @M @âm
  Kịch bản: US-01-005 âm 1 · Tệp quá cỡ
    Biết HTTT ở `DRAFT` (tải lên, xóa); bất kỳ trạng thái (xem)
    Khi tệp quá cỡ
    Thì hệ thống từ chối với ERR-01-012 (413)
    Và người dùng thấy thông báo "Tệp lớn hơn {n} MB. Nén hoặc chia nhỏ tệp."

  @US-01-005 @FR-01-005 @M @âm
  Kịch bản: US-01-005 âm 2 · Định dạng không được phép
    Biết HTTT ở `DRAFT` (tải lên, xóa); bất kỳ trạng thái (xem)
    Khi định dạng không được phép
    Thì hệ thống từ chối với ERR-01-013 (415)
    Và người dùng thấy thông báo "Chỉ nhận PDF, DOCX, XLSX, PNG, JPG."

  @US-01-006 @FR-01-006 @M
  Kịch bản: US-01-006 dương · Khai hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT
    Biết HTTT ở `DRAFT`
    Khi người dùng điền bước 3 của UI-01-01 (phần "Năng lực kỹ thuật")
    Thì hệ thống trả `200`; hồ sơ kỹ thuật, `proposedGroup`, `explanation[]`
    Và hồ sơ kỹ thuật lưu kèm nhóm đề xuất; con số kết nối đồng thời được PH-05 dùng để đặt giới hạn đồng thời cho bộ điều hợp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-006 @FR-01-006 @M @âm
  Kịch bản: US-01-006 âm 1 · Số kết nối đồng thời nhỏ hơn 1 hoặc không phải số nguyên
    Biết HTTT ở `DRAFT`
    Khi số kết nối đồng thời nhỏ hơn 1 hoặc không phải số nguyên
    Thì hệ thống từ chối với ERR-01-003 (400)
    Và người dùng thấy thông báo "Số kết nối đồng thời tối đa phải là số nguyên từ 1. Hỏi đơn vị vận hành hệ thống để biết giá trị này."

  @US-01-006 @FR-01-006 @M @âm
  Kịch bản: US-01-006 âm 2 · Nhóm 3 thiếu loại CSDL
    Biết HTTT ở `DRAFT`
    Khi nhóm 3 thiếu loại CSDL
    Thì hệ thống từ chối với ERR-01-003 (400)
    Và người dùng thấy thông báo "Hệ thống không có API cần khai loại CSDL để chuẩn bị bắt thay đổi dữ liệu."

  @US-01-007 @FR-01-007 @M
  Kịch bản: US-01-007 dương · Khai nhu cầu khai thác kèm căn cứ pháp lý
    Biết HTTT ở `DRAFT`
    Khi người dùng thêm, sửa, xóa dòng ở bảng "Dữ liệu đề nghị" của UI-01-01 bước 3
    Thì hệ thống trả `200`; `dataDemands[]` kèm `missingLegalBasis` cho từng dòng
    Và danh sách nhu cầu của hồ sơ cập nhật; chưa có kết luận thẩm định
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-007 @FR-01-007 @M @âm
  Kịch bản: US-01-007 âm 1 · Dữ liệu thuộc danh mục bí mật nhà nước
    Biết HTTT ở `DRAFT`
    Khi dữ liệu thuộc danh mục bí mật nhà nước
    Thì hệ thống từ chối với ERR-01-016 (422)
    Và người dùng thấy thông báo "Dữ liệu này thuộc danh mục bí mật nhà nước, không kết nối qua Datahub."

  @US-01-007 @FR-01-007 @M @âm
  Kịch bản: US-01-007 âm 2 · Căn cứ không đủ số, ngày hoặc cơ quan ban hành
    Biết HTTT ở `DRAFT`
    Khi căn cứ không đủ số, ngày hoặc cơ quan ban hành
    Thì hệ thống từ chối với ERR-01-015 (422)
    Và người dùng thấy thông báo "Mục {tên} chưa có căn cứ pháp lý. Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác."

  @US-01-008 @FR-01-008 @M
  Kịch bản: US-01-008 dương · Quản lý đầu mối liên hệ của HTTT
    Biết HTTT tồn tại và chưa `TERMINATED`, `REJECTED`
    Khi người dùng thêm, sửa, thay thế, bỏ một đầu mối ở UI-01-01 bước 2 hoặc tab "Đầu mối" của UI-01-04
    Thì hệ thống trả `201` (thêm), `200` (sửa, thay thế), `204` (bỏ); danh sách đầu mối đã cập nhật
    Và đầu mối lưu ở DD-04; đầu mối cũ giữ lại lịch sử ở trạng thái `INACTIVE`
    Và sự kiện được phát: EVT-01-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-008 @FR-01-008 @M @âm
  Kịch bản: US-01-008 âm 1 · Thư điện tử ngoài miền công vụ
    Biết HTTT tồn tại và chưa `TERMINATED`, `REJECTED`
    Khi thư điện tử ngoài miền công vụ
    Thì hệ thống từ chối với ERR-01-011 (422)
    Và người dùng thấy thông báo "Thư điện tử phải thuộc miền {danh sách}. Dùng thư công vụ của cơ quan."

  @US-01-008 @FR-01-008 @M @âm
  Kịch bản: US-01-008 âm 2 · Bỏ hoặc vô hiệu đầu mối kỹ thuật cuối cùng
    Biết HTTT tồn tại và chưa `TERMINATED`, `REJECTED`
    Khi bỏ hoặc vô hiệu đầu mối kỹ thuật cuối cùng
    Thì hệ thống từ chối với ERR-01-050 (409)
    Và người dùng thấy thông báo "HTTT phải còn ít nhất một đầu mối kỹ thuật. Thêm đầu mối mới trước khi bỏ người này."

  @US-01-009 @FR-01-009 @S
  Kịch bản: US-01-009 dương · Xóa hồ sơ nháp và rút hồ sơ đã nộp
    Biết xóa: HTTT ở `DRAFT`
    Khi người dùng bấm "Xóa hồ sơ" hoặc "Rút hồ sơ"; hoặc tác vụ dọn nháp hằng ngày
    Thì hệ thống trả `204` (xóa), `200` hồ sơ `DRAFT` (rút)
    Và `DRAFT` hoặc xóa mềm; các việc thẩm định của hồ sơ biến mất khỏi hộp "Việc của tôi"
    Và sự kiện được phát: EVT-01-03 (khi rút)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-009 @FR-01-009 @S @âm
  Kịch bản: US-01-009 âm 1 · Hồ sơ đã được phê duyệt hoặc từ chối
    Biết xóa: HTTT ở `DRAFT`
    Khi hồ sơ đã được phê duyệt hoặc từ chối
    Thì hệ thống từ chối với ERR-01-005 (409)
    Và người dùng thấy thông báo "Hồ sơ đã có quyết định, không rút được."

  @US-01-010 @FR-01-010 @S
  Kịch bản: US-01-010 dương · Cung cấp mẫu văn bản và hướng dẫn kết nạp
    Biết có ít nhất một mẫu đã được công bố cho tenant
    Khi người dùng bấm "Tải mẫu văn bản" hoặc "Hướng dẫn" ở UI-01-01
    Thì hệ thống trả `200`; `templates[]`: `templateCode`, `title`, `version`, `updatedAt`; tệp khi tải

  @US-01-010 @FR-01-010 @S @âm
  Kịch bản: US-01-010 âm 1 · Không có mẫu cho mã yêu cầu
    Biết có ít nhất một mẫu đã được công bố cho tenant
    Khi không có mẫu cho mã yêu cầu
    Thì hệ thống từ chối với ERR-01-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy mẫu {mã}."

  # ---- EP-01-B · Kiểm tra, nộp và thẩm định

  @US-01-011 @FR-01-011 @M
  Kịch bản: US-01-011 dương · Kiểm tra hợp lệ hồ sơ trước khi nộp
    Biết HTTT ở `DRAFT`
    Khi người dùng bấm "Kiểm tra hợp lệ" ở bước "Rà soát" của UI-01-01, hoặc FR-01-012 gọi trước khi nộp
    Thì hệ thống trả `200`; `{ "valid": false, "errorCount": 3, "warningCount": 1, "issues": [ { "path": "dataDemands[1].legalBasis", "code": "ERR-01-015", "severity": "ERROR", "message": "Mục 'Thông tin thửa đất' chưa có căn cứ pháp lý" …

  @US-01-011 @FR-01-011 @M @âm
  Kịch bản: US-01-011 âm 1 · Có thiếu sót mức `ERROR`
    Biết HTTT ở `DRAFT`
    Khi có thiếu sót mức `ERROR`
    Thì hệ thống từ chối với ERR-01-015, ERR-01-016, ERR-01-047, ERR-01-050, ERR-01-008

  @US-01-011 @FR-01-011 @M @âm
  Kịch bản: US-01-011 âm 2 · Đã có hồ sơ khác đang xử lý cho cùng mã HTTT
    Biết HTTT ở `DRAFT`
    Khi đã có hồ sơ khác đang xử lý cho cùng mã HTTT
    Thì hệ thống từ chối với ERR-01-009
    Và người dùng thấy thông báo "Đã có hồ sơ {số hồ sơ} đang xử lý cho hệ thống này."

  @US-01-012 @FR-01-012 @M
  Kịch bản: US-01-012 dương · Nộp hồ sơ kết nạp
    Biết HTTT ở `DRAFT`; lần kiểm tra hợp lệ gần nhất đạt và sau lần sửa cuối
    Khi người dùng bấm "Gửi duyệt" ở bước 5 của UI-01-01
    Thì hệ thống trả `200`; `status = SUBMITTED`, `reviewStage`, `revisionNo`, `steps[]{stepType, dueAt}`
    Và HTTT `SUBMITTED`; nội dung chỉ đọc; các bước thẩm định mở
    Và sự kiện được phát: EVT-01-01, EVT-01-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-012 @FR-01-012 @M @âm
  Kịch bản: US-01-012 âm 1 · Hồ sơ chưa đủ điều kiện nộp
    Biết HTTT ở `DRAFT`; lần kiểm tra hợp lệ gần nhất đạt và sau lần sửa cuối
    Khi hồ sơ chưa đủ điều kiện nộp
    Thì hệ thống từ chối với ERR-01-008 (422)
    Và người dùng thấy thông báo "Hồ sơ còn {n} thiếu sót. Xem danh sách và sửa trước khi nộp."

  @US-01-012 @FR-01-012 @M @âm
  Kịch bản: US-01-012 âm 2 · Hồ sơ vừa bị người khác sửa
    Biết HTTT ở `DRAFT`; lần kiểm tra hợp lệ gần nhất đạt và sau lần sửa cuối
    Khi hồ sơ vừa bị người khác sửa
    Thì hệ thống từ chối với ERR-01-007 (412)

  @US-01-013 @FR-01-013 @M
  Kịch bản: US-01-013 dương · Thẩm định kỹ thuật và xác nhận nhóm HTTT
    Biết HTTT `SUBMITTED`, bước `TECHNICAL` đang mở và được phân công cho người này; người thẩm định không phải người lập hay nộp hồ sơ
    Khi người dùng mở việc từ hộp "Việc của tôi" hoặc hàng đợi UI-01-05, vào tab "Kỹ thuật" của UI-01-06
    Thì hệ thống trả `200`; bước thẩm định đã ghi, `confirmedGroup`, `minAuthMethod`, `reviewStage` mới
    Và bước `TECHNICAL` đóng; khi đủ các bước bắt buộc, `reviewStage = WAITING_APPROVAL`
    Và sự kiện được phát: EVT-01-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-013 @FR-01-013 @M @âm
  Kịch bản: US-01-013 âm 1 · Người thẩm định là người lập hồ sơ
    Biết HTTT `SUBMITTED`, bước `TECHNICAL` đang mở và được phân công cho người này; người thẩm định không phải người lập hay nộp hồ sơ
    Khi người thẩm định là người lập hồ sơ
    Thì hệ thống từ chối với ERR-01-017 (403)
    Và người dùng thấy thông báo "Anh/chị đã lập hoặc nộp hồ sơ này nên không thẩm định được."

  @US-01-013 @FR-01-013 @M @âm
  Kịch bản: US-01-013 âm 2 · Bước không còn mở
    Biết HTTT `SUBMITTED`, bước `TECHNICAL` đang mở và được phân công cho người này; người thẩm định không phải người lập hay nộp hồ sơ
    Khi bước không còn mở
    Thì hệ thống từ chối với ERR-01-020 (409)
    Và người dùng thấy thông báo "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác."

  @US-01-014 @FR-01-014 @M
  Kịch bản: US-01-014 dương · Thẩm định căn cứ pháp lý và ATTT theo từng mục
    Biết HTTT `SUBMITTED`; bước tương ứng đang mở và được phân công; người thẩm định không phải người lập hay nộp hồ sơ
    Khi người dùng mở việc, vào tab "Pháp lý" hoặc "ATTT" của UI-01-06
    Thì hệ thống trả `200`; `{ "stepType": "LEGAL", "result": "PASS", "summary": { "approved": 0, "narrowed": 1, "rejected": 1 }, "ceilingPreview": [ { "dataType": "THONG_TIN_CONG_DAN", "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC …
    Và bước đóng; kết luận từng mục lưu cùng người thẩm định và thời điểm; chưa tạo trần phạm vi chính thức (chỉ khi phê duyệt, FR-01-018)
    Và sự kiện được phát: EVT-01-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-014 @FR-01-014 @M @âm
  Kịch bản: US-01-014 âm 1 · Còn mục chưa đánh giá
    Biết HTTT `SUBMITTED`; bước tương ứng đang mở và được phân công; người thẩm định không phải người lập hay nộp hồ sơ
    Khi còn mục chưa đánh giá
    Thì hệ thống từ chối với ERR-01-018 (422)
    Và người dùng thấy thông báo "Còn {n} mục chưa có kết luận. Đánh giá hết các mục rồi hoàn tất."

  @US-01-014 @FR-01-014 @M @âm
  Kịch bản: US-01-014 âm 2 · Thu hẹp hoặc từ chối không có ý kiến, hoặc thu hẹp không có phạm vi được duyệt
    Biết HTTT `SUBMITTED`; bước tương ứng đang mở và được phân công; người thẩm định không phải người lập hay nộp hồ sơ
    Khi thu hẹp hoặc từ chối không có ý kiến, hoặc thu hẹp không có phạm vi được duyệt
    Thì hệ thống từ chối với ERR-01-019 (422)
    Và người dùng thấy thông báo "Mục {tên}: nhập {phạm vi được duyệt / ý kiến}."

  @US-01-015 @FR-01-015 @S
  Kịch bản: US-01-015 dương · Đánh giá tác động tới hạn mức dữ liệu quốc gia
    Biết HTTT `SUBMITTED`; có ít nhất một nhu cầu `CONSUME` thuộc dịch vụ quốc gia (do PH-14 công bố); `expectedDailyCalls` đã khai
    Khi người thẩm định mở tab "Kỹ thuật", hoặc FR-01-013 bước 6
    Thì hệ thống trả `200`; `impact[]`: `service`, `remaining`, `projected`, `level`, `suggestion`
    Và kết quả lưu vào bước `TECHNICAL`; không chặn quy trình

  @US-01-015 @FR-01-015 @S @âm
  Kịch bản: US-01-015 âm 1 · PH-14 không khả dụng
    Biết HTTT `SUBMITTED`; có ít nhất một nhu cầu `CONSUME` thuộc dịch vụ quốc gia (do PH-14 công bố); `expectedDailyCalls` đã khai
    Khi PH-14 không khả dụng
    Thì hệ thống từ chối với ERR-01-046 (503)
    Và người dùng thấy thông báo "Chưa lấy được hạn mức quốc gia. Ghi nhận xét thủ công hoặc thử lại."

  @US-01-016 @FR-01-016 @M
  Kịch bản: US-01-016 dương · Phân công, theo dõi hạn thẩm định, tham vấn
    Biết HTTT `SUBMITTED`
    Khi nộp hồ sơ (FR-01-012) tạo việc cho nhóm; TA vào hàng đợi UI-01-05 để phân công; tác vụ nhắc việc chạy mỗi giờ
    Thì hệ thống trả `200`; hàng đợi: `items[]` gồm `systemCode`, `applicationNo`, `stepType`, `dueAt`, `overdue`, `assignee`; phân công, tham vấn trả bước đã cập nhật
    Và mỗi bước có người xử lý, hạn và thời gian tạm dừng chính xác
    Và sự kiện được phát: EVT-01-02 (khi phân công); cảnh báo quá hạn gửi PH-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-016 @FR-01-016 @M @âm
  Kịch bản: US-01-016 âm 1 · Giao việc cho người lập hồ sơ
    Biết HTTT `SUBMITTED`
    Khi giao việc cho người lập hồ sơ
    Thì hệ thống từ chối với ERR-01-017 (403)
    Và người dùng thấy thông báo "Không giao được: người này đã lập hồ sơ."

  @US-01-016 @FR-01-016 @M @âm
  Kịch bản: US-01-016 âm 2 · Bước đã đóng
    Biết HTTT `SUBMITTED`
    Khi bước đã đóng
    Thì hệ thống từ chối với ERR-01-020 (409)

  @US-01-017 @FR-01-017 @M
  Kịch bản: US-01-017 dương · Trả bổ sung và nộp lại hồ sơ
    Biết HTTT `SUBMITTED` (bước thẩm định mở hoặc `WAITING_APPROVAL`)
    Khi người xử lý bấm "Trả bổ sung" ở UI-01-06 hoặc UI-01-07
    Thì hệ thống trả `200`; hồ sơ `DRAFT` kèm `returnReason`, `requests[]`
    Và HTTT `DRAFT`; các bước thẩm định đã đóng `RETURNED`; chờ nộp lại
    Và sự kiện được phát: EVT-01-02, EVT-01-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-017 @FR-01-017 @M @âm
  Kịch bản: US-01-017 âm 1 · Không có yêu cầu cụ thể
    Biết HTTT `SUBMITTED` (bước thẩm định mở hoặc `WAITING_APPROVAL`)
    Khi không có yêu cầu cụ thể
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nêu ít nhất một nội dung cần bổ sung."

  @US-01-017 @FR-01-017 @M @âm
  Kịch bản: US-01-017 âm 2 · Hồ sơ không ở bước thẩm định
    Biết HTTT `SUBMITTED` (bước thẩm định mở hoặc `WAITING_APPROVAL`)
    Khi hồ sơ không ở bước thẩm định
    Thì hệ thống từ chối với ERR-01-020 (409)

  @US-01-018 @FR-01-018 @M
  Kịch bản: US-01-018 dương · Phê duyệt hoặc từ chối kết nạp
    Biết HTTT `SUBMITTED`, `reviewStage = WAITING_APPROVAL`: mọi bước bắt buộc đã đóng, bước `LEGAL` có ít nhất một mục `APPROVED` hoặc `NARROWED` (nếu mọi mục `REJECTED` thì hệ thống chỉ cho từ chối hoặc trả bổ sung)
    Khi người dùng mở việc "Duyệt kết nạp" ở UI-01-07 (qua hộp "Việc của tôi")
    Thì hệ thống trả `200`; HTTT với `status` mới; khi duyệt: `provisionStage = PROVISIONING`, `ceiling[]`
    Và `APPROVED` (kèm trần phạm vi) hoặc `REJECTED` (cuối, mã giữ vĩnh viễn)
    Và sự kiện được phát: EVT-01-02, EVT-01-03; khi duyệt thêm EVT-01-11 (trần phạm vi lần đầu)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-018 @FR-01-018 @M @âm
  Kịch bản: US-01-018 âm 1 · Người phê duyệt từng thẩm định hoặc lập hồ sơ
    Biết HTTT `SUBMITTED`, `reviewStage = WAITING_APPROVAL`: mọi bước bắt buộc đã đóng, bước `LEGAL` có ít nhất một mục `APPROVED` hoặc `NARROWED` (nếu mọi mục `REJECTED` thì hệ thống chỉ cho từ chối hoặc trả bổ sung)
    Khi người phê duyệt từng thẩm định hoặc lập hồ sơ
    Thì hệ thống từ chối với ERR-01-017 (403)
    Và người dùng thấy thông báo "Anh/chị đã tham gia hồ sơ này nên không duyệt được. Nhờ người khác."

  @US-01-018 @FR-01-018 @M @âm
  Kịch bản: US-01-018 âm 2 · Hồ sơ chưa đủ kết luận
    Biết HTTT `SUBMITTED`, `reviewStage = WAITING_APPROVAL`: mọi bước bắt buộc đã đóng, bước `LEGAL` có ít nhất một mục `APPROVED` hoặc `NARROWED` (nếu mọi mục `REJECTED` thì hệ thống chỉ cho từ chối hoặc trả bổ sung)
    Khi hồ sơ chưa đủ kết luận
    Thì hệ thống từ chối với ERR-01-020 (409)
    Và người dùng thấy thông báo "Hồ sơ chưa đủ kết luận thẩm định."

  @US-01-019 @FR-01-019 @S
  Kịch bản: US-01-019 dương · Theo dõi tiến độ hồ sơ
    Biết HTTT đã nộp ít nhất một lần
    Khi người dùng mở UI-01-02 hoặc bấm liên kết trong thông báo
    Thì hệ thống trả `200`; `timeline[]`, `waitingOn{role, dueAt, overdue}`, `returnRequests[]`

  @US-01-019 @FR-01-019 @S @âm
  Kịch bản: US-01-019 âm 1 · Hồ sơ chưa từng nộp
    Biết HTTT đã nộp ít nhất một lần
    Khi hồ sơ chưa từng nộp
    Thì trang hiện thông báo
    Và người dùng thấy thông báo "Hồ sơ chưa nộp. Hoàn tất các bước và bấm Gửi duyệt."

  # ---- EP-01-C · Định danh ứng dụng và bàn giao

  @US-01-020 @FR-01-020 @M
  Kịch bản: US-01-020 dương · Cấp định danh SANDBOX sau phê duyệt (saga)
    Biết HTTT `APPROVED`, `provisionStage = PROVISIONING`; đã có trần phạm vi; PH-12, PH-03, OpenBao khả dụng (không thì thử lại, xem luồng ngoại lệ)
    Khi sự kiện EVT-01-03 `SUBMITTED → APPROVED` (qua outbox); hoặc TA bấm "Thử lại cấp định danh" khi saga thất bại
    Thì HTTT có định danh SANDBOX trong không quá 5 phút kể từ lúc phê duyệt (p95); đầu mối nhận thông báo
    Và `APPROVED`, `provisionStage = SANDBOX_READY` hoặc `AWAITING_KEY`; client ở PH-12, consumer ở PH-03, bí mật ở OpenBao; PH-01 giữ `secret_ref`
    Và sự kiện được phát: EVT-01-05; thông báo EVT-01-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-020 @FR-01-020 @M @âm
  Kịch bản: US-01-020 âm 1 · PH-12 không khả dụng
    Biết HTTT `APPROVED`, `provisionStage = PROVISIONING`; đã có trần phạm vi; PH-12, PH-03, OpenBao khả dụng (không thì thử lại, xem luồng ngoại lệ)
    Khi PH-12 không khả dụng
    Thì hệ thống từ chối với ERR-01-021 (503)
    Và người dùng thấy thông báo "Đang chờ dịch vụ định danh, hệ thống sẽ tự thử lại."

  @US-01-020 @FR-01-020 @M @âm
  Kịch bản: US-01-020 âm 2 · Client trùng ở PH-12 (mã HTTT đã có client)
    Biết HTTT `APPROVED`, `provisionStage = PROVISIONING`; đã có trần phạm vi; PH-12, PH-03, OpenBao khả dụng (không thì thử lại, xem luồng ngoại lệ)
    Khi client trùng ở PH-12 (mã HTTT đã có client)
    Thì hệ thống từ chối với ERR-01-022 (409)
    Và người dùng thấy thông báo "Mã client đã tồn tại ở PH-12, cần xử lý thủ công."

  @US-01-021 @FR-01-021 @M
  Kịch bản: US-01-021 dương · Đăng ký khóa công khai hoặc yêu cầu ký chứng thư
    Biết có định danh với `auth_method` là `PRIVATE_KEY_JWT` hoặc `MTLS`; `provisionStage = AWAITING_KEY` hoặc đang xoay vòng (FR-01-025)
    Khi đầu mối bấm "Đăng ký khóa" hoặc "Gửi yêu cầu chứng thư" ở UI-01-08
    Thì hệ thống trả `200`; `jwksRef`/chuỗi chứng thư, `cert_fingerprint`, `expires_at`
    Và định danh có khóa, `provisionStage = SANDBOX_READY`; PH-12 và PH-03 đã cập nhật
    Và sự kiện được phát: EVT-01-05, EVT-01-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-021 @FR-01-021 @M @âm
  Kịch bản: US-01-021 âm 1 · Khóa sai thuật toán, quá yếu, chứa khóa riêng, hoặc `kid` trùng
    Biết có định danh với `auth_method` là `PRIVATE_KEY_JWT` hoặc `MTLS`; `provisionStage = AWAITING_KEY` hoặc đang xoay vòng (FR-01-025)
    Khi khóa sai thuật toán, quá yếu, chứa khóa riêng, hoặc `kid` trùng
    Thì hệ thống từ chối với ERR-01-027 (422)
    Và người dùng thấy thông báo "Khóa không hợp lệ: dùng ES256 (P-256) hoặc PS256 (RSA ≥ 3072 bit), chỉ tải khóa công khai."

  @US-01-021 @FR-01-021 @M @âm
  Kịch bản: US-01-021 âm 2 · CSR sai tên, khóa yếu, hoặc chứng thư không thuộc CA tin cậy
    Biết có định danh với `auth_method` là `PRIVATE_KEY_JWT` hoặc `MTLS`; `provisionStage = AWAITING_KEY` hoặc đang xoay vòng (FR-01-025)
    Khi CSR sai tên, khóa yếu, hoặc chứng thư không thuộc CA tin cậy
    Thì hệ thống từ chối với ERR-01-028 (422)
    Và người dùng thấy thông báo "Yêu cầu chứng thư không hợp lệ: {lý do}."

  @US-01-022 @FR-01-022 @M
  Kịch bản: US-01-022 dương · Bàn giao thông tin xác thực một lần
    Biết có định danh `CLIENT_SECRET` ở trạng thái `ACTIVE` với `secret_ref`; đầu mối `TECHNICAL` có tài khoản người dùng ở tenant (`userAccountId`); bàn giao `PENDING` còn hạn
    Khi đầu mối bấm liên kết trong thư thông báo "Định danh đã sẵn sàng" (thư chỉ chứa liên kết); hoặc TA, OR tạo lại liên kết
    Thì tạo: `201`, `{ "handoverId", "expiresAt", "recipient" }` (không có liên kết gốc ở phản hồi; liên kết chỉ gửi qua thư)
    Và bàn giao `OPENED` hoặc `EXPIRED`, `CANCELLED`; bản sao bí mật của bàn giao bị hủy sau khi mở; PH-01 không giữ bí mật
    Và sự kiện được phát: EVT-01-09 (đã mở); EVT-01-10 (cảnh báo an ninh khi sai người mở, mở sai nhiều lần)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-022 @FR-01-022 @M @âm
  Kịch bản: US-01-022 âm 1 · Liên kết đã dùng, hết hạn hoặc bị hủy
    Biết có định danh `CLIENT_SECRET` ở trạng thái `ACTIVE` với `secret_ref`; đầu mối `TECHNICAL` có tài khoản người dùng ở tenant (`userAccountId`); bàn giao `PENDING` còn hạn
    Khi liên kết đã dùng, hết hạn hoặc bị hủy
    Thì hệ thống từ chối với ERR-01-024 (410)
    Và người dùng thấy thông báo "Liên kết bàn giao đã được sử dụng hoặc hết hạn. Nếu chưa nhận được thông tin, liên hệ quản trị tỉnh để xoay bí mật và nhận liên kết mới."

  @US-01-022 @FR-01-022 @M @âm
  Kịch bản: US-01-022 âm 2 · Người mở không phải đầu mối đã khai báo
    Biết có định danh `CLIENT_SECRET` ở trạng thái `ACTIVE` với `secret_ref`; đầu mối `TECHNICAL` có tài khoản người dùng ở tenant (`userAccountId`); bàn giao `PENDING` còn hạn
    Khi người mở không phải đầu mối đã khai báo
    Thì hệ thống từ chối với ERR-01-025 (403)
    Và người dùng thấy thông báo "Tài khoản này không phải đầu mối nhận bàn giao. Sự việc đã được ghi nhận."

  @US-01-023 @FR-01-023 @M
  Kịch bản: US-01-023 dương · Kiểm thử kết nối ở SANDBOX
    Biết HTTT `APPROVED`, `provisionStage = SANDBOX_READY`; đầu mối đã nhận bàn giao hoặc đã đăng ký khóa
    Khi HTTT gọi điểm cuối sandbox của Datahub; tác vụ thu thập kết quả chạy mỗi 5 phút; hoặc người dùng bấm "Làm mới kết quả" ở UI-01-10
    Thì hệ thống trả `200`; `{ "authOk": true, "apiOk": false, "callCount": 2, "required": 3, "errors": [ { "code": "invalid_scope", "count": 4, "guidance": "…" } ], "readyToActivate": false }`
    Và bản ghi kiểm thử lưu 1 năm; cờ `readyToActivate` cập nhật

  @US-01-023 @FR-01-023 @M @âm
  Kịch bản: US-01-023 âm 1 · Thiếu dữ liệu nhật ký từ PH-13
    Biết HTTT `APPROVED`, `provisionStage = SANDBOX_READY`; đầu mối đã nhận bàn giao hoặc đã đăng ký khóa
    Khi thiếu dữ liệu nhật ký từ PH-13
    Thì hệ thống từ chối với ERR-01-046 (503)
    Và người dùng thấy thông báo "Chưa lấy được kết quả kiểm thử. Thử làm mới sau."

  @US-01-023 @FR-01-023 @M @âm
  Kịch bản: US-01-023 âm 2 · Kiểm thử chưa đạt
    Biết HTTT `APPROVED`, `provisionStage = SANDBOX_READY`; đầu mối đã nhận bàn giao hoặc đã đăng ký khóa
    Khi kiểm thử chưa đạt
    Thì hệ thống từ chối với ERR-01-031
    Và người dùng thấy thông báo "Kích hoạt"

  @US-01-024 @FR-01-024 @M
  Kịch bản: US-01-024 dương · Kích hoạt môi trường thật (PRODUCTION)
    Biết HTTT `APPROVED`, `readyToActivate = true`; có đầu mối `TECHNICAL` hoạt động; cấp độ ATTT vẫn đạt yêu cầu theo trần phạm vi
    Khi quản trị tỉnh bấm "Kích hoạt môi trường thật" ở UI-01-10
    Thì hệ thống trả `200`; `status = ACTIVE`, `activatedAt`, định danh PRODUCTION (không bí mật); nếu saga cấp định danh chưa xong sau 10 giây thì `202` kèm `progressUrl` tới `GET /systems/{systemCode}/provisioning` (API-01-036)
    Và `ACTIVE`; PH-02, PH-10, PH-04, PH-05 nhận sự kiện và cho HTTT tham gia
    Và sự kiện được phát: EVT-01-03, EVT-01-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-024 @FR-01-024 @M @âm
  Kịch bản: US-01-024 âm 1 · Kiểm thử SANDBOX chưa đạt
    Biết HTTT `APPROVED`, `readyToActivate = true`; có đầu mối `TECHNICAL` hoạt động; cấp độ ATTT vẫn đạt yêu cầu theo trần phạm vi
    Khi kiểm thử SANDBOX chưa đạt
    Thì hệ thống từ chối với ERR-01-031 (422)
    Và người dùng thấy thông báo "Chưa đủ lượt kiểm thử đạt ở môi trường thử. Xem kết quả và khắc phục."

  @US-01-024 @FR-01-024 @M @âm
  Kịch bản: US-01-024 âm 2 · Thiếu điều kiện (đầu mối, cấp độ ATTT)
    Biết HTTT `APPROVED`, `readyToActivate = true`; có đầu mối `TECHNICAL` hoạt động; cấp độ ATTT vẫn đạt yêu cầu theo trần phạm vi
    Khi thiếu điều kiện (đầu mối, cấp độ ATTT)
    Thì hệ thống từ chối với ERR-01-032 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện kích hoạt: {danh sách}."

  @US-01-025 @FR-01-025 @M
  Kịch bản: US-01-025 dương · Xoay vòng thông tin xác thực
    Biết định danh `ACTIVE`; không đang `ROTATING` (ERR-01-029)
    Khi người dùng bấm "Xoay vòng" ở UI-01-08; SO bấm "Buộc xoay" ở UI-01-11; hoặc nhắc hạn của hệ thống
    Thì hệ thống trả `200`; `status = ROTATING`, `rotationEndsAt`; bàn giao mới nếu `CLIENT_SECRET`
    Và `ROTATING` trong thời gian chuyển tiếp rồi `ACTIVE` với thông tin mới; thông tin cũ bị gỡ
    Và sự kiện được phát: EVT-01-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-025 @FR-01-025 @M @âm
  Kịch bản: US-01-025 âm 1 · Đang xoay vòng
    Biết định danh `ACTIVE`; không đang `ROTATING` (ERR-01-029)
    Khi đang xoay vòng
    Thì hệ thống từ chối với ERR-01-029 (409)
    Và người dùng thấy thông báo "Đang trong thời gian chuyển tiếp tới {thời điểm}. Kết thúc hoặc chờ hết hạn."

  @US-01-025 @FR-01-025 @M @âm
  Kịch bản: US-01-025 âm 2 · Định danh đã thu hồi hoặc hết hạn
    Biết định danh `ACTIVE`; không đang `ROTATING` (ERR-01-029)
    Khi định danh đã thu hồi hoặc hết hạn
    Thì hệ thống từ chối với ERR-01-030 (409)
    Và người dùng thấy thông báo "Định danh không còn dùng được. Cấp định danh mới."

  @US-01-026 @FR-01-026 @M
  Kịch bản: US-01-026 dương · Thu hồi định danh ứng dụng
    Biết định danh `ACTIVE`, `ROTATING` (hoặc `EXPIRED` để dọn)
    Khi người dùng bấm "Thu hồi" ở UI-01-08, hoặc FR-01-031, FR-01-032 gọi khi chấm dứt HTTT
    Thì hệ thống trả `200`; `status = REVOKED`, `enforcement = DONE / PENDING`
    Và `REVOKED`; consumer gỡ; bí mật hủy
    Và sự kiện được phát: EVT-01-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-026 @FR-01-026 @M @âm
  Kịch bản: US-01-026 âm 1 · Định danh đã thu hồi, hết hạn
    Biết định danh `ACTIVE`, `ROTATING` (hoặc `EXPIRED` để dọn)
    Khi định danh đã thu hồi, hết hạn
    Thì hệ thống từ chối với ERR-01-030 (409)

  @US-01-026 @FR-01-026 @M @âm
  Kịch bản: US-01-026 âm 2 · Thiếu lý do
    Biết định danh `ACTIVE`, `ROTATING` (hoặc `EXPIRED` để dọn)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nhập lý do thu hồi."

  @US-01-027 @FR-01-027 @M
  Kịch bản: US-01-027 dương · Nhắc hạn và tự hết hạn định danh
    Biết có định danh `ACTIVE` hoặc `ROTATING` với `expires_at`
    Khi tác vụ hằng ngày lúc 06:00 giờ Việt Nam (khóa ShedLock)
    Thì đầu mối biết trước khi định danh hết hạn; định danh quá hạn không còn dùng được
    Và định danh `EXPIRED` hoặc vẫn `ACTIVE` với nhắc đã gửi
    Và sự kiện được phát: EVT-01-07, EVT-01-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-027 @FR-01-027 @M @âm
  Kịch bản: US-01-027 âm 1 · Thư thông báo thất bại (địa chỉ không hoạt động)
    Biết có định danh `ACTIVE` hoặc `ROTATING` với `expires_at`
    Khi thư thông báo thất bại (địa chỉ không hoạt động)
    Thì hệ thống ghi nhận, nhắc TA và đánh dấu đầu mối thông báo (FR-01-046)
    Và người dùng thấy thông báo "Thư điện tử không hoạt động"

  @US-01-027 @FR-01-027 @M @âm
  Kịch bản: US-01-027 âm 2 · PH-12 không khả dụng lúc hết hạn
    Biết có định danh `ACTIVE` hoặc `ROTATING` với `expires_at`
    Khi PH-12 không khả dụng lúc hết hạn
    Thì định danh vẫn đặt `EXPIRED` ở PH-01, thử lại vô hiệu hóa theo lịch lùi (như FR-01-026)

  @US-01-028 @FR-01-028 @M
  Kịch bản: US-01-028 dương · Xem danh sách định danh của HTTT
    Biết HTTT có ít nhất một định danh (từ `APPROVED`)
    Khi người dùng mở tab "Ứng dụng và thông tin xác thực" của UI-01-04 hoặc màn UI-01-08
    Thì hệ thống trả `200`; `credentials[]` (không bí mật), `allowedActions[]`

  @US-01-028 @FR-01-028 @M @âm
  Kịch bản: US-01-028 âm 1 · Không thấy định danh hoặc HTTT thuộc tenant khác
    Biết HTTT có ít nhất một định danh (từ `APPROVED`)
    Khi không thấy định danh hoặc HTTT thuộc tenant khác
    Thì hệ thống từ chối với ERR-01-001 (404)

  # ---- EP-01-D · Vòng đời thành viên

  @US-01-029 @FR-01-029 @M
  Kịch bản: US-01-029 dương · Tạm ngừng HTTT
    Biết HTTT `ACTIVE`
    Khi người dùng bấm "Tạm ngừng" ở UI-01-04 hoặc UI-01-11; hoặc hệ thống tự gọi khi căn cứ hết hiệu lực (FR-01-043)
    Thì hệ thống trả `200`; `status = SUSPENDED`, `enforcement`, `suspendedAt`
    Và `SUSPENDED`; định danh, consumer vô hiệu nhưng giữ nguyên cấu hình; bên phát, bên nhận ở PH-10 tạm ngừng theo
    Và sự kiện được phát: EVT-01-03 (`ACTIVE → SUSPENDED`), EVT-01-07 (định danh vô hiệu tạm thời)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-029 @FR-01-029 @M @âm
  Kịch bản: US-01-029 âm 1 · Thiếu hoặc quá ngắn lý do
    Biết HTTT `ACTIVE`
    Khi thiếu hoặc quá ngắn lý do
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nhập lý do tạm ngừng (ít nhất 10 ký tự)."

  @US-01-029 @FR-01-029 @M @âm
  Kịch bản: US-01-029 âm 2 · Có HTTT khác phụ thuộc, hoặc HTTT thiết yếu
    Biết HTTT `ACTIVE`
    Khi có HTTT khác phụ thuộc, hoặc HTTT thiết yếu
    Thì hệ thống từ chối với ERR-01-034 (409)
    Và người dùng thấy thông báo "Có {n} đối tượng đang phụ thuộc hệ thống này. Xác nhận để tiếp tục."

  @US-01-030 @FR-01-030 @M
  Kịch bản: US-01-030 dương · Khôi phục HTTT
    Biết HTTT `SUSPENDED`; không có thao tác khẩn chờ xác nhận (FR-01-032); nếu HTTT bị tạm ngừng vì nghi lộ bí mật thì các định danh đã được xoay
    Khi người dùng bấm "Khôi phục" ở UI-01-11
    Thì hệ thống trả `200`; `status = ACTIVE`
    Và `ACTIVE`; định danh còn hạn bật lại; bên phát, bên nhận bị tạm ngừng theo PH-01 tiếp tục
    Và sự kiện được phát: EVT-01-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-030 @FR-01-030 @M @âm
  Kịch bản: US-01-030 âm 1 · TA khôi phục HTTT bị SO tạm ngừng vì nghi lộ bí mật khi chưa có đồng ý của SO
    Biết HTTT `SUSPENDED`; không có thao tác khẩn chờ xác nhận (FR-01-032); nếu HTTT bị tạm ngừng vì nghi lộ bí mật thì các định danh đã được xoay
    Khi TA khôi phục HTTT bị SO tạm ngừng vì nghi lộ bí mật khi chưa có đồng ý của SO
    Thì hệ thống từ chối với ERR-01-036 (409)
    Và người dùng thấy thông báo "HTTT bị tạm ngừng vì nghi lộ bí mật. Cần Cán bộ ATTT đồng ý."

  @US-01-030 @FR-01-030 @M @âm
  Kịch bản: US-01-030 âm 2 · Thiếu điều kiện
    Biết HTTT `SUSPENDED`; không có thao tác khẩn chờ xác nhận (FR-01-032); nếu HTTT bị tạm ngừng vì nghi lộ bí mật thì các định danh đã được xoay
    Khi thiếu điều kiện
    Thì hệ thống từ chối với ERR-01-032 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện khôi phục: {danh sách}."

  @US-01-031 @FR-01-031 @M
  Kịch bản: US-01-031 dương · Chấm dứt tư cách thành viên
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi người dùng bấm "Chấm dứt" ở UI-01-11
    Thì hệ thống trả `201` (tạo đề nghị); `200` khi duyệt: `status = TERMINATED`
    Và `TERMINATED`, định danh `REVOKED`, consumer gỡ, dịch vụ ngừng; lịch sử và bằng chứng còn tra được
    Và sự kiện được phát: EVT-01-03, EVT-01-07, EVT-01-11 (trần phạm vi về rỗng)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-031 @FR-01-031 @M @âm
  Kịch bản: US-01-031 âm 1 · Còn phụ thuộc chưa xác nhận
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi còn phụ thuộc chưa xác nhận
    Thì hệ thống từ chối với ERR-01-034 (409)
    Và người dùng thấy thông báo "Có {n} đối tượng phụ thuộc. Xem danh sách và xác nhận."

  @US-01-031 @FR-01-031 @M @âm
  Kịch bản: US-01-031 âm 2 · Người duyệt trùng người đề nghị
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-01-017 (403)
    Và người dùng thấy thông báo "Anh/chị đã đề nghị nên không duyệt được. Nhờ quản trị khác."

  @US-01-032 @FR-01-032 @M
  Kịch bản: US-01-032 dương · Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi SO bấm "Xử lý khẩn" ở UI-01-11; hoặc theo playbook sự cố của D03-07
    Thì hệ thống trả `200`; `{ "actionId", "status": "SUSPENDED", "confirmBy", "enforcement" }`
    Và HTTT `SUSPENDED` hoặc `TERMINATED`; thao tác khẩn ở `PENDING_CONFIRM`, `CONFIRMED` hoặc `OVERDUE`
    Và sự kiện được phát: EVT-01-15, EVT-01-03, EVT-01-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-032 @FR-01-032 @M @âm
  Kịch bản: US-01-032 âm 1 · Thiếu lý do
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nhập lý do xử lý khẩn."

  @US-01-032 @FR-01-032 @M @âm
  Kịch bản: US-01-032 âm 2 · Xác nhận lần hai hoặc quá hạn đã đóng
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi xác nhận lần hai hoặc quá hạn đã đóng
    Thì hệ thống từ chối với ERR-01-036 (409)
    Và người dùng thấy thông báo "Thao tác khẩn này đã được xử lý."

  @US-01-033 @FR-01-033 @M
  Kịch bản: US-01-033 dương · Phân tích tác động phụ thuộc trước khi tạm ngừng, chấm dứt
    Biết HTTT tồn tại và chưa `TERMINATED`
    Khi người dùng bấm "Phân tích tác động" ở UI-01-11, hoặc FR-01-029, FR-01-031 gọi tự động
    Thì hệ thống trả `200`; `{ "impactLevel": "MEDIUM", "partial": false, "dependents": [ { "type": "SUBSCRIPTION", "ref": "…", "orgContact": "…" } ] }`

  @US-01-033 @FR-01-033 @M @âm
  Kịch bản: US-01-033 âm 1 · Phân hệ khác không khả dụng
    Biết HTTT tồn tại và chưa `TERMINATED`
    Khi phân hệ khác không khả dụng
    Thì hệ thống từ chối với ERR-01-046
    Và người dùng thấy thông báo "Chưa lấy được dữ liệu từ {phân hệ}; danh sách có thể thiếu."

  @US-01-034 @FR-01-034 @S
  Kịch bản: US-01-034 dương · Đề nghị thay đổi hồ sơ HTTT đã kết nạp theo mức duyệt
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi người dùng bấm "Sửa" ở UI-01-04
    Thì hệ thống trả `200` (áp dụng ngay, mức `NONE`) hoặc `202` (chờ duyệt, kèm `changeRequest{id, class, status}`)
    Và hồ sơ đổi (mức `NONE`) hoặc yêu cầu thay đổi `PENDING`
    Và sự kiện được phát: EVT-01-04 (khi áp dụng)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-034 @FR-01-034 @S @âm
  Kịch bản: US-01-034 âm 1 · Đang có yêu cầu thay đổi chờ duyệt
    Biết HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`
    Khi đang có yêu cầu thay đổi chờ duyệt
    Thì hệ thống từ chối với ERR-01-038 (409)
    Và người dùng thấy thông báo "Đã có thay đổi chờ duyệt. Chờ quyết định trước khi gửi thay đổi mới."

  @US-01-035 @FR-01-035 @M
  Kịch bản: US-01-035 dương · Đề nghị mở rộng trần phạm vi khai thác
    Biết HTTT `ACTIVE` hoặc `SUSPENDED`; không có đề nghị mở rộng đang chờ
    Khi người dùng bấm "Đề nghị mở rộng phạm vi" ở UI-01-04; hoặc đăng ký sử dụng ở PH-02 vượt trần và người dùng chọn xin mở rộng
    Thì hệ thống trả `202`; `changeRequest{id, class = FULL, status}`
    Và yêu cầu `FULL` chờ thẩm định; khi duyệt, trần phạm vi cập nhật
    Và sự kiện được phát: EVT-01-11 (khi duyệt)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-035 @FR-01-035 @M @âm
  Kịch bản: US-01-035 âm 1 · Mục thiếu căn cứ
    Biết HTTT `ACTIVE` hoặc `SUSPENDED`; không có đề nghị mở rộng đang chờ
    Khi mục thiếu căn cứ
    Thì hệ thống từ chối với ERR-01-015, ERR-01-016, ERR-01-047 (422)

  @US-01-035 @FR-01-035 @M @âm
  Kịch bản: US-01-035 âm 2 · Đã có đề nghị mở rộng đang chờ
    Biết HTTT `ACTIVE` hoặc `SUSPENDED`; không có đề nghị mở rộng đang chờ
    Khi đã có đề nghị mở rộng đang chờ
    Thì hệ thống từ chối với ERR-01-038 (409)

  @US-01-036 @FR-01-036 @S
  Kịch bản: US-01-036 dương · Tự tạm ngừng định danh không hoạt động
    Biết định danh PRODUCTION `ACTIVE` có `last_used_at` (nhận từ PH-13)
    Khi tác vụ hằng ngày lúc 06:30 (khóa ShedLock)
    Thì báo cáo lượt chạy; bật lại `200`
    Và định danh `disabled` hoặc không đổi
    Và sự kiện được phát: EVT-01-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-036 @FR-01-036 @S @âm
  Kịch bản: US-01-036 âm 1 · PH-13 không khả dụng
    Biết định danh PRODUCTION `ACTIVE` có `last_used_at` (nhận từ PH-13)
    Khi PH-13 không khả dụng
    Thì bỏ qua lượt chạy, không tạm ngừng (tránh tạm ngừng nhầm); cảnh báo vận hành

  @US-01-037 @FR-01-037 @M
  Kịch bản: US-01-037 dương · Đồng bộ trạng thái HTTT tới phân hệ khác
    Biết một thay đổi trạng thái, thuộc tính hoặc đầu mối của HTTT xảy ra
    Khi mỗi chuyển trạng thái (cùng giao dịch ghi outbox); tác vụ đối chiếu hằng giờ
    Thì sự kiện EVT-01-03, EVT-01-04, EVT-01-11; ảnh chụp theo lô
    Và bản sao ở phân hệ khác khớp PH-01 sau tối đa 1 giờ
    Và sự kiện được phát: EVT-01-03, EVT-01-04, EVT-01-11

  @US-01-037 @FR-01-037 @M @âm
  Kịch bản: US-01-037 âm 1 · Kafka không khả dụng
    Biết một thay đổi trạng thái, thuộc tính hoặc đầu mối của HTTT xảy ra
    Khi Kafka không khả dụng
    Thì outbox giữ sự kiện, phát lại khi Kafka trở lại; cảnh báo PH-13 khi hàng đợi outbox > 60 giây

  @US-01-037 @FR-01-037 @M @âm
  Kịch bản: US-01-037 âm 2 · Phân hệ tiêu thụ không xử lý được
    Biết một thay đổi trạng thái, thuộc tính hoặc đầu mối của HTTT xảy ra
    Khi phân hệ tiêu thụ không xử lý được
    Thì sự kiện vào hàng đợi lỗi của phân hệ đó (PH-18); PH-01 không bị chặn

  @US-01-038 @FR-01-038 @M
  Kịch bản: US-01-038 dương · Cung cấp bản sao đọc HTTT cho phân hệ khác
    Biết phân hệ gọi có token dịch vụ với scope phù hợp
    Khi phân hệ khác gọi API nội bộ (kiểm tra khi lưu, khi đối chiếu); hoặc khởi tạo bản sao lần đầu
    Thì hệ thống trả `200`; `items[]` rút gọn; `nextUpdatedSince`

  @US-01-038 @FR-01-038 @M @âm
  Kịch bản: US-01-038 âm 1 · Token thiếu scope
    Biết phân hệ gọi có token dịch vụ với scope phù hợp
    Khi token thiếu scope
    Thì `403`; không có mã ERR riêng (lỗi xác thực dùng chung theo FR-00-080)

  @US-01-038 @FR-01-038 @M @âm
  Kịch bản: US-01-038 âm 2 · Không thấy HTTT
    Biết phân hệ gọi có token dịch vụ với scope phù hợp
    Khi không thấy HTTT
    Thì hệ thống từ chối với ERR-01-001 (404)

  # ---- EP-01-E · Rà soát quyền định kỳ

  @US-01-039 @FR-01-039 @M
  Kịch bản: US-01-039 dương · Mở kỳ rà soát quyền định kỳ
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tác vụ lịch (mỗi `accessReview.intervalMonths` tháng, mặc định 6) hoặc người dùng bấm "Mở kỳ rà soát" ở UI-01-12
    Thì hệ thống trả `201`; `cycleCode`, `itemCount`, `status = OPEN`
    Và kỳ `OPEN` với các mục sinh ra
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-039 @FR-01-039 @M @âm
  Kịch bản: US-01-039 âm 1 · Đã có kỳ đang mở
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi đã có kỳ đang mở
    Thì hệ thống từ chối với ERR-01-039 (409)
    Và người dùng thấy thông báo "Kỳ rà soát {mã} đang mở. Hoàn tất hoặc đóng kỳ đó trước."

  @US-01-039 @FR-01-039 @M @âm
  Kịch bản: US-01-039 âm 2 · Chu kỳ ngoài miền cho phép
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi chu kỳ ngoài miền cho phép
    Thì hệ thống từ chối với ERR-01-044 (422)

  @US-01-040 @FR-01-040 @M
  Kịch bản: US-01-040 dương · Tổng hợp mức sử dụng từng phạm vi
    Biết kỳ rà soát `OPEN` có mục chưa tổng hợp
    Khi ngay sau khi mở kỳ (FR-01-039), và khi người dùng bấm "Làm mới số liệu"
    Thì hệ thống trả `200`; `items[]`: `systemCode`, `dataType`, `scopeApproved`, `usageInPeriod`, `unusedDays`, `flags[]`, `proposal`
    Và mục có số liệu và đề xuất

  @US-01-040 @FR-01-040 @M @âm
  Kịch bản: US-01-040 âm 1 · PH-13 hoặc PH-02 không khả dụng
    Biết kỳ rà soát `OPEN` có mục chưa tổng hợp
    Khi PH-13 hoặc PH-02 không khả dụng
    Thì hệ thống từ chối với ERR-01-046 (503)
    Và người dùng thấy thông báo "Chưa có số liệu"

  @US-01-041 @FR-01-041 @M
  Kịch bản: US-01-041 dương · Gửi xác nhận cho đơn vị chủ quản và theo dõi phản hồi
    Biết kỳ `OPEN` đã có số liệu (FR-01-040)
    Khi người dùng bấm "Gửi xác nhận" ở UI-01-12; tác vụ nhắc hằng ngày
    Thì gửi: `202`, số phiếu đã gửi
    Và mỗi mục có `ownerResponse` hoặc cờ "chưa phản hồi"
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-041 @FR-01-041 @M @âm
  Kịch bản: US-01-041 âm 1 · Liên kết hết hạn hoặc đã trả lời
    Biết kỳ `OPEN` đã có số liệu (FR-01-040)
    Khi liên kết hết hạn hoặc đã trả lời
    Thì hệ thống từ chối với ERR-01-040 (410)
    Và người dùng thấy thông báo "Phiếu xác nhận đã hết hạn hoặc đã được trả lời. Liên hệ quản trị tỉnh."

  @US-01-041 @FR-01-041 @M @âm
  Kịch bản: US-01-041 âm 2 · Người mở không thuộc tổ chức
    Biết kỳ `OPEN` đã có số liệu (FR-01-040)
    Khi người mở không thuộc tổ chức
    Thì hệ thống từ chối với ERR-01-025 (403)
    Và người dùng thấy thông báo "Tài khoản này không thuộc tổ chức được hỏi."

  @US-01-042 @FR-01-042 @M
  Kịch bản: US-01-042 dương · Xử lý kết quả rà soát: thu hẹp, thu hồi phạm vi
    Biết kỳ `DECIDING`
    Khi người dùng chọn một hoặc nhiều mục ở UI-01-12 rồi bấm "Thu hồi phạm vi" hoặc "Thu hẹp" hoặc "Giữ"
    Thì hệ thống trả `200`; `decisions[]`, số mục đã thu hồi, thu hẹp, giữ
    Và trần phạm vi cập nhật; kỳ `CLOSED` khi xong
    Và sự kiện được phát: EVT-01-11, EVT-01-12 (khi đóng kỳ)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-042 @FR-01-042 @M @âm
  Kịch bản: US-01-042 âm 1 · Thiếu lý do
    Biết kỳ `DECIDING`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nhập lý do cho quyết định."

  @US-01-042 @FR-01-042 @M @âm
  Kịch bản: US-01-042 âm 2 · Quyết định không hợp lệ (ví dụ giữ mục có căn cứ đã hết hiệu lực)
    Biết kỳ `DECIDING`
    Khi quyết định không hợp lệ (ví dụ giữ mục có căn cứ đã hết hiệu lực)
    Thì hệ thống từ chối với ERR-01-041 (422)
    Và người dùng thấy thông báo "Không giữ được mục có căn cứ hết hiệu lực. Chọn thu hồi hoặc bổ sung căn cứ ở Đề nghị mở rộng."

  @US-01-043 @FR-01-043 @M
  Kịch bản: US-01-043 dương · Kiểm tra hiệu lực căn cứ pháp lý
    Biết mục trần phạm vi có `validUntil` hoặc được đánh dấu bãi bỏ
    Khi tác vụ hằng ngày lúc 05:30; khi mở kỳ rà soát; khi người dùng đánh dấu "Văn bản đã bị bãi bỏ"
    Thì báo cáo lượt chạy: số mục tạm ngừng, số nhắc đã gửi
    Và mục trần `SUSPENDED`, đăng ký sử dụng liên quan tạm ngừng
    Và sự kiện được phát: EVT-01-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-043 @FR-01-043 @M @âm
  Kịch bản: US-01-043 âm 1 · Mục đã `SUSPENDED` hoặc `REVOKED`
    Biết mục trần phạm vi có `validUntil` hoặc được đánh dấu bãi bỏ
    Khi mục đã `SUSPENDED` hoặc `REVOKED`
    Thì bỏ qua, không phát lại sự kiện

  @US-01-043 @FR-01-043 @M @âm
  Kịch bản: US-01-043 âm 2 · Đánh dấu bãi bỏ thiếu số hiệu hoặc ngày
    Biết mục trần phạm vi có `validUntil` hoặc được đánh dấu bãi bỏ
    Khi đánh dấu bãi bỏ thiếu số hiệu hoặc ngày
    Thì hệ thống từ chối với ERR-01-003 (400)
    Và người dùng thấy thông báo "Nhập số hiệu và ngày văn bản bị bãi bỏ."

  @US-01-044 @FR-01-044 @S
  Kịch bản: US-01-044 dương · Báo cáo rà soát quyền
    Biết có kỳ rà soát đã `CLOSED`
    Khi người dùng bấm "Báo cáo" ở UI-01-12
    Thì hệ thống trả `200`, tệp báo cáo; hoặc `202` kèm tác vụ nền tra bằng API-01-088
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-044 @FR-01-044 @S @âm
  Kịch bản: US-01-044 âm 1 · Kỳ chưa đóng
    Biết có kỳ rà soát đã `CLOSED`
    Khi kỳ chưa đóng
    Thì hệ thống từ chối với ERR-01-020 (409)
    Và người dùng thấy thông báo "Kỳ rà soát chưa hoàn tất, báo cáo chỉ có khi kỳ đã đóng."

  # ---- EP-01-F · Danh bạ đầu mối

  @US-01-045 @FR-01-045 @M
  Kịch bản: US-01-045 dương · Tra cứu danh bạ đầu mối trong phạm vi cơ quan nhà nước
    Biết người dùng đã đăng nhập, chọn tenant; thuộc một tổ chức của tenant
    Khi người dùng mở menu Kết nối & API › Danh bạ đầu mối; hoặc phân hệ khác gọi API tra đầu mối
    Thì hệ thống trả `200`; `items[]`: `fullName`, `position`, `phone`, `email`, `orgName`, `systemName`, `contactType`, `lastConfirmedAt`; phân trang

  @US-01-045 @FR-01-045 @M @âm
  Kịch bản: US-01-045 âm 1 · Vượt giới hạn tra cứu
    Biết người dùng đã đăng nhập, chọn tenant; thuộc một tổ chức của tenant
    Khi vượt giới hạn tra cứu
    Thì hệ thống từ chối với ERR-01-045 (429)
    Và người dùng thấy thông báo "Bạn tra cứu quá nhanh. Thử lại sau {n} giây."

  @US-01-045 @FR-01-045 @M @âm
  Kịch bản: US-01-045 âm 2 · Không thấy tổ chức
    Biết người dùng đã đăng nhập, chọn tenant; thuộc một tổ chức của tenant
    Khi không thấy tổ chức
    Thì hệ thống từ chối với ERR-01-001 (404)

  @US-01-046 @FR-01-046 @M
  Kịch bản: US-01-046 dương · Cảnh báo tổ chức thiếu đầu mối và nhắc cập nhật
    Biết tenant có ít nhất một HTTT `ACTIVE`
    Khi tác vụ hằng ngày lúc 06:15; sự kiện PH-12 tài khoản đầu mối bị vô hiệu hoặc chuyển tổ chức; sự kiện PH-18 thư gửi đầu mối bị trả lại
    Thì báo cáo lượt chạy; danh sách "Cần xử lý" ở UI-01-14
    Và đầu mối `INACTIVE` hoặc gắn cờ; tổ chức vi phạm bị chặn kết nạp mới
    Và sự kiện được phát: EVT-01-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-046 @FR-01-046 @M @âm
  Kịch bản: US-01-046 âm 1 · PH-12, PH-18 không khả dụng
    Biết tenant có ít nhất một HTTT `ACTIVE`
    Khi PH-12, PH-18 không khả dụng
    Thì bỏ qua nguồn đó trong lượt chạy, ghi nhật ký; không đánh dấu nhầm

  @US-01-046 @FR-01-046 @M @âm
  Kịch bản: US-01-046 âm 2 · Bỏ đầu mối kỹ thuật cuối cùng
    Biết tenant có ít nhất một HTTT `ACTIVE`
    Khi bỏ đầu mối kỹ thuật cuối cùng
    Thì hệ thống từ chối với ERR-01-050 (409)

  @US-01-047 @FR-01-047 @C
  Kịch bản: US-01-047 dương · Xuất danh bạ đầu mối
    Biết người dùng đã đăng nhập; có quyền xuất
    Khi người dùng bấm "Xuất" ở UI-01-14
    Thì hệ thống trả `200` tệp, hoặc `202` kèm tác vụ nền tra bằng API-01-088
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-047 @FR-01-047 @C @âm
  Kịch bản: US-01-047 âm 1 · Thiếu mục đích
    Biết người dùng đã đăng nhập; có quyền xuất
    Khi thiếu mục đích
    Thì hệ thống từ chối với ERR-01-033 (400)
    Và người dùng thấy thông báo "Nhập mục đích sử dụng bản xuất."

  # ---- EP-01-G · Di trú và quản trị

  @US-01-048 @FR-01-048 @M
  Kịch bản: US-01-048 dương · Nhập HTTT từ hệ cũ
    Biết có tệp xuất từ hệ cũ (CSV, XLSX hoặc JSON) của danh sách Application, publisher, subscriber; tổ chức của tenant đã có ở PH-20
    Khi người dùng bấm "Nhập từ hệ cũ" ở UI-01-15
    Thì hệ thống trả `201`; `{ "jobId", "created": 118, "skipped": 4, "warnings": 6, "secretsDropped": 120 }`
    Và hồ sơ `DRAFT` gắn `legacy_ref`; tác vụ nhập `DONE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-048 @FR-01-048 @M @âm
  Kịch bản: US-01-048 âm 1 · Tệp sai cấu trúc hoặc thiếu cột bắt buộc
    Biết có tệp xuất từ hệ cũ (CSV, XLSX hoặc JSON) của danh sách Application, publisher, subscriber; tổ chức của tenant đã có ở PH-20
    Khi tệp sai cấu trúc hoặc thiếu cột bắt buộc
    Thì hệ thống từ chối với ERR-01-042 (400)
    Và người dùng thấy thông báo "Tệp không đúng mẫu. Tải mẫu nhập và thử lại."

  @US-01-048 @FR-01-048 @M @âm
  Kịch bản: US-01-048 âm 2 · Bản ghi trùng HTTT đã có
    Biết có tệp xuất từ hệ cũ (CSV, XLSX hoặc JSON) của danh sách Application, publisher, subscriber; tổ chức của tenant đã có ở PH-20
    Khi bản ghi trùng HTTT đã có
    Thì hệ thống từ chối với ERR-01-043 (409)

  @US-01-049 @FR-01-049 @M
  Kịch bản: US-01-049 dương · Tham số phân hệ theo tenant
    Biết người dùng có quyền
    Khi người dùng mở UI-01-16, sửa một tham số, bấm "Lưu"
    Thì hệ thống trả `200`; tham số đã cập nhật kèm `version`
    Và giá trị mới có hiệu lực sau tối đa 60 giây
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-049 @FR-01-049 @M @âm
  Kịch bản: US-01-049 âm 1 · Giá trị ngoài miền
    Biết người dùng có quyền
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-01-044 (422)
    Và người dùng thấy thông báo "Giá trị {khóa} phải từ {min} đến {max}."

  @US-01-049 @FR-01-049 @M @âm
  Kịch bản: US-01-049 âm 2 · Thiếu lý do
    Biết người dùng có quyền
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-01-033 (400)

  @US-01-050 @FR-01-050 @S
  Kịch bản: US-01-050 dương · Xuất danh sách HTTT thành viên
    Biết người dùng đã đăng nhập; danh sách hiện hành có dữ liệu
    Khi người dùng bấm "Xuất CSV" hoặc "Xuất Excel" ở UI-01-03
    Thì hệ thống trả `200` tệp; hoặc `202` kèm mã công việc, tra bằng API-01-088
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-01-050 @FR-01-050 @S @âm
  Kịch bản: US-01-050 âm 1 · Không có dòng nào khớp
    Biết người dùng đã đăng nhập; danh sách hiện hành có dữ liệu
    Khi không có dòng nào khớp
    Thì `204`; thông báo
    Và người dùng thấy thông báo "Không có dữ liệu để xuất."

  @US-01-051 @FR-01-051 @S
  Kịch bản: US-01-051 dương · Thống kê kết nạp và thời gian xử lý
    Biết có dữ liệu kết nạp trong khoảng thời gian chọn
    Khi người dùng mở UI-01-17
    Thì hệ thống trả `200`; `byStatus`, `stageDurations{median, p90}`, `endToEnd{median, p90, kpi05Met}`, `returnRate`, `backlog`, chuỗi tuần

  @US-01-051 @FR-01-051 @S @âm
  Kịch bản: US-01-051 âm 1 · Khoảng thời gian không hợp lệ (`from` sau `to`)
    Biết có dữ liệu kết nạp trong khoảng thời gian chọn
    Khi khoảng thời gian không hợp lệ (`from` sau `to`)
    Thì hệ thống từ chối với ERR-01-003 (400)
    Và người dùng thấy thông báo "Khoảng thời gian không hợp lệ."
