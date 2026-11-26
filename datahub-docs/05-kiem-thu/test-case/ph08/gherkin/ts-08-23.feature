# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-23
Tính năng: TS-08-23 · Khai báo, phát và xử lý cảnh báo chất lượng

  @TC-08-108 @P2 @Dương @Âm
  Kịch bản: TC-08-108 Khai báo quy tắc cảnh báo
    # Truy vết: FR-08-047 · API-08-098, 099, 100 · UI-08-17 · PERM-08-rule-admin · ERR-08-037
    Biết T90; DS1.
    Khi `POST /alert-rules` `{alertRuleCode: cb-diem-duoi-ngung, name: "Điểm dưới ngưỡng", conditionType: SCORE_BELOW, threshold: 80, severity: HIGH, assetCode: mdm-citizen}`
    Và `PUT /alert-rules/AR-01` đổi ngưỡng 75
    Và `POST /alert-rules` `{alertRuleCode: cb-am, name: "Ngưỡng âm", conditionType: SCORE_BELOW, threshold: -5, severity: HIGH}`
    Và `GET /alert-rules`
    Thì bước 1 `201`, bước 2 `200`. Bước 3 `422` ERR-08-037. Bước 4 có quy tắc mặc định và quy tắc vừa tạo; tắt quy tắc mặc định thay vì xóa.

  @TC-08-109 @P1 @Dương @Âm
  Kịch bản: TC-08-109 Phát cảnh báo, không trùng, nhắc lại, tự giải quyết và PH-13 lỗi
    # Truy vết: FR-08-048 · API-08-101 · UI-08-17 · BR-08-029 · EVT-08-12 · ERR-08-114
    Biết quy tắc `AR-01` `SCORE_BELOW` 80 cho `mdm-citizen`; `notif-sim`; `08.alert.repeat-hours = 4`; `clock-sim`.
    Khi lần đo điểm 78
    Và lần đo kế tiếp điểm 75 sau 1 giờ
    Và sau 4 giờ lần đo điểm 74
    Và lần đo điểm 85
    Và tắt `notif-sim`, lần đo điểm 70 làm cảnh báo mới `FIRING`, chờ 65 phút
    Thì bước 1 một cảnh báo `FIRING`, EVT: `alert.fired` (EVT-08-12), `notif-sim` nhận. Bước 2 không tạo cảnh báo thứ hai, không nhắc. Bước 3 nhắc lại một lần. Bước 4 `RESOLVED`, EVT-08-12 `RESOLVED`. Bước 5 sự kiện nằm ở hộp gửi, thử lại; quá 1 giờ UI-08-17 ghi ERR-08-114.

  @TC-08-110 @P2 @Dương @Âm
  Kịch bản: TC-08-110 Xác nhận, tắt tiếng và giới hạn 7 ngày
    # Truy vết: FR-08-049 · API-08-102, 103 · BR-08-029 · ERR-08-042, 006
    Biết cảnh báo `FIRING`; cảnh báo khác `RESOLVED`; DS1.
    Khi `POST /alerts/{id}:acknowledge`
    Và `POST /alerts/{id}:silence` `{reason: ≥ 20 ký tự, silencedUntil: +3 ngày}`
    Và `:silence` `silencedUntil: +10 ngày`
    Và `:acknowledge` cảnh báo `RESOLVED`
    Thì bước 1 `ACKNOWLEDGED`. Bước 2 `SILENCED`, không phát lại trong 3 ngày. Bước 3 `422` ERR-08-042 (thời hạn không quá 7 ngày). Bước 4 `409` ERR-08-006.
