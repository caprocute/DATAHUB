# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-27
Tính năng: TS-15-27 · Nhận diện và tham số cổng theo tenant

  @TC-15-155 @P1 @Dương
  Kịch bản: TC-15-155 Đặt nhận diện cổng
    # Truy vết: FR-15-056 · UC-15-29 · API-15-116, 117, 118, 139 · UI-15-25 · BR-15-032 · LGC-APIM-007.
    Biết U-T68-TA; logo PNG 200 KB, 256 px; U-ANON.
    Khi `PUT /admin/branding` {tên cổng, liên kết HTTPS, chân trang, lời chào}; `POST /admin/branding/logo`.
    Và khách `GET /public/branding`; mở `/`.
    Thì `200`; khách thấy tên, logo, chân trang mới ≤ 60 giây; KT: có (`CHANGE_SETTING`); màu, phông, token, vật liệu kính không đổi; không tenant khác bị ảnh hưởng.

  @TC-15-156 @P2 @Âm
  Kịch bản: TC-15-156 Logo sai, liên kết không HTTPS, trường ngoài miền
    # Truy vết: FR-15-056 · API-15-117, 118 · ERR-15-003, 006, 033 · BR-15-032 · LGC-APIM-007.
    Biết logo SVG, logo 600 KB, logo 100 px, liên kết `http://`, trường `primaryColor`.
    Khi tải từng logo.
    Và `PUT` liên kết `http://`; `PUT` có `primaryColor`; `PUT` với `If-Match` cũ.
    Thì `422` ERR-15-033 (ba logo, liên kết); `400` ERR-15-003 (`primaryColor`, giả định); `412` ERR-15-006.

  @TC-15-157 @P1 @Dương
  Kịch bản: TC-15-157 Đổi tham số có hiệu lực
    # Truy vết: FR-15-057 · UC-15-29 · API-15-119, 120 · UI-15-25 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-TA; `15.app.max-per-user` 10, `15.public.enabled` `false`.
    Khi `PUT /admin/settings` đặt `15.app.max-per-user = 3`, `15.public.enabled = true`.
    Và tạo ứng dụng thứ 4; mở cổng khi ẩn danh.
    Thì hiệu lực trong 60 giây; ứng dụng thứ 4 `422` ERR-15-015; ẩn danh vào được phần công khai; KT: có (`CHANGE_SETTING`) ghi giá trị cũ, mới.

  @TC-15-158 @P1 @Âm
  Kịch bản: TC-15-158 Ngoài miền, vượt trần, thiếu quyền
    # Truy vết: FR-15-057 · API-15-120 · ERR-15-005, 006, 034 · BR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hà; An, Chi, Bình, Khánh (không `PERM-15-portal-admin`).
    Khi `15.cred.ttl-days = 181`; `15.sync.interval-seconds = 30`; `15.try.prod-max-days = 91`.
    Và `If-Match` cũ.
    Và an, Chi, Bình, Khánh `PUT`.
    Thì `422` ERR-15-034 "Giá trị của 15.cred.ttl-days phải trong khoảng 30 đến 180" cho từng khóa; `412` ERR-15-006; bốn người `403` ERR-15-005; giá trị cũ giữ nguyên.
