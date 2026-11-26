# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-22
Tính năng: TS-12-22 · Chứng thư, khóa công khai và xoay bí mật client

  @TC-12-066 @P1 @Dương @Âm
  Kịch bản: TC-12-066 Đăng ký chứng thư và JWKS hợp lệ, không hợp lệ
    # Truy vết: FR-12-033 · UC-12-24 · UI-12-10 · API-12-064, 065 · ERR-12-021 · BR-12-024 · LGC-BUS-041
    Biết C-T68-A; F-CERT-OK, F-CERT-BAD.
    Khi `PUT …/credentials/certificate` bằng F-CERT-OK rồi F-CERT-BAD (hết hạn).
    Và `PUT …/credentials/jwks` hợp lệ rồi chứa khóa riêng.
    Thì hợp lệ `200`; F-CERT-BAD và JWKS có khóa riêng bị `422` ERR-12-021; KT: có.

  @TC-12-067 @P1 @Dương @Bảo @mật
  Kịch bản: TC-12-067 Xoay bí mật: giao một lần, chuyển tiếp, không lộ
    # Truy vết: FR-12-034 · UC-12-24 · UI-12-10 · API-12-066 · BR-12-023 · ERR-12-023 · ERR-12-039 · NFR-12-020
    Biết C-T68-B; mồi `DH-CANARY-rot`; OpenBao.
    Khi `:rotate` lấy liên kết bọc dùng một lần; mở hai lần.
    Và trong thời gian chuyển tiếp gọi lại `:rotate`; dùng cả bí mật cũ và mới.
    Và tắt OpenBao; gọi `:rotate`.
    Thì lần mở thứ hai thất bại; bước 2 `409` ERR-12-023, cả hai bí mật dùng được trong chuyển tiếp rồi bí mật cũ hết hiệu lực; bước 3 `503` ERR-12-039; bí mật không có trong phản hồi API, log, CSDL (mồi sạch).
