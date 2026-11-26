# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-32
Tính năng: TS-17-32 · Ghi nhật ký hội thoại đã che và tra cứu nội dung có lý do truy cập

  @TC-17-103 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-103 Mỗi lượt có nhật ký đã che, không token, không nội dung chưa che
    # Truy vết: FR-17-055 · API-17-168, 172 · BR-17-073 · NFR-17-017 · UI-17-15
    # Mục đích: Chứng minh BR-17-073 và NFR-17-017 phần quét hằng ngày.
    Biết T90; 200 lượt hỏi, trong đó 20 lượt chứa DLCN tổng hợp, 5 lượt chứa canary; U-T90-SO.
    Khi chạy 200 lượt.
    Và quét bảng `message` và nhật ký hội thoại bằng bộ mẫu chuẩn và danh sách canary.
    Và SO `GET /logs/conversations` theo khoảng, người dùng, năng lực, kết quả.
    Thì 100 % lượt có nhật ký (prompt, đáp, công cụ gọi, nguồn trích) đã che; 0 giá trị khớp mẫu DLCN rõ; 0 canary; 0 token truy cập. Bước 3 chỉ hiện siêu dữ liệu và mã người dùng (không tên), chưa có nội dung.

  @TC-17-104 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-104 Xem nội dung cần phiếu lý do ≥ 20 ký tự, 60 phút, ghi kiểm toán người xem
    # Truy vết: FR-17-056 · API-17-169, 170, 171 · BR-17-074, 075 · ERR-17-007, 079, 080 · EVT-17-25 · UI-17-16
    # Mục đích: Chứng minh BR-17-074, 075.
    Biết T95 (đồng hồ giả); `17.log.export-max-days = 31`; U-T95-SO, U-T95-AU, U-T95-IE, U-T95-TA1.
    Khi SO `GET /logs/conversations/{id}` khi chưa có phiếu.
    Và SO `POST /logs/access-grants` lý do 8 ký tự.
    Và SO `POST /logs/access-grants` lý do 30 ký tự, khoảng 45 ngày.
    Và SO `POST /logs/access-grants` lý do 30 ký tự, phạm vi một hội thoại, rồi `GET /logs/conversations/{id}`.
    Và đẩy đồng hồ 61 phút, `GET` lại.
    Và IE và TA1 `GET /logs/conversations/{id}`.
    Thì bước 1 `403` ERR-17-080. Bước 2 `422` ERR-17-007. Bước 3 `422` ERR-17-079 (tối đa 31 ngày). Bước 4 phiếu `ACTIVE`, EVT: `assist.log.access-granted`, KT: có (người xem, lý do, phạm vi), nội dung đã che, mã người dùng không tên. Bước 5 `403` ERR-17-080, phiếu `EXPIRED`. Bước 6 `403` ERR-00-403 (không có `PERM-17-log-read`).

  @TC-17-105 @P2 @Bảo_mật @Âm
  Kịch bản: TC-17-105 SO cấp phiếu không tự mở bằng người khác, tắt trợ lý không xóa nhật ký trước hạn
    # Truy vết: FR-17-056, 055 · API-17-169, 171 · BR-17-074, 079 · ERR-00-403
    # Mục đích: Chứng minh tách nhiệm vụ cấp phiếu và mở nhật ký và BR-17-079.
    Biết T90 có 30 hội thoại; phiếu `GR-1` cấp cho SO1; U-T90-SO2; T90 bị tắt rồi bật.
    Khi SO2 `GET /logs/conversations/{id}` bằng phiếu `GR-1`.
    Và TA1 `POST /policy:disable`; SO1 `GET /logs/retention`.
    Thì bước 1 `403` (phiếu không chuyển cho người khác), ghi nhật ký vi phạm. Bước 2 nhật ký 30 hội thoại vẫn còn.

  @TC-17-106 @P1 @Bảo_mật @Âm
  Kịch bản: TC-17-106 Không có nhật ký tenant khác
    # Truy vết: FR-17-056, 055 · API-17-168, 169, 171 · BR-17-086 · NFR-17-007 · ERR-17-001
    # Mục đích: Chứng minh BR-17-086 cho API nhật ký.
    Biết hội thoại `CV-90-2` của T90; U-T91-SO, U-T91-AU.
    Khi U-T91-SO `GET /logs/conversations/{CV-90-2}` và `POST /logs/access-grants` cho hội thoại này.
    Và U-T91-AU `GET /logs/conversations` đúng khoảng thời gian.
    Thì bước 1 `404` ERR-17-001, thân giống "không tồn tại" trừ `traceId`, không cấp phiếu. Bước 2 không có bản ghi của T90.
