# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-44
Tính năng: TS-18-44 · Hiệu năng, quy mô và sẵn sàng

  @TC-18-150 @P1 @Hiệu_năng
  Kịch bản: TC-18-150 Tiếp nhận DLQ 200 bản tin mỗi giây mỗi phân vùng, trễ hiện trên màn p95 ≤ 5 giây
    # Truy vết: NFR-18-001 · FR-18-013, 016
    # Mục đích: Đo NFR-18-001.
    Biết PERF (T97); 6 phân vùng; payload trung bình 8 KB, 5 % lớn hơn 256 KB; `dh-platform` 3 bản sao.
    Khi nạp 1.200 bản tin mỗi giây trong 15 phút.
    Và đo từ thời điểm ghi topic tới khi `GET /dlq/messages` trả mục.
    Thì thông lượng ≥ 200 bản tin mỗi giây mỗi phân vùng; p95 trễ ≤ 5 giây; không tăng độ trễ tiêu thụ kéo dài.

  @TC-18-151 @P1 @Hiệu_năng
  Kịch bản: TC-18-151 Danh sách DLQ 1 triệu mục, 200 người dùng đồng thời
    # Truy vết: NFR-18-003 · FR-18-019 · API-18-041
    # Mục đích: Đo NFR-18-003.
    Biết PERF (T97) 1 triệu mục; 200 người dùng ảo với bộ lọc ngẫu nhiên.
    Khi chạy 30 phút trang 50 dòng có `facets`.
    Thì p95 ≤ 1,5 giây, p99 ≤ 3 giây, lỗi < 0,1 %.

  @TC-18-152 @P1 @Hiệu_năng
  Kịch bản: TC-18-152 Đọc tham số lô 500 yêu cầu mỗi giây và lan truyền đổi tham số
    # Truy vết: NFR-18-004, 005 · FR-18-002, 006 · API-18-028
    # Mục đích: Đo NFR-18-004 và NFR-18-005.
    Biết PERF; 100 khóa mỗi yêu cầu; 30 DU giả lập dùng `dh-ops-client`.
    Khi chạy 500 yêu cầu mỗi giây trong 10 phút, 70 % kèm `If-None-Match`.
    Và đổi 20 khóa trong lúc chạy, đo phiên bản đệm của mọi bản sao.
    Thì đọc p95 ≤ 50 ms; `304` p95 ≤ 20 ms; lan truyền p95 ≤ 60 giây.

  @TC-18-153 @P1 @Hiệu_năng
  Kịch bản: TC-18-153 Phát lại 10.000 mục ở tốc độ mặc định
    # Truy vết: NFR-18-006 · FR-18-028, 029
    # Mục đích: Đo NFR-18-006.
    Biết PERF; lượt 10.000 mục đã duyệt; cổng nguồn giả lập phản hồi 50 ms; tốc độ 10 mục mỗi giây (giả định áp trần nguồn 20 mục mỗi giây để lượt chạy đủ nhanh).
    Khi chạy lượt, đo thời gian và tốc độ thực.
    Thì thời gian ≤ 20 phút với tốc độ đặt cho lượt; sai lệch tốc độ ≤ 10 %.

  @TC-18-154 @P1 @Hiệu_năng
  Kịch bản: TC-18-154 Thông báo 10.000 mỗi giờ, thư đồng bộ và URGENT khi hàng đợi tồn
    # Truy vết: NFR-18-007, 008 · FR-18-036 · API-18-091, 092
    # Mục đích: Đo NFR-18-007 và NFR-18-008.
    Biết PERF (T99); MOCK-SMTP, MOCK-SMS; hàng đợi thường tồn 5.000 thông báo.
    Khi gửi 10.000 thông báo trong một giờ.
    Và gửi 200 thư đồng bộ.
    Và gửi 100 thông báo `URGENT` khi hàng tồn.
    Thì bất đồng bộ p95 ≤ 60 giây; đồng bộ p95 ≤ 3 giây; `URGENT` p95 ≤ 30 giây.

  @TC-18-155 @P2 @Hiệu_năng
  Kịch bản: TC-18-155 Việc của tôi 50 việc mở mỗi người, việc hiện trong 10 giây
    # Truy vết: NFR-18-009 · FR-18-043, 044 · API-18-109, 111
    # Mục đích: Đo NFR-18-009.
    Biết PERF; 2.000 người dùng, mỗi người 50 việc mở.
    Khi 200 người dùng ảo gọi `GET /me/tasks` trong 15 phút.
    Và phân hệ giả lập tạo 1.000 việc, đo tới khi hiện.
    Thì danh sách p95 ≤ 800 ms; việc hiện ≤ 10 giây.

  @TC-18-156 @P1 @Hiệu_năng
  Kịch bản: TC-18-156 Khôi phục tenant 200 GB trong 4 giờ
    # Truy vết: NFR-18-010, 017 · FR-18-055
    # Mục đích: Đo NFR-18-010 cùng AC-18-10 ở diễn tập.
    Biết PERF (T98) hồ sơ `QM-VUA` 200 GB theo D03-09 §8.5.
    Khi duyệt yêu cầu khôi phục, đo từ lúc duyệt tới `SUCCEEDED` (Q18-46).
    Thì tổng thời gian ≤ 4 giờ, thời gian từng bước ghi ở `tenant_restore_step`; tenant khác cùng ô không đổi.

  @TC-18-157 @P2 @Hiệu_năng
  Kịch bản: TC-18-157 Xuất tenant 200 GB và chuyển sáp nhập 50 GB một phân hệ
    # Truy vết: NFR-18-011, 022 · FR-18-056, 057
    # Mục đích: Đo NFR-18-011 và NFR-18-022.
    Biết PERF (T98) `QM-VUA`.
    Khi xuất 200 GB.
    Và chuyển sáp nhập 50 GB của PH-04 sang tenant `QM-VUA` thứ hai.
    Thì xuất ≤ 2 giờ, tổng kiểm tra 100 % tệp; chuyển ≤ 2 giờ, 0 bản ghi mất `origin_tenant_id`.

  @TC-18-158 @P2 @Hiệu_năng
  Kịch bản: TC-18-158 Thông lượng di trú 300 bản ghi mỗi giây qua API nhập
    # Truy vết: NFR-18-013 · FR-18-062
    # Mục đích: Đo NFR-18-013.
    Biết PERF (T99); danh mục Aita giả lập 500.000 bản ghi; lô 500; API nhập PH-07 giả lập phản hồi 80 ms.
    Khi chạy thật đã duyệt.
    Thì thông lượng trung bình ≥ 300 bản ghi mỗi giây; không lỗi ERR-18-069.

  @TC-18-159 @P2 @Hiệu_năng
  Kịch bản: TC-18-159 Sẵn sàng 99,5 % và giữ bản tin khi PH-18 gián đoạn tới 7 ngày
    # Truy vết: NFR-18-016 · FR-18-072
    # Mục đích: Đo NFR-18-016 bằng giám sát tháng ở STAGING và kiểm cấu hình giữ topic.
    Biết STAGING; Prometheus 30 ngày; cấu hình topic `{tenant}.ops.dlq.v1`.
    Khi tính tỷ lệ sẵn sàng của API người dùng trong 30 ngày.
    Và kiểm `retention.ms` của topic DLQ.
    Thì tỷ lệ ≥ 99,5 %; thời hạn giữ topic ≥ 7 ngày.
