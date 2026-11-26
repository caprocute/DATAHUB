---
ma_tai_lieu: D05-02-PH05
ten: Kịch bản và test case phân hệ PH-05 Bộ điều hợp và kết nối
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-05
---

# D05-02-PH05 · Kịch bản và test case Bộ điều hợp và kết nối

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-05 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH05.
- Không mất chức năng khai báo kết nối, kiểm tra kết nối, connector đa loại và bảo mật endpoint của Bus cũ và Productivity Tooling (LGC-BUS-011, 013, 040, 041; LGC-TOOL-008…012, 027).
- Không có đường nào để bí mật của kết nối lộ ra ngoài OpenBao, và không có đường nào để tỉnh này thấy hay dùng kết nối, tài khoản CSDL của tỉnh khác.

**Phạm vi.** Gồm <!--gen:so-ts-->36<!--/gen--> kịch bản (TS-05-01…36) với <!--gen:so-tc-->0<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph05/tools/gen_matrix.py`.

**Căn cứ.** Tài liệu cùng bộ PH-05 (FRS D02-03-PH05, use case D02-04-PH05, SDD D03-02-PH05, CSDL D03-03-PH05, API D03-04-PH05, màn hình D03-06-PH05); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; yêu cầu ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026.

**Điểm cần hội đồng lưu ý.** Năm nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- không lộ bí mật, kiểm bằng giá trị mồi `DH-CANARY` (TS-05-31);
- cách ly tenant ở API, CSDL (RLS) và OpenBao (TS-05-32);
- bốn mắt cho bật PROD, phiên bản bộ điều hợp, tài khoản ghi CSDL, Kamelet (TS-05-33);
- tài khoản CSDL chỉ đọc không ghi được và không chạm CSDL control plane (TS-05-11, 19);
- Kamelet tỉnh không qua được kiểm tra tĩnh khi dùng ngôn ngữ kịch bản hay URI trực tiếp (TS-05-27).

Mã W1 hiện có chỉ có bảng `ph05.adapter` tối giản; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT) vì chưa có dữ liệu thật.

## 0. Giới thiệu

Tài liệu là tập 7 của bộ PH-05. Người đọc chính là kiểm thử viên (viết, chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT (ca TS-05-31…33) và chủ đầu tư (UAT mục 7). Ca được viết để chạy được ngay trên môi trường SIT với bộ dữ liệu mục 2, không cần hỏi lại.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

| Đối tượng | Thành phần | Ghi chú |
|---|---|---|
| Control plane | Mô-đun `adapter` trong `dh-integration` (Spring Boot 4, Spring Modulith) | API `/api/adapter/v1`, outbox, lịch |
| Data plane | Thư viện `vn.datahub.runtime.adapter` trong `dh-runtime` (Camel Quarkus 3.33.x), Kamelet nền | Hồ sơ `core-native`, `files-native`, `soap-jvm`, `legacy-jvm` |
| Bộ chạy kiểm tra | `ProbeWorker` hồ sơ `probe-jvm` | Kiểm tra kết nối, điều kiện CDC, quyền CSDL |
| CDC | Strimzi Kafka Connect + Debezium, SMT `DhSchemaGate`, `SchemaWatcher` | ADR-059 |
| Kho bí mật | OpenBao KV v2, database engine, PKI | Chính sách theo D03-02-PH05 §5 |
| CSDL | Schema `ph05_adapter` (23 bảng) | RLS chế độ P và S |
| Giao diện | UI-05-01…17 | React + antd v6 |

### 1.2. Mức kiểm thử

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Quy tắc miền, bộ chuyển đổi, bộ phân tích SQL, kiểm tra tĩnh KR-01…14 |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, OpenBao, Kafka, WireMock) | Control plane với CSDL, OpenBao, outbox |
| CSDL | DB | `psql` với `ph05_isolation_test.sql` | RLS, append-only, ràng buộc |
| Runtime | RT | `@QuarkusTest`, Camel test | Kamelet giao thức, phân giải `{{conn:…}}`, nhóm kết nối |
| Hợp đồng | CT | `check_contracts.py`, Spectral, `@asyncapi/parser` | OpenAPI, AsyncAPI |
| API | API | REST Assured | Mọi API-05 |
| Đầu cuối | E2E | Playwright | UI-05-* |
| Hiệu năng | k6 | k6, JMH | NFR-05-001…010, 013 |
| Chịu lỗi | Chaos | Chaos Mesh | OpenBao, Kafka, HTTT đích mất |
| Bảo mật | ZAP | OWASP ZAP, Trivy, Semgrep | ASVS 5.0 mức 2 |

### 1.3. Môi trường kiểm thử

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm, tenant T68, T01; OpenBao, Kafka, Kafka Connect, Apicurio thật; HTTT giả lập (mục 2.4) | API, E2E, RT, Chaos |
| PERF | Cấu hình QM-VUA theo D03-09, dữ liệu GĐ-01…07 | k6 |
| UAT | Như SIT, dữ liệu sao từ gói Bus cũ đã làm sạch | UAT mục 7 |

### 1.4. Tiêu chí vào và ra

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH05 ở trạng thái duyệt; DDL `ph05_adapter.sql` áp được; hợp đồng qua CT; bộ dữ liệu mục 2 nạp xong |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-05-31…33 đạt 100 % |

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-05-nn`, test case `TC-05-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case là một khối thống nhất với D05-02-PH04, D05-02-PH19:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, RT, CT, API, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC.
- **Tiền điều kiện / dữ liệu**: mã dữ liệu ở mục 2.
- **Bước**: đánh số. Đường dẫn API tương đối với `/api/adapter/v1`.
- **Mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-05-012 (thiếu quyền `PERM-05-*`) |
| 404-ẩn | `404` với ERR-05-001, thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` (BR-05-002) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{tên}` | Đúng một bản tin trên topic `t68.adapter.{tên}.v1` (CloudEvents, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong `ph05_adapter.outbox` và không có bản tin trên topic liên quan |
| Mồi sạch | Tìm chuỗi `DH-CANARY-{ca}` trong phản hồi API, log ứng dụng 5 phút, vết OTel, bảng `ph05_adapter.*`, outbox, Kafka, tệp xuất: không thấy |

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-05`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: lộ giá trị bí mật ở bất kỳ đâu ngoài OpenBao; đọc được kết nối, tài khoản, nhật ký của tenant khác; tài khoản chỉ đọc ghi được dữ liệu; người tự duyệt được yêu cầu của mình; Kamelet vi phạm KR chặn mà vẫn được duyệt; CDC phát bản ghi theo lược đồ phá vỡ. Báo cáo hằng đêm từ JUnit, Playwright, k6, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng `ph05/seed/` qua API (không chèn SQL trực tiếp), trừ dữ liệu CSDL nguồn giả lập.

### 2.1. Tenant

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập) | `05.secret.max-age-days = 90`; egress cho phép `*.sim.test`; đóng băng PROD tắt trừ ca ghi khác |
| `T01` | Tỉnh đối chứng rò rỉ | Có kết nối **trùng mã** `ndxp-ho-tich` với T68 nhưng khác `baseUrl`, để phát hiện trả nhầm |
| `COMMON` | Không gian Kamelet nền và dùng chung | Chỉ PA ghi |

### 2.2. Người dùng

Tên nhân vật trùng D02-04-PH05. Mọi người dùng vai trò TA, SO, IA, PA có TOTP thử để kiểm thử xác thực lại.

| Mã | Tenant | Vai trò | Nhân vật | Mục đích |
|---|---|---|---|---|
| U-PA | PLATFORM | PA | Đỗ Quang Khải | Duyệt Kamelet `COMMON`, nền |
| U-T68-TA | T68 | TA | Lê Thu Hà | Tham số tenant, loại kết nối |
| U-T68-IE1 | T68 | IE | Nguyễn Văn An | Người khai báo chính |
| U-T68-IE2 | T68 | IE | Trần Thị Bình | Người thứ hai, xung đột đồng thời |
| U-T68-IA1 | T68 | IA | Lê Văn Cường | Người duyệt chính |
| U-T68-IA2 | T68 | IA + IE | Đặng Thị Mai | Vừa khai vừa duyệt, kiểm bốn mắt |
| U-T68-TO | T68 | TO | Vũ Minh Tuấn | Vận hành, sức khỏe, CDC |
| U-T68-SO | T68 | SO | Phạm Thu Dung | Đồng ý ghi CSDL, nhật ký truy cập, tạm ngừng ATTT |
| U-T68-AU | T68 | AU | — | Kiểm toán, chỉ đọc |
| U-T68-VW | T68 | VW (chỉ `PERM-05-read`) | — | Chỉ đọc |
| U-T01-IE | T01 | IE | — | Đối chứng rò rỉ |
| S-RT-T68, S-RT-T01 | — | Tài khoản dịch vụ `dh-runtime` | — | API nội bộ, scope `adapter:runtime-config` |
| S-INT | — | Tài khoản dịch vụ PH-04 | — | Scope `adapter:verify`, `adapter:health-read` |

### 2.3. Kết nối, bộ điều hợp, Kamelet mẫu

| Mã | Loại, mục đích | HTTT | Trạng thái nạp sẵn | Dùng cho |
|---|---|---|---|---|
| C-NDXP (`ndxp-ho-tich`) | `http-rest`, OAuth2, chỉ đọc | `HT-NDXP` | `ACTIVE`; TEST, PROD bật | Đa số ca REST, sức khỏe |
| C-QLVB (`qlvb-soap`) | `soap`, WS-Security UsernameToken | `HT-QLVB` | `ACTIVE`; TEST bật | SOAP |
| C-DKKD (`dkkd-db`) | `db-flow` PostgreSQL, đọc ghi, `allowedSchemas = dkkd, dm` | `HT-DKKD` | `ACTIVE`; TEST, PROD bật | Tài khoản CSDL |
| C-SFTP (`bhxh-sftp`) | `sftp`, khóa SSH | `HT-BHXH` | `ACTIVE`; TEST bật | Tệp |
| C-MQ (`tnmt-amqp`) | `amqp` | `HT-TNMT` | `ACTIVE`; TEST bật | Hàng đợi |
| C-MAIL (`mot-cua-mail`) | `smtp`, `imap` | `HT-MOTCUA` | `ACTIVE`; TEST bật | Thư |
| C-CDC (`dkkd-cdc`) | `cdc-debezium` PostgreSQL | `HT-DKKD` | `ACTIVE`; TEST bật | CDC |
| C-NEW | Chưa có, tạo trong ca | `HT-NDXP` | — | Tạo mới |
| A-DVC (`dvc-rest`) | Bộ điều hợp REST 12 thao tác | `HT-DVC` | v7 `APPROVED` | Phân trang, so sánh |
| A-QLVB (`qlvb-soap`) | SOAP 6 thao tác | `HT-QLVB` | v3 `APPROVED`, v4 `DRAFT` | SOAP, duyệt |
| A-CDC (`dkkd-cdc`) | CDC 2 bảng | `HT-DKKD` | v1 `APPROVED`, CDC `STOPPED` | CDC |
| K-MST (`dh-t68-tra-cuu-mst-action`) | Kamelet `TENANT` | — | 1.0.0 `APPROVED`, 3 luồng dùng | Kamelet |

Mọi bí mật nạp sẵn có dạng `DH-CANARY-{mã dữ liệu}-{uuid}` để TS-05-31 dò được.

### 2.4. HTTT giả lập

| Mã | Thành phần | Hành vi điều khiển được |
|---|---|---|
| SIM-HTTP | WireMock `ndxp.sim.test` | Trả 200, 401, 429 có `Retry-After`, 5xx, chậm n ms, phân trang 1…600 trang, chứng thư tự ký |
| SIM-SOAP | WireMock SOAP `qlvb.sim.test` | WSDL v1, v2 (đổi thao tác), SOAP Fault theo mã |
| SIM-PG | PostgreSQL 16 `dkkd.sim.test`, `wal_level = logical`, publication `dh_dkkd` | CSDL nguồn tài khoản động, CDC |
| SIM-PG-BAD | PostgreSQL 16, `wal_level = replica` | Điều kiện CDC không đạt |
| SIM-MY | MySQL 8.0 `binlog_format = ROW` | CDC MySQL |
| SIM-SFTP | `atmoz/sftp` | Tệp ghi dần, tệp lỗi |
| SIM-MQ | RabbitMQ 3.13 | Ngắt kết nối |
| SIM-MAIL | GreenMail | SMTP, IMAP |
| SIM-LDAP | OpenLDAP | Danh bạ mẫu |

### 2.5. Tệp mẫu

| Mã | Nội dung |
|---|---|
| F-CTX | Gói `camel-context.xml` + `application.properties` của Bus cũ: 7 kết nối (HTTP, SOAP, JDBC, SFTP, JMS), 2 URI có mật khẩu nhúng, 1 scheme `jt400` không hỗ trợ |
| F-OAS | OpenAPI 3.1 của DVC: 14 đường dẫn, 2 `oneOf` |
| F-WSDL | WSDL 1.1 + 3 XSD của QLVB (ZIP) |
| F-CSV-1M | CSV 1 triệu dòng, `windows-1258`, 3 dòng thiếu trường bắt buộc |
| F-FIX | Tệp cố định độ rộng BHXH 2.000 dòng |
| F-XML | Phản hồi SOAP có phần tử lặp một lần và thuộc tính |
| F-KAM-OK, F-KAM-BAD | Kamelet hợp lệ; Kamelet dùng `groovy`, `#class:`, URI `http://` trực tiếp |
| F-EICAR | Tệp thử mã độc EICAR |

### 2.6. Nguyên tắc dữ liệu

Không dùng số định danh, số điện thoại thật. Mẫu dữ liệu cá nhân dùng dải số giả `0999…`. Mỗi ca tạo đối tượng có tiền tố `tc-` và tự dọn sau khi chạy (trừ ca cần giữ mã để kiểm BR-05-004).

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

| Máy trạng thái | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Kết nối | DRAFT → ACTIVE → SUSPENDED → ACTIVE → RETIRED | RETIRED → *; DRAFT → SUSPENDED |
| Giá trị môi trường | CONFIGURED → ENABLED; CONFIGURED → PENDING_APPROVAL → ENABLED; ENABLED → DISABLED | Bật khi chưa kiểm tra đạt 24 giờ |
| Phiên bản bộ điều hợp | DRAFT → SUBMITTED → APPROVED → SUPERSEDED; SUBMITTED → DRAFT (từ chối) | Sửa ở SUBMITTED, APPROVED |
| CDC | STOPPED → SNAPSHOTTING → STREAMING → PAUSED → STREAMING; STREAMING → PAUSED_SCHEMA → STREAMING; * → FAILED | Tiếp tục ở PAUSED_SCHEMA khi còn thay đổi chờ |
| Kamelet | DRAFT → SUBMITTED → APPROVED → DEPRECATED; APPROVED → WITHDRAWN | Duyệt khi còn vi phạm chặn; sửa ở APPROVED |
| Tài khoản CSDL | REQUESTED → ISSUED (đọc); REQUESTED → CONSENTED → ISSUED (ghi); ISSUED → REVOKED; ISSUED → EXPIRED | ISSUED khi chưa CONSENTED (ghi) |

## 4. Kịch bản và test case chức năng

### TS-05-01 · Loại kết nối và khai báo kết nối

**Mục tiêu.** Xác nhận khai báo kết nối thay "Thêm chương trình" và "Sửa host, port" của Bus cũ: loại kết nối có lược đồ tham số, mã bất biến, HTTT phải hoạt động, tham số không chứa bí mật.

**Phủ.** FR-05-001, 004, 006; UC-05-01; API-05-001, 002, 004, 006; UI-05-03; BR-05-004, 013; LGC-BUS-011, 040.

#### TC-05-### · Liệt kê loại kết nối và lược đồ tham số <!--k:type-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-001 · API-05-001, 002 · UI-05-03
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-T68-TA đã tắt loại `ldap` ở T68.
- **Bước**
  1. `GET /connection-types`.
  2. `GET /connection-types/http-rest`.
- **Mong đợi** Bước 1 trả `200`, có `http-rest`, `soap`, `db-flow`, `sftp`, `amqp`, `smtp`, `cdc-debezium`; `ldap` có `enabled = false`. Bước 2 trả `paramsSchema` (JSON Schema có `if/then` theo `auth`), `secretKeys` gồm `clientSecret`, `password`, `apiKey`, `clientKey`; `paramsSchema` không chứa khóa nào trong `secretKeys`.

#### TC-05-### · Tạo kết nối REST hợp lệ ở trạng thái Nháp <!--k:conn-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-004 · API-05-004, 005 · UI-05-03 · UC-05-01 · LGC-BUS-011
- **Tiền điều kiện / dữ liệu** U-T68-IE1; HTTT `HT-NDXP` `ACTIVE`.
- **Bước**
  1. Mở UI-05-03, chọn loại REST/HTTP, nhập mã `tc-ndxp-moi`, tên, HTTT `HT-NDXP`, mục đích Chỉ đọc; bấm "Tạo".
  2. `GET /connections/tc-ndxp-moi`.
- **Mong đợi** Bước 1 gọi `POST /connections` trả `201`, `Location`, `ETag`; màn sang bước 3. Bước 2: `status = DRAFT`, `environments` rỗng, `allowedActions` có `EDIT`, `CONFIGURE_ENV`; `disabledReasons` không rỗng cho `ENABLE`. KT: có (`CONNECTION_CREATE`). EVT: không.

#### TC-05-### · Tạo kết nối sai mã, trùng mã, HTTT không hoạt động, loại tắt <!--k:conn-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-004 · API-05-004 · ERR-05-002, 003, 004, 005, 012 · BR-05-004
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-T68-VW; kết nối `tc-cu` đã `RETIRED`.
- **Bước**
  1. `POST /connections` với `connectionCode = "TC_Hoa"`.
  2. `POST /connections` với mã `ndxp-ho-tich`.
  3. `POST /connections` với mã `tc-cu`.
  4. `POST /connections` với `systemCode = "HT-DUNG"` (HTTT `SUSPENDED`).
  5. `POST /connections` với `typeCode = "ldap"`.
  6. U-T68-VW gửi thân hợp lệ.
- **Mong đợi** Bước 1 `400` ERR-05-003 `errors[0].path = connectionCode`. Bước 2, 3 `409` ERR-05-002 (mã đã ngừng dùng cũng không dùng lại). Bước 4 `422` ERR-05-005. Bước 5 `422` ERR-05-004. Bước 6 403-PQ. KT: không.

#### TC-05-### · Bí mật gửi qua trường tham số bị chặn <!--k:conn-param-secret-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-005, 011 · API-05-011 · ERR-05-006 · BR-05-001
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` từ [[tc:conn-create]].
- **Bước**
  1. `PUT /connections/tc-ndxp-moi/environments/TEST` với `params = {"baseUrl":"https://ndxp.sim.test","auth":"OAUTH2_CLIENT_CREDENTIALS","clientSecret":"DH-CANARY-TC-a1"}`.
  2. Lặp với khóa `password`, `token`, `x-api-key` lồng trong `headers`.
- **Mong đợi** Mọi lần trả `422` ERR-05-006, `errors[]` chỉ chứa tên khóa, không chứa giá trị. Không có dòng nào trong `connection_environment` đổi. Mồi sạch với `DH-CANARY-TC-a1`.

#### TC-05-### · Sửa thông tin chung; mã, loại, HTTT bất biến <!--k:conn-patch-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-006 · API-05-006 · ERR-05-003, 007 · BR-05-004
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IE2; `tc-ndxp-moi`.
- **Bước**
  1. IE1 `PATCH` tên, mô tả, nhãn với `If-Match` đúng.
  2. IE2 `PATCH` với `If-Match` cũ của bước 1.
  3. IE1 `PATCH` với `{"typeCode":"soap"}`, rồi `{"systemCode":"HT-QLVB"}`.
- **Mong đợi** Bước 1 `200`, `ETag` mới, KT: có (`CONNECTION_UPDATE`, có khác biệt), EVT: `connection.changed`. Bước 2 `412` ERR-05-007. Bước 3 `400` ERR-05-003, dữ liệu không đổi.

#### TC-05-### · Máy chủ ngoài danh sách egress và dải nội bộ cấm <!--k:conn-egress-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-005 · BR-05-013 · API-05-011 · ERR-05-003
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi`.
- **Bước**
  1. `PUT …/environments/TEST` với `baseUrl = https://ngoai.example.org`.
  2. Với `baseUrl = https://169.254.169.254`, `https://10.96.0.1`, `https://localhost`.
- **Mong đợi** Bước 1 `200` nhưng `warnings[]` có "Cần mở egress cho ngoai.example.org" và có đề nghị bổ sung egress cho TA; bật môi trường bị chặn tới khi egress có. Bước 2 `400` ERR-05-003 rule `ssrf-blocked`.

### TS-05-02 · Giá trị môi trường và bí mật

**Mục tiêu.** Xác nhận tham số và bí mật theo môi trường được tách, bí mật ghi một chiều vào OpenBao và không bao giờ trả lại.

**Phủ.** FR-05-005, 011; UC-05-01; API-05-010, 011, 012; UI-05-02, 03; BR-05-001, 003, 010; NFR-05-011.

#### TC-05-### · Khai tham số và ghi bí mật cho TEST <!--k:env-secret-write-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-005, 011 · API-05-010, 011, 012 · UI-05-02, 03 · NFR-05-011
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi`.
- **Bước**
  1. `PUT …/environments/TEST` với tham số OAuth2 hợp lệ.
  2. `PUT …/environments/TEST/secret` với `{"clientId":"tc","clientSecret":"DH-CANARY-TC-b1"}`.
  3. `GET …/environments`.
  4. Đọc OpenBao `kv/dh/t68/conn/tc-ndxp-moi/TEST` bằng tài khoản kiểm thử.
  5. Mở UI-05-02 tab Môi trường.
- **Mong đợi** Bước 2 `204`. Bước 3: TEST `CONFIGURED`, `secret = {version:1, writtenBy, writtenAt, keys:["clientId","clientSecret"]}`, không có giá trị. Bước 4 thấy giá trị. Bước 5 ô bí mật trống, nhãn "Đã khai · phiên bản 1 · …", không có nút hiện, sao chép. Mồi sạch. KT: có (`SECRET_WRITE`, chỉ tên khóa, phiên bản).

#### TC-05-### · Thiếu khóa bí mật bắt buộc, khóa lạ <!--k:env-secret-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-005 · API-05-012 · ERR-05-003, 014
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` TEST có tham số `auth = BASIC`.
- **Bước**
  1. `PUT …/TEST/secret` với chỉ `username`.
  2. `PUT …/TEST/secret` với `{"username":"a","password":"b","extra":"c"}`.
  3. `POST …/environments/TEST:enable` khi chưa có bí mật.
- **Mong đợi** Bước 1 `400` ERR-05-003 (`password` bắt buộc). Bước 2 `400` ERR-05-003 (khóa không có trong `secretKeys`). Bước 3 `409` ERR-05-014.

#### TC-05-### · dh-integration chỉ ghi được bí mật, không đọc được <!--k:bao-policy-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-05-011 · BR-05-003 · NFR-05-011
- **Tiền điều kiện / dữ liệu** Token OpenBao của `dh-integration` T68; token `dh-runtime` T68, T01.
- **Bước**
  1. Bằng token `dh-integration`, `GET kv/data/dh/t68/conn/ndxp-ho-tich/PROD`.
  2. Bằng token `dh-runtime` T01, đọc cùng đường.
  3. Bằng token `dh-runtime` T68, đọc cùng đường.
- **Mong đợi** Bước 1, 2 `403` từ OpenBao. Bước 3 `200`. Nhật ký kiểm toán OpenBao có cả ba lần.

#### TC-05-### · Sửa tham số PROD đang bật không gián đoạn <!--k:env-prod-pending-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-005, 007 · BR-05-010 · API-05-011, 013 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-NDXP PROD bật, luồng mẫu gọi C-NDXP mỗi giây.
- **Bước**
  1. `PUT …/ndxp-ho-tich/environments/PROD` đổi `timeoutMs` 10000 → 8000.
  2. `GET …/environments`.
  3. Trong 2 phút, đo lượt gọi của luồng mẫu.
- **Mong đợi** Bước 2: PROD vẫn `ENABLED` với tham số cũ, có `pendingParams`, trạng thái chờ `PENDING_APPROVAL` sau khi xin bật. Bước 3: 0 lượt lỗi, runtime dùng `timeoutMs = 10000`. UI-05-02 hiện khối "Bản chờ duyệt" với `CMP-DiffViewer`.

### TS-05-03 · Kiểm tra kết nối

**Mục tiêu.** Xác nhận "Thêm chương trình có kiểm tra kết nối" của Bus cũ được thay bằng kiểm tra theo bước, không tác dụng phụ, có nguyên nhân và hướng dẫn tiếng Việt.

**Phủ.** FR-05-010; UC-05-02; API-05-017, 018, 019; UI-05-04; ERR-05-018, 019; NFR-05-004; LGC-BUS-013.

#### TC-05-### · Kiểm tra đạt, đủ bước, có hiệu lực 24 giờ <!--k:test-pass-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-010 · API-05-017, 019 · UI-05-04 · NFR-05-004 · LGC-BUS-013
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` TEST đủ tham số, bí mật; SIM-HTTP trả 200 ở `/health`.
- **Bước**
  1. Mở UI-05-02, chọn "Kiểm tra ▾ TEST".
  2. Theo dõi drawer UI-05-04 tới khi xong.
  3. `GET …/tests/{testId}`.
- **Mong đợi** Bước 1 gọi `POST …/environments/TEST/tests` trả `202`, `Location`. Drawer hiện lần lượt các bước DNS, TCP, TLS, xác thực (lấy token OAuth2), gọi thăm dò; mỗi bước ✓ kèm thời lượng. Tổng ≤ 15 giây. Bước 3: `result = PASSED`, `validUntil = startedAt + 24h`, `paramsHash`, `secretVersion = 1`. SIM-HTTP chỉ nhận yêu cầu `GET /health` và yêu cầu token, không có yêu cầu ghi. KT: có (`CONNECTION_TEST`).

#### TC-05-### · Kiểm tra không đạt theo từng nguyên nhân <!--k:test-causes-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-010 · API-05-017, 019 · UI-05-04 · ERR-05-102, 103, 104, 119 · BR-05-011
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` TEST.
- **Bước** Lặp với mỗi cấu hình SIM-HTTP:
  1. Tên miền không phân giải.
  2. Cổng đóng.
  3. Chứng thư tự ký.
  4. Máy chủ chỉ chấp nhận TLS 1.0.
  5. Endpoint token trả 401.
  6. `/health` chậm 30 giây (`timeoutMs = 5000`).
- **Mong đợi** Mỗi lần `result = FAILED` và bước lỗi đúng: 1 DNS `cause = DNS_NXDOMAIN`; 2 TCP `CONNECTION_REFUSED`; 3 TLS `UNTRUSTED_CERT`; 4 TLS `TLS_VERSION` (BR-05-011); 5 xác thực `AUTH_REJECTED`; 6 gọi thăm dò `TIMEOUT` kết thúc ≤ 10 giây. Mọi bước sau bước lỗi `SKIPPED`. `hint` tiếng Việt khớp bảng nguyên nhân FRS §5.2.1. Không bước nào ghi giá trị bí mật vào `detail`.

#### TC-05-### · Kiểm tra trùng lúc và vượt hạn mức <!--k:test-concurrent-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-010 · API-05-017 · ERR-05-018, 019
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `05.test.rate-per-hour = 20`.
- **Bước**
  1. Gửi hai `POST …/TEST/tests` cách nhau 100 ms khi SIM-HTTP chậm 5 giây.
  2. Gửi 21 lần trong một giờ.
- **Mong đợi** Bước 1 lần hai `409` ERR-05-018 với `testId` của lần đang chạy. Bước 2 lần 21 `429` ERR-05-019, `retryAfterSeconds` > 0.

#### TC-05-### · Kiểm tra không tác dụng phụ với CSDL và SFTP <!--k:test-no-side-effect-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-05-010 · API-05-017
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-DKKD TEST, C-SFTP TEST; ghi nhật ký câu lệnh SIM-PG (`log_statement = all`), nhật ký SIM-SFTP.
- **Bước**
  1. Chạy kiểm tra C-DKKD TEST.
  2. Chạy kiểm tra C-SFTP TEST.
- **Mong đợi** SIM-PG chỉ nhận `SELECT 1` và truy vấn danh mục quyền; không `INSERT`, `UPDATE`, `CREATE`. SIM-SFTP chỉ nhận `ls` thư mục khai báo; không tạo, xóa tệp.

### TS-05-04 · Bật môi trường và duyệt PROD

**Mục tiêu.** Xác nhận bật TEST, STAGING cần kiểm tra đạt; bật PROD cần duyệt bốn mắt; đóng băng PROD có hiệu lực.

**Phủ.** FR-05-007; UC-05-03; API-05-013…016; UI-05-02, 17; BR-05-006, 009; ERR-05-009, 011, 031; EVT-05-01.

#### TC-05-### · Bật TEST sau kiểm tra đạt <!--k:enable-test-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-007 · API-05-013 · BR-05-006 · EVT-05-01
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` có kiểm tra TEST đạt từ [[tc:test-pass]].
- **Bước** `POST …/environments/TEST:enable`.
- **Mong đợi** `200`, TEST `ENABLED`, kết nối `DRAFT` → `ACTIVE`. EVT: `connection.enabled` (không có tham số bí mật trong `data`). KT: có (`ENV_ENABLE`).

#### TC-05-### · Bật khi chưa kiểm tra, kiểm tra quá 24 giờ, đổi bí mật sau kiểm tra <!--k:enable-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-007 · API-05-013 · ERR-05-009 · BR-05-006
- **Tiền điều kiện / dữ liệu** U-T68-IE1; ba kết nối thử `tc-e1` (chưa kiểm tra), `tc-e2` (đạt 25 giờ trước, đồng hồ giả), `tc-e3` (đạt rồi ghi bí mật mới).
- **Bước** `POST …/TEST:enable` với từng kết nối.
- **Mong đợi** Cả ba `409` ERR-05-009 với `lastPassedAt` (rỗng với `tc-e1`); `disabledReasons.ENABLE` ở `GET` nêu đúng lý do.

#### TC-05-### · Xin bật PROD, người khác duyệt <!--k:enable-prod-approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-007 · API-05-013, 015 · UI-05-17 · UC-05-03 · EVT-05-01
- **Tiền điều kiện / dữ liệu** U-T68-IE1 (người xin, người ghi bí mật PROD), U-T68-IA1; `tc-ndxp-moi` PROD có kiểm tra đạt.
- **Bước**
  1. IE1 `POST …/PROD:enable` với lý do.
  2. IA1 mở "Việc của tôi", mục `ph05.env-enable`, xem khác biệt, bấm "Duyệt".
- **Mong đợi** Bước 1 `202`, PROD `PENDING_APPROVAL`, IA1 nhận thông báo. Bước 2 gọi `POST …/PROD:approve` trả `200`, PROD `ENABLED`. Khung duyệt chỉ hiện "Bí mật phiên bản 1, ghi bởi An", không có giá trị. EVT: `connection.enabled` với `env = PROD`. KT: có (`ENV_ENABLE_REQUEST`, `ENV_ENABLE_APPROVE`).

#### TC-05-### · Tự duyệt, người ghi bí mật duyệt, từ chối <!--k:enable-prod-4eyes-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-007 · API-05-015, 016 · ERR-05-011, 038 · BR-05-009
- **Tiền điều kiện / dữ liệu** U-T68-IA2 xin bật PROD của `tc-e4`; U-T68-IA1 đã ghi bí mật PROD của `tc-e5`, IE1 xin bật.
- **Bước**
  1. IA2 `POST …/tc-e4/environments/PROD:approve`.
  2. IA1 `POST …/tc-e5/environments/PROD:approve`.
  3. IA1 `POST …/tc-e4/environments/PROD:reject` không lý do; rồi có lý do.
- **Mong đợi** Bước 1, 2 `403` ERR-05-011 nêu vai trò trùng ("người đề nghị", "người ghi bí mật"); trạng thái giữ `PENDING_APPROVAL`. Bước 3 lần đầu `400` ERR-05-038; lần sau `200`, PROD về `CONFIGURED`, IA2 nhận thông báo với lý do.

#### TC-05-### · Đóng băng PROD chặn ghi và bật <!--k:prod-freeze-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-05-005, 007 · API-05-011, 012, 013 · ERR-05-031 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-TA bật đóng băng PROD 2 giờ; U-T68-IE1.
- **Bước**
  1. `PUT …/PROD`, `PUT …/PROD/secret`, `POST …/PROD:enable`.
  2. `PUT …/TEST`.
  3. Mở UI-05-02.
- **Mong đợi** Bước 1 mỗi lệnh `423` ERR-05-031 với thời điểm hết đóng băng. Bước 2 `200`. Bước 3 có `CMP-Banner` đóng băng, nút ghi PROD vô hiệu với lý do.

### TS-05-05 · Xoay vòng bí mật

**Mục tiêu.** Xác nhận xoay bí mật không gián đoạn, có kiểm tra trước, có thời gian chuyển tiếp.

**Phủ.** FR-05-012; UC-05-04; API-05-020, 021; UI-05-02; BR-05-007, 008; ERR-05-036; EVT-05-03.

#### TC-05-### · Xoay bí mật PROD không gián đoạn <!--k:rotate-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-012 · API-05-020, 021 · BR-05-007 · EVT-05-03 · UC-05-04
- **Tiền điều kiện / dữ liệu** U-T68-TO; C-NDXP PROD bí mật v2; SIM-HTTP chấp nhận cả v2 và v3; luồng mẫu gọi mỗi giây.
- **Bước**
  1. `POST …/ndxp-ho-tich/environments/PROD:rotate-secret` với bí mật v3, chuyển tiếp 1 giờ.
  2. Theo dõi kiểm tra `ROTATION`.
  3. Cho SIM-HTTP thôi chấp nhận v2.
  4. Đồng hồ giả vượt 1 giờ.
- **Mong đợi** Bước 2 đạt; OpenBao có v3, v2 vẫn còn. EVT: `connection.secret-rotated` (chỉ số phiên bản). Bước 1–3: 0 lượt lỗi của luồng; runtime dùng v3 trước. Bước 4: v2 bị hủy ở OpenBao, `rotations[0].status = COMPLETED`.

#### TC-05-### · Bí mật mới sai thì giữ nguyên bí mật cũ <!--k:rotate-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-012 · API-05-020 · ERR-05-036 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-TO; C-NDXP PROD.
- **Bước**
  1. Xoay với bí mật SIM-HTTP từ chối.
  2. Trong khi một lần xoay khác đang chuyển tiếp, gửi lần xoay mới.
- **Mong đợi** Bước 1: kiểm tra `ROTATION` không đạt ở bước xác thực; OpenBao không có phiên bản mới dùng được (phiên bản tạm bị hủy), `currentVersion` giữ nguyên; hộp xoay nói "Bí mật cũ vẫn đang dùng". Bước 2 `409` ERR-05-036.

#### TC-05-### · Lỗi xác thực không thử lại dồn dập <!--k:auth-retry-limit-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-012, 033 · BR-05-008 · ERR-05-102
- **Tiền điều kiện / dữ liệu** C-NDXP TEST; SIM-HTTP luôn trả 401.
- **Bước** Luồng mẫu gọi 100 lần trong 2 phút.
- **Mong đợi** SIM-HTTP nhận tối đa 2 yêu cầu lấy token trong 5 phút (một lần thử lại); các lượt còn lại trả ERR-05-102 ngay, không gọi ra.

### TS-05-06 · Tạm ngừng, tiếp tục, ngừng dùng kết nối

**Mục tiêu.** Xác nhận cán bộ ATTT, vận hành tạm ngừng được kết nối khi có sự cố với hiệu lực nhanh, và ngừng dùng bị chặn khi còn nơi dùng.

**Phủ.** FR-05-008; UC-05-05, 06; API-05-007, 008, 009; UI-05-02; BR-05-012; ERR-05-008, 010, 118; EVT-05-04; NFR-05-006.

#### TC-05-### · Tạm ngừng có hiệu lực trong 30 giây <!--k:suspend-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-008 · API-05-007 · EVT-05-04 · NFR-05-006 · ERR-05-118 · UC-05-05
- **Tiền điều kiện / dữ liệu** U-T68-SO; C-NDXP; luồng mẫu chạy ba bản sao.
- **Bước**
  1. `POST …/ndxp-ho-tich:suspend` với lý do, mã sự cố `SC-2026-11-01`.
  2. Đo thời điểm lượt mới cuối cùng tới SIM-HTTP.
- **Mong đợi** Bước 1 `200`, `SUSPENDED`. EVT: `connection.state-changed`. Bước 2 ≤ 30 giây sau lệnh; lượt mới của luồng nhận ERR-05-118. KT: có (`CONNECTION_SUSPEND`, mã sự cố).

#### TC-05-### · Tiếp tục sau tạm ngừng của SO <!--k:resume-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-008 · API-05-008 · ERR-05-008, 012
- **Tiền điều kiện / dữ liệu** C-NDXP do U-T68-SO tạm ngừng; U-T68-TO; U-T68-SO.
- **Bước**
  1. TO `POST …:resume`.
  2. SO `POST …:resume`.
  3. SO `POST …:resume` lần nữa.
- **Mong đợi** Bước 1 403-PQ (tạm ngừng do SO chỉ SO tiếp tục). Bước 2 `200`, `ACTIVE`. Bước 3 `409` ERR-05-008.

#### TC-05-### · Ngừng dùng bị chặn khi còn nơi dùng <!--k:retire-in-use-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-008, 013 · API-05-009, 025 · ERR-05-010 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-NDXP được 4 phiên bản luồng dùng.
- **Bước**
  1. `POST …/ndxp-ho-tich:retire` với lý do.
  2. Mở UI-05-02, bấm "Ngừng dùng".
- **Mong đợi** Bước 1 `409` ERR-05-010 với `usages[]` 4 mục. Bước 2 nút vô hiệu với lý do "Còn 4 nơi đang dùng".

#### TC-05-### · Ngừng dùng, hủy bí mật sau 30 ngày <!--k:retire-ok-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, IT
- **Truy vết** FR-05-008 · API-05-009 · BR-05-012, 004 · EVT-05-04
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-ndxp-moi` không nơi dùng.
- **Bước**
  1. `POST …/tc-ndxp-moi:retire` với lý do.
  2. Đồng hồ giả +29 ngày, kiểm OpenBao.
  3. Đồng hồ giả +31 ngày, kiểm OpenBao.
  4. `POST /connections` với mã `tc-ndxp-moi`.
- **Mong đợi** Bước 1 `200`, `RETIRED`, UI-05-02 chỉ đọc có banner ngày hủy bí mật. Bước 2 bí mật còn. Bước 3 mọi phiên bản bị xóa (`metadata` cũng xóa). Bước 4 `409` ERR-05-002.

### TS-05-07 · Danh sách, chi tiết, lịch sử, xuất

**Mục tiêu.** Xác nhận tìm, lọc, xem kết nối như Bus cũ và thêm sức khỏe, tuổi bí mật; xuất không có bí mật.

**Phủ.** FR-05-002, 003, 016, 017; API-05-003, 005, 026, 027; UI-05-01, 02; BR-05-014.

#### TC-05-### · Lọc, sắp xếp, mặc định Mất kết nối đứng đầu <!--k:conn-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-05-002 · API-05-003 · UI-05-01 · BR-05-014
- **Tiền điều kiện / dữ liệu** U-T68-VW; 40 kết nối thử, 2 `UNHEALTHY`, 3 `DEGRADED` ở PROD.
- **Bước**
  1. `GET /connections` không sắp xếp.
  2. `GET /connections?q=ndxp&typeCode=http-rest&health=UNHEALTHY&env=PROD`.
  3. Mở UI-05-01, bấm bộ lọc nhanh "Bí mật quá hạn".
- **Mong đợi** Bước 1: 2 mục đầu `UNHEALTHY`, rồi 3 `DEGRADED`; có `facets`. Bước 2 chỉ mục khớp. Bước 3 URL có `secretOverdue=true`, bảng chỉ còn kết nối có tuổi bí mật ≥ 90 ngày.

#### TC-05-### · Chi tiết kết nối trả allowedActions theo người xem <!--k:conn-detail-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-003 · API-05-005 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-VW, U-T68-IE1; C-NDXP.
- **Bước** VW và IE1 cùng `GET /connections/ndxp-ho-tich`.
- **Mong đợi** Cả hai `200`; với VW `allowedActions` rỗng; với IE1 có `EDIT`, `TEST`. Không trường nào chứa giá trị bí mật.

#### TC-05-### · Chi tiết kết nối của tenant khác trả 404-ẩn <!--k:conn-404-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-003 · API-05-005 · ERR-05-001 · BR-05-002
- **Tiền điều kiện / dữ liệu** U-T01-IE; kết nối `tc-chi-t68` chỉ có ở T68.
- **Bước**
  1. U-T01-IE `GET /connections/tc-chi-t68`.
  2. U-T01-IE `GET /connections/khong-co`.
- **Mong đợi** Cả hai 404-ẩn, thân giống nhau trừ `traceId`.

#### TC-05-### · Lịch sử thay đổi không có bí mật <!--k:conn-history-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-016 · API-05-026 · UI-05-02
- **Tiền điều kiện / dữ liệu** U-T68-AU; `tc-ndxp-moi` sau TS-05-01…05.
- **Bước** `GET /connections/tc-ndxp-moi/history`.
- **Mong đợi** Có các mục tạo, sửa, ghi bí mật (chỉ phiên bản), kiểm tra, bật, xin bật, duyệt theo thời gian; khác biệt tham số có; mồi sạch.

#### TC-05-### · Xuất CSV không chứa bí mật, đúng bộ lọc <!--k:conn-export-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-05-017 · API-05-027 · UI-05-01
- **Tiền điều kiện / dữ liệu** U-T68-IE1.
- **Bước** `GET /connections:export?typeCode=http-rest`.
- **Mong đợi** `200` `text/csv; charset=utf-8` có BOM; chỉ dòng REST; cột không có giá trị bí mật; mồi sạch trong tệp. KT: có (`CONNECTION_EXPORT`).

### TS-05-08 · Cấp sử dụng và nơi dùng

**Mục tiêu.** Xác nhận kết nối chỉ được dùng ở không gian làm việc hoặc luồng đã được cấp.

**Phủ.** FR-05-009, 013; UC-05-07; API-05-022, 023, 024, 025; UI-05-02; ERR-05-013, 033; EVT-05-05.

#### TC-05-### · Cấp cho không gian, có hạn; thu hồi <!--k:grant-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-009 · API-05-022, 023, 024 · EVT-05-05 · UC-05-07
- **Tiền điều kiện / dữ liệu** U-T68-IE1; không gian `ho-tich` ở PH-04.
- **Bước**
  1. `POST …/tc-ndxp-moi/grants` với `scope = WORKSPACE`, `scopeCode = ho-tich`, `envs = [TEST]`, `expiresAt` +30 ngày.
  2. `GET …/grants`.
  3. `DELETE …/grants/{id}`.
- **Mong đợi** Bước 1 `201`. EVT: `connection.grant-changed`. Bước 2 có mục. Bước 3 `204`, EVT lần nữa. KT: có (`GRANT_CREATE`, `GRANT_REVOKE`).

#### TC-05-### · Cấp cho không gian không tồn tại; db-flow cấp không gian <!--k:grant-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-009, 023 · API-05-023 · ERR-05-033, 003 · BR-05-018
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-DKKD; `05.dbflow.allow-workspace-scope = false`.
- **Bước**
  1. `POST …/tc-ndxp-moi/grants` với `scopeCode = khong-co`.
  2. `POST …/dkkd-db/grants` với `scope = WORKSPACE`.
- **Mong đợi** Bước 1 `422` ERR-05-033. Bước 2 `400` ERR-05-003 rule `dbflow-flow-scope-only`.

#### TC-05-### · Nơi dùng liệt kê phiên bản luồng và bộ điều hợp <!--k:usages-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-013 · API-05-025, 062 · UI-05-02, 09
- **Tiền điều kiện / dữ liệu** U-T68-VW; C-NDXP; A-DVC.
- **Bước** `GET /connections/ndxp-ho-tich/usages`; `GET /adapters/dvc-rest/usages`.
- **Mong đợi** Danh sách khớp chỉ mục `usage_ref` (luồng, phiên bản, môi trường, đã triển khai), đếm khớp `usageCount` ở danh sách.

### TS-05-09 · Nhập kết nối từ hệ cũ

**Mục tiêu.** Xác nhận đọc gói Context XML của Bus cũ để đề xuất kết nối, bỏ mật khẩu rõ, không chạy mã.

**Phủ.** FR-05-018; UC-05-11; API-05-028, 029, 030; UI-05-06; BR-05-025; ERR-05-024, 034, 035; LGC-BUS-011, 040.

#### TC-05-### · Phân tích gói Bus cũ ra đề xuất kết nối <!--k:legacy-parse-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-018 · API-05-028, 029 · UI-05-06 · BR-05-025 · UC-05-11 · LGC-BUS-040
- **Tiền điều kiện / dữ liệu** U-T68-IE1; F-CTX.
- **Bước**
  1. Tải F-CTX ở UI-05-06.
  2. Chờ `CMP-JobProgress` xong; `GET /connections/legacy-imports/{jobId}`.
- **Mong đợi** `proposals` có 6 kết nối (HTTP, SOAP, JDBC, SFTP, JMS) với tham số tìm được và vị trí trong tệp; `findings` có 2 mục `EMBEDDED_PASSWORD` (chỉ vị trí, không giá trị) và 1 `UNSUPPORTED_SCHEME` (`jt400`). Chuỗi mật khẩu trong F-CTX không có ở phản hồi, log, bảng `legacy_import_job`. Tệp gốc không còn ở kho sau khi phân tích.

#### TC-05-### · Tạo kết nối nháp từ đề xuất và tải bảng ánh xạ <!--k:legacy-commit-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-018 · API-05-030 · UI-05-06
- **Tiền điều kiện / dữ liệu** Kết quả [[tc:legacy-parse]].
- **Bước** `POST …/legacy-imports/{jobId}:commit` với 5 đề xuất, mỗi đề xuất có HTTT.
- **Mong đợi** `200`, 5 kết nối `DRAFT`, chưa có bí mật; `connectionMap` (URI cũ → mã mới) tải được cho FR-04-082.

#### TC-05-### · Tệp sai định dạng, quá lớn, có mã độc <!--k:legacy-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-018 · API-05-028 · ERR-05-024, 034
- **Tiền điều kiện / dữ liệu** U-T68-IE1; tệp `.xml` hỏng; ZIP 11 MiB; F-EICAR trong ZIP.
- **Bước** Tải từng tệp.
- **Mong đợi** Hỏng `400` ERR-05-024; quá lớn `413` ERR-05-024; mã độc `422` ERR-05-034. Không job nào ở trạng thái thành công.

### TS-05-10 · Sức khỏe kết nối và bộ điều hợp

**Mục tiêu.** Xác nhận phát hiện mất kết nối chủ động, suy giảm thụ động, cảnh báo và màn tổng quan.

**Phủ.** FR-05-019…022; UC-05-12; API-05-033, 034, 061, 093; UI-05-07; EVT-05-06; NFR-05-005.

#### TC-05-### · Phát hiện mất kết nối trong 3 phút <!--k:health-down-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, Chaos
- **Truy vết** FR-05-019, 021 · API-05-034 · EVT-05-06 · NFR-05-005 · UC-05-12
- **Tiền điều kiện / dữ liệu** U-T68-TO; C-NDXP PROD `HEALTHY`.
- **Bước**
  1. Ngắt SIM-HTTP lúc t0.
  2. Theo dõi `GET …/ndxp-ho-tich/health?env=PROD`.
  3. Bật lại SIM-HTTP.
- **Mong đợi** Trạng thái `UNHEALTHY` ≤ t0 + 3 phút; EVT: `health.changed` một lần mỗi lần đổi mức (không lặp mỗi chu kỳ); TO nhận cảnh báo PH-13. Bước 3 về `HEALTHY` sau hai chu kỳ đạt, EVT lần nữa.

#### TC-05-### · Suy giảm thụ động theo p95 so với nền <!--k:health-degraded-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** RT, API
- **Truy vết** FR-05-020 · API-05-034
- **Tiền điều kiện / dữ liệu** C-NDXP có `health_baseline` p95 = 400 ms; luồng mẫu 10 lượt/giây.
- **Bước** SIM-HTTP chậm thêm 600 ms trong 10 phút.
- **Mong đợi** Sức khỏe `DEGRADED` với lý do "p95 gấp 2,5 lần nền"; hết chậm thì về `HEALTHY`.

#### TC-05-### · Tổng quan sức khỏe và lưới nhiệt <!--k:health-overview-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-05-022 · API-05-033 · UI-05-07
- **Tiền điều kiện / dữ liệu** U-T68-TO; sau [[tc:health-down]].
- **Bước** Mở UI-05-07 PROD.
- **Mong đợi** Thẻ chỉ số khớp `GET /health/overview`; danh sách chú ý có C-NDXP đứng đầu; lưới nhiệt có bảng thay thế đọc được bằng trình đọc màn hình; tự làm mới dừng khi tab ẩn.

#### TC-05-### · PH-04 đọc trạng thái sức khỏe qua API nội bộ <!--k:health-internal-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-021 · API-05-093 · ERR-05-012
- **Tiền điều kiện / dữ liệu** S-INT; U-T68-IE1.
- **Bước**
  1. S-INT `GET /internal/health/states?tenant=T68`.
  2. U-T68-IE1 gọi cùng đường.
- **Mong đợi** Bước 1 `200`, mỗi mục `kind`, `code`, `env`, `level`, `since`. Bước 2 403-PQ (thiếu scope `adapter:health-read`).
