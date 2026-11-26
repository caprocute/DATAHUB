# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-07
Tính năng: TS-06-07 · Chuẩn hóa ứng viên và xử lý ứng viên lỗi

  @TC-06-027 @P1 @Dương
  Kịch bản: TC-06-027 Chuẩn hóa họ tên và tên pháp nhân
    # Truy vết: FR-06-014 · API-06-029 · UI-06-11 · BR-06-001
    # Mục đích: Chứng minh `nameAscii`, `nameKey`, tách họ, tên đệm, tên, tiền tố loại hình, theo FR-06-014.
    Biết F-CIT, F-ORG.
    Khi `POST /normalization:preview` với `NGUYEN VAN A` và `Nguyễn Văn A` (hai dấu cách).
    Và với `Đặng Thị Hồng`, `Công ty TNHH Thương mại Hoa Sen`, `CTCP Hoa Sen`.
    Thì bước 1 cùng `nameAscii = nguyen van a`, hoa chữ đầu, NFC. Bước 2 `nameAscii = dang thi hong`, `givenName = Hồng`; hai tổ chức cùng phần lõi `hoa sen`, `orgFormToken` `TNHH`, `CTCP`.
    # Hậu điều kiện: Không lưu.

  @TC-06-028 @P1 @Dương @Âm
  Kịch bản: TC-06-028 Chuẩn hóa ngày, điện thoại, số định danh
    # Truy vết: FR-06-014 · BR-06-001, 015 · API-06-029 · UI-06-11
    # Mục đích: Chứng minh ngày nhiều dạng, giá trị giả và số định danh sai không dùng làm khóa, theo FR-06-014.
    Biết CC-01, CC-X, MST-X.
    Khi preview ngày `12/03/1990`, `1990-03-12`, `19900312`, `1990`, `01/01/1900`, `00/00/0000`, ngày tương lai.
    Và preview `CC-01` có dấu chấm, `CC-X`, `MST-X`.
    Và điện thoại `+84 912 345 678`, email `AN@Mail.COM`.
    Thì bước 1 ba dạng đầu ra `1990-03-12` `DAY`; `1990` `YEAR`; ba giá trị giả `MISSING` cảnh báo `DATE_PLACEHOLDER`. Bước 2 CC-01 sạch `VALID`; `CC-X`, `MST-X` `identifierStatus` không hợp lệ, cảnh báo `IDENTIFIER_INVALID`, không dùng làm khóa. Bước 3 `0912345678`, `an@mail.com`.
    # Hậu điều kiện: Không lưu.

  @TC-06-029 @P1 @Dương @Âm
  Kịch bản: TC-06-029 Chuẩn hóa địa chỉ theo ĐVHC của PH-07
    # Truy vết: FR-06-015 · BR-06-033 · ERR-06-020, 021 · UI-06-11
    # Mục đích: Chứng minh mã ĐVHC hiện hành, chuyển mã cũ và cảnh báo mã lạ, theo FR-06-015.
    Biết F-ADDR; PH-07 giả lập mã cũ một-một, một-nhiều, mã lạ.
    Khi nạp địa chỉ mã hiện hành, mã cũ một-một, mã cũ một-nhiều, mã không tồn tại, chuỗi không tách được.
    Và dừng PH-07, nạp một địa chỉ.
    Thì bước 1 lần lượt không cảnh báo; `ADMIN_UNIT_CONVERTED` kèm `legacyAdminUnitCode`; `ADMIN_UNIT_SPLIT` đưa vào xem xét; `ADMIN_UNIT_UNKNOWN` (ERR-06-020 là cảnh báo, ứng viên vẫn đi tiếp); `ADDRESS_UNPARSED`. Bản ghi vàng chỉ giữ mã hiện hành. Bước 2 `NORMALIZATION_PENDING`, ERR-06-021 ở nhật ký; khi PH-07 lại, tự xử lý.
    # Hậu điều kiện: Ứng viên địa chỉ có cảnh báo.

  @TC-06-030 @P1 @Dương @Âm
  Kịch bản: TC-06-030 Chống trùng và bản ghi nguồn đến trễ
    # Truy vết: FR-06-016 · BR-06-028, 029, 009 · API-06-021
    # Mục đích: Chứng minh phiên bản nhỏ hơn không ghi đè giá trị mới hơn cùng nguồn, theo BR-06-029.
    Biết `HT-YTE`/`YT-0002` phiên bản 5 đã LINKED với `phone = 0901000001`.
    Khi gửi phiên bản 3 với `phone = 0902000002`.
    Và gửi phiên bản 6 với `phone = 0903000003`.
    Và gửi lại phiên bản 6.
    Thì bước 1 ứng viên `SUPERSEDED`, bản ghi vàng giữ `0901000001`. Bước 2 `phone` bản ghi vàng đổi `0903000003`, nguồn ở cấp thuộc tính là `HT-YTE`. Bước 3 `DUPLICATE`.
    # Hậu điều kiện: Bản ghi vàng YT-0002 phiên bản 6.

  @TC-06-031 @P1 @Dương
  Kịch bản: TC-06-031 Xóa từ nguồn gỡ liên kết, không xóa bản ghi vàng
    # Truy vết: FR-06-016 · BR-06-007, 018 · EVT-06-02
    # Mục đích: Chứng minh `operation = DELETE` gỡ liên kết chéo, tính lại sống sót và chỉ đề nghị ngừng qua hàng đợi, theo FR-06-016.
    Biết bản ghi vàng có hai liên kết `HT-YTE`, `HT-GIAODUC`; thuộc tính `phone` do `HT-YTE`.
    Khi `HT-YTE` gửi `DELETE` cho `sourceKey`.
    Và `HT-GIAODUC` gửi `DELETE` cho liên kết còn lại.
    Thì bước 1 xref `DETACHED` lý do `SOURCE_DELETED`, `phone` lấy từ nguồn còn lại, EVT-06-02. Bước 2 bản ghi vàng hết liên kết hiệu lực: mục hàng đợi `ORPHANED` đề nghị ngừng, bản ghi vẫn `ACTIVE`, không tự `RETIRED`.
    # Hậu điều kiện: Một mục ORPHANED.

  @TC-06-032 @P2 @Dương @Âm
  Kịch bản: TC-06-032 Xem, xử lý lại và loại bỏ ứng viên lỗi
    # Truy vết: FR-06-017 · BR-06-008, 010 · API-06-026, 027, 028 · ERR-06-007 · PERM-06-update
    # Mục đích: Chứng minh lọc, xem ứng viên, xử lý lại, loại bỏ có lý do, theo FR-06-017.
    Biết T90 có 5 ứng viên `REJECTED`, 3 cảnh báo; DS1.
    Khi `GET .../candidates?status=REJECTED&page=0&size=3`.
    Và `:reprocess` ứng viên đã sửa mô hình; `:discard` không lý do; `:discard` với lý do 25 ký tự.
    Và `GET` chi tiết ứng viên.
    Thì bước 1 3 phần tử, trường `SENSITIVE` che. Bước 2 reprocess `200` `NORMALIZED`; discard thiếu lý do `422` ERR-06-007; có lý do `DISCARDED`. Bước 3 NK: có, KT: có (discard).
    # Hậu điều kiện: Ứng viên `DISCARDED` giữ dòng rút gọn.
