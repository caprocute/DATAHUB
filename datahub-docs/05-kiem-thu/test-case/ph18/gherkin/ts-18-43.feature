# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-43
Tính năng: TS-18-43 · Đóng an toàn, chịu lỗi và phụ thuộc mềm

  @TC-18-145 @P1 @Chịu_lỗi
  Kịch bản: TC-18-145 PH-13 vắng: đọc và tiếp nhận vẫn chạy, chẩn đoán trả một phần, thao tác ghi cần kiểm toán bị từ chối
    # Truy vết: FR-18-013, 019, 021, 070 · BR-18-046, 011 · ERR-18-008, 106
    # Mục đích: Chứng minh LP-18-04 với PH-13: không có kiểm toán thì không có hiệu lực, nhưng màn đọc và tiếp nhận không bị chặn.
    Biết T94; ngắt PH-13 (kiểm toán và API-13-069) 15 phút; đẩy 500 bản tin lỗi trong lúc ngắt.
    Khi TO mở danh sách và chi tiết mục.
    Và TO phân loại một mục.
    Và kiểm số mục mới.
    Thì bước 1 `200`, khung chẩn đoán ghi ERR-18-106. Bước 2 `503` ERR-18-008. Bước 3 500 mục `NEW`, không mất.

  @TC-18-146 @P1 @Chịu_lỗi @Lũy_đẳng
  Kịch bản: TC-18-146 PH-04 runtime vắng khi phát lại: yêu cầu nằm ở topic, quá hạn rồi nhận kết quả một lần khi PH-04 trở lại
    # Truy vết: FR-18-027, 030 · BR-18-019, 020 · ERR-18-108, 109 · EVT-18-09
    # Mục đích: Chứng minh phát lại không gọi thẳng hệ đích khi nguồn vắng và kết quả muộn được nhận lũy đẳng.
    Biết T94; dừng consumer `dh-runtime` của `t94.ops.replay.requested.v1` 40 phút; lượt 20 mục; một nguồn `HTTP_PORT` khác cũng ngắt.
    Khi chạy lượt khi PH-04 dừng.
    Và chờ quá `18.dlq.replay.result-timeout-minutes`.
    Và bật lại PH-04.
    Thì bước 1 20 EVT-18-09 nằm ở topic; nguồn `HTTP_PORT` ghi ERR-18-108. Bước 2 mục `REPLAY_FAILED` ghi ERR-18-109. Bước 3 PH-04 xử lý mỗi khóa đúng một lần, callback đưa mục về `RESOLVED`; hệ đích nhận 0 lời gọi từ PH-18.

  @TC-18-147 @P1 @Chịu_lỗi @Bảo_mật
  Kịch bản: TC-18-147 PH-09 vắng: biến mẫu và trường payload chưa rõ mức được coi là cấm hoặc cần bốn mắt
    # Truy vết: FR-18-035, 024 · BR-18-027, 018 · ERR-18-039
    # Mục đích: Chứng minh đóng an toàn khi không phân loại được dữ liệu (BR-18-027, Q18-45).
    Biết T94; WireMock PH-09 trả `503`.
    Khi TA1 gửi duyệt phiên bản mẫu có biến mới.
    Và IE tạo bản sửa payload chạm trường mới.
    Thì bước 1 `422` ERR-18-039 (biến chưa xác định mức). Bước 2 bản sửa `PENDING_APPROVAL` thay vì `APPROVED` ngay.

  @TC-18-148 @P2 @Chịu_lỗi
  Kịch bản: TC-18-148 Registry PH-20 vắng: tác vụ nền dùng danh sách tenant gần nhất, không dừng
    # Truy vết: FR-18-033, 044, 052, 072 · BR-18-007
    # Mục đích: Chứng minh tác vụ dọn, nhắc, thu thập sao lưu không dừng toàn bộ khi `/internal/tenant/v1/tenants?status=ACTIVE` không trả lời.
    Biết T94; WireMock PH-20 ngắt 2 giờ; danh sách tenant gần nhất có 3 tenant.
    Khi chạy tác vụ dọn và nhắc.
    Và xem `GET /health`.
    Thì tác vụ chạy cho 3 tenant đã biết; `health` báo phụ thuộc `PH-20` `DOWN`, mô-đun `task` `DEGRADED`; không lỗi lan sang API người dùng.

  @TC-18-149 @P1 @Chịu_lỗi
  Kịch bản: TC-18-149 Giết bản sao, ngắt CSDL 60 giây và Garage 60 giây khi nạp 100.000 bản tin lỗi
    # Truy vết: FR-18-013, 016 · BR-18-011, 015 · NFR-18-002, 016
    # Mục đích: Chứng minh NFR-18-002: 0 mục mất, 0 mục trùng sau khử trùng.
    Biết PERF (T97); 100.000 bản tin `DLQ-SET-PERF` có `dh-message-id` duy nhất, 5 % lớn hơn 256 KB; Chaos Mesh.
    Khi bắt đầu nạp; ở phút 2 giết một bản sao `dh-platform`; ở phút 4 ngắt CSDL 60 giây; ở phút 7 ngắt Garage 60 giây.
    Và chờ tiêu thụ hết, đếm theo `dh-message-id`.
    Thì số mục bằng 100.000, không khóa trùng; mọi payload lớn có đối tượng Garage khớp SHA-256; độ trễ tiêu thụ trở về 0 trong 10 phút sau sự cố cuối.
