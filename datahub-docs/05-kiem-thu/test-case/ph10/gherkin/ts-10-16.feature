# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-16
Tính năng: TS-10-16 · Vận hành subscription: tạm dừng, sửa, thu hồi, thống kê

  @TC-10-072 @P1 @Dương
  Kịch bản: TC-10-072 Tạm dừng dừng giao trong 10 giây, tiếp tục từ vị trí cũ
    # Truy vết: FR-10-041 · API-10-050, 098 · UI-10-12 · EVT-10-09 · NFR-10-011 · UC-10-16
    Biết U-T68-TO; SUB-PUSH, SUB-PULL, SUB-KAFKA; phát nền 20 sự kiện/giây.
    Khi TO tạm dừng SUB-PUSH ở UI-10-12 với lý do "HTTT thuế bảo trì".
    Và tạm dừng SUB-PULL; HTTT kéo. Tạm dừng SUB-KAFKA; consumer ngoài đọc.
    Và sau 5 phút tiếp tục cả ba.
    Thì bước 1 `PAUSED`; SIM-WH không nhận lượt mới sau ≤ 10 giây. Bước 2 API kéo trả `409` ERR-10-110; consumer ngoài mất quyền đọc nhóm. Bước 3 giao tiếp từ offset đã commit, đủ 6.000 sự kiện, không trùng ngoài lượt đang bay lúc dừng. EVT: `subscription.state-changed`.

  @TC-10-073 @P2 @Âm
  Kịch bản: TC-10-073 Tạm dừng INTERNAL, thiếu lý do, sai trạng thái, sai quyền
    # Truy vết: FR-10-041 · API-10-050, 098 · ERR-10-006, 009, 052, 054
    Biết U-T68-TO, U-T68-IE1; SUB-FLOW, SUB-PUSH.
    Khi `:pause` SUB-FLOW.
    Và `:pause` SUB-PUSH không lý do; `:resume` khi đang `ACTIVE`.
    Và IE1 `:pause` SUB-PUSH.
    Thì bước 1 `422` ERR-10-052. Bước 2 `400` ERR-10-009; `409` ERR-10-006. Bước 3 403-PQ (IE không có `PERM-10-operate`).

  @TC-10-074 @P1 @Dương @Âm
  Kịch bản: TC-10-074 Sửa tham số không cần duyệt và cần duyệt lại
    # Truy vết: FR-10-046 · API-10-049 · ERR-10-012, 026, 030 · BR-10-025
    Biết U-T68-IE1, U-T68-IA1; SUB-PUSH `workerCount = 3`.
    Khi `PATCH` `workerCount = 6`, `timeoutMs = 5000`.
    Và `PATCH` `endpointUrl = https://hooks.sim.test/moi` (đã xác minh).
    Và `PATCH` `workerCount = 7`; `timeoutMs = 40000`; `endpointUrl = http://plain.sim.test`.
    Thì bước 1 `200`, áp dụng ≤ 60 giây, tái cân bằng hợp tác không mất bản tin. Bước 2 tạo yêu cầu `SUBSCRIPTION` với khác biệt; giao tiếp tục về URI cũ tới khi IA1 duyệt. Bước 3 `422` ERR-10-030, `422` ERR-10-012, `422` ERR-10-026.

  @TC-10-075 @P1 @Dương @Âm
  Kịch bản: TC-10-075 Thu hồi subscription; DLQ còn xem được nhưng không phát lại
    # Truy vết: FR-10-047 · API-10-099, 064 · ERR-10-006, 009, 044 · EVT-10-09 · BR-10-020
    Biết U-T68-IE1, U-T68-OR; subscription thử có 3 mục DLQ `NEW` và khóa ký `ACTIVE`; SB-THUE (ngoài tổ chức OR).
    Khi OR `:revoke` subscription của SB-THUE.
    Và IE1 `:revoke` không lý do, rồi có lý do.
    Và đề nghị phát lại 3 mục DLQ của subscription đã thu hồi.
    Thì bước 1 403-TC. Bước 2 `400` ERR-10-009; rồi `200`, `REVOKED`, khóa ký xóa khỏi OpenBao, nhóm tiêu thụ còn tới hết `10.subscription.group-delete-delay-hours`. Bước 3 `409` ERR-10-006; mục DLQ vẫn xem và loại bỏ được.

  @TC-10-076 @P2 @Dương @Âm
  Kịch bản: TC-10-076 Thống kê giao nhận và lượt lỗi gần đây
    # Truy vết: FR-10-056 · API-10-052, 053, 085 · UI-10-12 · ERR-10-049 · LGC-HUB-013
    Biết U-T68-VW; SUB-PUSH sau TC-10-068; SIM-WH trả thân lỗi có chuỗi `Bearer abc.def`.
    Khi `GET /subscriptions/ht-thue-dn-cap-phep/stats?from=…&to=…` 1 giờ.
    Và `GET …/failures`.
    Và `GET …/stats` khoảng 8 ngày ở độ phân giải phút.
    Thì bước 1 số thành công, lỗi tạm thời, thử lại, vào DLQ, p50, p95 theo phút khớp số sự kiện đã phát. Bước 2 mỗi dòng có `offset`, `eventId`, `httpStatus`, `errorCode`, `attempt`, `responseSnippet` ≤ 512 byte đã che (`Bearer *`); không có thân sự kiện. Bước 3 `400` ERR-10-049.
