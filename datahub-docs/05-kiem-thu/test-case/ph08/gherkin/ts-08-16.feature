# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-16
Tính năng: TS-08-16 · Cổng chất lượng cho PH-06 và giám sát kiểm tra trực tuyến

  @TC-08-084 @P2 @Dương
  Kịch bản: TC-08-084 Cổng chất lượng đầu vào cho PH-06
    # Truy vết: FR-08-035 · API-08-068, 071 · UI-08-20 · BR-08-016
    Biết `mdm-citizen` bật cổng `STRICT`; `S-T90-PH06` (`dq.check`); `mdm-sim` gọi trước khi nạp ứng viên.
    Khi nạp ứng viên thiếu `nationalId`
    Và đổi cổng sang `ADVISORY`, nạp lại
    Thì bước 1 PH-06 từ chối nạp với lý do `DQ_GATE`. Bước 2 nạp được, bản ghi gắn cờ chất lượng, không bị từ chối.

  @TC-08-085 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-08-085 FAIL_OPEN, FAIL_CLOSED khi phụ thuộc lỗi và quá ngân sách
    # Truy vết: FR-08-035 · FR-08-032 · API-08-068 · BR-08-018 · ERR-08-103 · ERR-08-104
    Biết `RS-CITIZEN` có `IN_RDM`; `rdm-sim` trả `503`; ngân sách `08.inline.timeout-ms = 10` và `rdm-sim` trễ 30 ms ở bước 4.
    Khi `FAIL_OPEN`: `POST /checks:evaluate`
    Và `FAIL_CLOSED`: `POST /checks:evaluate`
    Và cổng PH-06 ở `FAIL_CLOSED` nạp ứng viên
    Và `FAIL_CLOSED`, `rdm-sim` bật lại nhưng trễ 30 ms
    Thì bước 1 `200` `PASS` `degraded = true`, thống kê `degraded` tăng. Bước 2 `503` ERR-08-104. Bước 3 PH-06 nhận ERR-08-104, ghi nhật ký nạp. Bước 4 `504` ERR-08-103. Mặc định không đặt là `FAIL_OPEN` (không chặn nạp dữ liệu chủ).

  @TC-08-086 @P2 @Dương @Âm
  Kịch bản: TC-08-086 Thống kê kiểm tra trực tuyến theo phút
    # Truy vết: FR-08-034 · API-08-070 · UI-08-20 · EVT-08-13 · LGC-BUS-027 · PERM-08-read · ERR-08-045
    Biết 1.000 lần gọi trong 10 phút từ hai bên gọi, 120 lần `FAIL` ở `R-CCCD-NN`; U-T90-TO.
    Khi `GET /inline-stats?from=…&to=…&resolution=MINUTE`
    Và `GET /inline-stats?from=2026-01-01&to=2026-11-26&resolution=MINUTE`
    Thì bước 1 `series[]` theo phút, `topRules[]` đầu bảng `R-CCCD-NN`, `p95Ms`; EVT-08-13 gộp tối đa một bản tin mỗi phút mỗi đối tượng mỗi bên gọi, không chứa giá trị bản ghi. Bước 2 `422` ERR-08-045.
