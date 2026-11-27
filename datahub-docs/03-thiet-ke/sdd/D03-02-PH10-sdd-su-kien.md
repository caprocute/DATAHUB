---
ma_tai_lieu: D03-02-PH10
ten: Thiết kế chi tiết phần mềm phân hệ PH-10 Sự kiện
phien_ban: 0.5
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration và dh-runtime, kỹ sư nền tảng Kafka, kiến trúc sư, ATTT, hội đồng thẩm định
phan_he: PH-10
mo_ta: Thiết kế chi tiết hiện thực 76 FR của PH-10 gồm cấu trúc mã, mô hình miền, 16 thành phần control plane và data plane với khối đặc tả 10 mục, chín sơ đồ trình tự, đa tenant, bảo mật, xử lý lỗi, cấu hình, quan sát và vận hành.
tai_lieu_lien_quan: D02-03-PH10 FRS; D03-03-PH10 CSDL; D03-04-PH10 API; D03-06-PH10 Màn hình; D03-10 Thiết kế đa tenant
---

# D03-02-PH10 · Thiết kế chi tiết Sự kiện

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 76 FR của [D02-03-PH10](../../02-yeu-cau/frs/D02-03-PH10-frs-su-kien.md), phân hệ thay khối Hub Apache Pulsar của hệ cũ bằng trục sự kiện Kafka có lược đồ bắt buộc, có duyệt và có giao nhận tin cậy cho HTTT chỉ biết gọi HTTP. Thiết kế dựa trên năm quyết định:

1. **Control plane và data plane tách hẳn.** Mọi khai báo nghiệp vụ (dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription, yêu cầu duyệt, DLQ, phát lại, di trú) nằm ở module `event` của `dh-integration` (Spring Boot 4, Spring Modulith), lưu ở schema `ph10_event` của cụm `pg-core`. Đường đi của bản tin chỉ qua Kafka và hai mô-đun mới của `dh-runtime`: **cổng sự kiện** (API phát, API kéo) và **bộ giao nhận webhook** (ký HMAC, thử lại, DLQ, phát lại). Khi `dh-integration` hoặc `pg-core` ngừng, sự kiện vẫn được phát, giao và kéo (NFR-10-013, ADR-071).
2. **PH-10 là bên duy nhất ghi Apicurio.** Mỗi topic một artifact (`groupId = {tenant}`, `artifactId = {topicName}`), phiên bản qua duyệt bốn mắt, kiểm tra trước bằng `dryRun`, mức mặc định `BACKWARD`; thay đổi phá vỡ tạo topic `.v{n+1}` (ADR-070).
3. **Cấu hình cụm đi qua Git.** `dh-integration` không có quyền quản trị Kafka; nó sinh `KafkaTopic`, `KafkaUser` vào kho `dh-config-{tenant}`, Argo CD và Strimzi áp dụng, bộ đối soát theo dõi trạng thái `Ready` rồi chuyển đối tượng sang `ACTIVE` (ADR-072). Ngoại lệ duy nhất là Admin API để khởi tạo, đặt lại và xóa vị trí nhóm tiêu thụ, đọc lag.
4. **Ít nhất một lần, không mất bản tin.** Offset chỉ được commit sau khi giao thành công hoặc bản tin đã nằm chắc trên topic `{topicName}.dlq`; DLQ bền ở bảng `dlq_entry`, `dlq_payload`; phát lại không phụ thuộc lưu giữ của topic gốc (BR-10-024).
5. **Di trú song song.** Cầu nối Pulsar hai chiều theo từng topic chạy như luồng Camel trên `dh-runtime`, có hạn dùng, có đối chiếu mỗi giờ và cửa sổ quay lui (ADR-073).

Thiết kế không tạo ADR mới: bốn ADR-070…073 do FRS lập đã đủ. Tập nêu 10 câu hỏi mở Q10-20…29 và một mục "Đề nghị bổ sung cho FRS" (§13.4) cho bảy chỗ Phụ lục A chưa có tên bảng hay đường dẫn mà thiết kế cần.

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tài liệu mô tả cách hiện thực 76 FR của PH-10 ở mức đủ để kỹ sư viết mã ngay: cấu trúc gói, mô hình miền, từng thành phần của control plane (`dh-integration`, module `event`) và data plane (cổng sự kiện, bộ giao nhận của `dh-runtime`), trình tự các ca phức tạp, đa tenant, bảo mật, xử lý lỗi, cấu hình, quan sát và vận hành. Ngoài phạm vi: cụm Kafka, Apicurio, Keycloak, OpenBao (thuộc nền tảng, D03-09) và giao diện console (D03-06-PH10).

### 1.2. Đối tượng đọc

| Người đọc | Phần cần đọc | Mục đích |
|---|---|---|
| Hội đồng thẩm định, kiến trúc sư | Tóm tắt, chương 2, 6, 7 | Ranh giới control plane và data plane, cách ly tenant, bảo mật khóa ký |
| Kỹ sư `dh-integration` | Chương 3, 4.1…4.5, 4.9…4.17, 5, 8 | Hiện thực module `event` |
| Kỹ sư `dh-runtime` | Chương 3.2, 4.6…4.8, 4.10…4.12, 5.3…5.7 | Cổng sự kiện, bộ giao nhận, phát lại |
| Kỹ sư nền tảng Kafka, vận hành | Chương 4.4, 9, 10, 11 | GitOps, chỉ số, cảnh báo, mở rộng |
| ATTT | Chương 4.5, 4.8, 6, 7 | Scope, ACL, ký webhook, egress |
| Kiểm thử viên | Chương 5, 8, 12 | Ca trình tự, lỗi, tính nhất quán |

: Đối tượng đọc của tập SDD PH-10

### 1.3. Quy ước trong tài liệu

Mọi enum, trạng thái, tên trường, mã quyền, tham số `10.*`, mã màn hình, mã sự kiện và định danh kỹ thuật lấy đúng Phụ lục A của FRS; mã ERR, BR, NFR là của FRS; tên bảng là tên gợi ý ở Phụ lục A.3 (tập CSDL D03-03-PH10 viết song song theo cùng phụ lục); mã API theo gợi ý FRS §9.4 (định nghĩa đầy đủ ở D03-04-PH10). Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới. Định nghĩa chung (danh sách, kiểm toán, đăng nhập, "Việc của tôi") dẫn chiếu FR-00 của SRS, không nhắc lại.

### 1.4. Thuật ngữ và chữ viết tắt

| Thuật ngữ | Giải thích |
|---|---|
| Control plane, data plane | Phần điều khiển (khai báo, duyệt, cấu hình) và phần dữ liệu (đường đi của bản tin) |
| DU | Đơn vị triển khai (deployment unit), ví dụ `dh-integration`, `dh-runtime` |
| Aggregate | Cụm đối tượng miền thay đổi cùng nhau qua một gốc, giữ bất biến nghiệp vụ |
| Spring Modulith, ArchUnit | Công cụ kiểm ranh giới module và luật phụ thuộc lúc biên dịch, kiểm thử |
| GitOps | Cấu hình cụm khai báo trong kho Git, Argo CD áp dụng; ở đây là `KafkaTopic`, `KafkaUser` của Strimzi |
| Outbox, inbox | Ghi sự kiện cùng giao dịch CSDL để phát sau; khử trùng sự kiện nhận |
| Lease, cursor | Quyền kéo độc quyền có thời hạn của một subscription; vị trí đọc đã ký do máy chủ cấp |
| Ngắt mạch | Circuit breaker, tạm ngừng gọi một đích đang lỗi để tránh dồn tải |
| DLQ | Dead Letter Queue, topic `{topicName}.dlq` và bảng `dlq_entry` |
| Lag | Độ trễ tiêu thụ của nhóm tiêu thụ so với đầu topic |

: Thuật ngữ và chữ viết tắt của tập SDD PH-10

### 1.5. Cấu trúc tài liệu

Tài liệu đi từ vị trí trong kiến trúc (§2), cấu trúc mã (§3), từng thành phần (§4), sequence của các ca phức tạp (§5) tới đa tenant (§6), bảo mật (§7), máy trạng thái, lỗi và nhất quán (§8), cấu hình (§9), quan sát (§10), hiệu năng và vận hành (§11), kiểm thử (§12), lộ trình và câu hỏi mở (§13). Mục 3.5 liệt kê 16 thành phần được đặc tả; mỗi thành phần ở chương 4 mở bằng khối đặc tả 10 mục.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Tài liệu dùng FRS D02-03-PH10 (FR, BR, NFR, Phụ lục A), CSDL D03-03-PH10, API D03-04-PH10, Màn hình D03-06-PH10, ATTT D03-07, hạ tầng D03-09, đa tenant D03-10 và các ADR dưới đây.

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4 + Modulith cho `dh-integration` |
| ADR-002, ADR-061 | Camel Quarkus 3.33.x cho `dh-runtime`, hồ sơ runtime |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` |
| ADR-004 | Kafka (Strimzi, KRaft) và Apicurio Registry thay Pulsar |
| ADR-006 | Keycloak, OPA cho token và quyết định truy cập |
| ADR-008 | Valkey cho đệm chia sẻ |
| ADR-009, ADR-068 | GitOps Argo CD, kho cấu hình theo tenant `dh-config-{tenant}` |
| ADR-011 | OpenTelemetry, LGTM |
| ADR-012 | OpenBao cho bí mật ký, khóa transit |
| ADR-013 | Tách control plane và data plane |
| ADR-044 | Chữ ký webhook HMAC-SHA256 dùng chung với PH-19 |
| ADR-059 | CDC bằng Debezium trên Kafka Connect của tenant (`dh-cdc`) |
| [ADR-070](../../00-chung/adr/ADR-070-tuong-thich-luoc-do-va-phien-ban-topic.md) | Tương thích lược đồ, artifact mỗi topic, phiên bản topic |
| [ADR-071](../../00-chung/adr/ADR-071-giao-nhan-day-keo-qua-dh-runtime.md) | Cổng sự kiện, bộ giao nhận webhook trong `dh-runtime` |
| [ADR-072](../../00-chung/adr/ADR-072-cap-phat-topic-acl-qua-gitops.md) | `KafkaTopic`, `KafkaUser` qua kho Git của tenant |
| [ADR-073](../../00-chung/adr/ADR-073-cau-noi-di-tru-pulsar.md) | Cầu nối di trú Pulsar |

: Tài liệu liên quan và quyết định kiến trúc

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

| Thành phần | DU, tài nguyên | Vùng | Ghi chú |
|---|---|---|---|
| Module `event` (API control plane, nghiệp vụ, bộ đối soát cấp phát, bộ thu lag, bộ ghi DLQ, bộ điều phối di trú) | `dh-integration` | Z3 | Cùng DU với module `flow` (PH-04), `adapter` (PH-05), khác module Modulith |
| Cổng sự kiện (API phát, API kéo, chống trùng, kiểm lược đồ) | `dh-runtime`, Deployment `dh-runtime-event-gateway` trong namespace `dh-rt-{tenant}` | Z4 | Sau `apisix-ext` và `apisix-int`; tối thiểu 2 bản sao, HPA theo CPU |
| Bộ giao nhận webhook (kèm bộ phát lại, bộ giám sát tuân thủ, bộ xác minh endpoint) | `dh-runtime`, StatefulSet `dh-runtime-event-dispatcher` trong `dh-rt-{tenant}` | Z4 | Tối thiểu 2 bản sao, KEDA theo tổng lag của nhóm `dh-sub-{tenant}-*` |
| Cầu nối Pulsar | Luồng Camel trên `dh-runtime` hồ sơ `legacy-jvm` (thành phần `pulsar`) | Z4 | Chỉ trong giai đoạn di trú |
| Kafka KRaft, Topic Operator, User Operator | Strimzi, namespace `dh-kafka` | Z4 (broker), listener `external` mở ra Z2 khi tenant bật | Ba broker, `replicas: 3`, `min.insync.replicas: 2` |
| Apicurio Registry 3 | Nền tảng, lưu trữ trên `pg-infra` (schema riêng của Apicurio, D03-09) | Z4 | Ghi chỉ bởi `dh-integration`; HTTT đọc qua `/event/v1/registry/**` |
| `pg-core` schema `ph10_event` | Nền tảng (CNPG) | Z5 | RLS theo `tenant_id` |
| OpenBao | Nền tảng | Z5 | `kv/dh/{tenant}/event/subscriptions/{subscriptionCode}/signing`, `transit/dh-{tenant}-event-dlq` |
| Valkey | Nền tảng | Z5 | Lease kéo, chống trùng cổng, ảnh chụp cấu hình runtime (§4.12) |
| Kho Git `dh-config-{tenant}` | Nền tảng (GitHub khi phát triển, GitLab khi bàn giao) | Z3 | `kafka/topics/`, `kafka/users/` |

: Đơn vị triển khai và vùng mạng

Lượt giao webhook đi từ Z4 qua egress gateway với `ServiceEntry` theo FQDN (SEC-16). Lượt phát và kéo của HTTT đi vào qua APISIX (Z2), APISIX gọi OPA kiểm scope và quan hệ còn hiệu lực ở từng lượt (SEC-26), rồi chuyển tới cổng sự kiện của đúng tenant theo tiền tố của `topicName` hoặc theo `subscriptionCode` tra trong bảng định tuyến của APISIX.

### 2.2. Sơ đồ thành phần

```{.mermaid caption="Sơ đồ thành phần của PH-10 trong dh-integration và dh-runtime"}
flowchart TB
  subgraph Z2["Z2 · Biên"]
    AX["apisix-ext / apisix-int<br/>OIDC, OPA, limit-count"]
  end
  subgraph Z3["Z3 · dh-integration"]
    WEB["event.web<br/>/api/event/v1"]
    DOM["event.internal<br/>aggregate, dịch vụ"]
    PROV["provisioning<br/>GitOps writer, reconciler"]
    LAG["lag collector"]
    DLQW["dlq ingestor"]
    OBX["outbox_event"]
    WEB --> DOM --> OBX
    DOM --> PROV
  end
  subgraph Z4["Z4 · dh-runtime, Kafka"]
    GW["event-gateway<br/>phát, kéo"]
    DSP["event-dispatcher<br/>giao, thử lại, phát lại"]
    BR["Cầu nối Pulsar"]
    K[("Kafka KRaft")]
    APC["Apicurio 3"]
    STZ["Strimzi operators"]
  end
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph10_event")]
    BAO["OpenBao"]
    VK[("Valkey")]
  end
  GIT[("dh-config-{tenant}")]
  HTTT["HTTT"]
  AX --> WEB
  HTTT --> AX --> GW
  GW --> K
  K --> DSP -->|"webhook ký HMAC qua egress"| HTTT
  DOM --> PG
  DOM -->|"ghi lược đồ"| APC
  PROV -->|"commit KafkaTopic, KafkaUser"| GIT -->|"Argo CD"| STZ --> K
  PROV -.->|"đọc trạng thái CR"| STZ
  DOM -->|"ghi khóa ký"| BAO
  DSP -->|"đọc khóa ký"| BAO
  GW --> VK
  DSP --> VK
  GW -->|"đọc lược đồ"| APC
  DSP -->|"GET /runtime/subscriptions"| WEB
  LAG -->|"Admin API"| K
  K --> DLQW --> PG
  OBX -->|"Debezium outbox"| K
  BR --> K
```

Sơ đồ cho thấy ba đường. Đường khai báo đi từ giao diện qua APISIX vào `event.web`, ghi `ph10_event` và `outbox_event` trong một giao dịch, rồi sinh tài nguyên Strimzi vào Git và đăng ký lược đồ ở Apicurio. Đường bản tin đi từ HTTT qua APISIX tới cổng sự kiện, ghi Kafka, rồi bộ giao nhận đẩy về HTTT nhận hoặc HTTT nhận tự kéo qua cổng; đường này chỉ chạm Kafka, Apicurio (đọc, có đệm), OpenBao (đọc khóa ký, có đệm) và Valkey. Đường phản hồi gồm bộ thu lag đọc Admin API và bộ ghi DLQ tiêu thụ topic `*.dlq` để lưu bền mục DLQ. Bộ giao nhận lấy cấu hình subscription qua API-10-073 với scope `event:runtime-config` và giữ ảnh chụp ở Valkey để chạy tiếp khi control plane ngừng.

### 2.3. Phụ thuộc với module và phân hệ khác

| Bên | Hướng | Cơ chế | Dùng cho | Khi bên kia không khả dụng |
|---|---|---|---|---|
| PH-01 Kết nạp HTTT | PH-10 gọi và tiêu thụ | `SystemRegistryApi` (bản sao đọc, nạp bằng API-01-063, 064 với token `onboarding:internal-read` khi khởi tạo và đối chiếu mỗi giờ), EVT-01-03 và EVT-01-04 `{tenant}.connect.system.state-changed.v1` (đổi trạng thái HTTT, kèm ảnh chụp đối chiếu hằng giờ) | Kiểm `systemCode` `ACTIVE`, `clientId`, cấp độ ATTT; tạm ngừng theo PH-01 (FR-10-029) | Khai báo bên phát, bên nhận mới trả ERR-10-029; bên đang có giữ nguyên; đối chiếu mỗi giờ bù sự kiện lỡ |
| PH-04 Lõi tích hợp | Hai chiều trong tiến trình | `flow.api.FlowQueryApi` (PH-10 gọi); `event.api.EventPermissionApi`, `EventCatalogApi` (PH-04 gọi, cùng DU); qua HTTP cho môi trường tách DU: API-10-071, 072 với scope `event:permission-check` | VR-10, bảng chọn topic của trình thiết kế, phụ thuộc luồng (API-04-016), EVT-04-09 | PH-04 chặn gửi duyệt luồng khi không kiểm được (FR-10-069) |
| PH-05 Bộ điều hợp | PH-05 gọi | `event.api.TopicRegistrationApi` trong tiến trình hoặc API-10-009, API-10-023 với scope `event:topic-register`; tiêu thụ EVT-05-11 | Topic CDC tự duyệt (FR-10-066, 068) | PH-05 trả ERR-05-029, CDC đang chạy không ảnh hưởng |
| PH-12 Định danh | PH-10 gọi | Keycloak Admin API (gắn, gỡ client scope), bundle dữ liệu OPA | Scope `topic:{topicName}:publish`, `:subscribe` (BR-10-020) | Lệnh duyệt trả ERR-10-029, yêu cầu giữ `PENDING` |
| PH-13 Giám sát, kiểm toán | PH-10 phát | OTLP (chỉ số, vết, log), outbox kiểm toán | Lag, giao nhận, kiểm toán (FR-10-059, 065) | Đệm của bộ thu OTel; kiểm toán nằm trong outbox chờ |
| PH-18 Vận hành | PH-18 gọi, PH-10 phát | API-10-060…065 với scope `event:dlq-read`, `event:replay`; EVT-10-07, 09, 10, 11, 12, 14, 15 | Màn DLQ chung, sự cố | Không ảnh hưởng PH-10 |
| PH-18 kho tham số | PH-10 đọc | `ParameterApi` với tiền tố `10.` | Tham số tenant (FR-10-063) | Đệm tối đa 60 giây qua `dh-ops-client`, làm mới ngay khi PH-18 phát EVT-18-01 (BR-18-006, ADR-180); giá trị mặc định Phụ lục A.5 |
| PH-20 Quản trị tenant | PH-10 tiêu thụ, báo tiến độ | EVT-20-01 `platform.tenant.created.v1`, EVT-20-04 `platform.tenant.status-changed.v1` qua `inbox_event`; báo bước `S06_EVENTING` bằng API-20-166 với scope `tenant:provision-report` | Khai báo nền: hạn mức, principal nội bộ, ACL tiền tố, topic hệ thống (FR-10-064) | Khởi tạo chạy lại idempotent |
| PH-02 Danh mục dịch vụ | PH-02 tiêu thụ | EVT-10-01, 03, 04 | Công bố topic như dịch vụ sự kiện | Không ảnh hưởng |
| Apicurio, Git, Argo CD, Strimzi, OpenBao | PH-10 gọi | Client có ngắt mạch (§8.4) | Lược đồ, cấp phát, khóa ký | ERR-10-029, không để lại trạng thái dở dang |

: Phụ thuộc với module và phân hệ khác

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện có `docs/07-srs/SRS-PH-10-event.md` (FR-10-001…015 cũ) nhưng chưa có mã nguồn của module `event`. Module được tạo mới theo cấu trúc §3; ánh xạ FR cũ sang FR mới ở FRS §11.3. Hai mô-đun `dh-runtime` dựng trên thư viện `dh-runtime-lib` đã có của PH-04 (mTLS mesh, `TenantContext`, chỉ số chung) và PH-05 (đệm bí mật OpenBao `ConnManifestCache` được tái dùng cho khóa ký).

## 3. Cấu trúc mã nguồn

### 3.1. Module `event` trong `dh-integration`

```text
vn.datahub.integration.event
├── api/                         # công bố cho module khác (chỉ gói này được import từ ngoài)
│   ├── EventPermissionApi       # VR-10 cho PH-04 (FR-10-069)
│   ├── EventCatalogApi          # tra cứu topic, lược đồ hiện hành, phụ thuộc luồng
│   ├── TopicRegistrationApi     # đăng ký topic CDC, SYSTEM (FR-10-066, 067)
│   └── dto/                     # TopicView, PermissionCheckItem, PermissionResult, RegistrationResult
├── web/                         # @RestController theo nhóm API-10-001…078; ProblemDetail ERR-10-0xx
│   └── runtime/                 # API-10-073 cho dh-runtime (scope event:runtime-config)
├── internal/
│   ├── project/                 # aggregate EventProject (FR-10-001…005)
│   ├── topic/                   # aggregate Topic, TopicNamePolicy (BR-10-002), TopicConfigPolicy, TopicChangeService
│   ├── schema/                  # aggregate EventSchema, SchemaVersion; ApicurioGateway; CompatibilityChecker; PiiScanner
│   ├── party/                   # aggregate Publisher, Subscriber; CommTypeMatrix (A.2.8, BR-10-017)
│   ├── publication/             # aggregate Publication
│   ├── subscription/            # aggregate Subscription, SigningKey; EndpointPolicy (BR-10-026); StartPositionInitializer
│   ├── approval/                # aggregate ApprovalRequest; FourEyesGuard (BR-10-010); AutoApprovalPolicy (BR-10-031); Expirer
│   ├── provisioning/            # GitOpsWriter, KafkaManifestRenderer, ProvisioningReconciler, DriftDetector, ConsumerGroupAdmin
│   ├── access/                  # KeycloakScopeBinder, OpaDataPublisher, AclRenderer, QuotaAllocator (BR-10-029)
│   ├── signing/                 # SigningKeyService (OpenBao KV v2, chỉ ghi), RotationScheduler
│   ├── dlq/                     # DlqIngestor (tiêu thụ *.dlq), DlqService, PayloadVault (transit), Purger
│   ├── replay/                  # ReplayService (FR-10-051…053), RangeResolver (offsetsForTimes)
│   ├── lag/                     # LagCollector (khóa phân tán), AlertEvaluator (FR-10-055), LagSampleRollup
│   ├── stats/                   # DeliveryStatIngestor (từ dh-runtime), DashboardQuery, GraphBuilder (FR-10-057, 058)
│   ├── catalog/                 # CommType, RoutingMode và bật tắt theo tenant (FR-10-060, 061)
│   ├── quota/                   # TenantEventQuota, QuotaGuard (FR-10-062)
│   ├── settings/                # đọc tham số 10.* qua ParameterApi của PH-18
│   ├── machine/                 # TopicRegistrationService, CdcSchemaChangeConsumer (EVT-05-11), PartySyncConsumer (PH-01, PH-04)
│   ├── tenancy/                 # TenantBootstrapper (PH-20), LeakProbeScheduler (SEC-87)
│   ├── exchange/                # ManifestExporter, ManifestImportJob (FR-10-070, 071)
│   ├── migration/               # PulsarInventoryImporter, LegacyMapping, MigrationBridge, BridgeFlowRenderer, Reconciler
│   └── idempotency/             # IdempotencyFilter, IdempotencyStore
└── events/                      # record EVT-10-01…16, OutboxWriter, EventTypes (ce_type vn.datahub.event.*)
```

Quy tắc phụ thuộc kiểm bằng Spring Modulith (`ApplicationModules.verify()`) và ArchUnit:

| Luật | Kiểm bằng |
|---|---|
| Module khác chỉ import `event.api` và `event.events` | Modulith, `@NamedInterface` |
| `event` chỉ import `flow.api` (PH-04), `adapter.api` (PH-05), `platform.api` (tham số, kiểm toán) | Modulith |
| Lớp `web` không gọi `ApicurioGateway`, `GitOpsWriter`, `SigningKeyService` trực tiếp; mọi lệnh qua dịch vụ ứng dụng trong `internal/*` | ArchUnit |
| Không lớp nào ngoài `signing` có kiểu `SigningSecret`; `SigningSecret.toString()` trả `***` | ArchUnit, kiểm thử canary NFR-10-016 |
| Gói `provisioning` là nơi duy nhất dùng client Kubernetes (chỉ đọc) và Kafka Admin | ArchUnit |
| Mọi lệnh đổi trạng thái đi qua phương thức của aggregate, không `UPDATE … SET status` ngoài repository của aggregate | ArchUnit theo tên phương thức repository |

: Module event trong dh-integration

### 3.2. Hai mô-đun ở `dh-runtime`

```text
dh-runtime/
├── dh-runtime-lib/
│   └── vn.datahub.runtime.event
│       ├── common/              # RuntimeConfigClient (API-10-073), RuntimeConfigCache (Caffeine + ảnh chụp Valkey),
│       │                        # SchemaCache (Apicurio, theo contentId), CloudEventCodec (nhị phân Kafka, JSON có cấu trúc),
│       │                        # TenantGuard (tenant từ tiền tố topic), EventMetrics
│       ├── gateway/             # mô-đun cổng sự kiện (ADR-071)
│       │   ├── PublishResource       # API-10-079
│       │   ├── PullResource          # API-10-080…082
│       │   ├── DeadLetterResource    # API-10-083 (bên nhận Kafka ngoài tự báo)
│       │   ├── RegistryProxy         # API-10-084, chỉ đọc
│       │   ├── EnvelopeValidator     # CloudEvents 1.0, BR-10-021
│       │   ├── PartitionKeyResolver  # FR-10-013
│       │   ├── TenantProducerPool    # producer idempotent acks=all theo tenant
│       │   ├── PublishDeduplicator   # (bên phát, id) 24 giờ ở Valkey
│       │   ├── LeaseManager          # một lease mỗi subscription PULL_API
│       │   └── CursorCodec           # cursor ký HMAC phía máy chủ
│       └── delivery/            # mô-đun bộ giao nhận webhook (ADR-071)
│           ├── SubscriptionSupervisor # khởi, dừng, đổi tham số consumer theo cấu hình
│           ├── SlotAllocator          # chia worker của subscription cho các bản sao
│           ├── PartitionWorker        # vòng giao tuần tự trong một phân vùng
│           ├── WebhookRequestBuilder  # CLOUDEVENTS_STRUCTURED, CLOUDEVENTS_BINARY
│           ├── WebhookSigner          # ADR-044, hai chữ ký khi xoay khóa
│           ├── EgressGuard            # BR-10-026, chống DNS rebinding
│           ├── RetryPolicy            # FR-10-039
│           ├── SubscriptionBreaker    # ngắt mạch 50% trong 10.push.suspend-after-failures-minutes
│           ├── DlqWriter              # ghi {topicName}.dlq acks=all
│           ├── DeliveryStatsReporter  # cửa sổ 1 phút, lượt lỗi
│           ├── EndpointVerifier       # bắt tay CloudEvents HTTP Webhook (FR-10-036)
│           ├── replay/                # ReplayRunner (REDELIVER_RANGE, DLQ_ENTRIES), TokenBucket
│           └── compliance/            # ComplianceSampler (FR-10-023)
├── dh-runtime-kamelets/
│   └── event/                   # dh-kafka-source, dh-kafka-sink (đọc cấu hình topic từ PH-10, dùng cho luồng PH-04),
│                                # dh-pulsar-bridge-source, dh-pulsar-bridge-sink (cầu nối, ADR-073)
└── profiles/
    └── event-native/            # hồ sơ mới: chỉ gateway, delivery; không nạp luồng (FlowLoader tắt)
```

Hồ sơ `event-native` (Quarkus native, Vert.x HTTP client, Kafka client) được ghi vào `runtime-manifest.json` như mọi hồ sơ khác (FR-04-081). Một ảnh, hai vai: biến `DH_EVENT_ROLE=gateway` hoặc `dispatcher` chọn mô-đun khởi động. Hai vai tách Deployment để mở rộng độc lập: cổng mở rộng theo CPU và số yêu cầu, bộ giao nhận theo lag. Cầu nối Pulsar không ở hồ sơ này mà chạy ở `legacy-jvm` vì client Pulsar chưa ổn định ở native.

### 3.3. Giao diện công bố cho PH-04, PH-05

```java
public interface EventPermissionApi {
    // FR-10-069: kết quả ALLOWED, PENDING, DENIED kèm lý do TOPIC_NOT_FOUND, TOPIC_NOT_ACTIVE, NO_GRANT, GRANT_SUSPENDED
    List<PermissionResult> check(TenantId tenant, String environment, List<PermissionCheckItem> items);
    List<TopicView> usableTopics(TenantId tenant, String flowCode, String action);
    FlowDependencies dependenciesOf(TenantId tenant, String flowCode);     // cho API-04-016
    EnsurePartyResult ensureParty(TenantId tenant, String flowCode, List<PermissionCheckItem> wanted, UserRef onBehalfOf);
}

public interface TopicRegistrationApi {
    // FR-10-066, 067: idempotent theo topicName; trả PROVISIONING, PENDING_APPROVAL hoặc trạng thái hiện tại
    RegistrationResult register(TenantId tenant, ServiceRef caller, TopicRegistration request);
    SchemaRegistrationResult registerSchemaVersion(TenantId tenant, ServiceRef caller, String topicName, SchemaDraft draft);
    RegistrationResult newMajorVersion(TenantId tenant, ServiceRef caller, String topicName, SchemaDraft draft);
}
```

Giá trị `ALLOWED`, `PENDING`, `DENIED` và bốn lý do là kết quả trả về do FR-10-069 nêu, không phải trạng thái lưu. PH-04 và PH-05 cùng DU gọi trong tiến trình; khi tách DU (cấu hình `dh.event.remote=true`) lớp `api` có bản hiện thực gọi HTTP API-10-071, 072, 009, 023 với token dịch vụ, ngắt mạch 5 giây.

### 3.4. DTO chính

| DTO | Trường (tên API theo Phụ lục A.3) | Dùng ở |
|---|---|---|
| `TopicView` | `topicName`, `projectCode`, `topicKind`, `status`, `partitions`, `retentionHours`, `cleanupPolicy`, `routingMode`, `partitionKeyField`, `orderingRequired`, `dataClass`, `latestSchemaVersion`, `successorTopic`, `sunsetAt` | API-10-008, 010, `EventCatalogApi` |
| `RuntimeSubscription` | `subscriptionCode`, `topicName`, `deliveryMode`, `status`, `consumerGroup`, `push{endpointUrl, workerCount, maxRetries, retryBackoff, timeoutMs, failurePolicy, payloadFormat}`, `pull{maxBatch, leaseSeconds}`, `signingKeys[]{keyId, status, previousUntil}`, `configVersion` | API-10-073 cho bộ giao nhận, cổng kéo |
| `RuntimeTopic` | `topicName`, `status`, `routingMode`, `partitionKeyField`, `orderingRequired`, `maxMessageBytes`, `apicurioGroupId`, `apicurioArtifactId`, phiên bản `ENABLED`, `DEPRECATED`, `configVersion` | API-10-073 phần topic, cổng phát |
| `DeliveryReport` | `subscriptionCode`, `windowStart`, `successCount`, `transientErrorCount`, `retryCount`, `deadLetterCount`, `latencyP50Ms`, `latencyP95Ms`, danh sách `DeliveryFailure` | Bộ giao nhận gửi về (§4.10) |

: DTO chính

`RuntimeSubscription` không bao giờ chứa bí mật ký; chỉ có `keyId` để bộ giao nhận đọc đúng phiên bản ở OpenBao. `configVersion` là giá trị cột `version` của bản ghi, dùng để bộ giao nhận bỏ qua cập nhật cũ hơn trạng thái đang giữ.

### 3.5. Danh sách thành phần được đặc tả

Bảng sau liệt kê 16 thành phần được đặc tả ở chương 4 (từ mục 4.2), lớp chính và FR mà mỗi thành phần hiện thực. Mỗi mục mở bằng khối đặc tả 10 mục (mục đích, lớp chính, đơn vị chạy, FR hiện thực, giao diện vào, phụ thuộc ra, dữ liệu, sự kiện, lỗi và xử lý, quan sát) để người đọc nắm thành phần trước khi vào thuật toán. Mục 4.1 là mô hình miền dùng chung, không phải thành phần riêng.

| Mục | Thành phần | Lớp chính | FR |
|---|---|---|---|
| 4.2 | Chính sách tên topic | `TopicNamePolicy` (hàm thuần), `TopicConfigPolicy` | FR-10-008, 015, 066, 067; BR-10-002, 030 |
| 4.3 | Lược đồ và Apicurio | `ApicurioGateway`, `CompatibilityChecker`, `PiiScanner`, aggregate `EventSchema`, `SchemaVersion` | FR-10-017…022, 024; BR-10-011…013 |
| 4.4 | Cấp phát qua GitOps và đối soát | `GitOpsWriter`, `KafkaManifestRenderer`, `ProvisioningReconciler`, `DriftDetector`, `RetiredTopicJanitor`, `ConsumerGroupAdmin` | FR-10-009, 010, 011, 012, 014, 031, 037; ADR-072 |
| 4.5 | Quyền truy cập: scope, OPA, ACL, hạn mức | `AccessGrantService`, `KeycloakScopeBinder`, `OpaDataPublisher`, `AclRenderer`, `QuotaAllocator` | FR-10-031, 032, 037, 041, 047, 062; BR-10-020, 029 |
| 4.6 | Cổng sự kiện: API phát | `PublishResource`, `EnvelopeValidator`, `SchemaCache`, `PartitionKeyResolver`, `PublishDeduplicator`, `TenantProducerPool`, `TenantGuard` | FR-10-033, 013; BR-10-021; NFR-10-002 |
| 4.7 | Cổng sự kiện: API kéo có lease và cursor | `PullResource`, `DeadLetterResource`, `LeaseManager`, `CursorCodec` | FR-10-043, 044, 052 |
| 4.8 | Bộ giao nhận webhook | `SubscriptionSupervisor`, `SlotAllocator`, `PartitionWorker`, `WebhookRequestBuilder`, `WebhookSigner`, `EgressGuard`, `RetryPolicy`, `SubscriptionBreaker`, `DlqWriter`, `EndpointVerifier` | FR-10-036, 038, 039, 040, 042, 046, 048, 049; BR-10-024, 026; ADR-044, 071 |
| 4.9 | Bộ ghi DLQ và kho nội dung | `DlqIngestor`, `DlqService`, `PayloadVault`, `DlqPurger`, `DlqAlertAggregator` | FR-10-049, 050, 053; BR-10-023, 024 |
| 4.10 | Thống kê giao nhận và lượt lỗi | `DeliveryStatsReporter` (runtime), `DeliveryStatIngestor` (control plane) | FR-10-056 |
| 4.11 | Bộ phát lại | `ReplayService`, `RangeResolver`, `ReplayExpirer` (control plane); `ReplayRunner`, `TokenBucket` (runtime) | FR-10-051, 052, 053; BR-10-028 |
| 4.12 | Cấu hình runtime và chạy khi control plane ngừng | `RuntimeConfigClient`, `RuntimeConfigCache` | FR-10-013, 033, 038, 043; NFR-10-013; ADR-071 |
| 4.13 | Bộ thu lag và cảnh báo | `LagCollector` (ShedLock), `AlertEvaluator`, `LagSampleRollup` | FR-10-054, 055 |
| 4.14 | Đăng ký máy với máy | `TopicRegistrationService`, `AutoApprovalPolicy`, `CdcSchemaChangeConsumer`, `PartySyncConsumer`, `PartyReconciler`, `EventPermissionApi` | FR-10-029, 066, 067, 068, 069; BR-10-031 |
| 4.15 | Sơ đồ kết nối và dashboard | `GraphBuilder`, `DashboardQuery` | FR-10-057, 058, 059 |
| 4.16 | Di trú từ Pulsar | `PulsarInventoryImporter`, `LegacyMapping`, `BridgeFlowRenderer`, `BridgeMonitor`, `MigrationReconciler`, `CutOverService` | FR-10-072…076; BR-10-033; ADR-073 |
| 4.17 | Xuất, nhập khai báo | `ManifestExporter`, `ManifestImportJob` | FR-10-070, 071; BR-10-027, 032 |

: Danh sách thành phần được đặc tả của PH-10

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

```{.mermaid caption="Mô hình miền của module event"}
classDiagram
  class EventProject {
    projectCode
    name
    ownerOrgCode
    status
    archive()
    restore()
  }
  class Topic {
    topicName
    topicKind
    partitions
    retentionHours
    cleanupPolicy
    routingMode
    partitionKeyField
    orderingRequired
    dataClass
    status
    predecessorTopic
    successorTopic
    sunsetAt
    provisioningCommit
    submit()
    markProvisioning(commit)
    activate()
    fail(error)
    deprecate(successor, sunsetAt)
    retire()
  }
  class EventSchema {
    schemaFormat
    compatibility
    apicurioGroupId
    apicurioArtifactId
    latestVersionNo
  }
  class SchemaVersion {
    versionNo
    contentHash
    status
    apicurioGlobalId
    apicurioContentId
    compatibilityReport
    piiFindings
  }
  class Publisher {
    publisherCode
    partyType
    commType
    systemCode
    flowCode
    serviceCode
    kafkaPrincipal
    status
    suspendSource
  }
  class Subscriber {
    subscriberCode
    partyType
    commType
    status
    suspendSource
  }
  class Publication {
    publicationCode
    status
    grantedScope
    aclRef
    quotaBytesPerSecond
    suspendSource
  }
  class Subscription {
    subscriptionCode
    deliveryMode
    consumerGroup
    startPosition
    status
    alertState
    push
    pull
    suspendSource
  }
  class SigningKey {
    keyId
    secretRef
    status
    previousUntil
  }
  class ApprovalRequest {
    requestCode
    requestType
    targetType
    targetCode
    status
    autoApproved
    approve(by)
    reject(by, comment)
    withdraw(by)
  }
  class DlqEntry {
    dlqEntryId
    origin
    errorCode
    attempts
    status
    replayCode
  }
  class ReplayRequest {
    replayCode
    replayMode
    rangeType
    status
    ratePerSecond
  }
  EventProject "1" --> "*" Topic
  Topic "1" --> "1" EventSchema
  EventSchema "1" --> "*" SchemaVersion
  Publisher "1" --> "*" Publication
  Topic "1" --> "*" Publication
  Subscriber "1" --> "*" Subscription
  Topic "1" --> "*" Subscription
  Subscription "1" --> "*" SigningKey
  Subscription "1" --> "*" DlqEntry
  Subscription "1" --> "*" ReplayRequest
  ApprovalRequest ..> Topic
  ApprovalRequest ..> SchemaVersion
  ApprovalRequest ..> Publication
  ApprovalRequest ..> Subscription
  ApprovalRequest ..> ReplayRequest
```

Sơ đồ chỉ ghi trường cần cho invariant; danh sách đủ ở Phụ lục A.3. Ranh giới aggregate và invariant được kiểm trong mã:

| Aggregate | Bảng | Invariant kiểm ở máy chủ | Nguồn |
|---|---|---|---|
| `EventProject` | `event_project` | `projectCode` duy nhất trong tenant kể cả `ARCHIVED`, không thuộc từ dành riêng; lưu trữ chỉ khi không còn topic `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED` | BR-10-003, FR-10-005 |
| `Topic` | `topic` | Tên theo `TopicNamePolicy`; `replicationFactor = 3`, `minInsyncReplicas = 2` hằng; `partitions` chỉ tăng; `orderingRequired` đòi `KEY_HASH` hoặc `SINGLE_PARTITION`; `COMPACT`, `COMPACT_DELETE` đòi chế độ có khóa; `SINGLE_PARTITION` có `partitions = 1`; người dùng không sửa topic `CDC`, `SYSTEM` ngoài `description` | BR-10-002, 004, 005, 006, 030; ERR-10-045, 046, 048 |
| `EventSchema` + `SchemaVersion` | `event_schema`, `schema_version` | Một lược đồ mỗi topic; không sửa nội dung phiên bản đã `ENABLED`; `NONE` chỉ khi topic chưa từng `ACTIVE` (`activatedAt` rỗng); không `DISABLED` phiên bản mới nhất | BR-10-011, 012, 013, 015 |
| `Publisher`, `Subscriber` | `publisher`, `subscriber` | Tổ hợp `partyType`, `commType`, `deliveryMode` theo `CommTypeMatrix`; một bên `SYSTEM` cho mỗi cặp (`systemCode`, `commType`) | BR-10-017; ERR-10-024 |
| `Publication` | `publication` | Duy nhất theo (`publisherCode`, `topicName`) khi chưa `REVOKED`; topic `ACTIVE` hoặc `DEPRECATED` khi duyệt; topic `RESTRICTED`, `SENSITIVE` chỉ bên `SYSTEM` đạt cấp độ | BR-10-016, 019 |
| `Subscription` + `SigningKey` | `subscription`, `signing_key` | Duy nhất theo (`subscriberCode`, `topicName`) khi chưa `REVOKED`; `workerCount` ≤ min(`partitions`, `10.push.max-workers`); `deliveryMode` hợp với `commType`; tối đa một `SigningKey` `ACTIVE` và một `PREVIOUS` | BR-10-017, 022, 025, 027 |
| `ApprovalRequest` | `approval_request` | Bốn mắt: `decidedBy` khác `requestedBy` và khác người tạo đối tượng đích; một yêu cầu `PENDING` mỗi (`targetType`, `targetCode`, `requestType`) | BR-10-010 |
| `DlqEntry` | `dlq_entry`, `dlq_payload` | Chỉ `PURGED` sau `REPLAYED` hoặc `DISCARDED` và qua thời gian giữ; `NEW` không tự xóa | BR-10-024 |
| `ReplayRequest` | `replay_request` | Một lượt `APPROVED` hoặc `RUNNING` mỗi subscription; `RESET_OFFSET` đòi subscription `PAUSED` | BR-10-028; ERR-10-032, 035 |
| `LegacyMapping`, `MigrationBridge` | `legacy_mapping`, `migration_bridge` | Không hai cầu nối ngược chiều cùng cặp topic đang `RUNNING`; có `expiresAt` | BR-10-033 |

: Mô hình miền

Mỗi aggregate có cột `version` (khóa lạc quan). Lệnh từ API mang `If-Match`; lệnh hệ thống (đối soát, hết hạn, theo PH-01) thử lại tối đa 3 lần khi xung đột rồi ghi cảnh báo.

### 4.2. Chính sách tên topic

::: dac-ta
**Mục đích.** Bảo đảm mọi tên topic đúng quy ước `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}` và tiền tố tenant trước khi lưu, để topic của tỉnh này không bao giờ trùng hay lẫn với tỉnh khác và miền dành riêng không bị HTTT chiếm.

**Lớp chính.** `TopicNamePolicy` (hàm thuần), `TopicConfigPolicy`.

**Đơn vị chạy.** `dh-integration`, gói `internal/topic`.

**FR hiện thực.** FR-10-008, 015, 066, 067; BR-10-002, 030.

**Giao diện vào.** Gọi nội bộ từ `TopicChangeService` (API-10-009) và `TopicRegistrationService` (API-10-071, 072).

**Phụ thuộc ra.** Không.

**Dữ liệu.** Đọc `topic` để kiểm trùng; CHECK `ck_topic_name_*` ở CSDL là lớp chặn thứ hai.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-10-004 (sai quy ước, miền dành riêng), ERR-10-005 (tiền tố tenant không khớp), ERR-10-002 (tên đã dùng).

**Quan sát.** Không có chỉ số riêng; kiểm thử bằng bảng ca (§12).
:::

Chi tiết thiết kế:

`TopicNamePolicy` là hàm thuần, kiểm thử bằng bảng ca. Nó nhận `tenant`, `topicKind`, các đoạn tên và trả tên đã chuẩn hóa hoặc mã lỗi:

| Loại | Mẫu | Kiểm thêm | Lỗi |
|---|---|---|---|
| `BUSINESS` | `^{tenant}\.[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2}\.v[1-9][0-9]*$` | Miền không thuộc danh sách dành riêng của FR-10-008; tổng ≤ 200 ký tự | ERR-10-004 |
| `CDC` | Tiền tố `{tenant}.cdc.`, 2…4 đoạn giữa, hậu tố `.v{n}` | Chỉ tài khoản dịch vụ có `event:topic-register` | ERR-10-004, 005 |
| `SYSTEM` | `{tenant}.{miền dành riêng}.…v{n}` hoặc tiền tố `dh.`, `platform.` (tenant `COMMON`) | Chỉ tài khoản dịch vụ; `dh.`, `platform.` chỉ PA hoặc dịch vụ nền tảng | ERR-10-004, 045 |
| `DLQ` | `{topicName}.dlq` | Chỉ hệ thống tạo cùng topic cha | Không nhận từ API |

: Chính sách tên topic

Tiền tố tenant luôn là mã tenant chữ thường của ngữ cảnh xác thực (`T68` thành `t68.`); tiền tố khác trả ERR-10-005. Tên đã dùng (kể cả `RETIRED`) bị chặn bằng ràng buộc duy nhất `(tenant_id, topic_name)` không có điều kiện trạng thái (BR-10-003).

### 4.3. Lược đồ và Apicurio

::: dac-ta
**Mục đích.** Làm nơi duy nhất ghi Apicurio Registry: tạo artifact mỗi topic, kiểm tra tương thích `dryRun`, bật, ngừng khuyến nghị, vô hiệu phiên bản lược đồ qua duyệt bốn mắt và quét dữ liệu cá nhân trong lược đồ.

**Lớp chính.** `ApicurioGateway`, `CompatibilityChecker`, `PiiScanner`, aggregate `EventSchema`, `SchemaVersion`.

**Đơn vị chạy.** `dh-integration`, gói `internal/schema`.

**FR hiện thực.** FR-10-017…022, 024; BR-10-011…013.

**Giao diện vào.** API-10-021…031 (control plane), API-10-084 (tra lược đồ chỉ đọc), `TopicRegistrationApi.registerSchemaVersion` cho PH-05.

**Phụ thuộc ra.** Apicurio Registry 3 REST v3 (client Keycloak `dh-integration-registry`, vai trò `sr-developer`).

**Dữ liệu.** `event_schema`, `schema_version`, `approval_request`.

**Sự kiện.** EVT-10-05 khi phiên bản `ENABLED`; EVT-10-02 khi đổi mức tương thích hoặc trạng thái phiên bản.

**Lỗi và xử lý.** ERR-10-017 (lược đồ sai cú pháp), ERR-10-018 (không tương thích), ERR-10-019 (NONE sau khi topic đã ACTIVE), ERR-10-020; Apicurio không phản hồi thì thử lại 3 lần rồi trả lỗi tạm thời, không đổi trạng thái.

**Quan sát.** Span `event.schema.check`; kiểm toán mọi lệnh bật, vô hiệu.
:::

Chi tiết thiết kế:

`ApicurioGateway` bọc REST API v3 của Apicurio, là lớp duy nhất có thông tin xác thực ghi registry (client Keycloak `dh-integration-registry`, vai trò `sr-developer`). Các thao tác:

| Thao tác | Lời gọi Apicurio | Khi nào |
|---|---|---|
| Kiểm tra nháp | `POST /groups/{tenant}/artifacts/{topicName}/versions?dryRun=true` (artifact đã có) hoặc tạo artifact với `dryRun=true` | FR-10-017, 018 khi soạn, khi gửi duyệt |
| Tạo artifact và phiên bản 1 | `POST /groups/{tenant}/artifacts` với `artifactType` (`AVRO` hoặc `JSON` theo `schemaFormat`), quy tắc `COMPATIBILITY` theo `compatibility`, quy tắc `VALIDITY = FULL` | Duyệt `TOPIC_CREATE` (FR-10-009) |
| Thêm phiên bản | `POST /groups/{tenant}/artifacts/{topicName}/versions` | Duyệt `SCHEMA_VERSION` (FR-10-019) |
| Đổi trạng thái phiên bản | `PUT …/versions/{versionNo}/state` với `ENABLED`, `DEPRECATED`, `DISABLED` | FR-10-022 |
| Đổi mức tương thích | `PUT …/artifacts/{topicName}/rules/COMPATIBILITY` | Duyệt `TOPIC_CHANGE` (FR-10-021) |
| Xóa bù | `DELETE …/artifacts/{topicName}` | Hủy cấp phát khi topic chưa có bản tin (FR-10-010), lỗi giữa chừng khi duyệt |

: Lược đồ và Apicurio

`CompatibilityChecker` dùng kết quả `dryRun` làm nguồn chính và ghi `compatibilityReport` (danh sách vi phạm theo đường dẫn trường). Nó thêm hai kiểm tra Apicurio không làm: trường `partitionKeyField` phải có trong lược đồ với kiểu chuỗi hoặc số (ERR-10-017); định dạng phải trùng định dạng đã có (ERR-10-020). `PiiScanner` duyệt cây trường, so tên trường và `doc` với từ điển dữ liệu cá nhân (số định danh, họ tên, ngày sinh, địa chỉ, số điện thoại, thư điện tử) và trả `piiFindings[]` với `severity` `INFO`, `WARNING`, `BLOCKING`; với topic `PUBLIC`, `INTERNAL` và `10.schema.pii-check-mode = BLOCK`, phát hiện `WARNING` trở lên thành `BLOCKING` (ERR-10-018). Khi `WARN`, người duyệt phải gửi `acknowledgePii = true` (FR-10-009).

Thứ tự khi duyệt: (1) ghi Apicurio, (2) ghi `apicurioGlobalId`, `apicurioContentId`, trạng thái `ENABLED` và outbox trong một giao dịch. Nếu bước 2 lỗi sau khi bước 1 thành công, tác vụ bù `SchemaCompensator` chạy mỗi phút tìm phiên bản Apicurio không có bản ghi `ENABLED` tương ứng (so `contentHash`) và hoặc hoàn tất ghi (yêu cầu vẫn `APPROVED` theo nhật ký) hoặc xóa phiên bản Apicurio (yêu cầu không được ghi nhận). Cách này thay cho giao dịch phân tán.

### 4.4. Cấp phát qua GitOps và đối soát

::: dac-ta
**Mục đích.** Biến khai báo đã duyệt thành cấu hình cụm Kafka mà không cấp cho `dh-integration` quyền quản trị cụm: sinh `KafkaTopic`, `KafkaUser` vào kho Git của tenant và theo dõi tới khi Strimzi báo `Ready`.

**Lớp chính.** `GitOpsWriter`, `KafkaManifestRenderer`, `ProvisioningReconciler`, `DriftDetector`, `RetiredTopicJanitor`, `ConsumerGroupAdmin`.

**Đơn vị chạy.** `dh-integration`, gói `internal/provisioning`.

**FR hiện thực.** FR-10-009, 010, 011, 012, 014, 031, 037; ADR-072.

**Giao diện vào.** Sự kiện miền khi topic, publication, subscription được duyệt; API-10-013, 014 (theo dõi, thử lại cấp phát); tác vụ đối soát định kỳ.

**Phụ thuộc ra.** Kho `dh-config-{tenant}` (Git), Kubernetes API chỉ đọc trạng thái CR, Kafka Admin API chỉ cho nhóm tiêu thụ và lag.

**Dữ liệu.** `topic` (`provisioning_commit`, `provisioning_error`), `publication`, `subscription`.

**Sự kiện.** EVT-10-01 (topic `ACTIVE`), EVT-10-03, EVT-10-04 (`DEPRECATED`, `RETIRED`), EVT-10-02 (đổi cấu hình).

**Lỗi và xử lý.** Commit lỗi hoặc CR không `Ready` sau thời hạn thì topic sang `FAILED` kèm `provisioning_error`, người dùng thử lại ở UI-10-06 (FR-10-010).

**Quan sát.** `dh_event_provisioning_state{kind,state}`; cảnh báo lệch cấu hình do `DriftDetector`.
:::

Chi tiết thiết kế:

`KafkaManifestRenderer` sinh YAML xác định (cùng đầu vào cho cùng byte, sắp khóa) cho:

| Tài nguyên | Đường dẫn trong `dh-config-{tenant}` | Nội dung chính |
|---|---|---|
| `KafkaTopic` topic | `kafka/topics/{topicName}.yaml` | `partitions`, `replicas: 3`, `config` (`retention.ms`, `cleanup.policy`, `min.insync.replicas: 2`, `max.message.bytes`), nhãn `dh.gov.vn/tenant`, `dh.gov.vn/project`, `dh.gov.vn/topic-kind`, chú thích `dh.gov.vn/request-code` |
| `KafkaTopic` DLQ | `kafka/topics/{topicName}.dlq.yaml` | Cùng số phân vùng, `retention.ms` theo `10.dlq.topic-retention-hours`, nhãn `dh.gov.vn/topic-kind: dlq` (BR-10-023) |
| `KafkaUser` | `kafka/users/{principal}.yaml` | `authentication` (`tls` cho mTLS hoặc không khai báo cho OAUTHBEARER), `authorization.acls` literal theo topic và nhóm, `quotas` (`producerByteRate`, `consumerByteRate`) do `QuotaAllocator` tính |

: Cấp phát qua GitOps và đối soát

`GitOpsWriter` dùng thư viện JGit qua HTTPS với token kho của tenant (đọc từ OpenBao, quyền chỉ ghi vào nhánh môi trường), mỗi yêu cầu duyệt là một commit có thông điệp `event: {requestType} {targetCode} ({requestCode})`. Khi đẩy bị từ chối do nhánh đã tiến, `GitOpsWriter` kéo lại, áp lại thay đổi (tệp theo tên đối tượng nên không xung đột nội dung) và thử tối đa 5 lần. Commit hash ghi vào `provisioningCommit` của topic hoặc `aclRef` của publication, subscription.

`ProvisioningReconciler` chạy hai vòng, dùng khóa phân tán ShedLock trên `pg-core` để chỉ một bản sao chạy:

1. **Vòng nhanh (10 giây)** cho đối tượng `PROVISIONING`: đọc `status.conditions` của `KafkaTopic`, `KafkaUser` qua Kubernetes API (ServiceAccount chỉ `get`, `list`, `watch` trong `dh-kafka`). `Ready=True` và `observedGeneration` khớp thì gọi `Topic.activate()` hoặc tiếp bước cấp phát subscription; `Ready=False` với lý do từ Strimzi hoặc Kyverno từ chối (sự kiện admission) thì `fail(error)`; quá `10.provisioning.timeout-minutes` cũng `fail`. Kết quả ghi trạng thái và outbox trong một giao dịch.
2. **Vòng đối chiếu (10 phút)** cho mọi topic `ACTIVE`, `DEPRECATED`: so cấu hình thật trên cụm (Admin `describeConfigs`, `describeTopics`) với tệp trong Git và bản ghi `topic`; lệch thì ghi cảnh báo mức cao kèm khác biệt, chỉ số `dh_event_provisioning_state{state="drift"}`, không sửa đè (BR-10-036).

Xóa topic sau `RETIRED`: tác vụ `RetiredTopicJanitor` chờ `10.topic.delete-after-retire-days`, kiểm không còn mục DLQ `NEW` (BR-10-024), rồi commit xóa hai tệp `KafkaTopic`; Strimzi Topic Operator xóa trên cụm (cấu hình `deleteTopics` bật cho namespace). Bản ghi `topic` giữ vĩnh viễn.

### 4.5. Quyền truy cập: scope, OPA, ACL, hạn mức

::: dac-ta
**Mục đích.** Cấp và thu quyền truy cập dữ liệu sự kiện đúng lúc publication, subscription đổi trạng thái: scope OAuth ở Keycloak, dữ liệu chính sách OPA, ACL Kafka và phân bổ hạn mức, mỗi bước idempotent để chạy tiếp được sau lỗi.

**Lớp chính.** `AccessGrantService`, `KeycloakScopeBinder`, `OpaDataPublisher`, `AclRenderer`, `QuotaAllocator`.

**Đơn vị chạy.** `dh-integration`, gói `internal/access`.

**FR hiện thực.** FR-10-031, 032, 037, 041, 047, 062; BR-10-020, 029.

**Giao diện vào.** Chuyển trạng thái `ACTIVE`, `SUSPENDED`, `REVOKED` của publication, subscription.

**Phụ thuộc ra.** Keycloak Admin API, gói dữ liệu OPA, kho Git (`KafkaUser` ACL).

**Dữ liệu.** `publication`, `subscription`, `tenant_event_quota`, `approval_request.checks`.

**Sự kiện.** EVT-10-06, EVT-10-07 (publication), EVT-10-08, EVT-10-09 (subscription).

**Lỗi và xử lý.** ERR-10-011 (vượt hạn mức tenant); bước lỗi giữ dấu hoàn tất ở `checks` và thử lại theo lịch.

**Quan sát.** `dh_event_quota_usage_ratio{kind}`.
:::

Chi tiết thiết kế:

Khi publication, subscription chuyển `ACTIVE`, `AccessGrantService` chạy các bước theo `deliveryMode` và `partyType`, mỗi bước idempotent và ghi dấu hoàn tất vào `ApprovalRequest.checks` để có thể chạy tiếp sau lỗi:

| Đối tượng | `SYSTEM` qua HTTP | `SYSTEM` qua Kafka ngoài | `FLOW`, `INTERNAL_SERVICE` |
|---|---|---|---|
| Publication | Gắn client scope `topic:{topicName}:publish` vào client `clientId` (Keycloak Admin API); thêm cặp (client, topic, `PUBLISH`) vào dữ liệu OPA | ACL `WRITE`, `DESCRIBE` literal trên topic cho `kafkaPrincipal`, `quotas.producerByteRate` | Chỉ ghi nhận (VR-10); ACL tiền tố của principal nội bộ tenant đã có từ khởi tạo (BR-10-018) |
| Subscription `PUSH` | Không cấp scope cho HTTT; bộ giao nhận dùng principal `User:CN=dh-runtime-{tenant}` | — | — |
| Subscription `PULL_API` | Gắn `topic:{topicName}:subscribe`; OPA thêm cặp (client, `subscriptionCode`) | — | — |
| Subscription `PULL_KAFKA` | — | ACL `READ`, `DESCRIBE` literal trên topic, `READ` literal trên nhóm `dh-ext-{tenant}-{subscriptionCode}`, `quotas.consumerByteRate` | — |
| Subscription `INTERNAL` | — | — | Chỉ ghi nhận; nhóm `dh-flow-{tenant}-{flow}` hoặc `dh-svc-{service}-{tenant}` |

: Quyền truy cập: scope, OPA, ACL, hạn mức

`OpaDataPublisher` không đẩy trực tiếp vào OPA mà ghi bundle dữ liệu theo tenant (`event/grants/{tenant}.json`) vào kho bundle của PH-12; OPA kéo bundle mỗi 30 giây và nhận thông báo đẩy (`/v1/data` PATCH qua sidecar) để bảo đảm NFR-10-009 (từ chối trong ≤ 60 giây). Chính sách Rego của APISIX đòi đồng thời scope trong token và cặp cấp quyền trong dữ liệu, nên tạm ngừng chỉ cần gỡ dữ liệu OPA là có hiệu lực, không đợi token hết hạn (BR-10-020).

`QuotaAllocator` tính hạn mức của từng `KafkaUser`: phần dự trữ `10.quota.internal-reserve-ratio` của `produceBytesPerSecond`, `consumeBytesPerSecond` cho principal nội bộ; phần còn lại chia theo `quotaBytesPerSecond` khai báo, tối thiểu 256 KiB/s, và từ chối duyệt khi tổng vượt trần (ERR-10-011, BR-10-029). Hạn mức của cổng HTTP đặt ở APISIX (`limit-count` theo publication), sinh vào cấu hình route của tenant.

### 4.6. Cổng sự kiện: API phát

::: dac-ta
**Mục đích.** Nhận sự kiện HTTT phát qua HTTP, kiểm phong bì CloudEvents và lược đồ, chống trùng rồi ghi bền lên Kafka với `acks=all`; HTTT không cần biết Kafka.

**Lớp chính.** `PublishResource`, `EnvelopeValidator`, `SchemaCache`, `PartitionKeyResolver`, `PublishDeduplicator`, `TenantProducerPool`, `TenantGuard`.

**Đơn vị chạy.** `dh-runtime`, hồ sơ `event-native`, vai `gateway`.

**FR hiện thực.** FR-10-033, 013; BR-10-021; NFR-10-002.

**Giao diện vào.** API-10-079 qua `apisix-ext`, `apisix-int` (danh tính từ `X-Dh-Client-Id`, `X-Dh-Tenant` trên mTLS, SEC-15).

**Phụ thuộc ra.** Kafka (producer idempotent), Apicurio (đọc theo `contentId`), Valkey (khóa chống trùng 24 giờ).

**Dữ liệu.** Không đọc `ph10_event`; cấu hình từ `RuntimeConfigCache`.

**Sự kiện.** Sự kiện nghiệp vụ của HTTT lên topic `{tenant}.*.v{n}`.

**Lỗi và xử lý.** ERR-10-103 (topic không thuộc tenant), ERR-10-104, ERR-10-105 (không khớp lược đồ), ERR-10-108; Kafka không nhận thì 503 kèm `Retry-After`.

**Quan sát.** `dh_event_published_total`, `dh_event_publish_rejected_total{reason}`, `dh_event_publish_duration_seconds`; span `event.publish`.
:::

Chi tiết thiết kế:

`PublishResource` xử lý API-10-079. APISIX đã kiểm token và OPA trước khi tới cổng; cổng không tin tiêu đề do HTTT gửi mà đọc danh tính từ tiêu đề do APISIX ghi lại sau xác thực (`X-Dh-Client-Id`, `X-Dh-Tenant`, chỉ chấp nhận từ mTLS của APISIX, SEC-15). Đường xử lý theo thứ tự (chi tiết sequence §5.3):

1. `TenantGuard` tách tenant từ tiền tố `topicName`, so với `X-Dh-Tenant` (ERR-10-103 khi khác, không lộ topic tồn tại ở tenant khác).
2. `RuntimeConfigCache` tra `RuntimeTopic`: không có, hoặc không `ACTIVE`, `DEPRECATED` thì ERR-10-103.
3. `EnvelopeValidator` kiểm CloudEvents 1.0, `source` thuộc HTTT của client (bảng `source` cho phép đi kèm `RuntimeTopic.publishers[]`), ghi đè `dhtenant`, bổ sung `time`, `traceparent` (ERR-10-104).
4. `SchemaCache` chọn phiên bản theo `dataschema` hoặc phiên bản `ENABLED` mới nhất, kiểm `data` theo lược đồ (ERR-10-105). Đệm lược đồ theo `contentId`, bất biến nên không cần hết hạn; danh sách phiên bản hợp lệ làm mới bằng EVT-10-05, EVT-10-02.
5. `PartitionKeyResolver` lấy khóa theo `routingMode`: `KEY_HASH` đọc `partitionKeyField` (hoặc `ce_subject` khi `$subject`), thiếu khóa khi bắt buộc thì ERR-10-105; `ROUND_ROBIN` khóa rỗng, bộ chia phân vùng mặc định của client; `SINGLE_PARTITION` ghi phân vùng 0.
6. `PublishDeduplicator` đặt `SET NX` khóa `dh:{tenant}:evt:dedup:{publicationCode}:{id}` giá trị `pending`, TTL 24 giờ. Có giá trị `done:{partition}:{offset}` thì trả kết quả cũ; có `pending` trẻ hơn 30 giây thì chờ tối đa 2 giây để lấy kết quả của lượt đang chạy rồi trả `202` với kết quả đó; `pending` cũ hơn 30 giây (lượt trước đã chết giữa chừng) thì ghi lại (chấp nhận khả năng trùng hiếm, bên nhận chống trùng theo `id`, BR-10-009).
7. `TenantProducerPool` ghi với `acks=all`, `enable.idempotence=true`, `max.in.flight.requests.per.connection=5`, `delivery.timeout.ms=10000`. Lỗi `NOT_ENOUGH_REPLICAS` hoặc quá thời gian thì ERR-10-108, xóa khóa chống trùng.
8. Cập nhật khóa chống trùng thành `done:{partition}:{offset}`, trả `202` với `results[]`.

Lô (`application/cloudevents-batch+json`) được kiểm toàn bộ ở bước 3–5 trước khi ghi bất kỳ bản tin nào; ghi bằng một giao dịch Kafka (`transactional.id = dh-gw-{tenant}-{pod}-{n}`) để lô là tất cả hoặc không. Sự kiện đơn không dùng giao dịch để giữ p99 ≤ 50 ms (NFR-10-002). Bản tin trên Kafka theo định dạng §4.9 FRS: tiêu đề `ce_*`, giá trị có tiền tố định danh lược đồ kiểu Confluent (byte 0 và 4 byte `contentId`, ADR-070).

### 4.7. Cổng sự kiện: API kéo có lease và cursor

::: dac-ta
**Mục đích.** Cho HTTT không mở được cổng webhook kéo sự kiện theo lô bằng HTTP, xác nhận hoặc báo lỗi từng sự kiện, với lease để hai tiến trình không kéo trùng và cursor ký để không giả được vị trí.

**Lớp chính.** `PullResource`, `DeadLetterResource`, `LeaseManager`, `CursorCodec`.

**Đơn vị chạy.** `dh-runtime`, vai `gateway`.

**FR hiện thực.** FR-10-043, 044, 052.

**Giao diện vào.** API-10-080…083.

**Phụ thuộc ra.** Kafka consumer theo nhóm của subscription, Valkey (lease).

**Dữ liệu.** Không đọc `ph10_event`; `RuntimeSubscription` từ bộ đệm cấu hình.

**Sự kiện.** Bản tin lỗi vĩnh viễn ghi `{topicName}.dlq`.

**Lỗi và xử lý.** ERR-10-029, ERR-10-108, ERR-10-109 (lease đang giữ), ERR-10-113, ERR-10-121 (cursor sai, hết hạn).

**Quan sát.** `dh_event_pull_requests_total{result}`, `dh_event_dedup_bypass_total`.
:::

Chi tiết thiết kế:

`PullResource` phục vụ API-10-080…082 cho subscription `PULL_API`. Mỗi subscription có tối đa một lease (FR-10-043). Thiết kế:

| Thành phần | Thiết kế |
|---|---|
| Đọc bản tin | Consumer gán phân vùng thủ công (`assign`), `group.id = dh-sub-{tenant}-{subscriptionCode}` chỉ để đọc, ghi offset đã commit; không `subscribe` nên không tái cân bằng giữa các bản sao cổng. `auto.offset.reset=none` (BR-10-022) |
| Lease | Valkey khóa `dh:{tenant}:evt:lease:{subscriptionCode}` gồm `leaseId` (ULID), bản sao giữ lease, vị trí đầu và cuối theo phân vùng, `leaseExpiresAt`; đặt bằng `SET NX PX leaseSeconds` |
| Kéo lặp | Lượt kéo khi lease còn hạn và chưa ack trả lại đúng lô cũ: cổng đọc lại theo khoảng offset ghi trong lease (đọc lại từ Kafka, không giữ lô trong bộ nhớ) |
| Cursor | Chuỗi base64url của `{subscriptionCode, leaseId, offsets{partition: nextOffset}, exp}` kèm HMAC-SHA256 bằng khóa cursor của tenant ở OpenBao `kv/dh/{tenant}/event/runtime/cursor` (FRS A.8); cursor không giả được, không dùng được cho subscription khác |
| Ack | Kiểm chữ ký, `leaseId` khớp lease hiện hành và chưa hết hạn (ERR-10-109); commit offset bằng `commitSync` với `group.id` của subscription (nhóm không có thành viên động nên commit hợp lệ); xóa lease |
| Nack | Các `eventIds[]` được đọc lại theo khoảng của lease, ghi lên `{topicName}.dlq` với `dh_dlq_error_code = ERR-10-113`, `origin` sẽ là `PULL_NACK`; sau khi DLQ xác nhận thì xử lý như ack cả lô |
| Chờ dài | Khi không có bản tin, `poll` lặp tới `waitSeconds` (≤ `10.pull.long-poll-max-seconds`) trên luồng ảo; trả `204` khi hết giờ |
| Định tuyến | Cổng nào nhận yêu cầu thì đọc lease ở Valkey; lease thuộc bản sao khác vẫn phục vụ được vì lô xác định bằng khoảng offset, không phụ thuộc trạng thái trong bộ nhớ |
| Hàng chờ phát lại | Lượt phát lại `REDELIVER_RANGE` cho `PULL_API` ghi danh sách khoảng vào khóa `dh:{tenant}:evt:replayq:{subscriptionCode}`; lượt kéo ưu tiên khoảng này trước bản tin mới (FR-10-052) |

: Cổng sự kiện: API kéo có lease và cursor

Khi Valkey không khả dụng, cổng kéo không cấp được lease nên trả `503` kèm `Retry-After: 5`. Mã lỗi là ERR-10-121 (phụ thuộc runtime không khả dụng, FRS 0.2), khác ERR-10-029 của control plane và ERR-10-108 về bản sao đồng bộ của Kafka. API phát không bị chặn khi Valkey ngừng: `PublishDeduplicator` bỏ qua bước chống trùng (chấp nhận trùng, bên nhận chống trùng theo `id`) và tăng chỉ số `dh_event_dedup_bypass_total`.

### 4.8. Bộ giao nhận webhook

::: dac-ta
**Mục đích.** Giao sự kiện tới webhook của bên nhận kiểu ĐẨY: ký HMAC, giữ thứ tự trong phân vùng, thử lại giãn dần, ngắt mạch khi đầu nhận hỏng và chuyển sự kiện giao không được vào DLQ, không bao giờ mất hay gửi không ký.

**Lớp chính.** `SubscriptionSupervisor`, `SlotAllocator`, `PartitionWorker`, `WebhookRequestBuilder`, `WebhookSigner`, `EgressGuard`, `RetryPolicy`, `SubscriptionBreaker`, `DlqWriter`, `EndpointVerifier`.

**Đơn vị chạy.** `dh-runtime`, vai `dispatcher` (StatefulSet).

**FR hiện thực.** FR-10-036, 038, 039, 040, 042, 046, 048, 049; BR-10-024, 026; ADR-044, 071.

**Giao diện vào.** `RuntimeSubscription` `PUSH` `ACTIVE` từ `RuntimeConfigCache`.

**Phụ thuộc ra.** Webhook HTTPS của HTTT qua egress gateway, OpenBao (đọc khóa ký), Kafka (`{topicName}.dlq`), API-10-086, 119 (báo ngắt mạch).

**Dữ liệu.** Không đọc `ph10_event`.

**Sự kiện.** Bản tin DLQ; báo tạm ngừng qua API nội bộ dẫn tới EVT-10-09.

**Lỗi và xử lý.** ERR-10-111, 112 (tạm thời, thử lại), ERR-10-113 (vĩnh viễn, vào DLQ), ERR-10-114 (TLS), ERR-10-115 (đích bị chặn), ERR-10-116, ERR-10-117 (không đọc được khóa ký thì tạm dừng phân vùng).

**Quan sát.** `dh_event_delivery_total{result}`, `dh_event_delivery_duration_seconds`, `dh_event_delivery_retry_total`, `dh_event_dispatcher_workers`; span `event.deliver`.
:::

Chi tiết thiết kế:

Bộ giao nhận là StatefulSet; mỗi bản sao có số thứ tự `i` trong `N` bản sao. `SubscriptionSupervisor` nạp danh sách `RuntimeSubscription` `PUSH` có `status = ACTIVE` từ `RuntimeConfigCache`, và `SlotAllocator` quyết định bản sao nào chạy worker nào:

- Worker `j` (0 ≤ j < `workerCount`) của subscription `s` chạy ở bản sao `(hash(s) + j) mod N`. Mỗi worker là một consumer tham gia nhóm `dh-sub-{tenant}-{subscriptionCode}` với `partition.assignment.strategy = CooperativeStickyAssignor`, nên Kafka chia phân vùng giữa các worker và đổi `workerCount` chỉ di chuyển phần phân vùng cần thiết (FR-10-046).
- `N` đọc từ chú thích của StatefulSet (Kubernetes API, chỉ đọc) và theo dõi thay đổi; khi KEDA đổi số bản sao, các bản sao tính lại phân bổ, đóng worker không còn thuộc mình sau khi lượt đang giao hoàn tất, rồi mở worker mới.
- Mỗi worker xử lý mỗi phân vùng được gán trên một luồng ảo riêng, tuần tự trong phân vùng (BR-10-025). Bản tin kế tiếp của phân vùng chỉ được giao khi bản tin trước đã thành công hoặc đã vào DLQ.

Đường giao một bản tin (sequence §5.5):

1. Giải tuần tự theo `contentId` của tiền tố bằng `SchemaCache`; lỗi thì ghi DLQ ngay với ERR-10-116, `failureClass = DESERIALIZATION`.
2. `WebhookRequestBuilder` dựng yêu cầu theo `payloadFormat`: `CLOUDEVENTS_STRUCTURED` thân `application/cloudevents+json`; `CLOUDEVENTS_BINARY` tiêu đề `ce-*`, thân là `data` JSON.
3. `WebhookSigner` lấy khóa `ACTIVE` (và `PREVIOUS` trong thời gian chồng lấn) từ đệm khóa ký, tính `HMAC-SHA256(secret, "{Webhook-Id}.{Webhook-Timestamp}.{body}")`, ghi `X-Datahub-Signature: t={ts},v1={hex}[,v1={hex}]`, kèm `Webhook-Id` (= `ce_id`), `Webhook-Timestamp`, `X-Datahub-Subscription`, `X-Datahub-Attempt`, `X-Datahub-Key-Id`, `traceparent`. Không đọc được khóa thì tạm dừng phân vùng, ERR-10-117, không gửi không ký.
4. `EgressGuard` phân giải FQDN, chặn địa chỉ thuộc dải riêng của nền tảng và dải cấm (ERR-10-115), ghim IP đã kiểm cho kết nối này để chống DNS rebinding; client HTTP không theo chuyển hướng, chỉ TLS ≥ 1.2 với kho CA nền tảng (ERR-10-114). Lưu lượng ra đi qua egress gateway (SEC-16).
5. Gửi với thời gian chờ `timeoutMs`. Phân loại kết quả theo bảng §8.5.
6. Thành công: đánh dấu offset đã xử lý; commit theo lô mỗi 1 giây hoặc mỗi 100 bản tin cho từng phân vùng (chỉ offset liên tục đã xong). Thất bại tạm thời: `RetryPolicy`. Thất bại vĩnh viễn hoặc hết lượt: `DlqWriter`.

`RetryPolicy` tính lần chờ thứ k là `min(maxMs, initialMs × multiplier^(k-1))` nhân hệ số ngẫu nhiên 0,8…1,2, dùng `Retry-After` nếu nhỏ hơn `maxMs` (FR-10-039). Trong lúc chờ, worker `pause()` riêng phân vùng đó và tiếp tục `poll()` để giữ tư cách thành viên nhóm (không vượt `max.poll.interval.ms`); các phân vùng khác vẫn chạy. Hết `maxRetries`: `DEAD_LETTER` thì ghi DLQ rồi đi tiếp; `BLOCK` thì gửi lệnh tạm ngừng về control plane (API nội bộ API-10-086 `POST /runtime/subscriptions/{subscriptionCode}:suspend` với `suspendSource = DELIVERY_BLOCKED` và `suspendReason` ghi "đầu nhận lỗi, failurePolicy BLOCK"), dừng mọi worker của subscription, không commit. Trường hợp này không có worker thăm dò tự tiếp tục: FR-10-039 đòi TO khắc phục rồi tiếp tục. Giá trị `DELIVERY_BLOCKED` (FRS A.2.5) phân biệt trường hợp này với ngắt mạch.

`SubscriptionBreaker` đếm theo cửa sổ trượt 1 phút: tỷ lệ lỗi ≥ 50% liên tục trong `10.push.suspend-after-failures-minutes` phút thì báo control plane đặt `SUSPENDED` với `suspendSource = CIRCUIT_BREAKER`. Ở trạng thái này bộ giao nhận vẫn giữ một worker thăm dò: mỗi 5 phút gửi đúng bản tin đầu tiên chưa commit; thành công thì báo control plane đưa về `ACTIVE` (chỉ khi `suspendSource = CIRCUIT_BREAKER`), tiếp tục giao.

`DlqWriter` ghi bản tin gốc nguyên vẹn (khóa, tiêu đề, giá trị nhị phân) lên `{topicName}.dlq` bằng producer `acks=all` với sáu tiêu đề `dh_dlq_*` của Phụ lục A.8, chờ xác nhận rồi mới cho phép commit offset gốc. Ghi DLQ lỗi thì không commit, tạm dừng phân vùng, thử lại mỗi 5 giây, cảnh báo nghiêm trọng (BR-10-024).

### 4.9. Bộ ghi DLQ và kho nội dung

::: dac-ta
**Mục đích.** Biến bản tin trên topic `*.dlq` thành mục DLQ bền trong CSDL để người vận hành tra cứu, loại bỏ hoặc phát lại, kể cả khi topic gốc đã hết hạn lưu giữ; nội dung nhạy cảm được mã hóa.

**Lớp chính.** `DlqIngestor`, `DlqService`, `PayloadVault`, `DlqPurger`, `DlqAlertAggregator`.

**Đơn vị chạy.** `dh-integration`, gói `internal/dlq`.

**FR hiện thực.** FR-10-049, 050, 053; BR-10-023, 024.

**Giao diện vào.** Tiêu thụ topic `^{tenant}\..*\.dlq$` bằng nhóm `dh-svc-dh-integration-{tenant}`; API-10-060…062, 103 (tra cứu, loại bỏ), 064 (phát lại mục DLQ).

**Phụ thuộc ra.** OpenBao transit (mã hóa nội dung topic `RESTRICTED`, `SENSITIVE`).

**Dữ liệu.** `dlq_entry`, `dlq_payload`.

**Sự kiện.** EVT-10-11 (cảnh báo DLQ gộp).

**Lỗi và xử lý.** Ghi lặp không nhân đôi nhờ `uq_dlq_entry_source`; lỗi mã hóa thì không commit offset, thử lại.

**Quan sát.** `dh_event_dlq_entries{status}`.
:::

Chi tiết thiết kế:

`DlqIngestor` trong `dh-integration` tiêu thụ mọi topic `*.dlq` của tenant bằng nhóm `dh-svc-dh-integration-{tenant}` (mẫu nhóm DU của Phụ lục A.8), đăng ký theo mẫu tên `^{tenant}\..*\.dlq$`. Với mỗi bản tin, trong một giao dịch `pg-core`:

1. Tra trùng theo (`subscriptionCode`, `sourceTopic`, `sourcePartition`, `sourceOffset`, `attempts`) trên chỉ mục duy nhất, bỏ qua nếu đã có (tiêu thụ lặp an toàn).
2. Tạo `DlqEntry` `NEW` với `origin` suy từ tiêu đề và đường ghi: bộ giao nhận ghi `PUSH`, cổng kéo ghi `PULL_NACK`, API-10-083 ghi `EXTERNAL_REPORT`, bộ phát lại ghi `REPLAY`, cầu nối ghi `BRIDGE` (FRS A.2.11). Nguồn ghi đặt tiêu đề `dh_dlq_origin` (FRS A.8); mục của cầu nối mang thêm `dh_dlq_bridge` và lưu `bridgeCode`, không có `subscriptionCode`.
3. Ghi nội dung vào `dlq_payload`: topic `PUBLIC`, `INTERNAL` lưu nguyên (`bytea`, mã hóa khi lưu của CNPG, SEC-30); topic `RESTRICTED`, `SENSITIVE` mã hóa phong bì bằng `transit/dh-{tenant}-event-dlq` của OpenBao (SEC-31, SEC-88). `payloadRef` trỏ tới bản ghi nội dung.
4. Ghi outbox gộp: `DlqAlertAggregator` gom theo subscription trong cửa sổ 1 phút rồi phát một EVT-10-11.

Offset của nhóm ingestor chỉ commit sau khi giao dịch xong. Khi `pg-core` ngừng, bản tin nằm chờ trên topic DLQ (lưu giữ `10.dlq.topic-retention-hours`, mặc định 7 ngày, đủ dài hơn mục tiêu phục hồi `pg-core`). `DlqPurger` chạy mỗi đêm: mục `REPLAYED`, `DISCARDED` quá `10.dlq.payload-retention-days-after-resolve` ngày thì xóa `dlq_payload`, đặt `payloadPurgedAt`, chuyển `PURGED`; siêu dữ liệu giữ 1 năm (FRS §8.2).

### 4.10. Thống kê giao nhận và lượt lỗi

::: dac-ta
**Mục đích.** Gom số liệu giao nhận theo phút và lượt lỗi gần đây về control plane để màn hình và cảnh báo có số liệu, mà không thêm topic mới ngoài Phụ lục A.7.

**Lớp chính.** `DeliveryStatsReporter` (runtime), `DeliveryStatIngestor` (control plane).

**Đơn vị chạy.** `dh-runtime` vai `dispatcher`; `dh-integration` gói `internal/stats`.

**FR hiện thực.** FR-10-056.

**Giao diện vào.** API-10-085 `POST /runtime/delivery-reports` mỗi phút.

**Phụ thuộc ra.** Không.

**Dữ liệu.** `delivery_stat` (upsert theo phút), `delivery_failure`.

**Sự kiện.** Không.

**Lỗi và xử lý.** Control plane ngừng thì runtime giữ tối đa một khoảng đệm rồi bỏ, đếm vào `dh_event_stats_dropped_total`; không ảnh hưởng giao nhận.

**Quan sát.** `dh_event_stats_dropped_total`.
:::

Chi tiết thiết kế:

`DeliveryStatsReporter` của bộ giao nhận gộp theo (subscription, phút) trong bộ nhớ và mỗi phút gửi một `DeliveryReport` về control plane. Một topic nội bộ sẽ giữ số liệu tốt hơn khi control plane ngừng, nhưng Phụ lục A.7 không có topic báo cáo giao nhận và tập này không tự đặt topic mới. Vì vậy thiết kế dùng API nội bộ API-10-085 `POST /runtime/delivery-reports` (scope `event:runtime-config`) với đệm 15 phút trong bộ nhớ của bộ giao nhận; quá 15 phút thì bỏ bản cũ nhất và tăng `dh_event_stats_dropped_total` (chỉ số OTLP vẫn đi sang PH-13 nên giám sát không mất). Mã API là API-10-085 (FRS 0.2). Control plane ghi `delivery_stat` (một dòng mỗi subscription mỗi phút, khóa `(subscription_code, window_start)` nên gửi lặp ghi đè cùng giá trị) và `delivery_failure` (lượt lỗi, giữ 30 ngày, `responseSnippet` tối đa 512 byte đã lọc theo bộ che SEC-32).

### 4.11. Bộ phát lại

::: dac-ta
**Mục đích.** Phát lại sự kiện cho một subscription theo khoảng offset hoặc thời gian, hoặc phát lại mục DLQ đã chọn, có duyệt và giới hạn tốc độ để không làm quá tải bên nhận.

**Lớp chính.** `ReplayService`, `RangeResolver`, `ReplayExpirer` (control plane); `ReplayRunner`, `TokenBucket` (runtime).

**Đơn vị chạy.** `dh-integration` gói `internal/replay`; `dh-runtime` vai `dispatcher`.

**FR hiện thực.** FR-10-051, 052, 053; BR-10-028.

**Giao diện vào.** API-10-064, 065, 063, 104 (đề nghị, theo dõi, hủy), API-10-057…059, 101, 102 (duyệt), API-10-087…089 (runtime nhận, báo tiến độ, lấy nội dung).

**Phụ thuộc ra.** Kafka Admin `listOffsets`, consumer riêng của lượt phát lại.

**Dữ liệu.** `replay_request`, `dlq_entry`, `dlq_payload`.

**Sự kiện.** EVT-10-12 (lượt phát lại kết thúc).

**Lỗi và xử lý.** Một lượt chạy mỗi subscription (`uq_replay_request_running`); khoảng đã hết lưu giữ thì từ chối khi đề nghị; hết hạn duyệt thì `ReplayExpirer` hủy.

**Quan sát.** `dh_event_replay_records_total{result}`.
:::

Chi tiết thiết kế:

`ReplayService` ở control plane (FR-10-051, 053) giải khoảng: `RangeResolver` gọi Admin `listOffsets` với `OffsetSpec.forTimestamp` cho `TIME`, kiểm khoảng còn trên cụm bằng `earliest`, `latest`, ước lượng `estimatedRecords` bằng tổng chênh offset (với topic `COMPACT` ghi rõ là cận trên). Lượt `APPROVED` được công bố cho bộ giao nhận qua `RuntimeConfigCache` (mục `replays[]` của API-10-073) và EVT-10-09.

`ReplayRunner` trong bộ giao nhận nhận lượt bằng khóa Valkey `dh:{tenant}:evt:replay:{replayCode}` (một bản sao chạy một lượt) rồi báo control plane chuyển `RUNNING`:

| `replayMode` | Cách chạy |
|---|---|
| `REDELIVER_RANGE` | Consumer `assign` các phân vùng của khoảng, không tham gia nhóm của subscription (nhóm `dh-replay-{tenant}-{replayCode}` chỉ để định danh, không commit); giao như §4.8 với `X-Datahub-Replay: {replayCode}` và cùng `Webhook-Id` như lần đầu; `TokenBucket` giới hạn `ratePerSecond`; lỗi cuối vào DLQ với `origin = REPLAY` và `replayCode`. Với `PULL_API` ghi khoảng vào hàng chờ phát lại (§4.7) |
| `RESET_OFFSET` | Control plane (không phải bộ giao nhận) chạy: kiểm subscription vẫn `PAUSED`, đọc vị trí hiện tại ghi vào `previousOffsets`, gọi Admin `alterConsumerGroupOffsets`, chuyển `COMPLETED`; TO tiếp tục subscription |
| `DLQ_ENTRIES` | `ReplayRunner` gọi API nội bộ API-10-089 lấy nội dung theo lô 100 mục (`event:replay`), giao từ nội dung đã lưu, báo kết quả từng mục; control plane chuyển mục `REPLAY_PENDING` sang `REPLAYED` hoặc về `NEW` với `attempts` tăng |

: Bộ phát lại

Tiến độ (`deliveredRecords`, `failedRecords`) báo mỗi 5 giây. Hủy (`PERM-10-operate`) đặt cờ trong cấu hình runtime; `ReplayRunner` dừng sau bản tin đang giao. Lượt `APPROVED` quá 24 giờ chưa chạy bị `ReplayExpirer` chuyển `CANCELLED`.

### 4.12. Cấu hình runtime và chạy khi control plane ngừng

::: dac-ta
**Mục đích.** Giữ cho cổng sự kiện và bộ giao nhận chạy tiếp khi `dh-integration` hoặc `pg-core` ngừng, bằng bản cấu hình đệm cục bộ có phiên bản, cập nhật theo chu kỳ và theo sự kiện.

**Lớp chính.** `RuntimeConfigClient`, `RuntimeConfigCache`.

**Đơn vị chạy.** `dh-runtime`, cả hai vai.

**FR hiện thực.** FR-10-013, 033, 038, 043; NFR-10-013; ADR-071.

**Giao diện vào.** API-10-073 mỗi 30 giây và khi nhận EVT-10-02, 05, 08, 09, 13.

**Phụ thuộc ra.** Valkey (ảnh chụp cấu hình), Caffeine trong bộ nhớ.

**Dữ liệu.** `RuntimeTopic`, `RuntimeSubscription` không chứa bí mật; khóa ký đọc thẳng OpenBao.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** Mất kết nối control plane thì dùng bản đệm, cảnh báo khi tuổi cấu hình vượt ngưỡng; không có bản đệm khi khởi động thì không nhận lưu lượng.

**Quan sát.** `dh_event_runtime_config_age_seconds{role}`.
:::

Chi tiết thiết kế:

`RuntimeConfigClient` của `dh-runtime` gọi API-10-073 (`GET /runtime/subscriptions?since={configVersion}`) mỗi 30 giây và ngay khi nhận EVT-10-02, 05, 08, 09, 13 (tiêu thụ bằng nhóm `dh-svc-dh-runtime-{tenant}`). Phản hồi gồm `RuntimeTopic`, `RuntimeSubscription`, lượt phát lại `APPROVED`, danh sách `source` hợp lệ theo publication. `RuntimeConfigCache` giữ trong bộ nhớ và ghi ảnh chụp nén vào Valkey `dh:{tenant}:evt:runtime-config` sau mỗi lần làm mới thành công. Khi khởi động, bản sao đọc ảnh chụp trước rồi mới gọi API; khi API lỗi, cổng và bộ giao nhận chạy tiếp với ảnh chụp, chỉ số `dh_event_runtime_config_age_seconds` tăng và cảnh báo sau 10 phút. Không có thay đổi khai báo nào có hiệu lực trong thời gian này, đúng NFR-10-013 và NFR-00-012.

Khóa ký đọc trực tiếp OpenBao bằng xác thực Kubernetes của ServiceAccount `dh-runtime-event` trong `dh-rt-{tenant}`, chính sách chỉ `read` trên `kv/dh/{tenant}/event/subscriptions/*`; đệm trong bộ nhớ 10 phút, làm mới khi nhận EVT-10-13 (SEC-33). Khi OpenBao ngừng, khóa trong đệm vẫn dùng tới khi hết hạn đệm; sau đó phân vùng tạm dừng với ERR-10-117 (không bao giờ gửi không ký).

### 4.13. Bộ thu lag và cảnh báo

::: dac-ta
**Mục đích.** Đo độ trễ tiêu thụ của mọi subscription, lưu mẫu để vẽ xu hướng và phát cảnh báo khi bên nhận chậm hoặc nhóm tiêu thụ ngừng tiến.

**Lớp chính.** `LagCollector` (ShedLock), `AlertEvaluator`, `LagSampleRollup`.

**Đơn vị chạy.** `dh-integration`, gói `internal/lag`.

**FR hiện thực.** FR-10-054, 055.

**Giao diện vào.** Tác vụ định kỳ mỗi `10.lag.collect-interval-seconds` giây theo tenant.

**Phụ thuộc ra.** Kafka Admin API (offset nhóm, offset cuối).

**Dữ liệu.** `lag_sample` (phân vùng ngày), `lag_sample_5m`, `subscription` (trạng thái cảnh báo).

**Sự kiện.** EVT-10-10 (cảnh báo lag `WARNING`, `CRITICAL`, `STALLED`).

**Lỗi và xử lý.** Kafka Admin không phản hồi thì bỏ chu kỳ, không phát cảnh báo sai.

**Quan sát.** `dh_event_consumer_lag_records`, `dh_event_consumer_lag_seconds`.
:::

Chi tiết thiết kế:

`LagCollector` (khóa ShedLock, một bản sao mỗi DU) mỗi `10.lag.collect-interval-seconds` giây, theo từng tenant:

1. Liệt kê subscription `ACTIVE`, `PAUSED`, `SUSPENDED` cùng `consumerGroup`.
2. Gọi Admin `listConsumerGroupOffsets` theo lô 50 nhóm và `listOffsets(latest)` cho các phân vùng liên quan.
3. Tính `lagRecords` theo phân vùng. Với phân vùng có `lagRecords > 0`, lấy thời điểm của bản tin tại offset đã commit bằng một consumer `assign` đọc một bản tin (`max.poll.records = 1`, `fetch.max.bytes` nhỏ) để tính `lagSeconds`; phân vùng không lag có `lagSeconds = 0`. Chỉ đọc khi lag đổi so với chu kỳ trước để giảm tải (Q10-25).
4. Ghi `lag_sample` theo lô, xuất `dh_event_consumer_lag_records`, `dh_event_consumer_lag_seconds`.
5. `AlertEvaluator` tính `alertState` theo FR-10-055 (`WARNING` cần hai chu kỳ liên tiếp; `CRITICAL` khi vượt `lagCriticalSeconds` hoặc thời gian còn lại trước hết lưu giữ dưới 24 giờ; `STALLED` khi offset đã commit không đổi trong `10.lag.stalled-minutes` phút ở `ACTIVE`). Đổi mức thì ghi trạng thái và EVT-10-10 trong một giao dịch.

`LagSampleRollup` mỗi 5 phút gộp mẫu 30 giây, giữ mẫu gốc 48 giờ và bản gộp 90 ngày (FRS §8.2) bằng phân vùng bảng theo ngày (chi tiết ở D03-03-PH10).

### 4.14. Đăng ký máy với máy

::: dac-ta
**Mục đích.** Cho PH-05, PH-04 và DU nội bộ đăng ký topic, bên tham gia và quyền bằng máy, idempotent, tự duyệt khi đủ điều kiện, để luồng CDC và luồng tích hợp không phải chờ thao tác tay.

**Lớp chính.** `TopicRegistrationService`, `AutoApprovalPolicy`, `CdcSchemaChangeConsumer`, `PartySyncConsumer`, `PartyReconciler`, `EventPermissionApi`.

**Đơn vị chạy.** `dh-integration`, gói `internal/machine`, `api`.

**FR hiện thực.** FR-10-029, 066, 067, 068, 069; BR-10-031.

**Giao diện vào.** `TopicRegistrationApi`, `EventPermissionApi` (trong tiến trình); API-10-071, 072, 109; EVT-05-11 từ PH-05.

**Phụ thuộc ra.** Như §4.3, §4.4 (lược đồ, cấp phát).

**Dữ liệu.** `topic`, `publisher`, `subscriber`, `publication`, `subscription`, `approval_request`.

**Sự kiện.** EVT-10-01 khi topic đăng ký bằng máy sang `ACTIVE`; EVT-10-03 khi thay đổi phá vỡ của CDC làm topic cũ `DEPRECATED`.

**Lỗi và xử lý.** ERR-10-002 (cùng tên khác cấu hình), ERR-10-016; trùng cấu hình trả trạng thái hiện tại với 200.

**Quan sát.** Kiểm toán ghi `decided_by = system:auto` khi tự duyệt.
:::

Chi tiết thiết kế:

`TopicRegistrationService` phục vụ PH-05 và DU nội bộ (FR-10-066, 067). Idempotent theo `topicName`: đã có cùng cấu hình thì trả trạng thái hiện tại với `200`; khác cấu hình thì ERR-10-002. `AutoApprovalPolicy` quyết định tự duyệt khi đồng thời: chủ thể là tài khoản dịch vụ có `event:topic-register`; `topicKind` là `CDC` hoặc `SYSTEM`; `10.approval.auto-approve-machine = true` (BR-10-031). Tự duyệt vẫn tạo `ApprovalRequest` `APPROVED` với `autoApproved = true`, `decidedBy = system:auto`, `requestedBy` là tài khoản dịch vụ và chú thích `onBehalfOf`. Cùng giao dịch tạo publication `ACTIVE` cho bên phát `INTERNAL_SERVICE` của `dh-cdc` (topic CDC) hoặc của DU chủ quản (topic `SYSTEM`) theo `10.approval.auto-approve-internal`. Phần ghi Apicurio và Git chạy bất đồng bộ trong `ProvisioningWorker` sau khi giao dịch commit, nên lời gọi trả `202` trong ≤ 2 giây (PH-05 chờ tối đa 5 giây).

`CdcSchemaChangeConsumer` tiêu thụ EVT-05-11 qua inbox (§8.3). Thay đổi tương thích: chờ PH-05 gửi phiên bản qua `registerSchemaVersion`, tự duyệt khi đạt mức tương thích của topic, ngược lại trả ERR-10-016. Thay đổi phá vỡ được chấp nhận ở PH-05: `newMajorVersion` tạo topic `.v{n+1}` tự duyệt, đặt topic cũ `DEPRECATED` với `successorTopic`, `sunsetAt` theo `10.topic.deprecation-days`, phát EVT-10-03 và thông báo đầu mối các subscription (FR-10-068).

`PartySyncConsumer` tiêu thụ EVT-01-03 của PH-01 và EVT-04-09. Sự kiện HTTT tạm ngừng: mọi publisher, subscriber gắn `systemCode` sang `SUSPENDED` với `suspendSource = PH01`, kéo theo publication, subscription của chúng sang `SUSPENDED` cùng nguồn, gỡ dữ liệu OPA trước (hiệu lực ≤ 60 giây, NFR-10-009) rồi mới ghi Git gỡ ACL. HTTT `ACTIVE` lại: chỉ tiếp tục đối tượng có `suspendSource = PH01`. `PartyReconciler` mỗi giờ so toàn bộ với bản sao đọc của PH-01 và danh sách luồng PH-04 để bù sự kiện lỡ.

`TenantBootstrapper` tiêu thụ EVT-20-01 `platform.tenant.created.v1` và EVT-20-04 `platform.tenant.status-changed.v1` của PH-20 qua inbox (§8.3): khử trùng theo `ce_id`, tạo hạn mức mặc định, principal nội bộ, ACL tiền tố và topic hệ thống của tenant mới (FR-10-064, 067), rồi gọi API-20-166 báo bước `S06_EVENTING` (thử lại có lũy đẳng nếu PH-20 chưa nhận). Cùng cơ chế đăng ký, DU của PH-06 (`{tenant}.mdm.*`, 15 topic), PH-08 (`dq`, 14), PH-11 (`bpm`, 21), PH-16 (`kpi`, 14), PH-13 (`obs`) và PH-15 (`portal`) khai báo topic miền trong gói triển khai; PH-06 phát qua Debezium Outbox Event Router trên `ph06_mdm.outbox_event`, cùng mẫu với PH-04, PH-05. Các topic miền này thuộc miền dành riêng nên chỉ nhận đăng ký máy.

### 4.15. Sơ đồ kết nối và dashboard

::: dac-ta
**Mục đích.** Dựng sơ đồ kết nối HTTT, topic, bên nhận và dashboard sự kiện của tenant từ khai báo và số liệu đo, để người vận hành thấy luồng dữ liệu và điểm nghẽn.

**Lớp chính.** `GraphBuilder`, `DashboardQuery`.

**Đơn vị chạy.** `dh-integration`, gói `internal/stats`.

**FR hiện thực.** FR-10-057, 058, 059.

**Giao diện vào.** API-10-007 (sơ đồ), API-10-066 (dashboard).

**Phụ thuộc ra.** PH-13 (truy vấn Prometheus qua API).

**Dữ liệu.** `publication`, `subscription`, `topic`, `delivery_stat`, `lag_sample_5m`, `dlq_entry`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-10-049 (tham số lọc sai miền); PH-13 không phản hồi thì trả sơ đồ không có lớp lưu lượng kèm cờ thiếu số liệu.

**Quan sát.** Span `event.graph.build`.
:::

Chi tiết thiết kế:

`GraphBuilder` (API-10-007) dựng đồ thị bằng ba truy vấn theo tenant và bộ lọc (publication với bên phát, subscription với bên nhận, topic), gộp nút HTTT xuất hiện ở cả hai phía, gắn chỉ số phủ theo `overlay`: `LAG` từ mẫu lag mới nhất, `TRAFFIC` từ `delivery_stat` 15 phút và tốc độ vào từ PH-13 (truy vấn Prometheus qua API của PH-13, có thể trống), `DLQ` từ đếm mục `NEW`. Đếm nút trước khi dựng; vượt `10.graph.max-nodes` trả ERR-10-049. Bố cục ELK làm ở trình duyệt, máy chủ chỉ trả `nodes[]`, `edges[]`. `DashboardQuery` (API-10-066) đọc bảng tổng hợp làm mới mỗi phút (`MATERIALIZED VIEW` theo tenant, đề nghị ở D03-03-PH10) cho bốn số đếm thay LGC-HUB-001…004 và liên kết sang bảng chỉ số cụm của PH-13 thay LGC-HUB-005, 006.

### 4.16. Di trú từ Pulsar

::: dac-ta
**Mục đích.** Đưa Hub Pulsar cũ sang Kafka từng topic một: nhập kiểm kê, lập ánh xạ, chạy cầu nối hai chiều có hạn dùng, đối chiếu và chuyển hẳn, có cửa sổ quay lui.

**Lớp chính.** `PulsarInventoryImporter`, `LegacyMapping`, `BridgeFlowRenderer`, `BridgeMonitor`, `MigrationReconciler`, `CutOverService`.

**Đơn vị chạy.** `dh-integration` gói `internal/migration`; cầu nối chạy hồ sơ `legacy-jvm` của `dh-runtime`.

**FR hiện thực.** FR-10-072…076; BR-10-033; ADR-073.

**Giao diện vào.** API-10-075…078, 112…118 (control plane), API-10-090 (runtime báo trạng thái cầu nối).

**Phụ thuộc ra.** Pulsar Admin API (chỉ đọc kiểm kê), Kamelet `dh-pulsar-bridge-source`, `dh-pulsar-bridge-sink`.

**Dữ liệu.** `manifest_import_job`, `legacy_mapping`, `migration_bridge`.

**Sự kiện.** EVT-10-15 (chuyển hẳn, quay lui), EVT-10-16 (cầu nối đổi trạng thái).

**Lỗi và xử lý.** ERR-10-042 (đã có cầu nối trên cặp topic), ERR-10-118 (cầu nối lỗi); hết hạn dùng thì cầu nối `EXPIRED`.

**Quan sát.** `dh_event_bridge_lag_seconds`, `dh_event_bridge_messages_total{bridge}`.
:::

Chi tiết thiết kế:

| Thành phần | Trách nhiệm |
|---|---|
| `PulsarInventoryImporter` | Đọc tệp kiểm kê Hub cũ (`sourceKind = PULSAR_HUB`) trong `ManifestImportJob`, sinh `LegacyMapping` `PROPOSED` với `confidence`, `issues`; ánh xạ loại subscription Pulsar theo Phụ lục A.2.14 |
| `BridgeFlowRenderer` | Khi cầu nối được duyệt (yêu cầu `BRIDGE`), sinh định nghĩa luồng Camel dùng Kamelet `dh-pulsar-bridge-source` (chiều `PULSAR_TO_KAFKA`) hoặc `dh-pulsar-bridge-sink` (chiều `KAFKA_TO_PULSAR`), commit vào kho luồng của tenant theo quy trình triển khai luồng của PH-04 với hồ sơ `legacy-jvm` |
| Kamelet `dh-pulsar-bridge-source` | Subscription Pulsar `Failover` tên `pulsarSubscriptionName`; dựng CloudEvents với `id` từ `messageId`, `source = /legacy-hub/{pulsarTopic}`; chuyển nội dung theo lược đồ đích; ghi Kafka `acks=all` với principal `User:CN=dh-runtime-{tenant}`; ack Pulsar sau khi Kafka xác nhận; lỗi chuyển nội dung ghi DLQ với ERR-10-118, `origin = BRIDGE` |
| Kamelet `dh-pulsar-bridge-sink` | Tiêu thụ topic Kafka với nhóm `dh-bridge-{tenant}-{bridgeCode}`, bỏ phong bì, ghi Pulsar theo định dạng cũ |
| `BridgeMonitor` | Đọc chỉ số của luồng cầu nối (`bridgedCount`, `lagSeconds`, `lastPulsarMessageId`) mỗi 30 giây, cập nhật `migration_bridge`; vượt `10.migration.bridge-max-lag-seconds` thì cảnh báo; `expiresAt` tới thì dừng (`EXPIRED`) |
| `MigrationReconciler` | Mỗi giờ so số bản tin theo khoảng giờ giữa Pulsar (`stats` qua Admin REST của Pulsar) và Kafka (đếm bản tin có `source` cầu nối, dựa trên `DeliveryStat` của luồng cầu nối), so mẫu 100 `id`; lưu báo cáo ở kho đối tượng `dh-event-import/{tenant}/reconcile/{bridgeCode}/{yyyyMMddHH}.json` (FRS A.8), cảnh báo khi chênh khác 0 sau khi trừ lag |
| `CutOverService` | Kiểm điều kiện FR-10-075, dừng cầu nối, chuyển ánh xạ `CUT_OVER`, phát EVT-10-15; quay lui bật lại cầu nối chiều cũ, ánh xạ sang `ROLLED_BACK`; hết `10.migration.rollback-window-days` thì `CLOSED` |

: Di trú từ Pulsar

Ràng buộc không hai chiều cùng lúc (BR-10-033) kiểm bằng chỉ mục duy nhất một phần trên `migration_bridge (tenant_id, pulsar_topic, kafka_topic) WHERE status = 'RUNNING'` cộng kiểm ở dịch vụ khi tạo chiều ngược (ERR-10-042).

### 4.17. Xuất, nhập khai báo

::: dac-ta
**Mục đích.** Xuất khai báo của một dự án thành YAML để chuyển môi trường hay lưu hồ sơ, và nhập lại có xem trước, chỉ tạo đối tượng ở trạng thái chờ duyệt.

**Lớp chính.** `ManifestExporter`, `ManifestImportJob`.

**Đơn vị chạy.** `dh-integration`, gói `internal/exchange`.

**FR hiện thực.** FR-10-070, 071; BR-10-027, 032.

**Giao diện vào.** API-10-074 (xuất), API-10-075, 110, 111, 121 (nhập, xem trước, áp dụng, hủy).

**Phụ thuộc ra.** Kho đối tượng (tệp YAML).

**Dữ liệu.** `manifest_import_job` và các bảng khai báo.

**Sự kiện.** Không.

**Lỗi và xử lý.** Dòng `CONFLICT` chặn áp dụng tới khi người dùng chọn cách xử lý; tệp chứa bí mật bị từ chối (BR-10-027).

**Quan sát.** Kiểm toán lệnh xuất, nhập, áp dụng.
:::

Chi tiết thiết kế:

`ManifestExporter` (FR-10-070) xuất YAML theo dự án gồm dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription; không bao giờ chứa bí mật ký, `clientId` chỉ là tham chiếu (BR-10-027). `ManifestImportJob` (FR-10-071, Đợt sau) đi qua `VALIDATING`, `PREVIEW`, `APPLYING`, `APPLIED` hoặc `FAILED`, `CANCELLED`; mỗi dòng xem trước có `changeKind` `CREATE`, `UPDATE`, `UNCHANGED`, `CONFLICT`, `SKIP`; áp dụng chỉ tạo đối tượng ở trạng thái chờ duyệt, không bao giờ `ACTIVE` trực tiếp (BR-10-032).

## 5. Biểu đồ tuần tự

### 5.1. Tạo topic có duyệt và cấp phát (FR-10-008, 009, 010)

```{.mermaid caption="Tạo topic có duyệt và cấp phát (FR-10-008, 009, 010)"}
sequenceDiagram
  actor IE as IE
  actor IA as IA
  participant API as event.web
  participant SVC as TopicService
  participant APC as Apicurio
  participant GIT as dh-config-tenant
  participant STZ as Argo CD, Strimzi
  participant REC as ProvisioningReconciler
  IE->>API: POST /topics (submit=true, Idempotency-Key)
  API->>SVC: tạo topic
  SVC->>APC: kiểm lược đồ dryRun
  APC-->>SVC: hợp lệ, báo cáo tương thích
  SVC->>SVC: Topic PENDING_APPROVAL, ApprovalRequest TOPIC_CREATE PENDING
  API-->>IE: 201 kèm approvalRequestCode
  IA->>API: POST /approval-requests/{requestCode}:approve
  API->>SVC: FourEyesGuard, kiểm lại hạn mức và tên
  SVC->>APC: tạo artifact groupId tenant, quy tắc, phiên bản 1
  APC-->>SVC: globalId, contentId
  SVC->>GIT: commit KafkaTopic topic và DLQ
  GIT-->>SVC: commit hash
  SVC->>SVC: Topic PROVISIONING, SchemaVersion ENABLED, outbox EVT-10-05
  STZ->>GIT: đồng bộ
  REC->>STZ: đọc status.conditions mỗi 10 giây
  STZ-->>REC: Ready=True
  REC->>SVC: Topic ACTIVE, outbox EVT-10-01
```

Ghi Apicurio và commit Git nằm ngoài giao dịch CSDL. Commit Git lỗi sau khi artifact đã tạo thì dịch vụ xóa bù artifact, trả ERR-10-029 và yêu cầu vẫn `PENDING` (FR-10-009). Strimzi không báo `Ready` trong `10.provisioning.timeout-minutes` phút thì topic `FAILED` với `provisioningError`; thử lại (API-10-013) sinh commit mới, hủy (API-10-014) đưa topic về `DRAFT`.

### 5.2. Đăng ký phiên bản lược đồ (FR-10-017, 018, 019)

```{.mermaid caption="Đăng ký phiên bản lược đồ (FR-10-017, 018, 019)"}
sequenceDiagram
  actor IE as IE
  actor IA as IA
  participant API as event.web
  participant SCH as SchemaService
  participant APC as Apicurio
  participant RT as dh-runtime
  IE->>API: POST /topics/{topicName}/schema/versions
  API->>SCH: SchemaVersion DRAFT, contentHash
  IE->>API: POST .../versions/{versionNo}:submit
  SCH->>APC: thêm phiên bản dryRun
  APC-->>SCH: tương thích hoặc danh sách vi phạm
  SCH->>SCH: kiểm partitionKeyField, PiiScanner
  SCH->>SCH: PENDING_APPROVAL, ApprovalRequest SCHEMA_VERSION
  IA->>API: approve
  SCH->>APC: dryRun lần cuối rồi thêm phiên bản thật
  APC-->>SCH: globalId, contentId
  SCH->>SCH: SchemaVersion ENABLED và outbox EVT-10-05 cùng giao dịch
  SCH-->>RT: EVT-10-05 qua Kafka
  RT->>RT: làm mới danh sách phiên bản hợp lệ
```

Kiểm tra chạy lại khi duyệt vì phiên bản khác có thể đã bật trong lúc chờ. Không đạt mức tương thích trả ERR-10-016 kèm `compatibilityReport`; giao diện hướng dẫn tạo phiên bản topic mới (API-10-018). Phiên bản đã có ở Apicurio mà ghi CSDL lỗi thì `SchemaCompensator` xử lý theo §4.3.

### 5.3. Phát sự kiện qua API (FR-10-033)

```{.mermaid caption="Phát sự kiện qua API (FR-10-033)"}
sequenceDiagram
  participant H as HTTT phát
  participant AX as APISIX, OPA
  participant GW as event-gateway
  participant VK as Valkey
  participant K as Kafka
  H->>AX: POST /event/v1/topics/{topicName}/events
  AX->>AX: token, scope publish, dữ liệu OPA, limit-count
  AX->>GW: chuyển tiếp kèm X-Dh-Client-Id, X-Dh-Tenant qua mTLS
  GW->>GW: TenantGuard, topic ACTIVE hoặc DEPRECATED
  GW->>GW: kiểm phong bì, kiểm data theo lược đồ, tính khóa
  GW->>VK: SET NX khóa chống trùng pending
  VK-->>GW: mới
  GW->>K: produce acks=all, idempotent
  K-->>GW: partition, offset
  GW->>VK: khóa chống trùng done
  GW-->>H: 202 results
```

APISIX từ chối với ERR-10-101, 102, 107; cổng từ chối với ERR-10-103…106, 108. Lỗi `NOT_ENOUGH_REPLICAS` làm cổng xóa khóa chống trùng để lượt gửi lại được ghi (BR-10-007).

### 5.4. Subscription PUSH: xác minh, duyệt, cấp phát (FR-10-035, 036, 037, 040, 042)

```{.mermaid caption="Subscription PUSH: xác minh, duyệt, cấp phát (FR-10-035, 036, 037, 040, 042)"}
sequenceDiagram
  actor IE as IE
  actor IA as IA
  participant API as event.web
  participant SUB as SubscriptionService
  participant DSP as event-dispatcher
  participant EP as Endpoint HTTT
  participant BAO as OpenBao
  participant ADM as Kafka Admin
  IE->>API: POST /endpoint-verifications
  API->>DSP: yêu cầu xác minh
  DSP->>EP: OPTIONS, WebHook-Request-Origin
  EP-->>DSP: 200, WebHook-Allowed-Origin
  DSP-->>API: PASSED, endpointVerifiedAt
  IE->>API: POST /subscriptions deliveryMode PUSH
  API->>SUB: kiểm tổ hợp, workerCount, startAt, ApprovalRequest SUBSCRIPTION
  IA->>API: approve
  SUB->>SUB: PROVISIONING
  SUB->>BAO: ghi khóa ký, chính sách chỉ ghi
  SUB->>ADM: alterConsumerGroupOffsets theo startPosition
  ADM-->>SUB: đã đặt vị trí
  SUB->>SUB: ACTIVE, outbox EVT-10-08
  API-->>IE: bí mật ký hiển thị một lần
  DSP->>API: GET /runtime/subscriptions
  DSP->>DSP: SlotAllocator mở worker
```

Vị trí đọc đặt bằng Admin API trước khi worker đầu tiên tham gia nhóm nên không đua với `auto.offset.reset` (BR-10-022). Endpoint xác minh quá 24 giờ khi duyệt trả ERR-10-027. Bước nào lỗi thì subscription `FAILED`; các bước đã xong ghi ở `ApprovalRequest.checks` để thử lại không lặp.

### 5.5. Giao PUSH có ký, thử lại và DLQ (FR-10-038, 039, 049)

```{.mermaid caption="Giao PUSH có ký, thử lại và DLQ (FR-10-038, 039, 049)"}
sequenceDiagram
  participant K as Kafka
  participant W as PartitionWorker
  participant EP as Endpoint HTTT
  participant DLQ as topic .dlq
  participant ING as DlqIngestor
  participant PG as ph10_event
  K->>W: poll bản tin offset n
  W->>W: giải tuần tự, dựng CloudEvents, ký HMAC, ghim IP
  W->>EP: POST, X-Datahub-Attempt 1
  EP-->>W: 503
  W->>W: pause phân vùng, chờ giãn dần
  W->>EP: POST, X-Datahub-Attempt 2
  EP-->>W: 503
  Note over W: hết maxRetries, failurePolicy DEAD_LETTER
  W->>DLQ: bản tin gốc và tiêu đề dh_dlq, acks=all
  DLQ-->>W: xác nhận
  W->>K: commit offset n
  DLQ->>ING: tiêu thụ
  ING->>PG: DlqEntry NEW, dlq_payload, outbox EVT-10-11 gộp 1 phút
```

Offset `n` chỉ commit sau khi topic DLQ xác nhận (BR-10-024). Với `BLOCK`, bước ghi DLQ thay bằng lệnh tạm ngừng subscription, không commit, nên bản tin được giao lại từ vị trí cũ khi TO tiếp tục.

### 5.6. Kéo PULL_API có lease và cursor (FR-10-043)

```{.mermaid caption="Kéo PULL_API có lease và cursor (FR-10-043)"}
sequenceDiagram
  participant H as HTTT nhận
  participant AX as APISIX, OPA
  participant GW as event-gateway
  participant VK as Valkey
  participant K as Kafka
  H->>AX: GET /event/v1/subscriptions/{code}/events?max=100&waitSeconds=20
  AX->>GW: scope subscribe, client khớp bên nhận
  GW->>VK: đọc lease
  VK-->>GW: không có
  GW->>K: assign, seek offset đã commit, poll
  K-->>GW: 100 bản tin
  GW->>VK: SET NX lease kèm khoảng offset, PX leaseSeconds
  GW-->>H: 200 events, cursor ký, leaseExpiresAt
  H->>AX: POST .../events:ack với cursor
  AX->>GW: chuyển tiếp
  GW->>GW: kiểm HMAC cursor, leaseId
  GW->>K: commitSync offset theo phân vùng
  GW->>VK: xóa lease
  GW-->>H: 204
```

Kéo lại khi lease còn hạn trả đúng lô cũ bằng cách đọc lại khoảng offset của lease. Lease hết hạn chưa ack thì lô trả ở lượt kéo sau. Cursor sai hoặc của lease cũ trả ERR-10-109.

### 5.7. Phát lại mục DLQ (FR-10-051, 052, 053)

```{.mermaid caption="Phát lại mục DLQ (FR-10-051, 052, 053)"}
sequenceDiagram
  actor TO as TO
  actor IA as IA
  participant API as event.web
  participant RPL as ReplayService
  participant DSP as ReplayRunner
  participant EP as Endpoint HTTT
  TO->>API: POST /replays replayMode DLQ_ENTRIES, dlqEntryIds, reason
  API->>RPL: kiểm mục NEW, ERR-10-035, ước lượng
  RPL->>RPL: ReplayRequest PENDING_APPROVAL, ApprovalRequest REPLAY
  IA->>API: approve
  RPL->>RPL: APPROVED, mục DLQ sang REPLAY_PENDING
  DSP->>API: nhận việc, RUNNING
  loop lô 100 mục, giới hạn ratePerSecond
    DSP->>API: lấy nội dung mục bằng scope event:replay
    DSP->>EP: POST, X-Datahub-Replay, cùng Webhook-Id
    EP-->>DSP: 2xx hoặc lỗi
    DSP->>API: báo kết quả từng mục
    API->>RPL: REPLAYED hoặc NEW với attempts tăng
  end
  RPL->>RPL: COMPLETED hoặc FAILED, outbox EVT-10-12
```

`REDELIVER_RANGE` theo cùng khung nhưng đọc topic gốc bằng consumer `assign`. `RESET_OFFSET` không qua bộ giao nhận: `ReplayService` đặt vị trí nhóm bằng Admin API khi subscription còn `PAUSED` và lưu `previousOffsets` để hoàn tác.

### 5.8. CDC hộ PH-05, tự duyệt (FR-10-066, 068)

```{.mermaid caption="CDC hộ PH-05, tự duyệt (FR-10-066, 068)"}
sequenceDiagram
  participant P5 as PH-05 adapter
  participant REG as TopicRegistrationService
  participant PW as ProvisioningWorker
  participant APC as Apicurio
  participant GIT as dh-config-tenant
  participant REC as ProvisioningReconciler
  P5->>REG: register topicKind CDC, onBehalfOf, sourceRef
  REG->>REG: scope event:topic-register, tiền tố, idempotent theo topicName
  REG->>REG: AutoApprovalPolicy đạt, ApprovalRequest APPROVED autoApproved
  REG->>REG: Topic PROVISIONING, Publication ACTIVE cho dh-cdc
  REG-->>P5: 202 PROVISIONING
  PW->>APC: artifact và phiên bản 1
  PW->>GIT: commit KafkaTopic
  REC->>REC: Ready, Topic ACTIVE, EVT-10-01
  Note over P5,REC: sau đó lược đồ nguồn đổi tương thích
  P5->>REG: registerSchemaVersion
  REG->>APC: dryRun
  APC-->>REG: tương thích
  REG->>REG: SchemaVersion ENABLED tự duyệt, EVT-10-05
```

Tự duyệt tắt thì yêu cầu vào hộp việc của IA; PH-05 vẫn nhận `202` với `PENDING_APPROVAL`. Lược đồ không tương thích trả ERR-10-016 để PH-05 dừng CDC và xử lý như thay đổi phá vỡ.

### 5.9. Cầu nối Pulsar và chuyển hẳn (FR-10-073, 075)

```{.mermaid caption="Cầu nối Pulsar và chuyển hẳn (FR-10-073, 075)"}
sequenceDiagram
  actor TA as TA
  actor IA as IA
  participant MIG as MigrationService
  participant RT as dh-runtime legacy-jvm
  participant PS as Pulsar cũ
  participant K as Kafka
  participant RC as MigrationReconciler
  TA->>MIG: POST /migrations/bridges PULSAR_TO_KAFKA
  MIG->>MIG: ánh xạ PLANNED, kiểm ERR-10-042, ApprovalRequest BRIDGE
  IA->>MIG: approve
  MIG->>MIG: Publisher LEGACY_BRIDGE, Publication tự duyệt
  MIG->>RT: triển khai luồng cầu nối
  RT->>PS: subscribe Failover dh-bridge
  PS-->>RT: bản tin
  RT->>K: produce CloudEvents acks=all
  K-->>RT: xác nhận
  RT->>PS: ack
  MIG->>MIG: MigrationBridge RUNNING, LegacyMapping BRIDGING
  loop mỗi giờ
    RC->>PS: stats theo khoảng giờ
    RC->>K: đếm theo source cầu nối
    RC->>MIG: báo cáo chênh lệch
  end
  TA->>MIG: cut-over, IA duyệt CUTOVER
  MIG->>RT: dừng cầu nối
  MIG->>MIG: LegacyMapping CUT_OVER, EVT-10-15
```

Ack Pulsar chỉ sau khi Kafka xác nhận, nên dừng giữa chừng chỉ gây trùng (chống trùng theo `id` lấy từ `messageId`), không mất. Quay lui trong `10.migration.rollback-window-days` triển khai lại cầu nối chiều cũ và chuyển ánh xạ `ROLLED_BACK`.

## 6. Đa tenant trong mã nguồn

Mọi bảng `ph10_event` có `tenant_id` và `FORCE ROW LEVEL SECURITY`; `TenantContextFilter` của `dh-integration` đặt `SET LOCAL app.tenant_id` đầu mỗi giao dịch từ token (D03-10, SEC-80, SEC-81). Tác vụ nền (đối soát, thu lag, ingestor DLQ) lặp theo tenant và đặt ngữ cảnh cho từng vòng; không truy vấn nào chạy không có ngữ cảnh (kiểm bằng `RlsGuardTest` chạy với vai trò CSDL không có `BYPASSRLS`). Topic nền tảng `dh.` thuộc tenant `COMMON`; chính sách RLS cho đọc `tenant_id IN (current, 'COMMON')` ở bảng `topic`, `event_schema`, `schema_version`, ghi chỉ `current`.

Tenant của bản tin luôn lấy từ tiền tố topic (BR-10-001, FR-10-064). Trên cụm, cách ly theo bảng sau (SEC-82):

| Lớp | Cơ chế | Nơi kiểm |
|---|---|---|
| Tên topic, nhóm | Tiền tố `{tenant}.` và `dh-*-{tenant}-*` theo Phụ lục A.8 | `TopicNamePolicy`; Kyverno từ chối `KafkaTopic`, `KafkaUser` trong kho `dh-config-{tenant}` mà tên, ACL không mang tiền tố tenant của kho (ADR-072) |
| ACL | Principal nội bộ `User:CN=dh-runtime-{tenant}`, `User:CN=dh-cdc-{tenant}`: ACL `prefixed` trên `{tenant}.` và nhóm `dh-*-{tenant}-`; principal HTTT: ACL `literal` theo topic và nhóm | `AclRenderer`; kiểm thử rò rỉ |
| Hạn mức | `quotas` theo `KafkaUser`, tổng ≤ trần tenant | `QuotaAllocator` (SEC-86) |
| Lược đồ | `groupId = {tenant}`; `RegistryProxy` lọc theo scope của token, chỉ trả artifact của topic mà client có publication hoặc subscription `ACTIVE` | Cổng sự kiện |
| Bí mật | OpenBao theo tiền tố `kv/dh/{tenant}/event/`, transit `dh-{tenant}-event-dlq`; ServiceAccount của `dh-rt-{tenant}` chỉ đọc tiền tố của nó | Chính sách OpenBao (SEC-88) |
| Valkey | Khóa `dh:{tenant}:evt:*`, ACL Valkey theo người dùng của từng namespace | Cấu hình Valkey |
| Quan sát | Nhãn `tenant` bắt buộc; Grafana lọc theo tenant (SEC-84) | `EventMetrics` |

: Đa tenant trong mã nguồn

`LeakProbeScheduler` chạy mỗi ngày và sau mỗi lần phát hành: principal kiểm thử của T90 thử `DESCRIBE`, `READ`, `WRITE` topic và nhóm của T91, đọc artifact `groupId = t91`, gọi API phát, kéo với `subscriptionCode` của T91; mọi lượt phải bị từ chối, kết quả gửi PH-13 (SEC-87, NFR-10-017).

## 7. Bảo mật

| Vấn đề | Biện pháp | SEC |
|---|---|---|
| Giả mạo bên phát | Token client credentials, scope `topic:{topicName}:publish` và dữ liệu OPA mỗi lượt; `source` phải thuộc HTTT; `dhtenant` ghi đè | SEC-24, SEC-25, SEC-26 |
| Tạm ngừng chậm có hiệu lực | Gỡ dữ liệu OPA trước, không đợi token hết hạn | SEC-25, SEC-26 |
| Giả mạo, phát lại webhook | HMAC-SHA256 theo ADR-044, `Webhook-Timestamp`, `Webhook-Id`, hướng dẫn bên nhận kiểm độ lệch `10.push.signature-tolerance-seconds` | SEC-47 |
| Lộ khóa ký | Sinh trong `dh-integration`, ghi thẳng OpenBao, hiển thị một lần; không lưu CSDL, không log, không xuất; canary NFR-10-016 | SEC-33, SEC-32 |
| SSRF, DNS rebinding qua `endpointUrl` | HTTPS, FQDN trong danh sách egress, chặn dải riêng, ghim IP, không theo chuyển hướng | SEC-16, SEC-43 |
| TLS yếu ở đầu nhận | TLS ≥ 1.2, kho CA nền tảng, ERR-10-114 | SEC-12 |
| Lộ dữ liệu cá nhân qua sự kiện | `PiiScanner`, chính sách `10.schema.pii-check-mode`, sự kiện chỉ mang định danh (BR-10-014) | SEC-37 |
| Lộ nội dung DLQ | Mã hóa transit theo tenant cho `RESTRICTED`, `SENSITIVE`; xem nội dung cần `PERM-10-operate`, lý do, kiểm toán | SEC-31, SEC-60 |
| Cursor bị giả | HMAC phía máy chủ, gắn `leaseId` và `subscriptionCode` | SEC-43 |
| Sửa cụm ngoài quy trình | Git là nguồn sự thật, Kyverno, đối chiếu lệch mỗi 10 phút | SEC-07, SEC-59, SEC-65 |
| Kết nối Kafka ngoài | Chỉ khi PA bật; SASL OAUTHBEARER hoặc mTLS; nhóm đúng tên được cấp | SEC-13, SEC-24 |
| Hàng xóm ồn ào | Hạn mức Kafka theo principal, `limit-count` APISIX, trần worker | SEC-86 |
| Lạm dụng phát lại | Duyệt bốn mắt, lý do, nhật ký 3 năm | SEC-60 |

: Bảo mật

Quyền kiểm ở máy chủ: `@PreAuthorize` theo `PERM-10-read`, `PERM-10-create`, `PERM-10-update`, `PERM-10-subscribe`, `PERM-10-approve`, `PERM-10-operate`, `PERM-10-admin` ở lớp `web` theo ma trận FRS §3.2; phạm vi tổ chức (○) và bốn mắt kiểm trong dịch vụ, aggregate (ERR-10-044, 008). Scope máy `event:topic-register`, `event:permission-check`, `event:runtime-config`, `event:dlq-read`, `event:replay`, `event:metrics-read` chỉ cấp cho tài khoản dịch vụ; endpoint nội bộ `/runtime/**` chỉ mở trên `apisix-int`.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mỗi chuyển là một phương thức của aggregate; trạng thái nguồn không hợp lệ trả ERR-10-006. Sơ đồ trạng thái ở FRS §4.3…4.8.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| EventProject | ACTIVE | archive | ARCHIVED | Không còn topic PENDING_APPROVAL, PROVISIONING, ACTIVE, DEPRECATED (ERR-10-010) |
| EventProject | ARCHIVED | restore | ACTIVE | |
| Topic | DRAFT | submit | PENDING_APPROVAL | Lược đồ v1 đạt kiểm tra |
| Topic | PENDING_APPROVAL | reject, withdraw | DRAFT | |
| Topic | PENDING_APPROVAL | approve | PROVISIONING | Bốn mắt, hạn mức, tên; artifact và commit thành công |
| Topic | DRAFT | (tự duyệt máy) | PROVISIONING | `AutoApprovalPolicy` |
| Topic | PROVISIONING | (đối soát) | ACTIVE, FAILED | `Ready`, quá hạn |
| Topic | FAILED | retry-provisioning | PROVISIONING | `PERM-10-update` |
| Topic | FAILED | cancel-provisioning | DRAFT | Xóa artifact khi chưa có bản tin |
| Topic | ACTIVE | deprecate | DEPRECATED | Có `successorTopic` hoặc lý do, `sunsetAt` |
| Topic | ACTIVE, DEPRECATED | retire | RETIRED | Không còn subscription chưa REVOKED, hoặc đã tới `sunsetAt` (thu hồi hết) |
| SchemaVersion | DRAFT | submit | PENDING_APPROVAL | Tương thích, khóa phân vùng, PII |
| SchemaVersion | PENDING_APPROVAL | withdraw, reject, approve | DRAFT, REJECTED, ENABLED | Bốn mắt khi duyệt |
| SchemaVersion | ENABLED, DEPRECATED | deprecate, (bỏ) | DEPRECATED, ENABLED | |
| SchemaVersion | DEPRECATED | disable | DISABLED | Không còn bản tin trong lưu giữ, không phải bản mới nhất (BR-10-015) |
| Publisher, Subscriber | ACTIVE | suspend | SUSPENDED | Ghi `suspendSource` |
| Publisher, Subscriber | SUSPENDED | resume | ACTIVE | Chỉ nguồn tương ứng (PH01 chỉ khi HTTT ACTIVE) |
| Publisher, Subscriber | ACTIVE, SUSPENDED | retire | RETIRED | Thu hồi quan hệ |
| Publication | PENDING_APPROVAL | approve, reject | ACTIVE, REJECTED | Bốn mắt, scope, ACL, hạn mức |
| Publication | ACTIVE | suspend | SUSPENDED | Gỡ OPA, ACL |
| Publication | SUSPENDED | resume | ACTIVE | Đúng `suspendSource` |
| Publication | ACTIVE, SUSPENDED | revoke | REVOKED | |
| Subscription | PENDING_APPROVAL | approve, reject | PROVISIONING, REJECTED | Bốn mắt, endpoint xác minh 24 giờ |
| Subscription | PROVISIONING | (cấp phát) | ACTIVE, FAILED | |
| Subscription | FAILED | retry | PROVISIONING | |
| Subscription | ACTIVE | pause, resume | PAUSED, ACTIVE | `PERM-10-operate`, lý do |
| Subscription | ACTIVE | suspend (SO, PH-01, ngắt mạch, `BLOCK`) | SUSPENDED | `suspendSource` `SECURITY`, `PH01`, `CIRCUIT_BREAKER`, `DELIVERY_BLOCKED`, `MANUAL` |
| Subscription | SUSPENDED | resume | ACTIVE | Lý do khắc phục; ngắt mạch có thể tự về |
| Subscription | ACTIVE, PAUSED, SUSPENDED | revoke | REVOKED | Hủy lượt phát lại đang chạy |
| SigningKey | ACTIVE | rotate | PREVIOUS | Sinh khóa ACTIVE mới |
| SigningKey | PREVIOUS | (hết `previousUntil`) | REVOKED | Xóa khỏi OpenBao |
| SigningKey | ACTIVE | revoke khẩn | REVOKED | Sinh khóa mới, không chồng lấn |
| ApprovalRequest | PENDING | approve, reject, withdraw, (hết hạn) | APPROVED, REJECTED, WITHDRAWN, EXPIRED | Bốn mắt; hết hạn đưa đối tượng về trạng thái trước |
| ReplayRequest | PENDING_APPROVAL | approve, reject, cancel | APPROVED, REJECTED, CANCELLED | |
| ReplayRequest | APPROVED | (nhận việc), cancel, (24 giờ) | RUNNING, CANCELLED | |
| ReplayRequest | RUNNING | (xong), (lỗi), cancel | COMPLETED, FAILED, CANCELLED | |
| DlqEntry | NEW | replay, discard | REPLAY_PENDING, DISCARDED | ERR-10-036 nếu đã xử lý |
| DlqEntry | REPLAY_PENDING | (kết quả) | REPLAYED, NEW | |
| DlqEntry | REPLAYED, DISCARDED | (hết giữ) | PURGED | |
| MigrationBridge | PENDING_APPROVAL | approve, reject, (hết hạn duyệt) | RUNNING, REJECTED | Mỗi lần đổi trạng thái phát EVT-10-16 |
| MigrationBridge | RUNNING | stop, (lỗi), (hết hạn) | STOPPED, ERROR, EXPIRED | |
| MigrationBridge | STOPPED, ERROR | resume | RUNNING | Chưa quá `expiresAt` |
| LegacyMapping | PROPOSED | (lập kế hoạch) | PLANNED, SKIPPED | |
| LegacyMapping | PLANNED | (cầu nối RUNNING) | BRIDGING | |
| LegacyMapping | BRIDGING | cut-over | CUT_OVER | Điều kiện FR-10-075, duyệt CUTOVER |
| LegacyMapping | CUT_OVER | rollback, (hết cửa sổ) | ROLLED_BACK, CLOSED | Quay lui không qua duyệt |
| LegacyMapping | ROLLED_BACK | (cầu nối chiều cũ RUNNING) | BRIDGING | |
| ManifestImportJob | VALIDATING | (xong), cancel | PREVIEW, FAILED, CANCELLED | |
| ManifestImportJob | PREVIEW | apply, cancel | APPLYING, CANCELLED | |
| ManifestImportJob | APPLYING | (xong) | APPLIED, FAILED | |

: Bảng chuyển trạng thái

Ba chuyển `ROLLED_BACK` sang `BRIDGING`, cầu nối sang `REJECTED` và hủy tác vụ nhập ở `VALIDATING` theo FRS 0.2 (A.2.13, A.2.14).

### 8.2. Outbox

Sự kiện EVT-10-01…16 ghi vào `outbox_event` cùng giao dịch với thay đổi trạng thái; Debezium outbox của `pg-core` (cơ chế chung với PH-04, PH-05) đẩy lên `{tenant}.event.{thực-thể}.{sự-kiện}.v1` với khóa theo cột "Khóa" FRS §9.3 và `ce_type = vn.datahub.event.{thực-thể}.{sự-kiện}`. `ce_id` là ULID sinh khi ghi outbox, nên Debezium phát lại sau sự cố vẫn mang cùng `id`. Bản ghi kiểm toán đi cùng outbox sang PH-13 (FR-10-065), không ghi trực tiếp. Riêng EVT-10-11 được `DlqAlertAggregator` gộp: mỗi phút một bản ghi outbox cho mỗi subscription có mục mới.

### 8.3. Inbox và idempotency

| Đầu vào | Cơ chế | Khóa |
|---|---|---|
| Lệnh ghi qua `/api/event/v1` | `IdempotencyFilter`: lưu (tenant, chủ thể, `Idempotency-Key`, băm thân, phản hồi) 24 giờ; trùng khóa khác băm trả ERR-10-037 | `Idempotency-Key` 16…128 ký tự |
| Đăng ký máy (FR-10-066, 067), `ensure-party` | Idempotent tự nhiên theo `topicName`, (`flowCode`, `topicName`, `action`) | Mã nghiệp vụ |
| Sự kiện tiêu thụ (EVT-05-11, EVT-04-09, PH-01, PH-20) | Bảng `inbox_event` (FRS A.3): ghi `ce_id` và xử lý trong một giao dịch, trùng thì bỏ qua | `ce_id` |
| Bản tin DLQ | Chỉ mục duy nhất theo nguồn và `attempts` (§4.9) | Nguồn |
| Báo cáo giao nhận | Ghi đè theo (`subscriptionCode`, `windowStart`) | Cửa sổ |
| Lệnh hệ thống từ `dh-runtime` (tạm ngừng do ngắt mạch, kết quả phát lại) | Mang `configVersion`; bỏ qua khi cũ hơn | `version` |
| API phát | Chống trùng (bên phát, `id`) 24 giờ ở Valkey (§4.6) | `id` CloudEvents |

: Inbox và idempotency

### 8.4. Thời gian chờ, thử lại, ngắt mạch

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch, khi lỗi |
|---|---|---|---|
| Apicurio từ `dh-integration` | 3 giây | 2 lần, 200 ms, 800 ms | 50% trên 10 lượt, nửa mở 30 giây; ERR-10-029 |
| Apicurio từ `dh-runtime` (đọc) | 2 giây | 2 lần | Dùng đệm theo `contentId` (bất biến) |
| Git push | 15 giây | 5 lần với kéo lại | ERR-10-029, yêu cầu giữ `PENDING` |
| Kubernetes API (đọc CR) | 5 giây | Vòng sau | Không đổi trạng thái khi không đọc được |
| Kafka Admin | 10 giây | 3 lần | ERR-10-029; bộ thu lag bỏ chu kỳ |
| Keycloak Admin API | 5 giây | 2 lần | ERR-10-029 |
| OpenBao (ghi khóa ký) | 2 giây | 2 lần | ERR-10-029 |
| OpenBao (đọc khóa từ runtime) | 1 giây | 2 lần | Đệm 10 phút rồi ERR-10-117 |
| PH-01 bản sao đọc, PH-04 `FlowQueryApi` | Trong tiến trình hoặc 2 giây | Không | ERR-10-021, 022 khi không có; ERR-10-029 khi lỗi |
| Webhook tới HTTT | `timeoutMs` | Theo FR-10-039 | `SubscriptionBreaker` |
| Produce từ cổng | `delivery.timeout.ms` 10 giây | Client Kafka tự thử lại idempotent | ERR-10-108 |

: Thời gian chờ, thử lại, ngắt mạch

### 8.5. Ánh xạ lỗi

Control plane ánh xạ ngoại lệ miền sang ProblemDetail RFC 9457 bằng `EventProblemMapper`; `type` là URI của mã lỗi, `code` là ERR-10-0xx. Xác thực, quyền chung ở control plane trả ERR-10-053 (401, token thiếu hoặc hết hạn) và ERR-10-054 (403, thiếu `PERM-10-*` hoặc scope dịch vụ); ERR-10-101, 102 chỉ dành cho data plane (cổng sự kiện, API-10-079…084).

| Ngoại lệ hoặc tình huống | Mã |
|---|---|
| `NotFoundOrForeignTenant` | ERR-10-001 |
| Vi phạm ràng buộc duy nhất mã, tên | ERR-10-002 |
| Kiểm tra Bean Validation, trường bất biến, tổ hợp sai | ERR-10-003 |
| `TopicNamePolicy` từ chối, tiền tố khác tenant | ERR-10-004, 005 |
| `IllegalTransition` | ERR-10-006 |
| `OptimisticLockException`, `If-Match` sai | ERR-10-007 |
| `FourEyesViolation` | ERR-10-008 |
| Thiếu lý do, ý kiến, `acknowledgePii`, `acknowledgeDuplicates` | ERR-10-009 |
| Còn đối tượng phụ thuộc | ERR-10-010 |
| `QuotaGuard` | ERR-10-011 |
| Ngoài miền tham số | ERR-10-012 |
| Giảm phân vùng, chưa xác nhận thứ tự | ERR-10-013, 014 |
| Lược đồ: cú pháp, không tương thích, khóa phân vùng, PII, mức, định dạng | ERR-10-015…020 |
| PH-01, PH-04, DU không hợp lệ | ERR-10-021…023 |
| Quan hệ trùng, không ở trạng thái nhận | ERR-10-024, 025 |
| Endpoint không hợp lệ, xác minh lỗi, Kafka ngoài chưa bật | ERR-10-026…028 |
| `DependencyUnavailable` (Apicurio, Git, Admin, Keycloak, OpenBao, PH-01, PH-04) | ERR-10-029 |
| Worker, `startAt`, `RESET_OFFSET` chưa `PAUSED` | ERR-10-030…032 |
| Phát lại: khoảng, trần, đang có lượt, mục đã xử lý | ERR-10-033…036 |
| Idempotency trùng khác thân | ERR-10-037 |
| Cấp phát lỗi hoặc chưa xong | ERR-10-038 |
| Tenant tạm ngừng hoặc đóng băng | ERR-10-039 |
| Nhập khai báo, ánh xạ, cầu nối | ERR-10-040…042, 050 |
| Tắt danh mục đang dùng, ngoài tổ chức, topic máy | ERR-10-043…045 |
| Định tuyến, phiên bản topic, compaction, tham số truy vấn | ERR-10-046…049 |

: Ánh xạ ngoại lệ ở control plane sang mã lỗi ERR-10

Data plane phân loại kết quả giao bằng `DeliveryOutcomeClassifier`; `failureClass` ghi vào `delivery_failure` và quyết định nhánh xử lý:

| Kết quả | Mã | `failureClass` | Xử lý |
|---|---|---|---|
| Quá `timeoutMs`, lỗi mạng | ERR-10-111 | `TRANSIENT` | Thử lại giãn dần |
| `5xx`, `408`, `425`, `429` | ERR-10-112 | `TRANSIENT` | Thử lại, tôn trọng `Retry-After` |
| `4xx` khác, nack của bên nhận | ERR-10-113 | `PERMANENT` | DLQ ngay; `410` thêm tạm ngừng subscription |
| Lỗi TLS, chứng thư | ERR-10-114 | `SECURITY` | Thử lại như tạm thời (chứng thư có thể đang thay), cảnh báo TO |
| Địa chỉ bị chặn | ERR-10-115 | `SECURITY` | DLQ, cảnh báo SO |
| Không giải tuần tự | ERR-10-116 | `DESERIALIZATION` | DLQ ngay |
| Không đọc khóa ký | ERR-10-117 | `SECURITY` | Tạm dừng phân vùng, không gửi |
| Cầu nối không chuyển được | ERR-10-118 | `PERMANENT` | DLQ của cầu nối |
| Bản tin thiếu định danh lược đồ (tuân thủ) | ERR-10-119 | `DESERIALIZATION` | Đếm vi phạm theo publication |
| Kafka từ chối ACL, hạn mức | ERR-10-120 | `SECURITY` | Chỉ số theo principal |

: Ánh xạ kết quả giao nhận ở runtime sang mã lỗi ERR-10

## 9. Cấu hình và cờ tính năng theo tenant

Tham số `10.*` đầy đủ ở Phụ lục A.5 FRS; module `settings` đọc qua `ParameterApi` của PH-18 (thư viện `dh-ops-client`) với đệm tối đa 60 giây (BR-18-006, `18.param.cache-ttl-seconds`) và làm mới ngay khi PH-18 báo đổi. Nơi dùng:

| Nhóm tham số | Đọc ở | Áp dụng |
|---|---|---|
| `10.topic.*`, `10.schema.*`, `10.provisioning.timeout-minutes` | `TopicConfigPolicy`, `CompatibilityChecker`, `PiiScanner`, `ProvisioningReconciler` | Đối tượng tạo mới |
| `10.approval.*` | `AutoApprovalPolicy`, `ApprovalExpirer` | Ngay |
| `10.publish.max-batch`, `10.pull.*` | Cổng sự kiện qua `RuntimeConfigCache` | Ngay sau làm mới cấu hình |
| `10.push.*` | Giá trị mặc định khi tạo subscription; trần kiểm khi tạo, sửa; `10.push.suspend-after-failures-minutes`, `10.push.key-*` đọc ở bộ giao nhận và `RotationScheduler` | Mặc định cho đối tượng mới; trần ngay |
| `10.lag.*` | `LagCollector`, `AlertEvaluator` | Ngay (ngưỡng mặc định áp cho subscription không đặt riêng) |
| `10.dlq.*`, `10.replay.*` | `DlqPurger`, `ReplayService`, `ReplayRunner` | Ngay |
| `10.compliance.*` | `ComplianceSampler` | Ngay |
| `10.graph.max-nodes` | `GraphBuilder` | Ngay |
| `10.quota.*` | `QuotaGuard`, `QuotaAllocator` | Ngay ở control plane; Kafka sau commit Git |
| `10.migration.*` | `MigrationService`, `BridgeMonitor`, `CutOverService` | Ngay |

: Cấu hình và cờ tính năng theo tenant

Ba tham số đóng vai cờ tính năng: `10.external-kafka.enabled` (chỉ PA đặt; bật thì sinh route listener `external` cho tenant và cho phép `KAFKA_NATIVE`, `PULL_KAFKA`), `10.approval.auto-approve-machine`, `10.approval.auto-approve-internal`. Danh mục `comm_type_setting`, `routing_mode_setting` bật tắt từng mã theo tenant (FR-10-060, 061). Không có cờ tính năng nào ngoài các tham số này; FR-10-048 (lọc, gộp lô) và FR-10-071 (nhập khai báo) ở Đợt sau được tắt bằng cấu hình build `dh.event.features.*` của DU, không phải tham số tenant.

## 10. Quan sát

| Chỉ số | Kiểu | Nhãn (ngoài `tenant`) | Nguồn |
|---|---|---|---|
| `dh_event_published_total` | counter | `topic`, `publication` | Cổng |
| `dh_event_publish_rejected_total` | counter | `topic`, `reason` (mã ERR) | Cổng |
| `dh_event_publish_duration_seconds` | histogram | `topic` | Cổng (NFR-10-002) |
| `dh_event_pull_requests_total` | counter | `subscription`, `result` | Cổng |
| `dh_event_dedup_bypass_total` | counter | | Cổng |
| `dh_event_delivery_total` | counter | `subscription`, `result` (`success`, `transient`, `permanent`, `dead_letter`) | Bộ giao nhận |
| `dh_event_delivery_duration_seconds` | histogram | `subscription` | Bộ giao nhận (NFR-10-003, 005) |
| `dh_event_delivery_retry_total` | counter | `subscription` | Bộ giao nhận |
| `dh_event_dispatcher_workers` | gauge | `replica` | `SlotAllocator` |
| `dh_event_consumer_lag_records`, `dh_event_consumer_lag_seconds` | gauge | `topic`, `subscription`, `partition` | Bộ thu lag |
| `dh_event_dlq_entries` | gauge | `subscription`, `status` | Control plane |
| `dh_event_replay_records_total` | counter | `replay`, `result` | Bộ phát lại |
| `dh_event_compliance_violation_total` | counter | `publication`, `reason` | Bộ giám sát tuân thủ |
| `dh_event_provisioning_state` | gauge | `kind`, `state` | Bộ đối soát |
| `dh_event_quota_usage_ratio` | gauge | `kind` | `QuotaAllocator` |
| `dh_event_runtime_config_age_seconds` | gauge | `role` | `RuntimeConfigCache` |
| `dh_event_stats_dropped_total` | counter | | Bộ giao nhận |
| `dh_event_bridge_lag_seconds`, `dh_event_bridge_messages_total` | gauge, counter | `bridge` | Cầu nối |

: Quan sát

Bảy chỉ số đầu của FR-10-059 giữ đúng tên; các chỉ số còn lại là chỉ số vận hành của thiết kế, cùng tiền tố `dh_event_` và nhãn `tenant` (Phụ lục A.8). Nhãn `partition` chỉ có ở hai chỉ số lag; `ce_subject` và mọi giá trị nghiệp vụ không bao giờ là nhãn.

Vết: cổng tạo span `event.publish` nối tiếp `traceparent` của HTTT, ghi `traceparent` vào tiêu đề bản tin; bộ giao nhận tạo span `event.deliver` liên kết (span link) tới span phát, gửi `traceparent` mới cho đầu nhận. Thuộc tính `dh.topic`, `dh.subscription`, `messaging.kafka.partition`, `messaging.kafka.offset`, `http.response.status_code`, `dh.attempt`. Control plane có span cho Apicurio, Git, Keycloak, OpenBao. Log JSON có `tenant`, `topic`, `subscription`, `traceId`, `ce_id`; không có thân bản tin, không có bí mật, `responseSnippet` đã qua bộ che (SEC-32).

## 11. Hiệu năng và vận hành

**Định cỡ cho tỉnh vừa** (giả định, cơ sở GĐ-07 và GĐ-10-01, 02): 150 topic nghiệp vụ, 400 subscription (240 `PUSH`, 140 `PULL_API`, 20 `PULL_KAFKA`), 2 triệu sự kiện mỗi ngày, trung bình 23 sự kiện/giây, cao điểm khoảng 70 sự kiện/giây. Mỗi topic trung bình 2,7 bên nhận, nên số lượt giao đẩy khoảng 3,2 triệu mỗi ngày, cao điểm khoảng 110 lượt/giây.

| Thành phần | Định cỡ | Cơ sở |
|---|---|---|
| `dh-runtime-event-gateway` | 2 bản sao, 0,5 vCPU, 512 MiB | 70 sự kiện/giây là 4% NFR-10-004; bản sao thứ hai cho sẵn sàng |
| `dh-runtime-event-dispatcher` | 2 bản sao, 1 vCPU, 1 GiB; KEDA tới 6 | 110 lượt/giây so với 200 lượt/giây mỗi bản sao (NFR-10-005); 360 consumer, `fetch.max.bytes` 1 MiB |
| Module `event` trong `dh-integration` | Thêm khoảng 0,5 vCPU, 512 MiB | Bộ thu lag 400 nhóm mỗi 30 giây, ingestor DLQ |
| Kafka | 1.800 phân vùng (150 topic và 150 DLQ, 6 phân vùng) cộng topic CDC, `SYSTEM`; khoảng 85 GB đĩa (2 KB × 2 triệu × 7 ngày × 3 bản sao) cộng 30% dự phòng | Đề nghị thêm vào D03-09 (FRS §12.4) |
| `pg-core` `ph10_event` | `delivery_stat` khoảng 350 nghìn dòng/ngày (chỉ ghi phút có lượt), 90 ngày; `lag_sample` khoảng 7 triệu dòng/ngày, 48 giờ; cả hai phân vùng theo ngày | §7.2 FRS |
| Valkey | Dưới 200 MiB: khóa chống trùng 24 giờ (2 triệu × khoảng 80 byte), lease, ảnh chụp cấu hình | |

: Hiệu năng và vận hành

**Đường nóng.** Cổng giữ p99 ≤ 50 ms nhờ: kiểm lược đồ trên đệm `contentId` (không gọi mạng), một lượt Valkey `SET NX` (khoảng 1 ms), producer `linger.ms = 2`, `acks=all` (khoảng 5–15 ms trong một TTDL). Bộ giao nhận không chặn luồng nền khi chờ mạng nhờ luồng ảo và client HTTP không đồng bộ, giới hạn đồng thời mỗi bản sao bằng tổng phân vùng được gán.

**Vận hành** (sổ tay D06-03): xử lý topic `FAILED` và lệch cấu hình; thay số bản sao bộ giao nhận; đặt lại vị trí bằng `RESET_OFFSET` thay cho thao tác tay; khôi phục mục DLQ khi `pg-core` ngừng lâu hơn lưu giữ topic DLQ; dọn nhóm tiêu thụ mồ côi (so `dh-sub-*`, `dh-ext-*` trên cụm với `subscription`); DR: Argo CD dựng lại topic, ACL ở site DR từ cùng kho Git, MirrorMaker 2 sao bản tin và offset nhóm (NFR-10-019); sau chuyển site, bộ giao nhận đọc offset đã dịch và có thể giao trùng trong cửa sổ RPO.

## 12. Kiểm thử

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Invariant aggregate, `TopicNamePolicy`, `CommTypeMatrix`, `RetryPolicy`, `WebhookSigner` (vector thử ADR-044), `CursorCodec`, `QuotaAllocator`, `AlertEvaluator`, `KafkaManifestRenderer` (so tệp vàng) | JUnit 5, jqwik |
| Kiến trúc | Luật Modulith, cấm log `SigningSecret`, chỉ `provisioning` dùng client Kubernetes | ArchUnit |
| Tích hợp control plane | PostgreSQL với RLS, Apicurio 3, Keycloak, OpenBao dev, Gitea thay kho Git, Kafka | Testcontainers |
| Tích hợp data plane | Cổng và bộ giao nhận với Kafka, Apicurio, Valkey, WireMock làm đầu nhận (lỗi, chậm, `410`, TLS sai, chuyển hướng, DNS rebinding) | `@QuarkusTest`, chạy native ở CI ban đêm |
| Cấp phát | Strimzi và Argo CD trên kind, Kyverno từ chối tên sai tiền tố | kind, chạy ban đêm |
| Hỗn loạn | Giết broker, bộ giao nhận, cổng giữa chừng với 1 triệu sự kiện: 0 mất, trùng ≤ 0,1% (NFR-10-006, 007) | Chaos Mesh |
| Hiệu năng | Phát 500 sự kiện/giây 2 KB (NFR-10-002), giao 200 lượt/giây mỗi bản sao (NFR-10-005) | Gatling, k6 |
| Hợp đồng | OpenAPI, AsyncAPI của D03-04-PH10; hợp đồng với PH-04, PH-05 | Spectral, oasdiff (CI-5) |
| Bảo mật | Canary bí mật ký (NFR-10-016), rò rỉ chéo tenant (NFR-10-017), SSRF, cursor giả | D05-02-PH10, D05-04 |

: Kiểm thử

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

| Bước | Nội dung | FR |
|---|---|---|
| 1 | Module `event`: dự án, topic, lược đồ, Apicurio, duyệt, GitOps, đối soát | 001…022, 060, 061 |
| 2 | Bên phát, bên nhận, publication, cổng sự kiện (API phát), scope và OPA | 025…033 |
| 3 | Subscription, bộ giao nhận (đẩy, thử lại, ngắt mạch), khóa ký, xác minh endpoint | 035…042, 046, 047 |
| 4 | API kéo, Kafka ngoài, nội bộ; VR-10 cho PH-04; đăng ký máy cho PH-05, DU | 034, 043…045, 066…069 |
| 5 | DLQ, phát lại, lag, cảnh báo, thống kê, dashboard, sơ đồ, hạn mức, kiểm thử rò rỉ | 049…059, 062…065, 023 |
| 6 | Xuất khai báo, di trú Pulsar, cầu nối, đối chiếu, chuyển hẳn | 070, 072…076 |
| Đợt sau | Lọc và gộp lô khi đẩy, nhập khai báo | 048, 071 |

: Lộ trình

Bước 1–4 nằm trong W2–W4 của kế hoạch phát triển (song song PH-04, PH-05 vì PH-05 CDC cần bước 4); bước 5–6 ở W5–W6.

### 13.2. Truy vết hệ cũ

| Mã hệ cũ | Thành phần hiện thực |
|---|---|
| LGC-HUB-001…004 | `DashboardQuery` (§4.15) |
| LGC-HUB-005, 006 | Liên kết sang PH-13 |
| LGC-HUB-007 | `GraphBuilder`, `LagCollector` |
| LGC-HUB-008 | `project` |
| LGC-HUB-009 | `topic`, `schema`, `provisioning` |
| LGC-HUB-010, 011 | `party`, `PartySyncConsumer` |
| LGC-HUB-012 | `publication`, `access`, cổng sự kiện |
| LGC-HUB-013 | `subscription`, `signing`, bộ giao nhận, cổng kéo, `dlq`, `replay` |
| LGC-HUB-014 | `catalog` |
| LGC-TOOL-010 | `machine`, Kamelet `dh-kafka-source`, `dh-kafka-sink` |
| LGC-BUS-039 | Cổng sự kiện, bộ giao nhận |

: Truy vết hệ cũ

### 13.3. Rủi ro

| Rủi ro | Ảnh hưởng | Giảm thiểu |
|---|---|---|
| Cấp phát qua GitOps chậm hơn kỳ vọng của người dùng | PH-05 và IE chờ phút | Trả `202`, hiển thị tiến độ, NFR-10-008 đo ở CI |
| Số consumer lớn khi tenant có nhiều subscription đẩy | Bộ nhớ và tải nhóm của broker | Trần `10.quota.max-push-workers-total`, `fetch.max.bytes` nhỏ, KEDA |
| Endpoint HTTT chậm kéo dài làm tồn đọng | Lag, hết lưu giữ | Ngắt mạch, cảnh báo thời gian còn lại, `CRITICAL` khi dưới 24 giờ |
| Valkey ngừng | Mất chống trùng, API kéo ngừng | Phát vẫn chạy (bỏ chống trùng); kéo trả `503` ngắn; Valkey HA của nền tảng |
| Bên phát Kafka trực tiếp ghi sai lược đồ | Bên nhận nhận bản tin lỗi | Giám sát tuân thủ, DLQ ERR-10-116, tạm ngừng publication |
| Chuyển nội dung ở cầu nối Pulsar sai | Bản tin lỗi trong giai đoạn song song | DLQ cầu nối, đối chiếu mỗi giờ, quay lui |

: Rủi ro

### 13.4. Đề nghị bổ sung cho FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Trạng thái: bảy mục dưới đây đã xử lý ở FRS bản 0.2 (D02-03-PH10 §15); thân tập này đã dùng tên chốt.

| Mục | Chỗ thiếu ở Phụ lục A | Thiết kế đang dùng | Đề nghị |
|---|---|---|---|
| 1 | Bảng lưu khóa idempotency và inbox sự kiện tiêu thụ | Mô tả ở §8.3, chưa đặt tên bảng | Thêm vào A.3 hai bảng hạ tầng (ví dụ `idempotency_record`, `inbox_event`) để tập CSDL dùng chung tên |
| 2 | Giá trị `suspendSource` cho tạm ngừng do `failurePolicy = BLOCK` (khác ngắt mạch vì không tự tiếp tục). Chuyển trạng thái: `LegacyMapping` sau `ROLLED_BACK`; `MigrationBridge` khi yêu cầu `BRIDGE` bị từ chối; `ManifestImportJob` hủy ở `VALIDATING` | Ghi trong ngoặc ở §8.1 | Bổ sung chuyển ở A.2.13, A.2.14 (đề xuất `ROLLED_BACK` sang `BRIDGING` khi bật lại cầu nối; cầu nối bị từ chối không tạo bản ghi `RUNNING`) |
| 3 | Đường dẫn OpenBao cho khóa ký cursor của API kéo | §4.7 | Thêm vào A.8 một đường dẫn dạng `kv/dh/{tenant}/event/runtime/cursor` |
| 4 | Tiêu đề DLQ mang `origin` | §4.9 suy từ đường ghi | Thêm `dh_dlq_origin` vào A.8 |
| 5 | API nội bộ cho `dh-runtime`: báo cáo giao nhận, tạm ngừng do ngắt mạch hoặc `BLOCK`, nhận việc và báo kết quả phát lại, lấy nội dung mục DLQ | §4.8, 4.10, 4.11 | Thêm mã API kế tiếp từ API-10-085 ở FRS §9.4 (tập API cấp) |
| 6 | Mã lỗi data plane cho phụ thuộc runtime không khả dụng (Valkey, Apicurio khi đệm rỗng) | §4.7 trả `503` không mã riêng | Thêm một mã trong dải 121…199 |
| 7 | Thực thể lưu báo cáo đối chiếu di trú, kết quả xác minh endpoint, xác nhận cảnh báo lag | §4.16, FR-10-036, FR-10-055 | Thêm trường hoặc bảng vào A.3 (`endpointVerification` hiện chỉ có enum `result`) |

: Đề nghị bổ sung cho FRS

### 13.5. Câu hỏi mở

> **Câu hỏi mở Q10-20:** Ảnh chụp cấu hình runtime đặt ở Valkey (§4.12) làm data plane phụ thuộc thêm Valkey khi khởi động lúc control plane ngừng. Phương án khác là topic compacted riêng cho cấu hình runtime, cần FRS cấp tên topic. Đề xuất giữ Valkey ở MVP.

> **Câu hỏi mở Q10-21:** Chia worker bằng `SlotAllocator` theo số thứ tự StatefulSet (§4.8) hay để mỗi bản sao chạy đủ `workerCount` consumer và dựa vào Kafka chia phân vùng (đơn giản hơn, tốn consumer nhàn rỗi). Đề xuất `SlotAllocator`, đo lại ở W4.

> **Câu hỏi mở Q10-22:** Khóa ký cursor dùng chung cho mọi bản sao cổng của tenant; xoay khóa làm cursor đang mở mất hiệu lực (ERR-10-109). Có chấp nhận được không, hay giữ hai khóa trong thời gian bằng `10.pull.lease-seconds`.

> **Câu hỏi mở Q10-23:** Khi Valkey ngừng, API phát bỏ chống trùng thay vì từ chối (§4.6). Cần ý kiến về việc ưu tiên sẵn sàng hơn chống trùng phía cổng, khi bên nhận đã bắt buộc chống trùng (BR-10-009).

> **Câu hỏi mở Q10-24:** Nội dung DLQ lưu trong `pg-core` (`dlq_payload`) tới 1 MiB mỗi mục, trần 100.000 mục mỗi subscription, có thể chiếm hàng chục GB. Có chuyển nội dung lớn hơn 64 KiB sang Ceph RGW (bucket riêng, mã hóa) không.

> **Câu hỏi mở Q10-25:** Đọc một bản tin mỗi phân vùng có lag để tính `lagSeconds` mỗi 30 giây có thể tốn khi tenant có hàng nghìn phân vùng tồn đọng. Có chấp nhận ước lượng `lagSeconds` theo tốc độ tiêu thụ cho phân vùng lag ổn định không.

> **Câu hỏi mở Q10-26:** Strimzi Topic Operator chế độ một chiều có giới hạn thực tế về số `KafkaTopic` mỗi namespace `dh-kafka` khi nhiều tenant dùng chung cụm (NFR-10-014: 1.000 topic, cộng DLQ là 2.000). Cần đo với phiên bản Strimzi chốt ở D03-09.

> **Câu hỏi mở Q10-27:** Chính sách Kyverno kiểm tiền tố tenant cho `KafkaTopic`, `KafkaUser` do PH-10 hay đội nền tảng (D03-09) sở hữu và kiểm thử.

> **Câu hỏi mở Q10-28:** Tenant nhỏ có cần cổng sự kiện và bộ giao nhận riêng trong `dh-rt-{tenant}` (tối thiểu 4 pod) không, hay dùng chung một cụm cho nhiều tenant nhỏ với principal theo tenant. Ảnh hưởng tới cách ly (SEC-83) và chi phí.

> **Câu hỏi mở Q10-29:** Hủy cấp phát (FR-10-010) xóa artifact Apicurio "nếu chưa có bản tin". Kiểm điều kiện này bằng offset cuối của topic trên cụm; khi topic chưa từng tạo được trên cụm thì xóa luôn. Cần xác nhận không có trường hợp bên phát Kafka trực tiếp đã đọc lược đồ và giữ `contentId`.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người soạn |
|---|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: kiến trúc, cấu trúc mã, thành phần, chín sequence, máy trạng thái, lỗi, quan sát, định cỡ, câu hỏi mở Q10-20…29 | Nhóm thiết kế Datahub |
| 0.2 | 2026-11-26 | Theo FRS 0.2: `DELIVERY_BLOCKED`, ERR-10-121, API-10-085…090, `dh_dlq_origin`, khóa cursor, chuyển trạng thái di trú và tác vụ nhập; §13.4 đã xử lý | Nhóm thiết kế Datahub |
| 0.3 | 2026-11-26 | Nâng theo chuẩn kết hợp (K-TRINH-BAY §5): chương 1 đủ mục đích, đối tượng đọc, quy ước, thuật ngữ, cấu trúc, tài liệu liên quan; danh sách 16 thành phần (§3.5); khối đặc tả 10 mục cho từng thành phần ở §4.2…4.17; sơ đồ thành phần chuyển TB; chú thích bảng và hình; giữ nguyên toàn bộ thiết kế kỹ thuật | Nhóm viết tài liệu (Claude) |
| 0.4 | 2026-11-27 | Đồng bộ chéo cuối: Apicurio lưu ở `pg-infra`; EVT-01-03 thay giả định Q10-17; đệm tham số ≤ 60 giây; nghe EVT-20-01, 04 và báo S06 về PH-20; topic miền của PH-06, 08, 11, 13, 15, 16; tiền tố `platform.` | Nhóm viết tài liệu (Claude) |
| 0.5 | 27/11/2026 | Đồng bộ chéo cuối: Apicurio lưu ở `pg-infra`; EVT-01-03 thay giả định Q10-17; đệm tham số ≤ 60 giây; nghe EVT-20-01, 04 và báo S06 về PH-20; topic miền của PH-06, 08, 11, 13, 15, 16; tiền tố `platform.` | Đồng bộ chéo cuối: đổi dẫn chiếu nhật ký hấp thụ của FRS PH-10 sang §15 theo số chương mới |
