# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-37
Tính năng: TS-18-37 · Theo dõi chạy song song và đối soát bóng

  @TC-18-124 @P2 @Dương
  Kịch bản: TC-18-124 Theo dõi nhóm chạy song song, cầu nối PH-10 và tỷ lệ khớp mẫu bóng
    # Truy vết: FR-18-066, 067 · API-18-173, 174, 176 · EVT-18-27 · UI-18-23
    # Mục đích: Chứng minh FR-18-066, 067: trạng thái cầu nối từ EVT-10-15, EVT-10-16; bộ so sánh gửi cặp phản hồi đã băm; tỷ lệ khớp tính theo nhóm.
    Biết T96; nhóm `PG-THUE` 20 tuyến `PARALLEL`; S-SHADOW (`ops:shadow-ingest`); WireMock PH-10 phát EVT-10-15, EVT-10-16.
    Khi phát EVT-10-15 (cầu nối hoạt động).
    Và S-SHADOW gửi 1.000 cặp, 997 khớp băm.
    Và `GET /parallel-groups/PG-THUE`.
    Thì bước 1 nhóm hiện cầu nối `ACTIVE`. Bước 2 `202`. Bước 3 tỷ lệ khớp 99,7 %, mẫu lệch có tuyến, thời điểm, không có nội dung phản hồi.

  @TC-18-125 @P2 @Âm @Bảo_mật
  Kịch bản: TC-18-125 Mẫu lệch, danh tính sai gửi mẫu và sự kiện cầu nối xử lý lỗi
    # Truy vết: FR-18-067, 066 · API-18-176 · ERR-18-121, 124 · ERR-00-403
    # Mục đích: Chứng minh mẫu lệch được ghi ERR-18-121, scope `ops:shadow-ingest` là bắt buộc và lỗi tiêu thụ sự kiện PH-10 đi vào DLQ PH-18.
    Biết T96; S-NOSCOPE; WireMock PH-10.
    Khi S-SHADOW gửi 100 cặp, 5 lệch ở tuyến `/thue/v1/to-khai`.
    Và S-NOSCOPE gửi cặp.
    Và phát EVT-10-16 có thân hỏng làm bộ xử lý lỗi năm lần.
    Thì bước 1 5 mẫu lệch ghi ERR-18-121 nêu tuyến. Bước 2 `403` ERR-00-403. Bước 3 inbox `FAILED`, ghi ERR-18-124.

  @TC-18-169 @P2 @Dương @Âm
  Kịch bản: TC-18-169 Thay bộ quy tắc chuẩn hóa so sánh, mẫu trong cửa sổ được tính lại
    # Truy vết: FR-18-067 · API-18-184, 174 · ERR-18-007 · ERR-00-428 · EVT-18-27 · UI-18-23
    # Mục đích: Chứng minh luồng thay thế FR-18-067 qua API-18-184: lệch đã biết được chấp nhận bằng quy tắc chuẩn hóa có `If-Match` và lý do, tỷ lệ khớp tính lại trên mẫu 7 ngày.
    Biết T96; nhóm `PG-HT` tỷ lệ khớp 98,9 % do định dạng ngày `dd/MM/yyyy` và `yyyy-MM-dd` lệch ở 1,2 % mẫu; U-T96-TA1 có `PERM-18-migration`.
    Khi TA1 `PUT /parallel-groups/PG-HT/normalization-rules` thêm quy tắc đổi trường `ngaySinh` về ISO 8601 kèm `If-Match` và lý do.
    Và TA1 gửi lại bước 1 không có `If-Match`.
    Và TA1 gửi bước 1 với lý do 3 ký tự.
    Và chờ bộ so sánh tính lại, `GET /parallel-groups/PG-HT`.
    Thì bước 1 `200` bộ quy tắc phiên bản mới, ETag mới. Bước 2 `428` ERR-00-428. Bước 3 `422` ERR-18-007. Bước 4 tỷ lệ khớp tính lại trên mẫu trong 7 ngày đạt ≥ 99,5 %; nhóm sang `SHADOW_OK` khi đủ điều kiện, EVT-18-27 phát.
