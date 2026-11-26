# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-28
Tính năng: TS-01-28 · Nhập HTTT từ hệ cũ, tham số phân hệ, thống kê

  @TC-01-108 @P1 @Dương
  Kịch bản: TC-01-108 Nhập hệ cũ: xem trước, gộp vai trò, tạo nháp
    # Truy vết: FR-01-048 · UC-01-32 · API-01-080, 081, 082 · UI-01-15 · BR-01-018, 033 · LGC-APIM-019; 020 · LGC-HUB-010, 011.
    Biết U-PA hoặc U-T68-TA1; F-LEGACY-OK (20 Application, 8 publisher, 6 subscriber trong đó 5 trùng tên Application).
    Khi `POST /legacy-imports` tải F-LEGACY-OK; `GET /legacy-imports/{jobId}`.
    Và xác nhận ghép tổ chức; `POST …:confirm`.
    Và `GET /systems?status=DRAFT`.
    Thì bước 1: xem trước nêu ghép tổ chức, gộp vai trò (Application + publisher, subscriber trùng thành một HTTT nhiều vai trò `CONSUMER`, `PUBLISHER`, `SUBSCRIBER`), số bí mật bỏ. Bước 2 và 3: các HTTT ở `DRAFT`, không tự `ACTIVE`, không định danh; mã bất biến; không có tệp gốc nào còn bí mật.

  @TC-01-109 @P1 @Âm
  Kịch bản: TC-01-109 Nhập hệ cũ sai: cấu trúc, trùng, vượt số dòng, sai quyền
    # Truy vết: FR-01-048 · API-01-080, 082 · ERR-01-042, 043, 044.
    Biết F-LEGACY-BAD, F-LEGACY-DUP; tệp 5.001 dòng; `legacyImport.maxRows = 5.000`; U-T68-OR1.
    Khi tải F-LEGACY-BAD; F-LEGACY-DUP; tệp 5.001 dòng.
    Và OR1 gọi `POST /legacy-imports`.
    Thì `400` ERR-01-042 nêu cột thiếu; `409` ERR-01-043 nêu bản ghi trùng; `422` ERR-01-044; `403-PQ`.

  @TC-01-110 @P1 @Bảomật
  Kịch bản: TC-01-110 Nhập hệ cũ không mang bí mật
    # Truy vết: FR-01-048 · API-01-080, 081 · BR-01-007, 033 · NFR-01-009.
    Biết F-LEGACY-SECRET có 12 cột bí mật mang giá trị `DH-CANARY-legacy-*`.
    Khi tải tệp; xem trước; xác nhận.
    Và tìm giá trị mồi ở mọi nơi.
    Thì `secretsDropped = 12`; Mồi sạch ở API, bảng PH-01, log, vết, outbox, tệp tải (tệp tạm bị xóa sau xử lý); định danh phải cấp lại qua kết nạp.

  @TC-01-111 @P1 @Dương @Âm
  Kịch bản: TC-01-111 Sửa tham số tenant có miền, lý do, MFA
    # Truy vết: FR-01-049 · UC-01-33 · API-01-083, 084 · UI-01-16 · BR-01-009, 014, 020 · ERR-01-033, 035, 044.
    Biết `T90`; TA của T90; U-PA; U-T68-OR1.
    Khi `PUT /settings/review.slaWorkingDays` giá trị 3, kèm lý do, MFA mới.
    Và gửi giá trị 11; không lý do; không MFA.
    Và OR1 gọi `PUT`; `GET /settings` bởi VW.
    Và PA đặt trần nền tảng thấp hơn; TA gửi giá trị vượt trần.
    Thì bước 1: `200`, hồ sơ nộp mới có hạn 3 ngày (không hồi tố hồ sơ cũ), lịch sử sửa có người, lý do. Bước 2: `422` ERR-01-044; `400` ERR-01-033; `403` ERR-01-035. Bước 3: `403-PQ`; `200`. Bước 4: `422` ERR-01-044.

  @TC-01-112 @P3 @Dương @Âm
  Kịch bản: TC-01-112 Thống kê kết nạp (Đợt 2)
    # Truy vết: FR-01-051 · UC-01-34 · API-01-086 · UI-01-17 · ERR-01-003.
    Biết 40 hồ sơ ở các giai đoạn; U-T68-VW.
    Khi `GET /statistics?tu=2026-01-01&den=2026-12-31`.
    Và gọi với khoảng sai (`tu` sau `den`).
    Thì `200` có thời gian trung bình từng giai đoạn, tỷ lệ trả bổ sung, hồ sơ quá hạn, đối chiếu KPI-05; số khớp chỉ số `onboarding_stage_duration_days`. Bước 2: `400` ERR-01-003.
