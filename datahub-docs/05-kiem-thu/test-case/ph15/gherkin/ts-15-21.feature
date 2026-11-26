# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-21
Tính năng: TS-15-21 · Bật, tắt thử production theo dịch vụ

  @TC-15-124 @P1 @Dương
  Kịch bản: TC-15-124 Mặc định tắt
    # Truy vết: FR-15-042 · UC-15-21 · API-15-083 · ERR-15-112 · BR-15-019 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.try.prod-enabled` mặc định (`false`); U-T68-CA.
    Khi `GET /admin/try-production`.
    Và bình (đăng ký ACTIVE) `POST /try/requests` môi trường PRODUCTION.
    Thì mọi dịch vụ `OFF`; bước 2 `403` ERR-15-112 "Dịch vụ này chưa bật thử trên môi trường thật.".

  @TC-15-125 @P1 @Dương
  Kịch bản: TC-15-125 Đề xuất và duyệt bốn mắt, có thời hạn
    # Truy vết: FR-15-042 · UC-15-21 · API-15-084, 085 · UI-15-23 · EVT-15-10 · BR-15-019, 021 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.try.prod-enabled = true`; `thoi-tiet-cong-khai` (PUBLIC); U-T68-SV đề xuất, U-T68-CA duyệt.
    Khi SV `PUT /admin/try-production/thoi-tiet-cong-khai` {lý do, hạn 30 ngày, `allowWrite = false`}.
    Và CA `:approve`.
    Thì `PENDING` rồi `ENABLED` kèm `expiresAt`; EVT-15-10 hai lần; KT: có; sau hạn tự `EXPIRED` (tác vụ hằng giờ).

  @TC-15-126 @P1 @Âm
  Kịch bản: TC-15-126 Tự duyệt, API không đủ điều kiện, thiếu lý do, quá hạn tối đa
    # Truy vết: FR-15-042 · API-15-084, 085 · ERR-15-003, 023, 040 · BR-15-020, 021 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `bao-cao-noi-bo` (RESTRICTED), `tra-cuu-dat-dai` (SENSITIVE); tenant tắt công tắc; hạn 91 ngày.
    Khi SV tự `:approve`.
    Và đề xuất cho hai API RESTRICTED, SENSITIVE.
    Và đề xuất khi `15.try.prod-enabled = false`.
    Và đề xuất không lý do; hạn 91 ngày.
    Thì `403` ERR-15-023; `422` ERR-15-040 ở bước 2, 3; `400` ERR-15-003 ở bước 4.

  @TC-15-127 @P2 @Dương
  Kịch bản: TC-15-127 Tắt bằng một người có quyền
    # Truy vết: FR-15-042 · API-15-086 · EVT-15-10 · ERR-15-112 · BR-15-021 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết dịch vụ ENABLED; Hà (TA).
    Khi `POST /admin/try-production/thoi-tiet-cong-khai:disable`.
    Và bình thử production.
    Thì `OFF`, EVT-15-10, KT: có; bước 2 `403` ERR-15-112 ngay.
