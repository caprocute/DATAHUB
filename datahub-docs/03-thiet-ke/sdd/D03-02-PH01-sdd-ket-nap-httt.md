---
ma_tai_lieu: D03-02-PH01
ten: Thiết kế chi tiết phần mềm phân hệ PH-01 Kết nạp hệ thống thông tin
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, kiến trúc sư, ATTT, vận hành, hội đồng thẩm định
phan_he: PH-01
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Kết nạp hệ thống thông tin gồm thành phần, cấu trúc mã, trình tự các luồng chính, máy trạng thái, xử lý lỗi, cấu hình, mở rộng và bảo mật, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH01 FRS; D02-04-PH01 Use case; D03-03-PH01 CSDL; D03-04-PH01 API; D03-07 ATTT; D03-10 Đa tenant; D04-01 Quy ước mã
---

# D03-02-PH01 · Thiết kế chi tiết Kết nạp hệ thống thông tin

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 51 FR của [D02-03-PH01](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) và 34 use case của [D02-04-PH01](../../02-yeu-cau/use-case/D02-04-PH01-use-case-ket-nap-httt.md). PH-01 là module `onboarding` của đơn vị triển khai `dh-connect` (Java 21, Spring Boot 4, Spring Modulith), chạy ở mặt phẳng điều khiển, vùng Z3, lưu dữ liệu ở schema `ph01_onboarding` của cụm `pg-core`. Phân hệ không nằm trên đường dữ liệu: khi `dh-connect` ngừng, HTTT đã kết nạp vẫn gọi API bình thường vì định danh đã ở PH-12 và consumer đã ở APISIX (NFR-01-007). Thiết kế dựa trên năm quyết định:

1. **Máy trạng thái trong mã, một bảng chuyển duy nhất.** Vòng đời HTTT (bảy trạng thái của DD-03), định danh, bàn giao, kỳ rà soát đều là enum cộng bảng chuyển khai báo một lần; mỗi chuyển ghi lịch sử, kiểm toán và sự kiện outbox trong cùng giao dịch (ADR-058, ADR-042, BR-01-031). MVP không phụ thuộc Flowable, nhưng bảng chuyển đặt sau một giao diện để nâng lên chế độ quy trình nhiều cấp mà không đổi dữ liệu lưu; đã chốt 27/11/2026 (Q01-14): PH-01 tự điều phối việc duyệt ở MVP, tích hợp quy trình `DUYET_KET_NAP_HTTT` của PH-11 (API-11-049, EVT-11-05, 06) ở Đợt 2.
2. **Bí mật không đi qua PH-01.** PH-12 ghi bí mật client vào OpenBao; chính sách của `dh-connect` chỉ cho đọc kèm bọc bắt buộc, nên mã của PH-01 không thể đọc giá trị bí mật ở dạng rõ ngoài lần mở bàn giao. CSDL chỉ có `secret_ref`, dấu vân tay và giá trị băm (BR-01-005, 006, 007; SEC-33).
3. **Saga cấp định danh bền trong CSDL.** Trạng thái saga và từng bước nằm trong bảng của PH-01, bộ chạy lấy việc bằng `FOR UPDATE SKIP LOCKED`, mọi lệnh gọi PH-12 và PH-03 mang `sagaId` làm khóa lũy đẳng, bù trừ theo thứ tự ngược. `dh-connect` khởi động lại giữa chừng không làm mất tiến trình (FR-01-020, NFR-01-004).
4. **Cắt quyền chặn ở cổng trước.** Tạm ngừng, thu hồi, thao tác khẩn đặt trạng thái và đẩy client vào danh sách chặn của APISIX trước, rồi mới gọi PH-12 vô hiệu client, thu hồi token, gọi PH-03 vô hiệu consumer; bước nào chưa xong thì thử lại tới khi xong và cảnh báo, không bao giờ hoàn tác trạng thái (BR-01-023, NFR-01-008).
5. **Quyền theo dòng, không theo hồ sơ.** Kết luận thẩm định ghi cho từng mục nhu cầu khai thác; trần phạm vi sinh từ các mục được chấp thuận và là giới hạn trên của scope định danh, mọi kiểm tra bốn mắt và đặc quyền tối thiểu chốt ở máy chủ trong aggregate, không ở giao diện (BR-01-003, 017).

Phân hệ thêm 15 thành phần có bảng đặc tả 10 mục, 7 sơ đồ trình tự cho luồng phức tạp, 11 máy trạng thái có bảng chuyển và 30 tham số theo tenant. Tài liệu không thêm ADR; ba đề xuất ADR ghi ở mục "Đề nghị đồng bộ". Mười câu hỏi mở (Q01-20…29) chủ yếu là giao diện API chưa chốt với PH-12, PH-03 và cách OpenBao hiện thực việc bọc bắt buộc.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| FR hiện thực | 51 (M: 41, S: 9, C: 1), UC 34 |
| Thành phần có bảng đặc tả | 15 (chương 4), 1 mô hình miền |
| Sơ đồ trình tự | 7 (chương 5) |
| Máy trạng thái | 11 (chương 8) |
| API, sự kiện, mã lỗi | 88 · 15 · 54 (định nghĩa ở FRS §9, D03-04-PH01) |
| NFR ràng buộc thiết kế | NFR-01-004, 007, 008, 009, 010, 012, 021 |
| Tham số, cờ tính năng | 30 khóa `onboarding.*` · 7 cờ |
| Câu hỏi mở | 10 (Q01-20…29) |

: Con số chính của SDD PH-01

## 1. Giới thiệu

### 1.1. Mục đích, phạm vi và cách đọc

Tài liệu đi từ vị trí trong kiến trúc (chương 2), cấu trúc mã (chương 3), từng thành phần (chương 4), sơ đồ trình tự của các FR phức tạp (chương 5) tới đa tenant, bảo mật, máy trạng thái và xử lý lỗi, cấu hình, quan sát, hiệu năng và kiểm thử. Quy tắc nghiệp vụ `BR-01-*`, yêu cầu phi chức năng `NFR-01-*`, mã lỗi `ERR-01-*` và tham số `onboarding.*` là của FRS; mã `EVT-01-*`, `API-01-*` định nghĩa ở D03-04-PH01; bảng CSDL ở D03-03-PH01 (tên bảng trong tài liệu này là đề xuất của SDD, bản chốt ở tập CSDL). Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới.

Phạm vi thiết kế gồm: hồ sơ HTTT và đầu mối, kiểm tra và nộp, thẩm định, phê duyệt, saga cấp định danh, bàn giao một lần, kiểm thử SANDBOX và kích hoạt, xoay vòng, thu hồi, vòng đời thành viên, cắt quyền, đồng bộ trạng thái, rà soát quyền định kỳ, danh bạ đầu mối, nhập hệ cũ, tham số và thống kê. Không thuộc phạm vi: tạo client OAuth (PH-12), consumer và hạn mức (PH-03), đăng ký sử dụng API (PH-02), kho nhật ký kiểm toán (PH-13), danh mục tổ chức và khởi tạo tenant (PH-20).

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4 + Modulith cho `dh-connect`, module `onboarding` |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` trên mọi bảng `ph01_onboarding` |
| ADR-004 | Kafka cho sự kiện trạng thái EVT-01-* |
| ADR-006 | Keycloak (xác thực, `acr` cho xác thực lại hai yếu tố) và OPA (ủy quyền theo phân công) |
| ADR-007, ADR-058 | Quy trình ngắn dùng máy trạng thái trong mã; Flowable chỉ khi cần nhiều cấp (Q01-14) |
| ADR-008 | Garage lưu tài liệu đính kèm, mỗi tenant một bucket |
| ADR-012 | OpenBao: bí mật client, bọc phản hồi, PKI ký CSR, khóa transit |
| ADR-013 | Control plane tách data plane: PH-01 không nằm trên đường gọi API |
| ADR-031 | Nhật ký kiểm toán chỉ-thêm, WORM 5 năm |
| ADR-032 | Mã hóa envelope qua OpenBao transit cho mã bọc của bàn giao (mục 4.7) |
| ADR-041 | Idempotency: `Idempotency-Key` cho API ghi, `sagaId` cho lệnh sang PH-12, PH-03 |
| ADR-042 | Outbox cùng giao dịch, phát qua Debezium |
| ADR-056 | Nhập tệp hai pha (xem trước rồi ghi tất cả hoặc không) cho nhập hệ cũ |

: ADR áp dụng cho PH-01

### 1.2. Người đọc, thuật ngữ và tài liệu tham chiếu

Bảng dưới cho biết mỗi nhóm người đọc nên đọc phần nào; thuật ngữ và tài liệu tham chiếu nằm ngay sau bảng.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` | Chương 3, 4, 6, 8, 9 |
| Kỹ sư tích hợp PH-12, PH-03, PH-02 | Mục 4.6, 4.7, 4.10, 4.11, chương 5, mục 8.3 |
| ATTT | Mục 4.7, 4.8, 4.10, chương 7 |
| Vận hành | Chương 9, 10, 11 |
| Kiểm thử viên | Chương 5, 8, 12 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 7 |

: Người đọc và phần cần đọc

Thuật ngữ và chữ viết tắt dùng chung với [D02-03-PH01](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) §1.4 và D00-01. Thuật ngữ riêng của SDD: **cổng tích hợp** (port) là giao diện Java do PH-01 định nghĩa để gọi hệ khác, **bộ chuyển** (adapter) là lớp hiện thực cổng đó bằng REST hoặc gọi trong tiến trình; **bước saga** là một lệnh gọi ra ngoài có thao tác bù trừ. Mỗi thành phần ở chương 4 mở đầu bằng bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế. Tài liệu nguồn: D03-01 SAD §4, §7.3; D03-07 (SEC); D03-10 §3; D02-08 (PERM-01-*).

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

Bảng dưới trình bày đơn vị triển khai và vùng mạng.

| Thành phần | DU | Vùng | Ghi chú |
|---|---|---|---|
| Module `onboarding` (API, nghiệp vụ, saga, bộ cắt quyền, tác vụ định kỳ) | `dh-connect` | Z3 | Chung DU với module của PH-02, phần control của PH-03, PH-15; hai bản sao ở `QM-VUA`, tầng phục hồi `TPH-1` |
| `pg-core`, schema `ph01_onboarding` | Nền tảng | Z5 | Cụm CNPG chung control plane; RLS theo `tenant_id` |
| OpenBao | Nền tảng | Z6 | KV v2 `kv/dh/{tenant}/clients/*`, PKI `pki-clients`, transit `dh-{tenant}-pii`, `dh-{tenant}-handover` |
| Keycloak, OPA (PH-12) | `keycloak`, `opa` | Z6 | Realm theo tenant; OPA là sidecar trong pod `dh-connect` |
| APISIX (PH-03) | `apisix` | Z1, Z2 | Danh sách chặn, consumer; vẫn phục vụ bằng cấu hình đã nạp khi `dh-connect` ngừng |
| Kafka và Debezium | `kafka`, Kafka Connect | Z5 | Outbox của `ph01_onboarding` phát lên `{tenant}.connect.*` |
| Garage | Nền tảng | Z5 | Bucket tài liệu đính kèm theo tenant |
| Dịch vụ quét mã độc | Nền tảng | Z5 | Quét tệp trước khi nhận (SEC-45) |

: Đơn vị triển khai và vùng mạng của PH-01

Mọi lưu lượng ra khỏi `dh-connect` tới PH-12, PH-03, OpenBao, Garage, dịch vụ quét là lưu lượng đông–tây trong cụm, đi qua mTLS của mesh và `NetworkPolicy` từ chối mặc định (SEC-14, SEC-15). PH-01 không có đường ra Internet; thư thông báo đi qua PH-18.

### 2.2. Sơ đồ thành phần

Sơ đồ dưới mô tả sơ đồ thành phần.

```{.mermaid caption="Sơ đồ thành phần PH-01 trong dh-connect"}
flowchart TB
  subgraph DC["dh-connect · module onboarding"]
    WEB["web<br/>REST /api/onboarding/v1"]
    SYS["system<br/>MemberSystem, TechnicalProfile, DataDemand"]
    CTC["contact<br/>Contact, DirectoryService"]
    ATT["attachment<br/>AttachmentService"]
    SUB["submission<br/>SubmissionValidator"]
    REV["review<br/>ReviewService, ScopeCeilingFactory"]
    LIF["lifecycle<br/>MemberStateMachine, EmergencyService"]
    ENF["enforcement<br/>EnforcementService"]
    PRV["provisioning<br/>ProvisioningSaga"]
    HND["handover<br/>HandoverService"]
    CRD["credential<br/>CredentialService, RotationService"]
    ACR["accessreview<br/>AccessReviewService"]
    LEG["legacy<br/>LegacyImportService"]
    REP["replica<br/>ReplicaService, Reconciler"]
    PORT["integration<br/>Ph12Port, Ph03Port, OpenBaoPort,<br/>Ph13Port, Ph02Port, Ph20Port, NotifyPort"]
    OBX["events<br/>OutboxPublisher"]
    SCH["scheduler<br/>ShedLock jobs"]
    WEB --> SYS & CTC & ATT & SUB & REV & LIF & PRV & HND & CRD & ACR & LEG & REP
    SUB --> SYS
    REV --> SYS
    LIF --> ENF
    PRV --> PORT
    HND --> PORT
    CRD --> PORT
    ENF --> PORT
    SCH --> CRD & ACR & ENF & REP & CTC
    SYS & REV & LIF & PRV & CRD & ACR --> OBX
  end
  UI["dh-console BFF<br/>UI-01-01…17"] --> WEB
  PORT -->|"REST, sagaId"| P12["PH-12<br/>Keycloak, OPA"]
  PORT -->|"gọi trong tiến trình<br/>hoặc REST"| P3["PH-03<br/>consumer, danh sách chặn"]
  PORT -->|"bọc, mở, hủy, ký CSR"| OB[("OpenBao")]
  PORT --> P13["PH-13 · PH-14 · PH-18 · PH-20 · PH-02"]
  ATT --> GR[("Garage")]
  DC --> PG[("pg-core<br/>ph01_onboarding")]
  OBX --> KF[("Kafka")]
  KF --> CONS["PH-02, PH-03, PH-04,<br/>PH-05, PH-10, PH-13"]
```

Sơ đồ cho thấy ba điểm. Thứ nhất, mọi lời gọi ra ngoài đi qua lớp `integration` gồm các cổng tích hợp, nên toàn bộ thời gian chờ, thử lại, ngắt mạch đặt ở một nơi (mục 8.3) và kiểm thử thay bằng bản giả được. Thứ hai, các thành phần nghiệp vụ không gọi nhau tùy tiện: `lifecycle` chỉ gọi `enforcement` để cắt quyền, `review` chỉ đọc `system`, và mọi thay đổi trạng thái đều đi về `events` (outbox). Thứ ba, bí mật không có mũi tên nào đi vào `pg-core`: đường của bí mật chỉ nối `integration` với OpenBao.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng dưới trình bày phụ thuộc với module và phân hệ khác.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| PH-12 (Keycloak, OPA) | PH-01 gọi | REST, token dịch vụ của `dh-connect`, `Idempotency-Key = sagaId` | Tạo, vô hiệu client; thu hồi token; đăng ký khóa; xoay bí mật (Q01-03, Q01-20) |
| PH-03 (phần control) | PH-01 gọi | `ConsumerGatewayApi` trong tiến trình (cùng DU), bộ chuyển REST dự phòng | Consumer, hạn mức, danh sách chặn |
| PH-02 (cùng DU) | hai chiều | PH-01 công bố `MemberSystemQueryApi` (gói `onboarding.api`); PH-01 gọi `ServiceUsageApi` | PH-02 kiểm HTTT `ACTIVE` và trần phạm vi; PH-01 lấy API đang dùng, phụ thuộc |
| PH-13 | PH-01 gọi, PH-13 nhận | REST đọc mức dùng; sự kiện kiểm toán qua outbox | Mức dùng định danh, kết quả kiểm thử SANDBOX |
| PH-14 | PH-01 gọi | REST | Hạn mức dữ liệu quốc gia còn lại (FR-01-015) |
| PH-18 | PH-01 gọi | `NotificationApi`, `ParameterApi` có đệm 60 giây, lịch nghỉ | Thư, thông báo, tham số `onboarding.*` |
| PH-20 | PH-01 gọi, nhận sự kiện | REST có đệm 24 giờ; sự kiện tenant tạm ngừng | Danh mục tổ chức, trạng thái tenant |
| PH-04, PH-05, PH-10 | PH-01 phát | EVT-01-03, 04 và API nội bộ `/internal/systems` | Bản sao HTTT, tạm ngừng bên phát, bên nhận |
| Hộp việc chung (FR-00-070) | PH-01 gửi | `TaskInboxApi` | Việc thẩm định, duyệt, rà soát |
| Danh mục loại dữ liệu (PH-07 hoặc PH-09) | PH-01 đọc | `ReferenceDataApi` có đệm | Chọn `dataType` (Q01-16) |

: Phụ thuộc với module và phân hệ khác

Luật Modulith của `dh-connect`: `onboarding` chỉ import `shared` (hạt nhân dùng chung: `TenantContext`, `dh-audit`, `dh-crypto`, thư viện outbox), `catalog.api` (PH-02) và `gateway.api` (PH-03); không import `*.internal` của module khác. Module khác chỉ import `onboarding.api`. ArchUnit kiểm ở CI (CI-3). Giữa hai DU khác nhau chỉ dùng REST hoặc sự kiện, không đọc chéo CSDL (D03-01 §7.3).

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện có module `vn.lgsp.control.onboarding` trong `apps/control` (khoảng 1.100 dòng Java, một service 628 dòng), là bản thử nghiệm của SRS cũ; thiết kế này thay thế hoàn toàn thay vì mở rộng.

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| Gói `vn.lgsp.control.onboarding`, nằm trong `apps/control` | Gói `vn.datahub.connect.onboarding` trong `dh-connect` | GAP-01-01: đổi tên gói, chuyển sang DU `dh-connect`, giữ `package-info` với `allowedDependencies` mới |
| Schema `ph01`, bảng `application` 9 cột, trạng thái `SUBMITTED → REVIEWED → APPROVED → ACTIVE`, `REVOKED` | Schema `ph01_onboarding`, khoảng 24 bảng, bảy trạng thái DD-03 cộng `reviewStage`, `provisionStage`, `enforcement` | GAP-01-02: changeset di trú ở D03-03-PH01; trạng thái `REVIEWED` nhập vào `SUBMITTED` + `reviewStage`, `REVOKED` thành `TERMINATED` |
| Cột `client_secret_sealed` lưu bí mật mã hóa trong CSDL | Chỉ `secret_ref`, không cột bí mật | GAP-01-03 (vi phạm BR-01-007): xóa cột, quét CSDL xác nhận không còn giá trị |
| Route `/api/v1/onboarding/applications`, không `PERM-01-*`, không tenant | `/api/onboarding/v1/systems`, `@PreAuthorize` theo `PERM-01-*`, OPA, RLS | GAP-01-04 |
| `activate` chuyển thẳng `APPROVED → ACTIVE`, không SANDBOX, không định danh | Saga SANDBOX, kiểm thử, kích hoạt PRODUCTION có xác nhận | GAP-01-05 |
| `SelfReviewException` chỉ chặn người nộp tự thẩm định | Bốn điểm bốn mắt, phân công theo OPA, cặp loại trừ IE và IA | GAP-01-06 |
| `OutboxDispatcher` quét bảng mỗi 2 giây, chỉ ghi log | Outbox cho Debezium, bộ quét 500 ms chỉ là dự phòng `QM-NHO` | GAP-01-07 |
| `AttachmentStorage` ghi S3 tương thích, danh sách kiểu cho phép theo MIME | Giữ ý tưởng, thêm Tika kiểm kiểu theo nội dung, quét mã độc, bucket theo tenant, băm SHA-256 | GAP-01-08 |
| Bảng `external_system` (đồng bộ) ở `apps/control` | Bản sao chỉ-đọc `system_replica` ở các phân hệ nhận, dữ liệu gốc ở PH-01 | GAP-01-09 |

: Hiện trạng mã và đường chuyển

## 3. Cấu trúc mã nguồn

### 3.1. Module `onboarding` trong `dh-connect`

Gói gốc là `vn.datahub.connect.onboarding`. Gói `api` là phần duy nhất module khác được import. Gói `internal` chia theo năng lực nghiệp vụ, không chia theo tầng kỹ thuật, để một thay đổi nghiệp vụ nằm trọn trong một thư mục.

```text
vn.datahub.connect.onboarding
├── api/                       # công bố cho module khác: MemberSystemQueryApi, ScopeCeilingApi, DTO, EVT payload
├── web/                       # @RestController theo nhóm API; ProblemDetail ERR-01-*; PEP gọi OPA
│   ├── ui/                    # /api/onboarding/v1/systems, /credentials, /access-reviews, /directory …
│   └── internal/              # /api/onboarding/v1/internal/* cho token dịch vụ
├── internal/
│   ├── system/                # aggregate MemberSystem, TechnicalProfile, DataDemand; GroupAdvisor (đề xuất nhóm HTTT)
│   ├── contact/               # Contact, ContactPolicy (miền thư, ít nhất một đầu mối kỹ thuật), DirectoryService, GapDetector
│   ├── attachment/            # AttachmentService, ContentTypeSniffer (Tika), ScanClient, ObjectStorePort
│   ├── submission/            # SubmissionValidator (tập quy tắc), SubmissionService, DraftCleaner
│   ├── review/                # ReviewStep, ReviewAssignment, ReviewClock, DecisionService, QuotaImpactEvaluator, ScopeCeilingFactory
│   ├── lifecycle/             # MemberStateMachine, TransitionTable, LifecycleService, ImpactAnalyzer, EmergencyService, ChangeRequestService, ScopeExpansionService
│   ├── enforcement/           # EnforcementService, EnforcementTask, EnforcementRetryJob
│   ├── provisioning/          # ProvisioningSaga, SagaStep, SagaRunner, CompensationRunner, SagaRepository
│   ├── handover/              # HandoverService, LinkCodec, HandoverGuard, WrapTokenVault
│   ├── credential/            # AppCredential, CredentialService, KeyValidator, CsrValidator, RotationService, SandboxTestService, ActivationService, ExpiryJob, InactivityJob
│   ├── accessreview/          # AccessReviewCycle, UsageAggregator, ConfirmationService, LegalValidityChecker, ReviewReportService
│   ├── legacy/                # LegacyImportService, LegacyFileParser (không đọc cột bí mật), OrgMatcher, RoleMerger
│   ├── replica/               # ReplicaService, SnapshotPublisher, Reconciler
│   ├── settings/              # OnboardingSettings (ParameterApi, đệm 60 giây), SettingsService
│   ├── statistics/            # StatisticsService (Đợt 2), MetricsRegistrar
│   ├── scheduler/             # JobCatalog, TenantJobRunner (ShedLock, TenantContext.runAs)
│   └── integration/           # Ph12Port, Ph03Port, Ph02Port, Ph13Port, Ph14Port, Ph20Port, NotifyPort, OpenBaoPort + bộ chuyển
└── events/                    # record EVT-01-01…15, OutboxPublisher, DomainEvent
```

Quy tắc phụ thuộc trong module, kiểm bằng ArchUnit: `web` chỉ gọi service của `internal/*`, không chạm repository; `lifecycle`, `review`, `credential` không import nhau mà phối hợp qua `MemberSystem` và sự kiện trong tiến trình (`ApplicationEventPublisher`, đồng bộ trong cùng giao dịch cho phần ghi, bất đồng bộ sau commit cho phần thông báo); `integration` không import gói nghiệp vụ, chỉ dùng DTO của chính nó; không lớp nào ngoài `integration.OpenBaoPort` import client OpenBao.

### 3.2. Giao diện công bố cho module và phân hệ khác

`MemberSystemQueryApi` là bản gọi trong tiến trình của API-01-063, 064 cho PH-02 và PH-03 (cùng DU); phân hệ ở DU khác dùng REST `/internal/systems`. Hai bản trả cùng cấu trúc rút gọn, không có dữ liệu liên hệ cá nhân, không có `secret_ref` (FR-01-038).

```java
package vn.datahub.connect.onboarding.api;

public interface MemberSystemQueryApi {
  /** FR-01-038. Trả bản rút gọn; không tìm thấy hoặc khác tenant: Optional.empty() (BR-01-030). */
  Optional<MemberSystemView> find(TenantId tenant, String systemCode);
  /** Đồng bộ gia tăng cho bản sao; size tối đa 500. */
  Page<MemberSystemView> changedSince(TenantId tenant, Instant updatedSince, Set<MemberStatus> status, int page, int size);
  /** PH-02 kiểm đăng ký sử dụng không vượt trần phạm vi (BR-01-003, Q01-02). */
  CeilingCheck checkWithinCeiling(TenantId tenant, String systemCode, String dataType, Set<String> scopesRequested);
}

public record MemberSystemView(String code, String name, String ownerOrgId, MemberStatus status,
    Set<Role> roles, SecurityLevel securityLevel, Integer group, List<String> baseUrls,
    Map<Environment, List<String>> clientIds, Instant activatedAt, Instant updatedAt,
    List<String> ceilingDataTypes) {}
public record CeilingCheck(boolean within, List<String> excessScopes, String ceilingVersion) {}
```

### 3.3. Cổng tích hợp ra ngoài

Mỗi hệ ngoài PH-01 phụ thuộc có một cổng. Cổng nêu đủ điều kiện lũy đẳng để bộ chạy saga gọi lại an toàn. Lỗi được dịch về ba lớp: tạm thời (thử lại), nghiệp vụ (dừng, báo), không khả dụng (thử lại và cảnh báo).

```java
package vn.datahub.connect.onboarding.internal.integration;

public interface Ph12Port {
  /** Lũy đẳng theo sagaId. Không bao giờ trả giá trị bí mật; secretRef trỏ tới OpenBao. */
  ClientCreated createClient(TenantId t, String idempotencyKey, ClientSpec spec);
  void disableClients(TenantId t, String idempotencyKey, List<String> clientIds, DisableMode mode);
  void revokeTokens(TenantId t, String idempotencyKey, List<String> clientIds);
  void registerKey(TenantId t, String clientId, KeyMaterial publicKeyOrCert);
  RotationStarted startSecretRotation(TenantId t, String idempotencyKey, String clientId);
}

public interface Ph03Port {
  ConsumerCreated createConsumer(TenantId t, String idempotencyKey, ConsumerSpec spec);
  void deleteConsumer(TenantId t, String idempotencyKey, String consumerId);   // bù trừ
  void blockClients(TenantId t, String idempotencyKey, List<String> clientIds, String reason); // ≤ 60 giây
  void unblockClients(TenantId t, String idempotencyKey, List<String> clientIds);
  void disableConsumer(TenantId t, String idempotencyKey, String consumerId);
}

public interface OpenBaoPort {
  /** Đọc bí mật client kèm bọc bắt buộc: chỉ nhận mã bọc, không có đường đọc rõ. */
  WrapInfo wrapClientSecret(TenantId t, String secretRef, Duration wrapTtl);
  Secret unwrap(String wrapToken);                       // chỉ gọi ở HandoverService.open
  void destroyVersions(TenantId t, String secretRef);    // sau lần mở, sau kết thúc xoay vòng
  SignedCert signCsr(TenantId t, String role, String csrPem, Duration ttl);
  byte[] transitEncrypt(TenantId t, String key, byte[] plain, byte[] aad);
  byte[] transitDecrypt(TenantId t, String key, byte[] cipher, byte[] aad);
}
```

`Secret` ghi đè `toString` và được đánh dấu `@Sensitive` để bộ lọc log của thư viện nền thay giá trị bằng `***`; ArchUnit cấm log trực tiếp đối tượng này (CC-SEC trong D04-01) và cấm lớp nào ngoài `HandoverService` gọi `OpenBaoPort.unwrap`.

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình có bảy aggregate. `MemberSystem` là gốc của hồ sơ và vòng đời, kéo theo hồ sơ kỹ thuật, nhu cầu khai thác và đầu mối. `ScopeCeiling`, `AppCredential`, `ProvisioningSaga`, `AccessReviewCycle`, `EmergencyAction` và `ChangeRequest` có vòng đời riêng nên là aggregate riêng, tham chiếu `MemberSystem` bằng `systemCode`, không bằng đối tượng, để mỗi giao dịch chỉ khóa một aggregate.

```{.mermaid caption="Mô hình miền PH-01"}
classDiagram
  class MemberSystem {
    +UUID id
    +String tenantId
    +String code
    +String ownerOrgId
    +MemberStatus status
    +ReviewStage reviewStage
    +ProvisionStage provisionStage
    +Enforcement enforcement
    +int revisionNo
    +long version
    +submit(by)
    +returnForRevision(by, reason)
    +approve(by)
    +activate(by)
    +suspend(by, reason)
    +terminate(by, reason)
  }
  class TechnicalProfile {
    +boolean hasApi
    +Integer proposedGroup
    +Integer confirmedGroup
    +int maxConcurrentConnections
  }
  class DataDemand {
    +Direction direction
    +String dataType
    +Classification classification
    +LegalBasis legalBasis
    +Verdict verdict
    +String scopeApproved
  }
  class Contact {
    +ContactType type
    +String userAccountId
    +boolean isPublic
    +ContactStatus status
  }
  class ReviewStep {
    +StepType type
    +String assigneeId
    +StepResult result
    +Instant dueAt
    +long pausedMillis
    +String inputHash
  }
  class ScopeCeiling {
    +String dataType
    +String scopeApproved
    +CeilingStatus status
    +LocalDate validUntil
  }
  class AppCredential {
    +Environment environment
    +AuthMethod authMethod
    +String clientId
    +String secretRef
    +CredentialStatus status
    +Instant expiresAt
    +Instant rotationEndsAt
    +rotate(by, overlap)
    +revoke(by, reason)
  }
  class Handover {
    +String linkHash
    +String wrapAccessor
    +HandoverStatus status
    +int failedAttempts
    +Instant expiresAt
  }
  class ProvisioningSaga {
    +UUID sagaId
    +Environment environment
    +SagaState state
    +int attempt
    +Instant nextRunAt
  }
  class SagaStep {
    +StepName name
    +StepStatus status
    +String externalRef
  }
  class EmergencyAction {
    +ActionType type
    +String performedBy
    +String confirmedBy
    +Instant confirmBy
    +EmergencyStatus status
  }
  class ChangeRequest {
    +ChangeClass changeClass
    +JsonNode diff
    +String requestedBy
    +String decidedBy
  }
  class AccessReviewCycle {
    +String cycleCode
    +CycleStatus status
    +Instant openedAt
  }
  class AccessReviewItem {
    +String dataType
    +long usageInPeriod
    +Decision decision
    +OwnerResponse ownerResponse
  }
  MemberSystem "1" *-- "1" TechnicalProfile
  MemberSystem "1" *-- "*" DataDemand
  MemberSystem "1" *-- "*" Contact
  MemberSystem "1" *-- "*" ReviewStep
  MemberSystem "1" o-- "*" ScopeCeiling
  MemberSystem "1" o-- "*" AppCredential
  AppCredential "1" *-- "*" Handover
  MemberSystem "1" o-- "*" ProvisioningSaga
  ProvisioningSaga "1" *-- "*" SagaStep
  MemberSystem "1" o-- "*" EmergencyAction
  MemberSystem "1" o-- "*" ChangeRequest
  AccessReviewCycle "1" *-- "*" AccessReviewItem
  DataDemand "0..1" ..> "0..1" ScopeCeiling : sinh khi duyệt
```

Hình cho thấy ranh giới giao dịch: đường liền thể hiện sở hữu (cùng lưu, cùng khóa lạc quan), đường kim cương rỗng là tham chiếu bằng mã. `ScopeCeiling` sinh ra từ `DataDemand` có kết luận chấp thuận, nhưng sau đó sống độc lập vì rà soát quyền thu hẹp trần mà không động tới hồ sơ gốc. Invariant được kiểm trong aggregate trước khi ghi, không ở controller:

| Aggregate | Invariant | BR, ERR |
|---|---|---|
| `MemberSystem` | `code` bất biến, duy nhất trong tenant kể cả `REJECTED`, `TERMINATED` (chỉ mục duy nhất `(tenant_id, code)` không điều kiện) | BR-01-018 · ERR-01-002 |
| `MemberSystem` | Chuyển trạng thái chỉ qua `TransitionTable`; bốn mắt: người lập, nộp, thẩm định, đề nghị chấm dứt không phải người duyệt hoặc kích hoạt | BR-01-017 · ERR-01-005, 017 |
| `MemberSystem` | Nộp được chỉ khi bộ kiểm tra không còn lỗi mức ERROR; tổ chức không còn HTTT thiếu đầu mối kỹ thuật | BR-01-013 · ERR-01-008, 010 |
| `DataDemand` | Dòng `CONSUME` có đủ số, ngày, cơ quan, tệp căn cứ; `dataType` không thuộc danh mục bí mật nhà nước | BR-01-001, 004 · ERR-01-015, 016 |
| `DataDemand` | Kết luận `NARROWED` có `scopeApproved` là tập con của `scopeRequested`; hoàn tất khi mọi dòng có kết luận | BR-01-003 · ERR-01-018, 019 |
| `ReviewStep` | Người thẩm định là người được phân công và khác người lập, nộp; kết luận một lần cho mỗi vòng nộp | BR-01-017 · ERR-01-017, 020 |
| `ScopeCeiling` | `scopeApproved` không rộng hơn nhu cầu được duyệt; chỉ thu hẹp hoặc đóng, không tự mở rộng (mở rộng qua thẩm định pháp lý lại) | BR-01-003, 012 · ERR-01-037 |
| `AppCredential` | Mỗi `(systemCode, environment)` có tối đa một định danh `ACTIVE` hoặc `ROTATING`; hạn ≤ 365 ngày, chuỗi bí mật ≤ 180 ngày; không có scope dữ liệu khi mới cấp | BR-01-003, 020 · ERR-01-029, 030 |
| `AppCredential` | Phương thức xác thực không thấp hơn mức yêu cầu của phân loại cao nhất trong trần (Hạn chế: khóa công khai hoặc mTLS, Nhạy cảm: mTLS) | BR-01-019 · ERR-01-047 |
| `Handover` | Tối đa một bàn giao `PENDING` mỗi định danh; mở được đúng một lần, bởi đúng tài khoản đầu mối | BR-01-006 · ERR-01-024, 025, 026 |
| `EmergencyAction` | `confirmedBy` khác `performedBy`; quá hạn thì cảnh báo, không tự hoàn tác | BR-01-010, 017 · ERR-01-036 |
| `ChangeRequest` | Mỗi HTTT tối đa một yêu cầu `PENDING`; `decidedBy` khác `requestedBy` | BR-01-012, 025 · ERR-01-038 |
| `AccessReviewCycle` | Mỗi tenant tối đa một kỳ chưa `CLOSED` (chỉ mục duy nhất từng phần) | BR-01-014 · ERR-01-039 |
| `ProvisioningSaga` | Mỗi `(systemCode, environment)` tối đa một saga đang chạy; `sagaId` bất biến | BR-01-007, 031 · ERR-01-021, 022 |

: Invariant của các aggregate

### 4.2. Hồ sơ HTTT, hồ sơ kỹ thuật, nhu cầu khai thác và đầu mối

::: dac-ta
**Mục đích.** Cho đơn vị lập, sửa và xem hồ sơ kết nạp, tự lưu bản nháp, khai năng lực kỹ thuật (hệ thống tự đề xuất nhóm 1…4), nhu cầu khai thác kèm căn cứ pháp lý và đầu mối; cho mọi vai trò có quyền xem danh sách có bộ lọc, chi tiết và xuất.

**Lớp chính.** `MemberSystemService`, `MemberSystem`, `TechnicalProfile`, `DataDemand`, `GroupAdvisor`, `ContactService`, `ContactPolicy`, `SystemQueryRepository`, `SystemExporter`.

**Đơn vị chạy.** `dh-connect` (module `onboarding`).

**FR hiện thực.** FR-01-001, 002, 003, 004, 006, 007, 008, 009, 010, 050.

**Giao diện vào.** API-01-001…005, 010…021, 085; UC-01-01…05, 07.

**Phụ thuộc ra.** `Ph20Port` (tổ chức, đệm 24 giờ), `ReferenceDataPort` (danh mục `dataType`, nhãn bí mật nhà nước), `ParameterApi`, `AttachmentService`, `OutboxPublisher`.

**Dữ liệu.** `member_system`, `technical_profile`, `data_demand`, `contact`, `template`, `state_history`.

**Sự kiện.** EVT-01-03 (mọi chuyển trạng thái, kể cả tạo nháp), EVT-01-04 (đổi thuộc tính), EVT-01-13 (đổi đầu mối, không kèm dữ liệu liên hệ).

**Lỗi và xử lý.** ERR-01-002 (trùng mã), 003, 004, 006, 007 (`If-Match` lệch), 011, 049, 050; `Ph20Port` lỗi: dùng đệm, hết đệm thì ERR-01-046.

**Quan sát.** `onboarding_applications_total{status}`, `onboarding_members_total{status,group}`; log mức INFO cho tạo, sửa (không ghi họ tên, thư, điện thoại đầu mối).
:::

Chi tiết thiết kế:

*Sửa và tự lưu.* Giao diện gửi `PATCH` theo JSON Merge Patch mỗi 30 giây kèm `If-Match` là giá trị `version`. `MemberSystem` dùng khóa lạc quan của JPA (`@Version`); `version` lệch trả ERR-01-007 kèm bản hiện hành để giao diện dựng hộp so sánh. Hồ sơ chỉ sửa toàn bộ được ở `DRAFT`; ở trạng thái khác chỉ các trường mức `NONE` của BR-01-025 (đầu mối, mô tả) sửa trực tiếp, còn lại đi qua `ChangeRequestService` (mục 4.9). Mã `code` ghi một lần ở `POST` và bị chặn ở mọi lệnh sửa.

*Nhóm HTTT đề xuất.* `GroupAdvisor` là bảng quyết định năm dòng của FR-01-006 viết thành danh sách có thứ tự các `GroupRule(predicate, group, explanationKey)`; trả kết quả đầu tiên khớp cùng danh sách lý do đã dùng. Không dùng bộ luật ngoài vì bảng nhỏ, ổn định và phải kiểm thử được từng dòng (bảng bảo vệ bằng kiểm thử tham số hóa, mục 12).

*Danh sách và tìm kiếm.* `SystemQueryRepository` là đường đọc riêng (không đi qua aggregate): truy vấn JPA Criteria với chỉ mục `(tenant_id, status, owner_org_id)`, `(tenant_id, updated_at DESC)` và chỉ mục GIN `to_tsvector('simple', unaccent(name || ' ' || code))` cho `q`. Năm thẻ tổng và facets do một truy vấn `GROUP BY` lấy từ cùng bộ lọc. Với 500 HTTT và trang 50 dòng, p99 ≤ 1 giây (NFR-01-003) nhờ chỉ mục, không cần OpenSearch (Q01-25). Với vai trò OR, điều kiện `owner_org_id = :org` được OPA chèn vào bộ lọc, không do giao diện gửi; đối tượng ngoài phạm vi trả `404` cùng thân với "không tồn tại" (BR-01-030).

*Đầu mối.* `ContactPolicy` thực thi ba quy tắc ở một nơi: miền thư thuộc `contact.allowedEmailDomains` (ERR-01-011); HTTT `ACTIVE` luôn còn ít nhất một đầu mối `TECHNICAL` hoạt động, kiểm trong cùng giao dịch khi xóa hoặc vô hiệu (ERR-01-050); thông tin liên hệ là dữ liệu cá nhân mức Hạn chế (CMP-LAW-05), chưa thuộc mức Nhạy cảm nên không mã hóa trường bằng envelope (SEC-31); được bảo vệ bằng RLS, mã hóa tầng khối (SEC-30), che trong log và vết (SEC-32) và giới hạn tốc độ tra cứu (mục 4.13). Tìm kiếm danh bạ dùng cột chuẩn hóa không dấu `search_text` với chỉ mục GIN `pg_trgm`, không dùng bản băm vì FR-01-045 tìm theo từ khóa một phần. Nếu hội đồng nâng đầu mối lên mức Nhạy cảm thì phải đổi sang tìm theo chỉ mục băm tiền tố và mã hóa trường (Q01-29).

*Xuất danh sách.* `SystemExporter` ở MVP xuất đồng bộ, giới hạn 20.000 dòng (đã chốt 27/11/2026, Q01-57); từ Đợt 2 chạy bất đồng bộ cho trên 1.000 dòng và trả `202` kèm tác vụ nền tra bằng API-01-088 (`GET /jobs/{jobId}`; nơi lưu trạng thái là bảng `background_job` thêm ở Đợt 2) (ADR-056 pha ghi, giới hạn như FR-00 xuất tệp), ghi kiểm toán xuất kèm bộ lọc; xuất toàn tenant chỉ TA, AU, PA (PERM-01-read, quy tắc OPA).

### 4.3. Tài liệu đính kèm

::: dac-ta
**Mục đích.** Nhận, lưu, cho xem và xóa tài liệu hồ sơ (văn bản đề nghị, căn cứ pháp lý, hồ sơ cấp độ ATTT) an toàn: đúng kiểu theo nội dung, quét sạch mã độc, mã hóa khi lưu, mỗi tenant một bucket.

**Lớp chính.** `AttachmentService`, `ContentTypeSniffer` (Apache Tika), `ScanClient`, `ObjectStorePort`, `AttachmentAccessPolicy`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-005, 010 (mẫu văn bản); dùng lại ở FR-01-048.

**Giao diện vào.** API-01-006…009, 020, 021.

**Phụ thuộc ra.** Garage (S3, SSE-C), dịch vụ quét mã độc, OpenBao (khóa SSE-C).

**Dữ liệu.** `attachment` (`object_key`, `sha256`, `size_bytes`, `scan_status`); nội dung ở bucket `dh-{tenant}-onboarding`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-01-012 (413), 013 (415), 014 (422 nhiễm mã độc), 046 (kho tệp hoặc dịch vụ quét không khả dụng: từ chối nhận, không lưu nửa vời).

**Quan sát.** `onboarding_attachment_rejected_total{reason}`; thời gian quét; số tệp ở `PENDING` quá 5 phút.
:::

Chi tiết thiết kế: tệp được đọc theo luồng (không giữ cả tệp trong bộ nhớ) qua `DigestInputStream` tính SHA-256, ngắt khi vượt `attachment.maxSizeMb` (ERR-01-012, trần cứng 50 MB theo SEC-45). `ContentTypeSniffer` đọc 8 KiB đầu và xác định kiểu theo nội dung, đối chiếu danh sách cho phép của FR-01-005; phần mở rộng tên tệp chỉ để hiển thị. Tệp được ghi vào khóa tạm `staging/{uuid}` của bucket với khóa SSE-C lấy từ OpenBao (SEC-30), gửi quét; sạch thì sao chép sang khóa chính `{systemCode}/{attachmentId}` rồi xóa khóa tạm, nhiễm thì xóa và trả ERR-01-014. Lần quét đồng bộ có hạn 20 giây (giả định, tệp ≤ 20 MB); quá hạn thì tệp ở `PENDING` và quy tắc số 3 của bảng FR-01-011 chưa đạt cho tới khi quét xong. Tải xuống đi qua dịch vụ (không cấp URL ký trước) với `Content-Disposition: attachment` và `X-Content-Type-Options: nosniff`, sau khi `AttachmentAccessPolicy` kiểm quyền xem và phạm vi tổ chức. Chỉ xóa được tệp khi hồ sơ ở `DRAFT` và chưa từng được nộp; sau nộp, tệp thuộc hồ sơ lưu vĩnh viễn (BR-01-011). Tác vụ đối soát đêm so sánh khóa đối tượng với bảng `attachment` và báo tệp mồ côi.

### 4.4. Kiểm tra hợp lệ và nộp hồ sơ

::: dac-ta
**Mục đích.** Chạy 13 kiểm tra của FR-01-011 một lần, trả đủ danh sách thiếu sót, và nộp hồ sơ qua một giao dịch đảm bảo hồ sơ chuyển `SUBMITTED`, ba bước thẩm định được tạo và đồng hồ hạn bắt đầu chạy.

**Lớp chính.** `SubmissionValidator`, `SubmissionRule` (một lớp cho mỗi kiểm tra), `SubmissionService`, `ReviewStepFactory`, `DraftCleaner`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-011, 012, 009 (rút hồ sơ, xóa nháp).

**Giao diện vào.** API-01-022, 023, 018, 019.

**Phụ thuộc ra.** `Ph20Port`, `ReferenceDataPort`, `WorkingCalendarPort` (PH-18), `TaskInboxApi`, `NotifyPort`.

**Dữ liệu.** `member_system`, `review_step`, `state_history`, `outbox`.

**Sự kiện.** EVT-01-01 (nộp, nộp lại), EVT-01-03 (`DRAFT → SUBMITTED`, `SUBMITTED → DRAFT` khi rút).

**Lỗi và xử lý.** ERR-01-008 (kèm danh sách đầy đủ), 009, 006 (người nộp ngoài tổ chức), 007 (`If-Match`), 010, 015, 016, 047; không lỗi nào dừng ở mục đầu tiên: bộ kiểm tra gom toàn bộ.

**Quan sát.** `onboarding_stage_duration_days{stage="draft"}`; thời gian kiểm tra (mục tiêu p99 ≤ 2 giây, NFR-01-002).
:::

Chi tiết thiết kế:

*Bộ kiểm tra.* Mỗi dòng của bảng FR-01-011 là một lớp `SubmissionRule` thuần (không giao dịch, không gọi mạng), nhận `ValidationContext` đã nạp sẵn: aggregate với các dòng nhu cầu, tài liệu, đầu mối; tập tổ chức thiếu đầu mối (một truy vấn); bản đệm danh mục tổ chức, `dataType`, nhãn bí mật nhà nước. Lớp trả `Finding(level, ruleNo, errCode, field, args)`. `SubmissionValidator` chạy mọi quy tắc rồi trả danh sách sắp theo bước giao diện; mức `ERROR` chặn nộp, `WARNING` (quy tắc 10, 13) không chặn. Vì không có lời gọi mạng trên đường nóng nên 30 mục nhu cầu và 10 tài liệu kiểm trong dưới 2 giây (NFR-01-002) chỉ cần hai truy vấn nạp.

*Nộp.* `SubmissionService.submit` chạy trong một giao dịch: (1) nạp aggregate theo `If-Match`; (2) kiểm người nộp thuộc tổ chức đã khai (ERR-01-006); (3) chạy lại `SubmissionValidator` (không tin kết quả kiểm tra trước đó), có lỗi thì ERR-01-008; (4) `MemberStateMachine.apply(SUBMIT)` chuyển `DRAFT → SUBMITTED`, tăng `revisionNo`, đặt `reviewStage = WAITING_ASSIGN`; (5) `ReviewStepFactory` tạo ba bước `TECHNICAL`, `LEGAL`, `SECURITY` với `dueAt` do `ReviewClock` tính theo `review.slaWorkingDays` và lịch nghỉ của PH-18; (6) ghi `state_history`, kiểm toán và outbox EVT-01-01, EVT-01-03; (7) sau commit, tạo việc "Phân công thẩm định" trong hộp việc của TA. Nộp lại sau trả bổ sung (BR-01-032): `ReviewStepFactory` so `inputHash` của từng bước với băm của lát dữ liệu liên quan (hồ sơ kỹ thuật và cấu hình xác thực cho `TECHNICAL`; nhu cầu, căn cứ, tài liệu cho `LEGAL`; cấp độ, xác thực, IP cho `SECURITY`); trùng thì sao chép kết luận cũ sang vòng mới, khác thì mở bước mới.

*Rút hồ sơ và dọn nháp.* Rút hồ sơ (`SUBMITTED → DRAFT`) giữ nguyên nội dung và các bước đã có, dừng đồng hồ. `DraftCleaner` chạy hằng ngày (mục 4.15): nhắc ở `draft.retentionDays − 14` ngày, xóa mềm ở `draft.retentionDays` ngày không cập nhật; hồ sơ đã từng nộp không bao giờ bị xóa (BR-01-011, BR-01-024).

### 4.5. Thẩm định và phê duyệt

::: dac-ta
**Mục đích.** Điều phối ba bước thẩm định song song (kỹ thuật, pháp lý, ATTT) với hạn xử lý, tham vấn, trả bổ sung; kết luận từng mục nhu cầu; sinh trần phạm vi khi phê duyệt và khởi động saga cấp định danh trong cùng giao dịch.

**Lớp chính.** `ReviewService`, `ReviewAssignmentService`, `ReviewClock`, `DecisionService`, `QuotaImpactEvaluator`, `ScopeCeilingFactory`, `FourEyesGuard`, `EscalationJob`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-013…019.

**Giao diện vào.** API-01-024…034; UC-01-08…12.

**Phụ thuộc ra.** OPA (phân công, bốn mắt), `Ph14Port` (hạn mức quốc gia), `TaskInboxApi`, `NotifyPort`, `WorkingCalendarPort`, `SagaRepository` (khởi động saga).

**Dữ liệu.** `review_step`, `data_demand` (cột `verdict`, `scope_approved`, `opinion`), `scope_ceiling`, `member_system`, `provisioning_saga`.

**Sự kiện.** EVT-01-02 (hoàn tất bước, phân công, trả bổ sung), EVT-01-03 (`SUBMITTED → APPROVED | REJECTED | DRAFT`), EVT-01-11 (trần phạm vi tạo).

**Lỗi và xử lý.** ERR-01-017 (bốn mắt), 018 (còn mục chưa đánh giá), 019 (thiếu ý kiến, phạm vi, nhóm), 020 (sai giai đoạn), 047, 021 và 046 (phụ thuộc không khả dụng ở `Ph14Port`: không chặn, ghi "Chưa đánh giá hạn mức").

**Quan sát.** `onboarding_stage_duration_days{stage}`, `onboarding_review_overdue_total`; số việc quá hạn leo thang.
:::

Chi tiết thiết kế:

*Phân công và bốn mắt.* `PERM-01-read` là quyền nền, `PERM-01-approve` là quyền phân công (D02-08), nên IE và SO không có quyền ghi riêng. `ReviewAssignmentService` ghi `assigneeId` cho từng bước; khi người thẩm định ghi kết luận, PEP nạp phân công từ CSDL rồi gửi OPA `input = {actor, action, stepType, assigneeId, createdBy, submittedBy, priorReviewers}`; chính sách Rego trả `allow` hay lý do từ chối (SEC-26). `FourEyesGuard` là lớp duy nhất tính tập "người đã tham gia" của một hồ sơ (người lập, nộp, mọi người thẩm định, người đề nghị chấm dứt) và được gọi lại trong aggregate khi `approve`, `activate`, `terminate.decide`, nên kiểm tra không phụ thuộc OPA (kiểm hai lớp, SEC-26). Vi phạm trả ERR-01-017 và ghi sự kiện an ninh.

*Đồng hồ thẩm định.* `ReviewClock` tính hạn theo ngày làm việc từ lịch của PH-18 (`WorkingCalendarPort`, đệm 24 giờ, Q01-23); cột `paused_millis` cộng dồn thời gian ở `CONSULTING` và thời gian chờ đơn vị bổ sung (BR-01-032). Khi tiếp tục, `dueAt = now + (hạn gốc − đã dùng)`. `EscalationJob` (mỗi 15 phút, mục 4.15) tìm bước quá hạn `escalate.afterWorkingDays` ngày làm việc, gửi TA và PO, tăng `onboarding_review_overdue_total`.

*Kết luận từng mục và trần phạm vi.* Bước `LEGAL` ghi `verdict` (`APPROVED`, `NARROWED`, `REJECTED`) lên từng `DataDemand` kèm ý kiến; `NARROWED` bắt buộc `scopeApproved` (ERR-01-019); hoàn tất bước khi mọi dòng có kết luận (ERR-01-018). Thẩm định pháp lý do người làm, hệ thống chỉ hiển thị văn bản và kiểm hiệu lực theo ngày (BR-01-002), không tự quyết. `DecisionService.approve` chạy trong một giao dịch: kiểm ba bước `DONE`, `FourEyesGuard`, xác thực lại hai yếu tố (`acr` và `auth_time` ≤ `mfa.stepUpMinutes`, ERR-01-035), nhóm `confirmedGroup` đã xác nhận, phương thức xác thực đạt BR-01-019; rồi `ScopeCeilingFactory` sinh `ScopeCeiling` từ các dòng `APPROVED` và `NARROWED` (không bao giờ rộng hơn nhu cầu), đặt `status = APPROVED`, `provisionStage = PROVISIONING`, chèn một dòng `provisioning_saga` ở trạng thái `PENDING` (môi trường SANDBOX) và ghi outbox EVT-01-03, EVT-01-11. Chèn saga cùng giao dịch với phê duyệt là điểm mấu chốt: không có khoảng trống giữa "đã duyệt" và "đã xếp việc cấp định danh" kể cả khi `dh-connect` chết ngay sau commit.

*Tác động hạn mức quốc gia.* `QuotaImpactEvaluator` lấy `expectedDailyCalls` và danh sách dịch vụ quốc gia trong nhu cầu, hỏi `Ph14Port.remainingQuota` rồi phân mức `LOW`, `MEDIUM`, `HIGH` theo `quotaImpact.mediumPct`, `quotaImpact.highPct` (mặc định 20 và 50). PH-14 không khả dụng thì ghi "Chưa đánh giá hạn mức" và không chặn thẩm định (BR-01-016 chỉ yêu cầu đánh giá khi có nhu cầu dịch vụ quốc gia; người thẩm định ghi nhận xét tay).

### 4.6. Bộ điều phối saga cấp định danh

::: dac-ta
**Mục đích.** Tạo định danh ứng dụng SANDBOX (và PRODUCTION khi kích hoạt) qua PH-12, PH-03 và OpenBao thành một chuỗi bước có bù trừ, lũy đẳng, bền qua khởi động lại, hoàn tất trong 5 phút ở điều kiện bình thường.

**Lớp chính.** `ProvisioningSaga`, `SagaStep`, `SagaRunner`, `CompensationRunner`, `SagaRepository`, `ProvisionCallbackController`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-020, 021 (đăng ký khóa tiếp tục saga), 024 (PRODUCTION).

**Giao diện vào.** API-01-035, 036; API-01-087 (`POST /internal/provisioning-callbacks`, scope `onboarding:provision-callback`) cho kết quả bất đồng bộ (Q01-28, Q01-56).

**Phụ thuộc ra.** `Ph12Port`, `Ph03Port`, `OpenBaoPort`, `HandoverService`, `NotifyPort`.

**Dữ liệu.** `provisioning_saga`, `saga_step`, `app_credential`, `member_system.provision_stage`.

**Sự kiện.** EVT-01-05 (cấp xong), EVT-01-03 khi PRODUCTION chuyển `ACTIVE`.

**Lỗi và xử lý.** ERR-01-021 (PH-12 không khả dụng), 022 (client trùng, dừng `PROVISION_FAILED`), 023 (kho bí mật không khả dụng); thử lại 1, 2, 4, 8, 15 phút rồi mỗi 15 phút tới 24 giờ.

**Quan sát.** `onboarding_saga_failed_total`, `onboarding_saga_duration_seconds{env}`, `onboarding_saga_step_duration_seconds{step}`.
:::

Chi tiết thiết kế: saga là máy trạng thái lưu bền ở PH-01 theo D03-01 §7.3 ("trạng thái saga lưu ở phân hệ khởi tạo"); không dùng Flowable vì không có bước người duyệt xen giữa.

| # | Bước | Hành động | Bù trừ | Lũy đẳng bằng |
|---|---|---|---|---|
| 1 | `RECORD` | Giao dịch cục bộ: tạo `app_credential` trạng thái chờ, ghi `sagaId` | Xóa bản ghi chờ | Khóa duy nhất `(system_code, environment, saga_id)` |
| 2 | `CLIENT` | `Ph12Port.createClient`: client `{tenant}-{systemCode}-sbx`, scope môi trường thử, không scope dữ liệu; lưu ngay `clientId`, `secretRef` | `Ph12Port.disableClients(DELETE)` rồi `OpenBaoPort.destroyVersions` | `Idempotency-Key = sagaId:CLIENT` |
| 3 | `CONSUMER` | `Ph03Port.createConsumer`: gắn client, hạn mức `sandbox.quotaPerDay`, IP cho phép | `Ph03Port.deleteConsumer` | `Idempotency-Key = sagaId:CONSUMER` |
| 4 | `FINALIZE` | Giao dịch cục bộ: định danh `ACTIVE`, đặt `provisionStage` (`SANDBOX_READY` hoặc `AWAITING_KEY` với khóa công khai, mTLS), với PRODUCTION chuyển HTTT `ACTIVE`; outbox EVT-01-05, kiểm toán toàn saga | Không (bước cuối) | Giao dịch một lần theo `saga_step.status` |
| 5 | `HANDOVER` | Với `CLIENT_SECRET`: `HandoverService.create` rồi gửi thư (mục 4.7); chạy sau `SUCCEEDED`, không nằm trong chuỗi bù trừ | Hủy bàn giao (`CANCELLED`) | `credential_id` + bàn giao `PENDING` duy nhất |

: Các bước của saga cấp định danh

*Bộ chạy.* `SagaRunner` chạy mỗi 2 giây cho từng tenant (`TenantJobRunner`, mục 4.15): `SELECT … FROM provisioning_saga WHERE state IN ('PENDING','WAITING_RETRY') AND next_run_at <= now() ORDER BY next_run_at FOR UPDATE SKIP LOCKED LIMIT 10`. Hai bản sao `dh-connect` cùng chạy bộ này mà không giẫm chân nhau, không cần khóa ShedLock. Mỗi bước là một giao dịch ngắn: ghi `saga_step` ở `RUNNING`, commit, gọi ngoài (hạn 10 giây), ghi kết quả; vì lời gọi ngoài không nằm trong giao dịch nên không giữ khóa hàng khi chờ mạng. Chết giữa chừng: bước `RUNNING` quá 60 giây được bộ chạy coi là chưa biết kết quả và gọi lại với cùng khóa lũy đẳng.

*Lỗi và bù trừ.* Bước ngoài thất bại thì `CompensationRunner` chạy bù trừ các bước đã `DONE` theo thứ tự ngược (bước chưa tạo gì thì bỏ qua, không gọi), đặt saga `WAITING_RETRY` với `next_run_at` theo lịch lùi 1, 2, 4, 8, 15 phút rồi lặp 15 phút tới `started_at + 24 giờ`; quá hạn thì `FAILED`, `provisionStage = PROVISION_FAILED` và cảnh báo mức cao tới TA, PO (EVT cảnh báo qua PH-13). Lần thử lại dùng đúng `sagaId` nên PH-12, PH-03 trả lại kết quả cũ thay vì tạo trùng. Lỗi nghiệp vụ không thể tự khỏi (ERR-01-022 client trùng) dừng ngay ở `FAILED`. TA sửa nguyên nhân rồi bấm "Thử lại" (API-01-035): nếu saga chưa `FAILED` thì chỉ đặt `next_run_at = now`; nếu đã `FAILED` (bước trước đã bù trừ xong) thì tạo saga mới với `sagaId` mới.

*Kích hoạt PRODUCTION.* `ActivationService` (mục 4.8) tạo saga môi trường PRODUCTION với cờ `completeWith = ACTIVATE`: bước `FINALIZE` chuyển HTTT `APPROVED → ACTIVE` trong cùng giao dịch cục bộ. API chạy lượt đầu của saga đồng bộ với hạn 10 giây; xong thì trả `200` như FRS, chưa xong thì trả `202` kèm đường dẫn tiến độ (API-01-036) và saga chạy nền (Q01-28; đề nghị ghi vào D03-04-PH01).

*Kết quả bất đồng bộ.* Nếu PH-12 hoặc PH-03 chọn trả kết quả qua callback (scope `onboarding:provision-callback`), bước chuyển `ACCEPTED`, chờ tối đa 5 phút (giả định); callback đến sẽ đưa bước sang `DONE` hoặc `FAILED`, hết hạn thì coi như thất bại. Callback là API-01-087: kiểm token dịch vụ, `sagaId` và tenant của token (SEC-80), lũy đẳng theo `(sagaId, step)`; bước không ở `ACCEPTED` hoặc cờ `onboarding.saga.async-callback` đang tắt thì trả ERR-01-053 (409) và chỉ ghi nhật ký vận hành.

*Trạng thái hiển thị.* `GET /systems/{systemCode}/provisioning` đọc `provisioning_saga` và `saga_step`: `{sagaId, stage, steps[{name, status, at}]}`, không có bí mật hay `secretRef`.

### 4.7. Bộ bàn giao thông tin xác thực một lần

::: dac-ta
**Mục đích.** Đưa bí mật client tới đúng đầu mối kỹ thuật đúng một lần, qua cơ chế bọc phản hồi của OpenBao, sao cho PH-01 không đọc được bí mật ở dạng rõ trừ lúc trả phản hồi mở, và không còn bản đọc lại được sau đó.

**Lớp chính.** `HandoverService`, `LinkCodec`, `HandoverGuard`, `WrapTokenVault`, `HandoverRecoveryJob`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-022; phần bàn giao của FR-01-020, 024, 025.

**Giao diện vào.** API-01-039 (tạo), 040 (mở), 041 (tạo lại); UI-01-09; UC-01-15.

**Phụ thuộc ra.** `OpenBaoPort` (bọc, mở, hủy phiên bản, thu hồi mã bọc, transit), Keycloak (`acr`, `auth_time`), `NotifyPort`.

**Dữ liệu.** `handover` (`link_hash`, `wrap_accessor`, `wrap_token_sealed`, `status`, `failed_attempts`, `opened_by`, `opened_ip`).

**Sự kiện.** EVT-01-09 (mở thành công), EVT-01-10 (sai người mở, mở sai nhiều lần).

**Lỗi và xử lý.** ERR-01-024 (410), 025 (403), 026 (429), 035, 048, 023 (OpenBao không khả dụng: liên kết không bị tiêu hao), 003 (đầu mối chưa có tài khoản).

**Quan sát.** `onboarding_handover_total{result}` (`opened`, `expired`, `cancelled`, `wrong_recipient`, `locked`), `onboarding_handover_open_seconds`; cảnh báo khi `wrong_recipient` hoặc `locked` tăng.
:::

Chi tiết thiết kế:

*Tạo bàn giao.* `HandoverService.create` gọi `OpenBaoPort.wrapClientSecret(secretRef, ttl = handover.ttlHours)`: đọc `kv/data/dh/{tenant}/clients/{systemCode}/{env}` kèm tiêu đề `X-Vault-Wrap-TTL`. Chính sách OpenBao của `dh-connect` đặt `min_wrapping_ttl` cho đường dẫn này nên **mọi lần đọc đều bị bọc**, kể cả khi mã của PH-01 có lỗi hoặc bị lợi dụng; PH-01 chỉ nhận mã bọc (`wrap_info.token`) và `accessor`. Chính sách tối thiểu (sinh theo tenant khi PH-20 khởi tạo tenant):

```hcl
path "kv/data/dh/{tenant}/clients/*"     { capabilities = ["read"]
                                           min_wrapping_ttl = "60s"  max_wrapping_ttl = "72h" }  # không đọc rõ
path "kv/metadata/dh/{tenant}/clients/*" { capabilities = ["read", "list"] }       # đọc phiên bản, không đọc giá trị
path "kv/destroy/dh/{tenant}/clients/*"  { capabilities = ["update"] }             # hủy phiên bản sau khi mở
path "sys/wrapping/unwrap"               { capabilities = ["update"] }
path "auth/token/revoke-accessor"        { capabilities = ["update"] }             # thu hồi mã bọc khi tạo lại
path "pki-clients/sign/http-clients-{tenant}" { capabilities = ["update"] }        # FR-01-021
path "transit/encrypt/dh-{tenant}-handover"   { capabilities = ["update"] }
path "transit/decrypt/dh-{tenant}-handover"   { capabilities = ["update"] }
```

Liên kết gửi thư là `token` ngẫu nhiên 256 bit từ `SecureRandom`, mã hóa base64url (NFR-01-010). PH-01 chỉ lưu `link_hash = SHA-256(token)` và `wrap_accessor`. Mã bọc của OpenBao cần giữ để mở sau này nên được `WrapTokenVault` mã hóa bằng khóa transit riêng `dh-{tenant}-handover` với AAD là `tenant_id` và `handover_id`, lưu ở `wrap_token_sealed`; mã bọc chỉ dùng được một lần, sống tối đa 72 giờ và vô dụng nếu thiếu OpenBao, và cột được đặt `NULL` ngay khi bàn giao rời `PENDING`. Cách này đạt "không lưu liên kết gốc" của FR-01-022 mà vẫn mở được; cột thêm so với EN-01-09 ghi ở Đề nghị đồng bộ.

*Mở bàn giao.* Chỉ cổng `POST /handovers:open` (API-01-040) mở; đăng nhập lại do Keycloak ép (`prompt=login`, `acr` mức hai yếu tố). `HandoverGuard` kiểm tuần tự và dừng ở lỗi đầu tiên:

| Bước | Kiểm tra hoặc hành động | Kết quả khi không đạt |
|---|---|---|
| 1 | `acr` đủ và `auth_time` ≤ `mfa.stepUpMinutes` | ERR-01-035 (403), không tiêu hao liên kết |
| 2 | Băm `token`, tìm bàn giao theo `link_hash`, trạng thái `PENDING`, chưa hết hạn | ERR-01-024 (410), thân giống nhau cho "không có", "đã dùng", "hết hạn" |
| 3 | `sub` của token đăng nhập bằng `contact.user_account_id` của người nhận, cùng tenant | ERR-01-025 (403); tăng `failed_attempts` ở giao dịch riêng, phát EVT-01-10 |
| 4 | `failed_attempts` < `handover.maxFailedOpens` | ERR-01-026 (429), chuyển `CANCELLED` |
| 5 | HTTT không `SUSPENDED` | ERR-01-048 (409) |
| 6 | Chiếm chỗ: `UPDATE handover SET status='OPENING' WHERE id=? AND status='PENDING'` trả đúng 1 dòng | Người thứ hai đồng thời nhận ERR-01-024 |
| 7 | `OpenBaoPort.unwrap`; lỗi mạng thì trả `OPENING → PENDING` và ERR-01-023; mã bọc đã bị dùng thì `CANCELLED` kèm cảnh báo EVT-01-10 (liên kết bị lộ) | |
| 8 | `OPENED`, ghi người mở, IP, thời điểm; `OpenBaoPort.destroyVersions(secretRef)`; đặt `wrap_token_sealed = NULL`; outbox EVT-01-09 | |

: Trình tự kiểm tra khi mở bàn giao

Thân phản hồi có `Cache-Control: no-store`, `Pragma: no-cache`; đối tượng bí mật chỉ nằm trong bộ nhớ của yêu cầu và bị xóa tham chiếu sau khi serialize. Tuyến đường dẫn này được gắn nhãn "không ghi thân phản hồi" ở BFF, APISIX và Coraza (SEC-32; Q01-27). Với `PRIVATE_KEY_JWT` và `MTLS` không có bí mật nên không bọc: trang chỉ hiển thị thông tin kết nối, vẫn yêu cầu đăng nhập đúng đầu mối và ghi vết.

*Hết hạn, tạo lại, khôi phục sự cố.* Tạo lại (API-01-041): hủy bàn giao cũ (`CANCELLED`), thu hồi mã bọc cũ bằng `revoke-accessor`, bọc lại từ bí mật còn ở KV (chỉ khi chưa từng mở) rồi gửi liên kết mới. `HandoverRecoveryJob` (mỗi phút): bàn giao `PENDING` quá `expires_at` chuyển `EXPIRED` (mã bọc tự hết hạn ở OpenBao); bàn giao `OPENING` quá 2 phút nghĩa là tiến trình chết giữa lúc mở, bí mật có thể đã được mở mà chưa tới người nhận, nên chuyển `CANCELLED` kèm lý do `OPEN_INTERRUPTED`, báo TA xoay vòng (FR-01-025) vì không có cách dựng lại; đây là lý do duy nhất phải xoay ngoài lịch.

### 4.8. Vòng đời định danh: xoay vòng, hết hạn, kiểm thử SANDBOX, kích hoạt, thu hồi

::: dac-ta
**Mục đích.** Quản lý đời sống của định danh ứng dụng sau khi cấp: đăng ký khóa hoặc chứng thư, thu thập kết quả kiểm thử SANDBOX, kích hoạt PRODUCTION, xoay vòng có chuyển tiếp, nhắc hạn và tự hết hạn, thu hồi, tự vô hiệu khi không dùng.

**Lớp chính.** `CredentialService`, `KeyValidator`, `CsrValidator`, `RotationService`, `RotationFinisher`, `SandboxTestService`, `ActivationService`, `ExpiryJob`, `InactivityJob`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-021, 023, 024, 025, 026, 027, 028, 036.

**Giao diện vào.** API-01-037, 038, 042…050, 061; UC-01-14, 16…19, 25.

**Phụ thuộc ra.** `Ph12Port`, `Ph03Port`, `Ph13Port` (kết quả sandbox, lần dùng cuối), `OpenBaoPort` (PKI), `HandoverService`, `EnforcementService`.

**Dữ liệu.** `app_credential`, `sandbox_test`, `handover`, `state_history`.

**Sự kiện.** EVT-01-05 (cấp), 06 (bắt đầu, kết thúc xoay vòng, khóa mới), 07 (thu hồi, hết hạn, tự vô hiệu), 08 (sắp hết hạn).

**Lỗi và xử lý.** ERR-01-027, 028 (khóa, CSR sai), 029 (đang xoay), 030, 031 (chưa đủ kiểm thử), 032 (chưa đủ điều kiện), 033 (thiếu lý do), 035, 017 (người nộp tự kích hoạt), 021, 023.

**Quan sát.** `onboarding_credential_expiring_total`, `onboarding_sandbox_days{le}`, `onboarding_rotation_total{result}`, `onboarding_credential_disabled_total{reason}`.
:::

Chi tiết thiết kế:

*Kiểm tra khóa và chứng thư.* `KeyValidator` phân tích JWKS bằng thư viện Nimbus JOSE: chỉ chấp nhận `ES256` đường cong P-256 hoặc `PS256` với RSA từ 3072 bit; từ chối khóa có thành phần riêng (`d`, `p`, `q`, `dp`, `dq`, `qi`), thiếu hoặc trùng `kid`; tải trọng ≤ 16 KB (ERR-01-027). `CsrValidator` phân tích PKCS#10 bằng Bouncy Castle: khóa ECDSA P-256 hoặc RSA 3072, `CN` khớp `{systemCode}.{tenant}`, không có phần mở rộng ngoài danh sách cho phép của vai trò PKI (ERR-01-028); hợp lệ thì gọi `OpenBaoPort.signCsr` trên vai trò `http-clients-{tenant}` của mount `pki-clients` (SEC-35) với thời hạn `min(credential.maxLifetimeDays, yêu cầu)`. Dấu vân tay SHA-256 và `jwks_ref` lưu ở `app_credential`; nội dung khóa không vào nhật ký kiểm toán.

*Xoay vòng.* `RotationService.start` yêu cầu xác thực lại hai yếu tố (ERR-01-035), kiểm `ACTIVE` (ERR-01-030), không đang xoay (ERR-01-029), rồi theo phương thức: `CLIENT_SECRET` gọi `Ph12Port.startSecretRotation` (client có hai bí mật cùng hiệu lực, bí mật mới vào OpenBao) và `HandoverService.create`; `PRIVATE_KEY_JWT` chờ khóa kế tiếp qua API-01-037 (tối đa hai `kid` cùng hiệu lực); `MTLS` chờ CSR mới (PH-03 giữ hai dấu vân tay). Định danh sang `ROTATING`, `rotation_ends_at = now + overlapDays`, outbox EVT-01-06. `RotationFinisher` (mỗi phút) tìm định danh `ROTATING` có `rotation_ends_at ≤ now` hoặc người dùng bấm kết thúc (API-01-046), gỡ thông tin cũ ở PH-12, PH-03, hủy phiên bản OpenBao, về `ACTIVE`, tính lại `expires_at`. Xoay khẩn đặt `overlapDays = 0`: thông tin cũ bị gỡ ngay, nên lệnh xoay khẩn đi kèm cảnh báo gián đoạn ở giao diện.

*Kiểm thử SANDBOX.* `SandboxTestService` chạy mỗi 5 phút cho HTTT ở `SANDBOX_READY`: gọi `Ph13Port.sandboxActivity(clientId, since)` lấy số lượt xác thực thành công, số lượt gọi API thành công, mã lỗi nổi bật; ghi `sandbox_test`; đánh giá đạt khi có ít nhất một lần xác thực và ít nhất `sandbox.requiredSuccessfulCalls` lượt gọi thành công trong 7 ngày (thêm bắt tay chứng thư với `MTLS`); đặt `readyToActivate` và báo TA. Từ 20 lượt `invalid_client` trong 1 giờ thì đề nghị xoay và báo SO; quá `sandbox.maxDays` thì cảnh báo TA, PO. PH-13 không khả dụng ghi ERR-01-046 vào log, không đổi cờ (không kết luận nhầm).

*Kích hoạt PRODUCTION.* `ActivationService.activate` kiểm: người kích hoạt khác người nộp (`FourEyesGuard`, ERR-01-017), xác thực lại hai yếu tố, `readyToActivate`, kiểm thử đạt (ERR-01-031), đầu mối kỹ thuật hoạt động, cấp độ ATTT còn đạt theo trần (ERR-01-032, BR-01-026), rồi tạo saga PRODUCTION (mục 4.6).

*Hết hạn và nhắc.* `ExpiryJob` chạy hằng ngày: phát EVT-01-08 ở mốc `credential.expiryReminderDays` (30, 14, 7), định danh quá `expires_at` chuyển `EXPIRED` và gọi `EnforcementService` vô hiệu ở PH-12, PH-03 (EVT-01-07). `InactivityJob` (Đợt 2, cờ `onboarding.autosuspend.enabled`) so `last_used_at` từ PH-13 với `inactivity.autoSuspendDays` (90): đặt `disabled = true` có thể đảo ngược và báo SO; PH-13 không trả dữ liệu thì bỏ qua lượt, không vô hiệu nhầm. Thu hồi (`CredentialService.revoke`) bắt buộc lý do và xác thực lại, đi qua `EnforcementService` (mục 4.10), đóng mọi bàn giao `PENDING` của định danh.

### 4.9. Vòng đời thành viên: tạm ngừng, khôi phục, chấm dứt, thao tác khẩn, thay đổi hồ sơ

::: dac-ta
**Mục đích.** Thực thi các chuyển trạng thái sau kết nạp của HTTT (`ACTIVE ⇄ SUSPENDED`, `→ TERMINATED`) với phân tích tác động, lý do bắt buộc, xác thực lại hai yếu tố và bốn mắt; cho Cán bộ ATTT hành động ngay khi khẩn cấp; phân mức thay đổi hồ sơ và mở rộng trần phạm vi qua thẩm định lại.

**Lớp chính.** `LifecycleService`, `MemberStateMachine`, `TransitionTable`, `ImpactAnalyzer`, `EmergencyService`, `EmergencyConfirmationJob`, `ChangeRequestService`, `ChangeClassifier`, `ScopeExpansionService`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-029…035, 036 (phía trạng thái), 043 (gọi tạm ngừng khi căn cứ hết hiệu lực).

**Giao diện vào.** API-01-051…061, 056; UC-01-20…24.

**Phụ thuộc ra.** `EnforcementService`, `ImpactAnalyzer` gọi `Ph02Port`, và API phụ thuộc của PH-04, PH-05, PH-10; `ReviewService` (thẩm định lại); `NotifyPort`.

**Dữ liệu.** `member_system`, `state_history`, `emergency_action`, `change_request`, `scope_ceiling`.

**Sự kiện.** EVT-01-03 (mọi chuyển trạng thái), EVT-01-04 (đổi thuộc tính), EVT-01-11 (trần đổi), EVT-01-15 (thao tác khẩn, xác nhận, quá hạn).

**Lỗi và xử lý.** ERR-01-005 (sai trạng thái), 017, 033, 034 (cần xác nhận tác động), 035, 036 (khôi phục khi chưa có đồng ý SO), 037, 038, 048; lỗi cắt quyền không hoàn tác trạng thái (mục 4.10).

**Quan sát.** `onboarding_members_total{status,group}`, `onboarding_emergency_pending_total`, `onboarding_state_transition_total{from,to}`.
:::

Chi tiết thiết kế:

*Một bảng chuyển cho mọi trạng thái.* `TransitionTable` là danh sách bất biến các `Transition(from, command, to, guard, action)` dùng chung cho bốn đối tượng (HTTT, định danh, bàn giao, kỳ rà soát) theo từng enum; đây là nguồn duy nhất cho dịch vụ, cho danh sách hành động khả dụng trả kèm hồ sơ và cho kiểm thử (ADR-058, ADR-069). Mỗi lần áp dụng `MemberStateMachine.apply` ghi `state_history` (từ, đến, lý do, tác nhân, cờ khẩn, `traceId`), kiểm toán và outbox trong cùng giao dịch (BR-01-031); lệnh không có trong bảng ném ERR-01-005. Phần bảo vệ (guard) gồm bốn mắt, lý do, xác thực lại, điều kiện nghiệp vụ; bảng chuyển đầy đủ ở mục 8.1.

*Phân tích tác động.* `ImpactAnalyzer` chạy song song bằng `StructuredTaskScope` (luồng ảo) các lời gọi: `Ph02Port` (API đang công bố, đăng ký sử dụng đang hoạt động), PH-04, PH-05, PH-10 (luồng, kết nối, bên phát và nhận gắn HTTT), mỗi lời gọi hạn 3 giây. Kết quả gom thành `ImpactReport(items, partial)`; nguồn không trả lời thì `partial = true` và danh sách ghi rõ nguồn thiếu để người quyết định biết. Tạm ngừng hoặc chấm dứt khi có phụ thuộc, hoặc HTTT `criticality = CRITICAL`, đòi hỏi `confirmImpact = true` (ERR-01-034); báo cáo được lưu kèm kiểm toán để chứng minh người quyết định đã thấy tác động.

*Tạm ngừng và khôi phục.* `LifecycleService.suspend`: kiểm `ACTIVE`, lý do ≥ 10 ký tự, xác thực lại, tác động; đặt `SUSPENDED`, `enforcement = PENDING`, rồi gọi `EnforcementService.plan(SUSPEND)` trong cùng giao dịch. `resume` đòi hỏi trạng thái `SUSPENDED`, điều kiện theo lý do tạm ngừng: `SECURITY_SUSPECT` cần `EmergencyAction` liên quan đã có đồng ý của SO và mọi định danh đã xoay (BR-01-010, ERR-01-036); `LEGAL_EXPIRED` cần trần đã khôi phục qua thẩm định lại; sau đó `EnforcementService.plan(RESUME)` chạy chiều ngược (bỏ chặn, bật client và consumer). Khôi phục không dùng lại bí mật cũ nếu định danh đã bị thu hồi.

*Chấm dứt.* Chấm dứt là `ChangeRequest` loại `TERMINATE` (API-01-053) với bốn mắt: người đề nghị không duyệt (BR-01-017); duyệt ở API-01-059. Khi duyệt: chuyển `TERMINATED`, chờ `terminate.drainMinutes` (mặc định 5) cho giao dịch đang xử lý rồi cắt quyền và thu hồi mọi định danh, đóng trần phạm vi, đóng bàn giao; mã HTTT giữ nguyên, không dùng lại (BR-01-018). Hồ sơ APPROVED quá hạn kiểm thử (`sandbox.maxDays`) cũng đi đường này (`APPROVED → TERMINATED`).

*Thao tác khẩn.* `EmergencyService.act` (API-01-054) cho SO (hoặc TA) tạm ngừng hoặc thu hồi ngay, không chờ ai duyệt trước, nhưng vẫn bắt buộc lý do và xác thực lại; ghi `EmergencyAction(status = PENDING_CONFIRM, confirmBy = now + emergency.confirmHours)` và đi cùng đường cắt quyền. TA xác nhận bổ sung ở API-01-055 (khác người thực hiện). `EmergencyConfirmationJob` (mỗi 5 phút) đánh dấu `OVERDUE` các thao tác quá hạn, phát EVT-01-15 và cảnh báo mức cao tới TA, PO; **không tự hoàn tác** (BR-01-010). Thao tác xác nhận lần hai trả ERR-01-036.

*Thay đổi hồ sơ theo mức.* `ChangeClassifier` đặt mức theo trường bị đổi (BR-01-025): mức `NONE` (đầu mối, mô tả) áp dụng ngay và không tạo yêu cầu; mức `TECHNICAL` (địa chỉ, IP, hạn mức, cấp độ ATTT) cần TA duyệt kỹ thuật; `OWNER_CHANGE` cần tổ chức mới xác nhận rồi TA duyệt (BR-01-029); `FULL` (mở rộng phạm vi) đi qua thẩm định pháp lý lại. Một HTTT chỉ có một yêu cầu `PENDING` (ERR-01-038). Khi duyệt, `diff` được áp vào aggregate trong một giao dịch và phát EVT-01-04.

*Mở rộng trần phạm vi.* `ScopeExpansionService` (API-01-060) tạo `ChangeRequest FULL` kèm các dòng nhu cầu mới ở trạng thái chờ, mở lại bước `LEGAL` (và `SECURITY` nếu mức phân loại tăng) cho vòng thẩm định mới; sửa trần bằng đường thay đổi thường bị chặn ở ERR-01-037 (BR-01-012). Khi duyệt, `ScopeCeilingFactory` thêm hoặc mở rộng `ScopeCeiling` và phát EVT-01-11.

### 4.10. Cắt quyền

::: dac-ta
**Mục đích.** Bảo đảm lệnh tạm ngừng, thu hồi, chấm dứt, thao tác khẩn làm cổng API từ chối HTTT trong không quá 60 giây, kể cả khi PH-12 hoặc PH-03 chậm hoặc lỗi giữa chừng, và không để lại trạng thái "đã báo ngừng nhưng vẫn gọi được" kéo dài.

**Lớp chính.** `EnforcementService`, `EnforcementTask`, `EnforcementExecutor`, `EnforcementRetryJob`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-026, 029, 030, 031, 032, 033 (phần cắt), 037.

**Giao diện vào.** Gọi nội bộ từ `LifecycleService`, `EmergencyService`, `CredentialService`, `ExpiryJob`, `LegalValidityChecker`; không có API riêng.

**Phụ thuộc ra.** `Ph03Port.blockClients`, `Ph12Port.disableClients`, `Ph12Port.revokeTokens`, `Ph03Port.disableConsumer`; PH-10 hạ ACL Kafka khi nhận EVT-01-03.

**Dữ liệu.** `enforcement_task` (`seq`, `type`, `status`, `attempt`, `next_run_at`, `idempotency_key`), `member_system.enforcement`.

**Sự kiện.** EVT-01-03 (cùng giao dịch đặt trạng thái), EVT-01-07 (định danh bị vô hiệu).

**Lỗi và xử lý.** ERR-01-021 (PH-12), 046 (PH-03); lỗi chỉ dẫn tới thử lại và cảnh báo, không đổi trạng thái đã đặt.

**Quan sát.** `onboarding_enforcement_pending_total`, `onboarding_enforcement_latency_seconds{type}` (từ commit tới `DONE`), cảnh báo khi một việc còn `PENDING` quá 60 giây.
:::

Chi tiết thiết kế: nguyên tắc là **trạng thái và cổng đi trước, hệ định danh đi sau**. Trong giao dịch của lệnh nghiệp vụ, `EnforcementService.plan(mode, systemCode)` đặt `enforcement = PENDING` và chèn bốn việc có thứ tự:

| `seq` | Việc | Hành động | Vì sao ở vị trí này |
|---|---|---|---|
| 1 | `BLOCK_GATEWAY` | `Ph03Port.blockClients(clientIds)`: đưa client vào danh sách chặn của APISIX | Có hiệu lực ngay ở cổng, là điều kiện chính của NFR-01-008 |
| 2 | `DISABLE_CLIENTS` | `Ph12Port.disableClients`: vô hiệu client ở Keycloak | Ngăn cấp token mới |
| 3 | `REVOKE_TOKENS` | `Ph12Port.revokeTokens`: thu hồi token còn hạn (token sống 5 phút, SEC-25) | Dọn token đã cấp; cổng đã chặn nên không còn là cửa hở |
| 4 | `DISABLE_CONSUMER` | `Ph03Port.disableConsumer`: vô hiệu consumer, giữ cấu hình để khôi phục | Hoàn tất ở data plane |

: Việc cắt quyền theo thứ tự

Sau khi giao dịch commit, `EnforcementExecutor` chạy việc 1 **đồng bộ trong yêu cầu** với hạn 5 giây rồi trả kết quả cho người dùng (`enforcement = PENDING` hay `DONE`); các việc 2…4 chạy ngay sau đó ở luồng nền. Việc nào lỗi sẽ được `EnforcementRetryJob` (mỗi 10 giây, `SKIP LOCKED`) chạy lại với lịch 10, 20, 40, 60 giây rồi giữ 60 giây tới khi xong; sau 60 giây còn `PENDING` thì tăng `onboarding_enforcement_pending_total` và cảnh báo SO ("Việc cắt quyền của {mã} chưa hoàn tất"). Mọi việc lũy đẳng nhờ `Idempotency-Key = {enforcementId}:{type}` và vì thao tác trên tập `clientIds` cố định ghi trong việc. Chiều khôi phục (`RESUME`) chạy thứ tự ngược: bật consumer, bật client, bỏ chặn ở cổng sau cùng, để HTTT không gọi được trong lúc cấu hình chưa đủ.

Dự toán độ trễ cho NFR-01-008 (giả định, đo ở D05-02-PH01): commit lệnh ≤ 0,6 giây (NFR-01-001); lời gọi chặn ≤ 5 giây (hạn cứng); APISIX nhận cấu hình qua etcd thường dưới 2 giây; tổng thông thường dưới 10 giây, trần thiết kế 60 giây còn dư để chịu một lần thử lại. ACL Kafka ≤ 2 phút do PH-10 xử lý khi nhận EVT-01-03 (FR-01-037), tách khỏi đường cổng. PH-20 tạm ngừng cả tenant thì PH-03 chặn ở mức tenant, PH-01 không đổi trạng thái từng HTTT (FR-01-037 bước 6). API của PH-03 phải trả về sau khi cấu hình đã ghi vào etcd, không trước (Q01-24).

### 4.11. Đồng bộ trạng thái và bản sao đọc cho phân hệ khác

::: dac-ta
**Mục đích.** Làm PH-01 thành nguồn duy nhất về trạng thái HTTT: phát sự kiện không mất, đúng thứ tự theo HTTT, và cung cấp API đọc rút gọn để phân hệ khác khởi tạo, đối chiếu bản sao mà không đọc chéo CSDL.

**Lớp chính.** `OutboxPublisher`, `OutboxRelay` (dự phòng), `ReplicaController`, `ReplicaService`, `SnapshotPublisher`, `Reconciler`, `InboundEventHandler`, `InboxRepository`.

**Đơn vị chạy.** `dh-connect`; Debezium chạy ở Kafka Connect.

**FR hiện thực.** FR-01-037, 038.

**Giao diện vào.** API-01-062 (đối chiếu), 063, 064 (đọc bản sao); `MemberSystemQueryApi` trong tiến trình. Đã chốt 27/11/2026: sau khi PH-16 chốt danh sách trường tự đăng ký kiến trúc (FR-16-048), PH-01 phát thêm `componentCode`, loại, phiên bản, vòng đời, `dependsOn`, `contentHash` ở sự kiện và có API liệt kê để đối chiếu.

**Phụ thuộc ra.** Kafka (qua Debezium), Apicurio (lược đồ BACKWARD).

**Dữ liệu.** `outbox`, `inbox` (sự kiện đã xử lý), `member_system`.

**Sự kiện.** EVT-01-03, 04, 11 và ảnh chụp đối chiếu (`snapshot = true`); tiêu thụ ba loại sự kiện từ PH-12, PH-18, PH-20.

**Lỗi và xử lý.** Kafka ngừng: outbox giữ, phát bù khi trở lại; bản ghi hỏng lược đồ: đưa vào hàng đợi lỗi, cảnh báo, không chặn các bản ghi sau; token thiếu scope: `403`.

**Quan sát.** `onboarding_outbox_lag_seconds`, `onboarding_outbox_pending`, `onboarding_replica_requests_total{caller}`, `onboarding_reconcile_diff_total{consumer}`.
:::

Chi tiết thiết kế:

*Phát sự kiện.* Mọi lớp nghiệp vụ ghi sự kiện qua `OutboxPublisher.publish(DomainEvent)`, chèn một dòng `outbox` `(id ULID, tenant_id, key = systemCode, type, payload jsonb, created_at, trace_id)` trong giao dịch hiện hành; gọi ngoài giao dịch bị chặn bằng `Propagation.MANDATORY`. Ở hồ sơ `QM-VUA` và `QM-LON`, Debezium Outbox Event Router đọc WAL của bảng `outbox` và phát lên `{tenant}.connect.system.state-changed.v1` (và các topic EVT khác) với khóa bản ghi là `systemCode`, nên mọi thay đổi của một HTTT đến theo đúng thứ tự (NFR-01-021); ở `QM-NHO`, `OutboxRelay` quét lô mỗi 500 ms làm đường dự phòng (ADR-042). Hàng đã phát được dọn sau 7 ngày. Nội dung dùng CloudEvents 1.0, lược đồ đăng ký ở Apicurio chế độ BACKWARD; quy tắc cứng: không bí mật, không `secret_ref`, không dữ liệu liên hệ cá nhân (EVT-01-13 chỉ mang mã HTTT và loại đầu mối).

*Đối chiếu hằng giờ.* `SnapshotPublisher` quét toàn bộ HTTT của tenant theo lô 200 (khóa phân trang `(updated_at, id)`), phát lô sự kiện EVT-01-03 với `snapshot = true`; phân hệ nhận so khớp bản sao của mình và sửa lệch, ghi `onboarding_reconcile_diff_total` khi báo ngược qua API-01-062. Cách này bù sự kiện lỡ mà không cần phân hệ khác tự quét PH-01.

*API đọc bản sao.* `ReplicaService` phân trang theo con trỏ `nextUpdatedSince` là cặp `(updated_at, id)` mã hóa opaque, nên các bản ghi cùng mili giây không bị bỏ sót (`size ≤ 500`). Bản ghi rút gọn theo `MemberSystemView`; tenant lấy từ token dịch vụ, không từ tham số (SEC-80); đối tượng khác tenant trả `404` (BR-01-030). Số lượt gọi ghi theo `caller` (từ `azp`) để PH-13 phát hiện khai thác bất thường, không ghi kiểm toán từng lượt.

*Tiêu thụ sự kiện vào.* `InboundEventHandler` xử lý ba loại sự kiện: tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức (PH-12) đặt `Contact` về `INACTIVE` và chạy lại kiểm tra ERR-01-050; thư bị trả lại (PH-18) đánh dấu đầu mối không hoạt động (BR-01-028); tenant tạm ngừng (PH-20) chỉ ghi nhận, không đổi từng HTTT. Mỗi sự kiện có bản ghi `inbox(event_id)` duy nhất để xử lý lũy đẳng; lỗi lặp lại ba lần đưa vào hàng đợi lỗi của PH-18.

### 4.12. Rà soát quyền định kỳ

::: dac-ta
**Mục đích.** Mỗi sáu tháng (hoặc khi cần) mở kỳ rà soát mọi HTTT `ACTIVE`, tổng hợp mức sử dụng thật của từng phạm vi trong trần, hỏi đơn vị chủ quản, quyết định giữ, thu hẹp hay thu hồi; tạm ngừng ngay phạm vi có căn cứ hết hiệu lực.

**Lớp chính.** `AccessReviewService`, `AccessReviewScheduler`, `UsageAggregator`, `ConfirmationService`, `NoResponseJob`, `LegalValidityChecker`, `ReviewReportService`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-039…044.

**Giao diện vào.** API-01-065…075; UI-01-12, UI-01-13; UC-01-27…29.

**Phụ thuộc ra.** `Ph13Port.usageByCredential`, `Ph02Port.apisByDataType`, `NotifyPort`, `TaskInboxApi`, `ScopeCeilingService`.

**Dữ liệu.** `access_review_cycle`, `access_review_item`, `review_confirmation` (chỉ lưu `link_hash`), `scope_ceiling`.

**Sự kiện.** EVT-01-11 (trần đổi), EVT-01-12 (đóng kỳ).

**Lỗi và xử lý.** ERR-01-039, 040 (phiếu hết hạn), 041 (quyết định không hợp lệ), 044, 035, 033; PH-13 hoặc PH-02 không khả dụng: ghi ERR-01-046 vào log, mục đánh dấu "Chưa có số liệu", kỳ tiếp tục.

**Quan sát.** `onboarding_scope_unused_total`, `onboarding_review_cycle_open_days`, `onboarding_access_review_coverage_ratio`.
:::

Chi tiết thiết kế:

*Mở kỳ và sinh mục.* `AccessReviewScheduler` chạy hằng ngày, so `last_review_at` của từng HTTT với `accessReview.intervalMonths` (tối đa 6 để thỏa BR-01-014) và mở kỳ tự động khi có HTTT quá hạn; chỉ mục duy nhất từng phần bảo đảm mỗi tenant một kỳ chưa đóng (ERR-01-039). Kỳ sinh `cycleCode = RS-{năm}-{nn}` và một `access_review_item` cho mỗi cặp (HTTT, mục trần) bằng một câu `INSERT … SELECT` trong giao dịch. Kỳ theo chuyên đề (danh sách tổ chức) không cập nhật `last_review_at` toàn tenant.

*Tổng hợp mức dùng.* `UsageAggregator` ánh xạ `dataType` sang API và scope nhờ `Ph02Port`, hỏi `Ph13Port` số lượt gọi thành công theo định danh trong khoảng kỳ, với tối đa 8 lời gọi đồng thời mỗi tenant để không tạo tải đột biến lên PH-13; tính `usageInPeriod`, `unusedDays` và đặt cờ `UNUSED_IN_PERIOD`, `UNUSED_OVER_12M` (theo `accessReview.unusedDays`), `CREDENTIAL_EXPIRING`, `LEGAL_EXPIRED`, `NO_USAGE_DATA` (mục chưa gắn API: để người rà soát quyết định tay). Lượt tổng hợp lỗi một phần chỉ đánh dấu mục thiếu, bấm "Làm mới số liệu" chạy lại đúng các mục đó.

*Xác nhận của đơn vị.* `ConfirmationService.send` nhóm mục theo tổ chức, tạo một `review_confirmation` mỗi tổ chức với token 256 bit (chỉ lưu băm, hạn `accessReview.confirmLinkTtlDays`), gửi thư chỉ chứa liên kết và đưa việc vào hộp việc của OR; kỳ sang `WAITING`. Trang UI-01-13 yêu cầu đăng nhập và kiểm người mở thuộc tổ chức được hỏi (ERR-01-025), phản hồi `KEEP`, `REDUCE`, `RELEASE` lưu theo mục (`REDUCE` bắt buộc nêu phạm vi). `NoResponseJob` (hằng ngày) đặt đề xuất `REDUCE` và nhãn "Đơn vị chưa phản hồi" cho tổ chức quá `accessReview.noResponseDays`; nhắc lần hai sau 14 ngày; khi mọi tổ chức đã đáp hoặc hết hạn, kỳ sang `DECIDING`.

*Quyết định.* `AccessReviewService.decide` kiểm lý do, xác thực lại hai yếu tố cho `REVOKE_SCOPE`, và không cho giữ mục có căn cứ hết hiệu lực (ERR-01-041); khi thu hồi hoặc thu hẹp phạm vi đang có đăng ký sử dụng hoạt động, hệ thống liệt kê đăng ký bị ảnh hưởng và yêu cầu xác nhận. Cập nhật `ScopeCeiling` và phát EVT-01-11 để PH-02 hủy hoặc thu hẹp đăng ký vượt trần rồi gọi API-12-068 thay tập scope của client (PH-12 không nghe EVT-01-11). Mục cuối cùng có quyết định thì kỳ `CLOSED`, ghi `last_review_at` cho từng HTTT, phát EVT-01-12; bằng chứng giữ 5 năm (NFR-01-022).

*Căn cứ hết hiệu lực.* `LegalValidityChecker` chạy hằng ngày lúc 05:30 và khi mở kỳ: mục trần `ACTIVE` có `valid_until` đã qua hoặc bị TA, SO đánh dấu "văn bản bị bãi bỏ" (API-01-073, cần số hiệu và ngày) chuyển `SUSPENDED` với lý do `LEGAL_EXPIRED`, phát EVT-01-11 một lần (mục đã `SUSPENDED` bị bỏ qua), nhắc trước 30 ngày. Toàn bộ trần cùng hết hiệu lực thì đề nghị TA tạm ngừng HTTT thay vì từng mục (BR-01-015).

### 4.13. Danh bạ đầu mối

::: dac-ta
**Mục đích.** Cho cán bộ trong tenant tra đầu mối công khai của cơ quan hoặc HTTT; phát hiện tổ chức thiếu đầu mối kỹ thuật và nhắc cập nhật; xuất danh bạ có kiểm toán.

**Lớp chính.** `DirectoryService`, `DirectoryRateLimiter`, `GapDetector`, `StaleContactJob`, `DirectoryExporter`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-045, 046, 047 (Đợt 2).

**Giao diện vào.** API-01-076…079; UI-01-14; UC-01-30, 31.

**Phụ thuộc ra.** Valkey (giới hạn tốc độ), `Ph20Port`, `NotifyPort`.

**Dữ liệu.** `contact` (`is_public`, `status`, `last_confirmed_at`, `search_text`).

**Sự kiện.** EVT-01-14 (phát hiện thiếu đầu mối).

**Lỗi và xử lý.** ERR-01-045 (429, kèm `Retry-After`), 001, 046; Valkey không khả dụng: giới hạn tốc độ chuyển sang bộ đếm cục bộ theo bản sao (nới hơn, không mở không giới hạn).

**Quan sát.** `onboarding_directory_queries_total{result}`, `onboarding_directory_gap_total`, số lượt vượt giới hạn theo người dùng (cho PH-13 phát hiện thu thập hàng loạt).
:::

Chi tiết thiết kế: `DirectoryService` chỉ trả đầu mối `ACTIVE` có `is_public` của tenant trong token; đầu mối `SECURITY` và đầu mối không công khai chỉ trả cho TA, SO (BR-01-027, quy tắc cơ sở OPA, không cần mã quyền riêng). `DirectoryRateLimiter` dùng cửa sổ trượt trong Valkey với khóa tạo bằng hàm tên chuẩn `dir:{tenant}:{userId}`, mặc định `directory.rateLimitPerMinute = 60` (ERR-01-045). Tra theo từ khóa dùng chỉ mục GIN `pg_trgm` trên `search_text`; tra theo tổ chức trả đầu mối của mọi HTTT cơ quan đó chủ quản. `GapDetector` (hằng ngày) tìm tổ chức có HTTT `ACTIVE` mà không còn đầu mối `TECHNICAL` hoạt động, phát EVT-01-14, gửi thư nhắc OR và TA; tổ chức đó bị chặn nộp hồ sơ mới ở quy tắc 5 của FR-01-011 (BR-01-013). `StaleContactJob` nhắc đầu mối chưa xác nhận quá `directory.staleMonths`; thư bị trả lại đánh dấu đầu mối `INACTIVE` (mục 4.11). Xuất danh bạ (Đợt 2) chạy bất đồng bộ, ghi kiểm toán xuất kèm bộ lọc.

### 4.14. Nhập HTTT từ hệ cũ

::: dac-ta
**Mục đích.** Chuyển hàng trăm Application (APIM), publisher, subscriber (Hub) của hệ cũ thành hồ sơ `DRAFT` có sẵn tên, vai trò, mã cũ, mà không mang theo bất kỳ thông tin xác thực nào.

**Lớp chính.** `LegacyImportService`, `LegacyFileParser`, `ColumnMapper`, `SecretLikeDetector`, `OrgMatcher`, `RoleMerger`, `LegacyImportJob`.

**Đơn vị chạy.** `dh-connect`, tác vụ nền.

**FR hiện thực.** FR-01-048.

**Giao diện vào.** API-01-080 (tải, xem trước), 081 (trạng thái), 082 (xác nhận); UI-01-15; UC-01-32. Đã chốt 27/11/2026: giữ API nhập riêng này; khi PH-18 chốt khung API nhập chung, API nhận thêm tiêu đề `X-Datahub-Migration: true` và khóa lũy đẳng `legacySystem:objectType:legacyKey`, PH-18 gọi qua API nhập riêng của PH-01.

**Phụ thuộc ra.** `AttachmentService` (kiểm kiểu, quét), `Ph20Port` (ghép tổ chức), `TaskInboxApi`.

**Dữ liệu.** `legacy_import_job` (kết quả xem trước, băm tệp), `member_system.legacy_ref` (chỉ mục duy nhất trong tenant).

**Sự kiện.** Không (mỗi hồ sơ tạo ra phát EVT-01-03 `DRAFT` như hồ sơ thường).

**Lỗi và xử lý.** ERR-01-042 (tệp sai cấu trúc), 043 (trùng, bỏ qua từng dòng), 044 (quá số dòng); tệp có giá trị giống bí mật ở cột không khai báo: bỏ giá trị, ghi cảnh báo.

**Quan sát.** `onboarding_legacy_import_rows_total{result}`, `onboarding_legacy_import_secrets_dropped_total`.
:::

Chi tiết thiết kế: theo ADR-056, nhập hai pha. Pha 1 (`POST /legacy-imports`): tệp qua kiểm kiểu và quét như mục 4.3, rồi `LegacyFileParser` đọc theo luồng (CSV, XLSX bằng SAX, JSON) với giới hạn `legacyImport.maxRows` (5.000) và `ColumnMapper` chỉ đọc đúng các cột trong bảng ánh xạ của FR-01-048; **cột thông tin xác thực không bao giờ được đọc vào bộ nhớ ứng dụng**, chỉ đếm số cột bị bỏ. `SecretLikeDetector` quét các cột còn lại tìm giá trị giống khóa (độ dài ≥ 20 và entropy Shannon ≥ 3,5 bit mỗi ký tự, hoặc khớp mẫu khóa API phổ biến) và bỏ giá trị, ghi cảnh báo "Phát hiện giá trị có thể là bí mật ở cột {tên}". `OrgMatcher` chuẩn hóa tên (bỏ dấu, viết thường, bỏ tiền tố "Sở", "UBND") rồi ghép với danh mục PH-20 theo độ giống `pg_trgm` ≥ 0,8, dưới ngưỡng thì để "Chọn tổ chức"; `RoleMerger` gộp bản ghi trùng giữa ba nguồn theo `legacy_ref` hoặc tên chuẩn hóa thành một HTTT nhiều vai trò. Kết quả (số tạo, trùng, cảnh báo, số bí mật bỏ) lưu ở `legacy_import_job` ở trạng thái `PREVIEWED`; tệp gốc xóa sau 7 ngày, chỉ giữ băm.

Pha 2 (`:confirm`): một giao dịch tạo mọi hồ sơ `DRAFT` hoặc không tạo gì ("ghi tất cả hoặc không"), gắn `legacy_ref`, gán việc cho OR của tổ chức, ghi kiểm toán (người nhập, số bản ghi, băm tệp, số bí mật bỏ). Nhập lại cùng tệp bỏ qua HTTT đã có nhờ chỉ mục duy nhất `(tenant_id, legacy_ref)`. Vòng đời tác vụ: `UPLOADED → PARSING → PREVIEWED → CONFIRMED → DONE`, hoặc `FAILED`, `CANCELLED`. Đồng thời cờ `onboarding.legacy-import.enabled` tắt được cả chức năng sau giai đoạn chạy song song.

### 4.15. Tham số, thống kê và tác vụ định kỳ

::: dac-ta
**Mục đích.** Cung cấp tham số `onboarding.*` theo tenant với miền kiểm tra ở hai nơi; chỉ số vận hành theo NFR-01-015; và một khung duy nhất chạy mọi tác vụ định kỳ có phân tách tenant, khóa phân tán và theo dõi.

**Lớp chính.** `OnboardingSettings`, `SettingsService`, `StatisticsService`, `MetricsRegistrar`, `JobCatalog`, `TenantJobRunner`, `TenantRegistry`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-01-049, 051 (Đợt 2); nền cho FR-01-009, 016, 027, 036, 039, 041, 043, 046.

**Giao diện vào.** API-01-083, 084, 086; UI-01-16, 17; UC-01-33, 34.

**Phụ thuộc ra.** `ParameterApi` (PH-18), `Ph20Port` (danh sách tenant), ShedLock trên `pg-core`, OpenFeature.

**Dữ liệu.** `shedlock`, `stat_onboarding_daily` (khung nhìn vật chất hóa, Đợt 2).

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-01-044 (tham số vượt miền hoặc trần của PA), 033 (thiếu lý do); tham số không đọc được: dùng bản đệm 60 giây rồi giá trị mặc định; một tenant lỗi không làm dừng tenant khác.

**Quan sát.** `onboarding_job_duration_seconds{job}`, `onboarding_job_failures_total{job}`, `onboarding_job_last_success_timestamp{job}`.
:::

Chi tiết thiết kế:

*Tham số.* `OnboardingSettings` bọc `ParameterApi` với kiểu có miền (khai báo một lần, trùng bảng FRS §8.2): đọc có đệm 60 giây; ghi (API-01-084) cần `PERM-18-config` và lý do, kiểm miền và trần do PA đặt (ERR-01-044), ghi kiểm toán khóa, giá trị cũ, giá trị mới. Tham số đổi có hiệu lực ngay với thao tác mới và không áp ngược vào hạn đã tính cho bước thẩm định đang chạy (hạn gốc giữ trong `review_step.due_at`).

*Khung tác vụ.* Mỗi tác vụ định kỳ đăng ký ở `JobCatalog` với tên, lịch và hạn khóa; `TenantJobRunner` lấy danh sách tenant hoạt động từ `TenantRegistry` (PH-20, đệm 60 giây), chạy tuần tự từng tenant trong `TenantContext.runAs(tenant, job)` (D03-10 §6) kèm độ trễ ngẫu nhiên ≤ 30 giây để không dồn tải, tách lỗi theo tenant. Tác vụ định kỳ chỉ chạy ở một bản sao nhờ ShedLock (D03-09 §6.2); hai bộ chạy việc theo hàng (saga, cắt quyền) dùng `SKIP LOCKED` để cả hai bản sao cùng làm.

| Tác vụ | Lịch (cấu hình được) | Cơ chế | FR |
|---|---|---|---|
| `SagaRunner` | 2 giây | `SKIP LOCKED` | 020, 024 |
| `EnforcementRetryJob` | 10 giây | `SKIP LOCKED` | 026, 029, 032 |
| `HandoverRecoveryJob`, `RotationFinisher` | 1 phút | ShedLock | 022, 025 |
| `SandboxTestService.collect` | 5 phút | ShedLock | 023 |
| `EmergencyConfirmationJob` | 5 phút | ShedLock | 032 |
| `EscalationJob` | 15 phút | ShedLock | 016 |
| `SnapshotPublisher` | mỗi giờ | ShedLock | 037 |
| `InactivityJob` (Đợt 2) | 04:30 hằng ngày | ShedLock | 036 |
| `ExpiryJob` | 05:00 hằng ngày | ShedLock | 027 |
| `LegalValidityChecker` | 05:30 hằng ngày | ShedLock | 043 |
| `GapDetector`, `StaleContactJob` | 06:00 hằng ngày | ShedLock | 046 |
| `AccessReviewScheduler`, `NoResponseJob` | 06:30 hằng ngày | ShedLock | 039, 041 |
| `DraftCleaner` | 02:00 hằng ngày | ShedLock | 009 |
| `OutboxPurge`, `AttachmentReconciler` | 03:00 hằng ngày | ShedLock | 037, 005 |

: Tác vụ định kỳ của PH-01

*Thống kê.* Bộ đo `MetricsRegistrar` đăng ký các chỉ số ở chương 10. Chỉ số kiểu gauge được tính bằng truy vấn tổng hợp mỗi 60 giây (không tính theo yêu cầu); số liệu cho UI-01-17 (Đợt 2) đọc từ khung nhìn vật chất hóa `stat_onboarding_daily` làm mới mỗi giờ, để màn thống kê không quét bảng nghiệp vụ.

### 4.16. Cổng tích hợp ra ngoài

::: dac-ta
**Mục đích.** Gom mọi lời gọi ra PH-12, PH-03, OpenBao, PH-02, PH-13, PH-14, PH-18, PH-20 vào một lớp để thời gian chờ, thử lại, ngắt mạch, dịch lỗi và bản giả cho kiểm thử nằm một chỗ.

**Lớp chính.** `Ph12Port`, `Ph03Port`, `Ph02Port`, `Ph13Port`, `Ph14Port`, `Ph20Port`, `NotifyPort`, `OpenBaoPort`, `ServiceTokenProvider`, `PortErrorMapper`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** Hỗ trợ mọi FR có gọi ngoài (020, 021, 022, 024, 025, 026, 029…033, 040, 041, 043).

**Giao diện vào.** Gọi nội bộ từ các thành phần nghiệp vụ.

**Phụ thuộc ra.** Các hệ ở trên; Keycloak (token dịch vụ).

**Dữ liệu.** Không (bộ đệm tổ chức, danh mục, lịch ở bộ nhớ và Valkey).

**Sự kiện.** Không.

**Lỗi và xử lý.** Dịch về `TransientPortException`, `BusinessPortException`, `UnavailablePortException`; ánh xạ ERR-01-021, 022, 023, 046.

**Quan sát.** `onboarding_port_calls_total{port,op,result}`, `onboarding_port_duration_seconds{port,op}`, trạng thái ngắt mạch.
:::

Chi tiết thiết kế: bộ chuyển REST dùng `RestClient` của Spring cộng Resilience4j. Token dịch vụ lấy bằng `client_credentials` của tài khoản `dh-connect` (không chuyển tiếp token người dùng, FRS §3.3), đệm tới trước hạn 30 giây; scope theo từng cổng. `Idempotency-Key` bắt buộc ở mọi lệnh ghi sang PH-12, PH-03. Với phần control của PH-03 và PH-02 cùng DU, bộ chuyển trong tiến trình gọi `gateway.api.ConsumerGatewayApi`, `catalog.api.ServiceUsageApi` (chọn bằng `@ConditionalOnBean`), còn bộ chuyển REST dành cho hồ sơ triển khai tách DU (Q01-26). `PortErrorMapper` dịch mã HTTP và lỗi mạng: `408`, `429`, `5xx`, mất kết nối là tạm thời; `409` của PH-12 với mã client trùng là nghiệp vụ (ERR-01-022); `4xx` khác là nghiệp vụ. Lớp này không chứa quy tắc nghiệp vụ; mọi quyết định thử lại thuộc `SagaRunner`, `EnforcementRetryJob` hoặc người dùng.

## 5. Biểu đồ tuần tự

Chương này vẽ bảy luồng phức tạp nhất: các luồng có từ ba thành phần trở lên, có bốn mắt hoặc có thao tác không thể đảo ngược. Mỗi hình kèm đoạn nói rõ ranh giới giao dịch, nơi kiểm tra ở máy chủ và điều xảy ra khi một bước hỏng. Ví dụ dùng tenant `T68`, HTTT `ndxp-ho-tich`.

### 5.1. Nộp hồ sơ, thẩm định song song, phê duyệt và xếp việc cấp định danh (FR-01-012, 013, 014, 016, 018)

Sơ đồ dưới mô tả nộp hồ sơ, thẩm định song song, phê duyệt và xếp việc cấp định danh (FR-01-012, 013, 014, 016, 018).

```{.mermaid caption="Nộp hồ sơ, thẩm định song song, phê duyệt và xếp saga (FR-01-012, 013, 014, 016, 018)"}
sequenceDiagram
  autonumber
  actor OR as An (OR)
  participant BFF
  participant SUB as SubmissionService
  participant REV as ReviewService
  participant OPA
  participant DB as pg-core ph01_onboarding
  actor TA as Bình (TA)
  actor IE as Chi (IE)
  actor SO as Dũng (SO)
  OR->>BFF: POST /systems/ndxp-ho-tich:submit If-Match 7
  BFF->>SUB: chuyển tiếp, token người dùng
  SUB->>DB: nạp hồ sơ, 13 kiểm tra
  SUB->>DB: DRAFT sang SUBMITTED, 3 review_step, outbox EVT-01-01, 03
  SUB-->>OR: 200 SUBMITTED
  SUB->>TA: việc Phân công thẩm định
  TA->>REV: reviews:assign IE kỹ thuật, SO ATTT, TA pháp lý
  par Kỹ thuật
    IE->>REV: POST reviews/technical nhóm 2, xác thực JWT
    REV->>OPA: actor, stepType, assigneeId, createdBy
    OPA-->>REV: allow
    REV->>DB: ghi kết luận, outbox EVT-01-02
  and ATTT
    SO->>REV: POST reviews/security
    REV->>DB: ghi kết luận, outbox EVT-01-02
  and Pháp lý
    TA->>REV: POST reviews/legal từng mục APPROVED, NARROWED, REJECTED
    REV->>DB: ghi verdict từng DataDemand
  end
  TA->>REV: POST :approve, MFA mới trong 5 phút
  REV->>REV: FourEyesGuard, kiểm ba bước DONE
  REV->>DB: tx APPROVED PROVISIONING, scope_ceiling, saga PENDING, outbox EVT-01-03, 11
  REV-->>TA: 200 APPROVED
  Note over REV,DB: SagaRunner nhận việc trong 2 giây
```

Ba bước thẩm định chạy song song và độc lập; mỗi lệnh ghi là một giao dịch ngắn, nên hai người thẩm định hai phần không chờ nhau, chỉ tranh chấp ở khóa lạc quan của `member_system` khi cùng cập nhật `reviewStage`. Phê duyệt là giao dịch duy nhất sinh trần phạm vi, đổi trạng thái và chèn dòng saga, nên không thể có hồ sơ "đã duyệt mà không ai cấp định danh". `FourEyesGuard` chạy trong aggregate lúc phê duyệt, độc lập với OPA ở bước ghi kết luận: nếu chính sách Rego sai thì vi phạm bốn mắt vẫn bị chặn ở ERR-01-017.

### 5.2. Saga cấp định danh SANDBOX có bù trừ và thử lại (FR-01-020)

Sơ đồ dưới mô tả saga cấp định danh SANDBOX có bù trừ và thử lại (FR-01-020).

```{.mermaid caption="Saga cấp định danh SANDBOX có bù trừ và thử lại (FR-01-020)"}
sequenceDiagram
  autonumber
  participant SR as SagaRunner
  participant DB as pg-core
  participant P12 as PH-12
  participant OB as OpenBao
  participant P3 as PH-03
  participant HO as HandoverService
  participant PH18 as PH-18
  SR->>DB: SELECT saga PENDING FOR UPDATE SKIP LOCKED
  SR->>DB: step RECORD, credential chờ
  SR->>DB: step CLIENT RUNNING, commit
  SR->>P12: createClient Idempotency-Key sagaId:CLIENT
  P12->>OB: ghi bí mật kv/dh/T68/clients/ndxp-ho-tich/sandbox
  P12-->>SR: clientId, secretRef
  SR->>DB: step CLIENT DONE, lưu secretRef
  SR->>P3: createConsumer Idempotency-Key sagaId:CONSUMER
  alt PH-03 lỗi
    P3-->>SR: 503
    SR->>P12: bù trừ xóa client
    P12->>OB: hủy bí mật
    SR->>DB: saga WAITING_RETRY next_run_at +1 phút
  else Thành công
    P3-->>SR: consumerId
    SR->>DB: tx FINALIZE ACTIVE, SANDBOX_READY, outbox EVT-01-05
    SR->>HO: tạo bàn giao CLIENT_SECRET
    HO->>PH18: thư chứa liên kết, không bí mật
  end
```

Mỗi lời gọi ngoài nằm ngoài giao dịch CSDL: bước được ghi `RUNNING` và commit trước khi gọi, kết quả ghi sau khi gọi, nên không giữ khóa hàng khi chờ mạng và tiến trình chết giữa chừng chỉ để lại một bước `RUNNING` quá hạn mà bộ chạy gọi lại bằng cùng khóa lũy đẳng. Bù trừ theo thứ tự ngược chỉ chạy cho bước đã tạo thứ gì; lần thử lại dùng đúng `sagaId` nên PH-12 trả lại client đã tạo thay vì tạo trùng (Q01-20). Thư bàn giao nằm sau `FINALIZE` và không bù trừ được (thư đã gửi), nên lỗi gửi thư chỉ thử lại riêng, không phá định danh đã cấp.

### 5.3. Bàn giao và mở một lần (FR-01-022)

Sơ đồ dưới mô tả bàn giao và mở một lần (FR-01-022).

```{.mermaid caption="Bàn giao và mở một lần thông tin xác thực (FR-01-022)"}
sequenceDiagram
  autonumber
  actor DM as Đầu mối kỹ thuật
  participant BFF
  participant KC as Keycloak
  participant HG as HandoverGuard
  participant DB as pg-core
  participant OB as OpenBao
  participant K as Kafka
  HG->>OB: đọc kv clients sandbox kèm X-Vault-Wrap-TTL 24h
  OB-->>HG: mã bọc, accessor
  HG->>DB: link_hash, wrap_accessor, wrap_token_sealed bằng transit
  DM->>BFF: mở /ket-noi/ban-giao/token từ thư
  BFF->>KC: đăng nhập, MFA mới
  KC-->>BFF: phiên, sub, acr, auth_time
  BFF->>HG: POST /handovers:open token
  HG->>DB: băm token, kiểm PENDING, hạn, sub đúng đầu mối
  HG->>DB: PENDING sang OPENING chiếm chỗ
  HG->>OB: unwrap mã bọc, một lần
  OB-->>HG: clientId, clientSecret
  HG->>DB: OPENED, người mở, IP, xóa wrap_token_sealed
  HG->>OB: destroy mọi phiên bản bản sao
  HG->>K: outbox EVT-01-09
  HG-->>DM: 200 Cache-Control no-store, hiển thị một lần
```

Hình cho thấy ba điều. Một: PH-01 chưa bao giờ đọc được bí mật ở dạng rõ trước bước 11, vì chính sách OpenBao buộc mọi lần đọc bị bọc. Hai: mở bàn giao có chiếm chỗ bằng một câu `UPDATE … WHERE status = 'PENDING'`, nên hai người mở đồng thời không thể cùng thấy bí mật. Ba: sai người mở (kiểm ở bước 8) không chạm tới OpenBao, nên liên kết lộ ra ngoài không tiêu hao bí mật; chỉ tăng `failed_attempts` ở giao dịch riêng và phát EVT-01-10 tới SO. Nếu tiến trình chết giữa bước 9 và 12, `HandoverRecoveryJob` chuyển bàn giao `CANCELLED` và yêu cầu xoay vòng (mục 4.7).

### 5.4. Tạm ngừng, thao tác khẩn và cắt quyền trong 60 giây (FR-01-029, 032, 037)

Sơ đồ dưới mô tả tạm ngừng, thao tác khẩn và cắt quyền trong 60 giây (FR-01-029, 032, 037).

```{.mermaid caption="Thao tác khẩn của Cán bộ ATTT và cắt quyền trong 60 giây (FR-01-029, 032, 037)"}
sequenceDiagram
  autonumber
  actor SO as Dũng (SO)
  participant BFF
  participant LIF as EmergencyService
  participant DB as pg-core
  participant ENF as EnforcementExecutor
  participant P3 as PH-03 APISIX
  participant P12 as PH-12
  participant K as Kafka
  participant P10 as PH-10, PH-02
  actor TA as Bình (TA)
  SO->>BFF: POST :emergency-action SUSPEND, lý do, MFA
  BFF->>LIF: chuyển tiếp
  LIF->>DB: tx SUSPENDED, enforcement PENDING, emergency PENDING_CONFIRM, 4 việc, outbox EVT-01-03, 15
  LIF->>ENF: sau commit chạy việc 1
  ENF->>P3: blockClients, hạn 5 giây
  P3-->>ENF: đã ghi etcd
  LIF-->>SO: 200 SUSPENDED, enforcement PENDING
  ENF->>P12: disableClients, revokeTokens
  P12-->>ENF: xong
  ENF->>P3: disableConsumer
  P3-->>ENF: xong
  ENF->>DB: enforcement DONE
  DB->>K: Debezium EVT-01-03 state-changed
  K->>P10: tạm ngừng bên phát, bên nhận, đăng ký sử dụng
  TA->>BFF: POST emergency-actions/id:confirm trong 24 giờ
  BFF->>DB: CONFIRMED nếu TA khác SO
```

Thứ tự là điểm cốt lõi: trạng thái được đặt và lệnh chặn ở cổng đi trước, rồi mới gọi PH-12. Nếu bước 8 hay 10 lỗi, việc nằm lại bảng `enforcement_task` và `EnforcementRetryJob` chạy lại tới khi xong; trạng thái `SUSPENDED` không bao giờ bị hoàn tác vì lỗi hệ phụ thuộc (BR-01-023). Xác nhận bổ sung của TA là bước độc lập, không chặn hiệu lực; quá 24 giờ chưa xác nhận chỉ sinh cảnh báo (BR-01-010). Sự kiện EVT-01-03 đi qua outbox sau commit nên PH-10 và PH-02 nhận đúng một lần, đúng thứ tự theo `systemCode`.

### 5.5. Kiểm thử SANDBOX và kích hoạt PRODUCTION (FR-01-023, 024)

Sơ đồ dưới mô tả kiểm thử SANDBOX và kích hoạt PRODUCTION (FR-01-023, 024).

```{.mermaid caption="Kiểm thử SANDBOX và kích hoạt PRODUCTION (FR-01-023, 024)"}
sequenceDiagram
  autonumber
  participant TS as SandboxTestService
  participant P13 as PH-13
  participant DB as pg-core
  actor TA as Bình (TA)
  participant ACT as ActivationService
  participant SR as SagaRunner
  participant P12 as PH-12
  participant P3 as PH-03
  loop mỗi 5 phút
    TS->>P13: sandboxActivity clientId, since
    P13-->>TS: xác thực 12, gọi thành công 4, lỗi nổi bật
    TS->>DB: sandbox_test, readyToActivate khi đạt
  end
  TS->>TA: thông báo HTTT đã kiểm thử đạt
  TA->>ACT: POST :activate, MFA mới
  ACT->>ACT: FourEyesGuard khác người nộp, kiểm điều kiện
  ACT->>DB: saga PRODUCTION completeWith ACTIVATE
  ACT->>SR: chạy lượt đầu, hạn 10 giây
  SR->>P12: createClient PRODUCTION
  SR->>P3: createConsumer PRODUCTION, hạn mức đã thẩm định
  SR->>DB: tx FINALIZE, APPROVED sang ACTIVE, outbox EVT-01-05, 03
  ACT-->>TA: 200 ACTIVE hoặc 202 theo dõi tiến độ
```

Kích hoạt tái dùng đúng bộ máy saga của mục 5.2: khác ở môi trường, hạn mức và cờ `completeWith`. Chuyển `APPROVED → ACTIVE` nằm trong giao dịch `FINALIZE`, nên HTTT chỉ `ACTIVE` khi định danh PRODUCTION đã có thật. Lỗi PH-12 hoặc PH-03 giữ HTTT ở `APPROVED` và saga thử lại; người gọi nhận `202` thay vì chờ vô hạn.

### 5.6. Xoay vòng bí mật có thời gian chuyển tiếp (FR-01-025)

Sơ đồ dưới mô tả xoay vòng bí mật có thời gian chuyển tiếp (FR-01-025).

```{.mermaid caption="Xoay vòng bí mật có thời gian chuyển tiếp (FR-01-025)"}
sequenceDiagram
  autonumber
  actor TA as Bình (TA)
  participant ROT as RotationService
  participant P12 as PH-12
  participant OB as OpenBao
  participant HO as HandoverService
  actor DM as Đầu mối kỹ thuật
  participant FIN as RotationFinisher
  participant P3 as PH-03
  TA->>ROT: POST credentials/id:rotate, lý do, MFA
  ROT->>ROT: kiểm ACTIVE, không đang ROTATING
  ROT->>P12: startSecretRotation, giữ bí mật cũ
  P12->>OB: ghi bí mật mới
  P12-->>ROT: secretRef mới
  ROT->>DB: ROTATING, rotation_ends_at +7 ngày, outbox EVT-01-06
  ROT->>HO: tạo bàn giao một lần
  DM->>HO: mở liên kết, nhận bí mật mới, đổi cấu hình
  Note over P12,P3: hai bí mật cùng hiệu lực tới rotation_ends_at
  FIN->>DB: tìm ROTATING hết hạn mỗi phút
  FIN->>P12: gỡ bí mật cũ
  FIN->>OB: hủy phiên bản cũ
  FIN->>P3: gỡ dấu vân tay cũ nếu có
  FIN->>DB: ACTIVE, expires_at tính lại, outbox EVT-01-06
```

Trong thời gian chuyển tiếp hai thông tin cùng hiệu lực nên HTTT đổi cấu hình không gián đoạn (BR-01-021). Chỉ `RotationFinisher` mới gỡ thông tin cũ, và chỉ khi đến hạn hoặc người dùng bấm kết thúc; lỗi ở bước gỡ để định danh ở `ROTATING` và thử lại phút sau, không để HTTT mất cả hai. Xoay khẩn đặt chuyển tiếp 0 ngày nên bước gỡ chạy ngay trong cùng yêu cầu.

### 5.7. Kỳ rà soát quyền định kỳ (FR-01-039…043)

Sơ đồ dưới mô tả kỳ rà soát quyền định kỳ (FR-01-039…043).

```{.mermaid caption="Kỳ rà soát quyền định kỳ (FR-01-039…043)"}
sequenceDiagram
  autonumber
  participant SCH as AccessReviewScheduler
  participant ARS as AccessReviewService
  participant UA as UsageAggregator
  participant P13 as PH-13
  participant P2 as PH-02
  participant CS as ConfirmationService
  actor OR as Đại diện đơn vị (OR)
  participant NR as NoResponseJob
  actor TA as Bình (TA)
  participant K as Kafka
  SCH->>ARS: HTTT quá 6 tháng chưa rà soát, mở kỳ RS-2026-02
  ARS->>ARS: sinh mục cho mỗi cặp HTTT, mục trần
  ARS->>UA: tổng hợp, tối đa 8 lời gọi đồng thời
  UA->>P2: API và scope theo dataType
  UA->>P13: lượt gọi thành công theo định danh
  UA->>ARS: usageInPeriod, unusedDays, cờ
  ARS->>CS: gửi xác nhận theo tổ chức
  CS->>OR: thư chứa liên kết, kỳ WAITING
  OR->>CS: đăng nhập, trả lời KEEP, REDUCE, RELEASE từng mục
  NR->>ARS: sau 30 ngày chưa đáp, đề xuất REDUCE
  ARS->>TA: kỳ DECIDING, việc xử lý kết quả
  TA->>ARS: decide từng mục, lý do, MFA cho REVOKE_SCOPE
  ARS->>K: outbox EVT-01-11 trần đổi
  K->>P2: hủy, thu hẹp đăng ký sử dụng vượt trần
  ARS->>K: EVT-01-12 khi đóng kỳ
```

Kỳ rà soát đi một chiều từ `OPEN` đến `CLOSED`, mỗi bước chuyển ghi một dòng lịch sử. Tổng hợp mức dùng là bước duy nhất phụ thuộc hai phân hệ khác nên được giới hạn đồng thời và cho phép thiếu một phần; thiếu số liệu chỉ làm mục hiện "Chưa có số liệu", không bao giờ làm đề xuất thu hồi nhầm. Quyết định thu hồi chỉ thay đổi trần phạm vi và phát sự kiện: việc hủy đăng ký sử dụng và thay tập scope của client (API-12-068) do PH-02 làm khi nhận EVT-01-11, đúng ranh giới phạm vi.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph01_onboarding` có `tenant_id NOT NULL` và `FORCE ROW LEVEL SECURITY`; vai trò ứng dụng không có `BYPASSRLS` và không là chủ bảng (SEC-81, D03-03-PH01). `TenantContextFilter` của `dh-connect` đặt `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch từ token đã xác minh (D03-10 §3), không từ tham số, tiêu đề hay thân yêu cầu (SEC-80). Quy tắc riêng của PH-01:

- **Tác vụ định kỳ** chạy qua `TenantJobRunner` bọc `TenantContext.runAs(tenant, …)` (D03-10 §6, quy tắc 5); không tác vụ nào chạy "không tenant". Bộ chạy saga và cắt quyền lặp theo từng tenant, mỗi tenant một truy vấn `SKIP LOCKED` riêng.
- **Định danh tên có tenant.** Mọi tên tạo ra dùng hàm tạo tên của thư viện dùng chung: đường dẫn OpenBao `kv/dh/{tenant}/clients/…`, khóa transit `dh-{tenant}-handover`, bucket `dh-{tenant}-onboarding`, topic `{tenant}.connect.*`, khóa Valkey `dir:{tenant}:{userId}`; không ghép chuỗi tay (D03-10 §6, quy tắc 4). Chính sách OpenBao sinh theo tenant nên một lỗi mã không đọc nhầm bí mật tỉnh khác (SEC-82).
- **Điểm vào không đăng nhập.** PH-01 không có API công khai không xác thực: trang bàn giao (UI-01-09) và phiếu xác nhận (UI-01-13) đều bắt đăng nhập, nên tenant lấy từ token; liên kết chỉ là bằng chứng một lần, không mang tenant. Callback của PH-12, PH-03 dùng token dịch vụ mang `tenant` (SEC-80).
- **Đối tượng khác tenant hoặc ngoài phạm vi vai trò** trả `404` cùng thân với "không tồn tại" (BR-01-030, D03-10 §6 quy tắc 6). Ca kiểm thử rò rỉ chéo tenant có cho mọi API đọc, kể cả API nội bộ (mục 12).
- **Tenant `COMMON`** không có HTTT thành viên; nhu cầu HTTT cấp bộ, ngành, nhà cung cấp ngoài tỉnh (Q01-11) do TA tenant nhập hộ, không ghi vào `COMMON`.
- **Bản sao nhận ở phân hệ khác** chứa `tenant_id` và chịu RLS của phân hệ đó; sự kiện đi trên topic của đúng tenant, ACL Kafka theo tiền tố tenant (SEC-82).

## 7. Bảo mật

Thiết kế dẫn các biện pháp đã có ở D03-07, không tạo mã `SEC-*` mới. Bảng sau nêu rủi ro, biện pháp cụ thể trong mã của PH-01 và mã SEC liên quan.

| Rủi ro | Biện pháp trong thiết kế | SEC |
|---|---|---|
| Lộ bí mật qua CSDL, log, vết, phản hồi, tệp xuất, thư | Không cột bí mật (xóa `client_secret_sealed`); chính sách OpenBao buộc bọc khi đọc; `Secret` đánh dấu `@Sensitive`; ArchUnit cấm log và cấm gọi `unwrap` ngoài `HandoverService`; ca kiểm thử canary `DH-CANARY-…` (NFR-01-009) | SEC-33, SEC-32 |
| Bàn giao bị đánh cắp hoặc dùng lại | Liên kết 256 bit chỉ lưu băm; một lần; đăng nhập đúng tài khoản đầu mối với MFA mới; khóa sau `handover.maxFailedOpens` lần sai; thân phản hồi `no-store` | SEC-23, SEC-33 |
| Xác thực máy yếu so với mức dữ liệu | `CredentialService` chặn phương thức thấp hơn mức yêu cầu của phân loại cao nhất trong trần; khóa ES256 hoặc PS256 ≥ 3072 bit, chứng thư ký bằng `pki-clients` | SEC-24, SEC-35 |
| HTTT đã tạm ngừng vẫn gọi được | Chặn ở cổng trước, trạng thái đặt trước, thử lại tới khi xong; token sống 5 phút; thu hồi token | SEC-25 |
| Vượt quyền, vi phạm bốn mắt | `@PreAuthorize` theo `PERM-01-*` ở lớp `web`; OPA kiểm phân công, phạm vi tổ chức; `FourEyesGuard` kiểm lại trong aggregate; cặp loại trừ IE và IA | SEC-26 |
| Quyền tích tụ, tài khoản máy bỏ quên | Rà soát định kỳ theo mức dùng; tự vô hiệu định danh không dùng 90 ngày; hết hạn tối đa 12 tháng, chuỗi bí mật 180 ngày | SEC-27 |
| Tệp đính kèm độc hại | Kiểu theo nội dung (Tika), giới hạn kích thước, quét mã độc, bucket theo tenant, mã hóa SSE-C | SEC-45, SEC-30 |
| Đầu vào độc hại, lược đồ lỏng | Bean Validation sinh từ OpenAPI; thân ≤ 1 MB, độ sâu JSON ≤ 32; địa chỉ chỉ `https`, IP đúng CIDR; JSON Merge Patch chỉ trường được phép | SEC-43 |
| Trang bàn giao bị nhúng, lấy bí mật bằng giao diện | Tiêu đề CSP, `frame-ancestors 'none'` do BFF đặt; không cache | SEC-44 |
| Lộ dữ liệu cá nhân đầu mối | RLS, mã hóa tầng khối, che trong log, giới hạn tốc độ tra danh bạ, đầu mối `SECURITY` chỉ TA, SO; không đưa liên hệ vào sự kiện | SEC-32, SEC-37, SEC-10 |
| Đọc chéo tenant, dò tồn tại | Tenant chỉ từ token; RLS bắt buộc; `404` cùng thân; chính sách OpenBao, ACL Kafka theo tenant | SEC-80, SEC-81, SEC-82 |
| Không truy vết được quyết định | Kiểm toán cùng giao dịch cho mọi quyết định thẩm định, phê duyệt, thao tác vòng đời; chuỗi băm, WORM 5 năm | SEC-60, SEC-62 |
| Thiếu bằng chứng sự cố | Log JSON có `traceId`, `tenant`; sự kiện an ninh EVT-01-10, 15 tới PH-13 và SIEM | SEC-61 |
| Mất mặt phẳng điều khiển | Hai bản sao, saga và outbox bền trong CSDL, đối chiếu hằng giờ; RPO ≤ 1 giờ, RTO ≤ 4 giờ | SEC-71 |

: Bảo mật của PH-01

*Kiểm tra quyền ở máy chủ.* Mỗi API ghi hay đọc có `@PreAuthorize("hasAuthority('PERM-01-…')")` ở lớp `web` làm lớp thô; lớp tinh do PEP gọi OPA với phạm vi tổ chức và phân công, và aggregate kiểm lại bốn mắt, trạng thái. Giao diện ẩn nút chỉ là tiện ích, không là lớp bảo vệ.

| Quyền | Hành động được bảo vệ | Quy tắc OPA đi kèm |
|---|---|---|
| `PERM-01-read` | Xem hồ sơ, đầu mối, định danh (không bí mật), tiến độ, xuất | OR chỉ `owner_org_id` của mình; DO chỉ hồ sơ có dữ liệu của tổ chức mình; xuất toàn tenant chỉ TA, AU, PA |
| `PERM-01-create` | Lập, sửa hồ sơ nháp, đầu mối, đề nghị thay đổi, mở rộng phạm vi | OR chỉ tổ chức của mình; TA lập thay đơn vị |
| `PERM-01-submit` | Nộp, nộp lại, rút | Người nộp thuộc tổ chức đã khai (ERR-01-006) |
| `PERM-01-approve` | Phê duyệt, từ chối, phân công, duyệt thay đổi, xác nhận khẩn, kích hoạt | Không phải người lập, nộp, thẩm định, đề nghị chấm dứt (ERR-01-017) |
| `PERM-01-credential` | Cấp, xoay, thu hồi, bật lại định danh; tạo lại bàn giao; đăng ký khóa, CSR | OR chỉ định danh của tổ chức mình |
| `PERM-01-suspend` | Tạm ngừng, khôi phục, chấm dứt, thu hồi khẩn, rà soát quyền | SO, TA; AU, VW chỉ xem kết quả |
| `PERM-18-config` | Sửa tham số `onboarding.*` | TA, PA; không vượt trần PA |
| `PERM-18-migration` | Nhập từ hệ cũ | TA, PA, PO |
| Quyền cơ sở người dùng nội bộ | Tra danh bạ đầu mối công khai | Đầu mối `SECURITY` chỉ TA, SO |
| Token dịch vụ `onboarding:internal-read`, `provision-callback`, `reconcile` | API nội bộ, callback saga, đối chiếu | Kiểm `azp` và `tenant` của token; không cấp cho người |

: Quyền và nơi kiểm tra ở máy chủ

PH-01 không tự gọi `baseUrl` hay địa chỉ IP của HTTT (chỉ lưu và kiểm dạng), nên không có đường SSRF qua các trường này; việc thăm dò kết nối thuộc PH-05, nơi áp dụng kiểm soát lưu lượng ra theo FQDN (SEC-16).

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Phân hệ có 11 máy trạng thái. Mỗi máy là một enum cộng danh sách `Transition` khai báo một lần trong `TransitionTable` (mục 4.9); cột "Kiểm ở máy chủ" là phần bảo vệ (guard) chạy trong aggregate trước khi áp dụng. Mọi chuyển ghi `state_history`, kiểm toán và outbox trong cùng giao dịch (BR-01-031); chuyển không có trong bảng trả ERR-01-005.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| `MemberSystem.status` | (mới) | tạo | `DRAFT` | `PERM-01-create`, mã chưa dùng kể cả HTTT đã chấm dứt (ERR-01-002) |
| `MemberSystem.status` | `DRAFT` | submit | `SUBMITTED` | 13 kiểm tra đạt, người nộp thuộc tổ chức, `If-Match` |
| `MemberSystem.status` | `SUBMITTED` | return, withdraw | `DRAFT` | Return: lý do, người thẩm định hoặc TA; withdraw: OR, TA, lý do |
| `MemberSystem.status` | `SUBMITTED` | approve | `APPROVED` | Ba bước `DONE`, bốn mắt, MFA mới, `confirmedGroup`, phương thức xác thực đạt |
| `MemberSystem.status` | `SUBMITTED` | reject | `REJECTED` | Lý do, bốn mắt, MFA mới; trạng thái cuối |
| `MemberSystem.status` | `DRAFT` | delete | (xóa mềm) | Chưa từng nộp (BR-01-011) |
| `MemberSystem.status` | `APPROVED` | activate | `ACTIVE` | `readyToActivate`, khác người nộp, MFA mới; chỉ trong giao dịch `FINALIZE` của saga PRODUCTION |
| `MemberSystem.status` | `APPROVED` | terminate | `TERMINATED` | Quá `sandbox.maxDays` hoặc đề nghị được duyệt bốn mắt |
| `MemberSystem.status` | `ACTIVE` | suspend | `SUSPENDED` | Lý do, MFA mới, xác nhận tác động khi có phụ thuộc hoặc `CRITICAL` |
| `MemberSystem.status` | `SUSPENDED` | resume | `ACTIVE` | Điều kiện theo lý do (ERR-01-036), MFA mới |
| `MemberSystem.status` | `ACTIVE`, `SUSPENDED` | terminate | `TERMINATED` | `ChangeRequest TERMINATE` duyệt bốn mắt; trạng thái cuối, mã không dùng lại |
| `reviewStage` | `WAITING_ASSIGN` | assign | `IN_REVIEW` | `PERM-01-approve`, đủ ba bước có người |
| `reviewStage` | `IN_REVIEW` | consult, resume | `CONSULTING`, `IN_REVIEW` | Đồng hồ của bước dừng, tiếp tục (`paused_millis`) |
| `reviewStage` | `IN_REVIEW` | (hệ thống) | `WAITING_APPROVAL` | Cả ba bước `DONE`, mọi mục có kết luận (ERR-01-018) |
| `provisionStage` | `PROVISIONING` | (saga) | `AWAITING_KEY`, `SANDBOX_READY` | `FINALIZE` đạt; khóa công khai hoặc mTLS chờ khóa |
| `provisionStage` | `AWAITING_KEY` | đăng ký khóa | `SANDBOX_READY` | `KeyValidator`, `CsrValidator` đạt |
| `provisionStage` | `PROVISIONING` | (saga) | `PROVISION_FAILED` | Saga `FAILED` sau 24 giờ hoặc lỗi nghiệp vụ |
| `provisionStage` | `PROVISION_FAILED` | thử lại | `PROVISIONING` | `PERM-01-credential`, nguyên nhân đã sửa |
| `enforcement` | `NONE`, `DONE` | (lệnh cắt hoặc khôi phục) | `PENDING` | Đặt cùng giao dịch với trạng thái, kèm bốn việc |
| `enforcement` | `PENDING` | (hệ thống) | `DONE` | Cả bốn việc `DONE` |
| `AppCredential` | (saga) | cấp | `ACTIVE` | `FINALIZE`; một định danh `ACTIVE` hoặc `ROTATING` mỗi môi trường |
| `AppCredential` | `ACTIVE` | rotate | `ROTATING` | MFA mới; không đang xoay (ERR-01-029); `overlapDays` 0…14 |
| `AppCredential` | `ROTATING` | finish, hết hạn chuyển tiếp | `ACTIVE` | Đến `rotation_ends_at` hoặc người dùng kết thúc |
| `AppCredential` | `ACTIVE`, `ROTATING` | revoke, thu hồi khi chấm dứt | `REVOKED` | Lý do, MFA mới; trạng thái cuối |
| `AppCredential` | `ACTIVE` | hết hạn | `EXPIRED` | `expires_at` đã qua; trạng thái cuối |
| `AppCredential` | `ACTIVE` | tự vô hiệu, bật lại | `ACTIVE` với `disabled` đổi | Cờ có thể đảo ngược, không là trạng thái (Đợt 2, FR-01-036) |
| `Handover` | (mới) | tạo | `PENDING` | Đầu mối `TECHNICAL` có tài khoản, HTTT không `SUSPENDED` |
| `Handover` | `PENDING` | open | `OPENING` | Bảy kiểm tra của mục 4.7; chiếm chỗ bằng `UPDATE … WHERE status = 'PENDING'` |
| `Handover` | `OPENING` | unwrap xong | `OPENED` | Trạng thái cuối; hủy phiên bản bí mật; xóa mã bọc đã mã hóa |
| `Handover` | `OPENING` | lỗi trước khi bóc | `PENDING` | OpenBao không nhận lệnh, mã bọc còn hiệu lực (xác nhận bằng lookup) |
| `Handover` | `OPENING` | quá 2 phút | `CANCELLED` | Lý do `OPEN_INTERRUPTED`, yêu cầu xoay vòng |
| `Handover` | `PENDING` | hết hạn | `EXPIRED` | `expires_at` đã qua |
| `Handover` | `PENDING` | tạo lại, thu hồi, xoay, khóa | `CANCELLED` | Tạo bàn giao mới `PENDING` khi tạo lại (bản ghi mới) |
| `AccessReviewCycle` | (mới) | mở | `OPEN` | Chưa có kỳ nào chưa `CLOSED` (ERR-01-039) |
| `AccessReviewCycle` | `OPEN` | gửi xác nhận | `WAITING` | Có số liệu, có phiếu |
| `AccessReviewCycle` | `WAITING` | (hệ thống) | `DECIDING` | Mọi tổ chức đã đáp hoặc quá hạn |
| `AccessReviewCycle` | `DECIDING` | quyết định xong | `CLOSED` | Mọi mục có quyết định, lý do, MFA mới với `REVOKE_SCOPE` |
| `EmergencyAction` | (mới) | act | `PENDING_CONFIRM` | `PERM-01-suspend`, lý do, MFA mới |
| `EmergencyAction` | `PENDING_CONFIRM` | confirm | `CONFIRMED` | Người xác nhận khác người thực hiện (ERR-01-017) |
| `EmergencyAction` | `PENDING_CONFIRM` | (hệ thống) | `OVERDUE` | Quá `confirmBy`; không hoàn tác |
| `EmergencyAction` | `OVERDUE` | confirm | `CONFIRMED` | Như trên |
| `ChangeRequest` | (mới) | tạo | `PENDING` | Chưa có yêu cầu `PENDING` khác (ERR-01-038); phân mức |
| `ChangeRequest` | `PENDING` | decide | `APPROVED`, `REJECTED` | Người duyệt khác người đề nghị; `FULL` cần bước `LEGAL` xong |
| `ProvisioningSaga` | (mới) | phê duyệt, kích hoạt | `PENDING` | Chèn trong giao dịch phê duyệt hoặc kích hoạt |
| `ProvisioningSaga` | `PENDING`, `WAITING_RETRY` | (bộ chạy) | `RUNNING` | `next_run_at ≤ now`, `SKIP LOCKED` |
| `ProvisioningSaga` | `RUNNING` | lỗi bước | `COMPENSATING` | Bước đã tạo thứ gì mới bù trừ |
| `ProvisioningSaga` | `COMPENSATING` | bù trừ xong | `WAITING_RETRY` | Còn trong 24 giờ và lỗi có thể tự khỏi |
| `ProvisioningSaga` | `COMPENSATING`, `WAITING_RETRY` | (hệ thống) | `FAILED` | Quá 24 giờ hoặc lỗi nghiệp vụ (ERR-01-022) |
| `ProvisioningSaga` | `RUNNING` | bước cuối xong | `SUCCEEDED` | `FINALIZE` commit |
| `LegacyImportJob` | `UPLOADED` | (nền) | `PARSING`, `PREVIEWED` | Tệp sạch, ≤ `legacyImport.maxRows` (ERR-01-042, 044) |
| `LegacyImportJob` | `PREVIEWED` | confirm | `CONFIRMED`, `DONE` | `PERM-18-migration`; ghi tất cả hoặc không |
| `LegacyImportJob` | `UPLOADED`, `PREVIEWED` | hủy, lỗi | `CANCELLED`, `FAILED` | Tệp xóa sau 7 ngày |

: Bảng chuyển trạng thái của PH-01

Mỗi aggregate có cột `version` (khóa lạc quan). Lệnh từ API kèm `If-Match`; lệnh hệ thống (saga, cắt quyền, hết hạn, xoay) dùng thử lại tối đa 3 lần khi xung đột `version`. Hai máy `MemberSystem.status` và `reviewStage` cùng nằm trong một aggregate nên đổi cả hai trong một giao dịch. Kiểm thử thuộc tính (jqwik) sinh chuỗi lệnh ngẫu nhiên và khẳng định: không đạt được trạng thái ngoài bảng, trạng thái cuối không rời ra, mỗi chuyển có đúng một dòng lịch sử và đúng một bản ghi outbox (mục 12).

### 8.2. Outbox, hộp nhận và lũy đẳng

Sự kiện ra ghi vào bảng `outbox` trong cùng giao dịch với thay đổi (ADR-042; mục 4.11); sự kiện vào ghi `inbox(event_id)` duy nhất. Thông báo và việc cho hộp việc đi qua bảng `notify_outbox` có thử lại tới 24 giờ, để lỗi PH-18 không làm hỏng giao dịch nghiệp vụ và không mất việc sau commit. Bảng dưới liệt kê từng lớp chống trùng.

| Điểm | Cơ chế lũy đẳng | Phạm vi, thời hạn |
|---|---|---|
| API tạo (`POST /systems`, `:submit` và các lệnh `POST` có tác dụng phụ, trừ `POST /handovers:open`) | `Idempotency-Key` bắt buộc (mở bàn giao không dùng khóa này vì không được phát lại bí mật; lần mở thứ hai bị từ chối theo ERR-01-024); bảng `idempotency_record` khóa `(tenant_id, client, method, path, key)` kèm băm thân chuẩn hóa JCS; cùng khóa cùng thân trả lại phản hồi đã lưu; cùng khóa khác thân trả ERR-01-051 (409, `type = idempotency-mismatch`); cùng khóa đang xử lý trả ERR-01-054 (409) kèm `Retry-After` | Giữ 24 giờ (ADR-041) |
| Lệnh chuyển trạng thái lặp lại | Lệnh đã áp dụng cho cùng tác nhân và cùng đích trả lại kết quả hiện hành; khác thì ERR-01-005 | Theo trạng thái |
| Lệnh sang PH-12, PH-03 trong saga | `Idempotency-Key = {sagaId}:{step}`; bước `RUNNING` quá 60 giây được gọi lại | Hết saga cộng 7 ngày |
| Cắt quyền | `Idempotency-Key = {enforcementId}:{type}`; tập `clientIds` cố định trong việc | Hết việc cộng 7 ngày |
| Callback kết quả saga | Khóa `(sagaId, step)`; callback lặp bị bỏ qua | Hết saga |
| Sự kiện ra | `id` ULID duy nhất; bên nhận xử lý lũy đẳng theo `(systemCode, updatedAt)`, bỏ qua bản cũ hơn bản đang giữ | Theo bên nhận |
| Sự kiện vào | `inbox(event_id)` duy nhất | 30 ngày |
| Nhập hệ cũ | Chỉ mục duy nhất `(tenant_id, legacy_ref)` | Vĩnh viễn |
| Mở bàn giao | Chiếm chỗ `PENDING → OPENING` bằng một câu `UPDATE` có điều kiện | Một lần |

: Các lớp lũy đẳng của PH-01

### 8.3. Thời gian chờ, thử lại, ngắt mạch

Chính sách đặt ở lớp cổng tích hợp (mục 4.16); thử lại ở tầng nghiệp vụ (saga, cắt quyền) là việc của bộ chạy chứ không của bộ chuyển, để không nhân lượt thử.

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch |
|---|---|---|---|
| PH-12 tạo client, bắt đầu xoay | 10 giây | Do saga: 1, 2, 4, 8, 15 phút rồi 15 phút tới 24 giờ | 50% trên 20 lượt, nửa mở 30 giây; mở thì saga hoãn lượt |
| PH-12 vô hiệu client, thu hồi token | 5 giây | Do `EnforcementRetryJob`: 10, 20, 40, 60 giây | Không (không được chặn đường cắt quyền) |
| PH-03 chặn client | 5 giây | Một lần ngay, rồi `EnforcementRetryJob` | Không; luôn thử |
| PH-03 tạo, xóa, vô hiệu consumer | 10 giây, 5 giây, 5 giây | Do saga hoặc `EnforcementRetryJob` | 50% trên 20 lượt, nửa mở 30 giây |
| OpenBao bọc, metadata, hủy, transit, ký CSR | 2 giây | 2 lần: 200 ms, 400 ms | 50% trên 10 lượt, nửa mở 30 giây |
| OpenBao mở bọc (`unwrap`) | 5 giây | **Không thử lại** vì chỉ dùng được một lần | Kiểm sức khỏe trước khi chiếm chỗ |
| Garage | 5 giây | 2 lần | 50% trên 20 lượt |
| Dịch vụ quét mã độc | 20 giây | Không (tệp ở `PENDING`) | Không |
| PH-02, PH-13, PH-14 | 3 giây | 1 lần | 50% trên 20 lượt; mở thì kết quả `partial` |
| PH-20, danh mục `dataType`, lịch làm việc | 3 giây | 1 lần | Dùng bản đệm (24 giờ) |
| PH-18 thông báo, hộp việc | 3 giây | 3 lần: 1, 2, 4 giây; còn lỗi vào `notify_outbox` thử tới 24 giờ | Không |
| Keycloak (token dịch vụ) | 2 giây | 2 lần | Dùng token đã đệm tới hạn |

: Thời gian chờ, thử lại, ngắt mạch

*Mở bàn giao không thử lại.* Vì mã bọc chỉ dùng được một lần, bộ chuyển `unwrap` không thử lại. Trước khi chiếm chỗ, `HandoverGuard` gọi kiểm sức khỏe OpenBao (hạn 1 giây) để tránh mở khi biết nó đang lỗi. Khi lời gọi `unwrap` hết hạn đọc mà chưa rõ OpenBao đã xử lý hay chưa, `HandoverGuard` gọi `sys/wrapping/lookup` (không tiêu hao): mã còn hiệu lực thì trả `OPENING → PENDING` và ERR-01-023 (liên kết chưa bị tiêu hao); mã đã hết thì coi bí mật đã bị lấy mà không tới người nhận, chuyển `CANCELLED` kèm `OPEN_INTERRUPTED` và yêu cầu xoay vòng.

### 8.4. Phân loại lỗi

Mọi lỗi trả về theo RFC 9457 (`application/problem+json`) với `code` là mã `ERR-01-*`, `traceId` và (khi có) `errors[]` theo trường. Chi tiết nội bộ như ngăn xếp gọi hay thông điệp của hệ ngoài không bao giờ vào thân phản hồi; lỗi không lường trước trả mã chung của FR-00-080 kèm `traceId`.

| Lớp lỗi | Mã ERR-01 | HTTP | Xử lý |
|---|---|---|---|
| Dữ liệu không hợp lệ | 003, 004, 008, 011, 015, 016, 018, 019, 027, 028, 033, 037, 041, 042, 044, 047, 049 | 400, 413, 415, 422 | Không thử lại; trả danh sách lỗi theo trường |
| Trạng thái, đồng thời | 002, 005, 007, 009, 020, 022, 029, 030, 032, 034, 036, 038, 039, 043, 048, 050 | 409, 412 | Người dùng tải lại hoặc xử lý điều kiện; 007 kèm hồ sơ hiện hành |
| Quyền, bốn mắt, xác thực lại | 006, 017, 025, 035 | 403 | Ghi sự kiện an ninh với 017 và 025 |
| Không thấy hoặc ngoài phạm vi | 001 | 404 | Cùng thân với "không tồn tại" (BR-01-030) |
| Hết hạn, đã dùng | 024, 040 | 410 | Thân giống nhau cho mọi nguyên nhân (không lộ trạng thái liên kết) |
| Giới hạn tốc độ, khóa | 026, 045 | 429 | `Retry-After`; 026 hủy liên kết |
| Phụ thuộc không khả dụng | 021, 023, 046 | 503 | Saga, cắt quyền thử lại; không đổi trạng thái đã đặt; không tiêu hao liên kết bàn giao |
| Lỗi không tự khỏi của hệ ngoài | 022 | 409 | Dừng saga `FAILED`, cảnh báo TA |

: Phân loại lỗi và cách xử lý

Ba điều thiết kế không bao giờ làm khi có lỗi: không hoàn tác trạng thái cắt quyền (chỉ thử lại việc cắt); không tiêu hao liên kết bàn giao khi OpenBao lỗi; không ghi dở một bước saga mà không có bản ghi `RUNNING` để gọi lại.

### 8.5. Tính nhất quán

PH-01 chủ động chấp nhận nhất quán cuối cùng ở ranh giới với hệ ngoài và chỉ giữ tính nguyên tử trong CSDL của mình.

| Thao tác | Nguyên tử trong một giao dịch CSDL | Nhất quán cuối cùng | Khi hỏng giữa chừng |
|---|---|---|---|
| Nộp hồ sơ | Trạng thái, ba bước thẩm định, lịch sử, kiểm toán, outbox | Việc trong hộp việc, thư (`notify_outbox`) | Thông báo thử lại tới 24 giờ; hồ sơ không mất |
| Phê duyệt | Trạng thái, trần phạm vi, dòng saga `PENDING`, outbox | Cấp định danh ở PH-12, PH-03 | Dòng saga đã có nên bộ chạy tiếp tục sau khi khởi động lại |
| Bước saga | Mỗi bước một giao dịch (ghi `RUNNING`, rồi kết quả) | Tạo client, consumer ở hệ ngoài | Bước `RUNNING` quá 60 giây gọi lại bằng cùng khóa |
| Cắt quyền | Trạng thái, bốn việc, outbox | Chặn cổng, vô hiệu client, consumer | Thử lại tới khi xong, cảnh báo sau 60 giây |
| Mở bàn giao | Chiếm chỗ `OPENING`, ghi `OPENED` | `unwrap` và `destroy` ở OpenBao | `HandoverRecoveryJob` xử lý `OPENING` treo (mục 4.7) |
| Quyết định rà soát | Mục, trần, outbox | PH-02 hủy đăng ký rồi gọi API-12-068 thay tập scope | Ảnh chụp EVT-01-03 hằng giờ mang `ceilingDataTypes` để bên nhận phát hiện lệch |
| Phát sự kiện | Dòng outbox | Kafka | Outbox giữ, phát bù khi Kafka trở lại; cảnh báo khi trễ quá 60 giây |

: Ranh giới giao dịch và nhất quán

## 9. Cấu hình và cờ tính năng theo tenant

Có ba lớp cấu hình, theo thứ tự ưu tiên giảm dần: tham số theo tenant do quản trị tỉnh đặt qua PH-18 (UI-01-16); mức trần hoặc mặc định do PA đặt cho nền tảng; giá trị mặc định trong mã. Cấu hình không bao giờ chứa bí mật: `dh-connect` lấy token OpenBao bằng xác thực Kubernetes (SEC-33).

### 9.1. Tham số nghiệp vụ `onboarding.*`

30 khóa theo tenant định nghĩa ở D02-03-PH01 §8.2 (hạn thẩm định và phê duyệt, bàn giao, vòng đời định danh, SANDBOX, thao tác khẩn, rà soát, danh bạ, tác động hạn mức, cấp độ ATTT tối thiểu, xác thực lại, nhập hệ cũ). `OnboardingSettings` đọc qua `ParameterApi` của PH-18 có đệm 60 giây; giá trị ngoài miền hoặc vượt trần của PA bị từ chối ở cả hai nơi (ERR-01-044). Tham số không đọc được thì dùng bản đệm, hết đệm thì dùng mặc định trong mã. Tham số đổi chỉ áp cho thao tác mới.

### 9.2. Cấu hình kỹ thuật của module

Các khóa dưới đây nằm ở `application.yml` của `dh-connect` (Helm values), không theo tenant, đổi bằng triển khai. Giá trị mặc định là giả định thiết kế; cơ sở ghi ở cột cuối.

| Khóa | Mặc định | Ý nghĩa | Cơ sở |
|---|---|---|---|
| `dh.onboarding.saga.runner-delay` | 2 giây | Chu kỳ bộ chạy saga | Đáp ứng NFR-01-004 (5 phút) với dư lớn |
| `dh.onboarding.saga.step-timeout` | 10 giây | Hạn một lời gọi ngoài | Bằng thời gian chờ ở mục 8.3 |
| `dh.onboarding.saga.max-age` | 24 giờ | Quá thì `FAILED` | FR-01-020 |
| `dh.onboarding.saga.backoff` | `1m,2m,4m,8m,15m` | Lịch lùi, bước cuối lặp lại | FR-01-020 |
| `dh.onboarding.saga.running-stale` | 60 giây | Bước `RUNNING` quá bấy nhiêu thì gọi lại | Gấp 6 lần hạn lời gọi |
| `dh.onboarding.enforcement.block-timeout` | 5 giây | Hạn lệnh chặn đồng bộ | Ngân sách 60 giây của NFR-01-008 |
| `dh.onboarding.enforcement.retry-delay` | 10 giây, tăng tới 60 giây | Chu kỳ thử lại | NFR-01-008 |
| `dh.onboarding.outbox.mode` | `debezium` | `debezium` hoặc `relay` (dự phòng `QM-NHO`) | ADR-042 |
| `dh.onboarding.outbox.relay-poll` | 500 ms | Chu kỳ bộ quét dự phòng | NFR-01-021 (p95 ≤ 5 giây) |
| `dh.onboarding.outbox.retention` | 7 ngày | Thời hạn dọn hàng đã phát | Đủ cho phát bù sau sự cố cuối tuần |
| `dh.onboarding.snapshot.batch` | 200 | Cỡ lô ảnh chụp đối chiếu | Bản ghi nhỏ, tránh lô quá lớn trên Kafka |
| `dh.onboarding.replica.max-page` | 500 | Trần `size` của API đọc bản sao | FR-01-038 |
| `dh.onboarding.attachment.scan-timeout` | 20 giây | Hạn quét đồng bộ | Tệp ≤ 20 MB |
| `dh.onboarding.handover.opening-timeout` | 2 phút | `OPENING` quá thì `CANCELLED` | Mục 4.7 |
| `dh.onboarding.job.jitter` | 30 giây | Độ trễ ngẫu nhiên giữa tenant | Tránh dồn tải |
| `dh.onboarding.usage.concurrency` | 8 | Số lời gọi PH-13 đồng thời mỗi tenant | Mục 4.12 |
| `dh.onboarding.idempotency.ttl` | 24 giờ | Thời hạn lưu phản hồi lũy đẳng | ADR-041 |

: Cấu hình kỹ thuật của module

### 9.3. Cờ tính năng theo tenant

Cờ dùng OpenFeature (cùng nhà cung cấp với các phân hệ khác), đọc theo tenant, mặc định ghi dưới đây.

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `onboarding.autosuspend.enabled` | `false` | Bật tự vô hiệu định danh không dùng (FR-01-036, Đợt 2) |
| `onboarding.access-review.report.enabled` | `false` | Bật báo cáo rà soát quyền (FR-01-044, Đợt 2) |
| `onboarding.directory.export.enabled` | `false` | Bật xuất danh bạ đầu mối (FR-01-047, Đợt 2) |
| `onboarding.statistics.enabled` | `false` | Bật thống kê kết nạp, khung nhìn vật chất hóa (FR-01-051, Đợt 2) |
| `onboarding.legacy-import.enabled` | `true` | Bật nhập hệ cũ trong giai đoạn thay dần; tắt khi hết chạy song song |
| `onboarding.saga.async-callback` | `false` | Chấp nhận kết quả saga bất đồng bộ qua callback (Q01-28) |
| `onboarding.approval-mode` | `INTERNAL` | Chế độ duyệt: `INTERNAL` (máy trạng thái trong mã), `BPMN` dành chỗ cho Flowable (Q01-14), chưa hiện thực ở MVP |

: Cờ tính năng theo tenant

## 10. Quan sát

PH-01 phát chỉ số, vết và log qua OpenTelemetry (ADR-011); nhãn `tenant` do tài nguyên OTel gắn sẵn nên không lặp trong bảng. Tám chỉ số đầu là của NFR-01-015, giữ nguyên tên; các chỉ số sau đó là chỉ số kỹ thuật cùng tiền tố `onboarding_` (Q01-22 hỏi có đổi sang tiền tố `dh_` theo D04-01 không). Không dùng `systemCode` làm nhãn của bộ đếm hay histogram để tránh bùng nổ chuỗi thời gian; mã HTTT có trong log và vết, và trong nhãn của vài gauge cảnh báo giới hạn dưới 1.000 giá trị.

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `onboarding_applications_total` | counter | `status` | `MemberStateMachine`, mỗi chuyển |
| `onboarding_stage_duration_days` | histogram | `stage` (`draft`, `review`, `approval`, `provisioning`, `sandbox`) | Tính khi rời giai đoạn |
| `onboarding_members_total` | gauge | `status`, `group` | Truy vấn tổng hợp 60 giây |
| `onboarding_credential_expiring_total` | gauge | `window` (30, 14, 7) | `ExpiryJob` |
| `onboarding_scope_unused_total` | gauge | | `UsageAggregator` |
| `onboarding_review_overdue_total` | gauge | `step` | `EscalationJob` |
| `onboarding_saga_failed_total` | counter | `env`, `step` | `SagaRunner` |
| `onboarding_enforcement_pending_total` | gauge | `type` | `EnforcementRetryJob` |
| `onboarding_saga_duration_seconds` | histogram | `env`, `result` | `SagaRunner` |
| `onboarding_saga_step_duration_seconds` | histogram | `step`, `result` | `SagaRunner` |
| `onboarding_enforcement_latency_seconds` | histogram | `mode` (`suspend`, `resume`, `revoke`, `emergency`) | `EnforcementExecutor`, từ commit tới `DONE` |
| `onboarding_handover_total` | counter | `result` (`opened`, `expired`, `cancelled`, `wrong_recipient`, `locked`) | `HandoverGuard` |
| `onboarding_handover_open_seconds` | histogram | | `HandoverGuard` |
| `onboarding_emergency_pending_total` | gauge | `status` | `EmergencyConfirmationJob` |
| `onboarding_state_transition_total` | counter | `object`, `from`, `to` | `TransitionTable` |
| `onboarding_rotation_total` | counter | `result` | `RotationService`, `RotationFinisher` |
| `onboarding_credential_disabled_total` | counter | `reason` | `InactivityJob`, `ExpiryJob` |
| `onboarding_attachment_rejected_total` | counter | `reason` (`size`, `type`, `malware`, `scan_unavailable`) | `AttachmentService` |
| `onboarding_outbox_lag_seconds`, `onboarding_outbox_pending` | gauge | | Debezium, `OutboxRelay` |
| `onboarding_reconcile_diff_total` | counter | `consumer` | API-01-062 |
| `onboarding_replica_requests_total` | counter | `caller` | `ReplicaController` |
| `onboarding_port_calls_total`, `onboarding_port_duration_seconds` | counter, histogram | `port`, `op`, `result` | Cổng tích hợp |
| `onboarding_job_duration_seconds`, `onboarding_job_failures_total`, `onboarding_job_last_success_timestamp` | histogram, counter, gauge | `job` | `TenantJobRunner` |
| `onboarding_directory_queries_total` | counter | `result` (`ok`, `rate_limited`) | `DirectoryService` |
| `onboarding_legacy_import_rows_total`, `onboarding_legacy_import_secrets_dropped_total` | counter | `result` | `LegacyImportService` |
| `onboarding_access_review_coverage_ratio`, `onboarding_review_cycle_open_days` | gauge | | `AccessReviewService` |

: Chỉ số của PH-01

*Vết.* Mỗi yêu cầu có span `onboarding.command`; các span con `onboarding.saga.step` (thuộc tính `dh.saga.id`, `dh.saga.step`, `dh.env`), `onboarding.enforcement.task` (`dh.enforcement.type`), `onboarding.handover.open` (chỉ `dh.result`), `onboarding.job` (`dh.job`), `port.call` (`dh.port`, `dh.op`, `http.status_code`). `traceId` được ghi vào cột `trace_id` của dòng outbox và đi theo tiêu đề sự kiện nên bên nhận nối tiếp cùng vết. Không bao giờ ghi vào thuộc tính vết: thân yêu cầu hay phản hồi, JWT, bí mật, nội dung khóa, thông tin liên hệ (SEC-32).

*Log.* Log JSON có `ts`, `level`, `tenant`, `traceId`, `spanId`, `actorId`, `systemCode`, `command`, `outcome`, `errCode`. Các đường dẫn `/handovers:open`, `/credentials/{id}/public-key`, `/credentials/{id}:sign-csr`, `/systems/{systemCode}/contacts` và `/legacy-imports` được gắn nhãn "không ghi thân" ở bộ lọc log; thư viện log che theo `@Classified` và theo mẫu (thư điện tử, điện thoại, số định danh). Lỗi nghiệp vụ dự kiến (ERR-01-005, 017…) ghi mức INFO kèm `errCode`, chỉ lỗi hạ tầng mới là ERROR.

*Kiểm toán.* Thư viện `dh-audit` ghi trong cùng giao dịch (SEC-60): mọi chuyển trạng thái, quyết định thẩm định và phê duyệt, cấp, xoay, thu hồi định danh, tạo, mở, hủy bàn giao (người mở, IP, thời điểm), thao tác khẩn và xác nhận, quyết định rà soát, thay đổi tham số, xuất danh sách, nhập hệ cũ, và các lần bị chặn bốn mắt hoặc sai người nhận bàn giao. Không ghi kiểm toán từng lượt đọc của token dịch vụ, từng lượt tra danh bạ (chỉ lượt bất thường vượt giới hạn). Không bản ghi nào chứa bí mật hay nội dung khóa.

*Cảnh báo.* Quy tắc khai báo dạng PrometheusRule trong Helm chart của `dh-connect`, đi qua Alertmanager tới PH-13 và kênh trực vận hành.

| Cảnh báo | Điều kiện | Mức | Nhận | Căn cứ |
|---|---|---|---|---|
| `OnboardingEnforcementPending` | `onboarding_enforcement_pending_total > 0` quá 60 giây | Cao | SO, PO | NFR-01-008, 016 |
| `OnboardingSagaFailed` | `increase(onboarding_saga_failed_total[15m]) > 0` | Cao | TA, PO | NFR-01-016 |
| `OnboardingSagaSlow` | p95 `onboarding_saga_duration_seconds{env="SANDBOX"}` > 300 giây | Trung bình | PO | NFR-01-004 |
| `OnboardingOutboxLag` | `onboarding_outbox_lag_seconds > 60` trong 2 phút | Cao | PO | FR-01-037, NFR-01-021 |
| `OnboardingHandoverAnomaly` | `wrong_recipient` hoặc `locked` từ 3 lần trong 10 phút | Cao | SO | FR-01-022 |
| `OnboardingEmergencyOverdue` | Thao tác khẩn quá `confirmBy` chưa xác nhận | Cao | TA, PO | BR-01-010 |
| `OnboardingReviewOverdue` | `onboarding_review_overdue_total > 0` | Trung bình | TA | FR-01-016 |
| `OnboardingSandboxStale` | HTTT ở `SANDBOX_READY` quá `sandbox.maxDays` | Thấp | TA, PO | FR-01-023 |
| `OnboardingCredentialExpiring` | Định danh còn ≤ 30 ngày | Thấp | TA, OR | FR-01-027 |
| `OnboardingJobStale` | `now − onboarding_job_last_success_timestamp > 2 × chu kỳ` | Trung bình | PO | Mục 4.15 |

: Cảnh báo của PH-01

## 11. Hiệu năng và vận hành

### 11.1. Định cỡ

Hồ sơ đo là "tỉnh vừa" (GĐ-01-01, GĐ-07): 200 HTTT, 80 HTTT kết nạp năm đầu, đỉnh 20 hồ sơ mỗi tháng; trung bình 2,5 đầu mối, 6 mục nhu cầu, 1,3 định danh mỗi môi trường mỗi HTTT (GĐ-01-02). Trần thiết kế theo NFR-01-017: 1.000 HTTT, 5.000 định danh, 20.000 đầu mối, 50.000 mục trần mỗi tenant.

| Hạng mục | Ước tính tỉnh vừa | Cơ sở |
|---|---|---|
| Dòng `member_system`, `data_demand`, `contact`, `app_credential` | 200, 1.200, 500, 260 | GĐ-01-01, 02 |
| `state_history` | Khoảng 8.000 dòng mỗi năm | 200 HTTT nhân 40 chuyển (giả định) |
| `sandbox_test` | Khoảng 1 triệu dòng mỗi năm | 10 HTTT cùng ở SANDBOX, mỗi 5 phút một bản ghi (giả định), giữ 1 năm rồi dọn (NFR-01-022) |
| `outbox` ổn định | Dưới 40.000 dòng | Ảnh chụp 200 dòng mỗi giờ, giữ 7 ngày |
| CSDL không kể tệp | Dưới 1 GiB mỗi năm | Cộng các dòng trên |
| Tệp đính kèm | Khoảng 4 GiB mỗi năm | 80 HTTT nhân 10 tài liệu nhân 5 MB (giả định) |
| Tài nguyên thêm cho `dh-connect` | Khoảng 0,3 vCPU, 384 MiB heap | Giả định, đo lại ở giai đoạn 4 của lộ trình |
| Tải bộ chạy saga | Một truy vấn nhẹ mỗi tenant mỗi 2 giây | 20 tenant thì dưới 10 truy vấn mỗi giây |

: Định cỡ PH-01 ở tỉnh vừa

Chỉ mục quan trọng (chi tiết ở D03-03-PH01): duy nhất `member_system(tenant_id, code)`; duy nhất `handover(link_hash)`; duy nhất từng phần `access_review_cycle(tenant_id) WHERE status <> 'CLOSED'`; từng phần `provisioning_saga(tenant_id, next_run_at) WHERE state IN ('PENDING','WAITING_RETRY')`; từng phần `enforcement_task(tenant_id, next_run_at) WHERE status = 'PENDING'`; `member_system(tenant_id, status, owner_org_id)`; GIN `pg_trgm` trên `contact.search_text`.

### 11.2. Chỉ tiêu và cách đạt

Bảng dưới trình bày chỉ tiêu và cách đạt.

| NFR | Chỉ tiêu | Cách đạt trong thiết kế | Cách đo |
|---|---|---|---|
| NFR-01-001 | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | Đường đọc riêng, chỉ mục, không gọi mạng trên đường đọc; ghi một giao dịch ngắn, lời gọi ngoài chuyển nền | Gatling, 1.000 HTTT |
| NFR-01-002 | Kiểm tra hợp lệ p99 ≤ 2 giây | Quy tắc thuần trên dữ liệu nạp sẵn, hai truy vấn nạp (mục 4.4) | Gatling, hồ sơ 30 mục, 10 tài liệu |
| NFR-01-003 | Danh sách p99 ≤ 1 giây | Chỉ mục kép, facets một truy vấn `GROUP BY` | Gatling, 500 HTTT, 50 dòng |
| NFR-01-004 | Cấp SANDBOX p95 ≤ 5 phút | Saga bền, bộ chạy 2 giây, mỗi bước ≤ 10 giây, bàn giao sau `FINALIZE` | Đo `onboarding_saga_duration_seconds` ở thí điểm |
| NFR-01-007 | Cách ly sự cố ≥ 24 giờ | PH-01 không nằm trên đường gọi; APISIX giữ cấu hình đã nạp | Diễn tập dừng `dh-connect` 24 giờ |
| NFR-01-008 | Cắt quyền ≤ 60 giây | Chặn cổng trước, ngân sách mục 4.10 | Đo `onboarding_enforcement_latency_seconds`, chèn trễ PH-12 |
| NFR-01-021 | Sự kiện p95 ≤ 5 giây | Outbox, Debezium, khóa theo `systemCode` | `onboarding_outbox_lag_seconds` |

: Chỉ tiêu hiệu năng và cách đạt

### 11.3. Khả năng mở rộng

*Theo chiều ngang.* `dh-connect` không giữ trạng thái ngoài CSDL, tăng từ hai lên nhiều bản sao không đổi mã: bộ chạy việc hàng đợi (saga, cắt quyền) dùng `SKIP LOCKED` nên mọi bản sao cùng làm; tác vụ định kỳ dùng ShedLock nên chỉ một bản sao chạy. Vòng lặp theo tenant có độ phức tạp tuyến tính theo số tenant; khi một DU phục vụ trên khoảng 50 tenant, thay chu kỳ 2 giây bằng đánh thức theo sự kiện (`pg_notify` khi chèn saga hoặc việc cắt quyền) và chạy song song theo tenant, không đổi dữ liệu.

*Theo chiều dữ liệu.* `sandbox_test` và `state_history` phân vùng theo tháng khi vượt khoảng 10 triệu dòng; bảng có `tenant_id` đứng đầu mọi chỉ mục nên cùng chiến lược với các phân hệ khác. Tách CSDL vật lý theo tenant ở cấp độ 4 (SEC-92) chỉ đổi lớp `DataSource` định tuyến, không đổi mã nghiệp vụ.

Các điểm mở rộng có chủ đích:

| Nhu cầu | Điểm mở rộng | Việc cần làm |
|---|---|---|
| Thêm phương thức xác thực máy | Chiến lược `AuthMethodPolicy` và bảng BR-01-019 | Thêm lớp chiến lược, lớp kiểm khóa; PH-12 hỗ trợ phương thức mới |
| Thêm loại bước thẩm định | `StepType` và `ReviewStepFactory` | Thêm giá trị enum, quy tắc `inputHash`, tab ở UI-01-06 |
| Duyệt nhiều cấp liên cơ quan | Giao diện `ApprovalEngine` (`InternalApprovalEngine` hiện có, `FlowableApprovalEngine` dành chỗ), cờ `onboarding.approval-mode` | ADR mở rộng ADR-058, tích hợp PH-11 (Q01-14) |
| Thêm bước vào saga (ví dụ gắn hạn mức PH-14, tạo topic PH-10) | `StepDefinition` gồm hành động, bù trừ, khóa lũy đẳng | Khai báo thêm một dòng ở bảng bước, thêm cổng tích hợp |
| Thêm tiêu chí kiểm thử SANDBOX | Giao diện `SandboxCriterion` | Thêm lớp tiêu chí, tham số nếu cần |
| Thêm nguồn nhập hệ cũ | `ColumnMapper` khai báo theo nguồn | Thêm bảng ánh xạ, không đọc cột xác thực |
| Thêm loại sự kiện | Record ở `events` và lược đồ Apicurio BACKWARD | Cập nhật D03-04-PH01, AsyncAPI |
| Tách PH-01 khỏi `dh-connect` | Gói `api` và cổng tích hợp đã là đường biên | Thay bộ chuyển trong tiến trình của PH-02, PH-03 bằng REST, chuyển module sang DU riêng (điều kiện ở D03-01 §4.2) |

: Điểm mở rộng của PH-01

### 11.4. Vận hành

Các ý dưới đây trình bày vận hành.

- **Sổ tay** ở D06-03 có các kịch bản: saga `FAILED` (đọc `saga_step`, sửa nguyên nhân, thử lại); `enforcement` còn `PENDING` quá 60 giây (kiểm PH-03, PH-12, chạy lại việc); outbox trễ (kiểm Debezium, chuyển `relay`); bàn giao `CANCELLED` với lý do `OPEN_INTERRUPTED` (xoay vòng); kỳ rà soát kẹt `WAITING`; xoay khóa transit `dh-{tenant}-handover`; kiểm bí mật mồ côi ở `kv/dh/{tenant}/clients` so với `app_credential` (tác vụ đêm, báo cáo, không tự xóa).
- **Chuyển đổi dự phòng OpenBao.** Mã bọc nằm trong cubbyhole của OpenBao; nếu chuyển sang nút dự phòng mà bản sao chưa đồng bộ, các bàn giao `PENDING` mất mã bọc. Quy trình: sau chuyển đổi, `HandoverRecoveryJob` chế độ kiểm tra gọi `lookup` mọi bàn giao `PENDING`, hủy cái mất mã và tạo lại từ bí mật còn trong KV (chưa từng mở nên còn nguyên); đầu mối nhận liên kết mới.
- **Nâng cấp không gián đoạn.** Thay đổi CSDL theo mô hình mở rộng rồi thu hẹp (expand, contract) của Liquibase để hai bản sao chạy hai phiên bản trong lúc cuốn chiếu. Khi nhận SIGTERM, bộ chạy ngừng nhận việc mới và chờ bước đang chạy (tối đa 10 giây); việc dở dang được bản sao kia nhận sau 60 giây nhờ cơ chế `RUNNING` quá hạn.
- **Khôi phục thảm họa.** RPO ≤ 1 giờ, RTO ≤ 4 giờ (NFR-01-006, SEC-71). Sau khôi phục từ bản sao lưu, saga và việc cắt quyền tiếp tục từ CSDL; việc đầu tiên của sổ tay là kiểm các hồ sơ có `enforcement = PENDING`, rồi chạy tác vụ đối chiếu để PH-10, PH-02 đồng bộ lại.
- **Bảo trì dữ liệu.** `OutboxPurge` giữ 7 ngày; `sandbox_test` giữ 1 năm, bàn giao 3 năm, kỳ rà soát 5 năm, hồ sơ, bước thẩm định, lịch sử vĩnh viễn (NFR-01-022); tác vụ dọn ghi số dòng đã dọn vào kiểm toán.

## 12. Kiểm thử

Kế hoạch chi tiết và ca kiểm thử nằm ở D05-02-PH01; bảng dưới là chiến lược theo mức và các tính chất bắt buộc, theo ADR-038.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Mỗi dòng `GroupAdvisor`; mỗi quy tắc `SubmissionRule` (13 dương, 13 âm); `KeyValidator`, `CsrValidator` (thuật toán, độ dài, khóa riêng lẫn vào); `ChangeClassifier`; `ReviewClock` với lịch nghỉ và thời gian dừng; `SecretLikeDetector`; `LinkCodec`; `ScopeCeilingFactory` không bao giờ rộng hơn nhu cầu | JUnit 5, AssertJ, kiểm thử tham số hóa |
| Thuộc tính | Chuỗi lệnh ngẫu nhiên trên `TransitionTable`: không vào trạng thái ngoài bảng, trạng thái cuối không rời ra, mỗi chuyển có đúng một dòng lịch sử và một bản ghi outbox; thứ tự bù trừ saga là ngược của thứ tự thực hiện | jqwik |
| Kiến trúc | Luật Modulith (`onboarding` chỉ import `shared`, `catalog.api`, `gateway.api`); `web` không chạm repository; `integration` không import gói nghiệp vụ; cấm log đối tượng `Secret`; cấm gọi `OpenBaoPort.unwrap` ngoài `HandoverService`; cấm đọc tenant từ tham số | ArchUnit, Semgrep |
| Tích hợp | PostgreSQL 16 (RLS bắt buộc, `SKIP LOCKED`, chỉ mục duy nhất từng phần); Kafka và Debezium (thứ tự theo khóa); OpenBao (chính sách `min_wrapping_ttl` thật sự ép bọc, bọc và mở một lần, transit, PKI ký CSR); Keycloak (`acr`, `auth_time`); Garage và dịch vụ quét; Apicurio BACKWARD | Testcontainers |
| Saga và lỗi | Gây lỗi tại từng bước (PH-12 trả 503, PH-03 hết hạn, mất mạng sau khi PH-12 đã tạo): không tạo trùng client, bù trừ đủ, thử lại đúng lịch, không để consumer mồ côi; hết 24 giờ thì `FAILED` | WireMock, Toxiproxy |
| Hợp đồng | OpenAPI của D03-04-PH01; AsyncAPI của EVT-01-*; hợp đồng người tiêu dùng với PH-02, PH-10 cho EVT-01-03 và `MemberSystemQueryApi` | Spectral, oasdiff (CI-5), kiểm thử hợp đồng theo người tiêu dùng |
| Bảo mật | Canary `DH-CANARY-…` tìm trong CSDL, log, vết, phản hồi, tệp xuất, thư, nhật ký kiểm toán (NFR-01-009); chéo tenant cho mọi API đọc, kể cả `/internal/*` (BR-01-030); bốn mắt ở cả bốn điểm; kịch bản bàn giao: mở lần hai `410`, sai người `403` kèm EVT-01-10, hết hạn, khóa sau 5 lần sai, không còn bản sao ở OpenBao sau khi mở; giả mạo `If-Match`, IDOR, vượt giới hạn tra danh bạ | JUnit, ZAP, kịch bản D05-04 |
| Hiệu năng | NFR-01-001…003 ở quy mô trần; cắt quyền 60 giây khi PH-12 chậm 20 giây; 20 hồ sơ nộp đồng thời | Gatling, k6 |
| Hỗn loạn | Giết pod `dh-connect` giữa saga, giữa thao tác khẩn, giữa mở bàn giao; Kafka ngừng 30 phút rồi phát bù; OpenBao chuyển đổi dự phòng; dừng `dh-connect` 24 giờ (NFR-01-007) | Chaos Mesh, kịch bản diễn tập |
| Chấp nhận | Kết nạp trọn vẹn một HTTT thật đo KPI-05; UAT với 5 cán bộ đầu mối hoàn thành biểu mẫu ≤ 30 phút (NFR-01-014); 14 tiêu chí chấp nhận cấp phân hệ ở FRS §14 | UAT, kịch bản D05-02-PH01 |

: Chiến lược kiểm thử

Mục tiêu chất lượng: độ phủ dòng ≥ 80% ở module, 100% chuyển trạng thái của `TransitionTable` có ca kiểm thử dương và ca âm, kiểm thử đột biến (PIT) ≥ 70% ở `lifecycle`, `credential`, `handover`, `enforcement`; cổng CI-3 (kiến trúc), CI-5 (hợp đồng) bắt buộc đạt.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Thứ tự đưa các phần vào chạy theo mức rủi ro và phụ thuộc: phần nghiệp vụ thuần trước, phần phụ thuộc PH-12, PH-03 và OpenBao sau khi các giao diện của họ chốt, tránh viết mã trên giao diện còn đổi.

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| 1 | Khung module `onboarding`, schema `ph01_onboarding` với RLS, `TransitionTable`, hồ sơ, đầu mối, tài liệu đính kèm, danh sách (FR-01-001…010, 050); xóa module `apps/control/.../onboarding` cũ và cột `client_secret_sealed` | PH-20 (tổ chức), `pg-core`, Garage, OPA, thư viện dùng chung |
| 2 | Kiểm tra hợp lệ, nộp, thẩm định, phê duyệt, trần phạm vi (FR-01-011…019) | Hộp việc FR-00-070, PH-18 (lịch, thư) |
| 3 | Outbox, EVT-01-*, bản sao đọc nội bộ, đối chiếu hằng giờ (FR-01-037, 038) để PH-02, PH-10 dùng sớm | Debezium, Apicurio |
| 4 | Cổng tích hợp, saga SANDBOX, đăng ký khóa, bàn giao một lần (FR-01-020…022) | PH-12, PH-03, chính sách bọc của OpenBao (Q01-20, Q01-21) |
| 5 | Kiểm thử SANDBOX, kích hoạt PRODUCTION, xoay vòng, thu hồi, nhắc hạn, tạm ngừng, khôi phục, chấm dứt, cắt quyền, thao tác khẩn (FR-01-023…033) | PH-13, PH-02; bước 3, 4 |
| 6 | Thay đổi hồ sơ theo mức, mở rộng trần phạm vi (FR-01-034, 035) | Bước 2, 5 |
| 7 | Rà soát quyền, danh bạ, nhập hệ cũ, tham số (FR-01-039…043, 045, 046, 048, 049) | PH-13, PH-02, PH-20 |
| 8 | Đợt 2: tự vô hiệu, báo cáo rà soát, xuất danh bạ, thống kê (FR-01-036, 044, 047, 051); đánh giá Flowable (Q01-14) | Bước 7 |

: Lộ trình hiện thực

### 13.2. Rủi ro

Bảng dưới trình bày rủi ro.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Giao diện PH-12, PH-03 chưa chốt hoặc không lũy đẳng (Q01-03, Q01-20, Q01-28) | Cao | Cổng tích hợp tách riêng, thử với WireMock; chốt hợp đồng trước bước 4; phương án "tra trước khi tạo" theo `clientId` xác định |
| OpenBao không ép bọc bằng `min_wrapping_ttl` hoặc `unwrap` khác kỳ vọng (Q01-21) | Cao | Thử nghiệm sớm với bản OpenBao thật ở bước 4; dự phòng: mã yêu cầu bọc ở lớp `OpenBaoPort` và ArchUnit cấm đường đọc rõ, mất phần ép buộc ở chính sách nhưng vẫn một lần |
| Cắt quyền ≤ 60 giây phụ thuộc độ trễ APISIX, etcd (Q01-24) | Trung bình | Chặn ở chính cổng trước; đo ở thí điểm; cảnh báo sau 60 giây |
| Tenant nhỏ thiếu người cho bốn mắt (Q01-01) | Trung bình | So sánh theo định danh người dùng chứ không theo vai trò; vai trò thẩm định tạm qua PH-12 |
| Đầu mối là nhà thầu, tài khoản ở realm nào (Q01-05) | Trung bình | Tài khoản có ngày hết hạn; `HandoverGuard` chỉ so `sub`, không phụ thuộc realm |
| Mất mã bọc khi OpenBao chuyển đổi dự phòng | Trung bình | Kiểm và tạo lại bàn giao theo sổ tay (mục 11.4); bí mật còn nguyên trong KV vì chưa mở |
| Số liệu mức dùng của PH-13 sai hoặc thiếu dẫn tới đề xuất thu hồi nhầm | Trung bình | Chỉ là đề xuất, cờ `NO_USAGE_DATA`, người quyết định kèm lý do và xác thực lại, thông báo đơn vị trước khi thu hồi |
| Vòng lặp theo tenant tốn tài nguyên khi một DU phục vụ nhiều tenant | Thấp | Đánh thức theo sự kiện bằng `pg_notify` khi trên 50 tenant (mục 11.3) |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q01-20:** PH-12 và PH-03 chưa có tập thiết kế API. SDD giả định `createClient`, `createConsumer`, `blockClients` nhận `Idempotency-Key` và trả lại kết quả cũ khi lặp. Nếu không, saga phải tra theo `clientId` xác định (`{tenant}-{systemCode}-sbx`) trước khi tạo và chấp nhận cửa sổ trùng nhỏ. Cần PH-12, PH-03 xác nhận.

> **Câu hỏi mở Q01-21:** Bàn giao dựa vào việc OpenBao ép bọc bằng `min_wrapping_ttl` trên đường dẫn KV, và lưu mã bọc đã mã hóa bằng transit ở `wrap_token_sealed` (cột thêm so với EN-01-09, khác "chỉ lưu băm" của FR-01-022). Cần ATTT và nhóm hạ tầng xác nhận bản OpenBao dùng hỗ trợ đúng hành vi và chấp nhận cột này; đồng thời thống nhất tên vai trò PKI (FRS dùng `pki-http-clients`, SDD dùng mount `pki-clients` theo SEC-35 với vai trò `http-clients-{tenant}`).

> **Câu hỏi mở Q01-22:** NFR-01-015 đặt tên chỉ số `onboarding_*`, PH-05 dùng `dh_adapter_*`. Cần D04-01 hoặc D03-09 thống nhất tiền tố chung (đề xuất `dh_onboarding_*`).

> **Câu hỏi mở Q01-23:** Hạn thẩm định tính theo ngày làm việc (GĐ-01-04) cần lịch nghỉ lễ của tenant. SDD giả định PH-18 cung cấp `WorkingCalendarApi`; nếu chưa có, `ReviewClock` dùng thứ Hai đến thứ Sáu và danh sách ngày nghỉ do TA khai ở tham số.

> **Câu hỏi mở Q01-24:** NFR-01-008 (cắt quyền ≤ 60 giây) giả định API chặn của PH-03 trả về sau khi cấu hình đã ghi vào etcd và APISIX nhận trong vài giây. Cần PH-03 cam kết độ trễ này và cung cấp API đồng bộ; ACL Kafka ≤ 2 phút giao PH-10.

> **Câu hỏi mở Q01-25:** Tìm kiếm danh sách HTTT và danh bạ dùng PostgreSQL (GIN `pg_trgm`) là đủ cho 1.000 HTTT. D03-01 §4.3 cho phép OpenSearch tùy chọn trong `dh-connect` (quyết định ở SDD PH-02). Nếu PH-02 dùng OpenSearch, PH-01 có dùng chung không; đề xuất không dùng ở MVP vì dữ liệu nhỏ và có dữ liệu cá nhân.

> **Câu hỏi mở Q01-26:** Giao diện trong tiến trình `gateway.api.ConsumerGatewayApi`, `catalog.api.ServiceUsageApi`, `TaskInboxApi` do PH-03, PH-02 và hộp việc chung phải cung cấp; chưa có tập SDD của PH-02, PH-03. Cần chốt tên và hợp đồng; nếu PH-02 hoặc PH-03 tách khỏi `dh-connect` thì dùng bộ chuyển REST.

> **Câu hỏi mở Q01-27:** Phản hồi mở bàn giao chứa bí mật đi qua BFF, APISIX và Coraza. Cần ATTT xác nhận tắt được việc kiểm tra và ghi thân phản hồi ở các lớp này riêng cho tuyến `/handovers:open`, và BFF không đưa phản hồi vào bộ đệm hay phiên Valkey.

> **Câu hỏi mở Q01-28:** PH-12 và PH-03 trả kết quả đồng bộ hay bất đồng bộ qua callback (scope `onboarding:provision-callback` ở FRS §3.3)? SDD hỗ trợ cả hai (cờ `onboarding.saga.async-callback`) và cho kích hoạt PRODUCTION trả `202` khi chưa xong sau 10 giây thay vì `200` như FR-01-024; D03-04-PH01 đã ghi nhận mã `202` và đặc tả callback là API-01-087; việc còn lại là chốt đồng bộ hay bất đồng bộ với PH-12, PH-03 (Q01-56 của tập API).

> **Câu hỏi mở Q01-29:** Dữ liệu liên hệ đầu mối là dữ liệu cá nhân mức Hạn chế; SDD lưu rõ trong cột, bảo vệ bằng RLS và mã hóa tầng khối. Nếu hội đồng hoặc ATTT cho rằng cần mã hóa trường (SEC-31) vì danh bạ cả tỉnh dễ bị khai thác hàng loạt, tìm kiếm phải đổi sang chỉ mục băm theo token; cần quyết định trước khi chốt D03-03-PH01.

## 14. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây thuộc tài liệu dùng chung hoặc phân hệ khác, nằm ngoài quyền sửa của tập này; ghi lại để đợt đồng bộ cuối thực hiện.

| # | Tài liệu | Đề nghị |
|---|---|---|
| 1 | D03-03-PH01 (CSDL) | Lập bảng theo danh sách SDD đề xuất: `member_system`, `technical_profile`, `data_demand`, `scope_ceiling`, `contact` (thêm `search_text`), `attachment`, `review_step` (thêm `input_hash`), `app_credential`, `handover` (thêm `wrap_token_sealed`, trạng thái kỹ thuật `OPENING`), `sandbox_test`, `state_history`, `emergency_action`, `change_request`, `access_review_cycle`, `access_review_item`, `review_confirmation`, `legacy_import_job`, `template`, `provisioning_saga`, `saga_step`, `enforcement_task`, `outbox`, `inbox`, `notify_outbox`, `idempotency_record`, `shedlock`; chỉ mục ở mục 11.1; chính sách RLS; changeset di trú từ schema `ph01` cũ (GAP-01-02, 03) |
| 2 | D03-04-PH01 (API) | **Đã đồng bộ ở bản 0.2:** API-01-044 trả `200` hoặc `202`; ERR-01-051, 054 cho `Idempotency-Key`; callback là API-01-087; API-01-088 cho tác vụ nền. Ảnh chụp EVT-01-03 mang `ceilingDataTypes` (kiểm ở D03-04-PH01 §4) |
| 3 | D02-03-PH01 (FRS) | EN-01-09 thêm `wrapTokenSealed` và trạng thái kỹ thuật `OPENING`; FR-01-022 đổi "chỉ lưu băm" thành "băm liên kết và mã bọc đã mã hóa"; FR-01-021 thống nhất tên vai trò PKI; FR-01-024 đầu ra `200` hoặc `202` (Q01-21, Q01-28) |
| 4 | D03-07 | SEC-33: ghi chính sách OpenBao ép bọc khi đọc bí mật client (`min_wrapping_ttl`); thêm ca "OpenBao chuyển đổi dự phòng làm mất mã bọc" vào kịch bản sự cố |
| 5 | D03-09 | Dòng định cỡ cho module `onboarding` (khoảng 0,3 vCPU, 384 MiB), Debezium outbox cho `ph01_onboarding`, khóa transit `dh-{tenant}-handover`, bucket `dh-{tenant}-onboarding`, chính sách OpenBao sinh theo tenant lúc khởi tạo |
| 6 | D04-01 (Quy ước mã) | Tiền tố chỉ số (Q01-22); mẫu `TenantJobRunner` và saga bền làm mẫu chung vì D03-01 §7.3 cũng áp saga cho khởi tạo tenant (PH-20) |
| 7 | Tập PH-12, PH-03, PH-02, PH-18, PH-13, PH-14, PH-20 | Cung cấp giao diện PH-01 cần: PH-12 tạo, vô hiệu client lũy đẳng, thu hồi token, xoay bí mật, gỡ scope, đăng ký khóa; PH-03 chặn client ≤ 60 giây, consumer lũy đẳng; PH-02 `ServiceUsageApi`, kiểm trần; PH-18 `NotificationApi`, `WorkingCalendarApi`, tham số `onboarding.*`; PH-13 `sandboxActivity`, `usageByCredential`; PH-14 `remainingQuota`; PH-20 danh mục tổ chức, `TenantRegistry`, sự kiện tenant |
| 8 | D00-04 §2 | PH-01: đổi cột "Tài liệu" thành "FRS 0.1, UC 0.1, SDD 0.1" |
| 9 | D03-06-PH01 (màn hình) | Hiển thị tiến độ saga theo API `provisioning`; thông báo cho kích hoạt `202`: "Đang cấp định danh môi trường thật. Theo dõi tiến độ ở tab Ứng dụng và thông tin xác thực" |
| 10 | Đề xuất ADR (chưa cấp số) | (a) Bàn giao thông tin xác thực một lần bằng bọc phản hồi OpenBao ép bằng chính sách và mã bọc lưu mã hóa (cùng đề xuất 14(a) của FRS); (b) Saga bền trong CSDL của phân hệ khởi tạo, bộ chạy `SKIP LOCKED`, lũy đẳng bằng `sagaId`, dùng làm mẫu cho PH-20; (c) Nguyên tắc cắt quyền "chặn cổng trước, đặt trạng thái trước, thử lại tới khi xong, không hoàn tác" cho mọi phân hệ có lệnh ngừng (PH-10, PH-19) |
| 11 | D05-02-PH01 (kiểm thử) | Ca canary, gây lỗi từng bước saga, giết pod ở ba điểm, cắt quyền 60 giây khi PH-12 chậm, bàn giao theo bảng mục 4.7 |

: Đề nghị đồng bộ với tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD và quy chuẩn K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu, vị trí kiến trúc và hiện trạng mã, cấu trúc gói `vn.datahub.connect.onboarding`, mô hình miền và 15 thành phần có bảng đặc tả 10 mục, 7 sơ đồ trình tự (kết nạp, saga, bàn giao, cắt quyền, kích hoạt, xoay vòng, rà soát), 11 máy trạng thái, xử lý lỗi và nhất quán, cấu hình và cờ tính năng, quan sát, hiệu năng và khả năng mở rộng, kiểm thử, lộ trình, 8 rủi ro, 10 câu hỏi mở (Q01-20…29), 11 đề nghị đồng bộ. Nguồn: D02-03-PH01, D02-04-PH01, D03-01 §4 và §7.3, D03-07, D03-10, ADR-001, 003, 006, 007, 012, 031, 032, 041, 042, 056, 058, 069, mã hiện trạng `apps/control` |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: sửa lỗi lũy đẳng thành ERR-01-051, 054; callback saga là API-01-087 (ERR-01-053); xuất tệp nền API-01-088; mở bàn giao không dùng Idempotency-Key; số liệu 88 API, 54 mã lỗi; thêm đoạn mở các mục |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Chốt câu hỏi mở đợt đồng bộ: Q418 (Q01-57), Q380 (PH-12 không nghe EVT-01-11), Q389, Q426, Q428 |
