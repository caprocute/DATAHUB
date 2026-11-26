# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-18
Tính năng: TS-13-18 · Bảng giám sát tổng quan và sức khỏe thành phần

  @TC-13-056 @P1 @Dương
  Kịch bản: TC-13-056 Tổng quan nền tảng hiện số liệu và trạng thái các thành phần
    # Truy vết: FR-13-031 · UC-13-20 · API-13-001, 002 · UI-13-01 · NFR-13-004 · LGC-BUS-014 · LGC-APIM-026
    Biết SIT đủ thành phần; U-T68-VW.
    Khi mở UI-13-01; `GET /overview`, `GET /components`.
    Thì tải ≤ 3 giây (12 panel, 50 người xem); số liệu tenant T68; U-T68-VW xem được; chỉ số thiếu dữ liệu hiển thị "Chưa có dữ liệu" không phải 0 (BR-13-016); trạng thái truyền đạt cả bằng chữ lẫn màu.

  @TC-13-057 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-057 Người không quyền, sức khỏe cho phân hệ khác theo scope
    # Truy vết: FR-13-031, 058 · API-13-001, 002 · ERR-13-009, 010, 044 · BR-13-030
    Biết U-T68-NONE; S-PH18; token máy không scope.
    Khi U-T68-NONE gọi `GET /overview`; gọi không token.
    Và S-PH18 gọi `GET /components`; token không scope gọi.
    Thì 403-PQ; `401` ERR-13-010; S-PH18 `200`; thiếu scope `403` ERR-13-044.
