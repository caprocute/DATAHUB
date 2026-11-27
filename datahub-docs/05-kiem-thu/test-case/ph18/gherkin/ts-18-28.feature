# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-28
Tính năng: TS-18-28 · Mở, xử lý và đóng sự cố vận hành

  @TC-18-093 @P1 @Dương @Lũy_đẳng
  Kịch bản: TC-18-093 EVT-13-04 mở sự cố một lần theo sourceRef, cập nhật lần sau
    # Truy vết: FR-18-047 · API-18-132, 123 · BR-18-036 · EVT-18-17 · UI-18-17
    # Mục đích: Chứng minh FR-18-047 và BR-18-036: mỗi `sourceRef` có tối đa một sự cố mở; sự kiện lặp chỉ thêm mốc thời gian.
    Biết T90; WireMock PH-13 phát EVT-13-04 cảnh báo `ALR-77` mức `SEV2`; S-PH13 (`ops:incident-write`).
    Khi phát EVT-13-04 cho `ALR-77`.
    Và phát lại EVT-13-04 `ALR-77` với `eventId` mới.
    Và S-PH13 `POST /ops/internal/v1/incidents` `sourceRef = ALR-77`.
    Và U-T90-TO mở `/van-hanh/su-co`.
    Thì bước 1 một sự cố `OPEN` mức `SEV2`, EVT-18-17. Bước 2, 3 cùng sự cố, thêm mốc thời gian, không tạo mới. Bước 4 cột nguồn hiện `PH-13 · ALR-77`.

  @TC-18-094 @P1 @Dương
  Kịch bản: TC-18-094 Tạo tay, phân mức, gán người xử lý, chuyển trạng thái, thêm mốc và liên kết
    # Truy vết: FR-18-048, 049 · API-18-124, 125, 126, 127, 128, 129 · BR-18-037, 046 · EVT-18-17, 18 · UI-18-17, 18
    # Mục đích: Chứng minh FR-18-048, 049: vòng đời `OPEN → INVESTIGATING → MITIGATED → RESOLVED`, mốc thời gian chỉ thêm, liên kết mục DLQ và lượt phát lại.
    Biết T90; U-T90-TO (`PERM-18-incident`); `DLQ-A-02`, lượt `RJ-02`.
    Khi TO `POST /incidents` mức `SEV1`, tóm tắt.
    Và TO `PATCH` người xử lý U-T90-SO, `If-Match`.
    Và TO chuyển `INVESTIGATING`, thêm hai mốc, liên kết `DLQ-A-02` và `RJ-02`.
    Và chuyển `MITIGATED`, `RESOLVED`.
    Thì bước 1 `201`, hạn xác nhận theo `18.incident.sev1-ack-minutes`. Mỗi chuyển trạng thái phát EVT-18-18 và có KT. Bước 3 mốc thời gian theo thứ tự, liên kết hiện ở UI-18-18.

  @TC-18-095 @P1 @Âm
  Kịch bản: TC-18-095 Dữ liệu sai, chuyển trạng thái sai, xóa mốc thời gian, liên kết đối tượng không có, bộ tiêu thụ lỗi
    # Truy vết: FR-18-048, 049, 047 · API-18-124, 127, 128, 129 · BR-18-037 · ERR-18-001, 003, 006, 124
    # Mục đích: Chứng minh điều kiện chặn của sự cố và mốc thời gian chỉ thêm.
    Biết T90; sự cố `INC-T90-02` `OPEN`.
    Khi `POST /incidents` mức `SEV9`.
    Và chuyển `INC-T90-02` thẳng sang `CLOSED`.
    Và gọi `DELETE` trên một mốc thời gian (API không có) và thử `DELETE` bằng vai `ph18_app` ở CSDL.
    Và liên kết `DLQ-KHONG-CO`.
    Và làm bộ tiêu thụ EVT-13-05 lỗi năm lần.
    Thì bước 1 `400` ERR-18-003. Bước 2 `409` ERR-18-006. Bước 3 API `405`; CSDL báo SQLSTATE 55000 (bảng chỉ thêm). Bước 4 `404` ERR-18-001. Bước 5 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.

  @TC-18-096 @P1 @Âm @Dương
  Kịch bản: TC-18-096 Đóng sự cố cần nguyên nhân gốc và bài học từ 30 ký tự
    # Truy vết: FR-18-051 · API-18-131 · BR-18-037 · ERR-18-052 · EVT-18-18
    # Mục đích: Chứng minh BR-18-037 và AC-18-09.
    Biết T90; `INC-T90-03` `RESOLVED`.
    Khi `POST /incidents/INC-T90-03:close` nguyên nhân "lỗi mạng", bài học rỗng.
    Và đóng với nguyên nhân 60 ký tự, bài học 45 ký tự, việc khắc phục.
    Thì bước 1 `422` ERR-18-052. Bước 2 `200` `CLOSED`, EVT-18-18; sự cố hết liên kết giữ hoãn dọn mục DLQ.
