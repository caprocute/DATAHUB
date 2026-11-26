# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-34
Tính năng: TS-14-34 · Phân quyền và tách nhiệm

  @TC-14-086 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-086 Ma trận quyền: vai trò × thao tác
    # Truy vết: FR-14-003, 013, 028, 032, 050 · PERM-14-read · PERM-14-admin · PERM-14-service · PERM-14-route · PERM-14-approve · PERM-14-cert · PERM-14-quota · PERM-14-operate · PERM-14-sync · PERM-14-audit-read · PERM-14-audit-reveal · UI-14-17.
    Biết mọi người dùng mục 2.2; bảng tham số hóa theo FRS §3.2.
    Khi với mỗi cặp (vai trò, thao tác), gọi API tương ứng và đối chiếu `200` hay `403`.
    Và mở UI-14-02, 08, 09, 17 bằng từng vai trò.
    Thì kết quả khớp ma trận FRS §3.2; giao diện ẩn nút không có quyền nhưng máy chủ vẫn `403` khi gọi thẳng; PA và vai trò kiểm toán không có đường vòng quyền duyệt.

  @TC-14-087 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-087 Tài khoản máy chỉ gọi, không quản trị; mã HTTT từ token
    # Truy vết: PERM-14-invoke · BR-14-007 · API-14-075, 001, 042 · ERR-14-106.
    Biết S-HT-MC; S-HT-KHAC; token hết hạn; token thiếu scope.
    Khi S-HT-MC gọi `GET /platforms`, `POST /quotas`.
    Và gọi `invocations` bằng token hết hạn, token thiếu scope.
    Và S-HT-KHAC gọi dịch vụ chưa cấp.
    Thì `403` ở bước 1; `401` rồi `403` ở bước 2; `403` ERR-14-106 ở bước 3.
