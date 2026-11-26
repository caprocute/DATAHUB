# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-32
Tính năng: TS-15-32 · Không lộ bí mật và không token ở trình duyệt

  @TC-15-175 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-175 Dò mồi bí mật sau cấp và xoay
    # Truy vết: NFR-15-009 · FR-15-027, 028, 029, 030 · BR-15-011 · LGC-APIM-011; LGC-IAM-006.
    Biết bộ sinh khóa thay bằng giá trị `DH-CANARY-{ca}` (móc kiểm thử); ứng dụng An.
    Khi cấp API key, cấp client_credentials, xoay một credential.
    Và tìm `DH-CANARY-{ca}` ở: phản hồi API (ngoài lần cấp), log ứng dụng 5 phút, vết OTel, bảng `ph15_portal.*`, outbox, Kafka, Valkey, tệp xuất, mẫu mã, nhật ký gateway, PH-13.
    Thì mọi nơi 0 lần; CSDL chỉ có tiền tố 8 ký tự và băm.

  @TC-15-176 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-176 Dò mồi trong lượt thử
    # Truy vết: NFR-15-009 · FR-15-035, 040, 050 · BR-15-024 · LGC-APIM-022.
    Biết thân `{"ghiChu":"DH-CANARY-ct"}`, tiêu đề `X-API-Key: DH-CANARY-ct`.
    Khi thử MOCK và BACKEND; lưu vào bộ sưu tập; xem lịch sử, nhật ký, kiểm toán.
    Thì 0 canary ở `try_run`, lịch sử, nhật ký ứng dụng, kiểm toán, EVT-15-11, log, vết; tiêu đề xác thực bị loại khỏi bộ sưu tập.

  @TC-15-177 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-177 Không token ở trình duyệt
    # Truy vết: NFR-15-010 · FR-15-019 · UI-15-08 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết playwright; sau đăng nhập SSO và dh-dev.
    Khi kiểm `localStorage`, `sessionStorage`, IndexedDB, biến toàn cục, cookie không `HttpOnly`.
    Và bắt mọi yêu cầu XHR/fetch của SPA.
    Thì không có JWT, `access_token`, `refresh_token`; cookie phiên `HttpOnly`, `Secure`, `SameSite`; SPA không gửi `Authorization: Bearer` (BFF dùng cookie); yêu cầu ghi có chống CSRF.

  @TC-15-178 @P2 @Âm @Bảo @mật
  Kịch bản: TC-15-178 Không bí mật ở phản hồi, bộ đệm trình duyệt, log gateway
    # Truy vết: NFR-15-009 · FR-15-029 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết phản hồi cấp credential và `GET .../credentials`.
    Khi kiểm tiêu đề, bộ nhớ đệm, lịch sử trình duyệt, log APISIX.
    Thì `Cache-Control: no-store`; không `secret` ở `GET`; log gateway không ghi thân; ZAP không tìm thấy bí mật ở đường khác.
