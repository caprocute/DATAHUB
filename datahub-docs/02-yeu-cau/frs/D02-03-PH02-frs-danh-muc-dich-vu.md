---
ma_tai_lieu: D02-03-PH02
ten: Đặc tả yêu cầu chức năng phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, chủ quản dữ liệu và dịch vụ, kỹ sư dh-connect, kỹ sư tích hợp, kiểm thử viên
phan_he: PH-02
mo_ta: Đặc tả hành vi của phân hệ danh mục dịch vụ API gồm đăng ký, kiểm tra đặc tả OpenAPI, vòng đời và phiên bản, gói sử dụng, đăng ký sử dụng có duyệt, backend, đồng bộ danh mục quốc gia và cam kết chất lượng, làm căn cứ thiết kế chi tiết, lập trình và kiểm thử.
tai_lieu_lien_quan: D02-02 SRS; D02-04-PH02 Use case; D03-02-PH02 Thiết kế chi tiết; D03-03-PH02 CSDL; D03-04-PH02 API; D03-06-PH02 Màn hình; D05-02-PH02 Test case
---

# D02-03-PH02 · Đặc tả yêu cầu chức năng Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-02 là nơi giữ **hợp đồng** giữa bên cung cấp và bên khai thác dữ liệu trên Datahub. Mỗi dịch vụ chia sẻ dữ liệu được công bố dưới dạng một API có đặc tả OpenAPI 3.1; phân hệ kiểm tra đặc tả, điều phối vòng đời từ bản nháp tới khi ngừng dùng, quản lý phiên bản và kiểm tra tương thích, định nghĩa **gói sử dụng** (cách xác thực, hạn mức, đường dẫn được phép), xử lý **đăng ký sử dụng** có duyệt của từng hệ thống thông tin (HTTT), và đăng ký danh mục lên Nền tảng chia sẻ, điều phối dữ liệu quốc gia. PH-02 là nguồn sự thật về "cái gì được phép gọi, theo điều kiện nào"; việc thực thi lúc chạy do PH-03 (APISIX) làm, việc trình bày cho nhà phát triển do PH-15 làm.

**Phạm vi.** 62 yêu cầu chức năng chia mười nhóm: danh mục và tra cứu; đăng ký API và nạp đặc tả; kiểm tra đặc tả; backend, đường dẫn và khung route; gói sử dụng; vòng đời, duyệt và phiên bản; đăng ký sử dụng; đồng bộ danh mục quốc gia; cam kết chất lượng, thông báo và thống kê; tích hợp và quản trị. Phân hệ chạy trong đơn vị triển khai `dh-connect` (mặt phẳng điều khiển, Spring Boot) cùng PH-01, PH-03 (phần đồng bộ cấu hình) và PH-15 (phần máy chủ).

**Căn cứ pháp lý.** CMP-LAW-03 và CMP-LAW-19 (NĐ 278/2025 thay NĐ 47/2020: công bố, công khai, đăng ký danh mục dịch vụ chia sẻ dữ liệu; kết nối với Nền tảng chia sẻ quốc gia); CMP-LAW-01 và CMP-LAW-02 (Luật Dữ liệu số, NĐ 165/2025: phân loại, chia sẻ dữ liệu); CMP-LAW-09 (Công văn 631/THH-THHT: chức năng quản lý dịch vụ, cổng API của LGSP); CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3: xác thực máy–máy, kiểm soát truy cập, nhật ký); CMP-LAW-05 (Luật BVDLCN 91/2025: khai báo mục đích khai thác dữ liệu cá nhân).

**Những điểm hội đồng cần lưu ý.** (1) Không có API nào ra được gateway nếu chưa có đặc tả OpenAPI hợp lệ, đã qua hai lớp kiểm tra (chuẩn và quy ước nền tảng) và đã có người thứ hai duyệt; đặc tả chứa khóa hay token thật bị chặn tự động. (2) Thay đổi phá vỡ tương thích bắt buộc tăng số phiên bản chính; ngừng dùng một API đang có người khai thác phải có lộ trình tối thiểu 6 tháng, thông báo cho mọi bên đăng ký, và không bao giờ tự ngừng hẳn khi còn người dùng. (3) HTTT khai thác không được cấp quyền bằng tay: phạm vi truy cập `api:{mã API}:{mã gói}` sinh tự động từ đăng ký sử dụng đã duyệt; dữ liệu mức Hạn chế trở lên bắt buộc xác thực mTLS hoặc `private_key_jwt`. (4) Sự cố của PH-02 không làm gián đoạn API đang chạy, vì cấu hình đã nằm ở gateway (NFR-00-012). (5) Danh mục được đồng bộ lên Nền tảng quốc gia tự động và có cảnh báo tuân thủ khi quá hạn, để nghĩa vụ này không phụ thuộc việc ai đó nhớ làm.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng | 62 (M: 50, S: 11, C: 1) |
| Quy tắc nghiệp vụ | 40 (BR-02-001…040) |
| Yêu cầu phi chức năng | 20 (NFR-02-001…020) |
| Màn hình | 17 (UI-02-01…17) |
| API | 98 operation (API-02-001…098), 16 sự kiện (EVT-02-01…16), 45 mã lỗi (ERR-02-001…045) |
| Chức năng hệ cũ được phủ | 15 mục `LGC` của PH-02 (14 mục APIM, 1 mục Bus): 9 giữ nguyên, 5 nâng cấp, 1 thay thế; đủ 14 FR cũ của SRS cũ được ánh xạ |
| Mức đợt | MVP: 58 FR; Đợt 2: 4 FR (FR-02-009, 052, 058 mức S; FR-02-060 mức C) |

: Con số chính của PH-02

## 1. Giới thiệu

Chương này nói tài liệu viết cho ai, đặc tả những gì, và nằm ở đâu trong bộ tài liệu của Datahub. Người đọc chỉ cần đọc mục 1.2 và 1.3 để biết phần nào của tập này dành cho mình.

### 1.1. Mục đích của tài liệu

Tài liệu đặc tả đầy đủ hành vi của phân hệ PH-02 Danh mục dịch vụ, ở mức mà ba nhóm người đọc dùng được ngay không cần hỏi lại. Hội đồng thẩm định dùng tài liệu để đánh giá phân hệ có đáp ứng nghĩa vụ công bố, công khai, đăng ký danh mục dịch vụ chia sẻ dữ liệu và yêu cầu ATTT cấp độ 3 hay không, đồng thời có phủ trọn nghiệp vụ quản lý API của hệ cũ hay không. Kỹ sư dùng tài liệu làm đầu vào cho thiết kế chi tiết D03-02-PH02, thiết kế CSDL D03-03-PH02 và đặc tả API D03-04-PH02. Kiểm thử viên dùng các luồng xử lý, luồng ngoại lệ và quy tắc nghiệp vụ để viết ca kiểm thử ở D05-02-PH02.

Mỗi chức năng được đặc tả theo cùng một khung: mục đích, tác nhân, điều kiện trước, luồng xử lý chính theo từng bước, luồng thay thế, luồng ngoại lệ kèm thông báo người dùng nhìn thấy, quy tắc nghiệp vụ, kết quả, hậu điều kiện, sự kiện, kiểm toán và màn hình liên quan.

### 1.2. Phạm vi

PH-02 chịu trách nhiệm mười nhóm việc dưới đây.

| # | Trách nhiệm | Nhóm FR |
|---|---|---|
| 1 | Duy trì **danh mục API** của tenant: liệt kê, xem chi tiết, tìm kiếm toàn văn, phân loại, gắn thẻ, mức hiển thị; cung cấp danh mục cho bên khai thác và cho cổng nhà phát triển | A |
| 2 | Tiếp nhận API mới từ biểu mẫu, tệp, địa chỉ URL hoặc từ luồng của PH-04; giữ đặc tả OpenAPI qua mọi phiên bản | B |
| 3 | Kiểm tra đặc tả hai lớp (chuẩn OpenAPI 3.1 và quy ước nền tảng), quét bí mật, phát hiện API trùng chức năng | C |
| 4 | Quản lý **backend** của API (nhiều backend, cân bằng tải, kiểm tra sức khỏe), đường dẫn công bố, sinh khung route cho PH-04 | D |
| 5 | Quản lý **gói sử dụng** (Plan): điều kiện truy cập, kiểu xác thực, hạn mức và đường dẫn được phép, vòng đời bốn trạng thái | E |
| 6 | Điều phối **vòng đời** API (nháp, chờ duyệt, phát hành, tạm ngừng, ngừng khuyến nghị, ngừng), duyệt bốn mắt, phiên bản và kiểm tra tương thích, phân tích tác động | F |
| 7 | Xử lý **đăng ký sử dụng** của HTTT: gửi, duyệt, cấp phạm vi truy cập, tạm ngừng, thu hồi, rà soát định kỳ | G |
| 8 | Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14, theo dõi trạng thái, cảnh báo quá hạn | H |
| 9 | Cam kết chất lượng (SLA) và theo dõi tuân thủ; thông báo thay đổi cho bên khai thác; thống kê sử dụng | I |
| 10 | Giao diện nội bộ cho PH-03, PH-04, PH-15; đối soát cấu hình với gateway; di trú từ APIM cũ; tham số theo tenant | J |

: Trách nhiệm của PH-02

Những việc dưới đây liên quan nhưng không thuộc PH-02. Tài liệu chỉ mô tả điểm giao tiếp với các phân hệ đó.

| Không làm | Thuộc |
|---|---|
| Thực thi xác thực, giới hạn tần suất, hạn mức, chặn đường dẫn, ghi nhật ký lượt gọi lúc chạy; sinh và phát ảnh chụp cấu hình cho APISIX | PH-03 (PH-02 cung cấp dữ liệu công bố, PH-03 thực thi) |
| Kết nạp HTTT, cấp và xoay vòng định danh ứng dụng (client, khóa, chứng thư) | PH-01 |
| Cấp phạm vi (scope) lên client Keycloak, chính sách OPA | PH-12 (PH-02 chỉ phát yêu cầu gắn phạm vi theo đăng ký đã duyệt) |
| Hiển thị tài liệu API, thử API, sandbox, tự lấy thông tin xác thực cho nhà phát triển | PH-15 (PH-02 là nguồn dữ liệu) |
| Xử lý bản tin, chuyển đổi dữ liệu, thiết kế luồng; hiện thực logic của API | PH-04, PH-05 |
| Đăng ký topic và lược đồ sự kiện | PH-10 (PH-02 chỉ hiển thị topic `ACTIVE` như dịch vụ sự kiện) |
| Kết nối giao thức với Nền tảng quốc gia (chứng thư, giới hạn tần suất, mã hóa) | PH-14 (PH-02 gửi nội dung danh mục) |
| Đo lường, bảng điều khiển, cảnh báo vận hành chi tiết | PH-13 (PH-02 phát chỉ số và đọc chỉ số thực tế để đối chiếu SLA) |
| Thanh toán, thu phí sử dụng API | PH-19 (chia sẻ dữ liệu giữa cơ quan nhà nước không thu phí; đơn giá gói chỉ là thông tin, Q02-09) |

: Việc ngoài phạm vi PH-02

### 1.3. Đối tượng sử dụng và cách đọc

Bảng dưới nêu từng nhóm người đọc cần đọc phần nào của tập để làm việc của mình.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, chương 5, chương 11, chương 14 | Đánh giá sự cần thiết, mức đáp ứng nghĩa vụ công bố và an toàn, mức phủ nghiệp vụ hệ cũ |
| Chủ đầu tư, đơn vị chủ quản dữ liệu và dịch vụ | Chương 2, chương 3, mục 6.2, 6.7, 6.8, chương 10 | Biết việc mình phải làm: khai báo API, viết đặc tả, duyệt đăng ký, lộ trình ngừng dùng |
| Kỹ sư phát triển | Chương 4, chương 6, chương 7, chương 9 | Hiện thực API, xử lý, quy tắc, mã lỗi |
| Kiểm thử viên | Chương 6, chương 7, chương 8, chương 14 | Viết ca kiểm thử dương, âm, ca vòng đời, ca chéo tenant và ca rò rỉ bí mật trong đặc tả |
| Vận hành | Mục 6.8, 6.9, chương 8, chương 12 | Theo dõi đồng bộ quốc gia, SLA, đối soát cấu hình, xử lý sự cố |

: Người đọc và phần cần đọc

Mã định danh (FR, BR, NFR, ERR, EVT, API, UI) theo quy ước ở D00-01 §3. Chức năng dùng chung của mọi phân hệ (đăng nhập, chọn tenant, phân trang, lọc chuẩn, xuất Excel và CSV, kiểm toán chung, tab "Lịch sử", hộp "Việc của tôi", hiển thị lỗi chung) theo nhóm FR-00 của SRS và không lặp lại ở đây; các FR dưới đây chỉ nêu phần đặc thù của PH-02.

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới giải thích các thuật ngữ và chữ viết tắt dùng xuyên suốt tập; thuật ngữ chung của bộ tài liệu theo D00-01 §2.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| HTTT | Hệ thống thông tin của cơ quan, đơn vị đã kết nạp vào Datahub (PH-01) |
| Tenant | Một tỉnh dùng Datahub; dữ liệu và cấu hình của tenant tách biệt hoàn toàn với tenant khác |
| API | Một dịch vụ chia sẻ dữ liệu có đặc tả OpenAPI, do một HTTT cung cấp, công bố qua gateway; mã `apiCode` duy nhất trong tenant |
| Phiên bản API | Một lần phát hành của API, đánh số theo ngữ nghĩa `MAJOR.MINOR.PATCH`; mỗi phiên bản có đặc tả, backend, gói sử dụng và trạng thái vòng đời riêng |
| OpenAPI | Chuẩn mở mô tả API HTTP; Datahub dùng bản 3.1 |
| Gói sử dụng (Plan) | Điều kiện một HTTT được gọi một phiên bản API: kiểu xác thực, hạn mức, đường dẫn được phép, điều kiện đăng ký |
| Đăng ký sử dụng (Subscription) | Việc một HTTT xin dùng một gói của một phiên bản API và được duyệt |
| Backend | Điểm cuối phía sau gateway thật sự xử lý lời gọi: một HTTT cung cấp, hoặc một luồng của PH-04 |
| Context-path | Tiền tố đường dẫn công bố của API tại gateway, dạng `/{nhóm}/{apiCode}/v{major}` |
| Lớp 1, lớp 2 | Hai lớp kiểm tra đặc tả: lớp 1 theo chuẩn OpenAPI, lớp 2 theo quy ước nền tảng |
| Thay đổi phá vỡ | Thay đổi làm lời gọi hợp lệ của bên khai thác hiện có bị lỗi (xóa trường, đổi kiểu, thêm trường bắt buộc, đổi mã lỗi) |
| Ngừng khuyến nghị (`DEPRECATED`) | Trạng thái API vẫn phục vụ nhưng báo trước sẽ ngừng, có phiên bản kế nhiệm và hạn chuyển đổi |
| Dịch vụ sự kiện | Topic `ACTIVE` của PH-10 hiển thị trong danh mục như một dịch vụ để HTTT tìm và đăng ký |
| SLA | Cam kết chất lượng dịch vụ: độ trễ p99, tỷ lệ sẵn sàng, hạn mức, giờ phục vụ |
| Mặt phẳng điều khiển, mặt phẳng dữ liệu | Phần quản trị cấu hình (`dh-connect`), và phần xử lý lưu lượng thật (APISIX, `dh-runtime`) |
| Bốn mắt | Một việc quan trọng cần hai người khác nhau: một người đề nghị, một người duyệt |
| SV, CA, OR, TA, TO, SO, IE, PA, VW, AU | Vai trò: chủ dịch vụ, người duyệt dịch vụ, cán bộ đầu mối tổ chức, quản trị tenant, vận hành tenant, cán bộ ATTT, kỹ sư tích hợp, quản trị nền tảng, người xem, kiểm toán viên (mục 3.1) |
| p95, p99 | Phân vị 95, 99: tương ứng 95%, 99% số lượt đo có giá trị không vượt ngưỡng nêu |

: Thuật ngữ và chữ viết tắt

### 1.5. Tài liệu tham chiếu

Bảng dưới liệt kê các tài liệu mà tập này dựa vào và phần tập dùng từ từng tài liệu.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| CMP-LAW-03, CMP-LAW-19 | Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu | Công bố, công khai, đăng ký danh mục dịch vụ chia sẻ; kết nối Nền tảng quốc gia. Kế thừa NĐ 47/2020/NĐ-CP (Điều 24, 25, 26 của hệ cũ) |
| CMP-LAW-01, CMP-LAW-02 | Luật Dữ liệu số 60/2024/QH15, Nghị định 165/2025/NĐ-CP | Phân loại dữ liệu, chia sẻ dữ liệu |
| CMP-LAW-09 | Công văn 631/THH-THHT về yêu cầu kỹ thuật nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh | Quản lý dịch vụ, cổng API của LGSP |
| CMP-LAW-06, CMP-LAW-08 | Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 | Cấp độ 3: xác thực máy–máy, kiểm soát truy cập, nhật ký, tách nhiệm vụ |
| CMP-LAW-05 | Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 | Khai báo mục đích khai thác dữ liệu cá nhân khi đăng ký sử dụng |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | Nhóm FR-00, NFR-00 dùng chung; REQ-02 |
| D02-08 | Ma trận phân quyền | `PERM-02-*`, vai trò, phạm vi `api:{mã API}:{mã gói}` |
| D03-01 | Kiến trúc tổng thể (SAD) | Đơn vị triển khai `dh-connect`, vùng mạng |
| D03-07 | Thiết kế an toàn thông tin | SEC-16, SEC-24, SEC-26, SEC-43, SEC-80, SEC-81, SEC-87 |
| D03-09 | Hạ tầng triển khai và DR | Ảnh chụp cấu hình APISIX chế độ standalone, độ trễ lan truyền, RPO, RTO |
| ADR-005, ADR-013, ADR-033, ADR-057 | Quyết định về APISIX, tách mặt phẳng, lớp biên, đồng bộ quốc gia qua PH-14 | Lý do của các lựa chọn trong tài liệu |
| D02-03-PH04, D02-03-PH05, D02-03-PH10 | FRS các phân hệ liền kề | Điểm giao tiếp: luồng công bố API, kết nối, topic |
| `docs/07-srs/SRS-PH-02-api-catalog.md` | SRS cũ của PH-02 (bản 1.0) | Nguồn của FR-02-001…014 cũ, ánh xạ ở mục 11.2 |
| D03-06-PH02 | Thiết kế giao diện màn hình PH-02 | Bố cục chi tiết của 17 màn hình, câu thông báo |

: Tài liệu tham chiếu

### 1.6. Cấu trúc tài liệu

Chương 2 trình bày bối cảnh, mục tiêu và kiến trúc của phân hệ. Chương 3 nêu tác nhân và quyền. Chương 4 định nghĩa khái niệm, thực thể và vòng đời của các đối tượng chính. Chương 5 liệt kê toàn bộ 62 chức năng. Chương 6 đặc tả chi tiết từng chức năng theo khung thống nhất. Chương 7 đến chương 9 gom quy tắc nghiệp vụ, yêu cầu phi chức năng, tham số, mã lỗi, thông báo, sự kiện và API. Chương 10 giới thiệu giao diện tiêu biểu. Chương 11 đến chương 14 là truy vết, phụ thuộc, câu hỏi mở và tiêu chí chấp nhận.

## 2. Tổng quan phân hệ

Chương này dành cho hội đồng thẩm định và chủ đầu tư: vì sao cần PH-02, phân hệ đặt mục tiêu đo được nào, nằm ở đâu trong kiến trúc, và phủ những chức năng nào của hệ cũ. Chi tiết kỹ thuật nằm ở chương 6 trở đi.

### 2.1. Bối cảnh và vấn đề cần giải quyết

Ở hệ LGSP cũ, khối quản lý API (API Management theo mô hình Gravitee) cho tạo API, gói sử dụng và đăng ký, nhưng vận hành như một công cụ cấu hình hơn là một danh mục dịch vụ có kiểm soát: API tạo xong có thể chạy ngay, không ai duyệt, đặc tả không bắt buộc, Application tạo tay không gắn với hồ sơ HTTT, và việc ngừng một API không có lộ trình. Bảng dưới nêu những hạn chế đó, hệ quả thực tế và cách PH-02 khắc phục.

| Hạn chế hệ cũ | Hệ quả | Cách PH-02 khắc phục |
|---|---|---|
| API tạo bằng tên, context-path, URL backend; đặc tả OpenAPI không bắt buộc | Bên khai thác không có hợp đồng để lập trình; không kiểm tra được tuân thủ | Bắt buộc đặc tả OpenAPI 3.1 hợp lệ, kiểm tra hai lớp trước khi gửi duyệt (FR-02-010, 016, 017) |
| Tạo xong "triển khai ngay", không có bước duyệt | API chưa rà soát (phân loại dữ liệu, xác thực, hạn mức) ra ngoài gateway | Vòng đời có duyệt bốn mắt; chỉ API `PUBLISHED` mới có route (FR-02-034…036) |
| Khóa API là cơ chế bảo mật chủ yếu, Keyless dùng tùy ý | Khóa lộ thì ai cũng gọi được; dữ liệu nhạy cảm không có mTLS | Kiểu xác thực của gói ràng buộc theo mức phân loại: Keyless chỉ cho dữ liệu công khai, mức Hạn chế trở lên bắt buộc mTLS hoặc `private_key_jwt` (FR-02-028, BR-02-016) |
| Application tạo trực tiếp, đăng ký không rõ ai chịu trách nhiệm | Không biết HTTT nào dùng API nào; không báo được khi API đổi | Đăng ký sử dụng chỉ nhận từ HTTT đã kết nạp, có mục đích, có duyệt; phạm vi sinh tự động (FR-02-046…048) |
| Xóa API tức thì; plan đóng không báo | Bên đang dùng bị ngắt đột ngột | Xóa chỉ khi không còn đăng ký; ngừng khuyến nghị có lộ trình ≥ 6 tháng và thông báo (FR-02-038…040, 057) |
| Nhiều backend nhưng cân bằng tải và kiểm tra sức khỏe khai báo rời rạc | Backend chết vẫn nhận lưu lượng | Backend khai báo trong API, đẩy sang gateway cùng bộ kiểm tra sức khỏe (FR-02-022, 023) |
| Không có danh mục công khai, không đăng ký lên hệ thống trung ương | Không đáp ứng nghĩa vụ công khai, đăng ký dịch vụ chia sẻ | Danh mục tra cứu được theo mức hiển thị, đồng bộ tự động lên Nền tảng quốc gia, cảnh báo quá hạn (FR-02-004, 053, 054) |
| Không có thông tin chất lượng dịch vụ | Bên khai thác không biết dịch vụ có đáng tin | Cam kết SLA, đối chiếu thực tế, hiển thị cạnh nhau (FR-02-055, 056) |

: Hạn chế của hệ cũ và cách khắc phục

### 2.2. Mục tiêu của phân hệ

PH-02 có năm mục tiêu đo được. Mục tiêu thứ nhất là **mọi API công bố đều có hợp đồng hợp lệ**: 100% phiên bản `PUBLISHED` có đặc tả OpenAPI 3.1 qua kiểm tra lớp 1 và không còn lỗi lớp 2 mức nghiêm trọng, 0 đặc tả công bố chứa bí mật (NFR-02-012, BR-02-015). Mục tiêu thứ hai là **công bố nhanh nhưng có kiểm soát**: từ lúc người duyệt bấm phê duyệt tới lúc API gọi được qua gateway không quá 30 giây ở phân vị 95 (NFR-02-005), và thời gian từ lúc gửi duyệt tới lúc duyệt xong theo dõi được để đạt KPI-05 (HTTT gọi được API ở môi trường thật trong ≤ 5 ngày làm việc kể từ khi nộp hồ sơ kết nạp). Mục tiêu thứ ba là **không ngắt bên khai thác bất ngờ**: 0 API chuyển `RETIRED` khi còn đăng ký `ACTIVE` (BR-02-006), 100% bên đăng ký nhận thông báo thay đổi bắt buộc trong 15 phút (NFR-02-015). Mục tiêu thứ tư là **quyền truy cập tối thiểu và truy vết được**: 100% quyền gọi API của HTTT sinh từ đăng ký đã duyệt, không cấp tay (BR-02-025), góp phần KPI-07. Mục tiêu thứ năm là **tuân thủ nghĩa vụ đăng ký danh mục**: 100% API mức hiển thị `NATIONAL` hoặc `PUBLIC` đã đồng bộ lên Nền tảng quốc gia, không có API quá hạn chưa đồng bộ hơn 7 ngày mà chưa có cảnh báo (NFR-02-014).

### 2.3. Vị trí trong kiến trúc

Hình dưới đặt PH-02 giữa các phân hệ và thành phần nó trao đổi dữ liệu với; phần thuyết minh sau hình nêu hướng dữ liệu đi.

```{.mermaid caption="Vị trí của PH-02 trong kiến trúc Datahub"}
flowchart TB
  subgraph CP["Mặt phẳng điều khiển · dh-connect (vùng Z3)"]
    UI["Màn hình UI-02-*<br/>dh-console"] --> API["API /api/catalog/v1"]
    API --> CAT["Danh mục, vòng đời, phiên bản,<br/>gói, đăng ký, SLA, đồng bộ"]
    CAT --> DB[("pg-core<br/>schema ph02_catalog")]
    CAT --> LINT["Bộ kiểm tra đặc tả"]
    GW["PH-03: sinh ảnh chụp<br/>cấu hình gateway"]
  end
  CAT -->|"cấu hình đã duyệt"| GW
  GW --> S3[("Garage<br/>bucket cấu hình gateway")]
  S3 --> AP["APISIX standalone (vùng Z2)<br/>route, upstream, consumer"]
  AP --> BE["Backend: HTTT thành viên<br/>hoặc luồng dh-runtime (Z4)"]
  CAT -->|"sự kiện EVT-02-*"| K[("Kafka")]
  K --> P15["PH-15 cổng nhà phát triển"]
  K --> P13["PH-13 giám sát"]
  CAT -->|"yêu cầu gắn phạm vi"| P12["PH-12 Keycloak, OPA"]
  CAT -->|"danh mục đồng bộ"| P14["PH-14 → Nền tảng quốc gia"]
  P04["PH-04 luồng REST"] -->|"EVT-04-*"| CAT
  CAT -->|"khung route"| P04
```

PH-02 là phân hệ của mặt phẳng điều khiển, chạy trong `dh-connect` ở vùng Z3, lưu dữ liệu trong schema `ph02_catalog` của cụm `pg-core` với bảo mật mức dòng (RLS) theo tenant. Điều quan trọng nhất của hình là hướng đi của cấu hình: PH-02 quyết định "cái gì được phép", phần PH-03 trong cùng đơn vị triển khai biến quyết định đó thành ảnh chụp cấu hình có chữ ký ghi vào bucket Garage, và APISIX chế độ standalone ở vùng Z2 nạp ảnh chụp (D03-09 §6.1, ADR-013). APISIX không gọi ngược PH-02 trên đường xử lý lượt gọi, nên PH-02 ngừng thì API đang chạy vẫn phục vụ (NFR-00-012). PH-02 phát sự kiện `EVT-02-*` cho PH-15 và PH-13, nhận sự kiện luồng của PH-04, gửi yêu cầu gắn phạm vi cho PH-12 và gửi danh mục cho PH-14.

### 2.4. Kiến trúc thành phần và công nghệ

PH-02 gồm sáu thành phần. **Dịch vụ danh mục** trong `dh-connect` (Java 21, Spring Boot 4, Modulith theo ADR-001) cung cấp API `/api/catalog/v1`, giữ API, phiên bản, đặc tả, backend, gói, đăng ký, SLA trong PostgreSQL. **Bộ kiểm tra đặc tả** là một mô-đun chạy bộ phân tích OpenAPI 3.1 (lớp 1), bộ luật quy ước (lớp 2) và bộ quét bí mật; mỗi lần kiểm tra chạy trong giới hạn thời gian và bộ nhớ, tách khỏi luồng xử lý yêu cầu của người dùng. **Bộ so sánh phiên bản** tính khác biệt giữa hai đặc tả và phân loại tương thích. **Bộ đồng bộ cấu hình** chuyển trạng thái đã duyệt (route, upstream, consumer gắn gói) sang mô-đun PH-03 để sinh ảnh chụp cấu hình. **Bộ đồng bộ quốc gia** gom danh mục thành gói gửi PH-14 theo lịch và theo sự kiện, dùng bảng outbox để không mất lệnh khi PH-14 ngừng. **Bộ tính SLA và thông báo** đọc chỉ số thực tế từ PH-13 theo tháng, đối chiếu cam kết và phát thông báo thay đổi. Tìm kiếm toàn văn dùng PostgreSQL `tsvector` kèm `unaccent` cho hồ sơ `QM-NHO`, `QM-VUA`; hồ sơ `QM-LON`, `QM-CHUNG` có thể chuyển sang OpenSearch (SAD §6, Q02-02).

Hình dưới mô tả trình tự công bố một API: từ lúc chủ dịch vụ gửi duyệt, qua kiểm tra, duyệt bốn mắt, đẩy cấu hình, tới khi API gọi được và danh mục được đồng bộ. Điểm quan trọng: mọi bước đều có điểm dừng an toàn, nếu gateway không nhận cấu hình thì API không sang `PUBLISHED`.

```{.mermaid caption="Trình tự công bố một API từ lúc gửi duyệt tới khi gọi được qua gateway"}
sequenceDiagram
  autonumber
  participant SV as Chủ dịch vụ
  participant C as PH-02 Dịch vụ danh mục
  participant CA as Người duyệt
  participant G as PH-03 Bộ đồng bộ cấu hình
  participant AP as APISIX
  participant N as PH-14
  SV->>C: Gửi duyệt phiên bản 1.0.0
  C->>C: Kiểm tra lại đặc tả lớp 1, lớp 2, bí mật
  C-->>CA: Việc chờ duyệt trong Việc của tôi
  CA->>C: Duyệt kèm ý kiến
  C->>C: Kiểm tra bốn mắt, mức phân loại, backend, gói
  C->>G: Yêu cầu công bố route, upstream, gói
  G->>AP: Ảnh chụp cấu hình có chữ ký qua bucket
  AP-->>G: Xác nhận số phiên bản đã nạp
  G-->>C: Đã nạp
  C->>C: Chuyển PUBLISHED, ghi kiểm toán
  C-->>SV: Thông báo đã công bố
  C->>N: Đưa vào hàng đợi đồng bộ quốc gia
```

Hình trên cho thấy hai điểm dừng an toàn: việc duyệt bốn mắt đứng trước mọi thay đổi ở cổng, và PH-02 chỉ chuyển phiên bản sang `PUBLISHED` sau khi APISIX xác nhận đã nạp đúng số phiên bản cấu hình; thiếu xác nhận thì phiên bản giữ `PENDING` và hệ thống thử lại.

### 2.5. Quy trình nghiệp vụ liên quan

Bảng dưới nối các quy trình nghiệp vụ của danh mục dịch vụ với những bước do PH-02 đảm nhận.

| Quy trình | Bước có PH-02 |
|---|---|
| Kết nạp HTTT (PH-01) → công bố dịch vụ | HTTT `ACTIVE` ở PH-01 mới được là bên cung cấp; chủ dịch vụ đăng ký API, nạp đặc tả, kiểm tra, khai backend và gói, gửi duyệt |
| Khai thác dịch vụ | HTTT của đơn vị khác tìm API trong danh mục, gửi đăng ký sử dụng; chủ dịch vụ hoặc người duyệt dịch vụ duyệt; PH-02 gắn phạm vi cho client (PH-12) và consumer cho gói (PH-03); HTTT gọi API qua gateway |
| Thiết kế, phát hành luồng (PH-04) | Luồng có điểm vào REST được công bố như một API: PH-04 phát sự kiện, PH-02 đăng ký API gắn nhãn nguồn `FLOW` (FR-02-013); PH-02 sinh khung route cho PH-04 khi API đi từ đặc tả (FR-02-026) |
| Nâng phiên bản, ngừng dùng | Phiên bản mới song song với phiên bản cũ; báo cáo khác biệt, phân tích tác động; ngừng khuyến nghị cùng thông báo; ngừng hẳn khi hết hạn và không còn người dùng |
| Đồng bộ danh mục quốc gia | API mức `NATIONAL`, `PUBLIC` được gửi lên Nền tảng quốc gia qua PH-14 khi công bố và định kỳ hằng ngày; Cán bộ vận hành theo dõi, xử lý từ chối |
| Di trú từ APIM cũ (strangler) | Nhập định nghĩa API, gói, đăng ký từ Gravitee cũ thành bản nháp có đặc tả bổ sung; khóa API không di trú, HTTT cấp lại định danh (FR-02-061, FR-00-093) |
| Sự cố ATTT | Cán bộ ATTT tạm ngừng API hoặc đăng ký của HTTT nghi ngờ bị chiếm quyền (FR-02-037, 051) |

: Quy trình nghiệp vụ có PH-02 tham gia

Hình dưới tóm tắt vòng đời điển hình của một API từ lúc khai báo tới lúc ngừng hẳn.

```{.mermaid caption="Vòng đời điển hình của một API trong danh mục dịch vụ"}
flowchart TB
  A["SV đăng ký API,<br/>nạp đặc tả<br/>FR-02-010, 011"] --> B["Kiểm tra đặc tả<br/>lớp 1, lớp 2, bí mật<br/>FR-02-016…018"]
  B -->|"Còn lỗi"| A
  B -->|"Đạt"| C["Khai backend, gói<br/>FR-02-022, 027"]
  C --> D["Gửi duyệt<br/>FR-02-034"]
  D --> E["CA duyệt<br/>bốn mắt FR-02-035"]
  E -->|"Trả lại"| A
  E -->|"Duyệt"| F["Công bố ra gateway<br/>FR-02-036"]
  F --> G["HTTT đăng ký,<br/>được duyệt<br/>FR-02-046, 047"]
  G --> H["Theo dõi SLA,<br/>thống kê<br/>FR-02-056, 058"]
  H --> I["Phiên bản mới,<br/>ngừng khuyến nghị<br/>FR-02-042, 038"]
  I --> J["Ngừng hẳn<br/>FR-02-039"]
```

Hình trên là đường đi thông thường của một API. Vòng trả lại từ bước duyệt và bước kiểm tra về bước khai báo cho thấy chủ dịch vụ luôn có cơ hội sửa; mọi bước đều có mã chức năng được đặc tả ở chương 6.

### 2.6. Chức năng hệ cũ được phủ

PH-02 là phân hệ đích chính của 15 mục `LGC` thuộc khối APIM của hệ cũ và phối hợp một mục của khối Bus. Kết luận từng mục ở mục 11.1.

| Mã | Chức năng hệ cũ | Vai trò của PH-02 |
|---|---|---|
| LGC-APIM-001 | Hiển thị danh sách API | Chính |
| LGC-APIM-002 | Tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend | Chính |
| LGC-APIM-003 | Tạo API bằng cách nạp Swagger | Chính |
| LGC-APIM-004 | Tạo API chưa triển khai, hoặc tạo và triển khai ngay | Chính |
| LGC-APIM-005 | Start / Stop API | Chính (trạng thái và lệnh), cùng PH-03 (thực thi tại gateway) |
| LGC-APIM-006 | Publish / Unpublish API lên portal | Chính (mức hiển thị, công bố), cùng PH-15 (hiển thị) |
| LGC-APIM-008 | Xóa API | Chính |
| LGC-APIM-009 | Plan với bốn trạng thái Staging, Published, Deprecated, Closed | Chính |
| LGC-APIM-010 | Plan bước Define: metadata, nhóm được phép truy cập | Chính |
| LGC-APIM-011 | Plan bước Secure: Keyless hoặc API key | Chính (khai báo, ràng buộc theo mức phân loại), cùng PH-03 (thực thi) |
| LGC-APIM-016 | Quản lý subscription theo API | Chính |
| LGC-APIM-017 | Xem chi tiết đường dẫn sử dụng API (gateway URL + context path) | Chính, cùng PH-15 |
| LGC-APIM-018 | Quản lý endpoint backend của API | Chính |
| LGC-APIM-021 | Quản lý subscription theo Application | Chính (theo HTTT) |
| LGC-BUS-028 | Thông tin REST API của agent: URI và trạng thái | Chính (API công bố từ luồng được quản lý trong danh mục), cùng PH-04 |

: Chức năng hệ cũ do PH-02 phủ

Ngoài ra có bốn nhóm `LGC` của khối APIM do phân hệ khác làm chính nhưng PH-02 giữ dữ liệu hoặc khai báo liên quan, và đã ghi trong cột truy vết của FR tương ứng: `LGC-APIM-007` (Make Public) do PH-15 làm chính, PH-02 giữ thuộc tính mức hiển thị (FR-02-041); `LGC-APIM-012`, `013`, `014` (rate limit, quota, whitelist/blacklist đường dẫn) do PH-03 thực thi, PH-02 chỉ khai báo giá trị trong gói (FR-02-029); `LGC-APIM-015` (Policies) do PH-03; `LGC-APIM-019`, `020` (Application) do PH-01, PH-12.

## 3. Tác nhân, vai trò và quyền

Chương này nêu những ai và hệ thống nào tương tác với PH-02, quyền của từng vai trò theo ma trận phân quyền D02-08, và các ràng buộc tách nhiệm vụ. Quyền viết theo dạng `PERM-02-{động từ}` và kiểm tra ở máy chủ, không chỉ ở giao diện.

### 3.1. Tác nhân

Bảng dưới liệt kê các tác nhân người và máy tương tác với PH-02, kèm vai trò, mô tả và những việc họ làm chính.

| Tác nhân | Loại | Mô tả | Tương tác chính |
|---|---|---|---|
| Chủ dịch vụ (SV, ROLE-SERVICE_OWNER) | Người | Cán bộ của đơn vị chủ quản HTTT cung cấp dữ liệu; chỉ thấy và sửa API của tổ chức mình | Đăng ký API, nạp đặc tả, khai backend, gói, gửi duyệt, đề nghị ngừng dùng, duyệt đăng ký sử dụng cho API của mình |
| Người duyệt dịch vụ (CA, ROLE-CATALOG_APPROVER) | Người | Cán bộ được tenant giao rà soát công bố, gói, đăng ký | Duyệt công bố, gói, đăng ký sử dụng, ngừng khuyến nghị; nhận cảnh báo SLA |
| Cán bộ đầu mối tổ chức (OR, ROLE-ORG_REQUESTER) | Người | Đầu mối của đơn vị khai thác | Gửi đăng ký sử dụng API cho HTTT của tổ chức, theo dõi, hủy |
| Quản trị tenant (TA, ROLE-TENANT_ADMIN) | Người | Quản trị Datahub của tỉnh | Như SV và CA ở mức tenant, cộng tham số phân hệ, bộ luật, phân loại, chuyển chủ quản, di trú |
| Vận hành tenant (TO, ROLE-TENANT_OPERATOR) | Người | Cán bộ trực vận hành | Tạm ngừng, tiếp tục API và đăng ký; chạy, thử lại đồng bộ quốc gia; đối soát gateway |
| Cán bộ ATTT (SO, ROLE-SECURITY_OFFICER) | Người | Cán bộ chuyên trách an toàn thông tin | Tạm ngừng khẩn API, đăng ký; xem kết quả quét bí mật |
| Kỹ sư tích hợp (IE, ROLE-INTEGRATION_ENGINEER) | Người | Cán bộ kỹ thuật hoặc nhà thầu tích hợp | Xem danh mục, tải đặc tả, nhận khung route; không có quyền tạo API |
| Quản trị nền tảng (PA, ROLE-PLATFORM_ADMIN) | Người | Đơn vị vận hành nền tảng dùng chung | Quản lý bộ luật kiểm tra mặc định, tham số trần |
| Người xem (VW), kiểm toán viên (AU) | Người | Lãnh đạo, thanh tra, kiểm toán | Xem |
| HTTT khai thác | Hệ thống | HTTT của cơ quan khác, tra cứu danh mục bằng token máy | Đọc danh mục công khai trong tenant, tải đặc tả (scope `catalog:read`) |
| PH-01 | Hệ thống | Kết nạp HTTT | Cho biết HTTT `ACTIVE`, đầu mối kỹ thuật |
| PH-03 | Hệ thống | Cổng API, bộ đồng bộ cấu hình | Nhận dữ liệu công bố; trả xác nhận nạp; cho biết sức khỏe backend |
| PH-04, PH-05, PH-10 | Hệ thống | Luồng, kết nối, topic | Phát sự kiện luồng REST; nhận khung route; cho biết topic `ACTIVE` |
| PH-12 | Hệ thống | Định danh và phân quyền | Gắn phạm vi cho client theo đăng ký đã duyệt |
| PH-13, PH-14, PH-15, PH-16, PH-18 | Hệ thống | Giám sát, kết nối quốc gia, cổng nhà phát triển, báo cáo chỉ tiêu, vận hành | Chỉ số thực tế; nhận danh mục gửi quốc gia; hiển thị tài liệu; nhận chỉ số tuân thủ; tham số và thông báo |

: Tác nhân của PH-02

### 3.2. Ma trận quyền

Ma trận dưới đây dùng ký hiệu của D02-08 §3 (● có quyền, ○ chỉ với đối tượng của tổ chức mình, — không có). Bảy quyền đã có ở D02-08 §3.1; D02-08 gộp "tạo, sửa" thành một nhóm `PERM-02-create`, nên tập này dùng nhóm đó cho cả đăng ký, sửa, xóa mềm API và gói. Phần quản trị phân hệ (tham số, bộ phân loại, bộ luật kiểm tra, chuyển chủ quản, di trú) cần một quyền riêng với động từ `admin` của họ quyền PH-02 (quyền quản trị phân hệ): đề nghị bổ sung vào D02-08 trong đợt đồng bộ (mục "Đề nghị đồng bộ"), cho tới lúc đó các FR liên quan ghi bằng lời "quyền quản trị phân hệ". Các vai trò không nêu (PO, IA, DS, DA, DO) chỉ có `PERM-02-read`.

| Quyền | Ý nghĩa | PA | TA | TO | SO | IE | SV | CA | OR | VW | AU |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PERM-02-read | Xem danh mục, API, phiên bản, gói, SLA, thống kê; tải đặc tả đã công bố | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| PERM-02-create | Đăng ký API; nạp, sửa đặc tả; khai backend, gói, SLA; tạo phiên bản; đặt phân loại và thẻ; xóa mềm API và hủy gói nháp của tổ chức mình | — | ● | — | — | — | ○ | — | — | — | — |
| PERM-02-submit | Gửi duyệt công bố API, gói; đề nghị ngừng khuyến nghị, ngừng hẳn | — | ● | — | — | — | ○ | — | — | — | — |
| PERM-02-publish | Duyệt, từ chối và công bố API, gói; duyệt ngừng khuyến nghị, ngừng hẳn | — | ● | — | — | — | — | ● | — | — | — |
| PERM-02-subscribe | Gửi, hủy đăng ký sử dụng API cho HTTT của tổ chức mình | — | ● | — | — | — | — | — | ○ | — | — |
| PERM-02-approve-subscription | Duyệt, từ chối, thu hồi đăng ký sử dụng | — | ● | — | — | — | ○ | ● | — | — | — |
| PERM-02-operate | Tạm ngừng, tiếp tục API và đăng ký; chạy, thử lại đồng bộ danh mục quốc gia; đối soát gateway | — | ● | ● | ● | — | — | — | — | — | — |
| Quyền quản trị phân hệ (đề nghị, động từ `admin`) | Tham số phân hệ, bộ phân loại và thẻ, bộ luật kiểm tra, chuyển chủ quản, di trú từ APIM cũ | ● | ● | — | — | — | — | — | — | — | — |

: Ma trận quyền của PH-02

### 3.3. Tách nhiệm vụ và tài khoản máy

SV và CA đã là cặp loại trừ ở D02-08 §4: một người không được giữ cả hai vai trò trong cùng tenant, nên chủ dịch vụ không tự duyệt công bố. Ngoài ra nguyên tắc bốn mắt (FR-00-071) áp dụng cho từng đối tượng: người gửi duyệt, người sửa gần nhất đặc tả hoặc gói, và người duyệt phải là ba người khác nhau khi đối tượng được duyệt là API, gói hoặc đăng ký mức Hạn chế trở lên (BR-02-008, BR-02-026). `PERM-02-operate` của SO chỉ dùng khi có sự cố: tạm ngừng API (FR-02-037), tạm ngừng đăng ký (FR-02-051); không dùng cho công bố hay sửa nội dung.

Các phân hệ gọi nhau bằng token dịch vụ, không dùng tài khoản người. PH-03 đọc dữ liệu công bố bằng scope `catalog:gateway-read` (chỉ đọc) và xác nhận đã nạp cấu hình bằng scope `catalog:gateway-ack` (API-02-082, tách riêng để token chỉ đọc không ghi được trạng thái công bố); PH-15 đọc danh mục bằng `catalog:portal-read`; PH-04 đọc đặc tả và gửi sự kiện luồng bằng `catalog:flow-sync`; PH-13 và PH-16 đọc số liệu tuân thủ bằng `catalog:metrics-read`. Các scope này cấp cho tài khoản dịch vụ khi triển khai, không cấp cho người hay cho HTTT khai thác. HTTT khai thác chỉ có scope `catalog:read` (đọc danh mục công khai trong tenant) và các scope `api:{mã API}:{mã gói}` do đăng ký đã duyệt sinh ra (D02-08 §5).

## 4. Khái niệm và mô hình nghiệp vụ

Chương này định nghĩa các khái niệm dùng xuyên suốt (API, phiên bản, gói, đăng ký), các thực thể ở mức logic và ba máy trạng thái của phân hệ. Hiểu ba máy trạng thái là đủ để đọc hiểu phần lớn các FR ở chương 6.

### 4.1. Khái niệm nghiệp vụ

Bảng dưới định nghĩa các khái niệm nghiệp vụ mà phần đặc tả chức năng dùng lại, để mọi chương hiểu cùng một nghĩa.

| Khái niệm | Định nghĩa |
|---|---|
| API | Dịch vụ chia sẻ dữ liệu của một HTTT cung cấp, có mã `apiCode` duy nhất trong tenant (ví dụ `tra-cuu-ho-tich`), đơn vị chủ quản, mức phân loại dữ liệu, mức hiển thị, phân loại và thẻ. API có một hay nhiều phiên bản |
| Phiên bản API | Một lần phát hành, số hiệu `MAJOR.MINOR.PATCH`. Chỉ số chính xuất hiện trong context-path (`/v1`, `/v2`). Mỗi phiên bản có đặc tả OpenAPI, backend, gói, SLA và trạng thái vòng đời riêng |
| Đặc tả | Tài liệu OpenAPI 3.1 của một phiên bản, bất biến sau khi phiên bản được duyệt; giữ vĩnh viễn |
| Kết quả kiểm tra | Danh sách phát hiện của một lần kiểm tra đặc tả: lớp, mức (`ERROR`, `WARNING`, `INFO`), mã luật, vị trí, hướng dẫn |
| Mức phân loại dữ liệu | `PUBLIC` Công khai, `INTERNAL` Nội bộ, `RESTRICTED` Hạn chế, `SENSITIVE` Nhạy cảm (SAD §8.2); quyết định kiểu xác thực tối thiểu của gói |
| Mức hiển thị | `TENANT` (chỉ HTTT trong tenant thấy), `NATIONAL` (đồng bộ lên Nền tảng quốc gia để cơ quan khác tra cứu qua đó), `PUBLIC` (công khai trên cổng nhà phát triển, chỉ dữ liệu mức `PUBLIC`) |
| Backend | Đích phía sau gateway: địa chỉ HTTT cung cấp (qua kết nối PH-05) hoặc điểm vào REST của luồng PH-04; có trọng số, thời gian chờ, kiểm tra sức khỏe |
| Gói sử dụng | Điều kiện gọi một phiên bản API: kiểu xác thực (`KEYLESS`, `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS`), hạn mức, đường dẫn được phép, điều kiện đăng ký (nhóm HTTT được phép, tự duyệt hay duyệt tay). Bốn trạng thái: `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED` |
| Đăng ký sử dụng | Quan hệ giữa một HTTT và một gói; có mục đích, khối lượng dự kiến, người duyệt; sinh ra phạm vi `api:{apiCode}:{planCode}` |
| Yêu cầu duyệt | Việc chờ người có quyền xử lý: duyệt công bố phiên bản, duyệt ngừng dùng, duyệt gói, duyệt đăng ký; hiển thị trong "Việc của tôi" |
| Lộ trình ngừng dùng | Kế hoạch ngừng khuyến nghị một phiên bản: phiên bản kế nhiệm, hạn chuyển đổi, mốc nhắc, danh sách bên bị ảnh hưởng |
| Đồng bộ quốc gia | Việc gửi nội dung danh mục API mức `NATIONAL`, `PUBLIC` lên Nền tảng quốc gia qua PH-14 và nhận xác nhận |
| Cam kết SLA | Độ trễ p99, tỷ lệ sẵn sàng, hạn mức giờ, giờ phục vụ do chủ dịch vụ khai cho một phiên bản; được đối chiếu hằng tháng với số đo thực tế |
| Nguồn gốc API (`origin`) | `MANUAL` (khai biểu mẫu), `OPENAPI` (nạp đặc tả), `FLOW` (sinh từ luồng PH-04), `LEGACY` (nhập từ APIM cũ) |

: Khái niệm nghiệp vụ của PH-02

### 4.2. Thực thể

Thực thể ở mức logic; định nghĩa cột, kiểu, chỉ mục và RLS ở D03-03-PH02. Mọi thực thể có các cột ngữ cảnh bắt buộc của D00-01 §5.1 (`id`, `tenant_id`, `created_*`, `updated_*`, `version`).

| Mã | Thực thể | Thuộc tính chính | Quan hệ |
|---|---|---|---|
| EN-02-01 | API | `apiCode`, tên, mô tả, HTTT cung cấp, đơn vị chủ quản, `dataClass`, `visibility`, `categoryId`, thẻ, `origin`, `flowRef`, `basePath`, `deletedAt` | Có nhiều phiên bản; thuộc một HTTT ở PH-01 |
| EN-02-02 | Phiên bản API | `versionNo`, `major`, `status`, `specId`, `successorVersionId`, `sunsetAt`, `breaking`, `publishedAt`, `approvedBy` | Thuộc API; có đặc tả, backend, gói, SLA |
| EN-02-03 | Đặc tả | `format`, `source` (`UPLOAD`, `URL`, `PASTE`, `FLOW`, `LEGACY`), `sourceUrl`, `sha256`, `sizeBytes`, nội dung ở kho đối tượng | Một đặc tả cho một phiên bản; có nhiều kết quả kiểm tra |
| EN-02-04 | Kết quả kiểm tra | `layer` (`STANDARD`, `CONVENTION`, `SECRET`), `severity`, `ruleId`, `location`, `message`, `hint`, `resolved` | Thuộc đặc tả |
| EN-02-05 | Backend | `backendCode`, loại (`SYSTEM`, `FLOW`), `targetRef`, `weight`, `timeoutMs`, `retries`, cấu hình kiểm tra sức khỏe, `status` | Thuộc phiên bản API |
| EN-02-06 | Gói sử dụng | `planCode`, `status`, `authType`, `autoApprove`, nhóm HTTT được phép, hạn mức, đường dẫn cho phép, đơn giá thông tin | Thuộc phiên bản API; có nhiều đăng ký |
| EN-02-07 | Đăng ký sử dụng | `systemCode`, `purpose`, `expectedVolume`, `status`, `decidedBy`, `expiresAt` | Thuộc gói; HTTT ở PH-01 |
| EN-02-08 | Cam kết SLA và kỳ tuân thủ | `latencyP99Ms`, `availability`, `hourlyLimit`, `serviceHours`; kỳ `YYYY-MM`, giá trị thực tế, `met` | Thuộc phiên bản API |
| EN-02-09 | Yêu cầu duyệt | `kind`, `subjectRef`, `requestedBy`, `decision`, `comment`, `decidedBy`, `decidedAt` | Gắn với phiên bản, gói hoặc đăng ký |
| EN-02-10 | Bản ghi đồng bộ quốc gia | `status` (`QUEUED`, `SENT`, `ACKED`, `REJECTED`, `FAILED`), `payloadHash`, `nationalRef`, `rejectReason`, `sentAt`, `ackedAt` | Thuộc phiên bản API |
| EN-02-11 | Thông báo thay đổi | `kind`, `apiVersionId`, số bên nhận, kênh, `status`, nội dung | Thuộc phiên bản API |
| EN-02-12 | Phân loại và thẻ | `categoryCode`, tên, cha, thứ tự; thẻ tự do | Gắn với API |
| EN-02-13 | Luật kiểm tra | `ruleId`, lớp, mức mặc định, mức ở tenant, bật tắt, mô tả, hướng dẫn | Dùng bởi bộ kiểm tra |

: Thực thể của PH-02

### 4.3. Máy trạng thái phiên bản API

Vòng đời nằm ở **phiên bản** chứ không ở API: một API có thể có phiên bản `1.2.0` đang `DEPRECATED` song song với `2.0.0` đang `PUBLISHED`. Hình dưới là máy trạng thái của một phiên bản.

```{.mermaid caption="Máy trạng thái phiên bản API"}
stateDiagram-v2
  [*] --> DRAFT: Đăng ký, nạp đặc tả
  DRAFT --> PENDING: Gửi duyệt khi đủ điều kiện
  PENDING --> DRAFT: CA trả lại hoặc người gửi rút
  PENDING --> PUBLISHED: CA duyệt, gateway nạp cấu hình
  PUBLISHED --> SUSPENDED: Tạm ngừng
  SUSPENDED --> PUBLISHED: Tiếp tục
  PUBLISHED --> DEPRECATED: Ngừng khuyến nghị có lộ trình
  SUSPENDED --> DEPRECATED: Ngừng khuyến nghị
  DEPRECATED --> RETIRED: Hết hạn và không còn đăng ký
  DRAFT --> RETIRED: Hủy bản nháp
  PUBLISHED --> RETIRED: Phiên bản cùng số chính mới công bố thay thế
  RETIRED --> [*]
```

Cạnh `PUBLISHED → RETIRED` chỉ do hệ thống thực hiện, với lý do `SUPERSEDED`, khi một phiên bản mới cùng số chính được công bố (BR-02-035); người dùng không có lệnh này. Khi người duyệt đã duyệt cuối mà gateway chưa xác nhận nạp, phiên bản vẫn ở `PENDING`; lớp dịch vụ giữ trạng thái trung gian `activating` (không phải trạng thái vòng đời) cho tới khi có xác nhận, nên người dùng không thấy `PUBLISHED` giả (FR-02-036).

`DRAFT` là trạng thái duy nhất cho sửa đặc tả, backend và gói; có thể triển khai thử lên môi trường TEST để chủ dịch vụ kiểm tra bằng lời gọi thật. `PENDING` khóa nội dung chờ người duyệt, không ai sửa được; người gửi rút lại thì về `DRAFT`. `PUBLISHED` là trạng thái duy nhất nhận đăng ký sử dụng mới; đặc tả bất biến, chỉ sửa được mô tả, SLA và thông tin không ảnh hưởng hợp đồng. `SUSPENDED` là lệnh Stop của hệ cũ: route bị gỡ khỏi gateway nhưng dữ liệu và đăng ký giữ nguyên; thời hạn tạm ngừng tối đa 30 ngày trước khi phải quyết định (tiếp tục hoặc ngừng khuyến nghị). `DEPRECATED` vẫn phục vụ, có cảnh báo trong mọi phản hồi (tiêu đề `Deprecation`, `Sunset`, theo RFC 9745, RFC 8594) và không nhận đăng ký mới. `RETIRED` là trạng thái cuối: route bị gỡ, đặc tả giữ vĩnh viễn làm bằng chứng hợp đồng.

### 4.4. Máy trạng thái gói sử dụng

Gói giữ nguyên bốn trạng thái của hệ cũ (LGC-APIM-009), đổi tên sang mã chuẩn.

```{.mermaid caption="Máy trạng thái gói sử dụng"}
stateDiagram-v2
  [*] --> STAGING: Tạo gói
  STAGING --> PUBLISHED: CA duyệt khi phiên bản PUBLISHED hoặc cùng đợt
  PUBLISHED --> DEPRECATED: Ngừng khuyến nghị, chặn đăng ký mới
  DEPRECATED --> CLOSED: Không còn đăng ký đang dùng
  STAGING --> CLOSED: Hủy gói chưa công bố
  CLOSED --> [*]
```

`STAGING` là gói đang soạn, chưa nhận đăng ký, sửa tự do. `PUBLISHED` nhận đăng ký; chỉ sửa theo hướng tương thích (BR-02-017). `DEPRECATED` giữ nguyên các đăng ký sẵn có nhưng không nhận đăng ký mới. `CLOSED` là trạng thái cuối: không còn đăng ký đang dùng, route gói bị gỡ.

### 4.5. Máy trạng thái đăng ký sử dụng

Đăng ký sử dụng đi qua nhiều trạng thái từ lúc gửi tới lúc hết hiệu lực; hình dưới nêu các chuyển trạng thái được phép và điều kiện của chúng.

```{.mermaid caption="Máy trạng thái đăng ký sử dụng"}
stateDiagram-v2
  [*] --> PENDING: HTTT gửi đăng ký
  PENDING --> ACTIVE: Duyệt hoặc tự duyệt, cấp phạm vi
  PENDING --> REJECTED: Từ chối có lý do
  PENDING --> CANCELLED: Người gửi rút
  ACTIVE --> SUSPENDED: Tạm ngừng
  SUSPENDED --> ACTIVE: Tiếp tục
  ACTIVE --> REVOKED: Bên cung cấp thu hồi
  SUSPENDED --> REVOKED: Thu hồi
  ACTIVE --> CANCELLED: HTTT hủy
  ACTIVE --> EXPIRED: Quá hạn rà soát chưa gia hạn
  REJECTED --> [*]
  CANCELLED --> [*]
  REVOKED --> [*]
  EXPIRED --> [*]
```

Chỉ `ACTIVE` mang phạm vi `api:{apiCode}:{planCode}` hợp lệ và consumer ở gateway. `SUSPENDED` giữ đăng ký nhưng gỡ consumer tạm thời. Các trạng thái cuối giữ hồ sơ vĩnh viễn làm bằng chứng ai đã dùng API nào.

## 5. Danh sách chức năng

PH-02 có 62 chức năng chia mười nhóm. Hình dưới cho thấy nhóm chức năng và luồng dữ liệu chính giữa các nhóm.

```{.mermaid caption="Các nhóm chức năng của PH-02 và quan hệ giữa chúng"}
flowchart TB
  B["B · Đăng ký API,<br/>nạp đặc tả"] --> C["C · Kiểm tra đặc tả"]
  C --> D["D · Backend, đường dẫn,<br/>khung route"]
  D --> E["E · Gói sử dụng"]
  E --> F["F · Vòng đời, duyệt,<br/>phiên bản"]
  F --> A["A · Danh mục, tra cứu"]
  A --> G["G · Đăng ký sử dụng"]
  F --> H["H · Đồng bộ quốc gia"]
  G --> I["I · SLA, thông báo,<br/>thống kê"]
  F --> I
  J["J · Tích hợp, quản trị"] -.-> F
  J -.-> G
```

Cột "Mức" dùng M (bắt buộc), S (nên có), C (có thì tốt). Cột "Đợt" theo D00-04 §2: MVP hay Đợt 2.

| Mã | Nhóm | Chức năng | Mức | Đợt | Màn hình |
|---|---|---|---|---|---|
| FR-02-001 | A | Liệt kê API trong danh mục, lọc, sắp xếp | M | MVP | UI-02-01 |
| FR-02-002 | A | Xem chi tiết API | M | MVP | UI-02-02 |
| FR-02-003 | A | Tìm kiếm toàn văn danh mục | M | MVP | UI-02-01 |
| FR-02-004 | A | Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển theo mức hiển thị | M | MVP | UI-02-01 |
| FR-02-005 | A | Xem đường dẫn sử dụng và mẫu gọi API | M | MVP | UI-02-02 |
| FR-02-006 | A | Tải đặc tả OpenAPI đã công bố | M | MVP | UI-02-02 |
| FR-02-007 | A | Phân loại và gắn thẻ API | M | MVP | UI-02-02, UI-02-14 |
| FR-02-008 | A | Quản lý bộ phân loại và thẻ | S | MVP | UI-02-14 |
| FR-02-009 | A | Hiển thị dịch vụ sự kiện (topic) trong danh mục | S | Đợt 2 | UI-02-01 |
| FR-02-010 | B | Đăng ký API mới bằng trình hướng dẫn | M | MVP | UI-02-03 |
| FR-02-011 | B | Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL | M | MVP | UI-02-03 |
| FR-02-012 | B | Đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi | S | MVP | UI-02-02 |
| FR-02-013 | B | Tự đăng ký API từ luồng REST của PH-04 | M | MVP | UI-02-02 |
| FR-02-014 | B | Sửa thông tin API và đặc tả khi còn bản nháp | M | MVP | UI-02-02, UI-02-03 |
| FR-02-015 | B | Cung cấp mẫu đặc tả và quy ước viết API | S | MVP | UI-02-03 |
| FR-02-016 | C | Kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1 | M | MVP | UI-02-04 |
| FR-02-017 | C | Kiểm tra đặc tả lớp 2: quy ước nền tảng | M | MVP | UI-02-04 |
| FR-02-018 | C | Quét bí mật và dữ liệu cá nhân thật trong đặc tả | M | MVP | UI-02-04 |
| FR-02-019 | C | Kiểm tra đặc tả không lưu (xem trước khi gõ) | M | MVP | UI-02-03, UI-02-04 |
| FR-02-020 | C | Phát hiện API trùng chức năng | S | MVP | UI-02-03, UI-02-10 |
| FR-02-021 | C | Quản lý bộ luật kiểm tra quy ước | S | MVP | UI-02-15 |
| FR-02-022 | D | Khai báo backend của API | M | MVP | UI-02-02 |
| FR-02-023 | D | Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe backend | M | MVP | UI-02-02 |
| FR-02-024 | D | Quản lý context-path và kiểm tra trùng | M | MVP | UI-02-03, UI-02-02 |
| FR-02-025 | D | Xem sức khỏe backend | S | MVP | UI-02-02 |
| FR-02-026 | D | Sinh khung route cho PH-04 từ đặc tả | M | MVP | UI-02-02 |
| FR-02-027 | E | Tạo gói sử dụng: thông tin và điều kiện truy cập | M | MVP | UI-02-07 |
| FR-02-028 | E | Chọn kiểu xác thực của gói | M | MVP | UI-02-07 |
| FR-02-029 | E | Khai báo hạn mức và đường dẫn cho phép của gói | M | MVP | UI-02-07 |
| FR-02-030 | E | Công bố gói (`STAGING` sang `PUBLISHED`) | M | MVP | UI-02-06, UI-02-10 |
| FR-02-031 | E | Ngừng khuyến nghị gói | M | MVP | UI-02-06 |
| FR-02-032 | E | Đóng gói | M | MVP | UI-02-06 |
| FR-02-033 | E | Sao chép gói sang phiên bản mới | S | MVP | UI-02-06 |
| FR-02-034 | F | Gửi duyệt công bố API | M | MVP | UI-02-02 |
| FR-02-035 | F | Duyệt hoặc từ chối công bố (bốn mắt) | M | MVP | UI-02-10 |
| FR-02-036 | F | Công bố API ra gateway và danh mục | M | MVP | UI-02-02 |
| FR-02-037 | F | Tạm ngừng và tiếp tục API | M | MVP | UI-02-02 |
| FR-02-038 | F | Ngừng khuyến nghị API có lộ trình | M | MVP | UI-02-13 |
| FR-02-039 | F | Ngừng hẳn API | M | MVP | UI-02-13 |
| FR-02-040 | F | Xóa API | M | MVP | UI-02-02 |
| FR-02-041 | F | Đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển | M | MVP | UI-02-02 |
| FR-02-042 | F | Tạo phiên bản mới | M | MVP | UI-02-02 |
| FR-02-043 | F | So sánh phiên bản và phân loại thay đổi phá vỡ | M | MVP | UI-02-05 |
| FR-02-044 | F | Phân tích tác động của thay đổi tới bên khai thác | M | MVP | UI-02-05 |
| FR-02-045 | F | Chuyển chủ quản API | S | MVP | UI-02-02 |
| FR-02-046 | G | Gửi đăng ký sử dụng API | M | MVP | UI-02-09 |
| FR-02-047 | G | Duyệt hoặc từ chối đăng ký sử dụng | M | MVP | UI-02-10 |
| FR-02-048 | G | Cấp phạm vi truy cập theo đăng ký đã duyệt | M | MVP | UI-02-08 |
| FR-02-049 | G | Xem đăng ký theo API | M | MVP | UI-02-02 |
| FR-02-050 | G | Xem đăng ký theo HTTT | M | MVP | UI-02-08 |
| FR-02-051 | G | Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký | M | MVP | UI-02-08 |
| FR-02-052 | G | Gia hạn và rà soát định kỳ đăng ký | S | Đợt 2 | UI-02-08 |
| FR-02-053 | H | Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14 | M | MVP | UI-02-12 |
| FR-02-054 | H | Theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn | M | MVP | UI-02-12 |
| FR-02-055 | I | Khai báo cam kết chất lượng dịch vụ (SLA) | M | MVP | UI-02-02, UI-02-11 |
| FR-02-056 | I | Đối chiếu SLA thực tế, báo cáo tuân thủ | M | MVP | UI-02-11 |
| FR-02-057 | I | Thông báo thay đổi cho bên khai thác | M | MVP | UI-02-13 |
| FR-02-058 | I | Thống kê sử dụng dịch vụ | S | Đợt 2 | UI-02-11 |
| FR-02-059 | J | Cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15 | M | MVP | không có màn |
| FR-02-060 | J | Đối soát cấu hình công bố với gateway | C | Đợt 2 | UI-02-17 |
| FR-02-061 | J | Di trú API, gói, đăng ký từ APIM cũ | M | MVP | UI-02-16 |
| FR-02-062 | J | Cấu hình tham số của phân hệ | M | MVP | UI-02-17 |

: Danh sách chức năng của PH-02

Tổng số: 62 chức năng, trong đó M: 50, S: 11, C: 1. Bốn chức năng thuộc Đợt 2 là FR-02-009, 052, 058 (mức S) và FR-02-060 (mức C); 58 chức năng còn lại thuộc MVP.

## 6. Đặc tả chi tiết chức năng

Chương này đặc tả từng chức năng cho kỹ sư và kiểm thử viên: ai làm, điều kiện trước, từng bước xử lý, mã lỗi, thông báo người dùng thấy, sự kiện và kiểm toán. Mười nhóm chức năng đi theo thứ tự một API trải qua trong thực tế, từ danh mục, đăng ký, kiểm tra, backend, gói, vòng đời, tới đăng ký sử dụng, đồng bộ quốc gia, chất lượng và quản trị.

### 6.1. Cách đọc bảng đặc tả

Mỗi chức năng được đặc tả bằng một bảng hai cột gồm 17 mục cố định. Chuẩn này kết hợp hai nguồn: 12 trường kỹ thuật của mẫu FR ở D00-01 §4.3 (đầu vào, đầu ra, mã lỗi, sự kiện, kiểm toán) để kỹ sư và kiểm thử viên dùng ngay, và các mục của mẫu thuyết minh đặc tả chức năng (mục đích, kích hoạt, luồng theo tác nhân, thông báo, kết quả, màn hình) để hội đồng và người dùng nghiệp vụ đọc được. Mục không áp dụng ghi "Không" để người đọc biết đã được xét, không bị bỏ sót.

| Mục | Nội dung | Nguồn |
|---|---|---|
| Mục đích | Chức năng giúp ai làm được việc gì, vì sao cần | Mẫu thuyết minh |
| Tác nhân, quyền | Vai trò thực hiện và `PERM` cần có | D00-01 §4.3 |
| Mức ưu tiên, đợt | M (bắt buộc), S (nên có), C (có thì tốt); đợt phát hành | D00-01 §4.3, mẫu |
| Truy vết | REQ, LGC, Q, ADR | D00-01 §4.3 |
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

Ví dụ trong chương này dùng tenant `T68`; HTTT cung cấp `HT-TUPHAP` (Sở Tư pháp, đơn vị chủ quản `SO-TUPHAP`) với API `tra-cuu-ho-tich`; HTTT `HT-DATDAI` (Sở Tài nguyên và Môi trường) với API `ho-so-dat-dai`; HTTT khai thác `HT-MOTCUA` (Hệ thống một cửa điện tử) và `HT-DKKD` (đăng ký kinh doanh). Đây là dữ liệu giả lập. Mọi API ở mặt phẳng điều khiển dùng tiền tố `/api/catalog/v1`, lỗi theo RFC 9457, phân trang `page`/`size`, thao tác dạng hành động viết `POST …/{mã}:{động từ}`. Mọi lệnh ghi nhận tiêu đề `Idempotency-Key` (ERR-02-042) và `If-Match` với `ETag` của đối tượng (ERR-02-015) theo FR-00-052; các chức năng dưới đây chỉ nhắc lại khi có điểm đặc thù. Mặc định mọi lệnh ghi sinh bản ghi kiểm toán theo FR-00-040, 041 và danh sách, lọc, phân trang, xuất theo FR-00-020…034.

### 6.2. Nhóm A · Danh mục và tra cứu

Nhóm A là phần người dùng thấy đầu tiên: danh mục các API của tỉnh, tìm kiếm, xem chi tiết, lấy đường dẫn và đặc tả để lập trình. Cùng một dữ liệu có hai cách đọc: người dùng ở giao diện quản trị (FR-02-001…003, 005…007) và máy hoặc cổng nhà phát triển (FR-02-004). Hình dưới tóm tắt quan hệ giữa các chức năng trong nhóm.

```{.mermaid caption="Quan hệ giữa các chức năng nhóm A"}
flowchart TB
  L["FR-02-001<br/>Liệt kê, lọc"] --> D["FR-02-002<br/>Chi tiết API"]
  S["FR-02-003<br/>Tìm kiếm toàn văn"] --> D
  D --> U["FR-02-005<br/>Đường dẫn, mẫu gọi"]
  D --> O["FR-02-006<br/>Tải đặc tả"]
  K["FR-02-007, 008<br/>Phân loại, thẻ"] --> L
  M["FR-02-004<br/>Danh mục cho máy, cổng"] --> D
  E["FR-02-009<br/>Dịch vụ sự kiện"] --> L
```

Hình trên cho thấy danh sách và tìm kiếm cùng dẫn tới chi tiết API, từ chi tiết đi tiếp tới đường dẫn gọi và đặc tả. Phân loại, thẻ làm cho danh sách lọc được; danh mục cho máy đọc cùng nguồn dữ liệu với màn hình.

#### FR-02-001 · Liệt kê API trong danh mục, lọc, sắp xếp

::: dac-ta
**Mục đích.** Cho cán bộ của tỉnh nhìn toàn cảnh các API đã khai báo (nháp, đang chạy, sắp ngừng), lọc theo đơn vị, loại dữ liệu, trạng thái để biết "tỉnh mình đang chia sẻ những dịch vụ nào, ai chịu trách nhiệm, đang ở giai đoạn nào". Đây là màn hình khởi đầu của mọi việc ở PH-02.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-001.

**Tiền điều kiện.** Người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004).

**Kích hoạt.** Người dùng mở menu "Kết nối & API → Danh mục API" (`/ket-noi/api`).

**Đầu vào.** `q` (tìm nhanh theo mã, tên), `status` (trạng thái phiên bản mới nhất, chọn nhiều), `dataClass`, `categoryCode`, `systemCode` (HTTT cung cấp), `ownerOrg`, `visibility`, `origin`, `tag`; `page`, `size`, `sort` theo FR-00-021, 022.

**Luồng xử lý chính.**

1. Người dùng mở màn danh sách; hệ thống áp mặc định: trạng thái khác `RETIRED`, sắp xếp API có cảnh báo trước (SLA không đạt, đồng bộ quốc gia lỗi, gateway lệch), rồi theo thời gian cập nhật giảm dần.
2. Hệ thống kiểm tra tham số; sai miền giá trị hoặc `size` > 200 thì từ chối (ERR-02-003).
3. Hệ thống truy vấn API của tenant hiện hành theo quyền hiển thị: phiên bản `DRAFT`, `PENDING` chỉ hiện với tổ chức chủ quản, TA, CA, PA (BR-02-039); người khác thấy API khi có ít nhất một phiên bản từ `PUBLISHED` trở đi.
4. Hệ thống tính các số đếm theo trạng thái cho dải thẻ tổng ở đầu trang (Tất cả, Đang chạy, Chờ duyệt, Sắp ngừng, Cần chú ý) và trả danh sách phân trang.
5. Người dùng bấm một dòng để mở chi tiết (FR-02-002) hoặc bấm "Xuất" để xuất theo bộ lọc hiện tại (FR-00-030).

**Luồng thay thế.** Người dùng bấm một thẻ tổng để lọc nhanh; bộ lọc ghi vào URL để chia sẻ (FR-00-022).

**Luồng ngoại lệ.**

- Tham số lọc sai miền giá trị hoặc `size` quá lớn: ERR-02-003 (400); "Bộ lọc không hợp lệ: {tên trường}."
- Không có API khớp: trả `200` với danh sách rỗng; màn hình hiện "Chưa có API nào khớp bộ lọc." kèm nút "Xóa bộ lọc".

**Đầu ra.** `200`; `items[]` gồm `apiCode`, tên, HTTT cung cấp, đơn vị chủ quản, `dataClass`, `visibility`, `origin`, phiên bản mới nhất và trạng thái, số bên đăng ký `ACTIVE`, chỉ báo SLA kỳ gần nhất, cờ cảnh báo; `page`, `size`, `totalElements`, khối `facets` (số đếm theo trạng thái, loại dữ liệu, phân loại).

**Kết quả.** Người dùng thấy danh sách API của tỉnh với những mục cần chú ý nổi lên trên, lọc được theo mọi tiêu chí thường dùng.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (thao tác chỉ đọc, không có dữ liệu Nhạy cảm).

**Quy tắc nghiệp vụ.** BR-02-033 (đối tượng tenant khác không xuất hiện); BR-02-039.

**Màn hình, API.** UI-02-01; API-02-001.
:::

#### FR-02-002 · Xem chi tiết API

::: dac-ta
**Mục đích.** Cho người dùng xem trọn thông tin một API ở một chỗ: mô tả, chủ quản, các phiên bản và trạng thái, backend, gói sử dụng, danh sách bên đăng ký, thống kê, SLA và lịch sử thay đổi, để quyết định khai thác, duyệt hay ngừng dùng.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-001; LGC-APIM-017.

**Tiền điều kiện.** API tồn tại trong tenant hiện hành và người dùng được xem (BR-02-039).

**Kích hoạt.** Người dùng bấm một dòng ở UI-02-01, hoặc mở trực tiếp `/ket-noi/api/{ma-api}`.

**Đầu vào.** `apiCode` trong đường dẫn; `versionNo` tùy chọn để mở đúng phiên bản (mặc định phiên bản `PUBLISHED` mới nhất, nếu không có thì phiên bản mới nhất).

**Luồng xử lý chính.**

1. Người dùng mở trang chi tiết; hệ thống kiểm tra API thuộc tenant hiện hành (không phải: ERR-02-001).
2. Hệ thống lấy thông tin chung: mã, tên, mô tả, HTTT cung cấp, đơn vị chủ quản, `dataClass`, `visibility`, phân loại, thẻ, nguồn gốc, đầu mối kỹ thuật (từ PH-01).
3. Hệ thống dựng các tab theo quyền: Tổng quan, Phiên bản, Backend, Gói sử dụng, Đăng ký, Thống kê, SLA, Lịch sử (FR-00-043). Tab Đăng ký và Thống kê chỉ hiện đủ dữ liệu cho SV của tổ chức chủ quản, TA, CA; người khác thấy số tổng.
4. Hệ thống hiển thị nhãn trạng thái từng phiên bản và chỉ các hành động hợp lệ ở trạng thái đó (FR-00-053): ví dụ phiên bản `DRAFT` có "Gửi duyệt", phiên bản `PUBLISHED` có "Tạm ngừng", "Ngừng khuyến nghị".
5. Với phiên bản `DEPRECATED`, hệ thống hiện hạn chuyển đổi, phiên bản kế nhiệm và số bên chưa chuyển.

**Luồng thay thế.** Người dùng mở phiên bản cũ bằng bộ chọn phiên bản ở đầu trang; các tab hiển thị theo phiên bản được chọn.

**Luồng ngoại lệ.**

- API không có hoặc thuộc tenant khác: ERR-02-001 (404, cùng thân với "không tồn tại"); "Không tìm thấy API {mã}."
- Người dùng không được xem phiên bản nháp của đơn vị khác: bị ẩn, không báo lỗi (BR-02-039).

**Đầu ra.** `200`, `ETag`; chi tiết API kèm `versions[]` (số hiệu, trạng thái, `sunsetAt`, kế nhiệm), thông tin phiên bản được chọn (đường dẫn công bố, backend tóm tắt, gói tóm tắt, SLA cam kết và thực tế, số đăng ký theo trạng thái), `allowedActions[]`.

**Kết quả.** Người dùng nắm được toàn bộ tình trạng một API và biết mình làm được gì tiếp theo.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-02-033; BR-02-039; BR-02-013 (SLA cam kết hiển thị cùng thực tế).

**Màn hình, API.** UI-02-02 tab Tổng quan; API-02-002, API-02-090, API-02-091.
:::

#### FR-02-003 · Tìm kiếm toàn văn danh mục

::: dac-ta
**Mục đích.** Cho cán bộ không biết mã API vẫn tìm được dịch vụ cần dùng bằng từ khóa tự nhiên ("tra cứu hộ tịch", "đất đai") không phân biệt hoa thường và dấu tiếng Việt, kể cả tìm trong mô tả và mô tả thao tác của đặc tả.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`; HTTT khai thác với scope `catalog:read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-001; SRS cũ FR-02-008.

**Tiền điều kiện.** Người dùng đã đăng nhập, đã chọn tenant.

**Kích hoạt.** Người dùng gõ vào ô tìm kiếm ở UI-02-01 (sau 300 ms ngừng gõ), hoặc gọi API tìm kiếm.

**Đầu vào.** `q` (2…100 ký tự), các bộ lọc như FR-02-001, `fields` (chọn phạm vi tìm: `meta`, `spec`, mặc định cả hai), `page`, `size`.

**Luồng xử lý chính.**

1. Hệ thống chuẩn hóa `q`: Unicode NFC, bỏ dấu, hạ chữ thường, tách từ; từ khóa ngắn hơn 2 ký tự bị bỏ qua (ERR-02-003 nếu không còn từ nào).
2. Hệ thống tìm trong chỉ mục của tenant: mã, tên, mô tả, thẻ, phân loại, tên HTTT cung cấp, và (khi `fields` có `spec`) `summary`, `description`, `operationId` của các thao tác trong đặc tả đã công bố.
3. Hệ thống xếp hạng theo độ khớp, trọng số cao hơn cho mã và tên; cùng độ khớp thì ưu tiên API `PUBLISHED`, rồi sắp ngừng.
4. Hệ thống áp quyền hiển thị giống FR-02-001 và trả kết quả có đoạn trích tô sáng.
5. Khi không có kết quả, hệ thống gợi ý tối đa 5 từ khóa gần nhất (khoảng cách chỉnh sửa ≤ 2) và 5 phân loại có nhiều API nhất.

**Luồng thay thế.** Hồ sơ `QM-LON`, `QM-CHUNG` cấu hình `02.search.engine = OPENSEARCH`: bước 2 gọi OpenSearch với bộ phân tích tiếng Việt, kết quả và quyền hiển thị không đổi (Q02-02).

**Luồng ngoại lệ.**

- `q` rỗng hoặc chỉ có ký tự đặc biệt: ERR-02-003 (400); "Nhập ít nhất 2 ký tự để tìm."
- Chỉ mục đang dựng lại: chuyển sang tìm theo mã, tên bằng `ILIKE`; kết quả kèm cờ `degraded = true`, màn hình báo "Đang cập nhật chỉ mục, kết quả có thể chưa đầy đủ."

**Đầu ra.** `200`; `items[]` như FR-02-001 kèm `highlights`, `score`; `suggestions[]` khi rỗng; `degraded`.

**Kết quả.** Người dùng tìm được dịch vụ mong muốn chỉ với vài từ khóa, kể cả khi gõ không dấu.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không; truy vấn tìm kiếm không lưu nội dung `q` ở kiểm toán, chỉ đếm ở chỉ số `catalog_search_total`.

**Quy tắc nghiệp vụ.** BR-02-033; BR-02-039.

**Màn hình, API.** UI-02-01 ô tìm kiếm; API-02-003.
:::

#### FR-02-004 · Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển theo mức hiển thị

::: dac-ta
**Mục đích.** Cho HTTT khai thác và cổng nhà phát triển (PH-15) tự động đọc danh mục các API đang cung cấp, kèm đặc tả và điều kiện sử dụng, đúng với nghĩa vụ công khai thông tin dịch vụ chia sẻ dữ liệu; bên ngoài tenant chỉ thấy những gì được phép công khai.

**Tác nhân, quyền.** HTTT khai thác (scope `catalog:read`); PH-15 (scope `catalog:portal-read`); mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; CMP-LAW-03; SRS cũ FR-02-008 (`/api/v1/catalog`).

**Tiền điều kiện.** Có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`.

**Kích hoạt.** Cổng nhà phát triển hoặc HTTT gọi `GET /catalog/apis`; người dùng mở danh mục ở PH-15.

**Đầu vào.** `q`, `categoryCode`, `dataClass`, `visibility`, `updatedSince` (T-TS, để lấy phần thay đổi), `page`, `size`; tiêu đề `If-None-Match`.

**Luồng xử lý chính.**

1. Hệ thống xác định chủ thể từ token: HTTT khai thác của tenant, PH-15, hoặc người dùng không đăng nhập (chỉ ở cổng công khai).
2. Hệ thống chọn tập API được phép thấy: chủ thể trong tenant thấy `TENANT`, `NATIONAL`, `PUBLIC`; người dùng không đăng nhập ở cổng công khai chỉ thấy `PUBLIC` (BR-02-037).
3. Hệ thống chỉ trả phiên bản `PUBLISHED`, `DEPRECATED`; không trả phiên bản `SUSPENDED` (hiển thị nhãn "Tạm ngừng" ở mục chi tiết) hoặc nháp.
4. Mỗi mục gồm mã, tên, mô tả, chủ quản, loại dữ liệu, `dataClass`, SLA cam kết và thực tế, phạm vi cần có, trạng thái, số phiên bản, liên kết tới đặc tả và tài liệu; không trả backend, địa chỉ nội bộ, danh sách bên đăng ký.
5. Hệ thống đặt `ETag` theo băm nội dung; yêu cầu có `If-None-Match` khớp thì trả `304` (NFR-02-001).

**Luồng thay thế.** Tham số `updatedSince` trả chỉ các mục đổi sau thời điểm đó, kèm danh sách mã đã gỡ (`removed[]`), để PH-15 đồng bộ gia tăng.

**Luồng ngoại lệ.**

- Token thiếu hoặc không có scope `catalog:read`: `401`/`403` ERR-02-014; không có màn hình (lỗi gọi máy).
- API không thuộc tập được phép thấy: không xuất hiện, `GET /catalog/apis/{apiCode}` trả ERR-02-001 (404).
- Vượt giới hạn tần suất của gateway: `429` theo PH-03, tiêu đề `Retry-After`.

**Đầu ra.** `200` hoặc `304`; `items[]`, `removed[]`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `Cache-Control: private, max-age=300` (giá trị `public` chỉ với tập `PUBLIC`).

**Kết quả.** Bên khai thác có danh mục dịch vụ luôn cập nhật mà không phải hỏi từng đơn vị.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với tập `PUBLIC` và `TENANT`; với tập `NATIONAL` truy cập của chủ thể máy được ghi mức tóm tắt (thời điểm, chủ thể, số mục) vào nhật ký truy cập.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-037; BR-02-033.

**Màn hình, API.** UI-02-01; API-02-004, API-02-005, API-02-081 (cho PH-15).
:::

#### FR-02-005 · Xem đường dẫn sử dụng và mẫu gọi API

::: dac-ta
**Mục đích.** Cho bên khai thác biết chính xác địa chỉ gọi API ở từng môi trường và có sẵn mẫu lệnh gọi, thay vì tự ghép "địa chỉ gateway + context-path" như ở hệ cũ.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-017.

**Tiền điều kiện.** Phiên bản có context-path (FR-02-024); để thấy đường dẫn môi trường thật phiên bản phải `PUBLISHED`.

**Kích hoạt.** Người dùng mở tab Tổng quan, khối "Cách gọi API", của UI-02-02.

**Đầu vào.** `apiCode`, `versionNo`; `environment` (`TEST`, `STAGING`, `PROD`, mặc định `PROD`); `planCode` tùy chọn.

**Luồng xử lý chính.**

1. Hệ thống lấy địa chỉ gốc của gateway theo tenant và môi trường (tham số nền tảng của PH-03) và ghép với context-path của phiên bản: `https://{gateway}/{categoryCode}/{apiCode}/v{major}`.
2. Hệ thống liệt kê các thao tác từ đặc tả: phương thức, đường dẫn đầy đủ, mô tả, phạm vi cần có.
3. Với gói đã chọn (hoặc gói đầu tiên `PUBLISHED`), hệ thống sinh mẫu lệnh theo kiểu xác thực: `curl` kèm `Authorization: Bearer {token}` (OAuth), `X-API-Key` (khóa API), hoặc cờ `--cert` `--key` (mTLS); mẫu dùng giá trị giữ chỗ, không bao giờ chứa bí mật thật.
4. Hệ thống hiển thị thêm địa chỉ lấy token của realm tenant, phạm vi cần xin, tiêu đề bắt buộc (`Idempotency-Key` với thao tác ghi, `traceparent`).
5. Môi trường `TEST`, `STAGING` chỉ hiển thị cho người có `PERM-02-create` của API đó; bên khai thác chỉ thấy `PROD`.

**Luồng thay thế.** Người dùng bấm "Sao chép" để chép lệnh mẫu hoặc "Mở ở cổng nhà phát triển" (liên kết PH-15).

**Luồng ngoại lệ.**

- Phiên bản chưa `PUBLISHED` khi yêu cầu môi trường `PROD`: ERR-02-011 (409); "API chưa được công bố nên chưa có đường dẫn môi trường thật."
- Phiên bản chưa có context-path: ERR-02-019 (422); "Chưa đặt đường dẫn công bố cho phiên bản này."

**Đầu ra.** `200`; `baseUrl`, `operations[]` (phương thức, đường dẫn, mô tả, phạm vi), `tokenUrl`, `scopes[]`, `samples[]` (`curl`, `javascript`, `java`).

**Kết quả.** Bên khai thác sao chép được lệnh gọi đúng, có đủ tiêu đề và phương thức xác thực.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-02-022; BR-02-025.

**Màn hình, API.** UI-02-02 tab Tổng quan; API-02-006.
:::

#### FR-02-006 · Tải đặc tả OpenAPI đã công bố

::: dac-ta
**Mục đích.** Cho bên khai thác và cổng nhà phát triển tải đặc tả OpenAPI của phiên bản đã công bố làm tài liệu kỹ thuật để lập trình và sinh mã máy khách, đáp ứng nghĩa vụ công bố tài liệu kỹ thuật đi kèm dịch vụ chia sẻ.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`; HTTT khai thác với scope `catalog:read`; PH-04 với scope `catalog:flow-sync`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; CMP-LAW-03; SRS cũ (`/openapi`).

**Tiền điều kiện.** Phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED`; riêng chủ quản, TA, CA tải được cả phiên bản `DRAFT`, `PENDING`.

**Kích hoạt.** Người dùng bấm "Tải đặc tả" ở UI-02-02; PH-04 gọi để sinh luồng từ API.

**Đầu vào.** `apiCode`, `versionNo`; `format` (`yaml`, `json`, mặc định theo định dạng gốc); `resolve` (`true` để gộp `$ref` ngoài thành một tệp).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra quyền xem phiên bản (BR-02-039, BR-02-037); không được thì trả ERR-02-001.
2. Hệ thống lấy nội dung đặc tả từ kho đối tượng, kiểm tra băm `sha256` khớp với bản ghi.
3. Hệ thống thay `servers[]` bằng địa chỉ gateway của môi trường `PROD` và gắn phần mở rộng `x-datahub-api-code`, `x-datahub-version`, `x-datahub-plans`; ví dụ trong đặc tả giữ nguyên.
4. Hệ thống chuyển định dạng nếu được yêu cầu và trả tệp với tên `{apiCode}-{versionNo}.openapi.yaml`.

**Luồng thay thế.** `resolve = true` gộp tham chiếu ngoài; nếu tham chiếu ngoài không còn tải được thì dùng bản đã gộp lúc nạp.

**Luồng ngoại lệ.**

- Băm không khớp (tệp bị hỏng ở kho): ERR-02-034 (503); "Không đọc được đặc tả, hãy thử lại sau hoặc báo quản trị." kèm cảnh báo cho TO.
- Phiên bản không có hoặc không được xem: ERR-02-001 (404).

**Đầu ra.** `200`; thân là tài liệu OpenAPI; tiêu đề `Content-Disposition`, `ETag`, `Content-Type: application/yaml` hoặc `application/json`.

**Kết quả.** Bên khai thác có tệp đặc tả đúng phiên bản, dùng ngay với công cụ sinh mã.

**Hậu điều kiện.** Không thay đổi dữ liệu; bộ đếm tải đặc tả tăng một (chỉ số `catalog_spec_download_total`).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với phiên bản đã công bố; có (ghi người tải) với phiên bản `DRAFT`, `PENDING`.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-014; BR-02-039.

**Màn hình, API.** UI-02-02 tab Phiên bản; API-02-007.
:::

#### FR-02-007 · Phân loại và gắn thẻ API

::: dac-ta
**Mục đích.** Cho chủ dịch vụ xếp API vào nhóm nghiệp vụ, đặt mức phân loại dữ liệu và gắn thẻ để người khai thác tìm đúng dịch vụ và để hệ thống áp đúng ràng buộc bảo mật theo mức phân loại.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS hệ thống PH-02 ("phân loại, gắn thẻ"); CMP-LAW-01.

**Tiền điều kiện.** API tồn tại; người dùng thuộc tổ chức chủ quản (hoặc là TA).

**Kích hoạt.** Người dùng sửa khối "Phân loại" ở UI-02-02 hoặc ở bước 1 của UI-02-03.

**Đầu vào.** `categoryCode` (một nhóm, bắt buộc); `tags[]` (0…10 thẻ, mỗi thẻ 2…32 ký tự); `dataClass` (`PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`, bắt buộc); `stateSecret` (T-BOOL, bắt buộc khai, phải là `false`); `containsPersonalData` (T-BOOL); `legalBasis` (T-TEXT, bắt buộc khi `containsPersonalData = true`).

**Luồng xử lý chính.**

1. Người dùng chọn nhóm, mức phân loại và thẻ; giao diện giải thích hệ quả của từng mức (kiểu xác thực tối thiểu, mức hiển thị tối đa).
2. Hệ thống kiểm tra nhóm có trong bộ phân loại của tenant (ERR-02-003), số thẻ và độ dài.
3. Hệ thống từ chối nếu `stateSecret = true` (ERR-02-016): dữ liệu thuộc bí mật nhà nước không được công bố qua Datahub (BR-02-007).
4. Hệ thống kiểm tra hệ quả với dữ liệu đã có: hạ `dataClass` không ảnh hưởng; nâng `dataClass` thì rà các gói đang `PUBLISHED`, nếu kiểu xác thực của gói không còn phù hợp (BR-02-016) thì từ chối và liệt kê gói vi phạm (ERR-02-022); mức hiển thị hiện có vượt mức mới (BR-02-037) cũng bị từ chối (ERR-02-043).
5. Hệ thống lưu, tăng `version` của API, ghi kiểm toán giá trị trước và sau; nếu API đã `PUBLISHED` và mức `NATIONAL`, `PUBLIC` thì xếp đồng bộ quốc gia lại (FR-02-053).

**Luồng thay thế.** Chủ dịch vụ chỉ đổi thẻ: bỏ qua bước 4.

**Luồng ngoại lệ.**

- `stateSecret = true`: ERR-02-016 (422); "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub."
- Nâng mức khi còn gói không phù hợp: ERR-02-022 (422); "Mức phân loại mới yêu cầu xác thực mạnh hơn. Gói {mã gói} cần được đổi trước."
- Có dữ liệu cá nhân mà thiếu căn cứ pháp lý: ERR-02-003 (400); "Nêu căn cứ pháp lý xử lý dữ liệu cá nhân."
- Sửa khi phiên bản đang `PENDING`: ERR-02-038 (409); "API đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước."

**Đầu ra.** `200`, `ETag` mới; thông tin API sau cập nhật.

**Kết quả.** API nằm đúng nhóm, đúng mức phân loại, tìm kiếm và lọc được.

**Hậu điều kiện.** Thuộc tính phân loại của API cập nhật; chỉ mục tìm kiếm cập nhật trong 1 phút.

**Sự kiện phát ra.** EVT-02-02 (`api.updated`, `changedFields`).

**Kiểm toán.** Có: giá trị trước, sau của nhóm, mức phân loại, thẻ, `containsPersonalData`; `legalBasis` ghi mã văn bản.

**Quy tắc nghiệp vụ.** BR-02-007; BR-02-016; BR-02-032; BR-02-037.

**Màn hình, API.** UI-02-02 tab Tổng quan, UI-02-03 bước 1, UI-02-14; API-02-008.
:::

#### FR-02-008 · Quản lý bộ phân loại và thẻ

::: dac-ta
**Mục đích.** Cho quản trị tenant giữ một bộ nhóm nghiệp vụ thống nhất toàn tỉnh (ví dụ Hộ tịch, Đất đai, Y tế), tránh mỗi đơn vị tự đặt tên nhóm khác nhau làm danh mục rối.

**Tác nhân, quyền.** TA, PA có quyền quản trị phân hệ (đề nghị, động từ `admin`); mọi vai trò xem (`PERM-02-read`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; SRS hệ thống PH-02 ("phân loại, gắn thẻ").

**Tiền điều kiện.** Không.

**Kích hoạt.** Quản trị mở UI-02-14 (cây phân loại kèm bảng API trong nhóm).

**Đầu vào.** `categoryCode` (T-CODE, `^[a-z][a-z0-9-]{1,31}$`), `name` (T-NAME), `parentCode` (tùy chọn, tối đa 3 cấp), `order`; thao tác gộp: `mergeInto`.

**Luồng xử lý chính.**

1. Quản trị thêm nhóm: nhập mã, tên, nhóm cha; hệ thống kiểm tra mã chưa dùng, kể cả mã đã xóa (ERR-02-002) và độ sâu ≤ 3 (ERR-02-003).
2. Hệ thống lưu nhóm; nhóm mới có sẵn để chọn ở FR-02-007.
3. Khi đổi tên hoặc đổi nhóm cha, hệ thống cập nhật hiển thị; mã nhóm là bất biến vì nằm trong context-path (BR-02-022), nên chỉ đổi tên, không đổi mã.
4. Khi xóa nhóm: nếu còn API thuộc nhóm thì từ chối và đề nghị gộp (ERR-02-030 với `mergeInto` bắt buộc); nếu gộp thì cập nhật nhóm của các API, giữ nguyên context-path đã công bố.
5. Hệ thống ghi kiểm toán và làm mới chỉ mục tìm kiếm.

**Luồng thay thế.** Hệ thống nạp sẵn bộ nhóm mặc định theo danh mục lĩnh vực quản lý nhà nước ở PH-07 (bảng mã `DM_LINH_VUC`) khi tenant khởi tạo; quản trị bổ sung thêm.

**Luồng ngoại lệ.**

- Mã nhóm trùng: ERR-02-002 (409); "Mã nhóm {mã} đã được dùng. Chọn mã khác."
- Xóa nhóm còn API: ERR-02-030 (409); "Còn {n} API thuộc nhóm này. Chọn nhóm để gộp trước khi xóa."

**Đầu ra.** `201` (thêm, tiêu đề `Location`), `200` (sửa, gộp), `204` (xóa).

**Kết quả.** Toàn tỉnh dùng một bộ nhóm nghiệp vụ thống nhất.

**Hậu điều kiện.** Bộ phân loại cập nhật; các API đã gộp mang nhóm mới.

**Sự kiện phát ra.** EVT-02-02 cho từng API đổi nhóm.

**Kiểm toán.** Có: thao tác, mã nhóm, giá trị trước, sau, số API ảnh hưởng.

**Quy tắc nghiệp vụ.** BR-02-021; BR-02-022.

**Màn hình, API.** UI-02-14; API-02-009, API-02-010, API-02-011, API-02-012.
:::

#### FR-02-009 · Hiển thị dịch vụ sự kiện (topic) trong danh mục

::: dac-ta
**Mục đích.** Cho HTTT tìm thấy cả dịch vụ sự kiện (topic Kafka `ACTIVE` do PH-10 quản lý) trong cùng danh mục với API, để một chỗ duy nhất liệt kê những gì tỉnh chia sẻ; việc đăng ký nhận, phát sự kiện vẫn thực hiện ở PH-10.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-02; PH-10 mục "Công bố topic như một dịch vụ trong danh mục"; Q10-19; Q02-05.

**Tiền điều kiện.** PH-10 đã triển khai; topic `ACTIVE`.

**Kích hoạt.** PH-02 nhận EVT-10-01, 03, 04 của PH-10; hoặc người dùng chọn bộ lọc "Dịch vụ sự kiện" ở UI-02-01.

**Đầu vào.** Sự kiện của PH-10 (`topicName`, trạng thái, kế nhiệm, `sunsetAt`); phía người dùng: bộ lọc `kind = EVENT`.

**Luồng xử lý chính.**

1. Hệ thống nhận EVT-10-01 (topic `ACTIVE`) và tạo hoặc cập nhật một mục danh mục loại `EVENT` tham chiếu `topicName`, không giữ bản sao nội dung lược đồ.
2. Hệ thống lấy mô tả, lược đồ sự kiện, mức phân loại, HTTT phát từ PH-10 qua API đọc (hoặc khối đệm 60 giây) để hiển thị.
3. Khi nhận EVT-10-03 (`DEPRECATED`) hoặc EVT-10-04 (`RETIRED`), hệ thống đổi nhãn trạng thái mục tương ứng và phát thông báo cho bên đăng ký (qua PH-10) theo nguyên tắc của FR-02-057.
4. Người dùng lọc "Dịch vụ sự kiện" ở UI-02-01 thấy các mục này kèm nút "Mở ở PH-10" thay cho "Đăng ký sử dụng".
5. Hệ thống không cho tạo, sửa, đăng ký, duyệt các mục này ở PH-02 (BR-02-038).

**Luồng thay thế.** PH-10 không phát sự kiện (chưa triển khai): hệ thống đồng bộ định kỳ 15 phút bằng API đọc.

**Luồng ngoại lệ.**

- PH-10 không khả dụng khi lấy chi tiết: hiển thị phần đã đệm kèm nhãn "Chưa cập nhật lúc {thời điểm}"; ERR-02-034 chỉ ghi nhật ký, không chặn.
- Người dùng cố sửa mục sự kiện ở PH-02: ERR-02-014 (403); "Dịch vụ sự kiện được quản lý ở phân hệ Sự kiện."

**Đầu ra.** `200`; mục danh mục loại `EVENT` gồm `topicName`, mô tả, trạng thái, `dataClass`, HTTT phát, liên kết sang PH-10.

**Kết quả.** Người dùng tìm thấy topic sự kiện của tỉnh cùng chỗ với các API.

**Hậu điều kiện.** Mục danh mục loại `EVENT` đồng bộ với trạng thái topic ở PH-10.

**Sự kiện phát ra.** Không (chỉ tiêu thụ).

**Kiểm toán.** Không (đồng bộ tự động); kiểm toán thay đổi trạng thái nằm ở PH-10.

**Quy tắc nghiệp vụ.** BR-02-038; BR-02-033.

**Màn hình, API.** UI-02-01 bộ lọc dịch vụ sự kiện; API-02-013.
:::

### 6.3. Nhóm B · Đăng ký API và nạp đặc tả

Nhóm B là cửa vào của chủ dịch vụ: đưa một API mới vào danh mục bằng biểu mẫu, bằng tệp OpenAPI, bằng địa chỉ URL hoặc để PH-04 tự đăng ký khi luồng có điểm vào REST. Mọi con đường đều dẫn tới một phiên bản `DRAFT` có đặc tả, rồi sang nhóm C để kiểm tra. Hình dưới tóm tắt các con đường vào.

```{.mermaid caption="Các con đường đưa API vào danh mục"}
flowchart TB
  W["FR-02-010<br/>Trình hướng dẫn"] --> V["Phiên bản DRAFT<br/>có đặc tả"]
  F["FR-02-011<br/>Tệp, dán, URL"] --> V
  P["FR-02-013<br/>Từ luồng PH-04"] --> V
  L["FR-02-061<br/>Di trú APIM cũ"] --> V
  V --> E["FR-02-014<br/>Sửa khi còn nháp"]
  V --> R["FR-02-012<br/>Đồng bộ lại từ URL"]
  V --> C["Nhóm C<br/>Kiểm tra đặc tả"]
```

Hình trên cho thấy bốn con đường vào đều quy về một phiên bản `DRAFT` có đặc tả; từ đó mới sang kiểm tra, nên chất lượng đặc tả được bảo đảm ở một chỗ duy nhất bất kể API đến từ đâu.

#### FR-02-010 · Đăng ký API mới bằng trình hướng dẫn

::: dac-ta
**Mục đích.** Giúp chủ dịch vụ đưa một API mới vào danh mục qua năm bước có hướng dẫn: thông tin, đặc tả, kiểm tra và xem trước, backend và gói, rà soát. Bước nào chưa đạt thì chưa cho đi tiếp, để API vào danh mục luôn có đủ hợp đồng, thay cho kiểu "nhập tên, context-path, URL backend rồi chạy ngay" của hệ cũ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-002; LGC-APIM-004; SRS cũ FR-02-001.

**Tiền điều kiện.** HTTT cung cấp `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; loại API được tenant bật.

**Kích hoạt.** Người dùng bấm "+ Đăng ký API" ở UI-02-01, mở UI-02-03 (`/ket-noi/api/moi`).

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-010 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Người dùng nhập bước 1 "Thông tin": mã API, tên, mô tả, HTTT cung cấp, đơn vị chủ quản, nhóm, mức phân loại, số phiên bản đầu (mặc định `1.0.0`).
2. Hệ thống kiểm tra mã theo mẫu và chưa dùng kể cả mã đã xóa (sai mẫu: ERR-02-003; trùng: ERR-02-002), HTTT cung cấp `ACTIVE` ở PH-01 (ERR-02-004), người dùng thuộc tổ chức chủ quản (ERR-02-014) và `stateSecret` khác `true` (ERR-02-016).
3. Ở bước 2 "Đặc tả", người dùng chọn một trong ba cách nạp (FR-02-011); hệ thống kiểm tra trực tiếp khi nhập (FR-02-019) và hiển thị danh sách thao tác tìm thấy.
4. Ở bước 3 "Kiểm tra và xem trước", hệ thống chạy kiểm tra lớp 1, lớp 2, quét bí mật (FR-02-016…018) và phát hiện API trùng chức năng (FR-02-020); người dùng chỉ đi tiếp khi không còn lỗi mức `ERROR`.
5. Ở bước 4 "Backend và gói", người dùng khai ít nhất một backend và một gói (FR-02-022, 027); người dùng có thể bỏ qua rồi quay lại sau, API ở `DRAFT` không bị chặn.
6. Ở bước 5 "Rà soát", hệ thống hiển thị bản xem trước mục danh mục; người dùng chọn "Lưu nháp" hoặc "Lưu và gửi duyệt" (FR-02-034).
7. Hệ thống tạo API và phiên bản đầu ở trạng thái `DRAFT`, lưu đặc tả, đặt `origin`, ghi kiểm toán, trả chi tiết API.

**Luồng thay thế.** "Lưu và gửi duyệt" gộp bước 7 với FR-02-034 trong một giao dịch; nếu gửi duyệt không đạt điều kiện, API vẫn được lưu `DRAFT` và hiển thị các điều kiện còn thiếu (ERR-02-012). Người dùng thoát giữa chừng: bản nháp của trình hướng dẫn được giữ 7 ngày ở trình duyệt và ở máy chủ (không tạo API).

**Luồng ngoại lệ.**

- Mã API đã dùng: ERR-02-002 (409); "Mã {mã} đã được dùng (kể cả API đã xóa). Chọn mã khác."
- HTTT cung cấp không `ACTIVE`: ERR-02-004 (422); "HTTT {mã} chưa được kết nạp hoặc không ở trạng thái hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước."
- Dữ liệu thuộc bí mật nhà nước: ERR-02-016 (422); "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub."
- Đặc tả vượt kích thước: ERR-02-009 (413); "Đặc tả vượt {n} MiB. Rút gọn hoặc tách thành nhiều API."
- Người dùng không thuộc tổ chức chủ quản của HTTT: ERR-02-014 (403); "Bạn không thuộc đơn vị chủ quản của HTTT này."

**Đầu ra.** `201`, tiêu đề `Location`, `ETag`; chi tiết API và phiên bản `DRAFT`: `apiCode`, `versionNo`, `status = DRAFT`, `specId`, kết quả kiểm tra tóm tắt, `allowedActions[]`.

**Kết quả.** Chủ dịch vụ có một API ở bản nháp với đặc tả đã được kiểm tra, sẵn sàng khai backend, gói rồi gửi duyệt.

**Hậu điều kiện.** API và phiên bản `DRAFT` được tạo; đặc tả lưu ở kho đối tượng, băm lưu ở CSDL; chưa có route ở gateway.

**Sự kiện phát ra.** EVT-02-01 (`api.registered`).

**Kiểm toán.** Có: mã API, HTTT cung cấp, đơn vị chủ quản, `dataClass`, `origin`, băm đặc tả.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-007; BR-02-021; BR-02-022; BR-02-028; BR-02-032.

**Màn hình, API.** UI-02-03 bước 1…5; API-02-014.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `apiCode` | T-CODE | Có | `^[a-z][a-z0-9-]{2,62}$`, duy nhất trong tenant kể cả đã xóa | `tra-cuu-ho-tich` |
| `name` | T-NAME | Có | 5…255 ký tự | `Tra cứu thông tin hộ tịch` |
| `description` | T-TEXT | Có | 20…4000 ký tự, tiếng Việt (công khai theo CMP-LAW-03) | `Tra cứu giấy khai sinh theo số định danh…` |
| `providerSystemCode` | T-CODE | Có | HTTT `ACTIVE` ở PH-01 | `HT-TUPHAP` |
| `ownerOrgCode` | T-CODE | Có | Tổ chức của HTTT cung cấp | `SO-TUPHAP` |
| `categoryCode` | T-CODE | Có | Có trong bộ phân loại | `ho-tich` |
| `dataClass` | T-ENUM | Có | `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` | `RESTRICTED` |
| `stateSecret` | T-BOOL | Có | Phải `false` | `false` |
| `containsPersonalData` | T-BOOL | Có | Khi `true` cần `legalBasis` | `true` |
| `visibility` | T-ENUM | Không | `TENANT` (mặc định), `NATIONAL`, `PUBLIC`; ràng buộc theo `dataClass` | `TENANT` |
| `versionNo` | T-TEXT | Không | `MAJOR.MINOR.PATCH`, mặc định `1.0.0` | `1.0.0` |
| `spec` | tệp, T-TEXT hoặc T-URI | Có | Theo FR-02-011 | |

: Dữ liệu vào của FR-02-010

#### FR-02-011 · Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL

::: dac-ta
**Mục đích.** Cho chủ dịch vụ đưa đặc tả OpenAPI vào phiên bản theo cách tiện nhất: tải tệp YAML hoặc JSON, dán nội dung, hoặc trỏ tới địa chỉ URL của đặc tả (Swagger, OpenAPI đã công bố sẵn). Hỗ trợ cả đặc tả Swagger 2.0 (chuyển sang 3.1) để chủ dịch vụ không phải viết lại từ đầu.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-003; SRS cũ FR-02-003.

**Tiền điều kiện.** Phiên bản ở `DRAFT` (hoặc đang ở bước 2 của trình hướng dẫn FR-02-010).

**Kích hoạt.** Người dùng chọn "Tải tệp", "Dán nội dung" hoặc "Nhập từ URL" ở bước 2 của UI-02-03, hoặc ở tab Phiên bản của UI-02-02.

**Đầu vào.** `source` (`UPLOAD`, `PASTE`, `URL`); `file` (≤ 10 MiB) hoặc `content` hoặc `url`; `autoRefresh` (T-BOOL, chỉ với URL).

**Luồng xử lý chính.**

1. Người dùng chọn cách nạp và cung cấp nội dung; hệ thống kiểm tra kích thước ≤ 10 MiB (ERR-02-009) và kiểu tệp theo nội dung (Tika), chỉ nhận YAML, JSON (SEC-45).
2. Với URL: hệ thống kiểm tra địa chỉ là `https`, không trỏ tới địa chỉ nội bộ hay vùng link-local, đích có trong danh sách egress của tenant (SEC-16, ERR-02-010), rồi tải với thời gian chờ 15 giây và tối đa 3 lần chuyển hướng.
3. Hệ thống phân tích cú pháp với bộ phân tích an toàn (giới hạn alias YAML, độ sâu, không giải tham chiếu ngoài ra Internet); sai cú pháp thì trả ERR-02-005 kèm dòng, cột.
4. Nếu là Swagger 2.0 hoặc OpenAPI 3.0, hệ thống chuyển sang 3.1 và ghi `x-datahub-converted-from`; thông báo cho người dùng các điểm không chuyển được.
5. Hệ thống gộp tham chiếu ngoài hợp lệ, tính `sha256`, lưu đặc tả vào kho đối tượng và gắn với phiên bản (thay đặc tả cũ của bản nháp).
6. Hệ thống liệt kê thao tác tìm thấy, chạy kiểm tra không lưu (FR-02-019) và trả kết quả để người dùng xem ngay.

**Luồng thay thế.** Người dùng bật `autoRefresh` với URL: hệ thống đặt lịch đồng bộ lại theo FR-02-012. Người dùng dán đặc tả thiếu `servers`: hệ thống chấp nhận, vì địa chỉ công bố do gateway quyết định (FR-02-005).

**Luồng ngoại lệ.**

- URL không truy cập được hoặc không cho phép: ERR-02-010 (422); "Không tải được đặc tả từ địa chỉ này (địa chỉ không nằm trong danh sách cho phép hoặc không phản hồi)."
- Sai cú pháp: ERR-02-005 (422); "Đặc tả sai cú pháp ở dòng {n}, cột {m}: {mô tả}."
- Quá lớn: ERR-02-009 (413); "Đặc tả vượt 10 MiB."
- Phiên bản không còn `DRAFT`: ERR-02-038 (409); "Phiên bản đã khóa. Tạo phiên bản mới để đổi đặc tả."
- Vượt số lần nạp URL mỗi giờ: ERR-02-036 (429); "Đã nạp quá số lần cho phép. Thử lại sau {n} phút."

**Đầu ra.** `200`; `specId`, `sha256`, `sizeBytes`, `openapiVersion`, `operationCount`, `converted`, tóm tắt kiểm tra `{errors, warnings, infos}`.

**Kết quả.** Đặc tả nằm trong phiên bản nháp, danh sách thao tác hiện ra, lỗi nếu có được chỉ rõ vị trí.

**Hậu điều kiện.** Đặc tả của phiên bản `DRAFT` được thay; kết quả kiểm tra cũ bị đánh dấu lỗi thời; bản chưa duyệt không giữ vĩnh viễn, nhưng bản đã nộp duyệt thì giữ (BR-02-014).

**Sự kiện phát ra.** Không (EVT-02-07 chỉ phát khi nguồn URL đổi, FR-02-012).

**Kiểm toán.** Có: nguồn nạp, URL (đã che tham số truy vấn), băm, kích thước.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-015; BR-02-014.

**Màn hình, API.** UI-02-03 bước 2; API-02-015.
:::

#### FR-02-012 · Đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi

::: dac-ta
**Mục đích.** Khi chủ dịch vụ nạp đặc tả từ URL (thường là địa chỉ Swagger của chính hệ thống), cho hệ thống định kỳ kiểm tra đặc tả nguồn có đổi không và báo, để đặc tả trong danh mục không lệch khỏi hệ thống thật.

**Tác nhân, quyền.** Hệ thống (lịch); SV (○), TA có `PERM-02-create` khi bấm "Đồng bộ ngay".

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-003 bước 4.

**Tiền điều kiện.** Đặc tả có `source = URL` và `autoRefresh = true`; phiên bản ở bất kỳ trạng thái nào trừ `RETIRED`.

**Kích hoạt.** Lịch mỗi `02.spec.url-refresh-hours` giờ (mặc định 24); hoặc người dùng bấm "Đồng bộ ngay".

**Đầu vào.** `apiCode`, `versionNo`; lịch không có đầu vào.

**Luồng xử lý chính.**

1. Hệ thống tải lại URL với các kiểm tra như FR-02-011 bước 2 và tính băm nội dung đã chuẩn hóa (bỏ khoảng trắng, sắp khóa).
2. Hệ thống so băm với bản đang lưu; trùng thì cập nhật `lastCheckedAt`, kết thúc.
3. Khác nhau thì hệ thống lưu bản mới như "đề xuất cập nhật" (không thay đặc tả đang dùng), tính khác biệt và phân loại phá vỡ (như FR-02-043).
4. Hệ thống phát EVT-02-07 và gửi thông báo cho chủ dịch vụ: "Đặc tả nguồn của {mã API} {phiên bản} đã thay đổi; có {n} thay đổi phá vỡ."
5. Với phiên bản `DRAFT`, chủ dịch vụ chọn "Áp dụng" (thay đặc tả, chạy lại kiểm tra) hoặc "Bỏ qua"; với phiên bản đã khóa (từ `PENDING`), hệ thống chỉ cảnh báo, hợp đồng đã duyệt không đổi, và đề nghị tạo phiên bản mới (FR-02-042).

**Luồng thay thế.** Nguồn không còn truy cập được: tăng bộ đếm lỗi; sau 3 lần liên tiếp ghi cảnh báo "Không đọc được đặc tả nguồn" cho chủ dịch vụ và tạm ngừng đồng bộ tự động.

**Luồng ngoại lệ.**

- URL bị chặn bởi egress hoặc trả lỗi: ERR-02-010 (422) khi bấm tay; "Không tải được đặc tả từ địa chỉ này."
- Đang có lần đồng bộ chạy: ERR-02-035 (409); "Đang đồng bộ, vui lòng chờ."
- Phiên bản `RETIRED`: ERR-02-011 (409).

**Đầu ra.** `202` (bấm tay) kèm `operationId`; kết quả: `unchanged`, hoặc `changed` kèm `diffSummary`, `breakingCount`.

**Kết quả.** Chủ dịch vụ được báo khi đặc tả nguồn đổi và quyết định áp dụng hay không.

**Hậu điều kiện.** `lastCheckedAt` cập nhật; có thể có một "đề xuất cập nhật" chờ chủ dịch vụ.

**Sự kiện phát ra.** EVT-02-07 (`version.spec-source-changed`).

**Kiểm toán.** Có khi áp dụng đề xuất (băm cũ, mới); lần kiểm tra không đổi không ghi kiểm toán.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-014.

**Màn hình, API.** UI-02-02 tab Phiên bản; API-02-016, API-02-095 (tiến độ tác vụ).
:::

#### FR-02-013 · Tự đăng ký API từ luồng REST của PH-04

::: dac-ta
**Mục đích.** Khi kỹ sư tích hợp phát hành một luồng ở PH-04 có điểm vào REST, API tương ứng tự có mặt trong danh mục với đặc tả sinh từ luồng, để mọi dịch vụ đều đi qua cùng quy trình công bố và danh mục không bỏ sót dịch vụ nào. Đây là chỗ thay cho "thông tin REST API của agent" ở Bus cũ.

**Tác nhân, quyền.** PH-04 (token dịch vụ, scope `catalog:flow-sync`); không có người dùng trực tiếp.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-BUS-028; PH-04 FR-04-052; EVT-04-02, 04, 07.

**Tiền điều kiện.** Luồng có `rest` DSL và đã được duyệt phát hành ở PH-04; HTTT cung cấp (HTTT sở hữu luồng) `ACTIVE`.

**Kích hoạt.** Sự kiện EVT-04-04 (`version.approved`) và EVT-04-07 (`deployment.status-changed` sang `SYNCED`) của PH-04 cho luồng có điểm vào REST.

**Đầu vào.** Sự kiện chứa `flowCode`, `versionNo`, môi trường, `restOperations[]` (phương thức, đường dẫn, mô tả, lược đồ yêu cầu, phản hồi), HTTT sở hữu; hệ thống đọc thêm đặc tả OpenAPI sinh từ luồng qua API nội bộ của PH-04.

**Luồng xử lý chính.**

1. Hệ thống nhận sự kiện và tra `flowRef` trong danh mục; chưa có thì tạo API mới với `origin = FLOW`, `apiCode` = mã luồng, `ownerOrgCode` theo HTTT sở hữu luồng, `dataClass` lấy từ nhãn phân loại của luồng (mặc định `INTERNAL`), `visibility = TENANT`.
2. Hệ thống đọc đặc tả OpenAPI do PH-04 sinh, chạy kiểm tra như FR-02-016…018; kết quả `ERROR` không chặn việc tạo nhưng chặn công bố.
3. Hệ thống tạo phiên bản `DRAFT` (hoặc cập nhật phiên bản `DRAFT` có sẵn) với backend loại `FLOW` trỏ tới điểm vào của luồng ở môi trường tương ứng.
4. Hệ thống gắn nhãn "Sinh từ luồng", khóa phần hợp đồng (đường dẫn, lược đồ) không sửa tay (BR-02-030), chỉ cho sửa mô tả, phân loại, gói, SLA.
5. Hệ thống tạo việc cho SV của tổ chức chủ quản: "API sinh từ luồng {mã} cần hoàn thiện mô tả và gói, rồi gửi duyệt."
6. Khi luồng đổi hợp đồng ở phiên bản sau, hệ thống tạo phiên bản API mới tương ứng (theo số chính); khi luồng bị gỡ (EVT-04-*), hệ thống đánh dấu phiên bản "mất backend" và báo cho chủ dịch vụ (không tự ngừng).

**Luồng thay thế.** Luồng chỉ phát hành ở TEST: hệ thống tạo API nháp nhưng không cho gửi duyệt cho tới khi luồng có phiên bản ở môi trường thật.

**Luồng ngoại lệ.**

- Mã luồng trùng một API nhập tay có sẵn: ERR-02-002 (409) ghi nhật ký; việc đề nghị liên kết thủ công được tạo cho TA: "API {mã} đã có, chọn Liên kết với luồng hoặc đổi mã."
- Không đọc được đặc tả từ PH-04: ERR-02-034 (503); thử lại 3 lần lùi mũ rồi đưa vào hàng chờ, cảnh báo TO.
- Luồng chưa có HTTT sở hữu: ERR-02-004 (422), sự kiện chuyển vào hàng "chờ xử lý", TA nhận việc gán HTTT.

**Đầu ra.** Không có phản hồi người dùng; kết quả xử lý: API và phiên bản `DRAFT` được tạo hoặc cập nhật; cập nhật `flowSyncStatus` (`SYNCED`, `PENDING_OWNER`, `ERROR`).

**Kết quả.** Luồng REST của PH-04 xuất hiện trong danh mục như một API, đi cùng quy trình công bố như mọi API.

**Hậu điều kiện.** API `origin = FLOW` có phiên bản `DRAFT` kèm backend `FLOW`; chưa có route ở gateway cho tới khi công bố.

**Sự kiện phát ra.** EVT-02-01, EVT-02-02.

**Kiểm toán.** Có: chủ thể là tài khoản dịch vụ PH-04, mã luồng, phiên bản luồng, băm đặc tả.

**Quy tắc nghiệp vụ.** BR-02-030; BR-02-001; BR-02-023.

**Màn hình, API.** UI-02-02 (nhãn "Sinh từ luồng"); API-02-017 (nội bộ).
:::

#### FR-02-014 · Sửa thông tin API và đặc tả khi còn bản nháp

::: dac-ta
**Mục đích.** Cho chủ dịch vụ chỉnh thông tin và đặc tả trong lúc bản nháp, và chỉ sửa được phần an toàn sau khi đã công bố, để hợp đồng đã duyệt không bị đổi ngầm.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-002; Q02-03.

**Tiền điều kiện.** API tồn tại, người dùng thuộc tổ chức chủ quản (hoặc là TA).

**Kích hoạt.** Người dùng bấm "Sửa" ở UI-02-02 hoặc sửa các trường ở UI-02-03.

**Đầu vào.** Các trường như bảng dữ liệu vào của FR-02-010 (trừ `apiCode`, `providerSystemCode`); `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống nạp API kèm `ETag`; kiểm tra người dùng thuộc tổ chức chủ quản (BR-02-032).
2. Hệ thống xác định tập trường được sửa theo trạng thái của phiên bản đang chọn: `DRAFT` sửa mọi trường trừ mã; `PENDING` không sửa (ERR-02-038); `PUBLISHED`, `SUSPENDED`, `DEPRECATED` chỉ sửa mô tả, thẻ, đầu mối, thông tin SLA, mô tả thao tác; `RETIRED` không sửa.
3. Hệ thống kiểm tra thay đổi theo từng trường (như FR-02-007, FR-02-010) và ETag (ERR-02-015).
4. Với API `origin = FLOW`, hệ thống từ chối sửa trường hợp đồng (BR-02-030).
5. Hệ thống lưu, tăng `version`, ghi kiểm toán giá trị trước và sau; nếu đặc tả `DRAFT` đổi thì đánh dấu kết quả kiểm tra lỗi thời và yêu cầu kiểm tra lại trước khi gửi duyệt.

**Luồng thay thế.** Hai người sửa cùng lúc: người lưu sau nhận cảnh báo xung đột và xem khác biệt (FR-00-052).

**Luồng ngoại lệ.**

- Sửa trường hợp đồng của phiên bản đã công bố: ERR-02-011 (409); "Phiên bản đã công bố không sửa được đặc tả. Tạo phiên bản mới."
- `ETag` lệch: ERR-02-015 (412); "Thông tin vừa được người khác thay đổi. Tải lại để xem."
- Phiên bản đang chờ duyệt: ERR-02-038 (409).
- Sửa API sinh từ luồng: ERR-02-011 (409); "Phần hợp đồng của API này sinh từ luồng, hãy sửa ở PH-04."

**Đầu ra.** `200`, `ETag` mới; API sau cập nhật.

**Kết quả.** Thông tin API được cập nhật; người dùng biết trường nào không sửa được và lý do.

**Hậu điều kiện.** Bản ghi cập nhật; kết quả kiểm tra đặc tả (nếu đặc tả đổi) đánh dấu lỗi thời.

**Sự kiện phát ra.** EVT-02-02.

**Kiểm toán.** Có: các trường đổi, giá trị trước và sau (che trường Hạn chế).

**Quy tắc nghiệp vụ.** BR-02-014; BR-02-021; BR-02-030; BR-02-032.

**Màn hình, API.** UI-02-02, UI-02-03; API-02-018.
:::

#### FR-02-015 · Cung cấp mẫu đặc tả và quy ước viết API

::: dac-ta
**Mục đích.** Giúp chủ dịch vụ ít kinh nghiệm viết được đặc tả đạt lớp 2 ngay lần đầu, bằng mẫu OpenAPI mẫu tải về và tài liệu quy ước đặt tên, mã lỗi, phân trang. Đây là điều kiện nghiệm thu của SRS cũ (mẫu và hướng dẫn đã công bố).

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read`.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; FR-00-033; SRS cũ M10.3 điều kiện 7, 8.

**Tiền điều kiện.** Không.

**Kích hoạt.** Người dùng bấm "Tải mẫu đặc tả" hoặc "Xem quy ước" ở bước 2 của UI-02-03.

**Đầu vào.** `kind` (`rest-get`, `rest-crud`, `async-callback`), `lang` (`vi`).

**Luồng xử lý chính.**

1. Người dùng chọn loại mẫu; hệ thống chọn tệp mẫu OpenAPI 3.1 đã qua bộ kiểm tra của chính nền tảng.
2. Hệ thống điền sẵn tên tenant, tiền tố đường dẫn, khối `components` (lỗi RFC 9457, phân trang `page`, `size`), mã lỗi bắt buộc `400`, `401`, `403`, `404`, `429`, `500`, phạm vi mẫu `api:{mã API}:{mã gói}`.
3. Hệ thống trả tệp và liên kết tới trang quy ước (đặt tên `operationId`, đường dẫn danh từ số nhiều, mô tả tiếng Việt, ví dụ bắt buộc, không dữ liệu thật).
4. Nội dung quy ước lấy từ bộ luật hiện hành (FR-02-021) để quy ước và kiểm tra không lệch nhau.

**Luồng thay thế.** Tải "bộ luật kiểm tra" dạng bảng để kỹ sư tham khảo.

**Luồng ngoại lệ.**

- Loại mẫu không có: ERR-02-003 (400); "Loại mẫu không hợp lệ."
- Kho mẫu không đọc được: ERR-02-034 (503); "Không tải được mẫu. Thử lại sau."

**Đầu ra.** `200`; tệp mẫu YAML kèm `Content-Disposition`; hoặc trang quy ước (HTML) ở giao diện.

**Kết quả.** Chủ dịch vụ có mẫu đúng quy ước để bắt đầu.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-02-002.

**Màn hình, API.** UI-02-03 bước 2; API-02-019.
:::

### 6.4. Nhóm C · Kiểm tra đặc tả

Đặc tả OpenAPI là hợp đồng, nên một đặc tả hợp lệ về cú pháp vẫn có thể vô dụng nếu thiếu mô tả, thiếu ví dụ, thiếu mã lỗi hoặc chứa khóa thật. Nhóm C kiểm tra ba lớp: **lớp 1** theo chuẩn OpenAPI 3.1, **lớp 2** theo quy ước nền tảng (15 luật `LINT-02-nn`), và **quét bí mật** (9 mẫu `SCAN-02-nn`). Kết quả mỗi phát hiện có mã luật, vị trí dạng JSONPath và hướng dẫn sửa, để chủ dịch vụ không phải đoán. Hình dưới cho thấy các lớp kiểm tra và điểm chặn.

```{.mermaid caption="Các lớp kiểm tra đặc tả và điểm chặn"}
flowchart TB
  S["Đặc tả đã nạp"] --> L1["FR-02-016<br/>Lớp 1: chuẩn OpenAPI"]
  L1 -->|"ERROR"| X["Chặn<br/>không gửi duyệt"]
  L1 -->|"Đạt"| L2["FR-02-017<br/>Lớp 2: quy ước nền tảng"]
  L2 -->|"ERROR"| X
  L2 -->|"Đạt hoặc WARNING"| Q["FR-02-018<br/>Quét bí mật, DLCN thật"]
  Q -->|"Phát hiện"| X
  Q -->|"Sạch"| D["FR-02-020<br/>Phát hiện trùng chức năng"]
  D --> OK["Đủ điều kiện gửi duyệt<br/>FR-02-034"]
  P["FR-02-019<br/>Kiểm tra không lưu"] -.-> L1
```

Hình trên cho thấy ba lớp kiểm tra nối tiếp và ba điểm chặn; chỉ khi cả ba lớp qua thì phiên bản mới đủ điều kiện gửi duyệt. Kiểm tra không lưu dùng chung bộ luật nhưng không ghi dữ liệu.

#### FR-02-016 · Kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1

::: dac-ta
**Mục đích.** Bảo đảm đặc tả đúng chuẩn OpenAPI để mọi công cụ (gateway, cổng nhà phát triển, bộ sinh mã, PH-04) đọc được, trước khi bàn tới quy ước riêng của nền tảng. Lỗi lớp 1 luôn chặn.

**Tác nhân, quyền.** Hệ thống (tự chạy sau FR-02-011, 014); SV (○), TA có `PERM-02-create` khi bấm "Kiểm tra lại".

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-003; SRS cũ FR-02-002 lớp 1.

**Tiền điều kiện.** Phiên bản có đặc tả (FR-02-011).

**Kích hoạt.** Sau khi nạp hoặc sửa đặc tả; khi gửi duyệt (FR-02-034 kiểm tra lại); khi người dùng bấm "Kiểm tra lại".

**Đầu vào.** `apiCode`, `versionNo`; không có trường nhập thêm.

**Luồng xử lý chính.**

1. Hệ thống đọc đặc tả từ kho đối tượng, kiểm tra băm khớp bản ghi.
2. Hệ thống kiểm tra cú pháp YAML hoặc JSON và phiên bản `openapi` là `3.1.x` (`OAS-SYNTAX`, `OAS-VERSION`).
3. Hệ thống kiểm tra theo lược đồ JSON của OpenAPI 3.1: trường bắt buộc `info`, `paths` hoặc `webhooks`; kiểu giá trị; `operationId` không trùng; tham số đường dẫn khớp khuôn đường dẫn (`OAS-SCHEMA`, `OAS-DUP-PATH`, `OAS-PARAM-PATH-MISMATCH`).
4. Hệ thống giải mọi `$ref` nội bộ và ngoại tuyến đã gộp; tham chiếu không giải được là lỗi (`OAS-REF-UNRESOLVED`); phát hiện tham chiếu vòng chỉ cảnh báo.
5. Hệ thống ghi từng phát hiện mức `ERROR` vào kết quả kiểm tra (lớp `STANDARD`) kèm vị trí JSONPath, mô tả và hướng dẫn; cập nhật tóm tắt `{errors, warnings, infos}` của phiên bản.

**Luồng thay thế.** Đặc tả quá lớn (trên 5.000 thao tác): kiểm tra theo lô, trả kết quả khi xong và hiện tiến độ (FR-00-054).

**Luồng ngoại lệ.**

- Có lỗi lớp 1: kết quả `valid = false`; màn hình báo "Đặc tả còn {n} lỗi. Sửa các lỗi dưới đây rồi kiểm tra lại." Nút "Gửi duyệt" bị khóa; gọi FR-02-034 trả ERR-02-006 (422).
- Đặc tả không đọc được: ERR-02-005 (422); "Đặc tả sai cú pháp ở dòng {n}, cột {m}."
- Đang có lần kiểm tra khác chạy: ERR-02-035 (409); "Đang kiểm tra, vui lòng chờ."
- Vượt số lần kiểm tra mỗi giờ: ERR-02-036 (429); "Đã kiểm tra quá số lần cho phép. Thử lại sau {n} phút."

**Đầu ra.** `200`; `valid`, `summary {errors, warnings, infos}`, `findings[]` (`layer`, `severity`, `ruleId`, `location`, `message`, `hint`), `checkedAt`, `specSha256`.

**Kết quả.** Chủ dịch vụ biết đặc tả có đúng chuẩn không và sửa đúng vị trí.

**Hậu điều kiện.** Kết quả kiểm tra lớp `STANDARD` của đặc tả được ghi; phát hiện cũ đã sửa được đánh dấu `resolved` thay vì xóa.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có mức tóm tắt (kết quả, số lỗi, người chạy); chi tiết phát hiện nằm ở bảng kết quả.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-014.

**Màn hình, API.** UI-02-04; API-02-020, API-02-021.
:::

#### FR-02-017 · Kiểm tra đặc tả lớp 2: quy ước nền tảng

::: dac-ta
**Mục đích.** Bắt buộc đặc tả đạt mức "dùng được" cho cán bộ kỹ thuật các sở: mô tả tiếng Việt, mã lỗi đầy đủ, ví dụ, đường dẫn đúng quy ước, khai báo bảo mật. Luật nghiêm trọng chặn gửi duyệt, luật mức cảnh báo cho đi tiếp nhưng hiển thị ở danh mục.

**Tác nhân, quyền.** Hệ thống; SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-002 lớp 2; BR-02-002.

**Tiền điều kiện.** Đặc tả đạt lớp 1 (nếu lớp 1 còn lỗi, chỉ chạy các luật không phụ thuộc cấu trúc).

**Kích hoạt.** Ngay sau FR-02-016, khi gửi duyệt, và khi bấm "Kiểm tra lại".

**Đầu vào.** `apiCode`, `versionNo`; cấu hình luật của tenant (FR-02-021).

**Luồng xử lý chính.**

1. Hệ thống nạp bộ luật hiệu lực của tenant (mặc định nền tảng cộng điều chỉnh của tenant).
2. Hệ thống chạy từng luật trong bảng luật lớp 2 dưới đây trên cây đặc tả, mỗi luật sinh phát hiện có mức, vị trí, hướng dẫn.
3. Hệ thống đối chiếu ngữ cảnh API: `dataClass`, kiểu xác thực của gói (LINT-02-08), số chính của phiên bản với đường dẫn (LINT-02-14).
4. Hệ thống tổng hợp: có phát hiện `ERROR` thì phiên bản chưa đủ điều kiện gửi duyệt; chỉ có `WARNING` thì được gửi duyệt và cảnh báo hiển thị ở UI-02-02 và ở bước duyệt.
5. Hệ thống ghi phát hiện vào kết quả kiểm tra lớp `CONVENTION`.

**Luồng thay thế.** Chủ dịch vụ có lý do chính đáng cho một cảnh báo (ví dụ API thật sự không có ví dụ): bấm "Chấp nhận cảnh báo" kèm lý do; phát hiện chuyển `ACKNOWLEDGED`, người duyệt thấy lý do. Luật mức `ERROR` không cho chấp nhận.

**Luồng ngoại lệ.**

- Còn phát hiện `ERROR` khi gửi duyệt: ERR-02-007 (422); "Đặc tả còn {n} lỗi theo quy ước nền tảng. Mở kết quả kiểm tra để xem hướng dẫn sửa."
- Luật cấu hình sai (không giải được): bỏ qua luật đó, ghi nhật ký, cảnh báo TA; ERR-02-034 chỉ khi bộ luật không nạp được.
- Chấp nhận cảnh báo không có lý do: ERR-02-041 (400); "Cần nêu lý do chấp nhận cảnh báo."

**Đầu ra.** `200`; như FR-02-016 với `layer = CONVENTION`; mỗi phát hiện có `ruleId`, `severity`, `status` (`OPEN`, `RESOLVED`, `ACKNOWLEDGED`), `hint`, đường dẫn tài liệu quy ước.

**Kết quả.** Chủ dịch vụ thấy ngay đặc tả thiếu gì theo quy ước và cách sửa; người duyệt thấy mức chất lượng của đặc tả.

**Hậu điều kiện.** Kết quả kiểm tra lớp `CONVENTION` được ghi.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có mức tóm tắt; việc chấp nhận cảnh báo ghi kèm lý do và người chấp nhận.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-002; BR-02-016 (LINT-02-08).

**Màn hình, API.** UI-02-04; API-02-020, API-02-021, API-02-092 (chấp nhận cảnh báo kèm lý do).
:::

| Mã luật | Mức mặc định | Nội dung kiểm tra | Điều chỉnh ở tenant |
|---|---|---|---|
| LINT-02-01 | `ERROR` | Mọi thao tác có `operationId` duy nhất, dạng `camelCase`, bắt đầu bằng động từ (`getCivilRecord`) | Không |
| LINT-02-02 | `ERROR` thiếu; `WARNING` sai ngôn ngữ | Mọi thao tác có `summary` và `description` bằng tiếng Việt có dấu; tỷ lệ ký tự có dấu quá thấp thì cảnh báo | Hạ mức cảnh báo được |
| LINT-02-03 | `ERROR` | Khai báo đủ mã lỗi `401`, `403`, `429`, `500` cho mọi thao tác, thêm `400` khi có đầu vào, `404` khi đường dẫn có tham số | Không |
| LINT-02-04 | `ERROR` | Phản hồi lỗi dùng `application/problem+json` theo RFC 9457 (có `type`, `title`, `status`, `detail`, `traceId`) | Không |
| LINT-02-05 | `WARNING` | Mọi tham số và thuộc tính của lược đồ có `description` | Nâng lên `ERROR` được |
| LINT-02-06 | `WARNING` | Mọi yêu cầu và phản hồi thành công có `example` hoặc `examples` | Nâng lên `ERROR` được |
| LINT-02-07 | `ERROR` | Đường dẫn chữ thường, gạch ngang, danh từ số nhiều, không động từ, không kết thúc bằng `/` | Không |
| LINT-02-08 | `ERROR` | Mọi thao tác khai `security` và phạm vi cần thiết; kiểu khai báo phải phù hợp mức phân loại (BR-02-016); thao tác công khai chỉ với API `PUBLIC` | Không |
| LINT-02-09 | `ERROR` | Thao tác trả danh sách có tham số `page`, `size` (tối đa 200) và trả `totalElements` | Không |
| LINT-02-10 | `WARNING` | Dùng kiểu chuẩn: thời điểm `format: date-time`, ngày `format: date`, tiền VND `integer` `int64`; tên trường khác kiểu với từ điển dữ liệu dùng chung | Nâng lên `ERROR` được |
| LINT-02-11 | `ERROR` | Thao tác `POST` khai tiêu đề `Idempotency-Key`; thao tác ghi khai `412`, `409` khi có `ETag` | Không |
| LINT-02-12 | `WARNING` | `info.contact` có đầu mối kỹ thuật; `info.version` khớp số phiên bản của API | Nâng lên `ERROR` được |
| LINT-02-13 | `ERROR` | `servers` không chứa địa chỉ IP, `localhost`, tên miền nội bộ hay đường dẫn kiểm thử | Không |
| LINT-02-14 | `ERROR` | Số chính trong đường dẫn (`/v2`) khớp số chính của phiên bản | Không |
| LINT-02-15 | `WARNING` | Trường chứa dữ liệu mức Hạn chế hoặc Nhạy cảm có `x-dh-classification`; API `SENSITIVE` mà không trường nào gắn thì cảnh báo | Nâng lên `ERROR` được |

: Bộ luật kiểm tra lớp 2

Ghi chú: các luật bảo mật và an toàn (LINT-02-01, 03, 04, 07, 08, 09, 11, 13, 14) mang tính cấu trúc và không hạ mức được ở tenant; tenant chỉ nâng cảnh báo thành lỗi hoặc, với LINT-02-02, hạ mức phần cảnh báo ngôn ngữ (FR-02-021).

#### FR-02-018 · Quét bí mật và dữ liệu cá nhân thật trong đặc tả

::: dac-ta
**Mục đích.** Ngăn lỗi phổ biến là để token, khóa, mật khẩu hay số định danh thật trong phần ví dụ của đặc tả rồi công bố công khai. Phát hiện được thì chặn trước khi đặc tả tới tay người duyệt.

**Tác nhân, quyền.** Hệ thống quét; SV (○) và TA đề nghị đánh dấu "không phải bí mật" (`PERM-02-create`, API-02-093); SO xác nhận hoặc bác đề nghị (`PERM-02-operate`, API-02-094) và không được là người đề nghị; SV, TA, SO xem kết quả (`PERM-02-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ NFR-02-017, BR-02-015; CMP-LAW-05; SEC-32.

**Tiền điều kiện.** Phiên bản có đặc tả.

**Kích hoạt.** Cùng lúc FR-02-016, 017; luôn chạy lại khi gửi duyệt và khi duyệt.

**Đầu vào.** Nội dung đặc tả; danh sách miền ví dụ được phép (`example.com`, `example.gov.vn`, `*.example`).

**Luồng xử lý chính.**

1. Hệ thống quét toàn bộ giá trị chuỗi của đặc tả (`example`, `examples`, `default`, `enum`, `description`, `servers`, `x-*`) với các mẫu trong bảng dưới.
2. Mỗi giá trị khớp mẫu và không phải giá trị giữ chỗ hợp lệ (`{token}`, `<API_KEY>`, `***`, `xxxx`) sinh một phát hiện `ERROR` lớp `SECRET`; chuỗi khớp **không** được ghi vào kết quả, chỉ ghi vị trí, mã mẫu và 4 ký tự cuối đã che.
3. Hệ thống đánh giá entropy của các chuỗi dài ≥ 20 ký tự trong trường tên chứa `key`, `token`, `secret`, `password`, nghi ngờ khi entropy cao hơn ngưỡng.
4. Phiên bản có phát hiện `ERROR` lớp `SECRET` không gửi duyệt, không duyệt, không công bố được (BR-02-015); hệ thống gửi cảnh báo cho SV và, nếu mẫu là khóa riêng hoặc token còn hiệu lực nghi ngờ, cho SO để xử lý như lộ lọt.
5. Chủ dịch vụ thay giá trị bằng giá trị giữ chỗ rồi kiểm tra lại; phát hiện đã sửa chuyển `RESOLVED`.

**Luồng thay thế.** Phát hiện nhầm (ví dụ chuỗi ngẫu nhiên hợp lệ như mã tham chiếu mẫu): chủ dịch vụ đề nghị "Đánh dấu không phải bí mật" kèm lý do; SO xác nhận (`PERM-02-operate`) thì phát hiện chuyển `ACKNOWLEDGED` cho đúng giá trị đó.

**Luồng ngoại lệ.**

- Phát hiện bí mật: ERR-02-008 (422); "Đặc tả có giá trị giống khóa hoặc dữ liệu cá nhân thật tại {vị trí}. Thay bằng giá trị giữ chỗ rồi kiểm tra lại."
- Đặc tả sạch nhưng bộ quét lỗi: ERR-02-034 (503); "Chưa quét được bí mật, tạm không gửi duyệt được." (không bao giờ cho qua khi quét lỗi.)

**Đầu ra.** `200`; `findings[]` lớp `SECRET` (`ruleId = SCAN-02-nn`, `location`, `maskedTail`, `status`).

**Kết quả.** Đặc tả được công bố chắc chắn không chứa khóa hay dữ liệu cá nhân thật ở phần ví dụ.

**Hậu điều kiện.** Kết quả quét ghi vào bảng kết quả kiểm tra; không lưu chuỗi khớp.

**Sự kiện phát ra.** Không (cảnh báo qua trung tâm thông báo FR-00-060 cho SV, SO).

**Kiểm toán.** Có: số phát hiện theo mẫu, người xác nhận "không phải bí mật" và lý do; không ghi giá trị.

**Quy tắc nghiệp vụ.** BR-02-015; BR-02-007.

**Màn hình, API.** UI-02-04; API-02-020, API-02-021, API-02-093 (đề nghị không phải bí mật), API-02-094 (SO xác nhận).
:::

| Mã mẫu | Mẫu nhận diện | Ví dụ minh họa (đã làm sai) |
|---|---|---|
| SCAN-02-01 | Khóa riêng dạng PEM (`-----BEGIN … PRIVATE KEY-----`) | Khối PEM đầy đủ |
| SCAN-02-02 | JWT thật: ba đoạn base64url, đoạn đầu giải được thành JSON có `alg` | `eyJhbGciOi…` |
| SCAN-02-03 | Khóa truy cập đám mây và nền tảng phổ biến (tiền tố `AKIA…`, `ghp_…`, `xox…`) | `AKIA…` |
| SCAN-02-04 | Tiêu đề `Authorization: Bearer` hoặc `Basic` kèm giá trị dài hơn 20 ký tự không phải giữ chỗ | `Bearer 7f3a…` |
| SCAN-02-05 | Mật khẩu hoặc khóa trong URL (`scheme://user:pass@host`) hoặc trong tham số truy vấn (`?apikey=`, `?token=`) | `https://u:p@host` |
| SCAN-02-06 | Trường tên `password`, `secret`, `apiKey`, `clientSecret` có giá trị không phải giữ chỗ | `"password": "Abc@1234"` |
| SCAN-02-07 | Số định danh cá nhân 12 chữ số hợp lệ cấu trúc (CCCD) | `0790…` |
| SCAN-02-08 | Số điện thoại di động Việt Nam hợp lệ (`+84` hoặc `0` kèm đầu số nhà mạng) | `09xx…` |
| SCAN-02-09 | Địa chỉ thư điện tử không thuộc miền ví dụ cho phép | `nguyenvana@…` |

: Mẫu quét bí mật và dữ liệu cá nhân thật

#### FR-02-019 · Kiểm tra đặc tả không lưu (xem trước khi gõ)

::: dac-ta
**Mục đích.** Cho chủ dịch vụ thấy kết quả kiểm tra ngay khi đang gõ hoặc dán đặc tả, không phải lưu bản nháp trước, để sửa nhanh nhiều vòng. Cũng là cổng để công cụ ngoài (CI của nhà thầu) tự kiểm tra đặc tả trước khi nộp.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`; CI của nhà thầu bằng token người dùng.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ API `validate-spec`.

**Tiền điều kiện.** Người dùng đã đăng nhập và có `PERM-02-create`.

**Kích hoạt.** Trình soạn thảo ở UI-02-03 gọi sau 800 ms ngừng gõ; hoặc lệnh gọi API từ công cụ ngoài.

**Đầu vào.** `content` (T-TEXT tới 10 MiB, hoặc tệp), `dataClass` (để áp luật LINT-02-08, tùy chọn), `versionMajor` (tùy chọn, cho LINT-02-14).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra kích thước và kiểu nội dung (ERR-02-009, ERR-02-005).
2. Hệ thống chạy lớp 1, lớp 2 và quét bí mật như FR-02-016…018 nhưng không ghi vào CSDL, không lưu đặc tả, không lưu chuỗi khớp.
3. Hệ thống áp giới hạn tần suất 60 lần mỗi giờ mỗi người dùng (tham số `02.lint.max-per-hour`) và giới hạn 5 giây xử lý.
4. Hệ thống trả kết quả có cấu trúc `{valid, summary, findings[]}` và cờ `canContinue` (không còn `ERROR`).

**Luồng thay thế.** Công cụ ngoài gửi `Accept: application/sarif+json` thì nhận kết quả định dạng SARIF để hiển thị trong CI.

**Luồng ngoại lệ.**

- Vượt giới hạn tần suất: ERR-02-036 (429); "Đã kiểm tra quá nhiều lần. Thử lại sau {n} giây."
- Quá lớn: ERR-02-009 (413); "Đặc tả vượt 10 MiB."
- Hết thời gian xử lý (đặc tả quá phức tạp): ERR-02-003 (400); "Đặc tả quá phức tạp để kiểm tra nhanh. Lưu bản nháp để kiểm tra nền."

**Đầu ra.** `200`; `valid`, `canContinue`, `summary`, `findings[]`.

**Kết quả.** Chủ dịch vụ sửa đặc tả ngay trên trình soạn thảo với kết quả kiểm tra tức thì.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không lưu nội dung; chỉ đếm số lần gọi ở chỉ số `catalog_spec_validation_total{result,mode="adhoc"}`.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-015.

**Màn hình, API.** UI-02-03 bước 2; UI-02-04; API-02-022.
:::

#### FR-02-020 · Phát hiện API trùng chức năng

::: dac-ta
**Mục đích.** Phát hiện sớm khi nhiều đơn vị cùng công bố những API gần giống nhau (ví dụ tra cứu thông tin công dân), để gom về một dịch vụ dùng chung đúng tinh thần tránh trùng lặp, lãng phí của kiến trúc chính phủ điện tử. Chỉ cảnh báo, người duyệt quyết định.

**Tác nhân, quyền.** Hệ thống; SV (○), CA, TA xem.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-005 bước 3; CMP-LAW-10 (nguyên tắc tránh trùng lặp).

**Tiền điều kiện.** Phiên bản có đặc tả đã đạt lớp 1.

**Kích hoạt.** Ở bước 3 của UI-02-03; khi gửi duyệt; khi mở màn duyệt (UI-02-10).

**Đầu vào.** `apiCode`, `versionNo`; ngưỡng `02.duplicate.threshold` (mặc định 0,8).

**Luồng xử lý chính.**

1. Hệ thống chuẩn hóa các cặp (phương thức, đường dẫn) của đặc tả thành khuôn (thay tham số đường dẫn bằng `{}`, bỏ tiền tố nhóm và số chính).
2. Hệ thống so với mọi API còn hiệu lực của tenant theo ba độ đo: tỷ lệ khuôn trùng, độ tương đồng văn bản của mô tả (TF-IDF, cosine) và độ trùng của tên trường phản hồi (Jaccard).
3. Hệ thống tính điểm tổng hợp, giữ các API có điểm từ ngưỡng trở lên (tối đa 5), kèm lý do (khuôn trùng, từ khóa chung, trường chung).
4. Hệ thống hiển thị danh sách ở bước 3 của trình hướng dẫn và ở màn duyệt, với liên kết mở API gần giống.
5. Người duyệt ghi nhận quyết định: "Khác nhau, vẫn công bố" (kèm lý do) hoặc "Gom về API có sẵn" (trả lại chủ dịch vụ).

**Luồng thay thế.** Chủ dịch vụ chủ động chọn "API này là phiên bản thay thế của API khác": bỏ cảnh báo với API đó.

**Luồng ngoại lệ.**

- Không có API gần giống: trả danh sách rỗng, không cảnh báo.
- Bộ so sánh chưa sẵn sàng: bỏ qua bước, ghi `skipped`; không chặn công bố; ERR-02-034 chỉ ghi nhật ký.

**Đầu ra.** `200`; `duplicates[]` gồm `apiCode`, `score`, `reasons[]`, chủ quản, trạng thái.

**Kết quả.** Người duyệt thấy dịch vụ tương tự đã có và quyết định có gom lại hay không.

**Hậu điều kiện.** Quyết định của người duyệt gắn vào yêu cầu duyệt.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi người duyệt quyết định: API được so, điểm, quyết định, lý do.

**Quy tắc nghiệp vụ.** BR-02-008.

**Màn hình, API.** UI-02-03 bước 3; UI-02-10, UI-02-04; API-02-023.
:::

#### FR-02-021 · Quản lý bộ luật kiểm tra quy ước

::: dac-ta
**Mục đích.** Cho quản trị nền tảng giữ bộ luật mặc định dùng chung và cho quản trị tenant điều chỉnh vừa phải (nâng cảnh báo lên lỗi) theo yêu cầu riêng của tỉnh, mà không sửa mã nguồn.

**Tác nhân, quyền.** PA, TA có quyền quản trị phân hệ (đề nghị, động từ `admin`); mọi vai trò xem.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; Q02-04.

**Tiền điều kiện.** Không.

**Kích hoạt.** Quản trị mở UI-02-15 "Bộ luật kiểm tra".

**Đầu vào.** `ruleId`, `severity` (`ERROR`, `WARNING`), `enabled` (T-BOOL); PA có thêm đề xuất luật mới theo bản phát hành.

**Luồng xử lý chính.**

1. Quản trị mở danh sách 15 luật lớp 2 (và 9 mẫu quét, chỉ đọc), thấy mức mặc định, mức hiệu lực ở tenant, số API đang vi phạm.
2. Quản trị đổi mức hoặc bật tắt một luật; hệ thống kiểm tra thay đổi hợp lệ: không tắt hay hạ luật cấu trúc và bảo mật (ghi chú dưới bảng bộ luật lớp 2), không hạ mức `ERROR` mặc định của lớp 1 (ERR-02-003 nếu vi phạm); danh sách luật không điều chỉnh được nằm ở ghi chú dưới bảng bộ luật lớp 2 (FR-02-017).
3. Hệ thống hiển thị "Ảnh hưởng ước tính": số phiên bản `DRAFT` sẽ phát sinh lỗi mới, số phiên bản `PUBLISHED` không bị ảnh hưởng (luật chỉ áp khi kiểm tra tiếp theo).
4. Hệ thống lưu theo phiên bản của bộ luật (số tăng dần), ghi kiểm toán; các kiểm tra tiếp theo dùng bộ luật mới; kết quả cũ giữ nguyên số phiên bản bộ luật đã dùng.
5. PA phát hành luật mới theo bản triển khai nền tảng; luật mới ở mức `WARNING` trong 30 ngày trước khi thành `ERROR` (để chủ dịch vụ kịp sửa).

**Luồng thay thế.** Tenant khôi phục mặc định nền tảng bằng nút "Về mặc định".

**Luồng ngoại lệ.**

- Cố tắt luật cấu trúc: ERR-02-003 (400); "Luật {mã} là luật bắt buộc, không thể tắt hoặc hạ mức."
- Thiếu quyền: ERR-02-014 (403); "Bạn không có quyền thay đổi bộ luật."
- Vượt trần tham số: ERR-02-040 (422).

**Đầu ra.** `200`; bộ luật hiệu lực với `rulesetVersion`.

**Kết quả.** Tenant có bộ luật kiểm tra vừa chặt vừa phù hợp, không phải chờ bản phát hành.

**Hậu điều kiện.** Bộ luật hiệu lực của tenant có số phiên bản mới.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: luật, mức cũ, mức mới, người đổi, lý do.

**Quy tắc nghiệp vụ.** BR-02-002; BR-02-028.

**Màn hình, API.** UI-02-15; API-02-024, API-02-025.
:::

### 6.5. Nhóm D · Backend, đường dẫn và khung route

Nhóm D nối API trong danh mục với nơi thật sự xử lý lời gọi. Mỗi phiên bản có một hoặc nhiều **backend**: trỏ tới HTTT cung cấp qua một kết nối của PH-05, hoặc tới điểm vào REST của một luồng PH-04. Nhóm D cũng giữ **context-path** công bố và sinh khung route để PH-04 dựng luồng. Cấu hình ở đây là dữ liệu khai báo; việc thực thi cân bằng tải và kiểm tra sức khỏe do APISIX (PH-03) làm.

```{.mermaid caption="Backend và đường dẫn của một phiên bản API"}
flowchart TB
  V["Phiên bản API"] --> P["FR-02-024<br/>Context-path"]
  V --> B["FR-02-022<br/>Backend"]
  B --> S["Loại SYSTEM<br/>kết nối PH-05"]
  B --> F["Loại FLOW<br/>luồng PH-04"]
  B --> H["FR-02-023<br/>Cân bằng tải,<br/>kiểm tra sức khỏe"]
  H --> W["FR-02-025<br/>Xem sức khỏe"]
  V --> R["FR-02-026<br/>Sinh khung route"]
  R --> F
```

Hình trên cho thấy backend gắn vào phiên bản theo hai loại (kết nối PH-05 hoặc luồng PH-04); cân bằng tải và kiểm tra sức khỏe bám theo backend, còn khung route chỉ phục vụ loại luồng.

#### FR-02-022 · Khai báo backend của API

::: dac-ta
**Mục đích.** Cho chủ dịch vụ chỉ cho gateway biết lời gọi API sẽ được chuyển tới đâu: một hay nhiều backend ở HTTT của mình, hoặc một luồng tích hợp, kèm trọng số để chạy song song nhiều bản. Thay cho "URL backend" gõ tay ở hệ cũ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-018; LGC-APIM-002; SRS cũ.

**Tiền điều kiện.** Phiên bản `DRAFT`; với loại `SYSTEM`, kết nối PH-05 đã được cấp cho API; với loại `FLOW`, luồng đã có điểm vào REST ở PH-04.

**Kích hoạt.** Người dùng bấm "+ Thêm backend" ở tab Backend của UI-02-02, hoặc ở bước 4 của UI-02-03.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-022 dưới đây.

**Luồng xử lý chính.**

1. Người dùng chọn loại backend: "HTTT cung cấp" (`SYSTEM`) hoặc "Luồng tích hợp" (`FLOW`).
2. Với `SYSTEM`, người dùng chọn kết nối PH-05 loại HTTP (`http-*`, `oauth2-client`, `http-mtls`) thuộc HTTT cung cấp; hệ thống kiểm tra kết nối tồn tại, cùng HTTT, và môi trường tương ứng đã bật (ERR-02-020 nếu không).
3. Với `FLOW`, người dùng chọn luồng và tên điểm vào; hệ thống hỏi PH-04 xác minh luồng tồn tại, cùng tenant và có điểm vào REST (ERR-02-020 nếu không; ERR-02-034 khi PH-04 không khả dụng).
4. Hệ thống kiểm tra đích theo BR-02-023: TLS tối thiểu 1.2, địa chỉ có trong danh sách đích cho phép của tenant, không trỏ tới địa chỉ nội bộ control plane, loopback, link-local hay địa chỉ dịch vụ siêu dữ liệu đám mây.
5. Hệ thống đặt trọng số mặc định 100 và các tham số mặc định (FR-02-023), lưu backend ở trạng thái `ACTIVE`, đánh dấu `configDirty` để lần công bố sau đẩy xuống gateway.
6. Với phiên bản đã `PUBLISHED`, thêm hoặc đổi backend tạo "yêu cầu thay đổi backend" cần CA duyệt (FR-02-035) trước khi đẩy xuống gateway; không thay trực tiếp.

**Luồng thay thế.** Người dùng chọn "Dùng cho môi trường kiểm thử TEST": backend chỉ áp ở môi trường TEST, khi chuyển môi trường thật phải khai riêng.

**Luồng ngoại lệ.**

- Kết nối hoặc luồng không tồn tại hoặc khác HTTT: ERR-02-020 (422); "Backend không hợp lệ: {lý do}."
- Đích ngoài danh sách cho phép: ERR-02-020 (422); "Đích {máy chủ} chưa có trong danh sách đích cho phép. Đề nghị quản trị tenant bổ sung."
- Vượt số backend tối đa mỗi phiên bản (mặc định 10): ERR-02-040 (422).
- Phiên bản `PENDING`: ERR-02-038 (409).

**Đầu ra.** `201`, tiêu đề `Location`; chi tiết backend: `backendCode`, loại, `targetRef`, `weight`, `status`, cấu hình mặc định.

**Kết quả.** API có ít nhất một backend sẵn sàng để thử và công bố.

**Hậu điều kiện.** Backend lưu, gắn với phiên bản; chưa ảnh hưởng gateway cho tới khi công bố (hoặc duyệt thay đổi).

**Sự kiện phát ra.** EVT-02-02 (`changedFields = backends`) khi phiên bản đã công bố.

**Kiểm toán.** Có: loại, đích (đã che), trọng số, người khai.

**Quy tắc nghiệp vụ.** BR-02-023; BR-02-024; BR-02-032.

**Màn hình, API.** UI-02-02 tab Backend, UI-02-03 bước 4; API-02-026, API-02-027, API-02-029.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `backendCode` | T-CODE | Có | `^[a-z][a-z0-9-]{1,31}$`, duy nhất trong phiên bản | `tuphap-primary` |
| `kind` | T-ENUM | Có | `SYSTEM`, `FLOW` | `SYSTEM` |
| `connectionRef` | T-CODE | Khi `SYSTEM` | `connectionCode` của PH-05, cùng HTTT cung cấp | `ndxp-ho-tich` |
| `pathPrefix` | T-TEXT | Không | Bắt đầu bằng `/`, ≤ 255 ký tự; nối trước đường dẫn khi chuyển tiếp | `/api/v2` |
| `flowRef` | T-CODE | Khi `FLOW` | `flowCode` của PH-04 | `tra-cuu-ho-tich` |
| `entryPoint` | T-CODE | Khi `FLOW` | Tên điểm vào REST của luồng | `rest-main` |
| `weight` | số nguyên | Không | 1…1000, mặc định 100; tổng trọng số `ACTIVE` > 0 | `100` |
| `environments[]` | danh sách T-ENUM | Không | `TEST`, `STAGING`, `PROD`, mặc định cả ba | `["PROD"]` |

: Dữ liệu vào của FR-02-022

#### FR-02-023 · Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe backend

::: dac-ta
**Mục đích.** Cho chủ dịch vụ điều chỉnh cách gateway đối xử với backend: chia tải thế nào, chờ bao lâu, thử lại bao nhiêu lần, khi nào coi backend là hỏng và tạm loại khỏi vòng chia tải, để backend chết không kéo cả API chết.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-018 ("cân bằng tải, kiểm tra sức khỏe"); NFR-02-005.

**Tiền điều kiện.** Phiên bản `DRAFT` có ít nhất một backend (FR-02-022).

**Kích hoạt.** Người dùng sửa khối "Cân bằng tải và sức khỏe" ở tab Backend của UI-02-02.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-023 dưới đây.

**Luồng xử lý chính.**

1. Người dùng chọn thuật toán chia tải và nhập thời gian chờ, số lần thử lại.
2. Người dùng bật kiểm tra sức khỏe chủ động (đường dẫn, chu kỳ, ngưỡng) và/hoặc thụ động (số lỗi liên tiếp).
3. Hệ thống kiểm tra miền giá trị: thời gian chờ không vượt `02.backend.max-timeout-ms` (ERR-02-040); số lần thử lại chỉ áp cho phương thức an toàn lặp lại được (`GET`, `HEAD`, `PUT`, `DELETE`); `POST` chỉ thử lại khi thao tác khai `x-datahub-idempotent: true` (ERR-02-003 nếu vi phạm).
4. Hệ thống kiểm tra đường dẫn kiểm tra sức khỏe có trong danh sách đường dẫn được phép của backend và không cần xác thực nghiệp vụ.
5. Hệ thống lưu cấu hình, đánh dấu `configDirty`; cấu hình được đẩy xuống gateway ở lần công bố (FR-02-036) hoặc ở lần duyệt thay đổi (phiên bản đã công bố).

**Luồng thay thế.** Người dùng chọn "Dùng mặc định nền tảng": hệ thống áp bộ giá trị mặc định ở bảng dưới.

**Luồng ngoại lệ.**

- Giá trị ngoài miền: ERR-02-003 (400); "Giá trị {tên trường} nằm ngoài khoảng cho phép {a}…{b}."
- Vượt trần tenant: ERR-02-040 (422); "Thời gian chờ vượt trần {n} ms của tỉnh."
- Thử lại cho `POST` không đánh dấu lặp lại được: ERR-02-003 (400); "Không thử lại tự động cho thao tác ghi chưa khai là lặp lại được."

**Đầu ra.** `200`, `ETag` mới; cấu hình backend sau cập nhật.

**Kết quả.** Gateway sẽ chia tải và loại backend hỏng theo đúng cấu hình đã chọn.

**Hậu điều kiện.** Cấu hình backend lưu; chờ công bố để có hiệu lực.

**Sự kiện phát ra.** EVT-02-02 khi phiên bản đã công bố.

**Kiểm toán.** Có: giá trị trước, sau của từng tham số.

**Quy tắc nghiệp vụ.** BR-02-024; BR-02-028.

**Màn hình, API.** UI-02-02 tab Backend; API-02-028.
:::

| Tham số | Kiểu | Mặc định | Miền | Ý nghĩa |
|---|---|---|---|---|
| `balancer` | T-ENUM | `ROUND_ROBIN` | `ROUND_ROBIN`, `LEAST_CONN`, `CONSISTENT_HASH` | Thuật toán chia tải theo trọng số |
| `connectTimeoutMs` | số nguyên | 3.000 | 100…10.000 | Chờ kết nối |
| `readTimeoutMs` | số nguyên | 30.000 | 100…`02.backend.max-timeout-ms` (60.000) | Chờ phản hồi |
| `retries` | số nguyên | 1 | 0…3 | Số lần thử lại trên backend khác |
| `health.active.path` | T-TEXT | `/health` | Bắt đầu bằng `/` | Đường dẫn kiểm tra chủ động |
| `health.active.intervalSeconds` | số nguyên | 10 | 2…300 | Chu kỳ kiểm tra |
| `health.active.healthyThreshold` | số nguyên | 2 | 1…10 | Số lần đạt liên tiếp để coi là khỏe |
| `health.active.unhealthyThreshold` | số nguyên | 3 | 1…10 | Số lần lỗi liên tiếp để loại khỏi vòng chia tải |
| `health.passive.failures` | số nguyên | 5 | 1…50 | Số lỗi `5xx` hoặc hết thời gian chờ liên tiếp để loại |

: Dữ liệu vào của FR-02-023

#### FR-02-024 · Quản lý context-path và kiểm tra trùng

::: dac-ta
**Mục đích.** Bảo đảm mỗi phiên bản có một địa chỉ công bố đẹp, đoán được và không trùng ai, theo quy ước `/{nhóm}/{mã API}/v{số chính}`, thay cho context-path đặt tự do ở hệ cũ gây trùng và khó nhớ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`; mọi người dùng gọi được lệnh kiểm tra.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-002 ("context-path theo quy ước"); LGC-APIM-017.

**Tiền điều kiện.** Phiên bản `DRAFT`; API đã có nhóm.

**Kích hoạt.** Hệ thống tự đề xuất khi tạo phiên bản; người dùng bấm "Đổi đường dẫn" hoặc gõ ở bước 1 của UI-02-03 (kiểm tra ngay khi gõ).

**Đầu vào.** `contextPath` (T-TEXT, tùy chọn: mặc định tự sinh).

**Luồng xử lý chính.**

1. Hệ thống sinh đề xuất `/{categoryCode}/{apiCode}/v{major}` từ nhóm, mã API và số chính của phiên bản.
2. Người dùng chấp nhận hoặc sửa phần mở rộng; hệ thống kiểm tra theo mẫu `^/[a-z][a-z0-9-]*(/[a-z0-9][a-z0-9-]*){1,3}/v[0-9]+$` và số chính khớp phiên bản (ERR-02-019).
3. Hệ thống kiểm tra duy nhất trong tenant trên mọi phiên bản chưa `RETIRED` và không trùng, không là tiền tố, không bị tiền tố của đường dẫn khác (xung đột định tuyến) (ERR-02-019).
4. Hệ thống lưu đường dẫn; sau khi phiên bản `PUBLISHED` đường dẫn bất biến (BR-02-022).
5. Đường dẫn của phiên bản `RETIRED` được giữ chỗ, không cấp cho API khác trong 12 tháng.

**Luồng thay thế.** Di trú từ APIM cũ (FR-02-061): hệ thống giữ context-path cũ làm bí danh `legacyPath` để HTTT cũ vẫn gọi được trong giai đoạn chạy song song; bí danh có hạn do TA đặt.

**Luồng ngoại lệ.**

- Trùng hoặc xung đột: ERR-02-019 (422); "Đường dẫn {đường dẫn} đã được dùng hoặc xung đột với {đường dẫn khác}."
- Sai quy ước: ERR-02-019 (422); "Đường dẫn phải dạng /{nhóm}/{mã API}/v{số chính}, chữ thường, gạch ngang."
- Sửa khi đã công bố: ERR-02-011 (409); "Đường dẫn của phiên bản đã công bố không đổi được."

**Đầu ra.** `200`; `contextPath`, `available`, `conflicts[]` (khi kiểm tra); khi lưu: `200` với phiên bản sau cập nhật.

**Kết quả.** Mỗi phiên bản có địa chỉ công bố duy nhất, nhất quán toàn tỉnh.

**Hậu điều kiện.** `contextPath` lưu, chưa tạo route cho tới khi công bố.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: đường dẫn trước, sau.

**Quy tắc nghiệp vụ.** BR-02-003; BR-02-021; BR-02-022.

**Màn hình, API.** UI-02-03 bước 1, UI-02-02 tab Tổng quan; API-02-030, API-02-018 (đổi context-path khi còn bản nháp).
:::

#### FR-02-025 · Xem sức khỏe backend

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và cán bộ vận hành biết backend của API đang khỏe hay hỏng, từ khi nào, tỷ lệ lỗi bao nhiêu, mà không phải mở nhiều công cụ; hữu ích khi bên khai thác phản ánh "API chậm".

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read` (chi tiết nút cho SV của tổ chức, TA, TO, SO).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; LGC-APIM-018; REQ-13.

**Tiền điều kiện.** Phiên bản `PUBLISHED`, `SUSPENDED` hoặc `DEPRECATED`; PH-03 đang chạy.

**Kích hoạt.** Người dùng mở tab Backend của UI-02-02 (làm mới 30 giây).

**Đầu vào.** `apiCode`, `versionNo`; `window` (`15m`, `1h`, `24h`, mặc định `1h`).

**Luồng xử lý chính.**

1. Hệ thống gọi PH-03 và PH-13 lấy trạng thái từng nút backend (`HEALTHY`, `UNHEALTHY`, `UNKNOWN`) từ kiểm tra chủ động và thụ động ở APISIX.
2. Hệ thống ghép với cấu hình backend và tính cho mỗi backend: trạng thái, thời điểm đổi trạng thái gần nhất, tỷ lệ lỗi và độ trễ p95 trong khoảng chọn.
3. Hệ thống tính trạng thái tổng của phiên bản: `UP` (mọi backend khỏe), `DEGRADED` (có nút hỏng), `DOWN` (không còn backend khỏe).
4. Khi `DOWN`, hệ thống hiện dải cảnh báo "Không còn backend nào đáp ứng" và đưa vào thẻ "Cần chú ý" ở UI-02-01.

**Luồng thay thế.** PH-13 không khả dụng: hiển thị trạng thái từ PH-03 kèm nhãn "Thiếu số liệu độ trễ".

**Luồng ngoại lệ.**

- PH-03 không khả dụng: ERR-02-034 (503); "Chưa lấy được trạng thái từ cổng API. Thử lại sau." Hiển thị lần cuối đã biết kèm thời điểm.
- Phiên bản chưa công bố: ERR-02-011 (409); "Phiên bản chưa công bố nên chưa có số liệu sức khỏe."

**Đầu ra.** `200`; `overall`, `backends[]` (`backendCode`, `status`, `since`, `errorRate`, `p95Ms`, nút), `asOf`.

**Kết quả.** Người dùng biết ngay backend nào đang hỏng và từ lúc nào.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-02-024.

**Màn hình, API.** UI-02-02 tab Backend, UI-02-01 thẻ "Cần chú ý"; API-02-031.
:::

#### FR-02-026 · Sinh khung route cho PH-04 từ đặc tả

::: dac-ta
**Mục đích.** Khi chủ dịch vụ chưa có sẵn backend REST mà muốn hiện thực bằng luồng tích hợp, cho hệ thống dựng sẵn khung luồng ở PH-04 từ đặc tả: mỗi thao tác một route theo khung chín chặng chuẩn, để mọi API đều có kiểm quyền, ghi vết, xử lý lỗi và không thể "quên".

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`; kỹ sư tích hợp (IE) nhận khung ở PH-04.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-010; PH-04 FR-04-003 (nguồn `API_SPEC`); BR-04-002 (khung chín chặng của PH-04).

**Tiền điều kiện.** Phiên bản `DRAFT` đạt lớp 1; người dùng chọn không gian làm việc PH-04 mà mình có quyền; PH-04 khả dụng.

**Kích hoạt.** Người dùng bấm "Tạo luồng từ API này" ở tab Backend của UI-02-02.

**Đầu vào.** `workspaceCode` (T-CODE, không gian làm việc PH-04), `flowCode` (T-CODE, mặc định `{apiCode}`), `systemCode` (HTTT đích sẽ gọi, tùy chọn).

**Luồng xử lý chính.**

1. Người dùng chọn không gian làm việc và mã luồng; hệ thống kiểm tra quyền của người dùng ở không gian đó qua PH-04 (ERR-02-014) và `flowCode` chưa dùng (ERR-02-002).
2. Hệ thống gọi PH-04 tạo luồng với `origin = API_SPEC` và `apiRef` là API này (FR-04-003), kèm đầu mối và nhãn phân loại dữ liệu của API.
3. PH-04 đọc đặc tả đã gộp tham chiếu từ PH-02 (API-02-007, scope `catalog:flow-sync`), sinh `rest` DSL, mỗi thao tác một route `direct:{operationId}` với khung chín chặng; lược đồ yêu cầu, phản hồi gắn vào chặng kiểm tra lược đồ; phạm vi quyền lấy từ khai báo `security` của thao tác; PH-04 trả mã luồng và địa chỉ mở trình thiết kế.
4. Hệ thống tạo backend loại `FLOW` ở trạng thái `PLACEHOLDER` trỏ tới luồng vừa tạo; backend chưa tính là backend `ACTIVE` cho tới khi luồng được phát hành ở PH-04.
5. Hệ thống hiển thị liên kết "Mở trình thiết kế" để kỹ sư hoàn thiện phần logic riêng; phần đích đến không suy được để trống và đánh dấu "Cần điền" ở PH-04.
6. Khi luồng được phát hành (EVT-04-07), hệ thống chuyển backend sang `ACTIVE` (FR-02-013 xử lý tương ứng phía sự kiện).

**Luồng thay thế.** PH-04 không khả dụng: yêu cầu vào hàng chờ, vòng đời API vẫn tiếp tục được (backend `FLOW` chưa có thì chưa gửi duyệt được, ERR-02-021).

**Luồng ngoại lệ.**

- PH-04 không khả dụng: ERR-02-034 (503); "Chưa tạo được luồng vì phân hệ Tích hợp chưa sẵn sàng. Yêu cầu đã được xếp hàng."
- `flowCode` đã dùng: ERR-02-002 (409); "Mã luồng {mã} đã được dùng. Chọn mã khác."
- Đặc tả chưa đạt lớp 1: ERR-02-006 (422); "Đặc tả còn lỗi, chưa sinh khung luồng được."
- Không có quyền ở không gian làm việc: ERR-02-014 (403); "Bạn không có quyền ở không gian làm việc này."

**Đầu ra.** `202` kèm `operationId`; khi xong: `flowCode`, `designerUrl`, `generatedRoutes`, `pendingFill` (số chỗ cần điền).

**Kết quả.** Kỹ sư tích hợp nhận luồng nháp có sẵn khung chuẩn, chỉ còn điền logic riêng.

**Hậu điều kiện.** Luồng nháp được tạo ở PH-04; backend `FLOW` ở trạng thái `PLACEHOLDER`.

**Sự kiện phát ra.** EVT-02-02 (`changedFields = backends`).

**Kiểm toán.** Có: người yêu cầu, không gian làm việc, `flowCode`, số route sinh.

**Quy tắc nghiệp vụ.** BR-02-010; BR-02-024.

**Màn hình, API.** UI-02-02 tab Backend; API-02-032, API-02-095 (tiến độ tác vụ).
:::

```{.mermaid caption="Trình tự sinh khung route cho PH-04 từ đặc tả"}
sequenceDiagram
  autonumber
  participant SV as Chủ dịch vụ
  participant C as PH-02
  participant P as PH-04
  participant IE as Kỹ sư tích hợp
  SV->>C: Tạo luồng từ API, chọn không gian làm việc
  C->>P: Tạo luồng nguồn API_SPEC, kèm mã luồng, nhãn phân loại
  P->>C: Đọc đặc tả đã gộp tham chiếu
  P->>P: Sinh rest DSL, mỗi thao tác một route chín chặng
  P-->>C: Mã luồng, địa chỉ trình thiết kế, số chỗ cần điền
  C->>C: Tạo backend FLOW ở trạng thái PLACEHOLDER
  C-->>SV: Liên kết mở trình thiết kế
  IE->>P: Hoàn thiện logic riêng, phát hành luồng
  P-->>C: EVT-04-07 triển khai SYNCED
  C->>C: Chuyển backend sang ACTIVE
```

Hình trên cho thấy PH-02 chỉ khởi tạo yêu cầu và theo dõi, còn mọi thiết kế luồng thuộc PH-04; backend chỉ có hiệu lực sau khi luồng phát hành, nên API không thể công bố khi luồng chưa chạy được.

### 6.6. Nhóm E · Gói sử dụng

Gói sử dụng (Plan) là điều kiện thương lượng sẵn giữa bên cung cấp và bên khai thác: dùng kiểu xác thực nào, được gọi bao nhiêu, đường dẫn nào, ai được xin. Hệ cũ chia việc dựng plan thành các bước Define, Secure, Restriction, Policies; Datahub giữ ý đó nhưng gộp vào một biểu mẫu, bắt buộc kiểu xác thực phù hợp mức phân loại dữ liệu, và để PH-03 thực thi hạn mức. Mỗi gói thuộc đúng một phiên bản API và đi theo máy trạng thái bốn trạng thái ở mục 4.4.

```{.mermaid caption="Vòng đời và các chức năng của gói sử dụng"}
flowchart TB
  A["FR-02-027<br/>Tạo gói: thông tin,<br/>điều kiện truy cập"] --> B["FR-02-028<br/>Kiểu xác thực"]
  B --> C["FR-02-029<br/>Hạn mức, đường dẫn"]
  C --> D["FR-02-030<br/>Công bố gói<br/>STAGING sang PUBLISHED"]
  D --> E["FR-02-031<br/>Ngừng khuyến nghị<br/>DEPRECATED"]
  E --> F["FR-02-032<br/>Đóng gói CLOSED"]
  G["FR-02-033<br/>Sao chép sang<br/>phiên bản mới"] --> A
```

Hình trên đi theo thứ tự soạn gói: thông tin, xác thực, hạn mức rồi công bố. Sau công bố chỉ còn hai bước (ngừng khuyến nghị rồi đóng); sao chép gói là đường tắt khi tạo phiên bản mới.

#### FR-02-027 · Tạo gói sử dụng: thông tin và điều kiện truy cập

::: dac-ta
**Mục đích.** Cho chủ dịch vụ tạo một gói cho phiên bản API của mình: đặt tên, mô tả điều khoản, nói rõ nhóm HTTT nào được xin, đăng ký cần duyệt tay hay tự duyệt, thời hạn đăng ký. Tương ứng bước "Define" của plan ở hệ cũ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-009; LGC-APIM-010; D02-08 §6 (ánh xạ "nhóm được phép truy cập" thành điều kiện đăng ký của gói).

**Tiền điều kiện.** Phiên bản ở `DRAFT` hoặc `PUBLISHED` (gói mới thêm cho phiên bản đã công bố đi qua duyệt, FR-02-030); chưa vượt số gói tối đa mỗi phiên bản (mặc định 10).

**Kích hoạt.** Người dùng bấm "+ Tạo gói" ở tab Gói sử dụng của UI-02-02 hoặc ở UI-02-06, mở UI-02-07.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-027 dưới đây.

**Luồng xử lý chính.**

1. Người dùng chọn phiên bản API, nhập mã gói, tên, mô tả, điều khoản sử dụng.
2. Hệ thống kiểm tra mã gói theo mẫu, duy nhất trong phiên bản và chưa từng dùng kể cả gói đã đóng (ERR-02-002) và người dùng thuộc tổ chức chủ quản (ERR-02-014).
3. Người dùng chọn đối tượng được xin: "Mọi HTTT của tỉnh", "Nhóm HTTT" (theo đơn vị hoặc nhãn ở PH-01), hoặc "Danh sách HTTT cụ thể"; hệ thống kiểm tra các HTTT trong danh sách tồn tại ở PH-01 (ERR-02-026).
4. Người dùng chọn cách duyệt: tự duyệt (`autoApprove`) hoặc duyệt tay; hệ thống chỉ cho tự duyệt khi `dataClass` của API không vượt `02.subscription.auto-approve.max-class` (mặc định `INTERNAL`) (BR-02-026, ERR-02-003 nếu vi phạm).
5. Người dùng nhập thời hạn mỗi đăng ký (số tháng, hoặc không thời hạn) và, nếu muốn, đơn giá thông tin; hệ thống ghi nhận đơn giá chỉ để hiển thị (BR-02-040 nêu ở Q02-09).
6. Hệ thống tạo gói ở trạng thái `STAGING`, chuyển sang bước chọn kiểu xác thực (FR-02-028) và hạn mức (FR-02-029).

**Luồng thay thế.** Người dùng chọn "Tạo từ mẫu gói": hệ thống điền sẵn bộ ba gói thường dùng (Công khai tra cứu, Tích hợp nội bộ, Tích hợp bảo mật cao) cho người dùng chỉnh.

**Luồng ngoại lệ.**

- Mã gói đã dùng: ERR-02-002 (409); "Mã gói {mã} đã được dùng. Chọn mã khác."
- Vượt số gói tối đa: ERR-02-040 (422); "Phiên bản đã đạt số gói tối đa ({n})."
- Tự duyệt với dữ liệu mức cao: ERR-02-003 (400); "Dữ liệu mức {mức} không cho tự duyệt đăng ký."
- Phiên bản `PENDING` hoặc `RETIRED`: ERR-02-038 (409) hoặc ERR-02-011 (409).

**Đầu ra.** `201`, tiêu đề `Location`, `ETag`; chi tiết gói: `planCode`, `status = STAGING`, `audience`, `autoApprove`, `validityMonths`, các trường chờ khai (xác thực, hạn mức).

**Kết quả.** Chủ dịch vụ có gói nháp gắn với phiên bản API, sẵn sàng khai xác thực và hạn mức.

**Hậu điều kiện.** Gói `STAGING` được tạo; chưa nhận đăng ký, chưa có cấu hình ở gateway.

**Sự kiện phát ra.** EVT-02-08 (`plan.state-changed`, trạng thái đầu `STAGING`).

**Kiểm toán.** Có: mã gói, phiên bản API, `audience`, `autoApprove`, thời hạn.

**Quy tắc nghiệp vụ.** BR-02-021; BR-02-026; BR-02-032; BR-02-040.

**Màn hình, API.** UI-02-07 (phần "Thông tin"), UI-02-06, UI-02-03; API-02-033, API-02-034, API-02-035, API-02-096 (danh sách gói toàn tenant).
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `planCode` | T-CODE | Có | `^[a-z][a-z0-9-]{1,31}$`, duy nhất trong phiên bản | `tich-hop-bao-mat` |
| `name` | T-NAME | Có | 3…100 ký tự | `Tích hợp bảo mật cao` |
| `description` | T-TEXT | Có | 20…2000 ký tự | `Dành cho HTTT tích hợp máy–máy, xác thực mTLS` |
| `terms` | T-TEXT | Không | ≤ 4000 ký tự, hiện cho người đăng ký xác nhận | `Chỉ dùng cho thủ tục hộ tịch…` |
| `audience.type` | T-ENUM | Có | `ALL_SYSTEMS`, `SYSTEM_GROUP`, `SYSTEM_LIST` | `SYSTEM_LIST` |
| `audience.values[]` | danh sách T-CODE | Khi khác `ALL_SYSTEMS` | Mã HTTT hoặc nhãn nhóm ở PH-01 | `["HT-MOTCUA","HT-DKKD"]` |
| `autoApprove` | T-BOOL | Có | Chỉ `true` khi `dataClass` ≤ ngưỡng tự duyệt | `false` |
| `validityMonths` | số nguyên | Không | 1…60; rỗng là không thời hạn | `12` |
| `unitPriceVnd` | T-MONEY | Không | ≥ 0; chỉ hiển thị, mặc định 0 | `0` |

: Dữ liệu vào của FR-02-027

#### FR-02-028 · Chọn kiểu xác thực của gói

::: dac-ta
**Mục đích.** Cho chủ dịch vụ chọn cách bên khai thác chứng minh danh tính khi gọi API, và để hệ thống chặn chọn kiểu yếu cho dữ liệu nhạy cảm. Tương ứng bước "Secure" của plan hệ cũ (Keyless hoặc API key), được nâng cấp theo SEC-24.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-011; SEC-24; CMP-LAW-06, CMP-LAW-08.

**Tiền điều kiện.** Gói `STAGING` (gói `PUBLISHED` đổi xác thực theo BR-02-017: chỉ nâng mức mạnh hơn bằng gói mới).

**Kích hoạt.** Người dùng chọn kiểu xác thực ở phần "Bảo mật" của UI-02-07.

**Đầu vào.** `authType` (T-ENUM): `KEYLESS`, `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS`; `tokenLifetimeSeconds` (tùy chọn); `requireIdempotencyKey` (T-BOOL, mặc định `true` cho thao tác ghi).

**Luồng xử lý chính.**

1. Hệ thống hiển thị các kiểu xác thực, đánh dấu kiểu bị cấm với mức phân loại của API và lý do.
2. Người dùng chọn kiểu; hệ thống kiểm tra theo bảng ràng buộc dưới đây (ERR-02-022 nếu vi phạm).
3. Với `OAUTH2_PKJWT`, `OAUTH2_MTLS`, hệ thống xác nhận tenant đã có CA HTTT và Keycloak realm cấu hình cho `private_key_jwt` hoặc `tls_client_auth` (ERR-02-034 nếu thiếu cấu hình, báo TA).
4. Hệ thống sinh khuôn phạm vi `api:{apiCode}:{planCode}` và danh sách phạm vi từng thao tác (từ khai báo `security` của đặc tả), kiểm tra phạm vi đặc tả khớp khuôn (LINT-02-08).
5. Hệ thống lưu kiểu xác thực vào gói; với `KEYLESS` hiển thị cảnh báo "Mọi người gọi được API này không cần danh tính" và yêu cầu tích chọn xác nhận.

**Luồng thay thế.** Chuyển giai đoạn quá độ: tenant được phép dùng `OAUTH2_SECRET` cho dữ liệu `PUBLIC`, `INTERNAL` với bí mật ≥ 256 bit và hạn ≤ 180 ngày (SEC-24); gói hiển thị nhãn "Giai đoạn chuyển đổi".

**Luồng ngoại lệ.**

- Kiểu xác thực không phù hợp mức phân loại: ERR-02-022 (422); "Dữ liệu mức {mức} yêu cầu xác thực {kiểu tối thiểu}. Chọn kiểu mạnh hơn."
- `KEYLESS` cho API không phải `PUBLIC` hoặc mức hiển thị không phải `PUBLIC`: ERR-02-022 (422); "Chỉ API dữ liệu công khai mới được gọi không cần xác thực."
- Realm hoặc CA chưa sẵn sàng: ERR-02-034 (503); "Tỉnh chưa bật xác thực {kiểu}. Liên hệ quản trị tenant."

**Đầu ra.** `200`, `ETag` mới; gói với `authType`, `scopeTemplate`, `operationScopes[]`.

**Kết quả.** Gói có kiểu xác thực đúng với mức nhạy cảm của dữ liệu.

**Hậu điều kiện.** `authType` lưu; khuôn phạm vi gắn với gói.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: kiểu trước, sau; xác nhận `KEYLESS` nếu có.

**Quy tắc nghiệp vụ.** BR-02-016; BR-02-017; BR-02-025.

**Màn hình, API.** UI-02-07 (phần "Bảo mật"); API-02-036.
:::

| Mức phân loại của API | Kiểu xác thực được phép | Ghi chú |
|---|---|---|
| `PUBLIC` Công khai | `KEYLESS` (chỉ khi mức hiển thị `PUBLIC`), `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` | `KEYLESS` chịu giới hạn tần suất theo IP ở PH-03 |
| `INTERNAL` Nội bộ | `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` | `API_KEY` và `OAUTH2_SECRET` chỉ giai đoạn chuyển đổi, bí mật ≥ 256 bit, hạn ≤ 180 ngày |
| `RESTRICTED` Hạn chế | `OAUTH2_PKJWT`, `OAUTH2_MTLS` | `private_key_jwt` (RFC 7523) hoặc `tls_client_auth` (RFC 8705), theo SEC-24 |
| `SENSITIVE` Nhạy cảm | `OAUTH2_MTLS` | Token ràng buộc chứng thư, APISIX đối chiếu vân tay chứng thư (SEC-24) |

: Ràng buộc kiểu xác thực theo mức phân loại (BR-02-016)

#### FR-02-029 · Khai báo hạn mức và đường dẫn cho phép của gói

::: dac-ta
**Mục đích.** Cho chủ dịch vụ khai mỗi gói được gọi nhanh đến đâu (mỗi giây, mỗi phút), tối đa bao nhiêu lượt (mỗi giờ, ngày, tháng) và chỉ những thao tác, đường dẫn nào, để dịch vụ không bị một bên khai thác làm quá tải và để quyền gọi đúng với điều đã thương lượng. PH-02 chỉ khai báo; PH-03 mới thực thi hạn mức, chặn đường dẫn ở gateway.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-012; LGC-APIM-013; LGC-APIM-014 (phần khai báo; PH-03 làm chính); LGC-APIM-015 (chính sách do PH-03 cung cấp bộ chuẩn).

**Tiền điều kiện.** Gói `STAGING`; đặc tả của phiên bản đã đạt lớp 1.

**Kích hoạt.** Người dùng nhập phần "Hạn mức và đường dẫn" ở UI-02-07.

**Đầu vào.** `rateLimit.perSecond`, `rateLimit.perMinute`; `quota.perHour`, `quota.perDay`, `quota.perMonth`; `allowedOperations[]` (danh sách `operationId`), `deniedPathPatterns[]`; `maxRequestBodyKb`; `policyRef` (bộ chính sách chuẩn của PH-03, tùy chọn).

**Luồng xử lý chính.**

1. Hệ thống đề xuất giá trị mặc định theo `dataClass` (ví dụ `RESTRICTED`: 10 lượt/giây, 300 lượt/phút, 20.000 lượt/ngày) từ tham số tenant.
2. Người dùng chỉnh giá trị; hệ thống kiểm tra thứ tự hợp lý (giây ≤ phút/60 × hệ số đột biến cho phép; giờ ≤ ngày; ngày ≤ tháng) và không vượt trần tenant ở D03-10 §5.3 (ERR-02-040).
3. Người dùng chọn thao tác được phép từ danh sách thao tác của đặc tả; hệ thống kiểm tra mỗi `operationId` có trong đặc tả (ERR-02-037); mặc định "mọi thao tác".
4. Người dùng thêm mẫu đường dẫn bị cấm (danh sách đen); hệ thống kiểm tra cú pháp mẫu và không chặn toàn bộ thao tác được phép.
5. Hệ thống so hạn mức giờ của gói với hạn mức giờ cam kết SLA (FR-02-055): lớn hơn thì cảnh báo "Gói cho phép nhiều hơn năng lực đã cam kết".
6. Hệ thống lưu khai báo; khi công bố sẽ chuyển PH-03 sinh cấu hình `limit-req`, `limit-count`, danh sách cho phép và chặn (FR-02-036).

**Luồng thay thế.** Người dùng chọn "Không giới hạn" cho hạn mức tháng: chỉ được với `dataClass` `PUBLIC`, `INTERNAL`; còn lại bắt buộc có hạn mức ngày.

**Luồng ngoại lệ.**

- Giá trị sai thứ tự: ERR-02-023 (422); "Hạn mức không hợp lý: {mô tả}."
- Thao tác không có trong đặc tả: ERR-02-037 (422); "Thao tác {operationId} không có trong đặc tả."
- Vượt trần tenant: ERR-02-040 (422); "Hạn mức vượt trần {giá trị} của tỉnh."
- Gói `PUBLISHED`: chỉ nâng hạn mức hoặc thêm thao tác (BR-02-017); hạ hạn mức: ERR-02-011 (409); "Gói đã công bố không hạ hạn mức. Tạo gói mới và ngừng khuyến nghị gói này."

**Đầu ra.** `200`, `ETag` mới; gói với khai báo hạn mức, thao tác, cờ cảnh báo SLA.

**Kết quả.** Gói có hạn mức và phạm vi đường dẫn rõ ràng, sẵn sàng để PH-03 thực thi.

**Hậu điều kiện.** Khai báo lưu; chưa có hiệu lực ở gateway cho tới khi công bố.

**Sự kiện phát ra.** EVT-02-08 chỉ khi gói đã `PUBLISHED` (`changedFields`).

**Kiểm toán.** Có: giá trị trước, sau của hạn mức và danh sách thao tác.

**Quy tắc nghiệp vụ.** BR-02-017; BR-02-024; BR-02-028.

**Màn hình, API.** UI-02-07 (phần "Hạn mức và đường dẫn"); API-02-036.
:::

#### FR-02-030 · Công bố gói (`STAGING` sang `PUBLISHED`)

::: dac-ta
**Mục đích.** Cho gói bắt đầu nhận đăng ký sử dụng sau khi người có thẩm quyền rà soát điều kiện truy cập, kiểu xác thực và hạn mức. Gói đi kèm phiên bản được duyệt chung ở FR-02-035; gói thêm sau cho phiên bản đã công bố có yêu cầu duyệt riêng.

**Tác nhân, quyền.** SV (○), TA gửi (`PERM-02-submit`); CA, TA duyệt (`PERM-02-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-009.

**Tiền điều kiện.** Gói `STAGING` đã khai đủ xác thực và hạn mức; phiên bản `PUBLISHED`, hoặc `PENDING` trong cùng đợt duyệt.

**Kích hoạt.** Người dùng bấm "Gửi duyệt gói" ở UI-02-06, hoặc hệ thống chuyển cùng phiên bản khi FR-02-035 duyệt.

**Đầu vào.** `planCode`; `comment` (tùy chọn khi gửi); khi duyệt: quyết định, ý kiến.

**Luồng xử lý chính.**

1. SV bấm "Gửi duyệt gói"; hệ thống kiểm tra gói đủ điều kiện (ERR-02-012 liệt kê phần thiếu) và phiên bản không ở trạng thái cuối (ERR-02-011).
2. Hệ thống tạo yêu cầu duyệt loại `PLAN_PUBLISH` gắn với gói; việc hiện trong "Việc của tôi" của CA.
3. CA xem điều kiện đăng ký, kiểu xác thực, hạn mức, đơn giá thông tin, các cảnh báo; duyệt hoặc từ chối kèm lý do (FR-00-072); người gửi, người sửa gần nhất và người duyệt phải là ba người khác nhau (BR-02-008, ERR-02-013).
4. Nếu duyệt, hệ thống chuyển gói sang `PUBLISHED` và chuyển cấu hình xuống PH-03 (nhóm consumer, hạn mức); thành công thì gói nhận đăng ký.
5. Hệ thống ghi kiểm toán và thông báo SV.
6. Gói đi kèm một phiên bản đang `PENDING`: bước 2 gộp vào yêu cầu duyệt phiên bản (FR-02-035) và gói chỉ sang `PUBLISHED` khi phiên bản sang `PUBLISHED`.

**Luồng thay thế.** Từ chối: gói về `STAGING`, SV sửa rồi gửi lại.

**Luồng ngoại lệ.**

- Gói chưa đủ điều kiện: ERR-02-012 (409); "Gói còn thiếu: {danh sách}."
- Người gửi tự duyệt: ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."
- PH-03 không nhận cấu hình: ERR-02-033 (503); "Cổng API chưa nhận cấu hình gói. Hệ thống sẽ thử lại, gói chưa nhận đăng ký."

**Đầu ra.** `202` khi gửi (`reviewRequestId`); `200` khi duyệt; gói với `status = PUBLISHED`.

**Kết quả.** Gói đã công bố, HTTT có thể đăng ký sử dụng theo gói đó.

**Hậu điều kiện.** Gói `PUBLISHED`; cấu hình gói có ở gateway.

**Sự kiện phát ra.** EVT-02-08 (`plan.state-changed`).

**Kiểm toán.** Có: người gửi, người duyệt, ý kiến, trạng thái trước và sau.

**Quy tắc nghiệp vụ.** BR-02-008; BR-02-016; BR-02-028.

**Màn hình, API.** UI-02-06, UI-02-10; API-02-037, API-02-044, API-02-045.
:::

#### FR-02-031 · Ngừng khuyến nghị gói

::: dac-ta
**Mục đích.** Cho chủ dịch vụ ngừng nhận đăng ký mới vào một gói cũ (ví dụ chuyển sang gói bảo mật hơn) mà không cắt những HTTT đang dùng, đúng nguyên tắc không ngắt bên khai thác bất ngờ.

**Tác nhân, quyền.** SV (○), TA gửi (`PERM-02-submit`); CA, TA duyệt (`PERM-02-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-009.

**Tiền điều kiện.** Gói `PUBLISHED`.

**Kích hoạt.** Người dùng bấm "Ngừng khuyến nghị" ở UI-02-06.

**Đầu vào.** `planCode`, `reason` (bắt buộc), `successorPlanCode` (tùy chọn), `sunsetAt` (T-DATE, tùy chọn).

**Luồng xử lý chính.**

1. SV chọn gói và nhập lý do, gói kế nhiệm (nếu có) và hạn; hệ thống kiểm tra gói kế nhiệm cùng phiên bản và đang `PUBLISHED` (ERR-02-003 nếu không).
2. Hệ thống tính số đăng ký đang hiệu lực của gói và hiển thị cho SV (FR-02-044); nếu có đăng ký, hạn `sunsetAt` phải tuân thủ thời hạn tối thiểu của BR-02-004 (ERR-02-031).
3. Hệ thống tạo yêu cầu duyệt `PLAN_DEPRECATE`; CA duyệt hoặc từ chối.
4. Khi duyệt, hệ thống chuyển gói `DEPRECATED`, khóa nhận đăng ký mới (ERR-02-025 với đăng ký mới), giữ nguyên các đăng ký hiện có.
5. Hệ thống thông báo cho mọi bên đăng ký `ACTIVE` của gói kèm gói kế nhiệm và hạn (FR-02-057).
6. Hệ thống nhắc định kỳ theo lịch của BR-02-004 khi gần hạn.

**Luồng thay thế.** Gói chưa có đăng ký nào: bỏ qua bước thông báo và hạn; CA duyệt nhanh.

**Luồng ngoại lệ.**

- Gói không `PUBLISHED`: ERR-02-011 (409); "Chỉ gói đang công bố mới ngừng khuyến nghị được."
- Hạn quá ngắn khi còn đăng ký: ERR-02-031 (422); "Hạn chuyển đổi tối thiểu {n} ngày kể từ hôm nay."
- Gói kế nhiệm không hợp lệ: ERR-02-003 (400); "Gói kế nhiệm phải cùng phiên bản và đang công bố."
- Vi phạm bốn mắt: ERR-02-013 (403).

**Đầu ra.** `202` khi gửi; `200` khi duyệt; gói `DEPRECATED` kèm `successorPlanCode`, `sunsetAt`, số bên chưa chuyển.

**Kết quả.** Gói không nhận đăng ký mới, người đang dùng được báo và có thời gian chuyển.

**Hậu điều kiện.** Gói `DEPRECATED`; cấu hình gateway thêm tiêu đề cảnh báo cho lượt gọi theo gói.

**Sự kiện phát ra.** EVT-02-08; EVT-02-12 (`change.notice-issued`).

**Kiểm toán.** Có: lý do, kế nhiệm, hạn, số đăng ký bị ảnh hưởng, người duyệt.

**Quy tắc nghiệp vụ.** BR-02-004; BR-02-008; BR-02-018; BR-02-029.

**Màn hình, API.** UI-02-06, UI-02-10; API-02-038, API-02-044, API-02-096.
:::

#### FR-02-032 · Đóng gói

::: dac-ta
**Mục đích.** Cho chủ dịch vụ chấm dứt hẳn một gói không còn ai dùng, hoặc hủy một gói nháp chưa bao giờ công bố, để danh mục không đọng gói thừa.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create` (hủy gói `STAGING`) hoặc `PERM-02-submit` rồi CA `PERM-02-publish` (gói `DEPRECATED`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-009.

**Tiền điều kiện.** Gói `STAGING` (hủy) hoặc `DEPRECATED` (đóng) và không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-019).

**Kích hoạt.** Người dùng bấm "Hủy gói" hoặc "Đóng gói" ở UI-02-06.

**Đầu vào.** `planCode`, `reason` (bắt buộc với đóng).

**Luồng xử lý chính.**

1. Người dùng chọn gói và xác nhận (FR-00-050), nhập lý do khi đóng.
2. Hệ thống đếm đăng ký còn hiệu lực của gói (`PENDING`, `ACTIVE`, `SUSPENDED`); còn thì từ chối và liệt kê, gợi ý thu hồi hoặc chuyển sang gói kế nhiệm (ERR-02-024).
3. Với gói `STAGING` chưa từng công bố: hệ thống xóa mềm gói, mã gói được giữ chỗ vĩnh viễn (BR-02-021).
4. Với gói `DEPRECATED`: hệ thống tạo yêu cầu duyệt, CA duyệt; sau duyệt gói sang `CLOSED`, PH-03 gỡ cấu hình gói.
5. Hệ thống ghi kiểm toán và phát sự kiện.

**Luồng thay thế.** Người dùng chọn "Chuyển các đăng ký còn lại sang gói kế nhiệm" trước khi đóng: hệ thống tạo đăng ký mới `ACTIVE` ở gói kế nhiệm cho từng HTTT (kế thừa mục đích, thời hạn) và đóng đăng ký cũ.

**Luồng ngoại lệ.**

- Còn đăng ký đang hiệu lực: ERR-02-024 (409); "Còn {n} đăng ký đang dùng gói này. Chuyển hoặc thu hồi trước khi đóng."
- Gói đang `PUBLISHED`: ERR-02-011 (409); "Ngừng khuyến nghị gói trước khi đóng."
- Không nêu lý do khi đóng: ERR-02-041 (400); "Cần nêu lý do đóng gói."

**Đầu ra.** `204` (hủy gói nháp); `202` rồi `200` (đóng gói qua duyệt); gói `CLOSED`.

**Kết quả.** Gói không còn trong danh sách hoạt động; lịch sử giữ lại.

**Hậu điều kiện.** Gói `CLOSED` hoặc xóa mềm; cấu hình gói đã gỡ ở gateway.

**Sự kiện phát ra.** EVT-02-08.

**Kiểm toán.** Có: lý do, số đăng ký đã chuyển, người duyệt.

**Quy tắc nghiệp vụ.** BR-02-019; BR-02-021; BR-02-028.

**Màn hình, API.** UI-02-06; API-02-039, API-02-041.
:::

#### FR-02-033 · Sao chép gói sang phiên bản mới

::: dac-ta
**Mục đích.** Khi tạo phiên bản mới, cho chủ dịch vụ mang sang các gói của phiên bản trước để khỏi dựng lại từ đầu, và để việc chuyển đăng ký giữa phiên bản (cùng số chính) có gói cùng mã tiếp nhận.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; LGC-APIM-009; BR-02-035.

**Tiền điều kiện.** Phiên bản đích `DRAFT`; phiên bản nguồn cùng API.

**Kích hoạt.** Hệ thống đề xuất khi tạo phiên bản (FR-02-042); hoặc người dùng bấm "Sao chép gói từ phiên bản khác" ở UI-02-06.

**Đầu vào.** `fromVersionNo`, `toVersionNo`, `planCodes[]` (mặc định mọi gói `PUBLISHED`, `DEPRECATED` chưa `CLOSED`), `keepCodes` (T-BOOL, mặc định `true`).

**Luồng xử lý chính.**

1. Người dùng chọn phiên bản nguồn, đích và các gói cần sao chép.
2. Hệ thống sao chép khai báo (điều kiện, xác thực, hạn mức, đường dẫn cho phép) sang gói `STAGING` của phiên bản đích, giữ nguyên mã gói khi `keepCodes = true`.
3. Hệ thống đối chiếu đường dẫn, thao tác cho phép với đặc tả phiên bản đích; thao tác không còn thì loại khỏi gói và báo (ERR-02-037 chỉ dạng cảnh báo).
4. Hệ thống kiểm tra lại ràng buộc xác thực theo `dataClass` hiện hành (BR-02-016); gói không còn hợp lệ được đánh dấu "Cần sửa".
5. Hệ thống trả danh sách gói đã tạo kèm cảnh báo.

**Luồng thay thế.** Không chọn gói nào: bỏ qua; người dùng tạo gói mới (FR-02-027).

**Luồng ngoại lệ.**

- Mã gói trùng ở phiên bản đích: ERR-02-002 (409); "Phiên bản đích đã có gói {mã}. Bỏ chọn hoặc đổi mã."
- Vượt số gói tối đa: ERR-02-040 (422).
- Phiên bản đích không `DRAFT`: ERR-02-038 (409).

**Đầu ra.** `201`; `plans[]` mới tạo với `warnings[]`.

**Kết quả.** Phiên bản mới có sẵn các gói đã quen dùng, chỉ cần rà lại.

**Hậu điều kiện.** Gói `STAGING` mới ở phiên bản đích.

**Sự kiện phát ra.** EVT-02-08 cho từng gói.

**Kiểm toán.** Có: phiên bản nguồn, đích, danh sách gói.

**Quy tắc nghiệp vụ.** BR-02-016; BR-02-021; BR-02-035.

**Màn hình, API.** UI-02-06; API-02-040.
:::

### 6.7. Nhóm F · Vòng đời, duyệt và phiên bản

Nhóm F là trục của phân hệ: đưa một phiên bản API từ bản nháp tới môi trường thật có người thứ hai duyệt, tạm ngừng khi cần, ngừng khuyến nghị có lộ trình, ngừng hẳn khi không còn ai dùng, và quản lý các phiên bản song song. Máy trạng thái ở mục 4.3. Nguyên tắc xuyên suốt: không bước nào làm gián đoạn bên khai thác bất ngờ, và mọi chuyển trạng thái đều có lý do cùng kiểm toán (BR-02-028).

```{.mermaid caption="Các chức năng nhóm F theo trạng thái phiên bản"}
flowchart TB
  D["DRAFT"] -->|"FR-02-034 Gửi duyệt"| P["PENDING"]
  P -->|"FR-02-035 Duyệt"| G["FR-02-036 Công bố<br/>ra gateway"]
  P -->|"Trả lại"| D
  G --> U["PUBLISHED"]
  U -->|"FR-02-037"| S["SUSPENDED"]
  S -->|"FR-02-037"| U
  U -->|"FR-02-038"| E["DEPRECATED"]
  E -->|"FR-02-039"| R["RETIRED"]
  D -->|"FR-02-039 Hủy nháp"| R
  U --> V["FR-02-042, 043, 044<br/>Phiên bản mới,<br/>so sánh, tác động"]
```

Hình trên gắn từng chức năng vào đúng trạng thái. Chiều đi lên (duyệt, công bố) luôn qua người thứ hai; chiều đi xuống (tạm ngừng, ngừng khuyến nghị, ngừng hẳn) luôn có lý do và thông báo.

#### FR-02-034 · Gửi duyệt công bố API

::: dac-ta
**Mục đích.** Cho chủ dịch vụ nộp phiên bản đã hoàn chỉnh để người thứ hai rà soát trước khi ra môi trường thật. Hệ thống kiểm tra lại mọi điều kiện ở thời điểm nộp để người duyệt không mất công xem hồ sơ chưa đạt.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-submit`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-004; SRS cũ FR-02-004 (`PENDING`).

**Tiền điều kiện.** Phiên bản `DRAFT`.

**Kích hoạt.** Người dùng bấm "Gửi duyệt" ở UI-02-02, hoặc "Lưu và gửi duyệt" ở UI-02-03.

**Đầu vào.** `apiCode`, `versionNo`; `comment` (T-TEXT, ghi chú cho người duyệt, tùy chọn); `If-Match`.

**Luồng xử lý chính.**

1. Người dùng bấm "Gửi duyệt"; hệ thống chạy lại kiểm tra đặc tả lớp 1, lớp 2 và quét bí mật trên đúng băm đang lưu (FR-02-016…018): còn `ERROR` thì từ chối (ERR-02-006, 007, 008).
2. Hệ thống kiểm tra các điều kiện còn lại và gom mọi điều kiện thiếu vào một danh sách (ERR-02-012): có ít nhất một backend `ACTIVE` (BR-02-024, ERR-02-021); có ít nhất một gói `STAGING` hoặc `PUBLISHED` đủ khai báo (FR-02-027…029); SLA đã khai (FR-02-055); mô tả API tiếng Việt đủ độ dài; mức hiển thị hợp lệ với `dataClass` (BR-02-037); không còn cảnh báo `OPEN` chưa được chấp nhận ở mức yêu cầu của tenant.
3. Hệ thống kiểm tra phiên bản đã chạy thử ở môi trường TEST thành công trong 30 ngày trên đúng băm đặc tả (FR-02-036 chế độ thử; tham số `02.submit.require-test-deploy`, mặc định bật); nếu thiếu, từ chối với hướng dẫn "Thử trên TEST".
4. Hệ thống kiểm tra thay đổi phá vỡ so với phiên bản `PUBLISHED` cùng API: có phá vỡ mà giữ số chính thì từ chối (ERR-02-017); chưa phân loại được thì yêu cầu xác nhận tay (FR-02-043).
5. Hệ thống chuyển phiên bản `PENDING`, khóa nội dung, tạo yêu cầu duyệt loại `VERSION_PUBLISH` kèm ảnh chụp kết quả kiểm tra và danh sách API gần giống (FR-02-020), đưa vào "Việc của tôi" của CA.
6. Hệ thống ghi kiểm toán, phát sự kiện và thông báo SV: "Đã gửi duyệt phiên bản {phiên bản}."

**Luồng thay thế.** Người gửi bấm "Rút lại" khi chưa ai quyết định: phiên bản về `DRAFT`, yêu cầu duyệt chuyển `WITHDRAWN` (API-02-043). Người gửi có ghi chú: ghi chú hiện đầu màn duyệt.

**Luồng ngoại lệ.**

- Đặc tả còn lỗi: ERR-02-006 (422), ERR-02-007 (422) hoặc ERR-02-008 (422); "Đặc tả còn lỗi, mở kết quả kiểm tra để xem hướng dẫn sửa."
- Thiếu điều kiện: ERR-02-012 (409); "Chưa đủ điều kiện gửi duyệt: {danh sách}."
- Có thay đổi phá vỡ mà giữ số chính: ERR-02-017 (409); "Có {n} thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại."
- Phiên bản không `DRAFT`: ERR-02-011 (409); "Chỉ phiên bản nháp mới gửi duyệt được."
- Vi phạm quyền: ERR-02-014 (403).

**Đầu ra.** `202`, `reviewRequestId`; phiên bản `PENDING`, `ETag` mới.

**Kết quả.** Hồ sơ đã nằm trong hộp việc của người duyệt, nội dung được khóa.

**Hậu điều kiện.** Phiên bản `PENDING`; yêu cầu duyệt `PENDING`; đặc tả, backend, gói, SLA bị khóa đến khi có quyết định.

**Sự kiện phát ra.** EVT-02-04 (`version.submitted`).

**Kiểm toán.** Có: người gửi, băm đặc tả, tóm tắt kiểm tra, ghi chú.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-003; BR-02-008; BR-02-024; BR-02-028; BR-02-015.

**Màn hình, API.** UI-02-02, UI-02-03 bước 5; API-02-042, API-02-043.
:::

#### FR-02-035 · Duyệt hoặc từ chối công bố (bốn mắt)

::: dac-ta
**Mục đích.** Cho người duyệt dịch vụ (CA) xem xét hồ sơ và quyết định cho phép công bố, trả lại để sửa, hoặc từ chối, theo nguyên tắc bốn mắt. Cùng màn hình duyệt dùng cho cả công bố gói, ngừng khuyến nghị, ngừng hẳn, nâng mức hiển thị, thay đổi backend và đăng ký sử dụng.

**Tác nhân, quyền.** CA, TA có `PERM-02-publish` (đăng ký sử dụng: thêm SV ○ có `PERM-02-approve-subscription`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-005; FR-00-070, 071, 072; D02-08 §4 (SV khác CA).

**Tiền điều kiện.** Có yêu cầu duyệt ở trạng thái `PENDING`; loại yêu cầu thuộc `VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, `PLAN_CLOSE`, `SUBSCRIPTION_RENEW`. Trạng thái yêu cầu duyệt ở API là `PENDING`, `APPROVED`, `REJECTED`, `WITHDRAWN`.

**Kích hoạt.** Người duyệt mở yêu cầu từ "Việc của tôi" (UI-02-10, `/viec-cua-toi`).

**Đầu vào.** `reviewRequestId`; `decision` (`APPROVE`, `REJECT`); `comment` (T-TEXT, bắt buộc khi từ chối); `acknowledgedWarnings[]` (mã cảnh báo người duyệt đã xem).

**Luồng xử lý chính.**

1. Người duyệt mở yêu cầu; hệ thống hiển thị hồ sơ theo loại: với `VERSION_PUBLISH` là thông tin API, đặc tả (trình xem), kết quả kiểm tra ba lớp, kết quả chạy thử TEST, backend, gói, SLA, phân loại, mức hiển thị, danh sách API gần giống, báo cáo khác biệt với phiên bản trước (FR-02-043).
2. Hệ thống kiểm tra người duyệt khác người gửi, người sửa gần nhất đặc tả hoặc gói, và không giữ vai trò SV của chính API này (BR-02-008, ERR-02-013).
3. Người duyệt rà soát các điểm bắt buộc: phân loại dữ liệu hợp lý, kiểu xác thực của gói, hạn mức, SLA, API gần giống; tick xác nhận các cảnh báo còn mở.
4. Người duyệt chọn "Duyệt" hoặc "Trả lại" kèm ý kiến (từ chối bắt buộc có lý do, ERR-02-041).
5. Nếu API có `dataClass = SENSITIVE`, hệ thống yêu cầu thêm một xác nhận của TA (người thứ hai khác CA); yêu cầu ở trạng thái `AWAITING_SECOND` cho tới khi đủ (BR-02-008).
6. Khi đủ duyệt, hệ thống kiểm tra lại các điều kiện lần cuối (đặc tả không đổi: băm khớp; không có lỗi mới), rồi chạy hành động theo loại: `VERSION_PUBLISH` chuyển FR-02-036 (môi trường thật); các loại khác chạy FR tương ứng (030, 031, 032, 038, 039, 041, 047).
7. Hệ thống ghi kiểm toán quyết định, gửi thông báo cho người gửi và, nếu duyệt, phát sự kiện tương ứng.

**Luồng thay thế.** Người duyệt chọn "Hỏi thêm": yêu cầu về `CLARIFICATION`, người gửi trả lời trên cùng yêu cầu, không đổi nội dung bị khóa; không tính là quyết định. Yêu cầu quá `02.review.overdue-days` ngày làm việc: hệ thống nhắc người duyệt và báo TA (EVT-02-16).

**Luồng ngoại lệ.**

- Vi phạm bốn mắt: ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."
- Từ chối không có lý do: ERR-02-041 (400); "Cần nêu lý do khi trả lại."
- Hồ sơ đã đổi sau khi gửi (băm lệch, trường hợp hiếm): ERR-02-015 (412); "Hồ sơ đã thay đổi sau khi gửi duyệt. Mở lại để xem."
- Yêu cầu đã được người khác xử lý: ERR-02-011 (409); "Yêu cầu này đã có quyết định."
- Không có quyền với loại yêu cầu: ERR-02-014 (403).

**Đầu ra.** `200`; yêu cầu duyệt với `decision`, `decidedBy`, `decidedAt`; đối tượng sau hành động (nếu duyệt, ví dụ phiên bản `PENDING` chuyển sang bước công bố).

**Kết quả.** Hồ sơ được quyết định có người thứ hai chịu trách nhiệm; người gửi nhận thông báo kèm ý kiến.

**Hậu điều kiện.** Yêu cầu duyệt `APPROVED` hoặc `REJECTED`; đối tượng chuyển theo hành động, nếu bị trả lại thì về `DRAFT` hoặc `STAGING`.

**Sự kiện phát ra.** Tùy loại: EVT-02-05, EVT-02-06, EVT-02-08, EVT-02-11 (xem từng FR liên quan).

**Kiểm toán.** Có: người gửi, người duyệt, quyết định, ý kiến, cảnh báo đã xác nhận, băm hồ sơ.

**Quy tắc nghiệp vụ.** BR-02-008; BR-02-026; BR-02-028.

**Màn hình, API.** UI-02-10; API-02-044, API-02-045, API-02-046, API-02-098 (chi tiết yêu cầu duyệt).
:::

```{.mermaid caption="Trình tự duyệt bốn mắt một yêu cầu công bố"}
sequenceDiagram
  autonumber
  participant SV as Chủ dịch vụ
  participant C as PH-02
  participant H as Việc của tôi
  participant CA as Người duyệt
  participant TA as Quản trị tenant
  SV->>C: Gửi duyệt phiên bản
  C->>C: Kiểm tra điều kiện, khóa nội dung
  C->>H: Tạo việc VERSION_PUBLISH cho CA
  CA->>H: Mở việc
  H->>C: Lấy hồ sơ, kết quả kiểm tra, API gần giống
  CA->>C: Duyệt kèm ý kiến
  C->>C: Kiểm tra bốn mắt, băm hồ sơ không đổi
  alt API mức SENSITIVE
    C->>H: Tạo việc xác nhận lần hai cho TA
    TA->>C: Xác nhận
  end
  C->>C: Chạy công bố ra gateway FR-02-036
  C-->>SV: Thông báo kết quả
```

Hình trên cho thấy việc duyệt luôn đi qua "Việc của tôi" dùng chung, không có đường tắt; riêng dữ liệu Nhạy cảm cần người thứ hai sau CA.

#### FR-02-036 · Công bố API ra gateway và danh mục

::: dac-ta
**Mục đích.** Biến một phiên bản đã được duyệt thành API thật gọi được qua cổng, đồng thời xuất bản vào danh mục. Chức năng này cũng cho chủ dịch vụ **thử** phiên bản `DRAFT` ở môi trường TEST hoặc STAGING (không cần duyệt) để kiểm tra bằng lời gọi thật trước khi nộp.

**Tác nhân, quyền.** Hệ thống (sau duyệt, môi trường thật); SV (○), TA có `PERM-02-create` (chế độ thử TEST, STAGING); TO có `PERM-02-operate` (thử lại).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-004; LGC-APIM-006; SRS cũ FR-02-004, 005 (`PUBLISHED`); ADR-005, ADR-013; SEC-43; NFR-02-005.

**Tiền điều kiện.** Chế độ môi trường thật: yêu cầu duyệt đủ quyết định `APPROVE`. Chế độ thử: phiên bản `DRAFT` đạt kiểm tra đặc tả; backend và gói có cấu hình cho môi trường thử.

**Kích hoạt.** Sau quyết định duyệt cuối của FR-02-035; hoặc người dùng bấm "Thử trên TEST"; hoặc TO bấm "Thử lại công bố" (API-02-047).

**Đầu vào.** `apiCode`, `versionNo`, `environment` (`TEST`, `STAGING`, `PROD`); khi thử lại: `reviewRequestId`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra điều kiện theo chế độ; môi trường `PROD` chỉ chạy khi có duyệt và băm đặc tả khớp bản đã duyệt (ERR-02-012).
2. Hệ thống dựng bộ cấu hình công bố: một route cho mỗi thao tác trong đặc tả (chỉ các thao tác có trong đặc tả được phép, SEC-43), upstream từ danh sách backend `ACTIVE` kèm cân bằng tải và kiểm tra sức khỏe, nhóm consumer và chính sách cho từng gói `PUBLISHED`, lược đồ kiểm tra yêu cầu sinh từ đặc tả.
3. Nếu phiên bản cùng số chính với một phiên bản đang `PUBLISHED`, hệ thống kiểm tra phiên bản mới tương thích ngược (không phá vỡ) và mọi gói đang có đăng ký đều có gói cùng mã ở phiên bản mới (BR-02-035); thiếu thì dừng và liệt kê (ERR-02-012).
4. Hệ thống chuyển bộ cấu hình cho mô-đun PH-03 trong `dh-connect` để sinh ảnh chụp cấu hình có chữ ký và số phiên bản tăng dần; PH-03 ghi ảnh chụp vào kho cấu hình gateway và chờ APISIX xác nhận đã nạp số phiên bản đó (độ trễ lan truyền ≤ 10 giây, D03-09 §6.1).
5. Nhận xác nhận trong 30 giây: hệ thống chuyển phiên bản sang `PUBLISHED` (môi trường `PROD`), đặt `publishedAt`, chuyển các gói `STAGING` đi kèm sang `PUBLISHED`; nếu có phiên bản cũ cùng số chính thì chuyển đăng ký `ACTIVE` sang gói cùng mã của phiên bản mới và đưa phiên bản cũ sang `RETIRED` với lý do `SUPERSEDED`.
6. Hệ thống cập nhật chỉ mục danh mục, xếp đồng bộ quốc gia nếu mức hiển thị `NATIONAL`, `PUBLIC` (FR-02-053), phát sự kiện, thông báo người gửi và (nếu có) các bên khai thác của phiên bản cũ.
7. Chế độ thử: hệ thống chỉ nạp bộ cấu hình vào gateway của môi trường thử, ghi `lastTestDeploy {env, sha256, at, result}` cho điều kiện của FR-02-034, không đổi trạng thái vòng đời, không đồng bộ quốc gia, không phát thông báo bên khai thác.

**Luồng thay thế.** Phiên bản mới cùng số chính có gói khác mã: người duyệt chọn ánh xạ gói tại bước duyệt, hệ thống dùng ánh xạ đó ở bước 5.

**Luồng ngoại lệ.**

- PH-03 hoặc APISIX không xác nhận trong 30 giây: ERR-02-033 (503); phiên bản giữ `PENDING`, hệ thống thử lại tối đa 5 lần trong 15 phút lùi dần, sau đó cảnh báo TO; màn hình báo người gửi "Cổng API chưa nhận cấu hình, hệ thống đang thử lại."
- Xung đột context-path phát sinh sau khi duyệt: ERR-02-019 (422); phiên bản giữ `PENDING`, báo TA.
- Băm đặc tả khác bản đã duyệt: ERR-02-015 (412); không công bố, đưa về `DRAFT` và báo cả hai bên.
- Phiên bản mới phá vỡ tương thích nhưng cùng số chính: ERR-02-017 (409).

**Đầu ra.** `200` (đã công bố) hoặc `202` (đang đẩy cấu hình): `status`, `publishedAt`, `gatewayConfigVersion`, `publishedUrl`.

**Kết quả.** API gọi được qua cổng ở địa chỉ công bố và xuất hiện trong danh mục; chủ dịch vụ nhận thông báo.

**Hậu điều kiện.** Phiên bản `PUBLISHED`; route, upstream, consumer có ở gateway; bản ghi đồng bộ quốc gia đã xếp (nếu có); phiên bản cũ cùng số chính (nếu có) đã `RETIRED`.

**Sự kiện phát ra.** EVT-02-05 (`version.published`); EVT-02-06 cho phiên bản cũ (nếu `RETIRED`); EVT-02-12 (thông báo bên khai thác khi có phiên bản thay thế).

**Kiểm toán.** Có: người duyệt, số phiên bản cấu hình gateway, băm cấu hình, kết quả, thời gian từ duyệt tới gọi được.

**Quy tắc nghiệp vụ.** BR-02-001; BR-02-003; BR-02-014; BR-02-022; BR-02-035.

**Màn hình, API.** UI-02-02, UI-02-10; API-02-047, API-02-082 (xác nhận nạp từ PH-03).
:::

#### FR-02-037 · Tạm ngừng và tiếp tục API

::: dac-ta
**Mục đích.** Cho cán bộ vận hành hoặc Cán bộ ATTT chặn ngay một API khi phát hiện lỗi nghiêm trọng hoặc sự cố an ninh, rồi cho chạy lại khi đã xử lý. Đây là lệnh Stop/Start của hệ cũ, nay có lý do, thời hạn và kiểm toán.

**Tác nhân, quyền.** SO, TO, TA có `PERM-02-operate`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-005 (cùng PH-03); SEC-72 (ứng phó sự cố).

**Tiền điều kiện.** Phiên bản `PUBLISHED` (tạm ngừng) hoặc `SUSPENDED` (tiếp tục).

**Kích hoạt.** Người dùng bấm "Tạm ngừng" hoặc "Tiếp tục" ở UI-02-02.

**Đầu vào.** `apiCode`, `versionNo`; `reason` (bắt buộc); `category` (`SECURITY`, `BACKEND_FAILURE`, `LEGAL`, `OTHER`); `expectedResumeAt` (T-TS, tùy chọn).

**Luồng xử lý chính.**

1. Người dùng bấm "Tạm ngừng", chọn nhóm lý do, nhập lý do và xác nhận (FR-00-050); hệ thống kiểm tra phiên bản `PUBLISHED` (ERR-02-011).
2. Hệ thống chuyển phiên bản `SUSPENDED`, đặt `suspendedBy`, `suspendedAt`, `suspendDeadline` = hiện tại + `02.suspend.max-days` (mặc định 30).
3. Hệ thống yêu cầu PH-03 đẩy cấu hình mới: route trả `503` thân RFC 9457 mã `API_SUSPENDED`, tiêu đề `Retry-After` nếu có `expectedResumeAt`; không gỡ consumer, không đổi đăng ký (hiệu lực ≤ 30 giây, NFR-02-005).
4. Hệ thống gửi thông báo bắt buộc cho mọi bên đăng ký `ACTIVE` (BR-02-029) và cho chủ dịch vụ, nêu lý do ở mức tổng quát (không lộ chi tiết sự cố ATTT).
5. Khi tiếp tục: người dùng bấm "Tiếp tục" kèm ghi chú; hệ thống kiểm tra quyền tiếp tục theo BR-02-034 (người đã ngừng hoặc TA; nếu SO ngừng vì `SECURITY` thì chỉ SO hoặc TA), kiểm tra backend khỏe (FR-02-025) và khôi phục route.
6. Sau 80% thời hạn tạm ngừng mà chưa tiếp tục, hệ thống nhắc TA; quá hạn thì tạo việc bắt buộc: tiếp tục hoặc ngừng khuyến nghị (FR-02-038).

**Luồng thay thế.** Tạm ngừng do sự cố khẩn: SO, TO không cần duyệt (BR-02-034); hệ thống ghi nhãn "Khẩn" và thông báo TA ngay.

**Luồng ngoại lệ.**

- Phiên bản không `PUBLISHED`: ERR-02-011 (409); "Chỉ API đang công bố mới tạm ngừng được."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do tạm ngừng."
- Người tiếp tục không đủ quyền theo BR-02-034: ERR-02-014 (403); "Chỉ người đã tạm ngừng hoặc quản trị tenant mới tiếp tục được."
- PH-03 không nhận: ERR-02-033 (503); "Cổng API chưa nhận lệnh. Hệ thống đang thử lại."

**Đầu ra.** `200`; phiên bản `SUSPENDED` hoặc `PUBLISHED`, `suspendDeadline`.

**Kết quả.** API bị chặn (hoặc phục hồi) trong vòng 30 giây, bên khai thác nhận thông báo.

**Hậu điều kiện.** Trạng thái đổi; cấu hình gateway cập nhật; đăng ký không đổi.

**Sự kiện phát ra.** EVT-02-06 (`version.state-changed`); EVT-02-12.

**Kiểm toán.** Có: người thực hiện, nhóm lý do, lý do, thời hạn, thời điểm hiệu lực ở gateway.

**Quy tắc nghiệp vụ.** BR-02-028; BR-02-029; BR-02-034.

**Màn hình, API.** UI-02-02; API-02-048, API-02-049.
:::

#### FR-02-038 · Ngừng khuyến nghị API có lộ trình

::: dac-ta
**Mục đích.** Cho chủ dịch vụ thông báo trước một phiên bản sẽ ngừng, kèm phiên bản kế nhiệm và hạn chuyển đổi, để bên khai thác có thời gian nâng cấp. Đây là trạng thái quan trọng nhất về mặt vận hành: ngừng đột ngột một API nhiều hệ thống dùng gây gián đoạn dây chuyền.

**Tác nhân, quyền.** SV (○), TA gửi (`PERM-02-submit`); CA, TA duyệt (`PERM-02-publish`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-007; LGC-APIM-008 (ngừng dùng có báo trước); Q02-04.

**Tiền điều kiện.** Phiên bản `PUBLISHED` hoặc `SUSPENDED`.

**Kích hoạt.** Người dùng bấm "Ngừng khuyến nghị" ở UI-02-02, mở UI-02-13 (lộ trình ngừng dùng).

**Đầu vào.** `apiCode`, `versionNo`; `successorVersionNo` (tùy chọn); `sunsetAt` (T-DATE); `reason` (T-TEXT, bắt buộc); `migrationGuide` (T-TEXT); `confirmNoSuccessor` (T-BOOL).

**Luồng xử lý chính.**

1. SV chọn phiên bản, phiên bản kế nhiệm và hạn chuyển đổi; hệ thống hiển thị số bên đăng ký `ACTIVE` và các bên chưa có đăng ký ở phiên bản kế nhiệm (FR-02-044).
2. Hệ thống kiểm tra phiên bản kế nhiệm `PUBLISHED` cùng API và số hiệu cao hơn (ERR-02-018); thiếu kế nhiệm thì cần `confirmNoSuccessor = true` và hiện cảnh báo "ngừng hẳn dịch vụ" (ERR-02-032).
3. Hệ thống kiểm tra `sunsetAt` ≥ hôm nay + `02.deprecation.min-days` (mặc định 180 ngày, BR-02-004); ngắn hơn chỉ chấp nhận khi có lý do khẩn chính đáng và TA đồng ý trong yêu cầu duyệt (ERR-02-031).
4. Hệ thống tạo yêu cầu duyệt `VERSION_DEPRECATE` kèm lộ trình; CA, TA duyệt (FR-02-035).
5. Khi duyệt, hệ thống chuyển phiên bản `DEPRECATED`, đặt `sunsetAt`, `successorVersionId`; các gói của phiên bản chuyển `DEPRECATED` (FR-02-031).
6. Hệ thống yêu cầu PH-03 thêm tiêu đề `Deprecation`, `Sunset` và `Link: rel="successor-version"` vào mọi phản hồi của phiên bản (RFC 9745, RFC 8594) và phát thông báo bắt buộc cho mọi bên đăng ký `ACTIVE` kèm hướng dẫn chuyển (FR-02-057).
7. Hệ thống lập lịch nhắc ở mốc 90, 30, 7 ngày trước hạn và hằng tuần trong tháng cuối cho các bên chưa chuyển; tháng cuối còn ai gọi thì báo cả chủ dịch vụ và TA.

**Luồng thay thế.** Chủ dịch vụ rút đề nghị khi chưa duyệt: yêu cầu `WITHDRAWN`, phiên bản giữ nguyên. Đổi `sunsetAt` sau khi đã `DEPRECATED`: chỉ được lùi ra xa hơn, không rút ngắn, không cần duyệt lại; hệ thống thông báo lại.

**Luồng ngoại lệ.**

- Thiếu kế nhiệm mà không xác nhận: ERR-02-032 (422); "Chưa có phiên bản kế nhiệm. Chọn phiên bản kế nhiệm hoặc xác nhận ngừng hẳn dịch vụ."
- Hạn quá ngắn: ERR-02-031 (422); "Hạn chuyển đổi tối thiểu {n} ngày. Chọn ngày muộn hơn {ngày}."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do ngừng khuyến nghị."
- Phiên bản không ở trạng thái cho phép: ERR-02-011 (409).
- PH-03 không nhận tiêu đề cảnh báo: ERR-02-033 (503); trạng thái vẫn chuyển, tiêu đề được thử lại, cảnh báo TO.

**Đầu ra.** `202` khi gửi (`reviewRequestId`); `200` khi duyệt; phiên bản `DEPRECATED` kèm `sunsetAt`, `successorVersionNo`, số bên chưa chuyển.

**Kết quả.** Bên khai thác biết API sẽ ngừng, ngày nào, chuyển sang đâu; mỗi lần gọi đều nhận cảnh báo trong tiêu đề phản hồi.

**Hậu điều kiện.** Phiên bản `DEPRECATED` có lộ trình; gói `DEPRECATED`; lịch nhắc đã đặt.

**Sự kiện phát ra.** EVT-02-06; EVT-02-12.

**Kiểm toán.** Có: lý do, kế nhiệm, hạn, số bên bị ảnh hưởng, người duyệt, ngoại lệ hạn ngắn.

**Quy tắc nghiệp vụ.** BR-02-004; BR-02-005; BR-02-008; BR-02-018; BR-02-029; BR-02-028.

**Màn hình, API.** UI-02-13, UI-02-10; API-02-050, API-02-044.
:::

#### FR-02-039 · Ngừng hẳn API

::: dac-ta
**Mục đích.** Cho phiên bản kết thúc đời sống một cách an toàn: gỡ khỏi gateway, đóng gói, giữ hồ sơ làm bằng chứng. Hệ thống không bao giờ tự ngừng hẳn khi còn bên khai thác. Cũng là nơi hủy một bản nháp chưa từng công bố.

**Tác nhân, quyền.** SV (○), TA gửi (`PERM-02-submit`); CA, TA duyệt (`PERM-02-publish`); hủy bản nháp: SV (○) với `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-007 (`RETIRED`); LGC-APIM-008.

**Tiền điều kiện.** Phiên bản `DEPRECATED` đã tới hạn `sunsetAt` hoặc người đề nghị chọn ngừng sớm; hoặc phiên bản `DRAFT` (hủy nháp).

**Kích hoạt.** Hệ thống đưa ra đề nghị khi tới hạn `sunsetAt`; hoặc người dùng bấm "Ngừng hẳn" ở UI-02-13; hoặc "Hủy bản nháp" ở UI-02-02.

**Đầu vào.** `apiCode`, `versionNo`; `reason` (bắt buộc); `force` (không có: hệ thống không có tùy chọn bỏ qua đăng ký).

**Luồng xử lý chính.**

1. Tới hạn `sunsetAt`, hệ thống đếm đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` còn lại của phiên bản và số lượt gọi 7 ngày gần nhất (FR-02-044).
2. Nếu còn đăng ký hiệu lực (BR-02-006): không tự ngừng; hệ thống báo SV, CA, TA "Còn {n} bên đang dùng", nhắc lại hằng tuần và gợi ý gia hạn lộ trình (đổi `sunsetAt`) hoặc thu hồi đăng ký (FR-02-051).
3. Nếu không còn đăng ký: SV hoặc hệ thống tạo yêu cầu duyệt `VERSION_RETIRE`; CA duyệt.
4. Khi duyệt, hệ thống chuyển phiên bản `RETIRED`, yêu cầu PH-03 gỡ route và consumer của phiên bản, chuyển các gói còn lại sang `CLOSED`.
5. Hệ thống giữ chỗ context-path 12 tháng (FR-02-024), giữ vĩnh viễn đặc tả và lịch sử (BR-02-014), cập nhật danh mục (mục chuyển sang "Đã ngừng"), xếp thông báo rút danh mục quốc gia (FR-02-053).
6. Hệ thống phát thông báo cho chủ dịch vụ, người duyệt và các bên từng đăng ký (đã đóng trước đó).
7. Hủy bản nháp: SV nhập lý do và xác nhận; hệ thống chuyển `DRAFT` sang `RETIRED` không qua duyệt, không có route nào để gỡ.

**Luồng thay thế.** Người đề nghị chọn "Ngừng sớm trước hạn" khi không còn đăng ký: cho phép với duyệt CA, không cần chờ `sunsetAt`.

**Luồng ngoại lệ.**

- Còn đăng ký hiệu lực: ERR-02-030 (409); "Còn {n} bên đang dùng phiên bản này. Chuyển hoặc thu hồi đăng ký trước, hoặc lùi hạn ngừng."
- Phiên bản không `DEPRECATED` hoặc `DRAFT`: ERR-02-011 (409); "Chỉ phiên bản đã ngừng khuyến nghị mới ngừng hẳn được."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do."
- PH-03 không gỡ được: ERR-02-033 (503); phiên bản giữ `DEPRECATED` cho tới khi gỡ xong.

**Đầu ra.** `202` khi gửi; `200` khi duyệt; phiên bản `RETIRED`.

**Kết quả.** Phiên bản kết thúc an toàn, không ai bị ngắt bất ngờ, hồ sơ được giữ.

**Hậu điều kiện.** Phiên bản `RETIRED`; route, consumer đã gỡ; gói `CLOSED`; context-path được giữ chỗ; đặc tả giữ vĩnh viễn.

**Sự kiện phát ra.** EVT-02-06; EVT-02-12.

**Kiểm toán.** Có: lý do, số đăng ký tại thời điểm ngừng, người duyệt, thời điểm gỡ ở gateway.

**Quy tắc nghiệp vụ.** BR-02-006; BR-02-008; BR-02-014; BR-02-028; BR-02-029.

**Màn hình, API.** UI-02-13, UI-02-10; API-02-051, API-02-044.
:::

#### FR-02-040 · Xóa API

::: dac-ta
**Mục đích.** Cho chủ dịch vụ gỡ khỏi danh mục một API đã khai nhầm hoặc không còn dùng, nhưng chỉ khi không còn ai đăng ký sử dụng, đúng nguyên tắc ngừng dùng phải có báo trước của hệ mới. Xóa là xóa mềm, hồ sơ vẫn giữ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create` (nhóm tạo, sửa, xóa mềm của D02-08).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-008; FR-00-051 (xóa mềm).

**Tiền điều kiện.** Mọi phiên bản của API ở `DRAFT` hoặc `RETIRED`; không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-020).

**Kích hoạt.** Người dùng bấm "Xóa API" ở UI-02-02 (menu "⋯").

**Đầu vào.** `apiCode`; `reason` (bắt buộc); `confirmCode` (T-CODE, người dùng gõ lại mã API để xác nhận).

**Luồng xử lý chính.**

1. Người dùng bấm "Xóa API"; hệ thống hiển thị tác động: số phiên bản, số đăng ký lịch sử, số phiên bản còn `PUBLISHED`, `DEPRECATED`, `SUSPENDED`.
2. Người dùng nhập lý do và gõ lại mã API để xác nhận (FR-00-050); sai mã thì không cho tiếp (ERR-02-003).
3. Hệ thống kiểm tra mọi phiên bản `DRAFT` hoặc `RETIRED` và không còn đăng ký hiệu lực; không đạt thì từ chối và chỉ ra việc cần làm trước: ngừng khuyến nghị, ngừng hẳn, thu hồi đăng ký (ERR-02-030).
4. Hệ thống xóa mềm API (đặt `deletedAt`), giữ vĩnh viễn đặc tả, phiên bản, đăng ký lịch sử (BR-02-014), giữ chỗ mã và context-path vĩnh viễn (BR-02-021).
5. Hệ thống rút API khỏi danh mục và chỉ mục tìm kiếm, xếp thông báo rút danh mục quốc gia nếu đã đồng bộ.
6. Hệ thống ghi kiểm toán và thông báo chủ dịch vụ và TA.

**Luồng thay thế.** TA khôi phục API đã xóa mềm trong vòng 30 ngày (FR-00-051): API trở lại với phiên bản `RETIRED`, `DRAFT` như trước khi xóa.

**Luồng ngoại lệ.**

- Còn phiên bản đang chạy hoặc còn đăng ký: ERR-02-030 (409); "API còn phiên bản đang phục vụ hoặc còn {n} bên đăng ký. Ngừng dùng có báo trước trước khi xóa."
- Gõ sai mã xác nhận: ERR-02-003 (400); "Mã xác nhận không khớp."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do xóa."
- Không có quyền: ERR-02-014 (403).

**Đầu ra.** `204`.

**Kết quả.** API biến khỏi danh mục, lịch sử vẫn tra cứu được bởi TA, kiểm toán viên.

**Hậu điều kiện.** API xóa mềm; mã giữ chỗ; thông báo rút danh mục quốc gia đã xếp.

**Sự kiện phát ra.** EVT-02-03 (`api.deleted`).

**Kiểm toán.** Có: lý do, số phiên bản, số đăng ký lịch sử, người xóa.

**Quy tắc nghiệp vụ.** BR-02-014; BR-02-020; BR-02-021; BR-02-028.

**Màn hình, API.** UI-02-02; API-02-052.
:::

#### FR-02-041 · Đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển

::: dac-ta
**Mục đích.** Cho chủ dịch vụ quyết định API được thấy tới đâu: chỉ HTTT trong tỉnh, lên danh mục quốc gia cho cơ quan khác, hoặc công khai cho cả cộng đồng nhà phát triển; và cho bật, tắt việc hiện API ở cổng nhà phát triển PH-15. Thay cho Publish, Unpublish, Make Public của hệ cũ.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create` (hạ mức, gỡ cổng); nâng mức cần `PERM-02-submit` rồi CA `PERM-02-publish`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-006; LGC-APIM-007 (PH-15 chính, PH-02 giữ thuộc tính); CMP-LAW-03.

**Tiền điều kiện.** API có phiên bản `PUBLISHED` hoặc `DEPRECATED` (với phiên bản nháp, mức hiển thị chỉ là dự định).

**Kích hoạt.** Người dùng sửa khối "Hiển thị" ở UI-02-02.

**Đầu vào.** `visibility` (`TENANT`, `NATIONAL`, `PUBLIC`); `portalPublished` (T-BOOL); `reason` (bắt buộc khi nâng mức).

**Luồng xử lý chính.**

1. Người dùng chọn mức hiển thị và công tắc "Hiện ở cổng nhà phát triển"; hệ thống giải thích hệ quả từng mức.
2. Hệ thống kiểm tra ràng buộc theo `dataClass` (BR-02-037): `PUBLIC` chỉ với dữ liệu `PUBLIC`; `NATIONAL` không với `SENSITIVE`; vi phạm thì ERR-02-043.
3. Nếu hạ mức hoặc gỡ khỏi cổng: hệ thống áp ngay, cập nhật danh mục, phát sự kiện cho PH-15, xếp đồng bộ quốc gia (rút bản ghi nếu hạ xuống `TENANT`).
4. Nếu nâng mức lên `NATIONAL` hoặc `PUBLIC`: hệ thống tạo yêu cầu duyệt `VISIBILITY_RAISE` (CA duyệt, FR-02-035); sau duyệt áp mức mới và xếp đồng bộ quốc gia.
5. Hệ thống đặt `portalPublished`: PH-15 chỉ hiển thị API `PUBLISHED`, `DEPRECATED` có `portalPublished = true` và đúng mức hiển thị theo người xem.
6. Hệ thống ghi kiểm toán.

**Luồng thay thế.** Hạ mức khi đang có bên nước ngoài tenant đã gọi (qua Nền tảng quốc gia): cảnh báo trước khi áp, thông báo bên đăng ký (FR-02-057).

**Luồng ngoại lệ.**

- Mức không phù hợp mức phân loại: ERR-02-043 (422); "Mức hiển thị {mức} không phù hợp với dữ liệu mức {phân loại}."
- Nâng mức khi thiếu lý do: ERR-02-041 (400); "Cần nêu lý do nâng mức hiển thị."
- API chưa có phiên bản công bố mà đòi hiện ở cổng: ERR-02-011 (409); "API chưa công bố nên chưa hiện ở cổng nhà phát triển được."

**Đầu ra.** `200`; API với `visibility`, `portalPublished`; hoặc `202` khi chờ duyệt nâng mức.

**Kết quả.** API hiển thị đúng đối tượng; cổng nhà phát triển phản ánh trong vài giây.

**Hậu điều kiện.** `visibility`, `portalPublished` cập nhật; đồng bộ quốc gia xếp hàng khi cần.

**Sự kiện phát ra.** EVT-02-02 (`changedFields = visibility, portalPublished`).

**Kiểm toán.** Có: mức trước, sau, lý do, người duyệt nâng mức.

**Quy tắc nghiệp vụ.** BR-02-008; BR-02-009; BR-02-037.

**Màn hình, API.** UI-02-02 tab Tổng quan, UI-02-10; API-02-053.
:::

#### FR-02-042 · Tạo phiên bản mới

::: dac-ta
**Mục đích.** Cho chủ dịch vụ phát triển API tiếp từ phiên bản đã có: sao chép đặc tả, backend, gói, SLA làm nền để sửa, thay vì dựng lại từ đầu. Phiên bản mới là cách duy nhất đổi hợp đồng của API đã công bố.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-006; BR-02-003; BR-02-035.

**Tiền điều kiện.** API có phiên bản nguồn ở trạng thái `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED`; không có phiên bản `DRAFT` hoặc `PENDING` khác của API (mỗi API chỉ một bản đang soạn).

**Kích hoạt.** Người dùng bấm "Tạo phiên bản mới" ở tab Phiên bản của UI-02-02.

**Đầu vào.** `fromVersionNo`; `versionNo` đề xuất (`MAJOR.MINOR.PATCH`); `copy` (`spec`, `backends`, `plans`, `sla`, mặc định cả bốn).

**Luồng xử lý chính.**

1. Người dùng chọn phiên bản nguồn và các thành phần cần sao chép.
2. Hệ thống đề xuất số hiệu tiếp theo theo mức thay đổi dự kiến: vá lỗi tăng `PATCH`, thêm tương thích tăng `MINOR`, phá vỡ tăng `MAJOR`; người dùng nhập số hiệu, hệ thống kiểm tra đúng định dạng, lớn hơn mọi phiên bản hiện có và chưa dùng kể cả đã xóa (ERR-02-018, ERR-02-002).
3. Hệ thống tạo phiên bản `DRAFT` mới, sao chép thành phần được chọn; gói sao chép theo FR-02-033; đường dẫn sinh theo số chính mới (FR-02-024).
4. Số chính khác phiên bản `PUBLISHED` hiện tại: hệ thống nói rõ phiên bản mới sẽ chạy **song song** ở đường dẫn mới. Cùng số chính: phiên bản mới sẽ **thay thế** phiên bản hiện tại khi công bố và chỉ được phép nếu tương thích ngược (BR-02-035).
5. Hệ thống ghi kiểm toán, trả phiên bản mới ở `DRAFT`; người dùng sửa đặc tả (FR-02-011, 014) rồi so sánh (FR-02-043) trước khi gửi duyệt.

**Luồng thay thế.** Người dùng chọn "Không sao chép đặc tả" để nạp đặc tả hoàn toàn mới (đổi lớn).

**Luồng ngoại lệ.**

- Đã có bản nháp khác: ERR-02-011 (409); "API đã có phiên bản đang soạn {số}. Hoàn tất hoặc hủy bản đó trước."
- Số hiệu không hợp lệ hoặc không tăng: ERR-02-018 (422); "Số phiên bản phải dạng MAJOR.MINOR.PATCH và lớn hơn {số hiện có}."
- Số hiệu đã dùng: ERR-02-002 (409).
- Vượt số phiên bản tối đa (50): ERR-02-040 (422).

**Đầu ra.** `201`, tiêu đề `Location`; phiên bản mới `DRAFT` kèm các thành phần đã sao chép.

**Kết quả.** Chủ dịch vụ có bản nháp phiên bản mới với nội dung phiên bản cũ làm nền.

**Hậu điều kiện.** Phiên bản `DRAFT` mới; phiên bản nguồn không đổi.

**Sự kiện phát ra.** EVT-02-02 (`changedFields = versions`).

**Kiểm toán.** Có: số hiệu nguồn, số hiệu mới, thành phần sao chép.

**Quy tắc nghiệp vụ.** BR-02-003; BR-02-014; BR-02-035; BR-02-021.

**Màn hình, API.** UI-02-02 tab Phiên bản; API-02-054.
:::

#### FR-02-043 · So sánh phiên bản và phân loại thay đổi phá vỡ

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và người duyệt thấy chính xác hai phiên bản khác nhau ở đâu và thay đổi nào làm hỏng bên khai thác hiện tại. Chủ dịch vụ thường không nhận ra thêm một trường bắt buộc là phá vỡ; phân loại tự động phát hiện trước khi gây sự cố.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read` (chủ dịch vụ, CA dùng chính); hệ thống khi gửi duyệt.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-006; BR-02-003; NFR-02-004.

**Tiền điều kiện.** Hai phiên bản của cùng API đều có đặc tả đạt lớp 1.

**Kích hoạt.** Người dùng mở UI-02-05 (`/ket-noi/api/{ma}/so-sanh?tu=&den=`); hệ thống tự chạy khi gửi duyệt (FR-02-034 bước 4).

**Đầu vào.** `apiCode`; `from`, `to` (hai `versionNo`; mặc định so với phiên bản `PUBLISHED` hiện tại).

**Luồng xử lý chính.**

1. Hệ thống đọc hai đặc tả đã gộp tham chiếu và chuẩn hóa để so sánh theo cấu trúc (không so văn bản thô).
2. Hệ thống tính từng thay đổi ở các cấp: đường dẫn, thao tác, tham số, thân yêu cầu, thân và mã phản hồi, lược đồ, bảo mật.
3. Hệ thống phân loại mỗi thay đổi theo bảng dưới thành `BREAKING`, `COMPATIBLE` hoặc `UNCERTAIN`.
4. Hệ thống tổng hợp: `breaking = true` nếu có ít nhất một `BREAKING`; đề xuất số hiệu tiếp theo (tăng `MAJOR` khi `breaking`; `MINOR` khi thêm tương thích; `PATCH` khi chỉ sửa mô tả, ví dụ).
5. Hệ thống đối chiếu với số hiệu phiên bản `to`: có `BREAKING` mà số chính không tăng thì cờ `versionViolation = true` (chặn ở FR-02-034, ERR-02-017).
6. Hệ thống hiển thị hai nhóm thay đổi (đỏ phá vỡ, xanh tương thích) với mô tả tác động, và xem đặc tả song song (`CMP-DiffViewer`); thay đổi `UNCERTAIN` cần người dùng xác nhận tay là phá vỡ hay không, kèm lý do, trước khi gửi duyệt.

**Luồng thay thế.** Người dùng bấm "Tạo lộ trình ngừng dùng" ở UI-02-05 để mở UI-02-13 với phiên bản kế nhiệm và hạn tối thiểu điền sẵn (FR-02-038).

**Luồng ngoại lệ.**

- Một trong hai phiên bản không có hoặc không có đặc tả hợp lệ: ERR-02-001 (404) hoặc ERR-02-006 (422); "Cần đặc tả hợp lệ ở cả hai phiên bản để so sánh."
- So sánh quá lâu (đặc tả rất lớn): chạy nền với tiến độ (FR-00-054); ERR-02-035 nếu đã có lần so sánh chạy cho cùng cặp.
- Thay đổi không xác định được: loại `UNCERTAIN`, không phải lỗi.

**Đầu ra.** `200`; `breaking`, `versionViolation`, `suggestedVersion`, `changes[]` (`class`, `kind`, `location`, `description`, `impact`), `uncertainCount`.

**Kết quả.** Chủ dịch vụ thấy ngay thay đổi nào phá vỡ và biết cần tăng số chính hay không.

**Hậu điều kiện.** Kết quả so sánh gắn với cặp phiên bản (giữ cùng yêu cầu duyệt).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với lần xem; có khi người dùng xác nhận thay đổi `UNCERTAIN` (người xác nhận, lý do).

**Quy tắc nghiệp vụ.** BR-02-003; BR-02-035.

**Màn hình, API.** UI-02-05; API-02-055.
:::

| Thay đổi | Loại | Tác động tới bên khai thác |
|---|---|---|
| Xóa đường dẫn, thao tác | `BREAKING` | Lời gọi tới thao tác đó lỗi `404` |
| Xóa trường hoặc đổi tên trường trong phản hồi | `BREAKING` | Bên đang đọc trường đó bị lỗi hoặc thiếu dữ liệu |
| Đổi kiểu dữ liệu, định dạng hoặc đơn vị của trường | `BREAKING` | Sai lệch khi phân tích dữ liệu |
| Thêm tham số hoặc trường bắt buộc vào yêu cầu | `BREAKING` | Lời gọi cũ bị từ chối `400` |
| Thu hẹp giá trị cho phép (bớt `enum`, giảm độ dài tối đa) của yêu cầu | `BREAKING` | Giá trị cũ bị từ chối |
| Đổi mã lỗi hoặc ý nghĩa mã lỗi của thao tác | `BREAKING` | Xử lý lỗi của bên khai thác sai |
| Tăng yêu cầu bảo mật (thêm phạm vi bắt buộc, đổi kiểu xác thực) | `BREAKING` | Bên đang gọi bị `401`, `403` |
| Thêm thao tác, đường dẫn mới | `COMPATIBLE` | Không |
| Thêm tham số hoặc trường tùy chọn vào yêu cầu | `COMPATIBLE` | Không |
| Thêm trường vào phản hồi | `COMPATIBLE` | Không (bên khai thác phải bỏ qua trường lạ) |
| Mở rộng `enum` của phản hồi | `UNCERTAIN` | Bên khai thác xử lý `enum` chặt có thể lỗi; cần chủ dịch vụ xác nhận |
| Nới giá trị cho phép của yêu cầu | `COMPATIBLE` | Không |
| Sửa mô tả, ví dụ, thẻ | `COMPATIBLE` | Không |
| Đổi thứ tự trường, sửa lỗi chính tả trong mô tả | `COMPATIBLE` | Không |
| Thay đổi `oneOf`, `anyOf`, `discriminator` | `UNCERTAIN` | Cần xác nhận tay |

: Phân loại thay đổi khi so sánh phiên bản

#### FR-02-044 · Phân tích tác động của thay đổi tới bên khai thác

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và người duyệt thấy trước ai sẽ bị ảnh hưởng nếu thay đổi hoặc ngừng một phiên bản: những HTTT nào đang gọi, gọi thao tác nào, bao nhiêu lượt, để quyết định có tiến hành, kéo dài lộ trình hay thương lượng với từng bên.

**Tác nhân, quyền.** SV (○) với API của mình, CA, TA có `PERM-02-read` ở mức chi tiết bên đăng ký.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-006 (`benKhaiThacBiAnhHuong`), FR-02-007.

**Tiền điều kiện.** Phiên bản có đăng ký hoặc lượt gọi; PH-13 sẵn sàng (nếu không, chỉ có phần đăng ký).

**Kích hoạt.** Người dùng mở khối "Bên bị ảnh hưởng" ở UI-02-05, UI-02-13 hoặc ở bước duyệt UI-02-10; hệ thống tự gọi khi gửi duyệt ngừng khuyến nghị, ngừng hẳn.

**Đầu vào.** `apiCode`, `versionNo`; `against` (`versionNo` kế nhiệm hoặc phiên bản so sánh, tùy chọn); `windowDays` (mặc định 30).

**Luồng xử lý chính.**

1. Hệ thống lấy danh sách đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` của phiên bản, kèm HTTT, đơn vị, gói, đầu mối kỹ thuật (từ PH-01).
2. Hệ thống lấy từ PH-13 số lượt gọi trong `windowDays` ngày của từng HTTT, chia theo thao tác (`operationId`), tỷ lệ lỗi.
3. Với `against` là phiên bản so sánh: hệ thống giao các thay đổi `BREAKING` (FR-02-043) với tập thao tác mỗi HTTT thực sự gọi, để đánh dấu bên **thật sự bị ảnh hưởng** (gọi đúng thao tác bị phá vỡ) với bên chỉ "đang đăng ký".
4. Với `against` là phiên bản kế nhiệm: hệ thống chỉ ra HTTT nào đã có đăng ký ở phiên bản kế nhiệm và HTTT nào chưa.
5. Hệ thống trả danh sách xếp theo mức ảnh hưởng (lượt gọi giảm dần) và khuyến nghị lộ trình: số bên cần chuyển, thời hạn gợi ý tối thiểu.
6. Người xem không có quyền chi tiết bên đăng ký chỉ thấy số tổng; SV chỉ thấy bên đăng ký API của mình.

**Luồng thay thế.** Người dùng bấm "Xuất danh sách" để gửi cho từng đơn vị (FR-00-030), tệp không chứa số liệu lượt gọi chi tiết theo thao tác của đơn vị khác.

**Luồng ngoại lệ.**

- PH-13 không khả dụng: ERR-02-034 (503) ghi nhật ký; kết quả chỉ có danh sách đăng ký kèm nhãn "Chưa có số lượt gọi; hiển thị theo đăng ký."
- Phiên bản không có đăng ký: trả danh sách rỗng, thông báo "Chưa có bên nào đăng ký phiên bản này."
- Không có quyền xem chi tiết: chỉ trả số tổng, không báo lỗi.

**Đầu ra.** `200`; `summary {registered, active, callers, affected}`, `affected[]` (`systemCode`, `orgCode`, `planCode`, `calls`, `errorRate`, `operations[]`, `contact`), `recommendation`.

**Kết quả.** Chủ dịch vụ biết đích danh bên nào bị ảnh hưởng và mức độ để lập lộ trình chuyển đổi hợp lý.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi người dùng xem danh sách chi tiết bên đăng ký của API không thuộc tổ chức mình (CA, TA); không với xem số tổng.

**Quy tắc nghiệp vụ.** BR-02-004; BR-02-006; BR-02-033.

**Màn hình, API.** UI-02-05, UI-02-13, UI-02-10; API-02-056.
:::

#### FR-02-045 · Chuyển chủ quản API

::: dac-ta
**Mục đích.** Cho quản trị tenant chuyển trách nhiệm một API sang đơn vị khác khi có sáp nhập, thay đổi tổ chức hoặc cán bộ nghỉ việc, để API không bị "mồ côi" mà không phải tạo lại và làm gián đoạn bên khai thác.

**Tác nhân, quyền.** TA, PA có quyền quản trị phân hệ (đề nghị, động từ `admin`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-02; Q02-07.

**Tiền điều kiện.** API chưa xóa; HTTT và đơn vị đích tồn tại và `ACTIVE` ở PH-01.

**Kích hoạt.** TA chọn "Chuyển chủ quản" ở menu "⋯" của UI-02-02.

**Đầu vào.** `apiCode`; `newOwnerOrgCode`; `newProviderSystemCode` (tùy chọn); `reason` (bắt buộc); `documentRef` (số, ngày văn bản giao, tùy chọn).

**Luồng xử lý chính.**

1. TA chọn đơn vị chủ quản mới và (nếu đổi) HTTT cung cấp mới; hệ thống kiểm tra tồn tại và `ACTIVE` ở PH-01 (ERR-02-004).
2. Hệ thống hiển thị tác động: yêu cầu duyệt đang chờ, đăng ký chờ duyệt, người dùng SV của đơn vị cũ sẽ mất quyền sửa, backend loại `SYSTEM` còn trỏ HTTT cũ.
3. TA nhập lý do và số văn bản, xác nhận (FR-00-050).
4. Hệ thống đổi `ownerOrgCode`, `providerSystemCode`; chuyển các yêu cầu duyệt đang chờ cho người có quyền của đơn vị mới; giữ nguyên người đã gửi để kiểm toán.
5. Hệ thống cảnh báo các backend `SYSTEM` còn dùng kết nối của HTTT cũ và yêu cầu SV mới rà soát trong 30 ngày (không đổi tự động).
6. Hệ thống thông báo đơn vị cũ, đơn vị mới và bên đăng ký (thông báo thông tin, không bắt buộc); ghi kiểm toán.

**Luồng thay thế.** Chỉ đổi HTTT cung cấp mà giữ đơn vị chủ quản (thay hệ thống): bỏ qua việc chuyển yêu cầu duyệt.

**Luồng ngoại lệ.**

- HTTT hoặc đơn vị đích không hợp lệ: ERR-02-004 (422); "HTTT hoặc đơn vị đích không tồn tại hoặc chưa hoạt động."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do chuyển chủ quản."
- Không có quyền: ERR-02-014 (403).
- API có yêu cầu đang xử lý khóa nội dung: không chặn; yêu cầu đi theo đơn vị mới.

**Đầu ra.** `200`; API với chủ quản mới và danh sách việc cần rà soát.

**Kết quả.** API có người chịu trách nhiệm mới, không gián đoạn.

**Hậu điều kiện.** Chủ quản đổi; quyền của SV theo đơn vị mới.

**Sự kiện phát ra.** EVT-02-02 (`changedFields = ownerOrgCode, providerSystemCode`).

**Kiểm toán.** Có: đơn vị cũ, mới, HTTT cũ, mới, lý do, số văn bản, người chuyển.

**Quy tắc nghiệp vụ.** BR-02-028; BR-02-032.

**Màn hình, API.** UI-02-02; API-02-057.
:::

### 6.8. Nhóm G · Đăng ký sử dụng

Đăng ký sử dụng biến "tôi muốn dùng API này" thành một quyền cụ thể, có người chịu trách nhiệm và có thể thu hồi: HTTT đã kết nạp nêu mục đích, bên cung cấp duyệt, hệ thống tự cấp phạm vi `api:{mã API}:{mã gói}`. Không có danh sách đăng ký thì khi cần ngừng dùng hoặc báo thay đổi sẽ không biết báo cho ai; vì vậy đăng ký là điều kiện để lộ trình ngừng dùng ở nhóm F hoạt động được. Máy trạng thái ở mục 4.5.

```{.mermaid caption="Các chức năng nhóm G theo vòng đời đăng ký"}
flowchart TB
  A["FR-02-046<br/>HTTT gửi đăng ký"] --> B["FR-02-047<br/>Duyệt hoặc từ chối"]
  B -->|"Duyệt"| C["FR-02-048<br/>Cấp phạm vi,<br/>gắn consumer"]
  C --> D["ACTIVE"]
  D --> E["FR-02-051<br/>Tạm ngừng, thu hồi,<br/>hủy"]
  D --> F["FR-02-052<br/>Gia hạn, rà soát"]
  G["FR-02-049<br/>Xem theo API"] -.-> D
  H["FR-02-050<br/>Xem theo HTTT"] -.-> D
```

Hình trên cho thấy đăng ký đi một chiều từ gửi, duyệt, cấp phạm vi tới hiệu lực; mọi thay đổi sau đó (tạm ngừng, thu hồi, hủy, gia hạn) đều quay về cùng một đối tượng đăng ký, hai màn xem theo API và theo HTTT là hai góc nhìn của cùng dữ liệu.

#### FR-02-046 · Gửi đăng ký sử dụng API

::: dac-ta
**Mục đích.** Cho cán bộ đầu mối của một đơn vị xin dùng một API của đơn vị khác cho HTTT của mình, nêu rõ mục đích và khối lượng dự kiến, thay cho việc tạo Application rồi tự đăng ký ở hệ cũ. Chỉ HTTT đã kết nạp mới xin được, nên luôn có chủ thể chịu trách nhiệm.

**Tác nhân, quyền.** OR (○), TA có `PERM-02-subscribe`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-016; LGC-APIM-021; SRS cũ FR-02-011; CMP-LAW-05.

**Tiền điều kiện.** HTTT khai thác `ACTIVE` ở PH-01 và thuộc tổ chức của người dùng; phiên bản API `PUBLISHED` (hoặc `DEPRECATED` có cảnh báo) và gói `PUBLISHED` có HTTT trong đối tượng được xin.

**Kích hoạt.** Người dùng bấm "Đăng ký sử dụng" ở UI-02-01 hoặc UI-02-02, mở UI-02-09.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-046 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Người dùng chọn API, phiên bản, gói và HTTT khai thác của đơn vị mình; hệ thống hiển thị điều khoản của gói và SLA cam kết.
2. Hệ thống kiểm tra HTTT khai thác `ACTIVE` và thuộc tổ chức của người dùng (ERR-02-026), gói `PUBLISHED` (ERR-02-025), HTTT nằm trong đối tượng của gói (ERR-02-028) và chưa có đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` cho cùng phiên bản (ERR-02-027).
3. Người dùng nhập mục đích sử dụng (không dưới 20 ký tự), khối lượng dự kiến (lượt mỗi ngày), thao tác cần dùng (mặc định mọi thao tác của gói), và căn cứ pháp lý khi API chứa dữ liệu cá nhân hoặc ở mức từ Hạn chế (ERR-02-029).
4. Hệ thống đối chiếu khối lượng dự kiến với hạn mức của gói và hạn mức giờ cam kết SLA; vượt thì cảnh báo, người dùng tiếp tục được nhưng người duyệt thấy cảnh báo.
5. Người dùng xác nhận đã đọc điều khoản; hệ thống tạo đăng ký `PENDING`.
6. Nếu gói `autoApprove` và `dataClass` trong ngưỡng: hệ thống bỏ qua duyệt, chuyển ngay `ACTIVE` và chạy FR-02-048. Còn lại hệ thống tạo yêu cầu duyệt `SUBSCRIPTION` cho SV của tổ chức chủ quản API và CA, và thông báo người gửi.

**Luồng thay thế.** Phiên bản `DEPRECATED`: hệ thống cảnh báo "Phiên bản sắp ngừng, nên đăng ký phiên bản mới" và gợi ý phiên bản kế nhiệm; vẫn cho gửi nếu gói `DEPRECATED` được CA cho phép ngoại lệ (không có ngoại lệ thì ERR-02-025). Người dùng rút đăng ký đang chờ: chuyển `CANCELLED` (FR-02-051).

**Luồng ngoại lệ.**

- HTTT chưa kết nối hoặc không hoạt động: ERR-02-026 (422); "HTTT {mã} chưa được kết nạp hoặc không hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước."
- Gói không nhận đăng ký: ERR-02-025 (409); "Gói {mã} không nhận đăng ký mới. Chọn gói khác."
- HTTT ngoài đối tượng của gói: ERR-02-028 (422); "HTTT của bạn không thuộc nhóm được dùng gói này."
- Đã có đăng ký: ERR-02-027 (409); "HTTT đã có đăng ký {trạng thái} cho phiên bản này."
- Thiếu mục đích hoặc khối lượng: ERR-02-029 (422); "Cần nêu mục đích và khối lượng dự kiến."
- Người dùng không thuộc tổ chức của HTTT: ERR-02-014 (403); "Bạn không phải đầu mối của đơn vị này."

**Đầu ra.** `201`, tiêu đề `Location`; đăng ký với `status` (`PENDING` hoặc `ACTIVE`), `reviewRequestId`, `warnings[]`.

**Kết quả.** Đơn vị khai thác có đăng ký đang chờ duyệt (hoặc đã được tự duyệt) và biết ai sẽ duyệt.

**Hậu điều kiện.** Đăng ký `PENDING` kèm yêu cầu duyệt, hoặc `ACTIVE` kèm tiến trình cấp phạm vi.

**Sự kiện phát ra.** EVT-02-09 (`subscription.requested`).

**Kiểm toán.** Có: HTTT, gói, mục đích, khối lượng, căn cứ pháp lý, người gửi.

**Quy tắc nghiệp vụ.** BR-02-011; BR-02-012; BR-02-026; BR-02-027.

**Màn hình, API.** UI-02-09; API-02-058.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `apiCode` | T-CODE | Có | API có phiên bản `PUBLISHED` | `tra-cuu-ho-tich` |
| `versionNo` | T-TEXT | Không | Mặc định phiên bản `PUBLISHED` mới nhất | `1.0.0` |
| `planCode` | T-CODE | Có | Gói `PUBLISHED` của phiên bản | `tich-hop-bao-mat` |
| `systemCode` | T-CODE | Có | HTTT `ACTIVE` ở PH-01 của tổ chức người gửi, nằm trong đối tượng của gói | `HT-MOTCUA` |
| `purpose` | T-TEXT | Có | 20…2000 ký tự | `Xác minh khai sinh khi tiếp nhận hồ sơ cấp thẻ BHYT trẻ em` |
| `expectedDailyCalls` | số nguyên | Có | 1…10.000.000 | `3000` |
| `operations[]` | danh sách T-ID, `operationId` | Không | Tập con thao tác được phép của gói | `["getBirthCertificate"]` |
| `legalBasis` | T-TEXT | Khi API chứa dữ liệu cá nhân hoặc mức từ Hạn chế | Số, ngày, tên văn bản căn cứ | `Quyết định 1234/QĐ-UBND` |
| `termsAccepted` | T-BOOL | Có | Phải `true` | `true` |

: Dữ liệu vào của FR-02-046

#### FR-02-047 · Duyệt hoặc từ chối đăng ký sử dụng

::: dac-ta
**Mục đích.** Cho bên cung cấp (chủ dịch vụ) và người duyệt dịch vụ quyết định ai được dùng API, trên cơ sở mục đích, khối lượng và hồ sơ HTTT đề nghị, để dữ liệu chỉ tới đúng người cần.

**Tác nhân, quyền.** SV (○ với API của tổ chức mình), CA, TA có `PERM-02-approve-subscription`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-016; FR-00-070, 071, 072.

**Tiền điều kiện.** Đăng ký `PENDING`; yêu cầu duyệt loại `SUBSCRIPTION`.

**Kích hoạt.** Người duyệt mở yêu cầu từ "Việc của tôi" (UI-02-10), hoặc từ tab Đăng ký của UI-02-02.

**Đầu vào.** `reviewRequestId`; `decision` (`APPROVE`, `REJECT`); `comment` (bắt buộc khi từ chối); `approvedDailyCalls` (T-TEXT, tùy chọn: hạn mức riêng thấp hơn gói); `expiresAt` (T-DATE, tùy chọn, mặc định theo thời hạn của gói).

**Luồng xử lý chính.**

1. Người duyệt mở yêu cầu; hệ thống hiển thị mục đích, khối lượng dự kiến, căn cứ pháp lý, hồ sơ HTTT khai thác ở PH-01 (đơn vị, cấp độ ATTT, đầu mối), lịch sử đăng ký trước, cảnh báo về hạn mức.
2. Hệ thống kiểm tra người duyệt khác người gửi (BR-02-008, ERR-02-013) và có quyền với API này (SV chỉ với API của tổ chức mình).
3. Với API `dataClass` từ `RESTRICTED` trở lên, hệ thống yêu cầu quyết định của CA hoặc TA, quyết định của SV một mình không đủ (BR-02-026): SV có thể "Đề xuất duyệt" để CA quyết.
4. Người duyệt chọn quyết định kèm ý kiến; có thể giới hạn hạn mức riêng và thời hạn thấp hơn gói.
5. Nếu duyệt: hệ thống chuyển đăng ký `ACTIVE`, ghi `decidedBy`, `decidedAt`, `expiresAt`, rồi chạy FR-02-048. Nếu từ chối: đăng ký `REJECTED`, lý do gửi lại cho người gửi.
6. Hệ thống ghi kiểm toán, thông báo người gửi và đầu mối kỹ thuật của HTTT (không kèm dữ liệu Hạn chế qua thư).

**Luồng thay thế.** Người duyệt chọn "Hỏi thêm": đăng ký `PENDING` kèm câu hỏi, người gửi trả lời ngay trên yêu cầu. Yêu cầu quá `02.review.overdue-days` ngày làm việc: hệ thống nhắc người duyệt, báo TA (EVT-02-16).

**Luồng ngoại lệ.**

- Vi phạm bốn mắt: ERR-02-013 (403); "Bạn là người gửi đăng ký này nên không được tự duyệt."
- Từ chối không có lý do: ERR-02-041 (400); "Cần nêu lý do từ chối."
- SV duyệt một mình với dữ liệu từ Hạn chế: ERR-02-014 (403); "Dữ liệu mức {mức} cần người duyệt dịch vụ quyết định."
- Đăng ký đã có quyết định: ERR-02-011 (409); "Đăng ký này đã được xử lý."
- HTTT khai thác không còn `ACTIVE` ở thời điểm duyệt: ERR-02-026 (422); "HTTT {mã} không còn hoạt động, không duyệt được."

**Đầu ra.** `200`; đăng ký với `status`, `decidedBy`, `expiresAt`, `grantStatus` (`PENDING`, `GRANTED`).

**Kết quả.** Đăng ký được quyết định có người chịu trách nhiệm; HTTT khai thác nhận kết quả kèm ý kiến.

**Hậu điều kiện.** Đăng ký `ACTIVE` hoặc `REJECTED`; yêu cầu duyệt đóng.

**Sự kiện phát ra.** EVT-02-10 (`subscription.activated`) khi duyệt và cấp thành công; EVT-02-11 khi từ chối.

**Kiểm toán.** Có: người duyệt, quyết định, ý kiến, hạn mức riêng, thời hạn.

**Quy tắc nghiệp vụ.** BR-02-008; BR-02-012; BR-02-026.

**Màn hình, API.** UI-02-10; API-02-044, API-02-045, API-02-046, API-02-098.
:::

#### FR-02-048 · Cấp phạm vi truy cập theo đăng ký đã duyệt

::: dac-ta
**Mục đích.** Tự động biến đăng ký đã duyệt thành quyền gọi thật: gắn phạm vi `api:{mã API}:{mã gói}` vào định danh máy của HTTT và đăng ký HTTT làm consumer của gói ở gateway, để không ai phải cấp quyền bằng tay (và không ai cấp nhầm).

**Tác nhân, quyền.** Hệ thống (sau duyệt hoặc tự duyệt); TO có `PERM-02-operate` khi thử lại.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; D02-08 §1, §5 (phạm vi sinh từ dữ liệu đã duyệt); SEC-24, SEC-26; BR-02-025.

**Tiền điều kiện.** Đăng ký `ACTIVE` chưa có `grantStatus = GRANTED`; HTTT khai thác có định danh máy ở PH-01 (client Keycloak, và chứng thư với `OAUTH2_MTLS`).

**Kích hoạt.** Sau FR-02-047 duyệt, hoặc tự duyệt ở FR-02-046; khi TO bấm "Cấp lại" (API-02-068).

**Đầu vào.** `subscriptionId`.

**Luồng xử lý chính.**

1. Hệ thống tính phạm vi: `api:{apiCode}:{planCode}` và, nếu đăng ký giới hạn thao tác, các phạm vi con `api:{apiCode}:{planCode}:{operationId}`.
2. Hệ thống hỏi PH-01 định danh máy của HTTT khai thác phù hợp kiểu xác thực của gói; thiếu thì đặt `grantStatus = AWAITING_CREDENTIAL` và tạo việc cho OR: "Xin cấp định danh ứng dụng ở mục Hệ thống thành viên" (không lỗi chặn).
3. Hệ thống yêu cầu PH-12 gắn phạm vi vào client Keycloak của HTTT (và cập nhật chính sách OPA theo phạm vi); chờ xác nhận.
4. Hệ thống yêu cầu mô-đun PH-03 thêm consumer vào nhóm của gói trong ảnh chụp cấu hình (kèm hạn mức riêng nếu có) và chờ APISIX xác nhận nạp.
5. Đủ hai xác nhận: hệ thống đặt `grantStatus = GRANTED`, `grantedAt`, và thông báo HTTT khai thác "Đã cấp quyền, bạn có thể gọi API" kèm đường dẫn (FR-02-005); thời gian từ duyệt tới gọi được p95 ≤ 30 giây (NFR-02-005).
6. Lỗi một trong hai bên: hệ thống thử lại lùi dần tối đa 5 lần trong 15 phút; hết lần mà chưa xong thì đặt `grantStatus = FAILED`, cảnh báo TO; không gỡ phần đã gắn thành công cho tới khi quyết định (tránh trạng thái nửa vời) mà đánh dấu để dọn.

**Luồng thay thế.** Gói `KEYLESS`: bỏ bước PH-12, chỉ cập nhật bộ đếm hạn mức theo IP ở PH-03; gói `API_KEY`: khóa do PH-01 cấp, PH-03 giữ băm khóa.

**Luồng ngoại lệ.**

- HTTT chưa có định danh máy: `AWAITING_CREDENTIAL` (không phải lỗi), thông báo cho OR; tiếp tục tự động khi PH-01 cấp xong.
- PH-12 hoặc PH-03 không khả dụng: ERR-02-033 (503) hoặc ERR-02-034 (503); thử lại như bước 6; "Quyền của HTTT đang được cấp, thử lại sau ít phút."
- Phạm vi trái chính sách (ví dụ mức Nhạy cảm mà HTTT chưa có mTLS): ERR-02-022 (422); đăng ký chuyển `AWAITING_CREDENTIAL` kèm hướng dẫn.

**Đầu ra.** `200` hoặc `202`; `grantStatus`, `scopes[]`, `grantedAt`, `failures[]`.

**Kết quả.** HTTT khai thác gọi được API ngay sau khi duyệt mà không ai thao tác thủ công ở nhiều nơi.

**Hậu điều kiện.** Phạm vi gắn ở Keycloak; consumer gắn ở gateway; đăng ký `GRANTED`.

**Sự kiện phát ra.** EVT-02-10.

**Kiểm toán.** Có: phạm vi cấp, client, kết quả từng bên, số lần thử.

**Quy tắc nghiệp vụ.** BR-02-016; BR-02-025.

**Màn hình, API.** UI-02-08 (trạng thái cấp); API-02-067, API-02-068.
:::

```{.mermaid caption="Trình tự cấp phạm vi truy cập sau khi duyệt đăng ký"}
sequenceDiagram
  autonumber
  participant CA as Người duyệt
  participant C as PH-02
  participant P1 as PH-01
  participant P12 as PH-12 Keycloak, OPA
  participant P3 as PH-03 Bộ đồng bộ cấu hình
  participant AP as APISIX
  CA->>C: Duyệt đăng ký
  C->>P1: Lấy định danh máy của HTTT
  P1-->>C: clientId, kiểu xác thực
  C->>P12: Gắn phạm vi api:mã API:mã gói
  P12-->>C: Đã gắn
  C->>P3: Thêm consumer vào nhóm của gói
  P3->>AP: Ảnh chụp cấu hình mới
  AP-->>P3: Đã nạp
  P3-->>C: Xác nhận
  C->>C: Đặt GRANTED, ghi kiểm toán
  C-->>CA: Hoàn tất, thông báo HTTT khai thác
```

Hình trên cho thấy quyền gọi chỉ thành hình khi cả hai nơi xác nhận (định danh và gateway); thiếu một bên thì đăng ký ở trạng thái chờ cấp, không có cửa sau.

#### FR-02-049 · Xem đăng ký theo API

::: dac-ta
**Mục đích.** Cho chủ dịch vụ biết ai đang dùng API của mình, theo gói nào, từ khi nào, lượt gọi ra sao, để quản lý lộ trình thay đổi và rà soát quyền.

**Tác nhân, quyền.** SV (○ API của tổ chức mình), CA, TA đủ chi tiết; mọi vai trò có `PERM-02-read` chỉ thấy số tổng.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-016.

**Tiền điều kiện.** API tồn tại và người dùng xem được.

**Kích hoạt.** Người dùng mở tab Đăng ký của UI-02-02.

**Đầu vào.** `apiCode`; `versionNo`, `planCode`, `status` (chọn nhiều), `systemCode`, `q`; `page`, `size`, `sort` theo FR-00-021, 022.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra quyền xem chi tiết theo vai trò và tổ chức chủ quản của API.
2. Hệ thống truy vấn đăng ký của API theo bộ lọc và phân trang; mặc định ẩn trạng thái cuối (`REJECTED`, `CANCELLED`, `EXPIRED`) trừ khi lọc.
3. Hệ thống ghép lượt gọi 30 ngày và lần gọi gần nhất từ PH-13 theo HTTT khai thác.
4. Hệ thống tính các thẻ tổng: theo trạng thái, theo gói, số đăng ký sắp hết hạn trong 30 ngày, số quá hạn rà soát.
5. Người dùng bấm một dòng để mở chi tiết đăng ký hoặc thao tác theo quyền (FR-02-051).

**Luồng thay thế.** Người dùng không đủ quyền chi tiết: chỉ thấy các thẻ tổng, danh sách bị ẩn kèm "Bạn không có quyền xem danh sách bên đăng ký."

**Luồng ngoại lệ.**

- API không có hoặc thuộc tenant khác: ERR-02-001 (404).
- PH-13 không khả dụng: danh sách vẫn hiển thị, cột lượt gọi ghi "Chưa có số liệu"; ERR-02-034 chỉ ghi nhật ký.
- Tham số lọc sai: ERR-02-003 (400).

**Đầu ra.** `200`; `items[]` (`subscriptionId`, `systemCode`, đơn vị, `planCode`, `status`, `grantStatus`, `activatedAt`, `expiresAt`, `calls30d`, `lastCallAt`), `facets`, `page`, `size`, `totalElements`.

**Kết quả.** Chủ dịch vụ nhìn rõ danh sách bên khai thác API của mình.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi CA, TA xem chi tiết đăng ký của API không thuộc tổ chức mình; không với SV xem API của mình.

**Quy tắc nghiệp vụ.** BR-02-033.

**Màn hình, API.** UI-02-02 tab Đăng ký; API-02-059, API-02-060.
:::

#### FR-02-050 · Xem đăng ký theo HTTT

::: dac-ta
**Mục đích.** Cho đầu mối của một đơn vị khai thác, hoặc quản trị tenant, xem một HTTT đang dùng những API nào, trạng thái từng đăng ký, hạn, và API nào sắp ngừng để chủ động nâng cấp. Tương ứng "quản lý subscription theo Application" ở hệ cũ.

**Tác nhân, quyền.** OR (○ HTTT của tổ chức mình), TA, CA, TO có `PERM-02-read` (chi tiết).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-021.

**Tiền điều kiện.** HTTT tồn tại ở PH-01.

**Kích hoạt.** Người dùng mở menu "Kết nối & API → Đăng ký sử dụng" (`/ket-noi/dang-ky`), hoặc tab "API đang dùng" ở chi tiết HTTT (PH-01).

**Đầu vào.** `systemCode` (mặc định các HTTT của tổ chức người dùng); `status`, `apiCode`, `planCode`, `expiringWithinDays`, `deprecatedOnly`; `page`, `size`, `sort`.

**Luồng xử lý chính.**

1. Hệ thống xác định tập HTTT người dùng được xem: OR chỉ HTTT thuộc tổ chức mình; TA, CA, TO mọi HTTT trong tenant.
2. Hệ thống truy vấn đăng ký theo bộ lọc, kèm tên API, phiên bản, trạng thái vòng đời của phiên bản và gói.
3. Hệ thống đánh dấu đăng ký trỏ tới phiên bản `DEPRECATED` (kèm hạn và phiên bản kế nhiệm), `SUSPENDED` và đăng ký sắp hết hạn trong 30 ngày.
4. Hệ thống trả danh sách, các thẻ tổng và nút hành động hợp lệ theo trạng thái và quyền (hủy, gia hạn, đăng ký phiên bản mới).
5. Người dùng bấm "Xuất" để xuất danh sách (FR-00-030).

**Luồng thay thế.** Người dùng bấm "Đăng ký phiên bản mới" ở dòng trỏ tới phiên bản `DEPRECATED`: mở UI-02-09 với API và phiên bản kế nhiệm điền sẵn.

**Luồng ngoại lệ.**

- HTTT không thuộc tập được xem: ERR-02-001 (404).
- Tham số lọc sai: ERR-02-003 (400).
- PH-01 không khả dụng: dùng bản sao danh sách HTTT đã đệm, nhãn "Chưa cập nhật lúc {thời điểm}"; ERR-02-034 chỉ ghi nhật ký.

**Đầu ra.** `200`; `items[]` như FR-02-049 kèm `apiName`, `versionNo`, `versionStatus`, `sunsetAt`, `successorVersionNo`, `allowedActions[]`; `facets`.

**Kết quả.** Đơn vị khai thác thấy toàn bộ API mình đang dùng và biết việc cần làm.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với OR xem HTTT của mình; có (mức tóm tắt) khi CA, TA xem hàng loạt hoặc xuất.

**Quy tắc nghiệp vụ.** BR-02-033.

**Màn hình, API.** UI-02-08; API-02-059, API-02-060.
:::

#### FR-02-051 · Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký

::: dac-ta
**Mục đích.** Cho phép chấm dứt hoặc tạm dừng quyền dùng API khi cần: bên cung cấp thu hồi khi HTTT vi phạm hoặc hết căn cứ, cán bộ ATTT tạm ngừng khi nghi ngờ lộ định danh, đơn vị khai thác tự hủy khi không còn dùng.

**Tác nhân, quyền.** TO, SO, TA có `PERM-02-operate` (tạm ngừng, tiếp tục); SV (○ API của mình), CA, TA có `PERM-02-approve-subscription` (thu hồi); OR (○), TA có `PERM-02-subscribe` (hủy).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; LGC-APIM-016; LGC-APIM-021; SEC-72.

**Tiền điều kiện.** Đăng ký `ACTIVE` hoặc `SUSPENDED` (tiếp tục, thu hồi); `ACTIVE` hoặc `PENDING` (hủy).

**Kích hoạt.** Người dùng bấm "Tạm ngừng", "Tiếp tục", "Thu hồi" hoặc "Hủy đăng ký" ở UI-02-08 hoặc tab Đăng ký của UI-02-02.

**Đầu vào.** `subscriptionId`; `action` (`SUSPEND`, `RESUME`, `REVOKE`, `CANCEL`); `reason` (bắt buộc với `SUSPEND`, `REVOKE`; tùy chọn với `CANCEL`).

**Luồng xử lý chính.**

1. Người dùng chọn hành động và nhập lý do; hệ thống kiểm tra quyền theo hành động và trạng thái hợp lệ (ERR-02-011).
2. Hệ thống xác nhận (FR-00-050); thu hồi và tạm ngừng khẩn hiển thị ảnh hưởng: HTTT sẽ không gọi được ngay, lượt gọi 7 ngày gần đây.
3. `SUSPEND`: hệ thống gỡ consumer khỏi nhóm của gói ở gateway (giữ đăng ký, phạm vi); `RESUME`: gắn lại consumer, kiểm tra HTTT vẫn `ACTIVE` ở PH-01 (BR-02-034 về người tiếp tục khi do SO ngừng).
4. `REVOKE`, `CANCEL`: hệ thống gỡ consumer và yêu cầu PH-12 gỡ phạm vi khỏi client; đăng ký sang `REVOKED` hoặc `CANCELLED`, không khôi phục được (muốn dùng lại phải gửi đăng ký mới).
5. Hiệu lực ở gateway trong 30 giây (NFR-02-005); hệ thống thông báo HTTT khai thác và đầu mối: thu hồi và tạm ngừng có kèm lý do ở mức tổng quát.
6. Hệ thống ghi kiểm toán và phát sự kiện.

**Luồng thay thế.** Khi HTTT bị tạm ngừng hoặc thu hồi ở PH-01, PH-02 tự chuyển mọi đăng ký `ACTIVE` của HTTT đó sang `SUSPENDED` (lý do `SYSTEM_SUSPENDED`) và khôi phục khi HTTT `ACTIVE` lại.

**Luồng ngoại lệ.**

- Trạng thái không hợp lệ: ERR-02-011 (409); "Không thực hiện được ở trạng thái {trạng thái} hiện tại."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do."
- Người tiếp tục không đủ quyền theo BR-02-034: ERR-02-014 (403); "Chỉ Cán bộ ATTT đã tạm ngừng hoặc quản trị tenant mới tiếp tục được."
- PH-03 hoặc PH-12 không nhận: ERR-02-033 (503) hoặc ERR-02-034 (503); thử lại; trạng thái chỉ đổi khi gateway đã áp dụng đối với `SUSPEND`, `REVOKE`.

**Đầu ra.** `200`; đăng ký với `status` mới, `grantStatus`.

**Kết quả.** Quyền dùng API bị chặn hoặc phục hồi nhanh, đúng lý do, HTTT được báo.

**Hậu điều kiện.** Đăng ký đổi trạng thái; consumer, phạm vi cập nhật.

**Sự kiện phát ra.** EVT-02-11 (`subscription.state-changed`).

**Kiểm toán.** Có: hành động, lý do, người thực hiện, thời điểm hiệu lực ở gateway.

**Quy tắc nghiệp vụ.** BR-02-028; BR-02-029; BR-02-034.

**Màn hình, API.** UI-02-08, UI-02-02; API-02-061, API-02-062, API-02-063, API-02-064.
:::

#### FR-02-052 · Gia hạn và rà soát định kỳ đăng ký

::: dac-ta
**Mục đích.** Bảo đảm quyền gọi API không tồn tại mãi khi mục đích đã hết hoặc người phụ trách đã đổi: mỗi đăng ký có hạn, tới kỳ đầu mối phải xác nhận còn dùng và còn đúng mục đích.

**Tác nhân, quyền.** Hệ thống (lịch); OR (○), TA có `PERM-02-subscribe` để gia hạn; SV (○), CA có `PERM-02-approve-subscription` để xác nhận với dữ liệu từ Hạn chế.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-02; SRS cũ BR-02-012 (rà soát quyền định kỳ); SEC-27.

**Tiền điều kiện.** Đăng ký `ACTIVE` có `expiresAt`; tham số `02.subscription.review-months` > 0.

**Kích hoạt.** Lịch hằng ngày 06:00 giờ Việt Nam; hoặc người dùng bấm "Gia hạn" ở UI-02-08.

**Đầu vào.** `subscriptionId`; `purposeStillValid` (T-BOOL), `purpose` (cập nhật nếu đổi), `expectedDailyCalls`.

**Luồng xử lý chính.**

1. Lịch tìm đăng ký sẽ hết hạn trong 30 ngày và tạo việc "Rà soát đăng ký" cho OR, nhắc lại ở mốc 14 và 3 ngày.
2. OR xác nhận còn dùng và còn đúng mục đích (có thể cập nhật mục đích, khối lượng); hệ thống kiểm tra HTTT vẫn `ACTIVE` ở PH-01 (ERR-02-026).
3. Với API `dataClass` từ `RESTRICTED` trở lên, hệ thống tạo yêu cầu duyệt `SUBSCRIPTION` loại gia hạn cho CA; dữ liệu thấp hơn thì gia hạn tự động.
4. Khi gia hạn: hệ thống đặt `expiresAt` mới bằng ngày hiện tại cộng thời hạn của gói và ghi lịch sử gia hạn; phạm vi, consumer giữ nguyên, không gián đoạn.
5. Tới hạn mà chưa gia hạn: hệ thống chuyển đăng ký `EXPIRED`, gỡ consumer và phạm vi như thu hồi (FR-02-051 bước 4), thông báo OR và SV; HTTT phải gửi đăng ký mới nếu muốn dùng lại.
6. Đăng ký gần hết hạn được hiển thị nhãn ở UI-02-08 và trong tab Đăng ký.

**Luồng thay thế.** OR chọn "Không còn dùng": đăng ký chuyển `CANCELLED` ngay (FR-02-051). Gói không thời hạn: đăng ký không có `expiresAt`, không vào lịch này.

**Luồng ngoại lệ.**

- HTTT không còn `ACTIVE`: ERR-02-026 (422); "HTTT {mã} không còn hoạt động nên không gia hạn được."
- Đăng ký không còn hiệu lực khi bấm gia hạn: ERR-02-011 (409); "Đăng ký đã hết hạn. Gửi đăng ký mới."
- Chưa tới thời điểm cho phép gia hạn (trước hạn hơn 60 ngày): ERR-02-003 (400); "Chỉ gia hạn khi còn dưới 60 ngày."

**Đầu ra.** `200`; đăng ký với `expiresAt` mới, `renewedAt`, hoặc `202` khi chờ duyệt.

**Kết quả.** Quyền gọi API luôn còn khớp với nhu cầu thật; đăng ký bỏ quên tự hết hạn.

**Hậu điều kiện.** `expiresAt` cập nhật hoặc đăng ký `EXPIRED`.

**Sự kiện phát ra.** EVT-02-11 khi `EXPIRED`.

**Kiểm toán.** Có: người xác nhận, mục đích cập nhật, hạn cũ, hạn mới.

**Quy tắc nghiệp vụ.** BR-02-012; BR-02-026; BR-02-028.

**Màn hình, API.** UI-02-08; API-02-065, API-02-066.
:::

### 6.9. Nhóm H · Đồng bộ danh mục quốc gia

Nhóm H hiện thực nghĩa vụ đăng ký danh mục dịch vụ chia sẻ dữ liệu lên Nền tảng chia sẻ, điều phối dữ liệu quốc gia (CMP-LAW-03, CMP-LAW-19). Đây là nghĩa vụ dễ bị bỏ sót vì không ảnh hưởng vận hành hằng ngày, nên được đưa vào luồng tự động và có cảnh báo tuân thủ khi quá hạn. PH-02 chỉ chuẩn bị nội dung và theo dõi kết quả; việc nói chuyện với nền tảng quốc gia (chứng thư, giới hạn tần suất, định dạng giao thức) do PH-14 làm (ADR-057).

```{.mermaid caption="Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14"}
flowchart TB
  E["Sự kiện: công bố, đổi mô tả,<br/>đổi trạng thái, đổi mức hiển thị"] --> Q["Hàng đợi outbox<br/>bản ghi đồng bộ QUEUED"]
  T["Lịch hằng ngày<br/>đối chiếu băm"] --> Q
  M["PERM-02-operate<br/>chạy tay"] --> Q
  Q --> B["FR-02-053<br/>Dựng gói, gửi qua PH-14"]
  B --> N["Nền tảng quốc gia"]
  N -->|"Xác nhận"| A["ACKED"]
  N -->|"Từ chối"| R["REJECTED<br/>FR-02-054 xử lý"]
  B -->|"Lỗi tạm thời"| F["FAILED, thử lại"]
  F --> Q
  A --> W["FR-02-054<br/>Theo dõi, cảnh báo quá hạn"]
  R --> W
  F --> W
```

Hình trên cho thấy ba nguồn kích hoạt (sự kiện, lịch, chạy tay) cùng vào một hàng đợi; từ hàng đợi chỉ có ba kết cục (xác nhận, từ chối, lỗi tạm thời rồi thử lại), và cả ba đều hiện ở màn theo dõi để phát cảnh báo quá hạn.

#### FR-02-053 · Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14

::: dac-ta
**Mục đích.** Bảo đảm mọi API được phép công khai ngoài tỉnh (mức `NATIONAL`, `PUBLIC`) đều có mặt trong danh mục dịch vụ chia sẻ của Nền tảng quốc gia, tự động khi công bố hoặc thay đổi và định kỳ hằng ngày, không phụ thuộc việc ai đó nhớ làm.

**Tác nhân, quyền.** Hệ thống (sự kiện, lịch); TA, TO có `PERM-02-operate` khi bấm "Đồng bộ ngay".

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; CMP-LAW-03, CMP-LAW-19; ADR-057; SRS cũ FR-02-009; Q02-01, Q02-08.

**Tiền điều kiện.** Có phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED` của API có mức hiển thị `NATIONAL`, `PUBLIC` và `dataClass` khác `SENSITIVE`; PH-14 đã cấu hình kết nối tới Nền tảng quốc gia của tenant.

**Kích hoạt.** EVT-02-05, 06 (công bố, đổi trạng thái); EVT-02-02 (đổi mô tả, mức hiển thị, chủ quản); lịch `02.sync.cron` (mặc định `0 0 2 * * *` giờ Việt Nam); người dùng bấm "Đồng bộ ngay" ở UI-02-12.

**Đầu vào.** Từ sự kiện hoặc lịch: tập `apiCode`, `versionNo`; chạy tay: `scope` (`ALL_PENDING`, hoặc danh sách API), `force` (T-BOOL, gửi lại cả khi băm không đổi).

**Luồng xử lý chính.**

1. Hệ thống chọn các phiên bản cần gửi: đủ điều kiện (mức hiển thị, `dataClass`, trạng thái) và băm nội dung hiện tại khác băm lần `ACKED` gần nhất (hoặc chưa từng gửi); khi lịch chạy còn rà cả bản ghi `FAILED`, `REJECTED` có thể thử lại.
2. Hệ thống dựng gói thông tin dịch vụ theo định dạng quy định của Nền tảng quốc gia (qua ánh xạ cấu hình ở PH-14): mã dịch vụ quốc gia, tên, mô tả, đơn vị chủ quản, loại dữ liệu, mức phân loại, địa chỉ gọi công khai, liên kết tới đặc tả, phạm vi cần có, SLA cam kết, trạng thái, phiên bản, đầu mối. Gói **không** chứa backend, địa chỉ nội bộ, danh sách bên đăng ký hay dữ liệu cá nhân.
3. Hệ thống ghi bản ghi đồng bộ `QUEUED` (kèm `payloadHash`) trong cùng giao dịch với sự kiện gốc (outbox) để không mất lệnh khi PH-14 ngừng.
4. Bộ gửi lấy tối đa 50 bản ghi mỗi lượt (`02.sync.batch-size`), gửi sang PH-14 với `Idempotency-Key` = `payloadHash` rồi chờ phản hồi; PH-14 chịu trách nhiệm xác thực, chữ ký và giới hạn tần suất với nền tảng quốc gia.
5. Nhận xác nhận: bản ghi `ACKED`, lưu `nationalRef`, `ackedAt`. Nhận từ chối: `REJECTED`, lưu mã và lý do từ nền tảng, thông báo SV và TO. Lỗi tạm thời: `FAILED`, thử lại lùi dần (1, 5, 15, 60 phút, rồi mỗi 6 giờ).
6. Hệ thống phát EVT-02-14 mỗi lần đổi trạng thái đồng bộ và cập nhật chỉ số `catalog_national_sync_status`.
7. Khi API bị xóa, hạ mức xuống `TENANT` hoặc phiên bản `RETIRED`, bản ghi rút (`WITHDRAW`) được gửi thay cho bản ghi đăng ký.

**Luồng thay thế.** PH-14 chưa triển khai hoặc tenant chưa bật kết nối quốc gia: hệ thống vẫn ghi bản ghi `QUEUED`, hiển thị "Chờ kết nối Nền tảng quốc gia" và không tính quá hạn (tham số `02.sync.enabled = false`).

**Luồng ngoại lệ.**

- PH-14 hoặc Nền tảng quốc gia không khả dụng: ERR-02-034 (503); bản ghi `FAILED`, vào hàng thử lại; không chặn vòng đời API; cảnh báo quá hạn theo FR-02-054.
- Nền tảng quốc gia từ chối một dịch vụ: bản ghi `REJECTED` kèm lý do; "Nền tảng quốc gia từ chối API {mã}: {lý do}. Sửa thông tin rồi gửi lại."
- API chưa đủ điều kiện khi bấm gửi tay: ERR-02-044 (409); "API {mã} chưa đủ điều kiện đồng bộ quốc gia (chưa công bố hoặc mức hiển thị là nội bộ)."
- Đang có lần gửi cho cùng API: ERR-02-035 (409); "Đang đồng bộ API này."

**Đầu ra.** `202` kèm `syncRunId` khi chạy tay; kết quả: số bản ghi theo trạng thái; bản ghi đồng bộ có `status`, `payloadHash`, `nationalRef`, `rejectReason`.

**Kết quả.** Danh mục quốc gia phản ánh đúng các API tỉnh đã công khai, tự động cập nhật khi thay đổi.

**Hậu điều kiện.** Bản ghi đồng bộ cập nhật; danh mục quốc gia có hoặc rút mục tương ứng.

**Sự kiện phát ra.** EVT-02-14 (`national-sync.state-changed`).

**Kiểm toán.** Có: API, phiên bản, hành động (`UPSERT`, `WITHDRAW`), băm, kết quả, mã tham chiếu quốc gia; giữ 5 năm (NFR-02-017).

**Quy tắc nghiệp vụ.** BR-02-009; BR-02-037.

**Màn hình, API.** UI-02-12; API-02-069, API-02-071, API-02-095 (tiến độ tác vụ).
:::

```{.mermaid caption="Trình tự gửi một dịch vụ lên Nền tảng quốc gia"}
sequenceDiagram
  autonumber
  participant C as PH-02 Bộ đồng bộ quốc gia
  participant O as Bảng outbox ph02_catalog
  participant P as PH-14 Bộ điều hợp quốc gia
  participant N as Nền tảng quốc gia
  C->>O: Ghi bản ghi QUEUED cùng giao dịch công bố
  C->>O: Lấy lô tối đa 50 bản ghi
  C->>P: Gửi gói thông tin dịch vụ, Idempotency-Key là băm
  P->>N: Gọi bằng thông tin xác thực, chứng thư của tenant
  alt Nền tảng chấp nhận
    N-->>P: Mã tham chiếu quốc gia
    P-->>C: ACK
    C->>O: Đặt ACKED
  else Nền tảng từ chối
    N-->>P: Lý do từ chối
    P-->>C: REJECT
    C->>O: Đặt REJECTED, thông báo SV
  else Lỗi tạm thời
    P-->>C: Lỗi, hết thời gian chờ
    C->>O: Đặt FAILED, hẹn thử lại
  end
```

Hình trên cho thấy PH-02 không giữ khóa hay chứng thư quốc gia; mọi giao tiếp với nền tảng đi qua PH-14, và trạng thái luôn ghi lại để theo dõi và thử lại.

#### FR-02-054 · Theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn

::: dac-ta
**Mục đích.** Cho cán bộ vận hành biết API nào đã lên danh mục quốc gia, API nào bị từ chối hoặc kẹt, xử lý từng trường hợp, và được cảnh báo khi quá hạn đăng ký, để nghĩa vụ pháp lý không rơi vào im lặng.

**Tác nhân, quyền.** TA, TO có `PERM-02-operate`; mọi vai trò có `PERM-02-read` (xem trạng thái); SV (○) thấy API của tổ chức mình.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; CMP-LAW-03; SRS cũ FR-02-009 ngoại lệ E2, E3; NFR-02-014.

**Tiền điều kiện.** Có bản ghi đồng bộ.

**Kích hoạt.** Người dùng mở UI-02-12 (`/ket-noi/dong-bo-quoc-gia`); hoặc lịch kiểm tra quá hạn mỗi giờ.

**Đầu vào.** `status`, `apiCode`, `overdueOnly`, `since`; `page`, `size`; lệnh: `retry`, `resend`.

**Luồng xử lý chính.**

1. Người dùng mở màn; hệ thống hiển thị các thẻ tổng: Đã đồng bộ, Đang chờ, Lỗi tạm thời, Bị từ chối, Quá hạn; kèm thời điểm đồng bộ thành công gần nhất.
2. Hệ thống liệt kê bản ghi theo bộ lọc; mỗi dòng có API, phiên bản, hành động, trạng thái, số lần thử, lý do, thời điểm; mục quá hạn nổi lên đầu.
3. Hệ thống xác định **quá hạn**: API đủ điều kiện đồng bộ mà chưa có bản ghi `ACKED` nào cho phiên bản hiện tại sau `02.sync.overdue-days` ngày (mặc định 7) kể từ lúc đủ điều kiện; cờ quá hạn hiện ở UI-02-12 và ở UI-02-01 (thẻ "Cần chú ý").
4. Người dùng bấm "Thử lại" ở bản ghi `FAILED` hoặc "Gửi lại" ở bản ghi `REJECTED` sau khi sửa thông tin API; hệ thống tạo bản ghi mới `QUEUED`.
5. Khi có API quá hạn, hệ thống gửi cảnh báo tuân thủ cho TA, TO qua trung tâm thông báo (FR-00-060) và PH-13 (chỉ số `catalog_national_sync_overdue_total`), nhắc lại hằng ngày tới khi xử lý.
6. Từ chối từ nền tảng quốc gia được gom theo mã lý do để TA nhận ra lỗi hệ thống (ví dụ sai ánh xạ).

**Luồng thay thế.** Bản ghi từ chối do dữ liệu chủ dịch vụ khai (mô tả thiếu): hệ thống tạo việc cho SV sửa thông tin rồi tự gửi lại khi sửa xong.

**Luồng ngoại lệ.**

- API chưa đủ điều kiện khi gửi lại: ERR-02-044 (409); "API {mã} chưa đủ điều kiện đồng bộ quốc gia."
- Đang có lần gửi: ERR-02-035 (409); "Đang đồng bộ API này."
- Không có quyền: ERR-02-014 (403); "Bạn không có quyền chạy đồng bộ."
- PH-14 không khả dụng khi bấm gửi: ERR-02-034 (503); "Chưa kết nối được Nền tảng quốc gia. Yêu cầu đã xếp hàng."

**Đầu ra.** `200`; `summary {acked, queued, failed, rejected, overdue}`, `lastSuccessAt`, `items[]` (`syncId`, `apiCode`, `versionNo`, `action`, `status`, `attempts`, `reason`, `updatedAt`).

**Kết quả.** Cán bộ vận hành biết tức thì tình trạng tuân thủ đăng ký danh mục và xử lý được từng trường hợp.

**Hậu điều kiện.** Bản ghi mới `QUEUED` khi thử lại; cảnh báo quá hạn đang bật khi còn API quá hạn.

**Sự kiện phát ra.** EVT-02-14.

**Kiểm toán.** Có cho lệnh thử lại, gửi lại (người thực hiện, bản ghi); xem không ghi.

**Quy tắc nghiệp vụ.** BR-02-009; BR-02-029.

**Màn hình, API.** UI-02-12; API-02-070, API-02-071, API-02-072.
:::

### 6.10. Nhóm I · Cam kết chất lượng, thông báo và thống kê

Bên khai thác chỉ nên phụ thuộc vào một dịch vụ khi biết nó đáng tin tới đâu. Nhóm I giúp chủ dịch vụ **cam kết** chất lượng, hệ thống **đo thực tế** và hiển thị cạnh cam kết, đồng thời **báo** mọi thay đổi ảnh hưởng tới bên khai thác và **thống kê** mức sử dụng để quản lý quyết định duy trì hay ngừng dịch vụ.

```{.mermaid caption="Cam kết, đo thực tế, thông báo và thống kê"}
flowchart TB
  A["FR-02-055<br/>Khai SLA cam kết"] --> C["FR-02-056<br/>Đối chiếu hằng tháng"]
  P13["PH-13<br/>Số đo thực tế"] --> C
  C --> D["Danh mục:<br/>cam kết cạnh thực tế"]
  C -->|"Không đạt liên tiếp"| W["Cảnh báo CA, TA, SV"]
  C --> K["PH-16<br/>Chỉ số tuân thủ"]
  N["FR-02-057<br/>Thông báo thay đổi"] --> S["Bên khai thác"]
  A -->|"đổi SLA"| N
  U["FR-02-058<br/>Thống kê sử dụng"] --> P13
```

Hình trên cho thấy cam kết và số đo thực tế gặp nhau ở bước đối chiếu; kết quả đi ba hướng: hiển thị ở danh mục, cảnh báo khi không đạt liên tiếp, và chỉ tiêu cho PH-16. Thông báo thay đổi chạy song song và được nhiều chức năng khác kích hoạt.

#### FR-02-055 · Khai báo cam kết chất lượng dịch vụ (SLA)

::: dac-ta
**Mục đích.** Cho chủ dịch vụ nêu rõ API cam kết điều gì: độ trễ, tỷ lệ sẵn sàng, số lượt tối đa mỗi giờ, giờ phục vụ, để bên khai thác biết trước và để hệ thống có chuẩn đối chiếu.

**Tác nhân, quyền.** SV (○), TA có `PERM-02-create`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-012; BR-02-013.

**Tiền điều kiện.** Phiên bản `DRAFT` (khai lần đầu) hoặc `PUBLISHED`, `SUSPENDED`, `DEPRECATED` (sửa).

**Kích hoạt.** Người dùng sửa khối "Cam kết chất lượng" ở UI-02-02 tab SLA, hoặc bước 4 của UI-02-03.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-055 dưới đây.

**Luồng xử lý chính.**

1. Người dùng nhập các cam kết; hệ thống gợi ý giá trị theo `dataClass` và theo thống kê các API tương tự của tenant.
2. Hệ thống kiểm tra miền giá trị (ERR-02-003) và nhất quán: hạn mức giờ không nhỏ hơn hạn mức giờ của mọi gói (cảnh báo ngược nếu nhỏ hơn: FR-02-029).
3. Hệ thống đối chiếu cam kết với năng lực backend đã đo (nếu có) và cảnh báo khi cam kết cao hơn đáng kể số đo thực tế gần nhất.
4. Khai lần đầu ở bản nháp: hệ thống lưu ngay, SLA là điều kiện bắt buộc để gửi duyệt (FR-02-034).
5. Sửa ở phiên bản đã công bố: cam kết **tốt hơn** (độ trễ giảm, sẵn sàng tăng, hạn mức tăng) có hiệu lực ngay; cam kết **kém đi** chỉ có hiệu lực sau `02.sla.worsen-notice-days` ngày (mặc định 30) kể từ lúc thông báo, và bắt buộc gửi thông báo cho mọi bên đăng ký (FR-02-057, BR-02-029).
6. Hệ thống ghi lịch sử cam kết (giữ vĩnh viễn) và kiểm toán.

**Luồng thay thế.** Người dùng chọn "Dùng mẫu theo mức phân loại": điền giá trị mặc định nền tảng đề xuất.

**Luồng ngoại lệ.**

- Giá trị ngoài miền: ERR-02-003 (400); "Giá trị {tên trường} nằm ngoài khoảng cho phép."
- Sửa khi phiên bản `PENDING`: ERR-02-038 (409); "Phiên bản đang chờ duyệt, không sửa được."
- Hạ cam kết mà không có thông báo hợp lệ (đang trong thời gian báo trước): hệ thống lưu `effectiveFrom`; không phải lỗi.

**Đầu ra.** `200`, `ETag` mới; cam kết hiện hành, cam kết chờ hiệu lực (nếu có) kèm `effectiveFrom`.

**Kết quả.** API có cam kết chất lượng rõ ràng, hiển thị trong danh mục.

**Hậu điều kiện.** Cam kết lưu; lịch sử cam kết thêm một dòng.

**Sự kiện phát ra.** EVT-02-02 (`changedFields = sla`); EVT-02-12 khi cam kết kém đi.

**Kiểm toán.** Có: giá trị trước, sau, `effectiveFrom`.

**Quy tắc nghiệp vụ.** BR-02-013; BR-02-029; BR-02-031.

**Màn hình, API.** UI-02-02 tab SLA, UI-02-03 bước 4, UI-02-11; API-02-073, API-02-074.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `latencyP99Ms` | số nguyên | Có | 50…60.000, độ trễ p99 cam kết ở gateway | `3000` |
| `availability` | số thập phân | Có | 0,900…0,99999, tỷ lệ sẵn sàng trong giờ phục vụ | `0,995` |
| `hourlyLimit` | số nguyên | Có | 1…10.000.000, lượt gọi tối đa mỗi giờ toàn API | `5000` |
| `serviceHours` | T-TEXT | Có | `24x7` hoặc `HH:mm-HH:mm T2-T6` | `07:30-17:30 T2-T6` |
| `maintenanceWindows[]` | danh sách | Không | Cửa sổ bảo trì định kỳ, không tính vào tỷ lệ sẵn sàng; tổng ≤ 8 giờ mỗi tháng | `CN 00:00-04:00` |
| `supportContact` | T-TEXT | Có | Đầu mối hỗ trợ (thư điện tử, điện thoại) | `ht.sotuphap@t68.gov.vn` |

: Dữ liệu vào của FR-02-055

#### FR-02-056 · Đối chiếu SLA thực tế, báo cáo tuân thủ

::: dac-ta
**Mục đích.** Tự động so cam kết với số đo thực tế mỗi tháng, hiển thị cả hai cạnh nhau trong danh mục (minh bạch với bên khai thác) và cảnh báo khi dịch vụ liên tục không đạt cam kết.

**Tác nhân, quyền.** Hệ thống (lịch); mọi vai trò có `PERM-02-read` xem kết quả; SV (○), CA, TA nhận cảnh báo; PH-13, PH-16 đọc.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02, REQ-13, REQ-16; SRS cũ FR-02-012; BR-02-013, BR-02-031.

**Tiền điều kiện.** Phiên bản có cam kết SLA và đã `PUBLISHED` ít nhất một phần của kỳ.

**Kích hoạt.** Lịch ngày 1 hằng tháng lúc 02:00 giờ Việt Nam chốt kỳ trước; tính tạm theo ngày cho kỳ hiện tại lúc 03:00; người dùng mở UI-02-11.

**Đầu vào.** `periodFrom`, `periodTo` (theo tháng, `YYYY-MM`); `apiCode`, `status` (`MET`, `BREACHED`, `INSUFFICIENT`); `consecutiveBreaches`.

**Luồng xử lý chính.**

1. Hệ thống lấy từ PH-13, cho mỗi phiên bản và kỳ: độ trễ p99 ở gateway, tổng lượt gọi, số lượt lỗi do hệ thống (`5xx`, hết thời gian chờ, backend không đáp ứng; không tính `4xx` do bên gọi), thời gian ngừng trong giờ phục vụ.
2. Hệ thống loại khỏi tính toán: thời gian `SUSPENDED` do quyết định quản lý, cửa sổ bảo trì đã khai, ngoài giờ phục vụ.
3. Hệ thống tính tỷ lệ sẵn sàng thực tế, độ trễ p99 thực tế, lượt cao nhất mỗi giờ; so từng chỉ tiêu với cam kết hiệu lực trong kỳ (kể cả cam kết kém đi theo `effectiveFrom`).
4. Nếu kỳ có dưới `02.sla.min-days-data` ngày dữ liệu hoặc dưới `02.sla.min-calls` lượt gọi (BR-02-031): kết luận `INSUFFICIENT`, hiển thị "Chưa đủ dữ liệu", không kết luận đạt hay không đạt.
5. Hệ thống ghi kỳ tuân thủ (`met` đạt khi cả ba chỉ tiêu đạt), đếm số kỳ không đạt liên tiếp; từ `02.sla.breach-periods` kỳ (mặc định 3) trở lên thì gửi cảnh báo cho SV, CA, TA kèm gợi ý hành động: điều chỉnh cam kết cho thực tế (FR-02-055), cải thiện backend, hoặc xem xét ngừng dùng.
6. Hệ thống phát EVT-02-13 mỗi lần chốt kỳ, cập nhật danh mục (cam kết cạnh thực tế, nhãn cảnh báo "Không đạt {n} kỳ liên tiếp") và chuyển chỉ số cho PH-16.

**Luồng thay thế.** TA bấm "Chốt lại kỳ" sau khi PH-13 bổ sung dữ liệu bị trễ: hệ thống tính lại, ghi `recalculatedAt`.

**Luồng ngoại lệ.**

- PH-13 không khả dụng khi chốt kỳ: ERR-02-034 (503) ghi nhật ký; kỳ để `PENDING`, thử lại mỗi giờ tới 24 giờ; danh mục hiển thị kỳ gần nhất kèm thời điểm.
- Phiên bản không có cam kết: bỏ qua, không phải lỗi (không đủ điều kiện gửi duyệt nên hiếm).
- Tham số lọc sai: ERR-02-003 (400).

**Đầu ra.** `200`; `periods[]` (`period`, `committed`, `actual`, `met`, `status`, `consecutiveBreaches`), `compliance` (tỷ lệ kỳ đạt 12 tháng), `asOf`.

**Kết quả.** Bên khai thác thấy SLA thực tế cạnh cam kết; quản lý phát hiện dịch vụ liên tục không đạt.

**Hậu điều kiện.** Kỳ tuân thủ ghi vào bảng; cờ cảnh báo cập nhật.

**Sự kiện phát ra.** EVT-02-13 (`sla.period-closed`).

**Kiểm toán.** Có cho việc chốt lại kỳ (người, lý do); chốt tự động chỉ ghi nhật ký vận hành.

**Quy tắc nghiệp vụ.** BR-02-013; BR-02-031.

**Màn hình, API.** UI-02-11, UI-02-01 (chỉ báo), UI-02-02 tab SLA; API-02-074, API-02-075, API-02-097 (tổng hợp SLA toàn tenant).
:::

```{.mermaid caption="Trình tự chốt kỳ tuân thủ SLA hằng tháng"}
sequenceDiagram
  autonumber
  participant L as Lịch ngày 1
  participant C as PH-02 Bộ tính SLA
  participant P as PH-13 Số đo
  participant N as Trung tâm thông báo
  participant K as PH-16
  L->>C: Chốt kỳ YYYY-MM
  C->>P: Lấy p99, lượt gọi, lỗi hệ thống theo phiên bản
  P-->>C: Số đo theo kỳ
  C->>C: Loại tạm ngừng, bảo trì, ngoài giờ
  C->>C: So cam kết, kết luận MET, BREACHED, INSUFFICIENT
  alt Không đạt từ 3 kỳ liên tiếp
    C->>N: Cảnh báo SV, CA, TA
  end
  C->>K: Chỉ số tuân thủ SLA
```

Hình trên cho thấy việc chốt kỳ chạy hoàn toàn tự động từ số đo của PH-13; các khoảng tạm ngừng, bảo trì, ngoài giờ bị loại trước khi so, và cảnh báo chỉ phát khi đủ số kỳ không đạt liên tiếp.

#### FR-02-057 · Thông báo thay đổi cho bên khai thác

::: dac-ta
**Mục đích.** Bảo đảm mọi bên đang dùng API biết ngay khi API thay đổi theo cách ảnh hưởng tới họ: có phiên bản mới phá vỡ, ngừng khuyến nghị, tạm ngừng, thay đổi SLA, ngừng hẳn. Không thông báo được thì mọi lộ trình ngừng dùng đều vô nghĩa.

**Tác nhân, quyền.** Hệ thống (theo sự kiện); SV (○), TA có `PERM-02-create` gửi thông báo tay.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; SRS cũ FR-02-013; FR-00-060, 061, 062; BR-02-029.

**Tiền điều kiện.** Có sự kiện thuộc các loại ở bảng dưới; có ít nhất một bên nhận.

**Kích hoạt.** Hệ thống nhận các sự kiện FR-02-031, 036, 037, 038, 039, 041, 055; hoặc SV bấm "Gửi thông báo" ở UI-02-13.

**Đầu vào.** `kind` (T-ENUM, bảng dưới), `apiCode`, `versionNo`; thông báo tay: `subject`, `message` (T-TEXT ≤ 2000 ký tự), `audience` (`ALL_ACTIVE`, `PLAN`, `SYSTEMS`).

**Luồng xử lý chính.**

1. Hệ thống xác định bên nhận: các HTTT có đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` của phiên bản hoặc gói bị ảnh hưởng, gộp trùng theo HTTT; kèm đầu mối kỹ thuật của HTTT từ PH-01.
2. Hệ thống dựng nội dung từ mẫu theo `kind`: nêu API, phiên bản, điều thay đổi, thời điểm hiệu lực, việc bên nhận cần làm, liên kết tới chi tiết; nội dung không chứa dữ liệu Hạn chế hay Nhạy cảm (FR-00-062).
3. Hệ thống gửi qua các kênh: thông báo trong ứng dụng (FR-00-060), thư điện tử tới đầu mối kỹ thuật (chỉ chứa liên kết vào ứng dụng), và sự kiện EVT-02-12 cho PH-15 (đăng trên trang tài liệu) và PH-18.
4. Loại bắt buộc (BR-02-029) không cho bên nhận tắt; loại thông tin tuân theo tùy chọn kênh của người dùng (FR-00-061).
5. Hệ thống ghi từng lần gửi (`SENT`, `READ`, `FAILED`) theo bên nhận; thất bại thì thử lại 3 lần (5, 30, 120 phút); vẫn thất bại thì hiện cảnh báo cho SV và đánh dấu bên nhận chưa nhận được trên UI-02-13.
6. Hệ thống đạt thời gian gửi trong ứng dụng ≤ 15 phút và thư ≤ 1 giờ (NFR-02-015).

**Luồng thay thế.** SV gửi thông báo tay (thông báo bảo trì, thay đổi mô tả); loại này là thông tin, tối đa 3 lần mỗi ngày mỗi API để tránh làm phiền.

**Luồng ngoại lệ.**

- Không có bên nhận: bỏ qua, ghi `NO_RECIPIENTS`; không phải lỗi.
- Gửi thư thất bại hoặc không có đầu mối: ERR-02-034 chỉ ghi nhật ký; thông báo trong ứng dụng vẫn gửi; cảnh báo SV "Không gửi được thư tới {HTTT}."
- Thông báo tay vượt số lần cho phép: ERR-02-036 (429); "Đã gửi quá số thông báo cho phép hôm nay."
- Thiếu nội dung: ERR-02-003 (400); "Cần nhập tiêu đề và nội dung."

**Đầu ra.** `202`; `noticeId`, số bên nhận, trạng thái theo kênh; chi tiết: danh sách bên nhận kèm trạng thái.

**Kết quả.** Mọi bên đang dùng API nhận được thông báo kịp thời, và chủ dịch vụ biết ai đã nhận.

**Hậu điều kiện.** Bản ghi thông báo và trạng thái gửi theo từng bên nhận được lưu 2 năm.

**Sự kiện phát ra.** EVT-02-12 (`change.notice-issued`).

**Kiểm toán.** Có: loại, API, số bên nhận, người gửi (thông báo tay); thông báo tự động ghi nhật ký vận hành.

**Quy tắc nghiệp vụ.** BR-02-029; BR-02-004.

**Màn hình, API.** UI-02-13; API-02-076, API-02-077.
:::

| `kind` | Khi nào | Bắt buộc | Bên nhận |
|---|---|---|---|
| `VERSION_PUBLISHED_BREAKING` | Phiên bản mới có thay đổi phá vỡ được công bố song song | Có | Bên đăng ký các phiên bản trước của API |
| `VERSION_PUBLISHED` | Phiên bản mới tương thích thay thế phiên bản cũ | Không | Bên đăng ký phiên bản cũ |
| `DEPRECATION` | Phiên bản hoặc gói được ngừng khuyến nghị | Có | Bên đăng ký phiên bản, gói |
| `DEPRECATION_REMINDER` | Mốc 90, 30, 7 ngày và hằng tuần tháng cuối | Có | Bên chưa chuyển |
| `SUSPENSION`, `RESUMPTION` | Tạm ngừng, tiếp tục API | Có | Mọi bên đăng ký của phiên bản |
| `RETIREMENT` | Ngừng hẳn phiên bản | Có | Bên từng đăng ký (đã đóng) và chủ dịch vụ |
| `SLA_WORSENED` | Cam kết SLA kém đi | Có | Mọi bên đăng ký |
| `VISIBILITY_LOWERED` | Hạ mức hiển thị hoặc gỡ khỏi cổng khi có bên ngoài tenant | Có | Bên đăng ký |
| `SUBSCRIPTION_DECISION` | Duyệt, từ chối, thu hồi, tạm ngừng đăng ký | Có | HTTT liên quan |
| `ANNOUNCEMENT` | Thông báo tay của chủ dịch vụ | Không | Theo `audience` |
| `OWNER_CHANGED` | Chuyển chủ quản API | Không | Bên đăng ký |

: Loại thông báo thay đổi

#### FR-02-058 · Thống kê sử dụng dịch vụ

::: dac-ta
**Mục đích.** Cho chủ dịch vụ, người duyệt và quản trị thấy mức sử dụng thực của từng API: bao nhiêu lượt, bao nhiêu bên dùng, tỷ lệ lỗi, độ trễ, xu hướng, API nào không ai dùng; làm căn cứ quyết định duy trì, nâng cấp hay ngừng dịch vụ.

**Tác nhân, quyền.** Mọi vai trò có `PERM-02-read` (số tổng); SV (○), CA, TA (chi tiết theo bên khai thác); PH-16 đọc chỉ số tổng.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-02; SRS cũ FR-02-014; REQ-13, REQ-16.

**Tiền điều kiện.** Phiên bản đã từng `PUBLISHED`; PH-13 có số đo.

**Kích hoạt.** Người dùng mở tab Thống kê ở UI-02-02 hoặc UI-02-11; PH-16 gọi định kỳ.

**Đầu vào.** `apiCode`, `versionNo`; `window` (`7d`, `30d`, `90d`, `12m`); `groupBy` (`day`, `week`, `month`).

**Luồng xử lý chính.**

1. Hệ thống lấy từ PH-13 chuỗi thời gian theo phiên bản: số lượt gọi, số HTTT khác nhau, tỷ lệ lỗi `4xx` và `5xx`, độ trễ p50, p95, p99.
2. Hệ thống tính xu hướng so với kỳ trước (tăng, giảm, phần trăm) và xếp hạng các bên khai thác theo lượt gọi (chi tiết tên bên khai thác chỉ cho người có quyền chi tiết; người khác thấy "Bên khai thác A, B…").
3. Hệ thống đánh dấu API **không dùng**: không có lượt gọi trong 90 ngày dù có đăng ký `ACTIVE`, gợi ý SV rà soát hoặc ngừng khuyến nghị.
4. Hệ thống tổng hợp cho cấp tenant: số API theo trạng thái, tổng lượt gọi, top API, tỷ lệ API đạt SLA; chuyển PH-16 làm chỉ tiêu.
5. Người dùng bấm "Xuất" để xuất bảng số liệu theo bộ lọc (FR-00-030).

**Luồng thay thế.** Chọn khoảng thời gian tùy chọn bằng bộ chọn ngày; khoảng quá 12 tháng bị từ chối.

**Luồng ngoại lệ.**

- PH-13 không khả dụng: hiển thị số liệu gần nhất đã đệm kèm thời điểm; "Số liệu cập nhật lúc {thời điểm}."; ERR-02-034 chỉ ghi nhật ký.
- Phiên bản chưa có số đo: trả khung rỗng, "Chưa có số liệu sử dụng."
- Tham số khoảng thời gian sai: ERR-02-003 (400).

**Đầu ra.** `200`; `series[]` (`time`, `calls`, `consumers`, `errorRate4xx`, `errorRate5xx`, `p95Ms`), `topConsumers[]`, `unused`, `trend`.

**Kết quả.** Người quản lý có số liệu thật để quyết định về từng dịch vụ.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với số tổng; có khi người có quyền chi tiết xem theo bên khai thác của API không thuộc tổ chức mình.

**Quy tắc nghiệp vụ.** BR-02-033.

**Màn hình, API.** UI-02-11, UI-02-02 tab Thống kê; API-02-078, API-02-079.
:::

### 6.11. Nhóm J · Tích hợp và quản trị

Nhóm J gồm những việc không có người dùng cuối nhưng làm cho phân hệ vận hành được: giao diện nội bộ cho PH-03, PH-04, PH-15; đối soát cấu hình với gateway; đưa dữ liệu từ APIM cũ sang theo cách strangler; và tham số theo tenant.

```{.mermaid caption="Các chức năng nhóm J và đối tác"}
flowchart TB
  S["FR-02-059<br/>Giao diện nội bộ"] --> P3["PH-03<br/>Cấu hình gateway"]
  S --> P15["PH-15<br/>Cổng nhà phát triển"]
  S --> P4["PH-04<br/>Luồng"]
  R["FR-02-060<br/>Đối soát cấu hình"] --> P3
  M["FR-02-061<br/>Di trú từ APIM cũ"] --> D["Danh mục PH-02"]
  T["FR-02-062<br/>Tham số tenant"] --> P18["PH-18<br/>Kho tham số"]
```

Hình trên cho thấy PH-02 chỉ làm nguồn dữ liệu cho PH-03, PH-04, PH-15 qua giao diện nội bộ; đối soát kiểm tra ngược PH-03; di trú và tham số là hai chức năng quản trị độc lập.

#### FR-02-059 · Cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15

::: dac-ta
**Mục đích.** Cho các phân hệ liền kề đọc dữ liệu công bố từ PH-02 một cách chuẩn và ổn định: PH-03 lấy dữ liệu để sinh ảnh chụp cấu hình gateway, PH-15 lấy danh mục để hiển thị, PH-04 lấy đặc tả để dựng luồng. Không phân hệ nào đọc thẳng bảng của PH-02.

**Tác nhân, quyền.** PH-03 (scope `catalog:gateway-read`), PH-15 (`catalog:portal-read`), PH-04 (`catalog:flow-sync`), PH-13, PH-16 (`catalog:metrics-read`); không có người dùng.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; ADR-013; D03-09 §6.1; SEC-15.

**Tiền điều kiện.** Tài khoản dịch vụ của phân hệ gọi đã được cấp scope tương ứng khi triển khai.

**Kích hoạt.** PH-03 khi cần dựng ảnh chụp cấu hình (sau EVT-02-05, 06, 08, 10, 11 hoặc đối soát); PH-15 khi nạp danh mục; PH-04 khi tạo luồng từ API; PH-13, PH-16 theo lịch.

**Đầu vào.** Theo từng giao diện: `environment`, `sinceConfigVersion` (PH-03); `updatedSince`, `page`, `size` (PH-15); `apiCode`, `versionNo` (PH-04); `period` (PH-13, PH-16).

**Luồng xử lý chính.**

1. Phân hệ gọi trình token dịch vụ qua mesh mTLS; PH-02 kiểm tra danh tính SPIFFE và scope (SEC-15, SEC-26); sai thì từ chối (ERR-02-014).
2. Với PH-03: PH-02 trả bộ dữ liệu công bố cho môi trường yêu cầu gồm API, phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED`, backend kèm cấu hình cân bằng tải và kiểm tra sức khỏe, gói, đăng ký `ACTIVE` kèm consumer, thao tác từ đặc tả, kèm `sourceVersion` tăng dần và băm toàn bộ.
3. Với PH-15: PH-02 trả danh mục như FR-02-004 nhưng kèm các mục `portalPublished` và tệp đặc tả đã gộp, cùng danh sách mã đã gỡ.
4. Với PH-04: PH-02 trả đặc tả đã gộp tham chiếu của phiên bản (FR-02-006) và thông tin đầu mối, nhãn phân loại.
5. Với PH-13, PH-16: PH-02 trả chỉ số tuân thủ (số API theo trạng thái, kỳ SLA đạt, đồng bộ quốc gia, đăng ký theo trạng thái) ở mức tổng, không chứa tên bên khai thác.
6. Mọi giao diện hỗ trợ `If-None-Match`/`ETag` và trả `304` khi chưa đổi; mọi giao diện chỉ đọc, idempotent; hợp đồng giữ tương thích ngược ở `v1` (NFR-02-018).

**Luồng thay thế.** PH-03 nhận sự kiện báo thay đổi rồi mới gọi lấy dữ liệu (kéo theo sự kiện); khi mất sự kiện, PH-03 gọi định kỳ 5 phút để bù (kéo theo lịch).

**Luồng ngoại lệ.**

- Thiếu scope hoặc sai danh tính: ERR-02-014 (403); không có màn hình, lỗi ghi nhật ký.
- Môi trường không hợp lệ: ERR-02-003 (400).
- PH-02 đang bảo trì: `503` kèm `Retry-After`; PH-03 giữ cấu hình đang chạy, không đổi gì (NFR-02-008).

**Đầu ra.** `200` hoặc `304`; bộ dữ liệu theo giao diện; tiêu đề `ETag`, `X-DH-Source-Version`.

**Kết quả.** PH-03, PH-04, PH-15 có nguồn dữ liệu chuẩn, nhất quán với PH-02.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không cho lần đọc; truy cập bị từ chối ghi nhật ký an ninh (SEC-61).

**Quy tắc nghiệp vụ.** BR-02-025; BR-02-033.

**Màn hình, API.** Không có màn hình; API-02-080, API-02-081, API-02-082 (và API-02-007 cho PH-04).
:::

#### FR-02-060 · Đối soát cấu hình công bố với gateway

::: dac-ta
**Mục đích.** Phát hiện sớm khi cấu hình đang chạy ở gateway lệch khỏi những gì PH-02 đã công bố (route thừa, route thiếu, backend sai, consumer sai) do lỗi đồng bộ hoặc ai đó sửa tay, để không có API "ma" hoặc API đã công bố mà không gọi được.

**Tác nhân, quyền.** Hệ thống (lịch mỗi 5 phút); TO, TA có `PERM-02-operate` để chạy tay và đẩy lại.

**Mức ưu tiên, đợt.** C · Đợt 2.

**Truy vết.** REQ-02; SEC-65 (giám sát toàn vẹn cấu hình); ADR-013 (phát hiện lệch).

**Tiền điều kiện.** PH-03 cho biết số phiên bản và băm cấu hình đã nạp của từng môi trường.

**Kích hoạt.** Lịch mỗi 5 phút; hoặc người dùng bấm "Đối soát ngay" ở UI-02-17.

**Đầu vào.** `environment`; `autoRepair` (đọc từ `02.reconcile.auto-repair`).

**Luồng xử lý chính.**

1. Hệ thống hỏi PH-03 số phiên bản cấu hình và băm đã nạp của từng pod APISIX ở môi trường.
2. Hệ thống tính "cấu hình mong đợi" từ dữ liệu công bố của PH-02 (FR-02-059) và so với danh sách route, upstream, consumer thực tế do PH-03 báo.
3. Hệ thống phân loại lệch: `MISSING_ROUTE` (đã công bố mà gateway không có), `EXTRA_ROUTE` (gateway có mà PH-02 không công bố), `UPSTREAM_MISMATCH`, `CONSUMER_MISMATCH`, `VERSION_BEHIND` (gateway chậm hơn phiên bản mong đợi quá 60 giây).
4. Không lệch: ghi `inSync = true`, cập nhật chỉ số. Có lệch: tạo cảnh báo cho TO, TA, hiển thị chi tiết lệch ở UI-02-17 và đánh dấu API trong UI-02-01 (thẻ "Cần chú ý").
5. Nếu `02.reconcile.auto-repair = true` và lệch thuộc `MISSING_ROUTE`, `UPSTREAM_MISMATCH`, `CONSUMER_MISMATCH`, `VERSION_BEHIND`: hệ thống yêu cầu PH-03 dựng và đẩy lại ảnh chụp; `EXTRA_ROUTE` không tự gỡ mà chỉ cảnh báo SO (có thể là tấn công hoặc sửa tay).
6. Hệ thống phát EVT-02-15 và chỉ số `catalog_gateway_drift_total`; phát hiện lệch được phát hiện trong ≤ 10 phút (NFR-02-020).

**Luồng thay thế.** TO bấm "Đẩy lại cấu hình" cho một môi trường: hệ thống gọi PH-03 dựng lại ảnh chụp ngay.

**Luồng ngoại lệ.**

- PH-03 không khả dụng: ERR-02-034 (503); bỏ qua lượt, cảnh báo nếu quá 15 phút không đối soát được.
- Môi trường không có gateway: bỏ qua, ghi nhật ký.
- Đang có lần đối soát chạy: ERR-02-035 (409); "Đang đối soát, vui lòng chờ."

**Đầu ra.** `200`; `inSync`, `drifts[]` (`kind`, `apiCode`, `versionNo`, `detail`), `gatewayConfigVersion`, `expectedVersion`; chạy tay: `202`.

**Kết quả.** Vận hành biết tức thì khi cấu hình gateway và danh mục không khớp.

**Hậu điều kiện.** Bản ghi đối soát lưu 90 ngày; cảnh báo mở khi còn lệch.

**Sự kiện phát ra.** EVT-02-15 (`gateway.drift-detected`).

**Kiểm toán.** Có cho lệnh đẩy lại và tự sửa (người, môi trường, kết quả); lượt đối soát tự động chỉ ghi nhật ký.

**Quy tắc nghiệp vụ.** BR-02-025.

**Màn hình, API.** UI-02-17; API-02-083, API-02-084, API-02-095 (tiến độ tác vụ).
:::

#### FR-02-061 · Di trú API, gói, đăng ký từ APIM cũ

::: dac-ta
**Mục đích.** Đưa định nghĩa API, plan và subscription của khối API Management cũ (Gravitee) sang danh mục mới theo cách strangler: giữ liên tục cho HTTT đang chạy, nhưng buộc bổ sung phần còn thiếu (đặc tả OpenAPI, phân loại, xác thực phù hợp) và không mang khóa cũ sang.

**Tác nhân, quyền.** TA, PA có quyền quản trị phân hệ (đề nghị, động từ `admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; FR-00-090, 091, 092, 093; LGC-APIM-002; 003, 009, 016, 021; BR-02-036.

**Tiền điều kiện.** Tệp xuất từ APIM cũ (JSON của các API, plan, subscription và danh sách Application); bảng ánh xạ Application cũ sang HTTT mới (`applicationMap`) đã chuẩn bị với PH-01.

**Kích hoạt.** Người dùng bấm "Nhập từ APIM cũ" ở UI-02-16.

**Đầu vào.** Theo bảng dữ liệu vào của FR-02-061 dưới đây.

**Luồng xử lý chính.**

1. Người dùng tải tệp gói xuất (tối đa 50 MiB) và `applicationMap`; hệ thống quét mã độc, kiểm tra định dạng (ERR-02-045).
2. Hệ thống phân tích và hiển thị **bản xem trước** theo từng API (FR-00-032): tên, phiên bản, mô tả, context-path cũ, backend, trạng thái cũ, plan, subscription, kèm đề xuất ánh xạ và các vấn đề phải xử lý.
3. Với mỗi API, hệ thống đề xuất tạo API `origin = LEGACY` ở trạng thái `DRAFT`: giữ tên, mô tả, backend (chuyển thành backend loại `SYSTEM` chờ kết nối PH-05), context-path cũ giữ làm bí danh `legacyPath` cho giai đoạn chạy song song; nếu có Swagger thì nạp làm đặc tả (FR-02-011), nếu không thì đặc tả khung ở trạng thái "Cần bổ sung".
4. Hệ thống ánh xạ plan: bốn trạng thái cũ sang `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED`; Keyless hoặc API key sang kiểu xác thực tương ứng và kiểm tra ràng buộc mức phân loại (BR-02-016), vi phạm thì đánh dấu "Cần nâng xác thực" thay vì chặn nhập.
5. Hệ thống ánh xạ subscription theo `applicationMap`: tạo đăng ký ở `SUSPENDED` với lý do `MIGRATED_AWAITING_CREDENTIAL` cho tới khi HTTT mới có định danh máy ở PH-01 (BR-02-036, FR-00-093); khóa API cũ không nhập; mọi chuỗi giống khóa trong tệp bị loại và báo.
6. Người dùng xem, sửa ánh xạ rồi bấm "Xác nhận nhập"; hệ thống ghi **tất cả hoặc không** cho mỗi API (hoặc cho cả gói nếu chọn), idempotent theo `legacyId` để nhập lại không nhân đôi.
7. Hệ thống sinh **báo cáo đối chiếu**: số API, plan, subscription ở nguồn và đã nhập, tổng kiểm tra, danh sách chưa nhập kèm lý do (FR-00-092); API chưa có đặc tả hợp lệ không thể gửi duyệt cho tới khi bổ sung.

**Luồng thay thế.** Chạy "chỉ kiểm tra" không ghi: chỉ sinh bản xem trước và báo cáo. Nhập một phần: người dùng bỏ chọn API có lỗi, nhập phần còn lại.

**Luồng ngoại lệ.**

- Tệp sai định dạng: ERR-02-045 (400); "Tệp không phải gói xuất APIM hợp lệ: {lý do}."
- Tệp quá lớn: ERR-02-009 (413); "Tệp vượt 50 MiB."
- Mã API sau chuyển đã dùng: ERR-02-002 (409) cho API đó, API khác vẫn nhập được; bản xem trước đề xuất đổi mã.
- HTTT trong `applicationMap` không `ACTIVE`: ERR-02-004 (422) cho các đăng ký liên quan; chúng không nhập, được liệt kê.
- Đang có lần nhập chạy: ERR-02-035 (409); "Đang có lần nhập khác chạy."

**Đầu ra.** `201` (xác nhận) kèm `importId`; báo cáo `{apis, plans, subscriptions, created, skipped, issues[], checksum}`; bản xem trước `200`.

**Kết quả.** Danh mục có dữ liệu từ APIM cũ ở dạng bản nháp, kèm danh sách việc cần bổ sung, không mang khóa cũ sang.

**Hậu điều kiện.** API, gói, đăng ký mới được tạo ở `DRAFT`, `STAGING`, `SUSPENDED`; bản ghi nhập lưu vĩnh viễn.

**Sự kiện phát ra.** EVT-02-01 cho từng API tạo.

**Kiểm toán.** Có: người nhập, tệp (băm), số lượng, báo cáo đối chiếu.

**Quy tắc nghiệp vụ.** BR-02-015; BR-02-016; BR-02-021; BR-02-036.

**Màn hình, API.** UI-02-16; API-02-085, API-02-086, API-02-087.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `bundle` | tệp | Có | JSON hoặc ZIP, ≤ 50 MiB, đã quét mã độc | `apim-export-20261120.zip` |
| `applicationMap` | tệp CSV hoặc JSON | Không | Ánh xạ `applicationId` cũ sang `systemCode` ở PH-01 | `app-17,HT-MOTCUA` |
| `mode` | T-ENUM | Có | `PREVIEW`, `COMMIT` | `PREVIEW` |
| `scope` | T-ENUM | Không | `ALL`, `SELECTED` (kèm `legacyIds[]`) | `ALL` |
| `defaultOwnerOrgCode` | T-CODE | Không | Đơn vị chủ quản mặc định khi nguồn không cho biết | `SO-TTTT` |
| `defaultCategoryCode` | T-CODE | Không | Nhóm mặc định | `khac` |

: Dữ liệu vào của FR-02-061

#### FR-02-062 · Cấu hình tham số của phân hệ

::: dac-ta
**Mục đích.** Cho quản trị tenant điều chỉnh các ngưỡng, thời hạn, lịch của PH-02 theo thực tế của tỉnh mà không cần phát hành lại phần mềm, trong phạm vi trần do nền tảng đặt.

**Tác nhân, quyền.** TA, PA có quyền quản trị phân hệ (đề nghị, động từ `admin`); mọi vai trò có `PERM-02-read` xem.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-02; PH-18 (kho tham số); SRS cũ.

**Tiền điều kiện.** PH-18 khả dụng (hoặc đọc giá trị mặc định đã đệm).

**Kích hoạt.** Quản trị mở UI-02-17 "Cài đặt phân hệ".

**Đầu vào.** `key`, `value` (T-JSON theo kiểu của tham số), `reason` (bắt buộc).

**Luồng xử lý chính.**

1. Quản trị mở danh sách tham số `02.*` (mục 8.2) kèm mặc định, miền, giá trị hiệu lực, ý nghĩa.
2. Quản trị sửa một tham số; hệ thống kiểm tra kiểu và miền giá trị, và trần do PA đặt cho tenant (ERR-02-003, ERR-02-040).
3. Hệ thống kiểm tra phụ thuộc giữa tham số (ví dụ `02.deprecation.min-days` không nhỏ hơn mốc nhắc lớn nhất, `02.sla.breach-periods` ≥ 2).
4. Hệ thống ghi giá trị qua PH-18, có hiệu lực trong 60 giây (bộ đệm), và hiển thị tác động ước tính nếu có (ví dụ số đăng ký sẽ vào diện rà soát).
5. Hệ thống ghi kiểm toán giá trị trước và sau; tham số liên quan bảo mật (ngưỡng tự duyệt, bật quét bí mật) sinh thông báo cho SO.

**Luồng thay thế.** Quản trị bấm "Về mặc định" cho một tham số hoặc cả nhóm.

**Luồng ngoại lệ.**

- Giá trị ngoài miền: ERR-02-003 (400); "Giá trị {tham số} phải nằm trong {a}…{b}."
- Vượt trần: ERR-02-040 (422); "Giá trị vượt trần {giá trị} do nền tảng đặt."
- Thiếu lý do: ERR-02-041 (400); "Cần nêu lý do thay đổi."
- PH-18 không khả dụng: ERR-02-034 (503); "Không lưu được tham số lúc này. Thử lại sau."

**Đầu ra.** `200`; danh sách tham số với giá trị hiệu lực (`GET`), hoặc tham số vừa sửa với `effectiveAt`.

**Kết quả.** Phân hệ chạy theo ngưỡng phù hợp tỉnh, thay đổi có hiệu lực trong vòng một phút.

**Hậu điều kiện.** Giá trị mới ở PH-18; PH-02 áp dụng sau khi đệm hết hạn.

**Sự kiện phát ra.** Không (PH-18 phát sự kiện đổi tham số của mình).

**Kiểm toán.** Có: khóa, giá trị trước, sau, lý do, người sửa.

**Quy tắc nghiệp vụ.** BR-02-028.

**Màn hình, API.** UI-02-17; API-02-088, API-02-089.
:::

## 7. Quy tắc nghiệp vụ

Bảng dưới gom 40 quy tắc nghiệp vụ của PH-02. Quy tắc đánh số `BR-02-001…015` kế thừa số và ý của bảng quy tắc ở SRS cũ (mục 11.2), phần còn lại bổ sung theo yêu cầu của hệ mới. Cột "FR áp dụng" ghi số thứ tự của FR-02-nnn.

| Mã | Quy tắc | FR áp dụng |
|---|---|---|
| BR-02-001 | Mỗi phiên bản API công bố có đặc tả OpenAPI 3.1 hợp lệ, có mô tả tiếng Việt, và đặc tả tải về được từ danh mục (nghĩa vụ công bố tài liệu kỹ thuật kèm dịch vụ chia sẻ, CMP-LAW-03). Thiếu thì không được công bố | 004, 006, 010, 011, 012, 013, 016, 017, 019, 034, 036 |
| BR-02-002 | Mô tả API, thao tác, tham số viết bằng tiếng Việt vì người đọc là cán bộ kỹ thuật các sở. Lớp 2 chỉ cảnh báo phần ngôn ngữ, nhưng mô tả tổng thể của API bắt buộc có | 015, 017, 021 |
| BR-02-003 | Thay đổi phá vỡ tương thích bắt buộc tăng số phiên bản chính; số chính nằm trong đường dẫn công bố (`/v1`, `/v2`) | 024, 034, 036, 042, 043 |
| BR-02-004 | Ngừng khuyến nghị có hạn chuyển đổi tối thiểu `02.deprecation.min-days` (mặc định 180 ngày). Ngắn hơn chỉ khi có lý do khẩn chính đáng và TA đồng ý trong yêu cầu duyệt; có đăng ký đang hiệu lực thì mốc nhắc theo lịch 90, 30, 7 ngày | 031, 038, 044, 057 |
| BR-02-005 | Ngừng khuyến nghị phải có phiên bản kế nhiệm đang `PUBLISHED`, hoặc xác nhận rõ là ngừng hẳn dịch vụ | 038 |
| BR-02-006 | Không tự động chuyển `RETIRED` khi còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED`; tới hạn thì cảnh báo và chờ người can thiệp | 039, 044 |
| BR-02-007 | Dữ liệu thuộc danh mục bí mật nhà nước không được công bố qua Datahub; API khai `stateSecret = true` bị từ chối | 007, 010, 018 |
| BR-02-008 | Bốn mắt: người duyệt khác người gửi duyệt, khác người sửa gần nhất đặc tả hoặc gói; SV không giữ vai trò CA (D02-08 §4); API `SENSITIVE` cần thêm xác nhận của TA khác CA | 020, 030, 031, 034, 035, 038, 039, 041, 047 |
| BR-02-009 | API mức hiển thị `NATIONAL`, `PUBLIC` phải được đồng bộ lên Nền tảng quốc gia (CMP-LAW-03, CMP-LAW-19); quá `02.sync.overdue-days` ngày chưa đồng bộ thì phát cảnh báo tuân thủ | 041, 053, 054 |
| BR-02-010 | Khung route sinh cho PH-04 theo khung chín chặng chuẩn (BR-04-002); PH-02 không sinh logic nghiệp vụ | 026 |
| BR-02-011 | Chỉ HTTT `ACTIVE` ở PH-01 mới đăng ký sử dụng được; chỉ phiên bản `PUBLISHED` và gói `PUBLISHED` nhận đăng ký mới | 046 |
| BR-02-012 | Đăng ký sử dụng phải khai mục đích và khối lượng dự kiến (phục vụ rà soát quyền định kỳ); dữ liệu cá nhân hoặc từ mức Hạn chế phải nêu căn cứ pháp lý (CMP-LAW-05) | 046, 047, 052 |
| BR-02-013 | SLA thực tế hiển thị cạnh SLA cam kết; không kết luận đạt hay không đạt khi chưa đủ dữ liệu | 002, 055, 056 |
| BR-02-014 | Đặc tả và mọi phiên bản của API giữ vĩnh viễn, kể cả `RETIRED` và đã xóa mềm, làm bằng chứng hợp đồng API | 006, 011, 012, 014, 016, 036, 039, 040, 042 |
| BR-02-015 | Đặc tả không chứa bí mật hoặc dữ liệu cá nhân thật ở phần ví dụ; phát hiện thì chặn gửi duyệt, duyệt và công bố | 011, 018, 019, 034, 061 |
| BR-02-016 | Kiểu xác thực của gói theo mức phân loại: `KEYLESS` chỉ với dữ liệu `PUBLIC` và mức hiển thị `PUBLIC`; `INTERNAL` từ `API_KEY` trở lên; `RESTRICTED` chỉ `OAUTH2_PKJWT` hoặc `OAUTH2_MTLS`; `SENSITIVE` chỉ `OAUTH2_MTLS` (SEC-24) | 007, 017, 028, 030, 033, 048, 061 |
| BR-02-017 | Gói `PUBLISHED` chỉ sửa theo hướng tương thích (tăng hạn mức, thêm thao tác cho phép, sửa mô tả); hạ hạn mức hoặc đổi kiểu xác thực phải tạo gói mới và ngừng khuyến nghị gói cũ | 028, 029 |
| BR-02-018 | Gói `DEPRECATED` không nhận đăng ký mới; các đăng ký sẵn có tiếp tục đến hết hạn | 031, 038 |
| BR-02-019 | Chỉ đóng gói khi không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` | 032 |
| BR-02-020 | Chỉ xóa API khi mọi phiên bản `DRAFT` hoặc `RETIRED` và không còn đăng ký đang hiệu lực; xóa là xóa mềm | 040 |
| BR-02-021 | Mã API, mã gói, mã nhóm, số hiệu phiên bản bất biến và không dùng lại, kể cả của đối tượng đã xóa hay ngừng | 008, 010, 014, 024, 027, 032, 033, 040, 042, 061 |
| BR-02-022 | Context-path duy nhất trong tenant, đúng quy ước `/{nhóm}/{mã API}/v{số chính}`, không xung đột tiền tố, bất biến sau khi `PUBLISHED`, giữ chỗ 12 tháng sau khi `RETIRED` | 005, 008, 010, 024, 036 |
| BR-02-023 | Backend chỉ trỏ tới đích trong danh sách cho phép của tenant (kết nối PH-05 hoặc luồng PH-04 cùng tenant), TLS ≥ 1.2, không trỏ tới địa chỉ nội bộ control plane, loopback, link-local hay dịch vụ siêu dữ liệu đám mây (SEC-16) | 013, 022 |
| BR-02-024 | Phiên bản cần ít nhất một backend `ACTIVE` với tổng trọng số lớn hơn 0, và ít nhất một gói trước khi gửi duyệt | 022, 023, 025, 026, 029, 034 |
| BR-02-025 | Phạm vi gọi API `api:{mã API}:{mã gói}` sinh tự động từ đăng ký `ACTIVE`; không có đường cấp tay | 005, 028, 048, 059, 060 |
| BR-02-026 | Duyệt đăng ký: tự duyệt chỉ khi gói bật `autoApprove` và `dataClass` không vượt `02.subscription.auto-approve.max-class`; từ `RESTRICTED` trở lên cần CA hoặc TA quyết định, SV một mình không đủ | 027, 035, 046, 047, 052 |
| BR-02-027 | Mỗi HTTT chỉ có một đăng ký hiệu lực (`PENDING`, `ACTIVE`, `SUSPENDED`) cho một phiên bản API; đổi gói là đăng ký mới rồi hủy cũ | 046 |
| BR-02-028 | Mọi chuyển trạng thái (trừ tạo mới) cần lý do và được ghi kiểm toán với giá trị trước, sau | 010, 021, 023, 029, 030, 032, 034, 035, 037, 038, 039, 040, 045, 051, 052, 062 |
| BR-02-029 | Thông báo bắt buộc (phiên bản phá vỡ, ngừng khuyến nghị, tạm ngừng, tiếp tục, ngừng hẳn, SLA kém đi, hạ mức hiển thị, quyết định đăng ký) gửi mọi bên liên quan và bên nhận không tắt được | 031, 037, 038, 039, 051, 054, 055, 057 |
| BR-02-030 | API sinh từ luồng (`origin = FLOW`): phần hợp đồng sinh từ luồng, không sửa tay; chỉ sửa mô tả, phân loại, gói, SLA; muốn đổi hợp đồng thì sửa luồng ở PH-04 | 013, 014 |
| BR-02-031 | SLA không kết luận khi kỳ có dưới `02.sla.min-days-data` ngày dữ liệu hoặc dưới `02.sla.min-calls` lượt gọi; không đạt từ `02.sla.breach-periods` kỳ liên tiếp thì cảnh báo SV, CA, TA; kỳ chưa đủ dữ liệu không được đếm vào chuỗi và cũng không làm ngắt chuỗi | 055, 056 |
| BR-02-032 | SV chỉ tạo, sửa API của tổ chức mình; đơn vị chủ quản API phải là tổ chức của HTTT cung cấp (trừ khi TA chuyển chủ quản) | 007, 010, 014, 022, 027, 045 |
| BR-02-033 | Đối tượng của tenant khác trả như không tồn tại (`404`, cùng thân), không tiết lộ sự tồn tại (FR-00-011, SEC-87) | 001, 002, 003, 004, 009, 044, 049, 050, 058, 059 |
| BR-02-034 | Tạm ngừng khẩn: SO, TO, TA tạm ngừng ngay có lý do, không cần duyệt, tối đa `02.suspend.max-days` ngày; tiếp tục do người đã tạm ngừng hoặc TA; nếu SO tạm ngừng vì an ninh thì chỉ SO hoặc TA tiếp tục | 037, 051 |
| BR-02-035 | Phiên bản khác số chính chạy song song ở đường dẫn riêng; phiên bản cùng số chính thay thế phiên bản đang chạy, chỉ khi tương thích ngược và mọi gói đang có đăng ký đều có gói cùng mã ở phiên bản mới | 033, 036, 042, 043 |
| BR-02-036 | Di trú: khóa và bí mật của hệ cũ không nhập; đăng ký nhập ở `SUSPENDED` cho tới khi HTTT mới có định danh máy ở PH-01 (FR-00-093) | 061 |
| BR-02-037 | Mức hiển thị theo phân loại: `PUBLIC` chỉ với dữ liệu `PUBLIC`; `NATIONAL` không với `SENSITIVE`; nâng mức lên `NATIONAL`, `PUBLIC` cần CA duyệt | 004, 007, 041, 053 |
| BR-02-038 | Dịch vụ sự kiện (topic) chỉ hiển thị trong danh mục; mọi thao tác đăng ký, duyệt, vòng đời thực hiện ở PH-10 | 009 |
| BR-02-039 | Phiên bản `DRAFT`, `PENDING` chỉ hiển thị cho tổ chức chủ quản, TA, CA, PA; người khác chỉ thấy phiên bản từ `PUBLISHED` trở đi | 001, 002, 003, 006 |
| BR-02-040 | Đơn giá của gói chỉ là thông tin hiển thị; chia sẻ dữ liệu giữa cơ quan nhà nước không thu phí qua PH-02, mọi việc thu phí (nếu có) thuộc PH-19 | 027 |

: Quy tắc nghiệp vụ của PH-02

## 8. Tham số và yêu cầu phi chức năng

Chương này gom các chỉ tiêu đo được của phân hệ (hiệu năng, sẵn sàng, quy mô, an toàn, lưu giữ) và các tham số mà từng tỉnh tự điều chỉnh trong giới hạn nền tảng cho phép.

### 8.1. Yêu cầu phi chức năng

Các NFR dưới đây đo ở hồ sơ "tỉnh vừa" (GĐ-07) trừ khi ghi khác. Cơ sở số liệu: GĐ-04 (200 HTTT, 80 HTTT kết nối năm đầu) và giả định GĐ-02-01 của tập này (mục 12.2): tỉnh vừa có khoảng 180 API công bố, 400 phiên bản, 640 đăng ký sau năm đầu; mức trần thiết kế gấp khoảng 10 lần.

| Mã | Yêu cầu | Chỉ tiêu | Điều kiện đo |
|---|---|---|---|
| NFR-02-001 | Tra cứu danh mục (danh sách, chi tiết, danh mục cho máy) | p95 ≤ 300 ms, p99 ≤ 500 ms; `304` khi chưa đổi | 2.000 API, 200 người dùng đồng thời, đo tại API |
| NFR-02-002 | Tìm kiếm toàn văn | p95 ≤ 500 ms | 2.000 API, 10.000 phiên bản, chỉ mục PostgreSQL |
| NFR-02-003 | Kiểm tra đặc tả (lớp 1, lớp 2, quét bí mật) | ≤ 5 giây với đặc tả 5.000 dòng; ≤ 20 giây với đặc tả 10 MiB | Đo từ lúc gọi tới lúc trả kết quả |
| NFR-02-004 | Sinh báo cáo khác biệt hai phiên bản | ≤ 3 giây | Hai đặc tả 5.000 dòng |
| NFR-02-005 | Hiệu lực cấu hình ở gateway sau lệnh (công bố, tạm ngừng, cấp phạm vi, thu hồi) | p95 ≤ 30 giây từ lúc có quyết định tới lúc gateway áp dụng; độ trễ lan truyền ảnh chụp ≤ 10 giây (D03-09 §6.1) | Ba bản sao APISIX, 300 lượt/giây nền |
| NFR-02-006 | API control plane PH-02 | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms (trừ lệnh bất đồng bộ) | 2.000 API mỗi tenant |
| NFR-02-007 | Sẵn sàng của `dh-connect` phần PH-02 | ≥ 99,5% mỗi tháng (mục tiêu control plane, ADR-013) | Tính theo thăm dò sức khỏe 30 giây |
| NFR-02-008 | Cách ly sự cố với data plane | API đang chạy tiếp tục phục vụ ≥ 24 giờ khi PH-02 ngừng hoàn toàn | Kiểm thử hỗn loạn tắt `dh-connect` (D05-01 CX-01) |
| NFR-02-009 | Khôi phục dữ liệu PH-02 | RPO ≤ 15 phút, RTO ≤ 4 giờ (NFR-00-014) | Diễn tập DR hai site |
| NFR-02-010 | Quy mô mỗi tenant | 2.000 API, 50 phiên bản mỗi API, 20.000 đăng ký, 5.000 thao tác mỗi đặc tả | Hồ sơ tải ở D05-01 |
| NFR-02-011 | Kích thước và độ phức tạp đặc tả | Tối đa 10 MiB; không quá 5.000 thao tác; độ sâu tham chiếu ≤ 50; giới hạn alias YAML để chống bom | Kiểm thử phân tích với đặc tả độc hại |
| NFR-02-012 | Không lọt bí mật và dữ liệu cá nhân thật qua đặc tả | Phát hiện ≥ 95% bộ 50 mẫu chuẩn (khóa PEM, JWT, khóa nền tảng, mật khẩu trong URL, CCCD, số điện thoại); 0 giá trị đánh dấu `DH-CANARY-…` lọt vào log, vết, kết quả kiểm tra, sự kiện | Bộ kiểm thử rò rỉ ở D05-02-PH02 |
| NFR-02-013 | Cách ly tenant | 100% API đọc và ghi đạt ca kiểm thử rò rỉ chéo tenant (`404` cùng thân) | SEC-87, D05-01 |
| NFR-02-014 | Đồng bộ danh mục quốc gia | Gửi trong ≤ 15 phút sau khi API đủ điều kiện (khi PH-14 sẵn sàng); cảnh báo tuân thủ khi quá 7 ngày chưa đồng bộ | Chỉ số `catalog_national_sync_overdue_total` |
| NFR-02-015 | Thông báo thay đổi bắt buộc | Thông báo trong ứng dụng tới 100% bên liên quan ≤ 15 phút; thư điện tử ≤ 1 giờ | Đo từ lúc sự kiện phát ra |
| NFR-02-016 | Khả năng truy cập | Màn UI-02-* đạt WCAG 2.2 AA theo D03-05 | Kiểm thử Playwright và axe |
| NFR-02-017 | Lưu giữ | Đặc tả, phiên bản, đăng ký, lịch sử vòng đời, cam kết SLA: vĩnh viễn; kỳ tuân thủ SLA 3 năm; bản ghi đồng bộ quốc gia 5 năm; thông báo 2 năm; kết quả kiểm tra đặc tả 1 năm; kiểm toán 12 tháng trực tuyến, WORM 5 năm | Chính sách lưu giữ ở D03-03-PH02 |
| NFR-02-018 | Tương thích hợp đồng | API `v1` chỉ thêm trường tùy chọn; sự kiện theo chế độ BACKWARD ở Apicurio | CI-5 |
| NFR-02-019 | Quan sát | Phát chỉ số `catalog_apis_total{status}`, `catalog_spec_validation_total{result,mode}`, `catalog_publish_duration_seconds`, `catalog_national_sync_status`, `catalog_national_sync_overdue_total`, `catalog_sla_compliance_ratio`, `catalog_deprecated_in_use_total`, `catalog_review_pending_age_seconds`, `catalog_gateway_drift_total`; cảnh báo: đồng bộ quá 7 ngày, `DEPRECATED` sắp hết hạn mà còn bên dùng, chờ duyệt quá 5 ngày làm việc | Dashboard và luật cảnh báo ở PH-13 |
| NFR-02-020 | Phát hiện lệch cấu hình gateway | Chu kỳ đối soát 5 phút; phát hiện lệch ≤ 10 phút | Tiêm lệch có chủ đích ở môi trường thử |

: Yêu cầu phi chức năng của PH-02

### 8.2. Tham số theo tenant

Tham số lưu ở PH-18 (khóa `02.*`), có bộ đệm 60 giây ở PH-02. Cột "Miền" là giới hạn tenant tự chỉnh được; trần nền tảng đặt thêm cho một số khóa (ERR-02-040).

| Khóa | Mặc định | Miền | Ý nghĩa |
|---|---|---|---|
| `02.spec.max-size-mib` | 10 | 1…50 | Kích thước tối đa đặc tả |
| `02.spec.url-fetch-timeout-seconds` | 15 | 5…60 | Thời gian chờ tải đặc tả từ URL |
| `02.spec.url-refresh-hours` | 24 | 1…168 | Chu kỳ đồng bộ lại đặc tả từ URL |
| `02.lint.max-per-hour` | 60 | 10…600 | Số lần kiểm tra mỗi người mỗi giờ |
| `02.duplicate.threshold` | 0,8 | 0,5…0,95 | Ngưỡng điểm coi là trùng chức năng |
| `02.submit.require-test-deploy` | `true` | | Bắt buộc thử trên TEST trước khi gửi duyệt |
| `02.review.reminder-days` | 3 | 1…10 | Nhắc người duyệt sau số ngày làm việc |
| `02.review.overdue-days` | 5 | 1…15 | Coi là quá hạn duyệt sau số ngày làm việc |
| `02.deprecation.min-days` | 180 | 30…720 | Hạn chuyển đổi tối thiểu khi ngừng khuyến nghị |
| `02.deprecation.reminders` | `[90,30,7]` | Mỗi giá trị 1…720 | Mốc nhắc trước hạn (ngày) |
| `02.suspend.max-days` | 30 | 1…90 | Thời hạn tạm ngừng tối đa |
| `02.backend.max-timeout-ms` | 60.000 | 1.000…120.000 | Trần thời gian chờ backend |
| `02.backend.max-per-version` | 10 | 1…50 | Số backend tối đa mỗi phiên bản |
| `02.plan.max-per-version` | 10 | 1…30 | Số gói tối đa mỗi phiên bản |
| `02.subscription.auto-approve.max-class` | `INTERNAL` | `PUBLIC`, `INTERNAL` | Mức dữ liệu cao nhất được tự duyệt đăng ký |
| `02.subscription.review-months` | 12 | 0…60 | Chu kỳ rà soát đăng ký; 0 là tắt |
| `02.sla.min-days-data` | 7 | 1…28 | Số ngày dữ liệu tối thiểu để kết luận SLA |
| `02.sla.min-calls` | 1.000 | 100…100.000 | Số lượt gọi tối thiểu để kết luận SLA |
| `02.sla.breach-periods` | 3 | 2…12 | Số kỳ không đạt liên tiếp để cảnh báo |
| `02.sla.worsen-notice-days` | 30 | 7…180 | Báo trước khi cam kết SLA kém đi có hiệu lực |
| `02.sync.enabled` | `true` | | Bật đồng bộ danh mục quốc gia |
| `02.sync.cron` | `0 0 2 * * *` | Biểu thức cron hợp lệ | Lịch đối chiếu hằng ngày (giờ Việt Nam) |
| `02.sync.batch-size` | 50 | 1…200 | Số bản ghi mỗi lượt gửi |
| `02.sync.overdue-days` | 7 | 1…30 | Quá số ngày này chưa đồng bộ thì cảnh báo tuân thủ |
| `02.reconcile.auto-repair` | `false` | | Tự đẩy lại cấu hình khi lệch (trừ route thừa) |
| `02.search.engine` | `POSTGRES` | `POSTGRES`, `OPENSEARCH` | Công cụ tìm kiếm toàn văn |
| `02.default-visibility` | `TENANT` | `TENANT`, `NATIONAL` | Mức hiển thị mặc định khi đăng ký API |
| `02.notice.announcement-max-per-day` | 3 | 1…10 | Số thông báo tay tối đa mỗi API mỗi ngày |

: Tham số theo tenant của PH-02

## 9. Mã lỗi, thông báo, sự kiện và API

Chương này liệt kê mã lỗi, câu thông báo hiển thị cho người dùng, sự kiện phát ra và danh mục API của PH-02; định nghĩa đầy đủ từng mã ở tập API D03-04-PH02.

### 9.1. Mã lỗi

Định nghĩa đầy đủ (thân RFC 9457, trường bổ sung) ở D03-04-PH02 §6. PH-02 là phân hệ mặt phẳng điều khiển nên toàn bộ mã nằm ở dải 001–099; lỗi lúc chạy ở gateway thuộc PH-03.

| Mã | HTTP | Ý nghĩa |
|---|---|---|
| ERR-02-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác |
| ERR-02-002 | 409 | Mã hoặc số hiệu đã tồn tại (kể cả đối tượng đã xóa hoặc ngừng) |
| ERR-02-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường |
| ERR-02-004 | 422 | HTTT hoặc đơn vị không tồn tại hoặc không `ACTIVE` ở PH-01 |
| ERR-02-005 | 422 | Đặc tả không phân tích được hoặc sai cú pháp |
| ERR-02-006 | 422 | Đặc tả không đạt lớp 1 (chuẩn OpenAPI) |
| ERR-02-007 | 422 | Đặc tả còn lỗi nghiêm trọng lớp 2 (quy ước nền tảng) |
| ERR-02-008 | 422 | Đặc tả chứa bí mật hoặc dữ liệu cá nhân thật |
| ERR-02-009 | 413 | Đặc tả hoặc tệp vượt kích thước tối đa |
| ERR-02-010 | 422 | Không tải được đặc tả từ URL (địa chỉ không được phép, không tới được, quá thời gian) |
| ERR-02-011 | 409 | Chuyển trạng thái hoặc thao tác không hợp lệ ở trạng thái hiện tại |
| ERR-02-012 | 409 | Chưa đủ điều kiện để chuyển trạng thái, kèm danh sách điều kiện còn thiếu |
| ERR-02-013 | 403 | Vi phạm nguyên tắc bốn mắt |
| ERR-02-014 | 403 | Không có quyền |
| ERR-02-015 | 412 | Đối tượng đã thay đổi (`If-Match` không khớp) |
| ERR-02-016 | 422 | Dữ liệu thuộc bí mật nhà nước, không được công bố |
| ERR-02-017 | 409 | Có thay đổi phá vỡ tương thích nhưng giữ số phiên bản chính |
| ERR-02-018 | 422 | Số hiệu phiên bản không hợp lệ hoặc không tăng |
| ERR-02-019 | 422 | Context-path trùng, xung đột hoặc sai quy ước |
| ERR-02-020 | 422 | Backend không hợp lệ (đích ngoài danh sách cho phép, TLS thấp, địa chỉ cấm, kết nối hoặc luồng không hợp lệ) |
| ERR-02-021 | 422 | Phiên bản chưa có backend `ACTIVE` hoặc chưa có gói |
| ERR-02-022 | 422 | Kiểu xác thực không phù hợp mức phân loại dữ liệu |
| ERR-02-023 | 422 | Hạn mức hoặc khai báo gói không hợp lý |
| ERR-02-024 | 409 | Gói còn đăng ký đang hiệu lực, không đóng hoặc xóa được |
| ERR-02-025 | 409 | Gói hoặc phiên bản không nhận đăng ký mới |
| ERR-02-026 | 422 | HTTT khai thác không tồn tại, không `ACTIVE` hoặc không thuộc tổ chức của người gửi |
| ERR-02-027 | 409 | HTTT đã có đăng ký hiệu lực cho phiên bản này |
| ERR-02-028 | 422 | HTTT không thuộc đối tượng được dùng gói |
| ERR-02-029 | 422 | Thiếu mục đích, khối lượng dự kiến hoặc căn cứ pháp lý |
| ERR-02-030 | 409 | Còn đăng ký hoặc phiên bản đang phục vụ, không ngừng hẳn hoặc xóa được |
| ERR-02-031 | 422 | Hạn chuyển đổi ngắn hơn tối thiểu |
| ERR-02-032 | 422 | Thiếu phiên bản kế nhiệm khi ngừng khuyến nghị |
| ERR-02-033 | 503 | Cổng API (PH-03) hoặc APISIX không nhận cấu hình trong thời hạn |
| ERR-02-034 | 503 | Dịch vụ phụ thuộc không khả dụng (PH-01, PH-04, PH-10, PH-12, PH-13, PH-14, PH-18, kho đối tượng) |
| ERR-02-035 | 409 | Đang có lần kiểm tra, đồng bộ hoặc đối soát chạy cho cùng đối tượng |
| ERR-02-036 | 429 | Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép |
| ERR-02-037 | 422 | Thao tác hoặc đường dẫn không có trong đặc tả |
| ERR-02-038 | 409 | Phiên bản đang chờ duyệt hoặc đã khóa, không sửa được |
| ERR-02-039 | 423 | Đang đóng băng thay đổi môi trường thật |
| ERR-02-040 | 422 | Vượt trần tham số của tenant |
| ERR-02-041 | 400 | Thiếu lý do bắt buộc |
| ERR-02-042 | 422 | `Idempotency-Key` đã dùng với thân khác |
| ERR-02-043 | 422 | Mức hiển thị không phù hợp mức phân loại dữ liệu |
| ERR-02-044 | 409 | API chưa đủ điều kiện đồng bộ quốc gia |
| ERR-02-045 | 400 | Gói nhập từ APIM cũ sai định dạng |

: Mã lỗi của PH-02

### 9.2. Thông báo hiển thị cho người dùng

Mỗi mã lỗi mà người dùng có thể gặp trên màn hình được chuyển thành một câu tiếng Việt cụ thể, nêu điều gì sai và phải làm gì. Bảng dưới là các câu chính; nguồn chuẩn và vị trí hiển thị ở D03-06-PH02 §5.2. Lỗi không có trong bảng hiển thị theo FR-00-080: câu từ trường `detail`, kèm mã lỗi và nút "Sao chép mã truy vết".

| Mã | Câu hiển thị | Vị trí |
|---|---|---|
| ERR-02-001 | "Không tìm thấy {đối tượng} {mã}. Có thể đã bị xóa hoặc thuộc tỉnh khác." | Trang lỗi hoặc thông báo nổi |
| ERR-02-002 | "Mã {mã} đã được dùng (kể cả đối tượng đã xóa hoặc ngừng). Chọn mã khác." | Dưới trường mã |
| ERR-02-003 | "Có {n} trường chưa hợp lệ." | Hộp cảnh báo đầu biểu mẫu và dưới từng trường |
| ERR-02-004 | "HTTT {mã} chưa được kết nạp hoặc không ở trạng thái hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước." | Dưới trường HTTT |
| ERR-02-005 | "Đặc tả sai cú pháp ở dòng {n}, cột {m}: {mô tả}." | Khung đặc tả ở UI-02-03 |
| ERR-02-006 | "Đặc tả còn {n} lỗi. Sửa các lỗi dưới đây rồi kiểm tra lại." | Dải đầu UI-02-04 |
| ERR-02-007 | "Đặc tả còn {n} lỗi theo quy ước nền tảng. Mở kết quả kiểm tra để xem hướng dẫn sửa." | Dải đầu UI-02-04 |
| ERR-02-008 | "Đặc tả có giá trị giống khóa hoặc dữ liệu cá nhân thật tại {vị trí}. Thay bằng giá trị giữ chỗ rồi kiểm tra lại." | Dòng lỗi ở UI-02-04, con trỏ nhảy tới vị trí |
| ERR-02-009 | "Tệp vượt {n} MiB cho phép. Rút gọn tệp rồi thử lại." | Khung nạp tệp |
| ERR-02-010 | "Không tải được đặc tả từ địa chỉ này (địa chỉ không nằm trong danh sách cho phép hoặc không phản hồi)." | Dưới trường URL |
| ERR-02-011 | "Không thực hiện được ở trạng thái {trạng thái} hiện tại." | Thông báo nổi |
| ERR-02-012 | "Chưa đủ điều kiện: {danh sách}." kèm liên kết tới từng mục còn thiếu | Hộp thoại gửi duyệt |
| ERR-02-013 | "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt." | Hộp duyệt |
| ERR-02-014 | "Bạn không có quyền thực hiện thao tác này." | Thông báo nổi hoặc trang không có quyền |
| ERR-02-015 | "Thông tin vừa được người khác thay đổi. Tải lại để xem." kèm nút "Xem khác biệt" | Hộp cảnh báo xung đột |
| ERR-02-016 | "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub." | Dưới trường khai báo phân loại |
| ERR-02-017 | "Có {n} thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại." kèm liên kết UI-02-05 | Hộp thoại gửi duyệt |
| ERR-02-018 | "Số phiên bản phải dạng MAJOR.MINOR.PATCH và lớn hơn {số hiện có}." | Dưới trường số phiên bản |
| ERR-02-019 | "Đường dẫn {đường dẫn} đã được dùng hoặc xung đột với {đường dẫn khác}." | Dưới trường đường dẫn |
| ERR-02-020 | "Backend không hợp lệ: {lý do}." | Dưới trường backend |
| ERR-02-021 | "Phiên bản cần ít nhất một backend hoạt động và một gói." | Danh sách điều kiện ở hộp thoại gửi duyệt |
| ERR-02-022 | "Dữ liệu mức {mức} yêu cầu xác thực {kiểu tối thiểu}. Chọn kiểu mạnh hơn." | Dưới trường kiểu xác thực |
| ERR-02-023 | "Hạn mức không hợp lý: {mô tả}." | Dưới trường hạn mức |
| ERR-02-024 | "Còn {n} đăng ký đang dùng gói này. Chuyển hoặc thu hồi trước khi đóng." kèm danh sách | Hộp thoại |
| ERR-02-025 | "Gói {mã} không nhận đăng ký mới. Chọn gói khác." | Dưới trường gói ở UI-02-09 |
| ERR-02-026 | "HTTT {mã} chưa được kết nạp hoặc không hoạt động." | Dưới trường HTTT |
| ERR-02-027 | "HTTT đã có đăng ký {trạng thái} cho phiên bản này." | Hộp cảnh báo đầu bước |
| ERR-02-028 | "HTTT của bạn không thuộc nhóm được dùng gói này." | Dưới trường HTTT ở UI-02-09 |
| ERR-02-029 | "Cần nêu mục đích và khối lượng dự kiến." | Dưới trường mục đích ở UI-02-09 |
| ERR-02-030 | "Còn {n} bên đang dùng hoặc phiên bản đang phục vụ. Ngừng dùng có báo trước trước khi ngừng hẳn hoặc xóa." | Hộp thoại |
| ERR-02-031 | "Hạn chuyển đổi tối thiểu {n} ngày. Chọn ngày muộn hơn {ngày}." | Dưới trường hạn |
| ERR-02-032 | "Chưa có phiên bản kế nhiệm. Chọn phiên bản kế nhiệm hoặc xác nhận ngừng hẳn dịch vụ." | Dưới trường kế nhiệm |
| ERR-02-033 | "Cổng API chưa nhận cấu hình, hệ thống đang thử lại. Phiên bản giữ nguyên trạng thái hiện tại." | Dải đầu trang chi tiết |
| ERR-02-034 | "Dịch vụ phụ thuộc chưa phản hồi, hệ thống đang thử lại. Thử lại sau ít phút." | Dải cảnh báo |
| ERR-02-035 | "Đang có lần {kiểm tra, đồng bộ, đối soát} chạy cho đối tượng này." kèm liên kết mở lần đó | Thông báo nổi |
| ERR-02-036 | "Đã thực hiện quá số lần cho phép. Thử lại sau {n} phút." | Thông báo nổi, nút đếm ngược |
| ERR-02-037 | "Thao tác {operationId} không có trong đặc tả." | Dưới trường thao tác ở UI-02-07 |
| ERR-02-038 | "Phiên bản đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước." | Thông báo nổi |
| ERR-02-039 | "Đang trong khoảng đóng băng thay đổi môi trường thật tới {thời điểm}." | Dải thông báo đầu trang |
| ERR-02-040 | "Vượt trần {n} {đối tượng} ({tham số})." | Hộp cảnh báo |
| ERR-02-041 | "Nhập lý do (bắt buộc)." | Dưới ô lý do |
| ERR-02-042 | "Yêu cầu này đã được gửi với nội dung khác. Tải lại trang rồi thử lại." | Thông báo nổi |
| ERR-02-043 | "Mức hiển thị {mức} không phù hợp với dữ liệu mức {phân loại}." | Dưới trường mức hiển thị |
| ERR-02-044 | "API {mã} chưa đủ điều kiện đồng bộ quốc gia (chưa công bố hoặc mức hiển thị là nội bộ)." | Thông báo nổi |
| ERR-02-045 | "Gói xuất từ APIM cũ sai định dạng. Dùng tệp xuất do hệ cũ sinh ra." | UI-02-16, bước 1 |

: Thông báo hiển thị theo mã lỗi

### 9.3. Sự kiện

Tên topic theo quy ước D00-04 §4: `{tenant}.catalog.{thực-thể}.{sự-kiện}.v1`, chữ thường. Sự kiện phát qua outbox cùng giao dịch ghi (ADR-042); lược đồ đăng ký ở Apicurio, chế độ BACKWARD (NFR-02-018).

| Mã | Topic | Khi nào | Bên tiêu thụ |
|---|---|---|---|
| EVT-02-01 | `{tenant}.catalog.api.registered.v1` | API được đăng ký (FR-02-010, 013, 061) | PH-13, PH-15 |
| EVT-02-02 | `{tenant}.catalog.api.updated.v1` | Đổi thông tin, phân loại, mức hiển thị, chủ quản, backend, SLA (kèm `changedFields`) | PH-03, PH-15, PH-13 |
| EVT-02-03 | `{tenant}.catalog.api.deleted.v1` | API bị xóa mềm | PH-15, PH-13, PH-14 |
| EVT-02-04 | `{tenant}.catalog.version.submitted.v1` | Phiên bản gửi duyệt | PH-18 (việc của tôi), PH-13 |
| EVT-02-05 | `{tenant}.catalog.version.published.v1` | Phiên bản sang `PUBLISHED` | PH-03, PH-15, PH-13, PH-16 |
| EVT-02-06 | `{tenant}.catalog.version.state-changed.v1` | Tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn | PH-03, PH-15, PH-13, PH-18 |
| EVT-02-07 | `{tenant}.catalog.version.spec-source-changed.v1` | Đặc tả nguồn URL thay đổi | PH-18 (nhắc chủ dịch vụ) |
| EVT-02-08 | `{tenant}.catalog.plan.state-changed.v1` | Gói đổi trạng thái hoặc khai báo | PH-03, PH-15 |
| EVT-02-09 | `{tenant}.catalog.subscription.requested.v1` | Đăng ký chờ duyệt | PH-18 (việc của tôi) |
| EVT-02-10 | `{tenant}.catalog.subscription.activated.v1` | Đăng ký được cấp phạm vi | PH-03, PH-13, PH-15 |
| EVT-02-11 | `{tenant}.catalog.subscription.state-changed.v1` | Từ chối, tạm ngừng, thu hồi, hủy, hết hạn | PH-03, PH-12, PH-13 |
| EVT-02-12 | `{tenant}.catalog.change.notice-issued.v1` | Thông báo thay đổi đã phát | PH-15, PH-18 |
| EVT-02-13 | `{tenant}.catalog.sla.period-closed.v1` | Chốt kỳ tuân thủ SLA | PH-13, PH-16 |
| EVT-02-14 | `{tenant}.catalog.national-sync.state-changed.v1` | Trạng thái đồng bộ quốc gia đổi | PH-13 |
| EVT-02-15 | `{tenant}.catalog.gateway.drift-detected.v1` | Phát hiện cấu hình gateway lệch | PH-13, PH-18 |
| EVT-02-16 | `{tenant}.catalog.review.overdue.v1` | Yêu cầu duyệt quá hạn | PH-18 |

: Sự kiện của PH-02

PH-02 tiêu thụ sự kiện của phân hệ khác: EVT-04-02, EVT-04-04, EVT-04-07 của PH-04 (FR-02-013); EVT-10-01, 03, 04 của PH-10 (FR-02-009); sự kiện tạm ngừng, thu hồi HTTT của PH-01 (FR-02-051; mã theo D03-04-PH01).

### 9.4. Danh mục API

Định nghĩa đầy đủ và ví dụ ở D03-04-PH02 (sinh từ OpenAPI có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`). Mọi API quản trị dùng tiền tố `/api/catalog/v1`; API nội bộ dưới `/api/catalog/v1/internal`. Bảng gom theo nhóm; tổng cộng 98 operation (API-02-001…098; bảy mã 092…098 bổ sung ở D03-04-PH02 §3.4).

| Nhóm | Mã | FR |
|---|---|---|
| Danh mục, tìm kiếm, đặc tả đã công bố | API-02-001…007, 090, 091 | 001…006 |
| Phân loại, thẻ, dịch vụ sự kiện | API-02-008…013 | 007…009 |
| Đăng ký API, nạp và đồng bộ đặc tả | API-02-014…019 | 010…015 |
| Kiểm tra đặc tả, bộ luật | API-02-020…025, 092…094 | 016…021 |
| Backend, đường dẫn, khung route | API-02-026…032 | 022…026 |
| Gói sử dụng | API-02-033…041, 096 | 027…033 |
| Vòng đời, duyệt, phiên bản | API-02-042…057, 098 | 034…045 |
| Đăng ký sử dụng | API-02-058…068 | 046…052 |
| Đồng bộ quốc gia | API-02-069…072 | 053, 054 |
| SLA, thông báo, thống kê | API-02-073…079, 097 | 055…058 |
| Nội bộ cho PH-03, PH-04, PH-15 | API-02-080…082 | 059 |
| Đối soát cấu hình | API-02-083, 084 | 060 |
| Di trú từ APIM cũ | API-02-085…087 | 061 |
| Tham số | API-02-088, 089 | 062 |
| Tác vụ bất đồng bộ | API-02-095 | 012, 026, 053, 060 |

: Danh mục API của PH-02

## 10. Giao diện

Chương này liệt kê 17 màn hình của PH-02 và giới thiệu hai màn tiêu biểu bằng ảnh hi-fi; bố cục chi tiết từng màn nằm ở tập màn hình D03-06-PH02.

### 10.1. Danh sách màn hình

PH-02 có 17 màn hình chia năm nhóm: danh mục và chi tiết API (UI-02-01, 02, 14), đăng ký và kiểm tra đặc tả (03, 04, 05, 15), gói sử dụng (06, 07), đăng ký sử dụng và duyệt (08, 09, 10), vận hành và tuân thủ (11, 12, 13) và quản trị (16, 17). Bố cục, thành phần, trạng thái của từng màn đặc tả ở D03-06-PH02; mẫu màn theo D03-06-00 §4 (`PTN-*`).

| Mã | Tên | Vai trò chính | Hành vi chính | FR |
|---|---|---|---|---|
| UI-02-01 | Danh mục API (`/ket-noi/api`, PTN-01) | Mọi vai trò xem; SV, TA | Tìm, lọc theo nhóm, phân loại, trạng thái, hiển thị; thẻ tổng "Cần chú ý"; đăng ký API; nhập từ APIM cũ; xuất | 001, 003, 004, 009, 025, 056 |
| UI-02-02 | Chi tiết API (`/ket-noi/api/{ma-api}`, PTN-02) | SV, CA, TA, TO, SO | Tab Tổng quan, Phiên bản, Backend, Gói sử dụng, Đăng ký, Thống kê, SLA, Lịch sử; cách gọi, tải đặc tả; gửi duyệt, tạm ngừng, xóa, chuyển chủ quản | 002, 005…007, 012…014, 022…026, 034, 036, 037, 040…042, 045, 049, 051, 055, 056, 058 |
| UI-02-03 | Đăng ký API từ OpenAPI (`/ket-noi/api/moi`, PTN-05) | SV, TA | Năm bước: thông tin, đặc tả (tệp, dán, URL), kiểm tra và xem trước, backend và gói, rà soát | 007, 010, 011, 014, 015, 019, 020, 022, 024, 027, 034, 055 |
| UI-02-04 | Kết quả kiểm tra đặc tả (PTN-02) | SV, TA, SO, CA | Thẻ tổng lỗi, cảnh báo; danh sách theo mức; khung đặc tả tô sáng dòng lỗi; nhảy tới lỗi; kiểm tra lại; chấp nhận cảnh báo | 016…020 |
| UI-02-05 | So sánh phiên bản và tác động (PTN-02, `CMP-DiffViewer`) | SV, CA, TA | Chọn hai phiên bản; danh sách thay đổi phá vỡ, tương thích, cần xác nhận; bên bị ảnh hưởng; tạo lộ trình ngừng dùng | 043, 044 |
| UI-02-06 | Danh sách gói sử dụng (`/ket-noi/goi-su-dung`, PTN-01) | SV, CA, TA | Tìm, lọc theo API, trạng thái, kiểu xác thực; công bố, ngừng khuyến nghị, đóng, sao chép gói | 027, 030…033 |
| UI-02-07 | Tạo, sửa gói sử dụng (PTN-03) | SV, TA | Thông tin, đối tượng được xin, kiểu xác thực, hạn mức và đường dẫn cho phép | 027…029 |
| UI-02-08 | Danh sách đăng ký sử dụng (`/ket-noi/dang-ky`, PTN-01) | OR, SV, CA, TA, TO | Xem theo HTTT hoặc API; trạng thái cấp quyền; tạm ngừng, tiếp tục, thu hồi, hủy, gia hạn; xuất | 048, 050…052 |
| UI-02-09 | Gửi đăng ký sử dụng (PTN-04) | OR, TA | Chọn API, gói, HTTT; nêu mục đích, khối lượng, căn cứ; xác nhận điều khoản | 046 |
| UI-02-10 | Duyệt công bố, gói, đăng ký (trong "Việc của tôi", PTN-10) | CA, TA, SV, SO | Mở hồ sơ, xem kết quả kiểm tra, API gần giống; duyệt hoặc trả lại kèm ý kiến | 020, 030, 031, 035, 036, 038, 039, 041, 044, 047 |
| UI-02-11 | Tuân thủ SLA và thống kê (`/ket-noi/tuan-thu-sla`, PTN-06) | SV, CA, TA, VW | Bảng cam kết với thực tế, biểu đồ theo kỳ, cảnh báo nhiều kỳ không đạt; lượt gọi, bên khai thác | 055, 056, 058 |
| UI-02-12 | Đồng bộ danh mục quốc gia (`/ket-noi/dong-bo-quoc-gia`, PTN-11) | TA, TO | Thẻ tổng, danh sách bản ghi, quá hạn; thử lại, gửi lại; xem lý do từ chối | 053, 054 |
| UI-02-13 | Lộ trình ngừng dùng và thông báo (PTN-04) | SV, CA, TA | Chọn kế nhiệm, hạn, hướng dẫn chuyển; bên bị ảnh hưởng; trạng thái thông báo từng bên; gửi thông báo tay | 038, 039, 044, 057 |
| UI-02-14 | Phân loại và thẻ (`/ket-noi/quan-tri/phan-loai`, PTN-08, cây và bảng) | TA, PA | Cây nhóm, thêm, đổi tên, gộp; API trong nhóm | 007, 008 |
| UI-02-15 | Bộ luật kiểm tra quy ước (`/ket-noi/quan-tri/bo-luat`, PTN-12) | TA, PA | Danh sách luật, mức hiệu lực, số API vi phạm; đổi mức; mẫu quét bí mật chỉ đọc | 021 |
| UI-02-16 | Nhập từ APIM cũ (`/ket-noi/quan-tri/nhap-apim-cu`, PTN-09, nhập có xem trước) | TA, PA | Tải gói xuất, xem trước ánh xạ, sửa, xác nhận, tải báo cáo đối chiếu | 061 |
| UI-02-17 | Cài đặt phân hệ và đối soát (`/ket-noi/quan-tri/cai-dat`, PTN-12) | TA, PA, TO | Tham số `02.*`; đối soát cấu hình gateway, đẩy lại | 060, 062 |

: Danh sách màn hình của PH-02

### 10.2. Giao diện tiêu biểu

Phần dưới giới thiệu hai màn hình tiêu biểu: màn đầu vào của mọi việc (danh mục API) và màn có giá trị nhất khi nâng phiên bản (so sánh và tác động). Hình dựng bằng bộ token Liquid Glass đề xuất của D03-05, dữ liệu minh họa của tenant `T68`.

Màn danh mục API (UI-02-01) là nơi cán bộ bắt đầu. Năm thẻ tổng ở đầu trang vừa là số liệu vừa là bộ lọc nhanh; thẻ "Cần chú ý" gom API có SLA không đạt, đồng bộ quốc gia lỗi hoặc gateway lệch. Mỗi dòng cho biết chủ quản, mức phân loại (nhãn màu), mức hiển thị, phiên bản kèm trạng thái, số bên đăng ký và chỉ báo SLA kỳ gần nhất. Dòng đầu là API `ho-so-dat-dai` đang có phiên bản cũ sắp ngừng và đã không đạt SLA ba kỳ liên tiếp nên xếp đầu danh sách (cờ cảnh báo), đúng quy tắc BR-02-031.

![UI-02-01 Danh mục API](../../03-thiet-ke/uiux/ph02/hifi/ui-02-01.png)

Màn so sánh phiên bản (UI-02-05) mở khi chủ dịch vụ chuẩn bị gửi duyệt phiên bản mới. Dải vàng nói thẳng kết luận: có ba thay đổi phá vỡ, số chính đã tăng đúng, nên chạy song song ít nhất 180 ngày và có năm HTTT đang gọi các thao tác bị ảnh hưởng. Bảng bên trái liệt kê từng thay đổi theo màu (đỏ phá vỡ, vàng cần xác nhận, xanh tương thích) kèm tác động; bảng bên phải cho biết bên nào bị ảnh hưởng, gọi bao nhiêu lượt, bao nhiêu thao tác bị đụng. Nút "Tạo lộ trình ngừng dùng" chuyển sang UI-02-13 với phiên bản kế nhiệm và hạn tối thiểu điền sẵn (FR-02-038).

![UI-02-05 So sánh phiên bản và tác động tới bên khai thác](../../03-thiet-ke/uiux/ph02/hifi/ui-02-05.png)

## 11. Truy vết

Chương này chứng minh PH-02 phủ trọn nghiệp vụ hệ cũ: mỗi chức năng cũ của phân hệ có một kết luận và nơi hiện thực ở hệ mới, mỗi mã của SRS cũ có mã mới tương ứng, và mỗi FR đi về một yêu cầu nghiệp vụ REQ.

### 11.1. Chức năng hệ cũ → FR

Mỗi mục `LGC` của PH-02 trong D00-03 phần A có đúng một kết luận. Cột "FR" liệt kê các FR hiện thực, FR đầu tiên là FR chính.

| Mã | Chức năng hệ cũ | FR | Kết luận |
|---|---|---|---|
| LGC-APIM-001 | Hiển thị danh sách API | 001, 002, 003, 004 (lọc, tìm, danh mục cho máy) | Giữ nguyên |
| LGC-APIM-002 | Tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend | 010, 014, 022, 024 (đặc tả OpenAPI bắt buộc, context-path theo quy ước) | Nâng cấp |
| LGC-APIM-003 | Tạo API bằng cách nạp Swagger | 011, 012, 016, 017, 018, 019 (nạp OpenAPI 3.x và Swagger 2.0, kiểm tra hợp lệ) | Nâng cấp |
| LGC-APIM-004 | Tạo API chưa triển khai, hoặc tạo và triển khai ngay | 010, 034, 035, 036 ("Lưu nháp", "Lưu và gửi duyệt", thử TEST; vòng đời có bước duyệt) | Nâng cấp |
| LGC-APIM-005 | Start / Stop API | 037 (lệnh trạng thái, lý do, thời hạn); PH-03 thực thi tại gateway | Giữ nguyên |
| LGC-APIM-006 | Publish / Unpublish API lên portal | 041, 036; PH-15 hiển thị (kèm mức hiển thị thay Make Public, `LGC-APIM-007` thuộc PH-15) | Giữ nguyên |
| LGC-APIM-008 | Xóa API | 040, 038, 039 (xóa chỉ khi không còn đăng ký; có ngừng dùng báo trước) | Nâng cấp |
| LGC-APIM-009 | Plan với bốn trạng thái Staging, Published, Deprecated, Closed | 027, 030, 031, 032, 033 | Giữ nguyên |
| LGC-APIM-010 | Plan bước Define: metadata, nhóm được phép truy cập | 027 (đối tượng được xin thành điều kiện đăng ký của gói) | Giữ nguyên |
| LGC-APIM-011 | Plan bước Secure: Keyless hoặc API key | 028, 029 (thêm OAuth 2.1 `client_credentials` với `private_key_jwt`, mTLS; Keyless chỉ cho dữ liệu công khai); PH-03 thực thi | Nâng cấp |
| LGC-APIM-016 | Quản lý subscription theo API | 049, 046, 047, 051 | Giữ nguyên |
| LGC-APIM-017 | Xem chi tiết đường dẫn sử dụng API (gateway URL + context path) | 005, 002, 024 | Giữ nguyên |
| LGC-APIM-018 | Quản lý endpoint backend của API | 022, 023, 025 (nhiều backend, cân bằng tải, kiểm tra sức khỏe) | Giữ nguyên |
| LGC-APIM-021 | Quản lý subscription theo Application | 050, 046, 051, 052 (Application thành HTTT thành viên có hồ sơ kết nạp) | Giữ nguyên |
| LGC-BUS-028 | Thông tin REST API của agent: URI và trạng thái | 013, 002 (API sinh từ luồng PH-04 được quản lý trong danh mục) | Thay thế |

: Truy vết từ chức năng hệ cũ đến FR

Các mục `LGC` thuộc phân hệ khác làm chính nhưng PH-02 phối hợp và đã ghi trong cột truy vết của FR tương ứng: `LGC-APIM-007` (PH-15, FR-02-041), `LGC-APIM-012`, `013`, `014` (PH-03 thực thi, FR-02-029 khai báo), `LGC-APIM-015` (PH-03, FR-02-029 tham chiếu bộ chính sách), `LGC-APIM-019`, `020` (PH-01, PH-12). Kết luận chính của các mục này giữ ở tập của phân hệ làm chính. Đối chiếu với D00-03 phần A: mọi hàng có `PH-02` trong cột PH đích (15 hàng) đều có mặt ở bảng trên, không thiếu hàng nào.

### 11.2. Mã cũ trong `docs/07-srs` → mã mới

Bảng ánh xạ phục vụ người đã quen SRS cũ (`docs/07-srs/SRS-PH-02-api-catalog.md`, bản 1.0 ngày 03/8/2026) và phục vụ đối soát khi di trú tài liệu. Mọi FR cũ đều có chỗ trong FR mới; không FR cũ nào bị bỏ.

| FR cũ | Nội dung cũ | FR mới | Ghi chú khác biệt |
|---|---|---|---|
| FR-02-001 | Đăng ký dịch vụ mới | 010, 011, 014 | Tách trình hướng dẫn, nạp đặc tả, sửa nháp; thêm đăng ký từ luồng (013), từ APIM cũ (061) |
| FR-02-002 | Kiểm tra đặc tả OpenAPI (hai lớp) | 016, 017, 018, 019, 021 | Tách thành lớp 1, lớp 2, quét bí mật, kiểm tra không lưu; bộ luật đánh số `LINT-02-nn` |
| FR-02-003 | Nhập đặc tả từ tệp hoặc URL | 011, 012 | Thêm chuyển Swagger 2.0, kiểm tra URL theo egress, đồng bộ lại theo lịch |
| FR-02-004 | Chuyển trạng thái dịch vụ | 034, 036, 037, 038, 039 | Vòng đời đặt ở **phiên bản**; bỏ trạng thái `TESTING` thành thử trên TEST (FR-02-036); thêm `SUSPENDED` thành lệnh Stop |
| FR-02-005 | Phê duyệt phát hành | 035, 036, 020 | Bốn mắt nâng thành ba người khác nhau; dữ liệu Nhạy cảm cần người thứ hai; trùng chức năng thành FR riêng |
| FR-02-006 | Quản lý phiên bản API | 042, 043, 044 | Tách tạo phiên bản, so sánh, phân tích tác động; thêm quy tắc thay thế cùng số chính |
| FR-02-007 | Ngừng dùng dịch vụ | 038, 039, 044, 057 | Thêm duyệt, thông báo bắt buộc, lịch nhắc, hủy bản nháp |
| FR-02-008 | Duy trì danh mục dịch vụ | 001, 002, 003, 004, 005, 006, 007, 008 | Thêm mức hiển thị, danh mục cho máy với `ETag`, bộ phân loại |
| FR-02-009 | Đăng ký danh mục lên hệ thống của Bộ | 053, 054 | Đích là Nền tảng chia sẻ, điều phối dữ liệu quốc gia qua PH-14 (NĐ 278/2025 thay NĐ 47/2020) |
| FR-02-010 | Sinh khung route cho PH-04 | 026 | Gọi FR-04-003 nguồn `API_SPEC`; thêm backend `FLOW` |
| FR-02-011 | Đăng ký sử dụng dịch vụ | 046, 047, 048, 051, 052 | Thêm duyệt, cấp phạm vi tự động, thu hồi, rà soát định kỳ |
| FR-02-012 | Quản lý cam kết chất lượng dịch vụ | 055, 056 | Tách khai báo và đối chiếu; cam kết kém đi báo trước 30 ngày |
| FR-02-013 | Thông báo thay đổi dịch vụ | 057 | Danh sách 11 loại thông báo, thông báo tay, theo dõi theo bên nhận |
| FR-02-014 | Thống kê sử dụng dịch vụ | 058 | Thêm phát hiện API không dùng, chỉ tiêu cho PH-16 |

: Ánh xạ FR cũ sang FR mới

Các FR mới không có FR cũ tương ứng (năng lực mới hoặc ghi nhận từ kiểm kê hệ cũ): 009 (dịch vụ sự kiện), 013 (đăng ký từ luồng, LGC-BUS-028), 015 (mẫu và quy ước), 022…025 (backend, từ LGC-APIM-018), 027…033 (gói sử dụng, từ LGC-APIM-009…011), 040 (xóa API, LGC-APIM-008), 041 (mức hiển thị, LGC-APIM-006), 045 (chuyển chủ quản), 049, 050 (đăng ký theo API, theo HTTT, LGC-APIM-016; 021), 059, 060 (giao diện nội bộ, đối soát), 061 (di trú), 062 (tham số).

Các mã khác của SRS cũ được ánh xạ như sau.

| Mã cũ | Mã mới | Ghi chú |
|---|---|---|
| BR-02-001…015 | BR-02-001…015 | Giữ số và ý; BR-02-008 mở rộng (ba người khác nhau, dữ liệu Nhạy cảm thêm TA); BR-02-016…040 là quy tắc mới |
| NFR-02-001 (tra cứu p99 ≤ 500 ms, 1.000 dịch vụ) | NFR-02-001 | Siết p95 ≤ 300 ms, quy mô 2.000 API |
| NFR-02-002 (kiểm tra ≤ 5 giây) | NFR-02-003 | Thêm ngưỡng 10 MiB |
| NFR-02-003 (khác biệt ≤ 3 giây) | NFR-02-004 | Giữ |
| NFR-02-004 (đẩy cấu hình ≤ 30 giây) | NFR-02-005 | Mở rộng cho tạm ngừng, cấp phạm vi, thu hồi |
| NFR-02-005 (`ETag`, đệm) | NFR-02-001, FR-02-004 | Hiện thực ở FR-02-004 |
| NFR-02-006 (sẵn sàng đọc 99,9%) | NFR-02-007 | Đổi thành 99,5% theo mục tiêu control plane ADR-013; danh mục vẫn đọc được qua bản đệm của PH-15 khi PH-02 ngừng |
| NFR-02-007 (quản trị 99,5%) | NFR-02-007 | Gộp |
| NFR-02-008 (sự cố không ảnh hưởng API đang chạy) | NFR-02-008 | Chỉ tiêu 24 giờ theo NFR-00-012 |
| NFR-02-009 (hai bản sao) | NFR-02-007 | Số bản sao nêu ở D03-09 §5 (hai, ba, bốn theo hồ sơ), không nhắc lại ở FRS |
| NFR-02-010 (RPO ≤ 1 giờ, RTO ≤ 4 giờ) | NFR-02-009 | Siết RPO ≤ 15 phút theo NFR-00-014 |
| NFR-02-011…014 (quy mô, kích thước) | NFR-02-010, 011 | Nâng 1.000 thành 2.000 API, 10.000 thành 20.000 đăng ký |
| NFR-02-015, 016 (chỉ chủ quản sửa, vai trò duyệt riêng) | BR-02-032, BR-02-008; `PERM-02-*` | Chuyển thành quy tắc nghiệp vụ và ma trận quyền |
| NFR-02-017 (không bí mật trong đặc tả) | NFR-02-012, FR-02-018 | Đo được bằng bộ mẫu chuẩn |
| NFR-02-018 (kiểm toán vòng đời) | FR-00-040, BR-02-028 | Dùng chung FR-00 |
| NFR-02-019 (chỉ số) | NFR-02-019 | Đổi tên theo quy ước, thêm chỉ số |
| NFR-02-020 (cảnh báo đồng bộ quá 7 ngày) | NFR-02-014, FR-02-054 | Tham số `02.sync.overdue-days` |
| NFR-02-021 (cảnh báo `DEPRECATED` sắp hết hạn) | FR-02-038, FR-02-039 | Nhắc theo lịch 90, 30, 7 ngày |
| NFR-02-022 (cảnh báo chờ duyệt quá 5 ngày) | FR-02-035, EVT-02-16 | Tham số `02.review.overdue-days` |
| UI-02-01…05, 07, 08 | UI-02-01, 02, 03, 04, 05, 11, 12 | UI-02-06 cũ (hàng đợi phê duyệt) thành UI-02-10 trong "Việc của tôi" |
| EN-02-01…06 (DICH_VU, PHIEN_BAN, DAC_TA, KET_QUA_KIEM_TRA, SLA, DANG_KY) | EN-02-01, 02, 03, 04, 08, 07 | `DONG_BO_BO` thành EN-02-10, `THONG_BAO` thành EN-02-11, `KHUNG_ROUTE` thành backend `FLOW` (EN-02-05) |
| API `/api/v1/catalog`, `/api/v1/services`, `/api/admin/v1/services` | `/api/catalog/v1` | Gộp một tiền tố; mã `API-02-001…098` |
| CMP-02, 03, 05, 23, 34 (mã của repo) | CMP-LAW-03, 19; BR-02-007; FR-02-056 | NĐ 47/2020 thay bằng NĐ 278/2025 (CMP-LAW-03); mã `CMP-xx` của repo không dùng nữa |
| AT-02-001…032 (kịch bản chấp nhận) | TC ở D05-02-PH02 | Bảng ánh xạ AT → FR ở dưới |

: Ánh xạ mã cũ khác sang mã mới

Lưu ý khi đọc bảng trên: số ở cột đầu là mã của SRS cũ nên trùng số với mã mới nhưng khác nghĩa; ví dụ `NFR-02-020` cũ là cảnh báo đồng bộ quá hạn, còn `NFR-02-020` mới là phát hiện lệch cấu hình gateway. Bộ yêu cầu phi chức năng mới chỉ gồm NFR-02-001…020 ở mục 8.2; `NFR-02-021`, `NFR-02-022` chỉ tồn tại ở SRS cũ.

| AT cũ | FR hoặc NFR mới | AT cũ | FR hoặc NFR mới |
|---|---|---|---|
| AT-02-001 | FR-02-010 | AT-02-017 | FR-02-026 |
| AT-02-002 | FR-02-016, FR-02-011 | AT-02-018 | FR-02-053 |
| AT-02-003 | FR-02-016 | AT-02-019 | FR-02-054 |
| AT-02-004 | FR-02-017 | AT-02-020 | FR-02-048, FR-02-046 |
| AT-02-005 | FR-02-017 | AT-02-021 | FR-02-046 |
| AT-02-006 | FR-02-018 | AT-02-022 | FR-02-056 |
| AT-02-007 | FR-02-007, FR-02-010 | AT-02-023 | FR-02-056 |
| AT-02-008 | FR-02-035 | AT-02-024 | FR-02-020 |
| AT-02-009 | FR-02-043 | AT-02-025 | FR-02-006 |
| AT-02-010 | FR-02-043 | AT-02-026 | NFR-02-008 |
| AT-02-011 | FR-02-042, FR-02-043 | AT-02-027 | NFR-02-001 |
| AT-02-012 | FR-02-044 | AT-02-028 | NFR-02-003 |
| AT-02-013 | FR-02-038 | AT-02-029 | FR-02-004 |
| AT-02-014 | FR-02-038, FR-02-057 | AT-02-030 | BR-02-032, FR-02-014 |
| AT-02-015 | FR-02-039 | AT-02-031 | FR-00-040, BR-02-028 |
| AT-02-016 | FR-02-036, NFR-02-005 | AT-02-032 | NFR-02-009 |

: Ánh xạ kịch bản chấp nhận cũ sang FR mới

### 11.3. FR → REQ

Mọi FR của PH-02 truy vết về REQ-02 (D02-01 §4). Cột "REQ liên quan" là các REQ khác mà FR đóng góp thêm.

| FR | REQ chính | REQ liên quan |
|---|---|---|
| 001…008, 010…012, 014…021 | REQ-02 | — |
| 009 | REQ-02 | REQ-10 |
| 013, 026 | REQ-02 | REQ-04 |
| 022, 023, 024, 027…033 | REQ-02 | REQ-03 |
| 025 | REQ-02 | REQ-13 |
| 034…036, 040, 042…045 | REQ-02 | — |
| 037…039 | REQ-02 | REQ-03, REQ-13 |
| 041 | REQ-02 | REQ-15 |
| 046, 047, 049, 050, 052 | REQ-02 | REQ-09, REQ-12 |
| 048, 051 | REQ-02 | REQ-03, REQ-12 |
| 053, 054 | REQ-02 | REQ-14 |
| 055…058 | REQ-02 | REQ-13, REQ-16 |
| 059 | REQ-02 | REQ-03, REQ-15 |
| 060 | REQ-02 | REQ-03, REQ-13 |
| 061 | REQ-02 | REQ-22 |
| 062 | REQ-02 | REQ-18 |

: Truy vết FR đến REQ

### 11.4. FR → use case

Bảng dưới là chiều ngược của bảng 5.1 ở tập use case D02-04-PH02: mỗi FR được hiện thực bởi những use case nào. Chiều sang test case ở D05-02-PH02 §8.1, chiều sang màn hình và API ở mục "Màn hình, API" của từng FR và ở mục 9.4, 10.1.

| FR | Tên | Use case (UC-02-) |
|---|---|---|
| FR-02-001 | Liệt kê API trong danh mục, lọc, sắp xếp | 01 |
| FR-02-002 | Xem chi tiết API | 01 |
| FR-02-003 | Tìm kiếm toàn văn danh mục | 01 |
| FR-02-004 | Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển theo mức hiển thị | 02 |
| FR-02-005 | Xem đường dẫn sử dụng và mẫu gọi API | 01 |
| FR-02-006 | Tải đặc tả OpenAPI đã công bố | 01 |
| FR-02-007 | Phân loại và gắn thẻ API | 03 |
| FR-02-008 | Quản lý bộ phân loại và thẻ | 03 |
| FR-02-009 | Hiển thị dịch vụ sự kiện (topic) trong danh mục | 04 |
| FR-02-010 | Đăng ký API mới bằng trình hướng dẫn | 05 |
| FR-02-011 | Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL | 05 |
| FR-02-012 | Đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi | 08 |
| FR-02-013 | Tự đăng ký API từ luồng REST của PH-04 | 09 |
| FR-02-014 | Sửa thông tin API và đặc tả khi còn bản nháp | 05 |
| FR-02-015 | Cung cấp mẫu đặc tả và quy ước viết API | 05 |
| FR-02-016 | Kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1 | 06 |
| FR-02-017 | Kiểm tra đặc tả lớp 2: quy ước nền tảng | 06 |
| FR-02-018 | Quét bí mật và dữ liệu cá nhân thật trong đặc tả | 07 |
| FR-02-019 | Kiểm tra đặc tả không lưu (xem trước khi gõ) | 06 |
| FR-02-020 | Phát hiện API trùng chức năng | 07 |
| FR-02-021 | Quản lý bộ luật kiểm tra quy ước | 38 |
| FR-02-022 | Khai báo backend của API | 11 |
| FR-02-023 | Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe backend | 11 |
| FR-02-024 | Quản lý context-path và kiểm tra trùng | 05 |
| FR-02-025 | Xem sức khỏe backend | 11 |
| FR-02-026 | Sinh khung route cho PH-04 từ đặc tả | 10 |
| FR-02-027 | Tạo gói sử dụng: thông tin và điều kiện truy cập | 12 |
| FR-02-028 | Chọn kiểu xác thực của gói | 12 |
| FR-02-029 | Khai báo hạn mức và đường dẫn cho phép của gói | 12 |
| FR-02-030 | Công bố gói (`STAGING` sang `PUBLISHED`) | 13 |
| FR-02-031 | Ngừng khuyến nghị gói | 14 |
| FR-02-032 | Đóng gói | 14 |
| FR-02-033 | Sao chép gói sang phiên bản mới | 14 |
| FR-02-034 | Gửi duyệt công bố API | 15 |
| FR-02-035 | Duyệt hoặc từ chối công bố (bốn mắt) | 16 |
| FR-02-036 | Công bố API ra gateway và danh mục | 15, 16 |
| FR-02-037 | Tạm ngừng và tiếp tục API | 17 |
| FR-02-038 | Ngừng khuyến nghị API có lộ trình | 19 |
| FR-02-039 | Ngừng hẳn API | 20 |
| FR-02-040 | Xóa API | 20 |
| FR-02-041 | Đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển | 21 |
| FR-02-042 | Tạo phiên bản mới | 18 |
| FR-02-043 | So sánh phiên bản và phân loại thay đổi phá vỡ | 18 |
| FR-02-044 | Phân tích tác động của thay đổi tới bên khai thác | 18 |
| FR-02-045 | Chuyển chủ quản API | 22 |
| FR-02-046 | Gửi đăng ký sử dụng API | 23 |
| FR-02-047 | Duyệt hoặc từ chối đăng ký sử dụng | 24 |
| FR-02-048 | Cấp phạm vi truy cập theo đăng ký đã duyệt | 25 |
| FR-02-049 | Xem đăng ký theo API | 26 |
| FR-02-050 | Xem đăng ký theo HTTT | 26 |
| FR-02-051 | Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký | 27 |
| FR-02-052 | Gia hạn và rà soát định kỳ đăng ký | 28 |
| FR-02-053 | Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14 | 29 |
| FR-02-054 | Theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn | 30 |
| FR-02-055 | Khai báo cam kết chất lượng dịch vụ (SLA) | 31 |
| FR-02-056 | Đối chiếu SLA thực tế, báo cáo tuân thủ | 32 |
| FR-02-057 | Thông báo thay đổi cho bên khai thác | 33 |
| FR-02-058 | Thống kê sử dụng dịch vụ | 34 |
| FR-02-059 | Cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15 | 35 |
| FR-02-060 | Đối soát cấu hình công bố với gateway | 36 |
| FR-02-061 | Di trú API, gói, đăng ký từ APIM cũ | 37 |
| FR-02-062 | Cấu hình tham số của phân hệ | 38 |

: Truy vết từ chức năng sang use case

## 12. Phụ thuộc, giả định và ràng buộc

Chương này nêu những gì PH-02 cần từ phân hệ khác và hệ quả khi chúng không khả dụng, các giả định có ghi cơ sở, và các ràng buộc pháp lý, kỹ thuật phải giữ.

### 12.1. Phụ thuộc

Bảng dưới liệt kê các phân hệ và dịch vụ mà PH-02 cần để chạy đủ chức năng, và điều gì xảy ra khi chúng không khả dụng.

| Phụ thuộc | Loại | Dùng cho | Khi không khả dụng |
|---|---|---|---|
| PostgreSQL `pg-core` (schema `ph02_catalog`) | Cứng | Mọi dữ liệu của phân hệ | Không quản lý được vòng đời, danh mục; API đang chạy không ảnh hưởng (NFR-02-008) |
| Kho đối tượng Garage | Cứng với đặc tả | Lưu đặc tả, gói xuất | Không nạp, đọc được đặc tả (ERR-02-034); danh mục metadata vẫn đọc |
| PH-03 (bộ đồng bộ cấu hình) và APISIX | Cứng khi công bố | Đẩy cấu hình, sức khỏe backend | Phiên bản giữ `PENDING`, thử lại (ERR-02-033) |
| PH-01 (hồ sơ HTTT) | Mềm | Kiểm tra HTTT, đầu mối, định danh máy | Dùng bản sao đệm; quá 24 giờ thì chặn đăng ký mới và công bố mới |
| PH-12 (Keycloak, OPA) | Cứng với cấp phạm vi | Gắn phạm vi theo đăng ký | Đăng ký ở `grantStatus = PENDING`, thử lại; không cấp lỏng |
| PH-04 | Mềm | Sinh khung luồng, sự kiện luồng REST, xác minh backend `FLOW` | Không sinh được khung, không đăng ký tự động từ luồng; API nhập tay vẫn dùng được |
| PH-05 | Mềm | Kết nối cho backend `SYSTEM` | Không chọn được kết nối mới; backend đã khai báo không ảnh hưởng |
| PH-10 | Mềm | Dịch vụ sự kiện | Hiển thị phần đã đệm |
| PH-13 | Mềm | SLA thực tế, thống kê, sức khỏe backend | Hiển thị số liệu gần nhất đã đệm; kỳ SLA chờ chốt |
| PH-14 và Nền tảng quốc gia | Mềm | Đồng bộ danh mục quốc gia | Bản ghi vào hàng đợi, thử lại; cảnh báo sau 7 ngày |
| PH-15 | Mềm (bên tiêu thụ) | Hiển thị danh mục | PH-15 dùng bản danh mục đã đệm |
| PH-18 | Mềm | Tham số, hộp việc, thông báo | Tham số đệm 60 giây rồi mặc định; việc duyệt vẫn mở ở UI-02-10 |
| Kafka, Apicurio | Cứng với sự kiện | EVT-02-*, sự kiện luồng | Outbox giữ sự kiện, không mất; tiêu thụ chậm |
| Dịch vụ quét mã độc (DD-12) | Cứng với nhập tệp | FR-02-011, 061 | Từ chối nhận tệp (ERR-02-034) |

: Phụ thuộc của PH-02

### 12.2. Giả định

Bảng dưới ghi các giả định đã dùng khi thiếu số liệu thật, kèm cơ sở; giả định nào sai thì phần liên quan phải xem lại.

| Mã | Giả định | Cơ sở |
|---|---|---|
| GĐ-02-01 | Tỉnh vừa sau năm đầu có khoảng 180 API công bố (60 HTTT cung cấp, trung bình 3 API), 400 phiên bản, 360 gói (2 gói mỗi API), 640 đăng ký (80 HTTT khai thác, trung bình 8 API); trần thiết kế gấp 10 lần | GĐ-04 (200 HTTT, 80 HTTT kết nối năm đầu); số thật lấy khi khảo sát |
| GĐ-02-02 | Khoảng 60% API có backend `FLOW` (đi qua luồng PH-04), 40% trỏ thẳng HTTT qua kết nối PH-05 loại HTTP | Hướng "mọi yêu cầu ra vào qua bộ điều hợp" (CMP-LAW-09) và thực tế một số HTTT đã có REST; dùng để định cỡ kiểm thử, thay bằng số khảo sát (Q02-06) |
| GĐ-02-03 | Khoảng 70% đặc tả nạp lần đầu có ít nhất một lỗi lớp 2 và 10% có phát hiện bí mật hoặc dữ liệu cá nhân thật ở ví dụ | Kinh nghiệm các dự án API đầu tiên của cơ quan nhà nước; dùng để định cỡ hỗ trợ chủ dịch vụ và mẫu đặc tả, không dùng làm chỉ tiêu nghiệm thu |
| GĐ-02-04 | Nền tảng quốc gia có đường đăng ký danh mục dịch vụ chia sẻ qua API hoặc biểu mẫu mà PH-14 nối được; PH-14 đảm nhận chứng thư, giới hạn tần suất | NĐ 278/2025; ADR-057; chưa có đặc tả kỹ thuật (Q02-08) |
| GĐ-02-05 | Mỗi tenant có realm Keycloak hỗ trợ `private_key_jwt` và `tls_client_auth`, và CA HTTT của OpenBao cấp chứng thư máy | SEC-24, D03-10 §5.2 |
| GĐ-02-06 | Mỗi chủ dịch vụ có người đại diện thuộc tổ chức của HTTT cung cấp và đầu mối kỹ thuật đã khai ở PH-01 | Quy trình kết nạp PH-01 |
| GĐ-02-07 | Nhà thầu tích hợp có thể chạy kiểm tra đặc tả ngoài (CI) bằng FR-02-019 với token người dùng | Thực tế các nhà thầu dựng API trước khi nộp |

: Giả định của PH-02

### 12.3. Ràng buộc

Bảng dưới liệt kê các ràng buộc pháp lý, kỹ thuật và vận hành mà thiết kế của PH-02 phải tuân thủ, kèm nguồn.

| Ràng buộc | Nguồn |
|---|---|
| Mỗi dịch vụ công bố có tài liệu kỹ thuật (đặc tả OpenAPI) tải được | CMP-LAW-03 (kế thừa NĐ 47/2020 Điều 24) |
| Thông tin dịch vụ chia sẻ được công khai theo phạm vi quy định | CMP-LAW-03 (kế thừa NĐ 47/2020 Điều 25) |
| Danh mục dịch vụ chia sẻ được đăng ký lên Nền tảng quốc gia | CMP-LAW-03, CMP-LAW-19 (kế thừa NĐ 47/2020 Điều 26) |
| Đặc tả theo chuẩn mở OpenAPI 3.1 | Nguyên tắc API trước, mã sau; D02-02 |
| Chia sẻ dữ liệu giữa cơ quan nhà nước không thu phí | NĐ 47/2020 (kế thừa); BR-02-040 |
| Không công bố dữ liệu thuộc danh mục bí mật nhà nước | Luật Bảo vệ bí mật nhà nước (chưa có mã `CMP-LAW`, xem Đề nghị đồng bộ) |
| Xác thực máy–máy theo mức phân loại: mTLS hoặc `private_key_jwt` cho dữ liệu từ Hạn chế | SEC-24, CMP-LAW-08 |
| APISIX chỉ công bố route khai báo trong OpenAPI đã duyệt | SEC-43 |
| Control plane tách khỏi data plane, data plane không gọi đồng bộ control plane trên đường xử lý lượt gọi | ADR-013, NFR-00-012 |
| Cấu hình gateway chế độ standalone, ảnh chụp có chữ ký, lan truyền ≤ 10 giây | D03-09 §6.1, ADR-005 |
| Toàn bộ công nghệ mã nguồn mở | Yêu cầu dự án |

: Ràng buộc của PH-02

## 13. Câu hỏi mở

> **Câu hỏi mở Q02-01:** Số điều khoản của NĐ 278/2025/NĐ-CP thay cho Điều 24, 25, 26 của NĐ 47/2020 (công bố, công khai, đăng ký danh mục dịch vụ chia sẻ) chưa được đối chiếu với Công báo; tập này viện dẫn ở mức văn bản (CMP-LAW-03, 19). Cần đơn vị thẩm định pháp lý xác nhận số điều và có cần đăng ký mã `CMP-LAW` riêng cho nghĩa vụ này không.

> **Câu hỏi mở Q02-02:** Tìm kiếm toàn văn dùng PostgreSQL (`tsvector`, `unaccent`) hay OpenSearch (bộ phân tích tiếng Việt). Đề xuất: PostgreSQL mặc định cho `QM-NHO`, `QM-VUA`, OpenSearch tùy chọn cho `QM-LON`, `QM-CHUNG`; chốt ở SDD PH-02 sau khi đo với 10.000 phiên bản (NFR-02-002).

> **Câu hỏi mở Q02-03:** Sửa mô tả của API đã công bố (FR-02-014) không qua duyệt lại, chỉ ghi kiểm toán. Có chấp nhận không, khi mô tả được công khai theo nghĩa vụ công bố thông tin. Đề xuất: không duyệt lại với sửa chính tả và làm rõ; sửa làm đổi bản chất dịch vụ phải tạo phiên bản mới.

> **Câu hỏi mở Q02-04:** Hạn chuyển đổi tối thiểu 180 ngày khi ngừng khuyến nghị (BR-02-004) kế thừa từ SRS cũ (6 tháng), chưa có văn bản quy định. Có văn bản của tỉnh hay của Bộ quy định thời hạn báo trước không. Đề xuất: giữ 180 ngày làm mặc định, tenant chỉnh trong 30…720 ngày (`02.deprecation.min-days`).

> **Câu hỏi mở Q02-05:** Dịch vụ sự kiện trong danh mục (FR-02-009) có cần PH-10 phát thêm sự kiện riêng không (Q10-19). Đề xuất: không, dùng EVT-10-01, 03, 04 là đủ; PH-02 đọc mô tả và lược đồ qua API của PH-10.

> **Câu hỏi mở Q02-06:** Có cho API trỏ thẳng HTTT (backend `SYSTEM`) hay bắt buộc mọi API đi qua luồng PH-04 để thỏa "mọi yêu cầu ra vào qua bộ điều hợp" (CMP-LAW-09). Đề xuất: cho phép với HTTT đã có REST, qua kết nối PH-05 loại HTTP; bắt buộc luồng với SOAP, CSDL, tệp. Cần ý kiến đơn vị thẩm định kiến trúc.

> **Câu hỏi mở Q02-07:** Khi sáp nhập tỉnh hoặc đơn vị (REQ-20), chuyển chủ quản API (FR-02-045) có cần văn bản giao nhận ký số lưu ở Datahub không, hay chỉ ghi số, ngày văn bản. Đề xuất: chỉ ghi số, ngày văn bản ở bản 0.1.

> **Câu hỏi mở Q02-08:** Định dạng và giao thức đăng ký danh mục dịch vụ lên Nền tảng quốc gia (mã dịch vụ quốc gia, trường bắt buộc, cách rút danh mục, cách nhận xác nhận) chưa có đặc tả chính thức. Cần Cục/Bộ cung cấp hoặc PH-14 xác minh khi khảo sát; ảnh hưởng nội dung gói ở FR-02-053.

> **Câu hỏi mở Q02-09:** Đơn giá gói (`unitPriceVnd`, BR-02-040) có cần thiết khi chia sẻ giữa cơ quan nhà nước không thu phí. Đề xuất: giữ trường thông tin, mặc định 0, để dành cho dịch vụ có thu (dịch vụ công thương mại hóa) xử lý ở PH-19.

> **Câu hỏi mở Q02-10:** API mức `SENSITIVE` có được đặt mức hiển thị `NATIONAL` không. Đề xuất: không (BR-02-037); khai thác liên tỉnh dữ liệu Nhạy cảm đi qua dịch vụ quốc gia của PH-14, không đi qua danh mục công khai.

> **Câu hỏi mở Q02-11:** Danh sách miền thư và số điện thoại được coi là "giữ chỗ" trong ví dụ của đặc tả (`example.gov.vn`…) và 9 mẫu quét bí mật (SCAN-02-01…09) cần Cán bộ ATTT duyệt; có cần thêm mẫu cho số định danh tổ chức, biển số xe không.

> **Câu hỏi mở Q02-12:** Gói `KEYLESS` cho API `PUBLIC` mở cho mọi người gọi không cần danh tính; có cần buộc bật bảo vệ bot và giới hạn theo IP ở PH-03 mặc định không. Đề xuất: bắt buộc giới hạn theo IP và WAF ở mức mặc định (SEC-10, SEC-11), cấu hình ở PH-03.

> **Câu hỏi mở Q02-13:** Phương pháp đo tỷ lệ sẵn sàng của SLA (FR-02-056): loại lỗi `5xx` do backend bên ngoài tỉnh, lỗi `429` do hạn mức riêng của bên gọi có tính vào sẵn sàng không. Đề xuất: tính `5xx` và hết thời gian chờ do backend; không tính `4xx`, `429`. Cần đơn vị chủ quản dịch vụ xác nhận.

> **Câu hỏi mở Q02-14:** KPI-05 yêu cầu từ khi nộp hồ sơ kết nạp tới khi HTTT gọi được API ở môi trường thật không quá 5 ngày làm việc. Quy trình gồm kết nạp (PH-01), công bố (PH-02) và duyệt đăng ký. Đề xuất ngân sách thời gian: kết nạp 2 ngày, duyệt công bố 1 ngày, duyệt đăng ký 1 ngày, còn lại cho cấp định danh; cần xác nhận với Chủ đầu tư.

## 14. Tiêu chí chấp nhận cấp phân hệ

Phân hệ được coi là đạt khi thỏa đồng thời các tiêu chí dưới đây; hội đồng thẩm định dùng danh sách này để nghiệm thu.

1. Mọi FR mức M có ít nhất một ca kiểm thử dương và một ca âm đạt ở D05-02-PH02; ca rò rỉ chéo tenant cho mọi API đọc và ghi đạt (NFR-02-013).
2. Bộ kiểm thử rò rỉ bí mật (NFR-02-012): phát hiện ≥ 95% bộ 50 mẫu chuẩn và không tìm thấy giá trị đánh dấu ở log, vết, kết quả kiểm tra, sự kiện, CSDL `pg-core`.
3. Đi trọn vòng đời với ít nhất 5 API thật: nháp, kiểm tra, thử TEST, gửi duyệt, duyệt bốn mắt, `PUBLISHED`, trong đó có một API sinh từ luồng PH-04 (FR-02-013) và một API mức Hạn chế dùng xác thực mTLS (BR-02-016).
4. Phiên bản có hai đăng ký đang hiệu lực: ngừng khuyến nghị với hạn 180 ngày, mọi bên nhận thông báo trong 15 phút, tiêu đề `Deprecation`, `Sunset` có trong phản hồi; tới hạn mà còn đăng ký thì không tự `RETIRED` (BR-02-006).
5. Duyệt một đăng ký: gọi được API trong ≤ 30 giây (NFR-02-005); thu hồi đăng ký: lượt gọi tiếp theo bị chặn trong ≤ 30 giây; HTTT chưa có định danh máy vào trạng thái chờ cấp, không cấp lỏng.
6. Thay đổi phá vỡ nhưng giữ số chính bị chặn khi gửi duyệt (ERR-02-017); phiên bản cùng số chính thay thế đúng phiên bản cũ và chuyển đăng ký sang gói cùng mã (BR-02-035).
7. Đồng bộ quốc gia: ít nhất một API mức `NATIONAL` đồng bộ `ACKED` (ở môi trường thử có PH-14 mô phỏng); chặn PH-14 8 ngày thì cảnh báo tuân thủ phát ra; từ chối của nền tảng quốc gia được hiển thị kèm lý do (FR-02-054).
8. Tắt toàn bộ `dh-connect` 24 giờ ở môi trường thử: API đang chạy tiếp tục phục vụ, không lệch cấu hình khi bật lại (NFR-02-008, kiểm thử hỗn loạn CX-01).
9. Đạt NFR-02-001, 003, 005, 009 và 012 ở hồ sơ "tỉnh vừa".
10. Nhập thử một gói xuất APIM cũ: báo cáo đối chiếu số lượng khớp, không khóa API nào được nhập, đăng ký ở `SUSPENDED` chờ định danh (BR-02-036).
11. Quy ước viết API, mẫu đặc tả OpenAPI và hướng dẫn công bố đã ban hành và tải được từ UI-02-03 (FR-02-015).
12. Mọi mục `LGC` ở mục 11.1 có kết luận và ca UAT tương ứng ở D05-02-PH02 §7; thuyết minh nghĩa vụ công bố, công khai, đăng ký danh mục (CMP-LAW-03) được hội đồng chấp thuận.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây nằm ngoài quyền sửa của tập này (tài liệu dùng chung hoặc phân hệ khác); chuyển cho luồng hoặc đợt đồng bộ phụ trách.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 §3.1 | Bổ sung một quyền quản trị phân hệ PH-02 với động từ `admin` (PA, TA) cho tham số, bộ phân loại, bộ luật, chuyển chủ quản, di trú; cân nhắc tách động từ `delete` (TA, SV ○) và `sync` (TA, TO) khỏi `create` và `operate` nếu hội đồng muốn quyền chi tiết hơn (tập này dùng nhóm tạo, sửa, xóa mềm của `PERM-02-create` và nhóm vận hành của `PERM-02-operate`); ghi rõ `PERM-02-publish` gồm duyệt ngừng khuyến nghị, ngừng hẳn, nâng mức hiển thị, thay đổi backend; ghi `PERM-02-approve-subscription` của SV chỉ đủ với dữ liệu dưới mức Hạn chế (BR-02-026) |
| D02-08 §5 | Bổ sung scope máy nội bộ của PH-02: `catalog:read`, `catalog:gateway-read`, `catalog:portal-read`, `catalog:flow-sync`, `catalog:metrics-read` |
| D02-02 SRS (bảng PH-02) và D02-01 (REQ-02) | Sửa cột `LGC` thành `APIM-001…006, 008…011, 016…018, 021; BUS-028` cho khớp D00-03 (`APIM-007` thuộc PH-15, `APIM-012…015` thuộc PH-03, `APIM-010` thuộc PH-02) |
| D00-01 §7 | Thêm `CMP-LAW` cho Luật Bảo vệ bí mật nhà nước (căn cứ BR-02-007); xem xét mã riêng cho nghĩa vụ công bố, công khai, đăng ký danh mục (Q02-01) |
| D03-06-00 §2.3 | Bổ sung mục menu "Kết nối & API": `/ket-noi/dong-bo-quoc-gia` (UI-02-12), `/ket-noi/tuan-thu-sla` (UI-02-11), `/ket-noi/quan-tri/phan-loai` (UI-02-14), `/ket-noi/quan-tri/nhap-apim-cu` (UI-02-16); thêm tab Backend, SLA vào ví dụ chi tiết API |
| D03-05 | Không đề nghị bổ sung thành phần mới; dùng `CMP-DiffViewer`, `CMP-ApiSelect`, `CMP-Transfer`, `CMP-VersionTimeline`, `CMP-DependencyGraph` hiện có. Nếu cần bảng "diff theo cấp" riêng cho phân loại phá vỡ thì ghi ở D03-06-PH02 |
| D03-07 | Ghi nơi hiện thực của SEC-43 là FR-02-036 (chỉ công bố route khai báo trong đặc tả đã duyệt), SEC-24 là FR-02-028, FR-02-048 (kiểm tra khi đăng ký sử dụng) |
| D03-09 §6.1 | Ghi PH-02 là nguồn dữ liệu cho ảnh chụp cấu hình (FR-02-059) và chỉ tiêu NFR-02-005 (hiệu lực ≤ 30 giây, lan truyền ≤ 10 giây) |
| D03-10 | Ghi hạn mức tenant cho `02.*` cần trần nền tảng: số API, số phiên bản, số đăng ký (NFR-02-010) |
| D05-01 | Thêm ca hỗn loạn "tắt `dh-connect` khi đang công bố" và ca "PH-14 chặn 8 ngày" cho PH-02 |
| PH-04 FRS | Xác nhận API đọc điểm vào REST của luồng cho FR-02-022 (loại `FLOW`) và dùng FR-04-003 nguồn `API_SPEC` ở FR-02-026; xác nhận sự kiện EVT-04-02, 04, 07 mang `restOperations[]` cho FR-02-013 |
| PH-05 FRS | Xem xét cho phép "cấp kết nối cho API của PH-02" (ngoài cấp cho không gian làm việc, luồng ở FR-05-009) để backend `SYSTEM` dùng được kết nối |
| PH-10 FRS | Trả lời Q10-19 theo Q02-05 |
| PH-01, PH-03, PH-12, PH-14, PH-15, PH-18 (khi viết) | Hiện thực các điểm giao tiếp ở mục 3.3, 9.3, 12.1: PH-03 nhận dữ liệu từ API-02-080 và xác nhận qua API-02-082; PH-12 gắn phạm vi `api:*`; PH-14 nhận gói đồng bộ; PH-15 tiêu thụ API-02-081 và EVT-02-*; PH-18 giữ tham số `02.*` |
| `build/tools/kiem_tra_ma.py` | Công cụ đếm `NFR-02-021`, `NFR-02-022` ở cột "Mã cũ" của §11.2 như mã đã định nghĩa nên bảng dải mã (D00-04 §3.2) ghi NFR-02 có 22 mã và số kế tiếp là 023; số kế tiếp thật của bộ mới là `NFR-02-021`. Đề nghị công cụ bỏ qua bảng ánh xạ mã cũ, hoặc đánh dấu cột là mã cũ |
| Đề xuất ADR | (1) Phiên bản là đơn vị vòng đời, gói thuộc phiên bản, cùng số chính thay thế phiên bản đang chạy (BR-02-035); (2) tìm kiếm danh mục: PostgreSQL mặc định, OpenSearch tùy chọn (Q02-02). Chưa tạo ADR trong tập này |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 62 FR theo chuẩn kết hợp 17 mục chia mười nhóm, 40 quy tắc nghiệp vụ, 20 yêu cầu phi chức năng, 17 màn hình, 91 API, 16 sự kiện, 45 mã lỗi; ma trận truy vết 15 mục `LGC` của PH-02 và bảng ánh xạ mã cũ của SRS cũ (14 FR, 22 NFR, 15 BR, 32 kịch bản chấp nhận) sang mã mới; hai ảnh giao diện tiêu biểu; 14 câu hỏi mở |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo bảy tập: thêm API-02-092…098 vào §9.4 và các FR liên quan; bảng thông báo §9.2 đủ 45 mã và khớp tập màn hình; thêm §11.4 FR → use case; thêm cạnh `PUBLISHED → RETIRED` và trạng thái `activating` ở §4.3; phạm vi `catalog:gateway-ack`; loại yêu cầu duyệt `PLAN_CLOSE`, `SUBSCRIPTION_RENEW`; quyền của FR-02-018; làm rõ BR-02-031; thống nhất route màn hình; xưng hô "Bạn" trong câu thông báo |
