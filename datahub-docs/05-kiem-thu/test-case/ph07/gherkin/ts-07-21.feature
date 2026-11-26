# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-21
Tính năng: TS-07-21 · Kiểm toán và lịch sử

  @TC-07-256 @P1 @Dương
  Kịch bản: TC-07-256 Mọi thao tác ghi đều có bản ghi kiểm toán
    # Truy vết: FR-07-050 · FR-00-041
    Biết bộ tiêu thụ thử đọc luồng kiểm toán gửi PH-13.
    Khi thực hiện chuỗi: tạo danh mục, thêm thuộc tính, thêm bản ghi, trình, rút lại, trình, duyệt, phát hành, ngừng hiệu lực.
    Thì mỗi thao tác có đúng một bản ghi với mã hành động `RDM_*` tương ứng, đủ trường chủ thể, thời điểm, địa chỉ nguồn, đối tượng, trước, sau, kết quả, `traceId` trùng `traceparent` của yêu cầu.

  @TC-07-257 @P1 @Dương
  Kịch bản: TC-07-257 Xem lịch sử gộp và lọc
    # Truy vết: FR-07-050 · API-07-072 · UI-07-02
    Biết danh mục sau TC-07-256.
    Khi `GET /catalogs/{c}/history`.
    Và lọc `action=RDM_VERSION_PUBLISH`.
    Và mở tab Lịch sử của UI-07-02.
    Thì bước 1 trả dòng thời gian giảm dần, mỗi mục có `summary` tiếng Việt. Bước 2 chỉ có một mục. Bước 3 hiển thị cùng dữ liệu.

  @TC-07-258 @P2 @Âm
  Kịch bản: TC-07-258 Khoảng thời gian không hợp lệ và PH-13 không sẵn sàng
    # Truy vết: FR-07-050 · ERR-07-009, 047
    Biết —.
    Khi gọi với `from = 2022-01-01`, `to = 2026-11-21` (vượt 3 năm).
    Và gọi với `from` sau `to`.
    Và dừng giả lập PH-13, gọi lại hợp lệ.
    Thì bước 1, 2 `422` `ERR-07-009`. Bước 3 `503` `ERR-07-047`, thân có phần dữ liệu từ PH-07 và `partial = true`.

  @TC-07-259 @P2 @Bảo @mật
  Kịch bản: TC-07-259 Che nội dung danh mục hạn chế và ghi nhận xuất lịch sử
    # Truy vết: FR-07-050 · FR-07-052
    Biết CAT-RES có lịch sử sửa bản ghi.
    Khi U-T68-VW xem lịch sử CAT-RES.
    Và U-T68-AU xem và xuất CSV.
    Thì bước 1: `changes[]` giữ mã, che nhãn và thuộc tính. Bước 2: không che; có bản ghi kiểm toán `RDM_HISTORY_EXPORT`.
