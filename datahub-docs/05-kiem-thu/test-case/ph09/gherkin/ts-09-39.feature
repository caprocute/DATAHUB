# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-39
Tính năng: TS-09-39 · Hiệu lực tức thời và đồng hồ

  @TC-09-135 @P1 @Hiệu @năng @Bảo
  Kịch bản: TC-09-135 Thu hồi chấp thuận có hiệu lực tại điểm thực thi ≤ 15 giây
    # Truy vết: FR-09-017, 019 · NFR-09-005 · BR-09-017 · EVT-09-08 · API-09-073, 227
    # Mục đích: Đo độ trễ thu hồi, tạm dừng bằng sự kiện đẩy; kênh bundle là dự phòng.
    Biết T97; 3 PEP (PH-03, PH-04, PH-14) bật đệm; 100 chấp thuận `ACTIVE`; mỗi PEP gọi `purpose:decide` 10 lượt mỗi giây.
    Khi DO1 thu hồi 100 chấp thuận lần lượt; đo từ `:revoke` đến lượt `deny` đầu tiên ở từng PEP.
    Và lặp với `:suspend`.
    Và chặn kênh sự kiện đẩy, thu hồi 10 chấp thuận.
    Thì bước 1 và 2 p95 ≤ 15 giây, tối đa ≤ 15 giây. Bước 3 hiệu lực qua bundle p99 ≤ 60 giây.

  @TC-09-136 @P1 @Hiệu @năng
  Kịch bản: TC-09-136 Đồng bộ chính sách và chấp thuận tới mọi OPA p99 ≤ 60 giây
    # Truy vết: NFR-09-005, 020 · FR-09-018 · API-09-078 · EVT-09-11
    # Mục đích: Đo NFR-09-005 và OPA nạp ≤ 2 giây.
    Biết T97; 3 OPA; 3.000 chấp thuận hiệu lực; bundle gần 5 MB.
    Khi thực hiện 200 thay đổi chấp thuận rải 20 phút; đo `bundle_loaded` từng OPA.
    Thì p99 ≤ 60 giây; bundle ≤ 5 MB; OPA nạp ≤ 2 giây.

  @TC-09-137 @P1 @Biên
  Kịch bản: TC-09-137 Phiếu xem đầy đủ hết hạn đúng 60 giây ± 1 giây
    # Truy vết: NFR-09-015 · FR-09-029 · API-09-236 · BR-09-026
    # Mục đích: Đo độ chính xác hết hạn của phiếu và việc không ghi đĩa.
    Biết T90; đồng hồ thực; `09.mask.reveal-seconds = 60`.
    Khi cấp phiếu 20 lần; gọi `:verify` ở giây 59, 60, 61.
    Thì hết hạn ở 60 ± 1 giây; giây 59 `200`, giây 61 `403` ERR-09-112; giá trị rõ không có trên đĩa nút DU.

  @TC-09-138 @P1 @Chịu @lỗi @Biên
  Kịch bản: TC-09-138 Đồng hồ 72 giờ bền qua khởi động lại và đổi múi giờ
    # Truy vết: NFR-09-017 · BR-09-054 · FR-09-059 · EVT-09-31
    # Mục đích: Chứng minh đồng hồ không đặt lại khi dịch vụ khởi động lại và cảnh báo không bị bỏ sót hay lặp.
    Biết T95 đồng hồ giả; vụ việc `detectedAt` = T0; múi giờ hiển thị `Asia/Ho_Chi_Minh`, lưu UTC.
    Khi tiến đến T0+23 giờ 59 phút; xóa pod rồi chờ dịch vụ lên.
    Và tiến đến T0+24 giờ, +48 giờ.
    Thì EVT: `breach.deadline-near` đúng một lần mỗi mốc ± 1 phút; `clock` hiển thị còn đúng thời gian; không mốc nào lặp lại sau khởi động.
