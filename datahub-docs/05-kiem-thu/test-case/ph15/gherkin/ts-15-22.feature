# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-22
Tính năng: TS-15-22 · Thử API trên production

  @TC-15-128 @P1 @Dương
  Kịch bản: TC-15-128 Thử GET ở production bằng token trao đổi
    # Truy vết: FR-15-043 · UC-15-22 · API-15-072 · UI-15-06 · EVT-15-11 · BR-15-022, 024 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `thoi-tiet-cong-khai` ENABLED; U-T68-OR (HT-DATDAI có đăng ký ACTIVE); APISIX production giả lập.
    Khi bình mở UI-15-06 (banner "Môi trường thật"), chọn môi trường production, gửi GET.
    Thì `200`; token trao đổi sống 5 phút, `act` là Bình (và mã HTTT), `aud` và scope thu hẹp theo đăng ký, không đệm; EVT-15-11 `env = PRODUCTION`; KT: có (`TRY_PRODUCTION`); không lưu thân phản hồi; `X-DH-Try-Id`, `traceparent` có ở gateway.

  @TC-15-129 @P1 @Âm
  Kịch bản: TC-15-129 Không có đăng ký sử dụng ACTIVE
    # Truy vết: FR-15-043 · UC-15-22 · API-15-072 · ERR-15-113 · BR-15-004, 022 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết đăng ký PENDING, đăng ký đã hết hạn, không đăng ký; U-T68-DEV-AN (nhà thầu).
    Khi bình thử khi đăng ký PENDING; khi hết hạn.
    Và an thử production.
    Thì `403` ERR-15-113 "Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này."; An `403` ERR-15-113 (FR-15-043); không lời gọi tới gateway production.

  @TC-15-130 @P1 @Âm
  Kịch bản: TC-15-130 Dataclass đổi sang nhạy cảm sau khi bật
    # Truy vết: FR-15-043 · API-15-072 · ERR-15-114 · BR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `thoi-tiet-cong-khai` ENABLED; S-PH02 đổi `dataClass = SENSITIVE` (EVT-02-02).
    Khi chờ đồng bộ; Bình thử production.
    Thì `403` ERR-15-114 "Dịch vụ có dữ liệu nhạy cảm không cho thử trên môi trường thật."; trạng thái thử production tự về `OFF`.

  @TC-15-131 @P1 @Âm
  Kịch bản: TC-15-131 Chỉ GET và HEAD
    # Truy vết: FR-15-043 · API-15-072 · ERR-15-116 · BR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `allowWrite = false`; mọi API ENABLED.
    Khi thử `POST`, `PUT`, `PATCH`, `DELETE`; thử `GET`, `HEAD`.
    Thì bốn phương thức ghi `422` ERR-15-116 "Chỉ được thử phương thức GET và HEAD trên production"; `GET`, `HEAD` `200`.

  @TC-15-132 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-132 PH-13 lỗi thì từ chối thử production
    # Truy vết: FR-15-043 · UC-15-22 · API-15-072 · ERR-15-115 · BR-15-023 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt PH-13 (kiểm toán đồng bộ); Bình; APISIX production đếm lời gọi.
    Khi thử production.
    Và khôi phục PH-13; thử lại.
    Thì `503` ERR-15-115 "Chưa ghi được nhật ký nên không thử được lúc này."; gateway production nhận 0 lời gọi, không phát token trao đổi; sau khôi phục `200` và có bản ghi kiểm toán.

  @TC-15-133 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-133 PH-13 lỗi ở sandbox: nhạy cảm thì chặn, còn lại ghi qua outbox
    # Truy vết: FR-15-035 · UC-15-19 · API-15-072 · ERR-15-115 · BR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt PH-13; API `tra-cuu-ho-tich` (INTERNAL), `bao-cao-noi-bo` (RESTRICTED) có hồ sơ MOCK; An.
    Khi thử `tra-cuu-ho-tich`.
    Và thử `bao-cao-noi-bo`.
    Và khôi phục PH-13.
    Thì bước 1 `200`, bản ghi kiểm toán nằm trong outbox; bước 2 `503` ERR-15-115; sau bước 3 outbox đẩy bù đủ bản ghi, không trùng.

  @TC-15-134 @P2 @Âm
  Kịch bản: TC-15-134 Token exchange lỗi, hạn mức production
    # Truy vết: FR-15-043 · API-15-072 · ERR-15-117, 118 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt token exchange Keycloak; `15.try.prod-rate-per-user-min = 1`.
    Khi thử production khi Keycloak lỗi.
    Và thử 2 lượt trong 1 phút khi Keycloak tốt.
    Thì `502` ERR-15-117; lượt 2 `429` ERR-15-118.

  @TC-15-135 @P2 @Biên
  Kịch bản: TC-15-135 Danh mục quá 24 giờ ẩn thử production
    # Truy vết: FR-15-043 · UI-15-06 · ERR-15-112 · BR-15-033 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt PH-02, đồng hồ +25 giờ.
    Khi mở UI-15-06 và gọi API thử production.
    Thì nút thử production bị ẩn; API `403` ERR-15-112, `detail` nêu danh mục quá 24 giờ (FR-15-043, BR-15-033); sandbox vẫn thử được.
