# language: vi
# Sinh tự động từ D02-02/D02-03-PH12 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-12
Tính năng: PH-12 · Định danh và phân quyền

  # ---- EP-12-A · Tài khoản người dùng

  @US-12-001 @FR-12-001 @M
  Kịch bản: US-12-001 dương · Liệt kê, tìm kiếm và lọc người dùng
    Biết người dùng đã đăng nhập, đã chọn tenant làm việc (FR-00-004)
    Khi người dùng mở "Quản trị người dùng" ở UI-12-01, hoặc API được gọi với bộ lọc
    Thì hệ thống trả `200`; `items[]` (mã người dùng, họ tên, tên đăng nhập, đơn vị, vai trò rút gọn, MFA, đăng nhập cuối, trạng thái), `page`, `size`, `totalElements`, `facets` (số theo trạng thái, đơn vị)

  @US-12-001 @FR-12-001 @M @âm
  Kịch bản: US-12-001 âm 1 · Tham số sai miền
    Biết người dùng đã đăng nhập, đã chọn tenant làm việc (FR-00-004)
    Khi tham số sai miền
    Thì hệ thống từ chối với ERR-12-003 (400)
    Và người dùng thấy thông báo "Bộ lọc không hợp lệ: {tên trường}."

  @US-12-001 @FR-12-001 @M @âm
  Kịch bản: US-12-001 âm 2 · Bản chiếu chưa đồng bộ kịp với Keycloak
    Biết người dùng đã đăng nhập, đã chọn tenant làm việc (FR-00-004)
    Khi bản chiếu chưa đồng bộ kịp với Keycloak
    Thì danh sách vẫn trả, kèm tiêu đề `X-DH-Projection-Lag` và dải thông báo thông báo
    Và người dùng thấy thông báo "Dữ liệu có thể chậm tới {n} phút so với hệ thống xác thực."

  @US-12-002 @FR-12-002 @M
  Kịch bản: US-12-002 dương · Xem chi tiết người dùng
    Biết người dùng cần xem tồn tại trong tenant của người xem
    Khi người dùng bấm một dòng ở UI-12-01 hoặc mở đường dẫn `/quan-tri/nguoi-dung/{ma}`
    Thì hệ thống trả `200`; thông tin người dùng, `roles[]` (mã, phạm vi, hiệu lực), `groups[]`, `factors[]` (loại, nhãn, đăng ký lúc, dùng cuối), `sessionsCount`, `lastLoginAt`, `authSource`, cờ `mfaRequired`, `ETag`

  @US-12-002 @FR-12-002 @M @âm
  Kịch bản: US-12-002 âm 1 · Không tìm thấy
    Biết người dùng cần xem tồn tại trong tenant của người xem
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-12-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy người dùng này trong tỉnh của anh/chị."

  @US-12-002 @FR-12-002 @M @âm
  Kịch bản: US-12-002 âm 2 · Không có quyền
    Biết người dùng cần xem tồn tại trong tenant của người xem
    Khi không có quyền
    Thì hệ thống từ chối với ERR-12-007 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."

  @US-12-003 @FR-12-003 @M
  Kịch bản: US-12-003 dương · Tạo tài khoản người dùng
    Biết đơn vị (`orgCode`) tồn tại và còn hiệu lực trong danh mục PH-07; thư điện tử thuộc miền công vụ được phép của tenant
    Khi TA bấm "+ Tạo người dùng" ở UI-12-01
    Thì hệ thống trả `201`, chi tiết tài khoản với `state=PENDING_ACTIVATION`; tiêu đề `Location`, `ETag`
    Và tài khoản `PENDING_ACTIVATION` ở Keycloak và bản chiếu `ph12_iam`; chưa đăng nhập được
    Và sự kiện được phát: EVT-12-01 (và EVT-12-03 nếu có vai trò ban đầu)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-003 @FR-12-003 @M @âm
  Kịch bản: US-12-003 âm 1 · Tên đăng nhập hoặc thư đã dùng
    Biết đơn vị (`orgCode`) tồn tại và còn hiệu lực trong danh mục PH-07; thư điện tử thuộc miền công vụ được phép của tenant
    Khi tên đăng nhập hoặc thư đã dùng
    Thì hệ thống từ chối với ERR-12-002 (409)
    Và người dùng thấy thông báo "Tên đăng nhập hoặc thư điện tử này đã được dùng. Chọn giá trị khác."

  @US-12-003 @FR-12-003 @M @âm
  Kịch bản: US-12-003 âm 2 · Đơn vị không có
    Biết đơn vị (`orgCode`) tồn tại và còn hiệu lực trong danh mục PH-07; thư điện tử thuộc miền công vụ được phép của tenant
    Khi đơn vị không có
    Thì hệ thống từ chối với ERR-12-004 (422)
    Và người dùng thấy thông báo "Đơn vị {mã} không tồn tại hoặc đã hết hiệu lực."

  @US-12-004 @FR-12-004 @M
  Kịch bản: US-12-004 dương · Sửa thông tin và chuyển đơn vị của người dùng
    Biết tài khoản tồn tại; không ở trạng thái `DISABLED` (kích hoạt lại trước khi sửa)
    Khi TA bấm "Sửa" ở UI-12-02 hoặc UI-12-03
    Thì hệ thống trả `200`, chi tiết tài khoản mới, `ETag` mới
    Và Keycloak và `ph12_iam` khớp nhau; phiên đang mở của cán bộ bị thu hồi nếu vai trò bị gỡ do chuyển đơn vị (BR-12-036)
    Và sự kiện được phát: EVT-12-02 (đổi đơn vị), EVT-12-03 (vai trò bị gỡ)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-004 @FR-12-004 @M @âm
  Kịch bản: US-12-004 âm 1 · Phiên bản đã đổi
    Biết tài khoản tồn tại; không ở trạng thái `DISABLED` (kích hoạt lại trước khi sửa)
    Khi phiên bản đã đổi
    Thì hệ thống từ chối với ERR-12-044 (412)
    Và người dùng thấy thông báo "Thông tin này vừa được người khác sửa. Tải lại trang để xem bản mới nhất."

  @US-12-004 @FR-12-004 @M @âm
  Kịch bản: US-12-004 âm 2 · Sửa trường nguồn LDAP
    Biết tài khoản tồn tại; không ở trạng thái `DISABLED` (kích hoạt lại trước khi sửa)
    Khi sửa trường nguồn LDAP
    Thì hệ thống từ chối với ERR-12-047 (422)
    Và người dùng thấy thông báo "Trường này do danh bạ LDAP của tỉnh quản lý; sửa ở danh bạ rồi đồng bộ."

  @US-12-005 @FR-12-005 @M
  Kịch bản: US-12-005 dương · Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản
    Biết tài khoản ở trạng thái cho phép chuyển theo máy trạng thái mục 4.3
    Khi người dùng chọn "Khóa", "Mở khóa", "Vô hiệu" hoặc "Kích hoạt lại" ở UI-12-02, UI-12-03
    Thì hệ thống trả `200`, tài khoản với `state` mới
    Và sự kiện được phát: EVT-12-02; EVT-12-05 khi khóa, vô hiệu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-005 @FR-12-005 @M @âm
  Kịch bản: US-12-005 âm 1 · Tự thao tác
    Biết tài khoản ở trạng thái cho phép chuyển theo máy trạng thái mục 4.3
    Khi tự thao tác
    Thì hệ thống từ chối với ERR-12-013 (403)
    Và người dùng thấy thông báo "Anh/chị không thể tự khóa hoặc vô hiệu tài khoản của mình."

  @US-12-005 @FR-12-005 @M @âm
  Kịch bản: US-12-005 âm 2 · Thiếu lý do
    Biết tài khoản ở trạng thái cho phép chuyển theo máy trạng thái mục 4.3
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-12-014 (400)
    Và người dùng thấy thông báo "Nhập lý do (ít nhất 10 ký tự)."

  @US-12-006 @FR-12-006 @M
  Kịch bản: US-12-006 dương · Kích hoạt tài khoản lần đầu
    Biết tài khoản `PENDING_ACTIVATION`; liên kết còn hiệu lực (24 giờ, chưa dùng)
    Khi cán bộ bấm liên kết trong thư; hoặc TA bấm "Gửi lại liên kết kích hoạt"
    Thì trang xác nhận kích hoạt của Keycloak; `204` ở API gửi lại
    Và tài khoản `ACTIVE`, có mật khẩu băm, liên kết đã hủy
    Và sự kiện được phát: EVT-12-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-006 @FR-12-006 @M @âm
  Kịch bản: US-12-006 âm 1 · Liên kết hết hạn hoặc đã dùng
    Biết tài khoản `PENDING_ACTIVATION`; liên kết còn hiệu lực (24 giờ, chưa dùng)
    Khi liên kết hết hạn hoặc đã dùng
    Thì hệ thống từ chối với ERR-12-016 (410)
    Và người dùng thấy thông báo "Liên kết đã hết hạn hoặc đã được dùng. Liên hệ quản trị tỉnh để được gửi liên kết mới."

  @US-12-006 @FR-12-006 @M @âm
  Kịch bản: US-12-006 âm 2 · Mật khẩu không đạt
    Biết tài khoản `PENDING_ACTIVATION`; liên kết còn hiệu lực (24 giờ, chưa dùng)
    Khi mật khẩu không đạt
    Thì hệ thống từ chối với ERR-12-015 (422)
    Và người dùng thấy thông báo "Mật khẩu cần ít nhất 14 ký tự, không trùng mật khẩu đã bị lộ và không chứa tên đăng nhập."

  @US-12-007 @FR-12-007 @M
  Kịch bản: US-12-007 dương · Đặt lại mật khẩu khi quên
    Biết tenant cho phép đặt lại mật khẩu tự phục vụ (tham số `12.password.self-reset`, mặc định bật); tài khoản `authSource=LOCAL`
    Khi cán bộ bấm "Quên mật khẩu" ở trang đăng nhập
    Thì trang thông báo của Keycloak; chuyển hướng về trang đăng nhập khi đặt xong
    Và mật khẩu mới có hiệu lực; mọi phiên cũ bị hủy
    Và sự kiện được phát: EVT-12-04 khi đổi mật khẩu thành công (loại sự kiện `password-changed`); EVT-12-16 cho mọi lần yêu cầu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-007 @FR-12-007 @M @âm
  Kịch bản: US-12-007 âm 1 · Mọi trường hợp tài khoản không hợp lệ
    Biết tenant cho phép đặt lại mật khẩu tự phục vụ (tham số `12.password.self-reset`, mặc định bật); tài khoản `authSource=LOCAL`
    Khi mọi trường hợp tài khoản không hợp lệ
    Thì không có lỗi riêng, người dùng luôn thấy thông báo
    Và người dùng thấy thông báo "Nếu tài khoản tồn tại, chúng tôi đã gửi hướng dẫn tới thư điện tử đăng ký."

  @US-12-007 @FR-12-007 @M @âm
  Kịch bản: US-12-007 âm 2 · Liên kết hết hạn
    Biết tenant cho phép đặt lại mật khẩu tự phục vụ (tham số `12.password.self-reset`, mặc định bật); tài khoản `authSource=LOCAL`
    Khi liên kết hết hạn
    Thì hệ thống từ chối với ERR-12-016 (410)
    Và người dùng thấy thông báo "Liên kết đã hết hạn. Hãy yêu cầu liên kết mới."

  @US-12-008 @FR-12-008 @M
  Kịch bản: US-12-008 dương · Tự vô hiệu tài khoản và tạm ngừng client không hoạt động
    Biết tenant `ACTIVE`; tác vụ chạy hằng ngày lúc 01:00 giờ địa phương
    Khi đồng hồ tác vụ định kỳ
    Thì báo cáo lượt chạy: số tài khoản, client đã xử lý, số cảnh báo đã gửi (xem ở UI-12-15)
    Và trạng thái tài khoản, client cập nhật; phiên và token bị chặn theo FR-12-040
    Và sự kiện được phát: EVT-12-02, EVT-12-07, EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-008 @FR-12-008 @M @âm
  Kịch bản: US-12-008 âm 1 · Keycloak không phản hồi giữa chừng
    Biết tenant `ACTIVE`; tác vụ chạy hằng ngày lúc 01:00 giờ địa phương
    Khi Keycloak không phản hồi giữa chừng
    Thì dừng lượt, ghi cảnh báo, chạy lại sau 1 giờ; thao tác đã làm không hoàn tác (idempotent)

  @US-12-008 @FR-12-008 @M @âm
  Kịch bản: US-12-008 âm 2 · Không đọc được thời điểm đăng nhập cuối của một tài khoản
    Biết tenant `ACTIVE`; tác vụ chạy hằng ngày lúc 01:00 giờ địa phương
    Khi không đọc được thời điểm đăng nhập cuối của một tài khoản
    Thì bỏ qua tài khoản đó và ghi cảnh báo, không vô hiệu theo suy đoán

  @US-12-009 @FR-12-009 @M
  Kịch bản: US-12-009 dương · Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ
    Biết tenant đã có danh mục đơn vị (PH-07); bảng ánh xạ vai trò hệ cũ đã khai báo hoặc dùng bảng mặc định ở mục 11.3
    Khi TA bấm "Nhập từ tệp" ở UI-12-01 và mở UI-12-04
    Thì hệ thống trả `202` ở pha 1 với `importId`; `200` ở xem trước (số dòng, lỗi); `202` ở pha 2 kèm báo cáo khi xong
    Và tài khoản hợp lệ ở `PENDING_ACTIVATION`; không có mật khẩu nào đi qua tệp; tệp nhập xóa sau 24 giờ
    Và sự kiện được phát: EVT-12-01, EVT-12-03 cho từng tài khoản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-009 @FR-12-009 @M @âm
  Kịch bản: US-12-009 âm 1 · Tệp sai định dạng hoặc quá lớn
    Biết tenant đã có danh mục đơn vị (PH-07); bảng ánh xạ vai trò hệ cũ đã khai báo hoặc dùng bảng mặc định ở mục 11.3
    Khi tệp sai định dạng hoặc quá lớn
    Thì hệ thống từ chối với ERR-12-035
    Và người dùng thấy thông báo "Tệp không đúng mẫu hoặc quá 5.000 dòng."

  @US-12-009 @FR-12-009 @M @âm
  Kịch bản: US-12-009 âm 2 · Vai trò cũ chưa có ánh xạ
    Biết tenant đã có danh mục đơn vị (PH-07); bảng ánh xạ vai trò hệ cũ đã khai báo hoặc dùng bảng mặc định ở mục 11.3
    Khi vai trò cũ chưa có ánh xạ
    Thì hệ thống từ chối với ERR-12-036 (422)
    Và người dùng thấy thông báo "Dòng {n}: vai trò {tên} chưa có ánh xạ. Thêm vào bảng ánh xạ hoặc bỏ cột này."

  @US-12-010 @FR-12-010 @S
  Kịch bản: US-12-010 dương · Đồng bộ thuộc tính người dùng từ danh mục đơn vị
    Biết PH-07 có danh mục đơn vị hành chính hiện hành của tenant
    Khi đồng hồ hằng ngày lúc 02:00, hoặc sự kiện thay đổi danh mục đơn vị của PH-07
    Thì báo cáo lượt đồng bộ: số người cập nhật, số cần rà soát
    Và thuộc tính đơn vị của người dùng cập nhật; vai trò không bị đổi ngoài ánh xạ kế thừa
    Và sự kiện được phát: EVT-12-02 cho người dùng đổi đơn vị
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-010 @FR-12-010 @S @âm
  Kịch bản: US-12-010 âm 1 · PH-07 không khả dụng
    Biết PH-07 có danh mục đơn vị hành chính hiện hành của tenant
    Khi PH-07 không khả dụng
    Thì bỏ qua lượt này, ghi cảnh báo, dùng bản đệm gần nhất; người dùng thấy thông báo lỗi hiển thị ở UI-12-07
    Và người dùng thấy thông báo "Danh mục đơn vị chưa cập nhật được từ {thời điểm}"

  # ---- EP-12-B · Vai trò, nhóm và quyền

  @US-12-011 @FR-12-011 @M
  Kịch bản: US-12-011 dương · Xem danh mục vai trò chuẩn và quyền
    Biết tenant đã khởi tạo xong (vai trò chuẩn đã có)
    Khi người dùng mở "Vai trò và quyền" ở UI-12-05
    Thì hệ thống trả `200`; `roles[]` (`roleCode`, tên, `scope`, `mfaRequired`, `type`, `holders`), `permissions[]` theo phân hệ, `source` (số phiên bản D02-08 sinh dữ liệu)

  @US-12-011 @FR-12-011 @M @âm
  Kịch bản: US-12-011 âm 1 · Không tìm thấy vai trò
    Biết tenant đã khởi tạo xong (vai trò chuẩn đã có)
    Khi không tìm thấy vai trò
    Thì hệ thống từ chối với ERR-12-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy vai trò này."

  @US-12-011 @FR-12-011 @M @âm
  Kịch bản: US-12-011 âm 2 · Dữ liệu ma trận chưa nạp (tenant mới khởi tạo dở)
    Biết tenant đã khởi tạo xong (vai trò chuẩn đã có)
    Khi dữ liệu ma trận chưa nạp (tenant mới khởi tạo dở)
    Thì hệ thống từ chối với ERR-12-040 (503)
    Và người dùng thấy thông báo "Danh mục vai trò chưa sẵn sàng. Thử lại sau ít phút."

  @US-12-012 @FR-12-012 @M
  Kịch bản: US-12-012 dương · Gán và gỡ vai trò cho người dùng
    Biết người dùng `ACTIVE` hoặc `PENDING_ACTIVATION`; vai trò tồn tại; người gán đã xác thực mức 2 trong 5 phút (FR-12-023)
    Khi TA bấm "Gán vai trò" ở UI-12-02 hoặc UI-12-06; hoặc FR-12-003, FR-12-009 gọi khi tạo
    Thì hệ thống trả `201` (gán) hoặc `204` (gỡ); thân gồm `assignmentId`, vai trò, phạm vi, hiệu lực
    Và bản gán lưu; dữ liệu gói chính sách yêu cầu tái sinh; phiên bị thu hồi khi hạ quyền
    Và sự kiện được phát: EVT-12-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-012 @FR-12-012 @M @âm
  Kịch bản: US-12-012 âm 1 · Tự gán hoặc gỡ cho chính mình
    Biết người dùng `ACTIVE` hoặc `PENDING_ACTIVATION`; vai trò tồn tại; người gán đã xác thực mức 2 trong 5 phút (FR-12-023)
    Khi tự gán hoặc gỡ cho chính mình
    Thì hệ thống từ chối với ERR-12-013 (403)
    Và người dùng thấy thông báo "Anh/chị không thể tự gán hoặc gỡ vai trò của mình."

  @US-12-012 @FR-12-012 @M @âm
  Kịch bản: US-12-012 âm 2 · Vai trò hoặc phạm vi sai
    Biết người dùng `ACTIVE` hoặc `PENDING_ACTIVATION`; vai trò tồn tại; người gán đã xác thực mức 2 trong 5 phút (FR-12-023)
    Khi vai trò hoặc phạm vi sai
    Thì hệ thống từ chối với ERR-12-010 (422)
    Và người dùng thấy thông báo "Vai trò {vai trò} không gán được với phạm vi {phạm vi} cho người dùng này."

  @US-12-013 @FR-12-013 @M
  Kịch bản: US-12-013 dương · Chặn cặp vai trò xung đột và duyệt ngoại lệ có thời hạn
    Biết bảng cặp xung đột (bảy cặp ở D02-08 §4) đã nạp vào gói chính sách của tenant
    Khi FR-12-012 phát hiện xung đột ở bước 5; hoặc TA mở "Đề nghị ngoại lệ" ở UI-12-06
    Thì hệ thống trả `201` khi tạo đề nghị; `200` khi duyệt, từ chối, thu hồi; thân gồm `exceptionId`, `state`, `expiresAt`
    Và ngoại lệ `ACTIVE` kèm bản gán; khi hết hạn vai trò phải gỡ bị gỡ và phiên bị thu hồi
    Và sự kiện được phát: EVT-12-12, EVT-12-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-013 @FR-12-013 @M @âm
  Kịch bản: US-12-013 âm 1 · Người duyệt trùng người đề nghị hoặc người được gán
    Biết bảng cặp xung đột (bảy cặp ở D02-08 §4) đã nạp vào gói chính sách của tenant
    Khi người duyệt trùng người đề nghị hoặc người được gán
    Thì hệ thống từ chối với ERR-12-008 (403)
    Và người dùng thấy thông báo "Anh/chị là người đề nghị hoặc người được gán nên không được duyệt ngoại lệ này."

  @US-12-013 @FR-12-013 @M @âm
  Kịch bản: US-12-013 âm 2 · Thời hạn vượt tối đa
    Biết bảng cặp xung đột (bảy cặp ở D02-08 §4) đã nạp vào gói chính sách của tenant
    Khi thời hạn vượt tối đa
    Thì hệ thống từ chối với ERR-12-043 (422)
    Và người dùng thấy thông báo "Thời hạn ngoại lệ tối đa {n} ngày."

  @US-12-014 @FR-12-014 @M
  Kịch bản: US-12-014 dương · Quản lý nhóm và đơn vị tổ chức
    Biết cây đơn vị tenant đã nạp từ PH-07 (FR-12-010)
    Khi TA mở "Nhóm và đơn vị" ở UI-12-07
    Thì hệ thống trả `200` hoặc `201`; nhóm với cây con, số thành viên
    Và nhóm lưu; thành viên cập nhật
    Và sự kiện được phát: EVT-12-03 khi thay đổi thành viên làm thay đổi phạm vi tổ chức của người nào đó
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-014 @FR-12-014 @M @âm
  Kịch bản: US-12-014 âm 1 · Vòng lặp nhóm
    Biết cây đơn vị tenant đã nạp từ PH-07 (FR-12-010)
    Khi vòng lặp nhóm
    Thì hệ thống từ chối với ERR-12-012 (422)
    Và người dùng thấy thông báo "Nhóm cha này làm thành vòng lặp: {đường đi}."

  @US-12-014 @FR-12-014 @M @âm
  Kịch bản: US-12-014 âm 2 · Nhóm còn thành viên hoặc đang dùng
    Biết cây đơn vị tenant đã nạp từ PH-07 (FR-12-010)
    Khi nhóm còn thành viên hoặc đang dùng
    Thì hệ thống từ chối với ERR-12-011 (409)
    Và người dùng thấy thông báo "Nhóm còn {n} thành viên. Chuyển hoặc gỡ họ trước khi xóa."

  @US-12-015 @FR-12-015 @S
  Kịch bản: US-12-015 dương · Tạo vai trò tùy biến của tenant
    Biết tenant bật tham số `12.role.custom-enabled` (mặc định tắt ở MVP)
    Khi TA bấm "+ Vai trò tùy biến" ở UI-12-05
    Thì hệ thống trả `201`, vai trò với `state` theo chính sách; sau phát hành `PUBLISHED`
    Và dữ liệu vai trò–quyền của tenant gồm vai trò tùy biến; vai trò không bao giờ mang quyền ngoài phạm vi tenant
    Và sự kiện được phát: EVT-12-09 khi phát hành chính sách `custom-roles`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-015 @FR-12-015 @S @âm
  Kịch bản: US-12-015 âm 1 · Quyền đặc quyền
    Biết tenant bật tham số `12.role.custom-enabled` (mặc định tắt ở MVP)
    Khi quyền đặc quyền
    Thì hệ thống từ chối với ERR-12-010 (422)
    Và người dùng thấy thông báo "Vai trò tùy biến không được chứa quyền {quyền}."

  @US-12-016 @FR-12-016 @M
  Kịch bản: US-12-016 dương · Xem quyền hiệu lực của người dùng
    Biết gói chính sách hiện hành đã nạp ở dịch vụ quản trị
    Khi người dùng mở tab "Quyền hiệu lực" ở UI-12-02; hoặc hỏi ngược theo quyền
    Thì hệ thống trả `200`; `permissions[]` (`permission`, `scope`, `source`, `validTo`, `conditions[]`), `generatedFromBundle` (phiên bản gói), `computedAt`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-016 @FR-12-016 @M @âm
  Kịch bản: US-12-016 âm 1 · Không tìm thấy người dùng
    Biết gói chính sách hiện hành đã nạp ở dịch vụ quản trị
    Khi không tìm thấy người dùng
    Thì hệ thống từ chối với ERR-12-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy người dùng này."

  @US-12-016 @FR-12-016 @M @âm
  Kịch bản: US-12-016 âm 2 · OPA hoặc dữ liệu gói chưa sẵn sàng
    Biết gói chính sách hiện hành đã nạp ở dịch vụ quản trị
    Khi OPA hoặc dữ liệu gói chưa sẵn sàng
    Thì hệ thống từ chối với ERR-12-040 (503)
    Và người dùng thấy thông báo "Chưa tính được quyền hiệu lực. Thử lại sau."

  @US-12-017 @FR-12-017 @M
  Kịch bản: US-12-017 dương · Cấp quyền có thời hạn cho vai trò đặc quyền và truy cập liên tenant
    Biết người đề nghị có tài khoản ở realm `dh-platform` và đã xác thực mức 3 (WebAuthn) trong 5 phút; tenant đích `ACTIVE` hoặc `SUSPENDED`
    Khi người đề nghị bấm "Đề nghị quyền" ở UI-12-08
    Thì hệ thống trả `201` khi đề nghị; `200` khi duyệt, từ chối, thu hồi; `grantId`, `state`, `expiresAt`
    Và quyền tự hết hạn; không còn bản gán, phiên hay danh sách chặn tồn lưu sau hạn
    Và sự kiện được phát: EVT-12-11, EVT-12-05 khi thu hồi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-017 @FR-12-017 @M @âm
  Kịch bản: US-12-017 âm 1 · Thời lượng vượt 4 giờ hoặc thiếu mã phiếu
    Biết người đề nghị có tài khoản ở realm `dh-platform` và đã xác thực mức 3 (WebAuthn) trong 5 phút; tenant đích `ACTIVE` hoặc `SUSPENDED`
    Khi thời lượng vượt 4 giờ hoặc thiếu mã phiếu
    Thì hệ thống từ chối với ERR-12-030 (422)
    Và người dùng thấy thông báo "Quyền có thời hạn tối đa 4 giờ và phải kèm mã phiếu hỗ trợ."

  @US-12-017 @FR-12-017 @M @âm
  Kịch bản: US-12-017 âm 2 · Người duyệt trùng người đề nghị
    Biết người đề nghị có tài khoản ở realm `dh-platform` và đã xác thực mức 3 (WebAuthn) trong 5 phút; tenant đích `ACTIVE` hoặc `SUSPENDED`
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-12-008 (403)
    Và người dùng thấy thông báo "Anh/chị là người đề nghị nên không được tự duyệt."

  @US-12-018 @FR-12-018 @S
  Kịch bản: US-12-018 dương · Rà soát quyền định kỳ
    Biết mỗi người dùng trong phạm vi có `managerUserId` hoặc được gán người rà soát thay thế; chu kỳ rà soát đã cấu hình
    Khi TA, SO bấm "Mở chiến dịch" ở UI-12-09; hoặc lịch tự động theo `12.recert.interval-days.admin` (90 ngày) và `12.recert.interval-days.other` (180 ngày)
    Thì hệ thống trả `201` khi mở; `200` khi quyết định từng mục; báo cáo chiến dịch khi đóng
    Và bản gán không được xác nhận bị gỡ; chiến dịch `CLOSED` và lưu vĩnh viễn
    Và sự kiện được phát: EVT-12-15, EVT-12-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-018 @FR-12-018 @S @âm
  Kịch bản: US-12-018 âm 1 · Đã có chiến dịch mở cho cùng phạm vi
    Biết mỗi người dùng trong phạm vi có `managerUserId` hoặc được gán người rà soát thay thế; chu kỳ rà soát đã cấu hình
    Khi đã có chiến dịch mở cho cùng phạm vi
    Thì hệ thống từ chối với ERR-12-031 (409)
    Và người dùng thấy thông báo "Đang có chiến dịch rà soát cho phạm vi này."

  @US-12-019 @FR-12-019 @S
  Kịch bản: US-12-019 dương · Chuyển định danh và vai trò khi sáp nhập tenant
    Biết quy trình sáp nhập của PH-20 đã đến bước "Chuyển định danh"; realm đích `ACTIVE`; realm nguồn `ACTIVE`
    Khi PH-20 gọi API kế hoạch chuyển định danh rồi thực hiện
    Thì hệ thống trả `200` kế hoạch; `202` thực hiện với báo cáo (số tài khoản chuyển, số trùng gộp, số chờ ngoại lệ, số client cấp mới)
    Và realm nguồn chỉ-đọc; tài khoản cũ giữ truy vết; client cũ hết hạn khi hết thời gian chuyển tiếp
    Và sự kiện được phát: EVT-12-01, EVT-12-03, EVT-12-06, EVT-12-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-019 @FR-12-019 @S @âm
  Kịch bản: US-12-019 âm 1 · Realm đích không `ACTIVE`
    Biết quy trình sáp nhập của PH-20 đã đến bước "Chuyển định danh"; realm đích `ACTIVE`; realm nguồn `ACTIVE`
    Khi realm đích không `ACTIVE`
    Thì hệ thống từ chối với ERR-12-041 (409)
    Và người dùng thấy thông báo "Tỉnh đích chưa sẵn sàng nhận định danh."

  # ---- EP-12-C · Xác thực người dùng

  @US-12-020 @FR-12-020 @M
  Kịch bản: US-12-020 dương · Xác thực người dùng theo OIDC Authorization Code và PKCE
    Biết realm `dh-{tenant}` `ACTIVE`; client `dh-console`, `dh-portal` đã khai báo với `redirect_uri` khớp chính xác; tài khoản `ACTIVE`
    Khi BFF chuyển trình duyệt tới điểm cuối `auth` của realm khi không có phiên (FR-00-001)
    Thì hệ thống trả `302` về `redirect_uri` kèm mã; ở điểm cuối `token`: `200` với `access_token`, `id_token`, `refresh_token`, `expires_in=300`
    Và phiên SSO ở Keycloak (nhàn rỗi tối đa 15 phút, tối đa 10 giờ); không có mật khẩu hay token trong trình duyệt
    Và sự kiện được phát: EVT-12-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-020 @FR-12-020 @M @âm
  Kịch bản: US-12-020 âm 1 · Sai tên hoặc mật khẩu
    Biết realm `dh-{tenant}` `ACTIVE`; client `dh-console`, `dh-portal` đã khai báo với `redirect_uri` khớp chính xác; tài khoản `ACTIVE`
    Khi sai tên hoặc mật khẩu
    Thì hệ thống từ chối với ERR-12-111 (401)
    Và người dùng thấy thông báo "Tên đăng nhập hoặc mật khẩu không đúng."

  @US-12-020 @FR-12-020 @M @âm
  Kịch bản: US-12-020 âm 2 · Tài khoản khóa tạm
    Biết realm `dh-{tenant}` `ACTIVE`; client `dh-console`, `dh-portal` đã khai báo với `redirect_uri` khớp chính xác; tài khoản `ACTIVE`
    Khi tài khoản khóa tạm
    Thì hệ thống từ chối với ERR-12-112 (423)
    Và người dùng thấy thông báo "Tài khoản tạm khóa do đăng nhập sai nhiều lần. Thử lại sau {n} phút."

  @US-12-021 @FR-12-021 @M
  Kịch bản: US-12-021 dương · Chống dò mật khẩu và khóa tài khoản
    Biết chính sách mật khẩu và phát hiện dò đã bật ở realm (cấu hình GitOps, FR-12-042)
    Khi người dùng đặt hoặc đổi mật khẩu; mỗi lần đăng nhập sai
    Thì trang đăng nhập hiển thị lỗi tương ứng; chỉ số `iam_login_total{result}`
    Và bộ đếm sai, bộ đếm khóa tạm cập nhật; tài khoản ở `LOCKED` hoặc `BLOCKED` khi vượt ngưỡng
    Và sự kiện được phát: EVT-12-02 (khóa), EVT-12-16, EVT-12-14 (khi khóa hẳn hoặc bị dò)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-021 @FR-12-021 @M @âm
  Kịch bản: US-12-021 âm 1 · Mật khẩu không đạt
    Biết chính sách mật khẩu và phát hiện dò đã bật ở realm (cấu hình GitOps, FR-12-042)
    Khi mật khẩu không đạt
    Thì hệ thống từ chối với ERR-12-015 (422)
    Và người dùng thấy thông báo "Mật khẩu cần ít nhất 14 ký tự, không trùng mật khẩu đã bị lộ và không chứa tên đăng nhập."

  @US-12-021 @FR-12-021 @M @âm
  Kịch bản: US-12-021 âm 2 · Khóa tạm
    Biết chính sách mật khẩu và phát hiện dò đã bật ở realm (cấu hình GitOps, FR-12-042)
    Khi khóa tạm
    Thì hệ thống từ chối với ERR-12-112 (423)
    Và người dùng thấy thông báo "Tài khoản tạm khóa do đăng nhập sai nhiều lần. Thử lại sau {n} phút."

  @US-12-022 @FR-12-022 @M
  Kịch bản: US-12-022 dương · Đăng ký và dùng yếu tố thứ hai TOTP, WebAuthn
    Biết người dùng đã qua bước mật khẩu; có thiết bị tạo mã TOTP hoặc khóa WebAuthn
    Khi Keycloak đánh giá luồng xác thực có điều kiện sau bước mật khẩu; hoặc người dùng chọn "Bảo mật tài khoản"
    Thì token mang `acr`, `auth_time`; danh sách yếu tố của người dùng
    Và yếu tố lưu ở Keycloak dưới dạng không đọc ngược được (khóa công khai WebAuthn, bí mật TOTP mã hóa); không hiển thị lại
    Và sự kiện được phát: EVT-12-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-022 @FR-12-022 @M @âm
  Kịch bản: US-12-022 âm 1 · Mã TOTP sai hoặc hết hạn
    Biết người dùng đã qua bước mật khẩu; có thiết bị tạo mã TOTP hoặc khóa WebAuthn
    Khi mã TOTP sai hoặc hết hạn
    Thì hệ thống từ chối với ERR-12-111 (401)
    Và người dùng thấy thông báo "Mã xác thực không đúng hoặc đã hết hạn. Nhập mã mới trên ứng dụng xác thực."

  @US-12-022 @FR-12-022 @M @âm
  Kịch bản: US-12-022 âm 2 · Bỏ qua bước đăng ký
    Biết người dùng đã qua bước mật khẩu; có thiết bị tạo mã TOTP hoặc khóa WebAuthn
    Khi bỏ qua bước đăng ký
    Thì không vào được ứng dụng; trang đăng ký hiện lại với dòng thông báo
    Và người dùng thấy thông báo "Vai trò của bạn bắt buộc xác thực hai yếu tố."

  @US-12-023 @FR-12-023 @M
  Kịch bản: US-12-023 dương · Xác thực lại bước lên cho thao tác nhạy cảm
    Biết người dùng có phiên; token mang `acr`, `auth_time`
    Khi OPA trả nghĩa vụ `STEPUP` cho một thao tác khi `acr` thấp hơn mức yêu cầu hoặc `auth_time` cũ hơn 5 phút
    Thì hệ thống trả `401` kèm tiêu đề thách thức ở bước 3; sau đó `2xx` của thao tác gốc
    Và token mới thay token cũ trong phiên BFF; mã phiên sinh lại sau step-up (SEC-29)
    Và sự kiện được phát: EVT-12-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-023 @FR-12-023 @M @âm
  Kịch bản: US-12-023 âm 1 · Xác thực lại thất bại
    Biết người dùng có phiên; token mang `acr`, `auth_time`
    Khi xác thực lại thất bại
    Thì tính vào số lần sai (FR-12-021); người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Xác thực lại không thành công. Thử lại."

  @US-12-023 @FR-12-023 @M @âm
  Kịch bản: US-12-023 âm 2 · Mức yêu cầu 3 nhưng người dùng chưa đăng ký WebAuthn
    Biết người dùng có phiên; token mang `acr`, `auth_time`
    Khi mức yêu cầu 3 nhưng người dùng chưa đăng ký WebAuthn
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Thao tác này cần khóa bảo mật. Đăng ký khóa ở Bảo mật tài khoản."

  @US-12-024 @FR-12-024 @M
  Kịch bản: US-12-024 dương · Đặt lại yếu tố thứ hai khi mất thiết bị
    Biết tài khoản `ACTIVE` hoặc `LOCKED`; người đặt lại cao hơn một cấp về vai trò (BR-12-034) và đã xác thực mức 3
    Khi quản trị bấm "Đặt lại yếu tố thứ hai" ở UI-12-02
    Thì hệ thống trả `200` (tài khoản thường) hoặc `202` chờ duyệt (tài khoản quản trị); thân gồm `requestId`, `state`
    Và tài khoản không còn yếu tố thứ hai tới khi đăng ký lại; không vào được ứng dụng trước đó
    Và sự kiện được phát: EVT-12-04, EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-024 @FR-12-024 @M @âm
  Kịch bản: US-12-024 âm 1 · Không đủ cấp
    Biết tài khoản `ACTIVE` hoặc `LOCKED`; người đặt lại cao hơn một cấp về vai trò (BR-12-034) và đã xác thực mức 3
    Khi không đủ cấp
    Thì hệ thống từ chối với ERR-12-017 (403)
    Và người dùng thấy thông báo "Chỉ quản trị cấp trên mới đặt lại được yếu tố thứ hai của tài khoản này."

  @US-12-024 @FR-12-024 @M @âm
  Kịch bản: US-12-024 âm 2 · Tự đặt lại
    Biết tài khoản `ACTIVE` hoặc `LOCKED`; người đặt lại cao hơn một cấp về vai trò (BR-12-034) và đã xác thực mức 3
    Khi tự đặt lại
    Thì hệ thống từ chối với ERR-12-013 (403)
    Và người dùng thấy thông báo "Anh/chị không thể tự đặt lại yếu tố thứ hai của mình."

  @US-12-025 @FR-12-025 @M
  Kịch bản: US-12-025 dương · Đăng nhập một lần bằng SAML 2 cho ứng dụng cũ
    Biết ứng dụng (nhà cung cấp dịch vụ, SP) cung cấp metadata có chứng thư ký còn hạn ít nhất 90 ngày và địa chỉ nhận khẳng định (ACS) dùng HTTPS
    Khi TA khai báo SP ở UI-12-11; người dùng mở ứng dụng SAML
    Thì hệ thống trả `201` khi khai báo; SAML `Response` đã ký tới ACS khi đăng nhập
    Và SAML client lưu ở realm, tên miền và chứng thư của SP ghi vào kiểm toán
    Và sự kiện được phát: EVT-12-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-025 @FR-12-025 @M @âm
  Kịch bản: US-12-025 âm 1 · Chữ ký `AuthnRequest` sai hoặc SP chưa đăng ký
    Biết ứng dụng (nhà cung cấp dịch vụ, SP) cung cấp metadata có chứng thư ký còn hạn ít nhất 90 ngày và địa chỉ nhận khẳng định (ACS) dùng HTTPS
    Khi chữ ký `AuthnRequest` sai hoặc SP chưa đăng ký
    Thì từ chối, ghi cảnh báo an ninh; người dùng thấy thông báo (`403`)
    Và người dùng thấy thông báo "Ứng dụng này chưa được đăng ký đăng nhập một lần. Liên hệ quản trị tỉnh."

  @US-12-025 @FR-12-025 @M @âm
  Kịch bản: US-12-025 âm 2 · Metadata không hợp lệ
    Biết ứng dụng (nhà cung cấp dịch vụ, SP) cung cấp metadata có chứng thư ký còn hạn ít nhất 90 ngày và địa chỉ nhận khẳng định (ACS) dùng HTTPS
    Khi metadata không hợp lệ
    Thì hệ thống từ chối với ERR-12-033 (422)
    Và người dùng thấy thông báo "Metadata của ứng dụng không hợp lệ: {lý do}."

  @US-12-026 @FR-12-026 @M
  Kịch bản: US-12-026 dương · Liên kết LDAP, Active Directory của tỉnh
    Biết tỉnh cung cấp máy chủ LDAPS (cổng 636, TLS từ 1.2), tài khoản đọc chỉ-đọc, chứng thư CA tin cậy; đích LDAP nằm trong danh sách egress của tenant
    Khi TA mở "Liên kết định danh" ở UI-12-11
    Thì hệ thống trả `200` hoặc `201`; kết quả kiểm tra (số người, ánh xạ mẫu); báo cáo đồng bộ (thêm, cập nhật, vô hiệu, bỏ qua)
    Và liên kết `ACTIVE`; bí mật chỉ nằm ở OpenBao
    Và sự kiện được phát: EVT-12-01, EVT-12-02 cho người nhập hoặc vô hiệu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-026 @FR-12-026 @M @âm
  Kịch bản: US-12-026 âm 1 · Không kết nối, chứng thư không tin cậy hoặc bind sai
    Biết tỉnh cung cấp máy chủ LDAPS (cổng 636, TLS từ 1.2), tài khoản đọc chỉ-đọc, chứng thư CA tin cậy; đích LDAP nằm trong danh sách egress của tenant
    Khi không kết nối, chứng thư không tin cậy hoặc bind sai
    Thì hệ thống từ chối với ERR-12-032 (422)
    Và người dùng thấy thông báo "Không kết nối được tới danh bạ {máy chủ}: {lý do}."

  @US-12-026 @FR-12-026 @M @âm
  Kịch bản: US-12-026 âm 2 · LDAP không khả dụng khi đăng nhập
    Biết tỉnh cung cấp máy chủ LDAPS (cổng 636, TLS từ 1.2), tài khoản đọc chỉ-đọc, chứng thư CA tin cậy; đích LDAP nằm trong danh sách egress của tenant
    Khi LDAP không khả dụng khi đăng nhập
    Thì người dùng LDAP thấy thông báo tài khoản cục bộ không bị ảnh hưởng
    Và người dùng thấy thông báo "Hệ thống danh bạ của tỉnh tạm thời không khả dụng. Thử lại sau."

  @US-12-027 @FR-12-027 @M
  Kịch bản: US-12-027 dương · Đăng nhập liên tenant cho người dùng thuộc nhiều tenant
    Biết hai realm tồn tại: `dh-platform` và realm tenant đích
    Khi BFF yêu cầu token của tenant đích khi người dùng đổi tenant (FR-00-004 bước 3)
    Thì token của realm đích; hoặc lỗi nêu trên
    Và phiên ở realm đích hết hạn không muộn hơn quyền; không có tài khoản môi giới tồn tại sau khi quyền hết hạn (xóa tự động)
    Và sự kiện được phát: EVT-12-16, EVT-12-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-027 @FR-12-027 @M @âm
  Kịch bản: US-12-027 âm 1 · Không có quyền có thời hạn
    Biết hai realm tồn tại: `dh-platform` và realm tenant đích
    Khi không có quyền có thời hạn
    Thì hệ thống từ chối với ERR-12-007 (403)
    Và người dùng thấy thông báo "Anh/chị không có quyền truy cập tỉnh {tên}. Đề nghị quyền có thời hạn ở Quyền truy cập."

  @US-12-027 @FR-12-027 @M @âm
  Kịch bản: US-12-027 âm 2 · Quyền hết hạn giữa phiên
    Biết hai realm tồn tại: `dh-platform` và realm tenant đích
    Khi quyền hết hạn giữa phiên
    Thì hệ thống từ chối với ERR-12-116
    Và người dùng thấy thông báo "Quyền truy cập tỉnh {tên} đã hết hạn."

  @US-12-028 @FR-12-028 @C
  Kịch bản: US-12-028 dương · Liên kết đăng nhập VNeID
    Biết cơ quan đã được cấp quyền tích hợp VNeID (giả định GĐ-12-01); tenant bật `12.vneid.enabled`; cấu hình khách VNeID đã nạp ở OpenBao
    Khi người dùng bấm "Đăng nhập bằng VNeID" ở trang đăng nhập; hoặc "Liên kết VNeID" ở Bảo mật tài khoản
    Thì phiên SSO; bản ghi liên kết (không chứa số định danh rõ)
    Và liên kết lưu dạng băm; mức `acr` của phiên theo VNeID
    Và sự kiện được phát: EVT-12-04, EVT-12-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-028 @FR-12-028 @C @âm
  Kịch bản: US-12-028 âm 1 · Số định danh chưa liên kết và người dùng không có tài khoản nội bộ
    Biết cơ quan đã được cấp quyền tích hợp VNeID (giả định GĐ-12-01); tenant bật `12.vneid.enabled`; cấu hình khách VNeID đã nạp ở OpenBao
    Khi số định danh chưa liên kết và người dùng không có tài khoản nội bộ
    Thì từ chối, **không** tự tạo tài khoản (BR-12-029); người dùng thấy thông báo lỗi
    Và người dùng thấy thông báo "Số định danh này chưa được liên kết với tài khoản Datahub. Liên hệ quản trị tỉnh."

  @US-12-029 @FR-12-029 @M
  Kịch bản: US-12-029 dương · Quản lý phiên: xem, buộc đăng xuất, hạn mức phiên
    Biết người dùng có ít nhất một phiên đang mở khi xem hoặc buộc đăng xuất
    Khi quản trị mở tab "Phiên" ở UI-12-02; hoặc người dùng mở thêm phiên vượt hạn mức
    Thì hệ thống trả `200` danh sách phiên; `204` khi buộc đăng xuất
    Và phiên bị hủy không dùng lại được
    Và sự kiện được phát: EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-029 @FR-12-029 @M @âm
  Kịch bản: US-12-029 âm 1 · Tự buộc đăng xuất tất cả phiên của chính mình qua trang quản trị
    Biết người dùng có ít nhất một phiên đang mở khi xem hoặc buộc đăng xuất
    Khi tự buộc đăng xuất tất cả phiên của chính mình qua trang quản trị
    Thì hệ thống từ chối với ERR-12-013 (403)
    Và người dùng thấy thông báo "Dùng trang Phiên đăng nhập của tôi."

  @US-12-029 @FR-12-029 @M @âm
  Kịch bản: US-12-029 âm 2 · Thiếu lý do
    Biết người dùng có ít nhất một phiên đang mở khi xem hoặc buộc đăng xuất
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-12-014 (400)
    Và người dùng thấy thông báo "Nhập lý do buộc đăng xuất."

  # ---- EP-12-D · Danh tính HTTT và token

  @US-12-030 @FR-12-030 @M
  Kịch bản: US-12-030 dương · Cấp client OAuth cho HTTT thành viên
    Biết HTTT ở PH-01 ở trạng thái đã duyệt; chưa có client cho `systemCode` đó; hợp đồng đã có mức phân loại cao nhất (D03-07 §4)
    Khi PH-01 gọi API tạo client trong saga kết nạp (bước tạo client, D03-01 §7.3)
    Thì hệ thống trả `201`, chi tiết client (`clientId`, `state`, `authMethod`, `contractLevel`, `credentialReady`, `scopes[]`, `secretHandover` chỉ có địa chỉ bọc); tiêu đề `Location`, `ETag`
    Và client `ENABLED` ở Keycloak và `ph12_iam`; bí mật không nằm ở bất kỳ phản hồi, log, CSDL của dịch vụ quản trị
    Và sự kiện được phát: EVT-12-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-030 @FR-12-030 @M @âm
  Kịch bản: US-12-030 âm 1 · Client đã có
    Biết HTTT ở PH-01 ở trạng thái đã duyệt; chưa có client cho `systemCode` đó; hợp đồng đã có mức phân loại cao nhất (D03-07 §4)
    Khi client đã có
    Thì hệ thống từ chối với ERR-12-018 (409)
    Và người dùng thấy thông báo "HTTT {mã} đã có danh tính truy cập."

  @US-12-030 @FR-12-030 @M @âm
  Kịch bản: US-12-030 âm 2 · Phương thức xác thực không đạt mức hợp đồng
    Biết HTTT ở PH-01 ở trạng thái đã duyệt; chưa có client cho `systemCode` đó; hợp đồng đã có mức phân loại cao nhất (D03-07 §4)
    Khi phương thức xác thực không đạt mức hợp đồng
    Thì hệ thống từ chối với ERR-12-022 (422)
    Và người dùng thấy thông báo "Hợp đồng mức {mức} cần xác thực bằng chứng thư mTLS hoặc khóa công khai, không dùng bí mật chia sẻ."

  @US-12-031 @FR-12-031 @M
  Kịch bản: US-12-031 dương · Quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi
    Biết client tồn tại; chuyển trạng thái hợp lệ theo mục 4.4
    Khi người dùng chọn thao tác ở UI-12-10; PH-01 gọi khi hủy kết nối; FR-12-008 tạm ngừng tự động
    Thì hệ thống trả `200`, client với `state` mới; `204` ở thu hồi
    Và trạng thái client cập nhật ở Keycloak, `ph12_iam`, danh sách chặn
    Và sự kiện được phát: EVT-12-07, EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-031 @FR-12-031 @M @âm
  Kịch bản: US-12-031 âm 1 · Chuyển trạng thái sai
    Biết client tồn tại; chuyển trạng thái hợp lệ theo mục 4.4
    Khi chuyển trạng thái sai
    Thì hệ thống từ chối với ERR-12-020 (409)
    Và người dùng thấy thông báo "Danh tính của HTTT đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-12-031 @FR-12-031 @M @âm
  Kịch bản: US-12-031 âm 2 · Thiếu lý do
    Biết client tồn tại; chuyển trạng thái hợp lệ theo mục 4.4
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-12-014 (400)
    Và người dùng thấy thông báo "Nhập lý do."

  @US-12-032 @FR-12-032 @S
  Kịch bản: US-12-032 dương · Cấp client cho ứng dụng nhà phát triển ở sandbox
    Biết nhà phát triển có tài khoản và ứng dụng ở PH-15; tenant bật sandbox
    Khi nhà phát triển bấm "Tạo thông tin xác thực" ở cổng PH-15
    Thì hệ thống trả `201`, client sandbox và tham chiếu bí mật bọc
    Và client sandbox `ENABLED`, hạn 180 ngày
    Và sự kiện được phát: EVT-12-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-032 @FR-12-032 @S @âm
  Kịch bản: US-12-032 âm 1 · Scope thật
    Biết nhà phát triển có tài khoản và ứng dụng ở PH-15; tenant bật sandbox
    Khi scope thật
    Thì hệ thống từ chối với ERR-12-019 (422)
    Và người dùng thấy thông báo "Ứng dụng sandbox chỉ nhận phạm vi thử nghiệm."

  @US-12-033 @FR-12-033 @M
  Kịch bản: US-12-033 dương · Đăng ký chứng thư mTLS và khóa công khai của client
    Biết client `ENABLED` hoặc `SUSPENDED`, có `authMethod` `TLS_CLIENT_AUTH` hoặc `PRIVATE_KEY_JWT`
    Khi TA bấm "Đăng ký chứng thư" hoặc "Đăng ký khóa công khai" ở UI-12-10; PH-01 gọi sau khi cấp chứng thư từ CA của HTTT
    Thì hệ thống trả `200`; danh sách chứng thư (dấu vân tay, hạn, trạng thái), `credentialReady`
    Và dấu vân tay có ở Keycloak và ở APISIX
    Và sự kiện được phát: EVT-12-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-033 @FR-12-033 @M @âm
  Kịch bản: US-12-033 âm 1 · Chứng thư hoặc khóa không hợp lệ
    Biết client `ENABLED` hoặc `SUSPENDED`, có `authMethod` `TLS_CLIENT_AUTH` hoặc `PRIVATE_KEY_JWT`
    Khi chứng thư hoặc khóa không hợp lệ
    Thì hệ thống từ chối với ERR-12-021 (422)
    Và người dùng thấy thông báo "Chứng thư không hợp lệ: {lý do: không tin cậy, hết hạn, thuật toán không được phép}."

  @US-12-033 @FR-12-033 @M @âm
  Kịch bản: US-12-033 âm 2 · Đã đủ 2 chứng thư
    Biết client `ENABLED` hoặc `SUSPENDED`, có `authMethod` `TLS_CLIENT_AUTH` hoặc `PRIVATE_KEY_JWT`
    Khi đã đủ 2 chứng thư
    Thì hệ thống từ chối với ERR-12-043 (422)
    Và người dùng thấy thông báo "Mỗi HTTT chỉ đăng ký tối đa 2 chứng thư cùng lúc. Gỡ chứng thư cũ trước."

  @US-12-034 @FR-12-034 @M
  Kịch bản: US-12-034 dương · Xoay bí mật client
    Biết client `ENABLED`, `authMethod=CLIENT_SECRET`; không có lần xoay đang chuyển tiếp
    Khi TA bấm "Xoay bí mật" ở UI-12-10; hoặc tới hạn 180 ngày; hoặc SO yêu cầu xoay khẩn
    Thì hệ thống trả `202`, tham chiếu bí mật bọc, thời điểm hết hiệu lực của bí mật cũ
    Và một bí mật hiệu lực; bí mật cũ hết hiệu lực khi hết chuyển tiếp
    Và sự kiện được phát: EVT-12-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-034 @FR-12-034 @M @âm
  Kịch bản: US-12-034 âm 1 · Đang chuyển tiếp
    Biết client `ENABLED`, `authMethod=CLIENT_SECRET`; không có lần xoay đang chuyển tiếp
    Khi đang chuyển tiếp
    Thì hệ thống từ chối với ERR-12-023 (409)
    Và người dùng thấy thông báo "Đang có lần xoay bí mật trong thời gian chuyển tiếp tới {thời điểm}."

  @US-12-034 @FR-12-034 @M @âm
  Kịch bản: US-12-034 âm 2 · Client không dùng bí mật chia sẻ
    Biết client `ENABLED`, `authMethod=CLIENT_SECRET`; không có lần xoay đang chuyển tiếp
    Khi client không dùng bí mật chia sẻ
    Thì hệ thống từ chối với ERR-12-022 (422)
    Và người dùng thấy thông báo "HTTT này không dùng bí mật chia sẻ."

  @US-12-035 @FR-12-035 @M
  Kịch bản: US-12-035 dương · Phát token cho HTTT bằng client_credentials
    Biết client `ENABLED`, `credentialReady=true`; realm `ACTIVE`
    Khi HTTT gửi yêu cầu tới điểm cuối `token` của realm tenant
    Thì hệ thống trả `200`: `access_token`, `token_type=Bearer`, `expires_in=300`, `scope`; lỗi theo RFC 6749
    Và sự kiện được phát: EVT-12-16 (không phát cho từng token nếu vượt ngưỡng lấy mẫu của `12.event.token-sample`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-035 @FR-12-035 @M @âm
  Kịch bản: US-12-035 âm 1 · Xác thực client sai
    Biết client `ENABLED`, `credentialReady=true`; realm `ACTIVE`
    Khi xác thực client sai
    Thì hệ thống từ chối với ERR-12-117

  @US-12-035 @FR-12-035 @M @âm
  Kịch bản: US-12-035 âm 2 · Client tạm ngừng hoặc thu hồi
    Biết client `ENABLED`, `credentialReady=true`; realm `ACTIVE`
    Khi client tạm ngừng hoặc thu hồi
    Thì hệ thống từ chối với ERR-12-118

  @US-12-036 @FR-12-036 @M
  Kịch bản: US-12-036 dương · Sinh scope của client từ dữ liệu đã duyệt
    Biết client tồn tại và không `REVOKED`
    Khi phân hệ nguồn gọi cập nhật tập scope khi một đăng ký sử dụng, mục đích, publication hay subscription được duyệt, đổi hoặc thu hồi
    Thì hệ thống trả `200`; tập scope hiện hành theo nguồn
    Và scope hiện hành lưu theo nguồn; gói chính sách yêu cầu tái sinh
    Và sự kiện được phát: EVT-12-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-036 @FR-12-036 @M @âm
  Kịch bản: US-12-036 âm 1 · Nguồn đặt loại scope không phải của mình
    Biết client tồn tại và không `REVOKED`
    Khi nguồn đặt loại scope không phải của mình
    Thì hệ thống từ chối với ERR-12-019 (422)
    Và người dùng thấy thông báo "Nguồn {nguồn} không được cấp phạm vi {scope}."

  @US-12-036 @FR-12-036 @M @âm
  Kịch bản: US-12-036 âm 2 · Client đã thu hồi
    Biết client tồn tại và không `REVOKED`
    Khi client đã thu hồi
    Thì hệ thống từ chối với ERR-12-020 (409)
    Và người dùng thấy thông báo "Danh tính của HTTT đã bị thu hồi."

  @US-12-037 @FR-12-037 @M
  Kịch bản: US-12-037 dương · Tài khoản dịch vụ nội bộ của đơn vị triển khai
    Biết DU đã được khai báo ở D03-01 §4; scope của tài khoản đã được phân hệ sở hữu định nghĩa (ví dụ `adapter:verify` của PH-05, `event:topic-register` của PH-10, `iam:*` của PH-12)
    Khi khởi tạo nền tảng hoặc thêm DU mới (qua yêu cầu thay đổi ở GitOps); xoay khóa theo lịch
    Thì hệ thống trả `201`; tài khoản dịch vụ với scope, hạn xoay khóa; không có khóa riêng trong phản hồi
    Và tài khoản dịch vụ ở Keycloak và `ph12_iam`; khóa riêng chỉ ở OpenBao hoặc pod sở hữu
    Và sự kiện được phát: EVT-12-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-037 @FR-12-037 @M @âm
  Kịch bản: US-12-037 âm 1 · Người duyệt trùng người khai báo
    Biết DU đã được khai báo ở D03-01 §4; scope của tài khoản đã được phân hệ sở hữu định nghĩa (ví dụ `adapter:verify` của PH-05, `event:topic-register` của PH-10, `iam:*` của PH-12)
    Khi người duyệt trùng người khai báo
    Thì hệ thống từ chối với ERR-12-008 (403)
    Và người dùng thấy thông báo "Anh/chị là người khai báo nên không được tự duyệt."

  @US-12-037 @FR-12-037 @M @âm
  Kịch bản: US-12-037 âm 2 · Scope không do phân hệ sở hữu định nghĩa
    Biết DU đã được khai báo ở D03-01 §4; scope của tài khoản đã được phân hệ sở hữu định nghĩa (ví dụ `adapter:verify` của PH-05, `event:topic-register` của PH-10, `iam:*` của PH-12)
    Khi scope không do phân hệ sở hữu định nghĩa
    Thì hệ thống từ chối với ERR-12-019 (422)
    Và người dùng thấy thông báo "Phạm vi {scope} chưa được phân hệ sở hữu đăng ký."

  @US-12-038 @FR-12-038 @M
  Kịch bản: US-12-038 dương · Vòng đời token: làm mới xoay vòng, phát hiện dùng lại
    Biết phiên SSO hiệu lực; BFF giữ refresh token của phiên
    Khi BFF làm mới token ở phút thứ 4 của access token 5 phút, hoặc khi một lời gọi trả `401` vì token hết hạn
    Thì hệ thống trả `200` với cặp token mới; lỗi `invalid_grant` khi dùng lại
    Và một refresh token hiệu lực cho mỗi phiên
    Và sự kiện được phát: EVT-12-16, EVT-12-14 (khi dùng lại)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-038 @FR-12-038 @M @âm
  Kịch bản: US-12-038 âm 1 · Refresh token đã dùng
    Biết phiên SSO hiệu lực; BFF giữ refresh token của phiên
    Khi refresh token đã dùng
    Thì hệ thống từ chối với ERR-12-115
    Và người dùng thấy thông báo "Phiên đăng nhập đã bị đóng vì lý do an toàn. Vui lòng đăng nhập lại."

  @US-12-038 @FR-12-038 @M @âm
  Kịch bản: US-12-038 âm 2 · Phiên hết hạn
    Biết phiên SSO hiệu lực; BFF giữ refresh token của phiên
    Khi phiên hết hạn
    Thì hệ thống từ chối với ERR-12-116 (401)
    Và người dùng thấy thông báo "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."

  @US-12-039 @FR-12-039 @M
  Kịch bản: US-12-039 dương · Công bố JWKS và xoay khóa ký 90 ngày
    Biết realm có khóa ký đang hoạt động (ES256 hoặc PS256)
    Khi lịch mỗi 90 ngày; hoặc lệnh xoay khẩn
    Thì tài liệu JWKS (`keys[]`, mỗi khóa có `kty`, `kid`, `alg`, `use`, `crv`, `x`, `y`); chỉ số `iam_key_age_days`
    Và một khóa ký đang hoạt động; khóa cũ biến mất sau 1 ngày
    Và sự kiện được phát: EVT-12-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-039 @FR-12-039 @M @âm
  Kịch bản: US-12-039 âm 1 · Keycloak không khả dụng
    Biết realm có khóa ký đang hoạt động (ES256 hoặc PS256)
    Khi Keycloak không khả dụng
    Thì APISIX tiếp tục dùng JWKS đệm tới khi đủ 24 giờ hoặc gặp `kid` lạ; token mới không phát được
    Và người dùng thấy thông báo "Keycloak không khả dụng"

  @US-12-039 @FR-12-039 @M @âm
  Kịch bản: US-12-039 âm 2 · `kid` lạ trong khi Keycloak không khả dụng
    Biết realm có khóa ký đang hoạt động (ES256 hoặc PS256)
    Khi `kid` lạ trong khi Keycloak không khả dụng
    Thì hệ thống từ chối với ERR-12-116

  @US-12-040 @FR-12-040 @M
  Kịch bản: US-12-040 dương · Thu hồi truy cập tức thời và phân phối danh sách chặn
    Biết đối tượng bị thu hồi (người dùng hoặc client) tồn tại trong tenant
    Khi người dùng bấm "Thu hồi truy cập" ở UI-12-02, UI-12-10; hoặc FR-12-005, 008, 024, 031 gọi
    Thì hệ thống trả `202`; `revocationId`, `appliedAt` ước lượng, số nút đã áp dụng
    Và mục danh sách chặn tồn tại tới khi hết hạn giữ; đối tượng bị vô hiệu hoặc tạm ngừng
    Và sự kiện được phát: EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-040 @FR-12-040 @M @âm
  Kịch bản: US-12-040 âm 1 · Thiếu lý do
    Biết đối tượng bị thu hồi (người dùng hoặc client) tồn tại trong tenant
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-12-014 (400)
    Và người dùng thấy thông báo "Nhập lý do thu hồi."

  @US-12-040 @FR-12-040 @M @âm
  Kịch bản: US-12-040 âm 2 · Tự thu hồi
    Biết đối tượng bị thu hồi (người dùng hoặc client) tồn tại trong tenant
    Khi tự thu hồi
    Thì hệ thống từ chối với ERR-12-013 (403)
    Và người dùng thấy thông báo "Anh/chị không thể tự thu hồi truy cập của mình."

  # ---- EP-12-E · Realm theo tenant

  @US-12-041 @FR-12-041 @M
  Kịch bản: US-12-041 dương · Khởi tạo realm của tenant từ mẫu
    Biết bản ghi tenant đã tạo (bước 1 của saga); mẫu realm `dh-realm-template` có ở kho cấu hình; chưa có realm cùng tên
    Khi PH-20 gọi API tạo realm kèm mã tenant
    Thì hệ thống trả `201`; `realmName`, `state`, `clients[]` (không có bí mật), `firstAdmin` (`userId`, `state`)
    Và realm `ACTIVE` ở `pg-iam`, giống mẫu bản `gitCommit`; bí mật client chỉ ở OpenBao
    Và sự kiện được phát: EVT-12-13, EVT-12-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-041 @FR-12-041 @M @âm
  Kịch bản: US-12-041 âm 1 · Realm đã có ở trạng thái khác `PROVISIONING`
    Biết bản ghi tenant đã tạo (bước 1 của saga); mẫu realm `dh-realm-template` có ở kho cấu hình; chưa có realm cùng tên
    Khi realm đã có ở trạng thái khác `PROVISIONING`
    Thì hệ thống từ chối với ERR-12-041 (409)
    Và người dùng thấy thông báo "Realm của tỉnh {mã} đã tồn tại."

  @US-12-041 @FR-12-041 @M @âm
  Kịch bản: US-12-041 âm 2 · Keycloak hoặc kho cấu hình không khả dụng
    Biết bản ghi tenant đã tạo (bước 1 của saga); mẫu realm `dh-realm-template` có ở kho cấu hình; chưa có realm cùng tên
    Khi Keycloak hoặc kho cấu hình không khả dụng
    Thì hệ thống từ chối với ERR-12-038, ERR-12-040 (503)

  @US-12-042 @FR-12-042 @M
  Kịch bản: US-12-042 dương · Cấu hình bảo mật realm bằng GitOps, phát hiện lệch
    Biết mọi realm được tạo từ mẫu (FR-12-041); Argo CD hoặc tác vụ áp cấu hình đang chạy
    Khi đồng hồ hằng giờ; hoặc PA bấm "Đối chiếu ngay" ở UI-12-19; hoặc yêu cầu hợp nhất thay đổi mẫu được duyệt
    Thì hệ thống trả `200` trạng thái lệch (`driftStatus`, danh sách trường lệch); `202` khi áp lại
    Và realm khớp mẫu; lịch sử áp dụng lưu ở Git và nhật ký
    Và sự kiện được phát: EVT-12-13, EVT-12-14 (khi lệch)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-042 @FR-12-042 @M @âm
  Kịch bản: US-12-042 âm 1 · Không xuất được cấu hình (Keycloak không phản hồi)
    Biết mọi realm được tạo từ mẫu (FR-12-041); Argo CD hoặc tác vụ áp cấu hình đang chạy
    Khi không xuất được cấu hình (Keycloak không phản hồi)
    Thì hệ thống từ chối với ERR-12-038 (503)

  @US-12-042 @FR-12-042 @M @âm
  Kịch bản: US-12-042 âm 2 · Áp lại khi realm đang bị khóa cấu hình bởi thao tác khác
    Biết mọi realm được tạo từ mẫu (FR-12-041); Argo CD hoặc tác vụ áp cấu hình đang chạy
    Khi áp lại khi realm đang bị khóa cấu hình bởi thao tác khác
    Thì hệ thống từ chối với ERR-12-042 (409)
    Và người dùng thấy thông báo "Realm đang được đối chiếu, thử lại sau."

  @US-12-043 @FR-12-043 @M
  Kịch bản: US-12-043 dương · Tạm ngừng, khôi phục, chuyển chỉ-đọc realm theo vòng đời tenant
    Biết realm tồn tại; chuyển trạng thái hợp lệ theo mục 4.7
    Khi PH-20 đổi trạng thái tenant (tạm ngừng, khôi phục, sáp nhập, chấm dứt)
    Thì hệ thống trả `200`; trạng thái realm, số phiên đã hủy, số mục danh sách chặn
    Và realm ở trạng thái đích; dữ liệu người dùng không bị xóa trừ khi `DELETED`
    Và sự kiện được phát: EVT-12-13, EVT-12-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-043 @FR-12-043 @M @âm
  Kịch bản: US-12-043 âm 1 · Chuyển trạng thái sai
    Biết realm tồn tại; chuyển trạng thái hợp lệ theo mục 4.7
    Khi chuyển trạng thái sai
    Thì hệ thống từ chối với ERR-12-041 (409)
    Và người dùng thấy thông báo "Realm đang ở trạng thái {trạng thái}, không chuyển sang {trạng thái đích} được."

  @US-12-043 @FR-12-043 @M @âm
  Kịch bản: US-12-043 âm 2 · Người dùng đăng nhập khi realm tạm ngừng
    Biết realm tồn tại; chuyển trạng thái hợp lệ theo mục 4.7
    Khi người dùng đăng nhập khi realm tạm ngừng
    Thì hệ thống từ chối với ERR-12-121, ERR-20-001 (403)
    Và người dùng thấy thông báo "Tỉnh {tên} đang tạm ngừng hoạt động."

  # ---- EP-12-F · Ủy quyền

  @US-12-044 @FR-12-044 @M
  Kịch bản: US-12-044 dương · Quyết định ủy quyền theo hợp đồng PEP và PDP
    Biết OPA đã nạp gói chính sách ký hợp lệ (ít nhất bản gói gốc của nền tảng và bản của tenant)
    Khi mỗi yêu cầu API hoặc thao tác nghiệp vụ cần kiểm tra quyền
    Thì hệ thống trả `200` với `{allow, reason, matchedPolicy, bundleRevision, fieldMask, privacyMode, obligations[], evaluationTimeMs}`; từ chối vẫn là `200` ở API quyết định
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-044 @FR-12-044 @M @âm
  Kịch bản: US-12-044 âm 1 · Thiếu trường bắt buộc
    Biết OPA đã nạp gói chính sách ký hợp lệ (ít nhất bản gói gốc của nền tảng và bản của tenant)
    Khi thiếu trường bắt buộc
    Thì hệ thống từ chối với ERR-12-101 (400)

  @US-12-044 @FR-12-044 @M @âm
  Kịch bản: US-12-044 âm 2 · Bên gọi quyết định qua API chưa xác thực hoặc thiếu scope
    Biết OPA đã nạp gói chính sách ký hợp lệ (ít nhất bản gói gốc của nền tảng và bản của tenant)
    Khi bên gọi quyết định qua API chưa xác thực hoặc thiếu scope
    Thì hệ thống từ chối với ERR-12-102 (401)

  @US-12-045 @FR-12-045 @M
  Kịch bản: US-12-045 dương · Quy tắc gốc: từ chối mặc định, từ chối thắng, cách ly tenant
    Biết gói gốc `base-authz` của nền tảng đã nạp; gói của tenant không được phép thay thế các luật `deny` của gói gốc
    Khi mỗi lần OPA đánh giá một yêu cầu (FR-12-044)
    Thì hệ thống trả `allow`, `reason` như FR-12-044
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-045 @FR-12-045 @M @âm
  Kịch bản: US-12-045 âm 1 · Luật Rego bị lỗi khi đánh giá
    Biết gói gốc `base-authz` của nền tảng đã nạp; gói của tenant không được phép thay thế các luật `deny` của gói gốc
    Khi luật Rego bị lỗi khi đánh giá
    Thì hệ thống từ chối với ERR-12-103 (500)

  @US-12-045 @FR-12-045 @M @âm
  Kịch bản: US-12-045 âm 2 · Gói tenant cố ghi đè một luật `deny` của gói gốc
    Biết gói gốc `base-authz` của nền tảng đã nạp; gói của tenant không được phép thay thế các luật `deny` của gói gốc
    Khi gói tenant cố ghi đè một luật `deny` của gói gốc
    Thì hệ thống từ chối với ERR-12-028

  @US-12-046 @FR-12-046 @M
  Kịch bản: US-12-046 dương · Phân quyền ba lớp: vai trò, phạm vi tổ chức, thuộc tính dữ liệu
    Biết dữ liệu gói gồm `role_perms`, `assignments`, `org_tree`, `client_scopes` (FR-12-051)
    Khi bước cho phép của FR-12-045
    Thì quyết định theo FR-12-044
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-046 @FR-12-046 @M @âm
  Kịch bản: US-12-046 âm 1 · Thiếu vai trò
    Biết dữ liệu gói gồm `role_perms`, `assignments`, `org_tree`, `client_scopes` (FR-12-051)
    Khi thiếu vai trò
    Thì từ chối `ROLE_MISSING`; người dùng thấy thông báo (`403`)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."

  @US-12-046 @FR-12-046 @M @âm
  Kịch bản: US-12-046 âm 2 · Ngoài phạm vi tổ chức
    Biết dữ liệu gói gồm `role_perms`, `assignments`, `org_tree`, `client_scopes` (FR-12-051)
    Khi ngoài phạm vi tổ chức
    Thì hệ thống trả `ORG_SCOPE_MISMATCH`; đối tượng của tổ chức khác trả `404` như không tồn tại (BR-12-041)

  @US-12-047 @FR-12-047 @M
  Kịch bản: US-12-047 dương · Tính mặt nạ trường và chế độ bảo vệ theo mục đích
    Biết thực thể trả về đã khai báo tập trường và mức phân loại từng trường (ở PH-07, PH-02 hoặc PH-09 từ Đợt 2)
    Khi quyết định cho phép của FR-12-044 với hành động `read`, `export`
    Thì hệ thống trả `fieldMask`, `privacyMode` trong quyết định
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-047 @FR-12-047 @M @âm
  Kịch bản: US-12-047 âm 1 · Thực thể chưa khai báo
    Biết thực thể trả về đã khai báo tập trường và mức phân loại từng trường (ở PH-07, PH-02 hoặc PH-09 từ Đợt 2)
    Khi thực thể chưa khai báo
    Thì hệ thống trả `fieldMask` rỗng, cảnh báo `ENTITY_FIELDS_UNDECLARED`; API trả `403` với thông báo khi yêu cầu cần trường
    Và người dùng thấy thông báo "Dữ liệu này chưa được khai báo cách chia sẻ. Liên hệ quản trị."

  @US-12-047 @FR-12-047 @M @âm
  Kịch bản: US-12-047 âm 2 · Mục đích thiếu với dữ liệu mức Hạn chế
    Biết thực thể trả về đã khai báo tập trường và mức phân loại từng trường (ở PH-07, PH-02 hoặc PH-09 từ Đợt 2)
    Khi mục đích thiếu với dữ liệu mức Hạn chế
    Thì hệ thống trả `PURPOSE_NOT_DECLARED` (từ FR-12-045)

  @US-12-048 @FR-12-048 @M
  Kịch bản: US-12-048 dương · Bộ chuyển đổi XACML 3.0
    Biết gói chính sách đã nạp; bảng ánh xạ thuộc tính XACML sang `input` đã cấu hình
    Khi bên gọi gửi yêu cầu tới `POST /api/authz/v1/xacml` với `Content-Type: application/xacml+xml` hoặc `application/xacml+json`
    Thì hệ thống trả `200` với phản hồi XACML hợp lệ: `Decision` ∈ {`Permit`, `Deny`, `NotApplicable`, `Indeterminate`}, `Status`, `Obligations`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-048 @FR-12-048 @M @âm
  Kịch bản: US-12-048 âm 1 · Yêu cầu sai lược đồ
    Biết gói chính sách đã nạp; bảng ánh xạ thuộc tính XACML sang `input` đã cấu hình
    Khi yêu cầu sai lược đồ
    Thì hệ thống từ chối với ERR-12-123 (400)

  @US-12-048 @FR-12-048 @M @âm
  Kịch bản: US-12-048 âm 2 · Thiếu thuộc tính bắt buộc
    Biết gói chính sách đã nạp; bảng ánh xạ thuộc tính XACML sang `input` đã cấu hình
    Khi thiếu thuộc tính bắt buộc
    Thì phản hồi `Indeterminate` kèm `missing-attribute`

  @US-12-049 @FR-12-049 @S
  Kịch bản: US-12-049 dương · Quyết định theo lô
    Biết như FR-12-044
    Khi PEP cần quyết định cho nhiều đối tượng cùng chủ thể, cùng hành động
    Thì hệ thống trả `200`, `results[]` (`itemId`, `allow`, `reason`, `fieldMask`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-049 @FR-12-049 @S @âm
  Kịch bản: US-12-049 âm 1 · Lô quá 100 phần tử
    Biết như FR-12-044
    Khi lô quá 100 phần tử
    Thì hệ thống từ chối với ERR-12-101 (400)

  @US-12-050 @FR-12-050 @S
  Kịch bản: US-12-050 dương · Bộ đệm quyết định
    Biết tham số `12.cache.ttl-seconds` lớn hơn 0 (mặc định 60)
    Khi mỗi lần PEP cần quyết định
    Thì quyết định lấy từ đệm hoặc từ OPA

  @US-12-050 @FR-12-050 @S @âm
  Kịch bản: US-12-050 âm 1 · Đệm trả quyết định của gói cũ
    Biết tham số `12.cache.ttl-seconds` lớn hơn 0 (mặc định 60)
    Khi đệm trả quyết định của gói cũ
    Thì không thể, vì khóa chứa `bundleRevision`

  @US-12-051 @FR-12-051 @M
  Kịch bản: US-12-051 dương · Sinh dữ liệu vai trò–quyền cho OPA từ ma trận D02-08
    Biết ma trận D02-08 đã chuyển thành tệp dữ liệu `permissions` ở kho `dh-policies` qua CI; khóa ký gói có ở OpenBao
    Khi sự kiện thay đổi dữ liệu nguồn (gán vai trò, quyền có thời hạn, đơn vị, scope client, tenant đổi trạng thái); hoặc đồng hồ 30 giây; hoặc đổi ma trận D02-08
    Thì hệ thống trả `202` khi kích hoạt tay (`POST /policy-data:regenerate`); thông tin gói hiện hành ở UI-12-12
    Và gói dữ liệu mới có chữ ký ở kho; OPA nạp thành công
    Và sự kiện được phát: EVT-12-09 khi gói dữ liệu mới hiệu lực
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-051 @FR-12-051 @M @âm
  Kịch bản: US-12-051 âm 1 · Dữ liệu nguồn không nhất quán
    Biết ma trận D02-08 đã chuyển thành tệp dữ liệu `permissions` ở kho `dh-policies` qua CI; khóa ký gói có ở OpenBao
    Khi dữ liệu nguồn không nhất quán
    Thì hệ thống từ chối với ERR-12-040 (503)
    Và người dùng thấy thông báo "Gói dữ liệu của tỉnh chưa cập nhật từ {thời điểm}: {lý do}."

  @US-12-051 @FR-12-051 @M @âm
  Kịch bản: US-12-051 âm 2 · OpenBao không ký được
    Biết ma trận D02-08 đã chuyển thành tệp dữ liệu `permissions` ở kho `dh-policies` qua CI; khóa ký gói có ở OpenBao
    Khi OpenBao không ký được
    Thì hệ thống từ chối với ERR-12-039 (503)

  @US-12-052 @FR-12-052 @M
  Kịch bản: US-12-052 dương · Soạn và kiểm thử chính sách
    Biết kho chính sách `dh-policies` (nền tảng) hoặc kho của tenant (ADR-068) hoạt động; người soạn đã xác thực mức 3 trong 5 phút khi lưu phiên bản
    Khi người soạn bấm "+ Chính sách" hoặc "Phiên bản mới" ở UI-12-12
    Thì hệ thống trả `201` hoặc `200`, phiên bản với `state=DRAFT`, `contentHash`, kết quả kiểm tra, độ phủ
    Và phiên bản lưu ở Git và `ph12_iam`; chưa ảnh hưởng đến OPA nào
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-052 @FR-12-052 @M @âm
  Kịch bản: US-12-052 âm 1 · Sai cú pháp
    Biết kho chính sách `dh-policies` (nền tảng) hoặc kho của tenant (ADR-068) hoạt động; người soạn đã xác thực mức 3 trong 5 phút khi lưu phiên bản
    Khi sai cú pháp
    Thì hệ thống từ chối với ERR-12-024 (422)
    Và người dùng thấy thông báo "Chính sách sai cú pháp ở dòng {n}: {thông báo}."

  @US-12-052 @FR-12-052 @M @âm
  Kịch bản: US-12-052 âm 2 · Ca kiểm thử không đạt hoặc thiếu
    Biết kho chính sách `dh-policies` (nền tảng) hoặc kho của tenant (ADR-068) hoạt động; người soạn đã xác thực mức 3 trong 5 phút khi lưu phiên bản
    Khi ca kiểm thử không đạt hoặc thiếu
    Thì hệ thống từ chối với ERR-12-025 (409)
    Và người dùng thấy thông báo "Còn {n} ca kiểm thử không đạt hoặc chưa có ca âm."

  @US-12-053 @FR-12-053 @M
  Kịch bản: US-12-053 dương · Chạy khô chính sách trên lưu lượng thật
    Biết phiên bản `DRAFT` đã qua kiểm thử (FR-12-052); nhật ký quyết định có đủ yêu cầu của cửa sổ chạy khô
    Khi người soạn bấm "Chạy khô" ở UI-12-13
    Thì hệ thống trả `202` khi bắt đầu; `200` với báo cáo (`total`, `changed`, `changedRatio`, `allowToDeny`, `denyToAllow`, `groups[]`, `examples[]`)
    Và báo cáo lưu 12 tháng; không thay đổi OPA nào đang chạy
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-053 @FR-12-053 @M @âm
  Kịch bản: US-12-053 âm 1 · Chưa đủ mẫu (dưới 100 yêu cầu)
    Biết phiên bản `DRAFT` đã qua kiểm thử (FR-12-052); nhật ký quyết định có đủ yêu cầu của cửa sổ chạy khô
    Khi chưa đủ mẫu (dưới 100 yêu cầu)
    Thì kết quả báo thông báo, vẫn cho gửi duyệt nhưng ghi dấu; không phải lỗi
    Và người dùng thấy thông báo "Mẫu quá ít để đánh giá tác động"

  @US-12-053 @FR-12-053 @M @âm
  Kịch bản: US-12-053 âm 2 · Nhật ký quyết định không đọc được
    Biết phiên bản `DRAFT` đã qua kiểm thử (FR-12-052); nhật ký quyết định có đủ yêu cầu của cửa sổ chạy khô
    Khi nhật ký quyết định không đọc được
    Thì hệ thống từ chối với ERR-12-040 (503)
    Và người dùng thấy thông báo "Chưa lấy được lưu lượng mẫu. Thử lại sau."

  @US-12-054 @FR-12-054 @M
  Kịch bản: US-12-054 dương · Duyệt bốn mắt và phát hành gói chính sách ký
    Biết phiên bản `DRAFT` có kiểm thử đạt và chạy khô trên đúng `contentHash` (BR-12-009); người duyệt đã xác thực mức 3 trong 5 phút
    Khi người soạn bấm "Gửi duyệt"; người duyệt mở yêu cầu ở "Việc của tôi" (UI-12-17)
    Thì hệ thống trả `200` với `state`, `bundleRevision`, số nút đã nạp
    Và một phiên bản `PUBLISHED` cho mỗi mã chính sách; bộ đệm quyết định cũ không còn khớp
    Và sự kiện được phát: EVT-12-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-054 @FR-12-054 @M @âm
  Kịch bản: US-12-054 âm 1 · Người duyệt trùng người soạn, gửi hay đóng góp
    Biết phiên bản `DRAFT` có kiểm thử đạt và chạy khô trên đúng `contentHash` (BR-12-009); người duyệt đã xác thực mức 3 trong 5 phút
    Khi người duyệt trùng người soạn, gửi hay đóng góp
    Thì hệ thống từ chối với ERR-12-008 (403)
    Và người dùng thấy thông báo "Anh/chị là người soạn hoặc người đóng góp chính sách này nên không được duyệt."

  @US-12-054 @FR-12-054 @M @âm
  Kịch bản: US-12-054 âm 2 · Thiếu xác nhận khi tác động lớn
    Biết phiên bản `DRAFT` có kiểm thử đạt và chạy khô trên đúng `contentHash` (BR-12-009); người duyệt đã xác thực mức 3 trong 5 phút
    Khi thiếu xác nhận khi tác động lớn
    Thì hệ thống từ chối với ERR-12-029 (409)
    Và người dùng thấy thông báo "Thay đổi này đổi {tỷ lệ}% quyết định. Tích xác nhận và nhập ý kiến để tiếp tục."

  @US-12-055 @FR-12-055 @M
  Kịch bản: US-12-055 dương · Thu hồi và quay lui chính sách
    Biết có phiên bản `PUBLISHED` cần thu hồi hoặc có gói trước đó ở kho; người thực hiện xác thực mức 3 trong 5 phút
    Khi SO bấm "Thu hồi" ở một phiên bản hoặc "Quay lui gói" ở UI-12-12; hoặc cảnh báo tự động đề xuất khi gói mới gây lỗi
    Thì hệ thống trả `200`, `bundleRevision` hiện hành, danh sách phiên bản đang `PUBLISHED`
    Và một gói hiện hành; phiên bản bị thu hồi không còn trong gói
    Và sự kiện được phát: EVT-12-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-055 @FR-12-055 @M @âm
  Kịch bản: US-12-055 âm 1 · Thu hồi chính sách gốc
    Biết có phiên bản `PUBLISHED` cần thu hồi hoặc có gói trước đó ở kho; người thực hiện xác thực mức 3 trong 5 phút
    Khi thu hồi chính sách gốc
    Thì hệ thống từ chối với ERR-12-027 (409)
    Và người dùng thấy thông báo "Không thu hồi được chính sách gốc. Hãy quay lui về gói trước."

  @US-12-055 @FR-12-055 @M @âm
  Kịch bản: US-12-055 âm 2 · Gói đích không còn ở kho hoặc chữ ký sai
    Biết có phiên bản `PUBLISHED` cần thu hồi hoặc có gói trước đó ở kho; người thực hiện xác thực mức 3 trong 5 phút
    Khi gói đích không còn ở kho hoặc chữ ký sai
    Thì hệ thống từ chối với ERR-12-024 (422)
    Và người dùng thấy thông báo "Gói đích không hợp lệ."

  # ---- EP-12-G · Ghi vết và giám sát

  @US-12-056 @FR-12-056 @M
  Kịch bản: US-12-056 dương · Ghi vết sự kiện xác thực và quản trị định danh
    Biết bộ nghe sự kiện của Keycloak và bộ ghi outbox của `dh-platform` đã bật
    Khi mỗi sự kiện xác thực hoặc thao tác quản trị định danh
    Thì bản ghi kiểm toán; chỉ số `iam_login_total{result,method}`, `iam_token_issued_total`
    Và bản ghi nằm ở kho log an ninh và chuỗi kiểm toán PH-13
    Và sự kiện được phát: EVT-12-16

  @US-12-056 @FR-12-056 @M @âm
  Kịch bản: US-12-056 âm 1 · Không gửi được tới Kafka
    Biết bộ nghe sự kiện của Keycloak và bộ ghi outbox của `dh-platform` đã bật
    Khi không gửi được tới Kafka
    Thì bộ nghe đệm vào hàng đợi bền trên đĩa tối đa 24 giờ và gửi lại; hàng đợi đầy thì cảnh báo nghiêm trọng, không chặn đăng nhập

  @US-12-056 @FR-12-056 @M @âm
  Kịch bản: US-12-056 âm 2 · Thao tác quản trị không ghi được kiểm toán (outbox lỗi)
    Biết bộ nghe sự kiện của Keycloak và bộ ghi outbox của `dh-platform` đã bật
    Khi thao tác quản trị không ghi được kiểm toán (outbox lỗi)
    Thì hệ thống từ chối với ERR-12-040
    Và người dùng thấy thông báo "Chưa ghi được nhật ký nên thao tác chưa thực hiện. Thử lại sau."

  @US-12-057 @FR-12-057 @M
  Kịch bản: US-12-057 dương · Ghi vết quyết định ủy quyền
    Biết phần ghi quyết định (decision log) của OPA bật; bộ thu OTel Collector có bộ lọc che dữ liệu
    Khi mỗi quyết định của OPA
    Thì bản ghi quyết định ở Loki và chuỗi kiểm toán; chỉ số `iam_decisions_total{result,policy}`, `iam_decision_duration_seconds`
    Và bản ghi không chứa dữ liệu cá nhân dạng rõ

  @US-12-057 @FR-12-057 @M @âm
  Kịch bản: US-12-057 âm 1 · Không ghi được vết với tài nguyên Nhạy cảm
    Biết phần ghi quyết định (decision log) của OPA bật; bộ thu OTel Collector có bộ lọc che dữ liệu
    Khi không ghi được vết với tài nguyên Nhạy cảm
    Thì hệ thống từ chối với ERR-12-124 (403)
    Và người dùng thấy thông báo "Hệ thống chưa ghi được vết truy cập nên không phục vụ dữ liệu này. Thử lại sau."

  @US-12-057 @FR-12-057 @M @âm
  Kịch bản: US-12-057 âm 2 · Bộ lọc che dữ liệu phát hiện giá trị trường Nhạy cảm
    Biết phần ghi quyết định (decision log) của OPA bật; bộ thu OTel Collector có bộ lọc che dữ liệu
    Khi bộ lọc che dữ liệu phát hiện giá trị trường Nhạy cảm
    Thì bản ghi bị che hoặc loại, cảnh báo cấu hình

  @US-12-058 @FR-12-058 @M
  Kịch bản: US-12-058 dương · Tra cứu nhật ký quyết định
    Biết người dùng đã chọn tenant làm việc; nhật ký quyết định có dữ liệu trong khoảng tra
    Khi người dùng mở "Nhật ký quyết định" ở UI-12-14
    Thì hệ thống trả `200`; `items[]` (thời điểm, chủ thể, tài nguyên, hành động, kết quả, chính sách, lý do, thời gian đánh giá), `page`, `size`, `totalElements`, `denyRatioSeries`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-058 @FR-12-058 @M @âm
  Kịch bản: US-12-058 âm 1 · Khoảng thời gian quá dài
    Biết người dùng đã chọn tenant làm việc; nhật ký quyết định có dữ liệu trong khoảng tra
    Khi khoảng thời gian quá dài
    Thì hệ thống từ chối với ERR-12-003 (400)
    Và người dùng thấy thông báo "Chỉ tra được tối đa 31 ngày mỗi lần."

  @US-12-058 @FR-12-058 @M @âm
  Kịch bản: US-12-058 âm 2 · Không có quyền
    Biết người dùng đã chọn tenant làm việc; nhật ký quyết định có dữ liệu trong khoảng tra
    Khi không có quyền
    Thì hệ thống từ chối với ERR-12-007 (403)

  @US-12-059 @FR-12-059 @S
  Kịch bản: US-12-059 dương · Phát hiện hành vi bất thường và cảnh báo
    Biết nhật ký xác thực và quyết định đã đổ vào Loki; kênh thông báo của SO đã cấu hình (FR-00-061)
    Khi đánh giá định kỳ mỗi phút trên cửa sổ thời gian của từng quy tắc; hoặc sự kiện tức thì
    Thì cảnh báo (`alertId`, `rule`, `severity`, đối tượng, số liệu, thời điểm), trạng thái `OPEN`, `ACKNOWLEDGED`
    Và cảnh báo lưu cùng trạng thái xác nhận
    Và sự kiện được phát: EVT-12-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-059 @FR-12-059 @S @âm
  Kịch bản: US-12-059 âm 1 · Không gửi được thông báo
    Biết nhật ký xác thực và quyết định đã đổ vào Loki; kênh thông báo của SO đã cấu hình (FR-00-061)
    Khi không gửi được thông báo
    Thì cảnh báo vẫn hiện ở UI-12-15 và chuyển PH-13; ghi cảnh báo thông báo
    Và người dùng thấy thông báo "Không gửi được thông báo"

  @US-12-060 @FR-12-060 @S
  Kịch bản: US-12-060 dương · Báo cáo tình trạng tài khoản và xác thực hai yếu tố
    Biết bản chiếu người dùng, client đã đồng bộ
    Khi báo cáo tự động chạy hằng ngày lúc 06:00; người dùng mở "Báo cáo tài khoản" ở UI-12-15 hoặc gọi API
    Thì hệ thống trả `200`; `byState`, `mfaCoverage` (`required`, `registered`, `ratio`, `missing[]`), `inactive[]`, `privileged[]`, `clientsAtRisk[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-060 @FR-12-060 @S @âm
  Kịch bản: US-12-060 âm 1 · Bản chiếu chưa đồng bộ kịp
    Biết bản chiếu người dùng, client đã đồng bộ
    Khi bản chiếu chưa đồng bộ kịp
    Thì báo cáo hiển thị thời điểm dữ liệu thông báo
    Và người dùng thấy thông báo "tính đến {thời điểm}"

  # ---- EP-12-H · Quản trị

  @US-12-061 @FR-12-061 @M
  Kịch bản: US-12-061 dương · Tham số phân hệ theo tenant
    Biết PH-18 cung cấp kho tham số theo tenant; khóa `12.*` đã khai báo ở mục 8.2
    Khi TA mở "Cài đặt Định danh" ở UI-12-16
    Thì hệ thống trả `200`; danh sách tham số hiện hành
    Và giá trị lưu theo tenant
    Và sự kiện được phát: EVT-12-13 khi đổi tham số bảo mật của realm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-12-061 @FR-12-061 @M @âm
  Kịch bản: US-12-061 âm 1 · Vượt trần hoặc yếu hơn mức bắt buộc
    Biết PH-18 cung cấp kho tham số theo tenant; khóa `12.*` đã khai báo ở mục 8.2
    Khi vượt trần hoặc yếu hơn mức bắt buộc
    Thì hệ thống từ chối với ERR-12-043 (422)
    Và người dùng thấy thông báo "Giá trị vượt giới hạn cho phép ({tối thiểu} đến {tối đa})."

  @US-12-061 @FR-12-061 @M @âm
  Kịch bản: US-12-061 âm 2 · Phiên bản đã đổi
    Biết PH-18 cung cấp kho tham số theo tenant; khóa `12.*` đã khai báo ở mục 8.2
    Khi phiên bản đã đổi
    Thì hệ thống từ chối với ERR-12-044 (412)
    Và người dùng thấy thông báo "Giá trị vừa được người khác sửa. Tải lại."

  @US-12-062 @FR-12-062 @M
  Kịch bản: US-12-062 dương · Tra cứu danh bạ người dùng cho phân hệ khác
    Biết bên gọi có token dịch vụ hợp lệ; tenant của lời gọi lấy từ token
    Khi phân hệ cần hiển thị thông tin người dùng theo mã
    Thì hệ thống trả `200`; `users[]` (`userId`, `displayName`, `orgCode`, `orgName`, `title`, `state`)

  @US-12-062 @FR-12-062 @M @âm
  Kịch bản: US-12-062 âm 1 · Mã không có hoặc thuộc tenant khác
    Biết bên gọi có token dịch vụ hợp lệ; tenant của lời gọi lấy từ token
    Khi mã không có hoặc thuộc tenant khác
    Thì bỏ khỏi kết quả (không báo lỗi, không tiết lộ sự tồn tại, BR-12-041)

  @US-12-062 @FR-12-062 @M @âm
  Kịch bản: US-12-062 âm 2 · Quá 100 mã
    Biết bên gọi có token dịch vụ hợp lệ; tenant của lời gọi lấy từ token
    Khi quá 100 mã
    Thì hệ thống từ chối với ERR-12-003 (400)
