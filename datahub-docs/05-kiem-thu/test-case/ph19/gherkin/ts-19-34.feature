# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-34
Tính năng: TS-19-34 · Chịu lỗi, phục hồi và an toàn dữ liệu

  @TC-19-826 @P1 @Chịu @lỗi
  Kịch bản: TC-19-826 Mạch ngắt mở và đóng lại theo NCC
    # Truy vết: NFR-19-012 · FR-19-011, 024 · ERR-19-017 · LGC-PAY-009, 023
    Biết `PGSIM` lỗi 60% trong cửa sổ đo.
    Khi tạo 100 giao dịch PV-PG.
    Và cho `PGSIM` phục hồi; chờ hết thời gian nửa mở.
    Thì bước 1: mạch mở; yêu cầu sau đó trả `503` ERR-19-017 ngay (không chờ timeout); NCC hiện "Gián đoạn" ở UI-19-02. Bước 2: lượt thử nửa mở thành công, mạch đóng; trạng thái về "Hoạt động".

  @TC-19-827 @P1 @Chịu @lỗi
  Kịch bản: TC-19-827 Mất một nút CSDL
    # Truy vết: NFR-19-010, 011
    Biết CNPG ba nút, đồng bộ một bản sao; tải 50 giao dịch/giây.
    Khi xóa pod chính của `pg-payment`.
    Và sau khi phục hồi, so số giao dịch đã trả `201` với số trong CSDL.
    Thì bước 1: chuyển chính ≤ 15 phút (mục tiêu < 1 phút). Bước 2: không mất giao dịch đã xác nhận (RPO = 0); yêu cầu lỗi trong lúc chuyển được đối tác thử lại nhờ `Idempotency-Key`, không trùng.

  @TC-19-828 @P2 @Chịu @lỗi
  Kịch bản: TC-19-828 Diễn tập mất site
    # Truy vết: NFR-19-011
    Biết hai site active–standby theo D03-09.
    Khi cắt site chính; kích hoạt site dự phòng theo sổ tay.
    Và đối chiếu giao dịch của 5 phút cuối với nhật ký IPN của `PGSIM`.
    Thì RTO ≤ 4 giờ; RPO ≤ 5 phút; giao dịch thiếu được bù bằng truy vấn chủ động và đối soát ngày; dữ liệu phục hồi qua kiểm tra toàn vẹn.

  @TC-19-829 @P1 @Bảo @mật
  Kịch bản: TC-19-829 Bất biến của bảng chỉ ghi thêm
    # Truy vết: NFR-19-016 · FR-19-028 · BR-19-030
    Biết vai trò `ph19_app`.
    Khi `UPDATE`, `DELETE` trên `transaction_event`, phần nguyên văn của `callback_inbox`, `reconciliation_session` đã `CLOSED`.
    Và `TRUNCATE` bảng `transaction_event`.
    Thì bị từ chối (không có quyền hoặc trigger SQLSTATE P1930); có bản ghi trong log CSDL.

  @TC-19-836 @P2 @Dương
  Kịch bản: TC-19-836 Thời hạn lưu và phân vùng
    # Truy vết: NFR-19-014, 015 · ADR-047
    Biết bảng phân vùng theo tháng; bucket `dh-t68-payment-worm`.
    Khi chạy tác vụ bảo trì phân vùng với đồng hồ giả tiến 13 tháng, rồi 121 tháng.
    Và đọc cấu hình khóa đối tượng và vòng đời của bucket WORM.
    Thì bước 1: phân vùng `integration_log` quá 12 tháng được tách ra lưu nén, không xóa; phân vùng giao dịch chỉ được đề xuất xóa sau 10 năm và cần phê duyệt. Bước 2: chế độ `COMPLIANCE`, thời hạn giữ ≥ 10 năm cho chứng từ, biên bản.

  @TC-19-830 @P1 @Dương
  Kịch bản: TC-19-830 Không dùng số thực cho tiền, định dạng hiển thị
    # Truy vết: NFR-19-017, 030
    Biết giao dịch 9.007.199.254.740.993 ₫ (vượt `Number.MAX_SAFE_INTEGER`) trong dữ liệu thử UT.
    Khi quét mã nguồn: ArchUnit cấm `double`, `float`, `BigDecimal` có phần lẻ ở gói `vn.datahub.payment`; ESLint cấm phép tính `Number` trên trường tiền.
    Và hiển thị giá trị trên ở UI-19-15.
    Thì bước 1: không vi phạm. Bước 2: hiện `9.007.199.254.740.993 ₫` đúng từng chữ số; thời điểm dạng `dd/MM/yyyy HH:mm:ss`.

  @TC-19-831 @P1 @Bảo @mật
  Kịch bản: TC-19-831 Bí mật và dữ liệu cá nhân không lộ, không lưu dữ liệu thẻ
    # Truy vết: NFR-19-022, 024 · BR-19-032 · FR-19-024, 054 · LGC-PAY-022
    Biết sau khi chạy toàn bộ TS-19-01…29.
    Khi quét log ứng dụng, `integration_log`, sự kiện Kafka, CSDL bằng bộ mẫu (chuỗi bí mật thử, số thẻ dạng Luhn, họ tên, điện thoại bản rõ của dữ liệu thử).
    Và kiểm cột dữ liệu cá nhân trong `transaction`.
    Thì bước 1: không khớp mẫu nào. Bước 2: cột ở dạng mã hóa `vault:v1:…`; giải mã chỉ được bằng khóa Transit của đúng tenant.

  @TC-19-832 @P2 @Chịu @lỗi
  Kịch bản: TC-19-832 Triển khai cuốn chiếu không gián đoạn
    # Truy vết: NFR-19-031, 010
    Biết tải 50 giao dịch/giây; bản mới có một thay đổi Liquibase mở rộng.
    Khi triển khai bản mới.
    Thì không yêu cầu nào lỗi do triển khai; bản cũ và mới cùng chạy trên lược đồ mới trong lúc chuyển.

  @TC-19-833 @P2 @Dương
  Kịch bản: TC-19-833 Thêm NCC mới chỉ bằng adapter; hợp đồng bộ giả lập
    # Truy vết: NFR-19-027, 032 · FR-19-010 · LGC-PAY-005
    Biết adapter mẫu `DemoBankAdapter` trong mã thử.
    Khi đăng ký adapter mẫu; tạo NCC dùng adapter đó; chạy luồng khởi tạo, IPN, truy vấn.
    Và chạy kiểm thử hợp đồng của `PGSIM` với OpenAPI và AsyncAPI.
    Thì bước 1 chạy đủ mà không đổi mã lõi, lược đồ, API đối tác (ArchUnit xác nhận phụ thuộc một chiều). Bước 2 đạt.

  @TC-19-834 @P2 @Dương
  Kịch bản: TC-19-834 Lệch đồng hồ và ngày giao dịch theo giờ Việt Nam
    # Truy vết: NFR-19-028 · BR-19-025
    Biết giao dịch thành công lúc 23:59:59 và 00:00:01 giờ Việt Nam.
    Khi chạy phiên đối soát ngày D.
    Thì giao dịch 23:59:59 thuộc ngày D, 00:00:01 thuộc D+1 (tính theo UTC+7); cảnh báo khi độ lệch NTP > 1 s.

  @TC-19-835 @P3 @Dương
  Kịch bản: TC-19-835 Vết đầu-cuối và lấy mẫu
    # Truy vết: NFR-19-026 · FR-19-055
    Biết một giao dịch thất bại.
    Khi tìm `trace_id` của giao dịch ở PH-13.
    Thì có đủ chặng: APISIX, `dh-payment` api, gọi NCC, IPN, worker, webhook; vết lỗi được giữ 100%.
