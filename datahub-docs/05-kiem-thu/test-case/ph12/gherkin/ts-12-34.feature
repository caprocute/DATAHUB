# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-34
Tính năng: TS-12-34 · Cách ly tenant và RLS

  @TC-12-107 @P1 @Bảo @mật
  Kịch bản: TC-12-107 Quét mọi API đọc: tenant khác trả 404-ẩn, danh sách không lẫn
    # Truy vết: BR-12-041, BR-12-004 · FR-12-001, 002, 030 · API-12-001, 002, 025, 032, 056, 057, 089, 090, 103, 104 · ERR-12-001
    Biết U-T01-TA; đối tượng cùng mã ở T01 và T68; U-T68-TA1.
    Khi với mỗi API đọc `GET` có `{id}`, gọi id của T68 bằng token T01.
    Và gọi danh sách của từng tài nguyên bằng cả hai token; thêm `X-Tenant`, tham số `tenant`.
    Thì mọi trường hợp chéo tenant `404` ERR-12-001 thân giống "không có" trừ `traceId`; danh sách chỉ có đối tượng của tenant token; tham số, tiêu đề tenant bị bỏ qua.

  @TC-12-108 @P1 @Bảo @mật
  Kịch bản: TC-12-108 Ghi chéo tenant và RLS ở CSDL
    # Truy vết: BR-12-003, BR-12-041 · NFR-12-023 · API-12-026, 058, 060, 062 · ERR-12-001 · SEC-80
    Biết U-T01-TA; pgTAP với vai trò ứng dụng.
    Khi bằng token T01 gán vai trò, `:suspend`, `:revoke` client của T68.
    Và pgTAP: đặt `app.tenant_id=T01`, `SELECT`, `UPDATE` bảng `ph12_iam.*` của T68; bỏ đặt biến tenant.
    Thì bước 1 trả 404-ẩn, dữ liệu T68 nguyên vẹn; bước 2 không thấy hàng nào, không ghi được; thiếu biến tenant thì 0 hàng.

  @TC-12-109 @P1 @Bảo @mật
  Kịch bản: TC-12-109 Token của tenant này không dùng được ở realm hay gói chính sách tenant khác
    # Truy vết: BR-12-003, BR-12-004 · FR-12-044, 058 · API-12-074, 086, 103 · ERR-12-116 · SEC-85
    Biết token T01; gói chính sách POL-T68-OK chỉ của T68.
    Khi dùng token T01 gọi API T68; thử đổi `iss` của token.
    Và gọi `decide` với token T01 nhưng tài nguyên T68; xem nhật ký quyết định của T68 bằng AU T01.
    Thì ERR-12-116 (401) hoặc 404-ẩn; quyết định `deny`; luật tenant T68 không ảnh hưởng quyết định của T01.
