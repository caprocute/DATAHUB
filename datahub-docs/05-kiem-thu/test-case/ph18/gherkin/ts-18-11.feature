# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-11
Tính năng: TS-18-11 · Xem và đề nghị phát lại DLQ tầng sự kiện của PH-10

  @TC-18-034 @P1 @Dương
  Kịch bản: TC-18-034 Xem siêu dữ liệu DLQ tầng sự kiện và đề nghị PH-10 phát lại
    # Truy vết: FR-18-017 · API-18-039, 040 · BR-18-016, 019 · UI-18-01
    # Mục đích: Chứng minh BR-18-016: chỉ siêu dữ liệu được hiển thị, nội dung không vào `ph18_ops`, đề nghị phát lại gọi API-10-061 bằng scope `event:replay`.
    Biết T90; WireMock PH-10 trả 5 mục cho API-10-060; U-T90-TO.
    Khi U-T90-TO mở UI-18-01 tab "Tầng sự kiện".
    Và `POST /dlq/event-dead-letters/{entryRef}:request-replay`.
    Và kiểm bảng `dlq_message` và Garage của T90.
    Thì bước 1 5 dòng có nhãn nguồn PH-10, chỉ siêu dữ liệu. Bước 2 `202`, WireMock nhận đúng một lời gọi tới API-10-061 với `entryRef`. Bước 3 không có dòng hay đối tượng nào mang nội dung của mục PH-10.

  @TC-18-035 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-035 PH-10 không phản hồi thì tab tầng sự kiện báo lỗi, danh sách DLQ của PH-18 vẫn dùng được
    # Truy vết: FR-18-017, 019 · API-18-039, 040, 041 · ERR-18-035 · UI-18-01
    # Mục đích: Chứng minh fail-soft khi PH-10 vắng: lỗi chỉ ở phần liên thông, không chặn danh sách chính.
    Biết T94; WireMock PH-10 trễ 10 giây rồi ngắt.
    Khi `GET /dlq/event-dead-letters`.
    Và đề nghị phát lại một mục PH-10.
    Và `GET /dlq/messages`.
    Thì bước 1 và 2 `503` ERR-18-035. Bước 3 `200` bình thường; UI-18-01 hiện dải cảnh báo ở tab tầng sự kiện, các tab khác không bị ảnh hưởng.
