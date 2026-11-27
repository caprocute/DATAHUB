# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-27
Tính năng: TS-18-27 · Quản lý lịch ngày làm việc, cửa sổ bảo trì và đóng băng

  @TC-18-089 @P1 @Dương
  Kịch bản: TC-18-089 Ghi lịch 2027 có ngày lễ, ngày làm bù và tính hạn cộng 5 ngày làm việc
    # Truy vết: FR-18-045 · API-18-113, 114, 115, 116, 117 · BR-18-033, 034 · EVT-18-15 · UI-18-16
    # Mục đích: Chứng minh FR-18-045: `add-working-days` bỏ cuối tuần, ngày lễ và tính ngày làm bù; EVT-18-15 phát khi lịch đổi.
    Biết T90; U-T90-TA1 (`PERM-18-calendar`); `CAL-2027` (giả định: nghỉ Tết từ 05/02 đến 11/02/2027, làm bù thứ Bảy 20/02/2027); S-PH02 (`ops:calendar-read`).
    Khi TA1 `PUT /calendars/2027` với `CAL-2027`, `If-Match`.
    Và TA1 `POST /calendars/2027/holidays` thêm một ngày nghỉ.
    Và S-PH02 `POST /ops/internal/v1/calendar/T90:add-working-days` từ 04/02/2027 cộng 5.
    Và S-PH02 `GET /ops/internal/v1/calendar/T90:working-days` tháng 2/2027.
    Thì bước 1 `200`, EVT-18-15 `year = 2027`. Bước 2 `201`, EVT-18-15 phiên bản mới. Bước 3 kết quả là ngày làm việc thứ năm sau Tết theo bảng dữ liệu, `calendarMissing = false`. Bước 4 số ngày khớp bảng.

  @TC-18-090 @P2 @Biên @Âm
  Kịch bản: TC-18-090 Thiếu lịch tenant dùng COMMON, thiếu cả hai chỉ bỏ cuối tuần, lịch sai
    # Truy vết: FR-18-045 · API-18-114, 117 · BR-18-034 · ERR-18-049
    # Mục đích: Chứng minh BR-18-034 và kiểm hợp lệ lịch.
    Biết T92 không có lịch 2027, `COMMON` có lịch 2027; năm 2031 không có ở đâu.
    Khi tính hạn cho T92 năm 2027.
    Và tính hạn cho T92 năm 2031.
    Và TA ghi lịch 2027 có ngày 30/02.
    Thì bước 1 dùng lịch `COMMON`, `calendarSource = COMMON`. Bước 2 chỉ bỏ thứ Bảy, Chủ nhật, `calendarMissing = true`. Bước 3 `422` ERR-18-049.

  @TC-18-091 @P1 @Dương @Âm
  Kịch bản: TC-18-091 Tạo cửa sổ bảo trì và đóng băng, đọc trạng thái, chồng lấn bị từ chối
    # Truy vết: FR-18-046 · API-18-118, 119, 120, 121, 122 · BR-18-035 · ERR-18-050 · EVT-18-16 · UI-18-16
    # Mục đích: Chứng minh FR-18-046: cửa sổ có môi trường, thời gian; EVT-18-16 phát cho PH-02, PH-04; API trạng thái đóng băng trả đúng; cửa sổ cùng loại chồng nhau bị từ chối.
    Biết T90; U-PA1 (`PERM-18-calendar`); S-PH02.
    Khi U-PA1 `POST /maintenance-windows` `FREEZE` môi trường `PROD` từ 20/12 đến 05/01.
    Và S-PH02 `GET /ops/internal/v1/freeze-status/T90` trong khoảng đó.
    Và U-PA1 tạo cửa sổ `FREEZE` khác từ 01/01 đến 10/01.
    Và U-PA1 `PATCH` cửa sổ đầu, rồi `:cancel` kèm lý do.
    Thì bước 1 `201`, EVT-18-16 `kind = FREEZE`. Bước 2 `frozen = true`, `windowId`. Bước 3 `409` ERR-18-050. Bước 4 `200` rồi `CANCELLED`, EVT-18-16 `state = CANCELLED`.

  @TC-18-092 @P1 @Chịu_lỗi
  Kịch bản: TC-18-092 PH-18 vắng thì PH-02 coi là không đóng băng và ghi cảnh báo
    # Truy vết: FR-18-046, 072 · API-18-122 · BR-18-035, 007 · NFR-18-018
    # Mục đích: Chứng minh BR-18-035 và LP-18-04: phân hệ chủ quyết định chặn, PH-18 vắng không chặn phát hành.
    Biết T94; thư viện `dh-ops-client` ở PH-02 giả lập; tắt `dh-platform`.
    Khi PH-02 kiểm trạng thái đóng băng khi tắt `dh-platform`.
    Thì thư viện trả `frozen = false`, `source = FALLBACK`, PH-02 ghi cảnh báo và chỉ số `dh_ops_client_fallback_total`; thao tác phát hành của PH-02 không bị chặn bởi lỗi kết nối.
