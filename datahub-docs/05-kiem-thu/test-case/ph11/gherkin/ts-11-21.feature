# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-21
Tính năng: TS-11-21 · Giám sát quy trình, phát hiện tắc nghẽn và báo cáo đúng hạn, trễ hạn

  @TC-11-117 @P1 @Dương
  Kịch bản: TC-11-117 Bảng điều khiển giám sát
    # Truy vết: FR-11-058 · API-11-107 · UI-11-19 · BR-11-031 · PERM-11-read
    Biết T98 có 50.000 phiên `RUNNING`, vài phiên `SUSPENDED`, `COMPENSATING`, `FAILED`; việc quá hạn; sự cố mở.
    Khi VW `GET /monitoring/summary`
    Và đếm trực tiếp ở CSDL theo trạng thái
    Và CB-TP gọi API
    Thì số phiên theo trạng thái, việc quá hạn, sự cố mở, outbox tồn khớp số đếm CSDL; CB-TP chỉ thấy phạm vi mình (BR-11-031).

  @TC-11-118 @P2 @Âm
  Kịch bản: TC-11-118 Giám sát sai tham số, thiếu quyền
    # Truy vết: FR-11-058 · API-11-107 · ERR-11-003 · ERR-00-403
    Biết VW; người không vai trò.
    Khi VW `GET /monitoring/summary?window=99d`
    Và người không vai trò gọi API
    Thì bước 1 `400` ERR-11-003. Bước 2 `403` ERR-00-403.

  @TC-11-119 @P2 @Dương @Âm
  Kịch bản: TC-11-119 Phát hiện tắc nghẽn bước và phiên tắc
    # Truy vết: FR-11-059 · API-11-108 · ERR-11-115 · BR-11-019
    Biết `11.bottleneck.minSamples = 30`, `11.bottleneck.factor = 2,0`; bước `guiCuTru` có 40 mẫu, `capTheBHYT` có 12 mẫu; một phiên ở một bước 80 giờ; `11.instance.stuckHours = 72`.
    Khi làm một phiên chờ ở `guiCuTru` quá 2 lần p95
    Và làm một phiên chờ ở `capTheBHYT` quá 2 lần p95
    Và `GET /monitoring/bottlenecks`
    Và CLK +73 giờ cho phiên chờ
    Thì `guiCuTru` được cảnh báo; `capTheBHYT` không (dưới 30 mẫu). Phiên chờ quá 72 giờ: sự cố `STUCK_INSTANCE` (ERR-11-115).

  @TC-11-120 @P2 @Dương @Âm
  Kịch bản: TC-11-120 Báo cáo đúng hạn, trễ hạn
    # Truy vết: FR-11-050 · API-11-094, 095 · UI-11-22 · BR-11-017, 018 · ERR-11-003, 039
    Biết 100 phiên đã đóng, 80 `MET`, 20 `MISSED` (trong đó 5 phiên chỉ trễ khi cộng thời gian chờ bổ sung); VW.
    Khi VW `GET /reports/due?groupBy=orgUnit&from&to`
    Và VW `POST /reports/due:export`
    Và VW gọi với `from` sau `to`
    Và VW gọi với khoảng 400 ngày
    Thì tỷ lệ đúng hạn 80 %; 5 phiên chờ bổ sung tính `MET`; xuất `202` ra tệp có băm; bước 3 `400` ERR-11-003; bước 4 `422` ERR-11-039 "Khoảng thời gian tối đa 366 ngày."
