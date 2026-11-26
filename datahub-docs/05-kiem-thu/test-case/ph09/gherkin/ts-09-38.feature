# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-38
Tính năng: TS-09-38 · Đóng an toàn, chịu lỗi và phục hồi

  @TC-09-131 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-131 Mất nhật ký PH-13: mọi thao tác đặc quyền bị từ chối
    # Truy vết: NFR-09-013 · BR-09-057 · ERR-09-010 · FR-09-007, 029, 033, 034, 043, 060 · API-09-006, 102, 124, 118, 161, 213
    # Mục đích: Chứng minh không thao tác đặc quyền nào chạy khi không ghi được kiểm toán.
    Biết T94; sáu thao tác đặc quyền sẵn sàng (gỡ nhãn, xem đầy đủ, khôi phục, hủy khóa, xóa mật mã, đóng vi phạm); PH-13 `503`.
    Khi ngừng PH-13; gọi sáu thao tác.
    Và bật PH-13; gọi lại.
    Thì bước 1 sáu `503` ERR-09-010, không đổi trạng thái. Bước 2 sáu thao tác thực hiện được, mỗi thao tác một bản ghi KT. Thao tác thường vẫn chạy với kiểm toán hàng đợi.

  @TC-09-132 @P1 @Chịu @lỗi
  Kịch bản: TC-09-132 Kafka ngừng: sự kiện nằm ở outbox, phát lại đủ, không trùng tác động
    # Truy vết: FR-09-017, 018 · EVT-09-08, 11 · NFR-09-005
    # Mục đích: Chứng minh không mất sự kiện thu hồi.
    Biết T94; Kafka dừng 10 phút; thu hồi 3 chấp thuận trong lúc dừng.
    Khi dừng Kafka; DO1 thu hồi 3 chấp thuận.
    Và bật Kafka.
    Thì ba hàng outbox chờ; sau khi Kafka lên đủ 3 EVT: `purpose-grant.revoked`, mỗi sự kiện đúng một lần theo khóa idempotent; trong lúc dừng, kênh bundle p99 ≤ 60 giây vẫn thu hồi hiệu lực ở OPA.

  @TC-09-133 @P1 @Chịu @lỗi
  Kịch bản: TC-09-133 Mất CSDL chính: RTO ≤ 30 phút, RPO ≤ 5 phút, mất một nút data plane
    # Truy vết: NFR-09-021, 006 · FR-09-018
    # Mục đích: Chứng minh diễn tập DR (ADR-034) và khả năng chịu mất nút.
    Biết T94; `pg-core` có bản sao đồng bộ; data plane 3 bản sao trên 3 nút; tải 1.000 yêu cầu mỗi giây.
    Khi ghi 10 phút; tắt PostgreSQL chính; đo đến khi `ph09_privacy` ghi lại được.
    Và xóa một pod data plane.
    Thì bước 1 mất dữ liệu ≤ 5 phút, khôi phục ≤ 30 phút. Bước 2 thông lượng giảm ≤ 33 %, 0 yêu cầu quyết định trả sai (chỉ chậm hoặc `5xx` tạm thời), PEP dùng đệm.

  @TC-09-134 @P2 @Chịu @lỗi
  Kịch bản: TC-09-134 Job quét hoặc ẩn danh bị dừng giữa chừng: không để lại tập dở dang
    # Truy vết: FR-09-005, 036 · API-09-020, 130 · BR-09-034
    # Mục đích: Chứng minh job lỗi kết thúc `FAILED`, không phát hành tập hoặc kết quả dở.
    Biết T94; job quét và job ARX đang `RUNNING`.
    Khi `kubectl delete pod` Job quét; Job ARX.
    Thì trạng thái `FAILED`, không tập `READY`, tệp tạm ở Garage bị dọn, chạy lại được, không kết quả quét một nửa.
