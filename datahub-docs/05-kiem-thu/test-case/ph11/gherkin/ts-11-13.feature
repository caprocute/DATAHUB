# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-13
Tính năng: TS-11-13 · Ủy quyền khi vắng mặt và phân công lại hàng loạt

  @TC-11-077 @P2 @Dương
  Kịch bản: TC-11-077 Ủy quyền hiệu lực, hết hạn, thu hồi
    # Truy vết: FR-11-041 · API-11-079, 080, 081 · UI-11-17 · EVT-11-09 · BR-11-020
    Biết CB-TP, CB-TP2; hai việc đang giữ của CB-TP; `11.delegation.maxDays = 30`.
    Khi CB-TP `POST /delegations` `{toUser:"CB-TP2", from:+1 ngày, to:+6 ngày, includeExisting:true}`
    Và CLK tới `from`
    Và CB-TP2 hoàn thành một việc
    Và CLK qua `to`
    Và CB-TP tạo ủy quyền mới rồi `POST /delegations/{id}:revoke`
    Thì bước 1 `SCHEDULED`. Bước 2 `ACTIVE`; việc chuyển `DELEGATED`, CB-TP vẫn thấy. Bước 3 hoàn thành được. Bước 4 `EXPIRED`, việc chưa xong trả CB-TP. Bước 5 `REVOKED`, việc trả về.

  @TC-11-078 @P2 @Âm
  Kịch bản: TC-11-078 Ủy quyền quá dài, chồng lấn, vòng, khác tenant
    # Truy vết: FR-11-041 · API-11-080 · ERR-11-025 · BR-11-020
    Biết T92 `11.delegation.maxDays = 7`; CB-TP, CB-TP2.
    Khi CB-TP ủy quyền 10 ngày
    Và ủy quyền chồng khoảng với ủy quyền đang có
    Và CB-TP ủy quyền cho CB-TP2 rồi CB-TP2 ủy lại cho CB-TP
    Và CB-TP ủy quyền cho `U-T91-CB1`
    Thì cả bốn `422` ERR-11-025 với lý do tương ứng (quá ngày, chồng lấn, vòng, khác tenant).

  @TC-11-079 @P2 @Dương
  Kịch bản: TC-11-079 Phân công lại hàng loạt có xem trước
    # Truy vết: FR-11-042 · API-11-082 · UI-11-16 · EVT-11-09 · BR-11-020 · PERM-11-task-admin
    Biết CB-TP đang giữ 4 việc, 1 việc là `duyetCapSo` mà người nhận đích đã xử lý cấp phòng; TO.
    Khi TO `POST /tasks:bulk-reassign` `{filter:{assignee:"CB-TP"}, toUser:"CB-TP2", preview:true}`
    Và TO gửi lại với `preview:false`
    Thì bước 1 `200` xem trước: 3 việc sẽ chuyển, 1 việc bị loại do tách nhiệm vụ. Bước 2 `202`, mỗi việc một giao dịch, kết quả từng việc; EVT: `task.assigned` `via = BULK` cho 3 việc.

  @TC-11-080 @P2 @Âm
  Kịch bản: TC-11-080 Giao lại quá giới hạn, người đích sai, thiếu quyền
    # Truy vết: FR-11-042 · API-11-082 · ERR-11-024, 050 · ERR-00-403
    Biết T92 `11.task.bulkMax = 5`; 6 việc của CB-TP; TO, CB-TP.
    Khi TO giao lại 6 việc
    Và TO giao lại cho người ngừng hoạt động
    Và CB-TP gọi `:bulk-reassign`
    Thì bước 1 `422` ERR-11-050. Bước 2 `422` ERR-11-024. Bước 3 `403` ERR-00-403.
