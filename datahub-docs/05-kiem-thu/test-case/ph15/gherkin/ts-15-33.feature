# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-33
Tính năng: TS-15-33 · An toàn khi lỗi, forward-auth, XSS, IDOR

  @TC-15-179 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-179 forward-auth đóng khi lỗi phụ thuộc
    # Truy vết: FR-15-035, 039 · API-15-082 · UC-15-19 · BR-15-023 · NFR-15-007, 008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt lần lượt Valkey, CSDL, JWKS Keycloak; lời gọi sandbox hợp lệ và không hợp lệ.
    Khi gọi sandbox trong từng sự cố.
    Và khôi phục.
    Thì khi Valkey, CSDL hoặc JWKS lỗi: mọi lời gọi qua `forward-auth` bị từ chối (đóng khi lỗi, Q15-47 cho hạn mức), không lời gọi nào lọt tới backend; đọc danh mục không phụ thuộc Valkey vẫn `200`; sau khôi phục lời gọi hợp lệ `200`.

  @TC-15-180 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-180 Cổng nội bộ không giả mạo được
    # Truy vết: API-15-082 · FR-15-035 · NFR-15-017 · ERR-15-001, 005 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết S-APISIX (SPIFFE hợp lệ); danh tính khác; client Internet.
    Khi gọi `POST /internal/v1/sandbox/authorize` từ danh tính khác APISIX; không mTLS.
    Và gọi qua BFF công khai `/api/portal/v1/internal/v1/...`.
    Và từ APISIX gửi `X-Forwarded-Host` của T01 với credential T68.
    Thì bước 1 bị từ chối ở cổng 8081; bước 2 `404`; bước 3 từ chối (tenant lấy từ host gateway, client không đặt được).

  @TC-15-181 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-181 Markdown không thực thi script, CSP chặt
    # Truy vết: NFR-15-011 · FR-15-014, 017 · BR-15-013 · UI-15-07 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết bộ vector XSS OWASP cho Markdown (120 mẫu) đã đưa vào trang đã đăng qua đường nhập Git (bỏ qua bộ lọc ghi) và qua API.
    Khi mở UI-15-07 từng trang; quét ZAP.
    Thì 0 script thực thi; CSP `script-src 'self'`, không `unsafe-inline`, `frame-ancestors 'none'`; có `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Strict-Transport-Security`; bộ lọc đầu ra loại mẫu lọt qua.

  @TC-15-182 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-182 Không IDOR giữa hai người dùng cùng tenant
    # Truy vết: NFR-15-017 · BR-15-009 · ERR-15-001, 005 · API-15-057, 062, 073, 078, 100, 105, 112 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an và Cự cùng T68; mọi định danh của An: `appCode`, `credentialId`, `tryId`, `collectionId`, `logId`, `messageId`, `ticketCode`.
    Khi cự gọi từng API với định danh của An.
    Thì mọi lần bị từ chối (`403` ERR-15-005 hoặc `404` ERR-15-001 theo FRS ở từng API); dữ liệu của An không đổi.

  @TC-15-183 @P2 @Âm @Bảo @mật
  Kịch bản: TC-15-183 CSRF và đăng nhập giả mạo
    # Truy vết: FR-15-019 · NFR-15-010 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang giả của origin lạ gửi `POST /api/portal/v1/apps` bằng cookie của An.
    Khi gửi yêu cầu chéo origin.
    Thì bị từ chối `403`; `state` và `nonce` đăng nhập được kiểm; không chuyển hướng mở tới địa chỉ ngoài.
