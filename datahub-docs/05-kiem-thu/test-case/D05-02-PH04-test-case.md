---
ma_tai_lieu: D05-02-PH04
ten: Kịch bản và test case phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Dự thảo
nguoi_doc: Đội kiểm thử, Đội phát triển PH-04 (L-INT, frontend console), Kiến trúc sư, ATTT, Vận hành, Cán bộ nghiệm thu, Chủ đầu tư
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
---

# D05-02-PH04 · Kịch bản và test case phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- Lõi tích hợp làm đúng mọi yêu cầu đã duyệt.
- Lõi không làm mất chức năng của Bus tích hợp và công cụ kéo thả Productivity Tooling đang vận hành.
- Không có đường nào để một luồng chưa được duyệt, hoặc một luồng của tỉnh này, chạm vào dữ liệu của tỉnh khác.

**Phạm vi.** Gồm 32 kịch bản (TS-04-01…32) với các test case TC-04-nnn và 12 kịch bản nghiệm thu người dùng (UAT-04-01…12). Phạm vi phủ:

- Ở control plane: không gian làm việc, luồng, phiên bản, trình thiết kế, kiểm tra hợp lệ, chạy thử, duyệt bốn mắt, phát hành GitOps, lệnh runtime, catalog.
- Ở data plane: chín chặng chuẩn, Kafka, xử lý lỗi, truy cập CSDL có kiểm soát theo Q359.
- Các yêu cầu phi chức năng: hiệu năng, bảo mật theo OWASP ASVS 5.0, khả dụng, truy cập theo WCAG 2.2 AA.

Mỗi yêu cầu mức bắt buộc (M) có ít nhất một ca dương tính và một ca âm tính. Ma trận truy vết ở mục 8 được sinh tự động từ chính tài liệu này.

**Căn cứ.** Gồm:

- Tài liệu cùng bộ của PH-04: FRS D02-03-PH04, use case D02-04-PH04, SDD D03-02-PH04, CSDL D03-03-PH04, API D03-04-PH04, màn hình D03-06-PH04.
- Ma trận phân quyền D02-08, kế hoạch kiểm thử tổng thể D05-01, cổng CI của D04-02.
- Cấu trúc tài liệu kiểm thử theo ISO/IEC/IEEE 29119-3.
- Yêu cầu an toàn thông tin cấp độ 3 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026), kiểm ở TS-04-23, 24, 30.

**Điểm cần hội đồng lưu ý.** Bốn nhóm ca là điều kiện bắt buộc đạt 100% trước khi phát hành:

- rò rỉ chéo tenant (TS-04-23);
- bốn mắt và "chỉ phiên bản đã duyệt mới chạy" (TS-04-15, 16);
- lệnh runtime có ký (TS-04-18);
- truy cập CSDL chỉ đọc (TS-04-22).

Hiện mã đang chạy (W2) mới chạy thử **giả lập**, chưa có sandbox thật. Vì vậy các ca chạy thử ở TS-04-12 là tiêu chí nghiệm thu của công việc mới, không phải mô tả hành vi hiện có. Số liệu quy mô dùng giả định GĐ vì chưa có dữ liệu thật của tỉnh thí điểm.

## 0. Giới thiệu

Tài liệu này là đặc tả kiểm thử của PH-04, lập theo ISO/IEC/IEEE 29119-3, gồm ba phần:

- đặc tả thiết kế kiểm thử: các kịch bản `TS-04-nn`;
- đặc tả ca kiểm thử: các test case `TC-04-nnn`;
- đặc tả thủ tục kiểm thử: các bước trong từng ca, cùng thủ tục thủ công ở mục 6 và mẫu tự động hóa ở mục 9.

Kế hoạch kiểm thử tổng thể ở D05-01. Tài liệu này kế thừa mọi quy định chung từ đó và theo đúng độ sâu của mẫu D05-02-PH07.

PH-04 có hai phần chạy rất khác nhau, nên được kiểm thử theo hai trục:

- **Control plane** `dh-integration`, module `flow`: API REST `/api/integration/v1` (API-04-001…091) và giao diện UI-04-01…21. Rủi ro chính là phân quyền, bốn mắt, xung đột soạn đồng thời, mất dữ liệu khi quay vòng YAML, và triển khai phiên bản chưa duyệt.
- **Data plane** `dh-runtime` và `dh-runtime-sandbox`: các luồng Camel đã phát hành. Rủi ro chính là rò rỉ tenant, lộ dữ liệu cá nhân trong log, ghi CSDL nguồn, nhận lệnh giả mạo, và mất bản tin.

Dẫn chiếu:

- Tài liệu PH-04: [FRS](../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md), [Use case](../../02-yeu-cau/use-case/D02-04-PH04-use-case-tich-hop.md), [SDD](../../03-thiet-ke/sdd/D03-02-PH04-sdd-tich-hop.md), [CSDL](../../03-thiet-ke/csdl/D03-03-PH04-csdl-tich-hop.md), [API](../../03-thiet-ke/api/D03-04-PH04-api-tich-hop.md), [Màn hình](../../03-thiet-ke/uiux/D03-06-PH04-man-hinh-tich-hop.md).
- Tài liệu nền: [D02-08](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md), [D03-10](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md), [D04-02](../../04-trien-khai/D04-02-ci-cd.md), [D05-01](../D05-01-ke-hoach-kiem-thu.md).

Khi kỳ vọng phân quyền mâu thuẫn, D02-08 được ưu tiên.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

| Đối tượng | Đơn vị triển khai | Ghi chú |
|---|---|---|
| Module `flow` (package `vn.datahub.integration.flow`) | `dh-integration` (Spring Boot 4, Java 21, Spring Modulith) | API-04-001…091, `ValidationEngine`, `SecretDetector`, `SqlPolicy`, `GitOpsWriter`, `CommandSigner`, `HeartbeatConsumer`, outbox `ph04.outbox` |
| Thư viện runtime `dh-runtime-lib` | Nhúng trong `dh-runtime` | Kamelet nền `dh-*-action`, `routeConfiguration` `dh-default-config`, `TenantGuard`, `FlowLoader`, `CommandListener`, hàm JQ `dh_map` |
| Ảnh runtime theo hồ sơ | `dh-runtime` (Camel Quarkus 3.33.2, Camel 4.18) | `core-native`, `files-native`, `soap-jvm`, `legacy-jvm` |
| Sandbox | `dh-runtime-sandbox` (namespace `dh-sandbox`, Q04-20) | Nhận lần chạy thử từ Valkey Stream `dh:int:testrun:queue` |
| Giao diện | `dh-console` (React, antd v6, Liquid Glass) | UI-04-01…21, đặc biệt trình thiết kế UI-04-04 và các cửa sổ 05…10 |
| Kho cấu hình | `dh-flows-{tenant}` + Argo CD ApplicationSet | Nhánh `env/test`, `env/staging`, `env/prod` |

Ngoài phạm vi, chỉ được giả lập:

- APISIX và Keycloak (kiểm thử ở D05-02 của PH-03 và PH-12);
- PH-05 kết nối, PH-02 API, PH-10 Hub (WireMock hoặc stub hợp đồng);
- hệ đích HTTT (WireMock);
- PH-13 (chỉ kiểm sự kiện, bản ghi được gửi đúng).

### 1.2. Mức kiểm thử

| Mức | Mục tiêu | Phạm vi chính | Công cụ | Chịu trách nhiệm | Khi chạy |
|---|---|---|---|---|---|
| Đơn vị (UT) | Logic thuần | Quy tắc VR-01…20, `SecretDetector`, `SqlPolicy` (JSqlParser), băm chuẩn hóa YAML, máy trạng thái, ký JCS, sinh JQ từ dhmap; phía frontend: chuyển đổi cây tài nguyên ↔ YAML, bố cục dagre, gộp ba bên | JUnit 5, AssertJ, jqwik, Vitest, fast-check | Lập trình viên | Mỗi commit (CI-2) |
| Tích hợp (IT) | Tương tác với hạ tầng thật | PostgreSQL 18 (RLS, trigger bất biến), Kafka, Valkey Stream, Git (Gitea), OpenBao transit, Camel context nạp YAML | Testcontainers, Spring Modulith Test, `@QuarkusTest` | Lập trình viên | Mỗi commit (CI-3) |
| Runtime (RT) | Luồng mẫu chạy đúng chín chặng | Kamelet nền, xử lý lỗi, chống trùng, `TenantGuard`, SQL Kamelet | `camel-test-junit5` trên Quarkus, WireMock, Testcontainers | Lập trình viên L-INT | Mỗi commit; ảnh native ở CI-8 |
| Hệ thống/API (ST) | API đầu cuối theo hợp đồng | Toàn bộ API-04, lỗi RFC 9457, phân quyền, tenant | REST Assured, Schemathesis trên `openapi-integration.yaml` | Kỹ sư kiểm thử | Khi hợp nhất; hằng đêm trên SIT |
| Giao diện E2E | Luồng người dùng | UI-04-01…21 | Playwright (Chromium, Firefox, WebKit), dữ liệu mồi qua API | Kỹ sư kiểm thử | Hằng đêm (CI-9) |
| GitOps (GO) | Đường Git → Argo CD → pod | Phát hành, nâng, quay lui, đối soát, dừng khẩn | k3d + Argo CD + Gitea trong SIT | Kỹ sư DevOps | Hằng đêm |
| Phi chức năng (NFT) | Hiệu năng, khả dụng | NFR-04-001…017 | k6, Lighthouse CI, Chrome DevTools trace, Chaos Mesh | Kỹ sư hiệu năng | Hằng tuần trên PERF; trước phát hành |
| Bảo mật (SEC) | Kiểm soát truy cập, injection, chuỗi cung ứng | ASVS 5.0 V4, V5, V8, V10, V12, V14 | OWASP ZAP, REST Assured, bộ YAML độc tự sinh, Trivy, Cosign verify | Kỹ sư ATTT | Hằng tuần; trước phát hành |
| Nghiệm thu (UAT) | Tương đương Bus và Tooling | Mục 7 | Thủ công trên UAT | Cán bộ vận hành Bus cũ của tỉnh thí điểm | Trước nghiệm thu |

### 1.3. Môi trường kiểm thử

| Môi trường | Thành phần | Ghi chú |
|---|---|---|
| CI | Testcontainers: PostgreSQL 18, Kafka KRaft, Valkey 8, Gitea (thay GitHub, GitLab), OpenBao dev, WireMock. Runtime chạy trong JVM | Schema `ph04` tạo bằng Liquibase. Vai trò ứng dụng `ph04_app` không có `BYPASSRLS` |
| SIT | k3d 3 nút; Argo CD; Gitea với kho `dh-flows-t68`, `dh-flows-t01`; Keycloak realm `dh-t68`, `dh-t01`, `dh-platform`; APISIX `apisix-int`; OPA; `dh-integration` 2 bản sao; `dh-runtime` hồ sơ `core-native` 2 bản sao, `soap-jvm` 1 bản sao cho mỗi tenant; `dh-runtime-sandbox` 2 bản sao; Kafka 3 broker; Debezium; Ceph RGW (hoặc MinIO tương thích S3); PostgreSQL nguồn giả lập cho Q359 | Nạp lại bộ dữ liệu mục 2 mỗi đêm |
| PERF | Như SIT; `dh-runtime` native 4 bản sao, mỗi bản sao 1 vCPU, 512 MiB; WireMock đích trả trong 20 ms | Quy mô theo GĐ: 300 luồng mỗi tenant, 3 tenant |
| UAT | Như SIT; luồng chuyển từ gói XML Bus cũ của tỉnh thí điểm, đã gỡ mật khẩu (Q04-49) | Cán bộ vận hành Bus cũ thao tác |

### 1.4. Công cụ

| Công cụ | Dùng cho | Ghi chú |
|---|---|---|
| JUnit 5, AssertJ, jqwik | UT, IT | Thẻ `@Tag("tenant-leak")`, `@Tag("four-eyes")`, `@Tag("signed-command")`, `@Tag("q359")` để lọc nhóm bắt buộc |
| Vitest, fast-check | UT frontend | Kiểm thử theo thuộc tính cho quay vòng cây ↔ YAML (BR-04-006) |
| Testcontainers | IT | Lớp cơ sở `IntegrationFlowTestBase` dùng chung container theo lớp |
| `camel-test-junit5`, `@QuarkusTest` | RT | Nạp luồng mẫu từ `src/test/resources/flows/*.camel.yaml` |
| REST Assured, Schemathesis | ST | Token thử ký bằng khóa thử ở CI; token thật ở SIT |
| Playwright, `@axe-core/playwright` | E2E, truy cập | Ghi trace khi lỗi; kéo thả dùng `page.mouse` với tọa độ thật |
| k6, Lighthouse CI | Hiệu năng | `xk6-kafka` cho luồng bất đồng bộ |
| Chaos Mesh | Hỗn loạn | Giết pod runtime, cắt Kafka, làm chậm Git |
| OWASP ZAP | Quét động | Ngữ cảnh xác thực theo vai trò |
| WireMock | Hệ đích, PH-05, PH-02, PH-10 | Kịch bản có trạng thái: `OK`, `SLOW_5S`, `HTTP_500`, `TIMEOUT`, `FLAKY_50` |
| Gitea | Kho cấu hình | Webhook giả lập merge request cho `env/prod` |

### 1.5. Tiêu chí vào và ra

**Tiêu chí vào** một đợt kiểm thử hệ thống:

- Bản dựng đã qua CI-1…8.
- Độ phủ dòng của module `flow` ≥ 80%. Độ phủ nhánh của `ValidationEngine`, `SecretDetector`, `SqlPolicy`, `CommandSigner`, máy trạng thái phiên bản ≥ 90%.
- `openapi-integration.yaml` khớp mã (Schemathesis không lỗi).
- Ca khói TC-04-001, TC-04-011, TC-04-060, TC-04-090 đạt trên SIT.

**Tiêu chí ra:**

- 100% ca P1 đạt.
- ≥ 95% ca P2 đạt; ca chưa đạt không thuộc nhóm bảo mật, tenant hay bốn mắt.
- 100% ca có thẻ `tenant-leak`, `four-eyes`, `signed-command`, `q359` đạt.
- Không còn lỗi mức Nghiêm trọng hoặc Cao.
- NFR-04-007…013 đạt trong hai lần đo liên tiếp.
- ZAP không có cảnh báo mức Cao.
- axe-core không có vi phạm "serious" hoặc "critical" trên UI-04-01, 04, 11, 14, 15.
- Ma trận mục 8 đạt 100% với FR mức M, BR và ERR.

**Tiêu chí tạm dừng:**

- Bất kỳ ca rò rỉ tenant nào không đạt.
- Runtime nạp được luồng không đi qua Git.
- Hơn 20% ca khói thất bại.

### 1.6. Quy ước mã và cách trình bày

Kịch bản có mã `TS-04-nn`, test case có mã `TC-04-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã (D00-01 §3.1). Mỗi test case là một khối có cấu trúc thống nhất với D05-02-PH07:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, RT, API, E2E, GO, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC liên quan.
- **Tiền điều kiện / dữ liệu**: tham chiếu mã dữ liệu ở mục 2.
- **Bước**: đánh số. Đường dẫn API tương đối với `/api/integration/v1`, trừ đường dẫn gọi luồng (ghi đầy đủ qua `apisix-int`).
- **Mong đợi**: mã HTTP, mã lỗi, trạng thái dữ liệu sau, sự kiện, kiểm toán.

Quy ước rút gọn trong phần mong đợi:

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-04-045 (thiếu quyền chức năng) |
| 404-ẩn | `404` với ERR-04-001, không phân biệt "không tồn tại" và "không được xem" (D03-10 §6 quy tắc 6) |
| KT: có (hành động) | Có bản ghi kiểm toán gửi PH-13 với hành động đó, đủ trường theo FR-00-041 |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: không | Sau 10 giây không có dòng mới trong `ph04.outbox` và không có bản tin trên topic liên quan |
| Git: không | Không có commit mới trên mọi nhánh `env/*` của kho tenant |

### 1.7. Quản lý lỗi và báo cáo

Lỗi ghi vào hệ thống quản lý lỗi với nhãn `PH-04`, mã test case, mức nghiêm trọng và `traceId`. Các lỗi sau luôn xếp mức Nghiêm trọng:

- runtime nạp định nghĩa chưa duyệt;
- phiên bản đã gửi duyệt bị sửa;
- người tự duyệt được phiên bản của mình;
- lệnh không chữ ký hoặc hết hạn được thực thi;
- luồng ghi được vào CSDL nguồn;
- bản tin của tenant này đi vào runtime hoặc topic của tenant khác;
- giá trị bí mật hay trường cá nhân xuất hiện trong log.

Báo cáo tiến độ sinh hằng đêm từ JUnit, Playwright, k6 và đối chiếu với ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Mọi số định danh, tên người, cơ quan chỉ dùng cho kiểm thử. Bộ dữ liệu nạp bằng `ph04/seed/` qua API (không chèn SQL trực tiếp, để đi qua đúng quy tắc).

### 2.1. Tenant

| Mã tenant | Ý nghĩa | Realm | Kho cấu hình | Ghi chú |
|---|---|---|---|---|
| `T68` | Tỉnh chính (Lâm Đồng, giả lập) | `dh-t68` | `dh-flows-t68` | `04.env.stages = TEST,STAGING,PROD` để phủ thứ tự môi trường; `04.workspace.enforce = true` trừ khi ca ghi khác |
| `T01` | Tỉnh đối chứng rò rỉ | `dh-t01` | `dh-flows-t01` | Có luồng **trùng mã** `tra-cuu-ho-tich` với T68 nhưng khác nội dung, để phát hiện trả nhầm |
| `PLATFORM` | Quản trị nền tảng | `dh-platform` | — | Chính sách thành phần nền, khuôn nền |

### 2.2. Người dùng

Tên nhân vật trùng với use case D02-04-PH04 để người đọc dễ đối chiếu. Vai trò theo D02-08.

| Mã dữ liệu | Tenant | Vai trò | Không gian, mức | Nhân vật | Mục đích |
|---|---|---|---|---|---|
| U-PA | PLATFORM | PA | — | Đỗ Quang Khải | Chính sách nền, quyết định đề xuất |
| U-T68-TA | T68 | TA | (không giới hạn) | Lê Thu Hà | Không gian, tham số, đóng băng, dừng khẩn |
| U-T68-TO | T68 | TO | — | Vũ Minh Tuấn | Tạm dừng, tiếp tục |
| U-T68-SO | T68 | SO | — | Phạm Thu Dung | Dừng khẩn, duyệt chính sách |
| U-T68-IE1 | T68 | IE | WS-HOTICH `EDIT` | Nguyễn Văn An | Người soạn chính |
| U-T68-IE2 | T68 | IE | WS-HOTICH `EDIT`, WS-DATDAI `EDIT` | Trần Thị Bình | Người soạn thứ hai, xung đột đồng thời, người đóng góp |
| U-T68-IE3 | T68 | IE | WS-DATDAI `EDIT` | Hoàng Văn Sơn | Kiểm thử phạm vi không gian (không có quyền ở WS-HOTICH) |
| U-T68-IA1 | T68 | IA | WS-HOTICH `MAINTAIN` | Lê Văn Cường | Người duyệt chính |
| U-T68-IA2 | T68 | IA + IE | WS-HOTICH `MAINTAIN` + `EDIT` | Đặng Thị Mai | Vừa soạn vừa duyệt, kiểm thử bốn mắt |
| U-T68-VW | T68 | VW | WS-HOTICH `VIEW` | — | Chỉ đọc |
| U-T68-AU | T68 | AU | — | — | Lịch sử, kiểm toán |
| U-T01-IE | T01 | IE | DEFAULT `EDIT` | — | Đối chứng rò rỉ |
| U-T01-TA | T01 | TA | — | — | Đối chứng rò rỉ |

Mọi người dùng có vai trò TA, SO, IA, PA đã đăng ký TOTP thử trong realm SIT, để không vướng FR-00-002 và để kiểm thử xác thực lại (`auth_time`).

### 2.3. Không gian làm việc

| Mã | Tenant | Thành viên | Ghi chú |
|---|---|---|---|
| WS-HOTICH | T68 | IE1, IE2 `EDIT`; IA1, IA2 `MAINTAIN`; VW `VIEW` | Mã `ho-tich` |
| WS-DATDAI | T68 | IE2, IE3 `EDIT` | Mã `dat-dai` |
| WS-ARCH | T68 | — | Đã lưu trữ, không chọn được khi tạo luồng |
| DEFAULT | T68, T01 | — | Không gian mặc định khi `04.workspace.enforce = false` |

### 2.4. Luồng mẫu

| Mã dữ liệu | Mã luồng | Tenant, không gian | Loại | Trạng thái ban đầu | Mô tả |
|---|---|---|---|---|---|
| F-HT | `tra-cuu-ho-tich` | T68, WS-HOTICH | ROUTE, SYNC, EXTERNAL | v3 `APPROVED`, chạy ở TEST, STAGING, PROD (`SYNCED`, `HEALTHY`); v4 `DRAFT` do IE1 tạo | Chín chặng: nhận REST `POST /ho-tich/tra-cuu`, kiểm lược đồ, OPA, JQ, làm giàu từ PH-07, gọi HTTT hộ tịch qua CONN-HT, kiểm toán, trả lời có che trường |
| F-DD | `dong-bo-dat-dai` | T68, WS-DATDAI | ROUTE, ASYNC, INTERNAL | v1 `APPROVED`, PROD | Nghe `t68.datdai.thua-dat.changed.v1`, chuyển CDM, gửi `t68.cdm.thua-dat.v1` |
| F-SQL | `doc-dkkd-sql` | T68, WS-DATDAI | ROUTE, SCHEDULED, INTERNAL | v1 `APPROVED`, TEST | Q359: `SELECT` theo lịch từ CSDL ĐKKD giả lập qua CONN-DKKD-RO |
| F-SOAP | `bhxh-soap` | T68, WS-HOTICH | ROUTE, SYNC, EXTERNAL | v2 `APPROVED`, PROD, hồ sơ `soap-jvm` | Gọi dịch vụ SOAP BHXH giả lập qua `cxf` |
| F-NEW | (tạo trong ca) | T68 | — | — | Mã do ca đặt, tiền tố `tc-` |
| F-KAM | `dh-ma-hoa-cccd-action` | T68, WS-HOTICH | KAMELET | v1 `DRAFT` | Kamelet tự viết che số định danh |
| F-T01 | `tra-cuu-ho-tich` | T01, DEFAULT | ROUTE | v1 `APPROVED`, PROD | Đối chứng: trả trường `tinh = "T01"` |

### 2.5. Kết nối, topic, khuôn mẫu

| Mã dữ liệu | Loại | Giá trị | Ghi chú |
|---|---|---|---|
| CONN-HT | PH-05 `http` | Có giá trị TEST, STAGING, PROD (WireMock) | Cấp cho WS-HOTICH |
| CONN-NOTEST | PH-05 `http` | Chỉ có giá trị PROD | Kiểm thử ERR-04-013 khi `SANDBOX_LIVE` |
| CONN-DKKD-RO | PH-05 `postgres-readonly` | Tài khoản `rd_doc_dkkd_sql` chỉ có `SELECT` trên `dkkd.doanh_nghiep` | Q359 |
| CONN-DKKD-RW | PH-05 `postgres` | Tài khoản có `INSERT` | Kiểm thử từ chối kết nối không phải chỉ đọc |
| CONN-DD-ONLY | PH-05 `http` | Chỉ cấp cho WS-DATDAI | Kiểm thử "chưa cấp cho không gian" |
| TOPIC-HT-REQ | PH-10 | `t68.hotich.yeucau.v1` | F-HT được publish |
| TOPIC-NOACL | PH-10 | `t68.thue.v1` | Đã đăng ký nhưng luồng không có quyền |
| TOPIC-T01 | PH-10 | `t01.hotich.yeucau.v1` | Topic của tenant khác |
| TPL-REST | Khuôn nền | `tpl-rest-proxy-9-chang` | Có `paramSchema` gồm `path`, `connection`, `schemaRef` |
| TPL-KAFKA | Khuôn nền | `tpl-kafka-cdm` | |

### 2.6. Bản tin và tệp mẫu

| Mã | Nội dung | Kích thước |
|---|---|---|
| MSG-OK | `{"soDinhDanh":"001099000001","hoTen":"Nguyễn Văn Thử","ngaySinh":"1990-01-01"}` (giả lập) | 0,1 KiB |
| MSG-NOID | MSG-OK bỏ `soDinhDanh` | 0,1 KiB |
| MSG-BIG | Mảng lặp MSG-OK | 300 KiB (vượt 256 KiB chạy thử) |
| MSG-RT-BIG | Thân gọi luồng | 11 MiB (vượt `04.runtime.max-body-kb` 10.240) |
| MSG-PII | MSG-OK có thêm `soDienThoai`, `email` thật dạng | Kiểm cảnh báo dữ liệu cá nhân |
| MSG-TENANT | MSG-OK kèm tiêu đề `dh-tenant: T01` | Kiểm `TenantGuard` |
| YAML-OK | YAML của F-HT v3 | 18 KiB |
| YAML-SECRET | YAML-OK có `password=Abc@12345678` trong URI | |
| YAML-BOMB | YAML "billion laughs" 10 tầng bí danh | 1 KiB |
| YAML-BIG | Định nghĩa 600 KiB | Vượt 512 KiB |
| YAML-200 | Luồng 200 chặng | Dùng cho hiệu năng |
| XML-OK | Gói Camel XML Bus cũ 3 route (REST, Kafka, timer) | 40 KiB |
| XML-EXEC | Camel XML có `exec:` | |
| XML-BAD | Tệp không phải Camel XML | |

### 2.7. Nguyên tắc dữ liệu

Ca không phụ thuộc thứ tự chạy, trừ khi ghi rõ "sau TC-…". Ca tạo dữ liệu dùng mã tiền tố `tc-{số ca}` và tự dọn bằng API gỡ. Ca hiệu năng dùng bộ dữ liệu sinh riêng ở PERF. Không ca nào dùng dữ liệu cá nhân thật. Bản tin mẫu có dạng số định danh đều là giá trị thử.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

| Kịch bản | Tên | FR chính | UC |
|---|---|---|---|
| TS-04-01 | Không gian làm việc và thành viên | 007 | 01 |
| TS-04-02 | Danh sách, tìm kiếm, chi tiết luồng | 001, 002 | 02 |
| TS-04-03 | Tạo luồng từ luồng trống, khuôn, API, YAML | 003, 025 | 03 |
| TS-04-04 | Sửa thông tin, nhân bản, hủy nháp, gỡ luồng | 004, 005, 006 | 16 |
| TS-04-05 | Phiên bản, lưu nháp, ETag, phiên soạn, gộp ba bên | 010, 011, 024 | 04 |
| TS-04-06 | Trình thiết kế: bảng thành phần, sơ đồ, cấu hình chặng | 012, 013, 014 | 04, 05 |
| TS-04-07 | Quay vòng YAML, tải xuống, nhập YAML | 017, 027 | 04 |
| TS-04-08 | Biểu thức, kết nối, bí mật, bản tin mẫu | 015, 016, 022 | 05 |
| TS-04-09 | Trình ánh xạ dữ liệu | 020 | 06 |
| TS-04-10 | Kamelet, Pipe, bean, ghi chú, luồng con | 018, 019, 021, 026 | 07 |
| TS-04-11 | Kiểm tra hợp lệ VR-01…20 | 023 | 04 |
| TS-04-12 | Chạy thử trên sandbox | 030, 032, 033 | 08 |
| TS-04-13 | Ca kiểm thử của luồng | 031 | 09 |
| TS-04-14 | Gửi duyệt, rút lại | 040 | 10 |
| TS-04-15 | Duyệt bốn mắt và so sánh phiên bản | 041, 043 | 11 |
| TS-04-16 | Phát hành GitOps và nâng môi trường | 042, 045 | 12 |
| TS-04-17 | Quay lui | 044 | 13 |
| TS-04-18 | Lệnh runtime có ký: tạm dừng, tiếp tục, dừng khẩn, đối soát | 050 | 14, 15 |
| TS-04-19 | Tình trạng runtime, điểm kết nối, giám sát, lịch sử | 051, 052, 053, 083 | 02 |
| TS-04-20 | Data plane đồng bộ qua chín chặng | 060, 061, 063…068 | 17 |
| TS-04-21 | Data plane bất đồng bộ, xử lý lỗi, chống trùng | 062, 069, 070, 071 | 18 |
| TS-04-22 | Truy cập CSDL có kiểm soát (Q359) | 072 | 19 |
| TS-04-23 | Ngữ cảnh tenant và rò rỉ chéo tenant | 073 | 17, 18 |
| TS-04-24 | Ma trận phân quyền và phạm vi không gian làm việc | 007, mọi FR | — |
| TS-04-25 | Catalog, chính sách thành phần, hồ sơ runtime | 075, 080, 081 | 21, 22 |
| TS-04-26 | Chuyển Camel XML của Bus cũ | 082 | 20 |
| TS-04-27 | Tham số PH-04 và đóng băng thay đổi | 084 | 7.1 |
| TS-04-28 | Sự kiện, outbox và hợp đồng API | 074, mọi EVT | — |
| TS-04-29 | Hiệu năng | NFR-04-001…013 | — |
| TS-04-30 | Bảo mật (ASVS) | — | — |
| TS-04-31 | Khả dụng và hỗn loạn | NFR-04-014 | — |
| TS-04-32 | Truy cập, bàn phím và bề rộng màn hình | NFR-04-015…017 | — |

### 3.2. Máy trạng thái được kiểm thử

Mỗi chuyển trạng thái hợp lệ có ít nhất một ca dương tính. Mỗi chuyển không hợp lệ quan trọng có ít nhất một ca âm tính. Máy trạng thái theo SDD §9.

| Máy | Chuyển hợp lệ (ca) | Chuyển bị cấm (ca) |
|---|---|---|
| Phiên bản | DRAFT → PENDING_REVIEW (TC-04-110); PENDING_REVIEW → DRAFT khi rút (TC-04-114); PENDING_REVIEW → APPROVED (TC-04-120); PENDING_REVIEW → CHANGES_REQUESTED (TC-04-121); CHANGES_REQUESTED → PENDING_REVIEW (TC-04-122); DRAFT → DISCARDED (TC-04-034); APPROVED → SUPERSEDED (TC-04-131) | Sửa PENDING_REVIEW, APPROVED (TC-04-045, 116); duyệt DRAFT (TC-04-126); phát hành DRAFT (TC-04-135) |
| Triển khai | PENDING → SYNCING → SYNCED (TC-04-130); PENDING → FAILED do Git (TC-04-137); SYNCING → FAILED do quá hạn (TC-04-138); SYNCED → OUT_OF_SYNC khi lệch băm (TC-04-163) | — |
| Lệnh | ISSUED → ACKNOWLEDGED (TC-04-150); ISSUED → PARTIAL (TC-04-155); PARTIAL → ACKNOWLEDGED khi gửi lại (TC-04-156); ISSUED → REJECTED (TC-04-157…160); ACKNOWLEDGED → RECONCILED (TC-04-153) | Lệnh hết hạn được thực thi (TC-04-158) |
| Lần chạy thử | QUEUED → RUNNING → PASSED, FAILED (TC-04-090, 091); RUNNING → TIMED_OUT (TC-04-094); QUEUED → CANCELLED (TC-04-096) | Mô phỏng được tính cho gửi duyệt (TC-04-113) |
| Luồng | ACTIVE → PAUSED → ACTIVE (TC-04-150, 151); ACTIVE → RETIRED (TC-04-036) | Sửa luồng RETIRED (TC-04-038) |

## 4. Kịch bản và test case chức năng

### TS-04-01 · Không gian làm việc và thành viên

**Mục tiêu.** Xác nhận không gian làm việc giới hạn đúng quyền sửa, duyệt theo thành viên khi `04.workspace.enforce` bật, và không ảnh hưởng khi tắt. Đây là sự kế thừa `Project`, `Project_group.access_level` của Bus cũ (LGC-BUS-032).

**Phủ.** FR-04-007; BR-04-021; UC-04-01; API-04-001…004; UI-04-21; ERR-04-017, 027, 028.

**Tiền điều kiện chung.** Bộ dữ liệu mục 2 đã nạp; `04.workspace.enforce = true`.

#### TC-04-### · Liệt kê, tạo và sửa không gian làm việc <!--k:ws-crud-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-007 · API-04-001, 002 · UI-04-21 · UC-04-01 · LGC-BUS-032
- **Tiền điều kiện / dữ liệu** Người gọi U-T68-TA.
- **Bước**
  1. Gọi `GET /workspaces`.
  2. Gọi `POST /workspaces` với `{"code":"tc-thue","name":"Thuế (thử)"}` và `Idempotency-Key`.
  3. Gửi lại bước 2 cùng khóa, cùng thân.
  4. Gọi `PATCH /workspaces/tc-thue` với `If-Match` từ bước 2, đổi `name`.
- **Mong đợi** Bước 1 trả `200` với WS-HOTICH, WS-DATDAI, WS-ARCH (trạng thái `ARCHIVED`) và DEFAULT; mỗi phần tử có `flowCount`, `allowedActions`. Bước 2 trả `201`. Bước 3 trả lại đúng phản hồi bước 2, không tạo bản ghi thứ hai. Bước 4 trả `200`, `ETag` mới. KT: có (`INT_WORKSPACE_CREATE`, `INT_WORKSPACE_UPDATE`).

#### TC-04-### · Tạo không gian trùng mã, sửa không gian không tồn tại <!--k:ws-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-007 · API-04-002 · ERR-04-027, 028
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. Gọi `POST /workspaces` với `code = "ho-tich"`.
  2. Gọi `PATCH /workspaces/khong-co` có `If-Match`.
  3. U-T68-IE1 gọi `POST /workspaces` với mã mới.
- **Mong đợi** Bước 1 trả `409` ERR-04-028. Bước 2 trả `404` ERR-04-027. Bước 3 trả 403-PQ (IE không có `PERM-04-admin`). KT: không với bước 1, 2.

#### TC-04-### · Thay danh sách thành viên và hiệu lực ngay <!--k:ws-members-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-007 · BR-04-021 · API-04-004, 022 · UC-04-01
- **Tiền điều kiện / dữ liệu** U-T68-IA1 (mức `MAINTAIN` trên WS-HOTICH); F-HT v4 `DRAFT`.
- **Bước**
  1. U-T68-IE3 gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft` với nội dung hợp lệ.
  2. U-T68-IA1 gọi `PUT /workspaces/ho-tich/members`, thêm IE3 mức `EDIT`.
  3. IE3 lặp bước 1 với `If-Match` mới.
- **Mong đợi** Bước 1 trả `403` ERR-04-003. Bước 2 trả `200`. Bước 3 trả `200` không cần đăng nhập lại (quyền không gian tra theo yêu cầu, không nằm trong token). KT: có (`INT_WORKSPACE_MEMBERS` ghi danh sách thêm, bớt).

#### TC-04-### · Thành viên mức VIEW và người ngoài không gian <!--k:ws-scope-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-007 · BR-04-021 · API-04-010, 012, 022 · ERR-04-003
- **Tiền điều kiện / dữ liệu** U-T68-VW (VIEW trên WS-HOTICH), U-T68-IE3 (chỉ WS-DATDAI).
- **Bước**
  1. VW gọi `GET /flows/tra-cuu-ho-tich`.
  2. VW gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft`.
  3. IE3 gọi `GET /flows?workspace=ho-tich`.
  4. IE3 gọi `GET /flows/tra-cuu-ho-tich`.
- **Mong đợi** Bước 1 trả `200`, `allowedActions` không có `EDIT`, `disabledReasons.EDIT` nêu "chỉ có quyền xem trong không gian Hộ tịch". Bước 2 trả `403` ERR-04-003. Bước 3 trả `200` với `items` rỗng, lọc ở SQL chứ không ở ứng dụng (kiểm bằng log câu lệnh ở IT). Bước 4 trả 404-ẩn.

#### TC-04-### · Tắt giới hạn không gian làm việc <!--k:ws-off-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-007, 084 · BR-04-021
- **Tiền điều kiện / dữ liệu** U-T68-TA đặt `04.workspace.enforce = false` qua PH-18.
- **Bước**
  1. IE3 gọi lại bước 2 của TC ở trên với F-HT v4.
  2. TA bật lại tham số; IE3 gọi lại.
- **Mong đợi** Bước 1 trả `200` (chỉ quyền chức năng có hiệu lực). Bước 2 trả `403` ERR-04-003 trong vòng 60 giây sau khi bật (bộ đệm tham số).

#### TC-04-### · Lưu trữ không gian còn luồng <!--k:ws-archive-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-04-007 · API-04-003, 011 · ERR-04-017, 027 · UI-04-03
- **Tiền điều kiện / dữ liệu** U-T68-TA; không gian `tc-thue` (từ ca đầu) có một luồng nháp.
- **Bước**
  1. Gọi `POST /workspaces/tc-thue:archive`.
  2. IE1 mở UI-04-03 bước 1, mở ô "Không gian làm việc".
  3. IE1 gọi `POST /flows` với `workspaceCode = "tc-thue"`.
- **Mong đợi** Bước 1 trả `200`, `status = ARCHIVED`, luồng cũ vẫn xem được. Bước 2 không có `tc-thue` trong danh sách. Bước 3 trả `409` ERR-04-005 với `detail` "Không gian làm việc đã lưu trữ". KT: có (`INT_WORKSPACE_ARCHIVE`).

### TS-04-02 · Danh sách, tìm kiếm, chi tiết luồng

**Mục tiêu.** Thay màn danh sách chương trình tích hợp và các ô tìm theo endpoint, nguồn, tên, host của Bus cũ.

**Phủ.** FR-04-001, 002; UC-04-02; API-04-010, 012, 016; UI-04-01, 02; ERR-04-001, 026, 049; LGC-BUS-001…008, 017, 018.

#### TC-04-### · Liệt kê luồng có lọc, đếm theo trạng thái <!--k:list-flows-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-001 · API-04-010 · UI-04-01 · LGC-BUS-001, 003, 004, 005
- **Tiền điều kiện / dữ liệu** T68 có F-HT, F-DD, F-SQL, F-SOAP, F-KAM; người gọi U-T68-TA.
- **Bước**
  1. Gọi `GET /flows?limit=25`.
  2. Gọi `GET /flows?status=ACTIVE&environment=PROD`.
  3. Gọi `GET /flows?q=ho tich` (không dấu).
  4. Gọi `GET /flows?resourceKind=KAMELET`.
  5. Gọi `GET /flows?label=nguon:bhxh`.
- **Mong đợi** Bước 1 trả `200` với 5 luồng, sắp `-updatedAt`, `facets.status` đếm đúng, không có F-T01. Bước 2 trả F-HT, F-DD, F-SOAP. Bước 3 trả F-HT. Bước 4 trả F-KAM. Bước 5 trả F-SOAP. Mỗi phần tử có `environments[]` với `syncStatus`, `healthStatus`, `openVersionNo`. KT: không.

#### TC-04-### · Tìm theo endpoint <!--k:list-endpoint-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-001 · API-04-010 · LGC-BUS-002
- **Tiền điều kiện / dữ liệu** F-HT có điểm vào `platform-http:/ho-tich/tra-cuu` và điểm ra qua CONN-HT.
- **Bước**
  1. Gọi `GET /flows?endpoint=/ho-tich/`.
  2. Gọi `GET /flows?endpoint=CONN-HT`.
  3. Gọi `GET /flows?endpoint=password` (chuỗi không nằm trong URI đã che).
- **Mong đợi** Bước 1, 2 trả F-HT. Bước 3 trả rỗng. Chỉ mục EN-04-04b chỉ chứa URI đã che tham số nhạy cảm.

#### TC-04-### · Tham số danh sách không hợp lệ <!--k:list-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-001 · API-04-010 · ERR-04-026, 049
- **Tiền điều kiện / dữ liệu** U-T68-VW.
- **Bước**
  1. Gọi `GET /flows?limit=100`.
  2. Gọi `GET /flows?limit=101`.
  3. Gọi `GET /flows?status=RUNNING`.
  4. Gọi `GET /flows?sort=drop`.
  5. Gọi `GET /flows?q=a` (1 ký tự).
  6. Gọi `GET /flows?cursor=abc` (con trỏ giả).
- **Mong đợi** Bước 1 trả `200`. Bước 2 trả `400` ERR-04-026. Bước 3, 4, 5, 6 trả `400` ERR-04-049 có `errors[].path` chỉ tham số sai, không lộ chi tiết SQL hay ngăn xếp.

#### TC-04-### · Chi tiết luồng đầy đủ <!--k:flow-detail-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-002 · API-04-012, 024, 054, 060 · UI-04-02 · LGC-BUS-006, 008, 017, 018
- **Tiền điều kiện / dữ liệu** F-HT; người gọi U-T68-VW.
- **Bước**
  1. Gọi `GET /flows/tra-cuu-ho-tich`.
  2. Mở UI-04-02, lần lượt các tab Tổng quan, Sơ đồ (chỉ đọc), YAML, Phiên bản, Triển khai, Điểm kết nối, Lịch sử.
- **Mong đợi** Bước 1 trả `200`, `ETag`, `routes[]` có `routeId`, `fromUri`, `stepCount`; `environments` có ba môi trường đều v3. Bước 2: sơ đồ hiện chín khối chặng chuẩn; YAML chỉ đọc; tab Lịch sử ẩn cột "trước/sau" với VW. Không nút nào ngoài "Xem", "Tải YAML".

#### TC-04-### · Chi tiết luồng không tồn tại hoặc ở tenant khác <!--k:flow-404-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-002 · API-04-012 · ERR-04-001
- **Tiền điều kiện / dữ liệu** U-T68-VW; F-T01 chỉ có ở T01.
- **Bước**
  1. Gọi `GET /flows/khong-co`.
  2. U-T01-IE tạo luồng `tc-chi-t01`; U-T68-VW gọi `GET /flows/tc-chi-t01`.
- **Mong đợi** Cả hai trả `404` ERR-04-001, thân giống nhau trừ `traceId` (không phân biệt được tồn tại hay không).

#### TC-04-### · Phụ thuộc của luồng <!--k:deps-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-002, 006 · API-04-016
- **Tiền điều kiện / dữ liệu** F-HT được API `ho-tich-tra-cuu` của PH-02 dùng (stub), được ca kiểm thử của chính nó dùng, và F-DD gọi `direct:` tới nó (giả lập).
- **Bước**
  1. Gọi `GET /flows/tra-cuu-ho-tich/dependencies`.
- **Mong đợi** `200`; `hard` có `API` (PH-02) và `FLOW` (F-DD); `soft` có `TEST_CASE`. PH-02 không trả lời trong 5 giây thì `503` ERR-04-047, không trả danh sách thiếu.

### TS-04-03 · Tạo luồng từ luồng trống, khuôn, API, YAML

**Mục tiêu.** Xác nhận bốn nguồn tạo luồng, ràng buộc mã, và việc tạo luồng chỉ sinh phiên bản 1 `DRAFT`, không chạm runtime.

**Phủ.** FR-04-003, 025; BR-04-001, 002, 003; UC-04-03; API-04-011, 031, 080, 081; UI-04-03, 19; ERR-04-002, 008, 009, 010, 018, 027, 033, 039; EVT-04-01; LGC-BUS-013, LGC-TOOL-001.

#### TC-04-### · Tạo luồng trống <!--k:create-blank-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-003 · API-04-011 · UI-04-03 · UC-04-03 · EVT-04-01 · LGC-BUS-013
- **Tiền điều kiện / dữ liệu** U-T68-IE1; mã `tc-trong`.
- **Bước**
  1. Gọi `POST /flows` với `{"code":"tc-trong","name":"Thử luồng trống","workspaceCode":"ho-tich","resourceKind":"ROUTE","origin":"BLANK"}` và `Idempotency-Key`.
  2. Gọi `GET /flows/tc-trong/versions/1`.
  3. Đếm commit trên kho `dh-flows-t68`.
- **Mong đợi** Bước 1 trả `201`, `ETag`, `status = DRAFT`, `openVersionNo = 1`. Bước 2: YAML có khung chín chặng rỗng với `routeConfigurationId: dh-default-config`, `catalogVersion` bằng catalog hiện hành. Bước 3: Git: không. EVT-04-01 trong outbox cùng giao dịch, khóa `T68:{flowId}`. KT: có (`INT_FLOW_CREATE`).

#### TC-04-### · Tạo luồng từ khuôn có tham số <!--k:create-template-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-003, 025 · API-04-080, 081, 011 · UI-04-19 · UC-04-03
- **Tiền điều kiện / dữ liệu** TPL-REST.
- **Bước**
  1. Gọi `GET /templates?resourceKind=ROUTE`.
  2. Gọi `GET /templates/tpl-rest-proxy-9-chang`.
  3. Gọi `POST /flows` với `origin = TEMPLATE`, `templateCode`, `templateParams = {"path":"/tc/khuon","connection":"CONN-HT","schemaRef":"hotich-yeucau-v1"}`.
- **Mong đợi** Bước 1 có TPL-REST, `scope = PLATFORM`. Bước 3 trả `201`; YAML có `path: /tc/khuon`, tham chiếu `{{conn:CONN-HT}}`; bố cục lấy `previewLayout` của khuôn. `origin = TEMPLATE`, `templateCode` lưu ở luồng.

#### TC-04-### · Tạo luồng từ OpenAPI của API công bố <!--k:create-openapi-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-003 · API-04-011
- **Tiền điều kiện / dữ liệu** PH-02 stub trả OpenAPI có 3 operation.
- **Bước**
  1. Gọi `POST /flows` với `origin = OPENAPI`, `apiRef = "ho-tich-tra-cuu"`.
- **Mong đợi** `201`; YAML có khối `rest` với 3 operation, mỗi operation một route `direct:` có khung chín chặng; `transport = SYNC`, `exposure = EXTERNAL`.

#### TC-04-### · Tạo luồng từ tệp YAML <!--k:create-yaml-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-003, 027 · API-04-031, 011
- **Tiền điều kiện / dữ liệu** YAML-OK đổi mã route và đường dẫn sang `tc-`.
- **Bước**
  1. Gọi `POST /validation:check` với YAML.
  2. Gọi `POST /flows` với `origin = YAML_FILE`, `yaml`.
- **Mong đợi** Bước 1 trả `200`, `errorCount = 0`, không ghi gì (EVT: không). Bước 2 trả `201`; băm chuẩn hóa của định nghĩa đã lưu bằng băm chuẩn hóa của tệp tải lên.

#### TC-04-### · Mã luồng sai định dạng hoặc trùng <!--k:create-code-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-003 · BR-04-001 · API-04-011 · ERR-04-002, 049
- **Tiền điều kiện / dữ liệu** U-T68-IE1; luồng `tc-da-go` đã gỡ 10 ngày trước; luồng `tc-go-cu` đã gỡ 31 ngày trước.
- **Bước**
  1. Tạo với `code = "tra-cuu-ho-tich"`.
  2. Tạo với `code = "Tra_Cuu"`, `"ab"`, chuỗi 64 ký tự.
  3. Tạo với `code = "tc-da-go"`.
  4. Tạo với `code = "tc-go-cu"`.
- **Mong đợi** Bước 1, 3 trả `409` ERR-04-002. Bước 2 trả `400` ERR-04-049 (mẫu `^[a-z][a-z0-9-]{2,62}$`). Bước 4 trả `201` (mã giải phóng sau 30 ngày). Mã trùng với F-T01 ở T01 không bị chặn ở T68 (đã có ở dữ liệu).

#### TC-04-### · Tạo luồng với nội dung không hợp lệ <!--k:create-content-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-003 · BR-04-003 · API-04-011 · ERR-04-008, 009, 010, 027, 033, 039
- **Tiền điều kiện / dữ liệu** YAML-SECRET, YAML-BIG; YAML cú pháp hỏng; YAML Kamelet nhưng `resourceKind = ROUTE`.
- **Bước**
  1. Tạo `origin = YAML_FILE` với YAML cú pháp hỏng.
  2. Tạo với YAML Kamelet, `resourceKind = ROUTE`.
  3. Tạo với YAML-SECRET.
  4. Tạo với YAML-BIG.
  5. Tạo với `workspaceCode = "khong-co"`.
  6. Tạo `origin = TEMPLATE` với `templateCode = "tpl-khong-co"`.
- **Mong đợi** Lần lượt `422` ERR-04-008 (có dòng, cột), `422` ERR-04-009, `422` ERR-04-010 (`findings[].path` trỏ tới URI, `message` không chứa `Abc@12345678`), `413` ERR-04-033, `404` ERR-04-027, `404` ERR-04-039. Không bản ghi nào được tạo. EVT: không.

#### TC-04-### · Chống trùng khi tạo luồng <!--k:create-idem-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-003 · API-04-011 · ERR-04-018
- **Tiền điều kiện / dữ liệu** Khóa `tc-idem-0000000001`.
- **Bước**
  1. Tạo `tc-idem` với khóa.
  2. Gửi lại cùng khóa, cùng thân.
  3. Gửi cùng khóa, đổi `name`.
  4. Gửi không có `Idempotency-Key`.
  5. Gửi khóa 15 ký tự.
- **Mong đợi** Bước 2 trả lại phản hồi `201` đã lưu. Bước 3 trả `409` ERR-04-018. Bước 4 trả `400` ERR-04-049. Bước 5 trả `400` ERR-04-049. Chỉ một luồng được tạo.

#### TC-04-### · Bắt buộc căn cứ pháp lý cho luồng đối ngoại <!--k:create-legal-->
- **Loại** Âm, Dương · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-04-003, 084 · API-04-011 · UI-04-03
- **Tiền điều kiện / dữ liệu** `04.flow.require-legal-basis = true`.
- **Bước**
  1. Tạo luồng `origin = OPENAPI` (đối ngoại) không có `legalBasisRef`.
  2. Tạo lại có `legalBasisRef = "ND-278-2025"`.
- **Mong đợi** Bước 1 trả `422` ERR-04-009 với finding "Luồng đối ngoại phải khai căn cứ pháp lý". Bước 2 trả `201`. Trên UI-04-03 ô căn cứ hiện dấu bắt buộc khi tham số bật.

### TS-04-04 · Sửa thông tin, nhân bản, hủy nháp, gỡ luồng

**Mục tiêu.** Xác nhận các thao tác vòng đời luồng ngoài phiên bản: thông tin chung, nhân bản, hủy nháp và gỡ có kiểm tra phụ thuộc, rút khỏi môi trường qua Git.

**Phủ.** FR-04-004, 005, 006; BR-04-001, 011, 017; UC-04-16; API-04-013, 014, 015, 016, 023; ERR-04-003, 005, 006, 007, 017, 025, 034; EVT-04-02, 06, 09; LGC-BUS-010, 011, 012.

#### TC-04-### · Sửa thông tin luồng <!--k:flow-update-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-004 · API-04-013 · EVT-04-02 · LGC-BUS-006, 011
- **Tiền điều kiện / dữ liệu** U-T68-IE1; F-HT, `ETag` hiện tại.
- **Bước**
  1. Gọi `PATCH /flows/tra-cuu-ho-tich` với `If-Match`, đổi `name`, thêm nhãn `muc-do:cao`.
  2. Gọi `PATCH` có `code` trong thân.
- **Mong đợi** Bước 1 trả `200`, `ETag` mới; EVT-04-02 có `changedFields = ["name","labels"]`; phiên bản và runtime không đổi (Git: không). Bước 2 trả `400` ERR-04-049 (mã không đổi được, BR-04-001). KT: có (`INT_FLOW_UPDATE` với trước, sau).

#### TC-04-### · Sửa thông tin luồng: khóa lạc quan và quyền <!--k:flow-update-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-004 · API-04-013 · ERR-04-003, 006, 007
- **Tiền điều kiện / dữ liệu** IE1, IE3; F-HT.
- **Bước**
  1. IE1 gọi `PATCH` không có `If-Match`.
  2. IE1 gọi `PATCH` với ETag cũ.
  3. IE1 chuyển luồng sang `workspaceCode = "dat-dai"` (IE1 không có `EDIT` ở WS-DATDAI).
  4. IE3 gọi `PATCH` với ETag đúng.
- **Mong đợi** Bước 1 trả `428` ERR-04-007. Bước 2 trả `412` ERR-04-006 kèm `currentEtag`, `savedBy`, `savedAt`. Bước 3, 4 trả `403` ERR-04-003. Dữ liệu không đổi.

#### TC-04-### · Nhân bản luồng <!--k:clone-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-005 · BR-04-011 · API-04-014 · UC-04-16 · EVT-04-01
- **Tiền điều kiện / dữ liệu** F-HT v3; IE1.
- **Bước**
  1. Gọi `POST /flows/tra-cuu-ho-tich:clone` với `{"code":"tc-ban-sao","name":"Bản sao","sourceVersionNo":3,"includeTestCases":true}`.
  2. Gọi `GET /flows/tc-ban-sao/versions/1`.
- **Mong đợi** Bước 1 trả `201`, `origin = CLONE`, `clonedFrom = "tra-cuu-ho-tich@3"`. Bước 2: mã route đổi tiền tố thành `tc-ban-sao-…`, đường dẫn HTTP đổi thành `/tc-ban-sao/…` để không vi phạm VR-08, VR-18; ca kiểm thử được sao; bản tin mẫu được sao; người tạo là IE1 (không kế thừa người đóng góp cũ).

#### TC-04-### · Hủy bản nháp <!--k:discard-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-006 · BR-04-016 · API-04-023, 021
- **Tiền điều kiện / dữ liệu** F-HT v4 `DRAFT`.
- **Bước**
  1. IE1 gọi `POST /flows/tra-cuu-ho-tich/versions/4:discard` có `If-Match`.
  2. Gọi `POST /flows/tra-cuu-ho-tich/versions`.
- **Mong đợi** Bước 1 trả `200`, `status = DISCARDED`; luồng không còn phiên bản mở. Bước 2 trả `201` phiên bản 5 sao từ v3 (đang chạy PROD). Số 4 không được dùng lại.

#### TC-04-### · Hủy bản nháp không đúng trạng thái <!--k:discard-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-006 · API-04-023 · ERR-04-005
- **Tiền điều kiện / dữ liệu** F-HT v3 `APPROVED`; phiên bản đang `PENDING_REVIEW` ở luồng khác.
- **Bước**
  1. Gọi `:discard` trên v3.
  2. Gọi `:discard` trên phiên bản `PENDING_REVIEW`.
- **Mong đợi** Cả hai trả `409` ERR-04-005, `detail` nêu trạng thái hiện tại.

#### TC-04-### · Gỡ luồng đã phát hành, rút theo thứ tự môi trường <!--k:retire-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-006 · BR-04-017 · API-04-015 · EVT-04-06, 09 · UC-04-16 · LGC-BUS-010, 012
- **Tiền điều kiện / dữ liệu** Luồng `tc-go` đã chạy ở TEST và PROD, không có phụ thuộc cứng; U-T68-TA.
- **Bước**
  1. Gọi `POST /flows/tc-go:retire` với `{"reason":"Thay bằng luồng mới theo Quyết định thử"}` và `If-Match`.
  2. Theo dõi `GET /flows/tc-go/deployments`.
- **Mong đợi** Bước 1 trả `202`. Hệ thống tạo triển khai `RETIRE` cho PROD trước, rồi tới TEST; mỗi môi trường xóa `flows/tc-go/` khỏi `env/*` (với PROD là merge request). Khi mọi bản sao báo không còn luồng, trạng thái luồng `RETIRED`, EVT-04-09 phát. Gọi tới `POST /tc-go/...` qua APISIX trả `404` ERR-04-111. KT: có (`INT_FLOW_RETIRE` có lý do).

#### TC-04-### · Gỡ luồng còn phụ thuộc, thiếu lý do <!--k:retire-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-006 · BR-04-017 · API-04-015 · ERR-04-017, 025, 005
- **Tiền điều kiện / dữ liệu** F-HT có phụ thuộc cứng (ca TC phụ thuộc ở TS-04-02); `tc-go2` đang có lần chạy thử `RUNNING`.
- **Bước**
  1. TA gỡ F-HT có lý do hợp lệ.
  2. TA gỡ `tc-go2` với `reason = "gỡ"` (4 ký tự).
  3. TA gỡ `tc-go2` với lý do hợp lệ.
  4. IE1 gỡ F-HT (luồng đã phát hành, IE không có `PERM-04-publish`).
- **Mong đợi** Bước 1 trả `409` ERR-04-017 kèm `dependencies`. Bước 2 trả `400` ERR-04-025. Bước 3 trả `409` ERR-04-005 ("đang có lần chạy thử"). Bước 4 trả 403-PQ. Git: không. EVT: không.

#### TC-04-### · Luồng đã gỡ chỉ đọc <!--k:edit-retired-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-006, 004 · API-04-013, 021 · ERR-04-034
- **Tiền điều kiện / dữ liệu** `tc-go` đã `RETIRED` (sau ca gỡ).
- **Bước**
  1. Gọi `PATCH /flows/tc-go`.
  2. Gọi `POST /flows/tc-go/versions`.
  3. Gọi `GET /flows/tc-go`.
- **Mong đợi** Bước 1, 2 trả `409` ERR-04-034. Bước 3 trả `200` với `retiredAt`, `retireReason`, `allowedActions` chỉ có `VIEW`, `CLONE`.

### TS-04-05 · Phiên bản, lưu nháp, ETag, phiên soạn, gộp ba bên

**Mục tiêu.** Xác nhận vòng đời phiên bản, tính bất biến sau khi gửi duyệt, lưu tự động an toàn khi nhiều người cùng mở, và không mất thay đổi khi xung đột.

**Phủ.** FR-04-010, 011, 024; BR-04-007, 016; UC-04-04; API-04-020, 021, 022, 024, 034; UI-04-04; ERR-04-004, 005, 006, 007, 016, 033, 041.

#### TC-04-### · Lưu nháp và tính lại băm <!--k:save-draft-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-024, 010 · API-04-020, 022 · BR-04-007
- **Tiền điều kiện / dữ liệu** F-HT v4 `DRAFT`; IE1 lấy ETag ở `GET /flows/tra-cuu-ho-tich/versions/4`.
- **Bước**
  1. Gọi `PUT .../versions/4/draft` chỉ đổi `canvasLayout` (kéo một chặng).
  2. Gọi `PUT .../draft` đổi `samples`.
  3. Gọi `PUT .../draft` đổi một thuộc tính trong `definitionYaml`.
- **Mong đợi** Bước 1, 2 trả `200`, `contentHash` không đổi (bố cục và bản tin mẫu không thuộc YAML). Bước 3 trả `200`, `contentHash` đổi, `validation.level = DESIGN` kèm `findings`. Mỗi bước `ETag` tăng `version`. IE1 có trong `contributors`. KT: không cho từng lần lưu (chỉ mốc gửi duyệt mới kiểm toán), có metric `dh_int_draft_saves_total`.

#### TC-04-### · Lưu nháp sai điều kiện <!--k:save-draft-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-024 · API-04-022 · ERR-04-004, 006, 007, 033, 008, 010
- **Tiền điều kiện / dữ liệu** F-HT v4 `DRAFT`.
- **Bước**
  1. Lưu `versions/9` (không tồn tại).
  2. Lưu không có `If-Match`.
  3. Lưu với YAML-BIG.
  4. Lưu với YAML cú pháp hỏng.
  5. Lưu với YAML-SECRET.
- **Mong đợi** Lần lượt `404` ERR-04-004, `428` ERR-04-007, `413` ERR-04-033, `422` ERR-04-008, `422` ERR-04-010. Ở bước 4, 5 nội dung cũ giữ nguyên trên máy chủ; CSDL không có chuỗi `Abc@12345678` ở bất kỳ cột nào (kiểm bằng truy vấn `ILIKE` trên `ph04` ở IT).

#### TC-04-### · Phiên bản đã gửi duyệt là bất biến <!--k:edit-pending-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-04-011, 040 · BR-04-016 · API-04-022 · ERR-04-005
- **Tiền điều kiện / dữ liệu** Phiên bản `PENDING_REVIEW` và v3 `APPROVED` của F-HT.
- **Bước**
  1. Gọi `PUT .../draft` trên phiên bản `PENDING_REVIEW` với ETag đúng.
  2. Gọi `PUT .../draft` trên v3.
  3. Ở IT, dùng vai trò `ph04_app` chạy `UPDATE ph04.flow_version SET definition_yaml = 'x' WHERE status = 'APPROVED'`.
- **Mong đợi** Bước 1, 2 trả `409` ERR-04-005. Bước 3 bị trigger `tg_flow_version_immutable` từ chối với lỗi SQLSTATE `P0001`; dữ liệu không đổi.

#### TC-04-### · Tạo phiên bản mới khi đã có phiên bản mở <!--k:new-version-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-011 · BR-04-016 · API-04-021, 024 · ERR-04-016, 004
- **Tiền điều kiện / dữ liệu** F-DD v1 `APPROVED`, không có phiên bản mở.
- **Bước**
  1. IE2 gọi `POST /flows/dong-bo-dat-dai/versions` với `{}`.
  2. IE3 gọi lại.
  3. Gọi `POST /flows/tra-cuu-ho-tich/versions` với `baseVersionNo = 99`.
  4. Gọi `GET /flows/dong-bo-dat-dai/versions`.
- **Mong đợi** Bước 1 trả `201` v2 `DRAFT` sao từ v1. Bước 2 trả `409` ERR-04-016 kèm `versionNo = 2` và người tạo. Bước 3 trả `404` ERR-04-004. Bước 4 liệt kê v1, v2 có `environments`.

#### TC-04-### · Hai người cùng sửa: phát hiện, xung đột, gộp ba bên <!--k:conflict-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-04-024, 010 · API-04-022, 034 · UI-04-04 · UC-04-04 · ERR-04-006
- **Tiền điều kiện / dữ liệu** IE1 và IE2 cùng mở F-HT v4 trên hai trình duyệt.
- **Bước**
  1. Cả hai mở trình thiết kế.
  2. IE2 đổi `timeout` của chặng `deliver`, chờ tự lưu.
  3. IE1 (chưa tải lại) đổi mô tả chặng `transform`, chờ tự lưu.
  4. IE1 chọn "Gộp" trong hộp xung đột.
  5. Lặp lại, lần này IE1 và IE2 cùng đổi `timeout` của chặng `deliver` với giá trị khác nhau.
- **Mong đợi** Bước 1: mỗi người thấy huy hiệu "Trần Thị Bình đang mở" (nhịp API-04-034). Bước 3: lưu nhận `412`, giao diện mở hộp xung đột ba bên (ST-08). Bước 4: thay đổi không chồng nhau được gộp tự động, lưu thành công với ETag mới, cả hai thay đổi có trong YAML. Bước 5: hộp liệt kê trường xung đột `timeout` với ba giá trị (gốc, của tôi, của Bình); chưa chọn thì nút "Lưu" bị khóa. Không bước nào mất thay đổi của IE1 (giữ ở IndexedDB tới khi lưu được).

#### TC-04-### · Mất kết nối khi đang soạn, khôi phục phiên nháp <!--k:offline-->
- **Loại** Khả dụng · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-04-024 · UI-04-04 · NFR-04-015
- **Tiền điều kiện / dữ liệu** IE1 mở F-HT v4.
- **Bước**
  1. Playwright đặt `context.setOffline(true)`, IE1 thêm hai chặng.
  2. Đóng tab, mở lại trang khi vẫn ngoại tuyến.
  3. Bật mạng.
- **Mong đợi** Bước 1: banner ST-09, chỉ báo "Chưa lưu lên máy chủ". Bước 2: hộp "Khôi phục thay đổi chưa lưu lúc {giờ}?". Bước 3: tự lưu, chỉ báo về "Đã lưu". Nếu ETag đã đổi trong lúc ngoại tuyến thì vào hộp gộp ba bên như ca xung đột.

#### TC-04-### · Phiên soạn hết hạn và catalog đổi khi đang mở <!--k:session-->
- **Loại** Biên · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-04-010, 081 · API-04-034 · UI-04-04
- **Tiền điều kiện / dữ liệu** IE1 mở F-HT v4.
- **Bước**
  1. IE2 gọi `PUT .../session` một lần rồi ngừng.
  2. Sau 125 giây IE1 gọi `PUT .../session`.
  3. PA phát hành catalog mới cho T68 trong lúc IE1 đang mở.
- **Mong đợi** Bước 2: `others` không còn IE2. Bước 3: ở nhịp kế tiếp `catalogVersion` khác bản đang dùng, giao diện hiện banner "Danh mục thành phần đã cập nhật" và nút "Nạp lại danh mục", không tự đổi giữa chừng.

#### TC-04-### · Lưu nháp trong khoảng đóng băng cả việc soạn <!--k:save-freeze-->
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-04-024, 084 · BR-04-022 · API-04-022 · ERR-04-041
- **Tiền điều kiện / dữ liệu** TA đặt khoảng đóng băng có cờ "khóa cả soạn thảo" từ bây giờ tới 2 giờ sau.
- **Bước**
  1. IE1 lưu nháp F-HT v4.
  2. TA đặt lại khoảng đóng băng không có cờ, IE1 lưu lại.
- **Mong đợi** Bước 1 trả `423` ERR-04-041 với `until`. Bước 2 trả `200` (đóng băng thường chỉ chặn phát hành).

### TS-04-06 · Trình thiết kế: bảng thành phần, sơ đồ, cấu hình chặng

**Mục tiêu.** Kiểm thử E2E trình thiết kế UI-04-04 ở mức thao tác người dùng thật: kéo thả bằng chuột, bàn phím, các cửa sổ cấu hình. Thay công cụ kéo thả Angular của Productivity Tooling (LGC-TOOL).

**Phủ.** FR-04-012, 013, 014; BR-04-014; UC-04-04, 05; API-04-070, 071; UI-04-04, 05, 17; NFR-04-001, 002.

#### TC-04-### · Bảng thành phần chỉ hiện thành phần được phép <!--k:palette-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-04-012, 080 · BR-04-014 · API-04-070 · UI-04-04 · LGC-TOOL-002
- **Tiền điều kiện / dữ liệu** Chính sách nền cấm `exec`, `ssh`; T68 thu hẹp cấm `ftp`. IE1 mở F-HT v4.
- **Bước**
  1. Gọi `GET /catalog`.
  2. Gọi lại với `If-None-Match` bằng ETag bước 1.
  3. Trên giao diện, gõ "ftp", "exec", "kafka" vào ô tìm của bảng thành phần.
  4. Lọc theo vai trò chặng "Gửi đích".
- **Mong đợi** Bước 1: `entries` không có `exec`, `ssh`, `ftp`; `sftp` có `policy = ALLOWED`. Bước 2 trả `304`. Bước 3: "ftp", "exec" ra "Không có thành phần phù hợp" kèm liên kết "Xem chính sách thành phần"; "kafka" ra `kafka` ở nhóm "Hàng đợi bản tin". Bước 4 chỉ còn thành phần producer. Mỗi lần gõ phản hồi < 50 ms (NFR-04-002, đo `performance.now`).

#### TC-04-### · Thao tác sơ đồ bằng chuột <!--k:canvas-mouse-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-04-013 · UI-04-04 · UC-04-04 · LGC-TOOL-003, 004
- **Tiền điều kiện / dữ liệu** IE1 mở `tc-trong` v1.
- **Bước**
  1. Kéo `log` từ bảng thành phần vào giữa chặng `transform` và `enrich`.
  2. Kéo `choice` vào sau `route`, thêm hai nhánh `when` và một `otherwise`.
  3. Chọn ba chặng bằng Shift + nhấp, nhấn Delete, rồi Ctrl+Z.
  4. Nhấn "Tự sắp xếp".
  5. Thu phóng bằng Ctrl + cuộn tới 25% và 200%.
- **Mong đợi** Bước 1: chặng chèn đúng vị trí, mũi tên nối lại, YAML cập nhật trong < 100 ms (NFR-04-005). Bước 2: nhánh hiện thành làn có nhãn điều kiện, `otherwise` luôn cuối. Bước 3: xóa rồi hoàn tác khôi phục đúng ba chặng và thuộc tính. Bước 4: bố cục dagre trái sang phải, không chồng khối. Bước 5: ở 25% nhãn chặng ẩn, chỉ còn biểu tượng và màu nhóm; minimap luôn hiện.

#### TC-04-### · Thao tác không hợp lệ trên sơ đồ <!--k:canvas-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-04-013 · BR-04-002 · UI-04-04
- **Tiền điều kiện / dữ liệu** IE1 mở `tc-trong` v1 (đối ngoại).
- **Bước**
  1. Kéo `kafka` (consumer) vào giữa route như một chặng thường.
  2. Kéo thả chặng `otherwise` ra ngoài `choice`.
  3. Xóa khối chặng chuẩn `authz`.
- **Mong đợi** Bước 1: vùng thả tô đỏ, tooltip "Thành phần này chỉ dùng làm điểm bắt đầu route"; không thêm. Bước 2: không cho thả. Bước 3: hộp xác nhận "Luồng đối ngoại phải có đủ chín chặng chuẩn. Xóa sẽ làm luồng không gửi duyệt được."; xác nhận thì xóa và bảng Vấn đề có VR-05 mức `WARN` (DESIGN).

#### TC-04-### · Cấu hình chặng bằng biểu mẫu sinh từ catalog <!--k:step-config-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-04-014 · API-04-071 · UI-04-05 · UC-04-05
- **Tiền điều kiện / dữ liệu** IE1 mở F-HT v4, chọn chặng gửi đích `http`.
- **Bước**
  1. Gọi `GET /catalog/components/http`.
  2. Mở UI-04-05 của chặng; mở nhóm "Nâng cao".
  3. Đổi `connectTimeout` sang `abc`, rồi `5000`.
  4. Nhấn "Khôi phục giá trị gốc" trên trường `followRedirects`.
- **Mong đợi** Bước 1: `properties` có nhóm, kiểu, mặc định, `descriptionVi`. Bước 2: trường bắt buộc có dấu, trường `secret = true` không có ô nhập tự do mà chỉ có "Chọn kết nối" hoặc "Tham chiếu bí mật". Bước 3: `abc` báo "Phải là số nguyên" tại chỗ, không lưu; `5000` lưu. Bước 4: trường về mặc định và bị bỏ khỏi YAML (không ghi giá trị mặc định thừa). Cửa sổ có 154 thuộc tính mở trong < 400 ms (NFR-04-006).

#### TC-04-### · Lược đồ thành phần không có trong catalog <!--k:step-config-neg-->
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-04-014 · API-04-071 · ERR-04-035
- **Tiền điều kiện / dữ liệu** U-T68-IE1.
- **Bước**
  1. Gọi `GET /catalog/components/khong-co`.
  2. Gọi `GET /catalog/components/http?catalogVersion=0.0.0`.
- **Mong đợi** Cả hai trả `404` ERR-04-035.

#### TC-04-### · Thành phần đã dùng nhưng sau đó bị cấm <!--k:palette-banned-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-04-012, 080 · BR-04-014 · UI-04-04 · ERR-04-011
- **Tiền điều kiện / dữ liệu** `tc-ftp` dùng `sftp`; TA thu hẹp chính sách cấm `sftp`.
- **Bước**
  1. IE1 mở `tc-ftp`.
  2. Gửi duyệt.
- **Mong đợi** Bước 1: chặng `sftp` hiện huy hiệu "Không còn được phép" màu cảnh báo, vẫn sửa được thuộc tính. Bước 2 trả `422` ERR-04-009 có finding VR-04 → ERR-04-011.

### TS-04-07 · Quay vòng YAML, tải xuống, nhập YAML

**Mục tiêu.** Bảo đảm không mất dữ liệu khi qua lại giữa sơ đồ, biểu mẫu và YAML (BR-04-006), và YAML đem triển khai không chứa bố cục, bản tin mẫu, ghi chú (BR-04-007).

**Phủ.** FR-04-017, 027; BR-04-006, 007; API-04-022, 026, 027; UI-04-04; ERR-04-008, 009, 033.

#### TC-04-### · Quay vòng không sửa giữ nguyên băm <!--k:roundtrip-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT, E2E
- **Truy vết** FR-04-017 · BR-04-006 · UI-04-04
- **Tiền điều kiện / dữ liệu** 40 tệp YAML mẫu trong `src/test/resources/roundtrip/` (gồm mọi EIP trong catalog, chú thích YAML, khóa không theo thứ tự, chuỗi nhiều dòng, ký tự tiếng Việt).
- **Bước**
  1. Với mỗi tệp: nạp thành cây tài nguyên, sinh lại YAML, tính băm chuẩn hóa.
  2. Kiểm thử theo thuộc tính (fast-check): sinh cây ngẫu nhiên hợp lệ 1.000 lần, YAML → cây → YAML.
  3. E2E: mở F-HT v4, chuyển tab Sơ đồ → YAML → Sơ đồ ba lần, không sửa.
- **Mong đợi** Bước 1, 2: băm chuẩn hóa trước và sau bằng nhau trong 100% trường hợp; thuộc tính không có trong catalog (thuộc tính tùy biến) được giữ nguyên. Bước 3: chỉ báo "Đã lưu" không đổi, không có lần lưu nào được gửi.

#### TC-04-### · Sửa trong YAML phản ánh lên sơ đồ <!--k:yaml-edit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-04-017 · UI-04-04
- **Tiền điều kiện / dữ liệu** IE1 mở F-HT v4, tab YAML (Monaco).
- **Bước**
  1. Thêm một bước `log` bằng tay trong YAML.
  2. Gõ sai thụt lề.
  3. Chuyển sang tab Sơ đồ khi YAML đang lỗi.
- **Mong đợi** Bước 1: sau 500 ms sơ đồ có chặng `log` đúng vị trí. Bước 2: gạch đỏ tại dòng, bảng Vấn đề có VR-01. Bước 3: hộp "YAML đang có lỗi cú pháp. Sơ đồ đang hiển thị bản hợp lệ gần nhất." và không ghi đè nội dung đang gõ.

#### TC-04-### · YAML triển khai không chứa bố cục, bản tin mẫu, ghi chú <!--k:yaml-clean-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT, GO
- **Truy vết** FR-04-017, 022, 026 · BR-04-007 · API-04-026
- **Tiền điều kiện / dữ liệu** F-HT v4 có bố cục, bản tin mẫu MSG-OK ở ba chặng, hai ghi chú dán.
- **Bước**
  1. Gọi `GET .../versions/4/download?format=yaml`.
  2. Gọi `GET .../versions/4/download?format=yaml+layout`.
  3. Sau khi v4 được phát hành ở TEST, đọc tệp `flows/tra-cuu-ho-tich/flow.camel.yaml` trên `env/test`.
- **Mong đợi** Bước 1 và 3: không có khóa `dh-layout`, `dh-samples`, `dh-notes`, không có chuỗi `001099000001`. Bước 2: có bố cục ở khối chú thích tách riêng để nhập lại được. Băm chuẩn hóa của tệp trên Git bằng `contentHash` của v4.

#### TC-04-### · Nhập YAML thay định nghĩa <!--k:import-yaml-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-027 · API-04-027
- **Tiền điều kiện / dữ liệu** F-HT v4; tệp YAML đã sửa ngoài.
- **Bước**
  1. Gọi `POST .../versions/4:import-yaml` với `keepLayout = true`.
- **Mong đợi** `200`; định nghĩa thay mới; chặng có cùng `id` giữ vị trí cũ trên sơ đồ, chặng mới được tự sắp xếp. `validation` trả kèm.

#### TC-04-### · Nhập YAML không hợp lệ <!--k:import-yaml-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-027 · API-04-027 · ERR-04-008, 009, 033
- **Tiền điều kiện / dữ liệu** YAML-BOMB, YAML-BIG, YAML có thẻ `!!java.lang.Runtime`.
- **Bước**
  1. Nhập YAML-BOMB.
  2. Nhập YAML-BIG.
  3. Nhập YAML có thẻ kiểu Java.
  4. Nhập YAML của Kamelet vào phiên bản loại ROUTE.
- **Mong đợi** Bước 1 trả `422` ERR-04-008 trong < 1 giây, bộ nhớ heap không tăng quá 50 MiB (VR-01 giới hạn bí danh 50, độ sâu 64). Bước 2 trả `413` ERR-04-033. Bước 3 trả `422` ERR-04-008, không tạo đối tượng Java (SnakeYAML Engine không hỗ trợ thẻ toàn cục). Bước 4 trả `422` ERR-04-009.

### TS-04-08 · Biểu thức, kết nối, bí mật, bản tin mẫu

**Mục tiêu.** Bảo đảm không có đường nào ghi bí mật vào định nghĩa luồng, biểu thức được kiểm đúng engine Camel của runtime, bản tin mẫu không mang dữ liệu cá nhân thật ra ngoài sandbox.

**Phủ.** FR-04-015, 016, 022; BR-04-003, 013; UC-04-05; API-04-032, 022; UI-04-05, 06; ERR-04-010, 013, 019, 021, 037.

#### TC-04-### · Kiểm tra và xem trước biểu thức <!--k:expr-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-015 · API-04-032 · UI-04-06 · LGC-TOOL-006
- **Tiền điều kiện / dữ liệu** IE1; MSG-OK.
- **Bước**
  1. Gọi `POST /expressions:check` với `{"language":"simple","expression":"${body[soDinhDanh]} != null","predicate":true}`.
  2. Gọi với `jsonpath` `$.hoTen`, `evaluate = true`, `sample.body` = MSG-OK.
  3. Gọi với `jq` `.ngaySinh | split("-")[0]`, `evaluate = true`.
  4. Trên UI-04-06, gõ `${he` và chờ gợi ý.
- **Mong đợi** Bước 1 trả `200`, `valid = true`. Bước 2 trả `result = "Nguyễn Văn Thử"`, `resultType = String`, `simulated = false`. Bước 3 trả `"1990"`. Bước 4: gợi ý `header.`, `headers` kèm mô tả tiếng Việt.

#### TC-04-### · Biểu thức lỗi <!--k:expr-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-015 · API-04-032 · ERR-04-037, 019, 021
- **Tiền điều kiện / dữ liệu** IE1.
- **Bước**
  1. Kiểm `simple` `${body[soDinhDanh}`.
  2. Kiểm như bước 1 ở chế độ chặt.
  3. Kiểm `jq` với `sample.body` = MSG-BIG.
  4. Dừng sandbox, kiểm `jq` với `evaluate = true`.
  5. Kiểm `groovy` (ngôn ngữ không có trong catalog).
- **Mong đợi** Bước 1 trả `200`, `valid = false`, `error.column` trỏ đúng vị trí; UI-04-06 tô đỏ vị trí. Bước 2 trả `422` ERR-04-037. Bước 3 trả `413` ERR-04-021. Bước 4 trả `503` ERR-04-019 (biên dịch không cần sandbox vẫn chạy được nếu `evaluate = false`). Bước 5 trả `400` ERR-04-049.

#### TC-04-### · Chọn kết nối PH-05 thay vì nhập thông tin đăng nhập <!--k:conn-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-04-016 · BR-04-003 · UI-04-05 · UC-04-05
- **Tiền điều kiện / dữ liệu** IE1 mở F-HT v4, chặng gửi đích.
- **Bước**
  1. Mở ô "Kết nối", tìm "HT".
  2. Chọn CONN-HT.
  3. Chọn trường "Mật khẩu proxy", bấm "Tham chiếu bí mật", chọn `vault:ho-tich/proxy`.
- **Mong đợi** Bước 1 chỉ liệt kê kết nối đã cấp cho WS-HOTICH (không có CONN-DD-ONLY), hiện loại và môi trường có giá trị. Bước 2: YAML có `{{conn:CONN-HT}}`. Bước 3: YAML có `{{vault:ho-tich/proxy}}`; giao diện không có ô nào cho phép dán giá trị bí mật.

#### TC-04-### · Phát hiện bí mật mọi chỗ trong định nghĩa <!--k:secret-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-04-016, 023 · BR-04-003 · API-04-022 · ERR-04-010
- **Tiền điều kiện / dữ liệu** 24 mẫu bí mật: tham số URI `password=`, `accessKey=`, `Authorization: Basic …` trong `setHeader`, JWT, khóa PEM, chuỗi AWS `AKIA…`, giá trị bean `secret`, chuỗi entropy cao 40 ký tự trong thuộc tính tên `token`; và 10 mẫu hợp lệ: `{{conn:…}}`, `{{vault:…}}`, `#bean`, UUID, băm sha256 trong `contentHash`.
- **Bước**
  1. Chạy `SecretDetector` trên từng mẫu (UT).
  2. Lưu nháp với từng mẫu bí mật (API).
- **Mong đợi** Bước 1: phát hiện 24/24, không báo nhầm 10/10 mẫu hợp lệ. Bước 2: mỗi lần trả `422` ERR-04-010; `findings[].message` chỉ có đường dẫn và loại ("chuỗi giống mật khẩu"), không có giá trị; log ứng dụng và vết OpenTelemetry không có giá trị (quét bằng `grep` trên log IT).

#### TC-04-### · Kết nối không hợp lệ <!--k:conn-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-016, 023 · API-04-030 · ERR-04-013
- **Tiền điều kiện / dữ liệu** `tc-conn` tham chiếu lần lượt `{{conn:KHONG-CO}}`, CONN-DD-ONLY (chưa cấp cho WS-HOTICH), CONN-DKKD-RO cho chặng `http` (sai loại).
- **Bước**
  1. Gọi `:validate` mức `DESIGN`.
  2. Gọi `:validate` mức `SUBMIT`.
- **Mong đợi** Bước 1: ba finding VR-07 mức `WARN`. Bước 2: ba finding VR-07 mức `ERROR`, mã ERR-04-013 trong `args`.

#### TC-04-### · Ghim bản tin mẫu theo chặng và cảnh báo dữ liệu cá nhân <!--k:samples-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-04-022 · BR-04-007, 013 · UI-04-04, 05
- **Tiền điều kiện / dữ liệu** IE1 (không có `PERM-04-sample-data`), IE2 (được cấp `PERM-04-sample-data` cho F-HT).
- **Bước**
  1. IE1 ghim MSG-OK ở chặng `receive`.
  2. IE1 dán MSG-PII vào chặng `transform`.
  3. IE2 dán MSG-PII và chọn "Vẫn dùng".
- **Mong đợi** Bước 1: chặng sau dùng bản tin của chặng trước gần nhất (hiện nhãn "kế thừa từ Tiếp nhận"). Bước 2: cảnh báo "Bản tin mẫu có dấu hiệu chứa dữ liệu cá nhân (số điện thoại, thư điện tử)", nút "Thay bằng dữ liệu giả" và không có "Vẫn dùng". Bước 3: lưu được; KT: có (`INT_SAMPLE_PII_OVERRIDE`).

### TS-04-09 · Trình ánh xạ dữ liệu

**Mục tiêu.** Xác nhận trình ánh xạ sinh JQ đúng, chạy được trên runtime và chuyển mã qua PH-07 bằng hàm `dh_map`.

**Phủ.** FR-04-020, 065; UC-04-06; API-04-033; UI-04-07; ERR-04-021, 038.

#### TC-04-### · Ánh xạ trường, hàm và chuyển mã <!--k:mapper-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API, RT
- **Truy vết** FR-04-020, 065 · API-04-033 · UI-04-07 · UC-04-06 · LGC-TOOL-008
- **Tiền điều kiện / dữ liệu** Lược đồ nguồn `hotich-yeucau-v1`, đích CDM `cdm-cong-dan-v1`; bảng chuyển mã PH-07 `GIOI_TINH` (giả lập).
- **Bước**
  1. Trên UI-04-07, kéo `hoTen` → `ten.day_du`, `ngaySinh` → `ngay_sinh` với hàm "Định dạng ngày", `gioiTinh` → `gioi_tinh` với "Chuyển mã danh mục GIOI_TINH".
  2. Gọi `POST /mappings:preview` với `sample` = MSG-OK có `gioiTinh = "1"`.
  3. Chạy luồng mẫu dùng ánh xạ trên runtime (RT).
- **Mong đợi** Bước 2 trả `jq` có `dh_map("GIOI_TINH"; .gioiTinh)`, `output.gioi_tinh = "NAM"`, `targetValid = true`. Bước 3: runtime trả cùng kết quả với bước 2 (cùng phiên bản thư viện JQ, so sánh từng byte).

#### TC-04-### · Ánh xạ không hợp lệ <!--k:mapper-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-020 · API-04-033 · ERR-04-038, 021
- **Tiền điều kiện / dữ liệu** Như ca trên.
- **Bước**
  1. Xem trước với ánh xạ tới `ten.khong_co`.
  2. Xem trước với hai trường suy ra lẫn nhau (vòng).
  3. Xem trước với tài liệu mẫu 1,1 MiB.
- **Mong đợi** Bước 1, 2 trả `422` ERR-04-038, `findings[].args.target` chỉ trường. Bước 3 trả `413` ERR-04-021.

#### TC-04-### · Trường bắt buộc của đích chưa ánh xạ <!--k:mapper-required-->
- **Loại** Biên · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-04-020, 084 · API-04-030
- **Tiền điều kiện / dữ liệu** Ánh xạ thiếu `so_dinh_danh` (bắt buộc ở đích).
- **Bước**
  1. `:validate` mức `SUBMIT` với `04.mapping.require-all-required = false`.
  2. Bật tham số, kiểm lại.
- **Mong đợi** Bước 1: finding mức `WARN`. Bước 2: finding mức `ERROR`.

### TS-04-10 · Kamelet, Pipe, bean, ghi chú, luồng con

**Phủ.** FR-04-018, 019, 021, 026; UC-04-07; UI-04-08, 09, 10; ERR-04-011, 029, 036.

#### TC-04-### · Soạn Kamelet tự viết và dùng trong luồng <!--k:kamelet-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-018 · UI-04-08 · UC-04-07
- **Tiền điều kiện / dữ liệu** F-KAM v1 `DRAFT`, tham số `pattern` và `maskChar`.
- **Bước**
  1. Trên UI-04-08, khai báo tham số, đánh dấu không nhạy cảm, lưu.
  2. Đưa F-KAM qua duyệt và phát hành TEST.
  3. Mở F-HT v4, tìm "ma hoa" trong bảng thành phần.
- **Mong đợi** Bước 1: VR-15 không có lỗi. Bước 3: F-KAM có trong nhóm "Chặng chuẩn Datahub" với nhãn "Của tỉnh", có `source = TENANT`; khi kéo vào, biểu mẫu sinh từ khai báo tham số.

#### TC-04-### · Kamelet sai <!--k:kamelet-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-018 · ERR-04-036, 029 · BR-04-003
- **Tiền điều kiện / dữ liệu** IE1.
- **Bước**
  1. Tạo Kamelet tên `dh-receive-action` (trùng Kamelet nền).
  2. Tạo Kamelet có tham số `apiKey` không đánh dấu `format: password`.
  3. Tạo Kamelet dùng `smb` (không hồ sơ nào có).
- **Mong đợi** Bước 1 trả `409` ERR-04-036. Bước 2: finding VR-15 `ERROR`. Bước 3: ở mức `PUBLISH` có ERR-04-029.

#### TC-04-### · Soạn Pipe <!--k:pipe-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-04-019 · UI-04-09
- **Tiền điều kiện / dữ liệu** Kamelet `kafka-source`, F-KAM (`action`), `http-sink`.
- **Bước**
  1. Tạo Pipe `source: kafka-source`, `steps: [F-KAM]`, `sink: http-sink`.
  2. Đặt `http-sink` vào `source`.
- **Mong đợi** Bước 1: hợp lệ. Bước 2: finding VR-15 "Kamelet loại sink không dùng làm nguồn".

#### TC-04-### · Bean khai báo và cấu hình cấp tệp <!--k:bean-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-04-021 · UI-04-10 · ERR-04-011
- **Tiền điều kiện / dữ liệu** Danh sách lớp bean cho phép có `vn.datahub.runtime.beans.VietnameseNormalizer`.
- **Bước**
  1. Khai báo bean lớp được phép, dùng `#normalizer` ở chặng `transform`.
  2. Khai báo bean `java.lang.ProcessBuilder`.
- **Mong đợi** Bước 1 hợp lệ. Bước 2: VR-04 `ERROR` ở `SUBMIT`, "Lớp không được phép"; gửi duyệt trả ERR-04-009 với ERR-04-011 trong finding.

#### TC-04-### · Ghi chú dán và luồng con <!--k:notes-subflow-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** E2E
- **Truy vết** FR-04-026 · BR-04-007 · UI-04-04
- **Tiền điều kiện / dữ liệu** F-HT v4.
- **Bước**
  1. Thêm hai ghi chú dán màu khác nhau.
  2. Chọn ba chặng, "Tách thành luồng con".
- **Mong đợi** Bước 1: ghi chú lưu ở bố cục, không có trong YAML (BR-04-007). Bước 2: sinh route `direct:{flow}-sub-1` trong cùng tệp, chỗ cũ thay bằng `to: direct:…`; quay vòng YAML giữ nguyên băm sau khi tách.

### TS-04-11 · Kiểm tra hợp lệ VR-01…20

**Mục tiêu.** Mỗi quy tắc kiểm tra có ít nhất một ca phát hiện và một ca không báo nhầm, ở đúng mức nghiêm trọng theo FRS FR-04-023. Bộ quy tắc phía trình duyệt và phía máy chủ cho cùng kết quả trên tập quy tắc chung.

**Phủ.** FR-04-023; BR-04-002, 008, 009, 010, 011, 014, 015, 020; API-04-030, 031; ERR-04-009, 011, 012, 013, 031, 043; NFR-04-007.

#### TC-04-### · Ma trận mức nghiêm trọng theo mức kiểm tra <!--k:vr-matrix-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT
- **Truy vết** FR-04-023 · API-04-030
- **Tiền điều kiện / dữ liệu** Bộ 20 tệp YAML, mỗi tệp vi phạm đúng một quy tắc VR-01…20 (`src/test/resources/vr/vr-nn.yaml`), cộng YAML-OK.
- **Bước**
  1. Chạy `ValidationEngine` trên từng tệp ở ba mức `DESIGN`, `SUBMIT`, `PUBLISH`.
- **Mong đợi** 60 kết quả khớp đúng bảng FR-04-023 (ví dụ VR-05: `WARN`, `ERROR`, `ERROR`; VR-12: `INFO`, `WARN`, `ERROR`). YAML-OK không có finding nào ở mọi mức. Mỗi finding có `rule`, `severity`, `path`, `nodeId`, `message` tiếng Việt.

#### TC-04-### · Chín chặng chuẩn với luồng đối ngoại và nội bộ <!--k:vr-stages-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023, 060 · BR-04-002 · ERR-04-012
- **Tiền điều kiện / dữ liệu** `tc-ngoai` (EXTERNAL) và `tc-noi` (INTERNAL), cùng thiếu chặng `authz` và đảo thứ tự `audit` với `deliver`.
- **Bước**
  1. `:validate` mức `SUBMIT` trên `tc-ngoai`.
  2. Như bước 1 trên `tc-noi`.
- **Mong đợi** Bước 1: VR-05 `ERROR`, `args.stages = ["authz"]`, và một finding thứ tự; map sang ERR-04-012. Bước 2: VR-06 `WARN`, không chặn.

#### TC-04-### · Trùng mã route, trùng đường dẫn HTTP <!--k:vr-dup-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023 · BR-04-011
- **Tiền điều kiện / dữ liệu** `tc-trung` có route `tra-cuu-ho-tich-main` (trùng F-HT đang chạy) và `path: /ho-tich/tra-cuu`.
- **Bước**
  1. `:validate` mức `DESIGN`.
  2. Đổi mã route và đường dẫn, kiểm lại.
- **Mong đợi** Bước 1: VR-08 và VR-18 `ERROR` ngay ở `DESIGN`. Bước 2: không còn finding. Đường dẫn trùng F-T01 ở T01 không bị báo (khác tenant).

#### TC-04-### · Topic chưa đăng ký hoặc không có quyền <!--k:vr-topic-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023, 069 · BR-04-009
- **Tiền điều kiện / dữ liệu** `tc-topic` gửi tới `t68.chua-dang-ky.v1`, TOPIC-NOACL, TOPIC-T01.
- **Bước**
  1. `:validate` mức `SUBMIT`.
- **Mong đợi** Ba finding VR-10 `ERROR`. Với TOPIC-T01 thông điệp là "Không được dùng topic của tỉnh khác".

#### TC-04-### · Thiếu xử lý lỗi và DLQ <!--k:vr-dlq-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023, 070 · BR-04-008
- **Tiền điều kiện / dữ liệu** `tc-loi` bỏ `routeConfigurationId`, không có `errorHandler`.
- **Bước**
  1. `:validate` mức `SUBMIT`.
  2. Thêm `errorHandler: deadLetterChannel` tới `kafka:t68.ops.dlq.v1`, kiểm lại.
- **Mong đợi** Bước 1: VR-11 `ERROR`. Bước 2: không còn finding.

#### TC-04-### · Đặt tiêu đề tenant sai chỗ <!--k:vr-tenant-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023, 073 · BR-04-010
- **Tiền điều kiện / dữ liệu** `tc-ten` có `setHeader: name: dh-tenant, simple: ${header.X-Tenant}` ở chặng `transform`.
- **Bước**
  1. `:validate` mức `DESIGN`, `SUBMIT`.
- **Mong đợi** VR-14 `WARN`, `ERROR`. Thông điệp "Không được đặt tiêu đề dh-tenant; tenant do chặng Tiếp nhận đặt".

#### TC-04-### · Thành phần nguy hiểm và chỉ chạy JVM <!--k:vr-danger-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-023, 075 · BR-04-014 · ERR-04-011, 029
- **Tiền điều kiện / dữ liệu** `tc-nguy` dùng `exec:`, `file:/etc`, `cxf` (chỉ JVM) khi T68 không được phép hồ sơ `legacy-jvm` nhưng được `soap-jvm`.
- **Bước**
  1. `:validate` mức `PUBLISH` với `targetEnvironment = TEST`.
- **Mong đợi** VR-19 `ERROR` cho `exec`, `file`; VR-12 không báo lỗi cho `cxf` vì có hồ sơ `soap-jvm` hợp lệ; nếu bỏ quyền `soap-jvm` thì VR-12 `ERROR` và ERR-04-029.

#### TC-04-### · HTTT đích chưa kết nạp và catalog cũ <!--k:vr-httt-catalog-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-023, 068, 081 · BR-04-020 · ERR-04-043, 042
- **Tiền điều kiện / dữ liệu** `tc-dich` có `targetSystems = ["HT-CHUA-KET-NAP"]` (không có ở bản sao PH-01); `definition.catalogVersion` thấp hơn catalog hiện hành.
- **Bước**
  1. `:validate` mức `SUBMIT`.
  2. `:submit`.
- **Mong đợi** Bước 1: finding với ERR-04-043 và VR-17 `ERROR`. Bước 2 trả `409` ERR-04-042 (kiểm catalog trước khi chạy đủ quy tắc, theo thứ tự ở D03-04-PH04 §3 ghi chú 3).

#### TC-04-### · Kiểm tra trình duyệt và máy chủ cho cùng kết quả <!--k:vr-parity-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** UT
- **Truy vết** FR-04-023 · NFR-04-007
- **Tiền điều kiện / dữ liệu** Bộ tệp `vr-nn.yaml` của các quy tắc VR-01…09, 15, 18, 20 (phần chạy được ở trình duyệt).
- **Bước**
  1. Chạy bộ quy tắc trình duyệt (Vitest) và máy chủ (JUnit) trên cùng tệp, so sánh `rule`, `severity`, `path`.
- **Mong đợi** Kết quả trùng khớp 100%. Thời gian máy chủ mức `SUBMIT` cho YAML-200 p95 < 2 giây (NFR-04-007).

### TS-04-12 · Chạy thử trên sandbox

**Mục tiêu.** Thay cơ chế "chạy thử giả lập" của mã W2 bằng chạy thật trên `dh-runtime-sandbox`, với đích mô phỏng (`MOCK`) hoặc đích thật môi trường TEST (`SANDBOX_LIVE`). Kết quả chạy thử là điều kiện của gửi duyệt. Vì vậy ca dương tính phải chứng minh lần chạy thử thật sự đi qua Camel, không chỉ trả kết quả dựng sẵn.

**Phủ.** FR-04-030, 032, 033; BR-04-004, 013; UC-04-08; API-04-040…043; UI-04-11, 12; ERR-04-009, 013, 019, 020, 021; EVT-04-10; NFR-04-008.

#### TC-04-### · Chạy thử MOCK đạt <!--k:run-pass-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-030, 033 · API-04-040, 042 · UI-04-11 · UC-04-08 · EVT-04-10 · NFR-04-008
- **Tiền điều kiện / dữ liệu** F-HT v4 hợp lệ; IE1; MSG-OK; đích mô phỏng trả `{"ketQua":"OK"}`.
- **Bước**
  1. Gọi `POST .../versions/4/test-runs` với `{"mode":"MOCK","body":MSG-OK,"assertions":[{"kind":"STATUS","expected":200},{"kind":"STEP_VISITED","nodeId":"deliver-ht"}]}` và `Idempotency-Key`.
  2. Mở SSE `GET .../test-runs/{runId}/events`.
  3. Trên UI-04-11, quan sát sơ đồ.
- **Mong đợi** Bước 1 trả `202`, `Location`, `status = QUEUED`, `definitionHash = contentHash` của v4. Bước 2 nhận `status` → `RUNNING`, chín sự kiện `step` (một cho mỗi chặng chuẩn) có `stage`, `durationMs`, rồi `completed` với `status = PASSED`. Vết OpenTelemetry của lần chạy có span `camel` trong pod sandbox (chứng minh chạy thật). Bước 3: các chặng đã đi tô xanh, nhãn thời gian trên cạnh. EVT-04-10 phát. Từ gửi tới kết quả p95 < 5 giây (NFR-04-008). KT: có (`INT_TESTRUN`).

#### TC-04-### · Chạy thử không đạt và chặng lỗi <!--k:run-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-030, 032 · API-04-040, 042 · UI-04-11, 12
- **Tiền điều kiện / dữ liệu** F-HT v4; MSG-NOID.
- **Bước**
  1. Chạy `MOCK` với MSG-NOID, khẳng định `STATUS = 200`.
  2. Mở UI-04-12 (nhật ký) của lần chạy.
- **Mong đợi** Bước 1: `status = FAILED`; `assertionResults[0].passed = false`, `actual = 400`; chặng `schema` có `status = FAILED`, `errorClass = VALIDATION`; chặng sau `schema` có `SKIPPED`. Bước 2: dòng chặng `schema` đỏ, thông điệp "Thiếu trường soDinhDanh", không có giá trị của trường khác (BR-04-013).

#### TC-04-### · Chạy thử với định nghĩa lỗi, kết nối thiếu TEST, bản tin lớn <!--k:run-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-030 · API-04-040 · ERR-04-009, 013, 021
- **Tiền điều kiện / dữ liệu** `tc-loi-cu-phap` (VR-02 `ERROR`); `tc-notest` dùng CONN-NOTEST.
- **Bước**
  1. Chạy thử `tc-loi-cu-phap`.
  2. Chạy `SANDBOX_LIVE` với `tc-notest`.
  3. Chạy F-HT v4 với MSG-BIG.
  4. Chạy với `timeoutSeconds = 121`.
- **Mong đợi** Lần lượt `422` ERR-04-009 (kèm `findings`), `422` ERR-04-013, `413` ERR-04-021, `400` ERR-04-049. Không có lần chạy nào vào hàng đợi.

#### TC-04-### · Quá thời gian và chặng treo <!--k:run-timeout-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-030 · API-04-042 · ERR-04-020
- **Tiền điều kiện / dữ liệu** Đích mô phỏng của F-HT trễ 10 giây.
- **Bước**
  1. Chạy `MOCK` với `timeoutSeconds = 5`.
- **Mong đợi** Sau khoảng 5 giây: `status = TIMED_OUT`, `errorCode = ERR-04-020`, `hungNodeId = "deliver-ht"`. Sandbox dừng exchange và giải phóng chỗ trong hạn mức; lần chạy kế tiếp bắt đầu ngay.

#### TC-04-### · Hạn mức chạy thử đồng thời <!--k:run-quota-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-030, 084 · API-04-040 · ERR-04-019
- **Tiền điều kiện / dữ liệu** `04.test.max-concurrent = 5`; đích trễ 10 giây.
- **Bước**
  1. Gửi đồng thời 6 lần chạy thử của T68.
  2. Cùng lúc gửi 1 lần của T01.
- **Mong đợi** Năm lần đầu `202`. Lần thứ sáu `429` ERR-04-019 kèm `retryAfterSeconds` và tiêu đề `Retry-After`. Lần của T01 `202` (hạn mức tính theo tenant).

#### TC-04-### · Hủy lần chạy thử <!--k:run-cancel-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-04-030 · API-04-043 · ERR-04-005
- **Tiền điều kiện / dữ liệu** Một lần chạy đang `QUEUED`, một lần đã `PASSED`.
- **Bước**
  1. `:cancel` lần `QUEUED`.
  2. `:cancel` lần `PASSED`.
- **Mong đợi** Bước 1 trả `200`, `status = CANCELLED`. Bước 2 trả `409` ERR-04-005.

#### TC-04-### · Sandbox không sẵn sàng và chế độ mô phỏng <!--k:run-sim-->
- **Loại** Khả dụng · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-030 · BR-04-004 · ERR-04-019
- **Tiền điều kiện / dữ liệu** Thu nhỏ `dh-runtime-sandbox` về 0 bản sao.
- **Bước**
  1. Chạy thử với `04.test.allow-simulation = false`.
  2. Bật `allow-simulation`, chạy lại.
- **Mong đợi** Bước 1 trả `503` ERR-04-019. Bước 2 trả `202`, kết quả `mode = SIMULATED`, giao diện hiện nhãn "Mô phỏng, không dùng để gửi duyệt". Lần chạy này không được tính cho BR-04-004 (xem ca gửi duyệt với lần mô phỏng ở TS-04-14).

#### TC-04-### · Nhật ký chạy thử: xem lại, so sánh, dọn <!--k:run-log-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-032 · API-04-041, 042 · UI-04-12 · BR-04-013
- **Tiền điều kiện / dữ liệu** F-HT có 3 lần chạy; một lần bật `captureBodies`.
- **Bước**
  1. Gọi `GET /flows/tra-cuu-ho-tich/test-runs?versionNo=4`.
  2. Gọi `GET .../test-runs/{id}/steps/3/body?side=out` cho lần có `captureBodies`.
  3. Trên UI-04-12, chọn hai lần chạy, bấm "So sánh".
  4. Đặt đồng hồ hệ thống tới 8 ngày sau, chạy job dọn.
- **Mong đợi** Bước 1: ba lần chạy, mỗi lần có `matchesCurrentHash`. Bước 2: thân đã che theo BR-04-013 (trường phân loại Cá nhân thay bằng `***`). Bước 3: bảng so sánh theo chặng, tô khác biệt thời gian và trạng thái. Bước 4: thân bị xóa khỏi RGW bucket `dh-int-testrun` (`04.test.body-retention-days = 7`), bước 2 nay trả `404`; metadata còn tới 90 ngày.

#### TC-04-### · Chạy thử SANDBOX_LIVE gọi đích TEST <!--k:run-live-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-030 · UC-04-08
- **Tiền điều kiện / dữ liệu** CONN-HT có giá trị TEST trỏ WireMock `OK`.
- **Bước**
  1. Chạy `SANDBOX_LIVE` với MSG-OK.
- **Mong đợi** `PASSED`; WireMock ghi nhận đúng một lệnh gọi tới URL TEST; không lệnh gọi nào tới URL PROD (kiểm bằng WireMock PROD không nhận yêu cầu). Sandbox chỉ đọc được giá trị TEST của kết nối (OpenBao policy).

### TS-04-13 · Ca kiểm thử của luồng

**Phủ.** FR-04-031; BR-04-004; UC-04-09; API-04-044; UI-04-13; ERR-04-030.

#### TC-04-### · Tạo ca kiểm thử và chạy tất cả <!--k:case-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-031 · API-04-044, 040 · UI-04-13 · UC-04-09
- **Tiền điều kiện / dữ liệu** F-HT v4.
- **Bước**
  1. Tạo ca "KS-01 tra cứu hợp lệ" (MSG-OK, `STATUS = 200`, `BODY_JQ .ketQua == "OK"`).
  2. Tạo ca "KS-02 thiếu số định danh" (MSG-NOID, `STATUS = 400`, `ERROR_CODE = ERR-04-101`, `STEP_NOT_VISITED deliver-ht`).
  3. Trên UI-04-13 bấm "Chạy tất cả".
- **Mong đợi** Bước 1, 2 trả `201`. Bước 3: hai lần chạy có `testCaseId`, cả hai `PASSED`; cột "Kết quả trên bản hiện tại" xanh.

#### TC-04-### · Ca kiểm thử sai và kết quả cũ hết hiệu lực <!--k:case-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-031 · API-04-044 · ERR-04-030, 006
- **Tiền điều kiện / dữ liệu** Ca KS-01 đã đạt trên băm cũ.
- **Bước**
  1. Tạo ca không có khẳng định nào.
  2. Sửa ca với ETag cũ.
  3. Xóa ca không tồn tại.
  4. Sửa định nghĩa v4 (đổi băm), xem lại danh sách ca.
- **Mong đợi** Bước 1 trả `400` ERR-04-049 (`minItems = 1`, VR-20). Bước 2 trả `412` ERR-04-006. Bước 3 trả `404` ERR-04-030. Bước 4: `lastResult.onCurrentHash = false` cho KS-01, nhãn "Cần chạy lại".

### TS-04-14 · Gửi duyệt, rút lại

**Mục tiêu.** Cổng chất lượng trước duyệt: kiểm tra mức `SUBMIT`, chạy thử đạt trên đúng nội dung, catalog hiện hành, phiên bản bất biến sau khi gửi.

**Phủ.** FR-04-040; BR-04-004, 016, 017, 020; UC-04-10; API-04-050, 051; UI-04-14; ERR-04-005, 009, 014, 025, 042; EVT-04-03.

#### TC-04-### · Gửi duyệt thành công <!--k:submit-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-040 · BR-04-004, 016 · API-04-050 · UC-04-10 · EVT-04-03
- **Tiền điều kiện / dữ liệu** F-HT v4 hợp lệ; một lần `MOCK` `PASSED` trên băm hiện tại; KS-01, KS-02 đạt trên băm hiện tại; IE1, IE2 là người đóng góp.
- **Bước**
  1. IE1 gọi `POST .../versions/4:submit` với `{"changeNote":"Thêm chuẩn hóa họ tên theo QĐ thử","suggestedReviewers":["U-T68-IA1"]}` và `If-Match`.
- **Mong đợi** `200`, `status = PENDING_REVIEW`, `submittedBy = IE1`, danh sách người đóng góp chụp lại (IE1, IE2). EVT-04-03 phát, PH-18 tạo thông báo cho IA1. `allowedActions` của IE1 chỉ còn `WITHDRAW`. KT: có (`INT_VERSION_SUBMIT`).

#### TC-04-### · Gửi duyệt khi chưa chạy thử đạt trên đúng băm <!--k:submit-notest-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-040 · BR-04-004 · API-04-050 · ERR-04-014
- **Tiền điều kiện / dữ liệu** F-HT v4: lần `PASSED` gần nhất ở băm cũ; sau đó sửa một thuộc tính.
- **Bước**
  1. `:submit`.
  2. Chạy `MOCK` đạt trên băm mới nhưng KS-02 `FAILED`, `:submit` lại.
- **Mong đợi** Cả hai trả `409` ERR-04-014; `detail` nêu rõ lý do (chưa có lần đạt trên băm hiện tại, hoặc ca KS-02 chưa đạt).

#### TC-04-### · Lần chạy mô phỏng không được tính <!--k:sim-not-counted-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-04-040, 030 · BR-04-004 · ERR-04-014
- **Tiền điều kiện / dữ liệu** F-HT v4 chỉ có lần chạy `SIMULATED` đạt trên băm hiện tại (từ ca sandbox không sẵn sàng); hoặc lần chạy cũ di trú từ W2 có `mode = SIMULATED`.
- **Bước**
  1. `:submit`.
- **Mong đợi** `409` ERR-04-014. Câu truy vấn kiểm BR-04-004 (SDD §8.4) lọc `mode <> 'SIMULATED'` (kiểm bằng IT với dữ liệu di trú `ph04-9000`).

#### TC-04-### · Gửi duyệt sai trạng thái, thiếu ghi chú, còn lỗi <!--k:submit-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-040 · BR-04-017 · API-04-050 · ERR-04-005, 009, 025
- **Tiền điều kiện / dữ liệu** v3 `APPROVED`; `tc-con-loi` có VR-05 `ERROR`.
- **Bước**
  1. `:submit` v3.
  2. `:submit` F-HT v4 với `changeNote = "sửa"`.
  3. `:submit` `tc-con-loi`.
- **Mong đợi** Lần lượt `409` ERR-04-005, `400` ERR-04-025, `422` ERR-04-009 kèm `findings`. Phiên bản giữ `DRAFT`. EVT: không.

#### TC-04-### · Rút lại yêu cầu duyệt <!--k:withdraw-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-040 · BR-04-017 · API-04-051
- **Tiền điều kiện / dữ liệu** F-HT v4 `PENDING_REVIEW`.
- **Bước**
  1. IE1 gọi `:withdraw` với lý do hợp lệ.
  2. IE1 lưu nháp.
- **Mong đợi** Bước 1 trả `200`, `status = DRAFT`; thông báo cho người duyệt được thu hồi. Bước 2 trả `200`. KT: có (`INT_VERSION_WITHDRAW` có lý do).

#### TC-04-### · Phiên bản đã gửi duyệt không sửa được qua mọi kênh <!--k:submit-immutable-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-040 · BR-04-016 · API-04-022, 027, 044
- **Tiền điều kiện / dữ liệu** F-HT v4 `PENDING_REVIEW`.
- **Bước**
  1. Lưu nháp.
  2. Nhập YAML.
  3. Tạo ca kiểm thử mới.
  4. Gọi `:discard`.
- **Mong đợi** Bước 1, 2, 4 trả `409` ERR-04-005. Bước 3 trả `201` (ca kiểm thử gắn luồng, không thuộc phiên bản), nhưng không thay đổi `contentHash` của v4.

### TS-04-15 · Duyệt bốn mắt và so sánh phiên bản

**Mục tiêu.** Không ai tự duyệt được phiên bản mình làm ra, kể cả khi có đủ vai trò. Người duyệt phải xem khác biệt trước khi quyết định. Đây là nhóm ca bắt buộc 100% (thẻ `four-eyes`).

**Phủ.** FR-04-041, 043; BR-04-005, 017; UC-04-11; API-04-025, 052, 053; UI-04-14, 16; ERR-04-005, 015, 025, 044; EVT-04-04, 05.

#### TC-04-### · Duyệt phiên bản <!--k:approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-041 · BR-04-005 · API-04-053, 025, 052 · UI-04-14 · UC-04-11 · EVT-04-04
- **Tiền điều kiện / dữ liệu** F-HT v4 `PENDING_REVIEW` (người tạo IE1, đóng góp IE2); IA1.
- **Bước**
  1. IA1 gọi `GET /reviews`.
  2. IA1 gọi `GET .../versions/4/diff?base=3&markViewed=true`.
  3. IA1 gọi `:review` với `{"decision":"APPROVE","comment":"Đúng đặc tả","checklist":{"c1":true,"c2":true,"c3":true,"c4":true}}`.
- **Mong đợi** Bước 1: có F-HT v4, `canDecide = true`, `changeSummary` đúng. Bước 2 trả `200` với khác biệt theo chặng. Bước 3 trả `200`, `status = APPROVED`, `approvedBy = IA1`; EVT-04-04 phát. KT: có (`INT_VERSION_APPROVE` với checklist).

#### TC-04-### · Yêu cầu sửa có ý kiến theo chặng <!--k:reqchanges-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-041 · API-04-052 · UI-04-14 · EVT-04-05
- **Tiền điều kiện / dữ liệu** Như trên.
- **Bước**
  1. IA1 gọi `:review` với `decision = REQUEST_CHANGES`, `comment`, `nodeComments = [{"nodeId":"transform-1","text":"Thiếu chuẩn hóa dấu"}]`.
  2. IE1 mở trình thiết kế.
- **Mong đợi** Bước 1: `status = CHANGES_REQUESTED`; EVT-04-05 phát. Bước 2: chặng `transform-1` có huy hiệu ý kiến, bảng Vấn đề có mục "Ý kiến người duyệt"; phiên bản sửa được.

#### TC-04-### · Gửi duyệt lại sau khi sửa <!--k:resubmit-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-040, 041 · API-04-050
- **Tiền điều kiện / dữ liệu** F-HT v4 `CHANGES_REQUESTED`.
- **Bước**
  1. IE1 sửa, chạy thử đạt, `:submit`.
- **Mong đợi** `200`, `status = PENDING_REVIEW`; lịch sử duyệt giữ ý kiến vòng trước.

#### TC-04-### · Tự duyệt bị chặn với người tạo, người đóng góp, người gửi <!--k:four-eyes-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-041 · BR-04-005 · API-04-052 · ERR-04-015
- **Tiền điều kiện / dữ liệu** Ba phiên bản `PENDING_REVIEW` trong WS-HOTICH: (a) do IA2 tạo; (b) do IE1 tạo, IA2 đóng góp một lần lưu; (c) do IE1 tạo, IA2 gửi duyệt. IA2 có cả vai trò IA và IE.
- **Bước**
  1. IA2 xem diff và `:review` APPROVE trên (a), (b), (c).
  2. Xem `GET /reviews` của IA2.
- **Mong đợi** Bước 1: cả ba trả `403` ERR-04-015, trạng thái không đổi; KT: có (`INT_REVIEW_DENIED`, nhật ký an ninh). Bước 2: ba mục có `canDecide = false`; trên giao diện nút "Duyệt" ẩn kèm lý do.

#### TC-04-### · Duyệt khi chưa xem so sánh, thiếu checklist, sai trạng thái <!--k:review-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-041, 043 · BR-04-017 · API-04-052 · ERR-04-005, 025
- **Tiền điều kiện / dữ liệu** F-HT v4 `PENDING_REVIEW`; `tc-nhap` v1 `DRAFT`.
- **Bước**
  1. IA1 `:review` APPROVE khi chưa gọi diff.
  2. IA1 xem diff rồi APPROVE thiếu mục `c3`.
  3. IA1 REQUEST_CHANGES không có `comment`.
  4. IA1 APPROVE `tc-nhap` v1.
- **Mong đợi** Bước 1 trả `409` ERR-04-005 ("chưa xem so sánh"). Bước 2, 3 trả `400` ERR-04-025. Bước 4 trả `409` ERR-04-005.

#### TC-04-### · Duyệt bởi người ngoài không gian hoặc thiếu quyền <!--k:review-scope-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-041, 007 · BR-04-021 · ERR-04-003, 045
- **Tiền điều kiện / dữ liệu** IA thứ ba `U-T68-IA3` không là thành viên WS-HOTICH; IE2 (không có `PERM-04-publish`).
- **Bước**
  1. IA3 `:review` F-HT v4.
  2. IE2 `:review` F-HT v4.
- **Mong đợi** Bước 1 trả `403` ERR-04-003. Bước 2 trả 403-PQ.

#### TC-04-### · Xác thực lại khi duyệt <!--k:reauth-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-04-041, 084 · API-04-052 · ERR-04-044
- **Tiền điều kiện / dữ liệu** `04.review.require-reauth = true`; token của IA1 có `auth_time` cách 10 phút.
- **Bước**
  1. `:review` APPROVE.
  2. Trên giao diện, đăng nhập lại trong cửa sổ bật, duyệt lại.
- **Mong đợi** Bước 1 trả `401` kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300`, `code = ERR-04-044`. Bước 2 trả `200`.

#### TC-04-### · So sánh hai phiên bản bất kỳ <!--k:diff-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-043 · API-04-025 · UI-04-16
- **Tiền điều kiện / dữ liệu** F-HT v2, v3, v4.
- **Bước**
  1. Gọi `diff` v4 với `base=2`.
  2. Mở UI-04-16 chế độ "Sơ đồ" và "YAML".
  3. Gọi `diff` v4 với `base=99`.
- **Mong đợi** Bước 1: `nodes[]` có `ADDED`, `REMOVED`, `MODIFIED` (kèm `fields`), `MOVED` khi chỉ đổi vị trí trong route; khác biệt bố cục không tính. Bước 2: sơ đồ tô xanh, đỏ, vàng; YAML hai cột cuộn đồng bộ. Bước 3 trả `404` ERR-04-004.

### TS-04-16 · Phát hành GitOps và nâng môi trường

**Mục tiêu.** Chỉ phiên bản `APPROVED` đi vào runtime, và chỉ qua Git. Thứ tự môi trường được giữ. `SYNCED` chỉ khi mọi bản sao báo đúng băm. Nhóm ca bắt buộc 100%.

**Phủ.** FR-04-042, 045; BR-04-012, 018, 019, 022; UC-04-12; API-04-054, 056; UI-04-15; ERR-04-005, 009, 022, 023, 029, 041; EVT-04-06, 07, 12; NFR-04-009.

#### TC-04-### · Phát hành lên TEST tới SYNCED <!--k:deploy-sync-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO, E2E
- **Truy vết** FR-04-042 · BR-04-012 · API-04-054 · UI-04-15 · UC-04-12 · EVT-04-06, 07, 12
- **Tiền điều kiện / dữ liệu** F-HT v4 `APPROVED`; IA1.
- **Bước**
  1. Gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"TEST"}` và `Idempotency-Key`.
  2. Mở SSE `.../deployments/{id}/events`.
  3. Đọc `env/test` trên Gitea.
  4. Gọi luồng qua `apisix-int` môi trường TEST.
- **Mong đợi** Bước 1 trả `202`, `syncStatus = PENDING`. Bước 2: `PENDING` → `SYNCING` (có `gitCommit`) → `SYNCED` khi mọi bản sao gửi nhịp tim EVT-04-12 có `contentHash` của v4; `healthStatus = HEALTHY`. Bước 3: commit có thông điệp chứa `flow=tra-cuu-ho-tich version=4 by=U-T68-IA1 trace=…`, `flow.dh.yaml` có `version: 4`, có chữ ký trong `.dh/signatures`. Bước 4: phản hồi do v4 sinh. EVT-04-06, 07 phát. KT: có (`INT_DEPLOY`).

#### TC-04-### · Nâng TEST → STAGING → PROD theo thứ tự <!--k:promote-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-045 · BR-04-019 · API-04-056 · UC-04-12 · NFR-04-009
- **Tiền điều kiện / dữ liệu** v4 `SYNCED`, `HEALTHY` ở TEST; `04.env.soak-minutes.STAGING = 1` (rút ngắn cho kiểm thử); TA có `PERM-04-promote`.
- **Bước**
  1. TA nâng v4 lên STAGING.
  2. Sau 1 phút ổn định, TA nâng lên PROD.
  3. Kiểm Gitea: `env/prod` nhận merge request, CI của kho cấu hình chạy, merge.
- **Mong đợi** Bước 1, 2 trả `202`. Bước 3: merge request có mô tả phiên bản, người duyệt, liên kết so sánh; sau merge, PROD `SYNCED`. Từ lệnh nâng PROD tới `SYNCED` p95 < 3 phút (NFR-04-009). v3 thành `SUPERSEDED` ở PROD.

#### TC-04-### · Sai thứ tự môi trường, chưa ổn định <!--k:promote-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-042, 045 · BR-04-019 · ERR-04-023
- **Tiền điều kiện / dữ liệu** `tc-moi` v1 `APPROVED`, chưa triển khai ở đâu; `04.env.soak-minutes.STAGING = 30`.
- **Bước**
  1. Phát hành `tc-moi` v1 thẳng lên PROD.
  2. Phát hành lên TEST, chờ `SYNCED`, nâng lên PROD (bỏ qua STAGING).
  3. Nâng lên STAGING, ngay lập tức nâng lên PROD.
  4. Cho TEST thành `DEGRADED` (đích mô phỏng trả 500), nâng lên STAGING.
- **Mong đợi** Bước 1, 2, 3, 4 trả `409` ERR-04-023, `detail` nêu môi trường trước và điều kiện còn thiếu (thời gian ổn định còn lại ở bước 3). Git: không cho PROD.

#### TC-04-### · Chỉ phiên bản đã duyệt được phát hành <!--k:release-draft-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-042 · BR-04-012 · ERR-04-005
- **Tiền điều kiện / dữ liệu** `tc-nhap` v1 `DRAFT`; F-HT phiên bản `PENDING_REVIEW`.
- **Bước**
  1. IA1 phát hành `tc-nhap` v1 lên TEST.
  2. IA1 phát hành phiên bản `PENDING_REVIEW` lên TEST.
  3. Dùng tài khoản Git của nhân viên DevOps đẩy trực tiếp một `flow.camel.yaml` không có chữ ký vào `env/test`.
- **Mong đợi** Bước 1, 2 trả `409` ERR-04-005. Bước 3: CI kho cấu hình (ADR-068) từ chối vì thiếu chữ ký hợp lệ; nếu nhánh bảo vệ bị vượt qua thì `FlowLoader` của runtime từ chối nạp tệp không có chữ ký khớp `contentHash` đã duyệt, ghi `loadError`, phát cảnh báo an ninh PH-13. Luồng không chạy.

#### TC-04-### · Lỗi ghi Git <!--k:deploy-gitfail-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-042 · API-04-054 · ERR-04-022
- **Tiền điều kiện / dữ liệu** Gitea trả `500` cho mọi lệnh đẩy (Chaos Mesh hoặc WireMock trước Gitea).
- **Bước**
  1. Phát hành F-HT v4 lên TEST.
- **Mong đợi** `202`; sau ba lần thử lại giãn cách, triển khai `FAILED`, `errorCode = ERR-04-022`; phiên bản vẫn `APPROVED`; nút "Thử lại" có trên UI-04-15. Runtime vẫn chạy phiên bản cũ.

#### TC-04-### · Quá hạn đồng bộ <!--k:deploy-timeout-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** GO
- **Truy vết** FR-04-042 · BR-04-018
- **Tiền điều kiện / dữ liệu** `04.deploy.timeout-minutes = 2`; Argo CD tạm dừng đồng bộ ứng dụng `dh-runtime-t68-test`.
- **Bước**
  1. Phát hành v4 lên TEST, chờ 2 phút.
- **Mong đợi** `SYNCING` → `FAILED` với lý do lấy từ trạng thái Argo CD ("OutOfSync"); EVT-04-07 phát; thông báo người phát hành.

#### TC-04-### · Phát hành trong khoảng đóng băng, không có hồ sơ runtime <!--k:deploy-freeze-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-042, 084 · BR-04-022 · ERR-04-041, 029
- **Tiền điều kiện / dữ liệu** TA đặt khoảng đóng băng 2 giờ tới; `tc-jvm` dùng thành phần chỉ JVM, tenant không được hồ sơ JVM.
- **Bước**
  1. Phát hành F-HT v4 lên PROD.
  2. Phát hành F-HT v4 lên TEST.
  3. Phát hành `tc-jvm` lên TEST.
- **Mong đợi** Bước 1 trả `423` ERR-04-041 kèm `until`. Bước 2 trả `202` (đóng băng chỉ chặn PROD). Bước 3 trả `422` ERR-04-029.

#### TC-04-### · Lệch băm sau khi đồng bộ <!--k:out-of-sync-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** GO
- **Truy vết** FR-04-042, 051 · BR-04-018 · EVT-04-07, 12
- **Tiền điều kiện / dữ liệu** v4 `SYNCED` ở TEST; giả lập một bản sao báo nhịp tim với `contentHash` khác (bản sao bị sửa ConfigMap bằng tay).
- **Bước**
  1. Sửa ConfigMap của luồng trong namespace `dh-rt-t68` bằng `kubectl`.
  2. Chờ 2 nhịp tim.
- **Mong đợi** Argo CD tự đưa ConfigMap về bản Git (self-heal). Trong lúc lệch, triển khai `OUT_OF_SYNC`, EVT-04-07 phát; khi khớp lại thì về `SYNCED`. Cảnh báo PH-13 "Cấu hình runtime bị sửa ngoài GitOps".

### TS-04-17 · Quay lui

**Phủ.** FR-04-044; BR-04-017, 019, 022; UC-04-13; API-04-055; UI-04-15; ERR-04-025, 040.

#### TC-04-### · Quay lui PROD về phiên bản trước <!--k:rollback-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-044 · API-04-055 · UC-04-13 · EVT-04-06
- **Tiền điều kiện / dữ liệu** v4 chạy PROD, v3 `SUPERSEDED`; IA1.
- **Bước**
  1. Gọi `POST /flows/tra-cuu-ho-tich/deployments:rollback` với `{"environment":"PROD","targetVersionNo":3,"reason":"Tỷ lệ lỗi tăng sau phát hành v4"}`.
- **Mong đợi** `202`; triển khai `kind = ROLLBACK` không cần duyệt lại và không cần qua STAGING (BR-04-019 trừ quay lui); PROD `SYNCED` với v3; v4 thành `ROLLED_BACK`. KT: có (`INT_ROLLBACK` có lý do).

#### TC-04-### · Quay lui trong khoảng đóng băng <!--k:rollback-freeze-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-044, 084 · BR-04-022
- **Tiền điều kiện / dữ liệu** Khoảng đóng băng đang hiệu lực.
- **Bước**
  1. Quay lui PROD về v3.
- **Mong đợi** `202` (quay lui được phép khi đóng băng).

#### TC-04-### · Quay lui về phiên bản dùng thành phần nay bị cấm, thiếu lý do <!--k:rollback-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-044 · ERR-04-040, 025, 004
- **Tiền điều kiện / dữ liệu** F-HT v2 dùng `ftp`, nay T68 cấm `ftp`.
- **Bước**
  1. Quay lui về v2.
  2. Quay lui về v3 với `reason = "lỗi"`.
  3. Quay lui về v9.
- **Mong đợi** Lần lượt `409` ERR-04-040 (gợi ý tạm dừng khẩn), `400` ERR-04-025, `404` ERR-04-004.

#### TC-04-### · Gợi ý quay lui khi tỷ lệ lỗi tăng <!--k:rollback-suggest-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** E2E
- **Truy vết** FR-04-044, 051 · UI-04-15
- **Tiền điều kiện / dữ liệu** `04.deploy.rollback-suggest-error-ratio = 2`; sau phát hành v4, đích trả 500 cho 30% lượt (v3 trước đó 5%).
- **Bước**
  1. Mở UI-04-02 sau 5 phút.
- **Mong đợi** Banner "Tỷ lệ lỗi gấp 6 lần phiên bản trước. Cân nhắc quay lui về v3." với nút "Quay lui". Hệ thống không tự quay lui.

### TS-04-18 · Lệnh runtime có ký: tạm dừng, tiếp tục, dừng khẩn, đối soát

**Mục tiêu.** Thay Start/Stop qua JMX-Jolokia của Bus cũ bằng lệnh có ký, hạn ngắn, xác nhận theo từng bản sao. Mọi trạng thái mong muốn cuối cùng phải về Git. Nhóm ca bắt buộc 100% (thẻ `signed-command`).

**Phủ.** FR-04-050; BR-04-017, 018; UC-04-14, 15; API-04-061; UI-04-02; ERR-04-023, 024, 025; EVT-04-08, 11, 13; NFR-04-010; LGC-BUS-009, 012.

#### TC-04-### · Tạm dừng một route ở PROD <!--k:pause-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-050 · API-04-061 · UC-04-14 · EVT-04-08, 11, 13 · NFR-04-010 · LGC-BUS-009
- **Tiền điều kiện / dữ liệu** F-HT v4 chạy PROD, 2 bản sao; U-T68-TO.
- **Bước**
  1. Gọi `POST /flows/tra-cuu-ho-tich/runtime/commands` với `{"environment":"PROD","action":"PAUSE","scope":"ROUTES","routeIds":["tra-cuu-ho-tich-main"],"reason":"Bảo trì HTTT hộ tịch 22:00–23:00","drain":true}`.
  2. Theo dõi `GET .../commands/{id}`.
  3. Gọi luồng qua APISIX.
- **Mong đợi** Bước 1 trả `202`, `status = ISSUED`, `expiresAt = issuedAt + 60 giây`. EVT-04-11 có `signature`, `keyId`. Bước 2: hai `acks` `APPLIED`, `status = ACKNOWLEDGED` trong p95 < 10 giây. Bước 3 trả `503` ERR-04-110. EVT-04-08 phát. Trong vòng 5 phút `desiredState` của route được ghi vào Git (`flow.dh.yaml`), lệnh `RECONCILED`. KT: có (`INT_RUNTIME_PAUSE` có lý do).

#### TC-04-### · Tiếp tục route <!--k:resume-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-050 · API-04-061 · LGC-BUS-012
- **Tiền điều kiện / dữ liệu** Route đã tạm dừng ở ca trên.
- **Bước**
  1. TO gửi `RESUME` cùng phạm vi.
  2. Gọi luồng.
- **Mong đợi** `ACKNOWLEDGED`; gọi luồng trả `200`. Bảng route bỏ nhãn "Tạm dừng bởi…".

#### TC-04-### · Dừng khẩn đi trước Git <!--k:estop-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, GO
- **Truy vết** FR-04-050 · BR-04-018 · API-04-061 · UC-04-15 · NFR-04-010
- **Tiền điều kiện / dữ liệu** F-HT PROD; U-T68-SO; Gitea bị làm chậm 30 giây mỗi lệnh đẩy.
- **Bước**
  1. SO gửi `EMERGENCY_STOP`, `scope = FLOW`, `drain = false`, `incidentRef = "SC-2026-001"`.
  2. Đo thời gian tới khi cả hai bản sao xác nhận.
  3. Chờ đối soát.
- **Mong đợi** Bước 2: < 5 giây, không phụ thuộc độ chậm của Git. Bản sao đặt `localOverride = true` trong nhịp tim. Bước 3: tiến trình `system:int-reconciler` ghi trạng thái `PAUSED` vào Git trong ≤ 5 phút; khi Git khớp, bản sao bỏ `localOverride`. Argo CD đồng bộ trong lúc đó **không** bật lại luồng. KT: có (`INT_RUNTIME_ESTOP`, người thực hiện SO và `system:int-reconciler` cho lần ghi Git).

#### TC-04-### · Đối soát hoàn tất <!--k:reconcile-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** GO
- **Truy vết** FR-04-050 · BR-04-018
- **Tiền điều kiện / dữ liệu** Lệnh `ACKNOWLEDGED` từ ca tạm dừng.
- **Bước**
  1. Đọc `GET .../commands/{id}` sau 5 phút.
  2. Đọc `flow.dh.yaml` trên `env/prod`.
- **Mong đợi** `status = RECONCILED`, `reconciledAt` ≤ `issuedAt + 5 phút`. Tệp có trạng thái mong muốn của route khớp runtime.

#### TC-04-### · Một bản sao không xác nhận, gửi lại <!--k:partial-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** API, Chaos
- **Truy vết** FR-04-050 · API-04-061 · ERR-04-024
- **Tiền điều kiện / dữ liệu** Chaos Mesh cắt mạng Kafka của bản sao thứ hai.
- **Bước**
  1. TO gửi `PAUSE`.
  2. Sau 30 giây đọc lệnh.
  3. Khôi phục mạng, gọi `:resend`.
- **Mong đợi** Bước 2: `status = PARTIAL`, `ackedReplicas = 1/2`, giao diện liệt kê bản sao chưa xác nhận và nút "Gửi lại lệnh". Bước 3: lệnh mới có `resendOf` = lệnh cũ, chữ ký mới, hạn mới; sau khi đủ xác nhận, lệnh gốc `ACKNOWLEDGED`.

#### TC-04-### · Lệnh có chữ ký sai <!--k:cmd-badsig-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-04-050 · EVT-04-11, 13 · ERR-04-024
- **Tiền điều kiện / dữ liệu** Client Kafka thử có quyền ghi `dh.integration.runtime.command.v1` (giả định kẻ tấn công vượt được ACL).
- **Bước**
  1. Gửi lệnh `EMERGENCY_STOP` với chữ ký Ed25519 sai.
  2. Gửi lệnh đúng chữ ký nhưng sửa `flowCode` sau khi ký.
- **Mong đợi** Runtime không thực thi; gửi ack `REJECTED`, `reason = BAD_SIGNATURE`; luồng vẫn chạy; cảnh báo an ninh mức cao ở PH-13.

#### TC-04-### · Lệnh hết hạn và lệnh phát lại <!--k:cmd-expired-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-04-050 · EVT-04-11, 13
- **Tiền điều kiện / dữ liệu** Một lệnh hợp lệ đã thực thi lúc T; bản ghi Kafka của nó.
- **Bước**
  1. Phát lại bản tin lệnh đó lúc T + 90 giây.
  2. Phát lại lúc T + 20 giây.
- **Mong đợi** Bước 1: `REJECTED`, `reason = EXPIRED`. Bước 2: `REJECTED`, `reason = DUPLICATE` (đã xử lý `commandId`). Không có thay đổi trạng thái route.

#### TC-04-### · Lệnh mang tenant khác hoặc luồng không tồn tại <!--k:cmd-tenant-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-04-050, 073 · EVT-04-13
- **Tiền điều kiện / dữ liệu** Lệnh ký đúng khóa nhưng `tenantId = T01` gửi tới runtime namespace `dh-rt-t68`; lệnh cho `flowCode = khong-co`.
- **Bước**
  1. Gửi hai lệnh.
- **Mong đợi** Lần lượt `REJECTED` với `TENANT_MISMATCH`, `UNKNOWN_FLOW`. Runtime T68 không thay đổi.

#### TC-04-### · Lệnh thiếu lý do, sai quyền, môi trường chưa triển khai <!--k:cmd-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-050 · BR-04-017 · API-04-061 · ERR-04-025, 023, 045
- **Tiền điều kiện / dữ liệu** F-SQL chỉ chạy TEST; TO (không có `PERM-04-emergency-stop`); IE1.
- **Bước**
  1. TO `PAUSE` F-HT với `reason = "bảo trì"`.
  2. TO `PAUSE` F-SQL ở PROD.
  3. TO `EMERGENCY_STOP` F-HT.
  4. IE1 `PAUSE` F-HT.
- **Mong đợi** Lần lượt `400` ERR-04-025, `409` ERR-04-023, 403-PQ, 403-PQ. EVT: không.

#### TC-04-### · Tiếp tục sau dừng khẩn chỉ SO hoặc TA <!--k:estop-resume-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-050 · UC-04-15
- **Tiền điều kiện / dữ liệu** F-HT đang dừng khẩn.
- **Bước**
  1. TO gửi `RESUME`.
  2. TA gửi `RESUME`.
- **Mong đợi** Bước 1 trả 403-PQ với `detail` "Luồng đang dừng khẩn; chỉ cán bộ ATTT hoặc quản trị tenant tiếp tục được" (Q04-47). Bước 2 trả `202`.

### TS-04-19 · Tình trạng runtime, điểm kết nối, giám sát, lịch sử

**Phủ.** FR-04-051, 052, 053, 083; API-04-060, 062, 063, 091; UI-04-02; ERR-04-047; LGC-BUS-007, 014…019, 030, 033.

#### TC-04-### · Tình trạng runtime theo môi trường và bản sao <!--k:runtime-status-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-04-051 · API-04-060 · UI-04-02 · LGC-BUS-014, 015, 017
- **Tiền điều kiện / dữ liệu** F-HT chạy ba môi trường; một route PROD đang tạm dừng.
- **Bước**
  1. Gọi `GET /flows/tra-cuu-ho-tich/runtime`.
  2. Dừng một bản sao PROD (xóa pod), gọi lại sau 70 giây.
- **Mong đợi** Bước 1: mỗi môi trường có `versionNo`, `syncStatus`, `healthStatus`, `readyReplicas`/`replicas`, `lastHeartbeatAt`; route tạm dừng có `pausedBy`, `pauseReason`. Bước 2: bản sao mất nhịp tim quá 60 giây không còn trong danh sách; `healthStatus = DEGRADED` tới khi pod mới sẵn sàng.

#### TC-04-### · Lỗi nạp luồng hiển thị cho người vận hành <!--k:load-error-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** GO
- **Truy vết** FR-04-051 · API-04-060
- **Tiền điều kiện / dữ liệu** Phát hành `tc-nap-loi` có tham chiếu kết nối mà PH-05 chưa cấp giá trị cho PROD (vượt qua kiểm tra do PH-05 đổi sau khi duyệt).
- **Bước**
  1. Phát hành lên TEST; đọc runtime.
- **Mong đợi** Triển khai `FAILED`, `loadError` nêu "Không phân giải được {{conn:…}} ở TEST" (không lộ giá trị); các luồng khác trong cùng pod vẫn chạy (lỗi nạp một luồng không làm hỏng context).

#### TC-04-### · Điểm kết nối và số liệu theo điểm <!--k:endpoints-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-052 · API-04-062 · LGC-BUS-018
- **Tiền điều kiện / dữ liệu** F-HT PROD có lưu lượng giả lập 1 giờ.
- **Bước**
  1. Gọi `GET .../endpoints?environment=PROD`.
- **Mong đợi** `items` có một điểm `IN` (`platform-http`, `httpPath`) và các điểm `OUT` (`http` qua CONN-HT, `kafka` topic kiểm toán); `uri` đã che tham số; `metrics` khớp Prometheus trong sai số 1%.

#### TC-04-### · Số liệu và lịch sử khi PH-13 không sẵn sàng <!--k:metrics-history-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-04-053, 083 · API-04-063, 091 · ERR-04-047 · LGC-BUS-007, 033
- **Tiền điều kiện / dữ liệu** U-T68-AU, U-T68-VW.
- **Bước**
  1. AU gọi `GET .../metrics?environment=PROD&step=1m`.
  2. AU gọi `GET .../history?action=INT_DEPLOY`.
  3. VW gọi `GET .../history`.
  4. Dừng PH-13, AU gọi lại bước 2.
- **Mong đợi** Bước 1: chuỗi `exchanges`, `failures`, `p95ms`, `dlq`, `dashboardUrl`. Bước 2: các lần triển khai có `before`, `after`. Bước 3: không có `before`, `after`. Bước 4 trả `503` ERR-04-047; các API khác của PH-04 vẫn trả bình thường.

