# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-25
Tính năng: TS-18-25 · Phân hệ đăng ký loại việc, tạo và đóng việc lũy đẳng

  @TC-18-083 @P1 @Dương @Lũy_đẳng
  Kịch bản: TC-18-083 PH-02 đăng ký loại việc, tạo, cập nhật và đóng việc lũy đẳng
    # Truy vết: FR-18-042, 043 · API-18-107, 108, 109, 110 · BR-18-032 · EVT-18-14 · UI-18-15
    # Mục đích: Chứng minh BR-18-032: `PUT` cùng `sourceRef` cập nhật thay vì tạo mới, đóng hai lần chỉ có một chuyển trạng thái, phân hệ nguồn là bên đóng việc.
    Biết T90; S-PH02 (`ops:task`); người nhận là nhóm duyệt `ROLE:TA` trừ người tạo phiên bản API.
    Khi S-PH02 `POST /ops/internal/v1/task-types` `ph02.approve-version`, quyền xem `PERM-02-publish`, hạn 3 ngày làm việc, liên kết màn.
    Và S-PH02 `PUT /ops/internal/v1/tasks/ph02:ver:svc-thue-v3` với `assignees`, `excludeUsers`.
    Và gọi lại bước 2 cùng thân, rồi đổi hạn.
    Và S-PH02 `POST .../tasks/ph02:ver:svc-thue-v3:close` `DONE` hai lần.
    Và `GET /task-types`.
    Thì bước 1 `201`. Bước 2 `201` `OPEN`, EVT-18-14. Bước 3 `200` cùng `taskId`, hạn mới. Bước 4 lần đầu `200` `DONE`, lần hai `200` không đổi, chỉ một EVT-18-14 `to = DONE`. Bước 5 loại việc hiện với chủ PH-02.

  @TC-18-084 @P1 @Âm
  Kịch bản: TC-18-084 Loại việc ngoài không gian tên, loại chưa đăng ký, việc đã đóng, tiêu đề chứa biến cấm
    # Truy vết: FR-18-042, 043 · API-18-107, 109 · BR-18-032 · ERR-18-003, 017, 039, 047, 048
    # Mục đích: Chứng minh điều kiện chặn của API việc.
    Biết T90; S-PH02; việc `ph02:ver:svc-thue-v3` đã `DONE`.
    Khi S-PH02 đăng ký loại `ph04.approve-flow`.
    Và S-PH02 đăng ký loại thiếu `name`.
    Và S-PH02 `PUT` việc loại `ph02.khong-co`.
    Và S-PH02 `PUT` lại việc đã `DONE` với hạn mới.
    Và S-PH02 tạo việc có tiêu đề chứa `{{soCccd}}`.
    Thì bước 1 `403` ERR-18-017. Bước 2 `400` ERR-18-003. Bước 3 `422` ERR-18-047. Bước 4 `409` ERR-18-048. Bước 5 `422` ERR-18-039.

  @TC-18-085 @P1 @Bảo_mật
  Kịch bản: TC-18-085 Việc duyệt bốn mắt ẩn với người tạo đối tượng và người mất quyền
    # Truy vết: FR-18-043, 044 · API-18-109, 111, 112 · BR-18-032 · ERR-18-001 · UI-18-15
    # Mục đích: Chứng minh AC-18-08: người dùng chỉ thấy việc được giao và còn quyền xem; việc bốn mắt có `excludeUsers` là người tạo.
    Biết T90; việc `ph02:ver:svc-dat-v2` giao `ROLE:TA`, `excludeUsers = [U-T90-TA1]`; U-T90-TA2; WireMock PH-12 thu hồi `PERM-02-publish` của TA2 ở bước 3.
    Khi TA1 `GET /me/tasks`.
    Và TA2 `GET /me/tasks`.
    Và thu hồi quyền của TA2, TA2 `GET /me/tasks/{taskId}`.
    Thì bước 1 không có việc. Bước 2 có việc. Bước 3 danh sách không còn việc, chi tiết trả `404` ERR-18-001.
