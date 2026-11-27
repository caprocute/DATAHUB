# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-02
Tính năng: TS-18-02 · Sửa giá trị tham số trên màn tham số chung

  @TC-18-006 @P1 @Dương
  Kịch bản: TC-18-006 TA sửa giá trị tham số tenant có lý do và If-Match trên màn nhúng
    # Truy vết: FR-18-003, 007 · API-18-004, 005, 006, 007, 016 · BR-18-002, 005, 049 · EVT-18-01 · UI-18-08
    # Mục đích: Chứng minh đường ghi chuẩn: kiểm trước bằng `:validate`, ghi có lý do và `If-Match`, tạo phiên bản mới, nhật ký đổi tham số có người đổi và lý do.
    Biết T90; U-T90-TA1 có `PERM-18-config`; `04.retry.max-attempts` (INT, miền 0…10, trần 8, mặc định 3) đang ở phiên bản 1.
    Khi U-T90-TA1 mở `/van-hanh/tham-so?ns=04.&nhom=thu-lai`.
    Và nhập giá trị 5 rồi bấm "Kiểm tra" (gọi `POST /params:validate`).
    Và nhập lý do "Tăng số lần thử cho luồng thuế ban đêm" và bấm "Lưu" (gửi `PUT /params/04.retry.max-attempts` kèm `If-Match`).
    Và mở `GET /param-changes?ns=04.`.
    Thì bước 1 màn chỉ hiện nhóm "thu-lai" của `04.`, có nguồn giá trị (mặc định, tenant). Bước 2 `200` hợp lệ, không ghi. Bước 3 `200`, `version = 2`, `ETag` mới, EVT-18-01 phát; KT: có (param-update) với giá trị cũ, mới, lý do. Bước 4 có dòng đổi với người đổi U-T90-TA1.

  @TC-18-007 @P1 @Âm
  Kịch bản: TC-18-007 Khóa chưa đăng ký, sai kiểu, ngoài miền, vượt trần, khóa PLATFORM và thiếu lý do
    # Truy vết: FR-18-003 · API-18-006, 007 · BR-18-002, 003 · ERR-18-007, 011, 012, 013, 014, 015
    # Mục đích: Chứng minh BR-18-002, 003: PH-18 chặn mọi giá trị sai ở thời điểm ghi với đúng mã lỗi, giá trị cũ giữ nguyên.
    Biết T90; U-T90-TA1; `04.retry.max-attempts` (miền 0…10, trần nền tảng 8); `onboarding.platform.max-tenants` mức `PLATFORM`.
    Khi `PUT /params/04.khong-dang-ky` giá trị 1.
    Và `PUT /params/04.retry.max-attempts` giá trị `"năm"`.
    Và cùng khóa giá trị 12, rồi giá trị 9.
    Và `PUT /params/onboarding.platform.max-tenants` giá trị 50.
    Và cùng khóa `04.retry.max-attempts` giá trị 6 nhưng lý do "sửa" (4 ký tự).
    Thì bước 1 `404` ERR-18-011. Bước 2 `422` ERR-18-012. Bước 3 lần đầu `422` ERR-18-013, lần sau `422` ERR-18-014. Bước 4 `403` ERR-18-015. Bước 5 `422` ERR-18-007. Không bước nào tạo phiên bản hay phát EVT-18-01; `:validate` cho cùng giá trị trả cùng mã.

  @TC-18-008 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-008 Hai người sửa cùng lúc, thiếu If-Match và vai không có quyền
    # Truy vết: FR-18-003 · API-18-006 · BR-18-049 · ERR-18-004 · ERR-00-428, 403 · UI-18-08
    # Mục đích: Chứng minh khóa lạc quan và quyền trên thao tác ghi: người lưu sau nhận lỗi ETag lệch, thiếu `If-Match` bị từ chối, VW không ghi được.
    Biết T90; U-T90-TA1, U-T90-TA2 cùng mở khóa `04.retry.max-attempts` phiên bản 2; U-T90-VW.
    Khi TA1 lưu giá trị 4 với `If-Match` của phiên bản 2.
    Và TA2 lưu giá trị 6 với `If-Match` của phiên bản 2.
    Và TA2 gửi lại không có `If-Match`.
    Và U-T90-VW gửi `PUT` hợp lệ.
    Thì bước 1 `200`, phiên bản 3. Bước 2 `412` ERR-18-004, UI-18-08 hiện câu thông báo và nút "Tải lại". Bước 3 `428` ERR-00-428. Bước 4 `403` ERR-00-403. Giá trị cuối là 4.

  @TC-18-009 @P2 @Dương @Âm
  Kịch bản: TC-18-009 PA chỉnh tham số `18.*` của chính phân hệ vận hành, TA chỉ chỉnh khóa được mở
    # Truy vết: FR-18-069 · API-18-004, 006 · BR-18-002, 004 · ERR-18-012, 014, 015
    # Mục đích: Chứng minh FR-18-069: tham số `18.*` dùng chính kho tham số, `PERM-18-admin` của PA ghi được, TA chỉ ghi khóa mức `TENANT` và bị chặn ở trần.
    Biết T90; U-PA1 (`PERM-18-admin`); U-T90-TA1 (`PERM-18-admin` hạn chế); `18.dlq.retention.closed-days` miền 30…365.
    Khi U-PA1 `PUT /params/18.dlq.retention.closed-days` cho T90 giá trị 120, lý do.
    Và U-T90-TA1 ghi cùng khóa giá trị 400.
    Và U-T90-TA1 ghi `18.dlq.replay.rate-per-second` giá trị `true`.
    Và U-T90-TA1 ghi `18.outbox.retention-days` (mức `PLATFORM`).
    Thì bước 1 `200`, tác vụ dọn của PH-18 đọc giá trị 120 ở lần chạy kế tiếp. Bước 2 `422` ERR-18-014. Bước 3 `422` ERR-18-012. Bước 4 `403` ERR-18-015.
