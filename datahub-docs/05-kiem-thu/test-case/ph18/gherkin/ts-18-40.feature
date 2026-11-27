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
    # Truy vết: FR-18-072, 007, 003 · API-18-006, 049, 091, 180 · BR-18-007 · ERR-18-071 · EVT-18-29 · LGC-NFR-006 · UI-18-08, 24
    # Mục đích: Chứng minh ERR-18-071 áp dụng cho mọi API ghi (theo FR-18-072, ĐN-UC-02) và việc bật, tắt chế độ đi qua đường quản trị riêng.
    Biết T90; U-PA1 bật `18.degraded.read-only = true` (giả định qua đường quản trị nêu ở ĐN-UC-11).
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
