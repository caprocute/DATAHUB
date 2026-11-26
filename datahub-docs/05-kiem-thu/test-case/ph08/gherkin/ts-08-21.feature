# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-21
Tính năng: TS-08-21 · Báo đã sửa, đo lại kiểm chứng và xác nhận phiếu

  @TC-08-101 @P1 @Dương
  Kịch bản: TC-08-101 Báo đã sửa và đo kiểm chứng sạch
    # Truy vết: FR-08-044 · API-08-090, 086 · UI-08-16 · BR-08-014, 034 · NFR-08-014 · EVT-08-09
    Biết phiếu `IN_PROGRESS` 12 lỗi `R-CCCD-NN`; DO1 đã sửa nguồn; `08.verify.wait-mdm-minutes = 0` ở TEST.
    Khi DO1 `POST /issues/{code}:mark-fixed` `{fixNote: ≥ 20 ký tự}`
    Và chờ lần đo `VERIFY`
    Và `GET /issues/{code}`
    Thì bước 1 `202`, `verifyScanId`, phiếu `FIXED`. Lần `VERIFY` chỉ trên 12 khóa, sạch → phiếu `VERIFIED`, 12 lỗi `RESOLVED` (`CLEARED`), EVT: `issue.verified` (EVT-08-09). Tổng thời gian ≤ 5 phút với ≤ 10.000 khóa.

  @TC-08-102 @P1 @Âm
  Kịch bản: TC-08-102 Đo kiểm chứng vẫn còn lỗi
    # Truy vết: FR-08-044 · API-08-090 · BR-08-034
    Biết phiếu `FIXED` nhưng 3 trên 12 lỗi vẫn còn ở nguồn.
    Khi chạy `VERIFY`
    Và `GET /issues/{code}`
    Thì phiếu `REOPENED`, 9 lỗi `RESOLVED`, 3 lỗi `IN_REMEDIATION`; DO báo sửa lại được.

  @TC-08-103 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-103 Chủ quản tự xác nhận, báo sửa thiếu ghi chú, DS xác nhận thủ công
    # Truy vết: FR-08-044 · API-08-090, 091 · BR-08-014 · ERR-08-036, 035, 007
    Biết phiếu `FIXED`; nguồn `src-cu` đã ngừng nên không đo lại được; DO1, DS1.
    Khi DO1 `POST /issues/{code}:mark-fixed` ghi chú 10 ký tự
    Và DO1 `POST /issues/{code}:verify`
    Và DS1 `:verify` lý do 30 ký tự
    Và DS1 `:verify` `{mode: MANUAL}` lý do 60 ký tự
    Thì bước 1 `422` ERR-08-036. Bước 2 `403` ERR-08-035. Bước 3 `422` ERR-08-007 (tối thiểu 50 ký tự). Bước 4 `200`, `VERIFIED`, lỗi `RESOLVED` lý do `MANUAL_CONFIRMED`, KT ghi lý do.

  @TC-08-104 @P2 @Chịu @lỗi
  Kịch bản: TC-08-104 Đo kiểm chứng lỗi kỹ thuật giữ phiếu FIXED
    # Truy vết: FR-08-044 · API-08-090 · UI-08-16 · ERR-08-115
    Biết phiếu vừa báo `FIXED`; `conn-sim` ngắt khi lần `VERIFY` chạy; `clock-sim`.
    Khi lần `VERIFY` `FAILED` do nguồn ngắt
    Và đẩy `clock-sim` 1 giờ, lặp lần nữa (tối đa 3 lần)
    Và sau lần thứ ba vẫn lỗi
    Thì phiếu giữ `FIXED` (không `REOPENED`), hiển thị ERR-08-115, hệ thống thử lại sau 1 giờ; sau 3 lần giao DS xử lý.
