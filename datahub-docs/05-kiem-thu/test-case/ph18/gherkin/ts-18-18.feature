# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-18
Tính năng: TS-18-18 · Bỏ qua và mở lại mục DLQ

  @TC-18-062 @P1 @Dương
  Kịch bản: TC-18-062 Bỏ qua một mục, hàng loạt 300 mục, mở lại mục đã bỏ qua
    # Truy vết: FR-18-031, 032 · API-18-077, 078, 079 · BR-18-023, 024 · EVT-18-07 · UI-18-01, 03
    # Mục đích: Chứng minh đường bỏ qua và mở lại có sự kiện, kiểm toán, giữ lý do.
    Biết T90; `DLQ-A-10` `TRIAGED`; 300 mục `TEST_MESSAGE`; U-T90-TO.
    Khi `POST /dlq/messages/DLQ-A-10:discard` mã `HANDLED_AT_SOURCE`, mô tả "Đã nhập tay ở hệ đích".
    Và `POST /dlq/messages:bulk-discard` 300 mục mã `TEST_MESSAGE`.
    Và `POST /dlq/messages/DLQ-A-10:reopen` kèm lý do.
    Thì bước 1 `200` `DISCARDED`, EVT-18-07. Bước 2 `200`, 300 mục `DISCARDED`, mỗi mục một bản ghi kiểm toán. Bước 3 `200` `TRIAGED`, lịch sử giữ cả lần bỏ qua.

  @TC-18-063 @P1 @Âm
  Kịch bản: TC-18-063 Bỏ qua thiếu mô tả, bỏ qua mục đã RESOLVED, mở lại mục không phải DISCARDED
    # Truy vết: FR-18-031, 032 · API-18-077, 079 · BR-18-023, 024 · ERR-18-006, 007
    # Mục đích: Chứng minh điều kiện của bỏ qua và mở lại theo máy trạng thái DLQ.
    Biết T90; `DLQ-A-11` `TRIAGED`, `DLQ-A-03` `RESOLVED`.
    Khi bỏ qua `DLQ-A-11` mô tả "bỏ" (3 ký tự).
    Và bỏ qua `DLQ-A-03`.
    Và mở lại `DLQ-A-11` đang `TRIAGED`.
    Thì bước 1 `422` ERR-18-007. Bước 2 `409` ERR-18-006. Bước 3 `409` ERR-18-006.

  @TC-18-064 @P2 @Âm @Biên
  Kịch bản: TC-18-064 Mở lại mục đã hết hạn lưu giữ bị từ chối
    # Truy vết: FR-18-032, 033 · API-18-079 · BR-18-024, 025 · ERR-18-034
    # Mục đích: Chứng minh BR-18-024: sau khi mục `EXPIRED` không mở lại được.
    Biết T95; `DLQ-A-12` `DISCARDED` 89 ngày trước.
    Khi tua đồng hồ 2 ngày, chạy tác vụ dọn.
    Và mở lại `DLQ-A-12`.
    Thì bước 1 mục `EXPIRED`. Bước 2 `409` ERR-18-034.
