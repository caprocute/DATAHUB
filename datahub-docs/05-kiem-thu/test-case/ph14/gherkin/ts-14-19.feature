# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-19
Tính năng: TS-14-19 · Theo dõi hạn chứng thư, chuỗi tin cậy, danh sách thu hồi

  @TC-14-048 @P1 @Dương @Biên
  Kịch bản: TC-14-048 Cảnh báo hạn và chuyển sang chứng thư thay thế
    # Truy vết: FR-14-029 · API-14-029, 031 · UC-14-19 · UI-14-08 · BR-14-017 · NFR-14-018.
    Biết K-HET (còn 5 ngày) và K-KY-02 `ACTIVE`; đồng hồ giả lập.
    Khi đặt đồng hồ tại các mốc 60, 30, 7 ngày trước hạn K-KY-01.
    Và tiến quá `notAfter` của K-HET.
    Thì cảnh báo ba mức ≤ 2 phút mỗi mốc; `EXPIRING → EXPIRED`; việc ký tự dùng chứng thư thay thế, không lượt nào bị chặn; đếm ngược hiển thị đúng ở UI-14-08.

  @TC-14-049 @P2 @Dương @Biên
  Kịch bản: TC-14-049 Làm mới chuỗi tin cậy và CRL; CRL quá hạn
    # Truy vết: FR-14-030 · API-14-035, 036 · UC-14-20 · ERR-14-110 · BR-14-002.
    Biết U-T68-SO; CRL của `sim-ndxp` nạp được; `14.crl.max-age-days = 7`; chế độ `SOFT` rồi `HARD`.
    Khi `POST /trust-store:refresh`; `GET /trust-store`.
    Và chặn tải CRL 8 ngày; gọi dịch vụ ở `SOFT`, đổi `14.crl.fail-mode = HARD` (bốn mắt), gọi lại.
    Và thu hồi chứng thư của `sim-ndxp` trong CRL.
    Thì bước 1 cập nhật thời điểm; bước 2 `SOFT` vẫn xác minh kèm cảnh báo mức cao, `HARD` `502` ERR-14-110; bước 3 phản hồi bị từ chối ERR-14-110.

  @TC-14-050 @P1 @Âm
  Kịch bản: TC-14-050 Chứng thư hết hạn không còn thay thế; chuỗi tin cậy bị sửa
    # Truy vết: FR-14-029, 030 · API-14-036, 075 · ERR-14-113, 019, 007 · BR-14-017, 018.
    Biết U-T68-SO; K-HET là chứng thư ký duy nhất; nguồn chuỗi tin cậy giả có chữ ký sai.
    Khi đồng hồ giả lập tiến quá `notAfter` của K-HET; gọi dịch vụ ký.
    Và `POST /trust-store:refresh` với nguồn chữ ký sai.
    Và thêm chứng thư neo tin cậy khi người duyệt trùng người đề nghị.
    Thì bước 1 `503` ERR-14-113, nền tảng bị chặn ký và có cảnh báo; bước 2 `422` ERR-14-019, chuỗi cũ giữ nguyên; bước 3 `403` ERR-14-007.

  @TC-14-117 @P1 @Âm
  Kịch bản: TC-14-117 Thu hồi, xóa chứng thư: thiếu lý do, trạng thái cuối, còn dùng xác minh
    # Truy vết: FR-14-029 · API-14-034, 092 · ERR-14-003, 004, 022 · BR-14-017, 019 · PERM-14-cert.
    Biết U-T68-SO, U-T68-TA; chứng thư `tc-cert-het` `EXPIRED` còn giao dịch trong thời hạn lưu; `tc-cert-cu` `SUPERSEDED`; `tc-cert-moi` `UPLOADED` chưa từng `ACTIVE`; K-KY-01 `ACTIVE`.
    Khi `POST /certificates/K-KY-01:revoke` không có `reason`.
    Và `POST /certificates/tc-cert-cu:revoke`.
    Và `DELETE /certificates/tc-cert-het`.
    Và `DELETE /certificates/K-KY-01`.
    Và U-T68-TA gọi `POST …:revoke`.
    Và `DELETE /certificates/tc-cert-moi`.
    Thì bước 1 `400` ERR-14-003 "Nhập lý do thu hồi." Bước 2 `409` ERR-14-004 "Chứng thư đã hết hạn, bị thu hồi hoặc được thay thế." Bước 3 `409` ERR-14-022 "Chứng thư này còn được dùng để xác minh giao dịch trong thời hạn lưu nên không xóa được." Bước 4 `409` ERR-14-004 (chứng thư từng `ACTIVE` không xóa được). Bước 5 `403`. Bước 6 `204` (chỉ chứng thư `UPLOADED` chưa từng `ACTIVE` mới xóa được). Chứng thư hết hạn vẫn được giữ.

  @TC-14-118 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-118 Chuỗi tin cậy: neo không hợp lệ, CRL chữ ký sai, tự duyệt, tải CRL lỗi
    # Truy vết: FR-14-030 · API-14-035, 036 · UC-14-20 · ERR-14-007, 019 · BR-14-002, 018 · NFR-14-018.
    Biết U-T68-SO, U-T68-IA; tệp neo hỏng `tc-neo-hong.pem`; máy chủ CRL giả lập ký sai hoặc không phản hồi; `14.crl.max-age-days = 7`; `Clock` giả lập.
    Khi đề nghị thêm neo tin cậy bằng tệp hỏng.
    Và SO tự duyệt đề nghị thêm neo hợp lệ do chính mình tạo.
    Và `POST /trust-store:refresh` khi CRL có chữ ký sai.
    Và cho máy chủ CRL không phản hồi, chờ 3 lần thử cách nhau 5 phút, rồi tiến `Clock` 8 ngày.
    Thì bước 1 `422` ERR-14-019 "Chứng thư neo không đọc được." Bước 2 `403` ERR-14-007, neo không được thêm. Bước 3 bản tải về bị bỏ, `crlLastRefreshedAt` không đổi, có cảnh báo. Bước 4 sau 3 lần thử lại có cảnh báo vận hành; quá 7 ngày có cảnh báo mức cao, `national_crl_age_seconds` tăng; không có mã lỗi cho người dùng. Chuỗi tin cậy hiện hành không bị thay đổi.
