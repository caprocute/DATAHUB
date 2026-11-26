---
ma_tai_lieu: D00-03
ten: Ma trận truy vết (RTM) — Phần A, kiểm kê chức năng hệ LGSP cũ
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, Quản lý dự án, Đội kỹ thuật
---

# D00-03 · Ma trận truy vết

## 1. Mục đích

Ma trận truy vết chứng minh hai điều mà chủ đầu tư yêu cầu. Thứ nhất, **Datahub phủ toàn bộ nghiệp vụ của hệ LGSP cũ**: mỗi chức năng cũ đều có kết luận rõ ràng và có chỗ hiện thực trong hệ mới. Thứ hai, **mọi yêu cầu đều đi được tới kiểm thử**: từ mục tiêu nghiệp vụ, qua yêu cầu chức năng, tới API, dữ liệu, màn hình và test case.

Tài liệu gồm bốn phần, được hoàn thiện dần theo các đợt viết:

| Phần | Nội dung | Hoàn thành ở đợt |
|---|---|---|
| A | Kiểm kê chức năng hệ cũ (`LGC`) và kết luận cho từng mục | Đợt 0 (bản này) |
| B | Ánh xạ `LGC` → `FR` cụ thể | Đợt 2–4, theo từng phân hệ |
| C | Ánh xạ dọc `BO` → `REQ` → `FR` → `UC/US` → `API/EN/UI` → `TC` | Đợt 2–4 |
| D | Ánh xạ pháp lý `CMP-LAW` → yêu cầu → bằng chứng kiểm chứng | Đợt 1 (khung), Đợt 5 (bằng chứng) |

: Mục đích

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

: Nguồn kiểm kê

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
| PAY | 23 | 16 | 7 | 0 | 0 | 0 |
| NGSP | 8 | 7 | 1 | 0 | 0 | 0 |
| IAM | 8 | 3 | 2 | 2 | 1 | 0 |
| NFR | 14 | 3 | 8 | 2 | 0 | 1 |
| **Tổng** | **183** | **85** | **69** | **25** | **3** | **1** |

: Tổng hợp độ phủ

Cột "Khác" là LGC-NFR-011 (hỗ trợ bảo trì), thuộc phạm vi hợp đồng chứ không phải yêu cầu kỹ thuật.

Phần B đã có cho khối BUS và TOOL: chiều LGC → FR ở [D02-03-PH04 §9.1](../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md), chiều LGC → FR → test case và nghiệm thu ở [D05-02-PH04 §7, §8.2](../05-kiem-thu/test-case/D05-02-PH04-test-case.md). Khối DMDC tương ứng ở D02-03-PH07 và D05-02-PH07.

> Bảng trên được đếm bằng script từ chính các bảng ở mục 4. Khi RTM được xuất ra tệp .xlsx ở đợt 1, script này chạy lại mỗi lần build.

### 5.1. Các mục loại bỏ (chủ đầu tư đã chấp thuận ngày 21/11/2026)

| Mã | Chức năng | Lý do |
|---|---|---|
| LGC-TOOL-022 | Người dùng tự cập nhật file pom của luồng | Phụ thuộc thư viện do nền tảng quản lý. Cho phép người dùng tự thêm thư viện tạo rủi ro chuỗi cung ứng phần mềm và không kiểm soát được bản quyền. |
| LGC-TOOL-027 | Nhập component từ file JAR | Nạp mã tùy ý vào runtime vi phạm yêu cầu kiểm soát phần mềm của cấp độ 3. Thay bằng quy trình đăng ký Kamelet có duyệt. |
| LGC-IAM-007 | Đăng nhập bằng tài khoản mạng xã hội | Không phù hợp với hệ thống của CQNN. Định danh công dân, nếu cần, dùng VNeID. |

: Các mục loại bỏ (chủ đầu tư đã chấp thuận ngày 21/11/2026)

## 6. Câu hỏi mở

> **Giả định GĐ-01 (thay Q01, 25/11/2026).** Phụ lục `PTYC_Toolings.xlsx` không có. Giả định 29 mục `LGC-TOOL` ở mục 4.2, lập từ tài liệu thiết kế chính của hệ cũ, đã phủ đủ chức năng của công cụ thiết kế. *Cơ sở:* tài liệu chính mô tả đủ các nhóm thao tác (kéo thả, cấu hình component, sinh luồng, triển khai). *Cách cập nhật:* chức năng nào người dùng hệ cũ chỉ ra trong khảo sát hoặc UAT mà chưa có mã thì thêm mục `LGC-TOOL` mới, gắn nhãn "phát hiện muộn", rồi chạy lại script đếm ở mục 5.

> **Giả định GĐ-02 (thay Q02, 25/11/2026).** Bảy nhóm dịch vụ quốc gia ở mục 4.7 vẫn còn nhu cầu. Từ nay chúng được kết nối qua Nền tảng chia sẻ, điều phối dữ liệu quốc gia theo NĐ 278/2025 (thay trục NGSP cũ), xác thực OAuth 2.1 `client_credentials`, không dùng Consumer Key/Secret tĩnh. Địa chỉ, mã dịch vụ và cách xác thực cụ thể là **cấu hình theo tenant** của PH-14, không ghi cứng trong tài liệu hay mã. *Cơ sở:* phụ lục NGSP của hệ cũ; CMP-LAW-03/19. *Cách cập nhật:* khi nhận được danh mục dịch vụ hiện hành, đối chiếu từng dịch vụ, đánh dấu "Còn", "Đổi đặc tả" hoặc "Ngừng" trong bảng 4.7; dịch vụ đổi đặc tả chỉ sửa adapter PH-14.

> **Giả định GĐ-03 (thay Q03, 25/11/2026).** Máy trạng thái giao dịch PH-19 dùng bộ trạng thái **nội bộ** của Datahub: `KHOI_TAO`, `CHO_THANH_TOAN`, `THANH_CONG`, `THAT_BAI`, `HET_HAN`, `DA_HUY`, `HOAN_TIEN_MOT_PHAN`, `HOAN_TIEN_TOAN_PHAN`; cờ đối soát tách riêng: `CHUA_DOI_SOAT`, `KHOP`, `LECH`. Mã kết quả của PayGov **không** được dùng trực tiếp mà ánh xạ sang trạng thái nội bộ qua bảng cấu hình; mã chưa biết luôn rơi về "chờ xác minh", không tự coi là thành công. *Cơ sở:* mô hình phổ biến của cổng thanh toán trung gian; tài liệu hệ cũ có giao dịch, đối soát, tra cứu nhưng không liệt kê trạng thái. *Cách cập nhật:* khi có tài liệu PayGov, chỉ điền bảng ánh xạ; máy trạng thái chỉ đổi nếu PayGov có trạng thái không quy được về bộ trên.
