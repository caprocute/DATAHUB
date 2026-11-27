# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-19
Tính năng: TS-18-19 · Lưu giữ, dọn, thống kê DLQ và phát sự kiện vượt ngưỡng

  @TC-18-065 @P1 @Dương @Biên
  Kịch bản: TC-18-065 Dọn mục đóng quá 90 ngày, giữ mục mở và mục gắn sự cố mở
    # Truy vết: FR-18-033 · API-18-080 · BR-18-025 · UI-18-06
    # Mục đích: Chứng minh BR-18-025: tác vụ dọn xóa payload ở CSDL và Garage của mục đóng quá `18.dlq.retention.closed-days`, giữ siêu dữ liệu, hoãn mục gắn sự cố mở.
    Biết T95 (đồng hồ giả); 10 mục `RESOLVED` đóng 91 ngày trước (3 có payload ở Garage), 1 mục trong số đó liên kết sự cố `INC-T95-01` đang `INVESTIGATING`; 5 mục `NEW` 200 ngày tuổi.
    Khi chạy tác vụ dọn.
    Và `GET /dlq/retention`.
    Và đóng sự cố, chạy lại tác vụ dọn.
    Thì bước 1 9 mục `EXPIRED`, payload xóa, 2 đối tượng Garage bị xóa; mục gắn sự cố giữ nguyên; 5 mục `NEW` không đổi. Bước 2 số mục sắp hết hạn, lần dọn gần nhất, dung lượng. Bước 3 mục còn lại `EXPIRED`.

  @TC-18-066 @P2 @Âm @Chịu_lỗi
  Kịch bản: TC-18-066 Đối tượng Garage lệch tổng kiểm tra lúc dọn được báo, không xóa nhầm
    # Truy vết: FR-18-033 · BR-18-014, 025 · ERR-18-104
    # Mục đích: Chứng minh tác vụ dọn không im lặng khi đối tượng lệch tổng kiểm tra.
    Biết T95; một mục đóng quá hạn có đối tượng Garage bị sửa.
    Khi chạy tác vụ dọn.
    Thì mục được dọn chỉ mục, ghi ERR-18-104 và chỉ số lỗi; UI-18-06 hiện số đối tượng lệch để PA xử lý.

  @TC-18-067 @P1 @Dương @Âm
  Kịch bản: TC-18-067 Thống kê theo khoảng, chỉ số Prometheus và EVT-18-08 khi vượt độ sâu
    # Truy vết: FR-18-034 · API-18-081 · BR-18-026 · ERR-18-003 · EVT-18-08 · UI-18-06, 24
    # Mục đích: Chứng minh FR-18-034 và BR-18-026: số liệu đúng, chỉ số `dh_ops_dlq_depth` theo nguồn, sự kiện khi vượt `18.dlq.threshold.depth` và `age-hours`; không có luật cảnh báo trong PH-18.
    Biết T92 với `18.dlq.threshold.depth = 50`; 49 mục mở; Prometheus của TEST.
    Khi `GET /dlq/stats?khoang=7d`.
    Và thêm 2 mục.
    Và đọc chỉ số `dh_ops_dlq_depth{source="SRC-PH04"}` và topic `t92.ops.dlq.threshold-crossed.v1`.
    Và `GET /dlq/stats?khoang=abc`.
    Thì bước 1 `200` theo nguồn, luồng, lớp, trạng thái, xu hướng. Bước 3 chỉ số 51, đúng một EVT-18-08 `type = DEPTH`, `value = 51`, `threshold = 50`; cấu hình PH-18 không có luật cảnh báo. Bước 4 `400` ERR-18-003.
