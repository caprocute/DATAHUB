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

  @TC-14-114 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-114 Ký theo từng chế độ: chỉ giá trị băm tới OpenBao, vết ký trong giao dịch
    # Truy vết: FR-14-026 · API-14-075 · UC-14-09 · BR-14-001, 004, 017 · NFR-14-002, 013 · SEC-32.
    Biết S-HT-MC; ba dịch vụ có `signingMode` lần lượt `XMLDSIG`, `WSSE`, `JWS`; K-KY-01 `ACTIVE`, K-HET `EXPIRING` ở một ca riêng; `sim-ndxp` `OK` ghi lại bản tin nhận được; nhật ký OpenBao bật.
    Khi gọi từng dịch vụ một lần.
    Và kiểm tra bản tin tại `sim-ndxp` và nhật ký kiểm toán OpenBao.
    Và đặt chứng thư đang dùng là K-HET (còn 5 ngày), gọi lại.
    Và đọc `national_sign_total` và giao dịch.
    Thì bước 1 `200`. Bước 2 có XML Signature trong thân, tiêu đề WS-Security hoặc tiêu đề JWS tương ứng, kèm chứng thư công khai; OpenBao chỉ nhận lời gọi `transit/sign` với giá trị băm (SHA-256), không nhận bản tin, không có lời gọi xuất khóa. Bước 3 vẫn ký được, có cảnh báo vận hành. Bước 4 `national_sign_total` tăng đúng số lượt, giao dịch ghi `certCode`, giá trị băm, thời điểm ký.

  @TC-14-115 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-115 Xác minh chữ ký phản hồi theo từng chế độ và đặt `signatureVerified`
    # Truy vết: FR-14-027 · API-14-075 · UC-14-09 · BR-14-002 · NFR-14-003, 013.
    Biết S-HT-MC; dịch vụ `verifyMode` `XMLDSIG`, `WSSE`, `JWS` và một dịch vụ `verifyMode = NONE`; K-NDXP-TIN trong chuỗi tin cậy; `sim-ndxp` `OK` có ký.
    Khi gọi từng dịch vụ có `verifyMode` khác `NONE`.
    Và gọi dịch vụ `verifyMode = NONE`.
    Và đọc `meta.signatureVerified` và giao dịch.
    Thì bước 1 `200`, `meta.signatureVerified = true`, giao dịch ghi chứng thư của nền tảng đã dùng để xác minh, `messageId` được nhớ ở Valkey 10 phút. Bước 2 `200`, `signatureVerified = false` và không có lỗi. Dữ liệu chỉ tới bên gọi sau khi xác minh đạt; số phản hồi cần xác minh đã xác minh là 100 % (NFR-14-013).

  @TC-14-116 @P1 @Âm @Biên @Bảo
  Kịch bản: TC-14-116 Biên thời điểm ký và chống phát lại: 299 giây, 301 giây, `messageId` lặp
    # Truy vết: FR-14-027, 031 · API-14-075, 037 · ERR-14-111 · BR-14-002, 003 · NFR-14-018 · EVT-14-06.
    Biết S-HT-MC; `sim-ndxp` `OLDTS` điều chỉnh được độ lệch thời điểm ký; `14.sign.max-skew-seconds = 300`; `Clock` giả lập; U-T68-SO.
    Khi gọi khi thời điểm ký lệch 299 giây.
    Và gọi khi lệch 301 giây.
    Và gọi khi lệch -301 giây (ký ở tương lai).
    Và cho `sim-ndxp` trả hai lần cùng `messageId` trong 10 phút.
    Và cho `sim-ndxp` trả lại `messageId` đó sau 11 phút.
    Thì bước 1 `200`. Bước 2, 3 và lần lặp ở bước 4 `502` ERR-14-111 "Bản tin nhận được có dấu hiệu cũ hoặc bị gửi lại nên bị từ chối.", thân không có dữ liệu; mỗi lần mở một sự cố chữ ký, phát EVT-14-06 và gửi cảnh báo cho SO trong 1 phút. Bước 5 lượt lặp muộn hơn cửa sổ vẫn bị từ chối vì lệch thời điểm, không phải vì `messageId`.
