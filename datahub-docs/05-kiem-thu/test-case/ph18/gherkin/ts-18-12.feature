# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-12
Tính năng: TS-18-12 · Lọc, gom nhóm, phân loại và gán người xử lý mục DLQ

  @TC-18-036 @P1 @Dương
  Kịch bản: TC-18-036 Lọc theo nguồn, mã lỗi, lớp lỗi, tuổi; khối facets và xuất CSV chỉ siêu dữ liệu
    # Truy vết: FR-18-019 · API-18-041, 042 · BR-18-047 · UI-18-01
    # Mục đích: Chứng minh FR-18-019: bộ lọc kết hợp trả đúng tập, `facets` đếm theo từng chiều, xuất CSV không có cột payload.
    Biết T90 với `DLQ-SET-A` (200 mục: 5 nguồn, 4 lớp lỗi, 6 trạng thái, tuổi 1 giờ đến 40 ngày); U-T90-TO.
    Khi `GET /dlq/messages?nguon=SRC-PH04&lopLoi=TRANSIENT&trangThai=NEW&tuoiTu=24h&page=0&size=50`.
    Và tìm theo `q=ERR-04-101` và theo `traceId`.
    Và `GET /dlq/messages:export` với bộ lọc bước 1.
    Và mở `/van-hanh/dlq?nguon=SRC-PH04` trên UI-18-01, đổi bộ lọc và tải lại trang.
    Thì bước 1 `200`, đúng số mục theo bảng dữ liệu, sắp mặc định theo tuổi giảm dần, `facets` đủ các chiều. Bước 2 trả đúng mục. Bước 3 CSV có `dlqId`, nguồn, luồng, mã lỗi, lớp lỗi, trạng thái, thời điểm; không có cột nội dung. Bước 4 bộ lọc giữ trên URL, dải bốn thẻ số hiện đúng.

  @TC-18-037 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-037 Bộ lọc sai và mục của tenant khác không xuất hiện
    # Truy vết: FR-18-019, 021 · API-18-041, 045 · BR-18-047 · ERR-18-003, 001 · NFR-18-017
    # Mục đích: Chứng minh lọc sai bị chặn rõ ràng và RLS bảo đảm không mục nào của T91 lọt vào kết quả, kể cả khi đoán `dlqId`.
    Biết T90, T91 cùng có mục mã lỗi `ERR-04-101`; `DLQ-T91-07` thuộc T91; U-T90-TO.
    Khi `GET /dlq/messages?trangThai=KHONG_CO&size=500`.
    Và `GET /dlq/messages?q=ERR-04-101`.
    Và `GET /dlq/messages/DLQ-T91-07`.
    Thì bước 1 `400` ERR-18-003 nêu `trangThai` và `size`. Bước 2 chỉ mục của T90. Bước 3 `404` ERR-18-001, thân giống hệt mục không tồn tại trừ `traceId`.

  @TC-18-038 @P3 @Dương @Âm
  Kịch bản: TC-18-038 Gom nhóm theo dấu hiệu lỗi và gán người xử lý cho cả nhóm
    # Truy vết: FR-18-020, 023 · API-18-043, 044 · ERR-18-006 · EVT-18-07 · UI-18-02
    # Mục đích: Chứng minh FR-18-020: mục cùng nguồn, luồng, mã lỗi, bước trong `18.dlq.group.window-hours` gom một nhóm; gán nhóm áp cho mọi mục mở của nhóm.
    Biết T90; 120 mục `ERR-04-101` của `SRC-PH04` trong 24 giờ, 15 mục `ERR-19-004` của `SRC-PH19`; nhóm `GRP-OLD` đã đóng.
    Khi U-T90-TO mở `/van-hanh/dlq?tab=nhom`.
    Và `POST /dlq/groups/{groupId}:assign` người xử lý U-T90-IE, ưu tiên `HIGH`.
    Và `POST /dlq/groups/GRP-OLD:assign`.
    Thì bước 1 hai nhóm, số mục 120 và 15, tuổi cũ nhất, nguồn. Bước 2 `200`, 120 mục có người xử lý và ưu tiên mới, mỗi mục một bản ghi kiểm toán. Bước 3 `409` ERR-18-006.

  @TC-18-039 @P1 @Dương @Âm
  Kịch bản: TC-18-039 Phân loại, gán, nhận việc từng mục và hàng loạt 1.000 mục; lỗi trạng thái, ETag, kiểm toán
    # Truy vết: FR-18-023 · API-18-049, 050, 051, 063 · BR-18-032, 046 · ERR-18-003, 004, 006, 008 · EVT-18-07 · UI-18-01, 03
    # Mục đích: Chứng minh FR-18-023: `NEW` sang `TRIAGED` có EVT-18-07 và kiểm toán trước; hàng loạt tối đa 1.000 mục; mục đã đóng không phân loại lại; PH-13 không ghi được kiểm toán thì từ chối.
    Biết T90; `DLQ-A-02` `NEW`, `DLQ-A-03` `RESOLVED`; 1.001 mục `NEW`; U-T90-TO; WireMock PH-13 bật lỗi ở bước 6.
    Khi `POST /dlq/messages/DLQ-A-02:triage` lớp `BUSINESS`, ưu tiên `HIGH`, ghi chú, `If-Match`.
    Và `POST /dlq/messages/DLQ-A-02:assign` cho chính mình.
    Và `POST /dlq/messages:bulk-triage` 1.000 mục rồi 1.001 mục.
    Và `POST /dlq/messages/DLQ-A-03:triage`.
    Và gửi lại bước 1 với `ETag` cũ.
    Và bật lỗi PH-13, phân loại một mục `NEW` khác.
    Thì bước 1 `200` `TRIAGED`, EVT-18-07 `from = NEW`, `to = TRIAGED`; `GET /dlq/messages/DLQ-A-02/audit` có dòng triage. Bước 2 `200`. Bước 3 lần đầu `200` 1.000 kết quả, lần hai `400` ERR-18-003. Bước 4 `409` ERR-18-006. Bước 5 `412` ERR-18-004. Bước 6 `503` ERR-18-008, mục vẫn `NEW`.
