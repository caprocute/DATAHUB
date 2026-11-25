# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-11
Tính năng: TS-07-11 · Xuất danh mục và lịch sử tác vụ

  @TC-07-131 @P1 @Dương
  Kịch bản: TC-07-131 Xuất Excel đồng bộ cho danh mục nhỏ
    # Truy vết: FR-07-024 · API-07-038 · UI-07-02 · LGC-DMDC-013
    Biết CAT-LH.
    Khi gọi `POST /export-jobs` thân `{"catalogCode":"LOAI_HINH_TC","version":"current","format":"XLSX"}` không có `Prefer: respond-async`.
    Và trên UI-07-02, chọn "Xuất" → "Excel".
    Thì `200` trả trực tiếp tệp xlsx; cấu trúc giống tệp mẫu (để nhập lại được), dữ liệu từ dòng 3, đủ 39 (hoặc số hiện hành) bản ghi, cột theo `sortOrder`. KT: có (EXPORT, số dòng, định dạng). EVT: không (xuất đồng bộ không phát EVT-07-08 theo giả định; xem Q07-83).

  @TC-07-132 @P1 @Dương
  Kịch bản: TC-07-132 Xuất CSV UTF-8 có BOM và JSON
    # Truy vết: FR-07-024 · LGC-DMDC-014 · FR-00-030
    Biết CAT-LH.
    Khi xuất `format = CSV`.
    Và xuất `format = JSON`.
    Và nhập lại tệp CSV vừa xuất vào một bản nháp bằng UPSERT.
    Thì CSV bắt đầu BOM, mở đúng tiếng Việt trên Excel; JSON là mảng đối tượng theo lược đồ API-07-048. Bước 3: mọi dòng `UNCHANGED` (khứ hồi xuất, nhập không mất dữ liệu).

  @TC-07-133 @P1 @Dương
  Kịch bản: TC-07-133 Xuất lớn chạy nền
    # Truy vết: FR-07-024 · API-07-038, 039 · EVT-07-08 · FR-00-031
    Biết CAT-BIG.
    Khi gọi `POST /export-jobs` với `format = XLSX`.
    Và thăm dò `GET /export-jobs/{jobId}`.
    Và tải tệp qua `downloadUrl`.
    Thì bước 1 trả `202` (vượt 10.000 dòng tự chuyển nền dù không có `Prefer`). Tác vụ xong trong ≤ 60 giây (NFR-07-006), `downloadUrl` là URL ký sẵn có `expiresAt` = thời điểm xong + 24 giờ. Tệp đủ 100.000 dòng. EVT-07-08 phát một lần. Có thông báo trong ứng dụng cho người tạo.

  @TC-07-134 @P2 @Âm
  Kịch bản: TC-07-134 Liên kết tải và báo cáo lỗi hết hạn
    # Truy vết: FR-07-024, 025 · API-07-035, 039, 040 · ERR-07-020 · FR-00-031
    Biết tác vụ xuất TC-07-133; tác vụ nhập F-ERR ở trạng thái `VALIDATED` tạo 8 ngày trước (đồng hồ giả lập).
    Khi sau 24 giờ 1 phút (đồng hồ giả lập; URL ký với thời hạn rút ngắn ở CI), tải `downloadUrl`.
    Và gọi `GET /export-jobs/{jobId}`.
    Và gọi `GET /import-jobs/{jobId}/rows?valid=false` của tác vụ nhập 8 ngày tuổi.
    Và gọi `GET /import-jobs?createdBy={người khác}` bằng U-T68-DS-NV.
    Thì bước 1 bị kho đối tượng từ chối (`403`). Bước 2 cho trạng thái `EXPIRED`, không còn `downloadUrl`; người dùng phải xuất lại. Bước 3 trả `409` `ERR-07-020` "Báo cáo không còn" vì dòng đã bị dọn sau 7 ngày; tác vụ vẫn hiện trong lịch sử. Bước 4 không lộ tác vụ của người khác: tham số `createdBy` chỉ có tác dụng với vai trò xem mọi tác vụ, nên kết quả chỉ gồm tác vụ do U-T68-DS-NV tạo.

  @TC-07-135 @P2 @Âm
  Kịch bản: TC-07-135 Xuất phiên bản không tồn tại
    # Truy vết: FR-07-024 · ERR-07-006
    Biết CAT-LH không có v9.
    Khi gọi `POST /export-jobs` với `version` = 9.
    Thì `404` `ERR-07-006`.

  @TC-07-136 @P2 @Dương
  Kịch bản: TC-07-136 Xuất phiên bản lịch sử, không xuất thuộc tính ẩn
    # Truy vết: FR-07-024 · FR-07-006
    Biết v2 có thuộc tính `website` HIDDEN (TC-07-028).
    Khi xuất v1 và v2 dạng CSV.
    Thì tệp v1 có cột `website`, đúng dữ liệu v1. Tệp v2 không có cột `website`.

  @TC-07-137 @P2 @Dương @Âm
  Kịch bản: TC-07-137 Kiểm toán xuất và ứng dụng thiếu scope
    # Truy vết: FR-07-024, 050 · FR-00-040 · NFR-07-015
    Biết U-T68-VW, APP-T68-NOSCOPE.
    Khi U-T68-VW xuất CAT-LH; đọc `GET /catalogs/LOAI_HINH_TC/history`.
    Và APP-T68-NOSCOPE gọi `POST /export-jobs`.
    Thì bước 1: lịch sử có mục EXPORT với người, thời điểm, định dạng, phiên bản. Bước 2 trả 403-PQ.
