---
ma_tai_lieu: D02-08
ten: Ma trận phân quyền
phien_ban: 0.1
ngay: 2026-11-21
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
| ROLE-PAYMENT_ADMIN | Quản trị thanh toán | Tenant | Có | Quản lý nhà cung cấp, đối tác, dịch vụ thanh toán; kích hoạt, dừng kênh |
| ROLE-PAYMENT_OFFICER | Cán bộ đối soát | Tenant | Có | Tra cứu giao dịch, đối soát, đề nghị hoàn tiền |
| ROLE-PAYMENT_APPROVER | Người duyệt hoàn tiền | Tenant | Có | Duyệt hoàn tiền, duyệt xử lý giao dịch lệch |
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

### 3.3. Thanh toán và nhà phát triển

| Quyền | Mô tả | PAYMENT_ADMIN | PAYMENT_OFFICER | PAYMENT_APPROVER | TA | AU | DEVELOPER |
|---|---|---|---|---|---|---|---|
| PERM-19-provider-admin | Thêm, sửa, kích hoạt, dừng nhà cung cấp và kênh | ● | — | — | — | — | — |
| PERM-19-service-admin | Quản lý đối tác, nhóm dịch vụ, dịch vụ | ● | — | — | ● | — | — |
| PERM-19-transaction-read | Tra cứu giao dịch, xem chi tiết | ● | ● | ● | ● | ● | — |
| PERM-19-transaction-export | Xuất giao dịch | ● | ● | — | — | ● | — |
| PERM-19-reconcile | Chạy đối soát, xử lý giao dịch lệch | — | ● | — | — | — | — |
| PERM-19-refund-request | Đề nghị hoàn tiền | — | ● | — | — | — | — |
| PERM-19-refund-approve | Duyệt hoàn tiền, duyệt xử lý lệch | — | — | ● | — | — | — |
| PERM-19-dashboard | Xem dashboard thanh toán | ● | ● | ● | ● | ● | — |
| PERM-15-app | Quản lý ứng dụng sandbox, xem thông tin xác thực của ứng dụng được giao | — | — | — | — | — | ● |
| PERM-15-try | Thử API trên sandbox | — | — | — | — | — | ● |

## 4. Tách nhiệm vụ

Bảng dưới đây liệt kê các cặp vai trò không được gán cùng lúc cho một người trong cùng tenant. PH-12 chặn khi gán; trường hợp tỉnh thiếu nhân sự phải có quyết định ngoại lệ được ghi kiểm toán và có thời hạn.

| Vai trò A | Vai trò B | Lý do |
|---|---|---|
| INTEGRATION_ENGINEER | INTEGRATION_APPROVER | Người thiết kế không tự duyệt phát hành |
| SERVICE_OWNER | CATALOG_APPROVER | Chủ dịch vụ không tự duyệt công bố |
| DATA_STEWARD | DATA_APPROVER | Người soạn danh mục không tự duyệt phát hành |
| PAYMENT_OFFICER | PAYMENT_APPROVER | Người đề nghị hoàn tiền không tự duyệt |
| TENANT_ADMIN | AUDITOR | Người quản trị không tự kiểm toán mình |
| PAYMENT_ADMIN | PAYMENT_APPROVER | Người cấu hình kênh không duyệt giao dịch tiền |

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
