# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-41
Tính năng: TS-13-41 · Bất biến nhật ký kiểm toán

  @TC-13-119 @P1 @Bảo @mật
  Kịch bản: TC-13-119 Mọi vai trò ứng dụng và quản trị chỉ `INSERT`, `SELECT`
    # Truy vết: BR-13-002, 019 · FR-13-011 · NFR-13-023
    Biết `ph13_isolation_test.sql`; vai trò ứng dụng, quản trị nền tảng, DBA thử.
    Khi mỗi vai trò chạy `UPDATE`, `DELETE`, `TRUNCATE`, `DROP PARTITION`, `ALTER TABLE` lên `audit_event` và bảng neo.
    Và thử API và giao diện xóa, sửa bản ghi.
    Thì vai trò ứng dụng: lỗi quyền cho mọi lệnh ngoài `INSERT`, `SELECT`; không có API hay nút sửa, xóa; ngoại lệ duy nhất là tiến trình lưu trữ phân vùng đã xác minh.

  @TC-13-120 @P1 @Bảo @mật
  Kịch bản: TC-13-120 Can thiệp bằng DBA thử bị phát hiện ≤ 24 giờ
    # Truy vết: BR-13-002 · FR-13-015 · NFR-13-016 · ERR-13-109
    Biết F-AUD-CUT; chỉ SIT.
    Khi DBA thử sửa một bản ghi cũ chưa neo; chờ kiểm tra hằng ngày.
    Thì phát hiện ≤ 24 giờ; ERR-13-109 Nghiêm trọng; bản sao WORM giữ giá trị gốc làm bằng chứng.
