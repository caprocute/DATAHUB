# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-33
Tính năng: TS-19-33 · Phân quyền và tách nhiệm

  @TC-19-801 @P1 @Bảo @mật
  Kịch bản: TC-19-801 Quét ma trận quyền theo vai trò
    # Truy vết: Khung §13.2, §13.3 · ERR-19-046
    Biết chín người dùng thử, mỗi người đúng một vai trò; bộ sinh ca đọc bảng vai trò × quyền × API từ khung §13.
    Khi mỗi người gọi mọi API quản trị với dữ liệu hợp lệ.
    Thì Ô "có" trả mã thành công hoặc lỗi nghiệp vụ (không phải `403`); ô "không" trả 403-PQ. 48 quyền đều có ít nhất một ô "có" và một ô "không" được kiểm. Báo cáo dạng bảng đính kèm.

  @TC-19-802 @P1 @Bảo @mật
  Kịch bản: TC-19-802 Quy tắc động 1: người quyết định khác người lập, mọi loại đề nghị
    # Truy vết: Khung §13.4 #1 · BR-19-011 · API-19-050 · ERR-19-033
    Biết U-AA1 có đủ quyền lập và quyết định mọi loại đề nghị (vai trò thử).
    Khi với từng loại đề nghị (kích hoạt NCC, ngừng hẳn NCC, duyệt đối tác, chấm dứt đối tác, hoàn tiền, xử lý chênh lệch, mở lại phiên, đổi chế độ định tuyến, đổi bảng ánh xạ), U-AA1 lập rồi tự duyệt.
    Thì mọi trường hợp `403` ERR-19-033; sự kiện an ninh có `rule = SOD-1`.

  @TC-19-803 @P1 @Bảo @mật
  Kịch bản: TC-19-803 Quy tắc động 2–5
    # Truy vết: Khung §13.4 #2–5 · BR-19-023, 024, 028
    Biết như các ca TC-19-427, TC-19-433, TC-19-480, TC-19-504.
    Khi chạy lại phần âm của bốn ca trên với người dùng có nhiều vai trò cùng lúc.
    Thì mọi vi phạm trả `403` ERR-19-033 dù người dùng có đủ quyền; quy tắc 4: yêu cầu hoàn sinh từ chênh lệch không duyệt được bởi người đề xuất chênh lệch.

  @TC-19-804 @P1 @Bảo @mật
  Kịch bản: TC-19-804 Quy tắc động 6: xem dữ liệu cá nhân phải có lý do
    # Truy vết: Khung §13.4 #6 · BR-19-031
    Biết như TC-19-553.
    Khi gọi API-19-052, 083 với yêu cầu bản rõ không có lý do.
    Thì `400` ERR-19-001; không trả bản rõ; mỗi lần xem có lý do đều có bản ghi kiểm toán.

  @TC-19-805 @P2 @Bảo @mật
  Kịch bản: TC-19-805 Quy tắc tĩnh 7–10 khi gán vai trò
    # Truy vết: Khung §13.4 #7–10
    Biết quản trị tenant ở PH-12.
    Khi gán `ROLE-AUDITOR` cùng `ROLE-PAYMENT_OPERATOR` cho một người.
    Và gán `ROLE-PAYMENT_APPROVER` cùng `ROLE-PAYMENT_ADMIN`.
    Và gán `ROLE-PARTNER_SYSTEM` cho người; gán `ROLE-PAYMENT_ADMIN` cho client máy.
    Và U-PLA1 đọc giao dịch của T68 không có phiên break-glass; rồi có phiên được duyệt 4 giờ; tiến 4 giờ 1 phút.
    Thì bước 1, 3: PH-12 từ chối. Bước 2: cho phép kèm cảnh báo và bản ghi ngoại lệ. Bước 4: lần đầu `403`; có phiên thì đọc được, mọi thao tác ghi kiểm toán có mã phiên; hết hạn thì `403`.
