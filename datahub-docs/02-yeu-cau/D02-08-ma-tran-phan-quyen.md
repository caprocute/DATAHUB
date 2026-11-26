---
ma_tai_lieu: D02-08
ten: Ma trận phân quyền
phien_ban: 0.4
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Phân tích nghiệp vụ, Kiến trúc sư, Đội phát triển, Kiểm thử, ATTT
mo_ta: Định nghĩa 22 vai trò, các quyền PERM theo phân hệ, ma trận gán quyền, cặp vai trò phải tách nhiệm vụ, scope của HTTT thành viên và ánh xạ từ quyền hệ cũ, làm căn cứ phân quyền và sinh ca kiểm thử.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước; D02-01 BRD; D02-02 SRS; D02-03-PH12 FRS Định danh và phân quyền; D03-07 Thiết kế ATTT; D03-10 Đa tenant; D05-01 Kiểm thử phân quyền
---

# D02-08 · Ma trận phân quyền

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Xác định ai được làm gì trên Datahub bằng một tập vai trò, quyền và ma trận gán quyền duy nhất, để mọi FRS dẫn chiếu cùng một nguồn và kiểm thử sinh được ca phân quyền dương và âm một cách tự động.

**Phạm vi.** 22 vai trò chuẩn, các quyền `PERM-{PH}-{động từ}` của 20 phân hệ, các cặp vai trò phải tách nhiệm vụ, quyền của HTTT thành viên (máy) dạng scope OAuth và ánh xạ từ quyền hệ cũ. Việc đăng nhập, cấp token và quản trị người dùng thuộc PH-12, không thuộc tài liệu này.

**Căn cứ pháp lý.** CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3) về kiểm soát truy cập, xác thực nhiều yếu tố, nhật ký; CMP-LAW-05 (Luật BVDLCN 91/2025) về hạn chế truy cập dữ liệu cá nhân; CMP-LAW-01 (Luật Dữ liệu số) về khai thác dữ liệu theo mục đích; CMP-LAW-03 (NĐ 278/2025) về kết nối, chia sẻ dữ liệu.

**Những điểm hội đồng cần lưu ý.** (1) Phân quyền ba lớp được OPA đánh giá cùng lúc: vai trò, phạm vi tổ chức và thuộc tính dữ liệu (ADR-006). (2) Từ chối mặc định: quyền không có trong ma trận là không được phép. (3) Quyền duyệt không áp dụng cho đối tượng do chính người dùng tạo hoặc gửi (bốn mắt, FR-00-071), và các cặp vai trò xung đột bị PH-12 chặn khi gán. (4) HTTT thành viên không có vai trò người dùng, quyền của máy là scope sinh tự động từ dữ liệu đã duyệt. (5) Vai trò quản trị, duyệt, an ninh, kiểm toán bắt buộc xác thực hai yếu tố.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Vai trò chuẩn | 22 (ROLE-*) |
| Họ quyền theo phân hệ | 20 phân hệ PH-01…PH-20 |
| Quyền thanh toán PH-19 | 48 quyền theo khung PH-19 §13 |
| Cặp vai trò tách nhiệm vụ | 7 cặp ở mục 4 |
| Loại scope của máy | 6 nhóm scope ở mục 5 |

: Con số chính của ma trận phân quyền

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

### 1.1. Sơ đồ mô hình phân quyền

Sơ đồ dưới đây gom ba lớp phân quyền thành một dòng đánh giá: người dùng mang vai trò, vai trò mở ra quyền, và OPA quyết định cuối cùng sau khi kiểm tra phạm vi tenant, tổ chức và thuộc tính dữ liệu.

```{.mermaid caption="Mô hình phân quyền: người dùng, vai trò, quyền, phạm vi tenant và OPA"}
flowchart TB
  U[Người dùng trong realm của tenant] -->|được gán| R[Vai trò ROLE]
  R -->|ma trận ở mục 3| P[Quyền PERM-PH-động từ]
  U -->|thuộc| O[Tổ chức và tổ chức cấp dưới]
  M[HTTT thành viên] -->|token client_credentials| S[Scope OAuth sinh từ dữ liệu đã duyệt]
  P --> OPA{OPA đánh giá}
  O -->|phạm vi tổ chức| OPA
  A[Thuộc tính dữ liệu: mức phân loại, mục đích, trạng thái] -->|ABAC| OPA
  T[Tenant của yêu cầu] -->|tách biệt tenant| OPA
  S --> OPA
  OPA -->|cho phép| OK[Thực hiện thao tác và ghi kiểm toán]
  OPA -->|từ chối mặc định| NO[403 hoặc 404 và ghi kiểm toán]
```

Người đọc cần thấy rằng vai trò chỉ là điều kiện cần. Dù có quyền trong ma trận, yêu cầu vẫn bị từ chối nếu sai tenant, ngoài phạm vi tổ chức hoặc vi phạm thuộc tính dữ liệu; quyền của máy đi theo nhánh scope riêng nhưng cũng qua OPA.

### 1.2. Phạm vi

Tài liệu bao phủ vai trò, quyền, ma trận, tách nhiệm vụ, scope của máy và ánh xạ hệ cũ. Tài liệu không mô tả cách đăng nhập, cấp token, quản trị người dùng (PH-12) và không lặp lại luồng phê duyệt chi tiết của từng phân hệ (FRS phân hệ).

### 1.3. Người đọc và cách đọc

Bảng dưới gợi ý phần nên đọc theo từng nhóm người đọc.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, mục 1, mục 4 | Đánh giá mô hình, tách nhiệm vụ và tuân thủ kiểm soát truy cập |
| Phân tích nghiệp vụ | Mục 2, mục 3 | Gán quyền đúng cho vai trò nghiệp vụ |
| Kiến trúc sư, cán bộ ATTT | Mục 1, mục 4, mục 5 | Xác nhận mô hình OPA, scope máy, tách nhiệm vụ |
| Đội phát triển | Mục 3, mục 5 | Cài chính sách OPA và kiểm tra quyền trong API |
| Kiểm thử viên | Mục 3, mục 7 | Sinh ca phân quyền dương và âm |

: Người đọc và phần cần đọc của ma trận phân quyền

### 1.4. Thuật ngữ và chữ viết tắt

Thuật ngữ chung theo D00-01. Bảng dưới giải thích ký hiệu riêng của tài liệu.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| RBAC, ABAC | Phân quyền theo vai trò, theo thuộc tính |
| OPA | Open Policy Agent, bộ máy đánh giá chính sách phân quyền |
| ROLE-*, PERM-{PH}-{động từ} | Mã vai trò, mã quyền |
| ●, ○, — | Được phép, chỉ với đối tượng của tổ chức mình, không được phép |
| MFA | Xác thực nhiều yếu tố |
| Bốn mắt | Người tạo và người duyệt phải là hai người khác nhau |
| Scope | Phạm vi OAuth của HTTT thành viên (máy) |
| DU | Đơn vị triển khai (xem D03-01); tài khoản dịch vụ của DU là tài khoản máy nội bộ |

: Thuật ngữ và chữ viết tắt của ma trận phân quyền

### 1.5. Tài liệu tham chiếu

Bảng dưới liệt kê tài liệu cung cấp quy ước, nguồn quyền và nơi hiện thực ma trận.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D00-01 | Thuật ngữ và quy ước | Quy ước mã ROLE, PERM |
| D02-02 | SRS | Nhóm FR-00 (MFA, bốn mắt) |
| D02-03-PH12 | FRS Định danh và phân quyền | Hiện thực gán vai trò, chặn cặp xung đột |
| D02-03-PH19-00 | Khung truy vết PH-19 | Nguồn 48 quyền thanh toán |
| D03-07 | Thiết kế an toàn thông tin | Chính sách OPA, kiểm soát truy cập |
| D03-10 | Thiết kế đa tenant | Vai trò chuẩn theo tenant (§5.2) |
| D05-01 | Kiểm thử phân quyền | Sinh ca dương, âm từ ma trận |

: Tài liệu tham chiếu của ma trận phân quyền

### 1.6. Cấu trúc tài liệu

Bảng dưới nêu nội dung từng chương và người đọc chính.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 1 | Mục đích, mô hình ba lớp, giới thiệu | Mọi người đọc |
| 2 | Danh mục 22 vai trò | Phân tích nghiệp vụ |
| 3 | Danh mục quyền và ma trận theo phân hệ | Phân tích nghiệp vụ, đội phát triển, kiểm thử |
| 4 | Tách nhiệm vụ và duyệt bốn mắt | Hội đồng thẩm định, ATTT |
| 5 | Quyền của HTTT thành viên | Kiến trúc sư, đội phát triển |
| 6 đến 7 | Ánh xạ hệ cũ, kiểm thử | Đội phát triển, kiểm thử |

: Cấu trúc tài liệu của ma trận phân quyền

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

: Danh mục 22 vai trò chuẩn, phạm vi và yêu cầu MFA

## 3. Danh mục quyền và ma trận

Quyền viết theo dạng `PERM-{PH}-{động từ}`. Các động từ chuẩn: `read` (xem), `create`, `update`, `delete`, `submit` (gửi duyệt), `approve` (duyệt hoặc từ chối), `publish` (phát hành, công bố), `operate` (kích hoạt, tạm dừng, xử lý lại), `export` (xuất dữ liệu), `admin` (cấu hình phân hệ). Quyền đặc thù được liệt kê riêng.

Ma trận dưới đây dùng ký hiệu: **●** được phép trong phạm vi của vai trò; **○** chỉ với đối tượng thuộc tổ chức của mình; **—** không được phép. Cột vai trò viết tắt: PA = PLATFORM_ADMIN, PO = PLATFORM_OPERATOR, TA = TENANT_ADMIN, TO = TENANT_OPERATOR, SO = SECURITY_OFFICER, IE = INTEGRATION_ENGINEER, IA = INTEGRATION_APPROVER, SV = SERVICE_OWNER, CA = CATALOG_APPROVER, OR = ORG_REQUESTER, DS = DATA_STEWARD, DA = DATA_APPROVER, DO = DATA_OWNER, VW = VIEWER, AU = AUDITOR. Vai trò thanh toán và nhà phát triển có bảng riêng ở mục 3.3.

### 3.1. Phân hệ MVP

Ma trận dưới đây gán quyền cho các vai trò chung ở các phân hệ MVP (PH-01 đến PH-05, 07, 10, 12, 13, 14, 18, 20).

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
| PERM-03-limit | Đặt hạn mức toàn tenant, ghi đè hạn mức theo route | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-03-waf-request | Đề nghị ngoại lệ luật WAF; xem sự kiện chặn của WAF | ● | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-waf-approve | Duyệt, từ chối ngoại lệ luật WAF | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-waf | Đổi chế độ WAF, luật vá ảo, chặn và bỏ chặn địa chỉ, đổi mức hoang tưởng | ● | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-operate | Dừng, mở API; tạm ngừng khẩn cấp route và consumer; quay lui; xác nhận cảnh báo; gia hạn chứng thư | ● | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-publish | Kiểm tra, xây và phát ảnh chụp cấu hình thủ công | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-03-approve | Duyệt yêu cầu thay đổi gateway có bốn mắt (cửa ngoài, hạ hạn mức tenant, đổi chế độ WAF) | — | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-03-log-read | Xem nhật ký lượt gọi chi tiết (có định danh HTTT, đã che dữ liệu nhạy cảm), xuất nhật ký | ● | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-04-read | Xem luồng | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | ● | ● |
| PERM-04-create / update | Thiết kế luồng, chạy thử | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-04-submit | Gửi duyệt phát hành | — | — | — | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-04-publish | Duyệt phát hành, quay lui | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-04-operate | Kích hoạt, tạm dừng luồng, route | — | — | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — |
| PERM-05-read | Xem Kamelet, kết nối | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | ● |
| PERM-05-connection | Khai báo, sửa kết nối nguồn, giá trị và bí mật theo môi trường, cấp kết nối, yêu cầu tài khoản CSDL | — | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-05-kamelet-approve | Duyệt, thu hồi Kamelet (IA: Kamelet của tỉnh; PA: `COMMON` và Kamelet nền) | ● | — | — | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-05-adapter | Tạo, sửa bộ điều hợp, thao tác, cấu hình CDC; gửi duyệt | — | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-05-test | Chạy kiểm tra kết nối, kiểm thử bộ điều hợp, kiểm tra quyền CSDL, điều kiện CDC | — | — | ● | ● | — | ● | ● | — | — | — | — | — | — | — | — |
| PERM-05-operate | Tạm ngừng, tiếp tục, tắt môi trường, xoay bí mật, điều khiển CDC | — | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-05-approve | Duyệt bật giá trị PROD, phiên bản bộ điều hợp, tài khoản ghi CSDL | — | — | — | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-05-db-write-consent | Đồng ý mục đích ghi vào CSDL của HTTT | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-05-kamelet-submit | Soạn, gửi đăng ký Kamelet; đề xuất dùng chung | — | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-05-audit-read | Xem nhật ký truy cập CSDL của luồng, lịch sử xoay bí mật chi tiết | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-05-admin | Tham số PH-05, bật tắt loại kết nối | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-07-read | Xem danh mục dùng chung | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-07-create / update | Soạn, nhập danh mục | ● (COMMON) | — | ● | — | — | — | — | — | — | — | ○ | — | — | — | — |
| PERM-07-submit | Gửi duyệt phát hành | ● (COMMON) | — | ● | — | — | — | — | — | — | — | ○ | — | — | — | — |
| PERM-07-publish | Duyệt phát hành phiên bản | ● (COMMON) | — | — | — | — | — | — | — | — | — | — | ● | — | — | — |
| PERM-07-export | Xuất danh mục | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-07-sync | Chạy đồng bộ danh mục quốc gia | ● | — | ● | — | — | — | — | — | — | — | — | ● | — | — | — |
| PERM-10-read | Xem dự án, topic, sơ đồ kết nối | ● | ● | ● | ● | ● | ● | ● | ● | — | ○ | — | — | ○ | ● | ● |
| PERM-10-create | Tạo dự án, topic, phiên bản lược đồ, bên phát, bên nhận; đề nghị publication; nhập khai báo; gửi duyệt | — | — | ● | — | — | ● | — | ○ | — | — | — | — | — | — | — |
| PERM-10-update | Sửa dự án, topic (phần không cần duyệt), lược đồ nháp, bên phát, bên nhận; ngừng topic | — | — | ● | — | — | ● | — | ○ | — | — | — | — | — | — | — |
| PERM-10-approve | Duyệt, từ chối: tạo topic, thay đổi cấu hình, phiên bản lược đồ, publication, subscription, lượt phát lại | — | — | ● | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-10-subscribe | Đề nghị, sửa, thu hồi subscription cho HTTT và luồng | — | — | ● | — | — | ● | — | — | — | ○ | — | — | — | — | — |
| PERM-10-operate | Tạm dừng, tiếp tục subscription, publication; xoay khóa ký; xử lý DLQ; đề nghị phát lại; xác nhận cảnh báo lag (SO chỉ tạm ngừng khi sự cố) | — | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-10-admin | Tham số `10.*`, danh mục kiểu giao tiếp và chế độ định tuyến, hạn mức, Kafka ngoài, di trú Pulsar, topic nền tảng `dh.` (chỉ PA) | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-user-admin | Quản lý người dùng, gán vai trò | ● (PLATFORM) | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-read | Xem người dùng, quyền hiệu lực | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-12-user-lock | Khóa, mở khóa, vô hiệu, kích hoạt lại tài khoản; buộc đăng xuất; thu hồi truy cập tức thời của người dùng hoặc client; tạm ngừng, tiếp tục client | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-mfa-reset | Đặt lại yếu tố thứ hai của người dùng cấp dưới (quản trị cấp trên) | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-sod-exception | Đề nghị ngoại lệ tách nhiệm vụ có thời hạn | — | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-approve | Duyệt, từ chối, thu hồi ngoại lệ tách nhiệm vụ; duyệt kích hoạt liên kết định danh ngoài (LDAP/AD, SAML, VNeID); duyệt đặt lại yếu tố thứ hai của tài khoản quản trị | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-client | Xem chi tiết, sửa, xoay bí mật, đăng ký chứng thư và khóa công khai của client; xem scope | — | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-policy-edit | Soạn, kiểm thử, chạy khô, gửi duyệt chính sách (PA: chính sách nền tảng; SO: chính sách của tỉnh) | ● | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-policy-approve | Duyệt, từ chối, thu hồi, quay lui chính sách (khác người soạn) | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-decision-read | Tra cứu nhật ký quyết định ủy quyền và sự kiện an ninh (PO chỉ trong phạm vi quyền có thời hạn) | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-12-jit-request | Đề nghị quyền có thời hạn cho vai trò đặc quyền hoặc truy cập tenant khác | ● | ● | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-jit-approve | Duyệt, từ chối, thu hồi quyền có thời hạn (người thứ hai) | ● | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-recert | Mở, theo dõi, đóng chiến dịch rà soát quyền | — | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-alert | Xem, xác nhận cảnh báo an ninh; tinh chỉnh ngưỡng quy tắc phát hiện trong miền cho phép | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-12-admin | Tham số phân hệ `12.*` trong trần của nền tảng; khai báo liên kết LDAP/AD, SAML, VNeID của tenant | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-12-realm-admin | Xem trạng thái, đối chiếu, tạm ngừng, khôi phục realm của tenant | ● | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-13-dashboard | Xem bảng điều khiển giám sát | ● | ● | ● | ● | ● | ● | ● | ○ | — | — | — | — | — | ● | ● |
| PERM-13-logs | Tra log, trace | ● | ● | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | ● |
| PERM-13-audit-read | Xem nhật ký kiểm toán | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-13-audit-export | Xuất bằng chứng kiểm toán | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-13-alert-admin | Cấu hình cảnh báo | ● | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — |
| PERM-13-alert-ack | Xác nhận, đánh dấu đã xử lý, tạm ẩn cảnh báo | ● | ● | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-13-security | Xem và xử lý cảnh báo an ninh; tinh chỉnh ngưỡng luật phát hiện; lập báo cáo sự cố | ● | — | ● | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-13-admin | Tham số `13.*`, mục tiêu SIEM, bộ dashboard, hạn mức quan sát | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-14-read | Xem danh mục dịch vụ quốc gia | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | — | — | — | ● | ● |
| PERM-14-admin | Cấu hình kết nối NDXP | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-14-service | Khai báo, sửa dịch vụ, hợp đồng, đặc tả, cung cấp lại, đối chiếu danh mục dịch vụ | ● | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-14-route | Tạo, sửa luật định tuyến, gửi duyệt | — | — | ● | — | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-14-approve | Duyệt bật nền tảng, luật định tuyến, hạn mức PROD, kích hoạt chứng thư | ● | — | ● | — | — | — | ● | — | — | — | — | — | — | — | — |
| PERM-14-cert | Nạp, yêu cầu kích hoạt, thu hồi chứng thư; làm mới chuỗi tin cậy, danh sách thu hồi | ● | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-14-quota | Khai báo hạn mức, phân bổ hạn mức nội bộ theo HTTT | — | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-14-operate | Tạm ngừng, tiếp tục nền tảng, dịch vụ; vô hiệu đệm; ngắt mạch tay; thử kết nối; xoay thông tin xác thực; xử lý sự cố chữ ký | ● | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-14-sync | Cấu hình, chạy, thử lại đồng bộ danh mục dịch vụ, dữ liệu chủ, dữ liệu mở | ● | — | ● | ● | — | — | — | — | — | — | — | — | — | — | — |
| PERM-14-audit-read | Tra giao dịch, nhật ký khai thác, báo cáo sử dụng, cảnh báo bất thường (nội dung đã che) | — | — | ● | ● | ● | — | — | — | — | — | — | — | — | — | ● |
| PERM-14-audit-reveal | Xem nội dung bản tin đầy đủ có lý do, xuất bằng chứng | — | — | — | — | ● | — | — | — | — | — | — | — | — | — | — |
| PERM-14-invoke | Gọi dịch vụ quốc gia đã cung cấp lại (chỉ client máy, theo scope) | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-18-dlq | Xem, xử lý lại, bỏ bản tin lỗi | — | ● | ● | ● | — | ● | — | — | — | — | — | — | — | — | — |
| PERM-18-config | Sửa tham số cấu hình | ● | — | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-18-migration | Chạy công cụ di trú | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-20-admin | Khởi tạo, cấu hình, tạm ngừng, sáp nhập tenant | ● | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| PERM-20-read | Xem thông tin, hạn mức tenant | ● | ● | ● | — | — | — | — | — | — | — | — | — | — | — | ● |

: Ma trận vai trò theo quyền của các phân hệ MVP PH-01…PH-05, 07, 10, 12, 13, 14, 18, 20

Khi khai thác dữ liệu Nhạy cảm, mọi vai trò cần thêm `PERM-09-unmask` (mục 3.2) để xem giá trị đầy đủ; nếu không, giá trị luôn bị che kể cả với vai trò có quyền `read`.

### 3.2. Phân hệ đợt 2 và đợt 3

Bảng dưới gán quyền cho các phân hệ PH-06, 08, 09, 11, 15, 16, 17, theo dạng liệt kê vai trò được phép.

| Quyền | Mô tả | Vai trò được phép |
|---|---|---|
| PERM-06-read | Xem domain, nguồn, quy tắc, bản ghi vàng (đã che), ứng viên, nguồn gốc, dashboard dữ liệu chủ | PA, TA, TO, SO, DS, DA, DO (○), VW, AU |
| PERM-06-update | Sửa tay thuộc tính bản ghi vàng, xử lý ứng viên lỗi, gỡ liên kết | TA, DS (○) |
| PERM-06-merge | Hợp nhất, tách, hoàn tác, ngừng, khôi phục bản ghi vàng; hợp nhất rủi ro cao cần DA duyệt | TA, DS (○), DA |
| PERM-06-config | Soạn mô hình domain, nguồn, ưu tiên nguồn, quy tắc đối sánh và sống sót, gửi duyệt | PA (gói nền), TA, DS (○) |
| PERM-06-approve | Duyệt mô hình, quy tắc, ưu tiên nguồn, hợp nhất rủi ro cao, hoàn tác quá hạn | DA |
| PERM-06-steward | Nhận, xử lý, phân công mục hàng đợi dữ liệu chủ; quản lý tập nhãn | TA, DS, DA |
| PERM-06-ingest | Nạp tệp lô, chạy lại xử lý ứng viên | TA, DS (○) |
| PERM-06-export | Đề nghị xuất dữ liệu chủ; DO, DA chấp thuận | TA, DS (○), DA, DO (○) |
| PERM-06-sync | Chạy, tạm dừng đồng bộ quốc gia, xử lý lệch | TA, DS, DA |
| PERM-06-operate | Lập lịch, chạy lại, hủy job dữ liệu chủ | TA, TO |
| PERM-06-dsr | Tiếp nhận, xử lý yêu cầu của chủ thể dữ liệu đối với dữ liệu chủ | TA, SO, DS |
| PERM-06-audit-read | Xem nhật ký truy cập dữ liệu chủ | SO, AU |
| PERM-08-read | Xem bảng điều khiển, thẻ điểm, đối tượng đo, quy tắc, lần đo, báo cáo chất lượng đã công bố | PA, TA, TO, SO, DS, DA, DO (○), VW (chỉ tổng hợp), AU |
| PERM-08-asset | Khai báo miền chất lượng, đối tượng đo, phần tử dữ liệu trọng yếu, chạy hồ sơ dữ liệu | TA, DS |
| PERM-08-rule-admin | Soạn quy tắc chất lượng, trọng số, ngưỡng, quy tắc cảnh báo, gửi duyệt | PA (mẫu `COMMON`), TA, DS |
| PERM-08-approve | Duyệt bộ quy tắc, trọng số và ngưỡng, ngoại lệ chấp nhận, công bố báo cáo chất lượng | DA |
| PERM-08-run | Lập lịch, chạy, hủy, chạy lại lần đo chất lượng | TA, TO, DS |
| PERM-08-finding-read | Xem chi tiết bản ghi lỗi chất lượng (giá trị đã che) | SO, DS, DA, DO (○, tổ chức mình) |
| PERM-08-remediate | Nhận, xử lý, cập nhật phiếu khắc phục chất lượng | TA, DS, DO (○) |
| PERM-08-report | Soạn, sinh, xuất báo cáo chất lượng | TA, DS |
| PERM-08-export | Xuất bản ghi lỗi; có trường Nhạy cảm cần DO chấp thuận | DS, DA |
| PERM-08-config | Tham số chất lượng theo tenant, lưu giữ | PA (trần), TA |
| PERM-08-audit-read | Xem nhật ký kiểm toán PH-08 | SO, AU |
| PERM-09-read | Xem danh mục, sổ, chính sách, bundle, báo cáo (đã che) | PA, TA, TO, SO, DS, DA, DO (○), VW, AU |
| PERM-09-classify | Đề xuất, xác nhận phân loại; nhãn chặn; quét | TA, SO, DS (○), DO (○), SV (○) |
| PERM-09-ropa | Soạn, duyệt sổ hoạt động xử lý và DPIA | TA, SO, DS (○), DA, DO (○) |
| PERM-09-purpose-request | Lập yêu cầu khai thác theo mục đích | TA, OR (○), SV (○) |
| PERM-09-purpose-approve | Chấp thuận, tạm dừng, thu hồi; duyệt khôi phục cấp một | DO (○) |
| PERM-09-policy | Soạn chính sách che, miền giả danh, mẫu che, cấu hình che log | TA, SO, DS (○) |
| PERM-09-policy-approve | Duyệt chính sách, lịch lưu giữ, cấu hình ẩn danh, xoay hoặc hủy khóa, mẫu đồng ý, xóa mật mã | TA, SO, DA |
| PERM-09-unmask | Xem giá trị đầy đủ có lý do, 60 giây | SO, DO (○), cấp riêng cho từng người theo quyết định |
| PERM-09-reidentify | Đề nghị và thực hiện khôi phục giá trị gốc từ token | SO |
| PERM-09-anonymize | Cấu hình, chạy ẩn danh hóa, chuẩn bị dữ liệu, phát hành tập | TA, SO, DS (○) |
| PERM-09-retention | Lịch lưu giữ, tác vụ xóa, giữ pháp lý, đề nghị xóa mật mã | TA, SO, DS (○) |
| PERM-09-dsr | Tiếp nhận, xử lý yêu cầu của chủ thể | TA, SO, DS |
| PERM-09-consent | Quản lý mẫu, bản ghi đồng ý | TA, SO, DS (○) |
| PERM-09-breach | Ghi nhận, xử lý vi phạm DLCN | TA, TO, SO |
| PERM-09-audit-read | Xem nhật ký bảo vệ dữ liệu, lịch sử xem đầy đủ | PA, SO, AU |
| PERM-09-config | Tham số `09.*`, ngưỡng cảnh báo, lịch báo cáo | PA (trần), TA |
| PERM-11-read | Xem mô hình, phiên, việc quy trình trong phạm vi | TA, TO, IE, IA, AU, VW |
| PERM-11-model | Soạn mô hình quy trình, gửi duyệt phát hành (mẫu `COMMON` do PA soạn) | TA, IE, PA |
| PERM-11-publish | Duyệt phát hành, ngừng dùng, thu hồi phiên bản mô hình (bốn mắt, khác người gửi) | TA, IA |
| PERM-11-instance | Khởi tạo thủ công, tạm dừng, tiếp tục, hủy phiên quy trình | TA, TO |
| PERM-11-instance-admin | Sửa biến, chuyển bước, di trú phiên (bốn mắt) | TA |
| PERM-11-task | Xử lý việc được giao trong quy trình | Mọi người dùng được giao việc |
| PERM-11-task-admin | Phân công lại, giao lại việc hàng loạt | TA, TO |
| PERM-11-compensate | Kích hoạt, xử lý bù trừ thủ công; xử lý sự cố engine | TA, TO |
| PERM-11-config | Lịch làm việc, tham số `11.*`, chính sách lưu giữ (PA đặt trần ở `COMMON`) | TA, PA |
| PERM-11-audit-read | Xem lịch sử bước đầy đủ, xuất bằng chứng tuân thủ | TA, AU |
| PERM-15-portal-admin | Quản trị nội dung cổng nhà phát triển | TA, CA |
| PERM-15-content-write | Soạn, sửa, gửi duyệt trang nội dung cổng; nhập từ Git | TA, CA, SV (○) |
| PERM-15-content-publish | Duyệt, đăng, gỡ trang nội dung cổng (người soạn không tự duyệt) | TA, CA |
| PERM-15-support | Xử lý hỏi đáp, phiếu hỗ trợ của dịch vụ trên cổng | TA, CA, SV (○) |
| PERM-15-dev-approve | Duyệt, từ chối, khóa, mở khóa tài khoản `dh-dev` và ứng dụng sandbox | TA, SO, PA |
| PERM-15-audit-read | Xem nhật ký truy cập, thử API và báo cáo sử dụng cổng | TA, SO, AU, PA |
| PERM-16-read | Xem báo cáo chỉ tiêu | TA, VW, AU |
| PERM-16-admin | Định nghĩa chỉ tiêu | TA |
| PERM-17-use | Dùng trợ lý AI | Mọi vai trò có `read` tương ứng; trợ lý chỉ trả lời trong phạm vi quyền của người hỏi |
| PERM-17-admin | Bật tắt, cấu hình trợ lý theo tenant | TA |

: Quyền và vai trò được phép của các phân hệ PH-06, 08, 09, 11, 15, 16, 17

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

: Ma trận 48 quyền thanh toán PH-19 theo vai trò

### 3.4. Nhà phát triển

Vai trò nhà phát triển chỉ có hai quyền của cổng nhà phát triển PH-15, giới hạn trong ứng dụng được giao.

| Quyền | Mô tả | DEVELOPER |
|---|---|---|
| PERM-15-app | Quản lý ứng dụng sandbox, xem thông tin xác thực của ứng dụng được giao | ● |
| PERM-15-try | Thử API trên sandbox | ● |

: Quyền của vai trò nhà phát triển ở cổng PH-15

## 4. Tách nhiệm vụ

Bảng dưới đây liệt kê các cặp vai trò không được gán cùng lúc cho một người trong cùng tenant. PH-12 chặn khi gán; trường hợp tỉnh thiếu nhân sự phải có quyết định ngoại lệ được ghi kiểm toán và có thời hạn.

| Vai trò A | Vai trò B | Lý do |
|---|---|---|
| INTEGRATION_ENGINEER | INTEGRATION_APPROVER | Người thiết kế không tự duyệt phát hành |
| SERVICE_OWNER | CATALOG_APPROVER | Chủ dịch vụ không tự duyệt công bố |
| DATA_STEWARD | DATA_APPROVER | Người soạn danh mục không tự duyệt phát hành; người quản lý dữ liệu chủ không tự duyệt hợp nhất rủi ro cao, quy tắc đối sánh (PH-06) |
| PAYMENT_ACCOUNTANT | PAYMENT_APPROVER | Người lập hoàn tiền, đề xuất xử lý chênh lệch không tự duyệt (tỉnh thiếu người được gán kèm cảnh báo, quy tắc động vẫn chặn, khung PH-19 §13.4) |
| TENANT_ADMIN | AUDITOR | Người quản trị không tự kiểm toán mình |
| PAYMENT_ADMIN | PAYMENT_APPROVER | Người cấu hình kênh không duyệt kích hoạt kênh (như dòng trên) |
| AUDITOR | mọi vai trò có quyền ghi của PH-19 | Độc lập kiểm toán (khung PH-19 §13.4 quy tắc 7) |

: Các cặp vai trò không được gán cùng một người

Ngoài tách vai trò, nguyên tắc bốn mắt (FR-00-071) vẫn áp dụng cho từng đối tượng.

Sơ đồ dưới vẽ bảy cặp xung đột thành các đường nối, để thấy vai trò nào không được cộng dồn với vai trò nào.

```{.mermaid caption="Các cặp vai trò xung đột phải tách nhiệm vụ"}
flowchart TB
  IE[INTEGRATION_ENGINEER] --- IA[INTEGRATION_APPROVER]
  SO[SERVICE_OWNER] --- CA[CATALOG_APPROVER]
  DS[DATA_STEWARD] --- DA[DATA_APPROVER]
  PAC[PAYMENT_ACCOUNTANT] --- PAP[PAYMENT_APPROVER]
  PAD[PAYMENT_ADMIN] --- PAP
  TA[TENANT_ADMIN] --- AU[AUDITOR]
  AU --- PW["Mọi vai trò có quyền ghi của PH-19"]
```

Hình cho thấy vai trò thiết kế, soạn, đề xuất luôn đứng đối diện vai trò duyệt, và AUDITOR đối lập với cả quản trị lẫn mọi vai trò ghi của thanh toán; `PAYMENT_APPROVER` đối lập với hai vai trò lập đề nghị.

Duyệt bốn mắt hoạt động ở mức từng đối tượng nên bổ sung cho tách vai trò. Sơ đồ dưới cho thấy một đề nghị đi từ người lập sang người duyệt và điểm chặn khi hai người trùng nhau.

```{.mermaid caption="Duyệt bốn mắt trên một đối tượng (FR-00-071)"}
sequenceDiagram
  actor L as Người lập đề nghị
  participant H as Datahub và OPA
  actor D as Người duyệt
  L->>H: Gửi đối tượng để duyệt (submit)
  H->>H: Ghi người gửi, kiểm tra vai trò gửi
  H->>D: Đưa vào hộp Việc của tôi
  D->>H: Duyệt hoặc từ chối (approve)
  H->>H: So người duyệt với người tạo hoặc gửi
  alt Người duyệt trùng người tạo hoặc gửi
    H-->>D: Từ chối 403 và ghi kiểm toán
  else Hai người khác nhau và có quyền approve
    H-->>L: Kết quả duyệt, ghi kiểm toán
  end
```

Hình cho thấy kiểm tra bốn mắt diễn ra ở lúc duyệt chứ không chỉ lúc gán vai trò: người có đủ quyền `approve` vẫn bị từ chối nếu chính họ là người tạo hoặc gửi đối tượng.

## 5. Quyền của HTTT thành viên (máy)

HTTT gọi Datahub bằng token `client_credentials` hoặc mTLS. Token mang phạm vi (scope) được sinh tự động từ dữ liệu đã duyệt, không cấp tay.

| Scope | Ý nghĩa | Được cấp khi |
|---|---|---|
| `api:{mã API}:{mã gói}` | Gọi API theo gói sử dụng | Đăng ký sử dụng được duyệt ở PH-02 |
| `purpose:{mã mục đích}` | Khai thác dữ liệu theo mục đích | Chủ quản dữ liệu chấp thuận ở PH-09 (đợt 2); trong MVP, gắn với đăng ký sử dụng |
| `topic:{tên topic}:publish` / `:subscribe` | Phát hoặc nhận sự kiện | Publication / subscription được duyệt ở PH-10 |
| `event:topic-register`, `event:permission-check`, `event:runtime-config`, `event:dlq-read`, `event:replay`, `event:metrics-read` | Scope máy nội bộ của PH-10, chỉ cấp cho tài khoản dịch vụ DU (PH-05, PH-04, `dh-runtime`, PH-18, PH-13), không cấp cho HTTT hay người | Cấp khi triển khai (FRS PH-10 §3.2) |
| `rdm:read` | Tra cứu danh mục dùng chung | Mặc định cho mọi HTTT `ACTIVE` |
| `payment:create` | Tạo yêu cầu thanh toán | HTTT được khai báo là đối tác ở PH-19 |

: Scope OAuth của HTTT thành viên (máy) và điều kiện cấp

## 6. Ánh xạ từ quyền của hệ cũ

Bảng dưới nêu cách quyền ở từng khối hệ cũ được chuyển thành vai trò và quyền của Datahub, làm đầu vào khi di trú người dùng.

| Hệ cũ | Datahub |
|---|---|
| `Project_group.access_level` (Bus) | Phạm vi không gian làm việc PH-04 với INTEGRATION_ENGINEER / VIEWER |
| Plan "Define: nhóm được phép truy cập" (APIM) | Điều kiện đăng ký sử dụng của gói (PH-02) |
| Vai trò Keycloak tự đặt ở từng khối | Vai trò chuẩn ở mục 2, gán lại khi di trú người dùng |

: Ánh xạ quyền hệ cũ sang vai trò Datahub

## 7. Kiểm thử

D05-01 sinh tự động từ ma trận mục 3 hai nhóm ca kiểm thử cho mỗi API: một ca dương với vai trò có ● hoặc ○, một ca âm với một vai trò có —. Ca ○ có thêm một ca âm với đối tượng của tổ chức khác. Kỳ vọng ca âm là `403` khi người dùng biết đối tượng tồn tại trong phạm vi của mình, và `404` khi đối tượng thuộc tổ chức hoặc tenant khác.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-21 | Nhóm viết tài liệu (Claude) | Bản đầu |
| 0.2 | 2026-11-26 | Nhóm viết tài liệu (Claude) | Mục 3.3 thay bằng 48 quyền và ma trận của khung PH-19 §13; vai trò thanh toán đổi `PAYMENT_OFFICER` thành `PAYMENT_ACCOUNTANT`, thêm `PAYMENT_OPERATOR`, `PARTNER_SYSTEM`; tách mục 3.4 cho nhà phát triển |
| 0.3 | 2026-11-26 | Nhóm viết tài liệu (Claude) | Mục 3.1: thêm tám quyền PH-05 (`adapter`, `test`, `operate`, `approve`, `db-write-consent`, `kamelet-submit`, `audit-read`, `admin`), mở rộng mô tả `PERM-05-connection`, `PERM-05-kamelet-approve` thêm IA cho Kamelet của tỉnh (D02-03-PH05 §3.2) |
| 0.4 | 2026-11-26 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp: thêm tóm tắt cho hội đồng thẩm định, sáu mục giới thiệu (mục 1.1 đến 1.6), sơ đồ mô hình phân quyền, sơ đồ cặp vai trò xung đột và sơ đồ duyệt bốn mắt kèm thuyết minh, đoạn mở cho các mục còn thiếu, viết lại chú thích bảng. Giữ nguyên toàn bộ vai trò, quyền, ma trận |
