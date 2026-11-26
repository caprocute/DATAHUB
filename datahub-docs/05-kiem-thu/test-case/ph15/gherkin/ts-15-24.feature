# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-24
Tính năng: TS-15-24 · Bảng điều khiển, thống kê và nhật ký ứng dụng

  @TC-15-143 @P2 @Dương
  Kịch bản: TC-15-143 Tổng quan cá nhân chịu lỗi từng thẻ
    # Truy vết: FR-15-048 · UC-15-26 · API-15-097, 140 · UI-15-18 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; ngắt PH-13.
    Khi `GET /dashboard`; mở UI-15-18.
    Thì thẻ ứng dụng, credential sắp hết hạn, đăng ký, phiếu bình thường; thẻ số liệu hiện "Chưa tải được."; `GET /inbox/unread-count` (API-15-140) khớp huy hiệu.

  @TC-15-144 @P1 @Dương
  Kịch bản: TC-15-144 Thống kê theo ứng dụng khớp số lượt gọi
    # Truy vết: FR-15-049 · UC-15-26 · API-15-098 · UI-15-12 · BR-15-009 · LGC-APIM-022.
    Biết ứng dụng gọi sandbox 100 lượt: 80 thành công, 15 lỗi 4xx, 5 lỗi 5xx.
    Khi `GET /apps/app-tra-cuu-ho-tich/stats?khoang=1d`.
    Thì tổng, lỗi theo mã, độ trễ p50, p95, theo API khớp đúng; đọc từ PH-13 (`metrics:portal-read`).

  @TC-15-145 @P1 @Âm
  Kịch bản: TC-15-145 Không thành viên, PH-13 lỗi
    # Truy vết: FR-15-049 · API-15-098 · ERR-15-005, 039 · NFR-15-017 · LGC-APIM-022.
    Biết U-T68-DEV-CU; ngắt PH-13; ứng dụng cùng mã ở T01.
    Khi cự `GET .../stats`.
    Và an `GET .../stats` khi PH-13 ngắt.
    Thì `403` ERR-15-005; `502` ERR-15-039 "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."

  @TC-15-146 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-146 Nhật ký gọi che dữ liệu
    # Truy vết: FR-15-050 · UC-15-26 · API-15-099, 100 · UI-15-12 · ERR-15-001 · BR-15-024 · LGC-APIM-022.
    Biết ứng dụng của An và ứng dụng của Bi; lời gọi có `Authorization`, thân chứa CCCD, số điện thoại, DH-CANARY.
    Khi `GET /apps/{của An}/logs`; `/logs/{logId}`.
    Và an gọi `logId` thuộc ứng dụng của Bi.
    Thì chỉ nhật ký ứng dụng của An; `Authorization` và trường PII che theo SEC-32; canary 0; bước 2 `404` ERR-15-001.
