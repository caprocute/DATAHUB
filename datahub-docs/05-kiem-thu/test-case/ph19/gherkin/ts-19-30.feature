# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-30
Tính năng: TS-19-30 · Bảo mật callback và webhook

  @TC-19-726 @P1 @Bảo @mật
  Kịch bản: TC-19-726 IPN sai chữ ký, chứng thư đã thu hồi
    # Truy vết: FR-19-029 · NFR-19-020 · API-19-201 · ERR-19-024 · LGC-PAY-010
    Biết TX `PENDING`; chứng thư cũ của PV-PG đã chuyển `REVOKED`.
    Khi gửi IPN đổi một byte trong thân sau khi ký.
    Và gửi IPN ký bằng chứng thư đã thu hồi.
    Và gửi IPN không có chữ ký.
    Thì cả ba trả `401` ERR-19-024; hộp nhận ghi `REJECTED` lý do `BAD_SIGNATURE`; giao dịch không đổi; `payment_callback_rejected_total{reason="signature"}` tăng; sự kiện an ninh tới PH-13.

  @TC-19-727 @P1 @Bảo @mật
  Kịch bản: TC-19-727 IPN lệch thời gian quá ±5 phút
    # Truy vết: NFR-19-020, 028 · API-19-201 · ERR-19-025
    Biết TX `PENDING`.
    Khi gửi IPN có dấu thời gian lệch −4 phút 59 giây và +4 phút 59 giây.
    Và lệch −5 phút 1 giây và +5 phút 1 giây.
    Thì bước 1 được nhận. Bước 2 trả `401` ERR-19-025.

  @TC-19-728 @P1 @Bảo @mật
  Kịch bản: TC-19-728 Phát lại nonce với nội dung khác
    # Truy vết: NFR-19-020 · API-19-201 · ERR-19-026
    Biết IPN thành công đã xử lý.
    Khi gửi IPN có cùng nonce nhưng mã kết quả khác, chữ ký hợp lệ.
    Và xóa khóa nonce trong Valkey rồi gửi lại.
    Thì bước 1 trả `409` ERR-19-026. Bước 2 vẫn trả `409` ERR-19-026 nhờ ràng buộc duy nhất trong CSDL.

  @TC-19-729 @P1 @Bảo @mật
  Kịch bản: TC-19-729 IPN từ IP lạ, sai connectionKey
    # Truy vết: NFR-19-020 · API-19-201 · ERR-19-027, 020
    Biết allowlist IP của PV-PG tại APISIX; máy thử ngoài allowlist.
    Khi gửi IPN hợp lệ từ IP lạ.
    Và gửi IPN tới `connectionKey` của PV-SUS bằng chữ ký của PV-PG.
    Và gửi tới `connectionKey` ngẫu nhiên.
    Thì bước 1 trả `403` ERR-19-027 tại biên, không tới `dh-payment`. Bước 2 trả `401` ERR-19-024. Bước 3 trả `403` ERR-19-027 với thân giống hệt bước 1, không lộ khóa có tồn tại hay không, không lộ tenant.

  @TC-19-730 @P2 @Bảo @mật
  Kịch bản: TC-19-730 Xoay bí mật webhook, hai bí mật cùng hiệu lực 7 ngày
    # Truy vết: NFR-19-021 · FR-19-060
    Biết đầu nhận của P-DVC; đồng hồ giả.
    Khi xoay bí mật.
    Và hoàn tất giao dịch; kiểm header chữ ký.
    Và tiến 7 ngày 1 phút; hoàn tất giao dịch.
    Thì bước 2: `X-Datahub-Signature` có hai giá trị `v1` phân tách bằng dấu phẩy (mới, cũ); đối tác chỉ có bí mật cũ vẫn xác minh được. Bước 3: chỉ còn chữ ký mới. Bí mật mới ≥ 256 bit, chỉ nằm trong OpenBao.

  @TC-19-731 @P1 @Bảo @mật
  Kịch bản: TC-19-731 Token đối tác hết hạn, client bị thu hồi
    # Truy vết: NFR-19-019 · API-19-101
    Biết C-DVC.
    Khi dùng token sau 5 phút 1 giây.
    Và dùng token mTLS-bound với chứng thư khác.
    Và thu hồi C-DVC, đo thời gian tới khi bị từ chối.
    Thì bước 1, 2 trả `401`. Bước 3: ≤ 60 giây.

  @TC-19-732 @P2 @Bảo @mật
  Kịch bản: TC-19-732 TLS ra ngoài và egress
    # Truy vết: NFR-19-018
    Biết SIT có egress gateway riêng tới `PGSIM`.
    Khi quét các điểm nhận `/api/payment-partner/v1`, `/api/payment-callback/v1`.
    Và từ pod `dh-payment` gọi một địa chỉ Internet khác `PGSIM`.
    Thì bước 1: chỉ TLS 1.3 (hoặc 1.2 AEAD theo OQ-19-02), không bộ mã yếu. Bước 2 bị chặn bởi chính sách egress.

  @TC-19-733 @P1 @Bảo @mật
  Kịch bản: TC-19-733 Quét động có xác thực, ASVS cấp 2
    # Truy vết: NFR-19-023 · API-19-001…205
    Biết ZAP nhập ba tệp OpenAPI của PH-19; ngữ cảnh U-ADM1, U-ACC1, C-DVC.
    Khi quét chủ động toàn bộ thao tác.
    Và chạy danh sách kiểm ASVS 5.0 cấp 2 cho các mục V2, V3, V4, V5, V8, V9 (thủ công phần không tự động được).
    Thì không phát hiện mức cao hoặc nghiêm trọng; mức trung bình có phiếu xử lý trước RG-3. Kết quả ASVS ghi vào báo cáo ATTT của đợt.
