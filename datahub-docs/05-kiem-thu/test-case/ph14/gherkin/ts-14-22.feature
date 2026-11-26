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

  @TC-14-122 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-122 Khóa đệm chuẩn hóa tham số, gộp lượt trùng, mã hóa mức `RESTRICTED`
    # Truy vết: FR-14-035 · API-14-046, 075 · UC-14-24 · BR-14-015 · NFR-14-004, 024 · SEC-82.
    Biết S-HT-MC; V-HT (đệm 300 giây); V-DKKD đặt mức `RESTRICTED`; `sim-ndxp` `SLOW` 2 giây ở bước 3; Valkey có thể liệt kê khóa.
    Khi gọi V-HT với `params` `{a:1, b:2}` rồi `{b:2, a:1, c:null}`.
    Và liệt kê khóa Valkey của V-HT và V-DKKD.
    Và gửi 50 lượt đồng thời cùng tham số khi chưa có đệm.
    Và gọi `GET /cache/stats`.
    Thì bước 1 lượt hai `HIT` vì tham số chuẩn hóa (sắp khóa, bỏ trường rỗng) cho cùng khóa. Bước 2 mọi khóa có tiền tố tenant, dịch vụ, thao tác và băm tham số; giá trị của V-DKKD ở dạng mã hóa bằng khóa tenant, không đọc được dạng rõ. Bước 3 `sim-ndxp` nhận đúng một lượt, 49 lượt còn lại chờ kết quả đó. Bước 4 `hits`, `misses`, `hitRatio` khớp.

  @TC-14-123 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-123 Đệm không được dùng sai: lỗi, `freshData`, ủy quyền trước khi đọc, Valkey mất
    # Truy vết: FR-14-035 · API-14-075 · ERR-14-106 · BR-14-014, 015 · NFR-14-024.
    Biết S-HT-MC, S-HT-KHAC; V-HT đã có mục đệm do S-HT-MC; V-BHXH (`SENSITIVE`); dịch vụ `tc-khong-dem` đặt `cacheable = false`; `sim-ndxp` `BIZ404`; Valkey có thể dừng.
    Khi S-HT-MC gọi V-HT khi `sim-ndxp` `BIZ404`; lặp lại.
    Và S-HT-KHAC (chưa được cấp V-HT) gọi V-HT cùng tham số đang có mục đệm.
    Và gọi V-BHXH và `tc-khong-dem` hai lần liên tiếp.
    Và dừng Valkey, gọi V-HT.
    Thì bước 1 lỗi nghiệp vụ không được đệm, lần lặp vẫn gọi ra. Bước 2 `403` ERR-14-106 dù có mục đệm, vì ủy quyền kiểm trước khi đọc đệm; dữ liệu đệm không lộ. Bước 3 cả hai lượt gọi ra quốc gia, không có `X-DH-Cache: HIT`. Bước 4 `200` từ lượt gọi thật, có cảnh báo, không trả lỗi cho người dùng vì lý do đệm; vẫn trừ hạn mức.

  @TC-14-124 @P1 @Dương
  Kịch bản: TC-14-124 Dùng dữ liệu đệm quá hạn có cờ khi quốc gia lỗi
    # Truy vết: FR-14-037 · API-14-075 · UC-14-24 · BR-14-016 · NFR-14-009 · EVT-14-10.
    Biết S-HT-MC; V-HT `staleAllowed`, đệm 300 giây, mục `NORMAL`, đã có mục đệm lưu từ 400 giây trước; `14.cache.stale-max-seconds = 86400`; `sim-ndxp` `DOWN` rồi `QUOTA`.
    Khi gọi V-HT khi `sim-ndxp` `DOWN` (ngắt mạch đã mở).
    Và gọi V-HT khi hạn mức đã hết.
    Và đọc phản hồi và chỉ số.
    Thì cả hai bước `200` với `meta.stale = true`, `meta.cacheAgeSeconds` ≈ 400, tiêu đề `X-DH-Cache: STALE` và `Warning: 110`; trả trong ≤ 1 giây sau khi ngắt mạch mở. `national_stale_served_total` tăng; có cảnh báo vận hành. Giao dịch ghi dùng dữ liệu quá hạn.

  @TC-14-125 @P1 @Âm
  Kịch bản: TC-14-125 Từ chối dữ liệu quá hạn: bên gọi không nhận, dữ liệu nhạy cảm, quá thời hạn cứng
    # Truy vết: FR-14-037 · API-14-075 · ERR-14-103, 104 · BR-14-016 · NFR-14-009.
    Biết S-HT-MC; V-HT `staleAllowed` có mục đệm quá hạn; V-LLTP (`SENSITIVE`) và V-HT-DK (ghi); `sim-ndxp` `DOWN`; `Clock` giả lập; `14.cache.stale-max-seconds = 3600`.
    Khi gọi V-HT với tiêu đề `X-DH-Accept-Stale: false`.
    Và gọi V-LLTP khi quốc gia lỗi.
    Và gọi V-HT-DK thao tác ghi khi quốc gia lỗi.
    Và tiến `Clock` qua thời hạn cứng 3.600 giây, gọi V-HT.
    Và đặt `14.cache.stale-max-seconds = 0`, gọi V-HT.
    Thì mọi bước trả lỗi gốc đã chuẩn hóa, không có dữ liệu đệm: `503` ERR-14-103 (hoặc `429` ERR-14-104 khi hết hạn mức) "Nền tảng quốc gia chưa phản hồi và chưa có dữ liệu lưu tạm phù hợp. Thử lại sau." Không có `meta.stale`, không có `Warning: 110`; dữ liệu `SENSITIVE` và thao tác ghi không bao giờ dùng đệm.
