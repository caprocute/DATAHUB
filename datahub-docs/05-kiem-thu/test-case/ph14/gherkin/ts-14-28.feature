# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-28
Tính năng: TS-14-28 · Giao dịch, đối soát, xem nội dung đầy đủ, xuất bằng chứng

  @TC-14-071 @P1 @Dương @Âm
  Kịch bản: TC-14-071 Tra cứu giao dịch và dòng thời gian
    # Truy vết: FR-14-049 · API-14-061, 062 · UI-14-12 · UC-14-33 · BR-14-020 · LGC-NGSP-001.
    Biết U-T68-AU; giao dịch `SUCCEEDED`, `FAILED`, `TIMEOUT`, `UNKNOWN_RESULT`, `COMPLETED_CACHE`.
    Khi Ô tra nhanh theo `transactionCode`.
    Và lọc theo HTTT, dịch vụ, trạng thái, khoảng thời gian.
    Và mở chi tiết.
    Thì kết quả đúng; chi tiết có dòng thời gian từng chặng, nội dung đã che; khoảng thời gian > 31 ngày `400` ERR-14-003; mã không có `404` ERR-14-001.

  @TC-14-072 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-14-072 Xem nội dung đầy đủ: lý do, xác thực lại, hết hạn lưu
    # Truy vết: FR-14-050 · API-14-063 · ERR-14-003, 030, 031 · BR-14-021 · PERM-14-audit-reveal · NFR-14-021.
    Biết U-T68-SO, U-T68-AU; `14.txn.payload-retention-days = 30`; `14.reveal.max-per-day = 20`.
    Khi SO xem có lý do, đã xác thực nhiều yếu tố.
    Và SO xem khi chưa xác thực lại; xem thiếu lý do.
    Và SO xem giao dịch quá 30 ngày giả lập; giao dịch của T01.
    Và U-T68-AU xem.
    Và SO xem lần thứ 21 trong ngày.
    Thì bước 1 `200`, nội dung giải mã, ghi kiểm toán có lý do; bước 2 `403` ERR-14-030 và `400` ERR-14-003; bước 3 `404` ERR-14-031 và ERR-14-001; bước 4 `403`; bước 5 vẫn xem được nhưng phát cảnh báo.

  @TC-14-073 @P3 @Dương @Âm
  Kịch bản: TC-14-073 Xuất bằng chứng giao dịch
    # Truy vết: FR-14-051 · API-14-064 · UC-14-33 · ERR-14-003, 031 · BR-14-020.
    Biết U-T68-SO; Đợt 2.
    Khi `POST /transactions:export-evidence` cho 10 giao dịch.
    Và xuất giao dịch quá hạn lưu nội dung; xuất không chọn giao dịch.
    Thì tệp có siêu dữ liệu, chữ ký, giá trị băm, không có giá trị mồi; bước 2 `404` ERR-14-031 cho nội dung, `400` ERR-14-003.
