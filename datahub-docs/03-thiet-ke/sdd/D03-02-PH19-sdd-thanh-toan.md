---
ma_tai_lieu: D03-02-PH19
ten: Thiết kế chi tiết phân hệ PH-19 Thanh toán điện tử
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, lập trình viên dh-payment và dh-console, kiểm thử viên, nhóm vận hành, cán bộ ATTT
phan_he: PH-19
nguoi_lap: Nhóm phân hệ PH-19
---

# D03-02-PH19 · Thiết kế chi tiết phân hệ PH-19 Thanh toán điện tử

## Tóm tắt cho hội đồng thẩm định

PH-19 là cổng thanh toán trung gian của tỉnh: các HTTT (dịch vụ công, một cửa, hộ tịch…) gọi một API duy nhất để thu phí, lệ phí qua Nền tảng thanh toán của Cổng Dịch vụ công quốc gia (PayGov); Datahub ghi nhận giao dịch, nhận kết quả có xác minh, báo lại cho HTTT, hoàn tiền có phê duyệt và đối soát hằng ngày với PayGov. Phân hệ thay khối Payment của LGSP cũ. Tài liệu này mô tả cách phần mềm được xây để đáp ứng [FRS D02-03-PH19](../../02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md) và mười quyết định ADR-040…049.

Năm điểm thiết kế quyết định độ tin cậy của phân hệ:

1. **Lõi nghiệp vụ không biết PayGov.** Mọi trao đổi với nhà cung cấp đi qua một cổng Java `PaymentProviderPort`; adapter PayGov là lớp chống nhiễm (ADR-040), chuyển định dạng, chữ ký, mã kết quả của PayGov thành khái niệm nội bộ. Mã kết quả đi qua bảng ánh xạ cấu hình có phê duyệt (§7); mã chưa biết luôn ra kết cục `UNKNOWN`, không bao giờ thành công.
2. **Đúng một lần ở cả hai chiều.** Chiều vào từ đối tác: khóa lũy đẳng trên Valkey và bảng `idempotency_record`, bảng chống trùng mã hồ sơ không phân vùng (ADR-041). Chiều vào từ PayGov: hộp nhận `callback_inbox` ghi nguyên văn rồi xử lý tuần tự theo giao dịch (ADR-042). Chiều ra: outbox cùng giao dịch CSDL, webhook ký HMAC có số thứ tự (ADR-044).
3. **Tenant được xác định trước khi chạm dữ liệu.** Lời gọi của đối tác mang tenant trong token; callback của PayGov không có token, nên tenant lấy từ `connectionKey` 160 bit trong đường dẫn và được kiểm tra chéo với mã đơn vị trong nội dung đã ký (ADR-045). RLS `FORCE` chặn mọi truy cập chéo.
4. **Tiền chỉ đổi qua bốn mắt.** Kích hoạt NCC, duyệt đối tác, hoàn tiền, xử lý chênh lệch, mở lại phiên, đổi chế độ định tuyến, đổi bảng ánh xạ đều qua một máy trạng thái đề nghị phê duyệt chung với ràng buộc tách nhiệm ở cả ứng dụng và CSDL (ADR-046).
5. **Sống sót khi phần còn lại của Datahub ngừng.** `dh-payment` là DU riêng ở tầng phục hồi `TPH-0` với cụm `pg-payment` riêng (chốt Q340): khi control plane và `pg-core` ngừng, công dân vẫn thanh toán được, IPN vẫn được nhận và webhook vẫn được gửi.

Về an toàn thông tin: khóa ký, chứng thư chỉ ở OpenBao, ký qua transit khi PayGov cho phép (ADR-012); dữ liệu cá nhân người nộp mã hóa mức trường bằng khóa của từng tenant và tìm kiếm qua băm HMAC (ADR-048, chi tiết hóa ADR-032); không lưu số thẻ, số tài khoản, OTP (BR-19-032); bảng lịch sử, IPN nguyên văn, phiên đã chốt là chỉ-ghi-thêm, biên bản lưu WORM (ADR-031, ADR-047). Thiết kế đáp ứng cấp độ 3 theo NĐ 331/2026 và TCVN 14423:2026, sẵn sàng cấp độ 4 (ADR-030).

Phạm vi: DU `dh-payment` (API quản trị, API đối tác, callback, bộ xử lý nền), schema `ph19_payment` trên cụm `pg-payment`, phần `features/payment` của `dh-console`. Ngoài phạm vi: DDL đầy đủ ([D03-03-PH19](../csdl/D03-03-PH19-csdl-thanh-toan.md)), hợp đồng API ([D03-04-PH19](../api/D03-04-PH19-api-thanh-toan.md)), màn hình ([D03-06-PH19](../uiux/D03-06-PH19-man-hinh-thanh-toan.md)).

## 1. Phạm vi và cách đọc

### 1.1. Mục đích

Tài liệu chuyển FRS, use case [D02-04-PH19](../../02-yeu-cau/use-case/D02-04-PH19-use-case-thanh-toan.md) và ADR-040…049 thành cấu trúc mã nguồn, giao diện Java và TypeScript, thuật toán, máy trạng thái, cấu hình, quan sát và kiểm thử ở mức đủ để đội phát triển bắt đầu viết mã mà không tự quyết điểm kiến trúc. Khi nhắc tới bảng, cột, API, sự kiện, mã lỗi, tài liệu dùng đúng tên trong FRS, D03-03-PH19 và D03-04-PH19.

### 1.2. Đối tượng đọc

| Người đọc | Mục nên đọc |
|---|---|
| Lập trình viên backend | §2…§14 |
| Lập trình viên giao diện | §3.5, §8, §9.1, D03-06-PH19 |
| Kiểm thử viên | §4.5, §5, §6, §7, §11, §16 |
| Vận hành | §2.1, §6, §14, §15 |
| Cán bộ ATTT | §4.3, §9, §14 |
| Kiến trúc sư thẩm định | Tóm tắt, §2, §4, §6, §7, §9, §17 |

### 1.3. Tài liệu liên quan

| Mã | Tên | Quan hệ |
|---|---|---|
| [D00-01](../../00-chung/D00-01-thuat-ngu-quy-uoc.md) | Thuật ngữ, quy ước | Kiểu T-*, đặt tên |
| [D02-03-PH19-00](../../02-yeu-cau/frs/D02-03-PH19-00-khung-truy-vet.md) | Khung truy vết PH-19 | Mã, máy trạng thái, thực thể |
| [D02-03-PH19](../../02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md) | FRS PH-19 | FR, BR, NFR, tham số `19.*` |
| [D02-04-PH19](../../02-yeu-cau/use-case/D02-04-PH19-use-case-thanh-toan.md) | Use case PH-19 | UC-19 |
| [D03-01](../D03-01-sad.md) | SAD | DU, cụm CSDL, tầng phục hồi |
| [D03-07](../attt/D03-07-thiet-ke-attt.md) | Thiết kế ATTT | SEC-*, mã hóa, kiểm toán |
| [D03-09](../ha-tang/D03-09-ha-tang-trien-khai-dr.md) | Hạ tầng, DR | Namespace `dh-payment`, vùng Z3, định cỡ |
| [D03-10](../D03-10-thiet-ke-da-tenant.md) | Đa tenant | RLS, `TenantContext` |
| [D03-03-PH19](../csdl/D03-03-PH19-csdl-thanh-toan.md) | CSDL PH-19 | DDL, RLS, phân vùng |
| [D03-04-PH19](../api/D03-04-PH19-api-thanh-toan.md) | API PH-19 | OpenAPI, AsyncAPI, ERR-19 |
| [D03-06-PH19](../uiux/D03-06-PH19-man-hinh-thanh-toan.md) | Màn hình PH-19 | UI-19 |
| [D05-02-PH19](../../05-kiem-thu/test-case/D05-02-PH19-test-case.md) | Ca kiểm thử PH-19 | TS-19, TC-19 |
| [D03-02-PH07](D03-02-PH07-sdd-danh-muc.md) | SDD PH-07 | Mẫu `TenantSession`, outbox |

### 1.4. Quyết định kiến trúc áp dụng

| ADR | Quyết định | Tác động trong SDD |
|---|---|---|
| ADR-001 | Spring Boot 4 + Spring Modulith | §2, §3 |
| ADR-003 | PostgreSQL RLS cách ly tenant | §3.6, §9.3 |
| ADR-004 | Kafka, outbox | §6 |
| ADR-005, ADR-033 | APISIX ở biên (`apisix-ext` Z1, `apisix-int` Z2), WAF Coraza | §2.3, §9.2 |
| ADR-006 | Keycloak + OPA | §9.1 |
| ADR-008 | Garage cho tệp; Ceph RGW Object Lock cho WORM (chốt Q306, Q347) | §11.6, §15 |
| ADR-011 | OpenTelemetry | §15.2 |
| ADR-012 | OpenBao | §4.3, §9.4 |
| ADR-031, ADR-032 | Kiểm toán chuỗi băm WORM; mã hóa envelope | §9.4, §9.5 |
| [ADR-040](../../00-chung/adr/ADR-040-adapter-chong-nhiem-nha-cung-cap.md) | Cổng NCC và adapter chống nhiễm | §4 |
| [ADR-041](../../00-chung/adr/ADR-041-idempotency-va-chong-trung.md) | Idempotency hai tầng, bảng chống trùng mã hồ sơ | §5.2, §5.3 |
| [ADR-042](../../00-chung/adr/ADR-042-inbox-outbox-trong-du.md) | Inbox, outbox trong DU, không phụ thuộc Kafka để báo đối tác | §6 |
| [ADR-043](../../00-chung/adr/ADR-043-mo-hinh-trang-thai-giao-dich.md) | Máy trạng thái giao dịch nội bộ, ánh xạ mã NCC qua bảng (GĐ-03) | §5.4, §7 |
| [ADR-044](../../00-chung/adr/ADR-044-ky-webhook-hmac.md) | Ký webhook HMAC-SHA256 kiểu `t=,v1=` | §6.4 |
| [ADR-045](../../00-chung/adr/ADR-045-xac-dinh-tenant-callback.md) | Xác định tenant của callback bằng `connectionKey` | §6.2 |
| [ADR-046](../../00-chung/adr/ADR-046-phe-duyet-bon-mat.md) | Đề nghị phê duyệt bốn mắt dùng chung | §12 |
| [ADR-047](../../00-chung/adr/ADR-047-luu-tru-phan-vung.md) | Phân vùng theo tháng, lưu trữ dài hạn | §15.3, D03-03-PH19 |
| [ADR-048](../../00-chung/adr/ADR-048-ma-hoa-dlcn-nguoi-nop.md) | Mã hóa DLCN người nộp, băm tìm kiếm | §9.5 |
| [ADR-049](../../00-chung/adr/ADR-049-strangler-theo-doi-tac.md) | Chuyển đổi strangler theo từng đối tác | §13 |

### 1.5. Quy ước trong tài liệu

Mã Java là Java 21, Spring Boot 4.0.x; mã TypeScript là TS 5.x, React 19, antd v6; SQL là PostgreSQL 18 (DDL đã chạy thử trên 16). Ví dụ dùng tenant `T68`, NCC `PAYGOV-T68`, đối tác `MCDT-T68`, dịch vụ `LP-LLTP`. Tên bucket dùng mã tenant viết thường (`dh-t68-payment`); khóa Valkey, topic Kafka dùng mã tenant viết thường (`t68:payment:…`, `t68.payment.…`). Các đoạn mã là mẫu thiết kế: chữ ký công khai, tên lớp, tên bảng, thứ tự thao tác là ràng buộc.

Mọi chi tiết của PayGov (tên trường, thuật toán ký, mã kết quả, định dạng đối soát) là **giả định chờ đối chiếu tài liệu kỹ thuật kết nối do VPCP cấp** (OQ-19-01…08); chúng chỉ xuất hiện trong package `adapter.paygov` và bảng ánh xạ §7.

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vai trò tiến trình

PH-19 chạy trong DU riêng `dh-payment` (SAD §4.2), namespace `dh-payment`, vùng Z3, tầng phục hồi `TPH-0`. Một ảnh container chạy ba vai trò, chọn bằng hồ sơ Spring (`spring.profiles.active`), để mở rộng độc lập theo tải:

| Vai trò | Nhận | Thành phần chạy | Bản sao (QM-VUA) | Mở rộng |
|---|---|---|---|---|
| `api` | API quản trị `/api/payment/v1`, API đối tác `/api/payment-partner/v1` | Controller, dịch vụ ứng dụng, adapter (khởi tạo, truy vấn) | 3 | HPA theo CPU, độ trễ p95 |
| `callback` | `/api/payment-callback/v1/**` | Xác minh IPN, ghi inbox, trang quay về | 2 | HPA theo số yêu cầu |
| `worker` | Không nhận HTTP (chỉ cổng quản lý) | Bộ xử lý inbox, bộ gửi webhook, bộ phát outbox (khi chưa có Debezium), bộ lập lịch (truy vấn bù, hết hạn, đối soát, sức khỏe), tác vụ nền | 2 | KEDA theo tồn đọng inbox, outbox, `background_job` |

Ba vai trò dùng chung schema `ph19_payment` trên `pg-payment` (CloudNativePG, 3 nút, đồng bộ tối thiểu một bản sao, NFR-19-011) và bản sao đọc cho tra cứu, báo cáo (§8). Bộ lập lịch dùng ShedLock trên bảng `shedlock` để mỗi tác vụ chỉ chạy ở một pod; tác vụ giám sát sức khỏe dùng khóa lãnh đạo Valkey `{tenant}:payment:health-leader` để giảm số lời gọi tới PayGov.

### 2.2. Sơ đồ thành phần

```mermaid
flowchart LR
  subgraph Z1["Z1 biên ngoài"]
    AX[apisix-ext]
  end
  subgraph Z2["Z2 cổng nội bộ"]
    AI[apisix-int<br/>cửa ra]
  end
  subgraph Z3["Z3 namespace dh-payment"]
    API[dh-payment api]
    CB[dh-payment callback]
    WK[dh-payment worker]
  end
  subgraph DATA["Dữ liệu TPH-0"]
    PG[(pg-payment<br/>ph19_payment)]
    PGR[(bản sao đọc)]
    VK[(Valkey)]
    OB[(OpenBao)]
    GA[(Garage<br/>dh-t68-payment)]
    CR[(Ceph RGW WORM<br/>dh-t68-payment-worm)]
    KF[(Kafka)]
  end
  HTTT[[HTTT đối tác]] --> AX --> API
  PGV[[PayGov]] --> AX --> CB
  ND([Người nộp]) --> AX --> CB
  CON[dh-console] --> AI --> API
  API --> PG & VK & OB
  API --> PGR
  CB --> PG & VK & OB
  WK --> PG & VK & OB & GA & CR
  WK --> KF
  API -- khởi tạo, truy vấn --> AI --> PGV
  WK -- truy vấn, hoàn, đối soát --> AI
  WK -- webhook --> AI --> HTTT
  KF --> PH13[PH-13] & PH16[PH-16]
```

### 2.3. Phụ thuộc với phân hệ khác

| Phân hệ | Hướng | Cơ chế | Khi phân hệ ngừng |
|---|---|---|---|
| PH-03 (APISIX) | Vào, ra | Tuyến `payment-admin`, `payment-partner`, `payment-callback`; cửa ra tới PayGov, webhook | Không phục vụ được; APISIX thuộc `TPH-0` |
| PH-12 (Keycloak) | Vào | JWT, JWKS đệm 10 phút; API quản trị client | Token còn hạn vẫn chạy (≤ 5 phút); cấp client mới bị chặn |
| OPA | Vào | Quyết định quyền, gói chính sách đệm cục bộ | Dùng gói đệm cuối cùng |
| PH-07 | Đọc | API tra mã, sự kiện `catalog.item-changed.v1` | Đệm mã (Caffeine 10 phút, Valkey 24 giờ); ghi mới cần kiểm tra bị chặn ERR-19-039 |
| PH-09 | Đọc | API chính sách che | Quy tắc che mặc định BR-19-031 |
| PH-13 | Ra | Kafka `audit.recorded.v1`, OTLP, luật cảnh báo | Kiểm toán nằm trong outbox chờ phát |
| PH-20 | Vào | Sự kiện bật, tắt mô-đun | Không ảnh hưởng tenant đã bật |
| PH-05 | Đọc | Kết nối chỉ đọc CSDL hệ cũ (di trú) | Di trú bằng tệp |

`dh-payment` **không** gọi đồng bộ bất kỳ DU nào thuộc control plane (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`) trên đường thu tiền; mọi phụ thuộc trên đường thu tiền thuộc `TPH-0` (D03-09 §7.1).

### 2.4. Luật Spring Modulith

1. Ứng dụng `PaymentApplication` gồm các module: `provider`, `catalog`, `partner`, `transaction`, `callback`, `refund`, `reconciliation`, `approval`, `notification`, `reporting`, `config`, `migration`, cùng `shared` (không phải module, chỉ thư viện).
2. Mỗi module chỉ công bố package `api` (giao diện truy vấn, lệnh, DTO, sự kiện miền); phần còn lại `internal`.
3. Phụ thuộc cho phép (không vòng): `transaction → provider.api, catalog.api, partner.api, config.api`; `callback → transaction.api, provider.api`; `refund → transaction.api, provider.api, approval.api`; `reconciliation → transaction.api, refund.api, provider.api, approval.api`; `notification → partner.api`; `migration → mọi *.api`; `approval` không phụ thuộc module nghiệp vụ (đối tượng được duyệt nhận quyết định qua sự kiện miền `ApprovalDecided`).
4. `ApplicationModules.of(PaymentApplication.class).verify()` chạy trong CI.
5. Sự kiện miền giữa module trong cùng giao dịch dùng `ApplicationEventPublisher` đồng bộ (cần thay đổi nguyên tử, ví dụ hoàn tiền thành công cập nhật giao dịch gốc); sự kiện không cần nguyên tử dùng `@ApplicationModuleListener`. Sự kiện ra ngoài DU luôn qua `outbox_event`.

### 2.5. Hiện trạng mã và đường chuyển

Kho mã hiện chưa có phân hệ thanh toán (khoảng trống ghi ở bộ nhớ dự án ngày 21/11/2026 và FRS §1.5). PH-19 được viết mới trong `apps/payment/` với package gốc `vn.datahub.payment` (Q350), không chuyển mã cũ của Viettel. Dữ liệu cũ đi qua công cụ di trú §13.

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

```text
vn.datahub.payment
├── PaymentApplication.java
├── shared/                      # TenantContext, Money, TxnCode, ProblemFactory, Clock, Ids (UUIDv7)
├── provider/
│   ├── api/                     # ProviderQueryApi, ProviderRef, ProviderCapabilities, events
│   ├── spi/                     # PaymentProviderPort, ProviderRequest/Result records (cổng ADR-040)
│   ├── internal/
│   │   ├── web/                 # ProviderController, CredentialController, CheckRunController
│   │   ├── lifecycle/           # ProviderService, ActivationChecklist, RetirementGuard
│   │   ├── credential/          # CredentialRefService, OpenBaoMetadataClient, RotationService
│   │   ├── health/              # HealthMonitor, CircuitBreakerRegistry (Resilience4j), HealthLeader
│   │   ├── mapping/             # ResultMappingService, ResultMapper, MappingVersion (§7)
│   │   └── checkrun/            # ConnectionTester, TestTransactionRunner
│   ├── adapter/
│   │   ├── paygov/              # PayGovAdapter, PayGovSigner, PayGovCallbackParser, PayGovReconParser
│   │   └── mock/                # MockProviderAdapter (NFR-19-032), chỉ nạp ở hồ sơ không phải PROD
├── catalog/                     # ServiceGroup, PaymentService, CatalogLookupClient (PH-07), CatalogValidityListener
├── partner/                     # Partner, PartnerClientService (PH-12), ServiceGrant, WebhookEndpoint, RoutingMode
├── transaction/
│   ├── api/                     # TransactionQueryApi, TransactionCommandApi, TransactionStateChanged
│   └── internal/
│       ├── web/                 # PartnerPaymentController, AdminTransactionController
│       ├── create/              # CreatePaymentHandler, PaymentValidator (15 bước), QuotaCounter
│       ├── idem/                # IdempotencyService, IdemKeyStore (Valkey), IdemRecordRepository
│       ├── state/               # TransactionStateMachine, Transition, TransitionSource
│       ├── query/               # PendingQueryScheduler, ExpiryScheduler, ManualSyncService
│       └── pii/                 # PayerDataProtector (mã hóa, băm tìm kiếm, che)
├── callback/                    # CallbackController, CallbackVerifier, InboxWriter, InboxProcessor, ReturnPageController
├── refund/                      # RefundService, RefundExecutor, ManualConfirmation
├── reconciliation/              # SessionScheduler, Collector, Matcher, DiscrepancyService, MinutesGenerator
├── approval/                    # ApprovalService, FourEyesGuard, ApprovalExpiryJob
├── notification/                # OutboxWriter, OutboxRelay, WebhookDispatcher, WebhookSigner, NotificationFeed
├── reporting/                   # DashboardService, StatsAggregator, ReportService, ExportJobRunner
├── config/                      # TenantPaymentConfigService, ConfigVersion, ModuleProvisioner
├── migration/                   # LegacyReader (JDBC, CSV), ImportRunner, LegacyStatusMapper, ShadowComparer
└── audit/                       # AuditWriter (outbox → PH-13), AuditAction (§9.6)
```

### 3.2. Trách nhiệm các lớp chính

| Lớp | Trách nhiệm | FR |
|---|---|---|
| `ProviderService` | Khai báo, sửa, vòng đời NCC; áp `pending_changes` sau kiểm tra kết nối | FR-19-001, 005, 006, 009, 010 |
| `ActivationChecklist` | Tính bốn mục của BR-19-010 từ `provider_check_run`, `provider_credential` | FR-19-005 |
| `HealthMonitor` | Thăm dò định kỳ, gộp số liệu cửa sổ trượt, đặt `health_status`, mạch | FR-19-011 |
| `ResultMappingService` | Đọc bảng ánh xạ theo phiên bản, đề nghị đổi, áp phiên bản mới | FR-19-069 |
| `CreatePaymentHandler` | Điều phối tạo giao dịch: lũy đẳng, kiểm tra, hạn mức, ghi, gọi NCC | FR-19-022…024, 033, 034 |
| `PaymentValidator` | 15 bước của BR-19-004 theo thứ tự cố định | FR-19-023 |
| `TransactionStateMachine` | Bảng chuyển trạng thái hợp lệ, nguồn chuyển, ghi `transaction_event` | FR-19-028, BR-19-014 |
| `CallbackVerifier` | Bảy bước xác minh IPN | FR-19-029 |
| `InboxProcessor` | Áp IPN đúng một lần, cách ly bất thường | FR-19-030, 031 |
| `PendingQueryScheduler` | Lịch truy vấn bù BR-19-016 | FR-19-036 |
| `RefundExecutor` | Thực thi hoàn chế độ `API`, `MANUAL` | FR-19-040 |
| `Matcher` | So khớp phiên đối soát, phân loại chênh lệch | FR-19-044 |
| `FourEyesGuard` | Kiểm tra tách nhiệm theo loại đề nghị | BR-19-011 |
| `WebhookDispatcher` | Gửi, thử lại, ký webhook | FR-19-060, 062 |
| `OutboxRelay` | Phát outbox lên Kafka khi chưa có Debezium | FR-19-061 |
| `ModuleProvisioner` | Khởi tạo tài nguyên khi bật PH-19 cho tenant | FR-19-064 |
| `ImportRunner`, `ShadowComparer` | Nhập dữ liệu hệ cũ, đối chiếu | FR-19-065, 068 |

### 3.3. Kiểu giá trị dùng chung

```java
package vn.datahub.payment.shared;

/** Số tiền VND nguyên đồng (T-MONEY). Không có phép toán số thực. */
public record Money(long dong) {
  public static final long MAX = 999_999_999_999L;
  public Money {
    if (dong < 0 || dong > MAX) throw new IllegalArgumentException("ERR-19-010");
  }
  public Money plus(Money o) { return new Money(Math.addExact(dong, o.dong)); }
  public Money minus(Money o) { return new Money(Math.subtractExact(dong, o.dong)); }
  public boolean gt(Money o) { return dong > o.dong; }
}

/** Mã giao dịch BR-19-002: {tenant}{yyMMdd}{10 ký tự Base32 Crockford}. */
public record TxnCode(String value) {
  private static final Pattern P = Pattern.compile("^[A-Z][A-Z0-9]{1,15}\\d{6}[0-9A-HJKMNP-TV-Z]{10}$");
  public TxnCode { if (!P.matcher(value).matches()) throw new IllegalArgumentException("ERR-19-001"); }
  public static TxnCode generate(TenantId t, LocalDate vnDate, SecureRandom r) { /* 50 bit ngẫu nhiên */ }
}
```

Mọi thời điểm là `Instant` (UTC); ngày nghiệp vụ tính bằng `ZoneId.of("Asia/Ho_Chi_Minh")` qua `BusinessCalendar` (NFR-19-028). JSON dùng `long` cho số tiền, không có `double` ở bất kỳ DTO nào; bài kiểm thử kiến trúc ArchUnit chặn kiểu `double`, `float`, `BigDecimal` trong package `transaction`, `refund`, `reconciliation`.

### 3.4. DTO và record chính

```java
// API-19-101 (đối tác tạo giao dịch)
public record CreatePaymentRequest(
    @NotBlank @Size(max = 32) String serviceCode,
    @NotBlank @Size(max = 64) @Pattern(regexp = "^[A-Za-z0-9._:/-]+$") String partnerOrderId,
    @Positive long amount,
    @NotNull Currency currency,          // chỉ VND
    @Valid PayerInfo payer,              // tùy chọn từng trường, mã hóa khi lưu
    @Size(max = 255) String description,
    @Min(5) @Max(1440) Integer expiryMinutes,
    @NotBlank @Size(max = 2048) String returnUrl,
    Map<@Size(max = 40) String, @Size(max = 255) String> metadata) {}   // ≤ 10 cặp

public record CreatePaymentResponse(
    String transactionCode, TransactionStatus status, String paymentUrl,
    Instant expiresAt, long amount, String partnerOrderId, int sequence) {}

public enum TransactionStatus { CREATED, PENDING, SUCCEEDED, FAILED, EXPIRED, CANCELLED, PARTIALLY_REFUNDED, REFUNDED }
public enum ReconStatus { UNRECONCILED, MATCHED, MISMATCHED }
public enum TransitionSource { PARTNER, PROVIDER_INIT, IPN, QUERY, EXPIRY, USER, REFUND, DISCREPANCY_RESOLUTION, MIGRATION }
```

### 3.5. Giao diện `dh-console`

Phần giao diện nằm ở `apps/console/src/features/payment/` theo kiến trúc chung của D03-06-00: `routes.tsx` (28 màn UI-19-nn), `api/` (client sinh từ OpenAPI quản trị bằng `openapi-typescript` + `openapi-fetch`, TanStack Query), `components/` (thành phần riêng: `MoneyText`, `TxnStatusTag`, `ReconStatusTag`, `MaskedPayer`, `ApprovalEvidenceDrawer`, `StateTimeline`, `ProviderHealthCard`), `hooks/` (`usePermission('PERM-19-…')`, `useEtag`). Mọi số tiền hiển thị qua `MoneyText` (`Intl.NumberFormat('vi-VN')` + ` ₫`, NFR-19-030); nhãn trạng thái tiếng Việt lấy từ bảng §5.4 của FRS. Lớp điều hướng, ngăn kéo dùng vật liệu Liquid Glass; bảng, biểu mẫu dùng nền đặc (D03-05).

### 3.6. Truy cập dữ liệu

- Spring Data JDBC cho thực thể có vòng đời (NCC, dịch vụ, đối tác, giao dịch, hoàn, phiên, chênh lệch, đề nghị); `JdbcClient` cho truy vấn đọc, lô ghi dòng đối soát, outbox.
- Mỗi giao dịch CSDL mở bằng `TenantSession.run(tenantId, () -> …)` đặt `SET LOCAL app.tenant_id` trước câu lệnh đầu tiên (mẫu D03-02-PH07); tài khoản ứng dụng `ph19_app` không có `BYPASSRLS`; bảng có `FORCE ROW LEVEL SECURITY`.
- Khóa lạc quan bằng cột `version` (ETag) cho thao tác quản trị; khóa bi quan `SELECT … FOR UPDATE` trên hàng giao dịch cho mọi chuyển trạng thái (IPN, truy vấn, hoàn, chênh lệch) để tuần tự hóa theo giao dịch.
- Liquibase quản lý schema (`db/changelog/ph19/`), DDL nguồn ở D03-03-PH19.

## 4. Cổng nhà cung cấp và adapter PayGov

### 4.1. Cổng `PaymentProviderPort`

```java
package vn.datahub.payment.provider.spi;

/** Cổng chống nhiễm (ADR-040). Lõi chỉ thấy các kiểu trong package này. */
public interface PaymentProviderPort {
  String adapterType();                                   // "PAYGOV", "MOCK"
  ProviderCapabilities capabilities(ProviderConfig cfg);  // khai năng lực theo bản ghi NCC

  InitResult initiate(ProviderConfig cfg, InitRequest req);          // khởi tạo, timeout 10 s
  QueryResult query(ProviderConfig cfg, QueryRequest req);           // truy vấn trạng thái
  CancelResult cancel(ProviderConfig cfg, CancelRequest req);        // nếu capabilities.cancel
  RefundResult refund(ProviderConfig cfg, RefundRequest req);        // nếu capabilities.refund
  HealthResult ping(ProviderConfig cfg);

  /** Phân tích, xác minh IPN thanh toán hoặc hoàn. Không chạm CSDL. */
  CallbackParseResult parseCallback(ProviderConfig cfg, CallbackKind kind, RawHttpRequest raw);
  /** Phân tích trang quay về. */
  ReturnParseResult parseReturn(ProviderConfig cfg, RawHttpRequest raw);
  /** Thu thập, phân tích dữ liệu đối soát. */
  ReconFetchResult fetchRecon(ProviderConfig cfg, LocalDate businessDate);   // nếu reconSource ≠ FILE_UPLOAD
  ReconParseResult parseRecon(ProviderConfig cfg, LocalDate businessDate, InputStream file);
  /** Phản hồi mà NCC chờ cho một IPN (mã xác nhận theo đặc tả NCC). */
  RawHttpResponse callbackAck(ProviderConfig cfg, CallbackAck ack);
}

public record ProviderCapabilities(boolean cancel, boolean refund, boolean partialRefund,
    boolean refundIpn, ReconSource reconSource, boolean returnSigned, boolean mtls,
    int queryRatePerSecond, Duration callbackRetryWindow) {}

public enum ReconSource { API, FILE_FETCH, FILE_UPLOAD }

/** Kết quả thô của NCC; lõi ánh xạ ra kết cục qua ResultMapper (§7). */
public record ProviderResult(Operation operation, String providerCode, String providerMessage,
    boolean transportOk, Map<String, String> extra) {}   // transportOk = false khi timeout, 5xx, mất kết nối
```

Adapter **không** tự quyết kết cục nghiệp vụ; nó trả `providerCode` thô và cờ `transportOk`. `ResultMapper` (§7.2) là nơi duy nhất chuyển `providerCode` thành `Outcome`.

### 4.2. Đăng ký adapter

Adapter là bean Spring có `@PaymentAdapter("PAYGOV")`; `AdapterRegistry` nạp theo `payment_provider.adapter_type`. Adapter `MOCK` chỉ có trong hồ sơ `dev`, `test`, `staging` (Maven profile loại khỏi ảnh PROD; bài kiểm thử khởi động PROD khẳng định không có bean `MOCK`). Thêm NCC mới (OQ-19-13) là thêm một package `adapter.{ten}` và bảng ánh xạ mặc định, không sửa lõi (NFR-19-027).

### 4.3. Adapter PayGov (giả định)

Theo giả định A-19-01…07 và mô tả chung của Nền tảng thanh toán Cổng DVCQG, adapter hiện thực như sau; mỗi dòng đánh dấu câu hỏi cần đối chiếu.

| Khía cạnh | Thiết kế giả định | Đối chiếu |
|---|---|---|
| Vận chuyển | HTTPS TLS 1.3 (1.2 AEAD nếu PayGov chưa hỗ trợ), mTLS bằng chứng thư của tỉnh nếu PayGov yêu cầu; cửa ra qua `apisix-int`, địa chỉ đích theo `payment_provider.*_base_url` | OQ-19-02 |
| Ký yêu cầu | Chữ ký số trên chuỗi chuẩn hóa các trường theo thứ tự PayGov quy định; khóa riêng của tỉnh trong OpenBao transit (`transit/dh/t68/payment/paygov-signing`), PH-19 gọi `sign` không lấy khóa ra | OQ-19-02 |
| Xác minh IPN | Chữ ký của PayGov bằng khóa công khai ở `provider_credential` mục đích `PROVIDER_PUBLIC_KEY` (`ACTIVE` hoặc `NEXT`) | OQ-19-02, 03 |
| Mã giao dịch gửi PayGov | `transaction_code` (19 ký tự với tenant `T68`); nếu PayGov giới hạn ngắn hơn thì adapter rút gọn có thể đảo ngược | OQ-19-01 |
| Số tiền | Số nguyên VND | OQ-19-01 |
| Thời hạn | `expiresAt` gửi theo giờ Việt Nam nếu PayGov dùng giờ địa phương | A-19-14 |
| Mã kết quả | Qua bảng §7 | OQ-19-05 |
| Truy vấn | Theo mã giao dịch; giới hạn tần suất `queryRatePerSecond` (mặc định giả định 10/giây) | OQ-19-04 |
| Hủy, hoàn | `capabilities.cancel = false`, `refund = false` cho tới khi OQ-19-06, 10 trả lời | OQ-19-06, 10 |
| Đối soát | `reconSource = FILE_UPLOAD`, tệp CSV: mã giao dịch bên gọi, mã PayGov, số tiền, thời điểm thanh toán, trạng thái, ngân hàng | OQ-19-07 |

### 4.4. Bulkhead, timeout, mạch ngắt

Mỗi NCC có một bulkhead riêng (Resilience4j `ThreadPoolBulkhead`, tối đa 50 lời gọi đồng thời mỗi pod, hàng chờ 0) và một `CircuitBreaker` (cửa sổ trượt thời gian 60 giây, ngưỡng lỗi `19.provider.circuit-error-rate`, tối thiểu 20 lời gọi, nửa mở sau 30 giây với 5 lời gọi thử). Timeout: khởi tạo 10 giây, truy vấn 5 giây, hoàn 10 giây, ping 3 giây. Lỗi một NCC không chiếm luồng của NCC khác hay API quản trị (NFR-19-012). Kiểm tra mạch **trước** khi ghi CSDL ở luồng tạo giao dịch (BR-19-013).

### 4.5. Lọc dữ liệu khi ghi nhật ký tích hợp

`IntegrationLogWriter` nhận yêu cầu, phản hồi thô và áp `Redactor` theo thứ tự: bỏ tiêu đề `Authorization`, `X-Signature`, `Cookie`; thay giá trị các khóa JSON khớp `(?i)(password|secret|key|token|signature|cardNo|pan|cvv|otp|accountNo)` bằng `***`; che dữ liệu người nộp theo BR-19-031; cắt 64 KB mỗi phía (FR-19-054). Bài kiểm thử thuộc tính (jqwik) sinh nội dung có số thẻ, OTP ngẫu nhiên và khẳng định không còn trong bản ghi.

## 5. Giao dịch

### 5.1. Luồng tạo giao dịch

```mermaid
sequenceDiagram
  autonumber
  participant C as PartnerPaymentController
  participant I as IdempotencyService
  participant V as PaymentValidator
  participant Q as QuotaCounter
  participant R as TransactionRepository
  participant M as TransactionStateMachine
  participant A as PaymentProviderPort
  participant X as ResultMapper
  C->>I: begin(client, key, hash)
  alt đã có phản hồi
    I-->>C: phản hồi đã lưu (Idempotent-Replayed)
  end
  C->>V: validate(req) 15 bước
  C->>Q: reserve(partner, service, amount)
  C->>R: tx1: guard + CREATED + event + outbox EVT-19-05 + idem IN_PROGRESS
  C->>A: initiate()
  A-->>C: ProviderResult
  C->>X: map(INIT, code)
  alt SUCCEEDED
    C->>M: CREATED→PENDING (tx2) + outbox EVT-19-06
  else FAILED
    C->>M: CREATED→FAILED (tx2) + outbox EVT-19-08; Q.release
  else UNKNOWN hoặc transportOk=false
    C->>M: giữ CREATED, init_uncertain=true (tx2)
  end
  C->>I: complete(key, response)
```

Giao dịch CSDL thứ nhất (tx1) cam kết **trước** khi gọi PayGov, để nếu pod chết giữa chừng thì bản ghi `CREATED` vẫn còn và bộ truy vấn bù tìm thấy (giao dịch `CREATED` quá 2 phút mà chưa có `provider_reference` được coi là `init_uncertain`). Không giữ kết nối CSDL trong lúc gọi PayGov.

### 5.2. Idempotency hai tầng (ADR-041)

1. **Tầng nhanh, Valkey:** `SET {tenant}:payment:idem:{clientId}:{sha256(key)} {requestHash}|IN_PROGRESS NX PX 86400000`. Không đặt được thì đọc giá trị: cùng `requestHash` và `IN_PROGRESS` → ERR-19-004; cùng hash và đã có phản hồi → trả phản hồi; khác hash → ERR-19-003.
2. **Tầng chuẩn, PostgreSQL:** `idempotency_record` (khóa duy nhất `tenant_id, client_id, method, path, key`) ghi trong tx1 với `request_hash`, `status = IN_PROGRESS`; tx2 cập nhật `COMPLETED` kèm `response_status`, `response_body` (đã loại dữ liệu cá nhân). Khi Valkey mất dữ liệu, ràng buộc duy nhất của PostgreSQL vẫn chặn bản trùng.
3. `requestHash` = SHA-256 của thân yêu cầu chuẩn hóa JCS (RFC 8785) cộng `method` và `path` (BR-19-006). Bản ghi hết hạn sau 24 giờ; tác vụ dọn xóa theo lô.
4. Yêu cầu `IN_PROGRESS` quá 60 giây (pod chết) được coi là bỏ dở: lần gửi lại tiếp tục từ bản ghi `CREATED` đã có (không tạo giao dịch mới) và trả kết quả hiện tại.

### 5.3. Chống trùng mã hồ sơ

Bảng giao dịch phân vùng theo tháng nên không đặt được chỉ mục duy nhất trên `partner_order_id` toàn bảng. `transaction_order_guard` (không phân vùng) giữ khóa (`tenant_id`, `partner_id`, `partner_order_id`) cho giao dịch đang ở `CREATED`, `PENDING`, `SUCCEEDED`, `PARTIALLY_REFUNDED`, `REFUNDED`; khi giao dịch về `FAILED`, `EXPIRED`, `CANCELLED` thì dòng guard bị xóa trong cùng giao dịch CSDL; thanh toán muộn (`CANCELLED`/`EXPIRED` → `SUCCEEDED`) chèn lại dòng guard, nếu đã có giao dịch khác giữ guard thì vẫn chuyển `SUCCEEDED` nhưng sinh chênh lệch `DUPLICATE` (BR-19-007, 018).

### 5.4. Máy trạng thái giao dịch (ADR-043)

```java
public final class TransactionStateMachine {
  private static final Map<TransactionStatus, Map<TransactionStatus, Set<TransitionSource>>> ALLOWED = Map.of(
    CREATED,   Map.of(PENDING, Set.of(PROVIDER_INIT, QUERY), FAILED, Set.of(PROVIDER_INIT, QUERY),
                      CANCELLED, Set.of(PARTNER, USER), EXPIRED, Set.of(EXPIRY), SUCCEEDED, Set.of(IPN, QUERY)),
    PENDING,   Map.of(SUCCEEDED, Set.of(IPN, QUERY), FAILED, Set.of(IPN, QUERY),
                      CANCELLED, Set.of(PARTNER, USER), EXPIRED, Set.of(EXPIRY)),
    CANCELLED, Map.of(SUCCEEDED, Set.of(IPN, QUERY, DISCREPANCY_RESOLUTION)),
    EXPIRED,   Map.of(SUCCEEDED, Set.of(IPN, QUERY, DISCREPANCY_RESOLUTION)),
    FAILED,    Map.of(SUCCEEDED, Set.of(DISCREPANCY_RESOLUTION)),
    SUCCEEDED, Map.of(FAILED, Set.of(DISCREPANCY_RESOLUTION), PARTIALLY_REFUNDED, Set.of(REFUND), REFUNDED, Set.of(REFUND)),
    PARTIALLY_REFUNDED, Map.of(PARTIALLY_REFUNDED, Set.of(REFUND), REFUNDED, Set.of(REFUND)),
    REFUNDED,  Map.of());

  /** Gọi trong giao dịch CSDL đã khóa hàng giao dịch. */
  public TransitionResult apply(PaymentTransaction tx, TransactionStatus to, TransitionSource src, TransitionContext ctx) {
    var ok = ALLOWED.getOrDefault(tx.status(), Map.of()).getOrDefault(to, Set.of()).contains(src);
    if (!ok) return TransitionResult.rejected("ERR-19-021");
    // ghi transaction_event (from, to, source, ref, trace), tăng sequence, cập nhật guard, outbox
  }
}
```

`CREATED → SUCCEEDED` có ở bảng vì IPN có thể đến trước khi phản hồi khởi tạo về (đua). Lượt quay về của người nộp không có trong `TransitionSource` nên về kiểu dữ liệu không thể đổi trạng thái (BR-19-014). Mỗi chuyển trạng thái tăng `sequence` của giao dịch (BR-19-021) và ghi `mapping_version` nếu kết cục đến từ bảng ánh xạ.

### 5.5. Hạn mức ngày

`QuotaCounter` dùng một script Lua trên khóa `{tenant}:payment:quota:{partnerId}:{serviceId}:{yyyyMMdd}` (hash hai trường `count`, `amount`, TTL 48 giờ): kiểm tra cộng thêm không vượt, rồi cộng, trả kết quả trong một lệnh nguyên tử. Hoàn lại khi giao dịch `FAILED` do NCC từ chối khởi tạo. Tác vụ mỗi 5 phút tính lại từ CSDL và sửa bộ đếm nếu lệch (BR-19-005); khi Valkey không sẵn sàng, `QuotaCounter` rơi về đếm bằng `SELECT … FOR UPDATE` trên bảng `partner_quota_usage` (đề xuất D03-03-PH19), chậm hơn nhưng đúng.

### 5.6. Truy vấn bù và hết hạn

`PendingQueryScheduler` chạy mỗi 30 giây, chọn giao dịch có `next_query_at ≤ now()` theo chỉ mục một phần (`WHERE status IN ('CREATED','PENDING') AND next_query_at IS NOT NULL`), theo lô 200, tôn trọng `queryRatePerSecond` bằng bộ giới hạn token bucket theo NCC. Sau mỗi lần truy vấn, `next_query_at` lấy từ lịch BR-19-016 (2, 5, 10, 15 phút; 30 phút, 1, 2, 4 giờ; rồi mỗi 6 giờ tới 72 giờ). `ExpiryScheduler` xử lý giao dịch quá hạn theo BR-19-017. Hai tác vụ chạy ở vai trò `worker` dưới ShedLock.

## 6. Inbox, outbox, sự kiện và webhook

### 6.1. Tổng quan (ADR-042)

`dh-payment` tự chứa mọi hàng đợi trên đường thu tiền trong `pg-payment`: `callback_inbox` cho IPN đến, `outbox_event` cho sự kiện và kiểm toán đi, `webhook_delivery` cho thông báo tới đối tác. Kafka chỉ dùng để phân phối sự kiện cho phân hệ khác (PH-13, PH-16); bộ gửi webhook đọc trực tiếp outbox nên đối tác vẫn nhận kết quả khi Kafka ngừng (NFR-19-013).

### 6.2. Nhận IPN

```java
@RestController
@RequestMapping("/api/payment-callback/v1/{adapter}/{connectionKey}")
class CallbackController {
  @PostMapping("/ipn")
  ResponseEntity<byte[]> ipn(@PathVariable String adapter, @PathVariable String connectionKey, HttpServletRequest http) {
    var raw = RawHttpRequest.capture(http, 256 * 1024);                    // giới hạn 256 KB
    var provider = providerResolver.byConnectionKey(connectionKey)         // đệm Caffeine 60 s, khóa băm SHA-256
        .orElseThrow(() -> problem(ERR_19_027));                            // không lộ tồn tại
    return TenantSession.call(provider.tenantId(), () -> {                  // ADR-045: tenant trước mọi truy cập dữ liệu
      var v = verifier.verify(provider, CallbackKind.PAYMENT, raw);         // 7 bước FR-19-029
      inboxWriter.write(provider, raw, v);                                  // RECEIVED | REJECTED | DUPLICATE
      return adapterOf(provider).callbackAck(provider.config(), v.ack());   // ≤ 200 ms
    });
  }
}
```

- `connectionKey` là 32 ký tự Base32 Crockford sinh từ 160 bit ngẫu nhiên; CSDL lưu `sha256(connectionKey)` để tra, không lưu nguyên văn ngoài OpenBao; đổi `connectionKey` là thao tác xoay có chuyển tiếp 7 ngày (hai khóa cùng hợp lệ).
- Sau khi xác định NCC, `CallbackVerifier` kiểm tra mã đơn vị kết nối trong nội dung đã ký khớp `merchant_ref` của NCC; không khớp thì `REJECTED` lý do `TENANT_MISMATCH` và cảnh báo khẩn (dấu hiệu cấu hình sai hoặc tấn công).
- Nonce: `SET {tenant}:payment:nonce:{providerId}:{nonce} {sha256(body)} NX EX 86400`; trùng nonce cùng băm → `DUPLICATE` (trả xác nhận thành công); trùng nonce khác băm → `REJECTED` ERR-19-026. Ràng buộc duy nhất (`provider_id`, `nonce`) trên `callback_inbox` là lớp thứ hai.
- `inboxWriter.write` ghi một dòng trong giao dịch CSDL ngắn (chỉ `INSERT`), không khóa hàng giao dịch, để giữ p95 ≤ 200 ms (NFR-19-003).

### 6.3. Xử lý inbox

`InboxProcessor` chạy ở vai trò `worker`, lấy việc bằng `SELECT … FROM callback_inbox WHERE status = 'RECEIVED' ORDER BY received_at LIMIT 100 FOR UPDATE SKIP LOCKED`, xử lý từng dòng trong giao dịch riêng:

1. Tìm giao dịch theo `transaction_code` hoặc `provider_reference`; khóa hàng `FOR UPDATE`.
2. `ResultMapper.map(provider, IPN, providerCode)` → `Outcome` và `mapping_version`.
3. Áp quy tắc BR-19-015, 018: kiểm số tiền (dung sai 0), tham chiếu; gọi `TransactionStateMachine.apply` với nguồn `IPN`.
4. Kết quả: `PROCESSED`; `QUARANTINED` (kèm `quarantine_reason`: `AMOUNT_MISMATCH`, `REF_MISMATCH`, `NOT_FOUND`, `UNMAPPED_CODE`, `CONFLICT_FINAL`) và chênh lệch tương ứng; `FAILED` khi lỗi kỹ thuật (thử lại tối đa 5 lần, giãn 1, 5, 15, 60, 240 giây, rồi cảnh báo).
5. Mọi IPN của cùng một giao dịch được tuần tự hóa nhờ khóa hàng; thứ tự đến không quan trọng vì máy trạng thái chỉ cho chuyển hợp lệ.

Độ trễ mục tiêu từ `received_at` tới `processed_at` p95 ≤ 2 giây; KEDA tăng bản sao `worker` khi tồn đọng `RECEIVED` > 500.

### 6.4. Outbox và phát sự kiện

`OutboxWriter.append(aggregateType, aggregateId, eventType, payload, partitionKey)` ghi `outbox_event` trong cùng giao dịch CSDL với thay đổi nghiệp vụ. Hai cách phát:

| Cách | Khi dùng | Cơ chế |
|---|---|---|
| Debezium Outbox Event Router (mặc định khi cụm có Debezium, D03-09) | QM-VUA, QM-LON | Đọc WAL `pg-payment` qua slot logic `ph19_outbox`, định tuyến tới topic theo cột `topic`, khóa theo `partition_key`; xóa dòng đã phát sau 7 ngày |
| `OutboxRelay` quét theo lô | QM-NHO, hoặc khi Debezium ngừng | `SELECT … WHERE published_at IS NULL ORDER BY id LIMIT 500 FOR UPDATE SKIP LOCKED`, gửi Kafka `acks=all` lũy đẳng, đặt `published_at` |

Sự kiện theo CloudEvents 1.0, `type = vn.datahub.payment.{entity}.{event}.v1`, `source = /{tenant}/payment`, `subject` là mã nghiệp vụ, phần mở rộng `tenantid`, `sequence`, `traceparent`. Lược đồ đăng ký Apicurio, tương thích `BACKWARD` (AsyncAPI ở D03-04-PH19). Kiểm toán đi cùng outbox với `topic = {tenant}.audit.recorded.v1` (FR-19-053).

### 6.5. Bộ gửi webhook (ADR-044)

1. `WebhookFanout` nghe outbox (đọc trực tiếp bảng, không qua Kafka) cho các `event_type` webhook được (`transaction.*`, `refund.*`, `reconciliation.closed`), tạo `webhook_delivery` cho mỗi đầu nhận `ACTIVE` của đối tác sở hữu, đã đăng ký loại sự kiện.
2. `WebhookDispatcher` lấy việc `PENDING`/`RETRY_SCHEDULED` đến hạn bằng `FOR UPDATE SKIP LOCKED`, nhưng chỉ lấy lượt có `sequence` nhỏ nhất chưa `DELIVERED` của mỗi (đầu nhận, giao dịch) để giữ thứ tự (BR-19-021).
3. Thân là CloudEvents JSON; tiêu đề: `Content-Type: application/cloudevents+json`, `Webhook-Id: {id}`, `Webhook-Timestamp: {unix}`, `X-Datahub-Signature: t={unix},v1={hex(HMAC_SHA256(secret, id + "." + t + "." + body))}`, `traceparent`. Trong 7 ngày chuyển tiếp xoay bí mật có hai giá trị `v1` phân tách bằng dấu phẩy (NFR-19-021).
4. Bí mật đọc từ OpenBao `kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}` và đệm trong bộ nhớ 5 phút (không ghi đĩa).
5. HTTP client: timeout kết nối 3 giây, tổng 10 giây, không theo chuyển hướng, chỉ HTTPS, kiểm tra lại địa chỉ IP phân giải không thuộc dải riêng ngay trước khi gửi (chống DNS rebinding), đi qua `apisix-int` cửa ra.
6. Kết quả: 2xx → `DELIVERED`; 408, 425, 429, 5xx, lỗi mạng → `RETRY_SCHEDULED` theo `19.webhook.retry-schedule` có độ ngẫu nhiên ±10%; 4xx khác → `EXHAUSTED`. Mỗi lần thử ghi `integration_log` hướng `OUT_PARTNER`.

### 6.6. Kéo thông báo dự phòng

API-19-109 đọc bảng `notification_feed` (đề xuất, D03-03-PH19): mỗi sự kiện webhook được cũng ghi một dòng (`id` UUIDv7 tăng theo thời gian, `partner_id`, `event_type`, `payload`) giữ 7 ngày; con trỏ `after` là `id` cuối đã đọc. Đối tác dùng khi webhook lỡ hoặc khi không mở được cổng nhận (A-19-10).

## 7. Bảng ánh xạ mã kết quả nhà cung cấp

### 7.1. Mô hình (FR-19-069, GĐ-03)

`provider_result_mapping` (EN-19-26, đề xuất) có các cột: `provider_id`, `mapping_version`, `operation` (`INIT`, `IPN`, `QUERY`, `CANCEL`, `REFUND`, `REFUND_IPN`, `RECON`), `provider_code`, `outcome` (`SUCCEEDED`, `FAILED`, `PENDING`, `UNKNOWN`), `is_final`, `reason_code` (mã lý do nội bộ), `message_vi`, `status` (`ACTIVE`, `RETIRED`). Phiên bản tăng dần theo NCC; chỉ một phiên bản hiện hành. Ràng buộc: `outcome = SUCCEEDED` thì `is_final = true`; không có hai dòng cùng (`provider_id`, `mapping_version`, `operation`, `provider_code`).

### 7.2. `ResultMapper`

```java
public Outcome map(ProviderRef p, Operation op, String providerCode, boolean transportOk) {
  if (!transportOk) return Outcome.unknown("TRANSPORT_ERROR", null);
  var v = versions.current(p.id());                          // đệm theo (provider, version), làm mới khi có sự kiện
  return v.lookup(op, providerCode)
      .map(row -> Outcome.of(row.outcome(), row.isFinal(), row.reasonCode(), v.number()))
      .orElseGet(() -> {
        metrics.unmappedCode(p, op, providerCode);           // payment_callback_quarantined_total, danh sách "mã đã gặp"
        return Outcome.unknown("UNMAPPED_CODE", v.number()); // không bao giờ SUCCEEDED
      });
}
```

`UNKNOWN` được xử lý như "chờ xác minh": giữ trạng thái giao dịch, `needs_reconciliation = true`, IPN `QUARANTINED` (ERR-19-028), cảnh báo, tiếp tục truy vấn bù. Mã đã gặp nhưng chưa ánh xạ được lưu vào `provider_unmapped_code` (đếm, lần đầu, lần cuối, ví dụ đã che) để hiển thị ở UI-19-04.

### 7.3. Bảng mặc định cho PayGov (giả định)

Bảng dưới là **giả định** của nhóm thiết kế dựa trên thông lệ cổng thanh toán, nạp khi khởi tạo tenant (FR-19-064) ở phiên bản 1; phải thay bằng bảng mã chính thức khi VPCP trả lời OQ-19-05. Thông điệp tiếng Việt dùng ở giao diện và webhook (`reasonMessage`).

| Thao tác | Mã PayGov (giả định) | Kết cục | Cuối | Mã lý do nội bộ | Thông điệp |
|---|---|---|---|---|---|
| `INIT` | `00` | `SUCCEEDED` (khởi tạo thành công) | Có | — | Đã tạo yêu cầu thanh toán |
| `INIT` | `09` | `FAILED` | Có | `SERVICE_NOT_REGISTERED` | Dịch vụ chưa đăng ký với nền tảng thanh toán |
| `INIT` | `11` | `FAILED` | Có | `INVALID_REQUEST` | Yêu cầu thanh toán không hợp lệ |
| `INIT` | `13` | `FAILED` | Có | `DUPLICATE_ORDER` | Mã giao dịch đã tồn tại ở nền tảng thanh toán |
| `INIT` | `97` | `UNKNOWN` | Không | `SIGNATURE_ERROR` | Lỗi chữ ký, chờ xác minh |
| `INIT` | `99` | `UNKNOWN` | Không | `PROVIDER_ERROR` | Lỗi của nền tảng thanh toán, chờ xác minh |
| `IPN`, `QUERY` | `00` | `SUCCEEDED` | Có | — | Thanh toán thành công |
| `IPN`, `QUERY` | `01` | `PENDING` | Không | `PROCESSING` | Giao dịch đang được xử lý |
| `IPN`, `QUERY` | `02` | `FAILED` | Có | `PAYMENT_FAILED` | Thanh toán không thành công |
| `IPN`, `QUERY` | `04` | `FAILED` | Có | `PAYER_CANCELLED` | Người nộp hủy thanh toán |
| `IPN`, `QUERY` | `05` | `FAILED` | Có | `PAYMENT_TIMEOUT` | Quá thời gian thanh toán |
| `IPN`, `QUERY` | `06` | `FAILED` | Có | `INSUFFICIENT_FUNDS` | Tài khoản không đủ số dư |
| `IPN`, `QUERY` | `07` | `UNKNOWN` | Không | `SUSPECTED_FRAUD` | Giao dịch nghi vấn, chờ xác minh |
| `QUERY` | `91` | `PENDING` | Không | `NOT_FOUND_AT_PROVIDER` | Nền tảng chưa ghi nhận giao dịch (trước hạn); tác vụ hết hạn xử lý như "không tồn tại" theo BR-19-017 |
| `QUERY` | `99` | `UNKNOWN` | Không | `PROVIDER_ERROR` | Lỗi của nền tảng thanh toán |
| `CANCEL` | `00` | `SUCCEEDED` | Có | — | Đã hủy tại nền tảng |
| `REFUND`, `REFUND_IPN` | `00` | `SUCCEEDED` | Có | — | Hoàn tiền thành công |
| `REFUND`, `REFUND_IPN` | `01` | `PENDING` | Không | `REFUND_PROCESSING` | Đang xử lý hoàn tiền |
| `REFUND`, `REFUND_IPN` | `02` | `FAILED` | Có | `REFUND_FAILED` | Hoàn tiền không thành công |
| `RECON` | `00` | `SUCCEEDED` | Có | — | Dòng đối soát thành công |
| `RECON` | `02` | `FAILED` | Có | `PAYMENT_FAILED` | Dòng đối soát thất bại |

Quy tắc đặc biệt ở `ExpiryScheduler`: với thao tác `QUERY`, mã lý do `NOT_FOUND_AT_PROVIDER` sau `expires_at + grace` được coi là "không tồn tại" và cho `EXPIRED` (BR-19-017). Mọi mã khác không có trong bảng ra `UNKNOWN`.

### 7.4. Đổi bảng ánh xạ

API-19-092 nhận danh sách thay đổi; `ResultMappingService` tạo bản nháp phiên bản `n+1` = phiên bản hiện hành + thay đổi, kiểm tra ràng buộc, tạo `approval_request` loại `RESULT_MAPPING_CHANGE` với `snapshot` là bảng khác biệt. Khi duyệt (§12), phiên bản `n+1` thành hiện hành trong một giao dịch CSDL, sự kiện nội bộ `ResultMappingActivated` làm mới đệm ở mọi pod (≤ 10 giây qua kênh Valkey pub/sub `{tenant}:payment:mapping-changed`). Bản ghi IPN và `transaction_event` lưu `mapping_version` đã dùng.

## 8. Phía đọc: tra cứu, dashboard, báo cáo

### 8.1. Bản sao đọc

Truy vấn danh sách, chi tiết, nhật ký, dashboard, báo cáo của API quản trị đi tới bản sao đọc của `pg-payment` (dịch vụ CNPG `pg-payment-ro`) qua `@ReadOnlyTx` định tuyến `AbstractRoutingDataSource`. Độ trễ sao chép mục tiêu < 1 giây; màn chi tiết giao dịch ngay sau một thao tác ghi đọc từ bản chính (cờ `read-your-writes` 5 giây theo người dùng trong Valkey). API đối tác truy vấn trạng thái (API-19-102, 103) đọc bản chính vì cần nhất quán ngay.

### 8.2. Chỉ mục phục vụ tra cứu

| Truy vấn | Chỉ mục (trên mỗi phân vùng tháng) |
|---|---|
| Tìm theo mã giao dịch | `UNIQUE (transaction_code)` toàn cục qua bảng `transaction_code_index` (không phân vùng) |
| Tìm theo mã hồ sơ | `(tenant_id, partner_id, partner_order_id)` |
| Tìm theo tham chiếu NCC | `(tenant_id, provider_id, provider_reference)` |
| Tìm theo người nộp | `(tenant_id, payer_search_hash)` (băm HMAC, ADR-048) |
| Danh sách mặc định | `(tenant_id, created_at DESC)` |
| Lọc trạng thái, NCC, dịch vụ | `(tenant_id, status, created_at DESC)`, `(tenant_id, service_id, created_at DESC)` |
| Truy vấn bù | Một phần `(next_query_at) WHERE status IN ('CREATED','PENDING')` |
| Đối soát ngày | `(tenant_id, provider_id, paid_at)` |

Danh sách dùng phân trang theo khóa (`createdAt`, `id`) khi người dùng cuộn sâu quá trang 50; tổng số chính xác tới 10.000 dòng bằng `count(*)` có giới hạn, trên đó trả `totalApprox` từ thống kê (FR-19-049).

### 8.3. Số liệu tổng hợp

`StatsAggregator` (worker, mỗi 60 giây) đọc outbox sự kiện giao dịch từ con trỏ cuối, cộng dồn vào `payment_stats_hourly` (`tenant_id`, `hour_vn`, `provider_id`, `service_id`, `partner_id`, `status`, `count`, `amount`) bằng `INSERT … ON CONFLICT DO UPDATE`. Dashboard đọc bảng này (NFR-19-006: trễ ≤ 60 giây), thay cơ chế đệm 10 phút của hệ cũ (LGC-PAY-026). Báo cáo tháng trở lên kết hợp `payment_stats_hourly` với kết quả phiên đối soát `CLOSED` để đánh dấu "tạm tính" (FR-19-058). Giao dịch thử, bóng không vào bảng.

### 8.4. Tác vụ xuất

`ExportJobRunner` chạy `background_job` loại `EXPORT` bằng con trỏ máy chủ (`fetchSize = 5000`) trên bản sao đọc, ghi luồng ra tệp tạm, tải lên Garage theo multipart, đặt `result_file_id`; đường tải là URL ký trước hạn 24 giờ, chỉ người tạo gọi API-19-084 mới lấy được. 1.000.000 dòng ≤ 10 phút (NFR-19-009).

## 9. Bảo mật

### 9.1. Xác thực và phân quyền

| Nhóm API | Xác thực | Phân quyền |
|---|---|---|
| Quản trị `/api/payment/v1` | JWT người dùng do Keycloak phát (PKCE qua BFF của console), `aud = dh-payment-admin` | OPA: `PERM-19-*` theo vai trò của tenant; thuộc tính đối tượng (tenant, người lập) cho tách nhiệm |
| Đối tác `/api/payment-partner/v1` | OAuth 2.1 `client_credentials`, `private_key_jwt` hoặc mTLS, token ràng buộc chứng thư (RFC 8705) khi dùng mTLS, hạn 5 phút (NFR-19-019) | Claim `partner_id`, `tenant_id`; OPA kiểm tra `PERM-19-partner-*`; mọi truy vấn lọc thêm `partner_id` |
| Callback `/api/payment-callback/v1` | Không token; allowlist IP tại APISIX, mTLS nếu PayGov dùng, chữ ký nội dung | `connectionKey` → NCC → tenant (ADR-045) |

`@PreAuthorize("@perm.has('PERM-19-refund-approve')")` ở controller là lớp thứ nhất; `FourEyesGuard` ở dịch vụ là lớp thứ hai; ràng buộc `CHECK` trên `approval_request` là lớp thứ ba (§12).

### 9.2. Mối đe dọa chính

| Mối đe dọa | Biện pháp | Kiểm thử |
|---|---|---|
| Giả mạo IPN để ghi nhận đã thu | Bốn lớp xác minh (NFR-19-020), chỉ ba nguồn có xác thực được chốt kết quả (BR-19-014), mã lạ ra `UNKNOWN` | TS-19-30 |
| Phát lại IPN cũ | Dấu thời gian ±5 phút, nonce Valkey + ràng buộc duy nhất | TS-19-30 |
| Sửa tham số trang quay về | Lượt quay về không đổi trạng thái; trang đọc trạng thái từ CSDL | TS-19-12 |
| Đối tác A truy vấn giao dịch của B | Lọc `partner_id` từ token, RLS tenant | TS-19-31 |
| Đoán `connectionKey` để gửi callback vào tenant khác | 160 bit ngẫu nhiên, kiểm tra chéo mã đơn vị đã ký, allowlist IP | TS-19-30 |
| SSRF qua địa chỉ webhook | Chỉ HTTPS, chặn dải riêng khi đăng ký và ngay trước khi gửi, không theo chuyển hướng, cửa ra qua `apisix-int` | TS-19-30 |
| Một người tự duyệt hoàn tiền | Tách nhiệm ba lớp | TS-19-33 |
| Rò rỉ dữ liệu người nộp qua log | `Redactor`, mã hóa trường, không ghi thân yêu cầu ở log ứng dụng | TS-19-34 |
| Lộ khóa ký | Khóa trong OpenBao transit, không rời OpenBao; xoay có chuyển tiếp | TS-19-06 |
| Sửa lịch sử để che gian lận | Bảng chỉ-ghi-thêm (trigger chặn `UPDATE`, `DELETE`), kiểm toán chuỗi băm, biên bản WORM | TS-19-34 |

### 9.3. Cách ly tenant

Mọi bảng có `tenant_id` và chính sách RLS `USING (tenant_id = current_setting('app.tenant_id'))`, `FORCE ROW LEVEL SECURITY`; tài khoản ứng dụng không phải chủ sở hữu bảng. `TenantContext` lấy từ token (quản trị, đối tác) hoặc từ NCC (callback), không bao giờ từ tham số do bên gọi gửi. Tác vụ nền lặp qua danh sách tenant `module_enabled = true` và mở `TenantSession` cho từng tenant; bài kiểm thử `TenantIsolationIT` khẳng định mọi bảng có chính sách và người dùng tenant A thấy 0 dòng của B (NFR-19-025).

### 9.4. Bí mật

| Bí mật | Vị trí OpenBao | Cách dùng |
|---|---|---|
| Khóa riêng ký yêu cầu tới PayGov | `transit/dh/{tenant}/payment/{providerCode}-signing` | `transit/sign`, khóa không rời OpenBao (nếu PayGov chấp nhận định dạng chữ ký của transit; nếu không, `kv` và nạp vào bộ nhớ có giới hạn thời gian) |
| Chứng thư, khóa mTLS của tỉnh | `kv/dh/{tenant}/payment/providers/{providerCode}/{env}/mtls` | Nạp vào `SSLContext` lúc khởi động và khi xoay |
| Khóa công khai PayGov | `kv/dh/{tenant}/payment/providers/{providerCode}/{env}/provider-public-key` | Xác minh IPN |
| Thông tin API PayGov | `kv/dh/{tenant}/payment/providers/{providerCode}/{env}/api-credential` | Tiêu đề xác thực |
| Bí mật ký webhook | `kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}` | HMAC |
| Bí mật ký tham số quay về | `kv/dh/{tenant}/payment/partners/{partnerCode}/return-secret` | HMAC `{transactionCode}.{status}.{ts}` |
| `connectionKey` | `kv/dh/{tenant}/payment/providers/{providerCode}/connection-key` | Chỉ hiển thị cho ADM khi đăng ký với PayGov |
| Khóa băm tìm kiếm người nộp | `transit/dh/{tenant}/payment/payer-search` (HMAC) | §9.5 |

`dh-payment` xác thực với OpenBao bằng phương thức Kubernetes, vai trò `dh-payment-{env}`, chính sách chỉ đọc các đường trên và gọi `transit/sign`, `transit/hmac`, `transit/encrypt|decrypt` của tenant.

### 9.5. Dữ liệu cá nhân người nộp (ADR-048)

- Các trường `payer_name`, `payer_id_number`, `payer_phone`, `payer_email`, `payer_address` được mã hóa envelope: mỗi giao dịch một khóa dữ liệu (DEK) AES-256-GCM sinh tại chỗ, DEK được bọc bằng khóa của tenant trong OpenBao transit (`transit/dh/{tenant}/payment/payer-kek`) và lưu cùng dòng (`payer_dek_wrapped`); bản rõ chỉ tồn tại trong bộ nhớ khi người có `PERM-19-transaction-read-pii` hiện đầy đủ (FR-19-051).
- `payer_search_hash` = HMAC-SHA256 (khóa transit `payer-search` của tenant) của từng giá trị chuẩn hóa (họ tên không dấu, chữ thường, bỏ khoảng trắng thừa; số điện thoại dạng E.164; số định danh) — lưu mảng băm, chỉ mục GIN.
- Bản che (`payer_name_masked`, `payer_phone_masked`) tính lúc ghi theo BR-19-031 để danh sách không cần giải mã.
- Xóa theo yêu cầu chủ thể (Luật 91/2025): sau thời hạn lưu chứng từ, hủy DEK đã bọc làm dữ liệu không giải mã được (crypto-shredding), giữ bản che và số liệu.

### 9.6. Kiểm toán

Danh mục hành động (`action`) gửi PH-13: `PROVIDER_CREATE`, `PROVIDER_UPDATE`, `PROVIDER_DELETE`, `CREDENTIAL_BIND`, `CREDENTIAL_ROTATE`, `CONNECTION_TEST`, `TEST_TRANSACTION`, `PROVIDER_SUSPEND`, `PROVIDER_RESUME`, `RESULT_MAPPING_CHANGE_REQUEST`, `RESULT_MAPPING_APPLIED`, `SERVICE_GROUP_*`, `SERVICE_*`, `PARTNER_*`, `PARTNER_CLIENT_ISSUE`, `PARTNER_CLIENT_REVOKE`, `SERVICE_GRANT_SET`, `WEBHOOK_ENDPOINT_*`, `WEBHOOK_SECRET_ROTATE`, `ROUTING_MODE_REQUEST`, `TRANSACTION_CANCEL`, `TRANSACTION_SYNC`, `CALLBACK_REPLAY`, `PII_VIEW`, `REFUND_CREATE`, `REFUND_EXECUTE`, `REFUND_CONFIRM_MANUAL`, `RECON_SESSION_CREATE`, `RECON_FILE_UPLOAD`, `RECON_RERUN`, `RECON_CLOSE`, `RECON_REOPEN_REQUEST`, `DISCREPANCY_ASSIGN`, `DISCREPANCY_ESCALATE`, `DISCREPANCY_NOTE`, `DISCREPANCY_PROPOSE`, `DISCREPANCY_RESOLVE`, `APPROVAL_DECISION`, `APPROVAL_WITHDRAW`, `EXPORT_CREATE`, `EXPORT_DOWNLOAD`, `CONFIG_VERSION_CREATE`, `MIGRATION_RUN`, `WEBHOOK_RESEND`, `ACCESS_DENIED`. `AuditWriter` loại giá trị bí mật và che dữ liệu cá nhân trong `before`, `after`. Không ghi được outbox thì thao tác bị hủy (ERR-19-050, BR-19-029).

## 10. Hoàn tiền

### 10.1. Lập và duyệt

`RefundService.create` khóa hàng giao dịch, kiểm tra BR-19-022 (gồm tổng `amount` của yêu cầu chưa kết thúc), xác định `required_approvals` theo `19.refund.two-level-threshold` của phiên bản cấu hình hiện hành, ghi `refund_request` và `approval_request` (loại `REFUND`) trong một giao dịch CSDL. Mã `refund_code` = `R` + 10 ký tự cuối của mã giao dịch + 4 ký tự Base32 ngẫu nhiên. Với đối tác, `partner_refund_id` duy nhất trong đối tác và đi cùng `Idempotency-Key` như §5.2.

`ApprovalDecided` (sự kiện miền đồng bộ) gọi `RefundService.onDecision`: cấp 1 với `required_approvals = 2` → `PENDING_SECOND_APPROVAL` và mở lượt duyệt thứ hai trên cùng `approval_request`; cấp cuối → `APPROVED` rồi `RefundExecutor.start`.

### 10.2. Thực thi

```java
void start(RefundRequest r) {
  var mode = resolveMode(r);                        // BR-19-024: API nếu capabilities.refund && tenant cho phép
  if (mode == MANUAL) { r.toAwaitingManual(); reminders.schedule(r, Duration.ofDays(1)); return; }
  r.toProcessing(r.executionCount() + 1);           // cam kết trước khi gọi NCC
  tx.commit();
  var res = port.refund(cfg, new RefundRequest(r.refundCode() + "-" + r.executionCount(), ...));
  var outcome = mapper.map(provider, REFUND, res.providerCode(), res.transportOk());
  switch (outcome.kind()) {
    case SUCCEEDED -> complete(r);                  // §10.3
    case FAILED    -> r.toFailed(outcome.reasonCode());
    case PENDING, UNKNOWN -> r.scheduleQuery();     // chờ REFUND_IPN hoặc truy vấn, trần 72 giờ
  }
}
```

Khóa lũy đẳng gửi NCC gồm `refundCode` và `executionCount` nên một lần thực thi không bao giờ gửi hai lệnh, còn lần thực thi lại (sau `FAILED`) là lệnh mới có chủ đích. Ghi nhận thủ công (`CONFIRM_MANUAL`) kiểm tra người xác nhận không thuộc tập người đã duyệt, tệp chứng từ đã quét mã độc và gắn `stored_file` mục đích `REFUND_VOUCHER`.

### 10.3. Hoàn tất

`complete(r)` trong một giao dịch CSDL: khóa hàng giao dịch gốc; `refunded_amount += r.amount`; gọi `TransactionStateMachine.apply(→ PARTIALLY_REFUNDED | REFUNDED, REFUND)`; `r.toSucceeded()`; outbox EVT-19-13 với khóa phân vùng `transactionId`. Kiểm tra bất biến `refunded_amount ≤ amount` bằng `CHECK` trên bảng làm lớp cuối.

## 11. Đối soát

### 11.1. Lập lịch và thu thập

`SessionScheduler` (cron theo `19.recon.cutoff-time` của từng tenant, ShedLock theo tenant) tạo phiên `INSERT … ON CONFLICT (tenant_id, provider_id, business_date) DO NOTHING`. `Collector` gọi `fetchRecon` hoặc chờ tải tệp theo `reconSource`; tệp gốc luôn lưu Garage trước (`stored_file` mục đích `RECON_SOURCE`, SHA-256), rồi `parseRecon` trả luồng `ReconLine` (`kind`, `providerReference`, `transactionCode`, `amount`, `providerStatusCode`, `paidAt`). Dòng chuẩn hóa ghi vào bảng tạm `recon_provider_line` gắn `session_id`, `run_no`.

### 11.2. So khớp

`Matcher` chạy bằng SQL trên bản chính trong một giao dịch đọc nhất quán (`REPEATABLE READ`):

```sql
-- Tập phía Datahub của ngày T (giờ Việt Nam), loại thử và bóng
WITH dh AS (
  SELECT id, transaction_code, provider_reference, amount, status
  FROM ph19_payment.payment_transaction
  WHERE tenant_id = :tenant AND provider_id = :provider
    AND NOT is_test AND NOT is_shadow
    AND ( (paid_at >= :dayStartUtc AND paid_at < :dayEndUtc AND status IN ('SUCCEEDED','PARTIALLY_REFUNDED','REFUNDED'))
       OR (needs_reconciliation AND created_at >= :dayStartUtc AND created_at < :dayEndUtc) )
),
pv AS (SELECT * FROM ph19_payment.recon_provider_line WHERE session_id = :session AND run_no = :run AND kind = 'PAYMENT')
SELECT dh.id AS txn_id, pv.id AS line_id,
       CASE
         WHEN pv.id IS NULL THEN 'MISSING_PROVIDER'
         WHEN dh.id IS NULL THEN 'MISSING_DH'
         WHEN dh.amount <> pv.amount THEN 'AMOUNT_MISMATCH'
         WHEN (dh.status IN ('SUCCEEDED','PARTIALLY_REFUNDED','REFUNDED')) <> (pv.outcome = 'SUCCEEDED') THEN 'STATUS_MISMATCH'
         ELSE 'MATCHED' END AS result
FROM dh FULL OUTER JOIN pv
  ON pv.provider_reference = dh.provider_reference
  OR (pv.provider_reference IS NULL AND pv.transaction_code = dh.transaction_code);
```

Trùng tham chiếu phía NCC được phát hiện trước bằng `GROUP BY provider_reference HAVING count(*) > 1` (loại `DUPLICATE`). Phía hoàn tiền so tương tự trên `refund_request` `SUCCEEDED` với `completed_at` trong ngày. Kết quả ghi `reconciliation_item` theo lô 5.000 bằng `COPY`; chênh lệch mới được tạo, chênh lệch cũ đã khớp được đóng `AUTO_MATCHED` (FR-19-044 bước 4). 100.000 dòng mỗi phía ≤ 10 phút (NFR-19-008): truy vấn chạy trên chỉ mục `(tenant_id, provider_id, paid_at)` của phân vùng tháng và chỉ mục `(session_id, run_no, provider_reference)` của bảng tạm.

### 11.3. Chênh lệch và xử lý

`DiscrepancyService` hiện thực máy trạng thái khung §7.7; ghi chú là bảng `discrepancy_note` chỉ-ghi-thêm. `ResolutionExecutor` thực thi cách xử lý đã duyệt theo bảng FR-19-046, luôn kiểm tra `version` của giao dịch bằng với giá trị ghi lúc đề xuất. Cách `ACCEPT_PROVIDER_FIGURE` ghi bản ghi bù `transaction_adjustment` (`transaction_id`, `kind`, `amount_delta`, `discrepancy_id`), không sửa số tiền gốc (BR-19-030).

### 11.4. Chốt và biên bản

`MinutesGenerator` sinh XLSX bằng Apache POI (luồng SXSSF) và PDF bằng OpenPDF theo mẫu thể thức NĐ 30/2020 (phông Times New Roman nhúng, khổ A4), tính SHA-256 của PDF, in mã băm ở chân trang, tải lên bucket WORM `dh-{tenant}-payment-worm` (Ceph RGW Object Lock chế độ `COMPLIANCE`, `RetainUntilDate` = ngày chốt + `19.retention.transaction-years`). Phiên chỉ chuyển `CLOSED` sau khi biên bản đã lưu thành công; với phiên lớn, việc sinh chạy bằng `background_job` loại `RECON_MINUTES` và phiên ở trạng thái con `CLOSING` (cột `closing_job_id`) cho tới khi xong.

### 11.5. Mở lại

Mở lại tạo `approval_request` loại `RECON_REOPEN`; khi duyệt, `run_no + 1`, phiên `IN_REVIEW`, chạy lại so khớp; biên bản cũ giữ nguyên trong WORM, biên bản mới tham chiếu `supersedes_file_id`.

### 11.6. Lưu tệp

| Bucket | Hệ lưu trữ | Nội dung | Khóa đối tượng | Giữ |
|---|---|---|---|---|
| `dh-{tenant}-payment` | Garage | Tệp đối soát gốc, tệp đính kèm, chứng từ hoàn, kết quả xuất | `{purpose}/{yyyy}/{MM}/{fileId}` | Đính kèm, chứng từ: theo đối tượng; xuất: 7 ngày |
| `dh-{tenant}-payment-worm` | Ceph RGW Object Lock | Biên bản đối soát, bản sao tệp đối soát gốc của phiên đã chốt | `recon/{providerCode}/{businessDate}/{runNo}/…` | ≥ 10 năm (NFR-19-014) |

## 12. Phê duyệt bốn mắt (ADR-046)

### 12.1. Mô hình

`approval_request` (EN-19-16): `approval_type`, `target_type`, `target_id`, `requested_by`, `requested_at`, `required_approvals` (1 hoặc 2), `first_approver_id`, `first_decided_at`, `second_approver_id`, `second_decided_at`, `status` (`PENDING`, `APPROVED`, `REJECTED`, `WITHDRAWN`, `EXPIRED`), `snapshot` (T-JSON, ảnh chụp bằng chứng lúc lập), `expires_at` (lập + 7 ngày), `version`. Các loại: `PROVIDER_ACTIVATE`, `PROVIDER_RETIRE`, `PARTNER_ONBOARD`, `PARTNER_TERMINATE`, `REFUND`, `DISCREPANCY_RESOLUTION`, `RECON_REOPEN`, `ROUTING_MODE_CHANGE`, `RESULT_MAPPING_CHANGE` (đề xuất).

### 12.2. Quyền và tách nhiệm theo loại

| Loại | Quyền lập | Quyền quyết định | Tách nhiệm bổ sung |
|---|---|---|---|
| `PROVIDER_ACTIVATE`, `PROVIDER_RETIRE` | `provider-write`, `provider-delete` | `provider-activate` | — |
| `PARTNER_ONBOARD`, `PARTNER_TERMINATE` | `partner-write` | `partner-approve` | — |
| `REFUND` | `refund-create`, `partner-refund-create` | `refund-approve` | Cấp 2 ≠ cấp 1; người xác nhận chứng từ ∉ người duyệt |
| `DISCREPANCY_RESOLUTION` | `discrepancy-handle` | `discrepancy-approve` | Nếu tạo hoàn: người duyệt hoàn ≠ người duyệt chênh lệch |
| `RECON_REOPEN` | `recon-close` | `recon-reopen-approve` | ≠ người đã chốt phiên |
| `ROUTING_MODE_CHANGE` | `migration-switch` | `migration-switch` | — |
| `RESULT_MAPPING_CHANGE` | `provider-write` | `provider-activate` | — |

Mọi loại: người quyết định ≠ `requested_by` (BR-19-011). `FourEyesGuard.check(type, request, actor)` hiện thực bảng trên; CSDL có `CHECK (first_approver_id IS DISTINCT FROM requested_by AND second_approver_id IS DISTINCT FROM requested_by AND second_approver_id IS DISTINCT FROM first_approver_id)` và chỉ mục duy nhất một phần cho mỗi đối tượng chỉ có một đề nghị `PENDING` cùng loại.

### 12.3. Quyết định

`ApprovalService.decide(id, decision, note, ifMatch)`: khóa hàng đề nghị, kiểm tra `PENDING` (ERR-19-034), ETag (ERR-19-045), quyền theo loại (ERR-19-046), tách nhiệm (ERR-19-033); ghi cấp quyết định; phát `ApprovalDecided(type, targetId, level, decision)` đồng bộ để module chủ đối tượng kiểm tra lại điều kiện nghiệp vụ và áp thay đổi **trong cùng giao dịch CSDL**; nếu module chủ từ chối (điều kiện không còn đúng), toàn bộ giao dịch quay lui và người duyệt nhận mã lỗi của module (ví dụ ERR-19-035). `ApprovalExpiryJob` mỗi 10 phút chuyển đề nghị quá hạn sang `EXPIRED` và phát `ApprovalDecided(EXPIRED)`.

## 13. Di trú và strangler (ADR-049)

### 13.1. Nhập dữ liệu

`LegacyReader` có hai hiện thực: `JdbcLegacyReader` (kết nối chỉ đọc khai báo ở PH-05, Q359) và `CsvLegacyReader` (mẫu tệp ở D06-01). `ImportRunner` đọc theo khóa tăng dần, lô 10.000, mỗi lô một giao dịch CSDL; `LegacyStatusMapper` theo khung §7.4; `legacy_mapping (tenant_id, legacy_table, legacy_id) UNIQUE` bảo đảm chạy lại cập nhật thay vì chèn trùng. Giao dịch nhập có `is_migrated = true`, `TransitionSource.MIGRATION`, không ghi outbox nghiệp vụ (chỉ ghi kiểm toán tổng hợp của lần chạy).

### 13.2. Chế độ định tuyến

PH-03 giữ bảng tuyến theo đối tác: `LEGACY` → upstream hệ cũ; `SHADOW` → upstream hệ cũ, plugin `proxy-mirror` nhân bản yêu cầu tạo giao dịch sang `dh-payment` với tiêu đề `X-Datahub-Shadow: 1`; `DATAHUB` → `dh-payment`. PH-03 cập nhật tuyến khi nhận EVT-19-04 (≤ 60 giây). Callback của PayGov (một địa chỉ đăng ký, A-19-07) được PH-03 định tuyến theo tiền tố mã giao dịch: mã theo mẫu BR-19-002 đi Datahub, còn lại đi hệ cũ.

### 13.3. Đối chiếu

`ShadowComparer` ghép giao dịch bóng với giao dịch hệ cũ theo (`legacyAppCode` của đối tác, `partnerOrderId`, số tiền) trong cửa sổ ±1 ngày; `HistoricalComparer` so tổng theo tháng và theo đối tác qua `legacy_mapping`. Kết quả ghi `background_job.result` (T-JSON) và tệp CSV bản ghi lệch; `PASSED` khi đạt ngưỡng BR-19-034.

## 14. Xử lý lỗi, chịu lỗi và nhất quán

| Tình huống | Hành vi | Bảo đảm |
|---|---|---|
| Pod `api` chết sau tx1, trước khi gọi PayGov | Giao dịch `CREATED` không có tham chiếu; truy vấn bù sau 2 phút; PayGov "không tồn tại" → giao dịch vẫn mở tới hạn rồi `EXPIRED` | Không mất, không trùng (đối tác gửi lại cùng khóa nhận cùng giao dịch) |
| Pod chết sau khi PayGov khởi tạo, trước tx2 | Truy vấn bù tìm thấy giao dịch ở PayGov → `PENDING` hoặc kết quả cuối | Không trùng |
| PayGov chậm, timeout | `init_uncertain`, ERR-19-019 cho đối tác | Không báo sai "thất bại" |
| `pg-payment` chuyển nút chính | CNPG tự chuyển trong ≤ 30 giây; ứng dụng thử lại giao dịch CSDL bị hủy (tối đa 3 lần, chỉ với thao tác lũy đẳng); API trả 503 trong lúc chuyển | RPO = 0 (đồng bộ) |
| Valkey ngừng | Lũy đẳng rơi về PostgreSQL; hạn mức rơi về bảng; nonce rơi về ràng buộc duy nhất | Chậm hơn, vẫn đúng |
| Kafka ngừng | Outbox tích lũy; webhook vẫn gửi; cảnh báo tồn đọng | Không mất sự kiện |
| OpenBao ngừng | Bí mật đệm trong bộ nhớ (≤ 1 giờ) tiếp tục dùng; ký qua transit thất bại → khởi tạo trả ERR-19-017 cho NCC đó | Không dùng khóa sai |
| PH-07 ngừng | Mã danh mục đệm; thao tác ghi cần kiểm tra mới bị chặn ERR-19-039 | Đường thu tiền không bị ảnh hưởng |
| Đồng hồ lệch | NTP; kiểm tra lệch ±5 phút của IPN dựa trên đồng hồ đã đồng bộ | NFR-19-028 |

Mọi lỗi trả RFC 9457 `application/problem+json` với `type = https://datahub.gov.vn/errors/ERR-19-nnn`, `code`, `title` tiếng Việt, `detail` không lộ nội bộ, `traceId`, `errors[]` cho lỗi trường (D03-04-PH19 §6).

## 15. Cấu hình, quan sát, dung lượng

### 15.1. Cấu hình ứng dụng

| Khóa (`application.yaml`) | Mặc định | Ghi chú |
|---|---|---|
| `dh.payment.role` | `api` | `api`, `callback`, `worker` |
| `dh.payment.datasource.primary.url` | `jdbc:postgresql://pg-payment-rw:5432/datahub` | |
| `dh.payment.datasource.replica.url` | `jdbc:postgresql://pg-payment-ro:5432/datahub` | |
| `dh.payment.provider.bulkhead.max-concurrent` | 50 | Mỗi NCC mỗi pod |
| `dh.payment.provider.timeout.initiate` | `PT10S` | |
| `dh.payment.inbox.batch-size` | 100 | |
| `dh.payment.outbox.relay.enabled` | `false` | `true` khi không có Debezium |
| `dh.payment.webhook.max-in-flight-per-endpoint` | 4 | Thứ tự theo giao dịch vẫn giữ |
| `dh.payment.export.max-concurrent-per-user` | 3 | FR-19-052 |

Tham số nghiệp vụ theo tenant (`19.*`) nằm ở `tenant_payment_config` (FRS §7.1), đọc qua `TenantPaymentConfigService` có đệm 60 giây và làm mới khi có sự kiện phiên bản mới.

### 15.2. Quan sát

Chỉ số theo FRS FR-19-059; vết OpenTelemetry với span cho mỗi lời gọi NCC (`payment.provider.initiate` với thuộc tính `provider.code`, `outcome`, không có dữ liệu cá nhân), mỗi lần xử lý inbox, mỗi lượt webhook; log JSON có `trace_id`, `tenant_id`, `transaction_code` (không có dữ liệu người nộp). Bảng điều khiển Grafana "PH-19 Thanh toán" gồm: giao dịch theo trạng thái, độ trễ NCC, tồn đọng inbox/outbox/webhook, mạch, chênh lệch mở, tuổi giao dịch treo.

### 15.3. Dung lượng ước tính (QM-VUA, giả định A-19-19)

| Bảng | Dòng mỗi năm | Kích thước một dòng | Mỗi năm | Ghi chú |
|---|---|---|---|---|
| `payment_transaction` | 7,3 triệu | ~1,2 KB (gồm mã hóa) | ~9 GB | Phân vùng tháng |
| `transaction_event` | ~22 triệu | ~0,3 KB | ~7 GB | |
| `callback_inbox` | ~8,5 triệu | ~2 KB | ~17 GB | Nguyên văn |
| `integration_log` | ~30 triệu | ~3 KB | ~90 GB | Online 12 tháng rồi nén ra kho đối tượng |
| `reconciliation_item` | ~7,3 triệu | ~0,3 KB | ~2,2 GB | |
| `webhook_delivery` | ~8 triệu | ~0,5 KB | ~4 GB | |

Tổng trực tuyến năm đầu khoảng 130 GB cộng chỉ mục (~40%), phù hợp định cỡ Q340 (`pg-iam` cộng 100 GB) cho năm đầu; từ năm thứ hai cần tăng theo D03-09 §8 hoặc rút ngắn thời gian nhật ký tích hợp trực tuyến (câu hỏi OQ-19-27).

## 16. Kiểm thử

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | `TransactionStateMachine` (mọi cặp trạng thái × nguồn), `ResultMapper`, `PaymentValidator` 15 bước, `FourEyesGuard`, `Redactor`, `Money` | JUnit 5, jqwik |
| Kiến trúc | Modulith `verify()`, ArchUnit (không `double` trong tiền, adapter chỉ dùng `spi`) | Spring Modulith, ArchUnit |
| Tích hợp | Repository, RLS (`TenantIsolationIT`), outbox, inbox với PostgreSQL thật | Testcontainers PostgreSQL 18, Valkey, Kafka |
| Hợp đồng | OpenAPI ba nhóm, AsyncAPI; ví dụ trong D03-04-PH19 chạy như ca kiểm thử | Spring Cloud Contract hoặc Schemathesis |
| Adapter | Bộ giả lập PayGov (WireMock + kịch bản) tái hiện khởi tạo, IPN lặp, IPN sai chữ ký, truy vấn, đối soát (NFR-19-032) | WireMock |
| Đồng thời | 1.000 yêu cầu cùng khóa, 1.000 IPN trùng song song (AC-19-04) | k6, JUnit `@RepeatedTest` song song |
| Hiệu năng | 200 giao dịch/giây 15 phút (NFR-19-002), đối soát 100.000 dòng | k6, Gatling |
| Chịu lỗi | Tắt Valkey, Kafka, chuyển nút `pg-payment`, tắt control plane (AC-19-13) | Chaos Mesh |
| An toàn | ZAP quét API, kiểm thử SSRF webhook, giả mạo IPN | OWASP ZAP, ca D05-02-PH19 |

Ca kiểm thử chi tiết ở D05-02-PH19 (TS-19-01…34).

## 17. Lộ trình hiện thực và MVP

| Bước | Nội dung | FR | Điều kiện xong |
|---|---|---|---|
| 1 | Khung DU, schema, RLS, `TenantSession`, outbox, kiểm toán, mock adapter | FR-19-053, 061, 064 | `TenantIsolationIT` xanh |
| 2 | NCC, thông tin xác thực, kiểm tra kết nối, giao dịch thử, kích hoạt, bảng ánh xạ | FR-19-001…011, 069 | Kích hoạt NCC mock qua bốn mắt |
| 3 | Dịch vụ, đối tác, client, hạn mức, webhook | FR-19-013…021 | Đối tác gửi thử webhook thành công |
| 4 | Tạo giao dịch, lũy đẳng, chống trùng, callback, inbox, truy vấn bù, hết hạn, webhook | FR-19-022…025, 027…031, 033…036, 060, 062 | AC-19-02 với mock; AC-19-03, 04, 05 |
| 5 | Adapter PayGov theo tài liệu VPCP | FR-19-024, 029 | Giao dịch thử thật với PayGov môi trường thử |
| 6 | Hoàn tiền thủ công, đối soát tải tệp, chênh lệch, chốt, biên bản | FR-19-038…048 | AC-19-07 |
| 7 | Tra cứu, chi tiết, nhật ký, dashboard, chỉ số | FR-19-049…051, 054…057, 059 | Màn UI-19-01, 02, 14, 15 |
| 8 | Cấu hình tenant, di trú, chạy bóng, chuyển chế độ | FR-19-063, 065, 066, 068 | AC-19-11 |
| Đ2b | Xoay khóa có chuyển tiếp, hủy chủ động, xử lý lại IPN, đồng bộ thủ công, hoàn qua API, xuất danh sách, báo cáo, API đối soát cho đối tác | FR-19-012, 026, 032 (phần), 037, 040 (phần), 048 (phần), 052, 058 | — |

## 18. Câu hỏi mở

| Mã | Câu hỏi | Ảnh hưởng | Phương án đang dùng |
|---|---|---|---|
| OQ-19-27 | Nhật ký tích hợp trực tuyến 12 tháng (NFR-19-015) làm `pg-payment` vượt định cỡ Q340 từ năm thứ hai; có chấp nhận rút còn 6 tháng trực tuyến cộng bản nén ở kho đối tượng không | §15.3, D03-09 | Giữ 12 tháng, theo dõi dung lượng, đề xuất lại khi đạt 70% |
| OQ-19-28 | PayGov có chấp nhận chữ ký do OpenBao transit tạo (định dạng ASN.1 DER hay thô) không | §9.4 | Thiết kế dùng transit; dự phòng `kv` với khóa trong bộ nhớ có hạn |
| OQ-19-29 | Cụm có Debezium ở QM-NHO không | §6.4 | `OutboxRelay` quét theo lô |

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 26/11/2026 | Bản đầu: kiến trúc DU ba vai trò, cổng NCC và adapter PayGov giả định, giao dịch, lũy đẳng, inbox, outbox, webhook, bảng ánh xạ mã mặc định, phía đọc, bảo mật, hoàn tiền, đối soát, phê duyệt, di trú, chịu lỗi, dung lượng, kiểm thử, lộ trình | Nhóm phân hệ PH-19 |
