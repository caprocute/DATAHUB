# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-07
Tính năng: TS-14-07 · Cung cấp lại dịch vụ quốc gia cho HTTT

  @TC-14-019 @P1 @Dương
  Kịch bản: TC-14-019 Cung cấp lại dịch vụ và lọc trường theo hợp đồng
    # Truy vết: FR-14-009 · API-14-021, 022, 023 · UI-14-05 · UC-14-07 · BR-14-007, 009.
    Biết U-T68-IE; V-HT `ACTIVE`; HTTT `HT-MOTCUA`; hợp đồng chỉ cho `hoTen`, `ngaySinh`.
    Khi `PUT /services/hotich-tra-cuu/exposure` cấp cho `HT-MOTCUA`.
    Và `POST …/exposure:publish`.
    Và S-HT-MC gọi dịch vụ; phản hồi quốc gia có thêm trường `soCCCD`.
    Thì bước 2 thành công; bước 3 trả chỉ `hoTen`, `ngaySinh`; HTTT không nhận khóa, token, địa chỉ nền tảng.

  @TC-14-020 @P2 @Âm
  Kịch bản: TC-14-020 Cung cấp lại khi chưa đủ điều kiện hoặc đường dẫn xung đột
    # Truy vết: FR-14-009 · API-14-022, 023 · ERR-14-025, 001.
    Biết dịch vụ `DRAFT`; hai dịch vụ cùng đường dẫn cung cấp lại.
    Khi `POST …/exposure:publish` dịch vụ `DRAFT`.
    Và cung cấp lại dịch vụ thứ hai trùng đường dẫn.
    Và `GET /services/khong-co/exposure`.
    Thì `422` ERR-14-025 hai lần; `404` ERR-14-001.
