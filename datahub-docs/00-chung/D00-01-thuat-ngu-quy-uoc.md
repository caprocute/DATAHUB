---
ma_tai_lieu: D00-01
ten: Thuật ngữ và quy ước chung
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Tất cả
mo_ta: Nguồn định nghĩa duy nhất về thuật ngữ, hệ mã truy vết, kiểu dữ liệu chuẩn, quy ước viết yêu cầu, đặt tên, trình bày và căn cứ pháp lý cho toàn bộ bộ tài liệu Datahub.
tai_lieu_lien_quan: D00-02 Sổ ADR; D00-03 Ma trận truy vết; D00-04 Sổ tra cứu gọn; D02-01 BRD; D02-02 SRS; D03-01 SAD; khuon/K-TRINH-BAY
---

# D00-01 · Thuật ngữ và quy ước chung

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu là nguồn định nghĩa duy nhất của bộ tài liệu Datahub về thuật ngữ, hệ mã truy vết, kiểu dữ liệu chuẩn, cách viết yêu cầu đo được, quy ước đặt tên và trình bày. Mọi tài liệu khác chỉ dẫn chiếu tới đây, nhờ đó cùng một khái niệm không bị hiểu theo hai nghĩa và mọi đối tượng đều truy vết được.

**Phạm vi.** Tài liệu gồm ba bảng thuật ngữ (nghiệp vụ và pháp lý, kỹ thuật, từ viết tắt), bảng mã truy vết và năm quy tắc truy vết, mức ưu tiên M, S, C, mẫu đặc tả một yêu cầu chức năng 17 mục, 16 kiểu dữ liệu chuẩn, quy ước đặt tên, danh mục căn cứ pháp lý và tiêu chuẩn, quy ước trình bày, cách đặt tên file và tổ chức ADR. Tài liệu không chứa nội dung nghiệp vụ hay thiết kế của phân hệ nào.

**Căn cứ.** Mục 7 liệt kê 33 văn bản pháp lý mang mã CMP-LAW (từ CMP-LAW-01 Luật Dữ liệu số 60/2024/QH15 đến CMP-LAW-97) và 5 tiêu chuẩn mang mã STD (STD-01 ISO/IEC/IEEE 29148 đến STD-05 OpenAPI, AsyncAPI, RFC 9457). Các tài liệu khác dẫn lại những mã này thay cho việc viết lại tên văn bản.

**Những điểm hội đồng cần lưu ý.** (1) Mỗi chức năng hệ cũ có đúng một kết luận trong bốn giá trị Giữ nguyên, Nâng cấp, Thay thế, Loại bỏ (mục 3.2), nên hội đồng kiểm tra được mức phủ nghiệp vụ. (2) Một mã không bao giờ được tái sử dụng, kể cả khi đối tượng bị hủy, nên dấu vết thay đổi không bị mất. (3) Văn bản ở trạng thái "Cần xác minh" trong mục 7 phải được đối chiếu nguồn chính thức trước khi phát hành bản 1.0. (4) Mỗi yêu cầu chức năng được đặc tả theo mẫu 17 mục cố định (mục 4.3), nên các phân hệ có cùng độ chi tiết và cùng cách kiểm thử.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Thuật ngữ nghiệp vụ và pháp lý | 17 |
| Thuật ngữ kỹ thuật | 22 |
| Từ viết tắt | 28 |
| Dòng trong bảng mã truy vết | 41 |
| Quy tắc truy vết | 5 |
| Mục của mẫu đặc tả một FR | 17 |
| Kiểu dữ liệu chuẩn | 16 |
| Văn bản pháp lý CMP-LAW | 33 |
| Tiêu chuẩn STD | 5 |

: Con số chính của tài liệu thuật ngữ và quy ước chung

Các con số trên được đếm từ bảng ở mục 2, 3.1, 4.3, 5 và 7 của tài liệu này.

## 1. Mục đích và phạm vi

Tài liệu này là nguồn định nghĩa duy nhất cho **thuật ngữ, hệ mã truy vết, kiểu dữ liệu chuẩn, quy ước viết yêu cầu và quy ước trình bày** của toàn bộ bộ tài liệu Datahub. Mọi tài liệu khác chỉ tham chiếu tới đây, không định nghĩa lại. Khi một thuật ngữ mới xuất hiện ở tài liệu khác, người viết phải bổ sung vào mục 2 trước khi dùng.

Tài liệu phục vụ hai nhóm người đọc. Hội đồng thẩm định dùng mục 2 và mục 7 để hiểu ngôn ngữ chung và căn cứ pháp lý. Đội kỹ thuật dùng mục 3 đến mục 6 làm luật khi viết tài liệu và mã nguồn.

### 1.1. Người đọc và cách đọc

Bảng dưới gợi ý phần cần đọc theo vai trò, để người đọc không phải đọc hết tài liệu.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, mục 2, 7 | Hiểu ngôn ngữ chung và căn cứ pháp lý của bộ tài liệu |
| Người viết tài liệu, quản lý dự án | Mục 3, 4, 8, 9 | Dùng đúng mã truy vết, mẫu yêu cầu, quy ước trình bày và tổ chức file |
| Kiến trúc sư, kỹ sư | Mục 5, 6 | Dùng đúng kiểu dữ liệu chuẩn và quy ước đặt tên khi thiết kế, viết mã |
| Kiểm thử viên | Mục 3.2, 4.2, 4.3 | Truy vết yêu cầu tới ca kiểm thử, kiểm tra yêu cầu đo được |

: Người đọc D00-01 và phần cần đọc theo vai trò

### 1.2. Tài liệu tham chiếu

Tài liệu này là gốc của bộ tài liệu nên chỉ dẫn chiếu ít tài liệu khác, như bảng dưới.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D00-02 | Sổ quyết định kiến trúc (ADR) | Hiện thực mục 9.2: dải số và danh sách ADR |
| D00-03 | Ma trận truy vết | Hiện thực mục 3.2: kết luận cho từng chức năng hệ cũ |
| D00-04 | Sổ tra cứu gọn | Bản rút gọn của mục 3, 6 và 8 cho người viết phân hệ |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | Nơi định nghĩa FR-00 và NFR-00 dùng chung |
| khuon/K-TRINH-BAY | Quy chuẩn trình bày | Cụ thể hóa mục 8 về văn phong và cách trình bày |
| CMP-LAW, STD | Văn bản pháp lý, tiêu chuẩn | Căn cứ liệt kê ở mục 7 |

: Tài liệu tham chiếu của D00-01

### 1.3. Cấu trúc tài liệu

Tài liệu đi từ từ vựng, qua mã và quy ước viết, tới căn cứ pháp lý và tổ chức file. Thuật ngữ và chữ viết tắt nằm ở chương 2 vì đó là nội dung chính của tài liệu.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Thuật ngữ nghiệp vụ, pháp lý, kỹ thuật và từ viết tắt | Mọi người đọc |
| 3 | Bảng mã truy vết và quy tắc truy vết | Người viết, kiểm thử viên |
| 4 | Mức ưu tiên, cách viết yêu cầu đo được, mẫu đặc tả FR | Người viết, kiểm thử viên |
| 5 | Kiểu dữ liệu chuẩn và trường ngữ cảnh bắt buộc | Kiến trúc sư, kỹ sư |
| 6 | Quy ước đặt tên | Kỹ sư |
| 7 | Căn cứ pháp lý và tiêu chuẩn viện dẫn | Hội đồng thẩm định |
| 8 | Quy ước trình bày tài liệu | Người viết |
| 9 | Đặt tên file, ADR, làm việc song song | Người viết, quản lý dự án |

: Cấu trúc chương của D00-01

## 2. Thuật ngữ

### 2.1. Thuật ngữ nghiệp vụ và pháp lý

Bảng dưới giải thích các thuật ngữ nghiệp vụ và pháp lý mà hội đồng thẩm định và người viết gặp trong toàn bộ bộ tài liệu, kèm tiếng Anh và định nghĩa.

| Thuật ngữ | Tiếng Anh | Định nghĩa trong Datahub |
|---|---|---|
| Datahub | — | Tên sản phẩm. Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới, đóng gói triển khai cho nhiều tỉnh. Về chức năng, Datahub đóng vai trò LGSP theo NĐ 278/2025/NĐ-CP (thay NĐ 47/2020/NĐ-CP). |
| LGSP | Local Government Service Platform | Nền tảng tích hợp, chia sẻ dữ liệu cấp bộ, cấp tỉnh. Trong bộ tài liệu này, "LGSP cũ" hoặc "hệ cũ" chỉ hệ thống do Viettel xây dựng năm 2021 được mô tả trong thư mục `lgsp_document`. |
| NDXP | National Data Exchange Platform | Nền tảng tích hợp, chia sẻ dữ liệu quốc gia (trước đây gọi là NGSP). Datahub kết nối lên NDXP để khai thác CSDL quốc gia và dữ liệu của bộ, ngành. |
| NDOP | National Data Open Platform | Nền tảng dữ liệu mở quốc gia, nơi công bố dữ liệu mở (PH-14 kết nối để công bố, FR-14-045). Việc khai thác dữ liệu, đăng ký danh mục dịch vụ chia sẻ và điều phối dữ liệu đi qua NDXP, không qua NDOP; cách gọi này thống nhất cho toàn bộ tài liệu. |
| Service-code | Service-code | Tiêu đề (header) HTTP mà nền tảng quốc gia dùng để phân biệt nghiệp vụ trên cùng một đường dẫn; hệ cũ rải mã này trong luồng, Datahub gom vào hợp đồng của bộ điều hợp PH-14 (D00-03 §4.7). |
| Nhãn đối chiếu (dịch vụ quốc gia) | Reconciliation label | Nhãn PH-14 gán cho đặc tả một dịch vụ quốc gia sau mỗi lần đối chiếu với nền tảng: `Còn` (không đổi), `Đổi đặc tả`, `Ngừng`. |
| Cung cấp lại (dịch vụ quốc gia) | Re-publish | Việc Datahub đăng ký dịch vụ quốc gia vào danh mục dịch vụ của PH-02 như một API của Datahub, để HTTT trong tỉnh dùng qua cổng mà không giữ thông tin xác thực quốc gia. |
| NGSP | National Government Service Platform | Tên cũ của NDXP; vẫn xuất hiện trong tài liệu hệ cũ (phụ lục kết nối NGSP). |
| HTTT | Information system | Hệ thống thông tin của một cơ quan, đơn vị. Là bên kết nối vào Datahub để cung cấp hoặc khai thác dữ liệu. |
| HTTT thành viên | Member system | HTTT đã hoàn tất thủ tục kết nạp vào Datahub và được cấp định danh kỹ thuật. |
| CQNN | State agency | Cơ quan nhà nước. |
| CSDLQG | National database | Cơ sở dữ liệu quốc gia (dân cư, đất đai, doanh nghiệp, bảo hiểm…). |
| Chủ quản dữ liệu | Data owner | Cơ quan chịu trách nhiệm về một tập dữ liệu, quyết định ai được khai thác. |
| Danh mục dùng chung | Reference data / Shared catalog | Bộ mã và giá trị được nhiều HTTT dùng chung (đơn vị hành chính, giới tính, dân tộc, quốc tịch…). Hệ cũ gọi là "Aita". |
| Dữ liệu chủ | Master data | Dữ liệu định danh các thực thể cốt lõi (công dân, tổ chức, thửa đất…) dùng chung giữa nhiều nghiệp vụ. |
| DVCTT | Online public service | Dịch vụ công trực tuyến. |
| PayGov | National payment platform | Nền tảng thanh toán trực tuyến dùng chung cho dịch vụ công. Hệ cũ dùng mã nhà cung cấp `PAYGOV`. |
| Tenant | Tenant | Một đơn vị triển khai độc lập về dữ liệu, cấu hình và người dùng. Trong Datahub, **một tỉnh là một tenant**. |
| Quản trị nền tảng | Platform operator | Đơn vị vận hành phần dùng chung của sản phẩm, quản lý nhiều tenant. |
| Quản trị tenant | Tenant administrator | Cán bộ của tỉnh, quản trị Datahub trong phạm vi tỉnh mình. |

: Thuật ngữ nghiệp vụ và pháp lý của Datahub, kèm tiếng Anh

### 2.2. Thuật ngữ kỹ thuật

Bảng dưới giải thích các thuật ngữ kỹ thuật dùng ở tài liệu thiết kế và đặc tả, để người viết dùng thống nhất một tên cho một khái niệm.

| Thuật ngữ | Tiếng Anh | Định nghĩa |
|---|---|---|
| Luồng tích hợp | Integration flow / Route | Một chuỗi xử lý nhận bản tin từ nguồn, biến đổi, định tuyến và chuyển tới đích. Được viết bằng Camel YAML DSL. Hệ cũ gọi là "chương trình tích hợp" (gồm nhiều route chạy trong một "agent"). |
| Agent (hệ cũ) | — | Một tiến trình Camel của hệ cũ chạy trên một máy chủ, chứa nhiều route. Trong Datahub, khái niệm này được thay bằng **đơn vị triển khai luồng** chạy trên Kubernetes. |
| Adapter | Adapter / Connector | Thành phần chuyên trách kết nối với một loại hệ thống cụ thể (CSDL, FTP, SOAP, REST, hàng đợi) hoặc một dịch vụ cụ thể (một API của bộ, ngành). |
| Kamelet | Kamelet | Khuôn mẫu đầu nối có tham số của Apache Camel; đơn vị tái sử dụng của adapter. |
| CDM | Canonical Data Model | Mô hình dữ liệu chuẩn làm trung gian khi chuyển đổi giữa các HTTT. |
| Sự kiện | Event | Thông báo một việc đã xảy ra, phát qua Kafka. Hệ cũ dùng Apache Pulsar với các khái niệm topic, publisher, subscriber. |
| Topic | Topic | Kênh logic chứa các sự kiện cùng loại. |
| Bên phát / bên nhận | Producer / Consumer | HTTT phát sự kiện / HTTT nhận sự kiện. Hệ cũ gọi là publisher / subscriber. |
| Đăng ký nhận | Subscription | Quan hệ một bên nhận theo dõi một topic, kèm cấu hình giao nhận (đẩy về URI hay tự kéo, số lần thử lại…). |
| DLQ | Dead Letter Queue | Nơi lưu bản tin xử lý thất bại sau khi đã hết số lần thử lại, chờ xử lý thủ công. |
| Gói sử dụng | Plan | Tập điều kiện khai thác một API: kiểu xác thực, hạn mức tốc độ (rate limit), hạn ngạch (quota), danh sách đường dẫn cho phép. Kế thừa khái niệm Plan của API Management hệ cũ. |
| Rate limit | Rate limit | Giới hạn số yêu cầu trong khoảng thời gian ngắn (giây, phút). |
| Quota | Quota | Giới hạn số yêu cầu trong khoảng thời gian dài (giờ, ngày, tháng). |
| Control plane | Control plane | Các phân hệ quản trị cấu hình, không nằm trên đường đi của bản tin nghiệp vụ. |
| Data plane | Data plane | Các phân hệ nằm trên đường đi của bản tin nghiệp vụ (gateway, lõi tích hợp, adapter, sự kiện). |
| DU | Deployment unit | Đơn vị triển khai: một ứng dụng Spring Boot hoặc Quarkus được đóng gói và chạy độc lập. Một DU có thể chứa nhiều phân hệ dưới dạng module. |
| Modulith | Spring Modulith | Cách tổ chức một DU thành các module có ranh giới được kiểm tra tự động. |
| Strangler | Strangler fig pattern | Chiến lược thay thế dần hệ cũ: đặt hệ mới phía trước, chuyển từng phần lưu lượng sang hệ mới cho tới khi tắt được hệ cũ. |
| Idempotency | Idempotency | Tính chất gửi lại cùng một yêu cầu nhiều lần chỉ tạo ra một kết quả. Bắt buộc với API ghi và với giao dịch thanh toán. |
| Outbox | Transactional outbox | Kỹ thuật ghi sự kiện vào bảng cùng giao dịch CSDL rồi mới phát ra Kafka, để không mất hoặc phát thừa sự kiện. |
| RLS | Row Level Security | Cơ chế của PostgreSQL lọc dòng dữ liệu theo ngữ cảnh phiên; dùng để cách ly tenant. |
| Liquid Glass | Liquid Glass | Ngôn ngữ thiết kế vật liệu kính trong suốt của Apple. Datahub học theo phong cách này cho lớp điều hướng và lớp nổi, không dùng tài sản của Apple. Xem D03-05. |

: Thuật ngữ kỹ thuật của Datahub, kèm tiếng Anh

### 2.3. Từ viết tắt

Bảng dưới liệt kê các từ viết tắt dùng trong bộ tài liệu cùng dạng đầy đủ, để không phải giải thích lại ở từng tài liệu.

| Viết tắt | Đầy đủ |
|---|---|
| ADR | Architecture Decision Record — bản ghi quyết định kiến trúc |
| API | Application Programming Interface |
| ATTT | An toàn thông tin |
| BRD | Business Requirements Document — tài liệu yêu cầu nghiệp vụ |
| BHXH | Bảo hiểm xã hội |
| CK, NB, CN1, CN2, TC | Nhóm phân loại dữ liệu: công khai, nội bộ, dữ liệu cá nhân cơ bản, dữ liệu cá nhân nhạy cảm, tài chính (D02-06 chương 2); `TC` ở đây khác `TC-{PH}-{nnn}` là test case |
| CP | Chính phủ |
| CPĐT | Chính phủ điện tử |
| DFD | Data Flow Diagram — sơ đồ luồng dữ liệu |
| DMDC | Danh mục dùng chung |
| DR | Disaster Recovery — khôi phục sau thảm họa |
| DS | Data store — kho dữ liệu trong sơ đồ luồng dữ liệu (`DS-{nn}`, D02-06) |
| ĐKKD | Đăng ký kinh doanh |
| ĐVQHNS | Đơn vị có quan hệ với ngân sách |
| FR / NFR | Functional / Non-functional Requirement |
| FRS | Functional Requirements Specification |
| HDSD / HDVH | Hướng dẫn sử dụng / Hướng dẫn vận hành |
| K8s | Kubernetes |
| LLTP | Lý lịch tư pháp |
| MVP | Minimum Viable Product — phạm vi tối thiểu của đợt đầu |
| NCKT | Nghiên cứu khả thi |
| RPO / RTO | Recovery Point / Time Objective |
| RTM | Requirements Traceability Matrix — ma trận truy vết |
| SAD / SDD | Software Architecture / Design Document |
| SRS | Software Requirements Specification |
| TTDL | Trung tâm dữ liệu |
| TTQGS | Khung Kiến trúc tổng thể quốc gia số |
| UAT | User Acceptance Test |
| VBQPPL | Văn bản quy phạm pháp luật |
| WCAG | Web Content Accessibility Guidelines |

: Từ viết tắt dùng trong bộ tài liệu và dạng đầy đủ

## 3. Hệ mã truy vết

### 3.1. Bảng mã

Mỗi đối tượng trong bộ tài liệu có một mã duy nhất, không bao giờ được tái sử dụng kể cả khi đối tượng bị xóa (khi đó đánh dấu "Đã hủy" và giữ nguyên mã). `{PH}` là số phân hệ hai chữ số `01`…`20`.

| Mã | Đối tượng | Định nghĩa tại | Ví dụ |
|---|---|---|---|
| `LGC-{khối}-{nnn}` | Chức năng của hệ cũ. Khối ∈ `BUS`, `TOOL`, `HUB`, `APIM`, `DMDC`, `PAY`, `NGSP`, `IAM`, `NFR` | D00-03 | `LGC-DMDC-006` |
| `BO-{nn}` | Mục tiêu nghiệp vụ | D02-01 | `BO-03` |
| `KPI-{nn}` | Chỉ số đo mục tiêu | D02-01 | `KPI-05` |
| `BP-{nn}` | Quy trình nghiệp vụ TO-BE | D02-01 | `BP-04` |
| `SH-{nn}` | Bên liên quan | D02-01 | `SH-02` |
| `REQ-{nn}` | Yêu cầu nghiệp vụ cấp cao | D02-01 | `REQ-12` |
| `UC-{PH}-{nn}` | Use case | D02-04 | `UC-19-04` |
| `EP-{PH}-{chữ}` | Epic: nhóm story cùng nhóm chức năng (Nhóm A, B…) của FRS; với `PH` = `00` chữ lấy từ số mục 4.n của SRS | D02-05 | `EP-07-C` |
| `US-{PH}-{nnn}` | User story; `nnn` trùng số FR gốc (mỗi FR một story), story tách thêm khi làm rõ backlog lấy số từ 501 trong cùng phân hệ | D02-05 | `US-07-031` |
| `FR-{PH}-{nnn}` | Yêu cầu chức năng | D02-03 | `FR-07-021` |
| `NFR-{PH}-{nnn}` | Yêu cầu phi chức năng; `PH` = `00` cho cấp hệ thống | D02-02, D02-03 | `NFR-00-014` |
| `BR-{PH}-{nnn}` | Quy tắc nghiệp vụ | D02-03 | `BR-19-006` |
| `DD-{nn}` | Thực thể dữ liệu dùng chung giữa nhiều phân hệ | D02-07 | `DD-03` |
| `EN-{PH}-{nn}` | Thực thể dữ liệu của một phân hệ | D02-03, D03-03 | `EN-19-03` |
| `API-{PH}-{nnn}` | Endpoint REST | D03-04 | `API-07-014` |
| `EVT-{PH}-{nn}` | Loại sự kiện | D03-04 | `EVT-10-02` |
| `UI-{PH}-{nn}` | Màn hình | D03-06 | `UI-07-05` |
| `CMP-{TênThànhPhần}` | Thành phần giao diện trong design system | D03-05 | `CMP-DataTable` |
| `TKN-{nhóm}-{tên}` | Design token | D03-05 | `TKN-color-primary` |
| `PTN-{nn}` | Mẫu bố cục màn hình (screen pattern) | D03-06 | `PTN-03` |
| `DS-{nn}` | Kho dữ liệu (data store) trong sơ đồ luồng dữ liệu và phân loại dữ liệu | D02-06 | `DS-03` |
| `ROLE-{MÃ}` | Vai trò | D02-08 | `ROLE-TENANT_ADMIN` |
| `PERM-{PH}-{động-từ}` | Quyền | D02-08 | `PERM-07-publish` |
| `ERR-{PH}-{nnn}` | Mã lỗi nghiệp vụ | D03-04 | `ERR-19-004` |
| `SEC-{nn}` | Biện pháp an toàn thông tin | D03-07 | `SEC-12` |
| `ADR-{nnn}` | Quyết định kiến trúc | D00-02 | `ADR-007` |
| `RSK-{nn}` | Rủi ro | D01-02 | `RSK-09` |
| `TS-{PH}-{nn}` / `TC-{PH}-{nnn}` | Kịch bản kiểm thử / test case | D05-02 | `TC-07-045` |
| `CMP-LAW-{nn}` | Điều khoản pháp lý được truy vết | D00-03 | `CMP-LAW-07` |
| `THR-{nn}` / `TA-{nn}` | Mối đe dọa (STRIDE) / tác nhân đe dọa | D03-07 | `THR-05` |
| `AS-{nn}` | Tài sản thông tin được bảo vệ (AS-01…20) | D03-07 | `AS-09` |
| `UC-SEC-{nn}` / `PB-{nn}` | Ca phát hiện sự cố an ninh / kịch bản ứng phó (playbook) | D03-07 | `PB-04` |
| `Z0`…`Z7` | Vùng mạng | D03-07, D03-09 | `Z2` |
| `TCD-{nn}` / `CD4-{nn}` / `TT-{nn}` | Tiêu chí xác định cấp độ / yếu tố đẩy lên cấp độ 4 / trường điền hồ sơ cấp độ | D03-08 | `TCD-03` |
| `QM-{NHO\|VUA\|LON\|CHUNG}` | Hồ sơ quy mô triển khai | D03-09 | `QM-VUA` |
| `HT-{A\|B}` | Hồ sơ hạ tầng: A on-prem tại TTDL tỉnh, B cloud Chính phủ dùng chung | D03-09 | `HT-A` |
| `TPH-{n}` / `RBK-{nn}` | Tầng phục hồi DR / runbook | D03-09 | `TPH-0` |
| `RSK-H{nn}` / `RSK-T{nn}` | Rủi ro hạ tầng / rủi ro kiểm thử (khác `RSK-{nn}` của dự án) | D03-09, D05-01 | `RSK-H08` |
| `CC-{nhóm}-{nn}` / `QT-{nhóm}-{nn}` | Quy chuẩn lập trình / quy trình kỹ thuật | D04-01, D04-02 | `CC-JAVA-04` |
| `CI-1`…`CI-9` | Cổng chất lượng trong CI (khác cổng quản lý dự án G0–G5) | D04-02 | `CI-3` |
| `RG-1`…`RG-5` / `CX-{nn}` | Cổng phát hành kiểm thử / tiêu chí xuất | D05-01 | `RG-2` |
| `S1`…`S4` / `P1`…`P4` | Mức nghiêm trọng / mức ưu tiên của lỗi | D05-01 | `S2/P1` |
| `T90`…`T99` | Mã tenant dành cho kiểm thử, gồm kiểm thử rò rỉ chéo tenant (`testTenant = true`) | D05-01 | `T91` |
| `T01`…`T34` | Mã tenant tổng hợp chỉ để đo hiệu năng quy mô 34 tỉnh (`testTenant = true`, NFR-20-005); không dùng cho kiểm thử rò rỉ | D05-01, D05-02-PH20 | `T17` |
| `STD-{nn}` | Tiêu chuẩn kỹ thuật viện dẫn | D00-01 §7 | `STD-06` |

: Họ mã truy vết, đối tượng, tài liệu định nghĩa và ví dụ

### 3.2. Quy tắc truy vết

Năm quy tắc dưới đây bảo đảm mọi yêu cầu đi được từ mục tiêu nghiệp vụ tới kiểm thử và mọi chức năng hệ cũ đều có kết luận.

1. Mỗi `FR` phải tham chiếu ít nhất một `REQ`. Nếu FR thay thế chức năng hệ cũ thì tham chiếu thêm `LGC`.
2. Mỗi `UC` liệt kê các `FR` mà nó hiện thực.
3. Mỗi `API`, `EN`, `UI` liệt kê các `FR` mà nó phục vụ.
4. Mỗi `FR` mức ưu tiên M có ít nhất hai `TC`: một dương tính và một âm tính.
5. Mỗi `LGC` có đúng một kết luận trong RTM: **Giữ nguyên** (hành vi tương đương), **Nâng cấp** (giữ mục đích, làm tốt hơn), **Thay thế** (mục đích được đáp ứng bằng cách khác) hoặc **Loại bỏ** (kèm lý do được chủ đầu tư chấp thuận).

## 4. Quy ước viết yêu cầu

### 4.1. Mức ưu tiên

Ba mức ưu tiên dưới đây dùng cho mọi yêu cầu, để biết mức nào bắt buộc nghiệm thu và mức nào có thể lùi.

| Mức | Ký hiệu | Ý nghĩa |
|---|---|---|
| Bắt buộc | **M** (Must) | Thiếu thì phân hệ không dùng được, hoặc vi phạm quy định, hoặc mất một chức năng hệ cũ đang dùng. |
| Cần có | **S** (Should) | Ảnh hưởng đáng kể tới chất lượng; có thể lùi sang đợt sau nếu được chấp thuận. |
| Nên có | **C** (Could) | Cải thiện trải nghiệm; không chặn nghiệm thu. |

: Ba mức ưu tiên M, S, C và ý nghĩa

### 4.2. Cách viết một yêu cầu đo được

Mỗi yêu cầu được viết thành một câu khẳng định có chủ ngữ là "Hệ thống" hoặc một tác nhân cụ thể, dùng động từ "phải". Yêu cầu chứa giá trị đo thì ghi rõ đơn vị, điều kiện đo và phân vị. Ví dụ:

- Không đạt: "Hệ thống phải phản hồi nhanh."
- Đạt: "Hệ thống phải trả kết quả tra cứu một mã danh mục với độ trễ p95 ≤ 20 ms, đo tại gateway, khi tải 500 yêu cầu/giây và dữ liệu đã có trong bộ đệm."

Những điểm chưa có thông tin không được viết chung chung. Người viết ghi thành câu hỏi mở theo mẫu `> **Câu hỏi mở Qxx:** …` và đưa vào danh sách câu hỏi mở ở cuối tài liệu.

### 4.3. Mẫu đặc tả một FR

Từ 26/11/2026, mỗi FR được đặc tả bằng bảng hai cột 17 mục theo thứ tự cố định dưới đây (chuẩn kết hợp). Chuẩn này giữ 12 trường kỹ thuật cũ của mục này (để kỹ sư, kiểm thử viên dùng ngay) và thêm các mục của mẫu thuyết minh đặc tả chức năng (để hội đồng và người dùng nghiệp vụ đọc được). Cách viết trong Markdown, mức sàn và ví dụ ở [K-TRINH-BAY](khuon/K-TRINH-BAY.md) §4. Tiêu đề `#### FR-{PH}-{nnn} · {động từ + đối tượng}` thay cho trường "Mã, tên".

| Mục | Nội dung | Nguồn |
|---|---|---|
| Mục đích | Chức năng giúp ai làm được việc gì, vì sao cần (1–3 câu) | Mẫu thuyết minh |
| Tác nhân, quyền | Vai trò thực hiện và `PERM` cần có | Trường cũ "Tác nhân, quyền" |
| Mức ưu tiên, đợt | M / S / C · đợt phát hành | Trường cũ "Mức ưu tiên" + mẫu |
| Truy vết | REQ, LGC, Q, ADR | Trường cũ "Truy vết" |
| Tiền điều kiện | Trạng thái hệ thống trước khi thực hiện | Trường cũ |
| Kích hoạt | Thao tác người dùng (nút, màn) hoặc sự kiện, lịch khởi động chức năng | Mẫu thuyết minh |
| Đầu vào | Tham số, trường nhập: tên, kiểu chuẩn, bắt buộc, ràng buộc, ví dụ; từ 5 trường thì bảng riêng "Dữ liệu vào của FR-…" | Trường cũ |
| Luồng xử lý chính | Các bước đánh số, chủ ngữ là tác nhân hoặc "Hệ thống"; bước kiểm tra ghi mã lỗi khi không đạt | Trường cũ "Xử lý" + mẫu |
| Luồng thay thế | Nhánh hợp lệ khác của luồng chính, hoặc "Không" | Mẫu thuyết minh |
| Luồng ngoại lệ | Mỗi ngoại lệ: điều kiện, mã `ERR`, mã HTTP, hành vi, câu thông báo người dùng nhìn thấy | Trường cũ "Ngoại lệ" + mẫu |
| Đầu ra | Mã HTTP, trường trả về, tiêu đề, dữ liệu thay đổi | Trường cũ |
| Kết quả | Điều người dùng nhận được, nói theo góc nhìn người dùng | Mẫu thuyết minh |
| Hậu điều kiện | Trạng thái sau khi thực hiện thành công | Trường cũ |
| Sự kiện phát ra | `EVT` nếu có, hoặc "Không" | Trường cũ |
| Kiểm toán | Có ghi nhật ký kiểm toán hay không, các trường được ghi | Trường cũ |
| Quy tắc nghiệp vụ | Mã `BR` áp dụng | Mẫu thuyết minh |
| Màn hình, API | `UI` (kèm tab, bước) và `API` hiện thực chức năng | Mẫu thuyết minh |

: Mẫu đặc tả một FR (chuẩn kết hợp 17 mục)

## 5. Kiểu dữ liệu chuẩn

Các kiểu dưới đây áp dụng cho mọi đặc tả dữ liệu, API và CSDL. Một trường chỉ được dùng kiểu khác khi có lý do ghi trong SDD.

| Kiểu chuẩn | Ý nghĩa | PostgreSQL | JSON / OpenAPI | Ghi chú |
|---|---|---|---|---|
| `T-ID` | Định danh nội bộ | `uuid` | `string`, `format: uuid` | UUID phiên bản 7 (có thứ tự thời gian), sinh ở tầng ứng dụng. |
| `T-CODE` | Mã nghiệp vụ do người dùng đặt | `varchar(64)` | `string`, pattern `^[A-Z0-9][A-Z0-9_.-]{0,63}$` | Không phân biệt hoa thường khi so sánh; lưu dạng chữ hoa. |
| `T-SLUG` | Mã chữ thường dùng làm thành phần đường dẫn công bố (mã API, mã gói, mã nhóm của PH-02) | `varchar(64)` | `string`, pattern `^[a-z][a-z0-9-]{2,62}$` | Chữ thường, so sánh phân biệt chữ; khác `T-CODE` vì là một phần của URL công bố. Chỉ dùng khi mã nằm trong đường dẫn. |
| `T-NAME` | Tên hiển thị | `varchar(255)` | `string`, `maxLength: 255` | Unicode chuẩn hóa NFC. |
| `T-TEXT` | Mô tả dài | `text` | `string`, `maxLength: 4000` | Giới hạn 4.000 ký tự ở tầng API. |
| `T-TS` | Thời điểm | `timestamptz` | `string`, `format: date-time` | Lưu UTC; hiển thị theo giờ Việt Nam (UTC+7), định dạng `dd/MM/yyyy HH:mm:ss`. |
| `T-DATE` | Ngày | `date` | `string`, `format: date` | Hiển thị `dd/MM/yyyy`. |
| `T-MONEY` | Số tiền VND | `numeric(19,0)` | `integer` (int64) | Không dùng số thực. Hệ cũ dùng `int(10)`, giới hạn khoảng 2,1 tỷ đồng; phải chuyển đổi khi di trú. |
| `T-BOOL` | Đúng / sai | `boolean` | `boolean` | Không dùng số 0/1. |
| `T-ENUM` | Giá trị liệt kê | `varchar(32)` + `CHECK` | `string`, `enum` | Giá trị viết hoa, gạch dưới, ví dụ `PUBLISHED`. |
| `T-JSON` | Cấu trúc tự do | `jsonb` | `object` | Phải có JSON Schema mô tả trong SDD. |
| `T-TENANT` | Mã tenant | `varchar(16)` | `string` | Mã tỉnh theo danh mục đơn vị hành chính, ví dụ `T68`. Có mặt trong mọi bảng nghiệp vụ. |
| `T-TRACE` | Mã truy vết giao dịch | `char(32)` | `string` | Trace ID theo W3C Trace Context, 32 ký tự hexa. |
| `T-EMAIL` | Thư điện tử | `varchar(254)` | `string`, `format: email` | |
| `T-PHONE` | Số điện thoại | `varchar(15)` | `string`, E.164 | Lưu dạng `+84…`. |
| `T-URI` | Địa chỉ | `varchar(2048)` | `string`, `format: uri` | |
| `T-SECRET-REF` | Tham chiếu bí mật | `varchar(255)` | `string` | Đường dẫn tới kho bí mật; **không bao giờ lưu giá trị bí mật**. |

: Kiểu dữ liệu chuẩn và ánh xạ sang PostgreSQL, JSON, OpenAPI

### 5.1. Trường ngữ cảnh bắt buộc

Mọi bảng nghiệp vụ có các cột sau, trừ khi SDD ghi rõ ngoại lệ:

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | `T-ID` | Khóa chính |
| `tenant_id` | `T-TENANT` | Tenant sở hữu dòng dữ liệu; là điều kiện của chính sách RLS |
| `created_at`, `created_by` | `T-TS`, `T-ID` | Thời điểm và người tạo |
| `updated_at`, `updated_by` | `T-TS`, `T-ID` | Thời điểm và người sửa cuối |
| `version` | `integer` | Khóa lạc quan, tăng mỗi lần sửa |

: Trường ngữ cảnh bắt buộc

Bảng có xóa mềm thêm `deleted_at` (`T-TS`, có thể rỗng).

## 6. Quy ước đặt tên

Bảng dưới quy định cách đặt tên cho từng loại đối tượng kỹ thuật, kèm ví dụ, để mã nguồn và tài liệu của các phân hệ nhất quán.

| Đối tượng | Quy ước | Ví dụ |
|---|---|---|
| Schema PostgreSQL | `ph{nn}_{tên ngắn}` | `ph07_rdm`, `ph19_payment` |
| Bảng, cột | `snake_case`, tiếng Anh, danh từ số ít | `catalog_item`, `paid_at` |
| Đường dẫn REST | `/api/{nhóm}/v{n}/{tài-nguyên-số-nhiều}` với `kebab-case` | `/api/rdm/v1/catalogs/{code}/items` |
| Nhóm REST | Một nhóm cho mỗi phân hệ có API: `onboarding` (PH-01), `catalog` (02), `gateway` (03), `integration` (04), `adapter` (05), `mdm` (06), `rdm` (07), `dq` (08), `privacy` (09), `event` (10), `bpm` (11), `iam` (12), `observability` và `audit` (13), `national` (14), `portal` (15), `kpi` (16), `assist` (17), `ops` (18), `payment` và `payment-callback` (19), `platform` và `tenant` (20) | `/api/gateway/v1` |
| Lỗi REST | RFC 9457, trường `type` có dạng `https://datahub.gov.vn/errors/ERR-{PH}-{nnn}` cho mọi phân hệ; mã lỗi do cổng trả cho bên gọi dùng dải `101…199` của phân hệ (ví dụ `ERR-03-101…199`) | `https://datahub.gov.vn/errors/ERR-07-026` |
| Topic Kafka | `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}`; topic cấp nền tảng không có tiền tố tenant mà dùng `platform` | `t68.rdm.catalog.published.v1`, `platform.tenant.created.v1` |
| Package Java | `vn.datahub.{du}.{module}.{api|internal|events}` | `vn.datahub.data.rdm.api` |
| Component React | `PascalCase`; hook `useCamelCase` | `CatalogTree`, `useCatalogItems` |
| Design token | `--dh-{nhóm}-{vai trò}-{biến thể}` | `--dh-color-surface-glass-regular` |
| Nhánh Git | `{loại}/{mã-việc}-{mô-tả-ngắn}` | `feat/FR-07-021-import-excel` |

: Quy ước đặt tên theo loại đối tượng kỹ thuật

## 7. Căn cứ pháp lý và tiêu chuẩn viện dẫn

Cột "Trạng thái kiểm tra" cho biết số hiệu và hiệu lực đã được đối chiếu với nguồn chính thức hay chưa. Văn bản ở trạng thái "Cần xác minh" phải được kiểm tra trước khi tài liệu được phát hành bản 1.0.

| Mã | Văn bản | Nội dung chi phối Datahub | Trạng thái kiểm tra |
|---|---|---|---|
| CMP-LAW-01 | Luật Dữ liệu số 60/2024/QH15 (hiệu lực 01/7/2025) | Quản trị, kết nối, chia sẻ, phân loại dữ liệu | Đã đối chiếu với repo, cần xác minh nguồn gốc |
| CMP-LAW-02 | Nghị định 165/2025/NĐ-CP | Quy định chi tiết Luật Dữ liệu | Cần xác minh |
| CMP-LAW-03 | Nghị định 278/2025/NĐ-CP ngày 22/10/2025 (thay toàn bộ NĐ 47/2020/NĐ-CP) | Kết nối, chia sẻ dữ liệu qua Nền tảng chia sẻ, điều phối dữ liệu của TTDL quốc gia; Agent Node tại tỉnh; hạn chuẩn hóa 31/12/2026 | Tra web 21/11/2026, cần đối chiếu Công báo. Kế thừa: NĐ 47/2020 |
| CMP-LAW-04 | Nghị định 356/2025/NĐ-CP (hiệu lực 01/01/2026, thay NĐ 13/2023/NĐ-CP) | Quy định chi tiết Luật BVDLCN; DPIA, thông báo vi phạm 72 giờ | Tra web 21/11/2026, cần đối chiếu Công báo. Kế thừa: NĐ 13/2023 |
| CMP-LAW-05 | Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 (hiệu lực 01/01/2026) | Xử lý dữ liệu cá nhân, sự đồng ý, đánh giá tác động | Tra web 21/11/2026, cần đối chiếu Công báo |
| CMP-LAW-06 | Nghị định 331/2026/NĐ-CP ngày 19/8/2026 (kế nhiệm NĐ 85/2016/NĐ-CP) | Bảo vệ an ninh mạng đối với HTTT theo cấp độ 1–5; thẩm định, phê duyệt hồ sơ cấp độ | Tra web 21/11/2026, cần đối chiếu Công báo. Kế thừa: NĐ 85/2016 |
| CMP-LAW-07 | Thông tư 12/2022/TT-BTTTT | Hướng dẫn chi tiết cấp độ (theo NĐ 85/2016) | Giữ làm đối chiếu cho tới khi có văn bản hướng dẫn NĐ 331/2026 (Q301) |
| CMP-LAW-08 | TCVN 14423:2026 (thay TCVN 14423:2025 và TCVN 11930:2017) | Yêu cầu bảo đảm ATTT theo cấp độ; cấp độ 3 gồm 18 nhóm 5.1–5.18 | Tra web 21/11/2026; số mục cần đối chiếu bản chính thức (Q313). Kế thừa: TCVN 11930:2017 |
| CMP-LAW-09 | Công văn 631/THH-THHT ngày 21/5/2020 | Yêu cầu chức năng, kỹ thuật của LGSP | Đã đối chiếu với repo |
| CMP-LAW-10 | Quyết định 2568/QĐ-BTTTT (2023) và Quyết định 1729/QĐ-BTTTT (2024) | Khung Kiến trúc CPĐT Việt Nam phiên bản 3.0 | Đã đối chiếu với repo |
| CMP-LAW-11 | Dự thảo Khung Kiến trúc tổng thể quốc gia số | Bốn lớp kiến trúc, năng lực NDOP, KPI, AI | Dự thảo, theo dõi bản chính thức |
| CMP-LAW-12 | Thông tư 13/2017/TT-BTTTT | Yêu cầu kỹ thuật kết nối với CSDL quốc gia | Cần xác minh |
| CMP-LAW-13 | Thông tư 39/2017/TT-BTTTT | Danh mục tiêu chuẩn kỹ thuật ứng dụng CNTT trong CQNN | Cần xác minh văn bản thay thế |
| CMP-LAW-14 | Nghị định 224/2026/NĐ-CP ngày 24/6/2026 quy định chi tiết Luật Chuyển đổi số 148/2025/QH15 (hiệu lực 01/7/2026); bãi bỏ NĐ 45/2026 (văn bản từng thay NĐ 73/2019) theo khoản 2 Điều 90 | Quản lý dự án đầu tư hệ thống chuyển đổi số: nội dung BCNCKT (Điều 45), thiết kế cơ sở (Điều 46), tuân thủ Khung kiến trúc tổng thể quốc gia số (Điều 37); dự án chưa có quyết định đầu tư áp dụng NĐ này (khoản 1 Điều 91). Chi phí theo Thông tư 39/2026/TT-BKHCN | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| CMP-LAW-15 | Nghị định 30/2020/NĐ-CP | Thể thức văn bản; áp dụng cho trình bày bản .docx | Cần xác minh |
| CMP-LAW-16 | Luật An ninh mạng số 116/2025/QH15 (hiệu lực 01/7/2026) và văn bản hướng dẫn | Lưu trữ dữ liệu trong nước, nhật ký, bảo vệ hệ thống thông tin | Cần xác minh văn bản hướng dẫn |
| CMP-LAW-17 | Nghị định 331/2026/NĐ-CP (xem CMP-LAW-06) | Điều 39 về chuyển tiếp; Datahub được xác định là hệ mới (Q300, chốt 25/11/2026) | Tra web 21/11/2026, cần đối chiếu Công báo |
| CMP-LAW-18 | Nghị định 356/2025/NĐ-CP (xem CMP-LAW-04) | Hồ sơ DPIA gửi A05, thông báo vi phạm DLCN | Tra web 21/11/2026, cần đối chiếu Công báo |
| CMP-LAW-19 | Nghị định 278/2025/NĐ-CP (xem CMP-LAW-03) | Kết nối với nền tảng chia sẻ dữ liệu quốc gia | Tra web 21/11/2026, cần đối chiếu Công báo |
| CMP-LAW-20 | Quyết định 8297/QĐ-BCA-A05 (2025) | Tiêu chí an ninh mạng cho nền tảng đám mây phục vụ CPĐT; áp dụng cho hồ sơ HT-B | Tra web 21/11/2026, cần đối chiếu Công báo |
| CMP-LAW-21 | Luật Chuyển đổi số số 148/2025/QH15 (hiệu lực 01/7/2026) | Luật gốc của NĐ 224/2026; đầu tư, mua sắm, thuê dịch vụ cho chuyển đổi số | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| CMP-LAW-22 | Nghị định 194/2025/NĐ-CP ngày 03/7/2025 (Luật Giao dịch điện tử: CSDL quốc gia, kết nối, chia sẻ dữ liệu, dữ liệu mở) | Hạng mục kết nối, chia sẻ CSDL trong thiết kế cơ sở (D01-01 §5.8.3) | Cần xác minh |
| CMP-LAW-23 | Thông tư 39/2026/TT-BKHCN (hiệu lực 01/7/2026, thay TT 18/2024/TT-BTTTT) | Lập và quản lý chi phí đầu tư, mua sắm, thuê dịch vụ cho chuyển đổi số; cơ cấu tổng mức đầu tư (D01-01 §8) | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| CMP-LAW-24 | Thông tư 41/2026/TT-BKHCN (hiệu lực 01/7/2026) | Khảo sát, triển khai, giám sát, kiểm thử, nghiệm thu dự án theo NĐ 224/2026 (D01-02 §3, §10, §13) | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| CMP-LAW-25 | Luật Đầu tư công số 58/2024/QH15, sửa đổi bởi Luật 90/2025/QH15 | Nhóm dự án, chủ trương đầu tư; khoản 2 Điều 47 là khung nội dung BCNCKT | Đã đối chiếu nguồn thứ cấp |
| CMP-LAW-26 | Luật Đấu thầu số 22/2023/QH15, sửa đổi bởi Luật 57/2024/QH15 và Luật 90/2025/QH15 | Lựa chọn nhà thầu, gói EP (D01-01 §9.4, D01-02 §7.3) | Đã đối chiếu VBHN 74/VBHN-VPQH |
| CMP-LAW-27 | Luật Bảo vệ bí mật nhà nước số 29/2018/QH14 (hiệu lực 01/7/2020) | Danh mục bí mật nhà nước; dữ liệu thuộc danh mục không được công bố qua Datahub (BR-02-007, ERR-02-016) | Cần xác minh số hiệu, hiệu lực và văn bản hướng dẫn hiện hành |
| CMP-LAW-91 | Nghị định 45/2020/NĐ-CP về thực hiện TTHC trên môi trường điện tử | Nộp phí, lệ phí trực tuyến trong TTHC (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-92 | Nghị định 42/2022/NĐ-CP về cung cấp thông tin và dịch vụ công trực tuyến | Dịch vụ công trực tuyến toàn trình có thanh toán (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-93 | Nghị định 61/2018/NĐ-CP về cơ chế một cửa, sửa đổi bởi Nghị định 107/2021/NĐ-CP | Vai trò Cổng DVC quốc gia, HTTT giải quyết TTHC (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-94 | Nghị định 52/2024/NĐ-CP về thanh toán không dùng tiền mặt | Cơ sở khẳng định PH-19 không làm trung gian thanh toán (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-95 | Luật Giao dịch điện tử số 20/2023/QH15 | Giá trị pháp lý của thông điệp dữ liệu, chứng cứ IPN, biên bản (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-96 | Thông tư 74/2022/TT-BTC hoặc văn bản thay thế; quy định về biên lai thu phí, lệ phí điện tử | Hình thức, thời hạn thu, nộp phí, lệ phí (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| CMP-LAW-97 | Luật Kế toán số 88/2015/QH13 và Luật Lưu trữ năm 2024 | Thời hạn lưu chứng từ ≥ 10 năm (PH-19) | Cần xác minh (dải 91–97 dành cho PH-19, D02-01-PH19 §2.1) |
| STD-01 | ISO/IEC/IEEE 29148 | Cấu trúc đặc tả yêu cầu | — |
| STD-02 | ISO/IEC/IEEE 29119-3 | Cấu trúc tài liệu kiểm thử | — |
| STD-03 | OWASP ASVS 5.0 (mức 2) | Yêu cầu kiểm chứng an toàn ứng dụng | — |
| STD-04 | WCAG 2.2 | Khả năng truy cập giao diện, mức AA | — |
| STD-05 | OpenAPI 3.1, AsyncAPI 3.0, RFC 9457 | Hợp đồng API, sự kiện, định dạng lỗi | — |
| STD-06 | TCVN 14423:2026 | Căn cứ chính của thiết kế ATTT cấp độ 3 (xem CMP-LAW-08, D03-07 mục 2.3) | — |
| STD-07 | OWASP API Security Top 10 2023; OWASP Top 10 2021 | Mô hình mối đe dọa API, kiểm thử (D03-07) | — |
| STD-08 | CIS Kubernetes Benchmark; NSA/CISA Kubernetes Hardening Guidance | Biện pháp nền tảng `SEC-50…59` | — |
| STD-09 | SLSA mức 3 | Chuỗi cung ứng phần mềm, ảnh do Datahub xây (`SEC-55…57`) | — |
| STD-10 | RFC 9700, 8705, 7523, 7636, 9449 | OAuth 2.0 an toàn, mTLS, xác thực client bằng JWT, PKCE, DPoP (`SEC-20…29`) | — |
| STD-11 | ISO/IEC 27001:2022 và 27002:2022 | Cấu trúc kiểm soát quản trị ATTT (`SEC-01…09`) | — |
| STD-12 | NIST SP 800-63B | Định danh số và xác thực, tham khảo cho chính sách mật khẩu (`SEC-22`) | — |

: Mã, văn bản, nội dung chi phối và trạng thái kiểm tra của căn cứ pháp lý và tiêu chuẩn

Bối cảnh tổ chức từ năm 2025 cũng chi phối thiết kế: Bộ Thông tin và Truyền thông hợp nhất vào Bộ Khoa học và Công nghệ; chính quyền địa phương chuyển sang mô hình hai cấp (tỉnh, xã); số đơn vị hành chính cấp tỉnh còn 34. Hệ quả trực tiếp là danh mục đơn vị hành chính phải hỗ trợ lịch sử sáp nhập, và cơ quan chủ quản ở các văn bản hệ cũ phải được hiểu theo cơ cấu mới.

## 8. Quy ước trình bày tài liệu

Sáu quy ước dưới đây áp dụng cho mọi file Markdown của bộ tài liệu; quy chuẩn chi tiết về văn phong nằm ở khuon/K-TRINH-BAY.

1. Mỗi file Markdown bắt đầu bằng khối metadata YAML gồm sáu trường bắt buộc `ma_tai_lieu`, `ten`, `phien_ban`, `ngay` (ISO `yyyy-MM-dd`), `trang_thai` (`Dự thảo` / `Chờ duyệt` / `Đã duyệt`), `nguoi_doc`. Được thêm trường tùy chọn `nguoi_lap`, `phan_he` (ví dụ `PH-07`), `thay_the` (mã tài liệu bị thay thế). Khối này sinh trang bìa và bảng ghi nhận thay đổi khi xuất .docx. Tiêu đề cấp 1 của file có dạng `# {mã} · {tên}`.
2. Phiên bản tài liệu: `0.x` là dự thảo; `1.0` là bản được duyệt qua cổng; tăng số phụ khi sửa nội dung, tăng số chính khi đổi phạm vi.
3. Sơ đồ viết bằng Mermaid trong khối ```` ```mermaid ````. Mỗi sơ đồ có một đoạn thuyết minh ngay sau nó.
4. Bảng có câu dẫn giải thích bảng dùng để làm gì. Không dùng bảng để thay cho lập luận.
5. Câu viết bằng tiếng Việt đầy đủ chủ vị. Thuật ngữ tiếng Anh chuẩn ngành được giữ trong ngoặc ở lần xuất hiện đầu.
6. Không đưa bí mật, địa chỉ IP thật, khóa truy cập thật hay dữ liệu cá nhân thật vào tài liệu. Ví dụ dùng giá trị giả lập rõ ràng.

## 9. Tổ chức file, ADR và làm việc song song

### 9.1. Đặt tên file

Tên file có dạng `{mã-tài-liệu}-{tên-không-dấu-gạch-nối}.md`, ví dụ `D02-01-brd.md`, `D03-05-design-system.md`. Tài liệu chia tập theo phân hệ đặt trong thư mục con của nhóm và mang mã phân hệ: `02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md`, `03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md`, `05-kiem-thu/test-case/D05-02-PH07-test-case.md`. Hình ảnh đặt ở thư mục `assets/` cạnh tài liệu.

### 9.2. Sổ quyết định kiến trúc

Sổ D00-02 gồm một file chỉ mục `00-chung/D00-02-so-adr.md` và **mỗi ADR một file** trong `00-chung/adr/`, tên `ADR-{nnn}-{tên-không-dấu}.md`. Mỗi ADR theo khung MADR rút gọn: Bối cảnh, Các phương án, Quyết định, Hệ quả, Trạng thái (`Đề xuất` / `Chấp nhận` / `Thay thế bởi ADR-xxx`), Truy vết. Metadata dùng chung sáu trường ở §8, với `ma_tai_lieu` là mã ADR.

Để các nhóm viết song song không trùng số, dải số ADR được cấp trước như sau. Nhóm nào cần thêm thì lấy số tiếp theo trong dải của mình.

| Dải | Chủ đề | Số đã cấp |
|---|---|---|
| ADR-001 … 019 | Kiến trúc nền, stack, dữ liệu, tích hợp, đa tenant (luồng lõi) | 001 Spring Boot 4 + Modulith làm backend chung; 002 Camel Quarkus cho PH-04/05/14; 003 PostgreSQL + RLS cho đa tenant; 004 Kafka thay Pulsar; 005 APISIX làm gateway; 006 Keycloak + OPA; 007 Flowable; 008 Garage cho lưu trữ đối tượng; 009 GitOps với Argo CD; 010 Camel YAML DSL thay XML |
| ADR-020 … 029 | Giao diện, design system | **020 Liquid Glass trên antd v6 (thay ADR-016 của repo)**; 021 font chữ |
| ADR-030 … 039 | ATTT, hạ tầng, DR, kiểm thử | — |
| ADR-040 … 049 | Thanh toán (PH-19) | — |
| ADR-050 … 059 | Danh mục dùng chung (PH-07) và các phân hệ khác | — |

: Dải số ADR cấp trước theo chủ đề và các số đã cấp

### 9.3. Nhánh và PR khi viết song song

Nhánh nền chứa khung thư mục và D00-01 là `claude/project-thread-ru93ej`. Mỗi nhóm tạo nhánh riêng từ nhánh nền và mở PR riêng. Mỗi nhóm chỉ sửa file thuộc phạm vi của mình. Việc bổ sung mã truy vết mới hoặc thuật ngữ mới vào D00-01 được ghi trong PR của nhóm và được gộp về D00-01 bởi luồng lõi, để tránh xung đột trên cùng một file. Dòng trạng thái trong `README.md` cũng do luồng lõi cập nhật.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: thuật ngữ, hệ mã truy vết, quy ước viết yêu cầu, kiểu dữ liệu, đặt tên, căn cứ pháp lý, trình bày, tổ chức file |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; thêm mục 1.1 Người đọc, 1.2 Tài liệu tham chiếu, 1.3 Cấu trúc tài liệu; thêm đoạn mở cho các mục 2.1, 2.2, 2.3, 3.2, 4.1, 6, 8; viết lại chú thích bảng cho cụ thể. Mẫu đặc tả 17 mục (mục 4.3) giữ nguyên |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: thêm mã EP, DS, T01…T34, STD và quy ước story từ 501 ở §3.1; viết tắt nhóm dữ liệu CK, NB, CN1, CN2, TC; thuật ngữ Service-code, nhãn đối chiếu, cung cấp lại và vai trò NDOP; kiểu T-SLUG; nhóm REST, mẫu type RFC 9457 và topic nền tảng ở §6; CMP-LAW-27 và STD-06…12 ở §7 |
