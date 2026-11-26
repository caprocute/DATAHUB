# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-02
Tính năng: TS-15-02 · Mức hiển thị theo người xem và truy cập ẩn danh

  @TC-15-007 @P1 @Dương
  Kịch bản: TC-15-007 Ma trận bốn hạng người xem × F-CAT
    # Truy vết: FR-15-002 · UC-15-01 · API-15-003, 005 · UI-15-02 · BR-15-002, 004, 005 · LGC-APIM-007.
    Biết F-CAT (11 mục, mục 2.3); `15.public.enabled = true`; U-T68-OR, U-T68-DEV-AN, U-T01-USER, U-ANON.
    Khi mỗi hạng gọi `GET /catalog/apis?co=100` (ANON gọi `/public/catalog/apis`).
    Và lặp ở UI-15-02 và so số mục với API.
    Thì số mục: cán bộ T68 (TENANT_USER) 8 (`tra-cuu-ho-tich`, `tra-cuu-dat-dai`, `dm-hanh-chinh`, `thoi-tiet-cong-khai`, `thoi-tiet-noi-bo`, `bao-cao-noi-bo`, `dich-vu-cu`, `tra-cuu-tam-ngung`); nhà phát triển `dh-dev` 7 (không có `tra-cuu-dat-dai` SENSITIVE); cán bộ T01 qua NATIONAL 4 (`dm-hanh-chinh`, `thoi-tiet-cong-khai`, `thoi-tiet-noi-bo`, `dich-vu-cu`); ẩn danh 2 (`thoi-tiet-cong-khai`, `dich-vu-cu`: vừa `PUBLIC` vừa dataClass `PUBLIC`). `an-khoi-cong`, `ban-do-cu` không có mặt ở cả bốn. UI khớp API. Ba cách hiển thị (API, UI, tìm kiếm) cho cùng kết quả.

  @TC-15-008 @P1 @Âm
  Kịch bản: TC-15-008 API ngoài tầm trả như không tồn tại ở mọi đường
    # Truy vết: FR-15-002 · UC-15-01 · API-15-004, 007, 008, 011, 012, 015, 016 · ERR-15-001 · BR-15-002 · NFR-15-017 · LGC-APIM-007.
    Biết U-T68-DEV-AN; `an-khoi-cong` (`portalPublished = false`), `tra-cuu-dat-dai` (SENSITIVE), mã không có `khong-co-that`.
    Khi với từng mã ở D, gọi chi tiết, `/usage`, `/versions`, `/versions/1.0.0/spec`, `/search?q={mã}`, `/search/suggest?q={mã}`.
    Và so thân phản hồi của mã ngoài tầm với mã không có thật.
    Thì mọi đường `404` ERR-15-001; thân giống hệt nhau trừ `traceId`, `instance`; tìm kiếm và gợi ý không có mục; tổng số kết quả không đếm mục ẩn.

  @TC-15-009 @P1 @Dương
  Kịch bản: TC-15-009 Khách ẩn danh xem phần công khai, không lộ thông tin nội bộ
    # Truy vết: FR-15-008 · UC-15-01 · API-15-003, 004, 010 · UI-15-01, 02, 04 · BR-15-005, 006 · LGC-APIM-007.
    Biết `15.public.enabled = true`; U-ANON.
    Khi `GET /public/catalog/apis`, `GET /public/catalog/apis/thoi-tiet-cong-khai`.
    Và mở UI-15-04 của API đó khi chưa đăng nhập; tìm `q=thời tiết` ở `/public/search`.
    Thì `200`; chi tiết không có địa chỉ backend, danh sách bên đăng ký, bí mật hay thông tin đầu mối cá nhân; không có nút Thử API và Đăng ký sử dụng, thay bằng lời mời đăng nhập; tìm kiếm chỉ trả mục và trang công khai.

  @TC-15-010 @P1 @Âm
  Kịch bản: TC-15-010 Tenant chưa bật công khai: ẩn danh không thấy gì
    # Truy vết: FR-15-002, 008 · UC-15-01 · API-15-003, 004 · UI-15-02 · BR-15-005 · ERR-15-001 · LGC-APIM-007.
    Biết `15.public.enabled = false` (mặc định); U-ANON.
    Khi `GET /public/catalog/apis/thoi-tiet-cong-khai`.
    Và mở `/dich-vu` ở UI khi chưa đăng nhập.
    Thì bước 1 `404` ERR-15-001 (FR-15-008); bước 2 chuyển tới `/dang-nhap`, không hiện thông báo lỗi.

  @TC-15-011 @P1 @Âm
  Kịch bản: TC-15-011 Ẩn danh chạm API không đủ điều kiện công khai
    # Truy vết: FR-15-008 · UC-15-01 · API-15-004, 010 · ERR-15-001 · BR-15-005, 006 · LGC-APIM-007.
    Biết `15.public.enabled = true`; U-ANON; `tra-cuu-ho-tich` (TENANT), `dm-hanh-chinh` (NATIONAL), `thoi-tiet-noi-bo` (PUBLIC nhưng INTERNAL).
    Khi `GET /public/catalog/apis/{mã}` cho ba mã.
    Và `GET /public/search?q=hộ tịch`.
    Thì ba mã `404` ERR-15-001 cùng thân; tìm kiếm không trả mục nào ngoài hai mục công khai; trang nội dung `audience = TENANT` không có trong `/public/pages`.

  @TC-15-012 @P2 @Âm
  Kịch bản: TC-15-012 Vượt tần suất ẩn danh theo IP
    # Truy vết: FR-15-008, 005 · API-15-010 · ERR-15-007 · BR-15-005 · LGC-APIM-007.
    Biết `15.public.rate-limit-per-minute = 30`; U-ANON từ hai IP A, B.
    Khi IP A gọi `GET /public/search?q=a` 31 lần trong 1 phút.
    Và IP B gọi một lần.
    Thì lần 31 của A trả `429` ERR-15-007 kèm `Retry-After`; B `200`; qua phút kế A lại `200`.

  @TC-15-013 @P1 @Dương
  Kịch bản: TC-15-013 Cán bộ tỉnh khác chỉ thấy mức NATIONAL và PUBLIC
    # Truy vết: FR-15-002 · UC-15-01 · API-15-005, 007 · BR-15-002, 003 · ERR-15-001 · LGC-APIM-007.
    Biết U-T01-USER đăng nhập realm T01, vào tên miền cổng T68; F-CAT.
    Khi `GET /catalog/apis`.
    Và `GET /catalog/apis/tra-cuu-ho-tich`.
    Thì bước 1 đúng 4 mục (xem TC-15-007); bước 2 `404` ERR-15-001.

  @TC-15-014 @P3 @Dương
  Kịch bản: TC-15-014 Đăng nhập giữa chừng tính lại bộ lọc
    # Truy vết: FR-15-002 · UC-15-01 · UI-15-02 · BR-15-002 · LGC-APIM-007.
    Biết `15.public.enabled = true`; U-T68-DEV-AN.
    Khi khách mở `/dich-vu` thấy 2 mục.
    Và bấm Đăng nhập, đăng nhập An.
    Thì về lại `/dich-vu` (giữ bộ lọc trên URL), trang nạp lại, thấy 7 mục.

  @TC-15-015 @P1 @Dương
  Kịch bản: TC-15-015 Gỡ và đăng lại cờ `portalPublished` phản ánh ngay
    # Truy vết: FR-15-001, 002 · UC-15-04 · EVT-15-14 · BR-15-001, 002 · LGC-APIM-006; LGC-APIM-007.
    Biết S-PH02; `tra-cuu-ho-tich` đang hiển thị.
    Khi S-PH02 phát EVT-02-05 đặt `portalPublished = false`.
    Và sau 30 giây `GET /catalog/apis/tra-cuu-ho-tich`, tìm kiếm.
    Và S-PH02 đặt lại `true`.
    Thì bước 2: `404` và mất khỏi tìm kiếm (Unpublish); sau bước 3 hiện lại trong 30 giây (Publish).
