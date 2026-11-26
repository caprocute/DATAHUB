# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-28
Tính năng: TS-16-28 · Lập và gửi gói báo cáo chỉ tiêu, sổ kiến trúc qua PH-14

  @TC-16-095 @P1 @Dương
  Kịch bản: TC-16-095 Lập gói báo cáo chỉ tiêu và gửi qua PH-14
    # Truy vết: FR-16-051 · API-16-118, 119, 120, 121, 123 · UI-16-17, UI-16-10 · EVT-16-12 · BR-16-021, BR-16-022
    Biết T96; U-T96-TA; báo cáo `bc-thang-2026-09` `PUBLISHED` phiên bản 1; mẫu `KPI_REPORT` `ACTIVE`; `qg-sim` kịch bản `ACK`; `16.national.enabled = true`.
    Khi `POST /national/submissions` `{submissionType: KPI_REPORT, reportCode: bc-thang-2026-09, version: 1, templateCode: qg-bao-cao-chi-tieu}` khóa idempotent `tc-sub-1`
    Và `GET /national/submissions/{id}` (bản xem trước)
    Và `POST /national/submissions/{id}:send`
    Và đợi biên nhận
    Và `GET /national/submissions/{id}/logs`
    Và `GET /national/submissions?submissionType=KPI_REPORT&state=ACKNOWLEDGED`
    Thì bước 1 `201`, `state = PENDING`, `contentHash`, `preview`. Bước 3 `202`, `SENDING` → `SENT`, gói đi qua PH-14 (không gọi thẳng hệ quốc gia; `qg-sim` nhận từ PH-14). Sau biên nhận `ACKNOWLEDGED`, `receiptNo`. Nhật ký có dòng cho mỗi lần giao, phản hồi, biên nhận; danh sách lọc trả gói này. EVT: `national-submission.state-changed` (EVT-16-12) mỗi lần đổi.

  @TC-16-096 @P1 @Âm
  Kịch bản: TC-16-096 Gửi quốc gia đang tắt, báo cáo chưa công bố, gói không đạt mẫu, báo cáo đột xuất
    # Truy vết: FR-16-051 · API-16-118, 121 · ERR-16-046, ERR-16-052, ERR-16-048 · BR-16-021
    Biết T90 (`16.national.enabled = false`); T96; báo cáo `bc-thang-2026-10` `DRAFT`; báo cáo `bc-dot-xuat-q1-q3` `AD_HOC`; mẫu gói yêu cầu trường `periodCode` mà báo cáo thử thiếu.
    Khi Ở T90 `POST /national/submissions`
    Và Ở T96 `POST /national/submissions` với `reportCode = bc-thang-2026-10` (chưa công bố)
    Và Ở T96 với báo cáo đột xuất
    Và Ở T96 với gói thiếu trường bắt buộc của mẫu
    Thì bước 1 `409` ERR-16-046. Bước 2 `422` ERR-16-052. Bước 3 `422` ERR-16-052 (đột xuất không gửi quốc gia). Bước 4 `422` ERR-16-048. Không gói nào được tạo hoặc gửi.

  @TC-16-097 @P1 @Âm @Biên
  Kịch bản: TC-16-097 Gói trùng nội dung đã nộp (idempotent)
    # Truy vết: FR-16-051, FR-16-053 · API-16-118 · ERR-16-049 · BR-16-021
    Biết T96; gói `KPI_REPORT` của `bc-thang-2026-09` phiên bản 1 đã `ACKNOWLEDGED` (mã biên nhận `BN-TC-0001`, ngày 2026-11-26).
    Khi `POST /national/submissions` lại với `reportCode = bc-thang-2026-09`, `version = 1`
    Và sau khi đính chính tạo phiên bản 2 công bố, `POST /national/submissions` với `version = 2`
    Thì bước 1 `409` ERR-16-049 (cùng `reportCode`, phiên bản, `contentHash`), không tạo gói mới. Bước 2 `201` (khác phiên bản, khác `contentHash`).

  @TC-16-098 @P2 @Dương
  Kịch bản: TC-16-098 Gửi sổ kiến trúc qua PH-14, toàn bộ và theo thay đổi
    # Truy vết: FR-16-052 · API-16-118, 121, 120 · UI-16-17 · EVT-16-12 · BR-16-021, BR-16-024
    Biết T96; sổ kiến trúc 40 thành phần, 10 đã `CONFIRMED` tuân thủ; mẫu `ARCH_REGISTRY` `ACTIVE`; `qg-sim`.
    Khi `POST /national/submissions` `{submissionType: ARCH_REGISTRY, mode: FULL, componentTypes: [HTTT, API], templateCode: qg-so-kien-truc}` rồi `:send`
    Và đổi vòng đời một thành phần
    Và `POST /national/submissions` `{submissionType: ARCH_REGISTRY, mode: DELTA}`
    Thì bước 1 `componentCount` đúng số `HTTT`, `API`, mỗi thành phần có phiên bản, trạng thái vận hành, `complianceLevel`; gói đi qua PH-14, nhận biên nhận. Bước 3 gói `DELTA` chỉ thành phần thay đổi; idempotent theo `componentCode` + phiên bản + `contentHash`.
