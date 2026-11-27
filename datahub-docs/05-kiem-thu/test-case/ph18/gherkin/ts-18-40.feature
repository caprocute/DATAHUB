# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-40
Tính năng: TS-18-40 · Theo dõi sức khỏe và chạy ở chế độ suy giảm

  @TC-18-133 @P1 @Dương
  Kịch bản: TC-18-133 Sức khỏe mô-đun, độ trễ tiêu thụ và EVT-18-29 khi mô-đun đổi trạng thái
    # Truy vết: FR-18-072 · API-18-180 · EVT-18-29 · UI-18-24
    # Mục đích: Chứng minh FR-18-072: `GET /health` trả trạng thái các mô-đun `param`, `dlq`, `notify`, `task`, `incident`, `backup`, `migration`, độ trễ tiêu thụ; đổi trạng thái phát EVT-18-29.
    Biết T90; U-PO1; dừng consumer DLQ 2 phút để tạo độ trễ.
    Khi `GET /health`.
    Và dừng consumer DLQ, chờ 2 phút, `GET /health`.
    Và mở UI-18-24.
    Thì bước 1 mọi mô-đun `UP`. Bước 2 `dlq` `DEGRADED`, `consumerLagSeconds` > 0, EVT-18-29 `from = UP`, `to = DEGRADED`. Bước 3 thẻ sức khỏe hiện trạng thái và độ trễ.

  @TC-18-134 @P1 @Âm @Biên
  Kịch bản: TC-18-134 Chế độ chỉ đọc chặn mọi API ghi, vẫn đọc được và có dải cảnh báo
    # Truy vết: FR-18-072, 007, 003 · API-18-006, 049, 091, 180, 187 · BR-18-007 · ERR-18-071 · EVT-18-29 · LGC-NFR-006 · UI-18-08, 24
    # Mục đích: Chứng minh ERR-18-071 áp dụng cho mọi API ghi (FR-18-072) và việc bật, tắt chế độ đi qua API-18-187 (ca TC-18-171).
    Biết T90; U-PA1 bật chế độ chỉ đọc qua API-18-187.
    Khi TA1 `PUT /params/04.retry.max-attempts`.
    Và TO `:triage` một mục DLQ.
    Và TA1 `GET /params`, TO `GET /dlq/messages`.
    Và mở `/van-hanh`.
    Thì bước 1, 2 `503` ERR-18-071. Bước 3 `200`. Bước 4 dải cảnh báo chỉ đọc trên mọi màn `/van-hanh`; EVT-18-29 `readOnly = true`. Gửi thông báo của phân hệ khác qua outbox vẫn nhận (không chặn đường chính).

  @TC-18-135 @P1 @Chịu_lỗi
  Kịch bản: TC-18-135 Tắt dh-platform 30 phút: phân hệ đọc tham số từ đệm, bản tin lỗi dồn ở Kafka và được nhận đủ
    # Truy vết: FR-18-072, 002, 013 · BR-18-007, 011 · NFR-18-016, 018 · LGC-NFR-001
    # Mục đích: Chứng minh AC-18-02 và BR-18-007, 011: PH-18 vắng không chặn đường chính; khi trở lại tiêu thụ đủ, không mất, không trùng.
    Biết STAGING (T94); tải data plane giả lập 200 giao dịch mỗi giây qua PH-04; 5.000 bản tin lỗi được đẩy trong lúc PH-18 tắt.
    Khi tắt `dh-platform` 30 phút trong khi chạy tải.
    Và bật lại, chờ tiêu thụ hết.
    Thì trong lúc tắt: 0 lỗi data plane do PH-18, p95 độ trễ giao dịch tăng không quá 5 %, PH-04 đọc tham số từ đệm. Sau khi bật: 5.000 mục, 0 mất, 0 trùng; độ trễ tiêu thụ về 0.

  @TC-18-171 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-18-171 Bật, tắt chế độ chỉ đọc qua API riêng và xem sự kiện inbox lỗi
    # Truy vết: FR-18-072 · API-18-187, 186, 006, 180 · BR-18-007 · ERR-18-071, 003, 007 · ERR-00-403 · EVT-18-29 · UI-18-24
    # Mục đích: Chứng minh FR-18-072 qua API-18-187 và API-18-186: chỉ PA bật, tắt được; API-18-187 không bị chặn khi đang chỉ đọc; khóa `18.degraded.read-only` không đổi được qua API-18-006; danh sách inbox `FAILED` chỉ có siêu dữ liệu.
    Biết T90; U-PA1 có `PERM-18-admin`; U-T90-TA1 có `PERM-18-config`; inbox mô-đun `notify` có 3 sự kiện `FAILED`.
    Khi TA1 `POST /degraded-mode` `readOnly = true`.
    Và PA1 `POST /degraded-mode` `readOnly = true` kèm lý do "Bảo trì CSDL theo lịch".
    Và TA1 `PUT /params/18.degraded.read-only` giá trị `false`.
    Và PA1 `POST /degraded-mode` `readOnly = false` kèm lý do khi đang chỉ đọc.
    Và PA1 `GET /inbox-failures?module=notify`.
    Và PA1 `POST /degraded-mode` với lý do 3 ký tự.
    Thì bước 1 `403` ERR-00-403. Bước 2 `200`, `readOnly = true`, EVT-18-29 phát, kiểm toán có. Bước 3 `503` ERR-18-071 (chế độ đang bật); khi chế độ tắt, cùng lời gọi trả `400` ERR-18-003. Bước 4 `200`, chế độ tắt, EVT-18-29 `readOnly = false`, tiêu thụ DLQ đọc tiếp từ offset đã commit. Bước 5 `200` 3 dòng có mô-đun, người tiêu thụ, lỗi cuối, số lần thử; không có nội dung sự kiện. Bước 6 `422` ERR-18-007.
