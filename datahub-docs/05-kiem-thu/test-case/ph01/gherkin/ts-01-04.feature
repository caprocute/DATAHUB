# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-04
Tính năng: TS-01-04 · Nhu cầu khai thác, căn cứ pháp lý và tài liệu đính kèm

  @TC-01-017 @P1 @Dương
  Kịch bản: TC-01-017 Khai nhu cầu CONSUME có căn cứ, dùng chung một văn bản
    # Truy vết: FR-01-005, 007 · UC-01-04 · API-01-007, 012, 013 · UI-01-01 · BR-01-001.
    Biết U-T68-OR1; `HT-HOTICH`; F-PDF-VB.
    Khi `POST …/attachments` tải F-PDF-VB loại `LEGAL_BASIS`.
    Và `PUT …/data-demands` với hai dòng `CONSUME` (loại dữ liệu trong danh mục), cùng chọn tệp trên và có số, ngày, cơ quan ban hành; một dòng `PROVIDE` không căn cứ nhưng có mức phân loại.
    Và `GET …/data-demands`.
    Thì bước 1: `201`, tệp mã hóa khi lưu, không lưu lặp. Bước 2 và 3: `200`, `missingLegalBasis = false` ở mọi dòng; trần phạm vi tính từ các dòng; dòng `PROVIDE` được nhận.

  @TC-01-018 @P1 @Âm
  Kịch bản: TC-01-018 Dòng CONSUME thiếu căn cứ được lưu nhưng bị đánh dấu
    # Truy vết: FR-01-007 · API-01-012, 013 · UI-01-01 · BR-01-001 · ERR-01-015, 003.
    Biết U-T68-OR1; `HT-HOTICH`.
    Khi `PUT …/data-demands` một dòng `CONSUME` không có căn cứ.
    Và gửi dòng có ngày ban hành là ngày mai.
    Thì bước 1: `200`, `missingLegalBasis = true`, UI tô đỏ "Thiếu căn cứ"; ERR-01-015 chỉ xuất hiện khi kiểm tra hợp lệ (TS-01-06). Bước 2: `400` ERR-01-003.

  @TC-01-019 @P1 @Âm @Bảomật
  Kịch bản: TC-01-019 Dữ liệu bí mật nhà nước bị từ chối tuyệt đối
    # Truy vết: FR-01-007, 011 · API-01-012 · BR-01-004 · ERR-01-016.
    Biết U-T68-OR1; U-T68-TA1; loại dữ liệu `BMNN-TEST` thuộc danh mục bí mật nhà nước.
    Khi OR1 và TA1 lần lượt `PUT …/data-demands` có dòng `CONSUME` loại `BMNN-TEST` (cả khi có căn cứ đầy đủ).
    Và gọi lại với dòng `PROVIDE` cùng loại.
    Thì cả bốn lần `422` ERR-01-016, thông báo "không kết nối qua Datahub"; dòng không được lưu; không có ngoại lệ cho TA. KT: có (từ chối).

  @TC-01-020 @P1 @Âm @Bảomật
  Kịch bản: TC-01-020 Tệp đính kèm: cỡ, định dạng, mã độc, lỗi phụ thuộc
    # Truy vết: FR-01-005 · API-01-007 · ERR-01-012, 013, 014, 046 · NFR-01-005, 011.
    Biết U-T68-OR1; F-PDF-BIG, F-EXE, F-EICAR; `attachment.maxSizeMb = 20`.
    Khi tải lần lượt F-PDF-BIG, F-EXE, F-EICAR.
    Và đặt giả lập quét mã độc `fail`; tải F-PDF-VB.
    Thì `413` ERR-01-012; `415` ERR-01-013; `422` ERR-01-014. Bước 2: `503` ERR-01-046, không nhận tệp chưa quét. Không còn tệp nào trong kho sau các bước.

  @TC-01-021 @P1 @Dương @Bảomật
  Kịch bản: TC-01-021 Tải, xóa tệp; tệp của tenant khác
    # Truy vết: FR-01-005 · API-01-006, 008, 009 · ERR-01-001, 005 · BR-01-001.
    Biết U-T68-OR1; U-T01-TA; tệp đã đính kèm vào `HT-HOTICH`; tệp có ở `HT-HOTICH-SS`.
    Khi `GET …/attachments`; `GET …/attachments/{id}/content`; `DELETE` một tệp ở `HT-HOTICH`.
    Và U-T01-TA gọi `GET …/attachments/{id}/content` bằng id của T68.
    Và `DELETE` tệp ở `HT-HOTICH-SS`.
    Thì bước 1: `200`, `200` đúng nội dung, `204`. Bước 2: `404-ẩn`. Bước 3: `409` ERR-01-005. Tệp lưu ở bucket riêng của tenant (kiểm bằng đường dẫn đối tượng).

  @TC-01-022 @P2 @Âm
  Kịch bản: TC-01-022 Cấp độ ATTT thấp hơn mức phân loại dữ liệu (kiểm tra sớm)
    # Truy vết: FR-01-007 · API-01-012, 013 · BR-01-026 · UC-01-04.
    Biết U-T68-OR1; `HT-HOTICH` cấp độ `L2`; dòng `CONSUME` mức Hạn chế.
    Khi `PUT …/data-demands`; sau đó `GET …/data-demands`.
    Thì `200` và dòng có cờ cảnh báo cấp độ thấp hơn yêu cầu (`security.minLevelRestricted = L3`); lỗi ERR-01-047 chỉ tạo ở kiểm tra hợp lệ và thẩm định.
