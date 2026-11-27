# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-21
Tính năng: TS-04-21 · Data plane bất đồng bộ, xử lý lỗi, chống trùng

  @TC-04-131 @P1 @Dương
  Kịch bản: TC-04-131 Nhận sự kiện Kafka, chuyển CDM, phát sự kiện
    # Truy vết: FR-04-062, 069 · BR-04-009 · UC-04-18 · LGC-BUS-039.
    Biết F-DD PROD; nhóm tiêu thụ `dh-flow-t68-dong-bo-dat-dai`.
    Khi gửi 100 bản tin vào `t68.datdai.thua-dat.changed.v1`.
    Và đọc `t68.cdm.thua-dat.v1`.
    Thì 100 bản tin CDM, khóa phân vùng theo cấu hình luồng, cùng `traceparent` với bản tin vào. Offset chỉ ghi nhận sau khi gửi thành công (at-least-once).

  @TC-04-132 @P1 @Âm
  Kịch bản: TC-04-132 Bản tin lỗi vào DLQ
    # Truy vết: FR-04-062, 070 · BR-04-008 · ERR-04-101.
    Biết một bản tin không phải JSON; một bản tin làm đích lỗi sau 3 lần thử.
    Khi gửi hai bản tin.
    Và đọc `t68.ops.dlq.v1`.
    Thì hai bản tin trong DLQ có tiêu đề `dh-dlq-error-code` (ERR-04-101 và ERR-04-104), `dh-flow`, `dh-version`, `dh-dlq-attempts`, `traceparent`. Các bản tin sau đó vẫn được xử lý (không tắc phân vùng). Lỗi giải tuần tự vào DLQ ngay, không thử lại.

  @TC-04-133 @P1 @Dương @Âm
  Kịch bản: TC-04-133 Chống trùng bản tin
    # Truy vết: FR-04-071 · ERR-04-106.
    Biết F-HT khai báo khóa chống trùng `Idempotency-Key`; `04.runtime.idempotency-ttl-hours = 24`.
    Khi gọi F-HT hai lần cùng `Idempotency-Key`.
    Và gọi lần ba cùng khóa sau khi kết quả cũ bị xóa khỏi kho (giả lập vượt 64 KiB, không lưu kết quả).
    Và gửi trùng một bản tin Kafka cho F-DD (cùng `ce_id`).
    Thì bước 1: lần hai trả đúng kết quả lần một, hệ đích nhận một lệnh gọi. Bước 2 trả `409` ERR-04-106. Bước 3: chỉ một bản tin CDM được phát.

  @TC-04-134 @P1 @Bảo @mật
  Kịch bản: TC-04-134 Topic không có quyền ở runtime
    # Truy vết: FR-04-069 · BR-04-009.
    Biết một luồng đã chạy (giả lập vượt qua kiểm tra tĩnh) cố gửi tới TOPIC-NOACL.
    Khi kích hoạt lần gửi.
    Thì kafka từ chối do ACL theo principal của runtime tenant; bản tin vào DLQ với ERR-04-109; cảnh báo PH-13. Chứng minh ràng buộc có hai lớp: kiểm tra tĩnh và ACL Kafka.

  @TC-04-199 @P1 @Âm
  Kịch bản: TC-04-199 Lỗi nghiệp vụ, dữ liệu ở luồng bất đồng bộ vào DLQ không thử lại
    # Truy vết: FR-04-062, 065, 070 · UC-04-18 · BR-04-008 · ERR-04-108, 109.
    Biết F-DD PROD; một bản tin có mã loại đất không có trong bảng ánh xạ PH-07 (cấu hình `FAIL`); một bản tin làm bộ chuẩn hóa CDM ném lỗi không phân loại.
    Khi gửi hai bản tin vào `t68.datdai.thua-dat.changed.v1`, tiếp theo 10 bản tin hợp lệ.
    Và đọc `t68.ops.dlq.v1` và chỉ số `dh_flow_failures_total`.
    Thì hai bản tin vào DLQ với `dh-dlq-attempts = 1` (không thử lại): tiêu đề `dh-dlq-error-code` lần lượt ERR-04-108 và ERR-04-109, kèm `dh-flow`, `dh-version`, `traceparent`; trường nhạy cảm đã mã hóa. 10 bản tin hợp lệ vẫn ra `t68.cdm.thua-dat.v1` (không tắc phân vùng). ERR-04-109 sinh cảnh báo PH-13; người vận hành thấy cả hai ở màn DLQ của PH-18.
