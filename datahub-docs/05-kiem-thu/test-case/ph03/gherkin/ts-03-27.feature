# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-27
Tính năng: TS-03-27 · Cách ly tenant ở API, CSDL, bộ đếm và cấu hình

  @TC-03-108 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-108 Rò rỉ chéo tenant cho mọi API đọc: 404-ẩn
    # Truy vết: FR-03-028, 046, 051 · API-03-002, 006, 012, 016, 022, 057, 064, 066, 069, 075, 082 · ERR-03-001 · BR-03-026, 028 · NFR-03-019 · SEC-87.
    Biết đối tượng chỉ có ở T01 cho mỗi loại (route, upstream, consumer, chính sách, ảnh chụp, nút, mẫu, chứng thư, nhật ký, kiểm tra tổng hợp, cảnh báo, chuyển tiếp, ghi đè hạn mức); U-T68-TA, U-T68-AU.
    Khi với từng API đọc theo mã (`GET …/{mã}`), U-T68-TA gọi bằng mã đối tượng của T01.
    Và gọi bằng mã không tồn tại.
    Và với từng API danh sách, tìm theo mã của T01.
    Và lặp bước 1 cho `PUT`, `DELETE`, `POST …:{động từ}` có mã trong đường dẫn.
    Thì bước 1 và 2 cùng `404` ERR-03-001, thân giống hệt trừ `traceId`, thời gian phản hồi khác nhau không quá 20 %. Bước 3 danh sách không chứa đối tượng T01, tổng số không lộ. Bước 4 cũng 404-ẩn và không đổi dữ liệu của T01.

  @TC-03-109 @P1 @Bảo @mật
  Kịch bản: TC-03-109 RLS chặn đọc, ghi chéo tenant ở CSDL
    # Truy vết: BR-03-026, 028 · NFR-03-019 · SEC-80, 87 · ADR-003.
    Biết vai trò ứng dụng với `SET app.tenant_id = 'T68'`; bản ghi `T01` ở mọi bảng `ph03_gateway.*`.
    Khi `SELECT` không điều kiện từ từng bảng.
    Và `INSERT`, `UPDATE`, `DELETE` bản ghi có `tenant_id = 'T01'`.
    Và không đặt `app.tenant_id` rồi `SELECT`.
    Và thử sửa, xóa bảng nhật ký kiểm toán và bảng ảnh chụp đã phát.
    Thì bước 1 chỉ thấy dòng T68. Bước 2 vi phạm chính sách RLS (0 dòng bị đổi hoặc lỗi). Bước 3 0 dòng. Bước 4 bị chặn (append-only).

  @TC-03-110 @P1 @Bảo @mật
  Kịch bản: TC-03-110 Bộ đếm hạn mức, danh sách chặn, khóa bộ đệm tách theo tenant
    # Truy vết: FR-03-021, 018, 013 · API-03-029, 054 · ERR-03-116, 105 · BR-03-005, 026 · NFR-03-019 · SEC-86.
    Biết hai client trùng `clientId` `ht-ndxp` ở T68 và T01; thu hồi `jti` giống nhau ở T01.
    Khi làm client T01 hết hạn mức; gọi bằng client T68.
    Và thu hồi một `jti` ở T01; gọi bằng token T68 có `jti` trùng.
    Và kiểm khóa Valkey.
    Thì bước 1, 2 client T68 không bị ảnh hưởng. Bước 3 mọi khóa có tiền tố tenant; không khóa nào dùng chung hai tenant.

  @TC-03-111 @P1 @Bảo @mật
  Kịch bản: TC-03-111 Ảnh chụp cấu hình của tenant không chứa đối tượng tenant khác
    # Truy vết: FR-03-039, 041 · API-03-057 · BR-03-026 · NFR-03-019 · SEC-87.
    Biết T68, T01 đều có route, consumer; ảnh chụp dùng chung cho cụm gateway.
    Khi build ảnh chụp ở T68; giải nén phần nội dung.
    Và kiểm từng route, consumer, chính sách có `tenant` đúng.
    Và kiểm không có hai route cùng host, đường dẫn khác tenant.
    Thì mọi đối tượng thuộc đúng tenant ghi trên đối tượng; không có khóa của tenant này trong phạm vi tenant khác; bản kiểm tĩnh BR-03-026 báo 0 xung đột.
