# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-22
Tính năng: TS-03-22 · Tham số gateway theo tenant và báo cáo sử dụng

  @TC-03-092 @P1 @Dương
  Kịch bản: TC-03-092 Đổi tham số trong miền và trần, đặt lại mặc định
    # Truy vết: FR-03-056 · API-03-086, 087 · UI-03-16 · UC-03-29 · EVT-03-11 · BR-03-016 · NFR-00-052.
    Biết U-T68-TA; `gw.ip.apiReqPerSecond = 200` mặc định.
    Khi `GET /settings`.
    Và `PUT /settings` `{gw.ip.apiReqPerSecond: 400, gw.jwks.refreshMinutes: 5}` kèm `If-Match`.
    Và gửi 300 lượt/giây từ một IP sau khi hiệu lực.
    Và đặt lại `gw.ip.apiReqPerSecond` về mặc định.
    Thì bước 1 `200` kèm mặc định, miền, trần, người sửa gần nhất, `ETag`. Bước 2 `200` hoặc `202`; ảnh chụp mới; hiệu lực ≤ 60 s (thường < 10 s). Bước 3 không bị `429` mã 119. Bước 4 giá trị về 200. KT: có (`SETTINGS_UPDATE`, giá trị trước, sau); EVT: `limit.changed` khi đổi tham số hạn mức.

  @TC-03-093 @P1 @Âm @Biên
  Kịch bản: TC-03-093 Tham số sai miền, vượt trần, ETag cũ, tham số rủi ro cao
    # Truy vết: FR-03-056 · API-03-087 · UI-03-16 · ERR-03-003, 018, 004, 022 · BR-03-019.
    Biết U-T68-TA; U-T68-VW; trần nền tảng `gw.ip.maxConnections = 1.000`.
    Khi `PUT` giá trị sai kiểu (`"abc"`), dưới tối thiểu (`gw.ip.maxConnections = 5`).
    Và `gw.ip.maxConnections = 2.000`.
    Và `If-Match` cũ.
    Và đổi `gw.waf.mode`, `gw.tenantRateLimit.perSecond` qua `/settings`.
    Và U-T68-VW `PUT`.
    Thì bước 1 `400` ERR-03-003 "Giá trị của {khóa} phải thuộc {miền}." Bước 2 `422` ERR-03-018 "gw.ip.maxConnections không được vượt 1.000 theo hợp đồng của tỉnh." Bước 3 `412` ERR-03-004. Bước 4 `400` ERR-03-003 (phải đi qua chức năng bốn mắt). Bước 5 403-PQ.

  @TC-03-094 @P2 @Dương @Âm
  Kịch bản: TC-03-094 Báo cáo sử dụng API theo HTTT, route, gói; xuất
    # Truy vết: FR-03-058 · API-03-089, 090 · UI-03-01 · UC-03-27 · ERR-03-021, 026, 022, 003 · BR-03-020, 028 · LGC-APIM-022.
    Biết U-T68-TA; dữ liệu 31 ngày; lượt kiểm tra tổng hợp; U-T68-VW; `SIM-PH13`.
    Khi `GET /reports/usage?groupBy=consumer&from&to`; đổi `groupBy=route`, `plan`.
    Và `POST /reports/usage:export`.
    Và khoảng 32 ngày; `groupBy=xyz`.
    Và ngắt `SIM-PH13`.
    Và U-T68-VW `POST …:export`.
    Thì bước 1 `200`, tổng khớp bộ tạo tải ≤ 1 %, loại lượt `synthetic`, không có trường tiền, giá hay hóa đơn (BR-03-020), chỉ có dữ liệu T68. Bước 2 `202`. Bước 3 `400` ERR-03-021, `400` ERR-03-003. Bước 4 `503` ERR-03-026. Bước 5 403-PQ (xuất cần `PERM-03-log-read`).
