# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-28
Tính năng: TS-10-28 · Di trú từ Pulsar: kiểm kê và ánh xạ

  @TC-10-116 @P1 @Dương
  Kịch bản: TC-10-116 Nhập kiểm kê Hub cũ, đề xuất ánh xạ đủ loại
    # Truy vết: FR-10-072 · API-10-075, 076, 110 · UI-10-20 · UC-10-26 · LGC-HUB-008, 009, 010, 011, 012, 013, 014
    Biết U-T68-TA ở T96; F-PUL-INV.
    Khi tải F-PUL-INV (`sourceKind = PULSAR_HUB`).
    Và `GET /migrations/mappings`.
    Thì 3 dự án, 8 topic (tên đề xuất `t96.{miền}.{thực-thể}.{sự-kiện}.v1` chữ thường), 5 bên phát, 7 bên nhận (2 có `partyType = FLOW`), 6 publication, 9 subscription; mỗi ánh xạ `PROPOSED` có `confidence`; `routing_mode` `CustomPartition` ánh xạ `KEY_HASH` kèm cờ "cần khai báo trường khóa"; subscription `Shared` 2 consumer thành `workerCount = 2`, `DEAD_LETTER`; `type_of_comm` ánh xạ theo `legacyCode`.

  @TC-10-117 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-117 Không di trú mật khẩu cũ; sửa ánh xạ; tệp sai; đích không hợp lệ
    # Truy vết: FR-10-072 · API-10-075, 111, 112 · ERR-10-040, 041 · BR-10-032, 034
    Biết tác vụ từ TC-10-116; F-PUL-BAD.
    Khi xem ánh xạ subscription có mật khẩu Basic trong URI.
    Và `PATCH /migrations/mappings/{id}` đặt `targetCode` là topic không theo quy ước; đặt `SKIPPED` cho một ánh xạ.
    Và `:apply` tác vụ.
    Và tải F-PUL-BAD.
    Thì bước 1 URI đích đã bỏ thông tin xác thực, có vấn đề "cấp lại thông tin xác thực"; mật khẩu không có trong CSDL, log, báo cáo (mồi sạch). Bước 2 `422` ERR-10-041; `SKIPPED` `200`. Bước 3 đối tượng đích tạo ở `DRAFT`, `PENDING_APPROVAL`; không `ACTIVE`. Bước 4 `422` ERR-10-040.
