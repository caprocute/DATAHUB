# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-04
Tính năng: TS-15-04 · Tìm kiếm toàn văn tiếng Việt và gợi ý

  @TC-15-022 @P1 @Dương
  Kịch bản: TC-15-022 Tìm không phân biệt dấu và hoa thường
    # Truy vết: FR-15-005 · UC-15-02 · API-15-011 · UI-15-03 · BR-15-002 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-OR; F-CAT (mô tả của `tra-cuu-ho-tich` chứa "hộ tịch", "Đăng ký khai sinh").
    Khi `GET /search?q=hộ tịch`, `q=ho tich`, `q=HỘ TỊCH`, `q=dang ky khai sinh`.
    Thì bốn lần cùng kết quả đầu là `tra-cuu-ho-tich` và trang hướng dẫn liên quan, có đoạn nổi bật; phân trang đúng; UI-15-03 hiện số kết quả.

  @TC-15-023 @P2 @Dương
  Kịch bản: TC-15-023 Gợi ý khi gõ
    # Truy vết: FR-15-005 · UC-15-02 · API-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; F-CAT.
    Khi `GET /search/suggest?q=tra c`.
    Thì tối đa 8 gợi ý bắt đầu bằng "Tra cứu"; không có `tra-cuu-dat-dai` (ngoài tầm của nhà phát triển); p95 ≤ 200 ms (đo ở TC-15-189).

  @TC-15-024 @P1 @Âm
  Kịch bản: TC-15-024 Tìm kiếm không lộ mục ngoài tầm, kể cả ẩn danh
    # Truy vết: FR-15-005, 008 · UC-15-02 · API-15-010, 011 · BR-15-002, 005 · ERR-15-001 · LGC-APIM-007.
    Biết U-T68-DEV-AN, U-ANON (công khai bật); trang `huong-dan-noi-bo` `audience = TENANT`; `an-khoi-cong`; `tra-cuu-dat-dai`.
    Khi an tìm `q=đất đai`, `q=an-khoi-cong`, `q=huong-dan-noi-bo`.
    Và khách tìm `q=hộ tịch`.
    Thì bước 1 không có kết quả; `total` không đếm mục bị ẩn (không dò được bằng số đếm); bước 2 chỉ mục `PUBLIC` và trang `PUBLIC`.

  @TC-15-025 @P2 @Dương
  Kịch bản: TC-15-025 Dự phòng PostgreSQL FTS khi OpenSearch hỏng
    # Truy vết: FR-15-005 · UC-15-02 · API-15-011 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.search.engine = OPENSEARCH`; ngắt OpenSearch; F-CAT.
    Khi `GET /search?q=ho tich`.
    Và đặt `15.search.engine = PG_FTS`, lặp lại.
    Thì cả hai lần vẫn có `tra-cuu-ho-tich` (unaccent), không `5xx`; không lộ mục ngoài tầm; cảnh báo vận hành được ghi.

  @TC-15-026 @P2 @Âm
  Kịch bản: TC-15-026 Từ khóa rỗng hoặc quá dài; lạm dụng
    # Truy vết: FR-15-005 · API-15-011, 012 · ERR-15-003, 007 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN.
    Khi `q=` rỗng; `q` 201 ký tự.
    Và 40 lần `GET /search/suggest` trong 10 giây.
    Thì bước 1 `400` ERR-15-003 "Từ khóa cần từ 1 đến 200 ký tự"; bước 2 sau ngưỡng `429` ERR-15-007 kèm `Retry-After`.
