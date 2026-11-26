# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-31
Tính năng: TS-01-31 · Phân quyền và tách nhiệm

  @TC-01-121 @P1 @Âm @Bảomật
  Kịch bản: TC-01-121 Ma trận vai trò × quyền
    # Truy vết: FR-01-001, 003, 012, 018, 025, 029 · API-01-001, 004, 023, 032, 045, 051 · ERR-01-052.
    Biết người dùng đủ mười ba vai trò theo ma trận §3.2 của FRS (PA, PO, TA, TO, SO, IE, IA, SV, CA, OR, DO, VW, AU).
    Khi tham số hóa: mỗi vai trò gọi một API đại diện cho từng quyền `PERM-01-read`, `create`, `submit`, `approve`, `credential`, `suspend` và hai quyền `PERM-18-config`, `PERM-18-migration`.
    Thì chỉ cặp ● (hoặc ○ đúng đối tượng) trong ma trận được `2xx`; mọi cặp còn lại `403-PQ`, không có ngoại lệ nào ở giao diện mà API cho qua.

  @TC-01-122 @P1 @Âm @Bảomật
  Kịch bản: TC-01-122 Bốn mắt tại bốn điểm
    # Truy vết: BR-01-017 · FR-01-018, 024, 031 · API-01-032, 044, 053, 059 · ERR-01-017.
    Biết U-T68-X1 (TA + IE, cấu hình sai có chủ đích).
    Khi X1 lập hồ sơ rồi thẩm định kỹ thuật của chính hồ sơ.
    Và X1 thẩm định rồi phê duyệt cùng hồ sơ.
    Và X1 nộp hồ sơ rồi kích hoạt PRODUCTION.
    Và X1 đề nghị chấm dứt rồi duyệt.
    Thì mọi bước vi phạm `403` ERR-01-017, bất kể X1 có đủ quyền theo vai trò.

  @TC-01-123 @P1 @Bảomật
  Kịch bản: TC-01-123 Xác thực lại hai yếu tố cho mọi thao tác nhạy cảm
    # Truy vết: NFR-01-012 · BR-01-009 · API-01-032, 040, 044, 045, 047, 051, 054 · ERR-01-035.
    Biết TA1, SO, TECH; `mfa.stepUpMinutes = 5`.
    Khi với từng thao tác (phê duyệt, kích hoạt, tạm ngừng, thu hồi, xoay vòng, mở bàn giao, thao tác khẩn): gọi khi phiên chưa có MFA mới.
    Và xác thực MFA; gọi lại trong 5 phút; tua 6 phút; gọi lần nữa.
    Thì `403` ERR-01-035 ở bước 1 và sau 6 phút; thành công trong 5 phút. Thao tác thất bại không thay đổi dữ liệu.

  @TC-01-124 @P1 @Âm @Bảomật
  Kịch bản: TC-01-124 Token dịch vụ đúng scope, OR đúng tổ chức
    # Truy vết: FR-01-003, 037, 038 · API-01-004, 062, 063, 087 · ERR-01-006, 052 · BR-01-030.
    Biết S-INT, S-RECON, S-CB; U-T68-OR1; Văn phòng UBND.
    Khi mỗi token dịch vụ gọi API của scope khác; gọi API người dùng.
    Và OR1 tạo hồ sơ của Văn phòng UBND; sửa `HT-DVC`.
    Thì bước 1: `403-PQ`. Bước 2: `403` ERR-01-006 và `404-ẩn`.
