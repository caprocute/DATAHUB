# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-07
Tính năng: TS-05-07 · Danh sách, chi tiết, lịch sử, xuất

  @TC-05-027 @P2 @Dương
  Kịch bản: TC-05-027 Lọc, sắp xếp, mặc định Mất kết nối đứng đầu
    # Truy vết: FR-05-002 · API-05-003 · UI-05-01 · BR-05-014
    Biết U-T68-VW; 40 kết nối thử, 2 `UNHEALTHY`, 3 `DEGRADED` ở PROD.
    Khi `GET /connections` không sắp xếp.
    Và `GET /connections?q=ndxp&typeCode=oauth2-client&health=UNHEALTHY&env=PROD`.
    Và mở UI-05-01, bấm bộ lọc nhanh "Bí mật quá hạn".
    Thì bước 1: 2 mục đầu `UNHEALTHY`, rồi 3 `DEGRADED`; có `facets`. Bước 2 chỉ mục khớp. Bước 3 URL có `secretOverdue=true`, bảng chỉ còn kết nối có tuổi bí mật ≥ 90 ngày.

  @TC-05-028 @P2 @Dương
  Kịch bản: TC-05-028 Chi tiết kết nối trả allowedActions theo người xem
    # Truy vết: FR-05-003 · API-05-005 · UI-05-02
    Biết U-T68-VW, U-T68-IE1; C-NDXP.
    Thì cả hai `200`; với VW `allowedActions` rỗng; với IE1 có `updateConnection`, `startConnectionTest`. Không trường nào chứa giá trị bí mật.

  @TC-05-029 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-029 Chi tiết kết nối của tenant khác trả 404-ẩn
    # Truy vết: FR-05-003 · API-05-005 · ERR-05-001 · BR-05-002
    Biết U-T01-IE; kết nối `tc-chi-t68` chỉ có ở T68.
    Khi U-T01-IE `GET /connections/tc-chi-t68`.
    Và U-T01-IE `GET /connections/khong-co`.
    Thì cả hai 404-ẩn, thân giống nhau trừ `traceId`.

  @TC-05-030 @P2 @Dương
  Kịch bản: TC-05-030 Lịch sử thay đổi không có bí mật
    # Truy vết: FR-05-016 · API-05-026 · UI-05-02
    Biết U-T68-AU; `tc-ndxp-moi` sau TS-05-01…05.
    Thì có các mục tạo, sửa, ghi bí mật (chỉ phiên bản), kiểm tra, bật, xin bật, duyệt theo thời gian; khác biệt tham số có; mồi sạch.

  @TC-05-031 @P3 @Dương @Bảo @mật
  Kịch bản: TC-05-031 Xuất CSV không chứa bí mật, đúng bộ lọc
    # Truy vết: FR-05-017 · API-05-027 · UI-05-01
    Biết U-T68-IE1.
    Thì `200` `text/csv; charset=utf-8` có BOM; chỉ dòng REST; cột không có giá trị bí mật; mồi sạch trong tệp. KT: có (`CONNECTION_EXPORT`).

  @TC-05-147 @P2 @Âm
  Kịch bản: TC-05-147 Lọc sai, lịch sử của đối tượng không tồn tại
    # Truy vết: FR-05-002, 016, 029 · API-05-003, 026, 043, 066 · ERR-05-003, 001
    Biết U-T68-VW; U-T01-IE.
    Khi `GET /connections?q=a`; `GET /connections?status=XYZ`; `GET /adapters?systemGroup=7`; `GET /connections?limit=101`.
    Và U-T01-IE `GET /connections/tc-chi-t68/history`; `GET /adapters/khong-co/history`.
    Thì bước 1 mỗi lệnh `400` ERR-05-003 chỉ đúng tham số (tìm cần ≥ 2 ký tự, `limit` ≤ 100). Bước 2 404-ẩn.
