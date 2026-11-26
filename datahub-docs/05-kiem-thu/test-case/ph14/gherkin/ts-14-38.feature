# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-38
Tính năng: TS-14-38 · Kiểm toán và bảo vệ bằng chứng

  @TC-14-151 @P1 @Bảo @mật @Dương
  Kịch bản: TC-14-151 Mọi thay đổi cấu hình ghi kiểm toán đủ người, trước, sau, không có bí mật
    # Truy vết: BR-14-005, 022 · FR-14-003, 013, 028, 032, 054 · NFR-14-015, 020 · SEC-62 · EVT-14-01, 03, 04, 08.
    Biết U-T68-TA, U-T68-IE, U-T68-IA, U-T68-SO; mồi `DH-CANARY-AUD` ở ô thông tin xác thực; PH-13 nhận kiểm toán.
    Khi thực hiện một thay đổi của mỗi nhóm: nền tảng (bật, tạm ngừng), luật định tuyến (tạo, duyệt), hạn mức (khai báo, phân bổ), chứng thư (nạp, kích hoạt, thu hồi), tham số bảo mật, điểm cuối chiều vào, xoay thông tin xác thực.
    Và tra nhật ký kiểm toán ở PH-13 theo từng thao tác.
    Và tìm `DH-CANARY-AUD` trong mọi bản ghi.
    Thì mỗi thao tác có bản ghi kiểm toán gồm người thực hiện, người đề nghị và người duyệt với việc cần bốn mắt, thời điểm, đối tượng, giá trị trước và sau ở dạng đã che, mã truy vết; sự kiện EVT-14 tương ứng được phát. Không bản ghi nào chứa giá trị bí mật.

  @TC-14-152 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-152 Lượt gọi bị từ chối vẫn có giao dịch và nhật ký khai thác
    # Truy vết: BR-14-008, 020 · FR-14-011, 052 · NFR-14-020 · ERR-14-104, 105, 106, 107, 117, 132 · API-14-075, 061, 065.
    Biết S-HT-MC, S-HT-KHAC; V-BHXH, V-HT; mỗi lỗi gây ra riêng: chưa được cấp, mục đích sai, thiếu mã hồ sơ, hết hạn mức, không có luật, nền tảng tạm ngừng, OPA dừng.
    Khi thực hiện bảy lượt gọi bị từ chối, mỗi lượt một nguyên nhân.
    Và tra `GET /transactions` và `GET /usage` theo từng `transactionCode`.
    Và đếm số lượt gọi gửi tới và số dòng nhật ký khai thác.
    Thì cả bảy lượt có giao dịch với trạng thái và mã ERR tương ứng, `traceId` nối được tới PH-04, PH-13; có dòng nhật ký khai thác ghi HTTT (từ `azp`), dịch vụ, mục đích, kết quả `DENIED` hoặc lỗi, mã hồ sơ nếu có. Số lượt gọi bằng số dòng nhật ký (100 %). Lượt bị từ chối không chạm nền tảng quốc gia và không trừ hạn mức.

  @TC-14-153 @P2 @Dương @Bảo @mật
  Kịch bản: TC-14-153 Sự kiện EVT-14 đúng chủ đề, không bí mật, tương thích BACKWARD
    # Truy vết: NFR-14-022, 024, 015 · BR-14-021 · EVT-14-01, 05, 06, 07, 09, 10, 11, 17 · SEC-82.
    Biết kafka có chủ đề `{tenant}.national.*.v1`; Apicurio chế độ BACKWARD; mồi `DH-CANARY-EVT`; thao tác tạo từng loại sự kiện.
    Khi gây ra từng sự kiện: nền tảng đổi trạng thái, chứng thư chạm mốc, sự cố chữ ký, hạn mức chạm ngưỡng, vô hiệu đệm, ngắt mạch đổi, giao dịch kết thúc, nhận thông báo.
    Và đọc từng chủ đề, kiểm tên chủ đề, lược đồ, trường.
    Và đăng ký lược đồ mới có thêm trường bắt buộc.
    Và tìm mồi và dữ liệu cá nhân trong thân sự kiện.
    Thì mỗi sự kiện có mặt đúng một lần ở chủ đề tiền tố tenant (`T68.national.…`), tenant khác không đọc được. Lược đồ đổi không BACKWARD bị Apicurio từ chối. Thân EVT-14-11 chỉ có siêu dữ liệu giao dịch; không có bí mật, nội dung bản tin hay DLCN.

  @TC-14-154 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-154 Nhật ký kiểm toán không sửa, không xóa; sự kiện an ninh tới SIEM
    # Truy vết: NFR-14-021 · BR-14-003, 019, 020 · FR-14-031, 050 · SEC-62, SEC-63 · EVT-14-06, 16.
    Biết U-T68-SO, U-PA; kho kiểm toán và WORM của PH-13; sự cố chữ ký mở sẵn; một lượt xem nội dung đầy đủ đã diễn ra.
    Khi cố sửa và xóa một bản ghi kiểm toán PH-14 bằng API quản trị, bằng SO, bằng PA.
    Và kiểm tra EVT-14-06 và EVT-14-16 ở SIEM.
    Và kiểm lưu giữ: siêu dữ liệu 5 năm, sự cố chữ ký 5 năm, mẫu sức khỏe 90 ngày.
    Và cố xóa chứng thư còn dùng để xác minh giao dịch.
    Thì bước 1 mọi cách sửa, xóa đều bị từ chối, nỗ lực bị ghi lại. Bước 2 hai sự kiện tới SIEM trong 1 phút với tham chiếu giao dịch, không có nội dung bản tin. Bước 3 không bản ghi nào bị xóa trước hạn lưu. Bước 4 `409` ERR-14-022.
