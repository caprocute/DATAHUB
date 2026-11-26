# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-17
Tính năng: TS-14-17 · Ký số bản tin và xác minh chữ ký phản hồi

  @TC-14-043 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-043 Ký bằng khóa trong OpenBao, xác minh phản hồi
    # Truy vết: FR-14-026, 027 · UC-14-09 · UI-14-08 · BR-14-001, 002, 004 · NFR-14-002, 003, 013 · SEC-32.
    Biết V-LLTP (ký `REQUIRED`, xác minh `REQUIRED`); K-KY-01; `sim-ndxp` `OK`.
    Khi gọi V-LLTP.
    Và đối chiếu bản tin `sim-ndxp` nhận và nhật ký OpenBao.
    Và xem thống kê ký ở UI-14-08.
    Thì bản tin có chữ ký, `sim-ndxp` xác minh được; OpenBao ghi một lệnh `transit/sign` với giá trị băm; khóa riêng không ở bộ nhớ hay đĩa của pod; phản hồi xác minh đạt rồi mới trả.

  @TC-14-044 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-044 Chữ ký phản hồi sai, ngoài chuỗi tin cậy, lệch thời điểm, lặp
    # Truy vết: FR-14-027, 031 · UI-14-14 · ERR-14-109, 110, 111 · BR-14-002, 003 · NFR-14-018.
    Biết U-T68-SO; `sim-ndxp` lần lượt `BADSIG`, `BADCHAIN`, `OLDTS`, phát lại một phản hồi.
    Khi gọi dịch vụ ở từng chế độ.
    Và mở UI-14-14.
    Thì `502` lần lượt ERR-14-109, 110, 111, 111; phản hồi không đến HTTT; giao dịch `SIGNATURE_FAILED`; có sự cố chữ ký mới và cảnh báo SO ≤ 1 phút.

  @TC-14-045 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-14-045 Không ký được thì không gửi; chứng thư hết hạn; thiếu chứng thư
    # Truy vết: FR-14-026 · API-14-075, 076, 008 · ERR-14-112, 113, 037, 035 · BR-14-001, 017 · NFR-14-010.
    Biết dừng OpenBao; chứng thư ký hết hạn (đồng hồ giả lập); nền tảng `ndxp-moi` có dịch vụ yêu cầu ký nhưng chưa có chứng thư `ACTIVE`.
    Khi dừng OpenBao, gọi dịch vụ ký và gửi một yêu cầu bất đồng bộ.
    Và khôi phục OpenBao; đặt đồng hồ quá `notAfter`; gọi dịch vụ.
    Và `:request-activation` `ndxp-moi`.
    Thì bước 1 `503` ERR-14-112, `sim-ndxp` nhận 0 bản tin, yêu cầu bất đồng bộ ở lại hàng chờ, 0 bản tin mất; bước 2 `503` ERR-14-113 (nền tảng bị chặn ký); bước 3 `422` ERR-14-037.
