# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-01
Tính năng: TS-15-01 · Đồng bộ danh mục từ PH-02

  @TC-15-001 @P1 @Dương
  Kịch bản: TC-15-001 Nạp đầu từ PH-02 phân trang tới hết
    # Truy vết: FR-15-001 · UC-15-04 · API-15-009, 131 · UI-15-27 · EVT-15-14 · BR-15-001 · LGC-APIM-006.
    Biết S-PH02 (WireMock API-02-081) trả F-CAT (10 API, 1 topic, 12 phiên bản) chia 3 trang; tenant T68 chưa có mốc đồng bộ.
    Khi khởi động mô-đun `portal`.
    Và đọc `GET /catalog/sync-status` (U-T68-TA) mỗi 2 giây đến khi `state = IDLE`.
    Và `GET /catalog/apis?co=100` bằng U-T68-TA.
    Thì lần gọi đầu tới API-02-081 không có `updatedSince`, đọc đủ 3 trang; `itemCount = 11`; `lagSeconds` ≤ 5; đúng một EVT-15-14 `RUNNING` rồi một `IDLE`; đặc tả của 12 phiên bản có `contentHash`; mục `an-khoi-cong` (`portalPublished = false`) được lưu nhưng không hiện cho ai.

  @TC-15-002 @P1 @Dương
  Kịch bản: TC-15-002 Sự kiện PH-02 cập nhật bản sao trong 30 giây, loại trùng
    # Truy vết: FR-15-001 · UC-15-04 · EVT-15-14 · BR-15-001 · NFR-15-004 · LGC-APIM-006.
    Biết bản sao đã nạp; S-PH02 phát EVT-02-02 cho `tra-cuu-ho-tich` (đổi mô tả, `sourceVersion` 10 → 11), gửi hai lần cùng mã sự kiện.
    Khi ghi nhận thời điểm phát sự kiện.
    Và gọi `GET /catalog/apis/tra-cuu-ho-tich` (U-T68-DEV-AN) mỗi giây.
    Thì mô tả mới hiện ≤ 30 giây; bản ghi chỉ được ghi đè một lần (inbox loại trùng, ADR-042); bộ đệm trang chi tiết bị vô hiệu; chỉ mục tìm kiếm cập nhật.

  @TC-15-003 @P1 @Dương
  Kịch bản: TC-15-003 Mục bị gỡ ở PH-02 biến mất ở cổng
    # Truy vết: FR-15-001 · UC-15-04 · BR-15-001, 002 · ERR-15-001 · LGC-APIM-006.
    Biết F-CAT; mục `api-thu-nghiem` đã đồng bộ và đang hiển thị; S-PH02 đưa nó vào `removed[]` (EVT-02-06).
    Khi chạy kéo bù (`POST /admin/sync:run`, U-T68-TA).
    Và `GET /catalog/apis/api-thu-nghiem` và `GET /search?q=thử nghiệm` bằng U-T68-DEV-AN.
    Thì mục bị gỡ đánh dấu ẩn (xóa mềm): `404` ERR-15-001 và vắng mặt ở danh sách, tìm kiếm; mục khác không đổi. Gọi lại PH-02 với `If-None-Match` nhận `304` thì chỉ ghi mốc kiểm tra, không đổi `updated_at` của mục nào.

  @TC-15-004 @P1 @Âm
  Kịch bản: TC-15-004 PH-02 hỏng: giữ bản sao, cảnh báo, ẩn thử production sau 24 giờ
    # Truy vết: FR-15-001 · UC-15-04 · UI-15-02 · EVT-15-14 · BR-15-033 · NFR-15-008 · LGC-APIM-006.
    Biết bản sao đã nạp; `15.sync.stale-seconds = 300` (tối thiểu); S-PH02 trả `503`; đồng hồ giả lập.
    Khi cho S-PH02 trả `503`; quan sát nhịp thử lại.
    Và sau 6 phút `GET /catalog/sync-status`; mở UI-15-02 bằng U-T68-DEV-AN.
    Và đẩy đồng hồ thêm 24 giờ; mở UI-15-06 cho `thoi-tiet-cong-khai`.
    Thì thử lại lùi mũ 5, 30, 120 giây; `state = STALE`, EVT-15-14; UI-15-02 có banner "Danh mục có thể chưa phản ánh thay đổi mới nhất." nhưng danh mục và tài liệu vẫn đọc được; sau 24 giờ nút "Thử trên môi trường thật" bị ẩn; khi PH-02 hồi phục, `state` về `IDLE` không cần can thiệp.

  @TC-15-005 @P2 @Âm
  Kịch bản: TC-15-005 Tenant chưa nạp xong: 503 và trang chủ vẫn dựng
    # Truy vết: FR-15-001, 003 · UC-15-04 · API-15-005 · UI-15-01 · ERR-15-008 · LGC-APIM-006.
    Biết tenant mới T90 chưa từng đồng bộ; trang `huong-dan` đã đăng.
    Khi `GET /catalog/apis` (người dùng T90).
    Và mở UI-15-01.
    Thì bước 1 trả `503` ERR-15-008, `detail` "Danh mục đang được chuẩn bị. Vui lòng quay lại sau ít phút"; bước 2 khối danh mục hiện thông báo, các khối nội dung vẫn hiển thị.

  @TC-15-006 @P2 @Âm
  Kịch bản: TC-15-006 Đặc tả hỏng giữ bản cũ, không kéo theo API khác
    # Truy vết: FR-15-001, 009 · UC-15-04 · API-15-016 · ERR-15-009 · BR-15-001 · LGC-APIM-006.
    Biết F-SPEC-BAD là đặc tả mới của phiên bản `1.0.0` `tra-cuu-ho-tich`; mục khác bình thường.
    Khi S-PH02 phát EVT-02-03 kèm đặc tả hỏng; chờ đồng bộ.
    Và `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/spec`.
    Và `GET /catalog/apis/dm-hanh-chinh`.
    Thì cổng giữ đặc tả đã nạp trước đó, ghi cảnh báo vào nhật ký vận hành (không hiện cho người dùng); khi chưa từng có đặc tả hợp lệ bước 2 trả `422` ERR-15-009; bước 3 bình thường.
