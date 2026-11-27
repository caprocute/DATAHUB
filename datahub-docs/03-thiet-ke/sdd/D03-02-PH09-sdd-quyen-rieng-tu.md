---
ma_tai_lieu: D03-02-PH09
ten: Thiết kế chi tiết phần mềm phân hệ PH-09 Quyền riêng tư
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-data, kỹ sư tích hợp PEP, ATTT, pháp chế, kiến trúc sư, hội đồng thẩm định
phan_he: PH-09
mo_ta: Thiết kế chi tiết hiện thực 64 FR của PH-09 gồm cấu trúc mã module privacy, 15 thành phần với khối đặc tả 10 mục, thư viện dh-privacy-client cho điểm thực thi, chín sơ đồ trình tự, máy trạng thái theo enum FRS, đệm và đóng an toàn, xử lý lỗi ERR-09, cấu hình 09.*, hiệu năng, bảo mật, quan sát và kiểm thử.
tai_lieu_lien_quan: D02-03-PH09 FRS; D02-04-PH09 UC; D03-03-PH09 CSDL; D03-04-PH09 API; D03-06-PH09 Màn hình; D03-07 ATTT; D03-10 Thiết kế đa tenant
---

# D03-02-PH09 · Thiết kế chi tiết Quyền riêng tư

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 64 FR của [D02-03-PH09](../../02-yeu-cau/frs/D02-03-PH09-frs-quyen-rieng-tu.md). PH-09 là nơi Datahub quản lý việc bảo vệ dữ liệu cá nhân: danh mục phân loại trường, sổ hoạt động xử lý, mục đích và chấp thuận khai thác, chính sách che, giả danh hóa và ẩn danh hóa, thời hạn lưu, quyền của chủ thể, sự đồng ý, đánh giá tác động và vi phạm dữ liệu cá nhân (DLCN). Ở hệ cũ chỉ có nhóm bảo mật mã hóa gói tin (LGC-TOOL-012) và kiểm soát mục đích khai thác của BHXH (LGC-NGSP-003), nên phần lớn là thiết kế mới. Sáu quyết định chi phối thiết kế:

1. **PH-09 là nơi quản lý chính sách, không phải nơi thực thi từng lời gọi.** PH-09 đóng vai trò điểm quản trị (PAP) và nguồn thông tin chính sách (PIP). Điểm quyết định (PDP) là OPA của PH-12. Điểm thực thi (PEP) là APISIX, PH-04, PH-06, PH-14, PH-19, mỗi nơi dùng thư viện chung `dh-privacy-client` với đệm cục bộ. Nhờ đó một sự cố của PH-09 không làm dừng toàn bộ lưu lượng (đề xuất ADR số 090).
2. **Chính sách đến PEP bằng bundle ký và sự kiện đẩy.** `bundle-publisher` dựng dữ liệu `purpose_grants`, `mask_policies`, `classification_index`, kiểm thử bằng bộ ca chuẩn, ký bằng khóa transit không xuất được và đặt hạn `validUntil`. Thu hồi có hiệu lực trong 15 giây nhờ sự kiện, tối đa 60 giây nhờ bundle (BR-09-017).
3. **Đóng an toàn có phân biệt.** PEP đọc không có kế hoạch che thì chỉ trả trường `PUBLIC`, PEP luồng thì từ chối, bundle quá hạn thì từ chối hợp đồng `SENSITIVE`. Quy tắc này nằm trong một thư viện duy nhất để không điểm thực thi nào tự cài khác nhau.
4. **Không bảng ánh xạ bí danh.** Giả danh hóa dùng HMAC-SHA256 khóa theo tenant và mục đích (không đảo ngược) hoặc token hóa đảo ngược bằng OpenBao transit; PH-09 không bao giờ giữ giá trị gốc đi kèm bí danh (đề xuất ADR số 091).
5. **Ẩn danh hóa kiểm chứng được.** Job Kubernetes chạy thư viện ARX (Java, Apache-2.0), đòi k ≥ 10 và đo rủi ro tái định danh trước khi phát hành; rủi ro `HIGH` thì chặn (đề xuất ADR số 092).
6. **Phát hiện DLCN bằng bộ mẫu và kiểm tổng**, không dùng mô hình học máy ở đợt 2; kết quả quét chỉ là gợi ý, mọi đổi mức đi qua xác nhận của người (đề xuất ADR số 093).

Tập nêu bốn ADR đề xuất (số 090 đến 093), mười câu hỏi mở Q09-20…29 và mục 13.5 ghi kết quả đồng bộ với FRS 0.2 cùng các việc còn lại cho tài liệu khác.

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tập này là thiết kế chi tiết cấp mã nguồn của PH-09: cấu trúc module, miền, thuật toán, trình tự, trạng thái, lỗi, cấu hình, quan sát, kiểm thử. Phạm vi gồm 64 FR (FR-09-001…064), thành phần phía máy chủ trong `dh-data` và thư viện `dh-privacy-client` dùng ở điểm thực thi. Không thuộc phạm vi: nội dung màn hình (D03-06-PH09), lược đồ bảng (D03-03-PH09), đặc tả endpoint (D03-04-PH09), mã hóa trường (thư viện `dh-crypto`, SEC-31, ADR-032), lưu nhật ký kiểm toán (PH-13), chạy quy trình (PH-11), phát hiện sự cố (PH-18, PH-13) và quy tắc Rego (kho `dh-policies` của PH-12).

### 1.2. Người đọc

Kỹ sư `dh-data` đọc chương 3, 4, 8. Kỹ sư PH-03, 04, 06, 14, 19 đọc §4.17, §5.1, §5.2, §8.6. ATTT và pháp chế đọc chương 7 và §4.4, §4.8, §4.14. Hội đồng thẩm định đọc phần tóm tắt, chương 2, 11, 13.

### 1.3. Quy ước trong tài liệu

Tên lớp, gói, trường dùng dấu `` ` ``. Mã FR, BR, NFR, ERR, EVT, API, PERM, SEC lấy nguyên từ FRS và D03-07, enum từ FRS Phụ lục A. Số liệu chưa đo ghi "giả định" kèm cơ sở: hồ sơ tỉnh vừa (200 HTTT, 3.000 chấp thuận hiệu lực, 50.000 phần tử, 3 bản sao data plane).

### 1.4. Thuật ngữ và chữ viết tắt

Bảng ghi các thuật ngữ dùng xuyên suốt tập.


| Thuật ngữ | Nghĩa trong tài liệu |
|---|---|
| PAP, PIP, PDP, PEP | Điểm quản trị, nguồn thông tin, điểm quyết định, điểm thực thi chính sách |
| DLCN | Dữ liệu cá nhân |
| DSR | Yêu cầu của chủ thể dữ liệu (data subject request), ở FRS là `SubjectRequest` |
| Bundle | Gói dữ liệu và chính sách cho OPA, có chữ ký và hạn hiệu lực |
| Kế hoạch che | Danh sách trường và kiểu che áp cho một (vai trò, mục đích, kênh, hợp đồng) |
| Đóng an toàn | Khi thiếu chính sách thì từ chối hoặc hạ xuống mức chặt nhất, không cho qua |
| Giả danh hóa | Thay giá trị bằng bí danh, vẫn là DLCN (BR-09-031) |
| Ẩn danh hóa | Xử lý không còn đường khôi phục, kiểm chứng bằng k và rủi ro (BR-09-034) |
| ARX | Thư viện mã nguồn mở Java để ẩn danh hóa và đo rủi ro tái định danh |
| `subjectHash` | HMAC-SHA256 khóa theo tenant của định danh chủ thể (BR-09-045) |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2 và 3 nói vị trí và cấu trúc mã. Chương 4 là mô hình miền và 15 thành phần cùng thư viện `dh-privacy-client`. Chương 5 là chín sơ đồ trình tự. Chương 6 đến 12 nói đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, hiệu năng, kiểm thử. Chương 13 là lộ trình, ADR, đề nghị đồng bộ, câu hỏi mở.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Bảng dưới ghi từng tài liệu hoặc ADR và phần nội dung tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH09 FRS | 64 FR, 61 BR, 23 NFR, ERR-09, EVT-09-01…32, API-09, Phụ lục A enum |
| D03-03-PH09 CSDL | Schema `ph09_privacy`: bảng, RLS, ràng buộc, outbox và inbox |
| D03-04-PH09 API | Control plane `/api/privacy/v1`, data plane `/privacy/v1` |
| D03-01 SAD | `dh-data`, vùng mạng, OPA, OpenBao, Garage |
| D03-07 ATTT §3.2, §6 | Bốn mức phân loại, SEC-26, 31, 32, 37, 38, 39, 74, THR-51 |
| D03-10 | `TenantContext`, `app.tenant_id`, RLS |
| ADR-032 | Mã hóa envelope qua OpenBao transit |
| ADR-041, 042, 046 | Idempotency, outbox và inbox, phê duyệt bốn mắt |
| ADR đề xuất số 090…093 | Mục 13.4 |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-09 là module Modulith `privacy` trong đơn vị triển khai `dh-data` (cùng PH-06, 07, 08), chạy ở vùng Z4 ứng dụng nội bộ, dữ liệu ở schema `ph09_privacy` của `pg-core`. Control plane đi qua APISIX (Z2) tới `/api/privacy/v1`. Data plane `/privacy/v1` chỉ nhận lời gọi trong cụm bằng mTLS và danh tính SPIFFE của DU. Ba tải chạy ngoài tiến trình chính: Job Kubernetes `privacy-arx` (ẩn danh hóa), Job quét nguồn của `scanner`, và OpenBao cho khóa. Data plane chạy 3 bản sao trên 3 nút (NFR-09-021); control plane và tác vụ nền chạy chung ảnh nhưng bật theo hồ sơ (`profile=dataplane` hoặc `profile=control`), để quyết định mục đích không tranh CPU với job quét hay báo cáo.

### 2.2. Sơ đồ thành phần

Sơ đồ cho thấy các thành phần của PH-09 bên trong `dh-data`, thư viện `dh-privacy-client` ở các điểm thực thi, và các hệ lân cận (OPA, OpenBao, Kafka, Garage, PH-13).

```{.mermaid caption="Sơ đồ thành phần của PH-09 trong dh-data và các hệ lân cận"}
flowchart TB
  subgraph Z2["Z2 · Biên"]
    AX["APISIX<br/>OIDC, OPA, dh-privacy-client"]
  end
  subgraph Z4["Z4 · dh-data (module privacy)"]
    WEB["web<br/>/api/privacy/v1"]
    DEC["decision<br/>/privacy/v1"]
    CLS["classification<br/>+ scanner"]
    ROP["ropa + dpia"]
    PUR["purpose"]
    POL["policy.mask"]
    PSE["pseudonym"]
    ANO["anonymize"]
    RET["retention"]
    DSR["dsr + consent"]
    BRC["breach"]
    BUN["bundle"]
    REP["reporting"]
    CRY["crypto + audit"]
  end
  subgraph Z4b["Z4 · Điểm thực thi"]
    P04["PH-04 dh-runtime"]
    P06["PH-06"]
    OTH["PH-14, PH-19"]
  end
  JOB["Job K8s privacy-arx"]
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph09_privacy")]
    K[("Kafka t68.privacy.*")]
    GA[("Garage")]
    BAO["OpenBao transit"]
  end
  P12["PH-12 OPA, máy chủ bundle"]
  P13["PH-13 kiểm toán"]
  AX --> WEB
  AX -. "OPA cục bộ" .-> P12
  P04 --> DEC
  P06 --> DEC
  OTH --> DEC
  WEB --> CLS & ROP & PUR & POL & PSE & ANO & RET & DSR & BRC & REP
  PUR --> BUN
  POL --> BUN
  CLS --> BUN
  BUN --> P12
  DEC --> CRY
  PSE --> CRY
  CRY --> BAO
  ANO --> JOB --> GA
  RET --> PG
  WEB --> PG
  BUN --> K
  K --> P04 & P06 & OTH
  CRY --> P13
```

Hình cho thấy ba đường chính. Đường quản trị đi từ APISIX vào `web` rồi tới các thành phần nghiệp vụ. Đường chính sách đi từ `purpose`, `policy.mask`, `classification` qua `bundle` tới OPA của PH-12 và qua Kafka tới điểm thực thi. Đường thực thi đi từ PH-04, PH-06, PH-14, PH-19 tới `decision`, và mọi thao tác nhạy cảm đều đi qua `crypto + audit` để ghi vết trước khi xử lý.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng ghi hướng gọi, nội dung trao đổi và hành vi khi phụ thuộc lỗi.


| Phân hệ, hệ thống | Hướng | Nội dung | Khi lỗi |
|---|---|---|---|
| PH-12 (OPA, máy chủ bundle) | Ra | Phát bundle ký, theo dõi `bundle_loaded` | Bundle cũ còn hiệu lực đến `validUntil` |
| PH-13 | Ra | Ghi sự kiện kiểm toán qua thư viện chung, tra nhật ký theo `subjectHash` (Q09-16) | Thao tác đặc quyền bị từ chối (ERR-09-010) |
| PH-06 | Hai chiều | PH-06 đăng ký phân loại trường, nhận sự kiện đổi phân loại, hỏi kế hoạch che, nhận tác vụ DSR | PH-06 dùng đệm 5 phút rồi chỉ `PUBLIC` |
| PH-04 | Vào | `mask-plans:resolve`, `messages:apply`, `classification:check` | Dùng kế hoạch đệm, hết đệm thì đóng an toàn |
| PH-02, PH-03 | Hai chiều | Đăng ký sử dụng, kích hoạt hợp đồng `SENSITIVE` (FR-09-022), nhận EVT chấp thuận | Chặn kích hoạt khi PH-09 không trả lời |
| PH-14, PH-19 | Vào, ra | Báo lượt khai thác, tra theo băm, tác vụ DSR; PH-14 gọi thêm `purpose:decide` (lấy `ropaActivityId`) và `classification:check` với `egressScope` là `OUT_OF_PROVINCE` trước khi gửi ra ngoài tỉnh, p95 ≤ 200 ms (NFR-09-027) | Hàng chờ thử lại, cảnh báo sau 24 giờ; kiểm ra ngoài tỉnh không trả lời thì PH-14 không gửi |
| PH-11 | Ra | Hạn xử lý DSR nếu tenant bật | Đồng hồ nội bộ |
| PH-17, PH-20 | Ra | Tập ẩn danh cho AI, xóa mật mã tenant | Không phát hành, giữ trạng thái chờ |
| PH-18 | Hai chiều | Nhận sự cố có DLCN, nhận EVT vi phạm | Nhập tay vụ việc |
| OpenBao | Ra | Ký bundle, HMAC, token hóa, giải bọc khóa | ERR-09-032, ERR-09-108 |
| Garage | Ra | Lưu bundle, tập ẩn danh (SSE-C), hồ sơ xuất | Tác vụ `FAILED`, thử lại |
| Kafka | Hai chiều | Phát EVT-09, nghe sự kiện PH-06, PH-18, PH-12 | Outbox giữ, inbox chống trùng |

: Phụ thuộc của PH-09

### 2.4. Hiện trạng mã và đường chuyển

Trước đợt 2 phân loại được khai báo ngay trong mã (`@Classified`, `x-dh-classification`) và che tối thiểu ở PH-03, 12, 13. Khi PH-09 vào W4, `classification.MvpImporter` đọc các khai báo này vào trạng thái `PROPOSED` với `ClassificationSource.MVP_IMPORT` (BR-09-007), người xác nhận duyệt mẫu rồi xác nhận hàng loạt. Che tối thiểu cũ được thay bằng `dh-privacy-client` theo thứ tự PH-04, PH-06, PH-14, PH-19; mỗi điểm thực thi chuyển xong khi kiểm thử tương đương Rego (NFR-09-008) đạt.

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

Module nằm ở `apps/data/src/main/java/vn/datahub/data/privacy`, theo `CC-MOD-01…05` của D04-01: ba gói `api`, `internal`, `events`; module khác chỉ import `api` và `events`. Thư viện điểm thực thi `dh-privacy-client` là artifact riêng ở `libs/dh-privacy-client`, không phụ thuộc `internal`.

```text
vn/datahub/data/privacy/
|-- package-info.java       @ApplicationModule(allowedDependencies = {"mdm::api","rdm::api","shared"})
|-- api/                    PrivacyDecisionApi, MaskPlanApi, ClassificationLookupApi, ConsentLookupApi,
|                           PseudonymApi, dto/ (Decision, MaskPlan, FieldPlan, ...)
|-- events/                 ClassificationChanged, GrantApproved, GrantRevoked, BundlePublished,
|                           MaskPolicyActivated, DsrReceived, BreachRecorded, ... (EVT-09-01…32)
|-- internal/
    |-- classification/     DataElementService, ClassificationService, ClassificationGate, StateSecretGuard,
    |                       ContractLevelCalculator, MvpImporter, SchemaImporter, ClassificationIndexBuilder
    |-- scanner/            ScanService, ScanJobRunner, DetectorRegistry, Detectors (NationalId12, TaxId, Luhn,
    |                       PhoneVn, Email, SocialInsurance10, FieldNameHint), FindingService, SafeRegex
    |-- ropa/               ActivityService, ActivityVersioning, ActivityLinkService, LegalBasisService, RopaExporter
    |-- purpose/            PurposeService, AccessRequestService, ReviewService, GrantService, GrantScheduler,
    |                       UsageCounter, AnomalyDetector, ContractActivationGuard
    |-- policy/             MaskTypeService, MaskPolicyService, PolicyResolver, MaskSimulator, PolicyApproval,
    |                       RevealService, LogMaskConfigService, LeakScanner
    |-- pseudonym/          PseudonymDomainService, Pseudonymizer, HmacPseudonymizer, TokenPseudonymizer,
    |                       KeyLifecycleService, ReidentificationService, KeyCache
    |-- anonymize/          AnonConfigService, AnonJobService, ArxJobLauncher, RiskService, DatasetService, DataPrepService
    |-- retention/          ScheduleService, RetentionPlanner, RetentionTaskRunner, LegalHoldService,
    |                       TenantShredService, RetentionReport, OwnerPurgeClient
    |-- dsr/                SubjectRequestService, VerificationService, SubjectLookupService, SubjectTaskService,
    |                       DsrClock, DsrResponder, AccessReportService, RestrictionService
    |-- consent/            ConsentTemplateService, ConsentService, ConsentLookupService
    |-- dpia/               DpiaService, DpiaReviewScheduler, DpiaExporter
    |-- breach/             BreachService, BreachClock, NotificationService, RemediationService
    |-- decision/           PurposeDecisionService, MaskPlanService, MessageMaskService, ReportUsageService, DecisionAuditor
    |-- bundle/             BundleBuilder, BundleTester, BundleSigner, BundlePublisher, BundleRollback, SyncTracker
    |-- reporting/          DashboardService, ComplianceReportService, AuditQueryService, TenantSettingService
    |-- crypto/             PrivacyCrypto (bọc dh-crypto), SubjectHasher, HmacKeyProvider, DekCache
    |-- audit/              PrivacyAuditWriter (ghi PH-13, fail-closed), PrivilegedGuard
    |-- web/                *Controller (/api/privacy/v1), DataPlaneController (/privacy/v1), PrivacyExceptionHandler,
    |                       IdempotencyFilter, EtagSupport
    |-- persistence/        *Repository, TenantSession, OutboxWriter, InboxStore
    |-- config/             PrivacyProperties (@ConfigurationProperties "datahub.privacy"), CacheConfig, KafkaConfig
libs/dh-privacy-client/     PrivacyClient, DecisionCache, PlanCache, MaskEngine, FailSafePolicy, BundleWatcher,
                            PrivacyEventListener, UsageReporter, LogMasker
apps/data/jobs/privacy-arx/ Main.java (ARX), RiskEvaluator, manifest, Dockerfile (ảnh tối giản, người dùng không phải root)
```

### 3.2. Quy tắc phụ thuộc

Ba luật ArchUnit riêng, ngoài bộ chung của D04-01. Một: mọi lệnh đọc khóa, HMAC, giải bọc, ký chỉ đi qua `internal.crypto` và `internal.audit`; không gói nào khác import client OpenBao. Hai: giá trị DLCN rõ (kết quả giải mã, định danh chủ thể) chỉ tồn tại trong biến cục bộ của `RevealService`, `ReidentificationService`, `SubjectHasher`; các lớp này không có trường thành viên kiểu chuỗi giữ giá trị. Ba: thư viện `dh-privacy-client` không import gì từ `vn.datahub.data.privacy.internal`, chỉ dùng DTO của `api`. Gói `decision` không phụ thuộc gói nghiệp vụ nào ngoài `persistence` ở chế độ chỉ đọc, để data plane khởi động và phục vụ được từ bản chụp đệm.

### 3.3. Giao diện công bố

Module khác trong DU chỉ dùng PH-09 qua các giao diện dưới đây.


| Giao diện | Dùng bởi | Phương thức chính |
|---|---|---|
| `PrivacyDecisionApi` | PH-06, PH-08 (cùng DU) | `decide(purpose, htttId, contract, fields)`, `isRestricted(subjectHash)` |
| `MaskPlanApi` | PH-06, PH-08 | `plan(roles, purpose, channel, contract)`, `apply(plan, record)` |
| `ClassificationLookupApi` | PH-06, PH-08, PH-02 | `levelOf(kind, contractId)`, `levelOfField(elementRef)` (p95 ≤ 100 ms, NFR-09-002), `register(elementRef, proposed)` (PH-08 đề xuất phân loại cho CDE ở `PROPOSED`) |
| `ConsentLookupApi` | Module trong DU | `check(subjectHash, templateCode)` |
| `PseudonymApi` | PH-08, PH-17 | `issue(domain, values)` |
| Sự kiện `events/*` | PH-02, 03, 04, 06, 08, 12, 13, 14, 17, 19 | Phát qua outbox, EVT-09-01…32 |
| REST `/api/privacy/v1`, `/privacy/v1` | HTTT, điểm thực thi | API-09-001…237 |

: Giao diện công bố của module privacy

### 3.4. Danh sách thành phần được đặc tả

Chương 4 đặc tả 15 thành phần (mục 4.2 đến 4.16) và thư viện điểm thực thi (4.17); mỗi mục mở bằng khối đặc tả 10 mục. Mục 4.1 là mô hình miền dùng chung.

| Mục | Thành phần | Lớp chính | FR |
|---|---|---|---|
| 4.2 | `classification` | `ClassificationService`, `StateSecretGuard`, `ContractLevelCalculator` | 001…004, 006…008 |
| 4.3 | `scanner` | `ScanService`, `DetectorRegistry`, `SafeRegex` | 005 |
| 4.4 | `ropa` | `ActivityService`, `ActivityLinkService`, `RopaExporter` | 009…013 |
| 4.5 | `purpose` | `AccessRequestService`, `GrantService`, `AnomalyDetector` | 014…017, 020…022 |
| 4.6 | `policy` (che) | `PolicyResolver`, `MaskSimulator`, `RevealService`, `LeakScanner` | 023…026, 029, 030 |
| 4.7 | `pseudonym` | `Pseudonymizer`, `KeyLifecycleService`, `ReidentificationService` | 031…034 |
| 4.8 | `anonymize` | `AnonJobService`, `ArxJobLauncher`, `RiskService` | 035…039 |
| 4.9 | `retention` | `RetentionPlanner`, `RetentionTaskRunner`, `LegalHoldService` | 040…044 |
| 4.10 | `dsr` | `SubjectLookupService`, `DsrClock`, `DsrResponder` | 045…051 |
| 4.11 | `consent` | `ConsentService`, `ConsentLookupService` | 052…054 |
| 4.12 | `decision` (data plane) | `PurposeDecisionService`, `MaskPlanService`, `MessageMaskService` | 018 (phục vụ), 019, 027, 028, 032 |
| 4.13 | `dpia` | `DpiaService`, `DpiaReviewScheduler`, `DpiaExporter` | 055…057 |
| 4.14 | `breach` | `BreachService`, `BreachClock`, `NotificationService` | 058…060 |
| 4.15 | `bundle` (OPA) | `BundleBuilder`, `BundleTester`, `BundleSigner` | 018 |
| 4.16 | `reporting` | `DashboardService`, `ComplianceReportService`, `TenantSettingService` | 061…064 |
| 4.17 | `dh-privacy-client` | `PrivacyClient`, `FailSafePolicy`, `MaskEngine` | 027, 028, 030 (phía PEP) |

: Danh sách thành phần được đặc tả của PH-09

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền có chín aggregate, mỗi aggregate một người ghi (service sở hữu) để tránh tranh chấp: `DataElement` (kèm các `ElementClassification`), `ProcessingActivity` (có phiên bản), `PurposeGrant` (sinh từ `AccessRequest`), `MaskPolicy` (có phiên bản và quy tắc), `PseudonymDomain` (kèm khóa), `AnonymizationJob` (kèm báo cáo rủi ro và tập kết quả), `RetentionSchedule` (kèm tác vụ, giữ pháp lý), `SubjectRequest` (kèm tác vụ con và xác minh), `BreachCase` (kèm thông báo). Hồ sơ đồng ý, DPIA, bundle là aggregate đơn giản một bảng. Tên bảng khớp DDL `ph09_privacy` (ví dụ `data_element`, `element_classification`, `purpose_grant`, `mask_policy`, `pseudonym_key`, `subject_request`, `breach_case`, `policy_bundle`).

```{.mermaid caption="Mô hình miền cốt lõi của PH-09"}
classDiagram
  class DataElement { scope, ref, status }
  class ElementClassification { dataClass, personalDataType, identifiability, status }
  class ProcessingActivity { purpose, legalBasis, retention, status }
  class Purpose { code, statutory, allowSensitive }
  class AccessRequest { htttId, purpose, contract, fields, status }
  class PurposeGrant { validFrom, validTo, fields, quota, status }
  class MaskPolicy { version, status }
  class MaskRule { priority, dataClass, role, purpose, channel, maskType }
  class PseudonymDomain { purpose, method, status }
  class PseudonymKey { keyVersion, status, openbaoRef }
  class SubjectRequest { type, status, subjectHash, dueAt, overdue }
  class BreachCase { detectedAt, deadlineAt, status }
  DataElement "1" --> "*" ElementClassification
  ProcessingActivity "*" --> "*" DataElement : liên kết
  Purpose "1" --> "*" AccessRequest
  AccessRequest "1" --> "0..1" PurposeGrant
  MaskPolicy "1" --> "*" MaskRule
  PseudonymDomain "1" --> "*" PseudonymKey
  SubjectRequest "1" --> "*" SubjectRequest : tác vụ con
```

Sơ đồ chỉ nêu quan hệ chính. Bốn bất biến xuyên suốt, kiểm ở tầng service và ràng buộc CSDL: (1) mỗi `DataElement` có tối đa một phân loại `CONFIRMED` (BR-09-001); (2) tại một thời điểm mỗi chính sách, hoạt động, lịch lưu giữ, mẫu đồng ý, DPIA chỉ có một phiên bản `ACTIVE` (BR-09-011); (3) người đề nghị không duyệt, ba người ở chuỗi khôi phục phải khác nhau (BR-09-014, 032); (4) không đối tượng nào mang giá trị DLCN rõ trong cột, sự kiện, log (BR-09-025), chỉ băm khóa theo tenant hoặc bản mã envelope (`*_hash`, `*_enc`). Đối tượng nghiệp vụ không xóa cứng; quyền `DELETE` của tài khoản ứng dụng bị thu hồi ở D03-03.

### 4.2. Phân loại và nhãn chặn (`classification`)

::: dac-ta
**Mục đích.** Quản lý danh mục mức phân loại, loại DLCN, phần tử dữ liệu và phân loại từng trường; tính mức hợp đồng; chặn nhãn bí mật nhà nước; cung cấp bản chụp chỉ mục phân loại cho bundle và PEP.

**Lớp chính.** `DataElementService`, `ClassificationService`, `ClassificationGate`, `StateSecretGuard`, `ContractLevelCalculator`, `ClassificationIndexBuilder`, `MvpImporter`, `SchemaImporter`.

**Đơn vị chạy.** `dh-data`, control plane; `ClassificationIndexBuilder` chạy khi có sự kiện và cho phục vụ `classification-index`.

**FR hiện thực.** FR-09-001…004, 006…008; BR-09-001…007.

**Giao diện vào.** `ClassificationLookupApi`; API-09-015…018, 027…031, 243 (ngừng phần tử); sự kiện đăng ký trường từ PH-06 (FR-06-004) và lược đồ API, topic từ PH-02, PH-10.

**Phụ thuộc ra.** `crypto` + `audit`, `bundle` (kích hoạt dựng lại), `purpose.ContractActivationGuard`.

**Dữ liệu.** `data_class`, `block_label`, `personal_data_category`, `data_element`, `element_classification`, `classification_change`, `contract_level`.

**Sự kiện.** EVT-09-01 khi xác nhận hoặc đổi mức, EVT-09-03 khi mức hợp đồng đổi, EVT-09-14 khi gặp `STATE_SECRET`.

**Lỗi và xử lý.** ERR-09-005, 012, 013, 014, 015, 018, 019; không ghi được kiểm toán thì ERR-09-010.

**Quan sát.** `privacy_unclassified_fields`, `privacy_classification_change_total{direction}`, `privacy_contract_level_recompute_seconds`.
:::

`ClassificationService.confirm` kiểm ba điều: người xác nhận khác người đề xuất và là TA, SO hoặc DO của tổ chức sở hữu (BR-09-003); nếu mức mới thấp hơn mức hiện hành hoặc loại DLCN hạ từ `SENSITIVE` xuống `BASIC` hay `NONE` thì đòi số văn bản căn cứ và một người xác nhận thứ hai (BR-09-002, ERR-09-013); trường được gắn `personalDataType ≠ NONE` thì bắt buộc có `PersonalDataCategory` (ERR-09-012). Mỗi lần xác nhận ghi `classification_change` (mức cũ, mới, người, căn cứ), chuyển bản cũ sang `SUPERSEDED`, ghi outbox EVT-09-01 trong cùng giao dịch.

`ContractLevelCalculator` tính mức hợp đồng bằng mức cao nhất của các trường trong lược đồ đã đăng ký (BR-09-004). Trường chưa có phân loại `CONFIRMED` được tính `SENSITIVE` và hợp đồng mang cờ `provisional` (BR-09-001). Khi một phân loại đổi, hệ thống tra chỉ mục ngược `element -> contract` để tính lại chỉ các hợp đồng bị ảnh hưởng. Với hồ sơ tỉnh vừa tính một hợp đồng ≤ 5 giây và toàn bộ hợp đồng bị ảnh hưởng ≤ 60 giây (NFR-09-010) nhờ tính theo lô 200 hợp đồng và chỉ ghi hợp đồng đổi mức.

`StateSecretGuard` giữ danh mục nhãn `STATE_SECRET` do cán bộ bảo vệ bí mật nhà nước nhập (Q09-06). Khác các phân loại khác, nhãn chặn toàn bản tin, không lọc từng trường; thân lỗi ERR-09-101 không nêu trường nào mang nhãn (BR-09-005). Gỡ nhãn cần số và ngày văn bản giải mật cùng hai người (ERR-09-019), và là thao tác đặc quyền bị từ chối khi không ghi được kiểm toán (BR-09-057).

`ClassificationIndexBuilder` dựng bản chụp `classification-index` gồm `{path -> dataClass, personalDataType, neverReveal, noEgress}` theo hợp đồng, có `ETag` là băm nội dung. Bản chụp này dùng cho `GET /privacy/v1/classification-index` (API-09-232) và cho bundle.

### 4.3. Quét phát hiện trường nghi DLCN (`scanner`)

::: dac-ta
**Mục đích.** Tìm trường chưa phân loại nhưng có dấu hiệu là DLCN bằng bộ mẫu và kiểm tổng, để người phân loại xử lý; không tự đổi phân loại (BR-09-006).

**Lớp chính.** `ScanService`, `ScanJobRunner`, `DetectorRegistry`, bộ dò `NationalId12Detector`, `TaxIdDetector`, `LuhnCardDetector`, `PhoneVnDetector`, `EmailDetector`, `SocialInsurance10Detector`, `FieldNameHintDetector`, `SafeRegex`, `FindingService`.

**Đơn vị chạy.** `dh-data` tác vụ nền (hồ sơ `control`), lịch `09.scan.schedule-cron`; đọc nguồn qua tài khoản chỉ đọc do PH-06, PH-07 hoặc chủ quản cấp.

**FR hiện thực.** FR-09-005; BR-09-006, 025.

**Giao diện vào.** API-09-020…023; lịch nội bộ.

**Phụ thuộc ra.** Nguồn dữ liệu được quét, `classification` (tạo đề xuất `SCAN`), `audit`.

**Dữ liệu.** `detector_rule`, `scan_run`, `scan_finding`.

**Sự kiện.** EVT-09-02 khi lượt quét kết thúc.

**Lỗi và xử lý.** ERR-09-016 (mẫu không an toàn), ERR-09-017 (trùng phạm vi), ERR-09-009 (nguồn lỗi).

**Quan sát.** `privacy_scan_duration_seconds`, `privacy_scan_findings_total{detector}`, `privacy_scan_rows_total`.
:::

Bộ dò có hai lớp. Lớp cấu trúc dùng biểu thức chính quy neo đầu cuối và kiểm tổng: thẻ ngân hàng theo Luhn; số định danh 12 chữ số theo cấu trúc (3 chữ số mã tỉnh, 1 chữ số mã thế kỷ và giới, 2 chữ số năm sinh, 6 chữ số ngẫu nhiên), chưa có chữ số kiểm tra chính thức nên không kiểm tổng (Q09-07); mã số thuế 10 hoặc 13 chữ số theo trọng số; số BHXH 10 chữ số; số điện thoại Việt Nam theo đầu số; thư điện tử theo cú pháp. Lớp tên trường dùng danh sách gợi ý (`cccd`, `so_dien_thoai`, `ho_ten`...) có độ tin cậy thấp hơn. Độ tin cậy của một cột là tỉ lệ dòng mẫu khớp, nhân hệ số của loại bộ dò; chỉ cột ≥ `09.scan.confidence` (mặc định 0,8) vào hộp việc.

Hai ràng buộc an toàn. Thứ nhất, mẫu do người dùng thêm (`detector_rule`) phải qua `SafeRegex`: bị từ chối nếu có lặp lồng nhau hoặc vượt thời hạn 50 ms trên chuỗi thử dài 10.000 ký tự (ERR-09-016), tránh tấn công từ chối dịch vụ bằng biểu thức chính quy. Thứ hai, trình quét lấy mẫu `09.scan.sample-rows` dòng mỗi bảng trong bộ nhớ, chỉ lưu `scan_finding` dạng (cột, bộ dò, tỉ lệ khớp), không lưu giá trị mẫu (BR-09-025). Quét 10.000 dòng cho 500 cột chạy song song theo bảng, tối đa 4 luồng, để đạt ≤ 10 phút (NFR-09-009).

### 4.4. Sổ hoạt động xử lý (`ropa`)

::: dac-ta
**Mục đích.** Lập, duyệt, phiên bản hóa hoạt động xử lý DLCN; liên kết với trường, API, topic, luồng; quản lý cơ sở pháp lý; xuất sổ theo mẫu.

**Lớp chính.** `ActivityService`, `ActivityVersioning`, `ActivityLinkService`, `LegalBasisService`, `LegalDocumentService`, `RopaExporter`.

**Đơn vị chạy.** `dh-data`, control plane; xuất sổ chạy nền.

**FR hiện thực.** FR-09-009…013; BR-09-008…012.

**Giao diện vào.** API-09-032…053.

**Phụ thuộc ra.** `classification` (kiểm trường DLCN chưa thuộc hoạt động nào), `purpose` (mục đích), Garage (tệp xuất).

**Dữ liệu.** `legal_document`, `legal_basis`, `processing_activity`, `activity_link`.

**Sự kiện.** EVT-09-04 khi kích hoạt hoặc ngừng.

**Lỗi và xử lý.** ERR-09-020, 021, 022, 023, 024, 025, 004 (xung đột phiên bản).

**Quan sát.** `privacy_activity_total{status}`, `privacy_unlinked_pii_fields`.
:::

Hoạt động `ACTIVE` không sửa tại chỗ. `ActivityVersioning.edit` sao chép bản `ACTIVE` thành bản `DRAFT` mới, người soạn sửa, rồi gửi duyệt; kích hoạt cần người duyệt khác người soạn (BR-09-011) và đưa bản cũ sang `SUPERSEDED` trong cùng giao dịch. Kích hoạt kiểm đủ các mục bắt buộc (mục đích, cơ sở pháp lý chính duy nhất, loại dữ liệu, nhóm chủ thể, bên nhận, thời hạn lưu kèm hành động khi hết hạn, vai trò kiểm soát hoặc xử lý): thiếu thì ERR-09-020. Cơ quan nhà nước chỉ dùng `STATE_TASK` hoặc `LEGAL_OBLIGATION` làm cơ sở, `CONSENT` chỉ cho tiện ích không bắt buộc (ERR-09-024, BR-09-009).

`ActivityLinkService` bảo đảm quy tắc SEC-37: mỗi trường DLCN đã xác nhận thuộc ít nhất một hoạt động `ACTIVE` (BR-09-008). Danh sách trường chưa thuộc hoạt động nào (API-09-044) là truy vấn `data_element` có `personalDataType ≠ NONE` loại trừ `activity_link` của bản `ACTIVE`; con số này là chỉ số `privacy_unlinked_pii_fields` và là điều kiện chặn kích hoạt hợp đồng ở §4.5. `RopaExporter` dựng tệp theo mẫu `ROPA_A05` (giả định, Q09-03), không chứa giá trị DLCN, ghi vào Garage hạn tải 24 giờ.

### 4.5. Mục đích và chấp thuận khai thác (`purpose`)

::: dac-ta
**Mục đích.** Quản lý danh mục mục đích, yêu cầu khai thác theo mục đích, thẩm định và chấp thuận có điều kiện, vòng đời chấp thuận, đếm lượt khai thác, phát hiện bất thường (THR-51), chặn kích hoạt hợp đồng `SENSITIVE` khi thiếu chấp thuận (SEC-37).

**Lớp chính.** `PurposeService`, `AccessRequestService`, `ReviewService`, `GrantService`, `GrantScheduler`, `UsageCounter`, `AnomalyDetector`, `ContractActivationGuard`, `UsageReportService`.

**Đơn vị chạy.** `dh-data`, control plane; `GrantScheduler` và `AnomalyDetector` là tác vụ nền theo tenant.

**FR hiện thực.** FR-09-014…017, 020…022; BR-09-013…020.

**Giao diện vào.** API-09-054…073, 086, 087; `ContractActivationGuard` do PH-02 và PH-03 gọi; `usage-events:report` (API-09-237).

**Phụ thuộc ra.** `bundle` (kích hoạt dựng lại), PH-02 (kiểm đăng ký sử dụng), PH-11 hoặc Việc của tôi (hộp việc DO), Valkey (bộ đếm).

**Dữ liệu.** `purpose`, `purpose_element`, `access_request`, `purpose_grant`, `grant_condition`, `usage_counter`, `usage_anomaly`.

**Sự kiện.** EVT-09-05 gửi thẩm định, EVT-09-06 duyệt, 07 tạm dừng hoặc khôi phục, 08 thu hồi, 09 hết hạn, 10 sắp hết hạn, 13 bất thường.

**Lỗi và xử lý.** ERR-09-026…031, 035, 055, 005, 008; ERR-09-029 khi trùng bộ ba.

**Quan sát.** `privacy_grant_total{status}`, `privacy_request_open`, `privacy_request_age_days`, `privacy_usage_total{result}`, `privacy_anomaly_total{type}`.
:::

`GrantService.approve` tạo `PurposeGrant` từ `AccessRequest` được `APPROVE` hoặc `APPROVE_WITH_CONDITIONS`: một chấp thuận gắn đúng một bộ ba (HTTT, mục đích, hợp đồng hoặc tập trường), không chuyển nhượng (BR-09-013); chỉ DO của tổ chức chủ quản dữ liệu quyết định và người lập không duyệt yêu cầu của mình (BR-09-014); hạn tối đa `09.grant.max-days` (365) và gia hạn tối đa `09.grant.renew-max` (3) lần, hết hạn là tự chấm dứt (BR-09-015). Điều kiện `ConditionType` (`FIELD_SUBSET`, `DAILY_QUOTA`, `TIME_WINDOW`, `NO_EXPORT`, `MASK_REQUIRED`) được ghi vào `grant_condition` và đưa vào bundle (BR-09-016). `GrantScheduler` quét mỗi phút: chuyển `SCHEDULED` sang `ACTIVE` khi đến `validFrom`, chuyển `ACTIVE` hoặc `SUSPENDED` sang `EXPIRED` khi quá `validTo`, phát EVT-09-10 trước `09.grant.expiring-notice-days` ngày. Mỗi chuyển trạng thái làm đổi bundle nên gọi `BundlePublisher.requestRebuild(reason)`; riêng tạm dừng và thu hồi ghi EVT-09-07, 08 để PEP gỡ ngay (§5.4).

`ContractActivationGuard.check(contract)` là cổng của SEC-37: hợp đồng mức `SENSITIVE` phải có mục đích, chấp thuận `ACTIVE` phủ đủ trường (ERR-09-035) và mọi trường DLCN của nó thuộc hoạt động xử lý `ACTIVE` (BR-09-008); mức `RESTRICTED` chỉ cần mục đích thuộc danh mục trừ khi tenant bật `09.grant.require-restricted` (BR-09-019). Cổng trả kết quả có mã lý do để PH-02, PH-03 hiển thị và từ chối kích hoạt.

`UsageCounter` nhận lượt khai thác từ `usage-events:report` do PEP gửi theo lô, đếm theo (HTTT, mục đích, hợp đồng) bằng bộ đếm Valkey (`INCRBY` có khóa theo giờ) và ghi định kỳ về `usage_counter` mỗi phút. `AnomalyDetector` chạy 5 phút một lần (BR-09-020): `QUOTA_EXCEEDED` khi vượt hạn ngạch `DAILY_QUOTA`, cảnh báo sớm ở `09.anomaly.quota-warn-percent`; `BULK_ACCESS` khi vượt `09.anomaly.bulk-threshold` lượt mỗi giờ; `OFF_PURPOSE` khi trường ngoài `fields`; `OFF_HOURS` khi ngoài `TIME_WINDOW`; `DORMANT_REUSE` khi chấp thuận im lặng quá 90 ngày rồi dùng lại (giả định). Bất thường mức cao và `09.anomaly.auto-suspend = true` thì tự tạm dừng chấp thuận (Q09-17).

### 4.6. Chính sách che và xem đầy đủ (`policy`)

::: dac-ta
**Mục đích.** Quản lý kiểu che, soạn và phát hành chính sách che có phiên bản, mô phỏng, cấp phiếu xem giá trị đầy đủ 60 giây, cấu hình che log và quét rò rỉ.

**Lớp chính.** `MaskTypeService`, `MaskPolicyService`, `PolicyResolver`, `MaskSimulator`, `PolicyApproval`, `RevealService`, `LogMaskConfigService`, `LeakScanner`.

**Đơn vị chạy.** `dh-data`, control plane; `PolicyResolver` cũng được `decision` dùng ở data plane; `LeakScanner` là tác vụ nền `09.log.scan-cron`.

**FR hiện thực.** FR-09-023…026, 029, 030; BR-09-021…027.

**Giao diện vào.** API-09-090…108, 236 (xác thực phiếu), 241 (chi tiết phiếu xem, không kèm giá trị).

**Phụ thuộc ra.** `classification` (chỉ mục), `bundle`, `crypto` + `audit`, Loki hoặc kho log (quét rò rỉ).

**Dữ liệu.** `mask_type`, `mask_policy`, `mask_rule`, `mask_simulation`, `reveal_grant`, `log_mask_config`, `leak_finding`.

**Sự kiện.** EVT-09-12 khi kích hoạt hoặc đổi phiên bản, EVT-09-15 khi cấp phiếu vượt ngưỡng bất thường.

**Lỗi và xử lý.** ERR-09-037…044, 007, 112; ERR-09-010 khi không ghi được vết.

**Quan sát.** `privacy_mask_policy_total{status}`, `privacy_reveal_total{result}`, `privacy_leak_findings_total{source}`.
:::

`PolicyResolver.resolve(ctx, field)` là hàm thuần dùng chung cho control plane (mô phỏng), data plane và bộ ca chuẩn tương đương Rego (NFR-09-008). Thứ tự chọn quy tắc theo BR-09-022: lọc quy tắc khớp (loại DLCN, vai trò, mục đích, kênh, mức); chọn quy tắc cụ thể hơn, tính bằng số tiêu chí khác `*` (ưu tiên theo thứ tự loại DLCN, vai trò, mục đích, kênh, mức); trùng ưu tiên thì kiểu che chặt hơn thắng, với thứ tự chặt tăng dần `NONE < PARTIAL < REPLACE < GENERALIZE < KEYED_HASH < TOKENIZE < DROP`. Không quy tắc nào khớp thì áp mặc định theo mức (BR-09-021): `SENSITIVE` che mặc định, `RESTRICTED` che một phần theo vai trò, `INTERNAL` và `PUBLIC` giữ nguyên. Trường chưa phân loại được xử lý như `SENSITIVE` (BR-09-001).

Kiểu che thực hiện bằng mẫu `MaskPatternKind` ở `MaskEngine` (dùng chung với PEP): `PARTIAL` + `KEEP_LAST_N` cho số điện thoại, `KEEP_DOMAIN` cho thư điện tử, `YEAR_ONLY` cho ngày sinh, `ADMIN_LEVEL` tổng quát hóa địa chỉ lên cấp xã hoặc huyện. `KEYED_HASH` và `TOKENIZE` cần khóa nên chỉ chạy ở PH-09 (`pseudonym`). Kiểm tương thích kiểu dữ liệu (ERR-09-037) và đòi quy tắc mặc định cho mức `SENSITIVE` (ERR-09-038) khi lưu phiên bản.

`MaskSimulator` chạy `PolicyResolver` trên tối đa 1.000 dòng mẫu do người dùng đưa vào trong bộ nhớ, không ghi dữ liệu mẫu (ERR-09-039, BR-09-025), kết quả mô phỏng ghi `mask_simulation` dạng đạt hoặc không đạt kèm băm bộ mẫu. Gửi duyệt đòi mô phỏng đạt cho đúng phiên bản (ERR-09-040) và duyệt bốn mắt (BR-09-023, ADR-046). Mô phỏng 1.000 dòng ≤ 5 giây (NFR-09-023).

`RevealService.issue` thực hiện FR-09-029 theo thứ tự kiểm quyền `PERM-09-unmask` (ERR-09-041), lý do ≥ 20 ký tự (ERR-09-007), trường không `neverReveal` (ERR-09-042), hạn mức `09.mask.reveal-max-per-hour` mỗi người (ERR-09-043, đếm bằng Valkey), rồi ghi kiểm toán trước (BR-09-057) và mới cấp `reveal_grant` có `expiresAt = now + 09.mask.reveal-seconds`. Chi tiết trình tự ở §5.3. PH-09 chỉ giữ `token_hash` của phiếu, không thấy giá trị.

`LeakScanner` quét log, vết đã lưu bằng bộ dò của `scanner` (dùng lại `DetectorRegistry`), ghi `leak_finding` gồm nguồn, bộ dò, số khớp và vị trí, không ghi nội dung khớp (SEC-32, NFR-00-029). Cấu hình che log (`log_mask_config`) được thư viện log dùng chung và OTel Collector nạp qua `GET /log-masking-config`.

### 4.7. Giả danh hóa và vòng đời khóa (`pseudonym`)

::: dac-ta
**Mục đích.** Quản lý miền giả danh hóa theo tenant và mục đích; giả danh hóa lô giá trị bằng HMAC hoặc token; khôi phục giá trị gốc có duyệt; vòng đời khóa.

**Lớp chính.** `PseudonymDomainService`, `Pseudonymizer`, `HmacPseudonymizer`, `TokenPseudonymizer`, `KeyLifecycleService`, `ReidentificationService`, `KeyCache`.

**Đơn vị chạy.** `dh-data`; `Pseudonymizer` chạy ở data plane, phần còn lại ở control plane.

**FR hiện thực.** FR-09-031…034; BR-09-028…033.

**Giao diện vào.** `PseudonymApi`; API-09-109…124, 230.

**Phụ thuộc ra.** OpenBao transit (khóa, giải bọc, mã hóa có dẫn xuất), `audit`, PH-13.

**Dữ liệu.** `pseudonym_domain`, `pseudonym_key` (chỉ tham chiếu `openbao_ref`), `reidentification_request`.

**Sự kiện.** EVT-09-16 đổi trạng thái khóa, EVT-09-17 khôi phục đã thực hiện.

**Lỗi và xử lý.** ERR-09-045…050, 108, 109, 107, 110, 005.

**Quan sát.** `privacy_pseudonym_total{method}`, `privacy_pseudonym_duration_seconds{method}`, `privacy_key_cache_hit_ratio`, `privacy_key_age_days`.
:::

Hai phương pháp ứng với `PseudonymMethod`. `HMAC_SHA256`: khóa gốc của miền được tạo và giữ trong OpenBao (`openbao_ref`); `KeyCache` giải bọc một lần rồi dẫn xuất khóa làm việc bằng HKDF-SHA256 với `info = tenant | domain | keyVersion`, giữ trong bộ nhớ tối đa 5 phút, không ghi đĩa. Bí danh là `PSN-{keyVersion}-{base32(HMAC(khóaLàmViệc, giáTrịChuẩnHóa))}`. Chuẩn hóa trước khi băm: bỏ khoảng trắng đầu cuối, NFC, với số định danh giữ chỉ chữ số, để cùng giá trị cùng miền cùng phiên bản khóa luôn cho cùng bí danh (BR-09-029). Hai miền của hai mục đích dùng khóa khác nhau nên hai tập xuất không nối được (BR-09-028). Tính HMAC cục bộ đạt ≥ 2.000 giá trị mỗi giây mỗi bản sao (NFR-09-011).

`TOKEN_TRANSIT`: gọi `transit/encrypt` với khóa `dh-{tenant}-pseudo-{domain}` bật mã hóa hội tụ (`convergent_encryption`) và `context = tenant | domain`, nên cùng giá trị cho cùng token mà không cần bảng ánh xạ (BR-09-030); gọi theo lô 500 giá trị, ≥ 500 giá trị mỗi giây. Chỉ token đảo ngược được, bằng `transit/decrypt` có kiểm soát. Không lưu bảng ánh xạ bí danh với giá trị gốc ở bất cứ đâu, kể cả log.

`KeyLifecycleService` quản `KeyVersionStatus`: tạo phiên bản `ACTIVE`; xoay (`09.pseudo.key-rotate-days`, giãn cách tối thiểu `09.pseudo.min-rotate-days`, ERR-09-047) đưa bản cũ sang `DECRYPT_ONLY` và cảnh báo vì xoay phá tính nhất quán bí danh cũ mới; `DISABLED` rồi `DESTROYED` chỉ khi không còn dữ liệu cần giải bằng khóa đó, có hai người duyệt và chờ `09.pseudo.destroy-delay-days` (ERR-09-046, BR-09-033).

`ReidentificationService` thực hiện chuỗi `ReidStatus`: SO lập đề nghị (miền phải là `TOKEN_TRANSIT`, ERR-09-048, tối đa 100 giá trị, ERR-09-049), DO duyệt cấp một, TA hoặc DA duyệt cấp hai, ba người khác nhau (ERR-09-005), trong hạn `09.reid.approval-ttl-hours`; thực hiện trong `09.reid.exec-window-minutes` sau xác thực lại bước cao (MFA). Nhật ký ghi trước khi giải mã (BR-09-032, 057), kết quả trả về giao diện hiển thị 60 giây và không lưu.

### 4.8. Ẩn danh hóa (`anonymize`)

::: dac-ta
**Mục đích.** Cấu hình, chạy, đánh giá rủi ro và phát hành tập dữ liệu ẩn danh (k ≥ 10) cho AI, ngoài PROD, dữ liệu mở.

**Lớp chính.** `AnonConfigService`, `AnonJobService`, `ArxJobLauncher`, `RiskService`, `DatasetService`, `DataPrepService`.

**Đơn vị chạy.** Điều phối ở `dh-data`; xử lý ở Job Kubernetes `privacy-arx` (Java, ARX).

**FR hiện thực.** FR-09-035…039; BR-09-034…037.

**Giao diện vào.** API-09-125…144.

**Phụ thuộc ra.** Kubernetes (tạo Job), Garage (tập đầu vào và đầu ra, SSE-C), PH-17 (nhận tập), `classification`, `audit`.

**Dữ liệu.** `anonymization_config`, `anonymization_job`, `risk_report`, `anonymized_dataset`.

**Sự kiện.** EVT-09-18 khi tập phát hành, rút hoặc hết hạn.

**Lỗi và xử lý.** ERR-09-051…056, 009.

**Quan sát.** `privacy_anon_job_total{status}`, `privacy_anon_job_duration_seconds`, `privacy_anon_k_actual`, `privacy_anon_risk_total{level}`.
:::

Cấu hình (`anonymization_config`, có phiên bản theo `VersionStatus`) gán cho từng trường một `IdentifiabilityType` và một `AnonTransform`: trường `DIRECT` bắt buộc `REMOVE` (ERR-09-052), trường `QUASI` dùng `GENERALIZE`, `BUCKET`, `ROUND`, `DATE_SHIFT` kèm phân cấp tổng quát (ví dụ ngày sinh, tháng, năm, thập niên; xã, huyện, tỉnh), trường `SENSITIVE_ATTR` cần mô hình `L_DIVERSITY` khi tenant bật (BR-09-036). `k` không dưới `09.anon.k-min` (sàn 10, ERR-09-051).

`ArxJobLauncher` tạo Job `privacy-arx-{tenant}-{jobId}` với tài khoản dịch vụ riêng, `NetworkPolicy` chỉ tới Garage, không root, hệ tệp gốc chỉ đọc, ảnh ký cosign. Bản đầu vào không đi qua PH-09: nguồn được xuất vào Garage mã hóa SSE-C bởi phân hệ sở hữu, Job đọc bằng khóa tạm do `crypto` cấp và hủy sau khi xong. ARX tìm phép tổng quát hóa tối ưu theo thuật toán Flash, ràng buộc `K_ANONYMITY` (và `L_DIVERSITY`), chấp nhận loại bỏ dòng (suppression) tối đa 70% (tức còn ≥ 30%, ERR-09-054). Không đạt k thì `AnonJobService` tăng mức tổng quát hóa, tối đa ba vòng (BR-09-035); vẫn không đạt thì `REJECTED_RISK` hoặc `FAILED` với ERR-09-054. Job chỉ ghi `k_actual`, số dòng trước và sau, tập kết quả; không lưu ánh xạ hay khóa giải (BR-09-034).

`RiskService` đọc kết quả của `RiskEvaluator` (trong Job) theo ba mô hình `PROSECUTOR`, `JOURNALIST`, `MARKETER` (mặc định người truy tố, Q09-08), xếp `LOW`, `MEDIUM`, `HIGH` theo ngưỡng `09.anon.risk-medium-above` (0,05) và `09.anon.risk-high-above` (0,10). `HIGH` thì job sang `REJECTED_RISK`, không phát hành (ERR-09-053). `MEDIUM` chuyển `AWAITING_RISK_REVIEW` chờ SO duyệt. `DataPrepService` thêm điều kiện đích (BR-09-037): ngoài PROD chỉ dữ liệu sinh hoặc giả danh hóa không đảo ngược, `SENSITIVE` thật cấm, dữ liệu cho AI chỉ ẩn danh hoặc `RESTRICTED` khi `09.ai.allow-restricted` bật và mô hình chạy nội bộ (SEC-38, SEC-49). Mục đích không cho dữ liệu có trường `SENSITIVE` thì ERR-09-055. Tập đã `PUBLISHED` không sửa (ERR-09-056).

### 4.9. Thời hạn lưu và xóa (`retention`)

::: dac-ta
**Mục đích.** Lập lịch lưu giữ theo bảng và loại DLCN, chạy tác vụ xóa hoặc giả danh hóa khi hết hạn, giữ pháp lý, xóa mật mã khi chấm dứt tenant, báo cáo tuân thủ.

**Lớp chính.** `ScheduleService`, `RetentionPlanner`, `RetentionTaskRunner`, `OwnerPurgeClient`, `LegalHoldService`, `TenantShredService`, `RetentionReport`.

**Đơn vị chạy.** `dh-data`, tác vụ nền theo `09.retention.run-cron`; ShedLock theo (tenant, bảng).

**FR hiện thực.** FR-09-040…044; BR-09-038…041.

**Giao diện vào.** API-09-145…163.

**Phụ thuộc ra.** API xóa và giả danh hóa của phân hệ sở hữu bảng (PH-06, PH-19, PH-13...), OpenBao (hủy KEK), PH-20.

**Dữ liệu.** `retention_schedule`, `retention_schedule_line`, `retention_task`, `legal_hold`, `tenant_shred_request`.

**Sự kiện.** EVT-09-19 tác vụ kết thúc, EVT-09-20 giữ pháp lý đổi, EVT-09-21 xóa mật mã hoàn tất.

**Lỗi và xử lý.** ERR-09-057…061, 009.

**Quan sát.** `privacy_retention_rows_total{action}`, `privacy_retention_overdue_tables`, `privacy_retention_task_duration_seconds`, `privacy_legal_hold_active`.
:::

Nguyên tắc: PH-09 không tự xóa dữ liệu của phân hệ khác. `RetentionPlanner` đọc `retention_schedule_line` (bảng, cột mốc thời gian, thời hạn, `RetentionAction` `DELETE`, `PSEUDONYMIZE`, `ANONYMIZE`, `ARCHIVE`), gọi `OwnerPurgeClient` tới API lô của phân hệ sở hữu theo hợp đồng `retention:purge(table, cutoff, action, hold-ids, dryRun)`. Phân hệ sở hữu thực hiện trong CSDL của mình và trả số lượng quét, số lượng ảnh hưởng, số lượng bỏ qua do giữ pháp lý. Tác vụ chạy theo lô 10.000 dòng, thử lại lô lỗi tối đa ba lần rồi `FAILED` kèm cảnh báo; mỗi bảng chỉ một tác vụ tại một thời điểm (ERR-09-061). Chạy thử (`dry_run`) chỉ trả số lượng. Hết hạn 24 giờ sau lịch mà chưa xử lý thì tính vào `privacy_retention_overdue_tables`, cảnh báo sau `09.retention.overdue-days` (NFR-09-018).

`LegalHoldService` ghi giữ pháp lý (số văn bản, cơ quan, hạn rà soát, ERR-09-059) và mở rộng thành danh sách `hold_ids` truyền cho phân hệ sở hữu; bản ghi thuộc đối tượng đang giữ không bị xóa (ERR-09-058, BR-09-039). Nhật ký kiểm toán WORM và bản sao lưu bất biến nằm ngoài lịch này: sao lưu hết hạn tự nhiên tối đa 35 ngày, khôi phục phải áp lại danh sách xóa (tombstone) trước khi phục vụ (BR-09-040, SEC-39).

`TenantShredService` xử lý xóa mật mã khi chấm dứt tenant theo `CryptoShredStatus`: kiểm điều kiện bàn giao dữ liệu theo PH-20 (ERR-09-060), hai người duyệt, chờ `09.shred.delay-days` (sàn 7 ngày, có thể hủy trong thời gian chờ), rồi hủy KEK `dh-{tenant}-pii` ở OpenBao và phát EVT-09-21. Không hoàn tác (BR-09-041), nên thao tác bị từ chối nếu không ghi được kiểm toán.

### 4.10. Quyền của chủ thể dữ liệu (`dsr`)

::: dac-ta
**Mục đích.** Tiếp nhận yêu cầu của chủ thể, xác minh danh tính, tra cứu dữ liệu về chủ thể theo băm định danh, phân công và chuyển xử lý, theo dõi hạn, trả lời, đóng, báo cáo "ai đã truy cập dữ liệu của tôi".

**Lớp chính.** `SubjectRequestService`, `VerificationService`, `SubjectLookupService`, `SubjectTaskService`, `DsrClock`, `DsrResponder`, `RestrictionService`, `AccessReportService`, `SubjectHasher`.

**Đơn vị chạy.** `dh-data`, control plane; `DsrClock` là tác vụ nền mỗi giờ.

**FR hiện thực.** FR-09-045…051; BR-09-042…048, 061.

**Giao diện vào.** API-09-164…181, 235, 242 (gia hạn hạn trả lời), 244 (rút yêu cầu).

**Phụ thuộc ra.** PH-06, PH-19, PH-13, PH-14 (bộ tra theo băm), PH-11 (hạn, nếu bật), `crypto`.

**Dữ liệu.** `subject_request`, `subject_verification`, `subject_task`.

**Sự kiện.** EVT-09-22 đến 26.

**Lỗi và xử lý.** ERR-09-062…068, 063, 066, 106.

**Quan sát.** `privacy_dsr_total{type,status}`, `privacy_dsr_overdue`, `privacy_dsr_age_days`, `privacy_dsr_lookup_duration_seconds{target}`.
:::

Tiếp nhận (`SubjectRequestService.receive`, bắt buộc `Idempotency-Key`, BR-09-061) tính `subjectHash = HMAC-SHA256(khóaTenant, chuẩnHóa(định danh))` bằng `SubjectHasher`, mã hóa envelope định danh rõ và nội dung vào `identifier_enc`, `content_enc`, rồi bỏ giá trị rõ khỏi bộ nhớ. Từ đó mọi tra cứu chỉ dùng băm (BR-09-045). Chủ thể đã có yêu cầu cùng loại đang xử lý thì ERR-09-064. Hạn `due_at` = ngày hợp lệ cộng `09.dsr.sla-days` ngày làm việc, tính bằng lịch ngày nghỉ của PH-07 (giả định Q09-02); đồng hồ chạy khi xác minh đạt (BR-09-043). Chưa xác minh thì chỉ tiếp nhận, không tra cứu, không trả lời (BR-09-042, ERR-09-063).

`SubjectLookupService.search` gọi song song, thời hạn 5 giây mỗi bên, tới bộ tra của PH-06, PH-19, PH-13, PH-14 và bên kiểm soát đã đăng ký, chỉ truyền `subjectHash`. Mỗi bên trả `{count, dataTypes[], location}`, không trả giá trị. Nơi chưa hỗ trợ ghi "chưa tra cứu tự động" để cán bộ nhập tay (Q09-16 quyết định PH-13 có tra được theo băm hay phải quét theo định danh rõ). Tác vụ con (`DsrTarget`: `PH06_MASTER`, `PH19_PAYMENT`, `CONTROLLER`, `MANUAL`) sinh theo loại yêu cầu: `ERASE` và `RECTIFY` chuyển cho phân hệ sở hữu qua EVT-09-22 và API tác vụ, `CONTROLLER` dùng cho dữ liệu đi qua mà Datahub chỉ là bên xử lý và không lưu nội dung (BR-09-044), `RESTRICT` đặt cờ `restriction_active` để `decision` chặn mọi mục đích không `statutory` (BR-09-047, EVT-09-26). Yêu cầu xóa không áp dụng khi có căn cứ pháp lý phải giữ hoặc dữ liệu có nguồn thẩm quyền quốc gia: câu trả lời nêu căn cứ (BR-09-046, Q09-04).

`DsrClock` mỗi giờ nhắc trước `09.dsr.remind-days` ngày làm việc (EVT-09-23, 100%), đặt cờ `overdue` và phát EVT-09-24 khi quá hạn; quá hạn là cờ, không phải trạng thái (§8.1). `DsrResponder.respond` đòi kết quả `DsrOutcome` và tệp bằng chứng (ERR-09-068); `close` đòi mọi tác vụ con `DONE` hoặc `REFUSED` (ERR-09-067); hồ sơ lưu 5 năm (BR-09-048). `AccessReportService` lập báo cáo "ai đã truy cập dữ liệu của tôi" bằng cách hỏi PH-13 theo `subjectHash` và đã che người truy cập về mức tổ chức.

### 4.11. Sự đồng ý (`consent`)

::: dac-ta
**Mục đích.** Quản lý mẫu đồng ý, ghi nhận và rút đồng ý kèm bằng chứng, cho PEP tra trạng thái đồng ý đối với tiện ích không bắt buộc.

**Lớp chính.** `ConsentTemplateService`, `ConsentService`, `ConsentLookupService`.

**Đơn vị chạy.** `dh-data`, control plane và data plane (tra cứu).

**FR hiện thực.** FR-09-052…054; BR-09-049…051.

**Giao diện vào.** API-09-182…191, 234, 238 (chi tiết mẫu), 245 (tra đồng ý theo định danh trong thân).

**Phụ thuộc ra.** `crypto` (băm chủ thể), Valkey (đệm), `ropa` (mục đích).

**Dữ liệu.** `consent_template`, `consent_record`.

**Sự kiện.** EVT-09-27, 28.

**Lỗi và xử lý.** ERR-09-069…072.

**Quan sát.** `privacy_consent_total{status}`, `privacy_consent_check_total{result}`, `privacy_consent_check_seconds`.
:::

Mẫu đồng ý dùng vòng đời `VersionStatus`; mẫu đã có người đồng ý không sửa, tạo phiên bản mới (ERR-09-070). Bằng chứng (BR-09-050) gồm `subjectHash`, mã và phiên bản mẫu, băm SHA-256 của nội dung đã hiển thị, thời điểm, kênh `ConsentChannel`, người ghi nhận; thiếu thì ERR-09-071. Rút đồng ý chuyển `GIVEN` sang `WITHDRAWN`, ghi outbox EVT-09-28 và xóa khóa đệm tương ứng; có hiệu lực tại tra cứu trong 60 giây (BR-09-051) nhờ đệm phía PEP không quá `09.consent.cache-seconds` (trần 60) cộng sự kiện xóa đệm. Rút đồng ý không làm mất hiệu lực xử lý đã thực hiện trước đó. `ConsentLookupService.check` trả `{status, templateVersion}` theo `subjectHash` và `templateCode`; chỉ dùng cho tiện ích không bắt buộc, không bao giờ là điều kiện thực hiện thủ tục hành chính (BR-09-049).

### 4.12. Quyết định tại data plane (`decision`)

::: dac-ta
**Mục đích.** Phục vụ nội bộ cho điểm thực thi: quyết định mục đích, kế hoạch che, áp che bản tin, giả danh hóa lô, kiểm nhãn chặn, chỉ mục phân loại, bundle hiện hành, tra đồng ý, băm chủ thể, xác thực phiếu xem, báo lượt khai thác.

**Lớp chính.** `PurposeDecisionService`, `MaskPlanService`, `MessageMaskService`, `ReportUsageService`, `DecisionAuditor`, `DataPlaneController`.

**Đơn vị chạy.** `dh-data` hồ sơ `dataplane`, 3 bản sao, mTLS với danh tính SPIFFE.

**FR hiện thực.** FR-09-019, 027, 028, và phần phục vụ của 018, 032, 054, 047, 029, 020; BR-09-062.

**Giao diện vào.** API-09-227…237.

**Phụ thuộc ra.** Bản chụp trong bộ nhớ (chính sách, phân loại, chấp thuận), `pseudonym`, `audit`, OpenBao. Không phụ thuộc CSDL để trả lời, chỉ để nạp bản chụp.

**Dữ liệu.** Đọc `purpose_grant`, `mask_policy`, `element_classification`, `policy_bundle`; ghi `usage_counter` qua Valkey.

**Sự kiện.** Không phát; tiêu thụ EVT-09-01, 06, 07, 08, 09, 12 để làm mới bản chụp.

**Lỗi và xử lý.** ERR-09-101…113.

**Quan sát.** `privacy_decide_total{result}`, `privacy_decide_seconds`, `privacy_mask_total{type}`, `privacy_blocked_total{reason}`, `privacy_snapshot_age_seconds`.
:::

Data plane trả lời từ một **bản chụp bất biến trong bộ nhớ** (`PolicySnapshot`) gồm ba chỉ mục: chấp thuận `ACTIVE` theo (HTTT, mục đích, hợp đồng), kế hoạch theo (vai trò, mục đích, kênh, hợp đồng) và mức phân loại theo đường dẫn trường. Bản chụp được thay nguyên khối bằng hoán đổi tham chiếu nguyên tử khi nhận sự kiện hoặc khi `snapshot_version` ở CSDL đổi (thăm dò 5 giây), nên lời gọi quyết định không đọc CSDL (p95 ≤ 50 ms trực tiếp, NFR-09-001). Khởi động nguội nạp bản chụp từ CSDL trước khi báo `ready`; dịch vụ không phục vụ yêu cầu khi chưa có bản chụp (kiểm tra `readiness`).

`PurposeDecisionService.decide` làm đúng bốn bước của FR-09-019: nhãn chặn (ERR-09-101, trả `DENY` lý do `STATE_SECRET`), mức hợp đồng tra từ chỉ mục, kiểm theo mức (BR-09-019) và chủ thể bị hạn chế (BR-09-047). Kết quả là `200` với `decision` `ALLOW` hoặc `DENY`, `reasonCode`, `allowedFields[]`, `obligations[]` (ví dụ `MASK_REQUIRED`, `NO_EXPORT`), `grantId`, `planVersion`, `ropaActivityId`. `ropaActivityId` lấy từ `activity_link` (đích `API`, `TOPIC` hoặc `FLOW` trùng hợp đồng) của hoạt động xử lý `ACTIVE`, vắng khi không có, và đọc từ bản chụp bộ nhớ nạp cùng bundle nên không thêm truy vấn CSDL (chủ đầu tư chốt 27/11/2026). Thiếu mục đích thì ERR-09-103, bên gọi ngoài danh sách thì ERR-09-111. `DecisionAuditor` ghi kiểm toán tổng hợp theo lô mỗi 5 giây, riêng quyết định `SENSITIVE` ghi từng lượt (NFR-09-013).

`ClassificationCheckService` (cùng `DataPlaneController`) xử lý `classification:check`: nhãn chặn như cũ; khi `egressScope` là `OUT_OF_PROVINCE`, tra cờ `noEgress` của từng trường trong bản chụp chỉ mục và trả `egressBlocked`, `egressBlockedFields[]`. Trường chưa `CONFIRMED` hoặc chưa có trong chỉ mục xử lý như `noEgress` bật (BR-09-063). Lời gọi p95 ≤ 200 ms cho 200 trường (NFR-09-027); PH-09 không khả dụng thì PH-14 không gửi (ERR-14-132). Đây là quyết định của chủ đầu tư ngày 27/11/2026.

`MessageMaskService.apply` thực hiện FR-09-028: kiểm nhãn chặn và kích thước (≤ 1 MiB, ERR-09-107); áp `PARTIAL`, `REPLACE`, `GENERALIZE`, `DROP` bằng `MaskEngine` dùng chung; chuyển `KEYED_HASH`, `TOKENIZE` cho `Pseudonymizer` theo lô; trường chưa phân loại bị `DROP`. Ghi kiểm toán số lượng theo trường trước khi trả kết quả (ERR-09-110 nếu không ghi được). Không ghi bản tin, không đưa giá trị vào log hay trace (BR-09-025). Lời gọi `messages:apply` p95 ≤ 30 ms với bản tin 10 KB không băm có khóa (NFR-09-003).

### 4.13. Đánh giá tác động DLCN (`dpia`)

::: dac-ta
**Mục đích.** Lập, duyệt, phiên bản, nhắc rà soát và xuất hồ sơ đánh giá tác động xử lý DLCN gửi Cục A05, cho bên kiểm soát và bên xử lý.

**Lớp chính.** `DpiaService`, `DpiaReviewScheduler`, `DpiaExporter`.

**Đơn vị chạy.** `dh-data`, control plane; bộ nhắc là tác vụ nền hằng ngày.

**FR hiện thực.** FR-09-055…057; BR-09-052, 053.

**Giao diện vào.** API-09-192…201.

**Phụ thuộc ra.** `ropa` (hoạt động liên quan), Garage, PH-11 hoặc Việc của tôi.

**Dữ liệu.** `dpia_record`.

**Sự kiện.** EVT-09-29 đến hạn rà soát.

**Lỗi và xử lý.** ERR-09-073, 074.

**Quan sát.** `privacy_dpia_total{status}`, `privacy_dpia_review_due`.
:::

Hồ sơ dùng vòng đời `DpiaStatus` (như `VersionStatus` cộng `SUBMITTED_A05`) và hai loại `DpiaKind` `PROCESSING`, `CROSS_BORDER`. Kích hoạt đòi đủ mục (mô tả xử lý, cần thiết và tương xứng, rủi ro, biện pháp, tham chiếu hoạt động xử lý, ERR-09-073). `DpiaReviewScheduler` đặt `next_review_at` = kích hoạt cộng `09.dpia.review-months` tháng (12), nhắc trước 30 ngày và phát EVT-09-29; thêm hoặc sửa hoạt động có rủi ro cao cũng đặt lại hạn rà soát sớm (BR-09-053). Xuất gửi Cục A05 chỉ khi hồ sơ `ACTIVE` (ERR-09-074) và dùng mẫu giả định đến khi có mẫu chính thức (Q09-03, Q09-12).

### 4.14. Vi phạm DLCN và đồng hồ 72 giờ (`breach`)

::: dac-ta
**Mục đích.** Ghi nhận vi phạm DLCN, đánh giá ảnh hưởng, chạy đồng hồ 72 giờ, quản lý thông báo Cục A05 và chủ thể, hồ sơ khắc phục.

**Lớp chính.** `BreachService`, `BreachClock`, `NotificationService`, `RemediationService`.

**Đơn vị chạy.** `dh-data`, control plane; `BreachClock` là tác vụ nền mỗi phút.

**FR hiện thực.** FR-09-058…060; BR-09-054…057.

**Giao diện vào.** API-09-202…214, 239, 240 (liệt kê thông báo và biện pháp khắc phục); sự cố có DLCN từ PH-18 qua API-09-203 bằng tài khoản máy `privacy:register` (`source = INCIDENT_PH18`, khóa lũy đẳng theo mã sự cố), sự kiện sự cố từ PH-18, cảnh báo từ `purpose.AnomalyDetector` và PH-13.

**Phụ thuộc ra.** PH-18, PH-13 (kiểm toán, mẫu báo cáo), `audit`.

**Dữ liệu.** `breach_case`, `breach_notification`, `breach_action`.

**Sự kiện.** EVT-09-30 ghi nhận, EVT-09-31 mốc cảnh báo, EVT-09-32 đã thông báo.

**Lỗi và xử lý.** ERR-09-075…077, 006.

**Quan sát.** `privacy_breach_clock_seconds`, `privacy_breach_open{status}`, `privacy_breach_notified_in_time_total`.
:::

`BreachService.record` đặt `detectedAt` (bắt buộc cùng mô tả, ERR-09-075) và tính `deadlineAt = detectedAt + 72 giờ` một lần, không dừng hay đặt lại (BR-09-054). Hồ sơ chỉ ghi số lượng, loại, băm, không giá trị DLCN (BR-09-056). Nguồn `BreachSource` gồm `PERSON`, `INCIDENT_PH18`, `AUDIT_PH13`, `ANOMALY`; sự cố PH-18 có đánh dấu DLCN tự tạo vụ ở `REPORTED` kèm `incident_ref`. `BreachClock` tính còn lại theo thời gian thực và phát EVT-09-31 ở các mốc `09.breach.alert-hours` (24, 48, 60 giờ, sai số ±1 phút, NFR-09-017) cho SO, TA, DA. Thông báo tạo ở `DRAFT`, SO gửi ngoài hệ thống rồi `mark-sent` kèm bằng chứng, phát EVT-09-32 và chuyển `NOTIFIED`. Không thông báo chủ thể phải nêu căn cứ miễn và lý do (ERR-09-077) và SO duyệt; đóng hồ sơ đòi mọi nghĩa vụ thông báo hoàn tất (ERR-09-076). Bên xử lý dữ liệu báo vụ việc cho tỉnh trong 24 giờ (SEC-74, Q09-13) nên đồng hồ tỉnh bắt đầu từ thời điểm bên xử lý phát hiện nếu có.

### 4.15. Dựng và phát hành bundle OPA (`bundle`)

::: dac-ta
**Mục đích.** Dựng tài liệu dữ liệu chính sách từ chấp thuận, chính sách che, chỉ mục phân loại; kiểm thử; ký; phát hành cho OPA của PH-12; theo dõi nạp; quay lại bản trước.

**Lớp chính.** `BundleBuilder`, `BundleTester`, `BundleSigner`, `BundlePublisher`, `BundleRollback`, `SyncTracker`.

**Đơn vị chạy.** `dh-data`, một bản sao giữ khóa dẫn đầu (ShedLock theo tenant); phục vụ `bundles/current` ở data plane.

**FR hiện thực.** FR-09-018; BR-09-017, 018.

**Giao diện vào.** API-09-074…078, 233; yêu cầu dựng lại từ `purpose`, `policy`, `classification`.

**Phụ thuộc ra.** OpenBao (`transit/sign`), kho `dh-policies` và máy chủ bundle PH-12, Garage, `opa test`.

**Dữ liệu.** `policy_bundle`.

**Sự kiện.** EVT-09-11 bundle phát hành.

**Lỗi và xử lý.** ERR-09-032, 033.

**Quan sát.** `privacy_bundle_age_seconds`, `privacy_bundle_build_seconds`, `privacy_bundle_size_bytes`, `privacy_bundle_loaded_total{opa}`, `privacy_bundle_publish_total{result}`.
:::

`BundleBuilder` dựng `data.json` gồm `purpose_grants` (HTTT, mục đích, hợp đồng, trường, điều kiện, hiệu lực), `mask_policies` (quy tắc đã giải thành bảng tra) và `classification_index`, kèm `bundleId` và `content_hash` SHA-256. Luật Rego không nằm ở bundle này mà ở `dh-policies` của PH-12; PH-09 chỉ cấp dữ liệu. `BundleTester` chạy `opa test` trên bộ ca chuẩn ≥ 300 ca (NFR-09-008) và đòi bundle ≤ 5 MB (NFR-09-020); lỗi thì ERR-09-033, không phát hành. `BundleSigner` ký băm bằng khóa transit không xuất được (SEC-36), `validUntil = now + 09.bundle.valid-minutes` (BR-09-018). Chi tiết trình tự ở §5.4. Bundle cũ vẫn có hiệu lực khi không ký được (ERR-09-032); làm mới định kỳ chỉ gia hạn `validUntil` khi nội dung không đổi (ký lại cùng băm, giữ `bundleId`). `BundleRollback` phát hành lại nội dung bản trước dưới `bundle_no` mới, giữ lịch sử tuyến tính.

### 4.16. Giám sát, báo cáo và cấu hình (`reporting`)

::: dac-ta
**Mục đích.** Ghi vết thao tác bảo vệ dữ liệu, bảng điều khiển tuân thủ, báo cáo định kỳ, cấu hình tham số `09.*` của tenant.

**Lớp chính.** `PrivacyAuditWriter`, `AuditQueryService`, `DashboardService`, `ComplianceReportService`, `TenantSettingService`.

**Đơn vị chạy.** `dh-data`, control plane; báo cáo là tác vụ nền `09.report.schedule-cron`.

**FR hiện thực.** FR-09-061…064; BR-09-057…060.

**Giao diện vào.** API-09-215 trở đi (nhật ký, bảng điều khiển, báo cáo, cài đặt).

**Phụ thuộc ra.** PH-13 (nhật ký kiểm toán WORM), Prometheus, Garage.

**Dữ liệu.** `privacy_audit_event`, `compliance_report`, `tenant_setting`.

**Sự kiện.** Không riêng; tham số đổi làm mới bản chụp cấu hình.

**Lỗi và xử lý.** ERR-09-036, 078, 010.

**Quan sát.** `privacy_audit_write_failure_total`, `privacy_report_duration_seconds`, `privacy_setting_change_total`.
:::

`PrivacyAuditWriter` ghi sự kiện kiểm toán qua thư viện chung vào PH-13 và bản sao `privacy_audit_event` để tra nhanh; mọi bản ghi chỉ chứa tên trường, băm khóa, số lượng (BR-09-058). Thao tác ghi, đặc quyền và quyết định `SENSITIVE` đều phải ghi được; nếu không thì `PrivilegedGuard` từ chối (ERR-09-010, BR-09-057). Tra nhật ký tối đa `09.audit.query-max-days` ngày mỗi lần (ERR-09-036). `TenantSettingService.set` kiểm miền và trần, sàn do PA đặt (ERR-09-078, BR-09-059), lưu `tenant_setting` có phiên bản và áp dụng không cần khởi động lại nhờ `@RefreshScope` kiểu thủ công qua sự kiện nội bộ. `DashboardService` tổng hợp từ Prometheus và truy vấn nhẹ, làm mới 60 giây.

### 4.17. Thư viện điểm thực thi `dh-privacy-client`

::: dac-ta
**Mục đích.** Cho mọi điểm thực thi (APISIX plugin, PH-04, PH-06, PH-14, PH-19; PH-17 ở chế độ chỉ phân loại) một cách dùng thống nhất: hỏi quyết định, lấy và đệm kế hoạch che, áp che, đóng an toàn, báo lượt khai thác, che log.

**Lớp chính.** `PrivacyClient`, `DecisionCache`, `PlanCache`, `MaskEngine`, `FailSafePolicy`, `BundleWatcher`, `PrivacyEventListener`, `UsageReporter`, `LogMasker`.

**Đơn vị chạy.** Trong tiến trình của điểm thực thi; artifact `libs/dh-privacy-client` (Java), cùng ngữ nghĩa với bản Lua cho APISIX gọi OPA cục bộ.

**FR hiện thực.** FR-09-027, 028, 030 (phía PEP); BR-09-027, BR-09-062; NFR-09-024.

**Giao diện vào.** `PrivacyClient.decide`, `plan`, `applyLocal`, `report`, `classify` (chế độ `ClassificationOnly`); cấu hình `datahub.privacy.client.*`.

**Phụ thuộc ra.** `/privacy/v1` (mTLS), Kafka (nghe EVT-09), OPA cục bộ.

**Dữ liệu.** Chỉ bộ nhớ, không ghi đĩa.

**Sự kiện.** Tiêu thụ EVT-09-01, 03, 07, 08, 09, 12; không phát.

**Lỗi và xử lý.** ERR-09-101…113 ở phía bên gọi; ERR-04-109 của PH-04.

**Quan sát.** `privacy_client_cache_hit_ratio`, `privacy_client_fallback_total{mode}`, `privacy_client_call_seconds`, `privacy_client_stale_serve_total`.
:::

**Chế độ chỉ phân loại (`ClassificationOnly`).** Với `dh-assist` (PH-17) khi lập chỉ mục, `PrivacyClient` khởi tạo ở chế độ này: chỉ dùng `classification:check` (API-09-231) và đọc `classification-index` (API-09-232) có `ETag` với `If-None-Match`, nghe EVT-09-01 và EVT-09-03 để xóa đệm, không gọi `decide`, `plan` hay `apply`. Không rõ mức của trường thì bên gọi bỏ qua tài liệu (đóng an toàn). Tập ẩn danh cho AI đọc qua EVT-09-18 và API-09-137.

Thiết kế đệm và đóng an toàn nằm ở §8.6 vì áp dụng cho mọi PEP. Điểm cần chốt ở đây là thư viện không chứa luật nghiệp vụ: quyết định `ALLOW` hoặc `DENY` do OPA cục bộ hoặc `decide` trả, thư viện chỉ đệm, hết hạn đệm, áp `PolicyResolver` kết quả (bảng kế hoạch) bằng `MaskEngine` và chọn hành vi khi thiếu chính sách. `MaskEngine` dùng cùng mã với `PolicyResolver`, kiểm bằng ca tương đương mỗi lần phát hành (NFR-09-008).

## 5. Biểu đồ tuần tự

Chín luồng dưới đây là các FR nhiều bước, có giao dịch, đệm hoặc tác vụ nền. Thông điệp ngắn, không chứa dấu chấm phẩy; bước kiểm tra lỗi được nêu ở đoạn thuyết minh sau mỗi hình.

### 5.1. Quyết định mục đích tại PEP có đệm (FR-09-019, 020, 022)

Luồng này cho thấy khi nào PEP trả lời từ đệm, khi nào hỏi OPA và khi nào gọi PH-09.


```{.mermaid caption="Quyết định mục đích tại điểm thực thi với đệm và gọi trực tiếp"}
sequenceDiagram
  autonumber
  participant C as HTTT gọi API
  participant P as PEP + dh-privacy-client
  participant O as OPA cục bộ
  participant D as PH-09 decision
  C->>P: Yêu cầu kèm scope purpose
  P->>P: Tra DecisionCache theo khóa
  alt Trúng đệm còn hạn
    P-->>C: Kết quả đệm
  else Không trúng
    P->>O: Đánh giá bundle ký
    alt Bundle còn hạn và hợp lệ
      O-->>P: ALLOW hoặc DENY kèm lý do
    else Bundle quá hạn hoặc cần giải thích
      P->>D: purpose:decide
      D-->>P: decision, allowedFields, obligations
    end
    P->>P: Ghi đệm ngắn
    P-->>C: Cho qua hoặc 403 ERR-09-102
  end
  P--)D: usage-events:report theo lô
```

Khóa đệm là (`purpose`, `htttId`, `contract`, băm danh sách trường, cờ chủ thể bị hạn chế). Đệm kết quả `ALLOW` sống tối đa 15 giây và bị xóa ngay khi nhận EVT-09-07 hoặc 08 (nên thu hồi có hiệu lực ≤ 15 giây, BR-09-017, NFR-09-024); `DENY` đệm tối đa 5 giây để chống dò từng trường (BR-09-062). Nếu OPA chưa nạp bundle hoặc `validUntil` đã qua thì hợp đồng `SENSITIVE` bị `DENY` mà không gọi tiếp (NFR-09-007); hợp đồng `RESTRICTED` trở xuống đi theo `FailSafePolicy` (§8.6). Lượt khai thác được gom và gửi bất đồng bộ (`UsageReporter`, lô 500 lượt hoặc 2 giây); mất lô không ảnh hưởng quyết định nhưng tăng `privacy_client_report_dropped_total`.

### 5.2. Kế hoạch che và áp che bản tin PH-04 (FR-09-027, 028)

Luồng này là đường che dữ liệu của PH-04 ở chặng respond.


```{.mermaid caption="Kế hoạch che và áp che bản tin ở chặng respond của PH-04"}
sequenceDiagram
  autonumber
  participant R as PH-04 chặng respond
  participant L as dh-privacy-client
  participant M as PH-09 decision
  participant Y as pseudonym
  participant A as audit và PH-13
  R->>L: Bản tin, hợp đồng, dh-data-classes, dh-obligations
  L->>L: Tra PlanCache theo vai trò, mục đích, kênh, hợp đồng
  alt Chưa có kế hoạch hoặc hết hạn đệm
    L->>M: mask-plans:resolve kèm If-None-Match
    M-->>L: 200 kế hoạch hoặc 304
  end
  L->>M: classification:check
  M-->>L: Không có nhãn STATE_SECRET
  L->>L: Áp PARTIAL, REPLACE, GENERALIZE, DROP
  opt Có trường KEYED_HASH hoặc TOKENIZE
    L->>M: messages:apply cho các trường cần khóa
    M->>Y: Giả danh hóa lô
    Y-->>M: Bí danh
    M-->>L: Giá trị đã xử lý
  end
  L->>A: Ghi số lượng che theo trường
  A-->>L: Đã ghi
  L-->>R: Bản tin đã che, applied, warnings
```

Chỉ các kiểu cần khóa mới gọi sang PH-09; các kiểu còn lại áp ngay trong tiến trình PH-04 để giữ p95 ≤ 30 ms. Thứ tự là cố ý: kiểm nhãn chặn trước, che sau, ghi vết trước khi trả. Nếu `classification:check` trả `STATE_SECRET` thì cả bản tin bị chặn với ERR-09-101 mà không nêu trường (BR-09-005). Nếu không ghi được vết thì ERR-09-110 và bản tin không đi tiếp. PH-09 không khả dụng và đệm hết hạn thì chặng `respond` đóng an toàn (từ chối, ERR-04-109); điểm thực thi đọc thì chỉ trả trường `PUBLIC` kèm `X-Datahub-Masking: fallback` (BR-09-027).

### 5.3. Xem giá trị đầy đủ 60 giây (FR-09-029)

Luồng này cấp phiếu có hạn để người có quyền xem giá trị gốc.


```{.mermaid caption="Cấp phiếu và xem giá trị đầy đủ trong 60 giây"}
sequenceDiagram
  autonumber
  participant U as Người dùng PERM-09-unmask
  participant W as web RevealService
  participant A as audit và PH-13
  participant S as DU chứa dữ liệu
  U->>W: POST reveal-grants kèm lý do và trường
  W->>W: Kiểm quyền, lý do, neverReveal, hạn mức giờ
  W->>A: Ghi kiểm toán trước
  A-->>W: Đã ghi
  W->>W: Tạo phiếu hết hạn sau 60 giây, lưu token_hash
  W-->>U: 201 grantId, expiresAt, token
  U->>S: Đọc giá trị kèm token
  S->>W: reveal-grants verify
  W-->>S: Hợp lệ, còn hạn
  S-->>U: Giá trị giải mã
  U->>U: Đếm ngược 60 giây rồi tự che
```

Giá trị rõ chỉ sinh ra ở DU chứa dữ liệu và đi thẳng về giao diện; PH-09 chỉ giữ `token_hash` và thời hạn nên không thể lộ giá trị. Phiếu dùng một lần, hết hạn đúng 60 giây (sai số ±1 giây, NFR-09-015) và không dùng lại (ERR-09-112). Không ghi được kiểm toán thì ERR-09-010 và không cấp phiếu (BR-09-057). Quá 20 lần mỗi giờ thì ERR-09-043.

### 5.4. Đồng bộ bundle OPA ký (FR-09-017, 018)

Luồng này đưa thay đổi chấp thuận và chính sách tới OPA dưới dạng bundle có chữ ký.


```{.mermaid caption="Dựng, kiểm thử, ký và phát hành bundle chính sách"}
sequenceDiagram
  autonumber
  participant G as GrantService hoặc PolicyService
  participant B as BundlePublisher
  participant T as BundleTester
  participant X as OpenBao transit
  participant H as Máy chủ bundle PH-12
  participant O as OPA các điểm
  participant K as Kafka
  G->>B: requestRebuild kèm lý do
  G->>K: EVT-09-07 hoặc 08 đẩy ngay qua outbox
  B->>B: Gom thay đổi trong debounce 10 giây
  B->>B: Dựng data.json và băm nội dung
  B->>T: opa test và golden set
  T-->>B: Đạt, dung lượng dưới 5 MB
  B->>X: transit sign băm bundle
  X-->>B: Chữ ký
  B->>H: Phát hành bundle ký, validUntil
  H-->>O: OPA tải bundle và xác minh chữ ký
  O-->>B: bundle_loaded
  B->>K: EVT-09-11 bundle.published
```

Hai đường song song bảo đảm hai ngưỡng khác nhau. Đường sự kiện đẩy (EVT-09-07, 08) làm PEP xóa đệm và gỡ chấp thuận trong ≤ 15 giây. Đường bundle làm OPA chính thức nhất quán trong p99 ≤ 60 giây (NFR-09-005). `BundlePublisher` giữ một tác vụ dựng mỗi tenant tại một thời điểm (ShedLock), dựng lại nếu có thay đổi đến trong lúc đang dựng. Không ký được (OpenBao lỗi) thì ERR-09-032, bundle cũ còn hiệu lực và `privacy_bundle_age_seconds` tăng để cảnh báo trước khi chạm `validUntil`. Bộ ca chuẩn lỗi thì ERR-09-033 và không phát hành. OPA sai chữ ký thì từ chối nạp và giữ bundle cũ (THR-39).

### 5.5. Giả danh hóa HMAC và token qua OpenBao (FR-09-031, 032)

Luồng này tạo bí danh cho lô giá trị mà không lưu ánh xạ.


```{.mermaid caption="Giả danh hóa lô giá trị bằng HMAC cục bộ hoặc token transit"}
sequenceDiagram
  autonumber
  participant Q as Bên gọi privacy:pseudonymize
  participant D as decision
  participant P as Pseudonymizer
  participant C as KeyCache
  participant X as OpenBao transit
  participant A as audit
  Q->>D: pseudonyms:issue kèm miền và lô giá trị
  D->>P: Lô giá trị
  P->>P: Kiểm miền ACTIVE và kích thước lô
  alt Phương pháp HMAC_SHA256
    P->>C: Khóa làm việc của miền và phiên bản
    opt Chưa có trong đệm
      C->>X: Giải bọc khóa gốc
      X-->>C: Khóa gốc
      C->>C: HKDF dẫn xuất, giữ trong bộ nhớ
    end
    P->>P: Chuẩn hóa rồi HMAC từng giá trị
  else Phương pháp TOKEN_TRANSIT
    P->>X: transit encrypt theo lô 500 hội tụ
    X-->>P: Token
  end
  P->>A: Ghi số lượng theo miền
  A-->>P: Đã ghi
  P-->>Q: items, keyVersion
```

Giá trị rỗng giữ rỗng. OpenBao lỗi thì ERR-09-108 và không trả dữ liệu thô (không rơi về băm không khóa). Miền không `ACTIVE` thì ERR-09-109, lô quá lớn thì ERR-09-107. Khóa làm việc chỉ nằm trong bộ nhớ tối đa 5 phút (không ghi đĩa), nên bản sao nào bị thu hồi quyền ở OpenBao thì dừng sau tối đa 5 phút. Ở lần xoay khóa, bí danh mới mang `keyVersion` mới nên tập cũ và mới không nối được; điều này là chủ ý và được cảnh báo ở FR-09-034.

### 5.6. Ẩn danh hóa theo job (FR-09-036, 037)

Luồng này chạy ARX trong Job riêng và chặn phát hành khi rủi ro cao.


```{.mermaid caption="Ẩn danh hóa tập dữ liệu bằng Job Kubernetes ARX và duyệt rủi ro"}
sequenceDiagram
  autonumber
  participant U as Người dùng PERM-09-anonymize
  participant J as AnonJobService
  participant L as ArxJobLauncher
  participant K as Job privacy-arx
  participant G as Garage SSE-C
  participant R as RiskService
  participant S as SO duyệt rủi ro
  U->>J: POST anonymization-jobs
  J->>J: Kiểm cấu hình ACTIVE, nguồn đã phân loại, DIRECT đã loại
  J->>L: Tạo Job QUEUED
  L->>K: Khởi chạy Job kèm khóa tạm
  K->>G: Đọc đầu vào đã xuất
  loop Tối đa 3 vòng tổng quát hóa
    K->>K: ARX tìm phép tổng quát hóa, k thực tế
  end
  K->>K: Đánh giá rủi ro ba mô hình
  K->>G: Ghi tập kết quả
  K-->>J: kActual, số dòng, kết quả rủi ro
  J->>R: Xếp LOW, MEDIUM, HIGH
  alt LOW
    R-->>J: COMPLETED, tập READY
  else MEDIUM
    R-->>S: AWAITING_RISK_REVIEW
    S-->>J: Duyệt hoặc từ chối
  else HIGH
    R-->>J: REJECTED_RISK ERR-09-053
  end
```

Job chạy một tenant, tài khoản tạm không có quyền tới CSDL PH-09, hủy khóa tạm sau khi xong, `activeDeadlineSeconds` 7.200 giây và `backoffLimit: 0` (không tự chạy lại để tránh sinh hai tập, giả định). Tập 1 triệu bản ghi với 10 thuộc tính bán định danh ≤ 15 phút trên 8 vCPU và 32 GB (NFR-09-012, đo lại khi nghiệm thu). Còn dưới 30% bản ghi sau loại bỏ thì ERR-09-054. Phát hành tập (`DatasetService.publish`) đòi `k_actual ≥ k` cấu hình và rủi ro không `HIGH`; nếu không, ERR-09-053.

### 5.7. Tác vụ xóa hết hạn (FR-09-040…042)

Luồng này xóa hoặc giả danh hóa dữ liệu hết hạn nhưng bỏ qua dữ liệu đang giữ pháp lý.


```{.mermaid caption="Tác vụ lưu giữ xóa hoặc giả danh hóa dữ liệu hết hạn"}
sequenceDiagram
  autonumber
  participant C as Lịch 01:00 hằng ngày
  participant P as RetentionPlanner
  participant H as LegalHoldService
  participant R as RetentionTaskRunner
  participant O as Phân hệ sở hữu bảng
  participant A as audit và Kafka
  C->>P: Kích hoạt theo tenant
  P->>P: Đọc dòng lịch lưu giữ ACTIVE
  P->>H: Lấy hold_ids đang ACTIVE
  H-->>P: Danh sách giữ pháp lý
  P->>R: Tạo tác vụ QUEUED cho từng bảng
  R->>O: retention purge cutoff, action, hold-ids, lô 10.000
  O-->>R: scanned, affected, skippedByHold
  loop Đến hết lô
    R->>O: Lô tiếp theo
    O-->>R: Số lượng
  end
  alt Lô lỗi quá 3 lần
    R->>A: FAILED và cảnh báo
  else Hoàn tất
    R->>A: COMPLETED, EVT-09-19
  end
```

Quy tắc an toàn: chạy thử luôn đi trước lần chạy đầu tiên của một dòng lịch mới (người duyệt xem số lượng dự kiến); phân hệ sở hữu xác thực lại `cutoff` không nằm trong tương lai hay trong vòng 30 ngày gần nhất để tránh cấu hình sai xóa dữ liệu mới (giả định); mỗi bảng một tác vụ (ERR-09-061); dữ liệu bị giữ không bị xóa và được ghi `rows_skipped_hold`.

### 5.8. Yêu cầu chủ thể tra theo băm định danh (FR-09-045…050)

Luồng này xử lý một yêu cầu của chủ thể từ tiếp nhận đến đóng, chỉ truyền băm định danh.


```{.mermaid caption="Tiếp nhận, xác minh, tra cứu theo băm và trả lời yêu cầu của chủ thể"}
sequenceDiagram
  autonumber
  participant N as Cán bộ tiếp nhận
  participant S as SubjectRequestService
  participant H as SubjectHasher
  participant L as SubjectLookupService
  participant P6 as PH-06
  participant P19 as PH-19
  participant P13 as PH-13
  participant T as SubjectTaskService
  N->>S: POST subject-requests kèm Idempotency-Key
  S->>H: Chuẩn hóa và HMAC theo khóa tenant
  H-->>S: subjectHash
  S->>S: Mã hóa envelope định danh, trạng thái RECEIVED
  N->>S: Xác minh danh tính
  S->>S: VERIFYING rồi IN_PROGRESS, tính dueAt
  S->>L: search theo subjectHash
  par Tra song song
    L->>P6: Tra theo băm
    L->>P19: Tra theo băm
    L->>P13: Tra nhật ký theo băm
  end
  P6-->>L: Số lượng, loại, vị trí
  P19-->>L: Số lượng, loại, vị trí
  P13-->>L: Số lượng truy cập
  L-->>S: findings đã che
  S->>T: Tạo tác vụ con PH06_MASTER, PH19_PAYMENT, CONTROLLER
  T-->>S: Tác vụ hoàn tất
  S->>S: RESPONDED rồi CLOSED, lưu bằng chứng
```

Chỉ `subjectHash` rời PH-09; định danh rõ chỉ có trong `identifier_enc` (BR-09-045). Một bên không trả lời trong 5 giây thì `findings` ghi "chưa tra cứu tự động" và vẫn tiếp tục, ERR-09-066 chỉ phát sinh khi chuyển tác vụ lỗi, khi đó thử lại theo hàng chờ. Với dữ liệu đi qua, tác vụ `CONTROLLER` nêu rõ Datahub chỉ cung cấp siêu dữ liệu (BR-09-044). Trả lời `RESPONDED` đòi `DsrOutcome` và bằng chứng (ERR-09-068).

### 5.9. Vi phạm DLCN và đồng hồ 72 giờ (FR-09-058, 059)

Luồng này theo dõi hạn thông báo Cục A05 cho một vụ vi phạm.


```{.mermaid caption="Ghi nhận vi phạm, đồng hồ 72 giờ và thông báo Cục A05"}
sequenceDiagram
  autonumber
  participant I as PH-18 hoặc cán bộ
  participant B as BreachService
  participant K as BreachClock
  participant SO as SO
  participant N as NotificationService
  participant E as Kafka và PH-13
  I->>B: Ghi vụ việc kèm detectedAt
  B->>B: REPORTED, deadlineAt bằng detectedAt cộng 72 giờ
  B->>E: EVT-09-30 breach.recorded
  SO->>B: Đánh giá ASSESSING
  B->>B: NOTIFYING hoặc miễn có căn cứ
  loop Mỗi phút
    K->>K: Tính giờ còn lại
    K->>E: EVT-09-31 tại 24, 48, 60 giờ
  end
  SO->>N: Soạn thông báo mẫu A05 ở DRAFT
  SO->>N: Gửi ngoài hệ thống rồi mark-sent kèm bằng chứng
  N->>B: NOTIFIED
  B->>E: EVT-09-32 breach.notified
  SO->>B: REMEDIATING rồi CLOSED
```

Đồng hồ không tạm dừng và không đặt lại; điểm dừng duy nhất là khi thông báo Cục A05 chuyển `SENT`, lúc đó vụ việc sang `NOTIFIED` (BR-09-054). Việc không thông báo chủ thể phải có căn cứ miễn (ERR-09-077). Cảnh báo 24 giờ cũng là mốc bên xử lý phải báo vụ việc cho tỉnh (Q09-13). Một vụ việc sang `NOT_A_BREACH` chỉ khi SO duyệt kèm lý do; vụ việc ấy không còn nghĩa vụ thông báo nên không bị tính quá hạn.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph09_privacy` có `tenant_id` và RLS theo `app.tenant_id` (ADR-003, D03-10, BR-09-060). Bộ lọc Spring Security đọc tenant từ token, đặt `TenantContext`, và `TenantSession` chạy `SET LOCAL app.tenant_id` đầu mỗi giao dịch; mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Bốn điểm riêng của PH-09:

1. **Data plane.** `PolicySnapshot` là cấu trúc theo tenant, nạp bằng giao dịch đặt `app.tenant_id` tường minh; khóa trong bản đồ bản chụp là `tenantId`. Lời gọi `/privacy/v1` mang tenant từ danh tính SPIFFE và đối chiếu với tenant trong tải; lệch thì ERR-09-111. Điểm thực thi chỉ nhận dữ liệu của tenant mình.
2. **Tác vụ nền** (`GrantScheduler`, `AnomalyDetector`, `DsrClock`, `BreachClock`, `RetentionPlanner`, `BundlePublisher`, `LeakScanner`) lặp qua từng tenant `ACTIVE`, đặt `TenantContext` tường minh và dùng khóa ShedLock có tên kèm tenant; không có tác vụ "không tenant".
3. **Khóa mật mã.** KEK `dh-{tenant}-pii`, khóa giả danh hóa theo (tenant, miền), khóa HMAC chủ thể theo tenant và khóa ký bundle đều riêng tenant; AAD của bản mã gồm `tenant_id` nên bản mã chép sang tenant khác không giải được. Khóa Valkey, tên Job K8s, tên đối tượng Garage đều mang tenant.
4. **Kafka.** Topic có tiền tố tenant thường (`t68.privacy.purpose-grant.revoked.v1`), ràng buộc CSDL `ck_outbox_event_prefix` bảo đảm tiền tố khớp `tenant_id`; bộ nghe lấy tenant từ tiền tố topic và đối chiếu `inbox_event.tenant_id`, lệch thì bỏ và cảnh báo. Danh mục `COMMON` (mức phân loại, loại DLCN nạp sẵn) đọc ở chế độ chỉ đọc.

## 7. Bảo mật

Kiểm tra quyền ở máy chủ, độc lập với giao diện: APISIX xác minh token và gọi OPA (SEC-26), `dh-data` kiểm lại `PERM-09-*` và phạm vi tổ chức ở từng `Controller` (ERR-09-008), rồi dịch vụ kiểm tách nhiệm vụ. Bảng dưới liệt kê các kiểm soát và ràng buộc `SEC-*` đã có (không tạo mới).

| Kiểm soát | Hiện thực | SEC |
|---|---|---|
| Ủy quyền tập trung, bundle ký | PH-09 cấp dữ liệu, OPA quyết định; bundle ký bằng khóa transit không xuất được, OPA xác minh chữ ký, `validUntil` 60 phút; sửa bundle trái phép bị từ chối (THR-39) | SEC-26, 36 |
| Mã hóa trường, băm chủ thể | Định danh chủ thể và nội dung yêu cầu ở dạng `*_enc` (envelope, ADR-032), tra cứu bằng `*_hash` HMAC-SHA256 theo tenant; giải mã chỉ trong bộ nhớ | SEC-31 |
| Che trong log, trace, giao diện | `LogMasker` của `dh-privacy-client`, cấu hình `log_mask_config`, `LeakScanner` hằng ngày; không đưa giá trị, băm chủ thể, định danh vào nhãn chỉ số hay thuộc tính span | SEC-32 |
| Quản lý xử lý DLCN | `ContractActivationGuard` chặn hợp đồng `SENSITIVE` thiếu mục đích và chấp thuận; trường DLCN phải thuộc hoạt động `ACTIVE`; `AnomalyDetector` phát hiện khai thác vượt mục đích (THR-51) | SEC-37 |
| Giả danh hóa và dữ liệu thử | Không bảng ánh xạ; k ≥ 10 sàn; ngoài PROD chỉ dữ liệu sinh hoặc giả danh hóa không đảo ngược; dữ liệu cho AI theo SEC-49 | SEC-38 |
| Thời hạn lưu, xóa an toàn | Lịch lưu giữ theo bảng, giữ pháp lý, xóa mật mã tenant hai người, tombstone khi khôi phục sao lưu | SEC-39 |
| Báo cáo vi phạm | Đồng hồ 72 giờ, mẫu A05, nhắc ở 24, 48, 60 giờ | SEC-74 |
| Tách nhiệm vụ | Người đề nghị không duyệt (ERR-09-005), ba người khác nhau ở khôi phục, bốn mắt chính sách che (ADR-046), cặp loại trừ SO với `PERM-09-purpose-approve` | SEC-28 |
| Thao tác đặc quyền | Xem đầy đủ, khôi phục, hủy khóa, xóa mật mã, gỡ nhãn: ghi kiểm toán trước, không ghi được thì từ chối; MFA cho khôi phục | SEC-33 |
| Data plane nội bộ | mTLS, danh tính SPIFFE, scope `privacy:decide`, `privacy:apply`, `privacy:pseudonymize`, `privacy:consent`; hạn mức gọi (ERR-09-113) | SEC-24, 26 |
| Cách ly Job ẩn danh hóa | `ServiceAccount` riêng, `NetworkPolicy` chỉ tới Garage, không root, hệ tệp gốc chỉ đọc, ảnh ký cosign | SEC-14, 52, 53 |
| Kiểm tra đầu vào | JSON Schema, giới hạn bản tin 1 MiB và lô, `SafeRegex` cho mẫu phát hiện do người dùng thêm | SEC-43 |

: Kiểm soát bảo mật của PH-09

Hai rủi ro riêng: bản chụp chính sách bị đầu độc ảnh hưởng mọi PEP (phòng bằng bốn mắt, ca tương đương Rego, bundle ký); và `subjectHash` cho phép tương quan giữa các hệ cùng khóa tenant nên không bao giờ xuất hiện ở log, sự kiện, thuộc tính span.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Các enum và giá trị lấy từ FRS Phụ lục A; sơ đồ của yêu cầu khai thác, chấp thuận, chính sách che, yêu cầu chủ thể và vi phạm nằm ở FRS §4.3 đến §4.6, bảng này bổ sung phần hiện thực: bước chuyển hợp lệ và nơi kiểm ở máy chủ. Mọi bước chuyển nằm trong một giao dịch với ghi outbox, kiểm bằng khóa lạc quan `version` (ERR-09-004) và bước không có trong bảng thì ERR-09-006.

| Đối tượng (enum) | Chuyển hợp lệ | Nơi kiểm |
|---|---|---|
| Phân loại (`ClassificationStatus`) | `PROPOSED` sang `CONFIRMED` hoặc `REJECTED`; `CONFIRMED` sang `SUPERSEDED` | `ClassificationService.confirm`, `reject` |
| Quét (`ScanStatus`) | `QUEUED` sang `RUNNING` sang `COMPLETED` hoặc `FAILED`; `QUEUED`, `RUNNING` sang `CANCELLED` | `ScanJobRunner` |
| Kết quả quét (`FindingStatus`) | `OPEN` sang `CONFIRMED_PII` hoặc `EXCLUDED`; `CONFIRMED_PII` sang `CLASSIFIED` | `FindingService` |
| Phiên bản (`VersionStatus`): chính sách che, lịch lưu giữ, cấu hình ẩn danh, mẫu đồng ý, hoạt động, DPIA | `DRAFT` sang `PENDING_APPROVAL` sang `ACTIVE` hoặc `REJECTED`; `PENDING_APPROVAL` về `DRAFT`; `ACTIVE` sang `SUPERSEDED` hoặc `RETIRED` | `*Approval.approve` (khác người soạn), `ActivityVersioning` |
| DPIA (`DpiaStatus`) | như trên, thêm `ACTIVE` sang `SUBMITTED_A05` | `DpiaService.markSubmitted` |
| Yêu cầu khai thác (`AccessRequestStatus`) | `DRAFT` sang `SUBMITTED` hoặc `WITHDRAWN`; `SUBMITTED` sang `UNDER_REVIEW` hoặc `WITHDRAWN`; `UNDER_REVIEW` sang `NEEDS_INFO`, `APPROVED`, `REJECTED`; `NEEDS_INFO` sang `SUBMITTED` | `AccessRequestService`, `ReviewService` |
| Chấp thuận (`GrantStatus`) | `SCHEDULED` sang `ACTIVE`; `ACTIVE` sang `SUSPENDED`, `REVOKED`, `EXPIRED`; `SUSPENDED` sang `ACTIVE`, `REVOKED`, `EXPIRED` | `GrantService`, `GrantScheduler` |
| Phiếu xem (`RevealStatus`) | `ISSUED` sang `VERIFIED` hoặc `EXPIRED` | `RevealService.verify`, hết hạn theo đồng hồ |
| Khóa (`KeyVersionStatus`) | `ACTIVE` sang `DECRYPT_ONLY` sang `DISABLED` sang `DESTROYED` | `KeyLifecycleService` |
| Khôi phục (`ReidStatus`) | `PENDING_L1` sang `PENDING_L2` sang `APPROVED` sang `EXECUTED`; từ `PENDING_*` sang `REJECTED`; `PENDING_*`, `APPROVED` sang `EXPIRED` | `ReidentificationService` |
| Job ẩn danh (`AnonJobStatus`) | `QUEUED` sang `RUNNING` sang `COMPLETED`, `AWAITING_RISK_REVIEW`, `REJECTED_RISK`, `FAILED`; `AWAITING_RISK_REVIEW` sang `COMPLETED` hoặc `REJECTED_RISK`; chưa kết thúc sang `CANCELLED` | `AnonJobService`, `RiskService` |
| Tập ẩn danh (`DatasetStatus`) | `READY` sang `PUBLISHED`; `PUBLISHED` sang `WITHDRAWN` hoặc `EXPIRED` | `DatasetService` |
| Tác vụ lưu giữ (`RetentionTaskStatus`) | `QUEUED` sang `RUNNING` sang `COMPLETED` hoặc `FAILED`; `QUEUED` sang `CANCELLED` | `RetentionTaskRunner` |
| Giữ pháp lý (`LegalHoldStatus`) | `ACTIVE` sang `RELEASED` | `LegalHoldService` |
| Xóa mật mã (`CryptoShredStatus`) | `REQUESTED` sang `APPROVED` sang `WAITING` sang `EXECUTED`; ba trạng thái đầu sang `CANCELLED` | `TenantShredService` |
| Yêu cầu chủ thể (`DsrStatus`) | `RECEIVED` sang `VERIFYING` sang `IN_PROGRESS` sang `RESPONDED` sang `CLOSED`; sang `REJECTED` từ `VERIFYING`; sang `WITHDRAWN` từ ba trạng thái đầu; cờ `overdue` tách riêng | `SubjectRequestService`, `DsrClock` |
| Tác vụ chủ thể (`DsrTaskStatus`) | `OPEN` sang `DONE`, `REFUSED`, `CANCELLED` | `SubjectTaskService` |
| Đồng ý (`ConsentStatus`) | `GIVEN` sang `WITHDRAWN` hoặc `EXPIRED` | `ConsentService` |
| Vi phạm (`BreachStatus`) | `REPORTED` sang `ASSESSING` sang `NOT_A_BREACH`, `NOTIFYING` hoặc `REMEDIATING`; `NOTIFYING` sang `NOTIFIED` sang `REMEDIATING` sang `CLOSED` | `BreachService` |
| Thông báo (`NotificationStatus`) | `DRAFT` sang `SENT` | `NotificationService.markSent` |

: Chuyển trạng thái và nơi kiểm ở máy chủ

```{.mermaid caption="Máy trạng thái khôi phục giá trị gốc và job ẩn danh hóa"}
stateDiagram-v2
  state "Khôi phục (ReidStatus)" as R {
    [*] --> PENDING_L1
    PENDING_L1 --> PENDING_L2 : DO duyệt
    PENDING_L2 --> APPROVED : TA hoặc DA duyệt
    APPROVED --> EXECUTED : SO thực hiện trong cửa sổ
    PENDING_L1 --> REJECTED
    PENDING_L2 --> REJECTED
    PENDING_L1 --> EXPIRED
    PENDING_L2 --> EXPIRED
    APPROVED --> EXPIRED
  }
  state "Job ẩn danh (AnonJobStatus)" as A {
    [*] --> QUEUED
    QUEUED --> RUNNING
    RUNNING --> COMPLETED : rủi ro LOW
    RUNNING --> AWAITING_RISK_REVIEW : rủi ro MEDIUM
    RUNNING --> REJECTED_RISK : rủi ro HIGH
    RUNNING --> FAILED
    AWAITING_RISK_REVIEW --> COMPLETED : SO duyệt
    AWAITING_RISK_REVIEW --> REJECTED_RISK
  }
```

Hình mô tả hai vòng đời không có sơ đồ ở FRS: khôi phục có hai lớp hạn (duyệt và thực hiện), job ẩn danh chỉ sang `COMPLETED` khi rủi ro chấp nhận được.

### 8.2. Outbox

Mọi thay đổi trạng thái ghi `outbox_event` trong cùng giao dịch (ADR-042, `event_id`, `topic`, `partition_key = tenantId`, `trace_id`); `OutboxRelay` đọc theo lô và phát Kafka với phong bì CloudEvents. Ràng buộc `ck_outbox_event_no_value` ở CSDL chặn khóa mang giá trị (`value`, `identifier`...), cùng với kiểm tra ArchUnit bảo đảm sự kiện chỉ mang mã, trạng thái và thời điểm (BR-09-025). Sự kiện thu hồi (EVT-09-07, 08, 12) đi hàng đợi ưu tiên, thăm dò 200 ms, để đạt mốc 15 giây.

### 8.3. Inbox và idempotency

Sự kiện tiêu thụ (đăng ký phân loại của PH-06, sự cố của PH-18, hoàn tất tác vụ của phân hệ sở hữu) ghi `inbox_event` theo (tenant, consumer, event_id) trước khi xử lý, bản trùng thì bỏ. Mọi POST tạo hoặc chuyển trạng thái nhận `Idempotency-Key` (BR-09-061, ADR-041): `IdempotencyFilter` lưu băm yêu cầu và kết quả 24 giờ, gọi lặp cùng khóa trả cùng kết quả, cùng khóa khác nội dung thì `422`. Cấp chấp thuận, tiếp nhận yêu cầu chủ thể, tạo job và cấp phiếu đều qua cơ chế này. Các lệnh gọi hạ nguồn có tác dụng phụ (`retention:purge`, tạo tác vụ con) mang khóa idempotency riêng theo (tenant, tác vụ, lô) để thử lại an toàn.

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng dưới ghi thời gian chờ, số lần thử lại, ngắt mạch và cách xử lý khi hết lượt cho từng phụ thuộc, để biết PH-09 và PEP suy giảm thế nào khi một phụ thuộc lỗi.

| Phụ thuộc | Thời gian chờ | Thử lại | Ngắt mạch | Khi hết lượt |
|---|---|---|---|---|
| `pg-core` giao dịch ghi | 5 giây | Xung đột `version`: 5 lần, 20 đến 100 ms ngẫu nhiên | Không | ERR-09-004 hoặc 409 |
| OpenBao transit (ký, HMAC, mã hóa) | 1 giây | 2 lần, 200 ms | Resilience4j: mở khi lỗi ≥ 50% trong 20 lượt, nửa mở sau 30 giây | Bundle: ERR-09-032 giữ bản cũ. Giả danh hóa: ERR-09-108 không trả dữ liệu thô |
| PH-13 (ghi kiểm toán) | 100 ms | 1 lần | Như trên | Thao tác đặc quyền và che bị từ chối (ERR-09-010, 110) |
| Phân hệ sở hữu (tra, xóa, tác vụ) | 5 giây, lô 30 giây | 3 lần giãn dần | Mở khi lỗi liên tục 10 phút | Hàng chờ, ERR-09-066 hoặc 009, cảnh báo sau 24 giờ |
| Kafka (bộ nghe) | `max.poll.interval.ms` 5 phút | 5 lần, 1 giây nhân đôi | Không | Chuyển `.dlq`, cảnh báo |
| Valkey (bộ đếm, hạn mức) | 100 ms | Không | Lui về CSDL | Hạn mức mềm, không lỗi |
| Garage | 10 giây | 3 lần giãn dần | Không | Tác vụ xuất `FAILED` |
| Job K8s ARX | `activeDeadlineSeconds` 7.200 | `backoffLimit: 0` | Không | `FAILED` (ERR-09-054 hoặc 009) |
| Máy chủ bundle PH-12 | 5 giây | 3 lần | Không | Bundle cũ còn hiệu lực, cảnh báo tuổi bundle |

: Thời gian chờ, thử lại và ngắt mạch theo phụ thuộc

### 8.5. Ánh xạ lỗi

`PrivacyExceptionHandler` biến `PrivacyException(code, args)` thành phản hồi theo khung D03-04 §6 gồm `code`, `message`, `details`, `traceId`. ERR-09-001…082 trả người dùng control plane, ERR-09-101…113 trả bên gọi data plane và chỉ hiển thị cho người vận hành điểm thực thi. `401`, `403` do thiếu quyền chức năng và `428` do thiếu `If-Match` dùng ERR-00-401, ERR-00-403, ERR-00-428; vi phạm phạm vi tổ chức dùng ERR-09-008. Nhóm lỗi theo nguồn: kiểm tra dữ liệu `422` (ERR-09-007, 012, 013, 016, 020, 028, 037…040, 051…055, 057, 059, 062, 068…071, 073, 075, 077, 078); xung đột trạng thái `409` (ERR-09-002, 004, 006, 011, 014, 017, 022, 029, 045…047, 050, 056, 058, 061, 064, 067, 070, 072, 074, 076); lỗi phụ thuộc `503` hoặc `502` (ERR-09-009, 010, 032, 066, 105, 108, 110); quá hạn mức `429` (ERR-09-043, 113). `DENY` của quyết định mục đích là kết quả `200` hợp lệ, không phải lỗi HTTP (FR-09-019); điểm thực thi mới trả `403` ERR-09-102 cho bên khai thác. Thân lỗi không chứa giá trị DLCN, không nêu trường mang nhãn chặn (BR-09-005).

### 8.6. Thiết kế đệm và đóng an toàn ở PEP

Đây là thiết kế của `dh-privacy-client`, dùng chung để mọi PEP hành xử giống nhau khi PH-09 chậm hoặc ngừng. Có bốn đệm độc lập, mỗi đệm có hạn riêng và có đường xóa bằng sự kiện.

| Đệm | Khóa | Hạn | Xóa khi | Hết hạn mà không làm mới được |
|---|---|---|---|---|
| Kế hoạch che (`PlanCache`) | (vai trò, mục đích, kênh, hợp đồng) | `09.plan.cache-seconds` (300, trần 300) | EVT-09-12, EVT-09-01 | PEP đọc: chỉ trường `PUBLIC` kèm `X-Datahub-Masking: fallback`. PEP luồng: từ chối (đóng an toàn) |
| Quyết định (`DecisionCache`) | (mục đích, HTTT, hợp đồng, băm trường, cờ hạn chế) | `09.decision.cache-seconds` (15, trần 15) cho `ALLOW`, `DENY` tối đa 5 giây (BR-09-062) | EVT-09-07, 08, 09, 06 | Gọi OPA cục bộ, rồi `decide` |
| Bundle (OPA) | `bundleId` | `validUntil` (60 phút) | Bundle mới nạp | Hợp đồng `SENSITIVE`: `DENY`. `RESTRICTED` trở xuống theo `FailSafePolicy` |
| Đồng ý (`ConsentCache`) | (`subjectHash`, mẫu) | `09.consent.cache-seconds` (60, trần 60) | EVT-09-28 | Coi như chưa đồng ý cho tiện ích không bắt buộc |

: Đệm và hành vi khi hết hạn ở điểm thực thi

`FailSafePolicy` có đúng hai chế độ ở `FailMode`: `PUBLIC_ONLY` cho điểm thực thi đọc và `CLOSED` cho điểm thực thi luồng (BR-09-027). Chế độ do bên gọi khai khi khởi tạo (PH-03, 06, 14 dùng `PUBLIC_ONLY`, PH-04 chặng `respond` và PH-19 dùng `CLOSED`) và kiểm bằng ArchUnit ở từng DU. Quy tắc chung: không bao giờ phục vụ kế hoạch quá hạn đệm tối đa, không bao giờ suy luận kế hoạch từ quyết định cũ, và không bao giờ trả trường chưa phân loại. Trạng thái suy giảm được đếm ở `privacy_client_fallback_total{mode}` và đưa lên UI-09-01. Ngắt mạch phía client mở khi lỗi ≥ 50% trong 20 lượt gọi `/privacy/v1` và nửa mở sau 30 giây; khi mở, client lập tức dùng đệm mà không chờ thời hạn, để PH-09 hồi phục không bị dồn tải. Thời gian chờ mỗi lần gọi là 500 ms, thử lại 1 lần với `decide`, `mask-plans:resolve` (thử lại có `If-None-Match` nên rẻ). `PlanCache` làm mới nền khi còn 20% hạn, có jitter 10%.

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số theo tenant

Tham số `09.*` (FRS §8.2) do từng tỉnh chỉnh qua `TenantSettingService`, không vượt trần hoặc sàn do PA đặt (BR-09-059) và áp dụng không cần khởi động lại. Bảng dưới nêu cách hiện thực các tham số có ảnh hưởng thiết kế; miền và mặc định đầy đủ ở FRS.

| Nhóm | Khóa chính | Nơi tiêu thụ |
|---|---|---|
| Quét | `09.scan.sample-rows`, `09.scan.schedule-cron`, `09.scan.confidence` | `ScanJobRunner` |
| Chấp thuận | `09.request.sla-days`, `09.grant.max-days` (trần 730), `09.grant.renew-max`, `09.grant.expiring-notice-days`, `09.grant.require-restricted` | `GrantService`, `ContractActivationGuard` |
| Bundle, đệm | `09.bundle.debounce-seconds`, `09.bundle.valid-minutes`, `09.plan.cache-seconds` (trần 300), `09.consent.cache-seconds` (trần 60), `09.decision.cache-seconds` (mặc định và trần 15) | `BundlePublisher`, `dh-privacy-client` |
| Bất thường | `09.anomaly.quota-warn-percent`, `09.anomaly.bulk-threshold`, `09.anomaly.auto-suspend` | `AnomalyDetector` |
| Che, xem đầy đủ | `09.mask.reveal-seconds` (trần 60), `09.mask.reveal-max-per-hour`, `09.mask.reveal-alert-per-hour` (mặc định 10), `09.log.scan-cron` | `RevealService`, `LeakScanner` |
| Giả danh hóa | `09.pseudo.key-rotate-days`, `09.pseudo.min-rotate-days`, `09.pseudo.destroy-delay-days`, `09.reid.approval-ttl-hours`, `09.reid.exec-window-minutes` | `KeyLifecycleService`, `ReidentificationService` |
| Ẩn danh hóa | `09.anon.k-min` (sàn 10), `09.anon.risk-medium-above`, `09.anon.risk-high-above`, `09.ai.allow-restricted` | `AnonConfigService`, `RiskService` |
| Lưu giữ | `09.retention.run-cron`, `09.retention.overdue-days`, `09.shred.delay-days` | `RetentionPlanner`, `TenantShredService` |
| Chủ thể, vi phạm, DPIA | `09.dsr.sla-days`, `09.dsr.remind-days`, `09.breach.alert-hours`, `09.dpia.review-months` | `DsrClock`, `BreachClock`, `DpiaReviewScheduler` |
| Báo cáo, nhật ký | `09.audit.query-max-days`, `09.report.schedule-cron` | `AuditQueryService`, `ComplianceReportService` |
| Hạn mức gọi API | `09.api.rate-user-per-min` (300, trần 1.200), `09.api.rate-du-per-sec` (2.000, trần 5.000) | Bộ giới hạn ở APISIX (control plane), `DataPlaneController` (data plane); vượt hạn mức trả ERR-09-113 |

: Tham số 09.* và nơi tiêu thụ

### 9.2. Cờ tính năng

Cờ tính năng là tham số tenant dạng `09.feature.*` đọc cùng cơ chế ở trên (FRS §8.2): `09.feature.dsr-ph11` (dùng PH-11 cho hạn DSR, mặc định tắt), `09.feature.l-diversity` (bắt buộc `L_DIVERSITY` cho thuộc tính nhạy cảm), `09.feature.auto-confirm-mvp` (xác nhận hàng loạt khai báo MVP sau khi duyệt mẫu). Cờ không đổi được các bất biến an toàn (k tối thiểu, hai người duyệt khôi phục, 72 giờ).

### 9.3. Cấu hình triển khai

Thuộc tính `datahub.privacy.*` trong `application.yaml`, ghi đè bằng biến môi trường ở Helm: `dataplane.snapshot-poll-ms` (5.000), `dataplane.max-message-bytes` (1.048.576), `outbox.priority-poll-ms` (200), `arx.job-image`, `arx.max-memory`, `client.call-timeout-ms` (500), `client.breaker-failure-rate` (50). Bí mật lấy từ OpenBao và cert-manager, không nằm trong cấu hình. Data plane đặt `PodDisruptionBudget` `minAvailable: 2` và `topologySpreadConstraints` trên 3 nút.

## 10. Quan sát

Chỉ số phát qua Micrometer, tiền tố `privacy_` (khớp NFR-09-022), nhãn có bậc số lượng nhỏ (`tenant`, `result`, `type`, `status`); tuyệt đối không dùng `subjectHash`, định danh, tên người, mã trường làm nhãn (SEC-32).

| Nhóm | Chỉ số | Nhãn |
|---|---|---|
| Quyết định | `privacy_decide_total`, `privacy_decide_seconds`, `privacy_blocked_total`, `privacy_snapshot_age_seconds` | `result`, `reason` |
| Che | `privacy_mask_total`, `privacy_unclassified_fields`, `privacy_reveal_total` | `type`, `result` |
| Bundle | `privacy_bundle_age_seconds`, `privacy_bundle_build_seconds`, `privacy_bundle_loaded_total`, `privacy_bundle_publish_total` | `result`, `opa` |
| Chấp thuận | `privacy_grant_total`, `privacy_request_age_days`, `privacy_usage_total`, `privacy_anomaly_total` | `status`, `type` |
| Giả danh, ẩn danh | `privacy_pseudonym_total`, `privacy_key_cache_hit_ratio`, `privacy_anon_job_total`, `privacy_anon_k_actual`, `privacy_anon_risk_total` | `method`, `status`, `level` |
| Lưu giữ | `privacy_retention_rows_total`, `privacy_retention_overdue_tables`, `privacy_legal_hold_active` | `action` |
| Chủ thể, vi phạm | `privacy_dsr_total`, `privacy_dsr_overdue`, `privacy_breach_clock_seconds`, `privacy_breach_open` | `type`, `status` |
| Điểm thực thi | `privacy_client_cache_hit_ratio`, `privacy_client_fallback_total`, `privacy_client_stale_serve_total` | `mode` |
| Hệ thống | `privacy_audit_write_failure_total`, `privacy_outbox_pending`, `privacy_event_lag_seconds`, `privacy_leak_findings_total` | `source` |

: Chỉ số quan sát của PH-09

**Log**: JSON có `traceId`, `tenant`, `module = privacy`, `operationId`; qua `LogMasker`, không bao giờ có giá trị trường, băm chủ thể hay nội dung yêu cầu. **Trace**: span `privacy.decide`, `privacy.mask-plan`, `privacy.apply`, `privacy.pseudonymize`, `privacy.bundle.build`, `privacy.anon.job`, `privacy.retention.run`, `privacy.dsr.lookup`; thuộc tính span chỉ có mã (hợp đồng, mục đích, `grantId`, số lượng), không có DLCN, và `traceparent` được ghi vào cột `trace_id` của outbox. **Cảnh báo** (UI-09-01 và Alertmanager): tuổi bundle trên 45 phút, `privacy_dsr_overdue > 0`, đồng hồ vi phạm dưới mốc, `privacy_audit_write_failure_total` tăng, tỉ lệ `fallback` của PEP trên 1%, `privacy_unclassified_fields` tăng so với tuần trước, `privacy_leak_findings_total > 0`.

## 11. Hiệu năng và vận hành

**Ngân sách độ trễ quyết định (p95 ≤ 50 ms gọi trực tiếp, NFR-09-001; giả định phân bổ, đo khi nghiệm thu):** xác thực mTLS và quét scope 2 ms, tra chỉ mục bản chụp trong bộ nhớ 1 ms, đánh giá điều kiện và dựng phản hồi 2 ms, ghi hàng đợi kiểm toán 1 ms, còn lại là mạng và hàng đợi; đường chính không có truy vấn CSDL nên chi phí ổn định. Có đệm ở PEP thì p95 ≤ 20 ms, trúng đệm ≤ 2 ms. **Kế hoạch che** (≤ 50 ms): tra bảng đã giải sẵn theo (vai trò, mục đích, kênh), xây trước khi kích hoạt chính sách; một kế hoạch 200 trường dưới 20 KB. **Áp che bản tin** (≤ 30 ms cho 10 KB): duyệt JSON một lần theo đường dẫn trường, `MaskEngine` không cấp phát chuỗi trung gian cho kiểu `DROP`, `REPLACE`.

**Thông lượng (NFR-09-004, 5.000 yêu cầu mỗi giây toàn cụm):** mỗi bản sao 4 vCPU xử lý khoảng 2.000 yêu cầu mỗi giây vì chỉ đọc bộ nhớ (giả định, kiểm bằng k6); mất một nút giảm tối đa 33%. Kiểm toán gom lô 5 giây giữ ghi PH-13 dưới 100 yêu cầu mỗi giây cho quyết định không `SENSITIVE`. **Bundle (≤ 5 MB, OPA nạp ≤ 2 giây):** 3.000 chấp thuận khoảng 1,2 MB dạng nén (giả định 400 byte mỗi chấp thuận), chỉ mục phân loại 50.000 phần tử khoảng 2 MB, dưới trần; dựng cộng ký ≤ 10 giây nên p99 ≤ 60 giây gồm debounce 10 giây, kiểm thử, phát hành và nạp.

**Dung lượng.** 2 triệu bản ghi kiểm toán mỗi tháng (NFR-09-020) vào `privacy_audit_event` phân vùng theo tháng (D03-03), 12 tháng trực tuyến; `PolicySnapshot` toàn tenant dưới 20 MB bộ nhớ (giả định).

**Vận hành thường nhật.** 01:00 tác vụ lưu giữ, 02:00 Chủ nhật quét phát hiện, 03:00 quét rò rỉ log, mỗi giờ `DsrClock`, mỗi phút `GrantScheduler` và `BreachClock`, 06:00 ngày 1 hằng tháng báo cáo tuân thủ. Sổ tay vận hành ghi sáu tình huống: bundle quá tuổi, OpenBao không khả dụng, PEP rơi về `fallback` hàng loạt, tác vụ lưu giữ `FAILED`, DSR quá hạn, nhật ký kiểm toán không ghi được. **Triển khai:** hai Deployment cùng ảnh `dh-data` (profile `dataplane` 3 bản sao, profile `control` 2 bản sao), Job `privacy-arx` do `dh-data` tạo ở namespace job riêng (Q09-24), cấp phát tài nguyên theo D03-09. Phát hành theo `canary` 10% cho data plane, ca chuẩn tương đương Rego chạy trước khi tăng lưu lượng.

## 12. Kiểm thử

Bảng ghi nội dung và ví dụ ca theo từng lớp kiểm thử.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | Hàm thuần: `PolicyResolver`, `MaskEngine`, bộ dò (`Luhn`, `NationalId12`), `SubjectHasher`, `HmacPseudonymizer`, `DsrClock`, `BreachClock`, `ContractLevelCalculator` | Quy tắc trùng ưu tiên chọn kiểu che chặt hơn. Luhn đúng và sai. Ngày làm việc qua kỳ nghỉ lễ. Đồng hồ 72 giờ qua nửa đêm |
| Tương đương Rego | Golden set ≥ 300 ca chạy bằng OPA và `mask-plans:resolve` | 100% trùng quyết định và kế hoạch (NFR-09-008), chạy trong CI mỗi lần đổi chính sách |
| Tích hợp (Testcontainers) | PostgreSQL có RLS, Kafka, OpenBao dev, Valkey | Tenant A không đọc dòng tenant B ở mọi API đọc (NFR-09-019). Thu hồi chấp thuận ra EVT-09-08 qua outbox. Không giá trị rõ trong bảng, sự kiện |
| Hợp đồng | Lược đồ sự kiện Apicurio, OpenAPI | Sự kiện không có khóa `value`, `identifier`; tương thích `BACKWARD` |
| Điểm thực thi | `dh-privacy-client` với PH-09 ngắt, chậm, trả `304` | Hết đệm 300 giây: PEP đọc trả `PUBLIC` kèm `X-Datahub-Masking: fallback`, PH-04 từ chối. Bundle quá `validUntil`: `SENSITIVE` bị `DENY` |
| Đồng hồ | Đồng hồ giả (Clock injection) | Phiếu xem hết hạn đúng 60 giây. Cảnh báo 24, 48, 60 giờ. DSR nhắc trước 3 ngày làm việc |
| Job ẩn danh | Kind với tập sinh 100.000 bản ghi | `k_actual ≥ k`; còn trường `DIRECT` thì ERR-09-052; rủi ro `HIGH` không phát hành; Job không có quyền tới CSDL |
| Phi chức năng | k6, chaos, đo dung lượng | NFR-09-001…006, 011, 012; tắt OpenBao, Kafka, PH-13 thì đúng cách lui (§8.4) |
| Bảo mật | ArchUnit, quét CSDL và log, ZAP | Không đường nào giải mã ngoài `crypto`; 0 mẫu số định danh rõ trong `ph09_privacy`, log, trace (NFR-09-014); khôi phục cần ba người khác nhau |

: Chiến lược kiểm thử của PH-09

Dữ liệu kiểm thử là dữ liệu sinh (SEC-38) ở tenant T90 đến T99, có nhiễu (số định danh sai kiểm tổng, đầu số điện thoại lạ, thư điện tử thiếu miền).

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Thứ tự theo phụ thuộc và mốc W4 của đợt 2; tiêu chí xong đo được.

| Mốc | Nội dung | Tiêu chí xong |
|---|---|---|
| M1 | `classification`, `scanner`, `crypto`, `audit`, `persistence`, ArchUnit | Nhập khai báo MVP vào `PROPOSED`; quét 500 cột ≤ 10 phút |
| M2 | `purpose`, `bundle`, `decision` (quyết định), `dh-privacy-client` bản đầu | NFR-09-001, 005 đạt; thu hồi ≤ 15 giây (NFR-09-024); hết hạn ≤ 60 giây và cảnh báo bất thường ≤ 5 phút (NFR-09-025, 026); PH-04, PH-06 chuyển sang thư viện |
| M3 | `policy` che, kế hoạch, áp che, xem đầy đủ, `pseudonym` | NFR-09-002, 003, 011, 015 đạt; ca tương đương Rego 100% |
| M4 | `ropa`, `dpia`, `consent`, `retention` | Mọi trường DLCN thuộc hoạt động `ACTIVE`; tác vụ xóa chạy thử đúng |
| M5 | `dsr`, `breach`, `reporting`, `anonymize` ARX | NFR-09-012, 016, 017 đạt |
| M6 | Chuyển PH-14, PH-19, cắt bỏ che tối thiểu cũ, DR | RTO 30 phút, RPO 5 phút; nghiệm thu |

: Lộ trình hiện thực PH-09

### 13.2. Truy vết hệ cũ

LGC-TOOL-012 (nhóm bảo mật) tương ứng PH-04 và PH-09 ở bước che dữ liệu nhạy cảm: PH-09 giữ phần che theo chính sách (§4.6, §4.12). LGC-NGSP-003 (BHXH tra cứu hộ gia đình) tương ứng PH-14 và PH-09: kiểm soát mục đích khai thác ở §4.5 và §5.1 theo THR-51. Bốn chế độ `none`, `mask`, `pseudonymize`, `anonymize` của SRS cũ được thay bằng `MaskType` và các thành phần riêng (bảng ánh xạ ở FRS).

### 13.3. Rủi ro

Năm rủi ro chính và cách giảm thiểu.


| Rủi ro | Tác động | Giảm thiểu |
|---|---|---|
| Bản chụp chính sách sai hoặc bị đầu độc | Mọi PEP che sai hoặc cho qua nhầm | Bốn mắt, ca tương đương Rego, bundle ký, `bundle rollback` |
| PH-09 ngừng lâu hơn đệm | Luồng PH-04 từ chối, đọc chỉ `PUBLIC` | 3 bản sao 3 nút, đệm 5 phút, cảnh báo sớm, diễn tập DR |
| Cấu hình lưu giữ sai xóa nhầm dữ liệu | Mất dữ liệu | Chạy thử bắt buộc, xác thực `cutoff`, giữ pháp lý, bản sao lưu 35 ngày |
| Bộ dò bỏ sót trường DLCN | Trường lọt phân loại | Trường chưa phân loại tính `SENSITIVE` (BR-09-001), quét định kỳ, bộ mẫu chuẩn |
| Xoay khóa phá nhất quán bí danh | Hai tập cũ mới không nối | Cảnh báo, xác nhận, phiên bản khóa nằm trong bí danh |

: Rủi ro của PH-09

### 13.4. Quyết định kiến trúc đề xuất

Chưa tạo tệp ADR (theo quy ước dải). Bốn ADR đề xuất: **ADR 090** điểm quyết định mục đích tập trung (PH-09 là PAP và PIP, OPA là PDP, bundle ký, đệm ở PEP, thư viện dùng chung); **ADR 091** giả danh hóa HMAC-SHA256 theo (tenant, mục đích) và token hóa đảo ngược bằng transit hội tụ, không bảng ánh xạ; **ADR 092** ẩn danh hóa bằng ARX (Java, Apache-2.0), k tối thiểu 10, đo rủi ro ba mô hình; **ADR 093** phát hiện DLCN bằng bộ mẫu và kiểm tổng, không dùng học máy ở đợt 2.

### 13.5. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bảng ghi việc cần sửa ở tài liệu chung và phân hệ khác, vì tập này không tự sửa các tài liệu đó.


| Tài liệu | Đề nghị |
|---|---|
| D00-02 | Mở ADR 090, 091, 092, 093 theo §13.4 |
| D02-08 §3.2, §4, §5 | Thêm 13 quyền `PERM-09-*` và các scope `privacy:decide`, `apply`, `pseudonymize`, `register`, `consent` như FRS Phụ lục B |
| D03-03-PH09 | Bảng `usage_counter` đủ cột giờ; chỉ mục `purpose_grant (tenant_id, status, valid_to)` cho `GrantScheduler`; cột `snapshot_version` hoặc bảng tương đương để data plane thăm dò đổi bản chụp |
| D03-04-PH09 | Thêm tiêu đề `ETag` cho `classification-index` và `bundles/current`; trả `X-Datahub-Masking` ở phản hồi đọc của PEP |
| D03-09, D04-01 | Namespace job riêng cho `privacy-arx`; lớp ArchUnit `PrivacyCrypto`, `FailSafePolicy` thêm vào bộ chung |
| PH-04, PH-06, PH-14, PH-19, PH-03 | Dùng `dh-privacy-client`; khai `FailMode` khi khởi tạo; xóa đệm theo EVT-09-07, 08, 12 |
| PH-13 | Hỗ trợ tra nhật ký theo `subjectHash` (Q09-16) và ghi kiểm toán đồng bộ trong 100 ms |
| PH-12 | Máy chủ bundle nhận bundle PH-09 riêng nguồn dữ liệu, bộ ca chuẩn chạy ở CI của PH-12 |
| D00-04 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi nhận tập này |

: Đề nghị đồng bộ với tài liệu khác

**Kết quả đồng bộ với FRS 0.2.** Sáu đề nghị của bản 0.1 đã được FRS 0.2 nhận (Phụ lục C, các dòng "SDD 13.5"): (1) tên thư viện chốt là `dh-privacy-client` (FR-09-028, §2.4); (2) tham số `09.decision.cache-seconds` có ở §8.2, mặc định và trần 15, miền 0 đến 15; (3) ba cờ `09.feature.*` có ở §8.2; (4) hợp đồng `retention:purge` do phân hệ sở hữu cung cấp, FR-09-041 bước 3 nêu `table`, `cutoff`, `action`, `batchId`, `dryRun` và kiểm `cutoff`, PH-09 không thêm API; (5) NFR-09-024 đặt độ trễ thu hồi tại điểm thực thi ≤ 15 giây qua sự kiện và 60 giây qua bundle; (6) BR-09-062 đặt đệm `DENY` tối đa 5 giây; việc rà API-09-216 đến 226 với §4.16 đã làm ở bản 0.2 của tập API. Tập này đã sửa theo các điểm trên ở mục 4.17, 8.5, 8.6, 9.1, 9.2. Dòng D03-03-PH09 và D03-04-PH09 ở bảng trên được xử lý như sau: DDL có `usage_counter` theo `bucket_at` và chỉ mục `ix_purpose_grant_expiry` nên đủ cho `GrantScheduler`; `ETag` đã có ở `classification-index` và `bundles/current` (API-09-232, 233); bản chụp phân loại dùng `ETag` là băm nội dung nên không cần cột `snapshot_version`; tiêu đề `X-Datahub-Masking` là hành vi của điểm thực thi, không thuộc API của PH-09.

### 13.6. Câu hỏi mở

> **Câu hỏi mở Q09-20:** Đệm `ALLOW` 15 giây và `DENY` 5 giây ở PEP (§8.6) có đủ cho BR-09-017 mà không làm tăng tải `decide` quá NFR-09-004, hay cần kéo giảm xuống 5 giây và chấp nhận thêm tải; cần đo trên hồ sơ 200 HTTT.

> **Câu hỏi mở Q09-21:** Plugin APISIX viết bằng Lua có dùng chung mã `MaskEngine` bản Java được không, hay cần bản Lua riêng kèm ca tương đương Rego chạy trên cả hai.

> **Câu hỏi mở Q09-22:** Khóa làm việc HMAC giữ trong bộ nhớ 5 phút có thể bị đọc từ bản sao lõi bộ nhớ (core dump) hay kênh phụ; có cần tắt core dump và dùng vùng nhớ khóa riêng cho `KeyCache` hay không.

> **Câu hỏi mở Q09-23:** `transit` hội tụ (convergent) cho token hóa có đủ an toàn trước tấn công đoán giá trị với miền giá trị nhỏ (ví dụ giới tính, mã tỉnh), hay phải chặn token hóa cho trường có entropy thấp.

> **Câu hỏi mở Q09-24:** `dh-data` có được cấp `Role` tạo Job ở namespace job riêng cho `privacy-arx` (ngoại lệ so với SEC-53) hay Job do bộ điều phối riêng tạo, thống nhất với kết luận Q06-24.

> **Câu hỏi mở Q09-25:** ARX chạy trong bộ nhớ một nút có đủ cho tập vượt 5 triệu bản ghi của tỉnh lớn, hay cần chia theo khối và hợp kết quả mà vẫn giữ bảo đảm k.

> **Câu hỏi mở Q09-26:** Phân vùng `privacy_audit_event` và `usage_counter` có cần cho 2 triệu bản ghi mỗi tháng, hay một bảng chỉ mục theo (tenant, thời điểm) là đủ trong 12 tháng.

> **Câu hỏi mở Q09-27:** Tạo `cutoff` của tác vụ lưu giữ do PH-09 tính hay do phân hệ sở hữu tính từ lịch (đồng hồ hai bên có thể lệch múi giờ lưu ngày).

> **Câu hỏi mở Q09-28:** Bộ ca chuẩn chính sách ≥ 300 ca do ai sở hữu và cập nhật khi có quy tắc Rego mới (PH-12 hay PH-09), và ngưỡng chặn phát hành khi ca mới chưa có.

> **Câu hỏi mở Q09-29:** Cờ `overdue` của DSR và đồng hồ 72 giờ tính theo giờ Việt Nam (UTC+7) hay UTC, và hiển thị mốc nào cho cán bộ khi vụ việc qua nửa đêm.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-SDD và K-TRINH-BAY: cấu trúc module `privacy`, mô hình miền, 15 thành phần và thư viện `dh-privacy-client` với khối đặc tả 10 mục, chín sơ đồ trình tự, bảng trạng thái theo enum FRS, đệm và đóng an toàn ở PEP, ánh xạ ERR-09, chỉ số `privacy_*`, bốn ADR đề xuất số 090 đến 093, đề nghị cho FRS, câu hỏi mở Q09-20…29 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: thư viện `dh-privacy-client` chốt, đệm `DENY` 5 giây theo BR-09-062, `09.decision.cache-seconds`, `09.mask.reveal-alert-per-hour`, hai khóa hạn mức API, ERR-09-001…082, NFR-09-024, đồng hồ vi phạm dừng duy nhất khi đã thông báo Cục A05, mục 13.5 thành kết quả đồng bộ |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: `ClassificationLookupApi` thêm PH-08; chế độ `ClassificationOnly` của `dh-privacy-client` cho PH-17; PH-18 chuyển sự cố qua API-09-203; chốt câu hỏi mở đợt đồng bộ: Q393 |
