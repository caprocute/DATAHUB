# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-20
Tính năng: TS-13-20 · Theo API và theo HTTT

  @TC-13-060 @P1 @Dương
  Kịch bản: TC-13-060 Chủ dịch vụ xem chỉ số API của tổ chức mình
    # Truy vết: FR-13-035 · UC-13-22 · API-13-009, 010 · UI-13-03
    Biết F-ACCESS-5M; U-T68-SV thuộc `ORG-SO-TTTT`.
    Khi mở UI-13-03; lọc theo API; mở HTTT.
    Thì chỉ API của tổ chức `ORG-SO-TTTT`; số lượt, tỷ lệ lỗi, độ trễ p95 khớp F-ACCESS-5M.

  @TC-13-061 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-061 Chủ dịch vụ không xem được HTTT, API tổ chức khác
    # Truy vết: FR-13-035 · API-13-010 · ERR-13-001, 009 · BR-13-030
    Biết U-T68-SV; HTTT của tổ chức khác; HTTT của T01.
    Khi gọi `GET /systems/{systemCode}/stats` của tổ chức khác, rồi của T01.
    Thì 404-ẩn cho cả hai; thân giống hệt trừ `traceId`.
