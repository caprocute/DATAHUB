# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-25
Tính năng: TS-17-25 · Chạy công cụ bằng token của người dùng, không có quyền riêng

  @TC-17-080 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-080 Gọi công cụ bằng token ngắn hạn của người dùng với act là dh-assist
    # Truy vết: FR-17-043 · API-17-123 · BR-17-057 · UI-17-10
    # Mục đích: Chứng minh AC-17-12 phần token: `sub` là người dùng, `act` là `dh-assist`, scope chỉ đọc, hạn ngắn.
    Biết T90 bật; Keycloak T90 hỗ trợ token exchange; U-T90-IE; PH-02 WireMock ghi lại header `Authorization` giải mã.
    Khi IE hỏi "tìm API tra cứu hộ gia đình" để trợ lý gọi công cụ tìm API.
    Và đọc claim token đến PH-02.
    Và SO `GET /tools/calls`.
    Thì bước 2 `sub` = IE, `act.sub` = `dh-assist`, `scope` chỉ có scope đọc của API đích (không có `*.write`), `aud` là API đích, thời hạn ≤ vài phút, không dùng token máy. Bước 3 nhật ký gọi công cụ đã che có công cụ, kết quả, thời gian, mã người dùng, không có token.

  @TC-17-081 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-081 Người dùng thiếu quyền thì công cụ thiếu quyền, không nâng quyền
    # Truy vết: FR-17-043, 024 · BR-17-057, 035 · NFR-17-008 · ERR-17-060
    # Mục đích: Chứng minh trợ lý không đọc được thứ người hỏi không đọc được qua công cụ.
    Biết PH-04 WireMock trả `403` với token của U-T90-VW cho luồng `LUONG-NB`, `200` với token U-T90-IE; `dh-assist` không có token máy gọi PH-04.
    Khi VW hỏi "cho tôi xem cấu hình luồng LUONG-NB".
    Và IE hỏi cùng câu.
    Và kiểm mọi lời gọi PH-04 do `dh-assist` phát ra.
    Thì bước 1 trợ lý nhận `403` từ công cụ, trả lời không có quyền, không nêu cấu hình; nhật ký ghi `403`. Bước 2 có kết quả. Bước 3 100 % lời gọi mang token người dùng; 0 lời gọi bằng danh tính máy cho hội thoại.

  @TC-17-082 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-17-082 Không đổi được token thì công cụ không chạy
    # Truy vết: FR-17-043 · BR-17-057 · ERR-17-064 · ERR-17-009
    # Mục đích: Chứng minh ERR-17-064 và không dùng đường dự phòng bằng token máy.
    Biết T94; Keycloak ngừng; U-T94-IE phiên đã hết hạn làm mới.
    Khi IE hỏi câu cần công cụ.
    Và phục hồi Keycloak, IE hỏi lại.
    Thì bước 1 `503` ERR-17-064, không có lời gọi PH nào bằng token máy, câu trả lời không dùng công cụ hoặc nêu lỗi. Bước 2 `200`.
