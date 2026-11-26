# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-11
Tính năng: TS-15-11 · Tự đăng ký dh-dev và duyệt tài khoản

  @TC-15-066 @P1 @Dương
  Kịch bản: TC-15-066 Đăng ký, xác minh thư, chờ duyệt
    # Truy vết: FR-15-020 · UC-15-11 · API-15-045, 046 · UI-15-08 · EVT-15-06 · BR-15-028, 029 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hộp thư giả lập (Mailpit); `an@abc.example.vn`, Công ty ABC, hợp đồng `HD-2026-07`, đơn vị bảo lãnh Sở TT&TT.
    Khi `POST /developer-registrations`.
    Và lấy mã trong thư, `POST /developer-registrations:verify-email`.
    Và thử đăng nhập.
    Thì `PENDING_EMAIL` rồi `PENDING_APPROVAL`; EVT-15-06 một lần; KT: có; chỉ hỏi họ tên, thư, đơn vị, số hợp đồng, bảo lãnh, điện thoại tùy chọn, có thông báo xử lý dữ liệu cá nhân; bước 3 `422` ERR-15-011.

  @TC-15-067 @P1 @Âm
  Kịch bản: TC-15-067 Thư trùng, mã sai, hết hạn, thiếu trường
    # Truy vết: FR-15-020 · UC-15-11 · API-15-045, 046 · ERR-15-003, 012, 013 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `an@abc.example.vn` đã đăng ký; đồng hồ +25 giờ.
    Khi đăng ký lại cùng thư; thiếu số hợp đồng.
    Và xác minh với mã sai; xác minh sau 25 giờ.
    Thì `409` ERR-15-012; `400` ERR-15-003 lỗi theo trường; `400` ERR-15-013; sau 25 giờ tài khoản `EXPIRED`.

  @TC-15-068 @P2 @Âm
  Kịch bản: TC-15-068 Gửi lại thư và đăng ký quá nhiều
    # Truy vết: FR-15-020 · API-15-045 · ERR-15-037 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết một IP; một tài khoản PENDING_EMAIL.
    Khi gửi lại thư xác minh 4 lần trong 1 giờ.
    Và đăng ký liên tục từ một IP quá ngưỡng.
    Thì lần 4 và lần vượt ngưỡng `429` ERR-15-037 "Bạn gửi quá nhiều. Thử lại sau {n} phút."

  @TC-15-069 @P3 @Biên
  Kịch bản: TC-15-069 Tenant tắt đăng ký tự phục vụ
    # Truy vết: FR-15-020 · UI-15-08 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.dev.signup-enabled = false`.
    Khi mở `/dang-ky`; `POST /developer-registrations`.
    Thì UI ẩn mục đăng ký; API `403` ERR-15-005 (FR-15-020).

  @TC-15-070 @P1 @Dương
  Kịch bản: TC-15-070 Quản trị duyệt tài khoản
    # Truy vết: FR-15-058 · UC-15-30 · API-15-121, 122 · UI-15-24 · EVT-15-07 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản An PENDING_APPROVAL; U-T68-TA.
    Khi `GET /admin/dev-accounts?trang-thai=PENDING_APPROVAL`.
    Và `POST /admin/dev-accounts/{userId}:approve`.
    Và an đăng nhập.
    Thì `ACTIVE`; người dùng được tạo ở realm `dh-dev` Keycloak; thư thông báo; EVT-15-07; KT: có; An vào được cổng, hạng `DEV_USER`; từ chối `:reject` có lý do giúp tài khoản `REJECTED` và thư thông báo.

  @TC-15-071 @P2 @Âm
  Kịch bản: TC-15-071 Duyệt sai trạng thái, thiếu lý do, Keycloak lỗi
    # Truy vết: FR-15-058 · UC-15-30 · API-15-122, 123 · ERR-15-003, 020, 022 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản ACTIVE; tài khoản PENDING_APPROVAL khi ngắt Keycloak.
    Khi `:approve` tài khoản ACTIVE.
    Và `:reject` không có lý do.
    Và `:approve` khi Keycloak ngắt; sau đó khôi phục và thử lại.
    Thì `409` ERR-15-022; `400` ERR-15-003 "Cần nêu lý do từ chối"; `503` ERR-15-020 và tài khoản vẫn `PENDING_APPROVAL`, thử lại thành công.

  @TC-15-072 @P1 @Âm
  Kịch bản: TC-15-072 Chỉ vai trò có `PERM-15-dev-approve` duyệt được
    # Truy vết: FR-15-058 · API-15-121, 122, 124 · ERR-15-005 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN, U-T68-OR, U-T68-SV, U-T68-SO, U-T68-TA.
    Khi mỗi người gọi `GET /admin/dev-accounts` và `:approve`.
    Thì an, Bình, Chi `403` ERR-15-005; Khánh (SO) và Hà (TA) `200` theo D02-08 (xem Q15-46 ở UC); nhắc quá `15.dev.approval-sla-days` gửi TA.
