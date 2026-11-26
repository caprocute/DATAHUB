# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-26
Tính năng: TS-05-26 · Thay đổi lược đồ và chụp ảnh lại

  @TC-05-101 @P2 @Dương
  Kịch bản: TC-05-101 Thêm cột có thể null: tiếp tục, ghi nhận mức thông tin
    # Truy vết: FR-05-051 · EVT-05-11 · API-05-074
    Biết CDC `STREAMING`.
    Thì `cdc_schema_change` mức `INFO`; lược đồ Avro mới tương thích BACKWARD; CDC giữ `STREAMING`; bản ghi mới có trường `ghi_chu`.

  @TC-05-102 @P1 @Âm
  Kịch bản: TC-05-102 Đổi tên cột: CDC dừng trước khi phát
    # Truy vết: FR-05-051 · BR-05-022 · ERR-05-116 · EVT-05-11, 12 · UI-05-12
    Biết CDC `STREAMING`; người tiêu thụ đọc topic.
    Thì CDC `PAUSED_SCHEMA`; 0 bản ghi theo lược đồ mới trên topic (SMT `DhSchemaGate` chặn); EVT: `cdc.schema-changed` mức `BREAKING`; TO, IE nhận cảnh báo; UI-05-12 có banner và nút "Xử lý".

  @TC-05-103 @P1 @Âm @Dương
  Kịch bản: TC-05-103 Tiếp tục khi còn thay đổi chờ; ánh xạ cột rồi tiếp tục
    # Truy vết: FR-05-051, 050 · API-05-072, 074, 075 · ERR-05-026 · UI-05-13 · UC-05-20
    Biết U-T68-IE1, U-T68-TO; sau TC-05-102.
    Khi TO `POST …/cdc:resume`.
    Và IE1 ở UI-05-13 chọn "Ánh xạ cột" `ten_dn → ten_doanh_nghiep`, lý do, xác nhận.
    Và TO bấm "Tiếp tục CDC" trong toast.
    Thì bước 1 `409` ERR-05-026. Bước 2 `200`, toast "Còn 0 thay đổi chờ". Bước 3 `STREAMING`; 3 dòng đã ghi tới topic với tên trường cũ `ten_dn` theo ánh xạ. KT: có (quyết định, người, lý do).

  @TC-05-104 @P2 @Dương @Âm
  Kịch bản: TC-05-104 Mất nhật ký nguồn, chụp ảnh lại có lịch ngoài giờ
    # Truy vết: FR-05-053 · API-05-073 · ERR-05-117, 038 · EVT-05-12
    Biết U-T68-TO; CDC dừng lâu, slot bị xóa ở nguồn; bảng 12 triệu dòng (thống kê giả).
    Khi bật lại, quan sát trạng thái.
    Và `POST …/cdc:resnapshot` không lý do; có lý do nhưng không khung giờ; có khung giờ 22:00.
    Thì bước 1 `FAILED` với ERR-05-117. Bước 2 lần một `400` ERR-05-038; lần hai `400` ERR-05-003 (bảng > 10 triệu dòng cần khung giờ ngoài hành chính); lần ba `202`, chụp ảnh tăng dần chạy lúc 22:00, bản ghi `op = r`.
