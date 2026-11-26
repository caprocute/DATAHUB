# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-19
Tính năng: TS-12-19 · Đăng nhập liên tenant và liên kết VNeID

  @TC-12-059 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-12-059 Người dùng hai tenant chọn tenant khi đăng nhập
    # Truy vết: FR-12-027 · UC-12-13 · UI-12-18 · API-12-073, 074 · BR-12-031 · SEC-80
    Biết U-MULTI; U-PO.
    Khi U-MULTI chọn T68 rồi chọn T01.
    Và dùng token T68 gọi API T01.
    Và U-PO thử chọn tenant T68 khi chưa có quyền có thời hạn.
    Thì mỗi token mang đúng một `tenant`; bước 2 trả 404-ẩn; bước 3 bị từ chối.

  @TC-12-060 @P3 @Dương @Âm
  Kịch bản: TC-12-060 Liên kết, gỡ VNeID, trùng số định danh
    # Truy vết: FR-12-028 · UI-12-11 · API-12-054, 055 · ERR-12-034 · BR-12-029 · CMP-LAW-10
    Biết SIM-VNEID; hai người dùng T68; loại bỏ mạng xã hội theo LGC-IAM-007.
    Khi người dùng A xác nhận liên kết VNeID; người dùng B liên kết cùng số định danh.
    Và A gỡ liên kết; thử đăng nhập bằng VNeID khi chưa có tài khoản.
    Và tìm nút đăng nhập Google, Facebook ở UI-12-18.
    Thì bước 1 B nhận `409` ERR-12-034; bước 2 không tự tạo tài khoản; bước 3 không có nút mạng xã hội (LGC-IAM-007 bị loại); số định danh không ở log.
