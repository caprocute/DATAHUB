# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-32
Tính năng: TS-16-32 · Phân quyền PERM-16, bốn mắt và tài khoản máy

  @TC-16-110 @P1 @Bảo @mật @Truy
  Kịch bản: TC-16-110 Ma trận quyền theo vai trò
    # Truy vết: PERM-16-read, PERM-16-admin, PERM-16-approve, PERM-16-source, PERM-16-manual, PERM-16-run, PERM-16-report, PERM-16-export, PERM-16-arch, PERM-16-arch-assess, PERM-16-national, PERM-16-compare, PERM-16-config, PERM-16-audit-read · ERR-00-403 · API-16-002, 012, 022, 032, 050, 065, 079, 095, 108, 118, 092, 128, 129
    Biết người dùng ở bảng 2.2: VW, TA, TO, SO, DS, AU, PA, PU; D02-08 là nguồn quyền.
    Khi với mỗi cặp (vai trò, API đại diện của từng quyền) gọi một lần
    Và so kết quả với bảng quyền trong FRS mục 3.2
    Và ba vai trò PU, AU, VW thử mọi API ghi
    Thì mọi cặp được phép trả mã thành công, mọi cặp không được trả `403` ERR-00-403, không có đường tắt (ví dụ TO không `:approve`, VW không ghi, AU xuất được nhưng không nhập tay, PU chỉ đọc và so sánh, PA chỉ ghi mẫu `COMMON` và so sánh). 0 lệch giữa FRS và hành vi.

  @TC-16-111 @P1 @Bảo @mật
  Kịch bản: TC-16-111 Bốn cặp loại trừ không có đường vòng
    # Truy vết: FR-16-005, FR-16-015, FR-16-028, FR-16-047 · API-16-012, 040, 072, 074, 108 · ERR-16-005 · BR-16-003, BR-16-004, BR-16-005, BR-16-024
    Biết U-T90-TA3 có cả `PERM-16-report` và `PERM-16-approve`; hai phiên trình duyệt khác nhau của cùng người; hai tài khoản mới.
    Khi TA3 soạn rồi `:approve` định nghĩa chỉ tiêu của chính mình
    Và TA3 lập báo cáo rồi `:approve`, `:publish`
    Và TO nhập số tay rồi tự `:accept`
    Và SO lập đánh giá tuân thủ rồi tự `:confirm`
    Và thử bằng hai phiên của cùng người, đổi `If-Match`, gọi trực tiếp API không qua giao diện
    Và người thứ hai khác làm đúng các bước
    Thì bốn trường hợp tự duyệt đều `403` ERR-16-005, kể cả người có đủ hai quyền, đổi phiên hoặc gọi API trực tiếp. Người thứ hai khác thực hiện thành công. Mỗi lần chặn có kiểm toán từ chối.
