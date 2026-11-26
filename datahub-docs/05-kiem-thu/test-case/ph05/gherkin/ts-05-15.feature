# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-15
Tính năng: TS-05-15 · Thao tác REST, phân trang, giới hạn đồng thời

  @TC-05-058 @P1 @Dương
  Kịch bản: TC-05-058 Khai báo thao tác REST và gọi qua luồng
    # Truy vết: FR-05-032, 033 · API-05-050 · UI-05-10 · LGC-TOOL-009
    Biết U-T68-IE1; bản nháp v8 của A-DVC; SIM-HTTP `/api/v2/ho-so/{maHoSo}`.
    Khi `PUT /adapters/dvc-rest/versions/8/operations/chi-tiet-ho-so` với `method = GET`, `pathTemplate = /api/v2/ho-so/${param.maHoSo}`.
    Và kiểm thử trên TEST với `maHoSo = "H/01 ?x=1"`.
    Thì bước 1 `200`. Bước 2 SIM-HTTP nhận `GET /api/v2/ho-so/H%2F01%20%3Fx%3D1` (mã hóa URL, không ghép thô), tiêu đề `Authorization: Bearer …` lấy từ kết nối, có `traceparent`.

  @TC-05-059 @P1 @Âm
  Kịch bản: TC-05-059 Tiêu đề xác thực trong thao tác, sideEffect WRITE trên kết nối chỉ đọc
    # Truy vết: FR-05-032, 033 · API-05-050 · ERR-05-032, 017, 008
    Biết U-T68-IE1; A-DVC v8 nháp (kết nối chỉ đọc); A-DVC v7 `APPROVED`.
    Khi `PUT …/versions/8/operations/x` với `headers = {"Authorization":"Basic …"}`.
    Và `PUT …/versions/8/operations/y` với `method = POST`, `sideEffect = WRITE`.
    Và `PUT …/versions/7/operations/z`.
    Thì bước 1 `422` ERR-05-032. Bước 2 `409` ERR-05-017. Bước 3 `409` ERR-05-008 (phiên bản đã duyệt bất biến, BR-05-016).

  @TC-05-060 @P1 @Dương @Âm
  Kịch bản: TC-05-060 Phân trang đủ trang và lỗi khi vượt số trang tối đa
    # Truy vết: FR-05-033 · BR-05-021 · ERR-05-110
    Biết A-DVC thao tác `tra-cuu-ho-so` `PAGE_NUMBER`, `maxPages = 50`.
    Khi SIM-HTTP có 37 trang.
    Và SIM-HTTP có 51 trang.
    Và lặp với `CURSOR`, `LINK_HEADER`, `OFFSET_LIMIT`.
    Thì bước 1 trả đủ bản ghi 37 trang, tiêu đề `dh-adapter-pages = 37`. Bước 2 lỗi ERR-05-110, không trả 50 trang đầu. Bước 3 cùng kết quả với từng chế độ.

  @TC-05-061 @P2 @Biên
  Kịch bản: TC-05-061 Tôn trọng 429 Retry-After của đối tác
    # Truy vết: FR-05-033 · ERR-05-106
    Biết SIM-HTTP trả 429 `Retry-After: 2` hai lần rồi 200; lần khác luôn 429 `Retry-After: 120`.
    Thì lần 1 thành công sau khoảng 4 giây, không gửi yêu cầu trước khi hết `Retry-After`. Lần 2 trả ERR-05-106 khi `Retry-After` vượt thời gian chờ còn lại.

  @TC-05-062 @P1 @Âm @Biên
  Kịch bản: TC-05-062 Giới hạn đồng thời tính tổng trên mọi bản sao
    # Truy vết: FR-05-042 · BR-05-029 · ERR-05-105
    Biết A-DVC `maxConcurrency = 20`, `acquireTimeoutMs = 3000`; runtime 4 bản sao; SIM-HTTP chậm 2 giây, đếm kết nối đồng thời.
    Khi k6 bắn 200 yêu cầu đồng thời vào luồng.
    Và tăng runtime lên 5 bản sao, lặp lại.
    Thì SIM-HTTP không bao giờ thấy > 20 kết nối đồng thời (mỗi bản sao ≤ 5, rồi ≤ 4); yêu cầu chờ quá 3 giây trả ERR-05-105; chỉ số `dh_adapter_pool_exhausted_total` tăng.

  @TC-05-151 @P2 @Dương
  Kịch bản: TC-05-151 Hạn mức mỗi bản sao cập nhật khi số bản sao đổi
    # Truy vết: FR-05-042, 015 · API-05-032 · BR-05-029
    Biết A-DVC `maxConcurrency = 20`; runtime 2 bản sao.
    Thì hạn mức mỗi bản sao đổi từ 10 sang 5 trong ≤ 60 giây; `dh_adapter_pool_active` tổng ≤ 20.

  @TC-05-152 @P2 @Âm
  Kịch bản: TC-05-152 Thao tác chứa logic nghiệp vụ bị từ chối
    # Truy vết: FR-05-032, 040 · BR-05-005 · API-05-050 · ERR-05-032
    Biết U-T68-IE1; A-DVC v8 nháp.
    Thì mỗi lần `422` ERR-05-032 với thông điệp "Logic nghiệp vụ và chuyển mã danh mục thuộc luồng PH-04".
