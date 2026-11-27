---
ma_tai_lieu: D03-02-PH11
ten: Thiết kế chi tiết phần mềm phân hệ PH-11 Quy trình liên thông (BPM)
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kiến trúc sư, kỹ sư tích hợp PH-04, ATTT, vận hành, hội đồng thẩm định
phan_he: PH-11
mo_ta: Thiết kế chi tiết hiện thực 66 FR của PH-11 gồm cấu trúc mã module bpm trong dh-platform, cấu hình Flowable 7 nhúng một engine đa tenant, mười một thành phần với khối đặc tả 10 mục, bảy sơ đồ trình tự (phát hành bốn mắt, khởi tạo idempotent, service task qua outbox và inbox, hạn theo lịch làm việc, Saga bù trừ, tiến độ che DLCN, đồng bộ bản chiếu), mô hình lỗi và nhất quán, bảo mật, quan sát, triển khai, hiệu năng và năm ADR đề xuất 110 đến 114.
tai_lieu_lien_quan: D02-03-PH11 FRS; D02-04-PH11 UC; D03-03-PH11 CSDL; D03-04-PH11 API; D03-06-PH11 Màn hình; D03-10 Thiết kế đa tenant; D03-09 Hạ tầng
---

# D03-02-PH11 · Thiết kế chi tiết Quy trình liên thông (BPM)

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 66 FR của [D02-03-PH11](../../02-yeu-cau/frs/D02-03-PH11-frs-quy-trinh.md). PH-11 trả lời câu hỏi "hồ sơ này làm gì tiếp theo, ai làm, hạn đến khi nào" cho thủ tục liên thông nhiều cơ quan kéo dài nhiều ngày, ví dụ "Đăng ký khai sinh, đăng ký thường trú, cấp thẻ BHYT cho trẻ dưới 6 tuổi" (`LT_KHAI_SINH`). Hệ cũ (Viettel 2021) không có BPM nên toàn bộ là thiết kế mới. Sáu quyết định chính:

1. **Một module Modulith, một engine Flowable nhúng cho mọi tenant.** Phân hệ là module `bpm` của `dh-platform` (Spring Boot 4, Spring Modulith, package `vn.datahub.platform.bpm`), engine Flowable 7 nhúng cùng tiến trình, cô lập tenant bằng `tenantId` của Flowable cộng lớp nghiệp vụ `ph11_bpm` có RLS; bảng engine ở schema riêng `ph11_flowable` (đề xuất ADR 110).
2. **PH-11 quyết định "làm gì tiếp theo", PH-04 quyết định "làm bằng cách nào".** Service task chỉ mang ý định nghiệp vụ, được phát thành lệnh Kafka qua outbox; PH-04 thực thi và trả kết quả, PH-11 tương quan qua inbox rồi đánh thức đúng execution (đề xuất ADR 112, ADR-041, ADR-042). PH-11 không bao giờ gọi HTTT trực tiếp.
3. **Không giao dịch phân tán.** Engine và nghiệp vụ là hai nguồn kết nối, nguyên tử về hiệu ứng chứ không về giao dịch (Q11-21 đã chốt), nên thiết kế dựa vào mã lệnh xác định (gửi lại không sinh lệnh thứ hai), khởi tạo "engine trước, bản chiếu sau" có phục hồi, và đối soát bản chiếu mỗi phút. Khi một bước liên thông lỗi sau khi bước khác đã xong, Saga bù trừ theo thứ tự ngược (đề xuất ADR 113).

Tập nêu năm ADR đề xuất (ADR 110 đến ADR 114), mười câu hỏi mở Q11-20…29 và phụ lục đề nghị đồng bộ FRS (đã xử lý ở FRS 0.2). Rủi ro lớn nhất cần hội đồng lưu ý là Flowable 7.x trên Spring Boot 4 (Q11-04, Q11-20).

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Đủ để viết mã và ca kiểm thử mà không phải đoán: gói, lớp chính, giao dịch, khóa, cấu hình engine, tên chỉ số. Phạm vi: module `bpm` (mười một thành phần) và giao diện trình thiết kế. Ngoài phạm vi: lược đồ bảng (D03-03-PH11), hợp đồng API (D03-04-PH11), màn hình (D03-06-PH11), luồng Camel của PH-04, chính sách che dữ liệu của PH-09, Keycloak và OPA của PH-12.

### 1.2. Người đọc

Hội đồng đọc Tóm tắt, chương 2, chương 8 và mục 13.4 (ADR). Kỹ sư `dh-platform` đọc chương 3 đến 6. Kỹ sư PH-04 đọc mục 4.8 và 5.3 vì đó là hợp đồng lệnh và kết quả. ATTT đọc chương 7. Vận hành đọc chương 9 đến 11.

### 1.3. Quy ước trong tài liệu

Tên lớp, bảng, khóa tham số để trong dấu `` ` ``. Mã `FR-11-nnn`, `BR-11-nnn`, `NFR-11-nnn`, `ERR-11-nnn`, `EVT-11-nn`, `API-11-nnn` theo FRS. Mã `ADR 110` đến `ADR 114` là đề xuất trong tài liệu này, chưa có tệp ADR. Giá trị liệt kê theo FRS Phụ lục A, tên cột theo DDL `ph11_bpm.sql` (DDL theo FRS). Số liệu tải là giả định cho hồ sơ `QM-VUA` (D03-09). Sơ đồ trình tự không dùng dấu chấm phẩy trong thông điệp.

### 1.4. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng nhiều ở chương sau.

| Thuật ngữ | Giải thích |
|---|---|
| BPMN 2.0 | Business Process Model and Notation, ký pháp mô hình quy trình nghiệp vụ (CV 631) |
| Flowable | Engine BPM mã nguồn mở Apache 2.0 chạy nhúng trong `dh-platform` (ADR-007) |
| Execution, token | Một nhánh thực thi của phiên trong engine |
| Service task triggerable | Bước tự động chờ tín hiệu ngoài, engine dừng execution cho tới khi gọi `trigger` |
| Async executor | Bộ chạy job nền của Flowable, lấy job từ CSDL có khóa |
| Bản chiếu | Bản sao có RLS của phiên và việc (`instance_index`, `task_index`) để truy vấn, tra tiến độ |
| Outbox, inbox | Hộp gửi, hộp nhận trong CSDL của DU để gửi, nhận bản tin đúng một lần về hiệu ứng (ADR-042) |
| Saga | Chuỗi bù trừ theo thứ tự ngược thay cho giao dịch phân tán giữa các cơ quan |
| Bốn mắt | Hai người khác nhau cùng quyết định một thao tác rủi ro cao (FR-00-071, ADR-046) |
| DLCN, NC | Dữ liệu cá nhân; mức phân loại Nhạy cảm (`SENSITIVE`) |
| DU, RLS, HPA | Đơn vị triển khai; bảo mật mức dòng PostgreSQL (ADR-003); bộ tự co giãn số bản sao Kubernetes |

: Thuật ngữ và chữ viết tắt của tập SDD PH-11

### 1.5. Cấu trúc tài liệu

Chương 2 vị trí kiến trúc, 3 cây package, 4 mô hình miền, Flowable và mười một thành phần, 5 bảy sơ đồ trình tự, 6 đến 11 đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, hiệu năng, 12 và 13 kiểm thử, lộ trình, ADR, câu hỏi mở; phụ lục A đề nghị đồng bộ FRS.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Thiết kế dựa trên các tài liệu và ADR trong bảng, mỗi dòng ghi phần nội dung mà tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH11 FRS | 66 FR, 38 BR, 24 NFR, 74 mã lỗi, 20 sự kiện, 32 tham số `11.*`, Phụ lục A |
| D03-03-PH11, `ph11_bpm.sql` | 27 bảng, RLS, outbox, inbox, `shedlock`, cấu hình engine mục 6.1 |
| D03-04-PH11, `openapi-bpm.yaml`, `asyncapi-bpm.yaml` | 127 operation, hợp đồng bản tin Kafka |
| D03-01 SAD, D03-09, D03-10 | Vùng Z0 đến Z7, định cỡ `QM-VUA`, `TenantContext`, RLS |
| D04-01 | Cấu trúc package, `CC-MOD-01…05`, ArchUnit |
| ADR-001, 003, 007, 032, 041, 042, 046, 059 | Modulith; RLS; Flowable; mã hóa envelope; idempotency; inbox, outbox; bốn mắt; Debezium |
| ADR đề xuất 110…114 | Mục 13.4 |

: Tài liệu liên quan và ADR của PH-11

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

`bpm` là một module của DU `dh-platform`, chạy ở namespace `dh-control` (vùng Z3) cùng các module control plane khác. Engine Flowable chạy trong cùng tiến trình JVM, không có dịch vụ engine riêng. Lưu lượng người dùng và máy vào qua APISIX (Z1, Z2) với OIDC và OPA (SEC-21, 26); lệnh tới PH-04 và kết quả về đi qua Kafka (Z5), PH-04 chạy ở data plane `dh-runtime` (Z4) và là bên duy nhất tới bộ điều hợp PH-05. Dữ liệu nằm ở `pg-core` (Z5): schema `ph11_bpm` (RLS) và `ph11_flowable` (engine). Valkey (Z5) đệm tiến độ và giữ khóa ngắn; OpenBao (Z6) giữ khóa mã hóa biến NC. Không có đường mạng từ `dh-platform` tới HTTT chuyên ngành (SEC-14, SEC-16).

### 2.2. Sơ đồ thành phần

Sơ đồ cho thấy module `bpm` chia thành các thành phần con và các điểm tiếp xúc với hạ tầng.

```{.mermaid caption="Sơ đồ thành phần của module bpm trong dh-platform"}
flowchart TB
  subgraph Ngoai["Bên gọi"]
    UI["dh-console: /quy-trinh, /viec-cua-toi<br/>trình thiết kế bpmn-js"]
    DVC["Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19"]
  end
  GW["APISIX + OPA (Z1, Z2)"]
  subgraph BPM["dh-platform, module bpm (Z3)"]
    WEB["web: Controller /api/bpm/v1"]
    MODEL["model, resource<br/>phát hành, kiểm tra tĩnh"]
    RUNTIME["runtime<br/>phiên, bản chiếu, thông điệp"]
    TASK["task<br/>giao việc, hộp việc"]
    DUE["due<br/>lịch, hạn, nhắc"]
    BRIDGE["bridge<br/>lệnh, kết quả, tương quan"]
    SAGA["saga<br/>bù trừ, đối soát"]
    PROG["progress<br/>tiến độ che DLCN"]
    OPS["ops<br/>giám sát, sự cố, lưu giữ"]
    ENG["engine: Flowable 7<br/>async executor, history audit"]
  end
  PGB[("ph11_bpm (RLS)")]
  PGF[("ph11_flowable")]
  VK[("Valkey")]
  OB[("OpenBao transit")]
  K[["Kafka (Z5)"]]
  P04["PH-04 dh-runtime (Z4)"]
  P12["PH-12 Keycloak, OPA, đơn vị"]
  P13["PH-13 giám sát, kiểm toán"]
  UI --> GW
  DVC --> GW
  GW --> WEB
  WEB --> MODEL
  WEB --> RUNTIME
  WEB --> TASK
  WEB --> PROG
  MODEL --> ENG
  RUNTIME --> ENG
  TASK --> ENG
  BRIDGE --> ENG
  DUE --> ENG
  SAGA --> BRIDGE
  ENG --> PGF
  RUNTIME --> PGB
  TASK --> PGB
  DUE --> PGB
  SAGA --> PGB
  BRIDGE --> PGB
  PROG --> VK
  PROG --> PGB
  ENG -.-> OB
  PGB -- "outbox_event, Debezium" --> K
  K --> P04
  P04 --> K
  K -- "service.completed, failed" --> BRIDGE
  OPS --> PGB
  WEB -.-> P12
  K -.-> P13
```

Người đọc cần thấy ba điều. Thứ nhất, mọi thứ chạm tới engine đi qua `engine` (một facade duy nhất gắn `tenantId`), không module con nào gọi trực tiếp `RuntimeService` với tenant tự đặt. Thứ hai, đường ra thế giới ngoài chỉ có một: `outbox_event` rồi Kafka rồi PH-04. Thứ ba, `progress` đọc bản chiếu và đệm, không bao giờ đọc biến của engine, nên không thể lộ giá trị biến.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng liệt kê mỗi bên mà module gọi tới hoặc được gọi từ.

| Bên | Chiều | Cách dùng | FR liên quan |
|---|---|---|---|
| PH-04 (`dh-runtime`) | Ra, vào | Lệnh `{tenant}.bpm.service.requested.v1`; kết quả `.completed.v1`, `.failed.v1`; luồng nhận theo `intentCode` | FR-11-013, 028, 029 |
| PH-12 | Ra | Keycloak xác thực, OPA kiểm quyền, đơn vị và nhóm để giải ứng viên việc, người quản lý để leo thang | FR-11-034, 048 |
| PH-10 | Ra, vào | Đăng ký 20 topic `{tenant}.bpm.*`; sự kiện khởi tạo phiên (EVT trong PH-10) | FR-11-019 |
| PH-13 | Ra | Chỉ số, vết OpenTelemetry, sự kiện kiểm toán, cảnh báo | FR-11-061, 065 |
| PH-01, PH-07, PH-19 | Vào | Khởi tạo `DUYET_KET_NAP_HTTT` qua API-11-049; nghe EVT-11-05, 06 | FR-11-018 |
| PH-03 APISIX | Vào | Cổng vào, giới hạn lưu lượng, OIDC, OPA thô | NFR-11-020 |
| Cổng DVC tỉnh | Vào | `GET /progress/{businessKey}`; nhận EVT-11-04 nếu chọn kênh sự kiện (Q11-05) | FR-11-055, 056 |
| `pg-core`, Kafka, Valkey, OpenBao, Ceph RGW | Hạ tầng | Hai schema; topic; đệm; khóa transit; tệp đính kèm | CSDL mục 6 |

: Phụ thuộc của module bpm

### 2.4. Hiện trạng mã và đường chuyển

Chưa có mã PH-11 (đợt 2, tuần W4 của kế hoạch W0 đến W6). Không có dữ liệu cũ cần chuyển vì hệ cũ không có BPM. Mã mới tạo ở `apps/platform/src/main/java/vn/datahub/platform/bpm` và dữ liệu từ DDL `ph11_bpm.sql` qua Liquibase. Rủi ro nền tảng chưa khóa: Flowable 7.x chính thức hỗ trợ Spring Boot đến bản nào (Q11-04); phương án và quyết định chờ ở mục 13.3.

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

Module nằm ở `apps/platform/src/main/java/vn/datahub/platform/bpm`, theo `CC-MOD-01…05` của D04-01: ba package `api`, `internal`, `events`; module khác chỉ import `api` và `events`. Mỗi gói con của `internal` ứng với một thành phần ở chương 4.

```text
vn/datahub/platform/bpm/
|-- package-info.java   @ApplicationModule(allowedDependencies = {"shared", "iam::api", "notify::api"})
|-- api/                BpmStartApi, BpmTaskApi, BpmProgressApi, dto/
|-- events/             EVT-11-01…17, 20 (ModelPublished, InstanceStarted, StepCompleted, TaskCreated, ...)
|-- internal/
    |-- model/      ModelService, VersionService, StaticCheckEngine, CheckRule (mỗi ruleCode một lớp),
    |               VersionDiffService, PublishApprovalService, DeploymentService, DesignerLockService
    |-- resource/   FormService, IntentService, CompensationRegistry, TemplateService, VariableCatalog
    |-- engine/     EngineConfiguration, TenantEngineFacade, VariableCipher, ProcessEventDispatcher
    |-- runtime/    InstanceService, StartCoordinator, MessageCorrelator, InstanceChangeService,
    |               MigrationService, ProjectionListener, ProjectionReconciler, StartRecoveryJob
    |-- bridge/     ServiceTaskBehavior, CommandIdFactory, ResultConsumer, CorrelationService, TimeoutSweeper
    |-- task/       AssignmentResolver, ClaimService, CompleteTaskService, DelegationService, InboxItemProvider
    |-- due/        BusinessCalendarService, WorkingTimeCalculator, DueScanner, PauseService, EscalationService
    |-- saga/       SagaCoordinator, SagaPlanner, CompensationDispatcher, SagaReconciler
    |-- progress/   ProgressService, PublicStepMapper, PiiMaskGuard, ProgressCache, StepEventPublisher
    |-- ops/        IncidentService, BottleneckDetector, RetentionPurgeJob, EvidencePackBuilder, AiSuggestionClient
    |-- web/        *Controller (REST /api/bpm/v1), BpmExceptionHandler (RFC 9457), IdempotencyFilter
    |-- persistence/ *Repository, TenantSession, OutboxWriter, InboxStore, ShedLockConfig
    |-- config/     BpmProperties ("datahub.bpm"), BpmKafkaConfig
```

Giao diện của trình thiết kế (bpmn-js, React, antd v6) nằm ở `apps/console/src/features/bpm`, tách khỏi cây Java; mục 4.13 đặc tả.

### 3.2. Quy tắc phụ thuộc

Bốn luật ArchUnit riêng của module, ngoài bộ chung D04-01: (1) chỉ gói `engine` được import `org.flowable.engine.*`, các gói khác dùng `TenantEngineFacade`, để không có lời gọi engine nào thiếu `tenantId`; (2) chỉ `bridge` và `saga` được tạo bản ghi `outbox_event` qua `OutboxWriter`, và `OutboxWriter` từ chối payload có khóa nằm trong danh sách cấm (`variables`, `formData`, `values`, `identifier`); (3) gói `progress` không import `engine` và không đọc `ACT_*`; (4) không lớp nào ngoài `StartCoordinator` gọi `startProcessInstance*`. Luật (2) và (3) cùng ràng buộc `CHECK` `ck_outbox_event_no_value` ở CSDL tạo hai lớp chặn rò DLCN (NFR-11-021).

### 3.3. Giao diện công bố

Module khác trong `dh-platform` chỉ dùng PH-11 qua các giao diện sau.

| Giao diện | Dùng bởi | Phương thức chính |
|---|---|---|
| `BpmStartApi` | PH-01, PH-07, PH-19 (module khác trong `dh-platform`) | `start(processKey, businessKey, variables, idempotencyKey)`, `findByBusinessKey(businessKey)` |
| `BpmTaskApi` | `dh-console` qua hộp "Việc của tôi" (FR-00-070) | `listInbox(user, filter)`, `inboxCount(user)` |
| `BpmProgressApi` | Module cổng DVC của `dh-platform` nếu có | `progressOf(businessKey, clientId)` |
| Sự kiện miền `events/*` | PH-13, PH-10 | Phát qua `ApplicationEventPublisher` (Modulith) và outbox |
| REST `/api/bpm/v1` | Giao diện, HTTT, PH-04, Cổng DVC | API-11-001…137 |

: Giao diện công bố của module bpm

### 3.4. Danh sách thành phần được đặc tả

Mười một thành phần ở bảng dưới, mỗi mục chương 4 mở bằng khối đặc tả 10 mục. Mục 4.1 là mô hình miền, 4.2 là cấu hình engine, 4.14 đến 4.16 là các vấn đề cắt ngang.

| Mục | Thành phần | Lớp chính | FR |
|---|---|---|---|
| 4.3 | `model` · Mô hình, phát hành | `StaticCheckEngine`, `PublishApprovalService`, `DeploymentService` | FR-11-001…011 |
| 4.4 | `resource` · Tài nguyên quy trình | `IntentService`, `CompensationRegistry`, `VariableCatalog` | FR-11-012…017 |
| 4.5 | `engine` · Engine Flowable | `EngineConfiguration`, `TenantEngineFacade`, `VariableCipher` | nền cho mọi FR |
| 4.6 | `runtime` · Phiên và bản chiếu | `StartCoordinator`, `ProjectionListener`, `ProjectionReconciler` | FR-11-018…027, 030, 033 |
| 4.7 | `bridge` · Cầu nối PH-04 | `ServiceTaskBehavior`, `ResultConsumer`, `CorrelationService` | FR-11-028, 029, 031, 032 |
| 4.8 | `task` · Việc người dùng | `AssignmentResolver`, `CompleteTaskService`, `DelegationService` | FR-11-034…044 |
| 4.9 | `due` · Lịch và hạn | `WorkingTimeCalculator`, `DueScanner`, `EscalationService` | FR-11-045…050 |
| 4.10 | `saga` · Bù trừ | `SagaCoordinator`, `CompensationDispatcher`, `SagaReconciler` | FR-11-051…054 |
| 4.11 | `progress` · Tiến độ | `ProgressService`, `PublicStepMapper`, `PiiMaskGuard` | FR-11-055…057 |
| 4.12 | `ops` · Vận hành | `IncidentService`, `RetentionPurgeJob`, `EvidencePackBuilder` | FR-11-058…066 |
| 4.13 | Trình thiết kế · giao diện | `BpmnDesigner`, `PropertyPanel`, `CheckResultPane` | FR-11-003, 004, 005 |

: Danh sách thành phần được đặc tả của PH-11

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Miền của PH-11 xoay quanh bốn aggregate. `ProcessModel` gom các `ProcessVersion` (BPMN XML bất biến sau khi gửi duyệt). `ProcessInstanceView` là bản chiếu của phiên trong engine, kèm `ServiceCall`, `DueTracking` và `Saga` là những thực thể phụ thuộc vào đúng một phiên. `UserTask` là bản chiếu việc. Nguồn sự thật về trạng thái thực thi là engine; bản chiếu chỉ để truy vấn, báo cáo và tra tiến độ, nên không bao giờ được dùng để quyết định bước kế tiếp.

```{.mermaid caption="Mô hình miền PH-11: aggregate và thực thể phụ thuộc"}
classDiagram
  class ProcessModel
  class ProcessVersion {
    +status VersionStatus
    +bpmnXml
    +checksum
  }
  class PublishRequest
  class ProcessInstanceView {
    +state InstanceStatus
    +businessKey
    +progressPublic
  }
  class ServiceCall {
    +commandId
    +state
  }
  class DueTracking
  class Saga
  class SagaStep
  class UserTask
  class Incident
  ProcessModel "1" --> "*" ProcessVersion
  ProcessVersion "1" --> "*" PublishRequest
  ProcessVersion "1" --> "*" ProcessInstanceView
  ProcessInstanceView "1" --> "*" ServiceCall
  ProcessInstanceView "1" --> "*" UserTask
  ProcessInstanceView "1" --> "*" DueTracking
  ProcessInstanceView "1" --> "*" Saga
  Saga "1" --> "*" SagaStep
  ProcessInstanceView "1" --> "*" Incident
```

Hình trên cho thấy mọi thực thể vận hành đều treo vào đúng một phiên, và phiên treo vào đúng một phiên bản mô hình đã phát hành. Nhờ vậy sửa mô hình sau này không đổi hành vi của phiên đang chạy (BR-11 về khóa phiên bản), còn di trú là thao tác riêng có duyệt (FR-11-026).

Các bất biến (invariant) mà mã phải bảo đảm, mỗi bất biến có chốt ở máy chủ và chốt ở CSDL:

| Bất biến | Chốt ở mã | Chốt ở CSDL |
|---|---|---|
| Mỗi mô hình có tối đa một phiên bản `PUBLISHED` | `DeploymentService` đặt cũ `DEPRECATED` trong cùng giao dịch | Chỉ mục duy nhất một phần theo trạng thái |
| Nội dung phiên bản đã gửi duyệt không đổi | `VersionService` chặn sửa khi không `DRAFT` | Trigger `tg_frozen` (ERRCODE 55000) |
| Người duyệt khác người gửi và khác người sửa cuối | `PublishApprovalService` (ERR-11-005) | Ràng buộc `CHECK` trên `publish_request` |
| Một hồ sơ chỉ có một phiên chưa kết thúc trên một mô hình | `StartCoordinator` (ERR-11-018) | `uq_instance_index_live_key` |
| Khóa lũy đẳng khởi tạo là duy nhất | `IdempotencyGate` | `uq_instance_index_correlation` |
| Một lệnh một kết quả | `ResultConsumer` | `uq_service_call_command`, khóa chính `inbox_message` |
| `DONE` của bước Saga chỉ sau khi ghi nhật ký | `CompensationDispatcher` | `ck_saga_step_state` và trigger bất biến |
| Biến NC không vào bản chiếu, sự kiện, lệnh | `OutboxWriter`, `PiiMaskGuard` | `ck_outbox_event_no_value`, `ck_inbox_message_no_value` |

: Bất biến miền và nơi bảo đảm

### 4.2. Cấu hình Flowable 7 nhúng (`engine`)

Một `ProcessEngine` duy nhất cho mọi tenant (đề xuất ADR 110). Tenant được mang bằng `tenantId` của Flowable ở mọi đối tượng: triển khai, định nghĩa, phiên, việc, job, lịch sử. `TenantEngineFacade` là cửa duy nhất tới `RepositoryService`, `RuntimeService`, `TaskService`, `ManagementService`, `HistoryService`; nó lấy `tenantId` từ `TenantContext` (không từ tham số của bên gọi) và dùng các biến thể `...ByKeyAndTenantId`, `.processInstanceTenantId(...)`, `.taskTenantId(...)`. Bảng dưới là cấu hình đề xuất, tên thuộc tính theo Flowable 7.x và xác nhận khi dựng (Q11-04).

| Hạng mục | Giá trị | Lý do |
|---|---|---|
| Nguồn kết nối | `engineDataSource` riêng, tài khoản thuộc `ph11_engine`, `databaseSchema=ph11_flowable`, HikariCP tối đa 12 kết nối mỗi bản sao | Cô lập quyền với `ph11_bpm`; hạn mức không tranh với API |
| Tạo, nâng cấp bảng | `databaseSchemaUpdate=false` ở mọi môi trường ngoài DEV; nâng cấp bằng bước Liquibase của Flowable trong cửa sổ triển khai | Không để pod tự đổi lược đồ khi khởi động song song |
| Đa tenant | `tenantId` = mã tenant (ví dụ `T68`); không dùng tenant rỗng; mẫu `COMMON` triển khai dưới `tenantId` của tenant dùng mẫu, không chia sẻ định nghĩa | Tránh rò chéo; BPMN XML nằm ở `process_version` nên triển khai lại được |
| Lịch sử | `history=audit` | Ghi phiên, bước, việc, biến chi tiết ở mức kiểm toán, không ghi mọi thay đổi biến; chi tiết bước giữ ở `instance_step` |
| Dọn lịch sử | `enableHistoryCleaning=true`, `historyCleaningTimeCycleConfig` chạy 01:00, `cleanInstancesEndedAfterNumberOfDays` bằng `11.retention.engineHistoryMonths` quy ra ngày | `ACT_HI_*` không phình; bản nghiệp vụ giữ ở `ph11_bpm` |
| Async executor | Bật; `asyncExecutorCorePoolSize=4`, `MaxPoolSize=8`, `QueueSize=100` mỗi bản sao | Cỡ theo NFR-11-004 và mục 11.1; mỗi luồng giữ một kết nối nên không vượt nhóm 12 |
| Job lock | `asyncExecutorAsyncJobLockTimeInMillis=300000` (5 phút), `asyncExecutorTimerLockTimeInMillis=300000`, `asyncExecutorDefaultAsyncJobAcquireWaitTime=1000` | Khớp NFR-11-009: bản khác nhận job trong ≤ 5 phút sau khi hết khóa |
| Lượt thử job | `asyncExecutorNumberOfRetries=3`, giãn cách `PT30S`, `PT2M`, `PT10M` bằng `failedJobRetryTimeCycle`; hết lượt vào dead letter | Không mất job lặng lẽ; sinh `incident` `JOB_FAILED` |
| Chia việc giữa bản sao | `asyncExecutorGlobalAcquireLockEnabled=false`; dựa vào khóa mức job (`LOCK_OWNER_`) và `SELECT ... FOR UPDATE SKIP LOCKED` do Flowable thực hiện với PostgreSQL | Không có điểm tập trung đơn |
| Timer | Cùng async executor; `asyncExecutorTimerLockTimeInMillis` như trên; `ShedLock` cho `TimerCatchUp` bù khi tắt máy dài | Hẹn giờ không biến mất khi pod chết |
| Script, biểu thức | Tắt script task và `ExpressionManager` ở chế độ chỉ cho phép `${var}` trên biến đã khai báo; không bean tùy ý | Chống thực thi mã tùy ý (SEC-46), `UNSUPPORTED_ELEMENT` ở kiểm tra tĩnh |
| Biến NC | `VariableCipher` mã hóa envelope trước khi `setVariable`, giải mã chỉ ở điểm cần | ADR-032; mục 4.16 |
| Bộ nghe sự kiện | `ProcessEventDispatcher` đăng ký `TransactionDependentFlowableEventListener` cho `ACTIVITY_STARTED`, `ACTIVITY_COMPLETED`, `TASK_CREATED`, `TASK_ASSIGNED`, `TASK_COMPLETED`, `PROCESS_COMPLETED`, `PROCESS_CANCELLED`, `JOB_EXECUTION_FAILURE` ở thời điểm sau commit | Bản chiếu sau commit; mục 5.7 |

: Cấu hình Flowable 7 nhúng của PH-11

### 4.3. Mô hình và phát hành (`model`)

::: dac-ta
**Mục đích.** Quản lý mô hình và phiên bản BPMN: tạo, nhập, kiểm tra tĩnh, so sánh, gửi duyệt, duyệt bốn mắt và triển khai lên engine, ngừng dùng, thu hồi, chạy thử.

**Lớp chính.** `ModelService`, `VersionService`, `BpmnXmlParser`, `StaticCheckEngine`, `VersionDiffService`, `PublishRequestService`, `PublishApprovalService`, `DeploymentService`, `BpmnPackageService`, `DesignerLockService`, `TestRunService`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao; kiểm tra tĩnh `FULL` chạy cùng JVM.

**FR hiện thực.** FR-11-001…011; BR-11-003, 008, 014, 015, 034, 035.

**Giao diện vào.** REST API-11-001…028 (`ModelController`, `PublishController`); trình thiết kế UI-11-04 gọi `:lock`, `:request-lock` (API-11-136), `:validate`, `:submit`; `RESTORE` qua API-11-131.

**Phụ thuộc ra.** `engine` (`RepositoryService` qua facade), `resource` (ý định, biểu mẫu, bù trừ, biến), PH-04 (danh mục luồng để kiểm `INTENT_NO_FLOW`, hết 5 giây ghi `INFO`), PH-12 (quyền, người dùng), `pg-core`, Ceph RGW (gói quy trình).

**Dữ liệu.** `process_model`, `process_version`, `publish_request`, `variable_definition`, `compensation_action`; BPMN XML ở cột `bpmn_xml` kèm `checksum` SHA-256.

**Sự kiện.** EVT-11-01 `model.published`, EVT-11-02 `model.retired` qua outbox trong cùng giao dịch với đổi trạng thái.

**Lỗi và xử lý.** ERR-11-004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 037, 038 (trả người gọi); ERR-11-046 khi engine từ chối triển khai (giao dịch hoàn lại, `publish_request` về trạng thái từ chối triển khai, phiên bản về `DRAFT`).

**Quan sát.** `datahub_bpm_validate_duration_seconds{mode}`, `datahub_bpm_publish_total{result}`, `datahub_bpm_deploy_duration_seconds`; span `bpm.model.validate`, `bpm.model.deploy`.
:::

`StaticCheckEngine` chạy theo hai chế độ: `QUICK` (cú pháp, cấu trúc, ruleCode không cần gọi ngoài, dùng khi người dùng gõ) và `FULL` (thêm `INTENT_NO_FLOW` gọi danh mục luồng của PH-04, và kiểm lại tất cả luật khi triển khai). Parser đọc XML bằng StAX với `XMLConstants.FEATURE_SECURE_PROCESSING` và tắt thực thể ngoài, giới hạn `11.model.maxXmlKb` (mặc định 2.048 KB), để chặn XXE và bom XML (ERR-11-008, 009). Mỗi `ruleCode` ở bảng 6.2-c của FRS là một lớp `CheckRule` thuần hàm trên mô hình BPMN đã phân tích; mô hình 200 phần tử phải xong dưới 2 giây (NFR-11-013). Cổng triển khai tin kết quả của máy chủ, không tin kết quả phía trình duyệt (ADR 111).

`DesignerLockService` giữ khóa soạn thảo bằng hai cột `lock_owner`, `lock_until` trên `process_version` (cập nhật có điều kiện), gia hạn mỗi lần lưu (tự lưu theo `11.designer.autosaveSeconds`), hết hạn theo `11.designer.lockMinutes`; người thứ hai mở ở chế độ chỉ xem (ERR-11-016) và có thể gửi `:request-lock`, hệ thống phát EVT-11-20 cho người giữ mà không nhả khóa. Khóa không dùng Valkey để không mất khi đệm sự cố.

`DeploymentService.deploy(version)` thực hiện: nạp XML từ CSDL (không từ yêu cầu), kiểm checksum, chạy `FULL`, gọi `createDeployment().tenantId(t).name("processKey:v{n}").addString(...)`, đọc `ProcessDefinition` để ghi `deployment_id`, `process_definition_id`. Do engine và nghiệp vụ là hai nguồn kết nối nên thứ tự là: triển khai engine trước, rồi giao dịch nghiệp vụ đặt `PUBLISHED`, đổi bản cũ `DEPRECATED`, ghi `publish_request` và outbox EVT-11-01. Nếu giao dịch nghiệp vụ lỗi sau khi engine đã triển khai thì `DeploymentService` xóa triển khai vừa tạo (chỉ được vì chưa phiên nào dùng) và trả ERR-11-046; nếu chính việc xóa lỗi thì ghi `incident` `ENGINE_ERROR` và để `ProjectionReconciler` dọn triển khai mồ côi (không ảnh hưởng vì phiên chỉ khởi tạo theo bản `PUBLISHED` ghi ở CSDL nghiệp vụ).

### 4.4. Tài nguyên quy trình (`resource`)

::: dac-ta
**Mục đích.** Quản lý biểu mẫu việc (JSON Schema), ý định nghiệp vụ và ánh xạ sang luồng PH-04 theo môi trường, hành động bù trừ theo bước, mẫu quy trình `COMMON`, khai báo biến và phân loại dữ liệu, bảng quyết định DMN đơn giản.

**Lớp chính.** `FormService`, `IntentService`, `IntentBindingService`, `CompensationRegistry`, `TemplateService`, `VariableCatalog`, `DecisionTableService`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao.

**FR hiện thực.** FR-11-012…017; BR-11-002, 004, 006, 014, 015, 016.

**Giao diện vào.** REST API-11-029…048; `StaticCheckEngine` gọi `IntentService.isActive`, `VariableCatalog.classOf`.

**Phụ thuộc ra.** PH-04 (danh mục luồng, trạng thái phát hành theo môi trường), PH-12 (`PA` ghi mẫu `COMMON`), `pg-core`.

**Dữ liệu.** `form_definition`, `service_intent`, `compensation_action`, `process_template`, `variable_definition`, `decision_table`.

**Sự kiện.** Không (thay đổi tài nguyên đi vào kiểm toán).

**Lỗi và xử lý.** ERR-11-002, 004, 006, 011, 012, 014, 015, 036, 040, 044 (trả người gọi).

**Quan sát.** `datahub_bpm_resource_change_total{kind,action}`; span `bpm.resource.write`.
:::

Ý định (`service_intent`) là ranh giới thiết kế với PH-04 (BR-11-002): sơ đồ chỉ mang `intentCode` như `guiTuPhap`, còn "làm bằng cách nào" nằm ở cột `bindings` (môi trường `TEST`, `STAGING`, `PROD` tới mã luồng và phiên bản luồng PH-04). Đổi cách gọi HTTT là đổi `bindings`, không sửa sơ đồ. `IntentBindingService` hỏi PH-04 trạng thái phát hành của luồng khi người dùng gán và khi kiểm `FULL`; kết quả đệm Valkey 60 giây. `CompensationRegistry` ép hai quy tắc: ý định bù trừ phải khác ý định xuôi (ERR-11-044) và bước ghi dữ liệu ra ngoài (`writes_external = true`) phải có bù trừ hoặc miễn do người có quyền duyệt (`waiver_approved_by`). `VariableCatalog` là nguồn phân loại cho `VariableCipher` (mục 4.16), `PiiMaskGuard` (mục 4.11) và luật `SENSITIVE_IN_PUBLIC`.

### 4.5. Engine Flowable và tenant (`engine`)

::: dac-ta
**Mục đích.** Dựng và bao bọc engine Flowable dùng chung mọi tenant: cấu hình ở mục 4.2, facade có `tenantId`, bộ nghe sự kiện sau commit, mã hóa biến NC, kiểm tra sức khỏe.

**Lớp chính.** `EngineConfiguration`, `TenantEngineFacade`, `TenantIdResolver`, `AsyncExecutorConfig`, `HistoryCleanupConfig`, `VariableCipher`, `ProcessEventDispatcher`, `EngineHealthIndicator`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao đều chạy async executor (số bản sao ở mục 11.2).

**FR hiện thực.** Nền cho mọi FR; trực tiếp FR-11-060 (job lỗi), FR-11-063 (dọn lịch sử), NFR-11-008, 009, 011, 012.

**Giao diện vào.** Chỉ các thành phần trong module gọi qua `TenantEngineFacade`; không REST.

**Phụ thuộc ra.** `pg-core` (`ph11_flowable`), OpenBao (khóa transit, qua `dh-crypto`).

**Dữ liệu.** Bảng `ACT_*`, `FLW_*` do Flowable quản; không DDL của PH-11 ở đây (ADR 110).

**Sự kiện.** Không trực tiếp; `ProcessEventDispatcher` chuyển sự kiện engine thành lời gọi `ProjectionListener`, `StepEventPublisher`.

**Lỗi và xử lý.** ERR-11-046 (503 khi `EngineHealthIndicator` báo engine, CSDL không sẵn sàng); ERR-11-107 job hết lượt thử; ERR-11-108 hẹn giờ không chạy.

**Quan sát.** `datahub_bpm_job_queue_depth`, `datahub_bpm_job_failed_total`, `datahub_bpm_engine_up`; span `bpm.engine.command`.
:::

Hai điều cần nhớ khi dùng Flowable đa tenant. `tenantId` của Flowable không thay cho RLS: nó cô lập trong engine, còn RLS cô lập bản chiếu; `ph11_flowable` không có RLS nên quyền CSDL của engine chỉ cấp cho dịch vụ PH-11. Truy vấn engine thiếu điều kiện tenant sẽ thấy mọi tenant, nên luật ArchUnit số (1) mục 3.2 cấm gọi engine ngoài facade và `TenantEngineFacade` ném lỗi khi `TenantContext` trống.

### 4.6. Phiên và bản chiếu (`runtime`)

::: dac-ta
**Mục đích.** Khởi tạo phiên idempotent, tạm dừng, tiếp tục, hủy, sửa biến, chuyển bước, di trú, nhận thông điệp tương quan, nhận bổ sung hồ sơ; duy trì bản chiếu `instance_index`, `instance_step` đúng với engine.

**Lớp chính.** `InstanceService`, `StartCoordinator`, `IdempotencyGate`, `MessageCorrelator`, `SupplementService`, `InstanceChangeService`, `MigrationService`, `EventStartConsumer`, `ProjectionListener`, `ProjectionReconciler`, `StartRecoveryJob`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao; `ProjectionReconciler`, `StartRecoveryJob` chạy một bản tại một thời điểm nhờ ShedLock.

**FR hiện thực.** FR-11-018…027, 030, 033; BR-11-001, 005, 006, 007, 010.

**Giao diện vào.** REST API-11-049…071, 089 (`InstanceController`, `MessageController`); Kafka (sự kiện khởi tạo từ PH-10); `BpmStartApi` cho module trong DU.

**Phụ thuộc ra.** `engine`, `due` (tạo hạn phiên), `bridge` (ghi outbox), Valkey, `pg-core`.

**Dữ liệu.** `instance_index`, `instance_step` (phân vùng tháng), `inbox_message`, `instance_change`, `migration_plan` (cùng `instance_step`, `instance_change` theo FRS 0.2).

**Sự kiện.** EVT-11-03 `instance.started`, EVT-11-05 `completed`, EVT-11-06 `cancelled`, EVT-11-07 `suspended` (kèm `RESUMED` trong `state`).

**Lỗi và xử lý.** ERR-11-017, 018, 019, 020, 030, 031, 032, 033, 041, 049 (trả người gọi); ERR-11-118 quy trình con thiếu phiên bản phát hành; ERR-11-119 di trú một phiên thất bại (ghi, tiếp lô); ERR-11-120 sự kiện khởi tạo không hợp lệ (DLQ).

**Quan sát.** `datahub_bpm_instance_started_total{process,channel,result}`, `datahub_bpm_instance_start_duration_seconds`, `datahub_bpm_instance_active{state}`, `datahub_bpm_projection_lag_seconds`, `datahub_bpm_projection_drift_total`; span `bpm.instance.start`, `bpm.projection.apply`.
:::

`StartCoordinator` là thành phần duy nhất được gọi `startProcessInstanceByKeyAndTenantId` (luật ArchUnit số 4). Vì engine và bản chiếu không chung giao dịch (nguyên tử về hiệu ứng, Q11-21), "tạo phiên ở engine" đi trước rồi một giao dịch `ph11_bpm` ghi bản chiếu, hạn và outbox EVT-11-03 (mục 5.2). Ba chốt chống lệch: khóa tư vấn theo `(tenant, modelCode, businessKey)` giữ suốt thao tác, tra ngược engine theo `businessKey` khi gọi lại, và `StartRecoveryJob` mỗi phút nhặt phiên engine chưa có bản chiếu quá 60 giây để dựng bản chiếu, hoặc hủy nếu quá `11.instance.stuckHours`.

Tạm dừng, tiếp tục, hủy gọi `suspendProcessInstanceById`, `activateProcessInstanceById`, `deleteProcessInstance` rồi cập nhật bản chiếu theo `version` lạc quan (ERR-11-004). Hủy kèm bù trừ chuyển cho `saga` và phiên ở `COMPENSATING` từ chối thao tác khác (ERR-11-030). Sửa biến, chuyển bước, di trú tạo `instance_change` hoặc `migration_plan` chờ người thứ hai duyệt (ADR-046); khi duyệt dùng `setVariable`, `createChangeActivityStateBuilder()` hoặc `createProcessInstanceMigrationBuilder()` theo lô `11.migration.batchSize`, mỗi phiên một giao dịch để lỗi một phiên không hủy cả lô.

`MessageCorrelator` đón thông điệp (API-11-069 hoặc sự kiện PH-10): tra phiên theo `businessKey` hoặc `correlationKey` rồi `messageEventReceived`; thông điệp đến sớm giữ ở `inbox_message` `UNCORRELATED` tới `expires_at` (`11.message.bufferMinutes`), quá hạn thì mở sự cố `MESSAGE_UNCORRELATED` (ERR-11-109).

### 4.7. Cầu nối PH-04 (`bridge`)

::: dac-ta
**Mục đích.** Biến service task thành lệnh Kafka tới PH-04, nhận kết quả và lỗi, tương quan về đúng execution, xử lý quá hạn chờ, gửi thông báo, gọi quy trình con; bảo đảm một lệnh có đúng một hiệu ứng dù gửi lại.

**Lớp chính.** `ServiceTaskBehavior`, `CommandIdFactory`, `ServiceCallStore`, `ResultConsumer`, `CorrelationService`, `TimeoutSweeper`, `NotificationTaskBehavior`, `CallActivityGuard`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao (hành vi service task chạy trong job async; `ResultConsumer` là consumer Kafka cùng group nên bản tin được chia giữa các bản sao).

**FR hiện thực.** FR-11-028, 029, 031 (phần timer biên của service task), 032, 033; BR-11-002, 014, 022, 023.

**Giao diện vào.** Hành vi `triggerable` của Flowable; Kafka `{tenant}.bpm.service.completed.v1`, `.failed.v1`; REST API-11-070, 071 (gửi lại lệnh).

**Phụ thuộc ra.** `engine` (`trigger`, `BpmnError`), `OutboxWriter`, `due` (hẹn giờ biên), `saga` (khi lỗi nghiệp vụ không có biên bắt), PH-04 qua Kafka.

**Dữ liệu.** `service_call`, `outbox_event`, `inbox_message`.

**Sự kiện.** EVT-11-17 `service.requested` (phát); EVT-11-18, 19 (tiêu thụ); EVT-11-04 sau khi bước xong; EVT-11-20 khi thông báo.

**Lỗi và xử lý.** ERR-11-101 (đẩy lệnh lỗi), 102 (quá hạn chờ), 103 (không tương quan), 104 (trùng, chỉ đếm), 105 (lỗi nghiệp vụ), 106 (lỗi kỹ thuật hết lượt), 117 (outbox tồn đọng), 123 (thông báo lỗi).

**Quan sát.** `datahub_bpm_service_call_total{intent,result}`, `datahub_bpm_service_result_duration_seconds{intent}`, `datahub_bpm_service_timeout_total{intent}`, `datahub_bpm_inbox_duplicate_total`, `datahub_bpm_inbox_uncorrelated`, `datahub_bpm_outbox_pending`; span `bpm.service.dispatch`, `bpm.service.result`.
:::

**Mã lệnh xác định.** `CommandIdFactory` tạo `commandId` là UUID v5 trên chuỗi `{tenant}|{processInstanceId}|{executionId}|{activityId}|{lần}`, `lần` là số lần giao lệnh của execution đó, chỉ tăng khi người vận hành chủ ý gửi lệnh mới. Gửi lại do job lỗi giữ nguyên `commandId`, nên "outbox ghi rồi engine rollback rồi job thử lại" không sinh lệnh thứ hai: `outbox_event` có khóa chính `event_id = commandId` (`ON CONFLICT DO NOTHING`) và PH-04 chống trùng theo `commandId`. 

**Thứ tự trong `ServiceTaskBehavior.execute`.** (1) Dựng `payload` theo `inputMapping`, kiểm `inputSchema` (lỗi thì job thử lại rồi vào sự cố ERR-11-107); biến NC thay bằng tham chiếu `bpm-secret:{id}`, PH-04 đổi qua API nội bộ mTLS ngay trước khi gọi HTTT (BR-11-014). (2) Giao dịch `REQUIRES_NEW` trên `ph11_bpm` (không chung giao dịch với engine) ghi `service_call` `REQUESTED` (`timeout_at` = bây giờ + thời gian chờ của ý định hoặc `11.service.defaultTimeoutMinutes`) và `outbox_event`. (3) Trả về mà không `leave`, execution đứng ở `WAITING_SERVICE`. Lỗi ở (2) làm job lỗi và thử lại; engine rollback sau (2) thì lần thử sau dùng cùng `commandId`.

**Nhận kết quả.** `ResultConsumer` dùng `enable.auto.commit=false`, `isolation.level=read_committed`, một bản tin một giao dịch: chèn `inbox_message` khóa `(tenant, consumer, messageId)`, trùng thì xác nhận offset và đếm (ERR-11-104), đây là tầng hai của ADR-041. `CorrelationService` tìm `service_call` theo `(tenant, commandId)`; không thấy hoặc đã đóng thì DLQ và sự cố (ERR-11-103). Thành công: kiểm `output` theo `outputSchema`, ghi biến theo `outputMapping`, `trigger(executionId)`, rồi đặt `service_call` `COMPLETED`. Thứ tự `trigger` trước vì nếu cập nhật sau lỗi thì bản tin giao lại, `trigger` lần hai thấy execution đã đi nên bỏ qua. Lỗi `BUSINESS` trong `businessErrors[]` ném `BpmnError(errorCode)`; lỗi `TECHNICAL` mở sự cố và giữ phiên ở `WAITING_SERVICE` (ERR-11-106).

**Quá hạn.** `TimeoutSweeper` (ShedLock, 60 giây) quét `service_call` `REQUESTED` có `timeout_at` đã qua (`ix_service_call_timeout`), đặt `TIMED_OUT`; bước có hẹn giờ biên thì engine đã đi nhánh biên, không thì mở sự cố `SERVICE_TIMEOUT` (ERR-11-102).

**Outbox tới Kafka.** Không có bộ đẩy trong mã ứng dụng: Debezium Outbox Event Router (ADR-059) đọc `outbox_event` và định tuyến theo `topic`, khóa phân vùng `partition_key` là `businessKey` để sự kiện của một hồ sơ giữ thứ tự. `OutboxCleaner` xóa dòng đã phát quá `11.retention.progressEventYears`; `datahub_bpm_outbox_pending` báo tồn đọng (ERR-11-117).

### 4.8. Việc người dùng (`task`)

::: dac-ta
**Mục đích.** Tạo việc và phân công theo nhóm ứng viên, đơn vị, người cụ thể hay quy tắc; đăng ký việc vào hộp "Việc của tôi"; nhận, trả, chuyển, ủy quyền, giao lại hàng loạt; hoàn thành việc với biểu mẫu, ý kiến, quyết định; trả về bước trước, yêu cầu bổ sung.

**Lớp chính.** `TaskProjectionService`, `AssignmentResolver`, `ClaimService`, `CompleteTaskService`, `DraftService`, `DelegationService`, `DelegationExpirer`, `BulkReassignService`, `ReturnTaskService`, `InboxItemProvider`, `CommentService`, `AttachmentService`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao; `DelegationExpirer` một bản nhờ ShedLock.

**FR hiện thực.** FR-11-034…044; BR-11-011, 017, 018, 019, 020, 021.

**Giao diện vào.** REST API-11-072…088, 124, 125 (`TaskController`, `InboxController`); `BpmTaskApi.listInbox` cho `dh-console`.

**Phụ thuộc ra.** `engine` (`TaskService`), PH-12 (nhóm, đơn vị, người quản lý), `resource` (biểu mẫu), `due`, Valkey (khóa nhận việc), Ceph RGW (tệp đính kèm, quét mã độc), `VariableCipher`.

**Dữ liệu.** `task_index`, `task_comment`, `task_attachment`, `delegation`.

**Sự kiện.** EVT-11-08 `task.created`, EVT-11-09 `task.assigned`, EVT-11-10 `task.completed`.

**Lỗi và xử lý.** ERR-11-007, 021, 022, 023, 024, 025, 026, 027, 050 (trả người gọi); ERR-11-113 không có ứng viên (giao nhóm `11.task.fallbackGroup`, mở sự cố); ERR-11-114 không đăng ký được hộp việc (thử lại, cảnh báo).

**Quan sát.** `datahub_bpm_task_total{kind,action}`, `datahub_bpm_task_complete_duration_seconds`, `datahub_bpm_task_unassigned`, `datahub_bpm_inbox_register_lag_seconds`; span `bpm.task.claim`, `bpm.task.complete`.
:::

`AssignmentResolver` giải ứng viên khi tạo việc theo `AssignmentType`: `USER` giữ người cụ thể (đang ủy quyền thì giao người nhận ủy quyền, ghi `delegatedFrom`); `CANDIDATE_GROUP` và `ORG_UNIT` hỏi PH-12 rồi ghi `candidate_users`, `candidate_units`; `RULE` đánh giá biểu thức trên biến đã khai báo. Không giải ra ứng viên thì chuyển nhóm `11.task.fallbackGroup` và mở sự cố, không để việc lơ lửng.

`ClaimService.claim` dùng cập nhật có điều kiện (`UPDATE ... WHERE state = 'UNASSIGNED'`, `version` lạc quan) cộng khóa Valkey ngắn 5 giây để giảm tranh chấp; người thua nhận ERR-11-021 kèm tên người nhận và thời điểm. Mất Valkey không sai kết quả vì chốt cuối là điều kiện trong câu `UPDATE` và `claim` của Flowable.

`CompleteTaskService.complete` chạy theo thứ tự: kiểm quyền người hoàn thành, kiểm `decision` và JSON Schema (ERR-11-023), mã hóa trường NC theo `field_classification`, `taskService.complete`, cập nhật `task_index`, đóng `due_tracking` (ghi `closed_late`), ghi outbox EVT-11-10. Chỉ tiêu p99 ≤ 300 ms với biểu mẫu 30 trường (NFR-11-002) nhờ DEK đã đệm và bước kế tiếp là async.

Giao diện lưu nháp việc sau `11.task.draftDebounceSeconds` giây không gõ (trường NC mã hóa); giá trị `SENSITIVE` đã mở tự che lại sau `11.task.unmaskSeconds` giây ở phía giao diện. Việc phát hành mô hình (`PUBLISH_REVIEW`) và việc bù trừ thủ công cũng là `task_index` để hiện trong hộp "Việc của tôi" (FR-00-070); `InboxItemProvider` cung cấp API-11-125 để `dh-console` hợp nhất với việc của phân hệ khác.

### 4.9. Lịch làm việc và hạn xử lý (`due`)

::: dac-ta
**Mục đích.** Quản lý lịch làm việc theo tenant (ngày nghỉ, làm bù), tính hạn xử lý cho phiên và việc theo ngày làm việc, nhắc trước hạn, xử lý quá hạn và leo thang, tạm dừng tính hạn khi chờ bổ sung, báo cáo đúng hạn, trễ hạn.

**Lớp chính.** `BusinessCalendarService`, `WorkingTimeCalculator`, `DueTrackingService`, `DueScanner`, `PauseService`, `EscalationService`, `DueReportService`.

**Đơn vị chạy.** `dh-platform`; `DueScanner` chạy một bản tại một thời điểm nhờ ShedLock (khóa theo tên, quét lần lượt từng tenant); tính hạn chạy ở mọi bản sao.

**FR hiện thực.** FR-11-045…050; BR-11-024…029; đề xuất ADR 114.

**Giao diện vào.** REST API-11-090…095 (`CalendarController`, `DueReportController`); `StartCoordinator`, `CompleteTaskService` gọi `DueTrackingService`.

**Phụ thuộc ra.** `engine` (hẹn giờ biên của Flowable cho hạn cứng), `saga` không; PH-12 (người quản lý để leo thang), `pg-core`.

**Dữ liệu.** `business_calendar`, `calendar_day`, `due_tracking`.

**Sự kiện.** EVT-11-11 `task.due-soon`, EVT-11-12 `task.overdue` (kèm leo thang), EVT-11-20 thông báo.

**Lỗi và xử lý.** ERR-11-028 (lịch không hợp lệ, 422); ERR-11-116 (năm chưa có lịch: dùng lịch mặc định, ghi cảnh báo, mở sự cố nhẹ); ERR-11-108 (hẹn giờ không chạy).

**Quan sát.** `datahub_bpm_due_scan_duration_seconds`, `datahub_bpm_due_scan_lag_seconds`, `datahub_bpm_due_soon_total`, `datahub_bpm_due_overdue_total{subject}`, `datahub_bpm_due_escalation_total{level}`, `datahub_bpm_due_paused`; span `bpm.due.scan`, `bpm.due.compute`.
:::

`WorkingTimeCalculator` là hàm thuần trên `ZonedDateTime` ở `Asia/Ho_Chi_Minh`, với tuần làm việc, khung giờ (`business_calendar.work_hours`, thường 07:30 đến 11:30 và 13:00 đến 17:00) và tập ngày đặc biệt nạp theo `(tenant, year)`. `addWorkingDays(start, n)`: đưa `start` về đầu khung giờ kế tiếp nếu ngoài giờ (`11.due.receiveAfterHoursRule`), đếm `n` ngày làm việc (bỏ `HOLIDAY`, `SPECIAL_OFF`, thêm `MAKEUP_WORKDAY`), hạn là cuối khung giờ ngày cuối; `addWorkingHours` cộng theo giờ trong khung. Thời gian đã tạm dừng cộng thêm theo giờ làm việc. Bộ 200 ca lịch mẫu (Tết, 30/4 và 1/5 liền cuối tuần, ngày làm bù, nhận 16:59 và 17:01) là tiêu chí nghiệm thu số 6.

`DueScanner` chạy mỗi `11.due.scanMinutes` trên chỉ mục một phần `ix_due_tracking_scan`, lô 500 dòng `FOR UPDATE SKIP LOCKED`: dòng đến `due_soon_at` chuyển `DUE_SOON` và phát EVT-11-11; dòng quá `due_at` chuyển `OVERDUE`, phát EVT-11-12 kèm `escalation_level` và thực hiện `EscalationAction` (`NOTIFY_MANAGER`, `REASSIGN_GROUP`, `RAISE_PRIORITY`, `OPEN_INCIDENT`). Mỗi mức leo thang chỉ gửi một lần vì `escalation_level` tăng cùng giao dịch ghi outbox. Bước không khai `afterHours` thì mức đầu 0 giờ, mỗi mức sau cách `11.escalation.nextLevelHours`; `CALENDAR_DAY` hết hạn 23:59:59 `Asia/Ho_Chi_Minh`. Quá `deadline` bổ sung thì không tự hủy: phiên giữ `PAUSED`, mở sự cố `SUPPLEMENT_EXPIRED` kèm ERR-11-125. Tắt máy rồi bật lại thì lượt quét đầu bù ngay các mốc đã qua (NFR-11-016).

Hạn cứng của một bước dùng hẹn giờ biên của Flowable, hạn mềm (nhắc, quá hạn, leo thang) đi qua `DueScanner`; tách hai loại để tính theo ngày làm việc, điều engine không biết, và không tạo hàng chục nghìn job timer (ADR 114). Tạm dừng khi chờ bổ sung (`PauseService`) ghi `paused_at`, `pause_reason`; tiếp tục thì cộng khoảng đã qua vào `paused_total_seconds` và tính lại `due_at`; `11.supplement.resetDue = true` tính lại từ đầu (Q11-03).

### 4.10. Saga bù trừ (`saga`)

::: dac-ta
**Mục đích.** Khi một bước liên thông thất bại hoặc phiên bị hủy sau khi bước khác đã ghi dữ liệu ở cơ quan khác, chạy các hành động bù trừ theo thứ tự ngược, ghi nhật ký từng bước, chuyển xử lý thủ công khi không thành, đối soát định kỳ.

**Lớp chính.** `SagaCoordinator`, `SagaPlanner`, `CompensationDispatcher`, `ManualResolutionService`, `SagaReconciler`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao điều phối (theo phiên, khóa theo `instance_id`); `SagaReconciler` một bản nhờ ShedLock theo `11.saga.reconcileCron`.

**FR hiện thực.** FR-11-051…054; BR-11-009, 012, 013; đề xuất ADR 113.

**Giao diện vào.** Nội bộ từ `bridge` khi lỗi nghiệp vụ không có biên bắt; REST API-11-096…102, 132, 133, 129 (`SagaController`, `POST /instances/{id}:compensate`, `:retry`, `:resolve-manual`, `:skip` chỉ là đề nghị bỏ qua, `:approve-skip`, `:reject-skip`, `/sagas:export`).

**Phụ thuộc ra.** `bridge` (gửi lệnh bù trừ như lệnh thường), `engine` (đổi trạng thái phiên), `task` (việc `MANUAL_COMPENSATION`), `pg-core`.

**Dữ liệu.** `saga_log`, `saga_step`, `compensation_action`, `service_call`, `task_index`.

**Sự kiện.** EVT-11-13 `compensation.started`, EVT-11-14 `completed`, EVT-11-15 `failed` (mức P1 cho PH-13).

**Lỗi và xử lý.** ERR-11-030 (phiên đang bù trừ, từ chối thao tác khác), ERR-11-110 (hành động bù trừ thất bại), ERR-11-111 (không ghi được nhật ký: dừng bước, không đặt `DONE`), ERR-11-112 (bước không có bù trừ: chuyển thủ công), ERR-11-121 (đối soát phát hiện bù trừ chưa có hiệu lực).

**Quan sát.** `datahub_bpm_saga_started_total{trigger}`, `datahub_bpm_saga_duration_seconds`, `datahub_bpm_saga_step_total{status}`, `datahub_bpm_saga_manual_pending`, `datahub_bpm_saga_reconcile_mismatch_total`; span `bpm.saga.run`, `bpm.saga.step`.
:::

`SagaPlanner` lập kế hoạch khi Saga bắt đầu: lấy các bước đã `COMPLETED` trong `instance_step` mà có `compensation_action`, xếp theo thời điểm hoàn thành giảm dần, bước cùng mức song song được bù trừ song song, bước chưa xong đặt `SKIPPED`, bước `policy = MANUAL` hay không có hành động đặt `MANUAL`. `CompensationDispatcher` gửi lệnh bù trừ bằng đúng đường của `bridge` (cùng outbox, `commandId` mới, ý định bù trừ), và chỉ đặt `DONE` sau khi ghi `saga_step` kèm `response_code`, `evidence` (BR-11-013). Lượt thử theo `11.saga.maxRetries` (mặc định 3) và giãn cách `11.saga.retryBackoffSeconds` (mặc định 300 giây, nhân đôi mỗi lượt); hết lượt thì `FAILED` rồi `MANUAL` kèm việc `MANUAL_COMPENSATION` cho nhóm xử lý.

Bù trừ không phải "xóa": ví dụ khai sinh đã cấp thì hành động là "đánh dấu chờ xử lý" chứ không xóa văn bản đã phát hành (`business_note` ghi lý do nghiệp vụ). Điều kiện `requireForwardSuccess` kiểm `service_call` xuôi `COMPLETED` thật mới bù, tránh hủy thứ chưa tạo. Kết thúc: mọi bước `DONE` hoặc `SKIPPED` thì `SUCCEEDED`, phiên `COMPENSATED`, phát EVT-11-14; còn bước `MANUAL` chưa xong thì `PARTIAL`, phiên `FAILED`, phát EVT-11-15 và việc thủ công. `SagaReconciler` định kỳ gọi ý định kiểm tra (`verify_intent_code`) cho bước `DONE` để xác nhận hiệu lực bù trừ ở cơ quan đích, lệch thì ERR-11-121 và mở sự cố `COMPENSATION_FAILED`.

### 4.11. Tiến độ cho kênh DVC (`progress`)

::: dac-ta
**Mục đích.** Cung cấp cho Cổng DVC tiến độ hồ sơ che dữ liệu cá nhân, phát sự kiện tiến độ mỗi lần chuyển bước, tra lịch sử bước phục vụ kiểm toán.

**Lớp chính.** `ProgressService`, `PublicStepMapper`, `DisplayStatusMapper`, `PiiMaskGuard`, `ProgressCache`, `StepEventPublisher`, `HistoryQueryService`.

**Đơn vị chạy.** `dh-platform`, mọi bản sao (không trạng thái, đệm Valkey dùng chung).

**FR hiện thực.** FR-11-055, 056, 057; BR-11-014, 030, 031.

**Giao diện vào.** REST API-11-104 `GET /progress/{businessKey}` (scope `bpm.progress.read`), API-11-105, 106 (lịch sử, xuất), API-11-128, 130 (xuất CSV nền); Kafka nội bộ từ `ProjectionListener` cho `StepEventPublisher`.

**Phụ thuộc ra.** Valkey, `pg-core` (`instance_index`, `instance_step`), `OutboxWriter`.

**Dữ liệu.** `instance_index.progress_public`, `instance_step`; không đọc biến của engine.

**Sự kiện.** EVT-11-04 `instance.step.completed` (tiến độ).

**Lỗi và xử lý.** ERR-11-035 (404, không lộ tồn tại khi client không có quan hệ với hồ sơ), ERR-11-034 (403 ngoài phạm vi dữ liệu), ERR-11-039 (khoảng xuất quá giới hạn).

**Quan sát.** `datahub_bpm_progress_request_total{result}`, `datahub_bpm_progress_duration_seconds`, `datahub_bpm_progress_cache_hit_ratio`, `datahub_bpm_progress_event_lag_seconds`; span `bpm.progress.get`.
:::

Che DLCN được thiết kế theo nguyên tắc "cho phép rõ ràng" (allow-list) thay cho "che những gì nhạy cảm". Chỉ bước có `publicName` (do người thiết kế đặt ở thuộc tính bước, luật `NO_PUBLIC_NAME` cảnh báo nếu không có bước nào) mới xuất hiện; mỗi bước báo `PublicStepStatus` (`DONE`, `IN_PROGRESS`, `PENDING`), phiên báo `DisplayStatus` (`RECEIVED`, `IN_PROGRESS`, `WAITING_SUPPLEMENT`, `COMPLETED`, `REJECTED`, `CANCELLED`), `dueAt`, `percentEstimate` và một câu thông điệp theo mẫu. Không bao giờ có biến, tên cán bộ, mã lỗi kỹ thuật, tên HTTT. `PublicStepMapper` dựng khung tiến độ từ định nghĩa BPMN một lần khi khởi tạo (danh sách bước công khai theo thứ tự đồ thị, quy trình con gộp vào vị trí bước gọi) và lưu `progress_public`; mỗi lần chuyển bước chỉ cập nhật trạng thái các bước, không đọc lại engine. `PiiMaskGuard` còn là chốt cuối: duyệt cây JSON trả về và từ chối (lỗi 500, cảnh báo ATTT, đếm chỉ số) nếu thấy khóa ngoài danh sách cho phép, để một lỗi lập trình không biến thành rò rỉ.

`ProgressCache` đệm theo khóa `dh:{tenant}:bpm:progress:{businessKey}` trong `11.progress.cacheSeconds` (mặc định 30 giây, tỷ lệ trúng ≥ 80% theo NFR-11-006) và vô hiệu ngay khi `ProjectionListener` cập nhật bản chiếu của hồ sơ đó. Quan hệ client với hồ sơ lấy từ `instance_index.system_code` và `started_by` khi khởi tạo; client khác kênh nhận ERR-11-035 như không có hồ sơ. Mọi lượt tra ghi nhật ký truy cập (client, `businessKey`, thời điểm), không ghi nội dung trả về.

### 4.12. Giám sát, sự cố và vận hành (`ops`)

::: dac-ta
**Mục đích.** Bảng điều khiển giám sát, phát hiện tắc nghẽn bước, quản lý sự cố engine và thử lại, chỉ số và cảnh báo, tham số `11.*` theo tenant, lưu giữ và dọn lịch sử, xuất bằng chứng tuân thủ BPMN 2.0, nhật ký kiểm toán phân hệ, gợi ý AI mức C.

**Lớp chính.** `MonitoringService`, `BottleneckDetector`, `IncidentService`, `AlertRuleService`, `MetricsBinder`, `TenantSettingService`, `RetentionPurgeJob`, `PartitionMaintenanceJob`, `EvidencePackBuilder`, `AuditLogService`, `AiSuggestionClient`.

**Đơn vị chạy.** `dh-platform`; mọi job nền dùng ShedLock (bảng `shedlock`), chạy lần lượt từng tenant.

**FR hiện thực.** FR-11-058…066; BR-11-032…038.

**Giao diện vào.** REST API-11-107…124, 134, 135, 137 (`MonitoringController`, `IncidentController`, `SettingController`, `ComplianceController`); lịch cron của Spring.

**Phụ thuộc ra.** `engine` (`ManagementService`: job, dead letter job), PH-13 (cảnh báo, kiểm toán), PH-17 (gợi ý), Ceph RGW (gói bằng chứng), `pg-core`.

**Dữ liệu.** `incident`, `tenant_setting`, `instance_step`, `shedlock`; đọc `ACT_RU_DEADLETTER_JOB` qua `ManagementService`.

**Sự kiện.** EVT-11-16 `incident.opened`.

**Lỗi và xử lý.** ERR-11-029 (tham số ngoài miền hoặc vượt trần), ERR-11-039 (khoảng quá 366 ngày, 422), ERR-11-047 (hồ sơ đang giữ pháp lý, không dọn; gỡ giữ bằng `:release`), ERR-11-115 (phiên tắc quá ngưỡng), ERR-11-122 (dọn lịch sử lỗi), ERR-11-124 (gợi ý AI quá thời gian, bỏ qua).

**Quan sát.** `datahub_bpm_incident_open{type}`, `datahub_bpm_bottleneck_total`, `datahub_bpm_history_purge_rows_total{object}`, `datahub_bpm_job_duration_seconds{job}`, `datahub_bpm_setting_change_total`; span `bpm.ops.purge`, `bpm.ops.evidence`.
:::

`IncidentService` gom mọi nguồn lỗi vận hành về `incident` theo `IncidentType` của FRS Phụ lục A.1 (`JOB_FAILED`, `SERVICE_TIMEOUT`, `CORRELATION_FAILED`, `TIMER_FAILED`, `COMPENSATION_FAILED`, `STUCK_INSTANCE`, `ENGINE_ERROR`, `SUPPLEMENT_EXPIRED`). `DeadLetterWatcher` (60 giây) đọc dead letter job, tạo `incident` có khóa duy nhất `(tenant, flowable_job_id)`; `:retry` gọi `moveDeadLetterJobToExecutableJob` và đặt `RETRYING`; `:ignore` cần lý do từ 20 ký tự. `BottleneckDetector` so thời gian chờ của bước với p95 lịch sử khi có từ `11.bottleneck.minSamples` mẫu và vượt `11.bottleneck.factor` lần, kèm ngưỡng `11.instance.stuckHours` cho phiên. `RetentionPurgeJob` (01:00) xóa theo lô con trước cha các bản chiếu quá hạn, bỏ qua hồ sơ đang giữ pháp lý (ERR-11-047); `PartitionMaintenanceJob` (00:05) tạo phân vùng `instance_step`, tháo và xóa phân vùng quá hạn; cả hai chạy ngoài giờ cao điểm (NFR-11-024).

`EvidencePackBuilder` dựng gói tuân thủ (FR-11-064): XML BPMN 2.0, kết quả kiểm tra theo XSD, biên bản chạy mẫu, lịch sử phiên và thuyết minh BPMN kế thừa vai trò WS-BPEL theo CV 631, ghi ở Ceph RGW kèm băm. Phương án dự phòng nếu thẩm định bắt buộc BPEL thật là Q11-27.

### 4.13. Trình thiết kế BPMN (giao diện, bpmn-js)

::: dac-ta
**Mục đích.** Cho kỹ sư tích hợp vẽ, cấu hình và kiểm tra mô hình BPMN 2.0 ngay trong `dh-console`; nhập, xuất tệp; hiện kết quả kiểm tra tĩnh và nhảy tới phần tử lỗi.

**Lớp chính.** `BpmnDesigner` (bọc `bpmn-js` Modeler), `PropertyPanel` (antd v6, theo `StepType`), `ElementPalette` (hạn chế bảng phần tử theo `element-catalog`), `CheckResultPane`, `VersionDiffView`, `LockBanner`, `DesignerClient`.

**Đơn vị chạy.** Trình duyệt, mã tĩnh phục vụ qua `dh-console` (không máy chủ riêng).

**FR hiện thực.** FR-11-003, 004, 005, 006, 010; NFR-11-014, 022.

**Giao diện vào.** Người dùng ở UI-11-04 (PTN-07), tới `/quy-trinh/mo-hinh/{ma}/thiet-ke`.

**Phụ thuộc ra.** REST API-11-012 (khóa), 014 (kiểm tra), 015 (lưu nháp), 016 (gửi duyệt), `GET /element-catalog`; không gọi PH-04 trực tiếp.

**Dữ liệu.** Chỉ giữ BPMN XML trong bộ nhớ trình duyệt; bản nháp lưu bằng API, không dùng `localStorage` làm nguồn sự thật.

**Sự kiện.** Không.

**Lỗi và xử lý.** Hiển thị ERR-11-004, 008, 010, 016 theo thông báo ở FRS 9.2 (băng khóa, ngăn kết quả kiểm tra).

**Quan sát.** `designer_open_ms`, `designer_validate_ms` gửi qua `dh-console` tới PH-13 (không có nội dung mô hình).
:::

Giấy phép bpmn.io cho dùng bpmn-js miễn phí kể cả thương mại với điều kiện giữ logo bpmn.io hiển thị và không che hay xóa liên kết; thiết kế để logo ở góc dưới phải khung vẽ, không có tùy chọn ẩn, UI-11-04 ghi chú (ADR 111). `ElementPalette` hạn chế theo bảng 6.2-a của FRS (không script task); bảng thuộc tính dựng bằng antd v6 theo `StepType` và ghi thuộc tính `flowable:triggerable`, `flowable:async`, `datahub:intentCode`, `datahub:publicName`, `datahub:dueValue`, `datahub:dueUnit` vào `extensionElements` qua một moddle descriptor riêng; Flowable bỏ qua `datahub:*` khi triển khai, `StaticCheckEngine` đọc chúng. Thao tác bàn phím theo WCAG 2.2 AA (NFR-11-022); mở mô hình 300 phần tử ≤ 3 giây (NFR-11-014).

### 4.14. Xử lý đồng thời

Ba nơi có tranh chấp thật. Một: hai người cùng nhận một việc (mục 4.8). Hai: hai yêu cầu khởi tạo cùng `businessKey`, giải bằng `pg_advisory_lock(hashtextextended(tenant || ':' || modelCode || ':' || businessKey, 0))` trên kết nối `ph11_app`, giữ trong `StartCoordinator.start` (dự kiến dưới 200 ms) và nhả ở `finally`. Ba: cập nhật bản chiếu từ sự kiện của cùng phiên đến sai thứ tự; `ProjectionListener` chỉ ghi khi "tiến hơn" theo `instance_step.started_at` và số thứ tự sự kiện.

Khóa lạc quan `version` (ETag, ERR-11-004) áp dụng cho mọi thao tác người dùng sửa dữ liệu. Job nền dùng ShedLock cho loại một-bản (`DueScanner`, `TimeoutSweeper`, `OutboxCleaner`, `SagaReconciler`, `RetentionPurgeJob`, `PartitionMaintenanceJob`, `DelegationExpirer`, `ProjectionReconciler`, `StartRecoveryJob`) và `SKIP LOCKED` cho lô song song trong một job.

### 4.15. Bộ đệm

Valkey chỉ giữ dữ liệu có thể dựng lại: khóa lũy đẳng khởi tạo `dh:{tenant}:bpm:idem:{khóa}` (24 giờ, rơi về `uq_instance_index_correlation`), tiến độ `dh:{tenant}:bpm:progress:{businessKey}` (`11.progress.cacheSeconds`), khóa nhận việc `dh:{tenant}:bpm:claim:{taskId}` (5 giây), ánh xạ luồng PH-04 (60 giây). Lịch làm việc theo `(tenant, year)` và DEK giải mã (5 phút) nằm trong bộ nhớ JVM. Mất Valkey chỉ làm chậm hoặc tăng tranh chấp, không mất dữ liệu hay sai kết quả (CSDL mục 6.4).

### 4.16. Mã hóa biến Nhạy cảm theo ADR-032

Biến được khai báo ở `variable_definition` với `data_class` (`PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`) và cờ `encrypt`, `mask`. Với `SENSITIVE` (NC), `VariableCipher` mã hóa envelope trước khi đặt biến vào engine: khóa mã hóa dữ liệu (DEK) ngẫu nhiên cho mỗi giá trị bọc bởi KEK theo tenant `dh-{tenant}-bpm-pii` ở OpenBao transit; bản mã và `kid` đặt vào biến dạng đối tượng `{ "enc": "<base64>", "kid": "..." }`; AAD gồm `tenant_id` và tên biến nên bản mã chép sang tenant khác không giải được. Quy tắc theo từng đường:

| Đường | Xử lý biến NC |
|---|---|
| Biến trong engine (`ACT_RU_VARIABLE`, `ACT_HI_*`) | Chỉ bản mã; quét mẫu không thấy giá trị rõ (NFR-11-021) |
| Lệnh Kafka tới PH-04 | Thay bằng tham chiếu `bpm-secret:{id}`; PH-04 đổi qua API nội bộ mTLS (BR-11-014) |
| Sự kiện EVT-11-xx, `outbox_event` | Không bao giờ mang giá trị biến (hai chốt ở mục 3.2) |
| Bản chiếu, `progress_public` | Không có biến |
| Log, trace, chỉ số | `@Classified` che theo SEC-32; không biến nào làm nhãn chỉ số |
| Biểu thức điều kiện cổng | Chỉ dùng biến không NC; luật `CONDITION_UNKNOWN_VAR` và `SENSITIVE_IN_PUBLIC` chặn khi thiết kế |
| Hiển thị cho cán bộ | Giải mã ở `CompleteTaskService` và API chi tiết việc, che theo quyền, ghi nhật ký truy cập |

: Xử lý biến Nhạy cảm theo từng đường

OpenBao ngừng thì không đặt được biến NC và không hoàn thành được việc có trường NC (lỗi ERR-11-046); tiến độ vẫn trả được vì không dùng biến (CSDL mục 6.5). Đổi KEK dùng `kid` mới cho bản ghi mới, bản cũ giải được bằng `kid` cũ cho tới khi `REENCRYPT` chạy (Q11-26).

## 5. Biểu đồ tuần tự

Bảy sơ đồ dưới đây phủ các luồng nhiều thành phần hoặc có bốn mắt của PH-11. Mỗi sơ đồ có đoạn thuyết minh nói điều người đọc cần thấy, đặc biệt là chỗ nào nguyên tử, chỗ nào chỉ nhất quán cuối cùng.

### 5.1. Phát hành mô hình bốn mắt và triển khai lên engine (FR-11-005, 007, 008)

Luồng này bảo đảm không phiên bản nào lên engine mà chưa được hai người xem.

```{.mermaid caption="Trình tự gửi duyệt, duyệt bốn mắt và triển khai mô hình lên Flowable"}
sequenceDiagram
  autonumber
  actor IE as Kỹ sư tích hợp
  actor IA as Người duyệt
  participant API as ModelController
  participant CHK as StaticCheckEngine
  participant PUB as PublishApprovalService
  participant DEP as DeploymentService
  participant ENG as Flowable
  participant DB as ph11_bpm
  participant OB as outbox_event
  IE->>API: POST :submit phiên bản DRAFT, ghi chú thay đổi
  API->>CHK: validate FULL
  CHK-->>API: không còn lỗi ERROR
  API->>DB: version IN_REVIEW, publish_request PENDING, checksum
  API->>DB: tạo việc PUBLISH_REVIEW cho nhóm IA
  IA->>API: POST publish-requests/{id}:approve, ý kiến
  API->>PUB: approve(requestId, user)
  PUB->>DB: đọc request, version, updatedBy cuối
  PUB-->>API: ERR-11-005 nếu người duyệt trùng người gửi hoặc người sửa
  PUB->>DEP: deploy(version)
  DEP->>CHK: validate FULL lần nữa, kiểm checksum
  DEP->>ENG: createDeployment tenantId, tên processKey:v{n}
  ENG-->>DEP: deploymentId, processDefinitionId
  DEP->>DB: một giao dịch, version PUBLISHED, bản cũ DEPRECATED, request APPROVED
  DEP->>OB: EVT-11-01 model.published
  DEP-->>API: 200 phiên bản PUBLISHED
  Note over DEP,ENG: nếu giao dịch DB lỗi sau khi engine đã triển khai thì xóa triển khai và trả ERR-11-046
```

Điểm cần thấy: kiểm tra tĩnh chạy hai lần ở máy chủ (lúc gửi và lúc duyệt) với kiểm checksum giữa hai lần, nên không ai đổi nội dung giữa lúc gửi và lúc duyệt; người duyệt khác người gửi được kiểm trước khi chạm engine. Khoảng hở duy nhất là giữa triển khai engine và giao dịch nghiệp vụ, xử lý bằng bước xóa triển khai bù (mục 4.3).

### 5.2. Khởi tạo phiên idempotent (FR-11-018, NFR-11-001)

Luồng này là cửa vào chính của liên thông, phải idempotent vì bên gọi có thể gửi lại.

```{.mermaid caption="Trình tự khởi tạo phiên idempotent theo businessKey và Idempotency-Key"}
sequenceDiagram
  autonumber
  participant DVC as Cổng DVC
  participant GW as APISIX
  participant CT as InstanceController
  participant VK as Valkey
  participant SC as StartCoordinator
  participant ENG as Flowable
  participant DB as ph11_bpm
  DVC->>GW: POST /instances, Idempotency-Key, businessKey
  GW->>CT: JWT hợp lệ, scope bpm.instance.start
  CT->>VK: GET idem theo khóa
  VK-->>CT: trúng thì trả phản hồi lần đầu 200
  CT->>SC: start(request)
  SC->>DB: pg_advisory_lock theo tenant, mô hình, businessKey
  SC->>DB: tìm phiên chưa kết thúc theo businessKey
  DB-->>SC: có và cùng dấu vân tay thân thì trả phiên cũ, khác thì ERR-11-018
  SC->>ENG: tìm theo businessKey và tenantId, phát hiện phiên mồ côi
  SC->>ENG: startProcessInstanceByKeyAndTenantId, bước đầu async
  ENG-->>SC: processInstanceId
  SC->>DB: một giao dịch, instance_index, due_tracking hạn phiên, outbox EVT-11-03
  SC->>DB: pg_advisory_unlock
  SC->>VK: SET idem, 24 giờ
  SC-->>DVC: 201, instanceId, state RUNNING
```

Điểm cần thấy: DVC nhận `201` ngay khi bản chiếu và sự kiện cam kết, không chờ cơ quan nào vì bước đầu là async. Khoảng hở giữa "engine đã tạo phiên" và "bản chiếu đã ghi" không gây phiên đúp: khóa tư vấn chặn khởi tạo song song cùng hồ sơ, gọi lại tìm thấy phiên mồ côi theo `businessKey` rồi dựng nốt bản chiếu, và `StartRecoveryJob` làm điều tương tự khi bên gọi không gọi lại. Kiểm tra quyền, hạn mức và biến vào nằm trước khóa nên lượt bị từ chối không giữ khóa.

### 5.3. Service task qua outbox, Kafka, PH-04 và inbox tương quan (FR-11-028, 029)

Luồng này là ranh giới giữa PH-11 và PH-04.

```{.mermaid caption="Trình tự service task: lệnh qua outbox, kết quả qua inbox và đánh thức execution"}
sequenceDiagram
  autonumber
  participant ENG as Flowable async job
  participant SB as ServiceTaskBehavior
  participant DB as ph11_bpm
  participant DBZ as Debezium
  participant K as Kafka
  participant P04 as PH-04
  participant RC as ResultConsumer
  participant CS as CorrelationService
  ENG->>SB: execute(execution) trong job async
  SB->>SB: dựng payload, kiểm inputSchema, thay biến NC bằng tham chiếu
  SB->>DB: REQUIRES_NEW, service_call REQUESTED, outbox service.requested, commandId xác định
  SB-->>ENG: trả về, execution đứng ở WAITING_SERVICE
  DBZ->>DB: đọc outbox_event
  DBZ->>K: t68.bpm.service.requested.v1, khóa businessKey
  K->>P04: lệnh, chống trùng theo commandId
  P04->>P04: chạy luồng Camel theo intentCode, thử lại kỹ thuật
  P04->>K: service.completed hoặc service.failed, commandId
  K->>RC: bản tin kết quả
  RC->>DB: chèn inbox_message, trùng khóa thì bỏ qua và đếm
  RC->>CS: correlate(commandId)
  CS->>DB: tìm service_call, không thấy thì DLQ và sự cố
  CS->>ENG: ghi biến kết quả, trigger(executionId)
  CS->>DB: service_call COMPLETED, outbox EVT-11-04 tiến độ
  RC->>K: commit offset
```

Điểm cần thấy: không giao dịch nào trải qua cả engine và Kafka. "Đúng một lệnh" đạt bằng ba lớp: `commandId` xác định nên chèn outbox lại bị bỏ qua, PH-04 chống trùng theo `commandId`, và `inbox_message` khóa chính theo `messageId` nên kết quả lặp chỉ xử lý một lần (ADR-041, ADR-042). Nếu `trigger` thành công mà ghi `service_call` lỗi, bản tin giao lại, `trigger` lần hai bỏ qua rồi ghi nốt. PH-04 không trả lời thì `TimeoutSweeper` hoặc hẹn giờ biên xử lý (mục 4.7).

### 5.4. Hạn theo lịch làm việc: tính, nhắc, quá hạn, tạm dừng (FR-11-046…049)

Luồng này cho thấy ai tính hạn, ai quét và khi nào tạm dừng.

```{.mermaid caption="Trình tự tính hạn theo ngày làm việc, nhắc hạn, leo thang và tạm dừng khi chờ bổ sung"}
sequenceDiagram
  autonumber
  participant SC as StartCoordinator
  participant DT as DueTrackingService
  participant WT as WorkingTimeCalculator
  participant CAL as BusinessCalendarService
  participant DB as ph11_bpm
  participant DS as DueScanner
  participant ES as EscalationService
  participant OB as outbox_event
  SC->>DT: open(INSTANCE, startAt, slaDays)
  DT->>CAL: calendar(tenant, năm)
  CAL-->>DT: tuần làm việc, khung giờ, ngày nghỉ, ngày làm bù
  DT->>WT: addWorkingDays(startAt, slaDays)
  WT-->>DT: dueAt, dueSoonAt theo 11.task.dueSoonHours
  DT->>DB: due_tracking ON_TIME
  loop mỗi 11.due.scanMinutes, khóa ShedLock
    DS->>DB: chọn lô đến due_soon_at hoặc quá due_at, SKIP LOCKED
    DS->>DB: DUE_SOON hoặc OVERDUE, escalation_level tăng
    DS->>OB: EVT-11-11 hoặc EVT-11-12 cùng giao dịch
    DS->>ES: escalate(subject, level)
  end
  Note over DT,DB: người dùng yêu cầu bổ sung hồ sơ
  DT->>DB: PAUSED, paused_at, pause_reason
  Note over DT,DB: nhận đủ bổ sung
  DT->>WT: cộng khoảng tạm dừng theo giờ làm việc
  DT->>DB: ON_TIME, tính lại dueAt, paused_total_seconds
```

Điểm cần thấy: tính hạn là hàm thuần nên kiểm thử được bằng 200 ca lịch mẫu; quét hạn chạy ngoài engine nhưng cùng giao dịch với ghi outbox, nên không có nhắc hạn nào "đã gửi mà chưa ghi" hoặc ngược lại. Tạm dừng loại thời gian chờ bổ sung khỏi hạn nhưng vẫn ghi `paused_total_seconds` để báo cáo đúng hạn, trễ hạn có căn cứ (FR-11-050).

### 5.5. Saga bù trừ khi nhánh BHYT lỗi (FR-11-051, 053)

Luồng này minh họa ví dụ xuyên suốt khi nhánh BHYT lỗi.

```{.mermaid caption="Trình tự Saga bù trừ cho LT_KHAI_SINH khi cấp thẻ BHYT thất bại sau khi thường trú đã xong"}
sequenceDiagram
  autonumber
  participant RC as ResultConsumer
  participant SG as SagaCoordinator
  participant PL as SagaPlanner
  participant CD as CompensationDispatcher
  participant DB as ph11_bpm
  participant K as Kafka
  participant P04 as PH-04
  participant TK as task
  RC->>SG: lỗi BUSINESS BHXH_TIMEOUT không có biên bắt
  SG->>DB: phiên COMPENSATING, saga_log RUNNING
  SG->>DB: outbox EVT-11-13 compensation.started
  SG->>PL: plan(instance)
  PL->>DB: bước đã xong có bù trừ, xếp ngược theo thời điểm
  PL-->>SG: saga_step PENDING huyDangKyThuongTru, danhDauChoXuLy
  loop từng bước, bước cùng mức chạy song song
    SG->>CD: dispatch(step)
    CD->>DB: saga_step RUNNING, service_call mới, outbox lệnh bù trừ
    DB->>K: lệnh bù trừ qua Debezium
    K->>P04: thực thi ý định bù trừ
    P04->>K: completed hoặc failed
    K->>CD: kết quả
    CD->>DB: ghi nhật ký rồi mới đặt saga_step DONE
  end
  alt mọi bước DONE hoặc SKIPPED
    SG->>DB: saga_log SUCCEEDED, phiên COMPENSATED, EVT-11-14
  else hết lượt thử hoặc policy MANUAL
    SG->>TK: tạo việc MANUAL_COMPENSATION cho nhóm xử lý
    SG->>DB: saga_log PARTIAL, phiên FAILED, EVT-11-15
  end
```

Điểm cần thấy: bù trừ dùng đúng đường lệnh của service task nên được hưởng cùng bảo đảm chống trùng và nhật ký; "bù trừ" không phải xóa, mà là hành động nghiệp vụ do người thiết kế đăng ký (ví dụ đánh dấu hồ sơ khai sinh chờ xử lý thay vì xóa văn bản đã phát hành). Khi tự động không thành thì luôn có người nhận việc thủ công và có sự kiện P1, không bao giờ im lặng (BR-11-012).

### 5.6. Tiến độ cho Cổng DVC có che DLCN (FR-11-055, 056)

Luồng này là đường duy nhất Cổng DVC thấy được hồ sơ.

```{.mermaid caption="Trình tự tra tiến độ hồ sơ cho Cổng DVC qua đệm Valkey và lớp che DLCN"}
sequenceDiagram
  autonumber
  participant DVC as Cổng DVC
  participant GW as APISIX
  participant PC as ProgressController
  participant PS as ProgressService
  participant VK as Valkey
  participant DB as ph11_bpm
  participant PM as PiiMaskGuard
  DVC->>GW: GET /progress/{businessKey}, scope bpm.progress.read
  GW->>PC: yêu cầu đã xác thực
  PC->>PS: progressOf(businessKey, clientId)
  PS->>VK: GET progress theo tenant và businessKey
  alt trúng đệm
    VK-->>PS: ProgressView đã che
  else trượt đệm
    PS->>DB: instance_index, progress_public, quan hệ client
    DB-->>PS: dòng hoặc không có
    PS->>PM: kiểm cây JSON theo danh sách cho phép
    PM-->>PS: ProgressView sạch
    PS->>VK: SET progress, 11.progress.cacheSeconds
  end
  PS->>DB: ghi nhật ký truy cập, không ghi nội dung
  PS-->>DVC: 200 bước công khai, displayStatus, dueAt, không có DLCN
  Note over PS,DVC: không có quan hệ client với hồ sơ thì 404 ERR-11-035
```

Điểm cần thấy: đường đọc chỉ chạm bản chiếu và đệm, không bao giờ chạm engine hay biến, nên không có đường rò biến NC qua API này; `PiiMaskGuard` là chốt cuối nếu có lỗi lập trình ở `PublicStepMapper`. Đường đẩy tiến độ cho kênh sự kiện (EVT-11-04) dùng cùng `progress_public` nên hai kênh luôn khớp nhau (Q11-05).

### 5.7. Đồng bộ bản chiếu instance_index, task_index (FR-11-021, 035, 056)

Luồng này giữ bản chiếu khớp với engine.

```{.mermaid caption="Trình tự đồng bộ bản chiếu từ sự kiện engine sau commit, kèm đối soát định kỳ"}
sequenceDiagram
  autonumber
  participant ENG as Flowable
  participant ED as ProcessEventDispatcher
  participant PL as ProjectionListener
  participant DB as ph11_bpm
  participant OB as outbox_event
  participant PR as ProjectionReconciler
  participant VK as Valkey
  ENG->>ENG: commit giao dịch engine
  ENG->>ED: sự kiện sau commit, ACTIVITY_COMPLETED, TASK_CREATED, PROCESS_COMPLETED
  ED->>PL: apply(event) với TenantContext từ tenantId
  PL->>DB: một giao dịch, upsert instance_index, instance_step, task_index nếu tiến hơn
  PL->>DB: cập nhật progress_public, current_activities
  PL->>OB: EVT-11-04, 08, 09, 05 theo loại sự kiện
  PL->>VK: vô hiệu đệm tiến độ của hồ sơ
  loop mỗi 1 phút, khóa ShedLock
    PR->>ENG: phiên và việc đang chạy cập nhật gần đây
    PR->>DB: so với instance_index, task_index
    PR->>DB: sửa lệch, ghi projection_drift, quá ngưỡng thì mở sự cố
  end
```

Điểm cần thấy: bản chiếu ghi sau khi engine commit nên có độ trễ nhỏ (sự kiện tiến độ ≤ 10 giây, NFR-11-018) và có thể sót nếu pod chết giữa chừng; `ProjectionReconciler` là bộ sửa chữa chứ không phải đường chính. Engine là nguồn sự thật, không quyết định nghiệp vụ nào đọc bản chiếu. Sau khôi phục sao lưu, đối soát chạy toàn bộ trước khi mở lại API (Q11-54 của CSDL).

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph11_bpm` có `tenant_id` và `FORCE ROW LEVEL SECURITY` theo `app.tenant_id` (ADR-003, D03-10); `process_template` dùng mẫu S (tenant đọc thêm dòng `COMMON`). Bộ lọc Spring Security đọc tenant từ token, đặt `TenantContext`, và `TenantSession` chạy `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch; mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Năm điểm riêng của PH-11:

1. **Engine**: `TenantEngineFacade` lấy `tenantId` từ `TenantContext`, không từ tham số; engine không có RLS nên đây là chốt duy nhất, được ArchUnit bảo vệ (mục 3.2) và kiểm thử cô lập (mục 12).
2. **Job engine** chạy ngoài yêu cầu HTTP: `ProcessEventDispatcher` và `ServiceTaskBehavior` khôi phục `TenantContext` từ `tenantId` của execution trước khi chạm `ph11_bpm`; thiếu `tenantId` thì job lỗi chứ không chạy với tenant rỗng.
3. **Tác vụ nền** (`DueScanner`, `RetentionPurgeJob`, `TimeoutSweeper`, `ProjectionReconciler`) lặp từng tenant `ACTIVE`, đặt `TenantContext` tường minh; khóa ShedLock có tên kèm loại việc và không kèm tenant vì job lặp trong thân; không có tác vụ "không tenant".
4. **Kafka**: tiền tố topic mang tenant thường (`t68.bpm.…`), ràng buộc `ck_outbox_event_prefix` và `ck_inbox_message_prefix` bảo đảm tiền tố khớp `tenant_id`; `ResultConsumer` lấy tenant từ tiền tố topic và đối chiếu với `service_call.tenant_id`, lệch thì bỏ và cảnh báo.
5. **Khóa mật mã, đệm, tên khóa**: KEK `dh-{tenant}-bpm-pii`, khóa Valkey có `{tenant}`, AAD của bản mã có `tenant_id`. Mẫu `COMMON` triển khai lại dưới `tenantId` của tenant dùng (mục 4.2) nên không có định nghĩa engine chung.

Hai thao tác cần ngữ cảnh `PLATFORM`: PA sửa mẫu `COMMON` (ERR-11-036 nếu không phải PA) và đọc số liệu liên tenant của bảng điều khiển nền tảng, đều đi qua `TenantContext` đặc biệt có ghi kiểm toán.

## 7. Bảo mật

Kiểm tra quyền ở máy chủ, độc lập với giao diện: APISIX xác minh token và gọi OPA thô (SEC-26); `dh-platform` kiểm lại `PERM-11-*` và phạm vi dữ liệu ở từng `Controller` bằng OPA, rồi tới kiểm tra riêng của nghiệp vụ. Bảng dưới liệt kê các kiểm soát và ràng buộc `SEC-*` đã có (không tạo mới).

| Kiểm soát | Hiện thực | SEC |
|---|---|---|
| Xác thực, ủy quyền | OIDC qua BFF cho người; `client_credentials` cho máy; scope `bpm.instance.start`, `bpm.instance.read`, `bpm.task.read`, `bpm.progress.read`, `bpm.service.worker`; quyền `PERM-11-read`, `-model`, `-publish`, `-instance`, `-instance-admin`, `-task`, `-task-admin`, `-compensate`, `-config`, `-audit-read` | SEC-21, 24, 26 |
| Phạm vi dữ liệu | Phiên, việc xem theo đơn vị của người dùng (PH-12) và quan hệ client với hồ sơ; vi phạm trả ERR-11-034 hoặc 404 ERR-11-035 | SEC-26 |
| Tách nhiệm vụ, bốn mắt | Duyệt phát hành, sửa biến, chuyển bước, di trú phiên cần người thứ hai khác người đề nghị (ERR-11-005) kiểm ở `PublishApprovalService`, `InstanceChangeService`, `MigrationService`; dùng chung cơ chế ADR-046 | SEC-28 |
| Mã hóa biến NC | Envelope theo ADR-032, mục 4.16; quét `ACT_*` không còn giá trị rõ | SEC-31, 34 |
| Che dữ liệu | `@Classified` ở log, `PiiMaskGuard` ở tiến độ, không giá trị biến ở nhãn chỉ số hay trace | SEC-32 |
| Tin cậy giữa PH-11 và PH-04 | Kafka ACL theo tenant (topic `{tenant}.bpm.*`), PH-04 dùng `bpm.service.worker`; API đổi tham chiếu `bpm-secret` dùng mTLS Istio | SEC-15, 24 |
| An toàn trình thiết kế | Không script task; biểu thức hạn chế; phân tích XML chống XXE; giới hạn cỡ | SEC-43, 46 |
| Tệp đính kèm | Tika kiểm kiểu theo nội dung, quét mã độc, giới hạn `11.task.attachmentMaxMb`, mã hóa phía máy chủ ở Ceph RGW | SEC-45 |
| Nhật ký kiểm toán | Mọi thao tác quản trị, duyệt, sửa biến, chuyển bước, xem dữ liệu NC, xuất gửi PH-13 qua outbox; WORM 5 năm theo chính sách chung | SEC-37, 39 |
| Cô lập mạng | `NetworkPolicy` từ chối mặc định; `dh-platform` ra tới Kafka, Valkey, `pg-core`, OpenBao, Ceph RGW, PH-12; không có đường tới HTTT chuyên ngành | SEC-14, 16 |

: Kiểm soát bảo mật của PH-11

Rủi ro riêng của BPM: người thiết kế mô hình là điểm tấn công vì mô hình là mã chạy được, nên có ba lớp phòng (phần tử trong danh sách cho phép, biểu thức chỉ trên biến đã khai báo, bốn mắt khi phát hành). `businessKey` không được thành kênh lộ DLCN: luật `SENSITIVE_IN_PUBLIC` cấm biến NC ở `businessKey` và `publicName`, API kiểm `businessKey` theo mẫu `^[A-Za-z0-9._-]{3,100}$`.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Năm máy trạng thái chính có chỗ kiểm tra ở máy chủ và ở CSDL. Tên trạng thái theo FRS Phụ lục A (nguồn chuẩn; DDL theo FRS).

| Đối tượng | Từ | Sang | Điều kiện, người làm | Chốt kiểm tra |
|---|---|---|---|---|
| Phiên bản mô hình | `DRAFT` | `IN_REVIEW` | Kiểm tra `FULL` không lỗi; IE gửi (FR-11-007) | `VersionService`; trigger `tg_frozen` |
| | `IN_REVIEW` | `PUBLISHED` | Người duyệt khác người gửi, triển khai engine thành công (FR-11-008) | `PublishApprovalService`; `DeploymentService` |
| | `IN_REVIEW` | `DRAFT` | Từ chối hoặc rút lại hoặc triển khai lỗi | `PublishRequestService` |
| | `PUBLISHED` | `DEPRECATED` | Bản mới thay thế hoặc ngừng dùng (FR-11-009) | Cùng giao dịch triển khai |
| | `DEPRECATED` | `RETIRED` | Không còn phiên chạy, không còn tham chiếu (ERR-11-037) | `VersionService` |
| Phiên | `RUNNING` | `SUSPENDED` | PERM-11-instance; tạm dừng hạn | `InstanceService` |
| | `SUSPENDED` | `RUNNING` | Tiếp tục | `InstanceService` |
| | `RUNNING`, `SUSPENDED` | `COMPENSATING` | Lỗi bước hoặc hủy kèm bù trừ | `SagaCoordinator` |
| | `COMPENSATING` | `COMPENSATED` hoặc `FAILED` | Saga `SUCCEEDED` hoặc `PARTIAL` | `SagaCoordinator` |
| | `RUNNING` | `COMPLETED`, `CANCELLED` | Hết quy trình, hủy | Engine, `InstanceService` |
| Việc | `UNASSIGNED` | `ASSIGNED` | Nhận việc (ERR-11-021 nếu đã có) | `ClaimService` |
| | `ASSIGNED` | `DELEGATED` | Chuyển hoặc ủy quyền | `DelegationService` |
| | `ASSIGNED`, `DELEGATED` | `COMPLETED`, `UNASSIGNED` | Hoàn thành, trả lại việc | `CompleteTaskService` |
| Hạn | `ON_TIME` | `DUE_SOON`, `OVERDUE` | Quét hạn | `DueScanner` |
| | `ON_TIME`, `DUE_SOON` | `PAUSED` | Chờ bổ sung, tạm dừng pháp lý | `PauseService` |
| Bước Saga | `PENDING` | `RUNNING` | Gửi lệnh bù trừ | `CompensationDispatcher` |
| | `RUNNING` | `DONE`, `FAILED` | Kết quả; `DONE` sau khi ghi nhật ký | `CompensationDispatcher` |
| | `FAILED` | `RUNNING`, `MANUAL` | Còn lượt thử, hết lượt | `SagaCoordinator` |
| | `MANUAL` | `DONE`, `SKIPPED` | `DONE`: người xử lý đánh dấu kèm `evidence[]`; `SKIPPED`: người khác duyệt đề nghị bỏ qua (API-11-132), từ chối thì giữ `MANUAL` | `ManualResolutionService` |
| Sự cố | `OPEN` | `RETRYING` | Thử lại | `IncidentService` |
| | `RETRYING` | `RESOLVED`, `OPEN` | Thành công hoặc lại lỗi | `IncidentService` |
| | `OPEN` | `IGNORED` | Bỏ qua, lý do từ 20 ký tự | `IncidentService`; `ck_incident_*` |

: Bảng chuyển trạng thái của PH-11

### 8.2. Outbox

Mọi sự kiện EVT-11-01…17, 20 và 21 (`audit.recorded`, không chứa giá trị biến, PH-13 tiêu thụ) ghi vào `outbox_event` cùng giao dịch `ph11_bpm` với thay đổi trạng thái nghiệp vụ; Debezium Outbox Event Router đọc bảng và phát theo `topic`, giữ thứ tự theo `partition_key = businessKey` (ADR-042, ADR-059). `event_id` là khóa chính nên một sự kiện logic không thể phát hai bản từ phía ứng dụng. Ràng buộc CSDL chặn payload có khóa giá trị biến. Dung lượng ghi chú: khoảng 2 triệu sự kiện nghiệp vụ mỗi ngày cho cả nền tảng ở `QM-VUA`, phần PH-11 là một phần nhỏ (giả định 40.000 sự kiện mỗi ngày); `OutboxCleaner` giữ theo `11.retention.progressEventYears` (CSDL mục 7).

Bản chiếu và outbox cùng nguồn kết nối `ph11_bpm` nên nguyên tử với nhau; giữa engine và outbox chỉ có nhất quán cuối cùng cộng đối soát, vì vậy sự kiện tiến độ phát từ `ProjectionListener` (sau commit engine) chứ không từ trong giao dịch engine.

### 8.3. Inbox và idempotency

Bảng nêu từng lớp chống trùng và căn cứ.

| Lớp | Cơ chế | Phạm vi | Căn cứ |
|---|---|---|---|
| Lệnh khởi tạo phiên | `Idempotency-Key` (24 giờ, Valkey cộng `uq_instance_index_correlation`) và dấu vân tay thân yêu cầu; cùng khóa khác nội dung trả ERR-11-051 (409) | API-11-049 | ADR-041 tầng một và hai |
| Hồ sơ trùng | `uq_instance_index_live_key` cộng khóa tư vấn | Một hồ sơ một phiên chưa kết thúc | BR-11-005 |
| Lệnh service task | `commandId` xác định; `uq_service_call_command`; PH-04 chống trùng | Gửi lại, giao lại | ADR-041 |
| Kết quả từ PH-04 | `inbox_message` khóa `(tenant, consumer, messageId)` | EVT-11-18, 19 | ADR-042 |
| Thông điệp đến trước | `inbox_message` `UNCORRELATED`, giữ tới `expires_at` | FR-11-030 | ADR-042 |
| Thao tác người dùng | `If-Match` ETag và cột `version` | Sửa nháp, nhận việc, duyệt | ERR-11-004 |

: Cơ chế chống trùng theo lớp

Dòng `inbox_message` `PROCESSED` giữ theo chính sách lưu giữ chung; bản tin `UNCORRELATED` quá hạn thành sự cố, không xóa im lặng.

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng nêu thời gian chờ, số lần thử và cách rơi về của từng điểm gọi.

| Điểm gọi | Thời gian chờ | Thử lại | Khi hết lượt |
|---|---|---|---|
| Job engine (async) | Khóa 5 phút | 3 lần, giãn `PT30S`, `PT2M`, `PT10M` | Dead letter, `incident` `JOB_FAILED` (ERR-11-107) |
| Chờ kết quả service task | `timeout` của ý định hoặc `11.service.defaultTimeoutMinutes` (2.880 phút) | Người vận hành gửi lại có chủ ý | `TIMED_OUT`, nhánh biên hoặc sự cố (ERR-11-102) |
| Lỗi kỹ thuật của PH-04 | PH-04 tự thử theo chính sách luồng | Phía PH-11 không thử lại tự động để khỏi nhân đôi lệnh | Sự cố (ERR-11-106) |
| Debezium tới Kafka | Do Kafka Connect quản | Vô hạn có giãn cách, theo dõi `datahub_bpm_outbox_pending` | Cảnh báo tồn đọng (ERR-11-117) |
| Gọi OpenBao transit | 2 giây | 2 lần, giãn 200 ms | ERR-11-046, không đặt được biến NC |
| Gọi PH-12 (nhóm, đơn vị) | 3 giây | 2 lần | Dùng đệm cũ 5 phút nếu có, không thì giao nhóm `11.task.fallbackGroup` (ERR-11-113) |
| Gọi danh mục luồng PH-04 | 5 giây | Không | Ghi `INFO` "Chưa kiểm được ánh xạ luồng"; chặn ở `FULL` khi triển khai |
| Bù trừ một bước | Như service task | `11.saga.maxRetries` (3) giãn `11.saga.retryBackoffSeconds` (300 giây) | `MANUAL` và việc thủ công |

: Thời gian chờ, thử lại và cách rơi về

Ngắt mạch (Resilience4j) chỉ đặt ở ba điểm gọi đồng bộ ra ngoài: OpenBao, PH-12 và danh mục luồng PH-04; mở khi lỗi vượt 50% trong 20 lượt gần nhất, nửa mở sau 30 giây. Kênh Kafka không dùng ngắt mạch mà theo dõi độ sâu hàng đợi và độ trễ outbox. Mô hình lỗi chung: lỗi nghiệp vụ trả ngay `4xx` kèm ERR, không thử lại; lỗi kỹ thuật tạm thời thử lại có giãn cách; lỗi không phục hồi (hết lượt) tạo `incident`, giữ phiên ở trạng thái an toàn và báo vận hành, không có đường nào làm mất việc lặng lẽ (BR-11-012).

### 8.5. Ánh xạ lỗi

Lỗi trả theo RFC 9457 (`application/problem+json`) kèm `code`, `traceId`, `errors[]`; `BpmExceptionHandler` ánh xạ từ ngoại lệ miền. `401`, `403` do thiếu quyền chức năng và `428` dùng ERR-00-401, ERR-00-403, ERR-00-428; `403` do phạm vi dữ liệu hoặc bốn mắt giữ mã ERR-11.

| Họ lỗi | Mã | Ngoại lệ miền | HTTP | Nơi hiển thị |
|---|---|---|---|---|
| Không tìm thấy, hết lưu giữ | ERR-11-001, 035 | `NotFoundException` | 404, 410 | Trang lỗi; DVC nhận 404 không lộ tồn tại |
| Xung đột trạng thái, phiên bản | ERR-11-002, 004, 006, 016, 018, 021, 030, 037, 051 | `ConflictException`, `OptimisticLockException` | 409 | Hộp thoại xung đột, thông báo nổi |
| Vi phạm bốn mắt, phạm vi | ERR-11-005, 020, 022, 034, 036 | `ForbiddenBusinessException` | 403 | Băng lỗi trên nút duyệt |
| Dữ liệu không hợp lệ | ERR-11-003, 007, 008, 019, 023, 024, 025, 026, 028, 029, 033 | `ValidationException` | 400, 422 | Dưới trường, ngăn kết quả kiểm tra |
| Kiểm tra tĩnh, tài nguyên | ERR-11-010…015, 031, 032, 038, 040, 042, 044 | `StaticCheckException` | 422 | UI-11-04, UI-11-14 |
| Cỡ, tệp | ERR-11-009, 027 | `PayloadTooLargeException` | 413, 422 | Vùng tải tệp |
| Hạn mức | ERR-11-041 | `RateLimitException` | 429 | Phản hồi API kèm `Retry-After` |
| Engine, hạ tầng | ERR-11-046 | `EngineUnavailableException` | 503, 422 | Trang lỗi |
| Runtime (không có người xem trực tiếp) | ERR-11-101…125 | `RuntimeFault` | không có | Sự cố ở UI-11-19, 20, 21; chỉ số; cảnh báo PH-13 |

: Ánh xạ nhóm lỗi tới ngoại lệ, mã HTTP và nơi hiển thị

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số theo tenant

36 tham số `11.*` ở FRS mục 8.2 lưu ở `tenant_setting`, sửa ở UI-11-23, trần do PA đặt ở `COMMON`; vượt miền hoặc trần trả ERR-11-029. `TenantSettingService` đọc qua bộ đệm JVM 60 giây và vô hiệu bằng sự kiện nội bộ khi sửa, nên thay tham số có hiệu lực trong một phút mà không khởi động lại. Bảng nhóm tham số theo thành phần đọc.

| Nhóm | Khóa | Thành phần đọc |
|---|---|---|
| Việc | `11.task.dueSoonHours`, `fallbackGroup`, `bulkMax`, `attachmentMaxMb`, `draftDebounceSeconds`, `unmaskSeconds`; `11.delegation.maxDays` | `task`, `due` |
| Mô hình | `11.designer.lockMinutes`, `autosaveSeconds`, `11.model.maxXmlKb`, `11.timer.minSeconds`, `11.callActivity.maxDepth` | `model` |
| Bước tự động | `11.service.defaultTimeoutMinutes`, `11.outbox.maxAttempts`, `11.message.bufferMinutes` | `bridge`, `runtime` |
| Phiên | `11.instance.startRatePerClient`, `11.instance.stuckHours`, `11.migration.batchSize` | `runtime`, `ops` |
| Saga | `11.saga.maxRetries`, `retryBackoffSeconds`, `reconcileCron` | `saga` |
| Hạn | `11.due.scanMinutes`, `11.escalation.nextLevelHours`, `11.due.receiveAfterHoursRule`, `11.supplement.defaultDays`, `11.supplement.resetDue` | `due` |
| Giám sát, lưu giữ, khác | `11.bottleneck.*`, `11.retention.*`, `11.test.retentionDays`, `11.ai.timeoutSeconds`, `11.progress.cacheSeconds` | `ops`, `engine`, `progress` |

: Tham số theo tenant, nhóm theo thành phần đọc

FRS 8.2 là nguồn chuẩn của khóa và đơn vị; seed `tenant_setting` của CSDL theo FRS.

### 9.2. Cờ tính năng

Cờ tính năng theo tenant cho phép bật dần các chức năng mức S và C, lưu cũng ở `tenant_setting` với khóa `11.feature.*`. Các khóa này là đề xuất, chưa có trong FRS 8.2 (phụ lục).

| Cờ | Mặc định | Bật chức năng | Tắt thì |
|---|---|---|---|
| `11.feature.testRun` | `true` ở DEV, TEST; `false` ở PROD | Chạy thử mô hình với service task giả lập (FR-11-011) | Ẩn UI-11-06, API-11-025…027 trả 404 |
| `11.feature.eventStart` | `false` | Khởi tạo phiên từ sự kiện PH-10 (FR-11-019) | `EventStartConsumer` không đăng ký |
| `11.feature.progressEvents` | `true` | Phát EVT-11-04 cho kênh DVC (Q11-05) | Chỉ có API tra tiến độ |
| `11.feature.dmn` | `false` | Bảng quyết định DMN (FR-11-017) | Ẩn UI, `evaluate` trả 404 |
| `11.feature.ai` | `false` | Gợi ý xử lý việc qua PH-17 (FR-11-066), cần quyết định bật của tenant ghi kiểm toán (SEC-49) | Không gọi PH-17 |

: Cờ tính năng của PH-11

### 9.3. Cấu hình triển khai

`dh-platform` chạy ở namespace `dh-control`, node pool `control` (D03-09 §4); module `bpm` dùng chung Deployment, nên phần riêng của PH-11 là cấu hình `datahub.bpm.*`, hai tài khoản CSDL và HPA theo chỉ số của PH-11. Giá trị mẫu dưới đây thay bí mật bằng `<bi-mat>`.

```yaml
spec:
  replicas: 2                              # tối thiểu ở PROD
  template:
    spec:
      terminationGracePeriodSeconds: 60    # chờ job async đang chạy xong
      containers:
        - name: dh-platform
          resources:
            requests: { cpu: "1500m", memory: 3Gi }
            limits:   { cpu: "3",     memory: 3Gi }   # D03-09, QM-VUA
          env:
            - { name: DATAHUB_BPM_ENGINE_DB_PASSWORD, valueFrom: { secretKeyRef: { name: ph11-engine-db, key: password } } }
            - { name: DATAHUB_BPM_DB_PASSWORD, valueFrom: { secretKeyRef: { name: ph11-app-db, key: password } } }
          lifecycle: { preStop: { exec: { command: ["sh", "-c", "sleep 15"] } } }
---
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 6                           # NFR-11-008
  metrics:
    - { type: Resource, resource: { name: cpu, target: { type: Utilization, averageUtilization: 65 } } }
    - { type: Pods, pods: { metric: { name: datahub_bpm_job_queue_depth }, target: { type: AverageValue, averageValue: "200" } } }
```

Ba tài khoản CSDL theo `ph11_bpm.sql`: `ph11_app` (nghiệp vụ, RLS), `ph11_engine` (engine) và `ph11_readonly` (báo cáo). Mỗi bản sao giữ hai nhóm kết nối HikariCP (12 cho engine, 12 cho nghiệp vụ) qua PgBouncer, tối đa 6 bản sao là 144 kết nối, trong giới hạn 200 kết nối thực của `pg-core` ở `QM-VUA` (D03-09). `preStop` và `terminationGracePeriodSeconds` cho async executor dừng lấy job mới và hoàn tất job đang chạy; job dở dang được bản khác nhận khi hết khóa 5 phút (NFR-11-009).

## 10. Quan sát

Chỉ số phát qua Micrometer, tiền tố `datahub_bpm_`, nhãn có bậc số lượng nhỏ (`tenant` tối đa 34, `process` là mã mô hình, `intent` là mã ý định, mỗi loại vài chục đến vài trăm giá trị); tuyệt đối không dùng `businessKey`, `instanceId`, `taskId`, tên người, giá trị biến làm nhãn (SEC-32). Các chỉ số này đáp ứng NFR-11-019 và là "bảng 6.10-a" của FRS.

| Nhóm | Chỉ số | Nhãn | Dùng cho |
|---|---|---|---|
| Phiên | `datahub_bpm_instance_started_total`, `datahub_bpm_instance_start_duration_seconds`, `datahub_bpm_instance_active`, `datahub_bpm_instance_completed_total` | `process`, `channel`, `result`, `state` | NFR-11-001, 004, 005 |
| Bản chiếu | `datahub_bpm_projection_lag_seconds`, `datahub_bpm_projection_drift_total`, `datahub_bpm_projection_repair_total` | `kind` | Phát hiện bản chiếu lệch |
| Engine | `datahub_bpm_job_queue_depth`, `datahub_bpm_job_failed_total`, `datahub_bpm_job_lock_expired_total`, `datahub_bpm_engine_up` | `executor` | NFR-11-008, 009; HPA |
| Bước tự động | `datahub_bpm_service_call_total`, `datahub_bpm_service_result_duration_seconds`, `datahub_bpm_service_timeout_total`, `datahub_bpm_service_inflight` | `intent`, `result` | NFR-11-003; FR-11-029 |
| Outbox, inbox | `datahub_bpm_outbox_pending`, `datahub_bpm_outbox_lag_seconds`, `datahub_bpm_inbox_duplicate_total`, `datahub_bpm_inbox_uncorrelated`, `datahub_bpm_inbox_dlq_total` | `topic`, `consumer` | NFR-11-018; ERR-11-103, 104, 117 |
| Việc | `datahub_bpm_task_total`, `datahub_bpm_task_complete_duration_seconds`, `datahub_bpm_task_unassigned`, `datahub_bpm_inbox_register_lag_seconds` | `kind`, `action` | NFR-11-002, 015 |
| Hạn | `datahub_bpm_due_scan_duration_seconds`, `datahub_bpm_due_scan_lag_seconds`, `datahub_bpm_due_soon_total`, `datahub_bpm_due_overdue_total`, `datahub_bpm_due_escalation_total`, `datahub_bpm_due_paused` | `subject`, `level` | NFR-11-016 |
| Saga | `datahub_bpm_saga_started_total`, `datahub_bpm_saga_duration_seconds`, `datahub_bpm_saga_step_total`, `datahub_bpm_saga_manual_pending`, `datahub_bpm_saga_reconcile_mismatch_total` | `trigger`, `status` | NFR-11-017 |
| Tiến độ | `datahub_bpm_progress_request_total`, `datahub_bpm_progress_duration_seconds`, `datahub_bpm_progress_cache_hit_ratio`, `datahub_bpm_progress_event_lag_seconds` | `result` | NFR-11-006, 018 |
| Mô hình | `datahub_bpm_validate_duration_seconds`, `datahub_bpm_publish_total`, `datahub_bpm_deploy_duration_seconds` | `mode`, `result` | NFR-11-013 |
| Sự cố, vận hành | `datahub_bpm_incident_open`, `datahub_bpm_bottleneck_total`, `datahub_bpm_history_purge_rows_total`, `datahub_bpm_job_duration_seconds`, `datahub_bpm_pii_guard_block_total` | `type`, `object`, `job` | FR-11-058…063; NFR-11-021, 024 |

: Chỉ số quan sát của PH-11

**Log**: JSON có `traceId`, `tenant`, `module = bpm`, `operationId`; không có giá trị biến hay nội dung biểu mẫu. **Trace** (OpenTelemetry): span `bpm.instance.start`, `bpm.model.deploy`, `bpm.service.dispatch`, `bpm.service.result`, `bpm.task.complete`, `bpm.due.scan`, `bpm.saga.run`, `bpm.projection.apply`, `bpm.progress.get`; `traceparent` vào cột `trace_id` của `outbox_event`, `service_call`, `instance_index`, `incident` và header bản tin Kafka để nối giao dịch gốc với lệnh PH-04. **Cảnh báo** gửi PH-13: `outbox_pending` > 1.000 trong 5 phút (P2); `service_timeout_total` tăng đột biến (P2); `job_failed_total` > 0 (P2); `saga_manual_pending` > 0 quá 4 giờ (P1); `due_scan_lag_seconds` > 300 (P1); `projection_drift_total` tăng 3 lượt liên tiếp (P2); `pii_guard_block_total` > 0 (P1, nghi rò DLCN).

## 11. Hiệu năng và vận hành

### 11.1. Ngân sách độ trễ

Tải giả định cho `QM-VUA` (200 HTTT): 5.000 phiên mới mỗi ngày làm việc, mỗi phiên 12 bước, 4 service task, 3 việc người dùng, tức 20.000 lệnh PH-04 và 15.000 việc mỗi ngày; cao điểm gấp 10 lần trung bình, khoảng 2 phiên mỗi giây. NFR-11-001 và 004 (100 và 200 phiên mỗi giây) là tải kiểm thử căng, cao gấp 50 đến 100 lần cao điểm thực.

| Thao tác | Ngân sách (giả định, đo khi nghiệm thu) | Chỉ tiêu |
|---|---|---|
| Khởi tạo phiên (API-11-049) | Xác thực, quyền, hạn mức 15 ms; khóa, tra trùng 10 ms; `startProcessInstance` bước đầu async 60 ms; giao dịch `ph11_bpm` 40 ms; Valkey 5 ms; dự phòng 70 ms | p99 ≤ 200 ms (NFR-11-001) |
| Hoàn thành việc (API-11-076) | Quyền, JSON Schema 30 ms; mã hóa NC 20 ms; `taskService.complete` 90 ms; bản chiếu, hạn, outbox 60 ms; dự phòng 100 ms | p99 ≤ 300 ms (NFR-11-002) |
| Xử lý kết quả service task | `inbox_message` 10 ms; tìm `service_call` 5 ms; kiểm schema, ghi biến 40 ms; `trigger` 150 ms; cập nhật 30 ms; dự phòng 250 ms | p99 ≤ 500 ms (NFR-11-003) |
| Tra tiến độ (API-11-104) | Trúng đệm 3 ms; trượt: truy vấn `instance_index` 8 ms, dựng và che 10 ms | p99 ≤ 100 ms (NFR-11-006) |
| Kiểm tra tĩnh 200 phần tử | Phân tích XML 80 ms; các luật tuyến tính 600 ms | ≤ 2 s (NFR-11-013) |

: Ngân sách độ trễ của các thao tác chính

Thông lượng 200 phiên mỗi giây với 4 bản sao (50 mỗi bản): mỗi phiên cần khoảng 12 ms CPU cho API và 25 ms cho các bước async đầu (giả định), tức khoảng 1,9 vCPU mỗi bản; vì vậy hồ sơ đo NFR dùng 4 bản sao 2/4 vCPU. Thắt cổ chai dự kiến là ghi `ph11_flowable` (khoảng 20 lần ghi `ACT_RU_*`, `ACT_HI_*` mỗi phiên) chứ không phải CPU; đề xuất DBA đặt `fillfactor` 85 cho `ACT_RU_EXECUTION`, `ACT_RU_JOB` và kiểm bằng k6.

### 11.2. Mở rộng và định cỡ

Số bản sao tối thiểu 2, tối đa 6 (NFR-11-008). HPA co giãn theo CPU 65% và độ sâu hàng đợi job `datahub_bpm_job_queue_depth` (trung bình 200 job chờ mỗi bản, qua Prometheus Adapter hoặc KEDA); tăng nhanh (tối đa 2 bản mỗi 60 giây), giảm chậm (ổn định 10 phút). Mọi bản sao đều chạy async executor nhờ khóa job ở CSDL, không cần "bản chủ"; tách pod `worker` riêng là phương án khi tải lệch (Q11-22). Định cỡ `dh-platform` theo D03-09 (bản sao × CPU request/limit, bộ nhớ request/limit): `QM-NHO` 2 × 0,5/1, 2/2 GB; `QM-VUA` 2 × 1,5/3, 3/3 GB, hồ sơ đo NFR của PH-11 là 4 × 2/4, 4/4 GB (giả định); `QM-LON` 3 × 2/4, 4/4 GB; `QM-CHUNG` 4 × 2/4, 6/6 GB cho 34 tenant dùng một engine (Q11-24). Heap chiếm khoảng 65% RAM; Flowable không giữ phiên trong bộ nhớ nên bộ nhớ chủ yếu cho định nghĩa đã triển khai (giới hạn 500 định nghĩa trong `ProcessDefinitionCache`) và hàng đợi async executor.

### 11.3. Dung lượng

Giả định 5.000 phiên mỗi ngày làm việc, 250 ngày mỗi năm. `ACT_*` cho 50.000 phiên `RUNNING` khoảng 0,6 GB; `ACT_HI_*` mức `audit` giữ 12 tháng khoảng 15 GB; `instance_step` khoảng 12 GB mỗi năm (25 triệu dòng × 0,5 KB); `outbox_event` khoảng 15 GB mỗi năm trước khi dọn. Các con số cần xác nhận bằng dữ liệu giả lập (Q11-25).

### 11.4. Vận hành thường nhật

Hằng phút: quét hạn, quá hạn chờ lệnh, đối soát bản chiếu, dead letter. 00:05 tạo phân vùng, 01:00 dọn lịch sử và lưu giữ, 02:00 đối soát Saga. Sổ tay vận hành ghi sáu tình huống: outbox tồn đọng (kiểm Debezium), PH-04 không trả lời (gửi lại lệnh), job lỗi hàng loạt (`:bulk-retry`), bản chiếu lệch (đối soát toàn bộ), Saga thủ công tồn đọng, OpenBao ngừng (tiến độ vẫn chạy, việc có trường NC bị chặn). Nâng cấp Flowable chạy lệnh nâng lược đồ trong cửa sổ triển khai, theo kiểu cuốn chiếu hai bước (bản mới đọc được lược đồ cũ) và kiểm thử lược đồ trước khi lên PROD.

## 12. Kiểm thử

Bảng theo lớp.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | Hàm thuần: `WorkingTimeCalculator`, `CommandIdFactory`, `PublicStepMapper`, mỗi `ruleCode`, `AssignmentResolver`, `PiiMaskGuard` | 200 ca lịch mẫu; cùng đầu vào cho cùng `commandId` |
| Tích hợp (Testcontainers) | PostgreSQL hai schema, RLS, Kafka, Valkey, OpenBao dev, Flowable thật | `LT_KHAI_SINH`: thành công, BHYT lỗi có bù trừ, bù trừ thất bại sang thủ công; `DUYET_KET_NAP_HTTT` hai cấp |
| Đồng thời | 32 luồng khởi tạo cùng `businessKey`; hai người nhận một việc; hai bản sao quét hạn | Đúng một phiên, một người nhận, mỗi mốc nhắc một lần |
| Chịu lỗi (chaos) | Tắt cứng pod giữa `trigger` và ghi `service_call`; Kafka, Valkey, OpenBao ngừng; Debezium chậm | Không mất phiên, không nhân đôi lệnh; job nhận sau ≤ 5 phút; đúng cách rơi về (mục 8.4) |
| Cô lập tenant | Hai tenant cùng `processKey`; truy vấn engine thiếu tenant; `ph11_isolation_test.sql` | Tenant A không thấy phiên, việc, tiến độ của B; facade ném lỗi khi thiếu `TenantContext` |
| Hợp đồng, bảo mật | AsyncAPI, OpenAPI; ArchUnit; quét `ACT_*` và log tìm CCCD; ZAP; ca XXE | Sự kiện không có khóa `variables`, `formData`; 0 giá trị NC dạng rõ (NFR-11-021) |
| Hiệu năng | k6 200 phiên mỗi giây trong 5 phút; 50.000 phiên `RUNNING` | NFR-11-001…006; dọn lịch sử không tăng p99 quá 10% |
| Giao diện, tuân thủ | Playwright, axe cho UI-11-04, 15; bộ mô hình lỗi mẫu cho 21 `ruleCode`; chạy mẫu BPMN 2.0 | WCAG 2.2 AA; kiểm tra tĩnh chặn đủ lỗi; gói bằng chứng ≤ 2 phút |

: Chiến lược kiểm thử của PH-11

Dữ liệu kiểm thử là dữ liệu sinh (SEC-38) ở tenant T90 đến T99, có ca nhiễu: biến thiếu, kết quả PH-04 trùng và đến muộn, thông điệp đến trước, lịch năm chưa nạp.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Thứ tự theo phụ thuộc, mỗi mốc có tiêu chí xong đo được (kế hoạch W0 đến W6 của docs/08-implementation/04-ke-hoach-phat-trien.md, PH-11 thuộc đợt 2, tuần W4).

| Mốc | Nội dung | Tiêu chí xong |
|---|---|---|
| M0 | POC Flowable 7.x trên Spring Boot 4, đa tenant, async executor, `history=audit` (Q11-20) | Một mô hình chạy qua hai tenant; khởi động hai bản sao; job không chạy trùng |
| M1 | `engine`, `persistence`, `model`, `resource`, kiểm tra tĩnh, ArchUnit | Phát hành bốn mắt và triển khai thành công; 21 `ruleCode` có ca kiểm thử |
| M2 | `runtime`, `bridge`, outbox, inbox, `progress` | `LT_KHAI_SINH` nhánh thành công đầu cuối với PH-04 giả lập; NFR-11-001, 003 |
| M3 | `task`, `due`, lịch làm việc, hộp "Việc của tôi" | 200 ca lịch mẫu không sai lệch; NFR-11-002, 015, 016 |
| M4 | `saga`, `ops`, sự cố, lưu giữ, đối soát bản chiếu | Nhánh bù trừ và bù trừ thất bại đạt; tắt cứng pod không mất phiên |
| M5 | Trình thiết kế bpmn-js hoàn chỉnh, so sánh, chạy thử | NFR-11-014, 022 |
| M6 | Hiệu năng, chaos, gói tuân thủ CV 631 | Tiêu chí chấp nhận 1 đến 9 của FRS mục 14 |

: Lộ trình hiện thực

### 13.2. Truy vết hệ cũ

Hệ cũ (Viettel 2021) không có BPM; D02-02 ghi LGC "—" cho PH-11. Ba chức năng cũ liên quan gián tiếp, kết luận **phân hệ dùng dữ liệu và năng lực mới, không thay chức năng nào**.

| LGC | Chức năng hệ cũ | Vai trò trong thiết kế | Thành phần |
|---|---|---|---|
| LGC-NGSP-002 | Hộ tịch: đăng ký, tra trạng thái hồ sơ | Quy trình ví dụ `LT_KHAI_SINH`; tra tiến độ | `progress`, `bridge` |
| LGC-NGSP-004 | Hồ sơ thủ tục cấp mã ĐVQHNS | Mẫu quy trình nhiều cơ quan | `model`, `due` |
| LGC-BUS-037 | Xử lý lỗi, thực hiện lại | Thử lại, sự cố, gửi lại lệnh | `bridge`, `ops` |

: Truy vết LGC liên quan gián tiếp

### 13.3. Rủi ro

Bảng ghi rủi ro kỹ thuật, mức độ và cách giảm thiểu để người duyệt biết điểm cần theo dõi.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Flowable 7.x chưa hỗ trợ chính thức Spring Boot 4 (Q11-04, Q11-20) | Cao | POC ở M0 trước mọi mã khác; ba nhánh quyết định ở đoạn dưới |
| Lệnh nhân đôi tới PH-04 | Cao | `commandId` xác định, `outbox_event` khóa chính, PH-04 chống trùng, ca chaos |
| Rò DLCN qua biến, tiến độ, log | Cao | Mã hóa NC, danh sách cho phép, hai chốt ở outbox, quét định kỳ NFR-11-021 |
| Bản chiếu lệch khỏi engine | Trung bình | Bộ nghe sau commit, đối soát mỗi phút, chỉ số `projection_drift`; quyết định nghiệp vụ không đọc bản chiếu |
| Tính hạn sai do lịch thiếu | Trung bình | 200 ca mẫu; lịch mặc định kèm cảnh báo (ERR-11-116) |
| Mô hình độc hại làm treo phiên | Trung bình | Danh sách phần tử cho phép, biểu thức hạn chế, bốn mắt, kiểm tra tĩnh ở máy chủ |
| Engine chung gây "hàng xóm ồn ào"; nâng cấp lược đồ Flowable | Trung bình | Hạn mức khởi tạo theo client, hạn mức job theo tenant (Q11-24); nâng trong cửa sổ triển khai, kiểm thử lược đồ |
| Debezium chậm làm trễ lệnh và tiến độ | Trung bình | Chỉ số `outbox_lag`, cảnh báo, bộ đẩy dự phòng (Q11-28) |
| Vi phạm điều kiện logo bpmn.io | Thấp | Logo cố định, kiểm thử giao diện kiểm logo hiện (ADR 111) |

: Rủi ro và giảm thiểu

### 13.4. Quyết định kiến trúc đề xuất

Năm quyết định dưới đây là đề xuất trong dải ADR 110 đến 114 mở cho PH-11 (D00-02, chưa có tệp ADR). Mỗi quyết định ghi các phương án đã cân nhắc, lựa chọn, lý do và hệ quả.

| Số | Phương án đã cân nhắc | Chọn | Lý do và hệ quả |
|---|---|---|---|
| ADR 110 | A. Một engine nhúng, `tenantId` Flowable, schema `ph11_flowable` không RLS; B. mỗi tenant một engine (34 engine); C. engine ở DU riêng | A, history `audit` | Tải mức vừa (cao điểm khoảng 2 phiên mỗi giây ở `QM-VUA`), cô lập mạnh đã có ở `ph11_bpm` có RLS; B làm 34 lần nâng cấp và nhiều bộ job nền, C thêm một DU. Hệ quả: kiểm thử cô lập engine, hạn mức theo client, đường lui sang C (Q11-24); chi tiết bước giữ ở `instance_step` nên `audit` đủ kiểm toán |
| ADR 111 | A. bpmn-js nhúng React, kiểm tra tĩnh ở máy chủ; B. Flowable Modeler; C. tự viết trình vẽ | A | bpmn-js trưởng thành nhất, giấy phép cho dùng thương mại với điều kiện giữ logo bpmn.io hiển thị (logo cố định ở góc khung vẽ, không có tùy chọn ẩn, UI-11-04 ghi chú); B kéo theo REST và nhận dạng riêng, C chi phí quá lớn. Máy chủ kiểm lại ở `:validate` và khi duyệt nên không tin phía trình duyệt |
| ADR 112 | A. Lệnh Kafka qua outbox tới PH-04, kết quả qua inbox, `trigger` execution; B. delegate gọi HTTP đồng bộ tới PH-04; C. delegate gọi HTTT trực tiếp | A | Tách "làm gì" khỏi "làm bằng cách nào" (BR-11-002), chịu được PH-04 và HTTT chậm, một đường ra duy nhất; B giữ giao dịch engine khi chờ, C phá ranh giới và an ninh mạng. Hệ quả: hai nguồn kết nối không chung giao dịch (nguyên tử về hiệu ứng, Q11-21 đã chốt) nên cần `commandId` xác định, chống trùng nhiều lớp và đối soát (mục 5.7) |
| ADR 113 | A. Hành động bù trừ đăng ký theo bước, `SagaCoordinator`, nhật ký `saga_log`; B. chỉ compensation event của BPMN; C. 2PC giữa các cơ quan | A | Người thiết kế vẽ ý định bù trừ bằng ký pháp BPMN nhưng thực thi và ghi vết ở `saga` vì BPMN thiếu lượt thử, đối soát, việc thủ công; 2PC không khả thi giữa cơ quan độc lập. Hệ quả: bước ghi dữ liệu ra ngoài phải có bù trừ hoặc miễn có duyệt (`RISKY_NO_COMPENSATION`), bù trừ thất bại luôn sinh việc thủ công và sự kiện P1 |
| ADR 114 | A. `WorkingTimeCalculator` tự viết, lịch theo tenant, hạn mềm do `DueScanner`, hạn cứng bằng timer biên; B. timer ISO 8601 của Flowable; C. dịch vụ lịch ngoài | A | Báo cáo đúng hạn, trễ hạn là căn cứ pháp lý (NĐ 61/2018 và văn bản thay thế, Q11-01) nên phải tính theo ngày nghỉ, làm bù, tạm dừng của từng tỉnh, điều timer `P3D` không biết; tách hạn mềm để không tạo hàng chục nghìn job timer. Hệ quả: phải nạp lịch hằng năm (Q11-29) và có bộ ca kiểm thử lịch |

: Quyết định kiến trúc đề xuất ADR 110 đến 114

### 13.5. Câu hỏi mở

Mười câu hỏi dưới cần chủ đầu tư, nhóm PH-04, CSDL hoặc ATTT trả lời; câu trả lời có thể đổi thiết kế nêu kèm.

| Mã | Câu hỏi | Ảnh hưởng |
|---|---|---|
| Q11-20 | Chốt cách chạy Flowable 7.x với Spring Boot 4 sau POC (nhánh a, b, c ở mục 13.3)? | ADR 110, kế hoạch W4, DU `dh-platform` |
| Q11-21 | Đã chốt ở FRS 0.2: giữ hai nguồn kết nối, nguyên tử về hiệu ứng, không chung giao dịch (outbox và bản chiếu ghi sau cam kết engine, có đối soát). | FR-11-018, 028; mục 4.7, 5.7; CSDL mục 6.1 |
| Q11-22 | Khi nào tách async executor ra pod `worker` riêng (như PH-19): ngưỡng độ sâu hàng đợi, độ trễ API? | Mục 11.2; HPA |
| Q11-23 | FRS 0.2 đã đổi `commandId` thành UUID v5; PH-04 còn phải xác nhận coi trùng `commandId` là cùng một lệnh? | ADR 112; FR-11-028 |
| Q11-24 | Một engine cho 34 tenant ở `QM-CHUNG` có đủ; có cần hạn mức job theo tenant, hay chia engine theo cụm tenant? | ADR 110; NFR-11-008 |
| Q11-25 | Dung lượng `ACT_HI_*` thực tế ở `history=audit` với biến lớn, có nên hạ xuống mức thấp hơn hoặc ngắt ghi biến JSON lớn? | Mục 11.3; `11.retention.engineHistoryMonths` |
| Q11-26 | Đổi KEK `dh-{tenant}-bpm-pii`: job `REENCRYPT` biến NC trong `ACT_RU_VARIABLE` có chấp nhận được về khóa và thời gian? | Mục 4.16; ADR-032 |
| Q11-27 | Nếu thẩm định bắt buộc WS-BPEL thật (Q11-02), có chạy Apache ODE ở DU riêng, và mô hình BPMN chuyển sang BPEL bằng công cụ nào? | FR-11-064; mục 4.12 |
| Q11-28 | Debezium có đạt độ trễ outbox ≤ 10 giây (NFR-11-018) ổn định không; có cần bộ đẩy dự phòng trong ứng dụng khi Debezium chậm? | Mục 4.7, 8.2 |
| Q11-29 | Lịch nghỉ lễ, làm bù hằng năm nhập tay từng tỉnh hay lấy từ nguồn chuẩn nhà nước, ai chịu trách nhiệm nạp? | ADR 114; FR-11-045; ERR-11-116 |

: Câu hỏi mở của SDD PH-11

## Phụ lục A. Đề nghị đồng bộ FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa FRS, DDL hay OpenAPI. FRS 0.2 (Phụ lục C) đã xử lý các đề nghị của bản 0.1; cột Tình trạng ghi kết quả.

| # | Nơi | Đề nghị | Tình trạng |
|---|---|---|---|
| 1 | FRS EN-11-26 `test_run`, DDL | DDL chưa có bảng `test_run` | Không chấp nhận: FRS đã có; CSDL 0.2 thêm bảng |
| 2 | FRS EN-11-27 `instance_change`, DDL | DDL chưa có bảng `instance_change` | Không chấp nhận: FRS đã có; CSDL 0.2 thêm bảng |
| 3 | FRS A.1, DDL | Tên giá trị, cột khác nhau (`StartChannel`, `ServiceCallStatus`, `PauseReason`, `TaskKind`, `IncidentType`...) | Không chấp nhận: Phụ lục A.1 là nguồn chuẩn; DDL theo FRS, tập này đã sửa (`REQUESTED`, `COMPLETED`, `TIMED_OUT`, `IncidentType` mới) |
| 4 | FRS FR-11-028 | `commandId` UUID v5 xác định thay UUID v7 | Đã hấp thụ (mục 4.7) |
| 5 | FRS FR-11-018, 028, BR-11-023, Q11-21 | Hai nguồn kết nối, bỏ lời "cùng giao dịch" | Đã hấp thụ có sửa: nguyên tử về hiệu ứng, không chung giao dịch |

: Đề nghị đồng bộ FRS và các tập liên quan

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Nhóm thiết kế PH-11 | Bản đầu: kiến trúc module `bpm`, cấu hình Flowable, 11 thành phần, 7 sơ đồ trình tự, mô hình lỗi và nhất quán, bảo mật, quan sát, triển khai, năm ADR đề xuất 110…114, câu hỏi mở Q11-20…29, phụ lục đề nghị đồng bộ FRS |
| 0.2 | 2026-11-26 | Nhóm thiết kế PH-11 | Đồng bộ FRS 0.2: Q11-21 nguyên tử về hiệu ứng, `commandId` UUID v5, enum theo Phụ lục A.1, API-11-128…137, ERR-11-051, 125, EVT-11-21, bốn tham số mới, bỏ qua bước Saga bốn mắt, `SUPPLEMENT_EXPIRED` |

: Lịch sử phiên bản
