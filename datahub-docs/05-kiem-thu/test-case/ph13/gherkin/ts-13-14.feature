# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-14
Tính năng: TS-13-14 · Báo cáo truy cập liên tenant

  @TC-13-047 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-047 Mở phiên liên tenant, ghi hai chuỗi, thông báo tenant bị truy cập
    # Truy vết: FR-13-025 · UC-13-16 · API-13-085 · UI-13-16 · BR-13-018 · EVT-13-12
    Biết U-PO mở phiên liên tenant vào T68 kèm lý do; U-T68-AU.
    Khi U-PO mở phiên, xem bảng điều khiển T68.
    Và U-T68-AU mở UI-13-16, `GET /cross-tenant-access`.
    Thì báo cáo có phiên của U-PO, lý do, thời hạn 60 phút; bản ghi ở chuỗi PLATFORM và chuỗi T68; EVT: `cross-tenant-access` vào T68; hết 60 phút phiên tự đóng.

  @TC-13-048 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-048 Truy cập tenant khác không có phiên
    # Truy vết: FR-13-025 · ERR-13-036 · BR-13-018, 030 · API-13-085
    Biết U-PO không có phiên; U-T01-AU.
    Khi U-PO gọi `GET /alerts?targetTenant=t68`.
    Và U-T01-AU gọi `GET /cross-tenant-access` của T68.
    Thì bước 1 `403` ERR-13-036 (không nêu tên tenant đích); bước 2 chỉ thấy báo cáo của T01.
