# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-10
Tính năng: TS-01-10 · Thẩm định căn cứ pháp lý và ATTT theo từng mục

  @TC-01-044 @P1 @Dương
  Kịch bản: TC-01-044 Kết luận từng mục: chấp thuận, thu hẹp, từ chối
    # Truy vết: FR-01-014 · UC-01-10 · API-01-025 · UI-01-06 · BR-01-002, 003 · EVT-01-02.
    Biết `HT-HOTICH-SS` có ba mục `CONSUME`; U-T68-TA2 (bước `LEGAL`).
    Khi TA2 `POST …/reviews/LEGAL` với mục 1 chấp thuận, mục 2 chấp thuận thu hẹp (bỏ một phạm vi), mục 3 từ chối kèm lý do.
    Và `GET …/data-demands`.
    Thì `200`; phạm vi được chấp thuận của mục 1 đủ, mục 2 thu hẹp, mục 3 rỗng; hệ thống không tự đặt kết luận nào (BR-01-002). KT: có. EVT: `EVT-01-02`.

  @TC-01-045 @P1 @Âm
  Kịch bản: TC-01-045 Thẩm định pháp lý thiếu mục, thiếu ý kiến, bí mật nhà nước, người lập
    # Truy vết: FR-01-014 · API-01-025 · BR-01-004, 017 · ERR-01-016, 017, 018, 019.
    Biết `HT-HOTICH-SS`; TA2; TA1 là người lập hồ sơ thay; dòng `BMNN-TEST` chèn bằng công cụ kiểm thử.
    Khi TA2 ghi kết luận bỏ sót một mục; rồi thiếu ý kiến cho mục từ chối.
    Và TA2 chấp thuận mục `BMNN-TEST`.
    Và TA1 (người lập thay) ghi kết luận.
    Thì `422` ERR-01-018; `422` ERR-01-019; `422` ERR-01-016 (không có đường chấp thuận); `403` ERR-01-017.

  @TC-01-046 @P1 @Dương @Âm @Bảomật
  Kịch bản: TC-01-046 Thẩm định ATTT: đúng người, không tự động hóa
    # Truy vết: FR-01-014 · API-01-025 · BR-01-019, 026 · ERR-01-047 · UC-01-10.
    Biết `HT-HOTICH-SS` mức Hạn chế; U-T68-SO (được giao); U-T68-IE.
    Khi SO `POST …/reviews/SECURITY` đạt, ghi cấp độ ATTT và phương thức xác thực yêu cầu.
    Và IE gọi cùng API.
    Thì bước 1: `200`; KT: có. Bước 2: `403-PQ` (IE không có phân công bước này). Không có kết luận nào được đặt khi không có người gọi API.
