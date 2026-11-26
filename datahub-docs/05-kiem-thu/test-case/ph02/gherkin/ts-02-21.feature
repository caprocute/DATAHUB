# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-21
Tính năng: TS-02-21 · Thông báo thay đổi và thống kê

  @TC-02-064 @P1 @Dương @Biên @Âm
  Kịch bản: TC-02-064 Thông báo bắt buộc tới mọi bên liên quan; thông báo tay có trần
    # Truy vết: FR-02-057 · API-02-076, 077 · UI-02-13 · UC-02-33 · BR-02-029 · ERR-02-036, 014 · EVT-02-12 · NFR-02-015.
    Biết A-DEPREC có 3 HTTT đăng ký; bên nhận tắt thông báo trong hồ sơ; `02.notice.announcement-max-per-day` = 3.
    Khi phát sinh `:propose-deprecate`; xem `GET /change-notices`.
    Và gửi 4 thông báo tay trong một ngày.
    Thì cả 3 bên nhận trong ≤ 15 phút dù đã tắt, thư điện tử ≤ 1 giờ; thông báo tay thứ 4 `429` ERR-02-036.

  @TC-02-065 @P3 @Dương @Âm
  Kịch bản: TC-02-065 Thống kê sử dụng theo phiên bản và tenant
    # Truy vết: FR-02-058 · API-02-078, 079 · UI-02-11 · UC-02-34 · BR-02-033 · ERR-02-001, 014.
    Biết S-METRIC; số liệu gọi của A-DATDAI (Đợt 2).
    Khi `GET …/usage-stats`; `GET /usage-stats/summary` bằng S-METRIC.
    Và `GET /apis/tc-chi-t01/versions/1.0.0/usage-stats`; S-GW gọi `/usage-stats/summary`.
    Thì số lượt gọi, bên khai thác đúng; bước 2 404-ẩn và 403-PQ.

  @TC-02-135 @P2 @Âm @Bảo @mật
  Kịch bản: TC-02-135 Lịch sử thông báo thay đổi: bên nhận chỉ thấy phần của mình, cách ly tenant, lọc sai
    # Truy vết: FR-02-057 · API-02-076, 077 · UI-02-13 · UC-02-33 · BR-02-029, 033 · ERR-02-003, 014, 001.
    Biết thông báo bắt buộc và thông báo tay cho A-DATDAI (bên nhận H-KHAITHAC-1 và HTTT khác); thông báo của T01; U-T68-OR1, U-T68-VW, U-T68-SV2.
    Khi OR1 `GET /change-notices`.
    Và `GET /change-notices?from=2026-12-01&to=2026-11-01`; `type=KHONG-CO`.
    Và U-T68-SV2 (tổ chức khác chủ API) `POST /apis/tc-dat-dai/change-notices`.
    Và U-T68-VW `POST` thông báo tay.
    Thì bước 1: chỉ thấy thông báo gửi tới HTTT của OR1, không thấy danh sách bên nhận khác, không thấy của T01. Bước 2: `400` ERR-02-003. Bước 3, 4: `403` ERR-02-014, không phát thông báo nào.

  @TC-02-136 @P2 @Âm
  Kịch bản: TC-02-136 Thống kê sử dụng: khoảng thời gian sai, token máy sai scope, tenant khác
    # Truy vết: FR-02-058 · API-02-078, 079 · UI-02-11 · UC-02-34 · BR-02-033 · ERR-02-003, 001, 014.
    Biết S-METRIC (`catalog:metrics-read`), S-PORTAL; số liệu thống kê giả lập; A-T01.
    Khi `GET …/usage-stats?from=2026-12-01&to=2026-11-01`; khoảng dài hơn mức cho phép.
    Và S-PORTAL gọi `GET /usage-stats/summary`; S-METRIC gọi cùng operation.
    Và `GET /apis/tc-chi-t01/versions/1.0.0/usage-stats`.
    Thì bước 1: `400` ERR-02-003. Bước 2: S-PORTAL `403` ERR-02-014, S-METRIC `200` chỉ có số liệu T68. Bước 3: `404` ERR-02-001.
