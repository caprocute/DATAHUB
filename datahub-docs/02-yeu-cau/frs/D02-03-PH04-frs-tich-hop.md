---
ma_tai_lieu: D02-03-PH04
ten: Đặc tả chức năng phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Chủ đầu tư, hội đồng thẩm định, nhóm phân tích nghiệp vụ, kiến trúc sư, đội phát triển dh-integration và dh-runtime, đội giao diện dh-console, đội kiểm thử, đội di trú
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
mo_ta: Đặc tả hành vi của lõi tích hợp và trình thiết kế luồng Camel Quarkus gồm quản lý luồng, thiết kế trực quan, chạy thử, duyệt bốn mắt, phát hành GitOps, vận hành và khung chín chặng của data plane, làm căn cứ thiết kế chi tiết, lập trình, kiểm thử và nghiệm thu so với Bus và Productivity Tooling của LGSP cũ.
tai_lieu_lien_quan: D02-02 SRS; D02-04-PH04 Use case; D03-02-PH04 Thiết kế chi tiết; D03-03-PH04 CSDL; D03-04-PH04 API và sự kiện; D03-06-PH04 Màn hình; D05-02-PH04 Test case
---

# D02-03-PH04 · Đặc tả chức năng phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

PH-04 Lõi tích hợp và trình thiết kế luồng thay thế hai khối "Bus" và "Productivity Tooling" của LGSP cũ. Bus cũ là tập các chương trình tích hợp (agent) Apache Camel chạy trên máy chủ cố định, được quản trị qua JMX và Jolokia; Tooling là công cụ kéo thả viết bằng Angular, sinh Camel XML và tệp `pom.xml` cho từng project. PH-04 thay cả hai bằng một quy trình khép kín: kỹ sư tích hợp thiết kế luồng trên trình thiết kế trực quan, chạy thử trên môi trường cô lập, gửi duyệt, người duyệt khác người thiết kế phê duyệt, rồi luồng được phát hành qua kho cấu hình Git và tự động triển khai xuống lớp chạy `dh-runtime` (Camel Quarkus). Phân hệ thuộc đợt MVP vì mọi lượt trao đổi có chuyển đổi dữ liệu giữa hai hệ thống thông tin (HTTT) đều đi qua luồng của PH-04.

Phạm vi phủ hệ cũ: 41 chức năng của Bus (LGC-BUS-001…041) và 29 chức năng của Tooling (LGC-TOOL-001…029) đã kiểm kê ở D00-03. Mọi chức năng được giữ hoặc nâng cấp đều có FR tương ứng (mục 11.1). Hai chức năng bị loại bỏ vì lý do an toàn thông tin: người dùng tự sửa `pom.xml` (LGC-TOOL-022) và nhập component từ tệp JAR (LGC-TOOL-027). Một số chức năng giám sát của Bus (biểu đồ lượng bản tin, CPU, bộ nhớ, log) chuyển sang PH-13; PH-04 nhúng lại các biểu đồ đó trên màn chi tiết luồng.

**Những điểm hội đồng cần lưu ý (điểm mới so với hệ cũ).**

- Luồng có phiên bản, có lịch sử và so sánh khác biệt; mọi phiên bản đem chạy đều đã qua duyệt bốn mắt.
- Luồng viết bằng Camel YAML DSL thay Camel XML. Người dùng không thêm được thư viện tùy ý; chỉ dùng thành phần trong danh mục đã duyệt.
- Không còn ra lệnh trực tiếp vào máy chủ đang chạy. Trạng thái mong muốn nằm trong Git, Argo CD đưa xuống runtime và báo lại tình trạng triển khai. Lệnh tạm dừng khẩn cấp có kênh riêng, có ký và có kiểm toán.
- Bí mật kết nối không bao giờ nằm trong luồng. Luồng chỉ trỏ tới kết nối đã đăng ký ở PH-05.
- Có trình ánh xạ dữ liệu sinh biểu thức JQ, chuyển mã qua bảng ánh xạ của PH-07 và che dữ liệu cá nhân theo chính sách của PH-09.
- Một nền chạy phục vụ nhiều tỉnh. Mỗi bản tin mang ngữ cảnh tenant; luồng của tỉnh lớn chạy trong namespace riêng.

Căn cứ pháp lý chính ở mục 1.5. Phạm vi MVP ở mục 11.3, tiêu chí chấp nhận cấp phân hệ ở chương 14. Hiện trạng mã nguồn và các chỗ lệch so với thiết kế được ghi ở mục 2.7 để chủ đầu tư thấy rõ khối lượng còn lại.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng | 60 (FR-04-001…084, chia bảy nhóm A–G); mức chính M: 49, S: 10, C/S: 1 (FR-04-026); bốn FR mức M có phần mức S (027, 032, 033, 068) |
| Quy tắc nghiệp vụ | 22 (BR-04-001…022) |
| Yêu cầu phi chức năng | 17 (NFR-04-001…017) |
| Tham số theo tenant | 23 khóa `04.*` |
| Màn hình | 21 (UI-04-01…21) |
| API | Mã API-04-001…091 ở D03-04-PH04 (70 operation); 14 sự kiện (EVT-04-01…14) |
| Mã lỗi | ERR-04-001…049 (API điều khiển), ERR-04-101…112 (runtime) |
| Chức năng hệ cũ được phủ | 41/41 LGC-BUS, 29/29 LGC-TOOL có kết luận; 2 mục loại bỏ có lý do ATTT |
| Mức đợt | MVP; 12 FR hoặc phần FR mức S, C sang Đợt 2 (mục 11.3) |

: Con số chính của PH-04

## 1. Giới thiệu

### 1.1. Mục đích của tài liệu

Tài liệu này đặc tả đầy đủ yêu cầu chức năng của phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng thuộc sản phẩm Datahub. Mục tiêu là để đội phát triển lập trình ngay mà không phải đoán ý nghiệp vụ, để đội kiểm thử viết được ca dương tính và âm tính cho từng yêu cầu, và để chủ đầu tư có căn cứ nghiệm thu từng chức năng so với Bus và Tooling của hệ cũ.

Mỗi FR viết theo chuẩn kết hợp 17 mục (K-TRINH-BAY §4): 12 trường kỹ thuật của mẫu D00-01 §4.3 (tác nhân, truy vết, tiền điều kiện, đầu vào, xử lý kèm mã lỗi, đầu ra, hậu điều kiện, sự kiện, kiểm toán) cộng các mục thuyết minh (mục đích, kích hoạt, luồng thay thế, câu thông báo người dùng nhìn thấy, kết quả, màn hình). FR dùng kiểu dữ liệu chuẩn `T-*` ở D00-01 §5 và hệ mã truy vết ở D00-01 §3. Chức năng dùng chung cho mọi phân hệ (xác thực, phân trang, kiểm toán, thông báo, hộp "Việc của tôi", khóa lạc quan) đã đặc tả ở [D02-02 SRS §4](../D02-02-srs.md); tài liệu này chỉ ghi "Tuân thủ FR-00-nnn" và không viết lại.

### 1.2. Phạm vi

PH-04 gồm hai nửa chạy ở hai mặt phẳng khác nhau (ADR-013).

**Nửa điều khiển (control plane), đơn vị triển khai `dh-integration`.** Quản lý không gian làm việc và luồng; trình thiết kế luồng trên `dh-console` (canvas, bảng thành phần, cấu hình chặng, trình soạn biểu thức, đồng bộ hai chiều với YAML, Kamelet, Pipe, ca kiểm thử, bean, ánh xạ dữ liệu); kiểm tra hợp lệ; chạy thử và nhật ký chạy thử; gửi duyệt, duyệt bốn mắt, phát hành qua GitOps, thăng cấp môi trường, quay lui; điều khiển kích hoạt và tạm dừng; xem tình trạng triển khai; danh mục thành phần Camel; thư viện khuôn mẫu; công cụ chuyển luồng XML của hệ cũ sang YAML.

**Nửa chạy (data plane), đơn vị triển khai `dh-runtime`.** Khung chín chặng chuẩn của luồng; tiếp nhận đồng bộ (HTTP, SOAP qua APISIX) và bất đồng bộ (Kafka); kiểm tra lược đồ; ủy quyền qua OPA; chuyển đổi, chuẩn hóa về mô hình dữ liệu chuẩn (CDM) và chuyển mã qua PH-07; làm giàu; che dữ liệu cá nhân theo PH-09; định tuyến, tách, gộp, gọi song song; phát sự kiện; xử lý lỗi, thử lại, ngắt mạch, đẩy bản tin lỗi sang PH-18; chống trùng; truy cập CSDL có kiểm soát (Q359); ngữ cảnh tenant; phát vết, chỉ số, log.

Bảng dưới gom trách nhiệm của PH-04 theo bảy nhóm chức năng; danh sách đầy đủ ở chương 5.

| # | Trách nhiệm | Nhóm FR |
|---|---|---|
| 1 | Không gian làm việc, danh sách, chi tiết, tạo, sửa, nhân bản, gỡ luồng | A |
| 2 | Trình thiết kế luồng: sơ đồ, bảng thành phần, cấu hình chặng, biểu thức, kết nối, YAML hai chiều, Kamelet, Pipe, ánh xạ, bean, bản tin mẫu, kiểm tra hợp lệ, lưu nháp, khuôn mẫu, nhập xuất | B |
| 3 | Chạy thử trên sandbox, ca kiểm thử, nhật ký chạy thử, phủ kết quả lên sơ đồ | C |
| 4 | Gửi duyệt, duyệt bốn mắt, phát hành GitOps, so sánh, quay lui, thăng cấp | D |
| 5 | Kích hoạt, tạm dừng, dừng khẩn; tình trạng runtime; điểm kết nối; giám sát nhúng | E |
| 6 | Khung chín chặng của data plane: tiếp nhận, lược đồ, ủy quyền, chuyển đổi, làm giàu, che, định tuyến, phát sự kiện, xử lý lỗi, chống trùng, CSDL Q359, tenant, quan sát, hồ sơ runtime | F |
| 7 | Danh mục thành phần, khớp catalog, di trú XML, lịch sử, tham số và đóng băng | G |

: Trách nhiệm của PH-04 theo nhóm chức năng

Những việc dưới đây nằm ngoài phạm vi tài liệu này; PH-04 chỉ dùng kết quả của phân hệ chịu trách nhiệm.

| Việc ngoài phạm vi | Phân hệ chịu trách nhiệm | PH-04 làm gì |
|---|---|---|
| Danh mục Kamelet được duyệt và kết nối tới nguồn (khai báo, lưu bí mật, kiểm tra kết nối) | PH-05 | Chỉ dùng chúng |
| Topic, lược đồ sự kiện, publisher và subscriber | PH-10 | Chỉ gửi và nhận trên topic đã đăng ký |
| Đăng ký và công bố API ra cổng | PH-02, PH-03 | Luồng có điểm vào HTTP được công bố qua PH-02 như một backend |
| Bảng điều khiển, tra log, truy vết | PH-13 | Nhúng lại một phần trên màn chi tiết luồng |
| Xem, sửa, xử lý lại bản tin lỗi (DLQ) | PH-18 | Đẩy bản tin lỗi sang DLQ chuẩn |
| Adapter và quản lý thông tin xác thực với NDXP | PH-14 | Luồng kết nối quốc gia NDXP vẫn là luồng PH-04 |

: Việc ngoài phạm vi PH-04

### 1.3. Đối tượng sử dụng và cách đọc

Tài liệu phục vụ nhiều nhóm người đọc; bảng dưới chỉ phần nên đọc kỹ cho từng nhóm.

| Người đọc | Phần nên đọc kỹ | Mục đích sử dụng |
|---|---|---|
| Chủ đầu tư, lãnh đạo Sở, hội đồng thẩm định | Tóm tắt, chương 2, 11, 13, 14 | Xác nhận phạm vi, đối chiếu với Bus và Tooling, trả lời câu hỏi mở |
| Phân tích nghiệp vụ | Toàn bộ, đặc biệt chương 4, 6, 10 | Cơ sở cho use case D02-04-PH04 và user story |
| Kiến trúc sư, trưởng nhóm | Mục 2.4, 2.7, chương 4, chương 6 nhóm D–F, chương 8, 12 | SDD D03-02-PH04, CSDL, API |
| Lập trình viên `dh-integration` | Chương 6 nhóm A, C, D, E, G; chương 9 | Lập trình API điều khiển |
| Lập trình viên `dh-console` | Chương 4; chương 6 nhóm B, C, D; chương 10 | Màn hình D03-06-PH04 |
| Lập trình viên `dh-runtime` | Chương 6 nhóm F | Khuôn mẫu route chuẩn, Kamelet nền |
| Kiểm thử viên | Chương 6 (luồng ngoại lệ, hậu điều kiện), chương 7, 8 | Ca kiểm thử D05-02-PH04 |
| Đội di trú | Mục 2.1, FR-04-082, mục 11.1 | Chuyển luồng XML của Bus cũ |

: Người đọc và phần nên đọc

### 1.4. Thuật ngữ và chữ viết tắt

Trong tài liệu, "luồng" (flow) là một tệp tài nguyên Camel có phiên bản, quản lý như một đơn vị phát hành; một luồng có thể chứa nhiều "route" Camel. "Chặng" (step, node) là một bước trên sơ đồ, tương ứng một phần tử EIP hoặc một lời gọi thành phần. "Phiên bản" là một bản định nghĩa luồng bất biến sau khi gửi duyệt. "Triển khai" là việc một phiên bản đã duyệt được đưa xuống một môi trường. Mã thành phần Camel viết nguyên tiếng Anh như trong catalog (`kafka`, `platform-http`, `setBody`).

Repo gốc đã có hai bộ mã FR cho PH-04: `FR-04-001…040` ở `SRS-PH-04-integration-core.md` và `FR-D-001…085` ở `SRS-PH-04-designer.md`, kèm mã màn `D-01…08`, `UI-04-01…10`. Bộ tài liệu này đánh số lại theo quy ước chung (Q11). Mã cũ được giữ trong mục "Truy vết" của từng FR (ghi "Mã repo") và ở Phụ lục A, để đội phát triển đối chiếu chú thích trong mã nguồn hiện có.

| Thuật ngữ | Giải thích |
|---|---|
| Canvas | Vùng vẽ sơ đồ luồng trên trình thiết kế |
| Chặng, nút | Một phần tử trên sơ đồ, tương ứng một bước Camel |
| Cạnh | Đường nối thể hiện thứ tự xử lý giữa hai chặng |
| Inspector | Ngăn bên phải hiển thị cấu hình của chặng đang chọn |
| Bảng thành phần | Ngăn bên trái liệt kê thành phần kéo vào sơ đồ |
| Quay vòng YAML | Mở YAML lên sơ đồ rồi lưu lại; không được mất dữ liệu (BR-04-006) |
| Ghim bản tin mẫu (pin) | Gắn bản tin mẫu vào một chặng để xem trước biểu thức và ánh xạ |
| Sandbox | Môi trường chạy thử cô lập, đích bị thay bằng mô phỏng |
| Kho cấu hình | Kho Git chứa YAML luồng theo tenant và môi trường, nguồn của Argo CD |
| Hồ sơ runtime | Tập thành phần được biên dịch vào một ảnh `dh-runtime` |
| Lệnh khẩn | Lệnh tạm dừng gửi thẳng tới runtime qua topic điều khiển có ký |
| Khung chín chặng | Khuôn mẫu chuẩn của mọi luồng đối ngoại, chín khối chặng từ `receive` tới `respond` (mục 4.6) |
| Kamelet | Khối kết nối hoặc xử lý dùng lại viết bằng YAML, có tham số khai báo (loại `source`, `sink`, `action`) |
| Pipe | Tài nguyên Camel nối tuyến tính `source`, `steps`, `sink` bằng Kamelet |
| EIP | Enterprise Integration Pattern, mẫu tích hợp doanh nghiệp (`choice`, `split`, `aggregate`…) |
| CDM | Common Data Model, mô hình dữ liệu chuẩn của Datahub |
| DLQ | Dead Letter Queue, hàng đợi bản tin lỗi (topic `{tenant}.ops.dlq.v1` của PH-18) |
| GitOps | Cách triển khai lấy Git làm nguồn sự thật, Argo CD đồng bộ trạng thái xuống cụm |
| OPA | Open Policy Agent, bộ máy chính sách dùng cho chặng ủy quyền |
| SSE | Server-Sent Events, luồng sự kiện máy chủ đẩy về trình duyệt |
| IE, IA, TO, TA, SO, PA, PO, VW, AU | Vai trò theo D02-08: kỹ sư tích hợp, người duyệt tích hợp, vận hành tenant, quản trị tenant, cán bộ ATTT, quản trị nền tảng, chủ sở hữu nền tảng, người xem, kiểm toán |
| `T-FLOW-CODE` | Kiểu mã luồng, mẫu `^[a-z][a-z0-9-]{2,62}$` |
| `T-YAML` | Chuỗi UTF-8 là tài liệu YAML |
| `T-ENV` | Môi trường luồng ∈ {`TEST`, `STAGING`, `PROD`} |
| `T-INT` | Số nguyên 32 bit |

: Thuật ngữ và chữ viết tắt dùng trong PH-04

### 1.5. Tài liệu tham chiếu

Bảng thứ nhất liệt kê tài liệu dự án liên quan; bảng thứ hai liệt kê căn cứ pháp lý riêng của PH-04.

| Mã | Tài liệu | Quan hệ |
|---|---|---|
| D00-01 | Thuật ngữ và quy ước chung | Mẫu FR, kiểu `T-*`, hệ mã |
| D00-02 | Sổ ADR | ADR-002, 009, 010, 013 và ADR-060…069 của PH-04 |
| D00-03 | Ma trận truy vết | Kiểm kê LGC-BUS, LGC-TOOL (§4.1, §4.2) |
| D02-02 | SRS cấp hệ thống | FR-00-*, NFR-00-*, REQ-04 |
| D02-07 | Từ điển dữ liệu dùng chung | DD-*, trường ngữ cảnh |
| D02-08 | Ma trận phân quyền | PERM-04-*, vai trò IE, IA, TO |
| D03-01 | SAD | DU `dh-integration`, `dh-runtime`; đường phát hành §5 |
| D03-07 | Thiết kế ATTT | SEC-40…49 ứng dụng, SEC-50…59 nền tảng |
| D03-09 | Hạ tầng | Namespace `dh-runtime`, `dh-rt-{tenant}`, vùng Z4 |
| D03-10 | Đa tenant | Luồng thuộc tenant, ngưỡng 50 luồng |
| D04-01 | Coding convention | CC-CAMEL-*, Q359 |
| D02-04-PH04 | Use case PH-04 | UC-04-* |
| D03-02-PH04 | SDD PH-04 | Thiết kế chi tiết |
| D03-03-PH04 | CSDL PH-04 | Schema `ph04` |
| D03-04-PH04 | API và sự kiện PH-04 | API-04-*, EVT-04-*, ERR-04-* |
| D03-05 | Design system | CMP-*, vật liệu glass |
| D03-06-PH04 | Màn hình PH-04 | UI-04-* |
| D05-02-PH04 | Test case PH-04 | TS-04-*, TC-04-* |
| `docs/07-srs/SRS-PH-04-*.md` | SRS PH-04 của repo gốc | Nguồn tham khảo; ánh xạ mã cũ sang mã mới ở Phụ lục A |

: Tài liệu dự án liên quan

| Văn bản | Nội dung áp dụng cho PH-04 | Ghi chú |
|---|---|---|
| Luật Chuyển đổi số 148/2025/QH15 và Nghị định 224/2026/NĐ-CP | Đầu tư, thuê dịch vụ CNTT; yêu cầu hồ sơ thiết kế | Căn cứ đầu tư chung |
| Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu | Kết nối giữa các HTTT qua nền tảng chia sẻ cấp tỉnh; ghi nhật ký kết nối; chuẩn hóa trước 31/12/2026 | PH-04 là nơi thực hiện chuyển đổi và ghi vết trên đường trao đổi |
| Luật An ninh mạng 116/2025/QH15, Nghị định 331/2026/NĐ-CP | Bảo đảm an ninh HTTT cấp độ 3; kiểm soát thay đổi phần mềm, phân tách nhiệm vụ | Căn cứ duyệt bốn mắt, cấm nạp mã tùy ý |
| TCVN 14423:2026 cấp độ 3 (nhóm quản lý cấu hình, phát triển và thay đổi, nhật ký) | Quản lý phiên bản, kiểm thử trước khi đưa vào vận hành, nhật ký thao tác quản trị | Ánh xạ chi tiết ở D03-07 |
| Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP | Che, giả danh dữ liệu cá nhân khi chuyển tiếp; không lưu bản tin chứa dữ liệu cá nhân ngoài mục đích | Căn cứ BR-04-012, BR-04-013 |
| Khung kiến trúc Chính phủ số (phiên bản hiện hành) | Vai trò LGSP cấp tỉnh trong kiến trúc | Ánh xạ ở SAD |

: Căn cứ pháp lý riêng của PH-04

Các văn bản trên đã được tra cứu ngày 21/11/2026 và chưa đối chiếu Công báo; điểm chưa xác minh ghi ở câu hỏi Q04-01.

### 1.6. Cấu trúc tài liệu

Chương 2 trình bày bối cảnh, mục tiêu, vị trí và kiến trúc của phân hệ, quy trình nghiệp vụ, chức năng hệ cũ được phủ và hiện trạng mã. Chương 3 nêu tác nhân, quyền và tách nhiệm vụ. Chương 4 định nghĩa khái niệm, thực thể và vòng đời của luồng, phiên bản, triển khai, lần chạy thử, lệnh điều khiển. Chương 5 liệt kê toàn bộ 60 chức năng. Chương 6 đặc tả chi tiết từng chức năng theo khung 17 mục. Chương 7 đến chương 9 gom quy tắc nghiệp vụ, tham số, yêu cầu phi chức năng, mã lỗi, thông báo, sự kiện và API. Chương 10 giới thiệu màn hình và giao diện tiêu biểu. Chương 11 đến chương 14 là truy vết, phụ thuộc, câu hỏi mở và tiêu chí chấp nhận. Phụ lục A ánh xạ mã của repo gốc; Phụ lục B ghi các đề nghị đồng bộ với tài liệu khác.

## 2. Tổng quan phân hệ

### 2.1. Bối cảnh và vấn đề cần giải quyết

Khi hai HTTT trao đổi dữ liệu qua Datahub có hai đường đi. Đường thẳng: APISIX xác thực, kiểm tra đăng ký sử dụng rồi chuyển lượt gọi thẳng tới backend của HTTT cung cấp; đường này không cần PH-04. Đường có xử lý: dữ liệu cần đổi định dạng (SOAP sang REST, XML sang JSON), đổi mã (mã dân tộc của sở A sang mã chuẩn), ghép từ nhiều nguồn, che dữ liệu cá nhân, chuyển từ đồng bộ sang bất đồng bộ, hoặc đọc định kỳ từ CSDL và tệp FTP của hệ cũ. Mọi đường có xử lý đều là một luồng PH-04. Theo D03-09 §4, khoảng 40% lượt gọi đi qua `dh-runtime` (giả định định cỡ).

PH-04 cũng là nơi tỉnh đưa các tích hợp đang chạy trên Bus cũ sang Datahub theo kiểu strangler: từng luồng XML cũ được chuyển sang YAML, chạy song song, đối chiếu kết quả, rồi chuyển lưu lượng.

**Bus** gồm nhiều "chương trình tích hợp" (agent). Mỗi agent là một tiến trình Camel trên Spring XML chạy trên một máy chủ có host và cổng cố định, chứa nhiều route. Giao diện quản trị đọc thông tin agent, route, endpoint và số liệu qua JMX, phơi ra bằng Jolokia; cho phép start, stop agent và route, sửa host, port, method của agent, xóa agent, xem sơ đồ, mã nguồn XML và thuộc tính route. Dữ liệu quản trị lưu ở các bảng `Project`, `Group`, `Project_group` (phân quyền theo nhóm với `access_level`), `Context`, `Context_status`, `Context_file`, `File`, `Dependency`, `Builder`.

**Productivity Tooling** là trình thiết kế kéo thả: thanh Project, thanh Component có chế độ thu gọn và mở rộng, nhóm component (Routing, Data Transformation, Database Connection, Network, Message Broker, Scheduling, bảo mật), vùng thiết kế có kết nối giữa các component, thanh Properties, tab Source đồng bộ hai chiều, data mapping có nhập tài liệu mẫu, lưu nháp ở bảng `draft_session`, tải XML, cập nhật `pom.xml`, nhập component từ JAR.

Các hạn chế của hệ cũ mà PH-04 phải khắc phục:

| Hạn chế | Hệ quả | Cách PH-04 khắc phục |
|---|---|---|
| Agent gắn máy chủ cố định, sửa host/port trực tiếp | Không mở rộng theo tải, sự cố một máy ảnh hưởng mọi route trên đó | Runtime trên K8s, nhiều bản sao, KEDA; cấu hình qua phiên bản luồng |
| Điều khiển qua JMX/Jolokia phơi ra mạng | Bề mặt tấn công lớn, không kiểm toán được người ra lệnh | Không mở JMX; điều khiển qua GitOps và kênh lệnh có ký (ADR-065) |
| Lưu XML trong CSDL, không phiên bản | Không biết ai sửa gì, không quay lui được | Phiên bản bất biến, Git làm nguồn triển khai, so sánh khác biệt |
| Người dùng sửa `pom.xml`, nạp JAR | Rủi ro chuỗi cung ứng, vi phạm kiểm soát phần mềm cấp độ 3 | Danh mục thành phần được duyệt, ảnh runtime dựng sẵn |
| Không duyệt trước khi chạy | Một người có thể đưa thay đổi lỗi vào vận hành | Duyệt bốn mắt, kiểm tra hợp lệ bắt buộc |
| Mật khẩu CSDL, FTP nằm trong XML | Lộ bí mật qua mã nguồn và bản sao lưu | Tham chiếu kết nối PH-05, bí mật trong OpenBao |
| Không có chạy thử | Lỗi phát hiện khi đã vào vận hành | Chạy thử trên sandbox với đích mô phỏng |

: Hạn chế của Bus và Tooling cũ và cách PH-04 khắc phục

Ngoài phủ chức năng cũ, PH-04 phải đáp ứng các yêu cầu mới của chủ đầu tư (Q2, Q5, Q9, Q12 ở D00-02): đa tenant; ATTT cấp độ 3 sẵn sàng cấp độ 4; giữ Camel Quarkus cho data plane; chạy song song với Bus cũ trong thời gian chuyển đổi. Người dùng còn yêu cầu trình thiết kế luồng có trải nghiệm hiện đại tương đương Kaoto, theo phong cách Liquid Glass trên antd v6 (Q8).

### 2.2. Mục tiêu của phân hệ

PH-04 có năm mục tiêu đo được. Thứ nhất, **không có thay đổi nào vào vận hành mà chưa qua hai người**: 100% phiên bản chạy ở PROD có lần chạy thử đạt trên đúng băm nội dung và một người duyệt khác người tạo, người đóng góp, người gửi (BR-04-004, BR-04-005; đo bằng truy vấn kiểm toán, AC-04-03). Thứ hai, **phát hành nhanh và kiểm soát được**: từ lúc duyệt PROD tới khi luồng đồng bộ xong p95 dưới 3 phút (NFR-04-009), và tạm dừng khẩn có hiệu lực trên mọi bản sao dưới 5 giây (NFR-04-010, AC-04-10). Thứ ba, **chi phí xử lý thấp trên đường trao đổi**: khung chín chặng thêm không quá 15 ms p95 với bản tin JSON 10 KiB (NFR-04-011) và một vCPU native đạt ít nhất 400 bản tin/giây (NFR-04-012). Thứ tư, **trình thiết kế dùng được với luồng lớn**: mở luồng 200 chặng dưới 2 giây, kéo chặng ít nhất 50 khung hình/giây (NFR-04-003, 004) và quay vòng YAML không mất dữ liệu trên 100% luồng mẫu và luồng di trú (AC-04-05). Thứ năm, **di trú Bus cũ phần lớn tự động**: ít nhất 90% luồng của tỉnh thí điểm chuyển tự động với không quá 2 chặng cần xử lý tay mỗi luồng, kết quả chạy song song khớp từ 99,9% lượt (AC-04-09).

### 2.3. Vị trí trong kiến trúc

PH-04 có mặt ở cả hai mặt phẳng của Datahub. Hình dưới cho thấy đơn vị triển khai, vùng mạng và các phân hệ mà PH-04 trao đổi.

```{.mermaid caption="Vị trí của PH-04 trong kiến trúc Datahub"}
flowchart TB
  subgraph Z3["Vùng Z3 · mặt phẳng điều khiển"]
    CON["dh-console<br/>trình thiết kế, UI-04-*"] --> INT["dh-integration · module flow<br/>/api/integration/v1"]
    INT --> PG[("pg-core<br/>schema ph04")]
  end
  subgraph Z4["Vùng Z4 · mặt phẳng dữ liệu"]
    SB["dh-runtime-sandbox<br/>chạy thử"]
    RT["dh-runtime<br/>dh-runtime hoặc dh-rt-{tenant}"]
  end
  INT -->|"chạy thử"| SB
  INT -->|"commit ký"| GIT[("Kho cấu hình<br/>dh-flows-{tenant}")]
  GIT --> ARGO["Argo CD"] --> RT
  INT -->|"lệnh có ký, outbox"| K[("Kafka")]
  K --> RT
  RT -->|"nhịp tim, xác nhận, DLQ"| K
  APISIX["APISIX nội bộ<br/>PH-03"] -->|"lượt gọi đồng bộ"| RT
  RT --> HT["HTTT thành viên<br/>qua kết nối PH-05"]
  RT --> OB[("OpenBao<br/>bí mật kết nối")]
  INT -.-> PH05["PH-05 kết nối,<br/>Kamelet"]
  RT -.-> PH07["PH-07 chuyển mã,<br/>PH-09 chính sách che"]
  RT -.-> PH13["PH-13 vết, chỉ số,<br/>nhật ký kết nối"]
```

Ở mặt phẳng điều khiển (vùng Z3), `dh-console` là giao diện của trình thiết kế, còn `dh-integration` (module `flow`) giữ luồng, phiên bản, kết quả kiểm tra, duyệt và triển khai trong schema `ph04` của `pg-core`. `dh-integration` không nạp định nghĩa trực tiếp vào runtime: nó ghi commit có ký vào kho cấu hình theo tenant, Argo CD đồng bộ xuống `dh-runtime`. Ở mặt phẳng dữ liệu (vùng Z4), `dh-runtime` nhận lượt gọi đồng bộ từ APISIX nội bộ và bản tin Kafka, gọi HTTT qua kết nối PH-05 với bí mật đọc từ OpenBao, phát nhịp tim, xác nhận lệnh và bản tin lỗi lên Kafka. `dh-runtime-sandbox` cùng vùng Z4 nhưng cô lập, chỉ chạy định nghĩa chưa phát hành với đích mô phỏng.

### 2.4. Kiến trúc thành phần và công nghệ

PH-04 được hiện thực ở ba đơn vị triển khai (DU) và một phần giao diện, theo D03-02-PH04 §2.1.

| DU | Vai trò | Công nghệ | Namespace, vùng |
|---|---|---|---|
| `dh-integration` (module `flow`) | Control plane: luồng, phiên bản, kiểm tra hợp lệ, duyệt, phát hành, lệnh điều khiển, catalog, khuôn mẫu | Spring Boot 4, Modulith, Java 21 | `dh-control`, Z3 |
| `dh-runtime` | Data plane: chạy luồng đã phát hành, khung chín chặng, nhịp tim, nhận lệnh | Camel Quarkus 3.33.x native (hồ sơ JVM khi cần), Camel 4.18 LTS | `dh-runtime` hoặc `dh-rt-{tenant}`, Z4 |
| `dh-runtime-sandbox` | Chạy thử định nghĩa chưa phát hành bằng Camel thật | Camel Quarkus JVM cùng phiên bản | `dh-sandbox`, Z4 |
| `dh-console` (phần `features/integration`) | Trình thiết kế, các màn UI-04 | React 19, antd v6, `@xyflow/react` | `dh-control`, Z3 |

: Đơn vị triển khai của PH-04

Bên trong `dh-integration`, các thành phần chính là `FlowService` và `VersionService` (luồng, phiên bản), `ValidationEngine` (VR-01…20), `TestRunService` (gửi việc sang sandbox), `ReleaseService` (ghi kho cấu hình), `CommandService` (lệnh ký Ed25519), `Reconciler` (đối soát nhịp tim, xác nhận) và `CatalogService` (chính sách thành phần, khuôn mẫu). `dh-runtime` dùng thư viện nền `dh-runtime-lib` (`TenantGuard`, `OpaClient`, `MaskingProcessor`, `ErrorClassifier`, `TenantScopedSqlProcessor`, `CommandListener`, `HeartbeatPublisher`), bộ Kamelet nền `dh-*-action` và `FlowLoader` nạp YAML lúc chạy.

Hình dưới là trình tự luồng chính của phân hệ, từ lúc kỹ sư tích hợp lưu một phiên bản tới khi luồng chạy ở PROD.

```{.mermaid caption="Trình tự luồng chính từ thiết kế tới chạy ở PROD"}
sequenceDiagram
  autonumber
  actor IE as Kỹ sư tích hợp
  actor IA as Người duyệt
  participant C as dh-console
  participant I as dh-integration
  participant S as dh-runtime-sandbox
  participant G as Kho cấu hình Git
  participant A as Argo CD
  participant R as dh-runtime PROD
  IE->>C: Thiết kế, lưu nháp
  C->>I: Lưu định nghĩa (API-04-022), kiểm tra DESIGN
  IE->>I: Chạy thử (API-04-040)
  I->>S: Nạp YAML, đích mô phỏng
  S-->>I: PASSED trên contentHash
  IE->>I: Gửi duyệt (API-04-050), kiểm tra SUBMIT
  IA->>I: Xem so sánh, duyệt (API-04-052)
  I->>I: Kiểm tra bốn mắt, kiểm tra PUBLISH
  I->>G: Commit ký flow({code}) v{n} → prod
  A->>G: Nhận commit
  A->>R: Áp ConfigMap, FlowDeployment
  R->>R: FlowLoader nạp route
  R-->>I: Nhịp tim EVT-04-12 đúng băm
  I-->>IE: Triển khai SYNCED, luồng ACTIVE
```

Điểm cần thấy ở hình là không có mũi tên nào từ `dh-integration` vào thẳng `dh-runtime` PROD: định nghĩa chỉ đi qua kho cấu hình Git và Argo CD (BR-04-012), còn trạng thái thật được xác nhận bằng nhịp tim của runtime so với băm nội dung đã duyệt. Lệnh tạm dừng là ngoại lệ có kiểm soát: đi qua topic điều khiển có ký rồi được đối soát vào Git (FR-04-050).

### 2.5. Quy trình nghiệp vụ liên quan

PH-04 tham gia các quy trình nghiệp vụ dưới đây của Datahub.

| Quy trình | Bước có PH-04 |
|---|---|
| Kết nạp HTTT (PH-01) → tích hợp | Sau khi HTTT `ACTIVE` và kết nối PH-05 được bật, kỹ sư tạo luồng đối ngoại tham chiếu HTTT nguồn, đích |
| Công bố dịch vụ (PH-02) | Luồng có điểm vào HTTP được công bố làm backend; luồng có thể sinh từ OpenAPI của PH-02 (FR-04-003) |
| Thiết kế, phát hành luồng | Tạo, thiết kế, chạy thử, gửi duyệt, duyệt bốn mắt, phát hành TEST rồi PROD (nhóm B, C, D) |
| Vận hành | Theo dõi tình trạng, tạm dừng, tiếp tục, quay lui; xử lý bản tin lỗi ở PH-18 (nhóm D, E) |
| Di trú từ Bus cũ (strangler) | Chuyển XML sang YAML, gán kết nối PH-05, chạy song song, đối chiếu, chuyển lưu lượng (FR-04-082) |
| Sự cố ATTT | SO tạm dừng khẩn luồng, xem lịch sử thao tác, kiểm toán truy cập CSDL (FR-04-050, 072, 083) |

: Quy trình nghiệp vụ có PH-04 tham gia

Hình dưới tóm tắt vòng đời điển hình của một luồng từ lúc tạo tới khi chạy ở PROD và được vận hành.

```{.mermaid caption="Vòng đời điển hình của một luồng"}
flowchart TB
  A["Tạo luồng từ khuôn mẫu,<br/>API, YAML, XML cũ<br/>FR-04-003, 082"] --> B["Thiết kế trên sơ đồ,<br/>YAML hai chiều<br/>FR-04-010…027"]
  B --> C["Chạy thử sandbox<br/>FR-04-030, 031"]
  C -->|"Không đạt"| B
  C -->|"Đạt"| D["Gửi duyệt<br/>FR-04-040"]
  D --> E["Duyệt bốn mắt<br/>FR-04-041"]
  E -->|"Yêu cầu sửa"| B
  E -->|"Duyệt"| F["Phát hành TEST, PROD<br/>qua GitOps FR-04-042, 045"]
  F --> G["Vận hành: tạm dừng,<br/>tiếp tục, quay lui<br/>FR-04-044, 050"]
  G --> H["Phiên bản mới<br/>FR-04-011"]
  H --> B
```

Vòng lặp chính là thiết kế, chạy thử, duyệt: phiên bản không qua được chạy thử hoặc bị yêu cầu sửa quay lại thiết kế, không có đường tắt tới phát hành. Mỗi thay đổi sau khi chạy ở PROD bắt đầu bằng một phiên bản mới, nên phiên bản đang chạy luôn bất biến.

### 2.6. Chức năng hệ cũ được phủ

Bảng dưới tóm tắt cách PH-04 phủ các nhóm chức năng của Bus và Tooling; kết luận từng mục ở mục 11.1.

| Mã | Nhóm chức năng hệ cũ | Vai trò của PH-04 |
|---|---|---|
| LGC-BUS-001…006 | Danh sách, tìm kiếm, metadata chương trình tích hợp | Chính (FR-04-001, 002, 004) |
| LGC-BUS-007, 014…016, 019, 027…030 | Biểu đồ, số liệu, log, JMX | Thay thế bằng PH-13, nhúng ở FR-04-051…053 |
| LGC-BUS-008…013, 017…026 | Route, endpoint, thuộc tính, sơ đồ, mã nguồn, start/stop, xóa, thêm chương trình | Chính (FR-04-002, 003, 006, 033, 043, 050) |
| LGC-BUS-031…034 | Cấu hình hệ thống, project, group, lưu context XML, dependency | Chính hoặc thay thế (FR-04-007, 042, 075, 080, 082, 084) |
| LGC-BUS-035…041 | EIP định tuyến, chuyển đổi, xử lý lỗi, logging, bản tin, connector, bảo mật | Chính ở data plane (nhóm F), cùng PH-05, PH-07, PH-09, PH-13 |
| LGC-TOOL-001…021, 023…026, 028, 029 | Trình thiết kế kéo thả, thanh Component, Properties, Source, data mapping, lưu nháp | Chính (nhóm B) |
| LGC-TOOL-022, 027 | Cập nhật `pom.xml`, nhập component từ JAR | Loại bỏ vì ATTT; thay bằng danh mục thành phần và Kamelet (FR-04-018, 080) |

: Chức năng hệ cũ do PH-04 phủ

### 2.7. Hiện trạng mã nguồn và chỗ lệch so với thiết kế

Mã trong repo (tháng 11/2026) đã có một phần lớn PH-04. Bảng dưới ghi các điểm lệch giữa mã và thiết kế của bộ tài liệu này, để kế hoạch phát triển có đầu việc rõ ràng. Mỗi điểm lệch có FR hoặc ADR quyết định cách xử lý.

| Mã lệch | Hiện trạng trong mã | Thiết kế đích | Xử lý | Căn cứ |
|---|---|---|---|---|
| GAP-04-01 | Runtime Camel Quarkus 3.33.2 (Camel 4.18 LTS) ở `camel/dancu`, `camel/datdai`; catalog của trình thiết kế trước đây sinh từ `@kaoto/camel-catalog` 0.7.0 cho camel-quarkus **3.35.0**. Ngày 25/11/2026 đã có thay đổi hạ catalog về dòng 3.33 (PR #5): Kaoto không phát hành nhánh 3.33.2 nên dùng 3.33.1 (Camel 4.18.2), phiên bản đọc từ `camel/*/pom.xml`, `npm run catalog:check` chặn lệch | Catalog khớp phiên bản runtime; lệch bản vá (3.33.1 so với 3.33.2) chấp nhận được khi danh sách thành phần và lược đồ không đổi | Giữ cơ chế của PR #5; bổ sung so khớp theo tệp kê khai hồ sơ runtime và kiểm tra khác biệt lược đồ giữa hai bản vá | FR-04-081, ADR-061 |
| GAP-04-02 | Luồng nghiệp vụ `TraCuuRoute`, `StandardPipelineRoute`, `CdmMapRoute` viết bằng Java DSL; chỉ `ping` là YAML | Luồng nghiệp vụ viết bằng YAML DSL (ADR-010) | Chuyển ba luồng sang YAML; Java chỉ còn cho processor và bean nền được duyệt | ADR-062, FR-04-060 |
| GAP-04-03 | `GitOpsPublisher` ghi tệp `routes/<mã>/route.camel.yaml` trong cùng repo, commit tùy chọn; chưa có kho cấu hình riêng, chưa có Argo CD; runtime không nạp được luồng đã phát hành | Kho cấu hình Git riêng theo tenant và môi trường, Argo CD đồng bộ xuống runtime, runtime nạp YAML lúc chạy | Thiết kế mới ở SDD §5; luồng phát hành báo tình trạng triển khai | FR-04-042, ADR-063 |
| GAP-04-04 | `testRun` mô phỏng: dựng waterfall chín chặng từ `stage.hashCode()`, luôn trả `PASSED`, không nạp Camel | Chạy Camel thật trong sandbox cô lập, đích mô phỏng | Bộ chạy thử `dh-runtime-sandbox` | FR-04-030, ADR-064 |
| GAP-04-05 | `publish()` nhận phiên bản ở trạng thái `DRAFT` và phát hành thẳng, bỏ qua duyệt | Chỉ phát hành phiên bản `APPROVED`; duyệt bốn mắt bắt buộc | Siết máy trạng thái ở máy chủ | FR-04-041, BR-04-005 |
| GAP-04-06 | Bốn mắt so `actor` với `created_by` của phiên bản; chưa so với người gửi duyệt, người sửa gần nhất | Người duyệt khác người tạo, người sửa và người gửi duyệt | Lưu danh sách người đóng góp vào phiên bản | BR-04-005 |
| GAP-04-07 | Bảng `ph04.route` chưa có `tenant_id`, chưa có RLS | Mọi bảng có `tenant_id`, RLS theo D03-10 | DDL mới ở D03-03-PH04 | ADR-003 |
| GAP-04-08 | Khung chín chặng kiểm tra bằng tìm chuỗi con trong YAML (`lower.contains(stage)`) | Kiểm tra theo metadata chặng trên cây tài nguyên | Đánh dấu chặng bằng `id` có tiền tố chuẩn và `description` | FR-04-023, BR-04-002 |
| GAP-04-09 | DataMapper xem trước bằng mô phỏng JQ trong trình duyệt; engine máy chủ `camel-quarkus-jq` chưa có | Xem trước chạy JQ thật ở máy chủ | Gọi API xem trước của sandbox; giữ xem trước cục bộ có nhãn "mô phỏng" khi máy chủ không sẵn | FR-04-020 |
| GAP-04-10 | `camel/dancu` dùng `camel-quarkus-sql` với datasource dùng chung tài khoản `lgsp` | Q359: tài khoản chỉ đọc theo luồng, khai báo ở PH-05, kiểm toán, RLS theo tenant | Thiết kế ở FR-04-072, ADR-067 | Q359 |
| GAP-04-11 | Tạm dừng luồng chỉ đổi cột `status` trong CSDL control; runtime không biết | Tạm dừng thật trên runtime, có xác nhận | Kênh lệnh có ký và trạng thái mong muốn trong Git | FR-04-050, ADR-065 |
| GAP-04-12 | Không có `errorHandler` chuẩn ở luồng mẫu | Mọi luồng có DLQ chuẩn sang PH-18 | Khuôn `routeConfiguration` nền, kiểm tra bắt buộc | FR-04-070 |
| GAP-04-13 | Đường dẫn giao diện `/flows/...`, tên gói `vn.lgsp` | Đường dẫn `/tich-hop/luong/...` theo D03-06-00; gói `vn.datahub` theo Q350 | Đổi khi tái cấu trúc, giữ chuyển hướng từ đường dẫn cũ một đợt | D03-06-00 §2.4 |

: Điểm lệch giữa mã hiện có và thiết kế PH-04

### 2.8. Đa tenant trong PH-04

Mỗi luồng thuộc đúng một tenant. Tenant `PLATFORM` sở hữu các khuôn mẫu, Kamelet nền và luồng dùng chung toàn quốc (ví dụ luồng kết nối NDXP mẫu), các tenant tỉnh dùng lại bằng cách tạo luồng từ khuôn hoặc tham chiếu Kamelet. Luồng chạy trong namespace dùng chung `dh-runtime` có nhãn tenant, hoặc trong namespace riêng `dh-rt-{tenant}` khi tenant có trên 50 luồng hoặc có yêu cầu riêng (D03-10 §3, D03-09 §5). Mọi bản tin trong runtime mang tiêu đề `dh-tenant` được đặt ở chặng tiếp nhận từ token hoặc từ topic, không lấy từ dữ liệu do bên gọi gửi (BR-04-010). Ví dụ trong tài liệu dùng tenant `T68`, topic chữ thường tiền tố `t68.`.

## 3. Tác nhân, vai trò và quyền

### 3.1. Tác nhân

PH-04 có tác nhân người (thiết kế, duyệt, vận hành, kiểm soát) và tác nhân máy (HTTT gọi luồng, Argo CD, runtime, phân hệ khác).

| Tác nhân | Mã vai trò | Loại | Việc chính với PH-04 |
|---|---|---|---|
| Kỹ sư tích hợp | IE (INTEGRATION_ENGINEER) | Người | Thiết kế, chạy thử, gửi duyệt luồng; xem tình trạng |
| Người duyệt tích hợp | IA (INTEGRATION_APPROVER) | Người | Duyệt hoặc từ chối phiên bản, phát hành, quay lui |
| Vận hành tenant | TO (TENANT_OPERATOR) | Người | Kích hoạt, tạm dừng luồng và route; xem tình trạng |
| Quản trị tenant | TA (TENANT_ADMIN) | Người | Quản lý không gian làm việc, thành viên, tham số PH-04; vận hành |
| Cán bộ an toàn thông tin | SO (SECURITY_OFFICER) | Người | Tạm dừng khẩn cấp; xem nhật ký kiểm toán; duyệt danh mục thành phần |
| Quản trị nền tảng | PA (PLATFORM_ADMIN) | Người | Khuôn mẫu, Kamelet nền, luồng toàn quốc, danh mục thành phần, hồ sơ runtime |
| Người xem, kiểm toán | VW, AU | Người | Xem luồng, lịch sử, nhật ký |
| HTTT thành viên | (máy) | Hệ thống | Gọi điểm vào HTTP của luồng qua APISIX; gửi, nhận bản tin Kafka |
| Argo CD | (máy) | Hệ thống | Đồng bộ kho cấu hình xuống runtime; báo tình trạng |
| `dh-runtime` | (máy) | Hệ thống | Chạy luồng, báo nhịp tim, nhận lệnh điều khiển |
| PH-05, PH-07, PH-09, PH-10, PH-13, PH-18 | (máy) | Hệ thống | Cung cấp kết nối, chuyển mã, chính sách che, topic, giám sát, xử lý bản tin lỗi |

: Tác nhân của PH-04

### 3.2. Ma trận quyền

Quyền PH-04 theo D02-08 §3.1 như bảng thứ nhất; bảng thứ hai trình bày cùng nội dung dưới dạng ma trận quyền × vai trò (● có quyền, — không có).

| Quyền | Mô tả | Vai trò có quyền theo D02-08 §3.1 |
|---|---|---|
| `PERM-04-read` | Xem luồng, phiên bản, sơ đồ, mã nguồn, tình trạng | PA, PO, TA, TO, SO, IE, IA, VW, AU |
| `PERM-04-create`, `PERM-04-update` | Tạo, thiết kế luồng, chạy thử | IE |
| `PERM-04-submit` | Gửi duyệt phiên bản | IE |
| `PERM-04-publish` | Duyệt, từ chối, phát hành, quay lui | IA |
| `PERM-04-operate` | Kích hoạt, tạm dừng luồng và route | TA, TO, SO, IA |

: Quyền PH-04 theo D02-08

| Quyền | PA | PO | TA | TO | SO | IE | IA | VW | AU |
|---|---|---|---|---|---|---|---|---|---|
| `PERM-04-read` | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| `PERM-04-create`, `PERM-04-update` | — | — | — | — | — | ● | — | — | — |
| `PERM-04-submit` | — | — | — | — | — | ● | — | — | — |
| `PERM-04-publish` | — | — | — | — | — | — | ● | — | — |
| `PERM-04-operate` | — | — | ● | ● | ● | — | ● | — | — |
| `PERM-04-delete` (đề xuất) | — | — | ● | — | — | ● (nháp của mình) | — | — | — |
| `PERM-04-emergency-stop` (đề xuất) | — | — | ● | — | ● | — | — | — | — |
| `PERM-04-promote` (đề xuất) | — | — | ● | — | — | — | ● | — | — |
| `PERM-04-admin` (đề xuất) | ● | — | ● | — | — | — | — | — | — |
| `PERM-04-catalog-admin` (đề xuất) | ● | — | — | — | ● (duyệt) | — | — | — | — |
| `PERM-04-sample-data` (đề xuất) | — | — | — | — | — | ● (được TA cấp theo luồng) | — | — | — |

: Ma trận quyền × vai trò của PH-04

### 3.3. Quyền đề xuất bổ sung D02-08

D02-08 chưa có các quyền dưới đây. FRS đề xuất bổ sung (ghi ở Phụ lục B); cho tới khi D02-08 được cập nhật, mã nguồn kiểm tra mã quyền mới nhưng cấu hình vai trò mặc định theo cột "Gán mặc định đề xuất".

| Quyền đề xuất | Mô tả | Gán mặc định đề xuất | Lý do |
|---|---|---|---|
| `PERM-04-delete` | Gỡ bỏ luồng, xóa bản nháp | IE (bản nháp của mình), TA | Gỡ luồng đang chạy là thao tác có hậu quả, tách khỏi `update` |
| `PERM-04-emergency-stop` | Tạm dừng khẩn cấp bỏ qua GitOps | SO, TA | Lệnh khẩn có tác động ngay trên runtime, cần quyền riêng để kiểm toán |
| `PERM-04-promote` | Thăng cấp phiên bản đã duyệt lên môi trường cao hơn | IA, TA | Tách phê duyệt nội dung với phê duyệt đưa vào vận hành thật |
| `PERM-04-admin` | Quản lý không gian làm việc, thành viên, tham số PH-04 | TA, PA | Theo động từ chuẩn `admin` của D02-08 §3 |
| `PERM-04-catalog-admin` | Quản lý danh mục thành phần được phép, khuôn mẫu, hồ sơ runtime | PA, SO (duyệt) | Danh mục thành phần quyết định mã nào được chạy |
| `PERM-04-sample-data` | Dùng dữ liệu thật làm bản tin mẫu khi chạy thử trên môi trường TEST | IE (được TA cấp theo luồng) | Bản tin thật có thể chứa dữ liệu cá nhân |

: Quyền PH-04 đề xuất bổ sung vào D02-08

### 3.4. Phạm vi không gian làm việc

Quyền ở mục 3.2 áp trong phạm vi tenant. PH-04 bổ sung một phạm vi hẹp hơn là **không gian làm việc** (workspace), kế thừa khái niệm `Project` và `Project_group.access_level` của Bus cũ (LGC-BUS-032). Mỗi luồng thuộc đúng một không gian làm việc; mỗi không gian làm việc có danh sách thành viên với mức truy cập `VIEW`, `EDIT`, `MAINTAIN`. Người có `PERM-04-update` chỉ sửa được luồng trong không gian làm việc mà mình có mức `EDIT` trở lên. Người có `PERM-04-publish` chỉ duyệt được luồng trong không gian làm việc mà mình là thành viên mức `MAINTAIN`. TA và PA không bị giới hạn bởi không gian làm việc. Mục đích là để sở A không vô tình sửa luồng của sở B trong cùng tỉnh, như cách hệ cũ phân quyền project theo group.

### 3.5. Tách nhiệm vụ và tài khoản máy

IE và IA là cặp loại trừ ở D02-08 §4: một người không được giữ cả hai vai trò trong cùng tenant. Ngoài ra nguyên tắc bốn mắt (FR-00-071) áp cho từng phiên bản: người tạo, người có tên trong danh sách người đóng góp và người gửi duyệt không được duyệt phiên bản đó (BR-04-005), chốt ở máy chủ. Quyền `PERM-04-emergency-stop` của SO chỉ dùng khi luồng gây sự cố ATTT hoặc làm quá tải hệ đích; mọi lệnh khẩn có lý do và được đối soát vào Git (BR-04-018).

Tác nhân máy không dùng tài khoản người. `dh-integration` ký commit vào kho cấu hình và ký lệnh điều khiển bằng khóa dịch vụ lấy từ OpenBao (Ed25519); Argo CD chỉ có quyền đọc kho cấu hình và áp tài nguyên vào namespace runtime; `dh-runtime` đọc bí mật kết nối bằng danh tính Kubernetes của pod và chỉ nhận lưu lượng đồng bộ từ APISIX nội bộ. Không có tài khoản nào có quyền nạp định nghĩa trực tiếp vào runtime PROD ngoài đường kho cấu hình (BR-04-012).

## 4. Khái niệm và mô hình nghiệp vụ

Chương này định nghĩa các khái niệm và thực thể mức logic của PH-04 và vòng đời của luồng, phiên bản, triển khai, lần chạy thử, lệnh điều khiển. Bảng thực thể đầy đủ và DDL ở D03-03-PH04.

### 4.1. Tổng quan mô hình

```{.mermaid caption="Mô hình khái niệm của PH-04"}
classDiagram
    class Workspace {
      code
      name
      ownerOrgId
    }
    class WorkspaceMember {
      userId
      accessLevel
    }
    class Flow {
      code
      name
      resourceKind
      transport
      status
      sourceSystem
      targetSystems
      exposure
    }
    class FlowVersion {
      versionNo
      status
      definitionYaml
      canvasLayout
      changeNote
      contentHash
    }
    class Deployment {
      environment
      desiredState
      syncStatus
      healthStatus
      gitCommit
    }
    class TestRun {
      mode
      outcome
      durationMs
      traceId
    }
    class TestCase {
      name
      inputRef
      assertions
    }
    class Review {
      decision
      comment
      reviewer
    }
    class RuntimeCommand {
      action
      scope
      reason
      ackStatus
    }
    class Template {
      code
      category
    }
    class ComponentPolicy {
      componentName
      allowed
      nativeSupport
    }
    Workspace "1" --> "*" Flow
    Workspace "1" --> "*" WorkspaceMember
    Flow "1" --> "*" FlowVersion
    FlowVersion "1" --> "*" TestRun
    FlowVersion "1" --> "*" Review
    FlowVersion "1" --> "*" Deployment
    Flow "1" --> "*" TestCase
    Flow "1" --> "*" RuntimeCommand
    Template ..> FlowVersion : khởi tạo
    ComponentPolicy ..> FlowVersion : kiểm tra
```

Trung tâm của mô hình là cặp luồng và phiên bản: luồng mang danh tính ổn định (mã, không gian làm việc, HTTT liên quan), phiên bản mang nội dung bất biến sau khi gửi duyệt. Lần chạy thử, ý kiến duyệt và triển khai đều gắn vào một phiên bản cụ thể, nên bằng chứng duyệt và trạng thái chạy luôn truy về đúng nội dung. Khuôn mẫu chỉ dùng lúc khởi tạo, chính sách thành phần chỉ dùng lúc kiểm tra.

Các thực thể mức logic được dùng trong tài liệu:

| Mã | Thực thể | Dùng ở |
|---|---|---|
| EN-04-01 | Không gian làm việc | FR-04-007; thay `Project` của Bus |
| EN-04-02 | Luồng tích hợp | FR-04-001…006 |
| EN-04-03 | Phiên bản luồng | FR-04-010, 011, 024 |
| EN-04-04 | Chỉ mục route, điểm kết nối, tham chiếu ra ngoài tính khi lưu (04a, 04b, 04c ở D03-03) | FR-04-001, 002, 006 |
| EN-04-05 | Nhật ký gửi, rút, duyệt, yêu cầu sửa | FR-04-040, 041 |
| EN-04-06 | Triển khai phiên bản lên môi trường | FR-04-042, 044, 045 |
| EN-04-07 | Lần chạy thử | FR-04-030, 032 |
| EN-04-08 | Vết từng chặng của lần chạy thử | FR-04-030, 033 |
| EN-04-09 | Phiên soạn thảo | FR-04-010 |
| EN-04-10 | Lệnh điều khiển runtime có ký | FR-04-050 |
| EN-04-11 | Chính sách thành phần | FR-04-080 |
| EN-04-12…24 | Thành viên, người đóng góp, ánh xạ, ca kiểm thử, xác nhận lệnh, nhịp tim, đề xuất thành phần, khuôn mẫu, nhóm bảng thành phần, khác biệt catalog, bản sao HTTT, lượt chuyển XML, outbox | Xem D03-03-PH04 |

: Thực thể mức logic của PH-04

### 4.2. Không gian làm việc

Không gian làm việc (EN-04-01) là nhóm luồng của một đơn vị hoặc một dự án tích hợp, có mã duy nhất trong tenant, tên, tổ chức chủ quản và danh sách thành viên. Mỗi tenant có sẵn một không gian làm việc mặc định `DEFAULT` khi khởi tạo. Không gian làm việc tương ứng `Project` của Bus cũ và được di trú từ đó.

### 4.3. Luồng và loại tài nguyên

Luồng (EN-04-02) có mã duy nhất trong tenant, mẫu `^[a-z][a-z0-9-]{2,62}$`, không đổi được sau khi tạo vì là khóa của tệp trong kho cấu hình. Loại tài nguyên `resourceKind` gồm:

| Loại | Nội dung tệp | Chạy độc lập | Ví dụ |
|---|---|---|---|
| `ROUTE` | Một hoặc nhiều `route`, kèm `routeConfiguration`, `rest`, `beans` cấp tệp | Có | Luồng tra cứu hộ tịch |
| `KAMELET` | Một `Kamelet` (`spec.definition`, `spec.template`) | Không, được luồng khác dùng | Kamelet nguồn đọc bảng hồ sơ |
| `PIPE` | Một `Pipe` nối `source`, `steps`, `sink` | Có | Đẩy thay đổi CSDL sang Kafka |
| `TEST` | Một bộ ca kiểm thử gắn với một luồng `ROUTE` hoặc `PIPE` | Không, chỉ chạy khi kiểm thử | Bộ ca của luồng tra cứu |

: Loại tài nguyên của luồng

Thuộc tính vận chuyển `transport` (`SYNC`, `ASYNC`, `SCHEDULED`, `MIXED`) mô tả cách luồng được kích hoạt; được suy ra từ chặng đầu và người dùng không sửa tay. Thuộc tính `exposure` cho biết luồng **đối ngoại** (có `sourceSystem` hoặc `targetSystems` là HTTT thành viên đã kết nạp) hay **nội bộ**. Luồng đối ngoại phải theo khung chín chặng (BR-04-002).

### 4.4. Phiên bản

Mỗi luồng có dãy phiên bản `versionNo` tăng dần từ 1. Mỗi phiên bản (EN-04-03) chứa định nghĩa YAML, bố cục sơ đồ (vị trí chặng, ghi chú dán, nhóm), ghi chú thay đổi, băm SHA-256 của YAML đã chuẩn hóa, danh sách người đóng góp, kết quả kiểm tra hợp lệ gần nhất. Tại mọi thời điểm một luồng có tối đa một phiên bản mở (`DRAFT` hoặc `CHANGES_REQUESTED`). Phiên bản đã gửi duyệt là bất biến về nội dung: mọi sửa đổi phải làm trên phiên bản mới.

Bố cục sơ đồ không nằm trong YAML đem triển khai. Repo hiện nhúng bố cục vào dòng chú thích `# @lgsp-canvas-v1:` và lọc bỏ khi phát hành; thiết kế đích lưu bố cục ở cột riêng (`canvas_layout`) để YAML trong kho cấu hình sạch, còn tệp tải xuống vẫn có thể kèm bố cục để mở lại trên trình thiết kế khác của Datahub (FR-04-027).

### 4.5. Môi trường và triển khai

Datahub có ba môi trường luồng: `TEST` (sandbox và môi trường thử tích hợp), `STAGING` (tiền vận hành, tùy tỉnh) và `PROD`. Một phiên bản đã duyệt được triển khai lần lượt theo thứ tự môi trường; mỗi lần triển khai (EN-04-06) ghi môi trường, trạng thái mong muốn (`RUNNING`, `PAUSED`, `REMOVED`), commit Git, trạng thái đồng bộ Argo CD (`PENDING`, `SYNCED`, `OUT_OF_SYNC`, `FAILED`) và sức khỏe báo về từ runtime (`HEALTHY`, `DEGRADED`, `DOWN`, `UNKNOWN`). Tỉnh không có STAGING thì bỏ qua môi trường này (tham số `04.env.stages`).

### 4.6. Chặng và khung chín chặng chuẩn

Khung chín chặng là khuôn mẫu chuẩn của mọi luồng đối ngoại, kế thừa từ repo (`routes/_templates/standard-9-stage.camel.yaml`):

| Thứ tự | Mã chặng | Tên | Việc phải làm | FR |
|---|---|---|---|---|
| 1 | `receive` | Tiếp nhận | Nhận bản tin, đặt `traceId`, `dh-tenant`, `dh-flow`, `dh-flow-version`, đo kích thước | FR-04-061, 062 |
| 2 | `schema` | Kiểm tra lược đồ | Kiểm tra JSON Schema, XSD hoặc lược đồ Apicurio | FR-04-063 |
| 3 | `authz` | Ủy quyền | Hỏi OPA theo ngữ cảnh bên gọi, mục đích, dữ liệu | FR-04-064 |
| 4 | `transform` | Chuyển đổi | Chuẩn hóa về CDM, chuyển mã, đổi định dạng | FR-04-065 |
| 5 | `enrich` | Làm giàu | Bổ sung dữ liệu từ nguồn khác | FR-04-066 |
| 6 | `route` | Định tuyến | Chọn đích theo nội dung, tách, gộp | FR-04-068 |
| 7 | `deliver` | Gửi đích | Gọi HTTT đích hoặc phát sự kiện | FR-04-068, 069 |
| 8 | `audit` | Ghi vết | Ghi nhật ký kết nối theo NĐ 278/2025 | FR-04-074 |
| 9 | `respond` | Phản hồi | Trả kết quả, che dữ liệu theo bên nhận | FR-04-067 |

: Khung chín chặng chuẩn

Mỗi chặng chuẩn được đánh dấu trên cây tài nguyên bằng `id` có tiền tố `dh-stage-{mã}` ở phần tử EIP đầu tiên của chặng (thường là một `step` bao các bước con). Cách đánh dấu này thay việc tìm chuỗi con trong YAML (GAP-04-08) và cho phép sơ đồ nhóm các bước con thành một khối chặng có thể thu gọn.

### 4.7. Danh mục thành phần và hồ sơ runtime

Danh mục thành phần (EN-04-11) là bản sao có kiểm soát của catalog Camel cho đúng phiên bản runtime: component, mẫu EIP, Kamelet, dataformat, language, entity, load balancer. Mỗi mục có cờ "được phép" theo chính sách của nền tảng và tenant, mức hỗ trợ native, giấy phép. "Hồ sơ runtime" (runtime profile) là tập thành phần được biên dịch vào một ảnh `dh-runtime` native; mỗi luồng khi phát hành được gán vào hồ sơ có đủ thành phần nó dùng (ADR-063). Thành phần không hỗ trợ native chạy trong hồ sơ JVM riêng (ADR-002).

### 4.8. Kết nối và bí mật

Luồng không chứa bí mật. Mọi tham số nhạy cảm (mật khẩu, khóa API, chứng thư) được tham chiếu qua kết nối đã đăng ký ở PH-05, dạng `{{conn:<mã kết nối>.<khóa>}}`, hoặc qua tham chiếu kho bí mật `{{vault:<đường dẫn>#<khóa>}}` do nền tảng cấp. Runtime phân giải tham chiếu lúc khởi động route qua OpenBao (ADR-012). Trình kiểm tra hợp lệ chặn mọi chuỗi giống bí mật viết thẳng (BR-04-003).

### 4.9. Sơ đồ trạng thái luồng

Trạng thái luồng `Flow.status` là trạng thái tổng hợp để hiển thị và lọc, được tính từ phiên bản và triển khai.

```{.mermaid caption="Máy trạng thái của luồng"}
stateDiagram-v2
    [*] --> DRAFT : tạo luồng
    DRAFT --> IN_REVIEW : gửi duyệt phiên bản đầu
    IN_REVIEW --> DRAFT : từ chối
    IN_REVIEW --> APPROVED : duyệt
    APPROVED --> ACTIVE : triển khai PROD đồng bộ xong
    ACTIVE --> PAUSED : tạm dừng
    PAUSED --> ACTIVE : tiếp tục
    ACTIVE --> DEGRADED : runtime báo suy giảm
    DEGRADED --> ACTIVE : hồi phục
    ACTIVE --> RETIRED : gỡ bỏ
    PAUSED --> RETIRED : gỡ bỏ
    DRAFT --> [*] : xóa luồng chưa từng phát hành
    RETIRED --> [*]
```

Hình cho thấy luồng chỉ thành `ACTIVE` khi triển khai ở PROD đã đồng bộ, không phải khi được duyệt; trạng thái `DEGRADED` do runtime báo về chứ không do người đặt. Ý nghĩa từng trạng thái ở bảng dưới.

| Trạng thái | Nhãn hiển thị | Ý nghĩa |
|---|---|---|
| `DRAFT` | Nháp | Chưa có phiên bản nào được duyệt |
| `IN_REVIEW` | Chờ duyệt | Phiên bản đầu tiên đang chờ duyệt |
| `APPROVED` | Đã duyệt | Có phiên bản đã duyệt nhưng chưa chạy ở PROD |
| `ACTIVE` | Đang chạy | Có phiên bản chạy ở PROD với trạng thái mong muốn `RUNNING` |
| `PAUSED` | Tạm dừng | Trạng thái mong muốn ở PROD là `PAUSED` |
| `DEGRADED` | Suy giảm | Runtime báo `DEGRADED` hoặc `DOWN`, hoặc lệch đồng bộ quá ngưỡng |
| `RETIRED` | Đã gỡ | Đã gỡ khỏi mọi môi trường; chỉ xem lịch sử |

: Trạng thái của luồng

### 4.10. Sơ đồ trạng thái phiên bản

```{.mermaid caption="Máy trạng thái của phiên bản luồng"}
stateDiagram-v2
    [*] --> DRAFT : tạo phiên bản
    DRAFT --> PENDING_REVIEW : gửi duyệt (hợp lệ, có lần chạy thử đạt)
    PENDING_REVIEW --> DRAFT : người gửi rút lại
    PENDING_REVIEW --> CHANGES_REQUESTED : từ chối có lý do
    CHANGES_REQUESTED --> PENDING_REVIEW : gửi lại sau khi sửa
    PENDING_REVIEW --> APPROVED : duyệt bốn mắt
    APPROVED --> SUPERSEDED : phiên bản mới hơn chạy ở PROD
    APPROVED --> ROLLED_BACK : quay lui về phiên bản trước
    DRAFT --> DISCARDED : hủy nháp
    CHANGES_REQUESTED --> DISCARDED : hủy
    SUPERSEDED --> APPROVED : quay lui về phiên bản này
```

Phiên bản chỉ sửa được ở `DRAFT` và `CHANGES_REQUESTED`; từ `PENDING_REVIEW` trở đi nội dung bất biến. `SUPERSEDED` có thể quay lại `APPROVED` khi người duyệt quay lui về phiên bản này (FR-04-044).

Repo hiện có các trạng thái `DRAFT`, `TESTING`, `PENDING_REVIEW`, `APPROVED`. Trạng thái `TESTING` của repo được bỏ: việc đã chạy thử đạt là một điều kiện (BR-04-004), không phải trạng thái, vì người thiết kế có thể chạy thử nhiều lần xen kẽ với sửa.

### 4.11. Sơ đồ trạng thái triển khai

```{.mermaid caption="Máy trạng thái của triển khai"}
stateDiagram-v2
    [*] --> PENDING : ghi kho cấu hình
    PENDING --> SYNCING : Argo CD nhận commit
    SYNCING --> SYNCED : runtime nạp xong và báo nhịp tim đúng băm
    SYNCING --> FAILED : nạp lỗi hoặc quá hạn
    SYNCED --> OUT_OF_SYNC : runtime lệch băm hoặc thay đổi ngoài Git
    OUT_OF_SYNC --> SYNCED : tự sửa lệch
    FAILED --> PENDING : thử lại
    SYNCED --> [*] : bị thay bởi triển khai mới
```

Triển khai chỉ `SYNCED` khi nhịp tim của runtime báo đúng băm nội dung, không phải khi Argo CD báo áp xong; quá `04.deploy.timeout-minutes` thì `FAILED`. `OUT_OF_SYNC` phát hiện thay đổi ngoài Git và được tự sửa về trạng thái trong Git.

### 4.12. Sơ đồ trạng thái lần chạy thử

```{.mermaid caption="Máy trạng thái của lần chạy thử"}
stateDiagram-v2
    [*] --> QUEUED
    QUEUED --> RUNNING : sandbox nhận việc
    RUNNING --> PASSED : mọi khẳng định đạt
    RUNNING --> FAILED : lỗi chặng hoặc khẳng định sai
    RUNNING --> TIMED_OUT : quá thời gian tối đa
    QUEUED --> CANCELLED : người dùng hủy
    RUNNING --> CANCELLED : người dùng hủy
    QUEUED --> SIMULATED : sandbox không sẵn sàng, chạy mô phỏng có nhãn
```

Chỉ `PASSED` ở chế độ không mô phỏng được tính cho điều kiện gửi duyệt. `SIMULATED` chỉ dùng khi tham số `04.test.allow-simulation` bật (mặc định tắt ở PROD và STAGING của nền tảng, bật ở môi trường phát triển). Lần chạy mô phỏng không được tính là "chạy thử đạt" cho điều kiện gửi duyệt.

### 4.13. Sơ đồ trạng thái lệnh điều khiển runtime

```{.mermaid caption="Máy trạng thái của lệnh điều khiển runtime"}
stateDiagram-v2
    [*] --> ISSUED : người có quyền ra lệnh
    ISSUED --> DELIVERED : lệnh ghi lên topic điều khiển
    DELIVERED --> ACKNOWLEDGED : mọi bản sao xác nhận
    DELIVERED --> PARTIAL : một phần bản sao xác nhận khi hết hạn
    DELIVERED --> REJECTED : runtime từ chối (chữ ký sai, hết hạn)
    ACKNOWLEDGED --> RECONCILED : Git đã ghi trạng thái mong muốn tương ứng
    PARTIAL --> RECONCILED
```

Lệnh chỉ khép lại ở `RECONCILED` khi Git đã ghi trạng thái mong muốn tương ứng, để lần đồng bộ sau của Argo CD không bật lại luồng đã dừng. `PARTIAL` và `REJECTED` hiện cho người vận hành với danh sách bản sao chưa xác nhận (ERR-04-024).

## 5. Danh sách chức năng

PH-04 có 60 chức năng chia bảy nhóm. Bảng dưới liệt kê toàn bộ chức năng kèm nhóm, mức ưu tiên, đợt phát hành và màn hình hiện thực; đặc tả chi tiết ở chương 6. Nhóm: A Không gian làm việc và quản lý luồng; B Trình thiết kế luồng; C Chạy thử và ca kiểm thử; D Duyệt, phát hành và triển khai; E Vận hành luồng; F Data plane, khuôn mẫu route chuẩn; G Danh mục thành phần, di trú, kiểm toán, tham số. Quy ước đợt: FR mức M thuộc MVP; S thuộc Đợt 2 (mô hình dữ liệu và API chừa sẵn); C làm khi có nhu cầu.

| Mã | Nhóm | Chức năng | Mức | Đợt | Màn hình |
|---|---|---|---|---|---|
| FR-04-001 | A | Liệt kê luồng, tìm theo tên, endpoint, hệ nguồn, môi trường, đếm theo trạng thái | M | MVP | UI-04-01 |
| FR-04-002 | A | Xem chi tiết luồng | M | MVP | UI-04-02 |
| FR-04-003 | A | Tạo luồng mới từ luồng trống, khuôn mẫu, API hoặc tệp YAML | M | MVP | UI-04-03 |
| FR-04-004 | A | Cập nhật thông tin luồng | M | MVP | UI-04-02 |
| FR-04-005 | A | Nhân bản luồng | S | Đợt 2 | UI-04-02 |
| FR-04-006 | A | Gỡ bỏ luồng có kiểm tra phụ thuộc, xóa bản nháp | M | MVP | UI-04-02 |
| FR-04-007 | A | Quản lý không gian làm việc và thành viên | S | Đợt 2 | UI-04-21 |
| FR-04-010 | B | Mở trình thiết kế, phiên soạn thảo và cảnh báo người khác đang sửa | M | MVP | UI-04-04 |
| FR-04-011 | B | Tạo phiên bản mới từ phiên bản đã có | M | MVP | UI-04-04 |
| FR-04-012 | B | Bảng thành phần theo danh mục được phép | M | MVP | UI-04-04 |
| FR-04-013 | B | Thao tác trên sơ đồ | M | MVP | UI-04-04 |
| FR-04-014 | B | Cấu hình chặng bằng biểu mẫu sinh từ catalog | M | MVP | UI-04-04, UI-04-05 |
| FR-04-015 | B | Trình soạn biểu thức | M | MVP | UI-04-06 |
| FR-04-016 | B | Chọn kết nối PH-05 và tham chiếu bí mật | M | MVP | UI-04-05 |
| FR-04-017 | B | Đồng bộ hai chiều giữa sơ đồ, thuộc tính và YAML | M | MVP | UI-04-04 |
| FR-04-018 | B | Soạn Kamelet và gửi đăng ký Kamelet tự viết | S | Đợt 2 | UI-04-08 |
| FR-04-019 | B | Soạn Pipe | S | Đợt 2 | UI-04-09 |
| FR-04-020 | B | Trình ánh xạ dữ liệu sinh biểu thức JQ | M | MVP | UI-04-07 |
| FR-04-021 | B | Bean, cấu hình cấp tệp và metadata | S | Đợt 2 | UI-04-10 |
| FR-04-022 | B | Ghim bản tin mẫu theo chặng | M | MVP | UI-04-05 |
| FR-04-023 | B | Kiểm tra hợp lệ định nghĩa luồng | M | MVP | UI-04-04 |
| FR-04-024 | B | Lưu bản nháp tự động, phát hiện xung đột, khôi phục phiên nháp | M | MVP | UI-04-04 |
| FR-04-025 | B | Thư viện khuôn mẫu luồng | S | Đợt 2 (ba khuôn ở MVP) | UI-04-19, UI-04-03 |
| FR-04-026 | B | Ghi chú dán và luồng con dùng lại | C, S | Đợt 2 | UI-04-04 |
| FR-04-027 | B | Tải xuống, nhập YAML và xuất gói luồng | M (gói: S) | MVP | UI-04-04 |
| FR-04-030 | C | Chạy thử luồng trên sandbox với đích mô phỏng | M | MVP | UI-04-11 |
| FR-04-031 | C | Ca kiểm thử của luồng và bộ chạy | S | Đợt 2 | UI-04-13 |
| FR-04-032 | C | Nhật ký chạy thử, xem lại, so sánh, dọn nhật ký | M (so sánh, dọn: S) | MVP | UI-04-12 |
| FR-04-033 | C | Phủ kết quả chạy thử và số liệu chạy thật lên sơ đồ | M (số liệu thật: S) | MVP | UI-04-11, UI-04-02 |
| FR-04-040 | D | Gửi duyệt phiên bản | M | MVP | UI-04-04 |
| FR-04-041 | D | Duyệt bốn mắt với so sánh YAML và sơ đồ | M | MVP | UI-04-14 |
| FR-04-042 | D | Phát hành qua GitOps và theo dõi tình trạng triển khai | M | MVP | UI-04-15 |
| FR-04-043 | D | So sánh hai phiên bản bất kỳ | M | MVP | UI-04-16 |
| FR-04-044 | D | Quay lui về phiên bản trước | M | MVP | UI-04-15 |
| FR-04-045 | D | Thăng cấp phiên bản qua các môi trường | S | Đợt 2 | UI-04-15 |
| FR-04-050 | E | Kích hoạt, tạm dừng, tiếp tục luồng và từng route có lý do | M | MVP | UI-04-02 |
| FR-04-051 | E | Xem tình trạng runtime của luồng | M | MVP | UI-04-02 |
| FR-04-052 | E | Danh sách điểm kết nối và số liệu theo điểm kết nối | M | MVP | UI-04-02 |
| FR-04-053 | E | Giám sát theo luồng nhúng từ PH-13 | S | Đợt 2 | UI-04-02 |
| FR-04-060 | F | Khung chín chặng chuẩn và thư viện nền | M | MVP | Không (data plane) |
| FR-04-061 | F | Tiếp nhận đồng bộ HTTP và SOAP qua APISIX | M | MVP | Không |
| FR-04-062 | F | Tiếp nhận bất đồng bộ từ Kafka | M | MVP | Không |
| FR-04-063 | F | Kiểm tra lược đồ bản tin | M | MVP | Không |
| FR-04-064 | F | Ủy quyền qua OPA | M | MVP | Không |
| FR-04-065 | F | Chuyển đổi, chuẩn hóa về CDM và chuyển mã qua PH-07 | M | MVP | Không |
| FR-04-066 | F | Làm giàu bản tin | M | MVP | Không |
| FR-04-067 | F | Che, giả danh dữ liệu cá nhân theo chính sách PH-09 | M | MVP | Không |
| FR-04-068 | F | Định tuyến theo nội dung, tách, gộp, gọi song song, gửi đích | M (tách, gộp, song song: S) | MVP | Không |
| FR-04-069 | F | Phát sự kiện ra Kafka | M | MVP | Không |
| FR-04-070 | F | Xử lý lỗi chuẩn: phân loại, thử lại, ngắt mạch, DLQ, dự phòng | M | MVP | Không |
| FR-04-071 | F | Chống trùng bản tin | M | MVP | Không |
| FR-04-072 | F | Truy cập CSDL trực tiếp có kiểm soát (Q359) | M | MVP | Không |
| FR-04-073 | F | Ngữ cảnh tenant trên mỗi bản tin | M | MVP | Không |
| FR-04-074 | F | Vết, chỉ số, log và nhật ký kết nối | M | MVP | Không |
| FR-04-075 | F | Hồ sơ runtime, biên dịch native và chế độ JVM | M | MVP | Không |
| FR-04-080 | G | Danh mục thành phần và chính sách thành phần được phép | M | MVP | UI-04-17 |
| FR-04-081 | G | Khớp phiên bản catalog với runtime | M | MVP | UI-04-17 |
| FR-04-082 | G | Chuyển luồng Camel XML của Bus cũ sang YAML | M | MVP | UI-04-18 |
| FR-04-083 | G | Lịch sử thao tác và kiểm toán của luồng | M | MVP | UI-04-02 |
| FR-04-084 | G | Tham số PH-04 theo tenant và đóng băng thay đổi | S | Đợt 2 | UI-04-20 |

: Danh sách chức năng của PH-04

## 6. Đặc tả chi tiết chức năng

### 6.1. Cách đọc bảng đặc tả

Mỗi chức năng được đặc tả bằng một bảng hai cột gồm 17 mục cố định. Chuẩn này kết hợp hai nguồn: 12 trường kỹ thuật của mẫu FR ở D00-01 §4.3 (đầu vào, đầu ra, mã lỗi, sự kiện, kiểm toán) để kỹ sư và kiểm thử viên dùng ngay, và các mục của mẫu thuyết minh đặc tả chức năng (mục đích, kích hoạt, luồng theo tác nhân, thông báo, kết quả, màn hình) để hội đồng và người dùng nghiệp vụ đọc được. Mục không áp dụng ghi "Không" để người đọc biết đã được xét, không bị bỏ sót.

| Mục | Nội dung | Nguồn |
|---|---|---|
| Mục đích | Chức năng giúp ai làm được việc gì, vì sao cần | Mẫu thuyết minh |
| Tác nhân, quyền | Vai trò thực hiện và `PERM` cần có | D00-01 §4.3 |
| Mức ưu tiên, đợt | M (bắt buộc), S (nên có), C (có thì tốt); đợt phát hành | D00-01 §4.3, mẫu |
| Truy vết | REQ, LGC, Q, ADR, mã repo | D00-01 §4.3 |
| Tiền điều kiện | Trạng thái phải đúng trước khi chức năng chạy | D00-01 §4.3 |
| Kích hoạt | Thao tác hoặc sự kiện khởi động chức năng | Mẫu thuyết minh |
| Đầu vào | Tham số, trường nhập: tên, kiểu chuẩn, bắt buộc, ràng buộc (bảng riêng khi từ 5 trường) | D00-01 §4.3 |
| Luồng xử lý chính | Các bước đánh số, chủ ngữ là tác nhân hoặc hệ thống; bước kiểm tra ghi mã lỗi khi không đạt | Cả hai |
| Luồng thay thế | Nhánh hợp lệ khác của luồng chính | Mẫu thuyết minh |
| Luồng ngoại lệ | Điều kiện, mã lỗi `ERR`, mã HTTP, hành vi, câu thông báo người dùng nhìn thấy | Cả hai |
| Đầu ra | Mã HTTP, các trường trả về, tiêu đề | D00-01 §4.3 |
| Kết quả | Điều người dùng nhận được khi thành công | Mẫu thuyết minh |
| Hậu điều kiện | Trạng thái dữ liệu sau khi kết thúc | D00-01 §4.3 |
| Sự kiện phát ra | `EVT` nếu có | D00-01 §4.3 |
| Kiểm toán | Có ghi kiểm toán không, các trường được ghi | D00-01 §4.3 |
| Quy tắc nghiệp vụ | Mã `BR` áp dụng (chương 7) | Cả hai |
| Màn hình, API | `UI` và `API` hiện thực chức năng | Mẫu thuyết minh |

: Các mục của bảng đặc tả chức năng

Câu thông báo trong luồng ngoại lệ lấy từ D03-06-PH04 §5.3; câu mới viết trong tài liệu này được đánh dấu ở chương 9.2 và ghi vào Phụ lục B để đồng bộ. Lỗi runtime (ERR-04-101…112) không có người dùng nhìn trực tiếp trên màn PH-04: bên gọi nhận thân lỗi RFC 9457, người vận hành thấy ở nhật ký kết nối, PH-13 và PH-18. Ví dụ trong chương dùng tenant `T68` và dữ liệu giả lập. Mọi API ở mặt phẳng điều khiển dùng tiền tố `/api/integration/v1`.

**Quy định chung cho mọi FR.** Các quy định dưới đây không lặp lại ở từng FR.

**Tenant và phạm vi.** Tenant xác định từ ngữ cảnh xác thực, không lấy từ tham số client gửi (FR-00-010); mọi truy vấn chạy dưới RLS với `app.tenant_id` của phiên. Đối tượng thuộc tenant khác hoặc thuộc không gian làm việc mà người dùng không là thành viên (với vai trò bị giới hạn theo mục 3.4) trả `404` thay vì `403` để không lộ sự tồn tại (FR-00-011).

**Lũy đẳng và khóa lạc quan.** Thao tác tạo nhận tiêu đề `Idempotency-Key` (16…128 ký tự, lưu 24 giờ); cùng khóa cùng nội dung trả kết quả cũ, cùng khóa khác nội dung trả `ERR-04-018`. Thao tác sửa, xóa, chuyển trạng thái yêu cầu `If-Match` chứa ETag; không khớp trả `ERR-04-006` (412), thiếu trả `ERR-04-007` (428). Riêng lưu định nghĩa (FR-04-024) dùng ETag của phiên bản, không của luồng, để đổi tên luồng không làm hỏng phiên soạn thảo.

**Lỗi.** Lỗi trả theo RFC 9457 với `type`, `title`, `status`, `detail`, `instance`, `code` (mã `ERR-04-nnn`), `traceId`; lỗi kiểm tra hợp lệ thêm mảng `errors` gồm `{path, code, message, severity, nodeId}`, trong đó `nodeId` là mã chặng trên sơ đồ để giao diện tô đúng chặng. Thông điệp tiếng Việt nói rõ sai gì và sửa thế nào (FR-00-080).

**Kiểm toán.** Mọi thao tác ghi thành công sinh bản ghi kiểm toán qua PH-13 theo FR-00-040, FR-00-041 với các trường chung: thời điểm, tenant, chủ thể, địa chỉ nguồn, hành động, loại và mã đối tượng, giá trị trước và sau (chỉ trường thay đổi; với định nghĩa YAML chỉ ghi băm trước và sau, không ghi toàn văn), kết quả, lý do, `traceId`. Mục "Kiểm toán" của từng FR chỉ ghi phần riêng. Thao tác đọc không ghi kiểm toán, trừ đọc nhật ký chạy thử có bản tin thật (FR-04-032).

**Sự kiện.** Sự kiện ghi vào bảng outbox trong cùng giao dịch với thay đổi (SAD §7.3), phát lên topic `{tenant}.integration.{đối tượng}.{động từ}.v1` của PH-10.

**Định nghĩa luồng.** "YAML chuẩn hóa" là YAML sau khi bỏ chú thích bố cục, sắp khóa theo thứ tự của lược đồ Camel, thụt lề hai dấu cách, kết thúc bằng một dòng trống. Băm nội dung tính trên YAML chuẩn hóa. Kích thước định nghĩa tối đa `04.flow.max-definition-kb` (mặc định 512 KiB); vượt trả `ERR-04-033`.

Kiểu dữ liệu chuẩn theo D00-01 §5. FRS dùng thêm: `T-FLOW-CODE` mẫu `^[a-z][a-z0-9-]{2,62}$`; `T-YAML` chuỗi UTF-8 là tài liệu YAML; `T-ENV` ∈ {`TEST`, `STAGING`, `PROD`}; `T-INT` số nguyên 32 bit.

### 6.2. Nhóm A · Không gian làm việc và quản lý luồng

Nhóm A là phần quản lý luồng như một đối tượng nghiệp vụ: tìm, xem, tạo, sửa thông tin, nhân bản, gỡ, và nhóm luồng theo không gian làm việc của từng đơn vị. Nhóm này thay danh sách và chi tiết "chương trình tích hợp" của Bus cũ và thanh Project của Tooling. Vòng đời của luồng theo máy trạng thái ở mục 4.9. Hình dưới tóm tắt quan hệ giữa các chức năng trong nhóm.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm A"}
flowchart TB
  F007["FR-04-007 Không gian<br/>làm việc, thành viên"] --> F003["FR-04-003 Tạo luồng"]
  F003 --> F001["FR-04-001 Danh sách luồng"]
  F001 --> F002["FR-04-002 Chi tiết luồng"]
  F002 --> F004["FR-04-004 Sửa thông tin"]
  F002 --> F005["FR-04-005 Nhân bản"]
  F002 --> F006["FR-04-006 Gỡ, xóa nháp"]
  F005 --> F003
  F002 --> B["Nhóm B: mở<br/>trình thiết kế"]
```

Không gian làm việc quyết định ai được sửa, duyệt luồng nào (mục 3.4); mọi luồng sinh ra từ FR-04-003 hoặc FR-04-005 và được quản lý từ màn chi tiết.

#### FR-04-001 · Liệt kê luồng, tìm theo tên, endpoint, hệ nguồn, môi trường, đếm theo trạng thái

::: dac-ta
**Mục đích.** Cho mọi người có quyền xem tìm nhanh luồng cần làm việc và nắm tình trạng chung của các luồng trong tỉnh. Đây là màn đầu tiên của PH-04 (UI-04-01), thay danh sách chương trình tích hợp có phân trang của Bus và bốn kiểu tìm kiếm cũ (theo endpoint, nguồn, tên, host). Tìm theo host được thay bằng tìm theo môi trường và namespace vì không còn máy chủ cố định.

**Tác nhân, quyền.** Mọi vai trò có `PERM-04-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-001, 002, 003, 004, 005, 025; LGC-TOOL-001 · Mã repo: FR-D-001.

**Tiền điều kiện.** Đã đăng nhập và chọn tenant làm việc (FR-00-004).

**Kích hoạt.** Người dùng mở menu "Tích hợp › Luồng", nhập ô tìm, chọn bộ lọc hoặc bấm một ô đếm trạng thái ở đầu UI-04-01.

**Đầu vào.** Theo bảng tham số truy vấn của FR-04-001 dưới đây; mọi tham số tùy chọn.

**Luồng xử lý chính.**

1. Người dùng mở danh sách, nhập từ khóa hoặc chọn bộ lọc.
2. Hệ thống kiểm tra tham số; sai miền trả `400` với `errors` (ERR-04-049); `size` > 100 trả ERR-04-026.
3. Hệ thống lọc luồng của tenant, loại luồng đã xóa mềm, và với người dùng bị giới hạn theo không gian làm việc (mục 3.4) chỉ giữ luồng của không gian làm việc mà người dùng là thành viên.
4. Hệ thống áp bộ lọc. Lọc `endpoint` dùng bảng chỉ mục endpoint được tính khi lưu định nghĩa (EN-04-04), không phân tích YAML lúc truy vấn.
5. Hệ thống tính `facets` trên tập kết quả trước phân trang.
6. Hệ thống ghép tình trạng triển khai mới nhất theo môi trường (EN-04-06) và tính `allowedActions` theo quyền, trạng thái và vai trò không gian làm việc.
7. Hệ thống sắp xếp, phân trang, trả kết quả; giao diện hiện bảng và các ô đếm theo trạng thái.

**Luồng thay thế.**

- `workspace` không tồn tại hoặc người dùng không là thành viên: hệ thống trả `200` với danh sách rỗng, không báo lỗi.
- `pendingMyReview = true`: danh sách chỉ còn luồng có phiên bản chờ chính người dùng duyệt (lối tắt từ "Việc của tôi").

**Luồng ngoại lệ.**

- Tham số sai kiểu, ngoài miền: ERR-04-049 (400), `errors` theo tham số; bộ lọc sai hiện viền đỏ kèm "Giá trị lọc không hợp lệ: {tham số}."
- `size` > 100: ERR-04-026 (400); "Mỗi trang tối đa 100 dòng."

**Đầu ra.** `200`; trang kết quả `items[]` (mã, tên, loại tài nguyên, vận chuyển, đối ngoại/nội bộ, không gian làm việc, trạng thái tổng hợp, phiên bản đang chạy ở PROD, phiên bản mở và trạng thái của nó, HTTT nguồn, HTTT đích, endpoint chính, tình trạng triển khai theo từng môi trường, người sửa cuối, thời điểm sửa cuối, `allowedActions`), `page`, `size`, `totalElements`, khối `facets` đếm theo trạng thái, loại tài nguyên, vận chuyển, không gian làm việc, môi trường có triển khai.

**Kết quả.** Người dùng thấy danh sách luồng đúng phạm vi được xem, số luồng theo từng trạng thái và các nút thao tác được phép trên từng dòng.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (thao tác đọc).

**Quy tắc nghiệp vụ.** BR-04-021 (giới hạn theo không gian làm việc).

**Màn hình, API.** UI-04-01; API-04-010.
:::

| Tham số | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `q` | T-NAME | Không | Tìm không dấu trên mã, tên, mô tả; 1…100 ký tự | `ho tich` |
| `endpoint` | chuỗi | Không | Khớp chuỗi con trên URI của chặng đầu và các chặng `to` (đã chuẩn hóa, bỏ tham số truy vấn); 2…200 ký tự | `/ho-tich/tra-cuu` |
| `sourceSystem` | T-CODE[] | Không | Mã HTTT nguồn | `hotich-tinh` |
| `targetSystem` | T-CODE[] | Không | Mã HTTT đích | `ndxp` |
| `workspace` | T-CODE[] | Không | Mã không gian làm việc | `so-tu-phap` |
| `status` | T-ENUM[] | Không | Trạng thái ở mục 4.9; mặc định mọi trạng thái trừ `RETIRED` | `ACTIVE,DEGRADED` |
| `resourceKind` | T-ENUM[] | Không | `ROUTE`, `KAMELET`, `PIPE`, `TEST` | `ROUTE` |
| `transport` | T-ENUM[] | Không | `SYNC`, `ASYNC`, `SCHEDULED`, `MIXED` | `ASYNC` |
| `environment` | T-ENV | Không | Chỉ luồng có triển khai ở môi trường này | `PROD` |
| `namespace` | chuỗi | Không | `dh-runtime` hoặc `dh-rt-{tenant}` (thay tìm theo host) | |
| `hasOpenVersion` | T-BOOL | Không | Có phiên bản mở | `true` |
| `pendingMyReview` | T-BOOL | Không | Có phiên bản chờ người dùng hiện tại duyệt | `true` |
| `updatedFrom`, `updatedTo` | T-DATE | Không | Khoảng ngày sửa cuối | |
| `page`, `size` | T-INT | Không | `size` ∈ {10, 20, 50, 100}, mặc định 20 | |
| `sort` | chuỗi | Không | `code`, `name`, `updatedAt`, `status`, kèm `,asc` hoặc `,desc`; mặc định `updatedAt,desc` | |

: Dữ liệu vào của FR-04-001

#### FR-04-002 · Xem chi tiết luồng: thông tin, route, endpoint, thuộc tính, sơ đồ, mã nguồn, phiên bản, triển khai

::: dac-ta
**Mục đích.** Cho người dùng xem toàn bộ thông tin của một luồng ở một chỗ. Màn chi tiết nhiều tab (UI-04-02) thay màn chi tiết agent và chi tiết route của Bus: metadata (người tạo, ngày, mô tả, agent URL), danh sách route, tab endpoint, tab thuộc tính, tab đồ thị, tab mã nguồn, tab dữ liệu thêm, trạng thái hoạt động. Các biểu đồ lượng bản tin, CPU, bộ nhớ của Bus cũ được nhúng từ PH-13 (FR-04-053).

**Tác nhân, quyền.** `PERM-04-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-006, 008, 017, 018, 020, 021, 022, 023, 024, 025 · Mã repo: FR-D-004.

**Tiền điều kiện.** Luồng tồn tại trong tenant, người dùng thấy được theo mục 3.4.

**Kích hoạt.** Người dùng bấm tên luồng ở UI-04-01, mở liên kết trực tiếp, hoặc chọn phiên bản, môi trường trên tab Phiên bản.

**Đầu vào.** `{flowCode}` (T-FLOW-CODE, bắt buộc); `version` (T-INT hoặc `running`, `latest`, `open`; mặc định `running` nếu có, ngược lại `latest`); `environment` (T-ENV; với `version=running`, môi trường để chọn phiên bản đang chạy; mặc định `PROD`).

**Luồng xử lý chính.**

1. Người dùng mở chi tiết luồng.
2. Hệ thống tìm luồng; không thấy hoặc không được thấy trả ERR-04-001.
3. Hệ thống chọn phiên bản theo `version`; không có trả ERR-04-004.
4. Hệ thống trả các khối thông tin. Danh sách route, endpoint và bảng thuộc tính lấy từ cây tài nguyên đã phân tích và lưu khi lưu định nghĩa (EN-04-04), không phân tích lại YAML mỗi lần xem.
5. Hệ thống che URI endpoint: tham số có tên thuộc danh sách nhạy cảm (`password`, `secret`, `token`, `apiKey`, `accessKey`, `privateKey`, `passphrase`) thay bằng `***`, dù theo BR-04-003 chúng không thể là giá trị thật.
6. Giao diện hiện tab Tổng quan và các tab còn lại theo quyền.

**Luồng thay thế.** Người dùng chọn phiên bản khác hoặc môi trường khác trên tab Phiên bản, Triển khai: hệ thống lặp từ bước 3 với `version`, `environment` mới.

**Luồng ngoại lệ.**

- Không tìm thấy luồng: ERR-04-001 (404); "Không tìm thấy luồng, hoặc bạn không có quyền xem luồng này." kèm nút "Về danh sách luồng".
- Không tìm thấy phiên bản: ERR-04-004 (404); "Không tìm thấy phiên bản v{n} của luồng này."

**Đầu ra.** `200`; thông tin luồng (mọi trường EN-04-02, chủ sở hữu, HTTT liên quan, nhãn, không gian làm việc); danh sách route trong phiên bản chọn (mã route, chặng đầu, số chặng, mô tả, `autoStartup`); danh sách endpoint (chiều vào hoặc ra, thành phần, URI đã che tham số nhạy cảm, phương thức HTTP, đường dẫn); bảng thuộc tính (tham số của từng chặng lấy từ định nghĩa, không đọc từ JMX); sơ đồ chỉ đọc; YAML chuẩn hóa; danh sách phiên bản; triển khai theo môi trường; khối "dữ liệu thêm" gồm nhãn, chú thích, liên kết tài liệu; ETag của luồng.

**Kết quả.** Người dùng thấy mọi thông tin của luồng mà Bus cũ chia trên sáu tab, cùng phiên bản và triển khai theo môi trường, không cần truy cập máy chủ chạy.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-003 (che tham số nhạy cảm khi hiển thị).

**Màn hình, API.** UI-04-02; API-04-012, 024, 016.
:::

#### FR-04-003 · Tạo luồng mới từ luồng trống, khuôn mẫu, API trong danh mục dịch vụ hoặc tệp YAML

::: dac-ta
**Mục đích.** Cho kỹ sư tích hợp bắt đầu một luồng mới nhanh và đúng chuẩn ngay từ đầu: luồng đối ngoại sinh sẵn khung chín chặng và xử lý lỗi nền, luồng từ API sinh sẵn route cho từng thao tác. Thay "thêm project" của Tooling và "thêm chương trình tích hợp" của Bus.

**Tác nhân, quyền.** IE với `PERM-04-create`, mức `EDIT` trên không gian làm việc đích.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-013; LGC-TOOL-002 · Mã repo: FR-D-003, FR-D-060.

**Tiền điều kiện.** Tenant hoạt động; không gian làm việc tồn tại.

**Kích hoạt.** IE bấm "+ Tạo luồng" ở UI-04-01, chọn "Dùng khuôn này" ở UI-04-19, hoặc tạo luồng nháp từ báo cáo chuyển đổi ở UI-04-18.

**Đầu vào.** Theo bảng dữ liệu vào của FR-04-003 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. IE chọn loại tài nguyên, điểm xuất phát (trống, khuôn mẫu, API, tệp), nhập mã, tên, không gian làm việc, HTTT liên quan rồi bấm "Tạo luồng".
2. Hệ thống chuẩn hóa văn bản, kiểm tra quyền và mức truy cập không gian làm việc (không có mức `EDIT`: ERR-04-003; không gian không tồn tại: ERR-04-027).
3. Hệ thống kiểm tra tính duy nhất của `code`; trùng trả ERR-04-002.
4. Hệ thống sinh định nghĩa ban đầu theo `origin`:
   - `BLANK` với `ROUTE`: một route có chặng đầu trống và, nếu luồng đối ngoại, chín khối chặng chuẩn rỗng (mục 4.6) kèm `routeConfiguration` tham chiếu cấu hình xử lý lỗi nền (FR-04-070).
   - `BLANK` với `KAMELET`, `PIPE`, `TEST`: khung tối thiểu hợp lệ của loại đó.
   - `TEMPLATE`: điền tham số vào khuôn mẫu (FR-04-025); khuôn không tồn tại hoặc không được phép: ERR-04-039.
   - `API_SPEC`: đọc OpenAPI từ PH-02, sinh `rest` DSL với mỗi thao tác một route `direct:{operationId}` có khung chín chặng, lược đồ yêu cầu và phản hồi gắn vào chặng `schema`.
   - `YAML_FILE`: phân tích (lỗi cú pháp: ERR-04-008; vượt kích thước: ERR-04-033), xác định loại tài nguyên từ nội dung; loại khác `resourceKind` khai báo trả ERR-04-009.
5. Hệ thống chạy kiểm tra hợp lệ (FR-04-023) ở chế độ thiết kế; lỗi không chặn việc tạo, được lưu kèm phiên bản.
6. Hệ thống ghi luồng, phiên bản 1, chỉ mục endpoint và route, outbox EVT-04-01 trong một giao dịch.
7. Hệ thống ghi kiểm toán, trả `201` và giao diện mở trình thiết kế ở phiên bản 1.

**Luồng thay thế.**

- `origin = LEGACY_XML`: luồng được tạo từ kết quả chuyển đổi của FR-04-082, định nghĩa ban đầu là YAML đã chuyển kèm chỗ trống kết nối.
- Cùng `Idempotency-Key`, cùng nội dung: hệ thống trả lại kết quả của lần tạo trước, không tạo luồng thứ hai.

**Luồng ngoại lệ.**

- Mã luồng trùng: ERR-04-002 (409); "Mã luồng "{code}" đã được dùng trong tỉnh." kèm gợi ý mã "{code}-2".
- Không có mức `EDIT` trên không gian làm việc: ERR-04-003 (403); "Bạn chưa có quyền sửa trong không gian làm việc "{workspace}"."
- Không gian làm việc không tồn tại: ERR-04-027 (404); "Không tìm thấy không gian làm việc "{workspace}"."
- Khuôn mẫu không tồn tại hoặc không được phép: ERR-04-039 (404); "Khuôn mẫu "{template}" không tồn tại hoặc không được phép dùng trong tỉnh."
- YAML không phân tích được: ERR-04-008 (422); "YAML có lỗi cú pháp ở dòng {line}, cột {column}: {message}"
- Loại tài nguyên không khớp nội dung: ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi tạo."
- Định nghĩa vượt kích thước: ERR-04-033 (413); "Định nghĩa luồng vượt {limit}. Tách thành nhiều luồng hoặc luồng con."
- `Idempotency-Key` dùng với nội dung khác: ERR-04-018 (409); "Yêu cầu này đã được gửi với nội dung khác. Tải lại trang rồi thử lại."

**Đầu ra.** `201 Created`, `Location: /api/integration/v1/flows/{code}`, thân là chi tiết luồng kèm `openVersionNo = 1`; ETag.

**Kết quả.** IE có một luồng nháp đã có khung đúng chuẩn và được đưa thẳng vào trình thiết kế để làm tiếp.

**Hậu điều kiện.** Một `flow` trạng thái `DRAFT`; một `flow_version` số 1 trạng thái `DRAFT`, `origin` ghi nguồn khởi tạo; chỉ mục endpoint, route của phiên bản 1.

**Sự kiện phát ra.** EVT-04-01 `{tenant}.integration.flow.created.v1`.

**Kiểm toán.** Có: `INT_FLOW_CREATE`, đối tượng `flow/{code}`, giá trị sau là thông tin luồng và băm định nghĩa.

**Quy tắc nghiệp vụ.** BR-04-001 (mã duy nhất, không đổi); BR-04-002 (khung chín chặng cho luồng đối ngoại); BR-04-016 (một phiên bản mở).

**Màn hình, API.** UI-04-03, UI-04-19; API-04-011, 080, 081.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `code` | T-FLOW-CODE | Có | Duy nhất trong tenant, kể cả luồng đã gỡ trong 30 ngày lưu giữ; không dùng tiền tố dành riêng `dh-`, `sys-`, `platform-` | `tra-cuu-ho-tich` |
| `name` | T-NAME | Có | 1…255 ký tự, NFC | `Tra cứu hộ tịch cho cổng DVC` |
| `description` | T-TEXT | Không | ≤ 4.000 ký tự | |
| `workspaceCode` | T-CODE | Có | Người dùng có mức `EDIT` trở lên | `so-tu-phap` |
| `resourceKind` | T-ENUM | Có | `ROUTE`, `KAMELET`, `PIPE`, `TEST` | `ROUTE` |
| `origin` | T-ENUM | Có | `BLANK`, `TEMPLATE`, `API_SPEC`, `YAML_FILE`, `LEGACY_XML` (qua FR-04-082) | `TEMPLATE` |
| `templateCode` | T-CODE | Khi `TEMPLATE` | Khuôn mẫu tồn tại, cùng loại tài nguyên, được phép cho tenant | `tpl-sync-lookup` |
| `templateParams` | T-JSON | Không | Theo lược đồ tham số của khuôn mẫu | `{"path":"/ho-tich/tra-cuu"}` |
| `apiRef` | T-ID | Khi `API_SPEC` | API trong danh mục dịch vụ PH-02 mà người dùng có quyền xem | |
| `definitionYaml` | T-YAML | Khi `YAML_FILE` | ≤ 512 KiB; phân tích được | |
| `testTargetFlow` | T-FLOW-CODE | Khi `TEST` | Luồng `ROUTE` hoặc `PIPE` cùng không gian làm việc | `tra-cuu-ho-tich` |
| `sourceSystem` | T-CODE | Không | HTTT trong danh sách PH-01 đã kết nạp, hoặc mã nội bộ | `cong-dvc-tinh` |
| `targetSystems` | T-CODE[] | Không | Như trên, tối đa 20 | `["hotich-tinh"]` |
| `labels` | T-JSON (map) | Không | Tối đa 20 cặp; khóa `^[a-z0-9.-/]{1,63}$` | `{"linh-vuc":"tu-phap"}` |

: Dữ liệu vào của FR-04-003

#### FR-04-004 · Cập nhật thông tin luồng

::: dac-ta
**Mục đích.** Cho kỹ sư sửa thông tin mô tả của luồng (tên, mô tả, không gian làm việc, HTTT nguồn và đích, nhãn, liên kết tài liệu) mà không phải tạo phiên bản mới, vì các thông tin này không thuộc phiên bản. Mã luồng và loại tài nguyên không sửa được. Sửa host, port, method của agent như Bus cũ (LGC-BUS-011) không còn ở đây: tham số kết nối thuộc phiên bản luồng (FR-04-014) hoặc kết nối PH-05.

**Tác nhân, quyền.** IE (`PERM-04-update`, mức `EDIT`), TA.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-006, 011 · Mã repo: FR-D-002 (đổi tên).

**Tiền điều kiện.** Luồng tồn tại, không ở trạng thái `RETIRED`.

**Kích hoạt.** Người dùng bấm "Sửa thông tin" trên tab Tổng quan của UI-04-02.

**Đầu vào.** Các trường `name`, `description`, `workspaceCode`, `sourceSystem`, `targetSystems`, `labels`, `docLinks` (tối đa 10 URL `https`) như FR-04-003; `If-Match`.

**Luồng xử lý chính.**

1. Người dùng sửa các trường rồi bấm "Lưu".
2. Hệ thống kiểm tra `If-Match` (thiếu: ERR-04-007; không khớp: ERR-04-006) và luồng không `RETIRED` (ERR-04-034).
3. Hệ thống kiểm tra quyền; chuyển luồng sang không gian làm việc khác yêu cầu mức `EDIT` ở cả hai nơi (ERR-04-003).
4. Hệ thống lưu các trường đổi, trả ETag mới.
5. Nếu `sourceSystem` hoặc `targetSystems` đổi làm luồng chuyển từ nội bộ sang đối ngoại, hệ thống kiểm tra lại phiên bản mở với mức nghiêm ngặt của luồng đối ngoại và báo các phát hiện mới.
6. Hệ thống ghi outbox EVT-04-02 và kiểm toán.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**

- ETag không khớp: ERR-04-006 (412); "{user} đã lưu phiên bản này lúc {time}. Thay đổi của bạn chưa được lưu."
- Thiếu `If-Match`: ERR-04-007 (428); "Thiếu thông tin phiên bản dữ liệu. Tải lại trang rồi thử lại."
- Luồng đã gỡ: ERR-04-034 (409); "Luồng đã gỡ và chỉ còn để xem."
- Không có quyền trên không gian làm việc đích: ERR-04-003 (403); "Bạn chưa có quyền sửa trong không gian làm việc "{workspace}"."

**Đầu ra.** `200` với chi tiết luồng, ETag mới.

**Kết quả.** Thông tin luồng được cập nhật ngay trên danh sách và chi tiết; nếu luồng thành đối ngoại, người dùng thấy ngay những gì phải bổ sung trước khi gửi duyệt.

**Hậu điều kiện.** Thông tin luồng đổi; nếu `sourceSystem` hoặc `targetSystems` đổi làm luồng chuyển từ nội bộ sang đối ngoại thì phiên bản mở được kiểm tra lại với mức nghiêm ngặt của luồng đối ngoại.

**Sự kiện phát ra.** EVT-04-02 `flow.updated` với danh sách trường đổi.

**Kiểm toán.** Có: `INT_FLOW_UPDATE`, giá trị trước và sau của các trường đổi.

**Quy tắc nghiệp vụ.** BR-04-001 (mã không đổi); BR-04-002; BR-04-021.

**Màn hình, API.** UI-04-02 tab Tổng quan; API-04-013.
:::

#### FR-04-005 · Nhân bản luồng

::: dac-ta
**Mục đích.** Cho kỹ sư tạo một luồng mới từ một luồng đã có khi hai tích hợp gần giống nhau, tránh làm lại từ đầu.

**Tác nhân, quyền.** IE (`PERM-04-create`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04 · Mã repo: FR-D-002 (nhân bản).

**Tiền điều kiện.** Luồng nguồn tồn tại; người dùng có mức `EDIT` trên không gian làm việc đích.

**Kích hoạt.** Người dùng bấm "Nhân bản" trên UI-04-02 hoặc trong menu dòng của UI-04-01.

**Đầu vào.** `newCode` (T-FLOW-CODE), `newName`, `sourceVersion` (số phiên bản, mặc định phiên bản mới nhất), `workspaceCode`, `copyTests` (T-BOOL); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Người dùng nhập mã, tên mới, chọn phiên bản nguồn và không gian làm việc rồi bấm "Nhân bản".
2. Hệ thống kiểm tra mã mới chưa dùng (ERR-04-002) và quyền trên không gian làm việc đích (ERR-04-003).
3. Hệ thống sao chép định nghĩa và bố cục của phiên bản nguồn thành phiên bản 1 của luồng mới; ca kiểm thử chỉ sao chép khi `copyTests = true`.
4. Hệ thống giữ nguyên mã route bên trong; vì mã route chỉ cần duy nhất trong một runtime, hệ thống thêm hậu tố khi phát hiện trùng với route của luồng khác đang chạy trong cùng namespace (BR-04-011) và báo lại số mã route đã đổi.
5. Hệ thống ghi luồng mới, outbox EVT-04-01, kiểm toán và mở trình thiết kế.

**Luồng thay thế.** Không phát hiện trùng mã route: bước 4 không đổi mã nào và báo "0 mã route đã đổi".

**Luồng ngoại lệ.**

- Mã mới trùng: ERR-04-002 (409); "Mã luồng "{code}" đã được dùng trong tỉnh."
- Phiên bản nguồn không tồn tại: ERR-04-004 (404); "Không tìm thấy phiên bản v{n} của luồng này."
- Không có quyền trên không gian làm việc đích: ERR-04-003 (403).

**Đầu ra.** `201` như FR-04-003, `origin = DUPLICATE`, `duplicatedFrom = {code, versionNo}`.

**Kết quả.** Người dùng có luồng nháp mới giống luồng nguồn, sẵn sàng chỉnh sửa.

**Hậu điều kiện.** Luồng mới `DRAFT`, phiên bản 1 là bản sao định nghĩa và bố cục; không sao chép triển khai, lần chạy thử, lịch sử duyệt, ca kiểm thử (ca kiểm thử sao chép khi `copyTests = true`).

**Sự kiện phát ra.** EVT-04-01.

**Kiểm toán.** Có: `INT_FLOW_DUPLICATE`, luồng và phiên bản nguồn.

**Quy tắc nghiệp vụ.** BR-04-001; BR-04-011.

**Màn hình, API.** UI-04-02; API-04-014.
:::

#### FR-04-006 · Gỡ bỏ luồng có kiểm tra phụ thuộc, xóa bản nháp

::: dac-ta
**Mục đích.** Cho phép bỏ luồng không còn dùng mà không làm gãy luồng, API hay subscription khác đang phụ thuộc. Thay chức năng xóa agent của Bus. Luồng chưa từng phát hành được xóa hẳn (xóa mềm, giải phóng mã sau 30 ngày). Luồng đã phát hành chỉ được **gỡ**: trạng thái mong muốn ở mọi môi trường thành `REMOVED`, lịch sử giữ lại.

**Tác nhân, quyền.** Xóa luồng chưa phát hành: IE người tạo hoặc TA (`PERM-04-delete`). Gỡ luồng đã phát hành: IA hoặc TA (`PERM-04-delete` và `PERM-04-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-010; LGC-TOOL-016 · Mã repo: FR-D-002 (xóa nháp).

**Tiền điều kiện.** Không có lần chạy thử đang chạy.

**Kích hoạt.** Người dùng bấm "Xóa bản nháp" hoặc "Gỡ luồng" trên UI-04-02.

**Đầu vào.** `reason` (T-TEXT 10…1.000 ký tự, bắt buộc với gỡ), `If-Match`, `force` (chỉ TA, bỏ qua cảnh báo phụ thuộc mềm).

**Luồng xử lý chính.**

1. Người dùng bấm "Gỡ luồng"; giao diện gọi API-04-016 và hiện hộp xác nhận kèm danh sách phụ thuộc.
2. Hệ thống tính phụ thuộc: luồng khác gọi tới route của luồng này qua `direct:`, `seda:`, `kamelet:` (với Kamelet); API ở PH-02 dùng luồng làm backend; subscription ở PH-10 có subscriber là luồng; ca kiểm thử gắn với luồng.
3. Hệ thống chặn khi còn phụ thuộc cứng (API đang công bố, luồng đang chạy gọi tới) với ERR-04-017 kèm danh sách; phụ thuộc mềm (ca kiểm thử, luồng nháp) hiện cảnh báo.
4. Người dùng nhập lý do và xác nhận; hệ thống kiểm tra lý do (ERR-04-025) và không có lần chạy thử đang chạy (ERR-04-005).
5. Với luồng đã phát hành, hệ thống ghi trạng thái mong muốn `REMOVED` vào kho cấu hình cho mọi môi trường (FR-04-042), phát EVT-04-06 cho từng môi trường và trả `202`.
6. Khi mọi triển khai báo đã gỡ, hệ thống chuyển luồng `RETIRED` và phát EVT-04-09.

**Luồng thay thế.**

- Luồng chưa từng phát hành: bỏ bước 5–6; hệ thống đặt `deleted_at`, trả `204`.
- TA gỡ khi chỉ còn phụ thuộc mềm: gửi `force = true`, hệ thống bỏ qua cảnh báo và ghi danh sách phụ thuộc vào kiểm toán.

**Luồng ngoại lệ.**

- Còn phụ thuộc cứng: ERR-04-017 (409); "Luồng đang được dùng bởi {n} đối tượng. Gỡ các phụ thuộc trước." kèm danh sách phụ thuộc.
- Thiếu lý do khi gỡ: ERR-04-025 (400); "Vui lòng nhập lý do (ít nhất {min} ký tự)."
- Đang có lần chạy thử: ERR-04-005 (409); "Phiên bản đang ở trạng thái "{status}" nên không thể gỡ."
- Ghi kho cấu hình lỗi: ERR-04-022 (502); "Không ghi được vào kho cấu hình. Luồng chưa được phát hành."

**Đầu ra.** `202 Accepted` với danh sách triển khai được yêu cầu gỡ (luồng đã phát hành); `204` (luồng chưa phát hành).

**Kết quả.** Luồng không còn chạy ở môi trường nào, không còn hiện trong danh sách mặc định, lịch sử vẫn tra được.

**Hậu điều kiện.** Chưa phát hành: `deleted_at` được đặt. Đã phát hành: luồng `RETIRED` khi mọi triển khai báo đã gỡ.

**Sự kiện phát ra.** EVT-04-09 `flow.retired`; EVT-04-06 cho từng môi trường.

**Kiểm toán.** Có: `INT_FLOW_DELETE` hoặc `INT_FLOW_RETIRE`, lý do, danh sách phụ thuộc tại thời điểm gỡ.

**Quy tắc nghiệp vụ.** BR-04-001 (giải phóng mã sau 30 ngày); BR-04-017 (có lý do).

**Màn hình, API.** UI-04-02; API-04-015, 016, 023.
:::

#### FR-04-007 · Quản lý không gian làm việc và thành viên

::: dac-ta
**Mục đích.** Cho quản trị tenant chia luồng theo đơn vị hoặc dự án và giao quyền sửa, duyệt theo từng nhóm, để sở A không vô tình sửa luồng của sở B trong cùng tỉnh, như cách hệ cũ phân quyền project theo group.

**Tác nhân, quyền.** TA (`PERM-04-admin`) tạo, sửa, lưu trữ; thành viên mức `MAINTAIN` thêm, bớt thành viên.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04; LGC-BUS-032.

**Tiền điều kiện.** Tenant hoạt động; với thêm thành viên, người dùng hoặc nhóm tồn tại ở PH-12.

**Kích hoạt.** TA mở UI-04-21 và bấm "+ Tạo không gian làm việc", "Sửa", "Lưu trữ" hoặc tab Thành viên.

**Đầu vào.** `code` (T-CODE, duy nhất trong tenant), `name`, `ownerOrgId`, `description`; danh sách thành viên `{userId hoặc groupId, accessLevel ∈ VIEW, EDIT, MAINTAIN}`.

**Luồng xử lý chính.**

1. TA nhập mã, tên, tổ chức chủ quản rồi bấm "Lưu".
2. Hệ thống kiểm tra mã chưa dùng (ERR-04-028) và lưu không gian làm việc.
3. Người có quyền thêm, bớt thành viên và chọn mức truy cập; hệ thống thay danh sách thành viên.
4. Hệ thống mở rộng thành viên là nhóm Keycloak thành người dùng lúc kiểm tra quyền; quyền hiệu lực đổi ngay ở lượt gọi kế tiếp.
5. Hệ thống ghi kiểm toán.

**Luồng thay thế.**

- Không gian làm việc còn luồng: không xóa được, chỉ lưu trữ (ẩn khỏi danh sách chọn khi tạo luồng).
- Ở MVP mọi luồng thuộc không gian `DEFAULT` và kiểm tra mức truy cập chỉ bật khi tham số `04.workspace.enforce` bật.

**Luồng ngoại lệ.**

- Mã trùng: ERR-04-028 (409); "Mã không gian làm việc "{code}" đã được dùng."
- Xóa không gian còn luồng: ERR-04-017 (409); "Luồng đang được dùng bởi {n} đối tượng. Gỡ các phụ thuộc trước." (với không gian làm việc, danh sách là các luồng còn lại).
- Không tìm thấy không gian làm việc: ERR-04-027 (404).

**Đầu ra.** `200`/`201`; không gian làm việc và danh sách thành viên.

**Kết quả.** Mỗi đơn vị có không gian làm việc riêng với đúng người được sửa, được duyệt.

**Hậu điều kiện.** Quyền hiệu lực của thành viên thay đổi ngay ở lượt gọi kế tiếp.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: `INT_WORKSPACE_*`, ghi danh sách thành viên thêm, bớt.

**Quy tắc nghiệp vụ.** BR-04-021.

**Màn hình, API.** UI-04-21; API-04-001, 002, 003, 004.
:::

### 6.3. Nhóm B · Trình thiết kế luồng

Nhóm B đặc tả hành vi chức năng của trình thiết kế (UI-04-04 và các cửa sổ phụ UI-04-05…10), phần kỹ sư tích hợp dùng nhiều nhất. Bố cục, thành phần, tương tác chuột và bàn phím, trạng thái từng vùng được đặc tả chi tiết ở D03-06-PH04 §10–§18. FR ở đây chỉ quy định điều hệ thống phải làm và điều máy chủ phải kiểm. Phần lớn thao tác của nhóm chỉ đổi cây tài nguyên trong trình duyệt; máy chủ chỉ tham gia khi mở, lưu (FR-04-024), kiểm tra (FR-04-023) và xem trước biểu thức, ánh xạ trên sandbox.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm B"}
flowchart TB
  F010["FR-04-010 Mở trình thiết kế,<br/>phiên soạn"] --> F011["FR-04-011 Tạo phiên bản mới"]
  F010 --> F013["FR-04-013 Thao tác sơ đồ"]
  F012["FR-04-012 Bảng thành phần"] --> F013
  F013 --> F014["FR-04-014 Cấu hình chặng"]
  F014 --> F015["FR-04-015 Biểu thức"]
  F014 --> F016["FR-04-016 Chọn kết nối"]
  F014 --> F020["FR-04-020 Ánh xạ JQ"]
  F022["FR-04-022 Bản tin mẫu"] --> F015
  F022 --> F020
  F013 --> F017["FR-04-017 Đồng bộ<br/>sơ đồ và YAML"]
  F017 --> F024["FR-04-024 Lưu nháp"]
  F024 --> F023["FR-04-023 Kiểm tra hợp lệ"]
  F023 --> C["Nhóm C, D: chạy thử,<br/>gửi duyệt"]
  F018["FR-04-018 Kamelet, FR-04-019 Pipe,<br/>FR-04-021 Bean, FR-04-026 Ghi chú"] --> F017
  F025["FR-04-025 Khuôn mẫu, FR-04-027 Nhập xuất"] --> F017
```

Mọi đường trong hình hội tụ về FR-04-017: sơ đồ, Inspector và YAML là ba cách nhìn cùng một cây tài nguyên, và chỉ cây đó được lưu, kiểm tra, đem chạy thử.

#### FR-04-010 · Mở trình thiết kế, phiên soạn thảo và cảnh báo người khác đang sửa

::: dac-ta
**Mục đích.** Mở luồng trên trình thiết kế ở đúng chế độ (sửa hay chỉ đọc), báo cho người dùng biết ai khác đang mở cùng luồng và khi nào danh mục thành phần đã đổi, để tránh sửa chồng và tránh làm trên catalog cũ.

**Tác nhân, quyền.** `PERM-04-read` để mở chỉ đọc; `PERM-04-update` và mức `EDIT` để sửa.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-001, 029 · Mã repo: FR-D-010, FR-D-013.

**Tiền điều kiện.** Luồng tồn tại.

**Kích hoạt.** Người dùng bấm "Mở thiết kế" ở UI-04-01, UI-04-02, hoặc được chuyển tới sau khi tạo luồng.

**Đầu vào.** `{flowCode}`, `versionNo` (tùy chọn); nhịp phiên mỗi 30 giây.

**Luồng xử lý chính.**

1. Người dùng mở trình thiết kế. Nếu luồng có phiên bản mở và người dùng được sửa, trình thiết kế mở phiên bản đó ở chế độ sửa (không thấy luồng: ERR-04-001).
2. Trình duyệt gửi nhịp phiên (API-04-034) mỗi 30 giây. Máy chủ trả danh sách người khác đang có phiên trên cùng phiên bản. Giao diện hiển thị chỉ báo "Đang có {n} người khác mở luồng này" với tên và thời điểm. Đây là cảnh báo, không phải khóa cứng; xung đột thật được bắt bằng ETag khi lưu (FR-04-024).
3. Máy chủ trả `catalogVersion` mà định nghĩa được kiểm tra; nếu khác `catalogVersion` hiện hành của tenant (vì nền tảng vừa nâng runtime), giao diện hiển thị dải "Danh mục thành phần đã cập nhật lên {phiên bản}. Kiểm tra lại luồng trước khi gửi duyệt" và chạy lại kiểm tra (FR-04-081).
4. Nếu trình duyệt còn bản nháp cục bộ chưa lưu lên máy chủ (FR-04-024 bước 5) mới hơn ETag máy chủ, giao diện hỏi khôi phục.

**Luồng thay thế.**

- Không có phiên bản mở: mở phiên bản đang chạy ở PROD (hoặc mới nhất) ở chế độ chỉ đọc, kèm hành động "Tạo phiên bản mới" (FR-04-011).
- Luồng đã gỡ: `200`, mở chỉ đọc.
- Không có quyền sửa: `200`, mở chỉ đọc, ẩn hành động sửa.

**Luồng ngoại lệ.**

- Không tìm thấy luồng: ERR-04-001 (404); "Không tìm thấy luồng, hoặc bạn không có quyền xem luồng này."

**Đầu ra.** `200`; định nghĩa của phiên bản mở (hoặc phiên bản được chọn ở chế độ chỉ đọc), bố cục sơ đồ, kết quả kiểm tra gần nhất, phiên bản catalog, danh sách người đang mở luồng, ETag phiên bản.

**Kết quả.** Người dùng làm việc trên đúng phiên bản, biết ai đang mở cùng và có cơ hội khôi phục phần chưa lưu.

**Hậu điều kiện.** Một phiên soạn thảo (EN-04-09) được tạo hoặc gia hạn cho người dùng, hết hạn sau 120 giây không có nhịp.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-016; BR-04-020.

**Màn hình, API.** UI-04-04; API-04-020, 024, 034.
:::

#### FR-04-011 · Tạo phiên bản mới từ phiên bản đã có

::: dac-ta
**Mục đích.** Cho kỹ sư bắt đầu sửa một luồng đã duyệt mà không động tới phiên bản đang chạy, thay việc sửa trực tiếp host, port, method trên agent của Bus cũ.

**Tác nhân, quyền.** IE (`PERM-04-update`, mức `EDIT`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-011 (thay thế).

**Tiền điều kiện.** Luồng không có phiên bản mở; luồng không `RETIRED`.

**Kích hoạt.** IE bấm "Tạo phiên bản mới" trên trình thiết kế ở chế độ chỉ đọc hoặc trên tab Phiên bản.

**Đầu vào.** `baseVersion` (mặc định phiên bản đang chạy ở PROD, nếu không có thì mới nhất); `Idempotency-Key`.

**Luồng xử lý chính.**

1. IE chọn phiên bản gốc và bấm "Tạo phiên bản mới".
2. Hệ thống kiểm tra luồng chưa có phiên bản mở (ERR-04-016) và phiên bản gốc tồn tại (ERR-04-004).
3. Hệ thống tạo phiên bản số kế tiếp ở `DRAFT`, sao chép định nghĩa, bố cục, ca kiểm thử liên kết của phiên bản gốc.
4. Hệ thống ghi kiểm toán và mở phiên bản mới ở chế độ sửa.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**

- Đã có phiên bản mở: ERR-04-016 (409); "Luồng đã có bản nháp v{n} do {user} tạo." kèm nút "Mở bản nháp".
- Phiên bản gốc không tồn tại: ERR-04-004 (404); "Không tìm thấy phiên bản v{n} của luồng này."
- Luồng đã gỡ: ERR-04-034 (409); "Luồng đã gỡ và chỉ còn để xem."

**Đầu ra.** `201` với phiên bản mới `DRAFT`, `baseVersionNo`.

**Kết quả.** IE có bản nháp mới để sửa trong khi phiên bản cũ vẫn chạy bình thường.

**Hậu điều kiện.** Phiên bản mới sao chép định nghĩa, bố cục, ca kiểm thử liên kết của phiên bản gốc.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: `INT_VERSION_CREATE`, phiên bản gốc.

**Quy tắc nghiệp vụ.** BR-04-016 (một phiên bản mở).

**Màn hình, API.** UI-04-04; API-04-021.
:::

#### FR-04-012 · Bảng thành phần theo danh mục được phép, tìm kiếm và lọc theo vai trò chặng

::: dac-ta
**Mục đích.** Cho kỹ sư tìm và kéo đúng thành phần Camel vào sơ đồ, chỉ trong số thành phần được phép, nhóm theo cách quen thuộc của Tooling cũ. Thay thanh Component thu gọn, mở rộng và bảy nhóm component cũ.

**Tác nhân, quyền.** `PERM-04-update`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-003, 004, 005, 006, 007, 008, 009, 010, 011, 012 · Mã repo: FR-D-011.

**Tiền điều kiện.** Trình thiết kế đang mở ở chế độ sửa; chỉ mục catalog của đúng `catalogVersion` đã tải.

**Kích hoạt.** IE mở ngăn bảng thành phần, gõ ô tìm, chọn tab, hoặc bấm `＋` trên cạnh để chèn chặng.

**Đầu vào.** Từ khóa tìm, loại (tab), nhãn, vai trò chặng đang chèn (`from` hay bước giữa).

**Luồng xử lý chính.**

1. Trình duyệt tải chỉ mục catalog (API-04-070) một lần và lưu đệm theo `catalogVersion`.
2. Hệ thống lọc theo chính sách được phép của tenant (quy tắc 2) và theo vai trò chặng đang chèn (quy tắc 6).
3. IE gõ tìm; giao diện xếp kết quả theo quy tắc 5 trong ≤ 50 ms mỗi lần gõ.
4. IE kéo thành phần vào sơ đồ; với thành phần "cần kết nối PH-05" giao diện mở ngay ô chọn kết nối (FR-04-016).

**Luồng thay thế.** IE bấm "Đề xuất thành phần mới": giao diện mở yêu cầu tới PA theo FR-04-080 (API-04-074).

**Luồng ngoại lệ.**

- Thành phần đã có trong luồng nhưng sau đó bị cấm: vẫn hiện trên sơ đồ với huy hiệu "Không còn được phép" và lỗi kiểm tra ERR-04-011; "Thành phần "{component}" không được phép dùng trong tỉnh." kèm "Xem chính sách thành phần".
- Không tải được catalog: ERR-04-047 (503); "Danh mục thành phần tạm thời không tải được. Thử lại sau."

**Đầu ra.** Danh sách thành phần có tên Camel, tiêu đề tiếng Việt (nếu có), mô tả gốc, nhãn, biểu tượng nhóm, mức hỗ trợ (`stable`, `preview`, `deprecated`), mức native, cờ "cần kết nối PH-05", cờ "Kamelet tự viết của tenant".

**Kết quả.** IE tìm được thành phần cần trong vài lần gõ và chỉ thấy thứ được phép dùng.

**Hậu điều kiện.** Không.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-014; BR-04-020.

**Màn hình, API.** UI-04-04 bảng thành phần; API-04-070, 071, 074.
:::

Quy tắc chức năng của bảng thành phần:

1. Nguồn dữ liệu là chỉ mục catalog của đúng phiên bản runtime (FR-04-081), giao xuống trình duyệt một lần và lưu bộ đệm theo `catalogVersion`. Repo hiện có 751 nút (323 component, 74 EIP, 252 Kamelet, 48 dataformat, 26 language, 21 entity, 7 load balancer); con số chính xác thay đổi theo phiên bản.
2. Chỉ hiện thành phần được phép theo chính sách (FR-04-080). Thành phần bị cấm không hiện; thành phần đã có trong luồng nhưng sau đó bị cấm vẫn hiện trên sơ đồ với huy hiệu "Không còn được phép" và lỗi kiểm tra `ERR-04-011`.
3. Tab theo loại: Dùng nhiều, Thành phần, Mẫu EIP, Kamelet, Định dạng dữ liệu, Ngôn ngữ biểu thức. Tab "Dùng nhiều" tính theo tần suất dùng trong các luồng của tenant 90 ngày gần nhất, tối đa 24 mục, cộng các mục do nền tảng ghim.
4. Nhóm hiển thị theo nghiệp vụ của Tooling cũ để người dùng quen thuộc: Định tuyến (EIP định tuyến), Chuyển đổi dữ liệu (XML, JSON, văn bản, JQ, ánh xạ), Kết nối CSDL, Mạng (HTTP, REST, SOAP, tệp, FTP, SFTP), Hàng đợi bản tin (Kafka nội bộ ưu tiên, sau đó AMQP, MQTT, JMS), Lập lịch, Bảo mật (mã hóa, ký, che dữ liệu). Mỗi thành phần có thể thuộc nhiều nhóm. Bảng ánh xạ nhãn gốc của catalog sang nhóm nghiệp vụ ở SDD §6.3.
5. Tìm kiếm trên tên Camel, tiêu đề, tiêu đề tiếng Việt, mô tả, nhãn, không dấu, không phân biệt hoa thường; khớp đúng tên xếp trước, khớp tiền tố tiếp theo, khớp mô tả sau cùng. Thời gian phản hồi mỗi lần gõ ≤ 50 ms (NFR-04-002).
6. Khi người dùng chèn chặng đầu của route, chỉ hiện thành phần dùng được làm điểm vào (`consumer` hoặc Kamelet `source`). Khi chèn bước giữa, ẩn thành phần chỉ có chiều vào. Khi đang soạn Pipe, chỉ hiện Kamelet đúng loại (`source`, `action`, `sink`) cho vị trí đó.
7. Thành phần có cờ "cần kết nối PH-05" (CSDL, FTP, SFTP, LDAP, MQ ngoài, HTTP tới HTTT ngoài) khi kéo vào sơ đồ mở ngay ô chọn kết nối (FR-04-016) thay vì để người dùng nhập máy chủ, cổng, mật khẩu như Tooling cũ.
8. Không có chức năng nhập thành phần từ JAR hay sửa `pom.xml` (LGC-TOOL-022, 027 bị loại bỏ). Nút "Đề xuất thành phần mới" mở yêu cầu tới PA theo FR-04-080.

#### FR-04-013 · Thao tác trên sơ đồ: thêm, chèn, xóa, nối, rẽ nhánh, chọn nhiều, thu phóng, tự sắp xếp, hoàn tác

::: dac-ta
**Mục đích.** Cho kỹ sư dựng và sửa luồng trực quan bằng chuột hoặc bàn phím, với các thao tác quen thuộc của Tooling cũ (chèn ngang, dọc, Clear Page, thu phóng, bắt kết nối khi thả) và luôn giữ sơ đồ hợp lệ theo ngữ nghĩa Camel.

**Tác nhân, quyền.** `PERM-04-update` (chế độ sửa).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-013, 017, 018, 023, 024, 025 · Mã repo: FR-D-012.

**Tiền điều kiện.** Trình thiết kế mở ở chế độ sửa trên phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`.

**Kích hoạt.** IE kéo thả, bấm `＋` trên cạnh, dùng phím tắt (`Enter`, `Delete`, `Ctrl+D`, `Ctrl+Z`, `0`) hoặc menu chuột phải trên sơ đồ.

**Đầu vào.** Thao tác và đối tượng (chặng, cạnh, nhánh, tập chọn) theo bảng thao tác của FR-04-013 dưới đây.

**Luồng xử lý chính.**

1. IE thực hiện một thao tác trên sơ đồ.
2. Trình thiết kế kiểm tra thao tác hợp lệ theo ngữ nghĩa Camel (một chặng thường có đúng một chặng sau; nhánh chỉ tạo bằng chặng rẽ nhánh); không hợp lệ thì không cho thả và hiện gợi ý tại chỗ.
3. Trình thiết kế cập nhật cây tài nguyên, sinh lại YAML (FR-04-017) và ghi một bước hoàn tác.
4. Trình thiết kế chạy kiểm tra phía trình duyệt (FR-04-023) và cập nhật huy hiệu lỗi trên chặng.

**Luồng thay thế.** Thao tác có hậu quả lớn (thay chặng đã cấu hình, xóa chặng rẽ nhánh, "Xóa nội dung route") hỏi xác nhận trước bước 3; người dùng hủy thì không đổi gì.

**Luồng ngoại lệ.** Không có mã lỗi máy chủ: mọi thao tác chỉ đổi cây tài nguyên trong trình duyệt; lỗi phát sinh khi lưu theo FR-04-024. Sơ đồ vượt giới hạn hiệu năng (NFR-04-003, 004) không chặn thao tác.

**Đầu ra.** Cây tài nguyên Camel trong bộ nhớ trình duyệt và YAML sinh lại sau mỗi thay đổi.

**Kết quả.** Sơ đồ phản ánh ngay thay đổi, có thể hoàn tác ít nhất 100 bước.

**Hậu điều kiện.** Chưa lưu lên máy chủ; chỉ báo trạng thái chuyển "Chưa lưu".

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-006; BR-04-007.

**Màn hình, API.** UI-04-04 canvas; không gọi API (lưu qua API-04-022).
:::

| Thao tác | Quy tắc |
|---|---|
| Thêm chặng | Kéo từ bảng thành phần thả lên sơ đồ; thả lên cạnh thì chèn giữa hai chặng; thả lên chặng thì thay chặng (có xác nhận nếu chặng cũ đã cấu hình); thả vào vùng trống của một nhánh thì nối cuối nhánh. Có cách thêm không cần kéo: chọn chặng rồi nhấn `Enter` trên thành phần trong bảng, hoặc nút `＋` trên cạnh (WCAG 2.5.7) |
| Chèn ngang, dọc | Chèn sau chặng đang chọn trên cùng nhánh (ngang) hoặc thêm nhánh mới cho chặng rẽ nhánh `choice`, `multicast`, `doTry`, `loadBalance` (dọc) |
| Xóa chặng | Xóa chặng và nối chặng trước với chặng sau. Xóa chặng rẽ nhánh hỏi "Xóa cả các nhánh con ({n} chặng)?" |
| Nối, bỏ nối | Kéo từ cổng ra tới cổng vào. Sơ đồ Camel là cây có thứ tự, nên chỉ cho nối hợp lệ theo ngữ nghĩa Camel: một chặng thường có đúng một chặng sau; nhánh chỉ tạo bằng chặng rẽ nhánh. Thả dây ra vùng trống mở bảng thành phần để chọn chặng mới (LGC-TOOL-024 "bắt kết nối khi thả") |
| Chọn nhiều | Kéo vùng quét, `Shift`+bấm; thao tác xóa, nhân bản, nhóm áp cho tập chọn liên tiếp trên cùng nhánh |
| Nhân bản | `Ctrl+D` nhân bản chặng hoặc đoạn chặng đang chọn, đặt `id` mới |
| Xóa toàn bộ | "Xóa nội dung route" (Clear Page của Tooling cũ) giữ chặng đầu, xóa mọi chặng sau, có xác nhận và hoàn tác được |
| Thu phóng | 10%…400%; vừa khung (`0`); minimap tự hiện khi sơ đồ có trên 20 chặng |
| Tự sắp xếp | Sắp trái sang phải theo thứ tự luồng (dagre); giữ vị trí chặng người dùng đã ghim |
| Nhiều route | Một tệp có nhiều route; thanh thực thể (bố trí ở D03-06-PH04 §10.5) liệt kê route, `routeConfiguration`, `rest`, `beans`; chuyển qua lại giữ nguyên vị trí và mức thu phóng từng sơ đồ (Mã repo FR-D-005) |
| Hoàn tác, làm lại | Ít nhất 100 bước trong phiên; gộp các thay đổi liên tiếp trên cùng một trường trong 1 giây thành một bước |
| Nhóm chặng | Khối chặng chuẩn (mục 4.6) hiển thị như nhóm có tiêu đề, thu gọn hoặc mở rộng được |

: Thao tác trên sơ đồ của FR-04-013

Mọi thao tác chỉ đổi cây tài nguyên trong trình duyệt; lưu lên máy chủ theo FR-04-024. Giới hạn hiệu năng ở NFR-04-003, 004.

#### FR-04-014 · Cấu hình chặng bằng biểu mẫu sinh từ catalog, khôi phục giá trị gốc

::: dac-ta
**Mục đích.** Cho kỹ sư cấu hình tham số của từng chặng bằng biểu mẫu sinh tự động từ lược đồ của thành phần, không phải nhớ cú pháp URI, và khôi phục được giá trị gốc như thanh Properties của Tooling cũ.

**Tác nhân, quyền.** `PERM-04-update`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-019, 020 · Mã repo: FR-D-020, 021, 022, 023, FR-04-037 (repo).

**Tiền điều kiện.** Một chặng hoặc route đang được chọn; lược đồ thành phần của `catalogVersion` hiện hành đã tải (API-04-071).

**Kích hoạt.** IE chọn chặng trên sơ đồ (Inspector) hoặc bấm "Mở rộng" để mở UI-04-05.

**Đầu vào.** Chặng đang chọn; lược đồ JSON của thành phần ở phiên bản catalog hiện hành; giá trị IE nhập.

**Luồng xử lý chính.**

1. IE chọn chặng; trình thiết kế sinh biểu mẫu theo quy tắc 1–4.
2. IE nhập hoặc chọn giá trị.
3. Trình thiết kế kiểm tra tại chỗ (quy tắc 5) và báo lỗi dưới trường, tổng số lỗi ở chân biểu mẫu và trên huy hiệu của chặng.
4. Trình thiết kế ghi giá trị vào cây tài nguyên (bỏ giá trị bằng mặc định theo quy tắc 7) và sinh lại YAML.

**Luồng thay thế.** IE bấm "Khôi phục giá trị gốc" hoặc "Đặt về mặc định" (quy tắc 6); chọn route thay vì chặng để cấu hình thuộc tính route (quy tắc 8).

**Luồng ngoại lệ.** Lỗi kiểm tra tại chỗ không có mã máy chủ; khi lưu, lỗi lược đồ hiện là phát hiện VR-02 trong bảng Vấn đề (ERR-04-009 khi chặn gửi duyệt). Trường bí mật nhận chuỗi giống bí mật: VR-03, ERR-04-010 (422); "Phát hiện giá trị giống bí mật ở chặng "{node}", trường "{field}". Không được ghi bí mật vào luồng." kèm nút "Chọn kết nối".

**Đầu ra.** Giá trị tham số của chặng trên cây tài nguyên.

**Kết quả.** Chặng được cấu hình đúng lược đồ, lỗi hiện ngay tại trường.

**Hậu điều kiện.** Cây tài nguyên đổi, chưa lưu lên máy chủ.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-003; BR-04-006.

**Màn hình, API.** UI-04-04 Inspector, UI-04-05; API-04-071.
:::

Quy tắc chức năng của biểu mẫu cấu hình chặng:

1. Biểu mẫu sinh từ lược đồ của thành phần (thuộc tính đường dẫn URI, thuộc tính truy vấn, thuộc tính của EIP). Thuộc tính được nhóm theo nhóm gốc của catalog (`common`, `producer`, `consumer`, `security`, `scheduler`, `advanced` và các nhóm khác nếu có); tab đầu mở sẵn là nhóm có trường bắt buộc.
2. Mặc định chỉ hiện trường bắt buộc và trường đã có giá trị; nút "Hiện tất cả ({n})" mở phần còn lại. Có ô tìm trường xuyên các nhóm.
3. Điều khiển theo kiểu: `enum` dùng hộp chọn có mô tả từng giá trị; `boolean` dùng công tắc hiện giá trị mặc định; số dùng ô số có biên; `duration` dùng ô số kèm đơn vị; chuỗi là biểu thức dùng trình soạn biểu thức (FR-04-015); trường bí mật dùng ô chọn kết nối hoặc tham chiếu bí mật (FR-04-016), không có ô nhập tự do; `object`, `array` dùng bảng khóa–giá trị.
4. Mỗi trường hiện tiêu đề, mô tả gốc, giá trị mặc định, tên tham số Camel, dấu bắt buộc, cảnh báo `deprecated`.
5. Kiểm tra tại chỗ: sai kiểu, thiếu bắt buộc, ngoài `enum`, sai mẫu báo ngay dưới trường; tổng số lỗi hiện ở chân biểu mẫu và trên huy hiệu của chặng.
6. "Khôi phục giá trị gốc" (LGC-TOOL-020) có hai mức: khôi phục một trường về giá trị khi mở biểu mẫu, và khôi phục toàn chặng về giá trị trong phiên bản đã lưu gần nhất. "Đặt về mặc định" xóa giá trị để Camel dùng mặc định của thành phần.
7. Giá trị bằng mặc định không được ghi vào YAML (giữ YAML gọn), trừ khi người dùng ghim "luôn ghi".
8. Thuộc tính route (mã route, mô tả, `autoStartup`, `routePolicy`, `group`) cấu hình ở Inspector khi chọn route, đáp ứng "thuộc tính theo route" của LGC-TOOL-019.
9. Chặng có thể được đặt tên hiển thị tiếng Việt (`description` của EIP) và mã `id`; mã `id` duy nhất trong tệp, mẫu `^[a-zA-Z][a-zA-Z0-9-_]{0,63}$`.

#### FR-04-015 · Trình soạn biểu thức có gợi ý, kiểm tra cú pháp và xem trước trên bản tin mẫu

::: dac-ta
**Mục đích.** Cho kỹ sư viết biểu thức (`simple`, `jq`, `jsonpath`…) có gợi ý, kiểm tra cú pháp bằng đúng engine của runtime và xem trước kết quả trên bản tin mẫu, để phát hiện lỗi trước khi chạy thử.

**Tác nhân, quyền.** `PERM-04-update`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-031 (repo), FR-04-036 (repo).

**Tiền điều kiện.** Trường đang soạn có kiểu biểu thức; có bản tin mẫu ghim (FR-04-022) nếu muốn xem trước.

**Kích hoạt.** IE bấm vào trường biểu thức ở Inspector hoặc mở UI-04-06.

**Đầu vào.** Ngôn ngữ (`simple`, `constant`, `header`, `exchangeProperty`, `jq`, `jsonpath`, `xpath`, `xquery`, `groovy` nếu được phép), biểu thức, bản tin mẫu ghim (FR-04-022).

**Luồng xử lý chính.**

1. IE gõ biểu thức; giao diện gợi ý tự động theo ngôn ngữ: với `simple` gợi ý `${body}`, `${header.*}`, `${exchangeProperty.*}`, hàm có sẵn; với `jq`, `jsonpath` gợi ý đường dẫn trường lấy từ bản tin mẫu; với mọi ngôn ngữ gợi ý biến cấu hình `{{...}}` của môi trường (FR-04-084) và tiêu đề chuẩn `dh-*`.
2. Sau 400 ms kể từ lần gõ cuối, giao diện gửi biểu thức tới máy chủ (API-04-032); máy chủ kiểm tra cú pháp bằng engine Camel thật của đúng phiên bản runtime và trả vị trí dòng, cột khi lỗi (ERR-04-037).
3. IE bấm "Xem trước"; máy chủ chạy biểu thức trên bản tin mẫu ở sandbox (bản tin vượt giới hạn: ERR-04-021) và trả kết quả.
4. IE bấm "Áp dụng"; biểu thức được gán cho trường.

**Luồng thay thế.** Sandbox không sẵn sàng: giao diện được phép đánh giá cục bộ cho `simple` cơ bản, `jsonpath` và `jq`, và **bắt buộc** gắn nhãn "Xem trước mô phỏng trên trình duyệt, kết quả có thể khác runtime" (GAP-04-09). Ngôn ngữ kịch bản tùy ý (`groovy`, `js`, `python`) mặc định không được phép (ADR-062); chỉ hiện khi PA cho phép trong chính sách thành phần của tenant.

**Luồng ngoại lệ.**

- Biểu thức không biên dịch được: ERR-04-037 (422 ở chế độ chặt; chế độ thường trả `200` `valid = false`); "Biểu thức {language} có lỗi ở vị trí {pos}: {message}" và tô vị trí.
- Bản tin mẫu vượt kích thước: ERR-04-021 (413); "Bản tin mẫu vượt {limit}."
- Sandbox không sẵn sàng (xem trước máy chủ): ERR-04-019 (503); "Môi trường chạy thử đang bận hoặc chưa sẵn sàng (tỉnh đang có {n}/{max} lần chạy thử đồng thời). Thử lại sau ít phút."

**Đầu ra.** Biểu thức gán cho trường; kết quả xem trước; lỗi cú pháp.

**Kết quả.** IE biết biểu thức đúng hay sai và cho ra giá trị gì trước khi chạy thử cả luồng.

**Hậu điều kiện.** Cây tài nguyên đổi khi áp dụng; không lưu kết quả xem trước.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-014 (ngôn ngữ được phép).

**Màn hình, API.** UI-04-06; API-04-032.
:::

#### FR-04-016 · Chọn kết nối PH-05 và tham chiếu bí mật thay vì nhập bí mật

::: dac-ta
**Mục đích.** Bảo đảm luồng không bao giờ chứa mật khẩu, khóa: kỹ sư chọn kết nối đã khai báo ở PH-05 thay vì nhập máy chủ, cổng, mật khẩu như Tooling cũ.

**Tác nhân, quyền.** `PERM-04-update`; kết nối phải được cấp cho không gian làm việc của luồng ở PH-05.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04, REQ-05; LGC-TOOL-008; LGC-BUS-041 · Mã repo: FR-04-032 (repo), BR-D-02.

**Tiền điều kiện.** Chặng dùng thành phần có cờ "cần kết nối PH-05".

**Kích hoạt.** IE kéo thành phần cần kết nối vào sơ đồ (ô chọn mở tự động) hoặc bấm ô "Kết nối" trong biểu mẫu chặng.

**Đầu vào.** Loại kết nối cần (theo thành phần), mã kết nối.

**Luồng xử lý chính.**

1. Giao diện liệt kê kết nối PH-05 đúng loại (ví dụ `jdbc-postgresql`, `sftp`, `http-basic`, `oauth2-client`) được cấp cho không gian làm việc, kèm môi trường có giá trị (TEST, STAGING, PROD). Kết nối thiếu giá trị ở PROD được đánh dấu "Chưa sẵn sàng cho PROD".
2. IE chọn kết nối; trình thiết kế điền các tham số không bí mật (máy chủ, cổng, cơ sở dữ liệu) dưới dạng tham chiếu `{{conn:<mã>.<khóa>}}`, không chép giá trị. Người dùng không xem được giá trị bí mật.
3. Với CSDL, ô chọn chỉ hiện kết nối loại "chỉ đọc cho luồng" (FR-04-072); kết nối có quyền ghi chỉ hiện khi kết nối đó ở PH-05 được duyệt cho mục đích ghi và luồng đó.
4. Trình kiểm tra hợp lệ (FR-04-023, VR-07) báo ERR-04-013 khi luồng tham chiếu kết nối không tồn tại, không cấp cho không gian làm việc, hoặc sai loại.

**Luồng thay thế.** IE bấm "Tạo kết nối mới": giao diện mở luồng khai báo kết nối của PH-05 trong tab mới; trình thiết kế làm mới danh sách khi quay lại.

**Luồng ngoại lệ.**

- Kết nối không hợp lệ: ERR-04-013 (422 khi chặn gửi duyệt); "Kết nối "{connection}" không tồn tại, sai loại hoặc chưa được cấp cho không gian làm việc." kèm "Chọn kết nối khác", "Mở PH-05".
- PH-05 không sẵn sàng: ERR-04-047 (503); ô chọn hiện "Chưa lấy được danh sách kết nối từ PH-05. Thử lại sau."; luồng đang chạy không ảnh hưởng.

**Đầu ra.** Tham chiếu `{{conn:<mã>.<khóa>}}` trong tham số của chặng; tiêu đề hiển thị tên kết nối và trạng thái kiểm tra kết nối gần nhất.

**Kết quả.** Chặng dùng kết nối đã được kiểm tra ở PH-05; định nghĩa luồng không có bí mật.

**Hậu điều kiện.** Cây tài nguyên chứa tham chiếu kết nối; chưa lưu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (chọn kết nối ghi qua kiểm toán lưu nháp của FR-04-024).

**Quy tắc nghiệp vụ.** BR-04-003; BR-04-015.

**Màn hình, API.** UI-04-05; API-05-014 (xác minh tham chiếu của PH-05).
:::

#### FR-04-017 · Đồng bộ hai chiều giữa sơ đồ, thuộc tính và YAML, không mất dữ liệu khi quay vòng

::: dac-ta
**Mục đích.** Cho người dùng chuyển qua lại giữa sơ đồ và YAML mà không bao giờ mất nội dung, kể cả phần trình thiết kế chưa biểu diễn được. Thay tab Source đồng bộ hai chiều của Tooling cũ.

**Tác nhân, quyền.** `PERM-04-update` (sửa YAML), `PERM-04-read` (xem).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-021, 026 · Mã repo: BR-D-04, BR-D-04b.

**Tiền điều kiện.** Trình thiết kế đang mở.

**Kích hoạt.** Người dùng chọn chế độ Sơ đồ, YAML hoặc Chia đôi; sửa trên một trong hai phía.

**Đầu vào.** Thay đổi trên sơ đồ, Inspector hoặc văn bản YAML.

**Luồng xử lý chính.**

1. Trình thiết kế có ba chế độ: Sơ đồ, YAML, Chia đôi. Chuyển chế độ không mất dữ liệu.
2. Sửa trên sơ đồ hoặc Inspector: trình thiết kế sinh lại YAML trong ≤ 100 ms (NFR-04-005).
3. Sửa YAML: sau 500 ms không gõ, trình thiết kế phân tích YAML; hợp lệ thì cập nhật sơ đồ, giữ vị trí các chặng có `id` không đổi.
4. Trình thiết kế giữ quay vòng không mất dữ liệu theo quy tắc ở dưới (BR-04-006).

**Luồng thay thế.** Phần tử YAML mà trình thiết kế không biểu diễn được trên sơ đồ (ví dụ cú pháp ngắn lạ, khóa không có trong lược đồ) hiện trên sơ đồ như chặng "Không biểu diễn được", chỉ sửa được trong YAML, và không bị xóa khi sửa phần khác.

**Luồng ngoại lệ.** YAML lỗi cú pháp: hiện lỗi tại dòng và ở bảng Vấn đề, sơ đồ giữ trạng thái hợp lệ gần nhất kèm dải "YAML đang có lỗi, sơ đồ hiển thị phiên bản hợp lệ gần nhất"; khi lưu lên máy chủ trả ERR-04-008 (422) "YAML có lỗi cú pháp ở dòng {line}, cột {column}: {message}" kèm "Nhảy tới dòng".

**Đầu ra.** Sơ đồ, Inspector và YAML luôn biểu diễn cùng một cây tài nguyên.

**Kết quả.** Người dùng sửa ở phía nào cũng thấy phía kia cập nhật, mở rồi lưu không làm đổi luồng.

**Hậu điều kiện.** Bố cục sơ đồ (vị trí, ghi chú dán, trạng thái thu gọn nhóm) lưu riêng (mục 4.4), không làm bẩn YAML.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-006; BR-04-007.

**Màn hình, API.** UI-04-04 chế độ YAML, Chia đôi; API-04-031 (kiểm tra YAML chưa lưu).
:::

Quy tắc quay vòng không mất dữ liệu (BR-04-006): mở YAML rồi lưu không thay đổi phải cho YAML chuẩn hóa có cùng băm với YAML chuẩn hóa ban đầu. Biểu thức, khối lồng (`doTry`, `doCatch`, `doFinally`, `choice`, `multicast`, `split`, `loadBalance`, `circuitBreaker`, `saga`), chú thích dòng, thứ tự khóa không biết (khóa của phiên bản Camel mới hơn catalog) phải được giữ.

#### FR-04-018 · Soạn Kamelet và gửi đăng ký Kamelet tự viết

::: dac-ta
**Mục đích.** Cho tỉnh tự đóng gói một cách kết nối hoặc xử lý dùng lại thành Kamelet YAML có tham số khai báo, thay cho việc nạp component từ JAR (LGC-TOOL-027 đã loại bỏ).

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04, REQ-05 · Mã repo: FR-D-061, FR-D-062.

**Tiền điều kiện.** Luồng loại `KAMELET` đã tạo (FR-04-003).

**Kích hoạt.** IE mở luồng loại `KAMELET` trên UI-04-08.

**Đầu vào.** `metadata.name` (mẫu `^[a-z][a-z0-9-]{2,62}-(source|sink|action)$`), nhãn `camel.apache.org/kamelet.type`; `spec.definition` gồm tiêu đề, mô tả, danh sách tham số (tên, tiêu đề, kiểu, mặc định, bắt buộc, mô tả, `x-descriptors`); `spec.dataTypes`; `spec.template` (một route bắt đầu bằng `kamelet:source`).

**Luồng xử lý chính.**

1. IE khai tên, loại, tham số và template.
2. Trình thiết kế giới hạn kiểu tham số theo dữ liệu thực tế của Kamelet gốc: `string`, `boolean`, `integer`, `binary`, `long`; không dùng `number` dù lược đồ cho phép (theo đếm trên 243 Kamelet đã vendor ở repo: `string` 1.256, `boolean` 316, `integer` 111, `binary` 9, `long` 1).
3. Hệ thống kiểm tra tham số nhạy cảm đánh dấu `x-descriptors: urn:camel:group:credentials` và chỉ nhận tham chiếu kết nối, không nhận giá trị (VR-15); tên không trùng (ERR-04-036).
4. IE lưu, chạy thử, gửi duyệt như luồng thường (nhóm C, D).
5. Khi Kamelet được phát hành trong tenant, nó xuất hiện đầu tab Kamelet của bảng thành phần với huy hiệu "Của tỉnh".

**Luồng thay thế.** Muốn dùng chung toàn quốc: IE gửi đăng ký qua quy trình đăng ký Kamelet của PH-05 (duyệt bởi PA và SO).

**Luồng ngoại lệ.**

- Tên trùng Kamelet nền hoặc Kamelet tự viết khác trong tenant: ERR-04-036 (409); "Đã có Kamelet tên "{name}"."
- Tham số nhạy cảm nhận giá trị thật: ERR-04-010 (422); "Phát hiện giá trị giống bí mật ở chặng "{node}", trường "{field}". Không được ghi bí mật vào luồng."

**Đầu ra.** Luồng loại `KAMELET`.

**Kết quả.** Tỉnh có khối dùng lại của riêng mình, đã qua duyệt, kéo vào được ở mọi luồng của tỉnh.

**Hậu điều kiện.** Phiên bản Kamelet ở `DRAFT` cho tới khi được duyệt, phát hành.

**Sự kiện phát ra.** Theo nhóm D khi gửi duyệt, phát hành.

**Kiểm toán.** Có: như lưu nháp FR-04-024.

**Quy tắc nghiệp vụ.** BR-04-003; BR-04-014.

**Màn hình, API.** UI-04-08; API-04-011, 022; PH-05 đăng ký Kamelet.
:::

#### FR-04-019 · Soạn Pipe

::: dac-ta
**Mục đích.** Cho kỹ sư dựng nhanh tích hợp một chiều đơn giản bằng cách nối Kamelet nguồn, các bước, Kamelet đích, thay các chương trình Bus cũ chỉ chuyển dữ liệu một chiều; ví dụ đọc tệp SFTP định kỳ rồi đẩy lên Kafka.

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04 · Mã repo: FR-D-063.

**Tiền điều kiện.** Luồng loại `PIPE` đã tạo.

**Kích hoạt.** IE mở luồng loại `PIPE` trên UI-04-09.

**Đầu vào.** `source` (Kamelet loại source hoặc tham chiếu topic), `steps[]` (Kamelet loại action), `sink`, `errorHandler`.

**Luồng xử lý chính.**

1. IE chọn nguồn, thêm các bước, chọn đích.
2. Trình thiết kế khóa thao tác rẽ nhánh (sơ đồ Pipe là tuyến tính); bảng thành phần chỉ hiện Kamelet đúng vị trí.
3. IE cấu hình tham số của từng Kamelet bằng biểu mẫu sinh từ `spec.definition`.
4. Hệ thống kiểm tra Pipe chỉ dùng Kamelet đúng loại (VR-15) khi lưu.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.** Kamelet sai loại ở vị trí: phát hiện VR-15 mức `ERROR`, chặn gửi duyệt với ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt."

**Đầu ra.** Luồng loại `PIPE`.

**Kết quả.** Tích hợp một chiều được dựng không cần viết route.

**Hậu điều kiện.** Phiên bản `DRAFT` được cập nhật khi lưu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: như lưu nháp FR-04-024.

**Quy tắc nghiệp vụ.** BR-04-008 (`errorHandler` có DLQ).

**Màn hình, API.** UI-04-09; API-04-022.
:::

#### FR-04-020 · Trình ánh xạ dữ liệu sinh biểu thức JQ

::: dac-ta
**Mục đích.** Cho kỹ sư ánh xạ trường nguồn sang trường đích bằng kéo nối thay vì viết tay, sinh biểu thức JQ chạy được ở runtime, kèm chuyển mã qua bảng ánh xạ PH-07. Thay data mapping có nhập tài liệu mẫu của Tooling.

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-007, 028; LGC-BUS-036 · Mã repo: FR-D-083, 084, 085.

**Tiền điều kiện.** Có lược đồ hoặc tài liệu mẫu cho nguồn và đích.

**Kích hoạt.** IE thêm chặng `transform` và bấm "Mở trình ánh xạ" (UI-04-07).

**Đầu vào.** Lược đồ nguồn và đích: JSON Schema, XSD (chuyển sang cây trường), OpenAPI của API PH-02, lược đồ topic Apicurio, lược đồ CDM, hoặc suy ra từ tài liệu mẫu JSON, XML; danh sách ánh xạ.

**Luồng xử lý chính.**

1. IE chọn lược đồ hoặc nhập tài liệu mẫu (quy tắc 1); hệ thống dựng cây trường nguồn, đích (tài liệu vượt 1 MiB: ERR-04-021).
2. IE nối trường và chọn hàm (quy tắc 2, 3).
3. Trình ánh xạ sinh biểu thức JQ và kiểm tra ánh xạ (đích không tồn tại, vòng tham chiếu: ERR-04-038).
4. IE bấm "Xem trước"; hệ thống chạy JQ thật trên sandbox (API-04-033) với bản tin mẫu (quy tắc 4).
5. IE bấm "Áp dụng"; chặng nhận biểu thức JQ, tệp `*.dhmap.json` lưu cùng phiên bản.

**Luồng thay thế.**

- Xuất, đặt lại ánh xạ theo quy tắc 5; không có sandbox thì xem trước theo quy tắc nhãn ở FR-04-015.
- Ánh xạ một–nhiều chưa làm ở MVP (quy tắc 7).

**Luồng ngoại lệ.**

- Ánh xạ tới trường đích không tồn tại, vòng tham chiếu: ERR-04-038 (422); "Ánh xạ tới trường "{target}" không hợp lệ: {reason}"
- Tài liệu mẫu vượt 1 MiB: ERR-04-021 (413); "Bản tin mẫu vượt {limit}."

**Đầu ra.** Một chặng `transform` (hoặc `setBody`) với biểu thức `jq` sinh ra; tệp mô tả ánh xạ `*.dhmap.json` lưu cùng phiên bản để mở lại trên trình ánh xạ.

**Kết quả.** IE có phép chuyển đổi đã xem trước đúng trên dữ liệu mẫu, mở lại sửa được bằng giao diện.

**Hậu điều kiện.** Cây tài nguyên và tệp ánh xạ của phiên bản mở được cập nhật khi lưu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (ghi qua lưu nháp FR-04-024).

**Quy tắc nghiệp vụ.** BR-04-007; tham số `04.mapping.require-all-required`.

**Màn hình, API.** UI-04-07; API-04-033.
:::

Quy tắc chức năng của trình ánh xạ:

1. Nhập tài liệu mẫu (LGC-TOOL-028): dán hoặc tải tệp JSON, XML ≤ 1 MiB; hệ thống suy ra cây trường với kiểu. Với XML, chặng ánh xạ tự thêm bước `unmarshal` XML sang JSON trước và `marshal` sau nếu đích là XML.
2. Ánh xạ một–một, nhiều–một (ghép), hằng số, giá trị mặc định khi nguồn rỗng, điều kiện (nếu–thì), lặp mảng (ánh xạ phần tử mảng nguồn sang phần tử mảng đích).
3. Thư viện hàm: chuỗi (cắt, hoa, thường, nối, tách, thay thế, chuẩn hóa không dấu), số (làm tròn, định dạng), ngày (đổi định dạng `dd/MM/yyyy` sang ISO, đổi múi giờ), kiểm tra rỗng, và **chuyển mã qua PH-07**: chọn bảng ánh xạ mã của PH-07 (ví dụ mã dân tộc của HTTT A sang mã chuẩn), sinh lời gọi hàm `dh_map("<bảng>"; .<trường>)` do runtime cung cấp, tra từ ảnh chụp trong bộ nhớ của PH-07 (ADR-053 của PH-07).
4. Xem trước chạy JQ thật trên sandbox (API-04-033); không có sandbox thì theo quy tắc nhãn ở FR-04-015.
5. "Xuất ánh xạ" tải tệp `*.dhmap.json` và tệp `*.jq`; "Đặt lại ánh xạ" xóa mọi ánh xạ (có hoàn tác).
6. Không nhúng AtlasMap hay DataMapper XSLT của Kaoto (ADR-066).
7. Ánh xạ một–nhiều (tách một nguồn ra nhiều đích khác cấu trúc) chưa làm ở MVP; người dùng viết tay JQ trong trình soạn biểu thức.

#### FR-04-021 · Bean, cấu hình cấp tệp và metadata

::: dac-ta
**Mục đích.** Cho kỹ sư khai báo bean, `routeConfiguration` và metadata cấp tệp bằng giao diện, chỉ trong phạm vi lớp đã được duyệt.

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04 · Mã repo: FR-D-008, FR-D-080, 081, 082.

**Tiền điều kiện.** Luồng đang mở ở chế độ sửa.

**Kích hoạt.** IE chọn mục `beans`, `routeConfiguration` hoặc metadata trên thanh thực thể, mở UI-04-10.

**Đầu vào.** `beans[]` (`name`, `type`, `properties`); `routeConfiguration` (`errorHandler`, `onException`, `intercept`, `onCompletion`); metadata (`name`, `labels`, `annotations`) cho Kamelet, Pipe.

**Luồng xử lý chính.**

1. IE thêm bean, chọn `type` từ danh sách lớp được phép trong hồ sơ runtime (thư viện nền `vn.datahub.runtime.*` và lớp chuẩn của Camel, Quarkus được PA duyệt); không nhập tên lớp tự do.
2. IE khai thuộc tính; bean không chứa bí mật (VR-03).
3. Trường của thành phần nhận bean hiện hộp chọn các bean đã khai.
4. Hệ thống kiểm tra lớp được phép (VR-04, ERR-04-011) khi gửi duyệt.

**Luồng thay thế.** IE sửa `routeConfiguration` cấp tệp thay vì dùng `dh-default-config`: VR-11 vẫn yêu cầu có DLQ tới PH-18.

**Luồng ngoại lệ.**

- Lớp bean không được phép: ERR-04-011 (422); "Thành phần "{component}" không được phép dùng trong tỉnh."
- Thuộc tính bean giống bí mật: ERR-04-010 (422).

**Đầu ra.** Phần tử cấp tệp trong YAML.

**Kết quả.** Cấu hình cấp tệp được khai báo an toàn, không mở đường nạp mã tùy ý.

**Hậu điều kiện.** Cây tài nguyên đổi, lưu theo FR-04-024.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (ghi qua lưu nháp).

**Quy tắc nghiệp vụ.** BR-04-003; BR-04-008; BR-04-014.

**Màn hình, API.** UI-04-10; API-04-022.
:::

#### FR-04-022 · Ghim bản tin mẫu theo chặng

::: dac-ta
**Mục đích.** Cho kỹ sư gắn bản tin mẫu vào chặng để xem trước biểu thức và ánh xạ ngay khi thiết kế, mà bản tin đó không bao giờ đi theo luồng ra môi trường chạy.

**Tác nhân, quyền.** IE (`PERM-04-update`); bỏ qua cảnh báo dữ liệu thật cần `PERM-04-sample-data`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-033 (repo), FR-D-024, BR-D-03.

**Tiền điều kiện.** Chặng đang chọn trong phiên bản mở.

**Kích hoạt.** IE bấm "Ghim bản tin mẫu" ở cột Vào của UI-04-05 hoặc ghim từ kết quả một lần chạy thử.

**Đầu vào.** Thân (JSON, XML, văn bản ≤ 256 KiB), tiêu đề, thuộc tính exchange giả lập.

**Luồng xử lý chính.**

1. IE dán hoặc tải bản tin mẫu.
2. Hệ thống kiểm tra kích thước (ERR-04-021).
3. Trình thiết kế quét dấu hiệu dữ liệu cá nhân thật (mẫu số định danh 12 chữ số, số điện thoại, thư điện tử) và cảnh báo, gợi ý thay bằng dữ liệu giả.
4. Hệ thống lưu bản tin mẫu cùng phiên bản ở cột riêng, **không** đi vào YAML đem triển khai.

**Luồng thay thế.** Chặng chưa ghim dùng bản tin mẫu của chặng trước gần nhất trên đường đi. Người có `PERM-04-sample-data` được bỏ qua cảnh báo dữ liệu thật.

**Luồng ngoại lệ.** Bản tin mẫu vượt 256 KiB: ERR-04-021 (413); "Bản tin mẫu vượt {limit}."

**Đầu ra.** Bản tin mẫu gắn với chặng, dùng cho xem trước biểu thức và ánh xạ.

**Kết quả.** IE xem trước được biểu thức và ánh xạ trên dữ liệu gần thật mà không lộ dữ liệu cá nhân.

**Hậu điều kiện.** Bản tin mẫu lưu cùng phiên bản, không có trong YAML chuẩn hóa và băm nội dung.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (ghi qua lưu nháp).

**Quy tắc nghiệp vụ.** BR-04-007; BR-04-013.

**Màn hình, API.** UI-04-05 cột Vào; API-04-022.
:::

#### FR-04-023 · Kiểm tra hợp lệ định nghĩa luồng

::: dac-ta
**Mục đích.** Là chốt chặn kỹ thuật bảo đảm luồng đúng lược đồ, không có bí mật, chỉ dùng thành phần được phép, đủ khung chín chặng và tuân thủ Q359 trước khi chạy thử, gửi duyệt hay phát hành.

**Tác nhân, quyền.** `PERM-04-update`; chạy tự động khi lưu, gửi duyệt, phát hành.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-027 (repo), FR-04-034 (repo), FR-D-023, BR-D-01, BR-D-05.

**Tiền điều kiện.** Có định nghĩa YAML (đã lưu hoặc chưa lưu).

**Kích hoạt.** Trình duyệt chạy sau mỗi thay đổi; máy chủ chạy khi lưu (`DESIGN`), gửi duyệt (`SUBMIT`), phát hành (`PUBLISH`); IE bấm "Kiểm tra" ở bảng Vấn đề.

**Đầu vào.** YAML, loại tài nguyên, mức nghiêm ngặt (`DESIGN`, `SUBMIT`, `PUBLISH`), môi trường đích (với `PUBLISH`).

**Luồng xử lý chính.**

1. Hệ thống phân tích YAML và kiểm tra hình dạng (VR-01; lỗi cú pháp: ERR-04-008).
2. Hệ thống chạy các quy tắc VR-02…20 theo bảng dưới, mỗi phát hiện có mức theo mức nghiêm ngặt đang chạy.
3. Hệ thống gắn mỗi phát hiện với `nodeId` để giao diện tô chặng và đưa người dùng tới đúng trường.
4. Hệ thống trả `valid = false` khi có phát hiện mức `ERROR`; ở `SUBMIT`, `PUBLISH` thao tác gọi bị chặn với ERR-04-009 hoặc mã riêng (ERR-04-010, 011, 012, 013, 031, 037, 038, 043).

**Luồng thay thế.** Kiểm tra chạy ở hai nơi: trình duyệt (bộ quy tắc VR-01…09, 15, 18, 20 bằng lược đồ đã tải) cho phản hồi tức thì, và máy chủ (toàn bộ) là chốt chặn có hiệu lực.

**Luồng ngoại lệ.**

- Còn lỗi: ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi {action}." kèm "Mở bảng Vấn đề".
- Bí mật viết thẳng: ERR-04-010 (422); "Phát hiện giá trị giống bí mật ở chặng "{node}", trường "{field}". Không được ghi bí mật vào luồng."
- Thành phần bị cấm: ERR-04-011 (422); "Thành phần "{component}" không được phép dùng trong tỉnh."
- Thiếu chặng chuẩn: ERR-04-012 (422); "Luồng đối ngoại phải có đủ chín chặng chuẩn. Đang thiếu: {stages}." kèm "Thêm chặng chuẩn còn thiếu".
- SQL vi phạm Q359: ERR-04-031 (422); "Câu lệnh SQL ở chặng "{node}" không được phép: {reason}. Luồng chỉ được đọc dữ liệu."
- HTTT nguồn, đích chưa kết nạp: ERR-04-043 (422); "HTTT "{system}" chưa được kết nạp hoặc chưa hoạt động ở danh mục HTTT."
- Phiên bản soạn trên catalog cũ: ERR-04-042 (409); "Luồng được soạn trên danh mục thành phần {old}, cũ hơn danh mục hiện hành {new}. Mở lại luồng để kiểm tra lại."

**Đầu ra.** `200`; `valid`, danh sách phát hiện `{code, severity ∈ ERROR, WARN, INFO, path, nodeId, message, ruleId}`.

**Kết quả.** Người dùng thấy danh sách vấn đề theo mức, bấm vào là tới đúng chặng, đúng trường.

**Hậu điều kiện.** Kết quả kiểm tra gần nhất lưu kèm phiên bản (khi chạy ở máy chủ).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (kết quả kiểm tra ghi kèm thao tác lưu, gửi duyệt, phát hành).

**Quy tắc nghiệp vụ.** BR-04-002, 003, 008, 009, 010, 011, 014, 015, 020.

**Màn hình, API.** UI-04-04 bảng Vấn đề; API-04-030, 031.
:::

| Quy tắc | Nội dung | DESIGN | SUBMIT | PUBLISH |
|---|---|---|---|---|
| VR-01 | YAML phân tích được, đúng hình dạng của loại tài nguyên | ERROR | ERROR | ERROR |
| VR-02 | Mọi phần tử, thuộc tính hợp lệ theo lược đồ catalog của phiên bản runtime (thiếu bắt buộc, sai kiểu, ngoài `enum`) | ERROR | ERROR | ERROR |
| VR-03 | Không có chuỗi giống bí mật viết thẳng; chỉ chấp nhận `{{conn:…}}`, `{{vault:…}}`, `#bean` (BR-04-003) | ERROR | ERROR | ERROR |
| VR-04 | Mọi thành phần, ngôn ngữ, dataformat được phép theo chính sách của tenant | WARN | ERROR | ERROR |
| VR-05 | Luồng đối ngoại có đủ chín chặng chuẩn theo thứ tự (BR-04-002) | WARN | ERROR | ERROR |
| VR-06 | Luồng nội bộ có đủ chín chặng | INFO | WARN | WARN |
| VR-07 | Tham chiếu kết nối tồn tại, đúng loại, được cấp cho không gian làm việc; ở `PUBLISH` có giá trị cho môi trường đích | WARN | ERROR | ERROR |
| VR-08 | Mã `id` chặng, mã route duy nhất trong tệp; không trùng route đang chạy của luồng khác trong namespace đích | ERROR | ERROR | ERROR |
| VR-09 | Tham chiếu nội bộ `direct:`, `seda:` trỏ tới route tồn tại (trong tệp hoặc luồng đã phát hành cùng tenant) | WARN | ERROR | ERROR |
| VR-10 | Topic Kafka đã đăng ký ở PH-10 và luồng có quyền publish, subscribe tương ứng (BR-04-009) | WARN | ERROR | ERROR |
| VR-11 | Có `routeConfiguration` xử lý lỗi nền hoặc `errorHandler` có DLQ tới PH-18 (BR-04-008) | WARN | ERROR | ERROR |
| VR-12 | Thành phần hỗ trợ native, hoặc luồng được gán hồ sơ JVM được phép (BR-04-014) | INFO | WARN | ERROR |
| VR-13 | Truy cập CSDL tuân thủ Q359: kết nối chỉ đọc, câu lệnh chỉ `SELECT`, `WITH`; không tham chiếu schema control; có đặt `app.tenant_id` (BR-04-015) | ERROR | ERROR | ERROR |
| VR-14 | Chặng `receive` đặt tiêu đề `dh-tenant` từ nguồn tin cậy; không đặt từ thân hay tiêu đề do bên gọi gửi (BR-04-010) | WARN | ERROR | ERROR |
| VR-15 | Kamelet có tham số nhạy cảm đánh dấu đúng; Pipe chỉ dùng Kamelet đúng loại | ERROR | ERROR | ERROR |
| VR-16 | Biểu thức biên dịch được | WARN | ERROR | ERROR |
| VR-17 | Định nghĩa được kiểm tra trên đúng phiên bản catalog hiện hành của tenant | INFO | ERROR | ERROR |
| VR-18 | Luồng có điểm vào HTTP thì đường dẫn không trùng luồng khác đang chạy cùng tenant | ERROR | ERROR | ERROR |
| VR-19 | Không dùng thành phần đọc tệp cục bộ, thực thi lệnh hệ điều hành (`exec`, `ssh` tới máy ngoài danh sách), trừ khi chính sách cho phép tường minh | ERROR | ERROR | ERROR |
| VR-20 | Ca kiểm thử (loại `TEST`) mỗi ca có ít nhất một khẳng định | ERROR | ERROR | ERROR |

: Quy tắc kiểm tra hợp lệ VR-01…20 theo mức nghiêm ngặt

#### FR-04-024 · Lưu bản nháp tự động, phát hiện xung đột, khôi phục phiên nháp

::: dac-ta
**Mục đích.** Bảo đảm công sức thiết kế không bị mất (tự lưu, lưu khi mất mạng) và không ai ghi đè âm thầm thay đổi của người khác. Thay lưu kết quả thiết kế và bảng `draft_session` của Tooling cũ.

**Tác nhân, quyền.** IE (`PERM-04-update`, mức `EDIT`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-TOOL-014, 029 · Mã repo: FR-D-013.

**Tiền điều kiện.** Phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`.

**Kích hoạt.** Trình duyệt tự lưu 30 giây sau thay đổi cuối; IE nhấn `Ctrl+S` hoặc bấm "Lưu".

**Đầu vào.** `definitionYaml`, `canvasLayout`, `samples`, `If-Match` (ETag phiên bản).

**Luồng xử lý chính.**

1. Trình duyệt tự lưu 30 giây sau thay đổi cuối nếu có thay đổi; `Ctrl+S` lưu ngay. Chỉ báo trạng thái: "Đã lưu {giờ}", "Chưa lưu", "Đang lưu…", "Lưu lỗi", "Chưa lưu lên máy chủ" (mất kết nối).
2. Máy chủ kiểm tra phiên bản ở trạng thái `DRAFT` hoặc `CHANGES_REQUESTED`; khác trả ERR-04-005. Đang đóng băng cả việc soạn (FR-04-084): ERR-04-041.
3. Máy chủ so ETag; không khớp trả ERR-04-006 kèm ETag hiện tại và người lưu gần nhất. Giao diện mở so sánh YAML ba bên (gốc chung, của tôi, của người kia) để người dùng chọn giữ bản nào hoặc gộp tay. Không bao giờ ghi đè âm thầm.
4. Máy chủ kiểm tra kích thước (ERR-04-033), chạy kiểm tra mức `DESIGN`, lưu định nghĩa và kết quả. Lỗi kiểm tra không chặn lưu.
5. Máy chủ tính lại chỉ mục route, endpoint và thêm người dùng vào danh sách người đóng góp.

**Luồng thay thế.**

- Mất kết nối: trình duyệt lưu bản nháp vào IndexedDB với khóa `dh.int.draft.{tenant}.{flow}.{version}` (thay bảng `draft_session` của Tooling cũ ở phía máy chủ bằng bộ đệm phía trình duyệt cho phần chưa đồng bộ), tự đồng bộ khi có lại kết nối. Dữ liệu cục bộ bị xóa khi lưu thành công hoặc khi người dùng đăng xuất.
- Rời trang khi còn thay đổi chưa lưu lên máy chủ: hỏi xác nhận.

**Luồng ngoại lệ.**

- Phiên bản không còn ở trạng thái sửa được: ERR-04-005 (409); "Phiên bản đang ở trạng thái "{status}" nên không thể lưu."
- ETag không khớp: ERR-04-006 (412); "{user} đã lưu phiên bản này lúc {time}. Thay đổi của bạn chưa được lưu." kèm hộp xung đột (D03-06-PH04 §10.16.3).
- Định nghĩa vượt kích thước: ERR-04-033 (413); "Định nghĩa luồng vượt {limit}. Tách thành nhiều luồng hoặc luồng con."
- Thay đổi đang bị đóng băng (FR-04-084): ERR-04-041 (423); "Đang trong khoảng đóng băng thay đổi tới {until}. Chỉ được quay lui hoặc tạm dừng khẩn."

**Đầu ra.** `200` với ETag mới, kết quả kiểm tra mức `DESIGN`, thời điểm lưu.

**Kết quả.** Thiết kế được lưu an toàn; khi hai người cùng sửa, người lưu sau được thấy rõ khác biệt để gộp.

**Hậu điều kiện.** Phiên bản mở được cập nhật; chỉ mục route, endpoint tính lại; người dùng được thêm vào danh sách người đóng góp.

**Sự kiện phát ra.** Không phát sự kiện cho từng lần lưu nháp.

**Kiểm toán.** Có: `INT_VERSION_SAVE` với băm trước và sau; gộp các lần lưu tự động của cùng người trong 10 phút thành một bản ghi kiểm toán.

**Quy tắc nghiệp vụ.** BR-04-005 (danh sách người đóng góp); BR-04-016; BR-04-022.

**Màn hình, API.** UI-04-04; API-04-022.
:::

#### FR-04-025 · Thư viện khuôn mẫu luồng

::: dac-ta
**Mục đích.** Cho kỹ sư bắt đầu từ khuôn mẫu đã chuẩn hóa cho các kiểu tích hợp thường gặp, để luồng mới đúng khung chín chặng và xử lý lỗi nền ngay từ đầu.

**Tác nhân, quyền.** Dùng: IE. Quản lý khuôn mẫu nền: PA (`PERM-04-catalog-admin`). Khuôn mẫu của tenant: TA.

**Mức ưu tiên, đợt.** S · Đợt 2; MVP có `tpl-standard-9`, `tpl-sync-lookup`, `tpl-db-poll-to-kafka` dựng sẵn.

**Truy vết.** REQ-04; LGC-BUS-013 · Mã repo: FR-04-030 (repo).

**Tiền điều kiện.** Với tạo khuôn của tỉnh: có phiên bản luồng đã duyệt.

**Kích hoạt.** IE mở UI-04-19 hoặc chọn "Từ khuôn mẫu" ở UI-04-03; TA bấm "Lưu thành khuôn mẫu" trên phiên bản đã duyệt.

**Đầu vào.** Khuôn mẫu: mã, tên, mô tả, loại tài nguyên, nhóm, định nghĩa có chỗ trống tham số `${tpl.<tên>}`, lược đồ JSON của tham số, ảnh minh họa sơ đồ.

**Luồng xử lý chính.**

1. IE duyệt danh sách khuôn mẫu theo nhóm, xem trước sơ đồ.
2. IE chọn "Dùng khuôn này", nhập tham số theo lược đồ.
3. Hệ thống kiểm tra khuôn tồn tại, được phép cho tenant (ERR-04-039) và tham số đúng lược đồ (ERR-04-049).
4. Hệ thống điền tham số và chuyển sang FR-04-003 với `origin = TEMPLATE`.

**Luồng thay thế.** TA tạo khuôn của tỉnh từ phiên bản đã duyệt (API-04-082) hoặc ngừng dùng khuôn của tỉnh.

**Luồng ngoại lệ.**

- Khuôn không tồn tại hoặc không được phép: ERR-04-039 (404); "Khuôn mẫu "{template}" không tồn tại hoặc không được phép dùng trong tỉnh."
- Tham số sai lược đồ: ERR-04-049 (400); lỗi hiện dưới từng ô tham số.

**Đầu ra.** Danh sách và chi tiết khuôn mẫu; định nghĩa đã điền tham số khi tạo luồng.

**Kết quả.** IE có luồng khởi đầu đúng chuẩn cho kiểu tích hợp cần làm.

**Hậu điều kiện.** Không đổi dữ liệu khi xem; tạo khuôn của tỉnh thêm một khuôn `ACTIVE`.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi tạo, ngừng dùng khuôn: mã khuôn, phiên bản nguồn.

**Quy tắc nghiệp vụ.** BR-04-002; BR-04-008.

**Màn hình, API.** UI-04-19, UI-04-03; API-04-080, 081, 082.
:::

| Mã | Tên | Dùng khi |
|---|---|---|
| `tpl-standard-9` | Khung chín chặng trống | Luồng đối ngoại bất kỳ |
| `tpl-sync-lookup` | Tra cứu đồng bộ REST → HTTT đích REST | Cổng DVC tra cứu dữ liệu của sở |
| `tpl-soap-to-rest` | Bọc dịch vụ SOAP cũ thành REST | Dịch vụ SOAP của hệ cũ |
| `tpl-db-poll-to-kafka` | Đọc định kỳ CSDL chỉ đọc → Kafka | Đồng bộ dữ liệu từ CSDL hệ cũ (Q359) |
| `tpl-kafka-to-rest` | Nhận sự kiện Kafka → gọi REST HTTT | Đẩy thông báo cho HTTT nhận |
| `tpl-sftp-to-kafka` | Đọc tệp SFTP định kỳ → tách dòng → Kafka | Tệp CSV trao đổi định kỳ |
| `tpl-ndxp-proxy` | Gọi dịch vụ quốc gia qua PH-14 | Tra cứu CSDL quốc gia |
| `tpl-cdm-normalize` | Chuẩn hóa về CDM có chuyển mã PH-07 | Dữ liệu dân cư, tổ chức |

: Bộ khuôn mẫu nền tối thiểu

#### FR-04-026 · Ghi chú dán và luồng con dùng lại

::: dac-ta
**Mục đích.** Cho kỹ sư ghi chú giải thích ngay trên sơ đồ và tách phần dùng chung thành luồng con, để luồng lớn dễ đọc và dễ bảo trì.

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** C (ghi chú), S (luồng con) · Đợt 2.

**Truy vết.** REQ-04 · Mã repo: FR-04-039, FR-04-040 (repo).

**Tiền điều kiện.** Trình thiết kế mở ở chế độ sửa; với luồng con ngoài tệp, luồng đích đã phát hành trong tenant.

**Kích hoạt.** IE chọn "Thêm ghi chú" trên menu sơ đồ hoặc kéo chặng gọi `direct:` và chọn luồng con.

**Đầu vào.** Ghi chú: văn bản Markdown giới hạn (đậm, nghiêng, danh sách, liên kết `https`) ≤ 2.000 ký tự, vị trí. Luồng con: route `direct:` trong cùng tệp hoặc trong luồng khác đã phát hành của tenant.

**Luồng xử lý chính.**

1. IE đặt ghi chú dán trên sơ đồ và nhập nội dung.
2. Trình thiết kế lưu ghi chú trong bố cục, không vào YAML.
3. IE thêm chặng gọi luồng con; chặng hiển thị tên luồng con.
4. Kiểm tra VR-09 xác nhận tham chiếu `direct:` trỏ tới route tồn tại.

**Luồng thay thế.** IE bấm "Mở luồng con": trình thiết kế chuyển sang tab thực thể (cùng tệp) hoặc mở luồng khác ở chế độ chỉ đọc.

**Luồng ngoại lệ.** Tham chiếu tới route không tồn tại: phát hiện VR-09, ở `SUBMIT` chặn với ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt."

**Đầu ra.** Ghi chú trong bố cục; chặng gọi luồng con trong cây tài nguyên.

**Kết quả.** Sơ đồ có chú giải; phần lặp lại được dùng chung qua luồng con.

**Hậu điều kiện.** Bố cục và cây tài nguyên đổi, lưu theo FR-04-024.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-007.

**Màn hình, API.** UI-04-04; API-04-022.
:::

#### FR-04-027 · Tải xuống, nhập YAML và xuất gói luồng

::: dac-ta
**Mục đích.** Cho người dùng lấy định nghĩa luồng ra ngoài (để rà soát, lưu trữ, chạy CI) và đưa YAML soạn ở nơi khác vào phiên bản mở. Thay "tải mã XML" của Tooling bằng YAML.

**Tác nhân, quyền.** Tải xuống: `PERM-04-read`. Nhập vào phiên bản mở: `PERM-04-update`. Tải kèm bản tin mẫu: `PERM-04-sample-data`.

**Mức ưu tiên, đợt.** M (tải YAML), S (gói) · MVP.

**Truy vết.** REQ-04; LGC-TOOL-015 (thay XML bằng YAML).

**Tiền điều kiện.** Phiên bản tồn tại; với nhập, phiên bản mở ở `DRAFT` hoặc `CHANGES_REQUESTED`.

**Kích hoạt.** Người dùng bấm "Tải xuống" hoặc "Nhập YAML" trên thanh công cụ trình thiết kế.

**Đầu vào.** Định dạng tải: `yaml` (YAML chuẩn hóa), `yaml+layout` (kèm chú thích bố cục `# @dh-canvas-v1:` để mở lại), `bundle` (tệp nén gồm YAML, bố cục, ánh xạ `*.dhmap.json`, ca kiểm thử, `README.md` tự sinh). Nhập: tệp YAML, `If-Match`.

**Luồng xử lý chính.**

1. Người dùng chọn định dạng và bấm "Tải xuống".
2. Hệ thống dựng tệp theo định dạng; không kèm bản tin mẫu (có thể chứa dữ liệu cá nhân) trừ khi người dùng chọn rõ và có `PERM-04-sample-data`.
3. Trình duyệt nhận tệp tên `{flow}-v{n}.camel.yaml` hoặc `{flow}-v{n}.dhflow.zip`.

**Luồng thay thế.** Nhập YAML vào phiên bản mở: hệ thống phân tích (ERR-04-008, ERR-04-033), kiểm tra bí mật (ERR-04-010), hỏi xác nhận rồi thay toàn bộ định nghĩa, có hoàn tác.

**Luồng ngoại lệ.**

- YAML nhập lỗi cú pháp: ERR-04-008 (422); "YAML có lỗi cú pháp ở dòng {line}, cột {column}: {message}"
- YAML nhập chứa bí mật: ERR-04-010 (422).
- Vượt kích thước: ERR-04-033 (413).
- Phiên bản không sửa được: ERR-04-005 (409).

**Đầu ra.** Tệp tải xuống tên `{flow}-v{n}.camel.yaml` hoặc `{flow}-v{n}.dhflow.zip`; với nhập, `200` và ETag mới.

**Kết quả.** Người dùng có tệp luồng dùng được ngoài Datahub, hoặc đưa được YAML soạn ngoài vào trình thiết kế.

**Hậu điều kiện.** Tải xuống không đổi dữ liệu; nhập thay định nghĩa của phiên bản mở.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi nhập (như `INT_VERSION_SAVE`) và khi tải kèm bản tin mẫu.

**Quy tắc nghiệp vụ.** BR-04-003; BR-04-007; BR-04-013.

**Màn hình, API.** UI-04-04; API-04-026, 027.
:::

### 6.4. Nhóm C · Chạy thử và ca kiểm thử

Nhóm C thay "kiểm tra kết nối khi thêm chương trình tích hợp" của Bus cũ bằng chạy thử cả luồng với Camel thật trên sandbox cô lập, có ca kiểm thử tự động và nhật ký để người duyệt xem lại bằng chứng. Lần chạy thử đạt trên đúng băm nội dung là điều kiện gửi duyệt (BR-04-004). Vòng đời lần chạy thử theo máy trạng thái ở mục 4.12.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm C"}
flowchart TB
  F031["FR-04-031 Ca kiểm thử"] --> F030["FR-04-030 Chạy thử<br/>trên sandbox"]
  F030 --> F032["FR-04-032 Nhật ký,<br/>so sánh, dọn"]
  F030 --> F033["FR-04-033 Phủ kết quả<br/>lên sơ đồ"]
  F030 --> D["FR-04-040 Gửi duyệt<br/>(điều kiện chạy thử đạt)"]
```

#### FR-04-030 · Chạy thử luồng trên sandbox với đích mô phỏng

::: dac-ta
**Mục đích.** Cho kỹ sư thấy luồng chạy thật ra sao trước khi gửi duyệt: Camel đúng phiên bản runtime nạp YAML, bản tin đi qua từng chặng, đích ngoài được mô phỏng. Repo hiện mô phỏng kết quả (GAP-04-04); FR này đặc tả hành vi đích với Camel chạy thật.

**Tác nhân, quyền.** IE (`PERM-04-update`); chế độ `SANDBOX_LIVE` với dữ liệu thật cần `PERM-04-sample-data`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-013 · Mã repo: FR-04-028 (repo), FR-D-030, 031; ADR-064.

**Tiền điều kiện.** Phiên bản không có lỗi mức `ERROR` ở mức `DESIGN`; tenant chưa vượt hạn mức chạy thử đồng thời (`04.test.max-concurrent`, mặc định 5).

**Kích hoạt.** IE bấm "Chạy thử" trên UI-04-04 hoặc UI-04-11; bộ chạy ca kiểm thử gọi khi gửi duyệt (FR-04-040).

**Đầu vào.** Theo bảng dữ liệu vào của FR-04-030 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. IE nhập bản tin, mô phỏng đích, chọn chế độ rồi bấm "Chạy".
2. Máy chủ kiểm tra hợp lệ ở mức `DESIGN`; có lỗi `ERROR` trả ERR-04-009 kèm phát hiện, không chạy. Kiểm tra hạn mức (ERR-04-019, 429) và kích thước (ERR-04-021).
3. Máy chủ tạo `test_run` trạng thái `QUEUED`, gửi việc tới sandbox (`dh-runtime-sandbox`, ADR-064): YAML đã thay các điểm đích theo `mocks` (thành phần `mock:` hoặc WireMock nội bộ), tham chiếu kết nối được phân giải bằng giá trị môi trường TEST (thiếu giá trị với `SANDBOX_LIVE`: ERR-04-013), mọi thành phần đọc tệp, gọi lệnh bị vô hiệu.
4. Sandbox nạp YAML vào một `CamelContext` riêng của lần chạy với runtime đúng phiên bản (Camel Quarkus 3.33.2, Camel 4.18), bơm bản tin vào route chọn, ghi sự kiện từng chặng (`ExchangeCreated`, `StepStarted`, `StepCompleted`, `ExchangeFailed`) kèm thời điểm, thời lượng, ngoại lệ, và nếu `captureBodies` thì thân, tiêu đề sau chặng (đã che theo BR-04-013).
5. Lần chạy kết thúc khi bản tin hoàn tất, lỗi không bắt, hoặc quá `timeoutSeconds`; trạng thái `PASSED`, `FAILED`, `TIMED_OUT`. Với `testCaseIds`, `PASSED` khi mọi khẳng định đạt.
6. Máy chủ lưu kết quả từng chặng (EN-04-08) theo thứ tự đi qua, kể cả chặng bị bỏ qua (nhánh `choice` không chọn) với trạng thái `SKIPPED`, và đẩy tiến trình về giao diện qua SSE.
7. Thân bản tin lưu ở kho đối tượng, bucket `dh-int-testrun`, mã hóa phía máy chủ, xóa sau `04.test.body-retention-days` (mặc định 7 ngày); metadata lưu 90 ngày (FR-04-032). Theo nguyên tắc của repo (changeset 006), nếu không bật `captureBodies` thì không lưu thân, tiêu đề, tham số kết nối.

**Luồng thay thế.**

- Sandbox không sẵn sàng và tham số `04.test.allow-simulation` bật: máy chủ chạy mô phỏng tĩnh (đi theo cây, không thực thi), đặt trạng thái `SIMULATED`, gắn nhãn rõ trên kết quả. Lần chạy `SIMULATED` không thỏa điều kiện gửi duyệt.
- IE bấm "Hủy" khi lần chạy `QUEUED` hoặc `RUNNING`: trạng thái `CANCELLED` (API-04-043).

**Luồng ngoại lệ.**

- Định nghĩa còn lỗi: ERR-04-009 (422), không chạy; "Luồng còn {n} lỗi cần sửa trước khi chạy thử."
- Vượt hạn mức đồng thời: ERR-04-019 (429, kèm `retryAfterSeconds`), gợi ý chờ hoặc hủy lần chạy khác; "Môi trường chạy thử đang bận hoặc chưa sẵn sàng (tỉnh đang có {n}/{max} lần chạy thử đồng thời). Thử lại sau ít phút."
- Sandbox không sẵn sàng, không cho mô phỏng: ERR-04-019 (503); cùng câu trên.
- Bản tin vượt kích thước: ERR-04-021 (413); "Bản tin mẫu vượt {limit}."
- `SANDBOX_LIVE` dùng kết nối thiếu giá trị TEST: ERR-04-013 (422); "Kết nối "{connection}" không tồn tại, sai loại hoặc chưa được cấp cho không gian làm việc."
- Quá thời gian: ERR-04-020 (không phải mã HTTP, là `errorCode` của lần chạy `TIMED_OUT` kèm `hungNodeId`), đánh dấu chặng đang chạy là chặng treo; "Lần chạy thử quá {n} giây và đã dừng ở chặng "{node}"."

**Đầu ra.** `202 Accepted` với `runId`, sau đó kết quả qua API-04-042 hoặc luồng sự kiện máy chủ (SSE).

**Kết quả.** IE thấy bản tin đi qua từng chặng, chặng nào lỗi, mất bao lâu, dữ liệu vào ra ở mỗi chặng; lần chạy đạt mở đường gửi duyệt.

**Hậu điều kiện.** Một `test_run` và các `test_run_step`; phiên bản được đánh dấu "có lần chạy thử đạt" nếu `PASSED` ở chế độ không mô phỏng.

**Sự kiện phát ra.** EVT-04-10 `testrun.completed`.

**Kiểm toán.** Có: `INT_TESTRUN_START`; nếu dùng dữ liệu thật thì ghi thêm cờ `realData = true`.

**Quy tắc nghiệp vụ.** BR-04-004; BR-04-012 (sandbox là kênh nạp duy nhất ngoài kho cấu hình); BR-04-013.

**Màn hình, API.** UI-04-11; API-04-040, 042, 043.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `mode` | T-ENUM | Có | `MOCK` (mọi đích ngoài bị thay bằng mô phỏng), `SANDBOX_LIVE` (gọi hệ thống thật ở môi trường TEST qua kết nối giá trị TEST) | `MOCK` |
| `routeId` | chuỗi | Không | Route để bơm bản tin vào; mặc định route đầu tiên | `tra-cuu` |
| `input` | đối tượng | Có | `body` (≤ 256 KiB), `headers` (≤ 50), `contentType` | |
| `mocks` | mảng | Không | Mỗi phần tử `{endpointPattern, response: {status, headers, body}, delayMs, failWith}`; mặc định mọi đích trả `200` với thân rỗng | |
| `testCaseIds` | T-ID[] | Không | Chạy theo ca kiểm thử (FR-04-031) thay `input` | |
| `timeoutSeconds` | T-INT | Không | 1…120, mặc định 30 | `30` |
| `captureBodies` | T-BOOL | Không | Lưu thân bản tin từng chặng để xem lại; mặc định `true` với `MOCK`, `false` với `SANDBOX_LIVE` | |

: Dữ liệu vào của FR-04-030

```{.mermaid caption="Trình tự một lần chạy thử trên sandbox (FR-04-030)"}
sequenceDiagram
  autonumber
  actor IE as Kỹ sư tích hợp
  participant C as dh-console
  participant I as dh-integration
  participant S as dh-runtime-sandbox
  participant O as Kho đối tượng dh-int-testrun
  IE->>C: Bấm "Chạy"
  C->>I: API-04-040 (mode, input, mocks)
  I->>I: Kiểm tra DESIGN, hạn mức, kích thước
  I->>S: Việc chạy: YAML đã thay đích, kết nối TEST
  I-->>C: 202 runId, trạng thái QUEUED
  S->>S: CamelContext riêng, bơm bản tin
  S-->>I: Sự kiện từng chặng
  I-->>C: SSE tiến trình theo chặng
  S->>O: Thân, tiêu đề đã che (khi captureBodies)
  S-->>I: PASSED, FAILED hoặc TIMED_OUT
  I->>I: Ghi test_run, đánh dấu đạt trên contentHash
  I-->>C: Kết quả, phát EVT-04-10
```

Hình cho thấy `dh-integration` chỉ điều phối: Camel chạy trong `CamelContext` riêng của sandbox, thân bản tin đi thẳng vào kho đối tượng có thời hạn lưu, và kết quả "đạt" được gắn với băm nội dung để FR-04-040 kiểm.

#### FR-04-031 · Ca kiểm thử của luồng và bộ chạy

::: dac-ta
**Mục đích.** Cho kỹ sư lưu các bản tin vào và kết quả mong đợi thành ca kiểm thử chạy lại được, để mỗi lần sửa luồng đều được kiểm lại tự động khi gửi duyệt và trong CI của kho cấu hình.

**Tác nhân, quyền.** IE (`PERM-04-update`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04 · Mã repo: FR-D-064.

**Tiền điều kiện.** Luồng `ROUTE` hoặc `PIPE` tồn tại.

**Kích hoạt.** IE mở UI-04-13, bấm "+ Ca kiểm thử" hoặc "Lưu thành ca kiểm thử" từ một lần chạy thử.

**Đầu vào.** Mỗi ca: tên, mô tả, route vào, bản tin vào, mô phỏng đích, danh sách khẳng định `{kind ∈ STATUS, BODY_JQ, HEADER, STEP_VISITED, STEP_NOT_VISITED, ENDPOINT_CALLED, DURATION_LT, ERROR_CODE, DLQ_SENT}, expected}`.

**Luồng xử lý chính.**

1. IE nhập tên, bản tin vào, mô phỏng đích và các khẳng định.
2. Hệ thống kiểm tra mỗi ca có ít nhất một khẳng định (VR-20), vì ca không khẳng định gì luôn đạt và tạo cảm giác an toàn giả.
3. Hệ thống lưu bộ ca thành luồng loại `TEST` gắn với luồng đích, hoặc lưu kèm phiên bản.
4. IE bấm "Chạy tất cả"; hệ thống chạy từng ca qua FR-04-030 với `testCaseIds`.

**Luồng thay thế.** Khi gửi duyệt, mọi ca gắn với luồng được chạy tự động (FR-04-040). Bộ ca được xuất cùng gói luồng (FR-04-027) để chạy trong CI của kho cấu hình (cổng CI-5 ở D04-02).

**Luồng ngoại lệ.**

- Ca không có khẳng định: VR-20 mức `ERROR`, ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi lưu."
- Không tìm thấy ca: ERR-04-030 (404); "Không tìm thấy đối tượng được yêu cầu (lần chạy thử, ca kiểm thử, triển khai hoặc lệnh)."

**Đầu ra.** Bộ ca lưu thành luồng loại `TEST` gắn với luồng đích, hoặc lưu kèm phiên bản.

**Kết quả.** Luồng có bộ ca kiểm thử chạy lại được bằng một nút bấm và tự chạy khi gửi duyệt.

**Hậu điều kiện.** Ca kiểm thử lưu ở EN-04-15; ca xóa chuyển sang ngừng dùng.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: tạo, sửa, ngừng dùng ca.

**Quy tắc nghiệp vụ.** BR-04-004 (mọi ca đạt khi gửi duyệt).

**Màn hình, API.** UI-04-13; API-04-044.
:::

#### FR-04-032 · Nhật ký chạy thử, xem lại, so sánh hai lần chạy, dọn nhật ký

::: dac-ta
**Mục đích.** Giữ lịch sử các lần chạy thử để kỹ sư so sánh trước và sau khi sửa, và để người duyệt xem lại bằng chứng chạy thử của phiên bản.

**Tác nhân, quyền.** `PERM-04-read`; xem thân bản tin của lần chạy `SANDBOX_LIVE` cần `PERM-04-sample-data`.

**Mức ưu tiên, đợt.** M (nhật ký, xem lại), S (so sánh), S (dọn) · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-D-032, 040, 041, 042.

**Tiền điều kiện.** Luồng có ít nhất một lần chạy thử.

**Kích hoạt.** Người dùng mở UI-04-12, chọn một lần chạy hoặc chọn hai lần rồi bấm "So sánh"; tác vụ dọn chạy hằng ngày.

**Đầu vào.** Bộ lọc: phiên bản, kết quả, người chạy, chế độ, khoảng thời gian; mã một hoặc hai lần chạy.

**Luồng xử lý chính.**

1. Người dùng lọc danh sách lần chạy (API-04-041).
2. Người dùng mở một lần chạy; hệ thống trả sơ đồ thời gian từng chặng (waterfall), `traceId`, phiên bản định nghĩa đã dùng.
3. Người dùng mở thân bản tin của một chặng; hệ thống kiểm quyền `PERM-04-sample-data` với lần chạy dữ liệu thật và ghi kiểm toán đọc.
4. Người dùng chọn hai lần chạy; hệ thống trả so sánh thời lượng từng chặng.

**Luồng thay thế.** Dọn nhật ký chạy hằng ngày: metadata quá `04.test.retention-days` (mặc định 90) và thân quá `04.test.body-retention-days` bị xóa. Lần chạy đã được viện dẫn trong một lần duyệt được giữ tới khi phiên bản đó bị thay hai lần, để người duyệt sau này còn thấy bằng chứng.

**Luồng ngoại lệ.**

- Không tìm thấy lần chạy: ERR-04-030 (404).
- Xem thân lần chạy dữ liệu thật khi thiếu quyền: ERR-04-045 (403); "Bạn chưa có quyền xem dữ liệu thật của lần chạy thử này."
- Thân đã hết hạn lưu: `200`, khối thân hiện "Thân bản tin đã được xóa theo thời hạn lưu {n} ngày."

**Đầu ra.** Danh sách lần chạy; chi tiết gồm sơ đồ thời gian từng chặng (waterfall), thân và tiêu đề trước, sau mỗi chặng (nếu có), `traceId` liên kết sang PH-13, phiên bản định nghĩa đã dùng; so sánh thời lượng từng chặng của hai lần chạy.

**Kết quả.** Người dùng xem lại được mọi lần chạy còn trong thời hạn và biết chặng nào chậm đi hay nhanh lên.

**Hậu điều kiện.** Không đổi dữ liệu khi xem; tác vụ dọn xóa bản ghi quá hạn.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đọc thân bản tin của lần chạy dữ liệu thật: `INT_TESTRUN_VIEW_BODY`.

**Quy tắc nghiệp vụ.** BR-04-013.

**Màn hình, API.** UI-04-12; API-04-041, 042.
:::

#### FR-04-033 · Phủ kết quả chạy thử và số liệu chạy thật lên sơ đồ

::: dac-ta
**Mục đích.** Cho người dùng đọc kết quả ngay trên sơ đồ thay vì bảng số: đường bản tin đã đi, chặng lỗi, và với phiên bản đang chạy là số liệu thật theo chặng. Thay tab đồ thị route của Bus.

**Tác nhân, quyền.** `PERM-04-read`.

**Mức ưu tiên, đợt.** M (chạy thử), S (số liệu chạy thật) · MVP.

**Truy vết.** REQ-04; LGC-BUS-022 · Mã repo: FR-04-035 (repo), FR-D-031.

**Tiền điều kiện.** Có lần chạy thử; với số liệu thật, phiên bản đang chạy và PH-13 sẵn sàng.

**Kích hoạt.** Lần chạy thử kết thúc; người dùng bật lớp phủ "Số liệu" ở chế độ chỉ đọc của phiên bản đang chạy.

**Đầu vào.** `runId` hoặc khoảng thời gian 15 phút, 1 giờ, 24 giờ.

**Luồng xử lý chính.**

1. Sau một lần chạy thử, sơ đồ tô đường đi: chặng đạt có dấu ✓ và số thứ tự, chặng lỗi có dấu ✕, chặng bỏ qua có nét mờ và nhãn "Bỏ qua".
2. Người dùng bấm chặng; giao diện mở dữ liệu vào, ra của chặng đó.
3. Ở chế độ chỉ đọc của phiên bản đang chạy, sơ đồ có thể phủ số liệu chạy thật lấy từ PH-13 cho 15 phút, 1 giờ, 24 giờ gần nhất: số bản tin, tỷ lệ lỗi, độ trễ p95 theo chặng.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.** PH-13 không sẵn sàng: ERR-04-047 (503); lớp phủ hiện "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."

**Đầu ra.** Lớp phủ trên sơ đồ.

**Kết quả.** Người dùng thấy ngay chặng có vấn đề. Màu không phải kênh thông tin duy nhất (WCAG 1.4.1).

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** Không.

**Màn hình, API.** UI-04-11, UI-04-02 tab Sơ đồ; API-04-042, 063.
:::

### 6.5. Nhóm D · Duyệt, phát hành và triển khai

Nhóm D là phần kiểm soát thay đổi theo cấp độ 3: phiên bản chỉ vào vận hành sau khi một người khác người thiết kế xem khác biệt và duyệt, rồi được đưa xuống runtime qua kho cấu hình Git, không qua kênh nào khác (BR-04-012). Nhóm thay cơ chế lưu XML trong bảng `Context` và nạp trực tiếp vào agent của Bus cũ. Vòng đời phiên bản và triển khai theo máy trạng thái ở mục 4.10 và 4.11.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm D"}
flowchart TB
  F040["FR-04-040 Gửi duyệt"] --> F041["FR-04-041 Duyệt bốn mắt"]
  F043["FR-04-043 So sánh phiên bản"] --> F041
  F041 -->|"Yêu cầu sửa"| B["Nhóm B: sửa phiên bản"]
  F041 --> F042["FR-04-042 Phát hành GitOps"]
  F042 --> F045["FR-04-045 Thăng cấp<br/>môi trường"]
  F042 --> F044["FR-04-044 Quay lui"]
```

#### FR-04-040 · Gửi duyệt phiên bản

::: dac-ta
**Mục đích.** Cho kỹ sư khóa nội dung một phiên bản đã chạy thử đạt và chuyển cho người duyệt, kèm ghi chú thay đổi, để phiên bản được xem xét trước khi vào vận hành.

**Tác nhân, quyền.** IE (`PERM-04-submit`, mức `EDIT`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-029 (repo), BR-D-05.

**Tiền điều kiện.** Phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`; đã lưu (không còn thay đổi cục bộ).

**Kích hoạt.** IE bấm "Gửi duyệt" trên UI-04-04 và điền hộp gửi duyệt.

**Đầu vào.** `changeNote` (T-TEXT 10…4.000 ký tự, bắt buộc), `targetEnvironment` (T-ENV, mặc định môi trường đầu tiên của `04.env.stages` sau TEST), `suggestedReviewers` (tùy chọn), `If-Match`.

**Luồng xử lý chính.**

1. IE nhập ghi chú thay đổi, chọn môi trường đích, người duyệt gợi ý rồi bấm "Gửi".
2. Máy chủ kiểm tra trạng thái (ERR-04-005), ghi chú (ERR-04-025), catalog hiện hành (ERR-04-042).
3. Máy chủ chạy kiểm tra hợp lệ mức `SUBMIT`; có `ERROR` trả ERR-04-009 với phát hiện.
4. Máy chủ kiểm tra điều kiện chạy thử (BR-04-004): có ít nhất một lần chạy thử `PASSED` không mô phỏng trên **đúng băm định nghĩa hiện tại**; luồng có ca kiểm thử thì mọi ca phải đạt trên băm đó. Thiếu trả ERR-04-014. Tham số `04.review.require-test` cho TA tắt điều kiện với luồng nội bộ, không tắt được với luồng đối ngoại.
5. Máy chủ khóa nội dung phiên bản (bất biến), chụp danh sách người đóng góp, chuyển `PENDING_REVIEW`, ghi outbox EVT-04-03.
6. Máy chủ tạo việc "Duyệt luồng" trong hộp "Việc của tôi" (FR-00-070) của người có quyền duyệt.

**Luồng thay thế.** Người gửi **rút lại** phiên bản `PENDING_REVIEW` về `DRAFT` khi chưa ai duyệt (API-04-051), có lý do (ERR-04-025 khi thiếu).

**Luồng ngoại lệ.**

- Còn lỗi kiểm tra: ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi gửi duyệt." kèm "Mở bảng Vấn đề".
- Thiếu lần chạy thử đạt trên đúng băm: ERR-04-014 (409); "Chưa có lần chạy thử đạt (không mô phỏng) cho đúng nội dung đang gửi, hoặc còn ca kiểm thử chưa đạt." kèm "Chạy thử ngay", "Chạy tất cả ca kiểm thử".
- Trạng thái không cho gửi: ERR-04-005 (409); "Phiên bản đang ở trạng thái "{status}" nên không thể gửi duyệt."
- Thiếu ghi chú thay đổi: ERR-04-025 (400); "Vui lòng nhập lý do (ít nhất {min} ký tự)."
- Soạn trên catalog cũ: ERR-04-042 (409).

**Đầu ra.** `200`; phiên bản `PENDING_REVIEW`; việc "Duyệt luồng" trong hộp "Việc của tôi" của người có quyền duyệt.

**Kết quả.** Phiên bản được khóa và nằm trong hàng đợi duyệt; IE nhận thông báo khi có quyết định.

**Hậu điều kiện.** Nội dung phiên bản bất biến; danh sách người đóng góp được chụp.

**Sự kiện phát ra.** EVT-04-03 `version.submitted`.

**Kiểm toán.** Có: `INT_VERSION_SUBMIT`, băm định nghĩa, ghi chú thay đổi.

**Quy tắc nghiệp vụ.** BR-04-002; BR-04-004; BR-04-016; BR-04-020.

**Màn hình, API.** UI-04-04 hộp gửi duyệt; API-04-050, 051.
:::

#### FR-04-041 · Duyệt bốn mắt với so sánh YAML và so sánh sơ đồ

::: dac-ta
**Mục đích.** Bảo đảm mọi thay đổi vào vận hành được một người thứ hai xem đủ khác biệt và bằng chứng rồi mới quyết định (TCVN 14423:2026, kiểm soát thay đổi). Người duyệt không thể là người đã làm ra phiên bản.

**Tác nhân, quyền.** IA (`PERM-04-publish`, mức `MAINTAIN` khi giới hạn theo không gian làm việc).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-029 (repo), FR-D-050, FR-D-051.

**Tiền điều kiện.** Phiên bản `PENDING_REVIEW`.

**Kích hoạt.** IA mở việc "Duyệt luồng" trong "Việc của tôi" hoặc hàng đợi UI-04-14.

**Đầu vào.** `decision` ∈ {`APPROVE`, `REQUEST_CHANGES`}, `comment` (bắt buộc; với `REQUEST_CHANGES` ≥ 10 ký tự), `checklist` (các mục bắt buộc đã đánh dấu), bình luận theo dòng YAML hoặc theo chặng (tùy chọn), `If-Match`.

**Luồng xử lý chính.**

1. IA mở màn duyệt; màn hiện so sánh giữa phiên bản chờ duyệt và phiên bản đang chạy ở môi trường đích (hoặc phiên bản gốc nếu chưa chạy): so sánh YAML theo dòng có gộp đoạn không đổi, và so sánh sơ đồ (chặng thêm, xóa, đổi tham số tô ba màu có nhãn chữ).
2. Màn duyệt hiện bằng chứng: kết quả kiểm tra mức `PUBLISH` cho môi trường đích, lần chạy thử đạt và ca kiểm thử, danh sách thành phần mới so với phiên bản trước, kết nối mới, topic mới, thay đổi quyền truy cập CSDL.
3. IA mở tab so sánh; máy chủ ghi nhận đã xem qua API-04-025. Nút duyệt chỉ bật sau khi người duyệt đã mở tab so sánh ít nhất một lần (chưa xem: ERR-04-005).
4. IA đánh dấu checklist bắt buộc do TA cấu hình (`04.review.checklist`), mặc định: "Đã xem toàn bộ khác biệt", "Không có dữ liệu cá nhân đi ra ngoài mục đích", "Xử lý lỗi và DLQ phù hợp", "Đã kiểm tra kết nối và quyền CSDL mới"; nhập ý kiến (thiếu: ERR-04-025) rồi bấm "Duyệt".
5. Máy chủ kiểm tra người duyệt không phải người tạo phiên bản, người có tên trong danh sách người đóng góp, hoặc người gửi duyệt (BR-04-005); vi phạm chặn với ERR-04-015. Giao diện chỉ ẩn nút để đỡ bấm nhầm.
6. Máy chủ chuyển phiên bản `APPROVED`, phát EVT-04-04; duyệt đồng nghĩa phát hành tới môi trường đích ghi trong yêu cầu duyệt (FR-04-042).

**Luồng thay thế.**

- IA chọn "Yêu cầu sửa" kèm ý kiến ≥ 10 ký tự: phiên bản chuyển `CHANGES_REQUESTED`, phát EVT-04-05, IE nhận thông báo kèm bình luận theo dòng.
- IA chọn "Duyệt, phát hành sau": phiên bản `APPROVED`, không gọi FR-04-042 ngay.
- Môi trường đích là PROD hoặc `04.review.require-reauth` bật: giao diện yêu cầu xác thực lại trước bước 5.

**Luồng ngoại lệ.**

- Tự duyệt: ERR-04-015 (403); "Bạn đã tạo, đóng góp hoặc gửi duyệt phiên bản này nên không thể tự duyệt. Cần một người duyệt khác."
- Chưa xem so sánh: ERR-04-005 (409); "Phiên bản đang ở trạng thái "{status}" nên không thể duyệt." (kèm lý do "chưa xem so sánh").
- Thiếu ý kiến hoặc checklist: ERR-04-025 (400); "Vui lòng nhập lý do (ít nhất {min} ký tự)."
- Trạng thái không cho duyệt: ERR-04-005 (409).
- Không có mức `MAINTAIN` trên không gian làm việc: ERR-04-003 (403).

**Đầu ra.** `200`; phiên bản `APPROVED` hoặc `CHANGES_REQUESTED`.

**Kết quả.** Phiên bản được duyệt và bắt đầu phát hành, hoặc trả về người thiết kế với ý kiến cụ thể.

**Hậu điều kiện.** Quyết định, ý kiến, checklist, băm định nghĩa được duyệt lưu ở EN-04-05.

**Sự kiện phát ra.** EVT-04-04 `version.approved` hoặc EVT-04-05 `version.changes-requested`.

**Kiểm toán.** Có: `INT_VERSION_APPROVE` hoặc `INT_VERSION_REJECT`, ý kiến, checklist, băm định nghĩa được duyệt.

**Quy tắc nghiệp vụ.** BR-04-005; BR-04-017; BR-04-021.

**Màn hình, API.** UI-04-14, UI-04-16; API-04-052, 053, 025.
:::

```{.mermaid caption="Trình tự gửi duyệt và duyệt bốn mắt (FR-04-040, FR-04-041)"}
sequenceDiagram
  autonumber
  actor IE as Kỹ sư tích hợp
  actor IA as Người duyệt
  participant I as dh-integration
  participant W as Việc của tôi (FR-00-070)
  participant K as Kafka
  IE->>I: Gửi duyệt (API-04-050)
  I->>I: Kiểm tra SUBMIT, chạy thử đạt trên contentHash
  I->>I: Khóa nội dung, chụp người đóng góp
  I->>W: Tạo việc "Duyệt luồng"
  I->>K: EVT-04-03 version.submitted
  IA->>W: Mở việc
  IA->>I: Xem so sánh (API-04-025)
  IA->>I: Duyệt kèm checklist (API-04-052)
  I->>I: Kiểm tra bốn mắt (BR-04-005)
  I->>K: EVT-04-04 version.approved
  I-->>IE: Thông báo đã duyệt, bắt đầu phát hành
```

Hai chốt quan trọng nằm ở máy chủ: điều kiện chạy thử đạt được kiểm trên đúng băm nội dung đang gửi (bước 2), và bốn mắt được kiểm với danh sách người đóng góp đã chụp lúc gửi (bước 9), nên không thể lách bằng cách đổi người gửi sau khi sửa.

#### FR-04-042 · Phát hành qua GitOps và theo dõi tình trạng triển khai

::: dac-ta
**Mục đích.** Đưa phiên bản đã duyệt xuống đúng môi trường chỉ qua kho cấu hình Git và Argo CD, và cho người dùng biết chính xác khi nào runtime đã chạy đúng nội dung đó. Repo hiện ghi tệp YAML vào chính repo mã (GAP-04-03); FR này đặc tả luồng đích.

**Tác nhân, quyền.** IA (`PERM-04-publish`); với PROD khi `04.env.prod-requires-promote` bật cần thêm `PERM-04-promote`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-033, 034 · Mã repo: FR-04-020, FR-04-022 (repo); ADR-063.

**Tiền điều kiện.** Phiên bản `APPROVED`; kiểm tra mức `PUBLISH` cho môi trường đích không có `ERROR`; không trong thời gian đóng băng thay đổi.

**Kích hoạt.** Duyệt ở FR-04-041 (mặc định), hoặc IA bấm "Phát hành" trên UI-04-15, hoặc lịch `scheduledAt` tới hạn.

**Đầu vào.** `environment` (T-ENV), `strategy` ∈ {`REPLACE` mặc định, `CANARY` (đợt 2)}, `scheduledAt` (tùy chọn, trong 30 ngày), `If-Match`.

**Luồng xử lý chính.**

1. Máy chủ kiểm tra trạng thái `APPROVED` (ERR-04-005), thứ tự môi trường (ERR-04-023), đóng băng (ERR-04-041), kiểm tra mức `PUBLISH` (ERR-04-009) và hồ sơ runtime có đủ thành phần (ERR-04-029).
2. Máy chủ sinh các tệp triển khai cho luồng: YAML chuẩn hóa, tệp mô tả triển khai `flow.dh.yaml` (mã luồng, phiên bản, băm, tenant, hồ sơ runtime, namespace, trạng thái mong muốn, danh sách kết nối cần phân giải, topic, điểm vào HTTP). Cấu trúc kho ở SDD §5.2.
3. Máy chủ ghi các tệp vào kho cấu hình `dh-flows-{tenant}` trên nhánh của môi trường (`env/test`, `env/staging`, `env/prod`) bằng một commit ký bằng khóa của dịch vụ `dh-integration`, thông điệp `flow({code}): v{n} → {env}` kèm mã duyệt. Với PROD, commit đi qua yêu cầu gộp (merge request) tự động được gộp khi kho có chính sách bảo vệ nhánh (CI kho cấu hình chạy lại kiểm tra và ca kiểm thử). Ghi lỗi: ERR-04-022.
4. Argo CD (ApplicationSet theo tenant và môi trường) đồng bộ thư mục luồng thành ConfigMap và tài nguyên `FlowDeployment` của namespace đích. `dh-runtime` theo dõi tài nguyên, nạp hoặc nạp lại route của luồng mà không khởi động lại pod (ADR-063).
5. `dh-runtime` phát nhịp tim EVT-04-12 mỗi 30 giây với danh sách luồng, phiên bản, băm, trạng thái route. `dh-integration` so băm để chuyển triển khai sang `SYNCED`; quá `04.deploy.timeout-minutes` (mặc định 10) chưa khớp thì `FAILED` với lý do lấy từ Argo CD và log nạp route.
6. Khi PROD `SYNCED`, phiên bản trước đang chạy ở PROD chuyển `SUPERSEDED`, luồng chuyển `ACTIVE`.

**Luồng thay thế.**

- `scheduledAt` có giá trị: bước 2–6 chạy khi tới hạn; trước đó triển khai ở `PENDING` có lịch, hủy được.
- Trong 5 phút đầu sau `SYNCED`, tỷ lệ lỗi gấp `04.deploy.rollback-suggest-error-ratio` lần phiên bản trước: giao diện gợi ý quay lui (FR-04-044), không tự quay lui.

**Luồng ngoại lệ.**

- Phiên bản chưa duyệt: ERR-04-005 (409); "Phiên bản đang ở trạng thái "{status}" nên không thể phát hành."
- Chưa qua môi trường trước theo thứ tự: ERR-04-023 (409); "Phiên bản phải đồng bộ, khỏe ở {previousEnv} (và chạy ổn định đủ {minutes} phút) trước khi lên {env}, hoặc luồng chưa triển khai ở {env}."
- Kiểm tra mức `PUBLISH` có lỗi: ERR-04-009 (422); "Luồng còn {n} lỗi cần sửa trước khi phát hành."
- Không hồ sơ runtime đủ thành phần: ERR-04-029 (422); "Không hồ sơ runtime nào có đủ thành phần: {components}."
- Ghi kho cấu hình lỗi: ERR-04-022 (502), triển khai không được tạo, người dùng thử lại được; "Không ghi được vào kho cấu hình. Luồng chưa được phát hành." kèm "Thử lại".
- Đang đóng băng thay đổi: ERR-04-041 (423); "Đang trong khoảng đóng băng thay đổi tới {until}. Chỉ được quay lui hoặc tạm dừng khẩn."
- Quá hạn đồng bộ: triển khai `FAILED` (không phải mã HTTP), nhãn "Triển khai lỗi" kèm lý do từ Argo CD.

**Đầu ra.** `202 Accepted` với `deploymentId`; tiến trình qua API-04-054 (SSE).

**Kết quả.** Người dùng thấy triển khai đi qua các bước "Đã ghi kho cấu hình", "Argo CD đồng bộ", "Runtime đã nạp đúng băm", và luồng chuyển "Đang chạy".

**Hậu điều kiện.** Một `deployment` `PENDING`; commit trong kho cấu hình.

**Sự kiện phát ra.** EVT-04-06 `deployment.requested`; sau đó EVT-04-07 `deployment.status-changed` mỗi lần trạng thái đổi.

**Kiểm toán.** Có: `INT_DEPLOY_REQUEST`, môi trường, commit, người yêu cầu.

**Quy tắc nghiệp vụ.** BR-04-012; BR-04-018; BR-04-019; BR-04-022.

**Màn hình, API.** UI-04-15; API-04-054.
:::

```{.mermaid caption="Trình tự phát hành qua GitOps tới khi đồng bộ (FR-04-042)"}
sequenceDiagram
  autonumber
  participant I as dh-integration
  participant G as Kho dh-flows-T68
  participant CI as CI kho cấu hình
  participant A as Argo CD
  participant R as dh-runtime PROD
  participant K as Kafka
  I->>I: Kiểm tra PUBLISH, hồ sơ runtime
  I->>G: Commit ký vào env/prod (merge request)
  G->>CI: Chạy lại kiểm tra, ca kiểm thử
  CI-->>G: Đạt, tự gộp
  I->>K: EVT-04-06 deployment.requested
  A->>G: Nhận commit mới
  A->>R: Áp ConfigMap, FlowDeployment
  R->>R: FlowLoader nạp route, không khởi động lại pod
  R->>K: Nhịp tim EVT-04-12 (băm mới)
  K->>I: Nhịp tim
  I->>I: So băm, SYNCED; bản cũ SUPERSEDED
  I->>K: EVT-04-07 deployment.status-changed
```

Trạng thái `SYNCED` chỉ được đặt khi băm do runtime báo về trùng băm đã duyệt; Argo CD báo áp xong là chưa đủ. Nếu tới hạn `04.deploy.timeout-minutes` mà chưa khớp, triển khai `FAILED` và phiên bản đang chạy cũ vẫn giữ nguyên.

#### FR-04-043 · So sánh hai phiên bản bất kỳ

::: dac-ta
**Mục đích.** Cho người dùng biết hai phiên bản khác nhau ở đâu, cả ở mức văn bản YAML và mức sơ đồ, để rà soát thay đổi, điều tra sự cố hay chuẩn bị quay lui. Nâng cấp tab mã nguồn của Bus.

**Tác nhân, quyền.** `PERM-04-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-023 · Mã repo: FR-D-004, FR-D-050.

**Tiền điều kiện.** Cả hai phiên bản tồn tại.

**Kích hoạt.** Người dùng chọn hai phiên bản trên tab Phiên bản rồi bấm "So sánh", hoặc mở tab so sánh trên màn duyệt.

**Đầu vào.** `from`, `to` (số phiên bản), chế độ `yaml`, `graph`, `summary`.

**Luồng xử lý chính.**

1. Người dùng chọn hai phiên bản và chế độ.
2. Hệ thống kiểm tra hai phiên bản tồn tại (ERR-04-004).
3. Hệ thống so cây dựa trên `id` chặng; chặng không có `id` ổn định được ghép theo vị trí và loại.
4. Hệ thống trả khác biệt theo chế độ; giao diện hiện YAML hai cột hoặc sơ đồ tô màu kèm nhãn chữ.

**Luồng thay thế.** Gọi từ màn duyệt: hệ thống ghi nhận người duyệt đã xem so sánh (điều kiện bật nút duyệt ở FR-04-041).

**Luồng ngoại lệ.** Không tìm thấy phiên bản: ERR-04-004 (404); "Không tìm thấy phiên bản v{n} của luồng này."

**Đầu ra.** `200`; khác biệt YAML (unified hoặc hai cột), khác biệt cây (chặng thêm, xóa, đổi, di chuyển; tham số đổi theo chặng), tóm tắt (số chặng đổi, thành phần mới, kết nối mới, topic mới, điểm vào mới).

**Kết quả.** Người dùng thấy rõ từng thay đổi giữa hai phiên bản.

**Hậu điều kiện.** Không đổi dữ liệu (trừ ghi nhận đã xem khi gọi từ màn duyệt).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-005 (điều kiện xem so sánh trước khi duyệt).

**Màn hình, API.** UI-04-16, UI-04-14; API-04-025.
:::

#### FR-04-044 · Quay lui về phiên bản trước

::: dac-ta
**Mục đích.** Cho người duyệt đưa nhanh một môi trường về phiên bản đã duyệt trước đó khi phiên bản mới gây lỗi, không phải qua lại vòng duyệt nhưng vẫn qua kiểm tra mức `PUBLISH`.

**Tác nhân, quyền.** IA (`PERM-04-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04 · Mã repo: FR-04-022 (repo).

**Tiền điều kiện.** Phiên bản đích từng được duyệt (`APPROVED` hoặc `SUPERSEDED`), cùng loại tài nguyên; kiểm tra mức `PUBLISH` hiện tại không có `ERROR` (thành phần có thể đã bị cấm, kết nối có thể đã bị thu hồi).

**Kích hoạt.** IA bấm "Quay lui" trên UI-04-15, hoặc nhận gợi ý quay lui sau phát hành (FR-04-042).

**Đầu vào.** `environment`, `toVersion`, `reason` (bắt buộc).

**Luồng xử lý chính.**

1. IA chọn môi trường, phiên bản đích, nhập lý do (thiếu: ERR-04-025) và xác nhận.
2. Máy chủ kiểm tra phiên bản đích từng được duyệt (ERR-04-005) và chạy kiểm tra mức `PUBLISH` hiện tại; dùng thành phần nay bị cấm trả ERR-04-040.
3. Máy chủ ghi kho cấu hình như FR-04-042 bước 2–5 (không cần duyệt lại vì phiên bản đích đã được duyệt); quay lui được phép cả trong khoảng đóng băng (BR-04-022).
4. Khi `SYNCED`, phiên bản đang chạy chuyển `ROLLED_BACK`, phiên bản đích chạy lại.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**

- Phiên bản đích dùng thành phần đã bị cấm: ERR-04-040 (409); "Không quay lui được về v{n} vì phiên bản đó dùng thành phần "{component}" nay không còn được phép." kèm "Xem chính sách thành phần".
- Thiếu lý do: ERR-04-025 (400).
- Kiểm tra `PUBLISH` có lỗi khác (kết nối bị thu hồi): ERR-04-009 (422).
- Ghi kho cấu hình lỗi: ERR-04-022 (502).

**Đầu ra.** `202` như FR-04-042.

**Kết quả.** Môi trường chạy lại phiên bản ổn định trước đó trong vài phút.

**Hậu điều kiện.** Phiên bản đang chạy chuyển `ROLLED_BACK`; phiên bản đích chạy lại.

**Sự kiện phát ra.** EVT-04-06, EVT-04-07.

**Kiểm toán.** Có: `INT_ROLLBACK`, lý do.

**Quy tắc nghiệp vụ.** BR-04-017; BR-04-019 (quay lui không cần qua môi trường trước); BR-04-022.

**Màn hình, API.** UI-04-15; API-04-055.
:::

```{.mermaid caption="Trình tự quay lui một môi trường (FR-04-044)"}
sequenceDiagram
  autonumber
  actor IA as Người duyệt
  participant I as dh-integration
  participant G as Kho cấu hình
  participant A as Argo CD
  participant R as dh-runtime
  IA->>I: Quay lui về v{n}, lý do (API-04-055)
  I->>I: Kiểm tra từng duyệt, kiểm tra PUBLISH
  I->>G: Commit ký: v{n} → {env}
  A->>G: Nhận commit
  A->>R: Áp định nghĩa v{n}
  R-->>I: Nhịp tim đúng băm v{n}
  I->>I: Bản hiện tại ROLLED_BACK, v{n} chạy lại
```

Quay lui đi cùng đường kho cấu hình như phát hành, nên lịch sử Git luôn phản ánh đúng phiên bản đang chạy.

#### FR-04-045 · Thăng cấp phiên bản qua các môi trường

::: dac-ta
**Mục đích.** Đưa đúng phiên bản (cùng băm) đã chạy ổn định ở môi trường trước lên môi trường kế tiếp, tách quyết định "nội dung đúng" với quyết định "đưa vào vận hành thật".

**Tác nhân, quyền.** `PERM-04-promote` (IA, TA).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-04.

**Tiền điều kiện.** Phiên bản `SYNCED` và khỏe ở môi trường trước theo `04.env.stages`; đã chạy ổn định ít nhất `04.env.soak-minutes` (mặc định 30 ở STAGING, 0 ở TEST).

**Kích hoạt.** Người có quyền bấm "Thăng cấp lên {env}" trên UI-04-15.

**Đầu vào.** `fromEnvironment`, `toEnvironment`, `deploymentId` nguồn.

**Luồng xử lý chính.**

1. Người dùng chọn triển khai nguồn và môi trường đích.
2. Máy chủ kiểm tra thứ tự môi trường, trạng thái `SYNCED`, `HEALTHY` và thời gian ổn định (ERR-04-023), đóng băng với PROD (ERR-04-041).
3. Máy chủ phát hành đúng băm đó lên môi trường đích theo FR-04-042 bước 2–6.

**Luồng thay thế.** Thăng cấp lên PROD ngoài giờ hành chính: giao diện hiện cảnh báo, không chặn.

**Luồng ngoại lệ.**

- Chưa đủ điều kiện ở môi trường trước: ERR-04-023 (409); "Phiên bản phải đồng bộ, khỏe ở {previousEnv} (và chạy ổn định đủ {minutes} phút) trước khi lên {env}, hoặc luồng chưa triển khai ở {env}."
- Đang đóng băng: ERR-04-041 (423).
- Thiếu quyền: ERR-04-045 (403).

**Đầu ra.** `202` như FR-04-042.

**Kết quả.** Phiên bản đã kiểm chứng ở môi trường trước chạy ở môi trường kế tiếp.

**Hậu điều kiện.** Một `deployment` mới ở môi trường đích.

**Sự kiện phát ra.** EVT-04-06, EVT-04-07.

**Kiểm toán.** Có: như `INT_DEPLOY_REQUEST`, kèm môi trường nguồn.

**Quy tắc nghiệp vụ.** BR-04-019; BR-04-022.

**Màn hình, API.** UI-04-15; API-04-056.
:::

### 6.6. Nhóm E · Vận hành luồng

Nhóm E thay Start/Stop agent và route qua JMX, và các màn số liệu agent của Bus cũ. Runtime không mở JMX ra ngoài pod: tình trạng lấy từ nhịp tim do runtime chủ động phát, lệnh điều khiển đi qua topic có ký và trạng thái mong muốn luôn được ghi vào Git (ADR-065). Vòng đời lệnh điều khiển theo máy trạng thái ở mục 4.13.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm E"}
flowchart TB
  F051["FR-04-051 Tình trạng runtime"] --> F050["FR-04-050 Tạm dừng, tiếp tục,<br/>dừng khẩn"]
  F052["FR-04-052 Điểm kết nối,<br/>số liệu"] --> F053["FR-04-053 Giám sát<br/>nhúng PH-13"]
  F050 --> F051
```

#### FR-04-050 · Kích hoạt, tạm dừng, tiếp tục luồng và từng route có lý do

::: dac-ta
**Mục đích.** Cho người vận hành dừng, chạy lại một luồng hoặc từng route trong vài giây, có lý do và có xác nhận từ mọi bản sao; cho cán bộ ATTT dừng khẩn luồng gây sự cố. Thay Start/Stop agent và route của Bus cũ qua JMX.

**Tác nhân, quyền.** TO, TA, IA (`PERM-04-operate`); tạm dừng khẩn: SO, TA (`PERM-04-emergency-stop`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-009, 012, 026 · Mã repo: FR-04-021 (repo), FR-D-002 (tạm dừng); ADR-065.

**Tiền điều kiện.** Luồng có triển khai `SYNCED` ở môi trường chọn.

**Kích hoạt.** Người dùng bấm "Tạm dừng", "Tiếp tục" hoặc "Dừng khẩn" trên tab Triển khai của UI-04-02.

**Đầu vào.** `environment`, `scope` (`FLOW` hoặc danh sách `routeIds`), `action` ∈ {`PAUSE`, `RESUME`, `EMERGENCY_STOP`}, `reason` (10…1.000 ký tự, bắt buộc), `drain` (với `PAUSE`: chờ bản tin đang xử lý xong, mặc định `true`, tối đa 60 giây); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Người dùng chọn phạm vi, hành động, nhập lý do (thiếu: ERR-04-025); máy chủ kiểm tra luồng đã triển khai ở môi trường (ERR-04-023). Tạm dừng một route mà luồng khác đang gọi tới qua `direct:` hiện cảnh báo danh sách luồng bị ảnh hưởng trước khi gửi.
2. `PAUSE`, `RESUME` thông thường: máy chủ ghi trạng thái mong muốn mới vào `flow.dh.yaml` trong kho cấu hình **và** gửi lệnh có ký lên topic điều khiển `dh.integration.runtime.command.v1` để có hiệu lực trong vài giây thay vì chờ chu kỳ đồng bộ của Argo CD.
3. Lệnh mang mã lệnh, tenant, luồng, route, hành động, thời điểm hết hạn (60 giây), chữ ký Ed25519 bằng khóa của `dh-integration` lấy từ OpenBao. Runtime kiểm chữ ký, hết hạn, tenant của luồng trước khi thi hành; sai thì từ chối và phát xác nhận `REJECTED`.
4. Mỗi bản sao runtime thi hành lệnh và phát xác nhận EVT-04-13. Hết 30 giây mà chưa đủ xác nhận thì lệnh `PARTIAL`, giao diện hiển thị bản sao chưa xác nhận.
5. Khi mọi bản sao xác nhận, máy chủ phát EVT-04-08 và đối soát trạng thái mong muốn trong Git (lệnh `RECONCILED`).

**Luồng thay thế.** `EMERGENCY_STOP`: chỉ gửi lệnh lên topic điều khiển trước, ghi Git sau (trong 5 phút, BR-04-018); runtime dừng route ngay không chờ xả bản tin (bản tin đang xử lý được đưa sang DLQ với lý do "dừng khẩn"). Dùng khi luồng gây sự cố ATTT hoặc làm quá tải hệ đích; được phép cả trong khoảng đóng băng.

**Luồng ngoại lệ.**

- Thiếu lý do: ERR-04-025 (400); "Vui lòng nhập lý do (ít nhất {min} ký tự)."
- Luồng chưa triển khai ở môi trường: ERR-04-023 (409).
- Runtime từ chối hoặc không xác nhận: ERR-04-024 (không phải mã HTTP; lệnh `REJECTED`, `PARTIAL`); "Runtime chưa xác nhận lệnh ({k}/{n} bản sao) hoặc đã từ chối lệnh." kèm "Gửi lại lệnh", "Xem bản sao chưa xác nhận".
- Thiếu quyền dừng khẩn: ERR-04-045 (403).

**Đầu ra.** `202` với `commandId`; trạng thái lệnh qua API-04-061.

**Kết quả.** Luồng hoặc route dừng, chạy lại trên mọi bản sao (p95 < 10 s; khẩn < 5 s, NFR-04-010) và không bị Argo CD bật lại.

**Hậu điều kiện.** Lệnh `RuntimeCommand` (EN-04-10); khi tất cả bản sao xác nhận, trạng thái mong muốn ghi vào kho cấu hình để lần đồng bộ sau không bật lại luồng.

**Sự kiện phát ra.** EVT-04-11 `runtime.command` (topic điều khiển), EVT-04-08 `flow.runtime-state-changed` khi đã xác nhận.

**Kiểm toán.** Có: `INT_FLOW_PAUSE`, `INT_FLOW_RESUME`, `INT_FLOW_EMERGENCY_STOP`, lý do, phạm vi, danh sách bản sao xác nhận.

**Quy tắc nghiệp vụ.** BR-04-017; BR-04-018; BR-04-022.

**Màn hình, API.** UI-04-02 tab Triển khai; API-04-061.
:::

```{.mermaid caption="Trình tự tạm dừng luồng có xác nhận và đối soát Git (FR-04-050)"}
sequenceDiagram
  autonumber
  actor TO as Vận hành tenant
  participant I as dh-integration
  participant B as OpenBao
  participant K as Kafka (topic điều khiển)
  participant R as Các bản sao dh-runtime
  participant G as Kho cấu hình
  TO->>I: PAUSE, lý do (API-04-061)
  I->>B: Lấy khóa ký Ed25519
  I->>K: EVT-04-11 lệnh có ký, hết hạn 60 giây
  I->>G: Ghi trạng thái mong muốn PAUSED
  K->>R: Lệnh
  R->>R: Kiểm chữ ký, hạn, tenant; xả bản tin (drain)
  R->>K: EVT-04-13 xác nhận từng bản sao
  K->>I: Xác nhận
  I->>I: Đủ xác nhận: ACKNOWLEDGED, RECONCILED
  I-->>TO: EVT-04-08, luồng "Tạm dừng"
```

Lệnh đi hai đường song song: topic có ký để có hiệu lực ngay, và Git để trạng thái mong muốn không bị lần đồng bộ sau ghi đè. Với dừng khẩn, bước ghi Git đi sau bước gửi lệnh và phải xong trong 5 phút.

#### FR-04-051 · Xem tình trạng runtime của luồng

::: dac-ta
**Mục đích.** Cho người dùng biết luồng đang thực sự chạy phiên bản nào, trên bao nhiêu bản sao, route nào dừng, và có lệch giữa mong muốn và thực tế không. Thay việc đọc trạng thái agent và route qua JMX/Jolokia (LGC-BUS-030).

**Tác nhân, quyền.** `PERM-04-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-014, 015, 017, 025, 028 · Mã repo: không.

**Tiền điều kiện.** Luồng có ít nhất một triển khai.

**Kích hoạt.** Người dùng mở tab Triển khai của UI-04-02; giao diện làm mới theo nhịp tim.

**Đầu vào.** `{flowCode}`, `environment` (tùy chọn).

**Luồng xử lý chính.**

1. Người dùng mở tab Triển khai.
2. Hệ thống đọc nhịp tim mới nhất của mỗi bản sao (EN-04-17) do runtime chủ động phát; không mở JMX ra ngoài pod.
3. Hệ thống so phiên bản, băm mong muốn với thực tế và tính lệch.
4. Hệ thống trả tình trạng theo từng môi trường; nhịp tim quá 90 giây không về thì sức khỏe `UNKNOWN`.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.** Không tìm thấy luồng: ERR-04-001 (404). Bản sao mất nhịp tim: không phải lỗi API, nhãn "Không rõ" trên bản sao đó.

**Đầu ra.** `200`; theo từng môi trường: phiên bản mong muốn và phiên bản đang chạy, băm, trạng thái đồng bộ, namespace, hồ sơ runtime, số bản sao đang chạy trên tổng, sức khỏe từng bản sao, trạng thái từng route (`Started`, `Suspended`, `Stopped`) theo nhịp tim gần nhất, thời điểm nhịp tim, lệch giữa mong muốn và thực tế.

**Kết quả.** Người dùng thấy đúng tình trạng thật của luồng ở từng môi trường.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-018.

**Màn hình, API.** UI-04-02 tab Triển khai; API-04-060.
:::

#### FR-04-052 · Danh sách điểm kết nối của luồng và số liệu theo điểm kết nối

::: dac-ta
**Mục đích.** Cho người dùng thấy luồng nhận từ đâu, gửi đi đâu và mỗi điểm kết nối đang hoạt động thế nào. Thay tab endpoint, thống kê theo endpoint và REST API của agent ở Bus cũ.

**Tác nhân, quyền.** `PERM-04-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-04; LGC-BUS-020, 027, 028.

**Tiền điều kiện.** Phiên bản có chỉ mục điểm kết nối (EN-04-04).

**Kích hoạt.** Người dùng mở tab Điểm kết nối của UI-04-02 và chọn khoảng thời gian.

**Đầu vào.** `{flowCode}`, `environment`, khoảng thời gian.

**Luồng xử lý chính.**

1. Người dùng mở tab Điểm kết nối.
2. Hệ thống lấy danh sách điểm vào, ra từ chỉ mục của phiên bản đang chạy.
3. Hệ thống ghép số liệu theo điểm kết nối từ PH-13 trong khoảng thời gian chọn.
4. Hệ thống trả danh sách, URI đã che tham số nhạy cảm.

**Luồng thay thế.** PH-13 không sẵn sàng: danh sách vẫn hiện, cột số liệu để trống kèm ghi chú.

**Luồng ngoại lệ.** Không tìm thấy luồng: ERR-04-001 (404). PH-13 không sẵn sàng: ERR-04-047 (503) cho phần số liệu; "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."

**Đầu ra.** `200`; điểm vào, ra của luồng: chiều, thành phần, URI đã che, phương thức, đường dẫn, HTTT liên quan, API PH-02 công bố điểm vào này (nếu có), topic PH-10; số lượt, lỗi, độ trễ p95, lần gọi gần nhất, lỗi gần nhất trong khoảng thời gian chọn (lấy từ PH-13).

**Kết quả.** Người dùng biết điểm kết nối nào đang lỗi hoặc chậm.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-04-003 (che URI).

**Màn hình, API.** UI-04-02 tab Điểm kết nối; API-04-062.
:::

#### FR-04-053 · Giám sát theo luồng nhúng từ PH-13

::: dac-ta
**Mục đích.** Cho người dùng xem biểu đồ vận hành của luồng ngay trên màn chi tiết, thay biểu đồ lượng bản tin, CPU, bộ nhớ, log của Bus cũ, mà PH-04 không phải lưu số liệu.

**Tác nhân, quyền.** `PERM-04-read` và `PERM-13-read`.

**Mức ưu tiên, đợt.** S · Đợt 2 (MVP liên kết sang PH-13).

**Truy vết.** REQ-04, REQ-13; LGC-BUS-007, 015, 016, 019, 029.

**Tiền điều kiện.** Luồng có triển khai; PH-13 sẵn sàng.

**Kích hoạt.** Người dùng mở tab Giám sát của UI-04-02.

**Đầu vào.** Bộ lọc `tenant`, `flow`, `version`, `environment`, khoảng thời gian.

**Luồng xử lý chính.**

1. Người dùng mở tab Giám sát.
2. PH-04 truyền bộ lọc `tenant`, `flow`, `version`, `environment` cho bảng điều khiển theo luồng của PH-13; không lưu số liệu.
3. Tab hiển thị thông lượng, tỷ lệ lỗi, độ trễ p50, p95, p99 theo route; CPU, bộ nhớ của các bản sao chạy luồng; log lọc theo `dh-flow`; danh sách vết gần nhất.

**Luồng thay thế.** Người dùng thiếu `PERM-13-read`: tab hiện liên kết sang PH-13 thay vì nhúng.

**Luồng ngoại lệ.** PH-13 không sẵn sàng: ERR-04-047 (503); "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."

**Đầu ra.** Bảng điều khiển nhúng.

**Kết quả.** Người dùng theo dõi luồng ngay trên màn chi tiết.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** Không.

**Màn hình, API.** UI-04-02 tab Giám sát; API-04-063.
:::

### 5.6. Nhóm F — Data plane: khuôn mẫu route chuẩn

Nhóm F đặc tả hành vi bắt buộc của luồng khi chạy trong `dh-runtime`. Hành vi được cài đặt bằng thư viện nền `dh-runtime-core` (Kamelet nền, `routeConfiguration` nền, processor nền) để người thiết kế không phải tự viết. FR nhóm F được kiểm bằng ca kiểm thử của luồng mẫu và kiểm thử tích hợp của `dh-runtime`.

#### FR-04-060 · Khung chín chặng chuẩn và thư viện nền

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-060 · Khung chín chặng chuẩn và thư viện nền |
| Mức ưu tiên | M |
| Truy vết | REQ-04; LGC-BUS-035…039 · Mã repo: WP-20 (khung 9 bước) |

Mỗi chặng chuẩn có một Kamelet nền loại `action` (ví dụ `dh-receive-action`, `dh-schema-action`, `dh-authz-action`, `dh-audit-action`, `dh-respond-action`) và một `routeConfiguration` nền `dh-default-config` gồm xử lý lỗi, chặn `onCompletion` ghi vết. Người thiết kế kéo Kamelet nền vào khối chặng tương ứng hoặc dùng khuôn mẫu đã có sẵn. Luồng Java DSL hiện có (`TraCuuRoute`, `StandardPipelineRoute`, `CdmMapRoute`) được viết lại bằng YAML dùng các Kamelet nền này (GAP-04-02, ADR-062).

#### FR-04-061 · Tiếp nhận đồng bộ HTTP và SOAP qua APISIX

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-061 · Tiếp nhận đồng bộ |
| Mức ưu tiên | M |
| Truy vết | REQ-04; LGC-BUS-039 · Mã repo: FR-04-001 (repo) |

Điểm vào đồng bộ dùng `platform-http` (REST) hoặc `cxf` (SOAP, chỉ hồ sơ JVM nếu native chưa hỗ trợ đủ). Runtime chỉ nhận lưu lượng từ APISIX nội bộ (`apisix-int`, chính sách mạng và `AuthorizationPolicy` của mesh, D03-09). Chặng `receive` đọc tiêu đề do APISIX đặt sau khi xác thực (`X-Dh-Consumer`, `X-Dh-Tenant`, `X-Dh-Subscription`, `traceparent`), đặt tiêu đề nội bộ `dh-tenant`, `dh-caller`, `dh-flow`, `dh-flow-version`, đo kích thước, từ chối thân vượt `04.runtime.max-body-kb` (mặc định 10 MiB) với `ERR-04-107`. Thời gian chờ tối đa của lượt đồng bộ theo cấu hình luồng, mặc định 30 giây, tối đa 120 giây.

#### FR-04-062 · Tiếp nhận bất đồng bộ từ Kafka

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-062 · Tiếp nhận bất đồng bộ từ Kafka |
| Mức ưu tiên | M |
| Truy vết | REQ-04, REQ-10; LGC-BUS-039 · Mã repo: FR-04-002 (repo) |

Luồng nhận bản tin từ topic đã đăng ký ở PH-10 với nhóm tiêu thụ `dh-flow-{tenant}-{flow}`. Ghi nhận offset sau khi xử lý xong (at-least-once) kết hợp chống trùng (FR-04-071). Tenant lấy từ tiền tố topic `{tenant}.`, không lấy từ nội dung. Bản tin không giải tuần tự được theo lược đồ Apicurio đi thẳng DLQ với `ERR-04-101`.

#### FR-04-063 · Kiểm tra lược đồ bản tin

FR-04-063 (M; LGC-BUS-036; repo FR-04-003, 004). Chặng `schema` kiểm tra JSON Schema 2020-12, XSD, hoặc lược đồ Avro/JSON của Apicurio theo mã lược đồ khai báo; lỗi trả bên gọi đồng bộ `400` với `ERR-04-101` kèm tối đa 20 lỗi theo đường dẫn trường (không lặp lại giá trị trường để tránh lộ dữ liệu), với bất đồng bộ đưa DLQ. Kiểm tra đính kèm: kiểu MIME trong danh sách cho phép của luồng, kích thước, quét mã độc qua dịch vụ DD-12 với tệp vượt 1 MiB.

#### FR-04-064 · Ủy quyền qua OPA

FR-04-064 (M; LGC-BUS-041; repo FR-04-005). Chặng `authz` gọi OPA cục bộ (sidecar hoặc dịch vụ trong namespace) với đầu vào `{tenant, caller, subscription, flow, operation, purpose, dataClasses}`; kết quả `allow`, `obligations` (ví dụ che trường). Từ chối trả `403` với `ERR-04-102`. OPA không phản hồi trong 200 ms thì từ chối (đóng an toàn). Nghĩa vụ che trường được chặng `respond` thi hành.

#### FR-04-065 · Chuyển đổi, chuẩn hóa về CDM và chuyển mã qua PH-07

FR-04-065 (M; LGC-BUS-036; repo FR-04-006, 007, 010). Chặng `transform` dùng biểu thức JQ (từ trình ánh xạ hoặc viết tay), dataformat (`jackson`, `jacksonXml`, `csv`, `bindy`), XSLT (chỉ hồ sơ JVM hoặc khi native được kiểm chứng). Chuyển mã dùng hàm `dh_map` tra ảnh chụp bảng ánh xạ PH-07 trong bộ nhớ, cập nhật theo sự kiện thay đổi của PH-07; mã không có trong bảng xử lý theo cấu hình (`FAIL`, `PASS_THROUGH`, `DEFAULT:<mã>`). Lỗi chuyển đổi trả `ERR-04-108`.

#### FR-04-066 · Làm giàu bản tin

FR-04-066 (M; repo FR-04-008). Chặng `enrich` gọi nguồn bổ sung (`enrich`, `pollEnrich`) qua kết nối PH-05 hoặc luồng con, có thời gian chờ riêng (mặc định 5 giây) và hành vi khi lỗi (`FAIL` hoặc `CONTINUE` có đánh dấu `dh-enrich-partial`).

#### FR-04-067 · Che, giả danh dữ liệu cá nhân theo chính sách PH-09

FR-04-067 (M; LGC-TOOL-012; repo FR-04-009). Chặng `respond` (và mọi chặng gửi đích) áp chính sách che của PH-09 theo phân loại trường của lược đồ và nghĩa vụ từ OPA: che một phần, băm có khóa, mã hóa trường, bỏ trường. Log và vết không bao giờ chứa giá trị trường phân loại Cá nhân hoặc Nhạy cảm (BR-04-013).

#### FR-04-068 · Định tuyến theo nội dung, tách, gộp, gọi song song, gửi đích

FR-04-068 (M với định tuyến, gửi đích; S với tách, gộp, song song; LGC-BUS-035; repo FR-04-011, 012, 013). Dùng EIP `choice`, `split`, `aggregate` (kho tổng hợp bền vững bằng PostgreSQL schema `ph04_rt` hoặc Valkey, không dùng bộ nhớ khi luồng có nhiều bản sao), `multicast` song song có thời gian chờ tổng, `recipientList` chỉ với danh sách đích khai báo tĩnh. Gửi đích qua kết nối PH-05; HTTT đích phải đã kết nạp và đang hoạt động ở PH-01 (`ERR-04-043` ở kiểm tra).

#### FR-04-069 · Phát sự kiện ra Kafka

FR-04-069 (M; LGC-BUS-039; repo FR-04-014). Gửi lên topic đã đăng ký, khóa phân vùng theo cấu hình luồng, tuần tự hóa theo lược đồ Apicurio, `acks=all`, lũy đẳng nhà sản xuất bật; tiêu đề `dh-tenant`, `traceparent`, `dh-flow`, `dh-source-system`.

#### FR-04-070 · Xử lý lỗi chuẩn: phân loại, thử lại, ngắt mạch, DLQ, dự phòng

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-070 · Xử lý lỗi chuẩn |
| Mức ưu tiên | M |
| Truy vết | REQ-04, REQ-18; LGC-BUS-037 · Mã repo: FR-04-015…019 (repo) |

`routeConfiguration` nền `dh-default-config` quy định:

| Loại lỗi | Ví dụ | Thử lại | Đích cuối |
|---|---|---|---|
| Tạm thời | Hệ đích 502, 503, 504, quá thời gian, mất kết nối | 3 lần, trễ tăng dần 1 s, 4 s, 16 s, có nhiễu ±20% | DLQ nếu vẫn lỗi |
| Hạn mức | Hệ đích 429 | Theo `Retry-After`, tối đa 3 lần | DLQ |
| Nghiệp vụ | Hệ đích 400, 404, 409, 422 | Không | Trả bên gọi (đồng bộ) hoặc DLQ (bất đồng bộ) |
| Dữ liệu | Sai lược đồ, lỗi chuyển đổi | Không | Trả bên gọi hoặc DLQ |
| Ủy quyền | OPA từ chối | Không | Trả bên gọi; không đưa DLQ (không lưu bản tin bị từ chối) |
| Nội bộ | Ngoại lệ không phân loại | 1 lần | DLQ, cảnh báo |

Ngắt mạch (`circuitBreaker` Resilience4j) theo từng hệ đích: mở khi tỷ lệ lỗi ≥ 50% trên cửa sổ 20 lượt, nửa mở sau 30 giây. Khi mạch mở, lượt đồng bộ nhận `503` với `ERR-04-105` hoặc đi nhánh dự phòng (`onFallback`) nếu luồng khai báo. DLQ là topic `{tenant}.ops.dlq.v1` của PH-18 với tiêu đề lý do, số lần thử, chặng lỗi, mã lỗi; thân bản tin được mã hóa trường nhạy cảm trước khi đưa DLQ.

#### FR-04-071 · Chống trùng bản tin

FR-04-071 (M; repo EN-04-07). Luồng bất đồng bộ và luồng đồng bộ có khai báo khóa chống trùng (tiêu đề `Idempotency-Key` hoặc biểu thức trên thân) dùng `idempotentConsumer` với kho Valkey `dh:int:idem:{tenant}:{flow}:{key}` TTL 24 giờ (cấu hình được). Bản tin trùng của luồng đồng bộ trả lại kết quả đã lưu nếu có (lưu tối đa 64 KiB), ngược lại `409` với `ERR-04-106`.

#### FR-04-072 · Truy cập CSDL trực tiếp có kiểm soát (Q359)

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-072 · Truy cập CSDL trực tiếp có kiểm soát |
| Mức ưu tiên | M |
| Truy vết | REQ-04, REQ-05; LGC-BUS-040; LGC-TOOL-008 · Quyết định Q359 (25/11/2026) |

Luồng được đọc trực tiếp CSDL khi đáp ứng đủ:

1. Kết nối CSDL khai báo ở PH-05 với loại "CSDL cho luồng", gồm máy chủ, cơ sở dữ liệu, schema được phép, tài khoản **chỉ đọc riêng cho từng luồng** (hoặc từng không gian làm việc khi TA cho phép), bí mật trong OpenBao, cấp phát động khi engine hỗ trợ (OpenBao database secrets engine, TTL 1 giờ).
2. Câu lệnh chỉ `SELECT` hoặc `WITH … SELECT`; trình kiểm tra phân tích câu lệnh (VR-13) và chặn `INSERT`, `UPDATE`, `DELETE`, `MERGE`, DDL, `COPY`, gọi hàm có tác dụng phụ trong danh sách cấm, nhiều câu lệnh trong một chuỗi. Tham số truyền bằng tham số ràng buộc (`:#name`), không ghép chuỗi.
3. Không tham chiếu schema của control plane (`ph01`…`ph20`, `public` của `pg-core`) hay CSDL `pg-payment`; tài khoản chỉ đọc không có quyền trên các schema đó ở mức CSDL (chốt chặn thật), kiểm tra tĩnh là lớp phụ.
4. Với CSDL của Datahub có RLS theo tenant (ví dụ kho dữ liệu dùng chung `ph06`, `ph07` bản đọc), mỗi lượt truy vấn chạy trong giao dịch có `SET LOCAL app.tenant_id = '<tenant của bản tin>'` do Kamelet nền `dh-sql-ro-source` hoặc processor nền đặt từ tiêu đề `dh-tenant`, không từ dữ liệu bên gọi.
5. Mọi truy vấn được ghi kiểm toán ở phía CSDL (pgaudit, lớp `READ` cho vai trò của luồng) và ở phía runtime (mã luồng, phiên bản, tenant, băm câu lệnh, số dòng, thời lượng, `traceId`; không ghi giá trị tham số).
6. Giới hạn: thời gian chờ câu lệnh (`statement_timeout`) mặc định 10 giây, số dòng tối đa mỗi lượt 10.000 (cấu hình theo kết nối), kích thước lô khi đọc định kỳ.
7. Ghi vào CSDL nghiệp vụ của HTTT thành viên (không phải CSDL Datahub) chỉ được khi kết nối PH-05 được duyệt riêng cho mục đích ghi, có SO đồng ý, và luồng đó được liệt kê trong phạm vi kết nối; mặc định cấm.

| Điều kiện | Mã lỗi | Khi nào |
|---|---|---|
| Câu lệnh vi phạm chính sách | ERR-04-031 | Kiểm tra hợp lệ (thiết kế, gửi duyệt) |
| Kết nối không phải loại chỉ đọc cho luồng | ERR-04-013 | Kiểm tra hợp lệ |
| Truy vấn quá thời gian hoặc vượt số dòng | ERR-04-108 | Runtime |

#### FR-04-073 · Ngữ cảnh tenant trên mỗi bản tin

FR-04-073 (M; ADR-003, D03-10). Mỗi exchange có tiêu đề `dh-tenant` đặt một lần ở chặng `receive` từ nguồn tin cậy (tiêu đề APISIX sau xác thực, tiền tố topic, hoặc cấu hình luồng với luồng lập lịch). Tiêu đề này bất biến: processor nền `TenantGuard` chặn mọi thay đổi sau chặng `receive`. Mọi lời gọi đi (HTTP tới dịch vụ Datahub, Kafka, CSDL, PH-07) mang tenant này. Luồng chạy trong namespace dùng chung chỉ xử lý bản tin có tenant đúng tenant sở hữu luồng; bản tin lệch tenant bị từ chối và cảnh báo ATTT.

#### FR-04-074 · Vết, chỉ số, log và nhật ký kết nối

FR-04-074 (M; LGC-BUS-030, 038; repo FR-04-023, 024, 025). Runtime dùng OpenTelemetry: lan truyền `traceparent` W3C, span theo chặng chuẩn; chỉ số Micrometer `dh_flow_exchanges_total`, `dh_flow_failures_total`, `dh_flow_duration_seconds` (histogram) theo nhãn `tenant`, `flow`, `version`, `route`, `stage`; log JSON có `traceId`, `tenant`, `flow`, không có thân bản tin. Chặng `audit` ghi nhật ký kết nối theo NĐ 278/2025 (bên gọi, bên cung cấp, dịch vụ, thời điểm, kết quả, mã vết, loại dữ liệu) lên topic `{tenant}.audit.connection-log.v1` để PH-13 lưu.

#### FR-04-075 · Hồ sơ runtime, biên dịch native và chế độ JVM

FR-04-075 (M; ADR-002, ADR-063). Nền tảng dựng các ảnh `dh-runtime` theo hồ sơ: `core-native` (HTTP, REST, Kafka, JQ, Jackson, SQL PostgreSQL, Kamelet nền), `files-native` (thêm FTP, SFTP, tệp, CSV), `soap-jvm` (CXF, XSLT, SOAP), `legacy-jvm` (thành phần cần cho luồng di trú chưa hỗ trợ native). Ảnh được ký (cosign), có SBOM, quét lỗ hổng ở CI. Luồng phát hành được gán hồ sơ nhỏ nhất chứa đủ thành phần; hệ thống báo khi không hồ sơ nào đủ (`ERR-04-029`).

### 5.7. Nhóm G — Danh mục thành phần, di trú, kiểm toán, tham số

#### FR-04-080 · Danh mục thành phần và chính sách thành phần được phép

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-080 · Danh mục thành phần và chính sách được phép |
| Mức ưu tiên | M |
| Truy vết | REQ-04, REQ-05; LGC-BUS-034, 040 · Mã repo: FR-D-070, 071, 072, 073 |
| Tác nhân, quyền | Xem: `PERM-04-read`. Quản lý chính sách: PA (`PERM-04-catalog-admin`) cho nền tảng, TA cho tenant (chỉ thu hẹp, không mở rộng) |
| Đầu ra | Danh mục duyệt được theo loại, nhãn; chi tiết thành phần: mô tả gốc, cú pháp URI, bảng thuộc tính theo nhóm, mức hỗ trợ, `deprecated`, mức native (`SUPPORTED`, `JVM_ONLY`, `NOT_APPLICABLE`), phụ thuộc (tọa độ Maven với component; phụ thuộc logic `camel:<tên>` với Kamelet), giấy phép và nguồn catalog, trạng thái chính sách (được phép, cần duyệt từng luồng, cấm) kèm lý do |

Chính sách nền mặc định: cho phép thành phần trong các nhóm HTTP, REST, Kafka, SQL (chỉ đọc theo FR-04-072), FTP, SFTP, tệp trong thư mục làm việc tạm, JQ, JSON, XML, CSV, mail gửi qua máy chủ thư của nền tảng, lập lịch, Kamelet nền; **cấm** `exec`, `ssh`, `docker`, `kubernetes-*`, thành phần đám mây công cộng ngoài danh sách (trừ khi tỉnh có hợp đồng và SO duyệt), ngôn ngữ kịch bản tùy ý, `bean` với lớp ngoài danh sách. Màn chi tiết hiện "không có tham số cấu hình" cho 9 Kamelet không có lược đồ thay vì báo lỗi. Thay đổi chính sách ghi kiểm toán và làm luồng đang dùng thành phần bị cấm hiện cảnh báo trên danh sách luồng.

#### FR-04-081 · Khớp phiên bản catalog với runtime

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-081 · Khớp phiên bản catalog với runtime |
| Mức ưu tiên | M |
| Truy vết | REQ-04 · Quyết định 25/11/2026 (catalog khớp đúng phiên bản Camel Quarkus của runtime) |
| Tác nhân, quyền | PA; tự động ở CI |

1. Mỗi hồ sơ runtime có tệp kê khai `runtime-manifest.json`: phiên bản Quarkus, Camel Quarkus, Camel, danh sách extension, băm ảnh.
2. Catalog của trình thiết kế sinh bằng công cụ từ `@kaoto/camel-catalog` (hoặc trực tiếp từ `camel-catalog` của đúng phiên bản) cho phiên bản Camel Quarkus trong tệp kê khai; tệp chỉ mục ghi `runtime`, `runtimeVersion`, `camelVersion`, `generatedAt`, băm.
3. CI của `dh-console` và `dh-integration` chặn khi `runtimeVersion` của catalog khác phiên bản trong tệp kê khai của hồ sơ mặc định (cổng CI bổ sung cho D04-02). Lệch 3.35.0 so với 3.33.2 (GAP-04-01) đã được xử lý bằng PR #5 (catalog 3.33.1, Camel 4.18.2). Lệch ở mức bản vá được chấp nhận khi công cụ so khớp xác nhận danh sách thành phần và lược đồ không đổi; lệch bản phụ (minor) trở lên luôn bị chặn.
4. Khi nền tảng nâng runtime, catalog mới được phát hành cùng; `dh-integration` đánh dấu mọi luồng cần kiểm tra lại (VR-17) và lập danh sách luồng có thành phần, thuộc tính bị bỏ hoặc đổi tên giữa hai phiên bản.
5. Trình thiết kế chỉ dùng một phiên bản catalog tại một thời điểm cho một tenant; phiên bản đang chạy của một luồng cũ có thể dùng catalog cũ ở chế độ chỉ đọc để hiển thị.

#### FR-04-082 · Chuyển luồng Camel XML của Bus cũ sang YAML

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-04-082 · Chuyển luồng Camel XML của Bus cũ sang YAML |
| Mức ưu tiên | M |
| Truy vết | REQ-04, REQ-22; LGC-BUS-033; LGC-TOOL-015 |
| Tác nhân, quyền | IE, đội di trú |
| Đầu vào | Tệp Camel XML (Spring XML hoặc XML DSL) ≤ 2 MiB, hoặc gói xuất từ bảng `Context`, `Context_file` của hệ cũ; ánh xạ kết nối cũ sang kết nối PH-05 |
| Đầu ra | Báo cáo chuyển đổi và luồng nháp mới (`origin = LEGACY_XML`) |

1. Công cụ chuyển (dựa trên `camel-xml-io` và bộ ghi YAML của Camel cùng phiên bản) đọc XML, tách bean Spring, route, `routeContext`, `restContext`.
2. Tham số kết nối có máy chủ, tài khoản, mật khẩu được gỡ khỏi định nghĩa và thay bằng chỗ trống `{{conn:CHUA_GAN.<khóa>}}`; báo cáo liệt kê kết nối cần khai báo ở PH-05. Mật khẩu cũ không được lưu ở bất kỳ đâu trong Datahub.
3. Phần không chuyển được (bean Spring tùy biến, lớp Java của hệ cũ, thành phần bị cấm) được giữ dạng chú thích và đánh dấu chặng "Cần xử lý tay" trên sơ đồ.
4. Báo cáo chuyển đổi gồm: số route, số chặng chuyển được, số chặng cần xử lý tay, thành phần bị cấm, kết nối cần khai báo, khuyến nghị bổ sung chín chặng chuẩn. Báo cáo là đầu vào của kế hoạch di trú D06-01 và kiểm thử đối chiếu chạy song song.

| Điều kiện | Mã lỗi | HTTP |
|---|---|---|
| Tệp không phải Camel XML hoặc vượt kích thước | ERR-04-032 | 422 |

#### FR-04-083 · Lịch sử thao tác và kiểm toán của luồng

FR-04-083 (M; LGC-BUS-032, 033). Tab "Lịch sử" của chi tiết luồng liệt kê bản ghi kiểm toán của luồng và các phiên bản, triển khai, lệnh điều khiển, lần chạy thử, theo thời gian giảm dần, lọc theo loại hành động và người thực hiện; lấy từ PH-13 qua API-04-091. Xem cần `PERM-04-read`; nội dung giá trị trước, sau chỉ hiện cho AU, SO, TA.

#### FR-04-084 · Tham số PH-04 theo tenant và đóng băng thay đổi

FR-04-084 (S; LGC-BUS-031). TA đặt tham số `04.*` trong miền cho phép (mục 7.1) qua màn tham số chung của PH-18; biến cấu hình theo môi trường dùng trong biểu thức (`{{dh.env.<tên>}}`, Mã repo FR-04-036) khai báo ở đây với giá trị theo TEST, STAGING, PROD. TA, SO đặt **khoảng đóng băng thay đổi** (ví dụ kỳ cao điểm cuối năm): trong khoảng này mọi phát hành, thăng cấp tới PROD bị chặn với `ERR-04-041`, trừ quay lui và tạm dừng khẩn.

## 6. Quy tắc nghiệp vụ

| Mã | Quy tắc | FR áp dụng |
|---|---|---|
| BR-04-001 | Mã luồng duy nhất trong tenant, không đổi sau khi tạo; mã của luồng đã xóa mềm được giải phóng sau 30 ngày | FR-04-003, 006 |
| BR-04-002 | Luồng đối ngoại phải có đủ chín chặng chuẩn đúng thứ tự khi gửi duyệt và phát hành; luồng nội bộ chỉ nhận cảnh báo. Khung chuẩn gỡ được lúc thiết kế (kế thừa BR-D-01 sửa ngày 06/8/2026 của repo) | FR-04-023, 040, 042 |
| BR-04-003 | Định nghĩa luồng không được chứa bí mật; chỉ tham chiếu `{{conn:…}}`, `{{vault:…}}` hoặc `#bean` | FR-04-016, 023 |
| BR-04-004 | Gửi duyệt cần ít nhất một lần chạy thử `PASSED` không mô phỏng trên đúng băm định nghĩa đang gửi, và mọi ca kiểm thử gắn với luồng đạt | FR-04-030, 040 |
| BR-04-005 | Người duyệt khác người tạo, người đóng góp và người gửi duyệt của phiên bản (bốn mắt); chốt ở máy chủ | FR-04-041 |
| BR-04-006 | Quay vòng YAML không mất dữ liệu: băm YAML chuẩn hóa không đổi khi mở rồi lưu mà không sửa | FR-04-017 |
| BR-04-007 | Bản tin mẫu, bố cục sơ đồ, ghi chú dán không đi vào YAML đem triển khai | FR-04-017, 022, 026 |
| BR-04-008 | Mọi luồng có xử lý lỗi với DLQ tới PH-18, trực tiếp hoặc qua `routeConfiguration` nền | FR-04-023, 070 |
| BR-04-009 | Luồng chỉ gửi, nhận trên topic đã đăng ký ở PH-10 mà luồng được cấp quyền publish, subscribe | FR-04-023, 062, 069 |
| BR-04-010 | Tenant của bản tin đặt một lần ở chặng tiếp nhận từ nguồn tin cậy và bất biến trong suốt luồng | FR-04-061, 062, 073 |
| BR-04-011 | Mã route duy nhất trong mỗi namespace runtime; đường dẫn HTTP duy nhất trong tenant | FR-04-005, 023 |
| BR-04-012 | Chỉ phiên bản `APPROVED` được triển khai; không có kênh nào nạp định nghĩa vào runtime ngoài kho cấu hình (trừ sandbox chạy thử) | FR-04-042 |
| BR-04-013 | Log, vết, chỉ số, nhật ký chạy thử không chứa giá trị trường phân loại Cá nhân, Nhạy cảm, Bí mật; thân bản tin chỉ lưu ở nhật ký chạy thử khi được bật và trong thời hạn lưu | FR-04-030, 032, 067, 074 |
| BR-04-014 | Luồng chỉ dùng thành phần được phép; thành phần không hỗ trợ native chỉ chạy trong hồ sơ JVM được phép cho tenant | FR-04-012, 075, 080 |
| BR-04-015 | Truy cập CSDL trực tiếp theo Q359: tài khoản chỉ đọc riêng theo luồng khai báo ở PH-05, chỉ câu lệnh đọc, có kiểm toán, đặt `app.tenant_id`, không truy cập CSDL control plane | FR-04-072 |
| BR-04-016 | Một luồng có tối đa một phiên bản mở; phiên bản đã gửi duyệt là bất biến | FR-04-011, 040 |
| BR-04-017 | Mọi thay đổi trạng thái luồng, phiên bản, triển khai và mọi lệnh điều khiển có lý do (với tạm dừng, gỡ, quay lui) và được ghi kiểm toán | FR-04-006, 044, 050 |
| BR-04-018 | Trạng thái mong muốn trong kho cấu hình là nguồn sự thật; lệnh khẩn qua topic điều khiển phải được đối soát vào Git trong 5 phút | FR-04-050 |
| BR-04-019 | Phiên bản triển khai lên môi trường cao hơn phải đã `SYNCED` và khỏe ở môi trường trước, trừ quay lui | FR-04-042, 045 |
| BR-04-020 | Trình thiết kế dùng catalog đúng phiên bản runtime của tenant; định nghĩa được kiểm tra trên catalog khác phiên bản không được gửi duyệt | FR-04-081, 023 |
| BR-04-021 | Không gian làm việc giới hạn quyền sửa, duyệt khi `04.workspace.enforce` bật; TA, PA không bị giới hạn | FR-04-007 |
| BR-04-022 | Trong khoảng đóng băng thay đổi, không phát hành, thăng cấp tới PROD; quay lui và tạm dừng khẩn vẫn được | FR-04-042, 084 |

## 7. Tham số và yêu cầu phi chức năng

### 7.1. Tham số PH-04

| Tham số | Kiểu | Mặc định | Miền | Ý nghĩa |
|---|---|---|---|---|
| `04.workspace.enforce` | boolean | `false` | — | Giới hạn quyền theo không gian làm việc |
| `04.flow.max-definition-kb` | số | 512 | 64…2.048 | Kích thước định nghĩa tối đa |
| `04.env.stages` | danh sách | `TEST,PROD` | tập con có thứ tự của `TEST,STAGING,PROD` | Môi trường và thứ tự thăng cấp |
| `04.env.soak-minutes.STAGING` | số | 30 | 0…1.440 | Thời gian chạy ổn định trước khi thăng cấp |
| `04.env.prod-requires-promote` | boolean | `true` | — | Lên PROD cần `PERM-04-promote` |
| `04.review.require-test` | boolean | `true` | Không tắt được cho luồng đối ngoại | Điều kiện chạy thử khi gửi duyệt |
| `04.review.checklist` | danh sách | 4 mục (FR-04-041) | 1…10 mục | Checklist của người duyệt |
| `04.test.max-concurrent` | số | 5 | 1…20 | Số lần chạy thử đồng thời mỗi tenant |
| `04.test.allow-simulation` | boolean | `false` | — | Cho chạy mô phỏng khi sandbox không sẵn |
| `04.test.retention-days` | số | 90 | 7…365 | Lưu metadata lần chạy thử |
| `04.test.body-retention-days` | số | 7 | 0…30 | Lưu thân bản tin chạy thử |
| `04.deploy.timeout-minutes` | số | 10 | 2…60 | Hạn đồng bộ triển khai |
| `04.runtime.max-body-kb` | số | 10.240 | 64…51.200 | Kích thước bản tin tối đa |
| `04.runtime.sync-timeout-seconds` | số | 30 | 1…120 | Thời gian chờ mặc định của luồng đồng bộ |
| `04.runtime.idempotency-ttl-hours` | số | 24 | 1…168 | Thời gian giữ khóa chống trùng |
| `04.sql.statement-timeout-seconds` | số | 10 | 1…120 | Thời gian chờ câu lệnh CSDL |
| `04.sql.max-rows` | số | 10.000 | 1…100.000 | Số dòng tối đa mỗi lượt |
| `04.freeze.windows` | danh sách khoảng thời gian | rỗng | — | Khoảng đóng băng thay đổi |
| `04.flow.require-legal-basis` | boolean | `false` | — | Luồng đối ngoại phải khai căn cứ pháp lý khi tạo (bổ sung từ D03-06-PH04) |
| `04.review.sla-hours` | số | 24 | 1…168 | Ngưỡng thời gian chờ duyệt để cảnh báo (bổ sung từ D03-06-PH04) |
| `04.review.require-reauth` | boolean | `false` | Luôn `true` khi môi trường đích là PROD | Xác thực lại khi duyệt, phát hành (bổ sung từ D03-06-PH04) |
| `04.deploy.rollback-suggest-error-ratio` | số | 2,0 | 1,1…10 | Gợi ý quay lui khi tỷ lệ lỗi 5 phút đầu gấp n lần phiên bản trước; không tự quay lui (bổ sung từ D03-06-PH04) |
| `04.mapping.require-all-required` | boolean | `false` | — | Trường bắt buộc của lược đồ đích chưa ánh xạ là lỗi ở mức `SUBMIT` (bổ sung từ D03-06-PH04) |

### 7.2. Yêu cầu phi chức năng riêng của PH-04

| Mã | Yêu cầu | Ngưỡng | Cách đo |
|---|---|---|---|
| NFR-04-001 | Mở bảng thành phần với toàn bộ catalog | < 300 ms sau khi catalog đã nạp vào bộ đệm | Đo trên máy văn phòng chuẩn D05-03 |
| NFR-04-002 | Gõ tìm trong bảng thành phần | < 50 ms mỗi lần gõ | Đo `performance.now` |
| NFR-04-003 | Kéo chặng trên sơ đồ 200 chặng | ≥ 50 khung hình/giây (PTN-07); tối thiểu chấp nhận 30 | Chrome DevTools |
| NFR-04-004 | Mở trình thiết kế với luồng 200 chặng | < 2 s tới khi tương tác được | Lighthouse TTI |
| NFR-04-005 | Sinh lại YAML sau một thay đổi | < 100 ms | Kiểm thử đơn vị đo |
| NFR-04-006 | Mở cửa sổ cấu hình chặng 154 thuộc tính | < 400 ms | |
| NFR-04-007 | Kiểm tra hợp lệ máy chủ mức `SUBMIT` | p95 < 2 s với luồng 200 chặng | Kiểm thử tải API |
| NFR-04-008 | Chạy thử `MOCK` luồng mẫu chín chặng | p95 < 5 s từ lúc gửi tới khi có kết quả (gồm khởi tạo context) | |
| NFR-04-009 | Từ duyệt PROD tới `SYNCED` | p95 < 3 phút | Đo trên môi trường STAGING |
| NFR-04-010 | Từ lệnh tạm dừng tới mọi bản sao xác nhận | p95 < 10 s; khẩn < 5 s | |
| NFR-04-011 | Độ trễ thêm của khung chín chặng (không tính gọi đích) | p95 < 15 ms với bản tin JSON 10 KiB | Kiểm thử tải `dh-runtime` |
| NFR-04-012 | Thông lượng một vCPU `dh-runtime` native, luồng chuyển đổi JSON chuẩn | ≥ 400 bản tin/giây (D03-09) | |
| NFR-04-013 | Khởi động pod `dh-runtime` native tới sẵn sàng | < 1 s không tính nạp luồng; < 5 s với 50 luồng | |
| NFR-04-014 | Sẵn sàng data plane | 99,9% (KPI-03) | Theo D03-09 |
| NFR-04-015 | Giao diện trình thiết kế dùng được hoàn toàn bằng bàn phím | Tạo luồng ba chặng không dùng chuột | Kiểm thử thủ công D05-02-PH04 |
| NFR-04-016 | Tương phản và khả năng truy cập | WCAG 2.2 AA trên mọi màn UI-04 | axe-core, kiểm thử thủ công |
| NFR-04-017 | Bề rộng màn hình trình thiết kế | 1280…2560 px đầy đủ; 1024…1279 px panel tự gập; dưới 1024 px chỉ xem YAML | |

## 8. Mã lỗi, sự kiện và danh mục API

### 8.1. Mã lỗi ERR-04

Bảng mã lỗi chính thức nằm ở D03-04-PH04 §6. Tóm tắt nhóm mã: `ERR-04-001…049` lỗi của API điều khiển `dh-integration`; `ERR-04-101…120` lỗi do `dh-runtime` trả cho bên gọi luồng hoặc ghi vào DLQ.

### 8.2. Sự kiện EVT-04

| Mã | Topic | Phát khi |
|---|---|---|
| EVT-04-01 | `{tenant}.integration.flow.created.v1` | Tạo luồng |
| EVT-04-02 | `{tenant}.integration.flow.updated.v1` | Sửa thông tin luồng |
| EVT-04-03 | `{tenant}.integration.version.submitted.v1` | Gửi duyệt |
| EVT-04-04 | `{tenant}.integration.version.approved.v1` | Duyệt |
| EVT-04-05 | `{tenant}.integration.version.changes-requested.v1` | Từ chối |
| EVT-04-06 | `{tenant}.integration.deployment.requested.v1` | Yêu cầu triển khai, gỡ, quay lui |
| EVT-04-07 | `{tenant}.integration.deployment.status-changed.v1` | Trạng thái triển khai đổi |
| EVT-04-08 | `{tenant}.integration.flow.runtime-state-changed.v1` | Luồng, route tạm dừng, tiếp tục đã xác nhận |
| EVT-04-09 | `{tenant}.integration.flow.retired.v1` | Luồng đã gỡ |
| EVT-04-10 | `{tenant}.integration.testrun.completed.v1` | Lần chạy thử kết thúc |
| EVT-04-11 | `dh.integration.runtime.command.v1` | Lệnh điều khiển runtime (topic hệ thống, có ký) |
| EVT-04-12 | `dh.integration.runtime.heartbeat.v1` | Nhịp tim của bản sao runtime |
| EVT-04-13 | `dh.integration.runtime.command-ack.v1` | Xác nhận lệnh |
| EVT-04-14 | `{tenant}.audit.connection-log.v1` | Nhật ký kết nối của chặng `audit` (chủ quản topic là PH-13) |

### 8.3. Danh mục API theo FR

| FR | API |
|---|---|
| FR-04-001, 002 | API-04-010, 012, 016 |
| FR-04-003…006 | API-04-011, 013, 014, 015, 016 |
| FR-04-007 | API-04-001…004 |
| FR-04-010, 011, 024 | API-04-020, 021, 022, 023, 024, 034 |
| FR-04-012, 080, 081 | API-04-070…074 |
| FR-04-015, 020 | API-04-032, 033 |
| FR-04-023 | API-04-030, 031 |
| FR-04-025 | API-04-080…082 |
| FR-04-027, 082 | API-04-026, 027, 028 |
| FR-04-030…032 | API-04-040…044 |
| FR-04-040, 041 | API-04-050…053 |
| FR-04-042…045 | API-04-025, 054, 055, 056 |
| FR-04-050…053 | API-04-060…063 |
| FR-04-083, 084 | API-04-090, 091 |

## 9. Truy vết

### 9.1. Chức năng hệ cũ sang FR

Bảng chứng minh mọi chức năng của Bus và Tooling kiểm kê ở D00-03 §4.1, §4.2 đều có kết luận. Cột "Mức" lấy theo D00-03.

| Mã LGC | Chức năng hệ cũ | FR phủ (PH-04) hoặc phân hệ khác | Mức |
|---|---|---|---|
| LGC-BUS-001 | Danh sách chương trình tích hợp có phân trang | FR-04-001 | Nâng cấp |
| LGC-BUS-002 | Tìm theo endpoint | FR-04-001 (`endpoint`) | Giữ nguyên |
| LGC-BUS-003 | Tìm theo nguồn | FR-04-001 (`sourceSystem`) | Giữ nguyên |
| LGC-BUS-004 | Tìm theo tên | FR-04-001 (`q`) | Giữ nguyên |
| LGC-BUS-005 | Tìm theo host | FR-04-001 (`environment`, `namespace`) | Thay thế |
| LGC-BUS-006 | Metadata chương trình | FR-04-002, 004 | Nâng cấp |
| LGC-BUS-007 | Biểu đồ lượng bản tin theo giây | PH-13; nhúng ở FR-04-053 | Thay thế |
| LGC-BUS-008 | Danh sách route của chương trình | FR-04-002 | Giữ nguyên |
| LGC-BUS-009 | Start/Stop agent | FR-04-050 | Nâng cấp |
| LGC-BUS-010 | Xóa chương trình | FR-04-006 | Nâng cấp |
| LGC-BUS-011 | Sửa host, port, method | FR-04-004, 011, 014; PH-05 | Thay thế |
| LGC-BUS-012 | Kích hoạt, hủy chương trình | FR-04-050, 006 | Nâng cấp |
| LGC-BUS-013 | Thêm chương trình có kiểm tra kết nối | FR-04-003, 030; PH-05 kiểm tra kết nối | Nâng cấp |
| LGC-BUS-014 | Tổng quan số agent hoạt động | PH-13; FR-04-051 | Thay thế |
| LGC-BUS-015 | Số liệu từng agent | PH-13; FR-04-051, 053 | Thay thế |
| LGC-BUS-016 | CPU, bộ nhớ agent | PH-13; FR-04-053 | Thay thế |
| LGC-BUS-017 | Chi tiết agent | FR-04-002, 051 | Thay thế |
| LGC-BUS-018 | Dữ liệu các route | FR-04-002 | Giữ nguyên |
| LGC-BUS-019 | Biểu đồ theo route | PH-13; FR-04-053 | Thay thế |
| LGC-BUS-020 | Tab endpoint | FR-04-002, 052 | Giữ nguyên |
| LGC-BUS-021 | Tab thuộc tính route | FR-04-002 | Giữ nguyên |
| LGC-BUS-022 | Tab đồ thị route | FR-04-002, 033 | Nâng cấp |
| LGC-BUS-023 | Tab mã nguồn | FR-04-002, 043 | Nâng cấp |
| LGC-BUS-024 | Tab dữ liệu thêm | FR-04-002 | Giữ nguyên |
| LGC-BUS-025 | Trạng thái hoạt động, dừng | FR-04-001, 051 | Giữ nguyên |
| LGC-BUS-026 | Start/Stop từng route | FR-04-050 | Nâng cấp |
| LGC-BUS-027 | Thống kê theo endpoint | PH-13; FR-04-052 | Thay thế |
| LGC-BUS-028 | REST API của agent | PH-02; FR-04-052 | Thay thế |
| LGC-BUS-029 | Log của agent | PH-13; FR-04-053 | Thay thế |
| LGC-BUS-030 | Lấy dữ liệu từ JMX/Jolokia | PH-13; FR-04-051, 074 | Thay thế |
| LGC-BUS-031 | Cấu hình hệ thống | PH-18, PH-20; FR-04-084 | Nâng cấp |
| LGC-BUS-032 | Project, group, phân quyền | FR-04-007; PH-12 | Nâng cấp |
| LGC-BUS-033 | Lưu context XML, trạng thái, tệp | FR-04-042, 082 | Thay thế |
| LGC-BUS-034 | Dependency Maven, builder | FR-04-075, 080 | Thay thế |
| LGC-BUS-035 | Routing giữa kênh | FR-04-068 | Giữ nguyên |
| LGC-BUS-036 | Transformation | FR-04-020, 065; PH-07 | Nâng cấp |
| LGC-BUS-037 | Error handling | FR-04-070; PH-18 | Nâng cấp |
| LGC-BUS-038 | Logging routing | FR-04-074; PH-13 | Thay thế |
| LGC-BUS-039 | Document và event message | FR-04-061, 062, 069 | Giữ nguyên |
| LGC-BUS-040 | Danh mục connector | PH-05; FR-04-012, 016, 072 | Nâng cấp |
| LGC-BUS-041 | Bảo mật route, bản tin, endpoint | FR-04-016, 064, 067; PH-03, PH-12 | Nâng cấp |
| LGC-TOOL-001 | Thanh Project | FR-04-001, 010 | Nâng cấp |
| LGC-TOOL-002 | Thêm project | FR-04-003, 025 | Nâng cấp |
| LGC-TOOL-003 | Thanh Component thu gọn | FR-04-012 | Giữ nguyên |
| LGC-TOOL-004 | Thanh Component mở rộng | FR-04-012 | Giữ nguyên |
| LGC-TOOL-005 | Tìm component | FR-04-012 | Giữ nguyên |
| LGC-TOOL-006 | Nhóm Routing | FR-04-012 | Giữ nguyên |
| LGC-TOOL-007 | Nhóm Data Transformation | FR-04-012, 020 | Nâng cấp |
| LGC-TOOL-008 | Nhóm Database Connection | FR-04-012, 016, 072 | Nâng cấp |
| LGC-TOOL-009 | Nhóm Network | FR-04-012 | Giữ nguyên |
| LGC-TOOL-010 | Nhóm Message Broker | FR-04-012; PH-10 | Nâng cấp |
| LGC-TOOL-011 | Nhóm Scheduling | FR-04-012 | Giữ nguyên |
| LGC-TOOL-012 | Nhóm bảo mật | FR-04-012, 067; PH-09 | Nâng cấp |
| LGC-TOOL-013 | Đường kết nối giữa component | FR-04-013 | Giữ nguyên |
| LGC-TOOL-014 | Lưu kết quả thiết kế | FR-04-024 | Nâng cấp |
| LGC-TOOL-015 | Tải mã XML | FR-04-027 (YAML) | Thay thế |
| LGC-TOOL-016 | Xóa project | FR-04-006 | Giữ nguyên |
| LGC-TOOL-017 | Clear Page | FR-04-013 | Giữ nguyên |
| LGC-TOOL-018 | Thu, phóng | FR-04-013 | Giữ nguyên |
| LGC-TOOL-019 | Thanh Properties | FR-04-014 | Nâng cấp |
| LGC-TOOL-020 | Lưu dữ liệu gốc, reset tham số | FR-04-014 | Giữ nguyên |
| LGC-TOOL-021 | Đồng bộ hai chiều | FR-04-017 | Giữ nguyên |
| LGC-TOOL-022 | Cập nhật pom | — | Loại bỏ (D00-03 §6) |
| LGC-TOOL-023 | Thêm, xóa component, chèn ngang, dọc | FR-04-013 | Giữ nguyên |
| LGC-TOOL-024 | Tạo, xóa kết nối; bắt kết nối khi thả | FR-04-013 | Giữ nguyên |
| LGC-TOOL-025 | Nhiều component, nhiều route | FR-04-013 | Giữ nguyên |
| LGC-TOOL-026 | Source tab hai chiều | FR-04-017 | Giữ nguyên |
| LGC-TOOL-027 | Nhập component từ JAR | — (thay bằng FR-04-018 và quy trình đăng ký Kamelet PH-05) | Loại bỏ (D00-03 §6) |
| LGC-TOOL-028 | Data mapping | FR-04-020 | Nâng cấp |
| LGC-TOOL-029 | Phiên nháp `draft_session` | FR-04-010, 024 | Giữ nguyên |

Kết quả: 41/41 mục LGC-BUS và 29/29 mục LGC-TOOL có kết luận; 2 mục loại bỏ có lý do ATTT ghi ở D00-03 §6; 15 mục chuyển một phần hoặc toàn bộ sang PH-13 và có phần nhúng ở PH-04.

### 9.2. FR sang use case, màn hình và kiểm thử

| FR | Mức | UC | UI | TS (D05-02-PH04) |
|---|---|---|---|---|
| FR-04-001, 002 | M | UC-04-02 | UI-04-01, 02 | TS-04-01 |
| FR-04-003 | M | UC-04-03 | UI-04-03 | TS-04-02 |
| FR-04-004, 005, 006 | M (005: S) | UC-04-02, 16 | UI-04-02 | TS-04-03 |
| FR-04-007 | S | UC-04-01 | UI-04-21 | TS-04-04 |
| FR-04-010, 011, 024 | M | UC-04-04 | UI-04-04 | TS-04-05 |
| FR-04-012 | M | UC-04-04 | UI-04-04 (bảng thành phần) | TS-04-06 |
| FR-04-013 | M | UC-04-04 | UI-04-04 (canvas) | TS-04-07 |
| FR-04-014, 016 | M | UC-04-05 | UI-04-05 | TS-04-08 |
| FR-04-015 | M | UC-04-05 | UI-04-06 | TS-04-09 |
| FR-04-017 | M | UC-04-04 | UI-04-04 (chế độ YAML, chia đôi) | TS-04-10 |
| FR-04-018, 019, 021 | S | UC-04-07 | UI-04-08, 09, 10 | TS-04-11 |
| FR-04-020 | M | UC-04-06 | UI-04-07 | TS-04-12 |
| FR-04-022 | M | UC-04-05 | UI-04-05 (cột vào) | TS-04-09 |
| FR-04-023 | M | UC-04-04, 10 | UI-04-04 (bảng Vấn đề) | TS-04-13 |
| FR-04-025 | S | UC-04-03 | UI-04-19 | TS-04-02 |
| FR-04-026, 027 | C/S, M | UC-04-04 | UI-04-04 | TS-04-14 |
| FR-04-030, 033 | M | UC-04-08 | UI-04-11 | TS-04-15 |
| FR-04-031 | S | UC-04-09 | UI-04-13 | TS-04-16 |
| FR-04-032 | M | UC-04-08 | UI-04-12 | TS-04-15 |
| FR-04-040 | M | UC-04-10 | UI-04-04 (hộp gửi duyệt) | TS-04-17 |
| FR-04-041 | M | UC-04-11 | UI-04-14 | TS-04-18 |
| FR-04-042, 045 | M, S | UC-04-12 | UI-04-15 | TS-04-19 |
| FR-04-043 | M | UC-04-11 | UI-04-16 | TS-04-18 |
| FR-04-044 | M | UC-04-13 | UI-04-15 | TS-04-20 |
| FR-04-050 | M | UC-04-14, 15 | UI-04-02 (tab Triển khai) | TS-04-21 |
| FR-04-051, 052, 053 | M, M, S | UC-04-02 | UI-04-02 | TS-04-22 |
| FR-04-060…075 | M (068 một phần S) | UC-04-17, 18, 19 | — | TS-04-23…27 |
| FR-04-080, 081 | M | UC-04-21, 22 | UI-04-17 | TS-04-28 |
| FR-04-082 | M | UC-04-20 | UI-04-18 | TS-04-29 |
| FR-04-083 | M | Mọi UC ghi | UI-04-02 (tab Lịch sử) | TS-04-30 |
| FR-04-084 | S | — | UI-04-20 | TS-04-31 |

### 9.3. Phạm vi MVP

PH-04 thuộc MVP (D02-01 §8.3). Quy ước: FR mức M thuộc MVP; S thuộc đợt 2 nhưng mô hình dữ liệu và API được chừa sẵn; C làm khi có nhu cầu. Bảng sau liệt kê phần không thuộc MVP; mọi FR khác ở mục 5 thuộc MVP.

| FR | Mức | Đợt | Lý do |
|---|---|---|---|
| FR-04-005 Nhân bản luồng | S | Đợt 2 | Tạo từ khuôn mẫu, nhập YAML đáp ứng nhu cầu ở MVP |
| FR-04-007 Không gian làm việc | S | Đợt 2 | MVP dùng không gian `DEFAULT`, phân quyền theo vai trò tenant |
| FR-04-018 Kamelet tự viết | S | Đợt 2 | MVP dùng Kamelet nền và Kamelet vendor được phép |
| FR-04-019 Pipe | S | Đợt 2 | Luồng `ROUTE` phủ được các ca Pipe |
| FR-04-021 Bean, metadata | S | Đợt 2 | `routeConfiguration` nền đáp ứng MVP |
| FR-04-025 Thư viện khuôn mẫu đầy đủ | S | Đợt 2 | MVP có `tpl-standard-9`, `tpl-sync-lookup`, `tpl-db-poll-to-kafka` dựng sẵn |
| FR-04-026 Ghi chú dán, luồng con | C, S | Đợt 2 | Tiện ích |
| FR-04-031 Ca kiểm thử | S | Đợt 2 | MVP dùng chạy thử thủ công làm điều kiện gửi duyệt |
| FR-04-045 Thăng cấp nhiều môi trường | S | Đợt 2 | MVP có TEST và PROD |
| FR-04-053 Giám sát nhúng | S | Đợt 2 | MVP liên kết sang PH-13 |
| FR-04-068 Tách, gộp, song song | S | Đợt 2 | Khi có luồng thật cần |
| FR-04-084 Tham số theo tenant | S | Đợt 2 | MVP đặt tham số bằng cấu hình triển khai |

Các hạng mục bắt buộc xong trước khi đóng MVP vì là chỗ lệch mã so với thiết kế: GAP-04-01 (catalog khớp runtime), GAP-04-03 (GitOps thật), GAP-04-04 (chạy thử thật), GAP-04-05, 06 (bốn mắt), GAP-04-07 (tenant, RLS), GAP-04-10 (Q359), GAP-04-11 (tạm dừng thật), GAP-04-12 (DLQ chuẩn). GAP-04-02 (chuyển Java DSL sang YAML) và GAP-04-08, 09, 13 có thể làm song song đầu đợt 2.

## 10. Phụ thuộc, giả định và ràng buộc

### 10.1. Phụ thuộc với phân hệ khác

| Phân hệ | Hướng | Cơ chế | Khi không sẵn sàng |
|---|---|---|---|
| PH-01 Kết nạp HTTT | PH-04 dùng | Bản sao đọc `ph04.external_system` qua sự kiện, xác định luồng đối ngoại | Kiểm tra hiểu luồng là nội bộ (nới, không siết nhầm), cảnh báo |
| PH-02 Danh mục dịch vụ | Hai chiều | PH-04 đọc OpenAPI để sinh luồng; PH-02 công bố điểm vào của luồng làm backend | Không tạo được luồng từ API |
| PH-03 APISIX | PH-04 dùng | Định tuyến lượt gọi đồng bộ tới `dh-runtime` | Luồng đồng bộ ngừng nhận (ngoài phạm vi) |
| PH-05 Bộ điều hợp, kết nối | PH-04 dùng | Danh sách kết nối, Kamelet được duyệt, tài khoản CSDL chỉ đọc | Không chọn được kết nối mới; luồng đang chạy không ảnh hưởng |
| PH-07 Danh mục | PH-04 dùng | Bảng ánh xạ mã, ảnh chụp trong bộ nhớ runtime | Runtime dùng ảnh chụp gần nhất |
| PH-09 Dữ liệu cá nhân | PH-04 dùng | Phân loại trường, chính sách che | Runtime dùng chính sách đệm; không có thì đóng an toàn |
| PH-10 Sự kiện | PH-04 dùng | Topic, lược đồ, quyền publish, subscribe | Kiểm tra VR-10 không chạy được: chặn gửi duyệt |
| PH-12 IAM | PH-04 dùng | Vai trò, nhóm, OPA | Không đăng nhập được (ngoài phạm vi) |
| PH-13 Giám sát | PH-04 dùng | Kiểm toán, số liệu, log | Kiểm toán giữ ở outbox |
| PH-18 Vận hành | PH-04 dùng | DLQ, tham số | Bản tin lỗi giữ ở topic DLQ tới khi PH-18 xử lý |
| PH-20 Tenant | PH-04 dùng | Khởi tạo namespace runtime, kho cấu hình, không gian `DEFAULT` cho tenant mới | — |

### 10.2. Giả định

Thứ nhất, kho cấu hình Git của nền tảng là GitHub ở giai đoạn phát triển và GitLab on-prem khi bàn giao (Q353); `dh-integration` ghi qua API chuẩn của Git (HTTP smart protocol) nên không phụ thuộc nhà cung cấp. Thứ hai, Argo CD được triển khai theo ADR-009 trước khi đóng MVP. Thứ ba, số luồng của một tỉnh cỡ vừa khoảng 120 luồng ở năm đầu, 300 luồng ở năm thứ ba (giả định, căn cứ D03-10 §5 đặt ngưỡng 1.000 luồng hoạt động toàn nền tảng và ngưỡng 50 luồng để tách namespace); tỉnh thí điểm chưa có số liệu thật. Thứ tư, khoảng 60% luồng Bus cũ là REST hoặc SOAP đồng bộ đơn giản, 25% đọc CSDL hoặc tệp định kỳ, 15% phức tạp có bean tùy biến (giả định dựa trên mô tả nhóm connector của Bus cũ; dùng để ước lượng công di trú, cần đo lại khi có gói xuất của tỉnh). Thứ năm, catalog `@kaoto/camel-catalog` có bản phát hành cho Camel Quarkus 3.33.x; nếu không, công cụ sinh catalog dùng trực tiếp `camel-catalog` 4.18.

### 10.3. Ràng buộc

FRS chịu các ràng buộc: phân quyền theo D02-08 (quyền đề xuất ở mục 3.3 chờ gộp); đa tenant theo D03-10; ATTT theo D03-07 (cấm mã tùy ý, quản lý thay đổi, nhật ký); hạ tầng theo D03-09 (namespace, vùng Z4, priority class); ADR-002, 009, 010, 013 và ADR-060…069; quyết định Q359.

## 11. Câu hỏi mở

Câu hỏi của các tài liệu khác trong bộ PH-04 được quản lý ở chính tài liệu đó (D03-02-PH04: Q04-20…29; D03-06-PH04: Q04-30…39; D05-02-PH04: Q04-40…44; D02-04-PH04: Q04-45…49). Theo chỉ đạo của chủ đầu tư ngày 25/11/2026, câu hỏi thiếu dữ liệu thật được giải bằng giả định ghi rõ cơ sở; chỉ câu hỏi về lựa chọn thiết kế được đưa ra duyệt.

| Mã | Câu hỏi | Mục | Đề xuất tạm |
|---|---|---|---|
| Q04-01 | Đối chiếu Công báo các văn bản ở mục 1.6 | 1.6 | Viện dẫn như mục 1.6, đánh dấu cần xác minh |
| Q04-02 | Có bổ sung sáu quyền đề xuất ở mục 3.3 vào D02-08 không | 3.3 | Bổ sung trong PR gộp tiếp theo |
| Q04-03 | Tạm dừng khẩn qua topic điều khiển có ký (ADR-065) hay chỉ qua Git | 5.5 | Topic điều khiển có ký, đối soát Git trong 5 phút |
| Q04-04 | Một ảnh runtime theo hồ sơ thành phần nạp YAML lúc chạy (ADR-063), hay biên dịch native riêng cho từng luồng | 5.6 | Ảnh theo hồ sơ, nạp YAML lúc chạy |
| Q04-05 | Môi trường STAGING là bắt buộc cho mọi tỉnh hay tùy chọn | 4.5 | Tùy chọn, mặc định `TEST,PROD` |
| Q04-06 | Bỏ trạng thái `TESTING` của repo, chuyển thành điều kiện gửi duyệt | 4.10 | Bỏ |
| Q04-07 | Tỷ lệ phân loại luồng Bus cũ ở giả định thứ tư | 10.2 | Dùng giả định, đo lại khi có gói xuất |

## 12. Danh sách màn hình ở mức chức năng

Bố cục, trường, trạng thái và thông điệp chi tiết ở D03-06-PH04. Cột "Màn hệ cũ" cho biết màn tương ứng của Bus hoặc Tooling được giữ, gộp hay là màn mới.

| UI | Màn hình | Người dùng chính | Hành vi chức năng | FR | Màn hệ cũ |
|---|---|---|---|---|---|
| UI-04-01 | Danh sách luồng | Mọi vai trò có `PERM-04-read` | Lọc, tìm theo tên, endpoint, nguồn, môi trường; đếm theo trạng thái; mở thiết kế, chạy thử, nhật ký, tạo luồng | 001 | Giữ: danh sách agent của Bus và thanh Project của Tooling |
| UI-04-02 | Chi tiết luồng | Mọi vai trò có `PERM-04-read` | Tab Tổng quan, Sơ đồ, Route, Điểm kết nối, Thuộc tính, Mã nguồn, Phiên bản, Triển khai, Chạy thử, Giám sát, Lịch sử; tạm dừng, tiếp tục, gỡ | 002, 004, 006, 033, 043, 050…053, 083 | Giữ và gộp: chi tiết agent, chi tiết route (6 tab) |
| UI-04-03 | Tạo luồng | IE | Chọn loại tài nguyên, điểm xuất phát (trống, khuôn mẫu, API, tệp), nhập thông tin | 003, 025 | Giữ: thêm project, thêm chương trình tích hợp |
| UI-04-04 | Trình thiết kế luồng | IE (sửa), mọi vai trò (xem) | Canvas, bảng thành phần, Inspector, thanh thực thể, YAML hai chiều, bảng Vấn đề, lưu, gửi duyệt | 010…017, 021…024, 026, 027, 040 | Giữ và thiết kế lại: vùng thiết kế, thanh Component, thanh Properties, tab Source của Tooling |
| UI-04-05 | Cấu hình chặng mở rộng | IE | Cửa sổ ba cột Vào, Tham số, Ra; nhóm thuộc tính; chọn kết nối; ghim bản tin mẫu | 014, 016, 022 | Thiết kế lại: thanh Properties |
| UI-04-06 | Trình soạn biểu thức | IE | Soạn, gợi ý, kiểm tra, xem trước biểu thức | 015 | Mới |
| UI-04-07 | Trình ánh xạ dữ liệu | IE | Ba cột nguồn, ánh xạ, đích; hàm; chuyển mã PH-07; xem trước | 020 | Thiết kế lại: data mapping của Tooling |
| UI-04-08 | Trình soạn Kamelet | IE | Định nghĩa tham số, template, kiểu dữ liệu | 018 | Mới (thay nhập JAR) |
| UI-04-09 | Trình soạn Pipe | IE | Nguồn, các bước, đích tuyến tính | 019 | Mới |
| UI-04-10 | Cấu hình cấp tệp, bean | IE | `routeConfiguration`, xử lý lỗi, bean, metadata | 021 | Mới |
| UI-04-11 | Chạy thử | IE | Nhập bản tin, mô phỏng đích, chạy, đọc kết quả theo chặng | 030, 033 | Mới (thay kiểm tra kết nối) |
| UI-04-12 | Nhật ký chạy thử | IE, IA | Lọc, xem lại, so sánh hai lần chạy | 032 | Mới |
| UI-04-13 | Ca kiểm thử | IE | Soạn ca, khẳng định, chạy bộ ca | 031 | Mới |
| UI-04-14 | Hàng đợi duyệt và màn duyệt | IA | So sánh YAML và sơ đồ, bằng chứng, checklist, duyệt, yêu cầu sửa | 041, 043 | Mới |
| UI-04-15 | Phát hành, triển khai, quay lui | IA, TA | Chọn môi trường, theo dõi đồng bộ GitOps, quay lui | 042, 044, 045 | Mới (thay nạp context XML) |
| UI-04-16 | So sánh phiên bản | Mọi vai trò có `PERM-04-read` | So sánh hai phiên bản bất kỳ | 043 | Nâng cấp: tab mã nguồn |
| UI-04-17 | Danh mục thành phần | Mọi vai trò; PA quản lý chính sách | Duyệt, tìm, xem chi tiết thành phần, chính sách được phép | 080, 081 | Mới (thay quản lý dependency) |
| UI-04-18 | Nhập luồng hệ cũ | IE, đội di trú | Tải XML, xem báo cáo chuyển đổi, gán kết nối, tạo luồng nháp | 082 | Mới |
| UI-04-19 | Thư viện khuôn mẫu | IE; PA, TA quản lý | Duyệt, xem trước, dùng khuôn mẫu | 025 | Mới |
| UI-04-20 | Tham số PH-04 | TA | Đặt tham số `04.*`, biến môi trường, đóng băng thay đổi | 084 | Thay thế: cấu hình hệ thống của Bus |
| UI-04-21 | Không gian làm việc | TA | Tạo, sửa không gian làm việc, thành viên | 007 | Thay thế: quản lý project, group |

## 13. Tiêu chí chấp nhận cấp phân hệ

| Mã | Tiêu chí | Kiểm chứng |
|---|---|---|
| AC-04-01 | 100% mục LGC-BUS-001…041 và LGC-TOOL-001…029 có kết luận ở mục 9.1; mọi mục giữ hoặc nâng cấp có ít nhất một test case đạt | Báo cáo độ phủ D00-03; kết quả D05-02-PH04 |
| AC-04-02 | Mọi FR mức M có ít nhất một ca dương và một ca âm đạt; không còn lỗi mức nghiêm trọng, cao | Ma trận D05-02-PH04 §8 |
| AC-04-03 | Không có đường nào đưa định nghĩa vào runtime PROD mà không qua duyệt bốn mắt và kho cấu hình | Kiểm thử bảo mật D05-04; rà soát cấu hình mạng, RBAC K8s |
| AC-04-04 | Chạy thử chạy Camel thật đúng phiên bản runtime; catalog trình thiết kế khớp phiên bản runtime | TS-04-15, TS-04-28; cổng CI |
| AC-04-05 | Quay vòng YAML không mất dữ liệu trên toàn bộ luồng mẫu và 100% luồng di trú của tỉnh thí điểm | TS-04-10 |
| AC-04-06 | Không rò dữ liệu giữa tenant: luồng, nhật ký chạy thử, bản tin runtime của tenant A không đọc được từ tenant B | TS-04-24, kịch bản cách ly D05-01 |
| AC-04-07 | Truy cập CSDL trực tiếp chỉ chạy được câu lệnh đọc bằng tài khoản riêng của luồng, có kiểm toán, có RLS | TS-04-26 |
| AC-04-08 | Đạt NFR-04-001…017 | D05-03 và kiểm thử khả năng truy cập |
| AC-04-09 | Ít nhất 90% luồng Bus cũ của tỉnh thí điểm được chuyển tự động sang YAML với không quá 2 chặng cần xử lý tay mỗi luồng; kết quả chạy song song khớp ≥ 99,9% lượt | Báo cáo di trú D06-01 |
| AC-04-10 | Tạm dừng khẩn có hiệu lực trên mọi bản sao trong 5 giây và được đối soát vào Git | TS-04-21 |
| AC-04-11 | Hợp đồng `openapi-integration.yaml`, `asyncapi-integration.yaml` qua lint, mã nguồn khớp hợp đồng | Cổng CI D04-02 |

## Phụ lục A. Ánh xạ mã yêu cầu của repo gốc sang mã mới

| Mã repo | Nội dung | Mã mới |
|---|---|---|
| FR-04-001…004 (repo) | Tiếp nhận, kiểm tra cấu trúc, đính kèm | FR-04-061, 062, 063 |
| FR-04-005 (repo) | Ủy quyền | FR-04-064 |
| FR-04-006, 007, 010 (repo) | Chuẩn hóa CDM, ánh xạ DMDC quốc gia, chuyển định dạng | FR-04-065 |
| FR-04-008 (repo) | Làm giàu | FR-04-066 |
| FR-04-009 (repo) | Che, giả danh | FR-04-067 |
| FR-04-011…013 (repo) | Định tuyến, tách gộp, song song | FR-04-068 |
| FR-04-014 (repo) | Phát sự kiện | FR-04-069 |
| FR-04-015…019 (repo) | Xử lý lỗi | FR-04-070 |
| FR-04-020…022 (repo) | Nạp, tạm dừng, triển khai theo phiên bản | FR-04-042, 050, 044 |
| FR-04-023…025 (repo) | traceId, vết bất đồng bộ, chỉ số | FR-04-074 |
| FR-04-026, 027 (repo) | Thiết kế trực quan, kiểm tra hợp lệ | FR-04-013, 023 |
| FR-04-028 (repo) | Chạy thử | FR-04-030 |
| FR-04-029 (repo) | Duyệt | FR-04-040, 041 |
| FR-04-030 (repo) | Thư viện mẫu | FR-04-025 |
| FR-04-031…040 (repo) | Biểu thức, credential, pin, báo chặng thiếu, làm nổi chạy thử, biến môi trường, popup, choice, sticky, luồng con | FR-04-015, 016, 022, 023, 033, 084, 014, 013, 026 |
| FR-D-001…004 | Danh sách, thao tác, tạo, lịch sử phiên bản | FR-04-001…006, 043 |
| FR-D-005…008 | Tệp nhiều thực thể, cấu hình cấp tệp | FR-04-013, 021 |
| FR-D-010…013 | Bố cục, bảng thành phần, canvas, trạng thái lưu | FR-04-010, 012, 013, 024 |
| FR-D-020…024 | Cửa sổ cấu hình, nhóm trường, điều khiển theo kiểu, kiểm tra tại chỗ, bản tin mẫu | FR-04-014, 022 |
| FR-D-030…032 | Chạy thử, đối chiếu sơ đồ, so sánh lần chạy | FR-04-030, 032, 033 |
| FR-D-040…042 | Nhật ký chạy | FR-04-032 |
| FR-D-050, 051 | So sánh trước khi duyệt, bốn mắt | FR-04-041 |
| FR-D-060…064 | Loại tài nguyên, Kamelet, Pipe, Test | FR-04-003, 018, 019, 031 |
| FR-D-070…073 | Danh mục thành phần | FR-04-080, 081 |
| FR-D-080…085 | Bean, metadata, DataMapper | FR-04-020, 021 |
| BR-D-01…06 | Ràng buộc của repo | BR-04-002, 003, 007, 006, 004/023, 017 |
| D-01…D-08, UI-04-01…10 (repo) | Màn hình của repo | UI-04-01…21 (D03-06-PH04 §3) |
