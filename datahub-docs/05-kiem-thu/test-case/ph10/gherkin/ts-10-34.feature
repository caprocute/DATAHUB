# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-34
Tính năng: TS-10-34 · Chịu lỗi, hỗn loạn và phục hồi

  @TC-10-150 @P1 @Khả @dụng
  Kịch bản: TC-10-150 Không mất sự kiện khi mất một broker và khởi động lại bộ giao nhận
    # Truy vết: NFR-10-006 · FR-10-033, 038, 049 · BR-10-007, 024
    Biết PERF; 1 triệu sự kiện qua API phát vào TP-CP; SUB-PUSH tới SIM-WH đếm theo `Webhook-Id`.
    Khi trong lúc phát và giao: giết một broker; xóa ngẫu nhiên pod cổng sự kiện và bộ giao nhận 10 lần; ngắt mạng SIM-WH 2 phút.
    Và đối chiếu số `202`, số bản tin Kafka, số `Webhook-Id` duy nhất SIM-WH nhận cộng mục DLQ.
    Thì 0 sự kiện mất: mọi `id` được `202` có trên Kafka và hoặc được SIM-WH nhận, hoặc có mục DLQ.

  @TC-10-151 @P2 @Khả @dụng
  Kịch bản: TC-10-151 Tỷ lệ giao trùng trong vận hành bình thường
    # Truy vết: NFR-10-007 · BR-10-009
    Biết PERF; tải nền 24 giờ.
    Khi đếm lượt SIM-WH nhận có `Webhook-Id` lặp.
    Thì ≤ 0,1 % lượt giao; mọi lượt trùng cùng `Webhook-Id`.

  @TC-10-152 @P1 @Khả @dụng
  Kịch bản: TC-10-152 Data plane chạy khi control plane và pg-core ngừng
    # Truy vết: NFR-10-013 · FR-10-033, 038, 043 · ERR-10-029
    Biết SIT; tải nền phát, đẩy, kéo.
    Khi dừng `dh-integration` và `pg-core` 30 phút.
    Và gọi một lệnh control plane bất kỳ.
    Và khởi động lại.
    Thì bước 1 API phát, API kéo, bộ giao nhận tiếp tục với ảnh chụp cấu hình ở Valkey; `dh_event_runtime_config_age_seconds` tăng, cảnh báo sau 10 phút; mục DLQ chờ trên topic `.dlq`. Bước 2 `503` ERR-10-029. Bước 3 bộ ghi DLQ tạo đủ mục từ topic `.dlq`; số liệu giao nhận đệm ≤ 15 phút được gửi bù.

  @TC-10-153 @P2 @Khả @dụng
  Kịch bản: TC-10-153 Outbox không mất sự kiện PH-10 khi Kafka ngừng
    # Truy vết: FR-10-009, 037 · EVT-10-01, 08
    Biết SIT; 20 lệnh duyệt trong lúc Kafka ngừng 5 phút.
    Khi dừng Kafka, duyệt topic và subscription; bật lại.
    Thì mọi EVT `topic.activated`, `subscription.activated` được phát sau khi Kafka trở lại, đúng thứ tự theo khóa, không trùng ngoài ngữ nghĩa ít nhất một lần.

  @TC-10-154 @P2 @Khả @dụng
  Kịch bản: TC-10-154 Sao cấu hình sang site DR
    # Truy vết: NFR-10-019
    Biết hai site SIT với MirrorMaker 2 qua listener `replication`.
    Khi tạo topic, ACL, nhóm tiêu thụ ở site chính; cắt site chính; chuyển sang site DR.
    Thì cấu hình topic, ACL, offset nhóm có ở site DR với RPO < 30 giây; subscription tiếp tục từ offset đã dịch.
