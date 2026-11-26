---
ma_tai_lieu: D03-02-PH06
ten: Thiết kế chi tiết phần mềm phân hệ PH-06 Dữ liệu chủ
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-data, kỹ sư dữ liệu và học máy, kiến trúc sư, ATTT, hội đồng thẩm định
phan_he: PH-06
mo_ta: Thiết kế chi tiết hiện thực 60 FR của PH-06 gồm cấu trúc mã module mdm, mô hình miền, 11 thành phần với khối đặc tả 10 mục, thuật toán chuẩn hóa tên tiếng Việt, gom nhóm, chấm điểm Fellegi–Sunter, sống sót thuộc tính, job Splink trên Kubernetes, bảy sơ đồ trình tự, đa tenant, bảo mật, xử lý lỗi, quan sát và vận hành.
tai_lieu_lien_quan: D02-03-PH06 FRS; D02-04-PH06 UC; D03-03-PH06 CSDL; D03-04-PH06 API; D03-06-PH06 Màn hình; D03-10 Thiết kế đa tenant
---

# D03-02-PH06 · Thiết kế chi tiết Dữ liệu chủ

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 60 FR của [D02-03-PH06](../../02-yeu-cau/frs/D02-03-PH06-frs-du-lieu-chu.md). Phân hệ nhận bản ghi công dân, tổ chức, địa chỉ từ nhiều nguồn, chuẩn hóa, đối sánh, hợp nhất thành **bản ghi vàng** (golden record) kèm nguồn gốc từng thuộc tính, rồi cung cấp lại cho HTTT có kiểm soát mục đích. Hệ cũ không có chức năng này, nên toàn bộ là thiết kế mới. Sáu quyết định chi phối thiết kế:

1. **Một module Modulith, hai đường đối sánh.** Toàn bộ phân hệ là module `mdm` của `dh-data` (Spring Boot 4, Spring Modulith, package `vn.datahub.data.mdm`), lưu ở schema `ph06_mdm` của `pg-core`. Đối sánh trực tuyến chạy trong PostgreSQL bằng `pg_trgm` và quy tắc xác định; đối sánh theo lô chạy bằng Splink trong Job Kubernetes, chỉ đọc bảng staging và chỉ ghi bảng kết quả (đề xuất ADR số 080 và 081).
2. **Máy chỉ đề xuất, người quyết định vùng nghi ngờ.** Điểm Fellegi–Sunter chia ba vùng; vùng giữa luôn vào hàng đợi, hợp nhất rủi ro cao cần người thứ hai (bốn mắt). Job lô vượt 5% cặp `MATCH` thì dừng chờ xác nhận.
3. **Mọi thay đổi bản ghi vàng đi qua một lối ghi duy nhất** (`GoldenWriter`): khóa cụm, ảnh chụp đầy đủ trước thay đổi, sống sót theo thuộc tính, lineage, outbox, trong một giao dịch. Nhờ đó hợp nhất, tách, sửa tay đều hoàn tác được trong 90 ngày (đề xuất ADR số 082 và 083).
4. **Sự kiện không mang dữ liệu cá nhân.** Bên nhận tra lại qua API với mục đích đã được PH-09 chấp thuận; không ghi được nhật ký truy cập thì không trả dữ liệu (đề xuất ADR số 084).
5. **Số định danh không bao giờ ở dạng rõ ngoài bộ nhớ ứng dụng.** Mã hóa envelope (ADR-032) cho giá trị, HMAC-SHA256 khóa theo tenant cho đối sánh xác định, khóa gom nhóm và staging; job Splink không thấy khóa nào.
6. **Datahub không ghi đè nguồn gốc.** Dữ liệu nhân thân từ CSDL quốc gia đến qua PH-14, thắng mọi nguồn địa phương (BR-06-003); đồng bộ tự dừng khi lệch quá 5%.

Tập nêu năm ADR đề xuất (số 080 đến 084), mười câu hỏi mở Q06-20…29 và mục "Đề nghị bổ sung cho FRS" (§13.5) cho các điểm thiết kế cần FRS và CSDL làm rõ.

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tài liệu này là thiết kế phần mềm ở mức đủ để kỹ sư viết mã và kiểm thử viên viết ca kiểm thử mà không phải đoán: cấu trúc gói, lớp chính, thuật toán, giao dịch, khóa, tên chỉ số. Phạm vi gồm 11 thành phần của `mdm` và job `mdm-splink`. Ngoài phạm vi: lược đồ bảng (D03-03-PH06), hợp đồng API (D03-04-PH06), màn hình (D03-06-PH06), quy tắc phân loại dữ liệu và chính sách che (PH-09), kết nối CSDL quốc gia (PH-14).

### 1.2. Người đọc

Kỹ sư `dh-data` đọc chương 3, 4, 5, 8; kỹ sư dữ liệu và học máy đọc 4.4 đến 4.6; kiến trúc sư và ATTT đọc 2, 6, 7, 4.14; SRE đọc 9 đến 11; hội đồng thẩm định đọc phần Tóm tắt và chương 13.

### 1.3. Quy ước trong tài liệu

Mã `FR-06-nnn`, `BR-06-nnn`, `NFR-06-nnn`, `ERR-06-nnn`, `EVT-06-nn`, `API-06-nnn` lấy từ FRS; tên bảng lấy từ DDL `ph06_mdm.sql` của D03-03-PH06. Tên chỉ số quan sát có tiền tố `datahub_mdm_` (FRS viết rút gọn `mdm_`, xem §13.5). Mã `PERM-06-*` ngoài ba quyền sẵn có ở D02-08 là các quyền FRS Phụ lục B đề nghị bổ sung. Số liệu giả định ghi "giả định" kèm cơ sở: tenant T01 khoảng 1,2 triệu dân, 25.000 tổ chức, 5 triệu bản ghi nguồn từ 20 nguồn (GĐ-06-01 của FRS).

### 1.4. Thuật ngữ và chữ viết tắt

Tập thiết kế dùng nhiều thuật ngữ như bản ghi vàng, ứng viên và blocking; bảng dưới giải thích từng thuật ngữ, kèm tên bảng dữ liệu tương ứng khi có.

| Thuật ngữ | Giải thích |
|---|---|
| Bản ghi vàng | Bản ghi đại diện tốt nhất cho một thực thể, sinh từ nhiều nguồn (`golden_record`) |
| Ứng viên | Bản ghi nguồn vừa nhận, chưa liên kết (`candidate_record`) |
| Blocking (gom nhóm) | Giảm số cặp phải so bằng cách chỉ so các bản ghi chung ít nhất một khóa |
| Fellegi–Sunter (FS) | Mô hình xác suất đối sánh: mỗi thuộc tính góp trọng số `log2(m/u)` theo mức so sánh |
| m, u | Xác suất một mức so sánh xảy ra khi hai bản ghi cùng thực thể (m) hoặc khác thực thể (u) |
| Sống sót (survivorship) | Quy tắc chọn giá trị thắng cho từng thuộc tính của bản ghi vàng |
| Ảnh chụp | Trạng thái đầy đủ của bản ghi vàng trước một thay đổi (`golden_history`) |
| HMAC theo tenant | Băm có khóa HMAC-SHA256, khóa riêng từng tenant, dùng để so khớp mà không lưu giá trị rõ |
| Khóa cụm | Khóa tư vấn PostgreSQL (advisory lock) bao quanh một nhóm bản ghi có thể bị gộp |
| Splink | Thư viện Python đối sánh xác suất theo mô hình Fellegi–Sunter, chạy trên DuckDB hoặc Spark |
| DS, DA, TA, TO | Người quản lý dữ liệu, quản trị dữ liệu, quản trị tenant, vận hành tenant (D02-08) |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2 và 3 nói vị trí và cấu trúc mã; chương 4 là mô hình miền và 11 thành phần; chương 5 là bảy sơ đồ trình tự; chương 6 đến 12 là đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, vận hành, kiểm thử; chương 13 là lộ trình, rủi ro, ADR đề xuất, câu hỏi mở.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Thiết kế dựa trên FRS, thiết kế CSDL, kiến trúc tổng thể và các quyết định kiến trúc; bảng dưới ghi từng tài liệu và phần nội dung mà tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH06 FRS | 60 FR, 33 BR, 20 NFR, mã lỗi, sự kiện, Phụ lục A enum |
| D03-03-PH06 CSDL | Schema `ph06_mdm`: 43 bảng, RLS, chỉ mục |
| D03-01 SAD §4, §6 | `dh-data`, Splink hoặc Zingg theo lô, `pg_trgm` |
| D03-09 | Namespace, node pool, định cỡ |
| D03-10 | `TenantContext`, `app.tenant_id`, RLS |
| D04-01 | Cấu trúc package, `CC-MOD-01…05`, ArchUnit |
| ADR-001, 003 | Spring Boot 4 và Modulith; PostgreSQL RLS |
| ADR-032 | Mã hóa envelope qua OpenBao transit |
| ADR-041, 042 | Idempotency hai tầng; inbox và outbox |
| ADR-046 | Phê duyệt bốn mắt dùng chung |
| ADR đề xuất số 080…084 | Mục 13.4 |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

`mdm` là một module của DU `dh-data`, chạy ở namespace `dh-control` (vùng Z3) cùng PH-07, PH-08, PH-09 (D03-09 §4). Job `mdm-splink` cũng chạy ở `dh-control` nhưng là pod riêng, tài khoản dịch vụ riêng, mạng chỉ mở tới PgBouncer của `pg-core` (Z5) và Garage (Z5); không mở ra Internet, không tới Kafka, OpenBao hay API nghiệp vụ. Lưu lượng vào đi qua APISIX (Z2) với OIDC và OPA (SEC-21, 26); lưu lượng sự kiện đi qua Kafka (Z5) bằng Debezium Outbox Event Router của nền tảng (không phải mã của `dh-data`).

### 2.2. Sơ đồ thành phần

Sơ đồ dưới cho thấy các module của PH-06 bên trong `dh-data`, Job Splink chạy riêng, và các hệ lân cận như APISIX, luồng PH-04, `pg-core`, Kafka, Valkey và OpenBao.

```{.mermaid caption="Sơ đồ thành phần của PH-06 trong dh-data và các hệ lân cận"}
flowchart TB
  subgraph Z2["Z2 · Biên"]
    AX["APISIX<br/>OIDC, OPA, limit-count"]
  end
  subgraph Z3["Z3 · dh-data (module mdm)"]
    WEB["web<br/>/api/mdm/v1"]
    ING["ingest + source"]
    NRM["normalize"]
    MON["match.online"]
    STW["steward"]
    GLD["golden + lineage + xref"]
    SRV["serve + export + subscription"]
    SYN["sync"]
    OPS["ops + scheduler"]
    BAT["match.batch<br/>launcher, applier"]
    MDL["model"]
  end
  JOB["Job K8s mdm-splink<br/>Python, DuckDB"]
  subgraph Z4["Z4 · dh-runtime"]
    P04["Luồng PH-04"]
  end
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph06_mdm")]
    K[("Kafka t68.mdm.*")]
    GA[("Garage")]
    VK[("Valkey")]
    BAO["OpenBao"]
  end
  P07["PH-07"]
  P09["PH-09"]
  P14["PH-14"]
  AX --> WEB
  P04 --> ING
  WEB --> ING --> NRM --> MON --> GLD
  MON --> STW --> GLD
  WEB --> SRV --> GLD
  WEB --> MDL
  GLD --> PG
  GLD -->|"outbox"| PG
  PG -->|"Debezium"| K
  BAT -->|"staging"| PG
  BAT -->|"khởi Job"| JOB
  JOB -->|"đọc staging, ghi kết quả"| PG
  JOB --> GA
  BAT --> GLD
  K --> ING
  K --> SYN
  P14 <--> K
  SYN --> ING
  NRM --> P07
  SRV --> P09
  NRM --> VK
  SRV --> VK
  GLD --> BAO
  SRV --> BAO
  OPS --> BAT
```

Sơ đồ cho thấy ba đường. Đường nạp đi từ nguồn qua `ingest`, `normalize`, `match.online` rồi tới `golden`; đây là đường nóng, chạy trong một tiến trình `dh-data`. Đường lô đi từ `match.batch` xuất staging, khởi Job Splink, nhận kết quả rồi áp từng cặp qua `golden`; Job không bao giờ chạm bảng bản ghi vàng. Đường phục vụ đi từ APISIX tới `serve`, qua PH-09 để che, qua OpenBao để giải mã, và ghi nhật ký truy cập trước khi trả. Đồng bộ quốc gia (`sync`) đi vòng qua Kafka và PH-14, đưa dữ liệu quốc gia vào đúng đường nạp như một nguồn mức 1.

### 2.3. Phụ thuộc với module và phân hệ khác

PH-06 gọi hoặc tiêu thụ sự kiện từ các phân hệ khác; bảng dưới ghi cách phụ thuộc vào từng phân hệ và hành vi khi phân hệ đó không khả dụng.

| Phân hệ, hệ thống | Chiều | Cách phụ thuộc | Khi không khả dụng |
|---|---|---|---|
| PH-07 Danh mục, ĐVHC | `mdm` gọi | `RdmLookupApi` (module cùng DU), đệm Valkey 1 giờ | ERR-06-021, ứng viên `NORMALIZATION_PENDING` |
| PH-09 Quyền riêng tư | `mdm` gọi | `PrivacyPolicyApi` đệm 5 phút | Chặt nhất: chỉ `PUBLIC` |
| PH-01 Đăng ký HTTT | tiêu thụ sự kiện | Inbox, trạng thái HTTT | Dùng ảnh chụp cuối |
| PH-04, PH-05 | gọi `mdm` | `POST /internal/…/candidates`, `:resolve` | Luồng tự xử lý lỗi |
| PH-10 Sự kiện | `mdm` phát, nhận | Topic `{tenant}.mdm.*`, lược đồ Apicurio | Outbox giữ, phát lại |
| PH-14 Kết nối quốc gia | hai chiều | Sự kiện Kafka và API nội bộ; không gọi thẳng CSDL quốc gia (BR-06-032) | ERR-06-106, tra cứu nội bộ vẫn chạy |
| OpenBao, Valkey, Garage | `mdm` gọi | Mã hóa, đệm, tệp | Xem §8.4 |

: Phụ thuộc của PH-06

### 2.4. Hiện trạng mã và đường chuyển

Repo có SRS cũ (13 FR) nhưng chưa có mã `mdm` và không có dữ liệu cần di trú. PH-06 thuộc đợt 3, sau PH-07 và PH-09 vì chuẩn hóa cần PH-07 và che cần PH-09.

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

Module nằm ở `apps/data/src/main/java/vn/datahub/data/mdm`, theo `CC-MOD-01…05` của D04-01: ba package `api`, `internal`, `events`; module khác chỉ import `api` và `events`. Mỗi gói con của `internal` là một năng lực; lớp trong gói có phạm vi package-private trừ lớp dịch vụ vào.

```text
vn/datahub/data/mdm/
|-- package-info.java          @ApplicationModule(allowedDependencies = {"rdm::api","privacy::api","shared"})
|-- api/                       MdmResolveApi, MdmGoldenLookupApi, dto/ (GoldenView, ResolveResult, ...)
|-- events/                    GoldenCreated, GoldenUpdated, GoldenMerged, GoldenSplit, GoldenRetired,
|                              GoldenRestored, XrefChanged, JobFinished, ... (EVT-06-01…15)
|-- internal/
    |-- model/        DomainService, ModelVersionService, IdentifierValidator, CompatibilityChecker,
    |                 ClassificationGate, BaselinePackInstaller, SchemaCompiler
    |-- source/       SourceService, SourcePriorityService, ApprovalGuard
    |-- ingest/       CandidateIngestService, IdempotencyGuard, VersionOrderGuard, FileIngestJob,
    |                 InternalIngestController, SourceEventConsumer, CandidateReprocessor
    |-- normalize/    NormalizationPipeline, VietnameseNameNormalizer, DateNormalizer, IdentifierNormalizer,
    |                 PhoneEmailNormalizer, AddressNormalizer, OrgNameNormalizer, AdminUnitClient, BlockKeyGenerator
    |-- matching/
    |   |-- online/   MatchOrchestrator, DeterministicMatcher, CandidateRetriever, FellegiSunterScorer,
    |   |             Comparators, ExclusionRuleEngine, ThresholdClassifier
    |   |-- rules/    RuleSetService, RuleSetEvaluator, LabelSetService, DryRunService
    |   |-- batch/    BatchJobService, StagingExporter, SplinkJobLauncher, ResultApplier, BatchSafetyGate, JobWatchdog
    |-- steward/      QueueItemFactory, PriorityCalculator, ClaimService, DecisionService, ApprovalService, SlaMonitor
    |-- golden/       GoldenWriter, SurvivorshipEngine, SnapshotWriter, MergeService, SplitService, UndoService,
    |                 ManualEditService, RetireService, ReapplyJob, ClusterLock, RiskClassifier
    |-- lineage/      LineageRecorder, XrefService, XrefLookup
    |-- serve/        GoldenQueryService, ResolveService, SearchService, MaskingFilter, AccessLogWriter,
    |                 ExportService, ExportFileWriter, UpdateSubscriptionService, EventPublisher
    |-- sync/         NationalSyncService, NationalChangeConsumer, ReconcileJob, UpSyncJob, DiscrepancyService, SyncBreaker
    |-- ops/          DashboardMetrics, JobScheduler, ProcessingLogService, SubjectRequestService,
    |                 RetentionPurger, TenantSettingService
    |-- crypto/       MdmCrypto (bọc dh-crypto), HmacKeyProvider, DekCache
    |-- web/          *Controller (REST /api/mdm/v1), MdmExceptionHandler, EtagSupport, IdempotencyFilter
    |-- persistence/  *Repository (Spring Data JPA), GoldenJdbcDao, TenantSession, OutboxWriter, InboxStore
    |-- config/       MdmProperties (@ConfigurationProperties "datahub.mdm"), MdmCacheConfig, MdmKafkaConfig
```

Mã Python của job nằm ngoài cây Java: `apps/data/jobs/mdm-splink/` gồm `mdm_splink/settings.py` (dựng cấu hình Splink từ bộ quy tắc), `train.py`, `predict.py`, `manifest.py`, `requirements.lock` (ghim Splink 4.x, DuckDB), `Dockerfile` (ảnh tối giản, người dùng không phải root, ký cosign theo SEC-56).

### 3.2. Quy tắc phụ thuộc

Ba luật ArchUnit riêng của module, ngoài bộ chung của D04-01: (1) `internal.serve`, `internal.sync` và `internal.web` ghi bản ghi vàng chỉ qua `GoldenWriter`; không gói nào khác import `GoldenRecordEntity` để ghi; (2) không lớp nào ngoài `internal.crypto` import `dh-crypto` hay gọi OpenBao; (3) không lớp nào trong `internal.matching.batch` import `internal.golden` trừ `ResultApplier`. Luật (1) bảo vệ BR-06-005: không có đường ghi nào bỏ qua ảnh chụp.

### 3.3. Giao diện công bố

Các module khác của `dh-data` chỉ được dùng PH-06 qua các giao diện công bố; bảng dưới ghi giao diện, bên dùng và phương thức chính của từng giao diện.

| Giao diện | Dùng bởi | Phương thức chính |
|---|---|---|
| `MdmResolveApi` | Module khác trong `dh-data` (PH-08) | `resolve(domain, attrs, mode, purpose)`, `goldenOf(domain, sourceCode, sourceKey)` |
| `MdmGoldenLookupApi` | PH-08, PH-09 | `get(domain, goldenId, purpose)`, `exists(domain, goldenId)` |
| Sự kiện miền `events/*` | PH-08, PH-13 | Phát qua `ApplicationEventPublisher` (Modulith) và outbox |
| REST `/api/mdm/v1`, `/internal` | HTTT, PH-04, PH-14 | API-06-001…096 |

: Giao diện công bố của module mdm

### 3.4. Danh sách thành phần được đặc tả

Bảng liệt kê 11 thành phần của chương 4 (mục 4.2 đến 4.12), lớp chính và FR hiện thực. Mỗi mục mở bằng khối đặc tả 10 mục. Mục 4.1 là mô hình miền dùng chung; 4.13 đến 4.15 là ba mối quan tâm xuyên suốt.

| Mục | Thành phần | Lớp chính | FR |
|---|---|---|---|
| 4.2 | `model` · Mô hình domain | `DomainService`, `ModelVersionService`, `IdentifierValidator`, `ClassificationGate` | FR-06-001…007 |
| 4.3 | `source`, `ingest` · Nguồn và nạp | `CandidateIngestService`, `IdempotencyGuard`, `VersionOrderGuard`, `SourceService` | FR-06-008…013, 016, 017 |
| 4.4 | `normalize` · Chuẩn hóa | `NormalizationPipeline`, `VietnameseNameNormalizer`, `AddressNormalizer`, `BlockKeyGenerator` | FR-06-014, 015, 019 |
| 4.5 | `match.online` · Đối sánh trực tuyến | `MatchOrchestrator`, `CandidateRetriever`, `FellegiSunterScorer`, `RuleSetService` | FR-06-018, 020, 021, 023…026 |
| 4.6 | `match.batch` · Đối sánh theo lô | `BatchJobService`, `StagingExporter`, `SplinkJobLauncher`, `ResultApplier` | FR-06-022, 056 |
| 4.7 | `steward` · Hàng đợi người quản lý | `QueueItemFactory`, `DecisionService`, `ApprovalService` | FR-06-027…032 |
| 4.8 | `golden` · Bản ghi vàng, sống sót | `GoldenWriter`, `SurvivorshipEngine`, `MergeService`, `SplitService`, `UndoService` | FR-06-033…042 |
| 4.9 | `lineage`, `xref` · Nguồn gốc, liên kết chéo | `LineageRecorder`, `XrefService` | FR-06-043…045 |
| 4.10 | `serve` · Cung cấp dữ liệu | `ResolveService`, `MaskingFilter`, `AccessLogWriter`, `ExportService`, `UpdateSubscriptionService` | FR-06-046…052 |
| 4.11 | `sync` · Đồng bộ quốc gia | `NationalSyncService`, `ReconcileJob`, `SyncBreaker` | FR-06-053, 054 |
| 4.12 | `ops` · Vận hành | `JobScheduler`, `SubjectRequestService`, `RetentionPurger`, `TenantSettingService` | FR-06-055, 057…060 |

: Danh sách thành phần được đặc tả của PH-06

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền có sáu aggregate: `DomainModel` (mô hình và khóa định danh), `MatchRuleSet`, `SurvivorshipRuleSet`, `GoldenRecord` (gồm thuộc tính, liên kết chéo), `StewardItem`, `GoldenOperation`. Ứng viên và job không phải aggregate vì chỉ có một người ghi (đường nạp, `BatchJobService`). Hình dưới là sơ đồ lớp rút gọn; bất biến (invariant) nằm ở bảng liền sau.

```{.mermaid caption="Sơ đồ lớp miền của PH-06"}
classDiagram
  class DomainModel {
    +domainCode
    +versionNo
    +status VersionStatus
    +attributes ModelAttribute[]
    +identifierRules IdentifierRule[]
    +submit()
    +approve(by)
    +supersede()
  }
  class MatchRuleSet {
    +versionNo
    +status
    +blockingKeys[]
    +rules MatchRule[]
    +autoMergeThreshold
    +reviewThreshold
    +activate(evaluation)
  }
  class GoldenRecord {
    +goldenId UUIDv7
    +status GoldenStatus
    +mergedInto
    +version
    +attributes GoldenAttribute[]
    +xrefs SourceXref[]
    +apply(change) Snapshot
  }
  class GoldenAttribute {
    +name
    +valueEnc
    +sourceCode
    +strategy
    +nationalAuthority
  }
  class SourceXref {
    +sourceCode
    +sourceKey
    +status XrefStatus
    +matchMethod
    +score
  }
  class StewardItem {
    +reason
    +riskLevel
    +priority
    +status QueueItemStatus
    +decide(d)
    +approve(a)
  }
  class GoldenOperation {
    +changeType
    +status OperationStatus
    +undoOf
    +riskLevel
  }
  DomainModel "1" --> "*" GoldenRecord : định nghĩa
  MatchRuleSet "1" --> "*" StewardItem : sinh
  GoldenRecord "1" *-- "*" GoldenAttribute
  GoldenRecord "1" *-- "*" SourceXref
  GoldenOperation "1" --> "*" GoldenRecord : tác động
  StewardItem "0..1" --> "0..1" GoldenOperation : dẫn tới
```

Hình cho thấy mọi thay đổi bản ghi vàng đi qua `GoldenOperation`; mục hàng đợi chỉ dẫn tới thao tác, không tự sửa.

| Aggregate | Bất biến | Kiểm tra ở |
|---|---|---|
| `DomainModel` | Mỗi domain đúng một phiên bản `ACTIVE`; `ACTIVE` không sửa (BR-06-017); thuộc tính DLCN phải `CONFIRMED` phân loại trước khi kích hoạt (BR-06-016) | `ModelVersionService.activate`, ràng buộc CSDL |
| `MatchRuleSet` | `autoMergeThreshold` ≥ 0,90 và ≥ `reviewThreshold` + 0,10 (BR-06-020); kích hoạt cần đánh giá `PASSED` trên ≥ 1.000 cặp (BR-06-021); luật loại trừ khóa xác định khác nhau không tắt được (BR-06-006) | `RuleSetService.activate` |
| `GoldenRecord` | Không xóa (BR-06-007); `MERGED` luôn có `mergedInto` trỏ tới bản không `MERGED`; có ảnh chụp cho mọi `version` > 1 (BR-06-005); hai bản `ACTIVE` không cùng giá trị băm định danh xác định (BR-06-001) | `GoldenWriter`, chỉ mục duy nhất `uq_golden_identifier_active` |
| `SourceXref` | `(sourceCode, sourceKey)` có tối đa một liên kết `ACTIVE` (BR-06-018) | Chỉ mục `uq_source_xref_active` |
| `StewardItem` | Một mục mở cho mỗi cặp không thứ tự; người đề nghị không duyệt (ERR-06-005) | `uq_steward_item_open_pair`, `ApprovalService` |
| `GoldenOperation` | Mỗi thao tác bị hoàn tác tối đa một lần | `uq_golden_operation_undo` |

: Bất biến của aggregate và nơi kiểm tra

### 4.2. Mô hình domain (`model`)

::: dac-ta
**Mục đích.** Quản lý domain `CITIZEN`, `ORGANIZATION`, `ADDRESS` và domain khai thêm: thuộc tính có kiểu, khóa định danh, phân loại dữ liệu, phiên bản có duyệt; sinh JSON Schema để kiểm bản ghi nạp.

**Lớp chính.** `DomainService`, `ModelVersionService`, `IdentifierValidator`, `CompatibilityChecker`, `ClassificationGate`, `BaselinePackInstaller`, `SchemaCompiler`.

**Đơn vị chạy.** `dh-data`, mọi bản sao.

**FR hiện thực.** FR-06-001…007; BR-06-001, 016, 017.

**Giao diện vào.** REST API-06-001…013 (`DomainController`); `MdmResolveApi` đọc mô hình đang `ACTIVE`.

**Phụ thuộc ra.** PH-09 (`PrivacyPolicyApi.classify`), PH-01 (trạng thái HTTT), `pg-core`.

**Dữ liệu.** `mdm_domain`, `domain_model`, `model_attribute`, `identifier_rule`.

**Sự kiện.** EVT-06-10 khi phiên bản `ACTIVE`; outbox cùng giao dịch.

**Lỗi và xử lý.** ERR-06-008, 009, 010, 011 (422, trả người gọi); ERR-06-021 (PH-09 không khả dụng, 503, không kích hoạt được).

**Quan sát.** `datahub_mdm_model_activation_total{domain,result}`; span `mdm.model.activate`.
:::

Chi tiết thiết kế:

`IdentifierValidator` là hàm thuần theo `IdentifierType`: `CCCD_12` kiểm 12 chữ số và mã tỉnh trong 3 số đầu, thế kỷ-giới tính ở số thứ tư; `MST_10_13` kiểm chữ số kiểm tra theo trọng số của Tổng cục Thuế; `CMND_9`, `MA_BHXH_10`, `MSDN` kiểm độ dài và ký tự. Quy tắc cụ thể lấy từ bảng cấu hình ở `identifier_rule`, không ghim cứng trong mã, vì thuật toán cần đối chiếu văn bản hiện hành (Q06-09). Kết quả là `IdentifierStatus` (`VALID`, `INVALID_FORMAT`, `INVALID_CHECKSUM`, `PLACEHOLDER` cho dãy như `000000000000`, `MISSING`).

`CompatibilityChecker` so hai phiên bản mô hình: thêm thuộc tính tùy chọn, nới ràng buộc là `NON_BREAKING`; đổi kiểu, bỏ thuộc tính, siết ràng buộc, đổi khóa định danh, đổi phân loại lên mức cao hơn là `BREAKING`. Sửa trực tiếp phiên bản `DRAFT` nhưng phá vỡ phiên bản kế thừa đã `ACTIVE` thì trả ERR-06-008. `ClassificationGate` chặn `submit` khi còn thuộc tính DLCN ở `PROPOSED` (ERR-06-010). `SchemaCompiler` biên dịch mô hình thành JSON Schema và đệm theo `(tenant, domain, versionNo)`; EVT-06-10 xóa đệm trên mọi bản sao (§4.15). `BaselinePackInstaller` nạp ba domain nền từ tài nguyên `resources/mdm/baseline/*.json` ở trạng thái `DRAFT`, chờ DA duyệt, và chỉ chạy lại không lỗi (idempotent theo mã domain).

### 4.3. Nguồn và nạp bản ghi (`source`, `ingest`)

::: dac-ta
**Mục đích.** Nhận bản ghi ứng viên từ năm kênh (API, luồng PH-04, sự kiện PH-10, tệp lô, đồng bộ quốc gia), kiểm lược đồ, chống trùng và sai thứ tự, rồi đẩy sang chuẩn hóa mà không bao giờ mất bản ghi đã nhận.

**Lớp chính.** `CandidateIngestService`, `IdempotencyGuard`, `VersionOrderGuard`, `FileIngestJob`, `InternalIngestController`, `SourceEventConsumer`, `CandidateReprocessor`, `SourceService`, `SourcePriorityService`.

**Đơn vị chạy.** `dh-data`, mọi bản sao; `FileIngestJob` chạy trên hàng đợi tác vụ nền.

**FR hiện thực.** FR-06-008…013, 016, 017; BR-06-004, 018, 028, 029.

**Giao diện vào.** API-06-014…029; `POST /internal/domains/{d}/candidates` (API-06-022); Kafka (inbox, nhóm `mdm-source-events`); tệp ở Garage.

**Phụ thuộc ra.** `normalize` (nội bộ), Valkey (khóa idempotency), Garage, PH-01.

**Dữ liệu.** `mdm_source`, `source_priority`, `source_priority_proposal`, `candidate_file`, `candidate_record`, `source_record_head`, `inbox_event`.

**Sự kiện.** EVT-06-07 gộp theo phút (chỉ số lượng); không phát theo từng ứng viên.

**Lỗi và xử lý.** ERR-06-012…019 (trả người gọi), ERR-06-015 (409), ERR-06-018 (413); ERR-06-110 (sự kiện sai lược đồ, vào `.dlq`).

**Quan sát.** `datahub_mdm_candidate_total{domain,source,status}`, `datahub_mdm_ingest_duration_seconds`, `datahub_mdm_dedup_total{kind}`.
:::

Chi tiết thiết kế:

Bước ghi ứng viên là điểm không mất dữ liệu (FRS 2.4): `CandidateIngestService` ghi `candidate_record` ở trạng thái `RECEIVED` và chốt giao dịch **trước** khi gọi `normalize`, nên lỗi ở bước sau chỉ để lại ứng viên chờ xử lý lại. Thứ tự kiểm tra trong một giao dịch ngắn: (1) kênh và nguồn: `source_code` phải `ACTIVE` cho domain (ERR-06-014); (2) lược đồ: validate JSON Schema (ERR-06-017); (3) `IdempotencyGuard` (§8.3); (4) `VersionOrderGuard`: đọc `source_record_head(domain, source, key).last_version` có khóa dòng; nhỏ hơn thì `SUPERSEDED` (BR-06-029), bằng thì `DUPLICATE` (BR-06-028), lớn hơn thì cập nhật `last_version` và đi tiếp; (5) `operation = DELETE` đi nhánh gỡ liên kết của FR-06-016 qua `XrefService.detachBySourceDelete`.

Kênh sự kiện dùng `@KafkaListener` với `DefaultErrorHandler` (thử lại 1 giây nhân đôi, 5 lần), ghi `inbox_event` cùng giao dịch với ứng viên (ADR-042); hết lượt thì chuyển topic `{topic}.dlq` và tăng `datahub_mdm_inbox_dlq_total`. Kênh tệp: `FileIngestJob` đọc tệp đã qua quét (Tika, ClamAV theo SEC-45) bằng luồng, kiểm công thức và macro (ERR-06-019), nạp theo lô 1.000 dòng, tối đa `06.ingest.rate-per-source` bản ghi mỗi phút; xem trước 100 dòng đầu để người dùng xác nhận. Hạn mức mỗi nguồn cài bằng `limit-count` ở APISIX cho API và bằng bộ đếm Valkey cho kênh còn lại (ERR-06-048).

### 4.4. Chuẩn hóa (`normalize`)

::: dac-ta
**Mục đích.** Đưa tên, ngày, số định danh, điện thoại, địa chỉ về dạng chuẩn so sánh được và sinh khóa gom nhóm, để hai cách viết cùng một người cho cùng kết quả.

**Lớp chính.** `NormalizationPipeline`, `VietnameseNameNormalizer`, `OrgNameNormalizer`, `DateNormalizer`, `IdentifierNormalizer`, `PhoneEmailNormalizer`, `AddressNormalizer`, `AdminUnitClient`, `BlockKeyGenerator`.

**Đơn vị chạy.** `dh-data`, đồng bộ trong luồng nạp; cũng dùng được không lưu (xem trước, resolve).

**FR hiện thực.** FR-06-014, 015, 019; BR-06-001, 015, 033.

**Giao diện vào.** `NormalizationPipeline.run(domainModel, rawAttrs, refDate)`; API-06-029 xem trước.

**Phụ thuộc ra.** PH-07 (`RdmLookupApi.adminUnitAt`, `convertCode`, `mapExternalCode`) qua đệm Valkey; `MdmCrypto` (HMAC).

**Dữ liệu.** Ghi `candidate_record.attrs_norm`, `name_norm`, `birth_year`, `admin_unit_code`, `identifier_*`, `block_keys`, `warnings`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-06-020 (cảnh báo, không chặn), ERR-06-021 (PH-07 hỏng: `NORMALIZATION_PENDING`, tự thử lại mỗi 5 phút tối đa 24 giờ).

**Quan sát.** `datahub_mdm_normalize_duration_seconds{domain}`, `datahub_mdm_normalize_warning_total{warning}`, `datahub_mdm_normalization_pending`.
:::

Chi tiết thiết kế:

**Thuật toán chuẩn hóa họ tên tiếng Việt** (`VietnameseNameNormalizer`, hàm thuần, bộ kiểm thử bảng giá trị ở §12):

```text
normalizeName(raw, cfg):
  s  = Normalizer.normalize(raw, NFC)                    // hợp nhất dấu tổ hợp
  s  = removeControlChars(collapseWhitespace(trim(s)))   // "Nguyễn  Văn  A" -> "Nguyễn Văn A"
  s  = canonicalTone(s, cfg.toneStyle)                   // hoà/hòa, thuý/thúy về một kiểu (mặc định OLD)
  tokens = split(s, ' ')                                 // mỗi tiếng một token, giữ nguyên chữ Đ, Ư, Ơ
  tokens = map(tokens, titleCaseVn)                      // "NGUYEN" -> "Nguyen", giữ dấu nếu có
  if isForeign(tokens): return {display, nameAscii, family: null, given: whole}   // tên nước ngoài, dân tộc một tiếng
  // họ đứng cuối (kiểu "Văn A Nguyễn"): đảo khi token cuối thuộc danh sách họ và token đầu thì không
  if last(tokens) in cfg.familyNames and first(tokens) not in cfg.familyNames:
      tokens = rotateRight(tokens); flag REORDERED
  family = longestPrefixIn(tokens, cfg.familyNames + cfg.compoundFamily)   // "Nguyễn Phúc", "Tôn Thất"
  given  = last(tokens); middle = tokens between
  nameAscii = lower(stripMarks(replace(s,'Đ','D','đ','d')))   // NFD rồi bỏ Mn, rồi NFC
  nameKey   = join('-', map([family]+middle+[given], phoneticClass))
  genderHint = middle[0] in {"Văn","Hữu","Đức"} ? M : middle[0] in {"Thị","Ngọc"} ? F : UNKNOWN   // chỉ gợi ý, không dùng so khớp
  return {display, familyName, middleName, givenName, nameAscii, nameKey, genderHint, flags}
```

`phoneticClass` gộp các cặp hay nhầm do vùng miền và gõ không dấu theo bảng sau (`nameAscii` chữ thường làm đầu vào), áp dụng cho mỗi tiếng:

| Vị trí | Mẫu | Lớp | Ví dụ |
|---|---|---|---|
| Đầu tiếng | `ch`, `tr` | `C` | Chinh, Trinh |
| Đầu tiếng | `x`, `s` | `S` | Xuan, Suan |
| Đầu tiếng | `d`, `gi`, `r` | `Z` | Dung, Giung, Rung |
| Cuối tiếng | `ng`, `n` | `N` | Hung, Hun |
| Mọi vị trí | `y`, `i` đứng một mình hoặc sau phụ âm | `I` | Thuy, Thui |

: Lớp âm vị của nameKey (giả định, hiệu chỉnh bằng tập nhãn)

Danh sách họ phổ biến (Nguyễn, Trần, Lê, Phạm, Hoàng, Huỳnh, Phan, Vũ, Võ, Đặng, Bùi, Đỗ, Hồ, Ngô, Dương, Lý) phủ khoảng 90% dân số (giả định, cơ sở: thống kê họ thường dùng), họ kép và họ ít gặp nằm trong `domain_model` để tỉnh bổ sung. `nameKey` chỉ dùng để sinh khóa gom nhóm B4 và hàm so sánh mức `FUZZY_LOW`, không bao giờ để kết luận khớp. `OrgNameNormalizer` tách tiền tố loại hình (`Công ty TNHH`, `CTCP`, `DNTN`) vào `orgFormToken`, so phần lõi tên.

**Ngày**: `DateNormalizer` thử lần lượt `dd/MM/yyyy`, `yyyy-MM-dd`, `yyyyMMdd`, `yyyy`; trả `LocalDate` kèm `DatePrecision` (`DAY`, `MONTH`, `YEAR`); giá trị giả `01/01/1900`, `00/00/0000`, ngày tương lai thành `MISSING` cộng cảnh báo `DATE_PLACEHOLDER`. Ngày chỉ có năm vẫn cho `birth_year` dùng gom nhóm. **Địa chỉ**: `AddressNormalizer` tra `AdminUnitClient` theo ngày tham chiếu `sourceUpdatedAt`; mã cũ chuyển sang mã mới (giữ `legacyAdminUnitCode`, BR-06-033); mã tách thành nhiều xã không tự chọn mà gắn `ADMIN_UNIT_SPLIT` và đối sánh ở cấp tỉnh; chuỗi tự do được tách theo từ khóa (`Xã`, `Phường`, `P.`, `TT.`) rồi tìm tên xã trong danh mục tỉnh nguồn bằng `similarity` ≥ 0,8 và kết quả duy nhất, nếu không để trống mã, gắn `ADDRESS_UNPARSED`.

**Khóa gom nhóm** (`BlockKeyGenerator`): mỗi biểu thức trong bộ quy tắc (hàm cho phép `prefix`, `year`, `soundexVn`, `hmac`, `concat`) được ước lượng thành chuỗi; thuộc tính `SENSITIVE` chỉ qua `hmac` nên khóa lưu dạng `"B3:" + hex(HMAC(k, tên_khóa|giá_trị))[0..24]`, vừa `varchar(72)` của cột `block_keys`. Bộ khóa mặc định cho `CITIZEN`: B1 `prefix(given,3)+year(dob)`, B2 `adminUnit+year(dob)`, B3 `hmac(phone)`, B4 `nameKey+province`. Khóa thiếu thuộc tính thì bỏ qua, không sinh khóa rỗng.

### 4.5. Đối sánh trực tuyến và bộ quy tắc (`matching.online`, `matching.rules`)

::: dac-ta
**Mục đích.** Cho mỗi ứng viên hoặc lời gọi resolve, tìm bản ghi vàng tương ứng: chắc chắn bằng khóa xác định, hoặc bằng điểm xác suất chịu được sai dấu và sai chính tả, và chia ba vùng `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH` (cộng `CONFLICT`).

**Lớp chính.** `MatchOrchestrator`, `DeterministicMatcher`, `CandidateRetriever`, `FellegiSunterScorer`, `Comparators`, `ExclusionRuleEngine`, `ThresholdClassifier`, `RuleSetService`, `RuleSetEvaluator`, `LabelSetService`, `DryRunService`.

**Đơn vị chạy.** `dh-data`, trong tiến trình nạp và resolve; đánh giá chạy ở tác vụ nền `ACCURACY_EVAL`.

**FR hiện thực.** FR-06-018…021, 023…026; BR-06-001, 002, 006, 015, 020, 021.

**Giao diện vào.** `MatchOrchestrator.match(candidate)`; API-06-030…040, API-06-071.

**Phụ thuộc ra.** PostgreSQL (`pg_trgm`, `fuzzystrmatch`), `crypto` (HMAC), bộ đệm bộ quy tắc.

**Dữ liệu.** Đọc `golden_record`, `golden_identifier`, `golden_attribute`, `source_xref`; ghi `match_result`; bộ quy tắc ở `match_rule_set`, `match_rule`, `evaluation_report`, `label_set`, `label_pair`.

**Sự kiện.** EVT-06-11 khi bộ quy tắc `ACTIVE`; chuyển ứng viên sang hàng đợi thì EVT-06-08 do `steward` phát.

**Lỗi và xử lý.** Quá 800 ms: `POSSIBLE_MATCH` lý do `TIMEOUT`, tăng `datahub_mdm_match_timeout_total`; ERR-06-112 (hai bản ghi cùng khóa, `CONFLICT`); ERR-06-022, 023, 024, 026 khi cấu hình.

**Quan sát.** `datahub_mdm_match_duration_seconds{method}`, `datahub_mdm_match_outcome_total{domain,outcome,method}`, `datahub_mdm_block_size`, `datahub_mdm_block_truncated_total`, `datahub_mdm_auto_rate`.
:::

Chi tiết thiết kế:

`MatchOrchestrator` chạy tuần tự bốn bước, dừng ở bước đầu tiên cho kết luận:

1. **Liên kết đã có**: tra `source_xref(sourceCode, sourceKey, ACTIVE)`; có thì kết luận `MATCH` phương thức `DETERMINISTIC` với bản ghi vàng đó, trừ khi khóa định danh đổi so với lần trước.
2. **Xác định**: nếu ứng viên có khóa `VALID` và `deterministic = true`, `DeterministicMatcher` tra `golden_identifier` theo `(type, value_hash)` trên bản `ACTIVE` hoặc `LOCKED`: một bản khớp thì `MATCH` điểm 1,00; hai bản thì `CONFLICT` (ERR-06-112); khóa khác khóa của bản đang liên kết thì `CONFLICT` lý do `IDENTIFIER_CONFLICT`.
3. **Loại trừ**: `ExclusionRuleEngine` loại ứng viên đích có khóa xác định cùng loại nhưng khác giá trị (BR-06-006).
4. **Xác suất**: `CandidateRetriever` lấy tập ứng viên đích, `FellegiSunterScorer` chấm, `ThresholdClassifier` phân vùng.

**Blocking trực tuyến.** Vì `golden_record` chỉ có chỉ mục trigram trên `name_norm` và chỉ mục `(admin_unit_code, birth_year)`, ba khối được hiện thực bằng SQL và hợp bằng `UNION` (tối đa 200 dòng sau cùng):

```sql
SET LOCAL pg_trgm.similarity_threshold = 0.30;
SET LOCAL statement_timeout = '800ms';                -- NFR-06-003
WITH q AS (SELECT :nameAscii AS n, :birthYear AS y, :adminUnit AS a, :phoneHash AS p)
SELECT g.id, similarity(g.name_norm, q.n) AS sim FROM golden_record g, q
 WHERE g.domain_code = :d AND g.status IN ('ACTIVE','LOCKED')
   AND ( (g.name_norm % q.n AND g.birth_year = q.y)                         -- khối B1
      OR (g.admin_unit_code = q.a AND g.birth_year = q.y)                   -- khối B2
      OR g.id IN (SELECT golden_id FROM golden_attribute
                   WHERE attribute_name = 'phone' AND value_hash = q.p) )   -- khối B3
 ORDER BY sim DESC NULLS LAST LIMIT 200;
```

`tenant_id` do RLS áp (§6). Khối B4 (`nameKey + tỉnh`) chỉ dùng ở job lô, vì golden chưa có cột khóa gom nhóm; thêm cột `block_keys` và chỉ mục GIN cho `golden_record` để đồng nhất hai đường là đề nghị ở §13.5. Khối vượt 2.000 dòng được cắt 200 dòng giống nhất và tăng `datahub_mdm_block_truncated_total`.

**Chấm điểm Fellegi–Sunter** (`FellegiSunterScorer`). Với mỗi thuộc tính `k` có hàm so sánh, `Comparators` trả mức `ComparisonLevel` (`EXACT`, `FUZZY_HIGH`, `FUZZY_LOW`, `DIFFERENT`, `MISSING`). Trọng số của mức là `w(k,l) = log2(m(k,l) / u(k,l))`; thuộc tính `MISSING` ở một bên có `w = 0`, tương đương bỏ khỏi tổng. Tổng trọng số và xác suất:

```text
W = log2(λ / (1 − λ)) + Σ_k w(k, level_k)          λ = xác suất tiên nghiệm hai bản ghi bất kỳ khớp
P = 2^W / (1 + 2^W)                                  điểm dùng để phân vùng, thuộc [0, 1]
vùng:  P ≥ autoMergeThreshold → MATCH   |   reviewThreshold ≤ P < autoMergeThreshold → POSSIBLE_MATCH   |   P < reviewThreshold → NO_MATCH
```

Trực tuyến đặt `λ = 1 / N` với `N` số bản ghi vàng `ACTIVE` của domain (một cặp khớp kỳ vọng trong khối); job lô học `λ` bằng Splink và ghi vào bộ quy tắc. Mỗi mức của hàm so sánh:

| Hàm | `EXACT` | `FUZZY_HIGH` | `FUZZY_LOW` | `DIFFERENT` |
|---|---|---|---|---|
| `NAME_VN` | `nameAscii` bằng và có dấu bằng | `nameAscii` bằng (khác dấu) hoặc Jaro–Winkler ≥ 0,92 | `similarity` ≥ 0,80 hoặc `nameKey` bằng | còn lại |
| `DATE_TOLERANCE` | cùng ngày | cách ≤ 2 ngày, hoặc đảo ngày–tháng | cùng tháng và năm | còn lại |
| `ADMIN_UNIT` | cùng xã | cùng huyện | cùng tỉnh | khác tỉnh |
| `PHONE`, `EXACT` | bằng (qua HMAC) | không có | không có | khác |
| `TRIGRAM` (tên pháp nhân lõi) | `similarity` ≥ 0,95 | ≥ 0,85 | ≥ 0,70 | còn lại |

: Mức so sánh của các hàm đối sánh

Ví dụ bằng số (giả định tham số, thay bằng giá trị học từ Splink): `m/u` của họ tên `FUZZY_HIGH` là 0,12/0,002 (w = +5,91), ngày sinh `EXACT` 0,90/0,0003 (w = +11,55), xã `EXACT` 0,70/0,007 (w = +6,64); với `N = 1,2 triệu` thì log tiên nghiệm là −20,2. Bản ghi "Nguyen Van A, 15/01/1990, xã 00004" so với bản ghi vàng có dấu: `W = 5,91 + 11,55 + 6,64 − 20,2 = +3,9`, `P ≈ 0,94`, nằm vùng `MATCH` nếu `autoMergeThreshold = 0,90`. Hai ứng viên cùng vượt ngưỡng tự hợp nhất, hoặc chênh nhau dưới 0,03, thì hạ thành `POSSIBLE_MATCH` lý do `MULTIPLE_CANDIDATES`. Dưới `minAttributes` thuộc tính có giá trị thì không bao giờ `MATCH` (BR-06-015).

Cùng bộ tham số m, u được lưu ở `match_rule` và đọc bởi cả `FellegiSunterScorer` (Java) lẫn `settings.py` (Splink), để điểm hai đường so sánh được với nhau. Một ca kiểm thử "tương đương" (§12) chấm 10.000 cặp mẫu bằng cả hai và đòi chênh lệch tuyệt đối ≤ 0,01.

`RuleSetService.activate` chỉ chạy khi `RuleSetEvaluator` đã ghi `evaluation_report` `PASSED` cho đúng phiên bản trên tập nhãn `EVALUATION` ≥ 1.000 cặp (precision ≥ 99,9%, recall ≥ 98%, BR-06-021); khi đánh giá hằng tháng không đạt và `06.match.auto-disable-on-fail = true`, `ThresholdClassifier` hạ mọi `MATCH` xác suất thành `POSSIBLE_MATCH` cho tới khi đạt lại.

### 4.6. Đối sánh theo lô (`matching.batch`, job `mdm-splink`)

::: dac-ta
**Mục đích.** Khử trùng toàn bộ dữ liệu khi nạp ban đầu và rà trùng định kỳ giữa các bản ghi vàng (việc trực tuyến không làm nổi), và huấn luyện tham số m, u từ dữ liệu thật, mà không để Job chạm bản ghi vàng.

**Lớp chính.** `BatchJobService`, `StagingExporter`, `SplinkJobLauncher`, `ResultApplier`, `BatchSafetyGate`, `JobWatchdog`; Python `mdm_splink.settings`, `train`, `predict`, `manifest`.

**Đơn vị chạy.** Phía điều khiển ở `dh-data` (một bản sao nắm job qua khóa tư vấn); Job K8s `mdm-splink` ở `dh-control`.

**FR hiện thực.** FR-06-022, 056; BR-06-022, 023; ADR đề xuất số 080.

**Giao diện vào.** API-06-041…044; lịch từ `job_schedule`.

**Phụ thuộc ra.** Kubernetes API (tạo `Job`, chỉ trong namespace `dh-control`), OpenBao (cấp tài khoản CSDL tạm), `pg-core`, Garage (tệp kết quả tóm tắt).

**Dữ liệu.** `match_job`, `match_staging`, `match_result`, `job_schedule`.

**Sự kiện.** EVT-06-09 khi job kết thúc; EVT-06-03 cho từng hợp nhất do `golden`.

**Lỗi và xử lý.** ERR-06-025 (409), ERR-06-101…105 (nội bộ, hiển thị ở UI-06-12).

**Quan sát.** `datahub_mdm_job_duration_seconds{job_type,status}`, `datahub_mdm_job_total{job_type,status}`, `datahub_mdm_batch_pairs{outcome}`, `datahub_mdm_batch_skipped_total{reason}`.
:::

Chi tiết thiết kế:

Vòng đời job theo FRS 4.5; mỗi chuyển trạng thái là một `UPDATE … WHERE status = :expected` (so sánh và hoán đổi) nên không hai tiến trình cùng đẩy một job. Trình tự (xem §5.2):

1. `BatchJobService.start` lấy khóa tư vấn `(tenant, domain, 'BATCH_MATCH')`; có job `QUEUED…APPLYING` khác thì ERR-06-025.
2. `StagingExporter` (`PREPARING`) ghi `match_staging(job_id, candidate_id|golden_id, fields, block_keys)` bằng `INSERT … SELECT` theo trang 50.000 dòng; `fields` chỉ chứa thuộc tính `matchable` đã chuẩn hóa, trường `SENSITIVE` ở dạng HMAC. Phạm vi `GOLDEN_VS_GOLDEN` xuất bản ghi vàng `ACTIVE`; `CANDIDATES_SINCE` xuất ứng viên từ mốc `since` cộng bản ghi vàng; `FULL_INITIAL` xuất mọi ứng viên chưa liên kết.
3. `SplinkJobLauncher` xin tài khoản CSDL tạm từ OpenBao (database secrets engine, vai `ph06_splink`, TTL = hạn tối đa + 15 phút) chỉ có `SELECT` trên `match_staging` và `INSERT` trên `match_result`, đặt `app.tenant_id` cố định; tạo `Job` K8s `mdm-splink-{jobId}` (cấu hình §9.3), truyền `jobId`, `tenant`, `ruleSetVersion`, `mode` qua biến môi trường, không truyền khóa.
4. Trong Job: `settings.py` dựng cấu hình Splink từ `match_rule` (mức so sánh, `blocking_rules_to_generate_predictions` lấy từ `block_keys`); `train.py` (khi `trainOnly` hoặc lịch huấn luyện) ước lượng `u` bằng lấy mẫu ngẫu nhiên (tối đa 10^7 cặp), ước lượng `m` bằng EM hai phiên theo hai khối `dob+adminUnit` và `nameKey+province`; `predict.py` chấm cặp, chỉ ghi cặp có `P ≥ reviewThreshold` vào `match_result` (`applied = false`), kèm điểm từng thuộc tính; `manifest.py` ghi `manifest.json` (số đếm, tham số m, u, λ, phiên bản Splink) lên Garage.
5. `JobWatchdog` (ShedLock, mỗi 30 giây) theo dõi `Job` qua Kubernetes API: `Failed`, `activeDeadlineSeconds` quá hạn (ERR-06-102), `OOMKilled` (ERR-06-103); đặt `FAILED`, xóa staging; không bản ghi vàng nào bị đổi.
6. `ResultApplier` đọc manifest, phân ba vùng. `BatchSafetyGate`: số cặp `MATCH` > `06.batch.safety-ratio` × số bản ghi vào thì `AWAITING_CONFIRMATION` và giao việc DA (ERR-06-105). Sau xác nhận, `APPLYING` áp từng cặp trong **giao dịch riêng** qua `GoldenWriter` với `MatchMethod = PROBABILISTIC_BATCH`; bỏ qua cặp đã có quyết định người (`negativeLink`, BR-06-023) hoặc bản ghi có `updated_at` sau thời điểm xuất (ERR-06-104, `skip_code`).
7. Xong: `SUCCEEDED` hoặc `PARTIALLY_SUCCEEDED`, xóa staging và dòng `match_result` đã áp quá 7 ngày theo chính sách lưu giữ, phát EVT-06-09.

Khối quá lớn (> 5.000 bản ghi) bị Splink bỏ và `manifest` ghi `oversizedBlocks` để người cấu hình đổi khóa gom nhóm (FR-06-019). Trên 5 triệu bản ghi vào, `mode = SPARK_LOCAL` chạy hồ sơ `xl` (§9.3); Spark nhiều nút là ngoài phạm vi (Q06-26).

### 4.7. Hàng đợi người quản lý dữ liệu (`steward`)

::: dac-ta
**Mục đích.** Biến mỗi kết luận không chắc chắn thành một việc rõ ràng, xếp theo mức khẩn, có người nhận, có hạn, có quyết định và duyệt bốn mắt khi rủi ro cao.

**Lớp chính.** `QueueItemFactory`, `PriorityCalculator`, `RiskClassifier`, `ClaimService`, `DecisionService`, `ApprovalService`, `SlaMonitor`.

**Đơn vị chạy.** `dh-data`; `SlaMonitor` và bộ nhả giữ việc chạy theo ShedLock.

**FR hiện thực.** FR-06-027…032; BR-06-002, 008, 019, 023.

**Giao diện vào.** `QueueItemFactory.openFor(matchResult)` từ `matching`; API-06-045…050; "Việc của tôi" (FR-00-070).

**Phụ thuộc ra.** `golden` (`MergeService`, `GoldenWriter`), PH-12 (việc), PH-13 (cảnh báo).

**Dữ liệu.** `steward_item`, `golden_operation`, `match_result`.

**Sự kiện.** EVT-06-08 khi tạo mục.

**Lỗi và xử lý.** ERR-06-005, 007, 027, 028, 030, 031.

**Quan sát.** `datahub_mdm_queue_open{domain,reason}`, `datahub_mdm_queue_age_seconds`, `datahub_mdm_queue_sla_breach_total`, `datahub_mdm_steward_decision_total{decision}`.
:::

Chi tiết thiết kế:

`PriorityCalculator` tính `priority = base(reason) + min(10, số liên kết nguồn của bản ghi vàng liên quan) + round(10 × độ gần ngưỡng tự hợp nhất)` với `base` theo FR-06-027 (`IDENTIFIER_CONFLICT` 90 đến `ORPHANED` 20), cắt ở 100. `RiskClassifier` hiện thực BR-06-019 thành năm điều kiện độc lập, thỏa một là `HIGH`: hợp nhất hai bản ghi vàng cùng có ≥ 3 liên kết; có thuộc tính quan trọng khác nhau; điểm < 0,95 với hợp nhất vàng–vàng; hợp nhất thủ công ≥ 3 bản ghi; tách bản ghi có ≥ 3 liên kết.

`ClaimService.claim` là một câu `UPDATE steward_item SET status='ASSIGNED', assignee=:u, hold_until=now()+interval '30 min' WHERE id=:id AND status='OPEN'`; số dòng bằng 0 nghĩa là người khác nhanh hơn (ERR-06-027). Phạm vi tổ chức kiểm bằng OPA trước khi gọi (ERR-06-028). `DecisionService.decide` chạy trong một giao dịch: kiểm lý do ≥ 20 ký tự (BR-06-008), kiểm `version` của hai bản ghi (đã đổi thì `CANCELLED` lý do `STALE`, ERR-06-030), rồi theo quyết định: `NO_MATCH` ghi `negativeLink` và `RESOLVED`; `MATCH` rủi ro thấp gọi `MergeService.merge` ngay; `MATCH` rủi ro cao tạo `golden_operation` `PENDING_APPROVAL`, mục sang `PENDING_APPROVAL`, khóa bản ghi `LOCKED`; `DEFER` đặt `defer_until`. `ApprovalService.approve` so `requested_by` với người duyệt (ERR-06-005), kiểm lại `version`, rồi gọi đúng thao tác trong giao dịch của việc duyệt (§5.3); từ chối trả mục về `ASSIGNED` cho người đề nghị và mở khóa. Nhắc DA sau 2 ngày làm việc, giao DA khác sau 5 ngày.

`SlaMonitor` (mỗi 15 phút) nâng ưu tiên mục quá hạn thêm 10, trả mục có `hold_until` đã qua về `OPEN`, phát cảnh báo khi `datahub_mdm_queue_open` > `06.queue.max-open` và giao DA phân công lại mục chưa nhận sau `06.queue.escalate-after-days`. Quá tải hàng đợi không bao giờ làm hệ thống tự quyết thay người (BR-06-002).

### 4.8. Bản ghi vàng và sống sót (`golden`)

::: dac-ta
**Mục đích.** Là lối ghi duy nhất của bản ghi vàng: tạo, cập nhật, hợp nhất, tách, hoàn tác, sửa tay, ngừng, khôi phục, áp lại sống sót, luôn có ảnh chụp trước, nguồn gốc từng thuộc tính và một sự kiện outbox cho mỗi thay đổi đã commit.

**Lớp chính.** `GoldenWriter`, `SurvivorshipEngine`, `SnapshotWriter`, `MergeService`, `SplitService`, `UndoService`, `ManualEditService`, `RetireService`, `ReapplyJob`, `ClusterLock`, `RiskClassifier`.

**Đơn vị chạy.** `dh-data`, mọi bản sao; áp lại hàng loạt chạy ở tác vụ nền.

**FR hiện thực.** FR-06-033…042; BR-06-003, 005, 006, 007, 009, 018, 024, 025, 029; ADR đề xuất số 082, 083.

**Giao diện vào.** `GoldenWriter.apply(GoldenChange)` từ `matching`, `steward`, `sync`; API-06-051…064.

**Phụ thuộc ra.** `lineage`, `crypto`, `OutboxWriter`.

**Dữ liệu.** `golden_record`, `golden_attribute`, `golden_identifier`, `source_xref`, `golden_operation`, `golden_history`, `survivorship_rule_set`, `survivorship_rule`.

**Sự kiện.** EVT-06-01…06 theo loại thay đổi.

**Lỗi và xử lý.** ERR-06-004, 006, 029, 031…036 (trả người gọi); ERR-06-111 (không ghi được lịch sử, hủy giao dịch, thử lại 3 lần giãn dần).

**Quan sát.** `datahub_mdm_golden_total{domain,status}`, `datahub_mdm_golden_operation_total{type,status}`, `datahub_mdm_golden_lock_wait_seconds`, `datahub_mdm_optimistic_retry_total`, `datahub_mdm_snapshot_bytes`.
:::

Chi tiết thiết kế:

`GoldenChange` là giá trị bất biến mô tả một thay đổi: loại (`GoldenChangeType`), `goldenIds`, ứng viên hoặc cặp liên quan, phương thức, điểm, ngữ cảnh thao tác (người, lý do, `operationId`). `GoldenWriter.apply` là **mẫu giao dịch duy nhất**:

```text
apply(change):
  BEGIN                                          -- SET LOCAL app.tenant_id (TenantSession)
    locks = ClusterLock.acquire(change)          -- §4.13: advisory theo khóa gom nhóm, rồi FOR UPDATE theo id tăng dần
    targets = load(change.goldenIds, FOR UPDATE)
    guard: mỗi target không MERGED/RETIRED (đã MERGED thì chuyển theo mergedInto), không LOCKED trừ thao tác duyệt
    before = SnapshotWriter.write(targets)       -- golden_history: thuộc tính, liên kết, version  [lỗi => ERR-06-111, ROLLBACK]
    after  = compute(change, targets)            -- tạo, liên kết, SurvivorshipEngine, đổi trạng thái
    persist(after); version += 1 chỉ khi có thuộc tính đổi
    LineageRecorder.record(after.changedAttributes)
    insert golden_operation (changeType, status APPLIED, ...)
    OutboxWriter.add(event(after))               -- cùng giao dịch, không chứa giá trị (BR-06-012)
  COMMIT                                         -- lỗi khóa lạc quan: thử lại tối đa 5 lần (§4.13)
```

**Sống sót thuộc tính** (`SurvivorshipEngine`, giả mã). Đầu vào: với mỗi thuộc tính `a`, danh sách giá trị hiện hành lấy từ các liên kết `ACTIVE` của bản ghi vàng (mỗi liên kết đóng góp giá trị mới nhất của nó); cấu hình `strategies[a]` (mặc định `NATIONAL_AUTHORITY → SOURCE_PRIORITY → MOST_RECENT → MOST_COMPLETE`).

```text
survive(a, values[], cfg):
  if exists v in values where v.manualOverride and v.validUntil > now: return v (MANUAL_OVERRIDE, đứng đầu)
  pool = values minus {v | v.dropped or v.valueMissing}
  for s in cfg.strategies[a]:
      case NATIONAL_AUTHORITY: pool = {v in pool | v.sourceKind == NATIONAL_DB} if not empty else pool
      case SOURCE_PRIORITY:    pool = argmin(pool, v -> priority(v.source, a))       // mức 1 tốt nhất, bảng đã duyệt
      case MOST_RECENT:        pool = argmax(pool, v -> v.sourceUpdatedAt)
      case MOST_COMPLETE:      pool = argmax(pool, v -> completeness(normalized(v)))
      case MOST_FREQUENT:      pool = argmax(pool, v -> count(sources having v.normalizedValue))
      case FIRST_VALUE:        pool = argmin(pool, v -> v.firstSeenAt)
      if |pool| == 1: return pool[0] with strategy = s
  // còn nhiều giá trị khác nhau sau mọi chiến lược
  if cfg.criticalConflictToQueue[a] and distinctNormalized(pool) > 1 and span(pool.sourceUpdatedAt) <= 24h:
      return KEEP_CURRENT + openQueueItem(CRITICAL_CONFLICT)     // giữ giá trị cũ, nhờ người quyết
  return pool sorted by (source, id)[0]                           // tất định, để hai lần tính ra cùng kết quả
```

Hai bảo đảm: kết quả **tất định** (cùng đầu vào cho cùng giá trị thắng, nhờ khóa sắp thứ tự cuối), và **đến trễ không thắng** (giá trị có `sourceVersion` nhỏ hơn bản mới nhất cùng nguồn đã bị `VersionOrderGuard` loại, BR-06-029). Thuộc tính `nationalAuthority` không bao giờ rơi khỏi `NATIONAL_AUTHORITY` ở đầu chuỗi (BR-06-025); khi giá trị địa phương lệch giá trị quốc gia, `sync` xử lý (§4.11), `GoldenWriter` không giữ giá trị địa phương. Giá trị `SENSITIVE` được so bằng `value_hash`, không giải mã trong vòng lặp.

**Hợp nhất** (`MergeService`, FR-06-037, 031): 2 đến 10 bản ghi, `survivorId` mặc định là bản nhiều liên kết nhất. Trình tự trong một lần `apply`: kiểm cùng domain, đều `ACTIVE`, không có hai khóa xác định khác nhau (ERR-06-029); `RiskClassifier` tính rủi ro; `HIGH` thì tạo thao tác `PENDING_APPROVAL`, khóa `LOCKED`, dừng; ngược lại hoặc sau duyệt: chụp ảnh mọi bản ghi, chuyển `source_xref` sang `survivorId`, hợp `golden_identifier`, chạy `survive` cho mọi thuộc tính, đặt các bản còn lại `MERGED` với `mergedInto`, phát EVT-06-03 với `survivorId`.

**Tách** (`SplitService`, FR-06-038): nhận `groups[]` mỗi nhóm là tập `xrefId`, nhóm đầu ở lại. Với mỗi nhóm sau, nếu `golden_operation` `MERGE` trước đó chứa bản `MERGED` có liên kết trùng nhóm thì **khôi phục** bản đó về `ACTIVE`, ngược lại tạo bản mới (UUID v7); chuyển liên kết, tính lại sống sót cho mọi bản, ghi `negativeLink` giữa các nhóm (để job lô không đề xuất gộp lại, BR-06-023), phát EVT-06-04.

**Hoàn tác** (`UndoService`, FR-06-039): tải `golden_history` trước thao tác; tìm thao tác phụ thuộc về sau trên cùng bản ghi (`golden_ids` GIN); có thao tác thủ công phụ thuộc mà `confirmDependents = false` thì ERR-06-033; quá `06.undo.window-days` thì tạo đề nghị chờ DA (ERR-06-034). Thi hành: khôi phục trạng thái và liên kết theo ảnh chụp, sau đó **phát lại** các cập nhật nguồn đến sau (đọc từ `candidate_record` theo `source_version` lớn hơn) qua `survive` để không mất dữ liệu mới, ghi thao tác `UNDO` trỏ `undo_of`, đánh dấu gốc `UNDONE`. Hoàn tác không xóa dòng lịch sử nào.

**Áp lại sống sót hàng loạt** (`ReapplyJob`, FR-06-042): chạy theo trang 500 `goldenId`, mỗi trang một giao dịch, `changeType = SURVIVORSHIP_REAPPLY`, phát một EVT-06-02 gộp mỗi trang; có chế độ xem trước chỉ tính, không ghi.

### 4.9. Nguồn gốc và liên kết chéo (`lineage`, `xref`)

::: dac-ta
**Mục đích.** Cho biết từng thuộc tính của bản ghi vàng lấy từ nguồn nào, giá trị đã qua những gì, và cho phép tra hai chiều giữa khóa nguồn và `goldenId`, gỡ hoặc chuyển liên kết khi phát hiện sai.

**Lớp chính.** `LineageRecorder`, `XrefService`, `XrefLookup`.

**Đơn vị chạy.** `dh-data`, mọi bản sao.

**FR hiện thực.** FR-06-043, 044, 045; BR-06-009, 018, 023.

**Giao diện vào.** `LineageRecorder.record(...)` từ `GoldenWriter`; API-06-065…069.

**Phụ thuộc ra.** `golden`, `serve` (che, nhật ký truy cập).

**Dữ liệu.** `attribute_lineage` (phân vùng theo thời gian), `source_xref`, `source_correction`.

**Sự kiện.** EVT-06-14 khi gỡ hoặc chuyển liên kết; EVT-06-15 khi tạo yêu cầu sửa tại nguồn.

**Lỗi và xử lý.** ERR-06-001, 032, 037, 039.

**Quan sát.** `datahub_mdm_xref_total{status}`, `datahub_mdm_lineage_rows_total`.
:::

Chi tiết thiết kế:

`LineageRecorder` ghi một dòng cho mỗi thuộc tính **đổi giá trị** (không ghi khi nguồn gửi lại y nguyên): tên thuộc tính, nguồn, chiến lược đã thắng, `sourceUpdatedAt`, mã ảnh chụp, người hoặc máy gây đổi; giá trị nhạy cảm chỉ lưu bản mã envelope và băm. Bảng phân vùng theo tháng để `RetentionPurger` bỏ cả phân vùng. `XrefService.detach` gỡ một liên kết: ghi ảnh chụp, đặt `DETACHED` lý do `MANUAL`, tính lại sống sót, và hoặc tạo bản ghi vàng mới (`RelinkMode.NEW_GOLDEN`) hoặc đối sánh lại (`REMATCH`); liên kết do người xác nhận không bị job tự tách (BR-06-023). `XrefLookup` phục vụ tra theo `(sourceCode, sourceKey)` bằng chỉ mục `uq_source_xref_active`; API tra lô chỉ nhận khóa nguồn trong thân, tối đa 1.000 khóa mỗi lần.

### 4.10. Cung cấp dữ liệu (`serve`)

::: dac-ta
**Mục đích.** Cho HTTT, PH-04 và người dùng tra cứu, resolve, tìm kiếm, xuất dữ liệu chủ và đăng ký nhận cập nhật, trong phạm vi mục đích PH-09 đã chấp thuận, che đúng mức, và luôn có vết.

**Lớp chính.** `GoldenQueryService`, `ResolveService`, `SearchService`, `MaskingFilter`, `AccessLogWriter`, `ExportService`, `ExportFileWriter`, `UpdateSubscriptionService`, `EventPublisher`.

**Đơn vị chạy.** `dh-data`, mọi bản sao; xuất chạy ở tác vụ nền.

**FR hiện thực.** FR-06-046…052; BR-06-010, 012, 013, 026, 027; ADR đề xuất số 084.

**Giao diện vào.** API-06-070…079; `MdmResolveApi`, `MdmGoldenLookupApi`.

**Phụ thuộc ra.** PH-09 (chính sách che, mục đích), OpenBao (giải mã), Garage (tệp xuất), Valkey (đệm chính sách, bộ đếm truy cập).

**Dữ liệu.** `golden_record`, `golden_attribute`, `access_log`, `export_request`, `update_subscription`, `outbox_event`.

**Sự kiện.** EVT-06-01…06, 14 qua outbox (do `golden` ghi, `EventPublisher` chỉ cấu hình lọc cho đăng ký).

**Lỗi và xử lý.** ERR-06-037, 038, 039, 040, 041, 042, 043, 048, 050; ERR-06-113 (giải mã lỗi, trả dạng che); ERR-06-109 (outbox quá số lần thử).

**Quan sát.** `datahub_mdm_resolve_total{domain,outcome}`, `datahub_mdm_resolve_duration_seconds{outcome}`, `datahub_mdm_access_log_failure_total`, `datahub_mdm_decrypt_failure_total`, `datahub_mdm_bulk_access_blocked_total`, `datahub_mdm_export_total{status}`.
:::

Chi tiết thiết kế:

Mọi phương thức trả giá trị thuộc tính đi qua một `ServingPipeline` gồm bốn bộ lọc theo thứ tự cố định:

1. `PurposeGuard`: yêu cầu `X-Purpose`, hỏi PH-09 (đệm 5 phút theo chủ thể và mục đích) danh sách thuộc tính được phép và kiểu che; thiếu thì ERR-06-037.
2. `BulkAccessGuard`: bộ đếm cửa sổ trượt Valkey theo `(người gọi, 10 phút)` đếm số `goldenId` khác nhau; vượt `06.access.bulk-threshold` thì ERR-06-038 và ghi vết đặc biệt (BR-06-013).
3. `MaskingFilter`: bỏ thuộc tính ngoài phạm vi (không trả `null`, để không lộ sự tồn tại); thuộc tính `SENSITIVE` chỉ giải mã khi được phép trả rõ, ngược lại che theo kiểu (`nationalId` giữ 3 số cuối, `phone` giữ 3 số đầu 2 số cuối, `dateOfBirth` chỉ năm, `email` giữ ký tự đầu và tên miền). PH-09 không khả dụng và không còn đệm thì áp chính sách chặt nhất (chỉ `PUBLIC`) kèm `X-Datahub-Masking: fallback`; OpenBao hỏng thì trả dạng che, ERR-06-113.
4. `AccessLogWriter`: ghi `access_log` (ai, tra gì, mục đích, thuộc tính trả rõ hay che) **trước** khi gửi phản hồi, trong cùng yêu cầu; ghi lỗi thì **không trả dữ liệu** (ERR-06-039, BR-06-010). Đây là điểm đóng (fail-closed) duy nhất của đường đọc.

`ResolveService.resolve` (§5.6) chuẩn hóa tại chỗ không lưu ứng viên, gọi `MatchOrchestrator` rồi trả `200` (`MATCH`), `202` (`POSSIBLE_MATCH`, tối đa 3 ứng viên chỉ `goldenId`, điểm, thuộc tính đã che), hoặc `404` ERR-06-050 kèm `outcome = NO_MATCH`; `LOOKUP_OR_QUEUE` mới tạo mục hàng đợi. Bản ghi `MERGED` trả `200` kèm `mergedInto`; `RETIRED` trả `410` ERR-06-001 biến thể "đã ngừng". `SearchService` đòi tiêu chí đủ hẹp: họ tên phải đi kèm ngày sinh, năm sinh hoặc xã (ERR-06-040); tìm theo số định danh chỉ khớp chính xác qua HMAC, không tìm theo tiền tố.

`ExportService` tạo yêu cầu `PENDING_APPROVAL`, cần chấp thuận của DO các nguồn liên quan và DA (BR-06-027); sau duyệt, `ExportFileWriter` ghi tệp theo luồng (`CSV`, `XLSX`, `JSONL`), chống chèn công thức bằng tiền tố `'` cho ô bắt đầu `=`, `+`, `-`, `@`, mã hóa tệp bằng khóa dữ liệu của tenant, chèn thủy vân (mã yêu cầu, người xuất) vào tên cột ẩn hoặc dòng đầu, lưu Garage với hạn tải 24 giờ (ERR-06-042 khi quá hạn), tối đa `06.export.max-rows`. `UpdateSubscriptionService` quản lý đăng ký nhận cập nhật: phạm vi `LINKED_ONLY` lọc theo `goldenId` có liên kết với nguồn của HTTT (bộ lọc ở PH-10, FR-10-048), `DOMAIN` cần duyệt.

**Sự kiện không chứa giá trị** (đề xuất ADR số 084): `OutboxWriter` kiểm bằng ràng buộc CSDL `ck_outbox_event_no_value` (từ chối khóa `value`, `attributes`, `identifier`, `name`, `dateOfBirth` ở thân) và bằng bộ kiểm thử hợp đồng lược đồ. Thân CloudEvents gồm `goldenId`, `domainCode`, `version`, `changeType`, `changedAttributes[]` (chỉ tên), `sourceCode`, `operationId`; khóa phân vùng là `goldenId` (hợp nhất dùng `survivorId`) để thứ tự theo bản ghi được giữ.

### 4.11. Đồng bộ CSDL quốc gia (`sync`)

::: dac-ta
**Mục đích.** Giữ dữ liệu chủ của tỉnh nhất quán với CSDL quốc gia: nhận dữ liệu quốc gia làm chuẩn cho thuộc tính nhân thân, đối chiếu hằng đêm, gửi lên thuộc tính địa phương khi được phép, và tự dừng khi lệch bất thường; luôn qua PH-14, không gọi thẳng.

**Lớp chính.** `NationalSyncService`, `NationalChangeConsumer`, `ReconcileJob`, `UpSyncJob`, `DiscrepancyService`, `SyncBreaker`.

**Đơn vị chạy.** `dh-data`; `ReconcileJob`, `UpSyncJob` chạy theo ShedLock một bản sao.

**FR hiện thực.** FR-06-053, 054; BR-06-003, 011, 025, 032.

**Giao diện vào.** Kafka từ PH-14 (inbox, nhóm `mdm-national-change`); API-06-080…084; lịch từ `job_schedule`.

**Phụ thuộc ra.** PH-14 (dịch vụ tra lô, nhận dữ liệu chiều lên), `ingest` (kênh `NATIONAL_SYNC`).

**Dữ liệu.** `national_sync_state`, `national_sync_run`, `national_discrepancy`, `inbox_event`.

**Sự kiện.** EVT-06-12, EVT-06-13.

**Lỗi và xử lý.** ERR-06-044, 045 (trả người gọi); ERR-06-106, 107, 108 (nội bộ, hiển thị ở UI-06-14).

**Quan sát.** `datahub_mdm_sync_run_total{direction,result}`, `datahub_mdm_sync_discrepancy_ratio`, `datahub_mdm_sync_paused`, `datahub_mdm_sync_lag_seconds`.
:::

Chi tiết thiết kế:

Chiều xuống không có đường riêng: `NationalChangeConsumer` biến mỗi thay đổi PH-14 thành bản ghi ứng viên kênh `NATIONAL_SYNC` của nguồn `QG-DANCU` hoặc `QG-DKDN` (mức tin cậy 1) rồi đưa vào đúng đường nạp, nên cùng chuẩn hóa, đối sánh, sống sót; thuộc tính thẩm quyền quốc gia thắng nhờ `NATIONAL_AUTHORITY`. Đối chiếu `ReconcileJob` gửi danh sách khóa qua PH-14 theo lô 1.000, nhận giá trị quốc gia, so với bản ghi vàng bằng `value_hash` (không giải mã), phân mức `CRITICAL` (nhân thân), `MAJOR`, `MINOR` và ghi `national_discrepancy`.

`SyncBreaker` tính `ratio = số lệch / số đã đối chiếu` của lượt; > `06.sync.pause-ratio` (5%) thì đặt `national_sync_state = PAUSED`, **không áp lệch nào của lượt đó**, phát EVT-06-13 và cảnh báo (ERR-06-107). Lệch thuộc tính thẩm quyền trong ngưỡng được áp tự động theo giá trị quốc gia; lệch khác vào danh sách xử lý của DS (`ACCEPT_NATIONAL`, `KEEP_LOCAL`, `REPORT_TO_NATIONAL`, `IGNORE`); `KEEP_LOCAL` cho thuộc tính thẩm quyền quốc gia bị từ chối (BR-06-025). Chiều lên chỉ gửi thuộc tính trong `06.sync.up-attributes` (mặc định rỗng, Q06-02); thuộc tính thẩm quyền quốc gia bị chặn ERR-06-045. Dữ liệu quốc gia tự mâu thuẫn (một CCCD hai ngày sinh) thì không áp và báo đơn vị quản lý qua PH-14 (ERR-06-108).

### 4.12. Vận hành (`ops`)

::: dac-ta
**Mục đích.** Cung cấp lịch job, bảng điều khiển, nhật ký xử lý và truy cập, tiếp nhận yêu cầu của chủ thể dữ liệu, dọn dữ liệu theo chính sách lưu giữ và quản lý tham số theo tenant.

**Lớp chính.** `DashboardMetrics`, `JobScheduler`, `ProcessingLogService`, `SubjectRequestService`, `RetentionPurger`, `TenantSettingService`.

**Đơn vị chạy.** `dh-data`; mọi tác vụ định kỳ dùng ShedLock (một bản sao chạy) và chạy lặp theo từng tenant (D03-10).

**FR hiện thực.** FR-06-055, 057…060; BR-06-014, 030, 031.

**Giao diện vào.** API-06-085…096; lịch từ `job_schedule`.

**Phụ thuộc ra.** PH-09 (yêu cầu chủ thể, sổ lưu giữ), PH-13, Valkey.

**Dữ liệu.** `job_schedule`, `processing_log`, `access_log`, `subject_request`, `source_correction`, `retention_policy`, `tenant_setting`, `shedlock`.

**Sự kiện.** EVT-06-15 khi chuyển yêu cầu sửa tại nguồn.

**Lỗi và xử lý.** ERR-06-046, 047, 049; ERR-06-114 (đối tượng bị giữ pháp lý, bỏ qua khi dọn).

**Quan sát.** `datahub_mdm_purge_rows_total{object,action}`, `datahub_mdm_dsr_open{type}`, `datahub_mdm_setting_change_total`.
:::

Chi tiết thiết kế:

`JobScheduler` đọc `job_schedule` (cron theo tenant) mỗi phút dưới khóa ShedLock `mdm-scheduler` và tạo job `QUEUED`; FRS 2.4 nêu Quartz cluster nhưng DDL đã có `shedlock` và `job_schedule`, nên thiết kế chọn ShedLock cho đồng nhất với PH-04, PH-05, PH-07 (đề nghị ở §13.5). `RetentionPurger` dọn theo `retention_policy` bằng ba hành động `DELETE`, `ANONYMIZE`, `ARCHIVE_COLD` theo lô 10.000 dòng, bỏ phân vùng cũ cho `attribute_lineage` và `access_log`; đối tượng có giữ pháp lý bị bỏ qua và ghi ERR-06-114; nhật ký truy cập giữ 12 tháng trực tuyến rồi chuyển WORM 5 năm (BR-06-031). `SubjectRequestService` xác minh danh tính (ERR-06-046), chuyển yêu cầu `RECTIFICATION` thành `source_correction` gửi nguồn (BR-06-014) và đặt bản ghi vàng `LOCKED` khi yêu cầu `RESTRICTION`. `TenantSettingService` kiểm miền giá trị của 13 tham số (ERR-06-047) và phát lệnh xóa đệm tham số.

### 4.13. Xử lý đồng thời

Có bốn nguồn đồng thời: hai ứng viên cùng một thực thể đến cùng lúc (tạo trùng bản ghi vàng), hai thao tác cùng bản ghi vàng, người dùng sửa cùng bản ghi, job lô áp kết quả lúc có cập nhật trực tuyến. Thiết kế dùng ba lớp khóa theo thứ tự cố định để không bế tắc.

| Lớp | Cơ chế | Phạm vi | Dùng ở |
|---|---|---|---|
| 1. Khóa cụm | `pg_advisory_xact_lock(hashtextextended(concat_ws(':', :tenant, :domain, :clusterKey), 0))` | Mọi khóa gom nhóm và băm định danh của ứng viên, **sắp tăng dần** rồi lấy lần lượt | Tạo bản ghi vàng mới, hợp nhất tự động, resolve `LOOKUP_OR_QUEUE` |
| 2. Khóa dòng | `SELECT … FROM golden_record WHERE id = ANY(:ids) ORDER BY id FOR UPDATE` | Mọi bản ghi vàng bị đổi, **sắp theo id tăng dần** | `GoldenWriter` |
| 3. Khóa lạc quan | Cột `version`, `If-Match` bằng `ETag`, `UPDATE … WHERE version = :v` | Sửa tay, quyết định hàng đợi, cấu hình | API ghi do người dùng |

: Ba lớp khóa của xử lý đồng thời

`ClusterLock.acquire` lấy khóa lớp 1 trước (chờ tối đa 5 giây, hết thì thử lại cả giao dịch), rồi lớp 2. Khóa lớp 1 làm hai ứng viên trùng nhau xếp hàng nên người thứ hai thấy bản ghi vàng mà người thứ nhất vừa tạo và `MATCH` thay vì tạo bản thứ hai; hai ứng viên không chung khóa gom nhóm nào chạy song song hoàn toàn. Với `GoldenWriter` từ đường nạp, xung đột `version` (người dùng sửa cùng lúc) được thử lại tối đa 5 lần với chờ ngẫu nhiên 20 đến 100 ms rồi báo ERR-06-004; với API người dùng, xung đột trả `409` ngay cho người gọi tải lại. Job lô áp từng cặp bằng cùng `GoldenWriter` nên tuân theo các khóa này; cặp có bản ghi đã đổi sau lúc xuất staging bị bỏ qua (ERR-06-104) thay vì ghi đè. Chỉ số `datahub_mdm_golden_lock_wait_seconds` và `datahub_mdm_optimistic_retry_total` cho thấy tranh chấp; cảnh báo khi p99 chờ khóa > 1 giây.

### 4.14. Mã hóa và băm số định danh

Thuộc tính `SENSITIVE` (số định danh, ngày sinh đầy đủ, điện thoại, thư điện tử, địa chỉ chi tiết) được bảo vệ hai lớp, hiện thực trong gói `crypto` bọc thư viện chung `dh-crypto` (ADR-032, SEC-31, SEC-34); không gói nào khác gọi OpenBao (luật ArchUnit §3.2).

| Mục đích | Cơ chế | Cột |
|---|---|---|
| Lưu bí mật, giải mã khi được phép | Envelope: KEK `transit/keys/dh-{tenant}-pii`, DEK từ `transit/datakey`, AES-256-GCM, AAD gồm `tenant_id`, tên bảng, tên cột, `id` dòng | `*_enc`, `*_kid` (`raw_enc`, `value_enc`) |
| So khớp xác định, gom nhóm, staging | HMAC-SHA256, khóa riêng của tenant, đầu vào chuẩn tắc gồm `domainCode`, `identifierType`, giá trị chuẩn hóa nối bằng dấu gạch chéo | `value_hash`, `identifier_hash`, `block_keys` |

: Hai cơ chế bảo vệ trường nhạy cảm

Khóa HMAC của tenant được sinh một lần, cất ở OpenBao KV (`secret/dh/{tenant}/mdm/hmac`, có phiên bản), `HmacKeyProvider` tải khi khởi động và làm mới mỗi 5 phút; giữ khóa trong bộ nhớ là cần thiết vì mỗi ứng viên cần vài chục phép băm và một lượt gọi mạng cho mỗi phép là không chịu nổi ở 1.000 bản ghi mỗi giây (NFR-06-004). Đổi lại, quyền đọc khóa chỉ cấp cho tài khoản dịch vụ `dh-data`, không cấp cho Job Splink: job chỉ thấy chuỗi băm. `DekCache` giữ DEK đã giải bọc tối đa 5 phút theo SEC-31. Hệ quả: băm HMAC chỉ so khớp **chính xác** (không tìm theo tiền tố), và đổi khóa HMAC buộc tính lại băm bằng job `REENCRYPT` (Q06-27). Nhật ký ứng dụng che theo chú thích `@Classified` (SEC-32); không bao giờ ghi giá trị rõ hay băm của định danh vào log, trace hay nhãn chỉ số.

### 4.15. Bộ đệm

Bảng dưới ghi từng loại bộ đệm, nơi đặt, dạng khóa, thời hạn và điều kiện xóa, để biết dữ liệu nào có thể cũ và cũ trong bao lâu.

| Bộ đệm | Nơi | Khóa | Hạn | Xóa khi |
|---|---|---|---|---|
| Mô hình domain biên dịch, bộ quy tắc, cấu hình sống sót | Caffeine mỗi bản sao | `(tenant, domain, version)` | Đến khi đổi | Nhận EVT-06-10, EVT-06-11, lệnh Valkey pub/sub |
| Mã ĐVHC tại ngày, ánh xạ mã ngoài (PH-07) | Valkey | `mdm:{tenant}:adm:{code}:{date}` | 1 giờ | Hết hạn |
| Chính sách che, mục đích (PH-09) | Valkey | `mdm:{tenant}:pol:{subject}:{purpose}` | 5 phút | Hết hạn, sự kiện đổi chính sách |
| Idempotency | Valkey cộng bảng CSDL | `mdm:{tenant}:idem:{source}:{key}` | 24 giờ | Hết hạn |
| Bộ đếm truy cập hàng loạt | Valkey | `mdm:{tenant}:bulk:{subject}` | 10 phút trượt | Hết hạn |
| DEK đã giải bọc | Bộ nhớ | `(tenant, kid)` | 5 phút | Hết hạn |
| Bản ghi vàng theo ID (chỉ phần không nhạy cảm: trạng thái, `mergedInto`, `version`) | Caffeine | `(tenant, domain, goldenId)` | 30 giây | Ghi của `GoldenWriter` trên bản sao đó, hết hạn |

: Bộ đệm của PH-06

Hai nguyên tắc: **không đệm kết quả resolve hay giá trị thuộc tính**, vì mỗi lượt trả phải có bản ghi `access_log` (BR-06-010) và phải theo chính sách che hiện hành; và mọi khóa Valkey có tiền tố `tenant` để một sự cố cấu hình không trộn dữ liệu giữa tenant. Khi Valkey ngừng, từng bộ đệm lui về nguồn: PH-07 và PH-09 bị gọi trực tiếp (chậm hơn), idempotency lui về bảng CSDL, bộ đếm hàng loạt đếm từ `access_log`.

## 5. Biểu đồ tuần tự

Bảy sơ đồ phủ các luồng nhiều bước hoặc nhiều thành phần của FRS; mỗi sơ đồ ghi FR liên quan và một đoạn nói điểm cần chú ý.

### 5.1. Nạp, chuẩn hóa, đối sánh, sống sót, phát sự kiện (FR-06-010, 014, 015, 016, 020, 021, 034, 050)

Sơ đồ dưới cho thấy đường đi của một ứng viên từ lúc nguồn gửi đến khi có bản ghi vàng và sự kiện trên Kafka: lưu `RECEIVED`, chuẩn hóa, đối sánh, sống sót rồi ghi outbox.

```{.mermaid caption="Nạp ứng viên đến bản ghi vàng và sự kiện outbox (FR-06-010, 014, 015, 016, 020, 021, 034, 050)"}
sequenceDiagram
  participant S as Nguồn
  participant I as ingest
  participant N as normalize
  participant P7 as PH-07
  participant M as match.online
  participant W as GoldenWriter
  participant PG as ph06_mdm
  participant D as Debezium
  participant K as Kafka
  S->>I: POST candidates, Idempotency-Key, sourceVersion
  I->>PG: ghi RECEIVED, kiểm trùng và thứ tự, COMMIT
  I-->>S: 202 candidateId
  I->>N: chuẩn hóa
  N->>P7: mã ĐVHC tại ngày tham chiếu (đệm Valkey)
  P7-->>N: mã hiện hành
  N->>PG: NORMALIZED, block_keys, warnings
  N->>M: match
  M->>PG: tra xref, khóa xác định, rồi pg_trgm
  M-->>W: MATCH hoặc NO_MATCH, điểm
  W->>PG: BEGIN, khóa cụm, FOR UPDATE
  W->>PG: ảnh chụp, sống sót, lineage, golden_operation
  W->>PG: outbox_event, COMMIT
  PG-->>D: đọc WAL outbox
  D->>K: t68.mdm.golden.created.v1, khóa goldenId
```

Điểm cần chú ý: ứng viên được chốt ở trạng thái `RECEIVED` trước khi chuẩn hóa nên không mất dữ liệu; bản ghi vàng, lịch sử và sự kiện cùng một giao dịch nên không có sự kiện "ma" (không bản ghi) hay bản ghi không sự kiện. `POSSIBLE_MATCH` rẽ sang `steward` thay vì `GoldenWriter` (xem §4.7).

### 5.2. Job đối sánh theo lô bằng Splink (FR-06-022, 056)

Sơ đồ dưới cho thấy job đối sánh theo lô: dữ liệu được đưa vào bảng staging, Job Splink chấm cặp, rồi bộ áp kết quả ghi từng cặp vào bản ghi vàng, có bước DA xác nhận nếu số MATCH vượt ngưỡng.

```{.mermaid caption="Job đối sánh theo lô và áp kết quả (FR-06-022, 056)"}
sequenceDiagram
  actor TO
  participant B as BatchJobService
  participant PG as ph06_mdm
  participant BAO as OpenBao
  participant KA as Kubernetes API
  participant J as Job mdm-splink
  participant GA as Garage
  participant R as ResultApplier
  actor DA
  TO->>B: POST match-jobs BATCH_MATCH
  B->>PG: khóa tư vấn, job QUEUED rồi PREPARING
  B->>PG: INSERT match_staging, trường nhạy cảm dạng HMAC
  B->>BAO: xin tài khoản CSDL tạm vai ph06_splink
  BAO-->>B: user, mật khẩu, TTL
  B->>KA: tạo Job mdm-splink-jobId, RUNNING
  J->>PG: SELECT match_staging
  J->>J: ước lượng u, m (EM), chấm cặp trong khối
  J->>PG: INSERT match_result, applied=false
  J->>GA: manifest.json, số đếm, tham số
  KA-->>B: Job Complete
  B->>R: đọc manifest, phân ba vùng
  alt MATCH vượt 5% số bản ghi vào
    R-->>DA: việc xác nhận, AWAITING_CONFIRMATION
    DA->>R: xác nhận
  end
  loop mỗi cặp, giao dịch riêng
    R->>PG: GoldenWriter.apply PROBABILISTIC_BATCH hoặc steward_item
  end
  R->>PG: SUCCEEDED, xóa staging, outbox EVT-06-09
```

Điểm cần chú ý: Job chỉ có hai quyền CSDL (đọc staging, thêm kết quả) và không có đường tới Kafka, OpenBao hay API; mọi hiệu lực lên bản ghi vàng đi qua `ResultApplier` và `GoldenWriter` nên có ảnh chụp, lineage, sự kiện như đường trực tuyến.

### 5.3. Hợp nhất rủi ro cao có duyệt bốn mắt (FR-06-030, 031, 037)

Sơ đồ dưới cho thấy một quyết định MATCH rủi ro cao chưa hợp nhất ngay mà khóa bản ghi chờ DA duyệt, và chỉ thi hành khi người duyệt khác người đề nghị.

```{.mermaid caption="Hợp nhất rủi ro cao có duyệt bốn mắt (FR-06-030, 031, 037)"}
sequenceDiagram
  actor DS
  actor DA
  participant D as DecisionService
  participant RC as RiskClassifier
  participant A as ApprovalService
  participant W as GoldenWriter
  participant PG as ph06_mdm
  DS->>D: quyết định MATCH, lý do tối thiểu 20 ký tự
  D->>RC: tính rủi ro BR-06-019
  RC-->>D: HIGH
  D->>PG: golden_operation PENDING_APPROVAL, mục PENDING_APPROVAL, bản ghi LOCKED
  D-->>DS: 202 operationId
  Note over DA: việc xuất hiện ở Việc của tôi
  DA->>A: approve operationId
  A->>A: requested_by khác người duyệt, nếu không ERR-06-005
  A->>PG: kiểm version hai bản ghi chưa đổi, nếu không ERR-06-030
  A->>W: apply MERGE trong giao dịch duyệt
  W->>PG: ảnh chụp, chuyển xref, sống sót, MERGED, mở khóa
  W->>PG: outbox EVT-06-03 mergedIds, survivorId
  A-->>DA: 200 APPLIED
```

Điểm cần chú ý: kiểm tra "người duyệt khác người đề nghị" nằm ở máy chủ (`ApprovalService`), không dựa vào giao diện; trong lúc chờ, bản ghi `LOCKED` không nhận hợp nhất hay sửa tay khác (ERR-06-031).

### 5.4. Tách bản ghi vàng (FR-06-038)

Sơ đồ dưới cho thấy việc tách một bản ghi vàng thành nhiều bản ghi: lưu ảnh chụp bản gốc, chia lại liên kết nguồn, tính lại sống sót và ghi `negativeLink` giữa các nhóm.

```{.mermaid caption="Tách bản ghi vàng thành nhiều bản ghi (FR-06-038)"}
sequenceDiagram
  actor DS
  participant S as SplitService
  participant W as GoldenWriter
  participant PG as ph06_mdm
  DS->>S: split goldenId, groups, reason
  S->>PG: kiểm phân bổ đủ và duy nhất, kiểm số liên kết
  S->>S: tính rủi ro, HIGH thì sang duyệt như 5.3
  S->>W: apply SPLIT
  W->>PG: khóa cụm, FOR UPDATE theo id tăng dần
  W->>PG: ảnh chụp bản gốc
  W->>PG: nhóm sau: khôi phục bản MERGED cũ hoặc tạo bản mới
  W->>PG: chuyển xref, sống sót lại mọi bản, ghi negativeLink
  W->>PG: golden_operation SPLIT, outbox EVT-06-04
  W-->>DS: 200 operationId, resultGoldenIds
```

Điểm cần chú ý: `negativeLink` giữa các nhóm ngăn job lô đề xuất gộp lại ở lần chạy sau (BR-06-023).

### 5.5. Hoàn tác thao tác (FR-06-039)

Sơ đồ dưới cho thấy hoàn tác khôi phục trạng thái từ ảnh chụp trước thao tác, nhưng chặn khi có thao tác thủ công phụ thuộc chưa xác nhận hoặc đã quá 90 ngày thì chờ DA.

```{.mermaid caption="Hoàn tác thao tác trên bản ghi vàng (FR-06-039)"}
sequenceDiagram
  actor DS
  participant U as UndoService
  participant W as GoldenWriter
  participant PG as ph06_mdm
  DS->>U: undo operationId, reason, confirmDependents
  U->>PG: tải golden_operation và golden_history trước thao tác
  U->>PG: tìm thao tác phụ thuộc về sau
  alt có thao tác thủ công phụ thuộc và chưa xác nhận
    U-->>DS: 409 ERR-06-033 kèm danh sách
  else quá 90 ngày
    U->>PG: đề nghị chờ DA, ERR-06-034 cho người gọi
  else thi hành
    U->>W: apply UNDO
    W->>PG: khôi phục trạng thái và xref theo ảnh chụp
    W->>PG: phát lại cập nhật nguồn đến sau qua sống sót
    W->>PG: UNDO undo_of gốc, gốc UNDONE, outbox sự kiện ngược
    W-->>DS: 200
  end
```

Điểm cần chú ý: bước "phát lại cập nhật nguồn đến sau" bảo đảm hoàn tác không làm mất dữ liệu mới của nguồn; hoàn tác là một thao tác mới, không xóa dòng lịch sử.

### 5.6. Resolve trực tuyến cho luồng PH-04 (FR-06-047, 052, 057)

Sơ đồ dưới cho thấy một lượt resolve trực tuyến từ luồng PH-04: lấy thuộc tính được phép từ PH-09, đối sánh, che dữ liệu theo mục đích và ghi nhật ký truy cập trước khi trả kết quả.

```{.mermaid caption="Resolve trực tuyến có che và nhật ký truy cập (FR-06-047, 052, 057)"}
sequenceDiagram
  participant R as Luồng PH-04
  participant AX as APISIX
  participant RS as ResolveService
  participant P9 as PH-09
  participant M as match.online
  participant PG as ph06_mdm
  participant L as AccessLogWriter
  R->>AX: POST domains/CITIZEN:resolve, X-Purpose
  AX->>RS: token, scope mdm:resolve, hạn mức đã qua
  RS->>P9: mục đích và thuộc tính được phép (đệm 5 phút)
  P9-->>RS: fullName, dateOfBirth, permanentAddress
  RS->>RS: chuẩn hóa tại chỗ, không lưu ứng viên
  RS->>M: match
  M->>PG: xác định rồi pg_trgm, statement_timeout 800ms
  PG-->>M: MATCH 0,94
  RS->>RS: MaskingFilter theo mục đích
  RS->>L: ghi access_log trước khi trả
  alt ghi nhật ký lỗi
    RS-->>R: 503 ERR-06-039, không trả dữ liệu
  else đã ghi
    RS-->>R: 200 goldenId, điểm, thuộc tính đã che
  end
```

Điểm cần chú ý: thứ tự "ghi nhật ký rồi mới trả" là bất biến (BR-06-010); `202` nghĩa là chưa có kết luận và bên gọi không được ghi dữ liệu theo kết quả đó.

### 5.7. Đồng bộ quốc gia và tự dừng khi lệch (FR-06-053, 054)

Sơ đồ dưới cho thấy thay đổi từ PH-14 vào PH-06 như ứng viên mức 1, job đối chiếu hằng đêm so với giá trị quốc gia, và bộ ngắt tự dừng đồng bộ khi tỷ lệ lệch vượt 5%.

```{.mermaid caption="Đồng bộ quốc gia chiều xuống, đối chiếu và tự dừng (FR-06-053, 054)"}
sequenceDiagram
  participant P14 as PH-14
  participant K as Kafka
  participant C as NationalChangeConsumer
  participant I as ingest
  participant RJ as ReconcileJob
  participant SB as SyncBreaker
  participant PG as ph06_mdm
  actor DS
  P14->>K: thay đổi dân cư, ĐKDN
  K->>C: tiêu thụ
  C->>PG: inbox_event, bỏ qua nếu event_id đã xử lý
  C->>I: ứng viên kênh NATIONAL_SYNC, nguồn mức 1
  I->>PG: đường nạp, NATIONAL_AUTHORITY thắng
  Note over RJ: hằng đêm theo job_schedule
  RJ->>P14: danh sách khóa theo lô 1.000
  P14-->>RJ: giá trị quốc gia
  RJ->>PG: so value_hash, ghi national_discrepancy
  RJ->>SB: ratio của lượt
  alt ratio lớn hơn 5 phần trăm
    SB->>PG: PAUSED, không áp lệch của lượt
    SB->>K: EVT-06-13 paused
    DS->>SB: điều tra rồi tiếp tục, áp hoặc bỏ lệch
  else trong ngưỡng
    SB->>PG: áp lệch thẩm quyền, lệch khác vào danh sách xử lý
    SB->>K: EVT-06-12 nếu có lệch mới
  end
```

Điểm cần chú ý: PH-06 không gọi thẳng CSDL quốc gia (BR-06-032); `inbox_event` làm cho việc PH-14 gửi lại cùng một thay đổi không tạo hai ứng viên (ADR-042).

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph06_mdm` có `tenant_id` và RLS theo `app.tenant_id` (ADR-003, D03-10). Bộ lọc Spring Security đọc tenant từ token, đặt `TenantContext`, và `TenantSession` chạy `SET LOCAL app.tenant_id` đầu mỗi giao dịch; mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Bốn điểm riêng của PH-06:

1. **Tác vụ nền** (lịch job, `SlaMonitor`, `RetentionPurger`, `JobWatchdog`) lặp qua từng tenant `ACTIVE`, đặt `TenantContext` tường minh và dùng khóa ShedLock có tên kèm tenant; không có tác vụ "không tenant".
2. **Kafka**: topic có tiền tố tenant thường (`t68.mdm.…`), ràng buộc CSDL `ck_outbox_event_prefix` bảo đảm tiền tố khớp `tenant_id`; bộ nghe sự kiện lấy tenant từ tiền tố topic và đối chiếu với `inbox_event.tenant_id`, lệch thì bỏ và cảnh báo.
3. **Khóa mật mã**: KEK và khóa HMAC riêng từng tenant; AAD gồm `tenant_id` nên bản mã chép nhầm sang tenant khác không giải được. Khóa Valkey, khóa tư vấn, tên Job K8s đều mang tenant.
4. **Job Splink**: mỗi lần chạy một tenant, tài khoản CSDL tạm đặt cố định `app.tenant_id`; staging của hai tenant không bao giờ cùng một Job. Dữ liệu `COMMON` (danh mục PH-07) đọc qua `RdmLookupApi`, không đọc bảng của PH-07.

## 7. Bảo mật

Kiểm tra quyền ở máy chủ, độc lập với giao diện: APISIX xác minh token và gọi OPA thô (SEC-26); `dh-data` kiểm lại `PERM-06-*` và phạm vi tổ chức bằng OPA ở từng `Controller`, rồi `ServingPipeline` kiểm mục đích. Bảng dưới liệt kê các kiểm soát và ràng buộc `SEC-*` đã có (không tạo mới).

| Kiểm soát | Hiện thực | SEC |
|---|---|---|
| Xác thực, ủy quyền | OIDC qua BFF cho người; `client_credentials` cho máy; scope `mdm:resolve`, `mdm:ingest`, `mdm:national-sync` | SEC-21, 24, 26 |
| Tách nhiệm vụ | Cặp loại trừ DS và DA; người đề nghị không duyệt (ERR-06-005) kiểm ở `ApprovalService`; DA duyệt bốn mắt dùng chung ADR-046 | SEC-28 |
| Mã hóa trường | Envelope cho `SENSITIVE`; HMAC theo tenant cho so khớp; quét CSDL không còn mẫu CCCD rõ (NFR-06-016) | SEC-31, 34 |
| Che dữ liệu | `MaskingFilter` theo PH-09; log che theo `@Classified`; không đưa giá trị vào nhãn chỉ số hay trace | SEC-32 |
| Nhật ký truy cập | `access_log` trước khi trả, fail-closed; 12 tháng trực tuyến, 5 năm WORM | SEC-37, 39 |
| Kiểm tra đầu vào | JSON Schema theo mô hình; giới hạn kích thước lô và tệp; quét tệp, chặn công thức, macro | SEC-43, 45 |
| Cách ly Job | `ServiceAccount` riêng, `NetworkPolicy` chỉ tới PgBouncer và Garage, `securityContext` không root, `readOnlyRootFilesystem`, ảnh ký cosign | SEC-14, 52, 53, 56 |
| Truy cập khối lượng lớn | Cửa sổ 10 phút, `06.access.bulk-threshold`; xuất cần chấp thuận DO và DA; tệp mã hóa, thủy vân, hạn tải 24 giờ | BR-06-013, 027 |
| Chống chèn công thức khi xuất | Tiền tố `'` cho ô bắt đầu `=`, `+`, `-`, `@` | SEC-45 |
| Dữ liệu thử | Môi trường ngoài PROD chỉ dùng dữ liệu sinh; tenant kiểm thử T90 đến T99 | SEC-38 |

: Kiểm soát bảo mật của PH-06

Rủi ro riêng của dữ liệu chủ: `goldenId` có thể thành định danh mới của công dân nếu HTTT dùng làm khóa lâu dài (Q06-08), nên `PurposeGuard` tách quyền nhận `goldenId` khỏi quyền nhận thuộc tính; hợp nhất nhầm trộn hồ sơ hai người, nên có ba lớp phòng: ngưỡng đã đo, bốn mắt, hoàn tác 90 ngày.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

FRS mô tả bảy máy trạng thái (4.3 đến 4.6 cộng `OperationStatus`, `ExportStatus`, `SyncState`). Mỗi chuyển trạng thái hiện thực bằng một câu `UPDATE … WHERE status = :expected` (so sánh và hoán đổi) và trả số dòng; số dòng bằng 0 nghĩa là trạng thái đã đổi, dịch vụ trả ERR-06-006 hoặc thử lại tùy ngữ cảnh. Bảng dưới ghi các chuyển có điều kiện đáng kể và nơi kiểm tra ở máy chủ.

| Đối tượng | Từ → đến | Điều kiện, bảo vệ | Chỗ kiểm tra |
|---|---|---|---|
| Bản ghi vàng | `ACTIVE` → `LOCKED` | Có thao tác chờ duyệt, hoặc yêu cầu chủ thể `RESTRICTION` | `DecisionService`, `SubjectRequestService` |
| | `LOCKED` → `ACTIVE` | Duyệt xong, từ chối, hết hạn chế | `ApprovalService` |
| | `ACTIVE` → `MERGED` | Có `mergedInto`, đã chụp ảnh | `MergeService` qua `GoldenWriter` |
| | `MERGED` → `ACTIVE` | Tách hoặc hoàn tác hợp nhất | `SplitService`, `UndoService` |
| | `ACTIVE` → `RETIRED` | Không còn liên kết hiệu lực (ERR-06-036) | `RetireService` |
| | `RETIRED` → `ACTIVE` | Khôi phục có lý do | `RetireService` |
| Mục hàng đợi | `OPEN` → `ASSIGNED` | Câu `UPDATE … WHERE status='OPEN'` (ERR-06-027) | `ClaimService` |
| | `ASSIGNED` → `PENDING_APPROVAL` | Quyết định `MATCH` rủi ro `HIGH` | `DecisionService` |
| | `PENDING_APPROVAL` → `RESOLVED` | DA khác người đề nghị (ERR-06-005) | `ApprovalService` |
| | `OPEN`, `ASSIGNED` → `CANCELLED` | `version` của bản ghi đã đổi (ERR-06-030) | `DecisionService`, `QueueItemFactory` |
| Job đối sánh | `QUEUED` → `PREPARING` → `RUNNING` | Một job mỗi `(domain, loại)` (ERR-06-025) | `BatchJobService` |
| | `RUNNING` → `AWAITING_CONFIRMATION` | `MATCH` > `06.batch.safety-ratio` | `BatchSafetyGate` |
| | `AWAITING_CONFIRMATION` → `APPLYING` | DA xác nhận | `BatchJobService.confirm` |
| | `APPLYING` → `SUCCEEDED` hoặc `PARTIALLY_SUCCEEDED` | Có cặp bị bỏ qua thì `PARTIALLY` | `ResultApplier` |
| Phiên bản mô hình, bộ quy tắc | `DRAFT`, `TESTING` → `PENDING_APPROVAL` | Phân loại đã xác nhận; đánh giá `PASSED` (bộ quy tắc) | `ClassificationGate`, `RuleSetService` |
| | `PENDING_APPROVAL` → `ACTIVE` | DA khác người gửi; phiên bản trước thành `SUPERSEDED` trong cùng giao dịch | `ModelVersionService`, `RuleSetService` |
| Thao tác bản ghi vàng | `PENDING_APPROVAL` → `APPLIED` hoặc `REJECTED` | Duyệt bốn mắt | `ApprovalService` |
| | `APPLIED` → `UNDONE` | Chưa hoàn tác; chỉ mục `uq_golden_operation_undo` | `UndoService` |
| Yêu cầu xuất | `PENDING_APPROVAL` → `APPROVED` → `GENERATING` → `READY` → `EXPIRED` | Chấp thuận DO và DA; hạn tải 24 giờ | `ExportService` |
| Đồng bộ quốc gia | `RUNNING` → `PAUSED` | Lệch > `06.sync.pause-ratio` | `SyncBreaker` |
| | `PAUSED` → `RUNNING` | DS hoặc DA xác nhận đã điều tra | `NationalSyncService` |

: Chuyển trạng thái có điều kiện và nơi kiểm tra ở máy chủ

### 8.2. Outbox

Mỗi thay đổi nghiệp vụ ghi một dòng `outbox_event` **trong cùng giao dịch** với thay đổi (`OutboxWriter` được gọi từ `GoldenWriter`, `BatchJobService`, `ModelVersionService`, `SyncBreaker`), nên không có sự kiện mà không có thay đổi và ngược lại. Debezium Outbox Event Router của nền tảng đọc WAL, định tuyến theo cột `topic`, khóa phân vùng theo `partition_key` (giữ thứ tự theo bản ghi vàng); `dh-data` không có bộ phát tự chạy. Bảo đảm là ít nhất một lần: `event_id` (UUID v7) là khóa khử trùng của bên nhận. Bảng `outbox_event` bị dọn theo `occurred_at` sau khi Debezium xác nhận; `datahub_mdm_outbox_pending` (số dòng chưa được router lấy, ước lượng từ độ trễ slot) và `datahub_mdm_event_lag_seconds` (từ `occurred_at` tới thời điểm có trên Kafka, đo bằng bản tin thăm dò) cảnh báo khi vượt 5 giây ở p95 (NFR-06-014) hoặc nhiều hơn 50 lần thử (ERR-06-109, nêu ở UI-06-18). Thân sự kiện kiểm bằng ràng buộc `ck_outbox_event_no_value` và bằng lược đồ Apicurio đăng ký qua PH-10 (FR-10-067).

### 8.3. Inbox và idempotency

**Inbox (ADR-042).** Mỗi bộ nghe Kafka ghi `inbox_event(tenant, consumer, event_id)` trong cùng giao dịch với tác động nghiệp vụ; khóa chính chặn hai lần xử lý cùng sự kiện. Bốn consumer: `SourceEventConsumer` (sự kiện PH-10, FR-06-012), `NationalChangeConsumer` (PH-14), `SourceStatusConsumer` (trạng thái HTTT PH-01), `PolicyChangedConsumer` (đổi chính sách PH-09, xóa đệm che).

**Idempotency (ADR-041).** Hai tầng. Tầng một ở `IdempotencyFilter`: khóa `Idempotency-Key` cùng băm SHA-256 của thân, lưu Valkey 24 giờ kèm kết quả đã trả; cùng khóa cùng băm trả lại kết quả cũ, cùng khóa khác băm trả ERR-06-015. Tầng hai là sự thật ở CSDL: chỉ mục duy nhất `(tenant, source, key, source_version)` của `candidate_record` chặn trùng kể cả khi Valkey mất; bản trùng là ứng viên `DUPLICATE`, không phải lỗi (BR-06-028). Thao tác ghi của người dùng chống gửi lặp bằng `If-Match` và `operationId` do máy khách sinh (UUID v7) để `golden_operation` không tạo hai lần.

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng dưới ghi thời gian chờ, số lần thử lại, ngắt mạch và cách xử lý khi hết lượt cho từng phụ thuộc, để biết PH-06 suy giảm thế nào khi một phụ thuộc chậm hoặc lỗi.

| Phụ thuộc | Thời gian chờ | Thử lại | Ngắt mạch | Khi hết lượt |
|---|---|---|---|---|
| `pg-core` truy vấn trực tuyến | `statement_timeout` 800 ms | Không (trực tuyến) | Không | `POSSIBLE_MATCH` lý do `TIMEOUT` |
| `pg-core` giao dịch ghi | 5 giây | Lỗi tuần tự hóa, xung đột `version`: 5 lần, 20 đến 100 ms ngẫu nhiên | Không | ERR-06-004 hoặc `409` |
| PH-07 | 500 ms | 2 lần, 100 ms | Resilience4j: mở khi lỗi ≥ 50% trong 20 lượt, nửa mở sau 30 giây | `NORMALIZATION_PENDING`, tự chuẩn hóa lại mỗi 5 phút tối đa 24 giờ (ERR-06-021) |
| PH-09 | 500 ms | 1 lần | Như trên | Chính sách chặt nhất `PUBLIC`, `X-Datahub-Masking: fallback` |
| OpenBao transit | 1 giây | 2 lần, 200 ms | Như trên | Trả dạng che (ERR-06-113); ghi thì từ chối |
| Valkey | 100 ms | Không | Lui về CSDL | Giảm hiệu năng, không lỗi |
| Garage | 10 giây | 3 lần giãn dần | Không | Tệp xuất `FAILED`, ứng viên tệp tạm dừng |
| PH-14 | 5 giây, lô 30 giây | 3 lần giãn dần | Mở khi lỗi liên tục 10 phút | Giữ hàng chờ, cảnh báo sau 24 giờ (ERR-06-106) |
| Kafka (bộ nghe) | Theo `max.poll.interval.ms` 5 phút | 5 lần, 1 giây nhân đôi | Không | Chuyển `.dlq` (ERR-06-110) |
| Job K8s | `activeDeadlineSeconds` 14.400 | `backoffLimit: 0` (không tự chạy lại, tránh áp hai lần) | Không | `FAILED` (ERR-06-101…103) |

: Thời gian chờ, thử lại và ngắt mạch theo phụ thuộc

### 8.5. Ánh xạ lỗi

`MdmExceptionHandler` biến ngoại lệ miền (`MdmException(code, args)`) thành RFC 9457 kèm `code`, `traceId`, `errors[]` theo trường (CC-ERR). Mã 001 đến 099 trả người gọi; 101 đến 199 chỉ ghi nhật ký xử lý và hiển thị cho vận hành.

| Nhóm mã | HTTP | Thành phần ném | Xử lý |
|---|---|---|---|
| ERR-06-001, 050 | 404, 410 | `serve`, `lineage` | Không thử lại; `410` kèm lý do ngừng |
| ERR-06-002, 004, 006, 015, 025, 027, 030, 031, 033, 044 | 409 | Mọi dịch vụ ghi | Người gọi tải lại hoặc sửa; ERR-06-004 thử lại tự động ở đường máy |
| ERR-06-003, 007…011, 013, 016, 017, 019, 020, 022…024, 026, 029, 032, 035, 036, 040, 041, 043, 045…047, 049 | 400, 422 | `model`, `ingest`, `normalize`, `matching.rules`, `golden`, `serve` | Trả `errors[]`; không thử lại |
| ERR-06-005, 014, 028, 034, 037, 038 | 403 | `ApprovalService`, `ingest`, `serve` | Không thử lại; ghi kiểm toán khi bị chặn do bốn mắt hoặc truy cập hàng loạt |
| ERR-06-012 | 422 | `source` | HTTT chưa `ACTIVE` ở PH-01 |
| ERR-06-018 | 413 | `ingest` | Chia nhỏ lô |
| ERR-06-021, 039 | 503 | `normalize`, `serve` | ERR-06-021 đưa ứng viên vào hàng chờ chuẩn hóa; ERR-06-039 không trả dữ liệu, thử lại sau |
| ERR-06-042 | 410 | `ExportService` | Tạo yêu cầu xuất mới |
| ERR-06-048 | 429 | APISIX, `ingest` | `Retry-After` |
| ERR-06-101, 102, 103 | — | `JobWatchdog` | Job `FAILED`, không bản ghi vàng nào đổi; gợi ý Spark khi hết bộ nhớ |
| ERR-06-104 | — | `ResultApplier` | Bỏ qua cặp, ghi `skip_code`, job `PARTIALLY_SUCCEEDED` |
| ERR-06-105 | — | `BatchSafetyGate` | `AWAITING_CONFIRMATION`, việc cho DA |
| ERR-06-106, 107, 108 | — | `sync` | Giữ hàng chờ; tự dừng đồng bộ; không áp dữ liệu mâu thuẫn |
| ERR-06-109 | — | Debezium, `DashboardMetrics` | Cảnh báo outbox chậm |
| ERR-06-110 | — | `SourceEventConsumer` | Sự kiện vào `.dlq`, vận hành xử lý |
| ERR-06-111 | — | `GoldenWriter` | Hủy giao dịch, thử lại 3 lần giãn dần, rồi danh sách lỗi UI-06-11 |
| ERR-06-112 | — | `DeterministicMatcher` | `CONFLICT`, mục `IDENTIFIER_CONFLICT` ưu tiên cao nhất, cảnh báo nghiêm trọng |
| ERR-06-113 | — | `MaskingFilter` | Trả dạng che, cảnh báo vận hành |
| ERR-06-114 | — | `RetentionPurger` | Bỏ qua đối tượng giữ pháp lý, ghi nhật ký |

: Ánh xạ mã lỗi ERR-06 tới thành phần và cách xử lý

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số theo tenant

Mười ba tham số của FRS 8.2 lưu ở `tenant_setting`, đọc qua `MdmProperties` có đệm 60 giây và được xóa đệm khi `TenantSettingService` ghi (FR-06-060). Bảng dưới ghi nơi mỗi tham số có hiệu lực trong mã.

| Khóa | Mặc định | Thành phần đọc |
|---|---|---|
| `06.queue.sla-days`, `max-open`, `escalate-after-days`, `hold-minutes` | 7, 500, 14, 30 | `QueueItemFactory`, `SlaMonitor`, `ClaimService` |
| `06.match.auto-disable-on-fail` | `true` | `ThresholdClassifier` |
| `06.batch.safety-ratio` | 0,05 | `BatchSafetyGate` |
| `06.undo.window-days` | 90 | `UndoService` |
| `06.export.max-rows` | 100.000 | `ExportService` |
| `06.access.bulk-threshold` | 100 bản ghi trong 10 phút | `BulkAccessGuard` |
| `06.ingest.rate-per-source` | 6.000 bản ghi mỗi phút | `CandidateIngestService`, `FileIngestJob` |
| `06.sync.pause-ratio` | 0,05 | `SyncBreaker` |
| `06.sync.up-attributes` | rỗng | `UpSyncJob` |
| `06.dsr.sla-days` | 10 ngày làm việc (giả định) | `SubjectRequestService` |

: Tham số theo tenant và thành phần đọc

### 9.2. Cờ tính năng

Bảng dưới ghi các cờ tính năng, giá trị mặc định và tác dụng, để vận hành biết cờ nào bật hoặc tắt từng phần của phân hệ khi triển khai.

| Cờ | Mặc định | Tác dụng |
|---|---|---|
| `mdm.enabled` | tắt | Bật phân hệ cho tenant; tắt thì `/api/mdm/v1` trả `404` và bộ nghe dừng |
| `mdm.autoMerge.enabled` | bật | Tắt thì mọi `MATCH` xác suất thành `POSSIBLE_MATCH` (chế độ an toàn khi mới triển khai) |
| `mdm.batch.sparkMode` | tắt | Cho phép job hồ sơ `xl` khi > 5 triệu bản ghi |
| `mdm.nationalSync.up` | tắt | Cho phép chiều lên (cần Q06-02 xong) |

: Cờ tính năng theo tenant

### 9.3. Cấu hình triển khai

`dh-data` chạy ở namespace `dh-control`, node pool `control` (D03-09 §4), Deployment tối thiểu 2 bản sao, trải theo `topologySpreadConstraints` giữa hai nút, `PodDisruptionBudget` `minAvailable: 1`. Hồ sơ đo NFR là 2 bản sao × 4 vCPU, 8 GB; định cỡ theo cỡ triển khai nằm ở D03-09 §5.2. Job `mdm-splink` cũng ở `dh-control`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: mdm-splink-<jobId>
  namespace: dh-control
  labels: { app.kubernetes.io/name: mdm-splink, dh.gov.vn/tenant: t01, dh.gov.vn/job-id: <jobId> }
spec:
  backoffLimit: 0                      # không tự chạy lại, tránh áp kết quả hai lần
  activeDeadlineSeconds: 14400         # 4 giờ, ERR-06-102
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      serviceAccountName: mdm-splink   # không gắn Role nào trên API K8s
      restartPolicy: Never
      priorityClassName: dh-batch-low  # nhường tài nguyên cho API trực tuyến
      nodeSelector: { dh.gov.vn/pool: control }
      securityContext: { runAsNonRoot: true, seccompProfile: { type: RuntimeDefault } }
      containers:
        - name: splink
          image: harbor.<tenant-domain>/dh/mdm-splink:<tag>@sha256:<digest>     # ký cosign
          args: ["--job-id=<jobId>", "--mode=DUCKDB"]
          resources:
            requests: { cpu: "4", memory: 16Gi, ephemeral-storage: 20Gi }
            limits:   { cpu: "8", memory: 32Gi, ephemeral-storage: 50Gi }     # hồ sơ chuẩn, NFR-06-013
          env:
            - { name: DUCKDB_MEMORY_LIMIT, value: "24GB" }                    # chừa chỗ cho Python, tránh OOMKilled
            - { name: DUCKDB_THREADS, value: "8" }
          securityContext: { readOnlyRootFilesystem: true, allowPrivilegeEscalation: false, capabilities: { drop: ["ALL"] } }
          volumeMounts: [ { name: spill, mountPath: /tmp/duckdb } ]
      volumes: [ { name: spill, emptyDir: { sizeLimit: 50Gi } } ]
```

| Hồ sơ | Dùng khi | Tài nguyên | Ghi chú |
|---|---|---|---|
| `std` (DuckDB) | ≤ 5 triệu bản ghi vào | 4/16 đến 8/32 (CPU, GB) | Mặc định; 1,2 triệu `CITIZEN` ≤ 2 giờ (NFR-06-013, giả định) |
| `xl` (Spark local) | > 5 triệu, cờ `mdm.batch.sparkMode` | 16/64, đĩa 200 GB | Chạy một Job lớn, không cụm Spark (Q06-26) |

: Hồ sơ tài nguyên của Job mdm-splink

`NetworkPolicy` của Job: từ chối mặc định (SEC-14), chỉ ra tới PgBouncer của `pg-core` (`dh-db`, cổng 6432) và Garage (`dh-s3`); `dh-data` cần quyền `create`, `get`, `list`, `watch`, `delete` trên `jobs` và `get`, `list` trên `pods` chỉ trong `dh-control`, qua `Role` riêng của `ServiceAccount` `dh-data` (ngoại lệ có chủ đích so với SEC-53, cần ATTT duyệt, Q06-24).

## 10. Quan sát

Chỉ số phát ra qua Micrometer, tiền tố `datahub_mdm_`, nhãn có bậc số lượng nhỏ (`tenant`, `domain`, `source` tối đa vài chục giá trị); tuyệt đối không dùng `goldenId`, số định danh, tên người làm nhãn (SEC-32). 

| Nhóm | Chỉ số | Nhãn | Dùng cho |
|---|---|---|---|
| Nạp | `datahub_mdm_candidate_total`, `datahub_mdm_ingest_duration_seconds`, `datahub_mdm_dedup_total`, `datahub_mdm_inbox_dlq_total` | `domain`, `source`, `status`, `kind` | NFR-06-004; FR-06-055 |
| Chuẩn hóa | `datahub_mdm_normalize_duration_seconds`, `datahub_mdm_normalize_warning_total`, `datahub_mdm_normalization_pending` | `domain`, `warning` | Phát hiện PH-07 chậm |
| Đối sánh | `datahub_mdm_match_duration_seconds`, `datahub_mdm_match_outcome_total`, `datahub_mdm_match_timeout_total`, `datahub_mdm_block_size`, `datahub_mdm_block_truncated_total`, `datahub_mdm_auto_rate` | `domain`, `method`, `outcome` | NFR-06-003, 006, 007, 018 |
| Hàng đợi | `datahub_mdm_queue_open`, `datahub_mdm_queue_age_seconds`, `datahub_mdm_queue_sla_breach_total`, `datahub_mdm_steward_decision_total` | `domain`, `reason`, `decision` | NFR-06-017, 019 |
| Bản ghi vàng | `datahub_mdm_golden_total`, `datahub_mdm_golden_operation_total`, `datahub_mdm_golden_lock_wait_seconds`, `datahub_mdm_optimistic_retry_total`, `datahub_mdm_snapshot_bytes` | `domain`, `status`, `type` | Tranh chấp khóa |
| Phục vụ | `datahub_mdm_resolve_total`, `datahub_mdm_resolve_duration_seconds`, `datahub_mdm_access_log_failure_total`, `datahub_mdm_decrypt_failure_total`, `datahub_mdm_bulk_access_blocked_total`, `datahub_mdm_cache_hit_ratio` | `domain`, `outcome`, `cache` | NFR-06-001, 002, 015 |
| Sự kiện | `datahub_mdm_event_published_total`, `datahub_mdm_event_lag_seconds`, `datahub_mdm_outbox_pending` | `type` | NFR-06-014 |
| Job | `datahub_mdm_job_total`, `datahub_mdm_job_duration_seconds`, `datahub_mdm_batch_pairs`, `datahub_mdm_batch_skipped_total` | `job_type`, `status`, `outcome`, `reason` | FR-06-056 |
| Quốc gia | `datahub_mdm_sync_run_total`, `datahub_mdm_sync_discrepancy_ratio`, `datahub_mdm_sync_paused`, `datahub_mdm_sync_lag_seconds` | `direction`, `result` | NFR-06-020 |
| Lưu giữ | `datahub_mdm_purge_rows_total`, `datahub_mdm_dsr_open` | `object`, `action`, `type` | FR-06-058, 059 |

: Chỉ số quan sát của PH-06

**Log**: JSON có `traceId`, `tenant`, `module = mdm`, `domain`, `operationId`; không bao giờ có giá trị thuộc tính hay băm định danh. **Trace**: span `mdm.ingest`, `mdm.normalize`, `mdm.match`, `mdm.golden.apply`, `mdm.resolve`, `mdm.batch.launch`, `mdm.sync.reconcile`, truyền `traceparent` vào cột `trace_id` của outbox để nối sự kiện với giao dịch gốc. **Cảnh báo** (quy tắc PH-13, NFR-06-019): `queue_open` > 500; `auto_rate` < 80% trong 24 giờ; `sync_discrepancy_ratio` > 5%; mục chờ > 7 ngày; `job_total{status="FAILED"}` tăng; `access_log_failure_total` > 0; `bulk_access_blocked_total` tăng đột biến; p99 `golden_lock_wait_seconds` > 1 giây; `match_timeout_total` / `match_outcome_total` > 1% (FR-06-021).

## 11. Hiệu năng và vận hành

**Ngân sách độ trễ resolve (p95 ≤ 300 ms, NFR-06-003; giả định phân bổ, đo khi nghiệm thu):** kiểm scope và mục đích 5 ms (đệm), chuẩn hóa 10 ms, truy vấn lấy ứng viên 120 ms (`pg_trgm` trên khối ≤ 200 dòng, chỉ mục `ix_golden_record_name_trgm`), chấm 200 ứng viên × 5 hàm 30 ms, che và giải mã trường được trả 40 ms (DEK đã đệm), ghi `access_log` 20 ms. Tra theo khóa định danh (NFR-06-002, p99 ≤ 30 ms) chỉ một truy vấn theo `uq_golden_identifier_active` cộng ghi nhật ký.

**Thông lượng nạp (NFR-06-004, 1.000 bản ghi mỗi giây):** đường đồng bộ nạp–chuẩn hóa–đối sánh ở 2 bản sao × 4 vCPU cần trung bình dưới 8 ms CPU mỗi ứng viên; thiết kế đạt bằng ba điều chỉnh: ghi ứng viên theo lô (`INSERT` nhiều dòng với bản ghi cùng nguồn), đối sánh chạy trên hàng đợi tác vụ nền 16 luồng ảo mỗi bản sao, và khóa cụm hẹp theo khóa gom nhóm. Kênh tệp và đồng bộ quốc gia chạy ở mức ưu tiên thấp hơn API để không làm chậm resolve.

**Dung lượng:** 10 triệu bản ghi vàng mỗi tenant (NFR-06-005): `golden_attribute` khoảng 15 dòng mỗi bản ghi, 150 triệu dòng, phân vùng băm theo `tenant_id` do D03-03; chỉ mục trigram trên `name_norm` chiếm khoảng 1,5 lần dữ liệu cột (giả định). `golden_history` tăng theo thay đổi nên có chính sách dọn ảnh chụp quá hạn hoàn tác cộng 12 tháng (`retention_policy`). **DR:** PH-06 không giữ trạng thái ngoài `pg-core`, Garage, Kafka nên RPO ≤ 15 phút, RTO ≤ 30 phút đi theo hạ tầng (ADR-034); sau chuyển site, outbox phát lại từ vị trí Debezium đã lưu, Job đang chạy bị coi `FAILED` và chạy lại bằng tay.

**Vận hành thường nhật:** tuần một lần job `BATCH_MATCH` `GOLDEN_VS_GOLDEN` (01:00 Chủ nhật), đêm đối chiếu quốc gia, tháng một lần `ACCURACY_EVAL`; sổ tay vận hành ghi sáu tình huống: hàng đợi quá tải, job chờ xác nhận, đồng bộ dừng, outbox chậm, nhật ký truy cập lỗi, đổi khóa HMAC.

## 12. Kiểm thử

Chiến lược kiểm thử chia theo lớp; bảng dưới ghi nội dung mỗi lớp và ví dụ ca, từ hàm thuần, so sánh Java với Splink đến tích hợp với PostgreSQL và Kafka.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | Hàm thuần: `VietnameseNameNormalizer`, `DateNormalizer`, `IdentifierValidator`, `Comparators`, `FellegiSunterScorer`, `SurvivorshipEngine`, `RiskClassifier` | Bảng 300 tên: "NGUYEN VAN A", "Nguyễn  Văn A", "Văn A Nguyễn" cho cùng `nameAscii`; tên một tiếng, họ kép; ngày giả `01/01/1900` thành `MISSING`; hai lần `survive` cùng đầu vào cùng kết quả |
| Tương đương Java–Splink | 10.000 cặp mẫu chấm bằng `FellegiSunterScorer` và Splink với cùng m, u | Chênh lệch tuyệt đối ≤ 0,01 |
| Tích hợp (Testcontainers) | PostgreSQL có `pg_trgm`, RLS, Kafka, OpenBao dev | Nạp 1.000 ứng viên, kiểm số bản ghi vàng, `golden_history`, sự kiện, không giá trị rõ trong CSDL; tenant A không thấy dòng tenant B |
| Đồng thời | 32 luồng nạp cùng một thực thể; hai người cùng nhận một mục; sửa tay đồng thời với áp dụng nguồn | Đúng một bản ghi vàng; một người nhận được; không bế tắc; `version` đúng |
| Hợp đồng | Lược đồ sự kiện Apicurio, OpenAPI | Sự kiện không có khóa `value`, `name`, `dateOfBirth`; tương thích `BACKWARD` |
| Job Splink | Chạy trong kind với tập 100.000 bản ghi sinh sẵn | Quyền CSDL chỉ đọc staging, ghi kết quả; vượt 5% dừng chờ; OOM thì `FAILED` không đổi bản ghi vàng |
| Chất lượng đối sánh | Tập nhãn ≥ 10.000 cặp (Q06-06) | Precision ≥ 99,9%, recall ≥ 98%, độ phủ gom nhóm ≥ 99,5% |
| Phi chức năng | k6, kiểm thử dung lượng, mô phỏng lỗi (chaos) | NFR-06-001…005; tắt Valkey, PH-09, OpenBao thì đúng cách lui (§8.4) |
| Bảo mật | ArchUnit, quét CSDL tìm CCCD rõ, ZAP | Không đường ghi nào bỏ qua `GoldenWriter`; 0 mẫu CCCD rõ (NFR-06-016) |

: Chiến lược kiểm thử của PH-06

Dữ liệu kiểm thử là dữ liệu sinh (SEC-38) ở tenant T90 đến T99, có nhiễu: bỏ dấu, đảo thứ tự, sai chính tả, ngày đảo, thiếu thuộc tính, địa chỉ mã cũ.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Thứ tự theo phụ thuộc, mỗi mốc có tiêu chí xong đo được (kế hoạch W0 đến W6 (docs/08-implementation/04-ke-hoach-phat-trien.md), PH-06 thuộc đợt 3).

| Mốc | Nội dung | Tiêu chí xong |
|---|---|---|
| M1 | `model`, `crypto`, `persistence`, ArchUnit | Ba domain nền nạp được; quét CSDL không có giá trị rõ |
| M2 | `ingest`, `normalize`, `match.online` (xác định), `GoldenWriter` cơ bản, outbox | Nạp 1.000 bản ghi mỗi giây; EVT-06-01, 02 phát đúng |
| M3 | Xác suất trực tuyến, `steward`, bốn mắt, hợp nhất, tách, hoàn tác | Ca đồng thời đạt; precision và recall đo trên tập nhãn thử |
| M4 | `serve`, che, nhật ký truy cập, resolve, xuất, đăng ký | NFR-06-001…003 đạt; BR-06-010 kiểm thử fail-closed |
| M5 | `match.batch` Splink, tham số học, an toàn 5% | NFR-06-013 đo; tương đương Java–Splink ≤ 0,01 |
| M6 | `sync` qua PH-14, `ops`, lưu giữ, yêu cầu chủ thể | Tự dừng khi lệch 5%; dọn lưu giữ đúng |

: Lộ trình hiện thực

### 13.2. Truy vết hệ cũ

Hệ cũ (Viettel 2021) không có MDM, D02-02 ghi LGC "—" cho PH-06; tập này không phủ `LGC` nào làm chính. Bốn chức năng cũ liên quan gián tiếp, kết luận **phân hệ dùng dữ liệu, không thay chức năng**.

| LGC | Chức năng hệ cũ | Vai trò trong thiết kế | Thành phần |
|---|---|---|---|
| LGC-NGSP-003 | Tra cứu BHXH hộ gia đình | Nguồn bổ sung cho `CITIZEN` qua PH-14 | `sync`, `NationalChangeConsumer` |
| LGC-NGSP-005 | Dữ liệu đăng ký doanh nghiệp | Nguồn chính cho `ORGANIZATION` (MST) qua PH-14 | `sync`, `DeterministicMatcher` |
| LGC-DMDC-015 | Khai thác danh mục qua API | PH-07 cung cấp mã ĐVHC, giới tính, dân tộc | `AdminUnitClient` |
| LGC-DMDC-019 | Danh mục quốc gia qua NGSP | Mã ĐVHC hiện hành để chuẩn hóa địa chỉ | `AddressNormalizer` |

: Truy vết LGC liên quan gián tiếp

FR của SRS cũ (FR-06-001…013 ở `docs/07-srs`) được ánh xạ sang 60 FR mới ở FRS 11.2; thiết kế này đi theo FR mới.

### 13.3. Rủi ro

Bảng dưới ghi các rủi ro kỹ thuật và nghiệp vụ của thiết kế, mức độ và cách giảm thiểu, để người duyệt biết điểm nào cần theo dõi.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Hợp nhất nhầm hai công dân | Cao | Ngưỡng đo trên tập nhãn; bốn mắt; hoàn tác 90 ngày; `negativeLink` |
| Tập nhãn thật chưa có khi nghiệm thu | Cao | Lấy mẫu phân tầng từ dữ liệu nạp thử T01, hai DS gán độc lập (Q06-06); hiệu chỉnh m, u bằng Splink |
| Điểm Java và Splink lệch nhau | Trung bình | Dùng chung bộ tham số; ca kiểm thử tương đương ≤ 0,01 |
| Khóa HMAC lộ hoặc cần đổi | Cao | Quyền đọc hẹp; kho OpenBao; job `REENCRYPT` (Q06-27) |
| Job Splink tranh tài nguyên với API trực tuyến | Trung bình | `PriorityClass` thấp, hạn mức; đề xuất pool riêng (Q06-25) |
| PH-14 chưa sẵn sàng khi PH-06 hoàn thành | Trung bình | Nạp qua tệp, kênh `FILE`; đồng bộ quốc gia bật sau |

: Rủi ro và giảm thiểu

### 13.4. Quyết định kiến trúc đề xuất

Dải ADR 080 đến 084 dành cho PH-06 (D00-04 §3.1). Tập này chỉ nêu nội dung tóm tắt; tệp ADR do luồng tài liệu chung lập khi FRS đề nghị ở D00-02 (FRS Phụ lục B).

| Số đề xuất | Tiêu đề | Bối cảnh, quyết định, hệ quả (tóm tắt) |
|---|---|---|
| ADR đề xuất số 080 | Đối sánh theo lô bằng Splink chạy Job K8s đọc staging | Cần khử trùng hàng triệu bản ghi và học tham số m, u; Splink (MIT) chạy trên DuckDB không cần cụm Spark, giải thích được trọng số. Job chỉ đọc staging, ghi kết quả; áp qua `GoldenWriter`. Hệ quả: thêm thành phần Python, ảnh và quy trình chạy Job; ranh giới an toàn mạnh. Phương án khác: Zingg, tự viết trong PostgreSQL |
| ADR đề xuất số 081 | Đối sánh trực tuyến bằng quy tắc xác định và `pg_trgm` trong PostgreSQL | Cần p95 ≤ 300 ms không thêm dịch vụ tìm kiếm; khóa gom nhóm cộng trigram cộng chấm điểm FS trong Java. Hệ quả: không thêm hạ tầng, nhưng giới hạn quy mô khối và cần chỉ mục GIN; giữ cùng tham số với Splink. Phương án khác: Elasticsearch, bộ so khớp ngoài |
| ADR đề xuất số 082 | Ảnh chụp đầy đủ cho lịch sử và hoàn tác bản ghi vàng | Cần hoàn tác hợp nhất, tách, sửa tay; ghi ảnh chụp toàn bộ trạng thái trước mỗi thay đổi trong cùng giao dịch, thay vì chỉ lưu delta. Hệ quả: tốn dung lượng, đổi lấy hoàn tác tin cậy và đọc lịch sử đơn giản; có chính sách dọn |
| ADR đề xuất số 083 | Nguồn gốc ở cấp thuộc tính | Hai nguồn đóng góp thuộc tính khác nhau cho một bản ghi vàng; lưu nguồn, chiến lược, thời điểm cho từng thuộc tính (`golden_attribute`, `attribute_lineage`). Hệ quả: nhiều dòng hơn, nhưng sống sót, truy xuất và giải thích được |
| ADR đề xuất số 084 | Sự kiện dữ liệu chủ không chứa DLCN, bên nhận tra lại theo mục đích | Tránh lộ dữ liệu cá nhân qua trục sự kiện; sự kiện chỉ mang mã, phiên bản, tên thuộc tính đổi; giá trị lấy qua API có mục đích và nhật ký. Hệ quả: thêm một lượt gọi cho bên nhận, đổi lấy kiểm soát mục đích và quyền riêng tư |

: Quyết định kiến trúc đề xuất cho PH-06

### 13.5. Đề nghị bổ sung cho FRS và tài liệu khác

Quá trình thiết kế phát hiện vài chỗ FRS và tài liệu khác cần sửa; bảng dưới ghi từng đề nghị bổ sung kèm lý do để các tập khớp nhau.

| Tài liệu | Đề nghị | Lý do |
|---|---|---|
| FRS §2.4, FR-06-056 | Ghi "ShedLock cộng `job_schedule`" thay "Quartz cluster" | DDL đã có `shedlock`; đồng nhất với PH-04, 05, 07 |
| FRS FR-06-021 bước 3 | Sửa "trọng số chia lại" thành "mức `MISSING` có trọng số 0 trong tổng Fellegi–Sunter, điểm đổi sang xác suất `P`" | Toán tương đương nhưng rõ và khớp Splink |
| FRS NFR-06-018, FR-06-055 | Đổi tên chỉ số `mdm_*` thành `datahub_mdm_*` | Quy ước tiền tố chung (tập này dùng `datahub_mdm_*`) |
| FRS FR-06-022 | Nêu `activeDeadlineSeconds` 4 giờ là tham số cấu hình `06.batch.max-hours` và thêm vào 8.2 (hiện chỉ có 13 khóa) | Hằng số "4 giờ" chưa có khóa |
| FRS 8.2 | Thêm `06.sync.reconcile-batch-size` (1.000) và `06.match.timeout-ms` (800) | Hai hằng số của thiết kế |
| D03-03-PH06 CSDL | (a) Thêm `block_keys varchar(72)[]` cộng GIN cho `golden_record`; (b) vai `ph06_splink` chỉ `SELECT match_staging` và `INSERT match_result`; (c) FRS ghi bảng `stg_match_{jobId}` nhưng DDL dùng `match_staging` có `job_id`, FRS cần sửa theo DDL | Đối sánh trực tuyến B4 và nhất quán hai đường; quyền tối thiểu của Job |
| D03-09 | `ResourceQuota` và `PriorityClass dh-batch-low` cho Job ở `dh-control`; cân nhắc pool `batch` | Job 8 vCPU, 32 GB cạnh API (Q06-25) |
| D03-07 | Xác nhận ngoại lệ `Role` tạo `Job` của `ServiceAccount dh-data` so với SEC-53 | Q06-24 |
| PH-10 | Đăng ký 15 topic `{tenant}.mdm.*`; Debezium Outbox Event Router cho `ph06_mdm.outbox_event` | Phát sự kiện |
| PH-09 | Danh mục phân loại trường `ph06_mdm.*`, API chính sách che có độ trễ ≤ 50 ms | Ngân sách resolve |

: Đề nghị bổ sung và đồng bộ

### 13.6. Câu hỏi mở

> **Câu hỏi mở Q06-20:** Phân vùng băm `golden_attribute` có đủ cho 10 triệu bản ghi vàng mỗi tenant (NFR-06-005) hay cần bảng phẳng cho tra cứu; cần đo trên dữ liệu T01 giả lập.

> **Câu hỏi mở Q06-21:** Nên đặt `λ` tiên nghiệm trực tuyến bằng `1/N` (như thiết kế) hay hiệu chỉnh theo dữ liệu từng khối; cần so trên tập nhãn thử.

> **Câu hỏi mở Q06-22:** Danh sách họ phổ biến và họ kép của `VietnameseNameNormalizer` lấy từ nguồn thẩm quyền nào, và tên dân tộc thiểu số một tiếng xử lý thế nào ngoài mặc định "toàn bộ là tên".

> **Câu hỏi mở Q06-23:** Kiểu đặt dấu thanh chuẩn của tên trên CCCD (`hòa` hay `hoà`) để `canonicalTone` mặc định `OLD` hay `NEW` đúng với dữ liệu quốc gia.

> **Câu hỏi mở Q06-24:** `dh-data` có được cấp `Role` tạo, xem, xóa `Job` ở `dh-control` (ngoại lệ so với SEC-53), hay Job nên do một bộ điều phối riêng (ví dụ Argo Workflows) tạo.

> **Câu hỏi mở Q06-25:** Job Splink có cần node pool riêng (`batch`) thay vì `control`, nếu đo thấy tranh chấp tài nguyên với API trực tuyến.

> **Câu hỏi mở Q06-26:** Với tenant lớn hơn tỉnh vừa (trên 5 triệu bản ghi vào), có cần Spark chạy cụm nhiều nút (Spark on Kubernetes) thay vì `local[*]` trên một Job.

> **Câu hỏi mở Q06-27:** Quy trình đổi khóa HMAC theo tenant: băm lưu kèm số hiệu phiên bản khóa để tính lại dần (job `REENCRYPT`) hay tính lại toàn bộ một lần ngoài giờ.

> **Câu hỏi mở Q06-28:** Thủy vân tệp xuất (BR-06-027) dùng dạng nào (cột ẩn, dòng đầu, hay ký tự không hiển thị) mà vẫn đọc được bằng Excel và công cụ phân tích mà không gây lỗi nhập.

> **Câu hỏi mở Q06-29:** Tần suất và phạm vi huấn luyện lại tham số m, u (hằng tháng toàn domain hay chỉ khi `ACCURACY_EVAL` giảm), để tránh trôi tham số làm đổi vùng quyết định mà không qua duyệt (BR-06-020, 021).

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-SDD và K-TRINH-BAY: cấu trúc module `mdm`, mô hình miền, 11 thành phần với khối đặc tả 10 mục, thuật toán chuẩn hóa tên, blocking, Fellegi–Sunter, sống sót, đồng thời, mã hóa và băm, bảy sơ đồ trình tự, ánh xạ ERR-06, chỉ số `datahub_mdm_*`, cấu hình Job K8s, năm ADR đề xuất số 080 đến 084, câu hỏi mở Q06-20…29 |
