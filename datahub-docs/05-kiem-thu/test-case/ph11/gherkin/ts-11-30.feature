# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-30
Tính năng: TS-11-30 · Hiệu năng, tải và quy mô

  @TC-11-150 @P1 @Hiệu @năng
  Kịch bản: TC-11-150 Khởi tạo phiên: độ trễ và thông lượng khi dồn
    # Truy vết: NFR-11-001, 004, 005 · FR-11-018 · API-11-049
    # Mục đích: Chứng minh p99 ≤ 200 ms ở 100 phiên/s và ≥ 200 phiên/s trong 5 phút, lỗi < 0,1 %, 4 bản sao, đã có 50.000 phiên.
    Biết PERF 4 bản sao; T98 50.000 phiên `RUNNING`; 20 client S-DVC.
    Khi k6 100 phiên/s trong 15 phút, đo p99
    Và k6 tăng tới 200 phiên/s giữ 5 phút
    Và so p99 của hoàn thành việc, tra tiến độ với lúc trước khi có 50.000 phiên
    Thì p99 ≤ 200 ms; thông lượng ≥ 200 phiên/s, lỗi < 0,1 %; chỉ tiêu NFR-11-001…003 không giảm với 50.000 phiên.

  @TC-11-151 @P1 @Hiệu @năng
  Kịch bản: TC-11-151 Hoàn thành việc và xử lý kết quả service task
    # Truy vết: NFR-11-002, 003 · FR-11-038, 029 · API-11-076
    # Mục đích: Chứng minh p99 hoàn thành việc ≤ 300 ms với biểu mẫu 30 trường và p99 xử lý kết quả ≤ 500 ms ở 200 kết quả/s.
    Biết T97; 5.000 việc mở có biểu mẫu 30 trường; `ph04-sim` trả 200 kết quả/s.
    Khi k6 hoàn thành việc ở 50 lượt/s
    Và `ph04-sim` trả kết quả 200/s trong 5 phút
    Và đo theo `traceId` từ lúc nhận bản tin đến khi execution đi tiếp
    Thì p99 API-11-076 ≤ 300 ms; p99 xử lý kết quả ≤ 500 ms.

  @TC-11-152 @P1 @Hiệu @năng
  Kịch bản: TC-11-152 Tra tiến độ và sẵn sàng
    # Truy vết: NFR-11-006, 007 · FR-11-055 · API-11-104, 049, 076
    # Mục đích: Chứng minh p99 tra tiến độ ≤ 100 ms, trúng đệm ≥ 80 %, sẵn sàng ba API chính ≥ 99,9 %.
    Biết T98; 50.000 `businessKey`; thăm dò mỗi 10 giây trong 24 giờ.
    Khi k6 tra tiến độ 500 lượt/s theo phân bố 80 % lặp lại
    Và thăm dò ba API trong 24 giờ không bảo trì
    Và ghi tỷ lệ trúng đệm
    Thì p99 ≤ 100 ms; trúng đệm ≥ 80 %; sẵn sàng 24 giờ ≥ 99,9 % (số liệu tháng đo ở sản xuất, Q11-41).

  @TC-11-153 @P2 @Hiệu @năng
  Kịch bản: TC-11-153 Kiểm tra tĩnh và trình thiết kế
    # Truy vết: NFR-11-013, 014 · FR-11-005, 003 · UI-11-04
    # Mục đích: Chứng minh kiểm tra tĩnh 200 phần tử ≤ 2 giây, mở 300 phần tử ≤ 3 giây, kéo thả ≤ 100 ms.
    Biết mô hình 200 và 300 phần tử; Chromium hiện hành, máy văn phòng 8 GB.
    Khi `:validate?mode=FULL` mô hình 200 phần tử, đo
    Và playwright mở mô hình 300 phần tử, đo đến lúc vẽ xong
    Và đo phản hồi kéo thả
    Thì kiểm tra ≤ 2 giây (không tính gọi PH-04); mở ≤ 3 giây; phản hồi kéo thả ≤ 100 ms.

  @TC-11-154 @P2 @Hiệu @năng
  Kịch bản: TC-11-154 Hộp việc, sự kiện tiến độ, xuất bằng chứng, dọn lịch sử
    # Truy vết: NFR-11-015, 018, 023, 024 · FR-11-035, 056, 057, 064, 063
    # Mục đích: Chứng minh độ trễ hộp việc, sự kiện tiến độ, xuất lịch sử và tác động của dọn lịch sử.
    Biết T97, T99; phiên 50 bước; lô 1.000 phiên cần dọn.
    Khi tạo 1.000 việc, đo thời gian việc hiện ở hộp (p95)
    Và đo từ chuyển bước đến bản tin (p95)
    Và xuất lịch sử phiên 50 bước và gói tuân thủ
    Và chạy dọn lô 1.000 phiên khi tải nền
    Thì hộp việc ≤ 5 giây; sự kiện ≤ 10 giây; lịch sử ≤ 5 giây, gói tuân thủ ≤ 2 phút; p99 API tăng ≤ 10 % khi dọn.
