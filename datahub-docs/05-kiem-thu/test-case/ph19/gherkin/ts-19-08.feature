# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-08
Tính năng: TS-19-08 · Quản lý dịch vụ thanh toán

  @TC-19-176 @P1 @Dương
  Kịch bản: TC-19-176 Thêm dịch vụ ở trạng thái Nháp
    # Truy vết: FR-19-014 · BR-19-008 · API-19-021, 022 · UI-19-10 · LGC-PAY-022
    Biết U-ADM1.
    Khi trên UI-19-09 bấm "Thêm dịch vụ", nhập mã `S-YT`, nhóm G-TP, NCC PV-PG, loại khoản thu, cơ quan thu, khoảng 20.000–2.000.000 ₫, lưu.
    Thì `POST /services` trả `201`, `status = DRAFT`, `catalogInvalid = false`; ô số tiền hiển thị "2.000.000" và dòng đọc bằng chữ. KT: có (`SERVICE_CREATE`).

  @TC-19-177 @P1 @Âm
  Kịch bản: TC-19-177 Dịch vụ sai khoảng tiền, sai mã danh mục
    # Truy vết: FR-19-014, 016 · BR-19-001 · API-19-021 · ERR-19-001, 039
    Biết U-ADM1.
    Khi `POST /services` với `minAmount = 0`.
    Và `minAmount = 50000`, `maxAmount = 10000`.
    Và `maxAmount = 1000000000000` (vượt trần).
    Và `feeTypeCode` không tồn tại ở PH-07.
    Thì bước 1–3 trả `400` ERR-19-001 chỉ đúng trường. Bước 4 trả `422` ERR-19-039.

  @TC-19-178 @P1 @Dương
  Kịch bản: TC-19-178 Kích hoạt, tạm dừng, mở lại, ngừng hẳn dịch vụ
    # Truy vết: FR-19-015 · BR-19-009, 027 · API-19-025, 026, 027 · UI-19-09
    Biết U-ADM1; `S-YT` từ TC-19-176 đã có `beneficiaryRef`; C-DVC được gán `S-YT`.
    Khi `POST /services/{S-YT}/activations`.
    Và C-DVC tạo giao dịch `S-YT`.
    Và `POST …/suspensions` có lý do; C-DVC tạo giao dịch.
    Và `POST …/activations`; rồi `POST …/retirements` khi không còn giao dịch dở.
    Thì bước 1: `ACTIVE`. Bước 2: `201`. Bước 3: `SUSPENDED`; tạo giao dịch trả `422` ERR-19-008. Bước 4: `ACTIVE` rồi `RETIRED`. EVT: `service.activated`, `service.suspended`, `service.retired`.

  @TC-19-179 @P1 @Âm
  Kịch bản: TC-19-179 Kích hoạt khi NCC chưa hoạt động, thiếu tham chiếu thụ hưởng, mã danh mục hết hiệu lực
    # Truy vết: FR-19-015, 016 · BR-19-009 · API-19-025 · ERR-19-021, 039 · UI-19-09, 10
    Biết dịch vụ A gắn PV-NEW (`DRAFT`); dịch vụ B thiếu `beneficiaryRef`; dịch vụ C có `collectingAgencyCode` vừa hết hiệu lực ở PH-07.
    Khi kích hoạt A, B, C.
    Và PH-07 phát sự kiện `catalog.item.expired` cho mã của S-XD; C-DVC tạo giao dịch S-XD.
    Và mở UI-19-10 của S-XD.
    Thì bước 1: A, B trả `409` ERR-19-021 với lý do cụ thể; C trả `422` ERR-19-039. Bước 2: S-XD có `catalogInvalid = true`; tạo giao dịch trả `422` ERR-19-008. Bước 3: dải đỏ "Mã … đã hết hiệu lực… Chọn mã thay thế".

  @TC-19-180 @P2 @Âm
  Kịch bản: TC-19-180 Ngừng hẳn, xóa dịch vụ đã có giao dịch
    # Truy vết: FR-19-015 · BR-19-027 · API-19-024, 027 · ERR-19-036, 037
    Biết S-XD có TX-PEND.
    Khi `POST /services/{S-XD}/retirements`.
    Và `DELETE /services/{S-XD}`.
    Thì bước 1 trả `409` ERR-19-036. Bước 2 trả `409` ERR-19-037.
