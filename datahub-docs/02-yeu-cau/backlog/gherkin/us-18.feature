# language: vi
# Sinh tự động từ D02-02/D02-03-PH18 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-18
Tính năng: PH-18 · Vận hành và xử lý lỗi

  # ---- EP-18-A · Kho tham số và cờ tính năng

  @US-18-001 @FR-18-001 @M
  Kịch bản: US-18-001 dương · Đăng ký không gian tên và lược đồ khóa tham số
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi DU khởi động và gửi lược đồ của không gian tên; hoặc PA mở UI-18-08 xem lược đồ
    Thì hệ thống trả `200` với `ns`, `schemaVersion`, `added[]`, `changed[]`, `deprecated[]`
    Và lược đồ mới có hiệu lực cho mọi lần đọc và ghi sau đó; giá trị tenant không bị đổi
    Và sự kiện được phát: EVT-18-01 (loại `SCHEMA_CHANGED`, chỉ khi có khóa thêm hoặc đổi)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-001 @FR-18-001 @M @âm
  Kịch bản: US-18-001 âm 1 · Không gian tên không thuộc phân hệ gọi
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi không gian tên không thuộc phân hệ gọi
    Thì hệ thống từ chối với ERR-18-017 (403)
    Và người dùng thấy thông báo "Phân hệ {ph} không sở hữu không gian tên {ns}."

  @US-18-001 @FR-18-001 @M @âm
  Kịch bản: US-18-001 âm 2 · Đổi lược đồ làm giá trị tenant ra ngoài miền
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi đổi lược đồ làm giá trị tenant ra ngoài miền
    Thì hệ thống từ chối với ERR-18-016 (409)
    Và người dùng thấy thông báo "Lược đồ mới của {ns} xung đột với giá trị đang dùng ở {số} tenant. Xem danh sách trong chi tiết."

  @US-18-002 @FR-18-002 @M
  Kịch bản: US-18-002 dương · Đọc tham số có bộ đệm cho phân hệ khác
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi bộ đệm phía DU hết hạn (`18.param.cache-ttl-seconds`, mặc định 60 giây), hoặc DU nhận EVT-18-01 của không gian tên mình
    Thì hệ thống trả `200` với `values[]` (`key`, `value`, `version`, `source`), `unknown[]`, tiêu đề `ETag`; hoặc `304`

  @US-18-002 @FR-18-002 @M @âm
  Kịch bản: US-18-002 âm 1 · Tenant không tồn tại hoặc đã `DECOMMISSIONED`
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi tenant không tồn tại hoặc đã `DECOMMISSIONED`
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy tenant {mã}."

  @US-18-002 @FR-18-002 @M @âm
  Kịch bản: US-18-002 âm 2 · Quá giới hạn tần suất (> 50 yêu cầu mỗi giây mỗi DU)
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi quá giới hạn tần suất (> 50 yêu cầu mỗi giây mỗi DU)
    Thì hệ thống từ chối với ERR-18-010 (429)
    Và người dùng thấy thông báo "Quá nhiều yêu cầu. Thử lại sau {giây} giây."

  @US-18-003 @FR-18-003 @M
  Kịch bản: US-18-003 dương · Ghi giá trị tham số theo tenant có kiểm miền, trần và lý do
    Biết khóa đã đăng ký và không `DEPRECATED` (FR-18-001)
    Khi người dùng sửa giá trị ở UI-18-08 hoặc ở màn tham số nhúng của phân hệ rồi bấm "Lưu"
    Thì hệ thống trả `200` với `key`, `value`, `version`, `status` (`ACTIVE` hoặc `PENDING_APPROVAL`), `ETag`
    Và một phiên bản mới `ACTIVE` (hoặc `PENDING_APPROVAL` cho khóa ★); không xóa phiên bản cũ
    Và sự kiện được phát: EVT-18-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-003 @FR-18-003 @M @âm
  Kịch bản: US-18-003 âm 1 · Giá trị ngoài miền
    Biết khóa đã đăng ký và không `DEPRECATED` (FR-18-001)
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-18-013 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} nằm ngoài miền cho phép của {khóa}: {miền}."

  @US-18-003 @FR-18-003 @M @âm
  Kịch bản: US-18-003 âm 2 · Vượt trần nền tảng
    Biết khóa đã đăng ký và không `DEPRECATED` (FR-18-001)
    Khi vượt trần nền tảng
    Thì hệ thống từ chối với ERR-18-014 (422)
    Và người dùng thấy thông báo "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng."

  @US-18-004 @FR-18-004 @M
  Kịch bản: US-18-004 dương · Duyệt bốn mắt tham số bảo mật ★
    Biết khóa có `secure = true` và `approvalOwner = PH-18`; chưa có đề nghị khác chờ duyệt cho cùng khóa và tenant
    Khi FR-18-003 bước 4 gặp khóa ★; người duyệt mở việc "Duyệt tham số" trong Việc của tôi
    Thì đề nghị: `202` với `requestId`, `status = PENDING_APPROVAL`
    Và mỗi khóa và tenant có tối đa một đề nghị `PENDING_APPROVAL`
    Và sự kiện được phát: EVT-18-02 khi tạo đề nghị; EVT-18-01 khi duyệt
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-004 @FR-18-004 @M @âm
  Kịch bản: US-18-004 âm 1 · Đã có đề nghị chờ duyệt
    Biết khóa có `secure = true` và `approvalOwner = PH-18`; chưa có đề nghị khác chờ duyệt cho cùng khóa và tenant
    Khi đã có đề nghị chờ duyệt
    Thì hệ thống từ chối với ERR-18-018 (409)
    Và người dùng thấy thông báo "Tham số {khóa} đang có đề nghị chờ duyệt của {người}. Chờ duyệt xong hoặc rút đề nghị."

  @US-18-004 @FR-18-004 @M @âm
  Kịch bản: US-18-004 âm 2 · Người duyệt trùng người đề nghị
    Biết khóa có `secure = true` và `approvalOwner = PH-18`; chưa có đề nghị khác chờ duyệt cho cùng khóa và tenant
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-18-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị nên không được duyệt đề nghị này."

  @US-18-005 @FR-18-005 @M
  Kịch bản: US-18-005 dương · Xem lịch sử, so sánh và khôi phục phiên bản tham số
    Biết khóa có ít nhất một phiên bản theo tenant
    Khi người dùng mở tab "Lịch sử" của một khóa ở UI-18-09, chọn hai phiên bản để so sánh hoặc bấm "Khôi phục phiên bản này"
    Thì lịch sử: `200` với `items[]` phân trang
    Và khôi phục tạo phiên bản mới, không xóa phiên bản trung gian
    Và sự kiện được phát: EVT-18-01 khi khôi phục
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-005 @FR-18-005 @M @âm
  Kịch bản: US-18-005 âm 1 · Giá trị cũ không còn hợp lệ với lược đồ mới
    Biết khóa có ít nhất một phiên bản theo tenant
    Khi giá trị cũ không còn hợp lệ với lược đồ mới
    Thì hệ thống từ chối với ERR-18-023 (409)
    Và người dùng thấy thông báo "Phiên bản {số} không còn hợp lệ với lược đồ hiện hành của {khóa}: {lý do}."

  @US-18-005 @FR-18-005 @M @âm
  Kịch bản: US-18-005 âm 2 · Không tìm thấy phiên bản
    Biết khóa có ít nhất một phiên bản theo tenant
    Khi không tìm thấy phiên bản
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {số} của {khóa}."

  @US-18-006 @FR-18-006 @M
  Kịch bản: US-18-006 dương · Phát sự kiện đổi tham số và làm mới bộ đệm
    Biết có phiên bản mới `ACTIVE`, lược đồ đổi, cờ tính năng hoặc egress đổi
    Khi giao dịch ghi ở FR-18-001, 003, 004, 005, 008, 009, 010, 011 commit
    Thì sự kiện trên topic `{tenant}.ops.param.changed.v1`
    Và bản ghi outbox đánh dấu đã phát
    Và sự kiện được phát: EVT-18-01; EVT-18-03; EVT-18-04

  @US-18-006 @FR-18-006 @M @âm
  Kịch bản: US-18-006 âm 1 · Không phát được sau 5 phút
    Biết có phiên bản mới `ACTIVE`, lược đồ đổi, cờ tính năng hoặc egress đổi
    Khi không phát được sau 5 phút
    Thì hệ thống từ chối với ERR-18-124
    Và người dùng thấy thông báo "Sự kiện đổi tham số đang chậm {phút} phút."

  @US-18-007 @FR-18-007 @M
  Kịch bản: US-18-007 dương · Màn tham số chung nhúng theo không gian tên và nhóm
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi người dùng mở `/van-hanh/tham-so?ns=07.rdm.&nhom=nhap-lo`, hoặc màn của phân hệ nhúng thành phần tham số chung
    Thì hệ thống trả `200` danh sách nhóm và khóa; lưu như FR-18-003
    Và như FR-18-003
    Và sự kiện được phát: EVT-18-01 (qua FR-18-003)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-007 @FR-18-007 @M @âm
  Kịch bản: US-18-007 âm 1 · Một số khóa lưu lỗi
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi một số khóa lưu lỗi
    Thì mỗi khóa lỗi hiện mã và câu riêng, các khóa khác vẫn lưu; thanh đầu trang thông báo
    Và người dùng thấy thông báo "Đã lưu {n} tham số, {m} tham số lỗi."

  @US-18-007 @FR-18-007 @M @âm
  Kịch bản: US-18-007 âm 2 · PH-18 ở chế độ chỉ đọc
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi PH-18 ở chế độ chỉ đọc
    Thì hệ thống từ chối với ERR-18-071 (503)
    Và người dùng thấy thông báo "Phân hệ vận hành đang ở chế độ chỉ đọc. Thay đổi tham số tạm thời không thực hiện được."

  @US-18-008 @FR-18-008 @C
  Kịch bản: US-18-008 dương · Xuất, nhập gói tham số giữa môi trường
    Biết lược đồ ở môi trường đích đã đăng ký cùng hoặc mới hơn `schemaVersion` của gói
    Khi PA bấm "Xuất gói" hoặc "Nhập gói" ở UI-18-08 tab "Gói tham số"
    Thì xuất: `201` với `bundleId`, liên kết tải
    Và gói lưu 90 ngày; mỗi khóa áp có phiên bản mới
    Và sự kiện được phát: EVT-18-01 (qua FR-18-003); EVT-18-02 khi có khóa ★
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-008 @FR-18-008 @C @âm
  Kịch bản: US-18-008 âm 1 · Gói hỏng hoặc khác tổng kiểm tra
    Biết lược đồ ở môi trường đích đã đăng ký cùng hoặc mới hơn `schemaVersion` của gói
    Khi gói hỏng hoặc khác tổng kiểm tra
    Thì hệ thống từ chối với ERR-18-020 (422)
    Và người dùng thấy thông báo "Gói tham số không hợp lệ hoặc đã bị sửa: {chi tiết}."

  @US-18-009 @FR-18-009 @M
  Kịch bản: US-18-009 dương · Quản lý cờ tính năng theo tenant
    Biết cờ được khai báo trước khi mã dùng nó được triển khai
    Khi PA bấm "+ Cờ tính năng" ở UI-18-10; TA bật công tắc; tác vụ hằng ngày kiểm ngày gỡ
    Thì hệ thống trả `201` cờ mới; `200` khi bật tắt, kèm `ETag`
    Và cờ có trạng thái `ACTIVE` hoặc `RETIRED`; giá trị theo tenant có phiên bản
    Và sự kiện được phát: EVT-18-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-009 @FR-18-009 @M @âm
  Kịch bản: US-18-009 âm 1 · Thiếu chủ sở hữu hoặc ngày gỡ
    Biết cờ được khai báo trước khi mã dùng nó được triển khai
    Khi thiếu chủ sở hữu hoặc ngày gỡ
    Thì hệ thống từ chối với ERR-18-021 (422)
    Và người dùng thấy thông báo "Cờ tính năng cần chủ sở hữu và ngày gỡ dự kiến trong vòng 365 ngày."

  @US-18-009 @FR-18-009 @M @âm
  Kịch bản: US-18-009 âm 2 · Khóa cờ đã có
    Biết cờ được khai báo trước khi mã dùng nó được triển khai
    Khi khóa cờ đã có
    Thì hệ thống từ chối với ERR-18-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-18-010 @FR-18-010 @S
  Kịch bản: US-18-010 dương · Quản lý danh sách egress cho phép theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi TA bấm "+ Đích egress" ở UI-18-10 tab "Egress"
    Thì hệ thống trả `201` mục mới; `204` khi gỡ
    Và danh sách hiệu lực đọc được qua `params:batch-get` với khóa `18.egress.allowlist`
    Và sự kiện được phát: EVT-18-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-010 @FR-18-010 @S @âm
  Kịch bản: US-18-010 âm 1 · Đích nội bộ, IP hoặc không HTTPS
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi đích nội bộ, IP hoặc không HTTPS
    Thì hệ thống từ chối với ERR-18-022 (422)
    Và người dùng thấy thông báo "Đích {đích} không được phép: chỉ chấp nhận tên miền công khai qua HTTPS."

  @US-18-011 @FR-18-011 @M
  Kịch bản: US-18-011 dương · Ghi tham số mặc định khi khởi tạo tenant
    Biết tenant có trong registry PH-20 với trạng thái `PROVISIONING` hoặc `ACTIVE`
    Khi PH-20 gọi API seed trong bước khởi tạo; hoặc PH-18 tiêu thụ `platform.tenant.created.v1`
    Thì hệ thống trả `200` với `added`, `kept`, `namespaces[]`
    Và mỗi khóa của tenant có ít nhất mặc định; chạy lại không đổi gì
    Và sự kiện được phát: EVT-18-01; EVT-18-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-011 @FR-18-011 @M @âm
  Kịch bản: US-18-011 âm 1 · PH-18 không sẵn sàng
    Biết tenant có trong registry PH-20 với trạng thái `PROVISIONING` hoặc `ACTIVE`
    Khi PH-18 không sẵn sàng
    Thì hệ thống từ chối với ERR-18-071
    Và người dùng thấy thông báo "Chưa ghi được tham số mặc định. Hệ thống sẽ thử lại."

  @US-18-011 @FR-18-011 @M @âm
  Kịch bản: US-18-011 âm 2 · Registry PH-20 không phản hồi khi PH-18 tự chạy từ sự kiện
    Biết tenant có trong registry PH-20 với trạng thái `PROVISIONING` hoặc `ACTIVE`
    Khi registry PH-20 không phản hồi khi PH-18 tự chạy từ sự kiện
    Thì hệ thống từ chối với ERR-18-124

  # ---- EP-18-B · Tiếp nhận DLQ

  @US-18-012 @FR-18-012 @M
  Kịch bản: US-18-012 dương · Đăng ký nguồn DLQ và cổng phát lại
    Biết phân hệ nguồn có danh tính SPIFFE; với cổng `HTTP_PORT` thì đường dẫn nằm trong `/…/internal/v1` của DU nguồn
    Khi DU nguồn khởi động và gửi thông tin nguồn; hoặc PA bấm "+ Nguồn" ở UI-18-06 tab "Nguồn"
    Thì hệ thống trả `200` với `sourceCode`, `replayMode`, `status`, `ETag`
    Và một `dlq_source` `ACTIVE` hoặc `SUSPENDED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-012 @FR-18-012 @M @âm
  Kịch bản: US-18-012 âm 1 · Danh tính gọi không khớp phân hệ nguồn
    Biết phân hệ nguồn có danh tính SPIFFE; với cổng `HTTP_PORT` thì đường dẫn nằm trong `/…/internal/v1` của DU nguồn
    Khi danh tính gọi không khớp phân hệ nguồn
    Thì hệ thống từ chối với ERR-18-026 (403)
    Và người dùng thấy thông báo "Nguồn {mã} không được đăng ký bởi {danh tính}."

  @US-18-012 @FR-18-012 @M @âm
  Kịch bản: US-18-012 âm 2 · Cổng phát lại không hợp lệ
    Biết phân hệ nguồn có danh tính SPIFFE; với cổng `HTTP_PORT` thì đường dẫn nằm trong `/…/internal/v1` của DU nguồn
    Khi cổng phát lại không hợp lệ
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: cổng phát lại {cổng}."

  @US-18-013 @FR-18-013 @M
  Kịch bản: US-18-013 dương · Tiêu thụ topic DLQ và lập chỉ mục bền
    Biết topic `{tenant}.ops.dlq.v1` đã được PH-10 cấp theo GitOps với PH-18 là chủ, ACL ghi cho `dh-runtime-{tenant}` và ACL đọc cho PH-18
    Khi có bản tin mới trên topic
    Thì người vận hành thấy mục lỗi mới trên UI-18-01 trong ≤ 5 giây sau khi runtime ghi
    Và mỗi bản ghi đã commit offset có đúng một mục DLQ (hoặc tăng đếm lần gặp của mục trùng)
    Và sự kiện được phát: EVT-18-05; EVT-18-06 khi `POISON`

  @US-18-013 @FR-18-013 @M @âm
  Kịch bản: US-18-013 âm 1 · Không giải mã được bản ghi
    Biết topic `{tenant}.ops.dlq.v1` đã được PH-10 cấp theo GitOps với PH-18 là chủ, ACL ghi cho `dh-runtime-{tenant}` và ACL đọc cho PH-18
    Khi không giải mã được bản ghi
    Thì hệ thống từ chối với ERR-18-101
    Và người dùng thấy thông báo "Bản tin không đọc được định dạng. Xem nội dung thô để chẩn đoán."

  @US-18-013 @FR-18-013 @M @âm
  Kịch bản: US-18-013 âm 2 · Tenant trong header không khớp topic
    Biết topic `{tenant}.ops.dlq.v1` đã được PH-10 cấp theo GitOps với PH-18 là chủ, ACL ghi cho `dh-runtime-{tenant}` và ACL đọc cho PH-18
    Khi tenant trong header không khớp topic
    Thì hệ thống từ chối với ERR-18-103
    Và người dùng thấy thông báo "Có bản tin lỗi mang tenant {mã} trên topic của tenant khác."

  @US-18-014 @FR-18-014 @M
  Kịch bản: US-18-014 dương · Nhận mục DLQ qua API ghi cho phân hệ khác
    Biết nguồn đã đăng ký (FR-18-012) và `ACTIVE` hoặc đang đăng ký ngầm
    Khi phân hệ nguồn chuyển một bản tin sang trạng thái lỗi cuối cùng (hết số lần thử)
    Thì hệ thống trả `201` với `dlqId`, `duplicate`; lô: `207` với kết quả từng mục
    Và mục `NEW` trong chỉ mục; nguồn có thể đánh dấu bản tin của mình là "đã chuyển DLQ"
    Và sự kiện được phát: EVT-18-05

  @US-18-014 @FR-18-014 @M @âm
  Kịch bản: US-18-014 âm 1 · Thiếu trường ngữ cảnh
    Biết nguồn đã đăng ký (FR-18-012) và `ACTIVE` hoặc đang đăng ký ngầm
    Khi thiếu trường ngữ cảnh
    Thì hệ thống từ chối với ERR-18-024 (422)
    Và người dùng thấy thông báo "Thiếu trường ngữ cảnh bắt buộc của DLQ: {danh sách trường}."

  @US-18-014 @FR-18-014 @M @âm
  Kịch bản: US-18-014 âm 2 · Payload vượt giới hạn
    Biết nguồn đã đăng ký (FR-18-012) và `ACTIVE` hoặc đang đăng ký ngầm
    Khi payload vượt giới hạn
    Thì hệ thống từ chối với ERR-18-025 (413)
    Và người dùng thấy thông báo "Nội dung bản tin vượt {MB} MB. Lưu nội dung ở nguồn và gửi tham chiếu."

  @US-18-015 @FR-18-015 @M
  Kịch bản: US-18-015 dương · Kiểm hợp đồng ngữ cảnh và đánh dấu POISON
    Biết bản ghi đã đọc được (FR-18-013) hoặc đã qua kiểm trường của API (FR-18-014)
    Khi bước 2 của FR-18-013 hoặc bước 3 của FR-18-014
    Thì mục có `status`, `errorClass`, `missingFields[]`
    Và mục `POISON` chỉ chuyển được sang `DISCARDED` hoặc `TRIAGED` qua bản sửa được duyệt (FR-18-024)
    Và sự kiện được phát: EVT-18-06; EVT-18-08

  @US-18-015 @FR-18-015 @M @âm
  Kịch bản: US-18-015 âm 1 · Thiếu ngữ cảnh bắt buộc
    Biết bản ghi đã đọc được (FR-18-013) hoặc đã qua kiểm trường của API (FR-18-014)
    Khi thiếu ngữ cảnh bắt buộc
    Thì hệ thống từ chối với ERR-18-102
    Và người dùng thấy thông báo "Bản tin thiếu ngữ cảnh {danh sách trường} nên không phát lại được. Sửa bản tin hoặc bỏ qua."

  @US-18-016 @FR-18-016 @M
  Kịch bản: US-18-016 dương · Lưu payload lớn ở Garage và khử trùng theo khóa DLQ
    Biết bucket `dh-{tenant}-ops` tồn tại trên Garage, mã hóa phía máy khách bằng khóa tenant
    Khi bước 2 của FR-18-013 hoặc bước 3 của FR-18-014
    Thì hệ thống trả `dlq_payload_ref` với `storage` (`INLINE`, `GARAGE`), `sizeBytes`, `sha256`
    Và mỗi `dlqKey` chưa đóng có đúng một mục

  @US-18-016 @FR-18-016 @M @âm
  Kịch bản: US-18-016 âm 1 · Garage không ghi được
    Biết bucket `dh-{tenant}-ops` tồn tại trên Garage, mã hóa phía máy khách bằng khóa tenant
    Khi Garage không ghi được
    Thì hệ thống từ chối với ERR-18-104
    Và người dùng thấy thông báo "Kho đối tượng của DLQ không ghi được. Bản tin lỗi đang được giữ trong hàng đợi."

  @US-18-017 @FR-18-017 @M
  Kịch bản: US-18-017 dương · Liên thông DLQ tầng sự kiện của PH-10
    Biết PH-10 cấp scope cho `svc-ops`; nguồn `ph10-event` đăng ký với `replayMode = EVENT_LAYER`
    Khi người dùng mở tab "Tầng sự kiện" ở UI-18-01; hoặc PH-18 nhận EVT-10-11 và cập nhật bộ đếm
    Thì hệ thống trả `200` danh sách siêu dữ liệu; đề nghị phát lại `202` với `replayCode` của PH-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-017 @FR-18-017 @M @âm
  Kịch bản: US-18-017 âm 1 · PH-10 không phản hồi
    Biết PH-10 cấp scope cho `svc-ops`; nguồn `ph10-event` đăng ký với `replayMode = EVENT_LAYER`
    Khi PH-10 không phản hồi
    Thì hệ thống từ chối với ERR-18-035 (503)
    Và người dùng thấy thông báo "Chưa lấy được DLQ tầng sự kiện từ phân hệ sự kiện. Dữ liệu DLQ khác vẫn đầy đủ."

  @US-18-018 @FR-18-018 @S
  Kịch bản: US-18-018 dương · Đối soát chỉ mục DLQ với Kafka
    Biết topic DLQ giữ dữ liệu 14 ngày (ADR-181, NFR-18-016; cấu hình topic của PH-10)
    Khi lịch hằng ngày 02:30; hoặc TO bấm "Đối soát ngay" ở UI-18-06
    Thì hệ thống trả `202` khi chạy tay với `runId`; `200` kết quả gần nhất
    Và chỉ mục khớp topic trong khoảng đã đối soát
    Và sự kiện được phát: EVT-18-08 loại `RECONCILE_MISSING` khi số thiếu > 0
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-018 @FR-18-018 @S @âm
  Kịch bản: US-18-018 âm 1 · Không đọc được topic
    Biết topic DLQ giữ dữ liệu 14 ngày (ADR-181, NFR-18-016; cấu hình topic của PH-10)
    Khi không đọc được topic
    Thì hệ thống từ chối với ERR-18-124
    Và người dùng thấy thông báo "Lần đối soát {thời điểm} không đọc được topic DLQ. Lần sau sẽ chạy lại."

  # ---- EP-18-C · Phân loại và xử lý

  @US-18-019 @FR-18-019 @M
  Kịch bản: US-18-019 dương · Liệt kê, lọc và tìm mục DLQ
    Biết người dùng đã chọn tenant làm việc
    Khi người dùng mở `/van-hanh/dlq` hoặc bấm số đếm DLQ ở thẻ trang chủ, màn của PH-04, PH-10
    Thì hệ thống trả `200` với `items[]`, `page`, `size`, `totalElements`, `facets`; xuất: `200` `text/csv`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-019 @FR-18-019 @M @âm
  Kịch bản: US-18-019 âm 1 · Bộ lọc sai
    Biết người dùng đã chọn tenant làm việc
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: bộ lọc {tên}."

  @US-18-019 @FR-18-019 @M @âm
  Kịch bản: US-18-019 âm 2 · Xuất vượt 50.000 dòng
    Biết người dùng đã chọn tenant làm việc
    Khi xuất vượt 50.000 dòng
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Kết quả lọc có {n} dòng, vượt giới hạn xuất 50.000. Thu hẹp bộ lọc."

  @US-18-020 @FR-18-020 @C
  Kịch bản: US-18-020 dương · Gom nhóm mục DLQ theo dấu hiệu lỗi
    Biết có mục chưa đóng
    Khi người dùng mở tab "Theo nhóm lỗi" ở UI-18-02; tác vụ gom chạy mỗi phút
    Thì hệ thống trả `200` với `groups[]`; gán `200`
    Và mục mới luôn thuộc đúng một nhóm trong cửa sổ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-020 @FR-18-020 @C @âm
  Kịch bản: US-18-020 âm 1 · Nhóm không còn mục chưa đóng
    Biết có mục chưa đóng
    Khi nhóm không còn mục chưa đóng
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Nhóm {mã} không còn mục cần xử lý."

  @US-18-021 @FR-18-021 @M
  Kịch bản: US-18-021 dương · Xem chi tiết mục DLQ và ngữ cảnh chẩn đoán
    Biết mục thuộc tenant hiện hành và người dùng được xem theo lọc quyền
    Khi người dùng bấm một dòng ở UI-18-01
    Thì hệ thống trả `200` chi tiết mục; `200` chẩn đoán hoặc `206` khi một phần
    Và mục `NEW` không đổi trạng thái chỉ vì được mở; hệ thống ghi `firstViewedAt`

  @US-18-021 @FR-18-021 @M @âm
  Kịch bản: US-18-021 âm 1 · Không tìm thấy mục
    Biết mục thuộc tenant hiện hành và người dùng được xem theo lọc quyền
    Khi không tìm thấy mục
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy mục DLQ {mã}."

  @US-18-021 @FR-18-021 @M @âm
  Kịch bản: US-18-021 âm 2 · PH-13 quá thời gian
    Biết mục thuộc tenant hiện hành và người dùng được xem theo lọc quyền
    Khi PH-13 quá thời gian
    Thì hệ thống từ chối với ERR-18-106
    Và người dùng thấy thông báo "Chưa lấy được ngữ cảnh chẩn đoán từ giám sát. Thử lại sau."

  @US-18-022 @FR-18-022 @M
  Kịch bản: US-18-022 dương · Xem payload có lý do
    Biết mục chưa `EXPIRED`; payload còn trong chỉ mục hoặc Garage
    Khi người dùng bấm "Xem nội dung" ở UI-18-03
    Thì hệ thống trả `200` với `content`, `contentType`, `maskedFields[]`, `revealExpiresAt`
    Và một bản ghi kiểm toán "xem payload"
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-022 @FR-18-022 @M @âm
  Kịch bản: US-18-022 âm 1 · Thiếu lý do
    Biết mục chưa `EXPIRED`; payload còn trong chỉ mục hoặc Garage
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-18-007 (422)
    Và người dùng thấy thông báo "Nhập lý do xem nội dung (ít nhất 10 ký tự)."

  @US-18-022 @FR-18-022 @M @âm
  Kịch bản: US-18-022 âm 2 · Payload đã xóa do hết hạn lưu giữ
    Biết mục chưa `EXPIRED`; payload còn trong chỉ mục hoặc Garage
    Khi payload đã xóa do hết hạn lưu giữ
    Thì hệ thống từ chối với ERR-18-027 (409)
    Và người dùng thấy thông báo "Nội dung bản tin đã bị xóa do hết hạn lưu giữ. Chỉ còn thông tin mô tả."

  @US-18-023 @FR-18-023 @M
  Kịch bản: US-18-023 dương · Phân loại, ưu tiên và gán người xử lý
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi người dùng bấm "Phân loại" hoặc "Gán" ở UI-18-03; chọn nhiều mục ở UI-18-01
    Thì hệ thống trả `200` mục cập nhật kèm `ETag`; hàng loạt `207`
    Và mục `TRIAGED` có lớp lỗi, ưu tiên, người xử lý
    Và sự kiện được phát: EVT-18-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-023 @FR-18-023 @M @âm
  Kịch bản: US-18-023 âm 1 · Trạng thái không cho phép
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi trạng thái không cho phép
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Mục DLQ đang ở trạng thái {trạng thái} nên không thể phân loại."

  @US-18-023 @FR-18-023 @M @âm
  Kịch bản: US-18-023 âm 2 · Người được gán không có `PERM-18-dlq`
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi người được gán không có `PERM-18-dlq`
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Người {tên} không có quyền xử lý DLQ."

  @US-18-024 @FR-18-024 @M
  Kịch bản: US-18-024 dương · Sửa payload có kiểm soát
    Biết mục ở `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`; nguồn có `supportsRevision = true`; người dùng đã có phiếu xem payload còn hạn (FR-18-022)
    Khi người dùng bấm "Sửa nội dung" ở UI-18-03, mở UI-18-04
    Thì hệ thống trả `201` với `revisionNo`, `status`, `diff[]`; duyệt `200`
    Và bản gốc không đổi; mục có thêm một bản sửa
    Và sự kiện được phát: EVT-18-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-024 @FR-18-024 @M @âm
  Kịch bản: US-18-024 âm 1 · Bản sửa sai lược đồ
    Biết mục ở `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`; nguồn có `supportsRevision = true`; người dùng đã có phiếu xem payload còn hạn (FR-18-022)
    Khi bản sửa sai lược đồ
    Thì hệ thống từ chối với ERR-18-029 (422)
    Và người dùng thấy thông báo "Nội dung sửa không đúng lược đồ {lược đồ}: {chi tiết}."

  @US-18-024 @FR-18-024 @M @âm
  Kịch bản: US-18-024 âm 2 · Đã có bản sửa chờ duyệt
    Biết mục ở `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`; nguồn có `supportsRevision = true`; người dùng đã có phiếu xem payload còn hạn (FR-18-022)
    Khi đã có bản sửa chờ duyệt
    Thì hệ thống từ chối với ERR-18-030 (409)
    Và người dùng thấy thông báo "Mục đã có bản sửa số {n} chờ duyệt. Chờ duyệt xong trước khi sửa tiếp."

  @US-18-025 @FR-18-025 @S
  Kịch bản: US-18-025 dương · Quản lý sổ tay xử lý theo mã lỗi
    Biết mã lỗi có định nghĩa ở chương 9 của FRS phân hệ chủ
    Khi PA mở UI-18-07; tác vụ nạp ban đầu từ danh mục mã lỗi của các phân hệ
    Thì hệ thống trả `200` hướng dẫn với `version`, `ETag`
    Và hướng dẫn mới có hiệu lực cho mục mở sau đó
    Và sự kiện được phát: EVT-18-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-025 @FR-18-025 @S @âm
  Kịch bản: US-18-025 âm 1 · Nội dung bị lọc
    Biết mã lỗi có định nghĩa ở chương 9 của FRS phân hệ chủ
    Khi nội dung bị lọc
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: nội dung hướng dẫn chứa {loại} không được phép."

  @US-18-026 @FR-18-026 @S
  Kịch bản: US-18-026 dương · Cung cấp API đọc DLQ cho PH-17 và PH-13
    Biết token mang người dùng có `PERM-18-dlq` trong tenant
    Khi người dùng bấm "Giải thích lỗi này"; PH-17 gọi công cụ `view_dlq_message`
    Thì hệ thống trả `200` siêu dữ liệu; payload hoặc khung theo quyền
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-026 @FR-18-026 @S @âm
  Kịch bản: US-18-026 âm 1 · Người dùng không có quyền
    Biết token mang người dùng có `PERM-18-dlq` trong tenant
    Khi người dùng không có quyền
    Thì hệ thống từ chối với ERR-00-403 (403)
    Và người dùng thấy thông báo "Bạn không có quyền xem bản tin lỗi này."

  # ---- EP-18-D · Phát lại, bỏ qua và lưu giữ

  @US-18-027 @FR-18-027 @M
  Kịch bản: US-18-027 dương · Phát lại một mục DLQ
    Biết mục ở `NEW`, `TRIAGED` hoặc `REPLAY_FAILED`; nguồn `ACTIVE` có cổng phát lại khác `NONE`; không trong lượt phát lại khác
    Khi người dùng bấm "Phát lại" ở UI-18-03 và xác nhận
    Thì hệ thống trả `202` với `dlqId`, `status = REPLAYING`, `idempotencyKey`
    Và mục ở `REPLAYING` cho tới khi có kết quả hoặc quá hạn
    Và sự kiện được phát: EVT-18-09; EVT-18-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-027 @FR-18-027 @M @âm
  Kịch bản: US-18-027 âm 1 · Mục `POISON`
    Biết mục ở `NEW`, `TRIAGED` hoặc `REPLAY_FAILED`; nguồn `ACTIVE` có cổng phát lại khác `NONE`; không trong lượt phát lại khác
    Khi mục `POISON`
    Thì hệ thống từ chối với ERR-18-028 (409)
    Và người dùng thấy thông báo "Bản tin thiếu ngữ cảnh nên không phát lại được. Sửa nội dung hoặc bỏ qua."

  @US-18-027 @FR-18-027 @M @âm
  Kịch bản: US-18-027 âm 2 · Mục đang trong lượt khác
    Biết mục ở `NEW`, `TRIAGED` hoặc `REPLAY_FAILED`; nguồn `ACTIVE` có cổng phát lại khác `NONE`; không trong lượt phát lại khác
    Khi mục đang trong lượt khác
    Thì hệ thống từ chối với ERR-18-031 (409)
    Và người dùng thấy thông báo "Mục đang được phát lại trong lượt {mã}."

  @US-18-028 @FR-18-028 @M
  Kịch bản: US-18-028 dương · Phát lại loạt theo bộ lọc hoặc danh sách
    Biết bộ lọc hoặc danh sách cho ra ít nhất một mục phát lại được
    Khi người dùng chọn nhiều mục ở UI-18-01, bấm "Phát lại nhóm" ở UI-18-02, hoặc "Tạo lượt phát lại" ở UI-18-05
    Thì hệ thống trả `201` với `jobId`, `status`, `total`, `excluded[]`; gửi `200`; duyệt `200`
    Và mục trong lượt ở `REPLAY_PENDING` khi lượt `APPROVED`
    Và sự kiện được phát: EVT-18-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-028 @FR-18-028 @M @âm
  Kịch bản: US-18-028 âm 1 · Bộ lọc không có mục
    Biết bộ lọc hoặc danh sách cho ra ít nhất một mục phát lại được
    Khi bộ lọc không có mục
    Thì hệ thống từ chối với ERR-18-036 (422)
    Và người dùng thấy thông báo "Không có mục nào phù hợp để phát lại."

  @US-18-028 @FR-18-028 @M @âm
  Kịch bản: US-18-028 âm 2 · Vượt số mục tối đa
    Biết bộ lọc hoặc danh sách cho ra ít nhất một mục phát lại được
    Khi vượt số mục tối đa
    Thì hệ thống từ chối với ERR-18-032 (422)
    Và người dùng thấy thông báo "Lượt có {n} mục, vượt giới hạn {tối đa}. Thu hẹp bộ lọc hoặc chia thành nhiều lượt."

  @US-18-029 @FR-18-029 @M
  Kịch bản: US-18-029 dương · Điều khiển lượt phát lại: tốc độ, tạm dừng, tiếp tục, hủy
    Biết lượt ở `APPROVED`, `RUNNING` hoặc `PAUSED`
    Khi lượt được duyệt; người dùng bấm "Tạm dừng", "Tiếp tục", "Hủy" hoặc đổi tốc độ ở UI-18-05
    Thì hệ thống trả `200` lượt với trạng thái, tiến độ, `ETag`
    Và sự kiện được phát: EVT-18-10; EVT-18-08; EVT-18-09 cho từng mục
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-029 @FR-18-029 @M @âm
  Kịch bản: US-18-029 âm 1 · Lượt không ở trạng thái điều khiển được
    Biết lượt ở `APPROVED`, `RUNNING` hoặc `PAUSED`
    Khi lượt không ở trạng thái điều khiển được
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Lượt phát lại đang ở trạng thái {trạng thái} nên không thể {thao tác}."

  @US-18-029 @FR-18-029 @M @âm
  Kịch bản: US-18-029 âm 2 · Tốc độ vượt trần của nguồn
    Biết lượt ở `APPROVED`, `RUNNING` hoặc `PAUSED`
    Khi tốc độ vượt trần của nguồn
    Thì hệ thống từ chối với ERR-18-037 (422)
    Và người dùng thấy thông báo "Tốc độ {n} mục mỗi giây vượt giới hạn {trần} của nguồn {mã}."

  @US-18-030 @FR-18-030 @M
  Kịch bản: US-18-030 dương · Nhận kết quả phát lại và bảo đảm lũy đẳng
    Biết mục ở `REPLAYING` với `idempotencyKey` đã gửi
    Khi nguồn gọi callback; hoặc PH-18 nhận EVT-10-12; hoặc hết `18.dlq.replay.result-timeout-minutes`
    Thì hệ thống trả `200` với trạng thái mới của mục
    Và mỗi khóa lũy đẳng có tối đa một kết quả cuối
    Và sự kiện được phát: EVT-18-07; EVT-18-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-030 @FR-18-030 @M @âm
  Kịch bản: US-18-030 âm 1 · Callback từ nguồn khác
    Biết mục ở `REPLAYING` với `idempotencyKey` đã gửi
    Khi callback từ nguồn khác
    Thì hệ thống từ chối với ERR-18-038 (403)
    Và người dùng thấy thông báo "Có kết quả phát lại từ danh tính {danh tính} không khớp nguồn của mục {mã}."

  @US-18-030 @FR-18-030 @M @âm
  Kịch bản: US-18-030 âm 2 · Quá hạn chờ kết quả
    Biết mục ở `REPLAYING` với `idempotencyKey` đã gửi
    Khi quá hạn chờ kết quả
    Thì hệ thống từ chối với ERR-18-109
    Và người dùng thấy thông báo "Chưa nhận kết quả phát lại sau {phút} phút. Kiểm tra phân hệ nguồn."

  @US-18-031 @FR-18-031 @M
  Kịch bản: US-18-031 dương · Bỏ qua mục DLQ có lý do
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi người dùng bấm "Bỏ qua" ở UI-18-03 hoặc chọn nhiều mục ở UI-18-01
    Thì hệ thống trả `200` mục; hàng loạt `207`
    Và mục `DISCARDED` giữ payload tới hết hạn lưu giữ
    Và sự kiện được phát: EVT-18-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-031 @FR-18-031 @M @âm
  Kịch bản: US-18-031 âm 1 · Lý do thiếu hoặc ngắn
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi lý do thiếu hoặc ngắn
    Thì hệ thống từ chối với ERR-18-007 (422)
    Và người dùng thấy thông báo "Nhập lý do bỏ qua (ít nhất 10 ký tự)."

  @US-18-031 @FR-18-031 @M @âm
  Kịch bản: US-18-031 âm 2 · Trạng thái không cho phép
    Biết mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`
    Khi trạng thái không cho phép
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Mục DLQ đang ở trạng thái {trạng thái} nên không thể bỏ qua."

  @US-18-032 @FR-18-032 @S
  Kịch bản: US-18-032 dương · Mở lại mục đã bỏ qua
    Biết mục `DISCARDED`, chưa `EXPIRED`
    Khi người dùng bấm "Mở lại" ở UI-18-03
    Thì hệ thống trả `200` mục với trạng thái `TRIAGED`
    Và mục `TRIAGED`
    Và sự kiện được phát: EVT-18-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-032 @FR-18-032 @S @âm
  Kịch bản: US-18-032 âm 1 · Mục đã hết hạn lưu giữ
    Biết mục `DISCARDED`, chưa `EXPIRED`
    Khi mục đã hết hạn lưu giữ
    Thì hệ thống từ chối với ERR-18-034 (409)
    Và người dùng thấy thông báo "Mục đã hết hạn lưu giữ nên không thể mở lại."

  @US-18-033 @FR-18-033 @M
  Kịch bản: US-18-033 dương · Lưu giữ và dọn mục DLQ
    Biết có mục `RESOLVED` hoặc `DISCARDED` quá `18.dlq.retention.closed-days` (mặc định 90 ngày)
    Khi tác vụ 03:00 hằng ngày (ShedLock, một bản chạy)
    Thì kết quả dọn hiện ở UI-18-06
    Và mục `EXPIRED` chỉ còn siêu dữ liệu
    Và sự kiện được phát: EVT-18-08 loại `AGE` cho mục mở quá lâu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-033 @FR-18-033 @M @âm
  Kịch bản: US-18-033 âm 1 · Garage xóa lỗi
    Biết có mục `RESOLVED` hoặc `DISCARDED` quá `18.dlq.retention.closed-days` (mặc định 90 ngày)
    Khi Garage xóa lỗi
    Thì hệ thống từ chối với ERR-18-104
    Và người dùng thấy thông báo "Còn {n} nội dung DLQ quá hạn chưa xóa được."

  @US-18-034 @FR-18-034 @M
  Kịch bản: US-18-034 dương · Thống kê DLQ, chỉ số và sự kiện vượt ngưỡng
    Biết người dùng đã đăng nhập với vai trò người xem
    Khi người dùng mở UI-18-06; tác vụ ngưỡng chạy mỗi phút
    Thì hệ thống trả `200` thống kê; chỉ số ở `/actuator/prometheus`
    Và sự kiện được phát: EVT-18-08

  @US-18-034 @FR-18-034 @M @âm
  Kịch bản: US-18-034 âm 1 · Khoảng không hợp lệ
    Biết người dùng đã đăng nhập với vai trò người xem
    Khi khoảng không hợp lệ
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: khoảng thời gian {giá trị}."

  # ---- EP-18-E · Thông báo

  @US-18-035 @FR-18-035 @M
  Kịch bản: US-18-035 dương · Quản lý mẫu thông báo có phiên bản và kiểm trường cấm
    Biết phân hệ chủ đã khai báo biến của loại thông báo kèm mức phân loại của từng biến
    Khi người dùng mở UI-18-11, bấm "+ Mẫu" hoặc sửa mẫu ở UI-18-12
    Thì hệ thống trả `201` mẫu hoặc phiên bản; xem thử `200` với nội dung đã dựng; duyệt `200`
    Và mỗi mẫu và kênh có tối đa một phiên bản `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-035 @FR-18-035 @M @âm
  Kịch bản: US-18-035 âm 1 · Mẫu dùng trường cấm
    Biết phân hệ chủ đã khai báo biến của loại thông báo kèm mức phân loại của từng biến
    Khi mẫu dùng trường cấm
    Thì hệ thống từ chối với ERR-18-039 (422)
    Và người dùng thấy thông báo "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."

  @US-18-035 @FR-18-035 @M @âm
  Kịch bản: US-18-035 âm 2 · Cú pháp sai hoặc biến chưa khai báo
    Biết phân hệ chủ đã khai báo biến của loại thông báo kèm mức phân loại của từng biến
    Khi cú pháp sai hoặc biến chưa khai báo
    Thì hệ thống từ chối với ERR-18-040 (422)
    Và người dùng thấy thông báo "Mẫu có lỗi tại dòng {dòng}: {chi tiết}."

  @US-18-036 @FR-18-036 @M
  Kịch bản: US-18-036 dương · Gửi thông báo qua NotificationApi
    Biết loại thông báo có mẫu `ACTIVE` cho kênh (tenant hoặc `COMMON`)
    Khi phân hệ gọi API; quy tắc sự kiện sinh thông báo (FR-18-039)
    Thì hệ thống trả `202` với `messageId`, `status = QUEUED`; đồng bộ `200` với `status`
    Và một `notification_message` và các `notification_delivery`
    Và sự kiện được phát: EVT-18-13 khi thất bại cuối cùng

  @US-18-036 @FR-18-036 @M @âm
  Kịch bản: US-18-036 âm 1 · Không có mẫu đang dùng
    Biết loại thông báo có mẫu `ACTIVE` cho kênh (tenant hoặc `COMMON`)
    Khi không có mẫu đang dùng
    Thì hệ thống từ chối với ERR-18-041 (409)
    Và người dùng thấy thông báo "Loại thông báo {mã} chưa có mẫu đang dùng cho kênh {kênh}."

  @US-18-036 @FR-18-036 @M @âm
  Kịch bản: US-18-036 âm 2 · Máy chủ thư không sẵn sàng ở chế độ đồng bộ
    Biết loại thông báo có mẫu `ACTIVE` cho kênh (tenant hoặc `COMMON`)
    Khi máy chủ thư không sẵn sàng ở chế độ đồng bộ
    Thì hệ thống từ chối với ERR-18-044 (503)
    Và người dùng thấy thông báo "Chưa gửi được thư. Hệ thống sẽ thử lại hoặc bạn có thể gửi lại sau."

  @US-18-037 @FR-18-037 @M
  Kịch bản: US-18-037 dương · Phân giải người nhận từ tham chiếu
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi bước 3 của FR-18-036; hoặc DU gọi `recipients:resolve` để biết số người nhận
    Thì nội bộ: danh sách người nhận; thử: `200` với `counts`

  @US-18-037 @FR-18-037 @M @âm
  Kịch bản: US-18-037 âm 1 · Không phân giải được người nhận
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi không phân giải được người nhận
    Thì hệ thống từ chối với ERR-18-042 (422)
    Và người dùng thấy thông báo "Không xác định được người nhận từ {tham chiếu}."

  @US-18-037 @FR-18-037 @M @âm
  Kịch bản: US-18-037 âm 2 · PH-01 hoặc PH-12 không phản hồi
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi PH-01 hoặc PH-12 không phản hồi
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Đang chờ phân giải người nhận."

  @US-18-038 @FR-18-038 @M
  Kịch bản: US-18-038 dương · Quản lý tùy chọn nhận thông báo và giờ yên lặng
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi người dùng mở `/ca-nhan/thong-bao` (UI-18-14)
    Thì hệ thống trả `200` tùy chọn kèm `ETag`
    Và tùy chọn mới áp cho thông báo tạo sau đó

  @US-18-038 @FR-18-038 @M @âm
  Kịch bản: US-18-038 âm 1 · Tắt nhóm bắt buộc
    Biết người dùng đã đăng nhập với vai trò người dùng
    Khi tắt nhóm bắt buộc
    Thì hệ thống từ chối với ERR-18-046 (422)
    Và người dùng thấy thông báo "Không tắt được nhóm thông báo {nhóm} vì là thông báo bắt buộc."

  @US-18-039 @FR-18-039 @M
  Kịch bản: US-18-039 dương · Cấu hình quy tắc thông báo theo sự kiện
    Biết sự kiện thuộc bảng sự kiện PH-18 tiêu thụ (9.3b); mẫu có phiên bản `ACTIVE`
    Khi TA mở UI-18-11 tab "Quy tắc"; PH-18 tiêu thụ sự kiện qua inbox
    Thì hệ thống trả `201` quy tắc; `200` khi sửa
    Và quy tắc có hiệu lực cho sự kiện đến sau khi lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-039 @FR-18-039 @M @âm
  Kịch bản: US-18-039 âm 1 · Sự kiện chưa đăng ký tiêu thụ
    Biết sự kiện thuộc bảng sự kiện PH-18 tiêu thụ (9.3b); mẫu có phiên bản `ACTIVE`
    Khi sự kiện chưa đăng ký tiêu thụ
    Thì hệ thống từ chối với ERR-18-045 (422)
    Và người dùng thấy thông báo "Sự kiện {sự kiện} chưa được phân hệ vận hành tiêu thụ nên không tạo được quy tắc."

  @US-18-039 @FR-18-039 @M @âm
  Kịch bản: US-18-039 âm 2 · Mẫu chưa có phiên bản đang dùng
    Biết sự kiện thuộc bảng sự kiện PH-18 tiêu thụ (9.3b); mẫu có phiên bản `ACTIVE`
    Khi mẫu chưa có phiên bản đang dùng
    Thì hệ thống từ chối với ERR-18-041 (409)
    Và người dùng thấy thông báo "Mẫu {mã} chưa có phiên bản đang dùng."

  @US-18-040 @FR-18-040 @M
  Kịch bản: US-18-040 dương · Thử lại, xử lý thư trả lại và danh sách chặn
    Biết có `notification_delivery` lỗi hoặc thư trả lại
    Khi gửi lỗi tạm thời; máy chủ thư gửi báo cáo trả lại; TA bấm "Gửi lại" hoặc "Gỡ chặn"
    Thì báo cáo trả lại `202`; gửi lại `202`; gỡ chặn `204`
    Và mỗi lần gửi có trạng thái cuối
    Và sự kiện được phát: EVT-18-12; EVT-18-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-040 @FR-18-040 @M @âm
  Kịch bản: US-18-040 âm 1 · Gửi đồng bộ tới địa chỉ bị chặn
    Biết có `notification_delivery` lỗi hoặc thư trả lại
    Khi gửi đồng bộ tới địa chỉ bị chặn
    Thì hệ thống từ chối với ERR-18-043 (409)
    Và người dùng thấy thông báo "Địa chỉ nhận đang bị chặn do thư trả lại. Cập nhật đầu mối rồi gửi lại."

  @US-18-040 @FR-18-040 @M @âm
  Kịch bản: US-18-040 âm 2 · Gửi lại thông báo đã `DELIVERED`
    Biết có `notification_delivery` lỗi hoặc thư trả lại
    Khi gửi lại thông báo đã `DELIVERED`
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Thông báo đã được gửi thành công, không cần gửi lại."

  @US-18-041 @FR-18-041 @S
  Kịch bản: US-18-041 dương · Tra cứu nhật ký gửi thông báo và kênh cho PH-13
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi người dùng mở `/van-hanh/thong-bao/nhat-ky` (UI-18-13)
    Thì hệ thống trả `200` danh sách phân trang

  @US-18-041 @FR-18-041 @S @âm
  Kịch bản: US-18-041 âm 1 · Bộ lọc sai
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi bộ lọc sai
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: bộ lọc {tên}."

  # ---- EP-18-F · Việc của tôi và lịch

  @US-18-042 @FR-18-042 @M
  Kịch bản: US-18-042 dương · Đăng ký loại việc của phân hệ
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi DU khởi động và đăng ký loại việc
    Thì hệ thống trả `200` danh sách loại việc
    Và loại việc `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-042 @FR-18-042 @M @âm
  Kịch bản: US-18-042 âm 1 · Mã loại không thuộc phân hệ gọi
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi mã loại không thuộc phân hệ gọi
    Thì hệ thống từ chối với ERR-18-017 (403)
    Và người dùng thấy thông báo "Phân hệ {ph} không được đăng ký loại việc {mã}."

  @US-18-043 @FR-18-043 @M
  Kịch bản: US-18-043 dương · Tạo, cập nhật và đóng việc lũy đẳng
    Biết loại việc đã đăng ký (FR-18-042)
    Khi phân hệ tạo đối tượng chờ duyệt hoặc chờ xử lý; phân hệ hoàn tất hoặc hủy
    Thì hệ thống trả `200` với `taskId`, `status`, `dueAt`
    Và mỗi `sourceRef` và loại có đúng một việc
    Và sự kiện được phát: EVT-18-14

  @US-18-043 @FR-18-043 @M @âm
  Kịch bản: US-18-043 âm 1 · Loại việc chưa đăng ký
    Biết loại việc đã đăng ký (FR-18-042)
    Khi loại việc chưa đăng ký
    Thì hệ thống từ chối với ERR-18-047 (422)
    Và người dùng thấy thông báo "Loại việc {mã} chưa được đăng ký."

  @US-18-043 @FR-18-043 @M @âm
  Kịch bản: US-18-043 âm 2 · Cập nhật việc đã đóng với `sourceVersion` mới
    Biết loại việc đã đăng ký (FR-18-042)
    Khi cập nhật việc đã đóng với `sourceVersion` mới
    Thì hệ thống từ chối với ERR-18-048 (409)
    Và người dùng thấy thông báo "Việc {mã} đã đóng."

  @US-18-044 @FR-18-044 @M
  Kịch bản: US-18-044 dương · Hiển thị Việc của tôi, nhắc và quá hạn
    Biết người dùng đã chọn tenant
    Khi người dùng mở `/ca-nhan/viec` hoặc xem thẻ "Việc của tôi" trên trang chủ
    Thì hệ thống trả `200` danh sách hoặc tóm tắt
    Và sự kiện được phát: EVT-18-14 khi nhận việc

  @US-18-044 @FR-18-044 @M @âm
  Kịch bản: US-18-044 âm 1 · Việc không còn thuộc người dùng
    Biết người dùng đã chọn tenant
    Khi việc không còn thuộc người dùng
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy việc {mã} hoặc việc đã được người khác xử lý."

  @US-18-044 @FR-18-044 @M @âm
  Kịch bản: US-18-044 âm 2 · Nhận việc đã đóng
    Biết người dùng đã chọn tenant
    Khi nhận việc đã đóng
    Thì hệ thống từ chối với ERR-18-048 (409)
    Và người dùng thấy thông báo "Việc {mã} đã đóng."

  @US-18-045 @FR-18-045 @M
  Kịch bản: US-18-045 dương · Quản lý lịch ngày làm việc và tính hạn cho phân hệ khác
    Biết lịch `COMMON` của năm đã có ngày lễ quốc gia
    Khi TA mở `/van-hanh/lich` tab "Ngày làm việc"; DU gọi API tính hạn
    Thì hệ thống trả `200` lịch kèm `ETag`; tính hạn `200` với `dueAt`, `skippedDates[]`
    Và lịch năm có phiên bản
    Và sự kiện được phát: EVT-18-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-045 @FR-18-045 @M @âm
  Kịch bản: US-18-045 âm 1 · Lịch không hợp lệ
    Biết lịch `COMMON` của năm đã có ngày lễ quốc gia
    Khi lịch không hợp lệ
    Thì hệ thống từ chối với ERR-18-049 (422)
    Và người dùng thấy thông báo "Lịch năm {năm} không hợp lệ: {chi tiết}."

  @US-18-045 @FR-18-045 @M @âm
  Kịch bản: US-18-045 âm 2 · PH-18 vắng khi DU tính hạn
    Biết lịch `COMMON` của năm đã có ngày lễ quốc gia
    Khi PH-18 vắng khi DU tính hạn
    Thì DU dùng bản đệm, quá 24 giờ thì tính theo cuối tuần và ghi cảnh báo (phụ thuộc mềm của PH-01)

  @US-18-046 @FR-18-046 @M
  Kịch bản: US-18-046 dương · Quản lý cửa sổ bảo trì và đóng băng thay đổi
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi người dùng mở `/van-hanh/lich` tab "Bảo trì, đóng băng"; PH-20 gửi `platform.release.published.v1` kèm cửa sổ bảo trì
    Thì hệ thống trả `201` cửa sổ; `freeze-status` `200` với `active[]`
    Và cửa sổ có trạng thái `SCHEDULED`, `ACTIVE`, `ENDED`, `CANCELLED`
    Và sự kiện được phát: EVT-18-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-046 @FR-18-046 @M @âm
  Kịch bản: US-18-046 âm 1 · Cửa sổ chồng lấn
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi cửa sổ chồng lấn
    Thì hệ thống từ chối với ERR-18-050 (409)
    Và người dùng thấy thông báo "Cửa sổ {loại} chồng với cửa sổ {mã} từ {bắt đầu} đến {kết thúc}."

  @US-18-046 @FR-18-046 @M @âm
  Kịch bản: US-18-046 âm 2 · PH-18 vắng khi DU đọc
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi PH-18 vắng khi DU đọc
    Thì DU coi là không đóng băng (theo PH-04) và ghi cảnh báo

  # ---- EP-18-G · Sự cố vận hành

  @US-18-047 @FR-18-047 @M
  Kịch bản: US-18-047 dương · Mở hồ sơ sự cố từ sự kiện
    Biết quy tắc mở sự cố của tenant đang bật (mặc định bật cho EVT-13-04, EVT-13-05, EVT-18-08 loại `DEPTH` mức P1, EVT-18-19)
    Khi PH-18 tiêu thụ sự kiện; hoặc PH-13 gọi `POST /ops/internal/v1/incidents`
    Thì API: `201` với `incidentCode` hoặc `200` khi cập nhật sự cố có sẵn
    Và mỗi `sourceRef` có tối đa một sự cố mở
    Và sự kiện được phát: EVT-18-17
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-047 @FR-18-047 @M @âm
  Kịch bản: US-18-047 âm 1 · Không xử lý được sự kiện sau 5 lần
    Biết quy tắc mở sự cố của tenant đang bật (mặc định bật cho EVT-13-04, EVT-13-05, EVT-18-08 loại `DEPTH` mức P1, EVT-18-19)
    Khi không xử lý được sự kiện sau 5 lần
    Thì hệ thống từ chối với ERR-18-124
    Và người dùng thấy thông báo "Có {n} sự kiện mở sự cố chưa xử lý được."

  @US-18-048 @FR-18-048 @M
  Kịch bản: US-18-048 dương · Tạo tay, phân mức và gán người xử lý sự cố
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi người dùng bấm "+ Sự cố" ở UI-18-17; đổi trạng thái ở UI-18-18
    Thì hệ thống trả `201` sự cố; `200` khi cập nhật, kèm `ETag`
    Và mọi thay đổi có mốc thời gian
    Và sự kiện được phát: EVT-18-17; EVT-18-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-048 @FR-18-048 @M @âm
  Kịch bản: US-18-048 âm 1 · Chuyển trạng thái sai
    Biết người dùng đã đăng nhập với vai trò vận hành tỉnh
    Khi chuyển trạng thái sai
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Sự cố đang ở trạng thái {trạng thái} nên không thể chuyển sang {trạng thái mới}."

  @US-18-049 @FR-18-049 @S
  Kịch bản: US-18-049 dương · Ghi mốc thời gian và liên kết sự cố
    Biết sự cố chưa `CLOSED`
    Khi người dùng thêm ghi chú hoặc bấm "Liên kết" ở UI-18-18; hệ thống tự thêm mốc khi có sự kiện liên quan
    Thì hệ thống trả `201` mốc hoặc liên kết
    Và mốc chỉ thêm, không xóa
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-049 @FR-18-049 @S @âm
  Kịch bản: US-18-049 âm 1 · Đối tượng liên kết không tồn tại
    Biết sự cố chưa `CLOSED`
    Khi đối tượng liên kết không tồn tại
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã}."

  @US-18-050 @FR-18-050 @S
  Kịch bản: US-18-050 dương · Chuyển sự cố có dữ liệu cá nhân sang PH-09
    Biết sự cố có `hasPersonalData = true` hoặc nghi ngờ
    Khi người dùng bấm "Chuyển quyền riêng tư" ở UI-18-18; hoặc người dùng đặt `hasPersonalData = true`
    Thì hệ thống trả `200` với `privacyCaseRef`
    Và sự cố có liên kết `PRIVACY_CASE`
    Và sự kiện được phát: EVT-18-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-050 @FR-18-050 @S @âm
  Kịch bản: US-18-050 âm 1 · Thiếu thông tin
    Biết sự cố có `hasPersonalData = true` hoặc nghi ngờ
    Khi thiếu thông tin
    Thì hệ thống từ chối với ERR-18-053 (422)
    Và người dùng thấy thông báo "Cần nêu loại dữ liệu cá nhân, số người ước tính và thời điểm phát hiện."

  @US-18-051 @FR-18-051 @M
  Kịch bản: US-18-051 dương · Đóng sự cố có nguyên nhân gốc và bài học
    Biết sự cố `RESOLVED`; nếu có `PRIVACY_CASE` thì hồ sơ PH-09 đã có kết luận
    Khi người dùng bấm "Đóng sự cố" ở UI-18-18
    Thì hệ thống trả `200` sự cố `CLOSED`
    Và sự cố `CLOSED` chỉ đọc
    Và sự kiện được phát: EVT-18-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-051 @FR-18-051 @M @âm
  Kịch bản: US-18-051 âm 1 · Thiếu nguyên nhân hoặc bài học
    Biết sự cố `RESOLVED`; nếu có `PRIVACY_CASE` thì hồ sơ PH-09 đã có kết luận
    Khi thiếu nguyên nhân hoặc bài học
    Thì hệ thống từ chối với ERR-18-052 (422)
    Và người dùng thấy thông báo "Đóng sự cố cần nêu nguyên nhân gốc và bài học (mỗi phần ít nhất 30 ký tự)."

  @US-18-051 @FR-18-051 @M @âm
  Kịch bản: US-18-051 âm 2 · Hồ sơ PH-09 còn mở
    Biết sự cố `RESOLVED`; nếu có `PRIVACY_CASE` thì hồ sơ PH-09 đã có kết luận
    Khi hồ sơ PH-09 còn mở
    Thì hệ thống từ chối với ERR-18-006 (409)
    Và người dùng thấy thông báo "Hồ sơ quyền riêng tư {mã} chưa kết luận nên chưa đóng được sự cố."

  # ---- EP-18-H · Sao lưu và khôi phục

  @US-18-052 @FR-18-052 @M
  Kịch bản: US-18-052 dương · Theo dõi sao lưu theo đối tượng và cảnh báo lỗi
    Biết danh mục `backup_object` được nạp từ D03-09 §8.2 khi triển khai (PostgreSQL bản sao cơ sở, WAL, xuất logic theo tenant, Garage, OpenBao, Velero, kho Git, Harbor, ClickHouse, WORM kiểm toán)
    Khi tác vụ thu thập chạy mỗi 5 phút; CronJob báo bản sao lưu; người dùng mở `/van-hanh/sao-luu`
    Thì hệ thống trả `200` danh sách đối tượng và bản sao lưu; báo cáo `202`
    Và mỗi bản sao lưu có một `backup_run`
    Và sự kiện được phát: EVT-18-19

  @US-18-052 @FR-18-052 @M @âm
  Kịch bản: US-18-052 âm 1 · Không thu được trạng thái
    Biết danh mục `backup_object` được nạp từ D03-09 §8.2 khi triển khai (PostgreSQL bản sao cơ sở, WAL, xuất logic theo tenant, Garage, OpenBao, Velero, kho Git, Harbor, ClickHouse, WORM kiểm toán)
    Khi không thu được trạng thái
    Thì hệ thống từ chối với ERR-18-055
    Và người dùng thấy thông báo "Chưa thu được trạng thái sao lưu từ {công cụ}. Số liệu đang hiển thị là của {thời điểm}."

  @US-18-053 @FR-18-053 @M
  Kịch bản: US-18-053 dương · Ghi nhận kết quả kiểm tra khôi phục tự động
    Biết đối tượng có cách kiểm tra khôi phục được khai báo
    Khi CronJob chạy theo lịch (PostgreSQL hằng ngày, PITR hằng tuần, xuất tenant hằng tháng, Garage hằng tuần) và báo kết quả
    Thì hệ thống trả `202` khi báo; `200` danh sách kết quả
    Và mỗi lần kiểm tra có một bản ghi kèm biên bản
    Và sự kiện được phát: EVT-18-20

  @US-18-053 @FR-18-053 @M @âm
  Kịch bản: US-18-053 âm 1 · Đối tượng chưa khai báo
    Biết đối tượng có cách kiểm tra khôi phục được khai báo
    Khi đối tượng chưa khai báo
    Thì hệ thống từ chối với ERR-18-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy đối tượng sao lưu {mã}."

  @US-18-054 @FR-18-054 @M
  Kịch bản: US-18-054 dương · Tạo yêu cầu khôi phục một tenant
    Biết tenant `ACTIVE`; không có tác vụ nặng khác đang chạy cho tenant
    Khi TA bấm "Yêu cầu khôi phục" ở UI-18-20
    Thì hệ thống trả `201` yêu cầu `DRAFT`; gửi `200` `PENDING_APPROVAL` kèm `estimate`
    Và một yêu cầu `PENDING_APPROVAL`; dữ liệu chưa đổi
    Và sự kiện được phát: EVT-18-21
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-054 @FR-18-054 @M @âm
  Kịch bản: US-18-054 âm 1 · Thời điểm ngoài cửa sổ PITR
    Biết tenant `ACTIVE`; không có tác vụ nặng khác đang chạy cho tenant
    Khi thời điểm ngoài cửa sổ PITR
    Thì hệ thống từ chối với ERR-18-056 (422)
    Và người dùng thấy thông báo "Thời điểm {thời điểm} nằm ngoài cửa sổ khôi phục 30 ngày."

  @US-18-054 @FR-18-054 @M @âm
  Kịch bản: US-18-054 âm 2 · Tenant đang có tác vụ nặng khác
    Biết tenant `ACTIVE`; không có tác vụ nặng khác đang chạy cho tenant
    Khi tenant đang có tác vụ nặng khác
    Thì hệ thống từ chối với ERR-18-057 (409)
    Và người dùng thấy thông báo "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục."

  @US-18-055 @FR-18-055 @M
  Kịch bản: US-18-055 dương · Duyệt và chạy khôi phục tenant tám bước
    Biết yêu cầu `PENDING_APPROVAL` (FR-18-054); người duyệt khác người tạo
    Khi PA bấm "Duyệt" trên việc `ph18.approve-restore`
    Thì duyệt: `200` yêu cầu `RUNNING` kèm `jobName`
    Và tenant `ACTIVE` với dữ liệu tại thời điểm đích trong phạm vi; bản ghi kiểm toán khôi phục có số dòng thay thế mỗi bảng
    Và sự kiện được phát: EVT-18-21; EVT-18-22
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-055 @FR-18-055 @M @âm
  Kịch bản: US-18-055 âm 1 · Người duyệt trùng người tạo
    Biết yêu cầu `PENDING_APPROVAL` (FR-18-054); người duyệt khác người tạo
    Khi người duyệt trùng người tạo
    Thì hệ thống từ chối với ERR-18-005 (403)
    Và người dùng thấy thông báo "Bạn là người tạo yêu cầu nên không được duyệt."

  @US-18-055 @FR-18-055 @M @âm
  Kịch bản: US-18-055 âm 2 · Bước của Job lỗi
    Biết yêu cầu `PENDING_APPROVAL` (FR-18-054); người duyệt khác người tạo
    Khi bước của Job lỗi
    Thì hệ thống từ chối với ERR-18-114
    Và người dùng thấy thông báo "Bước {n} của khôi phục lỗi: {mô tả}. Hệ thống đang quay lui."

  @US-18-056 @FR-18-056 @M
  Kịch bản: US-18-056 dương · Xuất dữ liệu tenant
    Biết mục đích `HANDOVER` cần tenant `DECOMMISSIONED` hoặc `SUSPENDED`; `CELL_MOVE` cần cửa sổ bảo trì; không tác vụ nặng khác
    Khi PA bấm "Xuất dữ liệu" ở UI-18-20; PH-18 nhận sự kiện `platform.tenant.export-ready.v1`
    Thì hệ thống trả `201` lệnh xuất; chi tiết `200` với kích thước, tổng kiểm tra; liên kết `200` với `url` có hạn
    Và một `tenant_export_job` `SUCCEEDED` hoặc `FAILED`
    Và sự kiện được phát: EVT-18-23
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-056 @FR-18-056 @M @âm
  Kịch bản: US-18-056 âm 1 · Trạng thái tenant không phù hợp
    Biết mục đích `HANDOVER` cần tenant `DECOMMISSIONED` hoặc `SUSPENDED`; `CELL_MOVE` cần cửa sổ bảo trì; không tác vụ nặng khác
    Khi trạng thái tenant không phù hợp
    Thì hệ thống từ chối với ERR-18-059 (409)
    Và người dùng thấy thông báo "Tỉnh đang ở trạng thái {trạng thái}, chưa xuất được với mục đích {mục đích}."

  @US-18-056 @FR-18-056 @M @âm
  Kịch bản: US-18-056 âm 2 · Job xuất lỗi
    Biết mục đích `HANDOVER` cần tenant `DECOMMISSIONED` hoặc `SUSPENDED`; `CELL_MOVE` cần cửa sổ bảo trì; không tác vụ nặng khác
    Khi job xuất lỗi
    Thì hệ thống từ chối với ERR-18-116
    Và người dùng thấy thông báo "Xuất dữ liệu lỗi ở {bước}. Không có gói nào được tạo."

  @US-18-057 @FR-18-057 @S
  Kịch bản: US-18-057 dương · Chuyển dữ liệu phân hệ khi sáp nhập tenant
    Biết PH-20 đã có kế hoạch sáp nhập `mergePlanId` và tenant nguồn đã `SUSPENDED`; tenant đích `ACTIVE`; không tác vụ nặng khác trên hai tenant
    Khi PH-20 gọi `POST /merge-transfers` cho từng phân hệ tham gia; PH-18 nhận `platform.tenant.merge-started.v1`
    Thì hệ thống trả `202` với `transferId`, `status`; chi tiết `200` với số bản ghi đọc, nạp, xung đột
    Và bản ghi đã chuyển có `origin_tenant_id`; tenant nguồn giữ nguyên tới khi PH-20 giải thể
    Và sự kiện được phát: EVT-18-24
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-057 @FR-18-057 @S @âm
  Kịch bản: US-18-057 âm 1 · Yêu cầu không hợp lệ
    Biết PH-20 đã có kế hoạch sáp nhập `mergePlanId` và tenant nguồn đã `SUSPENDED`; tenant đích `ACTIVE`; không tác vụ nặng khác trên hai tenant
    Khi yêu cầu không hợp lệ
    Thì hệ thống từ chối với ERR-18-060 (422)
    Và người dùng thấy thông báo "Yêu cầu chuyển dữ liệu {phân hệ} không hợp lệ: {chi tiết}."

  @US-18-058 @FR-18-058 @C
  Kịch bản: US-18-058 dương · Ghi nhận diễn tập DR và PITR toàn cụm
    Biết diễn tập đã diễn ra
    Khi PA bấm "+ Diễn tập" ở UI-18-19 tab "Diễn tập"
    Thì hệ thống trả `201` bản ghi diễn tập
    Và bản ghi chỉ thêm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-058 @FR-18-058 @C @âm
  Kịch bản: US-18-058 âm 1 · Thiếu biên bản
    Biết diễn tập đã diễn ra
    Khi thiếu biên bản
    Thì hệ thống từ chối với ERR-18-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: cần tải biên bản diễn tập."

  # ---- EP-18-I · Di trú hệ cũ và chạy song song

  @US-18-059 @FR-18-059 @M
  Kịch bản: US-18-059 dương · Khai báo nguồn hệ cũ
    Biết bí mật kết nối đã được ghi vào OpenBao theo đường dẫn `kv/dh/{tenant}/migration/{sourceCode}` bởi người có quyền ở OpenBao
    Khi người dùng bấm "+ Nguồn hệ cũ" ở UI-18-21
    Thì hệ thống trả `201` nguồn; thử kết nối `200` với `readOnly`, `tables`, `estimatedRows`
    Và nguồn `READY` hoặc `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-059 @FR-18-059 @M @âm
  Kịch bản: US-18-059 âm 1 · Thông tin kết nối có mật khẩu
    Biết bí mật kết nối đã được ghi vào OpenBao theo đường dẫn `kv/dh/{tenant}/migration/{sourceCode}` bởi người có quyền ở OpenBao
    Khi thông tin kết nối có mật khẩu
    Thì hệ thống từ chối với ERR-18-070 (422)
    Và người dùng thấy thông báo "Thông tin kết nối phải là tham chiếu kho bí mật, không nhập mật khẩu trực tiếp."

  @US-18-059 @FR-18-059 @M @âm
  Kịch bản: US-18-059 âm 2 · Không kết nối được hoặc tài khoản có quyền ghi
    Biết bí mật kết nối đã được ghi vào OpenBao theo đường dẫn `kv/dh/{tenant}/migration/{sourceCode}` bởi người có quyền ở OpenBao
    Khi không kết nối được hoặc tài khoản có quyền ghi
    Thì hệ thống từ chối với ERR-18-062 (422)
    Và người dùng thấy thông báo "Nguồn {mã} không kết nối được hoặc tài khoản không phải chỉ đọc: {chi tiết}."

  @US-18-060 @FR-18-060 @M
  Kịch bản: US-18-060 dương · Lập kế hoạch di trú theo loại đối tượng và thứ tự phụ thuộc
    Biết nguồn `READY` (FR-18-059)
    Khi người dùng bấm "+ Kế hoạch" ở UI-18-21 và thêm loại đối tượng
    Thì hệ thống trả `201` kế hoạch; `200` khi cập nhật hoặc sẵn sàng, kèm thứ tự đã tính
    Và kế hoạch `READY` hoặc `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-060 @FR-18-060 @M @âm
  Kịch bản: US-18-060 âm 1 · Phụ thuộc vòng hoặc thiếu tiền đề
    Biết nguồn `READY` (FR-18-059)
    Khi phụ thuộc vòng hoặc thiếu tiền đề
    Thì hệ thống từ chối với ERR-18-063 (422)
    Và người dùng thấy thông báo "Kế hoạch có phụ thuộc vòng hoặc thiếu đối tượng tiền đề: {danh sách}."

  @US-18-061 @FR-18-061 @M
  Kịch bản: US-18-061 dương · Chạy thử di trú không ghi
    Biết kế hoạch `READY`
    Khi người dùng bấm "Chạy thử" ở UI-18-21
    Thì hệ thống trả `202` với `runId`
    Và sự kiện được phát: EVT-18-25
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-061 @FR-18-061 @M @âm
  Kịch bản: US-18-061 âm 1 · Kế hoạch chưa sẵn sàng
    Biết kế hoạch `READY`
    Khi kế hoạch chưa sẵn sàng
    Thì hệ thống từ chối với ERR-18-065 (409)
    Và người dùng thấy thông báo "Kế hoạch {mã} chưa ở trạng thái sẵn sàng."

  @US-18-061 @FR-18-061 @M @âm
  Kịch bản: US-18-061 âm 2 · Đọc nguồn lỗi
    Biết kế hoạch `READY`
    Khi đọc nguồn lỗi
    Thì hệ thống từ chối với ERR-18-117
    Và người dùng thấy thông báo "Không đọc được nguồn hệ cũ ở bảng {bảng}: {chi tiết}."

  @US-18-062 @FR-18-062 @M
  Kịch bản: US-18-062 dương · Chạy thật di trú có duyệt bốn mắt
    Biết kế hoạch `READY`; có lần chạy thử `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS` trong `18.migration.dry-run-valid-days` (7 ngày) với cùng phiên bản kế hoạch; không trong đóng băng của môi trường đích; không tác vụ nặng khác cho tenant
    Khi người dùng bấm "Chạy thật" ở UI-18-21
    Thì hệ thống trả `202` với `runId`, `status = PENDING_APPROVAL`; duyệt `200`
    Và mỗi bản ghi nguồn có tối đa một bản ghi đích
    Và sự kiện được phát: EVT-18-25; EVT-18-26
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-062 @FR-18-062 @M @âm
  Kịch bản: US-18-062 âm 1 · Kế hoạch chưa sẵn sàng
    Biết kế hoạch `READY`; có lần chạy thử `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS` trong `18.migration.dry-run-valid-days` (7 ngày) với cùng phiên bản kế hoạch; không trong đóng băng của môi trường đích; không tác vụ nặng khác cho tenant
    Khi kế hoạch chưa sẵn sàng
    Thì hệ thống từ chối với ERR-18-065 (409)
    Và người dùng thấy thông báo "Kế hoạch {mã} chưa ở trạng thái sẵn sàng."

  @US-18-062 @FR-18-062 @M @âm
  Kịch bản: US-18-062 âm 2 · Chưa có chạy thử hợp lệ
    Biết kế hoạch `READY`; có lần chạy thử `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS` trong `18.migration.dry-run-valid-days` (7 ngày) với cùng phiên bản kế hoạch; không trong đóng băng của môi trường đích; không tác vụ nặng khác cho tenant
    Khi chưa có chạy thử hợp lệ
    Thì hệ thống từ chối với ERR-18-064 (409)
    Và người dùng thấy thông báo "Cần một lần chạy thử thành công trong {ngày} ngày gần nhất trước khi chạy thật."

  @US-18-063 @FR-18-063 @M
  Kịch bản: US-18-063 dương · Quản lý bản ghi lỗi và chạy lại sau khi sửa
    Biết lần chạy có bản ghi lỗi
    Khi người dùng mở tab "Bản ghi lỗi" ở UI-18-22
    Thì hệ thống trả `200` danh sách lỗi; chạy lại `202` với `runId` mới
    Và mỗi bản ghi lỗi có trạng thái xử lý
    Và sự kiện được phát: EVT-18-25 (qua lần chạy mới)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-063 @FR-18-063 @M @âm
  Kịch bản: US-18-063 âm 1 · Lần chạy gốc không có bản ghi lỗi
    Biết lần chạy có bản ghi lỗi
    Khi lần chạy gốc không có bản ghi lỗi
    Thì hệ thống từ chối với ERR-18-036 (422)
    Và người dùng thấy thông báo "Không có mục nào phù hợp để chạy lại."

  @US-18-064 @FR-18-064 @M
  Kịch bản: US-18-064 dương · Lập báo cáo đối chiếu số lượng và tổng kiểm tra
    Biết lần chạy đã kết thúc
    Khi job kết thúc lần chạy; người dùng mở tab "Đối chiếu" ở UI-18-22
    Thì hệ thống trả `200` báo cáo, liên kết tải
    Và mỗi lần chạy có một báo cáo đối chiếu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-064 @FR-18-064 @M @âm
  Kịch bản: US-18-064 âm 1 · Tổng kiểm tra lệch
    Biết lần chạy đã kết thúc
    Khi tổng kiểm tra lệch
    Thì hệ thống từ chối với ERR-18-120
    Và người dùng thấy thông báo "Tổng kiểm tra của {loại} không khớp giữa nguồn và đích. Xem danh sách khóa lệch."

  @US-18-065 @FR-18-065 @M
  Kịch bản: US-18-065 dương · Đánh dấu thông tin xác thực cần cấp lại
    Biết lần chạy có loại đối tượng mang thông tin xác thực (application, subscription có khóa, client chứng thư)
    Khi bước 4 của FR-18-062
    Thì hệ thống trả `200` danh sách dấu theo HTTT, trạng thái
    Và sự kiện được phát: EVT-18-26
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-065 @FR-18-065 @M @âm
  Kịch bản: US-18-065 âm 1 · Không phát được sự kiện
    Biết lần chạy có loại đối tượng mang thông tin xác thực (application, subscription có khóa, client chứng thư)
    Khi không phát được sự kiện
    Thì hệ thống từ chối với ERR-18-124
    Và người dùng thấy thông báo "Chưa báo được danh sách cần cấp lại xác thực cho phân hệ kết nạp."

  @US-18-066 @FR-18-066 @S
  Kịch bản: US-18-066 dương · Theo dõi chạy song song và cầu nối PH-10
    Biết nhóm dịch vụ đã được khai báo (`parallel_run_group`) từ kế hoạch di trú
    Khi người dùng mở `/van-hanh/di-tru/song-song`; PH-18 nhận EVT-10-15, EVT-10-16
    Thì hệ thống trả `200` danh sách và chi tiết nhóm

  @US-18-066 @FR-18-066 @S @âm
  Kịch bản: US-18-066 âm 1 · Không xử lý được sự kiện của PH-10
    Biết nhóm dịch vụ đã được khai báo (`parallel_run_group`) từ kế hoạch di trú
    Khi không xử lý được sự kiện của PH-10
    Thì hệ thống từ chối với ERR-18-124

  @US-18-067 @FR-18-067 @S
  Kịch bản: US-18-067 dương · Đối soát kết quả hệ cũ và Datahub bằng lưu lượng nhân bản
    Biết PH-03 bật `proxy-mirror` cho tuyến của nhóm với tỷ lệ `18.migration.shadow.sample-percent` (5%); phản hồi của Datahub ở chế độ bóng không gửi về HTTT
    Khi có cặp phản hồi cũ và mới
    Thì hệ thống trả `202` khi nhận mẫu; xem ở chi tiết nhóm
    Và mẫu giữ 90 ngày
    Và sự kiện được phát: EVT-18-27 khi nhóm đổi trạng thái

  @US-18-067 @FR-18-067 @S @âm
  Kịch bản: US-18-067 âm 1 · Mẫu lệch
    Biết PH-03 bật `proxy-mirror` cho tuyến của nhóm với tỷ lệ `18.migration.shadow.sample-percent` (5%); phản hồi của Datahub ở chế độ bóng không gửi về HTTT
    Khi mẫu lệch
    Thì hệ thống từ chối với ERR-18-121
    Và người dùng thấy thông báo "Trường {đường dẫn} lệch ở {n} mẫu."

  @US-18-068 @FR-18-068 @M
  Kịch bản: US-18-068 dương · Điều khiển cắt chuyển nhóm dịch vụ và quay lui
    Biết nhóm `SHADOW_OK` (cắt chuyển một phần) hoặc `PARTIAL_CUTOVER` (cắt chuyển toàn phần)
    Khi người dùng bấm "Cắt chuyển" hoặc "Quay lui" ở UI-18-23
    Thì hệ thống trả `200` nhóm với trạng thái mới, mục sổ cắt chuyển
    Và mọi thao tác có dòng trong sổ cắt chuyển
    Và sự kiện được phát: EVT-18-27
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-068 @FR-18-068 @M @âm
  Kịch bản: US-18-068 âm 1 · Danh sách kiểm tra chưa đạt
    Biết nhóm `SHADOW_OK` (cắt chuyển một phần) hoặc `PARTIAL_CUTOVER` (cắt chuyển toàn phần)
    Khi danh sách kiểm tra chưa đạt
    Thì hệ thống từ chối với ERR-18-067 (409)
    Và người dùng thấy thông báo "Chưa cắt chuyển được nhóm {nhóm}: còn {n} mục kiểm tra chưa đạt."

  @US-18-068 @FR-18-068 @M @âm
  Kịch bản: US-18-068 âm 2 · Tỷ lệ khớp chưa đạt
    Biết nhóm `SHADOW_OK` (cắt chuyển một phần) hoặc `PARTIAL_CUTOVER` (cắt chuyển toàn phần)
    Khi tỷ lệ khớp chưa đạt
    Thì hệ thống từ chối với ERR-18-066 (422)
    Và người dùng thấy thông báo "Tỷ lệ khớp {tỷ lệ} thấp hơn ngưỡng {ngưỡng}."

  # ---- EP-18-J · Quản trị, kiểm toán và báo cáo

  @US-18-069 @FR-18-069 @M
  Kịch bản: US-18-069 dương · Quản lý tham số của phân hệ vận hành
    Biết PH-18 đã đăng ký không gian tên `18.` (FR-18-001)
    Khi người dùng mở `/van-hanh/tham-so?ns=18.`
    Thì như FR-18-003
    Và như FR-18-003
    Và sự kiện được phát: EVT-18-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-069 @FR-18-069 @M @âm
  Kịch bản: US-18-069 âm 1 · Vượt trần
    Biết PH-18 đã đăng ký không gian tên `18.` (FR-18-001)
    Khi vượt trần
    Thì hệ thống từ chối với ERR-18-014 (422)
    Và người dùng thấy thông báo "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng."

  @US-18-070 @FR-18-070 @M
  Kịch bản: US-18-070 dương · Ghi và tra nhật ký thao tác vận hành
    Biết thư viện kiểm toán chung của PH-13 sẵn sàng
    Khi mọi thao tác có mục "Kiểm toán: Có" ở chương 6; người dùng mở tab "Nhật ký" ở UI-18-24 hoặc tab nhật ký của mục DLQ
    Thì hệ thống trả `200` danh sách bản ghi kiểm toán
    Và bản ghi kiểm toán chỉ thêm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-070 @FR-18-070 @M @âm
  Kịch bản: US-18-070 âm 1 · PH-13 không ghi được
    Biết thư viện kiểm toán chung của PH-13 sẵn sàng
    Khi PH-13 không ghi được
    Thì hệ thống từ chối với ERR-18-008 (503)
    Và người dùng thấy thông báo "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."

  @US-18-071 @FR-18-071 @S
  Kịch bản: US-18-071 dương · Lập báo cáo vận hành định kỳ
    Biết kỳ đã kết thúc
    Khi ngày đầu kỳ mới 06:00; người dùng bấm "Dựng báo cáo"
    Thì hệ thống trả `202` khi dựng; `200` danh sách báo cáo với liên kết tải
    Và một `ops_report` mỗi kỳ
    Và sự kiện được phát: EVT-18-28
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-071 @FR-18-071 @S @âm
  Kịch bản: US-18-071 âm 1 · Kỳ không hợp lệ
    Biết kỳ đã kết thúc
    Khi kỳ không hợp lệ
    Thì hệ thống từ chối với ERR-18-072 (422)
    Và người dùng thấy thông báo "Kỳ báo cáo {kỳ} không hợp lệ hoặc chưa kết thúc."

  @US-18-072 @FR-18-072 @M
  Kịch bản: US-18-072 dương · Theo dõi sức khỏe phân hệ và chế độ suy giảm
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi kiểm tra sức khỏe mỗi 15 giây; PA bật hoặc tắt chế độ chỉ đọc; người dùng mở UI-18-24
    Thì hệ thống trả `200` trạng thái thành phần
    Và sự kiện được phát: EVT-18-29
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-18-072 @FR-18-072 @M @âm
  Kịch bản: US-18-072 âm 1 · Chế độ chỉ đọc
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi chế độ chỉ đọc
    Thì hệ thống từ chối với ERR-18-071 (503)
    Và người dùng thấy thông báo "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được."
