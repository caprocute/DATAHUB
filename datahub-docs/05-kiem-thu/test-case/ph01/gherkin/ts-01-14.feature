# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-14
Tính năng: TS-01-14 · Đăng ký khóa công khai hoặc ký chứng thư

  @TC-01-055 @P1 @Dương
  Kịch bản: TC-01-055 Đăng ký JWKS và ký CSR
    # Truy vết: FR-01-021 · UC-01-14 · API-01-037, 038 · UI-01-08 · BR-01-007, 019 · EVT-01-05, 06.
    Biết `HT-HOTICH-AP` (AWAITING_KEY); F-JWKS-OK; HTTT mức Nhạy cảm `tc-nhaycam` với F-CSR-OK; U-T68-TECH.
    Khi TECH `PUT /credentials/{credentialId}/public-key` với F-JWKS-OK.
    Và TA1 `POST …:sign-csr` cho CSR của `tc-nhaycam`.
    Thì bước 1: `200`, định danh `ACTIVE`, `EVT-01-05`; PH-01 chỉ lưu vân tay. Bước 2: chứng thư do PKI OpenBao cấp, hạn ≤ hạn định danh; khóa riêng không có mặt ở bất kỳ đâu. Mồi sạch.

  @TC-01-056 @P1 @Âm
  Kịch bản: TC-01-056 Khóa yếu, CSR sai, sai trạng thái, phụ thuộc ngừng
    # Truy vết: FR-01-021 · API-01-037, 038 · BR-01-019 · ERR-01-021, 023, 027, 028, 030.
    Biết F-JWKS-BAD, F-CSR-BAD; định danh `REVOKED`; PH-12, OpenBao giả lập `fail`.
    Khi `PUT …/public-key` với F-JWKS-BAD.
    Và `:sign-csr` với F-CSR-BAD.
    Và `PUT …/public-key` vào định danh `REVOKED`.
    Và đặt PH-12 `fail`; đăng ký khóa hợp lệ; đặt OpenBao `fail`; ký CSR hợp lệ.
    Thì `422` ERR-01-027; `422` ERR-01-028; `409` ERR-01-030; `503` ERR-01-021; `503` ERR-01-023. Không có thay đổi một phần.
