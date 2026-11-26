# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-20
Tính năng: TS-02-20 · Cam kết chất lượng (SLA) và tuân thủ

  @TC-02-062 @P1 @Dương @Âm
  Kịch bản: TC-02-062 Khai báo SLA, báo trước khi cam kết kém đi
    # Truy vết: FR-02-055 · API-02-073, 074 · UI-02-11 · UC-02-31 · BR-02-028 · ERR-02-003, 023, 014.
    Biết A-DATDAI SLA 99,5 %; `02.sla.worsen-notice-days` = 30; U-T68-SV1, U-T68-VW.
    Khi khai SLA 99 %; khai độ sẵn sàng 120 %; VW khai SLA.
    Thì SLA kém đi có hiệu lực sau 30 ngày, hiện "đang chờ hiệu lực", thông báo bắt buộc; 120 % `400` ERR-02-003; VW 403-PQ.

  @TC-02-063 @P1 @Dương @Biên @Âm
  Kịch bản: TC-02-063 Chốt kỳ SLA: thiếu dữ liệu không kết luận, 3 kỳ liên tiếp không đạt cảnh báo
    # Truy vết: FR-02-056 · API-02-075 · UI-02-11 · UC-02-32 · BR-02-013, 031 · EVT-02-13 · NFR-02-015.
    Biết `02.sla.min-days-data` = 7, `02.sla.min-calls` = 1.000, `02.sla.breach-periods` = 3; số liệu tổng hợp giả lập.
    Khi kỳ 5 ngày dữ liệu; kỳ 900 lượt gọi; ba kỳ đủ dữ liệu liên tiếp dưới cam kết.
    Thì hai kỳ đầu "chưa đủ dữ liệu"; kỳ thứ ba cảnh báo SV, CA, TA trong ≤ 15 phút, EVT: `sla.period-closed`.

  @TC-02-133 @P1 @Biên
  Kịch bản: TC-02-133 Kỳ SLA ở biên: đúng ngưỡng ngày dữ liệu, đúng ngưỡng lượt gọi, kỳ liên tiếp bị ngắt
    # Truy vết: FR-02-056 · API-02-075 · UI-02-11 · UC-02-32 · BR-02-013, 031.
    Biết `02.sla.min-days-data` = 7, `02.sla.min-calls` = 1.000, `02.sla.breach-periods` = 3; số liệu tổng hợp giả lập; cam kết 99,5 %.
    Khi kỳ có 6 ngày dữ liệu; kỳ có đúng 7 ngày; mỗi kỳ 999 và 1.000 lượt gọi, độ sẵn sàng thực tế 99,0 %.
    Và ba kỳ đủ dữ liệu liên tiếp không đạt, nhưng kỳ thứ hai đạt.
    Và hai kỳ không đạt liên tiếp, kỳ thứ ba thiếu dữ liệu, kỳ thứ tư không đạt.
    Thì bước 1: 6 ngày hoặc 999 lượt "chưa đủ dữ liệu", không kết luận; đúng 7 ngày và 1.000 lượt "không đạt". Bước 2: chuỗi bị ngắt, không cảnh báo. Bước 3: kỳ thiếu dữ liệu không đếm và không ngắt chuỗi, nên cảnh báo phát ở kỳ thứ tư (đủ 3 kỳ có kết luận liên tiếp: hai kỳ đầu và kỳ thứ tư). Đây là giả định, cơ sở: BR-02-031 chỉ kết luận ở kỳ đủ dữ liệu.

  @TC-02-134 @P2 @Âm
  Kịch bản: TC-02-134 Đọc SLA và kỳ SLA của tenant khác, phiên bản chưa có cam kết
    # Truy vết: FR-02-055, 056 · API-02-074, 075 · UI-02-11 · UC-02-31, 32 · BR-02-013, 033 · ERR-02-001.
    Biết A-DRAFT chưa khai SLA; A-T01 có SLA; U-T68-VW.
    Khi `GET …/tc-nhap/versions/1.0.0/sla` và `…/sla/periods`.
    Và `GET /apis/tc-chi-t01/versions/1.0.0/sla` và `…/sla/periods`.
    Thì bước 1: `200` với "chưa khai báo cam kết", không báo "đạt"; danh sách kỳ rỗng. Bước 2: `404` ERR-02-001 cùng thân với mã không tồn tại.

  @TC-02-168 @P2 @Dương @Biên @Âm
  Kịch bản: TC-02-168 Tổng hợp tuân thủ SLA toàn tenant: kỳ đủ dữ liệu, API không đạt liên tiếp, nhóm theo mức phân loại
    # Truy vết: FR-02-056 · API-02-097, 075 · UI-02-11 · UC-02-32 · BR-02-013, 031 · ERR-02-003, 034.
    Biết mười API có cam kết SLA: bảy đạt kỳ gần nhất, hai không đạt hai kỳ liên tiếp (`02.sla.breach-periods` = 2), một chưa đủ `02.sla.min-days-data` ngày; hai API chưa khai SLA; PH-13 giả trả số đo; người dùng U-T68-TA, U-T68-VW.
    Khi U-T68-TA gọi `GET /sla/summary`.
    Và gọi `GET /sla/summary?months=36` và `GET /sla/summary?months=0`.
    Và tắt PH-13 giả rồi gọi lại API-02-097.
    Và gọi bằng token tenant T01 cho dữ liệu T68.
    Thì bước 1: `200`, `apisWithCommitment = 10`, `apisWithoutCommitment = 2`, `breachedApis = 2`, `consecutiveBreachApis = 2`, `compliance` tính trên chín API đủ dữ liệu (API thiếu dữ liệu không bị tính là đạt), `groups[]` cộng lại bằng 10, `worstApis[]` nêu hai API. Bước 2: `36` hợp lệ; `0` trả `400` ERR-02-003. Bước 3: `503` ERR-02-034 kèm `retryAfterSeconds`; UI-02-11 hiện "Số liệu cập nhật lúc {thời điểm}", không hiện tỷ lệ giả. Bước 4: không thấy dữ liệu T68.
