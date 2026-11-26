# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-10
Tính năng: TS-11-10 · Nhận việc, xem hồ sơ và hoàn thành việc với biểu mẫu, ý kiến, quyết định

  @TC-11-060 @P1 @Dương
  Kịch bản: TC-11-060 Nhận và trả lại việc
    # Truy vết: FR-11-036 · API-11-074, 075 · EVT-11-09 · BR-11-016
    Biết việc `nhanHoSo` `UNASSIGNED`; CB-TP.
    Khi CB-TP `POST /tasks/{id}:claim`
    Và CB-TP `POST /tasks/{id}:unclaim`
    Thì bước 1 `200`, `ASSIGNED`, EVT: `task.assigned` `via = CLAIM`. Bước 2 `UNASSIGNED`, ứng viên khác lại thấy việc.

  @TC-11-061 @P1 @Âm
  Kịch bản: TC-11-061 Nhận việc: đã có người, không phải ứng viên, phiên tạm dừng
    # Truy vết: FR-11-036 · API-11-074 · ERR-11-006, 021, 022
    Biết việc có hai ứng viên CB-TP, CB-TP2; CB-BH không thuộc nhóm; phiên khác `SUSPENDED`.
    Khi CB-TP và CB-TP2 cùng gửi `:claim` đồng thời
    Và CB-BH `:claim`
    Và CB-TP `:claim` việc của phiên `SUSPENDED`
    Thì bước 1 một `200`, một `409` ERR-11-021. Bước 2 `403` ERR-11-022. Bước 3 `409` ERR-11-006.

  @TC-11-062 @P1 @Dương @Bảo @mật
  Kịch bản: TC-11-062 Xem chi tiết việc, che biến, xem giá trị rõ có lý do
    # Truy vết: FR-11-037 · API-11-073, 055 · UI-11-15 · BR-11-014, 031 · PERM-09-unmask
    Biết việc của `HS-03` (`F-DLCN`); CB-TP, TA có `PERM-09-unmask`, TO.
    Khi CB-TP `GET /tasks/{id}`
    Và TA `GET /instances/{id}/variables`
    Và TA gọi lại với `reason="Đối chiếu khiếu nại"` và quyền mở che
    Và TO gọi lại có lý do
    Thì bước 1 `maXa` rõ, `soDinhDanhMe` ``, `hoTenTre` che với người không có quyền. Bước 2 vẫn ``. Bước 3 giá trị rõ, KT: có (`variable.unmask`, lý do), giao diện tự che lại sau `11.task.unmaskSeconds` giây. Bước 4 vẫn `` (không `PERM-09-unmask`, BR-11-014).

  @TC-11-063 @P1 @Âm
  Kịch bản: TC-11-063 Xem việc ngoài phạm vi hoặc không tồn tại
    # Truy vết: FR-11-037 · API-11-073 · ERR-11-001, 022, 034 · BR-11-031
    Biết việc của đơn vị Tư pháp; CB-BH; `U-T91-IE1`.
    Khi CB-BH `GET /tasks/{id}`
    Và CB-BH `GET /tasks/khong-co`
    Và `U-T91-IE1` `GET /tasks/{id}`
    Thì bước 1 `403` ERR-11-034. Bước 2 `404` ERR-11-001. Bước 3 `404-ẩn` ERR-11-001.

  @TC-11-064 @P1 @Dương
  Kịch bản: TC-11-064 Hoàn thành việc với biểu mẫu, ý kiến, quyết định
    # Truy vết: FR-11-038, 046 · API-11-076 · UI-11-15 · EVT-11-10, 04 · BR-11-016, 023, 033 · PERM-11-task
    Biết việc `nhanHoSo` do CB-TP nhận; có nháp.
    Khi CB-TP `POST /tasks/{id}:complete` `{decision:"COMPLETE", data:{...}, comment:"Hồ sơ đủ"}`
    Và tra `task_index`, `due_tracking`, biến, `GET /instances/{id}`
    Thì `200`; việc `COMPLETED`, nháp xóa, `dueResult = MET`; biến `SENSITIVE` mã hóa; token sang bước sau; EVT: `task.completed` có `decision`, `completedBy`, `dueResult`. KT: có.

  @TC-11-065 @P1 @Âm
  Kịch bản: TC-11-065 Hoàn thành sai: dữ liệu, ý kiến, người, tách nhiệm vụ, phiên tạm dừng
    # Truy vết: FR-11-038 · API-11-076 · ERR-11-005, 006, 007, 022, 023 · BR-11-016, 020, 033
    Biết việc `duyetCapSo` của CB-SO; CB-LD là người đã xử lý `duyetCapPhong`; một việc của phiên `SUSPENDED`.
    Khi CB-SO `:complete` với dữ liệu sai schema
    Và CB-SO `:complete` `REJECT` với `comment` 8 ký tự
    Và CB-TP `:complete` việc của CB-SO
    Và cấp thêm CB-LD vào ứng viên bằng CSDL, CB-LD nhận rồi `:complete`
    Và CB-TP `:complete` việc phiên `SUSPENDED`
    Thì bước 1 `422` ERR-11-023, `errors[]` theo trường. Bước 2 `422` ERR-11-007. Bước 3 `403` ERR-11-022. Bước 4 `403` ERR-11-005. Bước 5 `409` ERR-11-006.

  @TC-11-066 @P3 @Dương @Âm
  Kịch bản: TC-11-066 Lưu nháp kết quả việc
    # Truy vết: FR-11-039 · API-11-077 · ERR-11-004, 022, 023 · BR-11-014
    Biết việc đang `ASSIGNED` cho CB-TP.
    Khi CB-TP `PUT /tasks/{id}/draft` với `If-Match`
    Và mở lại việc
    Và CB-TP `PUT` với `If-Match` cũ
    Và CB-BH `PUT`
    Và CB-TP `PUT` thân không phải đối tượng
    Thì bước 1 `200`, bước 2 nháp khớp, `SENSITIVE` mã hóa. Bước 3 `409` ERR-11-004. Bước 4 `403` ERR-11-022. Bước 5 `422` ERR-11-023.

  @TC-11-067 @P3 @Dương @Âm
  Kịch bản: TC-11-067 Gợi ý AI chỉ là gợi ý
    # Truy vết: FR-11-066 · API-11-124 · ERR-11-124 · BR-11-029, 014 · PERM-17-use
    Biết PH-17 giả; CB-TP có `PERM-17-use`; CB-VT không có; `11.ai.timeoutSeconds = 10`.
    Khi CB-TP `POST /tasks/{id}/ai-suggestions`
    Và CB-TP hoàn thành việc theo quyết định khác gợi ý
    Và đặt PH-17 chậm 15 giây, gọi lại
    Và CB-VT gọi
    Thì bước 1 `200` gợi ý, không chứa giá trị `SENSITIVE`. Bước 2 `ai_assisted = true`, quyết định là của cán bộ. Bước 3 ERR-11-124 sau 10 giây, việc xử lý bình thường. Bước 4 `403` ERR-00-403.
