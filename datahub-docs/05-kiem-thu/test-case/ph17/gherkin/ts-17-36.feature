# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-36
Tính năng: TS-17-36 · Dùng tập dữ liệu đã ẩn danh của PH-09 cho đánh giá, không huấn luyện mô hình nền

  @TC-17-116 @P3 @Dương
  Kịch bản: TC-17-116 Gắn tập ẩn danh đã phát hành vào bộ đánh giá, chạy đánh giá
    # Truy vết: FR-17-062 · API-17-184, 185 · BR-17-084 · UI-17-11
    # Mục đích: Chứng minh BR-17-084: chỉ `RELEASED`, k ≥ 10, chỉ cho đánh giá và hiệu chuẩn.
    Biết PH-09 WireMock phát EVT-09-18 cho tập `DS-AI-1` (`RELEASED`, k = 12); U-T90-SO.
    Khi SO `POST /eval-datasets` gắn `DS-AI-1` vào `ES-SEARCH-1`.
    Và SO `POST /eval-runs` dùng tập.
    Và `GET /eval-datasets`.
    Thì bước 1 `201`, KT: có. Bước 2 lượt đánh giá chạy, không có thao tác huấn luyện hay tinh chỉnh nào. Bước 3 liệt kê `DS-AI-1`.

  @TC-17-117 @P2 @Âm @Bảo_mật
  Kịch bản: TC-17-117 Tập chưa phát hành, k thấp, đã bị rút hoặc hết hạn
    # Truy vết: FR-17-062 · API-17-185, 186 · BR-17-084 · ERR-17-085, 086, 116 · EVT-17-21
    # Mục đích: Chứng minh ERR-17-085, 086, 116 và xóa kết quả khi tập bị rút.
    Biết `DS-AI-2` ở trạng thái `DRAFT`; `DS-AI-3` k = 6; `DS-AI-1` đã gắn, rồi PH-09 phát EVT-09-18 `WITHDRAWN`.
    Khi SO gắn `DS-AI-2`.
    Và SO gắn `DS-AI-3`.
    Và PH-09 phát `WITHDRAWN` cho `DS-AI-1`; SO chạy `POST /eval-runs` dùng tập.
    Và SO `DELETE /eval-datasets/{linkId}`.
    Thì bước 1 `422` ERR-17-085. Bước 2 `409` ERR-17-086. Bước 3 `409` ERR-17-116, kết quả liên quan bị xóa. Bước 4 `200`, kết quả gắn với tập bị xóa.

  @TC-17-118 @P3 @Bảo_mật @Âm
  Kịch bản: TC-17-118 PH-17 không có đường huấn luyện hay tinh chỉnh mô hình nền
    # Truy vết: FR-17-062, 007 · BR-17-084 · API-17-184
    # Mục đích: Chứng minh phạm vi D01-02: cổng quản trị, không vận hành mô hình nền, GPU ngoài phạm vi.
    Biết hợp đồng OpenAPI `/api/assist/v1` và `/assist/v1`; mã nguồn `vn.datahub.assist`.
    Khi spectral duyệt hợp đồng, tìm đường dẫn chứa `train`, `fine-tune`, `finetune`.
    Và quét mã tìm lời gọi tới API huấn luyện của nhà cung cấp.
    Và gọi `POST /eval-datasets` với `evalSetId` hợp lệ và `datasetRef` trỏ tập mà PH-09 khai mục đích huấn luyện (`purposeCode = TRAINING`).
    Thì bước 1 và 2 không có. Bước 3 `400` ERR-17-003 (mục đích duy nhất là đánh giá).
