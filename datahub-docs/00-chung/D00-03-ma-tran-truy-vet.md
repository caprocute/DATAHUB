---
ma_tai_lieu: D00-03
ten: Ma trận truy vết (RTM) — Phần A, kiểm kê chức năng hệ LGSP cũ
phien_ban: 0.4
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, Quản lý dự án, Đội kỹ thuật
mo_ta: Ma trận truy vết phần A kiểm kê 186 chức năng hệ LGSP cũ theo chín khối, kết luận cho từng chức năng và tổng hợp độ phủ vào Datahub.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước §3; D01-01 Báo cáo nghiên cứu khả thi; D02-02 SRS; D02-03 FRS PH-04, PH-07; D05-02 Test case PH-04, PH-07
---

# D00-03 · Ma trận truy vết

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Ma trận chứng minh hai điều chủ đầu tư yêu cầu. Thứ nhất, Datahub phủ toàn bộ nghiệp vụ của hệ LGSP cũ: mỗi chức năng cũ có một kết luận rõ ràng và có chỗ hiện thực trong hệ mới. Thứ hai, mọi yêu cầu đi được tới kiểm thử, từ mục tiêu nghiệp vụ qua yêu cầu chức năng, API, dữ liệu, màn hình tới test case.

**Phạm vi.** Bản này hoàn thiện phần A, kiểm kê 186 chức năng hệ cũ (mã `LGC`) thuộc chín khối Bus, Tooling, Hub, APIM, DMDC, PAY, NGSP, IAM và NFR, kèm kết luận, phân hệ đích và ghi chú chuyển hóa. Phần B (ánh xạ tới FR, US, UC, API và kiểm thử) đã có ở mục 5.2, sinh bằng script từ các tập phân hệ; phần C, D (ánh xạ dọc, ánh xạ pháp lý) hoàn thiện dần ở các đợt sau.

**Căn cứ.** Kiểm kê lập từ tài liệu thiết kế và hướng dẫn của hệ cũ trong thư mục `lgsp_document` (mục 2). Phần D sẽ ánh xạ các căn cứ CMP-LAW trong D00-01 §7 tới yêu cầu và bằng chứng kiểm chứng; công văn 631/THH-THHT của hệ cũ là CMP-LAW-09.

**Những điểm hội đồng cần lưu ý.** (1) Mọi chức năng có đúng một trong bốn kết luận Giữ nguyên, Nâng cấp, Thay thế, Loại bỏ (D00-01 §3.2), riêng một mục hợp đồng bảo trì xếp là "Khác". (2) Chỉ ba mục bị loại bỏ, đều đã được chủ đầu tư chấp thuận ngày 21/11/2026 (mục 5.1): sửa pom, nhập JAR, đăng nhập mạng xã hội, vì rủi ro chuỗi cung ứng, kiểm soát phần mềm cấp độ 3 và tính phù hợp với cơ quan nhà nước. (3) Phụ lục `PTYC_Toolings.xlsx` không có, nên khối Tooling dựa trên giả định GĐ-01 (mục 6). (4) Các giá trị phi chức năng mới ở khối NFR chỉ là dự kiến, chốt tại D02-02.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Chức năng hệ cũ được kiểm kê | 186 |
| Giữ nguyên | 85 |
| Nâng cấp | 72 |
| Thay thế | 25 |
| Loại bỏ | 3 |
| Khác (ngoài phạm vi kỹ thuật) | 1 |
| Khối nghiệp vụ | 9 |
| Giả định ghi ở mục 6 | 3 |

: Con số chính của ma trận truy vết phần A

Các con số được đếm từ bảng ở mục 4 và khớp với bảng tổng hợp ở mục 5.

## 1. Mục đích

Ma trận truy vết chứng minh hai điều mà chủ đầu tư yêu cầu. Thứ nhất, **Datahub phủ toàn bộ nghiệp vụ của hệ LGSP cũ**: mỗi chức năng cũ đều có kết luận rõ ràng và có chỗ hiện thực trong hệ mới. Thứ hai, **mọi yêu cầu đều đi được tới kiểm thử**: từ mục tiêu nghiệp vụ, qua yêu cầu chức năng, tới API, dữ liệu, màn hình và test case.

Tài liệu gồm bốn phần, được hoàn thiện dần theo các đợt viết:

| Phần | Nội dung | Hoàn thành ở đợt |
|---|---|---|
| A | Kiểm kê chức năng hệ cũ (`LGC`) và kết luận cho từng mục | Đợt 0 (bản này) |
| B | Ánh xạ `LGC` → `FR` cụ thể | Đợt 2–4, theo từng phân hệ |
| C | Ánh xạ dọc `BO` → `REQ` → `FR` → `UC/US` → `API/EN/UI` → `TC` | Đợt 2–4 |
| D | Ánh xạ pháp lý `CMP-LAW` → yêu cầu → bằng chứng kiểm chứng | Đợt 1 (khung), Đợt 5 (bằng chứng) |

: Bốn phần của ma trận truy vết và đợt hoàn thành

### 1.1. Phạm vi

Phần A của ma trận chỉ kiểm kê chức năng hệ cũ; việc ánh xạ sang yêu cầu, API, màn hình và test case thuộc các phần B, C, D và các tài liệu phân hệ, như bảng dưới.

| Thuộc tài liệu này (phần A) | Nằm ở tài liệu khác |
|---|---|
| Danh sách `LGC`, kết luận, phân hệ đích, ghi chú | Ánh xạ `LGC` tới FR: FRS từng phân hệ (ví dụ D02-03-PH04 §9.1) |
| Tổng hợp độ phủ, mục loại bỏ, giả định | Ánh xạ tới test case, nghiệm thu: D05-02 từng phân hệ |
| Nguồn kiểm kê từ hệ cũ | Định nghĩa các họ mã và kết luận: D00-01 §3 |

: Phân định phạm vi giữa D00-03 và các tài liệu khác

### 1.2. Người đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, mục 5, 6 | Đánh giá độ phủ nghiệp vụ và các mục loại bỏ |
| Quản lý dự án | Mục 1, 5, 6 | Theo dõi tiến độ hoàn thiện các phần B, C, D |
| Kiến trúc sư, người viết FRS | Mục 3, 4 | Biết chức năng cũ nào thuộc phân hệ của mình và cách chuyển hóa |
| Kiểm thử viên | Mục 4, 5 | Xác định chức năng cũ cần kiểm thử tương đương |

: Người đọc D00-03 và phần cần đọc theo vai trò

### 1.3. Thuật ngữ và chữ viết tắt

Bảng dưới chỉ gồm thuật ngữ riêng của ma trận. Thuật ngữ chung theo D00-01 §2.

| Thuật ngữ | Giải thích |
|---|---|
| `LGC` | Mã chức năng hệ cũ, dạng `LGC-{khối}-{nnn}` |
| RTM | Ma trận truy vết, tên tắt của tài liệu này |
| Kết luận | Một trong Giữ nguyên, Nâng cấp, Thay thế, Loại bỏ (D00-01 §3.2) |
| PH đích | Phân hệ Datahub chịu trách nhiệm hiện thực chức năng |
| Khối | Nhóm chức năng cùng nguồn: Bus, Tooling, Hub, APIM, DMDC, PAY, NGSP, IAM, NFR |
| GĐ | Giả định đã ghi cơ sở, thay cho câu hỏi mở (mục 6) |

: Thuật ngữ riêng của ma trận truy vết

### 1.4. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D00-03.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D00-01 | Thuật ngữ và quy ước chung | Định nghĩa mã `LGC` và bốn kết luận |
| D01-01 | Báo cáo nghiên cứu khả thi | Dùng kết quả kiểm kê để đánh giá phạm vi thay thế hệ cũ |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | Chốt giá trị mới của khối NFR |
| D02-03-PH04, D02-03-PH07 | FRS các phân hệ | Phần B ở mục 5.2 (sinh bằng script từ FRS, use case, test case) |
| D05-02-PH04, D05-02-PH07 | Test case các phân hệ | Ánh xạ tới kiểm thử và nghiệm thu |
| `lgsp_document` | Tài liệu hệ LGSP cũ | Nguồn kiểm kê (mục 2) |

: Tài liệu tham chiếu của D00-03

### 1.5. Cấu trúc tài liệu

Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Nguồn kiểm kê theo khối | Hội đồng, kiến trúc sư |
| 3 | Cách đọc bảng kiểm kê và bốn kết luận | Mọi người đọc |
| 4 | Kiểm kê chức năng hệ cũ, chín khối | Kiến trúc sư, kiểm thử viên |
| 5 | Tổng hợp độ phủ, các mục loại bỏ và phần B truy vết tới FR, US, UC, API, kiểm thử (mục 5.2) | Hội đồng, quản lý dự án, kiểm thử viên |
| 6 | Câu hỏi mở và giả định | Hội đồng, quản lý dự án |

: Cấu trúc chương của D00-03

## 2. Nguồn kiểm kê

Phần A được lập từ các tài liệu trong thư mục `lgsp_document` của dự án. Khi một chức năng xuất hiện ở nhiều phiên bản tài liệu, bản kiểm kê dùng phiên bản mới nhất.

| Khối | Tài liệu nguồn (phiên bản dùng) |
|---|---|
| Bus — quản trị trục tích hợp | `Bus_PhantichThietkeYeucau`, `Bus_ThietKeChiTietv1.5`, `Bus_ThietKeCSDL_v1.2`, `Bus_HDSD_v1.1`, `Bus_ThietkeTongthe` |
| Tooling — công cụ thiết kế luồng | `Bus_PhantichThietkeYeucau` mục Productivity Tooling, `Bus_ThietKeChiTietv1.5` mục Productivity Tooling. Phụ lục `PTYC_Toolings.xlsx` được tham chiếu nhưng không có trong thư mục |
| Hub — trung tâm tích hợp pub/sub | `Hub_ThietKeChiTiet`, `Hub_ThietKeCSDL`, `HDSD.Hubs.v1.0` |
| APIM — quản lý API | `Api_management_HDSD`, phần API Management trong `Bus_ThietkeTongthe` |
| DMDC — danh mục dùng chung Aita | `aita_PhantichThietkeYeucau`, `aita_ThietKeChiTiet_v1.7`, `aita_ThietKeCSDL_v1.1`, `aita_HDSD_v1.2` |
| PAY — thanh toán | `payment_PhantichThietkeYeucau_v1.2`, `paymentService_TKCT_v1.7`, `payment_ThietKeCSDL`, `payment_HDSD` |
| NGSP — kết nối quốc gia | `phucluc_ketnoiNGSP` |
| IAM — định danh | Mục Keycloak trong các PTYC, `huongdanlaytokenkeycloak` |
| NFR — phi chức năng, vận hành | Mục 4 của các PTYC, các tài liệu HDVH và hướng dẫn cài đặt |

: Tài liệu nguồn của hệ cũ theo khối kiểm kê

## 3. Cách đọc bảng kiểm kê

Mỗi dòng là một chức năng của hệ cũ. Cột **Kết luận** dùng bốn giá trị định nghĩa tại D00-01 §3.2:

- **Giữ nguyên:** hệ mới có hành vi tương đương với hệ cũ.
- **Nâng cấp:** giữ mục đích của chức năng nhưng làm đầy đủ hơn, an toàn hơn hoặc tự động hơn.
- **Thay thế:** mục đích được đáp ứng bằng một cơ chế khác, thường do thay đổi công nghệ (ví dụ JMX được thay bằng OpenTelemetry).
- **Loại bỏ:** không đưa sang hệ mới. Mỗi dòng loại bỏ phải có lý do và được chủ đầu tư chấp thuận. Ba mục loại bỏ ở §5.1 đã được chấp thuận ngày 21/11/2026.

Cột **PH đích** là phân hệ Datahub chịu trách nhiệm. Cột **Màn hình vận hành** đánh dấu những màn hình có giá trị vận hành mà theo quyết định Q4 phải được giữ lại dưới dạng thiết kế mới.

## 4. Kiểm kê chức năng hệ cũ

### 4.1. Bus — quản trị trục tích hợp (`LGC-BUS`)

Khối Bus của hệ cũ quản trị các "chương trình tích hợp". Mỗi chương trình là một **agent**, tức một tiến trình Apache Camel chạy trên một máy chủ (lưu `host_ip`, `host_port`), chứa nhiều route. Màn hình quản trị đọc số liệu của agent qua JMX và Jolokia. Trong Datahub, agent được thay bằng **đơn vị triển khai luồng** trên Kubernetes, số liệu được thu bằng OpenTelemetry, còn thao tác bật tắt được thực hiện qua control plane có kiểm soát và ghi kiểm toán.

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Màn hình vận hành | Ghi chú chuyển hóa |
|---|---|---|---|---|---|
| LGC-BUS-001 | Hiển thị danh sách chương trình tích hợp (agent), có phân trang | Nâng cấp | PH-04 | Có | Danh sách luồng tích hợp kèm trạng thái triển khai, phiên bản, tenant |
| LGC-BUS-002 | Tìm kiếm chương trình tích hợp theo endpoint | Giữ nguyên | PH-04 | — | Tìm theo URI endpoint của route |
| LGC-BUS-003 | Tìm kiếm theo nguồn | Giữ nguyên | PH-04 | — | Tìm theo HTTT nguồn |
| LGC-BUS-004 | Tìm kiếm theo tên | Giữ nguyên | PH-04 | — | |
| LGC-BUS-005 | Tìm kiếm theo host | Thay thế | PH-04 | — | Không còn host cố định; tìm theo môi trường, namespace, đơn vị triển khai |
| LGC-BUS-006 | Xem metadata của chương trình tích hợp (người tạo, ngày, mô tả, agent URL) | Nâng cấp | PH-04 | Có | Bổ sung chủ sở hữu, HTTT liên quan, phiên bản, lịch sử thay đổi |
| LGC-BUS-007 | Biểu đồ histogram lượng message đi qua và thất bại theo giây | Thay thế | PH-13 | Có | Bảng điều khiển theo luồng: thông lượng, tỷ lệ lỗi, độ trễ p50/p95/p99 |
| LGC-BUS-008 | Hiển thị các luồng (route) của chương trình | Giữ nguyên | PH-04 | Có | |
| LGC-BUS-009 | Chức năng điều khiển: Start/Stop agent | Nâng cấp | PH-04 | Có | Kích hoạt / tạm dừng luồng có phân quyền, lý do bắt buộc, ghi kiểm toán |
| LGC-BUS-010 | Xóa chương trình tích hợp (agent) | Nâng cấp | PH-04 | — | Gỡ bỏ có kiểm tra phụ thuộc (gói sử dụng, HTTT đang gọi), xóa mềm |
| LGC-BUS-011 | Sửa thông tin kết nối của chương trình (host, port, method) | Thay thế | PH-04, PH-05 | — | Sửa cấu hình qua phiên bản mới của luồng hoặc tham số adapter; không sửa trực tiếp trên runtime |
| LGC-BUS-012 | Kích hoạt / hủy chương trình tích hợp | Nâng cấp | PH-04 | — | Gộp với LGC-BUS-009, theo máy trạng thái của luồng |
| LGC-BUS-013 | Thêm mới chương trình tích hợp, có kiểm tra kết nối | Nâng cấp | PH-04 | — | Tạo luồng từ khuôn mẫu, chạy thử trước khi phát hành |
| LGC-BUS-014 | Tổng quan toàn hệ thống: số agent hoạt động / tổng số agent | Thay thế | PH-13 | Có | Bảng điều khiển tổng quan data plane |
| LGC-BUS-015 | Hiển thị dữ liệu từng agent: tổng route, tổng endpoint, thành công, thất bại, thời gian xử lý trung bình | Thay thế | PH-13 | Có | Theo đơn vị triển khai và theo luồng |
| LGC-BUS-016 | Đồ thị bộ nhớ và CPU của từng agent | Thay thế | PH-13 | Có | Chỉ số pod/container từ Prometheus |
| LGC-BUS-017 | Xem chi tiết agent | Thay thế | PH-04, PH-13 | Có | Chi tiết đơn vị triển khai: phiên bản, số bản sao, sức khỏe |
| LGC-BUS-018 | Hiển thị dữ liệu các route của agent | Giữ nguyên | PH-04 | Có | |
| LGC-BUS-019 | Chi tiết route: biểu đồ tổng thực hiện theo từng route | Thay thế | PH-13 | Có | |
| LGC-BUS-020 | Tab các điểm kết nối (endpoint) của agent | Giữ nguyên | PH-04 | Có | Danh sách endpoint, phương thức, đường dẫn, số lần gọi |
| LGC-BUS-021 | Tab bảng thuộc tính của route | Giữ nguyên | PH-04 | Có | Thuộc tính lấy từ định nghĩa luồng, không đọc từ JMX |
| LGC-BUS-022 | Tab đồ thị (sơ đồ) của route | Nâng cấp | PH-04 | Có | Sơ đồ luồng từ trình thiết kế, phủ số liệu chạy thật lên từng bước |
| LGC-BUS-023 | Tab mã nguồn của route | Nâng cấp | PH-04 | Có | Xem YAML theo phiên bản, so sánh khác biệt giữa hai phiên bản |
| LGC-BUS-024 | Tab dữ liệu thêm của route | Giữ nguyên | PH-04 | — | |
| LGC-BUS-025 | Xem trạng thái hoạt động / dừng của agent | Giữ nguyên | PH-04 | Có | |
| LGC-BUS-026 | Start/Stop từng route | Nâng cấp | PH-04 | Có | Như LGC-BUS-009 ở cấp route |
| LGC-BUS-027 | Thống kê theo endpoint: lưu lượng, bản tin gần nhất, lỗi xảy ra, most called API | Thay thế | PH-13 | Có | |
| LGC-BUS-028 | Thông tin REST API của agent: URI và trạng thái | Thay thế | PH-02, PH-04 | — | API công bố được quản lý tại danh mục dịch vụ |
| LGC-BUS-029 | Quản trị log của agent và chi tiết log | Thay thế | PH-13 | Có | Tra cứu log tập trung theo luồng, theo `trace_id` |
| LGC-BUS-030 | Lấy dữ liệu từ JMX/Jolokia về route và endpoint | Thay thế | PH-13 | — | OpenTelemetry và Micrometer; không mở JMX ra ngoài |
| LGC-BUS-031 | Cấu hình hệ thống: API lấy và cập nhật thông số hệ thống | Nâng cấp | PH-18, PH-20 | — | Cấu hình theo tenant, có phiên bản |
| LGC-BUS-032 | Quản lý project và group, phân quyền project theo group (`Project`, `Group`, `Project_group.access_level`) | Nâng cấp | PH-04, PH-12 | — | Không gian làm việc (workspace) theo đơn vị, phân quyền theo vai trò |
| LGC-BUS-033 | Lưu context Camel (XML) kèm trạng thái và file đính kèm (`Context`, `Context_status`, `Context_file`, `File`) | Thay thế | PH-04 | — | Định nghĩa luồng lưu trong Git theo GitOps, có phiên bản |
| LGC-BUS-034 | Quản lý dependency Maven của luồng (`Dependency`, `Builder`) | Thay thế | PH-04 | — | Danh mục thành phần được duyệt sẵn; không cho người dùng tự thêm thư viện |
| LGC-BUS-035 | Routing: chuyển dữ liệu giữa các kênh | Giữ nguyên | PH-04 | — | Mẫu EIP định tuyến |
| LGC-BUS-036 | Transformation: chuyển đổi định dạng và kiểu dữ liệu | Nâng cấp | PH-04, PH-07 | — | Thêm chuyển đổi ngữ nghĩa theo danh mục |
| LGC-BUS-037 | Error handling: thực hiện lại hoặc bỏ qua | Nâng cấp | PH-04, PH-18 | Có | Chính sách retry chuẩn, DLQ, xử lý bản tin lỗi |
| LGC-BUS-038 | Logging quá trình routing | Thay thế | PH-13 | — | Trace phân tán |
| LGC-BUS-039 | Hai loại bản tin: document message và event message | Giữ nguyên | PH-04, PH-10 | — | Đồng bộ qua PH-04, bất đồng bộ qua PH-10 |
| LGC-BUS-040 | Connector: CSDL (Oracle, MySQL…), NoSQL (MongoDB, Cassandra), LDAP, Hadoop, message broker (AMQP, MQTT), HTTP, SOAP, FTP, File, cloud, SMPP, lập lịch | Nâng cấp | PH-05 | — | Danh mục adapter có phiên bản; mỗi loại có Kamelet được duyệt |
| LGC-BUS-041 | Bảo mật route (Shiro, Spring), mã hóa bản tin, bảo mật endpoint (Basic, SSL, WS-Security) | Nâng cấp | PH-03, PH-04, PH-12 | — | OAuth 2.1, mTLS, mã hóa trường nhạy cảm |

: Bus — quản trị trục tích hợp (LGC-BUS)

### 4.2. Tooling — công cụ thiết kế luồng (`LGC-TOOL`)

Hệ cũ có studio kéo thả viết bằng Angular, sinh Camel XML và tự cập nhật file pom. Datahub thay bằng trình thiết kế luồng React dùng Camel YAML DSL. Repo DATAHUB đã có một bản hiện thực vượt về chức năng so với hệ cũ, nên phần lớn các dòng dưới đây có kết luận Nâng cấp.

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Ghi chú chuyển hóa |
|---|---|---|---|---|
| LGC-TOOL-001 | Thanh Project: hiển thị danh sách project | Nâng cấp | PH-04 | Danh sách luồng theo không gian làm việc |
| LGC-TOOL-002 | Thêm mới project | Nâng cấp | PH-04 | Tạo luồng từ khuôn mẫu hoặc từ API trong danh mục |
| LGC-TOOL-003 | Thanh Component chế độ thu gọn: danh sách component theo nhóm | Giữ nguyên | PH-04 | Bảng thành phần theo nhóm |
| LGC-TOOL-004 | Thanh Component chế độ mở rộng: icon chi tiết | Giữ nguyên | PH-04 | |
| LGC-TOOL-005 | Tìm kiếm component theo tên | Giữ nguyên | PH-04 | |
| LGC-TOOL-006 | Nhóm Routing component | Giữ nguyên | PH-04 | |
| LGC-TOOL-007 | Nhóm Data Transformation (XML, JSON, Text) | Nâng cấp | PH-04 | Bổ sung trình ánh xạ dữ liệu sinh biểu thức JQ |
| LGC-TOOL-008 | Nhóm Database Connection (MongoDB, SQL, Cassandra, HBase…) | Nâng cấp | PH-04, PH-05 | Chỉ dùng kết nối đã đăng ký ở PH-05; không nhập mật khẩu trên trình thiết kế |
| LGC-TOOL-009 | Nhóm Network (HTTP, File, FTP, REST…) | Giữ nguyên | PH-04 | |
| LGC-TOOL-010 | Nhóm Message Broker (RabbitMQ, ActiveMQ, Pulsar, Kafka…) | Nâng cấp | PH-04, PH-10 | Ưu tiên Kafka nội bộ qua topic đã đăng ký |
| LGC-TOOL-011 | Nhóm Scheduling | Giữ nguyên | PH-04 | |
| LGC-TOOL-012 | Nhóm bảo mật (mã hóa gói tin, điểm cuối) | Nâng cấp | PH-04, PH-09 | Bước mã hóa / che dữ liệu nhạy cảm |
| LGC-TOOL-013 | Đường kết nối giữa các component | Giữ nguyên | PH-04 | |
| LGC-TOOL-014 | Lưu kết quả thiết kế của project | Nâng cấp | PH-04 | Lưu nháp tự động, lịch sử hoàn tác |
| LGC-TOOL-015 | Tải xuống mã XML sinh ra | Thay thế | PH-04 | Tải YAML; XML không còn là định dạng chuẩn |
| LGC-TOOL-016 | Xóa project | Giữ nguyên | PH-04 | |
| LGC-TOOL-017 | Xóa nội dung kéo thả trên vùng thiết kế (Clear Page) | Giữ nguyên | PH-04 | |
| LGC-TOOL-018 | Thu / phóng màn hình | Giữ nguyên | PH-04 | |
| LGC-TOOL-019 | Thanh Properties: thuộc tính theo component và theo route | Nâng cấp | PH-04 | Biểu mẫu sinh từ catalog Camel, có kiểm tra hợp lệ |
| LGC-TOOL-020 | Lưu dữ liệu gốc trước khi sửa, reset tham số | Giữ nguyên | PH-04 | |
| LGC-TOOL-021 | Đồng bộ hai chiều giữa khung kéo thả, thuộc tính và mã nguồn | Giữ nguyên | PH-04 | Đồng bộ với YAML |
| LGC-TOOL-022 | Cập nhật file pom theo luồng tích hợp | Loại bỏ | — | Lý do: phụ thuộc do nền tảng quản lý; cho người dùng sửa pom là rủi ro chuỗi cung ứng |
| LGC-TOOL-023 | Thêm / xóa component trong route, chèn ngang hoặc dọc | Giữ nguyên | PH-04 | |
| LGC-TOOL-024 | Tạo / xóa kết nối giữa hai component; bắt kết nối khi thả giữa hai component | Giữ nguyên | PH-04 | |
| LGC-TOOL-025 | Xử lý nhiều component và nhiều route đồng thời | Giữ nguyên | PH-04 | |
| LGC-TOOL-026 | Source Tab: dịch ra mã nguồn khi kéo thả; vẽ lại sơ đồ từ mã nguồn | Giữ nguyên | PH-04 | |
| LGC-TOOL-027 | Nhập component từ file JAR | Loại bỏ | — | Lý do: nạp mã tùy ý vào runtime vi phạm yêu cầu ATTT cấp độ 3; thay bằng quy trình đăng ký Kamelet có duyệt |
| LGC-TOOL-028 | Data mapping: nhập tài liệu mẫu, export mapping, reset mapping | Nâng cấp | PH-04 | Trình ánh xạ dữ liệu sinh JQ, lưu cùng phiên bản luồng |
| LGC-TOOL-029 | Phiên nháp (`draft_session`) lưu XML đang soạn | Giữ nguyên | PH-04 | |

: Tooling — công cụ thiết kế luồng (LGC-TOOL)

### 4.3. Hub — trung tâm tích hợp publish/subscribe (`LGC-HUB`)

Khối Hub dùng Apache Pulsar. Dữ liệu cốt lõi gồm dự án tích hợp (`project`), topic (có thể phân vùng, có cấu trúc dữ liệu và chế độ định tuyến), publisher, subscriber, publication (publisher gắn với topic) và subscription (subscriber gắn với topic, kèm URI nhận, số worker, số lần thử lại, thời điểm bắt đầu). Datahub chuyển sang Kafka và giữ nguyên các khái niệm nghiệp vụ này.

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Màn hình vận hành | Ghi chú chuyển hóa |
|---|---|---|---|---|---|
| LGC-HUB-001 | Dashboard: tổng số publisher | Giữ nguyên | PH-10 | Có | |
| LGC-HUB-002 | Dashboard: tổng số subscriber | Giữ nguyên | PH-10 | Có | |
| LGC-HUB-003 | Dashboard: tổng số project | Giữ nguyên | PH-10 | Có | |
| LGC-HUB-004 | Dashboard: tổng số topic | Giữ nguyên | PH-10 | Có | |
| LGC-HUB-005 | Biểu đồ % Memory theo giây | Thay thế | PH-13 | Có | Chỉ số cụm Kafka |
| LGC-HUB-006 | Biểu đồ % CPU theo giây | Thay thế | PH-13 | Có | |
| LGC-HUB-007 | Sơ đồ kết nối publisher → topic → subscriber (Integration Project Connections) | Nâng cấp | PH-10 | Có | Sơ đồ tương tác, lọc theo dự án, phủ độ trễ tiêu thụ (consumer lag) |
| LGC-HUB-008 | Quản lý dự án tích hợp (project) | Giữ nguyên | PH-10 | — | |
| LGC-HUB-009 | Quản lý topic: tên, mô tả, phân vùng, cấu trúc, chế độ định tuyến | Nâng cấp | PH-10 | — | Bắt buộc đăng ký schema; cấu hình lưu giữ |
| LGC-HUB-010 | Quản lý publisher: tên, kiểu giao tiếp, khóa tham chiếu | Nâng cấp | PH-10, PH-01 | — | Publisher phải là HTTT thành viên |
| LGC-HUB-011 | Quản lý subscriber, đánh dấu subscriber là luồng tích hợp | Nâng cấp | PH-10, PH-01 | — | |
| LGC-HUB-012 | Quản lý publication (publisher ↔ topic) | Giữ nguyên | PH-10 | — | Quyền phát trên topic |
| LGC-HUB-013 | Quản lý subscription: URI nhận, số worker, số lần thử lại, thời điểm bắt đầu | Nâng cấp | PH-10 | — | Hai chế độ giao nhận: đẩy về URI (webhook có ký) hoặc HTTT tự kéo |
| LGC-HUB-014 | Danh mục kiểu giao tiếp (`type_of_comm`) và chế độ định tuyến (`routing_mode`) | Giữ nguyên | PH-10 | — | Danh mục cấu hình |

: Hub — trung tâm tích hợp publish/subscribe (LGC-HUB)

### 4.4. APIM — quản lý API (`LGC-APIM`)

Khối API Management của hệ cũ có mô hình tương tự Gravitee. Datahub tách thành ba phân hệ: danh mục và vòng đời API (PH-02), thực thi tại gateway (PH-03), và cổng nhà phát triển (PH-15).

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Màn hình vận hành | Ghi chú chuyển hóa |
|---|---|---|---|---|---|
| LGC-APIM-001 | Hiển thị danh sách API | Giữ nguyên | PH-02 | Có | |
| LGC-APIM-002 | Tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend | Nâng cấp | PH-02 | — | Bắt buộc đặc tả OpenAPI; context-path theo quy ước |
| LGC-APIM-003 | Tạo API bằng cách nạp Swagger | Nâng cấp | PH-02 | — | Nạp OpenAPI 3.x từ tệp hoặc URL, kiểm tra hợp lệ |
| LGC-APIM-004 | Tạo API chưa triển khai, hoặc tạo và triển khai ngay | Nâng cấp | PH-02 | — | Vòng đời có bước duyệt |
| LGC-APIM-005 | Start / Stop API | Giữ nguyên | PH-02, PH-03 | Có | |
| LGC-APIM-006 | Publish / Unpublish API lên portal | Giữ nguyên | PH-02, PH-15 | — | |
| LGC-APIM-007 | Make Public: mọi người dùng xem được thông tin API | Giữ nguyên | PH-15 | — | Mức hiển thị: nội bộ tenant, toàn bộ CQNN, công khai |
| LGC-APIM-008 | Xóa API | Nâng cấp | PH-02 | — | Chỉ xóa được khi không còn đăng ký sử dụng; nếu còn thì phải ngừng dùng có báo trước |
| LGC-APIM-009 | Plan với bốn trạng thái Staging, Published, Deprecated, Closed | Giữ nguyên | PH-02 | — | Gói sử dụng giữ nguyên bốn trạng thái |
| LGC-APIM-010 | Plan bước Define: metadata, nhóm được phép truy cập | Giữ nguyên | PH-02 | — | |
| LGC-APIM-011 | Plan bước Secure: Keyless hoặc API key | Nâng cấp | PH-02, PH-03 | — | Thêm OAuth 2.1 client_credentials và mTLS; Keyless chỉ cho API dữ liệu mở |
| LGC-APIM-012 | Plan bước Restriction: rate limit (giây, phút) | Giữ nguyên | PH-03 | — | |
| LGC-APIM-013 | Plan bước Restriction: quota (giờ, ngày, tháng) | Giữ nguyên | PH-03 | — | |
| LGC-APIM-014 | Plan bước Restriction: whitelist / blacklist đường dẫn | Giữ nguyên | PH-03 | — | |
| LGC-APIM-015 | Plan bước Policies | Nâng cấp | PH-03 | — | Bộ chính sách gateway được duyệt sẵn |
| LGC-APIM-016 | Quản lý subscription theo API | Giữ nguyên | PH-02 | Có | |
| LGC-APIM-017 | Xem chi tiết đường dẫn sử dụng API (gateway URL + context path) | Giữ nguyên | PH-02, PH-15 | — | |
| LGC-APIM-018 | Quản lý endpoint backend của API | Giữ nguyên | PH-02 | — | Nhiều backend, cân bằng tải, kiểm tra sức khỏe |
| LGC-APIM-019 | Danh sách Application | Nâng cấp | PH-01 | Có | Application trở thành HTTT thành viên có hồ sơ kết nạp |
| LGC-APIM-020 | Tạo Application: tên, mô tả, loại, Client ID | Nâng cấp | PH-01, PH-12 | — | Cấp định danh qua quy trình kết nạp có duyệt |
| LGC-APIM-021 | Quản lý subscription theo Application | Giữ nguyên | PH-02 | Có | |
| LGC-APIM-022 | Log toàn bộ request đến API của Application, xem chi tiết một log | Nâng cấp | PH-03, PH-13 | Có | Che dữ liệu nhạy cảm trong log |
| LGC-APIM-023 | Danh sách gateway đang kết nối | Thay thế | PH-03, PH-13 | Có | Danh sách nút gateway và trạng thái đồng bộ cấu hình |
| LGC-APIM-024 | Chi tiết một gateway | Thay thế | PH-13 | Có | |
| LGC-APIM-025 | Giám sát gateway: CPU, Java heap, JVM | Thay thế | PH-13 | Có | APISIX không chạy JVM; giám sát theo chỉ số của APISIX |
| LGC-APIM-026 | Dashboard hoạt động chung của hệ thống API | Giữ nguyên | PH-13 | Có | |
| LGC-APIM-027 | Audit: thông tin tác động hệ thống | Nâng cấp | PH-13 | Có | Nhật ký kiểm toán không sửa được (WORM) |

: APIM — quản lý API (LGC-APIM)

### 4.5. DMDC — danh mục dùng chung Aita (`LGC-DMDC`)

Hệ cũ lưu danh mục theo mô hình thực thể – thuộc tính – giá trị: bảng `Category` (mã, tên, cờ cho phép cập nhật), `category_fields` (thuộc tính do người dùng khai báo, có thứ tự và trạng thái), `Category_details` (bản ghi) và `Category_details_value` (giá trị theo từng thuộc tính, tối đa 2.000 ký tự). Datahub giữ khả năng **khai báo thuộc tính động** nhưng thêm kiểu dữ liệu, ràng buộc, phân cấp, phiên bản và đồng bộ với danh mục quốc gia.

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Màn hình vận hành | Ghi chú chuyển hóa |
|---|---|---|---|---|---|
| LGC-DMDC-001 | Danh sách danh mục, số lượng danh mục | Giữ nguyên | PH-07 | Có | |
| LGC-DMDC-002 | Hiển thị dữ liệu danh mục dạng cây | Giữ nguyên | PH-07 | Có | Cây theo mã cha cho danh mục phân cấp |
| LGC-DMDC-003 | Xem chi tiết danh mục: tên, danh sách thuộc tính, danh sách bản ghi | Giữ nguyên | PH-07 | Có | |
| LGC-DMDC-004 | Tạo danh mục bằng nhập tay: tên, danh sách thuộc tính | Nâng cấp | PH-07 | — | Thuộc tính có kiểu, bắt buộc, duy nhất, miền giá trị |
| LGC-DMDC-005 | Tạo danh mục từ tệp xlsx / csv theo khuôn: ô A2 là tên, dòng 4 là tên thuộc tính, từ dòng 5 là bản ghi; mã hóa UTF-16 | Nâng cấp | PH-07 | — | Khuôn mẫu tải về được; hỗ trợ UTF-8; xem trước và báo lỗi theo dòng trước khi ghi |
| LGC-DMDC-006 | Nhập dữ liệu danh mục từ Excel (service) | Nâng cấp | PH-07 | — | Xử lý nền cho tệp lớn |
| LGC-DMDC-007 | Nhập dữ liệu danh mục từ CSV (service) | Nâng cấp | PH-07 | — | |
| LGC-DMDC-008 | Nhập dữ liệu danh mục từ API: thêm tên danh mục, thêm thuộc tính, thêm bản ghi | Nâng cấp | PH-07 | — | API nhập theo lô, idempotent |
| LGC-DMDC-009 | Cập nhật tên danh mục | Giữ nguyên | PH-07 | — | |
| LGC-DMDC-010 | Cập nhật danh sách thuộc tính: thêm, sửa, xóa | Nâng cấp | PH-07 | — | Đổi thuộc tính tạo phiên bản mới, không phá dữ liệu cũ |
| LGC-DMDC-011 | Cập nhật danh sách bản ghi: thêm, sửa, xóa | Nâng cấp | PH-07 | — | Sửa trên bản nháp, phát hành thành phiên bản |
| LGC-DMDC-012 | Xóa danh mục | Nâng cấp | PH-07 | — | Chỉ xóa khi chưa phát hành; đã phát hành thì ngừng hiệu lực |
| LGC-DMDC-013 | Xuất danh mục ra Excel | Giữ nguyên | PH-07 | — | Xuất theo phiên bản |
| LGC-DMDC-014 | Xuất danh mục ra CSV | Giữ nguyên | PH-07 | — | |
| LGC-DMDC-015 | Xuất / khai thác danh mục qua API | Nâng cấp | PH-07 | — | Tra cứu một mã, tra cứu lô, lấy toàn bộ, lấy thay đổi từ một phiên bản |
| LGC-DMDC-016 | API truy vấn CSDL tùy chọn | Nâng cấp | PH-07 | — | Truy vấn có cấu trúc (lọc, chọn trường, phân trang) trên dữ liệu danh mục; **không cho chạy SQL tự do** |
| LGC-DMDC-017 | Cờ cho phép cập nhật danh mục (`Is_update`) | Nâng cấp | PH-07 | — | Phân biệt danh mục nguồn quốc gia (chỉ đọc) và danh mục địa phương |
| LGC-DMDC-018 | Thứ tự và trạng thái thuộc tính (`Order`, `status`) | Giữ nguyên | PH-07 | — | |
| LGC-DMDC-019 | Kết nối danh mục dùng chung quốc gia qua NGSP: danh sách danh mục, lấy cấu trúc, bổ sung danh mục, lấy dữ liệu | Nâng cấp | PH-07, PH-14 | — | Đồng bộ định kỳ và theo yêu cầu, có đối chiếu khác biệt |

: DMDC — danh mục dùng chung Aita (LGC-DMDC)

### 4.6. PAY — thanh toán (`LGC-PAY`)

Khối Payment là lớp trung gian giữa các HTTT của tỉnh và các kênh thanh toán, trong đó kênh mặc định là PayGov. Dữ liệu gồm đối tác (`payment_partner`), nhà cung cấp (`payment_provider`), nhóm dịch vụ, dịch vụ và giao dịch. Tài liệu hệ cũ không mô tả nghiệp vụ đối soát, hoàn tiền hay bảo mật callback. Theo quyết định Q3, Datahub bổ sung đầy đủ các nghiệp vụ này ở PH-19. Ba mục LGC-PAY-024…026 do luồng PH-19 rà lại tài liệu hệ cũ đề xuất và được thêm ngày 26/11/2026 (khung D02-03-PH19-00 §2).

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Màn hình vận hành | Ghi chú chuyển hóa |
|---|---|---|---|---|---|
| LGC-PAY-001 | Thêm nhà cung cấp: khai báo, liên kết API, kiểm tra luồng thanh toán thử, kiểm tra phản hồi, đưa vào danh sách khi thử thành công | Nâng cấp | PH-19 | — | Quy trình kích hoạt có checklist và bằng chứng giao dịch thử |
| LGC-PAY-002 | Xem danh sách nhà cung cấp | Giữ nguyên | PH-19 | Có | |
| LGC-PAY-003 | Xem chi tiết nhà cung cấp: ngày bắt đầu, đầu mối, điện thoại, tình trạng, số lượng dịch vụ, biểu đồ giao dịch theo ngày | Giữ nguyên | PH-19 | Có | Màn "Kênh thanh toán" |
| LGC-PAY-004 | Chỉnh sửa nhà cung cấp | Giữ nguyên | PH-19 | — | Thông tin xác thực chỉ lưu tham chiếu tới kho bí mật |
| LGC-PAY-005 | Xóa nhà cung cấp | Nâng cấp | PH-19 | — | Không xóa khi đã có giao dịch; chỉ ngừng hoạt động |
| LGC-PAY-006 | Tìm kiếm nhà cung cấp | Giữ nguyên | PH-19 | — | |
| LGC-PAY-007 | Kích hoạt nhà cung cấp: kiểm tra hiện trạng, kết nối, giao dịch mẫu, nhận phản hồi | Giữ nguyên | PH-19 | — | |
| LGC-PAY-008 | Dừng nhà cung cấp | Giữ nguyên | PH-19 | — | Xử lý các giao dịch đang dở trước khi dừng |
| LGC-PAY-009 | Thông báo lỗi kết nối với nhà cung cấp | Nâng cấp | PH-19, PH-13 | — | Cảnh báo tự động |
| LGC-PAY-010 | Nhận kết quả thanh toán từ nhà cung cấp | Nâng cấp | PH-19 | — | Xác minh chữ ký, chống phát lại, idempotent |
| LGC-PAY-011 | Lưu dữ liệu quá trình thanh toán vào CSDL | Nâng cấp | PH-19 | — | Lưu toàn bộ lịch sử trạng thái, không ghi đè |
| LGC-PAY-012 | Thông báo kết quả thanh toán cho HTTT gọi | Nâng cấp | PH-19, PH-10 | — | Phát sự kiện và gọi lại có ký |
| LGC-PAY-013 | Dashboard tổng quan: số giao dịch, số ứng dụng, số dịch vụ, giao dịch theo dịch vụ | Giữ nguyên | PH-19 | Có | |
| LGC-PAY-014 | Bảng tra cứu giao dịch: mã giao dịch, mã yêu cầu, tên giao dịch, kênh, lĩnh vực, số tiền, ngày phát sinh, trạng thái, người thanh toán | Giữ nguyên | PH-19 | Có | |
| LGC-PAY-015 | Tìm kiếm nâng cao theo trạng thái (chọn nhiều) | Giữ nguyên | PH-19 | — | |
| LGC-PAY-016 | Tìm kiếm nâng cao theo lĩnh vực (chọn nhiều) | Giữ nguyên | PH-19 | — | |
| LGC-PAY-017 | Tìm kiếm nâng cao theo thời gian | Giữ nguyên | PH-19 | — | |
| LGC-PAY-018 | Tìm theo từ khóa, phân trang khi kết quả > 20 dòng, tiêu chí sắp xếp | Giữ nguyên | PH-19 | — | |
| LGC-PAY-019 | Xem chi tiết giao dịch và lịch sử trạng thái | Giữ nguyên | PH-19 | Có | |
| LGC-PAY-020 | Dashboard kênh thanh toán | Giữ nguyên | PH-19 | Có | |
| LGC-PAY-021 | Danh sách, lọc, sắp xếp, xem chi tiết nhật ký giao dịch | Giữ nguyên | PH-19, PH-13 | — | |
| LGC-PAY-022 | Quản lý đối tác, nhóm dịch vụ và dịch vụ thanh toán | Giữ nguyên | PH-19 | — | |
| LGC-PAY-023 | Giám sát nhiều nhà cung cấp; tài liệu cũ chỉ hiện thực một nhà cung cấp mặc định (PayGov) | Nâng cấp | PH-19 | — | Kiến trúc đa kênh, PayGov là kênh đầu tiên |
| LGC-PAY-024 | Nhận yêu cầu thanh toán của HTTT, gửi yêu cầu sang NCC, xử lý quá trình thanh toán (HDSD mục 3, dòng 9–11) | Nâng cấp | PH-19 | — | API thu thống nhất có idempotency, kiểm tra hợp lệ 15 bước, trang kết quả không đổi trạng thái (FR-19-022…025, 033, 034; ADR-041) |
| LGC-PAY-025 | Ba trạng thái hoàn trả `REFUND_PENDING`, `REFUND_SUCCESS`, `REFUND_FAILED` chỉ có trong bộ trạng thái, không có chức năng (TKCT 3.4) | Nâng cấp | PH-19 | Có | Nghiệp vụ hoàn tiền đầy đủ: lập, duyệt một hoặc hai cấp, thực thi qua NCC hoặc thủ công có chứng từ (FR-19-038…041; ADR-043, ADR-046) |
| LGC-PAY-026 | Số liệu tổng trên dashboard được đệm 10 phút (TKCT 3.1) | Nâng cấp | PH-19 | Có | Số liệu trễ tối đa 60 giây (FR-19-056, NFR-19-006) |

: PAY — thanh toán (LGC-PAY)

### 4.7. NGSP — kết nối quốc gia (`LGC-NGSP`)

Phụ lục kết nối NGSP liệt kê các dịch vụ quốc gia mà hệ cũ đã kết nối thông qua cổng AM của trục quốc gia. Mỗi dịch vụ dùng header `Service-code` để phân biệt nghiệp vụ trên cùng một đường dẫn, và xác thực bằng Bearer token lấy theo grant `password` hoặc `client_credentials`. Trong Datahub, mỗi nhóm dịch vụ trở thành một adapter của PH-14 có hợp đồng riêng. Danh sách dịch vụ phải được đối chiếu lại với danh mục dịch vụ hiện hành của NDXP trước khi xây dựng.

| Mã | Dịch vụ hệ cũ | Kết luận | PH đích |
|---|---|---|---|
| LGC-NGSP-001 | Tư pháp — Lý lịch tư pháp: tra danh sách hồ sơ, tra danh sách danh mục, tra trạng thái hồ sơ, đánh dấu hồ sơ thành công, trả danh sách trạng thái, nhận hồ sơ đăng ký | Giữ nguyên | PH-14 |
| LGC-NGSP-002 | Tư pháp — Hộ tịch: lấy danh mục hộ tịch, đăng ký hộ tịch, tra trạng thái hồ sơ, kết quả đăng ký, danh sách hồ sơ đăng ký, tra hồ sơ | Giữ nguyên | PH-14 |
| LGC-NGSP-003 | Bảo hiểm xã hội: tra cứu hộ gia đình theo mã số BHXH, lấy mã số BHXH theo tiêu chí, tra cứu dữ liệu hộ gia đình | Giữ nguyên | PH-14, PH-09 |
| LGC-NGSP-004 | Đồng bộ hồ sơ thủ tục cấp mã số ĐVQHNS: danh sách hồ sơ theo khoảng thời gian, chi tiết một hồ sơ, tổng hợp kết quả giải quyết hồ sơ trực tuyến | Giữ nguyên | PH-14 |
| LGC-NGSP-005 | Đăng ký doanh nghiệp: dữ liệu mới nhất của một doanh nghiệp, hồ sơ xử lý trong ngày, hồ sơ tiếp nhận trong khoảng thời gian, chi tiết một hồ sơ | Giữ nguyên | PH-14 |
| LGC-NGSP-006 | Danh mục dùng chung quốc gia: danh sách, cấu trúc, bổ sung, lấy dữ liệu | Giữ nguyên | PH-14, PH-07 |
| LGC-NGSP-007 | Văn bản quy phạm pháp luật: tìm kiếm toàn văn, lĩnh vực, cơ quan ban hành, chi tiết, loại văn bản, người ký, chức danh | Giữ nguyên | PH-14 |
| LGC-NGSP-008 | Lấy token qua cổng AM bằng Consumer Key / Secret | Nâng cấp | PH-14, PH-12 | 

: NGSP — kết nối quốc gia (LGC-NGSP)

Ghi chú về LGC-NGSP-008: tài liệu hệ cũ chứa Consumer Key / Secret dạng văn bản và địa chỉ IP công khai của cổng token chạy HTTP. Datahub lưu mọi thông tin xác thực đối ngoại trong kho bí mật, gọi qua kênh mã hóa, và phải cấp lại khóa khi cắt chuyển (xem D06-01).

### 4.8. IAM — định danh và truy cập (`LGC-IAM`)

Khối IAM gồm tám chức năng định danh của hệ cũ, chủ yếu dựa trên Keycloak; Datahub gom về PH-12 và đổi một số cách xác thực để theo OAuth 2.1.

| Mã | Chức năng hệ cũ | Kết luận | PH đích | Ghi chú chuyển hóa |
|---|---|---|---|---|
| LGC-IAM-001 | Đăng nhập một lần (SSO) bằng Keycloak cho các khối | Giữ nguyên | PH-12 | |
| LGC-IAM-002 | Tạo realm, client OpenID, vai trò, người dùng, gán vai trò | Nâng cấp | PH-12, PH-20 | Realm theo tenant, khởi tạo tự động |
| LGC-IAM-003 | Xác thực hai yếu tố TOTP | Nâng cấp | PH-12 | Bắt buộc với vai trò quản trị |
| LGC-IAM-004 | Liên kết LDAP / Active Directory | Giữ nguyên | PH-12 | |
| LGC-IAM-005 | Quản lý phiên của người dùng | Giữ nguyên | PH-12 | |
| LGC-IAM-006 | Lấy token bằng grant `password` (hướng dẫn lấy token) | Thay thế | PH-12, PH-15 | OAuth 2.1 bỏ grant `password`; người dùng dùng Authorization Code + PKCE, máy dùng `client_credentials` |
| LGC-IAM-007 | Đăng nhập mạng xã hội (Google, Facebook…) | Loại bỏ | — | Lý do: không phù hợp hệ thống của CQNN; thay bằng VNeID khi có yêu cầu |
| LGC-IAM-008 | SSO bằng SAML của midPoint cho màn quản trị Bus | Thay thế | PH-12 | Thống nhất về Keycloak OIDC |

: IAM — định danh và truy cập (LGC-IAM)

### 4.9. NFR — yêu cầu phi chức năng và vận hành (`LGC-NFR`)

Các yêu cầu phi chức năng của hệ cũ được sao chép giống nhau giữa các khối và nhiều giá trị thấp hơn nhu cầu thực tế. Datahub giữ mục đích của từng yêu cầu nhưng thay giá trị bằng chỉ tiêu tại D02-02.

| Mã | Yêu cầu hệ cũ | Kết luận | Giá trị mới (dự kiến, chốt tại D02-02) |
|---|---|---|---|
| LGC-NFR-001 | Uptime ứng dụng 90%/năm | Nâng cấp | Data plane 99,9%/tháng; control plane 99,5%/tháng |
| LGC-NFR-002 | Phản hồi ≤ 5 giây với 10 CCU, tỷ lệ thành công ≥ 95%, 1.000 bản ghi | Nâng cấp | Màn danh sách p95 ≤ 1,5 giây với 200 người dùng đồng thời mỗi tenant và 1 triệu bản ghi |
| LGC-NFR-003 | 1 người dùng hoạt động, tối đa 100 đồng thời | Nâng cấp | Theo hồ sơ quy mô tỉnh (D03-09) |
| LGC-NFR-004 | Log có cấu trúc, mỗi giao dịch một dòng, phân tách bằng dấu `\|`, có ID giao dịch liên kết giữa các module | Nâng cấp | Log JSON, `trace_id` theo W3C Trace Context |
| LGC-NFR-005 | Sao lưu log mỗi tháng một lần | Nâng cấp | Lưu trực tuyến 90 ngày, lưu trữ dài hạn theo yêu cầu cấp độ |
| LGC-NFR-006 | Tự từ chối giao dịch khi vượt ngưỡng; cô lập module lỗi; xử lý timeout; chống tranh chấp tài nguyên | Giữ nguyên | Rate limit, circuit breaker, bulkhead, giới hạn pool |
| LGC-NFR-007 | Mã hóa thông tin kết nối (thư viện `viettel-security`) | Thay thế | Kho bí mật OpenBao/Vault, External Secrets |
| LGC-NFR-008 | Các yêu cầu ATTT máy chủ, webserver, CSDL, ứng dụng web | Nâng cấp | Theo cấp độ 3 (D03-07) |
| LGC-NFR-009 | Giao diện web hiện đại, độ phân giải tối thiểu 800×600 | Nâng cấp | Tối thiểu 1280×720 cho màn quản trị; WCAG 2.2 AA |
| LGC-NFR-010 | Chạy trên Chrome, Firefox; Linux | Nâng cấp | Hai phiên bản mới nhất của Chrome, Edge, Firefox, Safari; Kubernetes |
| LGC-NFR-011 | Hỗ trợ bảo trì 2 tháng sau triển khai | Ngoài phạm vi kỹ thuật | Do hợp đồng quy định |
| LGC-NFR-012 | Có HDSD, HDVH, hướng dẫn cài đặt, tài liệu thiết kế | Giữ nguyên | D06-02, D06-03, D06-04 |
| LGC-NFR-013 | HDVH: profile hệ thống, khởi động / dừng, tham số cấu hình, giám sát, sự cố, tối ưu, bảo dưỡng, checklist định kỳ | Giữ nguyên | D06-03 |
| LGC-NFR-014 | Công nghệ Java 8, PostgreSQL, Angular | Thay thế | Java 21, Spring Boot 4, Camel Quarkus, PostgreSQL 18, React 19, antd v6 |

: NFR — yêu cầu phi chức năng và vận hành (LGC-NFR)

## 5. Tổng hợp độ phủ

Bảng dưới đây đếm số mục theo khối và theo kết luận. Ở đợt 0, mọi mục đã có kết luận và có phân hệ đích. Cột FR sẽ được điền ở phần B khi viết FRS từng phân hệ.

| Khối | Tổng | Giữ nguyên | Nâng cấp | Thay thế | Loại bỏ | Khác |
|---|---|---|---|---|---|---|
| BUS | 41 | 11 | 15 | 15 | 0 | 0 |
| TOOL | 29 | 17 | 9 | 1 | 2 | 0 |
| HUB | 14 | 7 | 5 | 2 | 0 | 0 |
| APIM | 27 | 14 | 10 | 3 | 0 | 0 |
| DMDC | 19 | 7 | 12 | 0 | 0 | 0 |
| PAY | 26 | 16 | 10 | 0 | 0 | 0 |
| NGSP | 8 | 7 | 1 | 0 | 0 | 0 |
| IAM | 8 | 3 | 2 | 2 | 1 | 0 |
| NFR | 14 | 3 | 8 | 2 | 0 | 1 |
| **Tổng** | **186** | **85** | **72** | **25** | **3** | **1** |

: Số chức năng hệ cũ theo khối và theo kết luận

Cột "Khác" là LGC-NFR-011 (hỗ trợ bảo trì), thuộc phạm vi hợp đồng chứ không phải yêu cầu kỹ thuật.

Phần B đầy đủ cho cả chín khối nằm ở mục 5.2. Riêng khối BUS và TOOL còn có bảng riêng: chiều LGC → FR ở [D02-03-PH04 §9.1](../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md), chiều LGC → FR → test case và nghiệm thu ở [D05-02-PH04 §7, §8.2](../05-kiem-thu/test-case/D05-02-PH04-test-case.md). Khối DMDC tương ứng ở D02-03-PH07 và D05-02-PH07.

> Bảng trên được đếm bằng script từ chính các bảng ở mục 4. Khi RTM được xuất ra tệp .xlsx ở đợt 1, script này chạy lại mỗi lần build.

### 5.1. Các mục loại bỏ (chủ đầu tư đã chấp thuận ngày 21/11/2026)

Bảng dưới nêu ba mục không đưa sang hệ mới cùng lý do, đã được chủ đầu tư chấp thuận.

| Mã | Chức năng | Lý do |
|---|---|---|
| LGC-TOOL-022 | Người dùng tự cập nhật file pom của luồng | Phụ thuộc thư viện do nền tảng quản lý. Cho phép người dùng tự thêm thư viện tạo rủi ro chuỗi cung ứng phần mềm và không kiểm soát được bản quyền. |
| LGC-TOOL-027 | Nhập component từ file JAR | Nạp mã tùy ý vào runtime vi phạm yêu cầu kiểm soát phần mềm của cấp độ 3. Thay bằng quy trình đăng ký Kamelet có duyệt. |
| LGC-IAM-007 | Đăng nhập bằng tài khoản mạng xã hội | Không phù hợp với hệ thống của CQNN. Định danh công dân, nếu cần, dùng VNeID. |

: Ba chức năng loại bỏ, mã và lý do

### 5.2. Phần B: truy vết từ chức năng hệ cũ tới FR, US, UC, API và kiểm thử

Bảng dưới nối từng chức năng hệ cũ (`LGC`) tới các đối tượng của hệ mới, để đi được cả hai chiều từ hệ cũ tới yêu cầu, story, use case, API, kịch bản kiểm thử và kịch bản nghiệm thu. Bảng được sinh bằng `build/tools/sinh_ma_tran_lgc.py --ghi` từ các dòng "Truy vết" của tập FRS (cột FR), tập use case (cột UC) và tập test case (cột API, kịch bản kiểm thử, nghiệm thu), nên không sửa tay trong khối dưới; khi tập phân hệ đổi thì chạy lại script. Mỗi FR có đúng một story cùng số (theo D02-05), nên cột US lặp lại số của cột FR với tiền tố `US`; story tách thêm từ số 501 không ứng với FR riêng và không nằm trong bảng. Cột PH đích là phân hệ chịu trách nhiệm chính theo mục 4; các FR của phân hệ khác trong cùng hàng cho thấy phân hệ đó phủ một phần hoặc dùng gián tiếp chức năng, không đổi kết luận chính. Cột API lấy từ các ca kiểm thử dẫn mã `LGC`, nên cũng gồm API đi kèm trong ca; dấu "—" nghĩa là chưa có đối tượng tương ứng. Chức năng loại bỏ (mục 5.1) có thể vẫn hiện FR khi tập phân hệ nhắc tới lý do loại bỏ.

<!-- lgc-fr:bat-dau (sinh bằng build/tools/sinh_ma_tran_lgc.py --ghi, không sửa tay) -->

| Mã | PH đích | FR | US | UC | API | Kịch bản kiểm thử | Nghiệm thu |
|---|---|---|---|---|---|---|---|
| LGC-BUS-001 | PH-04 | FR-04-001; FR-05-029 | US-04-001; US-05-029 | UC-04-02 | API-04-010, 012, 016 | TS-04-02 | PH-04: UAT-01 |
| LGC-BUS-002 | PH-04 | FR-04-001; FR-17-023 | US-04-001; US-17-023 | UC-17-17 | API-04-010 | TS-04-02; TS-17-45 | PH-04: UAT-01 |
| LGC-BUS-003 | PH-04 | FR-04-001; FR-17-023 | US-04-001; US-17-023 | UC-17-17 | API-04-010 | TS-04-02; TS-17-45 | PH-04: UAT-01 |
| LGC-BUS-004 | PH-04 | FR-04-001; FR-17-023 | US-04-001; US-17-023 | UC-17-17 | API-04-010 | TS-04-02; TS-17-45 | PH-04: UAT-01 |
| LGC-BUS-005 | PH-04 | FR-04-001 | US-04-001 | — | API-04-010 | TS-04-02 | PH-04: UAT-01 |
| LGC-BUS-006 | PH-04 | FR-04-002, 004; FR-05-003, 016, 030 | US-04-002, 004; US-05-003, 016, 030 | — | API-04-012, 013, 024, 054, 060 | TS-04-02, 04 | PH-04: UAT-02 |
| LGC-BUS-007 | PH-13 | FR-04-053; FR-13-033 | US-04-053; US-13-033 | UC-13-21 | API-04-060, 062, 063, 091; API-13-003, 004, 005, 006, 007, 008 | TS-04-19; TS-13-19 | PH-04: UAT-10; PH-13: UAT-02 |
| LGC-BUS-008 | PH-04 | FR-04-002 | US-04-002 | — | API-04-012, 024, 054, 060 | TS-04-02 | PH-04: UAT-02 |
| LGC-BUS-009 | PH-04 | FR-04-050; FR-05-007, 008, 044 | US-04-050; US-05-007, 008, 044 | UC-04-14, 15; UC-05-05 | API-04-061, 107, 108 | TS-04-18 | PH-04: UAT-08 |
| LGC-BUS-010 | PH-04 | FR-04-006; FR-05-008, 013, 044 | US-04-006; US-05-008, 013, 044 | UC-04-16; UC-05-06 | API-04-013, 014, 015, 016, 023 | TS-04-04 | PH-04: UAT-11 |
| LGC-BUS-011 | PH-04, PH-05 | FR-04-004, 011; FR-05-004, 005, 006, 018 | US-04-004, 011; US-05-004, 005, 006, 018 | UC-04-05; UC-05-01, 06 | API-04-013, 014, 015, 016, 023; API-05-001, 002, 004, 005, 006, 028, 029, 030 | TS-04-04; TS-05-01, 09 | PH-05: UAT-01, 09 |
| LGC-BUS-012 | PH-04 | FR-04-050; FR-05-007, 044 | US-04-050; US-05-007, 044 | UC-04-14; UC-05-03 | API-04-013, 014, 015, 016, 023, 061, 107, 108 | TS-04-04, 18 | PH-04: UAT-07 |
| LGC-BUS-013 | PH-04 | FR-04-003, 025, 030; FR-05-004, 010, 031, 043 | US-04-003, 025, 030; US-05-004, 010, 031, 043 | UC-04-03, 08; UC-05-02 | API-04-011, 031, 080, 081; API-05-017, 018, 019, 052, 053, 055 | TS-04-03; TS-05-03, 21 | PH-04: UAT-03; PH-05: UAT-02, 09 |
| LGC-BUS-014 | PH-13 | FR-04-051; FR-05-019, 022, 062; FR-13-031, 032 | US-04-051; US-05-019, 022, 062; US-13-031, 032 | UC-05-12; UC-13-20, 21 | API-04-060, 062, 063, 091; API-13-001, 002 | TS-04-19; TS-13-18 | PH-04: UAT-10; PH-13: UAT-01 |
| LGC-BUS-015 | PH-13 | FR-04-051, 053; FR-05-019, 020, 021, 022, 029; FR-13-032 | US-04-051, 053; US-05-019, 020, 021, 022, 029; US-13-032 | UC-05-12; UC-13-21 | API-04-060; API-13-003, 004, 005, 006, 007, 008 | TS-04-19; TS-13-19 | PH-04: UAT-10; PH-13: UAT-03 |
| LGC-BUS-016 | PH-13 | FR-04-053; FR-13-007, 032 | US-04-053; US-13-007, 032 | UC-13-03, 21 | API-13-003, 004, 005, 006, 007, 008 | TS-13-19 | PH-13: UAT-03 |
| LGC-BUS-017 | PH-04, PH-13 | FR-04-002, 051; FR-13-032 | US-04-002, 051; US-13-032 | UC-13-21 | API-04-012, 024, 054, 060; API-13-003, 004, 005, 006, 007, 008 | TS-04-02, 19; TS-13-19 | PH-04: UAT-02; PH-13: UAT-03 |
| LGC-BUS-018 | PH-04 | FR-04-002 | US-04-002 | — | API-04-012, 024, 054, 060, 062 | TS-04-02, 19 | PH-04: UAT-02 |
| LGC-BUS-019 | PH-13 | FR-04-053; FR-13-033 | US-04-053; US-13-033 | UC-13-21 | API-13-003, 004, 005, 006, 007, 008 | TS-13-19 | PH-04: UAT-10; PH-13: UAT-03 |
| LGC-BUS-020 | PH-04 | FR-04-002, 052; FR-05-030, 032 | US-04-002, 052; US-05-030, 032 | — | API-04-028, 097 | TS-04-26 | PH-04: UAT-12 |
| LGC-BUS-021 | PH-04 | FR-04-002 | US-04-002 | — | — | — | PH-04: UAT-12 |
| LGC-BUS-022 | PH-04 | FR-04-002, 033 | US-04-002, 033 | UC-04-08 | — | — | PH-04: UAT-12 |
| LGC-BUS-023 | PH-04 | FR-04-002, 043 | US-04-002, 043 | UC-04-11 | — | — | PH-04: UAT-12 |
| LGC-BUS-024 | PH-04 | FR-04-002 | US-04-002 | — | — | — | PH-04: UAT-12 |
| LGC-BUS-025 | PH-04 | FR-04-001, 002, 051 | US-04-001, 002, 051 | — | — | — | PH-04: UAT-12 |
| LGC-BUS-026 | PH-04 | FR-04-050 | US-04-050 | UC-04-14 | — | — | PH-04: UAT-12 |
| LGC-BUS-027 | PH-13 | FR-04-052; FR-08-034; FR-13-006, 034; FR-16-011; FR-17-037 | US-04-052; US-08-034; US-13-006, 034; US-16-011; US-17-037 | UC-08-16; UC-13-03, 21; UC-16-06, 22; UC-17-22 | API-08-070; API-13-003, 004, 005, 006, 007, 008 | TS-08-16; TS-13-19; TS-17-45 | PH-04: UAT-12; PH-08: UAT-08; PH-13: UAT-04; PH-16: UAT-03 |
| LGC-BUS-028 | PH-02, PH-04 | FR-02-013; FR-04-051, 052 | US-02-013; US-04-051, 052 | UC-02-09 | API-02-017, 018 | TS-02-07 | PH-02: UAT-12; PH-04: UAT-12 |
| LGC-BUS-029 | PH-13 | FR-04-053; FR-13-002, 026, 027; FR-17-037 | US-04-053; US-13-002, 026, 027; US-17-037 | UC-13-01, 17; UC-17-22 | API-13-019, 020, 021, 027, 028, 029 | TS-13-15; TS-17-45 | PH-04: UAT-12; PH-13: UAT-05 |
| LGC-BUS-030 | PH-13 | FR-04-074; FR-13-001 | US-04-074; US-13-001 | UC-13-01, 03 | — | TS-13-01 | — |
| LGC-BUS-031 | PH-18, PH-20 | FR-04-084; FR-05-061; FR-18-001, 002, 003, 005, 007, 008, 011, 069; FR-20-018, 020 | US-04-084; US-05-061; US-18-001, 002, 003, 005, 007, 008, 011, 069; US-20-018, 020 | UC-05-26; UC-18-01, 02, 04, 05, 07; UC-20-02, 05, 09 | API-04-090, 113; API-18-004, 006, 013 | TS-04-27; TS-18-46 | PH-18: UAT-18; PH-20: UAT-01 |
| LGC-BUS-032 | PH-04, PH-12 | FR-04-007, 083; FR-05-009; FR-12-012, 014 | US-04-007, 083; US-05-009; US-12-012, 014 | UC-04-01; UC-05-07; UC-12-09, 11, 31 | API-04-001, 002 | TS-04-01 | PH-12: UAT-09 |
| LGC-BUS-033 | PH-04 | FR-04-042, 082, 083; FR-05-018 | US-04-042, 082, 083; US-05-018 | UC-04-12, 20; UC-05-11 | API-04-063, 091 | TS-04-19 | PH-04: UAT-10 |
| LGC-BUS-034 | PH-04 | FR-04-042, 075, 080 | US-04-042, 075, 080 | UC-04-12, 21 | — | — | — |
| LGC-BUS-035 | PH-04 | FR-04-060, 068 | US-04-060, 068 | UC-04-17 | — | TS-04-20 | — |
| LGC-BUS-036 | PH-04, PH-07 | FR-04-020, 063, 065; FR-05-040; FR-07-040, 041, 042 | US-04-020, 063, 065; US-05-040; US-07-040, 041, 042 | UC-04-06; UC-07-13 | API-07-064, 065, 066, 070 | TS-04-20; TS-07-16 | — |
| LGC-BUS-037 | PH-04, PH-18 | FR-04-070; FR-11-027, 060; FR-17-036, 038; FR-18-012, 013, 014, 015, 017, 019, 020, 021, 023, 024, 025, 027, 028, 030, 031 | US-04-070; US-11-027, 060; US-17-036, 038; US-18-012, 013, 014, 015, 017, 019, 020, 021, 023, 024, 025, 027, 028, 030, 031 | UC-11-04, 07, 16, 17, 18, 19, 22; UC-17-21, 22; UC-18-08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18 | API-18-041, 064, 077 | TS-17-45; TS-18-46 | PH-11: UAT-05, 06; PH-18: UAT-18 |
| LGC-BUS-038 | PH-13 | FR-04-074; FR-13-003, 028 | US-04-074; US-13-003, 028 | UC-13-01, 18 | API-13-022, 023, 024 | TS-13-01, 16 | PH-13: UAT-05 |
| LGC-BUS-039 | PH-04, PH-10 | FR-04-061, 062, 069; FR-10-033, 067 | US-04-061, 062, 069; US-10-033, 067 | UC-04-18; UC-10-10, 14, 15, 24 | API-10-009, 047, 079, 084 | TS-04-21; TS-10-11, 26 | — |
| LGC-BUS-040 | PH-05 | FR-04-072, 080; FR-05-001, 002, 018, 023, 031, 033, 034, 035, 036, 037, 038, 039, 048, 054 | US-04-072, 080; US-05-001, 002, 018, 023, 031, 033, 034, 035, 036, 037, 038, 039, 048, 054 | UC-04-05, 19, 21; UC-05-01, 11 | API-05-001, 002, 004, 006, 028, 029, 030, 043, 044, 045 | TS-05-01, 09, 14 | PH-05: UAT-03, 10 |
| LGC-BUS-041 | PH-03, PH-04, PH-12 | FR-03-001, 002, 012, 014, 015, 019; FR-04-016, 064; FR-05-005, 011, 012, 034; FR-12-033, 035, 044 | US-03-001, 002, 012, 014, 015, 019; US-04-016, 064; US-05-005, 011, 012, 034; US-12-033, 035, 044 | UC-03-01, 02, 17; UC-04-05; UC-05-04; UC-12-24, 25, 31 | API-03-016, 031, 035, 055; API-05-050 | TS-03-01, 07; TS-04-20; TS-05-16 | PH-03: UAT-02; PH-05: UAT-04; PH-12: UAT-10 |
| LGC-TOOL-001 | PH-04 | FR-04-001, 010 | US-04-001, 010 | UC-04-02 | API-04-011, 028, 031, 080, 081, 097 | TS-04-03, 26 | PH-04: UAT-03 |
| LGC-TOOL-002 | PH-04 | FR-04-003 | US-04-003 | UC-04-03 | API-04-070 | TS-04-06 | PH-04: UAT-04 |
| LGC-TOOL-003 | PH-04 | FR-04-012 | US-04-012 | UC-04-04 | — | TS-04-06 | PH-04: UAT-04 |
| LGC-TOOL-004 | PH-04 | FR-04-012 | US-04-012 | — | — | TS-04-06 | PH-04: UAT-04 |
| LGC-TOOL-005 | PH-04 | FR-04-012 | US-04-012 | — | — | — | — |
| LGC-TOOL-006 | PH-04 | FR-04-012 | US-04-012 | — | API-04-032 | TS-04-08 | PH-04: UAT-05 |
| LGC-TOOL-007 | PH-04 | FR-04-012, 020; FR-05-040; FR-17-030 | US-04-012, 020; US-05-040; US-17-030 | UC-04-06; UC-17-19 | API-05-054 | TS-05-20; TS-17-45 | — |
| LGC-TOOL-008 | PH-04, PH-05 | FR-04-012, 016, 072; FR-05-001, 004, 005, 011, 023, 024, 038, 054 | US-04-012, 016, 072; US-05-001, 004, 005, 011, 023, 024, 038, 054 | UC-04-05, 19; UC-05-01 | API-04-033; API-05-004, 011, 012, 017, 035, 036, 039, 040, 050 | TS-04-09; TS-05-11, 19 | PH-04: UAT-06; PH-05: UAT-05 |
| LGC-TOOL-009 | PH-04 | FR-04-012; FR-05-001, 004, 032, 033, 036 | US-04-012; US-05-001, 004, 032, 033, 036 | UC-05-01 | API-05-050 | TS-05-15, 18 | PH-05: UAT-06 |
| LGC-TOOL-010 | PH-04, PH-10 | FR-04-012; FR-05-001, 032, 035; FR-10-034, 044, 066 | US-04-012; US-05-001, 032, 035; US-10-034, 044, 066 | UC-10-11, 15, 23, 24, 25 | API-10-009, 083 | TS-05-17; TS-10-12, 18, 25 | PH-05: UAT-06; PH-10: UAT-10 |
| LGC-TOOL-011 | PH-04 | FR-04-012; FR-05-019, 036 | US-04-012; US-05-019, 036 | — | — | TS-05-18 | PH-05: UAT-07 |
| LGC-TOOL-012 | PH-04, PH-09 | FR-04-012, 067; FR-05-005, 034; FR-09-024, 028 | US-04-012, 067; US-05-005, 034; US-09-024, 028 | UC-09-16, 19 | API-09-090, 091, 101, 229, 231 | TS-05-16; TS-09-16, 17, 19, 42 | PH-05: UAT-04; PH-09: UAT-03, 04 |
| LGC-TOOL-013 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-014 | PH-04 | FR-04-024 | US-04-024 | — | — | — | — |
| LGC-TOOL-015 | PH-04 | FR-04-027, 082 | US-04-027, 082 | UC-04-20 | — | — | — |
| LGC-TOOL-016 | PH-04 | FR-04-006 | US-04-006 | UC-04-16 | — | — | — |
| LGC-TOOL-017 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-018 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-019 | PH-04 | FR-04-014 | US-04-014 | UC-04-05 | — | — | — |
| LGC-TOOL-020 | PH-04 | FR-04-014 | US-04-014 | UC-04-05 | — | — | — |
| LGC-TOOL-021 | PH-04 | FR-04-017 | US-04-017 | — | — | — | — |
| LGC-TOOL-022 | — | — | — | — | — | — | — |
| LGC-TOOL-023 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-024 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-025 | PH-04 | FR-04-013 | US-04-013 | — | — | — | — |
| LGC-TOOL-026 | PH-04 | FR-04-017 | US-04-017 | — | — | — | — |
| LGC-TOOL-027 | — | FR-05-056 | US-05-056 | UC-04-07 | API-05-076, 079, 081, 082, 083 | TS-05-27 | PH-05: UAT-08 |
| LGC-TOOL-028 | PH-04 | FR-04-020; FR-17-030, 031 | US-04-020; US-17-030, 031 | UC-04-06; UC-17-19 | — | TS-17-45 | — |
| LGC-TOOL-029 | PH-04 | FR-04-010, 024 | US-04-010, 024 | — | — | — | — |
| LGC-HUB-001 | PH-10 | FR-10-057; FR-16-010, 044 | US-10-057; US-16-010, 044 | UC-10-21; UC-16-20 | API-10-007, 066 | TS-10-23 | PH-10: UAT-01; PH-16: UAT-07 |
| LGC-HUB-002 | PH-10 | — | — | UC-10-21 | API-10-066 | TS-10-23 | PH-10: UAT-01; PH-16: UAT-07 |
| LGC-HUB-003 | PH-10 | — | — | UC-10-21 | API-10-066 | TS-10-23 | PH-10: UAT-01; PH-16: UAT-07 |
| LGC-HUB-004 | PH-10 | — | — | UC-10-21 | API-10-066 | TS-10-23 | PH-10: UAT-01; PH-16: UAT-07 |
| LGC-HUB-005 | PH-13 | FR-13-007, 038 | US-13-007, 038 | UC-10-21; UC-13-03, 23 | API-10-066; API-13-011, 012, 013, 014 | TS-10-23; TS-13-21 | PH-10: UAT-02; PH-13: UAT-06 |
| LGC-HUB-006 | PH-13 | FR-13-007, 038 | US-13-007, 038 | UC-10-21; UC-13-03, 23 | API-10-066; API-13-011, 012, 013, 014 | TS-10-23; TS-13-21 | PH-10: UAT-02; PH-13: UAT-06 |
| LGC-HUB-007 | PH-10 | FR-10-054, 058 | US-10-054, 058 | UC-10-20, 21 | API-10-007, 055, 056 | TS-10-22, 23 | PH-10: UAT-03 |
| LGC-HUB-008 | PH-10 | FR-10-001, 002, 003, 004, 005, 072 | US-10-001, 002, 003, 004, 005, 072 | UC-10-01, 26, 27; UC-18-34, 36 | API-10-001, 002, 003, 005, 006, 075, 076, 110, 111, 112 | TS-10-01, 28 | PH-10: UAT-04, 10; PH-18: UAT-18 |
| LGC-HUB-009 | PH-10 | FR-10-006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 020 | US-10-006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 020 | UC-10-02, 03, 04, 05, 06 | API-10-008, 009, 010, 018, 020, 021, 022, 023, 024, 026, 030, 057, 058, 059, 075, 076, 110 | TS-10-02, 03, 05, 06, 28 | PH-10: UAT-05, 10 |
| LGC-HUB-010 | PH-10, PH-01 | FR-01-002, 003, 038, 048; FR-10-025, 026, 028, 029 | US-01-002, 003, 038, 048; US-10-025, 026, 028, 029 | UC-01-02, 20, 21, 22, 26, 32; UC-10-07, 08; UC-18-34, 36 | API-01-004, 005, 020, 021, 080, 081, 082, 083, 084, 086; API-10-032, 033, 034, 035, 036, 037, 038, 039, 075, 076, 092, 093, 110 | TS-01-02, 28; TS-10-08, 09, 28 | PH-01: UAT-04, 09, 11; PH-10: UAT-06, 10 |
| LGC-HUB-011 | PH-10, PH-01 | FR-01-002, 003, 038, 048; FR-10-025, 027, 028, 029, 045 | US-01-002, 003, 038, 048; US-10-025, 027, 028, 029, 045 | UC-01-02, 20, 21, 22, 26, 32; UC-10-07, 08, 25 | API-01-004, 005, 020, 021, 080, 081, 082, 083, 084, 086; API-10-032, 033, 034, 037, 038, 039, 075, 076, 110 | TS-01-02, 28; TS-10-08, 09, 28 | PH-01: UAT-05, 09, 11; PH-10: UAT-06, 10 |
| LGC-HUB-012 | PH-10 | FR-10-030, 031, 032 | US-10-030, 031, 032 | UC-10-09, 10, 11 | API-10-042, 043, 059, 075, 076, 110 | TS-10-10, 28 | PH-10: UAT-07, 10 |
| LGC-HUB-013 | PH-10 | FR-10-035, 036, 037, 038, 039, 040, 041, 043, 046, 047, 048, 056 | US-10-035, 036, 037, 038, 039, 040, 041, 043, 046, 047, 048, 056 | UC-10-12, 13, 14, 15, 16, 17 | API-10-046, 047, 048, 051, 052, 053, 059, 075, 076, 080, 081, 085, 110, 120 | TS-10-13, 14, 15, 16, 17, 28 | PH-10: UAT-08, 10 |
| LGC-HUB-014 | PH-10 | FR-10-008, 013, 060, 061 | US-10-008, 013, 060, 061 | UC-10-02, 04, 22, 26, 27 | API-10-008, 015, 067, 068, 075, 076, 105, 106, 110 | TS-10-02, 04, 24, 28 | PH-10: UAT-09, 10 |
| LGC-APIM-001 | PH-02 | FR-02-001, 002, 003 | US-02-001, 002, 003 | UC-02-01 | API-02-001, 002, 003, 006, 007, 074, 075, 090, 091 | TS-02-01 | PH-02: UAT-01 |
| LGC-APIM-002 | PH-02 | FR-02-010, 014, 022, 024, 061; FR-03-059 | US-02-010, 014, 022, 024, 061; US-03-059 | UC-02-05, 11, 37; UC-03-31 | API-02-014, 015, 018, 019, 030, 085, 086, 087, 088, 089; API-03-091, 092, 093 | TS-02-04, 23; TS-03-23 | PH-02: UAT-02, 12; PH-03: UAT-11 |
| LGC-APIM-003 | PH-02 | FR-02-011, 016, 061 | US-02-011, 016, 061 | UC-02-05, 06, 37 | API-02-014, 015, 018, 019, 030, 085, 086, 087, 088, 089 | TS-02-04, 23 | PH-02: UAT-03, 12; PH-03: UAT-11 |
| LGC-APIM-004 | PH-02 | FR-02-010, 034, 036 | US-02-010, 034, 036 | UC-02-05, 15, 16 | API-02-014, 015, 016, 018, 019, 027, 028, 029, 030, 034, 035, 036, 042, 043, 044, 045, 046, 047, 082, 098 | TS-02-04, 11 | PH-02: UAT-04; PH-03: UAT-11 |
| LGC-APIM-005 | PH-02, PH-03 | FR-02-037; FR-03-036 | US-02-037; US-03-036 | UC-02-17; UC-03-09, 11 | API-02-028, 047, 048, 049; API-03-001, 003, 004 | TS-02-12; TS-03-12 | PH-02: UAT-05; PH-03: UAT-01, 11 |
| LGC-APIM-006 | PH-02, PH-15 | FR-02-036, 041; FR-15-001, 004, 062 | US-02-036, 041; US-15-001, 004, 062 | UC-02-16, 21; UC-15-01, 02, 04, 08 | API-02-016, 018, 027, 028, 029, 034, 035, 036, 042, 043, 044, 045, 046, 047, 053, 057, 069, 082, 098; API-15-003, 004, 005, 006, 007, 008, 009, 010, 016, 021, 038, 131, 135, 136, 137 | TS-02-11, 15; TS-15-01, 02, 03, 05, 09, 37 | PH-02: UAT-06; PH-15: UAT-01, 02, 09 |
| LGC-APIM-007 | PH-15 | FR-02-041; FR-15-002, 008, 056 | US-02-041; US-15-002, 008, 056 | UC-02-21; UC-15-01, 29 | API-15-003, 004, 005, 007, 008, 010, 011, 012, 015, 016, 023, 056, 072, 084, 116, 117, 118, 122, 128, 139 | TS-15-02, 04, 27, 28, 34 | PH-15: UAT-03 |
| LGC-APIM-008 | PH-02 | FR-02-038, 039, 040 | US-02-038, 039, 040 | UC-02-19, 20 | API-02-014, 045, 050, 051, 052 | TS-02-14 | PH-02: UAT-07 |
| LGC-APIM-009 | PH-02 | FR-02-027, 030, 031, 032, 033, 061 | US-02-027, 030, 031, 032, 033, 061 | UC-02-12, 13, 14, 37 | API-02-033, 034, 035, 036, 037, 038, 039, 040, 041, 045, 046, 085, 086, 087, 088, 089, 096 | TS-02-09, 10, 23 | PH-02: UAT-08, 12; PH-03: UAT-11 |
| LGC-APIM-010 | PH-02 | FR-02-027 | US-02-027 | UC-02-12 | API-02-033, 034, 035, 036, 040, 041 | TS-02-09 | PH-02: UAT-08; PH-03: UAT-11 |
| LGC-APIM-011 | PH-02, PH-03 | FR-02-028; FR-03-002, 012, 014, 015, 016, 017, 039; FR-15-028 | US-02-028; US-03-002, 012, 014, 015, 016, 017, 039; US-15-028 | UC-02-12; UC-03-01, 02, 19 | API-02-033, 034, 035, 036, 040, 041; API-03-012, 016, 021, 022, 031, 035, 052, 055, 056, 057, 059, 065, 066; API-15-062 | TS-02-09; TS-03-01, 06, 07, 16; TS-15-14, 32 | PH-02: UAT-08; PH-03: UAT-02, 11 |
| LGC-APIM-012 | PH-03 | FR-02-029; FR-03-021, 024 | US-02-029; US-03-021, 024 | UC-02-12; UC-03-01, 04, 19, 25 | API-03-025, 026, 027, 028, 029, 030 | TS-03-09, 10 | PH-03: UAT-03, 11 |
| LGC-APIM-013 | PH-03 | FR-02-029; FR-03-022, 024 | US-02-029; US-03-022, 024 | UC-03-01, 04, 19, 25 | API-03-025, 026, 027, 028, 029, 030 | TS-03-09, 10 | PH-03: UAT-04, 11 |
| LGC-APIM-014 | PH-03 | FR-02-029; FR-03-020 | US-02-029; US-03-020 | UC-03-01, 19 | API-03-012, 021, 022, 055, 065 | TS-03-07 | PH-03: UAT-05, 11 |
| LGC-APIM-015 | PH-03 | FR-02-029; FR-03-048 | US-02-029; US-03-048 | UC-03-01, 05, 19, 24 | API-03-065, 066, 067 | TS-03-19 | PH-03: UAT-06, 11 |
| LGC-APIM-016 | PH-02 | FR-02-046, 047, 049, 051, 061; FR-03-016; FR-15-044 | US-02-046, 047, 049, 051, 061; US-03-016; US-15-044 | UC-02-23, 24, 26, 27, 28, 37 | API-02-044, 045, 046, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068; API-03-012, 021, 022, 055, 065; API-15-087, 088, 089 | TS-02-16, 17, 18; TS-03-07; TS-15-23 | PH-02: UAT-09; PH-03: UAT-02 |
| LGC-APIM-017 | PH-02, PH-15 | FR-02-002, 005, 024; FR-03-028; FR-15-006, 012 | US-02-002, 005, 024; US-03-028; US-15-006, 012 | UC-02-01; UC-03-09; UC-15-03, 05 | API-02-001, 002, 003, 006, 007, 074, 075, 090, 091; API-03-001, 002; API-15-005, 007, 008, 015, 016, 019, 021 | TS-02-01; TS-03-12; TS-15-03, 05, 06, 37 | PH-02: UAT-10; PH-03: UAT-07; PH-15: UAT-04, 05 |
| LGC-APIM-018 | PH-02 | FR-02-022, 023, 025; FR-03-029, 030 | US-02-022, 023, 025; US-03-029, 030 | UC-02-11; UC-03-06 | API-02-026, 027, 028, 029, 031, 032, 042; API-03-005, 006, 010 | TS-02-08; TS-03-13 | PH-02: UAT-11; PH-03: UAT-07 |
| LGC-APIM-019 | PH-01 | FR-01-001, 002, 028, 048, 050; FR-03-046; FR-15-046 | US-01-001, 002, 028, 048, 050; US-03-046; US-15-046 | UC-01-01, 18, 19, 32; UC-03-23; UC-15-17, 23, 24 | API-01-001, 002, 003, 080, 081, 082, 083, 084, 085, 086, 088; API-03-011, 012, 013, 014, 015, 016, 063, 064; API-15-091, 092, 093 | TS-01-01, 28; TS-03-18; TS-15-23 | PH-01: UAT-01, 02, 08, 09, 10; PH-03: UAT-11; PH-15: UAT-07, 10 |
| LGC-APIM-020 | PH-01, PH-12 | FR-01-003, 004, 012, 020, 048; FR-03-046; FR-12-030, 031, 032; FR-15-022, 025, 026, 046 | US-01-003, 004, 012, 020, 048; US-03-046; US-12-030, 031, 032; US-15-022, 025, 026, 046 | UC-01-02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 23, 24, 32; UC-03-23; UC-12-21, 23; UC-15-13, 14, 23, 24 | API-01-004, 005, 020, 021, 022, 023, 080, 081, 082, 083, 084, 086; API-03-011, 012, 013, 014, 015, 016, 063, 064; API-15-049, 050, 051, 052, 053, 055, 056, 057, 058, 059, 060, 091, 092, 093, 141 | TS-01-02, 06, 28; TS-03-18; TS-15-12, 13, 23, 37 | PH-01: UAT-03, 06, 07, 09; PH-03: UAT-11; PH-12: UAT-10; PH-15: UAT-07, 10 |
| LGC-APIM-021 | PH-02 | FR-02-046, 050, 051, 061 | US-02-046, 050, 051, 061 | UC-02-23, 26, 27, 28, 37 | API-02-044, 045, 046, 058, 059, 060, 061, 062, 063, 064, 065, 066, 067, 068 | TS-02-16, 17, 18 | PH-02: UAT-09; PH-03: UAT-11 |
| LGC-APIM-022 | PH-03, PH-13 | FR-03-050, 051, 058; FR-13-006, 030, 035; FR-15-049, 050 | US-03-050, 051, 058; US-13-006, 030, 035; US-15-049, 050 | UC-03-01, 26, 27; UC-13-02, 03, 19, 22; UC-15-26 | API-03-074, 075, 089, 090; API-13-025, 026; API-15-097, 098, 099, 100 | TS-03-20, 22; TS-13-03, 17; TS-15-24, 32 | PH-03: UAT-08; PH-13: UAT-08; PH-15: UAT-08 |
| LGC-APIM-023 | PH-03, PH-13 | FR-03-045; FR-13-036 | US-03-045; US-13-036 | UC-03-22; UC-13-23 | API-03-011, 063, 064; API-13-011, 012, 013, 014 | TS-03-18; TS-13-21 | PH-03: UAT-09; PH-13: UAT-07 |
| LGC-APIM-024 | PH-13 | FR-03-045; FR-13-036 | US-03-045; US-13-036 | UC-03-22; UC-13-23 | API-03-063, 064; API-13-011, 012, 013, 014 | TS-03-18; TS-13-21 | PH-03: UAT-09 |
| LGC-APIM-025 | PH-13 | FR-03-045; FR-13-001, 007, 037 | US-03-045; US-13-001, 007, 037 | UC-03-22; UC-13-23 | API-03-063, 064; API-13-011, 012, 013, 014 | TS-03-18; TS-13-21 | PH-03: UAT-09 |
| LGC-APIM-026 | PH-13 | FR-03-055; FR-13-031, 035; FR-16-010, 038 | US-03-055; US-13-031, 035; US-16-010, 038 | UC-03-27; UC-13-20, 22; UC-16-11, 20 | API-03-077, 078, 079; API-13-001, 002 | TS-03-21; TS-13-18 | PH-03: UAT-09; PH-13: UAT-01; PH-16: UAT-01 |
| LGC-APIM-027 | PH-13 | FR-13-010, 011, 013, 020, 021, 024 | US-13-010, 011, 013, 020, 021, 024 | UC-13-05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16 | API-03-003, 017, 033, 037, 043, 087, 093; API-13-074, 075 | TS-03-28; TS-13-11 | PH-13: UAT-09, 12 |
| LGC-DMDC-001 | PH-07 | FR-07-001, 051 | US-07-001, 051 | UC-07-01; UC-18-34 | API-07-001 | TS-07-01, 22 | PH-07: UAT-01; PH-18: UAT-18 |
| LGC-DMDC-002 | PH-07 | FR-07-007, 018, 029 | US-07-007, 018, 029 | UC-07-01 | API-07-002, 004, 026, 044 | TS-07-03, 05, 12 | PH-07: UAT-02 |
| LGC-DMDC-003 | PH-07 | FR-07-002 | US-07-002 | UC-07-01 | API-07-003, 011, 022, 026 | TS-07-01 | PH-07: UAT-03 |
| LGC-DMDC-004 | PH-07 | FR-07-003, 005 | US-07-003, 005 | UC-07-01 | API-07-002, 022, 023 | TS-07-01, 03 | PH-07: UAT-04 |
| LGC-DMDC-005 | PH-07 | FR-07-022 | US-07-022 | UC-07-04 | API-07-033, 036 | TS-07-09, 26 | PH-07: UAT-05 |
| LGC-DMDC-006 | PH-07 | FR-07-021; FR-08-003, 025 | US-07-021; US-08-003, 025 | UC-07-03; UC-08-02, 11, 14 | API-07-033, 034, 036; API-08-006, 017, 060, 064 | TS-07-08; TS-08-02, 11, 14 | PH-07: UAT-06; PH-08: UAT-05 |
| LGC-DMDC-007 | PH-07 | FR-07-021; FR-08-003, 025 | US-07-021; US-08-003, 025 | UC-07-03 | API-08-006, 017, 060, 064 | TS-07-09; TS-08-02, 11, 14 | PH-07: UAT-06 |
| LGC-DMDC-008 | PH-07 | FR-07-023; FR-08-003, 025 | US-07-023; US-08-003, 025 | UC-07-05 | API-07-031; API-08-006, 017, 060, 064 | TS-07-10; TS-08-02, 11, 14 | PH-07: UAT-07 |
| LGC-DMDC-009 | PH-07 | FR-07-004 | US-07-004 | UC-07-01 | API-07-004 | TS-07-01, 26 | PH-07: UAT-08 |
| LGC-DMDC-010 | PH-07 | FR-07-006 | US-07-006 | UC-07-01 | API-07-024 | TS-07-03 | PH-07: UAT-08 |
| LGC-DMDC-011 | PH-07 | FR-07-011, 012 | US-07-011, 012 | UC-07-02 | API-07-012, 028 | TS-07-05 | PH-07: UAT-08 |
| LGC-DMDC-012 | PH-07 | FR-07-009 | US-07-009 | UC-07-14 | API-07-005, 006 | TS-07-01 | PH-07: UAT-09 |
| LGC-DMDC-013 | PH-07 | FR-07-024 | US-07-024 | UC-07-08 | API-07-038 | TS-07-11 | PH-07: UAT-10 |
| LGC-DMDC-014 | PH-07 | FR-07-024 | US-07-024 | UC-07-08 | — | TS-07-11 | PH-07: UAT-10 |
| LGC-DMDC-015 | PH-07 | FR-06-015; FR-07-026, 027, 028, 029, 031, 033 | US-06-015; US-07-026, 027, 028, 029, 031, 033 | UC-06-07; UC-07-09 | API-07-042 | TS-07-12 | PH-06: UAT-06; PH-07: UAT-11 |
| LGC-DMDC-016 | PH-07 | FR-07-032 | US-07-032 | UC-07-10 | API-07-047 | TS-07-13 | PH-07: UAT-12 |
| LGC-DMDC-017 | PH-07 | FR-07-008, 048 | US-07-008, 048 | UC-07-01, 17 | API-07-002 | TS-07-04, 18, 22 | PH-07: UAT-13 |
| LGC-DMDC-018 | PH-07 | FR-07-005, 006 | US-07-005, 006 | UC-07-01 | API-07-024 | TS-07-03 | PH-07: UAT-14 |
| LGC-DMDC-019 | PH-07, PH-14 | FR-07-035, 036; FR-14-023 | US-07-035, 036; US-14-023 | UC-06-07; UC-07-11; UC-14-15, 28 | API-07-055, 056, 057; API-14-079, 080, 081, 082, 083 | TS-07-15, 22; TS-14-15 | PH-07: UAT-15; PH-14: UAT-06 |
| LGC-PAY-001 | PH-19 | FR-19-001, 002, 003, 004, 005 | US-19-001, 002, 003, 004, 005 | UC-19-01, 02, 03 | API-19-002, 003, 006, 007, 009, 010, 011, 047, 048, 050, 089, 090, 101, 110 | TS-19-01, 02, 29, 32 | PH-19: UAT-01 |
| LGC-PAY-002 | PH-19 | FR-19-007 | US-19-007 | UC-19-05 | API-19-001, 003, 004, 091, 092 | TS-19-05 | PH-19: UAT-03 |
| LGC-PAY-003 | PH-19 | FR-19-008, 057 | US-19-008, 057 | UC-19-05, 25 | API-19-001, 003, 004, 080, 081, 091, 092 | TS-19-05, 25 | PH-19: UAT-03 |
| LGC-PAY-004 | PH-19 | FR-19-002, 009 | US-19-002, 009 | UC-19-01, 05 | API-19-001, 002, 003, 004, 006, 007, 091, 092 | TS-19-01, 05 | PH-19: UAT-01 |
| LGC-PAY-005 | PH-19 | FR-19-010 | US-19-010 | UC-19-04 | API-19-005, 012, 013, 014, 050 | TS-19-04, 34 | PH-19: UAT-02 |
| LGC-PAY-006 | PH-19 | FR-19-007 | US-19-007 | UC-19-05 | API-19-001, 003, 004, 091, 092 | TS-19-05 | PH-19: UAT-03 |
| LGC-PAY-007 | PH-19 | FR-19-003, 004, 005 | US-19-003, 004, 005 | UC-19-02, 03 | API-19-009, 010, 011, 012, 048, 049, 050 | TS-19-02, 03 | PH-19: UAT-01 |
| LGC-PAY-008 | PH-19 | FR-19-006 | US-19-006 | UC-19-04 | API-19-005, 012, 013, 014 | TS-19-04 | PH-19: UAT-02 |
| LGC-PAY-009 | PH-19, PH-13 | FR-13-043; FR-19-011, 059 | US-13-043; US-19-011, 059 | UC-13-27, 28; UC-19-06, 25 | API-13-035, 036, 037, 038, 039, 040, 041, 042, 043, 044; API-19-003, 008, 080, 081 | TS-13-24; TS-19-06, 25, 34 | PH-13: UAT-10; PH-19: UAT-03 |
| LGC-PAY-010 | PH-19 | FR-19-029, 030, 031, 032 | US-19-029, 030, 031, 032 | UC-19-13, 16 | API-19-201 | TS-19-13, 30, 32 | PH-19: UAT-08, 09 |
| LGC-PAY-011 | PH-19 | FR-19-022, 028, 054, 065 | US-19-022, 028, 054, 065 | UC-19-11, 13, 24, 29 | API-19-075, 076, 101, 102, 201 | TS-19-11, 13, 24 | PH-19: UAT-08 |
| LGC-PAY-012 | PH-19, PH-10 | FR-19-025, 060, 061, 062 | US-19-025, 060, 061, 062 | UC-19-12, 27 | API-19-077, 078, 079, 109, 201, 202, 205 | TS-19-12, 13, 27, 30, 31 | PH-19: UAT-06 |
| LGC-PAY-013 | PH-19 | FR-16-038; FR-19-056 | US-16-038; US-19-056 | UC-16-20; UC-19-25 | API-19-080, 081 | TS-19-25 | PH-16: UAT-01; PH-19: UAT-12 |
| LGC-PAY-014 | PH-19 | FR-19-049 | US-19-049 | UC-19-22 | API-19-051, 083, 084 | TS-19-22, 32 | PH-19: UAT-07 |
| LGC-PAY-015 | PH-19 | FR-19-050 | US-19-050 | UC-19-22 | API-19-051 | TS-19-22 | PH-19: UAT-07 |
| LGC-PAY-016 | PH-19 | FR-19-050 | US-19-050 | UC-19-22 | API-19-051 | TS-19-22 | PH-19: UAT-07 |
| LGC-PAY-017 | PH-19 | FR-19-050 | US-19-050 | UC-19-22 | API-19-051 | TS-19-22 | PH-19: UAT-07 |
| LGC-PAY-018 | PH-19 | FR-19-049 | US-19-049 | UC-19-22 | API-19-051 | TS-19-22 | PH-19: UAT-07 |
| LGC-PAY-019 | PH-19 | FR-13-022; FR-19-028, 051 | US-13-022; US-19-028, 051 | UC-19-11, 13, 23 | API-19-052, 054 | TS-19-23 | PH-19: UAT-08, 10 |
| LGC-PAY-020 | PH-19 | FR-19-057 | US-19-057 | UC-16-20; UC-19-25 | API-19-080, 081 | TS-19-25 | PH-16: UAT-01; PH-19: UAT-12 |
| LGC-PAY-021 | PH-19, PH-13 | FR-13-030; FR-19-053, 054, 055 | US-13-030; US-19-053, 054, 055 | UC-13-17, 19; UC-19-23, 24 | API-13-025, 026; API-19-052, 054, 075, 076 | TS-13-17; TS-19-23, 24 | PH-13: UAT-08; PH-19: UAT-08 |
| LGC-PAY-022 | PH-19 | FR-19-013, 014, 015, 017, 018, 020, 065 | US-19-013, 014, 015, 017, 018, 020, 065 | UC-19-07, 08, 09, 10, 29 | API-19-015, 016, 017, 018, 019, 020, 021, 022, 028, 029, 030, 031, 201 | TS-19-07, 08, 09, 30, 34 | PH-19: UAT-04, 05 |
| LGC-PAY-023 | PH-19 | FR-19-011, 024, 057 | US-19-011, 024, 057 | UC-19-06, 11, 25 | API-19-080, 081 | TS-19-25, 34 | PH-19: UAT-12 |
| LGC-PAY-024 | PH-19 | FR-19-022, 023, 024, 025, 033, 034, 067 | US-19-022, 023, 024, 025, 033, 034, 067 | UC-19-11, 12, 29 | API-19-101, 102, 201, 202, 205 | TS-19-11, 12, 30, 31 | PH-19: UAT-06 |
| LGC-PAY-025 | PH-19 | FR-19-038, 039, 040, 041 | US-19-038, 039, 040, 041 | UC-19-17, 18 | API-19-050, 059, 061, 062, 087, 105, 203 | TS-19-17, 18 | PH-19: UAT-11 |
| LGC-PAY-026 | PH-19 | FR-19-056 | US-19-056 | UC-19-25 | API-19-080, 081 | TS-19-25, 32 | PH-19: UAT-12 |
| LGC-NGSP-001 | PH-14 | FR-14-004, 005, 006, 007, 008, 009, 010, 014, 016, 017, 041, 055, 056 | US-14-004, 005, 006, 007, 008, 009, 010, 014, 016, 017, 041, 055, 056 | UC-14-04, 05, 06, 07, 09, 10, 11, 27 | API-14-061, 062, 072, 073, 075, 076, 089 | TS-14-09, 12, 28, 31 | PH-14: UAT-01, 09, 10 |
| LGC-NGSP-002 | PH-14 | FR-11-018, 055; FR-14-016, 018 | US-11-018, 055; US-14-016, 018 | UC-11-06, 07, 11, 15, 20; UC-14-10, 11 | API-14-075, 076, 077 | TS-14-12 | PH-11: UAT-02, 04; PH-14: UAT-01 |
| LGC-NGSP-003 | PH-14, PH-09 | FR-06-045, 046, 053; FR-09-019, 047; FR-14-019 | US-06-045, 046, 053; US-09-019, 047; US-14-019 | UC-06-04, 21, 25; UC-08-05, 11; UC-09-09, 13, 29; UC-14-12 | API-09-227, 237; API-14-065, 075 | TS-09-42; TS-14-10, 13 | PH-06: UAT-04; PH-09: UAT-01, 02; PH-14: UAT-02, 09 |
| LGC-NGSP-004 | PH-14 | FR-14-020; FR-16-053 | US-14-020; US-16-053 | UC-11-14; UC-14-13; UC-16-28, 29 | API-14-075 | TS-14-14 | PH-11: UAT-07; PH-14: UAT-03; PH-16: UAT-08 |
| LGC-NGSP-005 | PH-14 | FR-06-045, 046, 053; FR-14-021 | US-06-045, 046, 053; US-14-021 | UC-06-04, 25; UC-08-05, 11; UC-14-14 | API-08-031, 035; API-14-075 | TS-08-06; TS-14-14 | PH-06: UAT-05; PH-14: UAT-04 |
| LGC-NGSP-006 | PH-14, PH-07 | FR-07-035, 036, 038; FR-14-023 | US-07-035, 036, 038; US-14-023 | UC-07-11; UC-14-15 | API-07-056, 063; API-14-053, 054, 055, 079, 080, 081, 082, 083 | TS-07-15; TS-14-15, 26 | PH-07: UAT-15; PH-14: UAT-06 |
| LGC-NGSP-007 | PH-14 | FR-14-022 | US-14-022 | UC-14-14 | API-14-075 | TS-14-14 | PH-14: UAT-05 |
| LGC-NGSP-008 | PH-14, PH-12 | FR-12-030, 034, 035; FR-14-002, 024, 025 | US-12-030, 034, 035; US-14-002, 024, 025 | UC-12-22, 24, 25; UC-14-01, 16, 17, 37, 38 | API-14-001, 002, 003, 004, 008, 009, 039, 040, 059, 072, 073, 074, 089 | TS-14-01, 02, 16, 31 | PH-12: UAT-10; PH-14: UAT-07, 08 |
| LGC-IAM-001 | PH-12 | FR-12-020, 025 | US-12-020, 025 | UC-12-16, 19, 20 | — | — | PH-12: UAT-02 |
| LGC-IAM-002 | PH-12, PH-20 | FR-12-001, 002, 003, 004, 006, 007, 009, 011, 012, 014, 015, 016, 041; FR-20-008 | US-12-001, 002, 003, 004, 006, 007, 009, 011, 012, 014, 015, 016, 041; US-20-008 | UC-12-01, 02, 03, 05, 06, 08, 09, 11, 12, 21, 29; UC-20-05, 11, 30, 31 | — | — | PH-12: UAT-01; PH-20: UAT-01, 07 |
| LGC-IAM-003 | PH-12 | FR-12-022, 024 | US-12-022, 024 | UC-12-17, 18 | — | — | PH-12: UAT-03 |
| LGC-IAM-004 | PH-12 | FR-12-026 | US-12-026 | UC-12-19 | — | — | PH-12: UAT-04 |
| LGC-IAM-005 | PH-12 | FR-12-002, 005, 029, 038, 040, 056 | US-12-002, 005, 029, 038, 040, 056 | UC-12-01, 04, 16, 20, 28, 37 | — | — | PH-12: UAT-05 |
| LGC-IAM-006 | PH-12, PH-15 | FR-12-020, 032, 035; FR-15-006, 012, 027 | US-12-020, 032, 035; US-15-006, 012, 027 | UC-12-16, 21, 25; UC-15-03, 05, 15 | API-15-005, 007, 008, 015, 016, 019, 021, 061, 062, 063, 064, 082 | TS-15-03, 05, 06, 14, 15, 18, 32, 37 | PH-12: UAT-06; PH-15: UAT-06, 07 |
| LGC-IAM-007 | — | FR-12-028 | US-12-028 | UC-12-19 | — | — | PH-12: UAT-08 |
| LGC-IAM-008 | PH-12 | FR-12-020, 025 | US-12-020, 025 | UC-12-16 | — | — | PH-12: UAT-07 |
| LGC-NFR-001 | — | FR-18-072 | US-18-072 | UC-18-40 | API-18-180, 186, 187 | TS-18-40 | — |
| LGC-NFR-002 | — | — | — | — | — | — | — |
| LGC-NFR-003 | — | — | — | — | — | — | — |
| LGC-NFR-004 | — | FR-13-002, 026; FR-18-021, 047 | US-13-002, 026; US-18-021, 047 | UC-13-01, 17; UC-18-13, 28 | API-18-045, 046, 058 | TS-13-01; TS-18-13 | PH-13: UAT-05; PH-18: UAT-18 |
| LGC-NFR-005 | — | FR-13-013, 018; FR-18-052 | US-13-013, 018; US-18-052 | UC-13-06, 10; UC-18-30 | API-13-088; API-18-133, 134, 135 | TS-13-10; TS-18-30 | PH-13: UAT-11 |
| LGC-NFR-006 | — | FR-03-021, 027, 030, 031; FR-18-072 | US-03-021, 027, 030, 031; US-18-072 | UC-03-04, 06, 08; UC-18-40 | API-03-002, 005, 006, 010, 023, 029, 030, 086; API-18-006, 049, 091, 180, 186, 187 | TS-03-02, 09, 10, 13, 14; TS-18-40 | PH-03: UAT-10 |
| LGC-NFR-007 | — | — | — | — | — | — | — |
| LGC-NFR-008 | — | — | — | — | — | — | — |
| LGC-NFR-009 | — | — | — | — | — | — | — |
| LGC-NFR-010 | — | — | — | — | — | — | — |
| LGC-NFR-011 | — | — | — | — | — | — | — |
| LGC-NFR-012 | — | — | — | — | — | — | — |
| LGC-NFR-013 | — | — | — | — | — | — | — |
| LGC-NFR-014 | — | — | — | — | — | — | — |

<!-- lgc-fr:ket-thuc -->

: Truy vết từ chức năng hệ cũ tới FR, US, UC, API, kịch bản kiểm thử và nghiệm thu

Kết luận của đợt đồng bộ chéo cuối giữa các tập (đề nghị đồng bộ, quyết định đặt tên áp chung, câu hỏi mở Q380 trở đi) ghi ở phụ lục [D00-03-01 Sổ đồng bộ chéo cuối](D00-03-01-so-dong-bo-cuoi.md).

## 6. Câu hỏi mở

> **Giả định GĐ-01 (thay Q01, 25/11/2026).** Phụ lục `PTYC_Toolings.xlsx` không có. Giả định 29 mục `LGC-TOOL` ở mục 4.2, lập từ tài liệu thiết kế chính của hệ cũ, đã phủ đủ chức năng của công cụ thiết kế. *Cơ sở:* tài liệu chính mô tả đủ các nhóm thao tác (kéo thả, cấu hình component, sinh luồng, triển khai). *Cách cập nhật:* chức năng nào người dùng hệ cũ chỉ ra trong khảo sát hoặc UAT mà chưa có mã thì thêm mục `LGC-TOOL` mới, gắn nhãn "phát hiện muộn", rồi chạy lại script đếm ở mục 5.

> **Giả định GĐ-02 (thay Q02, 25/11/2026).** Bảy nhóm dịch vụ quốc gia ở mục 4.7 vẫn còn nhu cầu. Từ nay chúng được kết nối qua Nền tảng chia sẻ, điều phối dữ liệu quốc gia theo NĐ 278/2025 (thay trục NGSP cũ), xác thực OAuth 2.1 `client_credentials`, không dùng Consumer Key/Secret tĩnh. Địa chỉ, mã dịch vụ và cách xác thực cụ thể là **cấu hình theo tenant** của PH-14, không ghi cứng trong tài liệu hay mã. *Cơ sở:* phụ lục NGSP của hệ cũ; CMP-LAW-03/19. *Cách cập nhật:* khi nhận được danh mục dịch vụ hiện hành, đối chiếu từng dịch vụ, đánh dấu "Còn", "Đổi đặc tả" hoặc "Ngừng" trong bảng 4.7; dịch vụ đổi đặc tả chỉ sửa adapter PH-14.

> **Giả định GĐ-03 (thay Q03, 25/11/2026).** Máy trạng thái giao dịch PH-19 dùng bộ trạng thái **nội bộ** của Datahub: `KHOI_TAO`, `CHO_THANH_TOAN`, `THANH_CONG`, `THAT_BAI`, `HET_HAN`, `DA_HUY`, `HOAN_TIEN_MOT_PHAN`, `HOAN_TIEN_TOAN_PHAN`; cờ đối soát tách riêng: `CHUA_DOI_SOAT`, `KHOP`, `LECH`. Mã kết quả của PayGov **không** được dùng trực tiếp mà ánh xạ sang trạng thái nội bộ qua bảng cấu hình; mã chưa biết luôn rơi về "chờ xác minh", không tự coi là thành công. *Cơ sở:* mô hình phổ biến của cổng thanh toán trung gian; tài liệu hệ cũ có giao dịch, đối soát, tra cứu nhưng không liệt kê trạng thái. *Cách cập nhật:* khi có tài liệu PayGov, chỉ điền bảng ánh xạ; máy trạng thái chỉ đổi nếu PayGov có trạng thái không quy được về bộ trên.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: nguồn kiểm kê, kiểm kê chức năng chín khối, tổng hợp độ phủ, mục loại bỏ, câu hỏi mở |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; thêm mục 1.1 đến 1.5 (phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm đoạn mở cho mục 4.8 và 5.1; viết lại chú thích bảng cho cụ thể; sửa bảng tổng hợp độ phủ ở mục 5 cho khớp mục 4.6 (khối PAY 26 mục, nâng cấp 10; tổng 186 mục, nâng cấp 72) |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: thêm mục 5.2 (phần B) truy vết LGC tới FR, US, UC, API, kịch bản kiểm thử và nghiệm thu, sinh bằng build/tools/sinh_ma_tran_lgc.py; thêm cột US cùng số với FR; dẫn tới phụ lục D00-03-01 Sổ đồng bộ chéo cuối |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Sinh lại phần lgc-fr sau khi tách mã API trùng của PH-04 (API-04-107, 108, 097) |
