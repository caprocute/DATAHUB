# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-22
Tính năng: TS-14-22 · Đệm phản hồi và dữ liệu quá hạn

  @TC-14-056 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-14-056 Trúng đệm, cô lập tenant, không đệm mục nhạy cảm
    # Truy vết: FR-14-035 · API-14-046, 075 · UI-14-05, 09 · UC-14-24 · BR-14-014, 015 · NFR-14-004, 024.
    Biết V-HT (đệm 300 giây); V-BHXH; `T01` có `hotich-tra-cuu` cùng tham số; U-T68-TO.
    Khi S-HT-MC gọi V-HT hai lần; T01 gọi một lần cùng tham số.
    Và gọi V-BHXH hai lần.
    Và `GET /cache/stats`; kiểm khóa Valkey.
    Thì lần hai `COMPLETED_CACHE`; T01 không nhận dữ liệu của T68; V-BHXH không đệm; khóa có tiền tố tenant; ủy quyền mục đích kiểm trước khi đọc đệm (HTTT chưa cấp vẫn `403` khi dữ liệu đã đệm).

  @TC-14-057 @P1 @Dương @Âm
  Kịch bản: TC-14-057 Vô hiệu đệm; dùng dữ liệu quá hạn có cờ khi quốc gia lỗi
    # Truy vết: FR-14-036, 037 · API-14-047, 075 · ERR-14-103, 004 · BR-14-016 · NFR-14-009.
    Biết V-HT `staleAllowed`; V-DKKD không cho dùng quá hạn; `14.cache.stale-max-seconds = 86400`; U-T68-TO.
    Khi đệm hết hạn, `sim-ndxp` `DOWN`, gọi V-HT.
    Và cùng điều kiện, gọi V-DKKD.
    Và `POST /cache:invalidate` V-HT; gọi lại khi `OK`.
    Thì bước 1 `200` kèm `stale = true` trong ≤ 1 giây; bước 2 `503` ERR-14-103; bước 3 đệm bị xóa, lượt sau gọi ra quốc gia; vô hiệu cho dịch vụ không tồn tại `404` ERR-14-001.
