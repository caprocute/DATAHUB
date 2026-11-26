# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-03
Tính năng: TS-15-03 · Trang chủ, duyệt, lọc, dịch vụ sự kiện

  @TC-15-016 @P1 @Dương
  Kịch bản: TC-15-016 Trang chủ theo nhận diện tenant
    # Truy vết: FR-15-003 · UC-15-01 · API-15-001, 002 · UI-15-01 · BR-15-032 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN và U-ANON (`15.public.enabled = true`); nhận diện T68 đã đặt.
    Khi mở `/` ở hai vai.
    Thì có tên cổng, logo, lời chào của T68; khối API nổi bật, tin mới, lối vào tài liệu, ứng dụng; ẩn danh chỉ thấy phần công khai (`/public/home`); không thay màu, phông, vật liệu kính.

  @TC-15-017 @P3 @Biên
  Kịch bản: TC-15-017 Tenant chưa có API: hướng dẫn công bố cho chủ dịch vụ
    # Truy vết: FR-15-003 · UC-15-01 · UI-15-01 · FR-15-047 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tenant T90 có bản sao danh mục rỗng; U-T68-SV (chuyển sang T90) và DEV T90.
    Khi mở `/` bằng chủ dịch vụ rồi bằng nhà phát triển.
    Thì chủ dịch vụ thấy hướng dẫn liên hệ đầu mối và lối vào "Công bố API"; nhà phát triển chỉ thấy hướng dẫn liên hệ.

  @TC-15-018 @P1 @Dương
  Kịch bản: TC-15-018 Lọc, sắp xếp, phân trang, facet
    # Truy vết: FR-15-004 · UC-15-01 · API-15-005, 006 · UI-15-02 · LGC-APIM-006.
    Biết U-T68-OR; F-CAT mở rộng 60 API.
    Khi `GET /catalog/apis?linh-vuc=tu-phap&chu-quan=STP68&xac-thuc=oauth2&sap-xep=ten&trang=2&co=20`.
    Và `GET /catalog/facets` với cùng bộ lọc.
    Và mở UI-15-02, đặt bộ lọc, nạp lại trang bằng F5.
    Thì kết quả và phân trang đúng; số ở facet bằng số bản ghi lọc được; thứ tự theo tên tiếng Việt; bộ lọc còn nguyên trên URL sau F5; kết quả rỗng là `200` kèm "Không có dịch vụ nào khớp. Thử bỏ bớt bộ lọc.".

  @TC-15-019 @P1 @Âm
  Kịch bản: TC-15-019 Giá trị lọc sai miền
    # Truy vết: FR-15-004 · API-15-005 · ERR-15-003 · LGC-APIM-006.
    Biết U-T68-OR.
    Khi `GET /catalog/apis?co=7`, `?linh-vuc=khong-ton-tai`, `?loai=XYZ`, `?sap-xep=;drop`.
    Thì mỗi lần `400` ERR-15-003 kèm `errors[]` trỏ tham số sai; không `500`; `co` chỉ nhận 10, 20, 50, 100.

  @TC-15-020 @P2 @Dương
  Kịch bản: TC-15-020 Dịch vụ sự kiện và topic ngoài tầm
    # Truy vết: FR-15-007 · UC-15-01 · API-15-013, 014, 018 · UI-15-02, 04 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết topic `ho-tich.moi-dang-ky` (AsyncAPI 3.0) ở T68; topic `rieng-t01` chỉ ở T01; U-T68-OR.
    Khi `GET /catalog/topics`; `GET /catalog/topics/ho-tich.moi-dang-ky`; `GET .../events`.
    Và `GET /catalog/topics/rieng-t01`.
    Thì bước 1 có nhãn "Dịch vụ sự kiện", kênh và lược đồ thông điệp; bước 2 `404` ERR-15-001. Lọc `loai=EVENT` ở UI-15-02 chỉ thấy topic.

  @TC-15-021 @P3 @Dương
  Kịch bản: TC-15-021 Nhãn trạng thái, mục đã ngừng và tạm ngừng
    # Truy vết: FR-15-004, 006 · API-15-005 · UI-15-02 · BR-15-002 · LGC-APIM-006; LGC-APIM-017; LGC-IAM-006.
    Biết `dich-vu-cu` DEPRECATED, `tra-cuu-tam-ngung` SUSPENDED, `ban-do-cu` RETIRED.
    Khi duyệt mặc định rồi bật `da-ngung=true`.
    Thì mặc định không có `ban-do-cu`; hai mục còn lại có nhãn "Ngừng khuyến nghị", "Tạm ngừng"; bật bộ lọc hiện `ban-do-cu` trong mục "Đã ngừng" và không có đặc tả.
