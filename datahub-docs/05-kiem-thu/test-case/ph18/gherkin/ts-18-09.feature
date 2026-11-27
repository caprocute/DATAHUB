# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-09
Tính năng: TS-18-09 · Tiếp nhận bản tin lỗi từ topic, kiểm ngữ cảnh và đối soát với Kafka

  @TC-18-026 @P1 @Dương
  Kịch bản: TC-18-026 Bản tin đủ header thành mục NEW, sự kiện gộp theo phút
    # Truy vết: FR-18-013 · BR-18-011 · EVT-18-05 · UI-18-01, 24
    # Mục đích: Chứng minh FR-18-013: bản tin đủ hợp đồng ngữ cảnh (bảng 4.1b của FRS) thành mục `NEW` có lớp lỗi gợi ý, offset chỉ commit sau khi ghi bền, EVT-18-05 gộp theo phút.
    Biết T90; topic `t90.ops.dlq.v1` 6 phân vùng; `DLQ-SET-A` gồm 20 bản tin của `SRC-PH04` đủ header (`dh-tenant`, `dh-source-ph`, `dh-dlq-reason`, `dh-dlq-error-code`, `dh-dlq-stage`, `dh-dlq-attempts`, `dh-flow`, `dh-version`, `traceparent`, `dh-message-id`).
    Khi đẩy 20 bản tin bằng `kcat`.
    Và giết bản sao `dh-platform` giữa lúc tiêu thụ bản tin thứ 10, chờ bản sao mới.
    Và mở UI-18-01 lọc `nguon=SRC-PH04`.
    Và đọc `t90.ops.dlq.received.v1`.
    Thì có đúng 20 mục `NEW`, không mất, không trùng (bản tin thứ 10 được xử lý lại nhờ offset chưa commit và khử trùng). Mục có `errorClass` gợi ý theo `dh-dlq-reason`, có `traceId`. EVT-18-05 có `count = 20`, `poisonCount = 0` gộp theo phút.

  @TC-18-027 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-027 Thiếu header bắt buộc thành POISON, tenant lệch topic, không giải mã được
    # Truy vết: FR-18-013, 015 · BR-18-013 · ERR-18-101, 102, 103 · EVT-18-06, 08 · UI-18-01, 03
    # Mục đích: Chứng minh BR-18-013 và các lỗi worker: mục thiếu ngữ cảnh là `POISON` kèm EVT-18-06, bản tin có tenant khác tiền tố topic không vào chỉ mục của tenant đó, thân không giải mã được lưu dạng nhị phân.
    Biết T90; `DLQ-POISON` gồm 3 bản tin thiếu lần lượt `dh-dlq-stage`, `dh-flow` (nguồn `KAFKA_TOPIC`), `dh-tenant`; 1 bản tin `dh-tenant = T91` ghi vào `t90.ops.dlq.v1`; 1 bản tin thân không phải UTF-8 cũng không phải Avro.
    Khi đẩy 5 bản tin.
    Và mở UI-18-01 lọc `trang-thai=POISON`, mở một mục.
    Và đọc `t90.ops.dlq.poison-detected.v1`.
    Và đẩy thêm 10 bản tin thiếu header trong một giờ (vượt `18.dlq.threshold.poison-per-hour`).
    Thì ba mục `POISON` có `missingFields` đúng, ghi ERR-18-102. Bản tin tenant lệch bị ghi ERR-18-103, không có mục ở T90 hay T91, có chỉ số `dh_ops_errors_total{code="ERR-18-103"}`. Bản tin không giải mã được thành mục ghi ERR-18-101, payload lưu nhị phân. EVT-18-06 phát mỗi mục `POISON`; bước 4 phát EVT-18-08 `type = POISON_RATE`. UI-18-03 hiện nút "Sửa" và "Bỏ qua", không có "Phát lại".

  @TC-18-028 @P1 @Dương @Âm
  Kịch bản: TC-18-028 Payload 300 KB lưu ở Garage có SHA-256, tổng kiểm tra lệch bị phát hiện
    # Truy vết: FR-18-016 · BR-18-014 · ERR-18-104 · UI-18-03
    # Mục đích: Chứng minh BR-18-014: payload lớn hơn `18.dlq.payload.inline-max-kb` lưu ở bucket `dh-t90-ops`, chỉ mục giữ đường dẫn, kích thước, SHA-256; tổng kiểm tra lệch được báo khi đọc.
    Biết T90; `DLQ-BIG` 300 KB và 100 KB; Garage dev; quyền ghi đối tượng cho kiểm thử viên để làm hỏng đối tượng ở bước 3.
    Khi đẩy hai bản tin.
    Và kiểm bảng `dlq_payload_ref` và bucket.
    Và sửa một byte của đối tượng trong Garage, U-T90-SO xem payload có lý do.
    Thì bản tin 100 KB lưu nội tuyến; bản tin 300 KB có đối tượng ở `dh-t90-ops/dlq/...`, chỉ mục có `sizeBytes`, `sha256`. Bước 3 trả ERR-18-104 cho người xem, không trả nội dung, ghi chỉ số lỗi.

  @TC-18-029 @P1 @Biên @Lũy_đẳng
  Kịch bản: TC-18-029 Bản tin cùng dlqKey chỉ tăng số lần gặp khi mục chưa đóng
    # Truy vết: FR-18-016, 013 · BR-18-015 · ERR-18-105
    # Mục đích: Chứng minh BR-18-015: `dlqKey = sourceCode:flow:messageId:stage`; mục chưa đóng cùng khóa tăng `occurrences`, mục đã đóng ngoài `18.dlq.dedup-window-days` tạo mục mới.
    Biết T95 (đồng hồ giả); mục `DLQ-A-01` `NEW` khóa `SRC-PH04:thue-dong-bo:m-001:transform`.
    Khi đẩy lại bản tin `m-001` cùng bước ba lần.
    Và bỏ qua mục, tua 8 ngày, đẩy lại lần nữa.
    Và đẩy bản tin thiếu `dh-message-id` hai lần cùng thân.
    Thì bước 1 vẫn một mục, `occurrences = 4`, ghi ERR-18-105 ở nhật ký worker. Bước 2 tạo mục mới, mục cũ giữ `DISCARDED`. Bước 3 hai lần cùng băm SHA-256 thân nên chỉ một mục.

  @TC-18-030 @P2 @Dương @Âm
  Kịch bản: TC-18-030 Đối soát chỉ mục với Kafka bù mục thiếu và không chạy chồng
    # Truy vết: FR-18-018 · API-18-037, 038 · BR-18-011, 015 · ERR-18-006 · EVT-18-08 · NFR-18-021 · UI-18-06
    # Mục đích: Chứng minh FR-18-018: đối soát theo phân vùng phát hiện mục thiếu, bù vào chỉ mục, phát EVT-18-08 `RECONCILE_MISSING`; lần chạy thứ hai khi lần đầu chưa xong bị từ chối.
    Biết T90; xóa cưỡng bức 3 dòng `dlq_message` bằng vai chủ ở CSDL TEST để giả lập thiếu; U-PA1.
    Khi U-PA1 `POST /dlq/reconciliation:run`.
    Và gọi lại ngay khi lần 1 đang chạy.
    Và `GET /dlq/reconciliation`.
    Thì bước 1 `202`. Bước 2 `409` ERR-18-006. Bước 3 kết quả theo phân vùng có `missing = 3`, `backfilled = 3`; sau đối soát số mục thiếu bằng 0; EVT-18-08 `type = RECONCILE_MISSING` phát một lần.
