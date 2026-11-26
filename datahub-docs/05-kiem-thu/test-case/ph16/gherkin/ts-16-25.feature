# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-25
Tính năng: TS-16-25 · Khai báo, sửa thành phần, phiên bản và phụ thuộc

  @TC-16-087 @P2 @Dương
  Kịch bản: TC-16-087 Khai báo thành phần, phiên bản và phụ thuộc
    # Truy vết: FR-16-045 · API-16-095, 098, 099, 097 · UI-16-15 · EVT-16-10
    Biết T90; U-T90-TO1.
    Khi `POST /arch/components` `{componentCode: cong-thanh-toan-ngoai, name: "Cổng thanh toán ngoài", componentType: HTTT, lifecycle: PLANNED, ownerOrgId: ORG-TC, dependsOn: [httt-hotich]}`
    Và `POST /arch/components/cong-thanh-toan-ngoai/versions` `{version: "1.0.0", releasedOn: 2026-11-20, specRef: "doc:tc-1"}`
    Và `PUT /arch/components/cong-thanh-toan-ngoai/dependencies` `{dependsOn: [{componentCode: httt-hotich}, {componentCode: topic-moi-1}]}`
    Và `PATCH /arch/components/cong-thanh-toan-ngoai` đổi `description`
    Thì bước 1 `201`, `origin = MANUAL`. Bước 2 `201`. Bước 3 `200`, `dependencies[]` hai phần tử `kind = MANUAL`. Bước 4 `200`. EVT: `arch-component.changed` mỗi lần đổi.

  @TC-16-088 @P1 @Âm
  Kịch bản: TC-16-088 Loại sai, mã trùng, phụ thuộc vòng, sửa trường do nguồn quản lý
    # Truy vết: FR-16-045, FR-16-044 · API-16-095, 097, 099 · ERR-16-039, ERR-16-002, ERR-16-041, ERR-16-040 · BR-16-023, BR-16-025
    Biết thành phần A phụ thuộc B, B phụ thuộc C; `thanh-phan-cu` `RETIRED`.
    Khi `POST /arch/components` với `componentType = "LOAI-LA"`
    Và `POST /arch/components` lại `componentCode = httt-hotich`
    Và `PUT …/dependencies` của C với `dependsOn = [A]` (tạo vòng)
    Và `PUT …/dependencies` với `dependsOn = [thanh-phan-cu]`
    Và `PATCH /arch/components/httt-moi-1` (`origin = AUTO`, từ PH-01) đổi `name`, rồi đổi `description`
    Thì bước 1 `422` ERR-16-039. Bước 2 `409` ERR-16-002. Bước 3, 4 `422` ERR-16-041. Bước 5 đổi `name` `409` ERR-16-040, đổi `description` `200`. Đồ thị phụ thuộc không đổi.

  @TC-16-089 @P1 @Dương @Âm
  Kịch bản: TC-16-089 Chuyển vòng đời; không xóa, không ngừng khi còn phụ thuộc hoạt động
    # Truy vết: FR-16-045 · API-16-100, 096 · ERR-16-042, ERR-16-006 · BR-16-025 · EVT-16-10
    Biết `httt-hotich` `ACTIVE` có 2 thành phần `ACTIVE` phụ thuộc; `tc-mo-coi-2` `ACTIVE` không ai phụ thuộc.
    Khi `POST …/httt-hotich:change-lifecycle` `{lifecycle: DEPRECATED}`
    Và `{lifecycle: RETIRED}` cho `httt-hotich`
    Và `{lifecycle: RETIRED}` cho `tc-mo-coi-2`
    Và `{lifecycle: PLANNED}` cho `tc-mo-coi-2` đã `RETIRED`
    Và `DELETE /arch/components/tc-mo-coi-2`
    Thì bước 1 `200`. Bước 2 `422` ERR-16-042. Bước 3 `200 RETIRED`. Bước 4 `422` ERR-16-042 (chuyển ngược không hợp lệ). Bước 5 `404` hoặc `405` (không có thao tác xóa; chỉ `RETIRED`). EVT: `arch-component.changed` ở bước 1, 3.
