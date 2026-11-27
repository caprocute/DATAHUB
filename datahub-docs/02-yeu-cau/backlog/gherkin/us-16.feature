# language: vi
# Sinh tự động từ D02-02/D02-03-PH16 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-16
Tính năng: PH-16 · Báo cáo chỉ tiêu và sổ kiến trúc

  # ---- EP-16-A · Bộ chỉ tiêu

  @US-16-001 @FR-16-001 @M
  Kịch bản: US-16-001 dương · Liệt kê, tìm, lọc bộ chỉ tiêu theo nhóm, trạng thái, cách đo
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi mở UI-16-03 hoặc đổi bộ lọc
    Thì hệ thống trả `200`; `items[]` (`indicatorCode`, `name`, `groupCode`, `kind`, `unit`, `measurement`, `mandatory`, `state`, `activeVersion`, `pendingVersion`, `scope`, `derivedFrom`), `page`, `size`, `totalElements`, `facets`

  @US-16-001 @FR-16-001 @M @âm
  Kịch bản: US-16-001 âm 1 · Tham số sai miền
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số sai miền
    Thì hệ thống từ chối với ERR-16-057 (400)
    Và người dùng thấy thông báo "Tham số {trường} không hợp lệ: {lý do}."

  @US-16-002 @FR-16-002 @M
  Kịch bản: US-16-002 dương · Tạo chỉ tiêu và phiên bản định nghĩa nháp
    Biết nhóm chỉ tiêu tồn tại (FR-16-007); khi mở phiên bản mới, chỉ tiêu không có phiên bản `DRAFT` hoặc `PENDING_APPROVAL` khác
    Khi bấm "+ Chỉ tiêu" ở UI-16-03, hoặc "Tạo phiên bản mới" ở UI-16-04
    Thì hệ thống trả `201`; `indicatorCode`, `version`, `state = DRAFT`, `ETag`; tiêu đề `Location`
    Và chỉ tiêu `state = DRAFT` (khi tạo mới) hoặc giữ `ACTIVE` kèm phiên bản nháp; số đang tính không đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-002 @FR-16-002 @M @âm
  Kịch bản: US-16-002 âm 1 · Mã đã dùng
    Biết nhóm chỉ tiêu tồn tại (FR-16-007); khi mở phiên bản mới, chỉ tiêu không có phiên bản `DRAFT` hoặc `PENDING_APPROVAL` khác
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-16-002 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có."

  @US-16-002 @FR-16-002 @M @âm
  Kịch bản: US-16-002 âm 2 · Mã hoặc tổ hợp thuộc tính sai
    Biết nhóm chỉ tiêu tồn tại (FR-16-007); khi mở phiên bản mới, chỉ tiêu không có phiên bản `DRAFT` hoặc `PENDING_APPROVAL` khác
    Khi mã hoặc tổ hợp thuộc tính sai
    Thì hệ thống từ chối với ERR-16-003 (400)
    Và người dùng thấy thông báo "{Trường} chưa hợp lệ: {yêu cầu}."

  @US-16-003 @FR-16-003 @M
  Kịch bản: US-16-003 dương · Soạn công thức CEL, biến quan sát, thử tính trên dữ liệu kỳ trước
    Biết phiên bản ở `DRAFT`
    Khi sửa ô công thức ở UI-16-04 tab "Công thức", bấm "Thử tính"
    Thì lưu: `200`, phiên bản với `formula`, `variables`, `ETag`
    Và phiên bản vẫn `DRAFT`; không giá trị chính thức nào thay đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-003 @FR-16-003 @M @âm
  Kịch bản: US-16-003 âm 1 · Biểu thức sai cú pháp hoặc sai kiểu
    Biết phiên bản ở `DRAFT`
    Khi biểu thức sai cú pháp hoặc sai kiểu
    Thì hệ thống từ chối với ERR-16-008 (422)
    Và người dùng thấy thông báo "Công thức chưa đúng ở vị trí {dòng}:{cột}: {mô tả}."

  @US-16-003 @FR-16-003 @M @âm
  Kịch bản: US-16-003 âm 2 · Biến chưa có nguồn
    Biết phiên bản ở `DRAFT`
    Khi biến chưa có nguồn
    Thì hệ thống từ chối với ERR-16-009 (422)
    Và người dùng thấy thông báo "Biến {metricCode} chưa có nguồn số liệu nào. Đăng ký nguồn trước khi dùng."

  @US-16-004 @FR-16-004 @M
  Kịch bản: US-16-004 dương · Đặt mục tiêu, ngưỡng ba mức, chiều tốt, đơn vị, làm tròn
    Biết phiên bản ở `DRAFT`
    Khi sửa tab "Mục tiêu và ngưỡng" ở UI-16-04
    Thì hệ thống trả `200`; khối `target` (`baseline`, `target`, `targetDate`, `targetMode`), `thresholds`, `decimals`, `ETag`
    Và phiên bản vẫn `DRAFT`; kỳ đã chốt giữ trạng thái theo ngưỡng cũ (BR-16-033)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-004 @FR-16-004 @M @âm
  Kịch bản: US-16-004 âm 1 · Ngưỡng không đơn điệu hoặc ngoài miền
    Biết phiên bản ở `DRAFT`
    Khi ngưỡng không đơn điệu hoặc ngoài miền
    Thì hệ thống từ chối với ERR-16-010 (422)
    Và người dùng thấy thông báo "Ngưỡng chưa hợp lệ: với chiều {chiều}, mốc xanh phải {lớn hơn hoặc nhỏ hơn} mốc vàng."

  @US-16-004 @FR-16-004 @M @âm
  Kịch bản: US-16-004 âm 2 · Sửa đồng thời
    Biết phiên bản ở `DRAFT`
    Khi sửa đồng thời
    Thì hệ thống từ chối với ERR-16-004 (409)
    Và người dùng thấy thông báo "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."

  @US-16-005 @FR-16-005 @M
  Kịch bản: US-16-005 dương · Gửi duyệt và duyệt bốn mắt phiên bản định nghĩa
    Biết phiên bản `DRAFT` có công thức (trừ `MANUAL`), mục tiêu, ngưỡng; đã thử tính trên nội dung hiện tại
    Khi nút "Gửi duyệt" ở UI-16-04; mục trong hộp duyệt UI-16-12 và "Việc của tôi" (FR-00-070) cho người duyệt
    Thì hệ thống trả `200`; `version`, `state`, `approvedBy`, `approvedAt`, `effectiveFrom`
    Và phiên bản `ACTIVE` hoặc `CHANGES_REQUESTED`; tối đa một `ACTIVE` mỗi chỉ tiêu
    Và sự kiện được phát: EVT-16-01 khi `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-005 @FR-16-005 @M @âm
  Kịch bản: US-16-005 âm 1 · Chưa thử tính nội dung hiện tại
    Biết phiên bản `DRAFT` có công thức (trừ `MANUAL`), mục tiêu, ngưỡng; đã thử tính trên nội dung hiện tại
    Khi chưa thử tính nội dung hiện tại
    Thì hệ thống từ chối với ERR-16-011 (422)
    Và người dùng thấy thông báo "Thử tính phiên bản sau lần sửa cuối trước khi gửi duyệt."

  @US-16-005 @FR-16-005 @M @âm
  Kịch bản: US-16-005 âm 2 · Tự duyệt
    Biết phiên bản `DRAFT` có công thức (trừ `MANUAL`), mục tiêu, ngưỡng; đã thử tính trên nội dung hiện tại
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-16-005 (403)
    Và người dùng thấy thông báo "Anh/chị là người {vai} nên không được {thao tác}."

  @US-16-006 @FR-16-006 @S
  Kịch bản: US-16-006 dương · Ngừng, thay thế chỉ tiêu; lịch sử phiên bản, so sánh
    Biết chỉ tiêu `ACTIVE`; khi thay thế, chỉ tiêu thay có phiên bản `ACTIVE`
    Khi thao tác "Ngừng" hoặc "Thay bằng…" ở UI-16-03; tab "Lịch sử" ở UI-16-04
    Thì ngừng: `200`, `state = RETIRED`, `replacedBy`
    Và chỉ tiêu `RETIRED`; giá trị đã tính giữ nguyên
    Và sự kiện được phát: EVT-16-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-006 @FR-16-006 @S @âm
  Kịch bản: US-16-006 âm 1 · Còn báo cáo đang duyệt dùng chỉ tiêu
    Biết chỉ tiêu `ACTIVE`; khi thay thế, chỉ tiêu thay có phiên bản `ACTIVE`
    Khi còn báo cáo đang duyệt dùng chỉ tiêu
    Thì hệ thống từ chối với ERR-16-013 (409)
    Và người dùng thấy thông báo "Chỉ tiêu {mã} đang có trong {n} báo cáo chờ duyệt. Hoàn tất các báo cáo này trước khi ngừng."

  @US-16-007 @FR-16-007 @S
  Kịch bản: US-16-007 dương · Quản lý nhóm chỉ tiêu và trọng số điểm nhóm
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tab "Nhóm và trọng số" ở UI-16-03
    Thì hệ thống trả `200`; `groups[]`, `effectiveFrom`, `ETag`
    Và cấu hình nhóm mới cho kỳ chưa chốt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-007 @FR-16-007 @S @âm
  Kịch bản: US-16-007 âm 1 · Tổng trọng số khác 100
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tổng trọng số khác 100
    Thì hệ thống từ chối với ERR-16-012 (422)
    Và người dùng thấy thông báo "Tổng trọng số năm nhóm đang là {tổng}. Điều chỉnh cho bằng 100."

  @US-16-008 @FR-16-008 @M
  Kịch bản: US-16-008 dương · Kế thừa bộ chỉ tiêu mẫu COMMON, nhận cập nhật mẫu
    Biết mẫu ở `COMMON` có phiên bản `ACTIVE`
    Khi PH-20 khởi tạo tenant (tự kế thừa); TA bấm "Kế thừa từ mẫu" hoặc mở thông báo "Mẫu có bản mới" ở UI-16-03
    Thì kế thừa: `201`, `adopted[]`, `skipped[]`
    Và chỉ tiêu của tenant `ACTIVE` (khi khởi tạo) hoặc phiên bản `DRAFT` mới chờ duyệt; mẫu không tự áp lên tỉnh
    Và sự kiện được phát: EVT-16-01 cho mỗi chỉ tiêu `ACTIVE` khi khởi tạo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-008 @FR-16-008 @M @âm
  Kịch bản: US-16-008 âm 1 · Chỉ tiêu đã kế thừa
    Biết mẫu ở `COMMON` có phiên bản `ACTIVE`
    Khi chỉ tiêu đã kế thừa
    Thì hệ thống từ chối với ERR-16-002 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có."

  @US-16-008 @FR-16-008 @M @âm
  Kịch bản: US-16-008 âm 2 · Xung đột tùy biến chưa giải quyết
    Biết mẫu ở `COMMON` có phiên bản `ACTIVE`
    Khi xung đột tùy biến chưa giải quyết
    Thì hệ thống từ chối với ERR-16-055 (409)
    Và người dùng thấy thông báo "Trường {trường} đã được tỉnh tùy biến và mẫu cũng thay đổi. Chọn giữ bản nào."

  # ---- EP-16-B · Nguồn số liệu

  @US-16-009 @FR-16-009 @M
  Kịch bản: US-16-009 dương · Đăng ký nguồn và hợp đồng chỉ số
    Biết với `EVENT`, topic đã được PH-10 cấp và PH-16 có quyền đọc (FR-10-067); với `PULL_API`, phân hệ nguồn đã cấp scope đọc chỉ số cho tài khoản dịch vụ PH-16
    Khi bấm "+ Nguồn" ở UI-16-05; tenant mới nhận sẵn các nguồn mặc định khi kế thừa bộ mẫu (FR-16-008)
    Thì hệ thống trả `201` hoặc `200`; `sourceCode`, `sourceType`, `state`, `contract.metricCodes[]`, `priority`, `ETag`
    Và nguồn `ACTIVE`; bộ tiêu thụ hoặc lịch kéo được bật trong ≤ 60 giây
    Và sự kiện được phát: EVT-16-03 (`ACTIVE`, `RETIRED`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-009 @FR-16-009 @M @âm
  Kịch bản: US-16-009 âm 1 · Cấu hình thiếu
    Biết với `EVENT`, topic đã được PH-10 cấp và PH-16 có quyền đọc (FR-10-067); với `PULL_API`, phân hệ nguồn đã cấp scope đọc chỉ số cho tài khoản dịch vụ PH-16
    Khi cấu hình thiếu
    Thì hệ thống từ chối với ERR-16-015 (422)
    Và người dùng thấy thông báo "Nguồn loại {loại} cần {trường}. Bổ sung trước khi lưu."

  @US-16-009 @FR-16-009 @M @âm
  Kịch bản: US-16-009 âm 2 · Thử thất bại
    Biết với `EVENT`, topic đã được PH-10 cấp và PH-16 có quyền đọc (FR-10-067); với `PULL_API`, phân hệ nguồn đã cấp scope đọc chỉ số cho tài khoản dịch vụ PH-16
    Khi thử thất bại
    Thì hệ thống từ chối với ERR-16-016 (422)
    Và người dùng thấy thông báo "Không đọc được dữ liệu từ nguồn {mã}: {lý do}. Kiểm tra quyền và cấu hình."

  @US-16-010 @FR-16-010 @M
  Kịch bản: US-16-010 dương · Tiếp nhận quan sát từ sự kiện Kafka, idempotent, chuẩn hóa
    Biết nguồn `EVENT` ở `ACTIVE` hoặc `STALE`
    Khi bản tin mới trên topic của nguồn, ví dụ EVT-08-14 `t68.dq.kpi.published.v1`, EVT-02-13, EVT-19-07
    Thì số của phân hệ nguồn có trên bảng điều khiển trong vòng một phút; nguồn chuyển `ACTIVE` nếu đang `STALE`
    Và quan sát được ghi đúng một lần; `lastObservedAt` của nguồn cập nhật
    Và sự kiện được phát: EVT-16-03 khi nguồn đổi trạng thái do có số mới

  @US-16-010 @FR-16-010 @M @âm
  Kịch bản: US-16-010 âm 1 · Lược đồ không khớp
    Biết nguồn `EVENT` ở `ACTIVE` hoặc `STALE`
    Khi lược đồ không khớp
    Thì hệ thống từ chối với ERR-16-105
    Và người dùng thấy thông báo "Bản tin không đúng lược đồ {schemaRef}: {chi tiết}."

  @US-16-010 @FR-16-010 @M @âm
  Kịch bản: US-16-010 âm 2 · Chỉ số ngoài hợp đồng
    Biết nguồn `EVENT` ở `ACTIVE` hoặc `STALE`
    Khi chỉ số ngoài hợp đồng
    Thì hệ thống từ chối với ERR-16-102
    Và người dùng thấy thông báo "Chỉ số {metricCode} không thuộc hợp đồng của nguồn {mã}."

  @US-16-011 @FR-16-011 @M
  Kịch bản: US-16-011 dương · Kéo API chỉ số của phân hệ theo lịch, đọc bù khi lỡ sự kiện
    Biết nguồn `PULL_API` không ở `PAUSED`, `RETIRED`; hoặc nguồn `EVENT` có khai báo `backfillEndpoint` (ví dụ API-08-122 của PH-08 với scope `dq.read`)
    Khi tới lịch `cron` của nguồn; nút "Kéo ngay" hoặc "Đọc bù" ở UI-16-06; kỳ chuyển `COLLECTING` mà biến của nguồn chưa có quan sát
    Thì kéo ngay, đọc bù: `202`, `ingestLogId`; kết quả xem ở nhật ký tiếp nhận
    Và quan sát mới được ghi; `failCount` về 0 khi lần kéo đạt
    Và sự kiện được phát: EVT-16-03 khi nguồn đổi trạng thái
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-011 @FR-16-011 @M @âm
  Kịch bản: US-16-011 âm 1 · Gọi API lỗi
    Biết nguồn `PULL_API` không ở `PAUSED`, `RETIRED`; hoặc nguồn `EVENT` có khai báo `backfillEndpoint` (ví dụ API-08-122 của PH-08 với scope `dq.read`)
    Khi gọi API lỗi
    Thì hệ thống từ chối với ERR-16-106
    Và người dùng thấy thông báo "Kéo số từ {mã} lỗi lần {n}: {mã HTTP hoặc lý do}."

  @US-16-011 @FR-16-011 @M @âm
  Kịch bản: US-16-011 âm 2 · Khoảng đọc bù quá 12 tháng
    Biết nguồn `PULL_API` không ở `PAUSED`, `RETIRED`; hoặc nguồn `EVENT` có khai báo `backfillEndpoint` (ví dụ API-08-122 của PH-08 với scope `dq.read`)
    Khi khoảng đọc bù quá 12 tháng
    Thì hệ thống từ chối với ERR-16-060 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần."

  @US-16-012 @FR-16-012 @S
  Kịch bản: US-16-012 dương · Nhận quan sát qua API kpi.ingest
    Biết nguồn `PUSH_API` gắn `clientId` của bên gọi ở `ACTIVE` hoặc `STALE`
    Khi bên gọi gọi `POST /api/kpi/v1/ingest/observations`
    Thì hệ thống trả `202` khi mọi phần tử được nhận; `207` khi có phần tử lỗi; thân `results[]` (`index`, `status` `ACCEPTED`, `DUPLICATE`, `REJECTED`, `code`)
    Và quan sát hợp lệ được ghi đúng một lần
    Và sự kiện được phát: EVT-16-03 khi nguồn đổi trạng thái

  @US-16-012 @FR-16-012 @S @âm
  Kịch bản: US-16-012 âm 1 · Lược đồ sai
    Biết nguồn `PUSH_API` gắn `clientId` của bên gọi ở `ACTIVE` hoặc `STALE`
    Khi lược đồ sai
    Thì hệ thống từ chối với ERR-16-101 (400)
    Và người dùng thấy thông báo "Quan sát thứ {i} sai lược đồ: {trường}."

  @US-16-013 @FR-16-013 @M
  Kịch bản: US-16-013 dương · Theo dõi độ tươi, chuyển STALE, FAILED, cảnh báo
    Biết nguồn không ở `RETIRED`
    Khi bộ quét độ tươi chạy mỗi 10 phút; lần kéo lỗi (FR-16-011); nút "Tạm dừng", "Tiếp tục" ở UI-16-05
    Thì tạm dừng, tiếp tục: `200`, `state`
    Và trạng thái nguồn phản ánh đúng độ tươi; lần tổng hợp sau gắn cờ `STALE_SOURCE` hoặc `MISSING_SOURCE`
    Và sự kiện được phát: EVT-16-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-013 @FR-16-013 @M @âm
  Kịch bản: US-16-013 âm 1 · Nguồn quá hạn
    Biết nguồn không ở `RETIRED`
    Khi nguồn quá hạn
    Thì hệ thống từ chối với ERR-16-107
    Và người dùng thấy thông báo "Nguồn {mã} không có số mới từ {thời điểm}."

  @US-16-013 @FR-16-013 @M @âm
  Kịch bản: US-16-013 âm 2 · Nguồn lỗi liên tiếp
    Biết nguồn không ở `RETIRED`
    Khi nguồn lỗi liên tiếp
    Thì hệ thống từ chối với ERR-16-108
    Và người dùng thấy thông báo "Nguồn {mã} lỗi {n} lần liên tiếp, đã chuyển trạng thái Lỗi."

  @US-16-014 @FR-16-014 @M
  Kịch bản: US-16-014 dương · Nhập số liệu tay kèm bằng chứng
    Biết chỉ tiêu `measurement = MANUAL` hoặc `MIXED`, phiên bản `ACTIVE`; kỳ không ở `CLOSED`
    Khi UI-16-07, chọn "Nhập theo biểu mẫu" hoặc "Nhập từ tệp XLSX"
    Thì hệ thống trả `201` hoặc `200`; `manualId`, `state`, `evidence[]` (`fileName`, `sha256`, `docNumber`, `docDate`)
    Và bản nhập `DRAFT` hoặc `SUBMITTED`; chưa ảnh hưởng giá trị chỉ tiêu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-014 @FR-16-014 @M @âm
  Kịch bản: US-16-014 âm 1 · Giá trị ngoài miền
    Biết chỉ tiêu `measurement = MANUAL` hoặc `MIXED`, phiên bản `ACTIVE`; kỳ không ở `CLOSED`
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-16-019 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} nằm ngoài miền cho phép của chỉ tiêu ({miền})."

  @US-16-014 @FR-16-014 @M @âm
  Kịch bản: US-16-014 âm 2 · Thiếu bằng chứng
    Biết chỉ tiêu `measurement = MANUAL` hoặc `MIXED`, phiên bản `ACTIVE`; kỳ không ở `CLOSED`
    Khi thiếu bằng chứng
    Thì hệ thống từ chối với ERR-16-018 (422)
    Và người dùng thấy thông báo "Số liệu tay cần ít nhất một bằng chứng (tệp hoặc số văn bản)."

  @US-16-015 @FR-16-015 @M
  Kịch bản: US-16-015 dương · Xác nhận hoặc từ chối số liệu tay
    Biết bản nhập `SUBMITTED`; kỳ chưa `CLOSED`
    Khi việc trong UI-16-12 hoặc UI-16-07 tab "Chờ xác nhận"; "Việc của tôi"
    Thì hệ thống trả `200`; `manualId`, `state`, `decidedBy`, `decidedAt`
    Và bản nhập `ACCEPTED` (có quan sát tương ứng) hoặc `REJECTED`
    Và sự kiện được phát: EVT-16-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-015 @FR-16-015 @M @âm
  Kịch bản: US-16-015 âm 1 · Tự xác nhận
    Biết bản nhập `SUBMITTED`; kỳ chưa `CLOSED`
    Khi tự xác nhận
    Thì hệ thống từ chối với ERR-16-005 (403)
    Và người dùng thấy thông báo "Anh/chị là người {vai} nên không được {thao tác}."

  @US-16-015 @FR-16-015 @M @âm
  Kịch bản: US-16-015 âm 2 · Không thuộc vai trò xác nhận của chỉ tiêu
    Biết bản nhập `SUBMITTED`; kỳ chưa `CLOSED`
    Khi không thuộc vai trò xác nhận của chỉ tiêu
    Thì hệ thống từ chối với ERR-16-059 (403)
    Và người dùng thấy thông báo "Anh/chị không thuộc vai trò được giao xác nhận {đối tượng} này."

  @US-16-016 @FR-16-016 @S
  Kịch bản: US-16-016 dương · Tra nhật ký tiếp nhận, quan sát bị loại, xử lý lại
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-16-06 tab "Nhật ký tiếp nhận", "Bị loại", "Quan sát"
    Thì tra: `200`, `items[]`, `page`, `totalElements`
    Và quan sát mới được ghi; kỳ chưa chốt bị đánh dấu cần tính lại
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-016 @FR-16-016 @S @âm
  Kịch bản: US-16-016 âm 1 · Khoảng tra quá dài
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi khoảng tra quá dài
    Thì hệ thống từ chối với ERR-16-060 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần."

  # ---- EP-16-C · Tính toán

  @US-16-017 @FR-16-017 @M
  Kịch bản: US-16-017 dương · Quản lý lịch kỳ báo cáo theo tháng, quý, năm
    Biết `16.period.types` có loại kỳ cần sinh
    Khi bộ lập lịch nội bộ chạy 00:05 hằng ngày; nút "+ Kỳ" ở UI-16-08 (kỳ quá khứ cần cho báo cáo nền)
    Thì hệ thống trả `200` danh sách `items[]` (`periodCode`, `periodType`, `startDate`, `endDate`, `state`, `lastRun`); `201` khi tạo
    Và kỳ `OPEN` hoặc `COLLECTING`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-017 @FR-16-017 @M @âm
  Kịch bản: US-16-017 âm 1 · Mã kỳ sai, trùng hoặc tương lai
    Biết `16.period.types` có loại kỳ cần sinh
    Khi mã kỳ sai, trùng hoặc tương lai
    Thì hệ thống từ chối với ERR-16-024 (422)
    Và người dùng thấy thông báo "Kỳ {mã} không hợp lệ hoặc đã có. Mã kỳ có dạng M-2026-10, Q-2026-Q3, Y-2026."

  @US-16-018 @FR-16-018 @M
  Kịch bản: US-16-018 dương · Chạy tổng hợp theo lịch hoặc thủ công
    Biết kỳ ở `OPEN`, `COLLECTING`, `COMPUTED` hoặc `REOPENED`; không có lần tổng hợp `QUEUED`, `RUNNING` cho kỳ
    Khi lịch `0 30 1 * * *` cho mọi kỳ chưa chốt; nút "Tổng hợp ngay" ở UI-16-08; FR-16-023
    Thì hệ thống trả `202`, `runId`, `state = QUEUED`; chi tiết lần: `trigger`, `state`, `startedAt`, `finishedAt`, `completeness`, `flags[]`, `counts`
    Và một lần tổng hợp kết thúc; giá trị mới là giá trị hiện hành của kỳ
    Và sự kiện được phát: EVT-16-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-018 @FR-16-018 @M @âm
  Kịch bản: US-16-018 âm 1 · Kỳ đã chốt
    Biết kỳ ở `OPEN`, `COLLECTING`, `COMPUTED` hoặc `REOPENED`; không có lần tổng hợp `QUEUED`, `RUNNING` cho kỳ
    Khi kỳ đã chốt
    Thì hệ thống từ chối với ERR-16-022 (409)
    Và người dùng thấy thông báo "Kỳ {kỳ} đã chốt. Mở lại kỳ nếu cần sửa hoặc tính lại."

  @US-16-018 @FR-16-018 @M @âm
  Kịch bản: US-16-018 âm 2 · Đang có lần chạy
    Biết kỳ ở `OPEN`, `COLLECTING`, `COMPUTED` hoặc `REOPENED`; không có lần tổng hợp `QUEUED`, `RUNNING` cho kỳ
    Khi đang có lần chạy
    Thì hệ thống từ chối với ERR-16-023 (409)
    Và người dùng thấy thông báo "Kỳ {kỳ} đang được tổng hợp (bắt đầu {thời điểm}). Chờ lần này xong."

  @US-16-019 @FR-16-019 @M
  Kịch bản: US-16-019 dương · Tính giá trị chỉ tiêu theo phiên bản công thức có hiệu lực, lưu dòng truy nguồn
    Biết lần tổng hợp `RUNNING`
    Khi bước 3 của FR-16-018
    Thì bản ghi giá trị: `indicatorCode`, `periodCode`, `value`, `displayValue`, `versionUsed`, `lineage`
    Và giá trị của lần tổng hợp được ghi; lần trước giữ để so sánh

  @US-16-019 @FR-16-019 @M @âm
  Kịch bản: US-16-019 âm 1 · Công thức lỗi lúc tính
    Biết lần tổng hợp `RUNNING`
    Khi công thức lỗi lúc tính
    Thì hệ thống từ chối với ERR-16-109
    Và người dùng thấy thông báo "Chỉ tiêu {mã}: công thức lỗi khi tính ({lý do}). Giá trị để trống."

  @US-16-020 @FR-16-020 @M
  Kịch bản: US-16-020 dương · Đánh giá độ đầy đủ, gắn PARTIAL, cờ thiếu nguồn
    Biết giá trị chỉ tiêu vừa tính (FR-16-019)
    Khi bước 3 của FR-16-018, sau mỗi chỉ tiêu
    Thì trên giá trị: `completeness`, `flags[]`, `missingMetrics[]`
    Và mọi giá trị có nhãn độ đầy đủ

  @US-16-020 @FR-16-020 @M @âm
  Kịch bản: US-16-020 âm 1 · Thiếu nguồn
    Biết giá trị chỉ tiêu vừa tính (FR-16-019)
    Khi thiếu nguồn
    Thì hệ thống từ chối với ERR-16-111
    Và người dùng thấy thông báo "Thiếu số liệu từ {nguồn} cho kỳ {kỳ}."

  @US-16-020 @FR-16-020 @M @âm
  Kịch bản: US-16-020 âm 2 · Số liệu tay chờ xác nhận
    Biết giá trị chỉ tiêu vừa tính (FR-16-019)
    Khi số liệu tay chờ xác nhận
    Thì hệ thống từ chối với ERR-16-112
    Và người dùng thấy thông báo "Chỉ tiêu {mã} chờ xác nhận số liệu tay."

  @US-16-021 @FR-16-021 @M
  Kịch bản: US-16-021 dương · Đánh giá trạng thái so mục tiêu, ngưỡng; phát cảnh báo chệch
    Biết giá trị có độ đầy đủ (FR-16-020)
    Khi bước 3 của FR-16-018
    Thì trên giá trị: `status`, `threshold` vùng; danh sách thay đổi trạng thái của kỳ
    Và mọi giá trị có trạng thái; lịch sử thay đổi trạng thái được ghi
    Và sự kiện được phát: EVT-16-06

  @US-16-022 @FR-16-022 @S
  Kịch bản: US-16-022 dương · Tính điểm nhóm, xu hướng, chênh lệch so kỳ trước, cùng kỳ năm trước
    Biết mọi chỉ tiêu của lần tổng hợp đã có trạng thái
    Khi cuối bước 3 của FR-16-018
    Thì hệ thống trả `groupScores[]` (`groupCode`, `score`, `coverage`, `weight`); trên giá trị: `delta`, `deltaYoY`, `trend`
    Và điểm nhóm của lần tổng hợp được ghi

  @US-16-023 @FR-16-023 @M
  Kịch bản: US-16-023 dương · Tính lại khi có số liệu trễ hoặc đổi công thức
    Biết kỳ `COMPUTED` hoặc `REOPENED`
    Khi quan sát mới hoặc số tay `ACCEPTED` cho kỳ đã tính (FR-16-010, 015); phiên bản định nghĩa `ACTIVE` mới có hiệu lực trong kỳ (FR-16-005); nút "Tính lại" ở UI-16-09
    Thì hệ thống trả `202`, `runId`
    Và có lần tổng hợp mới; giá trị cũ giữ trong lịch sử lần tổng hợp
    Và sự kiện được phát: EVT-16-05 (qua FR-16-018)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-023 @FR-16-023 @M @âm
  Kịch bản: US-16-023 âm 1 · Kỳ đã chốt
    Biết kỳ `COMPUTED` hoặc `REOPENED`
    Khi kỳ đã chốt
    Thì hệ thống từ chối với ERR-16-022 (409)
    Và người dùng thấy thông báo "Kỳ {kỳ} đã chốt. Mở lại kỳ nếu cần sửa hoặc tính lại."

  @US-16-023 @FR-16-023 @M @âm
  Kịch bản: US-16-023 âm 2 · Tính lại tay khi đang có lần chạy
    Biết kỳ `COMPUTED` hoặc `REOPENED`
    Khi tính lại tay khi đang có lần chạy
    Thì hệ thống từ chối với ERR-16-023 (409)
    Và người dùng thấy thông báo "Kỳ {kỳ} đang được tổng hợp (bắt đầu {thời điểm}). Chờ lần này xong."

  @US-16-024 @FR-16-024 @M
  Kịch bản: US-16-024 dương · Chốt kỳ, mở lại kỳ có lý do
    Biết chốt: kỳ `COMPUTED` hoặc `REOPENED`
    Khi nút "Chốt kỳ", "Mở lại" ở UI-16-08; lịch tự chốt ngày 5 lúc 23:00
    Thì hệ thống trả `200`; `periodCode`, `state`, `closedAt`, `officialRunId`
    Và kỳ `CLOSED` hoặc `REOPENED`
    Và sự kiện được phát: EVT-16-14 khi kỳ `CLOSED` hoặc `REOPENED` (kèm `fromState`, `officialRunId`, lý do mở lại)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-024 @FR-16-024 @M @âm
  Kịch bản: US-16-024 âm 1 · Chưa đủ điều kiện chốt
    Biết chốt: kỳ `COMPUTED` hoặc `REOPENED`
    Khi chưa đủ điều kiện chốt
    Thì hệ thống từ chối với ERR-16-025 (422)
    Và người dùng thấy thông báo "Chưa chốt được kỳ {kỳ}: {lý do}."

  @US-16-024 @FR-16-024 @M @âm
  Kịch bản: US-16-024 âm 2 · Còn báo cáo đang duyệt
    Biết chốt: kỳ `COMPUTED` hoặc `REOPENED`
    Khi còn báo cáo đang duyệt
    Thì hệ thống từ chối với ERR-16-026 (409)
    Và người dùng thấy thông báo "Kỳ {kỳ} có báo cáo đang duyệt. Trả báo cáo về nháp trước khi mở lại kỳ."

  # ---- EP-16-D · Báo cáo

  @US-16-025 @FR-16-025 @M
  Kịch bản: US-16-025 dương · Quản lý mẫu báo cáo
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-16-13 tab "Mẫu báo cáo"
    Thì hệ thống trả `201` hoặc `200`; `templateCode`, `version`, `sections[]`, `ETag`
    Và mẫu `ACTIVE` phiên bản mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-025 @FR-16-025 @M @âm
  Kịch bản: US-16-025 âm 1 · Mẫu không hợp lệ
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mẫu không hợp lệ
    Thì hệ thống từ chối với ERR-16-027 (422)
    Và người dùng thấy thông báo "Mẫu chưa hợp lệ: {phần} {lý do}."

  @US-16-025 @FR-16-025 @M @âm
  Kịch bản: US-16-025 âm 2 · Mã đã dùng
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-16-002 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có."

  @US-16-026 @FR-16-026 @M
  Kịch bản: US-16-026 dương · Lập bản nháp báo cáo từ kỳ đã tính
    Biết kỳ ở `COMPUTED`, `CLOSED` hoặc `REOPENED`; báo cáo `PERIODIC` chính thức yêu cầu kỳ `CLOSED` khi gửi duyệt; mẫu `ACTIVE`
    Khi nút "+ Báo cáo" ở UI-16-10; lịch tự lập bản nháp sau khi chốt kỳ (nếu bật trong mẫu)
    Thì hệ thống trả `201`; `reportCode`, `state = DRAFT`, `runId`, `requiredExplanations[]`, `ETag`
    Và báo cáo `DRAFT` gắn kỳ và lần tổng hợp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-026 @FR-16-026 @M @âm
  Kịch bản: US-16-026 âm 1 · Kỳ chưa tính
    Biết kỳ ở `COMPUTED`, `CLOSED` hoặc `REOPENED`; báo cáo `PERIODIC` chính thức yêu cầu kỳ `CLOSED` khi gửi duyệt; mẫu `ACTIVE`
    Khi kỳ chưa tính
    Thì hệ thống từ chối với ERR-16-028 (422)
    Và người dùng thấy thông báo "Kỳ {kỳ} chưa có kết quả tổng hợp hoặc chưa chốt. Hoàn tất trước khi lập hoặc gửi báo cáo."

  @US-16-026 @FR-16-026 @M @âm
  Kịch bản: US-16-026 âm 2 · Mã đã dùng
    Biết kỳ ở `COMPUTED`, `CLOSED` hoặc `REOPENED`; báo cáo `PERIODIC` chính thức yêu cầu kỳ `CLOSED` khi gửi duyệt; mẫu `ACTIVE`
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-16-002 (409)
    Và người dùng thấy thông báo "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có."

  @US-16-027 @FR-16-027 @M
  Kịch bản: US-16-027 dương · Viết thuyết minh, giải trình chỉ tiêu chệch
    Biết báo cáo `DRAFT`
    Khi soạn ở UI-16-11, phần `NARRATIVE` hoặc ô "Giải trình" cạnh chỉ tiêu
    Thì hệ thống trả `200`; phần hoặc giải trình đã lưu, `missingExplanations[]`, `ETag`
    Và báo cáo vẫn `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-027 @FR-16-027 @M @âm
  Kịch bản: US-16-027 âm 1 · Sửa đồng thời
    Biết báo cáo `DRAFT`
    Khi sửa đồng thời
    Thì hệ thống từ chối với ERR-16-004 (409)
    Và người dùng thấy thông báo "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."

  @US-16-027 @FR-16-027 @M @âm
  Kịch bản: US-16-027 âm 2 · Báo cáo không ở nháp
    Biết báo cáo `DRAFT`
    Khi báo cáo không ở nháp
    Thì hệ thống từ chối với ERR-16-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

  @US-16-028 @FR-16-028 @M
  Kịch bản: US-16-028 dương · Gửi duyệt, yêu cầu sửa, duyệt bốn mắt
    Biết gửi: báo cáo `DRAFT`; với `PERIODIC`, `NATIONAL`: kỳ `CLOSED`
    Khi nút "Gửi duyệt" ở UI-16-11; việc ở UI-16-12
    Thì hệ thống trả `200`; `reportCode`, `state`, `submittedBy`, `reviewedBy`, `comment`
    Và báo cáo `IN_REVIEW`, `APPROVED` hoặc `CHANGES_REQUESTED` (kể cả khi trả về từ `APPROVED`)
    Và sự kiện được phát: EVT-16-07 khi gửi; EVT-16-09 khi `CHANGES_REQUESTED` (từ `IN_REVIEW` hoặc `APPROVED`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-028 @FR-16-028 @M @âm
  Kịch bản: US-16-028 âm 1 · Thiếu chỉ tiêu bắt buộc
    Biết gửi: báo cáo `DRAFT`; với `PERIODIC`, `NATIONAL`: kỳ `CLOSED`
    Khi thiếu chỉ tiêu bắt buộc
    Thì hệ thống từ chối với ERR-16-029 (422)
    Và người dùng thấy thông báo "Chỉ tiêu bắt buộc {danh sách} chưa có số liệu. Báo cáo chính thức chưa gửi duyệt được."

  @US-16-028 @FR-16-028 @M @âm
  Kịch bản: US-16-028 âm 2 · Thiếu số ký hiệu hoặc nơi nhận
    Biết gửi: báo cáo `DRAFT`; với `PERIODIC`, `NATIONAL`: kỳ `CLOSED`
    Khi thiếu số ký hiệu hoặc nơi nhận
    Thì hệ thống từ chối với ERR-16-061 (422)
    Và người dùng thấy thông báo "Báo cáo chính thức cần số ký hiệu và nơi nhận trước khi gửi duyệt."

  @US-16-029 @FR-16-029 @M
  Kịch bản: US-16-029 dương · Công bố báo cáo chính thức: chụp bất biến, ký số, lưu WORM
    Biết báo cáo `APPROVED`
    Khi nút "Công bố" ở UI-16-12
    Thì hệ thống trả `200`; `reportCode`, `version`, `state = PUBLISHED`, `publishedAt`, `contentHash`, `signature` (người ký, thời điểm, chứng thư), `wormRef`
    Và phiên bản báo cáo bất biến; mọi lệnh sửa trả ERR-16-032
    Và sự kiện được phát: EVT-16-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-029 @FR-16-029 @M @âm
  Kịch bản: US-16-029 âm 1 · Ký số không sẵn sàng
    Biết báo cáo `APPROVED`
    Khi ký số không sẵn sàng
    Thì hệ thống từ chối với ERR-16-031 (503)
    Và người dùng thấy thông báo "Dịch vụ ký số đang gián đoạn. Báo cáo vẫn ở trạng thái Đã duyệt, thử công bố lại sau."

  @US-16-029 @FR-16-029 @M @âm
  Kịch bản: US-16-029 âm 2 · Dựng PDF lỗi
    Biết báo cáo `APPROVED`
    Khi dựng PDF lỗi
    Thì hệ thống từ chối với ERR-16-113
    Và người dùng thấy thông báo "Không dựng được tệp báo cáo: {lý do}."

  @US-16-030 @FR-16-030 @S
  Kịch bản: US-16-030 dương · Đính chính báo cáo đã công bố bằng phiên bản mới; rút báo cáo
    Biết báo cáo `PUBLISHED`
    Khi thao tác "Đính chính" hoặc "Rút" ở UI-16-10; cờ "cần đính chính" sau khi kỳ được mở lại (FR-16-024)
    Thì đính chính: `201`, `version`, `state = DRAFT`
    Và bản cũ giữ nguyên trong WORM; không có tệp nào bị xóa
    Và sự kiện được phát: EVT-16-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-030 @FR-16-030 @S @âm
  Kịch bản: US-16-030 âm 1 · Thiếu lý do
    Biết báo cáo `PUBLISHED`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-16-007 (422)
    Và người dùng thấy thông báo "Nhập {nội dung} (tối thiểu {n} ký tự)."

  @US-16-031 @FR-16-031 @M
  Kịch bản: US-16-031 dương · Liệt kê, tìm, xem báo cáo và lịch sử phiên bản
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mở UI-16-10, chọn một báo cáo
    Thì hệ thống trả `200`; `items[]` (`reportCode`, `title`, `reportType`, `periodCode`, `state`, `latestVersion`, `publishedAt`, `needsCorrection`), `versions[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-031 @FR-16-031 @M @âm
  Kịch bản: US-16-031 âm 1 · Không có quyền xem trạng thái
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi không có quyền xem trạng thái
    Thì hệ thống từ chối với ERR-16-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-16-032 @FR-16-032 @C
  Kịch bản: US-16-032 dương · Báo cáo đột xuất theo khoảng thời gian, tập chỉ tiêu tự chọn
    Biết các kỳ tháng trong khoảng đã có kết quả tổng hợp
    Khi "+ Báo cáo" chọn loại "Đột xuất" ở UI-16-10
    Thì hệ thống trả `201`; `reportCode`, `reportType = AD_HOC`, `periodsIncluded[]`, `periodsMissing[]`
    Và báo cáo `AD_HOC` `DRAFT`; không gửi quốc gia (Q16-18)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-032 @FR-16-032 @C @âm
  Kịch bản: US-16-032 âm 1 · Khoảng không hợp lệ
    Biết các kỳ tháng trong khoảng đã có kết quả tổng hợp
    Khi khoảng không hợp lệ
    Thì hệ thống từ chối với ERR-16-033 (422)
    Và người dùng thấy thông báo "Khoảng báo cáo từ {từ} đến {đến} không hợp lệ hoặc vượt 24 tháng."

  # ---- EP-16-E · Xuất, phân phối

  @US-16-033 @FR-16-033 @M
  Kịch bản: US-16-033 dương · Xuất báo cáo, bảng chỉ tiêu ra PDF, XLSX, CSV, JSON
    Biết đối tượng xuất người dùng được xem
    Khi nút "Xuất" ở UI-16-10, UI-16-01, UI-16-02, UI-16-09
    Thì hệ thống trả `202`, `exportId`; trạng thái: `state`, `downloadUrl`, `expiresAt`, `rowCount`, `sha256`
    Và việc xuất `SUCCEEDED`, `FAILED`, sau hạn `EXPIRED`
    Và sự kiện được phát: EVT-16-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-033 @FR-16-033 @M @âm
  Kịch bản: US-16-033 âm 1 · Vượt giới hạn dòng
    Biết đối tượng xuất người dùng được xem
    Khi vượt giới hạn dòng
    Thì hệ thống từ chối với ERR-16-034 (422)
    Và người dùng thấy thông báo "Dữ liệu vượt giới hạn {n} {đơn vị}. Thu hẹp bộ lọc hoặc phạm vi."

  @US-16-033 @FR-16-033 @M @âm
  Kịch bản: US-16-033 âm 2 · Không đủ quyền với đối tượng
    Biết đối tượng xuất người dùng được xem
    Khi không đủ quyền với đối tượng
    Thì hệ thống từ chối với ERR-16-037 (403)
    Và người dùng thấy thông báo "Anh/chị hoặc ứng dụng không được truy cập {đối tượng} này."

  @US-16-034 @FR-16-034 @S
  Kịch bản: US-16-034 dương · Danh sách phân phối và lịch gửi theo kỳ qua kênh thông báo PH-13
    Biết kênh thư công vụ được cấu hình ở PH-13
    Khi UI-16-13 tab "Phân phối"; EVT-16-08 của báo cáo thuộc loại có danh sách
    Thì hệ thống trả `201` hoặc `200`; `distributionCode`, `recipients[]`, `active`
    Và lần gửi được ghi cho từng người nhận
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-034 @FR-16-034 @S @âm
  Kịch bản: US-16-034 âm 1 · Người nhận không hợp lệ
    Biết kênh thư công vụ được cấu hình ở PH-13
    Khi người nhận không hợp lệ
    Thì hệ thống từ chối với ERR-16-036 (422)
    Và người dùng thấy thông báo "Người nhận {địa chỉ} không hợp lệ hoặc không thuộc miền thư công vụ."

  @US-16-035 @FR-16-035 @M
  Kịch bản: US-16-035 dương · API đọc chỉ tiêu, báo cáo cho hệ khác (kpi.read)
    Biết bên gọi được cấp `kpi.read` cho tenant
    Khi gọi `GET /api/kpi/v1/feed/indicator-values` hoặc `/feed/reports`
    Thì hệ thống trả `200`; `items[]` (`indicatorCode`, `periodCode`, `value`, `unit`, `status`, `completeness`, `version`, `reportCode`, `provisional`); tiêu đề `ETag`, `Cache-Control: max-age=300`

  @US-16-035 @FR-16-035 @M @âm
  Kịch bản: US-16-035 âm 1 · Phạm vi không cho phép
    Biết bên gọi được cấp `kpi.read` cho tenant
    Khi phạm vi không cho phép
    Thì hệ thống từ chối với ERR-16-037 (403)
    Và người dùng thấy thông báo "Anh/chị hoặc ứng dụng không được truy cập {đối tượng} này."

  @US-16-035 @FR-16-035 @M @âm
  Kịch bản: US-16-035 âm 2 · Bộ lọc sai
    Biết bên gọi được cấp `kpi.read` cho tenant
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-16-057 (400)
    Và người dùng thấy thông báo "Tham số {trường} không hợp lệ: {lý do}."

  @US-16-036 @FR-16-036 @S
  Kịch bản: US-16-036 dương · Tải bằng chứng công bố (tệp ký, mã băm, nhật ký)
    Biết báo cáo `PUBLISHED`, `SUPERSEDED` hoặc `WITHDRAWN`
    Khi nút "Tải bằng chứng" ở UI-16-10
    Thì hệ thống trả `200`; `verified`, `contentHash`, `signature`, `downloadUrl`, `expiresAt`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-036 @FR-16-036 @S @âm
  Kịch bản: US-16-036 âm 1 · Bằng chứng không khớp
    Biết báo cáo `PUBLISHED`, `SUPERSEDED` hoặc `WITHDRAWN`
    Khi bằng chứng không khớp
    Thì hệ thống từ chối với ERR-16-124
    Và người dùng thấy thông báo "Bản lưu của báo cáo {mã} không khớp mã băm đã công bố. Đã báo cán bộ an toàn thông tin."

  @US-16-037 @FR-16-037 @S
  Kịch bản: US-16-037 dương · Cung cấp thẻ chỉ tiêu cho trang Tổng quan /tong-quan
    Biết tenant có ít nhất một kỳ đã tính
    Khi trang `/tong-quan` tải thẻ của PH-16
    Thì hệ thống trả `200`; `cards[]` (`indicatorCode`, `name`, `displayValue`, `unit`, `status`, `trend`, `periodCode`, `link`)

  @US-16-037 @FR-16-037 @S @âm
  Kịch bản: US-16-037 âm 1 · Không có quyền
    Biết tenant có ít nhất một kỳ đã tính
    Khi không có quyền
    Thì hệ thống từ chối với ERR-00-403

  # ---- EP-16-F · Bảng điều khiển

  @US-16-038 @FR-16-038 @M
  Kịch bản: US-16-038 dương · Bảng điều khiển tổng quan năm nhóm cho lãnh đạo
    Biết có ít nhất một kỳ đã tính
    Khi mở `/giam-sat/chi-tieu`
    Thì hệ thống trả `200`; `overallScore`, `groups[]`, `statusCounts`, `attention[]`, `series[]`, `flags[]`, `provisional`

  @US-16-038 @FR-16-038 @M @âm
  Kịch bản: US-16-038 âm 1 · Kỳ không tồn tại
    Biết có ít nhất một kỳ đã tính
    Khi kỳ không tồn tại
    Thì hệ thống từ chối với ERR-16-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-16-039 @FR-16-039 @M
  Kịch bản: US-16-039 dương · Chi tiết chỉ tiêu: chuỗi thời gian, mục tiêu, nguồn, truy tới quan sát
    Biết chỉ tiêu tồn tại
    Khi bấm một chỉ tiêu ở UI-16-01; mở `/giam-sat/chi-tieu/chi-so/{ma}`
    Thì hệ thống trả `200`; `definition`, `series[]` (`periodCode`, `value`, `status`, `completeness`, `version`), `targetLine`, `lineage` khi yêu cầu

  @US-16-039 @FR-16-039 @M @âm
  Kịch bản: US-16-039 âm 1 · Chỉ tiêu không có
    Biết chỉ tiêu tồn tại
    Khi chỉ tiêu không có
    Thì hệ thống từ chối với ERR-16-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  @US-16-039 @FR-16-039 @M @âm
  Kịch bản: US-16-039 âm 2 · Khoảng quá dài
    Biết chỉ tiêu tồn tại
    Khi khoảng quá dài
    Thì hệ thống từ chối với ERR-16-060 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần."

  @US-16-040 @FR-16-040 @S
  Kịch bản: US-16-040 dương · Lọc theo kỳ, nhóm, trạng thái; so sánh hai kỳ
    Biết hai kỳ cùng loại đều đã tính
    Khi bật "So sánh" ở UI-16-01 hoặc UI-16-02
    Thì hệ thống trả `200`; `items[]` (`indicatorCode`, `valueA`, `valueB`, `delta`, `deltaPct`, `statusA`, `statusB`, `definitionChanged`)

  @US-16-040 @FR-16-040 @S @âm
  Kịch bản: US-16-040 âm 1 · Hai kỳ khác loại
    Biết hai kỳ cùng loại đều đã tính
    Khi hai kỳ khác loại
    Thì hệ thống từ chối với ERR-16-057 (400)
    Và người dùng thấy thông báo "Tham số {trường} không hợp lệ: {lý do}."

  @US-16-041 @FR-16-041 @C
  Kịch bản: US-16-041 dương · So sánh liên tenant ẩn danh cho quản trị nền tảng
    Biết ít nhất `16.compare.min-tenants` tenant có giá trị chính thức của chỉ tiêu trong kỳ
    Khi mở UI-16-18
    Thì hệ thống trả `200`; `distribution`, `tenants[]` (`alias`, `value`, `status`), `tenantCount`, và `rank`, `peerCount` của tenant gọi (ẩn danh, chỉ khi tenant cho phép so sánh)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-041 @FR-16-041 @C @âm
  Kịch bản: US-16-041 âm 1 · Không đủ tenant
    Biết ít nhất `16.compare.min-tenants` tenant có giá trị chính thức của chỉ tiêu trong kỳ
    Khi không đủ tenant
    Thì hệ thống từ chối với ERR-16-038 (422)
    Và người dùng thấy thông báo "Cần ít nhất {n} tỉnh có số chính thức để so sánh."

  @US-16-042 @FR-16-042 @S
  Kịch bản: US-16-042 dương · Theo dõi tình trạng thu thập, tính toán (vận hành)
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-16-08 tab "Vận hành"
    Thì hệ thống trả `200`; `sources`, `runs[]`, `exports`, `national`, `outboxLagSeconds`

  @US-16-042 @FR-16-042 @S @âm
  Kịch bản: US-16-042 âm 1 · PO chọn tenant không tồn tại
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi PO chọn tenant không tồn tại
    Thì hệ thống từ chối với ERR-16-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

  # ---- EP-16-G · Sổ kiến trúc

  @US-16-043 @FR-16-043 @M
  Kịch bản: US-16-043 dương · Liệt kê, tìm thành phần kiến trúc theo loại, vòng đời, tuân thủ
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi mở UI-16-14
    Thì hệ thống trả `200`; `items[]` (`componentCode`, `name`, `componentType`, `lifecycle`, `opsStatus`, `origin`, `complianceLevel`, `currentVersion`, `ownerOrgName`, `reconFlag`), `facets`

  @US-16-043 @FR-16-043 @M @âm
  Kịch bản: US-16-043 âm 1 · Bộ lọc sai
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-16-057 (400)
    Và người dùng thấy thông báo "Tham số {trường} không hợp lệ: {lý do}."

  @US-16-044 @FR-16-044 @M
  Kịch bản: US-16-044 dương · Tự đăng ký, cập nhật thành phần từ sự kiện phân hệ nguồn
    Biết tenant đã kế thừa ánh xạ sự kiện mặc định
    Khi sự kiện EVT-01-03 (HTTT `ACTIVE`), EVT-02-05, EVT-02-06 (API công bố, đổi vòng đời), EVT-04-07, EVT-04-09 (luồng triển khai, ngừng), EVT-10-01, EVT-10-04 (topic tạo, ngừng), EVT-05-08 (bộ điều hợp), EVT-14-01 (liên kết quốc gia) …
    Thì sự kiện: không phản hồi
    Và thành phần `AUTO` phản ánh trạng thái mới nhất của nguồn
    Và sự kiện được phát: EVT-16-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-044 @FR-16-044 @M @âm
  Kịch bản: US-16-044 âm 1 · Sự kiện thiếu trường hoặc tham chiếu không tồn tại
    Biết tenant đã kế thừa ánh xạ sự kiện mặc định
    Khi sự kiện thiếu trường hoặc tham chiếu không tồn tại
    Thì hệ thống từ chối với ERR-16-119
    Và người dùng thấy thông báo "Lệch"

  @US-16-044 @FR-16-044 @M @âm
  Kịch bản: US-16-044 âm 2 · API đăng ký sai lược đồ
    Biết tenant đã kế thừa ánh xạ sự kiện mặc định
    Khi API đăng ký sai lược đồ
    Thì hệ thống từ chối với ERR-16-039 (422)
    Và người dùng thấy thông báo "Thành phần {mã} thiếu trường {trường} hoặc loại không hợp lệ."

  @US-16-045 @FR-16-045 @S
  Kịch bản: US-16-045 dương · Khai báo, sửa thành phần thủ công; phiên bản, phụ thuộc
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi "+ Thành phần" ở UI-16-14; sửa ở UI-16-15
    Thì hệ thống trả `201` hoặc `200`; thành phần với `versions[]`, `dependencies[]`, `ETag`
    Và thành phần `origin = MANUAL` hoặc `AUTO` có trường bổ sung
    Và sự kiện được phát: EVT-16-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-045 @FR-16-045 @S @âm
  Kịch bản: US-16-045 âm 1 · Trường do nguồn quản lý
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi trường do nguồn quản lý
    Thì hệ thống từ chối với ERR-16-040 (409)
    Và người dùng thấy thông báo "Trường {trường} do {phân hệ} cập nhật tự động, không sửa tay được."

  @US-16-046 @FR-16-046 @S
  Kịch bản: US-16-046 dương · Cập nhật trạng thái vận hành từ PH-13
    Biết thành phần có ánh xạ tới đối tượng giám sát của PH-13 (`monitorRef`)
    Khi sự kiện trạng thái sức khỏe của PH-13 (mã chờ PH-13, Phụ lục B); kéo API trạng thái của PH-13 mỗi 15 phút khi không có sự kiện
    Thì sổ kiến trúc hiện chấm xanh, vàng, đỏ, xám theo trạng thái thực
    Và `opsStatus` mới nhất được ghi
    Và sự kiện được phát: EVT-16-10 khi đổi `opsStatus`

  @US-16-046 @FR-16-046 @S @âm
  Kịch bản: US-16-046 âm 1 · Mất tin trạng thái
    Biết thành phần có ánh xạ tới đối tượng giám sát của PH-13 (`monitorRef`)
    Khi mất tin trạng thái
    Thì hệ thống từ chối với ERR-16-121
    Và người dùng thấy thông báo "Chưa nhận trạng thái vận hành của {mã} từ {thời điểm}."

  @US-16-047 @FR-16-047 @M
  Kịch bản: US-16-047 dương · Đánh giá tuân thủ theo bộ tiêu chí, xác nhận, miễn trừ có hạn
    Biết bộ tiêu chí `ACTIVE` có tiêu chí áp dụng cho loại thành phần
    Khi nút "Đánh giá" ở UI-16-15 mở ngăn kéo UI-16-16
    Thì hệ thống trả `201` hoặc `200`; `assessmentId`, `state`, `proposedLevel`, `confirmedLevel`, `confirmedBy`; miễn trừ: `waiverId`, `until`
    Và đánh giá `CONFIRMED` hoặc `REJECTED`; thành phần có mức mới
    Và sự kiện được phát: EVT-16-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-047 @FR-16-047 @M @âm
  Kịch bản: US-16-047 âm 1 · Thiếu kết quả hoặc bằng chứng
    Biết bộ tiêu chí `ACTIVE` có tiêu chí áp dụng cho loại thành phần
    Khi thiếu kết quả hoặc bằng chứng
    Thì hệ thống từ chối với ERR-16-043 (422)
    Và người dùng thấy thông báo "Còn {n} tiêu chí bắt buộc chưa có kết quả hoặc tiêu chí không đạt chưa có ghi chú."

  @US-16-047 @FR-16-047 @M @âm
  Kịch bản: US-16-047 âm 2 · Miễn trừ quá hạn tối đa
    Biết bộ tiêu chí `ACTIVE` có tiêu chí áp dụng cho loại thành phần
    Khi miễn trừ quá hạn tối đa
    Thì hệ thống từ chối với ERR-16-044 (422)
    Và người dùng thấy thông báo "Miễn trừ tối đa {n} ngày."

  @US-16-048 @FR-16-048 @S
  Kịch bản: US-16-048 dương · Đối chiếu sổ kiến trúc với phân hệ nguồn, phát hiện lệch, mồ côi
    Biết phân hệ nguồn cung cấp API liệt kê đối tượng (đề nghị đồng bộ)
    Khi lịch Chủ nhật 03:00; nút "Đối chiếu ngay" ở UI-16-14
    Thì hệ thống trả `202`, `reconId`; chi tiết: `items[]` (`kind`, `componentCode`, `sourceRef`, `diff`, `resolution`)
    Và mục lệch ở trạng thái mở hoặc đã xử lý
    Và sự kiện được phát: EVT-16-10 cho thành phần thay đổi khi xử lý
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-048 @FR-16-048 @S @âm
  Kịch bản: US-16-048 âm 1 · Đang có lần đối chiếu
    Biết phân hệ nguồn cung cấp API liệt kê đối tượng (đề nghị đồng bộ)
    Khi đang có lần đối chiếu
    Thì hệ thống từ chối với ERR-16-056 (409)
    Và người dùng thấy thông báo "Đã có lần {việc} đang chạy. Chờ lần này xong."

  @US-16-049 @FR-16-049 @C
  Kịch bản: US-16-049 dương · Xuất sổ kiến trúc, sơ đồ phụ thuộc
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi nút "Xuất sổ" ở UI-16-14, "Xuất sơ đồ" ở UI-16-15
    Thì hệ thống trả `202`, `exportId`
    Và việc xuất được ghi
    Và sự kiện được phát: EVT-16-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-049 @FR-16-049 @C @âm
  Kịch bản: US-16-049 âm 1 · Sơ đồ quá lớn
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi sơ đồ quá lớn
    Thì hệ thống từ chối với ERR-16-034 (422)
    Và người dùng thấy thông báo "Dữ liệu vượt giới hạn {n} {đơn vị}. Thu hẹp bộ lọc hoặc phạm vi."

  # ---- EP-16-H · Gửi quốc gia

  @US-16-050 @FR-16-050 @M
  Kịch bản: US-16-050 dương · Quản lý mẫu gói quốc gia có phiên bản
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi UI-16-17 tab "Mẫu gói" (PA)
    Thì hệ thống trả `201` hoặc `200`; `templateCode`, `version`, `state`, `testResult`
    Và mẫu `ACTIVE` phiên bản mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-050 @FR-16-050 @M @âm
  Kịch bản: US-16-050 âm 1 · Mẫu không hợp lệ
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi mẫu không hợp lệ
    Thì hệ thống từ chối với ERR-16-047 (422)
    Và người dùng thấy thông báo "Mẫu gói {mã} phiên bản {n} chưa hợp lệ: {lý do}."

  @US-16-051 @FR-16-051 @M
  Kịch bản: US-16-051 dương · Lập và gửi gói báo cáo chỉ tiêu qua PH-14
    Biết `16.national.enabled = true`; báo cáo `PUBLISHED` loại `PERIODIC` hoặc `NATIONAL`; mẫu gói `KPI_REPORT` `ACTIVE`
    Khi nút "Gửi quốc gia" ở UI-16-10 hoặc UI-16-17; lịch tự gửi sau công bố nếu tenant bật
    Thì hệ thống trả `201`, `submissionId`, `state = PENDING`, `preview`; gửi: `202`, `state = SENDING`
    Và gói `ACKNOWLEDGED`, `REJECTED` hoặc `FAILED`; nhật ký nộp đầy đủ
    Và sự kiện được phát: EVT-16-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-051 @FR-16-051 @M @âm
  Kịch bản: US-16-051 âm 1 · Gửi quốc gia đang tắt
    Biết `16.national.enabled = true`; báo cáo `PUBLISHED` loại `PERIODIC` hoặc `NATIONAL`; mẫu gói `KPI_REPORT` `ACTIVE`
    Khi gửi quốc gia đang tắt
    Thì hệ thống từ chối với ERR-16-046 (409)
    Và người dùng thấy thông báo "Chức năng gửi quốc gia chưa được bật cho tỉnh."

  @US-16-051 @FR-16-051 @M @âm
  Kịch bản: US-16-051 âm 2 · Báo cáo chưa công bố
    Biết `16.national.enabled = true`; báo cáo `PUBLISHED` loại `PERIODIC` hoặc `NATIONAL`; mẫu gói `KPI_REPORT` `ACTIVE`
    Khi báo cáo chưa công bố
    Thì hệ thống từ chối với ERR-16-052 (422)
    Và người dùng thấy thông báo "Chỉ gửi được báo cáo đã công bố."

  @US-16-052 @FR-16-052 @S
  Kịch bản: US-16-052 dương · Gửi sổ kiến trúc qua PH-14
    Biết `16.national.enabled = true`; mẫu gói `ARCH_REGISTRY` `ACTIVE`
    Khi nút "Gửi sổ kiến trúc" ở UI-16-17; lịch ngày 1 hằng tháng
    Thì hệ thống trả `201`, `submissionId`, `componentCount`, `state`
    Và gói có trạng thái cuối và nhật ký nộp
    Và sự kiện được phát: EVT-16-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-052 @FR-16-052 @S @âm
  Kịch bản: US-16-052 âm 1 · Gói trùng
    Biết `16.national.enabled = true`; mẫu gói `ARCH_REGISTRY` `ACTIVE`
    Khi gói trùng
    Thì hệ thống từ chối với ERR-16-049 (409)
    Và người dùng thấy thông báo "{Nội dung} đã được nộp ngày {ngày} (mã biên nhận {biên nhận}) và chưa thay đổi."

  @US-16-053 @FR-16-053 @M
  Kịch bản: US-16-053 dương · Nhật ký nộp làm bằng chứng, biên nhận, gửi lại khi lỗi
    Biết gói đã được lập
    Khi mỗi lần đổi trạng thái gói; nút "Gửi lại" ở UI-16-17; PH-14 gọi API-16-124
    Thì nhật ký: `200`, `logs[]` (`at`, `action`, `channelMessageId`, `status`, `code`)
    Và nhật ký không sửa, không xóa trước hạn lưu của báo cáo
    Và sự kiện được phát: EVT-16-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-053 @FR-16-053 @M @âm
  Kịch bản: US-16-053 âm 1 · Gửi lại không cho phép
    Biết gói đã được lập
    Khi gửi lại không cho phép
    Thì hệ thống từ chối với ERR-16-050 (409)
    Và người dùng thấy thông báo "Gói {mã} đang ở trạng thái {trạng thái} hoặc đã gửi lại tối đa {n} lần."

  @US-16-053 @FR-16-053 @M @âm
  Kịch bản: US-16-053 âm 2 · Biên nhận không khớp
    Biết gói đã được lập
    Khi biên nhận không khớp
    Thì hệ thống từ chối với ERR-16-124
    Và người dùng thấy thông báo "Biên nhận không khớp mã băm gói đã gửi."

  @US-16-054 @FR-16-054 @C
  Kịch bản: US-16-054 dương · Đối soát sổ kiến trúc, gói đã nộp và chỉ tiêu
    Biết có ít nhất một gói `ACKNOWLEDGED`
    Khi nút "Đối soát" ở UI-16-17; lịch sau mỗi lần nộp sổ kiến trúc
    Thì hệ thống trả `202`, `reconId`; chi tiết: `items[]` (`kind`, `ref`, `expected`, `actual`, `suggestion`)
    Và mục đối soát được ghi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-054 @FR-16-054 @C @âm
  Kịch bản: US-16-054 âm 1 · Đang có lần đối soát
    Biết có ít nhất một gói `ACKNOWLEDGED`
    Khi đang có lần đối soát
    Thì hệ thống từ chối với ERR-16-056 (409)
    Và người dùng thấy thông báo "Đã có lần {việc} đang chạy. Chờ lần này xong."

  # ---- EP-16-I · Quản trị

  @US-16-055 @FR-16-055 @M
  Kịch bản: US-16-055 dương · Tham số phân hệ theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi UI-16-19
    Thì hệ thống trả `200`; `settings[]` (`key`, `value`, `default`, `ceiling`, `updatedBy`, `updatedAt`), `ETag`
    Và giá trị mới áp dụng cho thao tác sau
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-055 @FR-16-055 @M @âm
  Kịch bản: US-16-055 âm 1 · Giá trị ngoài miền hoặc vượt trần
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi giá trị ngoài miền hoặc vượt trần
    Thì hệ thống từ chối với ERR-16-051 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} của {khóa} nằm ngoài miền cho phép ({miền})."

  @US-16-055 @FR-16-055 @M @âm
  Kịch bản: US-16-055 âm 2 · Sửa đồng thời
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi sửa đồng thời
    Thì hệ thống từ chối với ERR-16-004 (409)
    Và người dùng thấy thông báo "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."

  @US-16-056 @FR-16-056 @M
  Kịch bản: US-16-056 dương · Nhật ký kiểm toán thao tác PH-16, tra cứu
    Biết người dùng đã đăng nhập với vai trò kiểm toán viên
    Khi mỗi thao tác có ghi "Kiểm toán: Có" ở chương 6; mở UI-16-20
    Thì hệ thống trả `200`; `items[]` (`at`, `actor`, `role`, `action`, `objectType`, `objectRef`, `before`, `after`, `traceId`)
    Và bản ghi kiểm toán không sửa, không xóa (do PH-13 bảo đảm)

  @US-16-056 @FR-16-056 @M @âm
  Kịch bản: US-16-056 âm 1 · Khoảng tra quá dài
    Biết người dùng đã đăng nhập với vai trò kiểm toán viên
    Khi khoảng tra quá dài
    Thì hệ thống từ chối với ERR-16-060 (400)
    Và người dùng thấy thông báo "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần."

  @US-16-056 @FR-16-056 @M @âm
  Kịch bản: US-16-056 âm 2 · Tồn đọng chuyển kiểm toán
    Biết người dùng đã đăng nhập với vai trò kiểm toán viên
    Khi tồn đọng chuyển kiểm toán
    Thì hệ thống từ chối với ERR-16-123
    Và người dùng thấy thông báo "Kiểm toán PH-16 tồn {n} bản ghi chưa chuyển."

  @US-16-057 @FR-16-057 @S
  Kịch bản: US-16-057 dương · Lưu giữ, xóa dữ liệu theo hạn; giữ báo cáo công bố 10 năm
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi lịch 02:30 hằng ngày
    Thì tình trạng: `200`, `partitions[]`, `lastPurgeAt`, `nextPurgeAt`, `bytesFreed`
    Và dữ liệu quá hạn bị xóa; báo cáo công bố không bị ảnh hưởng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-16-057 @FR-16-057 @S @âm
  Kịch bản: US-16-057 âm 1 · Dọn lỗi
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dọn lỗi
    Thì hệ thống từ chối với ERR-16-122
    Và người dùng thấy thông báo "Lưu giữ"

  @US-16-058 @FR-16-058 @S
  Kịch bản: US-16-058 dương · Chỉ số vận hành của chính PH-16 cho PH-13
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi PH-13 thu chỉ số Prometheus mỗi 30 giây
    Thì chỉ số Prometheus dạng văn bản
