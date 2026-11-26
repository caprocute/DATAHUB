# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-34
Tính năng: TS-15-34 · Phân quyền và tách nhiệm

  @TC-15-184 @P1 @Âm
  Kịch bản: TC-15-184 Ma trận vai trò × API ghi
    # Truy vết: ERR-15-005 · FR-15-014, 042, 056, 058 · API-15-023, 056, 072, 084, 117, 122, 128 · LGC-APIM-007.
    Biết U-ANON, U-T68-DEV-AN, U-T68-OR, U-T68-SV, U-T68-CA, U-T68-TA, U-T68-SO, U-T68-AU; bảng vai trò → quyền sinh từ D02-08.
    Khi mỗi vai gọi mọi API ghi và API quản trị.
    Thì cặp không có quyền `403` ERR-15-005 (ẩn danh `401` ERR-15-004), cặp có quyền thành công; kết quả khớp bảng quyền, không ngoại lệ.

  @TC-15-185 @P1 @Âm
  Kịch bản: TC-15-185 Bốn mắt độc lập với quyền
    # Truy vết: BR-15-012, 021 · FR-15-015, 042 · ERR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-CA có cả `PERM-15-content-write` và `PERM-15-content-publish`.
    Khi CA soạn, gửi và tự duyệt; CA đề xuất và tự duyệt thử production.
    Thì `403` ERR-15-023 ở cả hai, dù đủ quyền.

  @TC-15-186 @P2 @Âm
  Kịch bản: TC-15-186 Chưa đăng nhập hoặc phiên hết hạn
    # Truy vết: ERR-15-004 · FR-15-019 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết không cookie; cookie hết hạn.
    Khi gọi mọi API không thuộc `/public`.
    Thì `401` ERR-15-004; `/public/*` không cần đăng nhập (khi bật).

  @TC-15-187 @P2 @Dương
  Kịch bản: TC-15-187 Menu và đường dẫn theo quyền
    # Truy vết: UI-15-24, 25, 26, 28 · BR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết vai DEV, OR, SV, TA, SO, AU.
    Khi mở menu và gõ trực tiếp đường dẫn `/quan-tri-cong/...`.
    Thì mục không có quyền không hiện; gõ trực tiếp `404` hoặc `403` theo TC-15-162; không lộ cấu trúc quản trị.
