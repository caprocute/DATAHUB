# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-24
Tính năng: TS-08-24 · Bảng điều khiển, thẻ điểm và so sánh liên tenant

  @TC-08-111 @P1 @Dương
  Kịch bản: TC-08-111 Bảng điều khiển và thẻ điểm tenant
    # Truy vết: FR-08-050, 051 · API-08-104, 105, 106 · UI-08-01, 04 · NFR-08-010 · PERM-08-read
    Biết T90 có `mdm-citizen` điểm 91,45 (10.000 bản ghi) và `src-hotich` điểm 80,00 (30.000 bản ghi); U-T90-DS1, U-T90-VW, U-T90-DO1.
    Khi DS1 `GET /dashboard`
    Và VW `GET /dashboard`
    Và DO1 `GET /dashboard`
    Và DS1 `GET /scorecards/assets/mdm-citizen?asOf=2026-10-31`
    Thì bước 1 `tenantScore` = (91,45 × 10.000 + 80,00 × 30.000) / 40.000 = 82,86; có `domains[]`, `radar`, `trend[]` 13 tháng, `counters{}`, `coverage`. Bước 2 chỉ số tổng hợp, không có liên kết tới danh sách lỗi. Bước 3 phần của ORG-CA nổi bật. Bước 4 trả ảnh chụp bất biến tại thời điểm đó.

  @TC-08-112 @P1 @Âm
  Kịch bản: TC-08-112 Ngoài phạm vi tổ chức, HTTT đọc thẻ điểm không phải của mình, chưa có số liệu
    # Truy vết: FR-08-050, 051 · API-08-104, 106 · BR-08-026 · ERR-08-032, 001
    Biết DO1 (ORG-CA); `S-T90-HTTT-HT` (scope `dq.read`, HTTT hộ tịch); đối tượng `src-moi` chưa đo; tenant T93 chưa có lần đo.
    Khi DO1 `GET /dashboard?orgId=ORG-TC`
    Và `S-T90-HTTT-HT` `GET /scorecards/assets/mdm-org`
    Và DS1 `GET /scorecards/assets/src-moi`
    Và T93 `GET /dashboard`
    Thì bước 1 và 2 `403` ERR-08-032. Bước 3 `404` ERR-08-001. Bước 4 `200` trạng thái trống "Chưa có số liệu. Đăng ký đối tượng đo và chạy lần đo đầu tiên." (không phải lỗi).

  @TC-08-113 @P3 @Dương
  Kịch bản: TC-08-113 So sánh liên tenant ẩn danh
    # Truy vết: FR-08-061 · API-08-128 · UI-08-01 · BR-08-030 · PERM-08-read
    Biết T90…T95 và T96 đặt `08.benchmark.opt-in = true` (6 tenant); U-PA; U-T90-TA.
    Khi PA `GET /platform/benchmarks`
    Và TA T90 `GET /platform/benchmarks`
    Thì có `median`, `p25`, `p75`, `groupSize = 6`, `minGroup`; không nêu tên tenant khác. Với TA có thêm `ownScore`.

  @TC-08-114 @P3 @Âm
  Kịch bản: TC-08-114 Nhóm nhỏ hơn 5 hoặc tenant chưa tham gia
    # Truy vết: FR-08-061 · API-08-128 · BR-08-030 · ERR-08-044
    Biết chỉ 4 tenant đã opt-in; T97 chưa opt-in; U-T97-TA.
    Khi PA `GET /platform/benchmarks`
    Và U-T97-TA `GET /platform/benchmarks`
    Thì bước 1 `422` ERR-08-044. Bước 2 `409` ERR-08-006 ("Tỉnh chưa bật tham gia so sánh chất lượng.").
