# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-35
Tính năng: TS-01-35 · Hợp đồng API, máy trạng thái, nhận lặp và đồng thời

  @TC-01-139 @P1 @Dương
  Kịch bản: TC-01-139 Kiểm tra hợp đồng 88 operation
    # Truy vết: NFR-01-019 · API-01-001, 002, 087, 088 · ERR-01-052.
    Biết openAPI `/api/onboarding/v1`; Apicurio chế độ BACKWARD.
    Khi chạy Schemathesis trên toàn bộ operation; so OpenAPI với bản phát hành trước; kiểm lược đồ sự kiện.
    Thì mọi phản hồi khớp lược đồ; lỗi theo RFC 9457 có `type`, `title`, `status`, `traceId`; chỉ thêm trường tùy chọn; sự kiện tương thích BACKWARD (CI-5).

  @TC-01-140 @P1 @Âm
  Kịch bản: TC-01-140 Ma trận chuyển trạng thái cấm
    # Truy vết: BR-01-031 · FR-01-009, 012, 018, 024, 029, 030, 031 · ERR-01-005, 020, 030.
    Biết một HTTT ở mỗi trạng thái DRAFT, SUBMITTED, APPROVED, ACTIVE, SUSPENDED, TERMINATED, REJECTED; đủ quyền.
    Khi từ mỗi trạng thái, gọi mọi hành động (`:submit`, `:withdraw`, `:approve`, `:reject`, `:activate`, `:suspend`, `:resume`, `:terminate`, xóa) không nằm ở bảng chuyển hợp lệ (mục 3.2).
    Thì `409` ERR-01-005 (hoặc ERR-01-020, ERR-01-030 với bước, định danh); trạng thái không đổi, không sự kiện, không kiểm toán nghiệp vụ.

  @TC-01-141 @P2 @Âm @Biên
  Kịch bản: TC-01-141 Nhận lặp, không xác thực, đua quyết định
    # Truy vết: BR-01-031 · API-01-023, 032, 044 · ERR-01-007, 051, 052, 054 · EVT-01-03.
    Biết `HT-HOTICH-OK`; `HT-HOTICH-SB`; TA1, TA2.
    Khi gọi các API có `Idempotency-Key` (mọi API ghi có đánh dấu "có" ở bảng API) hai lần cùng khóa cùng thân; một lần khác thân; hai lần song song.
    Và gọi không token, token hết hạn.
    Và TA1 và TA2 đồng thời `:approve` cùng HTTT; hai lần `:activate` đồng thời.
    Thì cùng thân: cùng kết quả; khác thân `409` ERR-01-051; song song `409` ERR-01-054. Bước 2: `401` ERR-01-052. Bước 3: đúng một thành công, còn lại `409` ERR-01-005 hoặc `412` ERR-01-007; đúng một `EVT-01-03`.
