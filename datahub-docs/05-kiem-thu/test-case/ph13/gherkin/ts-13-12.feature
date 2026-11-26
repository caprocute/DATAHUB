# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-12
Tính năng: TS-13-12 · Lịch sử theo đối tượng cho tab "Lịch sử"

  @TC-13-042 @P1 @Dương
  Kịch bản: TC-13-042 Lấy lịch sử của một đối tượng
    # Truy vết: FR-13-022 · UC-13-13 · API-13-076 · UI-13-13
    Biết F-AUD-1K có 12 bản ghi cho `object = CATALOG/DM_GIOI_TINH`; S-HIST.
    Khi `GET /objects/CATALOG/DM_GIOI_TINH/history`.
    Thì `200`, 12 mục theo thời gian giảm dần, đã che; không có bản ghi của đối tượng cùng mã ở T01.

  @TC-13-043 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-043 Scope thiếu hoặc đối tượng tenant khác
    # Truy vết: FR-13-022 · API-13-076 · ERR-13-044, 001, 036 · BR-13-017
    Biết token máy không có `audit:history-read`; S-HIST của T01 gọi đối tượng T68.
    Khi gọi bằng token thiếu scope.
    Và S-HIST của T01 gọi lịch sử đối tượng của T68.
    Thì bước 1 `403` ERR-13-044 (không nêu scope thiếu); bước 2 404-ẩn hoặc `403` ERR-13-036, không rò số bản ghi.
