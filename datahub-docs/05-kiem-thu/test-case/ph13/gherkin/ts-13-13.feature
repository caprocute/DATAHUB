# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-13
Tính năng: TS-13-13 · Xuất bằng chứng kiểm toán ký số

  @TC-13-044 @P1 @Dương
  Kịch bản: TC-13-044 Xuất gói bằng chứng, tải và tự xác minh ngoại tuyến
    # Truy vết: FR-13-024 · UC-13-15 · API-13-082, 083, 084 · UI-13-14 · EVT-13-08 · BR-13-014 · NFR-13-031
    Biết F-AUD-1K; U-T68-AU xác thực lại, nhập lý do và căn cứ.
    Khi `POST /exports` phạm vi 24 giờ; hỏi `GET /exports/{id}`.
    Và tải `GET /exports/{id}/download`; chạy script xác minh đi kèm không có mạng.
    Thì `202` → `READY`; EVT: `export-ready`; gói có bản ghi, chuỗi băm, neo, chữ ký; script báo hợp lệ; sửa một byte thì báo hỏng; KT: có (`AUDIT.EXPORT`, `AUDIT.DOWNLOAD`).

  @TC-13-045 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-045 Không ký được thì không xuất, không để lại tệp
    # Truy vết: FR-13-024 · BR-13-014 · ERR-13-026 · ERR-13-014
    Biết tắt OpenBao khi gói đã dựng.
    Khi yêu cầu tải gói khi OpenBao ngừng.
    Thì `503` ERR-13-026; không có tệp chưa ký ở kho tạm hay bucket; khi OpenBao về, tải lại được.

  @TC-13-046 @P1 @Âm @Biên
  Kịch bản: TC-13-046 Trùng yêu cầu, thiếu lý do, quá rộng, hết hạn tải
    # Truy vết: FR-13-024 · API-13-082, 084 · ERR-13-025, 008, 012, 013, 027, 028, 009 · BR-13-029
    Biết U-T68-AU; U-T68-TA; `13.export.link-ttl-minutes = 15`.
    Khi gửi hai yêu cầu cùng phạm vi.
    Và không lý do; phạm vi trên 10 triệu bản ghi; phiên chưa xác thực lại.
    Và tải sau 16 phút; U-T68-TA yêu cầu.
    Thì lần hai `409` ERR-13-025; ERR-13-008 hoặc 012; ERR-13-013; ERR-13-028; tải quá hạn `410` ERR-13-027; TA bị 403-PQ.
