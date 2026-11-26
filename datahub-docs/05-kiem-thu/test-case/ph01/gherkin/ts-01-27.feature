# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-27
Tính năng: TS-01-27 · Danh bạ đầu mối

  @TC-01-104 @P1 @Dương @Bảomật
  Kịch bản: TC-01-104 Tra cứu danh bạ, đầu mối an ninh ẩn
    # Truy vết: FR-01-045 · UC-01-30 · API-01-076, 077 · UI-01-14 · BR-01-027 · ERR-01-001 · CMP-LAW-05.
    Biết U-T68-VW; U-T68-SO; U-T01-OR; tổ chức Sở Tư pháp có ba loại đầu mối.
    Khi VW `GET /directory/contacts?q=Phúc`; `GET /directory/organizations/{orgId}/contacts`.
    Và SO gọi lại.
    Và U-T01-OR gọi với `orgId` của T68.
    Thì bước 1: có đầu mối `BUSINESS`, `TECHNICAL` (họ tên, chức vụ, điện thoại, thư); không có `SECURITY`. Bước 2: SO thấy `SECURITY`. Bước 3: `404-ẩn`.

  @TC-01-105 @P2 @Âm @Bảomật
  Kịch bản: TC-01-105 Giới hạn tốc độ tra cứu
    # Truy vết: FR-01-045 · API-01-076 · BR-01-027 · ERR-01-045.
    Biết U-T68-VW; `directory.rateLimitPerMinute = 60`.
    Khi gọi `GET /directory/contacts` 61 lần trong một phút; U-T68-TO gọi một lần.
    Thì lần 61 `429` ERR-01-045 kèm `Retry-After`; U-T68-TO không bị ảnh hưởng (giới hạn theo người dùng).

  @TC-01-106 @P2 @Dương @Âm
  Kịch bản: TC-01-106 Tổ chức thiếu đầu mối, thư bị trả, nhắc cập nhật
    # Truy vết: FR-01-046 · UC-01-31 · API-01-078 · UI-01-14 · BR-01-013, 028 · ERR-01-010, 050 · EVT-01-14.
    Biết tổ chức "Sở X" có HTTT mà đầu mối kỹ thuật duy nhất bị thư trả lại; `directory.staleMonths = 12`; U-T68-TA1.
    Khi giả lập thư bị trả; chạy tác vụ hằng ngày; `GET /directory/gaps`.
    Và tua 13 tháng; chạy tác vụ.
    Và cán bộ của "Sở X" nộp hồ sơ HTTT mới; chạy tác vụ với tổ chức khác còn đủ đầu mối kỹ thuật.
    Thì bước 1: đầu mối đánh dấu không hoạt động; "Sở X" có trong danh sách thiếu đầu mối; `EVT-01-14`; tổ chức đó không nộp được hồ sơ HTTT mới (ERR-01-010). Bước 2: nhắc cập nhật cho đầu mối lâu không xác nhận. Bước 3: nộp `422` ERR-01-010; tổ chức đủ đầu mối không có cảnh báo và không phát `EVT-01-14`.

  @TC-01-107 @P3 @Dương @Âm @Bảomật
  Kịch bản: TC-01-107 Xuất danh bạ (Đợt 2)
    # Truy vết: FR-01-047 · UC-01-30 · API-01-079, 088 · UI-01-14 · ERR-01-033, 045, 052.
    Biết U-T68-AU; U-T68-TA1; U-T68-OR1.
    Khi AU `POST /directory/contacts:export` với `format = XLSX`, `purpose`.
    Và gọi thiếu `purpose`; OR1 xuất toàn bộ.
    Và gọi liên tục vượt giới hạn.
    Thì `200` hoặc `202`, tệp không chứa đầu mối `SECURITY`; `400` ERR-01-033; `403-PQ`; `429` ERR-01-045. KT: có (mục đích, người xuất).
