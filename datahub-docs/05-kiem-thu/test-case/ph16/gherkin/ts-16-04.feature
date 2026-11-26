# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-04
Tính năng: TS-16-04 · Kế thừa bộ chỉ tiêu mẫu COMMON và nhận cập nhật mẫu

  @TC-16-015 @P1 @Dương
  Kịch bản: TC-16-015 Kế thừa bộ chỉ tiêu mẫu COMMON
    # Truy vết: FR-16-008 · API-16-018, 001, 003 · UI-16-03 · BR-16-018
    Biết T93 chưa có chỉ tiêu; U-T93-TA; mẫu `COMMON` 24 chỉ tiêu (U-PA).
    Khi `GET /indicators?scope=COMMON`
    Và `POST /indicators:adopt-common` với `indicatorCodes` rỗng (kế thừa toàn bộ), khóa idempotent `tc-adopt-1`
    Và `POST /indicators:adopt-common` lại với `indicatorCodes = [mttd]`
    Và `GET /indicators/mttd`
    Thì bước 1 `200`, 24 chỉ tiêu `scope = COMMON`. Bước 2 `201`, `adopted` 24 mã, `skipped` rỗng; mỗi chỉ tiêu ở tenant có `scope = TENANT`, `derivedFrom = {indicatorCode, version}`, công thức, ngưỡng, nhóm theo mẫu, trạng thái `ACTIVE`. Bước 3 `skipped = [{indicatorCode: mttd, reason}]`, không tạo bản trùng.

  @TC-16-016 @P1 @Âm
  Kịch bản: TC-16-016 Sửa trực tiếp chỉ tiêu mẫu hoặc kế thừa mã đã có
    # Truy vết: FR-16-008 · API-16-005, 007, 018 · ERR-16-014, ERR-16-002 · BR-16-018
    Biết T94 chưa kế thừa mẫu (dọn trước ca), U-T94-TA; T90 đã kế thừa, U-T90-TA1; U-PA.
    Khi U-T94-TA `PATCH /indicators/mttd/versions/1` trên chỉ tiêu `scope = COMMON`
    Và U-T90-TA1 `POST /indicators:adopt-common` với `indicatorCodes = [mttd]` khi đã có bản tùy biến
    Và U-PA sửa mẫu `COMMON` hợp lệ
    Thì bước 1 `403` ERR-16-014. Bước 2 `skipped` kèm lý do trùng (`201` với `adopted` rỗng) hoặc `409` ERR-16-002 khi mã trùng bản tự đặt. Bước 3 `200` (PA có quyền với mẫu). Mẫu `COMMON` không đổi từ phía tenant (BR-16-018).

  @TC-16-017 @P2 @Dương @Âm
  Kịch bản: TC-16-017 Nhận cập nhật mẫu, quyết định ACCEPT hoặc DISMISS, xung đột tùy biến
    # Truy vết: FR-16-008 · API-16-019, 020 · UI-16-03 · ERR-16-055 · BR-16-018 · EVT-16-01
    Biết T90 đã kế thừa; U-PA phát phiên bản 2 của mẫu `api-cong-bo` (đổi `greenFrom`) và `mttr-muc-1`; T90 chưa tùy biến hai chỉ tiêu này.
    Khi `GET /common-updates`
    Và `GET /indicators`
    Và U-T90-TA1 `POST /common-updates/api-cong-bo:decide` với `decision = ACCEPT`
    Và `POST /common-updates/mttr-muc-1:decide` với `decision = DISMISS`, `comment`
    Và `POST /common-updates/tre-gateway-p95:decide` `ACCEPT` khi T90 đã tùy biến `thresholds` của chỉ tiêu này và mẫu cũng đổi `thresholds`
    Thì bước 1 có hai mục, `changedFields`, `conflictFields` rỗng. Bước 2 `hasCommonUpdate = true`. Bước 3 `newDraftVersion` trỏ bản nháp tùy biến, chưa `ACTIVE` tới khi duyệt bốn mắt (BR-16-018); số liệu đang chạy không đổi. Bước 4 `dismissed = true`, mục chuyển `DISMISSED`. Bước 5 `conflictFields = [thresholds]`, `409` ERR-16-055, không tạo bản nháp.
