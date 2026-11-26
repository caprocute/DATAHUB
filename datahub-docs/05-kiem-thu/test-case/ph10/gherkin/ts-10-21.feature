# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-21
Tính năng: TS-10-21 · Phát lại theo khoảng có duyệt bốn mắt

  @TC-10-093 @P1 @Dương
  Kịch bản: TC-10-093 Phát lại theo khoảng thời gian không đổi vị trí subscription
    # Truy vết: FR-10-051, 052 · API-10-064, 059, 104 · UI-10-16 · EVT-10-12 · UC-10-19
    Biết U-T68-TO, U-T68-IA1; SUB-PUSH đã giao 20.000 sự kiện trong 2 ngày.
    Khi Ở UI-10-16 chọn SUB-PUSH, `REDELIVER_RANGE`, `rangeType = TIME`, khoảng 1 giờ, `ratePerSecond = 500`, lý do, đánh dấu xác nhận nhận trùng.
    Và IA1 duyệt; theo dõi tiến độ.
    Thì bước 1 `201` có `estimatedRecords` và thời gian chạy ước lượng. Bước 2 `APPROVED`, `RUNNING`, `COMPLETED`; tốc độ thực ≤ 500/giây; nhóm `dh-sub-t68-ht-thue-dn-cap-phep` không đổi offset; SIM-WH nhận lượt có `X-Datahub-Replay`. EVT: `replay.completed`. KT: có (phạm vi, ước lượng, người duyệt).

  @TC-10-094 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-094 Người đề nghị tự duyệt, TA tự duyệt, thiếu xác nhận
    # Truy vết: FR-10-051 · API-10-064, 059 · ERR-10-008, 009 · BR-10-010, 028
    Biết U-T68-TA (có `operate` và `approve`); U-T68-TO; U-T68-SO.
    Khi TA đề nghị rồi tự duyệt.
    Và TO đề nghị không có `reason`; `acknowledgeDuplicates = false`.
    Và SO đề nghị phát lại.
    Thì bước 1 duyệt `403` ERR-10-008. Bước 2 `400` ERR-10-009. Bước 3 403-PQ (SO không phát lại). Không có lượt nào chạy.

  @TC-10-095 @P1 @Âm @Biên
  Kịch bản: TC-10-095 Khoảng ngoài lưu giữ, vượt trần, trùng lượt, đặt lại offset khi chưa tạm dừng
    # Truy vết: FR-10-051 · API-10-064 · ERR-10-032, 033, 034, 035
    Biết U-T68-TO; SUB-PUSH `ACTIVE` có một lượt `APPROVED` chờ chạy; `10.replay.max-records = 1000000`.
    Khi `rangeType = TIME` từ 10 ngày trước.
    Và `rangeType = OFFSET` khoảng 1.500.000 bản tin.
    Và lượt thứ hai cho SUB-PUSH.
    Và `RESET_OFFSET` khi SUB-PUSH `ACTIVE`.
    Thì bước 1 `422` ERR-10-033 có `availableRange[]`. Bước 2 `422` ERR-10-034. Bước 3 `409` ERR-10-035. Bước 4 `409` ERR-10-032.

  @TC-10-096 @P1 @Dương
  Kịch bản: TC-10-096 Đặt lại offset có duyệt, lưu vị trí trước
    # Truy vết: FR-10-051, 052, 040 · API-10-050, 064, 059, 098
    Biết U-T68-TO, U-T68-IA1; SUB-PULL.
    Khi TO tạm dừng SUB-PULL; đề nghị `RESET_OFFSET` về `fromTime` hôm qua, `acknowledgeDuplicates = true`.
    Và IA1 duyệt; TO tiếp tục; HTTT kéo.
    Thì lượt `COMPLETED` do control plane chạy; `previousOffsets` ghi vị trí cũ theo phân vùng; offset nhóm khớp `offsetsForTimes`; lượt kéo đầu trả sự kiện từ hôm qua.

  @TC-10-097 @P2 @Dương @Âm
  Kịch bản: TC-10-097 Hủy lượt đang chạy; lượt duyệt quá 24 giờ hết hạn
    # Truy vết: FR-10-052 · API-10-065, 087 · ERR-10-006, 009 · EVT-10-12
    Biết U-T68-TO; lượt `RUNNING` 100.000 bản tin ở 100/giây; lượt `APPROVED` khác chưa chạy.
    Khi `:cancel` có lý do khi đã giao khoảng 3.000.
    Và `:cancel` lượt `COMPLETED`.
    Và đặt đồng hồ +25 giờ cho lượt `APPROVED`.
    Thì bước 1 dừng sau bản tin đang giao, `CANCELLED`, `deliveredRecords` khớp số SIM-WH nhận. Bước 2 `409` ERR-10-006. Bước 3 lượt tự chuyển `CANCELLED`. EVT: `replay.completed` với trạng thái cuối.
