# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-28
Tính năng: TS-09-28 · Giữ pháp lý và xóa mật mã khi chấm dứt tenant

  @TC-09-096 @P1 @Dương @Âm
  Kịch bản: TC-09-096 Đặt giữ pháp lý, chặn xóa, gỡ giữ
    # Truy vết: FR-09-042 · API-09-157, 158, 154 · ERR-09-059, 058 · EVT-09-20 · BR-09-039
    # Mục đích: Chứng minh giữ pháp lý chặn mọi tác vụ xóa đối tượng liên quan.
    Biết T90; bản ghi thuộc hoạt động HD-01 đã quá hạn; U-T90-SO.
    Khi SO `POST /legal-holds` thiếu số văn bản.
    Và SO đặt giữ kèm `CV-777/2026`, cơ quan, hạn rà soát.
    Và SO chạy `POST /retention-tasks:run` đối tượng đang giữ.
    Và SO `POST /legal-holds/{id}:release`; chạy lại.
    Thì bước 1 `422` ERR-09-059. Bước 2 `201`, EVT: `legal-hold.changed`. Bước 3 `409` ERR-09-058 "Dữ liệu đang bị giữ pháp lý, không xóa được cho đến khi gỡ giữ." Bước 4 `RELEASED`, KT: có, tác vụ xử lý được.

  @TC-09-097 @P1 @Dương
  Kịch bản: TC-09-097 Đề nghị, hai người duyệt, chờ rồi hủy KEK `dh-{tenant}-pii`
    # Truy vết: FR-09-043 · API-09-159, 161, 160 · EVT-09-21 · BR-09-041 · PERM-09-retention
    # Mục đích: Chứng minh xóa mật mã không hoàn tác sau đúng độ trễ và hai người duyệt.
    Biết T95 đồng hồ giả; tenant T95 đã bàn giao dữ liệu theo PH-20; `09.shred.delay-days = 30`; U-T95-SO, U-T95-DA1.
    Khi SO `POST /tenant-shred-requests`; SO tự `:approve`.
    Và DA1 `:approve`; trạng thái `WAITING`.
    Và tiến đồng hồ 30 ngày.
    Và đọc thử một bản ghi mã hóa bằng KEK của T95.
    Thì bước 1 `REQUESTED`, tự duyệt `403` ERR-09-005. Bước 2 `APPROVED`, `WAITING`. Bước 3 `EXECUTED`, EVT: `crypto-shred.completed`, KT: có. Bước 4 không giải mã được; khóa không khôi phục được.

  @TC-09-098 @P1 @Âm
  Kịch bản: TC-09-098 Chưa bàn giao, hủy trước khi thực hiện, tenant khác
    # Truy vết: FR-09-043 · API-09-159, 162 · ERR-09-060, 006 · BR-09-041
    # Mục đích: Chứng minh điều kiện xóa mật mã (BR-09-041).
    Biết T94 chưa bàn giao PH-20; yêu cầu ở trạng thái `WAITING`; U-T91-SO.
    Khi SO `POST /tenant-shred-requests` khi chưa bàn giao.
    Và SO `:cancel` yêu cầu `WAITING`; rồi `:cancel` lần hai.
    Và U-T91-SO `GET /tenant-shred-requests/{id}` của T94.
    Thì bước 1 `422` ERR-09-060 nêu lý do. Bước 2 `200` rồi `409` ERR-09-006. Bước 3 `404` ERR-09-001.
