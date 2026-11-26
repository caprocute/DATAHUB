# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-10
Tính năng: TS-03-10 · Hạn mức toàn tenant và ghi đè theo route

  @TC-03-047 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-047 Hạn mức toàn tenant và cách ly giữa các tenant
    # Truy vết: FR-03-023 · API-03-023 · UI-03-06 · ERR-03-118 · BR-03-005 · NFR-03-019 · SEC-86 · LGC-NFR-006.
    Biết T68 hạn mức 500 lượt/giây; T01 chạy tải nền 100 lượt/giây; nhiều client T68 (không client nào vượt hạn mức riêng).
    Khi T68 gửi 800 lượt/giây từ 40 client trong 60 giây.
    Và đo p95 và tỉ lệ lỗi của T01 trong cùng thời gian.
    Và `GET /tenant-limits`.
    Thì bước 1 tổng lượt thành công ≈ 500/giây, phần vượt `429` Lỗi GW 118 "Tỉnh của bạn đang dùng hết hạn mức chung. Chờ giây lát, thử lại." Bước 2 p95 của T01 tăng ≤ 10 %, 0 lỗi do T68. Bước 3 `200` có giá trị hiện hành và trần hợp đồng.

  @TC-03-048 @P1 @Dương @Âm
  Kịch bản: TC-03-048 Hạ hạn mức toàn tenant cần bốn mắt; tăng trong trần được ngay
    # Truy vết: FR-03-023 · API-03-024, 071, 072 · UI-03-06, 17 · ERR-03-008, 018, 004, 022 · EVT-03-11 · BR-03-019 · UC-03-25.
    Biết U-T68-TA, U-T68-TA2; trần hợp đồng 1.000; U-T68-TO.
    Khi TA `PUT /tenant-limits` `perSecond = 300` kèm `If-Match`.
    Và TA tự `:approve`.
    Và TA2 duyệt qua UI-03-17.
    Và TA `PUT /tenant-limits` `perSecond = 800`.
    Và `PUT` `perSecond = 1.200`.
    Và `PUT` với `If-Match` cũ.
    Và U-T68-TO `PUT`.
    Thì bước 1 `202`, hạn mức chưa đổi. Bước 2 `403` ERR-03-008. Bước 3 `200`, hạn mức mới hiệu lực ≤ 60 s, EVT: `limit.changed`. Bước 4 `200` ngay (tăng trong trần). Bước 5 `422` ERR-03-018 "Hạn mức phải nằm trong trần của tỉnh (1.000 lượt/giây)." Bước 6 `412` ERR-03-004. Bước 7 403-PQ.

  @TC-03-049 @P2 @Dương @Âm
  Kịch bản: TC-03-049 Ghi đè hạn mức theo route: tạo, sửa, xóa, thứ tự ưu tiên
    # Truy vết: FR-03-024 · API-03-025, 026, 027, 028 · UI-03-06 · ERR-03-018, 004, 003, 001, 022 · UC-03-25 · BR-03-005, 019 · LGC-APIM-012; 013.
    Biết U-T68-TA; `r-ho-tich`, C-HTTT1 hạn mức gói 20 lượt/giây.
    Khi `POST /rate-limit-overrides` `{routeCode: r-ho-tich, consumerCode: ht-ndxp, perSecond: 5}` với `Idempotency-Key`.
    Và gọi 10 lượt/giây tới `r-ho-tich` và 10 lượt/giây tới route khác.
    Và `PUT /rate-limit-overrides/{id}` `perSecond = 8` kèm `If-Match` cũ rồi đúng.
    Và `perSecond = 0` hoặc vượt trần.
    Và `DELETE /rate-limit-overrides/{id}`; `GET /rate-limit-overrides`.
    Và `DELETE` mã không tồn tại.
    Thì bước 1 `201`. Bước 2 route `r-ho-tich` chặn ở 5 lượt/giây (ghi đè thắng hạn mức gói), route khác vẫn theo 20. Bước 3 `412` ERR-03-004 rồi `200`. Bước 4 `422` ERR-03-018. Bước 5 `204`, hạn mức về 20 ≤ 60 s. Bước 6 404-ẩn. Thiếu `PERM-03-limit`: 403-PQ.
