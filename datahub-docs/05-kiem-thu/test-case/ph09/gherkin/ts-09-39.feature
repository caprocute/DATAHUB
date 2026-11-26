# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-39
Tính năng: TS-09-39 · Hiệu lực tức thời và đồng hồ

  @TC-09-135 @P1 @Hiệu @năng @Bảo
  Kịch bản: TC-09-135 Thu hồi chấp thuận có hiệu lực tại điểm thực thi ≤ 15 giây
    # Truy vết: FR-09-017, 019 · NFR-09-005, 024 · BR-09-017 · EVT-09-08 · API-09-073, 227
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

  @TC-09-150 @P1 @Dương @Biên
  Kịch bản: TC-09-150 Đệm quyết định tối đa 15 giây cho ALLOW, 5 giây cho DENY
    # Truy vết: FR-09-019 · API-09-227 · ERR-09-078 · BR-09-062 · NFR-09-024 · EVT-09-08
    # Mục đích: Chứng minh BR-09-062: thư viện `dh-privacy-client` không đệm quá trần, để không dò được từng trường qua kết quả đệm.
    Biết T97; PEP dùng `dh-privacy-client`; `09.decision.cache-seconds = 15`; chấp thuận G1 `ACTIVE`, trường `cccd` chưa thuộc G1; đồng hồ giả.
    Khi PEP gọi `purpose:decide` cho trường được phép ở giây 0, 10 và 16.
    Và PEP gọi cho `cccd` (bị từ chối) ở giây 0, 3 và 6.
    Và đặt `09.decision.cache-seconds = 3`; lặp bước 2 cách nhau 4 giây.
    Và khi quyết định `ALLOW` còn trong đệm, DO thu hồi G1.
    Và TA đặt `09.decision.cache-seconds = 30`.
    Thì bước 1 chỉ lượt giây 0 và 16 tới PH-09, lượt giây 10 lấy từ đệm. Bước 2 lượt giây 3 lấy từ đệm, lượt giây 6 tới PH-09 vì `DENY` chỉ đệm 5 giây. Bước 3 cả hai lượt tới PH-09 (tham số nhỏ hơn 5 giây thì lấy tham số). Bước 4 đệm bị xóa ngay, lượt kế tiếp bị từ chối trong ≤ 15 giây (NFR-09-024). Bước 5 `422` ERR-09-078 "Giá trị của 09.decision.cache-seconds ngoài miền cho phép 0…15."
