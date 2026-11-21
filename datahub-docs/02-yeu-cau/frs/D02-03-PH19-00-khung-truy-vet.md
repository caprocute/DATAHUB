---
ma_tai_lieu: D02-03-PH19-00
ten: Khung truy vết phân hệ PH-19 Thanh toán điện tử
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Nhóm phân tích, thiết kế, kiểm thử PH-19; luồng lõi (D00-03, D02-01, D02-07, D02-08)
nguoi_lap: Nhóm phân tích thiết kế
phan_he: PH-19
---

# D02-03-PH19-00 · Khung truy vết phân hệ PH-19 Thanh toán điện tử

## 0. Cách dùng tài liệu này

Tài liệu này là "xương sống" của toàn bộ bộ tài liệu PH-19. Nó không đặc tả chi tiết một chức năng nào, mà cấp phát và cố định **mọi mã truy vết** của phân hệ (FR, NFR, BR, UC, US, EN, API, EVT, UI, ERR, PERM, ROLE, TS/TC, OQ, giả định, ADR) cùng các quyết định nền mà bảy luồng viết song song phải dùng chung: máy trạng thái, tên cột, đường dẫn API, tên topic, mã lỗi và ma trận quyền. Lý do phải có một tài liệu như vậy là bảy luồng viết cùng lúc; nếu mỗi luồng tự đặt mã thì FRS, use case, CSDL, API, màn hình và test case sẽ không khớp nhau, và ma trận truy vết D00-03 không dựng được.

Ba quy tắc áp dụng cho mọi luồng viết sau tài liệu này:

1. **Chỉ dùng mã có trong tài liệu này.** Luồng nào thấy thiếu thì ghi vào mục "Đề xuất bổ sung mã" ở cuối tài liệu của mình, lấy số kế tiếp sau số lớn nhất của dải tương ứng tại đây và ghi rõ "đề xuất". Không sửa file này.
2. **Một sự thật, một nơi.** Tài liệu này chỉ đặt tên và phạm vi; nội dung chi tiết nằm ở tài liệu chủ quản ghi trong mục 16. Khi hai tài liệu mâu thuẫn thì thứ tự ưu tiên là: D00-01 → tài liệu này → tài liệu chủ quản của mã → các tài liệu tham chiếu.
3. **Mọi thứ liên quan tới PayGov là giả định.** Tài liệu hệ cũ không kèm đặc tả kỹ thuật của PayGov. Bất kỳ tên trường, tham số, thuật toán ký hay mã lỗi nào của PayGov xuất hiện trong bộ tài liệu đều phải kèm cụm "Giả định – cần đối chiếu Tài liệu kỹ thuật kết nối Nền tảng thanh toán của Cổng DVCQG do VPCP cấp" và tham chiếu một câu hỏi mở `OQ-19-nn` ở mục 15.

Quy ước mã tuân theo D00-01 §3. Riêng ba điểm sau khác với bản brief đầu tiên và đã được chốt theo D00-01: mã lỗi là `ERR-19-nnn` (không dùng `PAY-xxxx`); quyền là `PERM-19-{tài-nguyên}-{động-từ}`; đường dẫn REST theo dạng `/api/{nhóm}/v{n}/…` (D00-01 §6) nên ba nhóm API của PH-19 là `/api/payment/v1` (quản trị), `/api/payment-partner/v1` (đối tác) và `/api/payment-callback/v1` (nhà cung cấp gọi về).

| Loại mã | Dải đã cấp trong tài liệu này | Số lượng | Tài liệu chủ quản nội dung chi tiết |
|---|---|---|---|
| `LGC-PAY-nnn` | 001–023 (D00-03 §4.6), đề xuất thêm 024–026 | 23 + 3 | D00-03 |
| `REQ-nn`, `SH-nn`, `BP-nn` (đề xuất) | REQ-91…99, SH-91…98, BP-91…96 | 9 / 8 / 6 | D02-01-PH19 (BRD) |
| `BO-nn`, `KPI-nn` (đề xuất) | BO-91…96, KPI-91…99 | 6 / 9 | D02-01-PH19 (BRD) |
| `FR-19-nnn` | 001–068 | 68 | D02-03-PH19 (FRS) |
| `NFR-19-nnn` | 001–032 | 32 | D02-03-PH19 (FRS) |
| `BR-19-nnn` | 001–034 | 34 | D02-03-PH19 (FRS) |
| `UC-19-nn` | 01–29 | 29 | D02-04-PH19 |
| `US-19-nnn` | 001–056 | 56 | D02-05-PH19 |
| `EN-19-nn` | 01–25 | 25 | D03-03-PH19 (CSDL) |
| `API-19-nnn` | 001–090, 101–110, 201–204 | 104 | D03-04-PH19 |
| `EVT-19-nn` | 01–18 | 18 | D03-04-PH19 |
| `UI-19-nn` | 01–28 | 28 | D03-06-PH19 |
| `ERR-19-nnn` | 001–050, 099 | 51 | D03-04-PH19 |
| `PERM-19-*` | 48 quyền | 48 | D02-08 (đề xuất từ tài liệu này) |
| `ROLE-*` | 9 vai trò | 9 | D02-08 (đề xuất từ tài liệu này) |
| `TS-19-nn` / `TC-19-nnn` | TS 01–34; TC 001–850 (mỗi TS 25 số) | 34 | D05-02-PH19 |
| `OQ-19-nn` / `A-19-nn` | OQ 01–20; A 01–14 | 20 / 14 | Tài liệu này |
| `ADR-nnn` | 040–049 | 10 | `00-chung/adr/` |

Các mã `REQ`, `SH`, `BP`, `BO`, `KPI` do D02-01 chủ quản và hiện chưa có số chính thức cho phần thanh toán. Tài liệu này dùng tạm dải 91–99 để các luồng tham chiếu được ngay; luồng lõi sẽ cấp số chính thức khi gộp BRD và việc đổi số là thay thế cơ học một-một.

## 1. Phạm vi, tác nhân và phụ thuộc

### 1.1. PH-19 là gì

PH-19 là lớp trung gian thanh toán của tỉnh: các HTTT của tỉnh (Cổng DVC, HTTT giải quyết TTHC, các ứng dụng chuyên ngành — gọi chung là **đối tác**) gọi vào PH-19 để tạo yêu cầu thu phí, lệ phí, nghĩa vụ tài chính; PH-19 chuyển yêu cầu tới **nhà cung cấp thanh toán** (kênh đầu tiên và mặc định là PayGov), nhận kết quả, lưu toàn bộ lịch sử, báo lại cho đối tác, rồi đối soát với nhà cung cấp vào ngày hôm sau. PH-19 **không giữ tiền, không là trung gian thanh toán** theo nghĩa pháp lý; tiền đi từ người nộp tới tài khoản thụ hưởng qua PayGov và ngân hàng/trung gian thanh toán kết nối với PayGov. PH-19 chỉ giữ **chứng cứ điện tử** về yêu cầu, kết quả và việc đối soát.

Hệ cũ (Payment Đắk Nông, 2021) chỉ hiện thực phần danh mục, ghi nhận giao dịch và ba màn hình xem; tài liệu hệ cũ không mô tả bảo mật callback, idempotency, đối soát hay hoàn tiền, và mô hình dữ liệu có hai lỗi phải sửa khi di trú: số tiền kiểu `int(10)` (trần khoảng 2,1 tỷ đồng) và ngày thanh toán kiểu `varchar`. PH-19 làm đầy đủ các phần còn thiếu này.

### 1.2. Phạm vi làm và không làm

Bảng sau là ranh giới phạm vi. Mọi nội dung nằm ở cột "Không làm" mà một luồng thấy cần thì phải nêu thành câu hỏi mở, không tự mở rộng.

| Nhóm | Làm (trong phạm vi PH-19) | Không làm (ngoài phạm vi, nêu rõ ai làm) |
|---|---|---|
| Nhà cung cấp | Vòng đời NCC: khai báo, gắn thông tin xác thực (chỉ lưu tham chiếu kho bí mật), kiểm tra kết nối, giao dịch thử, kích hoạt có phê duyệt, tạm dừng, ngừng hẳn; giám sát sức khỏe; xoay khóa. Kiến trúc đa kênh qua adapter, PayGov là adapter đầu tiên | Tích hợp trực tiếp với từng ngân hàng, ví điện tử (đi qua PayGov). Đàm phán, ký thỏa thuận kết nối với VPCP (việc của chủ đầu tư) |
| Danh mục | Nhóm dịch vụ, dịch vụ thanh toán, gắn với lĩnh vực TTHC và loại phí qua mã danh mục PH-07 | Giữ bảng danh mục ngân hàng, kênh, lĩnh vực, loại phí (PH-07 chủ quản). Tính mức phí, lệ phí của từng TTHC (HTTT đối tác tính và gửi số tiền) |
| Đối tác | Đăng ký, phê duyệt, cấp client máy-máy, gán dịch vụ được dùng, hạn mức, webhook | Kết nạp HTTT thành viên nói chung (PH-01); cấp phát danh tính (PH-12 thực hiện, PH-19 gọi qua API) |
| Giao dịch | Tạo, khởi tạo tại NCC, điều hướng người nộp, nhận IPN, truy vấn trạng thái, hủy, hết hạn, lịch sử bất biến, idempotency | Giao diện chọn ngân hàng/nhập thẻ (PayGov cung cấp). Lưu số thẻ, số tài khoản đầy đủ của người nộp (cấm lưu). Phát hành biên lai/chứng từ điện tử thu phí có giá trị pháp lý (HTTT đối tác hoặc hệ thống biên lai; xem OQ-19-14) |
| Hoàn tiền | Yêu cầu, phê duyệt bốn mắt, thực thi qua API của NCC nếu có, hoặc chế độ thủ công có ghi nhận chứng cứ | Quyết định hành chính về việc hoàn phí (cơ quan thu quyết định ngoài hệ thống) |
| Đối soát | Đối soát T+1 theo NCC, phát hiện và xử lý chênh lệch, chốt phiên, biên bản, cung cấp kết quả cho đối tác | Hạch toán kế toán, lập báo cáo quyết toán ngân sách, đối soát giữa ngân hàng và Kho bạc |
| Tra cứu, báo cáo | Tra cứu, chi tiết, nhật ký, hai dashboard, báo cáo định kỳ, xuất file | Kho phân tích dài hạn/BI (PH-16 và lớp dữ liệu dùng chung tiêu thụ sự kiện) |
| Thông báo | Webhook có ký tới đối tác; sự kiện Kafka qua outbox | Gửi SMS/email/Zalo cho người nộp (đối tác thực hiện) |
| Đa tenant | Cấu hình theo tenant, RLS, tiền tố topic, khóa và chứng thư riêng từng tenant | Khởi tạo tenant, bật/tắt gói phân hệ (PH-20; PH-19 cung cấp hook) |
| Di trú | Nhập danh mục và giao dịch lịch sử từ hệ cũ, chạy song song, chuyển từng đối tác, lớp tương thích API cũ, đối chiếu sau di trú | Sửa mã nguồn hệ cũ; di trú người dùng (PH-12) |

### 1.3. Tác nhân là người

Bảng sau liệt kê các vai trò con người. Mã `ROLE-*` là đề xuất cho D02-08; quyền chi tiết ở mục 13.

| Vai trò | Mã | Tầng | Trách nhiệm trong PH-19 |
|---|---|---|---|
| Quản trị nền tảng | `ROLE-PLATFORM_ADMIN` | Nền tảng | Cài đặt adapter NCC, tham số mặc định của sản phẩm, hỗ trợ sự cố xuyên tenant. Không xem dữ liệu giao dịch của tenant khi không có phiên hỗ trợ được cấp (break-glass, PH-12) |
| Quản trị tenant | `ROLE-TENANT_ADMIN` | Tenant | Gán vai trò thanh toán cho cán bộ của tỉnh; bật phân hệ; không mặc nhiên có quyền nghiệp vụ thanh toán |
| Quản trị thanh toán | `ROLE-PAYMENT_ADMIN` | Tenant | Khai báo NCC, dịch vụ, nhóm dịch vụ, đối tác, client, webhook, cấu hình thanh toán; lập đề nghị kích hoạt |
| Người phê duyệt thanh toán | `ROLE-PAYMENT_APPROVER` | Tenant | Phê duyệt bốn mắt: kích hoạt NCC, duyệt đối tác, duyệt hoàn tiền, duyệt xử lý chênh lệch, mở lại phiên đối soát, chuyển chế độ định tuyến |
| Kế toán / đối soát viên | `ROLE-PAYMENT_ACCOUNTANT` | Tenant | Chạy và theo dõi đối soát, xử lý chênh lệch, lập yêu cầu hoàn tiền, chốt phiên, xuất biên bản và báo cáo |
| Cán bộ tra cứu / hỗ trợ | `ROLE-PAYMENT_OPERATOR` | Tenant | Tra cứu giao dịch, xem chi tiết, đồng bộ trạng thái thủ công, gửi lại webhook, xử lý lại callback |
| Kiểm toán viên | `ROLE-AUDITOR` | Tenant | Chỉ đọc toàn bộ dữ liệu, nhật ký và biên bản; không có thao tác ghi |
| Cán bộ ATTT | `ROLE-SECURITY_OFFICER` | Tenant / nền tảng | Quản lý thông tin xác thực NCC, xoay khóa, xem callback bị từ chối, xem nhật ký an ninh |
| Người nộp tiền | — (không đăng nhập PH-19) | Bên ngoài | Công dân, doanh nghiệp thanh toán trên trang PayGov rồi được chuyển về trang kết quả |

### 1.4. Tác nhân là hệ thống

| Hệ thống | Mã vai trò / ký hiệu | Chiều tương tác | Giao thức và ghi chú |
|---|---|---|---|
| HTTT đối tác (Cổng DVC tỉnh, HTTT giải quyết TTHC, ứng dụng chuyên ngành) | `ROLE-PARTNER_SYSTEM` | Gọi vào `/api/payment-partner/v1`; nhận webhook; tiêu thụ sự kiện | OAuth 2.1 `client_credentials` kèm mTLS hoặc `private_key_jwt`; đi qua PH-03 |
| PayGov (Nền tảng thanh toán của Cổng DVCQG) | NCC `PAYGOV` | PH-19 gọi ra để khởi tạo, truy vấn, hoàn tiền, lấy dữ liệu đối soát; PayGov gọi về `/api/payment-callback/v1/paygov/*` | Giả định HTTPS + chữ ký số; chi tiết chờ OQ-19-01…08 |
| Ngân hàng / trung gian thanh toán | — | Không kết nối trực tiếp | Chỉ xuất hiện dưới dạng mã ngân hàng, mã kênh trong kết quả PayGov trả về |
| PH-03 Cổng API (APISIX) | — | Đứng trước cả ba nhóm API | Xác thực token, mTLS, rate limit, danh sách IP cho callback, sinh `traceparent` |
| PH-12 Định danh, ủy quyền | — | PH-19 gọi | Token người dùng, tạo/thu hồi client đối tác, kiểm tra quyền (OPA) |
| PH-13 Giám sát, ghi vết | — | PH-19 đẩy | Nhật ký kiểm toán, metric, trace, log, cảnh báo |
| PH-10 Truyền thông sự kiện | — | PH-19 phát và nhận | Topic Kafka có tiền tố tenant, lược đồ tại Apicurio |
| PH-07 Danh mục dùng chung | — | PH-19 đọc | Tra mã danh mục, nhận sự kiện danh mục thay đổi |
| PH-01 Kết nạp HTTT | — | PH-19 đọc | Đối tác tham chiếu một HTTT thành viên đã kết nạp |
| PH-20 Quản trị tenant | — | PH-20 gọi PH-19 | Khởi tạo, tạm ngừng tenant; bật/tắt phân hệ; cấu hình mặc định |
| PH-18 Vận hành | — | PH-19 đẩy | Bản tin lỗi không tự xử lý được (DLQ) và quy trình xử lý sự cố |
| PH-09 Bảo vệ dữ liệu cá nhân | — | PH-19 gọi | Che dữ liệu người nộp khi hiển thị và xuất; nhãn phân loại |
| Kho bí mật (OpenBao/Vault), kho đối tượng (Garage), Valkey | — | Hạ tầng | Khóa ký và chứng thư; file đối soát và file xuất; khóa phân tán và bộ đệm |
| Hệ Payment cũ | `LEGACY` | Nguồn di trú; chạy song song | Đọc CSDL cũ khi di trú; định tuyến strangler tại PH-03 |

### 1.5. Phụ thuộc và danh mục dùng chung

PH-19 phụ thuộc cứng vào PH-03, PH-12, PH-13, PH-10, PH-07, PH-20 (đều thuộc MVP đợt 1) và phụ thuộc mềm vào PH-01, PH-09, PH-18. "Phụ thuộc cứng" nghĩa là PH-19 không khởi động được hoặc không đạt nghiệm thu nếu phân hệ kia chưa sẵn sàng. Theo ADR-001, PH-19 là một module Spring Modulith và chỉ được dùng gói `api/` và `events/` của module khác.

| Phân hệ | Mức | PH-19 dùng gì | Nếu phân hệ kia không sẵn sàng |
|---|---|---|---|
| PH-03 | Cứng | Định tuyến, xác thực biên, rate limit, allowlist IP callback | Không nhận được yêu cầu; không có phương án thay thế |
| PH-12 | Cứng | OIDC người dùng, client máy-máy của đối tác, quyết định OPA | Từ chối mọi yêu cầu (deny-by-default) |
| PH-13 | Cứng | Kho nhật ký kiểm toán, metric, cảnh báo | Thao tác quản trị bị chặn nếu không ghi được kiểm toán (BR-19-029); giao dịch vẫn chạy, kiểm toán xếp hàng trong outbox |
| PH-10 | Cứng | Kafka, Schema Registry | Sự kiện nằm lại trong `outbox_event`, phát bù khi Kafka phục hồi; webhook không bị ảnh hưởng |
| PH-07 | Cứng (lúc cấu hình), mềm (lúc chạy) | Tra và kiểm tra mã danh mục | Dùng bản đệm cục bộ trong Valkey; không cho tạo mới dịch vụ khi không xác thực được mã |
| PH-20 | Cứng | Vòng đời tenant, cờ bật phân hệ | Không tạo được cấu hình tenant mới |
| PH-01 | Mềm | Định danh HTTT thành viên của đối tác | Cho phép đối tác chưa gắn HTTT ở trạng thái `DRAFT`, không cho kích hoạt |
| PH-09 | Mềm | Chính sách che dữ liệu | Áp quy tắc che mặc định cứng trong PH-19 (BR-19-031) |
| PH-18 | Mềm | Hàng xử lý lỗi vận hành | Callback và webhook lỗi vẫn xem được tại UI-19-16, UI-19-24 |

**Danh mục dùng chung do PH-07 chủ quản.** PH-19 không tạo bảng danh mục trùng lặp. Các cột tham chiếu danh mục lưu **mã mục** (`T-CODE`) và được kiểm tra với PH-07 khi ghi (FR-19-016). Bảng sau liệt kê các mã danh mục PH-19 cần; luồng PH-07 chịu trách nhiệm khởi tạo dữ liệu.

| Mã danh mục | Nội dung | PH-19 dùng ở đâu | Ghi chú |
|---|---|---|---|
| `DM_LINH_VUC_TTHC` | Lĩnh vực thủ tục hành chính | `payment_service_group.sector_code`; bộ lọc "Lĩnh vực" | Nhóm dịch vụ của PH-19 là cách tenant gom dịch vụ để báo cáo; mỗi nhóm trỏ tới tối đa một lĩnh vực |
| `DM_KENH_THANH_TOAN` | Kênh/phương thức thanh toán (thẻ nội địa, QR, ví, chuyển khoản…) | `payment_transaction.channel_code` | Giá trị do NCC trả về, ánh xạ qua bảng ánh xạ mã của PH-07 |
| `DM_NGAN_HANG` | Ngân hàng, trung gian thanh toán | `payment_transaction.bank_code`; `refund_request.bank_code` | Như trên |
| `DM_LOAI_PHI_LE_PHI` | Loại khoản thu: phí, lệ phí, thuế, nghĩa vụ tài chính khác | `payment_service.fee_type_code` | |
| `DM_CO_QUAN` | Cơ quan, đơn vị (đơn vị thu, đơn vị chủ quản đối tác) | `payment_service.collecting_agency_code`; `payment_partner.agency_code` | Tên chính thức của danh mục do PH-07 chốt |
| `DM_DON_VI_HANH_CHINH` | Đơn vị hành chính | Báo cáo theo địa bàn (tùy chọn) | Có lịch sử sáp nhập |
| `DM_THU_TUC_HANH_CHINH` | Thủ tục hành chính | `payment_service.procedure_code` (tùy chọn); `payment_transaction.procedure_code` | |
| `DM_LOAI_TIEN_TE` | Loại tiền | Kiểm tra `currency = VND` | PH-19 đợt 2 chỉ nhận `VND` (BR-19-001) |
| `DM_LY_DO_HOAN_TIEN` | Lý do hoàn tiền | `refund_request.reason_code` | Đề xuất PH-07 bổ sung |
| `DM_LOAI_CHENH_LECH_DOI_SOAT` | Loại chênh lệch đối soát | Hiển thị nhãn cho `discrepancy.type` | Giá trị enum cố định trong mã nguồn (mục 7.7); danh mục chỉ giữ nhãn hiển thị |
| `DM_MA_LOI_NCC_THANH_TOAN` | Bảng ánh xạ mã kết quả của NCC sang trạng thái và thông điệp chuẩn | Adapter PayGov | Dùng tính năng ánh xạ mã giữa hệ thống của PH-07 |

Trạng thái vòng đời (mục 7) **không** phải danh mục PH-07: chúng là enum cố định trong mã nguồn vì máy trạng thái phụ thuộc vào chúng.

### 1.6. Yêu cầu nghiệp vụ cấp cao, bên liên quan, quy trình TO-BE (đề xuất cho D02-01)

Theo D00-01 §3.2, mỗi FR phải tham chiếu ít nhất một `REQ`. BRD tổng chưa có REQ cho thanh toán, nên tài liệu này đề xuất chín REQ; luồng BRD-PH19 đặc tả chi tiết.

| Mã (đề xuất) | Yêu cầu nghiệp vụ cấp cao |
|---|---|
| REQ-91 | Tỉnh phải quản lý được vòng đời các nhà cung cấp thanh toán và chỉ đưa vào sử dụng nhà cung cấp đã được kiểm tra, phê duyệt |
| REQ-92 | Tỉnh phải quản lý được danh mục dịch vụ thanh toán và các HTTT được phép thu qua nền tảng |
| REQ-93 | Mọi HTTT của tỉnh phải thu được phí, lệ phí trực tuyến qua một giao diện thống nhất, không phụ thuộc đặc tả riêng của nhà cung cấp |
| REQ-94 | Kết quả thanh toán phải được ghi nhận chính xác, đúng một lần, có chứng cứ, và được báo lại cho HTTT gọi kịp thời |
| REQ-95 | Tỉnh phải đối soát hằng ngày với nhà cung cấp và xử lý dứt điểm mọi chênh lệch có kiểm soát |
| REQ-96 | Tỉnh phải xử lý được việc hoàn tiền có phê duyệt và lưu vết |
| REQ-97 | Cán bộ phải tra cứu, giám sát, lập báo cáo về giao dịch và kênh thanh toán; kiểm toán viên phải truy được mọi thao tác |
| REQ-98 | Phân hệ phải vận hành đa tenant, an toàn theo cấp độ 3 (sẵn sàng cấp độ 4), bảo vệ dữ liệu cá nhân và lưu trữ chứng từ theo quy định |
| REQ-99 | Việc chuyển từ hệ Payment cũ phải diễn ra từng bước, không gián đoạn thu và không mất dữ liệu lịch sử |

| Mã (đề xuất) | Bên liên quan | Quan tâm chính |
|---|---|---|
| SH-91 | Sở Khoa học và Công nghệ / đơn vị vận hành Datahub của tỉnh | Vận hành ổn định, an toàn, chi phí |
| SH-92 | Sở Tài chính và bộ phận kế toán của cơ quan thu | Số liệu đúng, đối soát khớp, chứng từ |
| SH-93 | Văn phòng UBND tỉnh / Trung tâm phục vụ hành chính công | Tỷ lệ thanh toán trực tuyến, trải nghiệm người dân |
| SH-94 | Đơn vị chủ quản HTTT đối tác | Tích hợp đơn giản, kết quả tin cậy |
| SH-95 | Văn phòng Chính phủ (chủ quản PayGov) | Tuân thủ đặc tả kết nối |
| SH-96 | Người nộp tiền (công dân, doanh nghiệp) | Nộp một lần, không bị trừ tiền hai lần, được hoàn khi sai |
| SH-97 | Cơ quan kiểm toán, thanh tra | Truy vết, toàn vẹn chứng cứ |
| SH-98 | Đơn vị quản trị nền tảng (nhà cung cấp sản phẩm) | Một bản mã cho nhiều tỉnh, nâng cấp đồng loạt |

| Mã (đề xuất) | Quy trình nghiệp vụ TO-BE | UC chính |
|---|---|---|
| BP-91 | Đưa một nhà cung cấp thanh toán vào sử dụng | UC-19-01…04 |
| BP-92 | Đăng ký một HTTT đối tác được thu qua nền tảng | UC-19-08…10 |
| BP-93 | Thu một khoản phí, lệ phí trực tuyến (từ tạo yêu cầu tới báo kết quả) | UC-19-11…16, UC-19-27 |
| BP-94 | Hoàn tiền một giao dịch | UC-19-17, UC-19-18 |
| BP-95 | Đối soát ngày và xử lý chênh lệch | UC-19-19…21 |
| BP-96 | Chuyển một đối tác từ hệ cũ sang Datahub | UC-19-29 |

## 2. Chức năng hệ cũ và FR phủ (`LGC-PAY`)

D00-03 §4.6 đã kiểm kê 23 chức năng hệ cũ `LGC-PAY-001…023` từ bốn nguồn: tài liệu phân tích yêu cầu (20 chức năng), thiết kế chi tiết (dashboard tổng quan, bảng tra cứu, chi tiết giao dịch, tra cứu nâng cao, dashboard kênh), thiết kế CSDL (năm bảng) và HDSD. Bảng dưới đây giữ nguyên mã và kết luận của D00-03, bổ sung cột FR phủ và màn hình mới. Không LGC nào bị loại bỏ. Mỗi LGC có ít nhất một FR; chiều ngược lại xem cột "LGC" ở mục 4.

| Mã | Chức năng hệ cũ (rút gọn) | Nguồn hệ cũ | Kết luận | FR phủ | UI mới |
|---|---|---|---|---|---|
| LGC-PAY-001 | Thêm NCC: khai báo, liên kết API, thử luồng thanh toán, kiểm tra phản hồi, đưa vào danh sách khi thử thành công | PTYC #1 | Nâng cấp | FR-19-001, 002, 003, 004, 005 | UI-19-05, UI-19-06 |
| LGC-PAY-002 | Xem danh sách NCC | PTYC #2 | Giữ nguyên | FR-19-007 | UI-19-03 |
| LGC-PAY-003 | Xem chi tiết NCC: ngày bắt đầu, đầu mối, điện thoại, tình trạng, số dịch vụ, biểu đồ giao dịch theo ngày | PTYC #3, HDSD 4.3 | Giữ nguyên | FR-19-008, 057 | UI-19-04, UI-19-02 |
| LGC-PAY-004 | Chỉnh sửa NCC | PTYC #4 | Giữ nguyên | FR-19-009, 002 | UI-19-05 |
| LGC-PAY-005 | Xóa NCC | PTYC #5 | Nâng cấp | FR-19-010 | UI-19-03, UI-19-04 |
| LGC-PAY-006 | Tìm kiếm NCC | PTYC #6 | Giữ nguyên | FR-19-007 | UI-19-03 |
| LGC-PAY-007 | Kích hoạt NCC: kiểm tra hiện trạng, kết nối, giao dịch mẫu, nhận phản hồi | PTYC #7 | Giữ nguyên | FR-19-003, 004, 005 | UI-19-06, UI-19-13 |
| LGC-PAY-008 | Dừng NCC | PTYC #8 | Giữ nguyên | FR-19-006 | UI-19-04 |
| LGC-PAY-009 | Thông báo lỗi kết nối với NCC | PTYC #9 | Nâng cấp | FR-19-011, 059 | UI-19-04, UI-19-01 |
| LGC-PAY-010 | Nhận kết quả thanh toán từ NCC | PTYC #10 | Nâng cấp | FR-19-029, 030, 031, 032 | UI-19-16 |
| LGC-PAY-011 | Lưu dữ liệu quá trình thanh toán vào CSDL | PTYC #11, CSDL | Nâng cấp | FR-19-022, 028, 054 | UI-19-15 |
| LGC-PAY-012 | Thông báo kết quả thanh toán cho HTTT gọi | PTYC #12 | Nâng cấp | FR-19-025, 060, 061, 062 | UI-19-24, UI-19-28 |
| LGC-PAY-013 | Dashboard tổng quan: số dịch vụ, số hệ thống áp dụng, tổng giao dịch, giao dịch trong ngày, biểu đồ theo dịch vụ, bảng giao dịch trong ngày | TKCT 3.1, HDSD 4.1 | Giữ nguyên | FR-19-056 | UI-19-01 |
| LGC-PAY-014 | Bảng tra cứu giao dịch | TKCT 3.2 | Giữ nguyên | FR-19-049 | UI-19-14 |
| LGC-PAY-015 | Tìm kiếm nâng cao theo trạng thái (chọn nhiều) | TKCT 3.4, HDSD 4.2.2 | Giữ nguyên | FR-19-050 | UI-19-14 |
| LGC-PAY-016 | Tìm kiếm nâng cao theo lĩnh vực (chọn nhiều) | TKCT 3.4, HDSD 4.2.3 | Giữ nguyên | FR-19-050 | UI-19-14 |
| LGC-PAY-017 | Tìm kiếm nâng cao theo thời gian (mẫu 1 tháng, 3 tháng, 1 quý; tùy chọn từ ngày – đến ngày) | TKCT 3.4, HDSD 4.2.4 | Giữ nguyên | FR-19-050 | UI-19-14 |
| LGC-PAY-018 | Tìm theo từ khóa, phân trang khi > 20 dòng, tiêu chí sắp xếp | PTYC #13–15 | Giữ nguyên | FR-19-049 | UI-19-14 |
| LGC-PAY-019 | Xem chi tiết giao dịch và lịch sử trạng thái | PTYC #16, TKCT 3.3 | Giữ nguyên | FR-19-051, 028 | UI-19-15 |
| LGC-PAY-020 | Dashboard kênh thanh toán (30 ngày gần nhất) | TKCT 3.5 | Giữ nguyên | FR-19-057 | UI-19-02 |
| LGC-PAY-021 | Danh sách, lọc, sắp xếp, xem chi tiết nhật ký giao dịch | PTYC #17–20 | Giữ nguyên | FR-19-053, 054, 055 | UI-19-23 |
| LGC-PAY-022 | Quản lý đối tác, nhóm dịch vụ và dịch vụ thanh toán | CSDL 2.1.1, 2.1.2, 2.1.4 | Giữ nguyên | FR-19-013, 014, 015, 017, 018, 020 | UI-19-07…12 |
| LGC-PAY-023 | Giám sát nhiều NCC; hệ cũ chỉ hiện thực PayGov | TKCT 1.2 | Nâng cấp | FR-19-011, 024, 057 | UI-19-02, UI-19-03 |

Khi đối chiếu lại tài liệu gốc, có ba hành vi của hệ cũ chưa có dòng riêng trong D00-03. Tài liệu này **đề xuất** luồng lõi bổ sung vào D00-03 §4.6; trong lúc chờ, các luồng PH-19 được phép tham chiếu ba mã này kèm chữ "(đề xuất)".

| Mã (đề xuất) | Chức năng hệ cũ | Nguồn | Kết luận đề xuất | FR phủ |
|---|---|---|---|---|
| LGC-PAY-024 | Nhận yêu cầu thanh toán của người dùng, gửi yêu cầu thanh toán, xử lý quá trình thanh toán theo NCC | HDSD mục 3, dòng 9–11 | Nâng cấp | FR-19-022, 023, 024, 025, 033, 034 |
| LGC-PAY-025 | Bộ trạng thái giao dịch có ba trạng thái hoàn trả `REFUND_PENDING`, `REFUND_SUCCESS`, `REFUND_FAILED` (chỉ có trạng thái, không mô tả chức năng) | TKCT 3.4 | Nâng cấp | FR-19-038, 039, 040, 041 |
| LGC-PAY-026 | Số liệu tổng trên dashboard được đệm 10 phút | TKCT 3.1 | Nâng cấp | FR-19-056 (NFR-19-006: số liệu trễ tối đa 60 giây) |

Các yêu cầu phi chức năng của hệ cũ đã có mã `LGC-NFR-001…014` và `LGC-IAM-001` tại D00-03; ánh xạ sang NFR của PH-19 xem cột "Truy vết" ở mục 5.

## 3. Mục tiêu nghiệp vụ và chỉ số (`BO`, `KPI`)

Mục tiêu nghiệp vụ trả lời câu hỏi "vì sao tỉnh cần PH-19"; chỉ số cho biết khi nào coi là đạt. Mã là đề xuất cho D02-01 (dải 91–99). Mọi KPI đều tính được từ dữ liệu của chính PH-19 hoặc PH-13, không cần nhập tay.

| Mã | Mục tiêu nghiệp vụ | REQ |
|---|---|---|
| BO-91 | Mọi HTTT của tỉnh thu phí, lệ phí trực tuyến qua một đầu mối duy nhất, thay cho việc từng HTTT tự tích hợp PayGov | REQ-92, REQ-93 |
| BO-92 | Không sai, không mất, không ghi trùng một giao dịch nào; mỗi kết quả đều có chứng cứ truy lại được | REQ-94, REQ-98 |
| BO-93 | Đối soát xong trong ngày làm việc kế tiếp và mọi chênh lệch được xử lý dứt điểm, có người chịu trách nhiệm | REQ-95, REQ-96 |
| BO-94 | Chủ động với sự cố kênh thanh toán: phát hiện trong vài phút và có sẵn kiến trúc để thêm kênh thứ hai | REQ-91 |
| BO-95 | Lãnh đạo và kế toán có số liệu thu trực tuyến tức thời, không phải tổng hợp thủ công | REQ-97 |
| BO-96 | Tắt được hệ Payment cũ mà không gián đoạn việc thu và không mất dữ liệu lịch sử | REQ-99 |

| Mã | Chỉ số | Công thức và nguồn | Mục tiêu | BO |
|---|---|---|---|---|
| KPI-91 | Tỷ lệ HTTT có thu phí của tỉnh đã thu qua PH-19 | Số đối tác `ACTIVE` ở chế độ `DATAHUB` ÷ số HTTT có thu phí theo danh sách của tỉnh | ≥ 90% sau 6 tháng vận hành; 100% trước khi tắt hệ cũ | BO-91, BO-96 |
| KPI-92 | Tỷ lệ giao dịch có kết quả cuối trong 15 phút | Số giao dịch đạt `SUCCEEDED`/`FAILED`/`CANCELLED`/`EXPIRED` trong ≤ 15 phút kể từ `created_at` ÷ tổng giao dịch | ≥ 99,5% mỗi tháng | BO-92 |
| KPI-93 | Số giao dịch bị ghi nhận trùng hoặc sai số tiền | Số chênh lệch loại `DUPLICATE`, `AMOUNT_MISMATCH` có nguyên nhân gốc tại PH-19 | 0 mỗi tháng | BO-92 |
| KPI-94 | Tỷ lệ khớp tự động khi đối soát | Số `reconciliation_item` khớp tự động ÷ tổng số dòng | ≥ 99,9% mỗi phiên | BO-93 |
| KPI-95 | Thời gian chốt phiên đối soát | Thời điểm `CLOSED` trừ thời điểm kết thúc ngày giao dịch | ≤ 1 ngày làm việc với ≥ 95% số phiên | BO-93 |
| KPI-96 | Thời gian xử lý một chênh lệch | Trung vị `resolved_at − detected_at` | ≤ 3 ngày làm việc; không chênh lệch nào mở quá 10 ngày làm việc | BO-93 |
| KPI-97 | Thời gian phát hiện sự cố kênh | Từ lần kiểm tra sức khỏe thất bại đầu tiên tới khi cảnh báo được gửi | ≤ 3 phút | BO-94 |
| KPI-98 | Tỷ lệ thông báo kết quả tới đối tác thành công | Số `webhook_delivery` đạt `DELIVERED` trong ≤ 60 giây ÷ tổng số | ≥ 99% trong 60 giây; 100% trong 24 giờ hoặc có cảnh báo | BO-92 |
| KPI-99 | Độ lệch số liệu sau di trú | Chênh lệch số lượng và tổng tiền giữa hệ cũ và Datahub theo từng tháng lịch sử | 0 giao dịch, 0 đồng | BO-96 |

## 4. Danh mục yêu cầu chức năng (`FR-19-nnn`)

Có 68 FR, chia thành 15 nhóm miền (A–O). Mỗi dòng nêu vừa đủ để luồng FRS viết đặc tả đầy đủ theo mẫu D00-01 §4.3. Cột "Quyền" ghi phần sau tiền tố `PERM-19-` (ví dụ `provider-write` nghĩa là `PERM-19-provider-write`); chữ "hệ thống" nghĩa là tác vụ nền không có người gọi. Cột "Ưu tiên" dùng M/S/C theo D00-01 §4.1. Cột "Đợt": "Đ2" là đợt 2 (đợt phát hành đầu tiên của PH-19), "Sau" là sau đợt 2. API, màn hình, thực thể và kịch bản kiểm thử của từng FR tra ngược ở các mục 9–11, 14 và bảng tổng hợp mục 17.

### 4.1. Nhóm A — Nhà cung cấp thanh toán

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-001 | Khai báo nhà cung cấp | Tạo NCC ở trạng thái `DRAFT` với mã, tên, loại adapter, đầu mối liên hệ, địa chỉ môi trường thử và chính thức, ngày hiệu lực. Mã NCC duy nhất trong tenant và bất biến. | Quản trị thanh toán | provider-write | M | REQ-91 | 001 | UC-19-01 | Đ2 |
| FR-19-002 | Gắn thông tin xác thực NCC | Khai báo các tham chiếu bí mật (khóa ký, chứng thư mTLS, mã đơn vị kết nối) theo từng môi trường; hệ thống chỉ lưu đường dẫn kho bí mật, dấu vân tay và hạn dùng. | Cán bộ ATTT, Quản trị thanh toán | credential-manage | M | REQ-91, REQ-98 | 001, 004 | UC-19-01 | Đ2 |
| FR-19-003 | Kiểm tra kết nối NCC | Gọi phép thử kết nối của adapter (bắt tay TLS, xác thực, gọi API kiểm tra) và lưu kết quả từng bước làm bằng chứng. | Quản trị thanh toán | provider-test | M | REQ-91 | 001, 007 | UC-19-02 | Đ2 |
| FR-19-004 | Thực hiện giao dịch thử | Tạo một giao dịch đánh dấu `is_test = true` qua môi trường thử của NCC, theo dõi tới khi có callback, và ghi nhận kết quả vào checklist kích hoạt. | Quản trị thanh toán | provider-test | M | REQ-91 | 001, 007 | UC-19-02 | Đ2 |
| FR-19-005 | Kích hoạt NCC có phê duyệt | Người lập gửi đề nghị kích hoạt khi checklist đạt đủ; người phê duyệt khác người lập duyệt thì NCC chuyển `ACTIVE`. | Quản trị thanh toán; Người phê duyệt | provider-write; provider-activate | M | REQ-91 | 001, 007 | UC-19-03 | Đ2 |
| FR-19-006 | Tạm dừng và mở lại NCC | Tạm dừng thì NCC không nhận giao dịch mới nhưng vẫn nhận callback, truy vấn và đối soát cho giao dịch dở; mở lại yêu cầu kiểm tra kết nối đạt. | Quản trị thanh toán | provider-suspend | M | REQ-91 | 008 | UC-19-04 | Đ2 |
| FR-19-007 | Danh sách, tìm kiếm, sắp xếp NCC | Liệt kê NCC có lọc theo trạng thái, sức khỏe, từ khóa (mã, tên); sắp xếp và phân trang con trỏ. | Mọi vai trò thanh toán | provider-read | M | REQ-91 | 002, 006 | UC-19-05 | Đ2 |
| FR-19-008 | Xem chi tiết NCC | Hiển thị thông tin, trạng thái vòng đời, sức khỏe, dịch vụ đang dùng, hạn chứng thư, lịch sử thay đổi và kết quả kiểm tra gần nhất. | Mọi vai trò thanh toán | provider-read | M | REQ-91 | 003 | UC-19-05 | Đ2 |
| FR-19-009 | Chỉnh sửa NCC | Sửa các thuộc tính không định danh; thay đổi địa chỉ kết nối hoặc thông tin xác thực của NCC `ACTIVE` buộc kiểm tra kết nối lại trước khi có hiệu lực. | Quản trị thanh toán | provider-write | M | REQ-91 | 004 | UC-19-05 | Đ2 |
| FR-19-010 | Xóa hoặc ngừng hẳn NCC | Chỉ xóa cứng NCC `DRAFT` chưa từng có giao dịch; NCC đã có giao dịch chỉ chuyển `RETIRED` sau khi không còn giao dịch dở và phiên đối soát mở. | Quản trị thanh toán; Người phê duyệt | provider-delete | M | REQ-91 | 005 | UC-19-04 | Đ2 |
| FR-19-011 | Giám sát sức khỏe và cảnh báo lỗi kết nối | Kiểm tra sức khỏe định kỳ từng NCC `ACTIVE`, tính trạng thái `HEALTHY`/`DEGRADED`/`DOWN`, mở/đóng mạch ngắt và gửi cảnh báo qua PH-13. | Hệ thống; Cán bộ tra cứu | hệ thống; provider-read | M | REQ-91, REQ-97 | 009, 023 | UC-19-06 | Đ2 |
| FR-19-012 | Xoay khóa và chứng thư NCC | Thay thông tin xác thực không gián đoạn (chấp nhận song song khóa cũ và mới trong thời gian chuyển tiếp); cảnh báo trước hạn 30, 14, 7 ngày. | Cán bộ ATTT | credential-manage | S | REQ-98 | — | UC-19-06 | Đ2 |

### 4.2. Nhóm B — Nhóm dịch vụ và dịch vụ thanh toán

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-013 | Quản lý nhóm dịch vụ | Thêm, sửa, xem, xóa nhóm dịch vụ (hệ cũ gọi "lĩnh vực giao dịch"); mỗi nhóm trỏ tới một mã `DM_LINH_VUC_TTHC`. Không xóa nhóm còn dịch vụ. | Quản trị thanh toán | service-write; service-read | M | REQ-92 | 022 | UC-19-07 | Đ2 |
| FR-19-014 | Quản lý dịch vụ thanh toán | Thêm, sửa, xem, tìm dịch vụ: mã, tên, nhóm, NCC, loại khoản thu, đơn vị thu, tham chiếu tài khoản thụ hưởng, khoảng số tiền cho phép, thời hạn thanh toán riêng. | Quản trị thanh toán | service-write; service-read | M | REQ-92 | 022 | UC-19-08 | Đ2 |
| FR-19-015 | Điều khiển vòng đời dịch vụ | Kích hoạt, tạm dừng, ngừng hẳn dịch vụ; dịch vụ chỉ `ACTIVE` được khi NCC của nó `ACTIVE`; xóa cứng chỉ khi chưa có giao dịch. | Quản trị thanh toán | service-activate | M | REQ-92 | 022 | UC-19-08 | Đ2 |
| FR-19-016 | Kiểm tra và đồng bộ mã danh mục PH-07 | Khi ghi, kiểm tra mọi mã danh mục với PH-07; lắng nghe sự kiện danh mục thay đổi để đánh dấu dịch vụ, nhóm đang dùng mã hết hiệu lực. | Hệ thống | hệ thống | S | REQ-92 | — | UC-19-07, UC-19-08 | Đ2 |

### 4.3. Nhóm C — Đối tác và thông tin xác thực

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-017 | Quản lý hồ sơ đối tác | Thêm, sửa, xem, tìm đối tác: mã, tên, cơ quan chủ quản, HTTT thành viên (PH-01), đầu mối kỹ thuật và nghiệp vụ, mã ứng dụng hệ cũ (`app_code`). | Quản trị thanh toán | partner-write; partner-read | M | REQ-92 | 022 | UC-19-09 | Đ2 |
| FR-19-018 | Điều khiển vòng đời đối tác | Gửi duyệt, phê duyệt, tạm dừng, mở lại, chấm dứt đối tác; đối tác bị tạm dừng không tạo được giao dịch mới nhưng vẫn truy vấn và nhận thông báo. | Quản trị thanh toán; Người phê duyệt | partner-write; partner-approve; partner-suspend | M | REQ-92 | 022 | UC-19-09 | Đ2 |
| FR-19-019 | Cấp và thu hồi client của đối tác | Tạo client máy-máy tại PH-12 (mTLS hoặc `private_key_jwt`), gắn với đối tác, đặt hạn dùng, thu hồi tức thì; không hiển thị lại bí mật sau khi cấp. | Quản trị thanh toán; Cán bộ ATTT | partner-client-manage | M | REQ-92, REQ-98 | — | UC-19-10 | Đ2 |
| FR-19-020 | Gán dịch vụ và hạn mức cho đối tác | Khai báo đối tác được dùng dịch vụ nào, hạn mức số tiền mỗi giao dịch, hạn mức số giao dịch và tổng tiền mỗi ngày. | Quản trị thanh toán | partner-write | M | REQ-92 | 022 | UC-19-10 | Đ2 |
| FR-19-021 | Cấu hình webhook của đối tác | Khai báo địa chỉ nhận thông báo (bắt buộc HTTPS), loại sự kiện nhận, bí mật ký; gửi thử và xoay bí mật ký. | Quản trị thanh toán | partner-webhook-manage | M | REQ-94 | — | UC-19-10 | Đ2 |

### 4.4. Nhóm D — Giao dịch thanh toán và kết nối PayGov

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-022 | Tạo giao dịch thanh toán | Đối tác gửi yêu cầu thu (dịch vụ, số tiền, mã đơn hàng, nội dung, người nộp, địa chỉ quay về); hệ thống ghi giao dịch `CREATED`, sinh mã giao dịch và trả về địa chỉ thanh toán. | HTTT đối tác | partner-pay-create | M | REQ-93 | 011, 024 | UC-19-11 | Đ2 |
| FR-19-023 | Kiểm tra hợp lệ yêu cầu thanh toán | Kiểm tra theo thứ tự cố định: đối tác hoạt động, dịch vụ hoạt động và được gán, số tiền nguyên dương trong khoảng cho phép, hạn mức, định dạng trường; trả đúng một mã lỗi đầu tiên gặp. | Hệ thống | hệ thống | M | REQ-93 | 024 | UC-19-11 | Đ2 |
| FR-19-024 | Khởi tạo thanh toán tại NCC qua adapter | Chọn NCC theo dịch vụ, gọi adapter (lớp chống nhiễm, ADR-040) để khởi tạo; thành công thì giao dịch chuyển `PENDING` và lưu mã tham chiếu của NCC; lỗi thì xử lý theo BR-19-012. | Hệ thống | hệ thống | M | REQ-93 | 023, 024 | UC-19-11 | Đ2 |
| FR-19-025 | Xử lý người nộp quay về | Nhận lượt quay về từ NCC, xác minh chữ ký tham số, hiển thị trang kết quả trung gian rồi chuyển người nộp về địa chỉ của đối tác kèm kết quả có ký. Lượt quay về **không** được dùng để chốt trạng thái (BR-19-014). | Người nộp tiền; Hệ thống | công khai (có chữ ký) | M | REQ-93, REQ-94 | 012, 024 | UC-19-12 | Đ2 |
| FR-19-026 | Hủy giao dịch chưa thanh toán | Đối tác hoặc cán bộ hủy giao dịch `CREATED`/`PENDING`; nếu NCC có API hủy thì gọi, nếu không thì đánh dấu và xử lý callback thành công đến sau như thanh toán muộn. | HTTT đối tác; Cán bộ tra cứu | partner-pay-create; transaction-cancel | S | REQ-93 | — | UC-19-14 | Đ2 |
| FR-19-027 | Tự động hết hạn giao dịch | Tác vụ nền chuyển giao dịch quá `expires_at` sang `EXPIRED` sau khi đã truy vấn NCC lần cuối và không có kết quả thành công. | Hệ thống | hệ thống | M | REQ-94 | — | UC-19-14 | Đ2 |
| FR-19-028 | Ghi lịch sử trạng thái bất biến | Mỗi lần đổi trạng thái giao dịch ghi một dòng `transaction_event` (trạng thái cũ, mới, nguồn, lý do, người/hệ thống, `trace_id`) trong cùng giao dịch CSDL; không sửa, không xóa. | Hệ thống | hệ thống | M | REQ-94, REQ-98 | 011, 019 | UC-19-11, UC-19-13 | Đ2 |

### 4.5. Nhóm E — Callback / IPN

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-029 | Tiếp nhận và xác minh IPN | Nhận thông báo kết quả từ NCC, xác minh nguồn (IP, mTLS nếu có), chữ ký, thời hạn và tính duy nhất; ghi nguyên văn vào `callback_inbox` rồi mới trả lời NCC. | PayGov | công khai (xác minh chữ ký) | M | REQ-94, REQ-98 | 010 | UC-19-13 | Đ2 |
| FR-19-030 | Xử lý IPN đúng một lần | Xử lý bản ghi inbox: khóa giao dịch, đối chiếu số tiền và mã tham chiếu, chuyển trạng thái theo máy trạng thái, ghi sự kiện và outbox trong một giao dịch CSDL; IPN lặp lại cho cùng kết quả thì không đổi gì. | Hệ thống | hệ thống | M | REQ-94 | 010 | UC-19-13 | Đ2 |
| FR-19-031 | Cách ly IPN bất thường | IPN sai số tiền, không tìm thấy giao dịch, trái trạng thái, hoặc báo thành công cho giao dịch đã hết hạn/hủy được đánh dấu, cảnh báo, và sinh bản ghi chênh lệch khi cần. | Hệ thống | hệ thống | M | REQ-94, REQ-95 | 010 | UC-19-13 | Đ2 |
| FR-19-032 | Xem và xử lý lại IPN | Cán bộ xem danh sách IPN theo trạng thái xử lý, xem nguyên văn đã che, và yêu cầu xử lý lại một IPN lỗi sau khi nguyên nhân được khắc phục. | Cán bộ tra cứu; Cán bộ ATTT | callback-read; callback-replay | S | REQ-94 | 010 | UC-19-16 | Đ2 |

### 4.6. Nhóm F — Idempotency

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-033 | Bảo đảm idempotency theo `Idempotency-Key` | Mọi API ghi của đối tác bắt buộc header `Idempotency-Key`; cùng khóa và cùng nội dung trả lại đúng phản hồi cũ, cùng khóa khác nội dung bị từ chối, yêu cầu đang xử lý trả 409. | HTTT đối tác | partner-pay-create | M | REQ-94 | 024 | UC-19-11 | Đ2 |
| FR-19-034 | Chống trùng theo mã đơn hàng của đối tác | Trong một đối tác, một `partner_order_id` chỉ có tối đa một giao dịch chưa kết thúc hoặc đã thành công; yêu cầu trùng trả lỗi kèm mã giao dịch hiện có. | Hệ thống | hệ thống | M | REQ-94 | 024 | UC-19-11 | Đ2 |

### 4.7. Nhóm G — Truy vấn và đồng bộ trạng thái

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-035 | Đối tác truy vấn trạng thái giao dịch | Truy vấn theo mã giao dịch hoặc theo `partner_order_id`; trả trạng thái hiện tại, thời điểm thanh toán, số tiền, mã tham chiếu NCC; chỉ thấy giao dịch của chính đối tác. | HTTT đối tác | partner-pay-read | M | REQ-93, REQ-94 | — | UC-19-15 | Đ2 |
| FR-19-036 | Chủ động truy vấn NCC cho giao dịch treo | Tác vụ nền truy vấn NCC cho giao dịch `PENDING` chưa có IPN theo lịch giãn dần (BR-19-016) và áp kết quả như một IPN. | Hệ thống | hệ thống | M | REQ-94 | — | UC-19-16 | Đ2 |
| FR-19-037 | Đồng bộ trạng thái thủ công | Cán bộ yêu cầu truy vấn NCC ngay cho một giao dịch; kết quả hiển thị và được áp theo cùng quy tắc với FR-19-036; giới hạn tần suất mỗi giao dịch. | Cán bộ tra cứu | transaction-sync | S | REQ-94, REQ-97 | — | UC-19-16 | Đ2 |

### 4.8. Nhóm H — Hoàn tiền

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-038 | Lập yêu cầu hoàn tiền | Lập yêu cầu hoàn toàn phần hoặc một phần cho giao dịch `SUCCEEDED`/`PARTIALLY_REFUNDED`, kèm lý do và tài liệu; tổng hoàn không vượt số tiền gốc. Đối tác lập qua API, kế toán lập trên màn hình. | Kế toán; HTTT đối tác | refund-create; partner-refund-create | M | REQ-96 | 025 | UC-19-17 | Đ2 |
| FR-19-039 | Phê duyệt hoặc từ chối hoàn tiền | Người phê duyệt khác người lập duyệt hoặc từ chối kèm lý do; yêu cầu vượt ngưỡng số tiền cấu hình cần thêm một người duyệt thứ hai. | Người phê duyệt | refund-approve | M | REQ-96 | 025 | UC-19-18 | Đ2 |
| FR-19-040 | Thực thi hoàn tiền | Chế độ `API`: gọi NCC hoàn tiền và theo dõi kết quả. Chế độ `MANUAL` (khi NCC không có API): kế toán ghi nhận chứng từ hoàn ngoài hệ thống. Chế độ theo cấu hình NCC. | Hệ thống; Kế toán | hệ thống; refund-execute | M | REQ-96 | 025 | UC-19-18 | Đ2 |
| FR-19-041 | Theo dõi kết quả hoàn tiền | Danh sách, chi tiết, lịch sử yêu cầu hoàn; nhận kết quả hoàn từ NCC (IPN hoặc truy vấn); cập nhật trạng thái giao dịch gốc; đối tác truy vấn qua API. | Kế toán; HTTT đối tác | refund-read; partner-pay-read | M | REQ-96 | 025 | UC-19-18 | Đ2 |

### 4.9. Nhóm I — Đối soát và chênh lệch

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-042 | Lập lịch và khởi tạo phiên đối soát | Mỗi ngày tự tạo một phiên cho mỗi NCC `ACTIVE`/`SUSPENDED` cho ngày giao dịch liền trước, theo giờ chốt của tenant; kế toán tạo phiên thủ công cho ngày bất kỳ chưa có phiên. | Hệ thống; Kế toán | hệ thống; recon-run | M | REQ-95 | — | UC-19-19 | Đ2 |
| FR-19-043 | Thu thập dữ liệu đối soát của NCC | Lấy dữ liệu từ NCC theo cách adapter hỗ trợ (tải file, gọi API) hoặc kế toán tải file lên; kiểm tra định dạng, mã băm; lưu file gốc vào kho đối tượng. | Hệ thống; Kế toán | hệ thống; recon-upload | M | REQ-95 | — | UC-19-19 | Đ2 |
| FR-19-044 | So khớp tự động | So từng giao dịch và từng khoản hoàn của hai phía theo mã tham chiếu, số tiền, trạng thái; phân loại dòng khớp và dòng lệch; tính tổng số lượng và tổng tiền hai phía. | Hệ thống | hệ thống | M | REQ-95 | — | UC-19-19 | Đ2 |
| FR-19-045 | Quản lý bản ghi chênh lệch | Danh sách, lọc, chi tiết chênh lệch theo loại, tuổi, người phụ trách; giao việc; chuyển cấp tới NCC; ghi chú và đính kèm. | Kế toán | discrepancy-read; discrepancy-handle | M | REQ-95 | — | UC-19-20 | Đ2 |
| FR-19-046 | Đề xuất và phê duyệt xử lý chênh lệch | Kế toán đề xuất cách xử lý (cập nhật trạng thái theo NCC, lập hoàn tiền, chấp nhận theo số của NCC, ghi nhận không xử lý kèm lý do); người phê duyệt khác người đề xuất duyệt thì hệ thống thực thi. | Kế toán; Người phê duyệt | discrepancy-handle; discrepancy-approve | M | REQ-95 | — | UC-19-20 | Đ2 |
| FR-19-047 | Chốt và mở lại phiên đối soát | Chỉ chốt khi mọi chênh lệch đã `RESOLVED`; phiên đã chốt là bất biến; mở lại cần đề nghị có lý do và phê duyệt. | Kế toán; Người phê duyệt | recon-close; recon-reopen-approve | M | REQ-95 | — | UC-19-21 | Đ2 |
| FR-19-048 | Xuất biên bản và cung cấp kết quả đối soát | Sinh biên bản đối soát (PDF và XLSX) cho phiên đã chốt, lưu kho đối tượng kèm mã băm; đối tác tải kết quả đối soát phần của mình qua API. | Kế toán; HTTT đối tác | report-export; partner-recon-read | S | REQ-95 | — | UC-19-21 | Đ2 |

### 4.10. Nhóm J — Tra cứu giao dịch

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-049 | Danh sách giao dịch, tìm theo từ khóa | Bảng giao dịch với các cột của hệ cũ (dịch vụ, người thanh toán, lĩnh vực, trạng thái, thời điểm) và cột mới; tìm từ khóa theo mã giao dịch, mã đơn hàng, mã tham chiếu NCC, tên dịch vụ, người nộp; phân trang 20 dòng mặc định, sắp xếp. | Mọi vai trò thanh toán | transaction-read | M | REQ-97 | 014, 018 | UC-19-22 | Đ2 |
| FR-19-050 | Tra cứu nâng cao | Lọc kết hợp: lĩnh vực (nhiều), trạng thái (nhiều), khoảng thời gian (mẫu 30 ngày, 90 ngày, quý trước, tùy chọn), đối tác, NCC, dịch vụ, khoảng số tiền, kênh, ngân hàng, cờ giao dịch thử, có chênh lệch. | Mọi vai trò thanh toán | transaction-read | M | REQ-97 | 015, 016, 017 | UC-19-22 | Đ2 |
| FR-19-051 | Xem chi tiết giao dịch | Hiển thị toàn bộ thuộc tính, dòng thời gian trạng thái, các IPN, lần truy vấn NCC, webhook đã gửi, yêu cầu hoàn và chênh lệch liên quan; dữ liệu người nộp bị che nếu thiếu quyền. | Mọi vai trò thanh toán | transaction-read; transaction-read-pii | M | REQ-97 | 019 | UC-19-23 | Đ2 |
| FR-19-052 | Xuất danh sách giao dịch | Xuất kết quả tra cứu ra CSV/XLSX bằng tác vụ nền, giới hạn số dòng, che dữ liệu cá nhân theo quyền, ghi kiểm toán, đường tải có hạn. | Kế toán; Kiểm toán viên | transaction-export | S | REQ-97 | — | UC-19-22 | Đ2 |

### 4.11. Nhóm K — Nhật ký và kiểm toán

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-053 | Ghi nhật ký kiểm toán | Mọi thao tác ghi của người dùng và mọi quyết định phê duyệt được gửi tới PH-13 với ai, khi nào, làm gì, trên đối tượng nào, giá trị trước và sau (đã che bí mật), kết quả. | Hệ thống | hệ thống | M | REQ-97, REQ-98 | 021 | UC-19-24 | Đ2 |
| FR-19-054 | Nhật ký tích hợp giao dịch | Lưu và cho xem từng lượt trao đổi với NCC và đối tác (hướng, thao tác, mã kết quả, độ trễ, nội dung đã che); danh sách có lọc, sắp xếp, chi tiết. | Cán bộ tra cứu; Kiểm toán viên | log-read | M | REQ-97 | 011, 021 | UC-19-24 | Đ2 |
| FR-19-055 | Liên kết truy vết đầu-cuối | Mọi bản ghi giao dịch, sự kiện, nhật ký, webhook mang `trace_id`; từ màn hình chi tiết mở được vết tương ứng ở PH-13. | Cán bộ tra cứu | log-read | S | REQ-97 | 021 | UC-19-23, UC-19-24 | Đ2 |

### 4.12. Nhóm L — Dashboard và báo cáo

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-056 | Dashboard tổng quan | Số dịch vụ, số hệ thống áp dụng, tổng giao dịch, giao dịch trong ngày, biểu đồ giao dịch trong ngày theo dịch vụ (giảm dần), bảng giao dịch trong ngày; bổ sung tổng tiền, tỷ lệ thành công, số giao dịch treo, số chênh lệch mở. | Mọi vai trò thanh toán | dashboard-read | M | REQ-97 | 013, 026 | UC-19-25 | Đ2 |
| FR-19-057 | Dashboard kênh thanh toán | Theo từng NCC: tên, ngày hiệu lực, đầu mối, tình trạng, số dịch vụ, biểu đồ số giao dịch theo ngày trong 30 ngày; bổ sung sức khỏe, độ trễ, tỷ lệ lỗi, hạn chứng thư. | Mọi vai trò thanh toán | dashboard-read | M | REQ-97 | 003, 020, 023 | UC-19-25 | Đ2 |
| FR-19-058 | Báo cáo định kỳ và xuất | Báo cáo theo ngày/tháng/quý: tổng hợp thu theo dịch vụ, lĩnh vực, đối tác, NCC, kênh; hoàn tiền; đối soát; tỷ lệ thành công. Xuất XLSX/PDF. Lập lịch gửi tự động để sau. | Kế toán; Kiểm toán viên | report-read; report-export | S | REQ-97 | — | UC-19-26 | Đ2 (lập lịch gửi: Sau) |
| FR-19-059 | Phát chỉ số vận hành và cảnh báo | Phát metric chuẩn (số giao dịch theo trạng thái, độ trễ NCC, tuổi giao dịch treo, hàng đợi inbox/outbox, webhook lỗi) và bộ luật cảnh báo mặc định tới PH-13. | Hệ thống | hệ thống | M | REQ-97 | 009 | UC-19-25 | Đ2 |

### 4.13. Nhóm M — Thông báo cho đối tác

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-060 | Gửi webhook kết quả có ký | Khi giao dịch hoặc yêu cầu hoàn đạt trạng thái cuối, gửi thông báo tới các địa chỉ của đối tác, ký HMAC-SHA256, kèm mã sự kiện duy nhất và thời điểm; thử lại theo lịch giãn dần (BR-19-020). | Hệ thống | hệ thống | M | REQ-94 | 012 | UC-19-27 | Đ2 |
| FR-19-061 | Phát sự kiện qua outbox | Ghi sự kiện vào `outbox_event` cùng giao dịch CSDL với thay đổi trạng thái, rồi phát lên Kafka theo đúng thứ tự trong từng khóa phân vùng. | Hệ thống | hệ thống | M | REQ-94 | 012 | UC-19-27 | Đ2 |
| FR-19-062 | Theo dõi và gửi lại webhook | Danh sách lượt gửi theo trạng thái, xem chi tiết từng lần thử, gửi lại thủ công một lượt đã hết lần thử. | Cán bộ tra cứu | webhook-read; webhook-resend | S | REQ-94 | 012 | UC-19-27 | Đ2 |

### 4.14. Nhóm N — Cấu hình theo tenant

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-063 | Cấu hình thanh toán của tenant | Xem và sửa tham số: thời hạn giao dịch, giờ chốt đối soát, hạn xử lý chênh lệch, bật hoàn tiền, ngưỡng duyệt hai cấp, hạn hoàn tiền, lịch thử lại webhook, thời gian lưu; mỗi lần sửa tạo phiên bản mới có hiệu lực từ thời điểm xác định. | Quản trị thanh toán | config-read; config-write | M | REQ-98 | — | UC-19-28 | Đ2 |
| FR-19-064 | Khởi tạo và tạm ngừng phân hệ theo tenant | Khi PH-20 bật PH-19 cho một tenant: tạo cấu hình mặc định, topic, chính sách RLS; khi tắt: chặn giao dịch mới, giữ nguyên dữ liệu và việc đối soát dở. | PH-20; Quản trị tenant | hệ thống | M | REQ-98 | — | UC-19-28 | Đ2 |

### 4.15. Nhóm O — Di trú từ hệ cũ và chạy song song

| Mã | Tên | Mô tả | Tác nhân | Quyền | ƯT | REQ | LGC | UC | Đợt |
|---|---|---|---|---|---|---|---|---|---|
| FR-19-065 | Nhập danh mục và giao dịch lịch sử từ hệ cũ | Nhập năm bảng của hệ cũ theo lô, chuyển đổi kiểu (số tiền, ngày thanh toán, trạng thái), ghi `legacy_mapping`; chạy lại được nhiều lần mà không sinh trùng; báo cáo dòng lỗi. | Quản trị thanh toán | migration-run | M | REQ-99 | 011, 022 | UC-19-29 | Đ2 |
| FR-19-066 | Chuyển chế độ định tuyến theo đối tác | Mỗi đối tác có chế độ `LEGACY`, `SHADOW` (hệ cũ xử lý, Datahub ghi nhận song song để so sánh) hoặc `DATAHUB`; chuyển chế độ cần phê duyệt và quay lui được. | Quản trị thanh toán; Người phê duyệt | migration-switch | M | REQ-99 | — | UC-19-29 | Đ2 |
| FR-19-067 | Lớp tương thích API hệ cũ | Cung cấp mặt nạ API theo hợp đồng của hệ cũ cho đối tác chưa kịp sửa mã, ánh xạ sang API mới; có ngày ngừng hỗ trợ công bố trước. | HTTT đối tác | partner-pay-create | C | REQ-99 | 024 | UC-19-29 | Sau (chỉ làm khi OQ-19-17 xác nhận cần) |
| FR-19-068 | Đối chiếu sau di trú | So số lượng, tổng tiền, phân bố trạng thái giữa hệ cũ và Datahub theo tháng và theo đối tác; liệt kê từng bản ghi lệch; kết quả là điều kiện để chuyển chế độ. | Kế toán; Quản trị thanh toán | migration-run | M | REQ-99 | — | UC-19-29 | Đ2 |

