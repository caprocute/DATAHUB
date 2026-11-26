# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-06
Tính năng: TS-01-06 · Kiểm tra hợp lệ và nộp hồ sơ

  @TC-01-027 @P1 @Âm
  Kịch bản: TC-01-027 Kiểm tra hợp lệ trả đủ danh sách thiếu sót một lần
    # Truy vết: FR-01-011 · UC-01-06 · API-01-022 · UI-01-01 · ERR-01-008, 010, 015, 047 · BR-01-001, 013, 026, 028.
    Biết U-T68-OR1; hồ sơ `tc-thieu` thiếu: căn cứ một dòng, đầu mối kỹ thuật, cấp độ `L2` với dòng mức Hạn chế; tổ chức còn `HT-DVC` thiếu đầu mối.
    Khi `POST /systems/tc-thieu:validate`.
    Và bấm "Kiểm tra" ở bước 4 UI-01-01.
    Thì `422` ERR-01-008 kèm toàn bộ thiếu sót (mức `ERROR`) cùng mã chi tiết; UI liệt kê và dẫn tới đúng bước sửa; không có lỗi nào bị che bởi lỗi khác.

  @TC-01-028 @P1 @Dương
  Kịch bản: TC-01-028 Nộp hồ sơ đủ điều kiện
    # Truy vết: FR-01-011, 012 · UC-01-06 · API-01-022, 023 · UI-01-01 · BR-01-017, 031 · EVT-01-01, 03 · LGC-APIM-020.
    Biết U-T68-OR1; hồ sơ `tc-du` đủ điều kiện, mức Hạn chế, cấp độ `L3`; `review.slaWorkingDays = 2`.
    Khi chạy `…:validate`; bấm "Gửi duyệt" ở bước 5, đọc hộp xác nhận.
    Và `GET /systems/tc-du`.
    Thì `:validate` `200` không lỗi `ERROR`. `:submit` `200`; `status = SUBMITTED`, `reviewStage = WAITING_ASSIGN`, `revisionNo` tăng; có ba bước `TECHNICAL`, `LEGAL`, `SECURITY` (vì mức Hạn chế) với `dueAt` theo ngày làm việc; nội dung khóa. KT: có (nộp hồ sơ). EVT: `EVT-01-01` và `EVT-01-03`, cùng giao dịch. Việc xuất hiện ở hộp việc người nhận.

  @TC-01-029 @P2 @Biên
  Kịch bản: TC-01-029 Hồ sơ cấp Nội bộ chỉ có hai bước thẩm định
    # Truy vết: FR-01-012 · API-01-023 · UC-01-06.
    Biết U-T68-OR1; hồ sơ `tc-noibo` cấp độ `L1`, chỉ nhu cầu mức Nội bộ.
    Khi nộp hồ sơ `tc-noibo`.
    Thì `steps[]` chỉ có `TECHNICAL`, `LEGAL`; không có `SECURITY`.

  @TC-01-030 @P1 @Âm
  Kịch bản: TC-01-030 Nộp khi sai trạng thái, lệch phiên bản, nộp lặp, trùng hồ sơ
    # Truy vết: FR-01-012 · API-01-023 · ERR-01-005, 007, 009, 051 · BR-01-032.
    Biết U-T68-OR1; `HT-HOTICH-SS`; hồ sơ nháp `tc-hai` cùng HTTT với hồ sơ đang xử lý (tạo bằng nhập hệ cũ).
    Khi `:submit` vào `HT-HOTICH-SS`.
    Và `:submit` hồ sơ đủ điều kiện nhưng `If-Match` cũ.
    Và `:submit` `tc-hai`.
    Và `:submit` thành công hai lần cùng `Idempotency-Key`.
    Thì `409` ERR-01-005; `412` ERR-01-007; `409` ERR-01-009; lần hai của bước 4 trả cùng kết quả, chỉ một vòng thẩm định, chỉ một `EVT-01-01`.

  @TC-01-031 @P2 @Âm @Chịulỗi
  Kịch bản: TC-01-031 Danh mục tổ chức ngừng khi nộp
    # Truy vết: FR-01-012 · API-01-023 · ERR-01-046 · NFR-01-006.
    Biết U-T68-OR1; hồ sơ đủ điều kiện; PH-20 giả lập `fail`.
    Khi bấm "Gửi duyệt".
    Và khôi phục PH-20; nộp lại.
    Thì bước 1: `503` ERR-01-046, hồ sơ giữ `DRAFT`, không có bước thẩm định, không có sự kiện. Bước 2: thành công.

  @TC-01-032 @P2 @Hiệunăng
  Kịch bản: TC-01-032 Độ trễ kiểm tra hợp lệ hồ sơ lớn
    # Truy vết: FR-01-011 · API-01-022 · NFR-01-002.
    Biết hồ sơ 30 mục nhu cầu, 10 tài liệu.
    Khi gọi `:validate` 1.000 lần, 20 luồng.
    Thì p99 ≤ 2 giây.
