# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-15
Tính năng: TS-03-15 · Cửa vào Internet, nội bộ và chuyển tiếp tenant sáp nhập

  @TC-03-064 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-064 Route mặc định chỉ ở cửa INT; mở ra cửa EXT cần bốn mắt
    # Truy vết: FR-03-038 · API-03-008, 071, 072 · UI-03-03, 17 · UC-03-16 · ERR-03-008, 114 · EVT-03-03 · BR-03-015, 019 · SEC-13.
    Biết `r-ext-ok`; U-T68-TA, U-T68-SO1.
    Khi gọi `r-ext-ok` qua `ext.t68.sim.test` khi route ở `INT`.
    Và TA `PUT /routes/r-ext-ok/exposure` `{exposure: EXT, reason}`.
    Và TA tự duyệt qua `POST /change-requests/{id}:approve`.
    Và SO1 duyệt.
    Và gọi lại qua `ext.t68.sim.test`.
    Thì bước 1 `404` Lỗi GW 114. Bước 2 `202`, route vẫn `INT`. Bước 3 `403` ERR-03-008. Bước 4 `200`; ảnh chụp mới có `EXT`; EVT: `route.state-changed`. Bước 5 `200` ≤ 60 s. KT: có (`EXPOSURE_REQUEST`, `EXPOSURE_APPROVE`).

  @TC-03-065 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-065 Mở cửa EXT khi chưa đủ điều kiện
    # Truy vết: FR-03-038 · API-03-008 · UI-03-03 · ERR-03-011, 003, 022 · BR-03-015 · SEC-13.
    Biết `gw.waf.mode = DETECT`; `r-open-data` Keyless; `r-no-schema`; U-T68-TA; U-T68-TO.
    Khi `PUT /routes/r-ext-ok/exposure` `EXT` khi WAF `DETECT`.
    Và `PUT` cho route Keyless mức Nhạy cảm; cho `r-no-schema`.
    Và `PUT` với `exposure = XYZ`.
    Và U-T68-TO `PUT`.
    Thì bước 1, 2 `422` ERR-03-011 "Route chưa đủ điều kiện mở ra Internet: {lý do}." (`errors[]` nêu WAF chưa ở chế độ chặn, thiếu xác thực, thiếu lược đồ). Bước 3 `400` ERR-03-003. Bước 4 403-PQ. Route vẫn `INT`.

  @TC-03-066 @P2 @Dương
  Kịch bản: TC-03-066 Chuyển tiếp lượt gọi của tenant đã sáp nhập
    # Truy vết: FR-03-037 · API-03-094, 095, 096 · UI-03-16 · UC-03-30 · EVT-03-10 · BR-03-026, 030 · NFR-00-055.
    Biết U-PA; T91 `MERGED` vào T68; host `ext.t91.sim.test`; C-HTTT1 có token T68.
    Khi `POST /tenant-redirects` `{sourceTenant: T91, targetTenant: T68, days: 180}` kèm `Idempotency-Key`.
    Và gọi `https://ext.t91.sim.test/ho-tich/ping` bằng token T68.
    Và gọi bằng token cũ của T91.
    Và `GET /tenant-redirects`; `POST …/{redirectId}:end`.
    Và gọi lại host T91.
    Thì bước 1 `201`; EVT: `tenant-redirect.changed`. Bước 2 chuyển tới route T68, kèm `Deprecation`, `Sunset` (180 ngày). Bước 3 `401` Lỗi GW 106 (không chuyển tiếp token sai tenant). Bước 4 `200`. Bước 5 `404` hoặc `410` Lỗi GW 126. KT: có (`REDIRECT_CREATE`, `REDIRECT_END`).

  @TC-03-067 @P2 @Âm
  Kịch bản: TC-03-067 Chuyển tiếp tenant: sai điều kiện, trùng, thiếu quyền, đã kết thúc
    # Truy vết: FR-03-037 · API-03-095, 096, 094 · ERR-03-025, 003, 019, 022, 001 · BR-03-026, 030.
    Biết U-PA; U-T68-TA; T01 chưa sáp nhập; chuyển tiếp T91 đã tạo.
    Khi `POST /tenant-redirects` với nguồn `T01` (chưa `MERGED`).
    Và tạo chuyển tiếp thứ hai cho T91.
    Và thiếu `targetTenant`; `days = 400`.
    Và `:end` hai lần; `:end` mã lạ.
    Và U-T68-TA `POST /tenant-redirects`.
    Thì bước 1, 2 `409` ERR-03-025 "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy." Bước 3 `400` ERR-03-003. Bước 4 lần hai `409` ERR-03-019; mã lạ 404-ẩn. Bước 5 403-PQ (chỉ PA hoặc TA của tenant đích theo `PERM-03-admin`; TA T68 chỉ xem nếu không phải bên tạo).
