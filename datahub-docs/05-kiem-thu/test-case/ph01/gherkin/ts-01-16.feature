# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-16
Tính năng: TS-01-16 · Kiểm thử kết nối ở SANDBOX

  @TC-01-064 @P1 @Dương
  Kịch bản: TC-01-064 Đủ lượt gọi đạt thì sẵn sàng kích hoạt
    # Truy vết: FR-01-023 · UC-01-16 · API-01-042, 043 · UI-01-10 · BR-01-008.
    Biết `HT-HOTICH-AP` có định danh SANDBOX; `sandbox.requiredSuccessfulCalls = 3`.
    Khi dùng định danh gọi API sandbox giả hai lần; `POST …/sandbox-tests`; `GET …/sandbox-tests`.
    Và gọi lần thứ ba; làm mới.
    Thì bước 1: `readyToActivate = false`, UI-01-10 hiện kết quả hai bên và hướng dẫn khắc phục. Bước 2: `readyToActivate = true`. Hai API nhận `Idempotency-Key`.

  @TC-01-065 @P1 @Âm @Bảomật
  Kịch bản: TC-01-065 Định danh SANDBOX không gọi được dữ liệu thật, vượt hạn mức
    # Truy vết: FR-01-023 · API-01-042 · BR-01-034, 003.
    Biết định danh SANDBOX của `HT-HOTICH`; `sandbox.quotaPerDay = 1.000`; giả lập PH-03.
    Khi dùng định danh SANDBOX gọi một API của môi trường thật.
    Và gọi 1.001 lần trong một ngày ở sandbox.
    Thì bước 1: bị chặn ở cổng (`401` hoặc `403`), không có dữ liệu thật trả về. Bước 2: lượt 1.001 bị `429`; định danh mới cấp không có scope dữ liệu.

  @TC-01-066 @P3 @Biên @Chịulỗi
  Kịch bản: TC-01-066 Ở SANDBOX quá hạn, PH-13 không khả dụng
    # Truy vết: FR-01-023 · API-01-043 · ERR-01-046 · NFR-01-016.
    Biết `HT-HOTICH-AP`; `sandbox.maxDays = 30`; đồng hồ giả; PH-13 giả lập `fail`.
    Khi tua 31 ngày; chạy tác vụ.
    Và `GET …/sandbox-tests` khi PH-13 `fail`.
    Thì bước 1: cảnh báo "HTTT ở SANDBOX quá 30 ngày" gửi PH-13 và TA. Bước 2: `503` ERR-01-046 cho phần số liệu gọi, kết quả lưu của PH-01 vẫn trả được.
