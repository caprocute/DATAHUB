# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-23
Tính năng: TS-03-23 · Nhập cấu hình từ gateway cũ

  @TC-03-095 @P1 @Dương
  Kịch bản: TC-03-095 Nhập gói cấu hình Gravitee: phân tích và áp thành nháp
    # Truy vết: FR-03-059 · API-03-091, 092, 093 · UI-03-18 · UC-03-31 · BR-03-014, 029 · LGC-APIM-002…005, 009…015, 019…021.
    Biết U-T68-TA; `F-LEGACY-OK` gồm 12 API, 20 plan, 15 Application có khóa API đã làm sạch.
    Khi `POST /migrations/legacy-gateway:import` tải tệp, `Idempotency-Key`.
    Và `GET /migrations/legacy-gateway/{importId}` đến khi `DONE`.
    Và `POST …/{importId}:apply`.
    Và `GET /routes`, `GET /plan-policies`; `POST /snapshots:validate`.
    Thì bước 1 `202`. Bước 2 báo cáo từng mục: plan Keyless hoặc API key, rate limit, quota, whitelist, blacklist, plan Policies đều có đề xuất tương đương; mục không map được nêu lý do. Bước 3 `200`, tạo route và chính sách ở trạng thái nháp, không tự phát hành; không có khóa API cũ nào được chép. Bước 4 đối tượng nháp có mặt; `validate` nêu việc còn phải làm (lược đồ, OPA). KT: có (`LEGACY_IMPORT`, `LEGACY_APPLY`).

  @TC-03-096 @P2 @Âm @Bảo @mật
  Kịch bản: TC-03-096 Gói cũ hỏng, thiếu trường, bị bộ quét từ chối; áp lần hai
    # Truy vết: FR-03-059 · API-03-091, 092, 093 · ERR-03-020, 003, 019, 001, 022 · BR-03-014.
    Biết `F-LEGACY-BAD`; tệp chứa mã thực thi; tệp 100 MiB; U-T68-VW.
    Khi nhập `F-LEGACY-BAD` rồi xem kết quả.
    Và nhập tệp có mã thực thi và tệp quá cỡ.
    Và `:apply` hai lần cùng `importId`; `:apply` mã lạ.
    Và thiếu tệp; U-T68-VW nhập.
    Thì bước 1, 2 `422` ERR-03-020 "Gói cấu hình hệ cũ không đọc được: {lý do}." kèm `errors[]`. Bước 3 lần hai `409` ERR-03-019; mã lạ 404-ẩn. Bước 4 `400` ERR-03-003; 403-PQ. Không đối tượng nào được tạo.
