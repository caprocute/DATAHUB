# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-25
Tính năng: TS-05-25 · Thiết lập và chạy CDC

  @TC-05-095 @P1 @Dương
  Kịch bản: TC-05-095 Khai báo CDC, đăng ký topic và lược đồ
    # Truy vết: FR-05-048 · API-05-067, 068 · UI-05-12 · UC-05-19
    Biết U-T68-IE1; A-CDC; C-CDC TEST; PH-10 SIT.
    Thì `200`, trạng thái `STOPPED`; topic `t68.cdc.dkkd-cdc.dkkd.doanh_nghiep.v1` và lược đồ Avro có ở PH-10, Apicurio; đặc tả `KafkaConnector` ở nhánh môi trường của kho GitOps, chưa áp.

  @TC-05-096 @P2 @Âm
  Kịch bản: TC-05-096 Bảng ngoài phạm vi, PH-10 không khả dụng, vượt trần bảng
    # Truy vết: FR-05-048 · API-05-068 · ERR-05-027, 029, 030
    Biết U-T68-IE1; `05.cdc.max-tables = 50`.
    Khi khai bảng `ke_toan.so_cai`.
    Và dừng PH-10, khai hợp lệ.
    Và khai 51 bảng.
    Thì bước 1 `422` ERR-05-027. Bước 2 `503` ERR-05-029. Bước 3 `422` ERR-05-030.

  @TC-05-097 @P1 @Dương @Âm
  Kịch bản: TC-05-097 Kiểm tra điều kiện CDC đạt và không đạt
    # Truy vết: FR-05-049 · API-05-069, 070 · ERR-05-025 · UI-05-12
    Biết U-T68-IE1; SIM-PG; SIM-PG-BAD.
    Khi kiểm tra với SIM-PG.
    Và đổi kết nối sang SIM-PG-BAD, kiểm tra; rồi `POST …/cdc:start`.
    Thì bước 1 mọi mục đạt (`wal_level`, quyền `REPLICATION`, publication đúng bảng, slot còn chỗ). Bước 2 mục `wal_level` không đạt kèm hướng dẫn gửi đơn vị chủ quản; `start` `422` ERR-05-025.

  @TC-05-098 @P1 @Dương
  Kịch bản: TC-05-098 Chạy CDC: chụp ảnh ban đầu rồi đọc thay đổi
    # Truy vết: FR-05-050, 052 · API-05-070, 067 · EVT-05-12, 13 · NFR-05-009
    Biết U-T68-TO; sau TC-05-097 bước 1; bảng `doanh_nghiep` 10.000 dòng.
    Khi `POST …/cdc:start`.
    Và sau khi `STREAMING`, `INSERT`, `UPDATE`, `DELETE` ở SIM-PG.
    Và `GET …/cdc`.
    Thì `SNAPSHOTTING` → `STREAMING`; EVT: `cdc.state-changed` mỗi lần đổi. Topic bảng có 10.000 bản ghi `op = r` rồi đúng ba bản ghi `c`, `u`, `d`; `so_dien_thoai` đã băm. Bước 3 có vị trí LSN, độ trễ, số sự kiện theo loại.

  @TC-05-099 @P1 @Dương
  Kịch bản: TC-05-099 Tạm dừng, tiếp tục; khởi động lại không mất thay đổi
    # Truy vết: FR-05-050 · API-05-071, 072 · NFR-05-010
    Biết CDC `STREAMING` từ TC-05-098.
    Khi `:pause`; ghi 500 thay đổi ở nguồn; `:resume`.
    Và xóa pod Kafka Connect giữa lúc ghi 5.000 thay đổi.
    Thì bước 1 cả 500 thay đổi tới topic sau khi tiếp tục. Bước 2 không mất thay đổi nào (đối chiếu khóa và `source.lsn`); trùng chỉ trong cửa sổ từ offset cuối.

  @TC-05-100 @P2 @Dương
  Kịch bản: TC-05-100 Dừng hẳn giải phóng slot
    # Truy vết: FR-05-050 · BR-05-022
    Biết U-T68-TO; CDC `STREAMING`.
    Thì connector bị xóa khỏi GitOps; slot còn tới 7 ngày rồi bị xóa ở SIM-PG; `pg_replication_slots` không còn slot `dh_t68_dkkd_cdc`.

  @TC-05-154 @P2 @Âm
  Kịch bản: TC-05-154 Trạng thái CDC của bộ điều hợp không phải CDC hoặc tenant khác
    # Truy vết: FR-05-052 · API-05-067 · ERR-05-001, 003
    Biết U-T68-VW; U-T01-IE.
    Thì lần một `404` ERR-05-001 (không có cấu hình CDC). Lần hai 404-ẩn. Lần ba `400` ERR-05-003.
