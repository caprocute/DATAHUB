# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-35
Tính năng: TS-20-35 · Bảng điều khiển đa tenant và kiểm thử rò rỉ chéo tenant

  @TC-20-175 @P1 @Dương
  Kịch bản: TC-20-175 Bảng điều khiển hiện KPI, danh sách cần xử lý và mốc cập nhật cuối
    # Truy vết: FR-20-067 · UC-20-35 · API-20-129 · NFR-20-006 · UI-20-20 · `PERM-20-read`
    Biết `U-PA1`, `U-PO`, `U-PAU`; số đếm chuẩn mục 2.4 (tenant theo trạng thái, 5 cảnh báo hạn mức, 2 lệch cấu hình, 1 kế hoạch nâng cấp đang chạy); `obs-sim`.
    Khi `GET P/dashboard?environment=STAGING` bằng `U-PA1`
    Và lặp lại bằng `U-PO` và `U-PAU`
    Và số liệu sử dụng trễ 2 giờ (`obs-sim` trễ)
    Và mở UI-20-20, bấm một dòng cần xử lý
    Thì bước 1 `200`, các thẻ: số tenant theo trạng thái, thời gian khởi tạo p95, KPI-12, cảnh báo hạn mức, lệch, nâng cấp đang chạy, lần rò rỉ gần nhất. Bước 2 cùng nội dung. Bước 3 hiện mốc cập nhật cuối. Bước 4 dẫn tới màn chi tiết đúng tenant. Thời gian tải đạt NFR-20-003.

  @TC-20-176 @P2 @Âm
  Kịch bản: TC-20-176 Bảng điều khiển: nguồn chỉ số lỗi, tham số sai, quyền
    # Truy vết: FR-20-067 · API-20-129 · ERR-20-062, ERR-20-004 · UI-20-20
    Biết `U-PA1`, `U-T90-TA`; `obs-sim` `503`.
    Khi `GET P/dashboard` khi Mimir giả `503`
    Và `GET P/dashboard?environment=KHAC`
    Và `U-T90-TA` `GET P/dashboard`
    Thì bước 1 `503` `ERR-20-062` hoặc `200` với thẻ lỗi hiện "Không có số liệu" (theo FR-067, thẻ lỗi độc lập); ghi nhận theo bản chạy. Bước 2 `400` `ERR-20-004`. Bước 3 `403` `ERR-00-403`.

  @TC-20-177 @P1 @Dương
  Kịch bản: TC-20-177 Chạy kiểm thử rò rỉ T90 sang T91, không có rò rỉ
    # Truy vết: FR-20-070 · UC-20-35 · API-20-132, 134, 133 · BR-20-004 · NFR-20-019 · UI-20-20 · `PERM-20-admin`
    Biết `U-PA1`; `T90`, `T91` `ACTIVE` kiểm thử; F-LEAK (danh mục API của PH-03, tài nguyên mồi ở `T99`); `mod-sim`.
    Khi `POST P/leak-tests` với `sourceTenant = T90`, `targetTenant = T91`, `apiScope = ALL`, kèm `Idempotency-Key`
    Và `GET P/leak-tests/{testRunId}` đến khi `COMPLETED`
    Và `GET P/leak-tests?status=COMPLETED`
    Thì bước 1 `202`. Bước 2 mỗi API có kết quả `PASSED`; API chỉ nền tảng `SKIPPED` kèm lý do; không phản hồi nào chứa dữ liệu đánh dấu của `T91`; gọi cả với tham số `tenantId` giả. Bước 3 có lần chạy.

  @TC-20-178 @P1 @Âm
  Kịch bản: TC-20-178 Phát hiện rò rỉ: mở sự cố mức 1, báo PO
    # Truy vết: FR-20-070 · UC-20-35 · API-20-132, 134 · ERR-20-111 · SEC-87 · UI-20-20
    Biết `U-PA1`, `U-PO`; một API giả cố ý trả dữ liệu đánh dấu của tenant đích (bản giả `mod-sim`); `ops-sim` nhận sự cố.
    Khi `POST P/leak-tests` `T92` → `T93`
    Và xem kết quả và sự cố
    Thì kết quả của API đó `LEAKED` với `ERR-20-111` ("Phát hiện rò rỉ chéo tenant ở GET /api/ops/v1/tai-nguyen."); sự cố mức 1 mở qua PH-18; PO nhận thông báo; thẻ "lần rò rỉ gần nhất" ở UI-20-20 cập nhật.

  @TC-20-179 @P1 @Âm
  Kịch bản: TC-20-179 Kiểm thử rò rỉ trên tenant ngoài T90…T99, đang chạy, quyền
    # Truy vết: FR-20-070 · API-20-132, 133, 134 · ERR-20-065, ERR-20-004, ERR-20-009, ERR-20-002 · BR-20-038
    Biết `U-PA1`, `U-PO`; `T01` (`testTenant = false`, tỉnh thật); `T90`.
    Khi `POST P/leak-tests` với `sourceTenant = T01`
    Và `POST` với `sourceTenant = T90`, `targetTenant = T90` hoặc thiếu trường
    Và `POST` với `Idempotency-Key` đã dùng cho yêu cầu khác
    Và `GET P/leak-tests/khong-co`; `GET P/leak-tests?status=KHAC`
    Và `U-PO` `POST P/leak-tests`
    Thì bước 1 `422` `ERR-20-065` ("Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."). Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-009`. Bước 4 `404` `ERR-20-002`, `400` `ERR-20-004`. Bước 5 `403` `ERR-00-403` (cần `PERM-20-admin`).

  @TC-20-180 @P3 @Dương
  Kịch bản: TC-20-180 Lịch kiểm thử rò rỉ định kỳ theo tham số
    # Truy vết: FR-20-070, 069 · BR-20-004 · UC-20-35
    Biết `20.leak-test.schedule` đặt hàng đêm; đồng hồ giả lập; ShedLock.
    Khi tiến đồng hồ tới lịch, hai bản DU cùng chạy
    Và xem `GET P/leak-tests`
    Thì chỉ một lần chạy được tạo (ShedLock); mặc định `T90`, `T91`.
