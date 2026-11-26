# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-13
Tính năng: TS-03-13 · Cân bằng tải, kiểm tra sức khỏe, ngắt mạch, thời hạn chờ

  @TC-03-057 @P1 @Dương
  Kịch bản: TC-03-057 Cân bằng tải giữa các backend và xem upstream
    # Truy vết: FR-03-029 · API-03-005, 006 · UI-03-03 · UC-03-06 · BR-03-011 · LGC-APIM-018.
    Biết `up-ho-tich` gồm `SIM-BE-1…3` trọng số 1:1:2; U-T68-VW.
    Khi gửi 4.000 lượt tới `r-ho-tich`, đếm theo backend.
    Và `GET /upstreams`; `GET /upstreams/up-ho-tich`.
    Và `GET /upstreams/up-chi-t01`.
    Thì bước 1 tỉ lệ ≈ 1:1:2 (sai số ≤ 5 %). Bước 2 `200`, mỗi backend có `healthy`, trọng số, số lỗi. Bước 3 404-ẩn.

  @TC-03-058 @P1 @Dương @Âm @Chịu
  Kịch bản: TC-03-058 Loại backend hỏng khỏi vòng quay và đưa lại khi hồi phục
    # Truy vết: FR-03-030, 029 · API-03-006 · UI-03-03 · ERR-03-122 · BR-03-011 · NFR-03-001 · LGC-APIM-018; LGC-NFR-006.
    Biết `SIM-BE-2` trả `500` ở `/healthz`; tải 50 lượt/giây.
    Khi làm `SIM-BE-2` trả lỗi; theo dõi lượt gọi và `GET /upstreams/up-ho-tich`.
    Và cho `SIM-BE-2` trả lỗi ở đường dẫn nghiệp vụ nhưng `/healthz` vẫn `200`.
    Và phục hồi `SIM-BE-2`.
    Thì bước 1 backend bị loại ≤ 15 s (kiểm tra chủ động mỗi 5 giây, 3 lần liên tiếp), tỉ lệ lỗi của khách < 1 %. Bước 2 kiểm tra thụ động loại backend sau chuỗi lỗi. Bước 3 backend được đưa lại sau ≤ 30 s; có cảnh báo `backend-unhealthy` rồi tự đóng.

  @TC-03-059 @P1 @Dương @Âm @Chịu
  Kịch bản: TC-03-059 Mọi backend hỏng: trả 503 nhanh, thăm dò định kỳ
    # Truy vết: FR-03-031, 030 · API-03-010 · UI-03-03 · ERR-03-120 · BR-03-011, 023 · LGC-NFR-006.
    Biết cả ba `SIM-BE` trả `503`; tải 100 lượt/giây.
    Khi làm mọi backend lỗi; gọi liên tục 60 giây.
    Và đếm lượt thực sự tới backend trong thời gian mạch mở.
    Và phục hồi một backend.
    Thì bước 1 sau khi mạch mở, lượt gọi nhận `503` Lỗi GW 120 trong ≤ 50 ms kèm `Retry-After` "Dịch vụ tạm thời không có máy chủ khỏe. Thử lại sau {n} giây." Bước 2 chỉ vài lượt thăm dò mỗi chu kỳ, không dồn tải vào backend hỏng. Bước 3 mạch đóng sau thăm dò thành công, lượt gọi `200`.

  @TC-03-060 @P1 @Âm
  Kịch bản: TC-03-060 Thời hạn chờ và backend trả hỏng: 504 và 502
    # Truy vết: FR-03-031 · API-03-010 · UI-03-03 · ERR-03-121, 122, 018, 003, 001, 022 · BR-03-011, 023.
    Biết U-T68-TA; route `r-slow` tới `SIM-BE-SLOW` (chờ 40 giây), thời hạn chờ 30 giây; route `r-bad` tới `SIM-BE-BAD`.
    Khi gọi `r-slow`.
    Và gọi `r-bad`.
    Và `PUT /routes/r-slow/timeouts` với `readSeconds = 10`; gọi lại.
    Và `PUT` với `readSeconds = 0`, rồi vượt trần nền tảng; `PUT` cho route không tồn tại; U-T68-VW `PUT`.
    Thì bước 1 `504` Lỗi GW 121 "Dịch vụ phản hồi quá chậm. Thử lại; báo vận hành nếu lặp lại." Bước 2 `502` Lỗi GW 122 kèm `traceId`, không lộ nội dung phản hồi hỏng. Bước 3 `200`, sau hiệu lực lượt gọi hết hạn ở 10 giây. Bước 4 `422` ERR-03-018, `400` ERR-03-003, 404-ẩn, 403-PQ.
