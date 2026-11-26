# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-14
Tính năng: TS-15-14 · Cấp thông tin xác thực và bí mật hiện một lần

  @TC-15-087 @P1 @Dương
  Kịch bản: TC-15-087 Cấp client_credentials sandbox
    # Truy vết: FR-15-027, 029 · UC-15-15 · API-15-061, 062 · UI-15-13 · EVT-15-03 · BR-15-011 · NFR-15-006 · LGC-IAM-006.
    Biết U-T68-DEV-AN; ứng dụng ACTIVE; Keycloak realm `dh-dev` thật ở SIT.
    Khi `POST /apps/app-tra-cuu-ho-tich/credentials` {kind `CLIENT_CREDENTIALS`}.
    Và lấy token từ Keycloak bằng `clientId`, `clientSecret` vừa nhận.
    Và `GET /apps/app-tra-cuu-ho-tich/credentials`.
    Thì `201` trả `clientId = sbx-t68-app-tra-cuu-ho-tich-1` và `clientSecret` một lần; client tồn tại ở realm `dh-dev`, token lấy được, hạn ≤ 180 ngày; EVT-15-03; KT: có (`SECRET_ISSUED`); bước 3 chỉ có tiền tố 8 ký tự, trạng thái, hạn, không có bí mật; p95 ≤ 3 giây.

  @TC-15-088 @P2 @Dương
  Kịch bản: TC-15-088 Cấp theo private_key_jwt không có bí mật
    # Truy vết: FR-15-027 · API-15-062 · BR-15-011 · LGC-IAM-006.
    Biết cặp khóa thử, JWKS công khai.
    Khi `POST .../credentials` với `authMethod = private_key_jwt` và `jwks`.
    Thì `201` chỉ có `clientId`, không có bí mật để hiện; Keycloak ghi khóa công khai; lấy token bằng chứng thực khóa thành công.

  @TC-15-089 @P1 @Dương
  Kịch bản: TC-15-089 Cấp API key sandbox
    # Truy vết: FR-15-028 · UC-15-15 · API-15-062 · BR-15-011 · LGC-APIM-011.
    Biết ứng dụng ACTIVE của An.
    Khi `POST .../credentials` {kind `API_KEY`}.
    Và gọi sandbox bằng `X-API-Key`.
    Và kiểm CSDL `ph15_portal.app_credential`.
    Thì khóa `dhsk_t68_…` hiện một lần; gọi sandbox `200`; CSDL chỉ có tiền tố 8 ký tự và băm, không có khóa; EVT-15-03.

  @TC-15-090 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-090 Bí mật không xem lại được
    # Truy vết: FR-15-029 · UC-15-15 · API-15-061, 062 · UI-15-13 · ERR-15-019 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết credential vừa cấp; `Idempotency-Key` K2.
    Khi đóng hộp thoại bí mật, nạp lại UI-15-13, `GET .../credentials`.
    Và phát lại `POST` cấp với K2.
    Thì không có bí mật ở bước 1 (tiền tố thôi); bước 2 `410` ERR-15-019 "Bí mật chỉ hiện một lần..."; hộp thoại bí mật có nút sao chép, tải xuống, yêu cầu xác nhận "Tôi đã lưu"; phản hồi `Cache-Control: no-store`.

  @TC-15-091 @P1 @Âm
  Kịch bản: TC-15-091 Vượt giới hạn, ứng dụng không ACTIVE, thiếu quyền, Keycloak lỗi
    # Truy vết: FR-15-027, 028 · API-15-062 · ERR-15-005, 016, 017, 020 · BR-15-010 · LGC-APIM-011; LGC-IAM-006.
    Biết `15.cred.max-per-app = 3`; ứng dụng có 3 credential; ứng dụng SUSPENDED; Bi VIEWER; Keycloak ngắt.
    Khi cấp credential thứ 4.
    Và cấp ở ứng dụng SUSPENDED.
    Và bi cấp.
    Và cấp khi Keycloak ngắt.
    Thì `422` ERR-15-016; `409` ERR-15-017; `403` ERR-15-005; `503` ERR-15-020, không có bản ghi credential nào được tạo.

  @TC-15-092 @P2 @Âm
  Kịch bản: TC-15-092 Sập giữa pha cấp: không credential mồ côi
    # Truy vết: FR-15-027 · UC-15-15 · EVT-15-03 · BR-15-011 · LGC-IAM-006.
    Biết chaos Mesh giết pod `api` sau khi tạo client Keycloak, trước khi ghi CSDL.
    Khi bắt đầu cấp; giết pod; chờ đối soát.
    Thì không có client Keycloak `sbx-…` nào không có bản ghi ở cổng sau chu kỳ đối soát; không bí mật nào được trả cho người dùng; người dùng thử lại được.
