# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-05
Tính năng: TS-06-05 · Nạp ứng viên qua API, luồng PH-04 và sự kiện PH-10

  @TC-06-020 @P1 @Dương
  Kịch bản: TC-06-020 Nạp ứng viên qua API và phát sự kiện nhận lô
    # Truy vết: FR-06-010 · API-06-021 · EVT-06-07 · BR-06-028 · NFR-06-004
    # Mục đích: Chứng minh `POST candidates` nhận đúng, trả `202` và trạng thái, theo FR-06-010.
    Biết nguồn `HT-YTE` ACTIVE; S-T90-INGEST-HT-YTE; bản ghi F-CIT số 1.
    Khi `POST /domains/CITIZEN/candidates` với `Idempotency-Key`, `sourceKey = YT-0001`, `sourceVersion = 1`, `operation = CREATE`.
    Và `GET /domains/CITIZEN/candidates/{id}`.
    Và đọc topic `t90.mdm.candidate.ingested.v1`.
    Thì bước 1 `202` `RECEIVED`. Bước 2 chuyển tới `NORMALIZED` rồi `LINKED` hoặc `QUEUED` trong ≤ 10 s, `raw` và `normalized` cạnh nhau. Bước 3 một bản tin gộp, chỉ số lượng, không chứa giá trị. KT: có (candidate-ingest).
    # Hậu điều kiện: Ứng viên YT-0001 dùng ở ca golden-create.

  @TC-06-021 @P1 @Âm
  Kịch bản: TC-06-021 Thiếu sourceKey, sai lược đồ, quá lô, nguồn lạ, vượt hạn mức
    # Truy vết: FR-06-010 · API-06-021 · ERR-06-014, 016, 017, 018, 048
    # Mục đích: Chứng minh năm nhánh lỗi nạp, theo FR-06-010.
    Biết T92 (`06.ingest.rate-per-source = 600`); S-T90-INGEST-HT-YTE.
    Khi gửi bản ghi không `sourceKey`.
    Và gửi bản ghi thiếu thuộc tính bắt buộc, kiểu `DATE` sai.
    Và gửi lô 10.001 bản ghi.
    Và dùng token của `HT-GIAODUC` gửi cho nguồn `HT-YTE`.
    Và Ở T92 gửi 700 bản ghi trong một phút.
    Thì bước 1 `422` ERR-06-016. Bước 2 `422` ERR-06-017 liệt kê trường. Bước 3 `413` ERR-06-018. Bước 4 `403` ERR-06-014. Bước 5 bản ghi 601 trở đi `429` ERR-06-048 kèm `Retry-After`.
    # Hậu điều kiện: Không ứng viên nào từ các bước lỗi.

  @TC-06-022 @P1 @Dương @Âm
  Kịch bản: TC-06-022 Lũy đẳng bằng Idempotency-Key và sourceVersion
    # Truy vết: FR-06-010, 016 · BR-06-028, 029 · ERR-06-015
    # Mục đích: Chứng minh mỗi `(sourceCode, sourceKey, sourceVersion)` xử lý một lần và khóa lũy đẳng có hiệu lực 24 giờ, theo BR-06-028.
    Biết YT-0001 phiên bản 1 đã nạp.
    Khi gửi lại đúng thân, cùng `Idempotency-Key`.
    Và gửi `Idempotency-Key` cũ với thân khác.
    Và gửi khóa mới, cùng `(HT-YTE, YT-0001, 1)`.
    Thì bước 1 `202` trả đúng kết quả cũ, không thêm ứng viên. Bước 2 `409` ERR-06-015. Bước 3 ứng viên mới `DUPLICATE`, không đối sánh lại.
    # Hậu điều kiện: Chỉ một ứng viên có hiệu lực.

  @TC-06-023 @P1 @Dương @Âm
  Kịch bản: TC-06-023 Nạp qua luồng PH-04 bằng API nội bộ
    # Truy vết: FR-06-011 · API-06-022 · ERR-06-014
    # Mục đích: Chứng minh `dh-runtime` nạp thay nguồn đã đăng ký và không nạp thay nguồn khác, theo FR-06-011.
    Biết luồng giả `luong-yte` gắn nguồn `HT-YTE`; token `dh-runtime` T90.
    Khi `POST /internal/domains/CITIZEN/candidates` từ `luong-yte` với `sourceCode = HT-YTE`.
    Và cùng luồng gửi `sourceCode = QG-DANCU`.
    Và gọi API nội bộ từ ngoài mạng nội bộ qua APISIX.
    Thì bước 1 `202`, kênh `FLOW`. Bước 2 `403` ERR-06-014, nhật ký luồng PH-04 có câu "Luồng {mã} không được gửi dữ liệu thay nguồn {nguồn}". Bước 3 `404` (đường dẫn `/internal` không công bố ở cổng).
    # Hậu điều kiện: Một ứng viên kênh FLOW.

  @TC-06-024 @P2 @Dương @Âm
  Kịch bản: TC-06-024 Nạp qua sự kiện PH-10; sự kiện sai lược đồ vào DLQ
    # Truy vết: FR-06-012 · API-06-016 · ERR-06-110 · EVT-06-07
    # Mục đích: Chứng minh bộ nhận sự kiện nạp ứng viên đúng và không mất sự kiện hỏng, theo FR-06-012.
    Biết nguồn `HT-YTE` bật kênh `EVENT` với topic `t90.yte.cong-dan.cap-nhat.v1`.
    Khi đẩy 10 sự kiện hợp lệ.
    Và đẩy 1 sự kiện sai lược đồ.
    Thì bước 1 10 ứng viên kênh `EVENT`. Bước 2 sự kiện vào DLQ của PH-10, ghi ERR-06-110, bộ nhận không dừng; không ứng viên nào từ sự kiện hỏng.
    # Hậu điều kiện: DLQ có đúng 1 mục.
