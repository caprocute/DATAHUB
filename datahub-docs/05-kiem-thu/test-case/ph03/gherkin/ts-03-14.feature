# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-14
Tính năng: TS-03-14 · Truy vết, WebSocket và chuyển đổi gRPC

  @TC-03-061 @P1 @Dương @Âm
  Kịch bản: TC-03-061 Sinh và truyền `traceparent`, trả `X-Trace-Id`
    # Truy vết: FR-03-032 · UI-03-09 · UC-03-01 · BR-03-023 · NFR-03-020 · NFR-00-051.
    Biết `r-ho-tich`; C-HTTT1.
    Khi gọi không có `traceparent`.
    Và gọi có `traceparent` hợp lệ.
    Và gọi có `traceparent` sai định dạng.
    Và gọi gây lỗi `429` và `403`.
    Thì bước 1 gateway sinh `traceparent` mới gửi cho backend; phản hồi có `X-Trace-Id`. Bước 2 giữ nguyên `trace-id`, tạo `span` mới. Bước 3 thay bằng id mới, không lỗi. Bước 4 phản hồi lỗi vẫn có `X-Trace-Id`; 100 % lượt gọi có `trace_id` ở nhật ký và vết lỗi giữ 100 %.

  @TC-03-062 @P2 @Dương @Âm
  Kịch bản: TC-03-062 WebSocket: nâng cấp, tin nhắn, giới hạn kết nối, đóng khi thu hồi
    # Truy vết: FR-03-033 · API-03-002 · UI-03-03 · UC-03-07 · ERR-03-101, 116 · BR-03-001 · NFR-03-004 · CMP-LAW-09.
    Biết `r-ws` có giới hạn 50 kết nối mỗi consumer; C-HTTT1.
    Khi mở kết nối `wss://…/ws/thong-bao` kèm token; gửi 100 tin nhắn; bật `permessage-deflate`.
    Và mở 51 kết nối đồng thời.
    Và mở kết nối không có token; gửi frame quá lớn (> giới hạn của route).
    Và thu hồi token khi kết nối đang mở.
    Thì bước 1 nhận đủ 100 tin, nén hoạt động. Bước 2 kết nối thứ 51 `429` Lỗi GW 116. Bước 3 `401` mã 102 trước khi nâng cấp; frame quá lớn đóng kết nối (mã đóng 1009). Bước 4 kết nối đóng ≤ 60 s.

  @TC-03-063 @P3 @Biên
  Kịch bản: TC-03-063 Chuyển đổi gRPC và REST: hỗ trợ và chưa hỗ trợ
    # Truy vết: FR-03-034 · API-03-002 · UI-03-03 · UC-03-07 · ERR-03-125, 005 · BR-03-017.
    Biết hồ sơ triển khai Đợt 3 bật plugin chuyển đổi; route `r-grpc`; hồ sơ MVP tắt plugin.
    Khi Ở hồ sơ Đợt 3 gọi REST tới `r-grpc`.
    Và gọi kiểu chuyển đổi không hỗ trợ (SOAP sang gRPC).
    Và Ở hồ sơ MVP phát cấu hình có route `r-grpc`.
    Thì bước 1 trả thân REST từ backend gRPC. Bước 2 `501` Lỗi GW 125 "Kiểu chuyển đổi giao thức này chưa được hỗ trợ." Bước 3 `422` ERR-03-005 (plugin ngoài danh mục được duyệt của hồ sơ). Ca chỉ bắt buộc chạy khi bật Đợt 3.
