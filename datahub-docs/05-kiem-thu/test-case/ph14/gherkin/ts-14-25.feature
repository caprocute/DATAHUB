# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-25
Tính năng: TS-14-25 · Thông báo thay đổi từ quốc gia

  @TC-14-064 @P3 @Dương
  Kịch bản: TC-14-064 Nhận thông báo thay đổi và sinh đề xuất
    # Truy vết: FR-14-042 · API-14-085 · UC-14-28 · UI-14-10 · ERR-14-121.
    Biết S-NDXP-IN; E-NDXP-IN.
    Khi `POST /inbound/v1/ndxp-vao/notifications` loại `CATALOG_CHANGED` hợp lệ.
    Và gửi loại thông báo không hỗ trợ.
    Thì bước 1 `202`, tạo đề xuất cho IE ở UI-14-10, cấu hình chưa đổi; bước 2 `400` ERR-14-121.
