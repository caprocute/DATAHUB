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
    Thì `409` ERR-14-026; phiên `PARTIAL`, bản ghi lỗi `422` ERR-14-028 thử lại được tối đa `14.sync.max-retries`, thử lại phiên đã xong `409` ERR-14-004; `502` ERR-14-027; cảnh báo tuân thủ ở ngày thứ 8.

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
