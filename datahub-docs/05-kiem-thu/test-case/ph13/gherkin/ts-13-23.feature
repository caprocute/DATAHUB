# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-23
Tính năng: TS-13-23 · Quản lý bộ dashboard theo tenant

  @TC-13-066 @P2 @Dương
  Kịch bản: TC-13-066 Đồng bộ bộ dashboard chuẩn sang Grafana của tenant
    # Truy vết: FR-13-041 · UC-13-25 · API-13-017, 018 · UI-13-17 · BR-13-032
    Biết U-T68-TA.
    Khi `GET /dashboard-sets`; `POST /dashboard-sets/{setCode}:sync`.
    Thì `202`; Grafana của T68 có bộ chuẩn; KT: có (`OBS.DASHBOARD.SYNC`); không ảnh hưởng Grafana của T01.

  @TC-13-067 @P2 @Âm
  Kịch bản: TC-13-067 Bộ dashboard không hợp lệ hoặc không quyền
    # Truy vết: FR-13-041 · API-13-018 · ERR-13-035, 009, 016
    Biết bộ lỗi `bo-hong`; U-T68-TO; T68 tạm ngừng ở ca phụ.
    Khi đồng bộ `bo-hong`; U-T68-TO đồng bộ; tenant tạm ngừng đồng bộ.
    Thì `422` ERR-13-035; 403-PQ; `423` ERR-13-016 (chỉ đọc).
