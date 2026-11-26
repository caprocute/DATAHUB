# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-05
Tính năng: TS-03-05 · Kiểm tra lược đồ, CORS, tiêu đề bảo mật

  @TC-03-024 @P1 @Dương @Âm @Biên
  Kịch bản: TC-03-024 Lược đồ và giới hạn kích thước: chấp nhận hợp lệ, chặn sai
    # Truy vết: FR-03-009 · API-03-009, 002 · UI-03-03 · ERR-03-101, 115, 003, 018 · BR-03-014, 023 · SEC-43.
    Biết `r-ho-tich` có `gw.body.maxBytes = 1 MiB`, `gw.json.maxDepth = 32`; `F-JSON-DEEP`, `F-JSON-BIG`, `F-XML-DOCTYPE`; U-T68-TA.
    Khi POST thân JSON đúng lược đồ 900 KiB.
    Và POST thân sai kiểu trường; JSON sâu 100 mức; XML có DOCTYPE; `Content-Type` lạ.
    Và POST thân 1 MiB + 1 byte và `F-JSON-BIG` (11 MiB).
    Và `PUT /routes/r-ho-tich/request-limits` với `maxBytes = 11 MiB`, rồi `maxBytes = 2 MiB`.
    Thì bước 1 `200`. Bước 2 `400` Lỗi GW 101 kèm `errors[]` nêu trường, không nêu đường dẫn nội bộ. Bước 3 `413` Lỗi GW 115 "Dữ liệu gửi lên quá lớn." Bước 4: 11 MiB vượt trần 10 MiB `422` ERR-03-018; 2 MiB `200`; thân 1,5 MiB sau khi hiệu lực ≤ 60 s `200`. Dữ liệu sai không tới backend.

  @TC-03-025 @P2 @Dương @Âm
  Kịch bản: TC-03-025 CORS chỉ nguồn gốc liệt kê, không ký tự đại diện
    # Truy vết: FR-03-010 · API-03-050, 051 · UI-03-03 · ERR-03-005, 022 · BR-03-012 · SEC-44.
    Biết U-T68-TA; U-T68-VW.
    Khi `PUT /cors-policies/r-ho-tich` với `allowedOrigins = ["https://console.t68.sim.test"]`.
    Và gửi `OPTIONS` có `Origin` đúng, rồi `Origin: https://evil.test`.
    Và `PUT` với `allowedOrigins = ["*"]`.
    Và U-T68-VW `PUT` chính sách.
    Thì bước 2: nguồn đúng nhận `Access-Control-Allow-Origin` khớp đúng nguồn đó; nguồn lạ không có tiêu đề CORS. Bước 3 `422` ERR-03-005 (`findings[]` nêu ký tự đại diện). Bước 4 403-PQ.

  @TC-03-026 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-03-026 Tiêu đề bảo mật và che thông tin máy chủ
    # Truy vết: FR-03-011 · API-03-086, 087 · UI-03-16 · ERR-03-129 · BR-03-013, 023 · NFR-03-015 · SEC-12, 43, 44.
    Biết `r-ho-tich`; `SIM-BE-BAD` có tiêu đề `Server: nginx/1.25`, `X-Powered-By: PHP/8`; U-T68-TA.
    Khi gọi thành công, gọi lỗi `404`, `429`, `502` qua gateway.
    Và chạy ZAP quét tiêu đề.
    Và gây lỗi nội bộ gateway (plugin ném ngoại lệ có chủ đích trong môi trường thử).
    Và `PUT /settings` thử tắt tiêu đề bảo mật.
    Thì mọi phản hồi có `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy` (ở đường dẫn giao diện), không có `Server` hay `X-Powered-By` lộ phiên bản (0 tiêu đề lộ). Bước 3 `500` Lỗi GW 129 không có vết ngăn xếp, tên máy, đường dẫn nội bộ; có `X-Trace-Id`. Bước 4 `400` ERR-03-003 (tham số không đổi được).
