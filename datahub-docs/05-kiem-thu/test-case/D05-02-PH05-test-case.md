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

### TS-05-11 · Tài khoản CSDL chỉ đọc theo luồng

**Mục tiêu.** Xác nhận thay nhóm "Database Connection" của Tooling bằng tài khoản động theo luồng, chỉ đọc, sống ngắn, đúng phạm vi, không chạm CSDL control plane.

**Phủ.** FR-05-023, 024, 025, 028; UC-05-08; API-05-035, 036, 039, 040; UI-05-05; BR-05-017, 018, 019; ERR-05-015, 016, 027; EVT-05-15; NFR-05-007; LGC-TOOL-008.

#### TC-05-### · Khai báo kết nối db-flow trỏ CSDL control plane bị chặn <!--k:dbflow-control-plane-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-023 · API-05-011 · ERR-05-016 · BR-05-017
- **Tiền điều kiện / dữ liệu** U-T68-IE1; kết nối thử `tc-db-cp` loại `db-flow`.
- **Bước**
  1. `PUT …/tc-db-cp/environments/TEST` với `jdbcUrl` trỏ `pg-core.dh-data.svc`.
  2. Với `pg-payment.dh-data.svc`.
  3. Với SIM-PG nhưng `allowedSchemas = ["ph04","public"]`.
- **Mong đợi** Cả ba `422` ERR-05-016; không có dòng mới ở `connection_environment`.

#### TC-05-### · Cấp tài khoản chỉ đọc cho luồng, sống 1 giờ <!--k:dbflow-ro-issue-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-05-024 · API-05-035, 036 · EVT-05-15 · UI-05-05 · UC-05-08 · LGC-TOOL-008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-DKKD TEST; luồng `dkkd-dong-bo` ở PH-04.
- **Bước**
  1. `POST …/dkkd-db/flow-accounts` với `flowCode = dkkd-dong-bo`, `envs = [TEST]`, `access = READ`, `tables = ["dkkd.doanh_nghiep","dkkd.nganh_nghe"]`.
  2. Bằng token `dh-runtime` T68, đọc `database/creds/dh-t68-dkkd-dong-bo-test` ở OpenBao.
  3. Dùng thông tin đó `SELECT` từ hai bảng, rồi `SELECT` từ `dkkd.ho_so_mat`.
  4. Chờ hết TTL.
- **Mong đợi** Bước 1 `201`, `ISSUED` ngay (không cần duyệt). EVT: `flow-account.changed`. Bước 2 trả tài khoản `lease_duration = 3600`. Bước 3 lần đầu đạt, lần hai `permission denied`. Bước 4 role bị xóa ở SIM-PG.

#### TC-05-### · Tài khoản chỉ đọc không ghi, không DDL, không vượt RLS <!--k:dbflow-ro-nowrite-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-05-024 · BR-05-019
- **Tiền điều kiện / dữ liệu** Tài khoản từ [[tc:dbflow-ro-issue]].
- **Bước** Thử `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `CREATE TABLE`, `SET ROLE`, `COPY … TO PROGRAM`, `SELECT pg_read_file('/etc/passwd')`.
- **Mong đợi** Mọi lệnh bị SIM-PG từ chối. `pg_roles` của tài khoản: `rolsuper`, `rolcreaterole`, `rolcreatedb`, `rolbypassrls` đều `false`; `default_transaction_read_only = on`.

#### TC-05-### · Yêu cầu bảng ngoài phạm vi; luồng không tồn tại <!--k:dbflow-scope-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-024 · API-05-036 · ERR-05-027, 033
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-DKKD `allowedSchemas = dkkd, dm`.
- **Bước**
  1. `POST …/flow-accounts` với `tables = ["ns.luong"]`.
  2. Với `flowCode = khong-co`.
- **Mong đợi** Bước 1 `422` ERR-05-027. Bước 2 `422` ERR-05-033.

#### TC-05-### · Kiểm tra quyền thực tế phát hiện quyền vượt khai báo <!--k:dbflow-inspect-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-025 · API-05-040 · ERR-05-015 · UI-05-05
- **Tiền điều kiện / dữ liệu** U-T68-IE1; kết nối `tc-db-ro` khai chỉ đọc, tài khoản gốc ở SIM-PG có `INSERT` trên `dkkd.ket_qua`.
- **Bước**
  1. `POST …/tc-db-ro/environments/TEST:inspect-privileges`.
  2. `POST …/tc-db-ro/environments/TEST:enable`.
  3. Thu hồi `INSERT` ở SIM-PG, chạy lại bước 1.
- **Mong đợi** Bước 1 `conclusion = EXCESSIVE`, liệt kê `dkkd.ket_qua INSERT`. Bước 2 `422` ERR-05-015. Bước 3 `conclusion = OK`.

#### TC-05-### · Thu hồi tài khoản có hiệu lực trong 60 giây <!--k:dbflow-revoke-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-05-028 · API-05-039 · NFR-05-007 · EVT-05-15
- **Tiền điều kiện / dữ liệu** U-T68-SO; tài khoản `ISSUED` đang có phiên mở.
- **Bước** `POST …/flow-accounts/{id}:revoke` với lý do; đo thời điểm role biến mất ở SIM-PG.
- **Mong đợi** `200`, `REVOKED`; role bị xóa, phiên bị cắt ≤ 60 giây; lần lấy thông tin mới ở OpenBao bị từ chối. EVT: `flow-account.changed`. KT: có (`FLOW_ACCOUNT_REVOKE`).

### TS-05-12 · Quyền ghi CSDL có đồng ý và duyệt

**Mục tiêu.** Xác nhận ghi CSDL nguồn theo Q359 chỉ có qua đồng ý của cán bộ ATTT, duyệt của IA, có thời hạn và đúng bảng, thao tác.

**Phủ.** FR-05-026; UC-05-09; API-05-036, 037, 038; UI-05-05, 17; BR-05-009, 020; ERR-05-011, 017, 037.

#### TC-05-### · Đề nghị ghi, SO đồng ý, IA duyệt, cấp đúng quyền <!--k:dbwrite-flow-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-026 · API-05-036, 037, 038 · UI-05-05, 17 · BR-05-020 · UC-05-09
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-SO, U-T68-IA1; C-DKKD (đọc ghi); luồng `ghi-ket-qua`.
- **Bước**
  1. IE1 `POST …/flow-accounts` với `access = WRITE`, `tables = ["dkkd.ket_qua"]`, `operations = ["INSERT"]`, `expiresAt` +60 ngày, lý do, số văn bản đồng ý.
  2. SO mở UI-05-17 loại `ph05.db-write`, xem câu lệnh cấp quyền, bấm "Đồng ý".
  3. IA1 duyệt.
  4. Dùng tài khoản cấp ra `INSERT` vào `dkkd.ket_qua`, rồi `UPDATE` cùng bảng, rồi `INSERT` vào `dkkd.doanh_nghiep`.
- **Mong đợi** Bước 1 `202`, `REQUESTED`. Bước 2 `CONSENTED`. Bước 3 `ISSUED`. Bước 4: `INSERT` đạt; `UPDATE` và `INSERT` bảng khác bị từ chối. KT: có ở cả ba bước, có số văn bản.

#### TC-05-### · Ghi trên kết nối chỉ đọc, vượt hạn, duyệt khi chưa đồng ý <!--k:dbwrite-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-026 · API-05-036, 038 · ERR-05-017, 037, 008
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; `tc-db-ro` (chỉ đọc); C-DKKD.
- **Bước**
  1. `POST …/tc-db-ro/flow-accounts` với `access = WRITE`.
  2. `POST …/dkkd-db/flow-accounts` với `access = WRITE`, `expiresAt` +120 ngày.
  3. IA1 `POST …:approve` cho yêu cầu còn `REQUESTED`.
- **Mong đợi** Bước 1 `409` ERR-05-017. Bước 2 `422` ERR-05-037. Bước 3 `409` ERR-05-008.

#### TC-05-### · Bốn mắt với tài khoản ghi <!--k:dbwrite-4eyes-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-026 · API-05-037, 038 · ERR-05-011 · BR-05-009
- **Tiền điều kiện / dữ liệu** U-T68-IA2 (IA + IE) đề nghị ghi; U-T68-SO đã đồng ý.
- **Bước** IA2 `POST …:approve`.
- **Mong đợi** `403` ERR-05-011; trạng thái giữ `CONSENTED`.

#### TC-05-### · Tài khoản ghi hết hạn tự thu hồi <!--k:dbwrite-expire-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-05-026, 028 · EVT-05-15
- **Tiền điều kiện / dữ liệu** Tài khoản từ [[tc:dbwrite-flow]].
- **Bước** Đồng hồ giả qua `expiresAt`; chạy lịch thu hồi.
- **Mong đợi** `EXPIRED`; role ở OpenBao database engine bị xóa; chủ sở hữu luồng và SO nhận thông báo 7 ngày trước hạn và lúc hết hạn.

### TS-05-13 · Nhật ký truy cập CSDL của luồng

**Mục tiêu.** Xác nhận mọi câu lệnh của luồng tới CSDL nguồn được ghi lại, không chứa giá trị tham số, tra được theo luồng.

**Phủ.** FR-05-027; UC-05-10; API-05-041; UI-05-05; EVT-05-14; NFR-05-015.

#### TC-05-### · Mỗi câu lệnh có một bản ghi truy cập <!--k:dbaudit-record-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** RT, API
- **Truy vết** FR-05-027 · EVT-05-14 · API-05-041 · UC-05-10
- **Tiền điều kiện / dữ liệu** U-T68-SO; luồng `dkkd-dong-bo` chạy thao tác `dh-sql-ro-source` 5 lần với tham số `maSoThue = 0999000001`.
- **Bước**
  1. Đọc topic `t68.adapter.db.access-recorded.v1`.
  2. `GET /db-access-logs?flowCode=dkkd-dong-bo`.
- **Mong đợi** 5 sự kiện, 5 dòng `db_access_record`: luồng, phiên bản, thao tác, `statementHash`, số dòng, thời lượng, kết quả, `traceId`; không có giá trị `0999000001`. Bảng chỉ thêm (UPDATE, DELETE bị trigger chặn, xem [[tc:db-append-only]]).

#### TC-05-### · Chỉ SO, AU xem nhật ký; tenant khác không thấy <!--k:dbaudit-perm-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-027 · API-05-041 · ERR-05-012 · BR-05-002
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-T01-IE.
- **Bước** IE1 và U-T01-IE `GET /db-access-logs`.
- **Mong đợi** IE1 403-PQ. U-T01-IE (có quyền ở T01) `200` với 0 dòng của T68.

### TS-05-14 · Bộ điều hợp: tạo, danh sách, chi tiết

**Mục tiêu.** Xác nhận bộ điều hợp thay connector đa loại của Bus cũ, gắn đúng HTTT và kết nối.

**Phủ.** FR-05-029, 030, 031; API-05-043…046; UI-05-08, 09; BR-05-004, 015; ERR-05-002, 003; LGC-BUS-040.

#### TC-05-### · Tạo bộ điều hợp SOAP và mở trình cấu hình <!--k:adapter-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-031 · API-05-044, 045 · UI-05-08, 10 · LGC-BUS-040
- **Tiền điều kiện / dữ liệu** U-T68-IE1; C-QLVB.
- **Bước**
  1. Ở UI-05-08 bấm "Tạo bộ điều hợp", chọn HTTT `HT-QLVB`, giao thức SOAP, kết nối `qlvb-soap`, mã `tc-qlvb`, giới hạn 10.
  2. `GET /adapters/tc-qlvb`.
- **Mong đợi** Bước 1 `201`, chuyển UI-05-10 phiên bản 1. Bước 2: `DRAFT`, phiên bản 1 `DRAFT` 0 thao tác, `maxConcurrency = 10`, không có Kamelet sinh. KT: có (`ADAPTER_CREATE`).

#### TC-05-### · Kết nối khác HTTT, giao thức không khớp loại kết nối <!--k:adapter-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-031 · API-05-044 · ERR-05-003, 002 · BR-05-015
- **Tiền điều kiện / dữ liệu** U-T68-IE1.
- **Bước**
  1. `POST /adapters` với `systemCode = HT-QLVB`, `connectionCode = ndxp-ho-tich`.
  2. Với `protocol = SOAP`, `connectionCode = bhxh-sftp` (cùng HTTT giả định).
  3. Với mã `qlvb-soap` đã có.
- **Mong đợi** Bước 1 `400` ERR-05-003 rule `same-system` (BR-05-015). Bước 2 `400` ERR-05-003 (giao thức không khớp loại). Bước 3 `409` ERR-05-002.

#### TC-05-### · Danh sách lọc theo nhóm HTTT, có bản chờ duyệt <!--k:adapter-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-029 · API-05-043 · UI-05-08 · BR-05-014
- **Tiền điều kiện / dữ liệu** U-T68-VW; A-DVC, A-QLVB, A-CDC.
- **Bước** `GET /adapters?systemGroup=2&hasPendingVersion=true`.
- **Mong đợi** Chỉ A-QLVB, có `effectiveVersion = 3`, `draftVersion = 4`.

#### TC-05-### · Chi tiết bộ điều hợp; sửa chỉ thông tin chung <!--k:adapter-detail-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-030, 031 · API-05-045, 046 · ERR-05-003 · UI-05-09
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-QLVB.
- **Bước**
  1. `GET /adapters/qlvb-soap`.
  2. `PATCH` tên; rồi `PATCH` `{"maxConcurrency":5}`.
- **Mong đợi** Bước 1 có thao tác, Kamelet sinh, `allowedActions`. Bước 2 lần đầu `200`, lần hai `400` ERR-05-003 (đổi qua phiên bản nháp).

### TS-05-15 · Thao tác REST, phân trang, giới hạn đồng thời

**Mục tiêu.** Xác nhận Kamelet REST dựng yêu cầu an toàn, phân trang không trả thiếu im lặng, tôn trọng hạn mức đối tác và giới hạn tổng tới HTTT.

**Phủ.** FR-05-032, 033, 042; API-05-050; UI-05-10; BR-05-021, 029; ERR-05-017, 032, 105, 106, 110.

#### TC-05-### · Khai báo thao tác REST và gọi qua luồng <!--k:rest-op-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-032, 033 · API-05-050 · UI-05-10 · LGC-TOOL-009
- **Tiền điều kiện / dữ liệu** U-T68-IE1; bản nháp v8 của A-DVC; SIM-HTTP `/api/v2/ho-so/{maHoSo}`.
- **Bước**
  1. `PUT /adapters/dvc-rest/versions/8/operations/chi-tiet-ho-so` với `method = GET`, `pathTemplate = /api/v2/ho-so/${param.maHoSo}`.
  2. Kiểm thử trên TEST với `maHoSo = "H/01 ?x=1"`.
- **Mong đợi** Bước 1 `200`. Bước 2 SIM-HTTP nhận `GET /api/v2/ho-so/H%2F01%20%3Fx%3D1` (mã hóa URL, không ghép thô), tiêu đề `Authorization: Bearer …` lấy từ kết nối, có `traceparent`.

#### TC-05-### · Tiêu đề xác thực trong thao tác, sideEffect WRITE trên kết nối chỉ đọc <!--k:rest-op-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-032, 033 · API-05-050 · ERR-05-032, 017, 008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-DVC v8 nháp (kết nối chỉ đọc); A-DVC v7 `APPROVED`.
- **Bước**
  1. `PUT …/versions/8/operations/x` với `headers = {"Authorization":"Basic …"}`.
  2. `PUT …/versions/8/operations/y` với `method = POST`, `sideEffect = WRITE`.
  3. `PUT …/versions/7/operations/z`.
- **Mong đợi** Bước 1 `422` ERR-05-032. Bước 2 `409` ERR-05-017. Bước 3 `409` ERR-05-008 (phiên bản đã duyệt bất biến, BR-05-016).

#### TC-05-### · Phân trang đủ trang và lỗi khi vượt số trang tối đa <!--k:rest-paging-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** RT
- **Truy vết** FR-05-033 · BR-05-021 · ERR-05-110
- **Tiền điều kiện / dữ liệu** A-DVC thao tác `tra-cuu-ho-so` `PAGE_NUMBER`, `maxPages = 50`.
- **Bước**
  1. SIM-HTTP có 37 trang.
  2. SIM-HTTP có 51 trang.
  3. Lặp với `CURSOR`, `LINK_HEADER`, `OFFSET_LIMIT`.
- **Mong đợi** Bước 1 trả đủ bản ghi 37 trang, tiêu đề `dh-adapter-pages = 37`. Bước 2 lỗi ERR-05-110, không trả 50 trang đầu. Bước 3 cùng kết quả với từng chế độ.

#### TC-05-### · Tôn trọng 429 Retry-After của đối tác <!--k:rest-429-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-033 · ERR-05-106
- **Tiền điều kiện / dữ liệu** SIM-HTTP trả 429 `Retry-After: 2` hai lần rồi 200; lần khác luôn 429 `Retry-After: 120`.
- **Bước** Gọi thao tác hai lần với hai cấu hình.
- **Mong đợi** Lần 1 thành công sau khoảng 4 giây, không gửi yêu cầu trước khi hết `Retry-After`. Lần 2 trả ERR-05-106 khi `Retry-After` vượt thời gian chờ còn lại.

#### TC-05-### · Giới hạn đồng thời tính tổng trên mọi bản sao <!--k:pool-global-->
- **Loại** Biên · **Ưu tiên** P1 · **Tự động** RT, k6
- **Truy vết** FR-05-042 · BR-05-029 · ERR-05-105
- **Tiền điều kiện / dữ liệu** A-DVC `maxConcurrency = 20`, `acquireTimeoutMs = 3000`; runtime 4 bản sao; SIM-HTTP chậm 2 giây, đếm kết nối đồng thời.
- **Bước**
  1. k6 bắn 200 yêu cầu đồng thời vào luồng.
  2. Tăng runtime lên 5 bản sao, lặp lại.
- **Mong đợi** SIM-HTTP không bao giờ thấy > 20 kết nối đồng thời (mỗi bản sao ≤ 5, rồi ≤ 4); yêu cầu chờ quá 3 giây trả ERR-05-105; chỉ số `dh_adapter_pool_exhausted_total` tăng.

### TS-05-16 · Bộ điều hợp SOAP và WSDL

**Mục tiêu.** Xác nhận SOAP có WS-Security, phân tích WSDL an toàn (không XXE), ánh xạ SOAP Fault, phát hiện lệch WSDL.

**Phủ.** FR-05-034; UC-05-14; UI-05-10; BR-05-023; ERR-05-023, 107; LGC-BUS-041, LGC-TOOL-012.

#### TC-05-### · Khai báo thao tác SOAP từ WSDL, gọi có UsernameToken <!--k:soap-op-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-034 · API-05-050 · UI-05-10 · UC-05-14 · LGC-BUS-041
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `tc-qlvb` từ [[tc:adapter-create]]; SIM-SOAP WSDL v1.
- **Bước**
  1. Ở UI-05-10 thêm thao tác `lay-van-ban-den`, nhóm Giao thức: chọn dịch vụ, cổng, thao tác từ WSDL.
  2. Kiểm thử trên TEST.
- **Mong đợi** Bước 1 danh sách dịch vụ nạp từ WSDL đệm, `soapAction` tự điền. Bước 2 SIM-SOAP nhận phong bì có `wsse:UsernameToken` với `Nonce`, `Created`; phản hồi chuyển về JSON chuẩn.

#### TC-05-### · WSDL có thực thể ngoài (XXE) bị từ chối <!--k:soap-xxe-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-034 · API-05-050, 065 · ERR-05-023
- **Tiền điều kiện / dữ liệu** SIM-SOAP phục vụ WSDL có `<!DOCTYPE … SYSTEM "file:///etc/passwd">` và một bản có "billion laughs".
- **Bước** Tải WSDL qua kết nối cho thao tác mới; gửi cùng tệp qua API-05-065.
- **Mong đợi** Cả hai `422` ERR-05-023 "WSDL có khai báo DOCTYPE"; không có yêu cầu nào ra `file://` hay máy chủ ngoài; tiến trình không tăng bộ nhớ đột biến.

#### TC-05-### · SOAP Fault được phân loại theo bảng ánh xạ <!--k:soap-fault-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-034 · ERR-05-107
- **Tiền điều kiện / dữ liệu** Thao tác có `faultMapping`: `soap:Server.Busy` → `TRANSIENT`, `VB-404` → `BUSINESS`.
- **Bước** SIM-SOAP trả lần lượt ba fault: `Server.Busy`, `VB-404`, `X-LA`.
- **Mong đợi** ERR-05-107 với lớp lỗi `TRANSIENT`, `BUSINESS`, `BUSINESS` (không có trong bảng); PH-04 chỉ thử lại lớp `TRANSIENT`.

#### TC-05-### · WSDL ở hệ đích đổi so với bản đệm hạ sức khỏe <!--k:soap-drift-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-05-034, 020 · BR-05-023 · EVT-05-06
- **Tiền điều kiện / dữ liệu** A-QLVB v3 đang chạy; SIM-SOAP đổi sang WSDL v2 (xóa thao tác `LayVanBanDen`).
- **Bước** Chạy lịch so WSDL.
- **Mong đợi** Sức khỏe A-QLVB `DEGRADED`, lý do nêu thao tác lệch; EVT: `health.changed`; chủ sở hữu nhận cảnh báo.

### TS-05-17 · Hàng đợi, thư điện tử, LDAP

**Mục tiêu.** Xác nhận Kamelet hàng đợi xác nhận sau xử lý, tự kết nối lại; thư chỉ gửi tới miền cho phép; LDAP thoát giá trị lọc.

**Phủ.** FR-05-035, 037, 039; UC-05-16; BR-05-024, 028; ERR-05-114, 115; LGC-TOOL-010.

#### TC-05-### · Tiêu thụ AMQP, xác nhận sau khi luồng xử lý xong <!--k:mq-ack-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** RT
- **Truy vết** FR-05-035 · BR-05-024 · UC-05-16 · LGC-TOOL-010
- **Tiền điều kiện / dữ liệu** Bộ điều hợp `tc-tnmt` thao tác `INBOUND` hàng đợi `ho-so-moi`; luồng tiêu thụ lỗi ở bản tin thứ 3.
- **Bước** Đẩy 5 bản tin vào SIM-MQ.
- **Mong đợi** Bản tin 1, 2, 4, 5 được xác nhận; bản tin 3 không bị mất (nằm DLQ của luồng hoặc quay lại hàng đợi theo cấu hình), tiêu đề `traceparent`, `correlationId` được chuyển.

#### TC-05-### · Mất môi giới bản tin, tự kết nối lại <!--k:mq-reconnect-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** Chaos
- **Truy vết** FR-05-035 · ERR-05-114
- **Tiền điều kiện / dữ liệu** Như [[tc:mq-ack]].
- **Bước** Dừng SIM-MQ 2 phút, rồi 6 phút.
- **Mong đợi** Lần 2 phút: tự kết nối lại theo giãn cách, không mất bản tin. Lần 6 phút: ERR-05-114 ghi nhận, sức khỏe `UNHEALTHY`; có lại thì tiêu thụ tiếp.

#### TC-05-### · Thư chỉ tới miền cho phép; đính kèm có mã độc <!--k:mail-domain-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-037 · BR-05-028 · ERR-05-115
- **Tiền điều kiện / dữ liệu** Bộ điều hợp `tc-mail` miền cho phép `t68.gov.vn`; SIM-MAIL.
- **Bước**
  1. Gửi tới `a@t68.gov.vn`, `b@gmail.com`.
  2. Hộp thư nhận có thư kèm F-EICAR.
- **Mong đợi** Bước 1 chỉ thư thứ nhất tới SIM-MAIL; thư thứ hai lỗi lớp dữ liệu, không gửi. Bước 2 ERR-05-115, thư chuyển thư mục cách ly, không đưa vào luồng.

#### TC-05-### · LDAP thoát ký tự đặc biệt trong bộ lọc <!--k:ldap-escape-->
- **Loại** Bảo mật · **Ưu tiên** P3 · **Tự động** RT
- **Truy vết** FR-05-039
- **Tiền điều kiện / dữ liệu** Thao tác `search` với `filterTemplate = (uid=${param.uid})`; SIM-LDAP.
- **Bước** Gọi với `uid = "*)(objectClass=*"`.
- **Mong đợi** SIM-LDAP nhận bộ lọc `(uid=\2a\29\28objectClass=\2a)`; 0 kết quả; `sizeLimit` ≤ 1.000 được áp.

### TS-05-18 · Bộ điều hợp tệp SFTP

**Mục tiêu.** Xác nhận quét tệp thay nhóm Network, Scheduling của Tooling: chỉ nhận tệp đã ghi xong, mỗi tệp một bản sao xử lý, đọc theo luồng.

**Phủ.** FR-05-036; UC-05-15; BR-05-026; ERR-05-112, 113; NFR-05-008; LGC-TOOL-009, 011.

#### TC-05-### · Quét SFTP, bỏ tệp đang ghi dở <!--k:sftp-ready-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** RT
- **Truy vết** FR-05-036 · UC-05-15 · ERR-05-112 · LGC-TOOL-011
- **Tiền điều kiện / dữ liệu** Bộ điều hợp `tc-bhxh` `POLL`, `includePattern = BC_*.csv`, `readyStrategy = STABLE_SIZE`, `stableSeconds = 30`, lịch mỗi phút.
- **Bước**
  1. Ghi `BC_01.csv` dần trong 90 giây.
  2. Ghi `BC_02.csv` một lần; thêm `khac.txt`.
- **Mong đợi** `BC_01.csv` chỉ được nhận sau khi kích thước ổn định 30 giây (các lượt trước ghi ERR-05-112 mức thông tin); `BC_02.csv` nhận ở lượt kế; `khac.txt` không bị chạm. Tệp xong chuyển `archiveDirectory`.

#### TC-05-### · Hai bản sao không cùng xử lý một tệp <!--k:sftp-lock-->
- **Loại** Biên · **Ưu tiên** P1 · **Tự động** RT
- **Truy vết** FR-05-036 · BR-05-026
- **Tiền điều kiện / dữ liệu** Như [[tc:sftp-ready]]; runtime 3 bản sao.
- **Bước** Thả 100 tệp cùng lúc.
- **Mong đợi** Mỗi tệp được xử lý đúng một lần (đếm `dh-file-checksum` ở luồng); có tên tạm `.dh-processing-{uuid}` khi đang xử lý.

#### TC-05-### · Tệp sai định dạng và bản ghi lỗi <!--k:sftp-bad-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-036, 041 · ERR-05-113, 109
- **Tiền điều kiện / dữ liệu** F-CSV-1M (3 dòng thiếu trường bắt buộc, quy tắc `REJECT`); một tệp nhị phân đặt tên `.csv`.
- **Bước** Thả hai tệp.
- **Mong đợi** F-CSV-1M: 999.997 bản ghi đi tiếp, 3 bản ghi vào danh sách lỗi với dòng và trường; tệp nhị phân ERR-05-113, chuyển `errorDirectory`.

### TS-05-19 · Bộ điều hợp CSDL theo truy vấn khai báo

**Mục tiêu.** Xác nhận truy vấn CSDL nguồn theo Q359: câu lệnh khai báo trước, tham số ràng buộc, không SQL động, đúng phạm vi.

**Phủ.** FR-05-038; API-05-050; UI-05-10; ERR-05-032, 111; EVT-05-14; LGC-TOOL-008.

#### TC-05-### · Truy vấn khai báo với tham số ràng buộc <!--k:sql-op-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-05-038 · API-05-050 · EVT-05-14 · LGC-TOOL-008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; bộ điều hợp `tc-dkkd-sql` trên C-DKKD; tài khoản đọc của luồng.
- **Bước**
  1. Khai thao tác `statement = SELECT ma_so_thue, ten FROM dkkd.doanh_nghiep WHERE ma_so_thue = :#mst`.
  2. Luồng gọi với `mst = "0999000001' OR '1'='1"`.
- **Mong đợi** Bước 1 `200`, `parameters` tự nhận `mst`. Bước 2 trả 0 dòng (giá trị ràng buộc, không ghép chuỗi); SIM-PG nhận câu có `$1`. EVT-05-14 một bản ghi.

#### TC-05-### · Câu lệnh bị chặn khi khai báo <!--k:sql-op-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-038 · API-05-050 · ERR-05-032
- **Tiền điều kiện / dữ liệu** Như [[tc:sql-op]], kết nối chỉ đọc.
- **Bước** Khai lần lượt: `DELETE FROM dkkd.doanh_nghiep`; `SELECT 1; DROP TABLE x`; `SELECT pg_sleep(100)`; `SELECT * FROM ph04.flow`; `SELECT dblink(…)`.
- **Mong đợi** Mọi câu `422` ERR-05-032 với vị trí dòng, cột và quy tắc vi phạm.

#### TC-05-### · Quá thời gian, vượt số dòng <!--k:sql-limits-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** RT
- **Truy vết** FR-05-038 · ERR-05-111
- **Tiền điều kiện / dữ liệu** `maxRows = 1000`; bảng 5.000 dòng; câu chậm 40 giây với `timeoutMs = 10000`.
- **Bước** Chạy hai câu.
- **Mong đợi** Câu một trả 1.000 dòng với `dh-truncated = true` nếu thao tác cho phép cắt, nếu không ERR-05-111. Câu hai ERR-05-111 trong ≤ 11 giây, SIM-PG thấy phiên bị hủy.

### TS-05-20 · Chuyển đổi định dạng và chuẩn hóa

**Mục tiêu.** Xác nhận chuyển về JSON chuẩn theo quy ước cố định, xem trước bằng đúng bộ chuyển đổi của runtime, chuẩn hóa giá trị thiếu.

**Phủ.** FR-05-040, 041; API-05-054; UI-05-10; ERR-05-108, 109, 032, 035; LGC-TOOL-007.

#### TC-05-### · XML sang JSON: thuộc tính, phần tử lặp theo XSD <!--k:fmt-xml-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-05-040 · API-05-054 · UI-05-10
- **Tiền điều kiện / dữ liệu** U-T68-IE1; F-XML (phần tử `VanBan` lặp một lần, có thuộc tính `loai`).
- **Bước** `POST …/versions/4:preview-transform` với F-XML.
- **Mong đợi** `vanBan` là mảng một phần tử (theo XSD, không đoán theo số lần xuất hiện); thuộc tính thành `@loai`; văn bản kèm thuộc tính thành `#text`; tiền tố không gian tên bỏ theo bảng. Kết quả bằng đúng kết quả runtime trên cùng đầu vào (so băm).

#### TC-05-### · CSV windows-1258, TCVN3; VNI bị từ chối <!--k:fmt-encoding-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** UT, API
- **Truy vết** FR-05-040 · API-05-050, 054 · ERR-05-032
- **Tiền điều kiện / dữ liệu** Ba tệp mẫu cùng nội dung "Nguyễn Thị Ánh" ở `windows-1258`, `TCVN3`; thao tác khai `encoding = VNI`.
- **Bước** Xem trước hai tệp; lưu thao tác với `VNI`.
- **Mong đợi** JSON có đúng chuỗi Unicode NFC "Nguyễn Thị Ánh"; lưu `VNI` `422` ERR-05-032.

#### TC-05-### · Chuẩn hóa giá trị thiếu: DEFAULT, REJECT, PASS_NULL <!--k:norm-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-05-041 · API-05-054 · ERR-05-109 · UI-05-10
- **Tiền điều kiện / dữ liệu** Quy tắc: `$.ngayKy` thiếu khi `01/01/1900` → `PASS_NULL`; `$.coQuan` thiếu → `DEFAULT:Chưa rõ`; `$.so` thiếu → `REJECT`.
- **Bước** Xem trước mẫu 4 bản ghi có các giá trị trên.
- **Mong đợi** `ngayKy = null`, `coQuan = "Chưa rõ"`, bản ghi thiếu `so` bị từ chối; `warnings[]` nêu đường dẫn, giá trị gốc, quy tắc; số liệu "4 bản ghi · 1 bị từ chối". Ở runtime bản ghi đơn lẻ thiếu `so` trả ERR-05-109.

#### TC-05-### · Phản hồi sai lược đồ; mẫu quá lớn <!--k:fmt-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** RT, API
- **Truy vết** FR-05-040, 032 · ERR-05-108, 035
- **Tiền điều kiện / dữ liệu** Thao tác có `responseSchemaRef`; SIM-HTTP trả `so` là số thay vì chuỗi; mẫu 1,5 MiB.
- **Bước** Gọi thao tác; lưu mẫu 1,5 MiB.
- **Mong đợi** ERR-05-108 kèm đường dẫn trường sai; mẫu `413` ERR-05-035.

### TS-05-21 · Kiểm thử, gửi duyệt, duyệt phiên bản bộ điều hợp

**Mục tiêu.** Xác nhận chỉ phiên bản đã kiểm thử đạt mới được gửi duyệt, người khác duyệt, và thao tác ghi không bao giờ chạy thử trên PROD.

**Phủ.** FR-05-043, 044; UC-05-17; API-05-052, 053, 055…060; UI-05-09, 10, 17; BR-05-006, 009, 016, 030; ERR-05-009, 011; EVT-05-07, 08; LGC-BUS-013.

#### TC-05-### · Kiểm thử tất cả thao tác trên TEST <!--k:adapter-test-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-043 · API-05-052, 053 · UI-05-10 · UC-05-17 · LGC-BUS-013
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-QLVB v4 nháp 6 thao tác (1 `WRITE`).
- **Bước**
  1. Ở UI-05-10 chọn "Kiểm thử ▾ Tất cả thao tác".
  2. Ở hộp xác nhận ghi thử, tích "Tôi xác nhận môi trường TEST của HTTT cho phép ghi thử".
- **Mong đợi** `202`; R5 tab Kết quả kiểm thử hiện từng thao tác với các bước kết nối, gọi, chuyển đổi, chuẩn hóa, so lược đồ; 6 mục R2 có ✓. `GET …/tests/{id}` `result = PASSED`.

#### TC-05-### · Thao tác ghi không chạy trên STAGING, PROD; thiếu xác nhận <!--k:adapter-test-write-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-043 · BR-05-030 · API-05-052 · ERR-05-003
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-QLVB v4.
- **Bước**
  1. `POST …/versions/4/tests` với `env = PROD`.
  2. Với `env = STAGING`, `operations = ["gui-van-ban"]` (`WRITE`).
  3. Với `env = TEST`, thao tác `WRITE`, không `confirmWriteOnTest`.
- **Mong đợi** Bước 1 `400` ERR-05-003 (`env` chỉ `TEST`, `STAGING`). Bước 2, 3 `400` ERR-05-003; SIM-SOAP không nhận yêu cầu ghi.

#### TC-05-### · Gửi duyệt khi sửa sau kiểm thử bị chặn <!--k:adapter-submit-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-044, 032 · API-05-055 · ERR-05-009 · BR-05-006
- **Tiền điều kiện / dữ liệu** U-T68-IE1; sau [[tc:adapter-test]], sửa `timeoutMs` của một thao tác.
- **Bước** `POST …/versions/4:submit`; mở UI-05-10.
- **Mong đợi** `409` ERR-05-009; mục R2 của thao tác vừa sửa mất ✓; nút "Gửi duyệt" vô hiệu với lý do.

#### TC-05-### · Gửi duyệt, người khác duyệt, Kamelet sinh và phiên bản cũ bị thay <!--k:adapter-approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-044, 047 · API-05-055, 056 · UI-05-17 · EVT-05-07 · BR-05-016
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; A-QLVB v4 kiểm thử đạt.
- **Bước**
  1. IE1 gửi duyệt với ghi chú phát hành.
  2. IA1 duyệt ở UI-05-17.
  3. `GET /adapters/qlvb-soap`; `PUT …/versions/4/operations/x`.
- **Mong đợi** Bước 1 v4 `SUBMITTED`. Bước 2 v4 `APPROVED`, v3 `SUPERSEDED`. EVT: `adapter.version-approved`. Bước 3 `effectiveVersion = 4`, Kamelet sinh tên `qlvb-soap-{op}-v1-{loại}`; `PUT` trả `409` ERR-05-008.

#### TC-05-### · Tự duyệt phiên bản; từ chối thiếu lý do <!--k:adapter-approve-4eyes-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-044 · API-05-056, 057 · ERR-05-011, 038 · BR-05-009
- **Tiền điều kiện / dữ liệu** U-T68-IA2 soạn và gửi phiên bản của `tc-qlvb`.
- **Bước**
  1. IA2 `POST …:approve`.
  2. IA1 `POST …:reject` không lý do; rồi có lý do.
- **Mong đợi** Bước 1 `403` ERR-05-011. Bước 2 lần đầu `400` ERR-05-038; lần hai `200`, phiên bản về `DRAFT`, kết quả kiểm thử giữ.

#### TC-05-### · Tạm dừng bộ điều hợp chặn lượt mới; ngừng dùng khi còn nơi dùng <!--k:adapter-suspend-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, RT
- **Truy vết** FR-05-044 · API-05-058, 059, 060 · EVT-05-08 · ERR-05-118, 010
- **Tiền điều kiện / dữ liệu** U-T68-TO; A-DVC đang dùng ở 21 luồng.
- **Bước**
  1. TO `POST /adapters/dvc-rest:suspend` với lý do; luồng gọi.
  2. TO `:resume`.
  3. IE1 `:retire`.
- **Mong đợi** Bước 1 `200`, EVT: `adapter.state-changed`, lượt mới nhận ERR-05-118 trong ≤ 30 giây. Bước 2 hoạt động lại. Bước 3 `409` ERR-05-010.

### TS-05-22 · Phiên bản và so sánh trên lưu lượng thật

**Mục tiêu.** Xác nhận nâng phiên bản an toàn: một bản nháp tại một thời điểm, nhận diện thay đổi không tương thích, so sánh phản hồi trên lưu lượng thật chỉ với thao tác đọc.

**Phủ.** FR-05-045; UC-05-18; API-05-047, 048, 063, 064; UI-05-09; ERR-05-008.

#### TC-05-### · Tạo bản nháp mới sao từ phiên bản hiệu lực; chỉ một bản nháp <!--k:version-draft-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-045 · API-05-047, 048 · ERR-05-008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-DVC v7 hiệu lực, không có nháp.
- **Bước** `POST /adapters/dvc-rest/versions` hai lần.
- **Mong đợi** Lần 1 `201` v8 `DRAFT`, thao tác giống v7. Lần 2 `409` ERR-05-008.

#### TC-05-### · Thay đổi không tương thích tăng số chính Kamelet <!--k:version-breaking-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, UT
- **Truy vết** FR-05-045, 047 · UI-05-10
- **Tiền điều kiện / dữ liệu** A-DVC v8 nháp.
- **Bước** Bỏ tham số bắt buộc của thao tác `tra-cuu-ho-so`; xem R5 tab "Kamelet sẽ sinh".
- **Mong đợi** Nhãn "Thay đổi không tương thích → v2"; sau duyệt có Kamelet `dvc-rest-tra-cuu-ho-so-v2-action` mới, `…-v1-action` giữ cho luồng cũ.

#### TC-05-### · So sánh v7 và v8 trên lưu lượng thật <!--k:version-compare-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API, RT
- **Truy vết** FR-05-045 · API-05-063, 064 · ERR-05-003 · UI-05-09 · UC-05-18
- **Tiền điều kiện / dữ liệu** U-T68-IE1; v8 kiểm thử đạt; luồng PROD gọi `tra-cuu-ho-so` 10 lượt/giây.
- **Bước**
  1. `POST …/versions/8:compare` với `operations = ["tra-cuu-ho-so"]`, 10 % lưu lượng, 15 phút.
  2. `GET …/comparisons/{id}`.
  3. `POST …/versions/8:compare` với thao tác `WRITE`.
- **Mong đợi** Bước 2: số yêu cầu, tỷ lệ khác, mẫu khác đã che dữ liệu cá nhân; luồng vẫn nhận phản hồi v7. Bước 3 `400` ERR-05-003.

### TS-05-23 · Sinh bộ điều hợp từ OpenAPI, WSDL

**Mục tiêu.** Xác nhận sinh bản nháp thao tác từ đặc tả để rút ngắn khai báo.

**Phủ.** FR-05-046; UC-05-13; API-05-065; UI-05-11; ERR-05-023, 035.

#### TC-05-### · Sinh từ OpenAPI 3.1 <!--k:spec-oas-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-05-046 · API-05-065 · UI-05-11 · UC-05-13
- **Tiền điều kiện / dữ liệu** U-T68-IE1; F-OAS.
- **Bước** Tải F-OAS ở UI-05-11, chọn 10 đường dẫn, tạo bản nháp.
- **Mong đợi** 10 thao tác: GET → `sideEffect = NONE`, POST → `WRITE`; phân trang phát hiện ở 2 thao tác; cảnh báo `oneOf` cho 2 lược đồ; chuyển UI-05-10, mục R2 chưa có ✓.

#### TC-05-### · Sinh từ WSDL ZIP; đặc tả hỏng hoặc quá lớn <!--k:spec-neg-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-046 · API-05-065 · ERR-05-023, 035
- **Tiền điều kiện / dữ liệu** F-WSDL; YAML OpenAPI hỏng ở dòng 40; OpenAPI 6 MiB.
- **Bước** Gửi ba tệp.
- **Mong đợi** F-WSDL `200` với thao tác SOAP và XSD nhập kèm. YAML hỏng `422` ERR-05-023 có dòng 40. Tệp 6 MiB `413` ERR-05-035.

### TS-05-24 · Kamelet sinh và đồng bộ catalog

**Mục tiêu.** Xác nhận Kamelet sinh từ bộ điều hợp vào được bảng thành phần PH-04 và runtime, catalog đồng bộ theo hồ sơ runtime.

**Phủ.** FR-05-047, 059; API-05-089; UI-05-14; BR-05-027; EVT-05-07, 09.

#### TC-05-### · Kamelet sinh có trong catalog PH-04 <!--k:catalog-generated-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-047, 059 · API-05-089 · BR-05-027 · UI-05-14
- **Tiền điều kiện / dữ liệu** S-INT; sau [[tc:adapter-approve]].
- **Bước** S-INT `GET /internal/catalog/kamelets?tenant=T68&profile=soap-jvm`.
- **Mong đợi** Có Kamelet nền theo `runtime-manifest.json`, `COMMON` và `TENANT` `APPROVED`, Kamelet sinh của A-QLVB; mỗi mục có YAML, băm, mức native; Kamelet `DEPRECATED` có cờ ẩn. Không có mục của T01.

#### TC-05-### · Tên Kamelet sinh dài được rút gọn có băm <!--k:catalog-name-->
- **Loại** Biên · **Ưu tiên** P3 · **Tự động** UT
- **Truy vết** FR-05-047
- **Tiền điều kiện / dữ liệu** Mã bộ điều hợp 50 ký tự, mã thao tác 40 ký tự.
- **Bước** Duyệt phiên bản.
- **Mong đợi** Tên Kamelet ≤ 63 ký tự, có băm 6 ký tự, vẫn khớp mẫu `-(source|sink|action)$`; hai thao tác khác nhau không trùng tên.

#### TC-05-### · Nâng runtime chạy lại kiểm tra tĩnh, đánh dấu NEEDS_REVIEW <!--k:catalog-upgrade-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-05-059 · ERR-05-021
- **Tiền điều kiện / dữ liệu** K-MST dùng thành phần bị bỏ khỏi `runtime-manifest.json` bản mới.
- **Bước** Nạp manifest mới; chạy việc kiểm tra lại.
- **Mong đợi** K-MST mang thuộc tính `NEEDS_REVIEW` (trạng thái giữ `APPROVED`), UI-05-14 có huy hiệu; chủ sở hữu nhận thông báo nêu ERR-05-021.

### TS-05-25 · Thiết lập và chạy CDC

**Mục tiêu.** Xác nhận CDC cho HTTT di sản: kiểm tra điều kiện ở nguồn, chạy qua GitOps, theo dõi độ trễ, không mất dữ liệu khi khởi động lại.

**Phủ.** FR-05-048, 049, 050, 052; UC-05-19; API-05-067…072; UI-05-12; ERR-05-025, 027, 029; EVT-05-12, 13; NFR-05-009, 010.

#### TC-05-### · Khai báo CDC, đăng ký topic và lược đồ <!--k:cdc-config-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-048 · API-05-067, 068 · UI-05-12 · UC-05-19
- **Tiền điều kiện / dữ liệu** U-T68-IE1; A-CDC; C-CDC TEST; PH-10 SIT.
- **Bước** `PUT /adapters/dkkd-cdc/cdc` với `engine = postgresql`, 2 bảng, cột `so_dien_thoai` băm, `snapshotMode = INITIAL`.
- **Mong đợi** `200`, trạng thái `STOPPED`; topic `t68.cdc.dkkd-cdc.dkkd.doanh_nghiep.v1` và lược đồ Avro có ở PH-10, Apicurio; đặc tả `KafkaConnector` ở nhánh môi trường của kho GitOps, chưa áp.

#### TC-05-### · Bảng ngoài phạm vi, PH-10 không khả dụng, vượt trần bảng <!--k:cdc-config-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-048 · API-05-068 · ERR-05-027, 029, 030
- **Tiền điều kiện / dữ liệu** U-T68-IE1; `05.cdc.max-tables = 50`.
- **Bước**
  1. Khai bảng `ke_toan.so_cai`.
  2. Dừng PH-10, khai hợp lệ.
  3. Khai 51 bảng.
- **Mong đợi** Bước 1 `422` ERR-05-027. Bước 2 `503` ERR-05-029. Bước 3 `422` ERR-05-030.

#### TC-05-### · Kiểm tra điều kiện CDC đạt và không đạt <!--k:cdc-prereq-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-049 · API-05-069, 070 · ERR-05-025 · UI-05-12
- **Tiền điều kiện / dữ liệu** U-T68-IE1; SIM-PG; SIM-PG-BAD.
- **Bước**
  1. Kiểm tra với SIM-PG.
  2. Đổi kết nối sang SIM-PG-BAD, kiểm tra; rồi `POST …/cdc:start`.
- **Mong đợi** Bước 1 mọi mục đạt (`wal_level`, quyền `REPLICATION`, publication đúng bảng, slot còn chỗ). Bước 2 mục `wal_level` không đạt kèm hướng dẫn gửi đơn vị chủ quản; `start` `422` ERR-05-025.

#### TC-05-### · Chạy CDC: chụp ảnh ban đầu rồi đọc thay đổi <!--k:cdc-run-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-05-050, 052 · API-05-070, 067 · EVT-05-12, 13 · NFR-05-009
- **Tiền điều kiện / dữ liệu** U-T68-TO; sau [[tc:cdc-prereq]] bước 1; bảng `doanh_nghiep` 10.000 dòng.
- **Bước**
  1. `POST …/cdc:start`.
  2. Sau khi `STREAMING`, `INSERT`, `UPDATE`, `DELETE` ở SIM-PG.
  3. `GET …/cdc`.
- **Mong đợi** `SNAPSHOTTING` → `STREAMING`; EVT: `cdc.state-changed` mỗi lần đổi. Topic bảng có 10.000 bản ghi `op = r` rồi đúng ba bản ghi `c`, `u`, `d`; `so_dien_thoai` đã băm. Bước 3 có vị trí LSN, độ trễ, số sự kiện theo loại.

#### TC-05-### · Tạm dừng, tiếp tục; khởi động lại không mất thay đổi <!--k:cdc-pause-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, Chaos
- **Truy vết** FR-05-050 · API-05-071, 072 · NFR-05-010
- **Tiền điều kiện / dữ liệu** CDC `STREAMING` từ [[tc:cdc-run]].
- **Bước**
  1. `:pause`; ghi 500 thay đổi ở nguồn; `:resume`.
  2. Xóa pod Kafka Connect giữa lúc ghi 5.000 thay đổi.
- **Mong đợi** Bước 1 cả 500 thay đổi tới topic sau khi tiếp tục. Bước 2 không mất thay đổi nào (đối chiếu khóa và `source.lsn`); trùng chỉ trong cửa sổ từ offset cuối.

#### TC-05-### · Dừng hẳn giải phóng slot <!--k:cdc-stop-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-05-050 · BR-05-022
- **Tiền điều kiện / dữ liệu** U-T68-TO; CDC `STREAMING`.
- **Bước** Dừng hẳn với lý do; đồng hồ giả +7 ngày.
- **Mong đợi** Connector bị xóa khỏi GitOps; slot còn tới 7 ngày rồi bị xóa ở SIM-PG; `pg_replication_slots` không còn slot `dh_t68_dkkd_cdc`.

### TS-05-26 · Thay đổi lược đồ và chụp ảnh lại

**Mục tiêu.** Xác nhận thay đổi lược đồ phá vỡ làm CDC dừng trước khi phát bản ghi sai, có hộp việc xử lý và chụp ảnh lại.

**Phủ.** FR-05-051, 053; UC-05-20; API-05-073, 074, 075; UI-05-13; BR-05-022; ERR-05-026, 116, 117; EVT-05-11.

#### TC-05-### · Thêm cột có thể null: tiếp tục, ghi nhận mức thông tin <!--k:schema-compatible-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-05-051 · EVT-05-11 · API-05-074
- **Tiền điều kiện / dữ liệu** CDC `STREAMING`.
- **Bước** `ALTER TABLE dkkd.doanh_nghiep ADD COLUMN ghi_chu text`; ghi một dòng.
- **Mong đợi** `cdc_schema_change` mức `INFO`; lược đồ Avro mới tương thích BACKWARD; CDC giữ `STREAMING`; bản ghi mới có trường `ghi_chu`.

#### TC-05-### · Đổi tên cột: CDC dừng trước khi phát <!--k:schema-breaking-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-05-051 · BR-05-022 · ERR-05-116 · EVT-05-11, 12 · UI-05-12
- **Tiền điều kiện / dữ liệu** CDC `STREAMING`; người tiêu thụ đọc topic.
- **Bước** `ALTER TABLE … RENAME COLUMN ten_dn TO ten_doanh_nghiep`; ghi 3 dòng.
- **Mong đợi** CDC `PAUSED_SCHEMA`; 0 bản ghi theo lược đồ mới trên topic (SMT `DhSchemaGate` chặn); EVT: `cdc.schema-changed` mức `BREAKING`; TO, IE nhận cảnh báo; UI-05-12 có banner và nút "Xử lý".

#### TC-05-### · Tiếp tục khi còn thay đổi chờ; ánh xạ cột rồi tiếp tục <!--k:schema-resolve-->
- **Loại** Âm, Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-051, 050 · API-05-072, 074, 075 · ERR-05-026 · UI-05-13 · UC-05-20
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-TO; sau [[tc:schema-breaking]].
- **Bước**
  1. TO `POST …/cdc:resume`.
  2. IE1 ở UI-05-13 chọn "Ánh xạ cột" `ten_dn → ten_doanh_nghiep`, lý do, xác nhận.
  3. TO bấm "Tiếp tục CDC" trong toast.
- **Mong đợi** Bước 1 `409` ERR-05-026. Bước 2 `200`, toast "Còn 0 thay đổi chờ". Bước 3 `STREAMING`; 3 dòng đã ghi tới topic với tên trường cũ `ten_dn` theo ánh xạ. KT: có (quyết định, người, lý do).

#### TC-05-### · Mất nhật ký nguồn, chụp ảnh lại có lịch ngoài giờ <!--k:resnapshot-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** IT, API
- **Truy vết** FR-05-053 · API-05-073 · ERR-05-117, 038 · EVT-05-12
- **Tiền điều kiện / dữ liệu** U-T68-TO; CDC dừng lâu, slot bị xóa ở nguồn; bảng 12 triệu dòng (thống kê giả).
- **Bước**
  1. Bật lại, quan sát trạng thái.
  2. `POST …/cdc:resnapshot` không lý do; có lý do nhưng không khung giờ; có khung giờ 22:00.
- **Mong đợi** Bước 1 `FAILED` với ERR-05-117. Bước 2 lần một `400` ERR-05-038; lần hai `400` ERR-05-003 (bảng > 10 triệu dòng cần khung giờ ngoài hành chính); lần ba `202`, chụp ảnh tăng dần chạy lúc 22:00, bản ghi `op = r`.

### TS-05-27 · Kamelet của tỉnh: soạn, kiểm tra tĩnh, duyệt

**Mục tiêu.** Xác nhận thay "Nhập component từ JAR" (LGC-TOOL-027) bằng Kamelet YAML qua kiểm tra tĩnh KR-01…14 và duyệt.

**Phủ.** FR-05-054, 055, 056, 057; UC-05-21; API-05-076…084; UI-05-14, 15, 16, 17; ERR-05-002, 011, 020, 021, 022, 040; EVT-05-09; LGC-TOOL-027.

#### TC-05-### · Danh mục và chi tiết Kamelet <!--k:kamelet-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-05-054, 055 · API-05-076, 077, 078 · UI-05-14, 15
- **Tiền điều kiện / dữ liệu** U-T68-VW.
- **Bước** `GET /kamelets?scope=TENANT`; `GET /kamelets/dh-t68-tra-cuu-mst-action`.
- **Mong đợi** Danh sách có K-MST với phạm vi, phiên bản, nơi dùng = 3; mặc định không có `WITHDRAWN`. Chi tiết có tham số, YAML, kết quả kiểm tra tĩnh, phụ thuộc thành phần.

#### TC-05-### · Soạn Kamelet hợp lệ, kiểm tra tĩnh đạt, gửi, IA duyệt <!--k:kamelet-submit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-05-056, 057 · API-05-079, 081, 082, 083 · UI-05-16, 17 · EVT-05-09 · UC-05-21 · LGC-TOOL-027
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; F-KAM-OK.
- **Bước**
  1. Ở UI-05-16 dán F-KAM-OK, bấm "Kiểm tra tĩnh", "Gửi duyệt".
  2. IA1 duyệt ở UI-05-17.
- **Mong đợi** Bước 1 `violations` rỗng (có thể có cảnh báo KR-12, KR-13); `SUBMITTED`. Bước 2 `APPROVED`; EVT: `kamelet.published` trên `t68.adapter.kamelet.published.v1`; có trong catalog T68, không có ở T01.

#### TC-05-### · Kiểm tra tĩnh chặn ngôn ngữ kịch bản, #class, URI trực tiếp, bí mật cứng <!--k:kamelet-static-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-05-056 · API-05-081, 082 · ERR-05-020, 021 · UI-05-16
- **Tiền điều kiện / dữ liệu** U-T68-IE1; F-KAM-BAD và các biến thể.
- **Bước** Kiểm tra lần lượt các bản: `groovy`; `#class:java.lang.Runtime`; `to: https://ngoai.example.org`; chuỗi `"Pa55w0rd-AbCdEf-1234567"` trong `template`; tham số `matKhau` không `x-descriptors`; `{{vault:kv/dh/t01/…}}`; thành phần `jt400`; YAML 300 KiB.
- **Mong đợi** Mỗi bản có vi phạm đúng quy tắc: KR-04, KR-04, KR-05, KR-07, KR-06, KR-14 (ERR-05-020), KR-08 (ERR-05-021), KR-10 (ERR-05-020); mỗi vi phạm có dòng, cột, thông điệp tiếng Việt; gửi duyệt `422`.

#### TC-05-### · Tên trùng Kamelet nền; phiên bản phụ không tương thích <!--k:kamelet-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-056 · API-05-079, 081 · ERR-05-002, 022
- **Tiền điều kiện / dữ liệu** U-T68-IE1; K-MST 1.0.0.
- **Bước**
  1. `POST /kamelets` tên `dh-http-sink`.
  2. Tạo K-MST 1.1.0 bỏ một tham số.
- **Mong đợi** Bước 1 `409` ERR-05-002. Bước 2 `422` ERR-05-022 (KR-09).

#### TC-05-### · Tự duyệt Kamelet; tỉnh ghi lên Kamelet COMMON <!--k:kamelet-4eyes-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-057 · API-05-080, 083 · ERR-05-011, 040 · BR-05-009
- **Tiền điều kiện / dữ liệu** U-T68-IA2 gửi Kamelet; U-T68-IE1; Kamelet `COMMON` `dh-dm-tra-cuu-action`.
- **Bước**
  1. IA2 `POST …:approve` Kamelet của mình.
  2. IE1 `PUT /kamelets/dh-dm-tra-cuu-action/versions/1.0.0`.
- **Mong đợi** Bước 1 `403` ERR-05-011. Bước 2 `403` ERR-05-040.

### TS-05-28 · Ngừng khuyến nghị, thu hồi, đề xuất dùng chung

**Mục tiêu.** Xác nhận vòng đời sau duyệt của Kamelet, đặc biệt thu hồi khẩn khi có lỗi bảo mật.

**Phủ.** FR-05-058, 060; UC-05-22, 23; API-05-085…088; UI-05-15; ERR-05-120; EVT-05-10.

#### TC-05-### · Ngừng khuyến nghị ẩn khỏi bảng thành phần, luồng cũ vẫn chạy <!--k:kamelet-deprecate-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-058 · API-05-085, 089 · EVT-05-10 · UI-05-15
- **Tiền điều kiện / dữ liệu** U-T68-IA1; K-MST 3 luồng dùng.
- **Bước** Ngừng khuyến nghị 1.0.0 với Kamelet thay thế gợi ý.
- **Mong đợi** `DEPRECATED`; catalog trả cờ ẩn; 3 luồng vẫn chạy; EVT: `kamelet.lifecycle-changed`.

#### TC-05-### · Thu hồi chặn lần phát hành kế tiếp của luồng dùng <!--k:kamelet-withdraw-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-058 · API-05-086, 031 · ERR-05-120, 038 · EVT-05-10 · UC-05-22
- **Tiền điều kiện / dữ liệu** U-T68-IA1; S-INT; K-MST.
- **Bước**
  1. `POST …:withdraw` không lý do; rồi có lý do.
  2. S-INT `POST /internal/connection-references:verify` cho luồng dùng K-MST.
- **Mong đợi** Bước 1 lần đầu `400` ERR-05-038; lần sau `WITHDRAWN`, EVT, chủ sở hữu 3 luồng và TO nhận cảnh báo mức cao. Bước 2 trả mục lỗi ERR-05-120 cho K-MST; luồng đang chạy không bị dừng tự động.

#### TC-05-### · Đề xuất Kamelet tỉnh thành dùng chung, PA duyệt <!--k:kamelet-common-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-05-060, 057 · API-05-088, 083 · EVT-05-09 · UC-05-23
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-PA; Kamelet `APPROVED` mới của T68; ý kiến SO ghi trong đề xuất.
- **Bước** IE1 đề xuất; U-PA duyệt.
- **Mong đợi** Bản sao ở `COMMON` `SUBMITTED` rồi `APPROVED`; EVT trên `common.adapter.kamelet.published.v1`; catalog T01 có Kamelet mới.

### TS-05-29 · Runtime phân giải kết nối và PH-04 xác minh tham chiếu

**Mục tiêu.** Xác nhận runtime chỉ nhận cấu hình không bí mật từ control plane, lấy bí mật thẳng từ OpenBao, và PH-04 chặn phát hành luồng tham chiếu kết nối không hợp lệ.

**Phủ.** FR-05-014, 015; UC-05-24, 25; API-05-031, 032; BR-05-003, 013; ERR-05-013, 101; NFR-05-002, 012.

#### TC-05-### · Runtime nhận cấu hình kết nối không có bí mật <!--k:runtime-config-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-015 · API-05-032 · BR-05-003 · UC-05-24
- **Tiền điều kiện / dữ liệu** S-RT-T68.
- **Bước** `GET /internal/runtime/connections?env=PROD`.
- **Mong đợi** `200`, mỗi kết nối `ENABLED` có tham số, `secretPath`, `secretVersion`, hạn mức đồng thời mỗi bản sao; không có giá trị bí mật; mồi sạch; có `ETag` để hỏi lại có điều kiện.

#### TC-05-### · Runtime T01 không đọc được cấu hình T68 <!--k:runtime-config-tenant-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-015 · API-05-032 · BR-05-002 · ERR-05-012
- **Tiền điều kiện / dữ liệu** S-RT-T01; U-T68-IE1.
- **Bước** S-RT-T01 `GET /internal/runtime/connections?env=PROD&tenant=T68`; IE1 gọi cùng đường.
- **Mong đợi** S-RT-T01 nhận cấu hình T01 (tham số `tenant` bị bỏ qua, tenant lấy từ token) với `baseUrl` của T01 cho mã `ndxp-ho-tich`; IE1 403-PQ.

#### TC-05-### · PH-04 xác minh tham chiếu khi phát hành <!--k:verify-refs-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-05-014 · API-05-031 · ERR-05-013, 014, 118 · UC-05-25
- **Tiền điều kiện / dữ liệu** S-INT; luồng ở không gian `ho-tich` tham chiếu `ndxp-ho-tich` (đã cấp), `tc-chua-cap` (chưa cấp), `tc-e1` (PROD chưa có giá trị), `tc-tam-ngung` (`SUSPENDED`).
- **Bước** `POST /internal/connection-references:verify` với 4 tham chiếu, `env = PROD`.
- **Mong đợi** Trả từng mục: `ndxp-ho-tich` OK; `tc-chua-cap` ERR-05-013; `tc-e1` ERR-05-014; `tc-tam-ngung` ERR-05-118. Chỉ mục `usage_ref` được ghi khi PH-04 phát hành thành công.

#### TC-05-### · Phân giải kết nối nhanh khi có đệm; OpenBao mất <!--k:runtime-resolve-->
- **Loại** Hiệu năng, Khả dụng · **Ưu tiên** P1 · **Tự động** RT, Chaos
- **Truy vết** FR-05-015 · NFR-05-002, 012 · ERR-05-101
- **Tiền điều kiện / dữ liệu** Luồng mẫu gọi C-NDXP liên tục.
- **Bước**
  1. Đo thời gian phân giải `{{conn:ndxp-ho-tich}}` 10.000 lần.
  2. Dừng OpenBao 10 phút; rồi tới khi hết đệm 5 phút với kết nối chưa có trong đệm.
  3. Dừng `dh-integration` 24 giờ (đồng hồ giả).
- **Mong đợi** Bước 1 p99 ≤ 2 ms khi có đệm. Bước 2 kết nối đã đệm vẫn chạy; kết nối chưa đệm trả ERR-05-101. Bước 3 luồng đang chạy tiếp tục.

### TS-05-30 · Tham số phân hệ và báo cáo sử dụng

**Mục tiêu.** Xác nhận TA bật, tắt loại kết nối và đặt trần; báo cáo sử dụng có số liệu đúng.

**Phủ.** FR-05-061, 062; UC-05-26; API-05-090, 091, 092; ERR-05-010, 030.

#### TC-05-### · Bật, tắt loại kết nối; tắt khi còn dùng bị chặn <!--k:settings-type-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-061 · API-05-090, 091 · ERR-05-010, 004 · UC-05-26
- **Tiền điều kiện / dữ liệu** U-T68-TA; loại `ldap` không dùng; `http-rest` đang dùng.
- **Bước**
  1. `PUT /settings/connection-types/ldap` `enabled = true`.
  2. `PUT /settings/connection-types/http-rest` `enabled = false`.
- **Mong đợi** Bước 1 `200`, tạo kết nối LDAP được. Bước 2 `409` ERR-05-010 với số kết nối đang dùng.

#### TC-05-### · Trần tham số tenant được áp <!--k:settings-cap-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-05-061 · API-05-091, 011 · ERR-05-030
- **Tiền điều kiện / dữ liệu** U-T68-TA đặt trần `timeoutMs = 30000` cho `http-rest`; U-T68-IE1.
- **Bước** IE1 `PUT …/environments/TEST` với `timeoutMs = 45000`.
- **Mong đợi** `422` ERR-05-030 nêu trần.

#### TC-05-### · Báo cáo sử dụng kết nối và bộ điều hợp <!--k:report-usage-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-05-062 · API-05-092
- **Tiền điều kiện / dữ liệu** U-T68-TA; dữ liệu 7 ngày của SIT.
- **Bước** `GET /reports/usage?from=…&to=…&groupBy=system`.
- **Mong đợi** Số lượt gọi, lỗi, p95 theo HTTT khớp chỉ số Prometheus cùng khoảng (sai lệch ≤ 1 %); không có dữ liệu tenant khác.
