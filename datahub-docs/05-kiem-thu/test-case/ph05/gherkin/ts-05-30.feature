# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-30
Tính năng: TS-05-30 · Tham số phân hệ và báo cáo sử dụng

  @TC-05-117 @P2 @Dương @Âm
  Kịch bản: TC-05-117 Bật, tắt loại kết nối; tắt khi còn dùng bị chặn
    # Truy vết: FR-05-061 · API-05-090, 091 · ERR-05-010, 004 · UC-05-26
    Biết U-T68-TA; loại `ldap` không dùng; `oauth2-client` đang dùng.
    Khi `PUT /settings/connection-types/ldap` `enabled = true`.
    Và `PUT /settings/connection-types/oauth2-client` `enabled = false`.
    Thì bước 1 `200`, tạo kết nối LDAP được. Bước 2 `409` ERR-05-010 với số kết nối đang dùng.

  @TC-05-118 @P2 @Biên
  Kịch bản: TC-05-118 Trần tham số tenant được áp
    # Truy vết: FR-05-061 · API-05-091, 011 · ERR-05-030
    Biết U-T68-TA đặt trần `timeoutMs = 30000` cho `oauth2-client`; U-T68-IE1.
    Thì `422` ERR-05-030 nêu trần.

  @TC-05-119 @P3 @Dương
  Kịch bản: TC-05-119 Báo cáo sử dụng kết nối và bộ điều hợp
    # Truy vết: FR-05-062 · API-05-092
    Biết U-T68-TA; dữ liệu 7 ngày của SIT.
    Thì số lượt gọi, lỗi, p95 theo HTTT khớp chỉ số Prometheus cùng khoảng (sai lệch ≤ 1 %); không có dữ liệu tenant khác.
