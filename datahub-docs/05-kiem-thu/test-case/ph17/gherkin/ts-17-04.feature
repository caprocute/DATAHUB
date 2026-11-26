# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-04
Tính năng: TS-17-04 · Công bố điều khoản dùng AI và người dùng xác nhận lần đầu

  @TC-17-012 @P1 @Dương @Âm
  Kịch bản: TC-17-012 Người dùng chưa xác nhận điều khoản không gửi được câu hỏi
    # Truy vết: FR-17-005 · API-17-001, 016, 017, 095 · BR-17-007 · ERR-17-020 · UI-17-04
    # Mục đích: Chứng minh luồng xác nhận lần đầu ở UI-17-04 và chặn ở API khi chưa xác nhận.
    Biết T90 bật; điều khoản phiên bản 1 đã công bố; U-T90-IE chưa xác nhận.
    Khi IE mở bảng bên, quan sát hộp thoại điều khoản.
    Và IE `POST /conversations/{id}/messages` khi chưa xác nhận.
    Và IE chọn "Không đồng ý".
    Và IE mở lại, tích đồng ý, bấm "Đồng ý" (`POST /notices/current:accept`).
    Và IE gửi câu hỏi.
    Thì bước 1 `CMP-Modal` có nội dung, mô hình dùng (nội bộ), thời hạn lưu 90 ngày, ô tích. Bước 2 `403` ERR-17-020, không gọi mô hình. Bước 3 bảng bên đóng, không có lượt. Bước 4 `200`, ghi nhận phiên bản, thời điểm, mã người dùng, KT: có (notice-accept). Bước 5 `200`.

  @TC-17-013 @P2 @Âm @Biên
  Kịch bản: TC-17-013 Điều khoản đã công bố không sửa được, phiên bản mới buộc xác nhận lại
    # Truy vết: FR-17-005 · API-17-018, 019, 016, 017 · BR-17-007 · ERR-17-024 · EVT-17-05
    # Mục đích: Chứng minh tính bất biến của phiên bản đã công bố và yêu cầu xác nhận lại khi có phiên bản mới hoặc hết `17.notice.reaccept-days`.
    Biết T95 (đồng hồ giả); điều khoản v1 đã công bố, IE đã xác nhận v1; U-T95-TA1.
    Khi TA1 `PATCH` nội dung điều khoản v1 (hoặc `POST /notices` trùng số phiên bản 1).
    Và TA1 `POST /notices` soạn và công bố v2.
    Và IE `GET /status` và gửi câu hỏi.
    Và IE xác nhận v2 rồi đẩy đồng hồ 366 ngày (mặc định 365) và `GET /status`.
    Thì bước 1 `409` ERR-17-024. Bước 2 `201`, EVT: `assist.notice.published`. Bước 3 `status` có `noticeRequired = true`, câu hỏi `403` ERR-17-020. Bước 4 xác nhận lại v2 bị yêu cầu sau 365 ngày.

  @TC-17-014 @P2 @Truy_cập
  Kịch bản: TC-17-014 Hộp thoại điều khoản dùng được bằng bàn phím và trình đọc màn hình
    # Truy vết: FR-17-005 · NFR-17-024 · UI-17-04
    # Mục đích: Chứng minh `CMP-Modal` điều khoản đạt WCAG 2.1 AA.
    Biết STAGING; Playwright, axe-core; U-T90-IE chưa xác nhận.
    Khi mở bảng bên, chạy axe trên hộp thoại.
    Và điều hướng bằng Tab, Shift+Tab, Space tích ô, Enter bấm "Đồng ý", Esc.
    Thì 0 lỗi axe mức nghiêm trọng; tiêu điểm vào hộp thoại khi mở, bị nhốt trong hộp thoại, trả về nút "Trợ lý" khi đóng; ô tích có nhãn; Esc tương đương "Không đồng ý".
