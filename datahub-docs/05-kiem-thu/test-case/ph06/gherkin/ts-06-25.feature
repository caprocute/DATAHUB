# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-25
Tính năng: TS-06-25 · Đồng bộ CSDL tổng hợp quốc gia và xử lý lệch

  @TC-06-106 @P1 @Dương
  Kịch bản: TC-06-106 Chiều xuống: thuộc tính thẩm quyền quốc gia thắng
    # Truy vết: FR-06-053 · BR-06-003, 032 · NFR-06-020 · API-06-080 · UI-06-14 · PERM-06-sync
    # Mục đích: Chứng minh bản ghi quốc gia vào như ứng viên nguồn mức 1 và ghi đè giá trị địa phương, theo FR-06-053.
    Biết T94; `nat-sim` gửi 100 bản ghi; bản ghi vàng có `dateOfBirth` địa phương khác.
    Khi `nat-sim` gửi bản ghi kênh `NATIONAL_SYNC`.
    Và `GET /national-sync/status`.
    Thì `dateOfBirth` lấy theo quốc gia, `GoldenChangeType = NATIONAL_SYNC`, ảnh chụp, lineage nguồn `QG-DANCU`; `nationalSyncedAt` cập nhật; áp trong ≤ 15 phút từ lúc nhận (NFR-06-020). Không có kết nối từ `dh-data` tới host quốc gia, chỉ tới PH-14.
    # Hậu điều kiện: 100 bản ghi vàng đồng bộ.

  @TC-06-107 @P1 @Dương
  Kịch bản: TC-06-107 Đối chiếu 1.000 bản ghi lệch 2 %
    # Truy vết: FR-06-053, 054 · API-06-081, 083 · EVT-06-12 · UI-06-14
    # Mục đích: Chứng minh lượt đối chiếu trong ngưỡng áp lệch thẩm quyền và đưa lệch khác vào danh sách, theo FR-06-053.
    Biết T94 F-SYNC lệch 2 % (20 bản ghi: 8 thuộc tính thẩm quyền, 12 thuộc tính khác).
    Khi `POST /national-sync/runs` `RECONCILE`.
    Và `GET /national-sync/discrepancies`.
    Thì job `NATIONAL_RECONCILE` `SUCCEEDED`; 8 lệch thẩm quyền tự áp; 12 lệch còn `OPEN` với `DiscrepancySeverity` đúng (nhân thân `CRITICAL`); một EVT-06-12.
    # Hậu điều kiện: 12 lệch OPEN.

  @TC-06-108 @P1 @Âm
  Kịch bản: TC-06-108 Lệch 8 % tạm dừng đồng bộ tự động
    # Truy vết: FR-06-053 · BR-06-011 · ERR-06-044, 107 · EVT-06-13 · UI-06-14
    # Mục đích: Chứng minh tiêu chí chấp nhận 8: lệch > 5 % thì không áp lệch nào và cảnh báo.
    Biết T94 F-SYNC lệch 8 % (80/1.000); `06.sync.pause-ratio = 0,05`.
    Khi chạy `RECONCILE`.
    Và chạy lại `POST /national-sync/runs`.
    Và DA1 điều tra và `POST /national-sync:resume`, chọn bỏ các lệch.
    Thì bước 1 đồng bộ `PAUSED`, không bản ghi vàng nào đổi, ERR-06-107 "tỷ lệ lệch 8% vượt 5%", EVT-06-13, cảnh báo DA, TA, băng đỏ UI-06-14. Bước 2 `409` ERR-06-044. Bước 3 `RUNNING`, EVT-06-13 (tiếp tục). KT: có (sync-pause, sync-resume).
    # Hậu điều kiện: Đồng bộ RUNNING; 80 lệch đã xử lý.

  @TC-06-109 @P2 @Dương @Âm
  Kịch bản: TC-06-109 Chiều lên theo danh mục thuộc tính
    # Truy vết: FR-06-053 · API-06-082 · ERR-06-045 · BR-06-025
    # Mục đích: Chứng minh chỉ thuộc tính không thẩm quyền trong `06.sync.up-attributes` được gửi lên, theo FR-06-053 (Q06-02).
    Biết T94; `06.sync.up-attributes` rỗng, rồi `["email"]`.
    Khi chạy `NATIONAL_SYNC_UP` khi rỗng.
    Và đặt `["email"]`, chạy lại.
    Và đặt `["dateOfBirth"]`.
    Thì bước 1 không gửi gì. Bước 2 PH-14 nhận đúng `email`. Bước 3 `422` ERR-06-045 (thuộc tính thẩm quyền quốc gia).
    # Hậu điều kiện: Danh mục `["email"]`.

  @TC-06-110 @P1 @Dương @Âm
  Kịch bản: TC-06-110 Xử lý danh sách lệch
    # Truy vết: FR-06-054 · BR-06-014, 025 · API-06-084 · ERR-06-035 · PERM-06-sync
    # Mục đích: Chứng minh bốn cách giải quyết `DiscrepancyResolution` và cấm giữ giá trị địa phương cho thuộc tính thẩm quyền, theo BR-06-025.
    Biết ba lệch OPEN: thuộc tính thẩm quyền, thuộc tính khác, hai chiều mâu thuẫn.
    Khi `:resolve` `ACCEPT_NATIONAL` lệch 1.
    Và `KEEP_LOCAL` lệch 1 khác thẩm quyền; `KEEP_LOCAL` lệch thẩm quyền.
    Và `REPORT_TO_NATIONAL`; `IGNORE` kèm lý do.
    Thì `ACCEPTED_NATIONAL`; `KEPT_LOCAL` hợp lệ với thuộc tính thường; `KEEP_LOCAL` với thuộc tính thẩm quyền `422` ERR-06-035; `REPORTED_TO_NATIONAL`, `IGNORED`; mọi quyết định có lý do và KT.
    # Hậu điều kiện: Các lệch đã đóng.

  @TC-06-111 @P2 @Chịu @lỗi
  Kịch bản: TC-06-111 PH-14 không khả dụng hoặc dữ liệu mâu thuẫn
    # Truy vết: FR-06-053 · BR-06-032 · ERR-06-106, 108
    # Mục đích: Chứng minh đồng bộ suy giảm có kiểm soát khi PH-14 lỗi, theo FR-06-053.
    Biết T94, T95; `nat-sim` ngừng, rồi trả hai giá trị quốc gia mâu thuẫn cho một khóa.
    Khi chạy đồng bộ khi `nat-sim` ngừng.
    Và chạy khi dữ liệu quốc gia mâu thuẫn.
    Thì bước 1 ERR-06-106 ở nhật ký, thử lại giãn dần, tra cứu nội bộ không bị ảnh hưởng. Bước 2 ERR-06-108, bản ghi bỏ qua, vào danh sách lệch, không áp giá trị nào.
    # Hậu điều kiện: Không bản ghi vàng đổi.
