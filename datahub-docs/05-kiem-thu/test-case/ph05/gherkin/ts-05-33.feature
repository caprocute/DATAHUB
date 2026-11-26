# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-33
Tính năng: TS-05-33 · Phân quyền và tách nhiệm

  @TC-05-127 @P1 @Bảo @mật
  Kịch bản: TC-05-127 Ma trận vai trò và API
    # Truy vết: ERR-05-012 · BR-05-009 · NFR-05-016
    Biết mọi người dùng mục 2.2.
    Thì cặp không có quyền trả 403-PQ; cặp có quyền không trả `403`. 0 sai lệch với D02-08 §PH-05.

  @TC-05-128 @P1 @Bảo @mật
  Kịch bản: TC-05-128 Bốn mắt không có đường vòng
    # Truy vết: BR-05-009 · ERR-05-011 · API-05-015, 038, 056, 083
    Biết U-T68-IA2; U-T68-IE2 sửa nội dung gần nhất của yêu cầu IA1 sắp duyệt.
    Khi IA2 gửi một yêu cầu, IE2 (cùng nhóm) sửa nội dung, IA2 duyệt.
    Và IE2 sửa nội dung yêu cầu do IE1 gửi; IE2 được gán thêm vai trò IA rồi duyệt.
    Và gọi API duyệt bằng tài khoản dịch vụ S-INT.
    Thì bước 1, 2 `403` ERR-05-011 (người đề nghị, người sửa gần nhất). Bước 3 403-PQ (tài khoản dịch vụ không có quyền duyệt).

  @TC-05-129 @P2 @Bảo @mật
  Kịch bản: TC-05-129 Thao tác nhạy cảm cần xác thực lại
    # Truy vết: FR-05-007, 026, 058 · ERR-05-012
    Biết U-T68-IA1 có `auth_time` cũ hơn 15 phút.
    Thì mỗi lệnh trả `401` với yêu cầu xác thực lại (`acr` TOTP); sau xác thực lại thì đạt.
