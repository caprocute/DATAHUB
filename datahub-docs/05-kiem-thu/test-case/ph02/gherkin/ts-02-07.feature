# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-07
Tính năng: TS-02-07 · Đồng bộ lại đặc tả, tự đăng ký từ luồng, khung route

  @TC-02-025 @P2 @Dương @Âm
  Kịch bản: TC-02-025 Đồng bộ lại đặc tả từ URL: phát hiện thay đổi, không ghi đè bản đã công bố
    # Truy vết: FR-02-012 · API-02-016, 095 · UI-02-02 · EVT-02-07 · ERR-02-035, 011.
    Biết bản nháp nạp từ M-URL; đổi nội dung nguồn.
    Khi `POST …/spec:resync`, theo dõi `GET /operations/{id}`.
    Và gọi `:resync` lần hai khi lần một đang chạy.
    Và gọi `:resync` cho phiên bản `PUBLISHED`.
    Thì bước 1: `202`, có khác biệt, EVT: `version.spec-source-changed`. Bước 2: `409` ERR-02-035. Bước 3: `409` ERR-02-011.

  @TC-02-026 @P1 @Dương @Âm
  Kịch bản: TC-02-026 PH-04 tự đăng ký API từ luồng REST; chỉ sửa mô tả, gói, SLA
    # Truy vết: FR-02-013, 014 · API-02-017, 018 · BR-02-030 · ERR-02-014, 011 · EVT-02-01 · LGC-BUS-028.
    Biết S-FLOW (`catalog:flow-sync`); luồng `tc-luong-rest`.
    Khi S-FLOW `PUT /internal/flow-apis/tc-luong-rest`, lặp lại lần hai (idempotent).
    Và U-T68-SV1 sửa mô tả, rồi sửa đặc tả của API `origin = FLOW`.
    Và dùng token người dùng gọi `PUT /internal/flow-apis/…`.
    Thì bước 1: tạo một API, lần hai cập nhật. Bước 2: mô tả `200`; đặc tả bị từ chối. Bước 3: 403-PQ.

  @TC-02-027 @P1 @Dương @Âm
  Kịch bản: TC-02-027 Sinh khung route chín chặng cho PH-04 từ đặc tả
    # Truy vết: FR-02-026 · API-02-032, 095 · UC-02-10 · BR-02-010, 024 · ERR-02-037, 021 · UI-02-02.
    Biết A-DRAFT với F-SPEC-OK; M-FLOW.
    Khi `POST …/flow-skeleton` cho thao tác có trong đặc tả.
    Và gọi cho thao tác không có trong đặc tả.
    Và gọi cho phiên bản chưa có backend `ACTIVE`.
    Thì bước 1: `202`, khung đủ chín chặng, không có logic nghiệp vụ. Bước 2: `422` ERR-02-037. Bước 3: `422` ERR-02-021.

  @TC-02-098 @P2 @Âm
  Kịch bản: TC-02-098 Đồng bộ lại đặc tả: đang chạy, kho đối tượng sự cố, tra tiến độ
    # Truy vết: FR-02-012 · API-02-016, 095 · UI-02-02 · UC-02-08 · BR-02-014 · ERR-02-035, 034, 011, 001.
    Biết A-DRAFT có URL nguồn trên M-URL; A-DATDAI (`PUBLISHED`); A-T01.
    Khi hai `POST …:resync` liên tiếp cho cùng phiên bản `DRAFT`.
    Và tắt kho đối tượng (hộp giả) rồi `POST …:resync`.
    Và `GET /operations/{id}` của tác vụ ở bước 1; rồi `GET /operations/{id của T01}`.
    Và `POST …:resync` cho phiên bản `PUBLISHED`.
    Thì bước 1: `202` rồi `409` ERR-02-035. Bước 2: `503` ERR-02-034 kèm `retryAfterSeconds`, không đổi đặc tả. Bước 3: tiến độ đúng; định danh của T01 trả `404` ERR-02-001. Bước 4: `409` ERR-02-011, bản công bố không bị ghi đè.

  @TC-02-099 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-099 Tự đăng ký từ luồng: token tenant khác, scope sai, thân sai
    # Truy vết: FR-02-013 · API-02-017 · UC-02-09 · BR-02-030, 033 · ERR-02-014, 003, 001.
    Biết S-FLOW của T68 và S-FLOW-T01; luồng `tc-luong-rest` của T68.
    Khi S-FLOW-T01 `PUT /internal/flow-apis/tc-luong-rest`.
    Và S-FLOW gọi với thân thiếu `contractSpec`, rồi với `flowCode` khác đường dẫn.
    Và token `catalog:read` gọi cùng operation.
    Thì bước 1: API chỉ tạo ở T01 theo claim tenant của token; T68 không đổi và không lộ. Bước 2: `400` ERR-02-003, API cũ giữ nguyên. Bước 3: `403` ERR-02-014.

  @TC-02-163 @P2 @Dương @Biên @Âm
  Kịch bản: TC-02-163 Sinh lại khung route: không ghi đè luồng đã sửa, đặc tả rất lớn, không có logic nghiệp vụ
    # Truy vết: FR-02-026 · API-02-032, 095 · UI-02-02 · UC-02-10 · BR-02-010 · ERR-02-035, 038, 034.
    Biết A-DRAFT với F-SPEC-OK và với đặc tả 5.000 thao tác; M-FLOW; luồng `tc-khung` đã được kỹ sư sửa tay ở PH-04.
    Khi `POST …/flow-skeleton` cho đặc tả 5.000 thao tác; theo dõi `operationId`.
    Và gọi hai lần liền cho cùng thao tác.
    Và sinh lại khung cho thao tác đã có luồng `tc-khung` được sửa tay.
    Và gọi khi phiên bản ở `PENDING`; rồi khi M-FLOW không phản hồi.
    Thì bước 1: `202`, hoàn tất trong thời gian của tác vụ bất đồng bộ, khung đủ chín chặng cho từng thao tác, không có logic nghiệp vụ. Bước 2: `409` ERR-02-035 cho lần hai. Bước 3: PH-02 không ghi đè luồng đã sửa; trả khung mới dưới dạng đề xuất để PH-04 tự quyết. Bước 4: `409` ERR-02-038; `503` ERR-02-034.
