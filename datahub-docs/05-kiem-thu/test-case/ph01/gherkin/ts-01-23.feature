# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-23
Tính năng: TS-01-23 · Đề nghị thay đổi hồ sơ và mở rộng trần phạm vi

  @TC-01-089 @P2 @Dương
  Kịch bản: TC-01-089 Ba mức duyệt của thay đổi hồ sơ
    # Truy vết: FR-01-034 · UC-01-23 · API-01-057, 058, 059 · UI-01-04, 07 · BR-01-025, 029 · EVT-01-04.
    Biết `HT-TUPHAP` ACTIVE; U-T68-OR1; TA1; SO.
    Khi OR1 `POST …/change-requests` đổi mô tả.
    Và OR1 đổi địa chỉ cơ sở và dải IP.
    Và OR1 đổi cấp độ ATTT; TA1 và SO duyệt qua `POST /change-requests/{id}:decide`.
    Và đổi chủ quản sang Văn phòng UBND.
    Thì bước 1: `200`, áp dụng ngay. Bước 2: `202`, chờ duyệt kỹ thuật, `GET …/change-requests` thấy yêu cầu. Bước 3: áp dụng khi cả hai duyệt; `EVT-01-04`. Bước 4: cần tổ chức mới xác nhận rồi TA duyệt.

  @TC-01-090 @P1 @Âm
  Kịch bản: TC-01-090 Thay đổi sai: chồng yêu cầu, qua đường thường để mở rộng, địa chỉ http
    # Truy vết: FR-01-034 · API-01-057 · BR-01-012 · ERR-01-037, 038, 049.
    Biết `HT-TUPHAP` có yêu cầu thay đổi đang chờ; OR1.
    Khi gửi thêm yêu cầu thay đổi khi đang chờ.
    Và gửi thay đổi nhu cầu có thêm một mục `CONSUME` qua đường thay đổi thường.
    Và gửi địa chỉ `http://…`.
    Thì `409` ERR-01-038; `422` ERR-01-037; `422` ERR-01-049.

  @TC-01-091 @P1 @Dương
  Kịch bản: TC-01-091 Mở rộng trần phạm vi: thẩm định lại, trần đổi khi duyệt
    # Truy vết: FR-01-035 · UC-01-24 · API-01-060, 059 · UI-01-04, 06, 07 · BR-01-003, 012 · EVT-01-11.
    Biết `HT-TUPHAP`; mục mở rộng có căn cứ F-PDF-VB; người thẩm định LEGAL được giao; TA duyệt khác người đề nghị.
    Khi OR1 `POST …/scope-expansions`; kiểm trần.
    Và người thẩm định ghi kết luận pháp lý cho mục mới.
    Và TA duyệt.
    Thì bước 1: `202`, trần không đổi. Bước 3: trần tăng đúng mục được chấp thuận, không hơn; `EVT-01-11`. KT: có.

  @TC-01-092 @P1 @Âm @Bảomật
  Kịch bản: TC-01-092 Mở rộng phạm vi sai: thiếu căn cứ, bí mật nhà nước, cấp độ thấp
    # Truy vết: FR-01-035 · API-01-060 · BR-01-001, 004, 026 · ERR-01-015, 016, 038, 047.
    Biết `HT-TUPHAP` cấp độ `L2`; OR1.
    Khi `POST …/scope-expansions` thiếu căn cứ.
    Và mục `BMNN-TEST`.
    Và mục mức Hạn chế khi HTTT `L2`.
    Và gửi khi đã có mở rộng đang chờ.
    Thì `422` ERR-01-015; `422` ERR-01-016; `422` ERR-01-047; `409` ERR-01-038.

  @TC-01-150 @P2 @Dương
  Kịch bản: TC-01-150 Tổ chức giải thể: tạo sẵn đề nghị đổi chủ quản cho cả lô
    # Truy vết: FR-01-054 · FR-01-034 · UC-01-23 · API-01-058, 059 · UI-01-04, 07 · BR-01-017, 029 · EVT-01-04
    Biết tổ chức `TC-ORG-CU` có ba HTTT: `tc-own-act` ACTIVE, `tc-own-sus` SUSPENDED, `tc-own-app` APPROVED; thêm `tc-own-ter` TERMINATED; tổ chức kế thừa `TC-ORG-MOI` ACTIVE; PH-20 giả lập phát EVT-20-13 với `change = DISSOLVED`, `successorCode = TC-ORG-MOI`; TA1, TA2.
    Khi PH-20 giả lập phát EVT-20-13 một lần.
    Và TA1 `GET /change-requests?type=OWNER_CHANGE&status=PENDING` (API-01-058) và mở lô ở UI-01-07.
    Và TA1 bấm "Duyệt cả lô" (giao diện gọi API-01-059 từng yêu cầu).
    Và đọc `ownerOrgId` của bốn HTTT và nhật ký kiểm toán.
    Thì bước 2: đúng ba yêu cầu `OWNER_CHANGE` `PENDING` sang `TC-ORG-MOI` (không có cho `tc-own-ter`); người đề nghị `system:ph01-org-successor`, `owner_confirmed_by = system:ph20-successor`, `diff.source = EVT-20-13`, mã lô là mã sự kiện; TA có một việc `ph01.approve-change` gom ba yêu cầu. Bước 1: chưa HTTT nào đổi chủ quản. Bước 3: ba lần `200`, kết quả riêng từng HTTT; `ownerOrgId = TC-ORG-MOI` cho ba HTTT, `tc-own-ter` giữ nguyên. EVT: `EVT-01-04` ba lần. KT: có sự kiện nguồn, từng yêu cầu và người duyệt.

  @TC-01-151 @P2 @Âm @Biên
  Kịch bản: TC-01-151 Giải thể, sáp nhập: trường hợp không tạo, trùng, duyệt lệch
    # Truy vết: FR-01-054 · FR-01-034 · API-01-058, 059 · BR-01-017, 029 · ERR-01-005
    Biết như ca `owner-batch-ok`; thêm `tc-own-pend` ACTIVE của `TC-ORG-CU` đã có yêu cầu thay đổi khác `PENDING`; tổ chức `TC-ORG-NGHI` (không ACTIVE); TA1, TA2.
    Khi PH-20 giả lập phát EVT-20-13 `DISSOLVED` cho `TC-ORG-CU` (có `tc-own-pend`), rồi phát lại đúng sự kiện đó (cùng mã sự kiện).
    Và phát EVT-20-13 `DISSOLVED` thiếu `successorCode`; rồi với `successorCode = TC-ORG-NGHI`.
    Và phát EVT-20-13 cho tổ chức không có HTTT.
    Và với lô ở ca `owner-batch-ok`, TA2 duyệt `tc-own-act` trước; sau đó TA1 duyệt cả lô.
    Và TA1 từ chối yêu cầu của `tc-own-app`.
    Thì bước 1: lần đầu không tạo yêu cầu cho `tc-own-pend` (chỉ mục duy nhất của EN-01-13), HTTT vào danh sách "chờ tạo lại" của lô và TA được nhắc xử lý yêu cầu cũ; lần phát lại bị bỏ qua nhờ `inbox(event_id)`, không tạo thêm yêu cầu. Bước 2: không tạo yêu cầu, TA nhận nhắc đổi chủ quản từng HTTT theo FR-01-034. Bước 3: không phát sinh việc. Bước 4: dòng `tc-own-act` của TA1 trả `409` ERR-01-005, các dòng khác `200`. Bước 5: `tc-own-app` giữ chủ quản cũ, hiện cờ "chủ quản đã giải thể".
