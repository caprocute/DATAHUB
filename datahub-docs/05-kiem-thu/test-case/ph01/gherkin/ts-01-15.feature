# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-15
Tính năng: TS-01-15 · Bàn giao thông tin xác thực một lần

  @TC-01-057 @P1 @Dương @Bảomật
  Kịch bản: TC-01-057 Tạo liên kết bàn giao, thư chỉ chứa liên kết
    # Truy vết: FR-01-022 · UC-01-15 · API-01-039 · BR-01-005, 007 · NFR-01-010.
    Biết định danh SANDBOX `ACTIVE` của chuỗi bí mật (HTTT `HT-DVC` làm lại SANDBOX); U-T68-TA1 có MFA mới; U-T68-TECH.
    Khi TA1 `POST /credentials/{credentialId}/handovers` kèm `Idempotency-Key`.
    Và đọc thư ở mail-sink; tra bảng bàn giao ở CSDL.
    Thì `201`; mã liên kết ≥ 256 bit; CSDL chỉ lưu băm; hạn 24 giờ (`handover.ttlHours`). Thư gửi tới TECH chứa liên kết, không chứa bí mật, mã khách, hay mật khẩu. KT: có.

  @TC-01-058 @P1 @Dương @Bảomật
  Kịch bản: TC-01-058 Mở liên kết bằng đúng người: nhận bí mật một lần
    # Truy vết: FR-01-022 · UC-01-15 · API-01-040 · UI-01-09 · BR-01-006, 007 · EVT-01-09 · NFR-01-009.
    Biết liên kết `PENDING` từ ca trước; U-T68-TECH có tài khoản và TOTP.
    Khi TECH mở `/ket-noi/ban-giao/{token}`, đăng nhập, xác thực MFA mới.
    Và `POST /handovers:open`.
    Và tra bảng bàn giao, OpenBao, log, vết, Kafka.
    Thì bước 2: `200`, bí mật hiện một lần kèm nút sao chép, không lưu bộ nhớ đệm trình duyệt (tiêu đề `Cache-Control: no-store`, theo API-01-040). Sau đó: trạng thái `OPENED`, bản sao bí mật bị hủy; chỉ phản hồi này có `DH-CANARY` (Mồi sạch ở mọi nơi khác). EVT: `EVT-01-09`. KT: có.

  @TC-01-059 @P1 @Âm @Bảomật
  Kịch bản: TC-01-059 Mở lần hai, liên kết hết hạn
    # Truy vết: FR-01-022 · API-01-040 · ERR-01-024 · BR-01-006.
    Biết liên kết đã `OPENED`; liên kết khác tạo trước 25 giờ (đồng hồ giả); U-T68-TECH.
    Khi TECH mở lại liên kết đã mở.
    Và TECH mở liên kết quá hạn.
    Và thu hồi định danh rồi mở liên kết `PENDING`.
    Thì cả ba `410` ERR-01-024, thân giống nhau; không trả bí mật; liên kết bước 3 ở `CANCELLED`.

  @TC-01-060 @P1 @Âm @Bảomật
  Kịch bản: TC-01-060 Sai người mở liên kết
    # Truy vết: FR-01-022 · API-01-040 · ERR-01-025 · EVT-01-10 · BR-01-005.
    Biết liên kết `PENDING` của `HT-HOTICH`; U-T68-OR2 (đầu mối tổ chức khác); U-T68-TA1.
    Khi OR2 mở liên kết (có MFA).
    Và TA1 mở liên kết.
    Thì `403` ERR-01-025 cho cả hai (TA không phải người nhận); liên kết vẫn `PENDING`; EVT: `EVT-01-10` tới PH-13 và SO.

  @TC-01-061 @P1 @Âm @Bảomật
  Kịch bản: TC-01-061 Mở sai quá số lần, thiếu MFA
    # Truy vết: FR-01-022 · API-01-040 · ERR-01-026, 035 · EVT-01-10 · NFR-01-010.
    Biết liên kết `PENDING`; `handover.maxFailedOpens = 5`; U-T68-TECH.
    Khi TECH mở liên kết khi phiên chưa có MFA mới.
    Và mở với mã liên kết sai 5 lần liên tiếp, rồi lần thứ 6 bằng mã đúng.
    Thì bước 1: `403` ERR-01-035. Bước 2: lần 1 đến 4 `410` hoặc `404`, lần 5 `429` ERR-01-026; liên kết bị hủy, mã đúng cũng không mở được; thông báo "Liên hệ quản trị tỉnh". EVT: `EVT-01-10`.

  @TC-01-062 @P2 @Dương @Âm
  Kịch bản: TC-01-062 Tạo lại liên kết, HTTT đang tạm ngừng, đầu mối chưa có tài khoản
    # Truy vết: FR-01-022 · API-01-039, 041 · ERR-01-003, 024, 048 · BR-01-006.
    Biết liên kết `EXPIRED` chưa mở; liên kết đã `OPENED`; HTTT `SUSPENDED`; đầu mối `tc-chua-tk` chưa có tài khoản; TA1 có MFA mới.
    Khi TA1 `POST /handovers/{handoverId}:reissue` với liên kết `EXPIRED` chưa mở.
    Và gọi `:reissue` với liên kết đã `OPENED`.
    Và tạo liên kết cho HTTT `SUSPENDED`.
    Và tạo liên kết cho đầu mối chưa có tài khoản.
    Thì `201` (liên kết mới, cũ `CANCELLED`); `409` ERR-01-024 (muốn có lại phải xoay vòng, xem Q01-40); `409` ERR-01-048; `400` ERR-01-003.

  @TC-01-063 @P2 @Âm @Chịulỗi
  Kịch bản: TC-01-063 OpenBao ngừng khi mở liên kết
    # Truy vết: FR-01-022 · API-01-040 · ERR-01-023 · BR-01-006.
    Biết liên kết `PENDING`; U-T68-TECH.
    Khi dừng OpenBao; TECH mở liên kết.
    Và khởi động OpenBao; mở lại.
    Thì bước 1: `503` ERR-01-023, liên kết chưa bị tiêu hao. Bước 2: mở được một lần.
