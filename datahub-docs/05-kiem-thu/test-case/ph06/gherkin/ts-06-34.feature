# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-34
Tính năng: TS-06-34 · Chịu lỗi, khôi phục và quan sát

  @TC-06-145 @P1 @Chịu @lỗi
  Kịch bản: TC-06-145 PH-07 hoặc PH-09 ngừng
    # Truy vết: ERR-06-021 · FR-06-014, 015, 047 · NFR-06-011
    # Mục đích: Chứng minh nạp và resolve suy giảm đúng khi phụ thuộc ngừng.
    Biết T95; WireMock PH-07 rồi PH-09 trả `503`.
    Khi nạp ứng viên địa chỉ khi PH-07 ngừng.
    Và `resolve` khi PH-09 ngừng.
    Và khôi phục.
    Thì bước 1 `NORMALIZATION_PENDING`, tự xử lý sau khi khôi phục. Bước 2 `503` ERR-06-021, không trả dữ liệu chưa kiểm mục đích. Bước 3 hàng chờ tiêu hết, không mất ứng viên.
    # Hậu điều kiện: Không mất dữ liệu.

  @TC-06-146 @P1 @Chịu @lỗi
  Kịch bản: TC-06-146 PostgreSQL chuyển dự phòng, Kafka ngừng
    # Truy vết: NFR-06-012, 014 · ERR-06-109 · BR-06-005
    # Mục đích: Chứng minh RPO ≤ 15 phút, RTO ≤ 30 phút và outbox không mất sự kiện.
    Biết T95 chịu tải 50 thao tác mỗi giây.
    Khi chuyển dự phòng `pg-core`; đo thời gian dịch vụ tra cứu hồi phục.
    Và dừng Kafka 10 phút rồi bật.
    Thì không bản ghi vàng nào mất giao dịch đã commit, 0 bản ghi lệch ảnh chụp; hồi phục ≤ 30 phút; outbox phát đủ, thứ tự theo `goldenId`.
    # Hậu điều kiện: Số đo RTO, RPO.

  @TC-06-147 @P2 @Chịu @lỗi
  Kịch bản: TC-06-147 Đối sánh trực tuyến quá giờ
    # Truy vết: FR-06-021 · NFR-06-018 · UI-06-01
    # Mục đích: Chứng minh truy vấn > 800 ms thành `POSSIBLE_MATCH` lý do `TIMEOUT`.
    Biết T95; chèn độ trễ `pg_sleep` vào truy vấn khối.
    Khi `resolve` 100 lượt khi có độ trễ.
    Thì mọi lượt `202` `TIMEOUT`, `mdm_match_timeout_total` tăng; khi tỷ lệ > 1 % dashboard hiện cảnh báo "Đối sánh trực tuyến chậm".
    # Hậu điều kiện: Không đổi.

  @TC-06-148 @P2 @Dương
  Kịch bản: TC-06-148 Chỉ số và cảnh báo
    # Truy vết: NFR-06-018, 019 · FR-06-055
    # Mục đích: Chứng minh phát đủ chỉ số và bảy cảnh báo của NFR-06-019.
    Biết STAGING; Prometheus, Alertmanager PH-13.
    Khi kiểm danh sách chỉ số với bảng FR-06-055 và `mdm_event_lag_seconds`, `mdm_match_timeout_total`, `mdm_block_truncated_total`.
    Và mô phỏng: hàng đợi > 500, tự động < 80 %, lệch quốc gia > 5 %, mục chờ > 7 ngày, job thất bại, ghi vết lỗi, quét bất thường.
    Thì đủ chỉ số; mỗi mô phỏng sinh đúng một cảnh báo tới PH-13 trong ≤ 5 phút.
    # Hậu điều kiện: Không đổi.
