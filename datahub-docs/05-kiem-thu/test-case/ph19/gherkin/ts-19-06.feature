# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-06
Tính năng: TS-19-06 · Giám sát sức khỏe và xoay khóa

  @TC-19-126 @P1 @Dương
  Kịch bản: TC-19-126 Sức khỏe chuyển Suy giảm, Mất kết nối và cảnh báo
    # Truy vết: FR-19-011, 059 · API-19-003, 080 · UI-19-01, 02 · LGC-PAY-009
    Biết PV-PG `HEALTHY`; `19.provider.health-interval-seconds = 15`.
    Khi cho `PGSIM` lỗi 30% lời gọi trong 5 phút.
    Và cho `PGSIM` lỗi 100% trong 2 phút.
    Và khôi phục `PGSIM`.
    Thì bước 1: `healthStatus = DEGRADED`; UI-19-01 hiện dải cảnh báo vàng; PH-13 nhận cảnh báo `PaymentProviderDegraded`. Bước 2: `DOWN`, cảnh báo đỏ, huy hiệu menu "Kênh thanh toán" tăng. Bước 3: về `HEALTHY` trong ≤ 2 chu kỳ; cảnh báo tự đóng. Chỉ một bản sao `worker` chạy kiểm tra (khóa `t68:payment:health-leader`).

  @TC-19-127 @P1 @Âm
  Kịch bản: TC-19-127 Mạch ngắt mở từ chối tạo giao dịch trước khi ghi CSDL
    # Truy vết: FR-19-011, 024 · BR-19-013 · NFR-19-012 · API-19-101 · ERR-19-017
    Biết C-DVC; `19.provider.circuit-error-rate = 50`.
    Khi cho `PGSIM` trả 5xx cho khởi tạo; gửi 20 yêu cầu tạo giao dịch.
    Và đếm dòng `payment_transaction` mới sau khi mạch mở.
    Và chờ 30 giây (nửa mở), khôi phục `PGSIM`, gửi một yêu cầu.
    Thì bước 1: các yêu cầu đầu trả `504` ERR-19-019 (giao dịch `CREATED` `initUncertain`); sau khi vượt ngưỡng trả `503` ERR-19-017 có `Retry-After`. Bước 2: không có dòng mới cho yêu cầu bị mạch chặn. Bước 3: `201`, mạch về `CLOSED`. IPN và truy vấn vẫn chạy khi mạch mở.

  @TC-19-128 @P2 @Dương
  Kịch bản: TC-19-128 Xoay khóa xác minh, chấp nhận khóa cũ và mới trong chuyển tiếp
    # Truy vết: FR-19-012 · BR-19-026 · API-19-008, 201 · UI-19-04
    Biết U-SEC1; PV-PG `VERIFY_CERT` A `ACTIVE`; chứng thư B trong OpenBao.
    Khi `POST /providers/{PV-PG}/credentials/PRODUCTION/rotations` với tham chiếu B, chuyển tiếp 7 ngày.
    Và `PGSIM` gửi IPN ký bằng A; rồi IPN ký bằng B.
    Và tiến đồng hồ 7 ngày; `PGSIM` gửi IPN ký bằng A.
    Thì bước 1 trả `200`; danh sách có A `ACTIVE`, B `NEXT`. Bước 2: cả hai IPN `VERIFIED`. Bước 3: A `RETIRED`, B `ACTIVE`; IPN ký bằng A `BAD_SIGNATURE` (ERR-19-024), không đổi trạng thái giao dịch. KT: có (`CREDENTIAL_ROTATE`). Phát hành Đ2b.

  @TC-19-129 @P2 @Dương @Âm
  Kịch bản: TC-19-129 Nhắc hạn khóa, chứng thư sắp hết hạn
    # Truy vết: FR-19-011, 012, 059 · UI-19-02, 03 · BR-19-010
    Biết PV-PG chứng thư còn 31 ngày.
    Khi chạy CredentialExpiryJob; tiến đồng hồ 1 ngày, chạy lại; tiến tới còn 7 ngày, chạy lại.
    Và mở UI-19-02.
    Thì bước 1: lúc còn 30 ngày có cảnh báo `WARN` tới PH-13 và người có `credential-manage`; lúc còn 7 ngày `CRITICAL`. Bước 2: thẻ PayGov hiện "Chứng thư ký hết hạn sau 7 ngày" màu đỏ có chữ.
