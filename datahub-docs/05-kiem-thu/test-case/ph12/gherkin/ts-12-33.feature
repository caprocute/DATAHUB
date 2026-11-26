# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-33
Tính năng: TS-12-33 · Không lộ bí mật

  @TC-12-105 @P1 @Bảo @mật
  Kịch bản: TC-12-105 Mồi bí mật qua toàn bộ vòng đời định danh
    # Truy vết: NFR-12-020 · BR-12-045, BR-12-023 · FR-12-006, 022, 034, 035 · API-12-003, 066, 074
    Biết mật khẩu `DH-CANARY-pw`, bí mật client `DH-CANARY-cs`, token mồi; mọi loại lỗi.
    Khi tạo người dùng, kích hoạt bằng mật khẩu mồi, đăng ký TOTP, đăng nhập sai và đúng, tạo client, xoay bí mật, lấy token, xuất báo cáo.
    Và tìm mồi ở phản hồi API (HAR Playwright), `localStorage`, `sessionStorage`, log mọi pod 1 giờ (Loki), vết (Tempo), mọi bảng `ph12_iam.*`, Kafka `t68.*`, tệp xuất, kiểm toán PH-13, thông báo lỗi.
    Thì mồi sạch ở mọi nơi; mật khẩu chỉ ở dạng băm trong Keycloak; bí mật client chỉ ở OpenBao; khóa ký riêng không có trong log, ảnh container, kho mã.

  @TC-12-106 @P1 @Bảo @mật
  Kịch bản: TC-12-106 Mồi trong lỗi và trong khi hệ phụ thuộc hỏng
    # Truy vết: NFR-12-020 · BR-12-045 · ERR-12-003, ERR-12-015, ERR-12-111, ERR-12-039 · API-12-003, 074
    Biết mồi trong mật khẩu, thân sai lược đồ, JWKS sai; OpenBao tắt.
    Khi gây lỗi 400, 422, 401, 503 với thân chứa mồi; xem log và thân lỗi.
    Thì thân lỗi và log không chứa mồi; thông báo lỗi chỉ nêu tên trường.
