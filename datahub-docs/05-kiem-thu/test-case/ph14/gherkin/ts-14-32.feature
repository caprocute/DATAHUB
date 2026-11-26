# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-32
Tính năng: TS-14-32 · Không lộ bí mật và dữ liệu cá nhân

  @TC-14-081 @P1 @Bảo @mật
  Kịch bản: TC-14-081 Dò mồi `DH-CANARY` ở mọi nơi có thể rò
    # Truy vết: NFR-14-015 · BR-14-004, 005 · FR-14-025, 026, 050 · API-14-039, 063, 066 · ERR-14-127.
    Biết thông tin xác thực nền tảng, khóa chứng thư, hồ sơ BHXH đều mang mồi; chạy đủ TS-14-09…17, 28.
    Khi quét phản hồi mọi API, nhật ký ứng dụng, vết OpenTelemetry, tệp xuất, sự kiện Kafka, bảng PostgreSQL, ảnh bộ nhớ pod.
    Và gây lỗi nội bộ có ngăn xếp (`ERR-14-127`).
    Thì 0 mồi thông tin xác thực, khóa ở mọi nơi ngoài OpenBao; 0 mồi DLCN ngoài nội dung bản tin mã hóa; thân lỗi không có ngăn xếp.

  @TC-14-082 @P1 @Bảo @mật @Biên
  Kịch bản: TC-14-082 Nội dung bản tin mã hóa theo khóa tenant, thời hạn lưu
    # Truy vết: BR-14-021 · NFR-14-021 · FR-14-050 · SEC-33.
    Biết `14.txn.payload-retention-days` 30 rồi 0.
    Khi gọi dịch vụ, đọc bản ghi lưu nội dung ở CSDL.
    Và đặt 0, gọi lại; tiến đồng hồ 31 ngày.
    Thì nội dung là bản mã, giải bằng khóa tenant mới đọc được; đặt 0 thì không lưu; quá 30 ngày nội dung bị xóa, siêu dữ liệu giữ 5 năm.
