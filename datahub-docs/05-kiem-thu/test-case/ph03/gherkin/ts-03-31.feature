# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-31
Tính năng: TS-03-31 · Tăng cứng, TLS, WAF và quét bảo mật

  @TC-03-131 @P1 @Bảo @mật
  Kịch bản: TC-03-131 Tăng cứng container, ký ảnh, quét lỗ hổng
    # Truy vết: NFR-03-016 · FR-03-011 · SEC-52, 55, 56, 57.
    Biết ảnh APISIX và `dh-connect` bản phát hành.
    Khi kiểm `securityContext`, hệ thống tệp, nơi lưu khóa riêng (OpenBao hoặc Secret tmpfs).
    Và xác minh chữ ký `cosign` của ảnh APISIX và plugin.
    Và chạy Trivy và Semgrep.
    Thì không chạy root, hệ thống tệp gốc chỉ đọc; khóa riêng không nằm trong ảnh hay biến môi trường; chữ ký hợp lệ; Trivy 0 CRITICAL.

  @TC-03-132 @P1 @Bảo @mật
  Kịch bản: TC-03-132 Hiệu quả WAF với bộ payload OWASP và tỉ lệ chặn nhầm
    # Truy vết: FR-03-005 · API-03-039 · ERR-03-109 · NFR-03-012 · SEC-11.
    Biết `SIM-ATTACK` bộ 2.000 payload OWASP; 100.000 yêu cầu hợp lệ lấy từ trace giả lập GĐ; `gw.waf.mode = BLOCK`, mức hoang tưởng theo cấu hình.
    Khi gửi toàn bộ payload.
    Và gửi 100.000 yêu cầu hợp lệ.
    Thì ≥ 99 % payload bị chặn (giả định, chốt khi có dữ liệu thật, Q03-40); chặn nhầm < 0,1 % lượt hợp lệ.

  @TC-03-133 @P2 @Bảo @mật
  Kịch bản: TC-03-133 Quét API quản trị theo ASVS 5.0 mức 2 và kiểm tra lại TLS
    # Truy vết: API-03-001, 024, 059, 087 · FR-03-001 · NFR-03-010 · SEC-43, 44.
    Biết openAPI của `/api/gateway/v1`; U-T68-TA.
    Khi chạy ZAP quét chủ động trên OpenAPI.
    Và chạy `testssl.sh` sau khi đổi hồ sơ TLS.
    Thì 0 phát hiện mức Cao hoặc Nghiêm trọng; TLS điểm A+; không lỗi injection, IDOR, thiếu kiểm tra quyền.
