# IP-03 — Bản chốt stack công nghệ theo tầng (Production)

> **Vai trò.** Một trang nguồn sự thật: công nghệ **đã chốt** để đưa LGSP vào sản xuất, xếp theo tầng.
> Đổi stack tại đây **chỉ** sau khi cập nhật ADR tương ứng. Không liệt kê phương án loại trừ — xem [05-adr](../05-adr/README.md).
>
> **Ngày chốt:** 2026-08-03 · **Rà soát phiên bản gần nhất:** 2026-08-04 · **Trạng thái:** Bản sản xuất (locked)
>
> **Bắt buộc rà soát lại vòng đời phiên bản** trước mỗi lần: mở pha lập trình mới · nâng cấp major ·
> nộp hồ sơ cấp độ ATTT. Bảng ghim ở cuối trang là nơi duy nhất chứa số phiên bản.

---

## 0. Sơ đồ tầng

```text
┌─────────────────────────────────────────────────────────────────┐
│  L8  Trải nghiệm     Console · Portal · Designer                │
├─────────────────────────────────────────────────────────────────┤
│  L7  Cổng biên       APISIX · WAF · TLS                         │
├─────────────────────────────────────────────────────────────────┤
│  L6  Ứng dụng        Spring Boot DU · API / RBAC / MDM …        │
├─────────────────────────────────────────────────────────────────┤
│  L5  Tích hợp        Camel Quarkus · Adapter · BPM · CDM        │
├─────────────────────────────────────────────────────────────────┤
│  L4  Sự kiện         Kafka · Schema Registry · CDC              │
├─────────────────────────────────────────────────────────────────┤
│  L3  Dữ liệu         PostgreSQL · Object storage S3 · Valkey    │
├─────────────────────────────────────────────────────────────────┤
│  L2  Bảo mật         Keycloak · OPA · Vault · mTLS              │
├─────────────────────────────────────────────────────────────────┤
│  L1  Nền tảng        K8s · Mesh · GitOps · Observability · CI   │
└─────────────────────────────────────────────────────────────────┘
```

---

## L1 — Nền tảng & vận hành

| Hạng mục | Công nghệ chốt | Phiên bản / ghi chú | ADR / nguồn |
|---|---|---|---|
| Orchestration | **Kubernetes** | Multi-AZ; DR warm standby | [02-arch](../02-architecture/README.md) |
| CNI | **Cilium** | Network policy | Kiến trúc § hạ tầng |
| Service mesh | **Istio ambient** | mTLS nội bộ, không sidecar nặng | [ADR-011](../05-adr/README.md#adr-011) |
| GitOps | **Argo CD** + **Kustomize** | Overlay DEV→TEST→STAGING→PROD; cấm apply tay PROD | [ADR-010](../05-adr/README.md#adr-010) |
| Đóng gói bên thứ ba | **Helm** | Chỉ cài COTS (Keycloak, Kafka…) | ADR-010 |
| Registry ảnh | **Harbor** | Quét trước khi vào PROD | [04-deployment](../04-deployment/README.md) |
| Quét bảo mật ảnh | **Trivy** | CRITICAL chặn merge/deploy | IP-02 Gate S |
| Autoscaling | **HPA** + **KEDA** | Camel theo CPU + Kafka lag | Kiến trúc §10 |
| Secret sync | **External Secrets Operator** | Đồng bộ từ Vault vào K8s | [ADR-012](../05-adr/README.md#adr-012) |
| Observability | **OpenTelemetry** + **Prometheus** + **Loki** + **Tempo** + **Grafana** (LGTM) | Trace/metric/log chuẩn mở | [ADR-007](../05-adr/README.md#adr-007) |
| CI | GitHub Actions / GitLab CI (tương đương) | Gates A–S (IP-02) | IP-02 |
| Ngôn ngữ hệ thống | **Java 21** (LTS) | Temurin. Chọn 21 thay vì 25 LTS — lý do tại [ADR-020](../05-adr/README.md#adr-020) | ADR-002, ADR-019, [ADR-020](../05-adr/README.md#adr-020) |
| Node (FE/tooling) | **Node 22 LTS** | Console, mockup | ADR-016 |

**Môi trường:** DEV → TEST → STAGING → PROD (STAGING/PROD cần duyệt).

---

## L2 — Bảo mật & định danh

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| Xác thực / IdP | **Keycloak** | OIDC, SAML2, OAuth2, MFA; cầu VNeID | [ADR-004](../05-adr/README.md#adr-004) |
| Ủy quyền | **Open Policy Agent (OPA)** | Rego trong Git; PEP tại DU / gateway | ADR-004 · [SRS-19](../07-srs/SRS-19-rbac-matrix.md) |
| Bí mật / ký | **HashiCorp Vault** hoặc **OpenBao** | OpenBao nếu bắt buộc giấy phép mở tuyệt đối (BUSL) | [ADR-012](../05-adr/README.md#adr-012) |
| mTLS nội bộ | **Istio ambient** | Zero-trust east-west | ADR-011 |
| Ma trận quyền | **SRS-19** (tài liệu) | Không phải microservice riêng | SRS-19 |

---

## L3 — Lưu trữ dữ liệu

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| CSDL quan hệ | **PostgreSQL 17/18** + **CloudNativePG** | HA, WAL, PITR; schema riêng theo PH. Major theo bản CNPG hỗ trợ | [ADR-008](../05-adr/README.md#adr-008) |
| Object storage | **Garage** *(ưu tiên)* hoặc **SeaweedFS** / **Ceph RGW** | WORM / bằng chứng. **Không dùng MinIO** — community archive 25/04/2026 | [ADR-020](../05-adr/README.md#adr-020) |
| Cache | **Valkey** | Cache chia sẻ; Caffeine tại pod khi cần | ADR-008 |
| Migration schema (DU Boot) | **Liquibase** hoặc **Flyway** | Một tool/DU, không trộn | ADR-019 / IP-02 |

---

## L4 — Sự kiện & đồng bộ

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| Event backbone | **Apache Kafka** (operator **Strimzi**) | KRaft; xương sống bất đồng bộ | [ADR-005](../05-adr/README.md#adr-005) |
| Schema registry | **Apicurio Registry** | Avro/JSON Schema; tolerant reader | ADR-005 |
| CDC | **Debezium** | Bắt thay đổi CSDL di sản | ADR-005 |
| Outbox | Transactional outbox → Kafka | Trong DU Spring / Camel | IP-02 |

---

## L5 — Tích hợp & điều phối (Data Plane)

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| Integration engine | **Apache Camel 4.18.x LTS** | EIP duy nhất; không Spring Integration / NiFi. **Chỉ dùng dòng LTS** — xem bảng ghim | [ADR-001](../05-adr/README.md#adr-001) |
| Runtime Camel PROD | **Camel Quarkus native (GraalVM)** | DEV: JVM; deploy theo miền `lgsp-camel-*` | [ADR-002](../05-adr/README.md#adr-002) |
| Định nghĩa route | **Camel YAML DSL** | Git → Argo CD; designer chỉ sinh YAML | [ADR-010](../05-adr/README.md#adr-010), [ADR-015](../05-adr/README.md#adr-015) |
| Mẫu thiết kế / catalog | **Kaoto** (tham chiếu) | Không nhúng nguyên UI Kaoto | ADR-015 |
| Canvas designer | **XYFlow (`@xyflow/react`)** | UX cấu hình học n8n; NDV cố định | [ADR-017](../05-adr/README.md#adr-017) |
| Mô hình dữ liệu trung gian | **Canonical Data Model (CDM)** | Mapper 2n | [ADR-013](../05-adr/README.md#adr-013) |
| BPM dài hạn | **Flowable** (BPMN 2.0) | Camel = ngắn; Flowable = dài + người | [ADR-009](../05-adr/README.md#adr-009) |
| Adapter | PH-05 (REST/SOAP/JMS/File/CDC…) | Quản trị trên Boot; runtime nối Camel | SRS PH-05 |
| Kết nối quốc gia | PH-14 (NDXP/NGSP…) | Qua Data Plane | SRS PH-14 |

---

## L6 — Ứng dụng Control / nghiệp vụ (custom DU)

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| Framework | **Spring Boot 4.x** | Java 21 | [ADR-019](../05-adr/README.md#adr-019) |
| Module hóa | **Spring Modulith 2.x** | `api/` · `events/` · `internal/` + verify CI | ADR-019 · IP-01 |
| API contract | **OpenAPI 3.1** | Problem Details RFC 9457 | IP-02 |
| DU bắt buộc | `lgsp-control` · `lgsp-data` · `lgsp-process` · `lgsp-adapter-mgr` · (`lgsp-ai`) | Bản đồ PH → [IP-01](01-mo-hinh-phat-trien.md) | ADR-018 |
| Build | **Maven** hoặc **Gradle** (một chuẩn/repo) | Không trộn hai tool trong cùng DU | IP-02 |

**Cấm:** Spring Cloud Gateway thay APISIX; nhét route tích hợp nặng vào Boot thay Camel.

---

## L7 — Cổng biên (Edge)

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| API Gateway | **Apache APISIX** | TLS, JWT/OIDC, rate-limit, routing | [ADR-003](../05-adr/README.md#adr-003) |
| WAF | **Coraza** + OWASP CRS | Nhúng/đi kèm APISIX | ADR-003 |
| Ingress / TLS | Qua APISIX + chứng chỉ tổ chức | Chấm dứt TLS tại biên | Kiến trúc |

---

## L8 — Trải nghiệm người dùng

| Hạng mục | Công nghệ chốt | Ghi chú | ADR |
|---|---|---|---|
| Console quản trị | **React 19** + **TypeScript** + **Vite** | SPA | ADR-016 |
| UI kit | **Ant Design v6** | Token tinh chỉnh phong cách shadcn; sáng/tối | [ADR-016](../05-adr/README.md#adr-016) |
| Designer luồng | XYFlow + Ant Design + catalog Camel | Popup NDV cố định (UI-04-10) | ADR-015/017 |
| Developer Portal | **Backstage** | Catalog API / TechDocs | [ADR-006](../05-adr/README.md#adr-006) |
| FE types từ API | **openapi-typescript** (hoặc tương đương) | Cấm gọi path ngoài types | IP-02 |

---

## L9 — AI (khi kích hoạt PH-17)

| Hạng mục | Công nghệ chốt | Ghi chú | ADR / SRS |
|---|---|---|---|
| AI Gateway / quản trị | DU `lgsp-ai` | Không chặn go-live lõi | SRS PH-17 |
| MLOps / đánh giá | **MLflow** · **Evidently** (định hướng) | Theo SRS PH-17 | SRS PH-17 |
| Tích hợp LLM trong luồng | **camel-langchain4j** (khi cần) | Đi qua Camel, không bypass governance | Kiến trúc / PH-17 |

---

## Bản đồ nhanh: tầng → thành phần chính

| Tầng | Thành phần production |
|---|---|
| L1 | K8s · Cilium · Istio ambient · Argo CD · Kustomize · Harbor · Trivy · HPA/KEDA · OTel/LGTM |
| L2 | Keycloak · OPA · Vault/OpenBao · External Secrets |
| L3 | PostgreSQL 17/18 · CNPG · Garage/SeaweedFS (S3) · Valkey |
| L4 | Kafka/Strimzi · Apicurio · Debezium |
| L5 | Camel 4.18 LTS + Quarkus native · YAML DSL · Flowable · CDM · XYFlow designer |
| L6 | Spring Boot 4 + Modulith · OpenAPI 3.1 |
| L7 | APISIX · Coraza |
| L8 | React/Vite · Ant Design v6 · Backstage |
| L9 | MLflow · Evidently · camel-langchain4j *(khi bật)* |

---

## Mô hình triển khai mã (nhắc lại)

| Khối | Cách deploy production |
|---|---|
| COTS (L2–L4, L7 một phần, Portal) | Helm/Operator riêng — tách ngay |
| DU ứng dụng (L6) | Spring Boot jar/container theo DU |
| Camel (L5) | Nhiều deployment Quarkus native theo miền |
| Cấu hình route / policy | Git (YAML, Rego, Kustomize) → Argo CD |

Chi tiết → [IP-01](01-mo-hinh-phat-trien.md) · [ADR-018](../05-adr/README.md#adr-018).

---

## Phiên bản ghim (baseline sản xuất)

Các số dưới đây là **baseline** khi mở pha lập trình; nâng cấp theo lịch bảo trì, ghi vào changelog ADR nếu major.

> **Nguyên tắc ghim.** Chỉ ghim bản **LTS còn trong vòng đời hỗ trợ** tại thời điểm khóa.
> Trước mỗi lần mở pha lập trình hoặc nâng cấp lớn, **kiểm tra lại ngày EOL** — ghim một bản đã hết vòng đời
> đồng nghĩa chạy production không còn bản vá bảo mật, không qua được hồ sơ cấp độ ATTT.

| Thành phần | Baseline | Vòng đời / ghi chú |
|---|---|---|
| Java | **21 LTS** (Temurin) | Hỗ trợ tới ~2029. Java 25 LTS đã có (09/2025) — **chọn 21 có chủ đích**, xem [ADR-020](../05-adr/README.md#adr-020) |
| Apache Camel | **4.18.x LTS** | Hỗ trợ tới **17/02/2027**. **Không dùng 4.19/4.20/4.21** — 4.20 đã EOL 26/06/2026 |
| Camel Quarkus (platform) | **3.33.x** | Khớp Camel **4.18.x** · Quarkus **3.33.x** (W0 scaffold: 3.33.2 / Camel 4.18.2) |
| Spring Boot | **4.0.x** | GA 20/11/2025; yêu cầu tối thiểu Java 17, khuyến nghị LTS mới nhất |
| Spring Modulith | **2.0.x** | GA 21/11/2025, xây trên Spring Boot 4 + Framework 7 |
| Ant Design | **6.x** | GA 22/11/2025, tối ưu cho React 19 |
| React | **19.x** | — |
| Node (tooling FE) | **22 LTS** | — |
| PostgreSQL | **17.x** (tối thiểu), ưu tiên **18.x** nếu CloudNativePG trên cụm đích hỗ trợ | PG 18 GA 2025 (hiện 18.4). **Không khởi tạo mới trên 16.x** — rút ngắn tuổi thọ trước kỳ nâng cấp major |
| Object storage | Xem [ADR-020](../05-adr/README.md#adr-020) | MinIO community **đã archive 25/04/2026** — không còn là lựa chọn production |
| Kafka | Bản Strimzi hỗ trợ KRaft ổn định trên cụm đích | Kafka 4.0 đã bỏ hẳn ZooKeeper; Strimzi ≥ 0.46 bỏ hỗ trợ ZooKeeper |

**Kiểm chứng trước khi khóa.** Ba số dưới đây phụ thuộc cụm đích, **phải đối chiếu thực tế** chứ không lấy từ tài liệu này:

| Cần xác nhận | Vì sao |
|---|---|
| Phiên bản **CloudNativePG** có trên cụm | Quyết định PG major nào dùng được (17 hay 18) |
| Phiên bản **Strimzi** trên registry nội bộ | Quyết định Kafka major và chế độ KRaft |
| Bản **GraalVM** khớp Camel Quarkus 4.18 | Build native PROD (ADR-002) |

---

## Ngoài phạm vi / cấm thay thế im lặng

| Không dùng cho production LGSP | Thay bằng |
|---|---|
| Spring Integration / Apache NiFi (lõi) | Camel 4 |
| Spring Cloud Gateway (biên) | APISIX |
| Camunda thay Flowable *(đã loại)* | Flowable |
| Redis Stack thương mại làm cache bắt buộc | Valkey |
| Nhúng runtime n8n | Chỉ học UX; engine = Camel |
| Một uber-Camel chứa mọi miền | `lgsp-camel-<mien>` |
| Quarkus cho mọi DU ứng dụng | Spring Boot 4 (ADR-019); Quarkus **chỉ** Camel |

---

## Liên kết

| Tài liệu | Vai trò |
|---|---|
| [05-adr](../05-adr/README.md) | Lý do chọn từng công nghệ |
| [IP-01](01-mo-hinh-phat-trien.md) | DU / biên deploy |
| [IP-02](02-huong-dan-lap-trinh.md) | Chuẩn mã & gates |
| [02-architecture](../02-architecture/README.md) | Kiến trúc tổng thể |
| [04-deployment](../04-deployment/README.md) | Bước dựng hạ tầng |

---

## Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-03 | Khởi tạo bản chốt stack production đủ tầng L1–L9 |
| 2026-08-04 | **Rà soát vòng đời phiên bản** ([ADR-020](../05-adr/README.md#adr-020)): Camel **4.20 → 4.18 LTS** (4.20 đã EOL 26/06/2026) · PostgreSQL **16 → 17/18** · **bỏ MinIO** (archive 25/04/2026) → Garage/SeaweedFS/Ceph RGW · ghi rõ lý do giữ Java 21 · thêm nguyên tắc ghim và bảng "kiểm chứng trước khi khóa" |
