# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-13
Tính năng: TS-18-13 · Xem chi tiết, ngữ cảnh chẩn đoán và nội dung mục DLQ có lý do

  @TC-18-040 @P1 @Dương
  Kịch bản: TC-18-040 Chi tiết mục có ngữ cảnh chẩn đoán từ PH-13 và liên kết sổ tay
    # Truy vết: FR-18-021, 025 · API-18-045, 046, 058 · LGC-NFR-004 · UI-18-03
    # Mục đích: Chứng minh FR-18-021: chi tiết đủ ngữ cảnh, lịch sử trạng thái, bản sửa, lượt phát lại; khung chẩn đoán lấy từ API-13-069 theo `traceId`; mã lỗi có liên kết sổ tay.
    Biết T90; `DLQ-A-02` có `traceId`; WireMock PH-13 trả log và vết đã che cho API-13-069; sổ tay có `ERR-04-101`.
    Khi U-T90-TO `GET /dlq/messages/DLQ-A-02`.
    Và `GET /dlq/messages/DLQ-A-02/diagnostics`.
    Và mở `/van-hanh/dlq/DLQ-A-02`.
    Thì bước 1 `200` đủ khối ngữ cảnh, phân loại, lịch sử. Bước 2 `200` có log và vết, `partial = false`. Bước 3 ba cột ngữ cảnh, nội dung đã che, lịch sử; mã `ERR-04-101` là liên kết tới sổ tay; payload chưa hiện cho tới khi bấm "Xem nội dung".

  @TC-18-041 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-041 PH-13 quá thời gian thì chẩn đoán trả một phần, mục không tồn tại trả 404
    # Truy vết: FR-18-021 · API-18-045, 046 · ERR-18-001, 106 · UI-18-03
    # Mục đích: Chứng minh fail-soft của chẩn đoán: quá `18.dlq.diagnostics.timeout-ms` thì chi tiết vẫn hiện, khung chẩn đoán báo chưa lấy được.
    Biết T94; WireMock PH-13 trễ 5 giây; `18.dlq.diagnostics.timeout-ms = 3000`.
    Khi `GET /dlq/messages/DLQ-A-02/diagnostics`.
    Và mở UI-18-03 của mục.
    Và `GET /dlq/messages/DLQ-KHONG-CO`.
    Thì bước 1 `200` sau ≤ 3,5 giây, `partial = true`, ghi ERR-18-106. Bước 2 màn hiện câu thông báo ở khung chẩn đoán, các cột khác đủ. Bước 3 `404` ERR-18-001.

  @TC-18-042 @P1 @Dương @Bảo_mật
  Kịch bản: TC-18-042 Xem payload có lý do: kiểm toán trước, phiếu 15 phút, trường mã hóa vẫn che
    # Truy vết: FR-18-022 · API-18-047, 048 · BR-18-017 · UI-18-03
    # Mục đích: Chứng minh BR-18-017: người có `PERM-18-dlq-payload` nhập lý do ≥ 10 ký tự, kiểm toán ghi trước khi trả, phiếu xem hết hạn theo `18.dlq.reveal.ttl-minutes`, trường đã được nguồn mã hóa hiển thị `*`.
    Biết T95 (đồng hồ giả); `DLQ-A-04` có trường `soCccd` đã mã hóa ở nguồn và trường `tenDoanhNghiep` rõ; U-T95-SO.
    Khi `GET /dlq/messages/DLQ-A-04/payload/skeleton`.
    Và `POST /dlq/messages/DLQ-A-04/payload:reveal` lý do "Đối chiếu hồ sơ lỗi của doanh nghiệp".
    Và tua đồng hồ 16 phút, mở lại nội dung bằng phiếu cũ.
    Thì bước 1 `200` chỉ tên trường và kiểu. Bước 2 `200` nội dung, `soCccd = "*"`, phiếu hết hạn sau 15 phút; KT: có (payload-reveal) với lý do, thời điểm ghi kiểm toán trước thời điểm trả. Bước 3 phiếu hết hạn, phải nhập lý do lại.

  @TC-18-043 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-043 Thiếu quyền, lý do ngắn, PH-13 không ghi kiểm toán, payload đã hết hạn
    # Truy vết: FR-18-022 · API-18-047 · BR-18-017, 025 · ERR-18-007, 008, 027 · ERR-00-403
    # Mục đích: Chứng minh không có đường xem payload khi thiếu một điều kiện của BR-18-017 hoặc payload đã dọn.
    Biết T90; U-T90-AU (không có `PERM-18-dlq-payload`), U-T90-SO; `DLQ-A-09` `EXPIRED`; WireMock PH-13 lỗi ở bước 3.
    Khi U-T90-AU gọi `:reveal` có lý do hợp lệ.
    Và U-T90-SO gọi với lý do "xem" (4 ký tự).
    Và bật lỗi PH-13, SO gọi với lý do hợp lệ.
    Và SO gọi `:reveal` cho `DLQ-A-09`.
    Thì bước 1 `403` ERR-00-403. Bước 2 `422` ERR-18-007. Bước 3 `503` ERR-18-008, không trả nội dung. Bước 4 `409` ERR-18-027. Không bước nào trả nội dung payload.
