# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-29
Tính năng: TS-16-29 · Nhật ký nộp, biên nhận, gửi lại và đối soát

  @TC-16-099 @P1 @Dương
  Kịch bản: TC-16-099 Nhận biên nhận từ PH-14 và nhật ký chỉ thêm
    # Truy vết: FR-16-053 · API-16-124, 120, 123 · UI-16-17 · EVT-16-12 · BR-16-022
    Biết gói `SENT` (hash `H1`); S-T90-PH14 (scope `kpi.national-receipt`).
    Khi S-T90-PH14 `POST /internal/national/receipts` `{submissionId, channelMessageId: m-1, status: ACKNOWLEDGED, receiptNo: BN-TC-0002, contentHash: H1}`
    Và `GET /national/submissions/{id}`
    Và `GET /national/submissions/{id}/logs`
    Và gửi lại đúng biên nhận
    Thì bước 1 `204`. Bước 2 `ACKNOWLEDGED`, `receiptNo`, `ackAt`. Bước 3 nhật ký chỉ thêm, có dòng biên nhận kèm `channelMessageId`; không sửa, không xóa dòng cũ. Bước 4 không tạo dòng thứ hai (idempotent theo `channelMessageId`) hoặc `409` ERR-16-006.

  @TC-16-100 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-100 Biên nhận lệch mã băm, sai scope, gói không có
    # Truy vết: FR-16-053 · API-16-124 · ERR-16-124, ERR-16-001, ERR-16-006, ERR-00-403
    Biết gói `SENT` (hash `H1`); S-T90-NOSCOPE, S-T90-PH14.
    Khi S-T90-PH14 gửi biên nhận với `contentHash = H2`
    Và S-T90-NOSCOPE `POST /internal/national/receipts`
    Và S-T90-PH14 gửi biên nhận cho `submissionId` không có
    Và gửi biên nhận `ACKNOWLEDGED` cho gói đang `PENDING`
    Thì bước 1 ghi ERR-16-124, gói giữ `SENT`, báo cán bộ ATTT, thông báo PH-13. Bước 2 `403` ERR-00-403. Bước 3 `404` ERR-16-001. Bước 4 `409` ERR-16-006.

  @TC-16-101 @P1 @Dương @Chịu @lỗi
  Kịch bản: TC-16-101 Gửi lại tự động theo giãn cách và gửi lại thủ công
    # Truy vết: FR-16-053 · API-16-121, 122, 123 · UI-16-17 · ERR-16-118, ERR-16-117, ERR-16-050 · EVT-16-12 · BR-16-021
    Biết T96 `16.national.retry-max = 5`; `qg-sim` kịch bản `TIMEOUT`; `clock-sim`; gói mới (hash `H1`).
    Khi `POST …:send`
    Và đẩy đồng hồ 5, 15, 45, 135 phút lần lượt
    Và sau lần thứ 5 `GET /national/submissions/{id}`
    Và đổi `qg-sim` về `ACK`, U-T96-TA `POST …:retry` `{reason: <25 ký tự>}`
    Và với `qg-sim` `REJECT` mã `QG-422`, thử `POST …:retry`
    Và gửi lại khi đã `ACKNOWLEDGED`
    Thì lần đầu thất bại `FAILED`, ERR-16-118 "sẽ thử lại lần 1"; tự gửi lại đúng giãn cách 5, 15, 45, 135 phút (`attemptCount` tăng); quá `retry-max` thì dừng, tạo việc cho TA. Bước 4 gửi lại cùng `contentHash` thành công, không tạo bản trùng ở `qg-sim`. Bước 5 gói `REJECTED` hiện ERR-16-117, `:retry` bị `409` ERR-16-050. Bước 6 `409` ERR-16-050.

  @TC-16-102 @P3 @Dương
  Kịch bản: TC-16-102 Đối soát sổ kiến trúc, gói đã nộp và chỉ tiêu
    # Truy vết: FR-16-054 · API-16-125, 126 · UI-16-17 · ERR-16-056
    Biết T96; một thành phần đổi sau lần gửi `FULL`; một báo cáo `PUBLISHED` chưa có gói.
    Khi `POST /national/reconciliations` `{scope: ALL}`
    Và `GET /national/reconciliations/{reconId}`
    Và `POST /national/reconciliations` khi đang chạy
    Thì bước 1 `202`. Bước 2 `items[]` có `kind`, `ref`, `expected`, `actual`, `suggestion`: một dòng cho thành phần lệch, một cho báo cáo chưa nộp. Bước 3 `409` ERR-16-056.
