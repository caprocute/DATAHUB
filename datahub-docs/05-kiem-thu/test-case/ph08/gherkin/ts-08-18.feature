# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-18
Tính năng: TS-08-18 · Ngoại lệ chấp nhận có hạn và có duyệt

  @TC-08-092 @P1 @Dương
  Kịch bản: TC-08-092 Đề nghị, duyệt và hết hạn ngoại lệ
    # Truy vết: FR-08-040 · API-08-079, 080, 081 · UI-08-14 · BR-08-021 · EVT-08-10 · PERM-08-approve
    Biết 3 lỗi `OPEN` của `mdm-citizen`; DS1, DA1; `clock-sim`.
    Khi DS1 `POST /waivers` `{scope: FINDINGS, findingIds: [3 lỗi], reason: ≥ 50 ký tự, validUntil: +90 ngày}`
    Và DA1 `POST /waivers/{id}:approve`
    Và chạy lần đo kế tiếp
    Và đẩy `clock-sim` qua `validUntil`, chạy job hằng ngày
    Thì bước 1 `PENDING_APPROVAL`. Bước 2 `ACTIVE`, lỗi `WAIVED`, EVT: `waiver.approved` (EVT-08-10). Bước 3 lỗi `WAIVED` không vào mẫu số, đếm riêng. Bước 4 `EXPIRED`, lỗi về `OPEN` và tính lại ở lần đo sau. KT: có (waiver.approve).

  @TC-08-093 @P1 @Âm
  Kịch bản: TC-08-093 Hạn quá trần, phạm vi rỗng, lý do ngắn, tự duyệt
    # Truy vết: FR-08-040 · API-08-079, 081 · BR-08-007, 021 · ERR-08-033, 007
    Biết `08.waiver.max-days = 180`; DS1, DA1.
    Khi DS1 `POST /waivers` `validUntil` +200 ngày
    Và `POST /waivers` `findingIds = []`
    Và `POST /waivers` lý do 30 ký tự
    Và DS1 `POST /waivers/{id}:approve` ngoại lệ do mình đề nghị
    Thì bước 1 và 2 `422` ERR-08-033. Bước 3 `422` ERR-08-007 (tối thiểu 50 ký tự). Bước 4 `403` ERR-08-005 (câu "người đề nghị ngoại lệ").

  @TC-08-094 @P2 @Dương
  Kịch bản: TC-08-094 Từ chối và thu hồi ngoại lệ
    # Truy vết: FR-08-040 · API-08-082, 083 · UI-08-14
    Biết một ngoại lệ `PENDING_APPROVAL`, một ngoại lệ `ACTIVE`.
    Khi DA1 `POST /waivers/{id}:reject` kèm lý do
    Và DA1 `POST /waivers/{id}:revoke` kèm lý do
    Thì bước 1 `REJECTED`, lỗi vẫn `OPEN`. Bước 2 `REVOKED`, lỗi về `OPEN`, tính lại ở lần đo sau.
