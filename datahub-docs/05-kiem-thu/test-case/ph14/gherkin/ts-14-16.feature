# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-16
Tính năng: TS-14-16 · Token OAuth 2.1, xoay vòng thông tin xác thực

  @TC-14-040 @P1 @Dương
  Kịch bản: TC-14-040 Thử token và làm mới trước hạn
    # Truy vết: FR-14-024 · API-14-040 · UI-14-03 · UC-14-16 · LGC-NGSP-008 · BR-14-005.
    Biết U-T68-TO; token `sim-ndxp` sống 120 giây; `14.token.refresh-before-seconds = 60`.
    Khi `POST /platforms/ndxp/token:test`.
    Và đồng hồ giả lập tiến 61 giây; gọi dịch vụ.
    Thì bước 1 `200` chỉ có hạn dùng, không có giá trị token; bước 2 token mới được lấy trước khi gọi, không có lượt nào dùng token hết hạn.

  @TC-14-041 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-041 Xoay vòng thông tin xác thực, cửa sổ chuyển tiếp
    # Truy vết: FR-14-025 · API-14-039 · UC-14-17 · BR-14-005 · NFR-14-015 · SEC-31.
    Biết U-T68-TA (đã xác thực lại); `14.secret.overlap-hours = 24`; giá trị mồi `DH-CANARY-KEY-…`.
    Khi `POST /platforms/ndxp/credentials:rotate` kèm giá trị mới (ghi một chiều).
    Và gọi dịch vụ liên tục trong 5 phút; `GET /platforms/ndxp`.
    Và dò mồi ở phản hồi, nhật ký, PostgreSQL.
    Thì không lượt gọi nào hỏng khi chuyển; chỉ có siêu dữ liệu phiên bản và ngày xoay; không tìm thấy mồi ngoài OpenBao; cảnh báo xoay đúng theo `14.secret.max-age-days`.

  @TC-14-042 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-14-042 Thông tin xác thực chưa đặt, OpenBao lỗi, nền tảng từ chối
    # Truy vết: FR-14-024, 025 · API-14-039, 040 · ERR-14-034, 035, 114, 004 · BR-14-031.
    Biết `ndxp-moi` chưa đặt thông tin xác thực; `sim-ndxp` `AUTH401`; dừng OpenBao.
    Khi `:test` token cho `ndxp-moi`.
    Và gọi dịch vụ khi `AUTH401` liên tiếp 3 lần trong 5 phút.
    Và dừng OpenBao, `:rotate`.
    Thì bước 1 `422` ERR-14-034; bước 2 `502` ERR-14-114, chỉ thử lại một lần trong 5 phút; bước 3 `503` ERR-14-035, không có giá trị nào lưu ra nơi khác.
