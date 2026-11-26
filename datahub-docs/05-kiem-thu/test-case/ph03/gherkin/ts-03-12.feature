# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-12
Tính năng: TS-03-12 · Định tuyến, phiên bản API song song, dừng và mở API

  @TC-03-052 @P1 @Dương @Âm
  Kịch bản: TC-03-052 So khớp route theo host, đường dẫn, phương thức, ưu tiên
    # Truy vết: FR-03-028 · API-03-001, 002 · UI-03-02, 03 · UC-03-01 · ERR-03-114 · BR-03-026, 001 · LGC-APIM-017.
    Biết `r-ho-tich` GET, POST `/ho-tich/`; route chính xác `/ho-tich/tra-cuu` ưu tiên cao hơn; `r-pending` `PENDING`.
    Khi GET `/ho-tich/tra-cuu` (khớp chính xác) và GET `/ho-tich/khac` (khớp tiền tố).
    Và DELETE `/ho-tich/tra-cuu`.
    Và GET `/khong-co-duong-nay`; GET route `r-pending`.
    Và GET với `Host` không thuộc tenant nào.
    Thì bước 1 đúng backend của từng route (đường dẫn chính xác thắng). Bước 2 `405` kèm `Allow`, mã ERR-03-114 "Phương thức không được phép cho đường dẫn này." Bước 3 `404` Lỗi GW 114 "Không tìm thấy dịch vụ hoặc đường dẫn." (route `PENDING` như không tồn tại). Bước 4 `404` hoặc `421`, không lộ tên tenant.

  @TC-03-053 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-053 Route của tenant này không khớp lượt gọi của tenant khác
    # Truy vết: FR-03-028 · API-03-001, 002 · UI-03-02 · ERR-03-114, 001 · BR-03-026, 028 · NFR-03-019 · SEC-87.
    Biết route `r-ho-tich` trùng mã ở T68 và T01 nhưng khác backend; route `r-chi-t01` chỉ có ở T01; U-T68-VW.
    Khi gọi `r-chi-t01` qua host T68 (`int.t68.sim.test/chi-t01/...`) bằng token T68.
    Và gọi `r-ho-tich` qua mỗi host, ghi backend nhận.
    Và U-T68-VW `GET /routes/r-chi-t01`; `GET /routes/khong-co`; `GET /routes?q=r-chi-t01`.
    Thì bước 1 `404` Lỗi GW 114. Bước 2 mỗi host đến đúng backend của tenant mình. Bước 3 hai lần 404-ẩn giống hệt trừ `traceId`; danh sách không chứa route T01.

  @TC-03-054 @P2 @Dương @Biên
  Kịch bản: TC-03-054 Danh sách, chi tiết route: lọc, phân trang, phiên bản đối tượng
    # Truy vết: FR-03-028 · API-03-001, 002 · UI-03-02, 03 · BR-03-026 · NFR-03-023 · LGC-APIM-017.
    Biết T68 có 1.000 route; U-T68-VW.
    Khi `GET /routes?page=1&size=20&state=ACTIVE&q=ho-tich`.
    Và `GET /routes?size=101`.
    Và `GET /routes/r-ho-tich` rồi mở UI-03-03.
    Thì bước 1 `200`, đúng 20 phần tử và tổng đúng. Bước 2 `400` ERR-03-003 (cỡ trang tối đa 100). Bước 3 `200` có `ETag`, `hostPattern`, `pathPattern`, `methods`, `upstream`, `plan`, `exposure`, `allowedActions`; UI hiển thị địa chỉ gọi (LGC-APIM-017). Đọc p95 ≤ 300 ms.

  @TC-03-055 @P1 @Dương @Âm
  Kịch bản: TC-03-055 Dừng và mở API tức thời
    # Truy vết: FR-03-036 · API-03-003, 004 · UI-03-02, 03 · UC-03-09 · ERR-03-123, 019, 023, 001, 022 · EVT-03-03 · BR-03-010, 029 · LGC-APIM-005.
    Biết U-T68-TO; `r-ho-tich` `ACTIVE` dưới tải 50 lượt/giây; `r-pending`.
    Khi `POST /routes/r-ho-tich:stop`.
    Và gọi route; `POST …:stop` lần hai.
    Và `POST …:start`.
    Và `POST /routes/r-pending:stop`; `POST /routes/khong-co:stop`.
    Và U-T68-VW `POST …:stop`.
    Thì bước 1 `200`. Bước 2 lượt gọi `503` Lỗi GW 123 kèm `Retry-After` ≤ 30 s; lần dừng thứ hai `409` ERR-03-019. Bước 3 `200`, gọi được ≤ 60 s, 0 lượt lỗi ở route khác. Bước 4 `409` ERR-03-023 và 404-ẩn. Bước 5 403-PQ. EVT: `route.state-changed` mỗi lần đổi. KT: có (`ROUTE_STOP`, `ROUTE_START`).

  @TC-03-056 @P2 @Dương @Âm
  Kịch bản: TC-03-056 Phiên bản API song song, tiêu đề ngừng dùng, hết hạn phục vụ
    # Truy vết: FR-03-035 · API-03-007, 002 · UI-03-02, 03 · UC-03-09 · ERR-03-126, 005 · BR-03-030 · NFR-00-055.
    Biết `r-v1` `SUNSET` (công bố ngừng dùng từ 200 ngày trước), `r-v2` `ACTIVE`; một route khác chưa đủ 180 ngày.
    Khi `GET /routes/r-v1/versions`.
    Và gọi `r-v1` và `r-v2`.
    Và chuyển `r-v1` sang `RETIRED` (sau thời hạn giữ); gọi lại.
    Và cố đưa route công bố ngừng dùng 100 ngày sang `RETIRED`.
    Thì bước 1 `200`, liệt kê hai phiên bản kèm ngày công bố, ngày `Sunset`. Bước 2 `r-v1` có `Deprecation`, `Sunset`, `Link` tới phiên bản mới; `r-v2` không có. Bước 3 `410` Lỗi GW 126 "Phiên bản API đã hết hạn phục vụ. Chuyển sang phiên bản mới." Bước 4 bị từ chối kiểm tra (ERR-03-005, `findings[]` nêu chưa đủ 180 ngày).
