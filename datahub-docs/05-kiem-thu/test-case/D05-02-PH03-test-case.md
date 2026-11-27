---
ma_tai_lieu: D05-02-PH03
ten: Kịch bản và test case phân hệ PH-03 Cổng API
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư gateway và dh-connect, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-03
mo_ta: Kịch bản và ca kiểm thử của phân hệ Cổng API gồm lớp biên, xác thực, hạn mức, định tuyến, đồng bộ cấu hình và nhật ký lượt gọi, chạy được ngay trên SIT, kèm UAT tương đương hệ cũ và ma trận truy vết.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH03 FRS; D02-04-PH03 Use case; D03-04-PH03 API; D03-06-PH03 Màn hình
---

# D05-02-PH03 · Kịch bản và test case Cổng API

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-03 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH03: lớp biên, xác thực, hạn mức, định tuyến, đồng bộ cấu hình, nhật ký lượt gọi.
- Không mất chức năng của API Management cũ (Gravitee) mà PH-03 là phân hệ đích: plan Secure, rate limit, quota, whitelist/blacklist đường dẫn, plan Policies, Start/Stop API, nhật ký lượt gọi, danh sách gateway (LGC-APIM-005; 011…015, 022, 023; LGC-BUS-041; LGC-NFR-006), kèm phần nâng cấp OAuth 2.1 và mTLS.
- Không có đường nào để lượt gọi đi vòng qua gateway, giả mạo tenant bằng tiêu đề, hay làm tenant này thấy hoặc làm chậm tenant khác.
- Gateway tiếp tục phục vụ khi control plane hoặc nguồn ngoài ngừng, và thay đổi cấu hình không làm lỗi một lượt gọi nào.

**Phạm vi.** Gồm <!--gen:so-ts-->32<!--/gen--> kịch bản (TS-03-01…32) với <!--gen:so-tc-->136 (TC-03-001…136; 85 ca P1)<!--/gen--> test case và 11 kịch bản nghiệm thu người dùng (UAT-01…11). Mỗi FR mức M có ít nhất một ca dương và một ca âm; mọi API đọc có ca rò rỉ chéo tenant; mọi mã lỗi ERR-03-001…027 và ERR-03-101…130 có ít nhất một ca. Ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph03/tools/gen_matrix.py`.

**Căn cứ.** Tài liệu cùng bộ PH-03 (FRS D02-03-PH03, use case D02-04-PH03, SDD D03-02-PH03, CSDL D03-03-PH03, API D03-04-PH03, màn hình D03-06-PH03); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; Công văn 631/THH-THHT (CMP-LAW-09: quản lý API, OAuth, giới hạn tần suất, chống từ chối dịch vụ); NĐ 331/2026/NĐ-CP, TCVN 14423:2026 cấp độ 3 (CMP-LAW-06, CMP-LAW-08).

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- tenant lấy từ token đã xác minh, tiêu đề `X-DH-*` do khách gửi bị xóa, lượt gọi chéo tenant bị từ chối (TS-03-06, 27);
- không có đường tắt tới backend và biên chỉ nhận TLS 1.3 trừ ngoại lệ có hạn (TS-03-01, 12);
- bốn mắt cho bốn thay đổi rủi ro cao: ngoại lệ hoặc luật vá WAF, đổi chế độ WAF, mở route ra Internet, hạ hạn mức toàn tenant (TS-03-04, 03, 15, 10, 24, 28);
- không lộ thân bản tin, giá trị tiêu đề xác thực hay tham số truy vấn vào nhật ký, kiểm bằng giá trị mồi `DH-CANARY` (TS-03-20, 26);
- thu hồi token và tạm ngừng khẩn cấp có hiệu lực không quá 60 giây (TS-03-08);
- nạp cấu hình nóng không làm lỗi lượt gọi và gateway chạy tiếp ≥ 24 giờ khi control plane ngừng (TS-03-17, 30).

Mã W1 hiện có của PH-03 chưa có control plane; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô và ngưỡng chưa có số thật dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT) và giả định đã ghi trong D02-03-PH03 mục 8.1.

## 0. Giới thiệu

Chương này nói tài liệu dùng để làm gì, ai đọc, các thuật ngữ cần biết và nó nối với tài liệu nào.

### 0.1. Mục đích và phạm vi

Tài liệu là tập 7 của bộ PH-03. Mục đích là cho kiểm thử viên và kỹ sư một bộ kịch bản và ca kiểm thử đủ để nghiệm thu phân hệ Cổng API: mọi FR mức M có ca dương và ca âm, mọi API quản trị có ca, và các ràng buộc an ninh có ca riêng. Phạm vi là hai đơn vị triển khai `apisix` và `dh-connect` như chương 1 mô tả; chức năng của PH-02 và PH-12 chỉ được dùng làm đầu vào.

### 0.2. Người đọc

Người đọc chính là kiểm thử viên (viết, chạy ca), kỹ sư gateway và `dh-connect` (viết ca tự động), cán bộ ATTT (ca TS-03-03, 04, 06, 26…28, 31) và chủ đầu tư (UAT mục 7). Ca được viết để chạy được ngay trên môi trường SIT với bộ dữ liệu mục 2, không cần hỏi lại.

### 0.3. Thuật ngữ và chữ viết tắt

Mỗi ca ở chương 4 và 5 được đặc tả bằng một bảng hai cột: Loại, Ưu tiên, Tự động, Truy vết, Tiền điều kiện và dữ liệu, Các bước, Kết quả mong đợi. Ca hiệu năng ở TS-03-29 viết thành bảng tải và ngưỡng. Thuật ngữ dùng chung với [D02-03-PH03](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) và D00-01: **consumer** là hình chiếu của một client HTTT trên gateway; **ảnh chụp** là gói cấu hình gateway có số phiên bản và chữ ký; **WAF** là tường lửa ứng dụng web Coraza với bộ luật OWASP CRS; **bốn mắt** là thay đổi cần người thứ hai duyệt.

### 0.4. Tài liệu tham chiếu

D05-01 (kế hoạch kiểm thử tổng thể, cổng RG-1…5), D02-03-PH03 (FR, BR, NFR), D02-04-PH03 (UC), D03-04-PH03 (API, ERR, EVT), D03-06-PH03 (màn hình), D03-07 (SEC), bảng tính [D05-02-PH03-test-case.xlsx](ph03/D05-02-PH03-test-case.xlsx) sinh từ tài liệu này.

### 0.5. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| 1 | Phạm vi, chiến lược, mức kiểm thử, môi trường, tiêu chí vào và ra, quy ước mã |
| 2 | Dữ liệu kiểm thử: tenant, người dùng, route, hệ thống giả lập |
| 3 | Danh sách 32 kịch bản và máy trạng thái được kiểm thử |
| 4 | Kịch bản và test case chức năng |
| 5 | Kịch bản kiểm thử phi chức năng và xuyên suốt (hiệu năng, chịu lỗi, độ bền) |
| 6 | Thủ tục kiểm thử thủ công |
| 7 | Nghiệm thu người dùng tương đương hệ cũ (UAT-01…11) |
| 8 | Ma trận truy vết FR, LGC, BR, ERR, NFR, UC, UI, API, EVT sang ca |
| 9 | Tổ chức mã kiểm thử, mẫu ca, công cụ sinh ma trận và bảng tính |

: Cấu trúc tài liệu D05-02-PH03

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

Phạm vi kiểm thử là toàn bộ hành vi của PH-03 trên hai đơn vị triển khai `apisix` (mặt phẳng dữ liệu) và `dh-connect` (mặt phẳng điều khiển). Chiến lược dựa trên ba nhận định: phần lớn rủi ro nằm ở chuỗi plugin tại gateway nên ưu tiên ca API đi qua gateway thật; phần cấu hình và đồng bộ cần ca tích hợp với Git, bucket, OpenBao; chất lượng phi chức năng (độ trễ, chịu lỗi, cách ly) cần ca k6 và Chaos riêng.

### 1.1. Đối tượng kiểm thử

| Đối tượng | Thành phần | Ghi chú |
|---|---|---|
| Data plane | Apache APISIX 3.x chế độ khai báo (không etcd), WAF Coraza, plugin `dh-auth`, `dh-limit`, `dh-revocation`, `dh-path-acl`, `dh-ip-block`, `dh-kill-switch`, `dh-edge`, `dh-waf-guard`, `dh-adaptive-throttle`, `dh-problem` | Hai cửa vào `apisix-ext` (Internet) và `apisix-int` (mạng nội bộ), mỗi cửa ≥ 3 bản sao |
| Control plane | Mô-đun `gateway` trong `dh-connect` (Spring Boot 4, Spring Modulith) | API `/api/gateway/v1`, outbox, bộ tổng hợp, ký, phát |
| Kho cấu hình | Git, bucket Garage, Argo CD, bộ đồng bộ ở nút | Ảnh chụp có phiên bản và chữ ký |
| Phụ thuộc | Keycloak (JWKS), OPA, Valkey (bộ đếm), OpenBao (khóa ký, PKI), Kafka, PH-13 (nhật ký, chỉ số) | Chaos Mesh làm mất từng phần |
| CSDL | Schema `ph03_gateway` trên `pg-core` | RLS theo `tenant_id` |
| Giao diện | UI-03-01…18 | React + antd v6 |

: Đối tượng kiểm thử

### 1.2. Mức kiểm thử

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest, busted (Lua) | Quy tắc miền, bộ tổng hợp, kiểm tra tĩnh cấu hình, từng plugin Lua |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, OpenBao, Kafka, WireMock) | Control plane với CSDL, OpenBao, Git giả, outbox |
| CSDL | DB | `psql` với bài cô lập RLS của `ph03_gateway` | RLS, ràng buộc, append-only |
| Gateway | GW | APISIX trong Docker với bộ plugin thật, `test-nginx` | Chuỗi plugin, mã lỗi `ERR-03-1xx` |
| Hợp đồng | CT | `check_contracts.py`, Spectral, `@asyncapi/parser` | OpenAPI, AsyncAPI |
| API | API | REST Assured, `curl` với `--http1.1`, `--http2`, `openssl s_client` | Mọi API-03 |
| Đầu cuối | E2E | Playwright | UI-03-* |
| Hiệu năng | k6 | k6, `wrk2` | NFR-03-001…004, 008, 013, 017, 018, 021…023 |
| Chịu lỗi | Chaos | Chaos Mesh | Valkey, Keycloak, OPA, Git, bucket, control plane, vùng sẵn sàng |
| Bảo mật | ZAP | OWASP ZAP, testssl.sh, Trivy, Semgrep, bộ payload OWASP | ASVS 5.0 mức 2, TLS, WAF |

: Mức kiểm thử

### 1.3. Môi trường kiểm thử

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm, hai vùng sẵn sàng giả lập; tenant T68, T01, T91; APISIX ba bản sao mỗi cửa; Keycloak, OPA, Valkey, OpenBao, Kafka, Argo CD thật; backend giả lập `SIM-BE` (mục 2.4) | API, GW, E2E, Chaos |
| PERF | Cấu hình QM-VUA theo D03-09, dữ liệu GĐ-01…07, 1.000 route mỗi tenant, 200 consumer | k6 |
| UAT | Như SIT; cấu hình sao từ gói Gravitee cũ đã làm sạch khóa API | UAT mục 7 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào và ra

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH03 ở trạng thái duyệt; DDL `ph03_gateway` áp được; hợp đồng qua CT; bộ dữ liệu mục 2 nạp xong; ba bản sao APISIX mỗi cửa ở trạng thái sẵn sàng |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-03-06, 08, 26, 27, 28 đạt 100 % |

: Tiêu chí vào và ra

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-03-nn`, test case `TC-03-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case là một khối thống nhất với D05-02-PH05:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Chịu lỗi, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, GW, CT, API, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC.
- **Tiền điều kiện, dữ liệu**: mã dữ liệu ở mục 2.
- **Các bước**: đánh số. Đường dẫn API quản trị tương đối với `/api/gateway/v1`; lượt gọi qua gateway viết `GW <người gọi> <phương thức> <URL>`.
- **Kết quả mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-03-022 (thiếu `PERM-03-*` hoặc scope dịch vụ), thân RFC 9457 |
| 404-ẩn | `404` với ERR-03-001, thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` (BR-03-028) |
| Lỗi GW `nnn` | Phản hồi của gateway: mã HTTP đúng bảng ERR-03-1nn, thân RFC 9457 có `code = ERR-03-nnn`, tiêu đề `X-Trace-Id`, không có vết ngăn xếp, tên máy hay đường dẫn nội bộ (BR-03-023) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{tên}` | Đúng một bản tin trên topic `t68.gateway.{tên}.v1` (CloudEvents, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong outbox `ph03_gateway.outbox` và không có bản tin liên quan |
| Mồi sạch | Tìm chuỗi `DH-CANARY-{ca}` trong nhật ký APISIX, nhật ký ứng dụng 5 phút, vết OTel, bảng `ph03_gateway.*`, ClickHouse, Kafka, tệp xuất: không thấy |
| Hiệu lực ≤ N s | Gọi lặp mỗi 1 giây cho tới khi đổi kết quả; thời gian đo từ khi API quản trị trả thành công |

: Quy ước mã và cách trình bày

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-03`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: lượt gọi tới backend không qua chuỗi xác thực; tenant của lượt gọi suy ra từ tiêu đề hay tham số do khách gửi; đọc được đối tượng, nhật ký, báo cáo của tenant khác; người tự duyệt được thay đổi của chính mình; thân bản tin, giá trị tiêu đề xác thực hoặc tham số truy vấn xuất hiện trong nhật ký; thu hồi hoặc tạm ngừng có hiệu lực chậm hơn 60 giây; nạp cấu hình làm lỗi một lượt gọi; chấp nhận ảnh chụp có phiên bản không lớn hơn bản đang chạy hoặc sai chữ ký. Báo cáo hằng đêm từ JUnit, Playwright, k6, busted, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng `ph03/seed/` qua API quản trị và Keycloak admin (không chèn SQL trực tiếp), trừ dữ liệu bộ đếm Valkey và nhật ký ClickHouse sinh bằng bộ tạo tải.

### 2.1. Tenant

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập) | Host cửa Internet `ext.t68.sim.test`, cửa nội bộ `int.t68.sim.test`; hạn mức toàn tenant 500 lượt/giây (mặc định, FR-03-023); WAF `DETECT` khi khởi tạo, đổi sang `BLOCK` ở các ca cần |
| `T01` | Tỉnh đối chứng rò rỉ | Có route **trùng mã** `r-ho-tich` và HTTT trùng mã `HT-NDXP` với T68 nhưng khác backend, để phát hiện trả nhầm |
| `T91` | Tỉnh bị sáp nhập vào T68 | Trạng thái `MERGED`, còn host `ext.t91.sim.test` để thử chuyển tiếp (FR-03-037) |
| `COMMON` | Không gian dùng chung toàn quốc | Host riêng `common.sim.test`, không gắn tenant |

: Tenant

### 2.2. Người dùng và bên gọi

Tên nhân vật dùng riêng cho kiểm thử, không trùng người thật. Mọi người dùng vai trò TA, SO, PA có TOTP thử để kiểm thử xác thực lại.

| Mã | Tenant | Vai trò | Mục đích |
|---|---|---|---|
| U-PA | PLATFORM | PA | Mẫu chính sách, chứng thư biên, quay lui, trần nền tảng |
| U-PO | PLATFORM | PO | Chỉ đọc nút, trạng thái |
| U-T68-TA | T68 | TA | Hạn mức, phát cấu hình, duyệt thay đổi |
| U-T68-TA2 | T68 | TA | Người duyệt thứ hai, xung đột đồng thời |
| U-T68-TO | T68 | TO | Dừng, mở API, xác nhận cảnh báo, đề nghị ngoại lệ WAF |
| U-T68-SO1 | T68 | SO | Duyệt ngoại lệ WAF, đổi chế độ WAF, chặn địa chỉ |
| U-T68-SO2 | T68 | SO | Người duyệt thứ hai của SO1 |
| U-T68-SO-VD | T68 | SO + TA (cố ý cấu hình sai, chỉ có ở SIT) | Vi phạm tách nhiệm có chủ đích, để kiểm lớp bốn mắt độc lập với lớp tách vai trò; không tạo ở UAT, PROD |
| U-T68-AU | T68 | AU | Kiểm toán, chỉ đọc nhật ký |
| U-T68-VW | T68 | Chỉ có `PERM-03-read` | Ca thiếu quyền |
| U-T01-TA, U-T01-AU | T01 | TA, AU | Đối chứng rò rỉ chéo tenant |
| S-SYNC | — | Dịch vụ PH-01, scope `gateway:sync` | Đồng bộ consumer |
| S-REVOKE | — | Dịch vụ PH-12, scope `gateway:revoke` | Thu hồi token |
| C-HTTT1 | T68 | Client `ht-ndxp` (HTTT `HT-NDXP`), gói `GOI-STD`, mức Thường, 20 lượt/giây, quota 100.000/ngày | Bên gọi chính |
| C-HTTT2 | T68 | Client `ht-sensitive` (HTTT mức Nhạy cảm), token ràng buộc chứng thư (`cnf`) | Ca mTLS |
| C-ESS | T68 | Client `ht-thiet-yeu`, nhóm `ESSENTIAL` | Ca ưu tiên (BR-03-009) |
| C-KEY | T68 | Client `ht-apikey`, gói dùng khóa API | Ca phương thức xác thực |
| C-OPEN | T68 | Không có (Keyless), API dữ liệu mở | Ca Keyless |
| C-T01 | T01 | Client `ht-ndxp` của T01 | Ca token chéo tenant |

: Người dùng và bên gọi

### 2.3. Route, upstream, chính sách mẫu

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `r-ho-tich` | Route `ACTIVE` cửa `INT`, GET và POST `/ho-tich/**`, gói `GOI-STD`, scope `ho-tich.read`, có lược đồ OpenAPI và chính sách OPA `allow-ho-tich` | Route chuẩn của hầu hết ca |
| `r-open-data` | Route dữ liệu mở, Keyless, `INT` | Ca FR-03-015 |
| `r-sensitive` | Route yêu cầu mTLS và `cnf`, mức Nhạy cảm | Ca FR-03-002, 014 |
| `r-ws` | Route WebSocket `/ws/thong-bao` | FR-03-033 |
| `r-grpc` | Route chuyển đổi gRPC–REST | FR-03-034, hồ sơ Đợt 3, ca Biên |
| `r-ext-ok` | Route đủ điều kiện mở `EXT` (WAF `BLOCK`, bắt buộc xác thực, có lược đồ) | FR-03-038 |
| `r-no-schema` | Route thiếu lược đồ OpenAPI đã duyệt | Ca ERR-03-012 |
| `r-v1`, `r-v2` | Hai phiên bản API song song; `r-v1` ở `SUNSET` | FR-03-035 |
| `up-ho-tich` | Upstream 3 backend `SIM-BE-1…3`, kiểm tra sức khỏe chủ động `/healthz` mỗi 5 giây | FR-03-029…031 |
| `tpl-cors`, `tpl-lua-custom` | Mẫu chính sách trong danh mục; mẫu ngoài danh mục (có plugin Lua tự viết) | FR-03-048, ERR-03-013 |

: Route, upstream, chính sách mẫu

### 2.4. Hệ thống giả lập

| Mã | Mô tả | Dùng cho |
|---|---|---|
| `SIM-BE-1…3` | Backend HTTP, điều khiển được độ trễ, mã lỗi, tỉ lệ lỗi, trả `/healthz` | Cân bằng tải, ngắt mạch, thời hạn chờ |
| `SIM-BE-SLOW` | Chờ 40 giây rồi trả `200` | ERR-03-121 |
| `SIM-BE-BAD` | Trả thân hỏng, tiêu đề sai | ERR-03-122 |
| `SIM-KC` | Keycloak giả có thể ngắt, đổi `kid`, hết hạn JWKS | FR-03-012, ERR-03-124 |
| `SIM-OPA` | OPA điều khiển được quyết định và độ trễ | FR-03-019 |
| `SIM-GIT`, `SIM-BUCKET` | Git và bucket giả có thể từ chối ghi | FR-03-042, ERR-03-014 |
| `SIM-ATTACK` | Bộ phát payload OWASP (SQLi, XSS, path traversal, SSRF, log4shell) và bộ phát tải theo địa chỉ nguồn | WAF, chống tràn |
| `SIM-PH13` | PH-13 giả, có thể trả `503` | ERR-03-026 |

: Hệ thống giả lập

### 2.5. Tệp mẫu và bộ mồi

| Mã | Mô tả |
|---|---|
| `F-OAS-OK`, `F-OAS-BAD` | Lược đồ OpenAPI hợp lệ và hỏng |
| `F-LEGACY-OK`, `F-LEGACY-BAD` | Gói cấu hình xuất từ Gravitee cũ (đã làm sạch khóa API) và gói thiếu trường |
| `F-CERT-OK`, `F-CERT-EXP`, `F-CERT-WRONG-HOST` | Chứng thư biên hợp lệ, hết hạn, sai tên host |
| `F-JSON-DEEP` | JSON sâu 100 mức; `F-JSON-BIG` thân 11 MiB; `F-XML-DOCTYPE` XML có DOCTYPE |
| `CANARY` | Chuỗi `DH-CANARY-{ca}` đặt ở thân, tiêu đề `Authorization`, tham số truy vấn, giá trị `Cookie` |

: Tệp mẫu và bộ mồi

### 2.6. Nguyên tắc dữ liệu

Mỗi ca tạo đối tượng với tiền tố `tc-` và mã duy nhất theo mã ca; sau ca dọn bằng API gỡ (xóa mềm, mã không dùng lại theo BR-03-029) nên ca lặp dùng hậu tố ngày giờ. Ca đo hiệu lực (≤ 60 giây) chạy một mình trên cụm, không song song với ca tải. Thời gian trong ca dùng đồng hồ giả lập của `SIM-KC` cho hạn token và `faketime` cho hạn ngoại lệ, chứng thư.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-03-01 | TLS 1.3, mTLS và chứng thư biên | Xác nhận hai cửa vào chỉ nhận TLS 1.3 (TLS 1.2 chỉ ở host có ngoại lệ có hạn), xác minh chứng thư khách mTLS và quản lý vòng đời chứng thư biên không cắt kết nối | UC-03-02, 17 | 10 |
| TS-03-02 | Chống tràn theo địa chỉ nguồn và chặn tạm | Xác nhận giới hạn kết nối và tốc độ theo địa chỉ nguồn là lớp ngoài cùng (không thay hạn mức theo HTTT), tự chặn khi vi phạm liên tục, chặn thủ công có bảo vệ danh sách tin cậy | UC-03-12, 05 | 4 |
| TS-03-03 | WAF: chặn tấn công, chế độ phát hiện và chặn | Xác nhận WAF Coraza chặn payload OWASP ở chế độ `BLOCK`, chỉ ghi ở `DETECT`, đổi chế độ cần bốn mắt và điều kiện 14 ngày phát hiện, tự hạ về `DETECT` khi quá tải | UC-03-13, 05 | 5 |
| TS-03-04 | Ngoại lệ luật WAF và luật vá ảo khẩn cấp | Xác nhận ngoại lệ luật WAF luôn có lý do, hạn tối đa 90 ngày, một route một mã luật, người duyệt là SO khác người đề nghị; luật vá ảo khẩn cấp có bốn mắt và gỡ được | UC-03-14, 15 | 4 |
| TS-03-05 | Kiểm tra lược đồ, CORS, tiêu đề bảo mật | Xác nhận gateway chặn yêu cầu sai lược đồ hoặc quá cỡ trước backend, CORS không dùng ký tự đại diện, và phản hồi không lộ thông tin máy chủ | UC-03-05 | 3 |
| TS-03-06 | Xác thực JWT, xác định tenant, phương thức bảo mật theo gói | Xác nhận token được xác minh cục bộ bằng JWKS đã đệm, tenant chỉ lấy từ token, tiêu đề `X-DH-*` của khách bị xóa, token ràng buộc chứng thư và phương thức xác thực đúng với gói của API | UC-03-01, 03 | 5 |
| TS-03-07 | Đăng ký sử dụng, phạm vi quyền, đường dẫn và ủy quyền OPA | Xác nhận gateway chỉ kiểm soát truy cập thô (đăng ký, phạm vi, đường dẫn) rồi hỏi OPA; quyết định từ chối có lý do và gateway đóng khi OPA không phản hồi | UC-03-01 | 5 |
| TS-03-08 | Thu hồi token nhanh và tạm ngừng khẩn cấp | Xác nhận thu hồi token và tạm ngừng consumer hoặc route có hiệu lực không quá 60 giây (mục tiêu 30 giây), không chờ token hết hạn, và thao tác lặp, sai trạng thái, thiếu quyền bị từ chối đúng mã | UC-03-10, 11 | 5 |
| TS-03-09 | Hạn mức tần suất và hạn ngạch theo bên gọi | Xác nhận hạn mức tính theo HTTT chứ không theo IP, hạn ngạch theo chu kỳ có cảnh báo ngưỡng, nhóm `ESSENTIAL` được ưu tiên, phản hồi `429` đủ tiêu đề và gateway điều tiết khi backend yếu | UC-03-04 | 5 |
| TS-03-10 | Hạn mức toàn tenant và ghi đè theo route | Xác nhận hạn mức toàn tenant 500 lượt/giây cách ly tenant, hạ hạn mức cần bốn mắt, ghi đè theo route có thứ tự ưu tiên rõ và chặn giá trị vượt trần hợp đồng | UC-03-25 | 3 |
| TS-03-11 | Suy giảm có kiểm soát khi Valkey mất | Xác nhận khi bộ đếm Valkey không khả dụng gateway không sập: hạn ngạch mở có cảnh báo, tần suất và hạn mức tenant đếm cục bộ, danh sách chặn token dùng bộ đệm gần nhất | UC-03-08 | 2 |
| TS-03-12 | Định tuyến, phiên bản API song song, dừng và mở API | Xác nhận mỗi lượt gọi đi đúng route theo host, đường dẫn, phương thức; route của tenant này không khớp lượt gọi của tenant khác; dừng và mở API tức thời; phiên bản cũ phục vụ song song với tiêu đề ngừng dùng rồi trả `410` | UC-03-09, 01 | 5 |
| TS-03-13 | Cân bằng tải, kiểm tra sức khỏe, ngắt mạch, thời hạn chờ | Xác nhận gateway chia tải, loại backend hỏng nhanh, trả lỗi nhanh khi mọi backend không khỏe (không dồn tải), và trả `504`, `502` đúng ngữ cảnh | UC-03-06 | 4 |
| TS-03-14 | Truy vết, WebSocket và chuyển đổi gRPC | Xác nhận mọi lượt gọi có định danh truy vết truyền xuống backend, WebSocket đi qua với giới hạn kết nối, và chuyển đổi giao thức chưa hỗ trợ trả đúng mã | UC-03-07, 01 | 3 |
| TS-03-15 | Cửa vào Internet, nội bộ và chuyển tiếp tenant sáp nhập | Xác nhận route mặc định chỉ ở cửa nội bộ, mở ra Internet cần SO duyệt và đủ điều kiện, và lượt gọi vào host của tenant đã sáp nhập được chuyển tiếp có thời hạn | UC-03-16, 30 | 4 |
| TS-03-16 | Tổng hợp, kiểm tra hợp lệ và ký ảnh chụp cấu hình | Xác nhận control plane tổng hợp cấu hình từ danh mục, kiểm tra tĩnh chặn cấu hình nguy hiểm trước khi phát, và ký ảnh chụp có số phiên bản tăng đơn điệu | UC-03-19 | 4 |
| TS-03-17 | Phát ảnh chụp, nạp nóng ở nút và quay lui | Xác nhận phát ảnh chụp tới Git và bucket, nút nạp nóng không làm lỗi lượt gọi, nút từ chối ảnh chụp sai, gateway tiếp tục phục vụ khi control plane ngừng và quay lui bằng ảnh chụp mới | UC-03-20, 21 | 6 |
| TS-03-18 | Nút gateway và đồng bộ consumer | Xác nhận quản trị thấy đúng trạng thái đồng bộ từng nút (thay "Danh sách gateway" của hệ cũ) và consumer đồng bộ từ PH-01 có hiệu lực ≤ 60 giây, kể cả khi tạm ngừng HTTT | UC-03-22, 23 | 4 |
| TS-03-19 | Mẫu chính sách được duyệt sẵn và chạy thử chính sách | Xác nhận chỉ chạy plugin và mẫu chính sách trong danh mục được duyệt, bật tắt theo tenant có kiểm tra đang dùng, và chạy thử chính sách bằng mô phỏng không đụng bộ đếm thật | UC-03-24 | 2 |
| TS-03-20 | Nhật ký lượt gọi: ghi có che dữ liệu, tra cứu, xuất | Xác nhận gateway chỉ ghi siêu dữ liệu lượt gọi (không thân bản tin, không giá trị tiêu đề xác thực, không giá trị tham số truy vấn), tra cứu có giới hạn khoảng thời gian và cách ly tenant, xuất bất đồng bộ | UC-03-26, 01, 03 | 4 |
| TS-03-21 | Chỉ số, vết, kiểm tra tổng hợp, cảnh báo an ninh và bảng điều khiển | Xác nhận gateway phát chỉ số và vết OpenTelemetry đủ dùng, bảng điều khiển phản ánh đúng trong 15 giây, kiểm tra tổng hợp không làm sai số liệu thật và sự kiện an ninh sinh cảnh báo | UC-03-18, 27, 28, 08 | 4 |
| TS-03-22 | Tham số gateway theo tenant và báo cáo sử dụng | Xác nhận quản trị tenant chỉnh được tham số vận hành trong trần nền tảng (tham số rủi ro cao đi theo bốn mắt), và báo cáo sử dụng đúng, không dùng để tính tiền | UC-03-29, 27 | 3 |
| TS-03-23 | Nhập cấu hình từ gateway cũ | Xác nhận cán bộ chuyển được cấu hình API Management cũ (plan Secure, rate limit, quota, whitelist/blacklist đường dẫn, plan Policies, Application) sang cấu hình nháp của PH-03 mà không mất mục nào và không mang theo bí mật | UC-03-31 | 2 |
| TS-03-24 | Duyệt thay đổi gateway bốn mắt (xuyên suốt) | Xác nhận cả bốn thay đổi rủi ro cao ở PH-03 đều đi qua hàng đợi duyệt, người đề nghị không tự duyệt được, và quyết định đã chốt không đổi lại | UC-03-13, 16, 25 | 2 |
| TS-03-25 | Giao diện quản trị cổng API (E2E) | Xác nhận 18 màn UI-03-01…18 hoạt động đúng chức năng, quyền, trạng thái chuẩn (đang tải, rỗng, lỗi) và quy ước đường dẫn, truy vấn của giao diện | UC-03-27 | 6 |
| TS-03-26 | Không lộ dữ liệu, thông tin máy chủ và không có đường tắt tới backend | Chứng minh BR-03-001, 007, 013, 023: mọi lượt gọi đều qua gateway, mọi lỗi do gateway sinh theo RFC 9457 không lộ nội bộ, và không nơi nào ngoài siêu dữ liệu chứa nội dung lượt gọi | UC-03-01, 03 | 3 |
| TS-03-27 | Cách ly tenant ở API, CSDL, bộ đếm và cấu hình | Chứng minh mọi API đọc trả 404-ẩn cho đối tượng của tenant khác, RLS chặn ở tầng CSDL, bộ đếm hạn mức và khóa bộ đệm tách theo tenant, và ảnh chụp cấu hình của tenant không chứa đối tượng tenant khác | — | 4 |
| TS-03-28 | Phân quyền, tách nhiệm và kiểm toán | Chứng minh ma trận `PERM-03-*` ở D02-08 được thực thi đúng ở từng API, dịch vụ gọi dịch vụ dùng scope riêng, bốn mắt độc lập với vai trò và mọi thao tác ghi có kiểm toán đủ trường | — | 4 |
| TS-03-29 | Hiệu năng, tải và quy mô | Chứng minh NFR-03-001…004, 008, 013, 017, 018, 019, 021…023 ở cấu hình QM-VUA với dữ liệu giả định GĐ-01…07 (3 bản sao mỗi cửa, 1.000 route mỗi tenant, 200 consumer) | — | 12 |
| TS-03-30 | Chịu lỗi và phục hồi | Chứng minh gateway là điểm vào duy nhất vẫn chịu được mất một vùng, nâng cấp cuốn chiếu, tắt an toàn và đạt sẵn sàng ≥ 99,95 % theo kiểm tra tổng hợp | UC-03-08, 20 | 3 |
| TS-03-31 | Tăng cứng, TLS, WAF và quét bảo mật | Chứng minh thành phần gateway được tăng cứng và WAF chặn bộ payload OWASP ở mức hoang tưởng cấu hình, API quản trị đạt ASVS 5.0 mức 2 | — | 3 |
| TS-03-32 | Truy cập giao diện, IPv6 và lưu giữ | Chứng minh giao diện UI-03-* đạt WCAG 2.2 AA, hai cửa vào chạy ngăn xếp kép IPv4 và IPv6 theo Công văn 631, và dữ liệu lưu giữ đúng thời hạn | — | 3 |
| **Tổng** | | | | **136** (85 ca P1) |

: Danh sách kịch bản
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

| Đối tượng | Trạng thái | Ca kiểm thử chính |
|---|---|---|
| Route | `PENDING` → `ACTIVE` ⇄ `STOPPED`; `ACTIVE` ⇄ `SUSPENDED`; `ACTIVE` → `SUNSET` → `RETIRED` | TS-03-12, 08 |
| Ngoại lệ luật WAF | đề nghị → duyệt hoặc từ chối → hiệu lực → hết hạn hoặc thu hồi | TS-03-04 |
| Ảnh chụp cấu hình | xây → ký → phát → nạp; từ chối ở kiểm tra; quay lui sinh ảnh mới | TS-03-16, 17 |
| Yêu cầu thay đổi bốn mắt | chờ duyệt → duyệt (áp dụng) hoặc từ chối | TS-03-24 |
| Consumer | tạo → hoạt động ⇄ tạm ngừng → gỡ (xóa mềm) | TS-03-08, 18 |

: Máy trạng thái được kiểm thử

## 4. Kịch bản và test case chức năng

Hai mươi lăm kịch bản của chương này đi theo bảy nhóm FR của D02-03-PH03 (lớp biên, xác thực, hạn mức, định tuyến, đồng bộ cấu hình, quan sát, quản trị) cộng kịch bản duyệt bốn mắt và giao diện. Mỗi kịch bản có mục tiêu, phạm vi phủ rồi tới các ca.

### TS-03-01 · TLS 1.3, mTLS và chứng thư biên

**Mục tiêu.** Xác nhận hai cửa vào chỉ nhận TLS 1.3 (TLS 1.2 chỉ ở host có ngoại lệ có hạn), xác minh chứng thư khách mTLS và quản lý vòng đời chứng thư biên không cắt kết nối.

**Phủ.** FR-03-001, 002, 049; UC-03-02, 17; API-03-031…035, 068…070; UI-03-12; BR-03-003; NFR-03-010, 011; LGC-BUS-041, LGC-APIM-011.

#### TC-03-001 · Biên chỉ nhận TLS 1.3, TLS 1.2 và thấp hơn bị từ chối <!--k:tls-13-only-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** FR-03-001 · API-03-031 · UI-03-12 · BR-03-003 · NFR-03-010 · LGC-BUS-041.

**Tiền điều kiện, dữ liệu.** `ext.t68.sim.test`, `int.t68.sim.test` ở IPv4; U-T68-TA.

**Các bước.**

1. `openssl s_client -tls1_3` tới hai host.
2. `openssl s_client -tls1_2`, rồi `-tls1_1` tới hai host.
3. Chạy `testssl.sh` tới `ext.t68.sim.test`.
4. `GET /edge/tls-profile`.

**Kết quả mong đợi.** Bước 1 bắt tay thành công. Bước 2 bị từ chối ở cả hai host. Bước 3 điểm A+, 0 giao thức hoặc bộ mã yếu. Bước 4 trả `200`, `minVersion = TLSv1.3`, danh sách bộ mã khớp bước 3. KT: không.
:::

#### TC-03-002 · Ngoại lệ TLS 1.2 có thời hạn cho host riêng <!--k:tls-exception-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, GW.

**Truy vết.** FR-03-001 · API-03-032, 033, 034 · UI-03-12 · BR-03-003 · UC-03-17.

**Tiền điều kiện, dữ liệu.** U-PA; host chuyên dụng `legacy.t68.sim.test`.

**Các bước.**

1. `POST /tls-exceptions` với `host = legacy.t68.sim.test`, `days = 180`, lý do.
2. `openssl s_client -tls1_2` tới `legacy.t68.sim.test` và tới `ext.t68.sim.test`.
3. `POST /tls-exceptions/{exceptionId}:revoke`; chờ hiệu lực ≤ 60 s; lặp bước 2.
4. `POST …:revoke` lần hai.

**Kết quả mong đợi.** Bước 1 trả `201`. Bước 2 TLS 1.2 chỉ thành công ở host ngoại lệ. Bước 3 `200`, sau đó host ngoại lệ cũng từ chối TLS 1.2. Bước 4 `409` ERR-03-019. KT: có (`TLS_EXCEPTION_CREATE`, `TLS_EXCEPTION_REVOKE`).
:::

#### TC-03-003 · Ngoại lệ TLS 1.2 quá hạn, thiếu lý do, không đủ quyền <!--k:tls-exception-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-001 · API-03-033 · ERR-03-003, 022 · BR-03-003.

**Tiền điều kiện, dữ liệu.** U-PA; U-T68-VW.

**Các bước.**

1. `POST /tls-exceptions` với `days = 181`.
2. `POST /tls-exceptions` thiếu `reason`.
3. U-T68-VW gọi `POST /tls-exceptions` hợp lệ.

**Kết quả mong đợi.** Bước 1, 2 trả `400` ERR-03-003 kèm `errors[]` theo trường; bước 3 trả 403-PQ. Không có ngoại lệ nào được tạo. KT: không.
:::

#### TC-03-004 · SNI hoặc Host không khớp dịch vụ nào <!--k:sni-mismatch-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-001 · ERR-03-128 · BR-03-023 · UC-03-05.

**Tiền điều kiện, dữ liệu.** Cửa `apisix-ext`.

**Các bước.**

1. `curl --resolve unknown.sim.test:443:{ip-ext} https://unknown.sim.test/`.
2. `curl` tới `ext.t68.sim.test` nhưng đặt `Host: unknown.sim.test`.

**Kết quả mong đợi.** Cả hai trả `421`, Lỗi GW 128, câu "Địa chỉ truy cập không thuộc dịch vụ nào của nền tảng."; thân không nêu tên tenant nào.
:::

#### TC-03-005 · mTLS hợp lệ với token ràng buộc chứng thư <!--k:mtls-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-002, 014 · API-03-016, 035 · UI-03-05, 12 · UC-03-02 · BR-03-004 · LGC-BUS-041, LGC-APIM-011.

**Tiền điều kiện, dữ liệu.** C-HTTT2 có chứng thư khách do CA đã đăng ký; token có `cnf.x5t#S256` khớp; route `r-sensitive`.

**Các bước.**

1. `GW C-HTTT2 GET https://int.t68.sim.test/sensitive/ping` kèm chứng thư và token.
2. `GET /consumers/ht-sensitive/credentials`.

**Kết quả mong đợi.** Bước 1 `200`; backend nhận `X-DH-Tenant = T68`, `X-DH-Client`. Bước 2 `200`, chỉ có dấu vân tay và hạn chứng thư, không có khóa riêng.
:::

#### TC-03-006 · mTLS thiếu, sai CA hoặc không khớp `cnf` <!--k:mtls-bad-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-002, 014 · ERR-03-108 · UC-03-02 · BR-03-004 · SEC-24.

**Tiền điều kiện, dữ liệu.** Như TC mTLS hợp lệ; thêm chứng thư của CA lạ và chứng thư hợp lệ của C-HTTT1.

**Các bước.**

1. Gọi `r-sensitive` có token đúng nhưng không xuất trình chứng thư.
2. Xuất trình chứng thư của CA lạ.
3. Xuất trình chứng thư hợp lệ của C-HTTT1 với token của C-HTTT2.

**Kết quả mong đợi.** Cả ba trả `403` Lỗi GW 108, câu "Chứng thư của HTTT không hợp lệ hoặc không được phép. Kiểm tra chứng thư và liên hệ quản trị Datahub."; backend không nhận lượt nào; có cảnh báo EVT: `security.alert-raised` mức Trung bình ở lần thứ ba.
:::

#### TC-03-007 · Bộ CA khách và danh sách chứng thư biên theo tenant <!--k:cert-list-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-002, 049 · API-03-035, 068, 069 · ERR-03-001, 022 · BR-03-028 · UI-03-12.

**Tiền điều kiện, dữ liệu.** U-T68-VW; U-T01-TA; chứng thư `cert-ext-t01` chỉ có ở T01.

**Các bước.**

1. U-T68-VW `GET /edge/client-ca-bundles`, `GET /certificates`.
2. U-T68-VW `GET /certificates/cert-ext-t01`.
3. U-T68-VW `GET /certificates/khong-co`.

**Kết quả mong đợi.** Bước 1 `200`, không có thân khóa riêng; chỉ thấy chứng thư của T68 và `COMMON`. Bước 2 và 3 cùng 404-ẩn.
:::

#### TC-03-008 · Gia hạn chứng thư biên không cắt kết nối <!--k:cert-renew-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW, k6.

**Truy vết.** FR-03-049 · API-03-070, 069 · UI-03-12 · EVT-03-08 · NFR-03-011 · BR-03-016.

**Tiền điều kiện, dữ liệu.** U-T68-TO; 200 kết nối HTTP/2 đang mở và tải 100 lượt/giây; chứng thư `cert-ext-t68`.

**Các bước.**

1. `POST /certificates/cert-ext-t68:renew`.
2. Theo dõi tải và kết nối trong lúc nạp chứng thư mới.
3. `GET /certificates/cert-ext-t68`.

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 0 lượt gọi lỗi, 200 kết nối cũ vẫn sống tới khi tự đóng. Bước 3 `serial` mới, hạn mới. KT: có (`CERT_RENEW`).
:::

#### TC-03-009 · Gia hạn chứng thư lỗi: chuỗi sai, khóa ký không sẵn sàng, đang gia hạn <!--k:cert-renew-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** IT, Chaos.

**Truy vết.** FR-03-049 · API-03-070 · ERR-03-015, 016, 019, 022 · UI-03-12.

**Tiền điều kiện, dữ liệu.** U-T68-TO; PKI giả trả `F-CERT-WRONG-HOST`; Chaos làm OpenBao mất.

**Các bước.**

1. `POST …:renew` khi PKI giả trả chứng thư sai host.
2. Gọi hai lần liên tiếp `:renew` cho cùng chứng thư.
3. Ngắt OpenBao rồi gọi `:renew`.
4. U-T68-VW gọi `:renew`.

**Kết quả mong đợi.** Bước 1 `422` ERR-03-016 và chứng thư đang chạy không đổi. Bước 2 lần hai `409` ERR-03-019. Bước 3 `503` ERR-03-015 kèm `retryAfterSeconds`. Bước 4 403-PQ.
:::

#### TC-03-010 · Cảnh báo chứng thư sắp hết hạn và tự gia hạn trước 30 ngày <!--k:cert-expiring-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-03-049, 002 · EVT-03-08 · NFR-03-011 · UI-03-12.

**Tiền điều kiện, dữ liệu.** `faketime` đưa chứng thư `cert-ext-t68` còn 31 ngày, rồi 29 ngày; consumer `ht-sensitive` có chứng thư còn 25 ngày.

**Các bước.**

1. Chạy lịch kiểm tra chứng thư ở mốc 31 và 29 ngày.
2. Gọi `r-sensitive` bằng C-HTTT2.

**Kết quả mong đợi.** Ở mốc 29 ngày có đúng một EVT: `certificate.expiring` (nếu tự gia hạn chưa chạy xong); chứng thư biên được gia hạn tự động trước mốc 30 ngày. Bước 2 `200` kèm tiêu đề `X-DH-Cert-Expires-In-Days: 25`.
:::

### TS-03-02 · Chống tràn theo địa chỉ nguồn và chặn tạm

**Mục tiêu.** Xác nhận giới hạn kết nối và tốc độ theo địa chỉ nguồn là lớp ngoài cùng (không thay hạn mức theo HTTT), tự chặn khi vi phạm liên tục, chặn thủ công có bảo vệ danh sách tin cậy.

**Phủ.** FR-03-003, 004; UC-03-12, 05; API-03-036…038; UI-03-15, 16; BR-03-005, 023; NFR-03-013; SEC-10.

#### TC-03-011 · Vượt tốc độ và số kết nối theo địa chỉ nguồn <!--k:ip-limit-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** GW, k6.

**Truy vết.** FR-03-003 · API-03-086 · UI-03-15 · ERR-03-119 · BR-03-005, 023 · NFR-03-013 · LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** Địa chỉ nguồn `10.99.0.5` (không trong `gw.ip.trustedCidrs`); `gw.ip.apiReqPerSecond = 200`, `gw.ip.burst = 2`, `gw.ip.maxConnections = 100`.

**Các bước.**

1. Từ `10.99.0.5` gửi 250 lượt/giây tới `r-ho-tich` trong 10 giây.
2. Mở 120 kết nối đồng thời.

**Kết quả mong đợi.** Bước 1: phần vượt (sau dung sai gấp 2 lần mỗi giây) nhận `429` Lỗi GW 119 kèm `Retry-After`, câu "Quá nhiều yêu cầu từ địa chỉ của bạn trong thời gian ngắn. Thử lại sau {n} giây."; phần trong ngưỡng nhận `200`. Bước 2: kết nối thứ 101 trở đi bị từ chối. Lượt gọi từ địa chỉ khác không bị ảnh hưởng.
:::

#### TC-03-012 · Địa chỉ trong danh sách tin cậy không bị giới hạn theo IP <!--k:ip-trusted-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-003 · API-03-087 · UI-03-16 · BR-03-005 · SEC-10.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SO1; `10.99.0.9` thêm vào `gw.ip.trustedCidrs` (SO duyệt).

**Các bước.**

1. `PUT /settings` thêm CIDR `10.99.0.9/32`.
2. Chờ hiệu lực ≤ 60 s; gửi 400 lượt/giây từ `10.99.0.9` (trong hạn mức của HTTT).

**Kết quả mong đợi.** Không có `429` mã 119; hạn mức theo HTTT vẫn áp dụng (ERR-03-116 nếu vượt 20 lượt/giây của C-HTTT1). KT: có (`SETTINGS_UPDATE`).
:::

#### TC-03-013 · Tự chặn địa chỉ vi phạm liên tục rồi tự gỡ <!--k:ip-autoblock-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-004 · API-03-036 · UI-03-15 · ERR-03-110 · EVT-03-09 · UC-03-12 · NFR-03-013 · SEC-10, 64.

**Tiền điều kiện, dữ liệu.** `gw.ip.autoBlock.threshold = 10`, `gw.ip.autoBlock.minutes = 15`; `faketime` điều khiển đồng hồ.

**Các bước.**

1. Từ `10.99.0.7` gây 9 lần vi phạm trong 60 giây, rồi gọi bình thường.
2. Gây thêm 1 lần (tổng 10).
3. Gọi `r-ho-tich`; `GET /ip-blocks`.
4. Tiến đồng hồ 16 phút; gọi lại.

**Kết quả mong đợi.** Sau bước 1 chưa chặn. Sau bước 2 mọi lượt gọi từ địa chỉ này nhận `403` Lỗi GW 110 (câu "Yêu cầu bị từ chối."); `GET /ip-blocks` thấy bản ghi `AUTO`, hết hạn sau 15 phút; có EVT: `security.alert-raised`; nguồn bị chặn ≤ 60 giây từ khi tấn công bắt đầu. Bước 4 gọi được trở lại.
:::

#### TC-03-014 · Chặn và bỏ chặn thủ công, không chặn được địa chỉ tin cậy <!--k:ip-block-manual-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-004 · API-03-037, 038, 036 · UI-03-15 · ERR-03-019, 024, 022 · UC-03-12.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; U-T68-TO; địa chỉ nền tảng `10.0.0.10` thuộc danh sách tin cậy.

**Các bước.**

1. `POST /ip-blocks` chặn `10.99.0.20` có lý do và `minutes = 60`; `Idempotency-Key`.
2. `POST /ip-blocks` chặn `10.0.0.10`.
3. `DELETE /ip-blocks/{blockId}` hai lần.
4. U-T68-TO gọi `POST /ip-blocks`.

**Kết quả mong đợi.** Bước 1 `201`, địa chỉ bị chặn ≤ 60 s. Bước 2 `422` ERR-03-024 "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn." Bước 3 lần một `204`, lần hai `409` ERR-03-019. Bước 4 403-PQ. KT: có (`IP_BLOCK_CREATE`, `IP_BLOCK_DELETE`).
:::

### TS-03-03 · WAF: chặn tấn công, chế độ phát hiện và chặn

**Mục tiêu.** Xác nhận WAF Coraza chặn payload OWASP ở chế độ `BLOCK`, chỉ ghi ở `DETECT`, đổi chế độ cần bốn mắt và điều kiện 14 ngày phát hiện, tự hạ về `DETECT` khi quá tải.

**Phủ.** FR-03-005, 006; UC-03-13, 05; API-03-039…041, 071…073; UI-03-07, 17; BR-03-007, 019; NFR-03-012; SEC-11.

#### TC-03-015 · WAF chặn payload OWASP ở chế độ BLOCK <!--k:waf-block-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW, ZAP.

**Truy vết.** FR-03-005 · API-03-039 · UI-03-07 · ERR-03-109 · BR-03-007 · NFR-03-012 · UC-03-05 · SEC-11.

**Tiền điều kiện, dữ liệu.** `gw.waf.mode = BLOCK`; `gw.waf.paranoia.api = 1`; `SIM-ATTACK` có 200 payload (SQLi, XSS, path traversal, SSRF, log4shell) và 1.000 yêu cầu hợp lệ.

**Các bước.**

1. Gửi toàn bộ payload tới `ext.t68.sim.test/ho-tich/...` bằng C-HTTT1.
2. Gửi 1.000 yêu cầu hợp lệ.
3. U-T68-SO1 `GET /waf/events?from=…&to=…`.

**Kết quả mong đợi.** Bước 1 ≥ 99 % payload nhận `403` Lỗi GW 109 (câu "Yêu cầu bị từ chối bởi tường lửa ứng dụng. Nếu bạn cho rằng đây là nhầm lẫn, gửi mã truy vết {traceId} cho quản trị Datahub."); backend không nhận. Bước 2 chặn nhầm < 0,1 %. Bước 3 `200`, mỗi sự kiện có `ruleId`, `traceId`, địa chỉ nguồn, không có thân bản tin hay giá trị tham số (mồi sạch). EVT: `security.alert-raised` khi vượt ngưỡng cảnh báo.
:::

#### TC-03-016 · Chế độ DETECT chỉ ghi, không chặn <!--k:waf-detect-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-006, 005 · API-03-040 · UI-03-07 · BR-03-019.

**Tiền điều kiện, dữ liệu.** `gw.waf.mode = DETECT`; U-T68-VW.

**Các bước.**

1. Gửi 20 payload SQLi qua `ext.t68.sim.test`.
2. `GET /waf/mode`; `GET /waf/events`.

**Kết quả mong đợi.** Bước 1 các lượt vẫn tới backend (`200` hoặc lỗi của backend), không có `403` mã 109. Bước 2 `mode = DETECT`, `detectDays`, `fpOpen`; có 20 sự kiện `DETECTED`.
:::

#### TC-03-017 · Đổi chế độ WAF sang BLOCK cần bốn mắt và đủ 14 ngày phát hiện <!--k:waf-mode-switch-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-006 · API-03-041, 071, 072 · UI-03-07, 17 · ERR-03-008, 027 · BR-03-019 · UC-03-13.

**Tiền điều kiện, dữ liệu.** U-T68-SO1, U-T68-SO2; `detectDays = 3` rồi tiến `faketime` tới 14 ngày; `fpOpen = 25` rồi xử lý còn 15 (`gw.waf.fpReviewMax = 20`).

**Các bước.**

1. SO1 `PUT /waf/mode` `BLOCK` khi `detectDays = 3`.
2. Khi đủ 14 ngày nhưng `fpOpen = 25`, lặp bước 1.
3. Khi đủ điều kiện, SO1 `PUT /waf/mode` `BLOCK`.
4. SO1 gọi `POST /change-requests/{id}:approve` cho yêu cầu của chính mình.
5. SO2 duyệt qua UI-03-17.

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-03-027 "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)." (bước 2 nêu số cảnh báo giả chưa xử lý). Bước 3 `202`, yêu cầu chờ duyệt, chế độ chưa đổi. Bước 4 `403` ERR-03-008 "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." Bước 5 `200`; ảnh chụp mới có `BLOCK` hiệu lực ≤ 60 s. KT: có (`WAF_MODE_REQUEST`, `WAF_MODE_APPROVE`).
:::

#### TC-03-018 · WAF tự hạ về DETECT khi quá tải và báo cáo <!--k:waf-degrade-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** k6, Chaos.

**Truy vết.** FR-03-006 · API-03-040 · UI-03-07 · ERR-03-008 · EVT-03-09 · NFR-03-002, 012 · BR-03-019.

**Tiền điều kiện, dữ liệu.** `gw.waf.mode = BLOCK`; `gw.waf.degradeP99Ms = 15`; Chaos thêm CPU giới hạn để p99 WAF > 15 ms trong 5 phút.

**Các bước.**

1. Chạy tải 300 lượt/giây với thân 32 KB khi WAF bị bóp CPU.
2. `GET /waf/mode`; `GET /security-alerts`.
3. Bỏ bóp CPU; theo dõi.

**Kết quả mong đợi.** Bước 2 `effectiveMode = DETECT` (tự hạ, không cần bốn mắt vì là hạ an toàn), có cảnh báo mức Cao "WAF tự hạ về chế độ phát hiện". Bước 3: sau khi p99 về dưới ngưỡng, hệ thống đề nghị đổi lại `BLOCK` cần bốn mắt, không tự đổi. Không lượt gọi nào bị lỗi do tự hạ.
:::

#### TC-03-019 · Thiếu quyền xem sự kiện WAF và đổi chế độ <!--k:waf-perm-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-005, 006 · API-03-039, 041 · ERR-03-022 · BR-03-019.

**Tiền điều kiện, dữ liệu.** U-T68-VW; U-T68-TO; U-T01-AU.

**Các bước.**

1. U-T68-VW `GET /waf/events`.
2. U-T68-TO `PUT /waf/mode`.
3. U-T01-AU `GET /waf/events` của T68.

**Kết quả mong đợi.** Bước 1 và 2 403-PQ (TO chỉ có `PERM-03-waf-request`, không có `PERM-03-waf`). Bước 3 không thấy sự kiện của T68 (danh sách rỗng hoặc 403-PQ), không lộ sự tồn tại.
:::

### TS-03-04 · Ngoại lệ luật WAF và luật vá ảo khẩn cấp

**Mục tiêu.** Xác nhận ngoại lệ luật WAF luôn có lý do, hạn tối đa 90 ngày, một route một mã luật, người duyệt là SO khác người đề nghị; luật vá ảo khẩn cấp có bốn mắt và gỡ được.

**Phủ.** FR-03-007, 008; UC-03-14, 15; API-03-042…049; UI-03-07, 08, 17; BR-03-006, 019; EVT-03-05, 06; SEC-07, 09, 11.

#### TC-03-020 · Vòng đời ngoại lệ WAF: đề nghị, duyệt, hiệu lực, hết hạn <!--k:waf-exc-lifecycle-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-007 · API-03-042, 043, 044, 046 · UI-03-07, 08, 17 · EVT-03-05, 06 · BR-03-006 · UC-03-14 · SEC-07.

**Tiền điều kiện, dữ liệu.** U-T68-TO đề nghị; U-T68-SO1 duyệt; WAF `BLOCK`; cảnh báo giả `942100` trên `r-ho-tich`.

**Các bước.**

1. TO `POST /waf/exceptions` `{routeCode: r-ho-tich, ruleId: 942100, days: 30, reason}`.
2. SO1 `POST /waf/exceptions/{id}:approve`.
3. Gửi payload kích hoạt luật 942100 tới `r-ho-tich` và tới route khác.
4. Tiến `faketime` tới còn 7 ngày, rồi hết hạn.
5. Thu hồi một ngoại lệ khác bằng `POST …:revoke`.

**Kết quả mong đợi.** Bước 1 `201`, `PENDING`; EVT: `waf-exception.changed`. Bước 2 `200`, hiệu lực ≤ 60 s. Bước 3 payload không bị chặn ở `r-ho-tich` nhưng bị chặn ở route khác (ngoại lệ chỉ một route, một luật). Bước 4 có EVT: `waf-exception.expiring` ở mốc 7 ngày, sau hạn luật 942100 chặn trở lại. Bước 5 `200`, hiệu lực ≤ 60 s. KT: có (`WAF_EXC_REQUEST`, `WAF_EXC_APPROVE`, `WAF_EXC_REVOKE`).
:::

#### TC-03-021 · Ngoại lệ WAF sai: quá 90 ngày, thiếu lý do, luật không có, trùng <!--k:waf-exc-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-007 · API-03-043 · ERR-03-009, 010, 003 · UI-03-08 · BR-03-006.

**Tiền điều kiện, dữ liệu.** U-T68-TO; đã có ngoại lệ hiệu lực cho `r-ho-tich`, `942100`.

**Các bước.**

1. `POST /waf/exceptions` với `days = 91`.
2. Thiếu `reason`.
3. `ruleId = 999999` không có trong CRS.
4. Cùng `r-ho-tich`, `942100` lần hai.
5. Thân chứa trường lạ `{"foo": 1}`.

**Kết quả mong đợi.** Bước 1–3 `422` ERR-03-009 "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày." Bước 4 `409` ERR-03-010 kèm `existingExpiresAt`. Bước 5 `400` ERR-03-003. Không tạo ngoại lệ nào, KT: không.
:::

#### TC-03-022 · Tự duyệt ngoại lệ WAF, người duyệt thiếu vai trò, tách nhiệm <!--k:waf-exc-4eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-007 · API-03-044, 045 · ERR-03-008, 022 · BR-03-006, 019 · UC-03-14.

**Tiền điều kiện, dữ liệu.** U-T68-SO-VD tự đề nghị; U-T68-TO; U-T68-SO2.

**Các bước.**

1. U-T68-SO-VD đề nghị rồi tự `:approve`.
2. U-T68-TO `:approve` ngoại lệ của người khác.
3. U-T68-SO2 `:reject` có lý do; sau đó `:approve` lại.

**Kết quả mong đợi.** Bước 1 `403` ERR-03-008 dù người dùng có đủ quyền (lớp bốn mắt độc lập vai trò). Bước 2 403-PQ (TO không có `PERM-03-waf-approve`). Bước 3 từ chối `200`; duyệt sau từ chối `409` ERR-03-019. KT: có cho từng lần duyệt, từ chối; ghi người đề nghị và người duyệt.
:::

#### TC-03-023 · Luật vá ảo khẩn cấp: tạo, hiệu lực, gỡ <!--k:vpatch-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, GW.

**Truy vết.** FR-03-008 · API-03-047, 048, 049 · UI-03-08 · ERR-03-009, 019, 022 · UC-03-15 · NFR-03-012 · SEC-09, 11.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; U-T68-TO; luật tùy biến chặn chuỗi `${jndi:` ở tham số `q`.

**Các bước.**

1. SO1 `POST /waf/virtual-patches` với mã luật hợp lệ, lý do, hạn 30 ngày.
2. Gửi `?q=${jndi:ldap://x}` tới route đã khai.
3. SO1 `POST /waf/virtual-patches/{patchId}:retire`; gỡ lần hai.
4. Tạo luật có lý do rỗng; TO tạo luật.

**Kết quả mong đợi.** Bước 1 `201`; có hiệu lực ≤ 4 giờ theo cam kết, đo thực tế ≤ 60 s. Bước 2 `403` Lỗi GW 109. Bước 3 lần một `200`, lần hai `409` ERR-03-019. Bước 4 `422` ERR-03-009; TO nhận 403-PQ. KT: có (`VPATCH_CREATE`, `VPATCH_RETIRE`).
:::

### TS-03-05 · Kiểm tra lược đồ, CORS, tiêu đề bảo mật

**Mục tiêu.** Xác nhận gateway chặn yêu cầu sai lược đồ hoặc quá cỡ trước backend, CORS không dùng ký tự đại diện, và phản hồi không lộ thông tin máy chủ.

**Phủ.** FR-03-009, 010, 011; UC-03-05; API-03-002, 009, 050, 051, 086, 087; UI-03-03, 16; BR-03-012, 013, 014, 023; NFR-03-015; SEC-43, 44.

#### TC-03-024 · Lược đồ và giới hạn kích thước: chấp nhận hợp lệ, chặn sai <!--k:schema-limits-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-009 · API-03-009, 002 · UI-03-03 · ERR-03-101, 115, 003, 018 · BR-03-014, 023 · SEC-43.

**Tiền điều kiện, dữ liệu.** `r-ho-tich` có `gw.body.maxBytes = 1 MiB`, `gw.json.maxDepth = 32`; `F-JSON-DEEP`, `F-JSON-BIG`, `F-XML-DOCTYPE`; U-T68-TA.

**Các bước.**

1. POST thân JSON đúng lược đồ 900 KiB.
2. POST thân sai kiểu trường; JSON sâu 100 mức; XML có DOCTYPE; `Content-Type` lạ.
3. POST thân 1 MiB + 1 byte và `F-JSON-BIG` (11 MiB).
4. `PUT /routes/r-ho-tich/request-limits` với `maxBytes = 11 MiB`, rồi `maxBytes = 2 MiB`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `400` Lỗi GW 101 kèm `errors[]` nêu trường, không nêu đường dẫn nội bộ. Bước 3 `413` Lỗi GW 115 "Nội dung gửi lên vượt giới hạn {n} MiB của API này. Giảm kích thước hoặc dùng kênh tải tệp." Bước 4: 11 MiB vượt trần 10 MiB `422` ERR-03-018; 2 MiB `200`; thân 1,5 MiB sau khi hiệu lực ≤ 60 s `200`. Dữ liệu sai không tới backend.
:::

#### TC-03-025 · CORS chỉ nguồn gốc liệt kê, không ký tự đại diện <!--k:cors-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** GW, API.

**Truy vết.** FR-03-010 · API-03-050, 051 · UI-03-03 · ERR-03-005, 022 · BR-03-012 · SEC-44.

**Tiền điều kiện, dữ liệu.** U-T68-TA; U-T68-VW.

**Các bước.**

1. `PUT /cors-policies/r-ho-tich` với `allowedOrigins = ["https://console.t68.sim.test"]`.
2. Gửi `OPTIONS` có `Origin` đúng, rồi `Origin: https://evil.test`.
3. `PUT` với `allowedOrigins = ["*"]`.
4. U-T68-VW `PUT` chính sách.

**Kết quả mong đợi.** Bước 2: nguồn đúng nhận `Access-Control-Allow-Origin` khớp đúng nguồn đó; nguồn lạ không có tiêu đề CORS. Bước 3 `422` ERR-03-005 (`findings[]` nêu ký tự đại diện). Bước 4 403-PQ.
:::

#### TC-03-026 · Tiêu đề bảo mật và che thông tin máy chủ <!--k:sec-headers-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP, GW.

**Truy vết.** FR-03-011 · API-03-086, 087 · UI-03-16 · ERR-03-129 · BR-03-013, 023 · NFR-03-015 · SEC-12, 43, 44.

**Tiền điều kiện, dữ liệu.** `r-ho-tich`; `SIM-BE-BAD` có tiêu đề `Server: nginx/1.25`, `X-Powered-By: PHP/8`; U-T68-TA.

**Các bước.**

1. Gọi thành công, gọi lỗi `404`, `429`, `502` qua gateway.
2. Chạy ZAP quét tiêu đề.
3. Gây lỗi nội bộ gateway (plugin ném ngoại lệ có chủ đích trong môi trường thử).
4. `PUT /settings` thử tắt tiêu đề bảo mật.

**Kết quả mong đợi.** Mọi phản hồi có `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy` (ở đường dẫn giao diện), không có `Server` hay `X-Powered-By` lộ phiên bản (0 tiêu đề lộ). Bước 3 `500` Lỗi GW 129 không có vết ngăn xếp, tên máy, đường dẫn nội bộ; có `X-Trace-Id`. Bước 4 `400` ERR-03-003 (tham số không đổi được).
:::

### TS-03-06 · Xác thực JWT, xác định tenant, phương thức bảo mật theo gói

**Mục tiêu.** Xác nhận token được xác minh cục bộ bằng JWKS đã đệm, tenant chỉ lấy từ token, tiêu đề `X-DH-*` của khách bị xóa, token ràng buộc chứng thư và phương thức xác thực đúng với gói của API.

**Phủ.** FR-03-012, 013, 014, 015; UC-03-01, 03; API-03-052, 021, 022, 066; UI-03-03, 11, 13; BR-03-002, 004, 026; NFR-03-002; SEC-25, 80, 87; LGC-APIM-011.

#### TC-03-027 · Gọi với token hợp lệ, backend nhận tiêu đề nội bộ do gateway đặt <!--k:jwt-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-012, 013 · API-03-052 · UI-03-11 · UC-03-01 · BR-03-002, 004 · NFR-03-002 · LGC-APIM-011.

**Tiền điều kiện, dữ liệu.** C-HTTT1 lấy token `client_credentials` từ Keycloak T68; `r-ho-tich`.

**Các bước.**

1. `GW C-HTTT1 GET /ho-tich/ping` kèm `Authorization: Bearer`.
2. Gửi lại kèm tiêu đề giả `X-DH-Tenant: T01`, `X-DH-Consumer: ht-khac`.
3. `GET /auth/jwks-status`.

**Kết quả mong đợi.** Bước 1 `200`; backend nhận `X-DH-Tenant = T68`, `X-DH-Client`, `X-DH-Consumer = ht-ndxp`, `traceparent`. Bước 2 backend vẫn nhận giá trị đúng của T68 (tiêu đề giả bị xóa). Bước 3 `200`, mỗi nút có `kid` đã đệm và `refreshedAt`. Không có lượt gọi nào tới Keycloak cho từng yêu cầu (đếm ở `SIM-KC`).
:::

#### TC-03-028 · Thiếu token, chữ ký sai, `iss` hoặc `aud` sai, token hết hạn <!--k:jwt-bad-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-012 · UC-03-01 · ERR-03-102, 103, 104 · BR-03-004, 023 · SEC-25.

**Tiền điều kiện, dữ liệu.** `SIM-KC` ký được token sai (khóa lạ, `kid` lạ, `iss` realm khác, `aud` khác, `exp` đã qua); `r-ho-tich`.

**Các bước.**

1. Gọi không có `Authorization`.
2. Token ký bằng khóa lạ; `kid` không có trong JWKS; `iss` lạ; `aud` lạ; `alg = none`.
3. Token hết hạn 1 giây.

**Kết quả mong đợi.** Bước 1 `401` Lỗi GW 102 "Thiếu thông tin xác thực. Gửi token truy cập trong tiêu đề Authorization." Bước 2 mọi trường hợp `401` Lỗi GW 103 "Token không hợp lệ. Lấy token mới từ máy chủ định danh." Bước 3 `401` Lỗi GW 104 "Token đã hết hạn. Lấy token mới rồi gọi lại." Backend không nhận lượt nào; nhật ký có siêu dữ liệu, không có giá trị tiêu đề `Authorization` (mồi sạch).
:::

#### TC-03-029 · Bộ đệm JWKS: Keycloak ngắt vẫn xác minh, quá 24 giờ thì từ chối <!--k:jwks-cache-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-03-012 · API-03-052 · UI-03-11 · ERR-03-124 · NFR-03-007 · BR-03-004 · SEC-25.

**Tiền điều kiện, dữ liệu.** `gw.jwks.refreshMinutes = 10`; `SIM-KC` ngắt; `faketime`.

**Các bước.**

1. Ngắt `SIM-KC`; sau 2 giờ gọi bằng token còn hạn.
2. Tiến thời gian tới 24 giờ + 1 phút không làm mới được JWKS; gọi lại.
3. Bật `SIM-KC`; chờ chu kỳ làm mới; gọi lại.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `503` Lỗi GW 124 kèm `Retry-After: 30` "Dịch vụ định danh tạm thời không khả dụng. Thử lại sau."; `jwks-status` thấy `stale = true`; có cảnh báo EVT: `security.alert-raised`. Bước 3 `200` trở lại không cần khởi động lại.
:::

#### TC-03-030 · Token của tenant khác hoặc realm khác không dùng được <!--k:tenant-mismatch-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-013 · UC-03-03 · ERR-03-106 · BR-03-002, 026 · SEC-80, 87 · NFR-03-019.

**Tiền điều kiện, dữ liệu.** C-T01 (token T01); route `r-ho-tich` của T68; route `r-ho-tich` trùng mã của T01.

**Các bước.**

1. C-T01 gọi `https://int.t68.sim.test/ho-tich/ping`.
2. Token T68 nhưng sửa claim `tenant = T01` (ký lại bằng khóa lạ).
3. C-T01 gọi `https://int.t01.sim.test/ho-tich/ping`.

**Kết quả mong đợi.** Bước 1 `401` Lỗi GW 106 "Token không thuộc tỉnh của API này. Lấy token từ máy chủ định danh của đúng tỉnh." Bước 2 `401` Lỗi GW 103. Bước 3 `200` từ backend của T01, không phải của T68 (kiểm bằng dấu vết backend). Không bên nào thấy dữ liệu của tenant kia; cảnh báo `security.alert-raised` cho bước 1.
:::

#### TC-03-031 · Phương thức bảo mật khác gói, Keyless chỉ dữ liệu mở <!--k:plan-method-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-015 · API-03-021, 022, 066 · UI-03-03, 13 · ERR-03-103, 130, 005 · BR-03-004, 014 · LGC-APIM-011.

**Tiền điều kiện, dữ liệu.** C-KEY (khóa API) gọi `r-ho-tich` (gói OAuth); C-OPEN; `r-open-data`; U-T68-TA.

**Các bước.**

1. C-KEY gọi `r-ho-tich` bằng khóa API.
2. C-OPEN gọi `r-open-data` không xác thực.
3. C-OPEN gọi `r-ho-tich` không xác thực.
4. Dùng khóa API sai trên route gói khóa API.
5. `GET /plan-policies`, `GET /plan-policies/{policyCode}`.
6. Cố gắng phát cấu hình có route mức Nhạy cảm đặt Keyless (`POST /snapshots:build`).

**Kết quả mong đợi.** Bước 1 `403` Lỗi GW 130 "API này yêu cầu xác thực bằng {OAuth 2.1 | chứng thư mTLS}. Phương thức bạn dùng không được chấp nhận." Bước 2 `200`. Bước 3 `401` Lỗi GW 102. Bước 4 `401` Lỗi GW 103. Bước 5 `200`, mỗi chính sách có phương thức, hạn mức chiếu từ gói. Bước 6 `422` ERR-03-005 (`findings[]` nêu phương thức không hợp lệ với mức phân loại).
:::

### TS-03-07 · Đăng ký sử dụng, phạm vi quyền, đường dẫn và ủy quyền OPA

**Mục tiêu.** Xác nhận gateway chỉ kiểm soát truy cập thô (đăng ký, phạm vi, đường dẫn) rồi hỏi OPA; quyết định từ chối có lý do và gateway đóng khi OPA không phản hồi.

**Phủ.** FR-03-016, 017, 019, 020; UC-03-01; API-03-012, 021, 022, 055, 065; UI-03-03, 05, 13; BR-03-008, 014, 017, 021; SEC-24, 26; LGC-APIM-011; 014, 016.

#### TC-03-032 · Kiểm tra đăng ký sử dụng và hiệu lực gói <!--k:subscription-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-016 · API-03-012, 021 · UI-03-05 · ERR-03-111, 127 · BR-03-021, 022 · LGC-APIM-011; 016.

**Tiền điều kiện, dữ liệu.** C-HTTT1 có đăng ký `r-ho-tich` hiệu lực; HTTT `HT-KHAC` chưa đăng ký; đăng ký thứ ba hết hạn hôm qua.

**Các bước.**

1. C-HTTT1 gọi `r-ho-tich`.
2. Client của `HT-KHAC` gọi `r-ho-tich`.
3. Client có đăng ký hết hiệu lực gọi `r-ho-tich`.
4. PH-01 tạm ngừng HTTT của C-HTTT1; C-HTTT1 gọi lại.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2, 3 `403` Lỗi GW 111 "HTTT của bạn chưa đăng ký sử dụng API này hoặc đăng ký đã hết hiệu lực. Liên hệ chủ dịch vụ hoặc quản trị Datahub." Bước 4 `403` Lỗi GW 127 ≤ 60 s. `GET /consumers/ht-ndxp` hiển thị đăng ký và trạng thái.
:::

#### TC-03-033 · Phạm vi quyền thô: thiếu scope bị chặn <!--k:scope-check-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-017 · API-03-002, 022 · UI-03-03 · ERR-03-107 · BR-03-008 · SEC-25, 26.

**Tiền điều kiện, dữ liệu.** Route `r-ho-tich` yêu cầu `ho-tich.read` cho GET và `ho-tich.write` cho POST; token C-HTTT1 chỉ có `ho-tich.read`.

**Các bước.**

1. GET bằng token đủ scope.
2. POST bằng cùng token.
3. Token có cả hai scope POST.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `403` Lỗi GW 107 "Token thiếu phạm vi quyền {scope}. Xin cấp thêm phạm vi này cho HTTT của bạn." Bước 3 `200`. Backend không nhận lượt ở bước 2.
:::

#### TC-03-034 · Danh sách cho phép và chặn đường dẫn <!--k:path-acl-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-020 · API-03-021, 022, 065 · UI-03-03, 13 · ERR-03-113, 005 · BR-03-014, 017 · LGC-APIM-014.

**Tiền điều kiện, dữ liệu.** Gói `GOI-STD` cho phép `/ho-tich/tra-cuu/**`, chặn `/ho-tich/quan-tri/**`; U-T68-TA.

**Các bước.**

1. C-HTTT1 gọi `/ho-tich/tra-cuu/1`.
2. Gọi `/ho-tich/quan-tri/xoa`; gọi `/ho-tich/../quan-tri/xoa` (đường dẫn chuẩn hóa).
3. `GET /policy-templates` xem mẫu chặn đường dẫn.
4. Phát cấu hình có mẫu đường dẫn sai cú pháp (`/ho-tich/[`).

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 cả hai `403` Lỗi GW 113 "Đường dẫn này không nằm trong phạm vi gói sử dụng của HTTT của bạn." Bước 3 `200`. Bước 4 `422` ERR-03-005.
:::

#### TC-03-035 · OPA cho phép và từ chối kèm lý do <!--k:opa-decision-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-019 · API-03-055 · UI-03-03 · ERR-03-112 · BR-03-008, 023 · NFR-03-002 · SEC-26 · LGC-BUS-041.

**Tiền điều kiện, dữ liệu.** `SIM-OPA` cấu hình `allow-ho-tich` cho C-HTTT1, từ chối `C-OTHER` với lý do `purpose_not_allowed`.

**Các bước.**

1. C-HTTT1 gọi `r-ho-tich`.
2. `C-OTHER` (cùng gói) gọi `r-ho-tich`.
3. `GET /authorization-bindings`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `403` Lỗi GW 112 kèm lý do `purpose_not_allowed` (không lộ nội dung chính sách). Bước 3 `200`, `r-ho-tich` gắn `allow-ho-tich`; p99 hỏi OPA ≤ 2 ms (đo ở NFR-03-002).
:::

#### TC-03-036 · OPA không phản hồi: gateway đóng, không cho qua <!--k:opa-down-->

::: dac-ta
**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-03-019 · UI-03-03 · ERR-03-124 · BR-03-008 · SEC-26.

**Tiền điều kiện, dữ liệu.** `SIM-OPA` chờ 5 giây hoặc ngắt; `r-ho-tich`.

**Các bước.**

1. Ngắt OPA; C-HTTT1 gọi `r-ho-tich` liên tục 30 giây.
2. Bật OPA; gọi lại.

**Kết quả mong đợi.** Bước 1 mọi lượt `503` Lỗi GW 124 kèm `Retry-After` (không có lượt nào qua vì "OPA im lặng"), có cảnh báo mức Cao. Bước 2 `200` trở lại.
:::

### TS-03-08 · Thu hồi token nhanh và tạm ngừng khẩn cấp

**Mục tiêu.** Xác nhận thu hồi token và tạm ngừng consumer hoặc route có hiệu lực không quá 60 giây (mục tiêu 30 giây), không chờ token hết hạn, và thao tác lặp, sai trạng thái, thiếu quyền bị từ chối đúng mã.

**Phủ.** FR-03-018, 047; UC-03-10, 11; API-03-053, 054, 017…020; UI-03-02, 05; ERR-03-105, 123, 127, 019, 023, 022; EVT-03-03, 04; BR-03-021, 025, 029; NFR-03-009; SEC-25, 72, 73.

#### TC-03-037 · Thu hồi token có hiệu lực không quá 60 giây <!--k:revoke-token-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-018 · API-03-053, 054 · UI-03-05 · UC-03-10 · ERR-03-105 · BR-03-021 · NFR-03-009 · SEC-25.

**Tiền điều kiện, dữ liệu.** S-REVOKE; token C-HTTT1 còn hạn 1 giờ, đang gọi 5 lượt/giây; U-T68-TA.

**Các bước.**

1. Gọi liên tục mỗi 1 giây bằng token.
2. S-REVOKE `POST /revocations` `{jti, reason, expiresAt}` kèm `Idempotency-Key`.
3. Ghi thời gian tới lượt gọi đầu tiên nhận lỗi.
4. U-T68-TA `GET /revocations`.

**Kết quả mong đợi.** Bước 2 `201`. Bước 3 lượt gọi bị `401` Lỗi GW 105 "Token đã bị thu hồi. Liên hệ quản trị Datahub nếu cần cấp lại." trong ≤ 60 s (mục tiêu ≤ 30 s). Bước 4 `200`, `jti` có trong danh sách. Thu hồi không ảnh hưởng token khác của C-HTTT1. KT: có (`TOKEN_REVOKE`).
:::

#### TC-03-038 · Thu hồi token: thiếu scope dịch vụ, người dùng thường, lặp lại <!--k:revoke-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-018 · API-03-053 · ERR-03-022, 003, 019 · BR-03-021.

**Tiền điều kiện, dữ liệu.** U-T68-TA (không có scope `gateway:revoke`); S-SYNC (scope khác); S-REVOKE.

**Các bước.**

1. U-T68-TA `POST /revocations`.
2. S-SYNC `POST /revocations`.
3. S-REVOKE gửi thân thiếu `jti`.
4. S-REVOKE gửi lại cùng `Idempotency-Key` và thân cũ; rồi cùng khóa nhưng thân khác.

**Kết quả mong đợi.** Bước 1, 2 403-PQ. Bước 3 `400` ERR-03-003. Bước 4 lần đầu trả lại kết quả cũ không tạo bản ghi mới; thân khác `400` ERR-03-003.
:::

#### TC-03-039 · Tạm ngừng khẩn cấp consumer, mở lại <!--k:suspend-consumer-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-047 · API-03-017, 018 · UI-03-05 · UC-03-11 · ERR-03-127 · EVT-03-04 · BR-03-021, 022 · NFR-03-009 · SEC-72.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; C-HTTT1 đang gọi.

**Các bước.**

1. SO1 `POST /consumers/ht-ndxp:suspend` có lý do.
2. Đo thời gian tới lượt gọi đầu tiên bị chặn.
3. SO1 `POST /consumers/ht-ndxp:resume`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `403` Lỗi GW 127 "HTTT của bạn đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub." trong ≤ 30 s. Bước 3 `200`, gọi lại được ≤ 60 s. EVT: `consumer.state-changed` hai lần. KT: có (`CONSUMER_SUSPEND`, `CONSUMER_RESUME`).
:::

#### TC-03-040 · Tạm ngừng khẩn cấp route và route sai trạng thái <!--k:suspend-route-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-047 · API-03-019, 020 · UI-03-02 · UC-03-11 · ERR-03-123, 019, 023, 001 · EVT-03-03 · BR-03-021, 029.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; `r-ho-tich` `ACTIVE`; `r-pending` `PENDING`.

**Các bước.**

1. `POST /routes/r-ho-tich:suspend`; gọi route.
2. `POST …:suspend` lần hai.
3. `POST /routes/r-pending:suspend`.
4. `POST /routes/khong-co:suspend`.
5. `POST /routes/r-ho-tich:resume`.

**Kết quả mong đợi.** Bước 1 `200`; lượt gọi `503` Lỗi GW 123 "API {mã} đang tạm dừng{: lý do nếu có}. Thử lại sau." kèm `Retry-After` ≤ 30 s. Bước 2 `409` ERR-03-019. Bước 3 `409` ERR-03-023. Bước 4 404-ẩn. Bước 5 `200`, gọi được. Mã route không đổi (BR-03-029).
:::

#### TC-03-041 · Thiếu quyền thao tác khẩn cấp <!--k:suspend-perm-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-047, 018 · API-03-017, 019, 054 · ERR-03-022 · BR-03-021.

**Tiền điều kiện, dữ liệu.** U-T68-VW; U-T68-AU.

**Các bước.**

1. U-T68-VW `POST /consumers/ht-ndxp:suspend`, `POST /routes/r-ho-tich:suspend`.
2. U-T68-AU `POST …:resume`.

**Kết quả mong đợi.** Cả ba 403-PQ; trạng thái không đổi; KT: không.
:::

### TS-03-09 · Hạn mức tần suất và hạn ngạch theo bên gọi

**Mục tiêu.** Xác nhận hạn mức tính theo HTTT chứ không theo IP, hạn ngạch theo chu kỳ có cảnh báo ngưỡng, nhóm `ESSENTIAL` được ưu tiên, phản hồi `429` đủ tiêu đề và gateway điều tiết khi backend yếu.

**Phủ.** FR-03-021, 022, 025, 027; UC-03-04; API-03-029, 030; UI-03-05, 06; ERR-03-116, 117; EVT-03-07; BR-03-005, 009, 020, 023, 024; LGC-APIM-012; 013, LGC-NFR-006.

#### TC-03-042 · Hạn mức tần suất theo HTTT kèm tiêu đề hạn mức <!--k:rate-limit-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** GW, k6.

**Truy vết.** FR-03-021, 025 · API-03-029 · UI-03-06 · UC-03-04 · ERR-03-116 · BR-03-005, 023, 024 · NFR-03-002 · LGC-APIM-012; LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** C-HTTT1 hạn mức 20 lượt/giây; U-T68-TO.

**Các bước.**

1. Gọi 20 lượt trong 1 giây.
2. Gọi lượt thứ 21 trong cùng giây.
3. Chờ `Retry-After`; gọi lại.
4. `GET /consumers/ht-ndxp/usage`.

**Kết quả mong đợi.** Mọi phản hồi (kể cả `200`) có `X-RateLimit-Limit: 20`, `X-RateLimit-Remaining` giảm đúng, `X-RateLimit-Reset`. Bước 2 `429` Lỗi GW 116 kèm `Retry-After`, câu "HTTT {mã} đã dùng hết {n} lượt trong {w} giây cho API {mã API}. Thử lại sau {s} giây." Bước 3 `200`. Bước 4 `200`, thấy `rateLimit`, mức đã dùng.
:::

#### TC-03-043 · Hạn mức theo HTTT, không theo địa chỉ IP <!--k:rate-by-consumer-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-021 · API-03-029 · UI-03-06 · ERR-03-116 · BR-03-005 · SEC-10.

**Tiền điều kiện, dữ liệu.** C-HTTT1 và C-ESS cùng một địa chỉ nguồn NAT `10.99.1.1`.

**Các bước.**

1. C-HTTT1 gửi 40 lượt/giây trong 5 giây; đồng thời C-ESS gửi 10 lượt/giây.
2. C-HTTT1 đổi sang địa chỉ nguồn khác, gửi 40 lượt/giây.

**Kết quả mong đợi.** Bước 1 C-HTTT1 bị `429` mã 116 khi vượt 20 lượt/giây; C-ESS hoàn toàn `200` (không bị trừ hạn mức của C-HTTT1). Bước 2 C-HTTT1 vẫn bị `429` (đổi IP không đổi hạn mức).
:::

#### TC-03-044 · Hạn ngạch theo chu kỳ, cảnh báo 80 % và 100 % <!--k:quota-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** GW, IT.

**Truy vết.** FR-03-022, 025 · API-03-029, 030 · UI-03-05, 06 · UC-03-04 · ERR-03-117 · EVT-03-07 · BR-03-009, 020 · LGC-APIM-013.

**Tiền điều kiện, dữ liệu.** Gói `GOI-MINI`: quota 1.000 lượt/ngày; client `ht-mini`; bộ đếm đặt sẵn 799.

**Các bước.**

1. Gọi 1 lượt (800 = 80 %).
2. Gọi tới 1.000.
3. Gọi lượt 1.001.
4. `GET /quota-alerts`; `GET /consumers/ht-mini/usage`.
5. Tiến đồng hồ qua nửa đêm; gọi lại.

**Kết quả mong đợi.** Bước 1 có EVT: `quota.threshold-reached` (80 %). Bước 2 EVT thứ hai (100 %). Bước 3 `429` Lỗi GW 117 "HTTT {mã} đã dùng hết hạn ngạch {n} lượt/{ngày|tháng|giờ} cho API {mã API}. Hạn ngạch đặt lại lúc {thời điểm}." kèm `X-RateLimit-Reset`. Bước 4 `200`, danh sách đúng hai cảnh báo; hạn ngạch chỉ dùng để bảo vệ và thống kê, không có trường tính tiền (BR-03-020). Bước 5 `200`.
:::

#### TC-03-045 · Nhóm ESSENTIAL được ưu tiên khi vượt hạn ngạch <!--k:essential-priority-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-021, 022, 027 · API-03-029 · UI-03-06 · ERR-03-117 · BR-03-009.

**Tiền điều kiện, dữ liệu.** C-ESS quota 1.000/ngày, nhóm `ESSENTIAL`; client thường cùng quota.

**Các bước.**

1. Cả hai gọi tới 1.000.
2. Tiếp tục gọi tới 1.200 và 1.201.

**Kết quả mong đợi.** Client thường nhận `429` mã 117 từ lượt 1.001. C-ESS vẫn `200` tới 1.200 (nới tối đa 20 %) kèm cảnh báo, rồi `429` mã 117 ở lượt 1.201; không bị chặn đột ngột ở lượt 1.001.
:::

#### TC-03-046 · Điều tiết theo tình trạng backend (trừ ESSENTIAL) <!--k:adaptive-throttle-->

::: dac-ta
**Loại.** Dương, Chịu lỗi.

**Ưu tiên.** P3.

**Tự động.** GW, k6.

**Truy vết.** FR-03-027 · API-03-029 · UI-03-06 · ERR-03-116 · BR-03-009 · LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** `SIM-BE-1…3` đặt p95 3 giây; C-HTTT1 và C-ESS gọi 15 lượt/giây.

**Các bước.**

1. Chạy tải 5 phút; quan sát mã phản hồi.
2. Đưa backend về bình thường.

**Kết quả mong đợi.** Bước 1 gateway giảm dần số lượt chuyển tới backend của C-HTTT1 (một phần `429` mã 116 do điều tiết, nêu trong `detail`), C-ESS không bị điều tiết. Bước 2 hạn mức phục hồi dần trong ≤ 2 phút.
:::

### TS-03-10 · Hạn mức toàn tenant và ghi đè theo route

**Mục tiêu.** Xác nhận hạn mức toàn tenant 500 lượt/giây cách ly tenant, hạ hạn mức cần bốn mắt, ghi đè theo route có thứ tự ưu tiên rõ và chặn giá trị vượt trần hợp đồng.

**Phủ.** FR-03-023, 024; UC-03-25; API-03-023…028, 071…073; UI-03-06, 17; ERR-03-118, 018, 008, 004, 001; EVT-03-11; BR-03-005, 019; NFR-03-019; SEC-86.

#### TC-03-047 · Hạn mức toàn tenant và cách ly giữa các tenant <!--k:tenant-limit-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** FR-03-023 · API-03-023 · UI-03-06 · ERR-03-118 · BR-03-005 · NFR-03-019 · SEC-86 · LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** T68 hạn mức 500 lượt/giây; T01 chạy tải nền 100 lượt/giây; nhiều client T68 (không client nào vượt hạn mức riêng).

**Các bước.**

1. T68 gửi 800 lượt/giây từ 40 client trong 60 giây.
2. Đo p95 và tỉ lệ lỗi của T01 trong cùng thời gian.
3. `GET /tenant-limits`.

**Kết quả mong đợi.** Bước 1 tổng lượt thành công ≈ 500/giây, phần vượt `429` Lỗi GW 118 "Tỉnh {tenant} đang vượt hạn mức {n} lượt/giây của nền tảng. Thử lại sau giây lát." Bước 2 p95 của T01 tăng ≤ 10 %, 0 lỗi do T68. Bước 3 `200` có giá trị hiện hành và trần hợp đồng.
:::

#### TC-03-048 · Hạ hạn mức toàn tenant cần bốn mắt; tăng trong trần được ngay <!--k:tenant-limit-4eyes-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-023 · API-03-024, 071, 072 · UI-03-06, 17 · ERR-03-008, 018, 004, 022 · EVT-03-11 · BR-03-019 · UC-03-25.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-TA2; trần hợp đồng 1.000; U-T68-TO.

**Các bước.**

1. TA `PUT /tenant-limits` `perSecond = 300` kèm `If-Match`.
2. TA tự `:approve`.
3. TA2 duyệt qua UI-03-17.
4. TA `PUT /tenant-limits` `perSecond = 800`.
5. `PUT` `perSecond = 1.200`.
6. `PUT` với `If-Match` cũ.
7. U-T68-TO `PUT`.

**Kết quả mong đợi.** Bước 1 `202`, hạn mức chưa đổi. Bước 2 `403` ERR-03-008. Bước 3 `200`, hạn mức mới hiệu lực ≤ 60 s, EVT: `limit.changed`. Bước 4 `200` ngay (tăng trong trần). Bước 5 `422` ERR-03-018 "Hạn mức phải nằm trong trần của tỉnh (1.000 lượt/giây)." Bước 6 `412` ERR-03-004. Bước 7 403-PQ.
:::

#### TC-03-049 · Ghi đè hạn mức theo route: tạo, sửa, xóa, thứ tự ưu tiên <!--k:rate-override-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, GW.

**Truy vết.** FR-03-024 · API-03-025, 026, 027, 028 · UI-03-06 · ERR-03-018, 004, 003, 001, 022 · UC-03-25 · BR-03-005, 019 · LGC-APIM-012; 013.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `r-ho-tich`, C-HTTT1 hạn mức gói 20 lượt/giây.

**Các bước.**

1. `POST /rate-limit-overrides` `{routeCode: r-ho-tich, consumerCode: ht-ndxp, perSecond: 5}` với `Idempotency-Key`.
2. Gọi 10 lượt/giây tới `r-ho-tich` và 10 lượt/giây tới route khác.
3. `PUT /rate-limit-overrides/{id}` `perSecond = 8` kèm `If-Match` cũ rồi đúng.
4. `perSecond = 0` hoặc vượt trần.
5. `DELETE /rate-limit-overrides/{id}`; `GET /rate-limit-overrides`.
6. `DELETE` mã không tồn tại.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 route `r-ho-tich` chặn ở 5 lượt/giây (ghi đè thắng hạn mức gói), route khác vẫn theo 20. Bước 3 `412` ERR-03-004 rồi `200`. Bước 4 `422` ERR-03-018. Bước 5 `204`, hạn mức về 20 ≤ 60 s. Bước 6 404-ẩn. Thiếu `PERM-03-limit`: 403-PQ.
:::

### TS-03-11 · Suy giảm có kiểm soát khi Valkey mất

**Mục tiêu.** Xác nhận khi bộ đếm Valkey không khả dụng gateway không sập: hạn ngạch mở có cảnh báo, tần suất và hạn mức tenant đếm cục bộ, danh sách chặn token dùng bộ đệm gần nhất.

**Phủ.** FR-03-026; UC-03-08; API-03-077; UI-03-01; BR-03-025; NFR-00-012; NFR-03-007.

#### TC-03-050 · Valkey ngắt: hạn ngạch mở, tần suất đếm cục bộ <!--k:valkey-down-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-03-026, 021, 022, 018 · API-03-077 · UI-03-01 · UC-03-08 · BR-03-025 · NFR-03-007.

**Tiền điều kiện, dữ liệu.** 3 bản sao `apisix-int`; C-HTTT1 20 lượt/giây, `ht-mini` quota sắp hết; token đã thu hồi trước đó.

**Các bước.**

1. Chaos Mesh ngắt toàn bộ Valkey 10 phút.
2. `ht-mini` gọi vượt hạn ngạch; C-HTTT1 gửi 100 lượt/giây.
3. Gọi bằng token đã thu hồi trước khi ngắt.
4. `GET /overview`.

**Kết quả mong đợi.** Bước 2 hạn ngạch mở (`200`) kèm cảnh báo `quota-degraded`; tần suất vẫn bị chặn nhờ đếm cục bộ (tổng cả ba bản sao ≈ 20 lượt/giây ± dung sai chia cho 3 bản sao). Bước 3 vẫn `401` mã 105 (dùng bộ đệm gần nhất). Bước 4 `degraded = true`, nguyên nhân `VALKEY_DOWN`. Không lượt gọi nào lỗi do mất Valkey.
:::

#### TC-03-051 · Valkey phục hồi: bộ đếm trở lại, không đếm đôi <!--k:valkey-recover-->

::: dac-ta
**Loại.** Dương, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-03-026 · API-03-077 · UI-03-01 · UC-03-08 · BR-03-025.

**Tiền điều kiện, dữ liệu.** Sau TC Valkey ngắt.

**Các bước.**

1. Bật Valkey; chờ 60 giây.
2. `ht-mini` gọi vượt hạn ngạch.
3. `GET /overview`.

**Kết quả mong đợi.** Bước 2 `429` mã 117 trở lại (hạn ngạch đếm tiếp từ giá trị Valkey, không đặt lại về 0 một cách sai). Bước 3 `degraded = false`; cảnh báo tự đóng.
:::

### TS-03-12 · Định tuyến, phiên bản API song song, dừng và mở API

**Mục tiêu.** Xác nhận mỗi lượt gọi đi đúng route theo host, đường dẫn, phương thức; route của tenant này không khớp lượt gọi của tenant khác; dừng và mở API tức thời; phiên bản cũ phục vụ song song với tiêu đề ngừng dùng rồi trả `410`.

**Phủ.** FR-03-028, 035, 036; UC-03-09, 01; API-03-001…004, 007; UI-03-02, 03; ERR-03-114, 123, 126, 019, 023, 001, 022; EVT-03-03; BR-03-010, 026, 029, 030; LGC-APIM-005; 017.

#### TC-03-052 · So khớp route theo host, đường dẫn, phương thức, ưu tiên <!--k:route-match-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-028 · API-03-001, 002 · UI-03-02, 03 · UC-03-01 · ERR-03-114 · BR-03-026, 001 · LGC-APIM-017.

**Tiền điều kiện, dữ liệu.** `r-ho-tich` GET, POST `/ho-tich/**`; route chính xác `/ho-tich/tra-cuu` ưu tiên cao hơn; `r-pending` `PENDING`.

**Các bước.**

1. GET `/ho-tich/tra-cuu` (khớp chính xác) và GET `/ho-tich/khac` (khớp tiền tố).
2. DELETE `/ho-tich/tra-cuu`.
3. GET `/khong-co-duong-nay`; GET route `r-pending`.
4. GET với `Host` không thuộc tenant nào.

**Kết quả mong đợi.** Bước 1 đúng backend của từng route (đường dẫn chính xác thắng). Bước 2 `405` kèm `Allow`, mã ERR-03-114 "Phương thức không được phép cho đường dẫn này." Bước 3 `404` Lỗi GW 114 "Không tìm thấy dịch vụ hoặc đường dẫn." (route `PENDING` như không tồn tại). Bước 4 `404` hoặc `421`, không lộ tên tenant.
:::

#### TC-03-053 · Route của tenant này không khớp lượt gọi của tenant khác <!--k:route-cross-tenant-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-028 · API-03-001, 002 · UI-03-02 · ERR-03-114, 001 · BR-03-026, 028 · NFR-03-019 · SEC-87.

**Tiền điều kiện, dữ liệu.** Route `r-ho-tich` trùng mã ở T68 và T01 nhưng khác backend; route `r-chi-t01` chỉ có ở T01; U-T68-VW.

**Các bước.**

1. Gọi `r-chi-t01` qua host T68 (`int.t68.sim.test/chi-t01/...`) bằng token T68.
2. Gọi `r-ho-tich` qua mỗi host, ghi backend nhận.
3. U-T68-VW `GET /routes/r-chi-t01`; `GET /routes/khong-co`; `GET /routes?q=r-chi-t01`.

**Kết quả mong đợi.** Bước 1 `404` Lỗi GW 114. Bước 2 mỗi host đến đúng backend của tenant mình. Bước 3 hai lần 404-ẩn giống hệt trừ `traceId`; danh sách không chứa route T01.
:::

#### TC-03-054 · Danh sách, chi tiết route: lọc, phân trang, phiên bản đối tượng <!--k:route-list-detail-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-03-028 · API-03-001, 002 · UI-03-02, 03 · BR-03-026 · NFR-03-023 · LGC-APIM-017.

**Tiền điều kiện, dữ liệu.** T68 có 1.000 route; U-T68-VW.

**Các bước.**

1. `GET /routes?page=1&size=20&state=ACTIVE&q=ho-tich`.
2. `GET /routes?size=101`.
3. `GET /routes/r-ho-tich` rồi mở UI-03-03.

**Kết quả mong đợi.** Bước 1 `200`, đúng 20 phần tử và tổng đúng. Bước 2 `400` ERR-03-003 (cỡ trang tối đa 100). Bước 3 `200` có `ETag`, `hostPattern`, `pathPattern`, `methods`, `upstream`, `plan`, `exposure`, `allowedActions`; UI hiển thị địa chỉ gọi (LGC-APIM-017). Đọc p95 ≤ 300 ms.
:::

#### TC-03-055 · Dừng và mở API tức thời <!--k:route-stop-start-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-036 · API-03-003, 004 · UI-03-02, 03 · UC-03-09 · ERR-03-123, 019, 023, 001, 022 · EVT-03-03 · BR-03-010, 029 · LGC-APIM-005.

**Tiền điều kiện, dữ liệu.** U-T68-TO; `r-ho-tich` `ACTIVE` dưới tải 50 lượt/giây; `r-pending`.

**Các bước.**

1. `POST /routes/r-ho-tich:stop`.
2. Gọi route; `POST …:stop` lần hai.
3. `POST …:start`.
4. `POST /routes/r-pending:stop`; `POST /routes/khong-co:stop`.
5. U-T68-VW `POST …:stop`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 lượt gọi `503` Lỗi GW 123 kèm `Retry-After` ≤ 30 s; lần dừng thứ hai `409` ERR-03-019. Bước 3 `200`, gọi được ≤ 60 s, 0 lượt lỗi ở route khác. Bước 4 `409` ERR-03-023 và 404-ẩn. Bước 5 403-PQ. EVT: `route.state-changed` mỗi lần đổi. KT: có (`ROUTE_STOP`, `ROUTE_START`).
:::

#### TC-03-056 · Phiên bản API song song, tiêu đề ngừng dùng, hết hạn phục vụ <!--k:api-versions-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** GW, API.

**Truy vết.** FR-03-035 · API-03-007, 002 · UI-03-02, 03 · UC-03-09 · ERR-03-126, 005 · BR-03-030 · NFR-00-055.

**Tiền điều kiện, dữ liệu.** `r-v1` `SUNSET` (công bố ngừng dùng từ 200 ngày trước), `r-v2` `ACTIVE`; một route khác chưa đủ 180 ngày.

**Các bước.**

1. `GET /routes/r-v1/versions`.
2. Gọi `r-v1` và `r-v2`.
3. Chuyển `r-v1` sang `RETIRED` (sau thời hạn giữ); gọi lại.
4. Cố đưa route công bố ngừng dùng 100 ngày sang `RETIRED`.

**Kết quả mong đợi.** Bước 1 `200`, liệt kê hai phiên bản kèm ngày công bố, ngày `Sunset`. Bước 2 `r-v1` có `Deprecation`, `Sunset`, `Link` tới phiên bản mới; `r-v2` không có. Bước 3 `410` Lỗi GW 126 "Phiên bản {v} của API {mã} đã ngừng phục vụ từ {ngày}. Chuyển sang phiên bản {v mới}." Bước 4 bị từ chối kiểm tra (ERR-03-005, `findings[]` nêu chưa đủ 180 ngày).
:::

### TS-03-13 · Cân bằng tải, kiểm tra sức khỏe, ngắt mạch, thời hạn chờ

**Mục tiêu.** Xác nhận gateway chia tải, loại backend hỏng nhanh, trả lỗi nhanh khi mọi backend không khỏe (không dồn tải), và trả `504`, `502` đúng ngữ cảnh.

**Phủ.** FR-03-029, 030, 031; UC-03-06; API-03-005, 006, 010; UI-03-03; ERR-03-120, 121, 122, 018, 001, 003; BR-03-011, 023; NFR-03-001; LGC-APIM-018; LGC-NFR-006.

#### TC-03-057 · Cân bằng tải giữa các backend và xem upstream <!--k:lb-roundrobin-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-029 · API-03-005, 006 · UI-03-03 · UC-03-06 · BR-03-011 · LGC-APIM-018.

**Tiền điều kiện, dữ liệu.** `up-ho-tich` gồm `SIM-BE-1…3` trọng số 1:1:2; U-T68-VW.

**Các bước.**

1. Gửi 4.000 lượt tới `r-ho-tich`, đếm theo backend.
2. `GET /upstreams`; `GET /upstreams/up-ho-tich`.
3. `GET /upstreams/up-chi-t01`.

**Kết quả mong đợi.** Bước 1 tỉ lệ ≈ 1:1:2 (sai số ≤ 5 %). Bước 2 `200`, mỗi backend có `healthy`, trọng số, số lỗi. Bước 3 404-ẩn.
:::

#### TC-03-058 · Loại backend hỏng khỏi vòng quay và đưa lại khi hồi phục <!--k:health-check-->

::: dac-ta
**Loại.** Dương, Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-030, 029 · API-03-006 · UI-03-03 · ERR-03-122 · BR-03-011 · NFR-03-001 · LGC-APIM-018; LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** `SIM-BE-2` trả `500` ở `/healthz`; tải 50 lượt/giây.

**Các bước.**

1. Làm `SIM-BE-2` trả lỗi; theo dõi lượt gọi và `GET /upstreams/up-ho-tich`.
2. Cho `SIM-BE-2` trả lỗi ở đường dẫn nghiệp vụ nhưng `/healthz` vẫn `200`.
3. Phục hồi `SIM-BE-2`.

**Kết quả mong đợi.** Bước 1 backend bị loại ≤ 15 s (kiểm tra chủ động mỗi 5 giây, 3 lần liên tiếp), tỉ lệ lỗi của khách < 1 %. Bước 2 kiểm tra thụ động loại backend sau chuỗi lỗi. Bước 3 backend được đưa lại sau ≤ 30 s; có cảnh báo `backend-unhealthy` rồi tự đóng.
:::

#### TC-03-059 · Mọi backend hỏng: trả 503 nhanh, thăm dò định kỳ <!--k:breaker-open-->

::: dac-ta
**Loại.** Dương, Âm, Chịu lỗi, Biên.

**Ưu tiên.** P1.

**Tự động.** GW, k6.

**Truy vết.** FR-03-031, 030 · API-03-010 · UI-03-03 · ERR-03-120 · BR-03-011, 023 · LGC-NFR-006.

**Tiền điều kiện, dữ liệu.** Cả ba `SIM-BE` trả `503`; tải 100 lượt/giây.

**Các bước.**

1. Làm mọi backend lỗi; gọi liên tục 60 giây.
2. Đếm lượt thực sự tới backend trong thời gian mạch mở.
3. Phục hồi một backend.

**Kết quả mong đợi.** Bước 1 sau khi mạch mở, lượt gọi nhận `503` Lỗi GW 120 trong ≤ 50 ms kèm `Retry-After` "Dịch vụ tạm thời không khả dụng. Thử lại sau {s} giây." Bước 2 chỉ vài lượt thăm dò mỗi chu kỳ, không dồn tải vào backend hỏng. Bước 3 mạch đóng sau thăm dò thành công, lượt gọi `200`.
:::

#### TC-03-060 · Thời hạn chờ và backend trả hỏng: 504 và 502 <!--k:timeout-502-504-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-031 · API-03-010 · UI-03-03 · ERR-03-121, 122, 018, 003, 001, 022 · BR-03-011, 023.

**Tiền điều kiện, dữ liệu.** U-T68-TA; route `r-slow` tới `SIM-BE-SLOW` (chờ 40 giây), thời hạn chờ 30 giây; route `r-bad` tới `SIM-BE-BAD`.

**Các bước.**

1. Gọi `r-slow`.
2. Gọi `r-bad`.
3. `PUT /routes/r-slow/timeouts` với `readSeconds = 10`; gọi lại.
4. `PUT` với `readSeconds = 0`, rồi vượt trần nền tảng; `PUT` cho route không tồn tại; U-T68-VW `PUT`.

**Kết quả mong đợi.** Bước 1 `504` Lỗi GW 121 "Dịch vụ phía sau không phản hồi kịp. Thử lại; nếu lặp lại, gửi mã truy vết {traceId} cho quản trị." Bước 2 `502` Lỗi GW 122 kèm `traceId`, không lộ nội dung phản hồi hỏng. Bước 3 `200`, sau hiệu lực lượt gọi hết hạn ở 10 giây. Bước 4 `422` ERR-03-018, `400` ERR-03-003, 404-ẩn, 403-PQ.
:::

### TS-03-14 · Truy vết, WebSocket và chuyển đổi gRPC

**Mục tiêu.** Xác nhận mọi lượt gọi có định danh truy vết truyền xuống backend, WebSocket đi qua với giới hạn kết nối, và chuyển đổi giao thức chưa hỗ trợ trả đúng mã.

**Phủ.** FR-03-032, 033, 034; UC-03-07, 01; API-03-002; UI-03-03, 09; ERR-03-101, 116, 125, 005; BR-03-017, 023; NFR-03-020; LGC-NFR-006.

#### TC-03-061 · Sinh và truyền `traceparent`, trả `X-Trace-Id` <!--k:trace-propagation-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-032 · UI-03-09 · UC-03-01 · BR-03-023 · NFR-03-020 · NFR-00-051.

**Tiền điều kiện, dữ liệu.** `r-ho-tich`; C-HTTT1.

**Các bước.**

1. Gọi không có `traceparent`.
2. Gọi có `traceparent` hợp lệ.
3. Gọi có `traceparent` sai định dạng.
4. Gọi gây lỗi `429` và `403`.

**Kết quả mong đợi.** Bước 1 gateway sinh `traceparent` mới gửi cho backend; phản hồi có `X-Trace-Id`. Bước 2 giữ nguyên `trace-id`, tạo `span` mới. Bước 3 thay bằng id mới, không lỗi. Bước 4 phản hồi lỗi vẫn có `X-Trace-Id`; 100 % lượt gọi có `trace_id` ở nhật ký và vết lỗi giữ 100 %.
:::

#### TC-03-062 · WebSocket: nâng cấp, tin nhắn, giới hạn kết nối, đóng khi thu hồi <!--k:websocket-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-033 · API-03-002 · UI-03-03 · UC-03-07 · ERR-03-101, 116 · BR-03-001 · NFR-03-004 · CMP-LAW-09.

**Tiền điều kiện, dữ liệu.** `r-ws` có giới hạn 50 kết nối mỗi consumer; C-HTTT1.

**Các bước.**

1. Mở kết nối `wss://…/ws/thong-bao` kèm token; gửi 100 tin nhắn; bật `permessage-deflate`.
2. Mở 51 kết nối đồng thời.
3. Mở kết nối không có token; gửi frame quá lớn (> giới hạn của route).
4. Thu hồi token khi kết nối đang mở.

**Kết quả mong đợi.** Bước 1 nhận đủ 100 tin, nén hoạt động. Bước 2 kết nối thứ 51 `429` Lỗi GW 116. Bước 3 `401` mã 102 trước khi nâng cấp; frame quá lớn đóng kết nối (mã đóng 1009). Bước 4 kết nối đóng ≤ 60 s.
:::

#### TC-03-063 · Chuyển đổi gRPC và REST: hỗ trợ và chưa hỗ trợ <!--k:grpc-rest-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** GW.

**Truy vết.** FR-03-034 · API-03-002 · UI-03-03 · UC-03-07 · ERR-03-125, 005 · BR-03-017.

**Tiền điều kiện, dữ liệu.** Hồ sơ triển khai Đợt 3 bật plugin chuyển đổi; route `r-grpc`; hồ sơ MVP tắt plugin.

**Các bước.**

1. Ở hồ sơ Đợt 3 gọi REST tới `r-grpc`.
2. Gọi kiểu chuyển đổi không hỗ trợ (SOAP sang gRPC).
3. Ở hồ sơ MVP phát cấu hình có route `r-grpc`.

**Kết quả mong đợi.** Bước 1 trả thân REST từ backend gRPC. Bước 2 `501` Lỗi GW 125 "Gateway chưa hỗ trợ kiểu chuyển đổi giao thức này." Bước 3 `422` ERR-03-005 (plugin ngoài danh mục được duyệt của hồ sơ). Ca chỉ bắt buộc chạy khi bật Đợt 3.
:::

### TS-03-15 · Cửa vào Internet, nội bộ và chuyển tiếp tenant sáp nhập

**Mục tiêu.** Xác nhận route mặc định chỉ ở cửa nội bộ, mở ra Internet cần SO duyệt và đủ điều kiện, và lượt gọi vào host của tenant đã sáp nhập được chuyển tiếp có thời hạn.

**Phủ.** FR-03-038, 037; UC-03-16, 30; API-03-008, 071…073, 094…096; UI-03-03, 16, 17; ERR-03-011, 008, 114, 025, 003, 019, 126, 106; EVT-03-03, 10; BR-03-015, 019, 026, 030; SEC-13.

#### TC-03-064 · Route mặc định chỉ ở cửa INT; mở ra cửa EXT cần bốn mắt <!--k:exposure-ext-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, GW, E2E.

**Truy vết.** FR-03-038 · API-03-008, 071, 072 · UI-03-03, 17 · UC-03-16 · ERR-03-008, 114 · EVT-03-03 · BR-03-015, 019 · SEC-13.

**Tiền điều kiện, dữ liệu.** `r-ext-ok`; U-T68-TA, U-T68-SO1.

**Các bước.**

1. Gọi `r-ext-ok` qua `ext.t68.sim.test` khi route ở `INT`.
2. TA `PUT /routes/r-ext-ok/exposure` `{exposure: EXT, reason}`.
3. TA tự duyệt qua `POST /change-requests/{id}:approve`.
4. SO1 duyệt.
5. Gọi lại qua `ext.t68.sim.test`.

**Kết quả mong đợi.** Bước 1 `404` Lỗi GW 114. Bước 2 `202`, route vẫn `INT`. Bước 3 `403` ERR-03-008. Bước 4 `200`; ảnh chụp mới có `EXT`; EVT: `route.state-changed`. Bước 5 `200` ≤ 60 s. KT: có (`EXPOSURE_REQUEST`, `EXPOSURE_APPROVE`).
:::

#### TC-03-065 · Mở cửa EXT khi chưa đủ điều kiện <!--k:exposure-ineligible-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-038 · API-03-008 · UI-03-03 · ERR-03-011, 003, 022 · BR-03-015 · SEC-13.

**Tiền điều kiện, dữ liệu.** `gw.waf.mode = DETECT`; `r-open-data` Keyless; `r-no-schema`; U-T68-TA; U-T68-TO.

**Các bước.**

1. `PUT /routes/r-ext-ok/exposure` `EXT` khi WAF `DETECT`.
2. `PUT` cho route Keyless mức Nhạy cảm; cho `r-no-schema`.
3. `PUT` với `exposure = XYZ`.
4. U-T68-TO `PUT`.

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-03-011 "Route chưa đủ điều kiện mở ra Internet: {lý do}." (`errors[]` nêu WAF chưa ở chế độ chặn, thiếu xác thực, thiếu lược đồ). Bước 3 `400` ERR-03-003. Bước 4 403-PQ. Route vẫn `INT`.
:::

#### TC-03-066 · Chuyển tiếp lượt gọi của tenant đã sáp nhập <!--k:tenant-redirect-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** GW, API.

**Truy vết.** FR-03-037 · API-03-094, 095, 096 · UI-03-16 · UC-03-30 · EVT-03-10 · BR-03-026, 030 · NFR-00-055.

**Tiền điều kiện, dữ liệu.** U-PA; T91 `MERGED` vào T68; host `ext.t91.sim.test`; C-HTTT1 có token T68.

**Các bước.**

1. `POST /tenant-redirects` `{sourceTenant: T91, targetTenant: T68, days: 180}` kèm `Idempotency-Key`.
2. Gọi `https://ext.t91.sim.test/ho-tich/ping` bằng token T68.
3. Gọi bằng token cũ của T91.
4. `GET /tenant-redirects`; `POST …/{redirectId}:end`.
5. Gọi lại host T91.

**Kết quả mong đợi.** Bước 1 `201`; EVT: `tenant-redirect.changed`. Bước 2 chuyển tới route T68, kèm `Deprecation`, `Sunset` (180 ngày). Bước 3 `401` Lỗi GW 106 (không chuyển tiếp token sai tenant). Bước 4 `200`. Bước 5 `404` hoặc `410` Lỗi GW 126. KT: có (`REDIRECT_CREATE`, `REDIRECT_END`).
:::

#### TC-03-067 · Chuyển tiếp tenant: sai điều kiện, trùng, thiếu quyền, đã kết thúc <!--k:tenant-redirect-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-037 · API-03-095, 096, 094 · ERR-03-025, 003, 019, 022, 001 · BR-03-026, 030.

**Tiền điều kiện, dữ liệu.** U-PA; U-T68-TA; T01 chưa sáp nhập; chuyển tiếp T91 đã tạo.

**Các bước.**

1. `POST /tenant-redirects` với nguồn `T01` (chưa `MERGED`).
2. Tạo chuyển tiếp thứ hai cho T91.
3. Thiếu `targetTenant`; `days = 400`.
4. `:end` hai lần; `:end` mã lạ.
5. U-T68-TA `POST /tenant-redirects`.

**Kết quả mong đợi.** Bước 1, 2 `409` ERR-03-025 "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy." Bước 3 `400` ERR-03-003. Bước 4 lần hai `409` ERR-03-019; mã lạ 404-ẩn. Bước 5 403-PQ (chỉ PA hoặc TA của tenant đích theo `PERM-03-admin`; TA T68 chỉ xem nếu không phải bên tạo).
:::

### TS-03-16 · Tổng hợp, kiểm tra hợp lệ và ký ảnh chụp cấu hình

**Mục tiêu.** Xác nhận control plane tổng hợp cấu hình từ danh mục, kiểm tra tĩnh chặn cấu hình nguy hiểm trước khi phát, và ký ảnh chụp có số phiên bản tăng đơn điệu.

**Phủ.** FR-03-039, 040, 041; UC-03-19; API-03-056…059; UI-03-10; ERR-03-005, 006, 011, 012, 013, 015, 016, 018, 022; EVT-03-12; BR-03-014, 016, 017, 018, 026; SEC-36, 65; LGC-APIM-011…015.

#### TC-03-068 · Tổng hợp, ký ảnh chụp; phiên bản tăng đơn điệu <!--k:snapshot-build-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-03-039, 041 · API-03-059, 056, 057 · UI-03-10 · UC-03-19 · BR-03-016, 018 · SEC-36, 65 · LGC-APIM-011…015.

**Tiền điều kiện, dữ liệu.** U-T68-TA; danh mục T68 có 20 route, 10 consumer; OpenBao khóa ký.

**Các bước.**

1. `POST /snapshots:build` kèm `Idempotency-Key`.
2. `GET /snapshots/{version}`; `GET /snapshots`.
3. Build lần hai không đổi nội dung; build sau khi đổi một route.
4. Kiểm chữ ký bằng khóa công khai.

**Kết quả mong đợi.** Bước 1 `201`, `version` = bản trước + 1, có `contentHash`, `signatureKeyId`, `builtFromCatalogRevision`. Bước 2 `200`, đủ route, consumer, chính sách; không có bí mật hay khóa riêng. Bước 3 lần hai `200` với nội dung giống (không tăng phiên bản vô ích) hoặc phiên bản mới nhưng không giảm; số phiên bản không bao giờ giảm. Bước 4 chữ ký hợp lệ. KT: có (`SNAPSHOT_BUILD`).
:::

#### TC-03-069 · Kiểm tra tĩnh chặn cấu hình sai: lược đồ, plugin ngoài danh mục, trùng host <!--k:snapshot-validate-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-03-040 · API-03-058, 059 · UI-03-10 · ERR-03-005, 011, 012, 013, 016, 018 · EVT-03-12 · BR-03-014, 017, 026 · SEC-24, 26, 43, 65.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `r-no-schema`; `tpl-lua-custom` ngoài danh mục; hai route cùng host và đường dẫn của hai tenant (cố ý); route EXT chưa đủ điều kiện; chứng thư `F-CERT-WRONG-HOST`; hạn mức vượt trần.

**Các bước.**

1. `POST /snapshots:validate` với danh mục chứa lỗi lần lượt từng loại.
2. `POST /snapshots:build` khi còn lỗi.

**Kết quả mong đợi.** Bước 1 `200` với `findings[]` đủ `checkId`, `severity`, `objectType`, `objectCode`. Bước 2 `422` ERR-03-005 "Cấu hình gateway không hợp lệ: {n} lỗi."; từng loại lỗi có mã tương ứng (thiếu lược đồ hoặc OPA: 012; plugin ngoài danh mục: 013; EXT chưa đủ điều kiện: 011; chứng thư: 016; vượt trần: 018); không có ảnh chụp nào được tạo; EVT: `snapshot.rejected` kèm danh sách lỗi.
:::

#### TC-03-070 · Đang có tổng hợp khác; dịch vụ ký không khả dụng <!--k:snapshot-build-conflict-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT, Chaos.

**Truy vết.** FR-03-039, 041 · API-03-059, 058 · UI-03-10 · ERR-03-006, 015, 022, 003 · BR-03-016 · SEC-36.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-TA2; U-T68-VW.

**Các bước.**

1. TA và TA2 gọi đồng thời `POST /snapshots:build`.
2. Ngắt OpenBao; `POST /snapshots:build`.
3. U-T68-VW `POST /snapshots:build` và `:validate`.
4. Gửi `:build` với trường lạ.

**Kết quả mong đợi.** Bước 1 một `201`, một `409` ERR-03-006 "Đang có một lần tổng hợp hoặc phát cấu hình cho tỉnh này. Chờ lần đó hoàn tất." kèm `retryAfterSeconds`. Bước 2 `503` ERR-03-015, cấu hình đang chạy không đổi. Bước 3 403-PQ. Bước 4 `400` ERR-03-003.
:::

#### TC-03-071 · Xem và so sánh ảnh chụp; cách ly tenant <!--k:snapshot-read-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-039, 044 · API-03-056, 057, 062 · UI-03-10 · ERR-03-001 · BR-03-028.

**Tiền điều kiện, dữ liệu.** T68 có ảnh chụp 41, 42; T01 có ảnh chụp 7; U-T68-VW.

**Các bước.**

1. `GET /snapshots`; `GET /snapshots/42`.
2. `GET /snapshots/42/diff` so với bản đang chạy.
3. `GET /snapshots/7`; `GET /snapshots/9999`.

**Kết quả mong đợi.** Bước 1 chỉ có ảnh chụp của T68. Bước 2 diff nêu route, consumer thêm, bớt, sửa, không có bí mật. Bước 3 hai lần 404-ẩn giống nhau trừ `traceId`.
:::

### TS-03-17 · Phát ảnh chụp, nạp nóng ở nút và quay lui

**Mục tiêu.** Xác nhận phát ảnh chụp tới Git và bucket, nút nạp nóng không làm lỗi lượt gọi, nút từ chối ảnh chụp sai, gateway tiếp tục phục vụ khi control plane ngừng và quay lui bằng ảnh chụp mới.

**Phủ.** FR-03-042, 043, 044; UC-03-20, 21; API-03-060…062, 056, 063, 064; UI-03-10, 11; ERR-03-014, 015, 006, 007, 022, 019; EVT-03-01, 02; BR-03-010, 016, 018; NFR-03-007, 008, 024; SEC-65.

#### TC-03-072 · Phát ảnh chụp, nút nạp nóng không lỗi lượt gọi <!--k:snapshot-publish-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW, k6.

**Truy vết.** FR-03-042, 043 · API-03-060, 063 · UI-03-10, 11 · UC-03-20 · EVT-03-01 · BR-03-010, 016 · NFR-03-008, 024.

**Tiền điều kiện, dữ liệu.** U-T68-TA; ảnh chụp đã build; tải 2.000 lượt/giây qua 3 bản sao `apisix-int`.

**Các bước.**

1. `POST /snapshots/{version}:publish`.
2. Đo độ trễ lan truyền tới mọi nút và số lượt gọi lỗi trong 60 giây quanh thời điểm phát.
3. `GET /nodes`.
4. Kiểm Git và bucket.

**Kết quả mong đợi.** Bước 1 `200`; EVT: `snapshot.published`. Bước 2 mọi nút chạy phiên bản mới ≤ 10 s (≤ 60 s theo yêu cầu hệ thống), 0 lượt gọi lỗi, không khởi động lại nút. Bước 3 mọi nút `version` mới, `inSync = true`. Bước 4 có ảnh chụp ở cả hai nơi, hash khớp. KT: có (`SNAPSHOT_PUBLISH`).
:::

#### TC-03-073 · Không ghi được Git hoặc bucket: cấu hình đang chạy không đổi <!--k:snapshot-publish-fail-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-03-042 · API-03-060 · UI-03-10 · ERR-03-014, 015, 006 · BR-03-010, 016 · SEC-65.

**Tiền điều kiện, dữ liệu.** `SIM-GIT` từ chối ghi; sau đó `SIM-BUCKET` từ chối; tải nền 100 lượt/giây.

**Các bước.**

1. Publish khi `SIM-GIT` từ chối.
2. Publish khi `SIM-BUCKET` từ chối.
3. Phục hồi; publish lại cùng phiên bản.

**Kết quả mong đợi.** Bước 1, 2 `502` ERR-03-014 "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." kèm `retryAfterSeconds`; nút không nhận phiên bản dang dở; 0 lượt gọi lỗi. Bước 3 `200`, không tạo bản trùng.
:::

#### TC-03-074 · Nút từ chối ảnh chụp sai chữ ký, phiên bản cũ hoặc hash lệch <!--k:node-reject-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW, IT.

**Truy vết.** FR-03-043, 045 · API-03-063, 064 · UI-03-11 · BR-03-016, 018 · SEC-65 · EVT-03-09.

**Tiền điều kiện, dữ liệu.** Bộ đồng bộ ở nút; ảnh chụp giả: chữ ký sai, phiên bản bằng bản đang chạy, `contentHash` lệch, cấu hình bị sửa trực tiếp trên pod.

**Các bước.**

1. Đẩy từng ảnh chụp giả vào bucket.
2. Sửa cấu hình trực tiếp trên một pod.
3. `GET /nodes/{nodeId}`; `GET /security-alerts`.

**Kết quả mong đợi.** Bước 1 nút từ chối cả ba, giữ cấu hình đang chạy, lượt gọi không lỗi. Bước 2 lệch so với Git bị phát hiện ≤ 1 giờ, nút báo `drift`. Bước 3 nút ghi `lastRejected` kèm lý do; có cảnh báo an ninh mức Cao.
:::

#### TC-03-075 · Control plane ngừng: gateway chạy tiếp, pod khởi động lại vẫn có cấu hình <!--k:node-offline-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-03-043 · API-03-064 · UI-03-11 · UC-03-20 · BR-03-010 · NFR-03-007 · NFR-00-012.

**Tiền điều kiện, dữ liệu.** Tải 300 lượt/giây; Chaos ngắt `dh-connect`, Argo CD, Git, bucket và Keycloak 24 giờ (rút gọn bằng `faketime`).

**Các bước.**

1. Ngắt các thành phần trên.
2. Xóa lần lượt từng pod APISIX (`maxUnavailable: 1`).
3. Gọi liên tục trong 24 giờ giả lập.

**Kết quả mong đợi.** Tỉ lệ lỗi do nền tảng < 0,1 %; pod mới khởi động có đủ cấu hình từ bản chụp cục bộ và phục vụ ngay; token vẫn xác minh được nhờ JWKS đệm (ở ≤ 24 giờ); `GET /nodes` khi hồi phục báo đúng phiên bản.
:::

#### TC-03-076 · Quay lui bằng ảnh chụp mới mang nội dung bản cũ <!--k:rollback-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GW.

**Truy vết.** FR-03-044 · API-03-061, 062, 056 · UI-03-10 · UC-03-21 · EVT-03-02 · BR-03-018, 016 · NFR-03-008 · SEC-65.

**Tiền điều kiện, dữ liệu.** U-T68-TO; ảnh chụp 41 (tốt), 42 (làm hỏng `r-ho-tich` cố ý) đang chạy.

**Các bước.**

1. `GET /snapshots/41/diff`.
2. `POST /snapshots/41:rollback` kèm `Idempotency-Key`.
3. `GET /snapshots`; gọi `r-ho-tich`.

**Kết quả mong đợi.** Bước 1 diff đúng thay đổi. Bước 2 `201`, ảnh chụp **43** mới có nội dung của 41 (không đưa bản 41 trở lại), EVT: `snapshot.rolled-back`. Bước 3 phiên bản đang chạy là 43, `r-ho-tich` phục hồi ≤ 60 s. KT: có (`SNAPSHOT_ROLLBACK`).
:::

#### TC-03-077 · Quay lui không hợp lệ: đối tượng không còn, đang bận, giữ tenant, thiếu quyền <!--k:rollback-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-044 · API-03-061 · UI-03-10 · ERR-03-007, 006, 022, 001 · BR-03-018.

**Tiền điều kiện, dữ liệu.** U-T68-TO; U-T68-VW; ảnh chụp 30 tham chiếu consumer đã gỡ; một lần phát đang chạy.

**Các bước.**

1. `POST /snapshots/30:rollback`.
2. Quay lui khi có lần phát đang chạy.
3. U-T68-VW quay lui.
4. `POST /snapshots/9999:rollback`.

**Kết quả mong đợi.** Bước 1 `422` ERR-03-007 "Không thể quay lui về phiên bản 30: consumer ht-cu không còn hợp lệ." kèm `findings[]`. Bước 2 `409` ERR-03-006. Bước 3 403-PQ. Bước 4 404-ẩn. Cấu hình đang chạy không đổi.
:::

### TS-03-18 · Nút gateway và đồng bộ consumer

**Mục tiêu.** Xác nhận quản trị thấy đúng trạng thái đồng bộ từng nút (thay "Danh sách gateway" của hệ cũ) và consumer đồng bộ từ PH-01 có hiệu lực ≤ 60 giây, kể cả khi tạm ngừng HTTT.

**Phủ.** FR-03-045, 046; UC-03-22, 23; API-03-063, 064, 011…015; UI-03-04, 05, 11; ERR-03-001, 002, 003, 017, 022, 026, 127; EVT-03-04; BR-03-016, 021, 022, 029; LGC-APIM-019; 020, 023…025.

#### TC-03-078 · Danh sách và chi tiết nút: phiên bản, lệch cấu hình, sức khỏe <!--k:nodes-status-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-045 · API-03-063, 064 · UI-03-11 · UC-03-22 · ERR-03-001, 026 · BR-03-016 · NFR-03-021 · LGC-APIM-023; 024, 025.

**Tiền điều kiện, dữ liệu.** 6 nút (3 `apisix-ext`, 3 `apisix-int`); U-PO; U-T68-VW; một nút cố ý chậm một phiên bản.

**Các bước.**

1. `GET /nodes`.
2. `GET /nodes/{nodeId}` của nút chậm.
3. `GET /nodes/khong-co`.
4. Ngắt `SIM-PH13`; `GET /nodes/{nodeId}`.

**Kết quả mong đợi.** Bước 1 `200`, mỗi nút có `zone`, `gate`, `version`, `inSync`, CPU, bộ nhớ, số lượt gọi (chỉ số APISIX, không JVM). Bước 2 `inSync = false`, `lag = 1`. Bước 3 404-ẩn. Bước 4 `503` ERR-03-026 "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau." (phần cấu hình vẫn trả).
:::

#### TC-03-079 · Đồng bộ consumer từ PH-01: tạo, đổi, gỡ, hiệu lực ≤ 60 giây <!--k:consumer-sync-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GW.

**Truy vết.** FR-03-046 · API-03-013, 014, 015, 011, 012, 016 · UI-03-04, 05 · UC-03-23 · EVT-03-04 · BR-03-021, 022, 029 · LGC-APIM-019; 020.

**Tiền điều kiện, dữ liệu.** S-SYNC; client mới `ht-moi` ở Keycloak.

**Các bước.**

1. `PUT /consumers/ht-moi` `{tenant: T68, httt: HT-MOI, tier, group}` kèm `Idempotency-Key`; lặp lại để cập nhật.
2. `PUT /consumers/ht-moi/credentials` với khóa công khai và dấu vân tay chứng thư.
3. Gọi API bằng client mới.
4. `DELETE /consumers/ht-moi` khi không còn đăng ký.
5. U-T68-VW `GET /consumers`, `GET /consumers/ht-moi`.

**Kết quả mong đợi.** Bước 1 `201` rồi `200`. Bước 2 `200`, không nhận khóa riêng. Bước 3 gọi được ≤ 60 s. Bước 4 `204`; gọi lại `401` mã 103 ≤ 60 s. Bước 5 danh sách và chi tiết đúng. EVT: `consumer.state-changed` mỗi lần. KT: có (`CONSUMER_SYNC`).
:::

#### TC-03-080 · Đồng bộ consumer lỗi: trùng, sai dữ liệu, còn đăng ký, thiếu scope, mã không dùng lại <!--k:consumer-sync-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-046 · API-03-013, 014, 015 · ERR-03-002, 003, 017, 022, 001 · BR-03-022, 029.

**Tiền điều kiện, dữ liệu.** S-SYNC; consumer `ht-ndxp` còn 2 đăng ký hiệu lực; `ht-cu` đã gỡ; U-T68-TA.

**Các bước.**

1. `PUT /consumers/ht-cu` (mã đã gỡ).
2. `PUT /consumers/ht-x` thiếu `tenant`; credentials có khóa không phải khóa công khai.
3. `DELETE /consumers/ht-ndxp`.
4. U-T68-TA `PUT /consumers/ht-y`.
5. `DELETE /consumers/khong-co`.

**Kết quả mong đợi.** Bước 1 `409` ERR-03-002 "Mã ht-cu đã được dùng. Chọn mã khác." Bước 2 `400` ERR-03-003. Bước 3 `409` ERR-03-017 "HTTT còn 2 đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ." Bước 4 403-PQ (chỉ dịch vụ có `gateway:sync`). Bước 5 404-ẩn.
:::

#### TC-03-081 · Tạm ngừng HTTT ở PH-01 kéo theo mọi consumer <!--k:consumer-cascade-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-046 · API-03-013, 012 · UI-03-04, 05 · UC-03-23 · ERR-03-127 · EVT-03-04 · BR-03-021, 022.

**Tiền điều kiện, dữ liệu.** HTTT `HT-2C` có hai client `ht-2c-a`, `ht-2c-b` đang gọi.

**Các bước.**

1. PH-01 tạm ngừng `HT-2C` (S-SYNC cập nhật trạng thái).
2. Gọi bằng cả hai client; đo thời gian.
3. PH-01 mở lại.

**Kết quả mong đợi.** Bước 2 cả hai `403` Lỗi GW 127 ≤ 60 s. Bước 3 cả hai gọi được ≤ 60 s. `GET /consumers/ht-2c-a` hiện trạng thái đúng.
:::

### TS-03-19 · Mẫu chính sách được duyệt sẵn và chạy thử chính sách

**Mục tiêu.** Xác nhận chỉ chạy plugin và mẫu chính sách trong danh mục được duyệt, bật tắt theo tenant có kiểm tra đang dùng, và chạy thử chính sách bằng mô phỏng không đụng bộ đếm thật.

**Phủ.** FR-03-048, 057; UC-03-24; API-03-065…067, 088; UI-03-13, 14; ERR-03-003, 013, 019, 001, 018, 022; BR-03-014, 017, 027; SEC-26, 42, 52; LGC-APIM-015.

#### TC-03-082 · Danh mục mẫu chính sách; bật, tắt cho tenant <!--k:policy-templates-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-048 · API-03-065, 066, 067 · UI-03-13 · UC-03-24 · ERR-03-013, 019, 003, 001, 022 · BR-03-017 · LGC-APIM-015.

**Tiền điều kiện, dữ liệu.** U-T68-TA; U-PA; mẫu `tpl-cors` đang dùng bởi 2 route; `tpl-lua-custom` ngoài danh mục.

**Các bước.**

1. `GET /policy-templates`; `GET /policy-templates/tpl-cors`.
2. TA `PUT /policy-templates/tpl-cors/enablement` `{enabled: false}`.
3. Tắt mẫu chưa bật lần hai; `GET /policy-templates/tpl-lua-custom`.
4. Gán `tpl-lua-custom` cho route rồi `POST /snapshots:validate`.
5. U-T68-VW `PUT …/enablement`.

**Kết quả mong đợi.** Bước 1 `200`, chỉ mẫu trong danh mục (kèm phiên bản, tham số). Bước 2 `409` ERR-03-019 (đang dùng bởi 2 route). Bước 3 lần hai `409`; `tpl-lua-custom` 404-ẩn. Bước 4 `findings[]` ERR-03-013 "Route {mã} dùng plugin {tên} không có trong danh mục được duyệt." Bước 5 403-PQ.
:::

#### TC-03-083 · Chạy thử chính sách bằng mô phỏng, không tăng bộ đếm <!--k:simulate-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-057 · API-03-088, 029 · UI-03-14 · UC-03-24 · ERR-03-003, 001, 018, 022 · BR-03-027 · SEC-26, 42.

**Tiền điều kiện, dữ liệu.** U-T68-TA; C-HTTT1 đã dùng 150 lượt/ngày; `SIM-BE` đếm lượt nhận.

**Các bước.**

1. `POST /simulations` `{consumer: ht-ndxp, route: r-ho-tich, method: GET, path, scopes, ip}`.
2. Lặp 50 lần.
3. `GET /consumers/ht-ndxp/usage`.
4. Mô phỏng với route lạ; trường sai kiểu; U-T68-VW gọi.

**Kết quả mong đợi.** Bước 1 `200`, trả quyết định từng chốt (xác thực, đăng ký, scope, đường dẫn, OPA, hạn mức) và lý do. Bước 2, 3 bộ đếm vẫn 150, `SIM-BE` nhận 0 lượt. Bước 4 404-ẩn, `400` ERR-03-003, 403-PQ.
:::

### TS-03-20 · Nhật ký lượt gọi: ghi có che dữ liệu, tra cứu, xuất

**Mục tiêu.** Xác nhận gateway chỉ ghi siêu dữ liệu lượt gọi (không thân bản tin, không giá trị tiêu đề xác thực, không giá trị tham số truy vấn), tra cứu có giới hạn khoảng thời gian và cách ly tenant, xuất bất đồng bộ.

**Phủ.** FR-03-050, 051; UC-03-26, 01, 03; API-03-074…076; UI-03-09, 05; ERR-03-021, 026, 022, 001, 003; BR-03-007, 023, 028; NFR-03-014, 022, 026; LGC-APIM-022.

#### TC-03-084 · Nhật ký chỉ có siêu dữ liệu, không lộ mồi <!--k:log-masked-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW, IT.

**Truy vết.** FR-03-050 · API-03-074 · UI-03-09 · UC-03-01 · BR-03-007 · NFR-03-014 · CMP-LAW-05 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** `CANARY` đặt ở thân JSON, tiêu đề `Authorization` và `Cookie`, giá trị tham số `?cccd=DH-CANARY-…`; C-HTTT1.

**Các bước.**

1. Gọi `r-ho-tich` với `CANARY` ở bốn vị trí, cả khi thành công và khi bị `403`, `429`, `502`.
2. U-T68-AU `GET /access-logs?consumer=ht-ndxp`.
3. Quét nhật ký APISIX, nhật ký ứng dụng, vết OTel, ClickHouse, Kafka.

**Kết quả mong đợi.** Bước 2 mỗi dòng có `time`, `routeCode`, `consumerCode`, `method`, đường dẫn (không chuỗi truy vấn), `status`, `latencyMs`, `bytes`, `traceId`, `srcIp`; không có trường thân hay giá trị tiêu đề. Bước 3 mồi sạch ở mọi nơi (0 giá trị trường mức Nhạy cảm, 0 thân, 0 giá trị tiêu đề xác thực).
:::

#### TC-03-085 · Tra cứu nhật ký theo bộ lọc, hiệu năng và quyền xem định danh <!--k:log-search-->

::: dac-ta
**Loại.** Dương, Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** API, k6.

**Truy vết.** FR-03-051 · API-03-074, 075 · UI-03-09, 05 · UC-03-26 · ERR-03-001, 022 · BR-03-028 · NFR-03-022 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** ClickHouse có 5 triệu bản ghi/ngày cho T68 trong 31 ngày; U-T68-AU, U-T68-TO, U-T68-VW.

**Các bước.**

1. AU `GET /access-logs?from=&to=&consumer=&route=&status=5xx&size=50`.
2. `GET /access-logs/{logId}`.
3. U-T68-VW `GET /access-logs`.
4. U-T01-AU `GET /access-logs/{logId của T68}`.

**Kết quả mong đợi.** Bước 1 `200`, p95 ≤ 3 giây trên khoảng 24 giờ, phân trang đúng. Bước 2 `200` đủ trường. Bước 3 403-PQ (thiếu `PERM-03-log-read`). Bước 4 404-ẩn. Lượt kiểm tra tổng hợp có đánh dấu `synthetic = true`.
:::

#### TC-03-086 · Khoảng truy vấn quá giới hạn, PH-13 lỗi, bộ lọc sai <!--k:log-range-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-051 · API-03-074 · UI-03-09 · ERR-03-021, 026, 003 · NFR-00-062.

**Tiền điều kiện, dữ liệu.** U-T68-AU; `SIM-PH13`.

**Các bước.**

1. Truy vấn khoảng 32 ngày; khoảng bắt đầu cách đây 13 tháng.
2. Truy vấn đúng 31 ngày trong 12 tháng.
3. `status=abc`; `from` sau `to`.
4. Ngắt `SIM-PH13`; truy vấn.

**Kết quả mong đợi.** Bước 1 `400` ERR-03-021 "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất." Bước 2 `200`. Bước 3 `400` ERR-03-003. Bước 4 `503` ERR-03-026 kèm `retryAfterSeconds`.
:::

#### TC-03-087 · Xuất nhật ký bất đồng bộ, giới hạn dòng, không lộ mồi <!--k:log-export-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-051 · API-03-076 · UI-03-09 · UC-03-26 · ERR-03-021, 022, 003 · BR-03-007, 028 · NFR-00-062.

**Tiền điều kiện, dữ liệu.** U-T68-AU; dữ liệu `CANARY` của ca che dữ liệu; U-T68-VW.

**Các bước.**

1. `POST /access-logs:export` với bộ lọc hợp lệ, `Idempotency-Key`.
2. Tải tệp xuất khi xong.
3. Xuất vượt số dòng tối đa.
4. U-T68-VW xuất.

**Kết quả mong đợi.** Bước 1 `202` kèm đường dẫn theo dõi. Bước 2 tệp chỉ chứa tenant T68, đúng cột, mồi sạch. Bước 3 `400` ERR-03-021. Bước 4 403-PQ. KT: có (`ACCESS_LOG_EXPORT`, ghi bộ lọc và số dòng).
:::

### TS-03-21 · Chỉ số, vết, kiểm tra tổng hợp, cảnh báo an ninh và bảng điều khiển

**Mục tiêu.** Xác nhận gateway phát chỉ số và vết OpenTelemetry đủ dùng, bảng điều khiển phản ánh đúng trong 15 giây, kiểm tra tổng hợp không làm sai số liệu thật và sự kiện an ninh sinh cảnh báo.

**Phủ.** FR-03-052, 053, 054, 055; UC-03-18, 27, 28, 08; API-03-077…085; UI-03-01, 07; ERR-03-001, 003, 019, 022, 026; EVT-03-09; BR-03-007, 027, 028; NFR-03-020, 021; SEC-61, 63, 64.

#### TC-03-088 · Chỉ số và vết OpenTelemetry, lấy mẫu, không nhãn nhạy cảm <!--k:otel-metrics-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** IT, GW.

**Truy vết.** FR-03-052 · API-03-077 · UI-03-01 · BR-03-007, 023 · NFR-03-020, 021 · NFR-00-050, 051 · SEC-43.

**Tiền điều kiện, dữ liệu.** Tải hỗn hợp 100 lượt/giây trong 10 phút, 5 % lỗi; `CANARY`.

**Các bước.**

1. Đọc chỉ số `dh_gateway_requests_total`, `dh_gateway_added_latency_seconds`.
2. Đếm vết thành công và vết lỗi.
3. Quét nhãn chỉ số và thuộc tính vết.

**Kết quả mong đợi.** Bước 1 chỉ số đủ nhãn `tenant`, `route`, `status_class`, tới Grafana ≤ 15 giây. Bước 2 giữ 100 % vết lỗi và ≈ 5 % vết thành công. Bước 3 không nhãn hay thuộc tính chứa giá trị thân, tiêu đề xác thực, định danh cá nhân; nhãn có số giá trị hữu hạn.
:::

#### TC-03-089 · Bảng điều khiển lưu lượng, top HTTT và top route <!--k:overview-dashboard-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-03-055 · API-03-077, 078, 079 · UI-03-01 · UC-03-27 · ERR-03-026 · BR-03-028 · NFR-03-021 · LGC-APIM-026.

**Tiền điều kiện, dữ liệu.** T68 và T01 chạy tải khác nhau; U-T68-VW; `SIM-PH13`.

**Các bước.**

1. `GET /overview`; `GET /overview/top-consumers`; `GET /overview/top-routes`.
2. Đối chiếu tổng với số lượt gọi của bộ tạo tải.
3. Ngắt `SIM-PH13`; lặp bước 1.

**Kết quả mong đợi.** Bước 1 `200`; chỉ có consumer và route của T68, không có số liệu T01. Bước 2 sai lệch ≤ 1 %. Bước 3 `503` ERR-03-026; UI-03-01 hiện trạng thái lỗi từng thẻ và nút "Thử lại", không trắng trang.
:::

#### TC-03-090 · Kiểm tra tổng hợp cho API quan trọng <!--k:synthetic-check-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, GW.

**Truy vết.** FR-03-053 · API-03-080, 081, 082, 083 · UI-03-01 · UC-03-28 · ERR-03-001, 003, 022 · BR-03-027, 028.

**Tiền điều kiện, dữ liệu.** U-T68-TA; route đích có hạn mức 20 lượt/giây; U-T68-VW.

**Các bước.**

1. `POST /synthetic-checks` `{route, intervalSeconds: 60, expectStatus: 200}` kèm `Idempotency-Key`.
2. Chờ 5 phút; xem báo cáo sử dụng và bộ đếm hạn mức của HTTT.
3. `PUT /synthetic-checks/{id}` đổi chu kỳ; `DELETE`.
4. Tạo với route lạ; `intervalSeconds = 1`; VW tạo.
5. Làm backend lỗi; chờ kiểm tra tiếp.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 lượt kiểm tra có `synthetic = true`, bị loại khỏi báo cáo, không tăng bộ đếm hạn mức của HTTT thật. Bước 3 `200`, `204`. Bước 4 404-ẩn, `400` ERR-03-003, 403-PQ. Bước 5 có cảnh báo `synthetic-failed` ≤ 3 phút; `GET /synthetic-checks` hiện `lastResult`.
:::

#### TC-03-091 · Cảnh báo sự kiện an ninh và xác nhận xử lý <!--k:security-alert-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** GW, API.

**Truy vết.** FR-03-054 · API-03-084, 085 · UI-03-01, 07 · UC-03-18 · ERR-03-019, 022, 001 · EVT-03-09 · BR-03-007 · SEC-61, 63, 64 · CMP-LAW-16.

**Tiền điều kiện, dữ liệu.** U-T68-TO; U-T68-AU; sự kiện giả lập: WAF chặn hàng loạt, mTLS sai, token chéo tenant, tự chặn IP, Valkey mất.

**Các bước.**

1. Gây từng loại sự kiện.
2. `GET /security-alerts`.
3. TO `POST /security-alerts/{alertId}:acknowledge`; lần hai.
4. AU `POST …:acknowledge`; `GET /security-alerts` bằng U-T01-AU.

**Kết quả mong đợi.** Bước 2 mỗi sự kiện có cảnh báo đúng mức (Nghiêm trọng, Cao, Trung bình), `traceId`, không chứa dữ liệu nhạy cảm; EVT: `security.alert-raised`. Bước 3 `200` rồi `409` ERR-03-019. Bước 4 403-PQ; T01 không thấy cảnh báo của T68. KT: có (`ALERT_ACK`).
:::

### TS-03-22 · Tham số gateway theo tenant và báo cáo sử dụng

**Mục tiêu.** Xác nhận quản trị tenant chỉnh được tham số vận hành trong trần nền tảng (tham số rủi ro cao đi theo bốn mắt), và báo cáo sử dụng đúng, không dùng để tính tiền.

**Phủ.** FR-03-056, 058; UC-03-29, 27; API-03-086, 087, 089, 090; UI-03-16, 01; ERR-03-003, 018, 004, 021, 026, 022; EVT-03-11; BR-03-016, 019, 020, 028.

#### TC-03-092 · Đổi tham số trong miền và trần, đặt lại mặc định <!--k:settings-update-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-056 · API-03-086, 087 · UI-03-16 · UC-03-29 · EVT-03-11 · BR-03-016 · NFR-00-052.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `gw.ip.apiReqPerSecond = 200` mặc định.

**Các bước.**

1. `GET /settings`.
2. `PUT /settings` `{gw.ip.apiReqPerSecond: 400, gw.jwks.refreshMinutes: 5}` kèm `If-Match`.
3. Gửi 300 lượt/giây từ một IP sau khi hiệu lực.
4. Đặt lại `gw.ip.apiReqPerSecond` về mặc định.

**Kết quả mong đợi.** Bước 1 `200` kèm mặc định, miền, trần, người sửa gần nhất, `ETag`. Bước 2 `200` hoặc `202`; ảnh chụp mới; hiệu lực ≤ 60 s (thường < 10 s). Bước 3 không bị `429` mã 119. Bước 4 giá trị về 200. KT: có (`SETTINGS_UPDATE`, giá trị trước, sau); EVT: `limit.changed` khi đổi tham số hạn mức.
:::

#### TC-03-093 · Tham số sai miền, vượt trần, ETag cũ, tham số rủi ro cao <!--k:settings-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-056 · API-03-087 · UI-03-16 · ERR-03-003, 018, 004, 022 · BR-03-019.

**Tiền điều kiện, dữ liệu.** U-T68-TA; U-T68-VW; trần nền tảng `gw.ip.maxConnections = 1.000`.

**Các bước.**

1. `PUT` giá trị sai kiểu (`"abc"`), dưới tối thiểu (`gw.ip.maxConnections = 5`).
2. `gw.ip.maxConnections = 2.000`.
3. `If-Match` cũ.
4. Đổi `gw.waf.mode`, `gw.tenantRateLimit.perSecond` qua `/settings`.
5. U-T68-VW `PUT`.

**Kết quả mong đợi.** Bước 1 `400` ERR-03-003 "Giá trị của {khóa} phải thuộc {miền}." Bước 2 `422` ERR-03-018 "gw.ip.maxConnections không được vượt 1.000 theo hợp đồng của tỉnh." Bước 3 `412` ERR-03-004. Bước 4 `400` ERR-03-003 (phải đi qua chức năng bốn mắt). Bước 5 403-PQ.
:::

#### TC-03-094 · Báo cáo sử dụng API theo HTTT, route, gói; xuất <!--k:usage-report-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-058 · API-03-089, 090 · UI-03-01 · UC-03-27 · ERR-03-021, 026, 022, 003 · BR-03-020, 028 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** U-T68-TA; dữ liệu 31 ngày; lượt kiểm tra tổng hợp; U-T68-VW; `SIM-PH13`.

**Các bước.**

1. `GET /reports/usage?groupBy=consumer&from&to`; đổi `groupBy=route`, `plan`.
2. `POST /reports/usage:export`.
3. Khoảng 32 ngày; `groupBy=xyz`.
4. Ngắt `SIM-PH13`.
5. U-T68-VW `POST …:export`.

**Kết quả mong đợi.** Bước 1 `200`, tổng khớp bộ tạo tải ≤ 1 %, loại lượt `synthetic`, không có trường tiền, giá hay hóa đơn (BR-03-020), chỉ có dữ liệu T68. Bước 2 `202`. Bước 3 `400` ERR-03-021, `400` ERR-03-003. Bước 4 `503` ERR-03-026. Bước 5 403-PQ (xuất cần `PERM-03-log-read`).
:::

### TS-03-23 · Nhập cấu hình từ gateway cũ

**Mục tiêu.** Xác nhận cán bộ chuyển được cấu hình API Management cũ (plan Secure, rate limit, quota, whitelist/blacklist đường dẫn, plan Policies, Application) sang cấu hình nháp của PH-03 mà không mất mục nào và không mang theo bí mật.

**Phủ.** FR-03-059; UC-03-31; API-03-091…093; UI-03-18; ERR-03-020, 003, 019, 001, 022; BR-03-014, 029; LGC-APIM-002…005, 009…015, 019…021.

#### TC-03-095 · Nhập gói cấu hình Gravitee: phân tích và áp thành nháp <!--k:legacy-import-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-059 · API-03-091, 092, 093 · UI-03-18 · UC-03-31 · BR-03-014, 029 · LGC-APIM-002…005, 009…015, 019…021.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `F-LEGACY-OK` gồm 12 API, 20 plan, 15 Application có khóa API đã làm sạch.

**Các bước.**

1. `POST /migrations/legacy-gateway:import` tải tệp, `Idempotency-Key`.
2. `GET /migrations/legacy-gateway/{importId}` đến khi `DONE`.
3. `POST …/{importId}:apply`.
4. `GET /routes`, `GET /plan-policies`; `POST /snapshots:validate`.

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 báo cáo từng mục: plan Keyless hoặc API key, rate limit, quota, whitelist, blacklist, plan Policies đều có đề xuất tương đương; mục không map được nêu lý do. Bước 3 `200`, tạo route và chính sách ở trạng thái nháp, **không tự phát hành**; không có khóa API cũ nào được chép. Bước 4 đối tượng nháp có mặt; `validate` nêu việc còn phải làm (lược đồ, OPA). KT: có (`LEGACY_IMPORT`, `LEGACY_APPLY`).
:::

#### TC-03-096 · Gói cũ hỏng, thiếu trường, bị bộ quét từ chối; áp lần hai <!--k:legacy-import-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-03-059 · API-03-091, 092, 093 · ERR-03-020, 003, 019, 001, 022 · BR-03-014.

**Tiền điều kiện, dữ liệu.** `F-LEGACY-BAD`; tệp chứa mã thực thi; tệp 100 MiB; U-T68-VW.

**Các bước.**

1. Nhập `F-LEGACY-BAD` rồi xem kết quả.
2. Nhập tệp có mã thực thi và tệp quá cỡ.
3. `:apply` hai lần cùng `importId`; `:apply` mã lạ.
4. Thiếu tệp; U-T68-VW nhập.

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-03-020 "Gói cấu hình hệ cũ không đọc được: {lý do}." kèm `errors[]`. Bước 3 lần hai `409` ERR-03-019; mã lạ 404-ẩn. Bước 4 `400` ERR-03-003; 403-PQ. Không đối tượng nào được tạo.
:::

### TS-03-24 · Duyệt thay đổi gateway bốn mắt (xuyên suốt)

**Mục tiêu.** Xác nhận cả bốn thay đổi rủi ro cao ở PH-03 đều đi qua hàng đợi duyệt, người đề nghị không tự duyệt được, và quyết định đã chốt không đổi lại.

**Phủ.** FR-03-006, 007, 023, 038; UC-03-13, 16, 25; API-03-071…073; UI-03-17; ERR-03-008, 022, 019, 001; BR-03-006, 019.

#### TC-03-097 · Hàng đợi duyệt: xem, duyệt, từ chối cho bốn loại thay đổi <!--k:cr-list-approve-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-03-006, 023, 038 · API-03-071, 072, 073 · UI-03-17 · UC-03-13, 16, 25 · BR-03-019.

**Tiền điều kiện, dữ liệu.** Bốn yêu cầu chờ duyệt: đổi chế độ WAF, mở route `EXT`, hạ hạn mức tenant, (ngoại lệ WAF qua API riêng); U-T68-TA, U-T68-TA2, U-T68-SO1, U-T68-SO2.

**Các bước.**

1. `GET /change-requests?state=PENDING`.
2. Người thứ hai duyệt hai yêu cầu bằng `:approve`.
3. Người thứ hai từ chối yêu cầu còn lại bằng `:reject` kèm lý do.
4. `GET /change-requests/{id}`.

**Kết quả mong đợi.** Bước 1 `200`, mỗi yêu cầu có loại, người đề nghị, lý do, thay đổi trước và sau. Bước 2 áp dụng đúng thay đổi, ảnh chụp mới hiệu lực ≤ 60 s. Bước 3 yêu cầu `REJECTED`, thay đổi không áp. KT: có cho từng quyết định.
:::

#### TC-03-098 · Tự duyệt, sai vai trò, quyết định lần hai, tenant khác <!--k:cr-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-006, 023, 038 · API-03-072, 073 · UI-03-17 · ERR-03-008, 022, 019, 001 · BR-03-019.

**Tiền điều kiện, dữ liệu.** U-T68-SO-VD (vừa đề nghị vừa có quyền duyệt); U-T68-TO; U-T01-TA.

**Các bước.**

1. SO-VD đề nghị rồi `:approve`, và `:reject` yêu cầu của chính mình.
2. TO `:approve`.
3. Duyệt yêu cầu đã duyệt.
4. U-T01-TA duyệt yêu cầu của T68.

**Kết quả mong đợi.** Bước 1 `403` ERR-03-008 "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." (cả duyệt lẫn từ chối). Bước 2 403-PQ. Bước 3 `409` ERR-03-019. Bước 4 404-ẩn. Thay đổi không áp.
:::

### TS-03-25 · Giao diện quản trị cổng API (E2E)

**Mục tiêu.** Xác nhận 18 màn UI-03-01…18 hoạt động đúng chức năng, quyền, trạng thái chuẩn (đang tải, rỗng, lỗi) và quy ước đường dẫn, truy vấn của giao diện.

**Phủ.** UI-03-01…18; FR-03-051, 055, 056; UC-03-27; NFR-03-027; PTN-01, 02, 04, 05, 06, 10, 11, 12.

#### TC-03-099 · Tổng quan, danh sách và chi tiết route (UI-03-01, 02, 03) <!--k:ui-overview-routes-->

::: dac-ta
**Loại.** Dương, Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** UI-03-01, 02, 03 · FR-03-055, 028, 036 · API-03-077, 001, 002, 003 · UC-03-27, 09.

**Tiền điều kiện, dữ liệu.** U-T68-TO; 1.000 route; U-T68-VW.

**Các bước.**

1. Mở UI-03-01; đổi khoảng thời gian.
2. Mở UI-03-02 với `?trang=2&co=20&sap-xep=ten:tang&q=ho-tich`.
3. Mở UI-03-03 của `r-ho-tich`; bấm "Dừng"; xác nhận; bấm "Mở".
4. Đăng nhập U-T68-VW mở lại UI-03-03.

**Kết quả mong đợi.** Bước 1 biểu đồ lưu lượng, lỗi, độ trễ, thẻ cảnh báo; trạng thái đang tải, rỗng, lỗi đủ. Bước 2 danh sách đúng 20 dòng, URL phản ánh bộ lọc. Bước 3 thao tác thành công, banner trạng thái đổi. Bước 4 nút "Dừng", "Mở" bị ẩn hoặc vô hiệu kèm lý do.
:::

#### TC-03-100 · Consumer, hạn mức và hạn ngạch (UI-03-04, 05, 06) <!--k:ui-consumers-limits-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-03-04, 05, 06 · FR-03-046, 047, 022, 023, 024 · API-03-011, 012, 017, 018, 029, 024, 026 · UC-03-23, 25.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; U-T68-TA; `ht-mini` ở 85 % hạn ngạch.

**Các bước.**

1. Mở UI-03-04 lọc theo nhóm `ESSENTIAL`.
2. Mở UI-03-05 của `ht-ndxp`; bấm "Tạm ngừng khẩn cấp" rồi "Mở lại".
3. Mở UI-03-06; sửa hạn mức toàn tenant; thêm ghi đè theo route.

**Kết quả mong đợi.** Bước 2 hộp xác nhận có ô lý do bắt buộc; thông báo thành công và trạng thái đổi. Bước 3 thanh mức dùng đổi màu theo ngưỡng 80 % và 100 % (kèm chữ, không chỉ màu); hạ hạn mức toàn tenant hiện "Đã gửi yêu cầu, chờ người duyệt".
:::

#### TC-03-101 · Nhật ký WAF, ngoại lệ, duyệt thay đổi (UI-03-07, 08, 17) <!--k:ui-waf-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** UI-03-07, 08, 17 · FR-03-005, 006, 007, 008 · API-03-039, 041, 042, 043, 044, 071, 072 · UC-03-13, 14, 15.

**Tiền điều kiện, dữ liệu.** U-T68-TO; U-T68-SO1; U-T68-SO2.

**Các bước.**

1. TO mở UI-03-07, chọn một sự kiện bị chặn nhầm, bấm "Đề nghị ngoại lệ".
2. SO1 mở UI-03-17 duyệt.
3. SO1 đề nghị đổi chế độ WAF; SO1 thử duyệt chính mình.
4. SO2 duyệt.

**Kết quả mong đợi.** Bước 1 mở biểu mẫu điền sẵn route, mã luật; ngoại lệ ở UI-03-08 trạng thái "Chờ duyệt" rồi "Hiệu lực". Bước 3 nút "Duyệt" vô hiệu kèm "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." Bước 4 chế độ đổi sau duyệt.
:::

#### TC-03-102 · Nhật ký lượt gọi và nút gateway (UI-03-09, 11) <!--k:ui-logs-nodes-->

::: dac-ta
**Loại.** Dương, Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-03-09, 11 · FR-03-051, 045 · API-03-074, 075, 076, 063, 064 · UC-03-26, 22.

**Tiền điều kiện, dữ liệu.** U-T68-AU; U-T68-TO.

**Các bước.**

1. AU mở UI-03-09, lọc theo `traceId`; mở chi tiết; bấm "Xuất".
2. TO mở UI-03-11; mở một nút.

**Kết quả mong đợi.** Bước 1 danh sách, chi tiết, tiến trình xuất; không hiển thị thân hay giá trị tiêu đề. Bước 2 bảng nút có phiên bản, trạng thái đồng bộ, màu kèm nhãn chữ.
:::

#### TC-03-103 · Ảnh chụp, chứng thư, mẫu chính sách, chạy thử (UI-03-10, 12, 13, 14) <!--k:ui-snapshots-certs-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-03-10, 12, 13, 14 · FR-03-039…044, 049, 048, 057 · API-03-056, 059, 060, 061, 062, 068, 070, 065, 067, 088 · UC-03-19, 21, 24, 17.

**Tiền điều kiện, dữ liệu.** U-T68-TA; U-T68-TO; U-PA.

**Các bước.**

1. TA mở UI-03-10: "Tổng hợp và ký", xem diff, "Phát".
2. TO quay lui về bản trước.
3. PA mở UI-03-12 gia hạn chứng thư; TA mở UI-03-13 bật mẫu; mở UI-03-14 chạy thử.

**Kết quả mong đợi.** Bước 1 lỗi kiểm tra hiển thị theo `findings[]` với từng đối tượng bấm nhảy tới được. Bước 2 ảnh chụp mới xuất hiện ở danh sách. Bước 3 kết quả mô phỏng hiện từng chốt. Mọi bảng có chú thích và điều hướng bàn phím.
:::

#### TC-03-104 · Địa chỉ bị chặn, tham số, chuyển tiếp tenant, nhập hệ cũ (UI-03-15, 16, 18) <!--k:ui-ip-settings-import-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-03-15, 16, 18 · FR-03-003, 004, 056, 037, 059 · API-03-036, 037, 038, 086, 087, 095, 091, 092, 093 · UC-03-12, 29, 30, 31.

**Tiền điều kiện, dữ liệu.** U-T68-SO1; U-T68-TA; U-PA; `F-LEGACY-OK`.

**Các bước.**

1. SO1 mở UI-03-15, chặn một địa chỉ, bỏ chặn.
2. TA mở UI-03-16 sửa tham số; PA tạo chuyển tiếp tenant.
3. TA chạy trình hướng dẫn UI-03-18 với `F-LEGACY-OK`.

**Kết quả mong đợi.** Bước 1 danh sách cập nhật, hộp xác nhận. Bước 2 giá trị ngoài miền báo lỗi theo trường. Bước 3 wizard qua các bước tải lên, xem trước, áp dụng; kết thúc ở màn đối tượng nháp.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Bảy kịch bản dưới đây kiểm các tính chất không gắn với một FR đơn lẻ: không lộ dữ liệu, cách ly tenant, phân quyền, hiệu năng, chịu lỗi, tăng cứng và truy cập. Ba nhóm đầu (TS-03-26…28) bắt buộc đạt 100 % trước khi phát hành.

### TS-03-26 · Không lộ dữ liệu, thông tin máy chủ và không có đường tắt tới backend

**Mục tiêu.** Chứng minh BR-03-001, 007, 013, 023: mọi lượt gọi đều qua gateway, mọi lỗi do gateway sinh theo RFC 9457 không lộ nội bộ, và không nơi nào ngoài siêu dữ liệu chứa nội dung lượt gọi.

**Phủ.** FR-03-001, 011, 050, 052; UC-03-01, 03; API-03-074; định dạng của mọi ERR-03-1nn; BR-03-001, 007, 013, 023; NFR-03-014, 015, 016; SEC-14, 15, 43.

#### TC-03-105 · Quét mồi `DH-CANARY` toàn hệ thống sau chuỗi lượt gọi hỗn hợp <!--k:canary-sweep-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, GW.

**Truy vết.** FR-03-050, 052 · BR-03-007, 023 · NFR-03-014 · CMP-LAW-05 · SEC-32, 61.

**Tiền điều kiện, dữ liệu.** `CANARY` riêng theo ca đặt ở thân, tiêu đề, tham số, `Cookie`, đường dẫn; 1.000 lượt hỗn hợp thành công, `4xx`, `429`, `5xx`, WAF chặn, mTLS lỗi.

**Các bước.**

1. Chạy chuỗi lượt gọi hỗn hợp.
2. Quét nhật ký APISIX, nhật ký `dh-connect`, vết OTel, chỉ số, ClickHouse, Kafka, bảng `ph03_gateway.*`, tệp xuất, báo cáo.

**Kết quả mong đợi.** 0 lần xuất hiện của mồi ở mọi nơi (mồi sạch); riêng đường dẫn chỉ xuất hiện phần đường dẫn đã chuẩn hóa, không có chuỗi truy vấn.
:::

#### TC-03-106 · Mọi phản hồi lỗi của gateway theo RFC 9457, đủ `code` và `X-Trace-Id` <!--k:error-format-all-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW.

**Truy vết.** FR-03-009, 012, 019, 021, 036 · BR-03-023 · NFR-03-015.

**Tiền điều kiện, dữ liệu.** Bảng 30 tình huống, mỗi tình huống gây đúng một mã `ERR-03-1nn` (tham số hóa theo ca của TS-03-01…19).

**Các bước.**

1. Chạy từng tình huống.
2. Kiểm thân và tiêu đề từng phản hồi lỗi.

**Kết quả mong đợi.** Mỗi phản hồi có `Content-Type: application/problem+json`, các trường `type`, `title`, `status`, `detail`, `code = ERR-03-1nn` đúng mã, `instance`, `traceId`; có `X-Trace-Id`; mã HTTP khớp bảng ERR (kể cả `Retry-After` ở mã 116…120, 123, 124); không có vết ngăn xếp, tên máy, địa chỉ nội bộ, tên plugin hay phiên bản.
:::

#### TC-03-107 · Backend chỉ nhận lưu lượng từ APISIX, không có đường tắt <!--k:no-direct-backend-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** BR-03-001 · FR-03-001 · UC-03-01 · SEC-14, 15.

**Tiền điều kiện, dữ liệu.** `SIM-BE-1` trong namespace `dh-backend`; một pod thử trong namespace khác.

**Các bước.**

1. Từ pod thử gọi trực tiếp `SIM-BE-1` bằng IP pod và bằng Service.
2. Từ ngoài cụm gọi IP nút và cổng NodePort (nếu có).
3. Gọi qua gateway.

**Kết quả mong đợi.** Bước 1, 2 bị chính sách mạng chặn (hết thời gian hoặc bị từ chối kết nối). Bước 3 `200`. Chính sách mạng chỉ cho phép lưu lượng đến backend từ APISIX.
:::

### TS-03-27 · Cách ly tenant ở API, CSDL, bộ đếm và cấu hình

**Mục tiêu.** Chứng minh mọi API đọc trả 404-ẩn cho đối tượng của tenant khác, RLS chặn ở tầng CSDL, bộ đếm hạn mức và khóa bộ đệm tách theo tenant, và ảnh chụp cấu hình của tenant không chứa đối tượng tenant khác.

**Phủ.** FR-03-013, 028, 051, 056; API-03-001, 002, 005, 006, 011, 012, 016, 021, 022, 023, 025, 029, 036, 040, 042, 047, 050, 054, 055, 056, 057, 063, 064, 065, 068, 069, 071, 074, 075, 077, 080, 084, 086, 089, 094; ERR-03-001; BR-03-026, 028; NFR-03-019; SEC-80, 86, 87.

#### TC-03-108 · Rò rỉ chéo tenant cho mọi API đọc: 404-ẩn <!--k:xtenant-api-read-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-028, 046, 051 · API-03-002, 006, 012, 016, 022, 057, 064, 066, 069, 075, 082 · ERR-03-001 · BR-03-026, 028 · NFR-03-019 · SEC-87.

**Tiền điều kiện, dữ liệu.** Đối tượng chỉ có ở T01 cho mỗi loại (route, upstream, consumer, chính sách, ảnh chụp, nút, mẫu, chứng thư, nhật ký, kiểm tra tổng hợp, cảnh báo, chuyển tiếp, ghi đè hạn mức); U-T68-TA, U-T68-AU.

**Các bước.**

1. Với từng API đọc theo mã (`GET …/{mã}`), U-T68-TA gọi bằng mã đối tượng của T01.
2. Gọi bằng mã không tồn tại.
3. Với từng API danh sách, tìm theo mã của T01.
4. Lặp bước 1 cho `PUT`, `DELETE`, `POST …:{động từ}` có mã trong đường dẫn.

**Kết quả mong đợi.** Bước 1 và 2 cùng `404` ERR-03-001, thân giống hệt trừ `traceId`, thời gian phản hồi khác nhau không quá 20 %. Bước 3 danh sách không chứa đối tượng T01, tổng số không lộ. Bước 4 cũng 404-ẩn và không đổi dữ liệu của T01.
:::

#### TC-03-109 · RLS chặn đọc, ghi chéo tenant ở CSDL <!--k:rls-isolation-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** BR-03-026, 028 · NFR-03-019 · SEC-80, 87 · ADR-003.

**Tiền điều kiện, dữ liệu.** Vai trò ứng dụng với `SET app.tenant_id = 'T68'`; bản ghi `T01` ở mọi bảng `ph03_gateway.*`.

**Các bước.**

1. `SELECT` không điều kiện từ từng bảng.
2. `INSERT`, `UPDATE`, `DELETE` bản ghi có `tenant_id = 'T01'`.
3. Không đặt `app.tenant_id` rồi `SELECT`.
4. Thử sửa, xóa bảng nhật ký kiểm toán và bảng ảnh chụp đã phát.

**Kết quả mong đợi.** Bước 1 chỉ thấy dòng T68. Bước 2 vi phạm chính sách RLS (0 dòng bị đổi hoặc lỗi). Bước 3 0 dòng. Bước 4 bị chặn (append-only).
:::

#### TC-03-110 · Bộ đếm hạn mức, danh sách chặn, khóa bộ đệm tách theo tenant <!--k:counter-isolation-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GW, IT.

**Truy vết.** FR-03-021, 018, 013 · API-03-029, 054 · ERR-03-116, 105 · BR-03-005, 026 · NFR-03-019 · SEC-86.

**Tiền điều kiện, dữ liệu.** Hai client trùng `clientId` `ht-ndxp` ở T68 và T01; thu hồi `jti` giống nhau ở T01.

**Các bước.**

1. Làm client T01 hết hạn mức; gọi bằng client T68.
2. Thu hồi một `jti` ở T01; gọi bằng token T68 có `jti` trùng.
3. Kiểm khóa Valkey.

**Kết quả mong đợi.** Bước 1, 2 client T68 không bị ảnh hưởng. Bước 3 mọi khóa có tiền tố tenant; không khóa nào dùng chung hai tenant.
:::

#### TC-03-111 · Ảnh chụp cấu hình của tenant không chứa đối tượng tenant khác <!--k:snapshot-isolation-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-03-039, 041 · API-03-057 · BR-03-026 · NFR-03-019 · SEC-87.

**Tiền điều kiện, dữ liệu.** T68, T01 đều có route, consumer; ảnh chụp dùng chung cho cụm gateway.

**Các bước.**

1. Build ảnh chụp ở T68; giải nén phần nội dung.
2. Kiểm từng route, consumer, chính sách có `tenant` đúng.
3. Kiểm không có hai route cùng host, đường dẫn khác tenant.

**Kết quả mong đợi.** Mọi đối tượng thuộc đúng tenant ghi trên đối tượng; không có khóa của tenant này trong phạm vi tenant khác; bản kiểm tĩnh BR-03-026 báo 0 xung đột.
:::

### TS-03-28 · Phân quyền, tách nhiệm và kiểm toán

**Mục tiêu.** Chứng minh ma trận `PERM-03-*` ở D02-08 được thực thi đúng ở từng API, dịch vụ gọi dịch vụ dùng scope riêng, bốn mắt độc lập với vai trò và mọi thao tác ghi có kiểm toán đủ trường.

**Phủ.** FR-03-006, 007, 023, 038, 047; API-03-017, 024, 037, 041, 044, 053, 059, 072, 076, 087; ERR-03-022, 008; BR-03-006, 019; SEC-07, 24, 61.

#### TC-03-112 · Ma trận quyền: mọi quyền với từng vai trò <!--k:perm-matrix-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** API-03-003, 008, 024, 037, 041, 043, 044, 059, 061, 072, 074 · ERR-03-022 · FR-03-006, 007, 023, 036, 038, 044 · BR-03-019 · SEC-24.

**Tiền điều kiện, dữ liệu.** Mỗi vai trò PA, PO, TA, TO, SO, AU, VW; mỗi quyền `PERM-03-read`, `admin`, `limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read` có một API đại diện.

**Các bước.**

1. Với mỗi cặp (vai trò, API đại diện) gọi API hợp lệ về dữ liệu.
2. So kết quả với bảng ma trận ở D02-03-PH03 mục 3.2 và D02-08.

**Kết quả mong đợi.** Cặp có quyền (●) nhận `2xx`; cặp không có quyền (—) nhận 403-PQ, không đổi dữ liệu, không lộ sự tồn tại của đối tượng. Bất kỳ sai khác nào là lỗi mức Cao.
:::

#### TC-03-113 · API dịch vụ gọi dịch vụ chỉ nhận đúng scope <!--k:perm-service-scope-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-018, 046 · API-03-013, 014, 015, 053 · ERR-03-022 · SEC-24, 25.

**Tiền điều kiện, dữ liệu.** S-SYNC, S-REVOKE, token người dùng U-T68-TA, token dịch vụ lạ.

**Các bước.**

1. S-SYNC gọi `POST /revocations`; S-REVOKE gọi `PUT /consumers/{mã}`.
2. U-T68-TA (người dùng) gọi hai API trên.
3. Token dịch vụ không có scope gọi cả hai.

**Kết quả mong đợi.** Mọi lần 403-PQ; chỉ đúng cặp (S-SYNC, API consumer) và (S-REVOKE, `/revocations`) thành công.
:::

#### TC-03-114 · Bốn mắt độc lập với vai trò cho bốn loại thay đổi <!--k:perm-4eyes-all-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-03-006, 007, 023, 038 · API-03-044, 072 · ERR-03-008 · BR-03-006, 019 · SEC-07.

**Tiền điều kiện, dữ liệu.** U-T68-SO-VD (SO + TA) đề nghị từng loại: ngoại lệ WAF, đổi chế độ WAF, mở `EXT`, hạ hạn mức tenant.

**Các bước.**

1. SO-VD đề nghị rồi thử duyệt chính yêu cầu bằng vai trò SO, rồi bằng vai trò TA.
2. Người thứ hai duyệt.

**Kết quả mong đợi.** Bước 1 mọi lần `403` ERR-03-008 với cả bốn loại. Bước 2 thay đổi áp dụng. Bản kiểm toán ghi cả hai người và hai thời điểm.
:::

#### TC-03-115 · Kiểm toán đủ trường cho mọi thao tác ghi, không chứa bí mật <!--k:audit-complete-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-03-003, 007, 036, 047, 059 · API-03-003, 017, 033, 037, 043, 087, 093 · BR-03-016, 029 · FR-00-041 · NFR-03-026 · LGC-APIM-027.

**Tiền điều kiện, dữ liệu.** Bộ thao tác ghi mẫu của TS-03-01…24; PH-13 thật.

**Các bước.**

1. Thực hiện từng thao tác ghi một lần.
2. Truy vấn PH-13 theo `traceId`.
3. Quét giá trị mồi trong bản ghi kiểm toán.

**Kết quả mong đợi.** Mỗi thao tác có đúng một bản ghi với `tenant`, người, vai trò, hành động, đối tượng, trước và sau, thời điểm, `traceId`, nguồn; thao tác thất bại do quyền cũng có bản ghi từ chối; mồi sạch; bản ghi tồn tại online 12 tháng và đưa vào WORM theo NFR-03-026.
:::

### TS-03-29 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-03-001…004, 008, 013, 017, 018, 019, 021…023 ở cấu hình QM-VUA với dữ liệu giả định GĐ-01…07 (3 bản sao mỗi cửa, 1.000 route mỗi tenant, 200 consumer).

**Phủ.** NFR-03-001…004, 008, 013, 017, 018, 019, 021…023.

| Mã | Tên | Tải | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-03-116 | Độ trễ thêm tại gateway đủ chuỗi plugin <!--k:perf-latency--> | 300 lượt/giây, đủ chuỗi plugin và WAF, thân ≤ 32 KB, 30 phút | p95 ≤ 50 ms, p99 ≤ 100 ms | NFR-03-001 · FR-03-005, 012, 019, 021 |
| TC-03-117 | Chi phí từng chốt <!--k:perf-chokepoints--> | 1.000 lượt/giây, đo từng plugin | JWT p99 ≤ 2 ms; hạn mức p99 ≤ 3 ms; OPA p99 ≤ 2 ms; WAF ≤ 5 ms (≤ 32 KB) | NFR-03-002 · FR-03-012, 019, 021, 005 |
| TC-03-118 | Thông lượng danh định <!--k:perf-throughput--> | 1.000 lượt/giây trên 3 bản sao 30 phút; thang tới 3.000 | Lỗi do nền tảng < 0,1 %; đạt 3.000 lượt/giây danh định | NFR-03-003 · FR-03-028, 029 |
| TC-03-119 | Kết nối đồng thời <!--k:perf-connections--> | 20.000 kết nối HTTP/2 giữ trên mỗi bản sao | Không từ chối, bộ nhớ ổn định | NFR-03-004 · FR-03-033 |
| TC-03-120 | Nạp cấu hình dưới tải <!--k:perf-config-load--> | 2.000 lượt/giây, phát 20 ảnh chụp liên tiếp | 0 lượt lỗi; lan truyền ≤ 10 s, ≤ 60 s theo yêu cầu hệ thống | NFR-03-008 · FR-03-042, 043 |
| TC-03-121 | Chống tràn tầng 7 <!--k:perf-flood--> | Gấp 3 lần cao điểm (900 lượt/giây), rồi đột biến gấp 10 lần trong 30 giây từ 50 địa chỉ | Data plane không suy giảm; nguồn tấn công bị chặn ≤ 60 giây | NFR-03-013 · FR-03-003, 004 |
| TC-03-122 | Số route và độ trễ so khớp <!--k:perf-routes--> | 1.000 route mỗi tenant; thang tới 70.000 route nền tảng (QM-CHUNG) | Độ trễ so khớp tăng ≤ 10 % so với 100 route | NFR-03-017 · FR-03-028 |
| TC-03-123 | Mở rộng tự động <!--k:perf-hpa--> | Tăng tải dần từ 300 tới 3.000 lượt/giây | HPA CPU 60 %, 3 đến 10 bản sao; gấp đôi tài nguyên ≥ 1,8 lần thông lượng | NFR-03-018 · FR-03-028 |
| TC-03-124 | Cách ly hạn mức giữa hai tenant <!--k:perf-tenant-isolation--> | T68 tải 800 lượt/giây vượt hạn mức, T01 tải nền 100 lượt/giây | p95 của T01 tăng ≤ 10 %, 0 lượt T01 đọc dữ liệu T68 | NFR-03-019 · FR-03-023 |
| TC-03-125 | Độ trễ số liệu tới bảng điều khiển <!--k:perf-dashboard-->  | Sự kiện đánh dấu mỗi phút trong 1 giờ | Chỉ số tới biểu đồ ≤ 15 giây | NFR-03-021 · FR-03-055 |
| TC-03-126 | Truy vấn nhật ký lượt gọi <!--k:perf-log-query--> | ClickHouse 5 triệu bản ghi/ngày/tenant, 31 ngày; 20 truy vấn đồng thời | p95 ≤ 3 giây | NFR-03-022 · FR-03-051 |
| TC-03-127 | API quản trị <!--k:perf-admin-api--> | 1.000 route, 200 consumer mỗi tenant; 50 người dùng đồng thời, 30 phút | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-03-023 · FR-03-028, 046 |

: TS-03-29 · Hiệu năng, tải và quy mô

### TS-03-30 · Chịu lỗi và phục hồi

**Mục tiêu.** Chứng minh gateway là điểm vào duy nhất vẫn chịu được mất một vùng, nâng cấp cuốn chiếu, tắt an toàn và đạt sẵn sàng ≥ 99,95 % theo kiểm tra tổng hợp.

**Phủ.** FR-03-026, 043, 053; UC-03-08, 20; API-03-063, 077, 080; BR-03-010, 025; NFR-03-005, 006, 007, 024.

#### TC-03-128 · Mất một vùng sẵn sàng <!--k:lose-zone-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-03-043, 029 · API-03-063, 077 · UI-03-01, 11 · NFR-03-006, 005 · BR-03-010.

**Tiền điều kiện, dữ liệu.** Mỗi cửa 3 bản sao trải 2 vùng; tải 300 lượt/giây.

**Các bước.**

1. Chaos Mesh tắt toàn bộ nút của một vùng 10 phút.
2. Theo dõi độ trễ, lỗi, `GET /nodes`.
3. Khôi phục vùng.

**Kết quả mong đợi.** Độ trễ p95 tăng ≤ 50 %, không mất cấu hình, tỉ lệ lỗi do nền tảng < 0,1 % sau khi cân bằng lại; số bản sao còn lại ≥ 1 mỗi cửa; vùng trở lại tự nhận đúng phiên bản cấu hình.
:::

#### TC-03-129 · Nâng cấp cuốn chiếu và tắt an toàn dưới tải <!--k:rolling-upgrade-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos, k6.

**Truy vết.** FR-03-043 · API-03-063 · NFR-03-024 · NFR-00-013 · BR-03-010.

**Tiền điều kiện, dữ liệu.** Tải 1.000 lượt/giây và 500 kết nối dài; `maxUnavailable: 1`.

**Các bước.**

1. Nâng cấp phiên bản ảnh APISIX cuốn chiếu.
2. Gửi tín hiệu tắt cho một pod khi có yêu cầu dài 20 giây đang xử lý.

**Kết quả mong đợi.** 0 lượt gọi lỗi do nâng cấp; yêu cầu đang xử lý hoàn tất trong ≤ 30 giây khi tắt; kết nối mới không vào pod đang tắt.
:::

#### TC-03-130 · Sẵn sàng đo bằng kiểm tra tổng hợp suốt 24 giờ <!--k:availability-synthetic-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** FR-03-053 · API-03-080, 077 · NFR-03-005 · UI-03-01.

**Tiền điều kiện, dữ liệu.** Kiểm tra tổng hợp mỗi phút trên 5 route quan trọng; chạy kịch bản lỗi nhẹ định kỳ (xóa một pod mỗi giờ).

**Các bước.**

1. Chạy 24 giờ.
2. Tính tỉ lệ kiểm tra thành công.

**Kết quả mong đợi.** Sẵn sàng ≥ 99,95 % quy đổi tháng (ngoại suy từ cửa sổ 24 giờ); mọi lần thất bại có cảnh báo `synthetic-failed`.
:::

### TS-03-31 · Tăng cứng, TLS, WAF và quét bảo mật

**Mục tiêu.** Chứng minh thành phần gateway được tăng cứng và WAF chặn bộ payload OWASP ở mức hoang tưởng cấu hình, API quản trị đạt ASVS 5.0 mức 2.

**Phủ.** FR-03-001, 005, 011; API-03-031, 039; ERR-03-109; NFR-03-010, 012, 016; SEC-11, 12, 52, 55, 56, 57.

#### TC-03-131 · Tăng cứng container, ký ảnh, quét lỗ hổng <!--k:hardening-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** NFR-03-016 · FR-03-011 · SEC-52, 55, 56, 57.

**Tiền điều kiện, dữ liệu.** Ảnh APISIX và `dh-connect` bản phát hành.

**Các bước.**

1. Kiểm `securityContext`, hệ thống tệp, nơi lưu khóa riêng (OpenBao hoặc Secret tmpfs).
2. Xác minh chữ ký `cosign` của ảnh APISIX và plugin.
3. Chạy Trivy và Semgrep.

**Kết quả mong đợi.** Không chạy root, hệ thống tệp gốc chỉ đọc; khóa riêng không nằm trong ảnh hay biến môi trường; chữ ký hợp lệ; Trivy 0 CRITICAL.
:::

#### TC-03-132 · Hiệu quả WAF với bộ payload OWASP và tỉ lệ chặn nhầm <!--k:waf-effectiveness-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP, GW.

**Truy vết.** FR-03-005 · API-03-039 · ERR-03-109 · NFR-03-012 · SEC-11.

**Tiền điều kiện, dữ liệu.** `SIM-ATTACK` bộ 2.000 payload OWASP; 100.000 yêu cầu hợp lệ lấy từ trace giả lập GĐ; `gw.waf.mode = BLOCK`, mức hoang tưởng theo cấu hình.

**Các bước.**

1. Gửi toàn bộ payload.
2. Gửi 100.000 yêu cầu hợp lệ.

**Kết quả mong đợi.** ≥ 99 % payload bị chặn (giả định, chốt khi có dữ liệu thật, Q03-40); chặn nhầm < 0,1 % lượt hợp lệ.
:::

#### TC-03-133 · Quét API quản trị theo ASVS 5.0 mức 2 và kiểm tra lại TLS <!--k:zap-admin-api-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** ZAP.

**Truy vết.** API-03-001, 024, 059, 087 · FR-03-001 · NFR-03-010 · SEC-43, 44.

**Tiền điều kiện, dữ liệu.** OpenAPI của `/api/gateway/v1`; U-T68-TA.

**Các bước.**

1. Chạy ZAP quét chủ động trên OpenAPI.
2. Chạy `testssl.sh` sau khi đổi hồ sơ TLS.

**Kết quả mong đợi.** 0 phát hiện mức Cao hoặc Nghiêm trọng; TLS điểm A+; không lỗi injection, IDOR, thiếu kiểm tra quyền.
:::

### TS-03-32 · Truy cập giao diện, IPv6 và lưu giữ

**Mục tiêu.** Chứng minh giao diện UI-03-* đạt WCAG 2.2 AA, hai cửa vào chạy ngăn xếp kép IPv4 và IPv6 theo Công văn 631, và dữ liệu lưu giữ đúng thời hạn.

**Phủ.** UI-03-01…18; FR-03-001, 050; NFR-03-025, 026, 027; CMP-LAW-09.

#### TC-03-134 · Quét truy cập tự động toàn bộ màn UI-03 <!--k:a11y-auto-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-03-01…18 · NFR-03-027 · NFR-00-040…045.

**Tiền điều kiện, dữ liệu.** `axe-core` trong Playwright; dữ liệu mẫu đủ để mọi màn có nội dung, trạng thái rỗng và lỗi.

**Các bước.**

1. Mở từng màn UI-03-01…18 ở các trạng thái chuẩn.
2. Chạy `axe-core` ở giao diện sáng và tối, thu phóng 200 %.

**Kết quả mong đợi.** 0 vi phạm mức nghiêm trọng, đáng kể ở WCAG 2.2 AA; tương phản đạt; không dùng màu làm tín hiệu duy nhất (trạng thái, mức dùng hạn mức luôn có chữ).
:::

#### TC-03-135 · Hai cửa vào hoạt động qua IPv6 <!--k:ipv6-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** GW.

**Truy vết.** FR-03-001, 028 · NFR-03-025 · CMP-LAW-09 · UC-03-05.

**Tiền điều kiện, dữ liệu.** Hai cửa có địa chỉ AAAA; máy thử IPv6.

**Các bước.**

1. `curl -6` tới `ext.t68.sim.test`, `int.t68.sim.test` bằng token hợp lệ.
2. Gửi tải 100 lượt/giây qua IPv6 từ một địa chỉ vượt `gw.ip.apiReqPerSecond`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 giới hạn theo địa chỉ IPv6 (nhóm `/64` theo cấu hình) cho `429` Lỗi GW 119; nhật ký ghi đúng `srcIp` IPv6.
:::

#### TC-03-136 · Lưu giữ nhật ký theo thời hạn <!--k:retention-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-03-050, 051 · API-03-074 · ERR-03-021 · NFR-03-026 · NFR-00-028.

**Tiền điều kiện, dữ liệu.** Dữ liệu giả lập tuổi 89, 91 ngày (vận hành), 11, 13 tháng (siêu dữ liệu lượt gọi, nhật ký an ninh); `faketime`.

**Các bước.**

1. Chạy tác vụ dọn theo lịch.
2. Truy vấn từng loại.

**Kết quả mong đợi.** Nhật ký vận hành > 90 ngày bị xóa; siêu dữ liệu và nhật ký an ninh giữ 12 tháng; truy vấn quá 12 tháng `400` ERR-03-021; kiểm toán thao tác còn 12 tháng online và có ở WORM.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Ba phiên 90 phút, mỗi phiên một chủ đề: (1) vượt qua chuỗi xác thực và hạn mức bằng cách xáo trộn tiêu đề, tenant, mã hóa đường dẫn; (2) quản trị đổi cấu hình liên tục khi tải chạy (route, hạn mức, WAF, ảnh chụp, quay lui); (3) đọc nhật ký lượt gọi và báo cáo tìm dấu vết dữ liệu nhạy cảm. Ghi chép theo mẫu SBTM; lỗi phát hiện chuyển thành ca tự động.

### 6.2. Diễn tập chuyển từ gateway cũ (chạy song song)

Dùng gói cấu hình Gravitee thật của tỉnh thí điểm (đã làm sạch khóa): nhập (UI-03-18), hoàn thiện lược đồ và chính sách OPA, phát lên SIT, rồi chạy song song 7 ngày với lưu lượng sao chép từ gateway cũ để so sánh mã phản hồi và độ trễ. Đạt khi ≥ 99,9 % lượt có cùng mã phản hồi nghiệp vụ (khác biệt chỉ ở các chốt nâng cấp có chủ đích như mTLS, OAuth), 100 % plan, rate limit, quota, whitelist, blacklist được chuyển, không khóa API cũ nào bị chép sang.

### 6.3. Diễn tập sự cố

Ba tình huống có SO, TO tham gia: (1) lộ nghi ngờ khóa API hoặc token của một HTTT: thu hồi, tạm ngừng consumer, quan sát ≤ 60 giây, đối chiếu kiểm toán; (2) đợt quét lỗ hổng từ Internet: cảnh báo WAF, tự chặn địa chỉ, đề nghị ngoại lệ cho chặn nhầm, soạn luật vá ảo; (3) phát cấu hình gây sự cố: quay lui về bản trước ≤ 5 phút.

### 6.4. Kiểm thử truy cập thủ công

Với NVDA + Firefox và VoiceOver + Safari trên UI-03-02, 03, 06, 10, 17: đi hết luồng chính (xem, dừng API, đặt hạn mức, phát, duyệt thay đổi), ghi lỗi theo WCAG 2.2.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành API Management cũ (Gravitee) và Bus cũ tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ về số thao tác và thời gian hiệu lực.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Dừng rồi mở lại một API đang chạy | LGC-APIM-005 | Làm được trong 3 thao tác, hiệu lực ≤ 60 giây, lượt gọi trong lúc dừng nhận thông báo rõ | FR-03-036, 047 | TS-03-12, 08 |
| UAT-02 | Đặt kiểu bảo mật của gói: khóa API hoặc Keyless, thêm OAuth hoặc mTLS | LGC-APIM-011; LGC-APIM-016; LGC-BUS-041 | Giữ đủ kiểu của hệ cũ, thêm OAuth 2.1 và mTLS; Keyless chỉ cho dữ liệu mở | FR-03-015, 016, 002, 012, 014 | TS-03-06, 07, 01 |
| UAT-03 | Đặt giới hạn tần suất theo giây, phút cho một HTTT | LGC-APIM-012 | Đặt trong 2 phút, có tiêu đề hạn mức, thấy mức đang dùng | FR-03-021, 024, 025 | TS-03-09, 10 |
| UAT-04 | Đặt hạn ngạch theo giờ, ngày, tháng và nhận cảnh báo ngưỡng | LGC-APIM-013 | Cảnh báo ở 80 % và 100 %, đặt lại đúng chu kỳ | FR-03-022 | TS-03-09 |
| UAT-05 | Cho phép hoặc chặn đường dẫn trong gói | LGC-APIM-014 | Chặn đường dẫn chuẩn hóa, báo lỗi rõ | FR-03-020 | TS-03-07 |
| UAT-06 | Gắn chính sách cho gói và chạy thử trước khi phát | LGC-APIM-015 | Chọn từ mẫu được duyệt, chạy thử không ảnh hưởng hạn mức thật | FR-03-048, 057 | TS-03-19 |
| UAT-07 | Xem địa chỉ gọi API, thêm backend, kiểm tra cân bằng tải | LGC-APIM-017; LGC-APIM-018 | Thấy host, đường dẫn, các backend và sức khỏe trong 3 thao tác | FR-03-028, 029, 030 | TS-03-12, 13 |
| UAT-08 | Tra nhật ký lượt gọi của một HTTT và xem chi tiết một lượt | LGC-APIM-022 | Tìm trong 3 thao tác, p95 ≤ 3 giây, không lộ thân bản tin | FR-03-050, 051 | TS-03-20 |
| UAT-09 | Xem danh sách gateway, trạng thái đồng bộ và tổng quan lưu lượng | LGC-APIM-023…026 | Thấy nút, phiên bản cấu hình, sức khỏe, biểu đồ lưu lượng | FR-03-045, 052, 055 | TS-03-18, 21 |
| UAT-10 | Quan sát gateway tự từ chối khi quá tải, cô lập lỗi, hết thời hạn chờ | LGC-NFR-006 | Hạn mức, ngắt mạch, thời hạn chờ có hiệu lực và có cảnh báo | FR-03-021, 026, 031 | TS-03-09, 11, 13 |
| UAT-11 | Chuyển cấu hình từ gateway cũ sang Datahub | LGC-APIM-002…005, LGC-APIM-009…015, LGC-APIM-019…021 | Có đề xuất cho mọi plan và Application; chỉ phải bổ sung lược đồ, chính sách OPA, bí mật | FR-03-059, 046 | TS-03-23, 18 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

Ma trận dưới sinh tự động từ chính các ca ở chương 4, 5 và 7 bằng `ph03/tools/gen_matrix.py`; không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-03. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph03/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-03-001 | Kết thúc TLS tại hai cửa vào | M | LGC-BUS-041 | 001, 002, 135 | 003, 004 | 107, 133 | Có |
| FR-03-002 | Xác minh chứng thư khách mTLS | M | LGC-APIM-011; LGC-BUS-041 | 005, 007, 010 | 006 | — | Có |
| FR-03-003 | Giới hạn kết nối và tốc độ theo địa chỉ nguồn | M | mới | 011, 012, 104, 115 | 011 | 121 | Có |
| FR-03-004 | Chặn tạm địa chỉ nguồn vi phạm liên tục | S | mới | 013, 014, 104 | 014 | 121 | Có |
| FR-03-005 | WAF Coraza với bộ luật OWASP CRS | M | mới | 015, 016, 101 | 019 | 116, 117, 132 | Có |
| FR-03-006 | Chế độ phát hiện, chặn của WAF và tự hạ khi quá tải | M | mới | 016, 017, 097, 101 | 017, 019, 098, 112, 114 | 018 | Có |
| FR-03-007 | Ngoại lệ luật WAF có thời hạn | M | mới | 020, 101, 115 | 021, 022, 112, 114 | — | Có |
| FR-03-008 | Luật vá ảo khẩn cấp | S | mới | 023, 101 | 023 | — | Có |
| FR-03-009 | Kiểm tra lược đồ và giới hạn kích thước yêu cầu | M | mới | 024, 106 | 024 | — | Có |
| FR-03-010 | Xử lý CORS | S | mới | 025 | 025 | — | Có |
| FR-03-011 | Tiêu đề bảo mật và che thông tin máy chủ | M | mới | 026 | 026 | 131 | Có |
| FR-03-012 | Xác minh chữ ký JWT cục bộ | M | LGC-APIM-011; LGC-BUS-041 | 027, 106 | 028 | 029, 116, 117 | Có |
| FR-03-013 | Xác định tenant của lượt gọi | M | mới | 027 | 030 | 110 | Có |
| FR-03-014 | Ràng buộc token với chứng thư khách | M | LGC-APIM-011; LGC-BUS-041 | 005 | 006 | — | Có |
| FR-03-015 | Áp phương thức bảo mật theo gói sử dụng | M | LGC-APIM-011; LGC-BUS-041 | 031 | 031 | — | Có |
| FR-03-016 | Kiểm tra đăng ký sử dụng và hiệu lực gói | M | LGC-APIM-011; LGC-APIM-016 | 032 | 032 | — | Có |
| FR-03-017 | Kiểm tra phạm vi quyền thô | M | LGC-APIM-011 | 033 | 033 | — | Có |
| FR-03-018 | Thu hồi token nhanh bằng danh sách chặn | M | mới | 037 | 038, 041, 050, 113 | 110 | Có |
| FR-03-019 | Ủy quyền chi tiết bằng OPA tại gateway | M | LGC-BUS-041 | 035, 106 | 035 | 036, 116, 117 | Có |
| FR-03-020 | Danh sách cho phép và chặn đường dẫn | M | LGC-APIM-014 | 034 | 034 | — | Có |
| FR-03-021 | Giới hạn tần suất theo bên gọi | M | LGC-APIM-012; LGC-NFR-006 | 042, 043, 045, 106 | 042, 050 | 110, 116, 117 | Có |
| FR-03-022 | Hạn ngạch theo chu kỳ và cảnh báo ngưỡng | M | LGC-APIM-013 | 044, 045, 100 | 044, 050 | — | Có |
| FR-03-023 | Hạn mức toàn tenant | M | mới | 047, 048, 097, 100 | 048, 098, 112, 114 | 124 | Có |
| FR-03-024 | Hạn mức theo route và thứ tự ưu tiên chính sách | S | LGC-APIM-012; LGC-APIM-013 | 049, 100 | 049 | — | Có |
| FR-03-025 | Phản hồi vượt hạn mức và tiêu đề hạn mức | M | mới | 042, 044 | 042, 044 | — | Có |
| FR-03-026 | Suy giảm có kiểm soát khi Valkey mất | M | mới | 051 | 050 | — | Có |
| FR-03-027 | Điều tiết theo tình trạng backend | S | LGC-NFR-006 | 045, 046 | — | — | Có |
| FR-03-028 | Định tuyến theo host, đường dẫn, phương thức | M | LGC-APIM-017 | 052, 054, 099, 135 | 052, 053, 108 | 118, 122, 123, 127 | Có |
| FR-03-029 | Cân bằng tải giữa các backend | M | LGC-APIM-018 | 057, 058 | 058 | 118, 128 | Có |
| FR-03-030 | Kiểm tra sức khỏe backend chủ động và thụ động | M | LGC-APIM-018; LGC-NFR-006 | 058, 059 | 058, 059 | — | Có |
| FR-03-031 | Thời hạn chờ, ngắt mạch và trả lỗi nhanh | M | LGC-NFR-006 | 059 | 059, 060 | — | Có |
| FR-03-032 | Sinh và truyền định danh truy vết | M | mới | 061 | 061 | — | Có |
| FR-03-033 | Chuyển tiếp WebSocket và nén nội dung | M | mới | 062 | 062 | 119 | Có |
| FR-03-034 | Chuyển đổi gRPC và REST | C | mới | — | — | 063 | Có |
| FR-03-035 | Phiên bản API song song và tiêu đề ngừng dùng | S | mới | 056 | 056 | — | Có |
| FR-03-036 | Dừng và mở API tức thời | M | LGC-APIM-005 | 055, 099, 106, 115 | 055, 112 | — | Có |
| FR-03-037 | Chuyển tiếp lượt gọi của tenant đã sáp nhập | S | mới | 066, 104 | 067 | — | Có |
| FR-03-038 | Phân cửa vào Internet và mạng nội bộ | M | mới | 064, 097 | 065, 098, 112, 114 | — | Có |
| FR-03-039 | Tổng hợp cấu hình gateway từ danh mục | M | LGC-APIM-011; LGC-APIM-012; LGC-APIM-013… | 068, 071, 103 | 070 | 111 | Có |
| FR-03-040 | Kiểm tra hợp lệ cấu hình trước khi phát | M | mới | 103 | 069 | — | Có |
| FR-03-041 | Sinh ảnh chụp cấu hình có phiên bản và chữ ký | M | mới | 068, 103 | 070 | 111 | Có |
| FR-03-042 | Phát ảnh chụp tới Git và bucket | M | mới | 072, 103 | 073 | 120 | Có |
| FR-03-043 | Nạp ảnh chụp ở nút gateway | M | mới | 072, 103 | 074 | 075, 120, 128, 129 | Có |
| FR-03-044 | Quay lui về phiên bản cấu hình trước | M | mới | 071, 076, 103 | 077, 112 | — | Có |
| FR-03-045 | Theo dõi nút và trạng thái đồng bộ | M | LGC-APIM-023; LGC-APIM-024; LGC-APIM-025 | 078, 102 | 074 | — | Có |
| FR-03-046 | Đồng bộ consumer và thông tin xác thực công khai | M | LGC-APIM-019; LGC-APIM-020 | 079, 081, 100 | 080, 108, 113 | 127 | Có |
| FR-03-047 | Tạm ngừng khẩn cấp route hoặc consumer | M | mới | 039, 040, 100, 115 | 040, 041 | — | Có |
| FR-03-048 | Bộ mẫu chính sách gateway được duyệt sẵn | M | LGC-APIM-015 | 082, 103 | 082 | — | Có |
| FR-03-049 | Quản lý chứng thư biên | M | mới | 007, 008, 010, 103 | 009 | — | Có |
| FR-03-050 | Ghi siêu dữ liệu lượt gọi có che dữ liệu | M | LGC-APIM-022 | 084, 136 | 084 | 105 | Có |
| FR-03-051 | Tra cứu và xuất nhật ký lượt gọi | M | LGC-APIM-022 | 085, 087, 102, 136 | 086, 087, 108 | 126 | Có |
| FR-03-052 | Phát chỉ số và vết OpenTelemetry | M | mới | 088 | 088 | 105 | Có |
| FR-03-053 | Kiểm tra tổng hợp cho API quan trọng | S | mới | 090 | 090 | 130 | Có |
| FR-03-054 | Cảnh báo sự kiện an ninh tại gateway | M | mới | 091 | 091 | — | Có |
| FR-03-055 | Bảng điều khiển lưu lượng gateway | M | LGC-APIM-026 | 089, 099 | 089 | 125 | Có |
| FR-03-056 | Tham số gateway theo tenant | M | mới | 092, 104 | 093 | — | Có |
| FR-03-057 | Chạy thử chính sách bằng mô phỏng | S | mới | 083, 103 | 083 | — | Có |
| FR-03-058 | Báo cáo sử dụng API theo HTTT và gói | S | LGC-APIM-022 | 094 | 094 | — | Có |
| FR-03-059 | Nhập cấu hình từ gateway cũ | S | LGC-APIM-002; LGC-APIM-003; LGC-APIM-004… | 095, 104, 115 | 096 | — | Có |

: Yêu cầu chức năng → test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của hệ cũ mà PH-03 là phân hệ đích (`LGC-BUS-041`, `LGC-APIM`, `LGC-NFR-006`) được truy tới FR mới và tới ca tự động, ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-002 | 059 | 095 | UAT-11 |
| LGC-APIM-003 | 059 | 095 | UAT-11 |
| LGC-APIM-004 | 059 | 095 | UAT-11 |
| LGC-APIM-005 | 036, 059 | 055, 095, 099, 106, 115 | UAT-01, UAT-11 |
| LGC-APIM-009 | 059 | 095 | UAT-11 |
| LGC-APIM-010 | 059 | 095 | UAT-11 |
| LGC-APIM-011 | 002, 012, 014, 015, 016, 017, 039, 059 | 005, 007, 010, 027, 031, 032, 033, 068 (+2) | UAT-02, UAT-11 |
| LGC-APIM-012 | 021, 024, 039, 059 | 042, 043, 045, 049, 068, 095, 100, 106 | UAT-03, UAT-11 |
| LGC-APIM-013 | 022, 024, 039, 059 | 044, 045, 049, 068, 095, 100 | UAT-04, UAT-11 |
| LGC-APIM-014 | 020, 039, 059 | 034, 068, 095 | UAT-05, UAT-11 |
| LGC-APIM-015 | 039, 048, 059 | 068, 082, 095, 103 | UAT-06, UAT-11 |
| LGC-APIM-016 | 016 | 032 | UAT-02 |
| LGC-APIM-017 | 028 | 052, 054, 099, 135 | UAT-07 |
| LGC-APIM-018 | 029, 030 | 057, 058, 059 | UAT-07 |
| LGC-APIM-019 | 046, 059 | 079, 081, 095, 100 | UAT-11 |
| LGC-APIM-020 | 046, 059 | 079, 081, 095, 100 | UAT-11 |
| LGC-APIM-021 | 059 | 095 | UAT-11 |
| LGC-APIM-022 | 050, 051, 058 | 084, 085, 087, 094, 102, 136 | UAT-08 |
| LGC-APIM-023 | 045 | 078, 102 | UAT-09 |
| LGC-APIM-024 | 045 | 078, 102 | UAT-09 |
| LGC-APIM-025 | 045 | 078, 102 | UAT-09 |
| LGC-APIM-026 | 055 | 089, 099 | UAT-09 |
| LGC-BUS-041 | 001, 002, 012, 014, 015, 019 | 001, 002, 005, 007, 010, 027, 031, 035 (+2) | UAT-02 |
| LGC-NFR-006 | 021, 027, 030, 031 | 011, 042, 043, 045, 046, 047, 058, 059 (+1) | UAT-10 |

: Chức năng hệ cũ → yêu cầu → test case

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-03-001 | 052, 062, 107 |
| BR-03-002 | 027, 030 |
| BR-03-003 | 001, 002, 003 |
| BR-03-004 | 005, 006, 027, 028, 029, 031 |
| BR-03-005 | 011, 012, 042, 043, 047, 049, 110 |
| BR-03-006 | 020, 021, 022, 114 |
| BR-03-007 | 015, 084, 087, 088, 091, 105 |
| BR-03-008 | 033, 035, 036 |
| BR-03-009 | 044, 045, 046 |
| BR-03-010 | 055, 072, 073, 075, 128, 129 |
| BR-03-011 | 057, 058, 059, 060 |
| BR-03-012 | 025 |
| BR-03-013 | 026 |
| BR-03-014 | 024, 031, 034, 069, 095, 096 |
| BR-03-015 | 064, 065 |
| BR-03-016 | 008, 068, 070, 072, 073, 074, 076, 078, 092, 115 |
| BR-03-017 | 034, 063, 069, 082 |
| BR-03-018 | 068, 074, 076, 077 |
| BR-03-019 | 016, 017, 018, 019, 022, 048, 049, 064, 093, 097 (+3) |
| BR-03-020 | 044, 094 |
| BR-03-021 | 032, 037, 038, 039, 040, 041, 079, 081 |
| BR-03-022 | 032, 039, 079, 080, 081 |
| BR-03-023 | 004, 011, 024, 026, 028, 035, 042, 059, 060, 061 (+3) |
| BR-03-024 | 042 |
| BR-03-025 | 050, 051 |
| BR-03-026 | 030, 052, 053, 054, 066, 067, 069, 108, 109, 110 (+1) |
| BR-03-027 | 083, 090 |
| BR-03-028 | 007, 053, 071, 085, 087, 089, 090, 094, 108, 109 |
| BR-03-029 | 040, 055, 079, 080, 095, 115 |
| BR-03-030 | 056, 066, 067 |

: Quy tắc nghiệp vụ → test case

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-03-001 | 007, 040, 049, 053, 055, 060, 067, 071, 077, 078 (+9) |
| ERR-03-002 | 080 |
| ERR-03-003 | 003, 021, 024, 038, 049, 060, 065, 067, 070, 080 (+8) |
| ERR-03-004 | 048, 049, 093 |
| ERR-03-005 | 025, 031, 034, 056, 063, 069 |
| ERR-03-006 | 070, 073, 077 |
| ERR-03-007 | 077 |
| ERR-03-008 | 017, 018, 022, 048, 064, 098, 114 |
| ERR-03-009 | 021, 023 |
| ERR-03-010 | 021 |
| ERR-03-011 | 065, 069 |
| ERR-03-012 | 069 |
| ERR-03-013 | 069, 082 |
| ERR-03-014 | 073 |
| ERR-03-015 | 009, 070, 073 |
| ERR-03-016 | 009, 069 |
| ERR-03-017 | 080 |
| ERR-03-018 | 024, 048, 049, 060, 069, 083, 093 |
| ERR-03-019 | 009, 014, 023, 038, 040, 055, 067, 082, 091, 096 (+1) |
| ERR-03-020 | 096 |
| ERR-03-021 | 086, 087, 094, 136 |
| ERR-03-022 | 003, 007, 009, 014, 019, 022, 023, 025, 038, 041 (+21) |
| ERR-03-023 | 040, 055 |
| ERR-03-024 | 014 |
| ERR-03-025 | 067 |
| ERR-03-026 | 078, 086, 089, 094 |
| ERR-03-027 | 017 |
| ERR-03-101 | 024, 062 |
| ERR-03-102 | 028 |
| ERR-03-103 | 028, 031 |
| ERR-03-104 | 028 |
| ERR-03-105 | 037, 110 |
| ERR-03-106 | 030 |
| ERR-03-107 | 033 |
| ERR-03-108 | 006 |
| ERR-03-109 | 015, 132 |
| ERR-03-110 | 013 |
| ERR-03-111 | 032 |
| ERR-03-112 | 035 |
| ERR-03-113 | 034 |
| ERR-03-114 | 052, 053, 064 |
| ERR-03-115 | 024 |
| ERR-03-116 | 042, 043, 046, 062, 110 |
| ERR-03-117 | 044, 045 |
| ERR-03-118 | 047 |
| ERR-03-119 | 011 |
| ERR-03-120 | 059 |
| ERR-03-121 | 060 |
| ERR-03-122 | 058, 060 |
| ERR-03-123 | 040, 055 |
| ERR-03-124 | 029, 036 |
| ERR-03-125 | 063 |
| ERR-03-126 | 056 |
| ERR-03-127 | 032, 039, 081 |
| ERR-03-128 | 004 |
| ERR-03-129 | 026 |
| ERR-03-130 | 031 |

: Mã lỗi → test case

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-03-001 | 058, 116 |
| NFR-03-002 | 018, 027, 035, 042, 117 |
| NFR-03-003 | 118 |
| NFR-03-004 | 062, 119 |
| NFR-03-005 | 128, 130 |
| NFR-03-006 | 128 |
| NFR-03-007 | 029, 050, 075 |
| NFR-03-008 | 072, 076, 120 |
| NFR-03-009 | 037, 039 |
| NFR-03-010 | 001, 133 |
| NFR-03-011 | 008, 010 |
| NFR-03-012 | 015, 018, 023, 132 |
| NFR-03-013 | 011, 013, 121 |
| NFR-03-014 | 084, 105 |
| NFR-03-015 | 026, 106 |
| NFR-03-016 | 131 |
| NFR-03-017 | 122 |
| NFR-03-018 | 123 |
| NFR-03-019 | 030, 047, 053, 108, 109, 110, 111, 124 |
| NFR-03-020 | 061, 088 |
| NFR-03-021 | 078, 088, 089, 125 |
| NFR-03-022 | 085, 126 |
| NFR-03-023 | 054, 127 |
| NFR-03-024 | 072, 129 |
| NFR-03-025 | 135 |
| NFR-03-026 | 115, 136 |
| NFR-03-027 | 134 |

: Yêu cầu phi chức năng → test case

### 8.6. Use case → test case

| Mã | Test case |
|---|---|
| UC-03-01 | 027, 028, 052, 061, 084, 107 |
| UC-03-02 | 005, 006 |
| UC-03-03 | 030 |
| UC-03-04 | 042, 044 |
| UC-03-05 | 004, 015, 135 |
| UC-03-06 | 057 |
| UC-03-07 | 062, 063 |
| UC-03-08 | 050, 051 |
| UC-03-09 | 055, 056, 099 |
| UC-03-10 | 037 |
| UC-03-11 | 039, 040 |
| UC-03-12 | 013, 014, 104 |
| UC-03-13 | 017, 097, 101 |
| UC-03-14 | 020, 022, 101 |
| UC-03-15 | 023, 101 |
| UC-03-16 | 064, 097 |
| UC-03-17 | 002, 103 |
| UC-03-18 | 091 |
| UC-03-19 | 068, 103 |
| UC-03-20 | 072, 075 |
| UC-03-21 | 076, 103 |
| UC-03-22 | 078, 102 |
| UC-03-23 | 079, 081, 100 |
| UC-03-24 | 082, 083, 103 |
| UC-03-25 | 048, 049, 097, 100 |
| UC-03-26 | 085, 087, 102 |
| UC-03-27 | 089, 094, 099 |
| UC-03-28 | 090 |
| UC-03-29 | 092, 104 |
| UC-03-30 | 066, 104 |
| UC-03-31 | 095, 104 |

: Use case → test case

### 8.7. Màn hình → test case

| Mã | Test case |
|---|---|
| UI-03-01 | 050, 051, 088, 089, 090, 091, 094, 099, 128, 130 (+1) |
| UI-03-02 | 040, 052, 053, 054, 055, 056, 099, 134 |
| UI-03-03 | 024, 025, 031, 033, 034, 035, 036, 052, 054, 055 (+11) |
| UI-03-04 | 079, 081, 100, 134 |
| UI-03-05 | 005, 032, 037, 039, 044, 079, 081, 085, 100, 134 |
| UI-03-06 | 042, 043, 044, 045, 046, 047, 048, 049, 100, 134 |
| UI-03-07 | 015, 016, 017, 018, 020, 091, 101, 134 |
| UI-03-08 | 020, 021, 023, 101, 134 |
| UI-03-09 | 061, 084, 085, 086, 087, 102, 134 |
| UI-03-10 | 068, 069, 070, 071, 072, 073, 076, 077, 103, 134 |
| UI-03-11 | 027, 029, 072, 074, 075, 078, 102, 128, 134 |
| UI-03-12 | 001, 002, 005, 007, 008, 009, 010, 103, 134 |
| UI-03-13 | 031, 034, 082, 103, 134 |
| UI-03-14 | 083, 103, 134 |
| UI-03-15 | 011, 013, 014, 104, 134 |
| UI-03-16 | 012, 026, 066, 092, 093, 104, 134 |
| UI-03-17 | 017, 020, 048, 064, 097, 098, 101, 134 |
| UI-03-18 | 095, 104, 134 |

: Màn hình → test case

### 8.8. API quản trị → test case

| Mã | Test case |
|---|---|
| API-03-001 | 052, 053, 054, 099, 133 |
| API-03-002 | 024, 033, 052, 053, 054, 056, 062, 063, 099, 108 |
| API-03-003 | 055, 099, 112, 115 |
| API-03-004 | 055 |
| API-03-005 | 057 |
| API-03-006 | 057, 058, 108 |
| API-03-007 | 056 |
| API-03-008 | 064, 065, 112 |
| API-03-009 | 024 |
| API-03-010 | 059, 060 |
| API-03-011 | 079, 100 |
| API-03-012 | 032, 079, 081, 100, 108 |
| API-03-013 | 079, 080, 081, 113 |
| API-03-014 | 079, 080, 113 |
| API-03-015 | 079, 080, 113 |
| API-03-016 | 005, 079, 108 |
| API-03-017 | 039, 041, 100, 115 |
| API-03-018 | 039, 100 |
| API-03-019 | 040, 041 |
| API-03-020 | 040 |
| API-03-021 | 031, 032, 034 |
| API-03-022 | 031, 033, 034, 108 |
| API-03-023 | 047 |
| API-03-024 | 048, 100, 112, 133 |
| API-03-025 | 049 |
| API-03-026 | 049, 100 |
| API-03-027 | 049 |
| API-03-028 | 049 |
| API-03-029 | 042, 043, 044, 045, 046, 083, 100, 110 |
| API-03-030 | 044 |
| API-03-031 | 001 |
| API-03-032 | 002 |
| API-03-033 | 002, 003, 115 |
| API-03-034 | 002 |
| API-03-035 | 005, 007 |
| API-03-036 | 013, 014, 104 |
| API-03-037 | 014, 104, 112, 115 |
| API-03-038 | 014, 104 |
| API-03-039 | 015, 019, 101, 132 |
| API-03-040 | 016, 018 |
| API-03-041 | 017, 019, 101, 112 |
| API-03-042 | 020, 101 |
| API-03-043 | 020, 021, 101, 112, 115 |
| API-03-044 | 020, 022, 101, 112, 114 |
| API-03-045 | 022 |
| API-03-046 | 020 |
| API-03-047 | 023 |
| API-03-048 | 023 |
| API-03-049 | 023 |
| API-03-050 | 025 |
| API-03-051 | 025 |
| API-03-052 | 027, 029 |
| API-03-053 | 037, 038, 113 |
| API-03-054 | 037, 041, 110 |
| API-03-055 | 035 |
| API-03-056 | 068, 071, 076, 103 |
| API-03-057 | 068, 071, 108, 111 |
| API-03-058 | 069, 070 |
| API-03-059 | 068, 069, 070, 103, 112, 133 |
| API-03-060 | 072, 073, 103 |
| API-03-061 | 076, 077, 103, 112 |
| API-03-062 | 071, 076, 103 |
| API-03-063 | 072, 074, 078, 102, 128, 129 |
| API-03-064 | 074, 075, 078, 102, 108 |
| API-03-065 | 034, 082, 103 |
| API-03-066 | 031, 082, 108 |
| API-03-067 | 082, 103 |
| API-03-068 | 007, 103 |
| API-03-069 | 007, 008, 108 |
| API-03-070 | 008, 009, 103 |
| API-03-071 | 017, 048, 064, 097, 101 |
| API-03-072 | 017, 048, 064, 097, 098, 101, 112, 114 |
| API-03-073 | 097, 098 |
| API-03-074 | 084, 085, 086, 102, 112, 136 |
| API-03-075 | 085, 102, 108 |
| API-03-076 | 087, 102 |
| API-03-077 | 050, 051, 088, 089, 099, 128, 130 |
| API-03-078 | 089 |
| API-03-079 | 089 |
| API-03-080 | 090, 130 |
| API-03-081 | 090 |
| API-03-082 | 090, 108 |
| API-03-083 | 090 |
| API-03-084 | 091 |
| API-03-085 | 091 |
| API-03-086 | 011, 026, 092, 104 |
| API-03-087 | 012, 026, 092, 093, 104, 115, 133 |
| API-03-088 | 083, 103 |
| API-03-089 | 094 |
| API-03-090 | 094 |
| API-03-091 | 095, 096, 104 |
| API-03-092 | 095, 096, 104 |
| API-03-093 | 095, 096, 104, 115 |
| API-03-094 | 066, 067 |
| API-03-095 | 066, 067, 104 |
| API-03-096 | 066, 067 |

: API quản trị → test case

### 8.9. Sự kiện → test case

| Mã | Test case |
|---|---|
| EVT-03-01 | 072 |
| EVT-03-02 | 076 |
| EVT-03-03 | 040, 055, 064 |
| EVT-03-04 | 039, 079, 081 |
| EVT-03-05 | 020 |
| EVT-03-06 | 020 |
| EVT-03-07 | 044 |
| EVT-03-08 | 008, 010 |
| EVT-03-09 | 013, 018, 074, 091 |
| EVT-03-10 | 066 |
| EVT-03-11 | 048, 092 |
| EVT-03-12 | 069 |

: Sự kiện → test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

| Thư mục | Nội dung |
|---|---|
| `apps/connect/src/test/java/vn/datahub/connect/gateway/` | UT, IT; lớp cơ sở `GatewayTestBase` (Testcontainers PostgreSQL 16, OpenBao, Kafka, WireMock) |
| `gateway/plugins/{plugin}/spec/*_spec.lua` | UT plugin Lua bằng `busted` (`dh-auth`, `dh-limit`, `dh-revocation`, `dh-path-acl`, `dh-ip-block`, `dh-kill-switch`) |
| `gateway/test/conf/` | Cấu hình APISIX chế độ khai báo dùng cho ca GW |
| `apps/console/src/features/gateway/**/*.test.ts` | UT frontend |
| `e2e/gateway/ts-03-nn.spec.ts` | Playwright |
| `perf/gateway/*.js` | k6 |
| `datahub-docs/03-thiet-ke/csdl/ph03/test/` | Bài kiểm cô lập CSDL |
| `datahub-docs/05-kiem-thu/test-case/ph03/gherkin/` | Gherkin sinh từ tài liệu này |

: Tổ chức mã kiểm thử

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-03-nnn")`, `test('TC-03-nnn …')`, `-- TC-03-nnn` trong `busted`).

### 9.2. Mẫu ca dò mồi (JUnit)

```java
@Tag("TC-03-nnn")
@Test
void nhatKyKhongChuaMoi() {
    var canary = "DH-CANARY-" + testInfo.getTestMethod().get().getName();
    gateway.as(C_HTTT1).post("/ho-tich/tra-cuu?cccd=" + canary)
           .header("Cookie", "s=" + canary).body("{\"x\":\"" + canary + "\"}")
           .send();
    var hits = Sweep.allSinks(canary); // nhật ký APISIX, ứng dụng, OTel, ClickHouse, Kafka, bảng ph03_gateway.*
    assertThat(hits).isEmpty();
}
```

Ca quét toàn hệ thống dùng lớp `Sweep` chung; mỗi ca có mồi riêng để khi hỏng biết ca nào làm lộ.

### 9.3. Mẫu ca kiểm tra plugin (busted)

```lua
-- TC-03-nnn: dh-auth xóa tiêu đề X-DH-* do khách gửi
describe("dh-auth", function()
  it("xoa X-DH-Tenant gia va dat lai tu token", function()
    local ctx = mock_request({ headers = { ["X-DH-Tenant"] = "T01" }, token = token_for("T68") })
    dh_auth.access({}, ctx)
    assert.equal("T68", ctx.upstream_headers["X-DH-Tenant"])
  end)
end)
```

### 9.4. Mẫu ca E2E (Playwright)

```ts
test('TC-03-nnn không tự duyệt thay đổi của mình', async ({ page }) => {
  await loginAs(page, 'U-T68-SO1');
  await page.goto('/cong-api/duyet-thay-doi');
  await expect(page.getByRole('button', { name: 'Duyệt' }).first()).toBeDisabled();
  await expect(page.getByText('Bạn đã đề nghị thay đổi này nên không thể tự duyệt.')).toBeVisible();
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

| Lệnh | Kết quả |
|---|---|
| `python3 ph03/tools/number_tcs.py` | Cấp số `TC-03-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph03/tools/fill_doc.py` | Ghi bảng kịch bản (mục 3.1), số kịch bản, số ca và ma trận mục 8; in ra stderr BR, ERR, NFR, API, UI, UC chưa có ca |
| `python3 ph03/tools/gen_gherkin.py` | `ph03/gherkin/ts-03-nn.feature` và `uat-tuong-duong-gateway.feature` |
| `python3 ph03/tools/gen_xlsx.py` | `ph03/D05-02-PH03-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

Chạy các lệnh từ thư mục `datahub-docs/05-kiem-thu/test-case/`.

## Câu hỏi mở

> **Câu hỏi mở Q03-40:** Ngưỡng hiệu quả WAF (chặn ≥ 99 % payload OWASP, chặn nhầm < 0,1 %) ở NFR-03-012 là giả định. Cần lưu lượng thật của tỉnh thí điểm để chốt ngưỡng chặn nhầm trước khi đổi sang `BLOCK`. Đề xuất: giữ giả định ở SIT, hiệu chỉnh sau 14 ngày chạy `DETECT` ở UAT; cần ý kiến đơn vị thẩm định ATTT.

> **Câu hỏi mở Q03-41:** Ca mất một vùng sẵn sàng (TC-03-128, NFR-03-006) cần hạ tầng hai vùng thật; SIT chỉ giả lập bằng hai nhóm nút. Đề xuất: chạy ca ở SIT bằng taint nút và chạy lại một lần ở PERF có hai vùng thật trước phát hành; cần xác nhận với nhóm hạ tầng.

> **Câu hỏi mở Q03-42:** Ca nhập cấu hình (TS-03-23) và diễn tập chuyển song song (mục 6.2) cần một gói cấu hình Gravitee thật đã làm sạch khóa từ tỉnh thí điểm; hiện `F-LEGACY-OK` do nhóm kiểm thử dựng theo cấu trúc hệ cũ. Đề xuất: tỉnh thí điểm cấp gói trước cổng RG-2; nếu chưa có, UAT-11 chạy bằng gói giả lập và ghi rõ vào biên bản.

> **Câu hỏi mở Q03-43:** Ca chống tràn theo địa chỉ nguồn (TS-03-02, TC-03-121) cần bộ phát tải từ ít nhất 50 địa chỉ nguồn khác nhau, gồm IPv6. Đề xuất: SIT cấp dải `10.99.0.0/16` và `fd00:99::/48` cho `SIM-ATTACK`; cần xác nhận với nhóm hạ tầng.

> **Câu hỏi mở Q03-44:** Các ca dùng đồng hồ giả lập (hạn ngạch theo ngày, hạn ngoại lệ 90 ngày, hạn chứng thư, lưu giữ) chạy lâu nếu không dùng `faketime`. Đề xuất: ca có `faketime` chỉ chạy ở lần chạy đêm, không ở cổng CI-5; cần ý kiến nhóm CI (D04-02).

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

| Tài liệu | Đề nghị |
|---|---|
| D00-04 §2 | Cập nhật cột "Tài liệu" của PH-03 thành "đủ bảy tập 0.1" khi cả bảy tập đã duyệt; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để cập nhật dải mã TS, TC của PH-03 |
| D05-01 | Ghi PH-03 vào bảng phủ kiểm thử: nhóm ca bắt buộc 100 % (TS-03-06, 08, 26, 27, 28) và số liệu ca ở Tóm tắt; thêm môi trường SIT hai vùng sẵn sàng và dải địa chỉ giả lập của Q03-43 |
| D04-02 | Đưa bộ ca GW (APISIX trong Docker) và `busted` vào cổng CI-3 hoặc CI-4; ca có `faketime` chạy đêm (Q03-44) |
| D02-08 §3.1 | Bổ sung tám quyền `PERM-03-*` đã đề nghị ở D02-03-PH03 (đã có trong FRS, nhắc để đồng bộ); thêm vai trò kiểm thử chỉ có `PERM-03-read` (VW) vào danh sách người dùng kiểm thử dùng chung |
| Đề xuất ADR | Không có |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 32 kịch bản, 11 UAT tương đương hệ cũ; ma trận truy vết, Gherkin, bảng tính sinh bằng công cụ `ph03/tools/` |

