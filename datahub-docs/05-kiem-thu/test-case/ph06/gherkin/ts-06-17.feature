# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-17
Tính năng: TS-06-17 · Sửa tay, ngừng và khôi phục bản ghi vàng

  @TC-06-076 @P2 @Dương
  Kịch bản: TC-06-076 Sửa tay thuộc tính có hạn và yêu cầu sửa tại nguồn
    # Truy vết: FR-06-036 · BR-06-014 · API-06-057 · EVT-06-02, 15 · PERM-06-update
    # Mục đích: Chứng minh sửa tay là tạm thời, có `validUntil` và sinh yêu cầu sửa tại nguồn, theo BR-06-014.
    Biết bản ghi vàng Bình thuộc tính `phone` do `HT-YTE`; DS1, DO1.
    Khi `PATCH .../attributes` đặt `phone`, lý do 30 ký tự, `validUntil` +30 ngày, `If-Match`.
    Và tiến quá hạn; đọc `phone`.
    Thì bước 1 `200`, chiến lược `MANUAL_OVERRIDE`, lineage nguồn `MANUAL`, `GoldenChangeType = MANUAL_EDIT`, ảnh chụp; EVT-06-15 gửi DO1, EVT-06-02. Bước 2 override bỏ, giá trị `HT-YTE` quay lại, DS1 nhận thông báo. Nếu nguồn đã gửi giá trị khớp trước hạn, override tự bỏ. KT: có (manual-edit).
    # Hậu điều kiện: Một yêu cầu sửa tại nguồn.

  @TC-06-077 @P1 @Âm
  Kịch bản: TC-06-077 Sửa tay trái thẩm quyền, thiếu lý do, ETag cũ, đang khóa
    # Truy vết: FR-06-036 · BR-06-008, 025 · API-06-057 · ERR-06-004, 007, 031, 035
    # Mục đích: Chứng minh bốn nhánh chặn sửa tay, theo FR-06-036.
    Biết bản ghi vàng Bình; bản ghi vàng LOCKED G-L.
    Khi `PATCH` `dateOfBirth` (thẩm quyền quốc gia).
    Và `PATCH` `phone` lý do 10 ký tự.
    Và `PATCH` với `ETag` cũ.
    Và `PATCH` G-L.
    Thì bước 1 `422` ERR-06-035. Bước 2 `422` ERR-06-007. Bước 3 `409` ERR-06-004. Bước 4 `409` ERR-06-031.
    # Hậu điều kiện: Không đổi.

  @TC-06-078 @P1 @Dương
  Kịch bản: TC-06-078 Ngừng và khôi phục bản ghi vàng
    # Truy vết: FR-06-040 · BR-06-007 · API-06-062, 113 · EVT-06-05, 06 · PERM-06-merge
    # Mục đích: Chứng minh ngừng chỉ chuyển `RETIRED`, không xóa, và khôi phục được, theo BR-06-007.
    Biết bản ghi vàng TEST_DATA không còn liên kết hiệu lực; DS1.
    Khi `POST .../{id}:retire` `RetireReason = TEST_DATA`, lý do 25 ký tự.
    Và `GET` bản ghi, rồi `GET .../history`.
    Và `:restore`.
    Thì bước 1 `RETIRED`, EVT-06-05. Bước 2 `410` ở tra cứu thường; lịch sử còn nguyên. Bước 3 `ACTIVE`, EVT-06-06. Không có đường `DELETE` (`405`). KT: có (retire, restore).
    # Hậu điều kiện: Bản ghi ACTIVE.

  @TC-06-079 @P1 @Âm
  Kịch bản: TC-06-079 Ngừng khi còn liên kết hiệu lực, trạng thái sai
    # Truy vết: FR-06-040 · API-06-062 · ERR-06-006, 007, 036
    # Mục đích: Chứng minh chỉ ngừng bản ghi hết liên kết và hợp lệ về trạng thái, theo FR-06-040.
    Biết bản ghi vàng Bình (3 liên kết); bản ghi `MERGED`.
    Khi `:retire` Bình.
    Và `:retire` bản ghi `MERGED`.
    Và `:restore` bản ghi `ACTIVE`.
    Và `:retire` thiếu lý do.
    Thì bước 1 `422` ERR-06-036. Bước 2, 3 `409` ERR-06-006. Bước 4 `422` ERR-06-007.
    # Hậu điều kiện: Không đổi.
