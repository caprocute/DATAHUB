# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-26
Tính năng: TS-14-26 · Đồng bộ: danh mục dịch vụ, dữ liệu chủ, dữ liệu mở

  @TC-14-065 @P1 @Dương
  Kịch bản: TC-14-065 Đồng bộ danh mục dịch vụ lên Bộ, chỉ dịch vụ đã công bố
    # Truy vết: FR-14-043, 046 · API-14-053, 054, 055 · UI-14-11 · UC-14-29 · BR-14-035 · LGC-NGSP-006.
    Biết U-T68-TO; 5 dịch vụ chia sẻ `PUBLISHED`, 2 `DRAFT`, 3 API nội bộ; `sim-ndxp` nhận đăng ký.
    Khi `POST /sync/catalog-runs`.
    Và `GET /sync/runs/{runId}`; xem từng bản ghi ở UI-14-11.
    Thì chỉ 5 bản ghi gửi; không có API nội bộ hoặc dịch vụ tenant khác; phiên `SUCCEEDED`; lịch `14.sync.catalog-cron` chạy đúng.

  @TC-14-066 @P1 @Âm
  Kịch bản: TC-14-066 Đồng bộ lỗi: phiên trùng, bên nhận từ chối, phụ thuộc không khả dụng, thử lại
    # Truy vết: FR-14-043, 046 · API-14-054, 057, 053 · ERR-14-026, 027, 028, 004 · BR-14-026.
    Biết phiên đang chạy; `sim-ndxp` từ chối 1 bản ghi; PH-02 không khả dụng; `14.sync.stale-alert-days = 7`.
    Khi `POST /sync/catalog-runs` khi đang có phiên.
    Và chạy khi giả lập từ chối; `POST /sync/runs/{runId}:retry`.
    Và chạy khi PH-02 không khả dụng.
    Và không đồng bộ được 8 ngày giả lập.
    Thì `409` ERR-14-026; phiên `COMPLETED_WITH_ERRORS`, bản ghi lỗi `422` ERR-14-028 thử lại được tối đa `14.sync.max-retries`, thử lại phiên đã xong `409` ERR-14-004; `502` ERR-14-027; cảnh báo tuân thủ ở ngày thứ 8.

  @TC-14-067 @P3 @Âm
  Kịch bản: TC-14-067 Dữ liệu chủ hai chiều: thiếu ánh xạ, PH-09 chặn
    # Truy vết: FR-14-044 · API-14-056 · UC-14-30 · ERR-14-125, 126 · BR-14-010.
    Biết S-PH06; lô thiếu ánh xạ danh mục ở PH-07; lô có trường bị PH-09 cấm.
    Khi `POST /sync/master-data-runs` lô thiếu ánh xạ.
    Và chạy lô có trường cấm.
    Thì `422` ERR-14-125, không gửi gì; `403` ERR-14-126, không gửi gì.

  @TC-14-068 @P3 @Dương @Âm
  Kịch bản: TC-14-068 Công bố và rút dữ liệu mở lên NDOP
    # Truy vết: FR-14-045 · API-14-087, 088 · UC-14-31 · ERR-14-126, 028 · BR-14-010.
    Biết U-T68-TA; tập dữ liệu đã qua PH-09; P-NDOP `ACTIVE`.
    Khi `POST /open-datasets` tập hợp lệ.
    Và `POST /open-datasets/{datasetCode}:withdraw`.
    Và công bố tập có trường cá nhân.
    Thì công bố rồi rút thành công, có kiểm toán; bước 3 `403` ERR-14-126.

  @TC-14-128 @P2 @Dương
  Kịch bản: TC-14-128 Dữ liệu chủ hai chiều: chiều xuống, chiều lên đủ ánh xạ, gửi lại bản ghi lệch
    # Truy vết: FR-14-044 · API-14-056, 055, 057 · UC-14-30 · BR-14-010 · EVT-14-12.
    Biết S-PH06, U-T68-TO; lô nguồn PH-06 mẫu 100 bản ghi đã đủ ánh xạ ở PH-07 và qua kiểm tra PH-09; `sim-ndxp` `OK`, 3 bản ghi bị trung ương từ chối.
    Khi chạy chiều xuống: `POST /sync/master-data-runs` hướng `DOWN`.
    Và chạy chiều lên với lô 100 bản ghi, `batchRef = B1`.
    Và gửi lại `B1` lần hai.
    Và sửa 3 bản ghi lệch rồi `POST /sync/runs/{runId}:retry`.
    Thì bước 1 `202`, lô chuyển cho PH-06 kèm EVT-14-12 mang tham chiếu lô. Bước 2 `202`, bản tin ký, `sync_run` `kind = MASTER_DATA`, đối soát từng bản ghi: 97 thành công, 3 lệch. Bước 3 không gửi trùng nhờ chống trùng theo `batchRef`. Bước 4 gửi lại với `batchRef` mới có liên kết tới lô gốc; phiên cuối không còn bản ghi lệch.

  @TC-14-129 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-129 Công bố dữ liệu mở: trường bị cấm, NDOP từ chối, tự duyệt, NDOP ngừng
    # Truy vết: FR-14-045 · API-14-087, 088 · UC-14-31 · ERR-14-007, 028, 103, 126 · BR-14-010, 022 · PERM-14-sync.
    Biết U-T68-TA, U-T68-IA; P-NDOP; tập `tc-dm-co-dlcn` có cột CCCD, tập `tc-dm-sach` đã qua PH-09; `sim-ndxp` chế độ NDOP từ chối rồi `DOWN`.
    Khi công bố `tc-dm-co-dlcn`.
    Và công bố `tc-dm-sach` lần đầu, người đề nghị tự duyệt.
    Và công bố `tc-dm-sach` sau khi được duyệt, NDOP từ chối bản ghi.
    Và công bố khi NDOP `DOWN`.
    Và gỡ tập đã `WITHDRAWN`.
    Thì bước 1 `403` ERR-14-126 "Nguồn chứa trường không được công bố: {danh sách}. Loại trường đó khỏi tập dữ liệu mở.", không gửi gì. Bước 2 `403` ERR-14-007. Bước 3 `422` ERR-14-028 "Nền tảng dữ liệu mở từ chối tập {mã}: {lý do}." Bước 4 `503` ERR-14-103, lô giữ lại thử theo lịch. Bước 5 `409` ERR-14-004. Không bước nào làm tập chuyển trạng thái đã công bố.
