# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-13
Tính năng: TS-12-13 · Chuyển định danh khi sáp nhập tenant

  @TC-12-043 @P2 @Dương
  Kịch bản: TC-12-043 Lập kế hoạch và thực hiện chuyển định danh
    # Truy vết: FR-12-019 · UC-12-15 · UI-12-19 · API-12-045, 046 · SEC-80
    Biết S-PH20; T91 (12 người dùng, 3 client) và T92; một tên đăng nhập trùng.
    Khi `:plan` rồi đọc xung đột; `:execute`.
    Thì kế hoạch nêu tên trùng cần đổi mã; sau thực hiện người dùng ở T92 với vai trò ánh xạ, vết kiểm toán giữ `tenant_id` cũ ở bản ghi lịch sử; client chuyển, realm T91 chuyển `READ_ONLY`.

  @TC-12-044 @P3 @Âm
  Kịch bản: TC-12-044 Chuyển định danh khi tenant không ở trạng thái cho phép
    # Truy vết: FR-12-019 · API-12-046 · ERR-12-041 · ERR-12-040
    Biết T92 `SUSPENDED`; hoặc PH-20 không sẵn sàng.
    Khi `:execute` khi T92 tạm ngừng; lặp khi dịch vụ phụ thuộc tắt.
    Thì `409` ERR-12-041; khi phụ thuộc tắt `503` ERR-12-040; không có thay đổi nửa chừng.
