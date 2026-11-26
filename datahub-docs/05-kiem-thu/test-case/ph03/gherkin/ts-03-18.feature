# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-18
Tính năng: TS-03-18 · Nút gateway và đồng bộ consumer

  @TC-03-078 @P1 @Dương
  Kịch bản: TC-03-078 Danh sách và chi tiết nút: phiên bản, lệch cấu hình, sức khỏe
    # Truy vết: FR-03-045 · API-03-063, 064 · UI-03-11 · UC-03-22 · ERR-03-001, 026 · BR-03-016 · NFR-03-021 · LGC-APIM-023; 024, 025.
    Biết 6 nút (3 `apisix-ext`, 3 `apisix-int`); U-PO; U-T68-VW; một nút cố ý chậm một phiên bản.
    Khi `GET /nodes`.
    Và `GET /nodes/{nodeId}` của nút chậm.
    Và `GET /nodes/khong-co`.
    Và ngắt `SIM-PH13`; `GET /nodes/{nodeId}`.
    Thì bước 1 `200`, mỗi nút có `zone`, `gate`, `version`, `inSync`, CPU, bộ nhớ, số lượt gọi (chỉ số APISIX, không JVM). Bước 2 `inSync = false`, `lag = 1`. Bước 3 404-ẩn. Bước 4 `503` ERR-03-026 "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau." (phần cấu hình vẫn trả).

  @TC-03-079 @P1 @Dương
  Kịch bản: TC-03-079 Đồng bộ consumer từ PH-01: tạo, đổi, gỡ, hiệu lực ≤ 60 giây
    # Truy vết: FR-03-046 · API-03-013, 014, 015, 011, 012, 016 · UI-03-04, 05 · UC-03-23 · EVT-03-04 · BR-03-021, 022, 029 · LGC-APIM-019; 020.
    Biết S-SYNC; client mới `ht-moi` ở Keycloak.
    Khi `PUT /consumers/ht-moi` `{tenant: T68, httt: HT-MOI, tier, group}` kèm `Idempotency-Key`; lặp lại để cập nhật.
    Và `PUT /consumers/ht-moi/credentials` với khóa công khai và dấu vân tay chứng thư.
    Và gọi API bằng client mới.
    Và `DELETE /consumers/ht-moi` khi không còn đăng ký.
    Và U-T68-VW `GET /consumers`, `GET /consumers/ht-moi`.
    Thì bước 1 `201` rồi `200`. Bước 2 `200`, không nhận khóa riêng. Bước 3 gọi được ≤ 60 s. Bước 4 `204`; gọi lại `401` mã 103 ≤ 60 s. Bước 5 danh sách và chi tiết đúng. EVT: `consumer.state-changed` mỗi lần. KT: có (`CONSUMER_SYNC`).

  @TC-03-080 @P1 @Âm
  Kịch bản: TC-03-080 Đồng bộ consumer lỗi: trùng, sai dữ liệu, còn đăng ký, thiếu scope, mã không dùng lại
    # Truy vết: FR-03-046 · API-03-013, 014, 015 · ERR-03-002, 003, 017, 022, 001 · BR-03-022, 029.
    Biết S-SYNC; consumer `ht-ndxp` còn 2 đăng ký hiệu lực; `ht-cu` đã gỡ; U-T68-TA.
    Khi `PUT /consumers/ht-cu` (mã đã gỡ).
    Và `PUT /consumers/ht-x` thiếu `tenant`; credentials có khóa không phải khóa công khai.
    Và `DELETE /consumers/ht-ndxp`.
    Và U-T68-TA `PUT /consumers/ht-y`.
    Và `DELETE /consumers/khong-co`.
    Thì bước 1 `409` ERR-03-002 "Mã ht-cu đã được dùng. Chọn mã khác." Bước 2 `400` ERR-03-003. Bước 3 `409` ERR-03-017 "HTTT còn 2 đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ." Bước 4 403-PQ (chỉ dịch vụ có `gateway:sync`). Bước 5 404-ẩn.

  @TC-03-081 @P1 @Dương
  Kịch bản: TC-03-081 Tạm ngừng HTTT ở PH-01 kéo theo mọi consumer
    # Truy vết: FR-03-046 · API-03-013, 012 · UI-03-04, 05 · UC-03-23 · ERR-03-127 · EVT-03-04 · BR-03-021, 022.
    Biết HTTT `HT-2C` có hai client `ht-2c-a`, `ht-2c-b` đang gọi.
    Khi PH-01 tạm ngừng `HT-2C` (S-SYNC cập nhật trạng thái).
    Và gọi bằng cả hai client; đo thời gian.
    Và PH-01 mở lại.
    Thì bước 2 cả hai `403` Lỗi GW 127 ≤ 60 s. Bước 3 cả hai gọi được ≤ 60 s. `GET /consumers/ht-2c-a` hiện trạng thái đúng.
