# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-05
Tính năng: TS-13-05 · Tiếp nhận và chuỗi băm theo tenant

  @TC-13-016 @P1 @Dương
  Kịch bản: TC-13-016 Ghi một bản ghi hợp lệ, nối băm và gán `seq`
    # Truy vết: FR-13-010, 011 · UC-13-05 · BR-13-004 · NFR-13-008 · API-13-087 · UI-13-18
    Biết S-DU; chuỗi T68 trống.
    Khi gửi 1.000 bản ghi hợp lệ qua Kafka.
    Và `GET /chain-status`; đọc 1.000 bản ghi theo `seq`.
    Thì `seq` 1…1.000 liên tục; `hash = SHA-256(prev_hash ‖ canonical_json)` đúng với mọi bản ghi; offset Kafka chỉ xác nhận sau khi cam kết; độ trễ p95 ≤ 2 giây.

  @TC-13-017 @P1 @Âm
  Kịch bản: TC-13-017 Bản ghi thiếu trường, trùng `id`, sai tenant, DU không được phép
    # Truy vết: FR-13-010, 011 · ERR-13-101, 102, 103, 104 · BR-13-001, 017
    Biết F-DU-SIM phát sai.
    Khi gửi bản ghi thiếu `action`.
    Và gửi lại một `id` đã có.
    Và gửi bản ghi `tenant_id = t01` vào topic của T68.
    Và DU chưa đăng ký ghi cho T68 gửi bản ghi hợp lệ.
    Thì bước 1: ERR-13-101 cách ly. Bước 2: ERR-13-102 bỏ qua, chuỗi không đổi. Bước 3: ERR-13-104. Bước 4: ERR-13-103. Mỗi lần có cảnh báo `WARNING` cho DU nguồn; chuỗi T68 không có `seq` nào thừa.

  @TC-13-018 @P2 @Biên
  Kịch bản: TC-13-018 Đồng hồ DU lệch về tương lai quá 2 giây
    # Truy vết: FR-13-010 · ERR-13-126 · BR-13-001
    Biết F-DU-SIM đặt `occurred_at` lệch +3 giây.
    Khi gửi bản ghi lệch +1 giây, rồi +3 giây.
    Thì +1 giây: ghi bình thường. +3 giây: ghi được kèm cờ, ERR-13-126 cảnh báo `WARNING` cho DU; `recorded_at` do PH-13 gán, quyết định phân vùng.

  @TC-13-019 @P1 @Biên
  Kịch bản: TC-13-019 Ghi đồng thời nhiều DU vào cùng chuỗi không hở `seq`
    # Truy vết: FR-13-011 · BR-13-017 · NFR-13-008 · ERR-13-106
    Biết ba DU giả, mỗi DU 1.000 bản ghi cùng lúc; sau đó chặn ghi bảng 30 giây.
    Khi phát đồng thời 3.000 bản ghi.
    Và chặn quyền ghi bảng kiểm toán 30 giây khi đang phát.
    Thì bước 1: 3.000 `seq` liên tục, không trùng, chuỗi băm đúng. Bước 2: ERR-13-106; offset Kafka không tiến; khi hết chặn không mất, không trùng bản ghi.
