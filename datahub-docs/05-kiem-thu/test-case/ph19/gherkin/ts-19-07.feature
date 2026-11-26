# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-07
Tính năng: TS-19-07 · Quản lý nhóm dịch vụ

  @TC-19-151 @P2 @Dương
  Kịch bản: TC-19-151 Thêm, sửa, xóa nhóm dịch vụ
    # Truy vết: FR-19-013 · API-19-015, 016, 017, 018, 019, 028 · UI-19-07, 08 · LGC-PAY-022
    Biết U-ADM1.
    Khi trên UI-19-07 bấm "Thêm nhóm", nhập mã `G-YT`, tên "Y tế", chọn lĩnh vực từ ô tra PH-07, lưu.
    Và sửa tên, đổi thứ tự bằng `Alt+↓`.
    Và xóa `G-YT`.
    Thì bước 1: ô tra gọi API-19-028 có kết quả trong ≤ 500 ms; `POST /service-groups` trả `201`. Bước 2 trả `200`. Bước 3 trả `204` (xóa mềm); nhóm không còn trong bộ lọc lĩnh vực ở UI-19-14. KT: có cho cả ba.

  @TC-19-152 @P2 @Âm
  Kịch bản: TC-19-152 Xóa nhóm còn dịch vụ, mã lĩnh vực hết hiệu lực, trùng mã
    # Truy vết: FR-19-013, 016 · API-19-016, 019 · ERR-19-037, 038, 039
    Biết U-ADM1; G-TP có S-HT; mã lĩnh vực `LV-OLD` hết hiệu lực ở PH-07.
    Khi `DELETE /service-groups/{G-TP}`.
    Và `POST /service-groups` với `sectorCode = LV-OLD`.
    Và `POST /service-groups` với `code = G-TP`.
    Và dừng PH-07 giả lập; `POST /service-groups` với mã lĩnh vực hợp lệ.
    Thì bước 1 trả `409` ERR-19-037. Bước 2, 4 trả `422` ERR-19-039 (bước 4: "chưa kiểm tra được với danh mục dùng chung"). Bước 3 trả `409` ERR-19-038.
