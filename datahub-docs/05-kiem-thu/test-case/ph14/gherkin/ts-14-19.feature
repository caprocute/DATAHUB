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
