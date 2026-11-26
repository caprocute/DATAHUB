---
ma_tai_lieu: D02-08
ten: Ma trận phân quyền
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Phân tích nghiệp vụ, Kiến trúc sư, Đội phát triển, Kiểm thử, ATTT
---

# D02-08 · Ma trận phân quyền

## 1. Mục đích và mô hình

Tài liệu này định nghĩa **vai trò** (`ROLE-*`), **quyền** (`PERM-{PH}-{động từ}`) và ma trận gán quyền cho vai trò. FRS từng phân hệ dẫn chiếu quyền tại đây cho mỗi chức năng; kiểm thử dùng ma trận này để sinh ca kiểm thử phân quyền âm và dương.

Mô hình phân quyền kết hợp ba lớp, được OPA đánh giá cùng lúc (ADR-006):

1. **Theo vai trò (RBAC).** Vai trò gán cho người dùng trong realm của tenant. Vai trò quyết định người dùng được làm loại thao tác nào.
2. **Theo phạm vi tổ chức.** Một số vai trò bị giới hạn trong tổ chức của người dùng và tổ chức cấp dưới. Ví dụ cán bộ sở A chỉ nộp và xem hồ sơ HTTT do sở A chủ quản.
3. **Theo thuộc tính dữ liệu (ABAC).** Mức phân loại dữ liệu, mục đích khai thác đã được chấp thuận, trạng thái đối tượng. Ví dụ xem giá trị đầy đủ của trường Nhạy cảm cần quyền `PERM-09-unmask` cộng lý do.

Các nguyên tắc chung:

- **Từ chối mặc định.** Quyền không có trong ma trận nghĩa là không được phép.
- **Bốn mắt.** Các quyền duyệt (`approve`) không áp dụng cho đối tượng do chính người dùng tạo hoặc gửi (FR-00-071).
- **Tách nhiệm vụ.** Một người dùng không được đồng thời giữ cặp vai trò xung đột ở mục 4. PH-12 chặn khi gán.
- **Quyền tối thiểu cho máy.** HTTT thành viên không có vai trò người dùng; quyền của máy là phạm vi (scope) OAuth gắn với đăng ký sử dụng đã duyệt ở PH-02 và mục đích ở PH-09.

## 2. Danh mục vai trò

Bảng dưới đây liệt kê vai trò chuẩn được tạo tự động cho mỗi tenant khi khởi tạo (D03-10 §5.2). Vai trò có tiền tố `PLATFORM_` chỉ tồn tại ở tenant `PLATFORM`. Cột MFA cho biết vai trò bắt buộc xác thực hai yếu tố (FR-00-002).

| Mã | Tên | Phạm vi | MFA | Mô tả |
|---|---|---|---|---|
| ROLE-PLATFORM_ADMIN | Quản trị nền tảng | Toàn nền tảng | Có | Khởi tạo, cấu hình, tạm ngừng tenant; quản lý danh mục `COMMON`, Kamelet được duyệt |
| ROLE-PLATFORM_OPERATOR | Vận hành nền tảng | Toàn nền tảng, chỉ-đọc nghiệp vụ | Có | Giám sát, xử lý sự cố hạ tầng; truy cập liên tenant phải có lý do |
| ROLE-PLATFORM_AUDITOR | Kiểm toán nền tảng | Toàn nền tảng, chỉ-đọc | Có | Xem nhật ký kiểm toán mọi tenant |
| ROLE-TENANT_ADMIN | Quản trị tỉnh | Tenant | Có | Quản trị người dùng, tổ chức, cấu hình, duyệt kết nạp HTTT |
| ROLE-TENANT_OPERATOR | Vận hành tỉnh | Tenant | Có | Giám sát, kích hoạt/tạm dừng luồng và API, xử lý DLQ |
| ROLE-SECURITY_OFFICER | Cán bộ ATTT | Tenant | Có | Xem nhật ký an ninh, thu hồi định danh, tạm ngừng HTTT khi có sự cố |
| ROLE-INTEGRATION_ENGINEER | Kỹ sư tích hợp | Tenant hoặc không gian làm việc | Không | Thiết kế, chạy thử luồng; khai báo kết nối; gửi duyệt |
| ROLE-INTEGRATION_APPROVER | Người duyệt tích hợp | Tenant | Có | Duyệt phát hành luồng, Kamelet mới, schema sự kiện |
| ROLE-SERVICE_OWNER | Chủ dịch vụ | Tổ chức | Không | Đăng ký, cập nhật API và topic của tổ chức mình; gửi duyệt công bố |
| ROLE-CATALOG_APPROVER | Người duyệt dịch vụ | Tenant | Có | Duyệt công bố API, gói sử dụng, đăng ký sử dụng |
| ROLE-ORG_REQUESTER | Cán bộ đầu mối của tổ chức | Tổ chức | Không | Nộp hồ sơ kết nạp HTTT, đăng ký sử dụng API cho HTTT của tổ chức |
| ROLE-DATA_STEWARD | Cán bộ quản lý danh mục, dữ liệu | Tổ chức hoặc tenant | Không | Soạn, nhập, xuất danh mục; quản lý quy tắc chất lượng |
| ROLE-DATA_APPROVER | Người duyệt danh mục | Tenant | Có | Duyệt phát hành danh mục |
| ROLE-DATA_OWNER | Chủ quản dữ liệu | Tổ chức | Có | Chấp thuận yêu cầu khai thác dữ liệu do tổ chức mình làm chủ |
| ROLE-PAYMENT_ADMIN | Quản trị thanh toán | Tenant | Có | Cấu hình nhà cung cấp, dịch vụ, đối tác; lập đề nghị kích hoạt, duyệt đối tác |
| ROLE-PAYMENT_APPROVER | Người phê duyệt thanh toán | Tenant | Có | Chỉ quyết định đề nghị: kích hoạt NCC, đối tác, hoàn tiền, xử lý chênh lệch, mở lại phiên, đổi chế độ định tuyến |
| ROLE-PAYMENT_ACCOUNTANT | Kế toán, đối soát viên | Tenant | Có | Đối soát, xử lý chênh lệch, lập và ghi nhận hoàn tiền, báo cáo (thay `PAYMENT_OFFICER` của bản 0.1) |
| ROLE-PAYMENT_OPERATOR | Vận hành thanh toán | Tenant | Có | Tra cứu, đồng bộ trạng thái, xử lý lại IPN, gửi lại webhook, hủy giao dịch thay đối tác |
| ROLE-PARTNER_SYSTEM | HTTT đối tác thanh toán | Client máy-máy | — | Tạo, truy vấn giao dịch, lập yêu cầu hoàn; chỉ gán cho client, không gán cho người |
| ROLE-DEVELOPER | Nhà phát triển | Ứng dụng được giao | Không | Dùng cổng nhà phát triển, sandbox, xem thông tin xác thực ứng dụng được giao |
| ROLE-VIEWER | Người xem | Tenant | Không | Xem bảng điều khiển và báo cáo, không xem dữ liệu HC/NC |
| ROLE-AUDITOR | Kiểm toán, thanh tra tỉnh | Tenant, chỉ-đọc | Có | Xem nhật ký kiểm toán, xuất bằng chứng |

## 3. Danh mục quyền và ma trận

Quyền viết theo dạng `PERM-{PH}-{động từ}`. Các động từ chuẩn: `read` (xem), `create`, `update`, `delete`, `submit` (gửi duyệt), `approve` (duyệt hoặc từ chối), `publish` (phát hành, công bố), `operate` (kích hoạt, tạm dừng, xử lý lại), `export` (xuất dữ liệu), `admin` (cấu hình phân hệ). Quyền đặc thù được liệt kê riêng.

Ma trận dưới đây dùng ký hiệu: **●** được phép trong phạm vi của vai trò; **○** chỉ với đối tượng thuộc tổ chức của mình; **—** không được phép. Cột vai trò viết tắt: PA = PLATFORM_ADMIN, PO = PLATFORM_OPERATOR, TA = TENANT_ADMIN, TO = TENANT_OPERATOR, SO = SECURITY_OFFICER, IE = INTEGRATION_ENGINEER, IA = INTEGRATION_APPROVER, SV = SERVICE_OWNER, CA = CATALOG_APPROVER, OR = ORG_REQUESTER, DS = DATA_STEWARD, DA = DATA_APPROVER, DO = DATA_OWNER, VW = VIEWER, AU = AUDITOR. Vai trò thanh toán và nhà phát triển có bảng riêng ở mục 3.3.

### 3.1. Phân hệ MVP

| Quyền | Mô tả | PA | PO | TA | TO | SO | IE | IA | SV | CA | OR | DS | DA | DO | VW | AU |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PERM-01-read | Xem hồ sơ HTTT | ● | ● | ● | ● | ● | ● | ● | ● | ● | ○ | — | — | ○ | ● | ● |
| PERM-01-create | Tạo hồ sơ HTTT | — | — | ● | — | — | — | — | — | — | ○ | — | — | — | — | — |
| PERM-01-submit | Gửi hồ sơ kết nạp | — | — | ● | — | — | — | — | — | — | ○ | — | — | — | — | — |
| PERM-01-approve | Duyệt kết nạp | — | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-01-credential | Cấp, xoay vòng định danh ứng dụng | — | — | ● | — | — | — | — | — | — | ○ | — | — | — | — | — |
| PERM-01-suspend | Tạm ngừng, thu hồi HTTT | — | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-02-read | Xem danh mục dịch vụ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-02-create / update | Đăng ký, sửa API, gói | — | — | ● | — | — | — | — | ○ | — | — | — | — | — | — | — |
| PERM-02-submit | Gửi duyệt công bố | — | — | ● | — | — | — | — | ○ | — | — | — | — | — | — | — |
| PERM-02-publish | Duyệt và công bố API, gói | — | — | ● | — | — | — | — | — | ● | — | — | — | — | — | — |
| PERM-02-subscribe | Đăng ký sử dụng API cho HTTT | — | — | ● | — | — | — | — | — | — | ○ | — | — | — | — | — |
| PERM-02-approve-subscription | Duyệt đăng ký sử dụng | — | — | ● | — | — | — | — | ○ | ● | — | — | — | — | — | — |
| PERM-02-operate | Start/Stop API | — | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-read | Xem cấu hình gateway, trạng thái nút | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-03-admin | Quản lý chính sách gateway | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-04-read | Xem luồng | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | ● | ● |
| PERM-04-create / update | Thiết kế luồng, chạy thử | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-04-submit | Gửi duyệt phát hành | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-04-publish | Duyệt phát hành, quay lui | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-04-operate | Kích hoạt, tạm dừng luồng, route | — | — | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — |
| PERM-05-read | Xem Kamelet, kết nối | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | ● |
| PERM-05-connection | Khai báo, sửa kết nối nguồn | — | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-05-kamelet-approve | Duyệt Kamelet mới vào danh mục | ● | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-07-read | Xem danh mục dùng chung | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-07-create / update | Soạn, nhập danh mục | ● (COMMON) | — | ● | — | — | — | — | — | — | — | ○ | — | — | — | — |
| PERM-07-submit | Gửi duyệt phát hành | ● (COMMON) | — | ● | — | — | — | — | — | — | — | ○ | — | — | — | — |
| PERM-07-publish | Duyệt phát hành phiên bản | ● (COMMON) | — | — | — | — | — | — | — | — | — | — | ● | — | — | — |
| PERM-07-export | Xuất danh mục | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-07-sync | Chạy đồng bộ danh mục quốc gia | ● | — | ● | — | — | — | — | — | — | — | — | ● | — | — | — |
| PERM-10-read | Xem dự án, topic, sơ đồ kết nối | ● | ● | ● | ● | ● | ● | ● | ● | — | ○ | — | — | ○ | ● | ● |
| PERM-10-create / update | Tạo dự án, topic, schema | — | — | ● | — | — | ● | — | ○ | — | — | — | — | — | — | — |
| PERM-10-approve | Duyệt schema, publication, subscription | — | — | ● | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-10-subscribe | Đăng ký subscriber cho HTTT | — | — | ● | — | — | — | — | — | — | ○ | — | — | — | — | — |
| PERM-12-user-admin | Quản lý người dùng, gán vai trò | ● (PLATFORM) | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-read | Xem người dùng, quyền hiệu lực | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-13-dashboard | Xem bảng điều khiển giám sát | ● | ● | ● | ● | ● | ● | ● | ○ | — | — | — | — | — | ● | ● |
| PERM-13-logs | Tra log, trace | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | ● |
| PERM-13-audit-read | Xem nhật ký kiểm toán | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-13-audit-export | Xuất bằng chứng kiểm toán | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-13-alert-admin | Cấu hình cảnh báo | ● | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — |
| PERM-14-read | Xem danh mục dịch vụ quốc gia | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | — | — | — | ● | ● |
| PERM-14-admin | Cấu hình kết nối NDXP | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-18-dlq | Xem, xử lý lại, bỏ bản tin lỗi | — | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-18-config | Sửa tham số cấu hình | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-18-migration | Chạy công cụ di trú | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-20-admin | Khởi tạo, cấu hình, tạm ngừng, sáp nhập tenant | ● | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-20-read | Xem thông tin, hạn mức tenant | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — | ● |

Khi khai thác dữ liệu Nhạy cảm, mọi vai trò cần thêm `PERM-09-unmask` (mục 3.2) để xem giá trị đầy đủ; nếu không, giá trị luôn bị che kể cả với vai trò có quyền `read`.

### 3.2. Phân hệ đợt 2 và đợt 3

| Quyền | Mô tả | Vai trò được phép |
|---|---|---|
| PERM-06-read / update / merge | Xem, sửa, hợp nhất dữ liệu chủ | DS (○), TA; merge cần DA |
| PERM-08-rule-admin | Quản lý quy tắc chất lượng | DS, TA |
| PERM-09-classify | Gán phân loại dữ liệu cho trường | TA, SO, DO (○) |
| PERM-09-purpose-approve | Chấp thuận khai thác dữ liệu theo mục đích | DO (○) |
| PERM-09-unmask | Xem giá trị đầy đủ của trường Nhạy cảm, bắt buộc nêu lý do | SO, DO (○), cấp riêng cho từng người theo quyết định |
| PERM-11-model | Thiết kế, phát hành mô hình quy trình | TA, IA |
| PERM-11-task | Xử lý việc được giao trong quy trình | Mọi người dùng được giao việc |
| PERM-15-portal-admin | Quản trị nội dung cổng nhà phát triển | TA, CA |
| PERM-16-read | Xem báo cáo chỉ tiêu | TA, VW, AU |
| PERM-16-admin | Định nghĩa chỉ tiêu | TA |
| PERM-17-use | Dùng trợ lý AI | Mọi vai trò có `read` tương ứng; trợ lý chỉ trả lời trong phạm vi quyền của người hỏi |
| PERM-17-admin | Bật tắt, cấu hình trợ lý theo tenant | TA |

### 3.3. Thanh toán (PH-19)

Bốn mươi tám quyền và ma trận dưới đây lấy nguyên từ khung truy vết PH-19 ([D02-03-PH19-00 §13](frs/D02-03-PH19-00-khung-truy-vet.md)), thay tám quyền gộp của bản 0.1 (`provider-admin`, `service-admin`, `reconcile`, `refund-request`, `dashboard`…). Cột FR ghi ba chữ số cuối của `FR-19-nnn`. Cột vai trò: PA = PLATFORM_ADMIN, TA = TENANT_ADMIN, PAD = PAYMENT_ADMIN, PAP = PAYMENT_APPROVER, PAC = PAYMENT_ACCOUNTANT, POP = PAYMENT_OPERATOR, AU = AUDITOR, SO = SECURITY_OFFICER, PTN = PARTNER_SYSTEM (client máy-máy). Tỉnh được thu hẹp, không được mở rộng các ô của quyền phê duyệt; quy tắc tách nhiệm động của PH-19 nằm ở khung §13.4 và được kiểm ở D05-02-PH19 TS-19-33.

| Quyền | Mô tả | FR | PA | TA | PAD | PAP | PAC | POP | AU | SO | PTN |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PERM-19-provider-read | Xem nhà cung cấp: danh sách, chi tiết, sức khỏe, siêu dữ liệu thông tin xác thực, kết quả kiểm tra | 007, 008, 011 | — | — | ● | ● | ● | ● | ● | ● | — |
| PERM-19-provider-write | Khai báo, sửa nhà cung cấp: tạo, sửa, gửi đề nghị kích hoạt | 001, 005, 009 | — | — | ● | — | — | — | — | — | — |
| PERM-19-provider-test | Kiểm tra nhà cung cấp: kiểm tra kết nối, giao dịch thử | 003, 004 | — | — | ● | — | — | — | — | — | — |
| PERM-19-provider-activate | Duyệt kích hoạt, ngừng hẳn nhà cung cấp: quyết định đề nghị `PROVIDER_ACTIVATE`, `PROVIDER_RETIRE` | 005, 010 | — | — | — | ● | — | — | — | — | — |
| PERM-19-provider-suspend | Tạm dừng, mở lại nhà cung cấp: kể cả tạm dừng khẩn cấp khi lộ khóa | 006 | — | — | ● | — | — | — | — | ● | — |
| PERM-19-provider-delete | Xóa, đề nghị ngừng hẳn nhà cung cấp: xóa cứng `DRAFT`; lập đề nghị `RETIRE` | 010 | — | — | ● | — | — | — | — | — | — |
| PERM-19-credential-manage | Quản lý thông tin xác thực nhà cung cấp: gắn tham chiếu bí mật, xoay khóa, chứng thư | 002, 012 | — | — | ● | — | — | — | — | ● | — |
| PERM-19-service-read | Xem dịch vụ, nhóm dịch vụ | 013, 014 | — | — | ● | ● | ● | ● | ● | — | — |
| PERM-19-service-write | Quản lý dịch vụ, nhóm dịch vụ: thêm, sửa, xóa nhóm; thêm, sửa dịch vụ | 013, 014 | — | — | ● | — | — | — | — | — | — |
| PERM-19-service-activate | Điều khiển vòng đời dịch vụ: kích hoạt, tạm dừng, ngừng hẳn, xóa cứng dịch vụ | 015 | — | — | ● | — | — | — | — | — | — |
| PERM-19-partner-read | Xem đối tác: hồ sơ, client, dịch vụ được gán, webhook | 017 | — | — | ● | ● | ● | ● | ● | ● | — |
| PERM-19-partner-write | Quản lý hồ sơ đối tác: thêm, sửa, gán dịch vụ và hạn mức, lập đề nghị duyệt, chấm dứt | 017, 018, 020 | — | — | ● | — | — | — | — | — | — |
| PERM-19-partner-approve | Duyệt đối tác: quyết định đề nghị `PARTNER_ONBOARD`, `PARTNER_TERMINATE` | 018 | — | — | — | ● | — | — | — | — | — |
| PERM-19-partner-suspend | Tạm dừng, mở lại đối tác | 018 | — | — | ● | ● | — | — | — | — | — |
| PERM-19-partner-client-manage | Cấp, thu hồi client đối tác | 019 | — | — | ● | — | — | — | — | ● | — |
| PERM-19-partner-webhook-manage | Quản lý webhook đối tác: thêm, sửa, gửi thử, xoay bí mật | 021 | — | — | ● | — | — | — | — | — | — |
| PERM-19-partner-pay-create | Đối tác tạo, hủy giao dịch: gán cho client máy-máy; gồm lớp tương thích | 022, 026, 033, 067 | — | — | — | — | — | — | — | — | ● |
| PERM-19-partner-pay-read | Đối tác truy vấn: giao dịch, hoàn tiền, dịch vụ được gán, thông báo của chính đối tác | 035, 041 | — | — | — | — | — | — | — | — | ● |
| PERM-19-partner-refund-create | Đối tác lập yêu cầu hoàn | 038 | — | — | — | — | — | — | — | — | ● |
| PERM-19-partner-recon-read | Đối tác tải kết quả đối soát: chỉ phần của chính đối tác, phiên đã chốt | 048 | — | — | — | — | — | — | — | — | ● |
| PERM-19-transaction-read | Xem giao dịch: danh sách, tra cứu, chi tiết (dữ liệu cá nhân bị che) | 049, 050, 051 | — | — | ● | ● | ● | ● | ● | — | — |
| PERM-19-transaction-read-pii | Xem dữ liệu cá nhân người nộp: bỏ che; mỗi lần xem ghi kiểm toán (BR-19-031) | 051 | — | — | — | — | ● | ● | ● | — | — |
| PERM-19-transaction-cancel | Hủy giao dịch: hủy giao dịch chưa thanh toán thay đối tác | 026 | — | — | — | — | — | ● | — | — | — |
| PERM-19-transaction-sync | Đồng bộ trạng thái thủ công | 037 | — | — | — | — | ● | ● | — | — | — |
| PERM-19-transaction-export | Xuất danh sách giao dịch | 052 | — | — | — | — | ● | — | ● | — | — |
| PERM-19-callback-read | Xem IPN: danh sách, nguyên văn đã che | 032 | — | — | — | — | ● | ● | ● | ● | — |
| PERM-19-callback-replay | Xử lý lại IPN | 032 | — | — | — | — | — | ● | — | — | — |
| PERM-19-refund-read | Xem yêu cầu hoàn | 041 | — | — | — | ● | ● | ● | ● | — | — |
| PERM-19-refund-create | Lập yêu cầu hoàn: lập, rút yêu cầu; tải tài liệu | 038 | — | — | — | — | ● | — | — | — | — |
| PERM-19-refund-approve | Duyệt hoàn tiền: quyết định đề nghị `REFUND` cấp 1, cấp 2 | 039 | — | — | — | ● | — | — | — | — | — |
| PERM-19-refund-execute | Thực thi hoàn tiền: thực thi lại, chuyển thủ công, ghi nhận chứng từ | 040 | — | — | — | — | ● | — | — | — | — |
| PERM-19-recon-run | Chạy đối soát: tạo phiên thủ công, thu thập lại, chạy lại so khớp | 042, 044 | — | — | — | — | ● | — | — | — | — |
| PERM-19-recon-upload | Tải file đối soát | 043 | — | — | — | — | ● | — | — | — | — |
| PERM-19-recon-close | Chốt, đề nghị mở lại phiên | 047 | — | — | — | — | ● | — | — | — | — |
| PERM-19-recon-reopen-approve | Duyệt mở lại phiên: quyết định đề nghị `RECON_REOPEN` | 047 | — | — | — | ● | — | — | — | — | — |
| PERM-19-discrepancy-read | Xem đối soát và chênh lệch: phiên, dòng đối soát, chênh lệch (phạm vi gồm cả dữ liệu phiên đối soát) | 042, 044, 045 | — | — | — | ● | ● | ● | ● | — | — |
| PERM-19-discrepancy-handle | Xử lý chênh lệch: giao việc, chuyển cấp, ghi chú, đề xuất cách xử lý | 045, 046 | — | — | — | — | ● | — | — | — | — |
| PERM-19-discrepancy-approve | Duyệt xử lý chênh lệch: quyết định đề nghị `DISCREPANCY_RESOLUTION` | 046 | — | — | — | ● | — | — | — | — | — |
| PERM-19-report-read | Xem báo cáo | 058 | — | — | ● | ● | ● | — | ● | — | — |
| PERM-19-report-export | Xuất báo cáo, biên bản: xuất báo cáo, sinh và tải biên bản đối soát | 048, 058 | — | — | — | — | ● | — | ● | — | — |
| PERM-19-dashboard-read | Xem dashboard | 056, 057 | — | — | ● | ● | ● | ● | ● | ● | — |
| PERM-19-log-read | Xem nhật ký tích hợp: nhật ký tích hợp và liên kết vết | 054, 055 | — | — | — | — | — | ● | ● | ● | — |
| PERM-19-webhook-read | Xem lượt gửi webhook | 062 | — | — | ● | — | — | ● | ● | — | — |
| PERM-19-webhook-resend | Gửi lại webhook | 062 | — | — | — | — | — | ● | — | — | — |
| PERM-19-config-read | Xem cấu hình thanh toán | 063 | ● | ● | ● | — | — | — | ● | — | — |
| PERM-19-config-write | Sửa cấu hình thanh toán: tạo phiên bản cấu hình mới | 063 | — | — | ● | — | — | — | — | — | — |
| PERM-19-migration-run | Chạy di trú, đối chiếu: lô nhập, đối chiếu sau di trú, xem kết quả | 065, 068 | — | — | ● | — | ● | — | — | — | — |
| PERM-19-migration-switch | Đổi chế độ định tuyến: lập và quyết định đề nghị `ROUTING_MODE_CHANGE` (người lập ≠ người duyệt) | 066 | — | — | ● | ● | — | — | — | — | — |

### 3.4. Nhà phát triển

| Quyền | Mô tả | DEVELOPER |
|---|---|---|
| PERM-15-app | Quản lý ứng dụng sandbox, xem thông tin xác thực của ứng dụng được giao | ● |
| PERM-15-try | Thử API trên sandbox | ● |

## 4. Tách nhiệm vụ

Bảng dưới đây liệt kê các cặp vai trò không được gán cùng lúc cho một người trong cùng tenant. PH-12 chặn khi gán; trường hợp tỉnh thiếu nhân sự phải có quyết định ngoại lệ được ghi kiểm toán và có thời hạn.

| Vai trò A | Vai trò B | Lý do |
|---|---|---|
| INTEGRATION_ENGINEER | INTEGRATION_APPROVER | Người thiết kế không tự duyệt phát hành |
| SERVICE_OWNER | CATALOG_APPROVER | Chủ dịch vụ không tự duyệt công bố |
| DATA_STEWARD | DATA_APPROVER | Người soạn danh mục không tự duyệt phát hành |
| PAYMENT_ACCOUNTANT | PAYMENT_APPROVER | Người lập hoàn tiền, đề xuất xử lý chênh lệch không tự duyệt (tỉnh thiếu người được gán kèm cảnh báo, quy tắc động vẫn chặn, khung PH-19 §13.4) |
| TENANT_ADMIN | AUDITOR | Người quản trị không tự kiểm toán mình |
| PAYMENT_ADMIN | PAYMENT_APPROVER | Người cấu hình kênh không duyệt kích hoạt kênh (như dòng trên) |
| AUDITOR | mọi vai trò có quyền ghi của PH-19 | Độc lập kiểm toán (khung PH-19 §13.4 quy tắc 7) |

Ngoài tách vai trò, nguyên tắc bốn mắt (FR-00-071) vẫn áp dụng cho từng đối tượng.

## 5. Quyền của HTTT thành viên (máy)

HTTT gọi Datahub bằng token `client_credentials` hoặc mTLS. Token mang phạm vi (scope) được sinh tự động từ dữ liệu đã duyệt, không cấp tay.

| Scope | Ý nghĩa | Được cấp khi |
|---|---|---|
| `api:{mã API}:{mã gói}` | Gọi API theo gói sử dụng | Đăng ký sử dụng được duyệt ở PH-02 |
| `purpose:{mã mục đích}` | Khai thác dữ liệu theo mục đích | Chủ quản dữ liệu chấp thuận ở PH-09 (đợt 2); trong MVP, gắn với đăng ký sử dụng |
| `topic:{tên topic}:publish` / `:subscribe` | Phát hoặc nhận sự kiện | Publication / subscription được duyệt ở PH-10 |
| `rdm:read` | Tra cứu danh mục dùng chung | Mặc định cho mọi HTTT `ACTIVE` |
| `payment:create` | Tạo yêu cầu thanh toán | HTTT được khai báo là đối tác ở PH-19 |

## 6. Ánh xạ từ quyền của hệ cũ

| Hệ cũ | Datahub |
|---|---|
| `Project_group.access_level` (Bus) | Phạm vi không gian làm việc PH-04 với INTEGRATION_ENGINEER / VIEWER |
| Plan "Define: nhóm được phép truy cập" (APIM) | Điều kiện đăng ký sử dụng của gói (PH-02) |
| Vai trò Keycloak tự đặt ở từng khối | Vai trò chuẩn ở mục 2, gán lại khi di trú người dùng |

## 7. Kiểm thử

D05-01 sinh tự động từ ma trận mục 3 hai nhóm ca kiểm thử cho mỗi API: một ca dương với vai trò có ● hoặc ○, một ca âm với một vai trò có —. Ca ○ có thêm một ca âm với đối tượng của tổ chức khác. Kỳ vọng ca âm là `403` khi người dùng biết đối tượng tồn tại trong phạm vi của mình, và `404` khi đối tượng thuộc tổ chức hoặc tenant khác.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-21 | Bản đầu |
| 0.2 | 2026-11-26 | Mục 3.3 thay bằng 48 quyền và ma trận của khung PH-19 §13; vai trò thanh toán đổi `PAYMENT_OFFICER` thành `PAYMENT_ACCOUNTANT`, thêm `PAYMENT_OPERATOR`, `PARTNER_SYSTEM`; tách mục 3.4 cho nhà phát triển |
