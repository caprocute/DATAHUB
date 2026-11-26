# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-04
Tính năng: TS-05-04 · Bật môi trường và duyệt PROD

  @TC-05-015 @P1 @Dương
  Kịch bản: TC-05-015 Bật TEST sau kiểm tra đạt
    # Truy vết: FR-05-007 · API-05-013 · BR-05-006 · EVT-05-01
    Biết U-T68-IE1; `tc-ndxp-moi` có kiểm tra TEST đạt từ TC-05-011.
    Thì `200`, TEST `ENABLED`, kết nối `DRAFT` → `ACTIVE`. EVT: `connection.enabled` (không có tham số bí mật trong `data`). KT: có (`ENV_ENABLE`).

  @TC-05-016 @P1 @Âm
  Kịch bản: TC-05-016 Bật khi chưa kiểm tra, kiểm tra quá 24 giờ, đổi bí mật sau kiểm tra
    # Truy vết: FR-05-007 · API-05-013 · ERR-05-009 · BR-05-006
    Biết U-T68-IE1; ba kết nối thử `tc-e1` (chưa kiểm tra), `tc-e2` (đạt 25 giờ trước, đồng hồ giả), `tc-e3` (đạt rồi ghi bí mật mới).
    Thì cả ba `409` ERR-05-009 với `lastPassedAt` (rỗng với `tc-e1`); `disabledReasons.ENABLE` ở `GET` nêu đúng lý do.

  @TC-05-017 @P1 @Dương
  Kịch bản: TC-05-017 Xin bật PROD, người khác duyệt
    # Truy vết: FR-05-007 · API-05-013, 015 · UI-05-17 · UC-05-03 · EVT-05-01
    Biết U-T68-IE1 (người xin, người ghi bí mật PROD), U-T68-IA1; `tc-ndxp-moi` PROD có kiểm tra đạt.
    Khi IE1 `POST …/PROD:enable` với lý do.
    Và IA1 mở "Việc của tôi", mục `ph05.env-enable`, xem khác biệt, bấm "Duyệt".
    Thì bước 1 `202`, PROD `PENDING_APPROVAL`, IA1 nhận thông báo. Bước 2 gọi `POST …/PROD:approve` trả `200`, PROD `ENABLED`. Khung duyệt chỉ hiện "Bí mật phiên bản 1, ghi bởi An", không có giá trị. EVT: `connection.enabled` với `env = PROD`. KT: có (`ENV_ENABLE_REQUEST`, `ENV_ENABLE_APPROVE`).

  @TC-05-018 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-018 Tự duyệt, người ghi bí mật duyệt, từ chối
    # Truy vết: FR-05-007 · API-05-015, 016 · ERR-05-011, 038 · BR-05-009
    Biết U-T68-IA2 xin bật PROD của `tc-e4`; U-T68-IA1 đã ghi bí mật PROD của `tc-e5`, IE1 xin bật.
    Khi IA2 `POST …/tc-e4/environments/PROD:approve`.
    Và IA1 `POST …/tc-e5/environments/PROD:approve`.
    Và IA1 `POST …/tc-e4/environments/PROD:reject` không lý do; rồi có lý do.
    Thì bước 1, 2 `403` ERR-05-011 nêu vai trò trùng ("người đề nghị", "người ghi bí mật"); trạng thái giữ `PENDING_APPROVAL`. Bước 3 lần đầu `400` ERR-05-038; lần sau `200`, PROD về `CONFIGURED`, IA2 nhận thông báo với lý do.

  @TC-05-019 @P2 @Âm
  Kịch bản: TC-05-019 Đóng băng PROD chặn ghi và bật
    # Truy vết: FR-05-005, 007 · API-05-011, 012, 013 · ERR-05-031 · UI-05-02
    Biết U-T68-TA bật đóng băng PROD 2 giờ; U-T68-IE1.
    Khi `PUT …/PROD`, `PUT …/PROD/secret`, `POST …/PROD:enable`.
    Và `PUT …/TEST`.
    Và mở UI-05-02.
    Thì bước 1 mỗi lệnh `423` ERR-05-031 với thời điểm hết đóng băng. Bước 2 `200`. Bước 3 có `CMP-Banner` đóng băng, nút ghi PROD vô hiệu với lý do.
