# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-31
Tính năng: TS-18-31 · Yêu cầu, duyệt và chạy khôi phục tenant tám bước

  @TC-18-103 @P1 @Dương
  Kịch bản: TC-18-103 Khôi phục T90 về thời điểm 3 ngày trước, đủ tám bước, tenant khác không đổi
    # Truy vết: FR-18-054, 055 · API-18-138, 139, 140, 141, 142, 145 · BR-18-038, 039, 047 · EVT-18-21, 22 · NFR-18-017 · UI-18-20, 15
    # Mục đích: Chứng minh đường chính của RBK-04 và AC-18-10: dữ liệu về đúng thời điểm đích trong phạm vi, kiểm toán không bị khôi phục, T91 trên cùng ô CSDL không bị chạm.
    Biết STAGING; T90 và T91 cùng ô `pg-core`; U-T90-TA1 (`PERM-18-backup`), U-PA2 (`PERM-18-approve`); bản băm số dòng mỗi bảng của T91 trước khi chạy.
    Khi TA1 `POST /tenant-restores` thời điểm đích 3 ngày trước, phạm vi toàn tenant; `:submit`.
    Và PA2 mở việc `ph18.approve-restore`, `:approve` kèm `maintenanceNotice = true`.
    Và theo dõi `GET /tenant-restores/{requestId}/steps` tới khi xong.
    Và so bản băm số dòng của T91 và kiểm bảng kiểm toán PH-13 của T90.
    Thì bước 1 `201` `DRAFT` rồi `PENDING_APPROVAL`. Bước 2 `200` `RUNNING` có `jobName`. Bước 3 tám bước `SUCCEEDED` theo thứ tự; tenant `SUSPENDED` ở bước 4 đến 8 rồi `ACTIVE`; EVT-18-21 mỗi bước, đúng một EVT-18-22; TA1 và PA2 nhận thông báo. Bước 4 T91 không đổi; bản ghi kiểm toán của T90 sau thời điểm đích vẫn còn, có thêm bản kiểm toán khôi phục với số dòng thay mỗi bảng.

  @TC-18-104 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-104 Thời điểm ngoài cửa sổ PITR, phạm vi sai, tác vụ nặng khác và người tạo tự duyệt
    # Truy vết: FR-18-054, 055 · API-18-138, 142, 143, 144 · BR-18-038, 039 · ERR-18-005, 056, 057, 058
    # Mục đích: Chứng minh điều kiện chặn khi tạo và khi duyệt khôi phục (BR-18-038, 039).
    Biết T90; U-T90-TA1 có cả `PERM-18-approve` để kiểm tách nhiệm vụ; lệnh xuất `EXP-T90-01` đang `RUNNING` ở bước 3.
    Khi tạo yêu cầu thời điểm 31 ngày trước.
    Và tạo yêu cầu phạm vi gồm phân hệ `PH-99`.
    Và tạo yêu cầu hợp lệ khi `EXP-T90-01` đang chạy.
    Và sau khi xuất xong, tạo, gửi, rồi TA1 tự `:approve`.
    Và PA2 `:reject` kèm lý do; tạo yêu cầu khác rồi TA1 `:cancel`.
    Thì bước 1 `422` ERR-18-056. Bước 2 `422` ERR-18-058. Bước 3 `409` ERR-18-057. Bước 4 `403` ERR-18-005. Bước 5 `REJECTED`, `CANCELLED`, không có Job.

  @TC-18-105 @P1 @Chịu_lỗi
  Kịch bản: TC-18-105 Lỗi ở bước 3 dừng khôi phục, dữ liệu không đổi, tenant trở về ACTIVE
    # Truy vết: FR-18-055 · API-18-145 · BR-18-038 · ERR-18-114 · EVT-18-21
    # Mục đích: Chứng minh luồng thay thế của FR-18-055 và ĐN-UC-15: lỗi ở bước 2 đến 4 không đổi dữ liệu.
    Biết STAGING; T90; tiêm lỗi `COPY` ở bước 3 (đĩa tạm đầy); băm số dòng T90 trước khi chạy.
    Khi PA2 duyệt yêu cầu, Job chạy.
    Và đọc các bước và trạng thái tenant.
    Thì bước 3 `FAILED` ghi ERR-18-114; yêu cầu `FAILED`; tenant `ACTIVE` (chưa từng `SUSPENDED` vì lỗi trước bước 4); băm số dòng T90 không đổi; cụm tạm đã xóa.

  @TC-18-106 @P1 @Chịu_lỗi
  Kịch bản: TC-18-106 Lỗi ở bước 5 tự quay lui từ bản trích, PA quay lui tay khi tự động thất bại
    # Truy vết: FR-18-055 · API-18-145, 146 · BR-18-038 · ERR-18-114 · EVT-18-21
    # Mục đích: Chứng minh ĐN-UC-15: lỗi từ bước 5 phải quay lui, yêu cầu `ROLLED_BACK`, dữ liệu như trước khi chạy.
    Biết STAGING; T90; tiêm lỗi giao dịch thay dữ liệu PH-04 ở bước 5; lần hai tiêm thêm lỗi quay lui tự động.
    Khi chạy khôi phục lần một.
    Và chạy lần hai, quay lui tự động thất bại, PA2 `POST /tenant-restores/{requestId}:rollback`.
    Thì lần một bước 5 ghi ERR-18-114, Job quay lui, yêu cầu `ROLLED_BACK`, tenant `ACTIVE`, băm số dòng như trước. Lần hai yêu cầu dừng chờ PA, `:rollback` `202`, kết thúc `ROLLED_BACK`; KT: có (restore-rollback).

  @TC-18-107 @P1 @Chịu_lỗi
  Kịch bản: TC-18-107 Đối chiếu số dòng ở bước 8 lệch thì tenant giữ SUSPENDED chờ PA
    # Truy vết: FR-18-055 · API-18-145 · BR-18-038 · ERR-18-115
    # Mục đích: Chứng minh ERR-18-115: không mở lại tenant khi số dòng lệch bản trích.
    Biết STAGING; T90; xóa một dòng của bảng `ph02_catalog.api` trong cụm tạm sau bước 5 để giả lập lệch.
    Khi chạy khôi phục.
    Thì bước 8 ghi ERR-18-115 nêu bảng; tenant giữ `SUSPENDED`; UI-18-20 hiện câu "Số dòng sau khôi phục không khớp bản trích"; PA nhận việc quyết định.
