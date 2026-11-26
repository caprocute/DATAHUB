# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-27
Tính năng: TS-09-27 · Lịch lưu giữ, tác vụ xóa và báo cáo tuân thủ thời hạn lưu

  @TC-09-093 @P1 @Dương @Âm
  Kịch bản: TC-09-093 Lập, duyệt lịch lưu giữ và bảng DLCN thiếu thời hạn lưu
    # Truy vết: FR-09-040 · API-09-146, 149, 150 · UI-09-15 · ERR-09-057, 005 · BR-09-038
    # Mục đích: Chứng minh mỗi bảng chứa DLCN có thời hạn lưu tường minh (BR-09-038).
    Biết T90; bảng `ho_so_cong_dan` chứa DLCN chưa có lịch; U-T90-SO (soạn), U-T90-DA1 (duyệt).
    Khi SO `GET /retention-schedules` và mở UI-09-15.
    Và SO tạo lịch 36 tháng, hành động `PSEUDONYMIZE`; `:submit`; tự `:approve`; DA1 `:approve`.
    Thì bước 1 cảnh báo ERR-09-057 "Bảng ho_so_cong_dan chứa dữ liệu cá nhân nhưng chưa có thời hạn lưu." Bước 2 tự duyệt `403` ERR-09-005; DA1 `ACTIVE`; bảng hết cảnh báo.

  @TC-09-094 @P1 @Dương @Âm
  Kịch bản: TC-09-094 Chạy thử, chạy thật xóa hoặc giả danh hóa, không chạy chồng, báo cáo
    # Truy vết: FR-09-041, 044 · API-09-154, 152, 153, 163 · ERR-09-061 · EVT-09-19 · NFR-09-018
    # Mục đích: Chứng minh tác vụ xử lý đúng bản ghi hết hạn trong 24 giờ sau lịch, trừ đối tượng giữ pháp lý.
    Biết T90; 1.000 bản ghi giả quá hạn 36 tháng, 50 bản ghi đang giữ pháp lý; U-T90-SO.
    Khi SO `POST /retention-tasks:run` `dryRun = true`.
    Và SO chạy thật; ngay sau đó chạy lần hai.
    Và `GET /retention-reports`.
    Thì bước 1 liệt kê 950 bản ghi sẽ xử lý, không đổi dữ liệu. Bước 2 `202`, lần hai `409` ERR-09-061. Tác vụ `COMPLETED` giả danh hóa 950 bản ghi, bỏ qua 50 đang giữ; EVT: `retention.task-finished`. Bước 3 tỷ lệ tuân thủ 100 % ngoài đối tượng giữ pháp lý.

  @TC-09-095 @P2 @Dương @Âm
  Kịch bản: TC-09-095 Hủy tác vụ chưa chạy, sao lưu và tombstone
    # Truy vết: FR-09-041 · API-09-155 · ERR-09-006 · BR-09-040
    # Mục đích: Chứng minh chỉ hủy được tác vụ chưa chạy và danh sách xóa áp lại khi khôi phục sao lưu.
    Biết T90; tác vụ `QUEUED` và tác vụ `COMPLETED`; U-T90-SO.
    Khi SO `:cancel` tác vụ `QUEUED`; rồi `:cancel` tác vụ `COMPLETED`.
    Và khôi phục bản sao lưu 20 ngày tuổi trong môi trường thử.
    Thì bước 1 `200` rồi `409` ERR-09-006. Bước 2 trước khi phục vụ, hệ thống áp lại tombstone nên bản ghi đã xóa không xuất hiện lại.
