# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-18
Tính năng: TS-16-18 · Xuất báo cáo và phân phối theo danh sách

  @TC-16-071 @P1 @Dương
  Kịch bản: TC-16-071 Xuất báo cáo và bảng chỉ tiêu ra bốn định dạng
    # Truy vết: FR-16-033 · API-16-079, 080, 081 · UI-16-10 · EVT-16-13 · BR-16-026, BR-16-027 · NFR-16-010
    Biết T90; U-T90-TO1; `bc-thang-2026-09` `PUBLISHED`; kỳ `M-2026-10` đã tính.
    Khi `POST /exports` `{subject: REPORT, subjectRef: {reportCode: bc-thang-2026-09, version: 1}, format: PDF}`
    Và `POST /exports` `{subject: INDICATOR_VALUES, subjectRef: {periodCode: M-2026-10}, format: XLSX}`
    Và tương tự `CSV` và `JSON`
    Và `GET /exports/{exportId}` đến khi `SUCCEEDED`
    Và `GET /exports/{exportId}/file`
    Thì bước 1, 2 `202`, `state = QUEUED`. Bước 4 `SUCCEEDED`, `rowCount`, `sha256`, `downloadUrl`, `expiresAt` = lúc tạo + 24 giờ. Bước 5 `200` tệp đúng định dạng; PDF theo thể thức NĐ 30/2020. EVT: `export.completed` (EVT-16-13) tới người yêu cầu. Chỉ báo cáo `PUBLISHED` được xuất ra ngoài phân hệ.

  @TC-16-072 @P1 @Âm
  Kịch bản: TC-16-072 Xuất vượt giới hạn dòng, liên kết hết hạn, đối tượng ngoài quyền
    # Truy vết: FR-16-033 · API-16-079, 080, 081 · ERR-16-034, ERR-16-035, ERR-16-037, ERR-16-115 · EVT-16-13 · BR-16-026
    Biết T92 `16.export.max-rows = 1000` với 1.500 quan sát; báo cáo `bc-thang-2026-10` `DRAFT`; liên kết đã tạo cách đây 25 giờ (`clock-sim`).
    Khi Ở T92 `POST /exports` `{subject: OBSERVATIONS, format: CSV}`
    Và U-T90-TO1 `POST /exports` `{subject: REPORT, subjectRef: {reportCode: bc-thang-2026-10}}` (chưa công bố)
    Và `GET /exports/{exportId}/file` sau 25 giờ
    Và U-T91-TO1 `GET /exports/{exportId}` của T90
    Và xuất báo cáo khi bộ dựng tệp bị làm lỗi
    Thì bước 1 `422` ERR-16-034. Bước 2 `403` ERR-16-037. Bước 3 `410` ERR-16-035, `state = EXPIRED`. Bước 4 `404` ERR-16-001 (404-ẩn). Bước 5 `state = FAILED`, `errorCode = ERR-16-115`, EVT-16-13 báo lỗi tới người yêu cầu.

  @TC-16-073 @P2 @Dương @Âm
  Kịch bản: TC-16-073 Danh sách phân phối, gửi khi công bố, người nhận sai, gửi lỗi
    # Truy vết: FR-16-034 · API-16-083, 084, 082, 085 · UI-16-13 · ERR-16-036, ERR-16-116 · EVT-16-08
    Biết T90; U-T90-TA1; `notif-sim` nhận thư; báo cáo kỳ `M-2026-10` được công bố (pub-ok).
    Khi `POST /distributions` `{distributionCode: tc-lanh-dao, name: "Lãnh đạo UBND", reportTypes: [PERIODIC], periodTypes: [MONTH], recipients: [{type: USER, ref: U-T90-VW}, {type: GROUP, ref: lanh-dao-so}, {type: EMAIL, ref: "ubnd@t90.example.vn"}], attach: LINK, active: true}`
    Và công bố báo cáo `PERIODIC` kỳ tháng
    Và `GET /distributions/tc-lanh-dao/deliveries`
    Và `POST /distributions` với người nhận `EMAIL` `ai-do@gmail.com`
    Và công bố khi `notif-sim` làm lỗi địa chỉ `loi@t90.example.vn`
    Thì bước 1 `201`. Sau bước 2 sinh ba dòng `Delivery` `state = SENT` kèm `reportCode`, `version`, `recipient`, `sentAt`; thư gửi qua kênh PH-13 chứa liên kết (`attach = LINK`). Báo cáo `AD_HOC` không kích hoạt danh sách này. Bước 4 `422` ERR-16-036. Bước 5 `Delivery` `FAILED`, `errorCode = ERR-16-116`, không ảnh hưởng `PUBLISHED`.
