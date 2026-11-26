# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-21
Tính năng: TS-05-21 · Kiểm thử, gửi duyệt, duyệt phiên bản bộ điều hợp

  @TC-05-081 @P1 @Dương
  Kịch bản: TC-05-081 Kiểm thử tất cả thao tác trên TEST
    # Truy vết: FR-05-043 · API-05-052, 053 · UI-05-10 · UC-05-17 · LGC-BUS-013
    Biết U-T68-IE1; A-QLVB v4 nháp 6 thao tác (1 `WRITE`).
    Khi Ở UI-05-10 chọn "Kiểm thử ▾ Tất cả thao tác".
    Và Ở hộp xác nhận ghi thử, tích "Tôi xác nhận môi trường TEST của HTTT cho phép ghi thử".
    Thì `202`; R5 tab Kết quả kiểm thử hiện từng thao tác với các bước kết nối, gọi, chuyển đổi, chuẩn hóa, so lược đồ; 6 mục R2 có ✓. `GET …/tests/{id}` `status = PASSED`.

  @TC-05-082 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-082 Thao tác ghi không chạy trên PROD; thiếu xác nhận
    # Truy vết: FR-05-043 · BR-05-030 · API-05-052 · ERR-05-003
    Biết U-T68-IE1; A-QLVB v4.
    Khi `POST …/versions/4/tests` với `env = PROD`.
    Và với `env = STAGING`, `operations = ["gui-van-ban"]` (`WRITE`), có `confirmWriteOnTest = true`.
    Và với `env = TEST`, thao tác `WRITE`, không `confirmWriteOnTest`.
    Thì bước 1 `400` ERR-05-003 (`env` chỉ `TEST`, `STAGING`). Bước 2 `202`, SIM-SOAP STAGING nhận đúng một yêu cầu ghi, kiểm toán ghi xác nhận (BR-05-030). Bước 3 `400` ERR-05-003; SIM-SOAP TEST không nhận yêu cầu ghi.

  @TC-05-083 @P1 @Âm
  Kịch bản: TC-05-083 Gửi duyệt khi sửa sau kiểm thử bị chặn
    # Truy vết: FR-05-044, 032 · API-05-055 · ERR-05-009 · BR-05-006
    Biết U-T68-IE1; sau TC-05-081, sửa `timeoutMs` của một thao tác.
    Thì `409` ERR-05-009; mục R2 của thao tác vừa sửa mất ✓; nút "Gửi duyệt" vô hiệu với lý do.

  @TC-05-084 @P1 @Dương
  Kịch bản: TC-05-084 Gửi duyệt, người khác duyệt, Kamelet sinh và phiên bản cũ bị thay
    # Truy vết: FR-05-044, 047 · API-05-055, 056 · UI-05-17 · EVT-05-07 · BR-05-016
    Biết U-T68-IE1, U-T68-IA1; A-QLVB v4 kiểm thử đạt.
    Khi IE1 gửi duyệt với ghi chú phát hành.
    Và IA1 duyệt ở UI-05-17.
    Và `GET /adapters/qlvb-soap`; `PUT …/versions/4/operations/x`.
    Thì bước 1 v4 `SUBMITTED`. Bước 2 v4 `APPROVED`, v3 `SUPERSEDED`. EVT: `adapter.version-approved`. Bước 3 `effectiveVersion = 4`, Kamelet sinh tên `qlvb-soap-{op}-v1-{loại}`; `PUT` trả `409` ERR-05-008.

  @TC-05-085 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-085 Tự duyệt phiên bản; từ chối thiếu lý do
    # Truy vết: FR-05-044 · API-05-056, 057 · ERR-05-011, 038 · BR-05-009
    Biết U-T68-IA2 soạn và gửi phiên bản của `tc-qlvb`.
    Khi IA2 `POST …:approve`.
    Và IA1 `POST …:reject` không lý do; rồi có lý do.
    Thì bước 1 `403` ERR-05-011. Bước 2 lần đầu `400` ERR-05-038; lần hai `200`, phiên bản về `DRAFT`, kết quả kiểm thử giữ.

  @TC-05-086 @P2 @Dương @Âm
  Kịch bản: TC-05-086 Tạm dừng bộ điều hợp chặn lượt mới; ngừng dùng khi còn nơi dùng
    # Truy vết: FR-05-044 · API-05-058, 059, 060 · EVT-05-08 · ERR-05-118, 010
    Biết U-T68-TO; A-DVC đang dùng ở 21 luồng.
    Khi TO `POST /adapters/dvc-rest:suspend` với lý do; luồng gọi.
    Và TO `:resume`.
    Và IE1 `:retire`.
    Thì bước 1 `200`, EVT: `adapter.state-changed`, lượt mới nhận ERR-05-118 trong ≤ 30 giây. Bước 2 hoạt động lại. Bước 3 `409` ERR-05-010.
