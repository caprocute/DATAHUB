# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-12
Tính năng: TS-12-12 · Rà soát quyền định kỳ

  @TC-12-041 @P2 @Dương
  Kịch bản: TC-12-041 Chiến dịch rà soát: mở, quyết định, đóng, hết hạn 14 ngày
    # Truy vết: FR-12-018 · UC-12-14 · UI-12-09 · API-12-041, 042, 043, 044 · BR-12-044
    Biết U-T68-SO mở chiến dịch; U-T68-MGR rà 5 quyền.
    Khi MGR giữ 3, gỡ 1 và bỏ qua 1; SO `:close`.
    Và chiến dịch khác: không phản hồi, nhảy 15 ngày.
    Thì quyền "gỡ" có hiệu lực ≤ 60 giây; quyền không phản hồi bị gỡ (vai trò đặc quyền) ở lần 2; KT: có.

  @TC-12-042 @P2 @Âm
  Kịch bản: TC-12-042 Tự rà quyền của mình và mở chiến dịch trùng
    # Truy vết: FR-12-018 · BR-12-044, BR-12-033 · API-12-041, 043 · ERR-12-013 · ERR-12-031
    Biết chiến dịch đang mở; MGR có quyền trong danh sách rà.
    Khi MGR quyết định quyền của chính mình.
    Và `POST /recertification-campaigns` khi đã có chiến dịch mở; quyết định trên chiến dịch đã đóng.
    Thì bước 1 `403` ERR-12-013; bước 2 `409` ERR-12-031.
