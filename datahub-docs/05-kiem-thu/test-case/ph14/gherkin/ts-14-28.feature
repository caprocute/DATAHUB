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

  @TC-14-131 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-131 Tra cứu giao dịch sai: khoảng quá rộng, tenant khác, thiếu quyền, giao dịch cũ
    # Truy vết: FR-14-049 · API-14-061, 062 · UI-14-12 · UC-14-33 · ERR-14-001, 003 · BR-14-029 · PERM-14-audit-read.
    Biết U-T68-AU, U-T68-VW; giao dịch của T68 và của T01 (`tc-gd-t01`); một giao dịch cũ hơn 12 tháng ở kho lưu trữ.
    Khi `GET /transactions?from=…&to=…` khoảng 93 ngày.
    Và `GET /transactions/tc-gd-t01`.
    Và `GET /transactions/GD-KHONG-CO`.
    Và U-T68-VW gọi `GET /transactions`.
    Và tra giao dịch cũ hơn 12 tháng.
    Thì bước 1 `400` ERR-14-003 "Khoảng thời gian tra tối đa 92 ngày." Bước 2 và 3 `404` ERR-14-001 "Không tìm thấy giao dịch {mã}.", thân giống nhau trừ `traceId`. Bước 4 `403`. Bước 5 trả yêu cầu chạy nền, kết quả lấy từ kho lưu trữ. Mọi thân phản hồi đều có nội dung đã che, không lộ DLCN.

  @TC-14-132 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-132 Xem nội dung đầy đủ bị từ chối: sai vai trò, tenant khác, đã quá lưu, vượt số lần
    # Truy vết: FR-14-050 · API-14-063 · ERR-14-001, 003, 030, 031 · BR-14-021 · PERM-14-audit-reveal · EVT-14-16.
    Biết U-T68-SO, U-T68-AU, U-T68-TA; giao dịch `tc-gd-co-nd` có nội dung mã hóa, `tc-gd-het-han` quá `14.txn.payload-retention-days`; `14.reveal.max-per-day = 20`.
    Khi U-T68-AU và U-T68-TA gọi `:reveal`.
    Và U-T68-SO gọi `:reveal` với lý do 5 ký tự.
    Và U-T68-SO gọi mà chưa xác thực lại nhiều yếu tố.
    Và U-T68-SO gọi `tc-gd-het-han`, rồi giao dịch của T01.
    Và U-T68-SO xem lần thứ 21 trong ngày.
    Thì bước 1 `403`. Bước 2 `400` ERR-14-003 "Nhập lý do xem nội dung đầy đủ (từ 10 ký tự)." Bước 3 `403` ERR-14-030. Bước 4 giao dịch quá lưu `404` ERR-14-031; giao dịch T01 `404` ERR-14-001. Bước 5 vẫn xem được nhưng phát EVT-14-16 và cảnh báo SO trưởng. Mọi lần từ chối đều có bản ghi kiểm toán; không lần nào trả `payload`.

  @TC-14-133 @P3 @Âm
  Kịch bản: TC-14-133 Xuất bằng chứng sai: vượt 100 giao dịch, chưa xác thực lại, OpenBao lỗi
    # Truy vết: FR-14-051 · API-14-064 · ERR-14-001, 003, 030, 035 · BR-14-020, 021 · PERM-14-audit-reveal.
    Biết U-T68-SO, U-T68-AU; 150 giao dịch mẫu; giao dịch `tc-gd-t01` của T01.
    Khi xuất 101 giao dịch.
    Và xuất 5 giao dịch với `includePayload = true` khi chưa xác thực lại.
    Và xuất 5 giao dịch không lý do.
    Và xuất khi OpenBao dừng.
    Và xuất kèm `tc-gd-t01`.
    Và U-T68-AU gọi xuất.
    Thì bước 1 `400` ERR-14-003 "Mỗi lần xuất tối đa 100 giao dịch." Bước 2 `403` ERR-14-030, gói không có nội dung. Bước 3 `400` ERR-14-003. Bước 4 `503` ERR-14-035 "Kho bí mật tạm thời không khả dụng nên chưa ký được gói bằng chứng." Bước 5 `404` ERR-14-001. Bước 6 `403`. Không gói nào được tạo hoặc có liên kết tải.

  @TC-14-156 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-156 Xem nội dung đầy đủ: xác thực lại, lý do, 60 giây, hình mờ, vết kiểm toán
    # Truy vết: FR-14-050 · API-14-063 · UI-14-12 · UC-14-34 · BR-14-021 · PERM-14-audit-reveal · NFR-14-021.
    Biết U-T68-SO (đã xác thực lại TOTP), U-T68-TA; giao dịch `tc-gd-co-nd` còn trong `14.txn.payload-retention-days = 30`, nội dung mã hóa bằng khóa tenant; mồi `DH-CANARY-PII-…` trong nội dung.
    Khi U-T68-SO bấm "Xem nội dung đầy đủ" ở UI-14-12, nhập lý do 20 ký tự và mã phiếu.
    Và quan sát màn hình 60 giây.
    Và tra kiểm toán và thông báo của U-T68-TA.
    Và tra nhật ký ứng dụng và vết tìm mồi.
    Thì `200` với `payload` đã giải mã bằng khóa tenant ở OpenBao, `expiresInSeconds = 60`; màn hình có hình mờ tên người xem và tự che lại sau 60 giây. Kiểm toán ghi ngay người, giao dịch, lý do, mã phiếu, thời điểm, trường đã xem; U-T68-TA nhận thông báo. Mồi chỉ có trong phản hồi này, không có trong nhật ký, vết, CSDL quản trị.
