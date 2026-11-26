# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-24
Tính năng: TS-06-24 · Phát sự kiện thay đổi và đăng ký nhận cập nhật

  @TC-06-103 @P1 @Dương @Bảo @mật
  Kịch bản: TC-06-103 Sự kiện bản ghi vàng đủ sáu loại, không lộ giá trị
    # Truy vết: FR-06-050 · BR-06-012 · EVT-06-01, 02, 03, 04, 05, 06 · NFR-06-014, 016 · ERR-06-109
    # Mục đích: Chứng minh mỗi thao tác phát đúng một sự kiện cùng giao dịch outbox và chỉ chứa mã, phiên bản, tên thuộc tính đổi, theo BR-06-012.
    Biết T90; canary `DH-CANARY-evt` trong thuộc tính `SENSITIVE`.
    Khi tạo, cập nhật, hợp nhất, tách, ngừng, khôi phục một bản ghi vàng.
    Và đọc sáu topic `t90.mdm.golden.*.v1`.
    Và dừng Kafka 5 phút khi cập nhật; bật lại.
    Thì bước 2 mỗi thao tác đúng một bản tin `ce_type = vn.datahub.mdm.golden.{…}`, có `dhtenant`, `goldenId`, `version`, tên thuộc tính đổi, nguồn gây đổi; Mồi sạch. Bước 3 outbox giữ, phát đủ theo thứ tự `goldenId` sau khi bật lại; quá số lần thử thì ERR-06-109 báo vận hành.
    # Hậu điều kiện: Không mất, không trùng bản tin.

  @TC-06-104 @P2 @Dương
  Kịch bản: TC-06-104 Đăng ký nhận cập nhật LINKED_ONLY được DO duyệt
    # Truy vết: FR-06-051 · API-06-077, 078, 079, 115, 117 · UI-06-15 · BR-06-026 · PERM-06-export
    # Mục đích: Chứng minh HTTT nhận sự kiện của bản ghi vàng đã liên kết với nguồn của mình, theo FR-06-051.
    Biết HTTT `HT-YTE` có mục đích PH-09; DO1, DA1.
    Khi `POST /update-subscriptions` `SubscriptionScope = LINKED_ONLY`.
    Và DO1 `:approve`.
    Và sửa một bản ghi vàng có xref `HT-YTE` và một bản ghi không có.
    Thì đăng ký `PENDING_APPROVAL` → `ACTIVE`. Chỉ bản ghi có xref `HT-YTE` sinh sự kiện tới bên nhận. `:suspend`, `:revoke` dừng nhận trong ≤ 60 giây. KT: có (subscription).
    # Hậu điều kiện: Một đăng ký ACTIVE.

  @TC-06-105 @P2 @Âm
  Kịch bản: TC-06-105 Đăng ký thiếu mục đích, tự duyệt, đã thu hồi
    # Truy vết: FR-06-051 · API-06-078, 079, 116 · ERR-06-005, 006, 043
    # Mục đích: Chứng minh chặn đăng ký không có mục đích và dùng lại đăng ký đã thu hồi, theo FR-06-051.
    Biết HTTT `HT-MOI` chưa có mục đích; đăng ký `REVOKED`.
    Khi `POST /update-subscriptions` cho `HT-MOI`.
    Và người đề nghị tự `:approve`.
    Và `:resume` đăng ký `REVOKED`.
    Thì bước 1 `422` ERR-06-043. Bước 2 `403` ERR-06-005. Bước 3 `409` ERR-06-006.
    # Hậu điều kiện: Không đăng ký mới.
