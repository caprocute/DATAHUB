# language: vi
# Sinh tự động từ D02-02/D02-03-PH06 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-06
Tính năng: PH-06 · Dữ liệu chủ

  # ---- EP-06-A · Mô hình domain dữ liệu chủ

  @US-06-001 @FR-06-001 @M
  Kịch bản: US-06-001 dương · Liệt kê và xem domain dữ liệu chủ
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi mở UI-06-07 hoặc gọi API-06-001
    Thì hệ thống trả `200`; `items[]` gồm `domainCode`, `name`, `status`, `activeVersion`, `attributeCount`, `goldenCount`; chi tiết có `attributes[]`, `identifiers[]`, `schemaUrl`, `versions[]`, `ETag`

  @US-06-001 @FR-06-001 @M @âm
  Kịch bản: US-06-001 âm 1 · Không có domain hoặc domain thuộc tenant khác
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi không có domain hoặc domain thuộc tenant khác
    Thì hệ thống từ chối với ERR-06-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy domain {mã} trong tỉnh đang làm việc."

  @US-06-001 @FR-06-001 @M @âm
  Kịch bản: US-06-001 âm 2 · Tham số sai miền
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi tham số sai miền
    Thì hệ thống từ chối với ERR-06-047 (422)
    Và người dùng thấy thông báo "Tham số {tên} không hợp lệ: {chi tiết}."

  @US-06-002 @FR-06-002 @M
  Kịch bản: US-06-002 dương · Soạn mô hình domain với thuộc tính có kiểu
    Biết domain chưa có bản nháp khác đang mở (một domain một bản nháp)
    Khi bấm "Tạo bản nháp" ở UI-06-07 (từ phiên bản `ACTIVE`) hoặc "+ Domain mới"
    Thì hệ thống trả `201` (tạo) hoặc `200` (sửa); bản nháp, `ETag`, `schemaPreview`
    Và phiên bản `ACTIVE` không đổi; pipeline vẫn kiểm bản ghi theo phiên bản cũ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-002 @FR-06-002 @M @âm
  Kịch bản: US-06-002 âm 1 · Tên thuộc tính trùng
    Biết domain chưa có bản nháp khác đang mở (một domain một bản nháp)
    Khi tên thuộc tính trùng
    Thì hệ thống từ chối với ERR-06-002 (409)
    Và người dùng thấy thông báo "Thuộc tính {tên} đã có trong domain."

  @US-06-002 @FR-06-002 @M @âm
  Kịch bản: US-06-002 âm 2 · Danh mục tham chiếu không tồn tại hoặc chưa phát hành
    Biết domain chưa có bản nháp khác đang mở (một domain một bản nháp)
    Khi danh mục tham chiếu không tồn tại hoặc chưa phát hành
    Thì hệ thống từ chối với ERR-06-003 (400)
    Và người dùng thấy thông báo "Danh mục {mã} chưa phát hành ở PH-07."

  @US-06-003 @FR-06-003 @M
  Kịch bản: US-06-003 dương · Khai báo khóa định danh và quy tắc kiểm tra
    Biết bản nháp `DRAFT` của domain
    Khi tab "Khóa định danh" của UI-06-07; nút "Thử kiểm tra"
    Thì hệ thống trả `200`; danh sách khóa; với thử: `results[]` gồm `value` (đã che, giữ 3 số cuối), `verdict`, `reason`
    Và khóa có hiệu lực khi phiên bản được kích hoạt (FR-06-006)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-003 @FR-06-003 @M @âm
  Kịch bản: US-06-003 âm 1 · Thuộc tính không phải `IDENTIFIER`
    Biết bản nháp `DRAFT` của domain
    Khi thuộc tính không phải `IDENTIFIER`
    Thì hệ thống từ chối với ERR-06-009 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} phải có kiểu Định danh để làm khóa."

  @US-06-003 @FR-06-003 @M @âm
  Kịch bản: US-06-003 âm 2 · Biểu thức không an toàn hoặc sai cú pháp
    Biết bản nháp `DRAFT` của domain
    Khi biểu thức không an toàn hoặc sai cú pháp
    Thì hệ thống từ chối với ERR-06-003 (400)
    Và người dùng thấy thông báo "Biểu thức kiểm tra không hợp lệ hoặc có nguy cơ chạy quá lâu."

  @US-06-004 @FR-06-004 @M
  Kịch bản: US-06-004 dương · Gán phân loại dữ liệu cho thuộc tính theo PH-09
    Biết bản nháp `DRAFT`; PH-09 có danh mục DD-08
    Khi cột "Phân loại" ở UI-06-07; gửi duyệt (FR-06-006) kiểm lại
    Thì hệ thống trả `200`; thuộc tính kèm `dataClass`, `classificationStatus` (`PROPOSED`, `CONFIRMED`)
    Và phân loại là đầu vào của FR-06-052 (che) và FR-06-057 (nhật ký)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-004 @FR-06-004 @M @âm
  Kịch bản: US-06-004 âm 1 · Thuộc tính DLCN chưa phân loại
    Biết bản nháp `DRAFT`; PH-09 có danh mục DD-08
    Khi thuộc tính DLCN chưa phân loại
    Thì hệ thống từ chối với ERR-06-010 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} là dữ liệu cá nhân nhưng chưa có phân loại được PH-09 xác nhận."

  @US-06-004 @FR-06-004 @M @âm
  Kịch bản: US-06-004 âm 2 · PH-09 không khả dụng
    Biết bản nháp `DRAFT`; PH-09 có danh mục DD-08
    Khi PH-09 không khả dụng
    Thì hệ thống từ chối với ERR-06-021 (503)
    Và người dùng thấy thông báo "Chưa kết nối được phân hệ Quyền riêng tư. Lưu nháp được, gửi duyệt sau."

  @US-06-005 @FR-06-005 @S
  Kịch bản: US-06-005 dương · Quản lý phiên bản mô hình và kiểm tra tương thích
    Biết domain có ít nhất hai phiên bản
    Khi tab "Phiên bản" của UI-06-07, chọn hai phiên bản, bấm "So sánh"
    Thì hệ thống trả `200`; `changes[]` (`path`, `kind`, `before`, `after`, `compat`), `affectedSources[]`, `affectedGoldenCount`

  @US-06-005 @FR-06-005 @S @âm
  Kịch bản: US-06-005 âm 1 · Phiên bản không tồn tại
    Biết domain có ít nhất hai phiên bản
    Khi phiên bản không tồn tại
    Thì hệ thống từ chối với ERR-06-001 (404)
    Và người dùng thấy thông báo "Không có phiên bản {n} của domain {mã}."

  @US-06-006 @FR-06-006 @M
  Kịch bản: US-06-006 dương · Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain
    Biết bản nháp qua kiểm tra FR-06-002…004; domain `ACTIVE` hoặc `DRAFT` (domain mới)
    Khi nút "Gửi duyệt" ở UI-06-07; DA xử lý ở "Việc của tôi" (FR-00-070)
    Thì hệ thống trả `200`; phiên bản kèm `status`, `approvedBy`, `activatedAt`
    Và một domain đúng một phiên bản `ACTIVE`
    Và sự kiện được phát: EVT-06-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-006 @FR-06-006 @M @âm
  Kịch bản: US-06-006 âm 1 · Tự duyệt
    Biết bản nháp qua kiểm tra FR-06-002…004; domain `ACTIVE` hoặc `DRAFT` (domain mới)
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-06-005 (403)
    Và người dùng thấy thông báo "Anh/chị là người gửi duyệt nên không được tự duyệt."

  @US-06-006 @FR-06-006 @M @âm
  Kịch bản: US-06-006 âm 2 · Từ chối không lý do
    Biết bản nháp qua kiểm tra FR-06-002…004; domain `ACTIVE` hoặc `DRAFT` (domain mới)
    Khi từ chối không lý do
    Thì hệ thống từ chối với ERR-06-007 (422)
    Và người dùng thấy thông báo "Nhập lý do từ chối (tối thiểu 20 ký tự)."

  @US-06-007 @FR-06-007 @M
  Kịch bản: US-06-007 dương · Nạp gói domain nền CITIZEN, ORGANIZATION, ADDRESS
    Biết tenant `ACTIVE`; PH-07 đã nạp danh mục nền (ĐVHC, giới tính, dân tộc, quốc tịch)
    Khi sự kiện khởi tạo tenant của PH-20 hoặc PA bấm "Nạp gói nền" ở UI-06-07
    Thì hệ thống trả `200`; `installed[]`, `skipped[]`, `followUpTasks[]`
    Và ba domain `ACTIVE`; bộ quy tắc, sống sót `DRAFT`
    Và sự kiện được phát: EVT-06-10 cho từng domain được tạo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-007 @FR-06-007 @M @âm
  Kịch bản: US-06-007 âm 1 · PH-07 thiếu danh mục tham chiếu
    Biết tenant `ACTIVE`; PH-07 đã nạp danh mục nền (ĐVHC, giới tính, dân tộc, quốc tịch)
    Khi PH-07 thiếu danh mục tham chiếu
    Thì hệ thống từ chối với ERR-06-003 (400)
    Và người dùng thấy thông báo "Thiếu danh mục {mã} ở PH-07. Nạp gói danh mục nền trước."

  @US-06-007 @FR-06-007 @M @âm
  Kịch bản: US-06-007 âm 2 · Phiên bản gói không tồn tại
    Biết tenant `ACTIVE`; PH-07 đã nạp danh mục nền (ĐVHC, giới tính, dân tộc, quốc tịch)
    Khi phiên bản gói không tồn tại
    Thì hệ thống từ chối với ERR-06-001 (404)
    Và người dùng thấy thông báo "Không có gói domain nền phiên bản {n}."

  # ---- EP-06-B · Nguồn và nạp bản ghi ứng viên

  @US-06-008 @FR-06-008 @M
  Kịch bản: US-06-008 dương · Đăng ký nguồn dữ liệu chủ gắn HTTT
    Biết HTTT `ACTIVE` ở PH-01 (trừ loại `NATIONAL_DB` gắn kết nối PH-14 và loại `MANUAL_ENTRY`)
    Khi "+ Thêm nguồn" ở UI-06-08
    Thì hệ thống trả `201`; nguồn kèm `status`, `trustLevel`, `channels[]`, `Location`
    Và nguồn `DRAFT`; scope và subscription ở trạng thái đề nghị
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-008 @FR-06-008 @M @âm
  Kịch bản: US-06-008 âm 1 · HTTT không hoạt động
    Biết HTTT `ACTIVE` ở PH-01 (trừ loại `NATIONAL_DB` gắn kết nối PH-14 và loại `MANUAL_ENTRY`)
    Khi HTTT không hoạt động
    Thì hệ thống từ chối với ERR-06-012 (422)
    Và người dùng thấy thông báo "HTTT {mã} chưa ở trạng thái hoạt động trong danh mục HTTT."

  @US-06-008 @FR-06-008 @M @âm
  Kịch bản: US-06-008 âm 2 · Mã nguồn đã dùng
    Biết HTTT `ACTIVE` ở PH-01 (trừ loại `NATIONAL_DB` gắn kết nối PH-14 và loại `MANUAL_ENTRY`)
    Khi mã nguồn đã dùng
    Thì hệ thống từ chối với ERR-06-002 (409)
    Và người dùng thấy thông báo "Mã nguồn {mã} đã được dùng."

  @US-06-009 @FR-06-009 @M
  Kịch bản: US-06-009 dương · Khai báo mức tin cậy và thứ tự ưu tiên nguồn có phê duyệt
    Biết domain `ACTIVE`; nguồn `DRAFT` hoặc `ACTIVE`
    Khi tab "Ưu tiên nguồn" ở UI-06-08: kéo thả thứ tự, bấm "Đề nghị áp dụng"
    Thì hệ thống trả `202`; đề nghị kèm `impactPreview`; sau duyệt `200` bảng ưu tiên hiện hành
    Và bảng ưu tiên cũ lưu lịch sử; sống sót dùng bảng mới cho mọi cập nhật sau thời điểm duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-009 @FR-06-009 @M @âm
  Kịch bản: US-06-009 âm 1 · Thiếu căn cứ phê duyệt
    Biết domain `ACTIVE`; nguồn `DRAFT` hoặc `ACTIVE`
    Khi thiếu căn cứ phê duyệt
    Thì hệ thống từ chối với ERR-06-013 (422)
    Và người dùng thấy thông báo "Nhập số, ngày văn bản phê duyệt thứ tự ưu tiên nguồn."

  @US-06-009 @FR-06-009 @M @âm
  Kịch bản: US-06-009 âm 2 · Hạ CSDL quốc gia khỏi mức 1 ở thuộc tính thẩm quyền
    Biết domain `ACTIVE`; nguồn `DRAFT` hoặc `ACTIVE`
    Khi hạ CSDL quốc gia khỏi mức 1 ở thuộc tính thẩm quyền
    Thì hệ thống từ chối với ERR-06-035 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, nguồn quốc gia phải ở mức 1."

  @US-06-010 @FR-06-010 @M
  Kịch bản: US-06-010 dương · Nạp bản ghi ứng viên qua API
    Biết nguồn `ACTIVE` có kênh `API` cho domain; domain `ACTIVE`
    Khi HTTT gọi API-06-021
    Thì hệ thống trả `202`; `results[]` gồm `sourceKey`, `candidateId`, `status` (`RECEIVED`, `DUPLICATE`, `SUPERSEDED`, `REJECTED`), `errors[]`; lỗi từng bản ghi không làm hỏng cả lô (trả `207` khi có bản ghi lỗi)
    Và ứng viên `RECEIVED` chờ chuẩn hóa
    Và sự kiện được phát: EVT-06-07 (ứng viên được nhận, gom theo lô); EVT-06-08 khi bị từ chối
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-010 @FR-06-010 @M @âm
  Kịch bản: US-06-010 âm 1 · Nguồn không được phép
    Biết nguồn `ACTIVE` có kênh `API` cho domain; domain `ACTIVE`
    Khi nguồn không được phép
    Thì hệ thống từ chối với ERR-06-014 (403)
    Và người dùng thấy thông báo "Hệ thống {mã} chưa được đăng ký làm nguồn cho domain {domain}."

  @US-06-010 @FR-06-010 @M @âm
  Kịch bản: US-06-010 âm 2 · Thiếu khóa nguồn
    Biết nguồn `ACTIVE` có kênh `API` cho domain; domain `ACTIVE`
    Khi thiếu khóa nguồn
    Thì hệ thống từ chối với ERR-06-016 (422)
    Và người dùng thấy thông báo "Bản ghi thiếu sourceKey nên không truy vết ngược được."

  @US-06-011 @FR-06-011 @M
  Kịch bản: US-06-011 dương · Nạp bản ghi ứng viên qua luồng PH-04
    Biết nguồn `ACTIVE` có kênh `FLOW`; luồng đã phát hành ở PH-04, khai báo `mdmSource` trong cấu hình
    Khi bước `dh-mdm-ingest-sink` (Kamelet nền, đề nghị cho PH-05) trong luồng gửi bản ghi
    Thì hệ thống trả `202` như FR-06-010
    Và ứng viên `RECEIVED` mang `flowCode`, `exchangeId`
    Và sự kiện được phát: EVT-06-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-011 @FR-06-011 @M @âm
  Kịch bản: US-06-011 âm 1 · Luồng không khớp nguồn
    Biết nguồn `ACTIVE` có kênh `FLOW`; luồng đã phát hành ở PH-04, khai báo `mdmSource` trong cấu hình
    Khi luồng không khớp nguồn
    Thì hệ thống từ chối với ERR-06-014 (403)
    Và người dùng thấy thông báo "Luồng {mã} không được gửi dữ liệu thay nguồn {nguồn}."

  @US-06-011 @FR-06-011 @M @âm
  Kịch bản: US-06-011 âm 2 · Sai lược đồ
    Biết nguồn `ACTIVE` có kênh `FLOW`; luồng đã phát hành ở PH-04, khai báo `mdmSource` trong cấu hình
    Khi sai lược đồ
    Thì hệ thống từ chối với ERR-06-017 (422)

  @US-06-012 @FR-06-012 @S
  Kịch bản: US-06-012 dương · Nạp bản ghi ứng viên qua sự kiện PH-10
    Biết nguồn `ACTIVE` kênh `EVENT`, khai báo `topic`, phiên bản lược đồ và ánh xạ trường sự kiện sang thuộc tính domain
    Khi sự kiện đến topic, ví dụ `t68.hotich.khai-sinh.registered.v1`
    Thì sự kiện nghiệp vụ tự cập nhật bản ghi vàng, HTTT nguồn không phải làm gì thêm
    Và ứng viên `RECEIVED`, offset đã xác nhận
    Và sự kiện được phát: EVT-06-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-012 @FR-06-012 @S @âm
  Kịch bản: US-06-012 âm 1 · Bản tin sai lược đồ hoặc thiếu khóa
    Biết nguồn `ACTIVE` kênh `EVENT`, khai báo `topic`, phiên bản lược đồ và ánh xạ trường sự kiện sang thuộc tính domain
    Khi bản tin sai lược đồ hoặc thiếu khóa
    Thì hệ thống từ chối với ERR-06-110
    Và người dùng thấy thông báo "Sự kiện {id} từ topic {topic} không dựng được bản ghi: {lý do}."

  @US-06-013 @FR-06-013 @M
  Kịch bản: US-06-013 dương · Nạp tệp lô có xem trước
    Biết nguồn `ACTIVE` có kênh `FILE`
    Khi UI-06-11, nút "Nhập tệp"
    Thì hệ thống trả `202`; `fileId`, `phase` (enum `FilePhase`), `report` (tải được), `jobId` sau xác nhận
    Và tệp gốc xóa khỏi bucket tạm sau 7 ngày; ứng viên `RECEIVED`
    Và sự kiện được phát: EVT-06-07; EVT-06-09 khi job xong
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-013 @FR-06-013 @M @âm
  Kịch bản: US-06-013 âm 1 · Tệp quá lớn
    Biết nguồn `ACTIVE` có kênh `FILE`
    Khi tệp quá lớn
    Thì hệ thống từ chối với ERR-06-018 (413)
    Và người dùng thấy thông báo "Tệp vượt {n} dòng hoặc {m} MB. Chia tệp nhỏ hơn."

  @US-06-013 @FR-06-013 @M @âm
  Kịch bản: US-06-013 âm 2 · Sai khuôn
    Biết nguồn `ACTIVE` có kênh `FILE`
    Khi sai khuôn
    Thì hệ thống từ chối với ERR-06-019 (422)
    Và người dùng thấy thông báo "Tệp không đúng khuôn mẫu của domain {mã}: thiếu cột {cột}."

  @US-06-014 @FR-06-014 @M
  Kịch bản: US-06-014 dương · Chuẩn hóa họ tên, ngày, số định danh
    Biết ứng viên `RECEIVED`
    Khi bản ghi ứng viên mới; hoặc "Xem trước chuẩn hóa" ở UI-06-11 (API-06-029)
    Thì ứng viên `NORMALIZED` (nội bộ); API xem trước trả `200` `raw`, `normalized`, `warnings[]`
    Và ứng viên có giá trị chuẩn hóa và cảnh báo

  @US-06-014 @FR-06-014 @M @âm
  Kịch bản: US-06-014 âm 1 · Định danh sai kiểm tra
    Biết ứng viên `RECEIVED`
    Khi định danh sai kiểm tra
    Thì không lỗi; cảnh báo `IDENTIFIER_INVALID` hiển thị ở UI-06-11 thông báo
    Và người dùng thấy thông báo "Số định danh {3 số cuối} không đúng quy tắc, không dùng làm khóa."

  @US-06-014 @FR-06-014 @M @âm
  Kịch bản: US-06-014 âm 2 · Thuộc tính bắt buộc bị đánh dấu `MISSING` sau chuẩn hóa
    Biết ứng viên `RECEIVED`
    Khi thuộc tính bắt buộc bị đánh dấu `MISSING` sau chuẩn hóa
    Thì ứng viên vẫn đi tiếp, BR-06-015 quyết định ở nhóm C

  @US-06-015 @FR-06-015 @M
  Kịch bản: US-06-015 dương · Chuẩn hóa địa chỉ theo ĐVHC của PH-07
    Biết ứng viên đã qua FR-06-014; PH-07 có danh mục ĐVHC
    Khi tiếp sau FR-06-014
    Thì ứng viên `NORMALIZED` hoặc `NORMALIZATION_PENDING`
    Và có `adminUnitCode` hiện hành hoặc cảnh báo lý do không có

  @US-06-015 @FR-06-015 @M @âm
  Kịch bản: US-06-015 âm 1 · Mã không tồn tại
    Biết ứng viên đã qua FR-06-014; PH-07 có danh mục ĐVHC
    Khi mã không tồn tại
    Thì hệ thống từ chối với ERR-06-020
    Và người dùng thấy thông báo "Mã ĐVHC {mã} không có trong danh mục tại ngày {ngày}."

  @US-06-015 @FR-06-015 @M @âm
  Kịch bản: US-06-015 âm 2 · PH-07 không khả dụng
    Biết ứng viên đã qua FR-06-014; PH-07 có danh mục ĐVHC
    Khi PH-07 không khả dụng
    Thì hệ thống từ chối với ERR-06-021
    Và người dùng thấy thông báo "Chuẩn hóa địa chỉ đang chờ phân hệ Danh mục: {n} bản ghi."

  @US-06-016 @FR-06-016 @M
  Kịch bản: US-06-016 dương · Chống trùng, thứ tự phiên bản nguồn và xóa từ nguồn
    Biết bản ghi đã qua kiểm lược đồ
    Khi mọi kênh nạp
    Thì trạng thái ứng viên trả theo FR-06-010
    Và mỗi `(sourceCode, sourceKey)` có tối đa một phiên bản hiện hành
    Và sự kiện được phát: EVT-06-14 khi liên kết bị gỡ do xóa nguồn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-016 @FR-06-016 @M @âm
  Kịch bản: US-06-016 âm 1 · Khóa dùng lại với nội dung khác
    Biết bản ghi đã qua kiểm lược đồ
    Khi khóa dùng lại với nội dung khác
    Thì hệ thống từ chối với ERR-06-015 (409)
    Và người dùng thấy thông báo "Idempotency-Key {khóa} đã dùng cho nội dung khác trong 24 giờ."

  @US-06-017 @FR-06-017 @M
  Kịch bản: US-06-017 dương · Xem bản ghi ứng viên và xử lý ứng viên lỗi
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi UI-06-11, tab "Ứng viên"; liên kết từ cảnh báo ở UI-06-01
    Thì hệ thống trả `200`; danh sách ứng viên; với thao tác: `accepted`, `skipped[]`
    Và ứng viên xử lý lại có trạng thái mới; lịch sử trạng thái giữ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-017 @FR-06-017 @M @âm
  Kịch bản: US-06-017 âm 1 · Ứng viên không ở trạng thái xử lý lại được
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi ứng viên không ở trạng thái xử lý lại được
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Ứng viên {id} đang ở trạng thái {trạng thái}, không xử lý lại được."

  @US-06-017 @FR-06-017 @M @âm
  Kịch bản: US-06-017 âm 2 · Thiếu lý do loại bỏ
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi thiếu lý do loại bỏ
    Thì hệ thống từ chối với ERR-06-007 (422)
    Và người dùng thấy thông báo "Nhập lý do loại bỏ (tối thiểu 20 ký tự)."

  # ---- EP-06-C · Đối sánh

  @US-06-018 @FR-06-018 @M
  Kịch bản: US-06-018 dương · Quản lý bộ quy tắc đối sánh có phiên bản
    Biết domain `ACTIVE`
    Khi UI-06-09, "Tạo phiên bản mới" từ phiên bản `ACTIVE` hoặc mặc định của gói nền
    Thì hệ thống trả `201` hoặc `200`; bộ quy tắc kèm `status`, `evaluation`
    Và một bộ quy tắc `ACTIVE` mỗi domain
    Và sự kiện được phát: EVT-06-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-018 @FR-06-018 @M @âm
  Kịch bản: US-06-018 âm 1 · Quy tắc sai
    Biết domain `ACTIVE`
    Khi quy tắc sai
    Thì hệ thống từ chối với ERR-06-022 (422)
    Và người dùng thấy thông báo "Bộ quy tắc không hợp lệ: {chi tiết}."

  @US-06-018 @FR-06-018 @M @âm
  Kịch bản: US-06-018 âm 2 · Chưa đạt độ chính xác
    Biết domain `ACTIVE`
    Khi chưa đạt độ chính xác
    Thì hệ thống từ chối với ERR-06-024 (422)
    Và người dùng thấy thông báo "Phiên bản {n} chưa có đánh giá đạt (precision {p}%, recall {r}%)."

  @US-06-019 @FR-06-019 @M
  Kịch bản: US-06-019 dương · Cấu hình khóa gom nhóm và theo dõi hiệu quả
    Biết bộ quy tắc ở `DRAFT`
    Khi tab "Gom nhóm" ở UI-06-09
    Thì hệ thống trả `200`; khóa kèm `stats` (`avgBlockSize`, `p99BlockSize`, `oversizedBlocks`, `pairCoverage`)
    Và khóa có hiệu lực khi bộ quy tắc kích hoạt; khóa mới tính lại cho bản ghi vàng bằng job nền
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-019 @FR-06-019 @M @âm
  Kịch bản: US-06-019 âm 1 · Biểu thức không hợp lệ hoặc dùng trường nhạy cảm dạng rõ
    Biết bộ quy tắc ở `DRAFT`
    Khi biểu thức không hợp lệ hoặc dùng trường nhạy cảm dạng rõ
    Thì hệ thống từ chối với ERR-06-022 (422)
    Và người dùng thấy thông báo "Khóa gom nhóm {biểu thức} không hợp lệ: thuộc tính nhạy cảm phải dùng hmac()."

  @US-06-020 @FR-06-020 @M
  Kịch bản: US-06-020 dương · Đối sánh xác định theo khóa định danh
    Biết ứng viên `NORMALIZED`; bộ quy tắc `ACTIVE`
    Khi ứng viên chuyển `NORMALIZED`; hoặc lời gọi resolve (FR-06-047)
    Thì hệ thống trả `match_result` nội bộ; với resolve trả theo FR-06-047
    Và ứng viên `LINKED` hoặc `QUEUED`

  @US-06-020 @FR-06-020 @M @âm
  Kịch bản: US-06-020 âm 1 · Hai bản ghi vàng cùng khóa (dữ liệu hỏng)
    Biết ứng viên `NORMALIZED`; bộ quy tắc `ACTIVE`
    Khi hai bản ghi vàng cùng khóa (dữ liệu hỏng)
    Thì hệ thống từ chối với ERR-06-112
    Và người dùng thấy thông báo "Phát hiện {n} bản ghi vàng cùng số định danh. Cần xử lý ngay."

  @US-06-020 @FR-06-020 @M @âm
  Kịch bản: US-06-020 âm 2 · Ứng viên có khóa khác với khóa của bản ghi vàng đang liên kết
    Biết ứng viên `NORMALIZED`; bộ quy tắc `ACTIVE`
    Khi ứng viên có khóa khác với khóa của bản ghi vàng đang liên kết
    Thì hệ thống trả `CONFLICT`, lý do `IDENTIFIER_CONFLICT`

  @US-06-021 @FR-06-021 @M
  Kịch bản: US-06-021 dương · Đối sánh xác suất trực tuyến
    Biết ứng viên `NORMALIZED` không có khóa xác định hợp lệ, hoặc chuyển từ FR-06-020 bước 4
    Khi tiếp sau FR-06-020
    Thì hệ thống trả `match_result` nội bộ
    Và ứng viên `LINKED` hoặc `QUEUED`

  @US-06-021 @FR-06-021 @M @âm
  Kịch bản: US-06-021 âm 1 · Truy vấn vượt `06.match.timeout-ms` (mặc định 800 ms)
    Biết ứng viên `NORMALIZED` không có khóa xác định hợp lệ, hoặc chuyển từ FR-06-020 bước 4
    Khi truy vấn vượt `06.match.timeout-ms` (mặc định 800 ms)
    Thì ngắt, kết luận `POSSIBLE_MATCH` lý do `TIMEOUT`, ghi `datahub_mdm_match_timeout_total`; vận hành thấy cảnh báo khi tỷ lệ > 1% ở UI-06-01 thông báo
    Và người dùng thấy thông báo "Đối sánh trực tuyến chậm: {tỷ lệ}% lượt quá giờ."

  @US-06-022 @FR-06-022 @M
  Kịch bản: US-06-022 dương · Chạy job đối sánh theo lô bằng Splink
    Biết bộ quy tắc `ACTIVE` (hoặc `TESTING` với `dryRun = true`); không có job `BATCH_MATCH` khác đang chạy cho domain
    Khi "Chạy job" ở UI-06-12 hoặc lịch (mặc định 01:00 Chủ nhật)
    Thì hệ thống trả `202`; `jobId`; trạng thái job: `counts` (`input`, `pairs`, `match`, `possible`, `noMatch`, `applied`, `skipped`), `parameters` (m, u nếu huấn luyện)
    Và staging bị xóa; tham số huấn luyện lưu vào bộ quy tắc nháp mới nếu `trainOnly`
    Và sự kiện được phát: EVT-06-09; EVT-06-03 cho từng hợp nhất
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-022 @FR-06-022 @M @âm
  Kịch bản: US-06-022 âm 1 · Job trùng
    Biết bộ quy tắc `ACTIVE` (hoặc `TESTING` với `dryRun = true`); không có job `BATCH_MATCH` khác đang chạy cho domain
    Khi job trùng
    Thì hệ thống từ chối với ERR-06-025 (409)
    Và người dùng thấy thông báo "Domain {mã} đang có job đối sánh {jobId} chạy."

  @US-06-022 @FR-06-022 @M @âm
  Kịch bản: US-06-022 âm 2 · Job K8s lỗi đọc staging
    Biết bộ quy tắc `ACTIVE` (hoặc `TESTING` với `dryRun = true`); không có job `BATCH_MATCH` khác đang chạy cho domain
    Khi job K8s lỗi đọc staging
    Thì hệ thống từ chối với ERR-06-101
    Và người dùng thấy thông báo "Job {id} lỗi khi đọc dữ liệu: {chi tiết}. Không bản ghi vàng nào bị đổi."

  @US-06-023 @FR-06-023 @M
  Kịch bản: US-06-023 dương · Cấu hình ngưỡng tự hợp nhất, xem xét, khác biệt
    Biết bộ quy tắc `DRAFT`
    Khi tab "Ngưỡng" ở UI-06-09, thanh trượt kèm biểu đồ phân bố điểm
    Thì hệ thống trả `200`; ngưỡng, `estimatedQueuePerDay`, `estimatedPrecision`, `estimatedRecall`
    Và ngưỡng lưu trong bộ quy tắc nháp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-023 @FR-06-023 @M @âm
  Kịch bản: US-06-023 âm 1 · Ngưỡng sai
    Biết bộ quy tắc `DRAFT`
    Khi ngưỡng sai
    Thì hệ thống từ chối với ERR-06-023 (422)
    Và người dùng thấy thông báo "Ngưỡng tự hợp nhất phải từ 0,90 trở lên và cao hơn ngưỡng xem xét ít nhất 0,10."

  @US-06-024 @FR-06-024 @S
  Kịch bản: US-06-024 dương · Chạy thử bộ quy tắc trên mẫu
    Biết bộ quy tắc `DRAFT` hoặc `TESTING`
    Khi "Chạy thử" ở UI-06-09
    Thì hệ thống trả `202`; `jobId`; báo cáo `dryRunReport`
    Và sự kiện được phát: EVT-06-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-024 @FR-06-024 @S @âm
  Kịch bản: US-06-024 âm 1 · Mẫu ngoài miền
    Biết bộ quy tắc `DRAFT` hoặc `TESTING`
    Khi mẫu ngoài miền
    Thì hệ thống từ chối với ERR-06-047 (422)
    Và người dùng thấy thông báo "Cỡ mẫu phải từ 1.000 đến 100.000."

  @US-06-025 @FR-06-025 @M
  Kịch bản: US-06-025 dương · Quản lý tập nhãn kiểm chứng
    Biết domain `ACTIVE`
    Khi UI-06-13, "Tạo tập nhãn"; hoặc tự động khi DS quyết định ở hàng đợi
    Thì hệ thống trả `201`; tập kèm `stats`
    Và cặp có nhãn lưu ở `label_pair`, tham chiếu bản ghi (không chép DLCN)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-025 @FR-06-025 @M @âm
  Kịch bản: US-06-025 âm 1 · Mã trùng
    Biết domain `ACTIVE`
    Khi mã trùng
    Thì hệ thống từ chối với ERR-06-002 (409)
    Và người dùng thấy thông báo "Mã tập nhãn {mã} đã được dùng."

  @US-06-025 @FR-06-025 @M @âm
  Kịch bản: US-06-025 âm 2 · Tập đã khóa
    Biết domain `ACTIVE`
    Khi tập đã khóa
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Tập nhãn {mã} đã khóa. Tạo phiên bản mới để thêm cặp."

  @US-06-026 @FR-06-026 @M
  Kịch bản: US-06-026 dương · Đo precision, recall và chặn kích hoạt quy tắc kém
    Biết tập nhãn `EVALUATION` đã khóa, ≥ 1.000 cặp (nghiệm thu: ≥ 10.000)
    Khi "Đánh giá" ở UI-06-09; tự động hằng tháng cho bộ quy tắc `ACTIVE`
    Thì hệ thống trả `202`; báo cáo `precision`, `recall`, `reviewRate`, `confusion` (TP, FP, TN, FN, REVIEW), `verdict`
    Và báo cáo lưu 2 năm, gắn phiên bản quy tắc và phiên bản tập nhãn
    Và sự kiện được phát: EVT-06-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-026 @FR-06-026 @M @âm
  Kịch bản: US-06-026 âm 1 · Tập nhãn nhỏ
    Biết tập nhãn `EVALUATION` đã khóa, ≥ 1.000 cặp (nghiệm thu: ≥ 10.000)
    Khi tập nhãn nhỏ
    Thì hệ thống từ chối với ERR-06-026 (422)
    Và người dùng thấy thông báo "Tập nhãn cần tối thiểu 1.000 cặp, hiện có {n}."

  @US-06-026 @FR-06-026 @M @âm
  Kịch bản: US-06-026 âm 2 · Gửi duyệt khi đánh giá không đạt
    Biết tập nhãn `EVALUATION` đã khóa, ≥ 1.000 cặp (nghiệm thu: ≥ 10.000)
    Khi gửi duyệt khi đánh giá không đạt
    Thì hệ thống từ chối với ERR-06-024 (422)
    Và người dùng thấy thông báo "Phiên bản {n} chưa đạt: precision {p}%, recall {r}%."

  # ---- EP-06-D · Hàng đợi người quản lý dữ liệu

  @US-06-027 @FR-06-027 @M
  Kịch bản: US-06-027 dương · Tạo mục hàng đợi và tính mức ưu tiên
    Biết có `match_result` kết luận `POSSIBLE_MATCH` hoặc `CONFLICT`, hoặc xung đột thuộc tính quan trọng từ sống sót, hoặc bản ghi vàng mồ côi, hoặc PH-08 chuyển lỗi chất lượng của bản ghi vàng sang hàng đợi (`DQ_FINDING`)
    Khi nhóm C, FR-06-033, FR-06-016; PH-08 gọi API-06-126 (FR-08-046) bằng scope `mdm:steward-intake`
    Thì mục hàng đợi nội bộ
    Và mục `OPEN`; bản ghi vàng liên quan không bị khóa (chỉ khóa khi chờ duyệt)
    Và sự kiện được phát: EVT-06-08

  @US-06-027 @FR-06-027 @M @âm
  Kịch bản: US-06-027 âm 1 · Hàng đợi vượt `06.queue.max-open` (mặc định 500)
    Biết có `match_result` kết luận `POSSIBLE_MATCH` hoặc `CONFLICT`, hoặc xung đột thuộc tính quan trọng từ sống sót, hoặc bản ghi vàng mồ côi, hoặc PH-08 chuyển lỗi chất lượng của bản ghi vàng sang hàng đợi (`DQ_FINDING`)
    Khi hàng đợi vượt `06.queue.max-open` (mặc định 500)
    Thì vẫn tạo, cảnh báo quá tải (FR-06-032)

  @US-06-027 @FR-06-027 @M @âm
  Kịch bản: US-06-027 âm 2 · `DQ_FINDING` có `goldenId` không tồn tại hoặc không thuộc domain
    Biết có `match_result` kết luận `POSSIBLE_MATCH` hoặc `CONFLICT`, hoặc xung đột thuộc tính quan trọng từ sống sót, hoặc bản ghi vàng mồ côi, hoặc PH-08 chuyển lỗi chất lượng của bản ghi vàng sang hàng đợi (`DQ_FINDING`)
    Khi `DQ_FINDING` có `goldenId` không tồn tại hoặc không thuộc domain
    Thì hệ thống từ chối với ERR-06-050 (404)
    Và người dùng thấy thông báo "Không có bản ghi vàng cho {nguồn}/{khóa}."

  @US-06-028 @FR-06-028 @M
  Kịch bản: US-06-028 dương · Liệt kê, nhận việc và phân công mục hàng đợi
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi UI-06-04; "Nhận việc tiếp theo"
    Thì hệ thống trả `200`; danh sách, `counts` theo trạng thái, lý do
    Và mục `ASSIGNED` kèm người, hạn giữ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-028 @FR-06-028 @M @âm
  Kịch bản: US-06-028 âm 1 · Mục đã có người nhận
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi mục đã có người nhận
    Thì hệ thống từ chối với ERR-06-027 (409)
    Và người dùng thấy thông báo "Mục này vừa được {người} nhận. Hệ thống chuyển anh/chị sang mục kế tiếp."

  @US-06-028 @FR-06-028 @M @âm
  Kịch bản: US-06-028 âm 2 · Không thuộc phạm vi
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi không thuộc phạm vi
    Thì hệ thống từ chối với ERR-06-028 (403)
    Và người dùng thấy thông báo "Mục thuộc dữ liệu của tổ chức khác, anh/chị không được xử lý."

  @US-06-029 @FR-06-029 @M
  Kịch bản: US-06-029 dương · So sánh cạnh nhau hai bản ghi
    Biết mục `ASSIGNED` cho người dùng hoặc `PENDING_APPROVAL` với DA
    Khi mở mục ở UI-06-04
    Thì hệ thống trả `200`; `left`, `right`, `attributes[]` (`name`, `leftValue`, `rightValue`, `score`, `level`), `context`, `mergeAllowed`, `queueRemaining`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-029 @FR-06-029 @M @âm
  Kịch bản: US-06-029 âm 1 · Mục lỗi thời
    Biết mục `ASSIGNED` cho người dùng hoặc `PENDING_APPROVAL` với DA
    Khi mục lỗi thời
    Thì hệ thống từ chối với ERR-06-030 (409)
    Và người dùng thấy thông báo "Dữ liệu của cặp đã thay đổi sau khi tạo mục. Hệ thống đã đối sánh lại."

  @US-06-029 @FR-06-029 @M @âm
  Kịch bản: US-06-029 âm 2 · Không ghi được nhật ký
    Biết mục `ASSIGNED` cho người dùng hoặc `PENDING_APPROVAL` với DA
    Khi không ghi được nhật ký
    Thì hệ thống từ chối với ERR-06-039 (503)
    Và người dùng thấy thông báo "Chưa ghi được nhật ký truy cập nên không hiển thị dữ liệu. Thử lại sau ít phút."

  @US-06-030 @FR-06-030 @M
  Kịch bản: US-06-030 dương · Quyết định khớp, không khớp, hoãn
    Biết mục `ASSIGNED` cho người dùng, còn hiệu lực
    Khi nút "Cùng một thực thể", "Khác nhau", "Hoãn" ở UI-06-05; phím tắt M, K, H (FR-06-029)
    Thì hệ thống trả `200`; mục kèm `status`, `operationId` (nếu có thay đổi bản ghi vàng), `nextItemId`
    Và ứng viên `LINKED`; cặp vào tập nhãn; `negativeLink` nếu `NO_MATCH`
    Và sự kiện được phát: EVT-06-01, EVT-06-02 hoặc EVT-06-03 tùy thay đổi bản ghi vàng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-030 @FR-06-030 @M @âm
  Kịch bản: US-06-030 âm 1 · Thiếu lý do
    Biết mục `ASSIGNED` cho người dùng, còn hiệu lực
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-06-007 (422)
    Và người dùng thấy thông báo "Nhập lý do quyết định (tối thiểu 20 ký tự)."

  @US-06-030 @FR-06-030 @M @âm
  Kịch bản: US-06-030 âm 2 · Hai số định danh khác nhau
    Biết mục `ASSIGNED` cho người dùng, còn hiệu lực
    Khi hai số định danh khác nhau
    Thì hệ thống từ chối với ERR-06-029 (422)
    Và người dùng thấy thông báo "Hai bản ghi có số định danh khác nhau nên không được hợp nhất. Kiểm tra lại dữ liệu nguồn."

  @US-06-031 @FR-06-031 @M
  Kịch bản: US-06-031 dương · Duyệt bốn mắt hợp nhất rủi ro cao
    Biết mục `PENDING_APPROVAL` hoặc thao tác `golden_operation` `PENDING_APPROVAL` (từ FR-06-037, 038, 039)
    Khi việc trong "Việc của tôi"; UI-06-05 chế độ duyệt
    Thì hệ thống trả `200`; mục, `operationId`, `status`
    Và bản ghi vàng `ACTIVE` (bản sống sót), `MERGED` (bản bị hợp nhất) hoặc trở lại như cũ
    Và sự kiện được phát: EVT-06-03 khi duyệt hợp nhất; EVT-06-04 khi duyệt tách
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-031 @FR-06-031 @M @âm
  Kịch bản: US-06-031 âm 1 · Tự duyệt
    Biết mục `PENDING_APPROVAL` hoặc thao tác `golden_operation` `PENDING_APPROVAL` (từ FR-06-037, 038, 039)
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-06-005 (403)
    Và người dùng thấy thông báo "Anh/chị là người đề nghị hợp nhất nên không được tự duyệt."

  @US-06-031 @FR-06-031 @M @âm
  Kịch bản: US-06-031 âm 2 · Thiếu ý kiến khi từ chối
    Biết mục `PENDING_APPROVAL` hoặc thao tác `golden_operation` `PENDING_APPROVAL` (từ FR-06-037, 038, 039)
    Khi thiếu ý kiến khi từ chối
    Thì hệ thống từ chối với ERR-06-007 (422)
    Và người dùng thấy thông báo "Nhập lý do từ chối (tối thiểu 20 ký tự)."

  @US-06-032 @FR-06-032 @M
  Kịch bản: US-06-032 dương · Theo dõi SLA, nâng ưu tiên và cảnh báo quá tải
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi job định kỳ 15 phút
    Thì API-06-050 trả `200` thống kê hàng đợi theo trạng thái, lý do, nguồn, tuổi
    Và mục quá hạn có ưu tiên mới

  @US-06-032 @FR-06-032 @M @âm
  Kịch bản: US-06-032 âm 1 · PH-13 không nhận cảnh báo
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi PH-13 không nhận cảnh báo
    Thì hệ thống giữ cảnh báo ở UI-06-01 thông báo
    Và người dùng thấy thông báo "Hàng đợi có {n} mục mở, vượt ngưỡng {m}."

  # ---- EP-06-E · Bản ghi vàng

  @US-06-033 @FR-06-033 @M
  Kịch bản: US-06-033 dương · Cấu hình quy tắc sống sót thuộc tính
    Biết domain `ACTIVE`; bảng ưu tiên nguồn đã duyệt (FR-06-009)
    Khi UI-06-10
    Thì hệ thống trả `200`; cấu hình kèm `status`, `version`
    Và cấu hình mới áp cho mọi cập nhật sau duyệt; áp cho dữ liệu cũ qua FR-06-042
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-033 @FR-06-033 @M @âm
  Kịch bản: US-06-033 âm 1 · Chiến lược sai kiểu
    Biết domain `ACTIVE`; bảng ưu tiên nguồn đã duyệt (FR-06-009)
    Khi chiến lược sai kiểu
    Thì hệ thống từ chối với ERR-06-022 (422)
    Và người dùng thấy thông báo "Chiến lược {chiến lược} không áp được cho thuộc tính kiểu {kiểu}."

  @US-06-033 @FR-06-033 @M @âm
  Kịch bản: US-06-033 âm 2 · Bỏ thẩm quyền quốc gia
    Biết domain `ACTIVE`; bảng ưu tiên nguồn đã duyệt (FR-06-009)
    Khi bỏ thẩm quyền quốc gia
    Thì hệ thống từ chối với ERR-06-035 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, không đổi được chiến lược đầu."

  @US-06-034 @FR-06-034 @M
  Kịch bản: US-06-034 dương · Tạo và cập nhật bản ghi vàng tự động
    Biết kết luận `MATCH` (liên kết vào bản ghi có sẵn) hoặc `NO_MATCH` (tạo mới); bản ghi vàng đích không `MERGED`, `RETIRED`
    Khi FR-06-020, 021, 022, 030, 031, 053
    Thì nội bộ: `goldenId`, `version`, danh sách thuộc tính đổi
    Và ảnh chụp trước thay đổi tồn tại cho mọi `version` > 1
    Và sự kiện được phát: EVT-06-01; EVT-06-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-034 @FR-06-034 @M @âm
  Kịch bản: US-06-034 âm 1 · Ghi lịch sử lỗi
    Biết kết luận `MATCH` (liên kết vào bản ghi có sẵn) hoặc `NO_MATCH` (tạo mới); bản ghi vàng đích không `MERGED`, `RETIRED`
    Khi ghi lịch sử lỗi
    Thì hệ thống từ chối với ERR-06-111
    Và người dùng thấy thông báo "Không lưu được lịch sử bản ghi vàng nên chưa cập nhật. Đã ghi nhận để xử lý lại."

  @US-06-034 @FR-06-034 @M @âm
  Kịch bản: US-06-034 âm 2 · Xung đột khóa lạc quan khi nhiều cập nhật đồng thời
    Biết kết luận `MATCH` (liên kết vào bản ghi có sẵn) hoặc `NO_MATCH` (tạo mới); bản ghi vàng đích không `MERGED`, `RETIRED`
    Khi xung đột khóa lạc quan khi nhiều cập nhật đồng thời
    Thì thử lại tối đa 5 lần

  @US-06-035 @FR-06-035 @M
  Kịch bản: US-06-035 dương · Xem chi tiết bản ghi vàng
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi mở từ UI-06-02, hàng đợi, lineage
    Thì hệ thống trả `200`; như ví dụ JSON dưới; `ETag`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-035 @FR-06-035 @M @âm
  Kịch bản: US-06-035 âm 1 · Không tìm thấy
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-06-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy bản ghi vàng {id}."

  @US-06-035 @FR-06-035 @M @âm
  Kịch bản: US-06-035 âm 2 · Không ghi được nhật ký
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi không ghi được nhật ký
    Thì hệ thống từ chối với ERR-06-039 (503)
    Và người dùng thấy thông báo "Chưa ghi được nhật ký truy cập nên không hiển thị dữ liệu. Thử lại sau ít phút."

  @US-06-036 @FR-06-036 @S
  Kịch bản: US-06-036 dương · Sửa tay thuộc tính có lý do
    Biết bản ghi vàng `ACTIVE`; thuộc tính không thẩm quyền quốc gia
    Khi nút "Sửa" cạnh thuộc tính ở UI-06-03
    Thì hệ thống trả `200`; bản ghi vàng mới, `operationId`, `sourceCorrectionRequestId`
    Và `version` tăng; yêu cầu sửa tại nguồn mở
    Và sự kiện được phát: EVT-06-02; EVT-06-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-036 @FR-06-036 @S @âm
  Kịch bản: US-06-036 âm 1 · Thuộc tính thẩm quyền quốc gia
    Biết bản ghi vàng `ACTIVE`; thuộc tính không thẩm quyền quốc gia
    Khi thuộc tính thẩm quyền quốc gia
    Thì hệ thống từ chối với ERR-06-035 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} chỉ được sửa tại CSDL quốc gia. Hướng dẫn công dân liên hệ cơ quan đăng ký."

  @US-06-037 @FR-06-037 @M
  Kịch bản: US-06-037 dương · Hợp nhất bản ghi vàng thủ công
    Biết mọi bản ghi `ACTIVE`, cùng domain
    Khi UI-06-06 "Hợp nhất", chọn 2…10 bản ghi từ UI-06-02
    Thì hệ thống trả `200` (thực hiện ngay) hoặc `202` (chờ duyệt); `operationId`, `survivorId`
    Và bản ghi bị hợp nhất `MERGED`; liên kết chuyển; hoàn tác được 90 ngày
    Và sự kiện được phát: EVT-06-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-037 @FR-06-037 @M @âm
  Kịch bản: US-06-037 âm 1 · Định danh khác nhau
    Biết mọi bản ghi `ACTIVE`, cùng domain
    Khi định danh khác nhau
    Thì hệ thống từ chối với ERR-06-029 (422)
    Và người dùng thấy thông báo "Hai bản ghi có số định danh khác nhau nên không được hợp nhất."

  @US-06-037 @FR-06-037 @M @âm
  Kịch bản: US-06-037 âm 2 · Bản ghi không còn `ACTIVE`
    Biết mọi bản ghi `ACTIVE`, cùng domain
    Khi bản ghi không còn `ACTIVE`
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Bản ghi {id} đang ở trạng thái {trạng thái}."

  @US-06-038 @FR-06-038 @M
  Kịch bản: US-06-038 dương · Tách bản ghi vàng
    Biết bản ghi `ACTIVE` có ≥ 2 liên kết nguồn hiệu lực
    Khi UI-06-06 "Tách"
    Thì hệ thống trả `200` hoặc `202`; `operationId`, `resultGoldenIds[]`
    Và `negativeLink` ngăn đối sánh hợp nhất lại
    Và sự kiện được phát: EVT-06-04; EVT-06-01 cho bản ghi tạo mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-038 @FR-06-038 @M @âm
  Kịch bản: US-06-038 âm 1 · Phân bổ thiếu, trùng
    Biết bản ghi `ACTIVE` có ≥ 2 liên kết nguồn hiệu lực
    Khi phân bổ thiếu, trùng
    Thì hệ thống từ chối với ERR-06-032 (422)
    Và người dùng thấy thông báo "Mỗi bản ghi nguồn phải thuộc đúng một nhóm sau khi tách."

  @US-06-038 @FR-06-038 @M @âm
  Kịch bản: US-06-038 âm 2 · Bản ghi chỉ một liên kết
    Biết bản ghi `ACTIVE` có ≥ 2 liên kết nguồn hiệu lực
    Khi bản ghi chỉ một liên kết
    Thì hệ thống từ chối với ERR-06-032 (422)
    Và người dùng thấy thông báo "Bản ghi chỉ có một nguồn liên kết, không có gì để tách."

  @US-06-039 @FR-06-039 @M
  Kịch bản: US-06-039 dương · Hoàn tác thao tác trên bản ghi vàng
    Biết thao tác `APPLIED`, chưa `UNDONE`
    Khi tab "Thao tác" ở UI-06-03, nút "Hoàn tác"
    Thì hệ thống trả `200` hoặc `202`; `undoOperationId`, bản ghi bị ảnh hưởng
    Và lịch sử có cả thao tác gốc và thao tác hoàn tác
    Và sự kiện được phát: EVT-06-02, EVT-06-03 hoặc EVT-06-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-039 @FR-06-039 @M @âm
  Kịch bản: US-06-039 âm 1 · Có thao tác phụ thuộc
    Biết thao tác `APPLIED`, chưa `UNDONE`
    Khi có thao tác phụ thuộc
    Thì hệ thống từ chối với ERR-06-033 (409)
    Và người dùng thấy thông báo "Có {n} thao tác sau phụ thuộc vào thao tác này. Xem danh sách và xác nhận để hoàn tác cả chuỗi."

  @US-06-039 @FR-06-039 @M @âm
  Kịch bản: US-06-039 âm 2 · Quá hạn
    Biết thao tác `APPLIED`, chưa `UNDONE`
    Khi quá hạn
    Thì hệ thống từ chối với ERR-06-034 (403)
    Và người dùng thấy thông báo "Thao tác đã quá {n} ngày. Đề nghị hoàn tác đã được gửi người duyệt dữ liệu."

  @US-06-040 @FR-06-040 @M
  Kịch bản: US-06-040 dương · Ngừng và khôi phục bản ghi vàng
    Biết ngừng: `ACTIVE`, không còn liên kết hiệu lực hoặc nguồn thẩm quyền báo chấm dứt (giải thể, chết)
    Khi UI-06-03 "Ngừng", "Khôi phục"; mục hàng đợi `ORPHANED`
    Thì hệ thống trả `200`; bản ghi kèm `status`, `retiredReason`
    Và sự kiện được phát: EVT-06-05 (ngừng); EVT-06-06 (khôi phục)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-040 @FR-06-040 @M @âm
  Kịch bản: US-06-040 âm 1 · Còn liên kết hiệu lực
    Biết ngừng: `ACTIVE`, không còn liên kết hiệu lực hoặc nguồn thẩm quyền báo chấm dứt (giải thể, chết)
    Khi còn liên kết hiệu lực
    Thì hệ thống từ chối với ERR-06-036 (422)
    Và người dùng thấy thông báo "Bản ghi còn {n} nguồn liên kết hiệu lực. Gỡ liên kết hoặc chọn lý do có căn cứ từ nguồn thẩm quyền."

  @US-06-041 @FR-06-041 @M
  Kịch bản: US-06-041 dương · Xem lịch sử phiên bản và so sánh hai phiên bản
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi tab "Lịch sử" ở UI-06-03
    Thì hệ thống trả `200`; `versions[]`; `snapshot`; `diff[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-041 @FR-06-041 @M @âm
  Kịch bản: US-06-041 âm 1 · Phiên bản không có
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi phiên bản không có
    Thì hệ thống từ chối với ERR-06-001 (404)
    Và người dùng thấy thông báo "Bản ghi {id} không có phiên bản {n}."

  @US-06-042 @FR-06-042 @S
  Kịch bản: US-06-042 dương · Xem trước tác động và áp lại sống sót hàng loạt
    Biết cấu hình mới đã duyệt hoặc đang chờ duyệt (xem trước)
    Khi "Xem trước tác động" ở UI-06-08, UI-06-10; job `SURVIVORSHIP_REAPPLY` tạo bởi FR-06-006, 009, 033
    Thì hệ thống trả `200` (xem trước) hoặc `202` (`jobId`)
    Và bản ghi vàng phản ánh cấu hình mới
    Và sự kiện được phát: EVT-06-02; EVT-06-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-042 @FR-06-042 @S @âm
  Kịch bản: US-06-042 âm 1 · Đang có job áp lại khác
    Biết cấu hình mới đã duyệt hoặc đang chờ duyệt (xem trước)
    Khi đang có job áp lại khác
    Thì hệ thống từ chối với ERR-06-025 (409)
    Và người dùng thấy thông báo "Domain {mã} đang có job áp lại {jobId}."

  # ---- EP-06-F · Truy xuất nguồn gốc và liên kết chéo nguồn

  @US-06-043 @FR-06-043 @M
  Kịch bản: US-06-043 dương · Truy xuất nguồn gốc từng thuộc tính
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi bấm nhãn nguồn của thuộc tính ở UI-06-03, tab "Nguồn gốc"
    Thì hệ thống trả `200`; `attribute`, `currentValue`, `history[]`, `perSourceValues[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-043 @FR-06-043 @M @âm
  Kịch bản: US-06-043 âm 1 · Thuộc tính không có trong mô hình
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi thuộc tính không có trong mô hình
    Thì hệ thống từ chối với ERR-06-003 (400)
    Và người dùng thấy thông báo "Domain {mã} không có thuộc tính {tên}."

  @US-06-044 @FR-06-044 @M
  Kịch bản: US-06-044 dương · Xem và gỡ liên kết chéo nguồn
    Biết gỡ: liên kết `ACTIVE`; bản ghi vàng không `LOCKED`
    Khi tab "Nguồn liên kết" ở UI-06-03
    Thì hệ thống trả `200`; danh sách liên kết; khi gỡ: `operationId`, `newGoldenId`
    Và bản ghi nguồn liên kết đúng một bản ghi vàng hoặc chờ đối sánh lại
    Và sự kiện được phát: EVT-06-14; EVT-06-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-044 @FR-06-044 @M @âm
  Kịch bản: US-06-044 âm 1 · Liên kết không hiệu lực
    Biết gỡ: liên kết `ACTIVE`; bản ghi vàng không `LOCKED`
    Khi liên kết không hiệu lực
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Liên kết đã ở trạng thái {trạng thái}."

  @US-06-044 @FR-06-044 @M @âm
  Kịch bản: US-06-044 âm 2 · Đang khóa
    Biết gỡ: liên kết `ACTIVE`; bản ghi vàng không `LOCKED`
    Khi đang khóa
    Thì hệ thống từ chối với ERR-06-031 (409)
    Và người dùng thấy thông báo "Bản ghi vàng {id} đang có thao tác chờ duyệt."

  @US-06-045 @FR-06-045 @M
  Kịch bản: US-06-045 dương · Tra ID nguồn và ID vàng
    Biết nguồn của bên gọi `ACTIVE`; tra chiều vàng sang nguồn khác cần mục đích PH-09 cho phép biết sự tồn tại của bản ghi ở hệ khác
    Khi API-06-068 (một khóa), API-06-069 (lô ≤ `06.xref.batch-max`)
    Thì hệ thống trả `200`; `items[]` gồm `sourceCode`, `sourceKey`, `goldenId`, `status`, `redirectedFrom`, `links[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-045 @FR-06-045 @M @âm
  Kịch bản: US-06-045 âm 1 · Không có liên kết
    Biết nguồn của bên gọi `ACTIVE`; tra chiều vàng sang nguồn khác cần mục đích PH-09 cho phép biết sự tồn tại của bản ghi ở hệ khác
    Khi không có liên kết
    Thì hệ thống từ chối với ERR-06-050 (404)
    Và người dùng thấy thông báo "Không có bản ghi vàng cho {nguồn}/{khóa}."

  @US-06-045 @FR-06-045 @M @âm
  Kịch bản: US-06-045 âm 2 · Thiếu mục đích
    Biết nguồn của bên gọi `ACTIVE`; tra chiều vàng sang nguồn khác cần mục đích PH-09 cho phép biết sự tồn tại của bản ghi ở hệ khác
    Khi thiếu mục đích
    Thì hệ thống từ chối với ERR-06-037 (403)
    Và người dùng thấy thông báo "Yêu cầu thiếu mục đích khai thác được chấp thuận cho dữ liệu này."

  # ---- EP-06-G · Cung cấp dữ liệu và đồng bộ quốc gia

  @US-06-046 @FR-06-046 @M
  Kịch bản: US-06-046 dương · Tra cứu bản ghi vàng theo ID hoặc khóa định danh
    Biết bên gọi có mục đích được PH-09 chấp thuận cho domain (trừ PH-08 dùng mục đích nội bộ "chất lượng dữ liệu")
    Khi API-06-056 (theo `goldenId`), API-06-070 (theo khóa, `POST` để khóa không nằm trên URL)
    Thì hệ thống trả `200`; như ví dụ FR-06-035 sau khi che; `ETag`, `Cache-Control: private, max-age=0`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-046 @FR-06-046 @M @âm
  Kịch bản: US-06-046 âm 1 · Không tìm thấy
    Biết bên gọi có mục đích được PH-09 chấp thuận cho domain (trừ PH-08 dùng mục đích nội bộ "chất lượng dữ liệu")
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-06-050 (404)
    Và người dùng thấy thông báo "Không có bản ghi vàng khớp khóa đã gửi."

  @US-06-046 @FR-06-046 @M @âm
  Kịch bản: US-06-046 âm 2 · Đã ngừng
    Biết bên gọi có mục đích được PH-09 chấp thuận cho domain (trừ PH-08 dùng mục đích nội bộ "chất lượng dữ liệu")
    Khi đã ngừng
    Thì hệ thống từ chối với ERR-06-001 (410)
    Và người dùng thấy thông báo "Bản ghi vàng {id} đã ngừng sử dụng: {lý do}."

  @US-06-047 @FR-06-047 @M
  Kịch bản: US-06-047 dương · Giải quyết bản ghi trực tuyến (resolve)
    Biết bộ quy tắc `ACTIVE`; mục đích PH-09 cho domain
    Khi API-06-071
    Thì hệ thống trả `200`, `202` hoặc `404`; `outcome` (`MatchOutcome`), `goldenId`, `score`, `method`, `attributeScores`, `candidates[]`, `queueItemId`
    Và sự kiện được phát: EVT-06-08 khi tạo mục hàng đợi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-047 @FR-06-047 @M @âm
  Kịch bản: US-06-047 âm 1 · Thiếu thuộc tính tối thiểu
    Biết bộ quy tắc `ACTIVE`; mục đích PH-09 cho domain
    Khi thiếu thuộc tính tối thiểu
    Thì hệ thống từ chối với ERR-06-003 (400)
    Và người dùng thấy thông báo "Cần ít nhất {n} thuộc tính để đối sánh: {danh sách}."

  @US-06-047 @FR-06-047 @M @âm
  Kịch bản: US-06-047 âm 2 · Vượt hạn mức
    Biết bộ quy tắc `ACTIVE`; mục đích PH-09 cho domain
    Khi vượt hạn mức
    Thì hệ thống từ chối với ERR-06-048 (429)
    Và người dùng thấy thông báo "Vượt hạn mức {n} lượt mỗi phút."

  @US-06-048 @FR-06-048 @M
  Kịch bản: US-06-048 dương · Tìm kiếm bản ghi vàng theo thuộc tính
    Biết với HTTT: mục đích PH-09 cho phép tìm
    Khi UI-06-02; API-06-072
    Thì hệ thống trả `200`; `items[]` (`goldenId`, tên hiển thị, ngày sinh che dạng năm, xã, số nguồn, độ tin cậy, trạng thái), `page`, `totalElements` (giới hạn hiển thị "trên 1.000")
    Và bộ đếm truy cập của người dùng tăng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-048 @FR-06-048 @M @âm
  Kịch bản: US-06-048 âm 1 · Tìm quá rộng
    Biết với HTTT: mục đích PH-09 cho phép tìm
    Khi tìm quá rộng
    Thì hệ thống từ chối với ERR-06-040 (422)
    Và người dùng thấy thông báo "Nhập thêm tiêu chí: họ tên cần đi kèm ngày sinh, năm sinh hoặc xã."

  @US-06-048 @FR-06-048 @M @âm
  Kịch bản: US-06-048 âm 2 · Vượt ngưỡng hàng loạt
    Biết với HTTT: mục đích PH-09 cho phép tìm
    Khi vượt ngưỡng hàng loạt
    Thì hệ thống từ chối với ERR-06-038 (403)
    Và người dùng thấy thông báo "Anh/chị đã xem quá {n} bản ghi trong {phút} phút. Truy cập hàng loạt cần phê duyệt."

  @US-06-049 @FR-06-049 @M
  Kịch bản: US-06-049 dương · Xuất dữ liệu chủ có kiểm soát
    Biết mục đích xuất được PH-09 ghi nhận
    Khi UI-06-15 "Đề nghị xuất"
    Thì hệ thống trả `202`; `exportId`, `status`; khi `READY`: liên kết tải ký thời hạn
    Và đề nghị và lượt tải lưu 5 năm cùng nhật ký kiểm toán
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-049 @FR-06-049 @M @âm
  Kịch bản: US-06-049 âm 1 · Vượt giới hạn hoặc chưa duyệt
    Biết mục đích xuất được PH-09 ghi nhận
    Khi vượt giới hạn hoặc chưa duyệt
    Thì hệ thống từ chối với ERR-06-041 (422)
    Và người dùng thấy thông báo "Yêu cầu xuất vượt {n} bản ghi hoặc chưa được chấp thuận."

  @US-06-049 @FR-06-049 @M @âm
  Kịch bản: US-06-049 âm 2 · Tệp hết hạn
    Biết mục đích xuất được PH-09 ghi nhận
    Khi tệp hết hạn
    Thì hệ thống từ chối với ERR-06-042 (410)
    Và người dùng thấy thông báo "Tệp xuất đã hết hạn tải. Tạo đề nghị mới nếu còn cần."

  @US-06-050 @FR-06-050 @M
  Kịch bản: US-06-050 dương · Phát sự kiện thay đổi bản ghi vàng
    Biết topic `{tenant}.mdm.*` đã cấp phát ở PH-10
    Khi commit giao dịch có bản ghi outbox (FR-06-034, 036…040, 042, 044, 053)
    Thì sự kiện trên topic; ví dụ dưới
    Và mỗi thay đổi đã commit có đúng một sự kiện (ít nhất một lần, bên nhận khử trùng theo `id`)
    Và sự kiện được phát: EVT-06-01…06, 14

  @US-06-050 @FR-06-050 @M @âm
  Kịch bản: US-06-050 âm 1 · Kafka không khả dụng
    Biết topic `{tenant}.mdm.*` đã cấp phát ở PH-10
    Khi Kafka không khả dụng
    Thì hệ thống từ chối với ERR-06-109
    Và người dùng thấy thông báo "Có {n} sự kiện dữ liệu chủ chưa phát được quá {phút} phút."

  @US-06-051 @FR-06-051 @S
  Kịch bản: US-06-051 dương · Đăng ký nhận cập nhật cho HTTT
    Biết HTTT `ACTIVE` ở PH-01; mục đích PH-09
    Khi UI-06-15 tab "Đăng ký nhận"
    Thì hệ thống trả `201`; đăng ký kèm `status`, `subscriptionRef`
    Và subscription ở PH-10 gắn đăng ký
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-051 @FR-06-051 @S @âm
  Kịch bản: US-06-051 âm 1 · Thiếu thỏa thuận hoặc mục đích
    Biết HTTT `ACTIVE` ở PH-01; mục đích PH-09
    Khi thiếu thỏa thuận hoặc mục đích
    Thì hệ thống từ chối với ERR-06-043 (422)
    Và người dùng thấy thông báo "HTTT {mã} chưa có mục đích khai thác dữ liệu chủ được chấp thuận."

  @US-06-052 @FR-06-052 @M
  Kịch bản: US-06-052 dương · Che dữ liệu theo phân loại và mục đích PH-09
    Biết thuộc tính có phân loại (FR-06-004)
    Khi mọi phản hồi có giá trị thuộc tính
    Thì phản hồi đã lọc, che
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-052 @FR-06-052 @M @âm
  Kịch bản: US-06-052 âm 1 · PH-09 không khả dụng và không có bộ đệm
    Biết thuộc tính có phân loại (FR-06-004)
    Khi PH-09 không khả dụng và không có bộ đệm
    Thì áp chính sách chặt nhất (chỉ `PUBLIC`), phản hồi có tiêu đề `X-Datahub-Masking: fallback`

  @US-06-052 @FR-06-052 @M @âm
  Kịch bản: US-06-052 âm 2 · Giải mã lỗi (OpenBao transit không khả dụng)
    Biết thuộc tính có phân loại (FR-06-004)
    Khi giải mã lỗi (OpenBao transit không khả dụng)
    Thì hệ thống từ chối với ERR-06-113
    Và người dùng thấy thông báo "Không giải mã được trường nhạy cảm, đang trả dạng che."

  @US-06-053 @FR-06-053 @M
  Kịch bản: US-06-053 dương · Đồng bộ với CSDL tổng hợp quốc gia qua PH-14
    Biết kết nối PH-14 tới dịch vụ dân cư, ĐKDN đã thông; nguồn `QG-DANCU`, `QG-DKDN` loại `NATIONAL_DB` `ACTIVE`; đồng bộ không ở `PAUSED`
    Khi sự kiện thay đổi từ PH-14 (chiều xuống); lịch đối chiếu hằng đêm; "Chạy đồng bộ" ở UI-06-14
    Thì hệ thống trả `202`; `runId`; trạng thái: `checked`, `discrepancies`, `ratio`, `applied`, `paused`
    Và `nationalSyncedAt` cập nhật; lệch chưa xử lý nằm ở FR-06-054
    Và sự kiện được phát: EVT-06-02; EVT-06-12; EVT-06-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-053 @FR-06-053 @M @âm
  Kịch bản: US-06-053 âm 1 · PH-14 không khả dụng
    Biết kết nối PH-14 tới dịch vụ dân cư, ĐKDN đã thông; nguồn `QG-DANCU`, `QG-DKDN` loại `NATIONAL_DB` `ACTIVE`; đồng bộ không ở `PAUSED`
    Khi PH-14 không khả dụng
    Thì hệ thống từ chối với ERR-06-106
    Và người dùng thấy thông báo "Chưa kết nối được dịch vụ quốc gia từ {thời điểm}. Tra cứu nội bộ vẫn hoạt động."

  @US-06-053 @FR-06-053 @M @âm
  Kịch bản: US-06-053 âm 2 · Lệch vượt ngưỡng
    Biết kết nối PH-14 tới dịch vụ dân cư, ĐKDN đã thông; nguồn `QG-DANCU`, `QG-DKDN` loại `NATIONAL_DB` `ACTIVE`; đồng bộ không ở `PAUSED`
    Khi lệch vượt ngưỡng
    Thì hệ thống từ chối với ERR-06-107
    Và người dùng thấy thông báo "Đồng bộ tự động đã tạm dừng: tỷ lệ lệch {x}% vượt 5%. Điều tra trước khi tiếp tục."

  @US-06-054 @FR-06-054 @M
  Kịch bản: US-06-054 dương · Xử lý danh sách lệch đồng bộ quốc gia
    Biết có lệch `OPEN`
    Khi UI-06-14 tab "Danh sách lệch"
    Thì hệ thống trả `200`; `processed`, `skipped[]`
    Và lệch không còn `OPEN` hoặc có lý do giữ mở
    Và sự kiện được phát: EVT-06-02 khi áp giá trị
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-054 @FR-06-054 @M @âm
  Kịch bản: US-06-054 âm 1 · Giữ địa phương cho thuộc tính thẩm quyền
    Biết có lệch `OPEN`
    Khi giữ địa phương cho thuộc tính thẩm quyền
    Thì hệ thống từ chối với ERR-06-035 (422)
    Và người dùng thấy thông báo "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, không giữ giá trị địa phương được."

  @US-06-054 @FR-06-054 @M @âm
  Kịch bản: US-06-054 âm 2 · Thiếu lý do bỏ qua
    Biết có lệch `OPEN`
    Khi thiếu lý do bỏ qua
    Thì hệ thống từ chối với ERR-06-007 (422)
    Và người dùng thấy thông báo "Nhập lý do bỏ qua lệch (tối thiểu 20 ký tự)."

  # ---- EP-06-H · Vận hành

  @US-06-055 @FR-06-055 @M
  Kịch bản: US-06-055 dương · Dashboard chỉ số dữ liệu chủ
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi mở UI-06-01
    Thì hệ thống trả `200`; `metrics` theo bảng ở FR gốc, `series[]`, `bySource[]`

  @US-06-055 @FR-06-055 @M @âm
  Kịch bản: US-06-055 âm 1 · Số liệu cũ hơn 30 phút
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi số liệu cũ hơn 30 phút
    Thì hiển thị nhãn thông báo, không lỗi
    Và người dùng thấy thông báo "Số liệu cập nhật lúc {thời điểm}"

  @US-06-056 @FR-06-056 @M
  Kịch bản: US-06-056 dương · Lịch job, chạy lại và hủy job
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-06-12
    Thì hệ thống trả `200`; lịch; job mới kèm `jobId`
    Và lịch mới có hiệu lực ngay
    Và sự kiện được phát: EVT-06-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-056 @FR-06-056 @M @âm
  Kịch bản: US-06-056 âm 1 · Tham số sai
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tham số sai
    Thì hệ thống từ chối với ERR-06-047 (422)
    Và người dùng thấy thông báo "Lịch {cron} không hợp lệ hoặc dày hơn 1 giờ."

  @US-06-056 @FR-06-056 @M @âm
  Kịch bản: US-06-056 âm 2 · Chạy lại khi bảng kết quả đã xóa
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi chạy lại khi bảng kết quả đã xóa
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Kết quả của job {id} đã hết hạn giữ. Chạy lại từ đầu."

  @US-06-057 @FR-06-057 @M
  Kịch bản: US-06-057 dương · Nhật ký xử lý và nhật ký truy cập
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ghi: mọi lượt truy cập, xử lý
    Thì hệ thống trả `200`; `items[]` nhật ký
    Và nhật ký truy cập giữ 12 tháng trực tuyến, 5 năm WORM

  @US-06-057 @FR-06-057 @M @âm
  Kịch bản: US-06-057 âm 1 · Không ghi được nhật ký truy cập
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi không ghi được nhật ký truy cập
    Thì hệ thống từ chối với ERR-06-039 (503)
    Và người dùng thấy thông báo "Ghi nhật ký truy cập thất bại {n} lần trong 5 phút."

  @US-06-058 @FR-06-058 @M
  Kịch bản: US-06-058 dương · Tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu
    Biết yêu cầu có thông tin xác minh danh tính (kết quả xác thực qua kênh của PH-09 hoặc bản sao giấy tờ đã đối chiếu)
    Khi PH-09 chuyển yêu cầu; DS tạo ở UI-06-16 khi công dân đến trực tiếp
    Thì hệ thống trả `201`; yêu cầu kèm `status`, `dueAt`; báo cáo tải được (mã hóa)
    Và yêu cầu và báo cáo lưu 5 năm
    Và sự kiện được phát: EVT-06-15 (yêu cầu sửa gửi nguồn)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-058 @FR-06-058 @M @âm
  Kịch bản: US-06-058 âm 1 · Chưa xác minh danh tính
    Biết yêu cầu có thông tin xác minh danh tính (kết quả xác thực qua kênh của PH-09 hoặc bản sao giấy tờ đã đối chiếu)
    Khi chưa xác minh danh tính
    Thì hệ thống từ chối với ERR-06-046 (422)
    Và người dùng thấy thông báo "Yêu cầu chưa có thông tin xác minh danh tính của chủ thể dữ liệu."

  @US-06-058 @FR-06-058 @M @âm
  Kịch bản: US-06-058 âm 2 · Gỡ hạn chế khi bản ghi không có cờ `restricted`
    Biết yêu cầu có thông tin xác minh danh tính (kết quả xác thực qua kênh của PH-09 hoặc bản sao giấy tờ đã đối chiếu)
    Khi gỡ hạn chế khi bản ghi không có cờ `restricted`
    Thì hệ thống từ chối với ERR-06-006 (409)
    Và người dùng thấy thông báo "Bản ghi {id} không ở trạng thái hạn chế xử lý."

  @US-06-059 @FR-06-059 @M
  Kịch bản: US-06-059 dương · Chính sách lưu giữ và dọn dữ liệu
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi job `RETENTION_PURGE` hằng ngày; UI-06-17 sửa chính sách
    Thì hệ thống trả `200`; chính sách; báo cáo lượt dọn
    Và đối tượng quá hạn đã xóa, ẩn danh hoặc chuyển lưu trữ lạnh
    Và sự kiện được phát: EVT-06-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-059 @FR-06-059 @M @âm
  Kịch bản: US-06-059 âm 1 · Dưới mức tối thiểu
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dưới mức tối thiểu
    Thì hệ thống từ chối với ERR-06-049 (422)
    Và người dùng thấy thông báo "Thời hạn lưu {loại} không được thấp hơn {n} ngày."

  @US-06-059 @FR-06-059 @M @âm
  Kịch bản: US-06-059 âm 2 · Bị giữ pháp lý
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi bị giữ pháp lý
    Thì hệ thống từ chối với ERR-06-114
    Và người dùng thấy thông báo "bỏ qua {n} đối tượng do giữ pháp lý"

  @US-06-060 @FR-06-060 @M
  Kịch bản: US-06-060 dương · Tham số phân hệ theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-06-17
    Thì hệ thống trả `200`; danh sách tham số, `ETag`
    Và giá trị mới có hiệu lực cho lượt xử lý sau
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-06-060 @FR-06-060 @M @âm
  Kịch bản: US-06-060 âm 1 · Ngoài miền
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ngoài miền
    Thì hệ thống từ chối với ERR-06-047 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} của {khóa} ngoài miền {miền}."

  @US-06-060 @FR-06-060 @M @âm
  Kịch bản: US-06-060 âm 2 · Sửa đồng thời
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi sửa đồng thời
    Thì hệ thống từ chối với ERR-06-004 (409)
    Và người dùng thấy thông báo "Tham số đã được người khác sửa. Tải lại để xem giá trị mới."
