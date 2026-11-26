# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-19
Tính năng: TS-03-19 · Mẫu chính sách được duyệt sẵn và chạy thử chính sách

  @TC-03-082 @P1 @Dương @Âm
  Kịch bản: TC-03-082 Danh mục mẫu chính sách; bật, tắt cho tenant
    # Truy vết: FR-03-048 · API-03-065, 066, 067 · UI-03-13 · UC-03-24 · ERR-03-013, 019, 003, 001, 022 · BR-03-017 · LGC-APIM-015.
    Biết U-T68-TA; U-PA; mẫu `tpl-cors` đang dùng bởi 2 route; `tpl-lua-custom` ngoài danh mục.
    Khi `GET /policy-templates`; `GET /policy-templates/tpl-cors`.
    Và TA `PUT /policy-templates/tpl-cors/enablement` `{enabled: false}`.
    Và tắt mẫu chưa bật lần hai; `GET /policy-templates/tpl-lua-custom`.
    Và gán `tpl-lua-custom` cho route rồi `POST /snapshots:validate`.
    Và U-T68-VW `PUT …/enablement`.
    Thì bước 1 `200`, chỉ mẫu trong danh mục (kèm phiên bản, tham số). Bước 2 `409` ERR-03-019 (đang dùng bởi 2 route). Bước 3 lần hai `409`; `tpl-lua-custom` 404-ẩn. Bước 4 `findings[]` ERR-03-013 "Route {mã} dùng plugin {tên} không có trong danh mục được duyệt." Bước 5 403-PQ.

  @TC-03-083 @P2 @Dương @Âm
  Kịch bản: TC-03-083 Chạy thử chính sách bằng mô phỏng, không tăng bộ đếm
    # Truy vết: FR-03-057 · API-03-088, 029 · UI-03-14 · UC-03-24 · ERR-03-003, 001, 018, 022 · BR-03-027 · SEC-26, 42.
    Biết U-T68-TA; C-HTTT1 đã dùng 150 lượt/ngày; `SIM-BE` đếm lượt nhận.
    Khi `POST /simulations` `{consumer: ht-ndxp, route: r-ho-tich, method: GET, path, scopes, ip}`.
    Và lặp 50 lần.
    Và `GET /consumers/ht-ndxp/usage`.
    Và mô phỏng với route lạ; trường sai kiểu; U-T68-VW gọi.
    Thì bước 1 `200`, trả quyết định từng chốt (xác thực, đăng ký, scope, đường dẫn, OPA, hạn mức) và lý do. Bước 2, 3 bộ đếm vẫn 150, `SIM-BE` nhận 0 lượt. Bước 4 404-ẩn, `400` ERR-03-003, 403-PQ.
