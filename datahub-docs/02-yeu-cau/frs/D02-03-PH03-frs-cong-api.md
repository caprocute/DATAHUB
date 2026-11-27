---
ma_tai_lieu: D02-03-PH03
ten: Đặc tả yêu cầu chức năng phân hệ PH-03 Cổng API
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư dh-connect và gateway, cán bộ ATTT, kiểm thử viên
phan_he: PH-03
mo_ta: Đặc tả hành vi của phân hệ cổng API gồm lớp biên, xác thực, hạn mức, định tuyến, đồng bộ cấu hình xuống APISIX và nhật ký lượt gọi, làm căn cứ thiết kế chi tiết, lập trình và kiểm thử.
tai_lieu_lien_quan: D02-02 SRS; D02-04-PH03 Use case; D03-02-PH03 Thiết kế chi tiết; D03-03-PH03 CSDL; D03-04-PH03 API; D03-06-PH03 Màn hình; D05-02-PH03 Test case
---

# D02-03-PH03 · Đặc tả yêu cầu chức năng Cổng API

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-03 là cửa vào duy nhất của mọi lượt gọi API từ ngoài và từ giao diện vào Datahub. Phân hệ bảo đảm ba điều. Thứ nhất, **chỉ lượt gọi hợp lệ mới đi tiếp**: kết thúc TLS, lọc tấn công tầng ứng dụng bằng WAF, xác minh token hoặc chứng thư, kiểm tra đăng ký sử dụng, giới hạn tần suất và hạn ngạch, hỏi OPA rồi mới chuyển tới backend. Thứ hai, **tenant của lượt gọi không giả mạo được**: tenant chỉ lấy từ token đã xác minh, mọi tiêu đề nội bộ do khách tự gửi bị xóa. Thứ ba, **gateway không phụ thuộc lúc chạy vào phần quản trị**: cấu hình được đóng thành ảnh chụp có số phiên bản và chữ ký, mỗi nút APISIX tự nạp và tiếp tục phục vụ khi phần quản trị ngừng.

**Phạm vi.** 59 yêu cầu chức năng chia bảy nhóm: lớp biên và bảo vệ truyền tải, xác thực và kiểm soát truy cập thô, hạn mức và hạn ngạch, định tuyến và chuyển tiếp, đồng bộ cấu hình, quan sát và nhật ký lượt gọi, quản trị. Phân hệ chạy trên hai đơn vị triển khai: `apisix` (mặt phẳng dữ liệu, Apache APISIX 3.x chế độ khai báo, không etcd, kèm WAF Coraza) và `dh-connect` (mặt phẳng điều khiển, Spring Boot: tổng hợp, kiểm tra, ký và phát cấu hình).

**Căn cứ pháp lý.** CMP-LAW-09 (Công văn 631/THH-THHT: quản lý API, xác thực OAuth, giới hạn tần suất, chống tấn công từ chối dịch vụ, hỗ trợ HTTP, HTTPS, WebSocket, sẵn sàng IPv6); CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026 và TCVN 14423:2026 cấp độ 3: TLS, WAF, kiểm soát truy cập, nhật ký); CMP-LAW-16 (Luật An ninh mạng 116/2025: nhật ký, bảo vệ hệ thống); CMP-LAW-05 (Luật BVDLCN 91/2025: không ghi dữ liệu cá nhân vào nhật ký lượt gọi); CMP-LAW-03 (NĐ 278/2025: kết nối, chia sẻ dữ liệu).

**Những điểm hội đồng cần lưu ý.** (1) Hệ cũ chỉ có gói Keyless hoặc API key; Datahub thêm OAuth 2.1 `client_credentials` và mTLS, Keyless chỉ còn cho API dữ liệu mở (FR-03-015). (2) Hạn mức chính tính theo bên gọi (HTTT), không theo địa chỉ IP, vì nhiều sở dùng chung một địa chỉ sau NAT (BR-03-005); thêm hạn mức toàn tenant 500 lượt/giây để một tỉnh không làm chậm tỉnh khác (FR-03-023). (3) Ngoại lệ luật WAF là lỗ hổng có chủ đích nên luôn có lý do, thời hạn không quá 90 ngày và người duyệt khác người đề nghị (FR-03-007). (4) Thu hồi token hoặc tạm ngừng một HTTT có hiệu lực trong 60 giây, không chờ token hết hạn (FR-03-018, 047). (5) Gateway không giữ nội dung bản tin trong nhật ký, chỉ ghi siêu dữ liệu (BR-03-007). (6) Có một điểm khác SRS cũ cần hội đồng cho ý kiến: khi mọi backend không khỏe, hệ mới trả `503` nhanh thay vì giữ lại backend ít lỗi nhất (BR-03-011, Q03-03).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng | 59 (M: 47, S: 11, C: 1) |
| Quy tắc nghiệp vụ | 30 (BR-03-001…030) |
| Yêu cầu phi chức năng | 27 (NFR-03-001…027) |
| Màn hình | 18 (UI-03-01…18) |
| API | 96 operation (API-03-001…096), 12 sự kiện (EVT-03-01…12) |
| Mã lỗi | 27 mã control plane (ERR-03-001…027), 30 mã gateway trả cho bên gọi (ERR-03-101…130) |
| Chức năng hệ cũ được phủ | 9 mục `LGC` có PH-03 là phân hệ đích (LGC-BUS-041, LGC-APIM-005; 011…015, 022, 023) và 4 mục liên quan; 17 FR cũ của repo ánh xạ đủ sang mã mới |
| Mức đợt | MVP 51 FR; Đợt 2 có 7 FR mức S; Đợt 3 có 1 FR mức C |

: Con số chính của PH-03

## 1. Giới thiệu

### 1.1. Mục đích của tài liệu

Tài liệu đặc tả đầy đủ hành vi của phân hệ PH-03 Cổng API ở mức ba nhóm người đọc dùng được ngay không cần hỏi lại. Hội đồng thẩm định dùng tài liệu để đánh giá phân hệ có đáp ứng yêu cầu kiểm soát lượt gọi API của Công văn 631/THH-THHT và yêu cầu an toàn thông tin cấp độ 3 hay không. Kỹ sư dùng tài liệu làm đầu vào cho thiết kế chi tiết D03-02-PH03, CSDL D03-03-PH03 và đặc tả API D03-04-PH03. Kiểm thử viên dùng luồng xử lý, luồng ngoại lệ và quy tắc nghiệp vụ để viết ca kiểm thử ở D05-02-PH03.

Mỗi chức năng được đặc tả theo một khung 17 mục thống nhất: mục đích, tác nhân và quyền, mức ưu tiên, truy vết, tiền điều kiện, kích hoạt, đầu vào, luồng xử lý chính, luồng thay thế, luồng ngoại lệ kèm câu thông báo, đầu ra, kết quả, hậu điều kiện, sự kiện, kiểm toán, quy tắc nghiệp vụ, màn hình và API.

### 1.2. Phạm vi

PH-03 chịu trách nhiệm bảy nhóm việc dưới đây.

| # | Trách nhiệm | Nhóm FR |
|---|---|---|
| 1 | Kết thúc TLS 1.3 (1.2 theo ngoại lệ) ở hai cửa vào `apisix-ext` và `apisix-int`, xác minh chứng thư khách mTLS, chống tràn theo địa chỉ nguồn, WAF Coraza với OWASP CRS, kiểm tra lược đồ, CORS, tiêu đề bảo mật | A |
| 2 | Xác minh JWT cục bộ bằng JWKS đã đệm, xác định tenant, ràng buộc token với chứng thư, kiểm tra đăng ký sử dụng và phạm vi quyền thô, thu hồi token nhanh, gọi OPA, chặn hoặc cho phép theo đường dẫn | B |
| 3 | Hạn mức tần suất, hạn ngạch theo chu kỳ, hạn mức toàn tenant, phản hồi `429`, suy giảm có kiểm soát khi Valkey mất, điều tiết theo tình trạng backend | C |
| 4 | Định tuyến theo host hoặc tiền tố tenant, cân bằng tải, kiểm tra sức khỏe, thời hạn chờ và ngắt mạch, truyền `traceparent`, WebSocket, phiên bản API song song, dừng và mở API, chuyển tiếp tenant sáp nhập, phân cửa vào | D |
| 5 | Control plane `dh-connect`: tổng hợp cấu hình từ danh mục PH-01, PH-02, kiểm tra hợp lệ, ký, phát, quay lui, theo dõi trạng thái đồng bộ, đồng bộ consumer, tạm ngừng khẩn cấp, chứng thư biên | E |
| 6 | Siêu dữ liệu lượt gọi có che dữ liệu, tra cứu nhật ký, chỉ số, vết, kiểm tra tổng hợp, cảnh báo an ninh, bảng điều khiển lưu lượng | F |
| 7 | Tham số theo tenant, chạy thử chính sách, báo cáo sử dụng, nhập cấu hình từ gateway cũ | G |

: Trách nhiệm của PH-03

Những việc dưới đây liên quan nhưng không thuộc PH-03. Tài liệu chỉ mô tả điểm giao tiếp với các phân hệ đó.

| Không làm | Thuộc |
|---|---|
| Soạn, duyệt, công bố API; gói sử dụng; đăng ký sử dụng; vòng đời API ở mức nghiệp vụ | PH-02 (PH-03 nhận kết quả đã duyệt và thực thi) |
| Hồ sơ kết nạp HTTT, cấp định danh ứng dụng, tạm ngừng HTTT | PH-01 (qua saga, PH-03 tạo consumer) |
| Cấp và làm mới token, quản lý người dùng, viết và ký chính sách OPA | PH-12 |
| Chuyển đổi bản tin, ánh xạ dữ liệu, luồng tích hợp | PH-04 (backend của route có thể là luồng PH-04) |
| Kết nối giao thức thô tới HTTT, bộ điều hợp | PH-05 |
| Kết nối Nền tảng chia sẻ quốc gia (NDXP) | PH-14 |
| Lưu trữ lâu dài nhật ký lượt gọi, bảng điều khiển liên phân hệ, cảnh báo tập trung, nhật ký kiểm toán WORM | PH-13 (PH-03 phát siêu dữ liệu và chỉ số) |
| Cổng tự phục vụ của nhà phát triển, tài liệu API, thử API | PH-15 |
| Khởi tạo tenant, hạn mức hợp đồng của tenant | PH-20 (PH-03 thực thi hạn mức) |

: Việc ngoài phạm vi PH-03

### 1.3. Đối tượng sử dụng và cách đọc

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, chương 5, chương 11, chương 14 | Đánh giá sự cần thiết, mức đáp ứng yêu cầu pháp lý, mức phủ nghiệp vụ hệ cũ |
| Cán bộ ATTT, vận hành tenant | Chương 3, mục 6.2, 6.3, 6.8, chương 8, chương 10 | Biết các chốt kiểm soát, cách xử lý cảnh báo giả của WAF, thu hồi và chặn khẩn cấp |
| Chủ dịch vụ, cán bộ đầu mối HTTT | Chương 2, mục 6.4, mục 6.5, mục 9.2 | Biết lượt gọi của mình bị chặn vì sao và cần làm gì |
| Kỹ sư phát triển | Chương 4, chương 6, chương 7, chương 9 | Hiện thực API, plugin, xử lý, quy tắc, mã lỗi |
| Kiểm thử viên | Chương 6, chương 7, chương 8, chương 14 | Viết ca kiểm thử dương, âm, ca hiệu năng, ca rò rỉ chéo tenant, ca chống tấn công |
| Vận hành nền tảng | Mục 6.6, chương 8, chương 12 | Phát cấu hình, quay lui, theo dõi nút, gia hạn chứng thư |

: Người đọc và phần cần đọc

Mã định danh (FR, BR, NFR, ERR, EVT, API, UI) theo quy ước ở D00-01 §3. Chức năng dùng chung của mọi phân hệ (đăng nhập, chọn tenant, phân trang, lọc chuẩn, kiểm toán chung, hộp "Việc của tôi", hiển thị lỗi chung) theo nhóm FR-00 của SRS và không lặp lại ở đây.

### 1.4. Thuật ngữ và chữ viết tắt

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| HTTT | Hệ thống thông tin của cơ quan, đơn vị kết nối vào Datahub |
| Tenant | Một tỉnh dùng Datahub; dữ liệu và cấu hình của tenant tách biệt với tenant khác |
| Gateway, APISIX | Cổng chuyển tiếp lượt gọi API; Apache APISIX 3.x chạy ở chế độ khai báo (standalone), mỗi nút đọc cấu hình từ một tệp |
| Cửa vào | Một trong hai nhóm APISIX: `apisix-ext` (cửa Internet, vùng Z1) và `apisix-int` (cửa mạng truyền số liệu chuyên dùng TSLCD và nội bộ tỉnh, vùng Z2) |
| Route | Quy tắc định tuyến: host, đường dẫn, phương thức tới một upstream, kèm chuỗi plugin |
| Upstream | Nhóm backend nhận lượt gọi của một route, có cân bằng tải và kiểm tra sức khỏe |
| Consumer | Hình chiếu của một client (HTTT) trên gateway: định danh, thông tin xác thực công khai, nhóm ưu tiên, trạng thái |
| Plugin | Mô-đun xử lý trong APISIX, ví dụ `limit-count`, `opa`, `openid-connect` |
| Ảnh chụp cấu hình | Tệp khai báo đầy đủ route, upstream, consumer, plugin config của một tenant hoặc một cửa vào, có số phiên bản tăng dần và chữ ký |
| WAF, Coraza, OWASP CRS | Tường lửa ứng dụng web; Coraza là bộ máy chạy dạng plugin proxy-wasm trong APISIX; CRS là bộ luật cốt lõi của OWASP |
| Mức hoang tưởng (paranoia level) | Mức chặt của bộ luật CRS, từ 1 đến 4; Datahub dùng 2 cho giao diện và 1 cho API máy với máy |
| JWT, JWKS | Token truy cập dạng JSON có chữ ký; tập khóa công khai do Keycloak công bố để kiểm chữ ký |
| mTLS | TLS hai chiều: máy chủ và máy khách cùng xuất trình chứng thư |
| OPA | Open Policy Agent, bộ ra quyết định ủy quyền chạy cạnh APISIX (PH-12 viết chính sách) |
| Valkey | Kho khóa–giá trị trong bộ nhớ, dùng cho bộ đếm hạn mức và danh sách chặn token |
| Hạn mức, hạn ngạch | Hạn mức là số lượt tối đa trong cửa sổ ngắn (giây, phút); hạn ngạch (quota) là số lượt tối đa trong chu kỳ dài (giờ, ngày, tháng) |
| Bốn mắt | Một việc quan trọng cần hai người khác nhau: một người đề nghị, một người duyệt |
| Control plane, data plane | Mặt phẳng điều khiển (`dh-connect`) và mặt phẳng dữ liệu (APISIX, OPA, Valkey) |
| PA, PO, TA, TO, SO, AU | Vai trò: quản trị nền tảng, vận hành nền tảng, quản trị tenant, vận hành tenant, Cán bộ ATTT, kiểm toán viên (mục 3.1) |
| p95, p99 | Phân vị 95 và 99: 95% (99%) số lượt đo có giá trị không vượt ngưỡng nêu |

: Thuật ngữ và chữ viết tắt

### 1.5. Tài liệu tham chiếu

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| CMP-LAW-09 | Công văn 631/THH-THHT về yêu cầu kỹ thuật LGSP | Quản lý API, OAuth, giới hạn tần suất, chống DDoS, HTTP, HTTPS, WebSocket, IPv6 |
| CMP-LAW-06 | Nghị định 331/2026/NĐ-CP về bảo đảm an ninh mạng hệ thống thông tin theo cấp độ | Yêu cầu cấp độ 3 |
| CMP-LAW-08 | TCVN 14423:2026 | TLS, WAF, kiểm soát truy cập, nhật ký, thời hạn lưu |
| CMP-LAW-16 | Luật An ninh mạng 116/2025/QH15 | Bảo vệ hệ thống, nhật ký an ninh |
| CMP-LAW-05 | Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 | Không ghi dữ liệu cá nhân vào nhật ký lượt gọi |
| CMP-LAW-03 | Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu | Nguyên tắc hạn ngạch chỉ để bảo vệ hệ thống và thống kê |
| D02-01 | Tài liệu yêu cầu nghiệp vụ (BRD) | REQ-03, KPI-03, KPI-04 |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | Nhóm FR-00 dùng chung, NFR-00-001, 002, 010, 012, 020, 052, 062 |
| D02-08 | Ma trận phân quyền | `PERM-03-*`, `ROLE-*` |
| D03-01 | Kiến trúc tổng thể (SAD) §4.3 | Đơn vị `apisix`, `dh-connect`, vùng mạng |
| D03-07 | Thiết kế an toàn thông tin | SEC-10, 11, 12, 15, 24, 25, 26, 43, 65, 80, 86 |
| D03-09 | Hạ tầng triển khai và DR | §6.1 cấu hình gateway, §4.4 cửa vào, định cỡ |
| D03-10 | Thiết kế đa tenant | §3 xác định tenant, §5.3 hạn mức, §5.4 sáp nhập |
| ADR-005, ADR-033, ADR-013, ADR-006 | Quyết định về APISIX, lớp biên và WAF, tách control và data plane, Keycloak và OPA | Lý do của các lựa chọn trong tài liệu |
| `docs/07-srs/SRS-PH-03-gateway.md` | SRS PH-03 của repo (17 FR, 28 NFR, 12 BR) | Nguồn kế thừa; bảng ánh xạ ở mục 11.3 |

: Tài liệu tham chiếu

### 1.6. Cấu trúc tài liệu

Chương 2 trình bày bối cảnh, mục tiêu, kiến trúc và các chốt kiểm soát của phân hệ. Chương 3 nêu tác nhân và quyền. Chương 4 định nghĩa khái niệm, thực thể và vòng đời các đối tượng chính. Chương 5 liệt kê toàn bộ 59 chức năng. Chương 6 đặc tả chi tiết từng chức năng theo khung 17 mục. Chương 7 đến chương 9 gom quy tắc nghiệp vụ, yêu cầu phi chức năng, tham số, mã lỗi, thông báo, sự kiện và API. Chương 10 giới thiệu giao diện. Chương 11 đến chương 14 là truy vết, phụ thuộc, câu hỏi mở và tiêu chí chấp nhận.

## 2. Tổng quan phân hệ

### 2.1. Bối cảnh và vấn đề cần giải quyết

Ở hệ LGSP cũ, khối API Management có mô hình tương tự Gravitee: người quản trị tạo API, gói sử dụng (plan) và đăng ký sử dụng; một gateway chạy trên JVM thực thi gói đó. Khi chuyển sang Datahub dùng chung cho nhiều tỉnh, mô hình này gặp bảy vấn đề mà PH-03 phải khắc phục. Bảng dưới nêu từng vấn đề (theo kiểm kê D00-03 §4.4 và ADR-005), hệ quả và cách PH-03 giải quyết.

| Hạn chế hệ cũ | Hệ quả | Cách PH-03 khắc phục |
|---|---|---|
| Gateway kiểu Gravitee chạy JVM, tốn tài nguyên (ADR-005) | Độ trễ thêm lớn, cần nhiều bản sao để chịu tải | APISIX (NGINX và LuaJIT), độ trễ thêm p95 ≤ 50 ms (KPI-04, NFR-03-001) |
| Gói sử dụng chỉ có Keyless hoặc API key (LGC-APIM-011) | Máy với máy không có định danh mạnh; khóa bị chia sẻ, khó truy vết | OAuth 2.1 `client_credentials` và mTLS; Keyless chỉ cho dữ liệu mở (FR-03-015) |
| Hạn mức chỉ theo giây, phút; quota theo giờ, ngày, tháng gắn với Application (LGC-APIM-012; 013) | Một bên gọi hoặc một tỉnh có thể làm chậm bên khác trên nền tảng dùng chung | Giữ các hạn mức cũ, thêm hạn mức toàn tenant và thứ tự ưu tiên chính sách (FR-03-021…024) |
| Nhật ký toàn bộ request, phải che dữ liệu nhạy cảm (LGC-APIM-022) | Nguy cơ lộ dữ liệu cá nhân trong nhật ký | Chỉ ghi siêu dữ liệu, không ghi thân bản tin, che trường nhạy cảm (FR-03-050, BR-03-007) |
| Danh sách gateway, giám sát CPU và Java heap (LGC-APIM-023; 025) | Không còn nghĩa với APISIX; không biết nút nào đang chạy cấu hình nào | Danh sách nút kèm số phiên bản cấu hình đang chạy và trạng thái đồng bộ (FR-03-045) |
| Kiểm kê hệ cũ không có WAF và chống tràn tầng 7 riêng (D00-03 không có chức năng tương ứng) | Công văn 631 yêu cầu chống tấn công từ chối dịch vụ; cấp độ 3 yêu cầu WAF | WAF Coraza với OWASP CRS, `limit-conn`, `limit-req`, chặn địa chỉ (FR-03-003…008) |
| Chính sách (Policies) gắn tay theo từng API (LGC-APIM-015) | Mỗi API một kiểu cấu hình, khó rà soát, dễ sai | Bộ mẫu chính sách được duyệt sẵn, chỉ dùng plugin trong danh mục (FR-03-048, BR-03-017) |

: Hạn chế của hệ cũ và cách khắc phục

### 2.2. Mục tiêu của phân hệ

PH-03 có năm mục tiêu đo được. Mục tiêu thứ nhất là **một điểm vào duy nhất**: 100% lượt gọi từ ngoài và từ giao diện đi qua APISIX, không có đường tắt tới backend (BR-03-001, kiểm tra bằng chính sách mạng và kiểm thử thâm nhập). Mục tiêu thứ hai là **độ trễ thấp**: độ trễ thêm do gateway p95 ≤ 50 ms và p99 ≤ 100 ms ở 300 lượt/giây, đã gồm chi phí WAF (NFR-03-001, kế thừa KPI-04). Mục tiêu thứ ba là **không phụ thuộc phần quản trị khi chạy**: gateway phục vụ liên tục ít nhất 24 giờ khi `dh-connect`, Argo CD hoặc kho Git ngừng (NFR-03-007, kế thừa NFR-00-012). Mục tiêu thứ tư là **thay đổi nhanh và an toàn**: cấu hình mới lan tới mọi nút trong 10 giây (mục tiêu thiết kế, yêu cầu hệ thống 60 giây) mà không lượt gọi nào lỗi; thu hồi token hoặc tạm ngừng HTTT có hiệu lực trong 60 giây (NFR-03-008, 009). Mục tiêu thứ năm là **không lộ dữ liệu và không lẫn tenant**: 0 giá trị nhạy cảm trong nhật ký gateway, 0 lượt gọi đọc được dữ liệu của tenant khác (NFR-03-014, 019, kiểm thử rò rỉ chéo tenant ở D05-02-PH03).

### 2.3. Vị trí trong kiến trúc

```{.mermaid caption="Vị trí của PH-03 trong kiến trúc Datahub"}
flowchart TB
  subgraph EXT["Bên ngoài"]
    NET["Internet<br/>callback PayGov, cổng nhà phát triển"]
    TSL["Mạng TSLCD và nội bộ tỉnh<br/>HTTT, cán bộ, NDXP"]
  end
  subgraph Z1["Vùng Z1 · dh-edge"]
    AXE["apisix-ext<br/>TLS, mTLS, WAF, limit"]
  end
  subgraph Z2["Vùng Z2 · dh-gateway"]
    AXI["apisix-int<br/>TLS, mTLS, WAF, limit"]
    OPA["OPA sidecar"]
    SYNC["Bộ đồng bộ cấu hình<br/>cạnh mỗi pod"]
  end
  subgraph Z3["Vùng Z3 · dh-connect, PH-03 phần control"]
    CP["Tổng hợp, kiểm tra,<br/>ký, phát cấu hình"]
    DB[("pg-core<br/>schema ph03_gateway")]
  end
  VK[("Valkey<br/>bộ đếm, danh sách chặn")]
  KC["Keycloak<br/>JWKS theo realm"]
  BK[("Garage<br/>dh-platform-gateway")]
  GIT[("Git cấu hình<br/>Argo CD, ConfigMap")]
  BE["Backend dịch vụ<br/>HTTT, dh-runtime, PH-14"]
  OBS["PH-13<br/>ClickHouse, LGTM"]
  NET --> AXE
  TSL --> AXI
  AXE --> AXI
  AXI --> OPA
  AXI --> VK
  AXI -.->|"JWKS đệm 10 phút"| KC
  AXI --> BE
  CP --> DB
  CP --> BK
  CP --> GIT
  BK -.->|"theo dõi, kiểm chữ ký"| SYNC
  GIT -.->|"ConfigMap"| SYNC
  SYNC --> AXI
  AXI -.->|"siêu dữ liệu, chỉ số, vết"| OBS
```

Hình cho thấy phân hệ nằm ở hai mặt phẳng. Mặt phẳng dữ liệu là hai nhóm APISIX: `apisix-ext` ở vùng Z1 chỉ phục vụ những gì phải mở ra Internet, `apisix-int` ở vùng Z2 phục vụ mạng TSLCD và nội bộ tỉnh; cả hai dùng chung một cấu hình nhưng chỉ nạp route gắn nhãn cho cửa của mình (ADR-033). OPA chạy cạnh mỗi pod, Valkey giữ bộ đếm dùng chung. Mặt phẳng điều khiển là `dh-connect` ở vùng Z3: nó không nằm trên đường đi của lượt gọi mà chỉ sinh ảnh chụp cấu hình, ký, ghi vào Git và bucket; bộ đồng bộ cạnh pod APISIX kiểm chữ ký rồi ghi tệp khai báo cho APISIX tự nạp lại. Nhờ vậy khi `dh-connect` ngừng, gateway vẫn chạy bằng cấu hình đã nạp (ADR-013).

### 2.4. Kiến trúc thành phần và công nghệ

PH-03 gồm sáu thành phần. **APISIX** (hai nhóm `apisix-ext`, `apisix-int`) thực thi chuỗi plugin cho mọi lượt gọi: `limit-conn`, `limit-req`, `ip-restriction`, WAF Coraza dạng proxy-wasm, `openid-connect` hoặc `jwt-auth` kèm plugin kiểm tra thu hồi, `consumer-restriction`, `limit-count`, `opa`, `request-validation`, `proxy-rewrite`, `api-breaker`, `opentelemetry` và `http-logger` qua bộ che dữ liệu. **OPA sidecar** trong mỗi pod trả quyết định ủy quyền cục bộ với gói chính sách do PH-12 ký (SEC-26). **Valkey** giữ bộ đếm `limit-count` và danh sách chặn `jti`, `sub`. **Bộ đồng bộ cấu hình** là tiến trình nhỏ cạnh APISIX: theo dõi bucket `dh-platform-gateway`, kiểm chữ ký và số phiên bản, ghi tệp `apisix.yaml`. **Dịch vụ quản trị cổng** trong `dh-connect` (Java 21, Spring Boot, package `vn.datahub.connect.gateway`) cung cấp API `/api/gateway/v1`, lưu dữ liệu trong schema `ph03_gateway` của cụm `pg-core` với bảo mật mức dòng theo tenant, tổng hợp, kiểm tra, ký và phát ảnh chụp. **Bộ truy vấn nhật ký** trong `dh-connect` đọc siêu dữ liệu lượt gọi từ kho của PH-13 (ClickHouse, Q331 ở D03-09) để phục vụ màn hình, không giữ bản sao.

Hình dưới là trình tự một lượt gọi API giữa hai HTTT qua gateway. Điểm quan trọng: mọi quyết định (token, hạn mức, ủy quyền) được ra bằng dữ liệu đã nạp sẵn ở APISIX, OPA và Valkey; không bước nào gọi sang `dh-connect`.

```{.mermaid caption="Trình tự một lượt gọi API qua gateway tới backend"}
sequenceDiagram
  autonumber
  participant H as HTTT gọi
  participant AX as APISIX
  participant VK as Valkey
  participant OPA as OPA sidecar
  participant BE as Backend dịch vụ
  participant OB as PH-13
  H->>AX: HTTPS TLS 1.3, Bearer token, traceparent
  AX->>AX: Giới hạn theo IP, WAF, kích thước thân
  AX->>AX: Kiểm chữ ký bằng JWKS đệm, đối chiếu tenant với realm
  AX->>VK: Kiểm danh sách chặn token, tăng bộ đếm hạn mức
  VK-->>AX: Không bị thu hồi, còn hạn mức
  AX->>AX: Kiểm đăng ký sử dụng, phạm vi, xóa X-DH-* của khách, đặt X-DH-Tenant
  AX->>OPA: Hỏi quyết định (vai trò, tenant, phân loại, mục đích)
  OPA-->>AX: allow
  AX->>BE: Chuyển tiếp qua mTLS của mesh, kèm traceparent
  BE-->>AX: Phản hồi
  AX-->>H: Phản hồi kèm X-Trace-Id, X-RateLimit-*
  AX-)OB: Siêu dữ liệu lượt gọi, chỉ số, vết (không có nội dung)
```

Hình dưới là trình tự phát một thay đổi cấu hình từ phần quản trị tới các nút gateway. Điểm quan trọng: `dh-connect` ghi hai nơi (Git và bucket); nút gateway chỉ nhận bản đã ký và có số phiên bản lớn hơn bản đang chạy.

```{.mermaid caption="Trình tự phát cấu hình từ dh-connect tới các nút APISIX"}
sequenceDiagram
  autonumber
  participant P2 as PH-02 hoặc PH-01
  participant CP as dh-connect
  participant ST as Git và bucket
  participant SY as Bộ đồng bộ
  participant AX as Pod APISIX
  P2-)CP: Sự kiện API đã công bố, consumer đổi
  CP->>CP: Tổng hợp, kiểm tra hợp lệ, sinh ảnh chụp, ký
  CP->>ST: Ghi ảnh chụp vA (Git và bucket)
  SY->>ST: Theo dõi bucket, thấy phiên bản mới
  SY->>SY: Kiểm chữ ký, kiểm số phiên bản lớn hơn bản đang chạy
  SY->>AX: Ghi apisix.yaml, APISIX nạp lại nguyên tử
  AX-->>SY: Chỉ số dh_gateway_config_version = vA
  SY-->>CP: Trạng thái nút qua chỉ số PH-13
```

Chuỗi chốt kiểm soát được sắp theo nguyên tắc chi phí tăng dần: bước rẻ đặt trước để loại lưu lượng xấu sớm. Bảng dưới là thứ tự áp dụng trong một lượt gọi và FR hiện thực từng chốt.

| Thứ tự | Chốt | FR | Loại bỏ được gì |
|---|---|---|---|
| 0 | Chống DDoS tầng 3 và 4 (bộ cân bằng tải, dịch vụ của TTDL) | Ngoài PH-03 | Tràn băng thông, SYN flood |
| 1 | TLS, xác minh chứng thư khách | 001, 002 | Kết nối không mã hóa, chứng thư sai |
| 2 | `limit-conn`, `limit-req`, chặn địa chỉ theo IP | 003, 004 | Cạn kiệt kết nối, quét dò, lạm dụng |
| 3 | Giới hạn kích thước thân và số tham số | 009 | Bản tin khổng lồ |
| 4 | WAF Coraza | 005…008 | Chèn mã, XSS, duyệt đường dẫn |
| 5 | Xác minh token, xác định tenant, ràng buộc chứng thư | 012…014 | Token giả, hết hạn, sai tenant |
| 6 | Kiểm tra thu hồi | 018 | Token đã thu hồi |
| 7 | Đăng ký sử dụng, phương thức bảo mật theo gói, phạm vi, đường dẫn | 015…017, 020 | HTTT chưa đăng ký, thiếu phạm vi |
| 8 | Hạn mức consumer, hạn ngạch, hạn mức tenant | 021…026 | Lạm dụng, hàng xóm ồn ào |
| 9 | Kiểm tra lược đồ yêu cầu | 009 | Yêu cầu sai cấu trúc |
| 10 | OPA | 019 | Truy cập ngoài chính sách |
| 11 | Định tuyến, cân bằng tải, ngắt mạch | 028…031 | Backend hỏng |
| 12 | Ghi siêu dữ liệu, chỉ số, vết | 050, 052 | Không loại bỏ, phục vụ truy vết |

: Thứ tự các chốt kiểm soát trong một lượt gọi

Kiểm tra lược đồ yêu cầu (chốt 9) chạy trước OPA (chốt 10) vì plugin kiểm tra lược đồ chạy ở pha `rewrite` còn plugin OPA chạy ở pha `access` của APISIX (D03-02-PH03 §4.1).

Nếu đảo thứ tự, ví dụ đặt xác minh token trước giới hạn theo IP, thì mọi yêu cầu độc hại vẫn phải qua bước mật mã tốn kém trước khi bị chặn.

### 2.5. Quy trình nghiệp vụ liên quan

| Quy trình | Bước có PH-03 |
|---|---|
| Kết nạp HTTT (PH-01) | Saga kết nạp: PH-01 tạo hồ sơ, PH-12 tạo client ở Keycloak, PH-03 tạo consumer ở gateway (FR-03-046); lỗi ở bước sau thì bù trừ bằng cách gỡ consumer |
| Công bố API (PH-02) | API được duyệt và công bố thì PH-03 tổng hợp route, upstream, chính sách từ gói sử dụng, kiểm tra, ký và phát (FR-03-039…043) |
| Đăng ký sử dụng API (PH-02) | Đăng ký được duyệt thì quan hệ consumer – route – gói có hiệu lực ở gateway; hết hiệu lực hoặc bị thu hồi thì lượt gọi bị `403` (FR-03-016) |
| Xử lý cảnh báo giả của WAF | Vận hành thấy lượt hợp lệ bị chặn, đề nghị ngoại lệ có hạn, Cán bộ ATTT duyệt (FR-03-007) |
| Sự cố ATTT | Cán bộ ATTT tạm ngừng khẩn cấp consumer hoặc route, thu hồi token, chặn địa chỉ, đổi WAF sang chế độ chặn (FR-03-004, 006, 018, 047) |
| Gia hạn chứng thư biên | cert-manager gia hạn, gateway nạp lại không gián đoạn; cảnh báo khi còn dưới 30 ngày (FR-03-049) |
| Sáp nhập tỉnh (PH-20) | Tenant nguồn sang `MERGED`, PH-03 chuyển tiếp lượt gọi sang tenant đích kèm tiêu đề `Deprecation` (FR-03-037) |
| Chuyển đổi từ hệ cũ (strangler) | Nhập cấu hình API, plan từ gateway cũ thành cấu hình nháp; chạy song song rồi chuyển dần (FR-03-059) |

: Quy trình nghiệp vụ có PH-03 tham gia

Hình dưới tóm tắt vòng đời điển hình của một API từ lúc được công bố ở PH-02 tới lúc phục vụ lượt gọi thật ở gateway.

```{.mermaid caption="Vòng đời điển hình của một route từ công bố tới phục vụ"}
flowchart TB
  A["PH-02 duyệt<br/>công bố API"] --> B["PH-03 tổng hợp<br/>FR-03-039"]
  B --> C["Kiểm tra hợp lệ<br/>FR-03-040"]
  C -->|"Không đạt"| X["Báo PH-02,<br/>không phát"]
  C -->|"Đạt"| D["Ký, phát<br/>FR-03-041, 042"]
  D --> E["Nút nạp<br/>FR-03-043"]
  E --> F["Phục vụ lượt gọi<br/>chuỗi chốt kiểm soát"]
  F --> G["Quan sát, nhật ký<br/>FR-03-050, 052"]
  F --> H["Dừng, tạm ngừng khẩn cấp<br/>FR-03-036, 047"]
```

### 2.6. Chức năng hệ cũ được phủ

| Mã | Chức năng hệ cũ | Vai trò của PH-03 |
|---|---|---|
| LGC-BUS-041 | Bảo mật route, mã hóa bản tin, bảo mật endpoint (Basic, SSL, WS-Security) | Chính phần đầu vào: TLS, mTLS, OAuth 2.1 tại gateway; cùng PH-04, PH-12 |
| LGC-APIM-005 | Start / Stop API | Thực thi dừng và mở route tức thời; PH-02 giữ vòng đời |
| LGC-APIM-011 | Plan bước Secure: Keyless hoặc API key | Chính: thực thi phương thức bảo mật của gói |
| LGC-APIM-012 | Plan bước Restriction: rate limit (giây, phút) | Chính |
| LGC-APIM-013 | Plan bước Restriction: quota (giờ, ngày, tháng) | Chính |
| LGC-APIM-014 | Plan bước Restriction: whitelist, blacklist đường dẫn | Chính |
| LGC-APIM-015 | Plan bước Policies | Chính: bộ mẫu chính sách được duyệt sẵn |
| LGC-APIM-022 | Log toàn bộ request đến API của Application | Chính phần ghi, che và tra cứu siêu dữ liệu; lưu trữ ở PH-13 |
| LGC-APIM-023 | Danh sách gateway đang kết nối | Chính phần nút và trạng thái đồng bộ; cùng PH-13 |

: Chức năng hệ cũ do PH-03 phủ

## 3. Tác nhân, vai trò và quyền

### 3.1. Tác nhân

| Tác nhân | Loại | Mô tả | Tương tác chính |
|---|---|---|---|
| HTTT gọi API (client máy) | Hệ thống | HTTT của sở, ngành, huyện, đối tác thanh toán; tài khoản `client` ở Keycloak | Gọi API qua gateway bằng token hoặc mTLS; nhận `4xx`, `5xx` theo mã lỗi |
| Người dùng giao diện | Người | Cán bộ dùng `dh-console`, `dh-portal` qua BFF | Mọi lượt gọi dữ liệu của giao diện cũng qua gateway |
| Quản trị nền tảng (PA, ROLE-PLATFORM_ADMIN) | Người | Đơn vị vận hành nền tảng dùng chung | Mẫu chính sách, chứng thư biên, tham số nền tảng, quay lui, hạn mức trần |
| Vận hành nền tảng (PO), Kiểm toán (AU) | Người | Giám sát hạ tầng; thanh tra | Xem nút, trạng thái, nhật ký (chỉ đọc) |
| Quản trị tenant (TA, ROLE-TENANT_ADMIN) | Người | Quản trị Datahub của tỉnh | Hạn mức tenant, duyệt thay đổi, phát cấu hình thủ công |
| Vận hành tenant (TO, ROLE-TENANT_OPERATOR) | Người | Cán bộ trực vận hành | Dừng, mở API, xác nhận cảnh báo, đề nghị ngoại lệ WAF |
| Cán bộ ATTT (SO, ROLE-SECURITY_OFFICER) | Người | Cán bộ chuyên trách ATTT của tỉnh | Duyệt ngoại lệ WAF, đổi chế độ WAF, chặn địa chỉ, tạm ngừng khẩn cấp, duyệt cửa ngoài |
| PH-01 | Hệ thống | Kết nạp HTTT | Gọi API nội bộ tạo, gỡ consumer trong saga; tạm ngừng HTTT |
| PH-02 | Hệ thống | Danh mục dịch vụ | Phát sự kiện API, gói, đăng ký; nhận kết quả kiểm tra cấu hình |
| PH-12 | Hệ thống | Định danh và phân quyền | Keycloak (JWKS, token), gói chính sách OPA ký, đẩy danh sách chặn token |
| PH-13 | Hệ thống | Giám sát và kiểm toán | Nhận siêu dữ liệu lượt gọi, chỉ số, vết; cung cấp truy vấn thống kê |
| PH-20 | Hệ thống | Quản trị tenant | Khởi tạo tenant, hạn mức hợp đồng, sáp nhập |
| Backend dịch vụ | Hệ thống | HTTT, luồng `dh-runtime`, adapter PH-14 | Đích của route |
| Valkey, OpenBao, Garage, Git, Argo CD | Hệ thống | Hạ tầng | Bộ đếm; chứng thư, khóa ký; ảnh chụp cấu hình; lịch sử và triển khai |

: Tác nhân của PH-03

### 3.2. Ma trận quyền

Ma trận dưới dùng ký hiệu của D02-08 §3 (● có quyền, — không có). Quyền `PERM-03-read` và `PERM-03-admin` đã có ở D02-08; tám quyền còn lại được đề nghị bổ sung vào D02-08 §3.1 trong đợt đồng bộ (mục "Đề nghị đồng bộ" cuối tài liệu).

| Quyền | Ý nghĩa | PA | PO | TA | TO | SO | AU |
|---|---|---|---|---|---|---|---|
| PERM-03-read | Xem cấu hình gateway, route, consumer, hạn mức, trạng thái nút, tổng quan lưu lượng | ● | ● | ● | ● | ● | ● |
| PERM-03-admin | Quản lý chính sách gateway: tham số, mẫu chính sách, chứng thư biên, chuyển tiếp tenant, nhập từ hệ cũ, chạy thử | ● | — | ● | — | ● | — |
| PERM-03-limit | Đặt hạn mức toàn tenant, ghi đè hạn mức theo route | ● | — | ● | — | — | — |
| PERM-03-waf-request | Đề nghị ngoại lệ luật WAF; xem sự kiện chặn của WAF | ● | — | ● | ● | ● | — |
| PERM-03-waf-approve | Duyệt, từ chối ngoại lệ luật WAF | — | — | — | — | ● | — |
| PERM-03-waf | Đổi chế độ WAF, luật vá ảo, chặn và bỏ chặn địa chỉ, đổi mức hoang tưởng | ● | — | — | — | ● | — |
| PERM-03-operate | Dừng, mở API; tạm ngừng khẩn cấp route và consumer; quay lui; xác nhận cảnh báo; gia hạn chứng thư | ● | — | ● | ● | ● | — |
| PERM-03-publish | Kiểm tra, xây và phát ảnh chụp cấu hình thủ công | ● | — | ● | — | — | — |
| PERM-03-approve | Duyệt yêu cầu thay đổi gateway có bốn mắt (cửa ngoài, hạ hạn mức tenant, đổi chế độ WAF) | — | — | ● | — | ● | — |
| PERM-03-log-read | Xem nhật ký lượt gọi chi tiết (có định danh HTTT, đã che dữ liệu nhạy cảm), xuất nhật ký | ● | — | ● | ● | ● | ● |

: Ma trận quyền của PH-03

Tài khoản máy gọi API nội bộ của PH-03 dùng scope cấp theo dịch vụ, không cấp cho người: `gateway:sync` cho PH-01 và PH-02 (tạo, gỡ consumer, báo thay đổi gói), `gateway:revoke` cho PH-12 (đẩy danh sách chặn token), `gateway:read-state` cho PH-13 (đọc cấu hình, trạng thái nút).

### 3.3. Tách nhiệm vụ và tài khoản máy

Nguyên tắc bốn mắt (FR-00-071) áp dụng cho bốn nhóm thay đổi có rủi ro cao tại PH-03 (BR-03-019): ngoại lệ luật WAF, chuyển chế độ WAF từ phát hiện sang chặn hoặc ngược lại, route ra cửa Internet, và hạ hạn mức toàn tenant. Người đề nghị không được tự duyệt. Ngoại lệ WAF do TA, TO hoặc SO đề nghị nhưng chỉ SO duyệt; đổi chế độ WAF do SO đề nghị và TA duyệt (hoặc ngược lại) để luôn có hai người khác nhau; route ra cửa ngoài do TA đề nghị, SO duyệt. Thay đổi cấu hình do PH-02 phát hành đã qua duyệt ở PH-02 nên PH-03 không yêu cầu duyệt lần hai mà chỉ kiểm tra hợp lệ kỹ thuật (FR-03-040).

`PERM-03-operate` của TO và SO dùng khi có sự cố vận hành: dừng API, tạm ngừng khẩn cấp, xác nhận cảnh báo. Quyền tạm ngừng khẩn cấp có hiệu lực ngay, không cần người duyệt, nhưng phải kèm lý do, sinh kiểm toán và sự kiện; việc mở lại cũng do người có `PERM-03-operate` thực hiện. Quyền xem nhật ký lượt gọi chi tiết (`PERM-03-log-read`) tách khỏi `PERM-03-read` vì nhật ký có định danh HTTT và địa chỉ nguồn.

## 4. Khái niệm và mô hình nghiệp vụ

### 4.1. Khái niệm nghiệp vụ

**Route** là đơn vị định tuyến của gateway. Một route do PH-02 sinh ra từ một API đã công bố (mỗi API và phiên bản có một hoặc nhiều route), gắn với một upstream, một cửa vào và một tập chính sách. Mã route (`routeCode`) trùng mã API ở PH-02 kèm phiên bản, ví dụ `tra-cuu-cong-dan.v1`, duy nhất trong tenant và không dùng lại.

**Cửa vào** có hai giá trị: `INT` (mặc định, chỉ nạp ở `apisix-int`) và `EXT` (nạp thêm ở `apisix-ext`, chỉ khi được Cán bộ ATTT duyệt, BR-03-015). Callback của nhà cung cấp thanh toán và cổng nhà phát triển là các route `EXT` điển hình.

**Consumer** là hình chiếu trên gateway của một client của HTTT. Một HTTT có thể có nhiều client (BR-03-022); mỗi client là một consumer. Consumer mang mã (`consumerCode` trùng `clientId` ở Keycloak), tenant, nhóm ưu tiên (`ESSENTIAL`, `NORMAL`, `LOW`), vân tay chứng thư khách (nếu dùng mTLS) và trạng thái. Gateway **không lưu bí mật** của client: client dùng `client_secret` hoặc `private_key_jwt` chỉ trao đổi với Keycloak để lấy token.

**Chính sách chiếu từ gói** là phần của gói sử dụng ở PH-02 mà gateway thực thi: phương thức bảo mật (Keyless, API key, OAuth 2.1, mTLS), hạn mức theo giây và phút, hạn ngạch theo giờ, ngày, tháng, danh sách đường dẫn cho phép hoặc chặn, nhóm ưu tiên. PH-02 là nguồn sự thật về gói; PH-03 chỉ giữ bản chiếu để sinh cấu hình.

**Ảnh chụp cấu hình** là tệp khai báo đầy đủ trạng thái mong muốn của gateway cho một tenant (hoặc cho toàn nền tảng ở phần dùng chung), có `version` tăng đơn điệu và chữ ký. Gateway luôn chạy đúng một ảnh chụp; thay đổi là chuyển sang ảnh chụp mới hơn.

**Ngoại lệ luật WAF** là quyết định có thời hạn bỏ qua một mã luật CRS cho một route để tránh chặn nhầm. **Luật vá ảo** là luật WAF bổ sung nhanh khi có lỗ hổng chưa có bản vá.

**Nút gateway** là một pod APISIX; trạng thái đồng bộ của nút là số phiên bản cấu hình đang chạy so với phiên bản mong muốn.

**Hai tầng kiểm soát truy cập.** Gateway kiểm soát thô: token hợp lệ, HTTT đã đăng ký, có phạm vi cần thiết, trong hạn mức. Quyết định chi tiết theo vai trò, tenant, mức phân loại và mục đích khai thác do OPA ra (SEC-26), và tại từng DU qua thư viện PEP. Chia hai tầng vì gateway không có ngữ cảnh nghiệp vụ của bản tin (BR-03-008).

### 4.2. Thực thể

Thực thể ở mức logic; kiểu và ràng buộc chi tiết ở D03-03-PH03. Mọi thực thể đều có `id`, `tenant_id`, `created_at`, `updated_at`, `version` theo D00-01 §5.1 (trừ ghi chú). Schema `ph03_gateway`.

| Mã | Thực thể | Trường chính | Ghi chú |
|---|---|---|---|
| EN-03-01 | Route | `routeCode`, `apiCode`, `apiVersion`, `hostPattern`, `pathPattern`, `methods[]`, `priority`, `exposure` (`INT`, `EXT`), `upstreamCode`, `policySetCode`, `state`, `requiredScopes[]`, `requireMtls`, `bodyMaxBytes` | Sinh từ PH-02; trạng thái ở mục 4.3 |
| EN-03-02 | Upstream | `upstreamCode`, `nodes[]` (địa chỉ, cổng, trọng số), `scheme`, `healthCheck`, `timeouts`, `breaker` | Một upstream có thể dùng chung nhiều route |
| EN-03-03 | Consumer | `consumerCode`, `systemCode` (HTTT ở PH-01), `priorityGroup`, `trustedSource`, `state` | Không có bí mật |
| EN-03-04 | Thông tin xác thực công khai của consumer | `consumerCode`, `authMethod`, `certThumbprint`, `certNotAfter`, `apiKeyHash`, `apiKeyNotAfter` | `apiKeyHash` chỉ cho giai đoạn chuyển đổi (SEC-24) |
| EN-03-05 | Chính sách chiếu từ gói | `policyCode`, `planCode`, `securityMode`, `rateLimits[]`, `quotas[]`, `pathAllow[]`, `pathDeny[]`, `subscriptionState` | Nguồn là PH-02 |
| EN-03-06 | Ghi đè hạn mức | `overrideId`, `scope` (`CONSUMER`, `CONSUMER_ROUTE`, `ROUTE`, `TENANT`), `limit`, `windowSeconds`, `burst` | Thứ tự ưu tiên ở FR-03-024 |
| EN-03-07 | Ngoại lệ luật WAF | `exceptionId`, `routeCode`, `ruleId`, `reason`, `requestedBy`, `approvedBy`, `expiresAt`, `state` | Mục 4.4 |
| EN-03-08 | Luật vá ảo | `patchId`, `ruleText`, `appliesTo`, `reason`, `expiresAt`, `state` | |
| EN-03-09 | Ảnh chụp cấu hình | `snapshotVersion`, `scope`, `contentHash`, `signature`, `builtFrom` (danh sách phiên bản nguồn), `state` | Mục 4.5; nội dung ở Git và bucket, bảng chỉ giữ siêu dữ liệu |
| EN-03-10 | Nút gateway | `nodeId`, `gate` (`EXT`, `INT`), `site`, `runningVersion`, `lastSeenAt`, `syncState` | Cập nhật từ chỉ số, không do nút gọi về; thực thể suy ra từ chỉ số, không có bảng ở CSDL |
| EN-03-11 | Chứng thư biên | `certCode`, `subject`, `hosts[]`, `notAfter`, `issuer`, `state` | Khóa riêng ở OpenBao, không ở bảng |
| EN-03-12 | Lệnh tạm ngừng khẩn cấp | `blockId`, `targetType` (`ROUTE`, `CONSUMER`), `targetCode`, `reason`, `createdBy`, `liftedAt` | |
| EN-03-13 | Chuyển tiếp tenant sáp nhập | `redirectId`, `fromTenant`, `toTenant`, `startAt`, `endAt`, `state` | Mặc định 180 ngày |
| EN-03-14 | Địa chỉ bị chặn | `blockId`, `cidr`, `source` (`AUTO`, `MANUAL`), `expiresAt`, `reason` | |
| EN-03-15 | Yêu cầu thay đổi gateway | `requestId`, `changeType`, `payload`, `requestedBy`, `decidedBy`, `state` | Dùng cho bốn mắt |
| EN-03-16 | Host cửa vào | `hostId`, `hostPattern`, `purpose`, `state` | Gắn một host với đúng một tenant (BR-03-026), không dùng lại host đã gỡ (BR-03-029); bảng `edge_host` |
| EN-03-17 | Bản chiếu đăng ký sử dụng | `consumerCode`, `routeCode`, `planPolicyCode`, `state`, `validFrom`, `validTo` | Nguồn là PH-02; gateway chỉ cho consumer có đăng ký hiệu lực đi qua (FR-03-016); bảng `subscription_ref` |
| EN-03-18 | Thiết lập mẫu chính sách | `templateCode`, `templateVersion`, `enabled`, `params` | Bật, tắt, tham số hóa mẫu được duyệt sẵn theo tenant (FR-03-048); không có đường tải plugin của tenant; bảng `policy_template_setting` |
| EN-03-19 | CA tin cậy cho mTLS | `caCode`, `subject`, `fingerprint`, `notAfter`, `crlUrl` | Chỉ chứa chứng thư công khai của CA (FR-03-002, FR-03-049); bảng `client_ca` |
| EN-03-20 | Ngoại lệ TLS 1.2 | `hostId`, `reason`, `state`, `expiresAt` | Hạn tối đa 180 ngày, PA tạo, không bao giờ dưới TLS 1.2 (FR-03-001, BR-03-003); bảng `tls_exception` |

: Thực thể logic của PH-03

### 4.3. Máy trạng thái route

Route do PH-02 sinh ra nên vòng đời nghiệp vụ của API (soạn, duyệt, công bố, ngừng) ở PH-02. Trạng thái dưới đây là trạng thái **thực thi** của route ở gateway.

```{.mermaid caption="Máy trạng thái thực thi của route"}
stateDiagram-v2
  [*] --> PENDING: PH-02 công bố, đã tổng hợp
  PENDING --> ACTIVE: Ảnh chụp chứa route được nạp
  ACTIVE --> STOPPED: Dừng API (FR-03-036)
  STOPPED --> ACTIVE: Mở API
  ACTIVE --> SUSPENDED: Tạm ngừng khẩn cấp (FR-03-047)
  SUSPENDED --> ACTIVE: Mở lại
  ACTIVE --> SUNSET: Phiên bản hết hạn (FR-03-035)
  STOPPED --> RETIRED: PH-02 ngừng dùng
  SUNSET --> RETIRED: Quá thời hạn giữ
  RETIRED --> [*]
```

`PENDING` là route đã được tổng hợp nhưng chưa có ảnh chụp nào chứa nó; lượt gọi tới route này nhận `404` (ERR-03-114). `ACTIVE` phục vụ bình thường. `STOPPED` do người vận hành chủ động dừng, lượt gọi nhận `503` kèm `Retry-After` (ERR-03-123); mở lại được ngay. `SUSPENDED` do tạm ngừng khẩn cấp vì sự cố an ninh, lượt gọi nhận `403` (ERR-03-127 khi áp cho consumer) hoặc `503` (ERR-03-123 khi áp cho route); chỉ người có `PERM-03-operate` mở lại và phải ghi lý do. `SUNSET` là phiên bản API đã qua ngày kết thúc, lượt gọi nhận `410` (ERR-03-126). `RETIRED` không còn trong ảnh chụp mới.

### 4.4. Máy trạng thái ngoại lệ luật WAF

```{.mermaid caption="Máy trạng thái ngoại lệ luật WAF"}
stateDiagram-v2
  [*] --> REQUESTED: TA, TO, SO đề nghị
  REQUESTED --> ACTIVE: SO khác duyệt (FR-03-007)
  REQUESTED --> REJECTED: SO từ chối, có lý do
  ACTIVE --> EXPIRING: Còn 7 ngày
  EXPIRING --> EXPIRED: Hết hạn
  ACTIVE --> EXPIRED: Hết hạn
  ACTIVE --> REVOKED: SO thu hồi
  EXPIRING --> REVOKED: SO thu hồi
  REJECTED --> [*]
  EXPIRED --> [*]
  REVOKED --> [*]
```

`REQUESTED` chờ duyệt, chưa có hiệu lực ở gateway. `ACTIVE` được đưa vào ảnh chụp cấu hình và bỏ qua mã luật cho đúng route. `EXPIRING` vẫn hiệu lực nhưng hiển thị cảnh báo và phát sự kiện để rà soát; không có gia hạn tự động, muốn kéo dài phải đề nghị lại. `EXPIRED` và `REVOKED` bị gỡ khỏi ảnh chụp kế tiếp.

### 4.5. Máy trạng thái ảnh chụp cấu hình

```{.mermaid caption="Máy trạng thái ảnh chụp cấu hình"}
stateDiagram-v2
  [*] --> BUILT: Tổng hợp xong (FR-03-039)
  BUILT --> REJECTED: Kiểm tra hợp lệ không đạt (FR-03-040)
  BUILT --> SIGNED: Đạt, đã ký (FR-03-041)
  SIGNED --> PUBLISHED: Ghi Git và bucket (FR-03-042)
  PUBLISHED --> APPLIED: Mọi nút đang chạy bản này
  PUBLISHED --> PARTIAL: Một số nút chưa nạp quá 60 giây
  PARTIAL --> APPLIED: Nút còn lại nạp xong
  APPLIED --> SUPERSEDED: Có bản mới hơn được nạp
  PARTIAL --> SUPERSEDED: Có bản mới hơn
  REJECTED --> [*]
  SUPERSEDED --> [*]
```

`REJECTED` không được phát và báo lại PH-02, người dùng sửa rồi tổng hợp lại. `PUBLISHED` nghĩa là đã ghi vào Git và bucket nhưng chưa biết nút nào đã nạp; trạng thái `APPLIED` và `PARTIAL` suy ra từ chỉ số `dh_gateway_config_version` của từng nút (FR-03-045). Quay lui (FR-03-044) không đưa phiên bản cũ trở lại mà **sinh ảnh chụp mới có nội dung của phiên bản cũ** (BR-03-018), nên số phiên bản luôn tăng.

## 5. Danh sách chức năng

PH-03 có 59 chức năng chia bảy nhóm. Bảng dưới liệt kê toàn bộ chức năng kèm nhóm, mức ưu tiên, đợt phát hành và màn hình hiện thực; đặc tả chi tiết ở chương 6. Nhóm: A Lớp biên và bảo vệ truyền tải; B Xác thực và kiểm soát truy cập thô; C Hạn mức và hạn ngạch; D Định tuyến và chuyển tiếp; E Đồng bộ cấu hình; F Quan sát và nhật ký lượt gọi; G Quản trị.

| Mã | Nhóm | Chức năng | Mức | Đợt | Màn hình |
|---|---|---|---|---|---|
| FR-03-001 | A | Kết thúc TLS tại hai cửa vào | M | MVP | UI-03-12 |
| FR-03-002 | A | Xác minh chứng thư khách mTLS | M | MVP | UI-03-12 |
| FR-03-003 | A | Giới hạn kết nối và tốc độ theo địa chỉ nguồn | M | MVP | UI-03-15, UI-03-16 |
| FR-03-004 | A | Chặn tạm địa chỉ nguồn vi phạm liên tục | S | MVP | UI-03-15 |
| FR-03-005 | A | WAF Coraza với bộ luật OWASP CRS | M | MVP | UI-03-07 |
| FR-03-006 | A | Chế độ phát hiện, chặn của WAF và tự hạ khi quá tải | M | MVP | UI-03-07, UI-03-17 |
| FR-03-007 | A | Ngoại lệ luật WAF có thời hạn | M | MVP | UI-03-07, UI-03-08, UI-03-17 |
| FR-03-008 | A | Luật vá ảo khẩn cấp | S | Đợt 2 | UI-03-08 |
| FR-03-009 | A | Kiểm tra lược đồ và giới hạn kích thước yêu cầu | M | MVP | UI-03-03 |
| FR-03-010 | A | Xử lý CORS | S | Đợt 2 | UI-03-03 |
| FR-03-011 | A | Tiêu đề bảo mật và che thông tin máy chủ | M | MVP | UI-03-16 |
| FR-03-012 | B | Xác minh chữ ký JWT cục bộ | M | MVP | UI-03-11 |
| FR-03-013 | B | Xác định tenant của lượt gọi | M | MVP | — |
| FR-03-014 | B | Ràng buộc token với chứng thư khách | M | MVP | UI-03-05 |
| FR-03-015 | B | Áp phương thức bảo mật theo gói sử dụng | M | MVP | UI-03-03, UI-03-13 |
| FR-03-016 | B | Kiểm tra đăng ký sử dụng và hiệu lực gói | M | MVP | UI-03-05 |
| FR-03-017 | B | Kiểm tra phạm vi quyền thô | M | MVP | UI-03-03 |
| FR-03-018 | B | Thu hồi token nhanh bằng danh sách chặn | M | MVP | UI-03-05 |
| FR-03-019 | B | Ủy quyền chi tiết bằng OPA tại gateway | M | MVP | UI-03-03 |
| FR-03-020 | B | Danh sách cho phép và chặn đường dẫn | M | MVP | UI-03-03, UI-03-13 |
| FR-03-021 | C | Giới hạn tần suất theo bên gọi | M | MVP | UI-03-06 |
| FR-03-022 | C | Hạn ngạch theo chu kỳ và cảnh báo ngưỡng | M | MVP | UI-03-05, UI-03-06 |
| FR-03-023 | C | Hạn mức toàn tenant | M | MVP | UI-03-06, UI-03-17 |
| FR-03-024 | C | Hạn mức theo route và thứ tự ưu tiên chính sách | S | Đợt 2 | UI-03-06 |
| FR-03-025 | C | Phản hồi vượt hạn mức và tiêu đề hạn mức | M | MVP | — |
| FR-03-026 | C | Suy giảm có kiểm soát khi Valkey mất | M | MVP | UI-03-01 |
| FR-03-027 | C | Điều tiết theo tình trạng backend | S | Đợt 2 | UI-03-06 |
| FR-03-028 | D | Định tuyến theo host, đường dẫn, phương thức | M | MVP | UI-03-02, UI-03-03 |
| FR-03-029 | D | Cân bằng tải giữa các backend | M | MVP | UI-03-03 |
| FR-03-030 | D | Kiểm tra sức khỏe backend chủ động và thụ động | M | MVP | UI-03-03 |
| FR-03-031 | D | Thời hạn chờ, ngắt mạch và trả lỗi nhanh | M | MVP | UI-03-03 |
| FR-03-032 | D | Sinh và truyền định danh truy vết | M | MVP | — |
| FR-03-033 | D | Chuyển tiếp WebSocket và nén nội dung | M | MVP | UI-03-03 |
| FR-03-034 | D | Chuyển đổi gRPC và REST | C | Đợt 3 | UI-03-03 |
| FR-03-035 | D | Phiên bản API song song và tiêu đề ngừng dùng | S | MVP | UI-03-02, UI-03-03 |
| FR-03-036 | D | Dừng và mở API tức thời | M | MVP | UI-03-02, UI-03-03 |
| FR-03-037 | D | Chuyển tiếp lượt gọi của tenant đã sáp nhập | S | Đợt 2 | UI-03-16 |
| FR-03-038 | D | Phân cửa vào Internet và mạng nội bộ | M | MVP | UI-03-03, UI-03-17 |
| FR-03-039 | E | Tổng hợp cấu hình gateway từ danh mục | M | MVP | UI-03-10 |
| FR-03-040 | E | Kiểm tra hợp lệ cấu hình trước khi phát | M | MVP | UI-03-10 |
| FR-03-041 | E | Sinh ảnh chụp cấu hình có phiên bản và chữ ký | M | MVP | UI-03-10 |
| FR-03-042 | E | Phát ảnh chụp tới Git và bucket | M | MVP | UI-03-10 |
| FR-03-043 | E | Nạp ảnh chụp ở nút gateway | M | MVP | UI-03-11 |
| FR-03-044 | E | Quay lui về phiên bản cấu hình trước | M | MVP | UI-03-10 |
| FR-03-045 | E | Theo dõi nút và trạng thái đồng bộ | M | MVP | UI-03-11 |
| FR-03-046 | E | Đồng bộ consumer và thông tin xác thực công khai | M | MVP | UI-03-04, UI-03-05 |
| FR-03-047 | E | Tạm ngừng khẩn cấp route hoặc consumer | M | MVP | UI-03-02, UI-03-05 |
| FR-03-048 | E | Bộ mẫu chính sách gateway được duyệt sẵn | M | MVP | UI-03-13 |
| FR-03-049 | E | Quản lý chứng thư biên | M | MVP | UI-03-12 |
| FR-03-050 | F | Ghi siêu dữ liệu lượt gọi có che dữ liệu | M | MVP | — |
| FR-03-051 | F | Tra cứu và xuất nhật ký lượt gọi | M | MVP | UI-03-05, UI-03-09 |
| FR-03-052 | F | Phát chỉ số và vết OpenTelemetry | M | MVP | UI-03-01 |
| FR-03-053 | F | Kiểm tra tổng hợp cho API quan trọng | S | MVP | UI-03-01 |
| FR-03-054 | F | Cảnh báo sự kiện an ninh tại gateway | M | MVP | UI-03-01, UI-03-07 |
| FR-03-055 | F | Bảng điều khiển lưu lượng gateway | M | MVP | UI-03-01 |
| FR-03-056 | G | Tham số gateway theo tenant | M | MVP | UI-03-16 |
| FR-03-057 | G | Chạy thử chính sách bằng mô phỏng | S | Đợt 2 | UI-03-14 |
| FR-03-058 | G | Báo cáo sử dụng API theo HTTT và gói | S | Đợt 2 | UI-03-01 |
| FR-03-059 | G | Nhập cấu hình từ gateway cũ | S | MVP | UI-03-18 |

: Danh sách chức năng của PH-03

## 6. Đặc tả chi tiết chức năng

### 6.1. Cách đọc bảng đặc tả

Mỗi chức năng được đặc tả bằng một bảng hai cột gồm 17 mục cố định. Chuẩn này kết hợp hai nguồn: 12 trường kỹ thuật của mẫu FR ở D00-01 §4.3 (đầu vào, đầu ra, mã lỗi, sự kiện, kiểm toán) để kỹ sư và kiểm thử viên dùng ngay, và các mục của mẫu thuyết minh đặc tả chức năng (mục đích, kích hoạt, luồng theo tác nhân, thông báo, kết quả, màn hình) để hội đồng và người dùng nghiệp vụ đọc được. Mục không áp dụng ghi "Không" để người đọc biết đã được xét, không bị bỏ sót.

| Mục | Nội dung | Nguồn |
|---|---|---|
| Mục đích | Chức năng giúp ai làm được việc gì, vì sao cần | Mẫu thuyết minh |
| Tác nhân, quyền | Vai trò hoặc hệ thống thực hiện và `PERM` cần có | D00-01 §4.3 |
| Mức ưu tiên, đợt | M (bắt buộc), S (nên có), C (có thì tốt); đợt phát hành | D00-01 §4.3, mẫu |
| Truy vết | REQ, LGC, SEC, ADR, Q | D00-01 §4.3 |
| Tiền điều kiện | Trạng thái phải đúng trước khi chức năng chạy | D00-01 §4.3 |
| Kích hoạt | Thao tác hoặc sự kiện khởi động chức năng | Mẫu thuyết minh |
| Đầu vào | Tham số, trường nhập: tên, kiểu chuẩn, bắt buộc, ràng buộc (bảng riêng khi từ 5 trường) | D00-01 §4.3 |
| Luồng xử lý chính | Các bước đánh số, chủ ngữ là tác nhân hoặc hệ thống; bước kiểm tra ghi mã lỗi khi không đạt | Cả hai |
| Luồng thay thế | Nhánh hợp lệ khác của luồng chính | Mẫu thuyết minh |
| Luồng ngoại lệ | Điều kiện, mã lỗi `ERR`, mã HTTP, hành vi, câu thông báo người nhìn thấy | Cả hai |
| Đầu ra | Mã HTTP, các trường trả về, tiêu đề | D00-01 §4.3 |
| Kết quả | Điều người dùng nhận được khi thành công | Mẫu thuyết minh |
| Hậu điều kiện | Trạng thái dữ liệu sau khi kết thúc | D00-01 §4.3 |
| Sự kiện phát ra | `EVT` nếu có | D00-01 §4.3 |
| Kiểm toán | Có ghi kiểm toán không, các trường được ghi | D00-01 §4.3 |
| Quy tắc nghiệp vụ | Mã `BR` áp dụng (chương 7) | Cả hai |
| Màn hình, API | `UI` và `API` hiện thực chức năng | Mẫu thuyết minh |

: Các mục của bảng đặc tả chức năng

Hai điểm riêng của phân hệ này cần nói trước. Thứ nhất, nhóm A, B, C, D và một phần F là **chức năng của mặt phẳng dữ liệu**: tác nhân là HTTT gọi API hoặc người dùng giao diện, không có màn hình tương tác trực tiếp, nên "câu thông báo" là nội dung `title` và `detail` của thân lỗi RFC 9457 mà gateway trả cho bên gọi (mã `ERR-03-101…130`); người vận hành xem lại các lượt lỗi này ở nhật ký lượt gọi (FR-03-051). Thứ hai, chức năng của mặt phẳng dữ liệu cấu hình được qua mặt phẳng điều khiển (nhóm E), nên các mục "Tiền điều kiện" thường nói "đã có trong ảnh chụp cấu hình đang chạy".

Ví dụ trong chương này dùng tenant `T68`, HTTT `HT-TUPHAP` (Sở Tư pháp) và `HT-QLVB` (quản lý văn bản), API `tra-cuu-ho-tich` phiên bản `v1` (route `tra-cuu-ho-tich.v1`). Đây là dữ liệu giả lập. Mọi API ở mặt phẳng điều khiển dùng tiền tố `/api/gateway/v1`. Thân lỗi RFC 9457 có dạng:

```json
{
  "type": "https://datahub.gov.vn/errors/gateway/rate-limit-exceeded",
  "title": "Vượt hạn mức truy cập",
  "status": 429,
  "detail": "HTTT HT-QLVB đã dùng hết 600 lượt trong 60 giây cho API tra-cuu-ho-tich.v1. Thử lại sau 12 giây.",
  "code": "ERR-03-116",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "retryAfterSeconds": 12
}
```

### 6.2. Nhóm A · Lớp biên và bảo vệ truyền tải

Nhóm A là tuyến phòng thủ đầu tiên, chạy trước mọi kiểm tra danh tính: kết thúc TLS, xác minh chứng thư khách, chống tràn theo địa chỉ nguồn, WAF, kiểm tra cấu trúc yêu cầu và làm sạch tiêu đề phản hồi. Hình dưới tóm tắt thứ tự và quan hệ giữa các chức năng trong nhóm.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm A"}
flowchart TB
  F001["FR-03-001 Kết thúc TLS"] --> F002["FR-03-002 Chứng thư khách mTLS"]
  F002 --> F003["FR-03-003 Giới hạn theo IP"]
  F003 --> F004["FR-03-004 Chặn tạm IP"]
  F003 --> F009["FR-03-009 Kích thước,<br/>lược đồ"]
  F009 --> F005["FR-03-005 WAF Coraza"]
  F005 --> F006["FR-03-006 Chế độ WAF"]
  F005 --> F007["FR-03-007 Ngoại lệ WAF"]
  F005 --> F008["FR-03-008 Luật vá ảo"]
  F010["FR-03-010 CORS"] -.-> F011["FR-03-011 Tiêu đề bảo mật"]
  F049["FR-03-049 Chứng thư biên"] -.-> F001
```

#### FR-03-001 · Kết thúc TLS tại hai cửa vào

::: dac-ta
**Mục đích.** Bảo đảm mọi kết nối từ ngoài vào Datahub được mã hóa bằng giao thức hiện hành, đúng chuẩn cấp độ 3, và cho phép HTTT cũ chưa hỗ trợ TLS 1.3 tiếp tục kết nối trong thời gian chuyển đổi mà không hạ chuẩn của toàn hệ thống.

**Tác nhân, quyền.** HTTT gọi API và người dùng giao diện (bên khởi tạo kết nối); PA, TA cấu hình hồ sơ TLS và ngoại lệ (`PERM-03-admin`); mọi vai trò có `PERM-03-read` xem hồ sơ.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-BUS-041; CMP-LAW-09, CMP-LAW-08; SEC-12; NFR-00-020; ADR-033.

**Tiền điều kiện.** Chứng thư biên của host đã được cấp và nạp (FR-03-049); ảnh chụp cấu hình đang chạy có phần `ssl` cho host đó.

**Kích hoạt.** Bên gọi mở kết nối TCP cổng 443 tới địa chỉ ảo của `apisix-ext` hoặc `apisix-int`.

**Đầu vào.** Gói ClientHello: phiên bản giao thức, bộ mã, nhóm khóa, SNI (tên host); hồ sơ TLS theo bảng "Hồ sơ TLS mặc định" dưới đây.

**Luồng xử lý chính.**

1. Bên gọi bắt tay TLS tới địa chỉ ảo của cửa vào, gửi SNI là host của tenant (ví dụ `api.t68.datahub.gov.vn`).
2. APISIX chọn chứng thư theo SNI; SNI không khớp host nào đã khai báo thì từ chối với ERR-03-128.
3. APISIX thương lượng TLS 1.3 với bộ mã `TLS_AES_256_GCM_SHA384`, `TLS_AES_128_GCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256` và nhóm khóa X25519, secp256r1.
4. Nếu bên gọi chỉ hỗ trợ TLS 1.2 và host thuộc một ngoại lệ TLS còn hạn (xem luồng thay thế) thì thương lượng TLS 1.2 với các bộ mã `ECDHE-ECDSA/RSA-AES128/256-GCM-SHA256/384`, `ECDHE-*-CHACHA20-POLY1305`; ngược lại, bắt tay thất bại (giao thức dưới mức cho phép).
5. APISIX bật OCSP stapling, tắt nén TLS, tắt renegotiation, xoay khóa phiên vé (session ticket) 24 giờ một lần.
6. APISIX giải mã yêu cầu và chuyển tiếp nội bộ qua mTLS của mesh (SEC-15); ghi chỉ số `dh_gateway_tls_handshake_total{version,result}`.

**Luồng thay thế.** Ngoại lệ TLS 1.2 cho HTTT cũ: quản trị tạo ngoại lệ gắn với một **host chuyên dụng** (ví dụ `tls12.t68.datahub.gov.vn`), có thời hạn tối đa 180 ngày, kèm lý do và HTTT hưởng ngoại lệ (API-03-033); các route của HTTT đó được gắn thêm host này. Lý do dùng host riêng: giao thức TLS được chọn trước khi biết bên gọi là ai, nên chỉ cấu hình được theo tên host.

**Luồng ngoại lệ.**

- Bên gọi chỉ hỗ trợ TLS dưới 1.2 hoặc bộ mã yếu: kết nối bị đóng ở bước bắt tay, bên gọi nhận cảnh báo TLS `protocol_version` hoặc `handshake_failure`; không có phản hồi HTTP. Chỉ số `dh_gateway_tls_handshake_total{result="rejected"}` tăng; UI-03-12 hiển thị số lần bắt tay bị từ chối theo lý do để quản trị liên hệ chủ HTTT.
- SNI không khớp host nào: trả ERR-03-128 (421), "Địa chỉ truy cập không thuộc dịch vụ nào của nền tảng."
- Ngoại lệ TLS quá 180 ngày hoặc thiếu lý do: ERR-03-003 (400), "Thời hạn ngoại lệ không được quá 180 ngày và phải có lý do."

**Đầu ra.** Kết nối TLS được thiết lập; yêu cầu HTTP đã giải mã chuyển cho chuỗi plugin. Chỉ số `dh_gateway_tls_handshake_total`.

**Kết quả.** HTTT kết nối được qua TLS 1.3; HTTT cũ có đường kết nối tạm thời có hạn, hiển thị rõ ở UI-03-12 để theo dõi thanh lý.

**Hậu điều kiện.** Không thay đổi dữ liệu nghiệp vụ. Khi tạo hoặc thu hồi ngoại lệ, ảnh chụp cấu hình kế tiếp có hoặc không còn host chuyên dụng.

**Sự kiện phát ra.** Không (thay đổi cấu hình đi theo EVT-03-01 của ảnh chụp).

**Kiểm toán.** Có khi tạo, thu hồi ngoại lệ TLS và khi đổi hồ sơ TLS: người thực hiện, host, HTTT, lý do, hạn, giá trị trước và sau.

**Quy tắc nghiệp vụ.** BR-03-003; BR-03-001.

**Màn hình, API.** UI-03-12; API-03-031, API-03-032, API-03-033, API-03-034.
:::

| Thông số | Giá trị mặc định | Ghi chú |
|---|---|---|
| Phiên bản giao thức | TLS 1.3; TLS 1.2 chỉ trên host có ngoại lệ | SEC-12, NFR-00-020 |
| Bộ mã TLS 1.3 | `TLS_AES_256_GCM_SHA384`, `TLS_AES_128_GCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256` | |
| Bộ mã TLS 1.2 (chỉ ngoại lệ) | `ECDHE-ECDSA/RSA-AES128/256-GCM-SHA256/384`, `ECDHE-*-CHACHA20-POLY1305` | Không CBC, không RSA tĩnh |
| Nhóm khóa | X25519, secp256r1 | |
| Chứng thư | RSA 3072 hoặc ECDSA P-256 | SEC-12; cấp bởi cert-manager (FR-03-049) |
| OCSP stapling | Bật | |
| Nén TLS, renegotiation | Tắt | |
| HSTS | `max-age=31536000; includeSubDomains` | Đặt ở FR-03-011 |
| Hạn ngoại lệ TLS 1.2 | ≤ 180 ngày, mỗi ngoại lệ một host chuyên dụng | Giả định: bằng thời hạn ngoại lệ phiên bản TLS của PH-05 (BR-05-011) |

: Hồ sơ TLS mặc định ở hai cửa vào

#### FR-03-002 · Xác minh chứng thư khách mTLS

::: dac-ta
**Mục đích.** Cho HTTT nhóm mức Hạn chế và Nhạy cảm xác thực bằng chứng thư thay vì bí mật chia sẻ (SEC-24), và làm nền cho việc ràng buộc token với chứng thư ở FR-03-014. Gateway xác minh chuỗi tin cậy và tình trạng thu hồi của chứng thư ngay ở lớp biên, trước mọi xử lý nặng.

**Tác nhân, quyền.** HTTT gọi API có chứng thư khách; PA, TA cấu hình bộ CA tin cậy (`PERM-03-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-BUS-041, LGC-APIM-011; SEC-24, SEC-35; ADR-033.

**Tiền điều kiện.** Bộ CA khách đã nạp ở cấu hình `ssl.client.ca` của host; route đặt `requireMtls = true` hoặc consumer dùng phương thức `MTLS`; CRL hoặc OCSP của CA có thể đọc được.

**Kích hoạt.** Bên gọi xuất trình chứng thư trong bắt tay TLS tới host yêu cầu mTLS.

**Đầu vào.** Chuỗi chứng thư khách; bộ CA tin cậy: CA HTTT của Datahub (OpenBao PKI, cấp qua PH-01) hoặc CA được tỉnh chấp nhận; danh sách thu hồi (CRL, làm mới mỗi giờ).

**Luồng xử lý chính.**

1. APISIX yêu cầu chứng thư khách ở host có cấu hình mTLS và xác minh chuỗi tới bộ CA tin cậy (chuỗi sai: ERR-03-108).
2. APISIX kiểm tra thời hạn hiệu lực và mục đích sử dụng khóa (`clientAuth`) của chứng thư (hết hạn hoặc sai mục đích: ERR-03-108).
3. APISIX kiểm tra chứng thư không có trong CRL đã đệm (bị thu hồi: ERR-03-108).
4. APISIX tính vân tay SHA-256 của chứng thư, đặt vào ngữ cảnh yêu cầu `ctx.client_cert_sha256` và ghi chỉ số `dh_gateway_mtls_total{result}`.
5. Plugin định danh đối chiếu vân tay với bảng `certThumbprint` của các consumer trong tenant; có khớp thì gắn `consumer` vào ngữ cảnh; không khớp mà route yêu cầu mTLS làm phương thức duy nhất thì từ chối (ERR-03-108).
6. Yêu cầu đi tiếp tới chốt thứ hai (FR-03-003).

**Luồng thay thế.** Route chấp nhận OAuth 2.1 làm phương thức chính và mTLS chỉ để ràng buộc token (FR-03-014): chứng thư không khớp consumer vẫn đi tiếp tới bước xác minh token, nơi vân tay được đối chiếu với `cnf`.

**Luồng ngoại lệ.**

- Không xuất trình chứng thư ở route yêu cầu mTLS, hoặc chuỗi, hạn, thu hồi không đạt: ERR-03-108 (403), "Chứng thư của HTTT không hợp lệ hoặc không được phép. Kiểm tra chứng thư và liên hệ quản trị Datahub."
- Không đọc được CRL quá 24 giờ: từ chối mọi chứng thư của CA đó (đóng an toàn), ERR-03-108, cảnh báo Nghiêm trọng cho PA ở FR-03-054.
- Chứng thư của consumer sắp hết hạn trong 30 ngày: lượt gọi vẫn qua, thêm tiêu đề `X-DH-Cert-Expires-In-Days`, và FR-03-049 báo chủ HTTT.

**Đầu ra.** Ngữ cảnh yêu cầu có `client_cert_sha256` và `consumer` (nếu khớp); hoặc `403` theo ERR-03-108.

**Kết quả.** HTTT có chứng thư hợp lệ được nhận diện ngay ở biên; chứng thư sai bị chặn trước khi tốn tài nguyên.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có trong nhật ký an ninh khi từ chối: thời điểm, địa chỉ nguồn, vân tay, lý do, host, `traceId` (không ghi chuỗi chứng thư đầy đủ).

**Quy tắc nghiệp vụ.** BR-03-001; BR-03-003; BR-03-004.

**Màn hình, API.** UI-03-12; API-03-035, API-03-016.
:::

#### FR-03-003 · Giới hạn kết nối và tốc độ theo địa chỉ nguồn

::: dac-ta
**Mục đích.** Chặn sớm lưu lượng bất thường từ một địa chỉ nguồn (quét dò, kết nối chậm, tràn yêu cầu) bằng các chốt rẻ nhất, trước cả xác minh token. Đây là lớp bảo vệ ngoài cùng; hạn mức chính vẫn tính theo HTTT (BR-03-005).

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA đổi tham số (`PERM-03-admin`); SO đề xuất danh sách tin cậy.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; CMP-LAW-09; SEC-10; ADR-033; NFR-00-002.

**Tiền điều kiện.** Tham số `gw.ip.*` có trong ảnh chụp; bộ cân bằng tải truyền địa chỉ nguồn thật qua giao thức PROXY, APISIX tin tiêu đề chuyển tiếp chỉ từ dải của bộ cân bằng tải.

**Kích hoạt.** Mỗi kết nối mới và mỗi yêu cầu tới cửa vào.

**Đầu vào.** Địa chỉ nguồn thật; loại đường dẫn (giao diện hay API máy); tham số theo bảng "Tham số giới hạn theo địa chỉ nguồn" dưới đây.

**Luồng xử lý chính.**

1. APISIX xác định địa chỉ nguồn thật từ giao thức PROXY (không tin tiêu đề `X-Forwarded-For` do khách tự gửi).
2. Nếu địa chỉ thuộc danh sách tin cậy (NDXP, nội bộ tỉnh, bộ giám sát tổng hợp) thì miễn các giới hạn ở bước 3 và 4; hạn mức theo HTTT vẫn áp dụng (FR-03-021).
3. Plugin `limit-conn` đếm kết nối đồng thời của địa chỉ, vượt ngưỡng thì từ chối kết nối mới (ERR-03-119).
4. Plugin `limit-req` đếm tốc độ yêu cầu: đường dẫn giao diện 50 yêu cầu/giây/IP, đường dẫn API máy 200 yêu cầu/giây/IP (giả định, xem bảng), kèm dung sai đột biến; vượt thì trả ERR-03-119.
5. Plugin đặt thời hạn đọc tiêu đề 10 giây, đọc thân 30 giây để chống tấn công kết nối chậm; hết hạn thì đóng kết nối.
6. Mỗi lần từ chối tăng bộ đếm vi phạm của địa chỉ (đầu vào của FR-03-004).

**Luồng thay thế.** Địa chỉ nguồn chung của một đơn vị sau NAT cần hạn mức cao hơn: SO đưa dải đó vào danh sách tin cậy kèm lý do; vẫn bị hạn mức HTTT ràng buộc.

**Luồng ngoại lệ.**

- Vượt kết nối hoặc tốc độ: ERR-03-119 (429) kèm `Retry-After`; "Quá nhiều yêu cầu từ địa chỉ của bạn trong thời gian ngắn. Thử lại sau {n} giây."
- Đọc quá chậm: đóng kết nối, ghi chỉ số `dh_gateway_slow_client_total`; bên gọi không nhận phản hồi HTTP.
- Địa chỉ nguồn không xác định được (thiếu PROXY từ bộ cân bằng tải): dùng địa chỉ của kết nối và cảnh báo cấu hình ở FR-03-054.

**Đầu ra.** `429` theo ERR-03-119 hoặc cho đi tiếp; chỉ số `dh_gateway_ip_limit_rejected_total{reason}`.

**Kết quả.** Lưu lượng bất thường từ một địa chỉ bị cắt ở biên, nền tảng chịu được tải gấp ba lần cao điểm (900 lượt/giây) không suy giảm (NFR-03-013).

**Hậu điều kiện.** Bộ đếm nằm ở bộ nhớ từng nút (độ chính xác theo nút là đủ cho lớp ngoài cùng); không ghi CSDL.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với từng lượt bị từ chối (đã có chỉ số và nhật ký an ninh tổng hợp); có khi đổi tham số hoặc danh sách tin cậy.

**Quy tắc nghiệp vụ.** BR-03-005; BR-03-001.

**Màn hình, API.** UI-03-15, UI-03-16; API-03-036, API-03-086, API-03-087.
:::

| Tham số | Mặc định | Miền | Cơ sở |
|---|---|---|---|
| `gw.ip.maxConnections` | 100 | 10…1.000 | SRS cũ (FR số 002), mặc định 100 kết nối đồng thời mỗi địa chỉ |
| `gw.ip.uiReqPerSecond` | 50 | 5…500 | SEC-10 |
| `gw.ip.apiReqPerSecond` | 200 | 20…2.000 | Giả định: bốn lần mức giao diện vì HTTT máy dùng chung địa chỉ sau NAT; chỉnh theo số liệu thật (Q03-05) |
| `gw.ip.burst` | 2 lần mức mỗi giây | 1…10 lần | Dung sai đột biến ngắn |
| `gw.ip.trustedCidrs` | Dải bộ giám sát và NDXP của tenant | Danh sách CIDR | Do SO duyệt, ghi kiểm toán |
| `gw.ip.headerTimeoutSeconds` / `gw.ip.bodyTimeoutSeconds` | 10 / 30 | 5…60 | Chống kết nối chậm; có hiệu lực ở mức nhóm cửa vào (`apisix-ext`, `apisix-int`), không theo từng route |

: Tham số giới hạn theo địa chỉ nguồn

#### FR-03-004 · Chặn tạm địa chỉ nguồn vi phạm liên tục

::: dac-ta
**Mục đích.** Tự động loại một địa chỉ nguồn đang tấn công hoặc dò quét khỏi nền tảng trong thời gian ngắn, và cho Cán bộ ATTT chặn thủ công khi có thông tin tình báo, để nguồn tấn công bị chặn trong không quá 60 giây (SEC-10).

**Tác nhân, quyền.** Hệ thống (chặn tự động); SO, PA chặn và bỏ chặn thủ công (`PERM-03-waf`); mọi vai trò có `PERM-03-read` xem danh sách.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-03; CMP-LAW-09; SEC-10, SEC-64; Q03-05.

**Tiền điều kiện.** Valkey truy cập được (danh sách chặn nằm ở Valkey để mọi nút cùng thấy); tham số `gw.ip.autoBlock.*` có trong ảnh chụp.

**Kích hoạt.** Một địa chỉ vượt `gw.ip.autoBlock.threshold` lần bị từ chối ở FR-03-003 hoặc FR-03-005 trong 60 giây; hoặc SO bấm "Chặn địa chỉ" ở UI-03-15.

**Đầu vào.** Với chặn thủ công: `cidr` (T-CIDR, một địa chỉ hoặc dải không rộng hơn /24 cho IPv4, /56 cho IPv6), `durationMinutes` (1…10.080), `reason` (T-TEXT, 10…500 ký tự).

**Luồng xử lý chính.**

1. Plugin `dh-ip-block` của nền tảng đếm số lần vi phạm của mỗi địa chỉ trong cửa sổ 60 giây.
2. Vượt ngưỡng (mặc định 10 lần) thì plugin ghi khóa chặn vào Valkey `{tenant}:ipblock:{cidr}` với thời hạn 15 phút, ghi sự kiện an ninh.
3. Mọi nút kiểm tra khóa này ở đầu chuỗi chốt (thứ tự 2), địa chỉ bị chặn nhận ERR-03-110 mà không tốn thêm xử lý nào.
4. Với chặn thủ công, SO nhập địa chỉ, thời hạn và lý do; hệ thống kiểm tra địa chỉ không thuộc danh sách tin cậy hoặc dải hạ tầng (vi phạm: ERR-03-024), ghi bản ghi EN-03-14 và khóa vào Valkey.
5. Khi hết hạn, khóa Valkey tự xóa; bản ghi chuyển `EXPIRED`.
6. SO bấm "Bỏ chặn" thì khóa bị xóa ngay và bản ghi chuyển `LIFTED`.

**Luồng thay thế.** Chặn một dải do nhiều địa chỉ cùng tấn công: SO nhập CIDR rộng, hệ thống cảnh báo số HTTT đang dùng địa chỉ trong dải (đọc từ nhật ký 7 ngày) trước khi xác nhận.

**Luồng ngoại lệ.**

- Địa chỉ thuộc danh sách tin cậy hoặc hạ tầng: ERR-03-024 (422), "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn."
- Dải quá rộng hoặc thiếu lý do: ERR-03-003 (400), "Chỉ được chặn dải không rộng hơn /24 (IPv4) hoặc /56 (IPv6) và phải nêu lý do."
- Valkey không khả dụng: chặn thủ công lưu vào EN-03-14 và áp dụng khi Valkey trở lại; chặn tự động tạm thời dùng bộ nhớ từng nút; cảnh báo ở FR-03-026.
- Địa chỉ bị chặn gọi: ERR-03-110 (403) không kèm chi tiết, chỉ "Yêu cầu bị từ chối."

**Đầu ra.** `201` cho chặn thủ công, thân gồm `blockId`, `cidr`, `expiresAt`; `204` khi bỏ chặn; phản hồi `403` ERR-03-110 cho địa chỉ bị chặn.

**Kết quả.** Nguồn tấn công bị cắt khỏi nền tảng trong tối đa 60 giây, tự gỡ sau 15 phút nếu không phải do SO đặt tay.

**Hậu điều kiện.** Có bản ghi EN-03-14; khóa Valkey tương ứng.

**Sự kiện phát ra.** EVT-03-09 (cảnh báo an ninh) khi chặn tự động hoặc thủ công.

**Kiểm toán.** Có: người chặn hoặc `AUTO`, `cidr`, lý do, thời hạn, số lần vi phạm đã đếm.

**Quy tắc nghiệp vụ.** BR-03-005; BR-03-023.

**Màn hình, API.** UI-03-15; API-03-036, API-03-037, API-03-038.
:::

#### FR-03-005 · WAF Coraza với bộ luật OWASP CRS

::: dac-ta
**Mục đích.** Phát hiện và chặn tấn công tầng ứng dụng (chèn SQL, XSS, duyệt đường dẫn, chèn lệnh, XXE) ngay ở biên, đáp ứng yêu cầu WAF của cấp độ 3 và chống DDoS tầng 7 của Công văn 631.

**Tác nhân, quyền.** Hệ thống (tự chạy); SO, PA xem sự kiện (`PERM-03-waf-request`); đổi cấu hình qua FR-03-006, 007, 008.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; CMP-LAW-09, CMP-LAW-08; SEC-11; ADR-033; NFR-03-012.

**Tiền điều kiện.** Plugin proxy-wasm Coraza nạp ở cả hai cửa vào; bộ luật CRS 4.x trong ảnh APISIX; mức hoang tưởng và ngưỡng điểm bất thường có trong ảnh chụp.

**Kích hoạt.** Mỗi yêu cầu đã qua chốt kích thước thân (FR-03-009).

**Đầu vào.** Yêu cầu HTTP đã giải mã: dòng yêu cầu, tiêu đề, tham số, thân (tối đa 128 KiB được quét, giả định để giữ chi phí WAF ≤ 5 ms); loại route để chọn mức hoang tưởng.

**Luồng xử lý chính.**

1. Plugin xác định mức hoang tưởng theo loại route: 2 cho đường dẫn giao diện, 1 cho API máy với máy đã có kiểm tra lược đồ (SEC-11).
2. Coraza chạy bộ luật CRS 4.x, cộng điểm bất thường theo từng luật khớp; áp ngoại lệ và luật vá ảo còn hiệu lực của route (FR-03-007, 008).
3. Nếu tổng điểm bất thường đạt ngưỡng (mặc định 5) và chế độ là `BLOCK` thì yêu cầu bị chặn ở bước 4; chế độ `DETECT` thì chỉ ghi nhận.
4. Yêu cầu bị chặn nhận ERR-03-109 (403); sự kiện ghi mã luật khớp, điểm, địa chỉ nguồn, route, `traceId`, đoạn khớp đã che.
5. Vi phạm WAF cũng cộng vào bộ đếm của FR-03-004.
6. Yêu cầu sạch đi tiếp; ghi chỉ số `dh_gateway_waf_blocked_total{rule}`, `dh_gateway_waf_duration_seconds`.

**Luồng thay thế.** Route có thân là tệp nhị phân đã được kiểm tra lược đồ hoặc kênh ký trước: cấu hình `skipBody = true` (do PA duyệt), WAF chỉ quét tiêu đề và tham số.

**Luồng ngoại lệ.**

- Bị chặn: ERR-03-109 (403), "Yêu cầu bị từ chối bởi tường lửa ứng dụng. Nếu bạn cho rằng đây là nhầm lẫn, gửi mã truy vết {traceId} cho quản trị Datahub." (Không nêu mã luật cho bên gọi để không giúp kẻ tấn công dò luật.)
- Cảnh báo giả: vận hành đề nghị ngoại lệ ở FR-03-007.
- WAF lỗi nạp luật: nút giữ bộ luật trước, cảnh báo Nghiêm trọng (FR-03-054).

**Đầu ra.** `403` theo ERR-03-109 hoặc cho đi tiếp; bản ghi sự kiện WAF ở nhật ký an ninh.

**Kết quả.** Tỉ lệ chặn nhầm dưới 0,1% lượt hợp lệ (NFR-03-012); tấn công phổ biến bị chặn trước khi tới backend.

**Hậu điều kiện.** Không đổi dữ liệu; sự kiện WAF được đẩy về SIEM qua PH-13 (SEC-63).

**Sự kiện phát ra.** EVT-03-09 khi số sự kiện chặn tăng đột biến (FR-03-054).

**Kiểm toán.** Có trong nhật ký an ninh (SEC-61): thời điểm, tenant, route, mã luật, điểm, địa chỉ nguồn, `traceId`; không ghi thân yêu cầu.

**Quy tắc nghiệp vụ.** BR-03-007; BR-03-001.

**Màn hình, API.** UI-03-07; API-03-039.
:::

#### FR-03-006 · Chế độ phát hiện, chặn của WAF và tự hạ khi quá tải

::: dac-ta
**Mục đích.** Cho phép đưa WAF vào PROD an toàn (chạy phát hiện trước, rồi mới chặn) và bảo đảm WAF không trở thành nút thắt: khi quá tải, ưu tiên giữ dịch vụ rồi cảnh báo.

**Tác nhân, quyền.** SO, PA đề nghị đổi chế độ (`PERM-03-waf`); TA, SO khác người duyệt (`PERM-03-approve`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-11; ADR-033; NFR-03-012; BR-03-019.

**Tiền điều kiện.** WAF nạp ở cả hai cửa vào (FR-03-005). Để chuyển `DETECT` sang `BLOCK` ở PROD: đã chạy `DETECT` ít nhất 14 ngày và tỉ lệ sự kiện chưa xử lý (cảnh báo giả) dưới ngưỡng `gw.waf.fpReviewMax`.

**Kích hoạt.** SO bấm "Đổi chế độ WAF" ở UI-03-07; hoặc nút APISIX phát hiện WAF quá tải.

**Đầu vào.** `mode` (`DETECT` hoặc `BLOCK`), `scope` (`TENANT` hoặc một `routeCode`), `reason` (T-TEXT).

**Luồng xử lý chính.**

1. SO chọn phạm vi và chế độ mong muốn, nêu lý do.
2. Hệ thống kiểm tra điều kiện 14 ngày chạy phát hiện khi đổi sang `BLOCK` ở PROD (chưa đủ: ERR-03-027).
3. Hệ thống tạo yêu cầu thay đổi EN-03-15 trạng thái chờ duyệt và đưa vào hộp "Việc của tôi" của TA, SO khác (FR-00-070).
4. Người duyệt xem số sự kiện `DETECT` 14 ngày qua theo luật, duyệt hoặc từ chối kèm ý kiến (người đề nghị tự duyệt: ERR-03-008).
5. Được duyệt thì hệ thống sinh ảnh chụp mới (FR-03-039…042) với chế độ mới; mọi nút nạp theo FR-03-043.
6. Tự hạ khi quá tải: nếu `dh_gateway_waf_duration_seconds` p99 vượt `gw.waf.degradeP99Ms` (mặc định 15 ms) liên tục 2 phút trên một nút, plugin `dh-waf-guard` chuyển WAF của nút đó sang `DETECT` tạm thời, phát cảnh báo Nghiêm trọng (FR-03-054); khi p99 dưới ngưỡng 5 phút liên tục thì tự trở lại `BLOCK`.

**Luồng thay thế.** Đổi sang `DETECT` khi đang có sự cố cảnh báo giả diện rộng: vẫn cần người thứ hai duyệt nhưng yêu cầu được đánh dấu khẩn, thông báo đẩy tới người duyệt.

**Luồng ngoại lệ.**

- Chưa đủ 14 ngày chạy phát hiện: ERR-03-027 (422), "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)."
- Người duyệt trùng người đề nghị: ERR-03-008 (403), "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."
- Phát ảnh chụp lỗi: theo FR-03-042; chế độ cũ vẫn chạy.

**Đầu ra.** `202` với `requestId` của yêu cầu thay đổi; khi được duyệt, `snapshotVersion` mới.

**Kết quả.** WAF chuyển chế độ đúng quy trình, có hai người chịu trách nhiệm; khi quá tải dịch vụ vẫn chạy, đội ATTT được báo ngay.

**Hậu điều kiện.** Chế độ WAF trong ảnh chụp đang chạy khớp quyết định; việc tự hạ ở nút không làm đổi cấu hình lưu.

**Sự kiện phát ra.** EVT-03-01 (ảnh chụp phát hành); EVT-03-09 khi tự hạ.

**Kiểm toán.** Có: người đề nghị, người duyệt, ý kiến, phạm vi, chế độ trước và sau, số phiên bản ảnh chụp; sự kiện tự hạ ghi nút, p99 đo được.

**Quy tắc nghiệp vụ.** BR-03-019; BR-03-010.

**Màn hình, API.** UI-03-07, UI-03-17; API-03-040, API-03-041, API-03-071, API-03-072, API-03-073.
:::

#### FR-03-007 · Ngoại lệ luật WAF có thời hạn

::: dac-ta
**Mục đích.** Cho vận hành xử lý cảnh báo giả của WAF (một lượt gọi hợp lệ bị chặn nhầm) bằng cách bỏ qua một mã luật cho một route, trong thời hạn ngắn, có người chịu trách nhiệm. Ngoại lệ là lỗ hổng có chủ đích nên không có ngoại lệ vĩnh viễn và không có ngoại lệ chỉ một người quyết.

**Tác nhân, quyền.** TA, TO, SO đề nghị (`PERM-03-waf-request`); SO duyệt (`PERM-03-waf-approve`); PA, SO thu hồi (`PERM-03-waf`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; CMP-LAW-08; SEC-11, SEC-07; ADR-033; BR-03-006; NFR-03-012.

**Tiền điều kiện.** Có sự kiện WAF chặn ở UI-03-07 làm căn cứ (chọn sự kiện để điền sẵn route và mã luật); người đề nghị có quyền ở tenant.

**Kích hoạt.** Người dùng bấm "Đề nghị ngoại lệ" trên một dòng sự kiện chặn.

**Đầu vào.** Theo bảng "Dữ liệu vào của FR-03-007" dưới đây.

**Luồng xử lý chính.**

1. Người đề nghị chọn sự kiện chặn; hệ thống điền sẵn `routeCode`, `ruleId`, `requestSample` (đã che).
2. Người đề nghị nhập lý do và thời hạn (tối đa 90 ngày); hệ thống kiểm tra mã luật có trong CRS (sai: ERR-03-009), lý do đủ độ dài, thời hạn không quá `gw.waf.exception.maxDays` (quá hạn hoặc thiếu lý do: ERR-03-009).
3. Hệ thống kiểm tra chưa có ngoại lệ còn hiệu lực cho cặp route và mã luật (có rồi: ERR-03-010), tạo EN-03-07 trạng thái `REQUESTED` và việc chờ duyệt cho SO.
4. SO khác người đề nghị xem căn cứ, bấm "Duyệt" hoặc "Từ chối" kèm ý kiến (từ chối bắt buộc lý do, FR-00-072; tự duyệt: ERR-03-008).
5. Khi duyệt, hệ thống chuyển `ACTIVE`, đặt `expiresAt`, sinh ảnh chụp mới có ngoại lệ (FR-03-039…042); sau khi nút nạp, lượt gọi tương tự đi qua.
6. Còn 7 ngày thì chuyển `EXPIRING` và phát EVT-03-06; hết hạn thì chuyển `EXPIRED`, ảnh chụp kế tiếp gỡ ngoại lệ.

**Luồng thay thế.** SO thu hồi sớm một ngoại lệ đang hiệu lực (API-03-046), ghi lý do; ảnh chụp mới gỡ ngoại lệ. Muốn kéo dài phải đề nghị lại từ đầu.

**Luồng ngoại lệ.**

- Thiếu lý do, quá 90 ngày hoặc mã luật không có: ERR-03-009 (422), "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày."
- Đã có ngoại lệ còn hiệu lực: ERR-03-010 (409), "Route này đã có ngoại lệ cho luật {mã luật} đến {ngày}. Thu hồi ngoại lệ cũ hoặc chờ hết hạn."
- Tự duyệt: ERR-03-008 (403), "Bạn đã đề nghị ngoại lệ này nên không thể tự duyệt."
- Tenant chỉ có một SO: không tự duyệt được; PA có thể duyệt thay khi tenant không có SO thứ hai (Q03-02).

**Đầu ra.** `201`, chi tiết ngoại lệ `{exceptionId, state, expiresAt}`; `Location`, `ETag`.

**Kết quả.** Lượt gọi hợp lệ không còn bị chặn nhầm trong thời hạn nêu; mọi ngoại lệ đang có được liệt kê, có người duyệt và hạn.

**Hậu điều kiện.** EN-03-07 ở trạng thái mới; ảnh chụp cấu hình kế tiếp phản ánh danh sách ngoại lệ `ACTIVE`.

**Sự kiện phát ra.** EVT-03-05 (ngoại lệ đổi trạng thái); EVT-03-06 (sắp hết hạn).

**Kiểm toán.** Có: người đề nghị, người duyệt, ý kiến, `routeCode`, `ruleId`, lý do, hạn, giá trị trước và sau, số phiên bản ảnh chụp áp dụng.

**Quy tắc nghiệp vụ.** BR-03-006; BR-03-019.

**Màn hình, API.** UI-03-07, UI-03-08, UI-03-17; API-03-042, API-03-043, API-03-044, API-03-045, API-03-046.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `routeCode` | T-CODE | Có | Route đang `ACTIVE` ở tenant | `tra-cuu-ho-tich.v1` |
| `ruleId` | T-CODE | Có | Mã luật CRS đang nạp, dạng `^9[0-9]{5}$` | `942100` |
| `reason` | T-TEXT | Có | 20…1.000 ký tự | "Trường `ghiChu` chứa dấu nháy hợp lệ trong văn bản hành chính" |
| `expiresAt` | T-TS | Có | Sau thời điểm hiện tại, tối đa 90 ngày | `2027-01-20T00:00:00+07:00` |
| `evidenceEventId` | T-ID | Không | Sự kiện chặn làm căn cứ | `01JD…` |

: Dữ liệu vào của FR-03-007

```{.mermaid caption="Trình tự đề nghị và duyệt ngoại lệ luật WAF"}
sequenceDiagram
  autonumber
  participant TO as Vận hành tenant
  participant CP as dh-connect
  participant SO as Cán bộ ATTT khác người
  participant SY as Bộ đồng bộ
  participant AX as APISIX
  TO->>CP: Đề nghị ngoại lệ route và mã luật, lý do, hạn
  CP->>CP: Kiểm tra mã luật, hạn tối đa 90 ngày, chưa trùng
  CP-->>SO: Việc chờ duyệt trong Việc của tôi
  SO->>CP: Duyệt kèm ý kiến
  CP->>CP: Ngoại lệ ACTIVE, sinh ảnh chụp mới và ký
  CP->>SY: Phát qua Git và bucket
  SY->>AX: Nạp ảnh chụp
  AX-->>CP: Chỉ số phiên bản mới đã chạy
```

Hình cho thấy ngoại lệ chỉ có hiệu lực ở gateway sau khi người thứ hai duyệt và nút đã nạp ảnh chụp mới; không có đường tắt nào đổi luật WAF mà không qua ảnh chụp ký.

#### FR-03-008 · Luật vá ảo khẩn cấp

::: dac-ta
**Mục đích.** Khi công bố lỗ hổng chưa có bản vá cho một backend, Cán bộ ATTT triển khai luật WAF tạm (vá ảo) để chặn kiểu khai thác trong không quá 4 giờ kể từ khi có thông tin (SEC-11).

**Tác nhân, quyền.** SO, PA soạn và đề nghị (`PERM-03-waf`); TA, SO khác người duyệt (`PERM-03-approve`); xem danh sách luật vá ảo cần `PERM-03-waf-request` (API-03-047, vì nội dung luật nêu lỗ hổng nên không mở theo `PERM-03-read`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03; SEC-11, SEC-09; ADR-033; NFR-03-012.

**Tiền điều kiện.** Chế độ WAF của phạm vi áp dụng là `BLOCK` hoặc `DETECT`; có thông tin lỗ hổng (CVE, cảnh báo của cơ quan chuyên trách).

**Kích hoạt.** SO bấm "Thêm luật vá ảo" ở UI-03-08.

**Đầu vào.** `ruleText` (T-TEXT, cú pháp SecLang, ≤ 4 KiB), `appliesTo` (`TENANT`, `ROUTE`, danh sách `routeCode`), `reason`, `reference` (mã CVE hoặc số cảnh báo), `expiresAt` (≤ 90 ngày).

**Luồng xử lý chính.**

1. SO nhập luật SecLang, phạm vi, căn cứ và hạn.
2. Hệ thống kiểm tra cú pháp bằng Coraza ở chế độ thử khô và chạy luật trên bộ yêu cầu mẫu sạch của tenant để ước lượng tỉ lệ chặn nhầm (luật sai cú pháp hoặc chặn quá 1% mẫu sạch: ERR-03-005).
3. Hệ thống tạo EN-03-08 và yêu cầu thay đổi chờ người thứ hai duyệt (khẩn: thông báo đẩy).
4. Người duyệt xem kết quả thử và duyệt; hệ thống sinh ảnh chụp mới và phát.
5. Khi CRS cập nhật có luật tương đương hoặc hết hạn, SO "Gỡ" luật (API-03-049) hoặc luật tự hết hạn.

**Luồng thay thế.** Luật áp cho `TENANT` thay vì từng route: thêm bước cảnh báo "ảnh hưởng mọi route" và yêu cầu SO xác nhận.

**Luồng ngoại lệ.**

- Luật sai cú pháp hoặc chặn quá 1% mẫu sạch: ERR-03-005 (422), "Luật không hợp lệ hoặc chặn nhầm quá 1% yêu cầu mẫu. Xem chi tiết lỗi bên dưới."
- Tự duyệt: ERR-03-008 (403).
- Thiếu căn cứ hoặc quá 90 ngày: ERR-03-009 (422).

**Đầu ra.** `201`, `{patchId, state, expiresAt, dryRun: {sampleCount, wouldBlock}}`.

**Kết quả.** Luật vá ảo có hiệu lực trong vài phút sau duyệt; đội ATTT có thời gian vá backend.

**Hậu điều kiện.** EN-03-08 `ACTIVE`; ảnh chụp mới chứa luật.

**Sự kiện phát ra.** EVT-03-01.

**Kiểm toán.** Có: người soạn, người duyệt, nội dung luật (băm và bản đầy đủ), căn cứ, kết quả thử khô.

**Quy tắc nghiệp vụ.** BR-03-019; BR-03-006.

**Màn hình, API.** UI-03-08; API-03-047, API-03-048, API-03-049.
:::

#### FR-03-009 · Kiểm tra lược đồ và giới hạn kích thước yêu cầu

::: dac-ta
**Mục đích.** Từ chối sớm yêu cầu sai cấu trúc hoặc quá lớn: giữ backend khỏi bản tin khổng lồ, JSON lồng sâu, XML có thực thể ngoài, và bảo đảm chỉ yêu cầu khớp hợp đồng OpenAPI đã duyệt mới đi tiếp (SEC-43).

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA cấu hình giới hạn ở route (`PERM-03-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-43; NFR-00-001; D03-09 §5 (trần thân 10 MB).

**Tiền điều kiện.** Route có lược đồ OpenAPI đã duyệt ở PH-02 được đưa vào ảnh chụp (BR-03-014); tham số `gw.body.*` và `gw.json.*` có trong ảnh chụp.

**Kích hoạt.** Mỗi yêu cầu tới route, ở hai thời điểm: kiểm tra kích thước (chốt 3) và kiểm tra lược đồ (chốt 10, sau khi đã xác thực).

**Đầu vào.** Tiêu đề `Content-Length`, `Content-Type`; thân yêu cầu; theo bảng "Giới hạn yêu cầu mặc định" dưới đây; lược đồ OpenAPI của route.

**Luồng xử lý chính.**

1. APISIX so `Content-Length` với `bodyMaxBytes` của route (mặc định 1 MiB, trần 10 MiB); thân lớn hơn bị từ chối ngay, không đọc hết (ERR-03-115).
2. Với thân không có `Content-Length` (chunked), APISIX cắt khi đếm vượt giới hạn (ERR-03-115).
3. Sau khi xác thực, plugin `request-validation` kiểm tra tiêu đề, tham số đường dẫn, tham số truy vấn và thân theo lược đồ OpenAPI của route.
4. Với JSON: độ sâu lồng không quá 32, số phần tử mảng không quá 10.000, độ dài chuỗi theo lược đồ; với XML: tắt DTD, thực thể ngoài, XInclude (vi phạm: ERR-03-101).
5. `Content-Type` không nằm trong danh sách route khai báo thì trả ERR-03-101; Datahub không dùng riêng mã `415` để giữ một mã lỗi cho mọi vi phạm cấu trúc.
6. Yêu cầu hợp lệ đi tiếp; ghi chỉ số `dh_gateway_validation_rejected_total{reason}`.

**Luồng thay thế.** Tệp lớn (trên 10 MiB): bên gọi lấy URL ký trước tới kho đối tượng qua API của DU; gateway không nhận tệp lớn (D03-09 §5).

**Luồng ngoại lệ.**

- Thân quá lớn: ERR-03-115 (413), "Nội dung gửi lên vượt giới hạn {n} MiB của API này. Giảm kích thước hoặc dùng kênh tải tệp."
- Sai lược đồ, JSON quá sâu, XML bị cấm, `Content-Type` sai: ERR-03-101 (400), "Yêu cầu không đúng định dạng: {danh sách lỗi theo trường}." (Danh sách lỗi theo trường chỉ nêu đường dẫn và quy tắc, không lộ lược đồ nội bộ.)

**Đầu ra.** `413` ERR-03-115 hoặc `400` ERR-03-101 theo RFC 9457 với `errors[]` (đường dẫn trường, quy tắc); hoặc cho đi tiếp.

**Kết quả.** Backend chỉ nhận yêu cầu đúng hợp đồng và đúng cỡ; 0 lỗi 5xx do fuzzing đầu vào (SEC-43).

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với từng lượt (có chỉ số và nhật ký lượt gọi); có khi đổi giới hạn ở route.

**Quy tắc nghiệp vụ.** BR-03-014; BR-03-023.

**Màn hình, API.** UI-03-03; API-03-009, API-03-002.
:::

| Tham số | Mặc định | Trần | Cơ sở |
|---|---|---|---|
| `gw.body.maxBytes` (route) | 1 MiB | 10 MiB | SEC-43; D03-09 §5 |
| `gw.json.maxDepth` | 32 | 64 | SEC-43 |
| `gw.json.maxArrayItems` | 10.000 | 100.000 | SEC-43 |
| `gw.xml.allowDoctype` | `false` | không đổi | SEC-43 |
| `gw.waf.bodyScanBytes` | 128 KiB | 1 MiB | Giả định: giữ chi phí WAF ≤ 5 ms với yêu cầu ≤ 32 KB (NFR-03-002) |

: Giới hạn yêu cầu mặc định

#### FR-03-010 · Xử lý CORS

::: dac-ta
**Mục đích.** Cho ứng dụng trình duyệt của tổ chức gọi API qua gateway an toàn: chỉ nguồn gốc (origin) đã khai báo mới được gọi từ trình duyệt, không dùng ký tự đại diện.

**Tác nhân, quyền.** TA, PA cấu hình chính sách CORS theo route (`PERM-03-admin`); trình duyệt của người dùng (bên gọi).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03; SEC-44; BR-03-012.

**Tiền điều kiện.** Route có khai báo `corsPolicy` trong ảnh chụp; ở MVP giao diện `dh-console` và `dh-portal` cùng nguồn gốc với BFF nên không cần CORS.

**Kích hoạt.** Trình duyệt gửi yêu cầu kiểm tra trước (`OPTIONS`) hoặc yêu cầu có tiêu đề `Origin`.

**Đầu vào.** `allowedOrigins[]` (T-URL, mỗi phần tử một nguồn gốc đầy đủ), `allowedMethods[]`, `allowedHeaders[]`, `exposedHeaders[]`, `allowCredentials` (mặc định `false`), `maxAgeSeconds` (mặc định 600).

**Luồng xử lý chính.**

1. Quản trị nhập danh sách nguồn gốc cho một route; hệ thống từ chối ký tự đại diện `*` và nguồn gốc không đúng dạng `https://host[:port]` (ERR-03-005).
2. Ảnh chụp mới mang cấu hình CORS tới các nút.
3. Khi trình duyệt gửi `OPTIONS`, APISIX so `Origin` với danh sách của route.
4. Khớp thì trả `204` với `Access-Control-Allow-Origin` đúng nguồn gốc đó, phương thức, tiêu đề được phép, `Access-Control-Max-Age`.
5. Yêu cầu thật có `Origin` hợp lệ nhận thêm tiêu đề `Access-Control-Allow-Origin`, `Vary: Origin`.

**Luồng thay thế.** Route không khai báo CORS: không trả tiêu đề CORS nào, trình duyệt tự chặn.

**Luồng ngoại lệ.**

- Cấu hình có ký tự đại diện hoặc nguồn gốc sai dạng: ERR-03-005 (422), "Không dùng ký tự đại diện cho nguồn gốc CORS. Nhập từng nguồn gốc đầy đủ, ví dụ https://qlvb.t68.gov.vn."
- Nguồn gốc không được phép: gateway không trả tiêu đề CORS và vẫn xử lý yêu cầu như thường (trình duyệt sẽ chặn phía khách); ghi chỉ số `dh_gateway_cors_denied_total`.

**Đầu ra.** `204` cho yêu cầu kiểm tra trước hợp lệ; tiêu đề CORS trên phản hồi.

**Kết quả.** Ứng dụng web được phép gọi API từ trình duyệt; ứng dụng lạ không gọi được.

**Hậu điều kiện.** Không đổi dữ liệu nghiệp vụ.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đổi chính sách CORS: route, danh sách trước và sau.

**Quy tắc nghiệp vụ.** BR-03-012.

**Màn hình, API.** UI-03-03; API-03-050, API-03-051.
:::

#### FR-03-011 · Tiêu đề bảo mật và che thông tin máy chủ

::: dac-ta
**Mục đích.** Giảm thông tin có lợi cho kẻ dò lỗ hổng và áp tiêu đề bảo mật chuẩn cho mọi phản hồi qua gateway.

**Tác nhân, quyền.** Hệ thống (tự chạy); PA cấu hình mặc định (`PERM-03-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-12, SEC-43, SEC-44; NFR-03-015.

**Tiền điều kiện.** Cấu hình tiêu đề mặc định có trong ảnh chụp.

**Kích hoạt.** Mỗi phản hồi gateway trả cho bên gọi, kể cả phản hồi lỗi do gateway sinh.

**Đầu vào.** Tiêu đề phản hồi của backend; cấu hình tiêu đề mặc định của tenant.

**Luồng xử lý chính.**

1. Gateway xóa các tiêu đề lộ phiên bản hoặc công nghệ: `Server`, `X-Powered-By`, `X-AspNet-Version`, `Via` nội bộ; đặt `Server` thành giá trị chung `datahub`.
2. Gateway thêm `Strict-Transport-Security: max-age=31536000; includeSubDomains`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`.
3. Với phản hồi lỗi do gateway sinh, gateway luôn đặt `Content-Type: application/problem+json` và `X-Trace-Id`, không kèm vết ngăn xếp hay tên nội bộ (ERR-03-129 cho lỗi nội bộ).
4. Với đường dẫn giao diện, tiêu đề CSP do BFF đặt (SEC-44); gateway không ghi đè CSP.
5. Quét kiểm thử hằng tuần (ZAP, testssl.sh) xác nhận không còn tiêu đề lộ phiên bản.

**Luồng thay thế.** Route cần giữ một tiêu đề của backend mà mặc định bị xóa: PA khai báo danh sách tiêu đề được phép ở route, có duyệt ở FR-03-048.

**Luồng ngoại lệ.**

- Lỗi nội bộ gateway: ERR-03-129 (500), "Hệ thống gặp sự cố. Gửi mã truy vết {traceId} cho quản trị Datahub." (Không nêu nguyên nhân kỹ thuật.)

**Đầu ra.** Phản hồi với tiêu đề đã làm sạch và bổ sung.

**Kết quả.** Bên gọi và công cụ quét bên ngoài không đọc được phiên bản phần mềm; tiêu đề bảo mật có mặt trên mọi phản hồi.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đổi cấu hình tiêu đề mặc định.

**Quy tắc nghiệp vụ.** BR-03-013; BR-03-023.

**Màn hình, API.** UI-03-16; API-03-086, API-03-087.
:::

### 6.3. Nhóm B · Xác thực và kiểm soát truy cập thô

Nhóm B trả lời bốn câu hỏi theo thứ tự rẻ đến đắt: token có thật và còn hạn không, thuộc tenant nào, HTTT này có được đăng ký dùng API này không, và có phạm vi cần thiết không; cuối cùng mới hỏi OPA. Gateway chỉ kiểm soát thô; quyết định chi tiết theo vai trò, mức phân loại và mục đích do OPA và từng DU ra (BR-03-008). Hình dưới là quan hệ giữa các chức năng trong nhóm.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm B"}
flowchart TB
  F012["FR-03-012 Xác minh JWT"] --> F013["FR-03-013 Xác định tenant"]
  F013 --> F014["FR-03-014 Ràng buộc chứng thư"]
  F014 --> F018["FR-03-018 Kiểm tra thu hồi"]
  F018 --> F015["FR-03-015 Phương thức theo gói"]
  F015 --> F016["FR-03-016 Đăng ký sử dụng"]
  F016 --> F017["FR-03-017 Phạm vi thô"]
  F017 --> F020["FR-03-020 Đường dẫn cho phép, chặn"]
  F020 --> F019["FR-03-019 OPA"]
  F002["FR-03-002 mTLS (nhóm A)"] -.-> F014
  F046["FR-03-046 Đồng bộ consumer (nhóm E)"] -.-> F016
```

#### FR-03-012 · Xác minh chữ ký JWT cục bộ

::: dac-ta
**Mục đích.** Xác minh token truy cập của mọi lượt gọi bằng khóa công khai đã đệm tại gateway, không gọi Keycloak cho từng lượt, để Keycloak không thành nút thắt và sự cố Keycloak không làm sập đường đi của lượt gọi (BR-03-004).

**Tác nhân, quyền.** HTTT gọi API, người dùng giao diện (qua BFF); Keycloak (nguồn JWKS); quyền xem trạng thái bộ đệm `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-12; LGC-BUS-041, LGC-APIM-011; SEC-25; ADR-006; NFR-03-002.

**Tiền điều kiện.** Route yêu cầu token (không phải `KEYLESS`, FR-03-015); URL JWKS của realm tenant có trong ảnh chụp; bộ đệm JWKS đã nạp ít nhất một lần.

**Kích hoạt.** Yêu cầu có tiêu đề `Authorization: Bearer {token}` tới route yêu cầu xác thực.

**Đầu vào.** Token JWT; JWKS của realm `dh-{tenant}`; tham số `gw.jwks.refreshMinutes` (10), `gw.jwt.clockSkewSeconds` (30), `gw.jwks.maxStaleHours` (24), `gw.jwks.kidRefreshMinIntervalSeconds` (30).

**Luồng xử lý chính.**

1. Plugin trích token từ tiêu đề; chỉ nhận lược đồ `Bearer`, một token (thiếu: ERR-03-102).
2. Plugin giải mã phần tiêu đề JWT, từ chối `alg` không thuộc `ES256`, `PS256` (kể cả `none`, `HS*`) và lấy `kid` (sai: ERR-03-103).
3. Plugin tìm khóa công khai theo `kid` trong bộ đệm JWKS của realm tương ứng với tenant của route; nếu chưa có `kid`, làm mới JWKS một lần (tối đa mỗi 30 giây mỗi realm để không bị lợi dụng làm quá tải Keycloak); vẫn không có: ERR-03-103.
4. Plugin xác minh chữ ký, rồi kiểm tra `iss` khớp realm của tenant, `aud` có nhóm API của route, `exp` và `nbf` với dung sai 30 giây (`exp` quá hạn: ERR-03-104; còn lại sai: ERR-03-103).
5. Plugin trích `sub`, `azp` (client), `scope`, `tenant`, `cnf` đưa vào ngữ cảnh yêu cầu cho các chốt sau (FR-03-013…019).
6. Nền làm mới JWKS định kỳ 10 phút; ghi chỉ số `dh_gateway_jwt_verify_total{result}` và `dh_gateway_jwks_age_seconds`.

**Luồng thay thế.** Keycloak không trả JWKS khi làm mới: nút tiếp tục dùng khóa đã đệm tới 24 giờ kể từ lần làm mới thành công cuối (NFR-03-007); token ký bằng khóa mới chưa có trong bộ đệm không qua được trong thời gian đó.

**Luồng ngoại lệ.**

- Thiếu tiêu đề hoặc sai lược đồ: ERR-03-102 (401) kèm `WWW-Authenticate: Bearer realm="datahub"`; "Thiếu thông tin xác thực. Gửi token truy cập trong tiêu đề Authorization."
- Chữ ký sai, `alg` cấm, `kid` lạ, `iss`, `aud` sai: ERR-03-103 (401), "Token không hợp lệ. Lấy token mới từ máy chủ định danh."
- Token hết hạn: ERR-03-104 (401) kèm `WWW-Authenticate: Bearer error="invalid_token", error_description="expired"`; "Token đã hết hạn. Lấy token mới rồi gọi lại."
- Bộ đệm JWKS quá 24 giờ không làm mới được: ERR-03-124 (503) kèm `Retry-After: 30`; "Dịch vụ định danh tạm thời không khả dụng. Thử lại sau." Cảnh báo Nghiêm trọng ở FR-03-054.

**Đầu ra.** Ngữ cảnh yêu cầu có `sub`, `client`, `scope`, `tenant`, `cnf`; hoặc `401`, `503` theo mã trên.

**Kết quả.** Token giả, hết hạn hoặc sai nơi phát hành bị loại ở gateway với độ trễ không quá 2 ms mỗi lượt (NFR-03-002); đường đi không gọi mạng tới Keycloak.

**Hậu điều kiện.** Bộ đệm JWKS có thể được làm mới; không đổi dữ liệu khác.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có trong nhật ký an ninh khi từ chối do chữ ký sai hoặc `kid` lạ (nghi giả mạo): địa chỉ nguồn, `kid`, `iss`, `traceId`; không ghi token.

**Quy tắc nghiệp vụ.** BR-03-004; BR-03-002.

**Màn hình, API.** UI-03-11; API-03-052.
:::

```{.mermaid caption="Trình tự xác minh JWT và làm mới JWKS khi gặp kid lạ"}
sequenceDiagram
  autonumber
  participant H as HTTT gọi
  participant AX as APISIX
  participant C as Bộ đệm JWKS
  participant KC as Keycloak realm dh-t68
  H->>AX: Bearer token, kid = k2
  AX->>C: Tìm khóa k2
  C-->>AX: Chưa có
  AX->>KC: Làm mới JWKS, tối đa mỗi 30 giây
  KC-->>AX: JWKS gồm k1, k2
  AX->>C: Cập nhật bộ đệm
  AX->>AX: Xác minh chữ ký, iss, aud, exp
  AX-->>H: Cho đi tiếp hoặc 401 theo ERR-03-103, 104
```

Hình cho thấy đường làm mới JWKS chỉ chạy khi gặp `kid` lạ và có giới hạn tần suất; bình thường mọi lượt xác minh dùng khóa đã đệm.

#### FR-03-013 · Xác định tenant của lượt gọi

::: dac-ta
**Mục đích.** Bảo đảm tenant của lượt gọi chỉ lấy từ token đã xác minh và không giả mạo được bằng tiêu đề hay tham số, làm nền cho cách ly dữ liệu ở mọi DU phía sau (SEC-80, D03-10 §3).

**Tác nhân, quyền.** Hệ thống (tự chạy).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-20; SEC-80, SEC-87; ADR-003; D03-10 §3; NFR-03-019.

**Tiền điều kiện.** Token đã qua FR-03-012; route có `tenant` (hoặc là route dùng chung `COMMON`); bảng ánh xạ host với tenant có trong ảnh chụp.

**Kích hoạt.** Ngay sau khi xác minh chữ ký token.

**Đầu vào.** Claim `tenant` của token; `iss` (realm); tenant của route theo host hoặc tiền tố đường dẫn; mọi tiêu đề `X-DH-*` của yêu cầu gốc.

**Luồng xử lý chính.**

1. Plugin xóa mọi tiêu đề có tiền tố `X-DH-` mà bên gọi gửi tới, trước mọi xử lý khác của chốt này.
2. Plugin đối chiếu `tenant` trong token với realm của `iss` (realm `dh-t68` chỉ được mang `tenant = T68`); khác nhau: ERR-03-106.
3. Với route của một tenant, plugin đối chiếu tenant của token với tenant của route; khác nhau: ERR-03-106 và ghi sự kiện an ninh "truy cập chéo tenant".
4. Với route dùng chung `COMMON`, plugin chấp nhận token của mọi realm tenant hợp lệ và lấy tenant từ token.
5. Plugin đặt `X-DH-Tenant`, `X-DH-Client` (`azp`), `X-DH-Consumer` và `traceparent` cho backend; hạn mức theo tenant (FR-03-023) dùng chính giá trị này.
6. Backend và DU chỉ tin `X-DH-Tenant` khi lượt gọi đến từ APISIX qua mesh (kiểm tra danh tính SPIFFE, SEC-80) và vẫn đọc lại tenant từ token để đặt ngữ cảnh.

**Luồng thay thế.** Giao diện: BFF gọi gateway bằng token của người dùng; tenant lấy từ token như HTTT máy, không có đường riêng.

**Luồng ngoại lệ.**

- Tenant của token không khớp realm hoặc route: ERR-03-106 (401), "Token không thuộc tỉnh của API này. Lấy token từ máy chủ định danh của đúng tỉnh."
- Host không thuộc tenant nào: ERR-03-114 (404), "Không tìm thấy dịch vụ."

**Đầu ra.** Yêu cầu chuyển tiếp mang `X-DH-Tenant`, `X-DH-Client`, `X-DH-Consumer`; hoặc `401`.

**Kết quả.** Không HTTT nào chọn được tenant khác bằng cách tự khai; mọi DU nhận tenant đã được gateway chứng thực.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** EVT-03-09 khi phát hiện truy cập chéo tenant (nghi tấn công).

**Kiểm toán.** Có trong nhật ký an ninh khi có truy cập chéo tenant: tenant token, tenant route, client, địa chỉ nguồn, `traceId`.

**Quy tắc nghiệp vụ.** BR-03-002; BR-03-026; BR-03-028.

**Màn hình, API.** Không có màn hình riêng (sự kiện xem ở UI-03-07, UI-03-09); không có API quản trị riêng.
:::

#### FR-03-014 · Ràng buộc token với chứng thư khách

::: dac-ta
**Mục đích.** Với HTTT dùng mTLS, bảo đảm token chỉ dùng được bởi đúng chủ chứng thư: token bị đánh cắp mà không có chứng thư và khóa riêng thì vô dụng (RFC 8705, SEC-24, SEC-25).

**Tác nhân, quyền.** HTTT dùng phương thức `MTLS`; PA, TA xem thông tin xác thực công khai (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-12; LGC-BUS-041, LGC-APIM-011; SEC-24, SEC-25; NFR-00-020.

**Tiền điều kiện.** Token có claim `cnf.x5t#S256`; kết nối đã qua FR-03-002 và ngữ cảnh có `client_cert_sha256`; plan có `securityMode = MTLS` (hợp đồng mức Nhạy cảm bắt buộc, SEC-24).

**Kích hoạt.** Sau FR-03-012 và FR-03-013, với route có `securityMode = MTLS` hoặc token có `cnf`.

**Đầu vào.** `cnf.x5t#S256` của token; `client_cert_sha256` của kết nối; `thumbprint` đã đăng ký của consumer (EN-03-04).

**Luồng xử lý chính.**

1. Plugin kiểm tra: nếu plan của route là `MTLS` thì token bắt buộc có `cnf` (thiếu: ERR-03-108).
2. Nếu token có `cnf`, plugin so với vân tay chứng thư của kết nối hiện tại (khác hoặc kết nối không có chứng thư: ERR-03-108).
3. Plugin so vân tay đó với vân tay đã đăng ký cho consumer của `azp` (không khớp: ERR-03-108; ghi sự kiện an ninh vì có thể là token bị đánh cắp).
4. Khớp cả ba: gắn `ctx.cert_bound = true` và cho đi tiếp.

**Luồng thay thế.** Plan `OAUTH2` thuần: token không có `cnf` thì bỏ qua chốt này; token có `cnf` mà kết nối không có chứng thư vẫn bị từ chối (không hạ mức bảo vệ của token).

**Luồng ngoại lệ.**

- Không khớp hoặc thiếu ràng buộc: ERR-03-108 (403), "Token không đi cùng chứng thư đã đăng ký của HTTT. Gọi lại bằng đúng chứng thư."
- Chứng thư khách mới (đã xoay) chưa có trong EN-03-04: cùng ERR-03-108; PH-01 phải cập nhật vân tay trước khi chuyển chứng thư (FR-03-046).

**Đầu ra.** Cho đi tiếp, hoặc `403` ERR-03-108.

**Kết quả.** Token bị đánh cắp không dùng lại được từ máy khác.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** EVT-03-09 khi vân tay trong token không khớp chứng thư kết nối.

**Kiểm toán.** Có trong nhật ký an ninh khi từ chối: client, hai vân tay (băm cắt ngắn), địa chỉ nguồn, `traceId`.

**Quy tắc nghiệp vụ.** BR-03-004; BR-03-022.

**Màn hình, API.** UI-03-05; API-03-012, API-03-016.
:::

#### FR-03-015 · Áp phương thức bảo mật theo gói sử dụng

::: dac-ta
**Mục đích.** Thực thi ở gateway bước "Secure" của gói sử dụng ở PH-02, nâng cấp so với hệ cũ chỉ có Keyless và API key: thêm OAuth 2.1 `client_credentials` và mTLS, và chỉ cho Keyless với API dữ liệu mở.

**Tác nhân, quyền.** Hệ thống (tự chạy); PH-02 là nguồn của gói; PA, TA xem chính sách chiếu (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-011; LGC-BUS-041; SEC-24; ADR-005.

**Tiền điều kiện.** Mỗi route có gói (policy chiếu EN-03-05) với `securityMode` ∈ {`KEYLESS`, `API_KEY`, `OAUTH2`, `MTLS`}; ảnh chụp đã qua kiểm tra FR-03-040.

**Kích hoạt.** Mỗi lượt gọi tới route, ngay sau chốt TLS và địa chỉ nguồn.

**Đầu vào.** `securityMode` của gói; thông tin xác thực trong yêu cầu: `Authorization: Bearer`, `X-API-Key`, chứng thư khách.

**Luồng xử lý chính.**

1. Gateway đọc `securityMode` của gói ứng với route.
2. `KEYLESS`: không yêu cầu thông tin xác thực; chỉ được cấu hình khi API đánh dấu dữ liệu mở (kiểm tra ở FR-03-040); vẫn áp hạn mức theo địa chỉ nguồn (FR-03-003), WAF và hạn mức route.
3. `API_KEY`: plugin băm khóa trong `X-API-Key` (SHA-256) và tra consumer theo `apiKeyHash`; chỉ dùng cho API mức phân loại Công khai hoặc Nội bộ trong giai đoạn chuyển đổi, khóa hết hạn tối đa 180 ngày (SEC-24).
4. `OAUTH2`: yêu cầu token hợp lệ qua FR-03-012…013.
5. `MTLS`: yêu cầu token hợp lệ cộng chứng thư khách khớp qua FR-03-002 và FR-03-014.
6. Phương thức trong yêu cầu không phải phương thức của gói (ví dụ gửi `X-API-Key` tới route `MTLS`): ERR-03-130.

**Luồng thay thế.** Giai đoạn chuyển đổi từ hệ cũ: gói của hệ cũ dùng API key được nhập thành `API_KEY` kèm hạn tối đa 180 ngày và cờ "cần chuyển sang OAuth 2.1" hiển thị ở UI-03-05 (FR-03-059).

**Luồng ngoại lệ.**

- Phương thức không đúng gói: ERR-03-130 (403), "API này yêu cầu xác thực bằng {OAuth 2.1 | chứng thư mTLS}. Phương thức bạn dùng không được chấp nhận."
- Khóa API không tìm thấy hoặc hết hạn: ERR-03-103 (401), "Khóa API không hợp lệ hoặc đã hết hạn."
- Cấu hình `KEYLESS` cho API không phải dữ liệu mở, hoặc `API_KEY` cho hợp đồng từ mức Hạn chế: bị chặn khi kiểm tra cấu hình, ERR-03-005 (422), "Gói này không được phép dùng phương thức {…} cho API có mức phân loại {…}."

**Đầu ra.** Cho đi tiếp với danh tính consumer, hoặc `401`, `403` theo mã trên.

**Kết quả.** Mỗi API dùng đúng phương thức xác thực mạnh theo mức phân loại; không còn khóa dùng chung cho dữ liệu hạn chế.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đổi gói ở PH-02 (do PH-02 ghi); ở gateway ghi từ chối lặp lại (nghi dò) vào nhật ký an ninh.

**Quy tắc nghiệp vụ.** BR-03-004; BR-03-014.

**Màn hình, API.** UI-03-03, UI-03-13; API-03-021, API-03-022, API-03-066.
:::

#### FR-03-016 · Kiểm tra đăng ký sử dụng và hiệu lực gói

::: dac-ta
**Mục đích.** Bảo đảm chỉ HTTT đã được duyệt đăng ký sử dụng một API, và đăng ký còn hiệu lực, mới gọi được API đó; việc thu hồi hay hết hạn đăng ký có tác dụng ngay ở gateway.

**Tác nhân, quyền.** HTTT gọi API; PH-02 (nguồn đăng ký); PH-01 (trạng thái HTTT); xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-011; LGC-APIM-016; SEC-24; ADR-005; BR-03-022.

**Tiền điều kiện.** Consumer đã được nhận diện (token, chứng thư hoặc API key); ảnh chụp có danh sách đăng ký đang hiệu lực của consumer với route (plugin `consumer-restriction`).

**Kích hoạt.** Sau khi nhận diện consumer, trước hạn mức.

**Đầu vào.** `consumerCode`; `routeCode`; đăng ký (`subscriptionState`, `validFrom`, `validTo`, `planCode`).

**Luồng xử lý chính.**

1. Gateway tra consumer trong ảnh chụp theo `azp`, vân tay hoặc khóa; không có consumer: ERR-03-111.
2. Gateway kiểm tra trạng thái consumer: `SUSPENDED` hoặc `BLOCKED` (do PH-01 tạm ngừng hay tạm ngừng khẩn cấp FR-03-047) thì ERR-03-127.
3. Gateway kiểm tra consumer có đăng ký `ACTIVE` cho API của route, trong khoảng `validFrom`…`validTo` (không có hoặc hết hiệu lực: ERR-03-111).
4. Gateway gắn chính sách của gói đăng ký vào ngữ cảnh (hạn mức, hạn ngạch, đường dẫn cho phép) để các chốt sau dùng.
5. Thay đổi đăng ký (duyệt mới, thu hồi, hết hạn) ở PH-02 sinh ảnh chụp mới qua FR-03-046, có hiệu lực ở mọi nút trong 10 giây (NFR-03-008).

**Luồng thay thế.** Route công khai dữ liệu mở (`KEYLESS`): không có consumer; bước này bỏ qua và dùng chính sách mặc định của gói.

**Luồng ngoại lệ.**

- Chưa đăng ký hoặc đăng ký hết hiệu lực: ERR-03-111 (403), "HTTT của bạn chưa đăng ký sử dụng API này hoặc đăng ký đã hết hiệu lực. Liên hệ chủ dịch vụ hoặc quản trị Datahub."
- HTTT đang bị tạm ngừng: ERR-03-127 (403), "HTTT của bạn đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub."

**Đầu ra.** Cho đi tiếp kèm chính sách của gói; hoặc `403`.

**Kết quả.** Đăng ký bị thu hồi thì lượt gọi kế tiếp (trong tối đa 10 giây) bị từ chối, không cần chờ token hết hạn.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với từng lượt từ chối (đã có nhật ký lượt gọi); thay đổi đăng ký do PH-02 ghi.

**Quy tắc nghiệp vụ.** BR-03-021; BR-03-022.

**Màn hình, API.** UI-03-05; API-03-012, API-03-021.
:::

#### FR-03-017 · Kiểm tra phạm vi quyền thô

::: dac-ta
**Mục đích.** Loại sớm lượt gọi thiếu phạm vi (scope) cơ bản, để backend và OPA không phải xử lý lượt gọi chắc chắn bị từ chối.

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA xem phạm vi yêu cầu của route (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-011; SEC-25, SEC-26; BR-03-008.

**Tiền điều kiện.** Route khai báo `requiredScopes[]` (từ PH-02, có thể rỗng); token đã được xác minh (FR-03-012).

**Kích hoạt.** Sau FR-03-016.

**Đầu vào.** Claim `scope` (danh sách cách nhau dấu cách); `requiredScopes[]` của route theo phương thức HTTP.

**Luồng xử lý chính.**

1. Plugin lấy `requiredScopes` của route ứng với phương thức của yêu cầu (đọc `GET`, ghi `POST`, `PUT`, `DELETE` có thể có scope khác nhau).
2. Plugin kiểm tra mọi scope yêu cầu đều có trong `scope` của token.
3. Thiếu scope thì dừng ngay, không chuyển tiếp (ERR-03-107).
4. Đủ thì cho đi tiếp; chi tiết "được xem công dân nào, mục đích gì" do OPA quyết (FR-03-019).

**Luồng thay thế.** Route không khai báo scope: bỏ qua chốt này (chỉ hợp lệ với API đã được duyệt không cần scope, và FR-03-040 cảnh báo).

**Luồng ngoại lệ.**

- Thiếu scope: ERR-03-107 (403), "Token thiếu phạm vi quyền {scope}. Xin cấp thêm phạm vi này cho HTTT của bạn." (Tên scope thiếu chỉ nêu cho bên đã xác thực.)

**Đầu ra.** Cho đi tiếp, hoặc `403` ERR-03-107.

**Kết quả.** Lượt gọi thiếu quyền cơ bản bị chặn với độ trễ không đáng kể.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (có nhật ký lượt gọi).

**Quy tắc nghiệp vụ.** BR-03-008.

**Màn hình, API.** UI-03-03; API-03-002, API-03-022.
:::

#### FR-03-018 · Thu hồi token nhanh bằng danh sách chặn

::: dac-ta
**Mục đích.** Thu hẹp thời gian rủi ro của token từ 5 phút (thời hạn token) xuống dưới 60 giây khi cần thu hồi khẩn: HTTT bị lộ khóa, người dùng bị khóa tài khoản, sự cố an ninh.

**Tác nhân, quyền.** PH-12 (đẩy danh sách chặn bằng scope `gateway:revoke`); SO, TA xem danh sách (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-12; SEC-25; NFR-03-009; BR-03-021.

**Tiền điều kiện.** Valkey truy cập được; plugin `dh-revocation` nạp ở mọi nút.

**Kích hoạt.** PH-12 vô hiệu hóa một client hoặc người dùng ở Keycloak, hoặc thu hồi một token cụ thể, rồi gọi API-03-053.

**Đầu vào.** `kind` (`JTI` hoặc `SUBJECT`), `jti` hoặc `sub`, `notBefore` (T-TS: mọi token của `sub` phát hành trước thời điểm này bị chặn), `tokenExpiresAt` (T-TS), `reason` (T-TEXT).

**Luồng xử lý chính.**

1. PH-12 gọi API-03-053 với danh tính cần chặn.
2. `dh-connect` kiểm tra scope của người gọi, lưu bản ghi vào `ph03_gateway.revoked_token` (để dựng lại khi Valkey mất) và ghi khóa vào Valkey `{tenant}:revoked:jti:{jti}` hoặc `{tenant}:revoked:sub:{sub}` với thời hạn bằng thời gian sống còn lại của token cộng dung sai.
3. Plugin `dh-revocation` ở mỗi nút tra khóa trong Valkey cho mọi lượt gọi đã xác minh chữ ký, có bộ đệm cục bộ 5 giây.
4. Token bị chặn nhận ERR-03-105; sự kiện ghi vào nhật ký an ninh.
5. Khóa tự xóa khi token hết hạn tự nhiên; bản ghi DB bị dọn sau 24 giờ.
6. Khi Valkey mất dữ liệu, `dh-connect` nạp lại từ bảng `revoked_token` các bản ghi chưa hết hạn.

**Luồng thay thế.** Thu hồi theo client: chặn `sub` của client với `notBefore = now`, mọi token phát trước đó bị chặn, token mới (sau khi khóa client được xoay) dùng được.

**Luồng ngoại lệ.**

- Token trong danh sách chặn: ERR-03-105 (401), "Token đã bị thu hồi. Liên hệ quản trị Datahub nếu cần cấp lại."
- Valkey không khả dụng: nút dùng bộ đệm cục bộ gần nhất, cảnh báo ở FR-03-026 và FR-03-054; token đã thu hồi sau lúc mất Valkey chỉ có hiệu lực chặn khi Valkey trở lại hoặc khi token hết hạn (tối đa 5 phút).
- Gọi API-03-053 không có scope `gateway:revoke`: ERR-03-022 (403).

**Đầu ra.** `202` cho API-03-053, thân `{revocationId, effectiveBy}`; ở data plane: `401` ERR-03-105.

**Kết quả.** Token đã thu hồi bị chặn trong tối đa 60 giây (thực tế dưới 15 giây: gọi API dưới 5 giây cộng bộ đệm 5 giây).

**Hậu điều kiện.** Có khóa trong Valkey và bản ghi DB tới khi token hết hạn.

**Sự kiện phát ra.** Không (EVT-03-09 chỉ khi có lượt gọi bằng token đã thu hồi lặp lại bất thường).

**Kiểm toán.** Có: người hoặc dịch vụ gọi, đối tượng bị chặn, lý do, thời điểm hiệu lực.

**Quy tắc nghiệp vụ.** BR-03-021; BR-03-025.

**Màn hình, API.** UI-03-05; API-03-053, API-03-054.
:::

```{.mermaid caption="Trình tự thu hồi token tới khi gateway chặn"}
sequenceDiagram
  autonumber
  participant KC as Keycloak và PH-12
  participant CP as dh-connect
  participant VK as Valkey
  participant AX as APISIX
  participant H as HTTT bị thu hồi
  KC->>CP: Vô hiệu client, đẩy jti hoặc sub, scope gateway:revoke
  CP->>CP: Lưu bản ghi revoked_token
  CP->>VK: Ghi khóa chặn, thời hạn bằng đời sống token
  H->>AX: Gọi API với token cũ
  AX->>VK: Tra khóa chặn, bộ đệm cục bộ 5 giây
  VK-->>AX: Có trong danh sách chặn
  AX-->>H: 401 ERR-03-105, token đã bị thu hồi
```

Hình cho thấy danh sách chặn nằm ở Valkey, thuộc data plane, nên việc chặn không phải chờ ảnh chụp cấu hình; `dh-connect` chỉ là trạm chuyển tiếp và giữ bản ghi dự phòng.

#### FR-03-019 · Ủy quyền chi tiết bằng OPA tại gateway

::: dac-ta
**Mục đích.** Để mọi lượt gọi API được quyết định cho phép hay từ chối theo vai trò, tenant, mức phân loại dữ liệu và mục đích khai thác bằng chính sách tập trung của PH-12, ngay tại gateway, không phụ thuộc từng backend tự làm (SEC-26).

**Tác nhân, quyền.** Hệ thống (tự chạy); PH-12 viết, ký và phát gói chính sách; xem liên kết route và gói chính sách `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-09, REQ-12; LGC-BUS-041; SEC-26; ADR-006; NFR-03-002.

**Tiền điều kiện.** OPA sidecar trong pod APISIX đã nạp gói chính sách ký và đã lưu bền (`persist`); mỗi route có `policyPackage` (BR-03-014).

**Kích hoạt.** Sau khi qua hạn mức (chốt 8), trước khi định tuyến.

**Đầu vào.** `input` gửi OPA: `tenant`, `consumer`, `client`, `scopes`, `method`, `path` (đã chuẩn hóa), `routeCode`, `apiClassification` (mức phân loại), `purpose` (nếu API yêu cầu), `certBound`; không gồm thân yêu cầu.

**Luồng xử lý chính.**

1. Plugin `opa` dựng `input` từ ngữ cảnh đã xác thực (không lấy từ tiêu đề của khách).
2. Plugin gọi OPA cục bộ trong pod với thời hạn chờ 50 ms (giả định, cơ sở: p99 quyết định ≤ 2 ms theo SEC-26 cộng dư gấp 25 lần).
3. OPA trả `allow` hoặc `deny` kèm `reason` mã hóa (ví dụ `purpose_required`); mặc định `allow := false` (SEC-26).
4. `allow` thì cho đi tiếp, và có thể kèm `obligations` (ví dụ danh sách trường cần che) đặt vào tiêu đề nội bộ `X-DH-Obligations` cho backend.
5. `deny` thì dừng: ERR-03-112; nhật ký quyết định (decision log) ghi đã che dữ liệu, gửi Loki qua PH-13.
6. Ghi chỉ số `dh_gateway_opa_duration_seconds`, `dh_gateway_opa_decision_total{result}`.

**Luồng thay thế.** Route công khai dữ liệu mở có chính sách `allow-open-data`: OPA vẫn được gọi (để có nhật ký) nhưng chính sách chỉ kiểm tra tenant và phương thức `GET`.

**Luồng ngoại lệ.**

- OPA từ chối: ERR-03-112 (403), "Yêu cầu không được phép theo chính sách truy cập. {lý do}. Liên hệ chủ quản dữ liệu nếu cần cấp quyền."
- OPA không phản hồi trong 50 ms hoặc chưa có gói chính sách: đóng an toàn, ERR-03-124 (503), "Dịch vụ ủy quyền tạm thời không khả dụng. Thử lại sau." Cảnh báo Nghiêm trọng ở FR-03-054.

**Đầu ra.** Cho đi tiếp kèm `X-DH-Obligations` (nếu có), hoặc `403`, `503`.

**Kết quả.** Mọi lượt gọi đều có quyết định cho phép hay từ chối có nhật ký; backend không nhận lượt gọi bị chính sách từ chối.

**Hậu điều kiện.** Có bản ghi quyết định ở Loki; không đổi dữ liệu khác.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có (nhật ký quyết định OPA, SEC-61): đầu vào đã che, quyết định, phiên bản gói chính sách, `traceId`.

**Quy tắc nghiệp vụ.** BR-03-008; BR-03-014; BR-03-023.

**Màn hình, API.** UI-03-03; API-03-055.
:::

#### FR-03-020 · Danh sách cho phép và chặn đường dẫn

::: dac-ta
**Mục đích.** Thực thi bước Restriction của gói sử dụng ở hệ cũ: cho phép một HTTT chỉ gọi một số đường dẫn của API, hoặc chặn một số đường dẫn (ví dụ `/admin`) với mọi HTTT hoặc một nhóm.

**Tác nhân, quyền.** Hệ thống (tự chạy); quản trị gói ở PH-02; PA, TA xem (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-014; ADR-005.

**Tiền điều kiện.** Gói của đăng ký có `pathAllow[]`, `pathDeny[]` (mẫu đường dẫn); route sinh ra gồm các mẫu này.

**Kích hoạt.** Sau FR-03-016, khi có chính sách của gói trong ngữ cảnh.

**Đầu vào.** Đường dẫn đã chuẩn hóa của yêu cầu (giải mã phần trăm một lần, xóa `//`, `.`, `..`); phương thức; `pathAllow[]`, `pathDeny[]` của gói; danh sách chặn toàn tenant của route.

**Luồng xử lý chính.**

1. Plugin `dh-path-acl` chuẩn hóa đường dẫn (chống vượt đường dẫn bằng mã hóa kép hoặc `..`).
2. Plugin kiểm tra danh sách chặn: khớp mẫu nào trong `pathDeny` thì dừng (ERR-03-113); danh sách chặn có ưu tiên cao hơn danh sách cho phép.
3. Nếu `pathAllow` không rỗng, đường dẫn phải khớp ít nhất một mẫu; không khớp thì ERR-03-113.
4. `pathAllow` rỗng nghĩa là mọi đường dẫn của route được phép.
5. Khớp thì cho đi tiếp; ghi chỉ số `dh_gateway_path_denied_total`.

**Luồng thay thế.** Chặn một đường dẫn cho mọi HTTT ở mọi route của tenant (`uri-blocker` mức tenant): PA, TA khai ở mẫu chính sách (FR-03-048).

**Luồng ngoại lệ.**

- Đường dẫn bị chặn hoặc không nằm trong danh sách cho phép: ERR-03-113 (403), "Đường dẫn này không nằm trong phạm vi gói sử dụng của HTTT của bạn."
- Mẫu đường dẫn sai cú pháp ở cấu hình: bị chặn ở FR-03-040, ERR-03-005.

**Đầu ra.** Cho đi tiếp, hoặc `403` ERR-03-113.

**Kết quả.** HTTT chỉ gọi đúng các đường dẫn của gói; đường quản trị không lộ ra qua API công bố.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với từng lượt; thay đổi gói do PH-02 ghi.

**Quy tắc nghiệp vụ.** BR-03-014; BR-03-017.

**Màn hình, API.** UI-03-03, UI-03-13; API-03-021, API-03-022, API-03-065.
:::

### 6.4. Nhóm C · Hạn mức và hạn ngạch

Nhóm C bảo vệ hệ thống khỏi bị dùng quá mức và bảo vệ tenant này khỏi tenant khác. Có bốn tầng, mỗi tầng một câu hỏi khác nhau: bên gọi này đang gọi nhanh quá không (tần suất, FR-03-021), đã dùng hết phần của chu kỳ chưa (hạn ngạch, FR-03-022), cả tỉnh có đang chiếm quá phần của mình không (FR-03-023), và route này có đang bị gọi quá mức chung không (FR-03-024). Một lượt gọi phải qua mọi tầng khớp với nó. Hình dưới là quan hệ giữa các chức năng.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm C"}
flowchart TB
  F021["FR-03-021 Tần suất theo bên gọi"] --> F025["FR-03-025 Phản hồi 429,<br/>tiêu đề hạn mức"]
  F022["FR-03-022 Hạn ngạch chu kỳ"] --> F025
  F023["FR-03-023 Hạn mức tenant"] --> F025
  F024["FR-03-024 Hạn mức theo route,<br/>thứ tự ưu tiên"] --> F025
  F026["FR-03-026 Valkey mất"] -.-> F021
  F026 -.-> F022
  F026 -.-> F023
  F027["FR-03-027 Điều tiết theo backend"] -.-> F021
  F030["FR-03-030 Sức khỏe backend (nhóm D)"] -.-> F027
```

#### FR-03-021 · Giới hạn tần suất theo bên gọi

::: dac-ta
**Mục đích.** Giữ nguyên bước Restriction "rate limit" của hệ cũ: mỗi HTTT chỉ được gọi một API với tần suất đã khai trong gói (theo giây và theo phút), để một HTTT lỗi hoặc lạm dụng không làm quá tải backend và các HTTT khác (BR-03-005).

**Tác nhân, quyền.** Hệ thống (tự chạy); PH-02 là nguồn gói; PA, TA xem (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-012; LGC-NFR-006; CMP-LAW-09; SEC-10; ADR-005.

**Tiền điều kiện.** Consumer và đăng ký đã được nhận diện (FR-03-016); gói có `rateLimits[]`; Valkey truy cập được (nếu không, FR-03-026).

**Kích hoạt.** Mỗi lượt gọi tới route sau khi qua đăng ký sử dụng.

**Đầu vào.** `consumerCode`; `routeCode`; `rateLimits[]` gồm `windowSeconds`, `limit`, `burst`; ví dụ gói chuẩn: 20 lượt/giây và 600 lượt/60 giây.

**Luồng xử lý chính.**

1. Plugin `limit-count` dựng khóa `{tenant}:rl:{consumerCode}:{routeCode}:{windowSeconds}` và tăng bộ đếm ở Valkey bằng một lệnh nguyên tử (một vòng đi về).
2. Plugin dùng cửa sổ trượt để tránh đột biến ở ranh giới cửa sổ cố định (giả định APISIX 3.x có chế độ cửa sổ trượt, cần xác minh ở Q03-06; nếu không có thì dùng cửa sổ cố định kèm `limit-req` làm mượt).
3. Dung sai `burst` cho phép vượt ngắn trong giới hạn; vượt `limit + burst` thì từ chối (ERR-03-116).
4. Mỗi cửa sổ khai trong gói được kiểm riêng; bị từ chối ở một cửa sổ là bị từ chối.
5. Còn hạn mức thì cho đi tiếp, đặt `X-RateLimit-*` (FR-03-025).
6. Ghi chỉ số `dh_gateway_ratelimit_rejected_total{route,consumer}` (nhãn `consumer` là mã HTTT, không phải IP).

**Luồng thay thế.** Consumer thuộc nhóm `ESSENTIAL` có hệ số nới `gw.rate.essentialFactor` (mặc định 1,5) áp cho tần suất, để dịch vụ công thiết yếu không bị chặn trước khi hệ thống kịp điều tiết các nhóm khác.

**Luồng ngoại lệ.**

- Vượt tần suất: ERR-03-116 (429) kèm `Retry-After`, "HTTT {mã} đã dùng hết {n} lượt trong {w} giây cho API {mã API}. Thử lại sau {s} giây."
- Valkey không khả dụng: chuyển sang đếm cục bộ theo FR-03-026, không từ chối lượt gọi vì lý do này.

**Đầu ra.** Cho đi tiếp kèm `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; hoặc `429` ERR-03-116.

**Kết quả.** Mỗi HTTT bị giới hạn công bằng theo gói; hạn mức tính theo HTTT nên hai HTTT cùng địa chỉ sau NAT không ảnh hưởng nhau (BR-03-005).

**Hậu điều kiện.** Bộ đếm ở Valkey tự hết hạn theo cửa sổ; không ghi CSDL.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với từng lượt (có chỉ số và nhật ký lượt gọi); có khi đổi gói (PH-02).

**Quy tắc nghiệp vụ.** BR-03-005; BR-03-009; BR-03-024.

**Màn hình, API.** UI-03-06; API-03-021, API-03-022, API-03-029.
:::

#### FR-03-022 · Hạn ngạch theo chu kỳ và cảnh báo ngưỡng

::: dac-ta
**Mục đích.** Giữ nguyên bước Restriction "quota" của hệ cũ: giới hạn tổng số lượt gọi theo giờ, ngày, tháng của một HTTT với một API, và cảnh báo chủ HTTT khi dùng gần hết, để bảo vệ hệ thống và có số liệu sử dụng. Hạn ngạch không dùng để tính tiền (BR-03-020).

**Tác nhân, quyền.** Hệ thống (tự chạy); TA, chủ dịch vụ nhận cảnh báo; xem mức dùng `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-013; CMP-LAW-03; BR-03-020.

**Tiền điều kiện.** Gói có `quotas[]` (chu kỳ `HOUR`, `DAY`, `MONTH`, số lượt); Valkey truy cập được.

**Kích hoạt.** Mỗi lượt gọi, sau chốt tần suất; và tác vụ định kỳ 5 phút của `dh-connect` đọc mức dùng để cảnh báo.

**Đầu vào.** `quotas[]` gồm `period`, `limit`; múi giờ `Asia/Ho_Chi_Minh` để xác định ranh giới chu kỳ; `gw.quota.warnPercent` (80).

**Luồng xử lý chính.**

1. Plugin dựng khóa theo chu kỳ lịch `{tenant}:quota:{consumerCode}:{routeCode}:{period}:{bucket}` (ví dụ bucket ngày `20261126`) và tăng bộ đếm.
2. Bộ đếm vượt `limit` thì từ chối (ERR-03-117) và kèm thời điểm đặt lại chu kỳ.
3. Consumer thuộc nhóm `ESSENTIAL` vượt hạn ngạch thì được cho qua kèm cảnh báo thay vì chặn (BR-03-009), mức vượt tối đa `gw.quota.essentialOverrunPercent` (mặc định 20%) rồi mới chặn.
4. Mỗi 5 phút `dh-connect` đọc bộ đếm của các consumer có hạn ngạch, so với 80% và 100%.
5. Lần đầu đạt 80% trong chu kỳ, hệ thống phát EVT-03-07 và thông báo cho đầu mối HTTT (FR-00-060) và TA; đạt 100% thì phát lại một lần.
6. Chu kỳ mới bắt đầu, khóa mới được tạo; khóa cũ tự hết hạn sau chu kỳ cộng 1 ngày để phục vụ báo cáo (FR-03-058).

**Luồng thay thế.** Đối tác thanh toán hoặc HTTT có thỏa thuận riêng: PH-02 cấp gói riêng với hạn ngạch cao; gateway không có logic riêng.

**Luồng ngoại lệ.**

- Vượt hạn ngạch: ERR-03-117 (429) kèm `Retry-After` và `X-Quota-Reset`, "HTTT {mã} đã dùng hết hạn ngạch {n} lượt/{ngày|tháng|giờ} cho API {mã API}. Hạn ngạch đặt lại lúc {thời điểm}."
- Valkey không khả dụng: hạn ngạch mở có cảnh báo (FR-03-026), không chặn lượt gọi vì lý do này.

**Đầu ra.** Cho đi tiếp kèm `X-Quota-Remaining`; hoặc `429` ERR-03-117.

**Kết quả.** HTTT biết trước khi sắp hết hạn ngạch; hệ thống không bị lạm dụng theo thời gian dài; dịch vụ thiết yếu không bị gián đoạn đột ngột.

**Hậu điều kiện.** Bộ đếm theo chu kỳ ở Valkey; bản tổng hợp theo ngày được PH-13 giữ từ siêu dữ liệu lượt gọi.

**Sự kiện phát ra.** EVT-03-07.

**Kiểm toán.** Không với từng lượt; sự kiện đạt ngưỡng được ghi ở nhật ký vận hành.

**Quy tắc nghiệp vụ.** BR-03-009; BR-03-020.

**Màn hình, API.** UI-03-05, UI-03-06; API-03-029, API-03-030.
:::

#### FR-03-023 · Hạn mức toàn tenant

::: dac-ta
**Mục đích.** Bảo đảm một tỉnh không chiếm hết năng lực gateway dùng chung (vấn đề hàng xóm ồn ào): tổng lượt gọi mỗi giây của cả tenant không vượt hạn mức theo hợp đồng, mặc định 500 lượt/giây (D03-10 §5.3).

**Tác nhân, quyền.** PA đặt trần theo hợp đồng; TA chỉnh trong trần (`PERM-03-limit`); TA, SO khác người duyệt khi hạ hạn mức (`PERM-03-approve`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-20; SEC-86; D03-10 §5.3; NFR-03-019.

**Tiền điều kiện.** Hạn mức hợp đồng của tenant có ở PH-20 và được PH-03 nhận khi khởi tạo tenant; Valkey truy cập được.

**Kích hoạt.** Mỗi lượt gọi của tenant; và khi quản trị đổi hạn mức.

**Đầu vào.** `limitPerSecond` (T-INT, 10…ceiling), `burst`, `warnPercent` (80), trần `ceiling` do hợp đồng.

**Luồng xử lý chính.**

1. Plugin `limit-count` dựng khóa `{tenant}:tl` và tăng bộ đếm cửa sổ 1 giây ở Valkey cho mọi lượt gọi đã xác định tenant (FR-03-013).
2. Vượt `limitPerSecond + burst` thì từ chối (ERR-03-118).
3. Đạt 80% hạn mức tenant liên tục 1 phút thì phát EVT-03-07 loại `TENANT_LIMIT` và cảnh báo ở FR-03-054.
4. Quản trị đổi hạn mức: hệ thống kiểm tra không vượt trần hợp đồng (vượt: ERR-03-018); nếu hạ thấp so với hiện tại thì tạo yêu cầu thay đổi chờ người thứ hai duyệt (ERR-03-008 nếu tự duyệt).
5. Được duyệt thì phát ảnh chụp mới (FR-03-039…042) và EVT-03-11.
6. Kiểm thử tải hằng tuần ở môi trường thử chứng minh một tenant vượt hạn mức không làm tăng p95 của tenant khác quá 10% (NFR-03-019).

**Luồng thay thế.** Tăng hạn mức tạm thời cho sự kiện cao điểm (ví dụ ngày nộp hồ sơ): TA đặt giá trị cao hơn có hạn dùng `validTo`, trong trần hợp đồng; hết hạn tự về mức cũ.

**Luồng ngoại lệ.**

- Vượt hạn mức tenant: ERR-03-118 (429) kèm `Retry-After: 1`, "Tỉnh {tenant} đang vượt hạn mức {n} lượt/giây của nền tảng. Thử lại sau giây lát."
- Đặt vượt trần hợp đồng hoặc dưới mức tối thiểu 10: ERR-03-018 (422), "Hạn mức phải từ 10 đến {trần} lượt/giây theo hợp đồng của tỉnh."
- Người hạ hạn mức tự duyệt: ERR-03-008 (403).

**Đầu ra.** `200` với hạn mức hiệu lực `{limitPerSecond, burst, validTo, ceiling}` hoặc `202` khi chờ duyệt; ở data plane: `429` ERR-03-118.

**Kết quả.** Mỗi tenant dùng trong phần của mình; cảnh báo sớm khi một tỉnh sắp chạm trần để hai bên cùng bàn mở rộng.

**Hậu điều kiện.** Hạn mức mới trong ảnh chụp đang chạy; bản ghi yêu cầu thay đổi (nếu hạ).

**Sự kiện phát ra.** EVT-03-11 (hạn mức đổi); EVT-03-07 (sắp chạm).

**Kiểm toán.** Có: người đổi, người duyệt, giá trị trước và sau, `validTo`, lý do.

**Quy tắc nghiệp vụ.** BR-03-019; BR-03-005.

**Màn hình, API.** UI-03-06, UI-03-17; API-03-023, API-03-024, API-03-071, API-03-072, API-03-073.
:::

#### FR-03-024 · Hạn mức theo route và thứ tự ưu tiên chính sách

::: dac-ta
**Mục đích.** Cho quản trị đặt thêm hạn mức riêng ngoài gói, theo route chung cho mọi HTTT hoặc theo cặp HTTT với route (ví dụ giảm tạm một HTTT đang gọi quá mức), và quy định rõ khi nhiều chính sách cùng khớp thì áp dụng thế nào.

**Tác nhân, quyền.** TA, PA (`PERM-03-limit`); xem `PERM-03-read`.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03; LGC-APIM-012; LGC-APIM-013; SRS cũ (FR số 008, hạn mức nhiều tầng).

**Tiền điều kiện.** Route và consumer tồn tại; hạn mức hợp đồng tenant (FR-03-023) đã có.

**Kích hoạt.** Quản trị bấm "Thêm hạn mức" ở UI-03-06.

**Đầu vào.** Theo bảng "Dữ liệu vào của FR-03-024" dưới đây.

**Luồng xử lý chính.**

1. Quản trị chọn phạm vi (`CONSUMER_ROUTE`, `ROUTE` hoặc `CONSUMER`), đối tượng, giới hạn, cửa sổ, dung sai và thời hạn.
2. Hệ thống kiểm tra mức không vượt hạn mức tenant (FR-03-023) cho phạm vi `ROUTE` và `CONSUMER`; vi phạm: ERR-03-018.
3. Hệ thống cảnh báo nếu giới hạn thấp hơn lưu lượng trung bình 7 ngày của đối tượng (đọc từ PH-13) và yêu cầu xác nhận; đối tượng thuộc nhóm `ESSENTIAL` thì cảnh báo mạnh hơn.
4. Hệ thống lưu EN-03-06 và phát ảnh chụp mới.
5. Ở gateway, một lượt gọi phải qua **mọi** hạn mức khớp: trần tenant (FR-03-023), trần route chung (`ROUTE`), và hạn mức của cặp consumer–route. Với cặp consumer–route, hạn mức `CONSUMER_ROUTE` do quản trị đặt thay thế giá trị của gói; nếu không có thì dùng giá trị của gói.
6. Thứ tự đánh giá từ cụ thể đến chung: `CONSUMER_ROUTE` rồi `ROUTE` rồi `TENANT`; từ chối ở bất kỳ tầng nào là từ chối, mã lỗi phản ánh tầng đã từ chối (ERR-03-116, 118).

**Luồng thay thế.** Đặt hạn mức có thời hạn (ví dụ 3 ngày xử lý sự cố): hết hạn thì tự gỡ ở ảnh chụp kế tiếp.

**Luồng ngoại lệ.**

- Vượt trần hoặc sai miền: ERR-03-018 (422), "Hạn mức phải nằm trong trần của tỉnh ({trần} lượt/giây)."
- Đối tượng không tồn tại hoặc thuộc tenant khác: ERR-03-001 (404), "Không tìm thấy route hoặc HTTT {mã}."

**Đầu ra.** `201`, chi tiết `{overrideId, scope, limit, windowSeconds, burst, validTo}`.

**Kết quả.** Quản trị điều chỉnh nhanh hạn mức khi sự cố mà không phải sửa gói ở PH-02; thứ tự áp dụng rõ ràng, kiểm thử được.

**Hậu điều kiện.** EN-03-06 mới; ảnh chụp mới có hạn mức.

**Sự kiện phát ra.** EVT-03-11.

**Kiểm toán.** Có: người đặt, phạm vi, đối tượng, giá trị trước và sau, lý do, hạn.

**Quy tắc nghiệp vụ.** BR-03-005; BR-03-019.

**Màn hình, API.** UI-03-06; API-03-025, API-03-026, API-03-027, API-03-028.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `scope` | T-ENUM | Có | `CONSUMER_ROUTE`, `ROUTE`, `CONSUMER` | `CONSUMER_ROUTE` |
| `consumerCode` | T-CODE | Khi scope có consumer | Consumer của tenant | `ht-qlvb` |
| `routeCode` | T-CODE | Khi scope có route | Route `ACTIVE` của tenant | `tra-cuu-ho-tich.v1` |
| `limit` | T-INT | Có | 1…`gw.tenantRateLimit` | 100 |
| `windowSeconds` | T-INT | Có | 1, 60, 3.600 | 60 |
| `burst` | T-INT | Không | 0…`limit` | 10 |
| `validTo` | T-TS | Không | Sau hiện tại, tối đa 365 ngày | `2026-12-31T23:59:59+07:00` |
| `reason` | T-TEXT | Có | 10…500 ký tự | "Giảm tạm do HT-QLVB gọi lặp lỗi" |

: Dữ liệu vào của FR-03-024

#### FR-03-025 · Phản hồi vượt hạn mức và tiêu đề hạn mức

::: dac-ta
**Mục đích.** Giúp bên gọi tự điều chỉnh: biết còn bao nhiêu lượt, khi nào đặt lại, nên chờ bao lâu, và phân biệt bị từ chối vì tần suất, hạn ngạch, hạn mức tỉnh hay địa chỉ nguồn.

**Tác nhân, quyền.** HTTT gọi API (nhận phản hồi); không có thao tác quản trị riêng.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; CMP-LAW-09; SEC-10; RFC 9457; BR-03-023, BR-03-024.

**Tiền điều kiện.** Route có ít nhất một hạn mức hoặc hạn ngạch áp dụng.

**Kích hoạt.** Mỗi phản hồi của route có hạn mức, thành công hoặc bị từ chối.

**Đầu vào.** Kết quả tất cả các hạn mức khớp ở FR-03-003, 021, 022, 023, 024.

**Luồng xử lý chính.**

1. Gateway lấy hạn mức **chặt nhất** (còn lại ít nhất theo tỉ lệ) trong các hạn mức khớp để báo.
2. Trên mọi phản hồi, kể cả thành công, gateway đặt `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (giây Unix) theo hạn mức chặt nhất; có hạn ngạch thì thêm `X-Quota-Remaining`.
3. Khi từ chối, gateway trả `429` với thân RFC 9457 mang `code` đúng tầng (ERR-03-116 tần suất, 117 hạn ngạch, 118 tenant, 119 địa chỉ nguồn), `retryAfterSeconds`, `limit`, `windowSeconds`.
4. Gateway đặt `Retry-After` bằng số giây tới khi hạn mức đặt lại (làm tròn lên, tối thiểu 1).
5. Gateway luôn kèm `X-Trace-Id` (FR-03-032).
6. Phản hồi `429` không kèm thông tin nội bộ nào của tenant khác.

**Luồng thay thế.** Route không có hạn mức: không có tiêu đề `X-RateLimit-*`.

**Luồng ngoại lệ.**

- Không tính được `Remaining` vì Valkey mất: bỏ tiêu đề `X-RateLimit-Remaining`, giữ `Limit` và đặt `X-RateLimit-Degraded: true` (FR-03-026).

**Đầu ra.** Tiêu đề hạn mức trên phản hồi; `429` ERR-03-116…119 khi từ chối.

**Kết quả.** HTTT thấy ngay mình ở đâu so với hạn mức và chờ đúng thời gian, giảm số lần thử lại vô ích.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-024; BR-03-023.

**Màn hình, API.** Không có màn hình riêng; API-03-025 (đọc ghi đè hạn mức đang hiệu lực).
:::

#### FR-03-026 · Suy giảm có kiểm soát khi Valkey mất

::: dac-ta
**Mục đích.** Bảo đảm sự cố Valkey chỉ làm hạn mức kém chính xác chứ không làm ngừng data plane: mất Valkey thì hạn mức mở có cảnh báo, giới hạn cục bộ vẫn chạy (D03-09 §6.1).

**Tác nhân, quyền.** Hệ thống (tự chạy); PO, PA nhận cảnh báo.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; NFR-00-012; D03-09 §6.1; BR-03-025; NFR-03-007.

**Tiền điều kiện.** Plugin `limit-count` cấu hình cho phép suy giảm; plugin `limit-req` cục bộ có trong chuỗi chốt.

**Kích hoạt.** Lệnh tới Valkey quá 50 ms hoặc lỗi kết nối.

**Đầu vào.** Trạng thái kết nối Valkey; số bản sao APISIX đang chạy (lấy từ `EndpointSlice` hoặc từ giá trị cấu hình khi không đọc được); `gw.degrade.localDivisorMode` (mặc định `REPLICAS`).

**Luồng xử lý chính.**

1. Plugin phát hiện Valkey lỗi hoặc chậm và chuyển nút sang chế độ suy giảm, không chờ thêm cho các lượt kế tiếp (ngắt mạch phía Valkey 5 giây rồi thử lại).
2. Tần suất theo giây và phút (FR-03-021) và hạn mức tenant (FR-03-023) chuyển sang đếm cục bộ từng nút với giới hạn bằng giới hạn gốc chia cho số bản sao đang chạy (làm tròn lên), để tổng thể gần đúng giới hạn thật.
3. Hạn ngạch theo giờ, ngày, tháng (FR-03-022) mở: lượt gọi được cho qua, không đếm; thông tin sử dụng chỉ còn từ siêu dữ liệu lượt gọi.
4. Phản hồi mang `X-RateLimit-Degraded: true` (FR-03-025).
5. Hệ thống phát cảnh báo Nghiêm trọng (FR-03-054) và ghi chỉ số `dh_gateway_valkey_up = 0`.
6. Khi Valkey trở lại, nút quay về chế độ thường; bộ đếm theo chu kỳ bắt đầu lại từ 0 (chấp nhận sai lệch trong chu kỳ đang chạy) và `dh-connect` nạp lại danh sách chặn token (FR-03-018).

**Luồng thay thế.** Ở hồ sơ `QM-NHO` có một bản sao APISIX duy nhất, giới hạn cục bộ chính là giới hạn gốc.

**Luồng ngoại lệ.**

- Valkey chậm nhưng không mất: giữ chế độ thường, tăng chỉ số `dh_gateway_valkey_latency_seconds` và cảnh báo Cao khi p99 vượt 20 ms.
- Chế độ suy giảm kéo dài trên 15 phút: cảnh báo leo thang, đề nghị PA xem xét tăng bản sao Valkey.

**Đầu ra.** Lượt gọi tiếp tục được phục vụ; tiêu đề `X-RateLimit-Degraded`.

**Kết quả.** Gateway không dừng vì Valkey; đội vận hành biết hạn mức đang kém chính xác.

**Hậu điều kiện.** Bộ đếm có thể sai lệch trong chu kỳ đang chạy; không mất dữ liệu cấu hình.

**Sự kiện phát ra.** EVT-03-09 (cảnh báo an ninh vận hành) khi bắt đầu và kết thúc suy giảm.

**Kiểm toán.** Không (sự kiện vận hành).

**Quy tắc nghiệp vụ.** BR-03-025.

**Màn hình, API.** UI-03-01; API-03-077.
:::

```{.mermaid caption="Trình tự gateway suy giảm khi Valkey mất"}
sequenceDiagram
  autonumber
  participant H as HTTT gọi
  participant AX as APISIX
  participant VK as Valkey
  participant OB as PH-13
  H->>AX: Gọi API
  AX->>VK: Tăng bộ đếm, hạn chờ 50 ms
  VK--xAX: Lỗi hoặc quá hạn
  AX->>AX: Bật suy giảm, đếm cục bộ theo số bản sao
  AX-->>H: Phản hồi kèm X-RateLimit-Degraded true
  AX-)OB: dh_gateway_valkey_up bằng 0, cảnh báo Nghiêm trọng
  Note over AX,VK: Sau 5 giây thử lại, Valkey trở lại thì thoát suy giảm
```

Hình cho thấy lượt gọi không bị từ chối vì Valkey; chỉ độ chính xác của hạn mức giảm và có cảnh báo.

#### FR-03-027 · Điều tiết theo tình trạng backend

::: dac-ta
**Mục đích.** Khi backend của một route quá tải, chủ động giảm lưu lượng của các HTTT ưu tiên thấp để giữ dịch vụ cho HTTT thiết yếu, thay vì để mọi lượt gọi cùng hết thời hạn.

**Tác nhân, quyền.** Hệ thống (tự chạy); TA, TO xem hệ số điều tiết (`PERM-03-read`); TA đặt nhóm ưu tiên của consumer (`PERM-03-limit`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03; SRS cũ (FR số 010); BR-03-009; LGC-NFR-006.

**Tiền điều kiện.** Consumer có `priorityGroup` ∈ {`ESSENTIAL`, `NORMAL`, `LOW`} (mặc định `NORMAL`); chỉ số sức khỏe backend có sẵn từ FR-03-030.

**Kích hoạt.** Tỉ lệ lỗi hoặc độ trễ của upstream vượt ngưỡng trong 1 phút.

**Đầu vào.** Tỉ lệ lỗi (5xx và quá hạn) và độ trễ p95 của upstream trong cửa sổ 1 phút; ngưỡng `gw.throttle.errorRatePercent` (20) và `gw.throttle.latencyFactor` (3 lần độ trễ nền 24 giờ).

**Luồng xử lý chính.**

1. Plugin `dh-adaptive-throttle` ở mỗi nút tính tỉ lệ lỗi và độ trễ p95 của từng upstream trong 1 phút.
2. Vượt ngưỡng lần đầu: nhân hạn mức tần suất của nhóm `LOW` với hệ số 0,5.
3. Còn vượt sau 1 phút nữa: nhóm `NORMAL` nhân 0,75 và nhóm `LOW` nhân 0,25; nhóm `ESSENTIAL` giữ nguyên.
4. Khi backend ổn định (dưới ngưỡng) 2 phút liên tục, hệ số tăng dần mỗi 30 giây thêm 0,1 cho tới 1,0.
5. Lượt gọi bị giảm hạn mức nhận ERR-03-116 kèm tiêu đề `X-DH-Throttled: true` để bên gọi biết là điều tiết chứ không phải hết gói.
6. Hệ thống ghi chỉ số `dh_gateway_throttle_factor{route,group}` và hiển thị ở UI-03-06.

**Luồng thay thế.** Backend không phản hồi hoàn toàn: bỏ qua điều tiết, chuyển sang ngắt mạch trả lỗi nhanh (FR-03-031).

**Luồng ngoại lệ.**

- Bị điều tiết: ERR-03-116 (429), "Dịch vụ {mã API} đang quá tải nên hạn mức của HTTT bạn tạm giảm. Thử lại sau {s} giây."
- Không có đủ mẫu đo (dưới 30 lượt trong 1 phút): không điều tiết để tránh quyết định theo ít dữ liệu.

**Đầu ra.** Hạn mức hiệu lực thay đổi theo thời gian; tiêu đề `X-DH-Throttled`.

**Kết quả.** HTTT thiết yếu vẫn được phục vụ khi backend yếu; hạn mức tự hồi phục khi backend ổn định.

**Hậu điều kiện.** Hệ số điều tiết ở bộ nhớ nút, không lưu.

**Sự kiện phát ra.** EVT-03-09 khi bắt đầu điều tiết một route.

**Kiểm toán.** Không (chỉ số và sự kiện vận hành).

**Quy tắc nghiệp vụ.** BR-03-009.

**Màn hình, API.** UI-03-06; API-03-029.
:::

### 6.5. Nhóm D · Định tuyến và chuyển tiếp

Nhóm D đưa lượt gọi đã qua mọi chốt tới đúng backend khỏe mạnh, giữ cho lượt gọi truy vết được từ đầu tới cuối, và cho quản trị dừng, chuyển hoặc đổi cửa của route một cách có kiểm soát. Hình dưới là quan hệ giữa các chức năng.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm D"}
flowchart TB
  F038["FR-03-038 Phân cửa vào"] --> F028["FR-03-028 Định tuyến"]
  F037["FR-03-037 Chuyển tiếp tenant sáp nhập"] --> F028
  F035["FR-03-035 Phiên bản song song"] --> F028
  F036["FR-03-036 Dừng, mở API"] --> F028
  F028 --> F029["FR-03-029 Cân bằng tải"]
  F029 --> F030["FR-03-030 Kiểm tra sức khỏe"]
  F030 --> F031["FR-03-031 Thời hạn chờ,<br/>ngắt mạch"]
  F028 --> F032["FR-03-032 Truy vết"]
  F028 --> F033["FR-03-033 WebSocket, nén"]
  F028 --> F034["FR-03-034 gRPC và REST"]
```

#### FR-03-028 · Định tuyến theo host, đường dẫn, phương thức

::: dac-ta
**Mục đích.** Chuyển lượt gọi tới đúng route (và nhờ đó đúng backend, đúng chính sách) theo host hoặc tiền tố tenant, đường dẫn và phương thức, đồng thời bảo đảm route của tenant này không bao giờ khớp lượt gọi của tenant khác.

**Tác nhân, quyền.** Hệ thống (tự chạy); xem danh sách route `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-017; ADR-005; D03-10 §4; BR-03-026.

**Tiền điều kiện.** Route ở trạng thái `ACTIVE` trong ảnh chụp đang chạy; mỗi route có `hostPattern`, `pathPattern`, `methods[]`, `priority`.

**Kích hoạt.** Mỗi yêu cầu qua các chốt trước.

**Đầu vào.** Host (SNI và `Host`), đường dẫn, phương thức; danh sách route của cửa vào đó.

**Luồng xử lý chính.**

1. APISIX chọn nhóm route theo host (mỗi tenant một host, hoặc host chung kèm tiền tố đường dẫn theo tenant, theo cấu hình của hồ sơ triển khai).
2. APISIX so khớp theo thứ tự ưu tiên: đường dẫn chính xác, rồi tiền tố dài nhất, rồi mẫu có tham số; cùng mức thì `priority` cao hơn thắng.
3. Phương thức không có trong `methods[]` của route khớp đường dẫn: ERR-03-114 (hoặc `405` khi đường dẫn khớp nhưng phương thức sai, kèm `Allow`).
4. Route được chọn nạp chuỗi plugin của nó; plugin `proxy-rewrite` bỏ tiền tố tenant khỏi đường dẫn gửi backend nếu có.
5. Không route nào khớp: ERR-03-114.
6. Cấu hình bảo đảm không có hai route của hai tenant khác nhau cùng host và đường dẫn (kiểm tra ở FR-03-040, BR-03-026).

**Luồng thay thế.** Route dùng chung `COMMON` (ví dụ danh mục dùng chung quốc gia) có host riêng không gắn tenant; tenant lấy từ token (FR-03-013).

**Luồng ngoại lệ.**

- Không route khớp hoặc host không thuộc tenant nào: ERR-03-114 (404), "Không tìm thấy dịch vụ hoặc đường dẫn."
- Phương thức không được phép: `405` kèm `Allow`, cùng mã ERR-03-114 và thông điệp "Phương thức không được phép cho đường dẫn này."
- Route `PENDING`: như không tồn tại (ERR-03-114).

**Đầu ra.** Yêu cầu chuyển cho FR-03-029; hoặc `404`, `405`.

**Kết quả.** Mỗi lượt gọi đi đúng route; route của tenant khác không bao giờ khớp (kiểm thử rò rỉ chéo tenant).

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-026; BR-03-001.

**Màn hình, API.** UI-03-02, UI-03-03; API-03-001, API-03-002.
:::

#### FR-03-029 · Cân bằng tải giữa các backend

::: dac-ta
**Mục đích.** Chia lượt gọi cho nhiều backend của cùng một dịch vụ theo trọng số, để dịch vụ chịu tải và bảo trì từng nút không gián đoạn.

**Tác nhân, quyền.** Hệ thống (tự chạy); PH-02 khai backend; xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-018; ADR-005.

**Tiền điều kiện.** Upstream có một hoặc nhiều nút (`address`, `port`, `weight`); ít nhất một nút khỏe mạnh (FR-03-030).

**Kích hoạt.** Sau khi chọn được route.

**Đầu vào.** `upstream.nodes[]`, `balancer` (`roundrobin` mặc định, `chash` theo khóa khi route cần dính phiên), `scheme` (`http`, `https`, `grpc`), `tlsVerify` (mặc định `true`), `retries`.

**Luồng xử lý chính.**

1. Gateway chọn nút khỏe theo thuật toán của upstream (vòng tròn có trọng số mặc định).
2. Với `chash`, khóa băm là `X-DH-Consumer` hoặc một tiêu đề khai báo; nút khỏe thay đổi thì băm nhất quán để giảm xáo trộn.
3. Gateway kết nối tới nút qua mTLS của mesh nếu backend trong cụm, hoặc TLS tới HTTT ngoài cụm qua egress gateway (SEC-16); xác minh chứng thư của backend khi `tlsVerify`.
4. Gateway thử lại sang nút khác tối đa `retries` lần (mặc định 1) chỉ cho phương thức an toàn lặp lại (`GET`, `HEAD`, `OPTIONS`) và lỗi kết nối chưa gửi thân (FR-03-031).
5. Gateway ghi nút đã dùng vào siêu dữ liệu lượt gọi (FR-03-050).

**Luồng thay thế.** Backend là một luồng của `dh-runtime` (PH-04) hoặc adapter quốc gia (PH-14): gateway xử lý như mọi backend khác; địa chỉ là service nội bộ của DU.

**Luồng ngoại lệ.**

- Không còn nút khỏe: ERR-03-120 (503), "Dịch vụ tạm thời không khả dụng. Thử lại sau {s} giây."
- Backend trả phản hồi không hợp lệ (đóng kết nối giữa chừng, không đúng giao thức): ERR-03-122 (502), "Dịch vụ phía sau trả về phản hồi không hợp lệ."

**Đầu ra.** Phản hồi của backend; hoặc `503`, `502`.

**Kết quả.** Lượt gọi được phân đều trên các backend khỏe; bảo trì từng nút không gây lỗi cho bên gọi.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-011; BR-03-001.

**Màn hình, API.** UI-03-03; API-03-005, API-03-006.
:::

#### FR-03-030 · Kiểm tra sức khỏe backend chủ động và thụ động

::: dac-ta
**Mục đích.** Chỉ chuyển lượt gọi tới backend khỏe: loại nút hỏng khỏi vòng và đưa lại khi hồi phục, bằng cả kiểm tra định kỳ (chủ động) và theo dõi lỗi thực tế (thụ động).

**Tác nhân, quyền.** Hệ thống (tự chạy); xem trạng thái `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-018; LGC-NFR-006; ADR-005; NFR-03-001.

**Tiền điều kiện.** Upstream khai báo kiểm tra sức khỏe: đường dẫn (mặc định `/readyz`), phương thức, mã trả về chấp nhận.

**Kích hoạt.** Bộ kiểm tra định kỳ mỗi `gw.upstream.healthcheck.intervalSeconds` (5); và mỗi phản hồi thực tế của nút.

**Đầu vào.** `healthCheck.active` (`path`, `intervalSeconds`, `timeoutMs`, `healthyStatuses[]`), `healthCheck.passive` (số lần lỗi liên tiếp, mã lỗi tính là thất bại), ngưỡng `failThreshold` (3), `successThreshold` (2).

**Luồng xử lý chính.**

1. APISIX gọi đường dẫn kiểm tra tới từng nút theo chu kỳ 5 giây.
2. Nút thất bại `failThreshold` lần liên tiếp (quá hạn, mã không chấp nhận) bị đánh dấu không khỏe và loại khỏi vòng.
3. Kiểm tra thụ động: nút trả 5xx hoặc lỗi kết nối quá `passive.failures` lần trong cửa sổ cũng bị loại.
4. Nút không khỏe tiếp tục được kiểm tra chủ động; đạt `successThreshold` lần liên tiếp (2) thì được đưa lại.
5. Trạng thái từng nút xuất thành chỉ số `dh_gateway_upstream_node_healthy{upstream,node}`.
6. Mọi nút của upstream không khỏe: xử lý theo FR-03-031 (ngắt mạch, ERR-03-120).

**Luồng thay thế.** Backend của HTTT ngoài không có `/readyz`: PA chọn kiểm tra TCP hoặc chỉ dùng kiểm tra thụ động.

**Luồng ngoại lệ.**

- Mọi nút không khỏe: ERR-03-120 (503) kèm `Retry-After: 5`, "Dịch vụ tạm thời không khả dụng. Thử lại sau 5 giây." Cảnh báo Cao ở FR-03-054.
- Bộ kiểm tra không tới được nút do mạng gateway bị chặn: nút bị coi không khỏe; cảnh báo cấu hình mạng.

**Đầu ra.** Danh sách nút khả dụng của mỗi upstream; chỉ số sức khỏe.

**Kết quả.** Nút hỏng bị loại trong tối đa 15 giây (3 lần × 5 giây) và lượt gọi chuyển sang nút còn lại không lỗi.

**Hậu điều kiện.** Trạng thái sức khỏe ở bộ nhớ từng nút; không lưu CSDL.

**Sự kiện phát ra.** Không (đi qua chỉ số tới PH-13).

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-011.

**Màn hình, API.** UI-03-03; API-03-006.
:::

#### FR-03-031 · Thời hạn chờ, ngắt mạch và trả lỗi nhanh

::: dac-ta
**Mục đích.** Không để lượt gọi treo khi backend chậm hoặc hỏng, và không dồn thêm tải vào backend đang hỏng: có thời hạn chờ theo route, ngắt mạch, và trả lỗi nhanh khi backend chắc chắn không phục vụ được.

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA đặt thời hạn chờ ở route (`PERM-03-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-NFR-006; CMP-LAW-09; ADR-005; BR-03-011; Q03-03.

**Tiền điều kiện.** Route có `timeouts` (`connectMs` 3.000, `sendMs` 10.000, `readMs` 10.000, trần 30.000) và `breaker` (`api-breaker`).

**Kích hoạt.** Mỗi lượt gọi tới backend; và khi số lỗi liên tiếp của upstream vượt ngưỡng.

**Đầu vào.** `timeouts`; `breaker`: `unhealthyStatuses[]` (mặc định 500, 502, 503, 504), `failures` (5 lần liên tiếp), `openSeconds` (10), `halfOpenProbes` (1).

**Luồng xử lý chính.**

1. APISIX áp thời hạn kết nối, gửi, đọc theo route; vượt thời hạn đọc thì hủy lượt gọi (ERR-03-121).
2. Plugin `api-breaker` đếm lỗi liên tiếp theo upstream; đạt `failures` thì **mở** mạch.
3. Khi mạch mở, mọi lượt gọi tới upstream đó nhận ngay ERR-03-120 (503) kèm `Retry-After` bằng thời gian mở còn lại, không chờ hết thời hạn.
4. Sau `openSeconds` mạch **nửa mở**: cho một lượt thăm dò đi qua; thành công thì đóng mạch, thất bại thì mở lại với thời gian gấp đôi (tối đa 60 giây).
5. Gateway không thử lại lượt gọi đã gửi thân hoặc phương thức không an toàn lặp lại (`POST`, `PUT`, `PATCH`, `DELETE`) để tránh thực hiện hai lần.
6. Ghi chỉ số `dh_gateway_breaker_state{upstream}` và `dh_gateway_upstream_timeout_total`.

**Luồng thay thế.** Hạ nguồn thật sự chậm nhưng hợp lệ (báo cáo lớn): PA tăng `readMs` cho riêng route, không quá 30.000 ms (trần của Công văn 631).

**Luồng ngoại lệ.**

- Quá hạn chờ: ERR-03-121 (504), "Dịch vụ phía sau không phản hồi kịp. Thử lại; nếu lặp lại, gửi mã truy vết {traceId} cho quản trị."
- Mạch mở: ERR-03-120 (503) kèm `Retry-After`, "Dịch vụ đang được bảo vệ vì lỗi liên tiếp. Thử lại sau {s} giây."
- Khác SRS cũ: khi mọi nút không khỏe, hệ mới trả lỗi nhanh thay vì dồn lưu lượng vào nút ít lỗi nhất; xem Q03-03.

**Đầu ra.** `504` ERR-03-121 hoặc `503` ERR-03-120; hoặc phản hồi backend.

**Kết quả.** Lỗi backend trả về nhanh, không chiếm kết nối của gateway; backend có thời gian hồi phục không bị dồn tải.

**Hậu điều kiện.** Trạng thái mạch ở bộ nhớ nút.

**Sự kiện phát ra.** EVT-03-09 khi mạch mở lần đầu trong 10 phút.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-011.

**Màn hình, API.** UI-03-03; API-03-010.
:::

#### FR-03-032 · Sinh và truyền định danh truy vết

::: dac-ta
**Mục đích.** Bảo đảm mọi lượt gọi có một `traceId` từ điểm vào, truyền xuyên suốt tới backend và trả về bên gọi; khi một sở báo lỗi, họ đưa `traceId` và vận hành tra được ngay toàn bộ đường đi.

**Tác nhân, quyền.** Hệ thống (tự chạy).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; NFR-00-051; ADR-011.

**Tiền điều kiện.** Plugin `opentelemetry` (hoặc `zipkin`) bật ở mọi route.

**Kích hoạt.** Mỗi yêu cầu vào gateway.

**Đầu vào.** Tiêu đề `traceparent` (W3C Trace Context) nếu bên gọi gửi.

**Luồng xử lý chính.**

1. Gateway kiểm tra `traceparent` của bên gọi: đúng định dạng thì giữ `trace-id` và sinh `span-id` mới.
2. Không có hoặc sai định dạng thì sinh `trace-id` mới (sai định dạng: ghi cảnh báo nhẹ, không từ chối).
3. Gateway gắn `traceparent` và `tracestate` vào yêu cầu gửi backend.
4. Gateway trả `X-Trace-Id` (bằng `trace-id`) trong mọi phản hồi, kể cả lỗi do gateway sinh.
5. Gateway gửi span qua OTLP tới OTel Collector; lấy mẫu theo `gw.trace.successSampling` (0,05) cho phản hồi thành công; phản hồi lỗi (4xx do hệ thống, 5xx) được giữ 100% ở Collector (tail sampling).
6. Siêu dữ liệu lượt gọi ghi cùng `traceId` (FR-03-050).

**Luồng thay thế.** Bên gọi là một luồng của `dh-runtime`: nó đã mang sẵn `traceparent`, gateway tiếp nối cùng vết.

**Luồng ngoại lệ.**

- `traceparent` sai định dạng: gateway sinh mới, không có lỗi trả bên gọi; chỉ số `dh_gateway_trace_invalid_total` tăng.
- Collector không khả dụng: span đệm cục bộ có giới hạn, bỏ điểm cũ nhất khi đầy; không ảnh hưởng lượt gọi.

**Đầu ra.** Tiêu đề `X-Trace-Id`; span OTLP.

**Kết quả.** 100% lượt gọi có `traceId`; vận hành tra một lượt gọi từ gateway tới backend trong một vết.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-023.

**Màn hình, API.** Không có màn hình riêng (hiển thị `traceId` ở UI-03-09); không có API riêng.
:::

#### FR-03-033 · Chuyển tiếp WebSocket và nén nội dung

::: dac-ta
**Mục đích.** Đáp ứng yêu cầu của Công văn 631 về hỗ trợ giao thức HTTP, HTTPS và WebSocket: cho phép API dạng kết nối dài và nén nội dung để tiết kiệm băng thông.

**Tác nhân, quyền.** HTTT gọi API; PA, TA bật cho route (`PERM-03-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; CMP-LAW-09; SRS cũ (FR số 013).

**Tiền điều kiện.** Route khai báo `protocols` gồm `ws`, `wss` (nếu dùng) và `compression`.

**Kích hoạt.** Yêu cầu nâng cấp kết nối `Upgrade: websocket`, hoặc yêu cầu có `Accept-Encoding`.

**Đầu vào.** `protocols[]`, `ws.idleTimeoutSeconds` (mặc định 120), `ws.maxMessageBytes` (mặc định 1 MiB), `compression` (`gzip`, `br`).

**Luồng xử lý chính.**

1. Gateway nhận yêu cầu `Upgrade` ở route cho phép WebSocket và chạy đủ chuỗi chốt (TLS, WAF theo tiêu đề, xác thực, hạn mức, OPA) ở lúc bắt tay.
2. Gateway chuyển tiếp nâng cấp tới backend, rồi chuyển khung dữ liệu hai chiều.
3. Gateway đóng kết nối nhàn rỗi sau `ws.idleTimeoutSeconds`; khung lớn hơn `ws.maxMessageBytes` bị đóng với mã 1009.
4. Token hết hạn giữa chừng không cắt kết nối đang mở, nhưng kết nối bị đóng khi token bị thu hồi (FR-03-018) và tối đa sau 10 phút phải nâng cấp lại.
5. Với HTTP thường, gateway nén phản hồi trên 1 KiB khi bên gọi gửi `Accept-Encoding`, trừ nội dung đã nén.
6. Mỗi kết nối WebSocket tính một lượt gọi vào hạn mức khi bắt tay; số kết nối đồng thời mỗi HTTT bị giới hạn (`gw.ws.maxPerConsumer`, mặc định 50).

**Luồng thay thế.** Route không bật WebSocket: yêu cầu `Upgrade` bị coi như yêu cầu thường và nhận `426` từ backend hoặc `400` từ gateway.

**Luồng ngoại lệ.**

- Vượt số kết nối WebSocket của HTTT: ERR-03-116 (429), "HTTT đang giữ quá {n} kết nối WebSocket cho API này. Đóng bớt kết nối rồi thử lại."
- Route chưa bật WebSocket: ERR-03-101 (400), "API này không hỗ trợ WebSocket."

**Đầu ra.** Kết nối WebSocket được chuyển tiếp; hoặc phản hồi nén.

**Kết quả.** API kết nối dài hoạt động qua gateway với cùng mức bảo vệ như API thường.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-001.

**Màn hình, API.** UI-03-03; API-03-002.
:::

#### FR-03-034 · Chuyển đổi gRPC và REST

::: dac-ta
**Mục đích.** Cho phép HTTT gọi dịch vụ gRPC bằng REST/JSON (và ngược lại) mà không phải tự viết lớp chuyển đổi, khi có HTTT thật cần.

**Tác nhân, quyền.** PA, TA cấu hình (`PERM-03-admin`); HTTT gọi API.

**Mức ưu tiên, đợt.** C · Đợt 3.

**Truy vết.** REQ-03; SRS cũ (FR số 013); Q03-07.

**Tiền điều kiện.** Có tệp mô tả `.proto` được duyệt ở PH-02 cho API; plugin `grpc-transcode` có trong danh mục (BR-03-017).

**Kích hoạt.** Yêu cầu REST/JSON tới route có `transcode.grpc`.

**Đầu vào.** `protoSetRef` (tham chiếu bộ `.proto` đã duyệt), `service`, `method`, ánh xạ đường dẫn REST sang phương thức gRPC.

**Luồng xử lý chính.**

1. Quản trị chọn bộ `.proto` đã duyệt và ánh xạ đường dẫn REST sang phương thức gRPC.
2. Hệ thống kiểm tra bộ `.proto` biên dịch được và ánh xạ hợp lệ (sai: ERR-03-005).
3. Ảnh chụp mới mang cấu hình chuyển đổi tới các nút.
4. Gateway nhận REST/JSON, chuyển thành gọi gRPC tới upstream `grpc`, rồi chuyển phản hồi về JSON.
5. Lỗi gRPC được ánh xạ sang mã HTTP (`UNAVAILABLE` sang 503, `DEADLINE_EXCEEDED` sang 504, `PERMISSION_DENIED` sang 403, `INVALID_ARGUMENT` sang 400).
6. Chỉ số `dh_gateway_transcode_total{service,method,result}`.

**Luồng thay thế.** Cặp chuyển đổi ngược (gRPC tới REST) chưa hỗ trợ ở bản này.

**Luồng ngoại lệ.**

- Cặp chuyển đổi không hỗ trợ: ERR-03-125 (501), "Gateway chưa hỗ trợ kiểu chuyển đổi giao thức này."
- `.proto` hoặc ánh xạ sai: ERR-03-005 (422), "Cấu hình chuyển đổi gRPC không hợp lệ: {lỗi}."

**Đầu ra.** Phản hồi JSON; hoặc `501`, `422`.

**Kết quả.** HTTT gọi dịch vụ gRPC bằng REST qua một điểm vào.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đổi cấu hình chuyển đổi.

**Quy tắc nghiệp vụ.** BR-03-017.

**Màn hình, API.** UI-03-03; API-03-002.
:::

#### FR-03-035 · Phiên bản API song song và tiêu đề ngừng dùng

::: dac-ta
**Mục đích.** Cho phép nhiều phiên bản của một API cùng phục vụ để HTTT có thời gian chuyển đổi: phiên bản cũ được duy trì ít nhất 6 tháng sau khi có phiên bản mới (NFR-00-055), kèm tiêu đề báo ngày ngừng.

**Tác nhân, quyền.** PH-02 khai phiên bản; PA, TA xem (`PERM-03-read`); HTTT gọi API nhận tiêu đề.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-03; NFR-00-055; D03-09 §10.5; ADR-005.

**Tiền điều kiện.** Hai phiên bản của một API cùng `ACTIVE`; phiên bản cũ có `deprecatedAt` và `sunsetAt` ở PH-02 (hạn tối thiểu `gw.sunset.minDays` = 180 ngày kể từ `deprecatedAt`).

**Kích hoạt.** Mỗi lượt gọi tới phiên bản đã đánh dấu ngừng dùng; và khi tới `sunsetAt`.

**Đầu vào.** `apiVersion` (trong đường dẫn `/v1/`, `/v2/`), `deprecatedAt`, `sunsetAt`, `successorRoute`.

**Luồng xử lý chính.**

1. Mỗi phiên bản là một route riêng, phân biệt bằng đường dẫn `/api/{nhóm}/v{n}/…`; hai phiên bản không ảnh hưởng nhau.
2. Với route đã `deprecatedAt`, gateway thêm `Deprecation: true` (hoặc ngày), `Sunset: {ngày HTTP}` và `Link: <đường dẫn phiên bản mới>; rel="successor-version"` vào mọi phản hồi.
3. Hệ thống kiểm tra (FR-03-040) khoảng `sunsetAt − deprecatedAt` không dưới 180 ngày (vi phạm: ERR-03-005).
4. Trước `sunsetAt` 30 ngày, hệ thống thông báo đầu mối các HTTT vẫn đang gọi phiên bản cũ (đọc từ nhật ký 7 ngày).
5. Tới `sunsetAt`, route chuyển `SUNSET`: lượt gọi nhận ERR-03-126.
6. Sau thời gian giữ thêm (`gw.sunset.retainDays`, 30 ngày), route chuyển `RETIRED` và không còn trong ảnh chụp.

**Luồng thay thế.** Chủ dịch vụ gia hạn phiên bản cũ: PH-02 đổi `sunsetAt`, ảnh chụp mới có hạn mới.

**Luồng ngoại lệ.**

- Phiên bản đã hết hạn: ERR-03-126 (410), "Phiên bản {v} của API {mã} đã ngừng phục vụ từ {ngày}. Chuyển sang phiên bản {v mới}."
- Khoảng ngừng dùng ngắn hơn 180 ngày: ERR-03-005 (422), "Phiên bản cũ phải được duy trì tối thiểu 180 ngày sau khi công bố ngừng dùng."

**Đầu ra.** Tiêu đề `Deprecation`, `Sunset`, `Link`; hoặc `410`.

**Kết quả.** HTTT biết sớm và có đủ thời gian chuyển sang phiên bản mới; không phiên bản nào ngừng đột ngột.

**Hậu điều kiện.** Route đổi trạng thái theo mốc thời gian.

**Sự kiện phát ra.** EVT-03-03 (route đổi trạng thái).

**Kiểm toán.** Có khi route đổi sang `SUNSET`, `RETIRED`: thời điểm, số lượt gọi cuối 7 ngày.

**Quy tắc nghiệp vụ.** BR-03-030.

**Màn hình, API.** UI-03-02, UI-03-03; API-03-007, API-03-002.
:::

#### FR-03-036 · Dừng và mở API tức thời

::: dac-ta
**Mục đích.** Giữ nguyên chức năng Start/Stop của hệ cũ ở phần thực thi: cho vận hành dừng một API ngay khi cần (bảo trì backend, sự cố) và mở lại, có hiệu lực ở gateway trong vài giây, không chờ quy trình phát hành.

**Tác nhân, quyền.** TO, TA, SO, PA (`PERM-03-operate`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-005; ADR-005; BR-03-010.

**Tiền điều kiện.** Route `ACTIVE` (để dừng) hoặc `STOPPED` (để mở).

**Kích hoạt.** Người vận hành bấm "Dừng API" hoặc "Mở API" ở UI-03-02 hoặc UI-03-03.

**Đầu vào.** `routeCode` (đường dẫn), `reason` (T-TEXT, 10…300 ký tự), `message` (câu hiển thị cho bên gọi, tùy chọn).

**Luồng xử lý chính.**

1. Người vận hành chọn route, nêu lý do; hệ thống xác nhận lần hai (FR-00-050) vì thao tác ảnh hưởng vận hành.
2. Hệ thống kiểm tra route đang ở trạng thái cho phép thao tác (không phải `PENDING`, `SUNSET`, `RETIRED`; sai trạng thái: ERR-03-023).
3. Hệ thống đổi trạng thái thực thi sang `STOPPED` (hoặc `ACTIVE` khi mở), sinh ảnh chụp mới (FR-03-039…042) theo đường nhanh.
4. Sau khi nút nạp (mục tiêu 10 giây), lượt gọi tới route `STOPPED` nhận ERR-03-123 kèm `Retry-After`.
5. Mở API làm ngược lại; sự kiện và kiểm toán được ghi cả hai chiều.
6. Hệ thống đồng bộ trạng thái ngược về PH-02 để danh mục hiển thị "Đang dừng".

**Luồng thay thế.** Dừng có hẹn giờ (bảo trì theo lịch): người vận hành nhập `from`, `to`; hệ thống đặt ảnh chụp theo lịch và tự mở khi hết.

**Luồng ngoại lệ.**

- Route đã dừng (hoặc đã mở): ERR-03-019 (409), "API đang ở trạng thái {trạng thái}."
- Route không cho thao tác: ERR-03-023 (409), "Không thể dừng hoặc mở API ở trạng thái {trạng thái}."
- Lượt gọi tới route đang dừng: ERR-03-123 (503), "API {mã} đang tạm dừng{: lý do nếu có}. Thử lại sau."

**Đầu ra.** `202`, `{routeCode, state, snapshotVersion}`; ở data plane `503` ERR-03-123.

**Kết quả.** API dừng và mở có hiệu lực trong vài giây, có lý do và dấu vết.

**Hậu điều kiện.** Route ở trạng thái mới; ảnh chụp mới được phát.

**Sự kiện phát ra.** EVT-03-03.

**Kiểm toán.** Có: người thao tác, route, lý do, trạng thái trước và sau, số phiên bản ảnh chụp.

**Quy tắc nghiệp vụ.** BR-03-010; BR-03-029.

**Màn hình, API.** UI-03-02, UI-03-03; API-03-003, API-03-004.
:::

#### FR-03-037 · Chuyển tiếp lượt gọi của tenant đã sáp nhập

::: dac-ta
**Mục đích.** Khi hai tỉnh sáp nhập, HTTT của tỉnh cũ vẫn gọi được API theo địa chỉ cũ trong thời gian chuyển tiếp (mặc định 6 tháng): gateway chuyển lượt gọi sang API tương ứng của tenant đích kèm tiêu đề cảnh báo (D03-10 §5.4).

**Tác nhân, quyền.** PA (`PERM-03-admin`); PH-20 khởi động quy trình sáp nhập; HTTT của tenant nguồn.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-20; D03-10 §5.4; BR-03-026.

**Tiền điều kiện.** Tenant nguồn ở trạng thái `MERGED`; tenant đích `ACTIVE`; có bảng ánh xạ API nguồn sang API đích do PH-20 cung cấp.

**Kích hoạt.** PA tạo chuyển tiếp ở UI-03-16 khi PH-20 chuyển tenant nguồn sang `MERGED`.

**Đầu vào.** `fromTenant`, `toTenant`, `startAt`, `endAt` (mặc định 180 ngày sau `startAt`), `routeMap[]` (route nguồn sang route đích), `identityMode` (`TOKEN_OF_TARGET`: HTTT dùng thông tin xác thực cấp mới ở tenant đích, giai đoạn chuyển tiếp cấp song song).

**Luồng xử lý chính.**

1. PA tạo chuyển tiếp, chọn bảng ánh xạ; hệ thống kiểm tra tenant nguồn `MERGED`, tenant đích `ACTIVE`, các route đích tồn tại (sai: ERR-03-025).
2. Hệ thống sinh ảnh chụp mới cho cả hai tenant: host của tenant nguồn có route chuyển tiếp trỏ route đích.
3. Lượt gọi tới host nguồn: gateway xác thực bằng token của tenant đích (HTTT đã được cấp song song), đặt `X-DH-Tenant` là tenant đích, chuyển tới route đích.
4. Gateway thêm `Deprecation: true`, `Sunset: {endAt}`, `Link` tới địa chỉ mới vào phản hồi.
5. Mỗi tuần hệ thống thống kê HTTT còn gọi địa chỉ cũ và gửi đầu mối.
6. Tới `endAt`, chuyển tiếp kết thúc, host nguồn trả ERR-03-126 (410).

**Luồng thay thế.** HTTT chưa kịp đổi thông tin xác thực: token tenant nguồn bị từ chối bằng ERR-03-106 kèm hướng dẫn nhận thông tin xác thực mới.

**Luồng ngoại lệ.**

- Tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp: ERR-03-025 (409), "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy."
- Token tenant nguồn: ERR-03-106 (401), "Địa chỉ này đã chuyển sang tỉnh {đích}. Dùng thông tin xác thực mới của tỉnh {đích}."

**Đầu ra.** `201`, `{redirectId, state, endAt}`.

**Kết quả.** HTTT của tỉnh cũ không bị gián đoạn khi sáp nhập, và có thời gian chuyển đổi rõ ràng.

**Hậu điều kiện.** EN-03-13 `ACTIVE`; ảnh chụp mới có route chuyển tiếp.

**Sự kiện phát ra.** EVT-03-10.

**Kiểm toán.** Có: người tạo, tenant nguồn và đích, bảng ánh xạ, thời hạn.

**Quy tắc nghiệp vụ.** BR-03-026; BR-03-030.

**Màn hình, API.** UI-03-16; API-03-094, API-03-095, API-03-096.
:::

#### FR-03-038 · Phân cửa vào Internet và mạng nội bộ

::: dac-ta
**Mục đích.** Bảo đảm chỉ những API thật sự cần mở ra Internet (callback thanh toán, cổng nhà phát triển) mới có mặt ở cửa Internet; mặc định mọi API chỉ ở cửa mạng nội bộ. Giữ đường từ Internet vào data plane ở mức tối thiểu.

**Tác nhân, quyền.** TA đề nghị (`PERM-03-admin`); SO duyệt (`PERM-03-approve`); xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-13; ADR-033; D03-09 §4.4; BR-03-015.

**Tiền điều kiện.** Route đã `ACTIVE` ở cửa `INT`; có lý do nghiệp vụ.

**Kích hoạt.** TA bấm "Mở ra Internet" ở UI-03-03.

**Đầu vào.** `routeCode`, `exposure` (`INT` hoặc `EXT`), `reason`, `wafParanoia` (mặc định 2 cho đường dẫn giao diện, 1 cho API máy), `ipAllowCidrs[]` (nếu bên gọi Internet có dải cố định, ví dụ dải của nhà cung cấp thanh toán).

**Luồng xử lý chính.**

1. TA chọn route, nêu lý do và dải địa chỉ nguồn được phép (nếu có).
2. Hệ thống kiểm tra route đủ điều kiện: có lược đồ, có chính sách OPA, bắt buộc xác thực (không `KEYLESS` trừ dữ liệu mở), WAF chế độ `BLOCK` ở PROD (không đủ: ERR-03-011).
3. Hệ thống tạo yêu cầu thay đổi chờ SO duyệt; người đề nghị không tự duyệt (ERR-03-008).
4. SO duyệt hoặc từ chối kèm ý kiến.
5. Được duyệt thì ảnh chụp mới gắn route vào nhóm `apisix-ext`; nút `apisix-ext` nạp route và áp các chốt ở biên (TLS, chặn địa chỉ, WAF, giới hạn thân, `ip-restriction` theo `ipAllowCidrs`) rồi chuyển lượt gọi sang `apisix-int`, nơi áp phần còn lại của chuỗi chốt (xác thực, thu hồi, hạn mức, OPA, định tuyến).
6. Đưa route về `INT` (thu hồi cửa ngoài) có hiệu lực ngay, không cần duyệt lại (giảm bề mặt tấn công).

**Luồng thay thế.** Callback của nhà cung cấp thanh toán (PH-19) dùng mẫu route `EXT` có sẵn: giới hạn theo dải nguồn đã công bố, xác minh chữ ký ở DU (SEC-48), hạn mức riêng.

**Luồng ngoại lệ.**

- Route chưa đủ điều kiện ra cửa ngoài: ERR-03-011 (422), "Route chưa đủ điều kiện mở ra Internet: {lý do}."
- Tự duyệt: ERR-03-008 (403).
- Lượt gọi từ Internet tới route chỉ ở `INT`: ERR-03-114 (404) như không tồn tại.

**Đầu ra.** `202`, `{requestId, state}`; khi được duyệt, `snapshotVersion`.

**Kết quả.** Bề mặt tiếp xúc Internet được kiểm soát và rà soát; không có API nào ra ngoài mà không qua hai người.

**Hậu điều kiện.** `exposure` của route đổi theo quyết định.

**Sự kiện phát ra.** EVT-03-03.

**Kiểm toán.** Có: người đề nghị, người duyệt, lý do, dải nguồn, trạng thái trước và sau.

**Quy tắc nghiệp vụ.** BR-03-015; BR-03-019.

**Màn hình, API.** UI-03-03, UI-03-17; API-03-008, API-03-071, API-03-072, API-03-073.
:::

### 6.6. Nhóm E · Đồng bộ cấu hình

Nhóm E là phần của PH-03 ở mặt phẳng điều khiển (`dh-connect`): biến những gì đã được duyệt ở PH-01, PH-02, PH-12 và PH-20 thành cấu hình gateway, kiểm tra, ký, phát, theo dõi nút nạp, và cho phép quay lui hoặc chặn khẩn cấp. Nguyên tắc xuyên suốt: `dh-connect` không nằm trên đường đi của lượt gọi; gateway chỉ nhận ảnh chụp đã ký; mọi thay đổi cấu hình đi qua ảnh chụp, không sửa trực tiếp trên pod (BR-03-016). Hình dưới là quan hệ giữa các chức năng trong nhóm.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm E"}
flowchart TB
  SRC["PH-01, PH-02, PH-12, PH-20<br/>và dữ liệu của PH-03"] --> F039["FR-03-039 Tổng hợp"]
  F046["FR-03-046 Đồng bộ consumer"] --> F039
  F048["FR-03-048 Mẫu chính sách"] --> F039
  F039 --> F040["FR-03-040 Kiểm tra hợp lệ"]
  F040 -->|"Đạt"| F041["FR-03-041 Ký, đặt phiên bản"]
  F040 -->|"Không đạt"| REJ["Từ chối, báo PH-02"]
  F041 --> F042["FR-03-042 Phát Git, bucket"]
  F042 --> F043["FR-03-043 Nút nạp"]
  F043 --> F045["FR-03-045 Trạng thái nút"]
  F044["FR-03-044 Quay lui"] --> F041
  F047["FR-03-047 Tạm ngừng khẩn cấp"] -.-> F039
  F049["FR-03-049 Chứng thư biên"] -.-> F043
```

#### FR-03-039 · Tổng hợp cấu hình gateway từ danh mục

::: dac-ta
**Mục đích.** Biến dữ liệu đã được duyệt ở các phân hệ khác (API, gói, đăng ký, HTTT, chính sách, hạn mức) và dữ liệu riêng của PH-03 (ngoại lệ WAF, ghi đè hạn mức, chuyển tiếp tenant) thành một mô hình cấu hình thống nhất rồi kết xuất thành tệp khai báo cho từng cửa vào. Con người không bao giờ phải viết tay cấu hình APISIX.

**Tác nhân, quyền.** Hệ thống (tự chạy khi có sự kiện hoặc định kỳ); PA, TA kích hoạt thủ công (`PERM-03-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-011…015; ADR-005; ADR-013; D03-09 §6.1.

**Tiền điều kiện.** Các phân hệ nguồn trả được dữ liệu (nếu không, dùng bản đã lưu gần nhất, quá 24 giờ thì cảnh báo); mẫu chính sách đã bật cho tenant (FR-03-048).

**Kích hoạt.** (a) Sự kiện từ PH-02 (API công bố, ngừng, gói đổi, đăng ký đổi), PH-01 (HTTT đổi trạng thái), PH-12 (gói chính sách mới), PH-20 (hạn mức, host của tenant); (b) tác vụ đối chiếu định kỳ mỗi 5 phút để bắt sự kiện bị lỡ; (c) thay đổi trực tiếp ở PH-03 (ngoại lệ WAF, hạn mức, chuyển tiếp); (d) người có `PERM-03-publish` bấm "Tổng hợp lại".

**Đầu vào.** Nguồn dữ liệu theo bảng "Nguồn của mô hình cấu hình" dưới đây; `scope` (`TENANT` hoặc `PLATFORM`).

**Luồng xử lý chính.**

1. `dh-connect` nhận sự kiện, gom các sự kiện trong 3 giây (`gw.snapshot.debounceSeconds`) cho cùng tenant thành một lần tổng hợp.
2. Với tenant liên quan, hệ thống đọc từ cơ sở của PH-03 (qua API nội bộ hoặc bản chiếu) các bản ghi nguồn ở bảng dưới; tenant đang bị đóng băng sau quay lui (FR-03-044) thì sự kiện được xếp hàng, chưa tổng hợp.
3. Hệ thống dựng mô hình: route, upstream, consumer, đăng ký, chính sách chiếu từ gói, mẫu chính sách, ngoại lệ WAF, hạn mức, chứng thư, chuyển tiếp.
4. Hệ thống kết xuất mô hình thành **mảnh tenant** dạng khai báo cho APISIX, tách nhóm `EXT` và `INT` theo `exposure` của route.
5. Hệ thống ghép mảnh mới với mảnh hiện hành của các tenant khác và phần dùng chung `COMMON` thành **bản ghép nền tảng** của site.
6. Bản ghép chuyển sang bước kiểm tra hợp lệ (FR-03-040); ghi bản ghi EN-03-09 trạng thái `BUILT` với danh sách phiên bản nguồn (`builtFrom`).

**Luồng thay thế.** Chỉ thay đổi phần dùng chung `COMMON` (ví dụ danh mục dùng chung quốc gia): tổng hợp lại mảnh `COMMON` và ghép, không đụng mảnh tenant.

**Luồng ngoại lệ.**

- Phân hệ nguồn không trả dữ liệu: dùng bản chiếu gần nhất, ghi chỉ số `dh_gateway_source_stale_seconds{source}`, cảnh báo khi quá 24 giờ; không dừng tổng hợp các tenant khác.
- Hai người cùng bấm tổng hợp: một lần chạy, lần còn lại nhận ERR-03-006 (409), "Đang có một lần tổng hợp cấu hình cho tỉnh này. Chờ lần đó hoàn tất."
- Tenant đang đóng băng: lần bấm thủ công nhận ERR-03-006 kèm thông tin thời điểm hết đóng băng, "Cấu hình tỉnh này đang bị giữ sau lần quay lui đến {thời điểm}. Bỏ giữ trước khi tổng hợp."

**Đầu ra.** `202`, `{buildId, snapshotVersion (khi xong), state: BUILT}`; ảnh chụp ở trạng thái `BUILT`.

**Kết quả.** Một mô hình cấu hình nhất quán, tái lập được từ dữ liệu nguồn; không ai phải sửa tay cấu hình gateway.

**Hậu điều kiện.** Có EN-03-09 `BUILT`; chưa có thay đổi nào ở gateway.

**Sự kiện phát ra.** Không (EVT-03-01 phát ở bước phát hành).

**Kiểm toán.** Có: nguyên nhân kích hoạt, danh sách phiên bản nguồn, số route, consumer, hash nội dung.

**Quy tắc nghiệp vụ.** BR-03-016; BR-03-026.

**Màn hình, API.** UI-03-10; API-03-059, API-03-056, API-03-057.
:::

| Nguồn | Dữ liệu lấy | Chủ sở hữu | Cách nhận |
|---|---|---|---|
| API, phiên bản, backend, OpenAPI đã duyệt | `apiCode`, `apiVersion`, upstream, lược đồ, `requiredScopes`, `policyPackage`, ngừng dùng | PH-02 | Sự kiện và API đọc |
| Gói sử dụng, đăng ký sử dụng | `securityMode`, hạn mức, hạn ngạch, đường dẫn, nhóm ưu tiên, trạng thái đăng ký | PH-02 | Sự kiện và API đọc |
| HTTT, client, trạng thái | `systemCode`, `consumerCode`, trạng thái, vân tay chứng thư | PH-01 qua FR-03-046 | API nội bộ (saga) |
| Chính sách ủy quyền | Phiên bản gói chính sách OPA hiện hành, URL JWKS theo realm | PH-12 | API đọc |
| Tenant, host, hạn mức hợp đồng | Host, tiền tố, hạn mức tối đa, trạng thái tenant | PH-20 | Sự kiện và API đọc |
| Dữ liệu riêng của PH-03 | Ngoại lệ WAF, luật vá ảo, ghi đè hạn mức, chuyển tiếp tenant, ngoại lệ TLS, tham số, lệnh tạm ngừng | PH-03 | Cơ sở `ph03_gateway` |
| Mẫu chính sách | Danh sách plugin và tham số mặc định | Bản phát hành nền tảng | Gói đi kèm (FR-03-048) |

: Nguồn của mô hình cấu hình gateway

#### FR-03-040 · Kiểm tra hợp lệ cấu hình trước khi phát

::: dac-ta
**Mục đích.** Không bao giờ đưa tới gateway một cấu hình sai hoặc không an toàn: mọi bản ghép phải qua một bộ kiểm tra tĩnh trước khi ký và phát. Cấu hình xấu bị chặn ở control plane, không để lọt tới data plane.

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA chạy thử không phát (`PERM-03-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-24, SEC-26, SEC-43, SEC-65; ADR-005; BR-03-014, BR-03-017.

**Tiền điều kiện.** Có ảnh chụp `BUILT` (FR-03-039), hoặc người dùng gửi cấu hình thử.

**Kích hoạt.** Ngay sau khi tổng hợp xong; hoặc người dùng gọi API-03-058 (chạy thử, không ghi).

**Đầu vào.** Bản ghép `BUILT`; bảng quy tắc kiểm tra bên dưới.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra cú pháp và lược đồ cấu hình APISIX bằng chính bộ kiểm tra của phiên bản APISIX đang chạy (cùng ảnh container).
2. Hệ thống chạy từng quy tắc ở bảng "Quy tắc kiểm tra tĩnh" dưới đây.
3. Mỗi vi phạm ghi mã quy tắc, đối tượng, mô tả; quy tắc mức `LỖI` làm cả ảnh chụp bị từ chối; mức `CẢNH BÁO` không chặn.
4. Nếu có lỗi, ảnh chụp chuyển `REJECTED`, hệ thống phát EVT-03-12 kèm danh sách lỗi cho PH-02 và gửi thông báo cho người phát hành (FR-00-060); cấu hình đang chạy không đổi.
5. Nếu không có lỗi, ảnh chụp chuyển sang ký (FR-03-041); cảnh báo (nếu có) được đính kèm.
6. Với chạy thử, hệ thống trả danh sách kết quả mà không tạo ảnh chụp.

**Luồng thay thế.** Lỗi chỉ ở route của một API: cho phép cô lập route đó (loại khỏi bản ghép) và vẫn phát phần còn lại khi tham số `gw.snapshot.isolateBadRoute` bật (mặc định tắt để giữ nguyên tắc tất cả hoặc không); route bị cô lập hiển thị `PENDING` kèm lỗi.

**Luồng ngoại lệ.**

- Cấu hình không hợp lệ: ERR-03-005 (422), "Cấu hình gateway không hợp lệ: {n} lỗi. Xem danh sách bên dưới." Mỗi lỗi nêu mã quy tắc và đối tượng.
- Route thiếu lược đồ OpenAPI hoặc chính sách OPA: ERR-03-012 (422), "Route {mã} thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát."
- Plugin hoặc mẫu chính sách ngoài danh mục: ERR-03-013 (422), "Route {mã} dùng plugin {tên} không có trong danh mục được duyệt."

**Đầu ra.** `200` (chạy thử) với `{valid, errors[], warnings[]}`; hoặc ảnh chụp `REJECTED` kèm danh sách lỗi.

**Kết quả.** Cấu hình sai hoặc thiếu an toàn không bao giờ tới gateway; người sửa biết chính xác lỗi ở đâu.

**Hậu điều kiện.** Ảnh chụp có kết quả kiểm tra; không đổi gateway.

**Sự kiện phát ra.** EVT-03-12 (ảnh chụp bị từ chối).

**Kiểm toán.** Có: kết quả kiểm tra, danh sách lỗi và cảnh báo, người hoặc nguyên nhân kích hoạt.

**Quy tắc nghiệp vụ.** BR-03-014; BR-03-017; BR-03-026.

**Màn hình, API.** UI-03-10; API-03-058, API-03-059.
:::

| Mã quy tắc | Nội dung kiểm tra | Mức | Mã lỗi |
|---|---|---|---|
| CHK-01 | Cú pháp và lược đồ cấu hình APISIX hợp lệ theo phiên bản đang chạy | LỖI | ERR-03-005 |
| CHK-02 | Mỗi route có lược đồ OpenAPI đã duyệt và bật `request-validation` | LỖI | ERR-03-012 |
| CHK-03 | Mỗi route có `policyPackage` tồn tại trong gói chính sách OPA hiện hành | LỖI | ERR-03-012 |
| CHK-04 | Chỉ dùng plugin và mẫu chính sách trong danh mục được duyệt | LỖI | ERR-03-013 |
| CHK-05 | Không có hai route của hai tenant cùng host và đường dẫn | LỖI | ERR-03-005 |
| CHK-06 | `KEYLESS` chỉ cho API dữ liệu mở; `API_KEY` chỉ cho mức phân loại Công khai, Nội bộ | LỖI | ERR-03-005 |
| CHK-07 | CORS không dùng ký tự đại diện | LỖI | ERR-03-005 |
| CHK-08 | Thời hạn chờ không quá 30.000 ms; thân không quá 10 MiB | LỖI | ERR-03-005 |
| CHK-09 | Route `EXT` đã có quyết định duyệt còn hiệu lực | LỖI | ERR-03-011 |
| CHK-10 | Địa chỉ upstream không thuộc dải bị cấm (loopback, dải siêu dữ liệu cloud 169.254.0.0/16, dải quản trị Z7) | LỖI | ERR-03-005 |
| CHK-11 | Khoảng từ `deprecatedAt` tới `sunsetAt` không dưới 180 ngày | LỖI | ERR-03-005 |
| CHK-12 | Hạn mức của tenant, route, consumer không vượt trần hợp đồng | LỖI | ERR-03-018 |
| CHK-13 | Mọi host có chứng thư còn hạn ít nhất 7 ngày | LỖI | ERR-03-016 |
| CHK-14 | Mọi consumer, đăng ký được tham chiếu đều tồn tại | LỖI | ERR-03-005 |
| CHK-15 | Kích thước ảnh chụp không quá `gw.snapshot.maxBytes` (20 MiB, giả định) | LỖI | ERR-03-005 |
| CHK-16 | Route không khai `requiredScopes` | CẢNH BÁO | — |
| CHK-17 | Chứng thư còn dưới 30 ngày | CẢNH BÁO | — |
| CHK-18 | Số route của tenant vượt 80% hạn mức số route | CẢNH BÁO | — |

: Quy tắc kiểm tra tĩnh cấu hình gateway

#### FR-03-041 · Sinh ảnh chụp cấu hình có phiên bản và chữ ký

::: dac-ta
**Mục đích.** Đóng cấu hình đã kiểm tra thành một ảnh chụp bất biến có số phiên bản tăng đơn điệu và chữ ký, để nút gateway chỉ nạp cấu hình do control plane chính thức tạo ra và không bao giờ nạp lùi lại phiên bản cũ (SEC-65, SEC-36).

**Tác nhân, quyền.** Hệ thống (tự chạy); khóa ký ở OpenBao.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-36, SEC-65; ADR-005, ADR-012; D03-09 §6.1; BR-03-016, BR-03-018.

**Tiền điều kiện.** Ảnh chụp đã qua kiểm tra hợp lệ (FR-03-040); khóa ký `transit/keys/dh-gateway-snapshot` ở OpenBao khả dụng.

**Kích hoạt.** Sau khi kiểm tra hợp lệ đạt.

**Đầu vào.** Bản ghép đã kiểm tra; khóa ký (không xuất được); bộ đếm phiên bản của site.

**Luồng xử lý chính.**

1. Hệ thống chuẩn hóa bản ghép (YAML chính tắc: thứ tự khóa cố định, không dấu thời gian) và tính `contentHash` SHA-256.
2. Hệ thống cấp `snapshotVersion` từ bộ đếm của site trong giao dịch có khóa, bảo đảm tăng đơn điệu, không trùng, không lùi.
3. Hệ thống lập tệp kê khai (manifest) gồm `snapshotVersion`, `site`, `contentHash`, danh sách mảnh tenant kèm hash từng mảnh, `builtFrom`, `generatedAt`.
4. Hệ thống gửi băm của manifest tới OpenBao transit để ký (ECDSA P-256); khóa riêng không rời OpenBao (OpenBao không khả dụng: ERR-03-015).
5. Hệ thống ghi chữ ký cạnh manifest; chuyển trạng thái `SIGNED`.
6. Khóa ký xoay vòng mỗi 12 tháng; khóa công khai các phiên bản còn hiệu lực được phân phối tới bộ đồng bộ qua ConfigMap, nút chấp nhận nhiều khóa trong thời gian chuyển giao.

**Luồng thay thế.** Hai lần tổng hợp song song cho hai site (hai TTDL): mỗi site có bộ đếm phiên bản riêng; sau khi chuyển site (DR), site mới tiếp tục từ số lớn nhất đã biết cộng khoảng cách an toàn `gw.snapshot.drGap` (1.000).

**Luồng ngoại lệ.**

- OpenBao hoặc dịch vụ ký không khả dụng: ERR-03-015 (503), "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi." Ảnh chụp giữ `BUILT`, thử lại theo lũy thừa tới 1 giờ rồi cảnh báo Cao.
- Đang có lần ký khác của cùng site: ERR-03-006 (409).

**Đầu ra.** Ảnh chụp `SIGNED` với `snapshotVersion`, `contentHash`, `signature`.

**Kết quả.** Mỗi ảnh chụp là bằng chứng bất biến, kiểm chứng được, truy được nguồn gốc dữ liệu.

**Hậu điều kiện.** EN-03-09 `SIGNED`; bộ đếm phiên bản tăng.

**Sự kiện phát ra.** Không (EVT-03-01 phát khi phát hành).

**Kiểm toán.** Có: `snapshotVersion`, `contentHash`, mã khóa ký, nguyên nhân tạo.

**Quy tắc nghiệp vụ.** BR-03-016; BR-03-018.

**Màn hình, API.** UI-03-10; API-03-059, API-03-057.
:::

#### FR-03-042 · Phát ảnh chụp tới Git và bucket

::: dac-ta
**Mục đích.** Đưa ảnh chụp đã ký tới nơi các nút gateway đọc, qua hai đường: bucket Garage `dh-platform-gateway` (đường nhanh, vài giây) và kho Git cấu hình qua Argo CD (đường lưu lịch sử và dự phòng), để gateway có cấu hình ngay cả khi một đường hỏng hoặc khi `dh-connect` ngừng.

**Tác nhân, quyền.** Hệ thống (tự chạy); PA, TA phát thủ công (`PERM-03-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; ADR-005, ADR-009, ADR-013; NFR-00-012, NFR-00-052; D03-09 §6.1; NFR-03-007, NFR-03-008.

**Tiền điều kiện.** Ảnh chụp `SIGNED`; bucket và kho Git cấu hình truy cập được.

**Kích hoạt.** Ngay sau khi ký, hoặc người dùng bấm "Phát" cho một ảnh chụp đã ký.

**Đầu vào.** Ảnh chụp `SIGNED`: manifest, chữ ký, tệp bản ghép.

**Luồng xử lý chính.**

1. Hệ thống ghi tệp vào bucket `dh-platform-gateway` tại `snapshots/{site}/{version}/` và cuối cùng cập nhật con trỏ `current` trỏ tới phiên bản mới (ghi con trỏ sau cùng để nút không đọc bản dở).
2. Hệ thống tạo commit vào kho Git cấu hình (thư mục `gateway/{site}/`) kèm manifest; Argo CD cập nhật ConfigMap `apisix-config` ở `dh-gateway`.
3. Hệ thống xác nhận đã ghi thành công vào bucket (bắt buộc) và Git (nếu Git lỗi thì xếp hàng thử lại tới 1 giờ, cảnh báo Cao).
4. Hệ thống chuyển ảnh chụp sang `PUBLISHED` và phát EVT-03-01.
5. Hệ thống giữ tối đa `gw.snapshot.retain` (50) phiên bản gần nhất ở bucket; Git giữ toàn bộ lịch sử.
6. Khi site hoạt động là DR, bucket được nhân bản sang site còn lại bởi cơ chế sao chép của Garage (D03-09, ADR-034).

**Luồng thay thế.** Bucket không ghi được nhưng Git ghi được: ảnh chụp tới nút qua ConfigMap (chậm hơn, phụ thuộc chu kỳ Argo CD); trạng thái `PUBLISHED` kèm cờ `fastPathDown`.

**Luồng ngoại lệ.**

- Cả bucket và Git đều không ghi được: ERR-03-014 (502), "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." Ảnh chụp giữ `SIGNED`, thử lại theo lũy thừa, cảnh báo Cao.
- Ảnh chụp mới hơn đã được phát trước (phát chen): ERR-03-006 (409), bản cũ hơn không được phát.

**Đầu ra.** `202` (bất đồng bộ), ảnh chụp `PUBLISHED` với `publishedAt`, `paths`.

**Kết quả.** Mọi nút gateway thấy ảnh chụp mới trong vài giây; cấu hình có lịch sử đầy đủ ở Git.

**Hậu điều kiện.** Ảnh chụp ở bucket và Git; con trỏ `current` đã chuyển.

**Sự kiện phát ra.** EVT-03-01.

**Kiểm toán.** Có: phiên bản, đường ghi, kết quả từng đường, thời điểm.

**Quy tắc nghiệp vụ.** BR-03-016; BR-03-010.

**Màn hình, API.** UI-03-10; API-03-060.
:::

#### FR-03-043 · Nạp ảnh chụp ở nút gateway

::: dac-ta
**Mục đích.** Mỗi nút APISIX tự nạp cấu hình mới đã ký, nguyên tử và không gián đoạn: yêu cầu đang xử lý dùng cấu hình cũ, yêu cầu mới dùng cấu hình mới, không có trạng thái nửa vời, và cấu hình sai không bao giờ thay cấu hình đang chạy.

**Tác nhân, quyền.** Bộ đồng bộ cấu hình (tiến trình nhỏ cạnh APISIX, tự chạy); PO, PA xem kết quả (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; ADR-005, ADR-013; NFR-00-012, NFR-00-013; SEC-65; D03-09 §6.1; NFR-03-007, NFR-03-008.

**Tiền điều kiện.** Bộ đồng bộ có khóa công khai của khóa ký (ConfigMap); có quyền đọc bucket và Secret chứng thư.

**Kích hoạt.** Con trỏ `current` ở bucket đổi (kiểm tra mỗi `gw.sync.pollSeconds` = 5 giây); hoặc ConfigMap đổi; hoặc pod khởi động.

**Đầu vào.** Manifest, chữ ký, bản ghép; `runningVersion` của nút; Secret chứng thư (FR-03-049).

**Luồng xử lý chính.**

1. Bộ đồng bộ phát hiện phiên bản mới ở bucket, tải manifest và bản ghép.
2. Bộ đồng bộ kiểm chữ ký bằng khóa công khai tin cậy và kiểm `contentHash`; sai thì từ chối (ghi chỉ số `result="bad_signature"`).
3. Bộ đồng bộ kiểm `snapshotVersion` lớn hơn `runningVersion`; không lớn hơn thì bỏ qua (chống nạp lùi).
4. Bộ đồng bộ chọn phần của nhóm mình (`EXT` hoặc `INT`), điền chứng thư và khóa riêng từ Secret đã gắn (khóa riêng không bao giờ ở Git hay bucket), kiểm tra bằng bộ kiểm tra cấu hình của APISIX.
5. Đạt thì ghi tệp `apisix.yaml` bằng đổi tên nguyên tử; APISIX tự nạp lại không mất kết nối; không đạt thì giữ tệp cũ và đặt chỉ số `result="invalid"`.
6. Nút cập nhật chỉ số `dh_gateway_config_version` và `dh_gateway_config_applied_timestamp`; PH-13 thu thập (FR-03-045).

**Luồng thay thế.** Khởi động lại khi `dh-connect` và bucket đều ngừng: nút dùng bản ghi trong ConfigMap `apisix-config` đã gắn kết (bản Git gần nhất) và nếu bucket sống lại thì lấy bản mới nhất; nhờ đó pod bị lập lịch lại vẫn có cấu hình (NFR-03-007).

**Luồng ngoại lệ.**

- Chữ ký sai hoặc hash sai: nút từ chối, giữ bản đang chạy, cảnh báo Nghiêm trọng "nghi cấu hình giả mạo" ở FR-03-054.
- Cấu hình không qua bộ kiểm tra của APISIX: nút từ chối, giữ bản cũ, cảnh báo Cao; `dh-connect` thấy nút `FAILED` ở FR-03-045.
- Mất kết nối bucket: nút giữ cấu hình hiện tại, tiếp tục phục vụ.

**Đầu ra.** Tệp `apisix.yaml` mới đang chạy; chỉ số phiên bản và kết quả.

**Kết quả.** Thay đổi cấu hình có hiệu lực ở mọi nút trong 10 giây (mục tiêu) mà không lượt gọi nào lỗi; cấu hình sai hoặc giả không bao giờ được nạp.

**Hậu điều kiện.** Nút chạy đúng một ảnh chụp; ảnh chụp cũ còn ở bộ nhớ để hoàn tất yêu cầu đang xử lý.

**Sự kiện phát ra.** Không (trạng thái đi qua chỉ số).

**Kiểm toán.** Có trong nhật ký hệ thống (SEC-61): nút, phiên bản trước và sau, kết quả.

**Quy tắc nghiệp vụ.** BR-03-010; BR-03-016; BR-03-018.

**Màn hình, API.** UI-03-11; API-03-063, API-03-064.
:::

#### FR-03-044 · Quay lui về phiên bản cấu hình trước

::: dac-ta
**Mục đích.** Khi một lần phát cấu hình gây sự cố, cho vận hành đưa gateway về trạng thái của một phiên bản trước chỉ bằng một thao tác, nhanh và có dấu vết, mà vẫn giữ nguyên tắc số phiên bản chỉ tăng.

**Tác nhân, quyền.** PA, TA, TO, SO (`PERM-03-operate`); xem so sánh `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; ADR-009; SEC-65; BR-03-018; NFR-03-008.

**Tiền điều kiện.** Có ít nhất một phiên bản trước đã `APPLIED` còn trong bucket hoặc Git.

**Kích hoạt.** Người vận hành chọn một phiên bản cũ ở UI-03-10 và bấm "Quay lui".

**Đầu vào.** `targetVersion` (T-INT), `scope` (`TENANT` với mảnh của một tenant, hoặc `PLATFORM` chỉ dành cho PA), `reason` (T-TEXT), `holdHours` (mặc định 24).

**Luồng xử lý chính.**

1. Người vận hành xem so sánh (diff) giữa phiên bản hiện tại và `targetVersion` (API-03-062) để biết route, hạn mức nào sẽ đổi.
2. Hệ thống kiểm tra phiên bản đích còn đọc được và các đối tượng tham chiếu (consumer, chứng thư, upstream) còn tồn tại (không: ERR-03-007).
3. Hệ thống tạo ảnh chụp **mới** có nội dung của phiên bản đích (không đưa phiên bản cũ trở lại), chạy kiểm tra hợp lệ (FR-03-040), ký và phát (FR-03-041, 042) theo đường ưu tiên.
4. Hệ thống đặt tenant ở trạng thái **giữ** (`holdHours`): các sự kiện từ PH-02, PH-01 xếp hàng, không tự tổng hợp lại, để lần đối chiếu định kỳ không âm thầm hoàn tác việc quay lui.
5. Người vận hành xử lý nguyên nhân, rồi bấm "Bỏ giữ"; hệ thống tổng hợp lại từ dữ liệu nguồn mới nhất (FR-03-039). Hết `holdHours` mà chưa bỏ giữ thì cảnh báo, hệ thống không tự bỏ giữ.
6. Hệ thống phát EVT-03-02.

**Luồng thay thế.** Quay lui một route đơn lẻ: dùng dừng API (FR-03-036) hoặc tạm ngừng khẩn cấp (FR-03-047), không cần quay lui cả mảnh tenant.

**Luồng ngoại lệ.**

- Phiên bản đích tham chiếu đối tượng đã bị xóa hoặc chứng thư hết hạn: ERR-03-007 (422), "Không thể quay lui về phiên bản {v}: {đối tượng} không còn hợp lệ."
- Có lần phát đang chạy: ERR-03-006 (409), "Đang có lần phát cấu hình khác. Chờ lần đó hoàn tất."
- Quay lui `PLATFORM` do người không phải PA: ERR-03-022 (403).

**Đầu ra.** `202`, `{newSnapshotVersion, restoredFrom, holdUntil}`.

**Kết quả.** Sự cố do cấu hình được khắc phục trong vài chục giây; mọi thao tác có lý do và dấu vết.

**Hậu điều kiện.** Gateway chạy nội dung phiên bản đích dưới số phiên bản mới; tenant ở trạng thái giữ.

**Sự kiện phát ra.** EVT-03-02; EVT-03-01.

**Kiểm toán.** Có: người thao tác, phiên bản đích, phiên bản mới, lý do, kết quả so sánh (tóm tắt), thời hạn giữ.

**Quy tắc nghiệp vụ.** BR-03-018; BR-03-016.

**Màn hình, API.** UI-03-10; API-03-061, API-03-062, API-03-056.
:::

#### FR-03-045 · Theo dõi nút và trạng thái đồng bộ

::: dac-ta
**Mục đích.** Thay thế màn "danh sách gateway đang kết nối" và "giám sát CPU, Java heap" của hệ cũ bằng bảng nút APISIX kèm phiên bản cấu hình đang chạy, để vận hành biết ngay nút nào chưa nhận cấu hình mới và nút nào lỗi.

**Tác nhân, quyền.** PO, PA, TA, TO, SO, AU (`PERM-03-read`); PH-13 (scope `gateway:read-state`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; LGC-APIM-023; LGC-APIM-024; LGC-APIM-025; ADR-005, ADR-011.

**Tiền điều kiện.** Các nút phát chỉ số Prometheus; PH-13 thu thập và truy vấn được.

**Kích hoạt.** Người dùng mở UI-03-11; hoặc tác vụ đánh giá trạng thái mỗi 30 giây.

**Đầu vào.** Chỉ số `dh_gateway_config_version`, `dh_gateway_config_applied_timestamp`, `dh_gateway_jwks_age_seconds`, `dh_gateway_valkey_up`, `dh_gateway_waf_mode`, chỉ số NGINX và tiến trình (CPU, bộ nhớ, kết nối) của từng pod; bộ lọc `gate`, `site`, `syncState`.

**Luồng xử lý chính.**

1. Hệ thống truy vấn PH-13 (Mimir) lấy chỉ số của mọi pod APISIX theo `gate` và `site`.
2. Hệ thống so `runningVersion` của từng nút với `desiredVersion` (phiên bản của ảnh chụp `PUBLISHED` mới nhất của site).
3. Hệ thống gán `syncState`: `IN_SYNC` (cùng phiên bản), `LAGGING` (lệch quá 60 giây), `FAILED` (nạp lỗi ở lần gần nhất), `UNKNOWN` (không có chỉ số quá 2 phút).
4. Hệ thống tính trạng thái ảnh chụp: mọi nút `IN_SYNC` thì ảnh chụp `APPLIED`; còn nút `LAGGING` thì `PARTIAL`.
5. Màn hình hiển thị bảng nút: tên pod, cửa, site, phiên bản chạy, độ trễ nạp, kết quả lần nạp cuối, tuổi JWKS, tình trạng Valkey, chế độ WAF, CPU, bộ nhớ, kết nối; có chi tiết một nút (API-03-064).
6. Nút `LAGGING`, `FAILED` hoặc `UNKNOWN` quá ngưỡng phát cảnh báo qua PH-13 (FR-03-054).

**Luồng thay thế.** PH-13 không truy vấn được: màn hình hiển thị trạng thái "không có số liệu" thay vì sai số liệu.

**Luồng ngoại lệ.**

- Không đọc được số liệu từ PH-13: ERR-03-026 (503), "Chưa lấy được số liệu nút gateway từ hệ thống giám sát. Thử lại sau."
- Nút không tồn tại: ERR-03-001 (404).

**Đầu ra.** `200`, danh sách nút `{nodeId, gate, site, runningVersion, desiredVersion, syncState, lastApplyResult, lagSeconds, …}` và tóm tắt `{inSync, lagging, failed, unknown}`.

**Kết quả.** Vận hành biết sau một phát cấu hình mọi nút đã nhận chưa; nút lệch được phát hiện trong dưới 2 phút.

**Hậu điều kiện.** Không đổi dữ liệu (trạng thái nút là chỉ số).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-016.

**Màn hình, API.** UI-03-11; API-03-063, API-03-064.
:::

#### FR-03-046 · Đồng bộ consumer và thông tin xác thực công khai

::: dac-ta
**Mục đích.** Khi một HTTT được kết nạp, tạm ngừng hoặc thu hồi ở PH-01, gateway phải biết ngay: tạo consumer (hình chiếu của client), nhận phần công khai của thông tin xác thực (vân tay chứng thư, băm khóa API), và áp trạng thái. Gateway không bao giờ giữ bí mật của client.

**Tác nhân, quyền.** PH-01 (saga kết nạp) và PH-02 gọi API nội bộ bằng scope `gateway:sync`; TA, PA xem (`PERM-03-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-01, REQ-03; LGC-APIM-019; LGC-APIM-020; SEC-24; ADR-005; D03-01 §7.3 (saga).

**Tiền điều kiện.** HTTT ở PH-01 đang kết nạp hoặc `ACTIVE`; client tương ứng đã (hoặc sắp) được PH-12 tạo ở Keycloak.

**Kích hoạt.** Bước "tạo consumer" của saga kết nạp; hoặc PH-01 đổi trạng thái HTTT; hoặc xoay chứng thư, khóa của client.

**Đầu vào.** Theo bảng "Dữ liệu vào của FR-03-046" dưới đây; tiêu đề `Idempotency-Key`.

**Luồng xử lý chính.**

1. PH-01 gọi `PUT /consumers/{consumerCode}` với danh tính client, trạng thái, nhóm ưu tiên (API-03-013).
2. `dh-connect` kiểm tra scope `gateway:sync`, tenant lấy từ token, mã đúng mẫu và chưa dùng cho HTTT khác (trùng: ERR-03-002), nhóm ưu tiên hợp lệ.
3. `dh-connect` lưu consumer (idempotent: cùng `Idempotency-Key` trả cùng kết quả) và gọi `PUT /consumers/{consumerCode}/credentials` để lưu phần công khai: vân tay SHA-256 chứng thư, ngày hết hạn, băm khóa API (nếu có) (API-03-014).
4. Hệ thống từ chối mọi trường trông như bí mật (khóa riêng, `client_secret`, khóa API dạng rõ) với ERR-03-003.
5. Hệ thống kích hoạt tổng hợp tenant (FR-03-039); trả `202` kèm `effectiveBy` (dự kiến 10 giây).
6. Saga theo dõi `GET /consumers/{consumerCode}` tới khi `syncState = IN_SYNC` thì coi bước hoàn tất; nếu bước sau thất bại, PH-01 gọi `DELETE` (API-03-015) để bù trừ; HTTT bị tạm ngừng thì PH-01 đặt `state = SUSPENDED` bằng cùng API, có hiệu lực qua ERR-03-127.

**Luồng thay thế.** Xoay chứng thư: PH-01 thêm vân tay mới vào danh sách của consumer (tối đa 2 vân tay cùng lúc trong giai đoạn chuyển giao), gỡ vân tay cũ sau khi HTTT chuyển xong.

**Luồng ngoại lệ.**

- Mã consumer đã thuộc HTTT khác: ERR-03-002 (409), "Mã {mã} đã được dùng cho HTTT khác."
- Dữ liệu có trường bí mật hoặc sai dạng: ERR-03-003 (400), "Không gửi bí mật tới gateway. Chỉ gửi vân tay chứng thư hoặc băm khóa."
- Xóa consumer còn đăng ký hiệu lực: ERR-03-017 (409), "HTTT còn {n} đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ."
- Gọi thiếu scope: ERR-03-022 (403).

**Đầu ra.** `202` với `{consumerCode, state, snapshotVersion?, effectiveBy}`; `Location`, `ETag`.

**Kết quả.** HTTT mới gọi được API trong vài giây sau khi saga hoàn tất; HTTT bị tạm ngừng bị chặn trong vài giây.

**Hậu điều kiện.** EN-03-03, EN-03-04 mới hoặc đổi; ảnh chụp mới có consumer.

**Sự kiện phát ra.** EVT-03-04.

**Kiểm toán.** Có: gọi từ dịch vụ nào, consumer, thay đổi trạng thái, vân tay (băm cắt ngắn), `Idempotency-Key`.

**Quy tắc nghiệp vụ.** BR-03-022; BR-03-021.

**Màn hình, API.** UI-03-04, UI-03-05; API-03-013, API-03-014, API-03-015, API-03-011, API-03-012.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `consumerCode` | T-CODE | Có | `^[a-z][a-z0-9-]{2,62}$`, trùng `clientId` ở Keycloak | `ht-qlvb` |
| `systemCode` | T-CODE | Có | HTTT `ACTIVE` ở PH-01 | `HT-QLVB` |
| `state` | T-ENUM | Có | `ACTIVE`, `SUSPENDED` | `ACTIVE` |
| `priorityGroup` | T-ENUM | Không | `ESSENTIAL`, `NORMAL` (mặc định), `LOW` | `NORMAL` |
| `trustedSource` | T-BOOL | Không | Mặc định `false`; `true` chỉ do SO duyệt | `false` |
| `authMethod` | T-ENUM | Có | `OAUTH2`, `MTLS`, `API_KEY` | `MTLS` |
| `certThumbprints[]` | T-STR | Khi `MTLS` | SHA-256 dạng hex 64 ký tự, tối đa 2 | `9f2c…` |
| `certNotAfter` | T-TS | Khi `MTLS` | Sau hiện tại | `2027-06-30T00:00:00+07:00` |
| `apiKeyHash` | T-STR | Khi `API_KEY` | SHA-256 hex, không phải khóa dạng rõ | `ab31…` |
| `apiKeyNotAfter` | T-TS | Khi `API_KEY` | Tối đa 180 ngày | `2027-03-01T00:00:00+07:00` |

: Dữ liệu vào của FR-03-046

```{.mermaid caption="Trình tự saga kết nạp HTTT tạo consumer ở gateway"}
sequenceDiagram
  autonumber
  participant P1 as PH-01 saga
  participant P12 as PH-12 Keycloak
  participant CP as dh-connect
  participant SY as Bộ đồng bộ
  participant AX as APISIX
  P1->>P12: Tạo client ở realm của tenant
  P12-->>P1: clientId và chứng thư đã đăng ký
  P1->>CP: PUT consumers và credentials, Idempotency-Key
  CP->>CP: Kiểm tra, lưu consumer, từ chối trường bí mật
  CP-->>P1: 202 effectiveBy 10 giây
  CP->>CP: Tổng hợp, kiểm tra, ký, phát
  SY->>AX: Nạp ảnh chụp mới
  P1->>CP: GET consumers, hỏi syncState
  CP-->>P1: IN_SYNC, bước hoàn tất
  Note over P1,CP: Bước sau lỗi thì PH-01 gọi DELETE consumer để bù trừ
```

Hình cho thấy gateway chỉ nhận phần công khai và chỉ báo hoàn tất khi nút đã nạp; nếu bước sau của saga lỗi, việc bù trừ là gỡ consumer.

#### FR-03-047 · Tạm ngừng khẩn cấp route hoặc consumer

::: dac-ta
**Mục đích.** Khi có sự cố an ninh (HTTT bị chiếm quyền, API bị khai thác), cho vận hành chặn ngay một HTTT hoặc một route khỏi gateway trong vài chục giây, không chờ quy trình phát hành, và mở lại khi xử lý xong.

**Tác nhân, quyền.** SO, TO, TA, PA (`PERM-03-operate`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-25, SEC-72, SEC-73; BR-03-021; NFR-03-009.

**Tiền điều kiện.** Đối tượng tồn tại ở tenant; người thực hiện có quyền.

**Kích hoạt.** Người vận hành bấm "Tạm ngừng khẩn cấp" ở UI-03-02 hoặc UI-03-05.

**Đầu vào.** `targetType` (`ROUTE` hoặc `CONSUMER`), `targetCode`, `reason` (T-TEXT, 10…500 ký tự bắt buộc).

**Luồng xử lý chính.**

1. Người vận hành chọn đối tượng, nêu lý do và xác nhận lần hai (FR-00-050).
2. Hệ thống kiểm tra đối tượng thuộc tenant và chưa bị tạm ngừng khẩn cấp (đã có: ERR-03-019).
3. Hệ thống ghi EN-03-12 và ghi khóa vào Valkey `{tenant}:kill:{type}:{code}` (đường nhanh); plugin `dh-kill-switch` ở mọi nút kiểm tra khóa này với bộ đệm cục bộ 5 giây.
4. Hệ thống đồng thời sinh ảnh chụp mới có đối tượng ở trạng thái `SUSPENDED` (đường bền vững, phòng khi Valkey mất).
5. Lượt gọi của consumer bị tạm ngừng nhận ERR-03-127; lượt gọi tới route bị tạm ngừng nhận ERR-03-123, trong tối đa 30 giây kể từ lệnh.
6. Mở lại: người có `PERM-03-operate` bấm "Mở lại", nhập lý do; hệ thống xóa khóa, đặt `liftedAt`, sinh ảnh chụp mới; việc mở lại cũng sinh kiểm toán và sự kiện.

**Luồng thay thế.** Tạm ngừng khẩn cấp cho nguyên một HTTT (mọi client của HTTT): dùng PH-01 tạm ngừng HTTT (FR-03-046 đồng bộ trạng thái); tạm ngừng khẩn cấp ở PH-03 áp cho từng consumer.

**Luồng ngoại lệ.**

- Đối tượng đã tạm ngừng: ERR-03-019 (409), "{Route|HTTT} {mã} đã đang bị tạm ngừng khẩn cấp từ {thời điểm}."
- Không tìm thấy hoặc thuộc tenant khác: ERR-03-001 (404).
- Valkey không khả dụng: đường nhanh lỗi, hệ thống báo "áp dụng qua ảnh chụp, dự kiến ≤ 60 giây" và vẫn hoàn tất qua đường bền vững.

**Đầu ra.** `202`, `{blockId, targetType, targetCode, effectiveBy}`.

**Kết quả.** Nguồn sự cố bị chặn trong tối đa 30 giây; nhân sự có thời gian điều tra mà không bị tác động.

**Hậu điều kiện.** EN-03-12 `ACTIVE`; đối tượng ở trạng thái `SUSPENDED` trong ảnh chụp.

**Sự kiện phát ra.** EVT-03-03 (route), EVT-03-04 (consumer); EVT-03-09.

**Kiểm toán.** Có: người thực hiện, đối tượng, lý do, thời điểm; cả lúc mở lại.

**Quy tắc nghiệp vụ.** BR-03-021; BR-03-029.

**Màn hình, API.** UI-03-02, UI-03-05; API-03-017, API-03-018, API-03-019, API-03-020.
:::

#### FR-03-048 · Bộ mẫu chính sách gateway được duyệt sẵn

::: dac-ta
**Mục đích.** Nâng cấp bước "Policies" của hệ cũ: thay vì gắn tay chính sách cho từng API, nền tảng cung cấp một bộ mẫu chính sách đã được rà soát an ninh; mỗi route chỉ chọn một mẫu và chỉnh tham số trong miền cho phép. Không có plugin nào ngoài danh mục được chạy.

**Tác nhân, quyền.** PA phát hành mẫu theo bản phát hành nền tảng; TA bật, tắt mẫu cho tenant (`PERM-03-admin`); xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; LGC-APIM-015; SEC-26, SEC-43, SEC-52; ADR-005; BR-03-017.

**Tiền điều kiện.** Bản phát hành nền tảng mang danh mục mẫu đã ký; mỗi mẫu có phiên bản.

**Kích hoạt.** TA mở UI-03-13; hoặc PH-02 gán mẫu cho gói khi soạn API.

**Đầu vào.** `templateCode`, `enabled` (theo tenant), tham số chỉnh trong miền (hạn mức mặc định, mức hoang tưởng, thời hạn chờ…).

**Luồng xử lý chính.**

1. Hệ thống liệt kê các mẫu của bảng "Mẫu chính sách gateway" dưới đây kèm danh sách plugin có thứ tự, tham số mặc định và miền cho phép chỉnh.
2. TA bật hoặc tắt từng mẫu cho tenant (mẫu bị tắt không dùng được cho API mới; API đang dùng không bị ảnh hưởng tới khi đổi gói).
3. PH-02 khi soạn gói chọn một mẫu và các tham số trong miền; tham số ngoài miền bị từ chối ở FR-03-040 (ERR-03-013).
4. Khi nền tảng phát hành phiên bản mẫu mới, PH-03 tổng hợp lại các route dùng mẫu theo chính sách nâng cấp (mặc định: áp phiên bản mới ở lần phát kế tiếp, có ghi chú thay đổi).
5. Plugin không thuộc danh mục (kể cả mã Lua do tenant viết) không có đường vào: không có API nào cho phép tải plugin lên.
6. Danh mục plugin do Datahub tự viết (`dh-revocation`, `dh-ip-block`, `dh-kill-switch`, `dh-path-acl`, `dh-waf-guard`, `dh-adaptive-throttle`) được xây cùng ảnh APISIX, ký bằng cosign và quét lỗ hổng như mọi ảnh khác (SEC-55 đến SEC-57).

**Luồng thay thế.** Tenant cần một biến thể không có trong danh mục: gửi đề nghị tới PA để thêm mẫu ở bản phát hành sau, không có đường tự thêm (ghi ở "Đề nghị đồng bộ" nếu cần ADR bổ sung plugin).

**Luồng ngoại lệ.**

- Mẫu hoặc plugin ngoài danh mục: ERR-03-013 (422), "Mẫu chính sách hoặc plugin {tên} không có trong danh mục được duyệt."
- Tham số ngoài miền cho phép: ERR-03-003 (400), "Tham số {tên} nằm ngoài miền cho phép của mẫu {mã}."
- Tắt mẫu đang được route dùng: ERR-03-019 (409) kèm danh sách route dùng.

**Đầu ra.** `200`, danh sách mẫu `{templateCode, version, plugins[], enabled, params[]}`.

**Kết quả.** Chính sách của mọi API thống nhất, rà soát được một lần; không có cấu hình riêng lẻ khó kiểm soát.

**Hậu điều kiện.** Trạng thái bật, tắt mẫu của tenant được lưu.

**Sự kiện phát ra.** Không (ảnh hưởng đi theo EVT-03-01).

**Kiểm toán.** Có khi bật, tắt mẫu: người, mẫu, tenant.

**Quy tắc nghiệp vụ.** BR-03-017; BR-03-014.

**Màn hình, API.** UI-03-13; API-03-065, API-03-066, API-03-067.
:::

| Mã mẫu | Dùng cho | Plugin có thứ tự (rút gọn) | Mức hoang tưởng WAF |
|---|---|---|---|
| `tpl-api-oauth2` | API máy với máy, dữ liệu Nội bộ, Hạn chế | `limit-conn`, `limit-req`, WAF, `openid-connect`, `dh-revocation`, `consumer-restriction`, `limit-count`, `dh-path-acl`, `opa`, `request-validation`, `opentelemetry` | 1 |
| `tpl-api-mtls` | API dữ liệu Nhạy cảm (bắt buộc mTLS và ràng buộc chứng thư) | như trên, cộng kiểm tra `cnf` | 1 |
| `tpl-api-open-data` | API dữ liệu mở (`KEYLESS`) | `limit-conn`, `limit-req`, WAF, `limit-count` theo IP, `request-validation`, `opentelemetry` | 1 |
| `tpl-ui-bff` | Đường dẫn giao diện `/api/{nhóm}/v{n}` gọi từ BFF | như `tpl-api-oauth2`, mức IP 50 yêu cầu/giây | 2 |
| `tpl-callback-ext` | Callback từ Internet (PayGov, đối tác) ở cửa `EXT` | `ip-restriction` theo dải công bố, `limit-req`, WAF, `request-validation`, chữ ký kiểm ở DU | 1 |
| `tpl-websocket` | API kết nối dài | như `tpl-api-oauth2`, cộng giới hạn kết nối WebSocket | 1 |

: Mẫu chính sách gateway được duyệt sẵn

#### FR-03-049 · Quản lý chứng thư biên

::: dac-ta
**Mục đích.** Bảo đảm chứng thư TLS của các host ở cửa vào luôn còn hạn, được gia hạn tự động, nạp không gián đoạn, và khóa riêng không bao giờ nằm ngoài kho bí mật; đồng thời quản lý bộ CA tin cậy để xác minh chứng thư khách (mTLS).

**Tác nhân, quyền.** PA, TA xem và gia hạn thủ công (`PERM-03-operate`); PA quản lý bộ CA khách và nhà phát hành (`PERM-03-admin`); cert-manager và OpenBao (hệ thống).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; SEC-12, SEC-35; ADR-012, ADR-033; NFR-03-010, NFR-03-011.

**Tiền điều kiện.** cert-manager và nhà phát hành (OpenBao PKI cho host nội bộ; ACME hoặc CA do tỉnh cung cấp cho host Internet, theo hồ sơ triển khai) đã cấu hình; External Secrets đồng bộ Secret từ OpenBao.

**Kích hoạt.** Tác vụ định kỳ mỗi giờ quét chứng thư; chứng thư còn dưới `gw.cert.renewDays` (30) ngày; hoặc người dùng bấm "Gia hạn ngay".

**Đầu vào.** Danh sách `Certificate` của cert-manager theo host; `renewDays`, `warnDays`; bộ CA khách.

**Luồng xử lý chính.**

1. Hệ thống liệt kê chứng thư của hai cửa vào: host, nhà phát hành, thời điểm hết hạn, trạng thái, nơi dùng.
2. Khi còn dưới 30 ngày, cert-manager tự gia hạn; khóa riêng mới sinh và lưu ở OpenBao (không xuất ra Git hay bucket).
3. External Secrets cập nhật Secret trong namespace gateway; bộ đồng bộ phát hiện Secret đổi, điền chứng thư mới vào `apisix.yaml` và APISIX nạp lại không mất kết nối (FR-03-043).
4. Chứng thư còn dưới `warnDays` mà gia hạn tự động chưa thành công thì phát EVT-03-08 và cảnh báo Cao ở FR-03-054; còn dưới 7 ngày thì cảnh báo Nghiêm trọng và FR-03-040 chặn phát cấu hình mới chứa host đó (CHK-13).
5. PA nhập thủ công chứng thư do CA bên ngoài cấp: hệ thống kiểm tra chuỗi, hạn, khớp khóa riêng và host trước khi nhận (sai: ERR-03-016).
6. PA cập nhật bộ CA tin cậy cho mTLS (thêm, gỡ CA); thay đổi bộ CA đi theo ảnh chụp có kiểm tra hợp lệ.

**Luồng thay thế.** Hồ sơ không có cloud: CA nội bộ OpenBao PKI cấp cho cả host nội bộ và ngoại lệ TLS; host Internet dùng chứng thư của CA do tỉnh cung cấp, nhập thủ công (Q03-09).

**Luồng ngoại lệ.**

- Chứng thư nhập sai chuỗi, hết hạn hoặc không khớp khóa: ERR-03-016 (422), "Chứng thư không hợp lệ: {lý do}."
- OpenBao hoặc nhà phát hành không khả dụng khi gia hạn: ERR-03-015 (503), "Dịch vụ cấp chứng thư tạm thời không khả dụng. Hệ thống sẽ thử lại; chứng thư hiện tại còn hiệu lực đến {ngày}."
- Gia hạn thủ công khi đã có lần gia hạn đang chạy: ERR-03-019 (409).

**Đầu ra.** `200`, danh sách chứng thư `{certCode, subject, hosts[], notAfter, issuer, state}`; `202` khi gia hạn.

**Kết quả.** Không còn sự cố hết hạn chứng thư; gia hạn tự động không gián đoạn (NFR-03-011).

**Hậu điều kiện.** Chứng thư mới ở Secret và nút; khóa riêng chỉ ở OpenBao.

**Sự kiện phát ra.** EVT-03-08.

**Kiểm toán.** Có: người gia hạn hoặc nhập, chứng thư, hạn mới; thay đổi bộ CA khách.

**Quy tắc nghiệp vụ.** BR-03-003; BR-03-016.

**Màn hình, API.** UI-03-12; API-03-068, API-03-069, API-03-070, API-03-035.
:::

### 6.7. Nhóm F · Quan sát và nhật ký lượt gọi

Nhóm F cho biết điều gì đã xảy ra với từng lượt gọi và với cả cổng: ghi siêu dữ liệu (không ghi nội dung), tra cứu, chỉ số, vết, kiểm tra tổng hợp, cảnh báo an ninh và bảng điều khiển. PH-03 phát và hiển thị; việc lưu lâu dài, cảnh báo tập trung và kiểm toán WORM do PH-13 đảm nhận. Hình dưới là quan hệ giữa các chức năng.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm F"}
flowchart TB
  F050["FR-03-050 Siêu dữ liệu lượt gọi"] --> OBS[("PH-13<br/>ClickHouse, Loki")]
  F052["FR-03-052 Chỉ số, vết"] --> OBS2[("PH-13<br/>Mimir, Tempo")]
  OBS --> F051["FR-03-051 Tra cứu nhật ký"]
  OBS --> F058["FR-03-058 Báo cáo sử dụng"]
  OBS2 --> F055["FR-03-055 Bảng điều khiển"]
  OBS2 --> F054["FR-03-054 Cảnh báo an ninh"]
  F053["FR-03-053 Kiểm tra tổng hợp"] --> OBS2
  F054 --> SIEM["SIEM của tỉnh<br/>qua PH-13"]
```

#### FR-03-050 · Ghi siêu dữ liệu lượt gọi có che dữ liệu

::: dac-ta
**Mục đích.** Ghi lại mọi lượt gọi qua gateway ở mức siêu dữ liệu để thanh tra, điều tra sự cố và thống kê (KPI-07), và tuyệt đối không ghi nội dung bản tin vì có thể chứa dữ liệu cá nhân (Luật BVDLCN). Thay cho "log toàn bộ request" của hệ cũ.

**Tác nhân, quyền.** Hệ thống (tự chạy); PH-13 nhận và lưu.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; LGC-APIM-022; CMP-LAW-05; SEC-32, SEC-61; NFR-00-029, NFR-00-062; ADR-011.

**Tiền điều kiện.** Plugin ghi nhật ký của APISIX bật ở mọi route; đường tới PH-13 (OTel Collector hoặc Kafka) truy cập được.

**Kích hoạt.** Sau mỗi lượt gọi, kể cả lượt bị từ chối ở bất kỳ chốt nào.

**Đầu vào.** Ngữ cảnh lượt gọi: kết quả từng chốt, thời gian, danh tính, route, upstream.

**Luồng xử lý chính.**

1. Gateway lập bản ghi theo bảng "Trường siêu dữ liệu lượt gọi" dưới đây ngay khi phản hồi xong, kể cả khi lượt gọi bị từ chối ở chốt sớm (khi đó các trường sau chốt đó để trống).
2. Bản ghi không chứa thân yêu cầu, thân phản hồi, giá trị tiêu đề `Authorization`, khóa API, cookie, hay giá trị tham số truy vấn; tham số truy vấn chỉ ghi tên.
3. Gateway ghi bản ghi vào bộ đệm đĩa cục bộ (tối đa 1 GiB mỗi pod) rồi gửi qua OTel Collector tới PH-13.
4. Bộ che dữ liệu của Collector (processor `redaction`, SEC-32) kiểm tra lần hai theo mẫu (số định danh 12 số, số điện thoại, thư điện tử) trong các trường chuỗi còn lại và thay bằng giá trị che.
5. PH-13 ghi vào kho lưu lượng (ClickHouse) với nhãn `tenant` bắt buộc; bản ghi thiếu nhãn tenant bị từ chối ở Collector (SEC-84).
6. Khi PH-13 hoặc Collector không khả dụng, bản ghi nằm ở bộ đệm đĩa và gửi lại sau; chỉ khi bộ đệm đầy mới bỏ bản ghi cũ nhất, kèm chỉ số `dh_gateway_accesslog_dropped_total` và cảnh báo Cao.

**Luồng thay thế.** Route dữ liệu mở (`KEYLESS`): không có consumer; trường `consumerCode` để trống, địa chỉ nguồn vẫn ghi.

**Luồng ngoại lệ.**

- Bộ đệm đĩa đầy do PH-13 ngừng lâu: bỏ bản ghi cũ nhất, cảnh báo Cao ở FR-03-054; không ảnh hưởng lượt gọi.
- Bản ghi chứa giá trị khớp mẫu dữ liệu nhạy cảm sau bước 4: bộ quét mẫu của CI và kiểm thử chạy hằng ngày báo lỗi (NFR-03-014); không có ca ngoại lệ được chấp nhận.

**Đầu ra.** Bản ghi siêu dữ liệu ở PH-13; chỉ số `dh_gateway_accesslog_sent_total`.

**Kết quả.** Mọi lượt gọi truy vết được theo thời gian, HTTT, route, kết quả, `traceId`; 0 dữ liệu cá nhân trong nhật ký.

**Hậu điều kiện.** Bản ghi nằm ở kho của PH-13 theo thời hạn lưu của NFR-03-026.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Bản thân bản ghi là dữ liệu truy vết; thay đổi cấu hình ghi nhật ký được kiểm toán.

**Quy tắc nghiệp vụ.** BR-03-007; BR-03-023.

**Màn hình, API.** UI-03-09; API-03-074.
:::

| Trường | Kiểu | Ví dụ | Ghi chú |
|---|---|---|---|
| `ts` | T-TS | `2026-11-26T09:14:03.218+07:00` | Thời điểm nhận yêu cầu |
| `tenant` | T-CODE | `T68` | Từ token, không từ tiêu đề |
| `traceId`, `spanId` | T-ID | `4bf92f35…` | W3C Trace Context |
| `routeCode`, `apiVersion` | T-CODE | `tra-cuu-ho-tich.v1` | Trống nếu không có route khớp |
| `consumerCode` | T-CODE | `ht-qlvb` | Trống với `KEYLESS` |
| `method`, `pathTemplate` | T-STR | `GET`, `/ho-tich/{id}` | Đường dẫn theo mẫu route, không có giá trị tham số |
| `queryNames[]` | T-STR | `["tuNgay","denNgay"]` | Chỉ tên tham số |
| `status`, `errorCode` | T-INT, T-CODE | `429`, `ERR-03-116` | Mã lỗi của gateway nếu có |
| `latencyMs`, `upstreamMs` | T-INT | `42`, `31` | Độ trễ tổng và của backend |
| `bytesIn`, `bytesOut` | T-INT | `312`, `5.120` | |
| `srcIp` | T-IP | `10.20.30.40` | Chỉ người có `PERM-03-log-read` xem |
| `authResult`, `limitResult`, `wafResult`, `opaResult` | T-ENUM | `OK`, `RATE_LIMITED`, `PASS`, `ALLOW` | Kết quả từng chốt |
| `node`, `upstreamNode`, `snapshotVersion` | T-STR | `apisix-int-2`, `10.1.4.7:8080`, `10412` | Để truy vết cấu hình |
| `synthetic` | T-BOOL | `false` | Lượt kiểm tra tổng hợp (FR-03-053) |

: Trường siêu dữ liệu lượt gọi

#### FR-03-051 · Tra cứu và xuất nhật ký lượt gọi

::: dac-ta
**Mục đích.** Cho vận hành, Cán bộ ATTT và kiểm toán viên tra cứu lượt gọi đã qua gateway theo thời gian, HTTT, route, kết quả, `traceId`; mở chi tiết một lượt; và xuất ra tệp phục vụ điều tra. Thay cho màn "Log request của Application" ở hệ cũ.

**Tác nhân, quyền.** TA, TO, SO, AU, PA (`PERM-03-log-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; LGC-APIM-022; NFR-00-062; FR-00-030, FR-00-031, FR-00-034.

**Tiền điều kiện.** Siêu dữ liệu đã có ở PH-13 (FR-03-050); người dùng đã chọn tenant (FR-00-004).

**Kích hoạt.** Người dùng mở UI-03-09 hoặc tab "Nhật ký" ở UI-03-05; hoặc dán `traceId` vào ô tìm.

**Đầu vào.** Theo bảng "Bộ lọc nhật ký lượt gọi" dưới đây; `page`, `size` (≤ 100).

**Luồng xử lý chính.**

1. Người dùng chọn khoảng thời gian (mặc định 1 giờ gần nhất) và bộ lọc.
2. Hệ thống kiểm tra khoảng thời gian không quá 31 ngày mỗi truy vấn và không quá 12 tháng về trước (vi phạm: ERR-03-021).
3. Hệ thống truy vấn kho của PH-13 với điều kiện tenant bắt buộc lấy từ token; đối tượng của tenant khác không bao giờ trả về (BR-03-028).
4. Hệ thống trả danh sách phân trang kèm tổng số bản ghi ước lượng; `srcIp` chỉ hiển thị khi người dùng có `PERM-03-log-read`.
5. Người dùng mở một dòng: chi tiết gồm mọi trường ở bảng siêu dữ liệu, kết quả từng chốt, liên kết sang vết ở PH-13 theo `traceId`.
6. Xuất: người dùng bấm "Xuất"; trên 10.000 dòng thì chạy nền, thông báo khi xong, tệp hạn tải 24 giờ (FR-00-031); tối đa `gw.accessLog.export.maxRows` (100.000) dòng mỗi lần; xuất có kiểm toán.

**Luồng thay thế.** Tra theo `traceId`: bỏ giới hạn khoảng thời gian mặc định, tìm trong 12 tháng.

**Luồng ngoại lệ.**

- Khoảng thời gian quá rộng: ERR-03-021 (400), "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất."
- Kho của PH-13 không khả dụng: ERR-03-026 (503), "Chưa truy vấn được nhật ký lượt gọi. Thử lại sau."
- Người không có quyền: ERR-03-022 (403), "Bạn không có quyền xem nhật ký lượt gọi."
- Xuất vượt số dòng tối đa: ERR-03-021 với gợi ý thu hẹp bộ lọc.

**Đầu ra.** `200`, `items[]`, `page`, `size`, `totalElements`; `202` khi xuất, kèm `exportId` và đường tải khi xong.

**Kết quả.** Vận hành tìm một lượt gọi lỗi trong vài giây, trong p95 ≤ 3 giây (NFR-03-022).

**Hậu điều kiện.** Không đổi dữ liệu (tạo tệp xuất khi xuất).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có cho xuất và cho xem chi tiết có `srcIp`: người dùng, bộ lọc, số dòng, thời điểm.

**Quy tắc nghiệp vụ.** BR-03-007; BR-03-028.

**Màn hình, API.** UI-03-09, UI-03-05; API-03-074, API-03-075, API-03-076.
:::

| Bộ lọc | Kiểu | Ràng buộc | Ví dụ |
|---|---|---|---|
| `tu`, `den` | T-TS | Không quá 31 ngày giữa hai mốc; trong 12 tháng | `2026-11-26T08:00`, `2026-11-26T09:00` |
| `consumerCode` | T-CODE | Consumer của tenant | `ht-qlvb` |
| `routeCode` | T-CODE | Route của tenant | `tra-cuu-ho-tich.v1` |
| `statusClass` | T-ENUM | `2xx`, `3xx`, `4xx`, `5xx` | `4xx` |
| `errorCode` | T-CODE | Mã `ERR-03-1xx` | `ERR-03-116` |
| `traceId` | T-ID | 32 ký tự hex | `4bf92f3577b34da6a3ce929d0e0e4736` |
| `srcIp` | T-IP | Chỉ khi có quyền | `10.20.30.40` |
| `sap-xep` | T-STR | `ts:giam` (mặc định) | `latencyMs:giam` |

: Bộ lọc nhật ký lượt gọi

#### FR-03-052 · Phát chỉ số và vết OpenTelemetry

::: dac-ta
**Mục đích.** Cung cấp cho PH-13 số liệu thời gian thực về lưu lượng, độ trễ, lỗi, từ chối, tình trạng từng thành phần của cổng, để dựng bảng điều khiển, cảnh báo và kiểm tra các chỉ tiêu NFR.

**Tác nhân, quyền.** Hệ thống (tự chạy); PO, PA, TA xem qua PH-13.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-13; NFR-00-050, NFR-00-051; ADR-011; SEC-43.

**Tiền điều kiện.** Cổng quản lý (management port) của APISIX mở chỉ cho Prometheus của PH-13 (chính sách mạng, SEC-14); plugin `prometheus` và `opentelemetry` bật.

**Kích hoạt.** Prometheus của PH-13 lấy mẫu mỗi 15 giây; mỗi lượt gọi phát span.

**Đầu vào.** Sự kiện của chuỗi chốt; bộ đếm của từng plugin.

**Luồng xử lý chính.**

1. Mỗi nút phơi ra chỉ số Prometheus ở cổng quản lý, không ở cổng dữ liệu.
2. Chỉ số theo bảng "Chỉ số của gateway" dưới đây, nhãn `tenant`, `route`, `consumer` tuân giới hạn số giá trị (tối đa 500 consumer khác nhau mỗi nhãn, phần còn lại gộp `other`) để tránh bùng nổ số chuỗi (giả định, Q03-08).
3. Mỗi lượt gọi phát span OTLP cho từng chốt chính (WAF, xác thực, hạn mức, OPA, upstream) gắn `traceId`; lấy mẫu thành công 5%, lỗi giữ 100% ở tail sampling của Collector (FR-03-032).
4. Hệ thống phát nhật ký hệ thống dạng JSON có `trace_id`, `tenant_id` (NFR-00-051), không chứa dữ liệu nhạy cảm.
5. PH-13 lưu chỉ số ở Mimir, vết ở Tempo, nhật ký ở Loki với nhãn `tenant` (SEC-84).
6. Chỉ số đến bảng điều khiển với độ trễ không quá 15 giây (NFR-03-021).

**Luồng thay thế.** Hồ sơ không có PH-13 đầy đủ (tỉnh nhỏ): chỉ số vẫn phơi ra để công cụ giám sát khác lấy.

**Luồng ngoại lệ.**

- Collector hoặc Prometheus không khả dụng: gateway đệm vết cục bộ có giới hạn và bỏ điểm cũ nhất khi đầy; chỉ số là kéo (pull) nên không mất khi Prometheus quay lại, chỉ thiếu điểm lấy mẫu.
- Số chuỗi chỉ số vượt trần: nhãn `consumer` gộp `other`, cảnh báo Trung bình.

**Đầu ra.** Chỉ số Prometheus; span OTLP; nhật ký JSON.

**Kết quả.** PH-13 có số liệu đủ để dựng bảng điều khiển và cảnh báo; chỉ tiêu NFR kiểm chứng được từ số liệu thật.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-007; BR-03-023.

**Màn hình, API.** UI-03-01; API-03-077.
:::

| Chỉ số | Loại | Nhãn | Ý nghĩa |
|---|---|---|---|
| `dh_gateway_requests_total` | Counter | `tenant`, `route`, `consumer`, `status_class` | Số lượt gọi |
| `dh_gateway_request_duration_seconds` | Histogram | `route` | Độ trễ tổng |
| `dh_gateway_upstream_duration_seconds` | Histogram | `route`, `upstream` | Độ trễ backend |
| `dh_gateway_added_latency_seconds` | Histogram | `route` | Độ trễ thêm của gateway (tổng trừ backend), cơ sở của KPI-04 |
| `dh_gateway_ratelimit_rejected_total` | Counter | `tenant`, `route`, `consumer`, `layer` | Lượt bị từ chối theo tầng hạn mức |
| `dh_gateway_waf_blocked_total` | Counter | `tenant`, `rule` | Lượt bị WAF chặn |
| `dh_gateway_auth_failed_total` | Counter | `tenant`, `reason` | Lượt thất bại xác thực |
| `dh_gateway_active_connections` | Gauge | `gate`, `node` | Kết nối đồng thời |
| `dh_gateway_config_version` | Gauge | `gate`, `node` | Phiên bản cấu hình đang chạy |
| `dh_gateway_valkey_up` | Gauge | `node` | Tình trạng Valkey |
| `dh_gateway_jwks_age_seconds` | Gauge | `node`, `realm` | Tuổi bộ đệm JWKS |
| `dh_gateway_breaker_state` | Gauge | `upstream` | Trạng thái ngắt mạch (0 đóng, 1 nửa mở, 2 mở) |
| `dh_gateway_tls_handshake_total` | Counter | `version`, `result` | Kết quả bắt tay TLS |
| `dh_gateway_synthetic_up` | Gauge | `check` | Kết quả kiểm tra tổng hợp |

: Chỉ số của gateway

#### FR-03-053 · Kiểm tra tổng hợp cho API quan trọng

::: dac-ta
**Mục đích.** Phát hiện sự cố của một API quan trọng trước khi người dân và HTTT gặp lỗi, bằng cách gọi thử đúng đường đi thật qua gateway mỗi phút và đo kết quả (SAD §4.3).

**Tác nhân, quyền.** Hệ thống (tự chạy); TA, TO cấu hình (`PERM-03-admin`); xem kết quả `PERM-03-read`.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-03, REQ-13; D03-01 §4.3 (kiểm tra tổng hợp mỗi phút); KPI-03.

**Tiền điều kiện.** API được PH-02 đánh dấu `critical`; có consumer kiểm tra `dh-synthetic-{tenant}` với phạm vi chỉ-đọc và gói riêng (hạn mức tách khỏi HTTT thật); bộ chạy kiểm tra (hồ sơ `probe` của `dh-runtime`) chạy ở data plane.

**Kích hoạt.** Bộ lập lịch của bộ chạy kiểm tra, mỗi 60 giây cho mỗi kiểm tra.

**Đầu vào.** `checkCode`, `routeCode`, `method`, `path`, `expectedStatus[]`, `expectedBodyJsonPath` (tùy chọn), `timeoutMs` (10.000), `intervalSeconds` (60).

**Luồng xử lý chính.**

1. TA khai báo kiểm tra cho một API quan trọng bằng yêu cầu chỉ-đọc không có tác dụng phụ (API không có yêu cầu an toàn thì không được khai báo).
2. Cấu hình kiểm tra được phát tới bộ chạy kiểm tra qua ảnh chụp hoặc ConfigMap; bộ chạy không cần `dh-connect` khi chạy.
3. Mỗi phút bộ chạy lấy token của consumer kiểm tra từ Keycloak (bí mật từ OpenBao) rồi gọi API qua địa chỉ thật của cửa vào.
4. Bộ chạy so mã trả về và nội dung kỳ vọng, đo độ trễ; ghi `dh_gateway_synthetic_up{check}` và `dh_gateway_synthetic_duration_seconds{check}`.
5. Hai lần thất bại liên tiếp thì phát cảnh báo Cao tới TO (FR-03-054); lượt gọi kiểm tra được đánh dấu `synthetic = true` ở nhật ký và bị loại khỏi báo cáo sử dụng.
6. Kết quả hiển thị ở UI-03-01 theo từng kiểm tra: lên, xuống, độ trễ, thời điểm thất bại gần nhất.

**Luồng thay thế.** API cần dữ liệu đầu vào đặc thù: dùng đối tượng kiểm tra do chủ dịch vụ cung cấp, ghi rõ ở cấu hình kiểm tra.

**Luồng ngoại lệ.**

- Thiếu consumer kiểm tra hoặc gói: ERR-03-001 (404), "Chưa có consumer kiểm tra cho tỉnh. Tạo consumer kiểm tra trước."
- Yêu cầu không an toàn (phương thức ghi) bị khai báo: ERR-03-003 (400), "Kiểm tra tổng hợp chỉ dùng phương thức đọc (GET, HEAD)."
- Kiểm tra vượt hạn mức riêng: bộ chạy giảm tần suất, cảnh báo Trung bình.

**Đầu ra.** Chỉ số kết quả kiểm tra; `200` cho danh sách kiểm tra `{checkCode, state, lastOkAt, lastFailAt, p95Ms}`.

**Kết quả.** Sự cố API quan trọng được phát hiện trong dưới 3 phút, trước khi người dùng báo.

**Hậu điều kiện.** Có lịch kiểm tra; không đổi dữ liệu nghiệp vụ.

**Sự kiện phát ra.** EVT-03-09 khi kiểm tra thất bại liên tiếp.

**Kiểm toán.** Có khi tạo, sửa, xóa kiểm tra.

**Quy tắc nghiệp vụ.** BR-03-027.

**Màn hình, API.** UI-03-01; API-03-080, API-03-081, API-03-082, API-03-083.
:::

#### FR-03-054 · Cảnh báo sự kiện an ninh tại gateway

::: dac-ta
**Mục đích.** Báo kịp thời cho Cán bộ ATTT và vận hành khi gateway cho thấy dấu hiệu tấn công hoặc suy giảm an ninh (WAF chặn dồn dập, dò khóa, truy cập chéo tenant, cấu hình bị giả mạo, chứng thư sắp hết hạn), và đẩy sự kiện ra SIEM của tỉnh (SEC-63, SEC-64).

**Tác nhân, quyền.** SO, TO, TA nhận cảnh báo; xác nhận cảnh báo `PERM-03-operate`; xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; SEC-61, SEC-63, SEC-64; CMP-LAW-16; KPI-15.

**Tiền điều kiện.** Chỉ số và sự kiện an ninh của gateway đã về PH-13 (FR-03-050, 052); luật cảnh báo cài ở PH-13.

**Kích hoạt.** Luật cảnh báo của PH-13 khớp theo bảng "Luật cảnh báo của gateway" dưới đây.

**Đầu vào.** Chỉ số, nhật ký an ninh, sự kiện EVT-03-09; ngưỡng theo luật.

**Luồng xử lý chính.**

1. PH-13 đánh giá luật mỗi phút trên chỉ số và nhật ký của gateway.
2. Luật khớp thì PH-13 tạo cảnh báo có mức độ, loại, đối tượng, số liệu minh chứng, khoảng thời gian; cảnh báo cùng loại và đối tượng trong 15 phút được gộp.
3. PH-13 thông báo trong ứng dụng (FR-00-060) và thư điện tử tới SO, TO của tenant tùy mức độ; mức Nghiêm trọng thêm kênh đẩy ra SIEM qua syslog RFC 5424 hoặc OTLP (IF-08).
4. Người dùng mở UI-03-01 hoặc UI-03-07 xem cảnh báo, liên kết tới nhật ký và sự kiện chặn liên quan.
5. Người có `PERM-03-operate` bấm "Xác nhận" kèm ghi chú; cảnh báo chuyển `ACKNOWLEDGED`, tiếp tục theo dõi tới khi hết điều kiện.
6. Mục tiêu thời gian phát hiện (MTTD) luật Nghiêm trọng ≤ 5 phút (SEC-64).

**Luồng thay thế.** Tỉnh chưa có SIEM: dùng bộ luật trên Loki và Grafana trong gói Datahub (SEC-63).

**Luồng ngoại lệ.**

- PH-13 không khả dụng: gateway vẫn chạy; cảnh báo không phát được, `dh-connect` hiển thị "chưa có số liệu cảnh báo" (ERR-03-026 khi gọi API).
- Cảnh báo trùng quá nhiều: gộp theo loại và đối tượng, không gửi lặp.

**Đầu ra.** `200`, danh sách cảnh báo `{alertId, severity, type, target, evidence, since, state}`; `200` khi xác nhận.

**Kết quả.** Đội ATTT biết trong vài phút khi gateway bị tấn công hoặc suy giảm; sự kiện ra SIEM đủ để điều tra.

**Hậu điều kiện.** Bản ghi cảnh báo ở PH-13.

**Sự kiện phát ra.** EVT-03-09.

**Kiểm toán.** Có khi xác nhận: người, thời điểm, ghi chú.

**Quy tắc nghiệp vụ.** BR-03-007.

**Màn hình, API.** UI-03-01, UI-03-07; API-03-084, API-03-085.
:::

| Luật | Điều kiện | Mức | Người nhận |
|---|---|---|---|
| GW-A01 | WAF chặn trên một route vượt 100 lượt/phút hoặc gấp 10 lần mức nền 24 giờ | Cao | SO, TO |
| GW-A02 | Thất bại xác thực từ một consumer hoặc một địa chỉ vượt 50 lượt/phút | Cao | SO |
| GW-A03 | Có bất kỳ lượt truy cập chéo tenant (ERR-03-106 do tenant route khác tenant token) | Nghiêm trọng | SO |
| GW-A04 | Token có `cnf` không khớp chứng thư kết nối (ERR-03-108) từ 3 lượt trong 10 phút | Nghiêm trọng | SO |
| GW-A05 | Nút từ chối ảnh chụp do chữ ký hoặc hash sai | Nghiêm trọng | SO, PA |
| GW-A06 | WAF tự hạ về chế độ phát hiện do quá tải (FR-03-006) | Nghiêm trọng | SO, PA |
| GW-A07 | Valkey không khả dụng quá 1 phút (FR-03-026) | Cao | PO, TO |
| GW-A08 | JWKS không làm mới được quá 1 giờ, hoặc OPA không phản hồi (ERR-03-124) | Nghiêm trọng | PA, SO |
| GW-A09 | Nút `LAGGING` hoặc `FAILED` quá 2 phút (FR-03-045) | Cao | PO, PA |
| GW-A10 | Chứng thư biên còn dưới 7 ngày (FR-03-049) | Nghiêm trọng | PA |
| GW-A11 | Kiểm tra tổng hợp thất bại hai lần liên tiếp (FR-03-053) | Cao | TO |
| GW-A12 | Tenant dùng trên 80% hạn mức tenant liên tục 1 phút (FR-03-023) | Trung bình | TA |
| GW-A13 | Nhật ký lượt gọi bị bỏ do bộ đệm đầy (FR-03-050) | Cao | PO |

: Luật cảnh báo của gateway

#### FR-03-055 · Bảng điều khiển lưu lượng gateway

::: dac-ta
**Mục đích.** Cho vận hành và lãnh đạo thấy ngay sức khỏe của cổng: bao nhiêu lượt gọi, bao nhiêu lỗi, ai gọi nhiều nhất, route nào chậm, bao nhiêu lượt bị chặn, và các thành phần của cổng có khỏe không. Thay cho "dashboard hoạt động chung" của hệ cũ ở phần gateway.

**Tác nhân, quyền.** Mọi vai trò có `PERM-03-read` (PA, PO, TA, TO, SO, AU).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03, REQ-13; LGC-APIM-026 (phần gateway); NFR-00-001, NFR-00-062; KPI-03, KPI-04.

**Tiền điều kiện.** Chỉ số và siêu dữ liệu đã về PH-13; người dùng đã chọn tenant.

**Kích hoạt.** Người dùng mở UI-03-01.

**Đầu vào.** `khoang` (`15m`, `1h`, `24h`, `7d`), `routeCode` và `consumerCode` (lọc tùy chọn).

**Luồng xử lý chính.**

1. Hệ thống truy vấn PH-13 lấy tóm tắt khoảng thời gian (API-03-077).
2. Hệ thống hiển thị năm thẻ: lượt gọi mỗi giây, tỉ lệ lỗi, độ trễ thêm p95 (so mục tiêu 50 ms), kết nối đang mở, tình trạng nút (số nút `IN_SYNC` trên tổng).
3. Hệ thống hiển thị biểu đồ lưu lượng theo thời gian, tách `2xx`, `4xx`, `5xx` và phần bị từ chối của gateway (WAF, hạn mức, xác thực).
4. Hệ thống hiển thị bảng xếp hạng HTTT theo lưu lượng kèm mức dùng so với hạn mức, và bảng xếp hạng route theo lưu lượng và độ trễ (API-03-078, API-03-079).
5. Hệ thống hiển thị thẻ cảnh báo đang mở (FR-03-054), kết quả kiểm tra tổng hợp (FR-03-053), và cờ Valkey, JWKS, chế độ WAF.
6. Màn hình tự làm mới 15 giây; nhấn một HTTT hoặc route thì lọc toàn trang; nhấn cột lỗi mở nhật ký (FR-03-051) đã lọc sẵn.

**Luồng thay thế.** PA, PO xem tổng hợp liên tenant chỉ ở mức tổng (không có chi tiết từng tenant); xem chi tiết một tenant khác phải đi đường truy cập liên tenant có lý do (SEC-85) nằm ngoài PH-03.

**Luồng ngoại lệ.**

- PH-13 không khả dụng: ERR-03-026 (503), "Chưa lấy được số liệu lưu lượng. Thử lại sau." Màn hình hiển thị trạng thái "không có số liệu", không hiển thị số 0 gây hiểu nhầm.
- Khoảng thời gian không hợp lệ: ERR-03-003 (400).

**Đầu ra.** `200`, `{cards, series, topConsumers, topRoutes, alerts, nodes}`.

**Kết quả.** Vận hành nắm tình hình cổng trong một màn hình, với độ trễ số liệu không quá 15 giây.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-03-028.

**Màn hình, API.** UI-03-01; API-03-077, API-03-078, API-03-079.
:::

### 6.8. Nhóm G · Quản trị

Nhóm G gom các chức năng hỗ trợ: tham số theo tenant, chạy thử chính sách trước khi phát, báo cáo sử dụng và nhập cấu hình từ gateway cũ để chuyển đổi dần.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm G"}
flowchart TB
  F056["FR-03-056 Tham số theo tenant"] --> F039["FR-03-039 Tổng hợp (nhóm E)"]
  F057["FR-03-057 Chạy thử chính sách"] -.-> F040["FR-03-040 Kiểm tra hợp lệ"]
  F059["FR-03-059 Nhập từ gateway cũ"] --> PH2["Đề xuất cho PH-02, PH-01"]
  F058["FR-03-058 Báo cáo sử dụng"] --> F051["FR-03-051 Nhật ký lượt gọi"]
```

#### FR-03-056 · Tham số gateway theo tenant

::: dac-ta
**Mục đích.** Cho quản trị tenant chỉnh các tham số vận hành của gateway (giới hạn theo địa chỉ, thời hạn chờ mặc định, lấy mẫu vết, thời gian giữ, ngưỡng cảnh báo) trong miền nền tảng cho phép, mà không phải sửa mã hay cấu hình tay.

**Tác nhân, quyền.** PA đặt trần nền tảng; TA chỉnh trong trần (`PERM-03-admin`); xem `PERM-03-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-03; NFR-00-052; D03-10 §5.3; FR-00 tham số (PH-18).

**Tiền điều kiện.** Có bảng tham số mặc định ở chương 8.2; tenant đang `ACTIVE`.

**Kích hoạt.** Quản trị mở UI-03-16 và bấm "Lưu".

**Đầu vào.** Bộ cặp `{khóa, giá trị}` thuộc bảng tham số chương 8.2; `If-Match` (ETag).

**Luồng xử lý chính.**

1. Hệ thống hiển thị tham số hiện hành kèm mặc định, miền, trần nền tảng, người sửa gần nhất.
2. Quản trị sửa giá trị; hệ thống kiểm tra từng giá trị theo kiểu, miền và trần (sai: ERR-03-003; vượt trần: ERR-03-018).
3. Hệ thống kiểm tra `If-Match`: ETag cũ nghĩa là có người sửa trước (xung đột: ERR-03-004, FR-00-052).
4. Tham số thuộc nhóm rủi ro cao (`gw.waf.mode`, `gw.tenantRateLimit.perSecond`, `exposure`) không đổi ở đây mà đi theo chức năng riêng có bốn mắt (FR-03-006, 023, 038); thử đổi ở đây nhận ERR-03-003.
5. Hệ thống lưu giá trị mới có phiên bản, ghi kiểm toán, và kích hoạt tổng hợp (FR-03-039) khi tham số ảnh hưởng cấu hình gateway.
6. Giá trị có hiệu lực trong 60 giây (NFR-00-052), thường dưới 10 giây.

**Luồng thay thế.** Đặt lại về mặc định cho một khóa: xóa giá trị riêng của tenant, ảnh chụp mới dùng mặc định nền tảng.

**Luồng ngoại lệ.**

- Giá trị sai kiểu hoặc ngoài miền: ERR-03-003 (400), "Giá trị của {khóa} phải thuộc {miền}."
- Vượt trần nền tảng: ERR-03-018 (422), "{khóa} không được vượt {trần} theo hợp đồng của tỉnh."
- ETag cũ: ERR-03-004 (412), "Tham số vừa được người khác sửa. Tải lại để xem thay đổi."

**Đầu ra.** `200`, bộ tham số hiệu lực kèm `ETag`.

**Kết quả.** Gateway của tỉnh chạy với tham số phù hợp điều kiện thực tế mà vẫn trong khuôn khổ an toàn nền tảng.

**Hậu điều kiện.** Tham số mới trong ảnh chụp đang chạy.

**Sự kiện phát ra.** EVT-03-11 khi đổi tham số hạn mức; còn lại đi theo EVT-03-01.

**Kiểm toán.** Có: khóa, giá trị trước và sau, người sửa.

**Quy tắc nghiệp vụ.** BR-03-016; BR-03-019.

**Màn hình, API.** UI-03-16; API-03-086, API-03-087.
:::

#### FR-03-057 · Chạy thử chính sách bằng mô phỏng

::: dac-ta
**Mục đích.** Cho quản trị và Cán bộ ATTT biết một yêu cầu giả định sẽ đi qua gateway như thế nào, chốt nào chặn, chính sách nào áp dụng, mà không gửi yêu cầu thật và không tăng bộ đếm. Dùng trước khi phát cấu hình hoặc khi điều tra vì sao một HTTT bị chặn.

**Tác nhân, quyền.** TA, SO, PA (`PERM-03-admin`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03; SEC-26, SEC-42; BR-03-027.

**Tiền điều kiện.** Có ảnh chụp đang chạy hoặc ảnh chụp `BUILT` để mô phỏng; gói chính sách OPA hiện hành.

**Kích hoạt.** Quản trị mở UI-03-14 và bấm "Chạy thử".

**Đầu vào.** Theo bảng "Dữ liệu vào của FR-03-057" dưới đây.

**Luồng xử lý chính.**

1. Quản trị nhập yêu cầu giả định và chọn ảnh chụp để mô phỏng (mặc định: đang chạy).
2. Hệ thống kiểm tra đầu vào không chứa bí mật thật (không nhập token thật; chỉ nhập claim giả định) (vi phạm: ERR-03-003).
3. Bộ mô phỏng của `dh-connect` đi qua từng chốt theo thứ tự ở mục 2.4 trên mô hình cấu hình: chọn route, phương thức bảo mật, đăng ký, scope, đường dẫn, hạn mức hiệu lực.
4. Với WAF, bộ mô phỏng chạy Coraza ở chế độ thử trên mẫu yêu cầu; với OPA, chạy đánh giá khô với gói chính sách hiện hành.
5. Hệ thống không gọi backend, không đọc hay ghi bộ đếm Valkey; phần hạn mức chỉ báo cấu hình hiệu lực, không báo còn lại bao nhiêu.
6. Hệ thống trả kết quả từng chốt: `PASS`, `BLOCK` hoặc `SKIP`, mã lỗi, lý do, chính sách áp dụng, và tóm tắt "nếu gửi thật sẽ nhận mã HTTP nào".

**Luồng thay thế.** Mô phỏng trên ảnh chụp `BUILT` (chưa phát): so sánh kết quả với ảnh chụp đang chạy để biết thay đổi có làm đổi kết quả của yêu cầu mẫu không.

**Luồng ngoại lệ.**

- Đầu vào có token hoặc khóa thật: ERR-03-003 (400), "Không nhập token hoặc khóa thật. Chỉ nhập phạm vi (scope) và thông tin giả định."
- Ảnh chụp chọn không còn: ERR-03-001 (404).

**Đầu ra.** `200`, `{matchedRoute, steps[], expectedStatus, effectivePolicies}`.

**Kết quả.** Quản trị hiểu và kiểm thử được chính sách trước khi áp dụng, không gây tác động nào lên lưu lượng thật.

**Hậu điều kiện.** Không đổi dữ liệu (không ghi bộ đếm).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người chạy, yêu cầu giả định (đã che), ảnh chụp, kết quả tóm tắt.

**Quy tắc nghiệp vụ.** BR-03-027.

**Màn hình, API.** UI-03-14; API-03-088.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `host` | T-STR | Có | Host của tenant | `api.t68.datahub.gov.vn` |
| `method`, `path` | T-STR | Có | Phương thức HTTP; đường dẫn | `GET`, `/api/hotich/v1/ho-tich/123` |
| `consumerCode` | T-CODE | Không | Mô phỏng danh tính | `ht-qlvb` |
| `claims` | T-JSON | Không | `scope`, `tenant`, `cnf` giả định; không có chữ ký | `{"scope":"hotich.read"}` |
| `headers` | T-JSON | Không | Tiêu đề không nhạy cảm | `{"Content-Type":"application/json"}` |
| `bodySample` | T-TEXT | Không | ≤ 32 KiB, chỉ để thử WAF và lược đồ | `{"hoTen":"Nguyen Van A"}` |
| `snapshotVersion` | T-INT | Không | Mặc định ảnh chụp đang chạy | 10412 |

: Dữ liệu vào của FR-03-057

#### FR-03-058 · Báo cáo sử dụng API theo HTTT và gói

::: dac-ta
**Mục đích.** Cho chủ dịch vụ, quản trị tenant và lãnh đạo thấy HTTT nào dùng API nào bao nhiêu, tỉ lệ lỗi, mức dùng so với hạn ngạch, để lập kế hoạch năng lực và rà soát đăng ký. Chỉ phục vụ bảo vệ hệ thống và thống kê, không để tính tiền (BR-03-020).

**Tác nhân, quyền.** TA, TO, SO, AU (`PERM-03-read`); xuất báo cáo cần `PERM-03-log-read`.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-03, REQ-13, REQ-16; LGC-APIM-022; NFR-00-062; FR-00-030, FR-00-031.

**Tiền điều kiện.** Bản tổng hợp theo ngày của siêu dữ liệu lượt gọi có ở PH-13.

**Kích hoạt.** Người dùng mở báo cáo ở UI-03-01 (tab "Báo cáo sử dụng") và chọn kỳ.

**Đầu vào.** `kyBaoCao` (`ngay`, `thang`), `tu`, `den`, `groupBy` (`CONSUMER`, `ROUTE`, `PLAN`), lọc `consumerCode`, `routeCode`.

**Luồng xử lý chính.**

1. Người dùng chọn kỳ, nhóm theo và bộ lọc.
2. Hệ thống kiểm tra khoảng thời gian không quá 12 tháng (vi phạm: ERR-03-021).
3. Hệ thống truy vấn bản tổng hợp ngày ở PH-13 theo tenant của token; loại các lượt `synthetic`.
4. Hệ thống tính mỗi nhóm: số lượt, tỉ lệ `4xx`, `5xx`, p95 độ trễ, byte vào ra, số lượt bị từ chối theo lý do, mức dùng so với hạn ngạch.
5. Hệ thống hiển thị bảng và biểu đồ; trên 10.000 dòng thì chạy nền khi xuất (FR-00-031).
6. Người có `PERM-03-log-read` xuất tệp xlsx hoặc CSV (UTF-8 có BOM); xuất có kiểm toán (FR-00-030).

**Luồng thay thế.** Chủ dịch vụ chỉ muốn xem HTTT dùng API của mình: bộ lọc route lấy theo API thuộc tổ chức của họ (ROLE-SERVICE_OWNER ở PH-02).

**Luồng ngoại lệ.**

- Khoảng thời gian quá 12 tháng: ERR-03-021 (400), "Báo cáo chỉ gồm 12 tháng gần nhất."
- PH-13 không khả dụng: ERR-03-026 (503).

**Đầu ra.** `200`, `items[]` theo nhóm, `totals`; `202` khi xuất kèm `exportId`.

**Kết quả.** Đủ số liệu để rà soát đăng ký sử dụng và lập kế hoạch năng lực.

**Hậu điều kiện.** Không đổi dữ liệu (tạo tệp xuất khi xuất).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có cho xuất: người, kỳ, bộ lọc, số dòng.

**Quy tắc nghiệp vụ.** BR-03-020; BR-03-028.

**Màn hình, API.** UI-03-01; API-03-089, API-03-090.
:::

#### FR-03-059 · Nhập cấu hình từ gateway cũ

::: dac-ta
**Mục đích.** Hỗ trợ chuyển đổi dần (strangler) từ gateway cũ: đọc gói xuất cấu hình của hệ cũ (API, plan, application, subscription) và biến thành đề xuất cấu hình mới cho PH-02, PH-01 và bảng ánh xạ để chạy song song, không phải khai lại thủ công hàng trăm API.

**Tác nhân, quyền.** PA, TA (`PERM-03-admin`); PH-02, PH-01 nhận đề xuất.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-22; LGC-APIM-002…005, 009…015, 019…021; FR-00-090, FR-00-093; D06-01.

**Tiền điều kiện.** Có gói xuất cấu hình của hệ cũ (JSON) hoặc quyền đọc chỉ-đọc cấu hình gateway cũ qua cầu nối chuyển đổi; tenant đang ở giai đoạn chuyển đổi.

**Kích hoạt.** Quản trị tải gói ở UI-03-18 và bấm "Phân tích".

**Đầu vào.** Tệp gói xuất (≤ 50 MiB), `tenant` (từ token), `mappingMode` (`PROPOSE_ONLY` mặc định).

**Luồng xử lý chính.**

1. Quản trị tải gói; hệ thống quét mã độc (DD-12), kiểm tra định dạng và kích thước (sai: ERR-03-020).
2. Hệ thống phân tích: danh sách API (tên, phiên bản, `context-path`, backend), plan (Keyless, API key; rate limit; quota; whitelist, blacklist), application, subscription.
3. Hệ thống ánh xạ sang mô hình mới: API tới đề xuất API ở PH-02 với mã route đề xuất; plan tới `securityMode` và hạn mức, hạn ngạch, đường dẫn; application tới đề xuất HTTT, consumer ở PH-01.
4. Hệ thống **không nhập khóa API hay thông tin xác thực của hệ cũ** (FR-00-093); mọi HTTT dùng API key được gắn cờ "cấp lại thông tin xác thực OAuth 2.1 hoặc mTLS"; plan Keyless cho API không phải dữ liệu mở được gắn cờ cần quyết định.
5. Hệ thống lập báo cáo phân tích: số API, plan, application, subscription; mục không ánh xạ được (chính sách tùy biến, bộ biến đổi); cảnh báo xung đột mã; người dùng xem, sửa ánh xạ.
6. Khi người dùng bấm "Áp dụng", hệ thống gửi đề xuất tới PH-02 và PH-01 qua API của họ (mỗi đề xuất vào hàng chờ duyệt thường lệ), lưu bảng `legacyMap` (API cũ sang route mới, plan cũ sang policy mới) để so sánh khi chạy song song.

**Luồng thay thế.** Chỉ phân tích, không áp dụng: dùng để ước lượng khối lượng chuyển đổi và danh sách HTTT phải cấp lại thông tin xác thực.

**Luồng ngoại lệ.**

- Gói không đọc được hoặc thiếu trường bắt buộc: ERR-03-020 (422), "Gói cấu hình hệ cũ không đọc được: {lý do}."
- Tệp chứa mã độc: ERR-03-020 với lý do "tệp bị từ chối bởi bộ quét".
- PH-02 hoặc PH-01 không nhận đề xuất: kết quả áp dụng từng phần, báo cáo nêu mục chưa gửi, có thể áp dụng lại.

**Đầu ra.** `201`, `{importId, state, summary}`; báo cáo phân tích; sau áp dụng, danh sách đề xuất đã gửi.

**Kết quả.** Khối lượng khai báo thủ công giảm mạnh; danh sách HTTT phải cấp lại thông tin xác thực rõ ràng; có ánh xạ cũ sang mới cho chạy song song.

**Hậu điều kiện.** Bản ghi nhập và `legacyMap`; không đổi cấu hình gateway đang chạy.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người nhập, tệp (hash), số lượng, kết quả, đề xuất đã gửi.

**Quy tắc nghiệp vụ.** BR-03-014; BR-03-029.

**Màn hình, API.** UI-03-18; API-03-091, API-03-092, API-03-093.
:::

## 7. Quy tắc nghiệp vụ

Quy tắc dưới đây ràng buộc nhiều chức năng; cột "FR áp dụng" ghi số của `FR-03-…`. Ba quy tắc BR-03-009, BR-03-011 và BR-03-017 thay đổi hoặc bổ sung so với SRS cũ và được nêu rõ lý do ở mục 11.3.

| Mã | Quy tắc | FR áp dụng |
|---|---|---|
| BR-03-001 | Mọi lượt gọi vào Datahub, kể cả từ giao diện quản trị, đi qua APISIX; không có đường tắt tới backend. Chính sách mạng chỉ cho phép backend nhận lưu lượng từ APISIX (SEC-14, SEC-15) | 001, 002, 003, 005, 028, 029, 033 |
| BR-03-002 | Tenant của lượt gọi chỉ lấy từ token đã xác minh; mọi tiêu đề `X-DH-*` do bên gọi gửi bị xóa trước khi gateway đặt tiêu đề nội bộ | 012, 013 |
| BR-03-003 | Biên chỉ chấp nhận TLS 1.3; TLS 1.2 chỉ trên host chuyên dụng có ngoại lệ có hạn tối đa 180 ngày; không bao giờ dưới TLS 1.2 | 001, 002, 049 |
| BR-03-004 | Token được xác minh cục bộ bằng JWKS đã đệm, không gọi Keycloak cho từng lượt gọi; token của HTTT mức Nhạy cảm phải ràng buộc chứng thư (`cnf`) | 002, 012, 014, 015 |
| BR-03-005 | Hạn mức chính tính theo HTTT (consumer), không theo địa chỉ IP, vì nhiều HTTT dùng chung địa chỉ sau NAT; giới hạn theo IP chỉ là lớp ngoài cùng | 003, 004, 021, 023, 024 |
| BR-03-006 | Ngoại lệ luật WAF phải có lý do, gắn một route và một mã luật, hạn tối đa 90 ngày, người duyệt là Cán bộ ATTT khác người đề nghị; không có ngoại lệ vĩnh viễn | 007, 008 |
| BR-03-007 | Gateway không ghi thân bản tin, giá trị tiêu đề xác thực hay giá trị tham số truy vấn vào bất kỳ nhật ký nào; chỉ ghi siêu dữ liệu | 005, 050, 051, 052, 054 |
| BR-03-008 | Gateway chỉ kiểm soát truy cập thô (token, đăng ký, phạm vi, đường dẫn, hạn mức) và gọi OPA; quyết định chi tiết theo tài nguyên, mức phân loại, mục đích do OPA và DU ra | 017, 019 |
| BR-03-009 | Consumer nhóm `ESSENTIAL` được ưu tiên: hệ số nới tần suất, không bị chặn đột ngột khi vượt hạn ngạch chu kỳ (cảnh báo, tối đa 20% vượt), và không bị điều tiết khi backend yếu | 021, 022, 027 |
| BR-03-010 | Mọi thay đổi cấu hình được nạp nóng, không khởi động lại nút và không làm lỗi lượt gọi nào; nút chỉ chuyển cấu hình khi bản mới đã qua kiểm tra | 006, 036, 042, 043 |
| BR-03-011 | Khi mọi backend của một upstream không khỏe hoặc mạch đã mở, gateway trả lỗi nhanh `503` kèm `Retry-After` và thăm dò định kỳ; không dồn lưu lượng vào backend đã hỏng (khác SRS cũ, Q03-03) | 029, 030, 031 |
| BR-03-012 | Không dùng ký tự đại diện cho nguồn gốc CORS; chỉ nguồn gốc liệt kê đầy đủ | 010 |
| BR-03-013 | Phản hồi không lộ tên hay phiên bản phần mềm; tiêu đề `Server`, `X-Powered-By` bị xóa hoặc thay bằng giá trị chung | 011 |
| BR-03-014 | Route chỉ được phát khi có lược đồ OpenAPI đã duyệt, chính sách OPA tồn tại và phương thức bảo mật hợp lệ với mức phân loại dữ liệu | 009, 015, 019, 020, 040, 048, 059 |
| BR-03-015 | Mặc định route chỉ ở cửa mạng nội bộ (`INT`); mở ra cửa Internet (`EXT`) cần Cán bộ ATTT duyệt, có lý do, và đủ điều kiện (WAF chế độ chặn, bắt buộc xác thực) | 038 |
| BR-03-016 | Cấu hình gateway chỉ thay đổi qua ảnh chụp có số phiên bản và chữ ký của control plane; cấm sửa trực tiếp trên pod; lệch so với Git bị phát hiện trong 1 giờ (SEC-65) | 039, 041, 042, 043, 044, 045, 049, 056 |
| BR-03-017 | Chỉ chạy plugin và mẫu chính sách trong danh mục được duyệt (kể cả plugin do Datahub viết, ký cùng ảnh); không có đường tải plugin hay mã Lua của tenant | 020, 034, 040, 048 |
| BR-03-018 | Số phiên bản ảnh chụp tăng đơn điệu; nút từ chối phiên bản không lớn hơn bản đang chạy; quay lui sinh ảnh chụp mới có nội dung cũ, không đưa phiên bản cũ trở lại | 041, 043, 044 |
| BR-03-019 | Bốn thay đổi rủi ro cao trực tiếp ở PH-03 cần người thứ hai duyệt: ngoại lệ hoặc luật vá WAF, đổi chế độ WAF, mở route ra cửa Internet, hạ hạn mức toàn tenant; người đề nghị không tự duyệt | 006, 007, 008, 023, 024, 038, 056 |
| BR-03-020 | Hạn ngạch chỉ để bảo vệ hệ thống và thống kê, không dùng để tính tiền (kế thừa nguyên tắc chia sẻ dữ liệu giữa cơ quan nhà nước không thu phí; cần đối chiếu NĐ 278/2025, Q03-10) | 022, 058 |
| BR-03-021 | Thu hồi token, tạm ngừng consumer hoặc route có hiệu lực không quá 60 giây (mục tiêu 30 giây), không chờ token hết hạn | 016, 018, 046, 047 |
| BR-03-022 | Một HTTT có thể có nhiều client; mỗi client là một consumer; tạm ngừng HTTT ở PH-01 kéo theo mọi consumer của nó | 014, 016, 046 |
| BR-03-023 | Lỗi do gateway sinh dùng RFC 9457, luôn có `code` dạng `ERR-03-1xx` và `X-Trace-Id`; không có vết ngăn xếp, tên máy hay đường dẫn nội bộ | 004, 009, 011, 019, 025, 032, 050, 052 |
| BR-03-024 | Route có hạn mức trả `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` trên mọi phản hồi, kể cả thành công | 021, 025 |
| BR-03-025 | Khi Valkey không khả dụng, hạn ngạch mở có cảnh báo, tần suất và hạn mức tenant đếm cục bộ theo số bản sao; danh sách chặn token dùng bộ đệm gần nhất | 018, 026 |
| BR-03-026 | Host hoặc tiền tố đường dẫn gắn với đúng một tenant; không có hai route của hai tenant trùng host và đường dẫn; route của tenant này không bao giờ khớp lượt gọi của tenant khác | 013, 028, 037, 039, 040 |
| BR-03-027 | Chạy thử chính sách và kiểm tra tổng hợp không tăng bộ đếm hạn mức của HTTT thật và không gọi backend ngoài phạm vi kiểm tra đã khai; lượt kiểm tra tổng hợp được đánh dấu và loại khỏi báo cáo | 053, 057 |
| BR-03-028 | Đối tượng, nhật ký, báo cáo của tenant khác được trả như không tồn tại (`404`, cùng thân), không tiết lộ sự tồn tại | 013, 051, 055, 058 |
| BR-03-029 | Mã route, consumer, chính sách, ngoại lệ là bất biến và không dùng lại sau khi gỡ; gỡ là xóa mềm | 036, 047, 059 |
| BR-03-030 | Phiên bản API cũ được phục vụ song song tối thiểu 180 ngày sau khi công bố ngừng dùng (NFR-00-055), có tiêu đề `Deprecation`, `Sunset`; tenant sáp nhập được chuyển tiếp mặc định 180 ngày | 035, 037 |

: Quy tắc nghiệp vụ của PH-03

## 8. Tham số và yêu cầu phi chức năng

### 8.1. Yêu cầu phi chức năng

Các chỉ tiêu dưới đây kế thừa NFR-00 của hệ thống khi có, và đặt chặt hơn cho riêng gateway khi gateway là điểm vào duy nhất; chỉ tiêu nào do tài liệu này đề xuất mà chưa có số liệu thật được ghi "giả định" kèm cơ sở. Điều kiện đo dùng hồ sơ "tỉnh vừa" (GĐ-07): 200 HTTT, cao điểm 300 lượt/giây, ba bản sao APISIX mỗi cửa.

| Mã | Yêu cầu | Chỉ tiêu | Điều kiện đo |
|---|---|---|---|
| NFR-03-001 | Độ trễ thêm tại gateway (từ khi APISIX nhận tới khi chuyển cho backend, đã gồm WAF) | p95 ≤ 50 ms, p99 ≤ 100 ms ở 300 lượt/giây (NFR-00-001, KPI-04) | k6, chỉ số `dh_gateway_added_latency_seconds` |
| NFR-03-002 | Chi phí từng chốt | Xác minh JWT p99 ≤ 2 ms; kiểm tra hạn mức p99 ≤ 3 ms; OPA p99 ≤ 2 ms (SEC-26); WAF ≤ 5 ms với yêu cầu ≤ 32 KB (giả định, cơ sở: SRS cũ, NFR số 004, 005, 006) | Đo tại plugin, có và không bật từng chốt |
| NFR-03-003 | Thông lượng | ≥ 1.000 lượt/giây trên 3 bản sao với đủ chuỗi plugin, tỉ lệ lỗi do nền tảng < 0,1% (NFR-00-002); năng lực danh định 3.000 lượt/giây (D03-09 §5) | k6, 30 phút |
| NFR-03-004 | Kết nối đồng thời | ≥ 20.000 mỗi bản sao (giả định, cơ sở: SRS cũ, NFR số 007) | Kiểm thử tải kết nối |
| NFR-03-005 | Sẵn sàng của gateway | ≥ 99,95% mỗi tháng, chặt hơn KPI-03 (99,9%) vì là điểm vào duy nhất (giả định, cơ sở: SRS cũ, NFR số 008) | Kiểm tra tổng hợp mỗi phút (FR-03-053) |
| NFR-03-006 | Số bản sao và phân bố | Mỗi cửa vào tối thiểu 3 bản sao, `maxUnavailable: 1`, trải ≥ 2 vùng sẵn sàng; mất một vùng thì độ trễ tăng ≤ 50% (giả định, cơ sở: SRS cũ, kịch bản AT-03-031) và không mất dịch vụ | Kiểm thử hỗn loạn tắt một vùng |
| NFR-03-007 | Tiếp tục phục vụ khi control plane hoặc nguồn bên ngoài ngừng | ≥ 24 giờ khi `dh-connect`, Argo CD, Git, bucket hoặc Keycloak ngừng (NFR-00-012); pod khởi động lại trong thời gian đó vẫn có cấu hình | Kiểm thử hỗn loạn tắt toàn bộ control plane |
| NFR-03-008 | Nạp cấu hình | 0 lượt gọi lỗi do nạp; độ trễ lan truyền tới mọi nút mục tiêu ≤ 10 giây, yêu cầu hệ thống ≤ 60 giây (NFR-00-052, NFR-00-013) | Phát cấu hình dưới tải 2.000 lượt/giây, đo số lỗi |
| NFR-03-009 | Hiệu lực thu hồi và tạm ngừng | Thu hồi token ≤ 60 giây (SEC-25); tạm ngừng khẩn cấp consumer, route ≤ 30 giây | Thu hồi rồi gọi liên tục tới khi bị chặn |
| NFR-03-010 | Cấu hình TLS | Điểm A+ ở testssl.sh, 0 giao thức hoặc bộ mã yếu (SEC-12); TLS 1.1 và thấp hơn bị từ chối 100% | Quét hằng tuần và mỗi lần đổi cấu hình TLS |
| NFR-03-011 | Gia hạn chứng thư | Tự động ≥ 30 ngày trước hạn; nạp chứng thư mới không cắt kết nối nào | Gia hạn thử dưới tải |
| NFR-03-012 | Hiệu quả WAF | Tỉ lệ chặn nhầm < 0,1% lượt hợp lệ; vá ảo triển khai ≤ 4 giờ từ khi có thông tin lỗ hổng (SEC-11); bộ payload OWASP bị chặn ≥ 99% ở mức hoang tưởng cấu hình (giả định, chốt khi có kết quả thử ở môi trường thử) | Bộ kiểm thử WAF với payload OWASP và lưu lượng mẫu sạch |
| NFR-03-013 | Chống tràn tầng 7 | Chịu tải gấp 3 lần cao điểm (900 lượt/giây) không suy giảm data plane; nguồn tấn công bị chặn ≤ 60 giây (SEC-10) | Tải đột biến gấp 10 lần trong 30 giây |
| NFR-03-014 | Không lộ dữ liệu trong nhật ký | 0 giá trị trường mức Nhạy cảm, 0 thân bản tin, 0 giá trị tiêu đề xác thực trong nhật ký, chỉ số, vết (NFR-00-029, BR-03-007) | Bộ quét mẫu dữ liệu và ca kiểm thử với giá trị đánh dấu `DH-CANARY-…` |
| NFR-03-015 | Không lộ thông tin máy chủ | 0 tiêu đề lộ tên hay phiên bản phần mềm; có đủ tiêu đề bảo mật (BR-03-013) | ZAP và kiểm tra tiêu đề tự động hằng tuần |
| NFR-03-016 | Tăng cứng thành phần | Container không chạy root, hệ thống tệp gốc chỉ đọc, khóa riêng chỉ ở OpenBao hoặc Secret tmpfs; ảnh APISIX và plugin ký cosign, quét Trivy 0 CRITICAL (SEC-52, 55…57) | Kyverno, Trivy trong CI |
| NFR-03-017 | Số route | ≥ 1.000 route mỗi tenant; ở hồ sơ `QM-CHUNG` khoảng 70.000 route mỗi nền tảng; độ trễ so khớp route tăng ≤ 10% so với 100 route (giả định, Q338 ở D03-09 còn mở) | Kiểm thử tải với số route lớn |
| NFR-03-018 | Mở rộng | HPA theo CPU ngưỡng 60%, 3 đến 10 bản sao; gấp đôi tài nguyên cho ≥ 1,8 lần thông lượng (NFR-00-061); gateway không giữ trạng thái phiên | Kiểm thử tải tăng dần |
| NFR-03-019 | Cách ly tenant về hạn mức | Một tenant vượt hạn mức không làm tăng p95 của tenant khác quá 10% (SEC-86); 0 lượt gọi đọc được dữ liệu của tenant khác (SEC-87) | Kiểm thử tải hai tenant; ca rò rỉ chéo tenant |
| NFR-03-020 | Truy vết và nhật ký cấu trúc | 100% lượt gọi có `trace_id`; nhật ký JSON có `trace_id`, `tenant_id` (NFR-00-051); giữ 100% vết lỗi, lấy mẫu 5% vết thành công (giả định, cơ sở: SRS cũ, NFR số 027) | Kiểm tra mẫu ở Tempo |
| NFR-03-021 | Độ trễ số liệu | Chỉ số tới bảng điều khiển ≤ 15 giây | Đo thời gian từ sự kiện tới biểu đồ |
| NFR-03-022 | Siêu dữ liệu lượt gọi | 5 triệu bản ghi/ngày/tenant, lưu 12 tháng; truy vấn theo thời gian và HTTT p95 ≤ 3 giây (NFR-00-062) | Kiểm thử trên ClickHouse với dữ liệu sinh |
| NFR-03-023 | API quản trị | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms (trừ lệnh bất đồng bộ) với 1.000 route và 200 consumer mỗi tenant (giả định, cơ sở: NFR-00-003, 004) | k6 |
| NFR-03-024 | Tắt an toàn và nâng cấp | Hoàn tất yêu cầu đang xử lý trong ≤ 30 giây khi tắt; 0 lượt gọi lỗi do nâng cấp cuốn chiếu (NFR-00-013) | Nâng cấp cuốn chiếu dưới tải |
| NFR-03-025 | IPv6 | Hai cửa vào hoạt động ở chế độ ngăn xếp kép IPv4 và IPv6 (CMP-LAW-09) | Truy cập thành công qua địa chỉ IPv6 |
| NFR-03-026 | Lưu giữ | Siêu dữ liệu lượt gọi 12 tháng trực tuyến; nhật ký WAF, xác thực (nhật ký an ninh) 12 tháng, nhật ký vận hành 90 ngày (NFR-00-028); kiểm toán thao tác 12 tháng trực tuyến, WORM 5 năm (NFR-00-027); ảnh chụp cấu hình lịch sử vĩnh viễn ở Git, 50 phiên bản gần nhất ở bucket | Kiểm tra chính sách lưu giữ |
| NFR-03-027 | Khả năng truy cập giao diện | Màn UI-03-* đạt WCAG 2.2 AA (NFR-00-040…045) | axe-core, Playwright |

: Yêu cầu phi chức năng của PH-03

### 8.2. Tham số theo tenant

Tham số chỉnh qua FR-03-056 (trừ các khóa ghi chú "có bốn mắt" đổi ở chức năng riêng). Miền là giới hạn nền tảng cho phép; hợp đồng của tenant có thể đặt trần thấp hơn.

| Khóa | Mặc định | Miền | Ý nghĩa |
|---|---|---|---|
| `gw.ip.maxConnections` | 100 | 10…1.000 | Số kết nối đồng thời tối đa mỗi địa chỉ nguồn (FR-03-003) |
| `gw.ip.uiReqPerSecond` | 50 | 5…500 | Yêu cầu/giây/IP cho đường dẫn giao diện |
| `gw.ip.apiReqPerSecond` | 200 | 20…2.000 | Yêu cầu/giây/IP cho API máy (giả định, Q03-05) |
| `gw.ip.burst` | 2 | 1…10 | Hệ số dung sai đột biến theo IP |
| `gw.ip.trustedCidrs` | dải giám sát và NDXP | Danh sách CIDR | Địa chỉ miễn giới hạn theo IP; SO duyệt |
| `gw.ip.headerTimeoutSeconds`, `gw.ip.bodyTimeoutSeconds` | 10, 30 | 5…60 | Thời hạn đọc tiêu đề, thân (chống kết nối chậm); có hiệu lực ở mức nhóm cửa vào |
| `gw.ip.autoBlock.threshold` | 10 | 3…100 | Số lần vi phạm trong 60 giây để tự chặn (FR-03-004) |
| `gw.ip.autoBlock.minutes` | 15 | 1…1.440 | Thời gian chặn tự động |
| `gw.body.maxBytes` | 1 MiB | 1 KiB…10 MiB | Kích thước thân tối đa mỗi route (FR-03-009) |
| `gw.json.maxDepth`, `gw.json.maxArrayItems` | 32, 10.000 | 8…64, 100…100.000 | Giới hạn cấu trúc JSON |
| `gw.waf.mode` (có bốn mắt) | `DETECT` khi khởi tạo | `DETECT`, `BLOCK` | Chế độ WAF; đổi ở FR-03-006 |
| `gw.waf.paranoia.ui`, `gw.waf.paranoia.api` | 2, 1 | 1…3 | Mức hoang tưởng CRS |
| `gw.waf.anomalyThreshold` | 5 | 3…15 | Ngưỡng điểm bất thường để chặn |
| `gw.waf.bodyScanBytes` | 128 KiB | 16 KiB…1 MiB | Phần thân được WAF quét (giả định) |
| `gw.waf.fpReviewMax` | 20 | 0…200 | Số cảnh báo giả chưa xử lý tối đa để được chuyển sang `BLOCK` (giả định) |
| `gw.waf.degradeP99Ms` | 15 | 5…100 | p99 thời gian WAF để tự hạ về `DETECT` (FR-03-006) |
| `gw.waf.exception.maxDays`, `gw.waf.exception.warnDays` | 90, 7 | 1…90, 1…30 | Hạn tối đa ngoại lệ; số ngày báo sắp hết hạn |
| `gw.tls.exceptionMaxDays` | 180 | 1…180 | Hạn tối đa ngoại lệ TLS 1.2 (FR-03-001) |
| `gw.jwks.refreshMinutes` | 10 | 1…60 | Chu kỳ làm mới JWKS |
| `gw.jwks.maxStaleHours` | 24 | 1…24 | Thời gian dùng bộ đệm JWKS khi không làm mới được |
| `gw.jwks.kidRefreshMinIntervalSeconds` | 30 | 10…300 | Khoảng tối thiểu giữa hai lần làm mới do `kid` lạ |
| `gw.jwt.clockSkewSeconds` | 30 | 0…60 | Dung sai đồng hồ khi kiểm `exp`, `nbf` (SEC-25) |
| `gw.opa.timeoutMs` | 50 | 10…200 | Thời hạn chờ OPA (giả định) |
| `gw.rate.essentialFactor` | 1,5 | 1…3 | Hệ số nới tần suất cho nhóm `ESSENTIAL` |
| `gw.quota.warnPercent` | 80 | 50…95 | Ngưỡng cảnh báo hạn ngạch |
| `gw.quota.essentialOverrunPercent` | 20 | 0…100 | Mức vượt hạn ngạch cho phép của nhóm `ESSENTIAL` |
| `gw.tenantRateLimit.perSecond` (có bốn mắt khi hạ) | 500 | 10…trần hợp đồng | Hạn mức toàn tenant (D03-10 §5.3, FR-03-023) |
| `gw.tenantRateLimit.burst` | 20% | 0…100% | Dung sai đột biến của hạn mức tenant |
| `gw.degrade.localDivisorMode` | `REPLICAS` | `REPLICAS`, `NONE` | Cách chia hạn mức khi Valkey mất (FR-03-026) |
| `gw.throttle.errorRatePercent`, `gw.throttle.latencyFactor` | 20, 3 | 5…80, 2…10 | Ngưỡng điều tiết theo backend (FR-03-027) |
| `gw.upstream.healthcheck.intervalSeconds` | 5 | 1…60 | Chu kỳ kiểm tra chủ động (FR-03-030) |
| `gw.upstream.failThreshold`, `gw.upstream.successThreshold` | 3, 2 | 1…10 | Số lần để loại, để đưa lại nút |
| `gw.upstream.timeout.connectMs`, `gw.upstream.timeout.readMs` | 3.000, 10.000 | 100…30.000 | Thời hạn chờ mặc định; trần 30.000 ms (CV 631) |
| `gw.breaker.failures`, `gw.breaker.openSeconds` | 5, 10 | 2…50, 5…60 | Ngắt mạch (FR-03-031) |
| `gw.ws.idleTimeoutSeconds`, `gw.ws.maxMessageBytes`, `gw.ws.maxPerConsumer` | 120, 1 MiB, 50 | 10…3.600, 4 KiB…16 MiB, 1…500 | WebSocket (FR-03-033) |
| `gw.trace.successSampling` | 0,05 | 0,01…1 | Tỉ lệ lấy mẫu vết thành công |
| `gw.sunset.minDays`, `gw.sunset.retainDays` | 180, 30 | 180…720, 0…180 | Hạn tối thiểu giữ phiên bản cũ; giữ thêm sau `SUNSET` |
| `gw.redirect.defaultDays` | 180 | 30…365 | Thời gian chuyển tiếp tenant sáp nhập (FR-03-037) |
| `gw.snapshot.debounceSeconds` | 3 | 0…30 | Gom sự kiện trước khi tổng hợp |
| `gw.reconcile.minutes` | 5 | 1…60 | Chu kỳ đối chiếu định kỳ |
| `gw.snapshot.retain` | 50 | 10…500 | Số ảnh chụp giữ ở bucket |
| `gw.snapshot.maxBytes` | 20 MiB | 1…100 MiB | Kích thước tối đa ảnh chụp (giả định) |
| `gw.snapshot.isolateBadRoute` | `false` | `true`, `false` | Cô lập route lỗi thay vì từ chối cả ảnh chụp |
| `gw.snapshot.drGap` | 1.000 | 100…100.000 | Khoảng an toàn số phiên bản khi chuyển site |
| `gw.sync.pollSeconds` | 5 | 1…60 | Chu kỳ bộ đồng bộ kiểm tra con trỏ `current` |
| `gw.rollback.holdHours` | 24 | 1…168 | Thời gian giữ tổng hợp tự động sau quay lui (FR-03-044) |
| `gw.node.lagSeconds`, `gw.node.unknownSeconds` | 60, 120 | 10…600 | Ngưỡng nút `LAGGING`, `UNKNOWN` |
| `gw.emergency.propagateSeconds` | 30 | 5…60 | Mục tiêu hiệu lực tạm ngừng khẩn cấp |
| `gw.cert.renewDays`, `gw.cert.warnDays` | 30, 30 | 7…60 | Ngày gia hạn tự động; ngày cảnh báo (7 ngày là Nghiêm trọng) |
| `gw.accessLog.bufferMiB` | 1.024 | 128…4.096 | Bộ đệm đĩa của nhật ký lượt gọi mỗi pod |
| `gw.accessLog.export.maxRows` | 100.000 | 1.000…500.000 | Số dòng tối đa mỗi lần xuất |
| `gw.metrics.maxConsumerLabels` | 500 | 50…5.000 | Số giá trị nhãn `consumer` tối đa (giả định, Q03-08) |

: Tham số theo tenant của PH-03

## 9. Mã lỗi, thông báo, sự kiện và API

### 9.1. Mã lỗi

Định nghĩa đầy đủ (thân RFC 9457, trường bổ sung) ở D03-04-PH03 §6. Dải 001–099 cho control plane (`dh-connect`), 101–199 cho gateway trả cho bên gọi.

| Mã | HTTP | Ý nghĩa (control plane) |
|---|---|---|
| ERR-03-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác |
| ERR-03-002 | 409 | Mã đã tồn tại (kể cả đối tượng đã gỡ) |
| ERR-03-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường |
| ERR-03-004 | 412 | Xung đột phiên bản bản ghi (`If-Match` sai) |
| ERR-03-005 | 422 | Cấu hình không hợp lệ theo kiểm tra tĩnh, kèm danh sách lỗi |
| ERR-03-006 | 409 | Đang có lần tổng hợp, ký hoặc phát khác; hoặc tenant đang bị giữ sau quay lui |
| ERR-03-007 | 422 | Không quay lui được vì phiên bản đích tham chiếu đối tượng không còn hợp lệ |
| ERR-03-008 | 403 | Người duyệt trùng người đề nghị (bốn mắt) |
| ERR-03-009 | 422 | Ngoại lệ hoặc luật vá WAF sai: thiếu lý do, quá hạn tối đa, mã luật không có |
| ERR-03-010 | 409 | Đã có ngoại lệ WAF còn hiệu lực cho cặp route và mã luật |
| ERR-03-011 | 422 | Route chưa đủ điều kiện hoặc chưa được duyệt để mở ra cửa Internet |
| ERR-03-012 | 422 | Route thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền |
| ERR-03-013 | 422 | Plugin hoặc mẫu chính sách ngoài danh mục được duyệt |
| ERR-03-014 | 502 | Không ghi được ảnh chụp tới Git hoặc bucket |
| ERR-03-015 | 503 | OpenBao, PKI hoặc dịch vụ ký không khả dụng |
| ERR-03-016 | 422 | Chứng thư không hợp lệ (chuỗi, hạn, khóa, host) |
| ERR-03-017 | 409 | Consumer còn đăng ký sử dụng đang hiệu lực |
| ERR-03-018 | 422 | Hạn mức hoặc tham số vượt trần hợp đồng hoặc dưới mức tối thiểu |
| ERR-03-019 | 409 | Đối tượng đã ở trạng thái đích hoặc đang được dùng (đã dừng, đã tạm ngừng, mẫu đang dùng) |
| ERR-03-020 | 422 | Gói nhập từ gateway cũ không đọc được, thiếu trường hoặc bị bộ quét từ chối |
| ERR-03-021 | 400 | Khoảng thời gian truy vấn, báo cáo hoặc số dòng xuất vượt giới hạn |
| ERR-03-022 | 403 | Thiếu quyền (`PERM`) hoặc thiếu scope dịch vụ |
| ERR-03-023 | 409 | Route không ở trạng thái cho phép thao tác |
| ERR-03-024 | 422 | Địa chỉ thuộc danh sách tin cậy hoặc hạ tầng, không được chặn |
| ERR-03-025 | 409 | Chuyển tiếp tenant xung đột: tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp |
| ERR-03-026 | 503 | Không đọc được số liệu từ PH-13 |
| ERR-03-027 | 422 | Chưa đủ điều kiện chuyển WAF sang chế độ chặn (chưa chạy phát hiện đủ 14 ngày, hoặc còn cảnh báo giả chưa xử lý; theo SDD §4.14) |

: Mã lỗi control plane của PH-03

Bảng sau là mã lỗi gateway trả cho bên gọi (HTTT, giao diện). Thân luôn theo RFC 9457 với `code`, `traceId`; cột cuối là việc bên gọi nên làm.

| Mã | HTTP | Ý nghĩa (gateway) | Bên gọi nên làm |
|---|---|---|---|
| ERR-03-101 | 400 | Yêu cầu sai cú pháp, lược đồ, kiểu nội dung hoặc vượt giới hạn cấu trúc | Sửa yêu cầu theo `errors[]` |
| ERR-03-102 | 401 | Thiếu thông tin xác thực | Gửi token trong `Authorization` |
| ERR-03-103 | 401 | Token hoặc khóa API không hợp lệ (chữ ký, `kid`, `iss`, `aud`) | Lấy token mới |
| ERR-03-104 | 401 | Token đã hết hạn | Lấy token mới rồi gọi lại |
| ERR-03-105 | 401 | Token đã bị thu hồi | Liên hệ quản trị Datahub |
| ERR-03-106 | 401 | Tenant của token không khớp realm hoặc tenant của API | Dùng token của đúng tỉnh |
| ERR-03-107 | 403 | Thiếu phạm vi quyền (scope) | Xin cấp thêm phạm vi |
| ERR-03-108 | 403 | Chứng thư khách không hợp lệ hoặc không khớp token | Dùng đúng chứng thư đã đăng ký |
| ERR-03-109 | 403 | Bị WAF chặn | Gửi `traceId` cho quản trị nếu nhầm |
| ERR-03-110 | 403 | Địa chỉ nguồn bị chặn | Liên hệ quản trị |
| ERR-03-111 | 403 | HTTT chưa đăng ký sử dụng API hoặc đăng ký hết hiệu lực | Liên hệ chủ dịch vụ |
| ERR-03-112 | 403 | OPA từ chối theo chính sách truy cập | Xem lý do; liên hệ chủ quản dữ liệu |
| ERR-03-113 | 403 | Đường dẫn bị chặn hoặc ngoài phạm vi gói | Gọi đúng đường dẫn của gói |
| ERR-03-114 | 404, 405 | Không có route khớp; host không thuộc tenant nào; phương thức không được phép | Kiểm tra địa chỉ, phương thức |
| ERR-03-115 | 413 | Thân yêu cầu quá lớn | Giảm kích thước hoặc dùng kênh tải tệp |
| ERR-03-116 | 429 | Vượt tần suất của HTTT (hoặc bị điều tiết, hoặc quá số kết nối WebSocket) | Chờ `Retry-After` rồi thử lại |
| ERR-03-117 | 429 | Vượt hạn ngạch theo chu kỳ | Chờ tới thời điểm đặt lại |
| ERR-03-118 | 429 | Vượt hạn mức toàn tenant | Chờ giây lát, thử lại |
| ERR-03-119 | 429 | Vượt giới hạn tốc độ hoặc kết nối theo địa chỉ nguồn | Giảm tốc độ, thử lại |
| ERR-03-120 | 503 | Không có backend khỏe hoặc mạch đang mở | Chờ `Retry-After` |
| ERR-03-121 | 504 | Backend quá hạn chờ | Thử lại; báo nếu lặp lại |
| ERR-03-122 | 502 | Backend phản hồi không hợp lệ | Báo vận hành kèm `traceId` |
| ERR-03-123 | 503 | API đang dừng hoặc route bị tạm ngừng | Thử lại sau |
| ERR-03-124 | 503 | Dịch vụ định danh hoặc ủy quyền tạm không khả dụng (JWKS hết hạn đệm, OPA không phản hồi) | Thử lại sau |
| ERR-03-125 | 501 | Không hỗ trợ kiểu chuyển đổi giao thức | Dùng giao thức được hỗ trợ |
| ERR-03-126 | 410 | Phiên bản API đã hết hạn phục vụ | Chuyển sang phiên bản mới |
| ERR-03-127 | 403 | HTTT đang bị tạm ngừng truy cập | Liên hệ quản trị Datahub |
| ERR-03-128 | 421 | SNI hoặc `Host` không khớp dịch vụ nào | Kiểm tra địa chỉ truy cập |
| ERR-03-129 | 500 | Lỗi nội bộ gateway | Báo vận hành kèm `traceId` |
| ERR-03-130 | 403 | Phương thức xác thực không đúng với gói của API | Dùng phương thức của gói |

: Mã lỗi gateway trả cho bên gọi

### 9.2. Thông báo hiển thị cho người dùng

Mỗi mã lỗi mà người dùng quản trị có thể gặp trên màn hình được chuyển thành một câu tiếng Việt cụ thể, nêu điều gì sai và phải làm gì. Bảng dưới là các câu chính của giao diện quản trị; nguồn chuẩn và vị trí hiển thị ở D03-06-PH03 §5.2. Lỗi không có trong bảng hiển thị theo FR-00-080: câu từ trường `detail`, kèm mã lỗi và nút "Sao chép mã truy vết". Các câu của mã `ERR-03-101…130` là nội dung `title` và `detail` trả cho bên gọi, đã nêu ở từng FR; UI-03-09 hiển thị lại chính các câu đó khi vận hành xem lượt gọi lỗi.

| Mã | Câu hiển thị | Vị trí |
|---|---|---|
| ERR-03-001 | "Không tìm thấy {đối tượng} {mã}. Có thể đối tượng đã bị gỡ hoặc thuộc tỉnh khác." | Trang kết quả thay cho nội dung |
| ERR-03-002 | "Mã {mã} đã được dùng. Chọn mã khác." | Dưới trường mã |
| ERR-03-003 | "Dữ liệu chưa hợp lệ: {n} lỗi. Xem các trường được đánh dấu." | Hộp lỗi đầu biểu mẫu, lỗi tại từng trường |
| ERR-03-004 | "{Người} vừa cập nhật {đối tượng} lúc {giờ}. Xem khác biệt rồi tải bản mới nhất hoặc ghi đè." | Hộp thoại so sánh khác biệt |
| ERR-03-005 | "Cấu hình gateway không hợp lệ: {n} lỗi. Xem danh sách bên dưới." | Hộp lỗi đầu trang, danh sách lỗi dưới |
| ERR-03-006 | "Đang có một lần tổng hợp hoặc phát cấu hình cho tỉnh này. Chờ lần đó hoàn tất." | Thông báo trên cùng |
| ERR-03-007 | "Không thể quay lui về phiên bản {v}: {đối tượng} không còn hợp lệ." | Hộp thoại quay lui |
| ERR-03-008 | "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." | Hộp thoại duyệt |
| ERR-03-009 | "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày." | Dưới trường thời hạn |
| ERR-03-010 | "Route này đã có ngoại lệ cho luật {mã luật} đến {ngày}. Thu hồi ngoại lệ cũ hoặc chờ hết hạn." | Hộp cảnh báo đầu biểu mẫu |
| ERR-03-011 | "Route chưa đủ điều kiện mở ra Internet: {lý do}." | Hộp thoại mở cửa ngoài |
| ERR-03-012 | "Route {mã} thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát." | Danh sách lỗi của ảnh chụp |
| ERR-03-013 | "Route {mã} dùng plugin {tên} không có trong danh mục được duyệt." | Danh sách lỗi của ảnh chụp |
| ERR-03-014 | "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." | Thông báo trên cùng |
| ERR-03-015 | "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi." | Thông báo trên cùng |
| ERR-03-016 | "Chứng thư không hợp lệ: {lý do}." | Dưới trường tệp chứng thư |
| ERR-03-017 | "HTTT còn {n} đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ." | Hộp thoại xác nhận |
| ERR-03-018 | "Hạn mức phải nằm trong trần của tỉnh ({trần} lượt/giây)." | Dưới trường giới hạn |
| ERR-03-019 | "{Route|HTTT} {mã} đã ở trạng thái {trạng thái}." | Thông báo trên cùng |
| ERR-03-020 | "Gói cấu hình hệ cũ không đọc được: {lý do}." | Dưới ô tải tệp |
| ERR-03-021 | "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất." | Dưới bộ chọn thời gian |
| ERR-03-022 | "Bạn chưa có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh để được cấp quyền." | Thông báo nổi mức lỗi |
| ERR-03-023 | "Route {mã} đang {trạng thái} nên chưa thực hiện được thao tác này." | Thông báo nổi mức cảnh báo |
| ERR-03-024 | "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn." | Dưới trường địa chỉ |
| ERR-03-025 | "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy." | Hộp thoại |
| ERR-03-026 | "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau." | Khung số liệu, thay cho số 0 |
| ERR-03-027 | "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)." | Hộp thoại đổi chế độ WAF |

: Thông báo hiển thị theo mã lỗi

### 9.3. Sự kiện

Sự kiện nghiệp vụ của `dh-connect` đi qua outbox tới Kafka theo ADR-042; riêng EVT-03-09 do APISIX phát qua plugin `kafka-logger` tới topic an ninh vì phát sinh ở data plane. Lược đồ và quy tắc tương thích ở D03-04-PH03 §7 (chế độ BACKWARD ở Apicurio, ADR-070).

| Mã | Topic | Khi nào | Bên tiêu thụ |
|---|---|---|---|
| EVT-03-01 | `{tenant}.gateway.snapshot.published.v1` | Ảnh chụp cấu hình được phát | PH-02, PH-13 |
| EVT-03-02 | `{tenant}.gateway.snapshot.rolled-back.v1` | Quay lui cấu hình | PH-02, PH-13 |
| EVT-03-03 | `{tenant}.gateway.route.state-changed.v1` | Route dừng, mở, tạm ngừng, `SUNSET`, `RETIRED`, đổi cửa vào | PH-02, PH-13, PH-15 |
| EVT-03-04 | `{tenant}.gateway.consumer.state-changed.v1` | Consumer tạo, đổi, tạm ngừng, gỡ | PH-01, PH-13 |
| EVT-03-05 | `{tenant}.gateway.waf-exception.changed.v1` | Ngoại lệ WAF đề nghị, duyệt, từ chối, thu hồi, hết hạn | PH-13, thông báo SO |
| EVT-03-06 | `{tenant}.gateway.waf-exception.expiring.v1` | Ngoại lệ còn 7 ngày hết hạn | Thông báo SO, TA |
| EVT-03-07 | `{tenant}.gateway.quota.threshold-reached.v1` | HTTT đạt 80% hoặc 100% hạn ngạch; tenant sắp chạm hạn mức | PH-02, thông báo đầu mối HTTT, TA |
| EVT-03-08 | `{tenant}.gateway.certificate.expiring.v1` | Chứng thư biên còn dưới 30 ngày | PH-13, PA |
| EVT-03-09 | `{tenant}.gateway.security.alert-raised.v1` | Sự kiện an ninh, vận hành của gateway (chặn IP, truy cập chéo tenant, suy giảm) | PH-13 (SIEM) |
| EVT-03-10 | `{tenant}.gateway.tenant-redirect.changed.v1` | Chuyển tiếp tenant sáp nhập bắt đầu, kết thúc | PH-20, PH-13 |
| EVT-03-11 | `{tenant}.gateway.limit.changed.v1` | Hạn mức toàn tenant, ghi đè hạn mức hoặc tham số hạn mức đổi | PH-13, PH-20 |
| EVT-03-12 | `{tenant}.gateway.snapshot.rejected.v1` | Ảnh chụp bị từ chối khi kiểm tra hợp lệ, kèm danh sách lỗi | PH-02, thông báo người phát hành |

: Sự kiện của PH-03

### 9.4. Danh mục API

Định nghĩa đầy đủ và ví dụ ở D03-04-PH03; nguồn chuẩn là OpenAPI của `dh-connect` có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`. Tiền tố `/api/gateway/v1`; tenant lấy từ token, không có trong đường dẫn. Hành động dùng `POST …/{mã}:{động-từ}`. Cột quyền: `read`, `admin`, `limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read` là `PERM-03-…`; `sync`, `revoke` là scope dịch vụ `gateway:…`.

| Mã | Phương thức và đường dẫn | FR | Quyền | Mã thành công |
|---|---|---|---|---|
| API-03-001 | `GET /routes` | 028 | read | 200 |
| API-03-002 | `GET /routes/{routeCode}` | 009, 017, 028, 033, 034, 035 | read | 200 |
| API-03-003 | `POST /routes/{routeCode}:stop` | 036 | operate | 200 |
| API-03-004 | `POST /routes/{routeCode}:start` | 036 | operate | 200 |
| API-03-005 | `GET /upstreams` | 029 | read | 200 |
| API-03-006 | `GET /upstreams/{upstreamCode}` | 029, 030 | read | 200 |
| API-03-007 | `GET /routes/{routeCode}/versions` | 035 | read | 200 |
| API-03-008 | `PUT /routes/{routeCode}/exposure` | 038 | admin | 200 (202) |
| API-03-009 | `PUT /routes/{routeCode}/request-limits` | 009 | admin | 200 |
| API-03-010 | `PUT /routes/{routeCode}/timeouts` | 031 | admin | 200 |
| API-03-011 | `GET /consumers` | 046 | read | 200 |
| API-03-012 | `GET /consumers/{consumerCode}` | 014, 016, 046 | read | 200 |
| API-03-013 | `PUT /consumers/{consumerCode}` | 046 | sync | 200 (201) |
| API-03-014 | `PUT /consumers/{consumerCode}/credentials` | 046 | sync | 200 |
| API-03-015 | `DELETE /consumers/{consumerCode}` | 046 | sync | 204 |
| API-03-016 | `GET /consumers/{consumerCode}/credentials` | 002, 014 | read | 200 |
| API-03-017 | `POST /consumers/{consumerCode}:suspend` | 047 | operate | 200 |
| API-03-018 | `POST /consumers/{consumerCode}:resume` | 047 | operate | 200 |
| API-03-019 | `POST /routes/{routeCode}:suspend` | 047 | operate | 200 |
| API-03-020 | `POST /routes/{routeCode}:resume` | 047 | operate | 200 |
| API-03-021 | `GET /plan-policies` | 015, 016, 020, 021 | read | 200 |
| API-03-022 | `GET /plan-policies/{policyCode}` | 015, 017, 020, 021 | read | 200 |
| API-03-023 | `GET /tenant-limits` | 023 | read | 200 |
| API-03-024 | `PUT /tenant-limits` | 023 | limit | 200 (202) |
| API-03-025 | `GET /rate-limit-overrides` | 024, 025 | read | 200 |
| API-03-026 | `POST /rate-limit-overrides` | 024 | limit | 201 |
| API-03-027 | `PUT /rate-limit-overrides/{overrideId}` | 024 | limit | 200 |
| API-03-028 | `DELETE /rate-limit-overrides/{overrideId}` | 024 | limit | 204 |
| API-03-029 | `GET /consumers/{consumerCode}/usage` | 021, 022, 027 | read | 200 |
| API-03-030 | `GET /quota-alerts` | 022 | read | 200 |
| API-03-031 | `GET /edge/tls-profile` | 001 | read | 200 |
| API-03-032 | `GET /tls-exceptions` | 001 | read | 200 |
| API-03-033 | `POST /tls-exceptions` | 001 | admin | 201 |
| API-03-034 | `POST /tls-exceptions/{exceptionId}:revoke` | 001 | admin | 200 |
| API-03-035 | `GET /edge/client-ca-bundles` | 002, 049 | read | 200 |
| API-03-036 | `GET /ip-blocks` | 003, 004 | read | 200 |
| API-03-037 | `POST /ip-blocks` | 004 | waf | 201 |
| API-03-038 | `DELETE /ip-blocks/{blockId}` | 004 | waf | 204 |
| API-03-039 | `GET /waf/events` | 005 | waf-request | 200 |
| API-03-040 | `GET /waf/mode` | 006 | read | 200 |
| API-03-041 | `PUT /waf/mode` | 006 | waf | 200 (202) |
| API-03-042 | `GET /waf/exceptions` | 007 | waf-request | 200 |
| API-03-043 | `POST /waf/exceptions` | 007 | waf-request | 201 |
| API-03-044 | `POST /waf/exceptions/{exceptionId}:approve` | 007 | waf-approve | 200 |
| API-03-045 | `POST /waf/exceptions/{exceptionId}:reject` | 007 | waf-approve | 200 |
| API-03-046 | `POST /waf/exceptions/{exceptionId}:revoke` | 007 | waf | 200 |
| API-03-047 | `GET /waf/virtual-patches` | 008 | waf-request | 200 |
| API-03-048 | `POST /waf/virtual-patches` | 008 | waf | 201 |
| API-03-049 | `POST /waf/virtual-patches/{patchId}:retire` | 008 | waf | 200 |
| API-03-050 | `GET /cors-policies` | 010 | read | 200 |
| API-03-051 | `PUT /cors-policies/{routeCode}` | 010 | admin | 200 |
| API-03-052 | `GET /auth/jwks-status` | 012 | read | 200 |
| API-03-053 | `POST /revocations` | 018 | revoke | 201 |
| API-03-054 | `GET /revocations` | 018 | read | 200 |
| API-03-055 | `GET /authorization-bindings` | 019 | read | 200 |
| API-03-056 | `GET /snapshots` | 039, 044 | read | 200 |
| API-03-057 | `GET /snapshots/{version}` | 039, 041 | read | 200 |
| API-03-058 | `POST /snapshots:validate` | 040 | publish | 200 |
| API-03-059 | `POST /snapshots:build` | 039, 040, 041 | publish | 201 (200) |
| API-03-060 | `POST /snapshots/{version}:publish` | 042 | publish | 200 |
| API-03-061 | `POST /snapshots/{version}:rollback` | 044 | operate | 201 |
| API-03-062 | `GET /snapshots/{version}/diff` | 044 | read | 200 |
| API-03-063 | `GET /nodes` | 043, 045 | read | 200 |
| API-03-064 | `GET /nodes/{nodeId}` | 043, 045 | read | 200 |
| API-03-065 | `GET /policy-templates` | 020, 048 | read | 200 |
| API-03-066 | `GET /policy-templates/{templateCode}` | 015, 048 | read | 200 |
| API-03-067 | `PUT /policy-templates/{templateCode}/enablement` | 048 | admin | 200 |
| API-03-068 | `GET /certificates` | 049 | read | 200 |
| API-03-069 | `GET /certificates/{certCode}` | 049 | read | 200 |
| API-03-070 | `POST /certificates/{certCode}:renew` | 049 | operate | 202 |
| API-03-071 | `GET /change-requests` | 006, 023, 038 | read | 200 |
| API-03-072 | `POST /change-requests/{requestId}:approve` | 006, 023, 038 | approve | 200 |
| API-03-073 | `POST /change-requests/{requestId}:reject` | 006, 023, 038 | approve | 200 |
| API-03-074 | `GET /access-logs` | 050, 051 | log-read | 200 |
| API-03-075 | `GET /access-logs/{logId}` | 051 | log-read | 200 |
| API-03-076 | `POST /access-logs:export` | 051 | log-read | 202 |
| API-03-077 | `GET /overview` | 026, 052, 055 | read | 200 |
| API-03-078 | `GET /overview/top-consumers` | 055 | read | 200 |
| API-03-079 | `GET /overview/top-routes` | 055 | read | 200 |
| API-03-080 | `GET /synthetic-checks` | 053 | read | 200 |
| API-03-081 | `POST /synthetic-checks` | 053 | admin | 201 |
| API-03-082 | `PUT /synthetic-checks/{checkId}` | 053 | admin | 200 |
| API-03-083 | `DELETE /synthetic-checks/{checkId}` | 053 | admin | 204 |
| API-03-084 | `GET /security-alerts` | 054 | read | 200 |
| API-03-085 | `POST /security-alerts/{alertId}:acknowledge` | 054 | operate | 200 |
| API-03-086 | `GET /settings` | 003, 011, 056 | read | 200 |
| API-03-087 | `PUT /settings` | 003, 011, 056 | admin | 200 (202) |
| API-03-088 | `POST /simulations` | 057 | admin | 200 |
| API-03-089 | `GET /reports/usage` | 058 | read | 200 |
| API-03-090 | `POST /reports/usage:export` | 058 | log-read | 202 |
| API-03-091 | `POST /migrations/legacy-gateway:import` | 059 | admin | 202 |
| API-03-092 | `GET /migrations/legacy-gateway/{importId}` | 059 | admin | 200 |
| API-03-093 | `POST /migrations/legacy-gateway/{importId}:apply` | 059 | admin | 200 |
| API-03-094 | `GET /tenant-redirects` | 037 | read | 200 |
| API-03-095 | `POST /tenant-redirects` | 037 | admin | 201 |
| API-03-096 | `POST /tenant-redirects/{redirectId}:end` | 037 | admin | 200 |

: Danh mục API của PH-03

## 10. Giao diện

### 10.1. Danh sách màn hình

PH-03 có 18 màn hình chia ba nhóm: quan sát và nhật ký (UI-03-01, 07, 09), cấu hình và chính sách (UI-03-02 đến 06, 08, 12, 13, 15, 16), phát hành và nút (UI-03-10, 11, 14, 17, 18). Màn hình nằm trong nhóm menu "Cổng API" của `dh-console`, route tiếng Việt không dấu dạng `/cong-api/...`. Bố cục, thành phần, trạng thái của từng màn đặc tả ở D03-06-PH03; mẫu màn `PTN-*` theo D03-06-00 §4.

| Mã | Tên | Mẫu | Vai trò chính | Hành vi chính | FR |
|---|---|---|---|---|---|
| UI-03-01 | Tổng quan lưu lượng | PTN-06 | TO, TA, SO, PO, PA, AU | Thẻ chỉ số, biểu đồ lưu lượng, xếp hạng HTTT và route, cảnh báo đang mở, kiểm tra tổng hợp, tab báo cáo sử dụng | 026, 052, 053, 054, 055, 058 |
| UI-03-02 | Danh sách route | PTN-01 | TO, TA, PA | Tìm, lọc theo trạng thái, cửa vào, phiên bản; dừng, mở, tạm ngừng khẩn cấp | 028, 035, 036, 047 |
| UI-03-03 | Chi tiết route | PTN-02 | TA, PA, TO | Tab Tổng quan, Chính sách (CORS, giới hạn yêu cầu, bảo mật), Backend và sức khỏe, Phiên bản, Cửa vào, Lịch sử | 009, 010, 015, 017, 019, 020, 028…031, 033…036, 038 |
| UI-03-04 | Danh sách consumer | PTN-01 | TA, TO, SO | Tìm, lọc theo trạng thái, nhóm ưu tiên, phương thức xác thực | 046 |
| UI-03-05 | Chi tiết consumer | PTN-02 | TA, TO, SO | Tab Thông tin xác thực công khai, Đăng ký, Hạn mức và mức dùng, Thu hồi, Nhật ký, Lịch sử; tạm ngừng khẩn cấp | 014, 016, 018, 022, 046, 047, 051 |
| UI-03-06 | Hạn mức và hạn ngạch | PTN-01 | TA, PA | Hạn mức tenant, ghi đè theo route, hệ số điều tiết, cảnh báo sắp hết hạn ngạch | 021…024, 027 |
| UI-03-07 | Nhật ký WAF và sự kiện chặn | PTN-11 | SO, TO, TA | Bảng sự kiện chặn, lọc theo luật, route, địa chỉ; đổi chế độ WAF; đề nghị ngoại lệ từ một dòng | 005, 006, 007, 054 |
| UI-03-08 | Ngoại lệ luật WAF và luật vá ảo | PTN-01 | SO, TA, TO | Danh sách ngoại lệ, đề nghị, duyệt, thu hồi; soạn luật vá ảo | 007, 008 |
| UI-03-09 | Nhật ký lượt gọi | PTN-11 | TA, TO, SO, AU | Tra cứu theo thời gian, HTTT, route, mã lỗi, `traceId`; chi tiết một lượt; xuất | 051 |
| UI-03-10 | Ảnh chụp cấu hình và phát hành | PTN-01, PTN-02 | PA, TA | Danh sách phiên bản, so sánh, kết quả kiểm tra, phát, quay lui, bỏ giữ | 039…042, 044 |
| UI-03-11 | Nút gateway | PTN-01 | PO, PA, TA, TO | Bảng nút, phiên bản đang chạy, trạng thái đồng bộ, JWKS, Valkey, CPU | 012, 043, 045 |
| UI-03-12 | Chứng thư và TLS | PTN-01 | PA, TA | Danh sách chứng thư và hạn, hồ sơ TLS, ngoại lệ TLS 1.2, bộ CA khách, gia hạn | 001, 002, 049 |
| UI-03-13 | Mẫu chính sách | PTN-01 | PA, TA | Danh mục mẫu, plugin, tham số; bật tắt cho tỉnh | 015, 020, 048 |
| UI-03-14 | Chạy thử chính sách | PTN-04 | TA, SO, PA | Nhập yêu cầu giả định, xem kết quả từng chốt | 057 |
| UI-03-15 | Địa chỉ bị chặn | PTN-01 | SO, PA | Danh sách chặn tự động và thủ công, chặn, bỏ chặn, danh sách tin cậy | 003, 004 |
| UI-03-16 | Tham số, chuyển tiếp tenant | PTN-12 | TA, PA | Tham số gateway, giới hạn theo địa chỉ nguồn, tiêu đề bảo mật, chuyển tiếp tenant sáp nhập | 003, 011, 037, 056 |
| UI-03-17 | Duyệt thay đổi gateway | PTN-10 | TA, SO | Hộp việc chờ duyệt: ngoại lệ WAF, chế độ WAF, cửa Internet, hạ hạn mức | 006, 007, 023, 038 |
| UI-03-18 | Nhập cấu hình từ gateway cũ | PTN-05 | PA, TA | Trình hướng dẫn: tải gói, xem phân tích, sửa ánh xạ, áp dụng | 059 |

: Danh sách màn hình của PH-03

### 10.2. Giao diện tiêu biểu

Ảnh hi-fi của các màn dưới đây do D03-06-PH03 dựng theo bộ token Liquid Glass của D03-05 và đặt ở thư mục `03-thiet-ke/uiux/ph03/hifi/`; bản 0.1 của tài liệu này chưa gắn ảnh vì tập màn hình chưa viết, nên phần dưới nêu bố cục và hành vi cần dựng. Dữ liệu minh họa dùng tenant `T68`.

**Màn Tổng quan lưu lượng (UI-03-01).** Đây là nơi vận hành bắt đầu mỗi ca trực. Hàng thẻ đầu trang gồm năm số: lượt gọi mỗi giây, tỉ lệ lỗi, độ trễ thêm p95 so với mục tiêu 50 ms (đổi sang màu cảnh báo khi vượt 40 ms), kết nối đang mở và nút đồng bộ (ví dụ "6/6"). Dưới đó là biểu đồ lưu lượng theo thời gian, tách `2xx`, `4xx`, `5xx` và phần bị gateway từ chối, hai bảng xếp hạng (HTTT theo lưu lượng kèm thanh mức dùng so với hạn mức, đổi màu khi vượt 80%; route theo lưu lượng và độ trễ), khung cảnh báo đang mở theo mức độ và dải trạng thái các kiểm tra tổng hợp. Mọi thẻ đều bấm được: bấm "WAF chặn" mở UI-03-07, bấm một HTTT lọc toàn trang, bấm cột lỗi mở UI-03-09 đã lọc sẵn. Khi PH-13 không trả số liệu, khung hiển thị "Chưa có số liệu" thay vì số 0 (ERR-03-026).

| Thành phần | Mô tả |
|---|---|
| Thẻ chỉ số | Năm thẻ có mũi tên xu hướng so với kỳ trước; thẻ lỗi và thẻ độ trễ có ngưỡng màu |
| Biểu đồ lưu lượng | Vùng xếp chồng theo nhóm mã trạng thái; chọn khoảng 15 phút, 1 giờ, 24 giờ, 7 ngày; làm mới 15 giây |
| Xếp hạng HTTT | Tên HTTT, lượt gọi, tỉ lệ lỗi, thanh dùng so với hạn mức; nhãn riêng cho nhóm `ESSENTIAL` |
| Cảnh báo đang mở | Mức Nghiêm trọng, Cao, Trung bình; nút "Xác nhận" cho người có `PERM-03-operate` |
| Kiểm tra tổng hợp | Chấm xanh, đỏ cho từng API quan trọng; thời điểm lỗi gần nhất |

: Thành phần chính của UI-03-01

**Màn Ngoại lệ luật WAF và luật vá ảo (UI-03-08).** Màn dành cho Cán bộ ATTT và vận hành xử lý cảnh báo giả. Bảng ngoại lệ liệt kê route, mã luật, lý do, người đề nghị, người duyệt, ngày hết hạn và trạng thái bằng nhãn màu (`Chờ duyệt`, `Hiệu lực`, `Sắp hết hạn`, `Hết hạn`); ngoại lệ còn dưới 7 ngày có biểu tượng cảnh báo. Nút "Đề nghị ngoại lệ" mở biểu mẫu nhanh điền sẵn từ sự kiện chặn đã chọn ở UI-03-07, trường lý do bắt buộc có bộ đếm ký tự, trường hạn dùng bộ chọn ngày không cho chọn quá 90 ngày. Người duyệt thấy nút "Duyệt" và "Từ chối" kèm khung ý kiến; nút "Duyệt" bị vô hiệu với chính người đề nghị và có chú thích "Bạn đã đề nghị ngoại lệ này". Tab "Luật vá ảo" có ô soạn SecLang, nút "Thử khô" hiển thị số yêu cầu mẫu sẽ bị chặn trước khi gửi duyệt.

| Thành phần | Mô tả |
|---|---|
| Bảng ngoại lệ | Cột Route, Mã luật, Lý do, Người đề nghị, Người duyệt, Hạn, Trạng thái; lọc theo trạng thái |
| Biểu mẫu đề nghị | Route, mã luật (điền sẵn), lý do, hạn (tối đa 90 ngày), sự kiện căn cứ |
| Khối duyệt | Hiển thị mẫu yêu cầu đã che, số lần chặn 7 ngày, nút Duyệt hoặc Từ chối kèm ý kiến |
| Tab Luật vá ảo | Ô soạn luật, phạm vi, căn cứ, kết quả thử khô, hạn |

: Thành phần chính của UI-03-08

## 11. Truy vết

### 11.1. Chức năng hệ cũ → FR

Bảng dưới liệt kê chín mục `LGC` của D00-03 phần A có PH-03 là phân hệ đích, mỗi mục một kết luận theo D00-01 §3.2. Cột "FR" là các FR của tập này hiện thực chức năng.

| Mã | Chức năng hệ cũ | FR | Kết luận |
|---|---|---|---|
| LGC-BUS-041 | Bảo mật route, mã hóa bản tin, bảo mật endpoint (Basic, SSL, WS-Security) | 001, 002, 012, 013, 014, 015, 019; phần bảo mật ra HTTT ở PH-05, phần mã hóa trường nhạy cảm ở PH-04, PH-12 | Nâng cấp |
| LGC-APIM-005 | Start / Stop API | 036 (thực thi), 047 (tạm ngừng khẩn cấp); vòng đời ở PH-02 | Giữ nguyên |
| LGC-APIM-011 | Plan bước Secure: Keyless hoặc API key | 015, 016, 012, 014, 002; thêm OAuth 2.1, mTLS; Keyless chỉ dữ liệu mở | Nâng cấp |
| LGC-APIM-012 | Plan bước Restriction: rate limit (giây, phút) | 021, 024, 025, 026 | Giữ nguyên |
| LGC-APIM-013 | Plan bước Restriction: quota (giờ, ngày, tháng) | 022, 025, 026 | Giữ nguyên |
| LGC-APIM-014 | Plan bước Restriction: whitelist, blacklist đường dẫn | 020 | Giữ nguyên |
| LGC-APIM-015 | Plan bước Policies | 048 (bộ chính sách được duyệt sẵn), 040, 005, 009, 010, 011 | Nâng cấp |
| LGC-APIM-022 | Log toàn bộ request đến API của Application, xem chi tiết một log | 050, 051; che dữ liệu nhạy cảm; lưu trữ ở PH-13 | Nâng cấp |
| LGC-APIM-023 | Danh sách gateway đang kết nối | 045, 043; phần giám sát chi tiết ở PH-13 | Thay thế |

: Truy vết LGC sang FR của PH-03

Các mục `LGC` dưới đây không có PH-03 là phân hệ đích trong D00-03 nhưng PH-03 hiện thực một phần; kết luận chính giữ ở tập của phân hệ làm chính.

| Mã | Chức năng hệ cũ | Phân hệ làm chính | Phần PH-03 phủ | FR |
|---|---|---|---|---|
| LGC-APIM-017 | Xem chi tiết đường dẫn sử dụng API (gateway URL và context path) | PH-02, PH-15 | Địa chỉ host và đường dẫn thật của route | 028, 035 |
| LGC-APIM-018 | Quản lý endpoint backend của API (nhiều backend, cân bằng tải, kiểm tra sức khỏe) | PH-02 | Thực thi cân bằng tải, sức khỏe, ngắt mạch | 029, 030, 031 |
| LGC-APIM-019; LGC-APIM-020 | Danh sách, tạo Application và cấp Client ID | PH-01, PH-12 | Hình chiếu consumer ở gateway | 046 |
| LGC-APIM-024; LGC-APIM-025 | Chi tiết gateway, giám sát CPU, Java heap, JVM | PH-13 | Chỉ số APISIX thay cho chỉ số JVM | 045, 052 |
| LGC-APIM-026 | Dashboard hoạt động chung của hệ thống API | PH-13 | Phần lưu lượng gateway | 055 |
| LGC-APIM-027 | Audit: thông tin tác động hệ thống | PH-13 | Ghi kiểm toán thao tác cấu hình gateway | Mục "Kiểm toán" của mọi FR |
| LGC-NFR-006 | Tự từ chối khi vượt ngưỡng, cô lập lỗi, xử lý timeout | Cấp hệ thống | Rate limit, ngắt mạch, thời hạn chờ | 021, 026, 027, 030, 031 |

: Chức năng hệ cũ PH-03 phủ một phần

### 11.2. FR → REQ và FR của repo

| FR | REQ | FR cũ của repo (số FR trong `docs/07-srs/SRS-PH-03-gateway.md`) |
|---|---|---|
| 001, 002 | REQ-03 | 001, 007 |
| 003, 004 | REQ-03 | 002 |
| 005…008 | REQ-03 | 003 (tách thành bốn FR) |
| 009 | REQ-03 | 002 (giới hạn kích thước), bổ sung SEC-43 |
| 010 | REQ-03 | 014 |
| 011 | REQ-03 | Không có FR; trước đây là 015, 019 |
| 012, 013, 014 | REQ-03, REQ-12, REQ-20 | 004, 007 |
| 015, 016, 020 | REQ-03 | Mới, từ LGC-APIM-011; 014 |
| 017, 019 | REQ-03, REQ-09, REQ-12 | 006 (thêm OPA theo SEC-26) |
| 018 | REQ-03, REQ-12 | 005 |
| 021, 024, 025, 026 | REQ-03 | 008 |
| 022 | REQ-03 | 009 |
| 023 | REQ-03, REQ-20 | Mới, từ D03-10 §5.3, SEC-86 |
| 027 | REQ-03 | 010 |
| 028, 038 | REQ-03, REQ-20 | 011 |
| 029, 030, 031 | REQ-03 | 011, 016 |
| 032 | REQ-03, REQ-13 | 012 |
| 033, 034 | REQ-03 | 013 |
| 035, 036, 037 | REQ-03, REQ-02, REQ-20 | Mới, từ LGC-APIM-005; NFR-00-055, D03-10 §5.4 |
| 039…045 | REQ-03 | 015 (tách thành bảy FR theo ADR-005 bản 0.2, không etcd) |
| 046 | REQ-01, REQ-03 | Mới, từ LGC-APIM-019; 020 |
| 047, 048, 049 | REQ-03 | Mới, từ SEC-25, LGC-APIM-015; SEC-35 |
| 050, 051 | REQ-03, REQ-13 | 017 (phần nhật ký truy cập) |
| 052, 053 | REQ-03, REQ-13 | 017 (phần chỉ số, vết) |
| 054, 055 | REQ-03, REQ-13, REQ-21 | Mới, từ SEC-63, SEC-64, UI-03-01 của repo |
| 056, 057 | REQ-03, REQ-18 | Mới |
| 058 | REQ-03, REQ-13, REQ-16 | Mới, từ LGC-APIM-022 |
| 059 | REQ-22 | Mới, từ FR-00-090, 093 |

: Truy vết FR sang REQ và FR cũ

### 11.3. Ánh xạ mã cũ của repo sang mã mới

Ba bảng dưới phủ đủ 17 FR, 28 NFR và 12 BR của SRS cũ. Với mỗi mã cũ, bảng nêu mã mới và điều thay đổi, nhất là các điểm được điều chỉnh theo quyết định đã chốt sau SRS cũ (APISIX chế độ khai báo không etcd, lớp biên trong APISIX, đa tenant, Keycloak và OPA).

| FR cũ (số) | Tên | FR mới | Thay đổi so với SRS cũ |
|---|---|---|---|
| 001 | Chấm dứt TLS | 001, 002 | Biên TLS 1.3 (cũ: tối thiểu 1.2); 1.2 chỉ qua ngoại lệ có hạn; xác minh mTLS tách thành FR riêng; mTLS nội bộ do mesh Istio ambient (SEC-15) |
| 002 | Giảm thiểu tấn công từ chối dịch vụ | 003, 004, 009, 023 | Tách giới hạn IP, chặn tạm, kích thước thân; thêm hạn mức toàn tenant; bỏ "siết hạn mức tự động khi tốc độ tăng 10 lần" thay bằng điều tiết theo backend (027) và chặn IP tự động (004) |
| 003 | Tường lửa ứng dụng web | 005, 006, 007, 008 | Coraza trong APISIX (ADR-033); mức hoang tưởng theo loại route; chế độ phát hiện 14 ngày trước khi chặn; ngoại lệ có bốn mắt; thêm luật vá ảo; "quá tải thì chỉ ghi nhận" thành tự hạ có điều kiện |
| 004 | Xác minh chữ ký JWT | 012, 013, 014 | JWKS đệm 10 phút và làm mới theo `kid` (cũ: 24 giờ); thêm xác định tenant (SEC-80) và ràng buộc chứng thư; đệm tối đa 24 giờ chỉ khi Keycloak ngừng |
| 005 | Kiểm tra token bị thu hồi | 018 | Danh sách chặn ở Valkey, hiệu lực ≤ 60 giây theo SEC-25; PH-12 đẩy qua API có scope riêng |
| 006 | Kiểm tra phạm vi quyền thô | 017, 019 | Giữ kiểm tra scope; thêm gọi OPA tại gateway (SEC-26, ADR-006) với ranh giới hai tầng rõ hơn |
| 007 | Xác thực bằng chứng thư mTLS | 002, 014 | mTLS theo RFC 8705 (`tls_client_auth`); bắt buộc cho hợp đồng mức Nhạy cảm (SEC-24) |
| 008 | Giới hạn tần suất theo client | 021, 024, 025, 026 | Thêm hạn mức theo route và thứ tự ưu tiên; suy giảm khi Valkey mất chia theo số bản sao |
| 009 | Hạn ngạch theo chu kỳ | 022 | Giữ cảnh báo 80%; nhóm `ESSENTIAL` vượt tối đa 20% rồi chặn (cũ: cho vượt không giới hạn) |
| 010 | Điều tiết theo tình trạng hạ nguồn | 027 | Tách khỏi ngắt mạch (031); hệ số theo nhóm ưu tiên cụ thể |
| 011 | Định tuyến yêu cầu | 028, 029, 036, 038 | Host hoặc tiền tố theo tenant; thêm dừng, mở API; thêm phân cửa vào Internet và nội bộ (ADR-033) |
| 012 | Sinh và gắn định danh truy vết | 032 | Giữ nguyên; thêm lấy mẫu vết theo tail sampling |
| 013 | Chuyển đổi giao thức | 033, 034 | WebSocket và nén là M (CV 631); gRPC và REST hạ xuống C, Đợt 3 |
| 014 | Xử lý CORS | 010 | Giữ nguyên; Đợt 2 vì giao diện cùng nguồn gốc với BFF ở MVP |
| 015 | Nạp nóng cấu hình | 039, 040, 041, 042, 043, 044, 045 | Không dùng etcd (ADR-005 bản 0.2): ảnh chụp có phiên bản và chữ ký qua Git và bucket, bộ đồng bộ cạnh pod, nút kiểm chữ ký và không nạp lùi |
| 016 | Kiểm tra sức khỏe hạ nguồn | 030, 031 | Giữ chu kỳ 5 giây, 3 lần loại, 2 lần đưa lại; khi mọi nút hỏng thì trả `503` nhanh thay vì giữ nút ít lỗi nhất (BR-03-011, Q03-03) |
| 017 | Phát telemetry | 050, 052, 053, 054, 055 | Tách nhật ký lượt gọi (che dữ liệu, ClickHouse), chỉ số, kiểm tra tổng hợp, cảnh báo, bảng điều khiển |

: Ánh xạ FR cũ sang FR mới

| NFR cũ (số) | Nội dung cũ (tóm tắt) | NFR mới | Thay đổi |
|---|---|---|---|
| 001 | Độ trễ thêm P50 ≤ 3 ms, P95 ≤ 8 ms, P99 ≤ 15 ms | NFR-03-001 | Theo NFR-00-001: p95 ≤ 50 ms, p99 ≤ 100 ms đã gồm WAF; chặt hơn giữ ở chi phí từng chốt (NFR-03-002) |
| 002, 003 | Thông lượng 3.000 mỗi bản sao, 10.000 toàn cụm | NFR-03-003 | Theo NFR-00-002 và định cỡ D03-09 (1.000 lượt/giây trên 3 bản sao, danh định 3.000) |
| 004, 005, 006 | JWT ≤ 2 ms, hạn mức ≤ 3 ms, WAF ≤ 5 ms | NFR-03-002 | Gộp, thêm OPA ≤ 2 ms |
| 007 | ≥ 20.000 kết nối mỗi bản sao | NFR-03-004 | Giữ, ghi giả định |
| 008 | Sẵn sàng ≥ 99,95% | NFR-03-005 | Giữ như mục tiêu riêng của gateway; hệ thống KPI-03 là 99,9% (Q03-01) |
| 009 | 3 bản sao, ≥ 2 vùng | NFR-03-006 | Giữ |
| 010 | Nạp cấu hình 0 lỗi | NFR-03-008 | Giữ, thêm độ trễ lan truyền ≤ 10 giây |
| 011 | Mất etcd, phục vụ ≥ 24 giờ | NFR-03-007 | Mở rộng sang mất control plane, Git, bucket, Keycloak (không còn etcd) |
| 012 | Tắt an toàn 30 giây | NFR-03-024 | Giữ, thêm nâng cấp cuốn chiếu |
| 013 | Gia hạn chứng thư tự động | NFR-03-011 | Giữ |
| 014 | TLS ≥ 1.2, quét SSL mức A | NFR-03-010 | Nâng thành A+ và TLS 1.3 ở biên (SEC-12) |
| 015, 019 | Không lộ phiên bản; tiêu đề bảo mật | NFR-03-015 | Gộp |
| 016 | Không ghi thân bản tin | NFR-03-014 | Mở rộng cho chỉ số, vết, tiêu đề xác thực |
| 017, 018 | Khóa riêng ở Vault; container không root | NFR-03-016 | Gộp; Vault thành OpenBao |
| 020 | Ngoại lệ WAF có hạn và người duyệt | BR-03-006 | Chuyển thành quy tắc nghiệp vụ |
| 021, 022 | HPA 70% từ 3 đến 10 bản sao; không trạng thái | NFR-03-018 | Ngưỡng CPU 60% theo D03-09 |
| 023 | ≥ 1.000 route | NFR-03-017 | Thêm mức 70.000 route cho `QM-CHUNG` (Q338) |
| 024 | IPv6 | NFR-03-025 | Giữ |
| 025, 026, 027 | `traceId`, nhật ký JSON, lấy mẫu vết | NFR-03-020 | Gộp |
| 028 | Độ trễ chỉ số ≤ 15 giây | NFR-03-021 | Giữ |

: Ánh xạ NFR cũ sang NFR mới

| BR cũ (số) | Nội dung cũ (tóm tắt) | BR mới | Thay đổi |
|---|---|---|---|
| 001 | Mọi lưu lượng qua Gateway | BR-03-001 | Giữ |
| 002 | Không TLS dưới 1.2 | BR-03-003 | TLS 1.3 ở biên, 1.2 theo ngoại lệ có hạn |
| 003 | Xác minh JWT cục bộ | BR-03-004 | Thêm ràng buộc chứng thư cho mức Nhạy cảm |
| 004 | Hạn mức theo `clientId` | BR-03-005 | Giữ |
| 005 | Ngoại lệ WAF có lý do, người duyệt, ≤ 90 ngày | BR-03-006 | Người duyệt khác người đề nghị, theo route và mã luật |
| 006 | Không ghi thân bản tin | BR-03-007 | Mở rộng cho tiêu đề xác thực và tham số truy vấn |
| 007 | Kiểm soát thô tại Gateway, chi tiết ở PH-04 và PH-12 | BR-03-008 | Chi tiết do OPA tại gateway và tại DU |
| 008 | `ESSENTIAL` được ưu tiên khi điều tiết | BR-03-009 | Thêm mức vượt hạn ngạch tối đa 20% |
| 009 | Thay đổi cấu hình nạp nóng | BR-03-010 | Giữ |
| 010 | Khi mọi hạ nguồn không khỏe, giữ thực thể tốt nhất | BR-03-011 | Đổi: trả `503` nhanh và thăm dò định kỳ (Q03-03) |
| 011 | Không ký tự đại diện cho CORS | BR-03-012 | Giữ |
| 012 | Không lộ phiên bản phần mềm | BR-03-013 | Giữ |

: Ánh xạ BR cũ sang BR mới

Các kịch bản kiểm thử chấp nhận cũ `AT-03-001…032` chuyển sang tập D05-02-PH03; điều kiện nghiệm thu cũ (12 FR mức M, 32 kịch bản, 8 mục tuân thủ) được thay bằng mục 14.

## 12. Phụ thuộc, giả định và ràng buộc

### 12.1. Phụ thuộc

| Phụ thuộc | Loại | Dùng cho | Khi không khả dụng |
|---|---|---|---|
| OPA sidecar và gói chính sách ký (PH-12) | Cứng với từng lượt gọi cần ủy quyền | FR-03-019 | Đóng an toàn, ERR-03-124 (503); gói chính sách lưu bền nên OPA khởi động lại vẫn có chính sách gần nhất |
| Valkey | Mềm | Bộ đếm hạn mức, danh sách chặn token, khóa chặn IP, kill switch | Suy giảm có kiểm soát (FR-03-026); danh sách chặn dùng bộ đệm gần nhất |
| Keycloak (JWKS) | Mềm | Xác minh JWT | Dùng JWKS đã đệm tới 24 giờ; sau đó ERR-03-124 |
| Garage (bucket `dh-platform-gateway`) | Mềm | Đường nhanh của ảnh chụp | Nút giữ cấu hình hiện tại; đường ConfigMap từ Git thay thế |
| Git cấu hình, Argo CD | Mềm | Lịch sử, đường dự phòng | Phát tiếp qua bucket, xếp hàng ghi Git |
| OpenBao (transit, PKI) | Cứng với ký và cấp chứng thư mới | FR-03-041, 049 | Không ký, không phát được (ERR-03-015); cấu hình đang chạy không đổi |
| `pg-core` | Cứng với API quản trị, mềm với data plane | Dữ liệu `ph03_gateway` | API quản trị lỗi; gateway vẫn phục vụ bằng cấu hình đã nạp |
| PH-02 | Mềm | Nguồn API, gói, đăng ký | Dùng bản chiếu gần nhất; quá 24 giờ thì cảnh báo |
| PH-01 | Mềm | Nguồn HTTT, saga | Saga chờ; gateway giữ trạng thái consumer đã nạp |
| PH-12 | Mềm | Gói chính sách, thu hồi token | Dùng gói đã lưu bền; thu hồi mới chờ PH-12 trở lại |
| PH-13 (ClickHouse, Mimir, Loki, Alertmanager) | Mềm | Nhật ký, chỉ số, cảnh báo | Bộ đệm đĩa giữ siêu dữ liệu; màn hình báo "chưa có số liệu" (ERR-03-026) |
| PH-20 | Mềm | Host, hạn mức hợp đồng, sáp nhập | Dùng giá trị đã lưu |
| Kafka | Mềm | Sự kiện qua outbox | Outbox giữ sự kiện, phát khi Kafka trở lại |
| cert-manager, External Secrets | Mềm | Chứng thư biên | Chứng thư hiện tại còn hiệu lực tới hạn; cảnh báo theo FR-03-049 |
| Backend của route | Cứng theo từng route | Đích của lượt gọi | ERR-03-120, 121, 122 cho route đó; route khác không ảnh hưởng |

: Phụ thuộc của PH-03

### 12.2. Giả định

| Mã | Giả định | Cơ sở |
|---|---|---|
| GĐ-03-01 | Tỉnh vừa: 200 HTTT, khoảng 5 API mỗi HTTT nên khoảng 1.000 route mỗi tenant, cao điểm 300 lượt/giây | GĐ-04, GĐ-07 ở D02-01, D02-02; số route là suy ra từ số HTTT |
| GĐ-03-02 | Mỗi tenant sinh 5 triệu bản ghi siêu dữ liệu lượt gọi mỗi ngày | NFR-00-062 |
| GĐ-03-03 | Khoảng 10% API là "quan trọng" cần kiểm tra tổng hợp (khoảng 100 kiểm tra mỗi phút mỗi tenant vừa) | Giả định để định cỡ bộ chạy kiểm tra; thay bằng số khảo sát |
| GĐ-03-04 | Khoảng 30% HTTT dùng mTLS (mức Hạn chế, Nhạy cảm), 70% dùng OAuth 2.1 `private_key_jwt` hoặc `client_secret` | SEC-24; tỷ lệ theo mức phân loại dữ liệu điển hình, thay bằng số thật khi khảo sát |
| GĐ-03-05 | Tenant vừa trở lên có ít nhất hai Cán bộ ATTT để bốn mắt cho ngoại lệ WAF; tenant nhỏ dùng PA duyệt thay (Q03-02) | Thực tế tổ chức của các tỉnh; cần xác nhận |
| GĐ-03-06 | Mỗi bản sao APISIX 1 vCPU; WAF chiếm thêm 30 đến 50% CPU | ADR-033, D03-09 §5 |
| GĐ-03-07 | Tổng hợp, kiểm tra, ký một ảnh chụp tenant 1.000 route mất ≤ 5 giây | Giả định thiết kế; kiểm chứng ở D05-02-PH03 |
| GĐ-03-08 | Backend của HTTT có `/readyz` hoặc cho phép kiểm tra TCP | Thực tế triển khai; nếu không, dùng kiểm tra thụ động |
| GĐ-03-09 | Dải địa chỉ của NDXP và bộ giám sát tổng hợp cố định và khai báo được | D03-09 §4; cần xác nhận khi khảo sát |

: Giả định của PH-03

### 12.3. Ràng buộc

| Ràng buộc | Nguồn |
|---|---|
| Quản lý API, xác thực OAuth, giới hạn tần suất, chống tấn công từ chối dịch vụ | CMP-LAW-09 |
| Hỗ trợ HTTP, HTTPS, WebSocket; sẵn sàng IPv6; hoạt động 24/7, thay đổi cấu hình không gián đoạn | CMP-LAW-09 |
| TLS 1.3 ở biên, mTLS nội bộ; không hạ dưới TLS 1.2 | NFR-00-020, SEC-12, CMP-LAW-08 |
| APISIX chế độ khai báo, không etcd; WAF Coraza trong APISIX; không Envoy, không Ingress NGINX | ADR-005, ADR-033 |
| `dh-connect` là Spring Boot Modulith, schema `ph03_gateway`, REST `/api/gateway/v1` | ADR-001, D00-04 §4 |
| Toàn bộ công nghệ mã nguồn mở | Yêu cầu dự án |
| Nhật ký lượt gọi không chứa dữ liệu cá nhân | CMP-LAW-05, SEC-32 |
| Thông tin xác thực của hệ cũ không di trú nguyên trạng | FR-00-093 |

: Ràng buộc của PH-03

## 13. Câu hỏi mở

> **Câu hỏi mở Q03-01:** NFR-03-005 đặt sẵn sàng của gateway ≥ 99,95% mỗi tháng (kế thừa SRS cũ), chặt hơn KPI-03 99,9% của data plane. Có đưa mục tiêu 99,95% vào cam kết với chủ đầu tư hay chỉ giữ 99,9%. Đề xuất: giữ 99,95% làm mục tiêu thiết kế, cam kết 99,9%. Cần ý kiến hội đồng thẩm định.

> **Câu hỏi mở Q03-02:** Tenant chỉ có một Cán bộ ATTT thì không thể bốn mắt cho ngoại lệ WAF (BR-03-006). Đề xuất: PA duyệt thay khi tenant có dưới hai SO, kiểm toán ghi rõ "duyệt thay"; hoặc TA duyệt. Cần ý kiến đơn vị thẩm định ATTT.

> **Câu hỏi mở Q03-03:** SRS cũ giữ lại thực thể ít lỗi nhất khi mọi backend không khỏe; tài liệu này đổi thành trả `503` nhanh và thăm dò định kỳ (BR-03-011). Cần xác nhận với vận hành: với backend duy nhất của dịch vụ công thiết yếu, có muốn giữ lưu lượng vào backend dù lỗi cao không.

> **Câu hỏi mở Q03-04:** Đầu vào `purpose` (mục đích khai thác) của OPA ở FR-03-019 lấy từ claim của token hay từ một tiêu đề do bên gọi gửi (tên tiêu đề). Tiêu đề `X-DH-*` bị xóa nên không dùng được. Cần thống nhất với PH-09 và PH-12.

> **Câu hỏi mở Q03-05:** Giới hạn theo IP cho API máy 200 yêu cầu/giây/IP (`gw.ip.apiReqPerSecond`) là giả định. Cần số liệu nhật ký gateway cũ ở ít nhất ba tỉnh (cùng nguồn với Q330 ở D03-09) để chốt mặc định, tránh chặn nhầm các sở chung địa chỉ sau NAT.

> **Câu hỏi mở Q03-06:** Phiên bản APISIX 3.x được chọn có hỗ trợ `limit-count` kiểu cửa sổ trượt không. Nếu không, dùng cửa sổ cố định kèm `limit-req` làm mượt và chấp nhận đột biến ở ranh giới cửa sổ; cần xác minh ở giai đoạn thiết kế chi tiết D03-02-PH03.

> **Câu hỏi mở Q03-07:** Có HTTT thật cần gRPC qua gateway không (FR-03-034 mức C, Đợt 3). Nếu không có nhu cầu trong 12 tháng đầu, đề xuất bỏ FR này khỏi phạm vi.

> **Câu hỏi mở Q03-08:** Giới hạn 500 giá trị nhãn `consumer` cho chỉ số (`gw.metrics.maxConsumerLabels`) có đủ với hồ sơ `QM-CHUNG` (34 tenant) không, hay cần chuyển thống kê theo HTTT hoàn toàn sang ClickHouse. Cần ước lượng số chuỗi thời gian cùng PH-13.

> **Câu hỏi mở Q03-09:** Chứng thư cho host Internet của hồ sơ HT-A (on-prem) do CA nào cấp (CA nhà nước hay ACME) và ai sở hữu tên miền `*.datahub.gov.vn`. Ảnh hưởng tới tự động gia hạn ở FR-03-049.

> **Câu hỏi mở Q03-10:** BR-03-020 kế thừa nguyên tắc "chia sẻ dữ liệu giữa cơ quan nhà nước không thu phí" của SRS cũ (dẫn NĐ 47/2020, đã được NĐ 278/2025 thay thế). Cần đối chiếu điều khoản tương ứng của NĐ 278/2025 để viện dẫn đúng.

> **Câu hỏi mở Q03-11:** Plugin do Datahub tự viết (`dh-revocation`, `dh-ip-block`, `dh-kill-switch`, `dh-path-acl`, `dh-waf-guard`, `dh-adaptive-throttle`) viết bằng Lua trực tiếp, Go plugin runner hay proxy-wasm. ADR-005 chỉ nói "Lua hoặc runner ngoài". Cần ADR bổ sung (ghi ở "Đề nghị đồng bộ") trước khi viết D03-02-PH03.

> **Câu hỏi mở Q03-12:** Bộ đếm hạn ngạch theo tháng ở Valkey có cần bền qua sự cố mất Valkey không (AOF hoặc sao lưu). Đề xuất MVP: chấp nhận đặt lại, số liệu chính xác lấy từ ClickHouse; nếu có đối tác cần hạn ngạch cam kết, bật lưu bền cho khóa hạn ngạch.

## 14. Tiêu chí chấp nhận cấp phân hệ

1. Mọi FR mức M có ít nhất một ca kiểm thử dương và một ca âm đạt ở D05-02-PH03; ca rò rỉ chéo tenant (token tenant A gọi route tenant B, `X-DH-*` giả) đạt cho mọi route mẫu.
2. Đạt NFR-03-001, 003, 006, 007, 008, 009, 012, 013 ở hồ sơ "tỉnh vừa": độ trễ thêm p95 ≤ 50 ms đã gồm WAF; phát cấu hình dưới tải 2.000 lượt/giây có 0 lượt gọi lỗi; thu hồi token bị chặn ≤ 60 giây.
3. Kiểm thử hỗn loạn: tắt toàn bộ `dh-connect`, Argo CD, Git, bucket và Keycloak; gateway tiếp tục phục vụ đúng ít nhất 24 giờ; một pod bị lập lịch lại trong thời gian đó khởi động được với cấu hình ConfigMap.
4. Nút từ chối ảnh chụp có chữ ký sai hoặc số phiên bản không lớn hơn bản đang chạy; cấu hình có route thiếu lược đồ OpenAPI hoặc chính sách OPA bị chặn ở FR-03-040 và không tới gateway.
5. Bộ payload OWASP bị chặn đúng; ngoại lệ WAF chỉ có hiệu lực sau khi người thứ hai duyệt, tự hết hạn đúng ngày, không quá 90 ngày; chuyển sang chế độ chặn bị từ chối khi chưa đủ 14 ngày phát hiện.
6. Valkey tắt giữa tải: không lượt gọi nào bị từ chối vì lý do đó, phản hồi có `X-RateLimit-Degraded`, cảnh báo phát ≤ 1 phút, và hạn mức theo số bản sao còn hiệu lực.
7. Ca kiểm thử rò rỉ dữ liệu: gửi yêu cầu chứa giá trị đánh dấu `DH-CANARY-…` ở thân, tham số truy vấn, tiêu đề `Authorization`; không tìm thấy giá trị ở nhật ký lượt gọi, chỉ số, vết, nhật ký WAF, tệp xuất.
8. Quét testssl.sh đạt A+; TLS 1.1 bị từ chối; chứng thư gia hạn thử không cắt kết nối; hai cửa vào truy cập được qua IPv6.
9. Saga kết nạp HTTT mẫu tạo consumer, gọi API qua gateway thành công trong ≤ 10 giây sau khi saga báo xong; bù trừ gỡ consumer; HTTT tạm ngừng bị chặn ≤ 30 giây.
10. Mọi mục `LGC` ở mục 11.1 có kết luận và ca UAT tương ứng ở D05-02-PH03; 17 FR, 28 NFR, 12 BR của SRS cũ đều có hàng ánh xạ ở mục 11.3.

## Đề nghị đồng bộ

Tập này không sửa tài liệu dùng chung; các việc dưới đây để đợt đồng bộ cuối thực hiện (hoặc các luồng phân hệ khác tiếp nhận).

| Tài liệu | Đề nghị |
|---|---|
| D02-08 §3.1 | Bổ sung tám quyền: `PERM-03-limit` (PA, TA), `PERM-03-waf-request` (PA, TA, TO, SO), `PERM-03-waf-approve` (SO), `PERM-03-waf` (PA, SO), `PERM-03-operate` (PA, TA, TO, SO), `PERM-03-publish` (PA, TA), `PERM-03-approve` (TA, SO), `PERM-03-log-read` (PA, TA, TO, SO, AU); giữ nguyên `PERM-03-read`, `PERM-03-admin`. Thêm cặp bốn mắt cho ngoại lệ WAF vào D02-08 §4. Ghi scope dịch vụ `gateway:sync`, `gateway:revoke`, `gateway:read-state` |
| D00-01 §6 | Thêm nhóm REST `gateway` (`/api/gateway/v1`) vào danh sách nhóm; thêm quy ước mã lỗi gateway `ERR-03-101…199` trả cho bên gọi |
| D03-01 §4.3 | Mô tả `dh-connect` phần PH-03: bộ tổng hợp, kiểm tra, ký, phát; danh mục plugin do Datahub viết (`dh-revocation`, `dh-ip-block`, `dh-kill-switch`, `dh-path-acl`, `dh-waf-guard`, `dh-adaptive-throttle`); kênh nhanh Valkey cho thu hồi token và tạm ngừng khẩn cấp song song với ảnh chụp |
| ADR (đề xuất, không tạo ở tập này) | (1) ADR về plugin APISIX do Datahub tự viết và danh mục plugin được duyệt, bổ sung ADR-005 (Q03-11); (2) ADR về kênh nhanh Valkey cho thu hồi token và tạm ngừng khẩn cấp; (3) ADR về mô hình mảnh tenant và bản ghép nền tảng của ảnh chụp cấu hình ở `QM-CHUNG` (liên quan Q338). Dải còn trống: ADR-014…019, 024…029, 039, 074 |
| D03-09 §6.1 | Ghi rõ cấu trúc bucket `dh-platform-gateway` (`snapshots/{site}/{version}/`, con trỏ `current`), kho Git thư mục `gateway/{site}/`, khóa ký `transit/keys/dh-gateway-snapshot`, và việc bộ đồng bộ điền chứng thư, khóa riêng từ Secret vào tệp cục bộ (khóa riêng không vào Git hay bucket) |
| D03-07 | SEC-25: ghi rõ đường đẩy danh sách chặn là PH-12 gọi API-03-053, `dh-connect` ghi Valkey; SEC-24: thêm kiểm tra khi phát cấu hình (CHK-06) bảo đảm 0 client dùng `client_secret` cho hợp đồng từ mức Hạn chế |
| D03-10 §5.3 | Ghi rõ nhóm `ESSENTIAL` không được miễn hạn mức toàn tenant; thêm cơ chế chuyển tiếp tenant sáp nhập ở gateway (FR-03-037) vào §5.4 |
| D03-06-00 §2.3 | Thêm nhóm menu "Cổng API" với các route: `/cong-api/tong-quan`, `/cong-api/route`, `/cong-api/route/{ma}`, `/cong-api/consumer`, `/cong-api/consumer/{ma}`, `/cong-api/han-muc`, `/cong-api/waf`, `/cong-api/waf/ngoai-le`, `/cong-api/nhat-ky`, `/cong-api/cau-hinh`, `/cong-api/nut`, `/cong-api/chung-thu`, `/cong-api/mau-chinh-sach`, `/cong-api/chay-thu`, `/cong-api/chan-dia-chi`, `/cong-api/tham-so`, `/cong-api/duyet`, `/cong-api/nhap-he-cu` |
| D03-06-PH03 (tập sau) | Dựng ảnh hi-fi UI-03-01 và UI-03-08 ở `03-thiet-ke/uiux/ph03/hifi/`; bảng thông báo ở mục 9.2 của tài liệu này là nguồn cho §5.2 |
| D00-03 phần A | Cân nhắc thêm PH-03 vào cột phân hệ đích của LGC-APIM-017; 018, 019, 020, 026, 027 và ghi nhận PH-03 phủ một phần (mục 11.1 bảng thứ hai) |
| Tập của PH-02, PH-01, PH-12, PH-13, PH-20 | PH-02: sự kiện và API đọc cho FR-03-039 (API, gói, đăng ký, `critical`, `deprecatedAt`, `sunsetAt`, `policyPackage`); nhận EVT-03-01, 03, 07, 12. PH-01: saga gọi API-03-013…015, nhận EVT-03-04. PH-12: đẩy thu hồi qua API-03-053; nguồn của gói chính sách OPA và JWKS. PH-13: luật cảnh báo GW-A01…A13, lược đồ ClickHouse siêu dữ liệu ở FR-03-050, truy vấn thống kê cho UI-03-01, 09. PH-20: host, hạn mức hợp đồng, trạng thái `MERGED` cho FR-03-037 |
| D00-04 §3.2 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi hợp nhất tập này: FR-03 (59), NFR-03 (27), BR-03 (30), API-03 (96), EVT-03 (12), ERR-03 (57 mã) |
| Rà soát chéo bảy tập PH-03 | Hạn chế còn lại sau đợt rà soát: (1) `kiem_tra_ma.py` báo thiếu tám mã `PERM-03-*` cho tới khi D02-08 §3.1 được bổ sung theo hàng trên, đây là lỗi dự kiến và tự hết sau đợt đồng bộ; (2) câu thông báo ở FRS, UC là câu cụ thể theo ngữ cảnh, còn bảng ở D03-06-PH03 §5.2 và D03-04-PH03 §6.3 là câu chung của mã, hai loại cùng ý nghĩa và không cần trùng từng chữ; (3) trạng thái Mermaid chỉ được soát bằng phép kiểm cú pháp tĩnh, chưa dựng được hình vì runner không có `mmdc`, cần chạy `DH_PDF=1 build/build-docx.sh` ở đợt xuất |

: Đề nghị đồng bộ của tập FRS PH-03

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo chuẩn kết hợp: 59 FR (47 M, 11 S, 1 C) đặc tả 17 mục, 30 BR, 27 NFR, 18 UI, 96 API, 12 sự kiện, 57 mã lỗi; ma trận truy vết 9 mục LGC của D00-03 phần A và ánh xạ đủ 17 FR, 28 NFR, 12 BR của SRS PH-03 cũ; điều chỉnh theo ADR-005 bản 0.2 (APISIX khai báo không etcd), ADR-033, SEC-24, SEC-25, SEC-80, SEC-86; 12 câu hỏi mở Q03-01…12 |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: thêm EN-03-16…20, thứ tự chốt 9 và 10, FR-03-038 và 026, §8.2 gw.ip.*, câu ERR-03-001…004, 022, 023 ở §9.2, cột mã thành công ở §9.4 |
