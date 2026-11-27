# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-38
Tính năng: TS-18-38 · Cắt chuyển nhóm dịch vụ và quay lui

  @TC-18-126 @P1 @Dương
  Kịch bản: TC-18-126 Danh sách kiểm tra đạt, đề nghị và người thứ hai duyệt cắt chuyển toàn phần
    # Truy vết: FR-18-068 · API-18-174, 175 · BR-18-044 · EVT-18-27 · UI-18-15, 23
    # Mục đích: Chứng minh BR-18-044 và AC-18-12: `PARALLEL → SHADOW_OK → CUT_OVER`, EVT-18-27 cho PH-03 đổi tuyến APISIX, có `rollbackUntil`.
    Biết T96; `PG-THUE` tỷ lệ khớp 99,7 %, DLQ của nhóm rỗng, 52 dấu cấp lại đã `REISSUED`, đối chiếu đã giải trình; U-T96-TA1 đề nghị, U-T96-TA2 duyệt.
    Khi TA1 mở UI-18-23, xem danh sách kiểm tra.
    Và TA1 `:transition` `action = REQUEST`, `target = CUT_OVER`.
    Và TA2 mở việc, `:transition` `action = APPROVE`.
    Thì bước 1 mọi mục `DLQ_EMPTY`, `MATCH_RATE`, `CREDENTIALS_REISSUED`, `RECONCILIATION_MATCHED` đạt. Bước 2 `202` chờ duyệt. Bước 3 `200` `CUT_OVER`, EVT-18-27 có `routes`, `rollbackUntil` = thời điểm + 15 phút; sổ cắt chuyển ghi người đề nghị, người duyệt.

  @TC-18-127 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-127 Danh sách kiểm tra chưa đạt, tỷ lệ khớp dưới ngưỡng, đóng băng, người đề nghị tự duyệt
    # Truy vết: FR-18-068 · API-18-175 · BR-18-044 · ERR-18-005, 051, 066, 067
    # Mục đích: Chứng minh mọi điều kiện của BR-18-044 và LP-18-01.
    Biết T96; `PG-DAT` còn 3 mục DLQ mở; `PG-HT` tỷ lệ khớp 98,9 %; cửa sổ `FREEZE` ở bước 3; U-T96-TA1 có `PERM-18-approve`.
    Khi TA1 đề nghị cắt chuyển `PG-DAT`.
    Và TA1 đề nghị cắt chuyển `PG-HT`.
    Và đề nghị `PG-THUE2` (đạt) khi đang đóng băng.
    Và hết đóng băng, TA1 đề nghị `PG-THUE2` rồi tự duyệt.
    Thì bước 1 `409` ERR-18-067 nêu số mục chưa đạt. Bước 2 `422` ERR-18-066. Bước 3 `409` ERR-18-051. Bước 4 `403` ERR-18-005.

  @TC-18-128 @P1 @Dương @Biên
  Kịch bản: TC-18-128 Quay lui ở phút thứ 14 không cần duyệt, lưu lượng về hệ cũ trong 15 phút
    # Truy vết: FR-18-068 · API-18-175 · BR-18-044, 046 · EVT-18-27 · NFR-18-015
    # Mục đích: Chứng minh ĐN-UC-15 và NFR-18-015: quay lui trong `18.migration.rollback-window-minutes` không cần bốn mắt, ghi kiểm toán trễ qua outbox được.
    Biết T95 (đồng hồ giả) với nhóm `PG-THUE` vừa `CUT_OVER`; WireMock PH-03 xác nhận đổi tuyến.
    Khi tua 14 phút, TA1 `:transition` `action = ROLLBACK`.
    Và đọc EVT-18-27 và xác nhận của PH-03.
    Thì bước 1 `200` `ROLLED_BACK`, không cần người duyệt. Bước 2 EVT-18-27 `to = ROLLED_BACK`; PH-03 xác nhận 100 % tuyến về hệ cũ; sổ cắt chuyển ghi lý do và thời điểm.

  @TC-18-129 @P1 @Âm @Biên
  Kịch bản: TC-18-129 Quay lui ở phút thứ 16 bị từ chối
    # Truy vết: FR-18-068 · API-18-175 · BR-18-044 · ERR-18-068
    # Mục đích: Chứng minh ĐN-UC-15: quá cửa sổ quay lui không quay lui tự động được.
    Biết T95; nhóm `PG-THUE` `CUT_OVER` lại.
    Khi tua 16 phút, TA1 gửi `ROLLBACK`.
    Thì `409` ERR-18-068; trạng thái giữ `CUT_OVER`; màn chỉ dẫn quy trình quay lui thủ công qua đề nghị bốn mắt mới.

  @TC-18-170 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-18-170 Xác nhận mục kiểm tay, người duyệt từ chối đề nghị cắt chuyển
    # Truy vết: FR-18-068 · API-18-185, 175, 174 · BR-18-044 · ERR-18-006, 005, 067 · EVT-18-27 · UI-18-23
    # Mục đích: Chứng minh FR-18-068 bước 1 và thân `action` của API-18-175: mục tay chỉ đạt khi có người xác nhận qua API-18-185, mục tự động không xác nhận tay được, `REJECT` giữ nguyên trạng thái nhóm.
    Biết T96; `PG-THUE` mọi mục tự động đạt, hai mục tay `HTTT_NOTIFIED`, `ONCALL_READY` `PENDING`; U-T96-TA1 đề nghị, U-T96-TA2 duyệt.
    Khi TA1 `POST /parallel-groups/PG-THUE/checklist/HTTT_NOTIFIED:confirm` kèm bằng chứng (số công văn).
    Và TA1 `:transition` `action = REQUEST` khi `ONCALL_READY` còn `PENDING`.
    Và TA1 xác nhận `ONCALL_READY`, rồi `:transition` `action = REQUEST`, `target = CUT_OVER`.
    Và TA1 `:confirm` mục tự động `MATCH_RATE`.
    Và TA1 `:transition` `action = APPROVE` trên đề nghị của chính mình.
    Và TA2 `:transition` `action = REJECT` kèm lý do.
    Thì bước 1 `200` mục `PASSED`, sổ cắt chuyển ghi người xác nhận. Bước 2 `409` ERR-18-067. Bước 3 `202` chờ duyệt. Bước 4 `409` ERR-18-006. Bước 5 `403` ERR-18-005. Bước 6 `200`, đề nghị đóng, nhóm giữ `SHADOW_OK`, sổ cắt chuyển ghi người từ chối và lý do, không gửi yêu cầu đổi tuyến cho PH-03.
