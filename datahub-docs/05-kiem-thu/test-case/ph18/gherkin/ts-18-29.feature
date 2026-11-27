# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-29
Tính năng: TS-18-29 · Chuyển sự cố có dữ liệu cá nhân sang PH-09

  @TC-18-097 @P2 @Dương
  Kịch bản: TC-18-097 SO chuyển sự cố có dữ liệu cá nhân sang PH-09
    # Truy vết: FR-18-050 · API-18-130 · BR-18-036 · EVT-18-18 · UI-18-18
    # Mục đích: Chứng minh FR-18-050: gói chuyển có loại dữ liệu, số người ước tính, thời điểm phát hiện; đồng hồ 72 giờ do PH-09 giữ.
    Biết T90; `INC-T90-04` `INVESTIGATING` có `hasPersonalData = true`; U-T90-SO; WireMock PH-09.
    Khi SO `POST /incidents/INC-T90-04:escalate-privacy` đủ trường.
    Và kiểm lời gọi tới PH-09.
    Thì bước 1 `202`, sự cố có `privacyRef`, mốc thời gian "Đã chuyển PH-09". Bước 2 PH-09 nhận đúng một lời gọi `source = INCIDENT_PH18`, không chứa payload.

  @TC-18-098 @P2 @Âm @Chịu_lỗi
  Kịch bản: TC-18-098 Thiếu thông tin chuyển PH-09 và PH-09 không nhận
    # Truy vết: FR-18-050 · API-18-130 · ERR-18-053, 054
    # Mục đích: Chứng minh điều kiện chuyển và cơ chế thử lại khi PH-09 vắng.
    Biết T94; WireMock PH-09 trả `503` ở bước 2.
    Khi SO chuyển nhưng thiếu số người ước tính.
    Và SO chuyển đủ trường khi PH-09 vắng, tua đồng hồ 65 phút.
    Thì bước 1 `422` ERR-18-053. Bước 2 `503` ERR-18-054, hệ thống thử lại mỗi 5 phút; sau 1 giờ SO nhận thông báo `URGENT`; khi PH-09 trở lại thì chuyển một lần.
