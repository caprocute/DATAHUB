# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-36
Tính năng: TS-13-36 · Cách ly tenant

  @TC-13-099 @P1 @Bảo @mật
  Kịch bản: TC-13-099 Bộ kiểm thử rò rỉ trên mọi API đọc
    # Truy vết: NFR-13-022 · BR-13-017, 030 · FR-13-020, 022, 026, 028, 030, 035 · ERR-13-001, 036 · API-13-004, 006, 010, 012, 019, 023, 025, 026, 031, 037, 057, 066, 075, 079, 081, 083
    Biết dữ liệu trùng mã T01 và T68; U-T68-AU, U-T68-TO, U-T01-AU, U-T01-TO.
    Khi với mỗi API đọc theo mã, gọi bằng token T68 các mã chỉ có ở T01.
    Và thử `targetTenant`, đổi `tenant` trong thân, thử tiêu đề `X-Tenant`.
    Thì 404-ẩn hoặc `403` ERR-13-036; bước 2 không đổi được tenant; tenant luôn lấy từ token.

  @TC-13-100 @P1 @Bảo @mật
  Kịch bản: TC-13-100 Cách ly ở kho: Mimir, Loki, Tempo, ClickHouse, Grafana, PostgreSQL, WORM
    # Truy vết: NFR-13-022 · BR-13-017 · FR-13-009, 011, 013
    Biết `ph13_isolation_test.sql`; chứng thư T68; bucket WORM của T01.
    Khi phiên PostgreSQL đặt `app.tenant = t68` đọc `audit_event` của t01.
    Và gọi Grafana của T68 tới nguồn dữ liệu T01; đọc bucket WORM của T01 bằng khóa T68.
    Thì RLS trả 0 dòng; Grafana, WORM từ chối; ClickHouse, Loki, Mimir, Tempo không trả dữ liệu T01.
