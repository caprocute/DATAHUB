# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-28
Tính năng: TS-11-28 · Idempotency khởi tạo, lệnh, kết quả, thông điệp, sự kiện

  @TC-11-143 @P1 @Chịu @lỗi
  Kịch bản: TC-11-143 Khởi tạo đồng thời cùng hồ sơ
    # Truy vết: FR-11-018 · API-11-049 · BR-11-007, 023
    # Mục đích: Chứng minh 50 lượt khởi tạo đồng thời cùng `businessKey` chỉ tạo một phiên.
    Biết T97; hai bản sao `dh-platform`; `businessKey` mới.
    Khi 50 luồng song song `POST /instances` cùng `businessKey`, một nửa cùng `Idempotency-Key`
    Và đếm `instance_index`, `ACT_RU_EXECUTION`, `outbox_event`
    Thì đúng một phiên, một bản tin `instance.started`; 49 phản hồi `200` cùng `instanceId` (hoặc phản hồi lần đầu); không `ACT_RU_EXECUTION` thừa.

  @TC-11-144 @P1 @Chịu @lỗi
  Kịch bản: TC-11-144 Giao lại kết quả, thông điệp, sự kiện khởi tạo
    # Truy vết: FR-11-029, 030, 019 · EVT-11-18 · ERR-11-104 · BR-11-022
    # Mục đích: Chứng minh Kafka giao lại 5 lần mỗi loại chỉ tác dụng một lần, kể cả khi pod chết trước khi cam kết offset.
    Biết kết quả `completed`, thông điệp `HO_SO_BO_SUNG`, sự kiện khởi tạo PH-10; Chaos tắt pod.
    Khi giao mỗi loại 5 lần cùng `id`
    Và tắt pod sau khi ghi `inbox_message` và trước khi cam kết offset
    Và đếm tác dụng
    Thì `inbox_message` duy nhất theo `id`; phiên đi tiếp một lần, không bản tin tiến độ trùng; bộ đếm trùng tăng (ERR-11-104).

  @TC-11-145 @P1 @Chịu @lỗi
  Kịch bản: TC-11-145 Lệnh service task gửi lại không gọi HTTT hai lần
    # Truy vết: FR-11-028 · API-11-071 · EVT-11-17 · BR-11-022
    # Mục đích: Chứng minh gửi lại cùng `commandId` sau lỗi Kafka, và lệnh mới sau `:resend`, đều được PH-04 chống trùng.
    Biết `ph04-sim` đếm số lần gọi HTTT giả theo `commandId`; Kafka chập chờn.
    Khi gây lỗi Kafka khi đẩy lệnh rồi hồi phục
    Và TO `:resend` khi kết quả đã tới
    Và đọc số lần gọi HTTT giả
    Thì mỗi `commandId` gọi HTTT giả đúng một lần; lệnh cũ không chạy lại sau khi có lệnh mới; không bước nào thực thi hai lần.
