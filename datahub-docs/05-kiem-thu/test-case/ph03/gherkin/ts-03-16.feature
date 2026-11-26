# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-16
Tính năng: TS-03-16 · Tổng hợp, kiểm tra hợp lệ và ký ảnh chụp cấu hình

  @TC-03-068 @P1 @Dương
  Kịch bản: TC-03-068 Tổng hợp, ký ảnh chụp; phiên bản tăng đơn điệu
    # Truy vết: FR-03-039, 041 · API-03-059, 056, 057 · UI-03-10 · UC-03-19 · BR-03-016, 018 · SEC-36, 65 · LGC-APIM-011…015.
    Biết U-T68-TA; danh mục T68 có 20 route, 10 consumer; OpenBao khóa ký.
    Khi `POST /snapshots:build` kèm `Idempotency-Key`.
    Và `GET /snapshots/{version}`; `GET /snapshots`.
    Và build lần hai không đổi nội dung; build sau khi đổi một route.
    Và kiểm chữ ký bằng khóa công khai.
    Thì bước 1 `201`, `version` = bản trước + 1, có `contentHash`, `signatureKeyId`, `builtFromCatalogRevision`. Bước 2 `200`, đủ route, consumer, chính sách; không có bí mật hay khóa riêng. Bước 3 lần hai `200` với nội dung giống (không tăng phiên bản vô ích) hoặc phiên bản mới nhưng không giảm; số phiên bản không bao giờ giảm. Bước 4 chữ ký hợp lệ. KT: có (`SNAPSHOT_BUILD`).

  @TC-03-069 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-069 Kiểm tra tĩnh chặn cấu hình sai: lược đồ, plugin ngoài danh mục, trùng host
    # Truy vết: FR-03-040 · API-03-058, 059 · UI-03-10 · ERR-03-005, 011, 012, 013, 016, 018 · EVT-03-12 · BR-03-014, 017, 026 · SEC-24, 26, 43, 65.
    Biết U-T68-TA; `r-no-schema`; `tpl-lua-custom` ngoài danh mục; hai route cùng host và đường dẫn của hai tenant (cố ý); route EXT chưa đủ điều kiện; chứng thư `F-CERT-WRONG-HOST`; hạn mức vượt trần.
    Khi `POST /snapshots:validate` với danh mục chứa lỗi lần lượt từng loại.
    Và `POST /snapshots:build` khi còn lỗi.
    Thì bước 1 `200` với `findings[]` đủ `checkId`, `severity`, `objectType`, `objectCode`. Bước 2 `422` ERR-03-005 "Cấu hình gateway không hợp lệ: {n} lỗi."; từng loại lỗi có mã tương ứng (thiếu lược đồ hoặc OPA: 012; plugin ngoài danh mục: 013; EXT chưa đủ điều kiện: 011; chứng thư: 016; vượt trần: 018); không có ảnh chụp nào được tạo; EVT: `snapshot.rejected` kèm danh sách lỗi.

  @TC-03-070 @P2 @Âm @Chịu @lỗi
  Kịch bản: TC-03-070 Đang có tổng hợp khác; dịch vụ ký không khả dụng
    # Truy vết: FR-03-039, 041 · API-03-059, 058 · UI-03-10 · ERR-03-006, 015, 022, 003 · BR-03-016 · SEC-36.
    Biết U-T68-TA, U-T68-TA2; U-T68-VW.
    Khi TA và TA2 gọi đồng thời `POST /snapshots:build`.
    Và ngắt OpenBao; `POST /snapshots:build`.
    Và U-T68-VW `POST /snapshots:build` và `:validate`.
    Và gửi `:build` với trường lạ.
    Thì bước 1 một `201`, một `409` ERR-03-006 "Đang có một lần tổng hợp hoặc phát cấu hình cho tỉnh này. Chờ lần đó hoàn tất." kèm `retryAfterSeconds`. Bước 2 `503` ERR-03-015, cấu hình đang chạy không đổi. Bước 3 403-PQ. Bước 4 `400` ERR-03-003.

  @TC-03-071 @P2 @Dương @Bảo @mật
  Kịch bản: TC-03-071 Xem và so sánh ảnh chụp; cách ly tenant
    # Truy vết: FR-03-039, 044 · API-03-056, 057, 062 · UI-03-10 · ERR-03-001 · BR-03-028.
    Biết T68 có ảnh chụp 41, 42; T01 có ảnh chụp 7; U-T68-VW.
    Khi `GET /snapshots`; `GET /snapshots/42`.
    Và `GET /snapshots/42/diff` so với bản đang chạy.
    Và `GET /snapshots/7`; `GET /snapshots/9999`.
    Thì bước 1 chỉ có ảnh chụp của T68. Bước 2 diff nêu route, consumer thêm, bớt, sửa, không có bí mật. Bước 3 hai lần 404-ẩn giống nhau trừ `traceId`.
