# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-01
Tính năng: TS-03-01 · TLS 1.3, mTLS và chứng thư biên

  @TC-03-001 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-001 Biên chỉ nhận TLS 1.3, TLS 1.2 và thấp hơn bị từ chối
    # Truy vết: FR-03-001 · API-03-031 · UI-03-12 · BR-03-003 · NFR-03-010 · LGC-BUS-041.
    Biết `ext.t68.sim.test`, `int.t68.sim.test` ở IPv4; U-T68-TA.
    Khi `openssl s_client -tls1_3` tới hai host.
    Và `openssl s_client -tls1_2`, rồi `-tls1_1` tới hai host.
    Và chạy `testssl.sh` tới `ext.t68.sim.test`.
    Và `GET /edge/tls-profile`.
    Thì bước 1 bắt tay thành công. Bước 2 bị từ chối ở cả hai host. Bước 3 điểm A+, 0 giao thức hoặc bộ mã yếu. Bước 4 trả `200`, `minVersion = TLSv1.3`, danh sách bộ mã khớp bước 3. KT: không.

  @TC-03-002 @P2 @Dương
  Kịch bản: TC-03-002 Ngoại lệ TLS 1.2 có thời hạn cho host riêng
    # Truy vết: FR-03-001 · API-03-032, 033, 034 · UI-03-12 · BR-03-003 · UC-03-17.
    Biết U-PA; host chuyên dụng `legacy.t68.sim.test`.
    Khi `POST /tls-exceptions` với `host = legacy.t68.sim.test`, `days = 180`, lý do.
    Và `openssl s_client -tls1_2` tới `legacy.t68.sim.test` và tới `ext.t68.sim.test`.
    Và `POST /tls-exceptions/{exceptionId}:revoke`; chờ hiệu lực ≤ 60 s; lặp bước 2.
    Và `POST …:revoke` lần hai.
    Thì bước 1 trả `201`. Bước 2 TLS 1.2 chỉ thành công ở host ngoại lệ. Bước 3 `200`, sau đó host ngoại lệ cũng từ chối TLS 1.2. Bước 4 `409` ERR-03-019. KT: có (`TLS_EXCEPTION_CREATE`, `TLS_EXCEPTION_REVOKE`).

  @TC-03-003 @P2 @Âm
  Kịch bản: TC-03-003 Ngoại lệ TLS 1.2 quá hạn, thiếu lý do, không đủ quyền
    # Truy vết: FR-03-001 · API-03-033 · ERR-03-003, 022 · BR-03-003.
    Biết U-PA; U-T68-VW.
    Khi `POST /tls-exceptions` với `days = 181`.
    Và `POST /tls-exceptions` thiếu `reason`.
    Và U-T68-VW gọi `POST /tls-exceptions` hợp lệ.
    Thì bước 1, 2 trả `400` ERR-03-003 kèm `errors[]` theo trường; bước 3 trả 403-PQ. Không có ngoại lệ nào được tạo. KT: không.

  @TC-03-004 @P2 @Âm
  Kịch bản: TC-03-004 SNI hoặc Host không khớp dịch vụ nào
    # Truy vết: FR-03-001 · ERR-03-128 · BR-03-023 · UC-03-05.
    Biết cửa `apisix-ext`.
    Khi `curl --resolve unknown.sim.test:443:{ip-ext} https://unknown.sim.test/`.
    Và `curl` tới `ext.t68.sim.test` nhưng đặt `Host: unknown.sim.test`.
    Thì cả hai trả `421`, Lỗi GW 128, câu "Không tìm thấy dịch vụ ứng với địa chỉ truy cập."; thân không nêu tên tenant nào.

  @TC-03-005 @P1 @Dương
  Kịch bản: TC-03-005 mTLS hợp lệ với token ràng buộc chứng thư
    # Truy vết: FR-03-002, 014 · API-03-016, 035 · UI-03-05, 12 · UC-03-02 · BR-03-004 · LGC-BUS-041, LGC-APIM-011.
    Biết C-HTTT2 có chứng thư khách do CA đã đăng ký; token có `cnf.x5t#S256` khớp; route `r-sensitive`.
    Khi `GW C-HTTT2 GET https://int.t68.sim.test/sensitive/ping` kèm chứng thư và token.
    Và `GET /consumers/ht-sensitive/credentials`.
    Thì bước 1 `200`; backend nhận `X-DH-Tenant = T68`, `X-DH-Client`. Bước 2 `200`, chỉ có dấu vân tay và hạn chứng thư, không có khóa riêng.

  @TC-03-006 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-006 mTLS thiếu, sai CA hoặc không khớp `cnf`
    # Truy vết: FR-03-002, 014 · ERR-03-108 · UC-03-02 · BR-03-004 · SEC-24.
    Biết như TC mTLS hợp lệ; thêm chứng thư của CA lạ và chứng thư hợp lệ của C-HTTT1.
    Khi gọi `r-sensitive` có token đúng nhưng không xuất trình chứng thư.
    Và xuất trình chứng thư của CA lạ.
    Và xuất trình chứng thư hợp lệ của C-HTTT1 với token của C-HTTT2.
    Thì cả ba trả `403` Lỗi GW 108, câu "Chứng thư khách không hợp lệ hoặc không khớp token."; backend không nhận lượt nào; có cảnh báo EVT: `security.alert-raised` mức Trung bình ở lần thứ ba.

  @TC-03-007 @P2 @Dương @Bảo @mật
  Kịch bản: TC-03-007 Bộ CA khách và danh sách chứng thư biên theo tenant
    # Truy vết: FR-03-002, 049 · API-03-035, 068, 069 · ERR-03-001, 022 · BR-03-028 · UI-03-12.
    Biết U-T68-VW; U-T01-TA; chứng thư `cert-ext-t01` chỉ có ở T01.
    Khi U-T68-VW `GET /edge/client-ca-bundles`, `GET /certificates`.
    Và U-T68-VW `GET /certificates/cert-ext-t01`.
    Và U-T68-VW `GET /certificates/khong-co`.
    Thì bước 1 `200`, không có thân khóa riêng; chỉ thấy chứng thư của T68 và `COMMON`. Bước 2 và 3 cùng 404-ẩn.

  @TC-03-008 @P1 @Dương
  Kịch bản: TC-03-008 Gia hạn chứng thư biên không cắt kết nối
    # Truy vết: FR-03-049 · API-03-070, 069 · UI-03-12 · EVT-03-08 · NFR-03-011 · BR-03-016.
    Biết U-T68-TO; 200 kết nối HTTP/2 đang mở và tải 100 lượt/giây; chứng thư `cert-ext-t68`.
    Khi `POST /certificates/cert-ext-t68:renew`.
    Và theo dõi tải và kết nối trong lúc nạp chứng thư mới.
    Và `GET /certificates/cert-ext-t68`.
    Thì bước 1 `202`. Bước 2 0 lượt gọi lỗi, 200 kết nối cũ vẫn sống tới khi tự đóng. Bước 3 `serial` mới, hạn mới. KT: có (`CERT_RENEW`).

  @TC-03-009 @P2 @Âm
  Kịch bản: TC-03-009 Gia hạn chứng thư lỗi: chuỗi sai, khóa ký không sẵn sàng, đang gia hạn
    # Truy vết: FR-03-049 · API-03-070 · ERR-03-015, 016, 019, 022 · UI-03-12.
    Biết U-T68-TO; PKI giả trả `F-CERT-WRONG-HOST`; Chaos làm OpenBao mất.
    Khi `POST …:renew` khi PKI giả trả chứng thư sai host.
    Và gọi hai lần liên tiếp `:renew` cho cùng chứng thư.
    Và ngắt OpenBao rồi gọi `:renew`.
    Và U-T68-VW gọi `:renew`.
    Thì bước 1 `422` ERR-03-016 và chứng thư đang chạy không đổi. Bước 2 lần hai `409` ERR-03-019. Bước 3 `503` ERR-03-015 kèm `retryAfterSeconds`. Bước 4 403-PQ.

  @TC-03-010 @P2 @Dương
  Kịch bản: TC-03-010 Cảnh báo chứng thư sắp hết hạn và tự gia hạn trước 30 ngày
    # Truy vết: FR-03-049, 002 · EVT-03-08 · NFR-03-011 · UI-03-12.
    Biết `faketime` đưa chứng thư `cert-ext-t68` còn 31 ngày, rồi 29 ngày; consumer `ht-sensitive` có chứng thư còn 25 ngày.
    Khi chạy lịch kiểm tra chứng thư ở mốc 31 và 29 ngày.
    Và gọi `r-sensitive` bằng C-HTTT2.
    Thì Ở mốc 29 ngày có đúng một EVT: `certificate.expiring` (nếu tự gia hạn chưa chạy xong); chứng thư biên được gia hạn tự động trước mốc 30 ngày. Bước 2 `200` kèm tiêu đề `X-DH-Cert-Expires-In-Days: 25`.
