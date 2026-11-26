# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-28
Tính năng: TS-02-28 · Giao diện: nhập liệu, trạng thái, nút theo quyền và ngôn ngữ

  @TC-02-153 @P1 @Dương @Âm
  Kịch bản: TC-02-153 Trình hướng dẫn đăng ký API: chặn từng bước, giữ bản nháp, chỉ lỗi theo dòng
    # Truy vết: FR-02-010, 011, 016, 019 · API-02-014, 015, 022 · UI-02-03, 04 · UC-02-05, 06 · ERR-02-003, 006.
    Biết U-T68-SV1; F-SPEC-OK, F-SPEC-L1.
    Khi mở UI-02-03; bấm "Tiếp" ở từng bước khi thiếu trường bắt buộc.
    Và điền bước 1, 2; tải lại trình duyệt giữa chừng.
    Và nạp F-SPEC-L1; bấm vào một lỗi trong danh sách.
    Và sửa bằng trình soạn và xem kết quả kiểm tra không lưu khi gõ.
    Thì bước 1: không qua bước, trường lỗi được đánh dấu bằng chữ và biểu tượng (không chỉ màu), thông báo cùng nội dung với `errors[]` của máy chủ. Bước 2: dữ liệu đã nhập còn nguyên (bản nháp). Bước 3: con trỏ nhảy đúng dòng lỗi trong đặc tả. Bước 4: kết quả cập nhật không quá 1 giây sau khi ngừng gõ, không ghi bản nào vào cơ sở dữ liệu.

  @TC-02-154 @P2 @Âm @Dương
  Kịch bản: TC-02-154 Trạng thái rỗng, đang tải, lỗi và mất kết nối ở các màn danh sách
    # Truy vết: FR-02-001, 046, 047, 054 · API-02-001, 059, 044, 072 · UI-02-01, 06, 08, 10, 12 · UC-02-01, 24, 30 · ERR-02-034.
    Biết tenant `T91` rỗng; T68 có dữ liệu; chặn mạng bằng công cụ Playwright; API trả `503` ERR-02-034 theo cờ.
    Khi mở từng màn ở `T91`.
    Và làm chậm phản hồi 3 giây.
    Và cho API trả `503`, rồi bấm "Thử lại".
    Và ngắt mạng khi đang mở màn.
    Thì bước 1: trạng thái rỗng có lời giải thích và hành động kế tiếp (ví dụ "Đăng ký API đầu tiên"). Bước 2: khung chờ, không nhảy bố cục. Bước 3: thông báo lỗi nêu `traceId`, "Thử lại" gọi lại một lần. Bước 4: báo mất kết nối, giữ dữ liệu đã nhập ở biểu mẫu.

  @TC-02-155 @P1 @Dương @Âm
  Kịch bản: TC-02-155 Nút thao tác theo `allowedActions` và vai trò, kèm lý do bị khóa
    # Truy vết: FR-02-034, 035, 037, 046, 051 · API-02-002, 033, 059 · UI-02-02, 06, 08, 10 · ERR-02-014, 011 · PERM-02-submit.
    Biết đối tượng ở các trạng thái `DRAFT`, `PENDING`, `PUBLISHED`, `SUSPENDED`; U-T68-SV1, U-T68-CA, U-T68-TO, U-T68-OR1, U-T68-VW.
    Khi mỗi vai trò mở UI-02-02, 06, 08, 10 ở từng trạng thái.
    Và di chuột hoặc dùng bàn phím vào nút bị khóa.
    Và gọi thẳng API cho thao tác mà UI đã khóa.
    Thì nút hiện hoặc khóa đúng `allowedActions[]`; nút khóa có lý do (`disabledReasons`) đọc được bằng bàn phím và trình đọc màn hình; VW không có nút ghi nào. Bước 3: máy chủ vẫn từ chối `403` ERR-02-014 hoặc `409` ERR-02-011.

  @TC-02-156 @P2 @Dương
  Kịch bản: TC-02-156 Màn so sánh phiên bản: phân loại thay đổi, lọc, điều hướng bàn phím
    # Truy vết: FR-02-043, 044 · API-02-055, 056 · UI-02-05 · UC-02-18 · BR-02-003.
    Biết A-DATDAI 1.0.0 và 2.0.0 (có 3 thay đổi phá vỡ, 5 không phá vỡ); U-T68-SV1.
    Khi mở UI-02-05, chọn hai phiên bản.
    Và lọc "chỉ phá vỡ"; mở rộng một thay đổi.
    Và duyệt hết danh sách bằng `Tab` và phím mũi tên.
    Và mở tab "Tác động".
    Thì số thay đổi đúng 3 phá vỡ, 5 không phá vỡ, khớp `GET /version-diff`; lọc đúng; có thể duyệt, mở rộng bằng bàn phím; tab "Tác động" liệt kê bên đăng ký ảnh hưởng, khớp API-02-056.

  @TC-02-157 @P1 @Dương @Âm
  Kịch bản: TC-02-157 Màn gửi đăng ký: chọn gói, căn cứ pháp lý theo mức dữ liệu, chặn gửi thiếu
    # Truy vết: FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 012, 026 · ERR-02-029, 025.
    Biết U-T68-OR1; gói `PUBLISHED` mức `INTERNAL` và `RESTRICTED`; gói `DEPRECATED`.
    Khi mở UI-02-09 cho API `RESTRICTED`; để trống mục đích, khối lượng, căn cứ pháp lý; bấm gửi.
    Và mở danh sách gói.
    Và chọn gói `INTERNAL` có tự duyệt; gửi.
    Thì bước 1: nút gửi bị chặn, trường căn cứ pháp lý hiện là bắt buộc kèm gợi ý. Bước 2: gói `DEPRECATED` bị khóa kèm lý do. Bước 3: đăng ký `ACTIVE` ngay, màn báo "đã tự duyệt" và phạm vi được cấp.

  @TC-02-158 @P1 @Dương @Âm
  Kịch bản: TC-02-158 Màn duyệt: thấy rõ thay đổi, bốn mắt, lý do bắt buộc
    # Truy vết: FR-02-035, 047 · API-02-044, 045, 046 · UI-02-10 · UC-02-16, 24 · BR-02-008 · ERR-02-013, 041.
    Biết yêu cầu duyệt phiên bản do U-T68-SV1 gửi, API `SENSITIVE`; U-T68-CA, U-T68-TA, U-T68-SV-CA.
    Khi U-T68-CA mở UI-02-10, xem hồ sơ; bấm "Từ chối" không nhập lý do.
    Và U-T68-SV-CA mở cùng yêu cầu (người gửi) và bấm "Duyệt".
    Và CA duyệt; mở lại bằng TA.
    Thì bước 1: hồ sơ hiện thay đổi trước, sau, kết quả kiểm tra, người gửi và người sửa gần nhất; từ chối cần lý do. Bước 2: nút bị khóa kèm nêu vai trò trùng (ERR-02-013, không nêu dữ liệu cá nhân). Bước 3: API `SENSITIVE` hiện thêm bước xác nhận của TA.

  @TC-02-159 @P2 @Dương
  Kịch bản: TC-02-159 Màn đồng bộ quốc gia và SLA: số trên thẻ khớp API, có bảng thay thế biểu đồ
    # Truy vết: FR-02-054, 056 · API-02-070, 072, 075 · UI-02-11, 12 · UC-02-30, 32 · BR-02-013 · NFR-02-016.
    Biết tám bản ghi đồng bộ ở mọi trạng thái; một API quá hạn 8 ngày; ba kỳ SLA (đạt, không đạt, chưa đủ dữ liệu).
    Khi mở UI-02-12; so các thẻ với `GET /national-sync/summary`.
    Và mở UI-02-11; xem kỳ chưa đủ dữ liệu.
    Và bật chế độ bảng thay cho biểu đồ.
    Thì số khớp API; API quá hạn có chỉ báo; kỳ chưa đủ dữ liệu hiện "chưa đủ dữ liệu" thay vì "đạt" hoặc "không đạt"; mọi biểu đồ có bảng số liệu tương đương.

  @TC-02-160 @P2 @Dương @Âm
  Kịch bản: TC-02-160 Màn nhập hệ cũ, bộ luật, cài đặt: chỉ quản trị, xem trước trước khi xác nhận
    # Truy vết: FR-02-021, 061, 062 · API-02-024, 025, 085, 086, 088, 089 · UI-02-15, 16, 17 · UC-02-37, 38 · ERR-02-014.
    Biết U-T68-TA, U-T68-SV1, U-T68-VW; F-APIM-EXPORT.
    Khi SV1 và VW mở UI-02-15, 16, 17.
    Và TA nạp F-APIM-EXPORT ở UI-02-16 và xem bản xem trước.
    Và TA bấm xác nhận khi chưa đọc báo cáo xem trước (cuộn chưa tới cuối).
    Và TA đổi một tham số `02.*` rồi hoàn tác.
    Thì bước 1: VW chỉ xem được bộ luật và tham số, SV1 không thấy nút ghi, màn nhập không hiển thị với hai vai trò này. Bước 2: số API, gói, đăng ký khớp F-APIM-EXPORT (12, 20, 35). Bước 3: có bước xác nhận nêu rõ "không nhập khóa, đăng ký vào `SUSPENDED`". Bước 4: mọi thay đổi ghi kiểm toán.

  @TC-02-161 @P3 @Dương @Biên
  Kịch bản: TC-02-161 Tiếng Việt có dấu, giờ Việt Nam, định dạng số và ngày, ngôn ngữ `en`
    # Truy vết: FR-02-001, 003, 056 · API-02-003 · UI-02-01, 02, 11 · UC-02-01 · NFR-02-016.
    Biết tên API và mô tả có dấu tiếng Việt, ký tự `đ`, `Đ`; dữ liệu có thời điểm `2026-11-26T17:30:00Z`.
    Khi mở UI-02-01, 02, 11 với múi giờ trình duyệt khác nhau.
    Và tìm `đất đai` và `dat dai`.
    Và chuyển `Accept-Language: en`; gây một lỗi.
    Thì thời điểm hiện 27/11/2026 00:30 (giờ Việt Nam, UTC+7) bất kể múi giờ trình duyệt; số theo quy ước Việt Nam; hai cách tìm cùng ra kết quả; thông báo lỗi `en` vẫn đủ `code` và `traceId`.
