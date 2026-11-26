# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-41
Tính năng: TS-09-41 · Truy cập giao diện và hợp đồng API

  @TC-09-145 @P2 @Truy @cập
  Kịch bản: TC-09-145 Truy cập 22 màn hình, trạng thái rỗng, lỗi và hộp thoại xem đầy đủ
    # Truy vết: UI-09-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 · NFR-09-023
    # Mục đích: Chứng minh WCAG 2.1 AA, route đúng, tab con và query giữ được khi quay lại.
    Biết STAGING; Playwright, axe-core; U-T90-SO, DO1, TA, AU, VW.
    Khi duyệt từng route `/du-lieu/quyen-rieng-tu/...` bằng vai phù hợp; chạy axe; thao tác chỉ bằng bàn phím.
    Và mở UI-09-22 từ màn PH-06: nhập lý do, quan sát đếm ngược.
    Thì 0 lỗi axe mức nghiêm trọng; vai không phù hợp thấy 403 đúng; UI-09-22 đặt tiêu điểm vào ô lý do, thông báo đếm ngược cho trình đọc màn hình và tự che ở giây 60.

  @TC-09-146 @P2 @Dương
  Kịch bản: TC-09-146 OpenAPI `/api/privacy/v1` và `/privacy/v1` khớp FRS 9.4
    # Truy vết: FR-09-064 · API-09-001, 227 · NFR-09-020
    # Mục đích: Chứng minh 237 API, mã lỗi và enum đúng nguồn chuẩn (FRS Phụ lục A).
    Biết `03-thiet-ke/api/ph09/openapi-privacy.yaml`; Spectral, oasdiff.
    Khi chạy Spectral; so mã API và đường dẫn với bảng FRS 9.4; so enum với Phụ lục A.
    Thì 0 lệch mã, đường dẫn, phương thức; mọi POST ghi có `Idempotency-Key`; mọi lỗi theo RFC 9457 có `code`, `traceId`.
