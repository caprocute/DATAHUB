# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-17
Tính năng: TS-07-17 · ĐVHC: sắp xếp, chuyển mã, tra theo thời điểm, dòng lịch sử

  @TC-07-200 @P1 @Dương
  Kịch bản: TC-07-200 Ghi sự kiện sắp xếp vào bản nháp
    # Truy vết: FR-07-045 · API-07-053, 052 · BR-07-021
    Biết U-PA mở bản nháp v4 của `DVHC`, thêm xã `99301`.
    Khi `POST /catalogs/DVHC/versions/draft/successions` với `type = MERGE`, `fromCodes = ["99101","99102"]`, `toCodes = ["99301"]`, `effectiveDate = 2027-01-01`, `legalBasis = "Nghị quyết giả lập số 03/2026"`.
    Và `GET .../versions/draft/successions`.
    Thì bước 1 `201`; `99101`, `99102` trong bản nháp được đặt `DEPRECATED`, `replacedBy = 99301`, `validTo = 2027-01-01`. Bước 2 trả sự kiện vừa ghi. KT: có (SUCCESSION_CREATE).

  @TC-07-201 @P1 @Âm
  Kịch bản: TC-07-201 Sự kiện sắp xếp không hợp lệ
    # Truy vết: FR-07-045 · BR-07-021 · ERR-07-035
    Biết bản nháp v4.
    Khi `MERGE` có một mã nguồn.
    Và `SPLIT` có một mã đích.
    Và mã nguồn không có trong phiên bản hiện hành.
    Và `RENAME` mà mã đích khác mã nguồn.
    Và thiếu `legalBasis`.
    Và sửa tay `replacedBy` của bản ghi ĐVHC qua API-07-028.
    Thì bước 1…5 `422` `ERR-07-035` với lý do cụ thể. Bước 6 `422` `ERR-07-035` ("ĐVHC chỉ ghi kế thừa qua sự kiện sắp xếp").

  @TC-07-202 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-202 Chỉ PLATFORM ghi được ĐVHC; không xóa sự kiện của phiên bản đã phát hành
    # Truy vết: FR-07-044, 045 · API-07-054 · ERR-07-003, 004
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi U-T68-TA ghi sự kiện vào `DVHC`.
    Và U-PA xóa một sự kiện của v2 (đã phát hành).
    Và U-PA xóa sự kiện TC-07-200 trong bản nháp.
    Thì bước 1 `403` `ERR-07-003`. Bước 2 `409` `ERR-07-004`. Bước 3 `204`, các bản ghi nguồn trở lại `ACTIVE` trong bản nháp.

  @TC-07-203 @P1 @Dương @Âm
  Kịch bản: TC-07-203 Phát hành DVHC bắt buộc qua duyệt và phát sự kiện sắp xếp
    # Truy vết: FR-07-044 · BR-07-027 · ERR-07-016 · EVT-07-10
    Biết bản nháp v4 có sự kiện ở TC-07-200.
    Khi U-PA phát hành thẳng (không trình).
    Và U-PA trình; U-PA thứ hai (U-PA2, cùng vai trò) duyệt và phát hành.
    Thì bước 1 `409` `ERR-07-016` (danh mục ĐVHC luôn cần duyệt). Bước 2 thành công; EVT-07-05 và EVT-07-10 phát trên topic `common.*`.

  @TC-07-204 @P1 @Dương
  Kịch bản: TC-07-204 Chuyển mã một bước và hai bước
    # Truy vết: FR-07-046 · API-07-051 · BR-07-022
    Biết mục 2.4.
    Khi `POST /admin-units:convert` với `at = 2026-06-01`, `codes = [{"code":"99001","asOf":"2024-06-01"},{"code":"99005","asOf":"2024-06-01"},{"code":"99004","asOf":"2024-06-01"}]`.
    Thì `200`, cùng thứ tự đầu vào: `99001` `MAPPED` → `99101`, `events` một phần tử `MERGE`; `99005` `MAPPED` → `99201`, `events` hai phần tử `RECODE` rồi `MERGE`; `99004` `UNCHANGED` (chỉ đổi tên), `newName` là tên tại 2026-06-01, `newPath` có mã tỉnh `97`.

  @TC-07-205 @P1 @Dương
  Kịch bản: TC-07-205 Chia tách trả nhiều ứng viên, không tự chọn
    # Truy vết: FR-07-046 · BR-07-022
    Biết mục 2.4.
    Khi chuyển `99003` (`asOf = 2024-06-01`) với `at = 2025-08-01`.
    Và như trên với `at = 2026-06-01`.
    Thì bước 1 `AMBIGUOUS`, `candidates` = `99102`, `99103` kèm ghi chú địa bàn từ sự kiện `SPLIT`, `newCode = null`. Bước 2 `AMBIGUOUS` với `99102`, `99201`.

  @TC-07-206 @P2 @Âm
  Kịch bản: TC-07-206 Đơn vị cấp huyện bị bỏ và mã không tồn tại
    # Truy vết: FR-07-046 · ERR-07-009
    Biết mục 2.4.
    Khi chuyển `971` (`asOf = 2024-06-01`) với `at = 2026-06-01`.
    Và chuyển `12345` (không tồn tại).
    Và chuyển `99001` với `asOf = 2027-01-01` sau `at = 2026-06-01`.
    Thì bước 1 `NOT_FOUND`, ghi chú "đơn vị đã bị giải thể hoặc bãi bỏ cấp", `newPath` có tỉnh `97`. Bước 2 `NOT_FOUND`. Bước 3 phần tử lỗi `ERR-07-009`, các phần tử khác trong lô vẫn có kết quả.

  @TC-07-207 @P2 @Dương
  Kịch bản: TC-07-207 Tra ngược mã mới về mã cũ
    # Truy vết: FR-07-046 · API-07-051
    Biết mục 2.4.
    Khi `direction = NEW_TO_OLD`, `at = 2026-06-01`, `codes = [{"code":"99201","asOf":"2024-06-01"}]`.
    Thì `AMBIGUOUS` với `candidates` = `99003` (ghi chú "một phần"), `99005`.

  @TC-07-208 @P2 @Âm @Biên
  Kịch bản: TC-07-208 Giới hạn lô và không có phiên bản tại thời điểm
    # Truy vết: FR-07-046 · ERR-07-006, 026
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi gửi 1.000 mã (biên), rồi 1.001 mã.
    Và gửi `at = 2019-01-01` (trước v1).
    Thì 1.000 mã trả `200` với p95 ≤ 300 ms ở môi trường PERF; 1.001 mã `400` `ERR-07-026`. Bước 2 `404` `ERR-07-006`.

  @TC-07-209 @P2 @Dương
  Kịch bản: TC-07-209 Chuyển mã bằng tệp trên giao diện
    # Truy vết: FR-07-046 · UI-07-11 · FR-07-024
    Biết F-DVHC-CONV; U-T68-VW.
    Khi mở UI-07-11 tab "Chuyển mã", tải F-DVHC-CONV, chọn ngày đích 2026-06-01, bấm "Chuyển mã".
    Và khi tác vụ xong, tải tệp kết quả.
    Thì tác vụ nhập `mode = ADMIN_UNIT_CONVERT` đi hết hai pha; tệp kết quả cùng định dạng, thêm cột "Mã mới", "Tên mới", "Trạng thái", "Ứng viên"; số dòng bằng tệp vào; tệp hết hạn tải sau 24 giờ. Danh mục `DVHC` không thay đổi.

  @TC-07-210 @P1 @Dương
  Kịch bản: TC-07-210 Tra theo thời điểm qua các phiên bản
    # Truy vết: FR-07-044 · FR-07-026 · API-07-026, 044
    Biết mục 2.4.
    Khi `GET /catalogs/DVHC/tree?at=2024-06-01&root=97`.
    Và `GET /catalogs/DVHC/tree?at=2026-06-01&root=97`.
    Thì bước 1 trả cây ba cấp (tỉnh, huyện `971`, `972`, xã). Bước 2 trả cây hai cấp (tỉnh, xã) đúng các mã của v3.

  @TC-07-211 @P1 @Dương
  Kịch bản: TC-07-211 Dòng lịch sử của một bản ghi
    # Truy vết: FR-07-047 · API-07-050 · UI-07-11
    Biết mục 2.4.
    Khi `GET /catalogs/DVHC/items/99101/lineage`.
    Và mở UI-07-11, chọn `99101`, xem dòng thời gian.
    Thì bước 1 trả hai khoảng tồn tại (2025-07-01…2026-01-01 tên cũ, từ 2026-01-01 tên mới), sự kiện vào `MERGE` từ `99001`, `99002`, sự kiện `RENAME`. Bước 2 hiển thị dòng thời gian và bảng thay thế đọc được bằng trình đọc màn hình (mục 20 của D03-06-PH07).

  @TC-07-212 @P2 @Âm
  Kịch bản: TC-07-212 Dòng lịch sử với mã không tồn tại hoặc danh mục hạn chế
    # Truy vết: FR-07-047 · ERR-07-001, 007, 030
    Biết APP-T68-READ.
    Khi lineage của `DVHC/12345`.
    Và lineage của `KHONG_CO/01`.
    Và lineage của một bản ghi `TRAM_QUAN_TRAC`.
    Thì `404` `ERR-07-007`; `404` `ERR-07-001`; `403` `ERR-07-030`.

  @TC-07-213 @P3 @Dương
  Kịch bản: TC-07-213 Dòng lịch sử của danh mục thường suy từ mã thay thế
    # Truy vết: FR-07-047 · API-07-050
    Biết CAT-LH: v2 ngừng dùng `KH01.L03` với `replacedBy = KH01.L04` (tạo trong ca, chạy tuần tự).
    Khi lineage của `LOAI_HINH_TC/KH01.L03`.
    Thì trả khoảng tồn tại tới ngày hiệu lực của v2 và một sự kiện ra loại `REPLACED` trỏ `KH01.L04`, `derived = true`.
