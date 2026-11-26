# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-09
Tính năng: TS-09-09 · Lập yêu cầu khai thác theo mục đích

  @TC-09-028 @P1 @Dương
  Kịch bản: TC-09-028 Lập nháp, sửa, gửi thẩm định tới chủ quản
    # Truy vết: FR-09-015 · API-09-059, 061, 062, 060 · UI-09-08 · EVT-09-05 · PERM-09-purpose-request
    # Mục đích: Chứng minh yêu cầu nháp gửi được và phát sự kiện tới chủ quản.
    Biết T90; U-T90-OR1; HTTT-BH có đăng ký sử dụng PH-02; API-HGD mức `SENSITIVE`; mục đích `MD-TRACUU-HGD`.
    Khi OR1 `POST /access-requests` (HTTT-BH, mục đích, API-HGD, 6 trường, 5.000 lượt mỗi ngày).
    Và OR1 `PUT` thêm lý do sử dụng; `:submit`.
    Thì bước 1 `201` `DRAFT`. Bước 2 `SUBMITTED`; EVT: `purpose-request.submitted`; hộp việc DO1 có yêu cầu với hạn `09.request.sla-days = 10` ngày làm việc.

  @TC-09-029 @P1 @Âm
  Kịch bản: TC-09-029 Mục đích hết hiệu lực, HTTT chưa hoạt động, trường ngoài phạm vi, tổ chức khác
    # Truy vết: FR-09-015 · API-09-059, 061 · ERR-09-026, 027, 028, 003, 008, 009 · BR-09-016
    # Mục đích: Chứng minh kiểm tra nghiệp vụ ở bước lập và phạm vi tổ chức của OR.
    Biết T90; `MD-CU` đã `RETIRED`; HTTT-CHUA chưa đăng ký sử dụng; mục đích `MD-THONGKE` chỉ cho 3 trường; U-T90-OR1, OR2 (tổ chức khác).
    Khi OR1 lập yêu cầu mục đích `MD-CU`.
    Và OR1 lập yêu cầu cho HTTT-CHUA.
    Và OR1 lập yêu cầu `MD-THONGKE` kèm trường ngoài 3 trường cho phép.
    Và OR2 `PUT` yêu cầu nháp của OR1.
    Và OR1 lập yêu cầu với `contractId` không tồn tại.
    Và ngừng PH-02 rồi OR1 lập yêu cầu mới.
    Thì bước 1 `422` ERR-09-026. Bước 2 `422` ERR-09-027. Bước 3 `422` ERR-09-028 nêu tên trường. Bước 4 `403` ERR-09-008. Bước 5 `400` ERR-09-003. Bước 6 `503` ERR-09-009 "Chưa kết nối được PH-02. Thử lại sau ít phút."

  @TC-09-030 @P2 @Dương @Âm
  Kịch bản: TC-09-030 Rút yêu cầu chưa quyết định và rút yêu cầu đã duyệt
    # Truy vết: FR-09-015 · API-09-063 · ERR-09-006
    # Mục đích: Chứng minh chỉ rút được yêu cầu chưa có quyết định cuối.
    Biết T90; hai yêu cầu `SUBMITTED` và `APPROVED`; U-T90-OR1.
    Khi OR1 `:withdraw` yêu cầu `SUBMITTED`.
    Và OR1 `:withdraw` yêu cầu `APPROVED`.
    Thì bước 1 `200`, `WITHDRAWN`, mục biến khỏi hộp việc DO1. Bước 2 `409` ERR-09-006.
