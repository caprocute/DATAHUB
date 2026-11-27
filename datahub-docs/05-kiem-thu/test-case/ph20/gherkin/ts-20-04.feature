# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-04
Tính năng: TS-20-04 · Quản lý mẫu khởi tạo có phiên bản

  @TC-20-019 @P2 @Dương
  Kịch bản: TC-20-019 Tạo mẫu, mở phiên bản mới, sửa, so sánh, phát hành, ngừng phiên bản
    # Truy vết: FR-20-015 · UC-20-04 · API-20-025, 026, 027, 028, 029, 030, 031, 032 · BR-20-042 · UI-20-21 · `PERM-20-admin`
    Biết `U-PA1`; mẫu `tinh-chuan` v3 `PUBLISHED`.
    Khi `GET P/provisioning-templates?state=PUBLISHED`
    Và `POST P/provisioning-templates` mã `mau-thu-90` với `modules`, `quotaByScale` bốn quy mô, `rdmPackageVersion`, `orgSeed`, `activation = AUTO`, `releaseChannel = STABLE`
    Và `GET P/provisioning-templates/mau-thu-90`
    Và `POST P/provisioning-templates/tinh-chuan/versions` với `fromVersion = 3`, `changeNote`
    Và `PATCH P/provisioning-templates/tinh-chuan/versions/4` đổi `kpiSetVersion`, kèm `If-Match`
    Và `GET P/provisioning-templates/tinh-chuan/versions/4?compareTo=3`
    Và `POST .../versions/4:publish`
    Và `POST .../versions/3:retire` với `reason`
    Thì bước 2 `201`, phiên bản 1 `DRAFT`. Bước 4 `201` phiên bản 4 `DRAFT` sao từ 3. Bước 5 `200`. Bước 6 trả bảng so sánh chỉ khác `kpiSetVersion`. Bước 7 `200`, phiên bản 4 `PUBLISHED`, bất biến. Bước 8 phiên bản 3 `RETIRED`, các lần chạy cũ vẫn giữ `templateVersion = 3`. KT mọi thao tác ghi.

  @TC-20-020 @P1 @Âm
  Kịch bản: TC-20-020 Mẫu trùng mã, thiếu phân hệ lõi, hạn mức quá trần, sửa bản đã phát hành
    # Truy vết: FR-20-015 · API-20-026, 028, 030, 031, 032 · BR-20-042 · ERR-20-003, ERR-20-006, ERR-20-029, ERR-20-033, ERR-20-063, ERR-00-428
    Biết `U-PA1`; mẫu `tinh-chuan` v3 `PUBLISHED`, v4 `DRAFT`.
    Khi `POST P/provisioning-templates` mã `tinh-chuan`
    Và `POST P/provisioning-templates` với `modules` thiếu PH-12 (phân hệ lõi)
    Và `PATCH .../tinh-chuan/versions/4` đặt `quotaByScale` `API_RPS` vượt trần nền tảng
    Và `PATCH .../tinh-chuan/versions/3` (đã `PUBLISHED`)
    Và `POST .../versions/3:publish` lần hai
    Và `PATCH .../versions/4` không có `If-Match`
    Thì bước 1 `409` `ERR-20-003`. Bước 2 `422` `ERR-20-033`. Bước 3 `422` `ERR-20-029`. Bước 4 `409` `ERR-20-063`. Bước 5 `409` `ERR-20-006`. Bước 6 `428` `ERR-00-428`. Mẫu không đổi.

  @TC-20-021 @P3 @Âm
  Kịch bản: TC-20-021 Ngừng phiên bản mẫu đang được lần chạy dùng và dùng mẫu đã ngừng
    # Truy vết: FR-20-015 · API-20-032, 002 · BR-20-042 · ERR-20-006, ERR-20-015
    Biết `U-PA1`; lần chạy `RUNNING` của `T93` đang dùng `tinh-chuan` v4; `tinh-chuan` v2 `RETIRED`.
    Khi `POST .../versions/4:retire` khi lần chạy đang dùng
    Và khai báo tenant mới với `templateVersion = 2`
    Thì bước 1 `409` `ERR-20-006` (còn lần chạy chưa kết thúc dùng phiên bản này). Bước 2 `422` `ERR-20-015` với lý do "phiên bản đã ngừng". Mẫu v4 giữ `PUBLISHED`.
