---
ma_tai_lieu: D02-03-PH15
ten: Đặc tả yêu cầu chức năng phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư dh-portal và dh-connect, kiểm thử viên, chủ dịch vụ, quản trị tỉnh
phan_he: PH-15
mo_ta: Đặc tả hành vi của cổng nhà phát triển gồm danh mục và tài liệu API, hướng dẫn, tài khoản và ứng dụng sandbox, thử API, điểm vào nghiệp vụ và quản trị cổng, làm căn cứ thiết kế chi tiết, lập trình và kiểm thử.
tai_lieu_lien_quan: D02-02 SRS; D02-04-PH15 Use case; D03-02-PH15 Thiết kế chi tiết; D03-03-PH15 CSDL; D03-04-PH15 API; D03-06-PH15 Màn hình; D05-02-PH15 Test case
---

# D02-03-PH15 · Đặc tả yêu cầu chức năng Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-15 là cửa duy nhất để nhà phát triển, gồm cán bộ kỹ thuật của các cơ quan nhà nước (CQNN) và nhà thầu viết phần mềm cho họ, tự tìm hiểu, thử và xin dùng các dịch vụ chia sẻ dữ liệu trên Datahub mà không phải gọi điện, gửi công văn hay chờ người hướng dẫn từng bước. Phân hệ gồm sáu việc: **danh mục và tìm kiếm** dịch vụ theo đúng người xem; **tài liệu API** (OpenAPI 3.1, AsyncAPI 3.0, mẫu mã sáu ngôn ngữ, lộ trình ngừng dùng); **hướng dẫn** viết bằng Markdown có duyệt bốn mắt; **tài khoản và ứng dụng sandbox** để tự cấp thông tin xác thực thử; **sandbox và thử API** trên dữ liệu tổng hợp; và **điểm vào nghiệp vụ** (đăng ký sử dụng, kết nạp HTTT, công bố API) chuyển đúng sang PH-01, PH-02. PH-15 là lớp trình bày và tự phục vụ, không phải nơi quyết định: PH-02 giữ sự thật về API, PH-03 thực thi lúc chạy, PH-01 và PH-12 cấp định danh chính thức.

**Phạm vi.** 62 yêu cầu chức năng chia mười nhóm (A đến J): danh mục và tìm kiếm; tài liệu API; hướng dẫn và nội dung; tài khoản nhà phát triển; ứng dụng và thông tin xác thực sandbox; sandbox và thử API; đăng ký và điểm vào nghiệp vụ; theo dõi của nhà phát triển; hỗ trợ; quản trị cổng. Giao diện là ứng dụng `dh-portal` (React 19, antd v6, Liquid Glass) với BFF nhẹ ở vùng Z2; phần máy chủ là module `portal` trong DU `dh-connect` (vùng Z3). Bộ mới tự xây cổng trên `@datahub/ui`, không dùng Backstage như SRS cũ; lý do và đề xuất ADR nằm ở mục Đề nghị đồng bộ.

**Căn cứ pháp lý.** CMP-LAW-03 (NĐ 278/2025: kết nối, chia sẻ dữ liệu; nghĩa vụ công bố thông tin và tài liệu kỹ thuật dịch vụ kế thừa Điều 24, 25 NĐ 47/2020); CMP-LAW-05 và CMP-LAW-04 (Luật BVDLCN 91/2025, NĐ 356/2025: dữ liệu cá nhân của người đăng ký tài khoản, cấm dùng dữ liệu cá nhân thật ở sandbox); CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3: xác thực, quản lý phiên, bí mật, nhật ký); CMP-LAW-16 (Luật ANM 116/2025: nhật ký, lưu trữ trong nước); CMP-LAW-09 (Công văn 631/THH-THHT: yêu cầu của LGSP).

**Những điểm hội đồng cần lưu ý.** (1) Cổng không phải nơi quản lý API: mọi trạng thái, đăng ký, duyệt đều ở PH-02, PH-01; cổng chỉ hiển thị và chuyển yêu cầu đi, nên đổi giao diện không ảnh hưởng vòng đời API. (2) Nhà thầu chưa phải cán bộ vẫn dùng được cổng qua tài khoản riêng ở realm `dh-dev`, nhưng phải xác minh thư, được quản trị cổng duyệt, chỉ thử sandbox và không bao giờ chạm dữ liệu thật. (3) Bí mật sandbox chỉ hiện đúng một lần và không được lưu ở cổng; thông tin xác thực production không hiển thị ở cổng, chỉ có tham chiếu. (4) Thử trên production mặc định tắt, chỉ bật theo từng dịch vụ sau phê duyệt, cấm với API có nhãn dữ liệu Hạn chế, Nhạy cảm, và từ chối ngay nếu không ghi được kiểm toán. (5) Trình duyệt không cầm token (BFF, SEC-21), nội dung hướng dẫn qua bộ lọc an toàn và CSP chặt (SEC-44).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng | 62 (M: 47, S: 13, C: 2) |
| Quy tắc nghiệp vụ | 34 (BR-15-001…034) |
| Yêu cầu phi chức năng | 22 (NFR-15-001…022) |
| Mã lỗi | 63 (ERR-15-001…040 control plane, ERR-15-101…123 sandbox và thử API) |
| Sự kiện | 14 (EVT-15-01…14) |
| API | 142 operation (API-15-001…142) |
| Màn hình | 28 (UI-15-01…28) |
| Chức năng hệ cũ được phủ | 5 mục `LGC` chính (APIM-006, 007, 017, IAM-006, phần nhà phát triển của APIM-022), 2 mục liên quan; 16 FR của SRS cũ đều có chỗ trong tập mới |
| Câu hỏi mở | 19 (Q15-01…19) |
| Mức đợt | Đợt 2 (tuần W4); ba FR mức S, C (018, 041, 053) sang Đợt 3 |

: Con số chính của PH-15

## 1. Giới thiệu

### 1.1. Mục đích của tài liệu

Tài liệu đặc tả đầy đủ hành vi của phân hệ PH-15 Cổng nhà phát triển ở mức mà ba nhóm người đọc dùng được ngay. Hội đồng thẩm định dùng tài liệu để đánh giá cổng có đáp ứng nghĩa vụ công bố thông tin dịch vụ, bảo vệ dữ liệu cá nhân và an toàn thông tin cấp độ 3 hay không. Kỹ sư dùng tài liệu làm đầu vào cho thiết kế chi tiết D03-02-PH15, thiết kế CSDL D03-03-PH15 và đặc tả API D03-04-PH15; riêng Phụ lục A là nguồn chuẩn cho enum, trạng thái, route và tham số mà các tập sau phải theo. Kiểm thử viên dùng luồng chính, luồng ngoại lệ và quy tắc nghiệp vụ để viết ca kiểm thử ở D05-02-PH15.

Mỗi chức năng được đặc tả theo một khung 17 mục: mục đích, tác nhân và quyền, mức ưu tiên, truy vết, tiền điều kiện, kích hoạt, đầu vào, luồng chính, luồng thay thế, luồng ngoại lệ kèm câu thông báo, đầu ra, kết quả, hậu điều kiện, sự kiện, kiểm toán, quy tắc nghiệp vụ, màn hình và API.

### 1.2. Phạm vi

PH-15 chịu trách nhiệm mười nhóm việc dưới đây. Điểm chung: PH-15 trình bày và tự phục vụ, không sở hữu sự thật nghiệp vụ nào ngoài nội dung hướng dẫn, tài khoản nhà phát triển, ứng dụng sandbox và lịch sử thử.

| # | Trách nhiệm | Nhóm FR |
|---|---|---|
| 1 | Giữ bản sao danh mục từ PH-02, áp mức hiển thị theo người xem, duyệt, lọc, tìm toàn văn tiếng Việt, trang chi tiết dịch vụ, đường dẫn sử dụng, dịch vụ sự kiện, truy cập ẩn danh | A |
| 2 | Hiển thị OpenAPI 3.1, AsyncAPI 3.0, chọn phiên bản, tải đặc tả, mẫu mã, changelog và lộ trình ngừng | B |
| 3 | Quản lý trang hướng dẫn Markdown, soạn, duyệt bốn mắt, phiên bản, nhập từ Git | C |
| 4 | Đăng nhập SSO realm tenant, tự đăng ký realm `dh-dev`, hồ sơ, nhóm, điều khoản sử dụng | D |
| 5 | Ứng dụng sandbox, cấp `client_credentials` hoặc API key sandbox, hiện bí mật một lần, xoay, thu hồi, tham chiếu thông tin xác thực production | E |
| 6 | Sandbox `MOCK` và `BACKEND`, thử API, dữ liệu tổng hợp, hạn mức, lịch sử, bộ sưu tập, xuất công cụ, thử production có kiểm soát | F |
| 7 | Điểm vào đăng ký sử dụng, kết nạp HTTT, công bố API, ủy thác cho PH-02, PH-01 | G |
| 8 | Bảng điều khiển, thống kê, nhật ký gọi đã che, theo dõi thay đổi, hộp thông báo | H |
| 9 | Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ chuyển chủ dịch vụ | I |
| 10 | Nhận diện cổng theo tenant, tham số, duyệt và khóa tài khoản, kiểm toán, đồng bộ lại, đối soát, di trú nội dung portal hệ cũ | J |

: Trách nhiệm của PH-15

Những việc dưới đây liên quan nhưng không thuộc PH-15. Tài liệu chỉ mô tả điểm giao tiếp với các phân hệ đó.

| Không làm | Thuộc |
|---|---|
| Vòng đời API (nháp, duyệt, công bố, ngừng), đặc tả gốc, gói sử dụng, duyệt đăng ký sử dụng, mức hiển thị `portalPublished` | PH-02 |
| Thực thi lúc chạy: định tuyến, hạn mức, mTLS, WAF; cấu hình tuyến sandbox | PH-03 |
| Kết nạp HTTT, cấp định danh và bí mật production | PH-01, PH-12 |
| Keycloak, realm, OPA, token exchange | PH-12 |
| Lưu chỉ số, nhật ký kiểm toán chuỗi băm, bảng điều khiển vận hành | PH-13 |
| Topic Kafka, lược đồ sự kiện (AsyncAPI gốc) | PH-10 |
| Chỉ tiêu kiến trúc, đăng ký kiến trúc (hạng mục Architecture Registry của SRS cũ) | PH-16 |
| Trình thiết kế luồng, runtime tích hợp | PH-04, PH-05 |

: Việc ngoài phạm vi PH-15

### 1.3. Đối tượng sử dụng và cách đọc

Mỗi nhóm người đọc nên đọc các phần phù hợp với việc của mình, theo bảng dưới.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, 3, 5, 11, 14, Đề nghị đồng bộ | Đánh giá sự cần thiết, ranh giới với PH-02, mức an toàn, mức phủ hệ cũ |
| Chủ đầu tư, quản trị tỉnh | Chương 2, mục 6.10, chương 8, chương 10 | Biết việc phải làm: duyệt tài khoản, nội dung, thử production, tham số |
| Chủ dịch vụ, cán bộ đầu mối | Mục 6.3, 6.7, 6.8, 6.9 | Khai báo sandbox, viết hướng dẫn, theo dõi đăng ký, xử lý hỗ trợ |
| Kỹ sư phát triển | Chương 4, 6, 7, 9, Phụ lục A | Hiện thực API, xử lý, quy tắc, mã lỗi, enum |
| Kiểm thử viên | Chương 6, 7, 8, 14 | Ca dương, âm, rò rỉ bí mật, chéo tenant, hạn mức |
| Vận hành | Mục 6.2, 6.6, 6.10, chương 8, 12 | Theo dõi đồng bộ, sandbox, đối soát, sự cố |

: Người đọc và phần cần đọc

Mã định danh (FR, BR, NFR, ERR, EVT, API, UI) theo quy ước ở D00-01 §3. Chức năng dùng chung của mọi phân hệ (đăng nhập OIDC, chọn tenant, phân trang, tìm kiếm không dấu, kiểm toán chung, thông báo, hộp "Việc của tôi", hiển thị lỗi) theo nhóm FR-00 của SRS và không lặp lại ở đây; tập này chỉ nêu phần PH-15 bổ sung.

### 1.4. Thuật ngữ và chữ viết tắt

Bảng dưới giải thích các thuật ngữ và chữ viết tắt riêng của PH-15; thuật ngữ chung của dự án xem D00-04.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| Nhà phát triển | Người viết hoặc bảo trì phần mềm của một HTTT: cán bộ kỹ thuật CQNN hoặc nhà thầu; dùng cổng để tìm, thử, xin dùng API |
| HTTT | Hệ thống thông tin của cơ quan, đơn vị kết nối vào Datahub |
| BFF | Backend-for-Frontend: máy chủ trung gian giữ token phía máy chủ, trình duyệt chỉ có cookie phiên (SEC-21) |
| Ứng dụng sandbox | Đối tượng của nhà phát triển ở cổng, đại diện cho phần mềm đang phát triển; mang thông tin xác thực chỉ dùng được ở sandbox |
| Thông tin xác thực | `client_credentials` (client ID và bí mật) hoặc API key; loại sandbox do cổng cấp, loại production do PH-01, PH-12 cấp |
| Sandbox | Môi trường thử tách khỏi production, gọi qua tuyến APISIX riêng, chỉ có dữ liệu tổng hợp |
| `MOCK` | Chế độ sandbox sinh phản hồi từ ví dụ và lược đồ trong OpenAPI, không gọi hệ thống nào |
| `BACKEND` | Chế độ sandbox chuyển lời gọi tới backend thử do chủ dịch vụ khai báo |
| Thử API (try-it) | Gửi một lời gọi thử từ trang tài liệu của cổng và xem phản hồi |
| Realm `dh-dev` | Realm Keycloak dành cho tài khoản nhà thầu và client sandbox, tách khỏi realm `dh-{tenant}` của cán bộ |
| `portalPublished` | Cờ của PH-02 cho phép một API hiện ở cổng |
| Mức hiển thị | `TENANT`, `NATIONAL`, `PUBLIC` của API (PH-02); quyết định ai thấy API ở cổng |
| Trang nội dung | Bài hướng dẫn, bắt đầu nhanh, hỏi đáp thường gặp hoặc thông báo, viết bằng Markdown và quản lý ở cổng |
| Bốn mắt | Một việc quan trọng cần hai người khác nhau: người soạn và người duyệt (FR-00-071) |
| SV, CA, TA, TO, SO, OR, DEV, AU, PA | Chủ dịch vụ, người duyệt dịch vụ, quản trị tỉnh, vận hành tỉnh, cán bộ ATTT, cán bộ đầu mối của tổ chức, nhà phát triển, kiểm toán, quản trị nền tảng (mục 3.1) |
| p95 | Phân vị 95: 95% lượt đo không vượt ngưỡng nêu |

: Thuật ngữ và chữ viết tắt

### 1.5. Tài liệu tham chiếu

Các tài liệu dưới đây là căn cứ của FRS này; khi có mâu thuẫn thì ưu tiên tài liệu chuẩn chung (D00-04, D02-08) rồi tới tài liệu của phân hệ.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| CMP-LAW-03 | Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu | Công bố thông tin dịch vụ, danh mục quốc gia |
| CMP-LAW-05, CMP-LAW-04 | Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15; Nghị định 356/2025/NĐ-CP | Dữ liệu người đăng ký, cấm dữ liệu cá nhân thật ở sandbox |
| CMP-LAW-06, CMP-LAW-08 | Nghị định 331/2026/NĐ-CP; TCVN 14423:2026 cấp độ 3 | Xác thực, phiên, bí mật, nhật ký, vô hiệu tài khoản 45 ngày |
| CMP-LAW-16 | Luật An ninh mạng 116/2025/QH15 | Nhật ký, dữ liệu trong nước |
| CMP-LAW-09 | Công văn 631/THH-THHT | Yêu cầu chức năng của LGSP |
| D02-01 BRD | BP-01, BO-03, REQ-15 | Quy trình kết nạp và cấp quyền, mục tiêu rút ngắn thời gian kết nối |
| D02-02 SRS | FR-00, NFR-00, bảng phân hệ | Chức năng dùng chung |
| D02-03-PH02 | FRS PH-02, đặc biệt FR-02-004, 005, 006, 041, 046, 057, 059, EVT-02-* | Nguồn danh mục, giao diện nội bộ `catalog:portal-read` |
| D02-08 | Ma trận phân quyền | `PERM-15-*`, `ROLE-DEVELOPER`, scope máy |
| D03-01 SAD | `dh-portal`, `dh-connect`, vùng mạng | Kiến trúc |
| D03-06-00 | Kiến trúc thông tin, mẫu màn `PTN-*` | Route, mẫu màn |
| D03-07 | SEC-20…29, SEC-31…33, SEC-43…45, SEC-60…62 | Biện pháp ATTT |
| ADR-005, ADR-006, ADR-012, ADR-013, ADR-020, ADR-031, ADR-041, ADR-042 | APISIX; Keycloak và OPA; OpenBao; tách control và data plane; Liquid Glass; nhật ký WORM; idempotency; inbox, outbox | Lý do của các lựa chọn |
| `docs/07-srs/SRS-PH-15-portal.md` | SRS cũ của repo (Backstage) | Bảng ánh xạ mã cũ ở mục 11.2 |

: Tài liệu tham chiếu

### 1.6. Cấu trúc tài liệu

Chương 2 trình bày bối cảnh, mục tiêu, kiến trúc, trình tự thử API và phần hệ cũ được phủ. Chương 3 nêu tác nhân và quyền. Chương 4 định nghĩa khái niệm, thực thể và bốn máy trạng thái. Chương 5 liệt kê 62 chức năng. Chương 6 đặc tả chi tiết từng chức năng theo mười nhóm. Chương 7 đến 9 gom quy tắc nghiệp vụ, yêu cầu phi chức năng, tham số, mã lỗi, thông báo, sự kiện và API. Chương 10 nêu giao diện. Chương 11 đến 14 là truy vết, phụ thuộc, câu hỏi mở và tiêu chí chấp nhận. Phụ lục A là nguồn chuẩn cho enum, route và giới hạn; tiếp theo là mục Đề nghị đồng bộ.

## 2. Tổng quan phân hệ

### 2.1. Bối cảnh và vấn đề cần giải quyết

Ở hệ cũ, nhà thầu muốn dùng một dịch vụ của LGSP phải xin thông tin qua công văn hoặc điện thoại, nhận tệp đặc tả qua thư điện tử, tự dựng môi trường thử và nhận khóa API qua kênh không kiểm soát. Gravitee portal của hệ cũ chỉ phục vụ xem danh sách API và tài liệu. SRS cũ của repo đề xuất Backstage làm cổng; khi đối chiếu với yêu cầu bắt buộc của dự án (antd v6 và vật liệu Liquid Glass tới từng thành phần, một design system cho mọi ứng dụng), lựa chọn đó không còn phù hợp. Bảng dưới nêu các hạn chế và cách PH-15 khắc phục.

| Hạn chế hệ cũ | Hệ quả | Cách PH-15 khắc phục |
|---|---|---|
| Tài liệu API gửi qua thư, nhiều phiên bản lưu hành song song | Nhà thầu code theo tài liệu lạc hậu, lỗi tích hợp muộn | Tài liệu sinh trực tiếp từ đặc tả đã công bố ở PH-02, luôn khớp bản đang chạy (FR-15-001, 009, 011) |
| Không có môi trường thử chuẩn | Thử trực tiếp trên hệ thật hoặc không thử | Sandbox `MOCK` và `BACKEND` trên tuyến APISIX riêng, dữ liệu tổng hợp (FR-15-034…039) |
| Khóa API cấp thủ công, gửi qua thư | Khóa lộ, không biết ai giữ, không thu hồi được | Thông tin xác thực sandbox tự cấp, hiện một lần, xoay và thu hồi được; production do PH-01, PH-12 cấp qua kênh riêng (FR-15-027…032) |
| Application tạo tự do, không gắn chủ thể chịu trách nhiệm (APIM cũ) | Không truy được người dùng | Ứng dụng sandbox gắn tài khoản, nhóm và tổ chức; production chỉ qua HTTT đã kết nạp (FR-15-025, 044) |
| Cổng chỉ xem được khi có tài khoản nội bộ | Nhà thầu ngoài không tiếp cận được | Realm `dh-dev` cho nhà thầu có duyệt; chế độ công khai theo tenant cho dịch vụ `PUBLIC` (FR-15-008, 020) |
| Không có kênh hỏi đáp, thông báo thay đổi | Đơn vị khai thác không biết API sắp ngừng | Thông báo thay đổi, hộp thông báo, hỏi đáp theo API (FR-15-051…055) |

: Hạn chế của hệ cũ và cách PH-15 khắc phục

### 2.2. Mục tiêu của phân hệ

Năm mục tiêu dưới đây đo được; chỉ tiêu chi tiết nằm ở NFR (chương 8) và được kiểm ở tiêu chí chấp nhận (chương 14).

1. **Rút ngắn thời gian bắt đầu.** Từ lúc nhà phát triển tạo ứng dụng sandbox đến lời gọi sandbox thành công đầu tiên: ≤ 15 phút với ≥ 80% nhà phát triển mới (NFR-15-006, NFR-15-022). Mục tiêu này đóng góp cho BO-03 (rút thời gian đưa một kết nối mới vào vận hành, mục tiêu ≤ 5 ngày).
2. **Tài liệu luôn đúng bản phát hành.** Sau khi PH-02 công bố hoặc đổi trạng thái, trang tài liệu ở cổng cập nhật p95 ≤ 30 giây, tối đa 5 phút kể cả khi mất sự kiện (NFR-15-004).
3. **Không lộ bí mật, không lộ dữ liệu thật.** 0 bí mật ngoài lần hiển thị đầu (NFR-15-009), 0 token trong bộ nhớ trình duyệt (NFR-15-010), 0 dữ liệu cá nhân thật ở sandbox qua kiểm tra mẫu nhận dạng (BR-15-016).
4. **Giảm hỗ trợ thủ công.** Giảm ≥ 50% số yêu cầu hỗ trợ về cách gọi API trong 6 tháng sau khi cổng chạy, tính theo số phiếu hỗ trợ (giả định nền: chưa đo ở hệ cũ, sẽ đo trong tháng đầu).
5. **Trải nghiệm nhanh và dùng được.** LCP ≤ 2,5 giây (NFR-15-001), tìm kiếm p95 ≤ 300 ms (NFR-15-002), WCAG 2.2 AA và dùng được từ 360 px (NFR-15-014).

### 2.3. Vị trí trong kiến trúc

PH-15 nằm ở mặt phẳng điều khiển, ngoài đường dữ liệu lúc chạy: cổng hỏng thì lời gọi API giữa các HTTT vẫn chạy bình thường. Giao diện `dh-portal` là tệp tĩnh phục vụ qua `apisix-ext` ở Z1 và BFF ở Z2; module `portal` của `dh-connect` ở Z3 giữ dữ liệu của cổng trong schema `ph15_portal` trên `pg-core`. Sơ đồ dưới cho thấy các thành phần và các phân hệ liền kề.

```{.mermaid caption="Vị trí của PH-15 trong kiến trúc"}
flowchart TB
  subgraph NGUOI["Người dùng"]
    DEV["Nhà phát triển"]
    STAFF["Chủ dịch vụ, quản trị cổng"]
    ANON["Khách ẩn danh"]
  end
  subgraph Z12["Z1, Z2"]
    APX["apisix-ext"]
    SPA["dh-portal tệp tĩnh"]
    BFF["BFF Spring Cloud Gateway"]
  end
  subgraph Z3["Z3 · dh-connect · module portal"]
    CAT["portal-catalog bản sao danh mục"]
    CON["portal-content trang nội dung"]
    DEVM["portal-dev tài khoản ứng dụng"]
    TRY["portal-try thử API"]
    MOCK["portal-sandbox MOCK và BACKEND"]
    SUP["portal-support hỗ trợ"]
  end
  subgraph LIEN["Phân hệ và hạ tầng liền kề"]
    PH02["PH-02 danh mục"]
    PH01["PH-01 kết nạp"]
    PH03["PH-03 APISIX tuyến sandbox"]
    PH12["PH-12 Keycloak OPA"]
    PH13["PH-13 kiểm toán chỉ số"]
    PH10["PH-10 sự kiện"]
    KAF["Kafka"]
    PG[("pg-core ph15_portal")]
    VK[("Valkey")]
    GAR[("Garage đính kèm")]
  end
  DEV --> APX
  STAFF --> APX
  ANON --> APX
  APX --> SPA
  APX --> BFF
  BFF --> CAT
  BFF --> CON
  BFF --> DEVM
  BFF --> TRY
  BFF --> SUP
  TRY --> MOCK
  TRY --> PH03
  CAT -->|"catalog:portal-read"| PH02
  PH02 -.->|"EVT-02"| KAF
  KAF -.-> CAT
  DEVM -->|"admin API realm dh-dev"| PH12
  TRY -->|"token exchange"| PH12
  TRY -->|"ghi kiểm toán"| PH13
  CON --> GAR
  CAT --> PG
  DEVM --> PG
  BFF --> VK
  CAT -.->|"danh mục topic"| PH10
  DEVM -->|"ủy thác kết nạp"| PH01
```

Hình cho thấy ba điều. Thứ nhất, mọi đường vào đều qua `apisix-ext` và BFF, trình duyệt không nói chuyện trực tiếp với `dh-connect`. Thứ hai, PH-15 chỉ đọc PH-02 và chỉ ủy thác cho PH-01, PH-02, không ghi vào trạng thái của họ. Thứ ba, tuyến sandbox thuộc cấu hình của PH-03; PH-15 không đẩy cấu hình gateway mà chỉ trả lời câu hỏi "lời gọi này có được phép không" cho APISIX qua giao diện nội bộ API-15-082.

### 2.4. Kiến trúc thành phần và công nghệ

Bảng dưới liệt kê các thành phần của PH-15. Các module `portal-*` là module Spring Modulith trong cùng DU `dh-connect` (ADR-001), package `vn.datahub.connect.portal`; SDD đã chốt `portal-mock` chạy trong DU `dh-connect` ở vai trò triển khai riêng `portal-sandbox` (QĐ-15-01), không làm plugin APISIX. Thiết kế tách thêm ba module `delegate`, `insight`, `admin` để mỗi module có một đầu mối trách nhiệm; chúng vẫn thuộc các nhóm chức năng của FRS này.

| Thành phần | Công nghệ | Vùng | Trách nhiệm |
|---|---|---|---|
| `dh-portal` (SPA) | React 19, TypeScript, antd v6, `@datahub/ui`, Liquid Glass (ADR-020) | Z2 (tệp tĩnh) | Giao diện cổng; trang tài liệu mẫu PTN-14; tiếng Việt mặc định |
| BFF của `dh-portal` | Spring Cloud Gateway nhẹ, một client bí mật cho cổng (SEC-21) | Z2 | OIDC Code + PKCE, giữ token ở Valkey, cookie `__Host-dh-sid`, đặt CSP |
| `portal-catalog` | Spring Boot, PostgreSQL, OpenSearch tùy chọn (PostgreSQL FTS và `unaccent` dự phòng) | Z3 | Bản sao danh mục từ PH-02, chỉ mục tìm kiếm, đặc tả đã phân tích |
| `portal-content` | Markdown (CommonMark), bộ lọc HTML an toàn, Garage | Z3 | Trang nội dung, phiên bản, duyệt bốn mắt, nhập Git |
| `portal-dev` | Spring Boot, Keycloak Admin API giới hạn realm `dh-dev` | Z3 | Tài khoản `dh-dev`, nhóm, ứng dụng, thông tin xác thực sandbox |
| `portal-try` | Spring Boot, WebClient, token exchange RFC 8693 (dự phòng: xác nhận JWS ký bằng khóa `transit` của OpenBao nếu Keycloak không đủ, QĐ-15-03) | Z3 | Chuyển lời gọi thử tới APISIX, đếm hạn mức theo người, ghi vết, kiểm tra PII |
| `portal-mock` (vai trò `portal-sandbox`) | Trình sinh phản hồi từ OpenAPI (ví dụ, schema); chuyển tiếp có allowlist và ngắt mạch | Z3 | Chế độ `MOCK` và chuyển tiếp `BACKEND`; không ghi CSDL |
| `portal-delegate` | Spring Boot | Z3 | Ủy thác đăng ký sử dụng, kết nạp, công bố sang PH-02, PH-01 (FR-15-044…047) |
| `portal-insight` | Spring Boot | Z3 | Bảng điều khiển, thống kê, nhật ký ứng dụng, thông báo từ PH-13, PH-02 (FR-15-048…052) |
| `portal-admin` | Spring Boot | Z3 | Quản trị cổng: nhận diện, tham số, duyệt tài khoản, nhật ký, đồng bộ, di trú (FR-15-056…062) |
| `portal-support` | Spring Boot | Z3 | Hỏi đáp, phiếu hỗ trợ, đánh giá |
| Keycloak | Realm `dh-{tenant}` (cán bộ) và `dh-dev` (nhà thầu, client sandbox) | Z6 | Đăng nhập, client sandbox |
| APISIX | Tuyến sandbox tĩnh `sandbox-api.{tenant}.datahub.gov.vn` (giả định) kèm `forward-auth` | Z1, Z2 | Chuyển lời gọi sandbox tới `portal-sandbox` sau khi `forward-auth` cho phép; không chuyển tiếp tới backend thử |

: Thành phần của PH-15

Luồng chính của phân hệ là thử API trên sandbox: nó đi qua nhiều thành phần nhất và chứa các điểm an toàn quan trọng (kiểm tra quyền, trao đổi token, kiểm tra mẫu dữ liệu cá nhân, hạn mức, ghi vết).

```{.mermaid caption="Trình tự thử API trên sandbox"}
sequenceDiagram
  autonumber
  actor D as Nhà phát triển
  participant B as BFF dh-portal
  participant T as portal-try
  participant K as Keycloak PH-12
  participant G as APISIX sandbox
  participant M as portal-sandbox (MOCK) hoặc backend thử qua portal-sandbox
  participant A as PH-13 kiểm toán
  D->>B: Bấm Gửi trên khung thử
  B->>T: POST /try/requests kèm cookie phiên
  T->>T: Kiểm tra quyền, điều khoản, hạn mức, mẫu dữ liệu cá nhân
  T->>K: Trao đổi token cho ứng dụng sandbox
  K-->>T: Token 5 phút thu hẹp phạm vi
  T->>G: Gọi tuyến sandbox kèm token và X-DH-Try-Id
  G->>T: forward-auth hỏi API-15-082
  T-->>G: Cho phép kèm hạn mức còn lại
  G->>M: Chuyển lời gọi tới portal-sandbox, chạy MOCK hoặc chuyển tiếp BACKEND
  M-->>G: Phản hồi
  G-->>T: Phản hồi
  T->>A: Ghi vết lượt thử
  T-->>B: Trạng thái, độ trễ, tiêu đề, thân đã che
  B-->>D: Hiển thị kết quả
```

Hình cho thấy cổng không bao giờ cầm bí mật của ứng dụng: nó xin token ngắn hạn thu hẹp phạm vi từ Keycloak (bước 4 đến 5), gateway tự hỏi lại cổng ở bước 8 để áp hạn mức và kiểm tra ứng dụng còn hiệu lực, và mọi lượt thử đều được ghi vết ở bước 12. Với thử production, chuỗi tương tự nhưng đích là tuyến production và có thêm điều kiện ở BR-15-019 đến BR-15-022.

### 2.5. Quy trình nghiệp vụ liên quan

PH-15 tham gia ba quy trình của D02-01. Bảng dưới nêu bước có PH-15 và các FR hiện thực.

| Quy trình | Bước có PH-15 | FR |
|---|---|---|
| BP-01 Kết nạp HTTT và cấp quyền sử dụng dịch vụ | Cán bộ nộp hồ sơ kết nạp từ cổng; được cấp môi trường sandbox; tìm API, thử; gửi đăng ký sử dụng; theo dõi trạng thái; xem tham chiếu thông tin xác thực production | 046, 025…032, 044, 045 |
| BP-02 Xây dựng và phát hành luồng tích hợp | Nhà phát triển đọc tài liệu và thử API của dịch vụ cần gọi trước khi dựng luồng ở PH-04 | 009…013, 035 |
| BP-09 Chuyển đổi từ hệ cũ | Di trú nội dung portal Gravitee; chạy song song hai cổng trong giai đoạn thay dần | 062 |

: Quy trình nghiệp vụ có PH-15

Vòng đời điển hình của một nhà thầu từ khi chưa có tài khoản đến khi gọi được API thật gồm sáu bước, đi qua bốn phân hệ. Sơ đồ dưới thể hiện thứ tự và nơi quyết định từng bước.

```{.mermaid caption="Hành trình của nhà thầu từ đăng ký đến gọi API thật"}
flowchart TB
  A["Tự đăng ký realm dh-dev và xác minh thư"] --> B["Quản trị cổng duyệt tài khoản"]
  B --> C["Tạo ứng dụng sandbox và nhận bí mật một lần"]
  C --> D["Đọc tài liệu và thử API sandbox"]
  D --> E["Cán bộ đầu mối gửi đăng ký sử dụng ở PH-02"]
  E --> F["Chủ dịch vụ và CA duyệt ở PH-02"]
  F --> G["PH-01 và PH-12 cấp thông tin xác thực production"]
  G --> H["Cổng hiện tham chiếu thông tin xác thực production"]
```

Sơ đồ cho thấy nhà thầu tự đi được bốn bước đầu mà không cần người trợ giúp; từ bước năm trở đi cần cán bộ đầu mối của đơn vị vì đăng ký sử dụng production luôn gắn với một HTTT đã kết nạp (BR-15-014).

### 2.6. Chức năng hệ cũ được phủ

Theo D00-03 §4.4, PH-15 phủ bốn mục `LGC` chính; mục thứ năm là phần nhà phát triển của một mục do PH-03, PH-13 làm chính. Hai mục cuối liên quan nhưng chủ yếu thuộc PH-01.

| Mã | Chức năng hệ cũ | Vai trò của PH-15 |
|---|---|---|
| LGC-APIM-006 | Publish, Unpublish API lên portal | PH-02 giữ cờ `portalPublished`; PH-15 phản ánh cờ này vào danh mục ở cổng |
| LGC-APIM-007 | Make Public: mọi người dùng xem được thông tin API | Ba mức hiển thị `TENANT`, `NATIONAL`, `PUBLIC` và chế độ công khai theo tenant |
| LGC-APIM-017 | Xem chi tiết đường dẫn sử dụng API (gateway URL và context path) | Khối "Cách gọi API" ở trang chi tiết và mẫu mã |
| LGC-IAM-006 | Lấy token bằng grant `password` (hướng dẫn lấy token) | Thay bằng hướng dẫn `client_credentials` và Authorization Code với PKCE; cổng cấp client sandbox |
| LGC-APIM-022 | Log request đến API của Application, xem chi tiết một log | Phần nhà phát triển: xem nhật ký gọi của ứng dụng mình, đã che dữ liệu |
| LGC-APIM-019, LGC-APIM-020 | Danh sách, tạo Application | Liên quan: Application trở thành HTTT có hồ sơ kết nạp ở PH-01; PH-15 chỉ có ứng dụng sandbox |

: Chức năng hệ cũ được PH-15 phủ

## 3. Tác nhân, vai trò và quyền

### 3.1. Tác nhân

Nhà phát triển ở cổng là hai nhóm người dùng khác nhau về nguồn gốc nhưng cùng vai trò `ROLE-DEVELOPER`: cán bộ CQNN đăng nhập SSO bằng realm tenant và nhà thầu tự đăng ký ở realm `dh-dev`. Bảng dưới mô tả tất cả tác nhân.

| Tác nhân | Loại | Mô tả | Tương tác chính |
|---|---|---|---|
| Khách ẩn danh | Người | Người chưa đăng nhập, chỉ ở tenant bật chế độ công khai | Xem danh mục và tài liệu của API `PUBLIC` |
| Cán bộ CQNN (DEV, `ROLE-DEVELOPER`) | Người | Cán bộ kỹ thuật đăng nhập SSO realm `dh-{tenant}` | Tìm, đọc, thử sandbox, tạo ứng dụng |
| Nhà thầu (DEV, tài khoản `dh-dev`) | Người | Người của đơn vị thầu, tự đăng ký và được duyệt | Như trên, chỉ sandbox, thấy ít API hơn (BR-15-004) |
| Cán bộ đầu mối (OR, `ROLE-ORG_REQUESTER`) | Người | Đại diện tổ chức ở tenant | Gửi đăng ký sử dụng, hồ sơ kết nạp từ cổng |
| Chủ dịch vụ (SV, `ROLE-SERVICE_OWNER`) | Người | Chủ API của tổ chức mình | Khai báo sandbox, viết hướng dẫn, xử lý hỗ trợ, đề xuất thử production |
| Biên tập viên nội dung | Người | Người giữ `PERM-15-content-write`: TA, CA, và SV (○, chỉ trang gắn API của tổ chức mình) | Soạn, sửa, gửi duyệt trang nội dung, nhập từ Git; không tự duyệt (BR-15-012) |
| Người duyệt dịch vụ (CA, `ROLE-CATALOG_APPROVER`) | Người | Người duyệt công bố ở PH-02 | Duyệt nội dung cổng, duyệt thử production |
| Quản trị tỉnh (TA, `ROLE-TENANT_ADMIN`) | Người | Quản trị Datahub của tỉnh | Quản trị cổng, duyệt tài khoản `dh-dev`, tham số |
| Cán bộ ATTT (SO, `ROLE-SECURITY_OFFICER`) | Người | Chuyên trách an toàn thông tin | Xem nhật ký truy cập và thử, khóa khi có sự cố |
| Kiểm toán viên (AU) | Người | Thanh tra, kiểm toán | Xem nhật ký |
| PH-02, PH-01, PH-03, PH-10, PH-12, PH-13, PH-18 | Hệ thống | Phân hệ liền kề | Nguồn danh mục; ủy thác kết nạp; tuyến sandbox; topic; định danh; kiểm toán và chỉ số; tham số |
| APISIX | Hệ thống | Gateway ở Z1, Z2 | Gọi `forward-auth` API-15-082 cho tuyến sandbox |
| Keycloak | Hệ thống | Realm `dh-{tenant}`, `dh-dev` | Đăng nhập, client sandbox, token exchange |
| Kho Git tài liệu | Hệ thống | Kho `docs/` của tổ chức | Nguồn nhập nội dung |

: Tác nhân của PH-15

### 3.2. Ma trận quyền

Ma trận dùng ký hiệu của D02-08 §3 (● có quyền, ○ chỉ đối tượng thuộc tổ chức của mình, — không có). Cả tám quyền `PERM-15-*` đã có ở D02-08 (năm quyền `content-write`, `content-publish`, `support`, `dev-approve`, `audit-read` được D02-08 bổ sung theo đề nghị của bản 0.1). Chỉ DEV (`ROLE-DEVELOPER`) giữ `PERM-15-try`: cán bộ đầu mối (OR, `ROLE-ORG_REQUESTER`) không thử API, chỉ gửi đăng ký sử dụng, kết nạp, công bố (FR-15-044…047). Hai quyền của DEV chỉ áp dụng cho ứng dụng được giao cho họ (BR-15-009). Xem danh mục, hướng dẫn, hỏi đáp, thông báo cá nhân dùng `PERM-02-read` và quyền tự phục vụ của người đã đăng nhập, không cần quyền riêng.

| Quyền | Ý nghĩa | DEV | OR | SV | CA | TA | SO | AU | PA |
|---|---|---|---|---|---|---|---|---|---|
| PERM-15-app | Tạo, quản lý ứng dụng sandbox, cấp, xoay, thu hồi thông tin xác thực sandbox, xem tham chiếu production của ứng dụng được giao | ● | — | — | — | — | — | — | — |
| PERM-15-try | Thử API trên sandbox; trên production khi dịch vụ đã bật và có đăng ký ACTIVE | ● | — | — | — | — | — | — | — |
| PERM-15-portal-admin | Quản trị nội dung cổng: nhận diện, tham số, đề xuất và duyệt thử production, đồng bộ lại, đối soát, di trú | — | — | — | ● | ● | — | — | — |
| PERM-15-content-write | Soạn, sửa, gửi duyệt trang nội dung; nhập từ Git; SV (○) còn dùng quyền này để xem, khai báo sandbox và đề xuất thử production của API thuộc tổ chức mình (FR-15-034, 042) | — | — | ○ | ● | ● | — | — | — |
| PERM-15-content-publish | Duyệt, đăng, gỡ trang nội dung | — | — | — | ● | ● | — | — | — |
| PERM-15-support | Xử lý hỏi đáp, phiếu hỗ trợ của dịch vụ | — | — | ○ | ● | ● | — | — | — |
| PERM-15-dev-approve | Duyệt, từ chối, khóa, mở khóa tài khoản `dh-dev` và ứng dụng sandbox | — | — | — | — | ● | ● | — | ● |
| PERM-15-audit-read | Xem nhật ký truy cập, thử và báo cáo sử dụng cổng | — | — | — | — | ● | ● | ● | ● |

: Ma trận quyền của PH-15

### 3.3. Tách nhiệm vụ và tài khoản máy

Cặp loại trừ của D02-08 §4 giữ nguyên: SV không đồng thời là CA (chủ dịch vụ không tự duyệt công bố). Ở cổng, nguyên tắc bốn mắt (FR-00-071) áp dụng cho từng đối tượng: người soạn trang không tự duyệt trang đó (BR-15-012), người đề xuất bật thử production không tự duyệt (BR-15-021). Nhà thầu `dh-dev` không bao giờ giữ vai trò duyệt hay quản trị.

Các thành phần gọi nhau bằng token dịch vụ, không dùng tài khoản người. PH-15 gọi PH-02 với scope `catalog:portal-read`; PH-15 gọi PH-13 với scope `metrics:portal-read` và ghi kiểm toán qua thư viện kiểm toán chung (SEC-60); APISIX gọi API-15-082 bằng mTLS mesh với danh tính SPIFFE của tuyến sandbox. Tài khoản Keycloak Admin mà `portal-dev` dùng bị giới hạn vào realm `dh-dev`, chỉ có quyền quản lý client có tiền tố `sbx-` và người dùng của realm này (SEC-20).

## 4. Khái niệm và mô hình nghiệp vụ

### 4.1. Khái niệm nghiệp vụ

PH-15 xoay quanh bốn khái niệm: bản sao danh mục (cái nhà phát triển đọc), ứng dụng sandbox (cái nhà phát triển sở hữu), thông tin xác thực (cái ứng dụng dùng để gọi) và lượt thử (cái nhà phát triển làm). Bảng dưới định nghĩa các khái niệm chưa có ở tài liệu chung.

| Khái niệm | Định nghĩa |
|---|---|
| Bản sao danh mục | Bản chỉ đọc của danh mục API từ PH-02 (`catalog:portal-read`), giữ trong `ph15_portal`; cổng không bao giờ sửa; mỗi mục kèm `sourceVersion` và thời điểm đồng bộ |
| Người xem | Một trong bốn hạng: `ANONYMOUS` (chưa đăng nhập), `TENANT_USER` (cán bộ đăng nhập realm tenant), `DEV_USER` (tài khoản `dh-dev` đã duyệt), `OTHER_TENANT_USER` (cán bộ tenant khác, xem qua mức `NATIONAL`); quyết định API nào hiện (Phụ lục A.2) |
| Ứng dụng sandbox | Phần mềm đang phát triển của một người hoặc một nhóm, có mã `appCode` bất biến trong tenant; mang thông tin xác thực sandbox; không phải HTTT và không có quyền gì ở production |
| Thông tin xác thực sandbox | Client `client_credentials` ở realm `dh-dev` (tên `sbx-{tenant}-{appCode}`) hoặc API key sandbox; sống ≤ 180 ngày; bí mật chỉ hiện một lần |
| Tham chiếu thông tin xác thực production | Thông tin chỉ đọc về định danh production của HTTT mà ứng dụng được giao: client ID, phương thức xác thực, dấu vân tay chứng thư, hạn, trạng thái; lấy từ PH-01, không có bí mật |
| Hồ sơ sandbox của dịch vụ | Khai báo của chủ dịch vụ cho từng phiên bản API: chế độ `MOCK` hoặc `BACKEND`, backend thử, chính sách ví dụ; do PH-15 giữ |
| Lượt thử | Một lời gọi thử từ khung thử, ở `SANDBOX` hoặc `PRODUCTION`; có `tryId`, ứng dụng, thao tác, kết quả, độ trễ |
| Trang nội dung | Đơn vị nội dung Markdown có mã `pageCode`, loại, ngôn ngữ, phiên bản, trạng thái; chỉ đăng sau khi duyệt bốn mắt |
| Thử production theo dịch vụ | Quyết định có thời hạn cho phép nhà phát triển có đăng ký ACTIVE thử một API ở production; mặc định tắt |
| Ủy thác | PH-15 chuyển yêu cầu sang PH-02 hoặc PH-01 nhân danh người dùng và đọc kết quả về hiển thị; không giữ quyết định |

: Khái niệm nghiệp vụ của PH-15

### 4.2. Thực thể

Bảng dưới liệt kê các thực thể mức logic; thuộc tính đầy đủ ở D03-03-PH15. Mọi bảng có `tenant_id`, `id`, `created_*`, `updated_*`, `version` và áp RLS theo `tenant_id` (ADR-003).

| Mã | Thực thể | Thuộc tính chính | Quan hệ |
|---|---|---|---|
| EN-15-01 | Mục danh mục | `apiCode`, `originTenantId` (tenant sở hữu API; khác tenant của cổng khi mục đến từ danh mục quốc gia, mức `NATIONAL`), tên, chủ quản, HTTT cung cấp, `dataClass`, `visibility`, `portalPublished`, trạng thái, `sourceVersion`, `syncedAt` | Có nhiều phiên bản đặc tả; nguồn PH-02 |
| EN-15-02 | Đặc tả đã nạp | `apiCode`, `versionNo`, loại (`OPENAPI`, `ASYNCAPI`), `contentHash`, mô hình đã phân tích, kích thước | Thuộc mục danh mục |
| EN-15-03 | Hồ sơ sandbox dịch vụ | `apiCode`, `versionNo`, `mode`, `backendUrl`, `examplePolicy`, `tryProduction` | Một cho mỗi phiên bản |
| EN-15-04 | Trang nội dung | `pageCode`, loại, ngôn ngữ, tiêu đề, trạng thái, phiên bản đang đăng, `apiCode` tùy chọn, thẻ | Có nhiều phiên bản trang |
| EN-15-05 | Phiên bản trang | `versionNo`, nội dung Markdown, trạng thái, người soạn, người gửi, người duyệt | Thuộc trang |
| EN-15-06 | Tài khoản nhà phát triển | `userId`, nguồn (`TENANT_SSO`, `DH_DEV`), thư, họ tên, tổ chức, số hợp đồng, trạng thái | Thuộc nhiều nhóm |
| EN-15-07 | Nhóm phát triển, thành viên | `teamCode`, tên, `userId`, vai trò nhóm | Sở hữu ứng dụng |
| EN-15-08 | Ứng dụng sandbox | `appCode`, tên, loại chủ (`USER`, `TEAM`), `linkedSystemCode` (mã HTTT ở PH-01 để xem tham chiếu production, FR-15-032; trống với nhà thầu), trạng thái, hạn mức riêng | Có thông tin xác thực, thành viên |
| EN-15-09 | Thông tin xác thực sandbox | `credentialId`, loại, tiền tố bí mật, trạng thái, hạn, `clientId` | Thuộc ứng dụng |
| EN-15-10 | Tham chiếu xác thực production | `systemCode`, `clientId`, phương thức, dấu vân tay, hạn, trạng thái | Chỉ đọc, bản sao từ PH-01 |
| EN-15-11 | Lượt thử | `tryId`, ứng dụng, người dùng, `apiCode`, `versionNo`, thao tác, môi trường, kết quả, độ trễ, `traceId` | Ghi vết sang PH-13 |
| EN-15-12 | Bộ sưu tập yêu cầu | `collectionId`, tên, danh sách yêu cầu mẫu | Của người dùng |
| EN-15-13 | Cho phép thử production | `apiCode`, trạng thái, thời hạn, `allowWrite`, người đề xuất, người duyệt | Một cho mỗi API |
| EN-15-14 | Theo dõi thông báo | `userId`, `apiCode`, kênh, loại | Nhận EVT-02-12 |
| EN-15-15 | Phiếu hỗ trợ | `ticketCode`, loại, trạng thái, `apiCode`, người gửi, người nhận | Có nhiều tin |
| EN-15-16 | Điều khoản sử dụng | `termsVersion`, nội dung, hiệu lực; chấp nhận theo người dùng | |
| EN-15-17 | Nhận diện và tham số cổng | tên cổng, logo, liên kết, chân trang, tham số `15.*` | Một cho mỗi tenant |
| EN-15-18 | Lần đồng bộ | `runId`, loại, trạng thái, số mục, lỗi | Phục vụ đối soát |

: Thực thể mức logic của PH-15

### 4.3. Máy trạng thái ứng dụng sandbox

Ứng dụng sandbox có ba trạng thái. `ACTIVE` là trạng thái làm việc. `SUSPENDED` do quản trị khóa khi nghi lạm dụng; ứng dụng không thử được và không xoay, cấp thông tin xác thực mới. `ARCHIVED` do chủ ứng dụng lưu trữ hoặc do hệ thống tự lưu trữ sau 180 ngày không dùng; thông tin xác thực bị thu hồi, khôi phục được trong 30 ngày.

```{.mermaid caption="Máy trạng thái ứng dụng sandbox"}
stateDiagram-v2
  [*] --> ACTIVE: Tạo ứng dụng
  ACTIVE --> SUSPENDED: Quản trị khóa
  SUSPENDED --> ACTIVE: Quản trị mở khóa
  ACTIVE --> ARCHIVED: Chủ lưu trữ hoặc 180 ngày không dùng
  SUSPENDED --> ARCHIVED: Chủ lưu trữ
  ARCHIVED --> ACTIVE: Khôi phục trong 30 ngày
  ARCHIVED --> [*]: Xóa sau 30 ngày
```

Sơ đồ cho thấy lưu trữ là lối ra duy nhất của người dùng và nó thu hồi mọi thông tin xác thực; khôi phục không khôi phục bí mật, người dùng phải cấp mới.

### 4.4. Máy trạng thái thông tin xác thực sandbox

Mỗi thông tin xác thực có bốn trạng thái. Khi xoay vòng, bản ghi cũ chuyển `ROTATING` (còn hiệu lực trong thời gian chuyển tiếp) và bản ghi mới `ACTIVE` được tạo; hết thời gian chuyển tiếp bản cũ thành `EXPIRED`.

```{.mermaid caption="Máy trạng thái thông tin xác thực sandbox"}
stateDiagram-v2
  [*] --> ACTIVE: Cấp
  ACTIVE --> ROTATING: Xoay vòng, bản mới ACTIVE
  ROTATING --> EXPIRED: Hết thời gian chuyển tiếp
  ROTATING --> REVOKED: Thu hồi
  ACTIVE --> REVOKED: Thu hồi hoặc lưu trữ ứng dụng
  ACTIVE --> EXPIRED: Hết hạn
  REVOKED --> [*]
  EXPIRED --> [*]
```

Sơ đồ cho thấy `REVOKED` và `EXPIRED` là trạng thái cuối, không khôi phục; muốn dùng lại phải cấp bản mới. Chỉ `ACTIVE` và `ROTATING` được `forward-auth` chấp nhận.

### 4.5. Máy trạng thái phiên bản trang nội dung

Vòng đời nằm ở phiên bản trang. Trang có trạng thái `DRAFT` (chưa đăng lần nào), `PUBLISHED` (có phiên bản đang đăng), `UNPUBLISHED` (đã gỡ), `ARCHIVED`. Sửa trang đã đăng tạo phiên bản nháp mới; bản đang đăng vẫn hiển thị cho đến khi bản mới được duyệt.

```{.mermaid caption="Máy trạng thái phiên bản trang nội dung"}
stateDiagram-v2
  [*] --> DRAFT: Soạn
  DRAFT --> IN_REVIEW: Gửi duyệt
  IN_REVIEW --> DRAFT: Người soạn rút lại
  IN_REVIEW --> REJECTED: Người duyệt từ chối
  REJECTED --> DRAFT: Soạn lại
  IN_REVIEW --> PUBLISHED: Người khác duyệt, đăng
  PUBLISHED --> SUPERSEDED: Phiên bản mới được đăng
  PUBLISHED --> UNPUBLISHED: Gỡ đăng
  UNPUBLISHED --> DRAFT: Soạn lại
  SUPERSEDED --> [*]
```

Sơ đồ cho thấy chỉ có một đường tới `PUBLISHED`: qua duyệt của người khác với người gửi (BR-15-012). Phiên bản `SUPERSEDED` và `REJECTED` giữ vĩnh viễn để so sánh và khôi phục (FR-15-016).

### 4.6. Máy trạng thái tài khoản nhà phát triển

Chỉ tài khoản `dh-dev` có vòng đời đầy đủ; cán bộ đăng nhập SSO có tài khoản được tạo khi đăng nhập lần đầu ở trạng thái `ACTIVE` và do realm tenant quản lý (khóa, vô hiệu ở PH-12).

```{.mermaid caption="Máy trạng thái tài khoản nhà phát triển dh-dev"}
stateDiagram-v2
  [*] --> PENDING_EMAIL: Tự đăng ký
  PENDING_EMAIL --> PENDING_APPROVAL: Xác minh thư trong 24 giờ
  PENDING_EMAIL --> EXPIRED: Quá 24 giờ
  PENDING_APPROVAL --> ACTIVE: Quản trị duyệt
  PENDING_APPROVAL --> REJECTED: Quản trị từ chối
  ACTIVE --> LOCKED: Quản trị khóa
  LOCKED --> ACTIVE: Quản trị mở khóa
  ACTIVE --> DISABLED: 45 ngày không hoạt động
  DISABLED --> PENDING_APPROVAL: Yêu cầu kích hoạt lại
  ACTIVE --> ERASED: Người dùng yêu cầu xóa
  REJECTED --> [*]
  EXPIRED --> [*]
  ERASED --> [*]
```

Sơ đồ cho thấy hai cổng chặn trước khi có quyền: xác minh thư (người đăng ký là chủ hộp thư) và duyệt của quản trị (người đăng ký thuộc đơn vị thầu có hợp đồng). Tài khoản bị vô hiệu sau 45 ngày theo SEC-27 phải qua duyệt lại, không tự kích hoạt.

## 5. Danh sách chức năng

PH-15 có 62 chức năng chia mười nhóm. Bảng dưới liệt kê toàn bộ chức năng kèm nhóm, mức ưu tiên, đợt phát hành và màn hình hiện thực; đặc tả chi tiết ở chương 6. Nhóm: A Danh mục và tìm kiếm; B Tài liệu API; C Hướng dẫn và nội dung; D Tài khoản nhà phát triển; E Ứng dụng và thông tin xác thực; F Sandbox và thử API; G Đăng ký và điểm vào nghiệp vụ; H Theo dõi; I Hỗ trợ; J Quản trị cổng. Mức: M bắt buộc, S nên có, C có thì tốt.

| Mã | Nhóm | Chức năng | Mức | Đợt | Màn hình |
|---|---|---|---|---|---|
| FR-15-001 | A | Đồng bộ danh mục dịch vụ từ PH-02 | M | Đợt 2 | UI-15-02, UI-15-27 |
| FR-15-002 | A | Áp mức hiển thị theo người xem | M | Đợt 2 | UI-15-02, UI-15-04 |
| FR-15-003 | A | Trang chủ cổng | M | Đợt 2 | UI-15-01 |
| FR-15-004 | A | Duyệt, lọc, sắp xếp danh mục dịch vụ | M | Đợt 2 | UI-15-02 |
| FR-15-005 | A | Tìm kiếm toàn văn tiếng Việt và gợi ý | M | Đợt 2 | UI-15-03 |
| FR-15-006 | A | Trang chi tiết dịch vụ, đường dẫn sử dụng và SLA | M | Đợt 2 | UI-15-04 |
| FR-15-007 | A | Hiển thị dịch vụ sự kiện | S | Đợt 2 | UI-15-02, UI-15-04 |
| FR-15-008 | A | Truy cập ẩn danh cổng công khai | M | Đợt 2 | UI-15-01, UI-15-02, UI-15-04 |
| FR-15-009 | B | Hiển thị tài liệu OpenAPI 3.1 | M | Đợt 2 | UI-15-05 |
| FR-15-010 | B | Hiển thị tài liệu AsyncAPI 3.0 | S | Đợt 2 | UI-15-05 |
| FR-15-011 | B | Chọn phiên bản, tải đặc tả, so sánh phiên bản | M | Đợt 2 | UI-15-05 |
| FR-15-012 | B | Sinh mẫu mã gọi API | M | Đợt 2 | UI-15-05 |
| FR-15-013 | B | Changelog, lộ trình ngừng dùng, banner DEPRECATED | M | Đợt 2 | UI-15-04, UI-15-05 |
| FR-15-014 | C | Soạn trang nội dung Markdown | M | Đợt 2 | UI-15-21 |
| FR-15-015 | C | Gửi duyệt, duyệt và đăng trang | M | Đợt 2 | UI-15-22 |
| FR-15-016 | C | Phiên bản trang, so sánh, khôi phục, gỡ đăng | S | Đợt 2 | UI-15-22 |
| FR-15-017 | C | Hiển thị trang nội dung | M | Đợt 2 | UI-15-07 |
| FR-15-018 | C | Nhập nội dung từ kho Git | S | Đợt 3 | UI-15-21, UI-15-27 |
| FR-15-019 | D | Đăng nhập SSO realm tenant | M | Đợt 2 | UI-15-08 |
| FR-15-020 | D | Tự đăng ký tài khoản dh-dev | M | Đợt 2 | UI-15-08 |
| FR-15-021 | D | Hồ sơ cá nhân và phiên đăng nhập | M | Đợt 2 | UI-15-09 |
| FR-15-022 | D | Nhóm phát triển | S | Đợt 2 | UI-15-09 |
| FR-15-023 | D | Chấp nhận điều khoản sử dụng có phiên bản | M | Đợt 2 | UI-15-09 |
| FR-15-024 | D | Vô hiệu hóa không hoạt động và xóa tài khoản | S | Đợt 2 | UI-15-09, UI-15-24 |
| FR-15-025 | E | Tạo ứng dụng sandbox | M | Đợt 2 | UI-15-11 |
| FR-15-026 | E | Xem, sửa, lưu trữ, khôi phục ứng dụng | M | Đợt 2 | UI-15-10, UI-15-12 |
| FR-15-027 | E | Cấp thông tin xác thực client_credentials sandbox | M | Đợt 2 | UI-15-13 |
| FR-15-028 | E | Cấp API key sandbox | M | Đợt 2 | UI-15-13 |
| FR-15-029 | E | Hiển thị bí mật đúng một lần | M | Đợt 2 | UI-15-13 |
| FR-15-030 | E | Xoay vòng thông tin xác thực | M | Đợt 2 | UI-15-13 |
| FR-15-031 | E | Thu hồi và hết hạn thông tin xác thực | M | Đợt 2 | UI-15-13 |
| FR-15-032 | E | Xem tham chiếu thông tin xác thực production | M | Đợt 2 | UI-15-13 |
| FR-15-033 | E | Giao ứng dụng cho thành viên | S | Đợt 2 | UI-15-12 |
| FR-15-034 | F | Khai báo sandbox của dịch vụ | M | Đợt 2 | UI-15-23 |
| FR-15-035 | F | Thử API trên sandbox | M | Đợt 2 | UI-15-06 |
| FR-15-036 | F | Chế độ sandbox MOCK | M | Đợt 2 | UI-15-06 |
| FR-15-037 | F | Chế độ sandbox BACKEND | M | Đợt 2 | UI-15-06 |
| FR-15-038 | F | Dữ liệu mẫu tổng hợp và chặn dữ liệu cá nhân thật | M | Đợt 2 | UI-15-06 |
| FR-15-039 | F | Hạn mức sandbox | M | Đợt 2 | UI-15-06 |
| FR-15-040 | F | Lịch sử thử và bộ sưu tập yêu cầu | S | Đợt 2 | UI-15-14 |
| FR-15-041 | F | Xuất Postman, Bruno, HTTP | C | Đợt 3 | UI-15-14 |
| FR-15-042 | F | Bật, tắt thử production theo dịch vụ | M | Đợt 2 | UI-15-23 |
| FR-15-043 | F | Thử API trên production | M | Đợt 2 | UI-15-06 |
| FR-15-044 | G | Gửi đăng ký sử dụng API production | M | Đợt 2 | UI-15-15 |
| FR-15-045 | G | Theo dõi đăng ký sử dụng | M | Đợt 2 | UI-15-15 |
| FR-15-046 | G | Điểm vào kết nạp HTTT (F-01) | M | Đợt 2 | UI-15-16 |
| FR-15-047 | G | Điểm vào công bố API (F-02) | M | Đợt 2 | UI-15-17 |
| FR-15-048 | H | Bảng điều khiển cá nhân | S | Đợt 2 | UI-15-18 |
| FR-15-049 | H | Thống kê lượt gọi và lỗi theo ứng dụng | M | Đợt 2 | UI-15-12 |
| FR-15-050 | H | Nhật ký gọi của ứng dụng đã che dữ liệu | S | Đợt 2 | UI-15-12 |
| FR-15-051 | H | Đăng ký nhận thông báo thay đổi API | M | Đợt 2 | UI-15-19 |
| FR-15-052 | H | Hộp thông báo | M | Đợt 2 | UI-15-19 |
| FR-15-053 | I | Hỏi đáp, báo lỗi tài liệu, đánh giá trang | C | Đợt 3 | UI-15-04, UI-15-07, UI-15-20 |
| FR-15-054 | I | Gửi yêu cầu hỗ trợ cho chủ dịch vụ | M | Đợt 2 | UI-15-20 |
| FR-15-055 | I | Xử lý yêu cầu hỗ trợ | S | Đợt 2 | UI-15-28 |
| FR-15-056 | J | Cấu hình nhận diện cổng theo tenant | M | Đợt 2 | UI-15-25 |
| FR-15-057 | J | Tham số cổng | M | Đợt 2 | UI-15-25 |
| FR-15-058 | J | Duyệt tài khoản dh-dev | M | Đợt 2 | UI-15-24 |
| FR-15-059 | J | Khóa, mở khóa tài khoản và ứng dụng | M | Đợt 2 | UI-15-24 |
| FR-15-060 | J | Nhật ký truy cập, thử và báo cáo sử dụng cổng | M | Đợt 2 | UI-15-26 |
| FR-15-061 | J | Đồng bộ lại và đối soát danh mục với PH-02 | S | Đợt 2 | UI-15-27 |
| FR-15-062 | J | Di trú nội dung portal hệ cũ | S | Đợt 2 | UI-15-27 |

: Danh sách chức năng của PH-15

## 6. Đặc tả chi tiết chức năng

### 6.1. Cách đọc bảng đặc tả

Mỗi chức năng được đặc tả bằng một khối hai cột gồm 17 mục cố định theo chuẩn kết hợp của K-TRINH-BAY §4: 12 trường kỹ thuật của mẫu FR ở D00-01 §4.3 (đầu vào, đầu ra, mã lỗi theo bước, sự kiện, kiểm toán) để kỹ sư và kiểm thử viên dùng ngay, và các mục thuyết minh (mục đích, kích hoạt, luồng thay thế, câu thông báo, kết quả, màn hình) để hội đồng và người dùng nghiệp vụ đọc.

| Mục | Nội dung | Nguồn |
|---|---|---|
| Mục đích | Chức năng giúp ai làm được việc gì, vì sao cần | Mẫu thuyết minh |
| Tác nhân, quyền | Vai trò thực hiện và `PERM` cần có | D00-01 §4.3 |
| Mức ưu tiên, đợt | M, S, C; đợt phát hành | D00-01 §4.3 |
| Truy vết | REQ, LGC, SRS cũ, ADR | D00-01 §4.3 |
| Tiền điều kiện | Trạng thái phải đúng trước khi chạy | D00-01 §4.3 |
| Kích hoạt | Thao tác hoặc sự kiện khởi động | Mẫu thuyết minh |
| Đầu vào | Tham số, trường nhập (bảng riêng khi từ 5 trường) | D00-01 §4.3 |
| Luồng xử lý chính | Các bước đánh số; bước kiểm tra ghi mã lỗi | Cả hai |
| Luồng thay thế | Nhánh hợp lệ khác | Mẫu thuyết minh |
| Luồng ngoại lệ | Điều kiện, mã `ERR`, HTTP, câu thông báo | Cả hai |
| Đầu ra | Mã HTTP, trường trả về | D00-01 §4.3 |
| Kết quả | Điều người dùng nhận được | Mẫu thuyết minh |
| Hậu điều kiện | Trạng thái dữ liệu sau khi xong | D00-01 §4.3 |
| Sự kiện phát ra | `EVT` nếu có | D00-01 §4.3 |
| Kiểm toán | Có ghi kiểm toán không, trường nào | D00-01 §4.3 |
| Quy tắc nghiệp vụ | Mã `BR` (chương 7) | Cả hai |
| Màn hình, API | `UI` và `API` hiện thực | Mẫu thuyết minh |

: Các mục của bảng đặc tả chức năng

Ví dụ dùng tenant `T68`, HTTT cung cấp `HT-TUPHAP` với API `tra-cuu-ho-tich` (khớp PH-02), HTTT khai thác `HT-DATDAI`, nhà phát triển `nguyen.van.an` (giả định). Mọi API của cổng có tiền tố `/api/portal/v1` qua BFF; phần ẩn danh `/api/portal/v1/public`; thử API `/api/portal/v1/try`. Câu thông báo đã chốt dùng chung ở mục 9.2. Sơ đồ dưới cho thấy mười nhóm chức năng và quan hệ phụ thuộc chính giữa chúng.

```{.mermaid caption="Mười nhóm chức năng của PH-15"}
flowchart TB
  A["A Danh mục, tìm kiếm"] --> B["B Tài liệu API"]
  C["C Hướng dẫn, nội dung"] --> A
  D["D Tài khoản nhà phát triển"] --> E["E Ứng dụng, thông tin xác thực"]
  E --> F["F Sandbox, thử API"]
  B --> F
  F --> G["G Đăng ký, điểm vào nghiệp vụ"]
  G --> H["H Theo dõi"]
  E --> H
  F --> I["I Hỗ trợ"]
  J["J Quản trị cổng"] --> D
  J --> C
  J --> F
  J --> A
```

Nhóm A, B, C là phần đọc (có thể ẩn danh), D, E, F là phần tự phục vụ cần đăng nhập, G và H nối cổng với nghiệp vụ thật, I là kênh hỗ trợ, J là nơi quản trị viên cấu hình và kiểm soát tất cả.

### 6.2. Nhóm A · Danh mục, tìm kiếm và truy cập

Nhóm A đưa danh mục API của PH-02 đến đúng người xem. Cổng giữ một bản sao chỉ đọc để trang tải nhanh và vẫn xem được khi PH-02 bảo trì. Sơ đồ dưới là trình tự đồng bộ danh mục: sự kiện báo "có thay đổi", cổng kéo phần thay đổi, phân tích đặc tả, cập nhật chỉ mục.

```{.mermaid caption="Trình tự đồng bộ danh mục từ PH-02"}
sequenceDiagram
  autonumber
  participant P2 as PH-02 danh mục
  participant K as Kafka
  participant C as portal-catalog
  participant D as pg-core ph15_portal
  participant S as Chỉ mục tìm kiếm
  P2->>K: Phát EVT-02-05 khi phiên bản được công bố
  K->>C: Giao sự kiện vào inbox
  C->>C: Loại trùng theo mã sự kiện, xếp hàng theo apiCode
  C->>P2: GET catalog portal-read updatedSince mốc trước
  P2-->>C: items, removed, ETag, sourceVersion
  C->>D: Upsert mục danh mục, đánh dấu ẩn mục đã gỡ
  C->>P2: Tải đặc tả đã gộp của phiên bản mới
  P2-->>C: Tệp OpenAPI hoặc AsyncAPI
  C->>D: Ghi đặc tả đã phân tích và băm nội dung
  C->>S: Cập nhật chỉ mục theo mức hiển thị
  C->>C: Ghi mốc đồng bộ, vô hiệu bộ đệm trang
```

Sơ đồ cho thấy sự kiện chỉ là tín hiệu; dữ liệu luôn được kéo từ PH-02 theo mốc `updatedSince`, nên mất sự kiện chỉ làm chậm tới lần kéo bù kế tiếp chứ không làm sai dữ liệu.

#### FR-15-001 · Đồng bộ danh mục dịch vụ từ PH-02

::: dac-ta
**Mục đích.** Giữ cho bản sao danh mục ở cổng khớp với PH-02 trong vài chục giây, để nhà phát triển luôn thấy API và đặc tả đang phát hành, không phải đợi nhân viên cập nhật tay như ở portal hệ cũ.

**Tác nhân, quyền.** Hệ thống (`portal-catalog`, scope `catalog:portal-read`); TA, CA xem trạng thái (`PERM-15-portal-admin`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-006; SRS cũ FR-15-001, SRS cũ FR-15-005; FR-02-059, FR-02-004, FR-02-041.

**Tiền điều kiện.** PH-02 khả dụng; tài khoản dịch vụ của `portal-catalog` đã được cấp scope khi triển khai.

**Kích hoạt.** Nhận EVT-02-01, 02, 03, 05, 06, 08, 10 hoặc 12; đến lịch kéo bù mỗi `15.sync.interval-seconds`; khởi động lần đầu; quản trị bấm "Đồng bộ lại" (FR-15-061).

**Đầu vào.** `updatedSince` (T-TS, mốc đồng bộ thành công gần nhất trừ 60 giây), `page`, `size`; tiêu đề `If-None-Match`.

**Luồng xử lý chính.**

1. Hệ thống nhận sự kiện, loại trùng theo mã sự kiện (inbox, ADR-042) và xếp hàng theo `apiCode` để xử lý tuần tự từng API.
2. Hệ thống gọi giao diện nội bộ của PH-02 (API-02-081) với `updatedSince`; phân trang tới hết; lần nạp đầu để trống `updatedSince`.
3. Với mỗi mục trong `items[]` có `sourceVersion` mới hơn bản đang giữ, hệ thống ghi đè mục danh mục; mục trong `removed[]` bị đánh dấu ẩn (xóa mềm).
4. Với phiên bản mới hoặc đổi, hệ thống tải đặc tả đã gộp, tính `contentHash`, phân tích thành mô hình thao tác và lưu; đặc tả không phân tích được thì giữ bản cũ và ghi cảnh báo (ERR-15-009).
5. Hệ thống cập nhật chỉ mục tìm kiếm theo mức hiển thị (FR-15-005) và vô hiệu bộ đệm của trang chi tiết.
6. Hệ thống ghi mốc đồng bộ và độ trễ `dh_portal_sync_lag_seconds`; khi trạng thái đồng bộ đổi (`IDLE`, `RUNNING`, `FAILED`, `STALE`) thì phát EVT-15-14.

**Luồng thay thế.** PH-02 trả `304` (ETag khớp): hệ thống chỉ ghi mốc kiểm tra. Mất sự kiện: lần kéo bù kế tiếp bắt kịp trong tối đa 5 phút (NFR-15-004).

**Luồng ngoại lệ.**

- PH-02 lỗi `5xx` hoặc quá thời gian: giữ bản sao, thử lại lùi mũ 5, 30, 120 giây; quá `15.sync.stale-seconds` thì trạng thái `STALE` và hiện banner "Danh mục có thể chưa phản ánh thay đổi mới nhất."
- Chưa từng nạp xong: ERR-15-008 (503); "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút." (chi tiết riêng ở `detail`: Danh mục đang được chuẩn bị. Vui lòng quay lại sau ít phút)
- Đặc tả hỏng: ERR-15-009 (chỉ ghi nhật ký); trang tài liệu hiện "Đặc tả của phiên bản này tạm thời chưa hiển thị được."

**Đầu ra.** Nội bộ; API-15-009 trả `state`, `lastSyncAt`, `lagSeconds`, `itemCount`.

**Kết quả.** Nhà phát triển thấy danh mục và tài liệu đúng với bản đang phát hành, kèm cảnh báo nếu dữ liệu chậm.

**Hậu điều kiện.** Bản sao khớp `sourceVersion` mới nhất của PH-02; chỉ mục tìm kiếm cập nhật.

**Sự kiện phát ra.** EVT-15-14 khi trạng thái đồng bộ đổi.

**Kiểm toán.** Không với lần đồng bộ tự động (nhật ký vận hành); có với lần quản trị bấm đồng bộ lại.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002; BR-15-033.

**Màn hình, API.** UI-15-02 (banner), UI-15-27; API-15-009; API-02-081 của PH-02.
:::

#### FR-15-002 · Áp mức hiển thị theo người xem

::: dac-ta
**Mục đích.** Bảo đảm mỗi người chỉ thấy đúng những API mà mức hiển thị `TENANT`, `NATIONAL`, `PUBLIC` của PH-02 cho phép họ thấy, thay cho cờ "Make Public" một chiều ở hệ cũ.

**Tác nhân, quyền.** Mọi người xem; hệ thống áp dụng.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-007; SRS cũ FR-15-002, SRS cũ FR-15-006; FR-02-041; CMP-LAW-03.

**Tiền điều kiện.** Bản sao danh mục đã nạp (FR-15-001).

**Kích hoạt.** Mọi truy vấn danh mục, tìm kiếm, tài liệu, thử.

**Đầu vào.** Hạng người xem suy ra từ phiên BFF (hoặc từ tên miền khi ẩn danh); không nhận từ tham số.

**Luồng xử lý chính.**

1. Hệ thống xác định tenant từ tên miền cổng (BR-15-003) và hạng người xem: `ANONYMOUS`, `TENANT_USER`, `DEV_USER`, `OTHER_TENANT_USER`.
2. Hệ thống chỉ đưa vào tập kết quả những mục có `portalPublished = true`, trạng thái `PUBLISHED`, `DEPRECATED` (và `SUSPENDED` hiển thị nhãn "Tạm ngừng", không thử được).
3. Hệ thống lọc theo bảng dưới; với `DEV_USER` bỏ thêm mọi API `dataClass = SENSITIVE` (BR-15-004).
4. Mọi thao tác trên một API ngoài tập được phép (chi tiết, tài liệu, thử, tải đặc tả) trả như API không tồn tại, cùng thân phản hồi (BR-15-002).
5. Chỉ mục tìm kiếm áp cùng bộ lọc ở mức truy vấn để tiêu đề API không lộ qua gợi ý.

**Luồng thay thế.** Người dùng đăng nhập giữa chừng: bộ lọc tính lại theo hạng mới, trang được nạp lại.

**Luồng ngoại lệ.**

- API ngoài tầm nhìn: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Tenant chưa bật chế độ công khai mà khách ẩn danh vào trang danh mục: chuyển tới trang đăng nhập, không hiện lỗi.

**Đầu ra.** Tập mục danh mục đã lọc; `404` cho mục ngoài tầm.

**Kết quả.** Người dùng chỉ thấy dịch vụ mà họ được phép biết, không lộ sự tồn tại của dịch vụ khác.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (từ chối ghi chỉ số `dh_portal_visibility_denied_total`).

**Quy tắc nghiệp vụ.** BR-15-002; BR-15-004; BR-15-005; BR-15-006.

**Màn hình, API.** UI-15-02, UI-15-04; API-15-003, API-15-004, API-15-005, API-15-007.
:::

| Hạng người xem | `PUBLIC` | `NATIONAL` | `TENANT` | Ghi chú |
|---|---|---|---|---|
| `ANONYMOUS` | Có, khi `15.public.enabled` bật | Không | Không | Chỉ API `dataClass = PUBLIC` |
| `DEV_USER` | Có | Có, của tenant được cấp | Có, của tenant được cấp | Bỏ API `SENSITIVE` |
| `TENANT_USER` | Có | Có | Có | Mọi `dataClass` theo `PERM-02-read` |
| `OTHER_TENANT_USER` | Có | Có, qua danh mục quốc gia | Không | Xem ở cổng của tenant sở hữu |

: Mức hiển thị theo hạng người xem

#### FR-15-003 · Trang chủ cổng

::: dac-ta
**Mục đích.** Đưa nhà phát triển tới việc họ cần trong một màn hình: tìm API, bắt đầu nhanh, xem thông báo mới.

**Tác nhân, quyền.** Mọi người xem (khách ẩn danh khi tenant bật công khai).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-002, SRS cũ FR-15-016.

**Tiền điều kiện.** Không.

**Kích hoạt.** Người dùng mở `/`.

**Đầu vào.** Không có; ngôn ngữ từ tùy chọn người dùng.

**Luồng xử lý chính.**

1. Hệ thống dựng khối tìm kiếm lớn (FR-15-005) và các lối vào "Danh mục dịch vụ", "Hướng dẫn", "Ứng dụng của tôi".
2. Hệ thống lấy tối đa 8 API nổi bật theo ba nhóm: mới công bố 30 ngày, nhiều người xem nhất 30 ngày, theo lĩnh vực; đều qua bộ lọc FR-15-002.
3. Hệ thống hiện trang `QUICKSTART` được ghim và tối đa 3 thông báo `ANNOUNCEMENT` còn hiệu lực (FR-15-017).
4. Người đã đăng nhập thấy thêm thẻ "Việc đang làm": ứng dụng gần đây, đăng ký chờ duyệt, thông báo chưa đọc.
5. Hệ thống hiển thị tên, logo, liên kết theo nhận diện tenant (FR-15-056) và trạng thái đồng bộ nếu `STALE`.

**Luồng thay thế.** Tenant chưa có API nào ở cổng: hiện hướng dẫn liên hệ đầu mối và lối vào "Công bố API" (FR-15-047) cho SV.

**Luồng ngoại lệ.**

- Bản sao danh mục chưa sẵn sàng: ERR-15-008 (503); "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút." (chi tiết riêng ở `detail`: Danh mục đang được chuẩn bị. Vui lòng quay lại sau ít phút) Các khối nội dung vẫn hiển thị.

**Đầu ra.** `200`; `featured[]`, `quickstart`, `announcements[]`, `myWork` (nếu đăng nhập); `Cache-Control: public, max-age=300` cho khách ẩn danh.

**Kết quả.** Trang chủ tải nhanh, dẫn người dùng tới đúng việc.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-002; BR-15-005; BR-15-032.

**Màn hình, API.** UI-15-01; API-15-001, API-15-002, API-15-139.
:::

#### FR-15-004 · Duyệt, lọc, sắp xếp danh mục dịch vụ

::: dac-ta
**Mục đích.** Cho nhà phát triển duyệt toàn bộ API được phép xem, thu hẹp theo lĩnh vực, chủ quản, kiểu xác thực, trạng thái; thay cho danh sách API phẳng ở hệ cũ.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-006; SRS cũ FR-15-002; FR-00-020…023.

**Tiền điều kiện.** Bản sao danh mục đã nạp.

**Kích hoạt.** Người dùng mở `/dich-vu` hoặc đổi bộ lọc.

**Đầu vào.** Query `q`, `linh-vuc`, `chu-quan`, `xac-thuc` (`OAUTH2`, `MTLS`, `API_KEY`), `loai` (`api`, `su-kien`), `trang-thai`, `da-ngung` (T-BOOL), `sap-xep` (`ten`, `moi-nhat`, `pho-bien`), `trang`, `co`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra tham số theo miền ở Phụ lục A.4; sai thì ERR-15-003.
2. Hệ thống truy vấn bản sao theo bộ lọc, áp mức hiển thị (FR-15-002), mặc định ẩn mục `RETIRED` và `SUSPENDED`; bật `da-ngung` thì hiện thêm mục đã ngừng.
3. Hệ thống tính số lượng theo từng nhóm lọc (facet) trên tập đã được phép thấy.
4. Hệ thống trả danh sách phân trang gồm mã, tên, chủ quản, phiên bản mới nhất, trạng thái, kiểu xác thực, SLA tóm tắt, nhãn dữ liệu.
5. Giao diện hiển thị dạng lưới thẻ hoặc bảng, nhãn màu: `PUBLISHED` xanh, `DEPRECATED` vàng, `SUSPENDED` xám; trạng thái bộ lọc giữ trên URL (FR-00-022).

**Luồng thay thế.** Người dùng chọn "Dịch vụ sự kiện": hiển thị mục `kind = EVENT` (FR-15-007).

**Luồng ngoại lệ.**

- Giá trị lọc sai miền: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Bộ lọc {tên} không hợp lệ)
- Không có kết quả: không phải lỗi; "Không có dịch vụ nào khớp. Thử bỏ bớt bộ lọc."
- `co` ngoài 10, 20, 50, 100: ERR-15-003.

**Đầu ra.** `200`; `items[]`, `facets`, `page`, `size`, `totalElements`.

**Kết quả.** Người dùng tìm được API theo nhu cầu trong vài thao tác.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-002; BR-15-006.

**Màn hình, API.** UI-15-02; API-15-005, API-15-006.
:::

#### FR-15-005 · Tìm kiếm toàn văn tiếng Việt và gợi ý

::: dac-ta
**Mục đích.** Cho nhà phát triển gõ "ho tich" mà ra "Tra cứu hộ tích" và tìm được cả API, bài hướng dẫn, dịch vụ sự kiện trong một ô tìm.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-011; FR-00-020; D03-01 (tìm kiếm tiếng Việt).

**Tiền điều kiện.** Chỉ mục đã dựng (hoặc dự phòng PostgreSQL).

**Kích hoạt.** Người dùng gõ vào ô tìm (gợi ý) hoặc nhấn Enter, `Ctrl+K`.

**Đầu vào.** `q` (T-TEXT, 1…200 ký tự), `loai` (`api`, `huong-dan`, `su-kien`), `trang`, `co`.

**Luồng xử lý chính.**

1. Hệ thống chuẩn hóa `q`: cắt khoảng trắng, hạ chữ thường, bỏ dấu để so khớp; giữ bản có dấu để tô sáng.
2. Hệ thống tìm trên mã, tên, mô tả, thẻ của API; tiêu đề và nội dung của trang đã đăng; tên topic; xếp hạng: khớp mã chính xác, rồi tên, thẻ, mô tả, nội dung.
3. Hệ thống áp bộ lọc người xem ở mức truy vấn (FR-15-002) và ngôn ngữ trang.
4. Gợi ý (từ 2 ký tự) trả tối đa 8 mục sau ≤ 200 ms; kết quả đầy đủ có đoạn trích tô sáng.
5. Khi OpenSearch không trả lời, hệ thống chuyển sang PostgreSQL FTS với `unaccent` và hiện banner nhẹ "Đang dùng tìm kiếm cơ bản."

**Luồng thay thế.** Ẩn danh: chỉ tìm trong API `PUBLIC` và trang công khai, tần suất giới hạn theo IP (FR-15-008).

**Luồng ngoại lệ.**

- `q` dài quá 200 ký tự hoặc rỗng khi `Enter`: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Từ khóa cần từ 1 đến 200 ký tự)
- Vượt tần suất: ERR-15-007 (429); "Thao tác quá nhanh. Thử lại sau {n} giây."

**Đầu ra.** `200`; `results[]` (loại, mã, tiêu đề, đoạn trích), `page`, `size`, `totalElements`; gợi ý: `suggestions[]`.

**Kết quả.** Kết quả liên quan lên đầu, không lộ dịch vụ ngoài tầm.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (từ khóa không ghi cùng định danh người dùng).

**Quy tắc nghiệp vụ.** BR-15-002; BR-15-005; BR-15-006.

**Màn hình, API.** UI-15-03; API-15-010, API-15-011, API-15-012.
:::

#### FR-15-006 · Trang chi tiết dịch vụ, đường dẫn sử dụng và SLA

::: dac-ta
**Mục đích.** Gom mọi điều cần biết về một API vào một trang: mô tả, chủ quản, phiên bản, gói, cam kết chất lượng, cách gọi; thay cho việc ghép "địa chỉ gateway cộng context path" bằng tay.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-017; LGC-IAM-006; SRS cũ FR-15-003, SRS cũ FR-15-006; FR-02-005, FR-02-055.

**Tiền điều kiện.** API nằm trong tập người xem được phép thấy.

**Kích hoạt.** Người dùng mở `/dich-vu/{ma-api}`.

**Đầu vào.** `apiCode` (đường dẫn); `phien-ban` (query, mặc định phiên bản `PUBLISHED` mới nhất).

**Luồng xử lý chính.**

1. Hệ thống nạp mục danh mục và phiên bản được chọn; không thấy thì ERR-15-001.
2. Hệ thống hiển thị: mô tả nghiệp vụ, đơn vị chủ quản, HTTT cung cấp, nhãn dữ liệu, trạng thái vòng đời (chỉ đọc), danh sách phiên bản và gói (kiểu xác thực, hạn mức).
3. Hệ thống hiển thị cam kết SLA công khai của PH-02: sẵn sàng, độ trễ, giờ phục vụ, và đầu mối kỹ thuật (chỉ với người đã đăng nhập).
4. Khối "Cách gọi API": địa chỉ gốc production, địa chỉ lấy token của realm, phạm vi cần xin, tiêu đề bắt buộc, mẫu `curl` với giá trị giữ chỗ (lấy qua API-02-006 của PH-02, bộ đệm 5 phút); với người không có quyền, chỉ hiện địa chỉ sandbox.
5. Hệ thống hiện các nút theo ngữ cảnh: "Đọc tài liệu", "Thử API", "Đăng ký sử dụng" (người có quyền, FR-15-044), "Theo dõi thay đổi" (FR-15-051), "Hỏi đáp" (FR-15-053).
6. Với chủ dịch vụ và TA, hệ thống hiện cảnh báo "Thiếu thông tin công bố" nếu mô tả, SLA hoặc đầu mối còn trống và liên kết sang PH-02 để bổ sung; không sửa ở cổng.

**Luồng thay thế.** `DEPRECATED`: banner lộ trình ngừng (FR-15-013). `SUSPENDED`: nhãn "Tạm ngừng", ẩn nút Thử API.

**Luồng ngoại lệ.**

- Không thấy hoặc ngoài tầm: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Phiên bản đã ngừng hẳn: ERR-15-038 (410); "Phiên bản này đã ngừng cung cấp." (chi tiết riêng ở `detail`: Phiên bản này đã ngừng hoạt động. Xem phiên bản mới hơn)
- PH-02 không trả được mẫu gọi: khối "Cách gọi API" hiện "Chưa tải được mẫu gọi. Thử lại." Phần còn lại vẫn hiển thị.

**Đầu ra.** `200`; mục chi tiết, `versions[]`, `plans[]`, `sla`, `usage` (`baseUrl`, `tokenUrl`, `scopes[]`, `samples[]`).

**Kết quả.** Nhà phát triển biết cách gọi API và điều kiện sử dụng mà không phải hỏi ai.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002; BR-15-006; BR-15-033.

**Màn hình, API.** UI-15-04; API-15-007, API-15-008.
:::

#### FR-15-007 · Hiển thị dịch vụ sự kiện

::: dac-ta
**Mục đích.** Cho nhà phát triển thấy cả topic sự kiện của tỉnh cùng chỗ với API và biết cách đăng ký nhận ở PH-10.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; FR-02-009; PH-10.

**Tiền điều kiện.** PH-02 đã đưa mục loại `EVENT` vào danh mục (từ EVT-10-01).

**Kích hoạt.** Người dùng chọn "Dịch vụ sự kiện" ở `/dich-vu` hoặc mở `/su-kien/{ma-topic}`.

**Đầu vào.** `topicName` (đường dẫn), bộ lọc như FR-15-004.

**Luồng xử lý chính.**

1. Hệ thống lấy các mục `kind = EVENT` từ bản sao danh mục, áp FR-15-002.
2. Hệ thống hiển thị tên topic, mô tả, trạng thái, nhãn dữ liệu, HTTT phát, lược đồ sự kiện (AsyncAPI, FR-15-010).
3. Nút "Đăng ký nhận ở phân hệ Sự kiện" mở liên kết sang PH-10; cổng không đăng ký thay.
4. Khi mục chuyển `DEPRECATED` hoặc `RETIRED`, cổng hiện banner như FR-15-013.

**Luồng thay thế.** Không có.

**Luồng ngoại lệ.**

- Topic ngoài tầm: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Chưa tải được lược đồ: ERR-15-009 ghi nhật ký; "Lược đồ sự kiện tạm thời chưa hiển thị được."

**Đầu ra.** `200`; mục sự kiện gồm `topicName`, mô tả, `dataClass`, HTTT phát, liên kết PH-10.

**Kết quả.** Nhà phát triển biết tỉnh có những sự kiện nào để nhận.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002.

**Màn hình, API.** UI-15-02, UI-15-04; API-15-013, API-15-014.
:::

#### FR-15-008 · Truy cập ẩn danh cổng công khai

::: dac-ta
**Mục đích.** Cho tenant bật cổng công khai để bất kỳ ai, kể cả nhà thầu chưa có tài khoản, đọc được danh mục và tài liệu của API đã được chủ dịch vụ đặt mức `PUBLIC`, đúng tinh thần công khai thông tin dịch vụ.

**Tác nhân, quyền.** Khách ẩn danh; TA bật tắt (FR-15-057).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-007; SRS cũ FR-15-006; CMP-LAW-03.

**Tiền điều kiện.** `15.public.enabled = true`; API có `visibility = PUBLIC`, `dataClass = PUBLIC`, `portalPublished = true`.

**Kích hoạt.** Truy cập `/public/...` hoặc trang cổng khi chưa đăng nhập.

**Đầu vào.** Tên miền cổng; các tham số như FR-15-004, FR-15-005.

**Luồng xử lý chính.**

1. Hệ thống ánh xạ tên miền sang tenant; tên miền lạ trả ERR-15-001.
2. Hệ thống kiểm tra `15.public.enabled`; tắt thì giao diện chuyển tới đăng nhập, còn API `/public/*` trả ERR-15-001 (404) để không lộ việc cổng công khai đang tắt.
3. Hệ thống chỉ phục vụ API `PUBLIC` và trang nội dung có `audience = PUBLIC`; không hiện đầu mối, địa chỉ nội bộ, danh sách gói có hạn mức riêng.
4. Hệ thống áp giới hạn `15.public.rate-limit-per-minute` theo IP và chống thu thập hàng loạt: phản hồi thêm `Cache-Control: public, max-age=300`.
5. Thao tác cần đăng nhập (thử, tạo ứng dụng, đăng ký, hỏi đáp) hiện lời mời đăng nhập hoặc đăng ký.

**Luồng thay thế.** Người dùng đã đăng nhập vào đường dẫn `/public`: chuyển về đường dẫn thường.

**Luồng ngoại lệ.**

- Vượt tần suất: ERR-15-007 (429); "Thao tác quá nhanh. Thử lại sau {n} giây."
- API không `PUBLIC`: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Cổng công khai đang tắt (`15.public.enabled = false`): ERR-15-001 (404) như trên.
- Tên miền cổng thuộc tenant khác với token của người gọi: ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này." (chi tiết riêng ở `detail`: Tài khoản không thuộc tenant của cổng này)

**Đầu ra.** `200` hoặc `304`; như FR-15-004, FR-15-006 nhưng rút gọn.

**Kết quả.** Dịch vụ công khai đọc được không cần tài khoản, dịch vụ khác vẫn kín.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (chỉ số truy cập tổng hợp); từ chối vì tần suất ghi nhật ký an ninh.

**Quy tắc nghiệp vụ.** BR-15-002; BR-15-003; BR-15-005; BR-15-006.

**Màn hình, API.** UI-15-01, UI-15-02, UI-15-04; API-15-003, API-15-004, API-15-010.
:::

### 6.3. Nhóm B · Tài liệu API

Nhóm B hiển thị đặc tả đã công bố thành tài liệu đọc được và dùng được: thao tác, lược đồ, ví dụ, mẫu mã, thay đổi giữa các phiên bản. Đặc tả gốc luôn ở PH-02; cổng không cho sửa đặc tả (BR-15-001) và không hiển thị đặc tả của phiên bản nháp.

#### FR-15-009 · Hiển thị tài liệu OpenAPI 3.1

::: dac-ta
**Mục đích.** Cho nhà phát triển đọc tài liệu kỹ thuật của một API tương tác được, luôn sinh từ đặc tả đã công bố, đáp ứng nghĩa vụ công bố tài liệu kỹ thuật đi kèm dịch vụ.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-004; FR-02-006; CMP-LAW-03; STD-05 (OpenAPI).

**Tiền điều kiện.** Phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` có đặc tả đã nạp.

**Kích hoạt.** Người dùng mở `/dich-vu/{ma-api}/tai-lieu`.

**Đầu vào.** `apiCode`; `phien-ban` (query); `thao-tac` (neo `operationId`).

**Luồng xử lý chính.**

1. Hệ thống nạp mô hình đã phân tích của phiên bản (không phân tích lại ở trình duyệt).
2. Hệ thống dựng mục lục trái theo thẻ `tags`, nội dung giữa cho từng thao tác: phương thức, đường dẫn, mô tả, tham số, thân yêu cầu, phản hồi, mã lỗi (RFC 9457), phạm vi cần có.
3. Hệ thống hiển thị schema dạng cây có thu gọn, ví dụ yêu cầu, phản hồi từ đặc tả; mô tả hiển thị tiếng Việt, tên trường giữ nguyên.
4. Hệ thống hiển thị mã băm và thời điểm của đặc tả để đối chiếu đồng bộ; mỗi thao tác có liên kết sâu bền vững theo `operationId`.
5. Mỗi thao tác có nút "Thử" mở khung thử (FR-15-035) và "Sao chép mẫu" (FR-15-012).

**Luồng thay thế.** Người dùng bấm "Tải đặc tả" (FR-15-011). Màn nhỏ: mục lục thành ngăn kéo.

**Luồng ngoại lệ.**

- Chưa có đặc tả đã nạp hoặc không phân tích được: ERR-15-009 (422); "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ." (chi tiết riêng ở `detail`: Đặc tả của phiên bản này tạm thời chưa hiển thị được. Báo lỗi cho chủ dịch vụ)
- Thao tác không có trong đặc tả: bỏ neo, hiển thị đầu trang.
- Phiên bản đã ngừng hẳn: ERR-15-038 (410).

**Đầu ra.** `200`; `operations[]`, `schemas`, `servers`, `hash`, `syncedAt`.

**Kết quả.** Tài liệu API đọc dễ, đúng bản đang phát hành, chia sẻ được bằng liên kết.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với API `PUBLIC`, `INTERNAL`; với `RESTRICTED`, `SENSITIVE` ghi mức tóm tắt (người, API, phiên bản) vào nhật ký truy cập.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002; BR-15-006.

**Màn hình, API.** UI-15-05; API-15-016, API-15-017.
:::

#### FR-15-010 · Hiển thị tài liệu AsyncAPI 3.0

::: dac-ta
**Mục đích.** Cho nhà phát triển đọc mô tả kênh, thông điệp và lược đồ của dịch vụ sự kiện cùng kiểu với tài liệu API.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; STD-05 (AsyncAPI); FR-02-009.

**Tiền điều kiện.** Mục `EVENT` có lược đồ AsyncAPI 3.0 đã nạp.

**Kích hoạt.** Mở `/su-kien/{ma-topic}` hoặc tài liệu của API có phần sự kiện.

**Đầu vào.** `topicName` hoặc `apiCode`; `phien-ban`.

**Luồng xử lý chính.**

1. Hệ thống nạp mô hình AsyncAPI đã phân tích (kênh, thao tác `send` và `receive`, thông điệp, `payload`).
2. Hệ thống dựng trang: tên topic theo quy ước `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}`, chế độ tương thích lược đồ, khóa, tiêu đề thông điệp, schema và ví dụ.
3. Hệ thống hiển thị mẫu mã nhận sự kiện (Java, Python, JavaScript) với giá trị giữ chỗ.
4. Hệ thống hiển thị nhãn chế độ sandbox: cổng không có sandbox sự kiện, chỉ hiện ví dụ thông điệp.

**Luồng thay thế.** Đặc tả AsyncAPI 2.x: hiển thị thô kèm cảnh báo "Hiển thị ở chế độ tương thích."

**Luồng ngoại lệ.**

- Lược đồ không phân tích được: ERR-15-009 (422); "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ." (chi tiết riêng ở `detail`: Lược đồ sự kiện tạm thời chưa hiển thị được)
- Ngoài tầm: ERR-15-001 (404).

**Đầu ra.** `200`; `channels[]`, `messages[]`, `schemas`.

**Kết quả.** Nhà phát triển hiểu thông điệp cần nhận, phát.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Như FR-15-009.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002.

**Màn hình, API.** UI-15-05; API-15-018.
:::

#### FR-15-011 · Chọn phiên bản, tải đặc tả, so sánh phiên bản

::: dac-ta
**Mục đích.** Cho nhà phát triển chọn đúng phiên bản API, tải đặc tả để sinh mã máy khách và nhìn ra điều gì đổi giữa hai phiên bản trước khi nâng cấp.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-004; FR-02-006, FR-02-043.

**Tiền điều kiện.** API có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`.

**Kích hoạt.** Người dùng đổi bộ chọn phiên bản, bấm "Tải đặc tả" hoặc "So sánh".

**Đầu vào.** `versionNo`; `format` (`yaml`, `json`); `base` (phiên bản so sánh).

**Luồng xử lý chính.**

1. Hệ thống liệt kê các phiên bản được phép thấy (không có `DRAFT`, `PENDING`) kèm trạng thái, ngày công bố, ngày dự kiến ngừng.
2. Khi chọn phiên bản, hệ thống nạp lại tài liệu (FR-15-009) và giữ phiên bản trên URL `phien-ban`.
3. Tải đặc tả: hệ thống trả tệp đã gộp tham chiếu với tên `{apiCode}-{versionNo}.{format}`, kèm `ETag` theo băm; chuyển đổi YAML, JSON không đổi nghĩa.
4. So sánh: hệ thống tính khác biệt giữa hai phiên bản trên mô hình đã phân tích, phân nhóm thao tác thêm, bỏ, đổi, đánh dấu thay đổi phá vỡ theo kết quả của PH-02 khi có; chỉ ở mức đọc.
5. Mọi lần tải đặc tả của API `RESTRICTED`, `SENSITIVE` được ghi kiểm toán.

**Luồng thay thế.** Phiên bản `DEPRECATED`: gợi ý phiên bản kế nhiệm ở đầu danh sách.

**Luồng ngoại lệ.**

- Phiên bản không tồn tại hoặc ngoài tầm: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Phiên bản đã ngừng hẳn: ERR-15-038 (410); "Phiên bản này đã ngừng cung cấp." (chi tiết riêng ở `detail`: Phiên bản này đã ngừng hoạt động. Xem phiên bản mới hơn)
- Hai phiên bản khác API: ERR-15-003 (400).

**Đầu ra.** `200`; tệp đặc tả với `Content-Disposition`; hoặc `diff` gồm `added[]`, `removed[]`, `changed[]`.

**Kết quả.** Nhà phát triển lấy được đặc tả đúng bản và thấy trước tác động của việc nâng cấp.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có với `RESTRICTED`, `SENSITIVE` (người, API, phiên bản, định dạng); không với còn lại.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002.

**Màn hình, API.** UI-15-05; API-15-015, API-15-016, API-15-020.
:::

#### FR-15-012 · Sinh mẫu mã gọi API

::: dac-ta
**Mục đích.** Cho nhà phát triển sao chép một đoạn mã chạy được cho thao tác đang xem, bằng ngôn ngữ họ dùng, kể cả bước lấy token, thay cho hướng dẫn lấy token bằng grant `password` của hệ cũ.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-017; LGC-IAM-006; SRS cũ FR-15-010; FR-02-005; SEC-24.

**Tiền điều kiện.** Phiên bản có đặc tả đã nạp.

**Kích hoạt.** Người dùng chọn ngôn ngữ ở thao tác của trang tài liệu hoặc khung thử.

**Đầu vào.** `operationId`; `lang` (`curl`, `java`, `python`, `javascript`, `csharp`, `go`); `env` (`SANDBOX`, `PRODUCTION`); `authKind`.

**Luồng xử lý chính.**

1. Hệ thống xác định kiểu xác thực của gói (OAuth2 `client_credentials`, mTLS, API key) và địa chỉ gốc theo môi trường.
2. Hệ thống sinh mẫu từ mẫu cố định theo ngôn ngữ: gồm bước lấy token (`client_credentials`, `private_key_jwt` hoặc `tls_client_auth` theo gói), gọi thao tác, tiêu đề bắt buộc (`Idempotency-Key` cho thao tác ghi, `traceparent`).
3. Hệ thống điền tham số và thân từ ví dụ trong đặc tả; giá trị nhạy cảm là giữ chỗ `{CLIENT_SECRET}`, không bao giờ là bí mật thật.
4. Hệ thống hiển thị nút "Sao chép" và ghi chú an toàn: không đưa bí mật vào mã nguồn, dùng kho bí mật.
5. Mẫu của môi trường `PRODUCTION` chỉ hiện cho người đủ điều kiện xem địa chỉ production (FR-15-006).

**Luồng thay thế.** Người dùng đang ở khung thử: mẫu phản ánh đúng yêu cầu đang soạn.

**Luồng ngoại lệ.**

- Ngôn ngữ không hỗ trợ: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Chưa có mẫu cho ngôn ngữ này)
- Thao tác không có: ERR-15-001 (404).

**Đầu ra.** `200`; `samples[]` (`lang`, `title`, `code`).

**Kết quả.** Nhà phát triển có mã chạy được trong vài giây.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-006; BR-15-011.

**Màn hình, API.** UI-15-05; API-15-019.
:::

#### FR-15-013 · Changelog, lộ trình ngừng dùng và banner DEPRECATED

::: dac-ta
**Mục đích.** Cho nhà phát triển biết API đã đổi gì qua từng phiên bản và khi nào phiên bản họ đang dùng sẽ ngừng, để không bị bất ngờ.

**Tác nhân, quyền.** Mọi người xem theo FR-15-002.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-005; FR-02-038, FR-02-039, FR-02-057.

**Tiền điều kiện.** Có phiên bản `DEPRECATED` hoặc có lịch sử phiên bản.

**Kích hoạt.** Mở `/dich-vu/{ma-api}/thay-doi`, hoặc mở tài liệu của phiên bản `DEPRECATED`.

**Đầu vào.** `apiCode`; `phien-ban`.

**Luồng xử lý chính.**

1. Hệ thống dựng dòng thời gian từ dữ liệu PH-02: công bố phiên bản, thay đổi phá vỡ, ngừng khuyến nghị, ngừng hẳn, thay đổi SLA, kèm ngày.
2. Với phiên bản `DEPRECATED`, hệ thống hiện banner không đóng được ở mọi trang liên quan: "Phiên bản {số} sẽ ngừng ngày {ngày}. Chuyển sang {phiên bản kế nhiệm}." kèm liên kết so sánh.
3. Hệ thống hiện thông báo `ANNOUNCEMENT` gắn với API (FR-15-017) trong cùng dòng thời gian.
4. Hệ thống hiện cảnh báo thêm cho người đã đăng ký phiên bản đó: "Đơn vị của bạn đang dùng phiên bản này."

**Luồng thay thế.** Phiên bản `RETIRED`: hiện ở mục "Đã ngừng" khi bật bộ lọc; không có đặc tả.

**Luồng ngoại lệ.**

- API không có lịch sử: "Chưa có thay đổi nào được ghi nhận."
- Ngoài tầm: ERR-15-001 (404).

**Đầu ra.** `200`; `timeline[]` (loại, ngày, mô tả, liên kết).

**Kết quả.** Nhà phát triển lên kế hoạch nâng cấp đúng hạn.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-002; BR-15-027.

**Màn hình, API.** UI-15-04, UI-15-05; API-15-021.
:::

### 6.4. Nhóm C · Hướng dẫn và nội dung

Nhóm C thay TechDocs của Backstage bằng một bộ quản lý nội dung nhẹ ngay trong PH-15: trang hướng dẫn viết bằng Markdown, có phiên bản, bắt buộc qua duyệt bốn mắt trước khi đăng, và có thể nhập từ thư mục `docs/` của kho Git. Chỉ nhân sự được giao (chủ dịch vụ, quản trị cổng) soạn nội dung; nhà phát triển chỉ đọc và phản hồi. Sơ đồ dưới là trình tự soạn, duyệt và đăng.

```{.mermaid caption="Trình tự soạn, duyệt và đăng một trang nội dung"}
sequenceDiagram
  autonumber
  actor S as Người soạn
  participant P as portal-content
  participant W as PH-18 Việc của tôi
  actor D as Người duyệt khác
  participant C as Bản sao danh mục và chỉ mục
  S->>P: Lưu bản nháp và bấm Gửi duyệt
  P->>P: Kiểm tra Markdown, liên kết, đính kèm
  P->>W: Tạo yêu cầu duyệt CONTENT cho người có quyền đăng
  D->>P: Mở yêu cầu, đọc, bấm Duyệt kèm ý kiến
  P->>P: So người duyệt với người soạn và người gửi
  P->>C: Đăng phiên bản, cập nhật chỉ mục tìm kiếm
  P-->>S: Thông báo kết quả và liên kết trang
```

Sơ đồ cho thấy kiểm tra bốn mắt diễn ra ở bước 5, lúc duyệt: người có đủ quyền đăng vẫn bị từ chối nếu chính họ là người soạn hoặc gửi bản đó.

#### FR-15-014 · Soạn trang nội dung Markdown

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và quản trị cổng viết hướng dẫn tích hợp, bắt đầu nhanh, hỏi đáp thường gặp, thông báo ngay trên cổng, thay cho tài liệu rời gửi qua thư và cho TechDocs của Backstage.

**Tác nhân, quyền.** SV (○, trang gắn API của tổ chức mình), CA, TA (`PERM-15-content-write`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-009, SRS cũ FR-15-010; D00-01 (Markdown là nguồn chuẩn).

**Tiền điều kiện.** Người dùng đã chấp nhận điều khoản nội bộ (nếu có); với trang gắn API, API thuộc tổ chức của người soạn (SV).

**Kích hoạt.** Ở UI-15-22 bấm "+ Trang mới": hộp nhập mã trang (đúng mẫu `pageCode`) rồi mở `/quan-tri-cong/noi-dung/{ma-trang}`, không có đường dẫn `/moi`; hoặc "Sửa" một trang có sẵn; hoặc "Tạo từ mẫu".

**Đầu vào.** Theo bảng dữ liệu vào của FR-15-014 dưới đây; `Idempotency-Key`; `If-Match` khi sửa.

**Luồng xử lý chính.**

1. Người dùng chọn loại trang và, nếu muốn, một mẫu có sẵn: "Kết nối mTLS", "Lấy token `client_credentials`", "Xử lý lỗi RFC 9457", "Danh sách kiểm tra tích hợp".
2. Hệ thống kiểm tra mã theo mẫu và chưa dùng (sai mẫu: ERR-15-003; trùng, kể cả trang đã lưu trữ: ERR-15-002).
3. Người dùng soạn Markdown với bản xem trước cạnh bên, dùng bộ lọc an toàn giống lúc hiển thị (BR-15-013); đính kèm ảnh (PNG, JPEG, WebP, tối đa 5 MB) qua API-15-033.
4. Hệ thống kiểm tra nội dung: cỡ ≤ 200 KB, không HTML thô, không script, iframe, liên kết `javascript:`, ảnh ngoài kho; vi phạm thì ERR-15-021.
5. Hệ thống lưu bản nháp (`DRAFT`), tự lưu mỗi 30 giây ở phía máy chủ; ghi kiểm toán khi lưu có chủ đích.

**Luồng thay thế.** Người dùng chỉ lưu nháp rồi quay lại sau. Sửa trang đã đăng: tạo phiên bản nháp mới, bản đang đăng giữ nguyên.

**Luồng ngoại lệ.**

- Mã đã dùng: ERR-15-002 (409); "Mã {mã} đã được dùng. Chọn mã khác."
- Nội dung không hợp lệ: ERR-15-021 (422); "Nội dung có phần không được phép: {chi tiết}."
- Tệp đính kèm không hợp lệ: ERR-15-024 (422); "Tệp không hợp lệ: chỉ nhận PNG, JPEG, WebP tối đa 5 MB và không có mã độc." (chi tiết riêng ở `detail`: Tệp không đúng định dạng hoặc vượt 5 MB)
- Hai người sửa cùng lúc: ERR-15-006 (412); "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."

**Đầu ra.** `201` (tạo) hoặc `200` (sửa), `ETag`; trang với `versionNo`, `status`.

**Kết quả.** Người soạn có bản nháp được xem trước đúng như hiển thị thật.

**Hậu điều kiện.** Phiên bản `DRAFT` được lưu, chưa hiển thị cho người đọc.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người, mã trang, loại, số phiên bản (không ghi nội dung).

**Quy tắc nghiệp vụ.** BR-15-007; BR-15-012; BR-15-013; BR-15-034.

**Màn hình, API.** UI-15-21; API-15-022, API-15-023, API-15-024, API-15-025, API-15-033, API-15-138 (đọc lại ảnh đính kèm khi xem trước).
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `pageCode` | T-CODE | Có | `^[a-z0-9][a-z0-9-]{1,62}$`, bất biến | `bat-dau-nhanh-mtls` |
| `type` | T-ENUM | Có | `GUIDE`, `QUICKSTART`, `FAQ`, `ANNOUNCEMENT`, `TERMS` | `GUIDE` |
| `lang` | T-ENUM | Có | `vi`, `en` | `vi` |
| `title` | T-NAME | Có | 3…150 ký tự | `Kết nối mTLS tới cổng API` |
| `body` | T-TEXT | Có | Markdown, ≤ 200 KB | `# Mở đầu…` |
| `audience` | T-ENUM | Có | `PUBLIC`, `LOGGED_IN`, `TENANT` | `LOGGED_IN` |
| `apiCode` | T-CODE | Không | API thuộc tổ chức người soạn | `tra-cuu-ho-tich` |
| `tags[]` | danh sách T-NAME | Không | ≤ 10 thẻ | `["mtls","bảo mật"]` |
| `validFrom`, `validTo` | T-TS | Với `ANNOUNCEMENT` | `validTo` sau `validFrom` | `2026-12-01T00:00:00+07:00` |

: Dữ liệu vào của FR-15-014

#### FR-15-015 · Gửi duyệt, duyệt và đăng trang

::: dac-ta
**Mục đích.** Bảo đảm mọi nội dung hiển thị cho nhà phát triển đã được một người thứ hai đọc, tránh hướng dẫn sai, lộ thông tin nội bộ hoặc đường dẫn nguy hiểm.

**Tác nhân, quyền.** Người soạn gửi (`PERM-15-content-write`); CA, TA duyệt (`PERM-15-content-publish`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; FR-00-070, FR-00-071, FR-00-072; ADR-046.

**Tiền điều kiện.** Phiên bản `DRAFT` đạt kiểm tra nội dung.

**Kích hoạt.** Người soạn bấm "Gửi duyệt"; người duyệt mở yêu cầu từ "Việc của tôi".

**Đầu vào.** `pageCode`, `versionNo`; quyết định `APPROVE` hoặc `REJECT`; `comment` (T-TEXT ≤ 2000, bắt buộc khi từ chối).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra lại nội dung và chuyển phiên bản `IN_REVIEW`, khóa sửa; tạo yêu cầu duyệt loại `CONTENT` gửi các người có `PERM-15-content-publish`.
2. Người duyệt đọc bản xem trước và khác biệt so với bản đang đăng.
3. Hệ thống kiểm tra người duyệt khác người soạn, người sửa gần nhất và người gửi (ERR-15-023).
4. Duyệt: hệ thống chuyển phiên bản `PUBLISHED`, bản đang đăng thành `SUPERSEDED`, cập nhật chỉ mục tìm kiếm và vô hiệu bộ đệm.
5. Từ chối: phiên bản thành `REJECTED` kèm lý do; người soạn nhận thông báo và soạn lại.
6. Hệ thống ghi kiểm toán, phát EVT-15-08.

**Luồng thay thế.** Người soạn rút lại bản đang `IN_REVIEW` (về `DRAFT`). Yêu cầu quá `15.content.review-sla-days` ngày chưa duyệt: nhắc trong "Việc của tôi" và báo TA.

**Luồng ngoại lệ.**

- Người duyệt là người soạn hoặc gửi: ERR-15-023 (403); "Người duyệt phải khác người soạn và người gửi duyệt." (chi tiết riêng ở `detail`: Bạn đã soạn hoặc gửi nội dung này nên không tự duyệt được)
- Trang không ở `IN_REVIEW`: ERR-15-022 (409); "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." (chi tiết riêng ở `detail`: Trang không ở trạng thái chờ duyệt)
- Thiếu lý do khi từ chối: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Cần nêu lý do từ chối)

**Đầu ra.** `200`; trang với `status`, `publishedVersionNo`.

**Kết quả.** Nội dung đã duyệt hiện cho người đọc ngay; nội dung bị từ chối quay về người soạn kèm lý do.

**Hậu điều kiện.** Một phiên bản `PUBLISHED` duy nhất mỗi trang.

**Sự kiện phát ra.** EVT-15-08 (`content.published`).

**Kiểm toán.** Có: người gửi, người duyệt, quyết định, lý do, phiên bản.

**Quy tắc nghiệp vụ.** BR-15-012; BR-15-013; BR-15-034.

**Màn hình, API.** UI-15-22; API-15-026, API-15-027, API-15-028.
:::

#### FR-15-016 · Phiên bản trang, so sánh, khôi phục, gỡ đăng

::: dac-ta
**Mục đích.** Cho người quản lý nội dung xem lịch sử mọi lần sửa, so sánh, quay lại bản cũ khi sửa nhầm, và gỡ trang không còn đúng.

**Tác nhân, quyền.** `PERM-15-content-write` (xem, so sánh, khôi phục thành nháp); `PERM-15-content-publish` (gỡ).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; FR-00-043.

**Tiền điều kiện.** Trang có từ một phiên bản trở lên.

**Kích hoạt.** Mở tab "Lịch sử" của trang ở UI-15-22.

**Đầu vào.** `pageCode`, `versionNo`; `reason` khi gỡ.

**Luồng xử lý chính.**

1. Hệ thống liệt kê các phiên bản kèm trạng thái, người soạn, người duyệt, thời điểm. So sánh hai phiên bản do máy chủ thực hiện (API-15-142, tham số `base`, `to`) để dùng chung bộ lọc an toàn và không phải tải hai bản đầy đủ về trình duyệt.
2. Người dùng chọn hai phiên bản; hệ thống hiển thị khác biệt theo dòng.
3. Khôi phục: hệ thống tạo phiên bản `DRAFT` mới có nội dung của bản chọn; vẫn phải qua FR-15-015 để đăng.
4. Gỡ đăng: người có quyền đăng nêu lý do; hệ thống chuyển trang `UNPUBLISHED` ngay (không cần người thứ hai, vì gỡ chỉ giảm hiển thị), xóa khỏi chỉ mục, phát EVT-15-09.
5. Hệ thống ghi kiểm toán.

**Luồng thay thế.** Gỡ trang `TERMS` đang có hiệu lực không cho phép khi chưa có bản thay thế.

**Luồng ngoại lệ.**

- Phiên bản không có: ERR-15-001 (404).
- Gỡ khi trang không `PUBLISHED`: ERR-15-022 (409); "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." (chi tiết riêng ở `detail`: Trang không ở trạng thái đang đăng)
- Gỡ điều khoản duy nhất: ERR-15-022 (409); "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." (chi tiết riêng ở `detail`: Không thể gỡ điều khoản đang có hiệu lực)

**Đầu ra.** `200`; danh sách phiên bản hoặc trang sau khi đổi trạng thái.

**Kết quả.** Có đủ lịch sử để truy trách nhiệm và hoàn tác.

**Hậu điều kiện.** Phiên bản cũ giữ vĩnh viễn; trang `UNPUBLISHED` không hiển thị.

**Sự kiện phát ra.** EVT-15-09 (`content.unpublished`) khi gỡ.

**Kiểm toán.** Có: phiên bản, hành động, lý do.

**Quy tắc nghiệp vụ.** BR-15-012; BR-15-034.

**Màn hình, API.** UI-15-22; API-15-029, API-15-030, API-15-031, API-15-032, API-15-142.
:::

#### FR-15-017 · Hiển thị trang nội dung

::: dac-ta
**Mục đích.** Cho người đọc xem hướng dẫn, hỏi đáp, thông báo ở dạng sạch, có mục lục, tìm được, an toàn trước chèn mã.

**Tác nhân, quyền.** Mọi người xem; phạm vi theo `audience` của trang.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-009; SEC-44, SEC-45.

**Tiền điều kiện.** Trang `PUBLISHED`.

**Kích hoạt.** Mở `/huong-dan`, `/huong-dan/{ma-trang}`, `/hoi-dap`, `/thong-bao`.

**Đầu vào.** `pageCode`; `lang`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra `audience` so với hạng người xem; ngoài tầm thì trả như không tồn tại.
2. Hệ thống dựng HTML từ Markdown qua bộ lọc cho phép (tiêu đề, danh sách, bảng, khối mã, liên kết, ảnh trong kho); liên kết ngoài có `rel="noopener nofollow"`.
3. Hệ thống dựng mục lục từ tiêu đề, hiển thị ngày cập nhật, phiên bản, tác giả hiển thị (tên cổng, không tên cá nhân).
4. Ảnh đính kèm phục vụ qua API-15-138 bằng đường dẫn có chữ ký, hết hạn 15 phút; tệp trả với `Content-Type` đúng và `X-Content-Type-Options: nosniff`.
5. Với `ANNOUNCEMENT`, chỉ hiện trong khoảng `validFrom` đến `validTo`; với `TERMS`, hiện kèm nút chấp nhận (FR-15-023).
6. Trang có ô "Trang này có hữu ích không" (FR-15-053).

**Luồng thay thế.** Chưa có bản `en`: hiện bản `vi` kèm ghi chú.

**Luồng ngoại lệ.**

- Trang không có hoặc ngoài tầm: ERR-15-001 (404); "Không tìm thấy nội dung yêu cầu."
- Ảnh hết hạn chữ ký: tải lại trang tự cấp chữ ký mới; không hiện lỗi.

**Đầu ra.** `200`; `html`, `toc[]`, `updatedAt`, `versionNo`.

**Kết quả.** Người đọc thấy hướng dẫn rõ, an toàn.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-005; BR-15-013; BR-15-006.

**Màn hình, API.** UI-15-07; API-15-034, API-15-035, API-15-036, API-15-037, API-15-138.
:::

#### FR-15-018 · Nhập nội dung từ kho Git

::: dac-ta
**Mục đích.** Cho tổ chức đang viết tài liệu tích hợp trong thư mục `docs/` của kho Git tiếp tục viết ở đó, còn cổng tự lấy về làm bản nháp, thay cho TechDocs build từ kho của Backstage.

**Tác nhân, quyền.** TA, CA (`PERM-15-content-write`); hệ thống (lịch đồng bộ).

**Mức ưu tiên, đợt.** S · Đợt 3.

**Truy vết.** REQ-15; SRS cũ FR-15-009; SEC-16, SEC-33.

**Tiền điều kiện.** Kho Git thuộc danh sách egress cho phép; có mã truy cập chỉ đọc.

**Kích hoạt.** Khai báo nguồn Git ở UI-15-21; đến lịch `15.git.sync-interval-minutes`; bấm "Đồng bộ ngay".

**Đầu vào.** `repoUrl` (HTTPS), `branch`, `path` (mặc định `docs/`), mã truy cập (ghi một chiều vào OpenBao).

**Luồng xử lý chính.**

1. Người dùng khai báo nguồn; hệ thống kiểm tra URL thuộc danh sách egress (ERR-15-025) và lưu mã truy cập vào OpenBao, không hiển thị lại.
2. Hệ thống lấy nhánh, đọc tệp `portal.yaml` ở thư mục gốc khai báo ánh xạ tệp Markdown sang `pageCode`, loại, ngôn ngữ, `audience` (thiếu hoặc sai: ERR-15-026).
3. Với mỗi tệp thay đổi so với lần trước (so băm), hệ thống tạo phiên bản `DRAFT` mới của trang tương ứng, ghi `commit` nguồn.
4. Hệ thống kiểm tra nội dung như FR-15-014; tệp vi phạm bị bỏ qua kèm báo cáo.
5. Hệ thống không bao giờ tự đăng: mọi phiên bản nhập qua duyệt bốn mắt (FR-15-015); người gửi duyệt là người bấm "Gửi duyệt".

**Luồng thay thế.** Webhook từ kho gọi đồng bộ ngay.

**Luồng ngoại lệ.**

- Kho không đọc được: ERR-15-025 (502); "Chưa kết nối được kho Git. Thử lại sau." (chi tiết riêng ở `detail`: Không đọc được kho Git. Kiểm tra địa chỉ và quyền truy cập)
- Thiếu `portal.yaml`: ERR-15-026 (422); "Gói di trú sai cấu trúc hoặc có tệp không được phép." (chi tiết riêng ở `detail`: Kho thiếu tệp portal.yaml hoặc sai cấu trúc)

**Đầu ra.** `202`; `runId`, số tệp mới, đổi, bị bỏ qua.

**Kết quả.** Tài liệu viết ở kho Git xuất hiện thành nháp ở cổng, chờ duyệt.

**Hậu điều kiện.** Các phiên bản nháp mới; mốc `commit` đã xử lý.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: nguồn, `commit`, số tệp, người khai báo.

**Quy tắc nghiệp vụ.** BR-15-012; BR-15-013; BR-15-034.

**Màn hình, API.** UI-15-21, UI-15-27; API-15-038, API-15-039, API-15-040.
:::

### 6.5. Nhóm D · Tài khoản nhà phát triển

Nhóm D cho hai nguồn người dùng vào cổng: cán bộ CQNN đăng nhập SSO bằng realm của tỉnh và nhà thầu tự đăng ký ở realm `dh-dev` rồi chờ duyệt. Hai nhóm này có quyền khác nhau nhưng dùng chung giao diện. Sơ đồ máy trạng thái tài khoản `dh-dev` ở mục 4.6.

#### FR-15-019 · Đăng nhập SSO realm tenant

::: dac-ta
**Mục đích.** Cho cán bộ CQNN vào cổng bằng tài khoản cơ quan đã có, không nhớ thêm mật khẩu; đồng thời cho nhà thầu đăng nhập bằng tài khoản `dh-dev` ở cùng một màn.

**Tác nhân, quyền.** Cán bộ CQNN; nhà thầu `dh-dev`.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-014; FR-00-001, FR-00-002, FR-00-003; SEC-21, SEC-23, SEC-29.

**Tiền điều kiện.** Keycloak khả dụng; tài khoản không bị khóa.

**Kích hoạt.** Bấm "Đăng nhập" hoặc mở trang cần đăng nhập.

**Đầu vào.** `realm` (`tenant`, `dev`) chọn ở `/dang-nhap`; địa chỉ quay về.

**Luồng xử lý chính.**

1. Người dùng chọn "Cán bộ cơ quan" (realm `dh-{tenant}`) hoặc "Nhà thầu" (realm `dh-dev`).
2. BFF chuyển tới Keycloak với Authorization Code và PKCE `S256`; Keycloak xác thực, bắt MFA nếu vai trò yêu cầu (TA, CA: WebAuthn).
3. BFF đổi mã lấy token, giữ ở Valkey, đặt cookie `__Host-dh-sid` (`HttpOnly`, `Secure`, `SameSite=Strict`); trình duyệt không cầm token (SEC-21).
4. Lần đầu của cán bộ: hệ thống tạo hồ sơ EN-15-06 nguồn `TENANT_SSO`, trạng thái `ACTIVE`; lần đầu của nhà thầu: hồ sơ đã có từ lúc đăng ký.
5. Hệ thống kiểm tra tài khoản `dh-dev` ở `ACTIVE` (FR-15-058) và điều khoản hiện hành (FR-15-023); cập nhật `lastLoginAt`.
6. Phiên nhàn rỗi 15 phút (cấu hình 5 đến 15 theo tenant) và tối đa 10 giờ thì hết; đăng xuất gọi `end_session_endpoint` và back-channel logout.

**Luồng thay thế.** Người dùng có nhiều tenant: chọn tenant làm việc (FR-00-004).

**Luồng ngoại lệ.**

- Keycloak lỗi: ERR-15-020 (503); "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau." (chi tiết riêng ở `detail`: Dịch vụ đăng nhập tạm gián đoạn. Các trang công khai vẫn xem được)
- Tài khoản `dh-dev` chưa xác minh hoặc chưa duyệt: ERR-15-011 (422); "Tài khoản chưa được xác minh hoặc chưa được duyệt."
- Tài khoản khóa hoặc vô hiệu: ERR-15-014 (403); "Tài khoản đang bị khóa. Liên hệ quản trị cổng."
- Phiên hết hạn: ERR-15-004 (401); "Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục."

**Đầu ra.** Chuyển hướng `302`; cookie phiên; hồ sơ `GET /me` (API-15-041).

**Kết quả.** Người dùng đăng nhập, thấy đúng danh mục theo hạng của mình.

**Hậu điều kiện.** Phiên BFF tồn tại; `lastLoginAt` cập nhật.

**Sự kiện phát ra.** Không (sự kiện đăng nhập do Keycloak, PH-12).

**Kiểm toán.** Có: đăng nhập, đăng xuất, thất bại (người, realm, nguồn).

**Quy tắc nghiệp vụ.** BR-15-004; BR-15-028; BR-15-031.

**Màn hình, API.** UI-15-08; API-15-041; đường dẫn BFF `/bff/dang-nhap`, `/bff/dang-xuat` (không thuộc API-15).
:::

#### FR-15-020 · Tự đăng ký tài khoản dh-dev

::: dac-ta
**Mục đích.** Cho nhà thầu chưa có tài khoản của tỉnh tự đăng ký để tìm hiểu dịch vụ và thử sandbox, nhưng chỉ sau khi chứng minh được hộp thư và thuộc một đơn vị thầu có hợp đồng.

**Tác nhân, quyền.** Khách ẩn danh.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-014; CMP-LAW-05; SEC-22, SEC-27.

**Tiền điều kiện.** `15.dev.signup-enabled = true`.

**Kích hoạt.** Bấm "Đăng ký tài khoản nhà thầu" ở UI-15-08.

**Đầu vào.** Theo bảng dữ liệu vào của FR-15-020 dưới đây.

**Luồng xử lý chính.**

1. Người dùng nhập thông tin và xác nhận đã đọc thông báo xử lý dữ liệu cá nhân và điều khoản.
2. Hệ thống kiểm tra thư chưa đăng ký (ERR-15-012), mật khẩu đạt chính sách 14 ký tự trở lên (SEC-22), tần suất đăng ký theo IP (ERR-15-037).
3. Hệ thống tạo tài khoản `PENDING_EMAIL`, tạo người dùng bị vô hiệu ở realm `dh-dev`, gửi thư chứa liên kết xác minh một lần, hiệu lực 24 giờ (thư chỉ có liên kết, FR-00-062).
4. Người dùng bấm liên kết; hệ thống kiểm tra mã (ERR-15-013) và chuyển `PENDING_APPROVAL`, phát EVT-15-06, tạo yêu cầu duyệt cho TA ở "Việc của tôi".
5. Quá 24 giờ chưa xác minh: tài khoản `EXPIRED` và bị xóa khỏi realm.

**Luồng thay thế.** Gửi lại thư xác minh tối đa 3 lần mỗi giờ.

**Luồng ngoại lệ.**

- Thư đã đăng ký: ERR-15-012 (409); "Thư điện tử này đã được đăng ký." (chi tiết riêng ở `detail`: Thư điện tử này đã có tài khoản. Đăng nhập hoặc đặt lại mật khẩu)
- Mã sai hoặc hết hạn: ERR-15-013 (400); "Mã xác minh không đúng hoặc đã hết hạn."
- Đăng ký quá nhiều: ERR-15-037 (429); "Bạn gửi quá nhiều. Thử lại sau {n} phút."
- Dữ liệu sai: ERR-15-003 (400); lỗi theo trường.
- Tự đăng ký đang tắt (`15.dev.signup-enabled = false`): ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này." (chi tiết riêng ở `detail`: Cổng chưa mở đăng ký tài khoản nhà thầu); giao diện ẩn mục đăng ký.

**Đầu ra.** `202`; `registrationId`, `status = PENDING_EMAIL`.

**Kết quả.** Người đăng ký biết đang chờ xác minh rồi chờ duyệt, không nhận quyền gì trước khi được duyệt.

**Hậu điều kiện.** Tài khoản `PENDING_EMAIL` rồi `PENDING_APPROVAL`; người dùng realm chưa bật.

**Sự kiện phát ra.** EVT-15-06 (`devaccount.registered`) khi xác minh thư xong.

**Kiểm toán.** Có: đăng ký, xác minh, đồng ý thông báo xử lý dữ liệu (thời điểm, phiên bản).

**Quy tắc nghiệp vụ.** BR-15-028; BR-15-029.

**Màn hình, API.** UI-15-08; API-15-045, API-15-046.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `email` | T-EMAIL | Có | Hợp lệ, không thuộc danh sách thư dùng một lần | `an.nguyen@congty-abc.vn` |
| `fullName` | T-NAME | Có | 2…100 ký tự | `Nguyễn Văn An` |
| `orgName` | T-NAME | Có | Tên đơn vị thầu, 2…200 ký tự | `Công ty ABC` |
| `contractRef` | T-TEXT | Có | Số hợp đồng hoặc văn bản giao việc, 3…200 ký tự | `HĐ 25/2026/SKHCN` |
| `sponsorOrgCode` | T-CODE | Có | Tổ chức CQNN của tenant giao việc | `SO-TUPHAP` |
| `phone` | T-TEXT | Không | Số điện thoại Việt Nam | `0901234567` |
| `password` | bí mật | Có | ≥ 14 ký tự, đạt chính sách realm | (không hiển thị) |
| `acceptPrivacyNotice` | T-BOOL | Có | Phải `true` | `true` |

: Dữ liệu vào của FR-15-020

#### FR-15-021 · Hồ sơ cá nhân và phiên đăng nhập

::: dac-ta
**Mục đích.** Cho người dùng xem, sửa thông tin của mình, chọn ngôn ngữ, kênh thông báo và thu hồi các phiên đang mở.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập (về chính mình).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; FR-00-005, FR-00-061.

**Tiền điều kiện.** Đã đăng nhập.

**Kích hoạt.** Mở `/tai-khoan`.

**Đầu vào.** `fullName`, `orgName`, `phone`, `lang`, `notifyChannels`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống hiển thị hồ sơ, nguồn tài khoản, vai trò, tenant được cấp, trạng thái điều khoản.
2. Người dùng sửa các trường được phép; thư và tổ chức của cán bộ SSO chỉ đọc (do PH-12 quản lý).
3. Hệ thống kiểm tra miền giá trị; lưu với `If-Match`.
4. Hệ thống liệt kê phiên đang mở (thiết bị, thời điểm, địa chỉ rút gọn); người dùng thu hồi từng phiên, hệ thống hủy phiên BFF ở Valkey.
5. Đổi mật khẩu, đăng ký MFA mở trang tài khoản Keycloak.

**Luồng thay thế.** Không có.

**Luồng ngoại lệ.**

- Hồ sơ bị sửa bởi nơi khác: ERR-15-006 (412); "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."
- Giá trị sai: ERR-15-003 (400).
- Thu hồi phiên không phải của mình: ERR-15-005 (403).

**Đầu ra.** `200`, `ETag`; hồ sơ; danh sách phiên.

**Kết quả.** Hồ sơ cập nhật; phiên bị thu hồi mất hiệu lực ngay.

**Hậu điều kiện.** Hồ sơ mới; phiên đã thu hồi bị hủy.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: sửa hồ sơ (trường đổi, không giá trị cũ của dữ liệu cá nhân), thu hồi phiên.

**Quy tắc nghiệp vụ.** BR-15-029; BR-15-034.

**Màn hình, API.** UI-15-09; API-15-041, API-15-042, API-15-043, API-15-044.
:::

#### FR-15-022 · Nhóm phát triển

::: dac-ta
**Mục đích.** Cho nhiều người của một đội cùng quản lý ứng dụng sandbox, thay vì một tài khoản dùng chung.

**Tác nhân, quyền.** Mọi người dùng có `PERM-15-app`; chủ nhóm (`OWNER`) quản lý thành viên.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-020 (liên quan).

**Tiền điều kiện.** Đã đăng nhập, đã chấp nhận điều khoản.

**Kích hoạt.** Tạo nhóm ở UI-15-09 hoặc mời thành viên.

**Đầu vào.** `teamCode` (T-CODE), `name`; mời: `email`, `role` (`DEVELOPER`, `VIEWER`).

**Luồng xử lý chính.**

1. Người dùng tạo nhóm; hệ thống kiểm tra mã chưa dùng (ERR-15-002) và đặt người tạo làm `OWNER`.
2. Chủ nhóm mời bằng thư của người đã có tài khoản cổng; hệ thống tạo lời mời hết hạn sau 7 ngày, gửi thông báo trong ứng dụng và thư (chỉ liên kết).
3. Người được mời chấp nhận hoặc từ chối ở hộp thông báo (FR-15-052).
4. Chủ nhóm đổi vai trò hoặc xóa thành viên; thành viên rời nhóm.
5. Ứng dụng thuộc nhóm hiện cho mọi thành viên theo vai trò (FR-15-033).

**Luồng thay thế.** Nhà thầu `dh-dev` chỉ mời được người cùng realm hoặc cán bộ của tenant được cấp.

**Luồng ngoại lệ.**

- Mã nhóm trùng: ERR-15-002 (409); "Mã {mã} đã được dùng. Chọn mã khác."
- Đã là thành viên, hoặc đã có lời mời: ERR-15-027 (409); "Người này đã là thành viên hoặc đã có lời mời."
- Chủ nhóm duy nhất rời hoặc xóa nhóm: ERR-15-028 (422); "Phải còn ít nhất một chủ sở hữu." (chi tiết riêng ở `detail`: Cần chuyển quyền chủ nhóm cho người khác trước)

**Đầu ra.** `201` hoặc `200`; nhóm, thành viên, lời mời.

**Kết quả.** Cả đội cùng làm việc trên ứng dụng của nhóm.

**Hậu điều kiện.** Quan hệ thành viên cập nhật; quyền trên ứng dụng của nhóm thay đổi theo.

**Sự kiện phát ra.** EVT-15-13 (`team.member-changed`).

**Kiểm toán.** Có: tạo nhóm, mời, đổi vai trò, xóa thành viên.

**Quy tắc nghiệp vụ.** BR-15-007; BR-15-009.

**Màn hình, API.** UI-15-09, UI-15-19; API-15-049, API-15-050, API-15-051, API-15-052, API-15-053.
:::

#### FR-15-023 · Chấp nhận điều khoản sử dụng có phiên bản

::: dac-ta
**Mục đích.** Bảo đảm mọi người tạo ứng dụng hoặc thử API đã đọc và đồng ý điều khoản hiện hành, kể cả khi điều khoản đổi.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; CMP-LAW-05.

**Tiền điều kiện.** Có trang `TERMS` đang đăng (FR-15-015).

**Kích hoạt.** Lần đầu tạo ứng dụng, thử API; hoặc khi điều khoản có phiên bản mới.

**Đầu vào.** `termsVersion`; `accepted` (T-BOOL).

**Luồng xử lý chính.**

1. Hệ thống so phiên bản điều khoản người dùng đã chấp nhận với phiên bản hiện hành.
2. Lệch thì hiển thị hộp thoại với nội dung, chặn các thao tác cần `PERM-15-app`, `PERM-15-try` (ERR-15-010).
3. Người dùng đánh dấu đồng ý và bấm "Đồng ý"; hệ thống ghi chấp nhận kèm phiên bản, thời điểm, băm địa chỉ nguồn.
4. Người không đồng ý vẫn đọc được danh mục và tài liệu.

**Luồng thay thế.** TA đăng bản điều khoản mới: thông báo bắt buộc tới người dùng đang hoạt động (FR-15-052).

**Luồng ngoại lệ.**

- Chưa chấp nhận khi thao tác: ERR-15-010 (409); "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."
- Phiên bản gửi lên không phải hiện hành: ERR-15-003 (400).

**Đầu ra.** `200`; `termsVersion`, `acceptedAt`.

**Kết quả.** Có bằng chứng người dùng đã đồng ý.

**Hậu điều kiện.** Bản ghi chấp nhận gắn người dùng và phiên bản.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: chấp nhận (người, phiên bản, thời điểm).

**Quy tắc nghiệp vụ.** BR-15-008.

**Màn hình, API.** UI-15-09, UI-15-07; API-15-047, API-15-048.
:::

#### FR-15-024 · Vô hiệu hóa không hoạt động và xóa tài khoản

::: dac-ta
**Mục đích.** Giảm rủi ro tài khoản bị bỏ quên và đáp ứng quyền xóa dữ liệu cá nhân của người đăng ký.

**Tác nhân, quyền.** Hệ thống (tác vụ hằng ngày); người dùng (yêu cầu xóa); TA (`PERM-15-dev-approve`) kích hoạt lại.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; CMP-LAW-05; SEC-27, SEC-39.

**Tiền điều kiện.** Tài khoản `dh-dev`.

**Kích hoạt.** Tác vụ hằng ngày; người dùng bấm "Xóa tài khoản".

**Đầu vào.** Yêu cầu xóa: xác nhận mật khẩu và cụm từ xác nhận.

**Luồng xử lý chính.**

1. Hệ thống tìm tài khoản `ACTIVE` không đăng nhập quá 30 ngày và gửi cảnh báo ở mốc 30 và 40 ngày.
2. Đến ngày 45, hệ thống chuyển tài khoản `DISABLED`, tắt người dùng ở realm `dh-dev`, tạm ngừng ứng dụng thuộc riêng người này.
3. Tài khoản muốn dùng lại gửi yêu cầu kích hoạt, chuyển `PENDING_APPROVAL` để TA duyệt (FR-15-058).
4. Người dùng yêu cầu xóa: hệ thống thu hồi mọi thông tin xác thực, chuyển ứng dụng của nhóm cho chủ nhóm khác hoặc lưu trữ, ẩn danh họ tên, thư, tổ chức, điện thoại, xóa người dùng ở realm `dh-dev`; tài khoản thành `ERASED`.
5. Bản ghi kiểm toán giữ nguyên theo thời hạn WORM nhưng chỉ tham chiếu mã ẩn danh.
6. Tài khoản không hoạt động quá `15.dev.anonymize-after-months` tháng (mặc định 24) bị ẩn danh tự động.

**Luồng thay thế.** Người dùng đăng nhập trước ngày 45: bộ đếm đặt lại.

**Luồng ngoại lệ.**

- Xác nhận xóa sai: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Cụm từ xác nhận chưa đúng)
- Là chủ duy nhất của nhóm còn thành viên: ERR-15-028 (422); "Phải còn ít nhất một chủ sở hữu." (chi tiết riêng ở `detail`: Cần chuyển quyền chủ nhóm trước khi xóa tài khoản)

**Đầu ra.** `202`; `status = ERASED`.

**Kết quả.** Tài khoản không còn dùng được và dữ liệu cá nhân bị ẩn danh.

**Hậu điều kiện.** Không còn dữ liệu cá nhân nhận diện được ngoài bản ghi kiểm toán theo luật.

**Sự kiện phát ra.** EVT-15-07 (`devaccount.state-changed`).

**Kiểm toán.** Có: vô hiệu, kích hoạt lại, xóa.

**Quy tắc nghiệp vụ.** BR-15-028; BR-15-029.

**Màn hình, API.** UI-15-09, UI-15-24; API-15-054.
:::

### 6.6. Nhóm E · Ứng dụng sandbox và thông tin xác thực

Nhóm E cho nhà phát triển tự tạo ứng dụng sandbox và tự cấp thông tin xác thực để gọi sandbox, thay cho việc xin khóa qua thư ở hệ cũ. Điểm an toàn cốt lõi: bí mật chỉ tồn tại trong phản hồi cấp phát, cổng không lưu, và thông tin xác thực sandbox không có quyền gì ở production. Sơ đồ dưới là trình tự cấp thông tin xác thực `client_credentials` sandbox.

```{.mermaid caption="Trình tự cấp thông tin xác thực sandbox"}
sequenceDiagram
  autonumber
  actor D as Nhà phát triển
  participant B as BFF dh-portal
  participant P as portal-dev
  participant K as Keycloak realm dh-dev
  participant A as PH-13 kiểm toán
  D->>B: Bấm Cấp thông tin xác thực trên ứng dụng
  B->>P: POST credentials kèm Idempotency-Key
  P->>P: Kiểm tra quyền, trạng thái ứng dụng, giới hạn số lượng
  P->>K: Tạo client sbx và service account qua Admin API
  K-->>P: clientId và secret
  P->>P: Lưu tiền tố bí mật và hạn, không lưu secret
  P->>A: Ghi kiểm toán SECRET_ISSUED không kèm secret
  P-->>B: 201 kèm secret, Cache-Control no-store
  B-->>D: Hiển thị bí mật một lần
```

Sơ đồ cho thấy bí mật đi từ Keycloak tới trình duyệt qua đường duy nhất ở bước 8, không đi qua cơ sở dữ liệu, bộ đệm hay nhật ký của cổng; mất phản hồi thì chỉ có thể xoay vòng để lấy bí mật mới (ERR-15-019).

#### FR-15-025 · Tạo ứng dụng sandbox

::: dac-ta
**Mục đích.** Cho nhà phát triển có "chỗ đứng" ở cổng để thử API: một ứng dụng có tên, có chủ, có hạn mức riêng.

**Tác nhân, quyền.** DEV (`PERM-15-app`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-020 (liên quan); SRS cũ FR-15-008; BP-01.

**Tiền điều kiện.** Đã đăng nhập, tài khoản `ACTIVE`, đã chấp nhận điều khoản (FR-15-023).

**Kích hoạt.** Bấm "+ Ứng dụng mới" ở UI-15-10.

**Đầu vào.** Theo bảng dữ liệu vào của FR-15-025 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Người dùng nhập tên, mã, mô tả, chọn chủ là cá nhân hoặc một nhóm của mình.
2. Hệ thống kiểm tra mã theo mẫu và chưa dùng, kể cả ứng dụng đã lưu trữ (sai mẫu: ERR-15-003; trùng: ERR-15-002). Giao diện báo trùng ngay khi gõ bằng API-15-141 (`appCode`), việc kiểm tra cuối vẫn ở bước tạo.
3. Hệ thống kiểm tra giới hạn số ứng dụng đang hoạt động của người hoặc nhóm (`15.app.max-per-user`, `15.app.max-per-team`; vượt: ERR-15-015).
4. Cán bộ CQNN có thể liên kết ứng dụng với một HTTT của tổ chức mình (`systemCode`) để xem tham chiếu production (FR-15-032); nhà thầu `dh-dev` không có trường này.
5. Hệ thống tạo ứng dụng `ACTIVE` và đặt người tạo là `OWNER`; chưa có thông tin xác thực; ghi kiểm toán.

**Luồng thay thế.** Người dùng chọn "Cấp thông tin xác thực ngay" để sang FR-15-027 hoặc FR-15-028.

**Luồng ngoại lệ.**

- Mã đã dùng: ERR-15-002 (409); "Mã {mã} đã được dùng. Chọn mã khác."
- Vượt giới hạn: ERR-15-015 (422); "Đã đạt số ứng dụng tối đa ({n}). Lưu trữ ứng dụng không dùng để tạo mới."
- Chưa chấp nhận điều khoản: ERR-15-010 (409).
- HTTT không thuộc tổ chức người dùng: ERR-15-032 (422); "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này." (chi tiết riêng ở `detail`: HTTT này không thuộc đơn vị của bạn)

**Đầu ra.** `201`, `Location`, `ETag`; ứng dụng với `appCode`, `status`, `ownerType`.

**Kết quả.** Nhà phát triển có ứng dụng sandbox và biết bước kế tiếp là cấp thông tin xác thực.

**Hậu điều kiện.** Ứng dụng `ACTIVE`, chưa có thông tin xác thực.

**Sự kiện phát ra.** EVT-15-01 (`app.created`).

**Kiểm toán.** Có: người, mã, chủ, HTTT liên kết.

**Quy tắc nghiệp vụ.** BR-15-007; BR-15-008; BR-15-009; BR-15-010.

**Màn hình, API.** UI-15-10, UI-15-11; API-15-056, API-15-141.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `appCode` | T-CODE | Có | `^[a-z][a-z0-9-]{2,40}$`, bất biến, duy nhất trong tenant | `datdai-thu-nghiem` |
| `name` | T-NAME | Có | 3…100 ký tự | `Thử nghiệm tra cứu hộ tịch` |
| `description` | T-TEXT | Không | ≤ 1000 ký tự | `Ứng dụng của HT-DATDAI` |
| `ownerType` | T-ENUM | Có | `USER`, `TEAM` | `TEAM` |
| `teamCode` | T-CODE | Khi `ownerType = TEAM` | Nhóm mà người tạo là `OWNER` hoặc `DEVELOPER` | `nhom-datdai` |
| `systemCode` | T-CODE | Không | HTTT `ACTIVE` của tổ chức người dùng; chỉ cán bộ SSO | `HT-DATDAI` |

: Dữ liệu vào của FR-15-025

#### FR-15-026 · Xem, sửa, lưu trữ, khôi phục ứng dụng

::: dac-ta
**Mục đích.** Cho nhà phát triển theo dõi ứng dụng của mình, sửa thông tin, dọn dẹp ứng dụng không dùng và lấy lại nếu lưu trữ nhầm.

**Tác nhân, quyền.** DEV (`PERM-15-app`), theo vai trò trên ứng dụng (BR-15-009).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-020 (liên quan); SRS cũ FR-15-008.

**Tiền điều kiện.** Người dùng là thành viên của ứng dụng.

**Kích hoạt.** Mở `/ung-dung` hoặc `/ung-dung/{ma-ung-dung}`.

**Đầu vào.** `appCode`; `name`, `description`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống liệt kê ứng dụng người dùng là thành viên (trực tiếp hoặc qua nhóm) kèm trạng thái, số thông tin xác thực, hạn sớm nhất, số lượt thử 24 giờ.
2. Trang chi tiết gồm các tab Tổng quan, Xác thực, Thống kê, Nhật ký, Thành viên, Bộ sưu tập.
3. `OWNER` sửa tên, mô tả; hệ thống lưu với `If-Match`.
4. Lưu trữ: hệ thống kiểm tra ứng dụng `ACTIVE` hoặc `SUSPENDED`, thu hồi mọi thông tin xác thực (FR-15-031), chuyển `ARCHIVED`.
5. Khôi phục trong 30 ngày: chuyển `ACTIVE`, không khôi phục bí mật; quá 30 ngày ứng dụng bị xóa.
6. Ứng dụng `ACTIVE` không có lượt gọi 180 ngày được hệ thống tự lưu trữ sau cảnh báo 14 ngày.

**Luồng thay thế.** Người dùng lọc theo trạng thái, nhóm.

**Luồng ngoại lệ.**

- Không phải thành viên hoặc không đủ vai trò: ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này."
- Ứng dụng không ở trạng thái cho phép: ERR-15-017 (409); "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."
- Xung đột sửa: ERR-15-006 (412).

**Đầu ra.** `200`, `ETag`; danh sách, chi tiết.

**Kết quả.** Người dùng quản lý được vòng đời ứng dụng của mình.

**Hậu điều kiện.** Trạng thái ứng dụng cập nhật; lưu trữ kéo theo thu hồi thông tin xác thực.

**Sự kiện phát ra.** EVT-15-02 (`app.state-changed`).

**Kiểm toán.** Có: sửa, lưu trữ, khôi phục.

**Quy tắc nghiệp vụ.** BR-15-009; BR-15-010; BR-15-034.

**Màn hình, API.** UI-15-10, UI-15-12; API-15-055, API-15-057, API-15-058, API-15-059, API-15-060.
:::

#### FR-15-027 · Cấp thông tin xác thực client_credentials sandbox

::: dac-ta
**Mục đích.** Cho ứng dụng có client ID và bí mật để lấy token gọi sandbox bằng OAuth 2.1 `client_credentials`, thay cho grant `password` của hệ cũ.

**Tác nhân, quyền.** DEV có vai trò `OWNER` hoặc `DEVELOPER` trên ứng dụng (`PERM-15-app`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-IAM-006; SRS cũ FR-15-008; SEC-24, SEC-25, SEC-33.

**Tiền điều kiện.** Ứng dụng `ACTIVE`; chưa đạt giới hạn thông tin xác thực.

**Kích hoạt.** Bấm "Cấp client_credentials" ở UI-15-13.

**Đầu vào.** `kind = CLIENT_CREDENTIALS`; `label` (T-NAME, tùy chọn); `ttlDays` (T-INT, mặc định `15.cred.ttl-days`, tối đa 180); `jwks` (tùy chọn, khóa công khai để dùng `private_key_jwt`).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra quyền, trạng thái ứng dụng (ERR-15-017) và giới hạn `15.cred.max-per-app` (ERR-15-016).
2. Hệ thống tạo client `sbx-{tenant}-{appCode}-{n}` ở realm `dh-dev` qua Admin API giới hạn, bật service account, chỉ cấp scope `sandbox:call`; token sống 5 phút.
3. Nếu có `jwks`, client dùng `private_key_jwt`; ngược lại dùng `client_secret_basic` (chỉ cho sandbox, SEC-24).
4. Hệ thống lưu bản ghi (`credentialId`, `clientId`, tiền tố bí mật 8 ký tự, `expiresAt`) và không lưu bí mật.
5. Hệ thống trả bí mật đúng một lần (FR-15-029) kèm địa chỉ lấy token và mẫu mã (FR-15-012).
6. Nếu bước 2 lỗi giữa chừng, hệ thống xóa client đã tạo, không để bản ghi nửa vời.

**Luồng thay thế.** Người dùng chọn `private_key_jwt`: không có bí mật để hiển thị, chỉ có `clientId`.

**Luồng ngoại lệ.**

- Vượt giới hạn: ERR-15-016 (422); "Ứng dụng đã đạt số thông tin xác thực tối đa ({n})."
- Ứng dụng không `ACTIVE`: ERR-15-017 (409).
- Keycloak lỗi: ERR-15-020 (503); "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau." (chi tiết riêng ở `detail`: Chưa cấp được thông tin xác thực do dịch vụ định danh tạm gián đoạn. Thử lại sau)
- Thiếu quyền: ERR-15-005 (403).

**Đầu ra.** `201`, `Cache-Control: no-store`; `credentialId`, `clientId`, `clientSecret` (chỉ lần này), `tokenUrl`, `expiresAt`.

**Kết quả.** Nhà phát triển có thể lấy token và gọi sandbox ngay.

**Hậu điều kiện.** Bản ghi `ACTIVE`; client tồn tại ở realm `dh-dev`.

**Sự kiện phát ra.** EVT-15-03 (`credential.issued`).

**Kiểm toán.** Có `SECRET_ISSUED`: người, ứng dụng, loại, `credentialId`, hạn; không có bí mật.

**Quy tắc nghiệp vụ.** BR-15-010; BR-15-011; BR-15-015.

**Màn hình, API.** UI-15-13; API-15-061, API-15-062.
:::

#### FR-15-028 · Cấp API key sandbox

::: dac-ta
**Mục đích.** Cho nhà phát triển cần cách đơn giản nhất để thử một khóa API ở sandbox, không phải cấu hình OAuth.

**Tác nhân, quyền.** DEV có vai trò `OWNER` hoặc `DEVELOPER` (`PERM-15-app`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-008; LGC-APIM-011 (liên quan: kiểu xác thực API key).

**Tiền điều kiện.** Như FR-15-027.

**Kích hoạt.** Bấm "Cấp API key" ở UI-15-13.

**Đầu vào.** `kind = API_KEY`; `label`; `ttlDays`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra như bước 1 của FR-15-027.
2. Hệ thống sinh khóa ngẫu nhiên 32 byte từ bộ sinh số an toàn, định dạng `dhsk_{tenant}_{chuỗi base64url}`.
3. Hệ thống lưu băm SHA-256 có muối và tiền tố 8 ký tự, không lưu khóa; bản ghi `ACTIVE` kèm `expiresAt`.
4. Hệ thống trả khóa đúng một lần (FR-15-029); khóa chỉ dùng ở tiêu đề `X-API-Key` của tuyến sandbox; `forward-auth` (API-15-082) đối chiếu băm.
5. Khóa không thể dùng ở production: tuyến production không biết khóa này.

**Luồng thay thế.** Người dùng cần OAuth: dùng FR-15-027.

**Luồng ngoại lệ.**

- Vượt giới hạn: ERR-15-016 (422).
- Ứng dụng không `ACTIVE`: ERR-15-017 (409).
- Thiếu quyền: ERR-15-005 (403).

**Đầu ra.** `201`, `Cache-Control: no-store`; `credentialId`, `apiKey` (chỉ lần này), `prefix`, `expiresAt`.

**Kết quả.** Khóa dùng được ngay ở sandbox.

**Hậu điều kiện.** Bản ghi `ACTIVE`, chỉ lưu băm.

**Sự kiện phát ra.** EVT-15-03.

**Kiểm toán.** Có `SECRET_ISSUED` như FR-15-027.

**Quy tắc nghiệp vụ.** BR-15-010; BR-15-011; BR-15-015.

**Màn hình, API.** UI-15-13; API-15-062.
:::

#### FR-15-029 · Hiển thị bí mật đúng một lần

::: dac-ta
**Mục đích.** Bảo đảm bí mật sandbox không nằm ở đâu ngoài tay người nhận: không ở cơ sở dữ liệu, nhật ký, bộ đệm, lịch sử trình duyệt.

**Tác nhân, quyền.** DEV vừa cấp hoặc xoay thông tin xác thực.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-008; SEC-32, SEC-33; NFR-15-009.

**Tiền điều kiện.** Vừa cấp (FR-15-027, 028) hoặc xoay (FR-15-030).

**Kích hoạt.** Phản hồi cấp phát tới trình duyệt.

**Đầu vào.** Không (dữ liệu trong phản hồi).

**Luồng xử lý chính.**

1. Phản hồi mang `Cache-Control: no-store`; BFF không ghi thân phản hồi của API cấp phát vào nhật ký (SEC-32).
2. Giao diện giữ bí mật chỉ trong bộ nhớ của trang, hiện trong ô bí mật của design system, có nút "Sao chép" và "Tải tệp `.env`"; không ghi `localStorage`, `sessionStorage`, URL.
3. Hộp thoại không đóng được cho tới khi người dùng đánh dấu "Tôi đã lưu bí mật".
4. Đóng hộp thoại hoặc rời trang: giao diện xóa bí mật khỏi bộ nhớ; không có chức năng xem lại.
5. Gọi lại cùng `Idempotency-Key` sau khi đã trả bí mật: hệ thống trả lỗi, không trả lại bí mật.

**Luồng thay thế.** Người dùng mất bí mật: xoay vòng (FR-15-030) để nhận bí mật mới.

**Luồng ngoại lệ.**

- Phát lại yêu cầu cấp: ERR-15-019 (410); "Bí mật chỉ hiện một lần và không xem lại được. Tạo thông tin xác thực mới nếu đã mất."

**Đầu ra.** Như FR-15-027, 028.

**Kết quả.** Người dùng nhận bí mật một lần và biết rõ phải lưu ngay.

**Hậu điều kiện.** Không có bản sao bí mật ở phía cổng.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có `SECRET_ISSUED` (đã ghi ở FR-15-027, 028).

**Quy tắc nghiệp vụ.** BR-15-011.

**Màn hình, API.** UI-15-13; API-15-062.
:::

#### FR-15-030 · Xoay vòng thông tin xác thực

::: dac-ta
**Mục đích.** Cho nhà phát triển thay bí mật định kỳ hoặc khi nghi lộ mà không làm gián đoạn phần mềm đang chạy thử.

**Tác nhân, quyền.** DEV có vai trò `OWNER` hoặc `DEVELOPER` (`PERM-15-app`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SEC-24, SEC-33.

**Tiền điều kiện.** Thông tin xác thực `ACTIVE`; ứng dụng `ACTIVE`.

**Kích hoạt.** Bấm "Xoay vòng" ở UI-15-13.

**Đầu vào.** `credentialId`; `graceHours` (T-INT, mặc định `15.cred.rotate-grace-hours`, 1…72).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra thông tin xác thực `ACTIVE` và giới hạn số lượng cho phép tạm thời thêm một bản.
2. Hệ thống tạo bản mới cùng loại (client mới hoặc khóa mới) và trả bí mật đúng một lần (FR-15-029).
3. Bản cũ chuyển `ROTATING`, còn hiệu lực trong `graceHours`, rồi tự `EXPIRED` và bị xóa khỏi Keycloak hoặc bảng băm.
4. Mọi lượt gọi dùng bản cũ trong thời gian chuyển tiếp được ghi chỉ số `dh_portal_cred_old_use_total` để người dùng thấy còn dùng bản cũ.
5. Hệ thống ghi kiểm toán, phát EVT-15-04.

**Luồng thay thế.** Người dùng chọn "Xoay và thu hồi bản cũ ngay" (`graceHours = 0`): chuyển thẳng `REVOKED`.

**Luồng ngoại lệ.**

- Thông tin xác thực không `ACTIVE`: ERR-15-018 (409); "Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này."
- Keycloak lỗi: ERR-15-020 (503); giữ nguyên bản cũ.

**Đầu ra.** `201`; bản mới (kèm bí mật một lần), bản cũ `ROTATING` kèm `rotatingUntil`.

**Kết quả.** Bí mật mới có hiệu lực, bản cũ còn dùng được trong thời gian ngắn.

**Hậu điều kiện.** Một bản `ACTIVE` mới, bản cũ `ROTATING`.

**Sự kiện phát ra.** EVT-15-04 (`credential.rotated`).

**Kiểm toán.** Có: người, ứng dụng, bản cũ, bản mới, `graceHours`.

**Quy tắc nghiệp vụ.** BR-15-011.

**Màn hình, API.** UI-15-13; API-15-063.
:::

#### FR-15-031 · Thu hồi và hết hạn thông tin xác thực

::: dac-ta
**Mục đích.** Cho nhà phát triển chấm dứt hiệu lực của thông tin xác thực khi nghi lộ hoặc không dùng, và bảo đảm khóa không sống vô hạn.

**Tác nhân, quyền.** DEV có vai trò `OWNER`, `DEVELOPER`; TA, SO qua FR-15-059; hệ thống (tác vụ hết hạn).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SEC-24, SEC-27.

**Tiền điều kiện.** Thông tin xác thực `ACTIVE` hoặc `ROTATING`.

**Kích hoạt.** Bấm "Thu hồi"; lưu trữ ứng dụng; tác vụ hằng giờ khi tới `expiresAt`.

**Đầu vào.** `credentialId`; `reason` (T-TEXT, tùy chọn).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra trạng thái cho phép (ERR-15-018).
2. Thu hồi: hệ thống xóa hoặc vô hiệu client ở realm `dh-dev`, đánh dấu bản ghi `REVOKED`, vô hiệu bộ đệm của `forward-auth` qua EVT-15-05 để lượt mới bị chặn trong ≤ 60 giây (NFR-15-007).
3. Hết hạn: tác vụ nhắc ở các mốc `15.cred.expiry-notice-days` (30, 7, 1 ngày) qua hộp thông báo và thư (chỉ liên kết), rồi chuyển `EXPIRED` khi tới hạn.
4. Hệ thống ghi kiểm toán và phát EVT-15-05.

**Luồng thay thế.** Lưu trữ ứng dụng thu hồi hàng loạt các thông tin xác thực của ứng dụng.

**Luồng ngoại lệ.**

- Đã thu hồi hoặc hết hạn: ERR-15-018 (409); "Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này." (chi tiết riêng ở `detail`: Thông tin xác thực đã {trạng thái})
- Keycloak lỗi khi thu hồi: ERR-15-020 (503); bản ghi vẫn đánh dấu `REVOKED` ở cổng để `forward-auth` chặn, hệ thống thử lại việc xóa client.

**Đầu ra.** `200`; thông tin xác thực với `status`.

**Kết quả.** Khóa bị thu hồi không còn dùng được ở sandbox sau tối đa 60 giây.

**Hậu điều kiện.** Bản ghi `REVOKED` hoặc `EXPIRED`.

**Sự kiện phát ra.** EVT-15-05 (`credential.revoked`, gồm cả hết hạn).

**Kiểm toán.** Có: người hoặc hệ thống, lý do.

**Quy tắc nghiệp vụ.** BR-15-010; BR-15-011.

**Màn hình, API.** UI-15-13; API-15-064.
:::

#### FR-15-032 · Xem tham chiếu thông tin xác thực production

::: dac-ta
**Mục đích.** Cho cán bộ đầu mối thấy định danh production của HTTT của mình đang ở trạng thái nào (còn hạn, sắp hết hạn) để chủ động xoay vòng ở PH-01, mà cổng không bao giờ cầm bí mật production.

**Tác nhân, quyền.** DEV là cán bộ SSO có ứng dụng liên kết HTTT (`PERM-15-app`); OR của tổ chức.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; BP-01; SEC-24; Q15-13.

**Tiền điều kiện.** Ứng dụng có `systemCode`; HTTT thuộc tổ chức của người dùng.

**Kích hoạt.** Mở tab "Xác thực" của ứng dụng ở UI-15-13.

**Đầu vào.** `appCode`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra người dùng là thành viên ứng dụng và thuộc tổ chức của HTTT (BR-15-015); nhà thầu `dh-dev` bị từ chối (BR-15-004).
2. Hệ thống đọc từ PH-01 (giao diện nội bộ, bộ đệm 5 phút) danh sách định danh production của HTTT.
3. Hệ thống hiển thị: `clientId`, phương thức (`tls_client_auth`, `private_key_jwt`, `client_secret_basic`), 16 ký tự đầu của dấu vân tay chứng thư, hạn, trạng thái (`ACTIVE`, `EXPIRING` khi còn dưới 30 ngày, `REVOKED`), thời điểm dùng gần nhất.
4. Hệ thống hiển thị liên kết "Xoay vòng hoặc nhận bí mật ở phân hệ Kết nạp" sang PH-01; không có bí mật, không có nút xem bí mật.
5. Hệ thống ghi kiểm toán lượt xem.

**Luồng thay thế.** HTTT chưa có định danh production: hiện hướng dẫn hoàn tất kết nạp (FR-15-046).

**Luồng ngoại lệ.**

- Không thuộc tổ chức hoặc nhà thầu: ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này."
- PH-01 lỗi: ERR-15-031 (502); "Chưa kết nối được dịch vụ kết nạp. Thử lại sau." (chi tiết riêng ở `detail`: Chưa tải được thông tin xác thực production. Thử lại sau)

**Đầu ra.** `200`; `items[]` (`clientId`, `method`, `certThumbprintPrefix`, `expiresAt`, `status`, `lastUsedAt`).

**Kết quả.** Cán bộ biết thông tin xác thực production còn hạn hay không, không cần hỏi quản trị.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người, HTTT.

**Quy tắc nghiệp vụ.** BR-15-004; BR-15-014; BR-15-015.

**Màn hình, API.** UI-15-13; API-15-065.
:::

#### FR-15-033 · Giao ứng dụng cho thành viên

::: dac-ta
**Mục đích.** Cho chủ ứng dụng quyết định ai được làm gì trên ứng dụng; đây là cách hiện thực "ứng dụng được giao" của vai trò nhà phát triển.

**Tác nhân, quyền.** `OWNER` của ứng dụng (`PERM-15-app`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; D02-08 `ROLE-DEVELOPER` (ứng dụng được giao).

**Tiền điều kiện.** Ứng dụng `ACTIVE` hoặc `SUSPENDED`.

**Kích hoạt.** Mở tab "Thành viên" ở UI-15-12.

**Đầu vào.** `userId` hoặc `email`; `role` (`OWNER`, `DEVELOPER`, `VIEWER`).

**Luồng xử lý chính.**

1. Hệ thống liệt kê thành viên trực tiếp và thành viên thừa hưởng từ nhóm sở hữu.
2. Chủ ứng dụng thêm người đã có tài khoản cổng cùng tenant; hệ thống tạo lời mời như FR-15-022.
3. Chủ đổi vai trò hoặc xóa thành viên trực tiếp; thành viên thừa hưởng từ nhóm chỉ đổi ở nhóm.
4. Hệ thống áp quyền: `OWNER` mọi việc kể cả giao người; `DEVELOPER` thử, cấp, xoay, thu hồi; `VIEWER` chỉ xem thống kê và nhật ký.
5. Không xóa được `OWNER` cuối cùng.

**Luồng thay thế.** Chuyển quyền `OWNER`: nâng người khác lên `OWNER` rồi hạ mình.

**Luồng ngoại lệ.**

- Đã là thành viên: ERR-15-027 (409); "Người này đã là thành viên hoặc đã có lời mời."
- Xóa chủ duy nhất: ERR-15-028 (422); "Phải còn ít nhất một chủ sở hữu."
- Không đủ quyền: ERR-15-005 (403).

**Đầu ra.** `200`; danh sách thành viên.

**Kết quả.** Quyền trên ứng dụng đúng người, đúng việc.

**Hậu điều kiện.** Quan hệ thành viên cập nhật.

**Sự kiện phát ra.** EVT-15-13.

**Kiểm toán.** Có: thêm, đổi vai trò, xóa.

**Quy tắc nghiệp vụ.** BR-15-009.

**Màn hình, API.** UI-15-12; API-15-066, API-15-067, API-15-068.
:::

### 6.7. Nhóm F · Sandbox và thử API

Nhóm F cho nhà phát triển gọi thử API ngay trên trang tài liệu mà không chạm dữ liệu thật. Sandbox có hai chế độ do chủ dịch vụ chọn: `MOCK` (cổng tự sinh phản hồi từ ví dụ và lược đồ) và `BACKEND` (chuyển tới backend thử do chủ dịch vụ khai báo). Thử trên production là ngoại lệ có kiểm soát, mặc định tắt. Lời gọi thử đi theo trình tự ở mục 2.4; thông tin xác thực không bao giờ rời Keycloak.

#### FR-15-034 · Khai báo sandbox của dịch vụ

::: dac-ta
**Mục đích.** Cho chủ dịch vụ chọn cách sandbox phục vụ API của mình: mô phỏng từ ví dụ, hay trỏ tới backend thử riêng.

**Tác nhân, quyền.** SV (○, API của tổ chức mình, theo đối tượng qua `PERM-15-content-write` của D02-08), TA, CA (`PERM-15-portal-admin`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; ADR-013.

**Tiền điều kiện.** API có phiên bản `PUBLISHED` hoặc `DEPRECATED` ở bản sao danh mục.

**Kích hoạt.** Mở UI-15-23 của API.

**Đầu vào.** Theo bảng dữ liệu vào của FR-15-034 dưới đây; `If-Match`.

**Luồng xử lý chính.**

1. Chủ dịch vụ chọn phiên bản và chế độ `MOCK`, `BACKEND` hoặc `OFF`.
2. Với `MOCK`, hệ thống kiểm tra đặc tả có ví dụ hoặc schema đủ để sinh phản hồi cho mọi thao tác và liệt kê thao tác thiếu (ERR-15-110 là cảnh báo ở bước này).
3. Với `BACKEND`, hệ thống kiểm tra `backendUrl` là HTTPS và nằm trong danh sách egress cho phép (ERR-15-119), thử kết nối đường `healthPath` và báo kết quả.
4. Bí mật tiêu đề của backend (nếu có) ghi một chiều vào OpenBao; không hiển thị lại.
5. Hệ thống lưu hồ sơ sandbox của phiên bản; ghi kiểm toán.

**Luồng thay thế.** `OFF`: API hiển thị "Chưa có sandbox", nút Thử bị ẩn.

**Luồng ngoại lệ.**

- Backend ngoài danh sách cho phép: ERR-15-119 (422); "Địa chỉ hệ thống thử không nằm trong danh sách cho phép."
- Thiếu cấu hình cho chế độ: ERR-15-120 (409); "Dịch vụ thiếu cấu hình cho chế độ {chế độ}." (chi tiết riêng ở `detail`: Chế độ {chế độ} cần khai báo {trường})
- Dịch vụ không đủ điều kiện (phiên bản đã ngừng): ERR-15-040 (422); "Dịch vụ này chưa đủ điều kiện cho thao tác này." (chi tiết riêng ở `detail`: Phiên bản này không cấu hình sandbox được)

**Đầu ra.** `200`, `ETag`; hồ sơ sandbox với `mode`, `lastHealthCheck`.

**Kết quả.** API có sandbox đúng chế độ chủ dịch vụ chọn.

**Hậu điều kiện.** Hồ sơ sandbox được lưu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người, API, phiên bản, chế độ, địa chỉ backend (không bí mật).

**Quy tắc nghiệp vụ.** BR-15-017; BR-15-018; BR-15-034.

**Màn hình, API.** UI-15-23; API-15-069, API-15-070.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `versionNo` | T-TEXT | Có | Phiên bản có trong bản sao | `1.0.0` |
| `mode` | T-ENUM | Có | `MOCK`, `BACKEND`, `OFF` | `MOCK` |
| `examplePolicy` | T-ENUM | Với `MOCK` | `FIRST`, `RANDOM` | `FIRST` |
| `mockLatencyMs` | T-INT | Không | 0…2000, mặc định 50 | `100` |
| `backendUrl` | T-URL | Với `BACKEND` | HTTPS, thuộc egress cho phép | `https://thu.hotich.t68.local/api` |
| `healthPath` | T-TEXT | Không | Bắt đầu bằng `/` | `/health` |
| `backendAuthHeader` | bí mật | Không | Ghi một chiều | (không hiển thị) |

: Dữ liệu vào của FR-15-034

#### FR-15-035 · Thử API trên sandbox

::: dac-ta
**Mục đích.** Cho nhà phát triển soạn một yêu cầu, gửi và xem phản hồi ngay trên trang tài liệu, để hiểu API trước khi viết mã.

**Tác nhân, quyền.** DEV (`PERM-15-try`) có ứng dụng `ACTIVE`.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; CMP-LAW-05; SEC-43.

**Tiền điều kiện.** Đã chấp nhận điều khoản; API có sandbox khác `OFF`; ứng dụng `ACTIVE`.

**Kích hoạt.** Bấm "Gửi" ở khung thử UI-15-06.

**Đầu vào.** Theo bảng dữ liệu vào của FR-15-035 dưới đây; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra người dùng là thành viên ứng dụng (ERR-15-005), điều khoản (ERR-15-010), ứng dụng `ACTIVE` (ERR-15-102), phiên bản cho thử (ERR-15-122).
2. Hệ thống kiểm tra yêu cầu khớp đặc tả: thao tác, tham số, schema thân (ERR-15-107), cỡ thân (ERR-15-105), bỏ tiêu đề cấm `Authorization`, `Cookie`, `Host` do người dùng gửi (ERR-15-121).
3. Hệ thống áp hạn mức (FR-15-039) và quét dữ liệu cá nhân thật (FR-15-038).
4. Hệ thống xin token ngắn hạn cho ứng dụng bằng trao đổi token ở Keycloak, gọi tuyến sandbox kèm `X-DH-Try-Id` và `traceparent`; `forward-auth` kiểm tra lại ứng dụng và hạn mức (API-15-082).
5. Hệ thống nhận phản hồi, cắt ở 1 MB: gần ngưỡng thì chỉ thêm cảnh báo vào `warnings[]` (HTTP 200); vượt cứng thì `bodyTruncated = true` và trả ERR-15-123 (413), khớp hợp đồng API-15-072, che trường nhạy cảm theo SEC-32, trả cho giao diện kèm trạng thái, độ trễ, tiêu đề.
6. Hệ thống ghi vết lượt thử (BR-15-023) và phát EVT-15-11.

**Luồng thay thế.** Gọi ngoài cổng bằng `curl` với thông tin xác thực đã cấp: đi thẳng vào tuyến sandbox, vẫn qua `forward-auth` và hạn mức, không ghi lịch sử trên giao diện.

**Luồng ngoại lệ.**

- Gateway sandbox lỗi: ERR-15-111 (503); "Cổng thử đang bảo trì. Thử lại sau." (chi tiết riêng ở `detail`: Sandbox tạm thời không phản hồi. Thử lại sau)
- Backend thử lỗi, quá hạn: ERR-15-109, ERR-15-108 (xem FR-15-037).
- Vượt hạn mức: ERR-15-103, ERR-15-104 (429).
- PH-13 không ghi được với API `RESTRICTED`, `SENSITIVE`: ERR-15-115 (503); "Chưa ghi được nhật ký nên không thử được lúc này." (chi tiết riêng ở `detail`: Hệ thống kiểm toán chưa sẵn sàng nên chưa thể thử API này)

**Đầu ra.** `200`; `tryId`, `status`, `latencyMs`, `headers`, `body` (đã che), `mode`, `warnings[]`.

**Kết quả.** Người dùng thấy phản hồi và biết nó từ MOCK hay BACKEND.

**Hậu điều kiện.** Bản ghi lượt thử; bộ đếm hạn mức cập nhật.

**Sự kiện phát ra.** EVT-15-11 (`try.executed`).

**Kiểm toán.** Có: người, ứng dụng, API, phiên bản, thao tác, môi trường, trạng thái, độ trễ, `traceId`; không ghi thân.

**Quy tắc nghiệp vụ.** BR-15-008; BR-15-016; BR-15-023; BR-15-024; BR-15-025; BR-15-026.

**Màn hình, API.** UI-15-06; API-15-071, API-15-072, API-15-073, API-15-082.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `appCode` | T-CODE | Có | Ứng dụng `ACTIVE` mà người dùng là thành viên | `datdai-thu-nghiem` |
| `apiCode`, `versionNo` | T-CODE, T-TEXT | Có | Phiên bản có sandbox | `tra-cuu-ho-tich`, `1.0.0` |
| `operationId` | T-ID | Có | Có trong đặc tả | `getBirthCertificate` |
| `environment` | T-ENUM | Có | `SANDBOX`, `PRODUCTION` | `SANDBOX` |
| `pathParams`, `query` | đối tượng | Theo đặc tả | Đúng kiểu | `{"id":"HT-0001"}` |
| `headers` | đối tượng | Không | Không chứa tiêu đề cấm | `{"Accept":"application/json"}` |
| `body` | JSON | Theo đặc tả | ≤ `15.try.max-body-kb` | `{"fullName":"Nguyen Van Mau"}` |

: Dữ liệu vào của FR-15-035

#### FR-15-036 · Chế độ sandbox MOCK

::: dac-ta
**Mục đích.** Cho API chưa có backend thử vẫn thử được: cổng tự sinh phản hồi đúng hình dạng từ đặc tả.

**Tác nhân, quyền.** Hệ thống (`portal-mock`, vai trò `portal-sandbox`) khi lượt thử tới API ở chế độ `MOCK`.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; Q15-07.

**Tiền điều kiện.** Hồ sơ sandbox `mode = MOCK`.

**Kích hoạt.** Lời gọi tới tuyến sandbox của thao tác ở chế độ `MOCK`.

**Đầu vào.** Thao tác, tham số, thân (đã qua FR-15-035); tiêu đề tùy chọn `X-DH-Mock-Status`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra lại yêu cầu theo đặc tả; sai thì trả `400` theo RFC 9457 với chi tiết như hệ thật.
2. Hệ thống chọn mã trạng thái: mặc định mã `2xx` đầu tiên của thao tác; `X-DH-Mock-Status` chọn mã khác có trong đặc tả.
3. Hệ thống chọn phản hồi: ví dụ đầu tiên (`FIRST`) hoặc ngẫu nhiên có hạt giống theo băm yêu cầu (`RANDOM`); thiếu ví dụ thì sinh từ schema (kiểu, `enum`, `format`, giới hạn); thiếu cả hai thì ERR-15-110.
4. Hệ thống chờ `mockLatencyMs` rồi trả phản hồi kèm `X-DH-Sandbox: mock`; không gọi hệ thống nào khác.

**Luồng thay thế.** Thao tác có `callbacks` hoặc tệp lớn: trả ví dụ cố định ngắn gọn.

**Luồng ngoại lệ.**

- Không sinh được phản hồi: ERR-15-110 (422); "Chưa sinh được phản hồi mẫu. Dịch vụ thiếu ví dụ hoặc lược đồ." (chi tiết riêng ở `detail`: Đặc tả thiếu ví dụ và lược đồ nên chưa mô phỏng được thao tác này)
- Yêu cầu không khớp đặc tả: ERR-15-107 (422); "Yêu cầu không khớp đặc tả: {chi tiết}."

**Đầu ra.** Phản hồi mô phỏng, tiêu đề `X-DH-Sandbox: mock`.

**Kết quả.** Nhà phát triển thấy phản hồi đúng hình dạng thật mà không có dữ liệu thật.

**Hậu điều kiện.** Không thay đổi dữ liệu ngoài bản ghi lượt thử.

**Sự kiện phát ra.** Không (EVT-15-11 do FR-15-035 phát).

**Kiểm toán.** Có (trong lượt thử).

**Quy tắc nghiệp vụ.** BR-15-016; BR-15-017.

**Màn hình, API.** UI-15-06; API-15-072.
:::

#### FR-15-037 · Chế độ sandbox BACKEND

::: dac-ta
**Mục đích.** Cho API có backend thử thật (không phải production) cho nhà phát triển thử với hành vi sát thực tế, như lỗi nghiệp vụ, trạng thái.

**Tác nhân, quyền.** Hệ thống (`portal-sandbox`: module `portal.mock` của `dh-connect` chuyển tiếp tới backend thử; APISIX chỉ giữ tuyến tĩnh và `forward-auth`, không chuyển tiếp tới backend).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; SEC-16, SEC-43.

**Tiền điều kiện.** Hồ sơ sandbox `mode = BACKEND`, backend sống.

**Kích hoạt.** Lời gọi tới tuyến sandbox của thao tác ở chế độ `BACKEND`.

**Đầu vào.** Yêu cầu đã qua FR-15-035; `backendUrl` của hồ sơ.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra lại `backendUrl` còn nằm trong danh sách egress cho phép ở thời điểm gọi (ERR-15-119).
2. `portal-sandbox` (không phải APISIX) chuyển tiếp yêu cầu tới backend thử qua egress gateway kèm `X-DH-Sandbox: backend`, `X-DH-App`, `X-DH-Try-Id`, `traceparent`; bỏ tiêu đề người dùng không được phép.
3. Hệ thống áp thời gian chờ `15.try.timeout-seconds` (mặc định 15 giây) và cỡ phản hồi tối đa.
4. Hệ thống đếm lỗi liên tiếp của backend: 5 lỗi trong 30 giây thì ngắt mạch 60 giây, các lượt thử trả ngay ERR-15-109 để không dồn tải.
5. Phản hồi được che trường nhạy cảm và trả về giao diện.

**Luồng thay thế.** Backend trả `4xx`, `5xx` nghiệp vụ: chuyển nguyên trạng cho người dùng, không tính là lỗi hạ tầng.

**Luồng ngoại lệ.**

- Backend quá hạn: ERR-15-108 (504); "Hệ thống thử không phản hồi trong {n} giây." (chi tiết riêng ở `detail`: Backend thử không phản hồi kịp. Thử lại hoặc báo chủ dịch vụ)
- Backend không với tới: ERR-15-109 (502); "Hệ thống thử trả lỗi." (chi tiết riêng ở `detail`: Không kết nối được backend thử của dịch vụ)
- Địa chỉ ngoài danh sách: ERR-15-119 (422).

**Đầu ra.** Phản hồi của backend (đã che), tiêu đề `X-DH-Sandbox: backend`.

**Kết quả.** Người dùng thử với hành vi sát thật mà không đụng production.

**Hậu điều kiện.** Không thay đổi dữ liệu của cổng.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có (trong lượt thử).

**Quy tắc nghiệp vụ.** BR-15-016; BR-15-018; BR-15-024.

**Màn hình, API.** UI-15-06; API-15-072.
:::

#### FR-15-038 · Dữ liệu mẫu tổng hợp và chặn dữ liệu cá nhân thật

::: dac-ta
**Mục đích.** Bảo đảm sandbox chỉ chứa dữ liệu tổng hợp: không ai vô tình dán số căn cước, số điện thoại, thư của người thật vào yêu cầu thử, theo Luật BVDLCN.

**Tác nhân, quyền.** Hệ thống áp dụng cho mọi lượt thử; DEV dùng nút "Điền dữ liệu mẫu".

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; CMP-LAW-05; CMP-LAW-04; SEC-38.

**Tiền điều kiện.** Yêu cầu thử đã qua kiểm tra khớp đặc tả.

**Kích hoạt.** Người dùng bấm "Điền dữ liệu mẫu" hoặc "Gửi".

**Đầu vào.** Thân, tham số, tiêu đề của yêu cầu thử.

**Luồng xử lý chính.**

1. Hệ thống quét giá trị chuỗi của yêu cầu theo bộ luật `PII-15-01…06` ở Phụ lục A.7 (căn cước 12 số, CMND 9 số, mã số thuế, số điện thoại, thư điện tử, số hộ chiếu), bỏ qua dải giả quy ước.
2. Nút "Điền dữ liệu mẫu" sinh giá trị tổng hợp theo kiểu và định dạng của trường (họ tên bộ tên giả, căn cước dải `000…`, điện thoại `0900000xxx`, thư `@example.gov.vn`).
3. Ở chế độ `BACKEND`, gặp mẫu nhận dạng thì hệ thống từ chối yêu cầu và chỉ ra trường (ERR-15-106); ở chế độ `MOCK`, hệ thống cảnh báo và vẫn cho gửi vì không có hệ thống nào nhận.
4. Hệ thống không lưu giá trị đã khớp mẫu vào lịch sử, bộ sưu tập hay nhật ký.

**Luồng thay thế.** Giá trị khớp mẫu nhưng là dải giả của dịch vụ khác: chủ dịch vụ khai thêm dải giả ở hồ sơ sandbox; Đợt 2 dùng bộ dải chung (Q15-09).

**Luồng ngoại lệ.**

- Có dữ liệu cá nhân thật: ERR-15-106 (422); "Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."

**Đầu ra.** Cảnh báo `warnings[]` hoặc lỗi `422` kèm tên trường (không kèm giá trị).

**Kết quả.** Sandbox không nhận dữ liệu cá nhân thật.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi từ chối (người, ứng dụng, mã luật, tên trường; không ghi giá trị).

**Quy tắc nghiệp vụ.** BR-15-016; BR-15-024.

**Màn hình, API.** UI-15-06; API-15-071.
:::

#### FR-15-039 · Hạn mức sandbox

::: dac-ta
**Mục đích.** Bảo vệ backend thử và hạ tầng khỏi lạm dụng, đồng thời cho nhà phát triển biết còn bao nhiêu lượt.

**Tác nhân, quyền.** Hệ thống; DEV xem hạn mức của mình.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; SEC-10.

**Tiền điều kiện.** Không.

**Kích hoạt.** Mọi lượt thử và mọi lời gọi tới tuyến sandbox.

**Đầu vào.** Danh tính người và ứng dụng; tham số `15.try.*`.

**Luồng xử lý chính.**

1. Hệ thống đếm trong Valkey theo cửa sổ trượt (script Lua nguyên tử; hạn mức theo người đếm ở `portal.try` khi gửi từ khung thử, hạn mức theo ứng dụng và theo tenant đếm ở API-15-082 nên áp cả lời gọi ngoài cổng): mỗi người `15.try.rate-per-user-min` (mặc định 30) lượt mỗi phút; mỗi ứng dụng `15.try.rate-per-app-day` (mặc định 3.000) lượt mỗi ngày; toàn tenant `15.try.rate-tenant-rps` (mặc định 100).
2. Hệ thống áp thêm cỡ thân tối đa `15.try.max-body-kb` (256) và thời gian chờ.
3. `forward-auth` áp cùng bộ đếm cho cả lời gọi ngoài cổng bằng thông tin xác thực.
4. Vượt thì trả `429` kèm `Retry-After`; mọi phản hồi có `X-RateLimit-Limit`, `X-RateLimit-Remaining`.
5. Khung thử hiện số lượt còn lại (API-15-074; tham số tùy chọn `appCode` chọn ứng dụng cần xem, mặc định ứng dụng đang chọn ở khung thử).

**Luồng thay thế.** TA nâng hạn mức riêng cho một ứng dụng trong biên của tham số trần (FR-15-057).

**Luồng ngoại lệ.**

- Vượt hạn mức người: ERR-15-103 (429); "Bạn đã vượt hạn mức thử mỗi phút. Thử lại sau {n} giây."
- Vượt hạn mức ứng dụng: ERR-15-104 (429); "Ứng dụng đã vượt hạn mức thử trong ngày." (chi tiết riêng ở `detail`: Ứng dụng đã dùng hết lượt thử hôm nay. Hạn mức làm mới lúc 00:00)
- Thân quá lớn: ERR-15-105 (413); "Nội dung gửi vượt {n} KB."

**Đầu ra.** `429` hoặc `413`; `Retry-After`; `GET /try/quota` trả số còn lại.

**Kết quả.** Sandbox không bị làm quá tải, người dùng biết giới hạn.

**Hậu điều kiện.** Bộ đếm cập nhật.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (chỉ số `dh_portal_try_throttled_total`).

**Quy tắc nghiệp vụ.** BR-15-025.

**Màn hình, API.** UI-15-06; API-15-074, API-15-082.
:::

#### FR-15-040 · Lịch sử thử và bộ sưu tập yêu cầu

::: dac-ta
**Mục đích.** Cho nhà phát triển xem lại các lượt thử gần đây, gửi lại nhanh và gom các yêu cầu hay dùng thành bộ sưu tập.

**Tác nhân, quyền.** DEV (`PERM-15-try`), về dữ liệu của chính mình.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-016.

**Tiền điều kiện.** Đã đăng nhập.

**Kích hoạt.** Mở UI-15-14.

**Đầu vào.** Bộ lọc `tu`, `den`, `api`, `ung-dung`, `ket-qua`; tên bộ sưu tập.

**Luồng xử lý chính.**

1. Hệ thống liệt kê lượt thử của người dùng trong `15.try.history-days` ngày (mặc định 30) gồm thời điểm, ứng dụng, API, thao tác, trạng thái, độ trễ.
2. Bản yêu cầu để gửi lại chỉ giữ cho lượt `SANDBOX` đã qua quét dữ liệu cá nhân, ≤ 16 KB; lượt `PRODUCTION` chỉ giữ siêu dữ liệu.
3. Người dùng bấm "Gửi lại": giao diện nạp yêu cầu vào khung thử.
4. Người dùng lưu yêu cầu vào bộ sưu tập (tối đa 50 bộ, mỗi bộ 100 yêu cầu), đổi tên, xóa.
5. Người dùng xóa toàn bộ lịch sử của mình; hệ thống xóa vật lý bản yêu cầu, giữ bản ghi kiểm toán.

**Luồng thay thế.** Chia sẻ bộ sưu tập cho nhóm: Đợt 3 (Q15-12).

**Luồng ngoại lệ.**

- Bộ sưu tập không phải của mình: ERR-15-001 (404).
- Vượt số bộ sưu tập: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Đã đạt số bộ sưu tập tối đa)

**Đầu ra.** `200`; `items[]`, bộ sưu tập.

**Kết quả.** Người dùng làm lại phép thử trong vài giây.

**Hậu điều kiện.** Lịch sử quá hạn bị xóa tự động.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với đọc; có với xóa toàn bộ lịch sử.

**Quy tắc nghiệp vụ.** BR-15-024; BR-15-034.

**Màn hình, API.** UI-15-14; API-15-075, API-15-076, API-15-077, API-15-078, API-15-079, API-15-080.
:::

#### FR-15-041 · Xuất Postman, Bruno, HTTP

::: dac-ta
**Mục đích.** Cho nhà phát triển mang bộ yêu cầu ra công cụ họ quen dùng.

**Tác nhân, quyền.** DEV (`PERM-15-try`).

**Mức ưu tiên, đợt.** C · Đợt 3.

**Truy vết.** REQ-15.

**Tiền điều kiện.** Có bộ sưu tập hoặc đang xem một API.

**Kích hoạt.** Bấm "Xuất" ở UI-15-14 hoặc trang tài liệu.

**Đầu vào.** `collectionId` hoặc `apiCode`, `versionNo`; `format` (`postman`, `bruno`, `http`).

**Luồng xử lý chính.**

1. Hệ thống dựng tệp từ các yêu cầu của bộ sưu tập hoặc toàn bộ thao tác của phiên bản.
2. Postman Collection v2.1 (`.json`), thư mục Bruno (`.zip`), hoặc tệp `.http`; địa chỉ gốc, token là biến môi trường.
3. Hệ thống chỉ ghi giá trị giữ chỗ `{{CLIENT_SECRET}}`, không bao giờ ghi bí mật thật.
4. Hệ thống trả tệp tải về.

**Luồng thay thế.** Xuất theo đặc tả của API không cần bộ sưu tập.

**Luồng ngoại lệ.**

- Định dạng không hỗ trợ: ERR-15-003 (400).
- Bộ sưu tập không phải của mình: ERR-15-001 (404).

**Đầu ra.** `200`; tệp với `Content-Disposition`.

**Kết quả.** Công cụ ngoài nạp được bộ yêu cầu.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-011; BR-15-024.

**Màn hình, API.** UI-15-14; API-15-081.
:::

#### FR-15-042 · Bật, tắt thử production theo dịch vụ

::: dac-ta
**Mục đích.** Cho phép, có kiểm soát và có thời hạn, nhà phát triển thử một API ở production, mặc định tắt vì mỗi lượt thử chạm hệ thống thật.

**Tác nhân, quyền.** Đề xuất: SV (○ API của mình, theo đối tượng qua `PERM-15-content-write`) hoặc TA, CA (`PERM-15-portal-admin`); duyệt: CA hoặc TA khác người đề xuất (`PERM-15-portal-admin`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007; FR-00-071; ADR-046.

**Tiền điều kiện.** `15.try.prod-enabled = true` của tenant; API `PUBLISHED`; `dataClass` là `PUBLIC` hoặc `INTERNAL`.

**Kích hoạt.** Đề xuất ở UI-15-23; duyệt ở "Việc của tôi".

**Đầu vào.** `apiCode`; `validDays` (T-INT, 1…`15.try.prod-max-days`, mặc định tối đa 90); `reason` (T-TEXT, bắt buộc); quyết định duyệt.

**Luồng xử lý chính.**

1. Người đề xuất nêu lý do và thời hạn; hệ thống kiểm tra điều kiện của dịch vụ (ERR-15-040) và tạo yêu cầu duyệt `TRY_PRODUCTION`.
2. Người duyệt khác người đề xuất xem thông tin và duyệt hoặc từ chối kèm ý kiến (ERR-15-023 nếu trùng người).
3. Duyệt: trạng thái `ENABLED` tới `validUntil`; từ chối: `OFF` kèm lý do.
4. Hết hạn hoặc `Tắt` bất kỳ lúc nào (một người có quyền đủ, không cần người thứ hai): `OFF`, các phiên thử đang mở bị chặn lượt kế tiếp.
5. Hệ thống ghi kiểm toán, phát EVT-15-10.

**Luồng thay thế.** Gia hạn là một đề xuất mới.

**Luồng ngoại lệ.**

- API `RESTRICTED`, `SENSITIVE` hoặc tenant tắt: ERR-15-040 (422); "Dịch vụ này chưa đủ điều kiện cho thao tác này."
- Người duyệt là người đề xuất: ERR-15-023 (403); "Người duyệt phải khác người soạn và người gửi duyệt." (chi tiết riêng ở `detail`: Bạn đã đề xuất nên không tự duyệt được)
- Thiếu lý do: ERR-15-003 (400).

**Đầu ra.** `200` hoặc `202` khi chờ duyệt; trạng thái `OFF`, `PENDING`, `ENABLED`, `validUntil`.

**Kết quả.** Chỉ những dịch vụ được duyệt mới cho thử production, và có hạn.

**Hậu điều kiện.** Bản ghi cho phép thử cập nhật.

**Sự kiện phát ra.** EVT-15-10 (`try.production-state-changed`).

**Kiểm toán.** Có: người đề xuất, người duyệt, lý do, thời hạn.

**Quy tắc nghiệp vụ.** BR-15-019; BR-15-020; BR-15-021.

**Màn hình, API.** UI-15-23; API-15-083, API-15-084, API-15-085, API-15-086.
:::

#### FR-15-043 · Thử API trên production

::: dac-ta
**Mục đích.** Cho nhà phát triển của đơn vị đã được cấp quyền kiểm tra một lời gọi đọc ở môi trường thật, khi sandbox chưa đủ để chẩn đoán.

**Tác nhân, quyền.** DEV (`PERM-15-try`) thuộc tổ chức có HTTT với đăng ký sử dụng `ACTIVE` của API.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-007, SRS cũ FR-15-015; CMP-LAW-05; SEC-24, SEC-60.

**Tiền điều kiện.** Dịch vụ `ENABLED` ở FR-15-042; người dùng là cán bộ CQNN (không phải `dh-dev`).

**Kích hoạt.** Người dùng chọn môi trường "Production" ở khung thử và xác nhận.

**Đầu vào.** Như FR-15-035 với `environment = PRODUCTION` và `systemCode`; xác nhận "Tôi hiểu đây là hệ thống thật".

**Luồng xử lý chính.**

1. Hệ thống kiểm tra dịch vụ `ENABLED` còn hạn (ERR-15-112), `dataClass` không phải `RESTRICTED`, `SENSITIVE` (ERR-15-114) và phương thức chỉ `GET`, `HEAD` (ERR-15-116).
2. Hệ thống kiểm tra HTTT của người dùng có đăng ký sử dụng `ACTIVE` của API ở PH-02 (ERR-15-113).
3. Hệ thống ghi kiểm toán đồng bộ vào PH-13 trước khi gọi; không ghi được thì từ chối (ERR-15-115).
4. Hệ thống xin token trao đổi 5 phút, thu hẹp vào phạm vi `api:{apiCode}:{planCode}` của đăng ký, đánh dấu `act` là người dùng (ERR-15-117 nếu Keycloak từ chối).
5. Hệ thống gọi tuyến production qua APISIX như mọi HTTT, áp hạn mức `15.try.prod-rate-per-user-min` (mặc định 10; ERR-15-118).
6. Hệ thống trả phản hồi cho người dùng, không lưu thân phản hồi; ghi kết quả vào kiểm toán.

**Luồng thay thế.** Không có.

**Luồng ngoại lệ.**

- Dịch vụ chưa bật: ERR-15-112 (403); "Dịch vụ này chưa bật thử trên môi trường thật." (chi tiết riêng ở `detail`: Thử trên production chưa được bật cho dịch vụ này)
- Không có đăng ký sử dụng: ERR-15-113 (403); "Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này."
- Người dùng `dh-dev` (không thuộc HTTT nào): ERR-15-113 như trên, không dùng ERR-15-005, để thông báo không lộ lý do cấu trúc; giao diện đã ẩn nút thử production.
- Danh mục quá 24 giờ chưa đồng bộ (BR-15-033): ERR-15-112 (403) như dịch vụ chưa bật, chi tiết riêng ở `detail`: Danh mục dịch vụ chưa được đồng bộ trong 24 giờ nên tạm ẩn thử production; không thêm mã lỗi riêng.
- Dữ liệu nhạy cảm: ERR-15-114 (403); "Dịch vụ có dữ liệu nhạy cảm không cho thử trên môi trường thật."
- Kiểm toán lỗi: ERR-15-115 (503); "Chưa ghi được nhật ký nên không thử được lúc này." (chi tiết riêng ở `detail`: Hệ thống kiểm toán chưa sẵn sàng nên chưa thể thử trên production)
- Phương thức bị chặn: ERR-15-116 (422); "Phương thức {phương thức} không được phép ở môi trường này." (chi tiết riêng ở `detail`: Chỉ được thử phương thức GET và HEAD trên production)

**Đầu ra.** `200`; như FR-15-035, thêm `environment = PRODUCTION`.

**Kết quả.** Người dùng kiểm tra được lời gọi đọc thật, mọi lượt đều có dấu vết.

**Hậu điều kiện.** Bản ghi kiểm toán lượt thử; không lưu thân phản hồi.

**Sự kiện phát ra.** EVT-15-11.

**Kiểm toán.** Có đồng bộ: người, HTTT, API, thao tác, trạng thái, `traceId`, `dataClass`.

**Quy tắc nghiệp vụ.** BR-15-019; BR-15-020; BR-15-022; BR-15-023; BR-15-024.

**Màn hình, API.** UI-15-06; API-15-072.
:::

### 6.8. Nhóm G · Đăng ký sử dụng và điểm vào nghiệp vụ

Nhóm G nối cổng với ba nghiệp vụ thật: đăng ký sử dụng API production (PH-02), kết nạp HTTT (PH-01) và công bố API (PH-02). Cổng chỉ là cửa vào và nơi theo dõi: biểu mẫu thu thập, ủy thác sang phân hệ chủ trì bằng danh tính của chính người dùng, rồi đọc trạng thái về; cổng không duyệt, không giữ bản sao quyết định (BR-15-014). Điều này giữ nguyên ranh giới "không thay API Manager" của SRS cũ.

#### FR-15-044 · Gửi đăng ký sử dụng API production

::: dac-ta
**Mục đích.** Cho cán bộ đầu mối đi từ trang tài liệu một API sang đăng ký sử dụng nó cho HTTT của đơn vị chỉ bằng vài bước, không qua công văn.

**Tác nhân, quyền.** OR (○) có `PERM-02-subscribe`, TA; nhà phát triển không phải đầu mối dùng nút "Nhờ đầu mối đăng ký".

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; BP-01; SRS cũ FR-15-012; FR-02-046; LGC-APIM-016 (liên quan).

**Tiền điều kiện.** Đã đăng nhập bằng tài khoản cán bộ; đơn vị có HTTT `ACTIVE` ở PH-01.

**Kích hoạt.** Bấm "Đăng ký sử dụng" ở UI-15-04 hoặc UI-15-15.

**Đầu vào.** Như bảng dữ liệu vào của FR-02-046: `apiCode`, `versionNo`, `planCode`, `systemCode`, `purpose`, `expectedDailyCalls`, `operations[]`, `legalBasis`, `termsAccepted`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra người dùng là cán bộ có quyền đăng ký của tổ chức (ERR-15-032) và có ít nhất một HTTT `ACTIVE` của tổ chức.
2. Wizard dẫn qua chọn phiên bản, gói, HTTT, mục đích, khối lượng, căn cứ pháp lý; điều khoản và SLA của gói lấy từ bản sao danh mục.
3. Hệ thống ủy thác bằng cách gọi API đăng ký sử dụng của PH-02 (API-02-058) kèm danh tính của người dùng; PH-02 kiểm tra và tạo đăng ký.
4. Hệ thống hiển thị kết quả PH-02 trả về (`PENDING` hoặc `ACTIVE`, cảnh báo) và liên kết sang theo dõi (FR-15-045).
5. Lỗi nghiệp vụ của PH-02 được chuyển nguyên văn tiếng Việt tới người dùng.

**Luồng thay thế.** Người dùng là nhà thầu hoặc không phải đầu mối: nút "Nhờ đầu mối đăng ký" tạo phiếu hỗ trợ loại `ACCESS_REQUEST` tới đầu mối của tổ chức (FR-15-054).

**Luồng ngoại lệ.**

- Không có quyền đăng ký hoặc không có HTTT hoạt động: ERR-15-032 (422); "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này." (chi tiết riêng ở `detail`: Chỉ cán bộ đầu mối của đơn vị có hệ thống đã kết nạp mới đăng ký sử dụng được)
- PH-02 không khả dụng: ERR-15-030 (502); "Chưa kết nối được dịch vụ danh mục." (chi tiết riêng ở `detail`: Chưa gửi được đăng ký vì dịch vụ danh mục tạm gián đoạn. Thử lại sau)
- Lỗi nghiệp vụ của PH-02: chuyển nguyên mã `ERR-02-*` và câu của PH-02.

**Đầu ra.** `201` hoặc mã của PH-02; đăng ký với `status`, `reviewRequestId`, `warnings[]`.

**Kết quả.** Đăng ký sử dụng được gửi đúng quy trình và người dùng biết ai sẽ duyệt.

**Hậu điều kiện.** Đăng ký tồn tại ở PH-02; cổng không giữ bản sao.

**Sự kiện phát ra.** EVT-02-09 do PH-02 phát; cổng không phát.

**Kiểm toán.** Có: người, API, HTTT; kiểm toán nghiệp vụ nằm ở PH-02.

**Quy tắc nghiệp vụ.** BR-15-004; BR-15-014.

**Màn hình, API.** UI-15-15; API-15-087.
:::

#### FR-15-045 · Theo dõi đăng ký sử dụng

::: dac-ta
**Mục đích.** Cho người gửi và đầu mối thấy đăng ký đang ở đâu và việc cần làm tiếp, không phải hỏi.

**Tác nhân, quyền.** OR (○), TA, người gửi.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; BP-01; FR-02-049, FR-02-050, FR-02-051.

**Tiền điều kiện.** Có đăng ký của HTTT thuộc tổ chức người dùng.

**Kích hoạt.** Mở `/dang-ky-su-dung`.

**Đầu vào.** Bộ lọc `trang-thai`, `api`, `he-thong`; `subscriptionId`.

**Luồng xử lý chính.**

1. Hệ thống đọc từ PH-02 danh sách đăng ký theo HTTT thuộc tổ chức người dùng, kèm trạng thái `PENDING`, `ACTIVE`, `SUSPENDED`, `REJECTED`, `CANCELLED`, `REVOKED`, `EXPIRED`.
2. Chi tiết hiển thị dòng thời gian: gửi, duyệt, lý do từ chối nếu có, thời hạn, phạm vi được cấp, ngày rà soát tiếp theo.
3. Khi `ACTIVE`, hệ thống hiển thị liên kết tới tham chiếu thông tin xác thực production (FR-15-032) và nút "Thử trên production" nếu dịch vụ cho phép (FR-15-043).
4. Người gửi hủy đăng ký `PENDING` bằng cách ủy thác API hủy của PH-02.
5. Thay đổi trạng thái (EVT-02-10, EVT-02-11) tạo thông báo ở hộp thông báo (FR-15-052).

**Luồng thay thế.** Đăng ký `EXPIRED` sắp tới hạn rà soát: nhắc gia hạn ở PH-02.

**Luồng ngoại lệ.**

- Đăng ký ngoài tổ chức: ERR-15-001 (404).
- PH-02 lỗi: ERR-15-030 (502); "Chưa kết nối được dịch vụ danh mục." (chi tiết riêng ở `detail`: Chưa tải được danh sách đăng ký. Thử lại sau)
- Hủy khi không còn `PENDING`: lỗi của PH-02 chuyển nguyên văn.

**Đầu ra.** `200`; `items[]`, chi tiết dòng thời gian.

**Kết quả.** Người dùng biết chính xác trạng thái và bước kế tiếp.

**Hậu điều kiện.** Không thay đổi dữ liệu (trừ hủy ở PH-02).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có với hủy; không với xem.

**Quy tắc nghiệp vụ.** BR-15-014.

**Màn hình, API.** UI-15-15; API-15-088, API-15-089, API-15-090.
:::

#### FR-15-046 · Điểm vào kết nạp HTTT (F-01)

::: dac-ta
**Mục đích.** Cho cán bộ đầu mối nộp hồ sơ kết nạp HTTT thành viên từ cổng và theo dõi nó, thay cho chuỗi công văn; quyết định và cấp định danh do PH-01 thực hiện.

**Tác nhân, quyền.** OR (○) có `PERM-01-submit`, TA.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; BP-01; SRS cũ FR-15-012; LGC-APIM-019, LGC-APIM-020 (liên quan, PH-01 chính).

**Tiền điều kiện.** Đã đăng nhập bằng tài khoản cán bộ.

**Kích hoạt.** Mở `/ket-nap`.

**Đầu vào.** Theo biểu mẫu của PH-01: tổ chức, HTTT, đầu mối, cấp độ ATTT, mục đích, căn cứ pháp lý; cổng nạp lược đồ biểu mẫu từ PH-01.

**Luồng xử lý chính.**

1. Hệ thống nạp lược đồ biểu mẫu kết nạp từ PH-01 (bộ đệm 10 phút) và dựng wizard từ lược đồ.
2. Người dùng điền; hệ thống kiểm tra sơ bộ theo lược đồ (lỗi theo trường, ERR-15-003).
3. Hệ thống ủy thác API tạo và gửi hồ sơ của PH-01 kèm danh tính người dùng, `Idempotency-Key`.
4. Hệ thống hiển thị mã hồ sơ, trạng thái (nháp, chờ duyệt, bổ sung, từ chối, đã kết nạp) đọc từ PH-01.
5. Khi PH-01 duyệt, hệ thống hiện hướng dẫn nhận định danh production qua kênh của PH-01 (không hiện bí mật ở cổng, BR-15-015) và gợi ý tạo ứng dụng sandbox liên kết HTTT.

**Luồng thay thế.** Hồ sơ cần bổ sung: người dùng mở lại hồ sơ và gửi lại.

**Luồng ngoại lệ.**

- PH-01 không khả dụng: ERR-15-031 (502); "Chưa kết nối được dịch vụ kết nạp. Thử lại sau." (chi tiết riêng ở `detail`: Dịch vụ kết nạp tạm gián đoạn. Hồ sơ nháp của bạn vẫn được giữ, thử lại sau)
- Không phải đầu mối: ERR-15-032 (422); "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này." (chi tiết riêng ở `detail`: Chỉ cán bộ đầu mối của đơn vị mới nộp hồ sơ kết nạp)
- Lỗi theo trường của PH-01: hiển thị dưới từng trường.

**Đầu ra.** `201`; `applicationId`, `status`.

**Kết quả.** Hồ sơ vào đúng quy trình kết nạp, người dùng theo dõi được.

**Hậu điều kiện.** Hồ sơ ở PH-01.

**Sự kiện phát ra.** Không (PH-01 phát).

**Kiểm toán.** Có: người, hồ sơ; kiểm toán nghiệp vụ ở PH-01.

**Quy tắc nghiệp vụ.** BR-15-014; BR-15-015.

**Màn hình, API.** UI-15-16; API-15-091, API-15-092, API-15-093.
:::

#### FR-15-047 · Điểm vào công bố API (F-02)

::: dac-ta
**Mục đích.** Cho chủ dịch vụ nộp đặc tả OpenAPI của API mình muốn công bố ngay từ cổng và theo dõi tiến trình tới khi API xuất hiện ở danh mục; duyệt công bố do PH-02.

**Tác nhân, quyền.** SV (○) có `PERM-02-create`, `PERM-02-submit`; TA.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-013; FR-02-010, FR-02-011, FR-02-034.

**Tiền điều kiện.** Người dùng là chủ dịch vụ của tổ chức; HTTT cung cấp `ACTIVE`.

**Kích hoạt.** Mở `/cong-bo/moi`.

**Đầu vào.** Tệp hoặc URL OpenAPI 3.1; mô tả nghiệp vụ; `systemCode`; `dataClass`.

**Luồng xử lý chính.**

1. Người dùng nạp đặc tả; hệ thống chuyển tệp quét mã độc (SEC-45) rồi ủy thác cho PH-02 tạo API và phiên bản `DRAFT`.
2. Hệ thống hiển thị kết quả kiểm tra đặc tả của PH-02 (lớp 1, lớp 2, quét bí mật, dữ liệu cá nhân thật) theo từng lỗi.
3. Người dùng sửa và nạp lại tới khi đạt; khi đủ điều kiện, người dùng bấm "Gửi duyệt" ủy thác cho PH-02.
4. Hệ thống đọc trạng thái `DRAFT`, `PENDING`, `PUBLISHED` của phiên bản và hiển thị dòng thời gian; không có nút duyệt ở cổng.
5. Khi `PUBLISHED` và `portalPublished`, API xuất hiện ở danh mục qua đồng bộ (FR-15-001).

**Luồng thay thế.** Liên kết "Mở ở PH-02" cho thao tác nâng cao (gói, backend).

**Luồng ngoại lệ.**

- Không phải chủ dịch vụ: ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này." (chi tiết riêng ở `detail`: Chỉ chủ dịch vụ của đơn vị mới công bố được API)
- Đặc tả không hợp lệ: lỗi từng dòng của PH-02 hiển thị tại chỗ.
- PH-02 không khả dụng: ERR-15-030 (502).

**Đầu ra.** `202`; `publicationId`, `status`, `lintResults[]`.

**Kết quả.** Chủ dịch vụ đưa API vào quy trình công bố mà không rời cổng.

**Hậu điều kiện.** Phiên bản ở PH-02.

**Sự kiện phát ra.** Không (PH-02 phát).

**Kiểm toán.** Có: người, API; kiểm toán nghiệp vụ ở PH-02.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-014.

**Màn hình, API.** UI-15-17; API-15-094, API-15-095, API-15-096.
:::

### 6.9. Nhóm H · Theo dõi của nhà phát triển

Nhóm H cho nhà phát triển thấy ứng dụng của mình hoạt động ra sao và không bị bỏ sót thay đổi của API mình dùng. Số liệu và nhật ký lấy từ PH-13; cổng không tự lưu chỉ số.

#### FR-15-048 · Bảng điều khiển cá nhân

::: dac-ta
**Mục đích.** Cho người dùng một màn hình tóm tắt việc của mình: ứng dụng, thông tin xác thực sắp hết hạn, đăng ký chờ duyệt, thử gần đây, thông báo.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-016.

**Tiền điều kiện.** Đã đăng nhập.

**Kích hoạt.** Mở `/tong-quan`.

**Đầu vào.** Không.

**Luồng xử lý chính.**

1. Hệ thống tổng hợp từ dữ liệu của cổng: số ứng dụng `ACTIVE`, thông tin xác thực hết hạn trong 30 ngày, lượt thử 24 giờ và tỷ lệ lỗi.
2. Hệ thống tổng hợp từ PH-02 (nếu là cán bộ): đăng ký chờ duyệt, đăng ký sắp hết hạn rà soát.
3. Hệ thống tổng hợp API đang theo dõi có thay đổi chưa đọc (FR-15-051).
4. Hệ thống hiển thị thông báo chưa đọc, phiếu hỗ trợ đang mở.
5. Mỗi thẻ có liên kết tới nơi xử lý; thẻ nào nguồn lỗi thì hiện trạng thái "Chưa tải được" riêng, không làm hỏng cả trang.

**Luồng thay thế.** Người dùng mới: hiện chuỗi bước "Tạo ứng dụng, cấp thông tin xác thực, thử API đầu tiên".

**Luồng ngoại lệ.**

- Nguồn PH-02 hoặc PH-13 lỗi: thẻ tương ứng hiện "Chưa tải được." ERR-15-030, ERR-15-039 chỉ ghi nhật ký.

**Đầu ra.** `200`; các thẻ `apps`, `credentialsExpiring`, `tries`, `subscriptions`, `followed`, `inbox`, `tickets`.

**Kết quả.** Người dùng nắm việc trong một màn hình.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-009.

**Màn hình, API.** UI-15-18; API-15-097.
:::

#### FR-15-049 · Thống kê lượt gọi và lỗi theo ứng dụng

::: dac-ta
**Mục đích.** Cho nhà phát triển thấy ứng dụng của mình gọi bao nhiêu, lỗi bao nhiêu, chậm ở đâu, để tự chẩn đoán trước khi hỏi hỗ trợ.

**Tác nhân, quyền.** DEV là thành viên ứng dụng (`PERM-15-app`), kể cả `VIEWER`.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-022 (phần nhà phát triển); SRS cũ FR-15-016.

**Tiền điều kiện.** Ứng dụng có hoạt động sandbox; PH-13 khả dụng.

**Kích hoạt.** Mở tab "Thống kê" ở UI-15-12.

**Đầu vào.** `khoang` (`24h`, `7d`, `30d`), `api` (tùy chọn).

**Luồng xử lý chính.**

1. Hệ thống kiểm tra người dùng là thành viên ứng dụng (ERR-15-005).
2. Hệ thống đọc từ PH-13 (scope `metrics:portal-read`) các chỉ số của đúng nhãn `app_code`: số lượt, tỷ lệ theo nhóm mã trạng thái, độ trễ p50, p95, theo API và theo thời gian.
3. Với ứng dụng liên kết HTTT, hệ thống hiển thị thêm tổng hợp production của HTTT (số lượt, tỷ lệ lỗi) nếu PH-13 cung cấp, không có chi tiết từng lời gọi.
4. Hệ thống trả biểu đồ chuỗi thời gian với độ phân giải theo khoảng chọn.

**Luồng thay thế.** Chưa có hoạt động: hiện hướng dẫn gọi thử đầu tiên.

**Luồng ngoại lệ.**

- PH-13 lỗi: ERR-15-039 (502); "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
- Không phải thành viên: ERR-15-005 (403); "Bạn không có quyền thực hiện thao tác này."

**Đầu ra.** `200`; `series[]`, `totals`, `byApi[]`.

**Kết quả.** Nhà phát triển thấy ứng dụng hoạt động thế nào.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-009; BR-15-024.

**Màn hình, API.** UI-15-12; API-15-098.
:::

#### FR-15-050 · Nhật ký gọi của ứng dụng đã che dữ liệu

::: dac-ta
**Mục đích.** Cho nhà phát triển xem từng lời gọi của ứng dụng sandbox mình để tìm nguyên nhân lỗi, phần nhà phát triển của chức năng xem log theo Application ở hệ cũ.

**Tác nhân, quyền.** DEV là thành viên ứng dụng (`PERM-15-app`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-022 (phần nhà phát triển); SEC-32.

**Tiền điều kiện.** Ứng dụng có lượt gọi trong 30 ngày.

**Kích hoạt.** Mở tab "Nhật ký" ở UI-15-12.

**Đầu vào.** `tu`, `den`, `api`, `trang-thai`, `trace`; `logId` cho chi tiết.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra quyền thành viên ứng dụng.
2. Hệ thống đọc từ PH-13 các bản ghi nhật ký của đúng `app_code`, tối đa 30 ngày.
3. Mỗi bản ghi gồm thời điểm, phương thức, đường dẫn đã che tham số truy vấn, mã trạng thái, độ trễ, `traceId`, địa chỉ nguồn che octet cuối; không có thân yêu cầu, thân phản hồi, tiêu đề `Authorization`.
4. Chi tiết một bản ghi hiển thị thêm thao tác, mã lỗi RFC 9457 và liên kết tới đoạn tài liệu liên quan.
5. Nhật ký production của HTTT không hiển thị ở cổng; xem ở PH-13.

**Luồng thay thế.** Lọc theo `trace` để xem một lượt thử cụ thể từ khung thử.

**Luồng ngoại lệ.**

- PH-13 lỗi: ERR-15-039 (502); "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
- Bản ghi không thuộc ứng dụng: ERR-15-001 (404).

**Đầu ra.** `200`; `items[]`, `page`, `size`; chi tiết bản ghi.

**Kết quả.** Nhà phát triển truy được nguyên nhân lỗi mà không lộ dữ liệu.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-009; BR-15-024.

**Màn hình, API.** UI-15-12; API-15-099, API-15-100.
:::

#### FR-15-051 · Đăng ký nhận thông báo thay đổi API

::: dac-ta
**Mục đích.** Cho nhà phát triển theo dõi một API để được báo khi nó có phiên bản mới, sắp ngừng hoặc đổi SLA, thay vì tự đọc lại tài liệu.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; FR-02-057; EVT-02-12; FR-00-061.

**Tiền điều kiện.** API nằm trong tập người dùng được thấy.

**Kích hoạt.** Bấm "Theo dõi" ở UI-15-04; hoặc EVT-02-12 tới.

**Đầu vào.** `apiCode`; `channels[]` (`IN_APP`, `EMAIL`); `kinds[]` (loại thông báo của PH-02).

**Luồng xử lý chính.**

1. Người dùng bật theo dõi; hệ thống lưu EN-15-14 với kênh và loại.
2. Người dùng có đăng ký `ACTIVE` của API tự động được theo dõi các loại bắt buộc (BR-15-027).
3. Khi nhận EVT-02-12, hệ thống tìm người theo dõi và người thuộc tổ chức có đăng ký liên quan, gộp trùng.
4. Hệ thống tạo thông báo ở hộp thông báo (FR-15-052) và gửi thư chỉ chứa liên kết (FR-00-062) theo kênh đã chọn.
5. Người dùng tắt theo dõi các loại thông tin; loại bắt buộc không tắt được.

**Luồng thay thế.** Theo dõi theo phiên bản cụ thể.

**Luồng ngoại lệ.**

- API ngoài tầm: ERR-15-001 (404).
- Tắt loại bắt buộc: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Loại thông báo này là bắt buộc nên không tắt được)

**Đầu ra.** `200`; cấu hình theo dõi.

**Kết quả.** Nhà phát triển không bỏ sót thay đổi quan trọng.

**Hậu điều kiện.** Bản ghi theo dõi cập nhật.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-027.

**Màn hình, API.** UI-15-19; API-15-101, API-15-102, API-15-103.
:::

#### FR-15-052 · Hộp thông báo

::: dac-ta
**Mục đích.** Gom mọi thông báo của cổng vào một chỗ: thay đổi API, lời mời nhóm, hạn thông tin xác thực, kết quả đăng ký, phản hồi hỗ trợ.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; FR-00-060, FR-00-062.

**Tiền điều kiện.** Đã đăng nhập.

**Kích hoạt.** Bấm biểu tượng chuông; mở `/tai-khoan/thong-bao`.

**Đầu vào.** Bộ lọc `loai`, `da-doc`; `messageId`.

**Luồng xử lý chính.**

1. Hệ thống tạo thông báo từ các nguồn: EVT-02-10, 11, 12; lời mời nhóm; nhắc hạn thông tin xác thực; trả lời phiếu hỗ trợ; kết quả duyệt tài khoản.
2. Hệ thống hiển thị số chưa đọc ở thanh trên (API-15-140, nhẹ hơn tải danh sách) và danh sách có phân trang, mới nhất trước.
3. Người dùng đánh dấu đã đọc từng thông báo hoặc tất cả; bấm vào để tới nơi xử lý.
4. Thông báo bắt buộc (hạn thông tin xác thực, điều khoản mới, ngừng dịch vụ) có nhãn và không tắt được.
5. Thông báo lưu 90 ngày rồi xóa; số chưa đọc cập nhật bằng truy vấn định kỳ 60 giây.

**Luồng thay thế.** Người dùng chọn kênh thư theo loại ở hồ sơ (FR-15-021).

**Luồng ngoại lệ.**

- Thông báo không phải của mình: ERR-15-001 (404).

**Đầu ra.** `200`; `items[]`, `unreadCount`.

**Kết quả.** Người dùng không bỏ lỡ việc cần làm.

**Hậu điều kiện.** Trạng thái đã đọc cập nhật.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-027.

**Màn hình, API.** UI-15-19; API-15-104, API-15-105, API-15-106, API-15-140.
:::

### 6.10. Nhóm I · Hỗ trợ và phản hồi

Nhóm I thay kênh hỗ trợ qua điện thoại và thư bằng kênh có hồ sơ: câu hỏi gắn với API, báo lỗi tài liệu, phiếu hỗ trợ chuyển đúng chủ dịch vụ, có hạn trả lời. Nội dung hỏi đáp và phiếu là văn bản thuần, không Markdown, để tránh chèn mã.

#### FR-15-053 · Hỏi đáp, báo lỗi tài liệu, đánh giá trang

::: dac-ta
**Mục đích.** Cho nhà phát triển đặt câu hỏi công khai dưới một API, báo lỗi tài liệu và cho biết trang hướng dẫn có hữu ích không, giúp chủ dịch vụ cải thiện tài liệu.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập; chủ dịch vụ trả lời (`PERM-15-support`).

**Mức ưu tiên, đợt.** C · Đợt 3.

**Truy vết.** REQ-15; SRS cũ FR-15-009.

**Tiền điều kiện.** API hoặc trang nằm trong tầm nhìn của người dùng.

**Kích hoạt.** Bấm "Hỏi đáp", "Báo lỗi tài liệu" hoặc nút hữu ích ở UI-15-04, UI-15-07.

**Đầu vào.** `subject` (T-TEXT ≤ 150), `body` (T-TEXT ≤ 2000, văn bản thuần), `kind` (`QUESTION`, `DOC_ERROR`, `FEEDBACK`), `operationId` tùy chọn; đánh giá `up` hoặc `down` kèm `comment`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra tần suất tối đa 10 bài mỗi ngày mỗi người (ERR-15-037).
2. Câu hỏi hiển thị dưới API cho người dùng đã đăng nhập, theo tên hiển thị; chủ dịch vụ và người khác trả lời.
3. Báo lỗi tài liệu tạo phiếu loại `DOC_ERROR` gửi chủ dịch vụ (FR-15-054) kèm thao tác liên quan.
4. Đánh giá trang lưu một phiếu mỗi người mỗi trang; thống kê tổng hợp hiện cho người quản lý nội dung.
5. Chủ dịch vụ đánh dấu câu hỏi đã giải quyết và có thể ghim câu trả lời.

**Luồng thay thế.** Câu hỏi riêng tư (có thông tin tổ chức): chuyển thành phiếu hỗ trợ.

**Luồng ngoại lệ.**

- Vượt tần suất: ERR-15-037 (429); "Bạn gửi quá nhiều. Thử lại sau {n} phút."
- Nội dung trống hoặc quá dài: ERR-15-003 (400).

**Đầu ra.** `201`; bài hỏi, phiếu hoặc đánh giá.

**Kết quả.** Phản hồi đến đúng chủ dịch vụ.

**Hậu điều kiện.** Bài, phiếu hoặc đánh giá được lưu.

**Sự kiện phát ra.** EVT-15-12 khi tạo phiếu `DOC_ERROR`.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-15-030.

**Màn hình, API.** UI-15-04, UI-15-07, UI-15-20; API-15-107, API-15-108, API-15-109.
:::

#### FR-15-054 · Gửi yêu cầu hỗ trợ cho chủ dịch vụ

::: dac-ta
**Mục đích.** Cho nhà phát triển gửi một yêu cầu hỗ trợ có hồ sơ tới đúng người phụ trách API, thay cho điện thoại và thư.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; BP-01.

**Tiền điều kiện.** Đã đăng nhập.

**Kích hoạt.** Bấm "Hỗ trợ" hoặc "Nhờ đầu mối đăng ký".

**Đầu vào.** `kind` (`QUESTION`, `DOC_ERROR`, `SUPPORT_REQUEST`, `ACCESS_REQUEST`), `apiCode` tùy chọn, `subject`, `body` (văn bản thuần ≤ 4000); `ticketCode` khi nhắn thêm.

**Luồng xử lý chính.**

1. Hệ thống kiểm tra tần suất (ERR-15-037) và nội dung (ERR-15-003).
2. Hệ thống chọn người nhận: đầu mối kỹ thuật của chủ dịch vụ khi có `apiCode`; `ACCESS_REQUEST` tới đầu mối của tổ chức người dùng; không có thì tới TA.
3. Hệ thống tạo phiếu `OPEN` với mã `HT-{năm}-{số}`, gửi thông báo và thư (chỉ liên kết) cho người nhận, phát EVT-15-12.
4. Người dùng theo dõi và nhắn thêm ở `/ho-tro/{ma-yeu-cau}`; hệ thống ghi từng tin.
5. Khi phiếu `RESOLVED`, người dùng xác nhận hoặc mở lại trong 7 ngày.

**Luồng thay thế.** Người dùng ẩn danh không gửi được; hiển thị đầu mối liên hệ của tenant.

**Luồng ngoại lệ.**

- Phiếu đã đóng: ERR-15-029 (409); "Phiếu đã đóng. Tạo phiếu mới nếu cần."
- Gửi quá nhiều: ERR-15-037 (429).
- Phiếu không phải của mình: ERR-15-001 (404).

**Đầu ra.** `201`; `ticketCode`, `status`.

**Kết quả.** Yêu cầu tới đúng người, có mã để theo dõi.

**Hậu điều kiện.** Phiếu `OPEN`.

**Sự kiện phát ra.** EVT-15-12 (`support.ticket-opened`).

**Kiểm toán.** Có: tạo phiếu, đổi trạng thái.

**Quy tắc nghiệp vụ.** BR-15-030.

**Màn hình, API.** UI-15-20; API-15-110, API-15-111, API-15-112, API-15-113.
:::

#### FR-15-055 · Xử lý yêu cầu hỗ trợ

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và quản trị cổng nhận, trả lời, chuyển và đóng phiếu, có hạn phản hồi để không phiếu nào bị bỏ quên.

**Tác nhân, quyền.** SV (○), CA, TA (`PERM-15-support`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; FR-00-070.

**Tiền điều kiện.** Có phiếu gửi tới người xử lý.

**Kích hoạt.** Mở hộp xử lý ở UI-15-28.

**Đầu vào.** `ticketCode`; tin trả lời; chuyển trạng thái `ANSWERED`, `RESOLVED`, `CLOSED`; `assignee`; ghi chú nội bộ.

**Luồng xử lý chính.**

1. Hệ thống liệt kê phiếu theo phạm vi của người xử lý (API của tổ chức mình với SV; mọi phiếu với TA) kèm hạn phản hồi đầu `15.support.sla-hours` (mặc định 24 giờ).
2. Người xử lý trả lời; hệ thống chuyển `ANSWERED`, thông báo người gửi.
3. Người xử lý chuyển giao cho người khác hoặc ghi chú nội bộ (không hiện cho người gửi).
4. Phiếu quá hạn phản hồi đầu: hệ thống nhắc trong "Việc của tôi" và báo TA (BR-15-030).
5. Phiếu `RESOLVED` quá 7 ngày không phản hồi tự `CLOSED`.

**Luồng thay thế.** Người xử lý chuyển phiếu cho PH-02 hay PH-01 bằng cách ghi nhận và liên hệ ngoài cổng (Q15-15).

**Luồng ngoại lệ.**

- Phiếu đã đóng: ERR-15-029 (409).
- Phiếu ngoài phạm vi: ERR-15-001 (404).
- Thiếu quyền: ERR-15-005 (403).

**Đầu ra.** `200`; phiếu cập nhật.

**Kết quả.** Phiếu được trả lời trong hạn hoặc được báo động.

**Hậu điều kiện.** Trạng thái phiếu cập nhật.

**Sự kiện phát ra.** EVT-15-12 khi đổi trạng thái (cùng chủ đề với lúc mở).

**Kiểm toán.** Có: đổi trạng thái, chuyển giao.

**Quy tắc nghiệp vụ.** BR-15-030.

**Màn hình, API.** UI-15-28; API-15-114, API-15-115.
:::

### 6.11. Nhóm J · Quản trị cổng

Nhóm J gom việc của quản trị viên: nhận diện cổng theo tỉnh, tham số, duyệt và khóa tài khoản, xem nhật ký, đồng bộ và đối soát với PH-02, di trú nội dung từ cổng hệ cũ. Khu `/quan-tri-cong` chỉ mở cho người có quyền, bắt buộc MFA và chỉ truy cập từ mạng quản trị (BR-15-031).

#### FR-15-056 · Cấu hình nhận diện cổng theo tenant

::: dac-ta
**Mục đích.** Cho mỗi tỉnh đặt tên cổng, logo, liên kết và chân trang riêng mà không đụng tới thiết kế chung.

**Tác nhân, quyền.** TA, CA (`PERM-15-portal-admin`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; LGC-APIM-007 (công khai theo tenant); ADR-020.

**Tiền điều kiện.** Đăng nhập khu quản trị có MFA.

**Kích hoạt.** Mở `/quan-tri-cong/nhan-dien`.

**Đầu vào.** `portalName` (T-NAME 3…80), `tagline` (≤ 160), `logo` (PNG hoặc WebP, ≤ 512 KB, từ 128 px), `supportEmail`, `supportPhone`, `footerLinks[]` (≤ 8 liên kết HTTPS), `welcomeText` (Markdown ngắn ≤ 2 KB); `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống hiển thị cấu hình hiện hành và bản xem trước. Tên cổng, logo và chân trang cho khách ẩn danh đọc qua API-15-139 (chỉ các khóa nhận diện, không lộ tham số quản trị).
2. Người dùng sửa; hệ thống kiểm tra miền giá trị và logo (kiểu theo nội dung, quét mã độc, SEC-45); SVG không được nhận.
3. Hệ thống lưu với `If-Match`, vô hiệu bộ đệm trang chủ.
4. Màu, phông, token, vật liệu kính không cấu hình được (BR-15-032).
5. Hệ thống ghi kiểm toán.

**Luồng thay thế.** Quay về mặc định của nền tảng.

**Luồng ngoại lệ.**

- Logo sai định dạng, quá cỡ: ERR-15-033 (422); "Thông tin nhận diện chưa hợp lệ." (chi tiết riêng ở `detail`: Logo cần là PNG hoặc WebP, tối đa 512 KB và từ 128 px)
- Liên kết không HTTPS: ERR-15-033 (422); "Thông tin nhận diện chưa hợp lệ." (chi tiết riêng ở `detail`: Liên kết chân trang cần dùng HTTPS)
- Xung đột sửa: ERR-15-006 (412).

**Đầu ra.** `200`, `ETag`; cấu hình.

**Kết quả.** Cổng mang tên và logo của tỉnh.

**Hậu điều kiện.** Cấu hình mới có hiệu lực sau ≤ 60 giây.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: trường đổi, giá trị trước và sau (trừ nội dung logo).

**Quy tắc nghiệp vụ.** BR-15-031; BR-15-032; BR-15-034.

**Màn hình, API.** UI-15-25; API-15-116, API-15-117, API-15-118, API-15-139.
:::

#### FR-15-057 · Tham số cổng

::: dac-ta
**Mục đích.** Cho tỉnh điều chỉnh hành vi của cổng (công khai, đăng ký, hạn mức, hạn khóa) trong biên an toàn mà không cần phát hành lại.

**Tác nhân, quyền.** TA (`PERM-15-portal-admin`); PA đặt trần.

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; D03-10 (trần theo tenant).

**Tiền điều kiện.** Đăng nhập khu quản trị có MFA.

**Kích hoạt.** Mở `/quan-tri-cong/tham-so`.

**Đầu vào.** Khóa `15.*` và giá trị (mục 8.2); `reason`.

**Luồng xử lý chính.**

1. Hệ thống liệt kê tham số kèm mặc định, miền, giá trị hiện hành.
2. TA sửa; hệ thống kiểm tra miền và trần nền tảng (ERR-15-034).
3. Hệ thống lưu qua kho tham số của PH-18 (không-gian-tên `15.`); bộ đệm 60 giây.
4. Một số tham số nhạy cảm (`15.public.enabled`, `15.try.prod-enabled`) cần nêu lý do và ghi kiểm toán ở mức cao.
5. Hệ thống ghi giá trị trước, sau.

**Luồng thay thế.** Đặt lại về mặc định.

**Luồng ngoại lệ.**

- Giá trị ngoài miền: ERR-15-034 (422); "Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}."
- Vượt trần của nền tảng: ERR-15-034 (422); "Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}." (chi tiết riêng ở `detail`: Giá trị vượt trần cho phép của nền tảng)
- Xung đột sửa: ERR-15-006 (412).

**Đầu ra.** `200`; danh sách tham số.

**Kết quả.** Hành vi cổng thay đổi đúng tham số, trong biên an toàn.

**Hậu điều kiện.** Giá trị mới hiệu lực trong 60 giây.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: khóa, giá trị trước, sau, lý do.

**Quy tắc nghiệp vụ.** BR-15-031; BR-15-034.

**Màn hình, API.** UI-15-25; API-15-119, API-15-120.
:::

#### FR-15-058 · Duyệt tài khoản dh-dev

::: dac-ta
**Mục đích.** Cho quản trị kiểm tra nhà thầu đăng ký có thật sự thuộc đơn vị có hợp đồng và được cơ quan nhà nước giao việc, trước khi cho vào cổng.

**Tác nhân, quyền.** TA, PA (`PERM-15-dev-approve`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-014; SEC-27; Q15-03.

**Tiền điều kiện.** Tài khoản `PENDING_APPROVAL`.

**Kích hoạt.** Mở yêu cầu duyệt `DEV_ACCOUNT` ở "Việc của tôi" hoặc UI-15-24.

**Đầu vào.** `userId`; quyết định `APPROVE` hoặc `REJECT`; `tenantGrants[]` (tenant được cấp, mặc định tenant hiện tại); `comment` (bắt buộc khi từ chối).

**Luồng xử lý chính.**

1. Quản trị xem họ tên, thư, tổ chức thầu, số hợp đồng, đơn vị bảo lãnh; có thể liên hệ đơn vị bảo lãnh ngoài cổng.
2. Duyệt: hệ thống bật người dùng ở realm `dh-dev`, gán thuộc tính `tenantGrants` và vai trò `ROLE-DEVELOPER`, chuyển `ACTIVE`.
3. Hệ thống gửi thư thông báo (chỉ liên kết đăng nhập), thông báo trong ứng dụng, phát EVT-15-07.
4. Từ chối: chuyển `REJECTED` kèm lý do, gửi thư; người đăng ký có thể đăng ký lại với thông tin khác.
5. Yêu cầu quá `15.dev.approval-sla-days` (mặc định 3) chưa xử lý: nhắc và báo PA.

**Luồng thay thế.** Kích hoạt lại tài khoản `DISABLED`: cùng luồng.

**Luồng ngoại lệ.**

- Tài khoản không ở `PENDING_APPROVAL`: ERR-15-022 (409); "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." (chi tiết riêng ở `detail`: Tài khoản không ở trạng thái chờ duyệt)
- Thiếu lý do khi từ chối: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Cần nêu lý do từ chối)
- Keycloak lỗi: ERR-15-020 (503); giữ `PENDING_APPROVAL`.

**Đầu ra.** `200`; tài khoản với `status`.

**Kết quả.** Nhà thầu được duyệt đăng nhập được; người bị từ chối biết lý do.

**Hậu điều kiện.** Tài khoản `ACTIVE` hoặc `REJECTED`.

**Sự kiện phát ra.** EVT-15-07 (`devaccount.state-changed`).

**Kiểm toán.** Có: người duyệt, quyết định, lý do, `tenantGrants`.

**Quy tắc nghiệp vụ.** BR-15-004; BR-15-028.

**Màn hình, API.** UI-15-24; API-15-121, API-15-122, API-15-123.
:::

#### FR-15-059 · Khóa, mở khóa tài khoản và ứng dụng

::: dac-ta
**Mục đích.** Cho quản trị và cán bộ ATTT chặn ngay tài khoản hoặc ứng dụng nghi lạm dụng sandbox (gọi dồn dập, dò quét, dán dữ liệu thật).

**Tác nhân, quyền.** TA, SO, PA (`PERM-15-dev-approve`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-014; SEC-27, SEC-64.

**Tiền điều kiện.** Tài khoản `ACTIVE` hoặc ứng dụng `ACTIVE`.

**Kích hoạt.** Bấm "Khóa" ở UI-15-24; hoặc nhận cảnh báo lạm dụng từ PH-13.

**Đầu vào.** `userId` hoặc `appCode`; `reason` (bắt buộc).

**Luồng xử lý chính.**

1. Quản trị chọn đối tượng, nêu lý do.
2. Khóa tài khoản: hệ thống tắt người dùng ở realm `dh-dev`, hủy mọi phiên BFF, chuyển `LOCKED`, tạm ngừng (`SUSPENDED`) mọi ứng dụng thuộc riêng người này.
3. Khóa ứng dụng: chuyển `SUSPENDED`; `forward-auth` từ chối lượt gọi sau tối đa 60 giây; thông tin xác thực giữ nguyên để mở khóa.
4. Mở khóa: ngược lại, kèm lý do.
5. Hệ thống thông báo chủ ứng dụng hoặc người dùng, ghi kiểm toán, phát EVT-15-02 hoặc EVT-15-07.

**Luồng thay thế.** Cán bộ SSO bị khóa ở PH-12: cổng đồng bộ trạng thái khi đăng nhập, không khóa ở cổng.

**Luồng ngoại lệ.**

- Đối tượng không ở trạng thái cho phép: ERR-15-017 (409) với ứng dụng, "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."; ERR-15-022 (409) với tài khoản, "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."
- Thiếu lý do: ERR-15-003 (400).

**Đầu ra.** `200`; đối tượng với `status`.

**Kết quả.** Lạm dụng bị chặn ngay, có dấu vết.

**Hậu điều kiện.** Đối tượng `LOCKED` hoặc `SUSPENDED`.

**Sự kiện phát ra.** EVT-15-02; EVT-15-07.

**Kiểm toán.** Có: người khóa, đối tượng, lý do.

**Quy tắc nghiệp vụ.** BR-15-010; BR-15-028.

**Màn hình, API.** UI-15-24; API-15-124, API-15-125, API-15-126, API-15-127.
:::

#### FR-15-060 · Nhật ký truy cập, thử và báo cáo sử dụng cổng

::: dac-ta
**Mục đích.** Cho kiểm toán và quản trị truy ra ai đã xem tài liệu nhạy cảm, ai đã thử gì, và đo mức dùng của cổng để chứng minh hiệu quả.

**Tác nhân, quyền.** TA, SO, AU, PA (`PERM-15-audit-read`).

**Mức ưu tiên, đợt.** M · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-015; FR-00-040, FR-00-041, FR-00-030; ADR-031; SEC-60, SEC-62.

**Tiền điều kiện.** Có bản ghi kiểm toán của cổng ở PH-13.

**Kích hoạt.** Mở `/quan-tri-cong/nhat-ky`.

**Đầu vào.** `tu`, `den`, `hanh-dong` (Phụ lục A.8), `nguoi-dung`, `api`, `ung-dung`, `ket-qua`; `format` (`csv`, `xlsx`).

**Luồng xử lý chính.**

1. Hệ thống đọc bản ghi kiểm toán loại `PORTAL_*` từ PH-13 (scope `audit:portal-read`) theo bộ lọc; trực tuyến 12 tháng, WORM 5 năm ở PH-13.
2. Hệ thống hiển thị chuỗi: thời điểm, người, hành động (`VIEW_SENSITIVE_DOCS`, `DOWNLOAD_SPEC`, `TRY_API`, `TRY_PRODUCTION`, `SECRET_ISSUED`, `SUBMIT_SUBSCRIPTION`, `SUBMIT_ONBOARDING`, `SUBMIT_PUBLICATION`, `LOCK_ACCOUNT`…), đối tượng, kết quả, `traceId`.
3. Báo cáo sử dụng hiển thị: số truy cập, API xem nhiều, số ứng dụng, số lượt thử, tỷ lệ lỗi, và thời gian trung vị từ tạo ứng dụng tới lời gọi sandbox thành công đầu tiên (mục tiêu 1 ở 2.2).
4. Xuất theo bộ lọc; trên 10.000 dòng chạy nền (FR-00-031); dữ liệu cá nhân trong tệp xuất bị che trừ khi có quyền (FR-00-034).
5. Xem nhật ký là một hành động ghi kiểm toán.

**Luồng thay thế.** Bộ lọc theo `traceId` để nối với nhật ký của PH-13.

**Luồng ngoại lệ.**

- PH-13 lỗi: ERR-15-039 (502); "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
- Khoảng thời gian quá 12 tháng cho truy vấn trực tuyến: ERR-15-003 (400); "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." (chi tiết riêng ở `detail`: Khoảng thời gian vượt 12 tháng. Chọn khoảng ngắn hơn hoặc yêu cầu truy xuất từ kho lưu trữ)
- Thiếu quyền: ERR-15-005 (403).

**Đầu ra.** `200`; `items[]`, `page`, `size`; `202` với xuất nền; báo cáo `summary`.

**Kết quả.** Truy ra được ai làm gì; đo được mức dùng cổng.

**Hậu điều kiện.** Không thay đổi dữ liệu nhật ký.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người xem, bộ lọc, số dòng xuất.

**Quy tắc nghiệp vụ.** BR-15-023; BR-15-031.

**Màn hình, API.** UI-15-26; API-15-128, API-15-129, API-15-130.
:::

#### FR-15-061 · Đồng bộ lại và đối soát danh mục với PH-02

::: dac-ta
**Mục đích.** Cho quản trị ép nạp lại danh mục khi nghi lệch và định kỳ kiểm chứng bản sao khớp PH-02, thay cho việc tin vào sự kiện.

**Tác nhân, quyền.** TA, CA (`PERM-15-portal-admin`); hệ thống (lịch tuần).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; SRS cũ FR-15-001, SRS cũ FR-15-005; FR-02-059.

**Tiền điều kiện.** PH-02 khả dụng.

**Kích hoạt.** Bấm "Đồng bộ lại" hoặc "Đối soát" ở UI-15-27; lịch hằng tuần.

**Đầu vào.** `scope` (`ALL`, `API`), `apiCode`; `fix` (T-BOOL).

**Luồng xử lý chính.**

1. Đồng bộ lại: hệ thống tạo lần đồng bộ nạp đầy (bỏ `updatedSince`) hoặc cho một API; từ chối khi đang có lần chạy (ERR-15-035).
2. Đối soát: hệ thống lấy tổng hợp từ PH-02 (số API, băm từng mục) và so với bản sao: mục thiếu, mục thừa, mục khác băm đặc tả.
3. Hệ thống hiển thị báo cáo chênh lệch; với `fix = true` chạy đồng bộ lại đúng các mục lệch.
4. Hệ thống ghi `SyncRun`, phát EVT-15-14 nếu trạng thái đổi; chênh lệch dai dẳng sau sửa tạo cảnh báo cho PH-13.

**Luồng thay thế.** Đối soát tự động hằng tuần, chỉ báo khi có lệch.

**Luồng ngoại lệ.**

- Đang đồng bộ: ERR-15-035 (409); "Đang có lần chạy khác. Đợi hoàn tất rồi thử lại."
- PH-02 lỗi: ERR-15-030 (502); "Chưa kết nối được dịch vụ danh mục."

**Đầu ra.** `202`; `runId`; báo cáo đối soát `missing[]`, `extra[]`, `stale[]`.

**Kết quả.** Bản sao được kiểm chứng và sửa khi lệch.

**Hậu điều kiện.** `SyncRun` hoàn tất.

**Sự kiện phát ra.** EVT-15-14.

**Kiểm toán.** Có: người, phạm vi, kết quả.

**Quy tắc nghiệp vụ.** BR-15-001; BR-15-033.

**Màn hình, API.** UI-15-27; API-15-131, API-15-132, API-15-133, API-15-134.
:::

#### FR-15-062 · Di trú nội dung portal hệ cũ

::: dac-ta
**Mục đích.** Chuyển các trang giới thiệu, tài liệu hướng dẫn đang có ở portal Gravitee hệ cũ sang cổng mới để chạy song song rồi tắt cổng cũ.

**Tác nhân, quyền.** TA, CA (`PERM-15-portal-admin`, `PERM-15-content-write`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-15; BP-09; LGC-APIM-006 (liên quan); FR-02-061.

**Tiền điều kiện.** Có gói xuất nội dung từ portal Gravitee; PH-02 đã nhập danh mục API từ APIM cũ.

**Kích hoạt.** Tải gói ở UI-15-27.

**Đầu vào.** Tệp nén (ZIP ≤ 50 MB) gồm trang, tài liệu, ảnh; `migrationId` do hệ thống cấp.

**Luồng xử lý chính.**

1. Hệ thống quét mã độc gói (SEC-45), kiểm tra cấu trúc (ERR-15-026).
2. Hệ thống đọc từng trang: Markdown giữ nguyên; HTML, AsciiDoc chuyển sang Markdown; tài liệu Swagger gắn API được bỏ qua vì cổng mới sinh từ đặc tả của PH-02.
3. Hệ thống đề xuất `pageCode`, loại `GUIDE`, ngôn ngữ, và ánh xạ trang tới `apiCode` theo context path đã nhập ở PH-02; ảnh chuyển vào kho Garage.
4. Hệ thống hiển thị báo cáo xem trước: trang nhập được, trang bỏ qua, cảnh báo nội dung (liên kết hỏng, HTML bị lọc).
5. Người dùng xác nhận; hệ thống tạo các phiên bản `DRAFT` (không đăng); chạy lại cùng `migrationId` không tạo trùng.

**Luồng thay thế.** Nhập từng phần: chọn tập con trang.

**Luồng ngoại lệ.**

- Gói không hợp lệ: ERR-15-026 (422); "Gói di trú sai cấu trúc hoặc có tệp không được phép."
- Đang có di trú chạy: ERR-15-035 (409).
- Tệp nhiễm mã độc: ERR-15-024 (422).

**Đầu ra.** `202`; `migrationId`, báo cáo xem trước, kết quả.

**Kết quả.** Nội dung cũ có mặt ở cổng mới dưới dạng nháp chờ duyệt.

**Hậu điều kiện.** Các phiên bản `DRAFT`; không trang nào được đăng tự động.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người, gói, số trang, kết quả.

**Quy tắc nghiệp vụ.** BR-15-012; BR-15-013; BR-15-034.

**Màn hình, API.** UI-15-27; API-15-135, API-15-136, API-15-137.
:::

## 7. Quy tắc nghiệp vụ

Các quy tắc dưới đây áp dụng xuyên chức năng. Quy tắc dạng "luôn" kiểm bằng ca kiểm thử âm; quy tắc có ngưỡng dùng tham số ở mục 8.2.

| Mã | Quy tắc | FR áp dụng |
|---|---|---|
| BR-15-001 | PH-15 chỉ đọc và trình bày: không quyết định trạng thái, mức hiển thị, đặc tả của API; sửa ở PH-02 và lần đồng bộ sau ghi đè bản sao | 001, 006, 007, 009…011, 013, 047, 061 |
| BR-15-002 | Chỉ hiện phiên bản `PUBLISHED`, `DEPRECATED` (và `SUSPENDED` có nhãn) có `portalPublished = true` đúng mức hiển thị; API ngoài tầm trả như không tồn tại (`404`, cùng thân), kể cả ở tìm kiếm, gợi ý, tải đặc tả | 001…013, 051 |
| BR-15-003 | Tenant xác định từ tên miền cổng và token; mọi bảng có `tenant_id` và RLS; không thao tác liên tenant | 002, 008 |
| BR-15-004 | Tài khoản `dh-dev` chỉ thấy API `PUBLIC` cùng `TENANT`, `NATIONAL` của tenant được cấp, bỏ `dataClass = SENSITIVE`; chỉ dùng sandbox; không đăng ký sử dụng, không kết nạp, không xem tham chiếu production | 002, 019, 032, 043, 044, 058 |
| BR-15-005 | Khách ẩn danh chỉ thấy API `PUBLIC` với `dataClass = PUBLIC` và trang `audience = PUBLIC`, và chỉ khi `15.public.enabled`; mặc định tắt | 002, 003, 005, 008, 017 |
| BR-15-006 | Cổng không hiển thị backend, địa chỉ nội bộ, danh sách bên đăng ký, bí mật, đầu mối cá nhân cho khách ẩn danh | 002, 005, 006, 008, 009, 012, 017 |
| BR-15-007 | Mã `appCode`, `pageCode`, `teamCode` bất biến, không dùng lại kể cả sau khi lưu trữ; mẫu quy định ở Phụ lục A.1 | 014, 022, 025 |
| BR-15-008 | Người chưa chấp nhận điều khoản hiện hành không tạo ứng dụng, không thử API; vẫn đọc được danh mục và tài liệu | 023, 025, 035 |
| BR-15-009 | Ứng dụng thuộc cá nhân hoặc nhóm; `PERM-15-app`, `PERM-15-try` chỉ áp dụng cho ứng dụng mà người dùng là thành viên; vai trò `OWNER`, `DEVELOPER`, `VIEWER` quyết định thao tác | 022, 026, 033, 048…050 |
| BR-15-010 | Giới hạn mỗi người `15.app.max-per-user` ứng dụng, mỗi nhóm `15.app.max-per-team`, mỗi ứng dụng `15.cred.max-per-app` thông tin xác thực; thông tin xác thực chỉ dùng khi ứng dụng `ACTIVE`; ứng dụng không dùng 180 ngày tự lưu trữ | 025…028, 031, 059 |
| BR-15-011 | Bí mật sandbox hiện đúng một lần, không lưu (chỉ tiền tố 8 ký tự và băm), sống ≤ 180 ngày (SEC-24), xoay có thời gian chuyển tiếp ≤ 72 giờ; không bao giờ có trong log, vết, tệp xuất, mẫu mã | 012, 027…031, 041 |
| BR-15-012 | Nội dung chỉ đăng sau duyệt bốn mắt: người duyệt khác người soạn, người sửa gần nhất và người gửi; chỉ nhân sự có `PERM-15-content-write` soạn; nhà phát triển không đăng nội dung | 014…016, 018, 062 |
| BR-15-013 | Markdown qua bộ lọc: cấm HTML thô, script, iframe, `javascript:`, ảnh ngoài kho; liên kết ngoài `rel="noopener nofollow"`; trang ≤ 200 KB, ảnh ≤ 5 MB (PNG, JPEG, WebP) | 014, 017, 018, 062 |
| BR-15-014 | Đăng ký sử dụng, kết nạp HTTT, công bố API do PH-02, PH-01 xử lý; cổng ủy thác bằng danh tính người dùng, không tự duyệt, không giữ bản sao quyết định; chỉ cán bộ đầu mối của tổ chức đăng ký sử dụng và kết nạp | 044…047 |
| BR-15-015 | Thông tin xác thực production không bao giờ hiển thị ở cổng; chỉ tham chiếu (`clientId`, phương thức, 16 ký tự đầu dấu vân tay chứng thư, hạn, trạng thái) cho cán bộ thuộc tổ chức của HTTT | 027, 032, 046 |
| BR-15-016 | Sandbox chỉ chứa dữ liệu tổng hợp; mẫu nhận dạng `PII-15-01…06` bị chặn ở `BACKEND`, cảnh báo ở `MOCK`; giá trị khớp mẫu không được lưu | 035…038 |
| BR-15-017 | Chế độ `MOCK` chỉ sinh phản hồi từ ví dụ và lược đồ của đặc tả, không gọi hệ thống nào, đánh dấu `X-DH-Sandbox: mock` | 034, 036 |
| BR-15-018 | Backend thử do chủ dịch vụ khai báo, HTTPS, thuộc danh sách egress cho phép kiểm lại lúc gọi, không chứa dữ liệu thật; ngắt mạch sau 5 lỗi trong 30 giây | 034, 037 |
| BR-15-019 | Thử production mặc định tắt; bật theo từng dịch vụ, có thời hạn ≤ `15.try.prod-max-days`, và chỉ khi `15.try.prod-enabled` của tenant bật | 042, 043 |
| BR-15-020 | Thử production chỉ với API `dataClass` `PUBLIC` hoặc `INTERNAL` và phương thức `GET`, `HEAD`; cấm `RESTRICTED`, `SENSITIVE` | 042, 043 |
| BR-15-021 | Bật thử production theo bốn mắt: người đề xuất khác người duyệt; tắt chỉ cần một người có quyền | 042 |
| BR-15-022 | Thử production chỉ cho cán bộ giữ `PERM-15-try` (`ROLE-DEVELOPER` đăng nhập SSO; `ROLE-ORG_REQUESTER` không thử, chỉ đăng ký) thuộc tổ chức có HTTT với đăng ký sử dụng `ACTIVE` của API; token trao đổi 5 phút, thu hẹp vào phạm vi của đăng ký, đánh dấu `act` | 043 |
| BR-15-023 | An toàn khi lỗi: không ghi được kiểm toán thì từ chối thử, với production luôn, với sandbox khi API `RESTRICTED`, `SENSITIVE`; sandbox còn lại ghi qua outbox | 035, 043, 060 |
| BR-15-024 | Thân yêu cầu, phản hồi, tiêu đề xác thực không vào lịch sử, nhật ký, kiểm toán; phản hồi che theo SEC-32; không lưu thân phản hồi production | 035…043, 049, 050 |
| BR-15-025 | Hạn mức sandbox theo người, ứng dụng, tenant, cỡ thân, thời gian chờ; vượt thì `429` hoặc `413` kèm `Retry-After`; cùng bộ đếm cho lời gọi ngoài cổng | 035, 039 |
| BR-15-026 | Mọi lượt thử mang `X-DH-Try-Id`, `traceparent`; tiêu đề `Authorization`, `Cookie`, `Host` do người dùng gửi bị chặn | 035 |
| BR-15-027 | Thông báo thay đổi loại bắt buộc (như BR-02-029: ngừng khuyến nghị, tạm ngừng, ngừng hẳn, SLA kém đi, thay đổi phá vỡ) không tắt được; loại thông tin theo tùy chọn kênh | 013, 051, 052 |
| BR-15-028 | Tài khoản `dh-dev`: xác minh thư ≤ 24 giờ, quản trị duyệt, khai tổ chức thầu, số hợp đồng và đơn vị bảo lãnh; vô hiệu sau 45 ngày không hoạt động (SEC-27); kích hoạt lại phải duyệt | 019, 020, 024, 058, 059 |
| BR-15-029 | Dữ liệu cá nhân của tài khoản `dh-dev` tối thiểu (họ tên, thư, đơn vị, điện thoại tùy chọn); có thông báo xử lý; xóa theo yêu cầu bằng ẩn danh; ẩn danh tự động sau 24 tháng không hoạt động | 020, 021, 024 |
| BR-15-030 | Yêu cầu hỗ trợ tới đầu mối của chủ dịch vụ; quá hạn phản hồi đầu `15.support.sla-hours` thì nhắc và báo quản trị; nội dung hỏi đáp là văn bản thuần | 053…055 |
| BR-15-031 | Khu `/quan-tri-cong` bắt buộc MFA (WebAuthn với TA, CA), chỉ truy cập từ mạng quản trị; từ tên miền công khai trả `404` | 056, 057, 060 |
| BR-15-032 | Nhận diện cổng theo tenant chỉ gồm tên, logo, liên kết, chân trang, lời chào; không đổi màu, phông, token, vật liệu kính | 003, 056 |
| BR-15-033 | Danh mục là bản sao chỉ đọc: PH-02 không khả dụng thì phục vụ bản sao kèm banner; quá `15.sync.stale-seconds` hiện cảnh báo "chưa mới nhất" nhưng vẫn cho đọc; quá 24 giờ ẩn nút thử production | 001, 006, 061 |
| BR-15-034 | Mọi thao tác ghi dùng `Idempotency-Key` (ADR-041) và `If-Match`; xóa là xóa mềm; đối tượng của tenant khác trả như không tồn tại | 014, 021, 025, 026, 040, 056, 057, 062 |

: Quy tắc nghiệp vụ của PH-15

## 8. Tham số và yêu cầu phi chức năng

### 8.1. Yêu cầu phi chức năng

Yêu cầu dưới đây đo ở hồ sơ "tỉnh vừa" (GĐ-07) với quy mô ở NFR-15-012. Chỉ tiêu hiệu năng đo qua cổng, tính cả BFF, trừ khi ghi khác.

| Mã | Yêu cầu | Chỉ tiêu | Điều kiện đo |
|---|---|---|---|
| NFR-15-001 | Tải trang đầu tiên của cổng | LCP ≤ 2,5 giây, INP ≤ 200 ms (như NFR-00-005) | Máy 4 nhân, 8 GB, mạng 20 Mbps; trang chủ, danh mục, tài liệu |
| NFR-15-002 | API danh mục và tìm kiếm | Đọc p95 ≤ 300 ms; tìm kiếm p95 ≤ 300 ms; gợi ý p95 ≤ 200 ms | 500 API, 3.000 phiên bản, 100 người dùng đồng thời |
| NFR-15-003 | Hiển thị tài liệu API | API `operations` p95 ≤ 500 ms; dựng trang 300 thao tác ≤ 2 giây | Đặc tả 300 thao tác |
| NFR-15-004 | Độ trễ đồng bộ danh mục | Từ sự kiện của PH-02 tới hiển thị p95 ≤ 30 giây; kéo bù bắt kịp ≤ 5 phút kể cả mất sự kiện | 50 thay đổi mỗi phút |
| NFR-15-005 | Độ trễ thêm của đường thử sandbox | p95 ≤ 100 ms ngoài thời gian backend; phản hồi `MOCK` p95 ≤ 150 ms | 50 lượt thử đồng thời |
| NFR-15-006 | Cấp thông tin xác thực sandbox | p95 ≤ 3 giây kể cả Keycloak | 20 yêu cầu đồng thời |
| NFR-15-007 | Hiệu lực thu hồi, khóa | Lượt gọi mới bị chặn ≤ 60 giây sau thu hồi, khóa; ≤ 5 giây khi nhận EVT-15-05 | Bộ đệm `forward-auth` 60 giây |
| NFR-15-008 | Sẵn sàng | 99,5% mỗi tháng (giả định, `TPH-1`); PH-02 hỏng vẫn phục vụ bản sao ≥ 24 giờ; PH-12 hỏng vẫn xem được trang công khai | Giám sát PH-13 |
| NFR-15-009 | Không lộ bí mật | 0 bí mật trong log, vết, DB, bộ đệm, tệp xuất, phản hồi ngoài lần cấp | Ca kiểm thử với giá trị đánh dấu `DH-CANARY-…` |
| NFR-15-010 | Không token ở trình duyệt | 0 token trong bộ nhớ JavaScript, `localStorage`, `sessionStorage` | Playwright (SEC-21) |
| NFR-15-011 | An toàn nội dung | 0 XSS với bộ kiểm thử OWASP cho Markdown; CSP chặn script ngoài (SEC-44) | ZAP và kiểm thử đơn vị |
| NFR-15-012 | Quy mô một tenant vừa | 500 API, 3.000 phiên bản, 2.000 tài khoản `dh-dev`, 2.000 ứng dụng, 300 trang nội dung, 100 người dùng đồng thời | GĐ-15-01 |
| NFR-15-013 | Thông lượng thử | ≥ 100 lượt/giây toàn tenant ở sandbox, giữ NFR-15-005 | k6, 10 phút |
| NFR-15-014 | Khả năng truy cập | WCAG 2.2 AA; dùng được từ 360 px | Kiểm thử D03-05 |
| NFR-15-015 | Trình duyệt hỗ trợ | Hai bản gần nhất của Chrome, Edge, Firefox, Safari | Ma trận Playwright |
| NFR-15-016 | Lưu giữ | Lịch sử thử 30 ngày; nhật ký truy cập 12 tháng trực tuyến, WORM 5 năm; phiên bản trang vĩnh viễn; thông báo 90 ngày; ẩn danh tài khoản sau 24 tháng không hoạt động | Tác vụ lưu giữ |
| NFR-15-017 | Cách ly tenant | 0 rò rỉ chéo tenant ở mọi API đọc | Ca kiểm thử RLS (ADR-003) |
| NFR-15-018 | Truy cập ẩn danh chịu tải | 300 lượt/giây trang `PUBLIC` nhờ bộ đệm; trần `15.public.rate-limit-per-minute` theo IP | k6 |
| NFR-15-019 | Tương thích hợp đồng | API `v1` chỉ thêm trường tùy chọn; sự kiện theo chế độ BACKWARD ở Apicurio | CI-5 |
| NFR-15-020 | Quan sát | Chỉ số `dh_portal_sync_lag_seconds`, `dh_portal_try_total`, `dh_portal_try_throttled_total`, `dh_portal_cred_old_use_total`, `dh_portal_visibility_denied_total`; cảnh báo khi lag > 900 giây | PH-13 |
| NFR-15-021 | Ngôn ngữ | Tiếng Việt mặc định; nhãn giao diện tiếng Anh nên có (Đợt 3, Q15-14) | Kiểm thử giao diện |
| NFR-15-022 | Bắt đầu nhanh và mẫu mã đúng | ≥ 80% nhà phát triển mới có lời gọi sandbox thành công đầu tiên ≤ 15 phút sau khi tạo ứng dụng; mẫu mã sinh ra chạy được ở ≥ 95% thao tác mẫu của sáu ngôn ngữ | Đo bằng EVT-15-03, EVT-15-11; kiểm thử khói mẫu mã |

: Yêu cầu phi chức năng của PH-15

### 8.2. Tham số theo tenant

Khóa có tiền tố `15.` do PH-18 giữ; mặc định áp dụng khi tenant chưa đặt. Tham số bảo mật có trần nền tảng mà tenant không vượt được.

| Khóa | Mặc định | Miền | Ý nghĩa |
|---|---|---|---|
| `15.sync.interval-seconds` | 300 | 60…3.600 | Chu kỳ kéo bù danh mục |
| `15.sync.stale-seconds` | 900 | 300…7.200 | Quá ngưỡng này hiện cảnh báo "chưa mới nhất" |
| `15.public.enabled` | `false` | | Bật truy cập ẩn danh cho API `PUBLIC` |
| `15.public.rate-limit-per-minute` | 120 | 30…1.000 | Tần suất tối đa theo IP với khách ẩn danh |
| `15.dev.signup-enabled` | `true` | | Cho nhà thầu tự đăng ký `dh-dev` |
| `15.dev.approval-sla-days` | 3 | 1…14 | Hạn duyệt tài khoản trước khi nhắc |
| `15.dev.anonymize-after-months` | 24 | 6…60 | Ẩn danh tài khoản không hoạt động |
| `15.app.max-per-user` | 10 | 1…50 | Số ứng dụng đang hoạt động mỗi người |
| `15.app.max-per-team` | 30 | 1…100 | Số ứng dụng mỗi nhóm |
| `15.cred.max-per-app` | 3 | 1…10 | Số thông tin xác thực mỗi ứng dụng |
| `15.cred.ttl-days` | 90 | 30…180 | Thời hạn mặc định của thông tin xác thực |
| `15.cred.rotate-grace-hours` | 24 | 1…72 | Thời gian chuyển tiếp khi xoay vòng |
| `15.cred.expiry-notice-days` | `[30,7,1]` | | Các mốc nhắc trước khi hết hạn |
| `15.try.rate-per-user-min` | 30 | 5…120 | Lượt thử mỗi người mỗi phút |
| `15.try.rate-per-app-day` | 3.000 | 100…50.000 | Lượt thử mỗi ứng dụng mỗi ngày |
| `15.try.rate-tenant-rps` | 100 | 10…500 | Lượt thử mỗi giây toàn tenant |
| `15.try.max-body-kb` | 256 | 16…1.024 | Cỡ thân yêu cầu tối đa |
| `15.try.timeout-seconds` | 15 | 5…30 | Thời gian chờ backend thử |
| `15.try.history-days` | 30 | 7…90 | Thời gian giữ lịch sử thử |
| `15.try.prod-enabled` | `false` | | Công tắc tổng cho thử production |
| `15.try.prod-max-days` | 90 | 1…90 | Thời hạn tối đa mỗi lần bật |
| `15.try.prod-rate-per-user-min` | 10 | 1…30 | Lượt thử production mỗi người mỗi phút |
| `15.content.review-sla-days` | 3 | 1…14 | Hạn duyệt nội dung trước khi nhắc |
| `15.git.sync-interval-minutes` | 30 | 5…1.440 | Chu kỳ đồng bộ kho Git |
| `15.support.sla-hours` | 24 | 4…120 | Hạn phản hồi đầu của phiếu |
| `15.search.engine` | `OPENSEARCH` | `OPENSEARCH`, `PG_FTS` | Bộ máy tìm kiếm; `PG_FTS` là dự phòng |

: Tham số theo tenant của PH-15

## 9. Mã lỗi, sự kiện và API

Chương này gom ba danh mục dùng chung cho mọi chức năng: mã lỗi kèm mã HTTP và câu thông báo, sự kiện PH-15 phát và tiêu thụ, và bảng tóm lược API. Định dạng lỗi theo `application/problem+json` (RFC 9457) với `code`, `title`, `detail`, `traceId`, `instance`, như ở D03-06-00.

### 9.1. Mã lỗi ERR-15

Mã `ERR-15-001…040` thuộc phần quản lý (control plane); `ERR-15-101…123` thuộc sandbox và thử API. Câu thông báo viết cho người dùng cuối, không nêu chi tiết nội bộ; `{…}` là giá trị được điền lúc chạy.

| Mã | HTTP | Ý nghĩa | Thông báo cho người dùng |
|---|---|---|---|
| ERR-15-001 | 404 | Không tìm thấy hoặc ngoài tầm nhìn | Không tìm thấy nội dung yêu cầu. |
| ERR-15-002 | 409 | Mã đã được dùng | Mã {mã} đã được dùng. Chọn mã khác. |
| ERR-15-003 | 400 | Dữ liệu gửi lên không hợp lệ | Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu. |
| ERR-15-004 | 401 | Chưa đăng nhập hoặc phiên hết hạn | Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục. |
| ERR-15-005 | 403 | Không đủ quyền | Bạn không có quyền thực hiện thao tác này. |
| ERR-15-006 | 412 | Xung đột phiên bản sửa (`If-Match`) | Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp. |
| ERR-15-007 | 429 | Quá tần suất thao tác | Thao tác quá nhanh. Thử lại sau {n} giây. |
| ERR-15-008 | 503 | Danh mục chưa sẵn sàng | Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút. |
| ERR-15-009 | 422 | Đặc tả không đọc được | Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ. |
| ERR-15-010 | 409 | Chưa chấp nhận điều khoản hiện hành | Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục. |
| ERR-15-011 | 422 | Tài khoản chưa xác minh hoặc chưa duyệt | Tài khoản chưa được xác minh hoặc chưa được duyệt. |
| ERR-15-012 | 409 | Thư điện tử trùng | Thư điện tử này đã được đăng ký. |
| ERR-15-013 | 400 | Mã xác minh sai hoặc hết hạn | Mã xác minh không đúng hoặc đã hết hạn. |
| ERR-15-014 | 403 | Tài khoản bị khóa | Tài khoản đang bị khóa. Liên hệ quản trị cổng. |
| ERR-15-015 | 422 | Vượt số ứng dụng | Đã đạt số ứng dụng tối đa ({n}). Lưu trữ ứng dụng không dùng để tạo mới. |
| ERR-15-016 | 422 | Vượt số thông tin xác thực | Ứng dụng đã đạt số thông tin xác thực tối đa ({n}). |
| ERR-15-017 | 409 | Ứng dụng sai trạng thái | Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này. |
| ERR-15-018 | 409 | Thông tin xác thực sai trạng thái | Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này. |
| ERR-15-019 | 410 | Bí mật đã hiển thị | Bí mật chỉ hiện một lần và không xem lại được. Tạo thông tin xác thực mới nếu đã mất. |
| ERR-15-020 | 503 | Dịch vụ định danh (Keycloak) lỗi | Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau. |
| ERR-15-021 | 422 | Nội dung không hợp lệ | Nội dung có phần không được phép: {chi tiết}. |
| ERR-15-022 | 409 | Trang nội dung hoặc tài khoản sai trạng thái | Đối tượng đang {trạng thái} nên không thực hiện được thao tác này. |
| ERR-15-023 | 403 | Vi phạm bốn mắt | Người duyệt phải khác người soạn và người gửi duyệt. |
| ERR-15-024 | 422 | Tệp đính kèm không hợp lệ | Tệp không hợp lệ: chỉ nhận PNG, JPEG, WebP tối đa 5 MB và không có mã độc. |
| ERR-15-025 | 502 | Kho Git lỗi | Chưa kết nối được kho Git. Thử lại sau. |
| ERR-15-026 | 422 | Cấu trúc kho Git hoặc gói di trú sai | Gói di trú sai cấu trúc hoặc có tệp không được phép. |
| ERR-15-027 | 409 | Đã là thành viên hoặc đã có lời mời | Người này đã là thành viên hoặc đã có lời mời. |
| ERR-15-028 | 422 | Chủ sở hữu duy nhất | Phải còn ít nhất một chủ sở hữu. |
| ERR-15-029 | 409 | Phiếu đã đóng | Phiếu đã đóng. Tạo phiếu mới nếu cần. |
| ERR-15-030 | 502 | PH-02 lỗi | Chưa kết nối được dịch vụ danh mục. |
| ERR-15-031 | 502 | PH-01 lỗi | Chưa kết nối được dịch vụ kết nạp. Thử lại sau. |
| ERR-15-032 | 422 | Không phải đầu mối hoặc chưa có HTTT hoạt động | Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này. |
| ERR-15-033 | 422 | Nhận diện không hợp lệ | Thông tin nhận diện chưa hợp lệ. |
| ERR-15-034 | 422 | Tham số ngoài miền | Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}. |
| ERR-15-035 | 409 | Đồng bộ hoặc di trú đang chạy | Đang có lần chạy khác. Đợi hoàn tất rồi thử lại. |
| ERR-15-036 | 403 | Khu quản trị chỉ từ mạng quản trị | Khu quản trị chỉ truy cập được từ mạng quản trị. |
| ERR-15-037 | 429 | Gửi quá nhiều (phiếu, hỏi đáp, đăng ký) | Bạn gửi quá nhiều. Thử lại sau {n} phút. |
| ERR-15-038 | 410 | Phiên bản đã ngừng | Phiên bản này đã ngừng cung cấp. |
| ERR-15-039 | 502 | PH-13 lỗi | Chưa tải được nhật ký hoặc số liệu. Thử lại sau. |
| ERR-15-040 | 422 | Dịch vụ không đủ điều kiện | Dịch vụ này chưa đủ điều kiện cho thao tác này. |
| ERR-15-101 | 422 | Dịch vụ chưa bật sandbox | Dịch vụ này chưa bật sandbox. |
| ERR-15-102 | 403 | Ứng dụng không đủ điều kiện thử | Ứng dụng chưa đủ điều kiện thử. Kiểm tra ứng dụng đang hoạt động và có thông tin xác thực. |
| ERR-15-103 | 429 | Vượt hạn mức theo người | Bạn đã vượt hạn mức thử mỗi phút. Thử lại sau {n} giây. |
| ERR-15-104 | 429 | Vượt hạn mức theo ứng dụng | Ứng dụng đã vượt hạn mức thử trong ngày. |
| ERR-15-105 | 413 | Thân yêu cầu quá lớn | Nội dung gửi vượt {n} KB. |
| ERR-15-106 | 422 | Dữ liệu cá nhân thật | Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả. |
| ERR-15-107 | 422 | Không khớp đặc tả | Yêu cầu không khớp đặc tả: {chi tiết}. |
| ERR-15-108 | 504 | Backend thử quá hạn | Hệ thống thử không phản hồi trong {n} giây. |
| ERR-15-109 | 502 | Backend thử lỗi | Hệ thống thử trả lỗi. |
| ERR-15-110 | 422 | Không sinh được phản hồi MOCK | Chưa sinh được phản hồi mẫu. Dịch vụ thiếu ví dụ hoặc lược đồ. |
| ERR-15-111 | 503 | Gateway sandbox không sẵn sàng | Cổng thử đang bảo trì. Thử lại sau. |
| ERR-15-112 | 403 | Chưa bật thử production | Dịch vụ này chưa bật thử trên môi trường thật. |
| ERR-15-113 | 403 | Không có đăng ký sử dụng ACTIVE | Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này. |
| ERR-15-114 | 403 | Dữ liệu nhạy cảm | Dịch vụ có dữ liệu nhạy cảm không cho thử trên môi trường thật. |
| ERR-15-115 | 503 | Kiểm toán lỗi nên từ chối thử | Chưa ghi được nhật ký nên không thử được lúc này. |
| ERR-15-116 | 422 | Phương thức bị chặn | Phương thức {phương thức} không được phép ở môi trường này. |
| ERR-15-117 | 502 | Token exchange lỗi | Chưa lấy được quyền truy cập tạm thời. Thử lại sau. |
| ERR-15-118 | 429 | Vượt hạn mức production | Vượt hạn mức thử trên môi trường thật. |
| ERR-15-119 | 422 | Địa chỉ ngoài allowlist | Địa chỉ hệ thống thử không nằm trong danh sách cho phép. |
| ERR-15-120 | 409 | Thiếu cấu hình theo chế độ | Dịch vụ thiếu cấu hình cho chế độ {chế độ}. |
| ERR-15-121 | 422 | Tiêu đề bị cấm | Tiêu đề {tên} không được phép gửi. |
| ERR-15-122 | 403 | Phiên bản không cho thử | Phiên bản này không cho thử. |
| ERR-15-123 | 413 | Phản hồi vượt cỡ | Phản hồi vượt cỡ cho phép và đã bị cắt. |

: Bảng mã lỗi ERR-15

### 9.2. Sự kiện EVT-15

PH-15 phát mười bốn sự kiện nghiệp vụ lên Kafka qua outbox, theo mẫu chủ đề `{tenant}.portal.{thực-thể}.{sự-kiện}.v1` và lược đồ Avro ở Apicurio (chế độ BACKWARD). Sự kiện không mang bí mật hay thân yêu cầu; PH-13 và PH-12 là bên nhận chính.

| Mã | Chủ đề (hậu tố) | FR phát | Nội dung chính | Bên nhận |
|---|---|---|---|---|
| EVT-15-01 | `app.created` | 025 | `appCode`, `ownerType`, `ownerId` | PH-13 |
| EVT-15-02 | `app.state-changed` | 026, 059 | `appCode`, `from`, `to`, `reason` | PH-13, PH-03 |
| EVT-15-03 | `credential.issued` | 027, 028 | `appCode`, `credentialId`, `kind`, `expiresAt` | PH-13 |
| EVT-15-04 | `credential.rotated` | 030 | `appCode`, `credentialId`, `newCredentialId`, `graceUntil` | PH-13 |
| EVT-15-05 | `credential.revoked` | 031 | `appCode`, `credentialId`, `reason`: `REVOKED_BY_OWNER`, `EXPIRED`, `APP_ARCHIVED`, `ADMIN_LOCK` | PH-03, PH-13 |
| EVT-15-06 | `devaccount.registered` | 020 | `userId`, `organization` | PH-13 |
| EVT-15-07 | `devaccount.state-changed` | 024, 058, 059 | `userId`, `from`, `to` | PH-13 |
| EVT-15-08 | `content.published` | 015 | `pageCode`, `versionNo`, `audience` | PH-13 |
| EVT-15-09 | `content.unpublished` | 016 | `pageCode`, `versionNo` | PH-13 |
| EVT-15-10 | `try.production-state-changed` | 042 | `apiCode`, `from`, `to`, `expiresAt` | PH-13 |
| EVT-15-11 | `try.executed` | 035, 043 | `tryId`, `env`, `apiCode`, `result`, `latencyMs` (không thân) | PH-13 |
| EVT-15-12 | `support.ticket-opened` | 053, 054, 055 | `ticketCode`, `kind`, `status` | PH-13, PH-10 |
| EVT-15-13 | `team.member-changed` | 022, 033 | `teamCode` hoặc `appCode`, `userId`, `role`, `change`: `ADDED`, `ROLE_CHANGED`, `REMOVED` | PH-13 |
| EVT-15-14 | `sync.state-changed` | 001, 061 | `from`, `to`, `lagSeconds` | PH-13 |

: Sự kiện do PH-15 phát

Cổng tiêu thụ các sự kiện do PH-02 phát để cập nhật bản sao danh mục và thông báo cho người theo dõi: EVT-02-01, EVT-02-02, EVT-02-03, EVT-02-05, EVT-02-06, EVT-02-08, EVT-02-10, EVT-02-11, EVT-02-12. Cổng cũng nhận EVT-02-09 (đăng ký sử dụng đổi trạng thái) để cập nhật đăng ký của người dùng; theo BR-15-014, cổng không phát lại sự kiện này.

### 9.3. Tóm lược API

Mọi đường dẫn dưới đây có tiền tố `/api/portal/v1`, trừ API-15-082 có đường dẫn gốc `/internal/v1/sandbox/authorize` (cổng 8081, mTLS mesh, không qua BFF, không có tiền tố này); phần `/public` là ẩn danh, `/try` là thử, `/admin` là quản trị, `/internal/v1` là đường nội bộ giữa gateway sandbox và cổng. Đặc tả đầy đủ (lược đồ, mã trả về) sinh từ OpenAPI của module `portal` ở D03-06-00 §4.17.

| Mã | Phương thức | Đường dẫn | FR-15 |
|---|---|---|---|
| API-15-001 | GET | `/public/home` | 003 |
| API-15-002 | GET | `/home` | 003 |
| API-15-003 | GET | `/public/catalog/apis` | 002, 008 |
| API-15-004 | GET | `/public/catalog/apis/{apiCode}` | 002, 008 |
| API-15-005 | GET | `/catalog/apis` | 002, 004 |
| API-15-006 | GET | `/catalog/facets` | 004 |
| API-15-007 | GET | `/catalog/apis/{apiCode}` | 002, 006 |
| API-15-008 | GET | `/catalog/apis/{apiCode}/usage` | 006 |
| API-15-009 | GET | `/catalog/sync-status` | 001 |
| API-15-010 | GET | `/public/search` | 005, 008 |
| API-15-011 | GET | `/search` | 005 |
| API-15-012 | GET | `/search/suggest` | 005 |
| API-15-013 | GET | `/catalog/topics` | 007 |
| API-15-014 | GET | `/catalog/topics/{topicCode}` | 007 |
| API-15-015 | GET | `/catalog/apis/{apiCode}/versions` | 011 |
| API-15-016 | GET | `/catalog/apis/{apiCode}/versions/{versionNo}/spec` | 009, 011 |
| API-15-017 | GET | `/catalog/apis/{apiCode}/versions/{versionNo}/operations` | 009 |
| API-15-018 | GET | `/catalog/topics/{topicCode}/events` | 010 |
| API-15-019 | GET | `/catalog/apis/{apiCode}/samples` | 012 |
| API-15-020 | GET | `/catalog/apis/{apiCode}/diff` | 011 |
| API-15-021 | GET | `/catalog/apis/{apiCode}/changelog` | 013 |
| API-15-022 | GET | `/content/pages` | 014 |
| API-15-023 | POST | `/content/pages` | 014 |
| API-15-024 | GET | `/content/pages/{pageCode}` | 014 |
| API-15-025 | PUT | `/content/pages/{pageCode}` | 014 |
| API-15-026 | POST | `/content/pages/{pageCode}:submit` | 015 |
| API-15-027 | POST | `/content/pages/{pageCode}:approve` | 015 |
| API-15-028 | POST | `/content/pages/{pageCode}:reject` | 015 |
| API-15-029 | POST | `/content/pages/{pageCode}:unpublish` | 016 |
| API-15-030 | GET | `/content/pages/{pageCode}/versions` | 016 |
| API-15-031 | GET | `/content/pages/{pageCode}/versions/{versionNo}` | 016 |
| API-15-032 | POST | `/content/pages/{pageCode}/versions/{versionNo}:restore` | 016 |
| API-15-033 | POST | `/content/attachments` | 014, 017 |
| API-15-034 | GET | `/public/pages` | 017 |
| API-15-035 | GET | `/public/pages/{pageCode}` | 017 |
| API-15-036 | GET | `/pages` | 017 |
| API-15-037 | GET | `/pages/{pageCode}` | 017 |
| API-15-038 | GET | `/content/git-sources` | 018 |
| API-15-039 | POST | `/content/git-sources` | 018 |
| API-15-040 | POST | `/content/git-sources/{sourceId}:sync` | 018 |
| API-15-041 | GET | `/me` | 021 |
| API-15-042 | PUT | `/me` | 021 |
| API-15-043 | GET | `/me/sessions` | 021 |
| API-15-044 | DELETE | `/me/sessions/{sessionId}` | 021 |
| API-15-045 | POST | `/developer-registrations` | 020 |
| API-15-046 | POST | `/developer-registrations:verify-email` | 020 |
| API-15-047 | GET | `/terms/current` | 023 |
| API-15-048 | POST | `/terms/acceptances` | 023 |
| API-15-049 | GET | `/teams` | 022 |
| API-15-050 | POST | `/teams` | 022 |
| API-15-051 | POST | `/teams/{teamCode}/invitations` | 022 |
| API-15-052 | POST | `/me/invitations/{invitationId}:respond` | 022 |
| API-15-053 | DELETE | `/teams/{teamCode}/members/{userId}` | 022 |
| API-15-054 | POST | `/me:request-erasure` | 024 |
| API-15-055 | GET | `/apps` | 025 |
| API-15-056 | POST | `/apps` | 025 |
| API-15-057 | GET | `/apps/{appCode}` | 025 |
| API-15-058 | PATCH | `/apps/{appCode}` | 026 |
| API-15-059 | POST | `/apps/{appCode}:archive` | 026 |
| API-15-060 | POST | `/apps/{appCode}:restore` | 026 |
| API-15-061 | GET | `/apps/{appCode}/credentials` | 027 |
| API-15-062 | POST | `/apps/{appCode}/credentials` | 027, 028, 029 |
| API-15-063 | POST | `/apps/{appCode}/credentials/{credentialId}:rotate` | 030 |
| API-15-064 | POST | `/apps/{appCode}/credentials/{credentialId}:revoke` | 031 |
| API-15-065 | GET | `/apps/{appCode}/prod-credentials` | 032 |
| API-15-066 | GET | `/apps/{appCode}/members` | 033 |
| API-15-067 | PUT | `/apps/{appCode}/members/{userId}` | 033 |
| API-15-068 | DELETE | `/apps/{appCode}/members/{userId}` | 033 |
| API-15-069 | GET | `/catalog/apis/{apiCode}/sandbox` | 034 |
| API-15-070 | PUT | `/catalog/apis/{apiCode}/sandbox` | 034 |
| API-15-071 | POST | `/try/requests:validate` | 038 |
| API-15-072 | POST | `/try/requests` | 035, 036, 037, 043 |
| API-15-073 | GET | `/try/requests/{tryId}` | 035 |
| API-15-074 | GET | `/try/quota` | 039 |
| API-15-075 | GET | `/try/history` | 040 |
| API-15-076 | DELETE | `/try/history` | 040 |
| API-15-077 | GET | `/try/collections` | 040 |
| API-15-078 | POST | `/try/collections` | 040 |
| API-15-079 | PUT | `/try/collections/{collectionId}` | 040 |
| API-15-080 | DELETE | `/try/collections/{collectionId}` | 040 |
| API-15-081 | GET | `/try/collections/{collectionId}/export` | 041 |
| API-15-082 | POST | `/internal/v1/sandbox/authorize` | 035, 039 |
| API-15-083 | GET | `/admin/try-production` | 042 |
| API-15-084 | PUT | `/admin/try-production/{apiCode}` | 042 |
| API-15-085 | POST | `/admin/try-production/{apiCode}:approve` | 042 |
| API-15-086 | POST | `/admin/try-production/{apiCode}:disable` | 042 |
| API-15-087 | POST | `/subscriptions` | 044 |
| API-15-088 | GET | `/subscriptions` | 045 |
| API-15-089 | GET | `/subscriptions/{subscriptionId}` | 045 |
| API-15-090 | POST | `/subscriptions/{subscriptionId}:cancel` | 045 |
| API-15-091 | POST | `/onboarding/applications` | 046 |
| API-15-092 | GET | `/onboarding/applications` | 046 |
| API-15-093 | GET | `/onboarding/applications/{applicationId}` | 046 |
| API-15-094 | POST | `/publications` | 047 |
| API-15-095 | GET | `/publications` | 047 |
| API-15-096 | GET | `/publications/{publicationId}` | 047 |
| API-15-097 | GET | `/dashboard` | 048 |
| API-15-098 | GET | `/apps/{appCode}/stats` | 049 |
| API-15-099 | GET | `/apps/{appCode}/logs` | 050 |
| API-15-100 | GET | `/apps/{appCode}/logs/{logId}` | 050 |
| API-15-101 | GET | `/notification-subscriptions` | 051 |
| API-15-102 | PUT | `/notification-subscriptions/{apiCode}` | 051 |
| API-15-103 | DELETE | `/notification-subscriptions/{apiCode}` | 051 |
| API-15-104 | GET | `/inbox` | 052 |
| API-15-105 | POST | `/inbox/{messageId}:read` | 052 |
| API-15-106 | POST | `/inbox:read-all` | 052 |
| API-15-107 | GET | `/catalog/apis/{apiCode}/questions` | 053 |
| API-15-108 | POST | `/catalog/apis/{apiCode}/questions` | 053 |
| API-15-109 | POST | `/feedback` | 053 |
| API-15-110 | POST | `/support/tickets` | 054 |
| API-15-111 | GET | `/support/tickets` | 054 |
| API-15-112 | GET | `/support/tickets/{ticketCode}` | 054 |
| API-15-113 | POST | `/support/tickets/{ticketCode}/messages` | 054 |
| API-15-114 | GET | `/admin/support/tickets` | 055 |
| API-15-115 | POST | `/admin/support/tickets/{ticketCode}:transition` | 055 |
| API-15-116 | GET | `/admin/branding` | 056 |
| API-15-117 | PUT | `/admin/branding` | 056 |
| API-15-118 | POST | `/admin/branding/logo` | 056 |
| API-15-119 | GET | `/admin/settings` | 057 |
| API-15-120 | PUT | `/admin/settings` | 057 |
| API-15-121 | GET | `/admin/dev-accounts` | 058 |
| API-15-122 | POST | `/admin/dev-accounts/{userId}:approve` | 058 |
| API-15-123 | POST | `/admin/dev-accounts/{userId}:reject` | 058 |
| API-15-124 | POST | `/admin/dev-accounts/{userId}:lock` | 059 |
| API-15-125 | POST | `/admin/dev-accounts/{userId}:unlock` | 059 |
| API-15-126 | POST | `/admin/apps/{appCode}:suspend` | 059 |
| API-15-127 | POST | `/admin/apps/{appCode}:resume` | 059 |
| API-15-128 | GET | `/admin/audit` | 060 |
| API-15-129 | GET | `/admin/usage-report` | 060 |
| API-15-130 | POST | `/admin/audit:export` | 060 |
| API-15-131 | POST | `/admin/sync:run` | 061 |
| API-15-132 | GET | `/admin/sync/runs` | 061 |
| API-15-133 | POST | `/admin/reconciliations` | 061 |
| API-15-134 | GET | `/admin/reconciliations/latest` | 061 |
| API-15-135 | POST | `/admin/migrations` | 062 |
| API-15-136 | GET | `/admin/migrations/{migrationId}` | 062 |
| API-15-137 | POST | `/admin/migrations/{migrationId}:confirm` | 062 |
| API-15-138 | GET | `/content/attachments/{attachmentId}` | 014, 017 |
| API-15-139 | GET | `/public/branding` | 003, 056 |
| API-15-140 | GET | `/inbox/unread-count` | 052 |
| API-15-141 | GET | `/apps:check-code` | 025 |
| API-15-142 | GET | `/content/pages/{pageCode}/diff` | 016 |

: Bảng tóm lược API-15

Danh mục trên có 142 operation (API-15-138…142 thêm ở bản 0.2 theo đề nghị của tập thiết kế API và màn hình); mọi thao tác ghi dùng `Idempotency-Key` và `If-Match` theo BR-15-034, mọi danh sách dùng `trang`, `co`, `sap-xep` theo Phụ lục A.4.

## 10. Danh sách màn hình UI-15

Mục này liệt kê màn hình ở mức chức năng: tên, đường dẫn, người dùng chính, mẫu giao diện (PTN) và chức năng hiện thực. Bố cục chi tiết, thành phần và nhãn thuộc tài liệu thiết kế giao diện D03-05; ở đây chỉ chốt phạm vi và quan hệ với FR.

| Mã | Màn hình | Đường dẫn | Người dùng chính | PTN | FR-15 |
|---|---|---|---|---|---|
| UI-15-01 | Trang chủ | `/` | Mọi người xem | | 003, 008 |
| UI-15-02 | Danh mục dịch vụ | `/dich-vu` | Mọi người xem | | 001, 002, 004, 007, 008 |
| UI-15-03 | Kết quả tìm kiếm | `/tim-kiem` | Mọi người xem | | 005 |
| UI-15-04 | Chi tiết dịch vụ | `/dich-vu/{ma-api}` | Mọi người xem | | 002, 006, 007, 008, 013, 053 |
| UI-15-05 | Tài liệu API | `/dich-vu/{ma-api}/tai-lieu` | Mọi người xem | PTN-14 | 009…013 |
| UI-15-06 | Thử API | `/dich-vu/{ma-api}/thu` | DEV, cán bộ | PTN-14 | 035…039, 043 |
| UI-15-07 | Hướng dẫn, FAQ, thông báo | `/huong-dan`, `/hoi-dap`, `/thong-bao` | Mọi người xem | PTN-14 | 017, 053 |
| UI-15-08 | Đăng nhập và đăng ký dh-dev | `/dang-nhap`, `/dang-ky` | Nhà thầu | | 019, 020 |
| UI-15-09 | Hồ sơ, điều khoản, nhóm | `/tai-khoan…` | Người đã đăng nhập | PTN-12 | 021…024 |
| UI-15-10 | Danh sách ứng dụng | `/ung-dung` | DEV | PTN-01 | 026 |
| UI-15-11 | Tạo ứng dụng | `/ung-dung/moi` | DEV | PTN-04 | 025 |
| UI-15-12 | Chi tiết ứng dụng | `/ung-dung/{ma-ung-dung}` | DEV | PTN-02 | 026, 033, 049, 050 |
| UI-15-13 | Thông tin xác thực | `/ung-dung/{ma}/xac-thuc` | DEV | | 027…032 |
| UI-15-14 | Lịch sử và bộ sưu tập thử | tab `bo-suu-tap` | DEV | PTN-11 | 040, 041 |
| UI-15-15 | Đăng ký sử dụng | `/dang-ky-su-dung` | Cán bộ đầu mối | PTN-05 | 044, 045 |
| UI-15-16 | Kết nạp HTTT | `/ket-nap` | Cán bộ đầu mối | PTN-05 | 046 |
| UI-15-17 | Công bố API | `/cong-bo`, `/cong-bo/moi` | Cán bộ đầu mối | PTN-05 | 047 |
| UI-15-18 | Tổng quan cá nhân | `/tong-quan` | Người đã đăng nhập | PTN-06 | 048 |
| UI-15-19 | Hộp thông báo và theo dõi | `/tai-khoan/thong-bao` | Người đã đăng nhập | | 051, 052 |
| UI-15-20 | Hỗ trợ và hỏi đáp | `/ho-tro…` | Người đã đăng nhập | | 053, 054 |
| UI-15-21 | Soạn trang nội dung | `/quan-tri-cong/noi-dung/{ma-trang}` | Biên tập viên | PTN-03 | 014, 018 |
| UI-15-22 | Duyệt nội dung, quản lý trang | `/quan-tri-cong/noi-dung` | Người duyệt | PTN-10 | 015, 016 |
| UI-15-23 | Khai báo sandbox và thử production | `/quan-tri-cong/dich-vu/{ma-api}` | Chủ dịch vụ, TA | | 034, 042 |
| UI-15-24 | Quản trị tài khoản dh-dev và ứng dụng | `/quan-tri-cong/tai-khoan-dev` | TA, SO | PTN-10 | 024, 058, 059 |
| UI-15-25 | Nhận diện và tham số cổng | `/quan-tri-cong/nhan-dien`, `/tham-so` | TA, CA | PTN-12 | 056, 057 |
| UI-15-26 | Nhật ký truy cập, thử, báo cáo | `/quan-tri-cong/nhat-ky` | TA, AU | PTN-11 | 060 |
| UI-15-27 | Đồng bộ, đối soát, di trú | `/quan-tri-cong/dong-bo`, `/di-tru` | TA, CA | PTN-05 | 001, 018, 061, 062 |
| UI-15-28 | Hộp xử lý hỗ trợ | `/quan-tri-cong/ho-tro` | Đầu mối hỗ trợ | PTN-10 | 055 |

: Danh sách màn hình UI-15

Mọi màn hình dùng `@datahub/ui` và Liquid Glass (ADR-020), thích ứng từ 360 px, đạt WCAG 2.2 AA (NFR-15-014). Giao diện quản trị công khai ở `/quan-tri-cong` là quyết định tạm của FRS; vị trí cuối cùng chờ Q15-16.

## 11. Truy vết

Chương này chứng minh phân hệ không bỏ sót chức năng hệ cũ: mỗi mục LGC của PH-15 ở D00-03 nối với FR, mỗi FR của SRS cũ nối với FR mới, và mỗi FR nối với yêu cầu mức cao REQ-15 ở D02-01.

### 11.1. Chức năng hệ cũ (LGC) sang FR

Bảng dưới phủ toàn bộ hàng PH-15 trong D00-03 cùng hai mục liên quan; mỗi mục có đúng một kết luận.

| LGC | Chức năng hệ cũ | Kết luận | FR-15 |
|---|---|---|---|
| LGC-APIM-006 | Portal danh mục API cho nhà phát triển | Giữ nguyên | 001, 002, 062 |
| LGC-APIM-007 | Công bố API công khai theo tenant | Giữ nguyên, nâng mức hiển thị | 002, 008, 056 |
| LGC-APIM-017 | Tài liệu API (Swagger) | Giữ nguyên | 006, 009, 012 |
| LGC-IAM-006 | Cấp credential tự phục vụ cho ứng dụng | Thay thế (client sandbox ở realm dh-dev, không cấp production) | 012, 014, 027, 030 |
| LGC-APIM-022 (phần nhà phát triển) | Thống kê sử dụng API | Nâng cấp | 049, 050 |
| LGC-APIM-019, LGC-APIM-020 (liên quan) | Đăng ký sử dụng, kết nạp | Liên quan: ủy thác cho PH-02, PH-01 | 025, 032, 046 |

: Truy vết LGC sang FR của PH-15

### 11.2. SRS cũ sang FR mới

Tệp `docs/07-srs/SRS-PH-15-portal.md` có mười sáu FR. Bảng dưới ánh xạ từng mã cũ (viết "SRS cũ FR-15-0xx") sang FR mới và ghi khác biệt đáng kể.

| Mã cũ | Nội dung cũ | FR-15 mới | Khác biệt |
|---|---|---|---|
| SRS cũ FR-15-001 | Đồng bộ danh mục từ APIM | 001, 002, 061 | Nguồn là PH-02, thêm đối soát |
| SRS cũ FR-15-002 | Lọc theo mức hiển thị | 002, 004, 005 | Thêm hạng DEV_USER |
| SRS cũ FR-15-003 | Hiển thị Swagger | 006, 009, 035 | OpenAPI 3.1, thử qua sandbox |
| SRS cũ FR-15-004 | Tài liệu theo phiên bản | 009, 011 | Thêm so sánh phiên bản |
| SRS cũ FR-15-005 | Làm mới danh mục | 001, 013, 061 | Sự kiện cộng kéo bù |
| SRS cũ FR-15-006 | Trang chi tiết API | 002, 006, 008 | Thêm SLA, đường dẫn sử dụng |
| SRS cũ FR-15-007 | Sandbox thử API | 034…043 | MOCK và BACKEND, thử production hạn chế |
| SRS cũ FR-15-008 | Cấp credential | 025…033 | Client realm dh-dev, không token ≤ 24 giờ của PH-01 và PH-12 |
| SRS cũ FR-15-009 | Tài liệu TechDocs | 014…018 | Markdown CMS và Git thay Backstage |
| SRS cũ FR-15-010 | Soạn tài liệu | 014 | Bốn mắt |
| SRS cũ FR-15-011 | Tìm kiếm | 005 | Tiếng Việt không dấu, gợi ý |
| SRS cũ FR-15-012 | Đăng ký sử dụng | 046 | Ủy thác PH-01 |
| SRS cũ FR-15-013 | Công bố API | 047 | Ủy thác PH-02 |
| SRS cũ FR-15-014 | Tài khoản nhà phát triển | 019, 020, 021 | Xác minh thư, duyệt, vô hiệu 45 ngày |
| SRS cũ FR-15-015 | Kiểm toán truy cập | 060 | Cộng kiểm toán từng FR |
| SRS cũ FR-15-016 | Thống kê sử dụng | 048, 049, 050 | Theo ứng dụng, che dữ liệu |

: Ánh xạ SRS cũ sang FR mới

Ghi chú về các mục có số FR chồng: SRS cũ FR-15-007 và FR-15-008 gộp nhiều yêu cầu nhỏ; FRS mới tách để mỗi FR có một mục đích kiểm thử độc lập.

### 11.3. FR sang yêu cầu mức cao REQ-15

Mọi FR của PH-15 truy về REQ-15 ở D02-01 (BO-03, BP-01, BP-02, BP-09). Cột "Truy vết" của từng đặc tả ghi thêm LGC, SRS cũ, FR-00 và ADR liên quan. Tổng hợp theo nhóm ở bảng sau.

| Nhóm | FR-15 | Căn cứ mức cao |
|---|---|---|
| A Danh mục, tìm kiếm, truy cập | 001…008 | REQ-15, BP-01 bước tìm dịch vụ |
| B Tài liệu API | 009…013 | REQ-15, BP-01 bước đọc tài liệu |
| C Hướng dẫn, nội dung | 014…018 | REQ-15, BP-09 |
| D Tài khoản | 019…024 | REQ-15, BO-03 |
| E Ứng dụng, thông tin xác thực | 025…033 | REQ-15, BP-01 bước nhận thông tin sandbox |
| F Sandbox, thử | 034…043 | REQ-15, BO-03 |
| G Đăng ký, điểm vào | 044…047 | REQ-15, BP-01, BP-02 |
| H Theo dõi | 048…052 | REQ-15, BP-01 |
| I Hỗ trợ | 053…055 | REQ-15 |
| J Quản trị cổng | 056…062 | REQ-15, BP-09 |

: Truy vết nhóm FR sang REQ-15

## 12. Phụ thuộc, giả định và ràng buộc

Phần này nêu những gì PH-15 cần từ phân hệ khác, các giả định dùng để đặt chỉ tiêu và các ràng buộc cố định.

### 12.1. Phụ thuộc

PH-15 chạy được khi các bên sau cung cấp đúng giao diện đã thỏa thuận; việc đề nghị bổ sung nằm ở mục "Đề nghị đồng bộ".

| Phân hệ | Cần gì | Dùng ở |
|---|---|---|
| PH-02 | API danh mục cổng (API-02-081), mẫu gọi API-02-006, sự kiện EVT-02-xx, đăng ký sử dụng, công bố API | FR 001…013, 044, 045, 047, 061 |
| PH-01 | Biểu mẫu kết nạp, định danh production chỉ đọc | FR 032, 046 |
| PH-12 | Realm `dh-realm`, `dh-dev`, Admin API giới hạn, token exchange, OPA | FR 019…032, 043, 058, 059 |
| PH-03 | Tuyến sandbox tĩnh và plugin `forward-auth` gọi API-15-082 | FR 035, 039 |
| PH-13 | Nhật ký kiểm toán, chỉ số, số liệu theo `app_code` | FR 048…050, 060 |
| PH-10, PH-18 | Thông báo và kho tham số `15.*` | FR 051, 052, 057 |

: Phụ thuộc của PH-15

### 12.2. Giả định và ràng buộc

Giả định dùng để đặt chỉ tiêu; nếu sai thì chỉ tiêu ở mục 8.1 đo lại. Ràng buộc là điều kiện cố định của kiến trúc đã chốt.

| Mã | Loại | Nội dung | Cơ sở |
|---|---|---|---|
| GĐ-15-01 | Giả định | Tenant vừa có 150 API, 300 tài khoản dh-dev, 120 ứng dụng; trần thiết kế theo NFR-15-012 | Hồ sơ "tỉnh vừa" (GĐ-07) |
| GĐ-15-02 | Giả định | Mỗi API có một đặc tả OpenAPI 3.1 hợp lệ do PH-02 giữ | D02-03-PH02 |
| GĐ-15-03 | Giả định | Tên miền sandbox mẫu `sandbox-api.{tenant}.datahub.gov.vn` và chứng thư do hạ tầng cấp | Q15-08 |
| GĐ-15-04 | Giả định | Chủ dịch vụ cung cấp backend thử không chứa dữ liệu thật | BR-15-016, BR-15-018 |
| RB-15-01 | Ràng buộc | Cổng không giữ bí mật sandbox, không giữ thông tin xác thực production | SEC-24, BR-15-015 |
| RB-15-02 | Ràng buộc | Token và phiên chỉ ở BFF, trình duyệt chỉ giữ cookie `__Host-dh-sid` | SEC-21 |
| RB-15-03 | Ràng buộc | Module `portal` chạy trong DU `dh-connect` (Z3), BFF nhẹ ở Z2 | D03-01 |
| RB-15-04 | Ràng buộc | Không dùng Backstage; giao diện tự xây trên `@datahub/ui` | đề xuất ADR số 075; ADR-020 |

: Giả định và ràng buộc của PH-15

## 13. Câu hỏi mở

Các câu hỏi dưới đây cần quyết định của chủ đầu tư, ATTT hoặc phân hệ khác; mỗi câu nêu phương án ngầm định FRS đang dùng để không chặn việc thiết kế.

> **Câu hỏi mở Q15-01:** Điều khoản sử dụng của cổng căn cứ NĐ 278/2025 nào, và có tương ứng Điều 24, 25 NĐ 47/2020 như FRS đang giả định không? Ngầm định: văn bản điều khoản do đơn vị pháp chế soạn, cổng chỉ quản lý phiên bản và ghi nhận chấp nhận.

> **Câu hỏi mở Q15-02:** Realm `dh-dev` dùng chung toàn nền tảng hay tách theo tenant? Ngầm định: dùng chung, có thuộc tính `tenantGrants`.

> **Câu hỏi mở Q15-03:** Người bảo lãnh và việc kiểm tra hợp đồng của nhà thầu do ai thực hiện, theo quy trình nào? Ngầm định: quản trị liên hệ đơn vị bảo lãnh ngoài cổng.

> **Câu hỏi mở Q15-04:** Cổng công khai có bật mặc định không, cần CAPTCHA và giới hạn IP thế nào? Ngầm định: tắt mặc định, giới hạn 120 lượt mỗi phút mỗi IP.

> **Câu hỏi mở Q15-05:** Thử production có cho phương thức ghi và mức `dataClass` nào (ý kiến ATTT)? Ngầm định: chỉ `GET`, `HEAD`, chỉ `PUBLIC`, `INTERNAL`.

> **Câu hỏi mở Q15-06:** Keycloak 26 có hỗ trợ token exchange theo RFC 8693 đủ cho `portal-try` không (PH-12 xác nhận)? Ngầm định: có, ở dạng tính năng chuẩn đã bật. Cập nhật 0.2: SDD QĐ-15-03 giữ phương án này, kèm dự phòng xác nhận JWS ký bằng khóa `transit` của OpenBao (Q15-20 của SDD).

> **Câu hỏi mở Q15-07:** Bộ sinh MOCK đặt trong DU `dh-connect` hay làm plugin APISIX (SDD chốt)? Ngầm định: trong `portal-mock` của `dh-connect`. Cập nhật 0.2: SDD QĐ-15-01 đã chốt phương án này với vai trò triển khai `portal-sandbox`.

> **Câu hỏi mở Q15-08:** Tên miền sandbox và chứng thư do ai cấp, theo mẫu nào? Ngầm định: `sandbox-api.{tenant}.datahub.gov.vn`, chứng thư của hạ tầng.

> **Câu hỏi mở Q15-09:** Dải dữ liệu giả quy ước và bộ luật PII-15 có đủ không? Ngầm định: dải ở Phụ lục A.7, ATTT bổ sung.

> **Câu hỏi mở Q15-10:** Hạ tầng và mạng của backend thử ở đâu, allowlist egress do ai quản? Ngầm định: PH-18 quản allowlist theo tenant.

> **Câu hỏi mở Q15-11:** Tìm kiếm mặc định là OpenSearch hay PostgreSQL FTS, và có dùng chung chỉ mục với PH-02 không? Ngầm định: OpenSearch riêng của cổng, dự phòng PG FTS (`15.search.engine`).

> **Câu hỏi mở Q15-12:** Có cho chia sẻ bộ sưu tập thử cho nhóm không (Đợt 3)? Ngầm định: không ở Đợt 2.

> **Câu hỏi mở Q15-13:** Kênh nhận bí mật production là gì, so với lời BP-01 "tự lấy trên cổng"? Ngầm định: cổng không hiển thị, cấp qua PH-01 và định danh production.

> **Câu hỏi mở Q15-14:** Tiếng Anh có bắt buộc không? Ngầm định: giao diện tiếng Việt, tiếng Anh nên có (Đợt 3).

> **Câu hỏi mở Q15-15:** Có tích hợp hệ thống ticket của tỉnh (ITSM, Một cửa) cho phiếu hỗ trợ không? Ngầm định: không, hộp xử lý riêng ở cổng.

> **Câu hỏi mở Q15-16:** Giao diện quản trị cổng đặt ở dh-portal `/quan-tri-cong` hay dh-console `/ket-noi/cong-nha-phat-trien` như D03-06-00 §2.14? Ngầm định: `/quan-tri-cong`.

> **Câu hỏi mở Q15-17:** Thời hạn lưu dữ liệu cá nhân của tài khoản dh-dev và yêu cầu DPIA là gì? Ngầm định: ẩn danh sau 24 tháng không hoạt động.

> **Câu hỏi mở Q15-18:** PH-13 và PH-03 có gắn nhãn chỉ số `app_code` được không? Ngầm định: có, nếu không thì FR-15-049 giảm xuống số liệu theo lượt thử.

> **Câu hỏi mở Q15-19:** PH-02 có trả trạng thái `SUSPENDED` trong danh mục cho cổng không? Ngầm định: có, để hiện nhãn tạm ngừng.

## 14. Tiêu chí chấp nhận cấp phân hệ

PH-15 được nghiệm thu khi mười tiêu chí dưới đây đạt trên môi trường thử nghiệm tích hợp với PH-02, PH-12, PH-03 và PH-13; chỉ tiêu số lấy từ mục 8.1.

| Mã | Tiêu chí | Cách kiểm |
|---|---|---|
| TC-15-01 | Danh mục của cổng khớp PH-02 sau đối soát, không mục lệch | FR-15-061, NFR-15-004 |
| TC-15-02 | Khách ẩn danh chỉ thấy API `PUBLIC` khi bật, và API ngoài tầm trả `404` như không tồn tại | Ca kiểm thử âm theo BR-15-002, BR-15-005 |
| TC-15-03 | Nhà thầu đăng ký, được duyệt, tạo ứng dụng và gọi sandbox thành công đầu tiên ≤ 15 phút | NFR-15-022 |
| TC-15-04 | Bí mật hiện đúng một lần, không có trong log, DB, bộ đệm | NFR-15-009 (canary) |
| TC-15-05 | Thu hồi hoặc khóa có hiệu lực ≤ 60 giây tại sandbox | NFR-15-007 |
| TC-15-06 | Thử production tắt mặc định, và bật chỉ với `PUBLIC`, `INTERNAL`, `GET`, `HEAD`, bốn mắt | BR-15-019…022 |
| TC-15-07 | Không ghi được kiểm toán thì từ chối thử production | BR-15-023, ERR-15-115 |
| TC-15-08 | Nội dung chỉ đăng sau duyệt bốn mắt và vượt kiểm thử XSS | BR-15-012, NFR-15-011 |
| TC-15-09 | Không token ở trình duyệt, không rò rỉ chéo tenant | NFR-15-010, NFR-15-017 |
| TC-15-10 | Đạt chỉ tiêu hiệu năng, khả năng truy cập và các FR mức M đều qua kiểm thử chấp nhận | NFR-15-001…003, NFR-15-014 |

: Tiêu chí chấp nhận cấp phân hệ

## 15. Đề nghị đồng bộ

FRS này chỉ sửa tệp PH-15. Các thay đổi cần ở tài liệu dùng chung hoặc phân hệ khác được nêu thành đề nghị để chủ các tài liệu đó quyết định; PH-15 giữ nguyên bản FRS cho tới khi có phản hồi. Các đề nghị đến từ các tập thiết kế của chính PH-15 được hấp thụ ở bản 0.2 và ghi ở mục 15.3.

### 15.1. Đề nghị cho tài liệu dùng chung

Bảng dưới liệt kê đề nghị cho D02-08, ADR, D03-06-00 và D00-04. Cập nhật 0.2: năm quyền `PERM-15-*` mới đã được thêm vào D02-08 nên dòng đầu đã xử lý.

| Tài liệu | Đề nghị | Lý do |
|---|---|---|
| D02-08 | Đã xử lý: năm quyền `PERM-15-content-write`, `PERM-15-content-publish`, `PERM-15-support`, `PERM-15-dev-approve`, `PERM-15-audit-read` đã được thêm vào D02-08 (TA, CA, SV ○, SO, AU, PA theo từng quyền); mục 3.2 đã khớp | Tách soạn, duyệt, hỗ trợ, duyệt tài khoản, xem nhật ký |
| D02-08 | Thêm scope máy `metrics:portal-read`, `sandbox:call`; cho `ROLE-DEVELOPER` tự gán với cán bộ đăng nhập SSO | Cổng đọc chỉ số và `forward-auth` kiểm quyền |
| ADR | Đề xuất ADR số 075: Cổng nhà phát triển tự xây trên `@datahub/ui` thay Backstage; dành dải 075 đến 079 cho PH-15. Không nhầm với ADR cũ về Backstage ở repo cũ | Quyết định công nghệ cổng |
| D03-06-00 §2.14, §2.3 | Đổi route `/api` thành `/dich-vu`, bỏ `/sandbox`, và chốt vị trí giao diện quản trị theo Q15-16 | Khớp Phụ lục A.4 |
| D00-04 | Ghi nhận dải mã `ERR-15-001…040`, `101…123`, `API-15-001…142`, `UI-15-01…28`, `EVT-15-01…14` | Tránh trùng mã |
| D03-05 | Không cần thành phần giao diện mới ngoài `@datahub/ui` | Giữ nhất quán |

: Đề nghị đồng bộ tài liệu dùng chung

### 15.2. Đề nghị cho các phân hệ

Mỗi dòng là một việc cụ thể cho chủ phân hệ, kèm FR của PH-15 phụ thuộc vào việc đó.

| Phân hệ | Việc cần làm | FR liên quan |
|---|---|---|
| PH-02 | Trả `SUSPENDED` trong `items[]` của API-02-081 (Q15-19), mẫu gọi API-02-006, giữ cờ `portalPublished` | 001, 002, 006 |
| PH-03 | Tuyến sandbox tĩnh kèm plugin `forward-auth` gọi API-15-082, mẫu route | 035, 039 |
| PH-12 | Realm `dh-dev`, client `portal-dev` giới hạn Admin API, token exchange cho `portal-try`, tự gán `ROLE-DEVELOPER` | 019…032, 043 |
| PH-13 | Scope `metrics:portal-read`, nhãn `app_code`, ghi kiểm toán đồng bộ | 049, 050, 060 |
| PH-01 | Lược đồ biểu mẫu kết nạp, API định danh production chỉ đọc | 032, 046 |
| PH-18 | Giữ tham số `15.*` ở mục 8.2 | 057 |
| PH-10 | Chấp nhận chủ đề `{tenant}.portal.*` và định tuyến thông báo | 051, 052 |

: Đề nghị đồng bộ cho các phân hệ

### 15.3. Nhật ký hấp thụ đề nghị

Bản 0.2 hấp thụ đề nghị từ sáu tập đã viết sau bản 0.1. Mỗi dòng nêu nguồn, đề nghị và cách xử lý; số mã sẵn có không đổi, chỉ thêm API-15-138…142.

| Nguồn tập | Đề nghị | Xử lý |
|---|---|---|
| Use case | FR-15-004 dẫn Phụ lục A.5 cho tham số truy vấn | Đã sửa: dẫn A.4 (FR-15-004, bước 1) |
| Use case | FR-15-038 và Q15-09 dẫn A.8 cho bộ luật PII-15 | Đã sửa: dẫn A.7; giữ A.8 ở FR-15-060 vì đó là hành động kiểm toán |
| Use case | API-15-045 gắn FR-15-019 trong khi là đăng ký nhà thầu | Đã sửa: bỏ FR-15-019, chỉ còn FR-15-020 ở §9.3 |
| Use case | Câu thông báo trong thân FR khác §9.1 | Đã sửa 95 chỗ: thông báo theo đúng §9.1; câu riêng theo ngữ cảnh chuyển thành "chi tiết riêng ở `detail`"; tách ERR-15-017 và 022 ở FR-15-059 |
| Use case | BR-15-022: ROLE-ORG_REQUESTER không thử production | Đã sửa BR-15-022 và mục 3.2: chỉ `ROLE-DEVELOPER` giữ `PERM-15-try`, đầu mối chỉ đăng ký |
| Use case | Thiếu tác nhân biên tập viên cho PERM-15-content-write | Đã thêm dòng "Biên tập viên nội dung" ở 3.1 (TA, CA, SV ○); mục 3.2 ghi D02-08 đã có đủ tám quyền |
| Thiết kế chi tiết | FR-15-037: `portal-sandbox` làm cả MOCK lẫn chuyển tiếp BACKEND | Đã sửa FR-15-036, 037, bảng 2.4, hình trình tự và hình kiến trúc; APISIX chỉ giữ tuyến tĩnh và `forward-auth`; Q15-07 ghi đã chốt |
| Thiết kế chi tiết | FR-15-039: nơi đếm hạn mức | Đã ghi: theo người ở `portal.try`, theo ứng dụng và tenant ở API-15-082 |
| Thiết kế chi tiết | FR-15-035, 043: token exchange RFC 8693 và dự phòng JWS ở OpenBao transit | Đã ghi ở bảng 2.4 (`portal-try`) và Q15-06; FR-15-035, 043 giữ nguyên luồng trao đổi token |
| Thiết kế chi tiết | §2.4 thêm module delegate, insight, admin | Đã thêm ba dòng vào bảng 2.4 kèm dải FR |
| CSDL | Phụ lục A.3 thêm enum (sync_run, lô di trú, tệp đính kèm, provisioning_state, thông báo, author_side) | Đã thêm sáu dòng vào A.3, giá trị đối chiếu `ph15_portal.sql` (CHECK) |
| CSDL | §4.2 thêm `app.linked_system_code`, `catalog_api.origin_tenant_id` | Đã thêm vào EN-15-08 và EN-15-01 |
| Màn hình | UI-15-14 không có route riêng; UI-15-27 hai route; tạo trang dùng hộp nhập mã, không dùng /moi | Bảng §10 đã đúng từ 0.1; thêm quy ước vào A.4 và sửa kích hoạt của FR-15-014 |
| Màn hình | Phụ lục B của tập màn hình: ba API B1 `GET /inbox/unread-count`, B2 `GET /apps:check-code`, B3 `GET /content/pages/{pageCode}/diff` | Chấp nhận: API-15-140, 141, 142; gắn FR-15-052, 025, 016 và UI liên quan |
| API | API-15-082 có đường dẫn gốc `/internal/v1/...`, không có tiền tố `/api/portal/v1` | Đã ghi ở đầu §9.3 |
| API | Thêm API-15-138 (`/content/attachments/{attachmentId}`) và API-15-139 (`/public/branding`) | Chấp nhận: gắn FR-15-014, 017 và FR-15-003, 056; thêm vào bảng §9.3 và tổng 142 ở Tóm tắt |
| API | Thêm FR-15-002 vào API-15-003, 004, 005, 007 | Đã sửa cột FR của §9.3 |
| API | ERR-15-123: cảnh báo hay 413 | Thống nhất: gần ngưỡng thì `warnings[]` (200), vượt cứng thì 413 kèm `bodyTruncated`; ghi ở FR-15-035 |
| API | Quyền SV (○) với API-15-069, 070, 084 | Ghi quyền theo đối tượng qua `PERM-15-content-write` (cùng tập TA, CA, SV ○); TA, CA giữ `PERM-15-portal-admin`; sửa FR-15-034, 042 và mục 3.2 |
| API | Hấp thụ trường `viewerClass`, `termsUpToDate`, `retryAfterSeconds`, `partial[]`, `appCode` (API-15-074), `TryResponse.result`, `bodyTruncated` | Đã thêm Phụ lục A.9; `appCode` còn ghi ở FR-15-039 |
| API | EVT-15-04 thêm `appCode`; EVT-15-05, 13 thêm `reason`, `change` | Đã sửa bảng §9.2 với enum cụ thể |
| Chung | Năm quyền PERM-15 chưa có ở D02-08 | Đã xử lý: D02-08 đã có; sửa §15.1 và 3.2 |
| Test case | Mã lỗi khi cổng công khai tắt, tự đăng ký tắt, thử production của `dh-dev`, danh mục quá 24 giờ, trang vượt cỡ, ngưỡng dương tính giả PII-15 (Q15-40…44 của tập TC) | Đã chốt ở FR-15-008, 014, 020, 043 và A.7, không thêm mã lỗi mới (chi tiết riêng ở `detail`); trang vượt cỡ giữ ERR-15-021 |

: Nhật ký hấp thụ đề nghị của bản 0.2

## Phụ lục A. Nguồn chuẩn enum, trạng thái, route và tham số

Phụ lục này là nguồn chuẩn: khi chương 5 đến 9 và phụ lục khác nhau thì lấy phụ lục. Giá trị enum viết hoa theo mã máy, nhãn tiếng Việt do giao diện quyết định.

### A.1. Mã định danh

Các mã do người dùng đặt phải khớp mẫu dưới đây và bất biến sau khi tạo (BR-15-007).

| Mã | Mẫu | Ví dụ |
|---|---|---|
| `appCode` | `^[a-z][a-z0-9-]{2,40}$` | `app-tra-cuu-ho-tich` |
| `pageCode` | `^[a-z0-9][a-z0-9-]{1,62}$` | `bat-dau-nhanh` |
| `teamCode` | `^[a-z][a-z0-9-]{2,40}$` | `nhom-thau-a` |
| `ticketCode` | `HT-{năm}-{số}` | `HT-2026-0042` |
| `clientId` sandbox | `sbx-{tenant}-{appCode}-{n}` | `sbx-t68-app-tra-cuu-ho-tich-1` |
| Khóa API sandbox | `dhsk_{tenant}_{base64url}` | `dhsk_t68_…` |

: Mẫu mã định danh của PH-15

### A.2. Hạng người xem và mức hiển thị

Hạng người xem quyết định danh mục thấy được; mức hiển thị và `dataClass` là thuộc tính của API do PH-02 giữ.

| Nhóm giá trị | Giá trị |
|---|---|
| Hạng người xem | `ANONYMOUS`, `TENANT_USER`, `DEV_USER`, `OTHER_TENANT_USER` |
| Mức hiển thị | `TENANT`, `NATIONAL`, `PUBLIC` |
| `dataClass` | `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` |
| Kiểu dịch vụ (`kind`) | `API`, `EVENT` |
| Trạng thái phiên bản API | `PUBLISHED`, `DEPRECATED`, `SUSPENDED`, `RETIRED` |
| Vai trò ứng dụng và nhóm | `OWNER`, `DEVELOPER`, `VIEWER` |
| `ownerType` | `USER`, `TEAM` |

: Enum về hạng người xem và thuộc tính dịch vụ

### A.3. Trạng thái và enum nghiệp vụ

Bảng gom toàn bộ trạng thái của các đối tượng PH-15; sơ đồ chuyển trạng thái ở mục 4.3 đến 4.6.

| Đối tượng | Giá trị |
|---|---|
| Ứng dụng | `ACTIVE`, `SUSPENDED`, `ARCHIVED` |
| Thông tin xác thực sandbox | `kind`: `CLIENT_CREDENTIALS`, `API_KEY`. Trạng thái: `ACTIVE`, `ROTATING`, `REVOKED`, `EXPIRED` |
| Tham chiếu production | `ACTIVE`, `EXPIRING`, `REVOKED`. Phương thức: `tls_client_auth`, `private_key_jwt`, `client_secret_basic` |
| Tài khoản dh-dev | `PENDING_EMAIL`, `PENDING_APPROVAL`, `ACTIVE`, `REJECTED`, `LOCKED`, `DISABLED`, `EXPIRED`, `ERASED`. Nguồn: `TENANT_SSO`, `DH_DEV` |
| Trang nội dung | `type`: `GUIDE`, `QUICKSTART`, `FAQ`, `ANNOUNCEMENT`, `TERMS`. `audience`: `PUBLIC`, `LOGGED_IN`, `TENANT`. `lang`: `vi`, `en`. Trạng thái trang: `DRAFT`, `PUBLISHED`, `UNPUBLISHED`, `ARCHIVED` |
| Phiên bản trang | `DRAFT`, `IN_REVIEW`, `REJECTED`, `PUBLISHED`, `SUPERSEDED`, `UNPUBLISHED` |
| Sandbox | Chế độ: `MOCK`, `BACKEND`, `OFF`. `examplePolicy`: `FIRST`, `RANDOM`. Môi trường thử: `SANDBOX`, `PRODUCTION`. Thử production: `OFF`, `PENDING`, `ENABLED`, `EXPIRED` |
| Kết quả thử | `OK`, `UPSTREAM_ERROR`, `DENIED`, `THROTTLED`, `TIMEOUT` |
| Phiếu hỗ trợ | `kind`: `QUESTION`, `DOC_ERROR`, `SUPPORT_REQUEST`, `ACCESS_REQUEST`, `FEEDBACK`. Trạng thái: `OPEN`, `ANSWERED`, `RESOLVED`, `CLOSED` |
| Đồng bộ | Trạng thái chung: `IDLE`, `RUNNING`, `FAILED`, `STALE`. Lần chạy (`sync_run`): `kind`: `INCREMENTAL`, `FULL`, `RECONCILE`, `GIT`; trạng thái: `RUNNING`, `SUCCEEDED`, `FAILED` |
| Lô di trú nội dung | `RUNNING`, `PREVIEW`, `APPLIED`, `FAILED` |
| Tệp đính kèm | `purpose`: `PAGE_IMAGE`, `LOGO`, `MIGRATION_PACKAGE`. `scan_status`: `PENDING`, `CLEAN`, `INFECTED` |
| Cấp thông tin xác thực ở Keycloak | `provisioning_state`: `PENDING`, `PROVISIONED`, `FAILED`, `DEPROVISIONING` (không hiển thị cho người dùng, chỉ để dọn client mồ côi) |
| Loại thông báo | `kind` của đăng ký theo dõi và của thông báo: `MANDATORY` (bắt buộc, không tắt được), `INFO` |
| Tin nhắn phiếu hỗ trợ | `author_side`: `REQUESTER` (người gửi), `HANDLER` (người xử lý) |
| Thông báo và lời mời | Kênh: `IN_APP`, `EMAIL`. Lời mời: `PENDING`, `ACCEPTED`, `DECLINED`, `EXPIRED` |
| Mẫu mã và xuất | Ngôn ngữ: `curl`, `java`, `python`, `javascript`, `csharp`, `go`. Xuất bộ sưu tập: `postman`, `bruno`, `http` |

: Enum trạng thái và nghiệp vụ của PH-15

### A.4. Đường dẫn giao diện và tham số truy vấn

Đường dẫn dùng chữ không dấu, gạch nối, và là nguồn chuẩn cho liên kết, dấu trang và kiểm thử giao diện.

| Nhóm | Đường dẫn |
|---|---|
| Danh mục | `/`, `/dich-vu`, `/dich-vu/{ma-api}` (tham số `phien-ban`), `/dich-vu/{ma-api}/tai-lieu`, `/dich-vu/{ma-api}/thu`, `/dich-vu/{ma-api}/thay-doi`, `/su-kien`, `/su-kien/{ma-topic}`, `/tim-kiem` |
| Nội dung | `/huong-dan`, `/huong-dan/{ma-trang}`, `/hoi-dap`, `/thong-bao` |
| Tài khoản | `/dang-nhap`, `/dang-ky`, `/tai-khoan`, `/tai-khoan/nhom`, `/tai-khoan/dieu-khoan`, `/tai-khoan/thong-bao`, `/tong-quan` |
| Ứng dụng | `/ung-dung`, `/ung-dung/moi`, `/ung-dung/{ma-ung-dung}` (tab `xac-thuc`, `bo-suu-tap`, `thong-ke`, `nhat-ky`, `thanh-vien`), `/ung-dung/{ma}/xac-thuc` |
| Điểm vào nghiệp vụ | `/dang-ky-su-dung`, `/ket-nap`, `/cong-bo`, `/cong-bo/moi` |
| Hỗ trợ | `/ho-tro`, `/ho-tro/moi`, `/ho-tro/{ma-yeu-cau}` |
| Quản trị | `/quan-tri-cong/nhan-dien`, `/noi-dung`, `/noi-dung/{ma-trang}`, `/tai-khoan-dev`, `/dich-vu/{ma-api}`, `/dong-bo`, `/nhat-ky`, `/ho-tro`, `/di-tru`, `/tham-so` |
| BFF | `/bff/dang-nhap`, `/bff/dang-xuat` |

: Đường dẫn giao diện của PH-15

Quy ước route đã chốt cùng tập màn hình: UI-15-14 không có route riêng mà là tab `bo-suu-tap` của `/ung-dung/{ma-ung-dung}`; UI-15-27 có hai route `/quan-tri-cong/dong-bo` và `/quan-tri-cong/di-tru`; tạo trang nội dung mới dùng hộp nhập mã trang ở UI-15-22 rồi mở `/quan-tri-cong/noi-dung/{ma-trang}`, không có `/quan-tri-cong/noi-dung/moi`.

Tham số truy vấn chung: `q`, `trang`, `co` (10, 20, 50, 100), `sap-xep`, `linh-vuc`, `chu-quan`, `xac-thuc`, `loai`, `trang-thai`, `da-ngung`, `tu`, `den`, `khoang`.

### A.5. Tiêu đề HTTP và phạm vi quyền

Các tiêu đề và scope riêng của PH-15; tiêu đề chuẩn khác theo D03-06-00.

| Mục | Giá trị | Ý nghĩa |
|---|---|---|
| Tiêu đề | `X-DH-Try-Id` | Mã lượt thử, cùng `traceparent` (BR-15-026) |
| Tiêu đề | `X-DH-Sandbox: mock` hoặc `backend` | Đánh dấu chế độ phục vụ |
| Tiêu đề | `X-DH-Mock-Status` | Chọn mã trạng thái mẫu ở chế độ `MOCK` |
| Tiêu đề | `X-DH-App` | Mã ứng dụng gọi |
| Tiêu đề bị chặn | `Authorization`, `Cookie`, `Host` | Do người dùng gửi (ERR-15-121) |
| Scope tiêu thụ | `catalog:portal-read` | Đọc danh mục từ PH-02 |
| Scope mới | `metrics:portal-read`, `sandbox:call` | Đọc chỉ số, gọi sandbox |

: Tiêu đề và scope của PH-15

### A.6. Giới hạn kích thước

Giới hạn cứng, tenant không nâng được; giới hạn có tham số ở mục 8.2.

| Đối tượng | Giới hạn |
|---|---|
| Trang nội dung | ≤ 200 KB Markdown |
| Ảnh đính kèm | ≤ 5 MB, PNG, JPEG, WebP, không SVG |
| Logo | ≤ 512 KB, PNG hoặc WebP, từ 128 px |
| Thân yêu cầu thử | ≤ 256 KB (`15.try.max-body-kb`) |
| Phản hồi thử | Cắt ở 1 MB |
| Bộ sưu tập thử | 50 bộ, mỗi bộ 100 yêu cầu, mỗi yêu cầu lưu ≤ 16 KB |
| Hỏi đáp, phiếu | Hỏi đáp ≤ 2.000 ký tự, phiếu ≤ 4.000 ký tự |
| Gói di trú | ≤ 50 MB |

: Giới hạn kích thước của PH-15

### A.7. Bộ luật nhận dạng dữ liệu cá nhân PII-15

Bộ luật chặn ở chế độ `BACKEND` và cảnh báo ở `MOCK` (BR-15-016). Dải giả được quy ước để nhà phát triển tạo dữ liệu thử mà không bị chặn nhầm.

| Mã | Mẫu nhận dạng | Dải giả quy ước |
|---|---|---|
| PII-15-01 | Số căn cước 12 chữ số | Bắt đầu bằng `000` |
| PII-15-02 | Số CMND 9 chữ số | Bắt đầu bằng `000` |
| PII-15-03 | Mã số thuế 10 hoặc 13 chữ số | Bắt đầu bằng `000` |
| PII-15-04 | Số điện thoại Việt Nam | `0900000xxx` |
| PII-15-05 | Thư điện tử | Miền `@example.gov.vn` |
| PII-15-06 | Số hộ chiếu | Bắt đầu bằng `X00` |

: Bộ luật nhận dạng PII-15

Ngưỡng dương tính giả chấp nhận được: tối đa 2% số yêu cầu mẫu hợp lệ của tập kiểm (mã đơn vị, mã bưu điện, mã hồ sơ dài 9 hoặc 10 chữ số) bị chặn nhầm; vượt ngưỡng thì ATTT chỉnh mẫu nhận dạng chứ không nới dải giả. Không có cơ chế miễn trừ theo dịch vụ ở Đợt 2: nhà phát triển dùng dải giả quy ước ở bảng trên. Đây là giả định thiết kế, ATTT xác nhận ở Q15-09.

### A.8. Hành động kiểm toán của cổng

Các hành động dưới đây ghi vào nhật ký kiểm toán ở PH-13 với loại `PORTAL_*` và là giá trị lọc `hanh-dong` của FR-15-060.

| Hành động | Ý nghĩa |
|---|---|
| `VIEW_SENSITIVE_DOCS` | Xem tài liệu dịch vụ có dữ liệu nhạy cảm |
| `DOWNLOAD_SPEC` | Tải đặc tả |
| `TRY_API` | Thử API ở sandbox |
| `TRY_PRODUCTION` | Thử API ở môi trường thật |
| `SECRET_ISSUED` | Cấp bí mật sandbox |
| `SUBMIT_SUBSCRIPTION`, `SUBMIT_ONBOARDING`, `SUBMIT_PUBLICATION` | Gửi đăng ký sử dụng, kết nạp, công bố |
| `LOCK_ACCOUNT`, `UNLOCK_ACCOUNT` | Khóa, mở khóa tài khoản hoặc ứng dụng |
| `CHANGE_SETTING` | Đổi tham số hoặc nhận diện |
| `VIEW_AUDIT`, `EXPORT_AUDIT` | Xem, xuất nhật ký |

: Hành động kiểm toán của PH-15

### A.9. Trường chỉ có ở phản hồi API

Các trường dưới đây do tập API (D03-04-PH15) khai báo và được bản 0.2 ghi nhận để phụ lục này vẫn là nguồn chuẩn; tên viết đúng như ở hợp đồng.

| Trường | Thuộc | Ý nghĩa |
|---|---|---|
| `viewerClass` | Hồ sơ cá nhân (API-15-041) | Một trong bốn hạng người xem ở A.2, suy từ phiên BFF, không nhận từ tham số |
| `termsUpToDate` | Hồ sơ cá nhân | `true` khi người dùng đã chấp nhận phiên bản điều khoản hiện hành (FR-15-023) |
| `retryAfterSeconds` | Phản hồi lỗi RFC 9457 | Số giây nên chờ với ERR-15-007, ERR-15-037, ERR-15-103, ERR-15-104, ERR-15-118; trùng tiêu đề `Retry-After` |
| `partial[]` | Bảng điều khiển (API-15-097) | Danh sách thẻ lỗi một phần; trang vẫn hiện các thẻ còn lại (FR-15-048) |
| `appCode` | Tham số truy vấn tùy chọn của API-15-074 | Chọn ứng dụng cần xem hạn mức (FR-15-039) |
| `result` | `TryResponse` (API-15-072, 073) | Kết quả lượt thử, một trong `OK`, `UPSTREAM_ERROR`, `DENIED`, `THROTTLED`, `TIMEOUT` (A.3) |
| `bodyTruncated` | `TryResponse` | `true` khi thân phản hồi bị cắt ở 1 MB; xem ERR-15-123 (FR-15-035) |

: Trường chỉ có ở phản hồi API

## Lịch sử phiên bản

Mục này ghi các lần sửa tài liệu để hội đồng thẩm định theo dõi.

| Phiên bản | Ngày | Người thực hiện | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm yêu cầu PH-15 | Bản đầu: 62 FR, 34 BR, 22 NFR, 63 ERR, 14 EVT, 137 API, 28 UI, 19 câu hỏi mở |
| 0.2 | 26/11/2026 | Nhóm yêu cầu PH-15 | Hấp thụ đề nghị đồng bộ từ tập use case, thiết kế chi tiết, CSDL, màn hình và API (chi tiết ở mục 15.3): thêm API-15-138…142 (142 API); sửa tham chiếu phụ lục, câu thông báo theo §9.1, enum và thực thể theo CSDL, kiến trúc theo SDD; thêm Phụ lục A.9; năm quyền PERM-15 đã có ở D02-08 |
| 0.3 | 26/11/2026 | Nhóm yêu cầu PH-15 | Rà chéo bộ PH-15: chốt mã lỗi cho Q15-40…44 của tập test case (FR-15-008, 020, 043, Phụ lục A.7), không đổi số mã |

: Lịch sử phiên bản D02-03-PH15
