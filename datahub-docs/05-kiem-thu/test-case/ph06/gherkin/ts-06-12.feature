# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-12
Tính năng: TS-06-12 · Hàng đợi người quản lý dữ liệu

  @TC-06-057 @P1 @Dương
  Kịch bản: TC-06-057 Tạo mục hàng đợi, ưu tiên và SLA
    # Truy vết: FR-06-027 · BR-06-002, 019 · EVT-06-08 · API-06-045
    # Mục đích: Chứng minh công thức ưu tiên 0…100, hạn SLA và không tạo trùng cặp, theo FR-06-027.
    Biết bảy lý do `QueueReason`; mặc định `06.queue.sla-days = 7`.
    Khi tạo mục cho từng `QueueReason`.
    Và tạo mục lần hai cho cùng một cặp, đổi thứ tự hai bản ghi.
    Thì điểm cơ sở `IDENTIFIER_CONFLICT` 90, `CRITICAL_CONFLICT` 70, `MULTIPLE_CANDIDATES` 50, `POSSIBLE_MATCH` 40, `INSUFFICIENT_ATTRIBUTES` 30, `ORPHANED` 20, cộng tối đa 10 + 10 theo số liên kết và độ gần ngưỡng, trần 100. SLA 7 ngày, riêng `IDENTIFIER_CONFLICT` 1 ngày. Cặp trùng chỉ cập nhật điểm, không mục mới. Mỗi mục mới một EVT-06-08.
    # Hậu điều kiện: Bảy mục `OPEN`.

  @TC-06-058 @P1 @Dương
  Kịch bản: TC-06-058 Liệt kê, nhận việc, phân công, nhả
    # Truy vết: FR-06-028 · API-06-045, 047 · UI-06-04 · PERM-06-steward
    # Mục đích: Chứng minh lọc, sắp theo ưu tiên, nhận việc, giữ 30 phút, phân công bởi DA, theo FR-06-028.
    Biết bảy mục của q-create; DS1, DS2, DA1.
    Khi DS1 `GET /stewardship/items?status=OPEN&sort=priority,desc`.
    Và DS1 `:claim` mục đầu; đợi quá `06.queue.hold-minutes`.
    Và DA1 `:assign` mục khác cho DS2; DS2 `:release`.
    Thì bước 1 xếp ưu tiên giảm dần. Bước 2 mục `ASSIGNED` cho DS1, hết 30 phút tự nhả về `OPEN`. Bước 3 `ASSIGNED` rồi `OPEN`. Mỗi chuyển có KT.
    # Hậu điều kiện: Mục trả về OPEN.

  @TC-06-059 @P1 @Âm
  Kịch bản: TC-06-059 Hai người cùng nhận, mục ngoài tổ chức
    # Truy vết: FR-06-028 · API-06-047 · ERR-06-027, 028 · UI-06-05
    # Mục đích: Chứng minh khóa nhận việc và phạm vi tổ chức của DS (`○`), theo FR-06-028.
    Biết mục M1 của nguồn Sở Y tế; DS1 (Y tế), DS2 (Giáo dục).
    Khi DS1 và DS2 cùng gọi `:claim` M1 trong 100 ms.
    Và DS2 `:claim` mục chỉ gồm dữ liệu nguồn Sở Y tế.
    Thì bước 1 một `200`, một `409` ERR-06-027, UI chuyển sang mục kế tiếp. Bước 2 `403` ERR-06-028.
    # Hậu điều kiện: M1 của DS1.

  @TC-06-060 @P1 @Dương
  Kịch bản: TC-06-060 Quá hạn SLA, nâng ưu tiên, quá tải
    # Truy vết: FR-06-032 · BR-06-002 · NFR-06-019 · UI-06-04, 01 · API-06-050
    # Mục đích: Chứng minh quá hạn +20 điểm, giao lại sau 14 ngày, cảnh báo quá tải mà không tự quyết cặp, theo FR-06-032.
    Biết T92 (`06.queue.max-open = 100`); đồng hồ giả lập.
    Khi tiến thời gian 8 ngày; đọc `GET /stewardship/stats`.
    Và tiến tới 15 ngày.
    Và tạo 101 mục mở.
    Thì bước 1 mục `overdue`, điểm +20 (trần 100), thông báo người nhận và DA. Bước 2 giao DA phân công lại. Bước 3 cảnh báo quá tải tới PH-13 có phân tích theo nguồn và lý do; mọi cặp vẫn `OPEN`, không cặp nào tự động hợp nhất (BR-06-002). `mdm_queue_open`, `overdue`, `age_seconds` đúng.
    # Hậu điều kiện: 101 mục mở.

  @TC-06-154 @P1 @Dương @Biên
  Kịch bản: TC-06-154 Nhận việc tiếp theo
    # Truy vết: FR-06-028 · API-06-124, 045 · UI-06-04 · ERR-06-027, 028 · PERM-06-steward
    # Mục đích: Chứng minh "Nhận việc tiếp theo" nhận nguyên tử mục ưu tiên cao nhất và trả `204` khi hết việc, theo FR-06-028 (API-06-124).
    Biết bảy mục của q-create; DS1, DS2 cùng tổ chức; DS3 khác tổ chức.
    Khi DS1 và DS2 đồng thời `POST /stewardship/items:claim-next`.
    Và DS1 `claim-next` kèm bộ lọc `riskLevel = HIGH`.
    Và nhận hết mục, rồi DS1 `claim-next` lần nữa.
    Và DS1 `GET /stewardship/items?partition=mine`; DS3 `claim-next`.
    Thì bước 1 hai mục khác nhau (`SKIP LOCKED`), mục có `priority` cao nhất, hạn SLA sớm nhất thuộc người nhận trước, cả hai `ASSIGNED` giữ 30 phút (`06.queue.hold-minutes`). Bước 2 chỉ trả mục rủi ro cao. Bước 3 `204`, không lỗi. Bước 4 `partition=mine` chỉ có mục của DS1; DS3 không nhận mục tổ chức khác (ERR-06-028 nếu chỉ định trực tiếp).
    # Hậu điều kiện: Các mục đã nhận ở `ASSIGNED`.

  @TC-06-155 @P1 @Dương
  Kịch bản: TC-06-155 Sửa quyết định trong hạn bằng mở lại
    # Truy vết: FR-06-030 · FR-06-039 · API-06-121, 048 · UI-06-05 · EVT-06-04 · `06.queue.reopen-hours`
    # Mục đích: Chứng minh người đã quyết hoặc DA mở lại quyết định hàng đợi trong `06.queue.reopen-hours` và quyết định lại, theo FR-06-030 luồng thay thế (API-06-121).
    Biết mục M3 vừa `RESOLVED` với `MATCH` rủi ro thấp (hợp nhất tự động); DS1 là người quyết; DS2 người khác.
    Khi DS2 `:reopen` M3.
    Và DS1 `:reopen` M3 với lý do 10 ký tự.
    Và DS1 `:reopen` M3 với lý do đủ 20 ký tự và `If-Match` đúng.
    Và DS1 `decide` `NO_MATCH` cho M3.
    Thì bước 1 `403` ERR-00-403 (không phải người quyết, không phải DA). Bước 2 `422` ERR-06-007. Bước 3 `200`, M3 `ASSIGNED` cho DS1, hợp nhất cũ được hoàn tác theo FR-06-039, quyết định cũ còn trong lịch sử; KT: có (q-reopen). Bước 4 M3 `RESOLVED` `NO_MATCH`, cặp nhãn cập nhật, hai bản ghi vàng tách lại.
    # Hậu điều kiện: M3 `NO_MATCH`, lịch sử có hai quyết định.

  @TC-06-156 @P1 @Âm @Biên
  Kịch bản: TC-06-156 Mở lại quá hạn hoặc đã có thao tác phụ thuộc
    # Truy vết: FR-06-030 · API-06-121 · ERR-06-053 · `06.queue.reopen-hours`
    # Mục đích: Chứng minh chặn mở lại khi quá hạn hoặc đã có thao tác phụ thuộc, theo FR-06-030 (ERR-06-053).
    Biết hai mục `RESOLVED`: M4 quyết cách đây 25 giờ (đồng hồ giả lập), M5 quyết 2 giờ trước nhưng bản ghi vàng đã sửa tay thêm.
    Khi DA1 `:reopen` M4.
    Và DA1 `:reopen` M5.
    Và đặt `06.queue.reopen-hours = 48` rồi `:reopen` M4.
    Thì bước 1 `409` ERR-06-053. Bước 2 `409` ERR-06-053 (có thao tác phụ thuộc), hướng dẫn dùng hoàn tác (FR-06-039). Bước 3 `200` vì còn trong hạn 48 giờ, chưa có thao tác phụ thuộc ở M4.
    # Hậu điều kiện: M5 vẫn `RESOLVED`.
