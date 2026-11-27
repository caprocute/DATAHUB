# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-15
Tính năng: TS-20-15 · Thu thập sử dụng tài nguyên và cảnh báo ngưỡng hạn mức

  @TC-20-066 @P1 @Dương
  Kịch bản: TC-20-066 Thu sử dụng theo giờ, lũy đẳng, đọc bù
    # Truy vết: FR-20-028 · UC-20-15 · NFR-20-008 · API-20-056, 057 · BR-20-016 · `PERM-20-read` · `20.usage.retention-months`
    Biết `T96`, `T90`; `obs-sim` (Mimir giả) trả số đo theo F-USAGE; `20.usage.snapshot-interval` = PT1H; `clock-sim`.
    Khi đẩy `clock-sim` một giờ, chạy bộ lập lịch
    Và chạy lại bộ lập lịch cùng giờ lần hai
    Và cài `obs-sim` thiếu số đo của `OBJECT_STORAGE_GB` một giờ, giờ sau trả lại
    Và `GET P/tenants/T96/usage?resource=API_RPS&granularity=HOUR`
    Thì bước 1 mỗi tài nguyên một dòng `usage_snapshot` có hạn mức hiệu lực tại giờ đó và phần trăm, trễ ≤ 15 phút (NFR-20-008). Bước 2 không nhân bản nhờ khóa duy nhất (`tenant_id`, `resource`, `hour_start`). Bước 3 giờ thiếu có `quality = MISSING`, giờ sau đọc bù lại tối đa 24 giờ trước. Bước 4 trả đúng chuỗi theo giờ.

  @TC-20-067 @P2 @Âm @Chịu @lỗi
  Kịch bản: TC-20-067 Nguồn số đo lỗi, thiếu quá 3 giờ, tenant đã chấm dứt
    # Truy vết: FR-20-028 · NFR-20-008 · ERR-20-006, ERR-20-062, ERR-20-110 · UC-20-15 · UI-20-06
    Biết `obs-sim` ngừng; `T88` `DECOMMISSIONED`; `U-PO`.
    Khi chạy bộ lập lịch khi Mimir không khả dụng
    Và giữ ngừng quá 3 giờ liên tiếp (`clock-sim`)
    Và yêu cầu thu bổ sung cho `T88`
    Thì bước 1 cả lượt `MISSING` với `ERR-20-062` ở nhật ký, không phát cảnh báo hạn mức giả. Bước 2 `ERR-20-110` ("Thiếu số liệu sử dụng API_RPS của T96 từ 09:00"), cảnh báo `U-PO` ở UI-20-06. Bước 3 `409` `ERR-20-006`.

  @TC-20-068 @P1 @Dương
  Kịch bản: TC-20-068 Cảnh báo 80 % và 100 %, khử lặp, đặt lại
    # Truy vết: FR-20-029 · UC-20-15 · BR-20-016 · NFR-20-009 · EVT-20-06 · UI-20-06 · `PERM-20-quota`
    Biết `T96` theo F-QUOTA (`API_RPS` 400/500, `ACTIVE_FLOWS` 1.000/1.000); `20.quota.warn-percent` = 80; `20.quota.alert-reset-percent` = 75; `ops-sim`.
    Khi thu số đo giờ đầu
    Và thu số đo `API_RPS` = 410 giờ sau
    Và đưa `API_RPS` xuống 370 và giữ 24 giờ liên tục
    Và `GET P/quota-alerts?tenantCode=T96`
    Thì bước 1 `API_RPS` 80 % tạo cảnh báo `WARN_80` `OPEN` và `ACTIVE_FLOWS` 100 % tạo `LIMIT_100`; EVT: `platform.tenant.quota-threshold-reached.v1` mỗi cảnh báo một lần, ≤ 5 phút sau thu số đo; thông báo qua PH-18 tới PO và đầu mối `TECHNICAL`, `TENANT_ADMIN`. Bước 2 cập nhật `lastAt`, không gửi lặp. Bước 3 sau 24 giờ dưới 75 % (370/500 = 74 %) cảnh báo `CLEARED`. Bước 4 liệt kê đúng.

  @TC-20-069 @P2 @Dương @Âm
  Kịch bản: TC-20-069 Xác nhận cảnh báo hợp lệ và không hợp lệ
    # Truy vết: FR-20-029 · API-20-058, 059 · ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009 · UI-20-06 · `PERM-20-quota`
    Biết `U-PA1`, `U-PO`; cảnh báo `OPEN` của `T96`; cảnh báo `CLEARED`.
    Khi `POST P/quota-alerts/{alertId}:acknowledge` với `comment`
    Và xác nhận lại cùng cảnh báo với khóa chống lặp khác
    Và `POST` cảnh báo `CLEARED`
    Và `POST` mã cảnh báo không có
    Và `U-PO` gọi `POST ...:acknowledge`
    Và `GET P/quota-alerts?alertLevel=KHONG`
    Và dùng lại `Idempotency-Key` của bước 1 cho một cảnh báo khác
    Thì bước 1 `200`, `acknowledgedBy`, `acknowledgedAt`. Bước 2 `409` `ERR-20-006`. Bước 3 `409` `ERR-20-006`. Bước 4 `404` `ERR-20-002`. Bước 5 `403` `ERR-00-403` (PO không có `PERM-20-quota`). Bước 6 `400` `ERR-20-004`. Bước 7 `409` `ERR-20-009`.
