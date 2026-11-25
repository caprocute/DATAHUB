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

