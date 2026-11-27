# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-22
Tính năng: TS-01-22 · Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT

  @TC-01-086 @P1 @Dương @Bảomật
  Kịch bản: TC-01-086 SO tạm ngừng khẩn, TA xác nhận
    # Truy vết: FR-01-032 · UC-01-22 · API-01-054, 055 · UI-01-11 · BR-01-010, 023 · EVT-01-15, 03, 07 · NFR-01-008.
    Biết `HT-DVC` ACTIVE đang gọi API; U-T68-SO có MFA mới; TA1.
    Khi SO `POST /systems/HT-DVC:emergency-action` với `mode = SUSPEND`, lý do, `incidentRef`.
    Và đo thời gian cổng từ chối.
    Và TA1 `POST /emergency-actions/{actionId}:confirm`.
    Thì bước 1: `200` ngay, không chờ TA; `SUSPENDED` lý do `SECURITY_SUSPECT`. Bước 2: ≤ 60 giây. Bước 3: `200`, ghi nhận xác nhận. EVT: `EVT-01-15` hai lần (thực hiện, xác nhận), `EVT-01-03`, `EVT-01-07`. KT: có.

  @TC-01-087 @P1 @Âm
  Kịch bản: TC-01-087 Thao tác khẩn sai điều kiện
    # Truy vết: FR-01-032 · API-01-054, 055 · ERR-01-033, 035, 036.
    Biết `HT-DVC`; thao tác khẩn đã xác nhận; U-T68-SO, TA1, OR1.
    Khi SO gọi không lý do; rồi thiếu MFA mới.
    Và TA1 xác nhận lần hai thao tác đã xử lý.
    Và OR1 gọi `:emergency-action`.
    Thì `400` ERR-01-033; `403` ERR-01-035; `409` ERR-01-036; `403-PQ`.

  @TC-01-088 @P2 @Biên
  Kịch bản: TC-01-088 Quá 24 giờ chưa xác nhận: cảnh báo, không hoàn tác
    # Truy vết: FR-01-032 · BR-01-010 · EVT-01-15.
    Biết thao tác khẩn chưa xác nhận; `emergency.confirmHours = 24`; đồng hồ giả.
    Khi tua 25 giờ; chạy tác vụ.
    Thì `EVT-01-15` loại "quá hạn", cảnh báo mức cao tới TA, PO; HTTT vẫn `SUSPENDED`, không tự khôi phục.

  @TC-01-144 @P1 @Dương @Bảomật
  Kịch bản: TC-01-144 TA khác xác nhận thao tác khẩn khi TA đầu vắng
    # Truy vết: FR-01-032 · UC-01-22 · API-01-054, 055 · UI-01-11 · BR-01-010
    Biết thao tác khẩn `PENDING_CONFIRM` do U-T68-SO tạo trên `HT-DVC`; U-T68-TA1 (Minh) đặt vắng, không đăng nhập; U-T68-TA2 (Quang) hoạt động; tenant T68 có đúng hai TA hoạt động.
    Khi việc xác nhận gửi tới cả TA1 và TA2; kiểm hộp việc của TA2.
    Và TA2 `POST /emergency-actions/{actionId}:confirm` kèm MFA mới.
    Và xem lịch sử thao tác khẩn ở UI-01-11 và nhật ký kiểm toán.
    Thì bước 1: việc xác nhận có ở hộp việc của TA2, người gửi không phải SO. Bước 2: `200`, thao tác khẩn `CONFIRMED`, HTTT vẫn `SUSPENDED`. Bước 3: người xác nhận là TA2, không có lần xác nhận nào của SO. EVT: `EVT-01-15` (xác nhận). KT: có.

  @TC-01-145 @P1 @Âm @Bảomật
  Kịch bản: TC-01-145 Không ai ngoài TA xác nhận thay; xác nhận lần hai bị từ chối
    # Truy vết: FR-01-032 · API-01-055 · BR-01-010 · ERR-01-036, 052
    Biết thao tác khẩn `PENDING_CONFIRM` trên `HT-DVC`; PA (U-PA, không giữ `PERM-01-approve` của T68); U-T68-SO; TA1, TA2.
    Khi PA `POST /emergency-actions/{actionId}:confirm`.
    Và SO tự xác nhận thao tác do chính mình tạo.
    Và TA2 xác nhận; sau đó TA1 xác nhận lần hai cùng thao tác.
    Thì bước 1: `403` ERR-01-052 (không có `PERM-01-approve`). Bước 2: `403` ERR-01-052. Bước 3: lần của TA2 `200`; lần của TA1 `409` ERR-01-036. Thao tác khẩn chỉ có một người xác nhận (TA2).

  @TC-01-146 @P1 @Dương @Bảomật
  Kịch bản: TC-01-146 PH-13 gửi đề xuất tạm ngừng, SO nhận việc khẩn
    # Truy vết: FR-01-053 · FR-01-032 · UC-01-22 · API-01-089 · UI-01-11 · BR-01-009, 010
    Biết `HT-QLVB` ACTIVE ở T68; S-SP (token dịch vụ `onboarding:suspension-proposal` của T68); U-T68-SO; `mail-sink` và hộp việc PH-18 giả lập.
    Khi S-SP `POST /internal/suspension-proposals` với `systemCode = HT-QLVB`, `alertId` mới, `severity = HIGH`, `reason` 40 ký tự, `evidenceUrl`, `incidentRef = SEC-ALERT-2026-0142`.
    Và đọc hộp việc của SO và của TA.
    Và đọc trạng thái `HT-QLVB` và nhật ký kiểm toán.
    Thì bước 1: `202` có `Location`, thân `{ systemCode, alertId, taskId, accepted = true, duplicate = false }`. Bước 2: SO có một việc loại `ph01.review-suspension-proposal`, mức khẩn, kèm lý do, mức nghiêm trọng, liên kết UI-01-11 và liên kết sâu về cảnh báo; TA không có việc này. Bước 3: `HT-QLVB` vẫn `ACTIVE`, không có sự kiện EVT-01-03, EVT-01-15; có một dòng kiểm toán (bên gửi PH-13, `alertId`, HTTT, lý do). KT: có.

  @TC-01-147 @P2 @Biên
  Kịch bản: TC-01-147 Đề xuất lặp cùng alertId không tạo việc thứ hai
    # Truy vết: FR-01-053 · API-01-089 · BR-01-010
    Biết như ca `susp-prop-ok`; đã có một đề xuất với `alertId` A cho `HT-QLVB`.
    Khi S-SP gửi lại đúng đề xuất (cùng `systemCode`, `alertId = A`).
    Và S-SP gửi đề xuất mới với `alertId = B` cho cùng HTTT.
    Và đếm việc `ph01.review-suspension-proposal` của SO.
    Thì bước 1: `202`, `duplicate = true`, `taskId` trùng lần đầu. Bước 2: `202`, `duplicate = false`, `taskId` mới. Bước 3: hai việc (A và B), không có việc thứ ba.

  @TC-01-148 @P1 @Âm @Bảomật
  Kịch bản: TC-01-148 Đề xuất tạm ngừng sai điều kiện
    # Truy vết: FR-01-053 · API-01-089 · ERR-01-001, 003, 005, 048, 052
    Biết S-SP của T68; S-INT (scope khác); token người dùng của U-T68-SO; `HT-QLVB` ACTIVE; `tc-susp` SUSPENDED; `HT-HOTICH-SB` APPROVED; `HT-TC-KHAC` chỉ có ở T01; S-SP-T01 (token của T01).
    Khi gọi không token; rồi bằng S-INT; rồi bằng token của SO.
    Và S-SP-T01 gửi đề xuất cho `HT-QLVB` (HTTT thuộc T68).
    Và S-SP gửi `systemCode = HT-TC-KHAC` (T01), rồi mã không tồn tại.
    Và S-SP gửi cho `tc-susp` (SUSPENDED), rồi cho `HT-HOTICH-SB` (APPROVED).
    Và S-SP gửi `reason` 5 ký tự; `severity = LOW`; `alertId` không phải UUID; thiếu `alertId`.
    Thì bước 1: `401` ERR-01-052 khi không token; `403` ERR-01-052 với S-INT và token người dùng. Bước 2: `403` ERR-01-052 (tenant của token không trùng). Bước 3: `404` ERR-01-001, thân giống hệt nhau (404-ẩn). Bước 4: `409` ERR-01-048 cho `tc-susp`; `409` ERR-01-005 cho `HT-HOTICH-SB`. Bước 5: `400` ERR-01-003 kèm `errors[].path` đúng trường. Không ca nào tạo việc cho SO.

  @TC-01-149 @P1 @Dương
  Kịch bản: TC-01-149 SO xử lý việc đề xuất: xử lý khẩn hoặc không tạm ngừng
    # Truy vết: FR-01-053 · FR-01-032 · API-01-054, 089 · UI-01-11 · BR-01-009, 010
    Biết hai việc đề xuất đang mở cho U-T68-SO: việc P1 cho `HT-QLVB` (có `incidentRef`), việc P2 cho `HT-DATDAI`; SO có MFA mới.
    Khi SO mở việc P1, xem lý do và tác động phụ thuộc (FR-01-033), chọn "Xử lý khẩn" chế độ `SUSPEND`.
    Và SO mở việc P2, chọn "Không tạm ngừng" kèm lý do.
    Và đọc hộp việc, trạng thái hai HTTT và kiểm toán.
    Thì bước 1: màn hình thao tác khẩn có sẵn `incidentRef` của đề xuất; `200`, `HT-QLVB` `SUSPENDED`; việc P1 tự đóng; EVT-01-15, EVT-01-03. Bước 2: việc P2 đóng, `HT-DATDAI` vẫn `ACTIVE`. Bước 3: không còn việc mở; kiểm toán ghi người đóng việc và quyết định của từng việc. Không có đường nào tạm ngừng mà SO không bấm.
