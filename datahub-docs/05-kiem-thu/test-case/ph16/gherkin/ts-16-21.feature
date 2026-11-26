# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-21
Tính năng: TS-16-21 · So sánh liên tenant ẩn danh

  @TC-16-079 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-16-079 So sánh liên tenant: phân bố, mã giả, không đủ tenant, vai trò
    # Truy vết: FR-16-041 · API-16-092 · UI-16-18 · ERR-16-038 · BR-16-020
    Biết bốn tenant T90, T91, T92, T94 có số chính thức `tre-gateway-p95` kỳ `M-2026-10`: 180, 220, 260, 340 (ms); cùng phiên bản mẫu; `16.compare.min-tenants = 3`; U-PA, U-PU.
    Khi U-PA `GET /cross-tenant/comparison?indicatorCode=tre-gateway-p95&periodCode=M-2026-10`
    Và U-PU gọi cùng yêu cầu
    Và đổi một tenant sang công thức tùy biến rồi gọi lại
    Và với `mttd` chỉ T90, T91 có số chính thức: U-PA gọi, rồi U-T90-TA1 gọi
    Thì bước 1 `200`, `tenantCount = 4`, `distribution` (`min` 180, `median` 240, `max` 340, `p25`, `p75`), `tenants[]` có `alias`, `value`, `status`; PA thấy mã tỉnh thật. Bước 2 cùng phân bố nhưng `alias` là mã giả ổn định theo kỳ (không suy ra tỉnh). Bước 3 `tenantCount = 3`, tenant tùy biến công thức bị loại. Bước 4 `422` ERR-16-038, không lộ số hai tenant; TA gọi `403` ERR-00-403.
