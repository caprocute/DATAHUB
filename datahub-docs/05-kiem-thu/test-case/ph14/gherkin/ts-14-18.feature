# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-18
Tính năng: TS-14-18 · Chứng thư số: nạp và kích hoạt

  @TC-14-046 @P1 @Dương
  Kịch bản: TC-14-046 Nạp, yêu cầu kích hoạt, duyệt bốn mắt
    # Truy vết: FR-14-028 · API-14-029, 030, 031, 032, 033 · UI-14-08, 17 · UC-14-18 · BR-14-018.
    Biết U-T68-SO, U-T68-IA; K-KY-02 hợp lệ, khóa đã ở OpenBao.
    Khi `POST /certificates` nạp K-KY-02; `GET /certificates/{certCode}`.
    Và SO `:request-activation`; IA `:approve-activation`.
    Thì `UPLOADED → PENDING_ACTIVATION → ACTIVE`; chi tiết không có khóa riêng; K-KY-01 chuyển `SUPERSEDED` sau cửa sổ `14.cert.overlap-hours`.

  @TC-14-047 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-047 Chứng thư lỗi: ngoài chuỗi, lệch khóa, chưa/hết hiệu lực, còn dùng xác minh
    # Truy vết: FR-14-028 · API-14-030, 032, 034 · ERR-14-019, 020, 021, 022, 007 · BR-14-018, 019.
    Biết tệp hỏng; chứng thư ngoài chuỗi; chứng thư khác khóa OpenBao; chứng thư `notBefore` ở tương lai; K-KY-01 còn dùng xác minh giao dịch trong hạn lưu.
    Khi nạp từng tệp trên.
    Và U-T68-SO tự duyệt yêu cầu của mình.
    Và thu hồi K-KY-01 rồi yêu cầu xóa bản ghi.
    Thì `422` ERR-14-019 (hai lần), `422` ERR-14-020, `409` ERR-14-021; bước 2 `403` ERR-14-007; bước 3 thu hồi được nhưng xóa `409` ERR-14-022, bản ghi vẫn giữ.
