# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-07
Tính năng: TS-08-07 · Gửi duyệt, duyệt, kích hoạt và ngừng bộ quy tắc

  @TC-08-037 @P1 @Dương
  Kịch bản: TC-08-037 Chạy thử, gửi duyệt, duyệt và kích hoạt
    # Truy vết: FR-08-017, 018 · API-08-037, 038, 039, 041 · UI-08-09 · BR-08-006 · EVT-08-01 · PERM-08-approve
    Biết nháp v2 của `RS-CITIZEN` (v1 `ACTIVE`); DS1 soạn; U-T90-DA1; `dq-inline` đang đăng ký topic.
    Khi DS1 `:dry-run` rồi `:submit`
    Và DS1 `:submit` rồi rút bằng `:reject` với `action = WITHDRAW`
    Và DS1 `:submit` lại; DA1 `POST …/versions/2:approve` hiệu lực ngay
    Và `GET /rule-sets/RS-CITIZEN/versions`
    Thì bước 1 `PENDING_APPROVAL`, nội dung bị khóa. Bước 2 về `DRAFT`, không tính là từ chối. Bước 3 `200`, `status = ACTIVE`, `approvedBy = DA1`, v1 thành `SUPERSEDED`; đúng một phiên bản `ACTIVE`. EVT: `ruleset.activated` (EVT-08-01) một lần. KT: có (ruleset.activate).

  @TC-08-038 @P1 @Âm
  Kịch bản: TC-08-038 Gửi duyệt khi bộ rỗng hoặc chưa chạy thử
    # Truy vết: FR-08-017 · API-08-038 · BR-08-006 · ERR-08-021, 053
    Biết nháp v3 chưa có quy tắc bật; nháp v4 đã chạy thử, rồi DS1 sửa một quy tắc.
    Khi DS1 `:submit` v3
    Và DS1 `:submit` v4 sau khi sửa
    Thì bước 1 `422` ERR-08-021. Bước 2 `422` ERR-08-053 vì sửa làm mất hiệu lực dấu chạy thử. Cả hai giữ `DRAFT`.

  @TC-08-039 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-039 Người soạn không tự duyệt, từ chối thiếu lý do
    # Truy vết: FR-08-017 · API-08-039, 040 · BR-08-007 · ERR-00-403 · ERR-08-005, 007
    Biết v5 chờ duyệt, DS1 gửi; U-T90-TA có cả `PERM-08-rule-admin` và `PERM-08-approve` (cấu hình sai chủ ý, chỉ SIT) và là người soạn v6.
    Khi DS1 `:approve` v5
    Và TA `:approve` v6 do chính TA soạn
    Và DA2 `:reject` v5 với lý do 10 ký tự
    Và DA2 `:reject` v5 với lý do 30 ký tự
    Và tenant chỉ có một người giữ `PERM-08-approve`, mở UI-08-19 và để việc duyệt chờ 6 ngày làm việc
    Thì bước 1 và 2 `403` ERR-08-005, trạng thái không đổi. Bước 3 `422` ERR-08-007. Bước 4 `200`, v5 về `DRAFT` kèm lý do. Bước 5 UI-08-19 cảnh báo thiếu DA dự phòng và hệ thống nhắc TA qua PH-13 khi chờ quá 5 ngày làm việc. KT: có (ruleset.reject).

  @TC-08-040 @P2 @Dương
  Kịch bản: TC-08-040 Duyệt hiệu lực tương lai rồi tự kích hoạt
    # Truy vết: FR-08-018 · API-08-039, 041 · BR-08-006 · EVT-08-01
    Biết v7 chờ duyệt; đồng hồ giả `clock-sim`.
    Khi DA2 `:approve` v7 `{effectiveFrom: 2026-12-01T00:00:00+07:00}`
    Và `GET /rule-sets/RS-CITIZEN/versions`
    Và đẩy `clock-sim` qua 2026-12-01T00:00
    Và kiểm lại
    Thì bước 1 v7 `APPROVED`, v6 vẫn `ACTIVE`. Sau bước 3 v7 `ACTIVE`, v6 `SUPERSEDED`, EVT-08-01 đúng một lần, bộ đệm trực tuyến nạp v7 trong 30 giây.

  @TC-08-041 @P2 @Âm
  Kịch bản: TC-08-041 Ngừng bộ quy tắc và các chuyển trạng thái cấm
    # Truy vết: FR-08-018 · API-08-041, 042 · BR-08-006 · ERR-08-007, 006, 027
    Biết `RS-HOTICH` v1 `ACTIVE`; `RS-CITIZEN` v5 `SUPERSEDED`.
    Khi DS1 `POST /rule-sets/RS-HOTICH:retire` lý do 10 ký tự
    Và lặp với lý do 40 ký tự
    Và `POST …/versions/5:activate`
    Và tạo lần đo `POST /scans` cho `src-hotich`
    Thì bước 1 `422` ERR-08-007. Bước 2 `200`, phiên bản `RETIRED`. Bước 3 `409` ERR-08-006. Bước 4 `422` ERR-08-027 vì không còn bộ quy tắc hiệu lực.
