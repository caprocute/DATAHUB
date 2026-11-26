# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-10
Tính năng: TS-19-10 · Client, dịch vụ được gán, webhook đối tác

  @TC-19-226 @P1 @Dương
  Kịch bản: TC-19-226 Cấp client mTLS và private_key_jwt
    # Truy vết: FR-19-019 · NFR-19-019 · API-19-036, 037 · UI-19-12
    Biết U-ADM1; P-DVC; một CSR và một JWKS URL thử.
    Khi tab "Client": cấp client `MTLS` từ CSR.
    Và cấp client `PRIVATE_KEY_JWT` từ JWKS URL.
    Và dùng client bước 1 xin token `client_credentials` ràng buộc chứng thư, gọi `P: GET /services`.
    Thì bước 1, 2 trả `201`; hộp "Thông tin kết nối" hiện một lần; hệ thống không lưu khóa riêng. Bước 3: token sống ≤ 5 phút, có `cnf.x5t#S256`; gọi trả `200` với S-HT, S-XD và hạn mức còn lại. KT: có (`PARTNER_CLIENT_ISSUE`).

  @TC-19-227 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-227 Thu hồi client có hiệu lực trong 60 giây
    # Truy vết: FR-19-019 · API-19-038, 101 · NFR-19-019
    Biết client `mTLS` từ TC-19-226 đang có token còn hạn 4 phút.
    Khi `DELETE /partners/{P-DVC}/clients/{clientId}` có lý do.
    Và sau 60 giây, gọi `P: POST /payments` bằng token cũ.
    Và gọi bằng token cũ nhưng chứng thư khác (token bị đánh cắp).
    Thì bước 2 trả `401` từ PH-03. Bước 3 trả `401` (ràng buộc chứng thư RFC 8705) cả trước khi thu hồi.

  @TC-19-228 @P1 @Dương @Âm
  Kịch bản: TC-19-228 Gán dịch vụ và hạn mức, chặn khi vượt
    # Truy vết: FR-19-020 · BR-19-005 · API-19-040, 101, 108 · ERR-19-012, 013
    Biết U-ADM1; bản sao P-DVC tên P-LIM gán S-XD với `maxAmountPerTxn = 1.000.000`, `dailyTxnLimit = 3`, `dailyAmountLimit = 2.000.000`; C-LIM.
    Khi C-LIM tạo giao dịch 1.000.001 ₫.
    Và tạo ba giao dịch 600.000 ₫.
    Và tạo giao dịch thứ tư 100.000 ₫.
    Và gọi `P: GET /services`.
    Và tiến đồng hồ qua 00:00 giờ Việt Nam; tạo lại.
    Thì bước 1 trả `422` ERR-19-012. Bước 2 trả `201` cả ba. Bước 3 trả `422` ERR-19-013. Bước 4: `usedToday.count = 3`, `amount = 1.800.000`. Bước 5 trả `201` (bộ đếm `t68:payment:quota:…:{yyyyMMdd}` theo ngày VN). Giao dịch `FAILED` do NCC từ chối không tính vào hạn mức (BR-19-005).

  @TC-19-229 @P1 @Dương
  Kịch bản: TC-19-229 Thêm đầu nhận webhook, gửi thử, xoay bí mật
    # Truy vết: FR-19-021 · NFR-19-021 · API-19-043, 045, 046 · UI-19-12
    Biết U-ADM1; P-DVC; đầu nhận giả lập `https://dvc.t68.test/hook2` kiểm chữ ký.
    Khi thêm đầu nhận với 8 loại sự kiện.
    Và bấm "Gửi thử".
    Và bấm "Xoay bí mật"; gửi thử lại trong 24 giờ chuyển tiếp.
    Thì bước 1 trả `201` kèm `secret` chỉ một lần; mở lại màn không thấy bí mật. Bước 2: đầu nhận nhận sự kiện mẫu, chữ ký `v1` hợp lệ với bí mật cũ; màn hiện mã HTTP, thời lượng. Bước 3: bí mật mới hiện một lần; trong chuyển tiếp tiêu đề chữ ký chứa hai giá trị `v1` (bí mật cũ và mới).

  @TC-19-230 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-230 Đầu nhận webhook không an toàn
    # Truy vết: FR-19-021 · API-19-043, 044 · ERR-19-044
    Biết U-ADM1.
    Khi thêm đầu nhận `http://dvc.t68.test/hook`.
    Và `https://10.0.0.5/hook`, `https://localhost/hook`, `https://169.254.169.254/latest`.
    Và `https://rebind.test/hook` (tên miền phân giải ra địa chỉ riêng lúc gửi).
    Thì bước 1, 2 trả `422` ERR-19-044. Bước 3: lưu được nhưng lúc gửi bộ gửi phân giải lại, phát hiện địa chỉ riêng, đánh lượt gửi `EXHAUSTED` với lý do "địa chỉ nội bộ", không mở kết nối (kiểm bằng log egress).
