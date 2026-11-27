---
ma_tai_lieu: D05-02-PH04
ten: Kịch bản và test case phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Đội kiểm thử, Đội phát triển PH-04 (L-INT, frontend console), Kiến trúc sư, ATTT, Vận hành, Cán bộ nghiệm thu, Chủ đầu tư
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
mo_ta: Kịch bản và test case của phân hệ Lõi tích hợp và trình thiết kế luồng, chạy được ngay trên SIT với bộ dữ liệu mẫu, kèm nghiệm thu tương đương Bus và Tooling cũ, ma trận truy vết sinh tự động, tệp Gherkin và bảng tính ghi kết quả.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH04 FRS; D02-04-PH04 Use case; D03-02-PH04 SDD; D03-03-PH04 CSDL; D03-04-PH04 API; D03-06-PH04 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH04 · Kịch bản và test case phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- Lõi tích hợp làm đúng mọi yêu cầu đã duyệt.
- Lõi không làm mất chức năng của Bus tích hợp và công cụ kéo thả Productivity Tooling đang vận hành.
- Không có đường nào để một luồng chưa được duyệt, hoặc một luồng của tỉnh này, chạm vào dữ liệu của tỉnh khác.

**Phạm vi.** Gồm <!--gen:so-ts-->32<!--/gen--> kịch bản (TS-04-01…32) với <!--gen:so-tc-->202 test case (TC-04-001…202; 119 ca P1)<!--/gen--> và 12 kịch bản nghiệm thu người dùng (UAT-01…12). Phạm vi phủ:

- Ở control plane: không gian làm việc, luồng, phiên bản, trình thiết kế, kiểm tra hợp lệ, chạy thử, duyệt bốn mắt, phát hành GitOps, lệnh runtime, catalog, di trú dữ liệu W2.
- Ở data plane: chín chặng chuẩn, Kafka, xử lý lỗi, truy cập CSDL có kiểm soát theo Q359.
- Các yêu cầu phi chức năng: hiệu năng, bảo mật theo OWASP ASVS 5.0, khả dụng, truy cập theo WCAG 2.2 AA.

Mỗi yêu cầu mức bắt buộc (M) có ít nhất một ca dương tính và một ca âm tính. Bốn trình tự chính của SDD (phát hành tới `SYNCED`, chạy thử `MOCK`, gửi duyệt và duyệt bốn mắt, dừng khẩn) có ca đầu cuối riêng. Ma trận truy vết ở mục 8 được sinh tự động từ chính tài liệu này.

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

Chương này nói tài liệu dùng để làm gì, cho ai, phủ đến đâu và đọc theo thứ tự nào. Người chỉ cần kết luận đọc phần tóm tắt ở trên và mục 7, 8; người viết hoặc chạy ca đọc thêm mục 1, 2 rồi vào thẳng chương 4, 5.

### 0.1. Mục đích

Tài liệu này là đặc tả kiểm thử của PH-04, lập theo ISO/IEC/IEEE 29119-3, gồm ba phần:

- đặc tả thiết kế kiểm thử: các kịch bản `TS-04-nn`;
- đặc tả ca kiểm thử: các test case `TC-04-nnn`, mỗi ca một khối đặc tả hai cột;
- đặc tả thủ tục kiểm thử: các bước trong từng ca, cùng thủ tục thủ công ở mục 6 và mẫu tự động hóa ở mục 9.

Ca được viết để kiểm thử viên chạy được ngay trên SIT với bộ dữ liệu mục 2, không cần hỏi lại người viết; kỹ sư dùng cùng ca đó làm tiêu chí nghiệm thu khi viết mã.

### 0.2. Phạm vi

PH-04 có hai phần chạy rất khác nhau, nên được kiểm thử theo hai trục:

- **Control plane** `dh-integration`, module `flow`: API REST `/api/integration/v1` (API-04-001…091) và giao diện UI-04-01…21. Rủi ro chính là phân quyền, bốn mắt, xung đột soạn đồng thời, mất dữ liệu khi quay vòng YAML, và triển khai phiên bản chưa duyệt.
- **Data plane** `dh-runtime` và `dh-runtime-sandbox`: các luồng Camel đã phát hành. Rủi ro chính là rò rỉ tenant, lộ dữ liệu cá nhân trong log, ghi CSDL nguồn, nhận lệnh giả mạo, và mất bản tin.

Kế hoạch kiểm thử tổng thể ở D05-01. Tài liệu này kế thừa mọi quy định chung từ đó và theo đúng độ sâu của mẫu D05-02-PH07, D05-02-PH05. Thành phần ngoài phạm vi chỉ được giả lập, liệt kê ở mục 1.1.

### 0.3. Người đọc

| Người đọc | Dùng tài liệu để | Đọc trước |
|---|---|---|
| Hội đồng thẩm định, chủ đầu tư | Đánh giá độ phủ và điều kiện phát hành | Tóm tắt, mục 7, 8 |
| Kiểm thử viên | Chạy ca, ghi kết quả vào bảng tính | Mục 1, 2, chương 4, 5 |
| Kỹ sư PH-04 (L-INT, frontend console) | Viết ca tự động, lấy ca làm tiêu chí nghiệm thu | Mục 1.2, 1.4, chương 4, mục 9 |
| Cán bộ ATTT | Soát ca tenant, bốn mắt, lệnh có ký, bảo mật | TS-04-15, 18, 22, 23, 24, 30 |
| Vận hành | Diễn tập sự cố, ca hỗn loạn | TS-04-18, 31, mục 6.3 |
| Cán bộ vận hành Bus cũ của tỉnh thí điểm | Nghiệm thu tương đương hệ cũ | Mục 7 |

: Người đọc và cách dùng tài liệu

### 0.4. Thuật ngữ và viết tắt

Thuật ngữ chung dùng theo D00-01 và D02-03-PH04 §1.4. Bảng dưới chỉ nêu những từ hay gặp trong tài liệu này.

| Thuật ngữ | Nghĩa |
|---|---|
| Kịch bản (TS) | Nhóm ca cùng mục tiêu kiểm thử, thường ứng với một use case |
| Test case, ca (TC) | Một phép kiểm có dữ liệu, bước, kết quả mong đợi xác định |
| Ca dương, ca âm | Ca chứng minh hệ làm đúng khi đầu vào hợp lệ; ca chứng minh hệ từ chối đúng khi đầu vào sai hoặc thiếu quyền |
| UAT | Nghiệm thu người dùng (User Acceptance Test), do người dùng nghiệp vụ tự thực hiện |
| SIT, PERF, UAT | Môi trường kiểm thử tích hợp, hiệu năng, nghiệm thu (mục 1.3) |
| MOCK, SANDBOX_LIVE, SIMULATED | Chế độ chạy thử: đích mô phỏng; đích thật môi trường TEST; mô phỏng tĩnh của mã W2 (không tính cho gửi duyệt) |
| GitOps | Cách phát hành bằng ghi cấu hình vào kho Git, Argo CD đồng bộ xuống cụm |
| SYNCED, OUT_OF_SYNC | Trạng thái triển khai: runtime đã báo đúng phiên bản, băm; lệch so với Git |
| Bốn mắt | Người duyệt phải khác người tạo, người đóng góp, người gửi duyệt |
| DLQ | Hàng bản tin lỗi (Dead Letter Queue) của PH-18 |
| W2 | Đợt mã hiện có trước bản thiết kế này (bảng `route*`, chạy thử giả lập) |
| 403-PQ, 404-ẩn, KT, EVT, Git | Ký hiệu rút gọn trong kết quả mong đợi (mục 1.6) |

: Thuật ngữ và viết tắt

### 0.5. Tài liệu tham chiếu

- Tài liệu PH-04: [FRS](../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md), [Use case](../../02-yeu-cau/use-case/D02-04-PH04-use-case-tich-hop.md), [SDD](../../03-thiet-ke/sdd/D03-02-PH04-sdd-tich-hop.md), [CSDL](../../03-thiet-ke/csdl/D03-03-PH04-csdl-tich-hop.md), [API](../../03-thiet-ke/api/D03-04-PH04-api-tich-hop.md), [Màn hình](../../03-thiet-ke/uiux/D03-06-PH04-man-hinh-tich-hop.md).
- Tài liệu nền: [D02-08](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md), [D03-10](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md), [D04-02](../../04-lap-trinh/D04-02-quy-trinh-ky-thuat.md), [D05-01](../D05-01-master-test-plan.md).
- Tệp đi kèm sinh từ tài liệu này: bảng tính [D05-02-PH04-test-case.xlsx](ph04/D05-02-PH04-test-case.xlsx), Gherkin `ph04/gherkin/*.feature`.
- Chuẩn: ISO/IEC/IEEE 29119-3, OWASP ASVS 5.0, WCAG 2.2.

Khi kỳ vọng phân quyền mâu thuẫn, D02-08 được ưu tiên. Câu thông báo người dùng nhìn thấy lấy từ D03-06-PH04 §5 và D02-03-PH04; câu chưa có ở đó ghi ở mục 11.

### 0.6. Cấu trúc tài liệu

Mục 1 nêu đối tượng, mức, môi trường, công cụ, tiêu chí và quy ước. Mục 2 là bộ dữ liệu kiểm thử có tên. Mục 3 là bảng danh sách kịch bản, máy trạng thái và bảng danh sách mọi test case. Chương 4 đặc tả các ca chức năng theo kịch bản, chương 5 các ca phi chức năng. Mục 6 là thủ tục thủ công, mục 7 nghiệm thu người dùng, mục 8 ma trận truy vết sinh tự động, mục 9 tự động hóa và tệp đi kèm, mục 10 câu hỏi mở, mục 11 đề nghị đồng bộ cho tập khác.

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

: Đối tượng kiểm thử

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

: Mức kiểm thử

### 1.3. Môi trường kiểm thử

| Môi trường | Thành phần | Ghi chú |
|---|---|---|
| CI | Testcontainers: PostgreSQL 18, Kafka KRaft, Valkey 8, Gitea (thay GitHub, GitLab), OpenBao dev, WireMock. Runtime chạy trong JVM | Schema `ph04` tạo bằng Liquibase. Vai trò ứng dụng `ph04_app` không có `BYPASSRLS` |
| SIT | k3d 3 nút; Argo CD; Gitea với kho `dh-flows-t68`, `dh-flows-t01`; Keycloak realm `dh-t68`, `dh-t01`, `dh-platform`; APISIX `apisix-int`; OPA; `dh-integration` 2 bản sao; `dh-runtime` hồ sơ `core-native` 2 bản sao, `soap-jvm` 1 bản sao cho mỗi tenant; `dh-runtime-sandbox` 2 bản sao; Kafka 3 broker; Debezium; Ceph RGW (hoặc MinIO tương thích S3); PostgreSQL nguồn giả lập cho Q359 | Nạp lại bộ dữ liệu mục 2 mỗi đêm |
| PERF | Như SIT; `dh-runtime` native 4 bản sao, mỗi bản sao 1 vCPU, 512 MiB; WireMock đích trả trong 20 ms | Quy mô theo GĐ: 300 luồng mỗi tenant, 3 tenant |
| UAT | Như SIT; luồng chuyển từ gói XML Bus cũ của tỉnh thí điểm, đã gỡ mật khẩu (Q04-49) | Cán bộ vận hành Bus cũ thao tác |

: Môi trường kiểm thử

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

: Công cụ kiểm thử

### 1.5. Tiêu chí vào và ra

**Tiêu chí vào** một đợt kiểm thử hệ thống:

- Bản dựng đã qua CI-1…8.
- Độ phủ dòng của module `flow` ≥ 80%. Độ phủ nhánh của `ValidationEngine`, `SecretDetector`, `SqlPolicy`, `CommandSigner`, máy trạng thái phiên bản ≥ 90%.
- `openapi-integration.yaml` khớp mã (Schemathesis không lỗi).
- Ca khói TC-04-007, TC-04-013, TC-04-043, TC-04-071 đạt trên SIT.

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

Kịch bản có mã `TS-04-nn`, test case có mã `TC-04-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã (D00-01 §3.1). Từ bản 0.2, mỗi test case là một khối đặc tả `::: dac-ta` (bộ xuất dựng thành bảng hai cột), thống nhất với D05-02-PH05 và D05-02-PH07. Khối có bảy mục theo đúng thứ tự sau:

- Tiêu đề (ngoài khối): mã, tên ca, khóa `<!--k:…-->`.
- **Loại.** Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên.** P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động.** UT, IT, RT, API, E2E, GO, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết.** FR, BR, API, UI, ERR, EVT, UC, NFR, LGC liên quan.
- **Tiền điều kiện, dữ liệu.** Tham chiếu mã dữ liệu ở mục 2.
- **Các bước.** Đánh số. Đường dẫn API tương đối với `/api/integration/v1`, trừ đường dẫn gọi luồng (ghi đầy đủ qua `apisix-int`).
- **Kết quả mong đợi.** Mã HTTP, mã lỗi, câu thông báo người dùng nhìn thấy (khi có), trạng thái dữ liệu sau, sự kiện, kiểm toán.

Bảng phụ của một ca (ví dụ ma trận vai trò của TC-04-143) đặt ngay sau khối, có chú thích riêng.

Quy ước rút gọn trong phần mong đợi:

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-04-045 (thiếu quyền chức năng) |
| 404-ẩn | `404` với ERR-04-001, không phân biệt "không tồn tại" và "không được xem" (D03-10 §6 quy tắc 6) |
| KT: có (hành động) | Có bản ghi kiểm toán gửi PH-13 với hành động đó, đủ trường theo FR-00-041 |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: không | Sau 10 giây không có dòng mới trong `ph04.outbox` và không có bản tin trên topic liên quan |
| Git: không | Không có commit mới trên mọi nhánh `env/*` của kho tenant |

: Ký hiệu rút gọn trong kết quả mong đợi

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

: Tenant kiểm thử

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

: Người dùng kiểm thử theo vai trò

Mọi người dùng có vai trò TA, SO, IA, PA đã đăng ký TOTP thử trong realm SIT, để không vướng FR-00-002 và để kiểm thử xác thực lại (`auth_time`).

### 2.3. Không gian làm việc

| Mã | Tenant | Thành viên | Ghi chú |
|---|---|---|---|
| WS-HOTICH | T68 | IE1, IE2 `EDIT`; IA1, IA2 `MAINTAIN`; VW `VIEW` | Mã `ho-tich` |
| WS-DATDAI | T68 | IE2, IE3 `EDIT` | Mã `dat-dai` |
| WS-ARCH | T68 | — | Đã lưu trữ, không chọn được khi tạo luồng |
| DEFAULT | T68, T01 | — | Không gian mặc định khi `04.workspace.enforce = false` |

: Không gian làm việc mẫu

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

: Luồng mẫu dùng trong ca

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

: Kết nối, topic, khuôn mẫu

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

: Bản tin và tệp mẫu

### 2.7. Nguyên tắc dữ liệu

Ca không phụ thuộc thứ tự chạy, trừ khi ghi rõ "sau TC-…". Ca tạo dữ liệu dùng mã tiền tố `tc-{số ca}` và tự dọn bằng API gỡ. Ca hiệu năng dùng bộ dữ liệu sinh riêng ở PERF. Không ca nào dùng dữ liệu cá nhân thật. Bản tin mẫu có dạng số định danh đều là giá trị thử.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

Mỗi kịch bản gom các ca cùng mục tiêu, thường ứng với một use case. Cột "FR chính" và "UC" ghi ba chữ số cuối của mã; cột "Số ca" do `ph04/tools/fill_doc.py` đếm lại từ chương 4, 5 nên luôn khớp.

<!--gen:ts-table-->
| Kịch bản | Tên | FR chính | UC | Số ca |
|---|---|---|---|---|
| TS-04-01 | Không gian làm việc và thành viên | 007 | 01 | 7 |
| TS-04-02 | Danh sách, tìm kiếm, chi tiết luồng | 001, 002 | 02 | 6 |
| TS-04-03 | Tạo luồng từ luồng trống, khuôn, API, YAML | 003, 025 | 03 | 9 |
| TS-04-04 | Sửa thông tin, nhân bản, hủy nháp, gỡ luồng | 004, 005, 006 | 16 | 8 |
| TS-04-05 | Phiên bản, lưu nháp, ETag, phiên soạn, gộp ba bên | 010, 011, 024 | 04 | 8 |
| TS-04-06 | Trình thiết kế: bảng thành phần, sơ đồ, cấu hình chặng | 012, 013, 014 | 04, 05 | 6 |
| TS-04-07 | Quay vòng YAML, tải xuống, nhập YAML | 017, 027 | 04 | 5 |
| TS-04-08 | Biểu thức, kết nối, bí mật, bản tin mẫu | 015, 016, 022 | 05 | 7 |
| TS-04-09 | Trình ánh xạ dữ liệu | 020 | 06 | 4 |
| TS-04-10 | Kamelet, Pipe, bean, ghi chú, luồng con | 018, 019, 021, 026 | 07 | 6 |
| TS-04-11 | Kiểm tra hợp lệ VR-01…20 | 023 | 04 | 9 |
| TS-04-12 | Chạy thử trên sandbox | 030, 032, 033 | 08 | 10 |
| TS-04-13 | Ca kiểm thử của luồng | 031 | 09 | 2 |
| TS-04-14 | Gửi duyệt, rút lại | 040 | 10 | 6 |
| TS-04-15 | Duyệt bốn mắt và so sánh phiên bản | 041, 043 | 11 | 10 |
| TS-04-16 | Phát hành GitOps và nâng môi trường | 042, 045 | 12 | 10 |
| TS-04-17 | Quay lui | 044 | 13 | 4 |
| TS-04-18 | Lệnh runtime có ký: tạm dừng, tiếp tục, dừng khẩn, đối soát | 050 | 14, 15 | 11 |
| TS-04-19 | Tình trạng runtime, điểm kết nối, giám sát, lịch sử | 051, 052, 053, 083 | 02 | 4 |
| TS-04-20 | Data plane đồng bộ qua chín chặng | 060, 061, 063…068 | 17 | 10 |
| TS-04-21 | Data plane bất đồng bộ, xử lý lỗi, chống trùng | 062, 069, 070, 071 | 18 | 5 |
| TS-04-22 | Truy cập CSDL có kiểm soát (Q359) | 072 | 19 | 4 |
| TS-04-23 | Ngữ cảnh tenant và rò rỉ chéo tenant | 073 | 17, 18 | 4 |
| TS-04-24 | Ma trận phân quyền và phạm vi không gian làm việc | 007, mọi FR | — | 3 |
| TS-04-25 | Catalog, chính sách thành phần, hồ sơ runtime | 075, 080, 081 | 21, 22 | 6 |
| TS-04-26 | Chuyển Camel XML của Bus cũ | 082 | 20 | 3 |
| TS-04-27 | Tham số PH-04 và đóng băng thay đổi | 084 | 7.1 | 3 |
| TS-04-28 | Sự kiện, outbox và hợp đồng API | 074, mọi EVT | — | 4 |
| TS-04-29 | Hiệu năng | NFR-04-001…013 | — | 14 |
| TS-04-30 | Bảo mật (ASVS) | — | — | 6 |
| TS-04-31 | Khả dụng và hỗn loạn | NFR-04-014 | — | 4 |
| TS-04-32 | Truy cập, bàn phím và bề rộng màn hình | NFR-04-015…017 | — | 4 |
| **Tổng** | | | | **202** (119 ca P1) |

: Danh sách kịch bản kiểm thử
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Mỗi chuyển trạng thái hợp lệ có ít nhất một ca dương tính. Mỗi chuyển không hợp lệ quan trọng có ít nhất một ca âm tính. Máy trạng thái theo SDD §9.

| Máy | Chuyển hợp lệ (ca) | Chuyển bị cấm (ca) |
|---|---|---|
| Phiên bản | DRAFT → PENDING_REVIEW (TC-04-082); PENDING_REVIEW → DRAFT khi rút (TC-04-086); PENDING_REVIEW → APPROVED (TC-04-088, đầu cuối TC-04-193); PENDING_REVIEW → CHANGES_REQUESTED (TC-04-089); CHANGES_REQUESTED → PENDING_REVIEW (TC-04-090); DRAFT → DISCARDED (TC-04-024); APPROVED → SUPERSEDED (TC-04-097); SUPERSEDED → ROLLED_BACK ngược (TC-04-104) | Sửa PENDING_REVIEW, APPROVED (TC-04-031, TC-04-087); duyệt DRAFT (TC-04-092); phát hành DRAFT (TC-04-099) |
| Triển khai | PENDING → SYNCING → SYNCED (TC-04-096, PROD đầu cuối TC-04-196); PENDING → FAILED do Git (TC-04-100); SYNCING → FAILED do quá hạn (TC-04-101); SYNCED → OUT_OF_SYNC → SYNCED khi lệch băm (TC-04-103) | Lên môi trường sau khi môi trường trước chưa đạt (TC-04-098) |
| Lệnh | ISSUED → ACKNOWLEDGED (TC-04-108); ISSUED → PARTIAL → ACKNOWLEDGED khi gửi lại (TC-04-112); ISSUED → REJECTED (TC-04-113, TC-04-115); ACKNOWLEDGED → RECONCILED (TC-04-111, dừng khẩn đầu cuối TC-04-197) | Lệnh hết hạn hoặc phát lại được thực thi (TC-04-114) |
| Lần chạy thử | QUEUED → RUNNING → PASSED, FAILED (TC-04-071, TC-04-072, đầu cuối TC-04-192); RUNNING → TIMED_OUT (TC-04-074); QUEUED → CANCELLED (TC-04-076) | Mô phỏng được tính cho gửi duyệt (TC-04-084, dữ liệu di trú W2 TC-04-202) |
| Luồng | ACTIVE → PAUSED → ACTIVE (TC-04-108, TC-04-109, TC-04-198); ACTIVE → RETIRED (TC-04-026) | Sửa luồng RETIRED (TC-04-028) |

: Máy trạng thái được kiểm thử

### 3.3. Danh sách test case

Bảng liệt kê mọi test case theo mã, trước phần đặc tả chi tiết ở chương 4 và 5. Cột "Kịch bản" ghi hai chữ số cuối của `TS-04-nn`. Bảng do `ph04/tools/fill_doc.py` sinh từ các khối đặc tả nên không sửa tay; ca mới có số lớn hơn 186 nằm trong kịch bản đúng chủ đề chứ không ở cuối.

<!--gen:tc-table-->
| Ca | Tên | Kịch bản | Loại | Ưu tiên | Tự động |
|---|---|---|---|---|---|
| TC-04-001 | Liệt kê, tạo và sửa không gian làm việc | 01 | Dương | P2 | API, E2E |
| TC-04-002 | Tạo không gian trùng mã, sửa không gian không tồn tại | 01 | Âm | P2 | API |
| TC-04-003 | Thay danh sách thành viên và hiệu lực ngay | 01 | Dương | P1 | API |
| TC-04-004 | Thành viên mức VIEW và người ngoài không gian | 01 | Âm, Bảo mật | P1 | API |
| TC-04-005 | Tắt giới hạn không gian làm việc | 01 | Dương | P2 | API |
| TC-04-006 | Lưu trữ không gian còn luồng | 01 | Dương, Âm | P3 | API, E2E |
| TC-04-007 | Liệt kê luồng có lọc, đếm theo trạng thái | 02 | Dương | P1 | API, E2E |
| TC-04-008 | Tìm theo endpoint | 02 | Dương | P2 | API |
| TC-04-009 | Tham số danh sách không hợp lệ | 02 | Âm, Biên | P2 | API |
| TC-04-010 | Chi tiết luồng đầy đủ | 02 | Dương | P1 | API, E2E |
| TC-04-011 | Chi tiết luồng không tồn tại hoặc ở tenant khác | 02 | Âm, Bảo mật | P1 | API |
| TC-04-012 | Phụ thuộc của luồng | 02 | Dương | P2 | API |
| TC-04-013 | Tạo luồng trống | 03 | Dương | P1 | API, E2E |
| TC-04-014 | Tạo luồng từ khuôn có tham số | 03 | Dương | P2 | API, E2E |
| TC-04-015 | Tạo luồng từ OpenAPI của API công bố | 03 | Dương | P2 | API |
| TC-04-016 | Tạo luồng từ tệp YAML | 03 | Dương | P2 | API |
| TC-04-017 | Mã luồng sai định dạng hoặc trùng | 03 | Âm, Biên | P1 | API |
| TC-04-018 | Tạo luồng với nội dung không hợp lệ | 03 | Âm | P1 | API |
| TC-04-019 | Chống trùng khi tạo luồng | 03 | Âm, Biên | P2 | API |
| TC-04-020 | Bắt buộc căn cứ pháp lý cho luồng đối ngoại | 03 | Âm, Dương | P3 | API, E2E |
| TC-04-021 | Sửa thông tin luồng | 04 | Dương | P1 | API |
| TC-04-022 | Sửa thông tin luồng: khóa lạc quan và quyền | 04 | Âm | P1 | API |
| TC-04-023 | Nhân bản luồng | 04 | Dương | P2 | API, E2E |
| TC-04-024 | Hủy bản nháp | 04 | Dương | P2 | API |
| TC-04-025 | Hủy bản nháp không đúng trạng thái | 04 | Âm | P2 | API |
| TC-04-026 | Gỡ luồng đã phát hành, rút theo thứ tự môi trường | 04 | Dương | P1 | API, GO |
| TC-04-027 | Gỡ luồng còn phụ thuộc, thiếu lý do | 04 | Âm | P1 | API |
| TC-04-028 | Luồng đã gỡ chỉ đọc | 04 | Âm | P2 | API |
| TC-04-029 | Lưu nháp và tính lại băm | 05 | Dương | P1 | API |
| TC-04-030 | Lưu nháp sai điều kiện | 05 | Âm | P1 | API |
| TC-04-031 | Phiên bản đã gửi duyệt là bất biến | 05 | Âm, Bảo mật | P1 | API, IT |
| TC-04-032 | Tạo phiên bản mới khi đã có phiên bản mở | 05 | Dương, Âm | P1 | API |
| TC-04-033 | Hai người cùng sửa: phát hiện, xung đột, gộp ba bên | 05 | Dương | P1 | E2E |
| TC-04-034 | Mất kết nối khi đang soạn, khôi phục phiên nháp | 05 | Khả dụng | P2 | E2E |
| TC-04-035 | Phiên soạn hết hạn và catalog đổi khi đang mở | 05 | Biên | P3 | API, E2E |
| TC-04-036 | Lưu nháp trong khoảng đóng băng cả việc soạn | 05 | Âm | P3 | API |
| TC-04-037 | Bảng thành phần chỉ hiện thành phần được phép | 06 | Dương | P1 | E2E, API |
| TC-04-038 | Thao tác sơ đồ bằng chuột | 06 | Dương | P1 | E2E |
| TC-04-039 | Thao tác không hợp lệ trên sơ đồ | 06 | Âm | P2 | E2E |
| TC-04-040 | Cấu hình chặng bằng biểu mẫu sinh từ catalog | 06 | Dương | P1 | E2E, API |
| TC-04-041 | Lược đồ thành phần không có trong catalog | 06 | Âm | P3 | API |
| TC-04-042 | Thành phần đã dùng nhưng sau đó bị cấm | 06 | Âm | P2 | E2E |
| TC-04-043 | Quay vòng không sửa giữ nguyên băm | 07 | Dương | P1 | UT, E2E |
| TC-04-044 | Sửa trong YAML phản ánh lên sơ đồ | 07 | Dương, Âm | P1 | E2E |
| TC-04-045 | YAML triển khai không chứa bố cục, bản tin mẫu, ghi chú | 07 | Dương, Bảo mật | P1 | IT, GO |
| TC-04-046 | Nhập YAML thay định nghĩa | 07 | Dương | P2 | API |
| TC-04-047 | Nhập YAML không hợp lệ | 07 | Âm, Bảo mật | P1 | API |
| TC-04-048 | Kiểm tra và xem trước biểu thức | 08 | Dương | P1 | API, E2E |
| TC-04-049 | Biểu thức lỗi | 08 | Âm | P1 | API, E2E |
| TC-04-050 | Chọn kết nối PH-05 thay vì nhập thông tin đăng nhập | 08 | Dương | P1 | E2E, API |
| TC-04-051 | Phát hiện bí mật mọi chỗ trong định nghĩa | 08 | Âm, Bảo mật | P1 | UT, API |
| TC-04-052 | Kết nối không hợp lệ | 08 | Âm | P1 | API |
| TC-04-053 | Ghim bản tin mẫu theo chặng và cảnh báo dữ liệu cá nhân | 08 | Dương, Âm, Bảo mật | P2 | E2E |
| TC-04-054 | Ánh xạ trường, hàm và chuyển mã | 09 | Dương | P1 | E2E, API, RT |
| TC-04-055 | Ánh xạ không hợp lệ | 09 | Âm | P1 | API |
| TC-04-056 | Trường bắt buộc của đích chưa ánh xạ | 09 | Biên | P3 | API |
| TC-04-057 | Soạn Kamelet tự viết và dùng trong luồng | 10 | Dương | P2 | API, E2E |
| TC-04-058 | Kamelet sai | 10 | Âm | P2 | API |
| TC-04-059 | Soạn Pipe | 10 | Dương, Âm | P3 | API, E2E |
| TC-04-060 | Bean khai báo và cấu hình cấp tệp | 10 | Dương, Âm | P3 | API, E2E |
| TC-04-061 | Ghi chú dán và luồng con | 10 | Dương | P3 | E2E |
| TC-04-062 | Ma trận mức nghiêm trọng theo mức kiểm tra | 11 | Dương | P1 | UT |
| TC-04-063 | Chín chặng chuẩn với luồng đối ngoại và nội bộ | 11 | Âm | P1 | API |
| TC-04-064 | Trùng mã route, trùng đường dẫn HTTP | 11 | Âm | P1 | API |
| TC-04-065 | Topic chưa đăng ký hoặc không có quyền | 11 | Âm | P1 | API |
| TC-04-066 | Thiếu xử lý lỗi và DLQ | 11 | Âm | P1 | API |
| TC-04-067 | Đặt tiêu đề tenant sai chỗ | 11 | Âm, Bảo mật | P1 | API |
| TC-04-068 | Thành phần nguy hiểm và chỉ chạy JVM | 11 | Âm, Bảo mật | P1 | API |
| TC-04-069 | HTTT đích chưa kết nạp và catalog cũ | 11 | Âm | P2 | API |
| TC-04-070 | Kiểm tra trình duyệt và máy chủ cho cùng kết quả | 11 | Dương | P2 | UT |
| TC-04-071 | Chạy thử MOCK đạt | 12 | Dương | P1 | API, E2E |
| TC-04-072 | Chạy thử không đạt và chặng lỗi | 12 | Âm | P1 | API, E2E |
| TC-04-073 | Chạy thử với định nghĩa lỗi, kết nối thiếu TEST, bản tin lớn | 12 | Âm | P1 | API |
| TC-04-074 | Quá thời gian và chặng treo | 12 | Biên | P2 | API |
| TC-04-075 | Hạn mức chạy thử đồng thời | 12 | Biên | P2 | API |
| TC-04-076 | Hủy lần chạy thử | 12 | Dương, Âm | P3 | API |
| TC-04-077 | Sandbox không sẵn sàng và chế độ mô phỏng | 12 | Khả dụng | P1 | API |
| TC-04-078 | Nhật ký chạy thử: xem lại, so sánh, dọn | 12 | Dương | P2 | API, E2E |
| TC-04-079 | Chạy thử SANDBOX_LIVE gọi đích TEST | 12 | Dương | P2 | API |
| TC-04-080 | Tạo ca kiểm thử và chạy tất cả | 13 | Dương | P2 | API, E2E |
| TC-04-081 | Ca kiểm thử sai và kết quả cũ hết hiệu lực | 13 | Âm | P2 | API |
| TC-04-082 | Gửi duyệt thành công | 14 | Dương | P1 | API, E2E |
| TC-04-083 | Gửi duyệt khi chưa chạy thử đạt trên đúng băm | 14 | Âm | P1 | API |
| TC-04-084 | Lần chạy mô phỏng không được tính | 14 | Âm, Bảo mật | P1 | API, IT |
| TC-04-085 | Gửi duyệt sai trạng thái, thiếu ghi chú, còn lỗi | 14 | Âm | P1 | API |
| TC-04-086 | Rút lại yêu cầu duyệt | 14 | Dương | P2 | API |
| TC-04-087 | Phiên bản đã gửi duyệt không sửa được qua mọi kênh | 14 | Âm, Bảo mật | P1 | API |
| TC-04-088 | Duyệt phiên bản | 15 | Dương | P1 | API, E2E |
| TC-04-089 | Yêu cầu sửa có ý kiến theo chặng | 15 | Dương | P1 | API, E2E |
| TC-04-090 | Gửi duyệt lại sau khi sửa | 15 | Dương | P2 | API |
| TC-04-091 | Tự duyệt bị chặn với người tạo, người đóng góp, người gửi | 15 | Âm, Bảo mật | P1 | API |
| TC-04-092 | Duyệt khi chưa xem so sánh, thiếu checklist, sai trạng thái | 15 | Âm | P1 | API |
| TC-04-093 | Duyệt bởi người ngoài không gian hoặc thiếu quyền | 15 | Âm, Bảo mật | P1 | API |
| TC-04-094 | Xác thực lại khi duyệt | 15 | Bảo mật | P2 | API, E2E |
| TC-04-095 | So sánh hai phiên bản bất kỳ | 15 | Dương | P1 | API, E2E |
| TC-04-096 | Phát hành lên TEST tới SYNCED | 16 | Dương | P1 | API, GO, E2E |
| TC-04-097 | Nâng TEST → STAGING → PROD theo thứ tự | 16 | Dương | P1 | API, GO |
| TC-04-098 | Sai thứ tự môi trường, chưa ổn định | 16 | Âm | P1 | API |
| TC-04-099 | Chỉ phiên bản đã duyệt được phát hành | 16 | Âm, Bảo mật | P1 | API, GO |
| TC-04-100 | Lỗi ghi Git | 16 | Âm, Khả dụng | P1 | API, GO |
| TC-04-101 | Quá hạn đồng bộ | 16 | Âm | P2 | GO |
| TC-04-102 | Phát hành trong khoảng đóng băng, không có hồ sơ runtime | 16 | Âm | P1 | API |
| TC-04-103 | Lệch băm sau khi đồng bộ | 16 | Bảo mật | P2 | GO |
| TC-04-104 | Quay lui PROD về phiên bản trước | 17 | Dương | P1 | API, GO |
| TC-04-105 | Quay lui trong khoảng đóng băng | 17 | Dương | P2 | API |
| TC-04-106 | Quay lui về phiên bản dùng thành phần nay bị cấm, thiếu lý do | 17 | Âm | P1 | API |
| TC-04-107 | Gợi ý quay lui khi tỷ lệ lỗi tăng | 17 | Dương | P3 | E2E |
| TC-04-108 | Tạm dừng một route ở PROD | 18 | Dương | P1 | API, GO |
| TC-04-109 | Tiếp tục route | 18 | Dương | P1 | API |
| TC-04-110 | Dừng khẩn đi trước Git | 18 | Dương | P1 | API, GO |
| TC-04-111 | Đối soát hoàn tất | 18 | Dương | P1 | GO |
| TC-04-112 | Một bản sao không xác nhận, gửi lại | 18 | Âm, Khả dụng | P1 | API, Chaos |
| TC-04-113 | Lệnh có chữ ký sai | 18 | Bảo mật | P1 | IT |
| TC-04-114 | Lệnh hết hạn và lệnh phát lại | 18 | Bảo mật | P1 | IT |
| TC-04-115 | Lệnh mang tenant khác hoặc luồng không tồn tại | 18 | Bảo mật | P1 | IT |
| TC-04-116 | Lệnh thiếu lý do, sai quyền, môi trường chưa triển khai | 18 | Âm | P1 | API |
| TC-04-117 | Tiếp tục sau dừng khẩn chỉ SO hoặc TA | 18 | Âm | P2 | API |
| TC-04-118 | Tình trạng runtime theo môi trường và bản sao | 19 | Dương | P1 | API, E2E |
| TC-04-119 | Lỗi nạp luồng hiển thị cho người vận hành | 19 | Âm | P2 | GO |
| TC-04-120 | Điểm kết nối và số liệu theo điểm | 19 | Dương, Âm | P2 | API |
| TC-04-121 | Số liệu và lịch sử khi PH-13 không sẵn sàng | 19 | Dương, Âm | P2 | API |
| TC-04-122 | Bản tin hợp lệ đi qua đủ chín chặng | 20 | Dương | P1 | RT, API |
| TC-04-123 | Sai lược đồ và vượt kích thước | 20 | Âm | P1 | RT, API |
| TC-04-124 | OPA từ chối hoặc không trả lời | 20 | Âm, Bảo mật | P1 | RT |
| TC-04-125 | Lỗi chuyển đổi và làm giàu | 20 | Âm | P1 | RT |
| TC-04-126 | Che dữ liệu cá nhân ở phản hồi và log | 20 | Dương, Âm, Bảo mật | P1 | RT, IT |
| TC-04-127 | Đích quá thời gian, lỗi, ngắt mạch | 20 | Dương, Âm, Khả dụng | P1 | RT |
| TC-04-128 | Đường dẫn không khớp route | 20 | Âm | P3 | RT |
| TC-04-129 | Lỗi nội bộ không lộ chi tiết | 20 | Âm, Bảo mật | P2 | RT |
| TC-04-130 | SOAP qua hồ sơ JVM | 20 | Dương | P2 | RT |
| TC-04-131 | Nhận sự kiện Kafka, chuyển CDM, phát sự kiện | 21 | Dương | P1 | RT |
| TC-04-132 | Bản tin lỗi vào DLQ | 21 | Âm | P1 | RT |
| TC-04-133 | Chống trùng bản tin | 21 | Dương, Âm | P1 | RT |
| TC-04-134 | Topic không có quyền ở runtime | 21 | Bảo mật | P1 | RT, IT |
| TC-04-135 | Đọc theo lịch với tham số hóa | 22 | Dương | P1 | RT, IT |
| TC-04-136 | Chính sách SQL chặn câu ghi và câu nguy hiểm | 22 | Âm, Bảo mật | P1 | UT, API |
| TC-04-137 | Kết nối không phải chỉ đọc | 22 | Âm, Bảo mật | P1 | API, RT |
| TC-04-138 | Quá thời gian, vượt số dòng | 22 | Biên | P2 | RT |
| TC-04-139 | Mọi API đọc theo mã trùng giữa hai tenant | 23 | Bảo mật | P1 | API |
| TC-04-140 | RLS chặn ở CSDL kể cả khi ứng dụng sai | 23 | Bảo mật | P1 | IT |
| TC-04-141 | Bản tin mang tiêu đề tenant giả | 23 | Dương, Âm, Bảo mật | P1 | RT |
| TC-04-142 | Runtime, topic, kho cấu hình tách theo tenant | 23 | Bảo mật | P1 | GO, IT |
| TC-04-143 | Ma trận vai trò × thao tác | 24 | Dương, Âm, Bảo mật | P1 | API |
| TC-04-144 | Quyền đối tượng không lộ qua danh sách và tìm kiếm | 24 | Bảo mật | P1 | API |
| TC-04-145 | Giao diện ẩn và giải thích hành động bị khóa | 24 | Dương | P2 | E2E |
| TC-04-146 | Đề xuất cho phép thành phần và quyết định | 25 | Dương | P2 | API, E2E |
| TC-04-147 | Tỉnh chỉ thu hẹp được chính sách | 25 | Âm, Bảo mật | P1 | API, IT |
| TC-04-148 | Khớp phiên bản catalog với runtime | 25 | Dương, Âm | P1 | API, CI |
| TC-04-149 | Nâng catalog: luồng soạn trên catalog cũ | 25 | Âm | P2 | API |
| TC-04-150 | Ảnh native khởi động và nạp luồng | 25 | Hiệu năng | P2 | CI |
| TC-04-151 | Chuyển gói XML ba route | 26 | Dương | P1 | API, E2E |
| TC-04-152 | Tệp XML không hợp lệ hoặc nguy hiểm | 26 | Âm, Bảo mật | P1 | API |
| TC-04-153 | Đọc tham số và đặt khoảng đóng băng | 27 | Dương | P2 | API, E2E |
| TC-04-154 | Tham số ngoài miền và ràng buộc không tắt được | 27 | Âm | P2 | API |
| TC-04-155 | Biến môi trường không chứa bí mật | 27 | Dương, Âm | P2 | API |
| TC-04-156 | Outbox ghi cùng giao dịch, không phát khi lỗi | 28 | Dương, Âm | P1 | IT |
| TC-04-157 | Lược đồ mọi sự kiện khớp AsyncAPI | 28 | Dương | P2 | IT |
| TC-04-158 | Hợp đồng OpenAPI khớp máy chủ | 28 | Dương | P1 | API, CI |
| TC-04-159 | Mở bảng thành phần với toàn bộ catalog | 29 | Hiệu năng | P2 | k6 |
| TC-04-160 | Gõ tìm trong bảng thành phần | 29 | Hiệu năng | P2 | k6 |
| TC-04-161 | Kéo chặng trên sơ đồ 200 chặng | 29 | Hiệu năng | P2 | k6 |
| TC-04-162 | Mở trình thiết kế với luồng 200 chặng | 29 | Hiệu năng | P2 | k6 |
| TC-04-163 | Sinh lại YAML sau một thay đổi | 29 | Hiệu năng | P2 | k6 |
| TC-04-164 | Mở cửa sổ cấu hình chặng 154 thuộc tính | 29 | Hiệu năng | P2 | k6 |
| TC-04-165 | Kiểm tra hợp lệ mức SUBMIT | 29 | Hiệu năng | P1 | k6 |
| TC-04-166 | Chạy thử MOCK luồng chín chặng | 29 | Hiệu năng | P1 | k6 |
| TC-04-167 | Từ nâng PROD tới SYNCED | 29 | Hiệu năng | P1 | k6 |
| TC-04-168 | Lệnh tạm dừng tới đủ xác nhận | 29 | Hiệu năng | P1 | k6 |
| TC-04-169 | Độ trễ thêm của khung chín chặng | 29 | Hiệu năng | P1 | k6 |
| TC-04-170 | Thông lượng một vCPU runtime native | 29 | Hiệu năng | P1 | k6 |
| TC-04-171 | Khởi động pod runtime native | 29 | Hiệu năng | P1 | k6 |
| TC-04-172 | Danh sách luồng với 300 luồng mỗi tenant | 29 | Hiệu năng | P2 | k6 |
| TC-04-173 | Quét động có xác thực | 30 | Bảo mật | P1 | ZAP |
| TC-04-174 | Chèn mã qua nội dung luồng và hiển thị | 30 | Bảo mật | P1 | E2E, API |
| TC-04-175 | Biểu thức không thoát được khỏi sandbox | 30 | Bảo mật | P1 | API, RT |
| TC-04-176 | Lệnh điều khiển chỉ từ control plane | 30 | Bảo mật | P1 | IT |
| TC-04-177 | Chuỗi cung ứng ảnh và kho cấu hình | 30 | Bảo mật | P2 | CI |
| TC-04-178 | Giới hạn tần suất API điều khiển | 30 | Bảo mật | P3 | k6 |
| TC-04-179 | Mất control plane không ảnh hưởng data plane | 31 | Khả dụng | P1 | Chaos |
| TC-04-180 | Mất một bản sao runtime | 31 | Khả dụng | P1 | Chaos |
| TC-04-181 | Mất Kafka tạm thời | 31 | Khả dụng | P2 | Chaos |
| TC-04-182 | Git không sẵn sàng khi đang có lệnh khẩn | 31 | Khả dụng | P2 | Chaos, GO |
| TC-04-183 | Tạo luồng ba chặng chỉ bằng bàn phím | 32 | Truy cập | P1 | E2E, Thủ công |
| TC-04-184 | Quét axe-core trên mọi màn UI-04 | 32 | Truy cập | P1 | E2E |
| TC-04-185 | Bề rộng màn hình | 32 | Truy cập | P2 | E2E |
| TC-04-186 | Phóng to 200% và giảm chuyển động | 32 | Truy cập | P3 | E2E, Thủ công |
| TC-04-187 | Trạng thái màn Không gian làm việc | 01 | Dương, Âm | P3 | E2E |
| TC-04-188 | Trạng thái màn Thư viện khuôn mẫu | 03 | Dương, Âm | P3 | E2E |
| TC-04-189 | Sandbox không sẵn sàng khi xem trước biểu thức | 08 | Âm, Khả dụng | P2 | E2E, API |
| TC-04-190 | Sandbox không sẵn sàng khi xem trước ánh xạ | 09 | Âm, Khả dụng | P2 | E2E, API |
| TC-04-191 | Trạng thái màn và câu chặn của Trình soạn Pipe | 10 | Dương, Âm | P2 | E2E |
| TC-04-192 | Đầu cuối một lần chạy thử MOCK theo trình tự SDD | 12 | Dương | P1 | IT, E2E |
| TC-04-193 | Đầu cuối gửi duyệt và duyệt bốn mắt theo trình tự SDD | 15 | Dương, Âm | P1 | API, IT |
| TC-04-194 | Trạng thái màn So sánh phiên bản | 15 | Dương, Âm | P3 | E2E |
| TC-04-195 | Phát hành khi kiểm tra mức PUBLISH còn lỗi hoặc catalog cũ | 16 | Âm | P1 | API, E2E |
| TC-04-196 | Đầu cuối phát hành lên PROD tới SYNCED theo trình tự SDD | 16 | Dương | P1 | GO |
| TC-04-197 | Đầu cuối dừng khẩn ở PROD theo trình tự SDD | 18 | Dương | P1 | GO, RT |
| TC-04-198 | Gọi đồng bộ khi luồng hoặc route đang tạm dừng | 20 | Âm | P1 | RT, API |
| TC-04-199 | Lỗi nghiệp vụ, dữ liệu ở luồng bất đồng bộ vào DLQ không thử lại | 21 | Âm | P1 | RT |
| TC-04-200 | Trạng thái màn Danh mục thành phần | 25 | Dương, Âm | P3 | E2E |
| TC-04-201 | Trạng thái màn Nhập luồng hệ cũ | 26 | Dương, Âm | P3 | E2E |
| TC-04-202 | Di trú dữ liệu W2 khi schema do tài khoản khác sở hữu | 28 | Dương, Biên | P1 | IT |

: Danh sách test case
<!--/gen-->

## 4. Kịch bản và test case chức năng

Chương này đặc tả các ca chức năng theo 28 kịch bản, theo thứ tự vòng đời của luồng: không gian làm việc, tạo và soạn, kiểm tra, chạy thử, duyệt, phát hành, vận hành, rồi data plane và các mặt xuyên suốt (tenant, phân quyền, catalog, sự kiện). Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ; mỗi ca là một khối đặc tả theo mục 1.6.

### TS-04-01 · Không gian làm việc và thành viên

**Mục tiêu.** Xác nhận không gian làm việc giới hạn đúng quyền sửa, duyệt theo thành viên khi `04.workspace.enforce` bật, và không ảnh hưởng khi tắt. Đây là sự kế thừa `Project`, `Project_group.access_level` của Bus cũ (LGC-BUS-032).

**Phủ.** FR-04-007; BR-04-021; UC-04-01; API-04-001…004; UI-04-21; ERR-04-017, 027, 028.

**Tiền điều kiện chung.** Bộ dữ liệu mục 2 đã nạp; `04.workspace.enforce = true`.

#### TC-04-001 · Liệt kê, tạo và sửa không gian làm việc <!--k:ws-crud-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-007 · API-04-001, 002 · UI-04-21 · UC-04-01 · LGC-BUS-032.

**Tiền điều kiện, dữ liệu.** Người gọi U-T68-TA.

**Các bước.**

1. Gọi `GET /workspaces`.
2. Gọi `POST /workspaces` với `{"code":"tc-thue","name":"Thuế (thử)"}` và `Idempotency-Key`.
3. Gửi lại bước 2 cùng khóa, cùng thân.
4. Gọi `PATCH /workspaces/tc-thue` với `If-Match` từ bước 2, đổi `name`.

**Kết quả mong đợi.** Bước 1 trả `200` với WS-HOTICH, WS-DATDAI, WS-ARCH (trạng thái `ARCHIVED`) và DEFAULT; mỗi phần tử có `flowCount`, `allowedActions`. Bước 2 trả `201`. Bước 3 trả lại đúng phản hồi bước 2, không tạo bản ghi thứ hai. Bước 4 trả `200`, `ETag` mới. KT: có (`INT_WORKSPACE_CREATE`, `INT_WORKSPACE_UPDATE`).
:::

#### TC-04-002 · Tạo không gian trùng mã, sửa không gian không tồn tại <!--k:ws-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-007 · API-04-002 · ERR-04-027, 028.

**Tiền điều kiện, dữ liệu.** U-T68-TA.

**Các bước.**

1. Gọi `POST /workspaces` với `code = "ho-tich"`.
2. Gọi `PATCH /workspaces/khong-co` có `If-Match`.
3. U-T68-IE1 gọi `POST /workspaces` với mã mới.

**Kết quả mong đợi.** Bước 1 trả `409` ERR-04-028. Bước 2 trả `404` ERR-04-027. Bước 3 trả 403-PQ (IE không có `PERM-04-admin`). KT: không với bước 1, 2.
:::

#### TC-04-003 · Thay danh sách thành viên và hiệu lực ngay <!--k:ws-members-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-007 · BR-04-021 · API-04-004, 022 · UC-04-01.

**Tiền điều kiện, dữ liệu.** U-T68-IA1 (mức `MAINTAIN` trên WS-HOTICH); F-HT v4 `DRAFT`.

**Các bước.**

1. U-T68-IE3 gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft` với nội dung hợp lệ.
2. U-T68-IA1 gọi `PUT /workspaces/ho-tich/members`, thêm IE3 mức `EDIT`.
3. IE3 lặp bước 1 với `If-Match` mới.

**Kết quả mong đợi.** Bước 1 trả `403` ERR-04-003. Bước 2 trả `200`. Bước 3 trả `200` không cần đăng nhập lại (quyền không gian tra theo yêu cầu, không nằm trong token). KT: có (`INT_WORKSPACE_MEMBERS` ghi danh sách thêm, bớt).
:::

#### TC-04-004 · Thành viên mức VIEW và người ngoài không gian <!--k:ws-scope-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-007, 010 · BR-04-021 · API-04-010, 012, 022 · ERR-04-003.

**Tiền điều kiện, dữ liệu.** U-T68-VW (VIEW trên WS-HOTICH), U-T68-IE3 (chỉ WS-DATDAI).

**Các bước.**

1. VW gọi `GET /flows/tra-cuu-ho-tich`.
2. VW gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft`.
3. IE3 gọi `GET /flows?workspace=ho-tich`.
4. IE3 gọi `GET /flows/tra-cuu-ho-tich`.

**Kết quả mong đợi.** Bước 1 trả `200`, `allowedActions` không có `EDIT`, `disabledReasons.EDIT` nêu "chỉ có quyền xem trong không gian Hộ tịch". Bước 2 trả `403` ERR-04-003. Bước 3 trả `200` với `items` rỗng, lọc ở SQL chứ không ở ứng dụng (kiểm bằng log câu lệnh ở IT). Bước 4 trả 404-ẩn.
:::

#### TC-04-005 · Tắt giới hạn không gian làm việc <!--k:ws-off-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-007, 084 · BR-04-021.

**Tiền điều kiện, dữ liệu.** U-T68-TA đặt `04.workspace.enforce = false` qua PH-18.

**Các bước.**

1. IE3 gọi lại bước 2 của TC ở trên với F-HT v4.
2. TA bật lại tham số; IE3 gọi lại.

**Kết quả mong đợi.** Bước 1 trả `200` (chỉ quyền chức năng có hiệu lực). Bước 2 trả `403` ERR-04-003 trong vòng 60 giây sau khi bật (bộ đệm tham số).
:::

#### TC-04-006 · Lưu trữ không gian còn luồng <!--k:ws-archive-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-04-007 · API-04-003, 011 · ERR-04-017, 027 · UI-04-03.

**Tiền điều kiện, dữ liệu.** U-T68-TA; không gian `tc-thue` (từ ca đầu) có một luồng nháp.

**Các bước.**

1. Gọi `POST /workspaces/tc-thue:archive`.
2. IE1 mở UI-04-03 bước 1, mở ô "Không gian làm việc".
3. IE1 gọi `POST /flows` với `workspaceCode = "tc-thue"`.

**Kết quả mong đợi.** Bước 1 trả `200`, `status = ARCHIVED`, luồng cũ vẫn xem được. Bước 2 không có `tc-thue` trong danh sách. Bước 3 trả `409` ERR-04-005 với `detail` "Không gian làm việc đã lưu trữ". KT: có (`INT_WORKSPACE_ARCHIVE`).
:::

#### TC-04-187 · Trạng thái màn Không gian làm việc <!--k:ui-ws-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-007 · UI-04-21 · ERR-04-017, 027, 028, 045.

**Tiền điều kiện, dữ liệu.** U-T68-TA; tenant T90 chưa có không gian nào ngoài DEFAULT; U-T68-IE1.

**Các bước.**

1. TA ở T90 mở UI-04-21.
2. TA ở T68 mở UI-04-21, giả lập API-04-001 chậm 2 giây rồi trả `500`.
3. TA bấm "Lưu trữ" ở không gian `ho-tich` (còn luồng).
4. IE1 mở thẳng URL của UI-04-21.

**Kết quả mong đợi.** Bước 1: trạng thái rỗng "Tỉnh chưa có không gian làm việc nào. Tạo không gian để giới hạn ai sửa luồng nào." kèm nút "Tạo không gian"; phím `N` mở biểu mẫu tạo. Bước 2: skeleton 6 dòng trong lúc chờ, sau đó ST-05 có mã truy vết. Bước 3: hộp thoại nêu ERR-04-017 và số luồng còn lại, không gian không đổi trạng thái. Bước 4: mục menu không hiện với IE1; vào bằng URL nhận ST-06 (ERR-04-045). Dải thông báo "Giới hạn theo không gian làm việc đang bật" hiện khi `04.workspace.enforce = true`.
:::

### TS-04-02 · Danh sách, tìm kiếm, chi tiết luồng

**Mục tiêu.** Thay màn danh sách chương trình tích hợp và các ô tìm theo endpoint, nguồn, tên, host của Bus cũ.

**Phủ.** FR-04-001, 002; UC-04-02; API-04-010, 012, 016; UI-04-01, 02; ERR-04-001, 026, 049; LGC-BUS-001…008, 017, 018.

#### TC-04-007 · Liệt kê luồng có lọc, đếm theo trạng thái <!--k:list-flows-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-001 · API-04-010 · UI-04-01 · LGC-BUS-001, 003, 004, 005.

**Tiền điều kiện, dữ liệu.** T68 có F-HT, F-DD, F-SQL, F-SOAP, F-KAM; người gọi U-T68-TA.

**Các bước.**

1. Gọi `GET /flows?limit=25`.
2. Gọi `GET /flows?status=ACTIVE&environment=PROD`.
3. Gọi `GET /flows?q=ho tich` (không dấu).
4. Gọi `GET /flows?resourceKind=KAMELET`.
5. Gọi `GET /flows?label=nguon:bhxh`.

**Kết quả mong đợi.** Bước 1 trả `200` với 5 luồng, sắp `-updatedAt`, `facets.status` đếm đúng, không có F-T01. Bước 2 trả F-HT, F-DD, F-SOAP. Bước 3 trả F-HT. Bước 4 trả F-KAM. Bước 5 trả F-SOAP. Mỗi phần tử có `environments[]` với `syncStatus`, `healthStatus`, `openVersionNo`. KT: không.
:::

#### TC-04-008 · Tìm theo endpoint <!--k:list-endpoint-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-001 · API-04-010 · LGC-BUS-002.

**Tiền điều kiện, dữ liệu.** F-HT có điểm vào `platform-http:/ho-tich/tra-cuu` và điểm ra qua CONN-HT.

**Các bước.**

1. Gọi `GET /flows?endpoint=/ho-tich/`.
2. Gọi `GET /flows?endpoint=CONN-HT`.
3. Gọi `GET /flows?endpoint=password` (chuỗi không nằm trong URI đã che).

**Kết quả mong đợi.** Bước 1, 2 trả F-HT. Bước 3 trả rỗng. Chỉ mục EN-04-04b chỉ chứa URI đã che tham số nhạy cảm.
:::

#### TC-04-009 · Tham số danh sách không hợp lệ <!--k:list-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-001 · API-04-010 · ERR-04-026, 049.

**Tiền điều kiện, dữ liệu.** U-T68-VW.

**Các bước.**

1. Gọi `GET /flows?limit=100`.
2. Gọi `GET /flows?limit=101`.
3. Gọi `GET /flows?status=RUNNING`.
4. Gọi `GET /flows?sort=drop`.
5. Gọi `GET /flows?q=a` (1 ký tự).
6. Gọi `GET /flows?cursor=abc` (con trỏ giả).

**Kết quả mong đợi.** Bước 1 trả `200`. Bước 2 trả `400` ERR-04-026. Bước 3, 4, 5, 6 trả `400` ERR-04-049 có `errors[].path` chỉ tham số sai, không lộ chi tiết SQL hay ngăn xếp.
:::

#### TC-04-010 · Chi tiết luồng đầy đủ <!--k:flow-detail-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-002 · API-04-012, 024, 054, 060 · UI-04-02 · LGC-BUS-006, 008, 017, 018.

**Tiền điều kiện, dữ liệu.** F-HT; người gọi U-T68-VW.

**Các bước.**

1. Gọi `GET /flows/tra-cuu-ho-tich`.
2. Mở UI-04-02, lần lượt các tab Tổng quan, Sơ đồ (chỉ đọc), YAML, Phiên bản, Triển khai, Điểm kết nối, Lịch sử.

**Kết quả mong đợi.** Bước 1 trả `200`, `ETag`, `routes[]` có `routeId`, `fromUri`, `stepCount`; `environments` có ba môi trường đều v3. Bước 2: sơ đồ hiện chín khối chặng chuẩn; YAML chỉ đọc; tab Lịch sử ẩn cột "trước/sau" với VW. Không nút nào ngoài "Xem", "Tải YAML".
:::

#### TC-04-011 · Chi tiết luồng không tồn tại hoặc ở tenant khác <!--k:flow-404-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-002 · API-04-012 · ERR-04-001.

**Tiền điều kiện, dữ liệu.** U-T68-VW; F-T01 chỉ có ở T01.

**Các bước.**

1. Gọi `GET /flows/khong-co`.
2. U-T01-IE tạo luồng `tc-chi-t01`; U-T68-VW gọi `GET /flows/tc-chi-t01`.

**Kết quả mong đợi.** Cả hai trả `404` ERR-04-001, thân giống nhau trừ `traceId` (không phân biệt được tồn tại hay không).
:::

#### TC-04-012 · Phụ thuộc của luồng <!--k:deps-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-002, 006 · API-04-016.

**Tiền điều kiện, dữ liệu.** F-HT được API `ho-tich-tra-cuu` của PH-02 dùng (stub), được ca kiểm thử của chính nó dùng, và F-DD gọi `direct:` tới nó (giả lập).

**Các bước.**

1. Gọi `GET /flows/tra-cuu-ho-tich/dependencies`.

**Kết quả mong đợi.** `200`; `hard` có `API` (PH-02) và `FLOW` (F-DD); `soft` có `TEST_CASE`. PH-02 không trả lời trong 5 giây thì `503` ERR-04-047, không trả danh sách thiếu.
:::

### TS-04-03 · Tạo luồng từ luồng trống, khuôn, API, YAML

**Mục tiêu.** Xác nhận bốn nguồn tạo luồng, ràng buộc mã, và việc tạo luồng chỉ sinh phiên bản 1 `DRAFT`, không chạm runtime.

**Phủ.** FR-04-003, 025; BR-04-001, 002, 003; UC-04-03; API-04-011, 031, 080, 081; UI-04-03, 19; ERR-04-002, 008, 009, 010, 018, 027, 033, 039; EVT-04-01; LGC-BUS-013, LGC-TOOL-001.

#### TC-04-013 · Tạo luồng trống <!--k:create-blank-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-003 · API-04-011 · UI-04-03 · UC-04-03 · EVT-04-01 · LGC-BUS-013.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; mã `tc-trong`.

**Các bước.**

1. Gọi `POST /flows` với `{"code":"tc-trong","name":"Thử luồng trống","workspaceCode":"ho-tich","resourceKind":"ROUTE","origin":"BLANK"}` và `Idempotency-Key`.
2. Gọi `GET /flows/tc-trong/versions/1`.
3. Đếm commit trên kho `dh-flows-t68`.

**Kết quả mong đợi.** Bước 1 trả `201`, `ETag`, `status = DRAFT`, `openVersionNo = 1`. Bước 2: YAML có khung chín chặng rỗng với `routeConfigurationId: dh-default-config`, `catalogVersion` bằng catalog hiện hành. Bước 3: Git: không. EVT-04-01 trong outbox cùng giao dịch, khóa `T68:{flowId}`. KT: có (`INT_FLOW_CREATE`).
:::

#### TC-04-014 · Tạo luồng từ khuôn có tham số <!--k:create-template-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-003, 025 · API-04-080, 081, 011 · UI-04-19 · UC-04-03.

**Tiền điều kiện, dữ liệu.** TPL-REST.

**Các bước.**

1. Gọi `GET /templates?resourceKind=ROUTE`.
2. Gọi `GET /templates/tpl-rest-proxy-9-chang`.
3. Gọi `POST /flows` với `origin = TEMPLATE`, `templateCode`, `templateParams = {"path":"/tc/khuon","connection":"CONN-HT","schemaRef":"hotich-yeucau-v1"}`.

**Kết quả mong đợi.** Bước 1 có TPL-REST, `scope = PLATFORM`. Bước 3 trả `201`; YAML có `path: /tc/khuon`, tham chiếu `{{conn:CONN-HT}}`; bố cục lấy `previewLayout` của khuôn. `origin = TEMPLATE`, `templateCode` lưu ở luồng.
:::

#### TC-04-015 · Tạo luồng từ OpenAPI của API công bố <!--k:create-openapi-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-003 · API-04-011.

**Tiền điều kiện, dữ liệu.** PH-02 stub trả OpenAPI có 3 operation.

**Các bước.**

1. Gọi `POST /flows` với `origin = OPENAPI`, `apiRef = "ho-tich-tra-cuu"`.

**Kết quả mong đợi.** `201`; YAML có khối `rest` với 3 operation, mỗi operation một route `direct:` có khung chín chặng; `transport = SYNC`, `exposure = EXTERNAL`.
:::

#### TC-04-016 · Tạo luồng từ tệp YAML <!--k:create-yaml-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-003, 027 · API-04-031, 011.

**Tiền điều kiện, dữ liệu.** YAML-OK đổi mã route và đường dẫn sang `tc-`.

**Các bước.**

1. Gọi `POST /validation:check` với YAML.
2. Gọi `POST /flows` với `origin = YAML_FILE`, `yaml`.

**Kết quả mong đợi.** Bước 1 trả `200`, `errorCount = 0`, không ghi gì (EVT: không). Bước 2 trả `201`; băm chuẩn hóa của định nghĩa đã lưu bằng băm chuẩn hóa của tệp tải lên.
:::

#### TC-04-017 · Mã luồng sai định dạng hoặc trùng <!--k:create-code-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-003 · BR-04-001 · API-04-011 · ERR-04-002, 049.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; luồng `tc-da-go` đã gỡ 10 ngày trước; luồng `tc-go-cu` đã gỡ 31 ngày trước.

**Các bước.**

1. Tạo với `code = "tra-cuu-ho-tich"`.
2. Tạo với `code = "Tra_Cuu"`, `"ab"`, chuỗi 64 ký tự.
3. Tạo với `code = "tc-da-go"`.
4. Tạo với `code = "tc-go-cu"`.

**Kết quả mong đợi.** Bước 1, 3 trả `409` ERR-04-002. Bước 2 trả `400` ERR-04-049 (mẫu `^[a-z][a-z0-9-]{2,62}$`). Bước 4 trả `201` (mã giải phóng sau 30 ngày). Mã trùng với F-T01 ở T01 không bị chặn ở T68 (đã có ở dữ liệu).
:::

#### TC-04-018 · Tạo luồng với nội dung không hợp lệ <!--k:create-content-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-003 · BR-04-003 · API-04-011 · ERR-04-008, 009, 010, 027, 033, 039.

**Tiền điều kiện, dữ liệu.** YAML-SECRET, YAML-BIG; YAML cú pháp hỏng; YAML Kamelet nhưng `resourceKind = ROUTE`.

**Các bước.**

1. Tạo `origin = YAML_FILE` với YAML cú pháp hỏng.
2. Tạo với YAML Kamelet, `resourceKind = ROUTE`.
3. Tạo với YAML-SECRET.
4. Tạo với YAML-BIG.
5. Tạo với `workspaceCode = "khong-co"`.
6. Tạo `origin = TEMPLATE` với `templateCode = "tpl-khong-co"`.

**Kết quả mong đợi.** Lần lượt `422` ERR-04-008 (có dòng, cột), `422` ERR-04-009, `422` ERR-04-010 (`findings[].path` trỏ tới URI, `message` không chứa `Abc@12345678`), `413` ERR-04-033, `404` ERR-04-027, `404` ERR-04-039. Không bản ghi nào được tạo. EVT: không.
:::

#### TC-04-019 · Chống trùng khi tạo luồng <!--k:create-idem-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-003 · API-04-011 · ERR-04-018.

**Tiền điều kiện, dữ liệu.** Khóa `tc-idem-0000000001`.

**Các bước.**

1. Tạo `tc-idem` với khóa.
2. Gửi lại cùng khóa, cùng thân.
3. Gửi cùng khóa, đổi `name`.
4. Gửi không có `Idempotency-Key`.
5. Gửi khóa 15 ký tự.

**Kết quả mong đợi.** Bước 2 trả lại phản hồi `201` đã lưu. Bước 3 trả `409` ERR-04-018. Bước 4 trả `400` ERR-04-049. Bước 5 trả `400` ERR-04-049. Chỉ một luồng được tạo.
:::

#### TC-04-020 · Bắt buộc căn cứ pháp lý cho luồng đối ngoại <!--k:create-legal-->

::: dac-ta
**Loại.** Âm, Dương.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-04-003, 084 · API-04-011 · UI-04-03.

**Tiền điều kiện, dữ liệu.** `04.flow.require-legal-basis = true`.

**Các bước.**

1. Tạo luồng `origin = OPENAPI` (đối ngoại) không có `legalBasisRef`.
2. Tạo lại có `legalBasisRef = "ND-278-2025"`.

**Kết quả mong đợi.** Bước 1 trả `422` ERR-04-009 với finding "Luồng đối ngoại phải khai căn cứ pháp lý". Bước 2 trả `201`. Trên UI-04-03 ô căn cứ hiện dấu bắt buộc khi tham số bật.
:::

#### TC-04-188 · Trạng thái màn Thư viện khuôn mẫu <!--k:ui-template-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-025 · UI-04-19 · ERR-04-039, 045.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; T68 chưa có khuôn của tỉnh; khuôn `tpl-cu` của tỉnh đã bị gỡ.

**Các bước.**

1. IE1 mở UI-04-19.
2. Lọc nhóm "Tệp" và gõ tìm "khong-co".
3. Mở URL chi tiết của `tpl-cu`.
4. U-T68-VW mở URL của UI-04-19.

**Kết quả mong đợi.** Bước 1: lưới 6 thẻ skeleton rồi đủ tám khuôn nền (`tpl-standard-9`, `tpl-sync-lookup`, …), không có khuôn của tỉnh nhưng không hiện trạng thái rỗng. Bước 2: ST-04 có nút "Xóa bộ lọc". Bước 3: ST-05 với câu "Khuôn mẫu "tpl-cu" không tồn tại hoặc không được phép dùng trong tỉnh." (ERR-04-039). Bước 4: ST-06. Phím `/` đặt con trỏ vào ô tìm; mũi tên chuyển thẻ theo lưới; `Enter` mở chi tiết.
:::

### TS-04-04 · Sửa thông tin, nhân bản, hủy nháp, gỡ luồng

**Mục tiêu.** Xác nhận các thao tác vòng đời luồng ngoài phiên bản: thông tin chung, nhân bản, hủy nháp và gỡ có kiểm tra phụ thuộc, rút khỏi môi trường qua Git.

**Phủ.** FR-04-004, 005, 006; BR-04-001, 011, 017; UC-04-16; API-04-013, 014, 015, 016, 023; ERR-04-003, 005, 006, 007, 017, 025, 034; EVT-04-02, 06, 09; LGC-BUS-010, 011, 012.

#### TC-04-021 · Sửa thông tin luồng <!--k:flow-update-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-004 · API-04-013 · EVT-04-02 · LGC-BUS-006, 011.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; F-HT, `ETag` hiện tại.

**Các bước.**

1. Gọi `PATCH /flows/tra-cuu-ho-tich` với `If-Match`, đổi `name`, thêm nhãn `muc-do:cao`.
2. Gọi `PATCH` có `code` trong thân.

**Kết quả mong đợi.** Bước 1 trả `200`, `ETag` mới; EVT-04-02 có `changedFields = ["name","labels"]`; phiên bản và runtime không đổi (Git: không). Bước 2 trả `400` ERR-04-049 (mã không đổi được, BR-04-001). KT: có (`INT_FLOW_UPDATE` với trước, sau).
:::

#### TC-04-022 · Sửa thông tin luồng: khóa lạc quan và quyền <!--k:flow-update-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-004 · API-04-013 · ERR-04-003, 006, 007.

**Tiền điều kiện, dữ liệu.** IE1, IE3; F-HT.

**Các bước.**

1. IE1 gọi `PATCH` không có `If-Match`.
2. IE1 gọi `PATCH` với ETag cũ.
3. IE1 chuyển luồng sang `workspaceCode = "dat-dai"` (IE1 không có `EDIT` ở WS-DATDAI).
4. IE3 gọi `PATCH` với ETag đúng.

**Kết quả mong đợi.** Bước 1 trả `428` ERR-04-007. Bước 2 trả `412` ERR-04-006 kèm `currentEtag`, `savedBy`, `savedAt`. Bước 3, 4 trả `403` ERR-04-003. Dữ liệu không đổi.
:::

#### TC-04-023 · Nhân bản luồng <!--k:clone-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-005 · BR-04-011 · API-04-014 · UC-04-16 · EVT-04-01.

**Tiền điều kiện, dữ liệu.** F-HT v3; IE1.

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich:clone` với `{"code":"tc-ban-sao","name":"Bản sao","sourceVersionNo":3,"includeTestCases":true}`.
2. Gọi `GET /flows/tc-ban-sao/versions/1`.

**Kết quả mong đợi.** Bước 1 trả `201`, `origin = CLONE`, `clonedFrom = "tra-cuu-ho-tich@3"`. Bước 2: mã route đổi tiền tố thành `tc-ban-sao-…`, đường dẫn HTTP đổi thành `/tc-ban-sao/…` để không vi phạm VR-08, VR-18; ca kiểm thử được sao; bản tin mẫu được sao; người tạo là IE1 (không kế thừa người đóng góp cũ).
:::

#### TC-04-024 · Hủy bản nháp <!--k:discard-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-006 · BR-04-016 · API-04-023, 021.

**Tiền điều kiện, dữ liệu.** F-HT v4 `DRAFT`.

**Các bước.**

1. IE1 gọi `POST /flows/tra-cuu-ho-tich/versions/4:discard` có `If-Match`.
2. Gọi `POST /flows/tra-cuu-ho-tich/versions`.

**Kết quả mong đợi.** Bước 1 trả `200`, `status = DISCARDED`; luồng không còn phiên bản mở. Bước 2 trả `201` phiên bản 5 sao từ v3 (đang chạy PROD). Số 4 không được dùng lại.
:::

#### TC-04-025 · Hủy bản nháp không đúng trạng thái <!--k:discard-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-006 · API-04-023 · ERR-04-005.

**Tiền điều kiện, dữ liệu.** F-HT v3 `APPROVED`; phiên bản đang `PENDING_REVIEW` ở luồng khác.

**Các bước.**

1. Gọi `:discard` trên v3.
2. Gọi `:discard` trên phiên bản `PENDING_REVIEW`.

**Kết quả mong đợi.** Cả hai trả `409` ERR-04-005, `detail` nêu trạng thái hiện tại.
:::

#### TC-04-026 · Gỡ luồng đã phát hành, rút theo thứ tự môi trường <!--k:retire-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-006 · BR-04-017 · API-04-015 · EVT-04-06, 09 · UC-04-16 · LGC-BUS-010, 012.

**Tiền điều kiện, dữ liệu.** Luồng `tc-go` đã chạy ở TEST và PROD, không có phụ thuộc cứng; U-T68-TA.

**Các bước.**

1. Gọi `POST /flows/tc-go:retire` với `{"reason":"Thay bằng luồng mới theo Quyết định thử"}` và `If-Match`.
2. Theo dõi `GET /flows/tc-go/deployments`.

**Kết quả mong đợi.** Bước 1 trả `202`. Hệ thống tạo triển khai `RETIRE` cho PROD trước, rồi tới TEST; mỗi môi trường xóa `flows/tc-go/` khỏi `env/*` (với PROD là merge request). Khi mọi bản sao báo không còn luồng, trạng thái luồng `RETIRED`, EVT-04-09 phát. Gọi tới `POST /tc-go/...` qua APISIX trả `404` ERR-04-111. KT: có (`INT_FLOW_RETIRE` có lý do).
:::

#### TC-04-027 · Gỡ luồng còn phụ thuộc, thiếu lý do <!--k:retire-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-006 · BR-04-017 · API-04-015 · ERR-04-017, 025, 005.

**Tiền điều kiện, dữ liệu.** F-HT có phụ thuộc cứng (ca TC phụ thuộc ở TS-04-02); `tc-go2` đang có lần chạy thử `RUNNING`.

**Các bước.**

1. TA gỡ F-HT có lý do hợp lệ.
2. TA gỡ `tc-go2` với `reason = "gỡ"` (4 ký tự).
3. TA gỡ `tc-go2` với lý do hợp lệ.
4. IE1 gỡ F-HT (luồng đã phát hành, IE không có `PERM-04-publish`).

**Kết quả mong đợi.** Bước 1 trả `409` ERR-04-017 kèm `dependencies`. Bước 2 trả `400` ERR-04-025. Bước 3 trả `409` ERR-04-005 ("đang có lần chạy thử"). Bước 4 trả 403-PQ. Git: không. EVT: không.
:::

#### TC-04-028 · Luồng đã gỡ chỉ đọc <!--k:edit-retired-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-006, 004 · API-04-013, 021 · ERR-04-034.

**Tiền điều kiện, dữ liệu.** `tc-go` đã `RETIRED` (sau ca gỡ).

**Các bước.**

1. Gọi `PATCH /flows/tc-go`.
2. Gọi `POST /flows/tc-go/versions`.
3. Gọi `GET /flows/tc-go`.

**Kết quả mong đợi.** Bước 1, 2 trả `409` ERR-04-034. Bước 3 trả `200` với `retiredAt`, `retireReason`, `allowedActions` chỉ có `VIEW`, `CLONE`.
:::

### TS-04-05 · Phiên bản, lưu nháp, ETag, phiên soạn, gộp ba bên

**Mục tiêu.** Xác nhận vòng đời phiên bản, tính bất biến sau khi gửi duyệt, lưu tự động an toàn khi nhiều người cùng mở, và không mất thay đổi khi xung đột.

**Phủ.** FR-04-010, 011, 024; BR-04-007, 016; UC-04-04; API-04-020, 021, 022, 024, 034; UI-04-04; ERR-04-004, 005, 006, 007, 016, 033, 041.

#### TC-04-029 · Lưu nháp và tính lại băm <!--k:save-draft-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-024, 010 · API-04-020, 022 · BR-04-007.

**Tiền điều kiện, dữ liệu.** F-HT v4 `DRAFT`; IE1 lấy ETag ở `GET /flows/tra-cuu-ho-tich/versions/4`.

**Các bước.**

1. Gọi `PUT .../versions/4/draft` chỉ đổi `canvasLayout` (kéo một chặng).
2. Gọi `PUT .../draft` đổi `samples`.
3. Gọi `PUT .../draft` đổi một thuộc tính trong `definitionYaml`.

**Kết quả mong đợi.** Bước 1, 2 trả `200`, `contentHash` không đổi (bố cục và bản tin mẫu không thuộc YAML). Bước 3 trả `200`, `contentHash` đổi, `validation.level = DESIGN` kèm `findings`. Mỗi bước `ETag` tăng `version`. IE1 có trong `contributors`. KT: không cho từng lần lưu (chỉ mốc gửi duyệt mới kiểm toán), có metric `dh_int_draft_saves_total`.
:::

#### TC-04-030 · Lưu nháp sai điều kiện <!--k:save-draft-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-024 · API-04-022 · ERR-04-004, 006, 007, 033, 008, 010.

**Tiền điều kiện, dữ liệu.** F-HT v4 `DRAFT`.

**Các bước.**

1. Lưu `versions/9` (không tồn tại).
2. Lưu không có `If-Match`.
3. Lưu với YAML-BIG.
4. Lưu với YAML cú pháp hỏng.
5. Lưu với YAML-SECRET.

**Kết quả mong đợi.** Lần lượt `404` ERR-04-004, `428` ERR-04-007, `413` ERR-04-033, `422` ERR-04-008, `422` ERR-04-010. Ở bước 4, 5 nội dung cũ giữ nguyên trên máy chủ; CSDL không có chuỗi `Abc@12345678` ở bất kỳ cột nào (kiểm bằng truy vấn `ILIKE` trên `ph04` ở IT).
:::

#### TC-04-031 · Phiên bản đã gửi duyệt là bất biến <!--k:edit-pending-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-04-011, 040 · BR-04-016 · API-04-022 · ERR-04-005.

**Tiền điều kiện, dữ liệu.** Phiên bản `PENDING_REVIEW` và v3 `APPROVED` của F-HT.

**Các bước.**

1. Gọi `PUT .../draft` trên phiên bản `PENDING_REVIEW` với ETag đúng.
2. Gọi `PUT .../draft` trên v3.
3. Ở IT, dùng vai trò `ph04_app` chạy `UPDATE ph04.flow_version SET definition_yaml = 'x' WHERE status = 'APPROVED'`.

**Kết quả mong đợi.** Bước 1, 2 trả `409` ERR-04-005. Bước 3 bị trigger `tg_flow_version_immutable` từ chối với lỗi SQLSTATE `P0001`; dữ liệu không đổi.
:::

#### TC-04-032 · Tạo phiên bản mới khi đã có phiên bản mở <!--k:new-version-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-011 · BR-04-016 · API-04-021, 024 · ERR-04-016, 004.

**Tiền điều kiện, dữ liệu.** F-DD v1 `APPROVED`, không có phiên bản mở.

**Các bước.**

1. IE2 gọi `POST /flows/dong-bo-dat-dai/versions` với `{}`.
2. IE3 gọi lại.
3. Gọi `POST /flows/tra-cuu-ho-tich/versions` với `baseVersionNo = 99`.
4. Gọi `GET /flows/dong-bo-dat-dai/versions`.

**Kết quả mong đợi.** Bước 1 trả `201` v2 `DRAFT` sao từ v1. Bước 2 trả `409` ERR-04-016 kèm `versionNo = 2` và người tạo. Bước 3 trả `404` ERR-04-004. Bước 4 liệt kê v1, v2 có `environments`.
:::

#### TC-04-033 · Hai người cùng sửa: phát hiện, xung đột, gộp ba bên <!--k:conflict-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-04-024, 010 · API-04-022, 034 · UI-04-04 · UC-04-04 · ERR-04-006.

**Tiền điều kiện, dữ liệu.** IE1 và IE2 cùng mở F-HT v4 trên hai trình duyệt.

**Các bước.**

1. Cả hai mở trình thiết kế.
2. IE2 đổi `timeout` của chặng `deliver`, chờ tự lưu.
3. IE1 (chưa tải lại) đổi mô tả chặng `transform`, chờ tự lưu.
4. IE1 chọn "Gộp" trong hộp xung đột.
5. Lặp lại, lần này IE1 và IE2 cùng đổi `timeout` của chặng `deliver` với giá trị khác nhau.

**Kết quả mong đợi.** Bước 1: mỗi người thấy huy hiệu "Trần Thị Bình đang mở" (nhịp API-04-034). Bước 3: lưu nhận `412`, giao diện mở hộp xung đột ba bên (ST-08). Bước 4: thay đổi không chồng nhau được gộp tự động, lưu thành công với ETag mới, cả hai thay đổi có trong YAML. Bước 5: hộp liệt kê trường xung đột `timeout` với ba giá trị (gốc, của tôi, của Bình); chưa chọn thì nút "Lưu" bị khóa. Không bước nào mất thay đổi của IE1 (giữ ở IndexedDB tới khi lưu được).
:::

#### TC-04-034 · Mất kết nối khi đang soạn, khôi phục phiên nháp <!--k:offline-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-024 · UI-04-04 · NFR-04-015.

**Tiền điều kiện, dữ liệu.** IE1 mở F-HT v4.

**Các bước.**

1. Playwright đặt `context.setOffline(true)`, IE1 thêm hai chặng.
2. Đóng tab, mở lại trang khi vẫn ngoại tuyến.
3. Bật mạng.

**Kết quả mong đợi.** Bước 1: banner ST-09, chỉ báo "Chưa lưu lên máy chủ". Bước 2: hộp "Khôi phục thay đổi chưa lưu lúc {giờ}?". Bước 3: tự lưu, chỉ báo về "Đã lưu". Nếu ETag đã đổi trong lúc ngoại tuyến thì vào hộp gộp ba bên như ca xung đột.
:::

#### TC-04-035 · Phiên soạn hết hạn và catalog đổi khi đang mở <!--k:session-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-04-010, 081 · API-04-034 · UI-04-04.

**Tiền điều kiện, dữ liệu.** IE1 mở F-HT v4.

**Các bước.**

1. IE2 gọi `PUT .../session` một lần rồi ngừng.
2. Sau 125 giây IE1 gọi `PUT .../session`.
3. PA phát hành catalog mới cho T68 trong lúc IE1 đang mở.

**Kết quả mong đợi.** Bước 2: `others` không còn IE2. Bước 3: ở nhịp kế tiếp `catalogVersion` khác bản đang dùng, giao diện hiện banner "Danh mục thành phần đã cập nhật" và nút "Nạp lại danh mục", không tự đổi giữa chừng.
:::

#### TC-04-036 · Lưu nháp trong khoảng đóng băng cả việc soạn <!--k:save-freeze-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-04-024, 084 · BR-04-022 · API-04-022 · ERR-04-041.

**Tiền điều kiện, dữ liệu.** TA đặt khoảng đóng băng có cờ "khóa cả soạn thảo" từ bây giờ tới 2 giờ sau.

**Các bước.**

1. IE1 lưu nháp F-HT v4.
2. TA đặt lại khoảng đóng băng không có cờ, IE1 lưu lại.

**Kết quả mong đợi.** Bước 1 trả `423` ERR-04-041 với `until`. Bước 2 trả `200` (đóng băng thường chỉ chặn phát hành).
:::

### TS-04-06 · Trình thiết kế: bảng thành phần, sơ đồ, cấu hình chặng

**Mục tiêu.** Kiểm thử E2E trình thiết kế UI-04-04 ở mức thao tác người dùng thật: kéo thả bằng chuột, bàn phím, các cửa sổ cấu hình. Thay công cụ kéo thả Angular của Productivity Tooling (LGC-TOOL).

**Phủ.** FR-04-012, 013, 014; BR-04-014; UC-04-04, 05; API-04-070, 071; UI-04-04, 05, 17; NFR-04-001, 002.

#### TC-04-037 · Bảng thành phần chỉ hiện thành phần được phép <!--k:palette-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-04-012, 080 · BR-04-014 · API-04-070 · UI-04-04 · LGC-TOOL-002.

**Tiền điều kiện, dữ liệu.** Chính sách nền cấm `exec`, `ssh`; T68 thu hẹp cấm `ftp`. IE1 mở F-HT v4.

**Các bước.**

1. Gọi `GET /catalog`.
2. Gọi lại với `If-None-Match` bằng ETag bước 1.
3. Trên giao diện, gõ "ftp", "exec", "kafka" vào ô tìm của bảng thành phần.
4. Lọc theo vai trò chặng "Gửi đích".

**Kết quả mong đợi.** Bước 1: `entries` không có `exec`, `ssh`, `ftp`; `sftp` có `policy = ALLOWED`. Bước 2 trả `304`. Bước 3: "ftp", "exec" ra "Không có thành phần phù hợp" kèm liên kết "Xem chính sách thành phần"; "kafka" ra `kafka` ở nhóm "Hàng đợi bản tin". Bước 4 chỉ còn thành phần producer. Mỗi lần gõ phản hồi < 50 ms (NFR-04-002, đo `performance.now`).
:::

#### TC-04-038 · Thao tác sơ đồ bằng chuột <!--k:canvas-mouse-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-04-013 · UI-04-04 · UC-04-04 · LGC-TOOL-003, 004.

**Tiền điều kiện, dữ liệu.** IE1 mở `tc-trong` v1.

**Các bước.**

1. Kéo `log` từ bảng thành phần vào giữa chặng `transform` và `enrich`.
2. Kéo `choice` vào sau `route`, thêm hai nhánh `when` và một `otherwise`.
3. Chọn ba chặng bằng Shift + nhấp, nhấn Delete, rồi Ctrl+Z.
4. Nhấn "Tự sắp xếp".
5. Thu phóng bằng Ctrl + cuộn tới 25% và 200%.

**Kết quả mong đợi.** Bước 1: chặng chèn đúng vị trí, mũi tên nối lại, YAML cập nhật trong < 100 ms (NFR-04-005). Bước 2: nhánh hiện thành làn có nhãn điều kiện, `otherwise` luôn cuối. Bước 3: xóa rồi hoàn tác khôi phục đúng ba chặng và thuộc tính. Bước 4: bố cục dagre trái sang phải, không chồng khối. Bước 5: ở 25% nhãn chặng ẩn, chỉ còn biểu tượng và màu nhóm; minimap luôn hiện.
:::

#### TC-04-039 · Thao tác không hợp lệ trên sơ đồ <!--k:canvas-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-013 · BR-04-002 · UI-04-04.

**Tiền điều kiện, dữ liệu.** IE1 mở `tc-trong` v1 (đối ngoại).

**Các bước.**

1. Kéo `kafka` (consumer) vào giữa route như một chặng thường.
2. Kéo thả chặng `otherwise` ra ngoài `choice`.
3. Xóa khối chặng chuẩn `authz`.

**Kết quả mong đợi.** Bước 1: vùng thả tô đỏ, tooltip "Thành phần này chỉ dùng làm điểm bắt đầu route"; không thêm. Bước 2: không cho thả. Bước 3: hộp xác nhận "Luồng đối ngoại phải có đủ chín chặng chuẩn. Xóa sẽ làm luồng không gửi duyệt được."; xác nhận thì xóa và bảng Vấn đề có VR-05 mức `WARN` (DESIGN).
:::

#### TC-04-040 · Cấu hình chặng bằng biểu mẫu sinh từ catalog <!--k:step-config-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-04-014 · API-04-071 · UI-04-05 · UC-04-05.

**Tiền điều kiện, dữ liệu.** IE1 mở F-HT v4, chọn chặng gửi đích `http`.

**Các bước.**

1. Gọi `GET /catalog/components/http`.
2. Mở UI-04-05 của chặng; mở nhóm "Nâng cao".
3. Đổi `connectTimeout` sang `abc`, rồi `5000`.
4. Nhấn "Khôi phục giá trị gốc" trên trường `followRedirects`.

**Kết quả mong đợi.** Bước 1: `properties` có nhóm, kiểu, mặc định, `descriptionVi`. Bước 2: trường bắt buộc có dấu, trường `secret = true` không có ô nhập tự do mà chỉ có "Chọn kết nối" hoặc "Tham chiếu bí mật". Bước 3: `abc` báo "Phải là số nguyên" tại chỗ, không lưu; `5000` lưu. Bước 4: trường về mặc định và bị bỏ khỏi YAML (không ghi giá trị mặc định thừa). Cửa sổ có 154 thuộc tính mở trong < 400 ms (NFR-04-006).
:::

#### TC-04-041 · Lược đồ thành phần không có trong catalog <!--k:step-config-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-04-014 · API-04-071 · ERR-04-035.

**Tiền điều kiện, dữ liệu.** U-T68-IE1.

**Các bước.**

1. Gọi `GET /catalog/components/khong-co`.
2. Gọi `GET /catalog/components/http?catalogVersion=0.0.0`.

**Kết quả mong đợi.** Cả hai trả `404` ERR-04-035.
:::

#### TC-04-042 · Thành phần đã dùng nhưng sau đó bị cấm <!--k:palette-banned-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-012, 080 · BR-04-014 · UI-04-04 · ERR-04-011.

**Tiền điều kiện, dữ liệu.** `tc-ftp` dùng `sftp`; TA thu hẹp chính sách cấm `sftp`.

**Các bước.**

1. IE1 mở `tc-ftp`.
2. Gửi duyệt.

**Kết quả mong đợi.** Bước 1: chặng `sftp` hiện huy hiệu "Không còn được phép" màu cảnh báo, vẫn sửa được thuộc tính. Bước 2 trả `422` ERR-04-009 có finding VR-04 → ERR-04-011.
:::

### TS-04-07 · Quay vòng YAML, tải xuống, nhập YAML

**Mục tiêu.** Bảo đảm không mất dữ liệu khi qua lại giữa sơ đồ, biểu mẫu và YAML (BR-04-006), và YAML đem triển khai không chứa bố cục, bản tin mẫu, ghi chú (BR-04-007).

**Phủ.** FR-04-017, 027; BR-04-006, 007; API-04-022, 026, 027; UI-04-04; ERR-04-008, 009, 033.

#### TC-04-043 · Quay vòng không sửa giữ nguyên băm <!--k:roundtrip-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT, E2E.

**Truy vết.** FR-04-017 · BR-04-006 · UI-04-04.

**Tiền điều kiện, dữ liệu.** 40 tệp YAML mẫu trong `src/test/resources/roundtrip/` (gồm mọi EIP trong catalog, chú thích YAML, khóa không theo thứ tự, chuỗi nhiều dòng, ký tự tiếng Việt).

**Các bước.**

1. Với mỗi tệp: nạp thành cây tài nguyên, sinh lại YAML, tính băm chuẩn hóa.
2. Kiểm thử theo thuộc tính (fast-check): sinh cây ngẫu nhiên hợp lệ 1.000 lần, YAML → cây → YAML.
3. E2E: mở F-HT v4, chuyển tab Sơ đồ → YAML → Sơ đồ ba lần, không sửa.

**Kết quả mong đợi.** Bước 1, 2: băm chuẩn hóa trước và sau bằng nhau trong 100% trường hợp; thuộc tính không có trong catalog (thuộc tính tùy biến) được giữ nguyên. Bước 3: chỉ báo "Đã lưu" không đổi, không có lần lưu nào được gửi.
:::

#### TC-04-044 · Sửa trong YAML phản ánh lên sơ đồ <!--k:yaml-edit-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-04-017 · UI-04-04.

**Tiền điều kiện, dữ liệu.** IE1 mở F-HT v4, tab YAML (Monaco).

**Các bước.**

1. Thêm một bước `log` bằng tay trong YAML.
2. Gõ sai thụt lề.
3. Chuyển sang tab Sơ đồ khi YAML đang lỗi.

**Kết quả mong đợi.** Bước 1: sau 500 ms sơ đồ có chặng `log` đúng vị trí. Bước 2: gạch đỏ tại dòng, bảng Vấn đề có VR-01. Bước 3: hộp "YAML đang có lỗi cú pháp. Sơ đồ đang hiển thị bản hợp lệ gần nhất." và không ghi đè nội dung đang gõ.
:::

#### TC-04-045 · YAML triển khai không chứa bố cục, bản tin mẫu, ghi chú <!--k:yaml-clean-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, GO.

**Truy vết.** FR-04-017, 022, 026 · BR-04-007 · API-04-026.

**Tiền điều kiện, dữ liệu.** F-HT v4 có bố cục, bản tin mẫu MSG-OK ở ba chặng, hai ghi chú dán.

**Các bước.**

1. Gọi `GET .../versions/4/download?format=yaml`.
2. Gọi `GET .../versions/4/download?format=yaml+layout`.
3. Sau khi v4 được phát hành ở TEST, đọc tệp `flows/tra-cuu-ho-tich/flow.camel.yaml` trên `env/test`.

**Kết quả mong đợi.** Bước 1 và 3: không có khóa `dh-layout`, `dh-samples`, `dh-notes`, không có chuỗi `001099000001`. Bước 2: có bố cục ở khối chú thích tách riêng để nhập lại được. Băm chuẩn hóa của tệp trên Git bằng `contentHash` của v4.
:::

#### TC-04-046 · Nhập YAML thay định nghĩa <!--k:import-yaml-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-027 · API-04-027.

**Tiền điều kiện, dữ liệu.** F-HT v4; tệp YAML đã sửa ngoài.

**Các bước.**

1. Gọi `POST .../versions/4:import-yaml` với `keepLayout = true`.

**Kết quả mong đợi.** `200`; định nghĩa thay mới; chặng có cùng `id` giữ vị trí cũ trên sơ đồ, chặng mới được tự sắp xếp. `validation` trả kèm.
:::

#### TC-04-047 · Nhập YAML không hợp lệ <!--k:import-yaml-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-027 · API-04-027 · ERR-04-008, 009, 033.

**Tiền điều kiện, dữ liệu.** YAML-BOMB, YAML-BIG, YAML có thẻ `!!java.lang.Runtime`.

**Các bước.**

1. Nhập YAML-BOMB.
2. Nhập YAML-BIG.
3. Nhập YAML có thẻ kiểu Java.
4. Nhập YAML của Kamelet vào phiên bản loại ROUTE.

**Kết quả mong đợi.** Bước 1 trả `422` ERR-04-008 trong < 1 giây, bộ nhớ heap không tăng quá 50 MiB (VR-01 giới hạn bí danh 50, độ sâu 64). Bước 2 trả `413` ERR-04-033. Bước 3 trả `422` ERR-04-008, không tạo đối tượng Java (SnakeYAML Engine không hỗ trợ thẻ toàn cục). Bước 4 trả `422` ERR-04-009.
:::

### TS-04-08 · Biểu thức, kết nối, bí mật, bản tin mẫu

**Mục tiêu.** Bảo đảm không có đường nào ghi bí mật vào định nghĩa luồng, biểu thức được kiểm đúng engine Camel của runtime, bản tin mẫu không mang dữ liệu cá nhân thật ra ngoài sandbox.

**Phủ.** FR-04-015, 016, 022; BR-04-003, 013; UC-04-05; API-04-032, 022; UI-04-05, 06; ERR-04-010, 013, 019, 021, 037.

#### TC-04-048 · Kiểm tra và xem trước biểu thức <!--k:expr-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-015 · API-04-032 · UI-04-06 · LGC-TOOL-006.

**Tiền điều kiện, dữ liệu.** IE1; MSG-OK.

**Các bước.**

1. Gọi `POST /expressions:check` với `{"language":"simple","expression":"${body[soDinhDanh]} != null","predicate":true}`.
2. Gọi với `jsonpath` `$.hoTen`, `evaluate = true`, `sample.body` = MSG-OK.
3. Gọi với `jq` `.ngaySinh | split("-")[0]`, `evaluate = true`.
4. Trên UI-04-06, gõ `${he` và chờ gợi ý.

**Kết quả mong đợi.** Bước 1 trả `200`, `valid = true`. Bước 2 trả `result = "Nguyễn Văn Thử"`, `resultType = String`, `simulated = false`. Bước 3 trả `"1990"`. Bước 4: gợi ý `header.`, `headers` kèm mô tả tiếng Việt.
:::

#### TC-04-049 · Biểu thức lỗi <!--k:expr-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-015 · API-04-032 · ERR-04-037, 019, 021.

**Tiền điều kiện, dữ liệu.** IE1.

**Các bước.**

1. Kiểm `simple` `${body[soDinhDanh}`.
2. Kiểm như bước 1 ở chế độ chặt.
3. Kiểm `jq` với `sample.body` = MSG-BIG.
4. Dừng sandbox, kiểm `jq` với `evaluate = true`.
5. Kiểm `groovy` (ngôn ngữ không có trong catalog).

**Kết quả mong đợi.** Bước 1 trả `200`, `valid = false`, `error.column` trỏ đúng vị trí; UI-04-06 tô đỏ vị trí. Bước 2 trả `422` ERR-04-037. Bước 3 trả `413` ERR-04-021. Bước 4 trả `503` ERR-04-019 (biên dịch không cần sandbox vẫn chạy được nếu `evaluate = false`). Bước 5 trả `400` ERR-04-049.
:::

#### TC-04-050 · Chọn kết nối PH-05 thay vì nhập thông tin đăng nhập <!--k:conn-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-04-016 · BR-04-003 · UI-04-05 · UC-04-05.

**Tiền điều kiện, dữ liệu.** IE1 mở F-HT v4, chặng gửi đích.

**Các bước.**

1. Mở ô "Kết nối", tìm "HT".
2. Chọn CONN-HT.
3. Chọn trường "Mật khẩu proxy", bấm "Tham chiếu bí mật", chọn `vault:ho-tich/proxy`.

**Kết quả mong đợi.** Bước 1 chỉ liệt kê kết nối đã cấp cho WS-HOTICH (không có CONN-DD-ONLY), hiện loại và môi trường có giá trị. Bước 2: YAML có `{{conn:CONN-HT}}`. Bước 3: YAML có `{{vault:ho-tich/proxy}}`; giao diện không có ô nào cho phép dán giá trị bí mật.
:::

#### TC-04-051 · Phát hiện bí mật mọi chỗ trong định nghĩa <!--k:secret-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-04-016, 023 · BR-04-003 · API-04-022 · ERR-04-010.

**Tiền điều kiện, dữ liệu.** 24 mẫu bí mật: tham số URI `password=`, `accessKey=`, `Authorization: Basic …` trong `setHeader`, JWT, khóa PEM, chuỗi AWS `AKIA…`, giá trị bean `secret`, chuỗi entropy cao 40 ký tự trong thuộc tính tên `token`; và 10 mẫu hợp lệ: `{{conn:…}}`, `{{vault:…}}`, `#bean`, UUID, băm sha256 trong `contentHash`.

**Các bước.**

1. Chạy `SecretDetector` trên từng mẫu (UT).
2. Lưu nháp với từng mẫu bí mật (API).

**Kết quả mong đợi.** Bước 1: phát hiện 24/24, không báo nhầm 10/10 mẫu hợp lệ. Bước 2: mỗi lần trả `422` ERR-04-010; `findings[].message` chỉ có đường dẫn và loại ("chuỗi giống mật khẩu"), không có giá trị; log ứng dụng và vết OpenTelemetry không có giá trị (quét bằng `grep` trên log IT).
:::

#### TC-04-052 · Kết nối không hợp lệ <!--k:conn-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-016, 023 · API-04-030 · ERR-04-013.

**Tiền điều kiện, dữ liệu.** `tc-conn` tham chiếu lần lượt `{{conn:KHONG-CO}}`, CONN-DD-ONLY (chưa cấp cho WS-HOTICH), CONN-DKKD-RO cho chặng `http` (sai loại).

**Các bước.**

1. Gọi `:validate` mức `DESIGN`.
2. Gọi `:validate` mức `SUBMIT`.

**Kết quả mong đợi.** Bước 1: ba finding VR-07 mức `WARN`. Bước 2: ba finding VR-07 mức `ERROR`, mã ERR-04-013 trong `args`.
:::

#### TC-04-053 · Ghim bản tin mẫu theo chặng và cảnh báo dữ liệu cá nhân <!--k:samples-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-022 · BR-04-007, 013 · UI-04-04, 05.

**Tiền điều kiện, dữ liệu.** IE1 (không có `PERM-04-sample-data`), IE2 (được cấp `PERM-04-sample-data` cho F-HT).

**Các bước.**

1. IE1 ghim MSG-OK ở chặng `receive`.
2. IE1 dán MSG-PII vào chặng `transform`.
3. IE2 dán MSG-PII và chọn "Vẫn dùng".

**Kết quả mong đợi.** Bước 1: chặng sau dùng bản tin của chặng trước gần nhất (hiện nhãn "kế thừa từ Tiếp nhận"). Bước 2: cảnh báo "Bản tin mẫu có dấu hiệu chứa dữ liệu cá nhân (số điện thoại, thư điện tử)", nút "Thay bằng dữ liệu giả" và không có "Vẫn dùng". Bước 3: lưu được; KT: có (`INT_SAMPLE_PII_OVERRIDE`).
:::

#### TC-04-189 · Sandbox không sẵn sàng khi xem trước biểu thức <!--k:expr-sandbox-down-->

::: dac-ta
**Loại.** Âm, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** E2E, API.

**Truy vết.** FR-04-015 · UC-04-05 · API-04-032 · UI-04-06 · ERR-04-019.

**Tiền điều kiện, dữ liệu.** U-T68-IE1 mở F-HT v4 `DRAFT` trên UI-04-04; `dh-runtime-sandbox` thu về 0 bản sao; bản tin mẫu MSG-OK đã ghim.

**Các bước.**

1. Mở trình soạn biểu thức (UI-04-06) của chặng `transform`, nhập `${body.soDinhDanh}` ngôn ngữ `simple`, bấm "Thử".
2. Đổi sang `jq` với `.hoTen`, bấm "Thử".
3. Đổi sang `xpath`, bấm "Thử".
4. Gọi thẳng `POST /expressions:check` với `evaluate = true`.

**Kết quả mong đợi.** Bước 4 trả `503` ERR-04-019. Bước 1, 2: giao diện không hiện hộp lỗi mà chuyển sang nhánh 6a của UC-04-05: đánh giá cục bộ trên trình duyệt, kết quả đúng giá trị của MSG-OK và **bắt buộc** gắn nhãn "Xem trước mô phỏng trên trình duyệt, kết quả có thể khác runtime". Bước 3: hiện "Chưa xem trước được" (ngôn ngữ không có bộ đánh giá cục bộ). Kiểm tra cú pháp (biên dịch) vẫn chạy, gạch sóng vẫn hiện khi gõ sai. Không có lần chạy thử nào được tạo; KT: không.
:::

### TS-04-09 · Trình ánh xạ dữ liệu

**Mục tiêu.** Xác nhận trình ánh xạ sinh JQ đúng, chạy được trên runtime và chuyển mã qua PH-07 bằng hàm `dh_map`.

**Phủ.** FR-04-020, 065; UC-04-06; API-04-033; UI-04-07; ERR-04-021, 038.

#### TC-04-054 · Ánh xạ trường, hàm và chuyển mã <!--k:mapper-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API, RT.

**Truy vết.** FR-04-020, 065 · API-04-033 · UI-04-07 · UC-04-06 · LGC-TOOL-008.

**Tiền điều kiện, dữ liệu.** Lược đồ nguồn `hotich-yeucau-v1`, đích CDM `cdm-cong-dan-v1`; bảng chuyển mã PH-07 `GIOI_TINH` (giả lập).

**Các bước.**

1. Trên UI-04-07, kéo `hoTen` → `ten.day_du`, `ngaySinh` → `ngay_sinh` với hàm "Định dạng ngày", `gioiTinh` → `gioi_tinh` với "Chuyển mã danh mục GIOI_TINH".
2. Gọi `POST /mappings:preview` với `sample` = MSG-OK có `gioiTinh = "1"`.
3. Chạy luồng mẫu dùng ánh xạ trên runtime (RT).

**Kết quả mong đợi.** Bước 2 trả `jq` có `dh_map("GIOI_TINH"; .gioiTinh)`, `output.gioi_tinh = "NAM"`, `targetValid = true`. Bước 3: runtime trả cùng kết quả với bước 2 (cùng phiên bản thư viện JQ, so sánh từng byte).
:::

#### TC-04-055 · Ánh xạ không hợp lệ <!--k:mapper-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-020 · API-04-033 · ERR-04-038, 021.

**Tiền điều kiện, dữ liệu.** Như ca trên.

**Các bước.**

1. Xem trước với ánh xạ tới `ten.khong_co`.
2. Xem trước với hai trường suy ra lẫn nhau (vòng).
3. Xem trước với tài liệu mẫu 1,1 MiB.

**Kết quả mong đợi.** Bước 1, 2 trả `422` ERR-04-038, `findings[].args.target` chỉ trường. Bước 3 trả `413` ERR-04-021.
:::

#### TC-04-056 · Trường bắt buộc của đích chưa ánh xạ <!--k:mapper-required-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-04-020, 084 · API-04-030.

**Tiền điều kiện, dữ liệu.** Ánh xạ thiếu `so_dinh_danh` (bắt buộc ở đích).

**Các bước.**

1. `:validate` mức `SUBMIT` với `04.mapping.require-all-required = false`.
2. Bật tham số, kiểm lại.

**Kết quả mong đợi.** Bước 1: finding mức `WARN`. Bước 2: finding mức `ERROR`.
:::

#### TC-04-190 · Sandbox không sẵn sàng khi xem trước ánh xạ <!--k:mapper-sandbox-down-->

::: dac-ta
**Loại.** Âm, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** E2E, API.

**Truy vết.** FR-04-020 · UC-04-06 · API-04-033 · UI-04-07 · ERR-04-019.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; F-HT v4 có chặng ánh xạ "Chuẩn hóa hồ sơ" dùng bảng mã `gioi-tinh-ht-ndxp` của PH-07; sandbox thu về 0 bản sao.

**Các bước.**

1. Mở UI-04-07, bấm "Thử trên bản tin mẫu" với MSG-OK.
2. Gọi thẳng `POST /mappings:preview`.
3. Bấm "Lưu" ánh xạ.

**Kết quả mong đợi.** Bước 2 trả `503` ERR-04-019. Bước 1: xem trước cục bộ có nhãn "Xem trước mô phỏng trên trình duyệt, kết quả có thể khác runtime"; trường dùng hàm `dh_map` hiện "Chưa xem trước được" vì cần runtime. Bước 3: lưu thành công (`200`), JQ sinh từ dhmap không đổi so với khi sandbox sẵn sàng (so băm). Dữ liệu xem trước vẫn được che theo BR-04-013.
:::

### TS-04-10 · Kamelet, Pipe, bean, ghi chú, luồng con

**Phủ.** FR-04-018, 019, 021, 026; UC-04-07; UI-04-08, 09, 10; ERR-04-011, 029, 036.

#### TC-04-057 · Soạn Kamelet tự viết và dùng trong luồng <!--k:kamelet-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-018 · UI-04-08 · UC-04-07.

**Tiền điều kiện, dữ liệu.** F-KAM v1 `DRAFT`, tham số `pattern` và `maskChar`.

**Các bước.**

1. Trên UI-04-08, khai báo tham số, đánh dấu không nhạy cảm, lưu.
2. Đưa F-KAM qua duyệt và phát hành TEST.
3. Mở F-HT v4, tìm "ma hoa" trong bảng thành phần.

**Kết quả mong đợi.** Bước 1: VR-15 không có lỗi. Bước 3: F-KAM có trong nhóm "Chặng chuẩn Datahub" với nhãn "Của tỉnh", có `source = TENANT`; khi kéo vào, biểu mẫu sinh từ khai báo tham số.
:::

#### TC-04-058 · Kamelet sai <!--k:kamelet-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-018 · ERR-04-036, 029 · BR-04-003.

**Tiền điều kiện, dữ liệu.** IE1.

**Các bước.**

1. Tạo Kamelet tên `dh-receive-action` (trùng Kamelet nền).
2. Tạo Kamelet có tham số `apiKey` không đánh dấu `format: password`.
3. Tạo Kamelet dùng `smb` (không hồ sơ nào có).

**Kết quả mong đợi.** Bước 1 trả `409` ERR-04-036. Bước 2: finding VR-15 `ERROR`. Bước 3: ở mức `PUBLISH` có ERR-04-029.
:::

#### TC-04-059 · Soạn Pipe <!--k:pipe-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-04-019 · UI-04-09.

**Tiền điều kiện, dữ liệu.** Kamelet `kafka-source`, F-KAM (`action`), `http-sink`.

**Các bước.**

1. Tạo Pipe `source: kafka-source`, `steps: [F-KAM]`, `sink: http-sink`.
2. Đặt `http-sink` vào `source`.

**Kết quả mong đợi.** Bước 1: hợp lệ. Bước 2: finding VR-15 "Kamelet loại sink không dùng làm nguồn".
:::

#### TC-04-060 · Bean khai báo và cấu hình cấp tệp <!--k:bean-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-04-021 · UI-04-10 · ERR-04-011.

**Tiền điều kiện, dữ liệu.** Danh sách lớp bean cho phép có `vn.datahub.runtime.beans.VietnameseNormalizer`.

**Các bước.**

1. Khai báo bean lớp được phép, dùng `#normalizer` ở chặng `transform`.
2. Khai báo bean `java.lang.ProcessBuilder`.

**Kết quả mong đợi.** Bước 1 hợp lệ. Bước 2: VR-04 `ERROR` ở `SUBMIT`, "Lớp không được phép"; gửi duyệt trả ERR-04-009 với ERR-04-011 trong finding.
:::

#### TC-04-061 · Ghi chú dán và luồng con <!--k:notes-subflow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-026 · BR-04-007 · UI-04-04.

**Tiền điều kiện, dữ liệu.** F-HT v4.

**Các bước.**

1. Thêm hai ghi chú dán màu khác nhau.
2. Chọn ba chặng, "Tách thành luồng con".

**Kết quả mong đợi.** Bước 1: ghi chú lưu ở bố cục, không có trong YAML (BR-04-007). Bước 2: sinh route `direct:{flow}-sub-1` trong cùng tệp, chỗ cũ thay bằng `to: direct:…`; quay vòng YAML giữ nguyên băm sau khi tách.
:::

#### TC-04-191 · Trạng thái màn và câu chặn của Trình soạn Pipe <!--k:ui-pipe-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-019 · UI-04-09 · ERR-04-001, 011.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; Pipe mới `tc-pipe`; Pipe `sftp-bhxh-to-kafka` v3 `APPROVED`; Kamelet `dh-csv-to-json` bị cấm sau khi dùng; U-T68-VW.

**Các bước.**

1. IE1 tạo Pipe `tc-pipe` và mở UI-04-09.
2. Kéo thành phần thô `http` vào ô Bước; kéo Kamelet `dh-kafka-sink` vào ô Nguồn.
3. Thêm bước thứ 21.
4. Mở `sftp-bhxh-to-kafka` v2 có bước `dh-csv-to-json`.
5. VW mở `sftp-bhxh-to-kafka` v3.

**Kết quả mong đợi.** Bước 1: ba ô rỗng nét đứt "Chọn nguồn", "Thêm bước (tùy chọn)", "Chọn đích"; skeleton ba ô trong lúc tải. Bước 2: không thả được, chú thích "Pipe chỉ dùng Kamelet. Muốn dùng thành phần http, tạo luồng loại route." và "Ô Nguồn chỉ nhận Kamelet loại source." (VR-15). Bước 3: "Pipe có tối đa 20 bước. Tách thành hai Pipe nối qua topic." Bước 4: ô có huy hiệu "Không còn được phép" (ERR-04-011). Bước 5: ST-07 chỉ đọc, bảng Kamelet ẩn.
:::

### TS-04-11 · Kiểm tra hợp lệ VR-01…20

**Mục tiêu.** Mỗi quy tắc kiểm tra có ít nhất một ca phát hiện và một ca không báo nhầm, ở đúng mức nghiêm trọng theo FRS FR-04-023. Bộ quy tắc phía trình duyệt và phía máy chủ cho cùng kết quả trên tập quy tắc chung.

**Phủ.** FR-04-023; BR-04-002, 008, 009, 010, 011, 014, 015, 020; API-04-030, 031; ERR-04-009, 011, 012, 013, 031, 043; NFR-04-007.

#### TC-04-062 · Ma trận mức nghiêm trọng theo mức kiểm tra <!--k:vr-matrix-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-04-023 · API-04-030.

**Tiền điều kiện, dữ liệu.** Bộ 20 tệp YAML, mỗi tệp vi phạm đúng một quy tắc VR-01…20 (`src/test/resources/vr/vr-nn.yaml`), cộng YAML-OK.

**Các bước.**

1. Chạy `ValidationEngine` trên từng tệp ở ba mức `DESIGN`, `SUBMIT`, `PUBLISH`.

**Kết quả mong đợi.** 60 kết quả khớp đúng bảng FR-04-023 (ví dụ VR-05: `WARN`, `ERROR`, `ERROR`; VR-12: `INFO`, `WARN`, `ERROR`). YAML-OK không có finding nào ở mọi mức. Mỗi finding có `rule`, `severity`, `path`, `nodeId`, `message` tiếng Việt.
:::

#### TC-04-063 · Chín chặng chuẩn với luồng đối ngoại và nội bộ <!--k:vr-stages-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023, 060 · BR-04-002 · ERR-04-012.

**Tiền điều kiện, dữ liệu.** `tc-ngoai` (EXTERNAL) và `tc-noi` (INTERNAL), cùng thiếu chặng `authz` và đảo thứ tự `audit` với `deliver`.

**Các bước.**

1. `:validate` mức `SUBMIT` trên `tc-ngoai`.
2. Như bước 1 trên `tc-noi`.

**Kết quả mong đợi.** Bước 1: VR-05 `ERROR`, `args.stages = ["authz"]`, và một finding thứ tự; map sang ERR-04-012. Bước 2: VR-06 `WARN`, không chặn.
:::

#### TC-04-064 · Trùng mã route, trùng đường dẫn HTTP <!--k:vr-dup-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023 · BR-04-011.

**Tiền điều kiện, dữ liệu.** `tc-trung` có route `tra-cuu-ho-tich-main` (trùng F-HT đang chạy) và `path: /ho-tich/tra-cuu`.

**Các bước.**

1. `:validate` mức `DESIGN`.
2. Đổi mã route và đường dẫn, kiểm lại.

**Kết quả mong đợi.** Bước 1: VR-08 và VR-18 `ERROR` ngay ở `DESIGN`. Bước 2: không còn finding. Đường dẫn trùng F-T01 ở T01 không bị báo (khác tenant).
:::

#### TC-04-065 · Topic chưa đăng ký hoặc không có quyền <!--k:vr-topic-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023, 069 · BR-04-009.

**Tiền điều kiện, dữ liệu.** `tc-topic` gửi tới `t68.chua-dang-ky.v1`, TOPIC-NOACL, TOPIC-T01.

**Các bước.**

1. `:validate` mức `SUBMIT`.

**Kết quả mong đợi.** Ba finding VR-10 `ERROR`. Với TOPIC-T01 thông điệp là "Không được dùng topic của tỉnh khác".
:::

#### TC-04-066 · Thiếu xử lý lỗi và DLQ <!--k:vr-dlq-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023, 070 · BR-04-008.

**Tiền điều kiện, dữ liệu.** `tc-loi` bỏ `routeConfigurationId`, không có `errorHandler`.

**Các bước.**

1. `:validate` mức `SUBMIT`.
2. Thêm `errorHandler: deadLetterChannel` tới `kafka:t68.ops.dlq.v1`, kiểm lại.

**Kết quả mong đợi.** Bước 1: VR-11 `ERROR`. Bước 2: không còn finding.
:::

#### TC-04-067 · Đặt tiêu đề tenant sai chỗ <!--k:vr-tenant-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023, 073 · BR-04-010.

**Tiền điều kiện, dữ liệu.** `tc-ten` có `setHeader: name: dh-tenant, simple: ${header.X-Tenant}` ở chặng `transform`.

**Các bước.**

1. `:validate` mức `DESIGN`, `SUBMIT`.

**Kết quả mong đợi.** VR-14 `WARN`, `ERROR`. Thông điệp "Không được đặt tiêu đề dh-tenant; tenant do chặng Tiếp nhận đặt".
:::

#### TC-04-068 · Thành phần nguy hiểm và chỉ chạy JVM <!--k:vr-danger-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-023, 075 · BR-04-014 · ERR-04-011, 029.

**Tiền điều kiện, dữ liệu.** `tc-nguy` dùng `exec:`, `file:/etc`, `cxf` (chỉ JVM) khi T68 không được phép hồ sơ `legacy-jvm` nhưng được `soap-jvm`.

**Các bước.**

1. `:validate` mức `PUBLISH` với `targetEnvironment = TEST`.

**Kết quả mong đợi.** VR-19 `ERROR` cho `exec`, `file`; VR-12 không báo lỗi cho `cxf` vì có hồ sơ `soap-jvm` hợp lệ; nếu bỏ quyền `soap-jvm` thì VR-12 `ERROR` và ERR-04-029.
:::

#### TC-04-069 · HTTT đích chưa kết nạp và catalog cũ <!--k:vr-httt-catalog-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-023, 068, 081 · BR-04-020 · ERR-04-043, 042.

**Tiền điều kiện, dữ liệu.** `tc-dich` có `targetSystems = ["HT-CHUA-KET-NAP"]` (không có ở bản sao PH-01); `definition.catalogVersion` thấp hơn catalog hiện hành.

**Các bước.**

1. `:validate` mức `SUBMIT`.
2. `:submit`.

**Kết quả mong đợi.** Bước 1: finding với ERR-04-043 và VR-17 `ERROR`. Bước 2 trả `409` ERR-04-042 (kiểm catalog trước khi chạy đủ quy tắc, theo thứ tự ở D03-04-PH04 §3 ghi chú 3).
:::

#### TC-04-070 · Kiểm tra trình duyệt và máy chủ cho cùng kết quả <!--k:vr-parity-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** UT.

**Truy vết.** FR-04-023 · NFR-04-007.

**Tiền điều kiện, dữ liệu.** Bộ tệp `vr-nn.yaml` của các quy tắc VR-01…09, 15, 18, 20 (phần chạy được ở trình duyệt).

**Các bước.**

1. Chạy bộ quy tắc trình duyệt (Vitest) và máy chủ (JUnit) trên cùng tệp, so sánh `rule`, `severity`, `path`.

**Kết quả mong đợi.** Kết quả trùng khớp 100%. Thời gian máy chủ mức `SUBMIT` cho YAML-200 p95 < 2 giây (NFR-04-007).
:::

### TS-04-12 · Chạy thử trên sandbox

**Mục tiêu.** Thay cơ chế "chạy thử giả lập" của mã W2 bằng chạy thật trên `dh-runtime-sandbox`, với đích mô phỏng (`MOCK`) hoặc đích thật môi trường TEST (`SANDBOX_LIVE`). Kết quả chạy thử là điều kiện của gửi duyệt. Vì vậy ca dương tính phải chứng minh lần chạy thử thật sự đi qua Camel, không chỉ trả kết quả dựng sẵn.

**Phủ.** FR-04-030, 032, 033; BR-04-004, 013; UC-04-08; API-04-040…043; UI-04-11, 12; ERR-04-009, 013, 019, 020, 021; EVT-04-10; NFR-04-008.

#### TC-04-071 · Chạy thử MOCK đạt <!--k:run-pass-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-030, 033 · API-04-040, 042 · UI-04-11 · UC-04-08 · EVT-04-10 · NFR-04-008.

**Tiền điều kiện, dữ liệu.** F-HT v4 hợp lệ; IE1; MSG-OK; đích mô phỏng trả `{"ketQua":"OK"}`.

**Các bước.**

1. Gọi `POST .../versions/4/test-runs` với `{"mode":"MOCK","body":MSG-OK,"assertions":[{"kind":"STATUS","expected":200},{"kind":"STEP_VISITED","nodeId":"deliver-ht"}]}` và `Idempotency-Key`.
2. Mở SSE `GET .../test-runs/{runId}/events`.
3. Trên UI-04-11, quan sát sơ đồ.

**Kết quả mong đợi.** Bước 1 trả `202`, `Location`, `status = QUEUED`, `definitionHash = contentHash` của v4. Bước 2 nhận `status` → `RUNNING`, chín sự kiện `step` (một cho mỗi chặng chuẩn) có `stage`, `durationMs`, rồi `completed` với `status = PASSED`. Vết OpenTelemetry của lần chạy có span `camel` trong pod sandbox (chứng minh chạy thật). Bước 3: các chặng đã đi tô xanh, nhãn thời gian trên cạnh. EVT-04-10 phát. Từ gửi tới kết quả p95 < 5 giây (NFR-04-008). KT: có (`INT_TESTRUN_START`).
:::

#### TC-04-072 · Chạy thử không đạt và chặng lỗi <!--k:run-fail-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-030, 032, 033 · API-04-040, 042 · UI-04-11, 12.

**Tiền điều kiện, dữ liệu.** F-HT v4; MSG-NOID.

**Các bước.**

1. Chạy `MOCK` với MSG-NOID, khẳng định `STATUS = 200`.
2. Mở UI-04-12 (nhật ký) của lần chạy.

**Kết quả mong đợi.** Bước 1: `status = FAILED`; `assertionResults[0].passed = false`, `actual = 400`; chặng `schema` có `status = FAILED`, `errorClass = VALIDATION`; chặng sau `schema` có `SKIPPED`. Trên UI-04-11 chặng `schema` tô đỏ, các chặng sau tô xám "Không chạy" (FR-04-033). Bước 2: dòng chặng `schema` đỏ, thông điệp "Thiếu trường soDinhDanh", không có giá trị của trường khác (BR-04-013).
:::

#### TC-04-073 · Chạy thử với định nghĩa lỗi, kết nối thiếu TEST, bản tin lớn <!--k:run-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-030 · API-04-040 · ERR-04-009, 013, 021.

**Tiền điều kiện, dữ liệu.** `tc-loi-cu-phap` (VR-02 `ERROR`); `tc-notest` dùng CONN-NOTEST.

**Các bước.**

1. Chạy thử `tc-loi-cu-phap`.
2. Chạy `SANDBOX_LIVE` với `tc-notest`.
3. Chạy F-HT v4 với MSG-BIG.
4. Chạy với `timeoutSeconds = 121`.

**Kết quả mong đợi.** Lần lượt `422` ERR-04-009 (kèm `findings`), `422` ERR-04-013, `413` ERR-04-021, `400` ERR-04-049. Không có lần chạy nào vào hàng đợi.
:::

#### TC-04-074 · Quá thời gian và chặng treo <!--k:run-timeout-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-030 · API-04-042 · ERR-04-020.

**Tiền điều kiện, dữ liệu.** Đích mô phỏng của F-HT trễ 10 giây.

**Các bước.**

1. Chạy `MOCK` với `timeoutSeconds = 5`.

**Kết quả mong đợi.** Sau khoảng 5 giây: `status = TIMED_OUT`, `errorCode = ERR-04-020`, `hungNodeId = "deliver-ht"`. Sandbox dừng exchange và giải phóng chỗ trong hạn mức; lần chạy kế tiếp bắt đầu ngay.
:::

#### TC-04-075 · Hạn mức chạy thử đồng thời <!--k:run-quota-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-030, 084 · API-04-040 · ERR-04-019.

**Tiền điều kiện, dữ liệu.** `04.test.max-concurrent = 5`; đích trễ 10 giây.

**Các bước.**

1. Gửi đồng thời 6 lần chạy thử của T68.
2. Cùng lúc gửi 1 lần của T01.

**Kết quả mong đợi.** Năm lần đầu `202`. Lần thứ sáu `429` ERR-04-019 kèm `retryAfterSeconds` và tiêu đề `Retry-After`. Lần của T01 `202` (hạn mức tính theo tenant).
:::

#### TC-04-076 · Hủy lần chạy thử <!--k:run-cancel-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-04-030 · API-04-043 · ERR-04-005.

**Tiền điều kiện, dữ liệu.** Một lần chạy đang `QUEUED`, một lần đã `PASSED`.

**Các bước.**

1. `:cancel` lần `QUEUED`.
2. `:cancel` lần `PASSED`.

**Kết quả mong đợi.** Bước 1 trả `200`, `status = CANCELLED`. Bước 2 trả `409` ERR-04-005.
:::

#### TC-04-077 · Sandbox không sẵn sàng và chế độ mô phỏng <!--k:run-sim-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-030 · BR-04-004 · ERR-04-019.

**Tiền điều kiện, dữ liệu.** Thu nhỏ `dh-runtime-sandbox` về 0 bản sao.

**Các bước.**

1. Chạy thử với `04.test.allow-simulation = false`.
2. Bật `allow-simulation`, chạy lại.

**Kết quả mong đợi.** Bước 1 trả `503` ERR-04-019. Bước 2 trả `202`, kết quả `mode = SIMULATED`, giao diện hiện nhãn "Mô phỏng, không dùng để gửi duyệt". Lần chạy này không được tính cho BR-04-004 (xem ca gửi duyệt với lần mô phỏng ở TS-04-14).
:::

#### TC-04-078 · Nhật ký chạy thử: xem lại, so sánh, dọn <!--k:run-log-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-032 · API-04-041, 042 · UI-04-12 · BR-04-013.

**Tiền điều kiện, dữ liệu.** F-HT có 3 lần chạy; một lần bật `captureBodies`.

**Các bước.**

1. Gọi `GET /flows/tra-cuu-ho-tich/test-runs?versionNo=4`.
2. Gọi `GET .../test-runs/{id}/steps/3/body?side=out` cho lần có `captureBodies`.
3. Trên UI-04-12, chọn hai lần chạy, bấm "So sánh".
4. Đặt đồng hồ hệ thống tới 8 ngày sau, chạy job dọn.

**Kết quả mong đợi.** Bước 1: ba lần chạy, mỗi lần có `matchesCurrentHash`. Bước 2: thân đã che theo BR-04-013 (trường phân loại Hạn chế, Nhạy cảm thay bằng `***`). Bước 3: bảng so sánh theo chặng, tô khác biệt thời gian và trạng thái. Bước 4: thân bị xóa khỏi RGW bucket `dh-int-testrun` (`04.test.body-retention-days = 7`), bước 2 nay trả `404`; metadata còn tới 90 ngày.
:::

#### TC-04-079 · Chạy thử SANDBOX_LIVE gọi đích TEST <!--k:run-live-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-030 · UC-04-08.

**Tiền điều kiện, dữ liệu.** CONN-HT có giá trị TEST trỏ WireMock `OK`.

**Các bước.**

1. Chạy `SANDBOX_LIVE` với MSG-OK.

**Kết quả mong đợi.** `PASSED`; WireMock ghi nhận đúng một lệnh gọi tới URL TEST; không lệnh gọi nào tới URL PROD (kiểm bằng WireMock PROD không nhận yêu cầu). Sandbox chỉ đọc được giá trị TEST của kết nối (OpenBao policy).
:::

#### TC-04-192 · Đầu cuối một lần chạy thử MOCK theo trình tự SDD <!--k:e2e-run-mock-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-04-030, 032 · UC-04-08 · API-04-040, 042 · UI-04-11 · EVT-04-10 · NFR-04-008.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; F-HT v4 `DRAFT`, `captureBodies = true`; WireMock CONN-HT đếm lượt gọi; theo dõi Valkey Stream `dh:int:testrun:queue`, Ceph RGW `dh-int-testrun`, nhật ký truy cập của sandbox (D03-02-PH04 §8.2, hình chạy thử MOCK).

**Các bước.**

1. IE1 bấm "Chạy thử" với MSG-OK ở UI-04-04 (`mode = MOCK`).
2. Đọc hàng đợi Valkey và bảng `test_run`.
3. Theo dõi lượt gọi của sandbox tới `dh-integration`.
4. Theo dõi SSE tới khi `completed`.
5. Đọc `s3://dh-int-testrun/T68/{runId}/`.

**Kết quả mong đợi.** Bước 1 trả `202` có `runId`, SSE mở ngay. Bước 2: `test_run` ở `QUEUED` và đúng một việc trong hàng đợi theo hồ sơ. Bước 3: sandbox chỉ gọi hai API nội bộ (lấy gói chạy qua mTLS, `POST /internal/v1/testruns/{id}/steps` theo lô khoảng 200 ms); không có lượt nào tới WireMock CONN-HT (endpoint ra đã thay bằng `mock:`). Bước 4: sự kiện `step` mang thân đã che (không có `soDinhDanh` rõ), rồi `completed` với `PASSED` sau khi chạy khẳng định; EVT-04-10 phát. Bước 5: có tệp `{nodeId}-in.json`, `{nodeId}-out.json` mã hóa phía máy chủ. Toàn trình p95 < 5 giây.
:::

### TS-04-13 · Ca kiểm thử của luồng

**Phủ.** FR-04-031; BR-04-004; UC-04-09; API-04-044; UI-04-13; ERR-04-030.

#### TC-04-080 · Tạo ca kiểm thử và chạy tất cả <!--k:case-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-031 · API-04-044, 040 · UI-04-13 · UC-04-09.

**Tiền điều kiện, dữ liệu.** F-HT v4.

**Các bước.**

1. Tạo ca "KS-01 tra cứu hợp lệ" (MSG-OK, `STATUS = 200`, `BODY_JQ .ketQua == "OK"`).
2. Tạo ca "KS-02 thiếu số định danh" (MSG-NOID, `STATUS = 400`, `ERROR_CODE = ERR-04-101`, `STEP_NOT_VISITED deliver-ht`).
3. Trên UI-04-13 bấm "Chạy tất cả".

**Kết quả mong đợi.** Bước 1, 2 trả `201`. Bước 3: hai lần chạy có `testCaseId`, cả hai `PASSED`; cột "Kết quả trên bản hiện tại" xanh.
:::

#### TC-04-081 · Ca kiểm thử sai và kết quả cũ hết hiệu lực <!--k:case-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-031 · API-04-044 · ERR-04-030, 006.

**Tiền điều kiện, dữ liệu.** Ca KS-01 đã đạt trên băm cũ.

**Các bước.**

1. Tạo ca không có khẳng định nào.
2. Sửa ca với ETag cũ.
3. Xóa ca không tồn tại.
4. Sửa định nghĩa v4 (đổi băm), xem lại danh sách ca.

**Kết quả mong đợi.** Bước 1 trả `400` ERR-04-049 (`minItems = 1`, VR-20). Bước 2 trả `412` ERR-04-006. Bước 3 trả `404` ERR-04-030. Bước 4: `lastResult.onCurrentHash = false` cho KS-01, nhãn "Cần chạy lại".
:::

### TS-04-14 · Gửi duyệt, rút lại

**Mục tiêu.** Cổng chất lượng trước duyệt: kiểm tra mức `SUBMIT`, chạy thử đạt trên đúng nội dung, catalog hiện hành, phiên bản bất biến sau khi gửi.

**Phủ.** FR-04-040; BR-04-004, 016, 017, 020; UC-04-10; API-04-050, 051; UI-04-14; ERR-04-005, 009, 014, 025, 042; EVT-04-03.

#### TC-04-082 · Gửi duyệt thành công <!--k:submit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-040 · BR-04-004, 016 · API-04-050 · UC-04-10 · EVT-04-03.

**Tiền điều kiện, dữ liệu.** F-HT v4 hợp lệ; một lần `MOCK` `PASSED` trên băm hiện tại; KS-01, KS-02 đạt trên băm hiện tại; IE1, IE2 là người đóng góp.

**Các bước.**

1. IE1 gọi `POST .../versions/4:submit` với `{"changeNote":"Thêm chuẩn hóa họ tên theo QĐ thử","suggestedReviewers":["U-T68-IA1"]}` và `If-Match`.

**Kết quả mong đợi.** `200`, `status = PENDING_REVIEW`, `submittedBy = IE1`, danh sách người đóng góp chụp lại (IE1, IE2). EVT-04-03 phát, PH-18 tạo thông báo cho IA1. `allowedActions` của IE1 chỉ còn `WITHDRAW`. KT: có (`INT_VERSION_SUBMIT`).
:::

#### TC-04-083 · Gửi duyệt khi chưa chạy thử đạt trên đúng băm <!--k:submit-notest-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-040 · BR-04-004 · API-04-050 · ERR-04-014.

**Tiền điều kiện, dữ liệu.** F-HT v4: lần `PASSED` gần nhất ở băm cũ; sau đó sửa một thuộc tính.

**Các bước.**

1. `:submit`.
2. Chạy `MOCK` đạt trên băm mới nhưng KS-02 `FAILED`, `:submit` lại.

**Kết quả mong đợi.** Cả hai trả `409` ERR-04-014; `detail` nêu rõ lý do (chưa có lần đạt trên băm hiện tại, hoặc ca KS-02 chưa đạt).
:::

#### TC-04-084 · Lần chạy mô phỏng không được tính <!--k:sim-not-counted-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-04-040, 030 · BR-04-004 · ERR-04-014.

**Tiền điều kiện, dữ liệu.** F-HT v4 chỉ có lần chạy `SIMULATED` đạt trên băm hiện tại (từ ca sandbox không sẵn sàng); hoặc lần chạy cũ di trú từ W2 có `mode = SIMULATED`.

**Các bước.**

1. `:submit`.

**Kết quả mong đợi.** `409` ERR-04-014. Câu truy vấn kiểm BR-04-004 (SDD §8.4) lọc `mode <> 'SIMULATED'` (kiểm bằng IT với dữ liệu di trú `ph04-9000`).
:::

#### TC-04-085 · Gửi duyệt sai trạng thái, thiếu ghi chú, còn lỗi <!--k:submit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-040 · BR-04-017 · API-04-050 · ERR-04-005, 009, 025.

**Tiền điều kiện, dữ liệu.** v3 `APPROVED`; `tc-con-loi` có VR-05 `ERROR`.

**Các bước.**

1. `:submit` v3.
2. `:submit` F-HT v4 với `changeNote = "sửa"`.
3. `:submit` `tc-con-loi`.

**Kết quả mong đợi.** Lần lượt `409` ERR-04-005, `400` ERR-04-025, `422` ERR-04-009 kèm `findings`. Phiên bản giữ `DRAFT`. EVT: không.
:::

#### TC-04-086 · Rút lại yêu cầu duyệt <!--k:withdraw-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-040 · BR-04-017 · API-04-051.

**Tiền điều kiện, dữ liệu.** F-HT v4 `PENDING_REVIEW`.

**Các bước.**

1. IE1 gọi `:withdraw` với lý do hợp lệ.
2. IE1 lưu nháp.

**Kết quả mong đợi.** Bước 1 trả `200`, `status = DRAFT`; thông báo cho người duyệt được thu hồi. Bước 2 trả `200`. KT: có (`INT_VERSION_WITHDRAW` có lý do).
:::

#### TC-04-087 · Phiên bản đã gửi duyệt không sửa được qua mọi kênh <!--k:submit-immutable-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-040 · BR-04-016 · API-04-022, 027, 044.

**Tiền điều kiện, dữ liệu.** F-HT v4 `PENDING_REVIEW`.

**Các bước.**

1. Lưu nháp.
2. Nhập YAML.
3. Tạo ca kiểm thử mới.
4. Gọi `:discard`.

**Kết quả mong đợi.** Bước 1, 2, 4 trả `409` ERR-04-005. Bước 3 trả `201` (ca kiểm thử gắn luồng, không thuộc phiên bản), nhưng không thay đổi `contentHash` của v4.
:::

### TS-04-15 · Duyệt bốn mắt và so sánh phiên bản

**Mục tiêu.** Không ai tự duyệt được phiên bản mình làm ra, kể cả khi có đủ vai trò. Người duyệt phải xem khác biệt trước khi quyết định. Đây là nhóm ca bắt buộc 100% (thẻ `four-eyes`).

**Phủ.** FR-04-041, 043; BR-04-005, 017; UC-04-11; API-04-025, 052, 053; UI-04-14, 16; ERR-04-005, 015, 025, 044; EVT-04-04, 05.

#### TC-04-088 · Duyệt phiên bản <!--k:approve-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-041 · BR-04-005 · API-04-053, 025, 052 · UI-04-14 · UC-04-11 · EVT-04-04.

**Tiền điều kiện, dữ liệu.** F-HT v4 `PENDING_REVIEW` (người tạo IE1, đóng góp IE2); IA1.

**Các bước.**

1. IA1 gọi `GET /reviews`.
2. IA1 gọi `GET .../versions/4/diff?base=3&markViewed=true`.
3. IA1 gọi `:review` với `{"decision":"APPROVE","comment":"Đúng đặc tả","checklist":{"c1":true,"c2":true,"c3":true,"c4":true}}`.

**Kết quả mong đợi.** Bước 1: có F-HT v4, `canDecide = true`, `changeSummary` đúng. Bước 2 trả `200` với khác biệt theo chặng. Bước 3 trả `200`, `status = APPROVED`, `approvedBy = IA1`; EVT-04-04 phát. KT: có (`INT_VERSION_APPROVE` với checklist).
:::

#### TC-04-089 · Yêu cầu sửa có ý kiến theo chặng <!--k:reqchanges-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-041 · API-04-052 · UI-04-14 · EVT-04-05.

**Tiền điều kiện, dữ liệu.** Như trên.

**Các bước.**

1. IA1 gọi `:review` với `decision = REQUEST_CHANGES`, `comment`, `nodeComments = [{"nodeId":"transform-1","text":"Thiếu chuẩn hóa dấu"}]`.
2. IE1 mở trình thiết kế.

**Kết quả mong đợi.** Bước 1: `status = CHANGES_REQUESTED`; EVT-04-05 phát. Bước 2: chặng `transform-1` có huy hiệu ý kiến, bảng Vấn đề có mục "Ý kiến người duyệt"; phiên bản sửa được.
:::

#### TC-04-090 · Gửi duyệt lại sau khi sửa <!--k:resubmit-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-040, 041 · API-04-050.

**Tiền điều kiện, dữ liệu.** F-HT v4 `CHANGES_REQUESTED`.

**Các bước.**

1. IE1 sửa, chạy thử đạt, `:submit`.

**Kết quả mong đợi.** `200`, `status = PENDING_REVIEW`; lịch sử duyệt giữ ý kiến vòng trước.
:::

#### TC-04-091 · Tự duyệt bị chặn với người tạo, người đóng góp, người gửi <!--k:four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-041 · BR-04-005 · API-04-052 · ERR-04-015.

**Tiền điều kiện, dữ liệu.** Ba phiên bản `PENDING_REVIEW` trong WS-HOTICH: (a) do IA2 tạo; (b) do IE1 tạo, IA2 đóng góp một lần lưu; (c) do IE1 tạo, IA2 gửi duyệt. IA2 có cả vai trò IA và IE.

**Các bước.**

1. IA2 xem diff và `:review` APPROVE trên (a), (b), (c).
2. Xem `GET /reviews` của IA2.

**Kết quả mong đợi.** Bước 1: cả ba trả `403` ERR-04-015, trạng thái không đổi; KT: có (`INT_REVIEW_DENIED`, nhật ký an ninh). Bước 2: ba mục có `canDecide = false`; trên giao diện nút "Duyệt" ẩn kèm lý do.
:::

#### TC-04-092 · Duyệt khi chưa xem so sánh, thiếu checklist, sai trạng thái <!--k:review-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-041, 043 · BR-04-017 · API-04-052 · ERR-04-005, 025.

**Tiền điều kiện, dữ liệu.** F-HT v4 `PENDING_REVIEW`; `tc-nhap` v1 `DRAFT`.

**Các bước.**

1. IA1 `:review` APPROVE khi chưa gọi diff.
2. IA1 xem diff rồi APPROVE thiếu mục `c3`.
3. IA1 REQUEST_CHANGES không có `comment`.
4. IA1 APPROVE `tc-nhap` v1.

**Kết quả mong đợi.** Bước 1 trả `409` ERR-04-005 ("chưa xem so sánh"). Bước 2, 3 trả `400` ERR-04-025. Bước 4 trả `409` ERR-04-005.
:::

#### TC-04-093 · Duyệt bởi người ngoài không gian hoặc thiếu quyền <!--k:review-scope-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-041, 007 · BR-04-021 · ERR-04-003, 045.

**Tiền điều kiện, dữ liệu.** IA thứ ba `U-T68-IA3` không là thành viên WS-HOTICH; IE2 (không có `PERM-04-publish`).

**Các bước.**

1. IA3 `:review` F-HT v4.
2. IE2 `:review` F-HT v4.

**Kết quả mong đợi.** Bước 1 trả `403` ERR-04-003. Bước 2 trả 403-PQ.
:::

#### TC-04-094 · Xác thực lại khi duyệt <!--k:reauth-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-041, 084 · API-04-052 · ERR-04-044.

**Tiền điều kiện, dữ liệu.** `04.review.require-reauth = true`; token của IA1 có `auth_time` cách 10 phút.

**Các bước.**

1. `:review` APPROVE.
2. Trên giao diện, đăng nhập lại trong cửa sổ bật, duyệt lại.

**Kết quả mong đợi.** Bước 1 trả `401` kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300`, `code = ERR-04-044`. Bước 2 trả `200`.
:::

#### TC-04-095 · So sánh hai phiên bản bất kỳ <!--k:diff-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-043 · API-04-025 · UI-04-16.

**Tiền điều kiện, dữ liệu.** F-HT v2, v3, v4.

**Các bước.**

1. Gọi `diff` v4 với `base=2`.
2. Mở UI-04-16 chế độ "Sơ đồ" và "YAML".
3. Gọi `diff` v4 với `base=99`.

**Kết quả mong đợi.** Bước 1: `nodes[]` có `ADDED`, `REMOVED`, `MODIFIED` (kèm `fields`), `MOVED` khi chỉ đổi vị trí trong route; khác biệt bố cục không tính. Bước 2: sơ đồ tô xanh, đỏ, vàng; YAML hai cột cuộn đồng bộ. Bước 3 trả `404` ERR-04-004.
:::

#### TC-04-193 · Đầu cuối gửi duyệt và duyệt bốn mắt theo trình tự SDD <!--k:e2e-review-4eyes-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-04-040, 041 · BR-04-004 · UC-04-10, 11 · API-04-050, 052 · EVT-04-03, 04 · ERR-04-015.

**Tiền điều kiện, dữ liệu.** U-T68-IE1 tạo F-HT v4 và có lần chạy `PASSED` trên `contentHash` hiện tại, mọi ca kiểm thử đạt; U-T68-IA2 là người đóng góp của v4; U-T68-IA1 (D03-02-PH04 §9.1, hình gửi duyệt và duyệt bốn mắt).

**Các bước.**

1. IE1 gọi `:submit` với ghi chú.
2. Đọc `flow_version` và `ph04.outbox`.
3. IA2 mở so sánh rồi gọi `:review` `APPROVE` có đủ checklist.
4. IA1 mở so sánh (`markViewed=true`) rồi gọi `:review` `APPROVE` có đủ checklist.

**Kết quả mong đợi.** Bước 1 trả `200` sau khi kiểm mức `SUBMIT`. Bước 2: `status = PENDING_REVIEW`, `submitted_hash` bằng `contentHash` của lần chạy đạt, một dòng outbox EVT-04-03. Bước 3 trả `403` ERR-04-015 ("Bạn đã tạo, đóng góp hoặc gửi duyệt phiên bản này nên không thể tự duyệt. Cần một người duyệt khác."), phiên bản giữ `PENDING_REVIEW`, không có EVT-04-04. Bước 4 trả `200`, `APPROVED`: máy chủ so băm hiện tại với `submitted_hash`, cập nhật có điều kiện `status = PENDING_REVIEW`, ghi `review`, phát EVT-04-04. Ba chốt ở máy chủ được chứng minh: lần chạy gắn đúng băm, người duyệt ngoài tập người đã chạm phiên bản, băm lúc duyệt bằng băm lúc gửi.
:::

#### TC-04-194 · Trạng thái màn So sánh phiên bản <!--k:ui-diff-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-043 · UI-04-16 · ERR-04-001, 004.

**Tiền điều kiện, dữ liệu.** U-T68-IA1; F-HT v3 và bản sao giống hệt v3 là v5 (tạo trong ca); YAML-200 làm v6; U-T01-IE.

**Các bước.**

1. IA1 mở UI-04-16 với Từ v3, Đến v5.
2. Chọn Đến v99.
3. Chọn Từ v3, Đến v6.
4. U-T01-IE mở URL so sánh của F-HT ở T68.

**Kết quả mong đợi.** Bước 1: trạng thái rỗng "Hai phiên bản giống hệt nhau." Bước 2: ST-05 với câu "Không tìm thấy phiên bản v99 của luồng này." (ERR-04-004). Bước 3: khác biệt hơn 500 dòng YAML nên mặc định chế độ Tóm tắt kèm cảnh báo hiệu năng; skeleton hai canvas và dải tổng "—" trong lúc tải. Bước 4: ST-05 với ERR-04-001, giống hệt trường hợp không tồn tại.
:::

### TS-04-16 · Phát hành GitOps và nâng môi trường

**Mục tiêu.** Chỉ phiên bản `APPROVED` đi vào runtime, và chỉ qua Git. Thứ tự môi trường được giữ. `SYNCED` chỉ khi mọi bản sao báo đúng băm. Nhóm ca bắt buộc 100%.

**Phủ.** FR-04-042, 045; BR-04-012, 018, 019, 022; UC-04-12; API-04-054, 056; UI-04-15; ERR-04-005, 009, 022, 023, 029, 041; EVT-04-06, 07, 12; NFR-04-009.

#### TC-04-096 · Phát hành lên TEST tới SYNCED <!--k:deploy-sync-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO, E2E.

**Truy vết.** FR-04-042 · BR-04-012 · API-04-054 · UI-04-15 · UC-04-12 · EVT-04-06, 07, 12.

**Tiền điều kiện, dữ liệu.** F-HT v4 `APPROVED`; IA1.

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"TEST"}` và `Idempotency-Key`.
2. Mở SSE `.../deployments/{id}/events`.
3. Đọc `env/test` trên Gitea.
4. Gọi luồng qua `apisix-int` môi trường TEST.

**Kết quả mong đợi.** Bước 1 trả `202`, `syncStatus = PENDING`. Bước 2: `PENDING` → `SYNCING` (có `gitCommit`) → `SYNCED` khi mọi bản sao gửi nhịp tim EVT-04-12 có `contentHash` của v4; `healthStatus = HEALTHY`. Bước 3: commit có thông điệp chứa `flow=tra-cuu-ho-tich version=4 by=U-T68-IA1 trace=…`, `flow.dh.yaml` có `version: 4`, có chữ ký trong `.dh/signatures`. Bước 4: phản hồi do v4 sinh. EVT-04-06, 07 phát. KT: có (`INT_DEPLOY_REQUEST`).
:::

#### TC-04-097 · Nâng TEST → STAGING → PROD theo thứ tự <!--k:promote-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-045 · BR-04-019 · API-04-056 · UC-04-12 · NFR-04-009.

**Tiền điều kiện, dữ liệu.** v4 `SYNCED`, `HEALTHY` ở TEST; `04.env.soak-minutes.STAGING = 1` (rút ngắn cho kiểm thử); TA có `PERM-04-promote`.

**Các bước.**

1. TA nâng v4 lên STAGING.
2. Sau 1 phút ổn định, TA nâng lên PROD.
3. Kiểm Gitea: `env/prod` nhận merge request, CI của kho cấu hình chạy, merge.

**Kết quả mong đợi.** Bước 1, 2 trả `202`. Bước 3: merge request có mô tả phiên bản, người duyệt, liên kết so sánh; sau merge, PROD `SYNCED`. Từ lệnh nâng PROD tới `SYNCED` p95 < 3 phút (NFR-04-009). v3 thành `SUPERSEDED` ở PROD.
:::

#### TC-04-098 · Sai thứ tự môi trường, chưa ổn định <!--k:promote-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-042, 045 · BR-04-019 · ERR-04-023.

**Tiền điều kiện, dữ liệu.** `tc-moi` v1 `APPROVED`, chưa triển khai ở đâu; `04.env.soak-minutes.STAGING = 30`.

**Các bước.**

1. Phát hành `tc-moi` v1 thẳng lên PROD.
2. Phát hành lên TEST, chờ `SYNCED`, nâng lên PROD (bỏ qua STAGING).
3. Nâng lên STAGING, ngay lập tức nâng lên PROD.
4. Cho TEST thành `DEGRADED` (đích mô phỏng trả 500), nâng lên STAGING.

**Kết quả mong đợi.** Bước 1, 2, 3, 4 trả `409` ERR-04-023, `detail` nêu môi trường trước và điều kiện còn thiếu (thời gian ổn định còn lại ở bước 3). Git: không cho PROD.
:::

#### TC-04-099 · Chỉ phiên bản đã duyệt được phát hành <!--k:release-draft-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-042 · BR-04-012 · ERR-04-005.

**Tiền điều kiện, dữ liệu.** `tc-nhap` v1 `DRAFT`; F-HT phiên bản `PENDING_REVIEW`.

**Các bước.**

1. IA1 phát hành `tc-nhap` v1 lên TEST.
2. IA1 phát hành phiên bản `PENDING_REVIEW` lên TEST.
3. Dùng tài khoản Git của nhân viên DevOps đẩy trực tiếp một `flow.camel.yaml` không có chữ ký vào `env/test`.

**Kết quả mong đợi.** Bước 1, 2 trả `409` ERR-04-005. Bước 3: CI kho cấu hình (ADR-068) từ chối vì thiếu chữ ký hợp lệ; nếu nhánh bảo vệ bị vượt qua thì `FlowLoader` của runtime từ chối nạp tệp không có chữ ký khớp `contentHash` đã duyệt, ghi `loadError`, phát cảnh báo an ninh PH-13. Luồng không chạy.
:::

#### TC-04-100 · Lỗi ghi Git <!--k:deploy-gitfail-->

::: dac-ta
**Loại.** Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-042 · API-04-054 · ERR-04-022.

**Tiền điều kiện, dữ liệu.** Gitea trả `500` cho mọi lệnh đẩy (Chaos Mesh hoặc WireMock trước Gitea).

**Các bước.**

1. Phát hành F-HT v4 lên TEST.

**Kết quả mong đợi.** `202`; sau ba lần thử lại giãn cách, triển khai `FAILED`, `errorCode = ERR-04-022`; phiên bản vẫn `APPROVED`; nút "Thử lại" có trên UI-04-15. Runtime vẫn chạy phiên bản cũ.
:::

#### TC-04-101 · Quá hạn đồng bộ <!--k:deploy-timeout-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** GO.

**Truy vết.** FR-04-042 · BR-04-018.

**Tiền điều kiện, dữ liệu.** `04.deploy.timeout-minutes = 2`; Argo CD tạm dừng đồng bộ ứng dụng `dh-runtime-t68-test`.

**Các bước.**

1. Phát hành v4 lên TEST, chờ 2 phút.

**Kết quả mong đợi.** `SYNCING` → `FAILED` với lý do lấy từ trạng thái Argo CD ("OutOfSync"); EVT-04-07 phát; thông báo người phát hành.
:::

#### TC-04-102 · Phát hành trong khoảng đóng băng, không có hồ sơ runtime <!--k:deploy-freeze-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-042, 084 · BR-04-022 · ERR-04-041, 029.

**Tiền điều kiện, dữ liệu.** TA đặt khoảng đóng băng 2 giờ tới; `tc-jvm` dùng thành phần chỉ JVM, tenant không được hồ sơ JVM.

**Các bước.**

1. Phát hành F-HT v4 lên PROD.
2. Phát hành F-HT v4 lên TEST.
3. Phát hành `tc-jvm` lên TEST.

**Kết quả mong đợi.** Bước 1 trả `423` ERR-04-041 kèm `until`. Bước 2 trả `202` (đóng băng chỉ chặn PROD). Bước 3 trả `422` ERR-04-029.
:::

#### TC-04-103 · Lệch băm sau khi đồng bộ <!--k:out-of-sync-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** GO.

**Truy vết.** FR-04-042, 051 · BR-04-018 · EVT-04-07, 12.

**Tiền điều kiện, dữ liệu.** v4 `SYNCED` ở TEST; giả lập một bản sao báo nhịp tim với `contentHash` khác (bản sao bị sửa ConfigMap bằng tay).

**Các bước.**

1. Sửa ConfigMap của luồng trong namespace `dh-rt-t68` bằng `kubectl`.
2. Chờ 2 nhịp tim.

**Kết quả mong đợi.** Argo CD tự đưa ConfigMap về bản Git (self-heal). Trong lúc lệch, triển khai `OUT_OF_SYNC`, EVT-04-07 phát; khi khớp lại thì về `SYNCED`. Cảnh báo PH-13 "Cấu hình runtime bị sửa ngoài GitOps".
:::

#### TC-04-195 · Phát hành khi kiểm tra mức PUBLISH còn lỗi hoặc catalog cũ <!--k:deploy-vr-catalog-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-042, 081 · UC-04-12 · API-04-054 · UI-04-15 · ERR-04-009, 042.

**Tiền điều kiện, dữ liệu.** U-T68-IA1; F-HT v4 `APPROVED` nhưng chặng `deliver` dùng topic vừa bị thu hồi quyền (VR-05 mức `PUBLISH` thành `ERROR`); F-SOAP v3 `APPROVED` soạn trên `cv-1` trong khi catalog hiện hành là `cv-2`.

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"TEST"}`.
2. Gọi `POST /flows/bhxh-soap/deployments` với `{"versionNo":3,"environment":"TEST"}`.
3. Lặp bước 1 trên UI-04-15.

**Kết quả mong đợi.** Bước 1 trả `422` ERR-04-009, `findings[]` chỉ chặng `deliver`. Bước 2 trả `409` ERR-04-042, kiểm catalog trước khi chạy đủ quy tắc. Bước 3: hộp thoại "Luồng còn 1 lỗi cần sửa trước khi phát hành." kèm "Mở bảng Vấn đề". Không tạo bản ghi `deployment`. Git: không. EVT: không.
:::

#### TC-04-196 · Đầu cuối phát hành lên PROD tới SYNCED theo trình tự SDD <!--k:e2e-deploy-synced-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GO.

**Truy vết.** FR-04-042, 045 · BR-04-012 · UC-04-12 · API-04-054 · EVT-04-06, 07, 12 · NFR-04-009.

**Tiền điều kiện, dữ liệu.** U-T68-IA1; F-HT v4 `APPROVED`, đã `SYNCED`, `HEALTHY` ở TEST và STAGING đủ thời gian ổn định; nhánh `env/prod` của `dh-flows-t68` được bảo vệ; có thể giữ nhịp tim của runtime PROD 60 giây (D03-02-PH04 §5.5, hình phát hành tới SYNCED).

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"PROD"}` và `Idempotency-Key`.
2. Đọc `deployment`, `ph04.outbox` ngay sau phản hồi.
3. Theo dõi Gitea: nhánh `release/tra-cuu-ho-tich-v4`, yêu cầu gộp, CI của kho.
4. Khi Argo CD báo Application đồng bộ, giữ nhịp tim 60 giây rồi thả.
5. Đọc lại `deployment`.

**Kết quả mong đợi.** Bước 1 trả `202` có `deploymentId`. Bước 2: `deployment` ở `PENDING`, một dòng outbox EVT-04-06 trong cùng giao dịch. Bước 3: commit có chữ ký, tác giả `dh-integration[bot]`, trailer `Dh-Published-By` và `Dh-Deployment: {id}`; yêu cầu gộp vào `env/prod` tự gộp sau khi CI chạy lại VR mức `PUBLISH` và ca kiểm thử. Bước 4: trong lúc giữ nhịp tim, triển khai chỉ ở `SYNCING` dù Argo CD đã báo đồng bộ. Bước 5: sau khi đủ bản sao báo `version = 4` và đúng `contentHash`, triển khai `SYNCED`, phát EVT-04-07. Từ gửi tới `SYNCED` (trừ 60 giây giữ) p95 < 3 phút. KT: có (`INT_DEPLOY_REQUEST`).
:::

### TS-04-17 · Quay lui

**Phủ.** FR-04-044; BR-04-017, 019, 022; UC-04-13; API-04-055; UI-04-15; ERR-04-025, 040.

#### TC-04-104 · Quay lui PROD về phiên bản trước <!--k:rollback-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-044 · API-04-055 · UC-04-13 · EVT-04-06.

**Tiền điều kiện, dữ liệu.** v4 chạy PROD, v3 `SUPERSEDED`; IA1.

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich/deployments:rollback` với `{"environment":"PROD","targetVersionNo":3,"reason":"Tỷ lệ lỗi tăng sau phát hành v4"}`.

**Kết quả mong đợi.** `202`; triển khai `kind = ROLLBACK` không cần duyệt lại và không cần qua STAGING (BR-04-019 trừ quay lui); PROD `SYNCED` với v3; v4 thành `ROLLED_BACK`. KT: có (`INT_ROLLBACK` có lý do).
:::

#### TC-04-105 · Quay lui trong khoảng đóng băng <!--k:rollback-freeze-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-044, 084 · BR-04-022.

**Tiền điều kiện, dữ liệu.** Khoảng đóng băng đang hiệu lực.

**Các bước.**

1. Quay lui PROD về v3.

**Kết quả mong đợi.** `202` (quay lui được phép khi đóng băng).
:::

#### TC-04-106 · Quay lui về phiên bản dùng thành phần nay bị cấm, thiếu lý do <!--k:rollback-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-044 · ERR-04-040, 025, 004.

**Tiền điều kiện, dữ liệu.** F-HT v2 dùng `ftp`, nay T68 cấm `ftp`.

**Các bước.**

1. Quay lui về v2.
2. Quay lui về v3 với `reason = "lỗi"`.
3. Quay lui về v9.

**Kết quả mong đợi.** Lần lượt `409` ERR-04-040 (gợi ý tạm dừng khẩn), `400` ERR-04-025, `404` ERR-04-004.
:::

#### TC-04-107 · Gợi ý quay lui khi tỷ lệ lỗi tăng <!--k:rollback-suggest-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-044, 051 · UI-04-15.

**Tiền điều kiện, dữ liệu.** `04.deploy.rollback-suggest-error-ratio = 2`; sau phát hành v4, đích trả 500 cho 30% lượt (v3 trước đó 5%).

**Các bước.**

1. Mở UI-04-02 sau 5 phút.

**Kết quả mong đợi.** Banner "Tỷ lệ lỗi gấp 6 lần phiên bản trước. Cân nhắc quay lui về v3." với nút "Quay lui". Hệ thống không tự quay lui.
:::

### TS-04-18 · Lệnh runtime có ký: tạm dừng, tiếp tục, dừng khẩn, đối soát

**Mục tiêu.** Thay Start/Stop qua JMX-Jolokia của Bus cũ bằng lệnh có ký, hạn ngắn, xác nhận theo từng bản sao. Mọi trạng thái mong muốn cuối cùng phải về Git. Nhóm ca bắt buộc 100% (thẻ `signed-command`).

**Phủ.** FR-04-050; BR-04-017, 018; UC-04-14, 15; API-04-061; UI-04-02; ERR-04-023, 024, 025; EVT-04-08, 11, 13; NFR-04-010; LGC-BUS-009, 012.

#### TC-04-108 · Tạm dừng một route ở PROD <!--k:pause-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-050 · API-04-061 · UC-04-14 · EVT-04-08, 11, 13 · ERR-04-110 · NFR-04-010 · LGC-BUS-009.

**Tiền điều kiện, dữ liệu.** F-HT v4 chạy PROD, 2 bản sao; U-T68-TO.

**Các bước.**

1. Gọi `POST /flows/tra-cuu-ho-tich/runtime/commands` với `{"environment":"PROD","action":"PAUSE","scope":"ROUTES","routeIds":["tra-cuu-ho-tich-main"],"reason":"Bảo trì HTTT hộ tịch 22:00–23:00","drain":true}`.
2. Theo dõi `GET .../commands/{id}`.
3. Gọi luồng qua APISIX.

**Kết quả mong đợi.** Bước 1 trả `202`, `status = ISSUED`, `expiresAt = issuedAt + 60 giây`. EVT-04-11 có `signature`, `keyId`. Bước 2: hai `acks` `APPLIED`, `status = ACKNOWLEDGED` trong p95 < 10 giây. Bước 3 trả `503` ERR-04-110. EVT-04-08 phát. Trong vòng 5 phút `desiredState` của route được ghi vào Git (`flow.dh.yaml`), lệnh `RECONCILED`. KT: có (`INT_FLOW_PAUSE` có lý do).
:::

#### TC-04-109 · Tiếp tục route <!--k:resume-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-050 · API-04-061 · LGC-BUS-012.

**Tiền điều kiện, dữ liệu.** Route đã tạm dừng ở ca trên.

**Các bước.**

1. TO gửi `RESUME` cùng phạm vi.
2. Gọi luồng.

**Kết quả mong đợi.** `ACKNOWLEDGED`; gọi luồng trả `200`. Bảng route bỏ nhãn "Tạm dừng bởi…".
:::

#### TC-04-110 · Dừng khẩn đi trước Git <!--k:estop-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, GO.

**Truy vết.** FR-04-050 · BR-04-018 · API-04-061 · UC-04-15 · NFR-04-010.

**Tiền điều kiện, dữ liệu.** F-HT PROD; U-T68-SO; Gitea bị làm chậm 30 giây mỗi lệnh đẩy.

**Các bước.**

1. SO gửi `EMERGENCY_STOP`, `scope = FLOW`, `drain = false`, `incidentRef = "SC-2026-001"`.
2. Đo thời gian tới khi cả hai bản sao xác nhận.
3. Chờ đối soát.

**Kết quả mong đợi.** Bước 2: < 5 giây, không phụ thuộc độ chậm của Git. Bản sao đặt `localOverride = true` trong nhịp tim. Bước 3: tiến trình `system:int-reconciler` ghi trạng thái `PAUSED` vào Git trong ≤ 5 phút; khi Git khớp, bản sao bỏ `localOverride`. Argo CD đồng bộ trong lúc đó **không** bật lại luồng. KT: có (`INT_FLOW_EMERGENCY_STOP`, người thực hiện SO và `system:int-reconciler` cho lần ghi Git).
:::

#### TC-04-111 · Đối soát hoàn tất <!--k:reconcile-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GO.

**Truy vết.** FR-04-050 · BR-04-018.

**Tiền điều kiện, dữ liệu.** Lệnh `ACKNOWLEDGED` từ ca tạm dừng.

**Các bước.**

1. Đọc `GET .../commands/{id}` sau 5 phút.
2. Đọc `flow.dh.yaml` trên `env/prod`.

**Kết quả mong đợi.** `status = RECONCILED`, `reconciledAt` ≤ `issuedAt + 5 phút`. Tệp có trạng thái mong muốn của route khớp runtime.
:::

#### TC-04-112 · Một bản sao không xác nhận, gửi lại <!--k:partial-->

::: dac-ta
**Loại.** Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-04-050 · API-04-061 · ERR-04-024.

**Tiền điều kiện, dữ liệu.** Chaos Mesh cắt mạng Kafka của bản sao thứ hai.

**Các bước.**

1. TO gửi `PAUSE`.
2. Sau 30 giây đọc lệnh.
3. Khôi phục mạng, gọi `:resend`.

**Kết quả mong đợi.** Bước 2: `status = PARTIAL`, `ackedReplicas = 1/2`, giao diện liệt kê bản sao chưa xác nhận và nút "Gửi lại lệnh". Bước 3: lệnh mới có `resendOf` = lệnh cũ, chữ ký mới, hạn mới; sau khi đủ xác nhận, lệnh gốc `ACKNOWLEDGED`.
:::

#### TC-04-113 · Lệnh có chữ ký sai <!--k:cmd-badsig-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-050 · EVT-04-11, 13 · ERR-04-024.

**Tiền điều kiện, dữ liệu.** Client Kafka thử có quyền ghi `dh.integration.runtime.command.v1` (giả định kẻ tấn công vượt được ACL).

**Các bước.**

1. Gửi lệnh `EMERGENCY_STOP` với chữ ký Ed25519 sai.
2. Gửi lệnh đúng chữ ký nhưng sửa `flowCode` sau khi ký.

**Kết quả mong đợi.** Runtime không thực thi; gửi ack `REJECTED`, `reason = BAD_SIGNATURE`; luồng vẫn chạy; cảnh báo an ninh mức cao ở PH-13.
:::

#### TC-04-114 · Lệnh hết hạn và lệnh phát lại <!--k:cmd-expired-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-050 · EVT-04-11, 13.

**Tiền điều kiện, dữ liệu.** Một lệnh hợp lệ đã thực thi lúc T; bản ghi Kafka của nó.

**Các bước.**

1. Phát lại bản tin lệnh đó lúc T + 90 giây.
2. Phát lại lúc T + 20 giây.

**Kết quả mong đợi.** Bước 1: `REJECTED`, `reason = EXPIRED`. Bước 2: `REJECTED`, `reason = DUPLICATE` (đã xử lý `commandId`). Không có thay đổi trạng thái route.
:::

#### TC-04-115 · Lệnh mang tenant khác hoặc luồng không tồn tại <!--k:cmd-tenant-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-050, 073 · EVT-04-13.

**Tiền điều kiện, dữ liệu.** Lệnh ký đúng khóa nhưng `tenantId = T01` gửi tới runtime namespace `dh-rt-t68`; lệnh cho `flowCode = khong-co`.

**Các bước.**

1. Gửi hai lệnh.

**Kết quả mong đợi.** Lần lượt `REJECTED` với `TENANT_MISMATCH`, `UNKNOWN_FLOW`. Runtime T68 không thay đổi.
:::

#### TC-04-116 · Lệnh thiếu lý do, sai quyền, môi trường chưa triển khai <!--k:cmd-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-050 · BR-04-017 · API-04-061 · ERR-04-025, 023, 045.

**Tiền điều kiện, dữ liệu.** F-SQL chỉ chạy TEST; TO (không có `PERM-04-emergency-stop`); IE1.

**Các bước.**

1. TO `PAUSE` F-HT với `reason = "bảo trì"`.
2. TO `PAUSE` F-SQL ở PROD.
3. TO `EMERGENCY_STOP` F-HT.
4. IE1 `PAUSE` F-HT.

**Kết quả mong đợi.** Lần lượt `400` ERR-04-025, `409` ERR-04-023, 403-PQ, 403-PQ. EVT: không.
:::

#### TC-04-117 · Tiếp tục sau dừng khẩn chỉ SO hoặc TA <!--k:estop-resume-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-050 · UC-04-15.

**Tiền điều kiện, dữ liệu.** F-HT đang dừng khẩn.

**Các bước.**

1. TO gửi `RESUME`.
2. TA gửi `RESUME`.

**Kết quả mong đợi.** Bước 1 trả 403-PQ với `detail` "Luồng đang dừng khẩn; chỉ cán bộ ATTT hoặc quản trị tenant tiếp tục được" (Q04-47). Bước 2 trả `202`.
:::

#### TC-04-197 · Đầu cuối dừng khẩn ở PROD theo trình tự SDD <!--k:e2e-estop-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** GO, RT.

**Truy vết.** FR-04-050 · BR-04-018 · UC-04-15 · API-04-061 · EVT-04-08, 11, 13 · NFR-04-010.

**Tiền điều kiện, dữ liệu.** U-T68-SO; F-HT PROD hai bản sao, đang có 20 bản tin xử lý dở (WireMock CONN-HT trả chậm 5 giây); theo dõi OpenBao transit, Kafka, `runtime_command`, DLQ PH-18 (D03-02-PH04 §10.2, hình dừng khẩn).

**Các bước.**

1. SO gửi `POST /flows/tra-cuu-ho-tich/runtime/commands` với `{"type":"EMERGENCY_STOP","scope":"FLOW","reason":"Nghi lộ dữ liệu","incidentRef":"SC-2026-002"}`.
2. Đối chiếu thứ tự: lời gọi `transit/sign`, bản tin EVT-04-11, dòng `runtime_command`.
3. Đọc EVT-04-13 của từng bản sao và trạng thái lệnh.
4. Đọc DLQ.
5. Chờ đối soát, đọc `flow.dh.yaml` ở `env/prod`.

**Kết quả mong đợi.** Bước 1 trả `202` có `commandId`. Bước 2: chữ ký tính trên dạng JCS của lệnh; EVT-04-11 gửi với `acks=all` trước khi ghi `runtime_command` `ISSUED` và trước mọi lần ghi Git. Bước 3: mỗi bản sao kiểm chữ ký, hạn, tenant rồi xác nhận `APPLIED`; lệnh `ACKNOWLEDGED` trong < 5 giây. Bước 4: bản tin dở vào DLQ với lý do "dừng khẩn". Bước 5: tác vụ nền ghi `desiredState: PAUSED`, Argo CD áp, nhịp tim khớp; lệnh `RECONCILED`, phát EVT-04-08. KT: có (`INT_FLOW_EMERGENCY_STOP`).
:::

### TS-04-19 · Tình trạng runtime, điểm kết nối, giám sát, lịch sử

**Phủ.** FR-04-051, 052, 053, 083; API-04-060, 062, 063, 091; UI-04-02; ERR-04-047; LGC-BUS-007, 014…019, 030, 033.

#### TC-04-118 · Tình trạng runtime theo môi trường và bản sao <!--k:runtime-status-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-051 · API-04-060 · UI-04-02 · LGC-BUS-014, 015, 017.

**Tiền điều kiện, dữ liệu.** F-HT chạy ba môi trường; một route PROD đang tạm dừng.

**Các bước.**

1. Gọi `GET /flows/tra-cuu-ho-tich/runtime`.
2. Dừng một bản sao PROD (xóa pod), gọi lại sau 70 giây.

**Kết quả mong đợi.** Bước 1: mỗi môi trường có `versionNo`, `syncStatus`, `healthStatus`, `readyReplicas`/`replicas`, `lastHeartbeatAt`; route tạm dừng có `pausedBy`, `pauseReason`. Bước 2: bản sao mất nhịp tim quá 60 giây không còn trong danh sách; `healthStatus = DEGRADED` tới khi pod mới sẵn sàng.
:::

#### TC-04-119 · Lỗi nạp luồng hiển thị cho người vận hành <!--k:load-error-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** GO.

**Truy vết.** FR-04-051 · API-04-060.

**Tiền điều kiện, dữ liệu.** Phát hành `tc-nap-loi` có tham chiếu kết nối mà PH-05 chưa cấp giá trị cho PROD (vượt qua kiểm tra do PH-05 đổi sau khi duyệt).

**Các bước.**

1. Phát hành lên TEST; đọc runtime.

**Kết quả mong đợi.** Triển khai `FAILED`, `loadError` nêu "Không phân giải được {{conn:…}} ở TEST" (không lộ giá trị); các luồng khác trong cùng pod vẫn chạy (lỗi nạp một luồng không làm hỏng context).
:::

#### TC-04-120 · Điểm kết nối và số liệu theo điểm <!--k:endpoints-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-052 · API-04-062 · LGC-BUS-018.

**Tiền điều kiện, dữ liệu.** F-HT PROD có lưu lượng giả lập 1 giờ.

**Các bước.**

1. Gọi `GET .../endpoints?environment=PROD`.
2. IE3 (không thuộc WS-HOTICH) gọi cùng API.

**Kết quả mong đợi.** `items` có một điểm `IN` (`platform-http`, `httpPath`) và các điểm `OUT` (`http` qua CONN-HT, `kafka` topic kiểm toán); `uri` đã che tham số; `metrics` khớp Prometheus trong sai số 1%. Bước 2 trả 404-ẩn.
:::

#### TC-04-121 · Số liệu và lịch sử khi PH-13 không sẵn sàng <!--k:metrics-history-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-053, 083 · API-04-063, 091 · ERR-04-047 · LGC-BUS-007, 033.

**Tiền điều kiện, dữ liệu.** U-T68-AU, U-T68-VW.

**Các bước.**

1. AU gọi `GET .../metrics?environment=PROD&step=1m`.
2. AU gọi `GET .../history?action=INT_DEPLOY_REQUEST`.
3. VW gọi `GET .../history`.
4. Dừng PH-13, AU gọi lại bước 2.

**Kết quả mong đợi.** Bước 1: chuỗi `exchanges`, `failures`, `p95ms`, `dlq`, `dashboardUrl`. Bước 2: các lần triển khai có `before`, `after`. Bước 3: không có `before`, `after`. Bước 4 trả `503` ERR-04-047; các API khác của PH-04 vẫn trả bình thường.
:::

### TS-04-20 · Data plane đồng bộ qua chín chặng

**Mục tiêu.** Luồng đối ngoại F-HT chạy trên `dh-runtime` thật, mỗi chặng chuẩn làm đúng việc và trả đúng mã lỗi ERR-04-101…112 cho bên gọi. Đường đi là HTTT → `apisix-int` → `dh-runtime` → HTTT đích (WireMock).

**Phủ.** FR-04-060, 061, 063, 064, 065, 066, 067, 068, 074; BR-04-002, 010, 013; UC-04-17; ERR-04-101, 102, 103, 104, 105, 107, 108, 109, 111; EVT-04-14; NFR-04-011; LGC-BUS-035, 036, 041.

#### TC-04-122 · Bản tin hợp lệ đi qua đủ chín chặng <!--k:rt-sync-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-04-060, 061, 063, 064, 065, 066, 068, 074 · BR-04-002 · UC-04-17 · EVT-04-14 · LGC-BUS-035.

**Tiền điều kiện, dữ liệu.** F-HT v4 PROD; HTTT `HT-MOT-CUA` (giả lập) có đăng ký sử dụng API ở PH-02; OPA cho phép; PH-07 có bảng chuyển mã.

**Các bước.**

1. Gọi `POST https://apisix-int…/t68/ho-tich/tra-cuu` với MSG-OK, `traceparent`.
2. Đọc vết OpenTelemetry và topic `t68.audit.connection-log.v1`.

**Kết quả mong đợi.** Bước 1 trả `200` với thân đã chuyển CDM, trường `hoTen` được che theo chính sách PH-09 với bên gọi này. Bước 2: vết có span cho đủ chín marker `dh-stage-receive` … `dh-stage-respond` theo đúng thứ tự, cùng `traceId` với bên gọi; EVT-04-14 có `consumerClientId`, `sourceSystem`, `targetSystem`, `outcome = SUCCESS`, `legalBasisRef`, `durationMs`, không có thân bản tin.
:::

#### TC-04-123 · Sai lược đồ và vượt kích thước <!--k:rt-schema-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-04-063, 061 · ERR-04-101, 107.

**Tiền điều kiện, dữ liệu.** MSG-NOID, MSG-RT-BIG; bản tin có 30 trường sai.

**Các bước.**

1. Gọi với MSG-NOID.
2. Gọi với bản tin 30 trường sai.
3. Gọi với MSG-RT-BIG.

**Kết quả mong đợi.** Bước 1 trả `400` ERR-04-101 với `errors[].path = "/soDinhDanh"`, không lặp giá trị nào. Bước 2 trả tối đa 20 lỗi. Bước 3 trả `413` ERR-04-107 trước khi đọc hết thân. Hệ đích không nhận lệnh gọi nào. EVT-04-14 có `outcome = REJECTED`.
:::

#### TC-04-124 · OPA từ chối hoặc không trả lời <!--k:rt-authz-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-064 · ERR-04-102 · LGC-BUS-041.

**Tiền điều kiện, dữ liệu.** Chính sách OPA từ chối `HT-KHAC`; OPA bị làm chậm 300 ms ở bước 2.

**Các bước.**

1. `HT-KHAC` gọi F-HT.
2. `HT-MOT-CUA` gọi khi OPA chậm.

**Kết quả mong đợi.** Cả hai trả `403` ERR-04-102 (đóng khi lỗi, không mở). Đầu vào OPA có `tenant`, `caller`, `subscription`, `flow`, `operation`, `purpose`, `dataClasses`. Không đưa DLQ.
:::

#### TC-04-125 · Lỗi chuyển đổi và làm giàu <!--k:rt-transform-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-065, 066 · ERR-04-108.

**Tiền điều kiện, dữ liệu.** Bản tin có `gioiTinh = "9"` (không có trong bảng chuyển mã, cấu hình `FAIL`); nguồn làm giàu PH-07 trả `500`.

**Các bước.**

1. Gọi với `gioiTinh = "9"`.
2. Gọi khi nguồn làm giàu lỗi.

**Kết quả mong đợi.** Bước 1 trả `422` ERR-04-108. Bước 2 trả `502` ERR-04-104 sau số lần thử lại của chặng `enrich`. Thông điệp lỗi không lộ URL nội bộ.
:::

#### TC-04-126 · Che dữ liệu cá nhân ở phản hồi và log <!--k:rt-mask-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT, IT.

**Truy vết.** FR-04-067, 074 · BR-04-013.

**Tiền điều kiện, dữ liệu.** Chính sách PH-09: `soDinhDanh` che 8 số đầu với bên gọi mục đích `THONG_KE`; log mức DEBUG bật trên runtime.

**Các bước.**

1. Gọi F-HT với mục đích `THONG_KE`.
2. Gọi với mục đích `KHAC` không có trong chính sách.
3. Quét log runtime, vết, chỉ số, EVT-04-14 tìm `001099000001` và `Nguyễn Văn Thử`.

**Kết quả mong đợi.** Bước 1: phản hồi có `soDinhDanh = "********0001"`. Bước 2: mọi trường phân loại Hạn chế, Nhạy cảm bị che toàn bộ (mặc định khi không có quy tắc). Bước 3: không xuất hiện ở bất kỳ nguồn nào, kể cả log DEBUG (log thân bản tin bị chặn bởi `dh-default-config`).
:::

#### TC-04-127 · Đích quá thời gian, lỗi, ngắt mạch <!--k:rt-deliver-->

::: dac-ta
**Loại.** Dương, Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-068, 070 · ERR-04-103, 104, 105.

**Tiền điều kiện, dữ liệu.** WireMock `SLOW_5S` với `04.runtime.sync-timeout-seconds = 3`; `HTTP_500`; `FLAKY_50`.

**Các bước.**

1. Gọi khi đích `SLOW_5S`.
2. Gọi khi đích `HTTP_500`.
3. Gọi 20 lần khi đích `FLAKY_50`, rồi gọi lần 21.
4. Sau 30 giây gọi lại khi đích đã `OK`.

**Kết quả mong đợi.** Bước 1 trả `504` ERR-04-103 sau khoảng 3 giây. Bước 2 trả `502` ERR-04-104 sau đúng số lần thử lại cấu hình, giãn cách lũy thừa. Bước 3: lần 21 trả `503` ERR-04-105 ngay (mạch mở, tỷ lệ lỗi ≥ 50% trên 20 lượt), không gọi đích. Bước 4: nửa mở cho một lượt thử, thành công thì đóng mạch.
:::

#### TC-04-128 · Đường dẫn không khớp route <!--k:rt-404-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** RT.

**Truy vết.** FR-04-061 · ERR-04-111.

**Tiền điều kiện, dữ liệu.** F-HT PROD.

**Các bước.**

1. Gọi `POST …/t68/ho-tich/khong-co`.

**Kết quả mong đợi.** `404` ERR-04-111, thân RFC 9457 không liệt kê các route có sẵn.
:::

#### TC-04-129 · Lỗi nội bộ không lộ chi tiết <!--k:rt-500-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** RT.

**Truy vết.** FR-04-070 · ERR-04-109.

**Tiền điều kiện, dữ liệu.** Luồng thử có chặng ném `NullPointerException`.

**Các bước.**

1. Gọi luồng.

**Kết quả mong đợi.** `500` ERR-04-109, thân chỉ có `title`, `code`, `traceId`; không có tên lớp, ngăn xếp, đường dẫn tệp.
:::

#### TC-04-130 · SOAP qua hồ sơ JVM <!--k:rt-soap-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** RT.

**Truy vết.** FR-04-061, 075 · LGC-BUS-036.

**Tiền điều kiện, dữ liệu.** F-SOAP trên hồ sơ `soap-jvm`; dịch vụ SOAP BHXH giả lập (WireMock SOAP).

**Các bước.**

1. Gọi REST F-SOAP; luồng chuyển sang SOAP 1.1 với WS-Security UsernameToken lấy từ `{{conn:…}}`.

**Kết quả mong đợi.** `200`; bản tin SOAP đúng XSD; mật khẩu WS-Security không có trong log. Pod `soap-jvm` tách khỏi pod `core-native`.
:::

#### TC-04-198 · Gọi đồng bộ khi luồng hoặc route đang tạm dừng <!--k:rt-paused-sync-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-04-050, 061 · UC-04-17 · ERR-04-110.

**Tiền điều kiện, dữ liệu.** F-HT PROD; route `tra-cuu` tạm dừng bằng lệnh `PAUSE` (`scope = ROUTES`), route `kiem-tra-trang-thai` của cùng luồng vẫn chạy; WireMock CONN-HT đếm lượt gọi.

**Các bước.**

1. Gọi `POST /ho-tich/tra-cuu` qua `apisix-int` với MSG-OK.
2. Gọi điểm vào của route `kiem-tra-trang-thai`.
3. Gửi lệnh `RESUME`, đợi `ACKNOWLEDGED`, lặp bước 1.

**Kết quả mong đợi.** Bước 1 trả `503` ERR-04-110 (RFC 9457, `title` "Luồng hoặc route đang tạm dừng"; câu hiển thị "Dịch vụ đang tạm dừng. Thử lại sau."); không có lượt gọi tới WireMock, bản tin không vào DLQ, nhật ký kết nối ghi lượt bị từ chối. Bước 2 trả `200`. Bước 3 trả `200` do v hiện hành sinh.
:::

### TS-04-21 · Data plane bất đồng bộ, xử lý lỗi, chống trùng

**Mục tiêu.** Xác nhận luồng nhận sự kiện Kafka xử lý ít nhất một lần, chống trùng cho kết quả nghiệp vụ một lần, và bản tin lỗi vào DLQ đúng phân loại mà không làm tắc phân vùng.

**Phủ.** FR-04-062, 065, 069, 070, 071; BR-04-008, 009; UC-04-18; ERR-04-101, 106, 108, 109; LGC-BUS-039.

#### TC-04-131 · Nhận sự kiện Kafka, chuyển CDM, phát sự kiện <!--k:rt-async-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-062, 069 · BR-04-009 · UC-04-18 · LGC-BUS-039.

**Tiền điều kiện, dữ liệu.** F-DD PROD; nhóm tiêu thụ `dh-flow-t68-dong-bo-dat-dai`.

**Các bước.**

1. Gửi 100 bản tin vào `t68.datdai.thua-dat.changed.v1`.
2. Đọc `t68.cdm.thua-dat.v1`.

**Kết quả mong đợi.** 100 bản tin CDM, khóa phân vùng theo cấu hình luồng, cùng `traceparent` với bản tin vào. Offset chỉ ghi nhận sau khi gửi thành công (at-least-once).
:::

#### TC-04-132 · Bản tin lỗi vào DLQ <!--k:rt-dlq-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-062, 070 · BR-04-008 · ERR-04-101.

**Tiền điều kiện, dữ liệu.** Một bản tin không phải JSON; một bản tin làm đích lỗi sau 3 lần thử.

**Các bước.**

1. Gửi hai bản tin.
2. Đọc `t68.ops.dlq.v1`.

**Kết quả mong đợi.** Hai bản tin trong DLQ có tiêu đề `dh-dlq-error-code` (ERR-04-101 và ERR-04-104), `dh-flow`, `dh-version`, `dh-dlq-attempts`, `traceparent`. Các bản tin sau đó vẫn được xử lý (không tắc phân vùng). Lỗi giải tuần tự vào DLQ ngay, không thử lại.
:::

#### TC-04-133 · Chống trùng bản tin <!--k:rt-idem-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-071 · ERR-04-106.

**Tiền điều kiện, dữ liệu.** F-HT khai báo khóa chống trùng `Idempotency-Key`; `04.runtime.idempotency-ttl-hours = 24`.

**Các bước.**

1. Gọi F-HT hai lần cùng `Idempotency-Key`.
2. Gọi lần ba cùng khóa sau khi kết quả cũ bị xóa khỏi kho (giả lập vượt 64 KiB, không lưu kết quả).
3. Gửi trùng một bản tin Kafka cho F-DD (cùng `ce_id`).

**Kết quả mong đợi.** Bước 1: lần hai trả đúng kết quả lần một, hệ đích nhận một lệnh gọi. Bước 2 trả `409` ERR-04-106. Bước 3: chỉ một bản tin CDM được phát.
:::

#### TC-04-134 · Topic không có quyền ở runtime <!--k:rt-topic-acl-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT, IT.

**Truy vết.** FR-04-069 · BR-04-009.

**Tiền điều kiện, dữ liệu.** Một luồng đã chạy (giả lập vượt qua kiểm tra tĩnh) cố gửi tới TOPIC-NOACL.

**Các bước.**

1. Kích hoạt lần gửi.

**Kết quả mong đợi.** Kafka từ chối do ACL theo principal của runtime tenant; bản tin vào DLQ với ERR-04-109; cảnh báo PH-13. Chứng minh ràng buộc có hai lớp: kiểm tra tĩnh và ACL Kafka.
:::

#### TC-04-199 · Lỗi nghiệp vụ, dữ liệu ở luồng bất đồng bộ vào DLQ không thử lại <!--k:rt-async-business-err-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-062, 065, 070 · UC-04-18 · BR-04-008 · ERR-04-108, 109.

**Tiền điều kiện, dữ liệu.** F-DD PROD; một bản tin có mã loại đất không có trong bảng ánh xạ PH-07 (cấu hình `FAIL`); một bản tin làm bộ chuẩn hóa CDM ném lỗi không phân loại.

**Các bước.**

1. Gửi hai bản tin vào `t68.datdai.thua-dat.changed.v1`, tiếp theo 10 bản tin hợp lệ.
2. Đọc `t68.ops.dlq.v1` và chỉ số `dh_flow_failures_total`.

**Kết quả mong đợi.** Hai bản tin vào DLQ với `dh-dlq-attempts = 1` (không thử lại): tiêu đề `dh-dlq-error-code` lần lượt ERR-04-108 và ERR-04-109, kèm `dh-flow`, `dh-version`, `traceparent`; trường nhạy cảm đã mã hóa. 10 bản tin hợp lệ vẫn ra `t68.cdm.thua-dat.v1` (không tắc phân vùng). ERR-04-109 sinh cảnh báo PH-13; người vận hành thấy cả hai ở màn DLQ của PH-18.
:::

### TS-04-22 · Truy cập CSDL có kiểm soát (Q359)

**Mục tiêu.** Luồng chỉ đọc được CSDL nguồn theo Q359: tài khoản chỉ đọc riêng theo luồng, chỉ câu lệnh đọc, có giới hạn thời gian và số dòng, có kiểm toán. Nhóm ca bắt buộc 100% (thẻ `q359`).

**Phủ.** FR-04-072; BR-04-015; UC-04-19; ERR-04-013, 031, 108.

#### TC-04-135 · Đọc theo lịch với tham số hóa <!--k:sql-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT, IT.

**Truy vết.** FR-04-072 · BR-04-015 · UC-04-19.

**Tiền điều kiện, dữ liệu.** F-SQL TEST; CSDL nguồn giả lập có 2.500 dòng `dkkd.doanh_nghiep`.

**Các bước.**

1. Kích hoạt lịch.
2. Đọc `pg_stat_activity` và nhật ký kiểm toán.

**Kết quả mong đợi.** Truy vấn chạy bằng `rd_doc_dkkd_sql`, có `SET LOCAL app.tenant_id = 'T68'`, `statement_timeout = 10s`, tham số `$1` (không nối chuỗi). Bản tin kiểm toán có câu lệnh đã chuẩn hóa, số dòng 2.500, không có giá trị dòng.
:::

#### TC-04-136 · Chính sách SQL chặn câu ghi và câu nguy hiểm <!--k:sql-policy-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-04-072, 023 · BR-04-015 · ERR-04-031.

**Tiền điều kiện, dữ liệu.** 18 câu lệnh: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `COPY … TO PROGRAM`, `SELECT pg_sleep(100)`, `SELECT … FOR UPDATE`, `SELECT dblink(…)`, `SELECT lo_import(…)`, hai câu nối bằng `;`, CTE có `DELETE … RETURNING`, câu tham chiếu `ph04.flow`, `SELECT … ${header.x}` (nối chuỗi), `CALL proc()`, `SET ROLE`; và 6 câu hợp lệ (`SELECT`, `WITH … SELECT`, có `$1`).

**Các bước.**

1. Chạy `SqlPolicy` (JSqlParser) trên từng câu.
2. Lưu nháp luồng chứa từng câu, `:validate` mức `DESIGN`.

**Kết quả mong đợi.** 18/18 câu bị chặn với VR-13 `ERROR` và ERR-04-031, `reason` cụ thể; 6/6 câu hợp lệ không báo. Câu không phân tích được bị coi là vi phạm (đóng khi lỗi).
:::

#### TC-04-137 · Kết nối không phải chỉ đọc <!--k:sql-rw-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-04-072 · BR-04-015 · ERR-04-013.

**Tiền điều kiện, dữ liệu.** `tc-sql-rw` dùng CONN-DKKD-RW.

**Các bước.**

1. `:validate` mức `SUBMIT`.
2. Ở RT, cấu hình bỏ qua kiểm tra tĩnh, chạy `SELECT` qua kết nối có `INSERT`, rồi thử `INSERT` bằng cách lồng trong hàm do CSDL nguồn định nghĩa.

**Kết quả mong đợi.** Bước 1: VR-13 `ERROR` với ERR-04-013 ("Kết nối không phải loại chỉ đọc"). Bước 2: Kamelet SQL mở giao dịch `READ ONLY` nên `INSERT` trong hàm bị CSDL từ chối (`25006 read_only_sql_transaction`); bản tin vào DLQ với ERR-04-108.
:::

#### TC-04-138 · Quá thời gian, vượt số dòng <!--k:sql-limits-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** RT.

**Truy vết.** FR-04-072, 084 · ERR-04-108.

**Tiền điều kiện, dữ liệu.** `04.sql.max-rows = 1000`; bảng 2.500 dòng; một câu `SELECT` trên bảng không có chỉ mục chạy 15 giây.

**Các bước.**

1. Chạy câu trả 2.500 dòng.
2. Chạy câu 15 giây.

**Kết quả mong đợi.** Bước 1: dừng ở 1.001 dòng, lỗi ERR-04-108 "vượt số dòng tối đa", không trả kết quả cắt cụt im lặng. Bước 2: CSDL hủy câu sau 10 giây (`57014`), ERR-04-108.
:::

### TS-04-23 · Ngữ cảnh tenant và rò rỉ chéo tenant

**Mục tiêu.** Không có đường nào, ở control plane hay data plane, để dữ liệu của T01 hiện ra với người dùng hoặc luồng của T68, và ngược lại. Mọi ca có thẻ `tenant-leak`, bắt buộc 100%.

**Phủ.** FR-04-073; BR-04-010; D03-10 §6; ERR-04-001, 112.

#### TC-04-139 · Mọi API đọc theo mã trùng giữa hai tenant <!--k:leak-api-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-073, 001, 002 · API-04-010, 012, 020, 024, 025, 026, 041, 042, 044, 054, 060, 062, 063, 091 · ERR-04-001.

**Tiền điều kiện, dữ liệu.** F-HT ở T68 và F-T01 ở T01 cùng mã `tra-cuu-ho-tich`; mỗi bên có phiên bản, lần chạy, ca, triển khai.

**Các bước.**

1. U-T68-TA gọi lần lượt mọi API đọc trong cột truy vết với mã `tra-cuu-ho-tich`.
2. Dùng `runId`, `deploymentId`, `commandId` của T01 trong đường dẫn với token T68.

**Kết quả mong đợi.** Bước 1: mọi phản hồi chỉ có dữ liệu của T68 (không có chuỗi `"tinh":"T01"` ở bất kỳ phản hồi nào). Bước 2: mọi lệnh trả 404-ẩn.
:::

#### TC-04-140 · RLS chặn ở CSDL kể cả khi ứng dụng sai <!--k:leak-rls-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-073.

**Tiền điều kiện, dữ liệu.** Kết nối vai trò `ph04_app`, `SET app.tenant_id = 'T68'`.

**Các bước.**

1. `SELECT count(*)` trên 26 bảng của `ph04` với điều kiện `tenant_id = 'T01'`.
2. `INSERT` một dòng `flow` với `tenant_id = 'T01'`.
3. `UPDATE ph04.component_policy` dòng `PLATFORM` đổi `decision = 'ALLOWED'`.
4. Không đặt `app.tenant_id`, `SELECT count(*) FROM ph04.flow`.

**Kết quả mong đợi.** Bước 1 trả 0 ở mọi bảng mẫu P; bảng mẫu S chỉ trả dòng `COMMON`/`PLATFORM`. Bước 2 bị `WITH CHECK` từ chối. Bước 3 không đổi dòng nào (ràng buộc `ck_component_policy_narrow` và chính sách S). Bước 4 trả 0.
:::

#### TC-04-141 · Bản tin mang tiêu đề tenant giả <!--k:leak-header-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-04-073, 061 · BR-04-010 · ERR-04-112.

**Tiền điều kiện, dữ liệu.** MSG-TENANT.

**Các bước.**

1. Gọi F-HT T68 với tiêu đề `dh-tenant: T01`.
2. Một chặng trong luồng thử (vượt qua kiểm tra tĩnh) đặt `dh-tenant = T01` giữa đường.

**Kết quả mong đợi.** Bước 1: `dh-receive-action` bỏ tiêu đề do bên gọi gửi, đặt `T68` từ ngữ cảnh namespace và token đã APISIX xác minh; luồng chạy bình thường cho T68. Bước 2: `TenantGuard` ở chặng gửi đích phát hiện lệch, trả `500` ERR-04-112, không gọi đích; cảnh báo an ninh mức cao.
:::

#### TC-04-142 · Runtime, topic, kho cấu hình tách theo tenant <!--k:leak-infra-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** GO, IT.

**Truy vết.** FR-04-073, 042.

**Tiền điều kiện, dữ liệu.** SIT có `dh-rt-t68`, `dh-rt-t01`.

**Các bước.**

1. Từ pod `dh-rt-t68`, thử đọc ConfigMap của `dh-rt-t01`.
2. Từ pod `dh-rt-t68`, thử tiêu thụ `t01.hotich.yeucau.v1`.
3. Từ pod `dh-rt-t68`, thử gọi HTTP tới pod `dh-rt-t01`.
4. Dùng token Git của ApplicationSet T68 đẩy vào `dh-flows-t01`.
5. Sandbox chạy lần thử của T68 rồi của T01 trên cùng pod.

**Kết quả mong đợi.** Bước 1 bị RBAC từ chối. Bước 2 bị ACL Kafka từ chối. Bước 3 bị NetworkPolicy chặn. Bước 4 bị Gitea từ chối. Bước 5: lần chạy T01 không thấy bất kỳ tiêu đề, thuộc tính, bộ đệm hay biến nào của lần T68 (mỗi lần chạy một `CamelContext` mới, đã dọn).
:::

### TS-04-24 · Ma trận phân quyền và phạm vi không gian làm việc

**Mục tiêu.** Đối chiếu từng quyền PERM-04-* với từng vai trò theo D02-08, cả chiều cho phép và chiều từ chối.

**Phủ.** FR-04-007 và các FR có quyền; D02-08 §3.1; ERR-04-003, 045.

#### TC-04-143 · Ma trận vai trò × thao tác <!--k:perm-matrix-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-001, 003, 024, 040, 041, 042, 045, 050, 006, 007, 080 · API-04-010, 011, 022, 050, 052, 054, 056, 061, 015, 002, 072.

**Tiền điều kiện, dữ liệu.** Mỗi vai trò PA, PO, TA, TO, SO, IE, IA, VW, AU một người dùng; `04.workspace.enforce = false` để chỉ kiểm quyền chức năng.

**Các bước.**

1. Với mỗi cặp (vai trò, thao tác) trong bảng ngay sau khối này, gọi API tương ứng trên dữ liệu đúng trạng thái.

**Kết quả mong đợi.** Kết quả khớp bảng (✓ thành công, ✗ 403-PQ). Bộ kiểm thử sinh từ D02-08, không viết tay, để lệch ma trận là lỗi kiểm thử.
:::

| Thao tác | PA | PO | TA | TO | SO | IE | IA | VW | AU |
|---|---|---|---|---|---|---|---|---|---|
| Xem luồng (`read`) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tạo luồng (`create`) | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| Lưu nháp, chạy thử (`update`) | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| Gửi duyệt (`submit`) | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| Duyệt, phát hành TEST (`publish`) | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Nâng môi trường (`promote`) | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Tạm dừng (`operate`) | ✗ | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✗ |
| Dừng khẩn (`emergency-stop`) | ✗ | ✗ | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Gỡ luồng đã phát hành (`delete` + `publish`) | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Không gian làm việc (`admin`) | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Chính sách thành phần nền (`catalog-admin`) | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

: Kết quả mong đợi theo vai trò và thao tác của TC-04-143

#### TC-04-144 · Quyền đối tượng không lộ qua danh sách và tìm kiếm <!--k:perm-list-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-001, 007 · BR-04-021 · API-04-010, 053.

**Tiền điều kiện, dữ liệu.** `04.workspace.enforce = true`; IE3 chỉ ở WS-DATDAI.

**Các bước.**

1. IE3 gọi `GET /flows?q=ho tich`, `GET /flows?endpoint=/ho-tich/`, `GET /reviews`.
2. IE3 xem `facets`.

**Kết quả mong đợi.** Không phản hồi nào chứa luồng của WS-HOTICH; `facets` chỉ đếm luồng IE3 xem được (không lộ số lượng luồng ẩn).
:::

#### TC-04-145 · Giao diện ẩn và giải thích hành động bị khóa <!--k:perm-ui-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-04-002 · UI-04-02, 04.

**Tiền điều kiện, dữ liệu.** VW, IE1, IA1 lần lượt mở UI-04-02 của F-HT v4 `DRAFT`.

**Các bước.**

1. So sánh thanh công cụ của ba người.

**Kết quả mong đợi.** Hành động hiển thị khớp đúng `allowedActions` do máy chủ trả; hành động có quyền nhưng sai trạng thái hiện dạng khóa kèm tooltip lấy từ `disabledReasons`; giao diện không tự suy luận quyền (kiểm bằng cách sửa phản hồi giả qua `page.route`).
:::

### TS-04-25 · Catalog, chính sách thành phần, hồ sơ runtime

**Phủ.** FR-04-012, 075, 080, 081; BR-04-014, 020; UC-04-21, 22; API-04-070…074; UI-04-17; ERR-04-011, 029, 035, 042; NFR-04-013.

#### TC-04-146 · Đề xuất cho phép thành phần và quyết định <!--k:proposal-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-080 · API-04-074, 072 · UI-04-17 · UC-04-21.

**Tiền điều kiện, dữ liệu.** `smb` có `policy = DENIED`; IE1, U-PA.

**Các bước.**

1. IE1 tạo đề xuất `ALLOW` `smb` với lý do 50 ký tự.
2. U-PA `:decide` `ACCEPTED`, `policyDecision = PER_FLOW`.
3. IE1 xem `GET /catalog`.

**Kết quả mong đợi.** Bước 1 trả `201`, `status = OPEN`. Bước 2 trả `200`; chính sách nền `smb` thành `PER_FLOW`, `policyVersion` tăng. Bước 3: `smb` hiện với nhãn "Cần duyệt từng luồng". KT: có (`INT_POLICY_CHANGE`).
:::

#### TC-04-147 · Tỉnh chỉ thu hẹp được chính sách <!--k:policy-narrow-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-04-080 · BR-04-014 · API-04-072.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `exec` bị cấm ở nền.

**Các bước.**

1. TA `PATCH /catalog/policies` với `{"changes":[{"kind":"COMPONENT","name":"ftp","decision":"DENIED","reason":"Tỉnh không dùng FTP thường"}]}`.
2. TA `PATCH` với `exec` → `ALLOWED`.
3. TA `PATCH` với `ftp` → `INHERIT`.

**Kết quả mong đợi.** Bước 1 trả `200`. Bước 2 trả 403-PQ (tỉnh không nới chính sách); kể cả khi gọi thẳng CSDL, ràng buộc `ck_component_policy_narrow` chặn. Bước 3 trả `200`, `ftp` theo nền.
:::

#### TC-04-148 · Khớp phiên bản catalog với runtime <!--k:catalog-match-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, CI.

**Truy vết.** FR-04-081 · BR-04-020 · API-04-073.

**Tiền điều kiện, dữ liệu.** Catalog designer 3.33.1 (Camel 4.18.2), runtime Camel Quarkus 3.33.2 (Camel 4.18), đúng trạng thái của mã sau PR #5.

**Các bước.**

1. Gọi `GET /catalog/versions`.
2. Chạy `npm run catalog:check` trong CI với `pom.xml` runtime đổi sang Camel 4.19.

**Kết quả mong đợi.** Bước 1: `match = true`; mỗi hồ sơ có `camelQuarkusVersion`, `camelVersion`, `imageDigest`. Bước 2: job thất bại, chặn hợp nhất, thông điệp nêu hai phiên bản lệch.
:::

#### TC-04-149 · Nâng catalog: luồng soạn trên catalog cũ <!--k:catalog-upgrade-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-081 · BR-04-020 · UC-04-22 · ERR-04-042.

**Tiền điều kiện, dữ liệu.** F-HT v4 soạn trên catalog `cv-1`; PA nâng T68 lên `cv-2`.

**Các bước.**

1. Gọi `GET /catalog/versions`.
2. IE1 `:submit` v4.
3. IE1 mở v4, chọn "Nâng lên danh mục mới", kiểm, gửi lại.

**Kết quả mong đợi.** Bước 1: `pendingUpgrade.affectedFlows ≥ 1` trước khi nâng. Bước 2 trả `409` ERR-04-042. Bước 3: định nghĩa ghi `catalogVersion = cv-2`, kiểm tra lại trên catalog mới, gửi được. `system:int-catalog` đánh dấu luồng bị ảnh hưởng.
:::

#### TC-04-150 · Ảnh native khởi động và nạp luồng <!--k:native-start-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** CI.

**Truy vết.** FR-04-075 · NFR-04-013.

**Tiền điều kiện, dữ liệu.** Ảnh `core-native` dựng ở CI-8.

**Các bước.**

1. Khởi động pod không có luồng, đo tới `/q/health/ready`.
2. Khởi động với 50 ConfigMap luồng.

**Kết quả mong đợi.** Bước 1 < 1 giây. Bước 2 < 5 giây. Ảnh có chữ ký Cosign, SBOM, không có lỗ hổng mức Cao theo Trivy.
:::

#### TC-04-200 · Trạng thái màn Danh mục thành phần <!--k:ui-catalog-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-080 · UI-04-17 · ERR-04-025, 045.

**Tiền điều kiện, dữ liệu.** U-T68-IE1 (không có quyền quản lý chính sách); U-T68-TA.

**Các bước.**

1. IE1 mở UI-04-17, lọc "Native: Không" và tìm "khong-co".
2. IE1 chọn dòng `exec`.
3. TA mở drawer `sftp`, đặt "Không được phép" mà để trống lý do, bấm "Lưu".

**Kết quả mong đợi.** Bước 1: skeleton cây 10 dòng, bảng 8 dòng; sau lọc là ST-04. Bước 2: cột "Được phép" hiện chữ, nút quản lý ẩn; drawer mở bằng `Enter`, đóng bằng `Esc`, `F6` chuyển giữa cây và bảng. Bước 3: ERR-04-025 tại trường lý do, chính sách không đổi. Dòng chân trang hiện phiên bản catalog và "khớp runtime".
:::

### TS-04-26 · Chuyển Camel XML của Bus cũ

**Phủ.** FR-04-082; UC-04-20; API-04-028; UI-04-18; ERR-04-032; LGC-BUS-020…029, LGC-TOOL-001.

#### TC-04-151 · Chuyển gói XML ba route <!--k:legacy-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-04-082 · API-04-028 · UI-04-18 · UC-04-20.

**Tiền điều kiện, dữ liệu.** XML-OK; bảng ánh xạ kết nối cũ → PH-05 (`connectionMap`).

**Các bước.**

1. Gọi `POST /legacy-imports` (multipart) với `file`, `workspaceCode = "ho-tich"`, `connectionMap`.
2. Gọi `GET /legacy-imports/{jobId}` tới khi `COMPLETED`.
3. Mở từng luồng tạo ra.

**Kết quả mong đợi.** Bước 1 trả `202`. Bước 2: `report.routes = 3`, `stepsConverted`, `stepsManual`, `connectionsToDeclare` (kết nối chưa có trong bảng ánh xạ), `recommendations` (ví dụ "Bọc route REST bằng khung chín chặng"); `createdFlows` có 3 mã, mỗi luồng ở `DRAFT`. Bước 3: YAML không còn mật khẩu, URL có thông tin đăng nhập được thay bằng `{{conn:…}}` theo bảng ánh xạ; chặng không chuyển được hiện chặng giữ chỗ màu cảnh báo kèm XML gốc trong ghi chú.
:::

#### TC-04-152 · Tệp XML không hợp lệ hoặc nguy hiểm <!--k:legacy-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-04-082 · API-04-028 · ERR-04-032, 046.

**Tiền điều kiện, dữ liệu.** XML-BAD, XML-EXEC, XML có thực thể ngoài (XXE `<!ENTITY x SYSTEM "file:///etc/passwd">`), tệp 3 MiB, tệp `.exe` đổi tên.

**Các bước.**

1. Tải lần lượt từng tệp.

**Kết quả mong đợi.** XML-BAD trả `422` ERR-04-032. XML-EXEC: chuyển được nhưng `report.forbiddenComponents = ["exec"]`, chặng bị thay bằng giữ chỗ. XXE: `422` ERR-04-032, không đọc tệp hệ thống (parser tắt DTD). 3 MiB trả `413` ERR-04-033. `.exe` trả `415` ERR-04-046.
:::

#### TC-04-201 · Trạng thái màn Nhập luồng hệ cũ <!--k:ui-legacy-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-04-082 · UI-04-18 · ERR-04-032.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; gói XML-OK nén `.zip`; XML-BAD; U-T68-VW.

**Các bước.**

1. IE1 mở UI-04-18 bước ①.
2. Thả gói `.zip` và chờ phân tích.
3. Rời trang giữa lúc phân tích, mở lại từ khay nền.
4. Thả XML-BAD.
5. VW mở URL của UI-04-18.

**Kết quả mong đợi.** Bước 1: dropzone "Kéo tệp XML hoặc ZIP vào đây". Bước 2: "Đang phân tích {k}/{n} route" rồi bảng ba nhóm Tự động, Cần chỉnh, Không chuyển được. Bước 3: ST-10 hỏi trước khi rời, tác vụ vẫn chạy và mở lại đúng kết quả. Bước 4: ST-05 với ERR-04-032. Bước 5: ST-06. Phím `Enter` tiếp tục, `Alt+←` quay lại.
:::

### TS-04-27 · Tham số PH-04 và đóng băng thay đổi

**Phủ.** FR-04-084; BR-04-022; UC-04-01 (mục 7.1); API-04-090; UI-04-20; ERR-04-010, 041; LGC-BUS-031.

#### TC-04-153 · Đọc tham số và đặt khoảng đóng băng <!--k:params-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-04-084 · API-04-090 · UI-04-20 · LGC-BUS-031.

**Tiền điều kiện, dữ liệu.** U-T68-TA.

**Các bước.**

1. Gọi `GET /settings`.
2. Trên UI-04-20 (nhúng màn tham số PH-18), đặt `04.test.max-concurrent = 8`.
3. Đặt khoảng đóng băng 2026-12-30 18:00 tới 2027-01-02 08:00, lý do "Nghỉ Tết dương lịch".

**Kết quả mong đợi.** Bước 1: đủ 23 tham số `04.*` có `value`, `default`, `domain`. Bước 2: có hiệu lực trong 60 giây (lần chạy thử thứ 6 không còn bị 429). Bước 3: `freezeWindows` có khoảng mới; banner đóng băng hiện trên UI-04-15 trong khoảng đó.
:::

#### TC-04-154 · Tham số ngoài miền và ràng buộc không tắt được <!--k:params-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-084.

**Tiền điều kiện, dữ liệu.** U-T68-TA.

**Các bước.**

1. Đặt `04.test.max-concurrent = 21`.
2. Đặt `04.review.require-test = false` khi tenant có luồng đối ngoại.
3. Đặt `04.env.stages = PROD,TEST`.

**Kết quả mong đợi.** Cả ba bị PH-18 từ chối với thông điệp miền; giá trị không đổi.
:::

#### TC-04-155 · Biến môi trường không chứa bí mật <!--k:envvars-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-04-084 · API-04-090 · ERR-04-010.

**Tiền điều kiện, dữ liệu.** U-T68-TA.

**Các bước.**

1. `PUT /settings/env-vars` với `ma-co-quan` có giá trị khác nhau cho TEST, STAGING, PROD.
2. `PUT` với `api-token` có giá trị dạng JWT.

**Kết quả mong đợi.** Bước 1 trả `200`; luồng dùng `{{dh.env.ma-co-quan}}` nhận đúng giá trị theo môi trường. Bước 2 trả `422` ERR-04-010, gợi ý dùng `{{vault:…}}`.
:::

### TS-04-28 · Sự kiện, outbox và hợp đồng API

**Mục tiêu.** Xác nhận sự kiện chỉ phát khi giao dịch thành công, mọi sự kiện và API khớp hợp đồng, và dữ liệu W2 được di trú đúng kể cả khi schema có chủ sở hữu khác.

**Phủ.** FR-04-074 và các FR phát sự kiện; EVT-04-01…14; D03-04-PH04 §4, §7; D03-03-PH04 §4.2 (di trú W2).

#### TC-04-156 · Outbox ghi cùng giao dịch, không phát khi lỗi <!--k:outbox-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** EVT-04-01, 03, 04, 06.

**Tiền điều kiện, dữ liệu.** Testcontainers PostgreSQL, Kafka, Debezium.

**Các bước.**

1. Tạo luồng; kiểm `ph04.outbox` và topic.
2. Gây lỗi sau khi ghi `flow` nhưng trước khi commit (tiêm lỗi ở `FlowService`).

**Kết quả mong đợi.** Bước 1: một dòng outbox, một bản tin CloudEvents trên `t68.integration.flow.created.v1` với tiêu đề `ce_id`, `ce_type`, `ce_source = /tenants/T68/integration`, khóa `T68:{flowId}`. Bước 2: không có dòng luồng, không có dòng outbox, không có bản tin.
:::

#### TC-04-157 · Lược đồ mọi sự kiện khớp AsyncAPI <!--k:events-schema-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** EVT-04-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14.

**Tiền điều kiện, dữ liệu.** Chạy đầy đủ một vòng tạo, sửa, gửi, yêu cầu sửa, duyệt, phát hành, tạm dừng, chạy thử, gỡ.

**Các bước.**

1. Thu mọi bản tin trên 14 topic, kiểm bằng lược đồ trong `asyncapi-integration.yaml`.

**Kết quả mong đợi.** 100% bản tin hợp lệ; không bản tin nào chứa `definitionYaml`, `samples` hay thân bản tin nghiệp vụ.
:::

#### TC-04-158 · Hợp đồng OpenAPI khớp máy chủ <!--k:contract-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, CI.

**Truy vết.** API-04-001, 091.

**Tiền điều kiện, dữ liệu.** `openapi-integration.yaml`; `dh-integration` trên Testcontainers.

**Các bước.**

1. Chạy `ph04/tools/check_contracts.py` (cổng CI-5): mọi ví dụ yêu cầu và phản hồi ở D03-04-PH04 chương 10 phải khớp lược đồ.
2. Chạy Schemathesis (`--checks all`) trên toàn bộ operation với token IE1, IA1, TA, dùng chính các ví dụ ở chương 10 làm dữ liệu ca (pha ví dụ tường minh) trước khi sinh ca ngẫu nhiên.
3. Chạy `oasdiff breaking` so với `main`.

**Kết quả mong đợi.** Bước 1 không có ví dụ nào lệch lược đồ. Không phản hồi nào sai lược đồ, không mã HTTP ngoài khai báo, không lỗi 500. `oasdiff` không báo thay đổi phá vỡ trong `v1`.
:::

#### TC-04-202 · Di trú dữ liệu W2 khi schema do tài khoản khác sở hữu <!--k:migrate-w2-owner-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-011, 030 · BR-04-004 · ERR-04-014 · D03-03-PH04 §4.2.

**Tiền điều kiện, dữ liệu.** Testcontainers PostgreSQL (bản của CI và bản 16.15 như lần chạy thử ở D03-03-PH04 §4.2); schema `ph04` tạo sẵn do `postgres` sở hữu, có bốn bảng W2: một `route` `PUBLISHED`, hai `route_version` `PUBLISHED` và `TESTING`, một `route_test_run`; tài khoản `ph04_owner` không phải chủ schema.

**Các bước.**

1. Chạy changelog Liquibase của `ph04` dưới `ph04_owner`.
2. Đọc `flow`, `flow_version`, `test_run`, danh sách bảng của schema.
3. Chạy lại changelog lần hai.
4. Dưới `ph04_app`, thử cập nhật lần chạy di trú sang `PASSED` và gửi duyệt phiên bản 2.
5. Chạy changelog trên CSDL trống để đối chứng.

**Kết quả mong đợi.** Bước 1: changeset `ph04-0004-legacy-owner` chuyển quyền sở hữu schema và bốn bảng cũ cho `ph04_owner`; không có lỗi "permission denied for schema ph04". Bước 2: luồng `APPROVED`; phiên bản 1 `APPROVED` (người duyệt `system:migrate`), phiên bản 2 `DRAFT`; cả hai `needs_revalidation = true`; lần chạy `mode = SIMULATED`; bốn bảng cũ đổi tên `*_legacy_w2`. Bước 3: không áp thêm changeset, dữ liệu không đổi. Bước 4: ràng buộc chặn `SIMULATED` thành `PASSED`; gửi duyệt trả `409` ERR-04-014 vì chưa có lần chạy thật (BR-04-004). Bước 5: 26 bảng, 25 bảng bật RLS, 100 chính sách.
:::

## 5. Kịch bản kiểm thử phi chức năng

Chương này gom bốn kịch bản phi chức năng: hiệu năng, bảo mật, khả dụng, truy cập. Ngưỡng theo FRS §7.2. Mỗi ca đo hai lần liên tiếp trên PERF; đạt khi cả hai lần đạt. Kết quả ghi vào báo cáo hiệu năng của đợt kèm cấu hình phần cứng.

### TS-04-29 · Hiệu năng

**Mục tiêu.** Chứng minh NFR-04-001…013 ở cấu hình PERF (mục 1.3) với dữ liệu quy mô GĐ; ca có NFR-04-007…013 là P1.

**Phủ.** NFR-04-001…013; FR-04-001, 012, 013, 014, 017, 060, 075.

#### TC-04-159 · Mở bảng thành phần với toàn bộ catalog <!--k:perf-palette-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-001 · UI-04-04.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: Lighthouse trên máy văn phòng chuẩn D05-03, catalog đã ở bộ đệm.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: < 300 ms.
:::

#### TC-04-160 · Gõ tìm trong bảng thành phần <!--k:perf-search-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-002 · FR-04-012.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: 50 lần gõ, `performance.now`.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: < 50 ms mỗi lần.
:::

#### TC-04-161 · Kéo chặng trên sơ đồ 200 chặng <!--k:perf-drag-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-003 · FR-04-013.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: YAML-200, Chrome DevTools trace 10 giây kéo liên tục.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: ≥ 50 khung hình/giây; tối thiểu 30.
:::

#### TC-04-162 · Mở trình thiết kế với luồng 200 chặng <!--k:perf-open-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-004 · UI-04-04.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: YAML-200, Lighthouse TTI.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: < 2 s.
:::

#### TC-04-163 · Sinh lại YAML sau một thay đổi <!--k:perf-regen-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-005 · FR-04-017.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: UT đo 1.000 thay đổi ngẫu nhiên trên YAML-200.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p99 < 100 ms.
:::

#### TC-04-164 · Mở cửa sổ cấu hình chặng 154 thuộc tính <!--k:perf-form-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-04-006 · FR-04-014.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: Thành phần `kafka`.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: < 400 ms.
:::

#### TC-04-165 · Kiểm tra hợp lệ mức SUBMIT <!--k:perf-validate-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-007 · API-04-030.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: k6, 20 người dùng ảo, YAML-200.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 < 2 s.
:::

#### TC-04-166 · Chạy thử MOCK luồng chín chặng <!--k:perf-mock-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-008 · API-04-040.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: k6, 5 lần đồng thời mỗi tenant × 3 tenant, 30 phút.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 < 5 s.
:::

#### TC-04-167 · Từ nâng PROD tới SYNCED <!--k:perf-sync-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-009 · API-04-056.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: 30 lần nâng trên STAGING của PERF.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 < 3 phút.
:::

#### TC-04-168 · Lệnh tạm dừng tới đủ xác nhận <!--k:perf-cmd-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-010 · API-04-061.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: 4 bản sao, 50 lệnh thường, 20 lệnh khẩn.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 < 10 s; khẩn < 5 s.
:::

#### TC-04-169 · Độ trễ thêm của khung chín chặng <!--k:perf-overhead-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-011 · FR-04-060.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: k6 200 yêu cầu/giây, JSON 10 KiB, đích WireMock 20 ms; so với luồng chỉ có `from` và `to`.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 thêm < 15 ms.
:::

#### TC-04-170 · Thông lượng một vCPU runtime native <!--k:perf-throughput-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-012 · FR-04-075.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: k6 tăng dần tới bão hòa, luồng chuyển đổi JSON chuẩn, 1 vCPU.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: ≥ 400 bản tin/giây, lỗi < 0,1%.
:::

#### TC-04-171 · Khởi động pod runtime native <!--k:perf-startup-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-04-013 · FR-04-075.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: 20 lần khởi động, có và không có 50 luồng.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: < 1 s; < 5 s với 50 luồng.
:::

#### TC-04-172 · Danh sách luồng với 300 luồng mỗi tenant <!--k:perf-list-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** FR-04-001 · API-04-010.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3).

**Các bước.**

1. Chạy tải và đo: k6 50 người dùng ảo, lọc và tìm ngẫu nhiên.
2. Lặp lại phép đo lần thứ hai trên cùng cấu hình.

**Kết quả mong đợi.** Đạt ngưỡng ở cả hai lần đo: p95 < 500 ms.
:::

### TS-04-30 · Bảo mật (ASVS)

Ánh xạ tới OWASP ASVS 5.0 và nhóm yêu cầu TCVN 14423:2026 cấp độ 3 theo D03-07. Ca có thẻ `security` chạy hằng tuần và trước mỗi bản phát hành.

#### TC-04-173 · Quét động có xác thực <!--k:zap-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** FR-04-001, 003, 024, 030 · API-04-001, 091.

**Tiền điều kiện, dữ liệu.** ZAP với ngữ cảnh IE1, IA1, TA; nhập `openapi-integration.yaml`.

**Các bước.**

1. Quét chủ động toàn bộ API và UI-04-01…21.

**Kết quả mong đợi.** Không cảnh báo mức Cao; cảnh báo Trung bình có ngoại lệ được SO ký. Tiêu đề `Content-Security-Policy` không có `unsafe-eval` (Monaco chạy với worker, không `eval`).
:::

#### TC-04-174 · Chèn mã qua nội dung luồng và hiển thị <!--k:xss-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-04-002, 013, 014 · UI-04-02, 04, 05.

**Tiền điều kiện, dữ liệu.** Tên luồng, mô tả chặng, ghi chú dán, nhãn, ý kiến duyệt, tên tệp XML đều chứa `<img src=x onerror=alert(1)>` và `{{constructor.constructor('alert(1)')()}}`.

**Các bước.**

1. Lưu và mở mọi màn hiển thị các trường đó.

**Kết quả mong đợi.** Hiển thị nguyên văn, không thực thi; không có hộp thoại (Playwright lắng nghe sự kiện `dialog`).
:::

#### TC-04-175 · Biểu thức không thoát được khỏi sandbox <!--k:expr-escape-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-04-015, 030 · API-04-032, 040.

**Tiền điều kiện, dữ liệu.** Biểu thức `simple` `${bean:java.lang.Runtime?method=getRuntime}`, `${sys.user.home}`, `${env.PATH}`, `jq` `input_filename`, `env`; chặng `exec` trong lần chạy thử.

**Các bước.**

1. Kiểm và đánh giá từng biểu thức qua API-04-032.
2. Chạy thử luồng có các biểu thức đó.

**Kết quả mong đợi.** Kiểm trả lỗi "Không được phép" (VR-16, VR-19); sandbox chạy với `camel.main.bean-introspection` hạn chế, không có biến môi trường của pod, hệ tệp chỉ đọc, không mạng ra ngoài ngoài WireMock (NetworkPolicy `dh-sandbox`).
:::

#### TC-04-176 · Lệnh điều khiển chỉ từ control plane <!--k:cmd-acl-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-04-050 · EVT-04-11.

**Tiền điều kiện, dữ liệu.** Chứng thư mTLS của `dh-runtime` T68.

**Các bước.**

1. Dùng chứng thư runtime ghi vào `dh.integration.runtime.command.v1`.
2. Dùng chứng thư PH-07 đọc topic đó.

**Kết quả mong đợi.** Cả hai bị ACL Kafka từ chối. Khóa ký ở OpenBao không xuất được (`exportable = false`).
:::

#### TC-04-177 · Chuỗi cung ứng ảnh và kho cấu hình <!--k:supply-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** CI.

**Truy vết.** FR-04-075, 042.

**Tiền điều kiện, dữ liệu.** Ảnh `dh-runtime` chưa ký; commit không ký trên `env/prod`.

**Các bước.**

1. Triển khai ảnh chưa ký.
2. Đẩy commit không ký.

**Kết quả mong đợi.** Kyverno chặn ảnh chưa ký. Nhánh `env/prod` được bảo vệ, chỉ nhận merge request qua CI của kho cấu hình.
:::

#### TC-04-178 · Giới hạn tần suất API điều khiển <!--k:ratelimit-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P3.

**Tự động.** k6.

**Truy vết.** FR-04-024 · API-04-022 · ERR-04-048.

**Tiền điều kiện, dữ liệu.** Một người dùng gửi 50 lần lưu nháp mỗi giây.

**Các bước.**

1. Chạy 30 giây.

**Kết quả mong đợi.** Phần vượt nhận `429` ERR-04-048 có `Retry-After`; người dùng khác không bị ảnh hưởng.
:::

### TS-04-31 · Khả dụng và hỗn loạn

#### TC-04-179 · Mất control plane không ảnh hưởng data plane <!--k:chaos-control-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-04-014 · FR-04-061.

**Tiền điều kiện, dữ liệu.** F-HT PROD; k6 100 yêu cầu/giây.

**Các bước.**

1. Xóa toàn bộ pod `dh-integration` và chặn `pg-core` trong 10 phút.

**Kết quả mong đợi.** Gọi luồng vẫn đạt tỷ lệ thành công ≥ 99,9%; runtime không phụ thuộc control plane lúc chạy. Giao diện hiện trang lỗi có mã truy vết; sau khi khôi phục, nhịp tim cập nhật lại tình trạng.
:::

#### TC-04-180 · Mất một bản sao runtime <!--k:chaos-pod-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-04-014 · FR-04-051.

**Tiền điều kiện, dữ liệu.** 2 bản sao, PodDisruptionBudget `minAvailable = 1`.

**Các bước.**

1. Giết một pod mỗi 2 phút trong 20 phút.

**Kết quả mong đợi.** Tỷ lệ lỗi < 0,1%; bản tin bất đồng bộ không mất (so số vào, số ra, số DLQ).
:::

#### TC-04-181 · Mất Kafka tạm thời <!--k:chaos-kafka-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-04-062, 069, 070.

**Tiền điều kiện, dữ liệu.** F-DD đang xử lý 50 bản tin/giây.

**Các bước.**

1. Cắt mạng tới Kafka 2 phút, khôi phục.

**Kết quả mong đợi.** Không mất bản tin, không trùng ở đầu ra (chống trùng theo `ce_id`); luồng đồng bộ không dùng Kafka không bị ảnh hưởng, chặng `audit` đệm cục bộ và gửi bù EVT-04-14.
:::

#### TC-04-182 · Git không sẵn sàng khi đang có lệnh khẩn <!--k:chaos-git-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos, GO.

**Truy vết.** FR-04-050 · BR-04-018.

**Tiền điều kiện, dữ liệu.** Gitea dừng 15 phút.

**Các bước.**

1. SO dừng khẩn F-HT.
2. Khôi phục Gitea sau 15 phút.

**Kết quả mong đợi.** Luồng dừng ngay; cảnh báo "Chưa đối soát được vào Git" sau 5 phút; ghi đè cục bộ giữ nguyên; khi Gitea trở lại, đối soát hoàn tất và lệnh `RECONCILED`.
:::

### TS-04-32 · Truy cập, bàn phím và bề rộng màn hình

#### TC-04-183 · Tạo luồng ba chặng chỉ bằng bàn phím <!--k:a11y-keyboard-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-04-015 · FR-04-013 · UI-04-04.

**Tiền điều kiện, dữ liệu.** IE1 mở `tc-trong` v1.

**Các bước.**

1. Tab tới bảng thành phần, gõ "log", Enter để thêm vào chặng đang chọn.
2. Dùng phím mũi tên chọn chặng kế tiếp, `A` mở hộp thêm chặng, chọn `setHeader`.
3. `Enter` mở cấu hình, điền, `Ctrl+S`.
4. `Shift+F10` mở trình đơn ngữ cảnh, xóa chặng.

**Kết quả mong đợi.** Mọi bước làm được không dùng chuột; viền tiêu điểm luôn thấy rõ (tương phản ≥ 3:1); thứ tự tiêu điểm theo thứ tự chặng; trình đọc màn hình đọc "Chặng 3 trên 9, Chuyển đổi, đã cấu hình".
:::

#### TC-04-184 · Quét axe-core trên mọi màn UI-04 <!--k:a11y-axe-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-04-016 · UI-04-01, 02, 03, 04, 05, 06, 07, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21.

**Tiền điều kiện, dữ liệu.** Giao diện sáng và tối; nền Liquid Glass bật.

**Các bước.**

1. Chạy `@axe-core/playwright` với `wcag22aa` trên từng màn, từng trạng thái ST-01…11.

**Kết quả mong đợi.** Không vi phạm "serious" hoặc "critical". Lớp glass chỉ ở điều hướng và lớp nổi; chữ trên nền nội dung đặc đạt tương phản 4,5:1.
:::

#### TC-04-185 · Bề rộng màn hình <!--k:a11y-width-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** NFR-04-017 · UI-04-04.

**Tiền điều kiện, dữ liệu.** F-HT v4.

**Các bước.**

1. Mở trình thiết kế ở 2560, 1280, 1100, 900 px.

**Kết quả mong đợi.** 2560, 1280: đủ ba vùng (bảng thành phần, sơ đồ, Inspector). 1100: bảng thành phần và Inspector tự gập thành ngăn kéo. 900: chỉ xem YAML, banner "Màn hình quá hẹp để thiết kế"; không cuộn ngang trang.
:::

#### TC-04-186 · Phóng to 200% và giảm chuyển động <!--k:a11y-zoom-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P3.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-04-016 · UI-04-04, 11.

**Tiền điều kiện, dữ liệu.** Trình duyệt phóng 200%; bật `prefers-reduced-motion`.

**Các bước.**

1. Mở trình thiết kế và màn chạy thử.

**Kết quả mong đợi.** Không mất nội dung hay chức năng; hiệu ứng chạy dọc cạnh khi chạy thử tắt, thay bằng đổi màu tĩnh.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi đợt có bốn phiên 90 phút, mỗi phiên một chủ đề:

- trình thiết kế với luồng thật chuyển từ Bus cũ;
- xung đột soạn đồng thời ba người;
- vòng đời đầy đủ từ tạo tới gỡ trên ba môi trường;
- vận hành sự cố (đích lỗi, dừng khẩn, quay lui).

Người kiểm thử ghi nhật ký phiên theo mẫu của D05-01. Phát hiện được chuyển thành ca tự động nếu tái hiện được.

### 6.2. Diễn tập chuyển luồng Bus cũ

Đội di trú thực hiện trên UAT:

1. Trích gói `Context` của Bus cũ của tỉnh thí điểm, gỡ mật khẩu (Q04-49).
2. Chuyển bằng API-04-028.
3. Bổ sung khung chín chặng, chạy thử, duyệt, phát hành TEST.
4. Chạy song song với Bus cũ 7 ngày theo D06-01, so sánh số bản tin và kết quả từng luồng.

Đạt khi 100% luồng ưu tiên chạy đúng và chênh lệch số bản tin bằng 0.

### 6.3. Diễn tập sự cố

Diễn tập sổ tay sự cố D03-07:

- dừng khẩn một luồng PROD khi Git không sẵn sàng (TC-04-182);
- dừng khẩn khi một bản sao không xác nhận, chặn ở mạng (UC-04-15 E3);
- quay lui sau phát hành lỗi.

Đo thời gian từ phát hiện tới luồng dừng, so với ngưỡng 5 phút của D03-07.

### 6.4. Kiểm thử truy cập thủ công

NVDA trên Firefox và VoiceOver trên Safari cho ba luồng:

- tạo luồng từ khuôn;
- cấu hình chặng và biểu thức;
- duyệt có so sánh.

Kiểm thông báo trực tiếp (`aria-live`) khi lưu, khi kiểm tra hợp lệ có lỗi mới, khi lần chạy thử kết thúc.

## 7. Nghiệm thu người dùng tương đương Bus và Tooling

Cán bộ vận hành Bus cũ của tỉnh thí điểm tự thực hiện trên UAT. Mỗi kịch bản đạt khi người thực hiện làm được không cần hướng dẫn ngoài tài liệu người dùng, và kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Tìm chương trình tích hợp theo tên, endpoint, hệ nguồn | LGC-BUS-001…005 | Tìm thấy trong 3 thao tác, có trạng thái từng môi trường | FR-04-001 | Danh sách, tìm theo endpoint (TS-04-02) |
| UAT-02 | Xem chi tiết chương trình, route, endpoint | LGC-BUS-006, 008, 017, 018 | Đủ thông tin như Bus cũ, thêm sơ đồ và phiên bản | FR-04-002, 052 | TS-04-02, 19 |
| UAT-03 | Tạo luồng mới từ khuôn REST và chạy thử | LGC-BUS-013, LGC-TOOL-001 | Luồng chạy thử đạt trong 30 phút với người đã dùng Tooling | FR-04-003, 030 | TS-04-03, 12 |
| UAT-04 | Kéo thả chặng, cấu hình thuộc tính, xem mã | LGC-TOOL-002, 003, 004 | Làm được như Tooling; không phải viết XML | FR-04-012, 013, 014, 017 | TS-04-06, 07 |
| UAT-05 | Viết biểu thức điều kiện và xem kết quả | LGC-TOOL-006 | Biết lỗi ngay khi gõ; xem trước trên bản tin mẫu | FR-04-015 | TS-04-08 |
| UAT-06 | Ánh xạ bản tin hộ tịch sang mẫu dữ liệu chung | LGC-TOOL-008 | Không cần viết JQ tay | FR-04-020 | TS-04-09 |
| UAT-07 | Gửi duyệt, người khác duyệt, phát hành TEST rồi PROD | LGC-BUS-012 | Đi hết quy trình trong một ngày làm việc; mọi bước có lý do và lịch sử | FR-04-040, 041, 042, 045 | TS-04-14, 15, 16 |
| UAT-08 | Tạm dừng và chạy lại một route khi HTTT đích bảo trì | LGC-BUS-009 | Có hiệu lực trong 10 giây, có ghi nhận người, lý do | FR-04-050 | TS-04-18 |
| UAT-09 | Quay lui phiên bản lỗi | — (Bus cũ không có) | Về phiên bản trước trong 3 phút | FR-04-044 | TS-04-17 |
| UAT-10 | Xem số liệu và lịch sử thao tác của luồng | LGC-BUS-007, 014, 015, 019, 033 | Có biểu đồ theo luồng, lịch sử ai làm gì | FR-04-051, 053, 083 | TS-04-19 |
| UAT-11 | Xóa chương trình không còn dùng | LGC-BUS-010 | Hệ thống chặn khi còn phụ thuộc và nói rõ phụ thuộc | FR-04-006 | TS-04-04 |
| UAT-12 | Chuyển một chương trình Camel XML cũ sang hệ mới | LGC-BUS-020…029 | Có báo cáo chặng chuyển được và chặng cần làm tay | FR-04-082 | TS-04-26 |

: Kịch bản nghiệm thu UAT-01…12 tương đương Bus và Tooling

## 8. Ma trận truy vết

Ma trận chứng minh độ phủ theo năm chiều: FR, chức năng hệ cũ, quy tắc nghiệp vụ, mã lỗi và yêu cầu phi chức năng. Toàn bộ mục này do `fill_doc.py` gọi `gen_matrix.py` sinh lại; quy tắc "mỗi FR mức M có ca dương và ca âm" được kiểm ở cột cuối bảng 8.1.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-04. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph04/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-04-001 | Liệt kê luồng, tìm theo tên, endpoint, hệ nguồn, môi trường, | M | LGC-BUS-001, LGC-BUS-002, LGC-BUS-003… | 007, 008, 143 | 009, 143 | 139, 144, 172, 173 | Có |
| FR-04-002 | Xem chi tiết luồng: thông tin, route, endpoint, thuộc tính,  | M | LGC-BUS-006, LGC-BUS-008, LGC-BUS-017… | 010, 012, 145 | 011 | 139, 174 | Có |
| FR-04-003 | Tạo luồng mới từ luồng trống, khuôn mẫu, API trong danh mục  | M | LGC-BUS-013, LGC-TOOL-002 | 013, 014, 015, 016, 020, 143 | 017, 018, 019, 020, 143 | 173 | Có |
| FR-04-004 | Cập nhật thông tin luồng | M | LGC-BUS-006, LGC-BUS-011 | 021 | 022, 028 | — | Có |
| FR-04-005 | Nhân bản luồng | S | mới | 023 | — | — | Có |
| FR-04-006 | Gỡ bỏ luồng có kiểm tra phụ thuộc, xóa bản nháp | M | LGC-BUS-010, LGC-TOOL-016 | 012, 024, 026, 143 | 025, 027, 028, 143 | — | Có |
| FR-04-007 | Quản lý không gian làm việc và thành viên | S | LGC-BUS-032 | 001, 003, 005, 006, 143, 187 | 002, 004, 006, 093, 143, 187 | 144 | Có |
| FR-04-010 | Mở trình thiết kế, phiên soạn thảo và cảnh báo người khác đa | M | LGC-TOOL-001, LGC-TOOL-029 | 029, 033 | 004 | 035 | Có |
| FR-04-011 | Tạo phiên bản mới từ phiên bản đã có | M | LGC-BUS-011 | 032, 202 | 031, 032 | — | Có |
| FR-04-012 | Bảng thành phần theo danh mục được phép, tìm kiếm và lọc the | M | LGC-TOOL-003, LGC-TOOL-004, LGC-TOOL-005… | 037 | 042 | 160 | Có |
| FR-04-013 | Thao tác trên sơ đồ: thêm, chèn, xóa, nối, rẽ nhánh, chọn nh | M | LGC-TOOL-013, LGC-TOOL-017, LGC-TOOL-018… | 038 | 039 | 161, 174, 183 | Có |
| FR-04-014 | Cấu hình chặng bằng biểu mẫu sinh từ catalog, khôi phục giá  | M | LGC-TOOL-019, LGC-TOOL-020 | 040 | 041 | 164, 174 | Có |
| FR-04-015 | Trình soạn biểu thức có gợi ý, kiểm tra cú pháp và xem trước | M | mới | 048 | 049, 189 | 175 | Có |
| FR-04-016 | Chọn kết nối PH-05 và tham chiếu bí mật thay vì nhập bí mật | M | LGC-BUS-041, LGC-TOOL-008 | 050 | 051, 052 | — | Có |
| FR-04-017 | Đồng bộ hai chiều giữa sơ đồ, thuộc tính và YAML, không mất  | M | LGC-TOOL-021, LGC-TOOL-026 | 043, 044, 045 | 044 | 163 | Có |
| FR-04-018 | Soạn Kamelet và gửi đăng ký Kamelet tự viết | S | mới | 057 | 058 | — | Có |
| FR-04-019 | Soạn Pipe | S | mới | 059, 191 | 059, 191 | — | Có |
| FR-04-020 | Trình ánh xạ dữ liệu sinh biểu thức JQ | M | LGC-BUS-036, LGC-TOOL-007, LGC-TOOL-028 | 054 | 055, 190 | 056 | Có |
| FR-04-021 | Bean, cấu hình cấp tệp và metadata | S | mới | 060 | 060 | — | Có |
| FR-04-022 | Ghim bản tin mẫu theo chặng | M | mới | 045, 053 | 053 | — | Có |
| FR-04-023 | Kiểm tra hợp lệ định nghĩa luồng | M | mới | 062, 070 | 051, 052, 063, 064, 065, 066, 067, 068, 069, 136 | — | Có |
| FR-04-024 | Lưu bản nháp tự động, phát hiện xung đột, khôi phục phiên nh | M | LGC-TOOL-014, LGC-TOOL-029 | 029, 033, 143 | 030, 036, 143 | 034, 173, 178 | Có |
| FR-04-025 | Thư viện khuôn mẫu luồng | S | LGC-BUS-013 | 014, 188 | 188 | — | Có |
| FR-04-026 | Ghi chú dán và luồng con dùng lại | C | mới | 045, 061 | — | — | Có |
| FR-04-027 | Tải xuống, nhập YAML và xuất gói luồng | M | LGC-TOOL-015 | 016, 046 | 047 | — | Có |
| FR-04-030 | Chạy thử luồng trên sandbox với đích mô phỏng | M | LGC-BUS-013 | 071, 076, 079, 192, 202 | 072, 073, 076, 084 | 074, 075, 077, 173, 175 | Có |
| FR-04-031 | Ca kiểm thử của luồng và bộ chạy | S | mới | 080 | 081 | — | Có |
| FR-04-032 | Nhật ký chạy thử, xem lại, so sánh hai lần chạy, dọn nhật ký | M | mới | 078, 192 | 072 | — | Có |
| FR-04-033 | Phủ kết quả chạy thử và số liệu chạy thật lên sơ đồ | M | LGC-BUS-022 | 071 | 072 | — | Có |
| FR-04-040 | Gửi duyệt phiên bản | M | mới | 082, 086, 090, 143, 193 | 031, 083, 084, 085, 087, 143, 193 | — | Có |
| FR-04-041 | Duyệt bốn mắt với so sánh YAML và so sánh sơ đồ | M | mới | 088, 089, 090, 143, 193 | 091, 092, 093, 143, 193 | 094 | Có |
| FR-04-042 | Phát hành qua GitOps và theo dõi tình trạng triển khai | M | LGC-BUS-033, LGC-BUS-034 | 096, 143, 196 | 098, 099, 100, 101, 102, 143, 195 | 103, 142, 177 | Có |
| FR-04-043 | So sánh hai phiên bản bất kỳ | M | LGC-BUS-023 | 095, 194 | 092, 194 | — | Có |
| FR-04-044 | Quay lui về phiên bản trước | M | mới | 104, 105, 107 | 106 | — | Có |
| FR-04-045 | Thăng cấp phiên bản qua các môi trường | S | mới | 097, 143, 196 | 098, 143 | — | Có |
| FR-04-050 | Kích hoạt, tạm dừng, tiếp tục luồng và từng route có lý do | M | LGC-BUS-009, LGC-BUS-012, LGC-BUS-026 | 108, 109, 110, 111, 143, 197 | 112, 116, 117, 143, 198 | 113, 114, 115, 176, 182 | Có |
| FR-04-051 | Xem tình trạng runtime của luồng | M | LGC-BUS-014, LGC-BUS-015, LGC-BUS-017… | 107, 118 | 119 | 103, 180 | Có |
| FR-04-052 | Danh sách điểm kết nối của luồng và số liệu theo điểm kết nố | M | LGC-BUS-020, LGC-BUS-027, LGC-BUS-028 | 120 | 120 | — | Có |
| FR-04-053 | Giám sát theo luồng nhúng từ PH-13 | S | LGC-BUS-007, LGC-BUS-015, LGC-BUS-016… | 121 | 121 | — | Có |
| FR-04-060 | Khung chín chặng chuẩn và thư viện nền | M | LGC-BUS-035, LGC-BUS-036, LGC-BUS-037… | 122 | 063 | 169 | Có |
| FR-04-061 | Tiếp nhận đồng bộ HTTP và SOAP qua APISIX | M | LGC-BUS-039 | 122, 130, 141 | 123, 128, 141, 198 | 179 | Có |
| FR-04-062 | Tiếp nhận bất đồng bộ từ Kafka | M | LGC-BUS-039 | 131 | 132, 199 | 181 | Có |
| FR-04-063 | Kiểm tra lược đồ bản tin | M | LGC-BUS-036 | 122 | 123 | — | Có |
| FR-04-064 | Ủy quyền qua OPA | M | LGC-BUS-041 | 122 | 124 | — | Có |
| FR-04-065 | Chuyển đổi, chuẩn hóa về CDM và chuyển mã qua PH-07 | M | LGC-BUS-036 | 054, 122 | 125, 199 | — | Có |
| FR-04-066 | Làm giàu bản tin | M | mới | 122 | 125 | — | Có |
| FR-04-067 | Che, giả danh dữ liệu cá nhân theo chính sách PH-09 | M | LGC-TOOL-012 | 126 | 126 | — | Có |
| FR-04-068 | Định tuyến theo nội dung, tách, gộp, gọi song song, gửi đích | M | LGC-BUS-035 | 122, 127 | 069, 127 | — | Có |
| FR-04-069 | Phát sự kiện ra Kafka | M | LGC-BUS-039 | 131 | 065 | 134, 181 | Có |
| FR-04-070 | Xử lý lỗi chuẩn: phân loại, thử lại, ngắt mạch, DLQ, dự phòn | M | LGC-BUS-037 | 127 | 066, 127, 129, 132, 199 | 181 | Có |
| FR-04-071 | Chống trùng bản tin | M | mới | 133 | 133 | — | Có |
| FR-04-072 | Truy cập CSDL trực tiếp có kiểm soát (Q359) | M | LGC-BUS-040, LGC-TOOL-008 | 135 | 136, 137 | 138 | Có |
| FR-04-073 | Ngữ cảnh tenant trên mỗi bản tin | M | mới | 141 | 067, 141 | 115, 139, 140, 142 | Có |
| FR-04-074 | Vết, chỉ số, log và nhật ký kết nối | M | LGC-BUS-030, LGC-BUS-038 | 122, 126 | 126 | — | Có |
| FR-04-075 | Hồ sơ runtime, biên dịch native và chế độ JVM | M | LGC-BUS-034 | 130 | 068 | 150, 170, 171, 177 | Có |
| FR-04-080 | Danh mục thành phần và chính sách thành phần được phép | M | LGC-BUS-034, LGC-BUS-040 | 037, 143, 146, 200 | 042, 143, 147, 200 | — | Có |
| FR-04-081 | Khớp phiên bản catalog với runtime | M | mới | 148 | 069, 148, 149, 195 | 035 | Có |
| FR-04-082 | Chuyển luồng Camel XML của Bus cũ sang YAML | M | LGC-BUS-033, LGC-TOOL-015 | 151, 201 | 152, 201 | — | Có |
| FR-04-083 | Lịch sử thao tác và kiểm toán của luồng | M | LGC-BUS-032, LGC-BUS-033 | 121 | 121 | — | Có |
| FR-04-084 | Tham số PH-04 theo tenant và đóng băng thay đổi | S | LGC-BUS-031 | 005, 020, 105, 153, 155 | 020, 036, 102, 154, 155 | 056, 075, 094, 138 | Có |

: Ma trận yêu cầu chức năng → test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của Bus tích hợp (`LGC-BUS`) và Productivity Tooling (`LGC-TOOL`) được truy tới FR mới và tới ca tự động, ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-BUS-001 | 001 | 007 | UAT-01 |
| LGC-BUS-002 | 001 | 008 | UAT-01 |
| LGC-BUS-003 | 001 | 007 | UAT-01 |
| LGC-BUS-004 | 001 | 007 | UAT-01 |
| LGC-BUS-005 | 001 | 007 | UAT-01 |
| LGC-BUS-006 | 002, 004 | 010, 021 | UAT-02 |
| LGC-BUS-007 | 053 | 121 | UAT-10 |
| LGC-BUS-008 | 002 | 010 | UAT-02 |
| LGC-BUS-009 | 050 | 108, 109, 110, 111, 143, 197 | UAT-08 |
| LGC-BUS-010 | 006 | 012, 024, 026, 143 | UAT-11 |
| LGC-BUS-011 | 004, 011 | 021, 032, 202 | — |
| LGC-BUS-012 | 050 | 026, 108, 109, 110, 111, 143, 197 | UAT-07 |
| LGC-BUS-013 | 003, 025, 030 | 013, 014, 015, 016, 020, 071, 076, 079 (+4) | UAT-03 |
| LGC-BUS-014 | 051 | 118 | UAT-10 |
| LGC-BUS-015 | 051, 053 | 118 | UAT-10 |
| LGC-BUS-016 | 053 | — | — |
| LGC-BUS-017 | 002, 051 | 010, 118 | UAT-02 |
| LGC-BUS-018 | 002 | 010, 120 | UAT-02 |
| LGC-BUS-019 | 053 | — | UAT-10 |
| LGC-BUS-020 | 002, 052 | 120 | UAT-12 |
| LGC-BUS-021 | 002 | — | UAT-12 |
| LGC-BUS-022 | 002, 033 | 071 | UAT-12 |
| LGC-BUS-023 | 002, 043 | 095, 194 | UAT-12 |
| LGC-BUS-024 | 002 | — | UAT-12 |
| LGC-BUS-025 | 001, 002, 051 | — | UAT-12 |
| LGC-BUS-026 | 050 | 108, 109, 110, 111, 143, 197 | UAT-12 |
| LGC-BUS-027 | 052 | 120 | UAT-12 |
| LGC-BUS-028 | 051, 052 | 120 | UAT-12 |
| LGC-BUS-029 | 053 | — | UAT-12 |
| LGC-BUS-030 | 074 | 122, 126 | — |
| LGC-BUS-031 | 084 | 005, 020, 105, 153, 155 | — |
| LGC-BUS-032 | 007, 083 | 001, 003, 005, 006, 121, 143, 187 | — |
| LGC-BUS-033 | 042, 082, 083 | 096, 121, 143, 151, 196, 201 | UAT-10 |
| LGC-BUS-034 | 042, 075, 080 | 037, 096, 130, 143, 146, 196, 200 | — |
| LGC-BUS-035 | 060, 068 | 122, 127 | — |
| LGC-BUS-036 | 020, 060, 063, 065 | 054, 122, 130 | — |
| LGC-BUS-037 | 060, 070 | 127 | — |
| LGC-BUS-038 | 060, 074 | 122, 126 | — |
| LGC-BUS-039 | 060, 061, 062, 069 | 122, 130, 131, 141 | — |
| LGC-BUS-040 | 072, 080 | 037, 135, 143, 146, 200 | — |
| LGC-BUS-041 | 016, 064 | 050, 122, 124 | — |
| LGC-TOOL-001 | 001, 010 | 029, 033 | UAT-03 |
| LGC-TOOL-002 | 003 | 013, 014, 015, 016, 020, 037, 143 | UAT-04 |
| LGC-TOOL-003 | 012 | 038 | UAT-04 |
| LGC-TOOL-004 | 012 | 038 | UAT-04 |
| LGC-TOOL-005 | 012 | — | — |
| LGC-TOOL-006 | 012 | 048 | UAT-05 |
| LGC-TOOL-007 | 012, 020 | 054 | — |
| LGC-TOOL-008 | 012, 016, 072 | 050, 054, 135 | UAT-06 |
| LGC-TOOL-009 | 012 | — | — |
| LGC-TOOL-010 | 012 | — | — |
| LGC-TOOL-011 | 012 | — | — |
| LGC-TOOL-012 | 012, 067 | 126 | — |
| LGC-TOOL-013 | 013 | — | — |
| LGC-TOOL-014 | 024 | 029, 033, 143 | — |
| LGC-TOOL-015 | 027, 082 | 016, 046, 151, 201 | — |
| LGC-TOOL-016 | 006 | 012, 024, 026, 143 | — |
| LGC-TOOL-017 | 013 | — | — |
| LGC-TOOL-018 | 013 | — | — |
| LGC-TOOL-019 | 014 | 040 | — |
| LGC-TOOL-020 | 014 | 040 | — |
| LGC-TOOL-021 | 017 | 043, 044, 045 | — |
| LGC-TOOL-023 | 013 | — | — |
| LGC-TOOL-024 | 013 | — | — |
| LGC-TOOL-025 | 013 | — | — |
| LGC-TOOL-026 | 017 | 043, 044, 045 | — |
| LGC-TOOL-028 | 020 | 054 | — |
| LGC-TOOL-029 | 010, 024 | 029, 033, 143 | — |

: Ma trận chức năng hệ cũ → yêu cầu → test case

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-04-001 | 017 |
| BR-04-002 | 039, 063, 122 |
| BR-04-003 | 018, 050, 051, 058 |
| BR-04-004 | 077, 082, 083, 084, 193, 202 |
| BR-04-005 | 088, 091 |
| BR-04-006 | 043 |
| BR-04-007 | 029, 045, 053, 061 |
| BR-04-008 | 066, 132, 199 |
| BR-04-009 | 065, 131, 134 |
| BR-04-010 | 067, 141 |
| BR-04-011 | 023, 064 |
| BR-04-012 | 096, 099, 196 |
| BR-04-013 | 053, 078, 126 |
| BR-04-014 | 037, 042, 068, 147 |
| BR-04-015 | 135, 136, 137 |
| BR-04-016 | 024, 031, 032, 082, 087 |
| BR-04-017 | 026, 027, 085, 086, 092, 116 |
| BR-04-018 | 101, 103, 110, 111, 182, 197 |
| BR-04-019 | 097, 098 |
| BR-04-020 | 069, 148, 149 |
| BR-04-021 | 003, 004, 005, 093, 144 |
| BR-04-022 | 036, 102, 105 |

: Ma trận quy tắc nghiệp vụ → test case

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-04-001 | 011, 139, 191, 194 |
| ERR-04-002 | 017 |
| ERR-04-003 | 004, 022, 093 |
| ERR-04-004 | 030, 032, 106, 194 |
| ERR-04-005 | 025, 027, 031, 076, 085, 092, 099 |
| ERR-04-006 | 022, 030, 033, 081 |
| ERR-04-007 | 022, 030 |
| ERR-04-008 | 018, 030, 047 |
| ERR-04-009 | 018, 047, 073, 085, 195 |
| ERR-04-010 | 018, 030, 051, 155 |
| ERR-04-011 | 042, 060, 068, 191 |
| ERR-04-012 | 063 |
| ERR-04-013 | 052, 073, 137 |
| ERR-04-014 | 083, 084, 202 |
| ERR-04-015 | 091, 193 |
| ERR-04-016 | 032 |
| ERR-04-017 | 006, 027, 187 |
| ERR-04-018 | 019 |
| ERR-04-019 | 049, 075, 077, 189, 190 |
| ERR-04-020 | 074 |
| ERR-04-021 | 049, 055, 073 |
| ERR-04-022 | 100 |
| ERR-04-023 | 098, 116 |
| ERR-04-024 | 112, 113 |
| ERR-04-025 | 027, 085, 092, 106, 116, 200 |
| ERR-04-026 | 009 |
| ERR-04-027 | 002, 006, 018, 187 |
| ERR-04-028 | 002, 187 |
| ERR-04-029 | 058, 068, 102 |
| ERR-04-030 | 081 |
| ERR-04-031 | 136 |
| ERR-04-032 | 152, 201 |
| ERR-04-033 | 018, 030, 047 |
| ERR-04-034 | 028 |
| ERR-04-035 | 041 |
| ERR-04-036 | 058 |
| ERR-04-037 | 049 |
| ERR-04-038 | 055 |
| ERR-04-039 | 018, 188 |
| ERR-04-040 | 106 |
| ERR-04-041 | 036, 102 |
| ERR-04-042 | 069, 149, 195 |
| ERR-04-043 | 069 |
| ERR-04-044 | 094 |
| ERR-04-045 | 093, 116, 187, 188, 200 |
| ERR-04-046 | 152 |
| ERR-04-047 | 121 |
| ERR-04-048 | 178 |
| ERR-04-049 | 009, 017 |
| ERR-04-101 | 123, 132 |
| ERR-04-102 | 124 |
| ERR-04-103 | 127 |
| ERR-04-104 | 127 |
| ERR-04-105 | 127 |
| ERR-04-106 | 133 |
| ERR-04-107 | 123 |
| ERR-04-108 | 125, 138, 199 |
| ERR-04-109 | 129, 199 |
| ERR-04-110 | 108, 198 |
| ERR-04-111 | 128 |
| ERR-04-112 | 141 |

: Ma trận mã lỗi → test case

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-04-001 | 159 |
| NFR-04-002 | 160 |
| NFR-04-003 | 161 |
| NFR-04-004 | 162 |
| NFR-04-005 | 163 |
| NFR-04-006 | 164 |
| NFR-04-007 | 070, 165 |
| NFR-04-008 | 071, 166, 192 |
| NFR-04-009 | 097, 167, 196 |
| NFR-04-010 | 108, 110, 168, 197 |
| NFR-04-011 | 169 |
| NFR-04-012 | 170 |
| NFR-04-013 | 150, 171 |
| NFR-04-014 | 179, 180 |
| NFR-04-015 | 034, 183 |
| NFR-04-016 | 184, 186 |
| NFR-04-017 | 185 |

: Ma trận yêu cầu phi chức năng → test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

Chương này nói ca tự động nằm ở đâu, gắn với mã ca thế nào, đưa ba mẫu mã cho nhóm ca bắt buộc và cách sinh lại ma trận, Gherkin, bảng tính từ tài liệu.

### 9.1. Tổ chức mã kiểm thử

| Thư mục | Nội dung |
|---|---|
| `apps/integration/src/test/java/vn/datahub/integration/flow/` | UT, IT theo package; lớp cơ sở `IntegrationFlowTestBase` |
| `apps/integration/src/test/resources/vr/`, `roundtrip/` | Bộ YAML cho VR-01…20 và quay vòng |
| `apps/runtime/src/test/java/…` | RT trên `@QuarkusTest`, luồng mẫu trong `src/test/resources/flows/` |
| `apps/console/src/features/integration/**/*.test.ts` | UT frontend |
| `e2e/integration/*.spec.ts` | Playwright; tệp theo kịch bản `ts-04-nn.spec.ts` |
| `perf/integration/*.js` | k6 |
| `datahub-docs/05-kiem-thu/test-case/ph04/gherkin/` | Gherkin sinh từ tài liệu này |

: Thư mục mã kiểm thử

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-04-031")`, `test('TC-04-031 …')`) để báo cáo đối chiếu với ma trận.

### 9.2. Mẫu ca bốn mắt (JUnit, REST Assured)

```java
@Tag("four-eyes") @Tag("TC-04-091")
@ParameterizedTest
@MethodSource("selfReviewCases") // người tạo, người đóng góp, người gửi
void selfReviewIsRejected(String versionRef) {
  var v = fixtures.pendingVersion(versionRef);           // trạng thái PENDING_REVIEW
  api.as(U_T68_IA2).get(v.diffUrl() + "?markViewed=true").then().statusCode(200);
  api.as(U_T68_IA2)
     .header("If-Match", v.etag())
     .body(Map.of("decision", "APPROVE", "comment", "ok", "checklist", fullChecklist()))
     .post(v.url() + ":review")
     .then().statusCode(403).body("code", equalTo("ERR-04-015"));
  assertThat(repo.version(v.id()).status()).isEqualTo(PENDING_REVIEW);
  assertThat(outbox.since(v.at())).noneMatch(e -> e.type().endsWith("version.approved.v1"));
}
```

### 9.3. Mẫu ca tiêu đề tenant giả (Camel trên Quarkus)

```java
@QuarkusTest @Tag("tenant-leak")
class TenantHeaderSpoofTest {
  @Inject ProducerTemplate producer;
  @Test void callerSuppliedTenantHeaderIsIgnored() {
    var resp = producer.request("platform-http:/ho-tich/tra-cuu", ex -> {
      ex.getIn().setHeader("dh-tenant", "T01");               // bên gọi cố đặt
      ex.getIn().setBody(Fixtures.MSG_OK);
    });
    assertThat(resp.getMessage().getHeader("dh-tenant")).isEqualTo("T68");
    wireMock.verify(postRequestedFor(urlEqualTo("/test/ho-tich")).withHeader("X-Tenant", equalTo("T68")));
  }
}
```

### 9.4. Mẫu ca kéo thả (Playwright)

```ts
test('TC-04-038 chèn chặng log giữa transform và enrich', async ({ page }) => {
  await page.goto('/integration/flows/tc-trong/versions/1/designer');
  const src = page.getByRole('option', { name: 'log' });
  const gap = page.getByTestId('edge-dh-stage-transform-dh-stage-enrich');
  await src.dragTo(gap);
  await expect(page.getByRole('treeitem', { name: /log/ })).toBeVisible();
  await page.getByRole('tab', { name: 'YAML' }).click();
  await expect(page.locator('.monaco-editor')).toContainText('- log:');
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

`ph04/tools/` có năm script, chạy từ thư mục `05-kiem-thu/test-case/ph04/tools` theo thứ tự:

1. `number_tcs.py`: cấp số TC-04-nnn cho ca mới (viết tạm là `TC-04-` và ba dấu thăng, kèm khóa `<!--k:…-->`) theo thứ tự xuất hiện. Thay mọi tham chiếu `[[tc:khóa]]` bằng số. Số đã cấp không đổi.
2. `fill_doc.py`: ghi số kịch bản, số ca ở phần tóm tắt, cột "Số ca" của bảng 3.1, bảng danh sách test case 3.3 và toàn bộ mục 8 (gọi `gen_matrix.py`).
3. `gen_matrix.py`: sinh mục 8; in ra stderr BR, ERR, NFR chưa có ca.
4. `gen_gherkin.py`: sinh `ph04/gherkin/*.feature`.
5. `gen_xlsx.py`: sinh `ph04/D05-02-PH04-test-case.xlsx` cho đội kiểm thử ghi kết quả.

Các script dùng chung `tc_parse.py`, đọc được cả khối đặc tả `::: dac-ta` (bản 0.2) và dạng gạch đầu dòng cũ (bản 0.1), cùng cách làm với PH-05, PH-07.

## 10. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q04-40 | Môi trường SIT có đủ tài nguyên cho Argo CD và ba namespace runtime mỗi tenant (TEST, STAGING, PROD gộp trong k3d) không | Gộp TEST và STAGING trong một cụm k3d, phân biệt bằng namespace; PROD giả lập ở cụm thứ hai |
| Q04-41 | Thiết bị chuẩn để đo NFR-04-001…006 (máy văn phòng D05-03) chưa chốt cấu hình | Giả định GĐ: 4 nhân, 8 GiB RAM, Chrome bản ổn định mới nhất, màn 1920×1080 |
| Q04-42 | Ai cung cấp gói XML Bus cũ đã gỡ mật khẩu cho diễn tập 6.2 | Đội vận hành Bus cũ của tỉnh thí điểm, có biên bản bàn giao |
| Q04-43 | Có cần ca kiểm thử với NDXP môi trường thử nghiệm thật (liên quan Q04-48) | Chưa; dùng WireMock tới khi NDXP cấp môi trường thử cho tỉnh |
| Q04-44 | Ngưỡng thông lượng NFR-04-012 đo với luồng nào là "chuyển đổi JSON chuẩn" | Luồng mẫu `perf-json-transform` trong `apps/runtime/src/test/resources/flows/`: nhận REST, JQ 20 trường, gửi WireMock |

: Câu hỏi mở về kiểm thử PH-04

## 11. Đề nghị đồng bộ

Các điểm dưới đây phát hiện khi viết ca bản 0.2, cần sửa ở tập khác trong đợt gom cuối. Tập này đã viết ca theo phương án ở cột "Đề nghị".

| Tập | Chỗ | Vấn đề | Đề nghị | Trạng thái |
|---|---|---|---|---|
| D03-02-PH04 SDD | §10.2, hình "Trình tự dừng khẩn một luồng ở PROD" | Tác nhân là "Vận hành u.to01", trong khi D02-08 và TC-04-143 chỉ cho TA, SO dừng khẩn (`PERM-04-emergency-stop`) | Đổi tác nhân thành SO hoặc TA; ca đầu cuối TC-04-197 dùng U-T68-SO | Đã hấp thụ (0.2): SDD §10.2 đổi tác nhân thành SO (u.so01) |
| D02-04-PH04 UC | §8.4, ERR-04-042 | Câu đề nghị "Phiên bản được soạn trên danh mục thành phần cũ…" khác câu ở bảng thông báo D02-03-PH04 "Luồng được soạn trên danh mục thành phần {old}, cũ hơn danh mục hiện hành {new}. Mở lại luồng để kiểm tra lại." | Chọn một câu, ghi vào D03-06-PH04 §5.3; ca TC-04-195 chỉ kiểm mã | Đã hấp thụ (0.2): UC §8.4 và MH §5.3 dùng câu của FRS §9.2; TC-04-195 chỉ kiểm mã |
| D03-06-PH04 Màn hình | §5.3 | Chưa có câu cho ERR-04-110 (thân lỗi runtime), FRS dùng "Dịch vụ đang tạm dừng. Thử lại sau." | Thêm câu này vào bảng thông báo runtime; ca TC-04-198 kiểm câu đó | Đã hấp thụ (0.2): MH §5.3 có câu ERR-04-110 (và ERR-04-101…112) |
| D02-04-PH04 UC | §8.4, câu cuối | Đề nghị thêm ca cho UC-04-05 E5, UC-04-06 E4, UC-04-12 E1, UC-04-17 E7, UC-04-18 E2 | Đã thêm: TC-04-189, TC-04-190, TC-04-195, TC-04-198, TC-04-199; có thể ghi số ca vào UC khi gom | Đã hấp thụ (0.2): UC §8.4 ghi số ca TC-04-187…202 |
| D03-03-PH04 CSDL | §4.2 | Kết quả chạy thử di trú W2 chưa có ca tự động dẫn chiếu | Dẫn chiếu TC-04-202 | Đã hấp thụ (0.2): CSDL §4.2 dẫn chiếu TC-04-202 |

: Đề nghị đồng bộ cho tập khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-25 | Bản đầu: 32 kịch bản, 186 ca, 12 UAT, mẫu tự động hóa, công cụ sinh ma trận |
| 0.2 | 2026-11-26 | Theo chuẩn trình bày D00-04-KTB: Giới thiệu đủ sáu mục; bảng danh sách test case 3.3; chuyển 186 ca (kể cả 14 ca hiệu năng) sang khối đặc tả, giữ nguyên dữ liệu, bước, mong đợi, truy vết; thêm 16 ca (TC-04-187…202): ngoại lệ UC-04-05 E5, 06 E4, 12 E1, 17 E7, 18 E2; ca đầu cuối cho bốn trình tự SDD; di trú W2 khi schema có chủ khác; trạng thái màn UI-04-09, 16, 17, 18, 19, 21; `fill_doc.py`, chú thích bảng ở ma trận; mục 11 đề nghị đồng bộ |
| 0.3 | 2026-11-27 | Đồng bộ chéo cuối: dh-dlq-error-code, TC-04-158, sinh lại gherkin và xlsx |
