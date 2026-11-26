# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-02
Tính năng: TS-04-02 · Danh sách, tìm kiếm, chi tiết luồng

  @TC-04-007 @P1 @Dương
  Kịch bản: TC-04-007 Liệt kê luồng có lọc, đếm theo trạng thái
    # Truy vết: FR-04-001 · API-04-010 · UI-04-01 · LGC-BUS-001, 003, 004, 005.
    Biết T68 có F-HT, F-DD, F-SQL, F-SOAP, F-KAM; người gọi U-T68-TA.
    Khi gọi `GET /flows?limit=25`.
    Và gọi `GET /flows?status=ACTIVE&environment=PROD`.
    Và gọi `GET /flows?q=ho tich` (không dấu).
    Và gọi `GET /flows?resourceKind=KAMELET`.
    Và gọi `GET /flows?label=nguon:bhxh`.
    Thì bước 1 trả `200` với 5 luồng, sắp `-updatedAt`, `facets.status` đếm đúng, không có F-T01. Bước 2 trả F-HT, F-DD, F-SOAP. Bước 3 trả F-HT. Bước 4 trả F-KAM. Bước 5 trả F-SOAP. Mỗi phần tử có `environments[]` với `syncStatus`, `healthStatus`, `openVersionNo`. KT: không.

  @TC-04-008 @P2 @Dương
  Kịch bản: TC-04-008 Tìm theo endpoint
    # Truy vết: FR-04-001 · API-04-010 · LGC-BUS-002.
    Biết F-HT có điểm vào `platform-http:/ho-tich/tra-cuu` và điểm ra qua CONN-HT.
    Khi gọi `GET /flows?endpoint=/ho-tich/`.
    Và gọi `GET /flows?endpoint=CONN-HT`.
    Và gọi `GET /flows?endpoint=password` (chuỗi không nằm trong URI đã che).
    Thì bước 1, 2 trả F-HT. Bước 3 trả rỗng. Chỉ mục EN-04-04b chỉ chứa URI đã che tham số nhạy cảm.

  @TC-04-009 @P2 @Âm @Biên
  Kịch bản: TC-04-009 Tham số danh sách không hợp lệ
    # Truy vết: FR-04-001 · API-04-010 · ERR-04-026, 049.
    Biết U-T68-VW.
    Khi gọi `GET /flows?limit=100`.
    Và gọi `GET /flows?limit=101`.
    Và gọi `GET /flows?status=RUNNING`.
    Và gọi `GET /flows?sort=drop`.
    Và gọi `GET /flows?q=a` (1 ký tự).
    Và gọi `GET /flows?cursor=abc` (con trỏ giả).
    Thì bước 1 trả `200`. Bước 2 trả `400` ERR-04-026. Bước 3, 4, 5, 6 trả `400` ERR-04-049 có `errors[].path` chỉ tham số sai, không lộ chi tiết SQL hay ngăn xếp.

  @TC-04-010 @P1 @Dương
  Kịch bản: TC-04-010 Chi tiết luồng đầy đủ
    # Truy vết: FR-04-002 · API-04-012, 024, 054, 060 · UI-04-02 · LGC-BUS-006, 008, 017, 018.
    Biết F-HT; người gọi U-T68-VW.
    Khi gọi `GET /flows/tra-cuu-ho-tich`.
    Và mở UI-04-02, lần lượt các tab Tổng quan, Sơ đồ (chỉ đọc), YAML, Phiên bản, Triển khai, Điểm kết nối, Lịch sử.
    Thì bước 1 trả `200`, `ETag`, `routes[]` có `routeId`, `fromUri`, `stepCount`; `environments` có ba môi trường đều v3. Bước 2: sơ đồ hiện chín khối chặng chuẩn; YAML chỉ đọc; tab Lịch sử ẩn cột "trước/sau" với VW. Không nút nào ngoài "Xem", "Tải YAML".

  @TC-04-011 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-011 Chi tiết luồng không tồn tại hoặc ở tenant khác
    # Truy vết: FR-04-002 · API-04-012 · ERR-04-001.
    Biết U-T68-VW; F-T01 chỉ có ở T01.
    Khi gọi `GET /flows/khong-co`.
    Và U-T01-IE tạo luồng `tc-chi-t01`; U-T68-VW gọi `GET /flows/tc-chi-t01`.
    Thì cả hai trả `404` ERR-04-001, thân giống nhau trừ `traceId` (không phân biệt được tồn tại hay không).

  @TC-04-012 @P2 @Dương
  Kịch bản: TC-04-012 Phụ thuộc của luồng
    # Truy vết: FR-04-002, 006 · API-04-016.
    Biết F-HT được API `ho-tich-tra-cuu` của PH-02 dùng (stub), được ca kiểm thử của chính nó dùng, và F-DD gọi `direct:` tới nó (giả lập).
    Khi gọi `GET /flows/tra-cuu-ho-tich/dependencies`.
    Thì `200`; `hard` có `API` (PH-02) và `FLOW` (F-DD); `soft` có `TEST_CASE`. PH-02 không trả lời trong 5 giây thì `503` ERR-04-047, không trả danh sách thiếu.
