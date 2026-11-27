# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-20
Tính năng: TS-20-20 · Tạm ngừng và khôi phục tenant

  @TC-20-090 @P1 @Dương
  Kịch bản: TC-20-090 Tạm ngừng T92 theo quyết định quản lý và hiệu lực ở mặt phẳng dữ liệu
    # Truy vết: FR-20-038, 044 · UC-20-20 · API-20-071, 079 · BR-20-021 · EVT-20-04 · ERR-20-001 · NFR-20-004 · UI-20-08 · `PERM-20-lifecycle`
    Biết `U-PA1`; `T92` `ACTIVE`; `iam-sim`, `mod-sim`, `mod-sim`, `ops-sim`; `clock-sim`.
    Khi `POST P/tenants/T92/lifecycle-requests` với `requestType = SUSPEND`, `suspendReason = MANAGEMENT_DECISION`, `reasonText` 30 ký tự, `ticketRef`, `decisionDocNo = TC/QĐ-01`, `decisionDocDate`, `essentialApisAllowed = false`
    Và theo dõi `GET P/lifecycle-requests/{requestId}` tới khi xong
    Và gọi API dữ liệu và `dh-console` bằng token `T92` ngay khi tenant `SUSPENDED`
    Và đọc thư thông báo ở `ops-sim`
    Thì bước 1 `201`, `APPROVED` ngay (không cần duyệt), thực hiện ngay. Bước 2 `DONE`, tenant `SUSPENDED`, đã gọi API-12-084 (realm chỉ đăng nhập xem, chặn token máy), lịch sử trạng thái có quyết định; EVT: `platform.tenant.status-changed.v1` đúng một lần. Bước 3 trong ≤ 60 giây mọi API trả `403` `ERR-20-001`, giao diện chỉ đọc có dải cảnh báo; PH-04 dừng luồng theo lịch, PH-10 chặn sản xuất sự kiện. Bước 4 đầu mối và quản trị tỉnh nhận thư nêu lý do và liên hệ, không có dữ liệu cá nhân của người dùng khác.

  @TC-20-091 @P1 @Âm
  Kịch bản: TC-20-091 Tạm ngừng sai trạng thái, thiếu lý do, thiếu văn bản, tenant đặc biệt, PH-12 lỗi
    # Truy vết: FR-20-038 · API-20-071, 079 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-107 · `20.lifecycle.reason-min-length`
    Biết `U-PA1`; `T92` đã `SUSPENDED`; `T90` `ACTIVE`; `iam-sim` trả `409` ở API-12-084.
    Khi `POST P/tenants/T92/lifecycle-requests` với `SUSPEND` khi đã `SUSPENDED`
    Và `POST P/tenants/T90/lifecycle-requests` `SUSPEND` với `reasonText` 10 ký tự, không `ticketRef`
    Và `POST` `suspendReason = MANAGEMENT_DECISION` không có `decisionDocNo`
    Và `POST P/tenants/PLATFORM/lifecycle-requests` `SUSPEND`
    Và `POST` `SUSPEND` cho `T90` khi `iam-sim` lỗi
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-008`. Bước 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-20-010`. Bước 5 đề nghị về `APPROVED` (thực hiện lỗi) với `ERR-20-107` ở UI-20-08, data plane vẫn chặn nhờ EVT-20-04 tới PH-03, tenant theo dõi được thực hiện lại.

  @TC-20-092 @P2 @Biên
  Kịch bản: TC-20-092 Tạm ngừng do sự cố an ninh: không cần văn bản, mở việc bổ sung văn bản
    # Truy vết: FR-20-038 · UC-20-20 · API-20-071 · BR-20-021 · UI-20-08
    Biết `U-PA1`; `T91`; `ops-sim` nhận việc; `clock-sim`.
    Khi `POST P/tenants/T91/lifecycle-requests` `SUSPEND` với `suspendReason = SECURITY_INCIDENT`, không văn bản
    Và kiểm tra việc ở `ops-sim`
    Và đẩy `clock-sim` quá 3 ngày làm việc khi chưa bổ sung
    Thì bước 1 `201`, tạm ngừng ngay. Bước 2 có việc yêu cầu bổ sung văn bản trong 3 ngày làm việc. Bước 3 tenant giữ `SUSPENDED`, cảnh báo hai PA, không tự khôi phục (Q20-47).

  @TC-20-093 @P1 @Dương
  Kịch bản: TC-20-093 Khôi phục tenant sau kiểm tra khói rút gọn
    # Truy vết: FR-20-039 · UC-20-20 · API-20-071, 079, API-12-085 · EVT-20-04 · UI-20-08 · `PERM-20-lifecycle`
    Biết `U-PA1`; `T92` `SUSPENDED` do `CONTRACT_EXPIRED`; `iam-sim`, `mod-sim`.
    Khi `POST P/tenants/T92/lifecycle-requests` với `requestType = RESUME`, `reasonText`, `ticketRef`, `decisionDocNo`
    Và theo dõi tới khi `DONE`
    Và gọi API dữ liệu bằng token `T92`
    Thì bước 2 gọi API-12-085, chạy ca `LOGIN_ADMIN`, `API_SAMPLE`, tenant `ACTIVE`, EVT: `status-changed` một lần; cảnh báo nếu chưa có hợp đồng hiệu lực mới (không chặn). Bước 3 `200`, trong ≤ 60 giây. Thông báo đổi trạng thái gửi đầu mối.

  @TC-20-094 @P1 @Âm
  Kịch bản: TC-20-094 Khôi phục sai trạng thái, đang có đề nghị chấm dứt, khói rút gọn lỗi
    # Truy vết: FR-20-039 · API-20-071, 079 · ERR-20-006, ERR-20-037, ERR-20-117
    Biết `U-PA1`; `T90` `ACTIVE`; `T92` `SUSPENDED` có đề nghị `TERMINATE` đã `APPROVED`; `T91` `SUSPENDED`, `iam-sim` lỗi ca `LOGIN_ADMIN`.
    Khi `POST P/tenants/T90/lifecycle-requests` `RESUME`
    Và `POST P/tenants/T92/lifecycle-requests` `RESUME`
    Và `POST P/tenants/T91/lifecycle-requests` `RESUME`
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-037` ("... đang có đề nghị chấm dứt"). Bước 3 `ERR-20-117` ("Ca kiểm tra khói LOGIN_ADMIN lỗi: ..."), tenant giữ `SUSPENDED`.
