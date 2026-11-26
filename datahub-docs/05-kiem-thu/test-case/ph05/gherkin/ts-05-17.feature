# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-17
Tính năng: TS-05-17 · Hàng đợi, thư điện tử, LDAP

  @TC-05-067 @P1 @Dương
  Kịch bản: TC-05-067 Tiêu thụ AMQP, xác nhận sau khi luồng xử lý xong
    # Truy vết: FR-05-035 · BR-05-024 · UC-05-16 · LGC-TOOL-010
    Biết bộ điều hợp `tc-tnmt` thao tác `INBOUND` hàng đợi `ho-so-moi`; luồng tiêu thụ lỗi ở bản tin thứ 3.
    Thì bản tin 1, 2, 4, 5 được xác nhận; bản tin 3 không bị mất (nằm DLQ của luồng hoặc quay lại hàng đợi theo cấu hình), tiêu đề `traceparent`, `correlationId` được chuyển.

  @TC-05-068 @P2 @Âm
  Kịch bản: TC-05-068 Mất môi giới bản tin, tự kết nối lại
    # Truy vết: FR-05-035 · ERR-05-114
    Biết như TC-05-067.
    Thì lần 2 phút: tự kết nối lại theo giãn cách, không mất bản tin. Lần 6 phút: ERR-05-114 ghi nhận, sức khỏe `UNHEALTHY`; có lại thì tiêu thụ tiếp.

  @TC-05-069 @P2 @Âm @Bảo @mật
  Kịch bản: TC-05-069 Thư chỉ tới miền cho phép; đính kèm có mã độc
    # Truy vết: FR-05-037 · BR-05-028 · ERR-05-115
    Biết bộ điều hợp `tc-mail` miền cho phép `t68.gov.vn`; SIM-MAIL.
    Khi gửi tới `a@t68.gov.vn`, `b@gmail.com`.
    Và hộp thư nhận có thư kèm F-EICAR.
    Thì bước 1 chỉ thư thứ nhất tới SIM-MAIL; thư thứ hai lỗi lớp dữ liệu, không gửi. Bước 2 ERR-05-115, thư chuyển thư mục cách ly, không đưa vào luồng.

  @TC-05-070 @P3 @Bảo @mật
  Kịch bản: TC-05-070 LDAP thoát ký tự đặc biệt trong bộ lọc
    # Truy vết: FR-05-039
    Biết thao tác `search` với `filterTemplate = (uid=${param.uid})`; SIM-LDAP.
    Thì SIM-LDAP nhận bộ lọc `(uid=\2a\29\28objectClass=\2a)`; 0 kết quả; `sizeLimit` ≤ 1.000 được áp.
