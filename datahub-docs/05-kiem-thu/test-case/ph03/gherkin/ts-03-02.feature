# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-02
Tính năng: TS-03-02 · Chống tràn theo địa chỉ nguồn và chặn tạm

  @TC-03-011 @P1 @Dương @Âm @Biên
  Kịch bản: TC-03-011 Vượt tốc độ và số kết nối theo địa chỉ nguồn
    # Truy vết: FR-03-003 · API-03-086 · UI-03-15 · ERR-03-119 · BR-03-005, 023 · NFR-03-013 · LGC-NFR-006.
    Biết địa chỉ nguồn `10.99.0.5` (không trong `gw.ip.trustedCidrs`); `gw.ip.apiReqPerSecond = 200`, `gw.ip.burst = 2`, `gw.ip.maxConnections = 100`.
    Khi từ `10.99.0.5` gửi 250 lượt/giây tới `r-ho-tich` trong 10 giây.
    Và mở 120 kết nối đồng thời.
    Thì bước 1: phần vượt (sau dung sai gấp 2 lần mỗi giây) nhận `429` Lỗi GW 119 kèm `Retry-After`, câu "Quá nhiều yêu cầu từ địa chỉ của bạn trong thời gian ngắn. Thử lại sau {n} giây."; phần trong ngưỡng nhận `200`. Bước 2: kết nối thứ 101 trở đi bị từ chối. Lượt gọi từ địa chỉ khác không bị ảnh hưởng.

  @TC-03-012 @P2 @Dương
  Kịch bản: TC-03-012 Địa chỉ trong danh sách tin cậy không bị giới hạn theo IP
    # Truy vết: FR-03-003 · API-03-087 · UI-03-16 · BR-03-005 · SEC-10.
    Biết U-T68-TA, U-T68-SO1; `10.99.0.9` thêm vào `gw.ip.trustedCidrs` (SO duyệt).
    Khi `PUT /settings` thêm CIDR `10.99.0.9/32`.
    Và chờ hiệu lực ≤ 60 s; gửi 400 lượt/giây từ `10.99.0.9` (trong hạn mức của HTTT).
    Thì không có `429` mã 119; hạn mức theo HTTT vẫn áp dụng (ERR-03-116 nếu vượt 20 lượt/giây của C-HTTT1). KT: có (`SETTINGS_UPDATE`).

  @TC-03-013 @P1 @Dương @Biên
  Kịch bản: TC-03-013 Tự chặn địa chỉ vi phạm liên tục rồi tự gỡ
    # Truy vết: FR-03-004 · API-03-036 · UI-03-15 · ERR-03-110 · EVT-03-09 · UC-03-12 · NFR-03-013 · SEC-10, 64.
    Biết `gw.ip.autoBlock.threshold = 10`, `gw.ip.autoBlock.minutes = 15`; `faketime` điều khiển đồng hồ.
    Khi từ `10.99.0.7` gây 9 lần vi phạm trong 60 giây, rồi gọi bình thường.
    Và gây thêm 1 lần (tổng 10).
    Và gọi `r-ho-tich`; `GET /ip-blocks`.
    Và tiến đồng hồ 16 phút; gọi lại.
    Thì sau bước 1 chưa chặn. Sau bước 2 mọi lượt gọi từ địa chỉ này nhận `403` Lỗi GW 110 (câu "Địa chỉ nguồn của bạn đang bị chặn. Liên hệ quản trị."); `GET /ip-blocks` thấy bản ghi `AUTO`, hết hạn sau 15 phút; có EVT: `security.alert-raised`; nguồn bị chặn ≤ 60 giây từ khi tấn công bắt đầu. Bước 4 gọi được trở lại.

  @TC-03-014 @P2 @Dương @Âm
  Kịch bản: TC-03-014 Chặn và bỏ chặn thủ công, không chặn được địa chỉ tin cậy
    # Truy vết: FR-03-004 · API-03-037, 038, 036 · UI-03-15 · ERR-03-019, 024, 022 · UC-03-12.
    Biết U-T68-SO1; U-T68-TO; địa chỉ nền tảng `10.0.0.10` thuộc danh sách tin cậy.
    Khi `POST /ip-blocks` chặn `10.99.0.20` có lý do và `minutes = 60`; `Idempotency-Key`.
    Và `POST /ip-blocks` chặn `10.0.0.10`.
    Và `DELETE /ip-blocks/{blockId}` hai lần.
    Và U-T68-TO gọi `POST /ip-blocks`.
    Thì bước 1 `201`, địa chỉ bị chặn ≤ 60 s. Bước 2 `422` ERR-03-024 "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn." Bước 3 lần một `204`, lần hai `409` ERR-03-019. Bước 4 403-PQ. KT: có (`IP_BLOCK_CREATE`, `IP_BLOCK_DELETE`).
