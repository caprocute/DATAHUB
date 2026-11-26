# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-06
Tính năng: TS-03-06 · Xác thực JWT, xác định tenant, phương thức bảo mật theo gói

  @TC-03-027 @P1 @Dương
  Kịch bản: TC-03-027 Gọi với token hợp lệ, backend nhận tiêu đề nội bộ do gateway đặt
    # Truy vết: FR-03-012, 013 · API-03-052 · UI-03-11 · UC-03-01 · BR-03-002, 004 · NFR-03-002 · LGC-APIM-011.
    Biết C-HTTT1 lấy token `client_credentials` từ Keycloak T68; `r-ho-tich`.
    Khi `GW C-HTTT1 GET /ho-tich/ping` kèm `Authorization: Bearer`.
    Và gửi lại kèm tiêu đề giả `X-DH-Tenant: T01`, `X-DH-Consumer: ht-khac`.
    Và `GET /auth/jwks-status`.
    Thì bước 1 `200`; backend nhận `X-DH-Tenant = T68`, `X-DH-Client`, `X-DH-Consumer = ht-ndxp`, `traceparent`. Bước 2 backend vẫn nhận giá trị đúng của T68 (tiêu đề giả bị xóa). Bước 3 `200`, mỗi nút có `kid` đã đệm và `refreshedAt`. Không có lượt gọi nào tới Keycloak cho từng yêu cầu (đếm ở `SIM-KC`).

  @TC-03-028 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-028 Thiếu token, chữ ký sai, `iss` hoặc `aud` sai, token hết hạn
    # Truy vết: FR-03-012 · UC-03-01 · ERR-03-102, 103, 104 · BR-03-004, 023 · SEC-25.
    Biết `SIM-KC` ký được token sai (khóa lạ, `kid` lạ, `iss` realm khác, `aud` khác, `exp` đã qua); `r-ho-tich`.
    Khi gọi không có `Authorization`.
    Và token ký bằng khóa lạ; `kid` không có trong JWKS; `iss` lạ; `aud` lạ; `alg = none`.
    Và token hết hạn 1 giây.
    Thì bước 1 `401` Lỗi GW 102 "Thiếu thông tin xác thực." Bước 2 mọi trường hợp `401` Lỗi GW 103 "Token không hợp lệ. Lấy token mới." Bước 3 `401` Lỗi GW 104 "Token đã hết hạn. Lấy token mới rồi gọi lại." Backend không nhận lượt nào; nhật ký có siêu dữ liệu, không có giá trị tiêu đề `Authorization` (mồi sạch).

  @TC-03-029 @P1 @Chịu @lỗi
  Kịch bản: TC-03-029 Bộ đệm JWKS: Keycloak ngắt vẫn xác minh, quá 24 giờ thì từ chối
    # Truy vết: FR-03-012 · API-03-052 · UI-03-11 · ERR-03-124 · NFR-03-007 · BR-03-004 · SEC-25.
    Biết `gw.jwks.refreshMinutes = 10`; `SIM-KC` ngắt; `faketime`.
    Khi ngắt `SIM-KC`; sau 2 giờ gọi bằng token còn hạn.
    Và tiến thời gian tới 24 giờ + 1 phút không làm mới được JWKS; gọi lại.
    Và bật `SIM-KC`; chờ chu kỳ làm mới; gọi lại.
    Thì bước 1 `200`. Bước 2 `503` Lỗi GW 124 kèm `Retry-After: 30` "Dịch vụ định danh tạm thời không khả dụng. Thử lại sau."; `jwks-status` thấy `stale = true`; có cảnh báo EVT: `security.alert-raised`. Bước 3 `200` trở lại không cần khởi động lại.

  @TC-03-030 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-030 Token của tenant khác hoặc realm khác không dùng được
    # Truy vết: FR-03-013 · UC-03-03 · ERR-03-106 · BR-03-002, 026 · SEC-80, 87 · NFR-03-019.
    Biết C-T01 (token T01); route `r-ho-tich` của T68; route `r-ho-tich` trùng mã của T01.
    Khi C-T01 gọi `https://int.t68.sim.test/ho-tich/ping`.
    Và token T68 nhưng sửa claim `tenant = T01` (ký lại bằng khóa lạ).
    Và C-T01 gọi `https://int.t01.sim.test/ho-tich/ping`.
    Thì bước 1 `401` Lỗi GW 106 "Token không thuộc tỉnh của dịch vụ này." Bước 2 `401` Lỗi GW 103. Bước 3 `200` từ backend của T01, không phải của T68 (kiểm bằng dấu vết backend). Không bên nào thấy dữ liệu của tenant kia; cảnh báo `security.alert-raised` cho bước 1.

  @TC-03-031 @P1 @Dương @Âm
  Kịch bản: TC-03-031 Phương thức bảo mật khác gói, Keyless chỉ dữ liệu mở
    # Truy vết: FR-03-015 · API-03-021, 022, 066 · UI-03-03, 13 · ERR-03-103, 130, 005 · BR-03-004, 014 · LGC-APIM-011.
    Biết C-KEY (khóa API) gọi `r-ho-tich` (gói OAuth); C-OPEN; `r-open-data`; U-T68-TA.
    Khi C-KEY gọi `r-ho-tich` bằng khóa API.
    Và C-OPEN gọi `r-open-data` không xác thực.
    Và C-OPEN gọi `r-ho-tich` không xác thực.
    Và dùng khóa API sai trên route gói khóa API.
    Và `GET /plan-policies`, `GET /plan-policies/{policyCode}`.
    Và cố gắng phát cấu hình có route mức Nhạy cảm đặt Keyless (`POST /snapshots:build`).
    Thì bước 1 `403` Lỗi GW 130 "Phương thức xác thực không đúng với gói của API." Bước 2 `200`. Bước 3 `401` Lỗi GW 102. Bước 4 `401` Lỗi GW 103. Bước 5 `200`, mỗi chính sách có phương thức, hạn mức chiếu từ gói. Bước 6 `422` ERR-03-005 (`findings[]` nêu phương thức không hợp lệ với mức phân loại).
