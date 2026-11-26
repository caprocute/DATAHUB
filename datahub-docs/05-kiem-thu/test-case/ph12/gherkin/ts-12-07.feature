# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-07
Tính năng: TS-12-07 · Gán và gỡ vai trò cho người dùng

  @TC-12-030 @P1 @Dương
  Kịch bản: TC-12-030 Gán vai trò rồi gỡ, hiệu lực ≤ 60 giây
    # Truy vết: FR-12-012 · UC-12-09 · UI-12-06 · API-12-025, 026, 027 · BR-12-036 · LGC-IAM-002, LGC-BUS-032
    Biết U-T68-TA1; U-T68-VW.
    Khi `POST /role-assignments` gán `INTEGRATION_ENGINEER` cho VW; xác nhận quyền ghi dùng được sau khi có token mới.
    Và `DELETE /role-assignments/{id}`.
    Thì bước 1 `201`, nâng quyền có hiệu lực khi có token mới; bước 2 `204`, phiên bị thu, OPA từ chối ≤ 60 giây; KT: có (role.assign, role.revoke); SK: `role.changed`.

  @TC-12-031 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-031 Không tự gán vai trò, không gán vai trò nền tảng
    # Truy vết: FR-12-012 · BR-12-033, BR-12-031 · API-12-026 · ERR-12-013 · ERR-12-010
    Biết U-T68-TA1.
    Khi TA1 gán `TENANT_ADMIN` cho chính mình; rồi gỡ vai trò của chính mình.
    Và TA1 gán `PLATFORM_ADMIN` cho VW ở T68.
    Và gán vai trò phạm vi `DV-B` cho người thuộc `DV-A` không cấp dưới.
    Thì bước 1 `403` ERR-12-013; bước 2, 3 `422` ERR-12-010; không có thay đổi.
