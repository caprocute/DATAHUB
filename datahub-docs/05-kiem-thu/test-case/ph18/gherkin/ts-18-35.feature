# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-35
Tính năng: TS-18-35 · Chạy thử di trú, đối chiếu và xử lý bản ghi lỗi

  @TC-18-115 @P1 @Dương
  Kịch bản: TC-18-115 Chạy thử kế hoạch READY không ghi vào phân hệ đích, có báo cáo đối chiếu
    # Truy vết: FR-18-061, 064 · API-18-164, 165, 166, 171 · BR-18-040, 043 · EVT-18-25 · UI-18-21, 22
    # Mục đích: Chứng minh FR-18-061 và BR-18-043: worker `dh-migrate` đọc nguồn chỉ đọc, gọi API nhập của đích ở chế độ kiểm (`dryRun`), không có bản ghi nào được ghi, không có sự kiện nghiệp vụ.
    Biết T96; `PLAN-AITA` `READY`; `LEG-AITA` có 12.000 danh mục, 180 HTTT, 900 API (giả định quy mô GĐ-01); WireMock API nhập PH-07, PH-01, PH-02 đếm lời gọi ghi.
    Khi `POST /migration-runs` `mode = DRY_RUN`.
    Và theo dõi `GET /migration-runs/{runId}` tới xong.
    Và `GET /migration-runs/{runId}/reconciliation`.
    Thì bước 2 `SUCCEEDED`, đọc 13.080, hợp lệ 13.080; WireMock nhận 0 lời gọi ghi thật; không có sự kiện nghiệp vụ của PH-07, PH-01, PH-02; EVT-18-25 `mode = DRY_RUN`. Bước 3 báo cáo theo đối tượng có số nguồn, số đích dự kiến, tổng kiểm tra.

  @TC-18-116 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-116 Kế hoạch chưa READY, nguồn đọc lỗi, bộ chuyển đổi lỗi bản ghi
    # Truy vết: FR-18-061, 063 · API-18-164, 169, 170 · ERR-18-065, 117, 118
    # Mục đích: Chứng minh lỗi di trú được ghi đúng mã ở mức lần chạy và bản ghi.
    Biết T96; `PLAN-NHAP` `DRAFT`; `LEG-AITA` có 15 danh mục thiếu mã cha; ngắt nguồn ở bước 3.
    Khi chạy thử `PLAN-NHAP`.
    Và chạy thử `PLAN-AITA`, xem `GET /migration-runs/{runId}/errors`.
    Và chạy thử lần hai và ngắt nguồn giữa chừng; `:cancel` lần chạy còn lại.
    Thì bước 1 `409` ERR-18-065. Bước 2 `SUCCEEDED_WITH_ERRORS`, 15 bản ghi lỗi ERR-18-118 có khóa hệ cũ và lý do, xuất CSV được. Bước 3 lần chạy `FAILED` ghi ERR-18-117; lần hủy dừng sau lô hiện hành `CANCELLED`.

  @TC-18-117 @P2 @Dương @Âm
  Kịch bản: TC-18-117 Sửa ở nguồn rồi chạy lại chỉ các bản ghi lỗi, không còn bản ghi để chạy
    # Truy vết: FR-18-063 · API-18-164, 170 · BR-18-041 · ERR-18-036
    # Mục đích: Chứng minh FR-18-063: chạy lại theo danh sách lỗi, bản ghi đã sửa chuyển `FIXED_AT_SOURCE`, khi không còn bản ghi lỗi thì từ chối.
    Biết T96; lần chạy `RUN-DRY-02` có 15 bản ghi lỗi; DS sửa mã cha ở nguồn.
    Khi U-T96-DS `POST /migration-runs` `mode = DRY_RUN`, `retryErrorsOf = RUN-DRY-02`.
    Và gửi lại bước 1 khi không còn bản ghi `OPEN`.
    Thì bước 1 lần chạy chỉ đọc 15 bản ghi, 15 hợp lệ, danh sách lỗi cũ `FIXED_AT_SOURCE`. Bước 2 `422` ERR-18-036.

  @TC-18-118 @P1 @Âm
  Kịch bản: TC-18-118 Tổng kiểm tra của một đối tượng lệch được báo trong đối chiếu
    # Truy vết: FR-18-064 · API-18-171 · BR-18-041 · ERR-18-120
    # Mục đích: Chứng minh FR-18-064: lệch tổng kiểm tra không bị che, đối chiếu yêu cầu giải trình.
    Biết T96; WireMock PH-07 trả tổng kiểm tra khác cho đối tượng `CATALOG` (giả lập một mã bị chuẩn hóa).
    Khi chạy thử `PLAN-AITA`.
    Và tải báo cáo đối chiếu PDF và CSV.
    Thì lần chạy ghi ERR-18-120 cho `CATALOG`; báo cáo đánh dấu dòng lệch, trường "giải trình" bắt buộc trước khi chạy thật.
