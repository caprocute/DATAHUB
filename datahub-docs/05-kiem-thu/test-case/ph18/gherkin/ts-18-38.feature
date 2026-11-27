# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-38
Tính năng: TS-18-38 · Cắt chuyển nhóm dịch vụ và quay lui

  @TC-18-126 @P1 @Dương
  Kịch bản: TC-18-126 Danh sách kiểm tra đạt, đề nghị và người thứ hai duyệt cắt chuyển toàn phần
    # Truy vết: FR-18-068 · API-18-174, 175 · BR-18-044 · EVT-18-27 · UI-18-15, 23
    # Mục đích: Chứng minh BR-18-044 và AC-18-12: `PARALLEL → SHADOW_OK → CUT_OVER`, EVT-18-27 cho PH-03 đổi tuyến APISIX, có `rollbackUntil`.
    Biết T96; `PG-THUE` tỷ lệ khớp 99,7 %, DLQ của nhóm rỗng, 52 dấu cấp lại đã `DONE`, đối chiếu đã giải trình; U-T96-TA1 đề nghị, U-T96-TA2 duyệt.
    Khi TA1 mở UI-18-23, xem danh sách kiểm tra.
    Và TA1 `:transition` `action = REQUEST`, mục tiêu `CUT_OVER`.
    Và TA2 duyệt từ việc.
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
