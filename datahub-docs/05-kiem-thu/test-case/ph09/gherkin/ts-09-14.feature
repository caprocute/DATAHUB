# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-14
Tính năng: TS-09-14 · Phát hiện khai thác bất thường và báo cáo theo mục đích

  @TC-09-048 @P2 @Dương
  Kịch bản: TC-09-048 Ghi nhận, loại trừ và chuyển cảnh báo thành vụ việc vi phạm
    # Truy vết: FR-09-020 · API-09-079…083 · UI-09-09 · EVT-09-13 · PERM-09-breach
    # Mục đích: Chứng minh vòng đời cảnh báo `OPEN → ACKNOWLEDGED, DISMISSED, ESCALATED`.
    Biết T90; ba cảnh báo `OPEN` (`BULK_ACCESS`, `OFF_HOURS`, `DORMANT_REUSE`); U-T90-DO1, U-T90-SO.
    Khi DO1 `:acknowledge` cảnh báo 1; `:dismiss` cảnh báo 2 kèm lý do 25 ký tự.
    Và SO `:escalate` cảnh báo 3.
    Và `GET /breaches`.
    Thì cảnh báo lần lượt `ACKNOWLEDGED`, `DISMISSED`, `ESCALATED`; có vụ việc `REPORTED` nguồn `ANOMALY` với `detectedAt` là thời điểm cảnh báo; KT: có cho từng thao tác.

  @TC-09-049 @P2 @Âm
  Kịch bản: TC-09-049 Ngưỡng cảnh báo ngoài miền và loại trừ không lý do
    # Truy vết: FR-09-020 · API-09-085, 082 · ERR-09-034, 007, 078
    # Mục đích: Chứng minh kiểm miền ngưỡng cảnh báo và lý do loại trừ.
    Biết T90; U-T90-TA, U-T90-DO1.
    Khi TA `PUT /anomaly-rules` đặt `quota-warn-percent = 99`.
    Và TA đặt `bulk-threshold = 50`.
    Và DO1 `:dismiss` không lý do.
    Thì bước 1 và 2 `422` ERR-09-034 (hoặc ERR-09-078 theo miền `50…95`, `100…100.000`). Bước 3 `422` ERR-09-007.

  @TC-09-050 @P2 @Dương @Âm
  Kịch bản: TC-09-050 Báo cáo khai thác theo mục đích, giới hạn 12 tháng, xuất nền
    # Truy vết: FR-09-021 · API-09-086, 087 · ERR-09-036 · UI-09-01
    # Mục đích: Chứng minh báo cáo theo (HTTT, mục đích, hợp đồng) và giới hạn khoảng thời gian.
    Biết T90; 3 tháng dữ liệu lượt khai thác; U-T90-SO.
    Khi SO `GET /usage-reports?from=2026-09-01&to=2026-11-25`.
    Và đặt khoảng 14 tháng.
    Và `POST /usage-reports:export`.
    Thì bước 1 tổng lượt khớp số báo cáo của PEP. Bước 2 `422` ERR-09-036 "Chọn khoảng thời gian tối đa 12 tháng." Bước 3 `202`, tệp không chứa giá trị DLCN.
