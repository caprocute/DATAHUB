# language: vi
# Sinh tự động từ D02-02/D02-03-PH00 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-00
Tính năng: PH-00 · Yêu cầu chức năng dùng chung (FR-00)

  # ---- EP-00-A · Đăng nhập, phiên và ngữ cảnh

  @US-00-001 @FR-00-001 @M
  Kịch bản: US-00-001 dương · Đăng nhập một lần qua Keycloak
    Biết tenant đã được khởi tạo, có realm `dh-{mã tenant}` và client của `dh-console`, `dh-portal` (D03-10 §5.2); tài khoản người dùng tồn tại và đang hoạt động
    Khi người dùng mở bất kỳ URL nào của ứng dụng khi chưa có phiên, hoặc khi phiên đã hết hạn
    Thì cookie phiên `__Host-dh-sid` (`Secure`, `HttpOnly`, `SameSite=Strict`); chuyển hướng `302` về URL gốc; token chỉ nằm ở BFF
    Và phiên BFF tồn tại, gắn với một người dùng và một tenant; không có token trong `localStorage`, `sessionStorage` hay bộ nhớ JavaScript
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-001 @FR-00-001 @M @âm
  Kịch bản: US-00-001 âm 1 · Sai tài khoản hoặc mật khẩu
    Biết tenant đã được khởi tạo, có realm `dh-{mã tenant}` và client của `dh-console`, `dh-portal` (D03-10 §5.2); tài khoản người dùng tồn tại và đang hoạt động
    Khi sai tài khoản hoặc mật khẩu
    Thì Keycloak hiển thị thông báo và đếm lần sai theo NFR-00-025
    Và người dùng thấy thông báo "Tên đăng nhập hoặc mật khẩu không đúng."

  @US-00-001 @FR-00-001 @M @âm
  Kịch bản: US-00-001 âm 2 · Tài khoản bị khóa tạm
    Biết tenant đã được khởi tạo, có realm `dh-{mã tenant}` và client của `dh-console`, `dh-portal` (D03-10 §5.2); tài khoản người dùng tồn tại và đang hoạt động
    Khi tài khoản bị khóa tạm
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Tài khoản tạm khóa do đăng nhập sai nhiều lần. Thử lại sau {n} phút."

  @US-00-002 @FR-00-002 @M
  Kịch bản: US-00-002 dương · Bắt buộc xác thực hai yếu tố cho vai trò quản trị, duyệt
    Biết người dùng đã qua bước mật khẩu của FR-00-001; vai trò của người dùng thuộc nhóm `mfa-required`
    Khi Keycloak đánh giá luồng xác thực có điều kiện sau bước mật khẩu
    Thì token có claim `acr` thể hiện mức xác thực và `auth_time`
    Và 100% tài khoản trong nhóm `mfa-required` có yếu tố thứ hai đã đăng ký (báo cáo hằng ngày theo SEC-23)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-002 @FR-00-002 @M @âm
  Kịch bản: US-00-002 âm 1 · Mã TOTP sai hoặc hết hạn
    Biết người dùng đã qua bước mật khẩu của FR-00-001; vai trò của người dùng thuộc nhóm `mfa-required`
    Khi mã TOTP sai hoặc hết hạn
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Mã xác thực không đúng hoặc đã hết hạn. Nhập mã mới trên ứng dụng xác thực."

  @US-00-002 @FR-00-002 @M @âm
  Kịch bản: US-00-002 âm 2 · Người dùng bỏ qua bước đăng ký
    Biết người dùng đã qua bước mật khẩu của FR-00-001; vai trò của người dùng thuộc nhóm `mfa-required`
    Khi người dùng bỏ qua bước đăng ký
    Thì không vào được ứng dụng, trang đăng ký hiển thị lại với dòng thông báo
    Và người dùng thấy thông báo "Vai trò của bạn bắt buộc xác thực hai yếu tố."

  @US-00-003 @FR-00-003 @M
  Kịch bản: US-00-003 dương · Tự khóa phiên khi không thao tác
    Biết người dùng đang có phiên BFF
    Khi đồng hồ nhàn rỗi của phiên đạt ngưỡng cảnh báo hoặc ngưỡng khóa
    Thì phiên bị hủy; phản hồi `401` cho lời gọi tiếp theo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-003 @FR-00-003 @M @âm
  Kịch bản: US-00-003 âm 1 · Gọi API sau khi phiên đã khóa
    Biết người dùng đang có phiên BFF
    Khi gọi API sau khi phiên đã khóa
    Thì hệ thống trả `401`; giao diện hiện thông báo và tự chuyển sau 5 giây
    Và người dùng thấy thông báo "Phiên làm việc đã hết hạn. Hệ thống sẽ đưa bạn tới trang đăng nhập và quay lại đúng trang này."

  @US-00-003 @FR-00-003 @M @âm
  Kịch bản: US-00-003 âm 2 · Quản trị nhập giá trị ngoài khoảng 5–15 phút
    Biết người dùng đang có phiên BFF
    Khi quản trị nhập giá trị ngoài khoảng 5–15 phút
    Thì lỗi tại trường thông báo (`400`)
    Và người dùng thấy thông báo "Thời gian khóa phải từ 5 đến 15 phút."

  @US-00-004 @FR-00-004 @M
  Kịch bản: US-00-004 dương · Chọn và đổi tenant làm việc
    Biết người dùng đã đăng nhập (FR-00-001)
    Khi người dùng bấm `CMP-TenantSwitcher` ở thanh trên, hoặc mở một URL thuộc tenant khác tenant đang làm việc
    Thì phiên BFF gắn tenant mới; claim `tenant` của token đổi theo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-004 @FR-00-004 @M @âm
  Kịch bản: US-00-004 âm 1 · Không có quyền ở tenant đích
    Biết người dùng đã đăng nhập (FR-00-001)
    Khi không có quyền ở tenant đích
    Thì hệ thống trả `403`; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."

  @US-00-004 @FR-00-004 @M @âm
  Kịch bản: US-00-004 âm 2 · Tenant đích đang tạm ngừng
    Biết người dùng đã đăng nhập (FR-00-001)
    Khi tenant đích đang tạm ngừng
    Thì hệ thống từ chối với ERR-12-121, ERR-20-001
    Và người dùng thấy thông báo "Tenant {mã} đang tạm ngừng hoạt động."

  @US-00-005 @FR-00-005 @S
  Kịch bản: US-00-005 dương · Xem và thu hồi phiên đăng nhập của mình
    Biết người dùng đã đăng nhập
    Khi người dùng chọn "Phiên đăng nhập" trong menu tài khoản
    Thì hệ thống trả `204`; danh sách phiên cập nhật
    Và phiên bị thu hồi không dùng được nữa
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-005 @FR-00-005 @S @âm
  Kịch bản: US-00-005 âm 1 · Phiên đã hết hạn trước khi thu hồi
    Biết người dùng đã đăng nhập
    Khi phiên đã hết hạn trước khi thu hồi
    Thì danh sách tự làm mới, không báo lỗi

  # ---- EP-00-B · Đa tenant

  @US-00-010 @FR-00-010 @M
  Kịch bản: US-00-010 dương · Gắn bản ghi với tenant từ ngữ cảnh xác thực
    Biết lời gọi mang token hợp lệ có claim `tenant` do realm tương ứng phát hành
    Khi mọi lệnh tạo hoặc sửa bản ghi nghiệp vụ
    Thì bản ghi được tạo có `tenant_id` bằng tenant ngữ cảnh
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-010 @FR-00-010 @M @âm
  Kịch bản: US-00-010 âm 1 · `tenant_id` trong thân khác tenant ngữ cảnh
    Biết lời gọi mang token hợp lệ có claim `tenant` do realm tương ứng phát hành
    Khi `tenant_id` trong thân khác tenant ngữ cảnh
    Thì hệ thống từ chối với ERR-00-003
    Và người dùng thấy thông báo "Dữ liệu gửi lên không thuộc tenant đang làm việc."

  @US-00-010 @FR-00-010 @M @âm
  Kịch bản: US-00-010 âm 2 · Token thiếu claim `tenant` hoặc realm không khớp
    Biết lời gọi mang token hợp lệ có claim `tenant` do realm tương ứng phát hành
    Khi token thiếu claim `tenant` hoặc realm không khớp
    Thì APISIX trả `401`, ghi log an ninh

  @US-00-011 @FR-00-011 @M
  Kịch bản: US-00-011 dương · Không rò rỉ dữ liệu giữa các tenant
    Biết FR-00-010 được áp dụng
    Khi mọi lời gọi đọc, liệt kê, tìm kiếm, xuất, sửa, xóa
    Thì dữ liệu chỉ của tenant ngữ cảnh
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-011 @FR-00-011 @M @âm
  Kịch bản: US-00-011 âm 1 · Mở đối tượng của tenant khác bằng mã hoặc định danh
    Biết FR-00-010 được áp dụng
    Khi mở đối tượng của tenant khác bằng mã hoặc định danh
    Thì hệ thống trả `404` như đối tượng không tồn tại, không trả `403` để không lộ sự tồn tại

  @US-00-012 @FR-00-012 @M
  Kịch bản: US-00-012 dương · Truy cập liên tenant có lý do và kiểm toán
    Biết người dùng có vai trò nền tảng ở tenant `PLATFORM`, đã xác thực WebAuthn
    Khi người dùng chọn một tenant trong nhóm "Truy cập liên tenant" của `CMP-TenantSwitcher`
    Thì phiên liên tenant có `expiresAt`; bản ghi kiểm toán có `actor_home_tenant`
    Và phiên liên tenant tự kết thúc khi hết hạn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-012 @FR-00-012 @M @âm
  Kịch bản: US-00-012 âm 1 · Không phải vai trò nền tảng
    Biết người dùng có vai trò nền tảng ở tenant `PLATFORM`, đã xác thực WebAuthn
    Khi không phải vai trò nền tảng
    Thì hệ thống trả `403`; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."

  @US-00-012 @FR-00-012 @M @âm
  Kịch bản: US-00-012 âm 2 · Lý do dưới 20 ký tự
    Biết người dùng có vai trò nền tảng ở tenant `PLATFORM`, đã xác thực WebAuthn
    Khi lý do dưới 20 ký tự
    Thì lỗi tại trường thông báo (`400`)
    Và người dùng thấy thông báo "Mô tả lý do tối thiểu 20 ký tự."

  # ---- EP-00-C · Danh sách, tìm kiếm, lọc

  @US-00-020 @FR-00-020 @M
  Kịch bản: US-00-020 dương · Tìm kiếm từ khóa không phân biệt hoa thường và dấu
    Biết người dùng đang ở một màn danh sách (PTN-01)
    Khi người dùng gõ vào ô tìm kiếm của `CMP-FilterBar`
    Thì hệ thống trả `200`, trang kết quả, `totalElements`
    Và URL chứa `q` để chia sẻ được

  @US-00-020 @FR-00-020 @M @âm
  Kịch bản: US-00-020 âm 1 · Không có kết quả
    Biết người dùng đang ở một màn danh sách (PTN-01)
    Khi không có kết quả
    Thì trạng thái rỗng thông báo.thông báoXóa bộ lọc"
    Và người dùng thấy thông báo "Không tìm thấy kết quả phù hợp với “{q}"

  @US-00-021 @FR-00-021 @M
  Kịch bản: US-00-021 dương · Phân trang phía máy chủ
    Biết như FR-00-020
    Khi mở danh sách, chuyển trang hoặc đổi cỡ trang
    Thì hệ thống trả `200`, `content[]`, `page`, `size`, `totalElements`, `totalPages`

  @US-00-021 @FR-00-021 @M @âm
  Kịch bản: US-00-021 âm 1 · Tham số không hợp lệ (cỡ trang 37, trang âm)
    Biết như FR-00-020
    Khi tham số không hợp lệ (cỡ trang 37, trang âm)
    Thì bỏ qua, sửa URL, `CMP-Toast` thông báo
    Và người dùng thấy thông báo "Một số điều kiện lọc không còn hợp lệ nên đã được bỏ qua."

  @US-00-022 @FR-00-022 @M
  Kịch bản: US-00-022 dương · Sắp xếp và giữ trạng thái danh sách trên URL
    Biết như FR-00-020
    Khi người dùng bấm tiêu đề cột, hoặc mở một URL đã chia sẻ
    Thì hệ thống trả `200`, danh sách đã sắp xếp
    Và URL phản ánh đủ trạng thái lọc, sắp xếp, trang

  @US-00-022 @FR-00-022 @M @âm
  Kịch bản: US-00-022 âm 1 · Trường sắp xếp không hợp lệ trên URL
    Biết như FR-00-020
    Khi trường sắp xếp không hợp lệ trên URL
    Thì bỏ qua, sửa URL, thông báo như FR-00-021

  @US-00-023 @FR-00-023 @M
  Kịch bản: US-00-023 dương · Bộ lọc nâng cao nhiều giá trị và khoảng thời gian
    Biết như FR-00-020
    Khi người dùng mở "Bộ lọc nâng cao" trên `CMP-FilterBar`
    Thì hệ thống trả `200`, danh sách đã lọc
    Và điều kiện lọc nằm trên URL

  @US-00-023 @FR-00-023 @M @âm
  Kịch bản: US-00-023 âm 1 · `tu` sau `den`
    Biết như FR-00-020
    Khi `tu` sau `den`
    Thì lỗi tại trường thông báo
    Và người dùng thấy thông báo "Ngày bắt đầu phải trước hoặc bằng ngày kết thúc."

  @US-00-023 @FR-00-023 @M @âm
  Kịch bản: US-00-023 âm 2 · Giá trị lọc không còn tồn tại
    Biết như FR-00-020
    Khi giá trị lọc không còn tồn tại
    Thì bỏ qua và thông báo như FR-00-021

  @US-00-024 @FR-00-024 @S
  Kịch bản: US-00-024 dương · Lưu bộ lọc thường dùng
    Biết đang áp dụng ít nhất một điều kiện lọc
    Khi người dùng bấm "Lưu bộ lọc"
    Thì hệ thống trả `201`, mã bộ lọc
    Và bộ lọc gắn với người dùng và tenant

  @US-00-024 @FR-00-024 @S @âm
  Kịch bản: US-00-024 âm 1 · Trùng tên
    Biết đang áp dụng ít nhất một điều kiện lọc
    Khi trùng tên
    Thì lỗi tại trường thông báo trên màn này." (`409`)
    Và người dùng thấy thông báo "Bạn đã có bộ lọc tên “{tên}"

  # ---- EP-00-D · Nhập và xuất dữ liệu

  @US-00-030 @FR-00-030 @M
  Kịch bản: US-00-030 dương · Xuất Excel và CSV theo bộ lọc hiện tại
    Biết màn danh sách có nghiệp vụ xuất; người dùng có quyền xuất
    Khi người dùng bấm "Xuất" và chọn định dạng
    Thì hệ thống trả `200`, tệp `.xlsx` hoặc `.csv`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-030 @FR-00-030 @M @âm
  Kịch bản: US-00-030 âm 1 · Không có quyền xuất
    Biết màn danh sách có nghiệp vụ xuất; người dùng có quyền xuất
    Khi không có quyền xuất
    Thì nút thông báo bị ẩn; gọi API trực tiếp nhận `403` thông báo
    Và người dùng thấy thông báo "Xuất"

  @US-00-031 @FR-00-031 @M
  Kịch bản: US-00-031 dương · Xuất lớn chạy nền, có hạn tải
    Biết số dòng theo bộ lọc lớn hơn 10.000
    Khi bước 2 của FR-00-030 phát hiện vượt ngưỡng
    Thì hệ thống trả `202` kèm mã tác vụ; liên kết tải có chữ ký, chỉ người yêu cầu dùng được
    Và tệp bị xóa khỏi kho sau 24 giờ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-031 @FR-00-031 @M @âm
  Kịch bản: US-00-031 âm 1 · Tải sau 24 giờ
    Biết số dòng theo bộ lọc lớn hơn 10.000
    Khi tải sau 24 giờ
    Thì hệ thống trả `410`; người dùng thấy thông báo lỗi (mã lỗi chưa có, xem đề nghị đồng bộ)
    Và người dùng thấy thông báo "Tệp đã hết hạn tải. Vui lòng xuất lại."

  @US-00-031 @FR-00-031 @M @âm
  Kịch bản: US-00-031 âm 2 · Tác vụ lỗi
    Biết số dòng theo bộ lọc lớn hơn 10.000
    Khi tác vụ lỗi
    Thì hệ thống từ chối với ERR-00-500
    Và người dùng thấy thông báo "Xuất dữ liệu không thành công. Mã truy vết {traceId}."

  @US-00-032 @FR-00-032 @M
  Kịch bản: US-00-032 dương · Nhập tệp có xem trước, ghi tất cả hoặc không
    Biết chức năng nhập được bật cho đối tượng; người dùng có quyền ghi
    Khi người dùng mở màn `/nhap` của đối tượng
    Thì hệ thống trả `202` cho phân tích và ghi; kết quả gồm số đã thêm, đã cập nhật, đã bỏ qua, thời gian, mã tác vụ; báo cáo lỗi tải về là tệp gốc thêm cột "Lỗi"
    Và dữ liệu hoặc được ghi đủ các dòng đã chọn, hoặc không thay đổi
    Và sự kiện được phát: Theo phân hệ sở hữu đối tượng (ví dụ sự kiện thay đổi danh mục của PH-07)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-032 @FR-00-032 @M @âm
  Kịch bản: US-00-032 âm 1 · Sai định dạng hoặc quá 50 MB
    Biết chức năng nhập được bật cho đối tượng; người dùng có quyền ghi
    Khi sai định dạng hoặc quá 50 MB
    Thì lỗi tại vùng thả thông báo, không chuyển bước (`415` hoặc `413`)
    Và người dùng thấy thông báo "Tệp phải là .xlsx hoặc .csv và không quá 50 MB."

  @US-00-032 @FR-00-032 @M @âm
  Kịch bản: US-00-032 âm 2 · Thiếu cột bắt buộc
    Biết chức năng nhập được bật cho đối tượng; người dùng có quyền ghi
    Khi thiếu cột bắt buộc
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Tệp thiếu cột bắt buộc: {danh sách cột}."

  @US-00-033 @FR-00-033 @M
  Kịch bản: US-00-033 dương · Cung cấp tệp mẫu nhập
    Biết như FR-00-032
    Khi người dùng bấm "Tải tệp mẫu (.xlsx)" ở bước 1 của PTN-09
    Thì hệ thống trả `200`, tệp `.xlsx`

  @US-00-033 @FR-00-033 @M @âm
  Kịch bản: US-00-033 âm 1 · Không sinh được tệp
    Biết như FR-00-032
    Khi không sinh được tệp
    Thì hệ thống từ chối với ERR-00-500
    Và người dùng thấy thông báo "Hệ thống đang gặp sự cố. Vui lòng thử lại sau ít phút; nếu vẫn lỗi, gửi mã truy vết cho bộ phận hỗ trợ."

  @US-00-034 @FR-00-034 @M
  Kịch bản: US-00-034 dương · Che trường Nhạy cảm trong dữ liệu xuất
    Biết dữ liệu xuất có trường được phân loại Nhạy cảm (D02-07)
    Khi bước 3 của FR-00-030 hoặc FR-00-031
    Thì tệp có trường Nhạy cảm đã che hoặc đầy đủ theo quyền
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-034 @FR-00-034 @M @âm
  Kịch bản: US-00-034 âm 1 · Chọn xuất đầy đủ mà không nêu lý do
    Biết dữ liệu xuất có trường được phân loại Nhạy cảm (D02-07)
    Khi chọn xuất đầy đủ mà không nêu lý do
    Thì lỗi tại trường thông báo (`400`)
    Và người dùng thấy thông báo "Vui lòng nêu lý do xem dữ liệu đầy đủ."

  # ---- EP-00-E · Nhật ký kiểm toán

  @US-00-040 @FR-00-040 @M
  Kịch bản: US-00-040 dương · Phạm vi thao tác phải ghi kiểm toán
    Biết DU dùng thư viện `dh-audit`
    Khi một trong các thao tác: tạo, sửa, xóa, đổi trạng thái, duyệt, đăng nhập, đăng xuất, xem dữ liệu Nhạy cảm, xuất dữ liệu
    Thì mọi thao tác thuộc danh sách đều có bản ghi kiểm toán tra cứu được
    Và bản ghi tồn tại trong chuỗi của tenant

  @US-00-040 @FR-00-040 @M @âm
  Kịch bản: US-00-040 âm 1 · PH-13 tạm không nhận
    Biết DU dùng thư viện `dh-audit`
    Khi PH-13 tạm không nhận
    Thì bản ghi nằm ở hộp thư đi của DU và được gửi lại; người vận hành thấy cảnh báo trên bảng điều khiển PH-13, người dùng không bị chặn thao tác

  @US-00-041 @FR-00-041 @M
  Kịch bản: US-00-041 dương · Nội dung bắt buộc của bản ghi kiểm toán
    Biết FR-00-040
    Khi mỗi lần sinh bản ghi
    Thì bản ghi theo cấu trúc ở D03-07 §7.1

  @US-00-041 @FR-00-041 @M @âm
  Kịch bản: US-00-041 âm 1 · Thiếu `reason` với thao tác bắt buộc lý do (FR-00-050)
    Biết FR-00-040
    Khi thiếu `reason` với thao tác bắt buộc lý do (FR-00-050)
    Thì thao tác bị từ chối trước khi thực hiện, `400`

  @US-00-042 @FR-00-042 @M
  Kịch bản: US-00-042 dương · Nhật ký không sửa, không xóa, có chuỗi băm
    Biết FR-00-041
    Khi ghi bản ghi mới; lịch kiểm tra toàn vẹn hằng ngày; kiểm toán viên yêu cầu kiểm tra
    Thì báo cáo toàn vẹn (đạt hoặc vị trí đứt chuỗi)
    Và lưu trực tuyến 12 tháng, WORM 5 năm (NFR-00-027)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-042 @FR-00-042 @M @âm
  Kịch bản: US-00-042 âm 1 · Lệnh `UPDATE`, `DELETE` vào bảng kiểm toán
    Biết FR-00-041
    Khi lệnh `UPDATE`, `DELETE` vào bảng kiểm toán
    Thì trigger từ chối với mọi vai trò trừ quy trình lưu trữ phân vùng đã hết hạn trực tuyến

  @US-00-042 @FR-00-042 @M @âm
  Kịch bản: US-00-042 âm 2 · Phát hiện đứt chuỗi
    Biết FR-00-041
    Khi phát hiện đứt chuỗi
    Thì cảnh báo mức nghiêm trọng trên PH-13 cho người trực, nêu `seq` đầu tiên không khớp

  @US-00-043 @FR-00-043 @M
  Kịch bản: US-00-043 dương · Tab "Lịch sử" trên màn chi tiết đối tượng
    Biết đối tượng có màn chi tiết (PTN-02)
    Khi người dùng mở tab "Lịch sử" hoặc liên kết sâu `/{ma}/lich-su`
    Thì hệ thống trả `200`, danh sách bản ghi đã che

  @US-00-043 @FR-00-043 @M @âm
  Kịch bản: US-00-043 âm 1 · PH-13 không phản hồi
    Biết đối tượng có màn chi tiết (PTN-02)
    Khi PH-13 không phản hồi
    Thì vùng tab hiện thông báo kèm nút thông báo; các tab khác vẫn dùng được
    Và người dùng thấy thông báo "Chưa tải được lịch sử. Bấm Thử lại."

  # ---- EP-00-F · Thao tác và trạng thái

  @US-00-050 @FR-00-050 @M
  Kịch bản: US-00-050 dương · Xác nhận và lý do cho thao tác phá hủy, ảnh hưởng vận hành
    Biết người dùng có quyền với thao tác
    Khi người dùng bấm hành động xóa, tạm dừng, thu hồi, hoàn tiền hoặc hành động khác được FRS đánh dấu
    Thì kết quả của thao tác gốc
    Và bản ghi kiểm toán có `reason`
    Và sự kiện được phát: Theo thao tác gốc của phân hệ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-050 @FR-00-050 @M @âm
  Kịch bản: US-00-050 âm 1 · Gọi API ảnh hưởng vận hành không kèm `reason`
    Biết người dùng có quyền với thao tác
    Khi gọi API ảnh hưởng vận hành không kèm `reason`
    Thì hệ thống trả `400`; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Vui lòng nêu lý do cho thao tác này."

  @US-00-051 @FR-00-051 @M
  Kịch bản: US-00-051 dương · Xóa mềm và khôi phục
    Biết đối tượng là đối tượng nghiệp vụ (không phải bản ghi kiểm toán, không phải dữ liệu tạm)
    Khi người dùng xóa đối tượng (sau FR-00-050); quản trị chọn "Khôi phục"
    Thì hệ thống trả `204` khi xóa; `200` và đối tượng khi khôi phục
    Và đối tượng đã xóa không xuất hiện trong danh sách, API tra cứu thông thường
    Và sự kiện được phát: Theo phân hệ (sự kiện xóa của đối tượng)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-051 @FR-00-051 @M @âm
  Kịch bản: US-00-051 âm 1 · Còn phụ thuộc
    Biết đối tượng là đối tượng nghiệp vụ (không phải bản ghi kiểm toán, không phải dữ liệu tạm)
    Khi còn phụ thuộc
    Thì hệ thống trả `409`; người dùng thấy thông báo lỗi (mã lỗi riêng theo phân hệ)
    Và người dùng thấy thông báo "Không xóa được vì {đối tượng} đang được {n} {loại phụ thuộc} sử dụng."

  @US-00-051 @FR-00-051 @M @âm
  Kịch bản: US-00-051 âm 2 · Khôi phục trùng mã với đối tượng mới tạo sau đó
    Biết đối tượng là đối tượng nghiệp vụ (không phải bản ghi kiểm toán, không phải dữ liệu tạm)
    Khi khôi phục trùng mã với đối tượng mới tạo sau đó
    Thì hệ thống trả `409`; người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Đã có đối tượng khác dùng mã {mã}. Đổi mã trước khi khôi phục."

  @US-00-052 @FR-00-052 @M
  Kịch bản: US-00-052 dương · Phát hiện xung đột khi hai người sửa cùng đối tượng
    Biết đối tượng có cột `version`; giao diện đã nhận `ETag` khi mở đối tượng
    Khi người dùng bấm "Lưu"
    Thì hệ thống trả `200` và `ETag` mới khi lưu được
    Và `version` tăng một mỗi lần lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-052 @FR-00-052 @M @âm
  Kịch bản: US-00-052 âm 1 · Phiên bản không khớp
    Biết đối tượng có cột `version`; giao diện đã nhận `ETag` khi mở đối tượng
    Khi phiên bản không khớp
    Thì hệ thống từ chối với ERR-00-412
    Và người dùng thấy thông báo "Đối tượng vừa được {người} cập nhật lúc {giờ}. Xem khác biệt rồi chọn ghi đè hoặc tải lại."

  @US-00-052 @FR-00-052 @M @âm
  Kịch bản: US-00-052 âm 2 · Thiếu `If-Match` ở API sửa
    Biết đối tượng có cột `version`; giao diện đã nhận `ETag` khi mở đối tượng
    Khi thiếu `If-Match` ở API sửa
    Thì hệ thống trả `428` (mã lỗi chưa có, xem đề nghị đồng bộ)

  @US-00-053 @FR-00-053 @M
  Kịch bản: US-00-053 dương · Nhãn trạng thái thống nhất và hành động theo trạng thái
    Biết đối tượng có máy trạng thái khai báo ở FRS phân hệ
    Khi hiển thị đối tượng ở danh sách hoặc chi tiết
    Thì trạng thái và `allowedActions[]`

  @US-00-053 @FR-00-053 @M @âm
  Kịch bản: US-00-053 âm 1 · Gọi API chuyển trạng thái không hợp lệ
    Biết đối tượng có máy trạng thái khai báo ở FRS phân hệ
    Khi gọi API chuyển trạng thái không hợp lệ
    Thì hệ thống trả `409`; người dùng thấy thông báo lỗi (mã lỗi riêng theo phân hệ)
    Và người dùng thấy thông báo "Không thể {hành động} khi đối tượng đang ở trạng thái {trạng thái}."

  @US-00-054 @FR-00-054 @M
  Kịch bản: US-00-054 dương · Thao tác chạy lâu chạy nền, có tiến độ
    Biết thao tác được FRS phân hệ đánh dấu chạy nền (nhập tệp, xuất lớn, đồng bộ, kiểm tra hàng loạt)
    Khi người dùng khởi động thao tác
    Thì hệ thống trả `202` kèm mã tác vụ; trạng thái tác vụ (`RUNNING`, `SUCCEEDED`, `FAILED`, `CANCELLED`), tiến độ
    Và kết quả tác vụ lưu tra cứu được trong trung tâm thông báo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-054 @FR-00-054 @M @âm
  Kịch bản: US-00-054 âm 1 · Gửi lại cùng `Idempotency-Key`
    Biết thao tác được FRS phân hệ đánh dấu chạy nền (nhập tệp, xuất lớn, đồng bộ, kiểm tra hàng loạt)
    Khi gửi lại cùng `Idempotency-Key`
    Thì trả lại tác vụ cũ, không tạo tác vụ mới

  @US-00-054 @FR-00-054 @M @âm
  Kịch bản: US-00-054 âm 2 · Tác vụ thất bại
    Biết thao tác được FRS phân hệ đánh dấu chạy nền (nhập tệp, xuất lớn, đồng bộ, kiểm tra hàng loạt)
    Khi tác vụ thất bại
    Thì hệ thống từ chối với ERR-00-500
    Và người dùng thấy thông báo "Tác vụ {tên} không thành công. Mã truy vết {traceId}."

  # ---- EP-00-G · Thông báo

  @US-00-060 @FR-00-060 @M
  Kịch bản: US-00-060 dương · Trung tâm thông báo trong ứng dụng
    Biết người dùng đã đăng nhập
    Khi một phân hệ gửi thông báo tới người dùng hoặc nhóm; người dùng bấm nút chuông
    Thì danh sách thông báo, số chưa đọc
    Và lịch sử thông báo xem được ở `/ca-nhan/thong-bao`

  @US-00-060 @FR-00-060 @M @âm
  Kịch bản: US-00-060 âm 1 · Đối tượng trong liên kết đã bị xóa hoặc người dùng mất quyền
    Biết người dùng đã đăng nhập
    Khi đối tượng trong liên kết đã bị xóa hoặc người dùng mất quyền
    Thì trang đích hiện `404` hoặc `403` theo FR-00-080; người dùng thấy thông báo lỗi vẫn giữ trong lịch sử

  @US-00-061 @FR-00-061 @S
  Kịch bản: US-00-061 dương · Chọn kênh nhận theo loại thông báo
    Biết người dùng có địa chỉ thư đã xác minh (cho kênh thư)
    Khi người dùng mở "Cài đặt cá nhân" → "Thông báo"
    Thì hệ thống trả `200`, cài đặt đã lưu
    Và cài đặt gắn với người dùng và tenant

  @US-00-061 @FR-00-061 @S @âm
  Kịch bản: US-00-061 âm 1 · Tắt loại bắt buộc
    Biết người dùng có địa chỉ thư đã xác minh (cho kênh thư)
    Khi tắt loại bắt buộc
    Thì lỗi tại dòng thông báo
    Và người dùng thấy thông báo "Loại thông báo này luôn được gửi trong ứng dụng."

  @US-00-062 @FR-00-062 @M
  Kịch bản: US-00-062 dương · Thư thông báo chỉ chứa liên kết, không chứa dữ liệu
    Biết người dùng bật kênh thư cho loại thông báo (FR-00-061)
    Khi dịch vụ thông báo dựng thư
    Thì thư điện tử không chứa dữ liệu nghiệp vụ

  @US-00-062 @FR-00-062 @M @âm
  Kịch bản: US-00-062 âm 1 · Gửi thư lỗi
    Biết người dùng bật kênh thư cho loại thông báo (FR-00-061)
    Khi gửi thư lỗi
    Thì dịch vụ thử lại theo chính sách chung, ghi log vận hành; người dùng thấy thông báo lỗi trong ứng dụng vẫn có, người vận hành thấy cảnh báo trên PH-13

  # ---- EP-00-H · Duyệt

  @US-00-070 @FR-00-070 @M
  Kịch bản: US-00-070 dương · Hộp "Việc của tôi" tổng hợp từ mọi phân hệ
    Biết phân hệ đã đăng ký loại việc với hộp việc chung theo hợp đồng ở D03-04
    Khi người dùng mở "Việc của tôi", hoặc bấm thông báo việc chờ duyệt
    Thì danh sách việc; số đếm việc chưa xử lý

  @US-00-070 @FR-00-070 @M @âm
  Kịch bản: US-00-070 âm 1 · Phân hệ nguồn không phản hồi khi mở chi tiết
    Biết phân hệ đã đăng ký loại việc với hộp việc chung theo hợp đồng ở D03-04
    Khi phân hệ nguồn không phản hồi khi mở chi tiết
    Thì khung chi tiết hiện thông báo; danh sách vẫn dùng được
    Và người dùng thấy thông báo "Chưa tải được nội dung yêu cầu. Bấm Thử lại."

  @US-00-071 @FR-00-071 @M
  Kịch bản: US-00-071 dương · Nguyên tắc bốn mắt: người tạo không tự duyệt
    Biết loại duyệt được FRS phân hệ đánh dấu áp dụng bốn mắt
    Khi người dùng mở hoặc quyết định một việc chờ duyệt
    Thì quyết định hoặc từ chối `403`
    Và mọi yêu cầu đã duyệt có người tạo khác người duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-071 @FR-00-071 @M @âm
  Kịch bản: US-00-071 âm 1 · Người tạo gọi API duyệt
    Biết loại duyệt được FRS phân hệ đánh dấu áp dụng bốn mắt
    Khi người tạo gọi API duyệt
    Thì hệ thống trả `403`; người dùng thấy thông báo lỗi (mã lỗi chưa có, xem đề nghị đồng bộ)
    Và người dùng thấy thông báo "Bạn là người gửi yêu cầu này nên không thể tự duyệt."

  @US-00-072 @FR-00-072 @M
  Kịch bản: US-00-072 dương · Ý kiến bắt buộc khi duyệt, lý do bắt buộc khi từ chối
    Biết việc đang ở trạng thái "Chờ duyệt"; người duyệt khác người tạo (FR-00-071)
    Khi người duyệt bấm "Duyệt", "Từ chối" hoặc "Yêu cầu bổ sung"
    Thì hệ thống trả `200`, trạng thái mới của yêu cầu
    Và yêu cầu ở "Đã duyệt", "Từ chối" hoặc "Yêu cầu bổ sung"
    Và sự kiện được phát: Theo phân hệ nguồn (ví dụ sự kiện phát hành sau khi duyệt)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-072 @FR-00-072 @M @âm
  Kịch bản: US-00-072 âm 1 · Thiếu ý kiến hoặc lý do
    Biết việc đang ở trạng thái "Chờ duyệt"; người duyệt khác người tạo (FR-00-071)
    Khi thiếu ý kiến hoặc lý do
    Thì nút quyết định bị vô hiệu; gọi API thiếu trường nhận `400` thông báo
    Và người dùng thấy thông báo "Vui lòng nhập ý kiến trước khi quyết định."

  @US-00-072 @FR-00-072 @M @âm
  Kịch bản: US-00-072 âm 2 · Việc đã được người khác xử lý
    Biết việc đang ở trạng thái "Chờ duyệt"; người duyệt khác người tạo (FR-00-071)
    Khi việc đã được người khác xử lý
    Thì hệ thống từ chối với ERR-00-412
    Và người dùng thấy thông báo "Việc này đã được {người} xử lý lúc {giờ}."

  # ---- EP-00-I · Lỗi và trợ giúp

  @US-00-080 @FR-00-080 @M
  Kịch bản: US-00-080 dương · Thông báo lỗi tiếng Việt, có mã lỗi và mã truy vết
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi một lời gọi API trả lỗi hoặc giao diện gặp lỗi
    Thì câu thông báo trên giao diện; phản hồi RFC 9457 cho HTTT

  @US-00-080 @FR-00-080 @M @âm
  Kịch bản: US-00-080 âm 1 · Lỗi không lường trước
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi lỗi không lường trước
    Thì hệ thống từ chối với ERR-00-500

  @US-00-081 @FR-00-081 @M
  Kịch bản: US-00-081 dương · Hiển thị lỗi kiểm tra hợp lệ tại trường
    Biết đang ở biểu mẫu (PTN-03, PTN-04, PTN-05)
    Khi người dùng rời trường hoặc bấm "Lưu"
    Thì câu lỗi tại trường
    Và dữ liệu đã nhập được giữ nguyên

  @US-00-081 @FR-00-081 @M @âm
  Kịch bản: US-00-081 âm 1 · Máy chủ trả lỗi trường không có trên biểu mẫu
    Biết đang ở biểu mẫu (PTN-03, PTN-04, PTN-05)
    Khi máy chủ trả lỗi trường không có trên biểu mẫu
    Thì hiển thị ở tóm tắt đầu biểu mẫu kèm tên trường

  @US-00-082 @FR-00-082 @S
  Kịch bản: US-00-082 dương · Trợ giúp theo ngữ cảnh liên kết tới HDSD
    Biết mục HDSD tương ứng màn hình đã có (D06-02)
    Khi người dùng bấm biểu tượng trợ giúp trên tiêu đề trang
    Thì nội dung trợ giúp

  @US-00-082 @FR-00-082 @S @âm
  Kịch bản: US-00-082 âm 1 · Không tải được HDSD
    Biết mục HDSD tương ứng màn hình đã có (D06-02)
    Khi không tải được HDSD
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Chưa tải được hướng dẫn. Bấm Thử lại."

  @US-00-090 @FR-00-090 @M
  Kịch bản: US-00-090 dương · Di trú dữ liệu của hệ cũ
    Biết có kết nối chỉ đọc tới hệ cũ (IF-07); tenant đích đã khởi tạo; đối tượng đích đã có mô hình ở phân hệ tương ứng
    Khi người có quyền chạy công cụ di trú cho một nhóm dữ liệu
    Thì hệ thống trả `202` mã tác vụ; báo cáo đối chiếu; danh sách lỗi
    Và hệ cũ không bị thay đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-090 @FR-00-090 @M @âm
  Kịch bản: US-00-090 âm 1 · Không kết nối được hệ cũ
    Biết có kết nối chỉ đọc tới hệ cũ (IF-07); tenant đích đã khởi tạo; đối tượng đích đã có mô hình ở phân hệ tương ứng
    Khi không kết nối được hệ cũ
    Thì tác vụ dừng, báo thông báo
    Và người dùng thấy thông báo "Không kết nối được tới hệ thống cũ. Kiểm tra kết nối chỉ đọc rồi chạy lại."

  @US-00-090 @FR-00-090 @M @âm
  Kịch bản: US-00-090 âm 2 · Bản ghi vi phạm ràng buộc đích
    Biết có kết nối chỉ đọc tới hệ cũ (IF-07); tenant đích đã khởi tạo; đối tượng đích đã có mô hình ở phân hệ tương ứng
    Khi bản ghi vi phạm ràng buộc đích
    Thì không ghi bản ghi đó, đưa vào danh sách không chuyển được; các bản ghi khác vẫn tiếp tục theo lô

  @US-00-091 @FR-00-091 @M
  Kịch bản: US-00-091 dương · Sửa lỗi thiết kế dữ liệu cũ khi di trú
    Biết FR-00-090 đang chạy
    Khi bước chuyển đổi của FR-00-090
    Thì bản ghi đích đã chuẩn hóa kiểu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-091 @FR-00-091 @M @âm
  Kịch bản: US-00-091 âm 1 · Chuỗi ngày không phân tích được
    Biết FR-00-090 đang chạy
    Khi chuỗi ngày không phân tích được
    Thì bản ghi vào danh sách không chuyển được với lý do thông báo
    Và người dùng thấy thông báo "Ngày thanh toán không đúng định dạng: {giá trị}."

  @US-00-091 @FR-00-091 @M @âm
  Kịch bản: US-00-091 âm 2 · Giá trị EAV không tìm thấy thuộc tính
    Biết FR-00-090 đang chạy
    Khi giá trị EAV không tìm thấy thuộc tính
    Thì vào danh sách không chuyển được

  @US-00-092 @FR-00-092 @M
  Kịch bản: US-00-092 dương · Báo cáo đối chiếu sau mỗi lần di trú
    Biết một lần chạy FR-00-090 kết thúc (thử hoặc thật)
    Khi tác vụ di trú kết thúc
    Thì báo cáo đối chiếu theo nhóm dữ liệu
    Và báo cáo lưu cùng tác vụ, tra cứu được
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-092 @FR-00-092 @M @âm
  Kịch bản: US-00-092 âm 1 · Có nhóm lệch
    Biết một lần chạy FR-00-090 kết thúc (thử hoặc thật)
    Khi có nhóm lệch
    Thì báo cáo đánh dấu thông báo và nêu số chênh; lần chạy thật không được đánh dấu hoàn thành cho tới khi xử lý hết chênh lệch hoặc có lý do chấp nhận
    Và người dùng thấy thông báo "Lệch"

  @US-00-093 @FR-00-093 @M
  Kịch bản: US-00-093 dương · Không di trú nguyên trạng thông tin xác thực
    Biết dữ liệu nguồn có trường thông tin xác thực (application, kết nối, luồng)
    Khi bước chuyển đổi của FR-00-090 gặp trường thông tin xác thực
    Thì đối tượng đích không chứa bí mật cũ; danh sách việc cấp lại
    Và 0 bí mật cũ trong CSDL, cấu hình, tài liệu của hệ mới (NFR-00-022)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-00-093 @FR-00-093 @M @âm
  Kịch bản: US-00-093 âm 1 · Phát hiện giá trị bí mật trong trường không khai báo
    Biết dữ liệu nguồn có trường thông tin xác thực (application, kết nối, luồng)
    Khi phát hiện giá trị bí mật trong trường không khai báo
    Thì không chép, ghi cảnh báo trong báo cáo đối chiếu để rà soát
