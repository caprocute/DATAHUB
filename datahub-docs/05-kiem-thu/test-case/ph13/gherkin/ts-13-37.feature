# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-37
Tính năng: TS-13-37 · Phân quyền và tách nhiệm

  @TC-13-101 @P1 @Bảo @mật
  Kịch bản: TC-13-101 Ma trận quyền PERM-13 theo từng vai trò
    # Truy vết: ERR-13-009, 010 · FR-13-020, 042, 047, 053, 061 · API-13-001, 019, 032, 036, 054, 062, 074, 082
    Biết mọi người dùng mục 2.2.
    Khi với mỗi vai trò, gọi một API đại diện cho từng quyền `dashboard`, `logs`, `audit-read`, `audit-export`, `alert-admin`, `alert-ack`, `security`, `admin`.
    Và gọi không token và token hết hạn.
    Thì khớp ma trận D02-08: PO không có `audit-read`; SO, AU có `audit-export`; TA không có `audit-export`; VW chỉ `dashboard`; 403-PQ cho phần còn lại; không token `401` ERR-13-010.

  @TC-13-102 @P1 @Bảo @mật
  Kịch bản: TC-13-102 Thao tác nhạy cảm cần xác thực lại phiên
    # Truy vết: ERR-13-028 · BR-13-006, 029 · FR-13-020, 024, 014, 053 · API-13-074, 077, 082, 084, 055, 060
    Biết U-T68-AU, U-T68-SO phiên mới đăng nhập 20 phút.
    Khi gọi tra kiểm toán, kiểm tra toàn vẹn, xuất, tải, tinh chỉnh ngưỡng, đề xuất tạm ngừng khi chưa xác thực lại.
    Và xác thực lại bằng TOTP rồi gọi lại.
    Thì bước 1 `403` ERR-13-028; bước 2 `200` hoặc `202`; không có bản ghi thành công nào ở bước 1.

  @TC-13-103 @P1 @Bảo @mật
  Kịch bản: TC-13-103 Tài khoản máy chỉ chạm phạm vi được cấp
    # Truy vết: ERR-13-044 · BR-13-017 · API-13-067, 069, 072, 073, 076, 089
    Biết S-DU, S-PH16, S-PH18, S-PH20, S-HIST.
    Khi mỗi tài khoản gọi API của tài khoản khác.
    Và S-DU gửi bản ghi cho tenant không được cấp.
    Thì `403` ERR-13-044 mọi trường hợp; bản ghi lạ cách ly ERR-13-103.
