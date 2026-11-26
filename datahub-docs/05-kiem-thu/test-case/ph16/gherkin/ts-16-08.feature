# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-08
Tính năng: TS-16-08 · Nhập số liệu tay kèm bằng chứng và xác nhận

  @TC-16-029 @P1 @Dương
  Kịch bản: TC-16-029 Nhập tay kèm bằng chứng và gửi xác nhận
    # Truy vết: FR-16-014 · API-16-032, 035, 033, 039, 031 · UI-16-07 · BR-16-006
    Biết T90; U-T90-TO1; chỉ tiêu `ket-noi-diem-diem-con-lai` (MANUAL, đơn vị `điểm`); kỳ `M-2026-10` chưa chốt.
    Khi `POST /manual-values` `{indicatorCode: ket-noi-diem-diem-con-lai, periodCode: M-2026-10, value: 142, method: "Khảo sát 200 HTTT bằng biểu mẫu nội bộ quý 4", evidence: [{docNumber: "TC/KS-2026-10", docDate: 2026-10-28}]}`
    Và `POST /manual-values/{manualId}/evidence` tệp PDF 200 KB, `docNumber`, `docDate`
    Và `POST /manual-values/{manualId}:submit`
    Và `GET /manual-values?state=SUBMITTED&periodCode=M-2026-10`
    Thì bước 1 `201`, `state = DRAFT`, `enteredBy = TO1`. Bước 2 `201`, `evidence[].sha256` 64 ký tự hex. Bước 3 `200`, `state = SUBMITTED`, `submittedAt`. Bước 4 có bản này. Giá trị chưa vào tính toán tới khi `ACCEPTED`; lần tổng hợp gắn cờ `MANUAL_PENDING` (ERR-16-112).

  @TC-16-030 @P1 @Âm
  Kịch bản: TC-16-030 Thiếu bằng chứng, ngoài miền, tệp sai loại, kỳ đã chốt
    # Truy vết: FR-16-014 · API-16-032, 035, 039, 034 · ERR-16-018, ERR-16-019, ERR-16-053, ERR-16-022 · BR-16-006
    Biết T90; U-T90-TO1; `16.manual.evidence-required = true`; kỳ `M-2026-09` `CLOSED`; chỉ tiêu `diem-hai-long-sus` miền 0…100.
    Khi tạo số tay không `evidence` rồi `:submit`
    Và tạo `diem-hai-long-sus` `value = 120`
    Và `POST …/evidence` tải tệp `bang-chung.exe`
    Và `POST /manual-values` cho kỳ `M-2026-09`
    Và `PATCH /manual-values/{manualId}` bản `SUBMITTED` đổi `value`
    Thì bước 1 `422` ERR-16-018. Bước 2 `422` ERR-16-019. Bước 3 `400` ERR-16-053. Bước 4 `409` ERR-16-022. Bước 5 `409` ERR-16-006 (không sửa bản đã gửi). Không bản nhập nào được tạo hoặc đổi.

  @TC-16-031 @P2 @Dương @Âm
  Kịch bản: TC-16-031 Nhập hàng loạt bằng tệp XLSX có xem trước, tệp sai
    # Truy vết: FR-16-014 · API-16-036, 037, 038 · UI-16-07 · ERR-16-020, ERR-16-021
    Biết T90; U-T90-TO1; tệp theo mẫu tải về từ `GET /manual-values/template` gồm 3 dòng hợp lệ, 1 dòng `value` sai kiểu.
    Khi `GET /manual-values/template`
    Và `POST /manual-values:import` tải tệp
    Và `POST /manual-values/imports/{importId}:commit`
    Và `POST /manual-values:import` với tệp thiếu cột `periodCode`, rồi tệp 2.001 dòng
    Và commit tệp có một dòng trùng chỉ tiêu và kỳ đã `ACCEPTED`
    Thì bước 2 `200`, `rows[]` có `row`, `status` (`VALID` hoặc `INVALID`), `errors`; `validCount = 3`, `invalidCount = 1`, `expiresAt`; chưa ghi gì. Bước 3 `200`, chỉ 3 dòng `IMPORTED`, tạo 3 bản nhập `DRAFT`; dòng sai không tạo. Bước 4 `422` ERR-16-020 "Tệp không đúng mẫu nhập số liệu hoặc vượt 2.000 dòng. Tải mẫu mới nhất." Bước 5 `409` ERR-16-021, không dòng nào được ghi.

  @TC-16-032 @P1 @Dương
  Kịch bản: TC-16-032 Xác nhận số liệu tay và dùng vào tính toán
    # Truy vết: FR-16-015 · API-16-040, 078, 053 · UI-16-07, UI-16-12 · EVT-16-04 · BR-16-005
    Biết số tay `SUBMITTED` của `ket-noi-diem-diem-con-lai` do U-T90-TO1 nhập (man-create-submit); U-T90-SO có `PERM-16-manual`, nằm trong `confirmerRoles`.
    Khi U-T90-SO `GET /review-queue?itemType=MANUAL_VALUE`
    Và U-T90-SO `POST /manual-values/{manualId}:accept`
    Và `POST /periods/M-2026-10/runs` rồi `GET /runs/{runId}/values?indicatorCode=ket-noi-diem-diem-con-lai`
    Thì bước 2 `200`, `state = ACCEPTED`, `decidedBy = SO`. EVT: `manual-value.decided` (EVT-16-04) tới PH-18. Bước 3 giá trị chỉ tiêu `value = 142`, `completeness = COMPLETE`, dòng truy nguồn có `manualId` (BR-16-001).

  @TC-16-033 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-033 Người nhập tự xác nhận, sai vai trò, từ chối thiếu lý do, trùng số
    # Truy vết: FR-16-015 · API-16-040, 041 · ERR-16-005, ERR-16-059, ERR-16-007, ERR-16-021 · BR-16-005
    Biết số tay `SUBMITTED` do TO1 nhập; U-T90-TA1 không thuộc `confirmerRoles` của chỉ tiêu này; chỉ tiêu đã có số `ACCEPTED` cùng kỳ ở ca khác.
    Khi U-T90-TO1 `:accept` bản của chính mình
    Và U-T90-TA1 `:accept`
    Và U-T90-SO `POST …:reject` với `reason` 10 ký tự
    Và U-T90-SO `:accept` bản thứ hai cùng chỉ tiêu và kỳ khi đã có `ACCEPTED`
    Thì bước 1 `403` ERR-16-005. Bước 2 `403` ERR-16-059 (không thuộc vai trò được xác nhận). Bước 3 `422` ERR-16-007. Bước 4 `409` ERR-16-021. Trạng thái bản nhập không đổi.

  @TC-16-034 @P1 @Biên
  Kịch bản: TC-16-034 Chỉ tiêu MIXED: số tự động chỉ có hiệu lực khi có xác nhận tay
    # Truy vết: FR-16-014, FR-16-015 · API-16-040, 053 · BR-16-035 · EVT-16-04
    Biết T90; chỉ tiêu `bi-mat-ngoai-kho` (MIXED); PH-12 quét ra 0 bí mật ngoài kho (AUTO) kỳ `M-2026-10`; chưa có số tay.
    Khi chạy tổng hợp `M-2026-10`, đọc `bi-mat-ngoai-kho`
    Và U-T90-SO nhập số tay `0` có bằng chứng, gửi, U-T90-DS xác nhận (người khác người nhập)
    Và chạy lại, đọc giá trị
    Và kỳ khác: số AUTO `NO_DATA`, số tay đã `ACCEPTED`, chạy tổng hợp
    Thì bước 1 chưa có số: `NO_DATA`, cờ `MANUAL_PENDING`. Bước 3 `value = 0`, `COMPLETE`. Bước 4 số tay thay số tự động vì tự động `NO_DATA` (BR-16-035). Số tự động không tự có hiệu lực khi chưa có xác nhận.
