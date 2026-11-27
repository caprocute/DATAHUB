# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-30
Tính năng: TS-18-30 · Theo dõi sao lưu, kiểm tra khôi phục và ghi nhận diễn tập DR

  @TC-18-099 @P1 @Dương
  Kịch bản: TC-18-099 Tác vụ thu thập báo bản sao lưu, bảng điều khiển hiện độ tươi
    # Truy vết: FR-18-052 · API-18-133, 134, 135 · BR-18-048 · NFR-18-012 · LGC-NFR-005 · UI-18-19
    # Mục đích: Chứng minh FR-18-052: đối tượng theo D03-09 §8.2 có lần chạy gần nhất, kết quả, dung lượng, độ tươi `FRESH`.
    Biết T90; S-BACKUP (`ops:backup-report`); đối tượng `pg-core/T90`, `garage/dh-t90-*`, `openbao/T90`.
    Khi S-BACKUP `POST /ops/internal/v1/backup/runs` cho ba đối tượng (CNPG/Barman, rclone Garage, OpenBao).
    Và U-PO1 mở `/van-hanh/sao-luu`.
    Và `GET /backup/runs?doiTuong=pg-core/T90`.
    Thì bước 1 `201` mỗi lần, có `sha256` biên bản khi có. Bước 2 ba dòng `FRESH`, thời điểm lần chạy gần nhất trễ ≤ 15 phút so với nguồn. Bước 3 lịch sử đúng.

  @TC-18-100 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-100 Sao lưu trễ quá 26 giờ phát cảnh báo và mở sự cố, thu thập lỗi
    # Truy vết: FR-18-052, 047 · API-18-133 · ERR-18-055, 122 · EVT-18-19, 17
    # Mục đích: Chứng minh EVT-18-19 khi trễ quá `18.backup.stale-hours`, sự cố tự mở (FR-18-047), lỗi thu thập ghi rõ công cụ.
    Biết T95 (đồng hồ giả); `pg-core/T95` lần cuối 27 giờ trước; WireMock Velero trả `500`.
    Khi chạy tác vụ kiểm độ tươi.
    Và chạy tác vụ thu thập Velero.
    Và `GET /backup/objects` khi tác vụ thu thập không lấy được trạng thái.
    Thì bước 1 đối tượng `STALE`, EVT-18-19 `reason = STALE`, sự cố `SEV2` mở. Bước 2 ghi ERR-18-122. Bước 3 `200` có cờ `collectorError` và câu ERR-18-055 ở UI-18-19.

  @TC-18-101 @P1 @Dương @Âm
  Kịch bản: TC-18-101 CronJob báo kết quả kiểm tra khôi phục, đối tượng không có trả 404
    # Truy vết: FR-18-053 · API-18-136, 137 · ERR-18-001 · EVT-18-20 · UI-18-19
    # Mục đích: Chứng minh FR-18-053: kết quả có số dòng lệch, thời lượng; EVT-18-20 phát; kết quả thất bại làm đối tượng mất trạng thái "0 lỗi".
    Biết T90; S-BACKUP.
    Khi S-BACKUP `POST /ops/internal/v1/backup/verifications` `pg-core/T90` `PASSED`.
    Và gửi kết quả `FAILED` cho `garage/dh-t90-ops`.
    Và gửi cho đối tượng `khong-co`.
    Thì bước 1 `201`, EVT-18-20. Bước 2 `201`, UI-18-19 hiện đối tượng đỏ. Bước 3 `404` ERR-18-001.

  @TC-18-102 @P3 @Dương @Âm
  Kịch bản: TC-18-102 Ghi nhận diễn tập DR và PITR có RTO, RPO, biên bản SHA-256
    # Truy vết: FR-18-058 · API-18-154, 155 · BR-18-048 · ERR-18-003 · UI-18-19
    # Mục đích: Chứng minh FR-18-058: chỉ ghi nhận, không chạy; thiếu biên bản hoặc RTO âm bị từ chối.
    Biết U-PA1; biên bản PDF đã tải lên Garage.
    Khi `POST /dr-drills` loại `PITR_CLUSTER`, RTO 95 phút, RPO 4 phút, biên bản kèm `sha256`.
    Và gửi lại thiếu biên bản và RTO -5.
    Và `GET /dr-drills`.
    Thì bước 1 `201`. Bước 2 `400` ERR-18-003. Bước 3 danh sách có diễn tập vừa ghi.
