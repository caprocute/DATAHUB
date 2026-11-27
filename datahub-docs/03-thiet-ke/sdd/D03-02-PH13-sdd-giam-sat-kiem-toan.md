---
ma_tai_lieu: D03-02-PH13
ten: Thiết kế chi tiết phần mềm phân hệ PH-13 Giám sát và kiểm toán
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kỹ sư nền tảng quan sát, ATTT, vận hành, kiến trúc sư, hội đồng thẩm định
phan_he: PH-13
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Giám sát và kiểm toán gồm cấu trúc mã hai module audit và observability, 21 thành phần, mười sơ đồ trình tự, máy trạng thái, xử lý lỗi, cách ly tenant, bảo mật, cấu hình và quan sát, đủ để lập trình và kiểm thử 61 yêu cầu chức năng.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH13 FRS; D02-04-PH13 UC; D03-03-PH13 CSDL; D03-04-PH13 API; D03-06-PH13 Màn hình; D03-07 ATTT; D03-09 Hạ tầng; D03-10 Đa tenant; ADR-011; ADR-031
---

# D03-02-PH13 · Thiết kế chi tiết Giám sát và kiểm toán

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 61 FR của [D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) và 42 use case của [D02-04-PH13](../../02-yeu-cau/use-case/D02-04-PH13-use-case-giam-sat-kiem-toan.md). Phân hệ không thêm đơn vị triển khai: phần ứng dụng là hai module Spring Modulith `audit` và `observability` trong `dh-platform`, phần quan sát là bộ hạ tầng `dh-obs` (OpenTelemetry Collector, Mimir, Loki, Tempo, Alertmanager, Grafana) cùng ClickHouse ở `dh-olap`. Thiết kế dựa trên sáu quyết định:

1. **Hai đường dữ liệu không bao giờ gặp nhau** (ADR-011, ADR-031). Đường quan sát chấp nhận lấy mẫu và mất một phần, lưu ngắn. Đường kiểm toán không lấy mẫu, không chặn người dùng và không mất bản ghi: mỗi khâu giữ bản ghi cho tới khi khâu sau xác nhận (hộp thư đi của DU, Kafka, bảng chỉ-thêm).
2. **Chuỗi băm ghi tuần tự theo tenant bằng một khóa tư vấn** trong cùng giao dịch với việc xác nhận offset Kafka. Băm tính trên JSON chuẩn tắc RFC 8785, neo ký bằng khóa transit không xuất được của OpenBao, bản sao WORM 5 phút và hai tầng kiểm tra: gia tăng mỗi lần neo, và kiểm tra lại toàn bộ chuỗi trực tuyến mỗi ngày để mọi sửa đổi bản ghi cũ bị phát hiện trong 24 giờ (NFR-13-016). Điểm này chặt hơn cách đọc "từ neo gần nhất" ở FR-13-014 nên được nêu ở §4.7 và ghi vào đề nghị đồng bộ.
3. **Cách ly tenant bằng hai lớp**: tổ chức `X-Scope-OrgID` do máy chủ đặt từ token (Mimir, Loki, Tempo tắt liên kết đa tenant), cộng bộ chặn biểu thức ép nhãn `tenant`; kiểm thử rò rỉ T90 → T91 chạy hằng ngày (SEC-84, SEC-87).
4. **PH-13 quan sát và kiểm toán chính nó như mọi DU**: thao tác tra cứu, xuất, đổi luật đi qua `dh-audit`; thao tác chỉ-đọc nhạy cảm ghi vết trước khi trả kết quả và từ chối nếu không ghi được (BR-13-006).
5. **Cảnh báo tách làm hai phần**: Ruler của Mimir đánh giá luật và Alertmanager gom, chống lặp, định tuyến; `dh-platform` giữ vòng đời cảnh báo, lịch trực, leo thang và thông báo. Kênh Nghiêm trọng có đường độc lập ngoài hạ tầng site và nhịp tim `Watchdog` chứng minh chính hệ giám sát còn sống.
6. **Hai câu hỏi do SAD và D03-09 để lại được chốt ở đây**: ClickHouse làm kho siêu dữ liệu lượt gọi API (đóng Q331, Q13-06) và `dh-runtime` ghi kiểm toán trực tiếp lên Kafka `acks=all` có đệm đĩa 1 GB cho thao tác thường, từ chối thao tác Nhạy cảm khi không ghi vết được (đóng Q13-03; PH-14 xác nhận ở Q13-21).

Tài liệu không tạo ADR mới. Các quyết định thiết kế mới nằm ở §4 và được đề xuất thành ADR ở mục "Đề nghị đồng bộ" cuối tập.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| FR hiện thực | 61 (59 MVP, 2 Đợt sau: FR-13-055, 060) |
| Module Modulith | 2 (`audit`, `observability`) trong `dh-platform`, cộng thư viện `dh-audit` nhúng ở mọi DU |
| Thành phần thiết kế ở chương 4 | 21 (khối đặc tả 10 mục, mục 4.2 đến 4.22) |
| Sơ đồ trình tự | 10 (mục 5.1 đến 5.10) |
| Máy trạng thái | 7 (cảnh báo, cảnh báo an ninh, luật, xuất bằng chứng, phân vùng, toàn vẹn chuỗi, lượt kiểm tra) |
| Mã lỗi, sự kiện, API tham chiếu | ERR-13-001…044 và 101…126; EVT-13-01…14; API-13-001…090 |
| Công việc nền theo lịch | 18 (bảng ở §11.2) |
| Câu hỏi mở mới | 8 (Q13-20…27) |

: Con số chính của D03-02-PH13

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu đi từ vị trí trong kiến trúc (§2), cấu trúc mã (§3), từng thành phần (§4), sequence của FR phức tạp (§5) tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát, hiệu năng, kiểm thử và lộ trình. Mã ERR, BR, NFR, EN, UI là của [FRS](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md); mã API, EVT được định nghĩa đầy đủ ở D03-04-PH13; bảng CSDL ở D03-03-PH13; màn hình ở D03-06-PH13. Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới.

Phạm vi thiết kế gồm: bộ tiếp nhận và chuỗi băm kiểm toán, neo, WORM, kiểm tra toàn vẹn, tra cứu và xuất bằng chứng; cổng truy vấn quan sát và cách ly tenant; bảng điều khiển; luật và vòng đời cảnh báo; phát hiện bất thường an ninh; SIEM; khởi tạo tenant. Ngoài phạm vi: cấu hình hạ tầng của Mimir, Loki, Tempo, ClickHouse (D03-09), lược đồ bảng (D03-03-PH13), hợp đồng REST và AsyncAPI (D03-04-PH13), bố cục màn hình (D03-06-PH13).

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4 và Spring Modulith cho `dh-platform` |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` cho `ph13_audit`, `ph13_obs` |
| ADR-004 | Kafka cho kênh bản ghi kiểm toán và siêu dữ liệu lượt gọi |
| ADR-008 | Garage cho bucket tạm của gói bằng chứng |
| ADR-009, ADR-068 | GitOps cho cấu hình `dh-obs`, bộ luật chuẩn |
| ADR-011 | OpenTelemetry, Mimir, Loki, Tempo, Grafana; kiểm toán là dòng riêng |
| ADR-012 | OpenBao: transit ký neo và gói, HMAC, tài khoản CSDL động |
| ADR-013 | Tách control plane và data plane: PH-13 không chặn data plane |
| ADR-023 | ECharts cho bảng điều khiển trong `dh-console` |
| ADR-030 | ATTT cấp độ 3, sẵn sàng cấp độ 4 |
| ADR-031 | Chuỗi băm theo tenant, neo ký hằng giờ, WORM, thời hạn lưu |
| ADR-034 | DR hai site: kiểm toán và cảnh báo khi chuyển site |
| ADR-042 | Inbox, outbox trong DU, nền của `dh-audit` |
| ADR-072 | Cấp phát topic và ACL qua GitOps cho `{tenant}.obs.*` |

: ADR áp dụng cho PH-13

### 1.2. Người đọc và tài liệu tham chiếu

Mỗi nhóm người đọc chỉ cần một phần của tài liệu; bảng dưới chỉ ra phần nào, và đoạn sau nêu cách đọc khối đặc tả ở chương 4.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-platform` (audit) | Chương 3, 4.1 đến 4.10, 5.1 đến 5.5, 8 |
| Kỹ sư `dh-platform` (observability) | Chương 3, 4.11 đến 4.22, 5.6 đến 5.10, 9 |
| Kỹ sư mọi DU nguồn | §4.2 (`dh-audit`), §7, §10 |
| Kỹ sư nền tảng quan sát, vận hành | §2.1, §4.11, §4.19, chương 10, 11 |
| ATTT, kiểm toán viên kỹ thuật | §4.4 đến 4.7, §4.10, chương 7 |
| Hội đồng thẩm định | Tóm tắt, chương 2, §4.7, §5.1, §5.2, §13 |

: Người đọc và phần cần đọc

Mỗi thành phần ở chương 4 mở đầu bằng một bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế. Tài liệu tham chiếu chính: D03-01 SAD §4 (`dh-platform`), D03-07 ATTT §7 (SEC-60…67) và §8 (SEC-84…87), D03-09 hạ tầng §2.3, §5, §9, D03-10 đa tenant §3, §5, D04-01 quy ước mã, D02-08 ma trận quyền.

### 1.3. Thuật ngữ và chữ viết tắt

Thuật ngữ nghiệp vụ dùng chung với FRS §1.4 và §4.1. Các từ kỹ thuật riêng của tài liệu này:

| Thuật ngữ | Nghĩa |
|---|---|
| Hộp thư đi (outbox) | Bảng trong CSDL của DU, ghi cùng giao dịch nghiệp vụ; bộ chuyển Debezium đẩy lên Kafka (ADR-042) |
| `dh-audit` | Thư viện chung nhúng ở mọi DU: sinh bản ghi kiểm toán, che giá trị Nhạy cảm, ghi hộp thư đi, đếm `dh_audit_emitted_total` |
| JCS | JSON Canonicalization Scheme, RFC 8785: dạng JSON chuẩn tắc để tính băm lặp lại được |
| Khóa tư vấn | `pg_advisory_xact_lock` của PostgreSQL, dùng để mỗi tenant chỉ có một người ghi chuỗi tại một thời điểm |
| OrgID | Giá trị tiêu đề `X-Scope-OrgID` chọn tổ chức (tenant) trong Mimir, Loki, Tempo |
| Đoạn neo | Dải bản ghi nằm giữa hai neo liên tiếp; đơn vị chia việc song song khi kiểm tra |
| Cách ly (quarantine) | Bảng giữ nguyên bản ghi không đạt kiểm tra tiếp nhận; không có hàng đợi thư chết (DLT) cho kênh kiểm toán |
| Fail-closed | Không ghi vết được thì từ chối thao tác, thay vì cho qua |

: Thuật ngữ kỹ thuật dùng trong tài liệu

### 1.4. Cấu trúc tài liệu

Tài liệu có 13 chương theo khuôn K-SDD; bảng dưới nối từng chương với nhóm FR mà chương đó hiện thực.

| Chương | Nội dung | FR chính |
|---|---|---|
| 2 | Vị trí trong kiến trúc, DU, vùng mạng, phụ thuộc, hiện trạng mã | Tất cả |
| 3 | Cấu trúc gói, quy tắc phụ thuộc, giao diện công bố, DTO | Tất cả |
| 4.1 | Mô hình miền | Tất cả |
| 4.2 đến 4.10 | Đường kiểm toán: `dh-audit`, tiếp nhận, chuỗi, neo, WORM, kiểm tra, đối chiếu, tra cứu, xuất | FR-13-010…025 |
| 4.11 đến 4.15 | Đường quan sát: thu thập, kiểm tra tổng hợp, cổng truy vấn, tra log và trace, bảng điều khiển | FR-13-001…009, 026…041, 056…058 |
| 4.16 đến 4.19 | Cảnh báo: luật, vòng đời, thông báo, tự giám sát | FR-13-042…050 |
| 4.20, 4.21 | Phát hiện an ninh và SIEM | FR-13-051…055 |
| 4.22 | Vòng đời tenant, tham số | FR-13-059…061 |
| 5 | Mười sơ đồ trình tự | |
| 6 đến 11 | Đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, hiệu năng, vận hành, khả năng mở rộng | |
| 12, 13 | Kiểm thử, lộ trình, rủi ro, câu hỏi mở, đề nghị đồng bộ | |

: Cấu trúc chương của D03-02-PH13

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-13 chạy trong DU `dh-platform` (Control, Z3, D03-01 §4.1) và dựa vào ba nhóm hạ tầng: bộ quan sát ở Z7, kho dữ liệu ở Z5 và kho khóa, kho WORM ở Z6. Bảng dưới nêu từng thành phần, nơi chạy và vùng.

| Thành phần | DU hoặc nơi chạy | Vùng | Ghi chú |
|---|---|---|---|
| Module `audit` (API, bộ tiếp nhận, công việc nền) | `dh-platform` | Z3 | Ba vai trò chạy `api`, `ingest`, `jobs` (§11.1) |
| Module `observability` (cổng truy vấn, bảng điều khiển, cảnh báo, phát hiện, SIEM, khởi tạo tenant) | `dh-platform` | Z3 | Cùng ảnh, cùng Deployment ở hồ sơ nhỏ |
| Thư viện `dh-audit`, bộ đệm đĩa | Nhúng ở mọi DU Spring và `dh-runtime` | Theo DU (Z2, Z3, Z4) | Phiên bản Quarkus cho `dh-runtime` |
| OTel Collector dạng agent | DaemonSet mỗi nút | Theo nút | Receiver `otlp`, `prometheus`, `filelog` |
| OTel Collector dạng gateway (3 bản sao) | `dh-obs` | Z7 | Gắn tenant, che, lấy mẫu đuôi, xuất SIEM |
| Mimir (có Ruler), Loki, Tempo, Alertmanager (3 bản sao), Grafana | `dh-obs` | Z7 | Đa tenant theo OrgID; Grafana dùng CSDL `pg-infra` |
| `otel-siem` (2 bản sao): bộ xuất sang SIEM, SOC | `dh-obs` | Z7 | Tách khỏi gateway chính để đổi mục tiêu SIEM không cuộn lại tuyến thu thập (§4.21) |
| `alert-relay` (2 bản sao): kênh cảnh báo `CRITICAL` độc lập | `dh-obs` | Z7 | Không dùng PH-18, `pg-core`, Kafka; bí mật riêng ở OpenBao (§4.18) |
| ClickHouse, ClickHouse Keeper | `dh-olap` | Z5 | Bảng `access_log`, view vật chất hóa theo phút, giờ |
| Schema `ph13_audit`, `ph13_obs` và bản sao đọc | `pg-core` (CNPG) | Z5 | RLS bắt buộc; vai trò `ph13_app`, `ph13_verify`, `ph13_archive` cấp động |
| Topic `{tenant}.obs.audit.recorded.v1`, `{tenant}.obs.access.logged.v1`, `{tenant}.obs.*` | Kafka | Z5 | Giữ 7 ngày (kiểm toán), 3 ngày (lượt gọi); cấp qua GitOps (ADR-072) |
| Khóa `dh-audit-sign`, khóa HMAC `dh-{tenant}-audit-hmac`, tài khoản CSDL động | OpenBao | Z6 | Transit không xuất; chính sách riêng cho từng vai trò |
| Bucket `dh-worm-audit` (Object Lock tuân thủ), bucket chứng cứ `dh-evidence` | Ceph RGW, tách Garage | Z6 | Tiền tố `{tenant}/`; SEC-75 cần Object Lock nên chứng cứ không nằm ở Garage |
| Bucket tạm `dh-audit-export-tmp` | Garage | Z5 | Gói bằng chứng 7 ngày |
| Bộ nhận nhịp tim `Watchdog` | Ngoài cụm hoặc do nhà cung cấp nền tảng vận hành | Ngoài site | Kênh độc lập (FR-13-049, Q13-24) |

: Đơn vị triển khai và vùng mạng của PH-13

Mọi lưu lượng giữa các vùng đi qua mesh mTLS và chính sách mạng từ chối mặc định (SEC-14, SEC-15). Nguồn dữ liệu quan sát đẩy tới Collector gateway ở Z7; ClickHouse chỉ nhận từ `dh-platform` và từ Kafka; kho WORM chỉ nhận ghi từ tài khoản của bộ sao WORM và đọc từ bộ kiểm tra, bộ xuất bằng chứng.

### 2.2. Sơ đồ thành phần

Sơ đồ đặt các thành phần của PH-13 theo ba đường dữ liệu (kiểm toán, quan sát, cảnh báo) và cho thấy chỗ hai module `audit`, `observability` chạm hạ tầng bên ngoài.

```{.mermaid caption="Sơ đồ thành phần PH-13 trong dh-platform và hạ tầng liên quan"}
flowchart TB
  subgraph SRC["Nguồn phát"]
    DUS["DU Spring, dh-runtime<br/>thư viện dh-audit, OTel SDK"]
    APX["APISIX<br/>kafka-logger, OTLP"]
  end
  subgraph OBS["dh-obs (Z7), dh-olap (Z5)"]
    COL["Collector agent và gateway<br/>gắn tenant, che, lấy mẫu đuôi"]
    MIM["Mimir và Ruler"]
    LOK["Loki"]
    TMP["Tempo"]
    AMG["Alertmanager"]
    CHS[("ClickHouse<br/>access_log")]
  end
  subgraph PLT["dh-platform (Z3)"]
    subgraph AUD["module audit"]
      ING["ingest<br/>BatchIngestService"]
      CHN["chain<br/>ChainWriter"]
      ANC["anchor, worm<br/>AnchorService, WormBatchWriter"]
      VER["verify<br/>VerificationService"]
      SRH["search, export<br/>AuditSearchService, ExportWorker"]
      RCN["reconcile, partition"]
    end
    subgraph OBM["module observability"]
      QRY["query<br/>TenantScope, ExpressionGuard"]
      DSH["dashboard, logs, trace, access"]
      ALT["alert<br/>RuleService, AlertWebhookHandler"]
      DET["detect, siem"]
      TNT["tenant, settings, probe, pii"]
    end
  end
  PG[("pg-core<br/>ph13_audit, ph13_obs")]
  KF[("Kafka")]
  OB[("OpenBao")]
  WM[("Kho WORM")]
  DUS -->|"OTLP"| COL
  APX -->|"OTLP"| COL
  APX -->|"siêu dữ liệu lượt gọi"| KF
  COL --> MIM
  COL --> LOK
  COL --> TMP
  KF --> CHS
  DUS -->|"outbox, Debezium"| KF
  KF --> ING --> CHN --> PG
  CHN --> ANC
  ANC -->|"ký"| OB
  ANC --> WM
  VER --> PG
  VER --> WM
  SRH --> PG
  SRH --> WM
  RCN --> MIM
  QRY --> MIM
  QRY --> LOK
  QRY --> TMP
  QRY --> CHS
  DSH --> QRY
  ALT -->|"đẩy luật"| MIM
  AMG -->|"webhook"| ALT
  MIM --> AMG
  DET --> PG
  DET --> AMG
  ALT --> PG
  TNT --> PG
```

Sơ đồ cho thấy ba đường. Đường kiểm toán đi một chiều từ `dh-audit` qua Kafka tới `ingest`, `chain`, bảng chỉ-thêm, rồi `anchor` và `worm`; không có mũi tên từ đường quan sát vào `audit_event`. Đường quan sát đi từ Collector vào ba kho và ClickHouse; mọi truy vấn của người dùng đều qua mô-đun `query`, nơi duy nhất đặt OrgID. Đường cảnh báo vòng từ Mimir Ruler tới Alertmanager, webhook về `alert` để ghi vòng đời và gửi thông báo, còn `detect` đọc bản ghi kiểm toán và đẩy cảnh báo an ninh vào cùng Alertmanager.

### 2.3. Phụ thuộc với module và phân hệ khác

PH-13 vừa nhận dữ liệu từ mọi DU vừa cung cấp dịch vụ cho vài phân hệ; bảng dưới nêu từng quan hệ, hướng gọi và cách gọi, để thấy phần nào là bắt buộc và phần nào là mềm.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| Mọi DU nguồn | DU → PH-13 | `dh-audit` (outbox, Debezium, Kafka); API dự phòng API-13-089 | Bản ghi kiểm toán (FR-13-010) |
| Mọi DU, APISIX | DU → PH-13 | OTLP, Prometheus, `kafka-logger` | Dữ liệu quan sát |
| PH-12 (`dh-platform`, Keycloak, OPA) | PH-13 → PH-12 | `PermissionApi`, `StepUpApi` (Modulith, trong tiến trình); sự kiện Keycloak, quyết định OPA vào Loki | Quyền `PERM-13-*`, xác thực lại phiên; nguồn kiểm toán |
| PH-20 (`dh-platform`) | PH-20 → PH-13 | `TenantObservabilityApi` (gói `observability.api`); REST API-13-072, 073 cho hồ sơ tách DU | Khởi tạo, đóng chuỗi (FR-13-059, 060) |
| PH-18 (`dh-platform`) | hai chiều | `NotificationApi` của PH-18 (PH-13 gọi); `DiagnosticsApi` của PH-13 (PH-18 gọi) | Gửi thư, SMS; ngữ cảnh DLQ (FR-13-057) |
| PH-16 (`dh-platform`) | PH-16 → PH-13 | `MetricsSummaryApi` | Số liệu thô chỉ tiêu (FR-13-056) |
| PH-01 (`dh-connect`) | PH-13 → PH-01 | API-01-089 (scope `onboarding:suspension-proposal`), tài khoản dịch vụ của `dh-platform` | Đề xuất tạm ngừng HTTT; PH-01 tạo việc khẩn cho SO (Q13-12, đã chốt 27/11/2026) |
| PH-10 | PH-13 → PH-10 | Cấp phát GitOps (ADR-072); đọc chỉ số lag qua Mimir | Topic `{tenant}.obs.*`, bảng sự kiện |
| PH-03 | PH-03 → PH-13 | Cấu hình plugin `kafka-logger`; chỉ số `dh_connect_config_revision` | Siêu dữ liệu lượt gọi, bảng nút gateway |
| PH-14, PH-19, PH-09 | → PH-13 | `dh-audit` (hành động `PII.REVEAL`, hoàn tiền, tra cứu có mục đích) | Nguồn của luật phát hiện UC-SEC-10, 11, 14 |
| OpenBao, Ceph RGW, ClickHouse, Grafana | PH-13 → | Client có thời gian chờ, ngắt mạch (§8.3) | Ký, WORM, lượt gọi API, dashboard |

: Phụ thuộc với module và phân hệ khác

Luật Modulith: `observability` chỉ import `audit.api` (không import `audit.internal`); `audit` không import `observability`. Chiều `audit` → `observability` đi qua sự kiện ứng dụng bền (`@ApplicationModuleListener`, sổ sự kiện Modulith) như `ChainBrokenEvent`, `ReconciliationMismatchEvent`, nên chuỗi nghi vấn luôn dẫn tới cảnh báo ngay cả khi `observability` đang khởi động lại. PH-12, PH-18, PH-20, PH-16 cùng DU nên gọi nhau trong tiến trình; REST ở D03-04-PH13 là bản công bố cho hồ sơ triển khai tách DU và cho tài khoản máy bên ngoài. ArchUnit kiểm ở CI (CI-3).

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện chưa có phần nào của PH-13 theo thiết kế mới; bảng dưới nêu mã sẵn có gần nhất, khoảng cách tới thiết kế và cách chuyển.

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| Bảng thường `application_audit` ở `apps/control` (`AuditEntryDto`, không chuỗi băm, không tenant) | Bảng chỉ-thêm `ph13_audit.audit_event` có chuỗi băm theo tenant | GAP-13-01: `apps/control` chuyển sang gọi `dh-audit`; dữ liệu cũ của hệ thử nghiệm không di trú vào chuỗi, lưu bản xuất ở WORM (Q13-09) |
| `libs/common-java` chỉ có `TraceIds` (UUID thay cho `traceparent`) | `dh-audit` và nền quan sát dùng OTel SDK, W3C Trace Context | GAP-13-02: `TraceIds` giữ cho mã cũ, mã mới dùng OTel; thư viện `dh-audit` là mô-đun mới |
| APISIX `deploy/apisix/config.yaml` bật plugin `prometheus` | Thêm `opentelemetry`, `kafka-logger` (không ghi thân bản tin, không ghi `Authorization`) | GAP-13-03: cấu hình ở PH-03, PH-13 chỉ nhận |
| Pod Camel có chú thích `prometheus.io/scrape` | Collector agent thu theo `ServiceMonitor` hoặc chú thích, gắn `tenant` từ namespace | GAP-13-04 |
| Không có bộ LGTM, ClickHouse, kho WORM, Alertmanager trong `deploy/` | Bộ `dh-obs`, `dh-olap`, bucket WORM theo D03-09 | GAP-13-05: GitOps ở kho cấu hình hạ tầng (ADR-009) |
| Không có trang giám sát, chỉ log JMX hệ cũ | 18 màn UI-13-01…18 | GAP-13-06: hệ cũ giữ chạy song song tới khi đối chiếu số liệu đạt (BP-09) |

: Hiện trạng mã và đường chuyển

## 3. Cấu trúc mã nguồn

### 3.1. Module `audit` trong `dh-platform`

Module `audit` sở hữu toàn bộ đường kiểm toán và là chủ duy nhất của schema `ph13_audit`. Cấu trúc gói theo K-SDD: `api` là chỗ duy nhất module khác được import, `internal` không lộ ra ngoài, `events` chứa bản ghi sự kiện phát qua outbox.

```text
vn.datahub.platform.audit
├── api/                       # AuditHistoryApi, AuditChainAdminApi, AuditDetectionQueryApi, DTO, ChainBrokenEvent
├── web/                       # @RestController /api/audit/v1, InternalAuditController (records:batch), ProblemDetail ERR-13-*
├── internal/
│   ├── ingest/                # AuditIngestListener (Kafka), BatchIngestService (dùng chung với API-13-089), RecordValidator,
│   │                          # SensitiveScanner, SourceAuthorizer, QuarantineWriter
│   ├── chain/                 # ChainWriter, CanonicalJson (RFC 8785), HashCalculator, TenantChainLock, ChainStatusService
│   ├── anchor/                # AnchorScheduler, AnchorService, TransitSigner (OpenBao), AnchorPublisher (bảng, WORM, SIEM)
│   ├── worm/                  # WormBatchWriter, WormClient (S3 SDK v2), WormReader, RetentionExtender (tài khoản riêng)
│   ├── verify/                # VerificationService, SegmentVerifier, WormComparator, TamperProbe, BreakHandler
│   ├── forensics/             # EvidenceCollector (SEC-75), bucket chứng cứ
│   ├── reconcile/             # ReconciliationService (đọc dh_audit_emitted_total từ Mimir)
│   ├── partition/             # PartitionManager, ArchiveService (vai trò ph13_archive), RetentionPolicy
│   ├── search/                # AuditSearchService, ObjectKeyHasher (HMAC), HistoryService, CrossTenantReport, ChainIndicator
│   ├── export/                # ExportService, ExportWorker, BundleBuilder, BundleSigner, ExportJanitor
│   └── guard/                 # SensitiveReadGuard (fail-closed), StepUpVerifier, ReasonValidator, AuditedRead (chú thích)
└── events/                    # EVT-13-05…09, 11, 12 (record), OutboxPublisher
```

### 3.2. Module `observability` trong `dh-platform`

Module `observability` sở hữu schema `ph13_obs` và là cửa duy nhất tới Mimir, Loki, Tempo, ClickHouse, Grafana và Alertmanager. Quy tắc quan trọng nhất của module là mọi lời gọi tới kho quan sát phải đi qua `internal.query` để OrgID được đặt đúng một nơi.

```text
vn.datahub.platform.observability
├── api/                       # ComponentHealthApi, DiagnosticsApi, MetricsSummaryApi, TenantObservabilityApi, DTO
├── web/                       # @RestController /api/observability/v1, AlertmanagerWebhookController (nội bộ, mTLS)
├── internal/
│   ├── query/                 # TenantScope, OrgIdResolver, ExpressionGuard, MimirClient, LokiClient, TempoClient,
│   │                          # ClickHouseClient, QueryLimiter, QueryAuditor
│   ├── dashboard/             # OverviewService, ComponentStatusEvaluator, DeploymentView, FlowView, EndpointView,
│   │                          # GatewayView, KafkaView, BusinessView, SecurityView, DashboardSetSync (Grafana API)
│   ├── logs/                  # LogSearchService, SimpleQueryCompiler (trường:giá-trị → LogQL), LiveTailService (SSE), SavedQueryService
│   ├── trace/                 # TraceService, CorrelationService, TimeBreakdown, InsightGenerator
│   ├── access/                # AccessLogService (ClickHouse access_log, view vật chất hóa)
│   ├── alert/                 # RuleService, RunbookService, StandardRuleCatalog, RulePublisher (Mimir Ruler API),
│   │                          # AlertWebhookHandler, AlertStateMachine, GroupingPolicy, SilenceService, AlertStatsService,
│   │                          # NotificationService, EscalationScheduler, OnCallResolver, ChannelRegistry
│   ├── selfmon/               # MonitoringHealthService, CapacityWatcher, HeartbeatContract
│   ├── detect/                # DetectionRuleCatalog, DetectionEngine, SecurityAlertService, SuspensionProposer,
│   │                          # IncidentReportGenerator (Đợt sau)
│   ├── siem/                  # SiemTargetService, SiemPipelineRenderer (cấu hình Collector gateway), SiemHealthProbe
│   ├── probe/                 # SyntheticProbeRunner, ProbeDefinitionService
│   ├── pii/                   # PiiScanner (mẫu Loki), PiiFindingRepository
│   ├── tenant/                # ObsProvisioner, OverridesReconciler, TenantObsConfigService, QuotaService, LifecycleCloser
│   └── settings/              # SettingsService (tham số 13.*), ParameterGuard
└── events/                    # EVT-13-01…04, 10, 13, 14 (record), OutboxPublisher
```

### 3.3. Thư viện `dh-audit` và kho cấu hình `dh-obs`

`dh-audit` là thư viện chung nằm ngoài `dh-platform`; mã nguồn đặt ở `libs/dh-audit` (giả định theo cấu trúc `libs/common-java` hiện có, tên gói chốt ở D04-01, Q13-22). Có hai artifact: `dh-audit-spring` cho DU Spring (ghi hộp thư đi trong giao dịch JPA) và `dh-audit-runtime` cho `dh-runtime` Quarkus (ghi Kafka trực tiếp, đệm đĩa).

```text
vn.datahub.common.audit            # (giả định, Q13-22)
├── AuditRecorder                  # điểm vào duy nhất: record(AuditEntry), recordSensitiveRead(AuditEntry)
├── AuditEntry, AuditOutcome       # DTO nguồn, không có seq, hash
├── envelope/                      # AuditEnvelope (CloudEvents 1.0), AuditEnvelopeMapper, lược đồ audit-event.v1
├── redact/                        # Redactor (@Classified, mẫu số định danh, điện thoại, thẻ, thư), SensitiveGuard
├── hmac/                          # ObjectKeyHasher (OpenBao transit/hmac, theo lô)
├── outbox/                        # AuditOutboxWriter (JPA, cùng giao dịch), OutboxDrainMonitor
├── runtime/                       # (chỉ artifact runtime) KafkaAuditSender (acks=all), DiskSpool (≤ 1 GB), SpoolDrainer
└── metrics/                       # dh_audit_emitted_total, dh_audit_outbox_pending, dh_audit_spool_bytes
```

Kho cấu hình hạ tầng quan sát (ADR-009) có cấu trúc dưới đây; luật chuẩn và dashboard chuẩn là nguồn sự thật khai báo, `StandardRuleCatalog` và `DashboardSetSync` nạp từ chính các tệp này (cùng phiên bản với ảnh `dh-platform`).

```text
clusters/{site}/obs/
├── collector/                     # agent.yaml, gateway.yaml (memory_limiter, k8sattributes, redaction, attributes, tail_sampling, transform, filter)
├── mimir/, loki/, tempo/          # values và runtime-config; overrides theo tenant do ObsProvisioner sinh (§4.22)
├── alertmanager/                  # một cấu hình toàn cục, định tuyến theo nhãn tenant, severity, kind
├── grafana/                       # datasource cố định OrgID, bộ dashboard chuẩn (JSON)
└── rules/platform/                # luật chuẩn nền tảng (YAML) + runbook (Markdown năm mục), kiểm bằng promtool và CI
```

### 3.4. Giao diện công bố

Các giao diện dưới đây là toàn bộ bề mặt module khác được dùng. Không giao diện nào ném ngoại lệ nghiệp vụ: lỗi từng phần nằm trong kết quả để bên gọi hiển thị phần còn lại (ví dụ FR-13-029, 057 khi một kho không khả dụng).

```java
package vn.datahub.platform.audit.api;

public interface AuditHistoryApi {
  /** FR-13-022. DU gọi sau khi tự kiểm tra quyền read của đối tượng. Chỉ trả giá trị đã che. */
  HistoryPage history(TenantId tenant, String objectType, String objectId, HistoryQuery query);
}

public interface AuditChainAdminApi {
  /** FR-13-059. Lũy đẳng theo idempotencyKey; khác tham số thì ERR-13-042. */
  ChainProvisionResult provision(TenantId tenant, ProvisionParams params, String idempotencyKey);
  /** FR-13-060 (Đợt sau). Đóng chuỗi, từ chối bản ghi mới bằng ERR-13-043. */
  ChainCloseResult close(TenantId tenant, CloseReason reason, String idempotencyKey);
}

public interface AuditDetectionQueryApi {
  /** FR-13-052. Truy vấn tổng hợp có tên, chỉ đọc, chỉ phân vùng nóng; không nhận SQL tự do. */
  List<AggregateRow> run(TenantId tenant, DetectionQueryName name, TimeWindow window, Map<String, Object> params);
}

public record ChainBrokenEvent(TenantId tenant, long firstBreakSeq, BreakKind kind, UUID verificationId) {}
public record ReconciliationMismatchEvent(TenantId tenant, String duCode, LocalDate day, long emitted, long received) {}

package vn.datahub.platform.observability.api;

public interface ComponentHealthApi {          // FR-13-058, đệm 15 giây
  List<ComponentHealth> components(TenantId tenant);
}
public interface DiagnosticsApi {              // FR-13-057, scope obs:diagnostics-read
  DiagnosticBundle forTrace(TenantId tenant, String traceId, Duration contextWindow);
}
public interface MetricsSummaryApi {           // FR-13-056, scope obs:metrics-read
  MetricsSummary summary(TenantId tenant, String period, Instant asOf);
  MetricsResult query(TenantId tenant, MetricsQuery query);
}
public interface TenantObservabilityApi {      // FR-13-059, 060, 061, scope obs:tenant-provision
  ProvisionReport provision(TenantId tenant, ObsProvisionParams params, String idempotencyKey);
  CloseReport closeAudit(TenantId tenant, CloseReason reason, String idempotencyKey);
}
```

### 3.5. DTO chính

Các bản ghi dưới đây là hợp đồng dữ liệu giữa lớp `web`, dịch vụ và thư viện `dh-audit`; ràng buộc kiểm bằng Bean Validation ở máy chủ, không tin giao diện.

```java
package vn.datahub.common.audit;

/** Bản ghi nguồn do DU tạo. Giá trị chỉ gồm chuỗi, số nguyên trong ±2^53, boolean, null, mảng, đối tượng. */
public record AuditEntry(
    @Pattern(regexp = "^[A-Z][A-Z0-9_]*(\\.[A-Z][A-Z0-9_]*)+$") String action,
    @NotBlank String objectType, @NotBlank String objectId,
    String objectKeyHmac,                       // do ObjectKeyHasher điền, không nhận số định danh
    Map<String, Object> before, Map<String, Object> after,   // đã che theo SEC-32
    @NotNull AuditOutcome outcome, String errorCode,
    @Size(min = 10, max = 500) String reason, String purpose) {}

package vn.datahub.platform.audit.internal.search;

public record AuditSearchRequest(
    @NotNull Instant from, @NotNull Instant to,
    String actorId, String action, String objectType, String objectId, AuditOutcome outcome,
    String traceId, String sourceDu, String sessionId,
    @Size(min = 10, max = 500) String reason,   // bắt buộc (BR-13-007), kiểm ở ReasonValidator
    @Min(1) @Max(200) int size, String cursor) {}

public record ObjectKeySearchRequest(
    @NotNull IdType idType, @NotBlank String identifier,   // không bao giờ log, không lưu, xóa tham chiếu sau khi băm
    @NotNull Instant from, @NotNull Instant to,
    @Size(min = 10, max = 500) String reason, @NotBlank String basis) {}

public record EvidenceExportRequest(
    @NotNull Instant from, @NotNull Instant to, AuditSearchFilter filter,
    @Size(min = 10, max = 500) String reason, @NotBlank String basis) {}

package vn.datahub.platform.observability.internal.alert;

public record AlertRuleRequest(
    @Pattern(regexp = "^[a-z][a-z0-9-]{2,62}$") String ruleCode, @NotBlank String name,
    @NotBlank String expr, @Min(0) @Max(3600) int forSeconds,
    @NotNull Severity severity, @NotBlank String symptom,      // bắt buộc với CRITICAL (BR-13-009)
    @NotBlank String runbookCode, List<String> receivers) {}
public record RunbookRequest(@NotBlank String meaning, @NotBlank String firstChecks, @NotBlank String commonCauses,
    @NotBlank String remediation, @NotBlank String escalationWhen) {}   // đủ năm mục (BR-13-008)
```

`AuditEntry` ghi đè `toString` chỉ in `action`, `objectType`, `objectId`; `before` và `after` được đánh dấu `@Sensitive` để bộ lọc log thay bằng `***` nếu bị log nhầm. Quy ước "chỉ chuỗi, số nguyên trong ±2^53, boolean, null" bảo đảm JCS cho cùng một kết quả ở Java, ở SQL (jsonb) và ở script xác minh ngoại tuyến (§4.4).

### 3.6. Quy tắc phụ thuộc và kiểm ở CI

Ranh giới module và các quy tắc bảo vệ tính bất biến của nhật ký được kiểm tự động ở CI, để vi phạm bị chặn trước khi gộp mã.

| Mã | Luật ArchUnit hoặc Semgrep | Bảo vệ |
|---|---|---|
| R1 | `observability.internal..` không import `audit.internal..` và ngược lại; chỉ `*.api..` | Ranh giới module (CI-3) |
| R2 | Chỉ `audit.internal.chain.ChainWriter` được `INSERT` vào `audit_event`; không lớp nào có `UPDATE`, `DELETE` trên `ph13_audit.audit_event`, `audit_anchor` (Semgrep cấm chuỗi SQL) | BR-13-002, BR-13-019 |
| R3 | Mọi `@RestController` ở `web` có `@PreAuthorize` theo `PERM-13-*` hoặc scope máy | Quyền kiểm ở máy chủ |
| R4 | `MimirClient`, `LokiClient`, `TempoClient`, `ClickHouseClient` chỉ được tạo và gọi trong `observability.internal.query` qua `TenantScope` | NFR-13-022 |
| R5 | Không log trực tiếp `AuditEntry`, `AuditEnvelope`, `ObjectKeySearchRequest.identifier`, thân yêu cầu tra cứu | BR-13-005, BR-13-011 |
| R6 | Lớp trong `audit.internal.chain` và `anchor` nhận `Clock` tiêm vào, cấm `Instant.now()` | Kiểm thử giờ xác định |
| R7 | Mọi `@Scheduled` và lô nền đi qua `JobRunner` (bọc `TenantContext.runAs` và `JobLock`) | D03-10 §5, tránh chạy hai nơi |
| R8 | Phương thức đánh dấu `@AuditedRead` phải gọi `SensitiveReadGuard.begin` trước khi đọc dữ liệu | BR-13-006 |

: Luật kiểm kiến trúc của PH-13

## 4. Thiết kế chi tiết từng thành phần

Chương này mở bằng mô hình miền (§4.1), sau đó mô tả 21 thành phần, mỗi thành phần có bảng đặc tả 10 mục rồi tới chi tiết thiết kế. Mục 4.2 đến 4.10 thuộc đường kiểm toán, 4.11 đến 4.22 thuộc đường quan sát, cảnh báo và vòng đời tenant. Bảng dưới cho biết mỗi FR được hiện thực ở thành phần nào, để kiểm thử viên và kỹ sư tra theo hai chiều.

| FR | Thành phần | FR | Thành phần |
|---|---|---|---|
| FR-13-001…007 | §4.11 | FR-13-031…041 | §4.15 |
| FR-13-008 | §4.12 | FR-13-042, 043 | §4.16 |
| FR-13-009 | §4.13 | FR-13-044, 045, 047, 050 | §4.17 |
| FR-13-010 | §4.2, §4.3 | FR-13-046, 048 | §4.18 |
| FR-13-011 | §4.4 | FR-13-049 | §4.19 |
| FR-13-012 | §4.5 | FR-13-051…053, 055 | §4.20 |
| FR-13-013 | §4.6 | FR-13-054 | §4.21 |
| FR-13-014, 015 | §4.7 | FR-13-056 | §4.13 |
| FR-13-016 | §4.2, §4.3 | FR-13-057 | §4.14 |
| FR-13-017, 018 | §4.8 | FR-13-058 | §4.15 |
| FR-13-019…023, 025 | §4.9 | FR-13-059, 060, 061 | §4.22 |
| FR-13-024 | §4.10 | FR-13-026…030 | §4.14 |

: Bảng tra FR sang thành phần thiết kế

### 4.1. Mô hình miền

Mô hình chia hai miền độc lập, đúng với hai đường dữ liệu. Miền kiểm toán có sáu aggregate xoay quanh chuỗi của một tenant; miền quan sát có bốn aggregate về cảnh báo, luật, an ninh và đích SIEM.

```{.mermaid caption="Mô hình miền kiểm toán của PH-13"}
classDiagram
  class AuditChain {
    +String tenantId
    +String genesisHash
    +long headSeq
    +String headHash
    +ChainStatus status
    +Integrity integrity
    +append(batch) 
    +markSuspect(breakInfo)
    +clearSuspect(verificationId, alertId)
    +close(reason)
  }
  class AuditEvent {
    +UUID id
    +long seq
    +Instant occurredAt
    +Instant recordedAt
    +String action
    +String objectType
    +String objectId
    +String prevHash
    +String hash
  }
  class AuditAnchor {
    +long seqLast
    +String hashLast
    +Instant anchoredAt
    +int keyVersion
    +AnchorKind kind
    +String signature
  }
  class WormBatch {
    +long seqFrom
    +long seqTo
    +String objectKey
    +String sha256
    +Instant retainUntil
    +Instant verifiedAt
  }
  class Verification {
    +Scope scope
    +VerificationStatus status
    +long firstBreakSeq
    +long checkedCount
    +WormCheck wormCheck
  }
  class ExportRequest {
    +String scopeHash
    +ExportStatus status
    +long recordCount
    +String fileHash
    +Instant expiresAt
  }
  class AuditPartition {
    +YearMonth month
    +PartitionStatus status
    +Instant wormVerifiedAt
  }
  AuditChain "1" *-- "*" AuditEvent
  AuditChain "1" *-- "*" AuditAnchor
  AuditChain "1" *-- "*" WormBatch
  AuditChain "1" o-- "*" Verification
  AuditChain "1" o-- "*" ExportRequest
  AuditChain "1" o-- "*" AuditPartition
  AuditAnchor "1" ..> "0..1" WormBatch : công bố
```

`AuditChain` là aggregate gốc duy nhất được ghi: mọi bản ghi mới đi qua `append`, và chỉ `append` làm đổi `headSeq`, `headHash`. `AuditEvent` và `AuditAnchor` bất biến sau khi ghi. Trạng thái toàn vẹn `integrity` tách khỏi `status` (OPEN, CLOSED) vì chuỗi `CLOSED` vẫn có thể nghi vấn và chuỗi `OPEN` có thể đang nghi vấn mà vẫn nhận bản ghi (FR-13-015 bước 6).

```{.mermaid caption="Mô hình miền cảnh báo, luật, an ninh của PH-13"}
classDiagram
  class AlertRule {
    +String ruleCode
    +String expr
    +int forSeconds
    +Severity severity
    +Scope scope
    +RuleStatus status
    +String runbookCode
    +publish()
    +disable(reason)
    +retire(reason)
  }
  class Runbook {
    +String runbookCode
    +String meaning
    +String firstChecks
    +String commonCauses
    +String remediation
    +String escalationWhen
  }
  class Alert {
    +UUID id
    +AlertStatus status
    +Severity severity
    +String groupKey
    +int escalationLevel
    +Instant silenceUntil
    +Resolution resolution
    +acknowledge(by)
    +silence(by, until, reason)
    +resolve(by, cause, measure, outcome)
    +escalate()
  }
  class AlertAction {
    +ActionKind action
    +String actor
    +Instant at
    +Outcome outcome
  }
  class DetectionRule {
    +String ruleCode
    +JsonNode threshold
    +JsonNode thresholdLimit
    +boolean canDisable
    +tune(threshold, by)
  }
  class SecurityAlert {
    +SecurityStatus status
    +Verdict verdict
    +String assignee
    +acknowledge(by)
    +close(verdict, note, by)
  }
  class SiemTarget {
    +Protocol protocol
    +Schema schema
    +Purpose purpose
    +boolean enabled
  }
  AlertRule "1" --> "1" Runbook
  AlertRule "1" o-- "*" Alert
  Alert "1" *-- "*" AlertAction
  DetectionRule "1" o-- "*" SecurityAlert
```

Hai aggregate có nhiều hành vi nhất là `Alert` (máy trạng thái, tạm ẩn, leo thang) và `SecurityAlert` (đóng cần kết luận). `AlertRule` luôn đi với một `Runbook` đủ năm mục ngay khi tạo nên không có trạng thái nháp. Invariant được kiểm trong aggregate trước khi ghi:

| Aggregate | Invariant | BR, ERR |
|---|---|---|
| `AuditChain` | `seq` liên tục không khoảng trống; `headSeq`, `headHash` bằng bản ghi cuối; `CLOSED` không nhận bản ghi; `SUSPECT` chỉ về `OK` khi có kết luận của cán bộ ATTT và một lượt kiểm tra mới đạt trên đoạn sau điểm đứt | BR-13-002, 012, 033; ERR-13-043 |
| `AuditEvent` | Bất biến; `hash = SHA-256(prev_hash ‖ JCS(bản ghi không gồm hash))`; `tenant_id` khớp topic; không giá trị Nhạy cảm chưa che | BR-13-017, 035; ERR-13-101…105 |
| `AuditAnchor` | Chỉ-thêm; `seqLast` không giảm theo thời gian; chữ ký hợp lệ với `keyVersion` | BR-13-013 |
| `WormBatch` | Dải `seq` liền kề không chồng; băm khớp bản ghi ở bảng; `retainUntil` không rút ngắn | BR-13-013, 020; ERR-13-108 |
| `ExportRequest` | Không hai yêu cầu cùng `scopeHash` đang chạy; `READY` chỉ khi đã ký; không để lại tệp chưa ký | BR-13-014, 029; ERR-13-025, 026 |
| `Verification` | Mỗi tenant một lượt `RUNNING` | ERR-13-032 |
| `AlertRule` | Có runbook đủ năm mục; luật `PLATFORM` tenant không sửa, không tắt; mã không dùng lại; không quá `13.alert.max-rules` luật; luật chỉ dựa tài nguyên thuần tối đa `WARNING` | BR-13-008, 009, 031, 032; ERR-13-002, 017, 019 |
| `Alert` | Chuyển trạng thái theo §8.1; `SILENCED` có `silenceUntil` ≤ 7 ngày (Nghiêm trọng ≤ 24 giờ) và lý do; đóng thủ công có nguyên nhân, hành động, kết quả | BR-13-021, 023; ERR-13-020…022 |
| `DetectionRule` | Ngưỡng nới không quá 2 lần mặc định; luật `canDisable = false` không tắt | BR-13-025; ERR-13-024 |
| `SecurityAlert` | Đóng cần một trong ba kết luận | BR-13-024; ERR-13-023 |
| `SiemTarget` | `purpose = AUTHORITY` tắt mặc định; dữ liệu đẩy đi đã loại dữ liệu cá nhân | BR-13-034; ERR-13-039 |

: Invariant của các aggregate

### 4.2. Thư viện `dh-audit` phía DU

::: dac-ta
**Mục đích.** Đưa việc sinh bản ghi kiểm toán vào một thư viện duy nhất để 100% DU ghi cùng định dạng, cùng giao dịch với thao tác nghiệp vụ, đã che giá trị Nhạy cảm, có chữ ký nguồn và có bộ đếm phục vụ đối chiếu.

**Lớp chính.** `AuditRecorder`, `Redactor`, `ObjectKeyHasher`, `AuditEnvelopeMapper`, `AuditOutboxWriter`, `OutboxRelay`, `OutboxDrainMonitor`; phía runtime: `KafkaAuditSender`, `DiskSpool`, `SpoolDrainer`.

**Đơn vị chạy.** Nhúng ở mọi DU Spring và `dh-runtime` (Camel Quarkus).

**FR hiện thực.** FR-13-010 (phía nguồn), FR-13-016, FR-13-017 (bộ đếm), FR-13-019 (cho chính `dh-platform`).

**Giao diện vào.** `AuditRecorder.record(AuditEntry)`, `recordSensitiveRead(AuditEntry)`; chú thích `@Audited` cho phương thức dịch vụ ghi; Kamelet `dh-audit-sink` của PH-04 gọi `KafkaAuditSender`.

**Phụ thuộc ra.** CSDL của DU (bảng `audit_outbox`, `audit_emit_counter`), Kafka (`acks=all`), OpenBao (`transit/hmac`, đọc khóa ký nguồn), OTel (lấy `trace_id`).

**Dữ liệu.** Bảng `audit_outbox` và `audit_emit_counter` trong schema của DU; thư mục đệm `/var/lib/dh-audit/spool` (chỉ runtime).

**Sự kiện.** Phát vào topic `{tenant}.obs.audit.recorded.v1`; không có mã EVT-13 vì là kênh vào của PH-13.

**Lỗi và xử lý.** Kafka hoặc PH-13 ngừng: bản ghi nằm ở hộp thư đi, gửi lại giãn dần, người dùng không bị chặn; không ghi được vết cho thao tác Nhạy cảm (hộp thư đi hoặc đĩa đệm đầy, OpenBao không băm được khóa): ném `AuditUnavailableException`, DU trả lỗi riêng của DU (BR-13-003); hộp thư đi quá 1 triệu bản ghi: cảnh báo cho nhóm DU đó.

**Quan sát.** `dh_audit_emitted_total`, `dh_audit_emitted_day`, `dh_audit_outbox_pending`, `dh_audit_spool_bytes`, `dh_audit_redacted_total`.
:::

Chi tiết thiết kế:

`record` bắt buộc chạy trong giao dịch đang mở (`Propagation.MANDATORY`) để bản ghi và thao tác nghiệp vụ cùng cam kết hoặc cùng hủy. Thư viện làm sáu việc theo thứ tự: (1) lấy `tenant_id` từ `TenantContext`, không nhận làm tham số; (2) điền ngữ cảnh: `actor` từ `SecurityContext` (`USER`, `CLIENT` hoặc `SYSTEM` kèm `system:{du}`), `source_ip` và `user_agent` từ tiêu đề đã xác thực qua mesh, `session_hash = SHA-256(mã phiên)`, `trace_id` từ span hiện tại, `id` UUID v7; (3) che `before`, `after`, `reason` bằng `Redactor` (chú thích `@Classified` và mẫu số định danh 12 số, điện thoại, thẻ, thư điện tử, SEC-32); (4) với khóa nghiệp vụ nhạy cảm, `ObjectKeyHasher` gọi OpenBao `transit/hmac/dh-{tenant}-audit-hmac` (gộp theo lô khi một giao dịch có nhiều khóa) để chỉ `object_key_hmac` được lưu, số định danh gốc không rời khỏi bộ nhớ của lời gọi; (5) ghi một hàng `audit_outbox` cùng giao dịch; (6) tăng bộ đếm.

**Bộ đếm phải chính xác để đối chiếu.** Tăng `Counter` trong bộ nhớ sau khi cam kết có thể sai khi tiến trình chết giữa hai việc, nên bộ đếm là một bảng `audit_emit_counter(day, tenant_id, slot, n)` được cập nhật trong cùng giao dịch (16 mảnh theo băm `id` để tránh khóa nóng). Bộ xuất chỉ số đọc bảng mỗi 15 giây và công bố hai chỉ số: `dh_audit_emitted_total{du,tenant}` (counter, tổng tích lũy) và `dh_audit_emitted_day{du,tenant,day}` (gauge, chỉ cho hôm nay, hôm qua, hôm kia nên chuỗi hoạt động bị chặn ở 3 ngày × tenant × DU). Ngày tính theo múi giờ `Asia/Ho_Chi_Minh` ở cả hai phía đối chiếu (§4.8).

**Hộp thư đi có xác nhận, không dùng chế độ xóa ngay.** Bản ghi kiểm toán dùng `OutboxRelay` của thư viện thay cho Debezium Event Router mà sự kiện miền của DU đang dùng (ADR-042): relay lấy lô 500 hàng bằng `FOR UPDATE SKIP LOCKED` mỗi 500 ms, gửi `acks=all` kèm `enable.idempotence=true`, chờ xác nhận, rồi mới đặt `published_at`; hàng đã xuất bản xóa sau 1 giờ. Lý do: BR-13-004 yêu cầu bản ghi chỉ rời hộp thư đi sau khi Kafka xác nhận, trong khi Debezium Outbox Router chèn rồi xóa hàng ngay và dùng WAL làm vùng đệm, nên không đếm được tồn đọng. `dh_audit_outbox_pending` là số hàng chưa có `published_at`. DU đã dùng Debezium cho sự kiện miền vẫn dùng Debezium cho sự kiện đó; hai cơ chế cùng tồn tại trong một DU. Hồ sơ cần dùng Debezium cho kiểm toán phải đo tồn đọng bằng độ trễ replication slot và vượt bộ kiểm thử NFR-13-011.

**Chữ ký nguồn.** Kafka không cho người tiêu thụ biết ai là người sản xuất bản ghi, nên danh tính DU không đọc được từ chứng thư KafkaUser như FR-13-010 bước 2 mô tả. Thiết kế dùng hai lớp: ACL Kafka chỉ cho KafkaUser của DU hợp lệ ghi vào topic của tenant (ADR-072), và mỗi bản ghi mang tiêu đề `dh-du`, `dh-kid`, `dh-mac` với `dh-mac = HMAC-SHA256(khóa nguồn của DU, tenant ‖ id ‖ SHA-256(payload))`. Khóa nguồn của mỗi DU nằm ở OpenBao `kv/dh/PLATFORM/audit-mac/{du}` (DU chỉ đọc khóa của chính nó, đọc lúc khởi động và làm mới mỗi giờ, giữ trong bộ nhớ); PH-13 đọc mọi khóa này để kiểm. DU bị chiếm quyền chỉ giả được danh nghĩa của chính nó. Quy tắc này thêm tiêu đề vào lược đồ `audit-event.v1` và được ghi vào đề nghị đồng bộ cho D03-04-PH13.

**Runtime (Q13-03 đã chốt).** `dh-runtime` không có CSDL riêng nên `KafkaAuditSender` gửi trực tiếp `acks=all`. Không với tới Kafka: thao tác truy cập dữ liệu Nhạy cảm (PH-14 tra cứu, `PII.REVEAL`) bị từ chối vì không bảo đảm ghi vết (BR-13-003); thao tác thường ghi vào `DiskSpool` (tệp nối thêm, CRC mỗi bản ghi, `fsync` mỗi 100 ms, đoạn 16 MB, tối đa 1 GB) rồi `SpoolDrainer` gửi lại theo thứ tự. Đĩa đệm là `emptyDir`, nên bản ghi trong đĩa đệm mất nếu pod bị xóa trong lúc Kafka không với tới. Rủi ro này được chấp nhận ở MVP vì hiếm và bị đối chiếu số lượng phát hiện (bộ đếm tăng sau khi ghi đệm); Q13-21 chờ PH-14 xác nhận.

### 4.3. Bộ tiếp nhận kiểm toán

::: dac-ta
**Mục đích.** Nhận mọi bản ghi kiểm toán từ DU, kiểm tra nguồn, tenant, trường bắt buộc, trùng và giá trị Nhạy cảm chưa che, rồi chuyển bản đạt sang ghi chuỗi; bản không đạt được giữ nguyên ở kho cách ly, không bao giờ bỏ.

**Lớp chính.** `AuditIngestListener`, `BatchIngestService`, `SourceAuthorizer`, `RecordValidator`, `SensitiveScanner`, `QuarantineWriter`.

**Đơn vị chạy.** `dh-platform`, vai trò `ingest` (và `api` cho kênh dự phòng).

**FR hiện thực.** FR-13-010, FR-13-016.

**Giao diện vào.** Kafka `{tenant}.obs.audit.recorded.v1` (group `dh-platform-audit-ingest`); API-13-089 `POST /internal/records:batch`.

**Phụ thuộc ra.** `ChainWriter` (§4.4), OpenBao (đọc khóa nguồn), bảng `audit_source_grant`, `audit_quarantine`.

**Dữ liệu.** `audit_quarantine` (bản gốc, lý do, DU), `audit_source_grant(du_code, tenant_id)`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-13-101, 102, 103, 104, 105 cách ly hoặc bỏ qua theo bảng dưới; ERR-13-043 khi chuỗi đóng; cơ sở dữ liệu lỗi: không xác nhận offset, thử lại giãn dần; không có DLT.

**Quan sát.** `dh_audit_ingest_total{result}`, `dh_audit_ingest_duration_seconds`, `dh_audit_consumer_lag`.
:::

Chi tiết thiết kế:

Listener đăng ký theo mẫu tên topic `^[a-z0-9]+\.obs\.audit\.recorded\.v1$` và `platform.obs.audit.recorded.v1`, `AckMode.MANUAL`, `max.poll.records = 500`, `enable.auto.commit = false`, `concurrency = 3` mỗi bản sao. Tenant của lô lấy **từ tên topic** (tiền tố chữ thường ánh xạ về mã `T68`, `PLATFORM` qua `TenantCode.fromTopicPrefix`), không từ nội dung. Offset chỉ xác nhận sau khi `ChainWriter` cam kết (BR-13-004); gặp lại bản đã nhận khi tái cân bằng hay khi DU gửi lại thì bước khử trùng bỏ qua và vẫn coi là đã nhận. Mỗi lô chạy trong `TenantContext.runAs(tenant)`.

Thứ tự kiểm tra mỗi bản ghi, dừng ở lỗi đầu tiên và ghi nguyên văn vào `audit_quarantine` (không phân tích được JSON thì lưu dạng bytes thô kèm `reason = UNPARSABLE`, vì kênh kiểm toán không có hàng đợi thư chết):

| Bước | Kiểm tra | Không đạt | Hành xử |
|---|---|---|---|
| 1 | `dh-mac` hợp lệ với khóa DU `dh-kid`, và cặp (DU, tenant) có trong `audit_source_grant` | ERR-13-103 | Cách ly; cảnh báo an ninh UC-SEC-09 |
| 2 | Lược đồ `audit-event.v1` đúng, đủ trường bắt buộc của §4.7 FRS, chuỗi không quá cỡ (`before`, `after` ≤ 64 KB) | ERR-13-101 | Cách ly; cảnh báo `WARNING` cho DU nguồn |
| 3 | `tenant_id` của bản ghi khớp tiền tố topic | ERR-13-104 | Cách ly; UC-SEC-09 |
| 4 | `id` chưa có trong chuỗi (xem dưới) | ERR-13-102 | Bỏ qua, coi như đã nhận, đếm `result=duplicate` |
| 5 | `SensitiveScanner`: mẫu độc lập với `Redactor` (số định danh 12 chữ số trong chuỗi, điện thoại, thư điện tử, số thẻ qua Luhn, khóa tên `password`, `secret`, `token`, `idNumber` có giá trị khác `***`) trên `before`, `after`, `reason` | ERR-13-105 | Cách ly; cảnh báo `CRITICAL` cho nhóm DU (BR-13-035) |
| 6 | Chuỗi tenant ở `OPEN` | ERR-13-043 | Cách ly kèm lý do `CHAIN_CLOSED` |

: Thứ tự kiểm tra ở bộ tiếp nhận

**Khử trùng theo `id`.** Bảng chia phân vùng theo `recorded_at` nên không ràng buộc duy nhất theo `id` được. `id` là UUID v7 chứa thời điểm sinh, và bản trùng chỉ có thể ghi sau thời điểm đó, nên truy vấn `SELECT id FROM audit_event WHERE tenant_id = ? AND id = ANY(?) AND recorded_at >= ?` với cận dưới là thời điểm nhỏ nhất trong lô trừ 1 ngày chỉ chạm một đến hai phân vùng nhờ cắt phân vùng, dùng chỉ mục `(tenant_id, id)` của từng phân vùng. Trong lô, bản trùng nội bộ được loại trước bằng tập băm.

**Quét Nhạy cảm tránh báo nhầm.** Chuỗi 12 chữ số là mẫu số định danh nên số hiệu hồ sơ dài 12 chữ số sẽ bị cách ly nhầm. Bộ quét chỉ xét giá trị kiểu chuỗi trong `before`, `after`, `reason`, bỏ qua `object_id` và số nguyên JSON, và có danh sách ngoại lệ theo `(DU, action)` trong cấu hình nền tảng. Bản ghi bị cách ly nhầm được DU sửa rồi gửi lại cùng `id`, vì khử trùng chỉ xét bảng chuỗi, không xét kho cách ly. Màn UI-13-18 hiện số bản cách ly theo DU và lý do.

**Kênh dự phòng.** `BatchIngestService` dùng chung bộ kiểm tra và `ChainWriter`; điểm khác là danh tính DU lấy từ token máy (scope `audit:write`) thay cho `dh-mac`, và phản hồi `202` có `accepted`, `duplicate`, `quarantined` sau khi lô đã cam kết (không hứa hẹn bất đồng bộ).

### 4.4. Ghi chuỗi băm theo tenant

::: dac-ta
**Mục đích.** Ghi bản ghi vào bảng chỉ-thêm và nối vào chuỗi băm riêng của tenant, để mọi sửa đổi về sau, kể cả của quản trị cơ sở dữ liệu, bị phát hiện.

**Lớp chính.** `ChainWriter`, `TenantChainLock`, `CanonicalJson`, `HashCalculator`, `ChainStatusService`.

**Đơn vị chạy.** `dh-platform`, vai trò `ingest` và `api`.

**FR hiện thực.** FR-13-011.

**Giao diện vào.** `ChainWriter.append(TenantId, List<ValidatedRecord>)` do §4.3 gọi; API-13-087 `GET /chain-status` (đọc).

**Phụ thuộc ra.** `pg-core` (`ph13_audit.audit_event`, `audit_chain`).

**Dữ liệu.** `audit_event` (phân vùng tháng, chỉ-thêm), `audit_chain` (đầu chuỗi).

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-13-106 khi không ghi được: hủy giao dịch, thử lại 1 giây tăng dần tới 1 phút; quá 5 phút cảnh báo `CRITICAL`; chờ khóa quá 5 giây: trả lô về hàng đợi; đồng hồ lệch quá 2 giây: vẫn ghi, cờ `clock_skew` (ERR-13-126).

**Quan sát.** `dh_audit_chain_head_seq{tenant}`, `dh_audit_chain_write_seconds`, `dh_audit_chain_lag_seconds{tenant}`, `dh_audit_chain_lock_wait_seconds`.
:::

Chi tiết thiết kế:

```java
@Transactional(isolation = READ_COMMITTED)
public AppendResult append(TenantId tenant, List<ValidatedRecord> batch) {
  jdbc.query("SELECT set_config('app.tenant_id', ?, true)", tenant.code());   // tương đương SET LOCAL, RLS (SEC-81)
  jdbc.execute("SET LOCAL lock_timeout = '5s'");
  lock.acquire(tenant);                                               // pg_advisory_xact_lock(hash64('audit:' + tenant))
  ChainHead head = chainRepo.read(tenant);                            // head_seq, head_hash, status
  if (head.status() == CLOSED) throw new ChainClosedException(tenant);   // ERR-13-043
  Instant floor = head.lastRecordedAt();
  List<AuditRow> rows = new ArrayList<>(batch.size());
  String prev = head.hash();  long seq = head.seq();
  for (ValidatedRecord r : batch) {
    Instant recordedAt = max(clock.instant(), floor);                 // không lùi (NTP), giữ phân vùng đơn điệu
    AuditRow row = r.toRow(++seq, recordedAt, prev, clockSkew(r.occurredAt(), recordedAt));
    row = row.withHash(hasher.hash(prev, canonical.of(row)));         // SHA-256(prev ‖ JCS)
    rows.add(row);  prev = row.hash();  floor = recordedAt;
  }
  eventRepo.insertBatch(rows);                                        // INSERT, reWriteBatchedInserts
  int n = chainRepo.advance(tenant, head.seq(), seq, prev, floor);    // UPDATE ... WHERE head_seq = :expected (CAS)
  if (n != 1) throw new ConcurrentChainWriteException(tenant);        // không xảy ra khi giữ khóa, giữ làm lớp thứ hai
  return new AppendResult(rows.size(), seq, prev);
}
```

Hai lớp chống ghi đồng thời: khóa tư vấn mức giao dịch (người đến sau chờ tối đa 5 giây rồi trả lô về hàng đợi) và cập nhật có điều kiện `head_seq = :expected`. Khóa được lấy trước khi đọc đầu chuỗi. Vì khóa tư vấn là của PostgreSQL nên API dự phòng và bộ tiếp nhận Kafka cùng một tenant vẫn tuần tự dù chạy ở hai pod.

**Định nghĩa băm (cố định, có phiên bản).** `hash = hex(SHA-256(UTF8(prev_hash) ‖ UTF8(JCS(R))))` với `R` là đối tượng gồm mọi cột của bản ghi trừ `hash`, kèm `v = 1` (phiên bản thuật toán). Quy tắc dựng `R` để tính lại được ở mọi nơi:

| Quy tắc | Lý do |
|---|---|
| Trường vắng hoặc `null` bị bỏ khỏi `R` | Thêm trường tùy chọn ở phiên bản sau không đổi băm bản ghi cũ |
| Thời điểm là chuỗi RFC 3339 UTC cố định 6 chữ số thập phân, ví dụ `2026-11-26T03:04:05.123456Z` | PostgreSQL `timestamptz` có độ phân giải micro giây; không lệch khi đọc lại |
| `before`, `after` chỉ gồm chuỗi, số nguyên trong ±2^53, boolean, null, mảng, đối tượng; số thập phân dạng chuỗi | `jsonb` chuẩn hóa số và thứ tự khóa; JCS của giá trị đã phân tích không đổi qua `jsonb`; script Python xác minh ngoại tuyến dùng `json` chuẩn của ngôn ngữ cũng cho cùng kết quả |
| `prev_hash` là chuỗi 64 ký tự thập lục phân thường | Độ dài cố định nên ghép không nhập nhằng |
| `seq`, `recorded_at`, `source_du` do PH-13 gán, `prev_hash` của bản đầu là `genesis_hash` | BR-13-017 |

: Quy tắc dựng bản ghi chuẩn tắc để tính băm

Kiểm thử thuộc tính (jqwik) bắt buộc: với mọi bản ghi sinh ngẫu nhiên, `JCS(đọc từ jsonb(JCS(x))) = JCS(x)`; và một bộ vector cố định (20 bản ghi, giá trị băm đã chốt) chạy ở Java, SQL và script xác minh để chặn sai lệch thư viện.

**Chặn sửa xóa ở CSDL.** `audit_event` thuộc vai trò chủ `ph13_owner` (không đăng nhập được, chỉ dùng cho di trú Flyway trong đường ống triển khai có `pgaudit` ghi DDL). Trigger `BEFORE UPDATE OR DELETE` (mức hàng) và `BEFORE TRUNCATE` (mức câu lệnh) ném lỗi cho mọi vai trò trừ `ph13_archive` khi tách phân vùng. `ph13_app` chỉ có `INSERT`, `SELECT` trên `audit_event` và `audit_anchor`, và `UPDATE` giới hạn theo cột (`head_seq`, `head_hash`, `last_recorded_at`, `status`, `integrity`) trên `audit_chain`. Thử `UPDATE`, `DELETE`, `TRUNCATE` hoặc `ALTER TABLE ... DISABLE TRIGGER` được `pgaudit` ghi lại và `TamperProbe` (§4.7) phát UC-SEC-20. Tài khoản CSDL là tài khoản động của OpenBao (TTL 1 giờ, SEC-33), không cấp cho người (BR-13-019). Ngoài `ChainWriter`, CSDL có hai lớp chốt bổ sung: trigger `tg_audit_chain_guard` (trước `UPDATE` ở `audit_chain`) bảo đảm đầu chuỗi chỉ tăng, đoạn mới liền kề và nối đúng, và constraint trigger hoãn `tg_audit_event_covered` bảo đảm bản ghi chỉ cam kết khi đầu chuỗi đã bao phủ `seq` của nó, nên không có bản ghi mồ côi.

### 4.5. Neo băm ký hằng giờ

::: dac-ta
**Mục đích.** Chốt đầu chuỗi của mỗi tenant thành một neo có chữ ký và lưu ở nhiều nơi độc lập, để kẻ muốn sửa nhật ký phải giả chữ ký, sửa cả bản WORM lẫn bản ở SIEM.

**Lớp chính.** `AnchorScheduler`, `AnchorService`, `TransitSigner`, `AnchorPublisher`.

**Đơn vị chạy.** `dh-platform`, vai trò `jobs`, một bản sao thực thi nhờ `JobLock`.

**FR hiện thực.** FR-13-012.

**Giao diện vào.** Lịch mỗi phút kiểm tra tenant đến hạn (`13.audit.anchor-interval-minutes`); API-13-080, 081 (đọc).

**Phụ thuộc ra.** OpenBao `transit/sign/dh-audit-sign`, `WormClient`, bộ xuất SIEM (§4.21), `pg-core`.

**Dữ liệu.** `audit_anchor` (chỉ-thêm), `audit_anchor_publish` (nơi công bố), `audit_signing_key` (khóa công khai theo phiên bản).

**Sự kiện.** EVT-13-06 qua outbox trong cùng giao dịch ghi neo.

**Lỗi và xử lý.** ERR-13-107 khi OpenBao không ký: thử lại mỗi phút; quá 3 giờ không có neo: `CRITICAL`; ERR-13-108 khi không ghi được WORM: neo vẫn có ở bảng, `worm_pending`; ERR-13-122 khi SIEM không nhận, không chặn neo.

**Quan sát.** `dh_audit_anchor_age_seconds{tenant}`, `dh_audit_anchor_total{result}`, `dh_audit_anchor_sign_seconds`.
:::

Chi tiết thiết kế:

`AnchorScheduler` chạy mỗi phút, chọn tenant có bản ghi mới từ neo trước và đã tới hạn, hoặc quá 24 giờ chưa có neo. Mỗi neo gồm bốn bước tuần tự: (1) đọc `head_seq`, `head_hash` từ `audit_chain` trong một câu lệnh (đã nhất quán vì cập nhật cùng giao dịch với bản ghi); (2) dựng tải `{"tenant","seqLast","hashLast","anchoredAt","keyVersion","v":1}` bằng JCS, tính `digest = SHA-256("datahub-audit-anchor-v1\n" ‖ tải)` (tiền tố tên miền để chữ ký neo không dùng lại được cho gói bằng chứng), gọi `transit/sign/dh-audit-sign/sha2-256` với `prehashed = true`, `marshaling_algorithm = asn1` để `openssl dgst -verify` kiểm được; (3) một giao dịch ghi `audit_anchor` và dòng outbox EVT-13-06; (4) công bố: ghi tệp `anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json` vào WORM có khóa tuân thủ, gửi SIEM nếu cấu hình, rồi ghi `worm_object`, `siem_ack_at` vào bảng phụ `audit_anchor_publish`. Tách bảng phụ giữ `audit_anchor` thuần chỉ-thêm; D03-03-PH13 ghi nhận tách này (EN-13-02 liệt kê hai cột ấy).

Sau khi ký, `AnchorService` kiểm tra gia tăng: tính lại băm đoạn từ neo trước tới neo này (khoảng 4.000 bản ghi mỗi giờ ở `QM-VUA`, dưới 2 giây). Lệch thì chuyển `BreakHandler` (§4.7). Đây là tầng 1 của hai tầng kiểm tra và là lý do sửa bản ghi vừa ghi bị phát hiện trong 1 giờ.

**Khóa ký.** Một khóa nền tảng `dh-audit-sign` (ECDSA P-256, không xuất, xoay 12 tháng, Q13-13). Mỗi lần xoay, `audit_signing_key` lưu khóa công khai của phiên bản mới và một tệp `keys/dh-audit-sign.json` được ghi vào WORM, để xác minh không phụ thuộc OpenBao còn sống. Neo mang `key_version`; bản ký phiên bản cũ vẫn kiểm được bằng khóa công khai cũ. **Neo ranh giới phân vùng:** khi chốt phân vùng tháng (§4.8), `AnchorService` ký thêm neo `kind = BOUNDARY` cho bản ghi cuối của tháng, để chuỗi trực tuyến luôn có điểm xuất phát có chữ ký sau khi phân vùng cũ được lưu trữ.

### 4.6. Sao lô sang kho WORM

::: dac-ta
**Mục đích.** Giữ một bản không sửa, không xóa được của mọi bản ghi ở hệ lưu trữ riêng, để bằng chứng còn kể cả khi cơ sở dữ liệu bị phá hay sửa.

**Lớp chính.** `WormBatchWriter`, `WormClient`, `WormReader`, `RetentionExtender`.

**Đơn vị chạy.** `dh-platform`, vai trò `jobs`.

**FR hiện thực.** FR-13-013; một phần FR-13-018.

**Giao diện vào.** Lịch mỗi `13.audit.worm-batch-minutes` (5 phút) cho tenant có bản ghi chưa sao; API-13-087 (đọc trạng thái).

**Phụ thuộc ra.** Ceph RGW (S3) bucket `dh-worm-audit`, `pg-core`.

**Dữ liệu.** `audit_worm_batch` (dải `seq`, khóa đối tượng, SHA-256, ETag, `verified_at`, `retain_until`); đối tượng `audit/{tenant}/{yyyy}/{MM}/{dd}/{seqĐầu}-{seqCuối}.jsonl.zst` và `.manifest.json`.

**Sự kiện.** Không (neo phát EVT-13-06); EVT-13-14 khi kho đạt 85%.

**Lỗi và xử lý.** ERR-13-108: giữ lô, thử lại giãn dần; trễ quá 30 phút `WARNING`, quá 4 giờ `CRITICAL`; ETag lệch: ghi lại dưới tên mới; ERR-13-123 khi kho đạt 85%.

**Quan sát.** `dh_audit_worm_lag_seconds{tenant}`, `dh_audit_worm_batches_total{result}`, `dh_audit_worm_bytes_total`.
:::

Chi tiết thiết kế:

Mỗi lần chạy, với từng tenant, `WormBatchWriter` lấy dải `seq` liền sau lô đã sao gần nhất tới `head_seq`, cắt thành lô tối đa 50.000 bản ghi (khoảng 75 MB thô, 10 đến 15 MB sau nén `zstd`), ghi tệp JSON Lines và tệp `manifest` gồm `count`, `seqFrom`, `seqTo`, `sha256`, `prev_batch_sha256` (băm lô trước, nên các lô trên WORM tự tạo thành một chuỗi thứ hai). Gọi `PutObject` một lần (dưới giới hạn đa phần) với `x-amz-object-lock-mode = COMPLIANCE`, `x-amz-object-lock-retain-until-date = hôm nay + 13.audit.worm-retention-years`, mã hóa phía máy chủ và tiêu đề `Content-MD5` để kho tự từ chối khi truyền hỏng; sau đó `HeadObject` đối chiếu `ETag` với băm đã tính (với `PutObject` đơn không mã hóa riêng phía kho, ETag là MD5; nếu cấu hình mã hóa của RGW làm ETag không còn là MD5 thì chuyển sang tiêu đề `x-amz-checksum-sha256`, ghi ở Q13-23) rồi mới ghi `verified_at`. Lô rỗng không tạo đối tượng.

Hai tài khoản S3 tách quyền, giữ ở OpenBao KV và xoay 90 ngày: `worm-writer` chỉ có `PutObject`, `GetObject`, `ListBucket` (không `DeleteObject`, không `PutObjectRetention`), và `worm-retention` chỉ có `PutObjectRetention` do `RetentionExtender` dùng khi tenant nâng thời hạn (Object Lock chỉ cho kéo dài). Việc xóa đối tượng hết hạn do quy tắc vòng đời của bucket theo tiền tố tenant (số ngày bằng thời hạn cộng 30 ngày) thực hiện; RGW từ chối xóa khi khóa còn hiệu lực nên quy tắc này an toàn khi tenant đã kéo dài thời hạn. `PartitionManager` (§4.8) phát hiện lô đã biến mất sau `retain_until` và ghi biên bản `AUDIT.WORM.EXPIRE` vào chuỗi `PLATFORM` (BR-13-002).

Q13-23 ghi nhận hệ quả số lượng đối tượng và yêu cầu với RGW: lô 5 phút cho mỗi tenant có hoạt động tạo tối đa 288 đối tượng mỗi ngày (khoảng 105.000 mỗi năm mỗi tenant, 3,6 triệu mỗi năm cho 34 tenant), và Object Lock cần bật versioning cho bucket. Nếu RGW không chịu được, tăng `13.audit.worm-batch-minutes` kèm chấp nhận RPO tương ứng.

### 4.7. Kiểm tra toàn vẹn và xử lý đứt chuỗi

::: dac-ta
**Mục đích.** Chứng minh định kỳ và theo yêu cầu rằng chuỗi của một tenant chưa bị sửa (băm, số thứ tự, chữ ký neo, bản WORM) và khi nghi vấn thì báo đúng người ở mức cao nhất, giữ chứng cứ, không tự sửa.

**Lớp chính.** `VerificationService`, `SegmentVerifier`, `WormComparator`, `TamperProbe`, `BreakHandler`, `EvidenceCollector`.

**Đơn vị chạy.** `dh-platform`, vai trò `jobs`; đọc từ bản sao đọc của `pg-core` bằng vai trò `ph13_verify`.

**FR hiện thực.** FR-13-014, FR-13-015.

**Giao diện vào.** Lịch `13.audit.verify-cron`; API-13-077 (yêu cầu), 078, 079 (đọc); sau mỗi neo (tầng gia tăng).

**Phụ thuộc ra.** Bản sao đọc `pg-core`, WORM, OpenBao (khóa công khai), bucket chứng cứ `dh-evidence`, `observability` qua `ChainBrokenEvent`.

**Dữ liệu.** `audit_verification`, `audit_chain.integrity`.

**Sự kiện.** EVT-13-07 (xong lượt), EVT-13-05 (đứt chuỗi).

**Lỗi và xử lý.** ERR-13-032 khi đang có lượt chạy; ERR-13-109, 110 khi đứt chuỗi hoặc neo lệch; WORM không đọc được: `wormCheck = UNAVAILABLE`, không báo đạt hoàn toàn; ERR-13-029 khi khoảng ngoài thời hạn trực tuyến mà không có WORM.

**Quan sát.** `dh_audit_verify_duration_seconds`, `dh_audit_verify_result_total{result}`, `dh_audit_verify_last_success_timestamp{tenant}`, `dh_audit_partition_tuple_changes`.
:::

Chi tiết thiết kế:

**Hai tầng và một lớp thăm dò.** Tầng gia tăng chạy sau mỗi neo (§4.5): phát hiện sửa đoạn mới trong 1 giờ. Tầng hằng ngày chạy theo `13.audit.verify-cron` (03:00). FR-13-014 bước 1 đặt điểm xuất phát là "neo đã xác minh gần nhất", cách đọc đó chỉ kiểm đoạn mới nên một bản ghi cũ bị sửa mà đoạn mới nguyên vẹn sẽ không bị thấy, trái với NFR-13-016 (mọi sửa bản ghi bị phát hiện ≤ 24 giờ). Thiết kế vì vậy cho lượt `DAILY` kiểm lại **toàn bộ chuỗi trực tuyến** của mỗi tenant, từ neo ranh giới phân vùng sớm nhất còn trực tuyến, chia theo đoạn neo và chạy song song; lượt `ON_DEMAND` cho phép chọn khoảng. Chi phí ở §11.1; việc chỉnh FR-13-014 bước 1 ghi vào đề nghị đồng bộ, Q13-20 chờ xác nhận định cỡ cho `QM-CHUNG`. Lớp thăm dò `TamperProbe` bổ sung phát hiện sớm: mỗi phút đọc `pg_stat_user_tables` của các phân vùng `audit_event` (`n_tup_upd`, `n_tup_del` phải bằng 0 so với mốc) và so `audit_chain.head_hash` với `hash` của dòng cuối; khác thì phát UC-SEC-20 ngay mà không chờ lượt kiểm tra.

**`SegmentVerifier`.** Một đoạn là dải bản ghi giữa hai neo liền kề. Thuật toán cho một đoạn `[a, b]` với neo đầu `A` và neo cuối `B` (đã kiểm chữ ký bằng khóa công khai theo `key_version`):

1. Đọc bản ghi theo `seq` bằng con trỏ khóa, trang 10.000, từ bản sao đọc (chỉ tới `min(head của bản sao, B.seq_last)`, vì bản sao có thể trễ).
2. Với bản ghi đầu đoạn, kiểm `prev_hash = A.hash_last`; với mỗi bản ghi kiểm `seq` tăng đúng 1, `prev_hash` bằng `hash` bản trước, và `hash` bằng tính lại từ nội dung đọc được (JCS dựng lại từ cột, đúng quy tắc §4.4).
3. Tại cuối đoạn kiểm `hash` bản cuối bằng `B.hash_last`.
4. Trả `Segment(from, to, ok, breakSeq, kind)`; `kind` ∈ `HASH_MISMATCH`, `SEQ_GAP`, `ANCHOR_SIGNATURE_INVALID`, `ANCHOR_MISMATCH`.

Các đoạn độc lập nhau (mỗi đoạn có điểm xuất phát đã ký) nên `VerificationService` chia việc cho `N` luồng ảo (mặc định 4, tối đa 8) và gom kết quả theo `seq`; `first_break_seq` là nhỏ nhất. Tenant thực thi tuần tự trong một hàng đợi (tối đa 4 tenant song song toàn nền tảng); mỗi tenant một lượt `RUNNING` bảo đảm bởi chỉ mục duy nhất từng phần theo `(tenant_id) WHERE status = 'RUNNING'` (ERR-13-032).

**So với WORM (`WormComparator`).** Lượt `DAILY` so mẫu 1% bản ghi theo từng lô (chọn bằng băm `seq`, ngẫu nhiên khác nhau mỗi ngày) và so đủ (`FULL`) mỗi Chủ nhật; lượt `ON_DEMAND` chọn `FULL` hoặc `SAMPLE`. So `FULL` tải từng lô, giải nén, so `hash` từng dòng với bảng và so `sha256` lô với `manifest`; không đọc được thì `wormCheck = UNAVAILABLE`, giao diện hiện "Chưa đối chiếu được với kho WORM." (không báo đạt hoàn toàn).

**`BreakHandler` (FR-13-015).** Khi một lượt `FAILED`, hoặc neo lệch, hoặc `TamperProbe` báo, `BreakHandler` thực hiện theo thứ tự, mỗi bước độc lập để lỗi một bước không chặn bước sau: (1) xác định khoảng từ `first_break_seq` tới đầu chuỗi; (2) đặt `audit_chain.integrity = SUSPECT` và lưu `suspect_from_seq`, giao diện tra cứu hiện dải đỏ và đánh dấu bản ghi trong khoảng; (3) phát `ChainBrokenEvent` (sự kiện Modulith bền) để module `observability` tạo cảnh báo an ninh UC-SEC-20 mức Nghiêm trọng gửi SO, TA (và PA nếu chuỗi `PLATFORM`), và phát EVT-13-05; (4) `EvidenceCollector` sao khoảng bản ghi nghi vấn từ bảng và từ WORM cùng kết quả kiểm tra vào bucket `dh-evidence` có Object Lock (SEC-75, kèm biên bản băm và người thu là `system:dh-platform`); (5) mở hồ sơ ứng cứu ở PH-18 kèm đường dẫn. Chuỗi vẫn nhận bản ghi mới. `ChainStatusService.clearSuspect` chỉ chạy khi cảnh báo an ninh tương ứng đóng với kết luận của SO (FR-13-053) và một lượt kiểm tra mới đạt trên đoạn sau điểm đứt; không có API sửa, nối lại hay dựng lại chuỗi (BR-13-033). Lỗi `WORM_MISMATCH` (bảng đúng, WORM lệch) vẫn mức Nghiêm trọng và bucket WORM bị cách ly khỏi ghi tới khi điều tra xong.

### 4.8. Đối chiếu số lượng và lưu trữ phân vùng

::: dac-ta
**Mục đích.** Chứng minh 100% thao tác thuộc FR-00-040 có bản ghi bằng cách so số DU báo phát với số PH-13 nhận mỗi ngày, và quản lý vòng đời phân vùng tháng (tạo, chốt, lưu trữ chỉ khi bản WORM đã xác minh).

**Lớp chính.** `ReconciliationService`, `PartitionManager`, `ArchiveService`, `RetentionPolicy`.

**Đơn vị chạy.** `dh-platform`, vai trò `jobs`.

**FR hiện thực.** FR-13-017, FR-13-018.

**Giao diện vào.** Lịch 01:00 hằng ngày (đối chiếu), 03:00 ngày 1 mỗi tháng và hằng ngày (phân vùng); API-13-086, 088 (đọc).

**Phụ thuộc ra.** Mimir (`dh_audit_emitted_day`), `pg-core`, WORM, vai trò `ph13_archive` (OpenBao).

**Dữ liệu.** `audit_reconciliation`, `audit_partition`.

**Sự kiện.** EVT-13-09 khi `MISMATCH`; EVT-13-11 khi lưu trữ phân vùng.

**Lỗi và xử lý.** ERR-13-111 lệch số; ERR-13-125 chưa đủ điều kiện lưu trữ; ERR-13-014 khi Mimir không đọc được (thử lại giờ sau, quá 24 giờ `WARNING`); DU không xuất bộ đếm: `NO_COUNTER`.

**Quan sát.** `dh_audit_reconcile_diff{du,tenant}`, `dh_audit_partition_status{status}`, `dh_audit_partition_archive_total{result}`.
:::

Chi tiết thiết kế:

**Đối chiếu.** Với ngày `D` theo múi giờ `Asia/Ho_Chi_Minh`, mỗi cặp (DU, tenant): `emitted` đọc từ `dh_audit_emitted_day{day=D}` (giá trị lớn nhất trong giờ cuối của ngày kế tiếp, vì bộ đếm chỉ tăng); `received` đếm `audit_event` có `source_du = du` và `occurred_at ∈ D` cộng bản cách ly cùng điều kiện. Vì bảng phân vùng theo `recorded_at` còn `occurred_at` có thể muộn tới nhiều giờ khi có tồn đọng, truy vấn quét phân vùng của tháng `D` và tháng kế tiếp, dùng chỉ mục `(tenant_id, source_du, occurred_at)` (đề nghị cho D03-03-PH13). `diff > 0` thì chờ 2 giờ rồi đếm lại; còn lệch thì `MISMATCH`, EVT-13-09, cảnh báo `CRITICAL` cho DU nguồn; `diff < 0` thì `SURPLUS` cảnh báo vì bộ đếm có thể sai. Vì bộ đếm của DU nằm trong cùng giao dịch với hộp thư đi (§4.2) nên một thao tác mất giữa DU và PH-13 luôn làm `diff > 0`.

**Phân vùng.** `PartitionManager` tạo trước 3 phân vùng tháng, chốt `SEALED` khi mọi lô WORM của tháng đã sao, đã so khớp và đối chiếu số lượng của tháng đều `MATCH`; đồng thời ký neo `BOUNDARY` (§4.5). Lưu trữ cho phân vùng `SEALED` quá `13.audit.online-months`: `ArchiveService.preflight` kiểm mọi lô trên WORM của dải `seq`, băm khớp bản trong bảng (đọc đủ cả hai phía), thời hạn giữ còn đủ; đạt thì mở phiên vai trò `ph13_archive` (OpenBao động, TTL 15 phút, chỉ `EXECUTE` thủ tục `p_archive_partition`, không quyền bảng), gọi thủ tục để tách và xóa phân vùng (thủ tục dùng `DETACH PARTITION` thường vì `CONCURRENTLY` không chạy được trong thủ tục; khóa ngắn chấp nhận được vì phân vùng đã `SEALED`, Q13-51), ghi `AUDIT.PARTITION.ARCHIVE` và EVT-13-11. Không đạt: giữ `SEALED`, ERR-13-125. Sau khi lưu trữ, điểm xuất phát của kiểm tra hằng ngày dời tới neo `BOUNDARY` của tháng cũ nhất còn trực tuyến.

### 4.9. Tra cứu kiểm toán, lịch sử đối tượng và truy cập liên tenant

::: dac-ta
**Mục đích.** Cho kiểm toán viên và cán bộ ATTT tra bản ghi theo bộ lọc, xem chi tiết kèm xác minh băm, tra theo đối tượng bị tra cứu, xem lịch sử của một đối tượng và rà soát truy cập liên tenant, với mọi lượt tra đều bị ghi vết trước khi trả kết quả.

**Lớp chính.** `AuditSearchService`, `ObjectKeyHasher`, `HistoryService`, `CrossTenantReport`, `ChainIndicator`, `SensitiveReadGuard`, `StepUpVerifier`, `ReasonValidator`.

**Đơn vị chạy.** `dh-platform`, vai trò `api`.

**FR hiện thực.** FR-13-019, 020, 021, 022, 023, 025.

**Giao diện vào.** API-13-074 `POST /records:search`, 075, 076, 085; UI-13-13, UI-13-16.

**Phụ thuộc ra.** `pg-core` (bản sao đọc cho truy vấn nặng), OpenBao (`transit/hmac`), `dh-audit` (ghi `AUDIT.QUERY`), PH-12 (quyền, xác thực lại).

**Dữ liệu.** `audit_event`, `audit_anchor`, `audit_verification`, `audit_chain`.

**Sự kiện.** EVT-13-12 khi bộ ghi chuỗi (§4.4) thấy bản ghi `AUDIT.CROSS_TENANT.OPEN` cam kết.

**Lỗi và xử lý.** ERR-13-004, 005, 008, 009, 012, 013, 014, 015, 029, 031, 036; không ghi vết được: từ chối (fail-closed).

**Quan sát.** `dh_audit_query_total{kind,result}`, `dh_audit_query_duration_seconds`, `dh_audit_query_rejected_total{reason}`.
:::

Chi tiết thiết kế:

**`SensitiveReadGuard` (fail-closed, BR-13-006).** Mọi phương thức `@AuditedRead` đi qua `begin(action, context)`: trong một giao dịch riêng (`REQUIRES_NEW`) ghi bản ghi `AUDIT.QUERY` (hoặc `AUDIT.RECORD.VIEW`, `AUDIT.VERIFY`, `AUDIT.EXPORT.*`) vào hộp thư đi, cam kết, rồi mới chạy truy vấn. Không cam kết được thì ném `AuditUnavailableException` và API trả ERR-13-014; truy vấn chưa chạy nên không dữ liệu nào trả ra mà không có vết. Bản ghi `AUDIT.QUERY` chứa tóm tắt bộ lọc, lý do, số bản ghi trả về được cập nhật bằng một bản ghi phụ `AUDIT.QUERY.RESULT` (vì bản đầu bất biến).

```{.mermaid caption="Luồng tra cứu kiểm toán ghi vết trước khi đọc (FR-13-020)"}
flowchart TB
  A["Yêu cầu: khoảng thời gian, bộ lọc, lý do"] --> B{"Kiểm tra: quyền, khoảng, lý do 10 đến 500"}
  B -->|"không đạt"| X["ERR-13-009, 004, 005, 012"]
  B -->|"đạt"| C["Ghi AUDIT.QUERY vào hộp thư đi, cam kết"]
  C -->|"lỗi"| Y["ERR-13-014, không trả dữ liệu"]
  C -->|"đạt"| D["Đếm tối đa 1.000.001 dòng"]
  D -->|"trên 1.000.000"| Z["ERR-13-013"]
  D -->|"đạt"| E["Truy vấn keyset, tối đa 200 dòng, RLS"]
  E --> F["Gắn chỉ báo toàn vẹn và trạng thái chuỗi"]
```

Luồng cho thấy việc ghi vết nằm **trước** việc đọc dữ liệu và là điều kiện để đọc; mọi nhánh lỗi đều dừng trước khi có dòng dữ liệu nào rời máy chủ.

**`AuditSearchService`.** Bộ lọc là danh sách trắng (thời gian, người thao tác, `action`, `object_type`, `object_id`, `outcome`, `trace_id`, `source_du`, `session_hash`), mỗi điều kiện có chỉ mục dành riêng ở D03-03-PH13 (theo thời gian; theo đối tượng; theo người; theo `action`; theo `trace_id`; theo `object_key_hmac`); không nhận biểu thức tự do. Đếm bằng `SELECT count(*) FROM (SELECT 1 ... LIMIT 1000001)` để chặn phạm vi quá rộng chính xác thay vì ước lượng của bộ lập kế hoạch. Phân trang con trỏ theo `(recorded_at, seq)`, tối đa 200 dòng (ERR-13-038). Khoảng thời gian có phần quá thời hạn trực tuyến: phần trực tuyến trả bình thường kèm dòng "Dữ liệu trước {ngày} nằm ở kho lưu trữ; dùng Xuất bằng chứng để lấy." (ERR-13-029 khi toàn bộ khoảng nằm ngoài). `ChainIndicator` đính kèm kết quả kiểm tra gần nhất, neo gần nhất và `integrity`; chuỗi `SUSPECT` vẫn trả kết quả kèm dải đỏ. Truy vấn nặng (khoảng trên 31 ngày) chạy trên bản sao đọc với `statement_timeout = 30s` (ERR-13-015) và `13.query.max-concurrent-per-user` (ERR-13-011).

**Tra theo đối tượng bị tra cứu (BR-13-005).** `ObjectKeyHasher` chuẩn hóa định danh (bỏ khoảng trắng, kiểm độ dài và chữ số, ERR-13-031) rồi gọi `transit/hmac/dh-{tenant}-audit-hmac/sha2-256`; đầu ra `vault:v1:base64` được đổi sang 64 ký tự thập lục phân để khớp cột `object_key_hmac`. Biến chứa định danh được xóa tham chiếu ngay sau khi băm, nằm ngoài mọi bản ghi log (luật R5) và ngoài `AUDIT.QUERY` (bản ghi chỉ chứa `object_key_hmac`). Nếu khóa HMAC từng được xoay (chỉ khi có sự cố), tìm theo mọi phiên bản chưa hủy bằng `object_key_hmac IN (...)`.

**Lịch sử đối tượng (FR-13-022).** `HistoryService` phục vụ tab "Lịch sử" của các phân hệ khác. DU gọi bằng token đổi từ người dùng, có scope `audit:history-read`, và đã tự kiểm tra quyền `read` của đối tượng (PH-13 không biết quyền của từng phân hệ). Tenant lấy từ token (SEC-80). Chỉ trả giá trị đã che; tab "Lịch sử" không có nút "Hiện" nên `PERM-09-unmask` không áp dụng (đề nghị đồng bộ cho FR-00-043).

**Truy cập liên tenant (FR-13-025).** Bản ghi mở và đóng phiên (`AUDIT.CROSS_TENANT.OPEN`, `.CLOSE`) do nơi cấp phiên (PH-12, FR-00-012) ghi bằng `AuditRecorder.recordCrossTenant(entry, homeTenant, targetTenant)`, lời gọi duy nhất được đặt tenant tường minh: nó ghi hai hàng hộp thư đi, một vào topic của tenant bị truy cập và một vào topic của tenant nhà (BR-13-017, BR-13-018); ArchUnit chỉ cho phép gọi nó từ mã của phiên liên tenant. Khi `ChainWriter` cam kết bản `OPEN`, một sự kiện Modulith kích hoạt phát EVT-13-12 và thông báo cho quản trị tỉnh bị truy cập. `CrossTenantReport` truy vấn `actor_home_tenant <> tenant_id`, gom theo `session_hash` thành phiên (người, tenant nhà, lý do, thời hạn, số thao tác, kết quả) và dẫn sang tra cứu đã lọc theo phiên. Tenant `PLATFORM` thấy phía "đi" gom theo tenant đích.

**Quyền.** Lớp `web` dùng `@PreAuthorize` theo `PERM-13-audit-read` cho tra cứu, xem chi tiết, lịch sử, báo cáo liên tenant; xuất bằng chứng và kiểm tra toàn vẹn theo yêu cầu cần `PERM-13-audit-export`. `StepUpVerifier` kiểm claim `acr` và `auth_time` (xác thực lại trong 5 phút) cho thao tác xuất và tra theo đối tượng (ERR-13-028).

### 4.10. Xuất bằng chứng kiểm toán ký số

::: dac-ta
**Mục đích.** Cho kiểm toán viên một gói bằng chứng có chữ ký số, tự xác minh được ngoại tuyến, gồm bản ghi trong phạm vi, chuỗi băm, neo liên quan và khóa công khai.

**Lớp chính.** `ExportService`, `ExportWorker`, `BundleBuilder`, `BundleSigner`, `ExportJanitor`.

**Đơn vị chạy.** `dh-platform`: `api` nhận yêu cầu, `jobs` chạy `ExportWorker` và `ExportJanitor`.

**FR hiện thực.** FR-13-024.

**Giao diện vào.** API-13-082 `POST /exports`, 083 (trạng thái), 084 (tải); UI-13-14.

**Phụ thuộc ra.** `pg-core`, WORM (đọc phần trên 12 tháng), OpenBao (`transit/sign`), Garage bucket `dh-audit-export-tmp`, `SegmentVerifier`.

**Dữ liệu.** `audit_export`; đối tượng `exports/{tenant}/{exportId}.zip`.

**Sự kiện.** EVT-13-08 khi `READY`.

**Lỗi và xử lý.** ERR-13-013 (quá 10 triệu bản ghi), 025, 026, 027, 028, 012; không ký được thì `FAILED`, xóa tệp tạm.

**Quan sát.** `dh_audit_export_duration_seconds`, `dh_audit_export_records_total`, `dh_audit_export_total{result}`.
:::

Chi tiết thiết kế:

**Hàng đợi.** `audit_export` là hàng đợi: `ExportWorker` lấy việc `REQUESTED` bằng `FOR UPDATE SKIP LOCKED`, tối đa 2 việc mỗi bản sao. `scope_hash = SHA-256(tenant ‖ phạm vi ‖ bộ lọc chuẩn tắc)` có chỉ mục duy nhất từng phần cho trạng thái `REQUESTED`, `RUNNING` (ERR-13-025). Yêu cầu hủy khi chưa `RUNNING` đổi sang `CANCELLED`; khi đang chạy, cờ hủy được kiểm giữa các trang.

**Cấu trúc gói và cách xác minh.**

| Tệp trong gói | Nội dung |
|---|---|
| `records.jsonl` | Bản ghi khớp bộ lọc, mỗi dòng một JSON (đã che), theo `seq` |
| `chain-skeleton.jsonl` | `{seq, prev_hash, hash}` của mọi bản ghi còn lại trong dải `seq` bao phủ (rỗng khi không lọc); để bản ghi khớp lọc nối được tới neo mà không lộ bản ghi khác |
| `anchors.json` | Neo trong dải, kèm `key_version`, chữ ký DER dạng base64 |
| `public-keys.pem` | Khóa công khai của các `key_version` liên quan |
| `verification.json` | Kết quả `SegmentVerifier` cho dải (cảnh báo rõ ở đầu tệp nếu không toàn vẹn) |
| `manifest.json`, `manifest.sig` | Phạm vi `seq`, số bản ghi, SHA-256 từng tệp; chữ ký của `SHA-256("datahub-evidence-v1\n" ‖ manifest)` |
| `HUONG-DAN-XAC-MINH.md`, `verify.py`, `verify.sh` | Hướng dẫn và script chỉ dùng thư viện chuẩn của Python 3 và `openssl` |

: Cấu trúc gói bằng chứng

`verify.py` thực hiện: kiểm băm từng tệp theo `manifest`; kiểm `manifest.sig` bằng `openssl dgst -sha256 -verify`; tính lại `hash` từng bản ghi bằng `json.dumps(sort_keys=True, separators=(',', ':'), ensure_ascii=False)` (đồng nhất với JCS vì bản ghi chỉ có chuỗi, số nguyên và boolean, §4.4); kiểm liên kết với `chain-skeleton` tới neo; kiểm chữ ký neo. Chữ ký có hai mức: `manifest.sig` trong gói (xác minh ngoại tuyến) và chữ ký của băm toàn gói lưu ở `audit_export.signature` (xác minh khi nhận). Domain separation bằng tiền tố chuỗi giúp chữ ký gói không dùng lại làm chữ ký neo dù cùng khóa `dh-audit-sign`.

**Chạy nền, luồng dữ liệu.** `BundleBuilder` ghi ZIP64 trực tiếp lên bucket tạm bằng tải lên nhiều phần (không giữ cả gói trên đĩa pod), tính băm khi ghi. Phần trong 12 tháng đọc từ bảng theo con trỏ `seq`; phần cũ hơn đọc từ lô WORM. `manifest` được ghi sau cùng (ZIP cho phép), rồi `BundleSigner` ký hai lần (manifest, băm toàn gói). Chỉ khi cả hai chữ ký có, trạng thái mới sang `READY` (BR-13-014); lỗi bất kỳ thì `FAILED`, tệp tạm bị xóa và ERR-13-026 hiện cho người yêu cầu. Giới hạn: 10 triệu bản ghi mỗi gói (BR-13-029), 1 triệu bản ghi hoàn tất trong 15 phút (NFR-13-031).

**Tải và hết hạn.** `GET /exports/{id}/download` ghi `AUDIT.EXPORT.DOWNLOAD` (fail-closed), rồi trả URL ký sẵn của Garage hiệu lực `13.export.link-ttl-minutes` (15 phút); quá 7 ngày `ExportJanitor` (mỗi giờ) xóa tệp, đổi sang `EXPIRED` và giữ siêu dữ liệu 5 năm. Quy tắc vòng đời bucket 7 ngày là lớp dự phòng của việc xóa ở ứng dụng.

### 4.11. Tuyến thu thập quan sát

::: dac-ta
**Mục đích.** Thu chỉ số, log, trace từ mọi thành phần vào ba kho theo đúng tenant, che dữ liệu Nhạy cảm, giữ mọi trace quan trọng, giới hạn số chuỗi chỉ số, và không bao giờ chặn nguồn phát.

**Lớp chính.** Cấu hình OTel Collector (agent, gateway) và hai thành phần Java sinh cấu hình: `CollectorConfigRenderer`, `SamplingThresholdPublisher`; công việc `SecurityLogArchiver`.

**Đơn vị chạy.** `dh-obs` (agent DaemonSet, gateway 3 bản sao ở Z7); các thành phần Java ở `dh-platform` vai trò `jobs`.

**FR hiện thực.** FR-13-001, 002, 003, 004, 005 (phần che), 006, 007; phần ghi của FR-13-009.

**Giao diện vào.** OTLP gRPC/HTTP từ SDK, scrape Prometheus, `filelog`, Kafka `{tenant}.obs.access.logged.v1`.

**Phụ thuộc ra.** Mimir, Loki, Tempo (OTLP/HTTP kèm `X-Scope-OrgID`), ClickHouse (qua Kafka), `otel-siem` (§4.21), Garage (kho nén log an ninh).

**Dữ liệu.** Không có CSDL riêng; ConfigMap `obs-gateway-routes`, `obs-tail-sampling`; bảng `tenant_obs_config`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-13-113 thiếu nhãn tenant (gán `_unattributed`); ERR-13-114 nhãn ngoài danh sách hoặc vượt hạn mức chuỗi; ERR-13-115 Collector quá tải; ERR-13-116, 117 trace quá dài hoặc thiếu span; ERR-13-118 ClickHouse không ghi được.

**Quan sát.** `otelcol_*` của chính Collector, `dh_obs_trace_decision_total{decision,reason}`, `dh_obs_access_dropped_total`, `dh_obs_series_active{tenant}`.
:::

Chi tiết thiết kế:

**Hai tầng Collector.** Agent chạy trên mỗi nút, nhận OTLP từ pod cùng nút (`internalTrafficPolicy: Local`), thu `filelog` (log container, phân tích JSON) và scrape theo chú thích hoặc `ServiceMonitor`; bộ xử lý `memory_limiter` (80%), `k8sattributes` (đọc nhãn `dh.gov.vn/tenant`, `dh.gov.vn/du` của namespace và pod), `batch`. Xuất tới gateway bằng `otlp` kèm hàng đợi bền trên đĩa (`file_storage`) đủ đệm 2 giờ khi gateway hoặc kho ngừng, quá hạn thì bỏ dữ liệu ít quan trọng trước (log mức DEBUG, INFO) và đếm (ERR-13-115). Riêng trace, agent dùng `loadbalancing` exporter với `routing_key = traceID` tới ba pod gateway, để mọi span của một trace gặp nhau ở cùng một gateway cho lấy mẫu đuôi.

| Đường ống ở gateway | Bộ xử lý chính | Đích |
|---|---|---|
| Chỉ số | `attributes` (ép `tenant`), `transform` (giữ nhãn trong danh sách §4.8 FRS, xóa phần còn lại), `routing` theo `tenant` | Mimir, OrgID = tenant |
| Log ứng dụng | `redaction` (danh sách khóa cho phép, che mẫu bằng `***` giữ độ dài), `attributes`, `routing` | Loki, OrgID = tenant; `trace_id` nằm ở siêu dữ liệu có cấu trúc, không phải nhãn luồng |
| Log an ninh | Như trên, đánh dấu theo nguồn (Keycloak, OPA, APISIX/WAF, nhật ký OpenBao, audit K8s, `pgaudit`, Hubble, Falco) | Loki, OrgID = `{tenant}-security` (12 tháng), `otel-siem` |
| Trace | `spanmetrics` (tính RED từ **mọi** span trước khi lấy mẫu), `tail_sampling`, `redaction`, `routing` | Tempo, OrgID = tenant |

: Đường ống Collector gateway

**Gắn tenant (BR-13-027).** Với namespace `dh-rt-{tenant}` và nút của tenant, `tenant` chỉ lấy từ nhãn namespace, bỏ mọi giá trị do dữ liệu tự khai. Với các DU nhiều tenant của control plane (`dh-platform`, `dh-integration`, `dh-data`, `dh-connect`, `dh-payment`) thuộc tính `tenant` của điểm dữ liệu do ứng dụng đặt từ `TenantContext` được chấp nhận, nhưng gateway kiểm giá trị thuộc danh sách tenant đang hoạt động (nạp từ PH-20) và nguồn thuộc danh sách DU kiểm soát; sai thì gán `_unattributed` (chỉ vai trò nền tảng thấy, ERR-13-113). Hạ tầng dùng chung (Kafka, PostgreSQL, OpenBao, K8s) thuộc tenant `PLATFORM`; chỉ số theo chủ đề Kafka suy ra tenant từ tiền tố tên topic.

**Lấy mẫu đuôi (BR-13-010).** Chính sách đánh giá theo thứ tự: giữ nếu có span lỗi; giữ nếu tổng thời gian vượt ngưỡng chậm của route; giữ nếu có thuộc tính `dh.data.class` từ Nhạy cảm trở lên hoặc `dh.audit = true`; phần còn lại giữ xác suất cố định theo `trace_id` bằng `13.trace.success-sample-percent` (10%). `decision_wait = 13.trace.decision-wait-seconds` (30 giây), `num_traces = 500.000` (đầy thì chuyển tạm sang lấy mẫu đầu 10% và phát ERR-13-115). Ngưỡng chậm "p99 của route" không đổi động được trong `tail_sampling`, nên `SamplingThresholdPublisher` mỗi ngày 02:00 đọc quy tắc ghi lại `dh:route_latency_p99:7d` từ Mimir, tính `max(p99 tuần trước, 2 × ngưỡng SLO)` (route chưa đủ dữ liệu chỉ dùng 2 × ngưỡng SLO) và dựng lại ConfigMap `obs-tail-sampling`; gateway được cuộn lại từng pod (PodDisruptionBudget `maxUnavailable = 1`). Mất bộ đệm quyết định của một pod trong lúc cuộn tối đa 30 giây dữ liệu của pod đó, chấp nhận được với đường quan sát.

**Chống bùng nổ chuỗi (BR-13-026, NFR-13-020).** `transform` giữ nhãn trong danh sách cho phép, cộng nhóm nhãn kỹ thuật có miền giá trị đóng của chỉ số do chính PH-13 và `dh-audit` phát (`result`, `decision`, `reason`, `backend`, `channel`, `probe`, `step`, `day`); danh sách này chỉ áp cho `du` thuộc `dh-platform` và thư viện `dh-audit`, và được ghi vào đề nghị đồng bộ cho FRS §4.8. Giới hạn cứng nằm ở Mimir: `max_global_series_per_user = 13.series.max-active` (ghi vào overrides, §4.22); vượt thì Mimir từ chối chuỗi mới và gateway đếm `otelcol_exporter_send_failed_metric_points`, `CapacityWatcher` (§4.19) cảnh báo từ 85%.

**Siêu dữ liệu lượt gọi (FR-13-006).** Plugin `kafka-logger` của APISIX (cấu hình ở PH-03) gửi bản ghi chỉ có siêu dữ liệu (không `Authorization`, không chuỗi truy vấn, không thân) theo lô tới `{tenant}.obs.access.logged.v1`, đệm tối đa 10.000 bản ghi rồi bỏ và đếm `dh_obs_access_dropped_total`, không chặn lượt gọi (BR-13-015). ClickHouse đọc bằng bảng động cơ Kafka với danh sách topic dạng biểu thức chính quy (librdkafka hỗ trợ; kiểm ở bộ kiểm thử tích hợp, §12) và view vật chất hóa ghi `access_log` (`ReplicatedMergeTree`, sắp theo `(tenant_id, route_id, ts)`), chỉ nhận dòng có `tenant_id` khớp tiền tố topic (cột ảo `_topic`), dòng khác vào `access_log_rejected` và đếm (ERR-13-104). Hai view vật chất hóa tổng hợp theo phút và theo giờ (số lượt, lỗi theo lớp, p50, p95, p99) phục vụ bảng điều khiển; chi tiết xóa sau 12 tháng bằng TTL, tổng hợp theo giờ giữ 5 năm.

**Chỉ số thành phần nền (FR-13-007).** Nguồn: kube-state-metrics, cAdvisor, node-exporter, exporter của Strimzi, CNPG, OpenBao, Keycloak, ClickHouse, APISIX, Istio. Chỉ số hạ tầng chung gắn `tenant = PLATFORM`; nhãn `pod` chỉ có ở chỉ số hạ tầng. Chu kỳ thu `13.metrics.scrape-interval-seconds` (15 giây).

**Kho nén log an ninh.** `SecurityLogArchiver` chạy 04:00 hằng ngày, đọc log của org `{tenant}-security` đã qua 12 tháng trực tuyến một ngày trước khi Loki xóa, nén `zstd` vào bucket `dh-seclog-archive` ở Garage với quy tắc vòng đời 3 năm (D03-07 §7.3). Đây là kho nén để tra cứu khi có yêu cầu, không phải WORM.

### 4.12. Kiểm tra tổng hợp và quét dữ liệu cá nhân trong log

::: dac-ta
**Mục đích.** Góc nhìn từ ngoài vào: gọi thử các API quan trọng mỗi phút để biết người dùng có dùng được không; và chứng minh bằng bộ quét hằng ngày rằng log không chứa giá trị Nhạy cảm.

**Lớp chính.** `SyntheticProbeRunner`, `ProbeDefinitionService`, `PiiScanner`, `PiiFindingRepository`.

**Đơn vị chạy.** `dh-platform`, vai trò `jobs`.

**FR hiện thực.** FR-13-008; phần quét của FR-13-005.

**Giao diện vào.** Lịch theo `13.probe.interval-seconds` (60 giây); lịch quét 02:00; API-13-070, 071 (định nghĩa kiểm tra trong cấu hình).

**Phụ thuộc ra.** APISIX bên ngoài, Keycloak (token), OpenBao PKI (`pki-tenant-{tenant}`), Loki.

**Dữ liệu.** `probe_definition`; bảng phát hiện `pii_finding` (DU, logger, số lần, mã mẫu đã che, không chứa giá trị).

**Sự kiện.** EVT-13-13 khi kiểm tra thất bại liên tiếp.

**Lỗi và xử lý.** ERR-13-124 thất bại liên tiếp; ERR-13-112 log chứa mẫu cá nhân; ERR-13-014 khi Loki không đọc được; ERR-13-003 khi định nghĩa trỏ API không tồn tại.

**Quan sát.** `dh_probe_success{probe}`, `dh_probe_duration_seconds{probe}`, `dh_obs_pii_findings_total{du}`, `dh_obs_pii_last_scan_timestamp{tenant}`.
:::

Chi tiết thiết kế:

**Kiểm tra tổng hợp.** `SyntheticProbeRunner` chạy mỗi định nghĩa trên một luồng ảo riêng với độ lệch ngẫu nhiên tối đa 10 giây để các tenant không dồn cùng lúc. Mỗi lượt: lấy token bằng client `dh-probe-{tenant}` (mTLS theo RFC 8705, chứng thư do OpenBao PKI cấp, SEC-24), gọi `https://{apisix-ext}/{api}` qua đường biên bên ngoài kèm `x-dh-synthetic: true`, so mã HTTP và độ trễ với `expected_status`, `timeout_ms`; ghi `dh_probe_success`, `dh_probe_duration_seconds` có nhãn `tenant`. Tham số bắt buộc của API đích dùng giá trị mẫu cố định trong định nghĩa (dữ liệu thử, không phải dữ liệu thật). Lượt gọi có cờ đồng bộ được ClickHouse đánh `synthetic = 1` để loại khỏi thống kê nghiệp vụ. Thất bại lần thứ ba liên tiếp (đếm trong bộ nhớ của bản sao thực thi, mất khi khởi động lại nên luật chuẩn `probe-failed` dùng `sum_over_time(dh_probe_success[3m]) == 0` làm nguồn chính) phát EVT-13-13 và ERR-13-124. Không xin được token thì tính là thất bại và cảnh báo thêm cho PH-12. Tenant tạm ngừng thì dừng kiểm tra.

**Quét dữ liệu cá nhân (NFR-13-021).** Hằng ngày 02:00, mỗi tenant: (1) mẫu 1% log 24 giờ qua, xấp xỉ bằng cách lấy `ceil(1% × số dòng)` dòng từ một điểm bắt đầu ngẫu nhiên trong mỗi giờ (LogQL không có lấy mẫu ngẫu nhiên); (2) 100% dòng mức `ERROR` phân trang theo thời gian. `PiiScanner` dùng bộ mẫu riêng ở `pii-scan-patterns.yaml`, độc lập với `Redactor` của `dh-audit` và với bộ che ở Collector (để một lỗi mẫu không làm hai lớp cùng hỏng): số định danh 12 chữ số có kiểm cấu trúc (ba chữ số đầu thuộc bảng mã tỉnh trong cấu hình), điện thoại, thư điện tử, số thẻ qua Luhn, khóa tên nhạy cảm có giá trị khác `***`. Phát hiện ghi vào `pii_finding` (12 tháng) chỉ gồm DU, logger, số lần và mã mẫu, không lưu giá trị (BR-13-011), tăng `dh_obs_pii_findings_total{du}` và cảnh báo `WARNING` cho DU nguồn; cùng DU tái phạm 3 ngày liên tiếp thì nâng `CRITICAL` và đề nghị bật `quarantine` (cờ `obs.pii.quarantine` theo DU do SO duyệt; bật thì cấu hình gateway loại log của DU đó khỏi kho tra cứu cho tới khi sửa).

### 4.13. Cổng truy vấn quan sát và cách ly tenant

::: dac-ta
**Mục đích.** Điểm duy nhất mà mọi truy vấn của người dùng và của phân hệ khác đi qua để tới Mimir, Loki, Tempo, ClickHouse, Grafana, bảo đảm một tenant không đọc được dữ liệu tenant khác và không làm quá tải kho.

**Lớp chính.** `TenantScope`, `OrgIdResolver`, `ExpressionGuard`, `QueryLimiter`, `QueryCache`, `MimirClient`, `LokiClient`, `TempoClient`, `ClickHouseClient`, `LeakTestRunner`, `MetricsSummaryService`.

**Đơn vị chạy.** `dh-platform`, vai trò `api` (và `jobs` cho kiểm thử rò rỉ).

**FR hiện thực.** FR-13-009 (phía truy vấn), FR-13-056.

**Giao diện vào.** Mọi API đọc `/api/observability/v1`; API-13-067 `POST /metrics:query`, 068 `GET /metrics/summary` (scope `obs:metrics-read`).

**Phụ thuộc ra.** Mimir, Loki, Tempo, ClickHouse, Valkey (đệm và bộ đếm đồng thời).

**Dữ liệu.** Không có bảng riêng; đệm Valkey khóa qua hàm tạo tên có tenant (SEC-82).

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-13-044 vượt phạm vi tenant hoặc thiếu scope; ERR-13-006 cú pháp sai; ERR-13-005 khoảng quá dài; ERR-13-011 quá nhiều truy vấn; ERR-13-014, 015 kho lỗi hoặc quá hạn; kiểm thử rò rỉ thành công: sự cố SEV-1 và ngừng truy vấn tự do.

**Quan sát.** `dh_obs_query_duration_seconds{backend}`, `dh_obs_query_rejected_total{reason}`, `dh_obs_leaktest_result_total{result}`.
:::

Chi tiết thiết kế:

**Bức tường thật là OrgID.** `TenantScope` được dựng từ token đã xác minh (SEC-80), không từ tham số hay tiêu đề do người dùng gửi. `OrgIdResolver` ánh xạ (tenant, loại dữ liệu) thành `X-Scope-OrgID`: `T68` cho chỉ số, log, trace thường; `T68-security` cho log an ninh và chỉ cho vai trò có `PERM-13-security` hoặc `PERM-13-audit-read` (Q13-18); `PLATFORM` cho chế độ toàn nền tảng của PA, PO (chỉ chỉ số tổng hợp); tenant khác chỉ khi có phiên liên tenant còn hiệu lực (ERR-13-036) và mỗi truy vấn ghi `OBS.CROSS_TENANT_ACCESS`. Mimir, Loki, Tempo chạy với `tenant_federation.enabled = false` nên `X-Scope-OrgID: a|b` bị từ chối; `OrgIdResolver` còn kiểm chuỗi theo `^[A-Za-z0-9_-]{1,150}$`. ClickHouse dùng ba lớp: mẫu truy vấn có tên (không nhận SQL tự do) với tham số `tenant_id` ràng buộc; `ClickHouseClient` đặt setting `SQL_dh_tenant` cho chính sách dòng; và người dùng ClickHouse của PH-13 chỉ đọc.

**`ExpressionGuard` là lớp thứ hai (FR-13-009 bước 2).** Biểu thức do người dùng gõ có ba chỗ: biểu thức luật cảnh báo và chạy thử (§4.16), `POST /metrics:query` của PH-16, và tìm trace (TraceQL do biểu mẫu dựng). Tra log dùng cú pháp đơn giản `trường:giá-trị` được `SimpleQueryCompiler` dịch sang LogQL (§4.14) nên người dùng không gõ LogQL (Q13-19). `ExpressionGuard` không cần hiểu ngữ nghĩa mà chỉ trích mọi bộ chọn nhãn bằng bộ tách từ (PromQL, TraceQL) và từ chối khi: bộ chọn đặt nhãn `tenant` (hoặc `__tenant_id__`) khác tenant của người gọi, dùng toán tử phủ định hay biểu thức chính quy trên `tenant`, khoảng truy vấn hay bước vượt giới hạn, hoặc biểu thức dài quá 4.096 ký tự; sau đó thêm `tenant="{tenant}"` vào bộ chọn của mọi chỉ số. Vì dữ liệu của tenant khác không có trong tổ chức đang truy vấn nên guard chỉ là phòng thủ chiều sâu; bộ tách từ tự viết hay dùng bộ phân tích cú pháp của Prometheus qua sidecar nhỏ được cân nhắc ở Q13-25.

**Giới hạn và đệm.** `QueryLimiter` giữ bộ đếm truy vấn đồng thời mỗi người (`13.query.max-concurrent-per-user`, 5) bằng khóa Valkey có TTL, chặn bằng ERR-13-011; thời gian chờ mỗi truy vấn `13.query.timeout-seconds` (30) ERR-13-015; khoảng tối đa mỗi lần tra theo loại dữ liệu ở §9.2. `QueryCache` đệm 15 giây cho truy vấn bảng điều khiển với khóa gồm tenant, truy vấn đã chuẩn hóa, bước và thời điểm làm tròn. Bảng điều khiển chuẩn dùng quy tắc ghi lại (`dh:*`) và view vật chất hóa để p95 ≤ 3 giây (NFR-13-004).

**Số liệu cho PH-16 (FR-13-056).** `MetricsSummaryService` chỉ tính trên khoảng thời gian đã kết thúc và đã chốt (dữ liệu cũ hơn `dataThrough` = hiện tại trừ 5 phút) từ quy tắc ghi lại và view vật chất hóa, nên cùng tham số luôn cho cùng kết quả; bước tối thiểu 1 phút; khoảng vượt thời hạn lưu chi tiết thì trả phần tổng hợp theo giờ hoặc ngày kèm `partial = true` và `availableFrom`.

**Kiểm thử rò rỉ (SEC-87).** `LeakTestRunner` dùng hai tenant kiểm thử T90, T91: mỗi ngày 04:30 tài khoản của T90 thử đọc dữ liệu T91 qua mọi API đọc, Grafana và truy vấn thô vào Mimir, Loki, Tempo, ClickHouse, PostgreSQL, WORM; mọi lần phải bị từ chối. Thành công dù một lần: cảnh báo `CRITICAL`, sự cố SEV-1 ở PH-13, cờ `obs.query.freeform` tự tắt (mọi biểu thức tự do bị từ chối bằng ERR-13-044 cho tới khi sửa). Bộ kiểm thử chạy ở môi trường thử và là cổng phát hành; ở PROD chỉ chạy khi chủ quản cho tạo hai tenant tổng hợp (Q13-27).

### 4.14. Tra log, truy vết và nhật ký truy cập API

::: dac-ta
**Mục đích.** Cho người vận hành và kỹ sư tích hợp tra log tập trung, theo dõi log trực tiếp, truy một giao dịch qua mọi thành phần bằng `trace_id`, liên kết ba nguồn và tra nhật ký truy cập API, tất cả đã che dữ liệu Nhạy cảm.

**Lớp chính.** `LogSearchService`, `SimpleQueryCompiler`, `LiveTailService`, `SavedQueryService`, `TraceService`, `TimeBreakdown`, `InsightGenerator`, `CorrelationService`, `AccessLogService`, `DiagnosticsService`.

**Đơn vị chạy.** `dh-platform`, vai trò `api`.

**FR hiện thực.** FR-13-026, 027, 028, 029, 030, 057.

**Giao diện vào.** API-13-019…029, API-13-069 (scope `obs:diagnostics-read`); UI-13-07, 08, 09.

**Phụ thuộc ra.** Qua `internal.query` tới Loki, Tempo, Mimir (exemplar), ClickHouse; `audit` (đếm bản ghi theo `trace_id` cho người có quyền).

**Dữ liệu.** `saved_query`; không lưu dữ liệu log.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-13-003, 004, 005, 006, 011, 014, 015, 030, 038; một kho lỗi thì phần đó trả `unavailable` kèm ERR-13-014, phần khác vẫn trả.

**Quan sát.** `dh_obs_logsearch_total{result}`, `dh_obs_livetail_active`, `dh_diag_requests_total{result}`.
:::

Chi tiết thiết kế:

**`SimpleQueryCompiler`.** Cú pháp `trường:giá-trị`, cụm trong dấu nháy, `-trường:giá-trị` để loại, `AND`, `OR` giới hạn ba cấp, và từ tự do (lọc dòng). Trường thuộc danh sách trắng chia hai loại: trường luồng (`du`, `namespace`, `level`, `service`, `flow`) dịch thành bộ chọn `{du="dh-data", level="error"}`; trường nội dung (`trace_id`, `user_id`, `route`, `system`) dịch thành `| json | user_id = "..."` hoặc bộ lọc siêu dữ liệu có cấu trúc. Mọi giá trị người dùng được thoát dấu nháy, dấu gạch ngược và bị từ chối nếu có dấu huyền; độ dài tối đa 512 ký tự; không có đường nào để người dùng viết bộ chọn luồng thô. Trang kết quả tối đa 200 dòng (ERR-13-038), khoảng tối đa mỗi lần tra theo §9.2. Ngữ cảnh một dòng lấy 10 dòng trước và sau cùng luồng bằng hai truy vấn theo hai hướng. Người vận hành nâng cao dùng Grafana (có LogQL, org đã tách).

**Theo dõi trực tiếp.** `LiveTailService` nối WebSocket `/loki/api/v1/tail` của Loki, đẩy ra trình duyệt qua SSE, giới hạn 1 phiên mỗi người và 200 dòng mỗi giây (quá thì gộp "bỏ qua {n} dòng"), nhịp tim 15 giây, tự tắt sau `13.live-tail.idle-minutes` (15) không hoạt động; mỗi dòng đi qua `Redactor` phía đọc (lớp phòng thủ thứ tư) trước khi gửi.

**Truy vết.** `TraceService.search` dựng TraceQL từ biểu mẫu (khoảng thời gian, thành phần, mã luồng, trạng thái lỗi, thời lượng tối thiểu) và `get` lấy trace theo mã. `TimeBreakdown` dựng cây span rồi tính thời gian riêng của từng span (thời lượng trừ hợp các khoảng của con) và gom theo thành phần; `InsightGenerator` sinh câu nhận xét theo luật cố định (span có thời gian riêng chiếm từ 50% tổng thì "{x}% thời gian là chờ {thành phần}", chặng lỗi đầu tiên theo thời gian được nêu tên). Trace thiếu span hoặc không có span gốc được đánh `incomplete` (ERR-13-117), trace quá dài cắt còn span đầu, cuối và lỗi (ERR-13-116). Trace hết hạn giữ hoặc bị bỏ do lấy mẫu trả ERR-13-030 khi cả ba nguồn đều trống.

**Liên kết ba nguồn (FR-13-029).** `CorrelationService` gọi song song bằng luồng ảo với hạn chót 3 giây mỗi nguồn: Tempo (trace), Loki (đếm dòng có `trace_id`), Mimir (exemplar), và chỉ khi người gọi có `PERM-13-audit-read` thì thêm `audit` (đếm bản ghi theo `trace_id` bằng chỉ mục `(tenant_id, trace_id)`); không có quyền thì phần này **vắng mặt, không báo có hay không** để không lộ sự tồn tại. Kết quả luôn trả được từng phần kèm `unavailable` cho nguồn lỗi.

**Nhật ký truy cập API (FR-13-030).** `AccessLogService` chỉ dùng mẫu truy vấn có tên tới `access_log` (lọc theo HTTT, API, lớp trạng thái, khoảng độ trễ, khoảng thời gian), phân trang bằng khóa `(ts, record_id)`, p95 ≤ 3 giây cho khoảng 24 giờ (NFR-13-006); thống kê dùng view vật chất hóa. Bản ghi chi tiết chỉ có siêu dữ liệu, không có thân (BR-13-011). Xuất danh sách dùng dịch vụ xuất chung của FR-00 với trần 100.000 dòng mỗi tệp (giả định, cơ sở: UC-SEC-12 coi 100.000 dòng/ngày/người là ngưỡng bất thường).

**Ngữ cảnh chẩn đoán cho PH-18 (FR-13-057).** `DiagnosticsService.forTrace` gom trong 3 giây: tóm tắt trace (nếu còn), tối đa 200 dòng log đã che theo `trace_id`, và chỉ số quanh thời điểm lỗi trong `contextWindow` (mặc định ±5 phút: tải CPU của DU, độ trễ hạ nguồn, lag Kafka). Trace hết hạn thì `expired = true` và chỉ trả log còn lại. Người gọi là tài khoản máy với scope `obs:diagnostics-read`, tenant lấy từ token đổi từ người dùng.

### 4.15. Bảng điều khiển và trạng thái thành phần

::: dac-ta
**Mục đích.** Dựng số liệu cho 11 loại bảng điều khiển chuẩn trong `dh-console` và trạng thái thành phần cho phân hệ khác, luôn hiển thị "Chưa có dữ liệu" thay vì 0 khi thiếu dữ liệu.

**Lớp chính.** `OverviewService`, `ComponentStatusEvaluator`, `DeploymentView`, `FlowView`, `EndpointView`, `GatewayView`, `KafkaView`, `BusinessView`, `SecurityView`, `DashboardSetSync`.

**Đơn vị chạy.** `dh-platform`, vai trò `api`; `DashboardSetSync` ở `jobs`.

**FR hiện thực.** FR-13-031…041, FR-13-058.

**Giao diện vào.** API-13-001…018, API-13-002; UI-13-01…06, UI-13-17.

**Phụ thuộc ra.** Qua `internal.query` tới Mimir, ClickHouse; `alert` (cảnh báo mở); PH-01, PH-02, PH-03 (bản sao danh sách HTTT, API); Grafana API.

**Dữ liệu.** `dashboard_set`; không lưu số liệu.

**Sự kiện.** Không.

**Lỗi và xử lý.** BR-13-016 thiếu dữ liệu: "Chưa có dữ liệu"; ERR-13-014 theo panel (panel khác vẫn hiển thị); ERR-13-004, 005, 009; ERR-13-035 bộ dashboard không hợp lệ.

**Quan sát.** `dh_obs_dashboard_duration_seconds{view}`, `dh_obs_dashboard_nodata_total{view}`, `dh_obs_dashboardsync_total{result}`.
:::

Chi tiết thiết kế:

**Nguồn dữ liệu theo màn.** Mỗi màn gọi một API tổng hợp trả JSON cho ECharts (ADR-023); các panel được tính song song và lỗi từng panel không làm hỏng cả màn.

| FR | Nguồn chính | Cách tính | Làm mới |
|---|---|---|---|
| 031 Tổng quan | Mimir (`dh:api_requests:rate1m`, `dh:api_success_ratio:5m`, `dh:gateway_latency:p95_5m`), ClickHouse MV phút, bảng `alert`, `probe` | Lượt gọi mỗi giây, tỷ lệ thành công 5 phút, p95 so vạch SLO, số HTTT đang gọi, 5 cảnh báo mới | 30 giây |
| 032 Đơn vị triển khai | Mimir (`kube_deployment_*`, `container_*` theo nhãn `deployment`) và `runtime-manifest` | Đơn vị hoạt động trên tổng, CPU, bộ nhớ, tái khởi động | 30 giây |
| 033, 034 Luồng, route, endpoint | Mimir (`dh_flow_*`, `dh_route_*` từ runtime, nhãn `flow`, `route`) | Histogram thông lượng ≥ 15 giây (Q13-15), tỷ lệ lỗi, top endpoint; điểm lỗi mở trace theo exemplar | 30 giây |
| 035 Theo API, HTTT | ClickHouse MV giờ và phút | Xếp hạng, độ trễ, lỗi; SV chỉ thấy API thuộc tổ chức mình (lọc theo `api_owner` từ PH-02) | 60 giây |
| 036, 037 Nút gateway | Mimir (`apisix_*`, `dh_connect_config_revision`) | Trạng thái đồng bộ cấu hình theo nút, CPU, heap | 30 giây |
| 038 Cụm Kafka | Mimir (exporter Strimzi) | Broker, phân vùng thiếu bản sao, lag theo nhóm | 30 giây |
| 039 Hoạt động nghiệp vụ | ClickHouse MV giờ, bản sao PH-01 | Xu hướng, xếp hạng đơn vị và dịch vụ, HTTT chưa kết nối | 5 phút |
| 040 An ninh | Loki `{tenant}-security` (đếm), Mimir, `security_alert`, `audit_chain` | Đăng nhập thất bại, từ chối, WAF, `PII.REVEAL`, cảnh báo an ninh, trạng thái chuỗi | 60 giây |

: Nguồn dữ liệu của bảng điều khiển

**`ComponentStatusEvaluator`.** Mỗi thành phần có hàm trạng thái: `NO_DATA` nếu chuỗi `up` hay chỉ số sức khỏe vắng quá 2 chu kỳ thu (không bao giờ quy về 0, BR-13-016); `DOWN` (Lỗi) nếu `up = 0` hoặc có cảnh báo `CRITICAL` mở của thành phần; `DEGRADED` (Cảnh báo) nếu có cảnh báo `WARNING` mở hoặc SLO đang đốt vượt mức; còn lại `UP` (Tốt). Kết quả đệm 15 giây phục vụ cả UI-13-01 và `ComponentHealthApi` (FR-13-058, scope `obs:health-read`). Giao diện luôn hiển thị nhãn chữ cùng màu (NFR-13-029).

**`DashboardSetSync` (FR-13-041).** Bộ dashboard chuẩn là tệp JSON trong kho cấu hình, có `set_code` và `version`. Mỗi lần đồng bộ (theo yêu cầu API-13-018 hoặc khi phiên bản bộ đổi) với từng org Grafana của tenant: dùng service account của org (token ở OpenBao), tạo hoặc cập nhật dashboard có `uid = dh-{set}-{name}` và nguồn dữ liệu cố định tiêu đề `X-Scope-OrgID`; dashboard của tenant tự tạo (không mang tiền tố `dh-`) không bị đụng tới. Người dùng tenant vào Grafana qua Keycloak OIDC, nhóm `tenant:{mã}` ánh xạ vào org tương ứng với vai trò Viewer hoặc Editor, không có vai trò quản trị server; quản trị Grafana chỉ có ở Z7 qua bastion (SEC-19). Bộ không hợp lệ (JSON sai lược đồ, thiếu `uid`) bị `ERR-13-035` trước khi gọi Grafana.

### 4.16. Luật cảnh báo, bộ luật chuẩn và runbook

::: dac-ta
**Mục đích.** Quản lý luật cảnh báo kèm runbook bắt buộc, phát hành bộ luật chuẩn của nền tảng cho mọi tenant, và đẩy luật tới Ruler của Mimir sao cho có hiệu lực trong 60 giây.

**Lớp chính.** `RuleService`, `RunbookService`, `RuleValidator`, `SeverityPolicy`, `StandardRuleCatalog`, `RulePublisher`, `RuleReconciler`.

**Đơn vị chạy.** `dh-platform`: `api` cho CRUD, `jobs` cho `RuleReconciler`.

**FR hiện thực.** FR-13-042, FR-13-043.

**Giao diện vào.** API-13-035…044; UI-13-11; ConfigMap luật chuẩn (Argo CD).

**Phụ thuộc ra.** Mimir Ruler API (`/prometheus/config/v1/rules`), Mimir truy vấn (chạy thử), `RunbookService`.

**Dữ liệu.** `alert_rule`, `runbook`.

**Sự kiện.** EVT-13-10 khi luật đổi.

**Lỗi và xử lý.** ERR-13-017 thiếu runbook, ERR-13-018 biểu thức sai, ERR-13-019 sửa luật chuẩn, ERR-13-002 mã trùng, ERR-13-041 vượt trần số luật, ERR-13-040 tham số ngoài miền.

**Quan sát.** `dh_alert_rules{scope,status}`, `dh_alert_rule_publish_seconds`, `dh_alert_rule_drift_total`.
:::

Chi tiết thiết kế:

**Kiểm tra khi lưu (`RuleValidator`).** (1) mã theo mẫu và chưa dùng, kể cả luật `RETIRED` (BR-13-031, ERR-13-002); (2) runbook đủ năm mục không rỗng (BR-13-008, ERR-13-017) và là điều kiện của cùng giao dịch ghi luật nên không có luật mồ côi; (3) biểu thức: `ExpressionGuard` (§4.13) rồi một truy vấn tức thời có thời gian chờ 5 giây tới Mimir của tenant, lỗi cú pháp trả ERR-13-018 kèm thông điệp của Mimir; (4) `SeverityPolicy` (BR-13-009): mức `CRITICAL` bắt buộc có mô tả triệu chứng `symptom`, và luật mà mọi chỉ số trong biểu thức thuộc danh mục tài nguyên thuần (`container_cpu_*`, `container_memory_*`, `node_cpu_*`, `node_memory_*`, `node_filesystem_*`, `kube_pod_container_resource_*`) chỉ được tối đa `WARNING`; việc nhận diện chỉ số bằng trích định danh trong biểu thức nên có thể sót biểu thức lắt léo, nên thống kê tỷ lệ cảnh báo giả (§4.17) là lưới an toàn thứ hai; (5) số luật của tenant không quá `13.alert.max-rules` (ERR-13-041); (6) luật `PLATFORM` không sửa, không tắt (ERR-13-019), chỉ nhân bản thành luật riêng.

**Đẩy luật tới Ruler (`RulePublisher`).** Mỗi tenant có hai nhóm luật trong Mimir (OrgID = tenant): `dh-standard` (luật chuẩn, `scope = PLATFORM`) và `dh-custom` (luật riêng). `RulePublisher` dựng nhóm từ bảng `alert_rule` và đẩy bằng `POST /prometheus/config/v1/rules/{namespace}` kèm `X-Scope-OrgID`. Mỗi luật mang `labels: {tenant, severity, rule_code, kind, group_key}` (nhãn `tenant` ghi đè mọi nhãn cùng tên từ biểu thức, nên cảnh báo luôn thuộc đúng tenant), `annotations: {summary, symptom, runbook_code}`, `for = forSeconds`, `keep_firing_for = 5m` (để cảnh báo chỉ tự đóng khi điều kiện hết liên tục 5 phút, FR-13-044 bước 4; phiên bản Mimir được chọn phải hỗ trợ tham số này, kiểm ở bộ kiểm thử tích hợp). Chu kỳ đánh giá mặc định `13.alert.eval-interval-seconds` (30 giây). Ruler đọc kho luật mỗi 10 giây nên luật có hiệu lực trong 60 giây kể từ lúc lưu (NFR-13-030). `RuleReconciler` mỗi 5 phút so băm nhóm luật trong Mimir với bảng và sửa lệch (đếm `dh_alert_rule_drift_total`), nên Ruler mất dữ liệu vẫn tự lành.

**Bộ luật chuẩn (`StandardRuleCatalog`).** Nguồn sự thật là kho Git cấu hình (`rules/platform/*.yaml` kèm runbook Markdown năm mục), Argo CD triển khai thành ConfigMap `obs-standard-rules` gắn vào pod qua volume. Catalog theo dõi thay đổi tệp, so băm, nạp vào `alert_rule` (`scope = PLATFORM`) với `source_revision` lấy từ chú thích ConfigMap, thay biến mẫu bằng tham số của tenant (`13.slo.data-plane-availability`, `13.slo.gateway-latency-p95-ms`) rồi nhân bản cho từng tenant đang hoạt động qua `RulePublisher`. 26 luật chuẩn của FR-13-043 gồm nhóm SLO (`slo-data-plane-burn-fast`, `slo-data-plane-burn-slow`, `slo-data-plane-burn-ticket`, `slo-control-plane-burn`, `slo-gateway-latency`, `slo-event-latency`, `slo-token`), hạ tầng (`pg-no-sync-standby`, `dr-replication-lag`, `kafka-under-min-isr`, `kafka-lag-dataplane`, `openbao-sealed`, `quorum-member-lost`, `volume-capacity`, `cert-expiry`, `gateway-config-skew`, `backup-failed`, `pod-crashloop`, `netpol-anomaly`), kiểm toán (`audit-chain-verify-failed`, `audit-worm-lag`, `audit-outbox-backlog`, `audit-reconcile-mismatch`), quan sát (`probe-failed`, `obs-ingest-dropped`) và `payment-provider-connection-error`. Luật tốc độ tiêu hao đa cửa sổ dùng hai cửa sổ ghép bằng `and` (1 giờ với 5 phút; 6 giờ với 30 phút) theo D03-09 §9.2. Mỗi lần phiên bản đổi, catalog ghi `ALERT.RULE.UPDATE` với chủ thể `system:argocd` kèm mã commit trong `after.gitRevision` và phát EVT-13-10; mã luật chuẩn không bao giờ dùng lại. CI của kho cấu hình chạy `promtool check rules`, kiểm runbook đủ năm mục và kiểm mỗi luật `CRITICAL` có `symptom`.

### 4.17. Vòng đời cảnh báo

::: dac-ta
**Mục đích.** Biến cảnh báo của Ruler và Alertmanager thành đối tượng có vòng đời trong `dh-platform`: sinh, phân mức, gom nhóm, xác nhận, tạm ẩn, đóng, và thống kê hiệu quả, bảo đảm xử lý lũy đẳng khi Alertmanager gửi lặp.

**Lớp chính.** `AlertWebhookHandler`, `AlertStateMachine`, `GroupingPolicy`, `SilenceService`, `AlertService`, `AlertStatsService`.

**Đơn vị chạy.** `dh-platform`, vai trò `api` (webhook, thao tác người dùng) và `jobs` (thống kê, đóng tự động).

**FR hiện thực.** FR-13-044, 045, 047, 050.

**Giao diện vào.** API-13-090 `POST /internal/alertmanager:webhook` (mTLS); API-13-030…034, 052; UI-13-10.

**Phụ thuộc ra.** Alertmanager API v2 (`/api/v2/silences`), `NotificationService` (§4.18), `audit` qua `dh-audit`.

**Dữ liệu.** `alert`, `alert_action`.

**Sự kiện.** EVT-13-01 (FIRING), EVT-13-02 (RESOLVED), EVT-13-03 (leo thang).

**Lỗi và xử lý.** ERR-13-020 trạng thái không áp dụng, ERR-13-021 tạm ẩn sai, ERR-13-022 đóng thiếu nguyên nhân, ERR-13-007 sai phiên bản, ERR-13-119 luật đánh giá lỗi; webhook lỗi thì trả `5xx` để Alertmanager gửi lại.

**Quan sát.** `dh_alert_open{severity}`, `dh_alert_webhook_total{result}`, `dh_alert_mtta_seconds`, `dh_alert_mttr_seconds`, `dh_alert_eval_failures_total`.
:::

Chi tiết thiết kế:

**Webhook lũy đẳng (API-13-090).** Alertmanager gửi lô tối đa 100 cảnh báo (định dạng webhook v4). `AlertWebhookHandler` kiểm chứng thư mTLS của người gọi (SPIFFE ID của Alertmanager, SEC-15), rồi với mỗi cảnh báo: khóa tự nhiên `(tenant, rule_code, fingerprint)`; trạng thái `firing` mà chưa có bản ghi mở thì tạo `FIRING` và phát EVT-13-01, có rồi thì chỉ cập nhật nhãn, `summary`; `resolved` thì chuyển `RESOLVED` với `resolution = AUTO` và phát EVT-13-02; `firing` đến khi bản ghi đang `SILENCED` mà `silence_until` đã qua thì chuyển về `FIRING` (đúng sơ đồ §8.1). Phản hồi `200` chỉ sau khi giao dịch cam kết; lỗi cơ sở dữ liệu trả `503` để Alertmanager gửi lại giãn dần, nên không mất cảnh báo. Webhook không kiểm quyền người dùng mà kiểm danh tính máy; `tenant` lấy từ nhãn do Ruler đóng (BR-13-027), không từ nội dung do luật tự khai, và cảnh báo thiếu nhãn bị bỏ và đếm.

**Gom nhóm và chống lặp (BR-13-009).** Cấu hình Alertmanager (một cấu hình toàn cục) dùng `group_by: [tenant, rule_code, severity, group_key]` nên hai mươi pod cùng một lỗi (khác nhau ở nhãn `pod`) thành một nhóm một thông báo; `group_wait = 10s`, `group_interval = 2m`, `repeat_interval = 168h` để cảnh báo đang mở không gửi lại (việc nhắc lại do leo thang của `dh-platform` đảm nhiệm). Quy tắc ức chế: cảnh báo `CRITICAL` ức chế cảnh báo `WARNING` cùng `tenant` và `group_key`. `GroupingPolicy` ở `dh-platform` thêm chống bão: nếu có hơn 50 cảnh báo mới trong 5 phút (cửa sổ trượt trong Valkey) thì gộp thành một thông báo tổng hợp "Có {n} cảnh báo mới trong 5 phút" và chỉ giữ gửi riêng các cảnh báo `CRITICAL`.

**Thao tác người dùng (FR-13-047).** Mỗi thao tác kiểm tra `If-Match` (ERR-13-007), quyền (`PERM-13-alert-ack`, ERR-13-009) và trạng thái hợp lệ (ERR-13-020) trong aggregate, rồi ghi `alert_action` và bản ghi kiểm toán trong cùng giao dịch. `acknowledge` dừng bộ đếm leo thang. `resolve` yêu cầu nguyên nhân, hành động, kết quả `FIXED`, `NO_ACTION` hoặc `EXTERNAL` (ERR-13-022). `silence` yêu cầu hạn và lý do, tối đa `13.alert.silence-max-days` (7), tối đa 24 giờ cho `CRITICAL` (ERR-13-021); `SilenceService` tạo silence ở Alertmanager với bộ so khớp `tenant`, `rule_code`, `fingerprint` và lưu `silenceId` trong `alert_action`; huỷ khi cảnh báo đóng sớm. Xác nhận hàng loạt trong danh sách lặp lại từng cảnh báo trong một giao dịch mỗi cảnh báo để một cảnh báo lỗi không hủy cả lô.

**Đóng tự động.** Luật `DISABLED` hoặc `RETIRED` thì `AlertService.closeAllFor(rule)` đóng mọi cảnh báo mở của luật với `AUTO`. Điều kiện hết khi đang `SILENCED` thì đóng theo `resolved` từ webhook.

**Thống kê hiệu quả (FR-13-050).** `AlertStatsService` tính theo luật bằng SQL trên `alert` và `alert_action`: số lần phát, số lần leo thang, MTTA (từ `started_at` tới `ACK` đầu tiên), MTTR (tới `RESOLVED`), tỷ lệ cảnh báo giả = (đóng với `NO_ACTION` cộng bị tạm ẩn) chia tổng đã đóng. Kết quả đệm 5 phút.

### 4.18. Thông báo, lịch trực và leo thang

::: dac-ta
**Mục đích.** Gửi cảnh báo đến đúng người trực ở đúng kênh, thử lại và chuyển kênh dự phòng khi thất bại, leo thang khi không ai xác nhận, và bảo đảm cảnh báo Nghiêm trọng có đường gửi độc lập với hạ tầng của site.

**Lớp chính.** `NotificationService`, `NotificationDispatcher`, `OnCallResolver`, `ChannelRegistry`, `EscalationScheduler`, `ScheduleValidator`; ngoài Java: `alert-relay` (Deployment nhỏ ở `dh-obs`).

**Đơn vị chạy.** `dh-platform` (`jobs` cho bộ gửi và leo thang, `api` cho CRUD); `alert-relay` ở Z7.

**FR hiện thực.** FR-13-046, FR-13-048.

**Giao diện vào.** Sự kiện nội bộ của `AlertService`; API-13-045…051 (lịch, nhóm, kênh, kiểm tra kênh); UI-13-12.

**Phụ thuộc ra.** `NotificationApi` của PH-18 (thư, SMS, trong ứng dụng, GĐ-13-06), webhook của tenant, `alert-relay`, OpenBao (bí mật kênh).

**Dữ liệu.** `oncall_schedule`, `notification_channel`, `alert_notification`.

**Sự kiện.** EVT-13-03 khi leo thang.

**Lỗi và xử lý.** ERR-13-120 gửi thất bại, ERR-13-121 leo thang hết cấp, ERR-13-033 kiểm tra kênh thất bại, ERR-13-034 lịch hở, chồng ca hoặc nhóm Nghiêm trọng thiếu đường độc lập, ERR-13-014 khi PH-18 không khả dụng.

**Quan sát.** `dh_alert_notifications_total{channel,result}`, `dh_alert_notify_latency_seconds`, `dh_alert_escalations_total{level}`.
:::

Chi tiết thiết kế:

**Chọn người nhận và kênh.** `OnCallResolver.resolve(group, instant)` đọc `rotation` (JSON các ca: thứ trong tuần, giờ bắt đầu, giờ kết thúc, người theo cấp 1, 2, 3) theo múi giờ của lịch (`Asia/Ho_Chi_Minh`); tenant chưa có lịch thì gửi nhóm TA mặc định và giao diện nhắc cấu hình. Kênh theo mức (BR-13-028): `CRITICAL` gửi SMS, thư và trong ứng dụng cùng lúc; `WARNING` gửi thư và trong ứng dụng, chỉ trong giờ hành chính (`13.office-hours`), ngoài giờ thì giữ tới giờ mở; `INFO` chỉ trong ứng dụng. Thư và SMS chỉ chứa mã cảnh báo, mức, tóm tắt và liên kết, không chứa dữ liệu (FR-00-062).

**Gửi và thử lại.** `NotificationService` ghi `alert_notification` trạng thái `PENDING` trong cùng giao dịch với việc sinh cảnh báo (nên không mất thông báo khi tiến trình chết), `NotificationDispatcher` lấy việc bằng `FOR UPDATE SKIP LOCKED` và gửi theo bộ chuyển kênh: `EmailChannel` và `SmsChannel` qua PH-18; `WebhookChannel` POST HTTPS có chữ ký `webhook-signature` theo SEC-47 tới FQDN nằm trong danh sách cho phép của cổng thoát (SEC-16) và qua bộ kiểm SSRF; `InAppChannel` đẩy vào trung tâm thông báo (FR-00-060). Thất bại thì thử lại sau 30 giây, 2 phút, 10 phút rồi chuyển kênh dự phòng (ERR-13-120, hiển thị cho PA, TA ở UI-13-12). Bí mật kênh nằm ở OpenBao (`secret_ref`), chỉ bộ gửi đọc.

**Leo thang (BR-13-022).** `EscalationScheduler` chạy mỗi 30 giây, chọn cảnh báo `CRITICAL` ở `FIRING` chưa xác nhận mà `now − started_at` đã tới ngưỡng của cấp kế (`13.alert.escalate-minutes` = `15,30`), cập nhật có điều kiện `UPDATE alert SET escalation_level = :l + 1 WHERE id = :id AND escalation_level = :l AND status = 'FIRING'` (một bản sao thắng, không gửi đôi), gửi thêm cho người cấp trên, phát EVT-13-03. Xác nhận chạy sau đó làm điều kiện cập nhật thất bại và dừng chuỗi. Hết cấp 3 mà chưa ai xác nhận: ERR-13-121 gửi PA, TA qua kênh độc lập.

**Lịch hợp lệ (ERR-13-034).** `ScheduleValidator` mô phỏng 168 giờ của tuần: không giờ nào thiếu người ở cấp 1 với nhóm có luật `CRITICAL`, không ca chồng cùng cấp, và nhóm nhận mức `CRITICAL` có từ hai kênh khác loại với ít nhất một kênh đánh dấu `external` (SMS qua nhà mạng, Q13-16) độc lập với hạ tầng site (D03-09 §9.2).

**Kênh độc lập (`alert-relay`).** Alertmanager có hai receiver cho `severity = CRITICAL`: webhook về `dh-platform` (vòng đời, lịch trực, leo thang) và `alert-relay` (route `continue: true`). `alert-relay` là dịch vụ không trạng thái, hai bản sao ở `dh-obs`, đổi webhook thành lời gọi API nhà cung cấp SMS và SMTP bằng bí mật riêng ở OpenBao, không dùng PH-18, `pg-core` hay Kafka; nên `dh-platform` ngừng thì cảnh báo `CRITICAL` vẫn tới người trực (NFR-13-013). Giá thành là thông báo có thể tới hai đường; thư và SMS mang cùng mã cảnh báo nên người nhận nhận biết trùng.

### 4.19. Giám sát chính hệ thống giám sát

::: dac-ta
**Mục đích.** Phát hiện khi chính hệ giám sát hỏng (Ruler, Alertmanager, Collector, kho đầy) bằng nhịp tim ngoài site và các chỉ số tự giám sát, vì một hệ giám sát im lặng là nguy hiểm hơn một hệ báo sai.

**Lớp chính.** `MonitoringHealthService`, `CapacityWatcher`, `HeartbeatContract`; luật `Watchdog` và `monitoring-down`.

**Đơn vị chạy.** `dh-platform` vai trò `jobs` và `api`; bộ nhận nhịp tim ngoài cụm.

**FR hiện thực.** FR-13-049.

**Giao diện vào.** Alertmanager gửi `Watchdog` mỗi phút; API-13-053 `GET /monitoring-health`; UI-13-01.

**Phụ thuộc ra.** Mimir (org `PLATFORM`), bộ nhận nhịp tim, `alert-relay`.

**Dữ liệu.** Không có bảng riêng; trạng thái đệm 15 giây.

**Sự kiện.** EVT-13-14 khi kho hay số chuỗi đạt 85%.

**Lỗi và xử lý.** Mất nhịp tim quá 3 phút: cảnh báo `CRITICAL` qua kênh độc lập; ERR-13-123 kho đạt 85%; chỉ số tự giám sát thiếu: "Chưa có dữ liệu" kèm ERR-13-014.

**Quan sát.** `dh_obs_monitoring_state` (0 tốt, 1 giảm sút, 2 lỗi), `dh_obs_store_usage_ratio{store}`, `dh_obs_heartbeat_age_seconds`.
:::

Chi tiết thiết kế:

**Nhịp tim.** Luật `Watchdog` (`vector(1)`) luôn thỏa. Route riêng của Alertmanager gửi nó mỗi phút (`repeat_interval = 1m`) tới bộ nhận ngoài cụm theo hợp đồng `HeartbeatContract`: `POST` có thân JSON `{site, time}` và token bearer; bộ nhận phát cảnh báo `monitoring-down` qua kênh độc lập khi quá 3 phút không có nhịp. Hồ sơ `HT-B` dùng bộ nhận do nhà cung cấp nền tảng vận hành; `HT-A` đặt bộ nhận ở một vị trí ngoài site của chủ quản (Q13-24). Kiểm tra tổng hợp (§4.12) bổ sung góc nhìn từ ngoài vào.

**Trạng thái tự giám sát.** `MonitoringHealthService` mỗi 15 giây tính từ chỉ số tự giám sát của org `PLATFORM`: `Tốt`; `Giảm sút` khi có dữ liệu bị bỏ (`otelcol_processor_dropped_*`, `dh_obs_access_dropped_total`) hoặc kho trên 80%; `Lỗi` khi Ruler (`cortex_ruler_rule_evaluation_failures_total` tăng, không có đánh giá trong 2 chu kỳ) hoặc Alertmanager (`alertmanager_notifications_failed_total` tăng, mất đa số bản sao) hỏng; thiếu chỉ số thì `NO_DATA`. `CapacityWatcher` mỗi 5 phút đọc mức dùng từng kho (Mimir, Loki, Tempo, ClickHouse, volume `pg-core`, bucket WORM) và số chuỗi hoạt động trên hạn mức từng tenant (`cortex_ingester_active_series` theo `user`); từ 85% phát ERR-13-123 và EVT-13-14 (PH-20 nhận để xem xét nâng hạn mức).

### 4.20. Phát hiện bất thường an ninh

::: dac-ta
**Mục đích.** Nạp bộ 25 luật phát hiện UC-SEC của D03-07 §7.5, cho cán bộ ATTT tinh chỉnh ngưỡng trong biên cho phép, phát hiện bất thường từ bản ghi kiểm toán trong 5 phút, và xử lý cảnh báo an ninh tới khi có kết luận.

**Lớp chính.** `DetectionRuleCatalog`, `DetectionEngine`, `SecurityAlertService`, `SuspensionProposer`, `IncidentReportGenerator` (Đợt sau).

**Đơn vị chạy.** `dh-platform`, vai trò `jobs` (engine) và `api` (xử lý).

**FR hiện thực.** FR-13-051, 052, 053, 055.

**Giao diện vào.** Lịch mỗi phút; API-13-054…060, 065, 066; UI-13-15.

**Phụ thuộc ra.** `AuditDetectionQueryApi` (§3.4), Alertmanager API v2 (`POST /api/v2/alerts`), Mimir Ruler (luật theo chỉ số và log), PH-01 (qua API-01-089).

**Dữ liệu.** `detection_rule`, `security_alert`, `detect_cursor`, `incident_report`.

**Sự kiện.** EVT-13-04.

**Lỗi và xử lý.** ERR-13-024 ngưỡng ngoài biên hoặc luật không tắt được, ERR-13-023 đóng thiếu kết luận, ERR-13-119 truy vấn phát hiện lỗi hoặc trễ quá 5 phút, ERR-13-028 thiếu xác thực lại, ERR-13-014; bản ghi thiếu trường cần cho luật thì bỏ qua và đếm `dh_detect_skipped_total`.

**Quan sát.** `dh_detect_run_duration_seconds{rule}`, `dh_detect_alerts_total{rule,severity}`, `dh_detect_skipped_total`, `dh_detect_lag_seconds`.
:::

Chi tiết thiết kế:

**Hai kiểu luật.** `DetectionRuleCatalog` nạp 25 luật từ tệp bất biến cùng ảnh, mỗi luật có `source`, ngưỡng mặc định, `threshold_limit`, mức, `can_disable`. Hai nhóm hiện thực:

| Nhóm | UC-SEC | Hiện thực |
|---|---|---|
| Theo chỉ số, log, sự kiện hạ tầng | 01 đến 09, 13, 15 đến 19, 21 đến 24 | Luật Mimir hoặc Loki Ruler nhãn `kind = security`, `rule_code = UC-SEC-nn`; ngưỡng lấy từ `detection_rule.threshold` và đẩy bằng `RulePublisher` (§4.16); log an ninh ở org `{tenant}-security` |
| Theo bản ghi kiểm toán | 10, 11, 12, 14, 25 và hai luật phụ "truy cập Nhạy cảm ngoài giờ", "từ chối tăng đột biến" | `DetectionEngine` (dưới đây) |
| Đứt chuỗi | 20 | `BreakHandler` (§4.7) phát thẳng, không qua truy vấn |

: Hiện thực hai nhóm luật phát hiện

**`DetectionEngine`.** Mỗi phút, với từng tenant và từng luật theo bản ghi kiểm toán, engine gọi `AuditDetectionQueryApi.run` với truy vấn có tên (`COUNT_DISTINCT_KEY_BY_SOURCE` cho UC-SEC-10, `COUNT_ACTION_BY_ACTOR` cho UC-SEC-11, `SUM_ROWCOUNT_BY_ACTOR` cho UC-SEC-12, `SUM_REFUND_OFFHOURS` cho UC-SEC-14, `CROSS_TENANT_EVENTS` cho UC-SEC-25, `OFFHOURS_SENSITIVE`, `DENIED_SPIKE`), chỉ đọc trên phân vùng nóng, không nhận SQL tự do và có hạn thời gian 10 giây. Kết quả vượt ngưỡng tạo hoặc cập nhật `security_alert` gom theo (luật, chủ thể) trong 1 giờ; bằng chứng là tối đa 100 `audit_id` cùng số đếm và khoảng thời gian, không có dữ liệu gốc. Cảnh báo được đẩy vào Alertmanager với `kind = security` để thông báo SO theo FR-13-046 (mức `CRITICAL` tới SO ngay, tới TA sau 15 phút nếu chưa tiếp nhận), đẩy sang SIEM và phát EVT-13-04. `detect_cursor(tenant, rule, processed_until)` giữ mốc đã xử lý; sau khi gián đoạn, engine chạy bù theo bước 5 phút từ mốc đó (tối đa 24 giờ) nên không bỏ cửa sổ nào. Giờ hành chính lấy từ `13.office-hours`.

**Tinh chỉnh ngưỡng (FR-13-051).** `PATCH /detection-rules/{ruleCode}` cần `PERM-13-security`, xác thực lại phiên, lý do; ngưỡng mới phải nằm trong `threshold_limit` (nới tối đa 2 lần mặc định, siết tự do, BR-13-025); luật `can_disable = false` (mức Nghiêm trọng kiểu "mọi sự kiện") không tắt, không đổi ngưỡng (ERR-13-024). Thay đổi ghi `SECURITY.RULE.TUNE` với giá trị trước, sau và phát EVT-13-10; luật theo chỉ số đến Ruler trong 60 giây.

**Xử lý cảnh báo an ninh (FR-13-053).** `SecurityAlertService` thực thi máy trạng thái §8.1: `acknowledge` ghi `assignee`; `close` bắt buộc `verdict` ∈ `CONFIRMED_INCIDENT`, `FALSE_POSITIVE`, `ACCEPTED_RISK` (có ghi chú, ERR-13-023). `SuspensionProposer` kiểm cảnh báo ở mức `HIGH` hoặc `CRITICAL` (thấp hơn: ERR-13-003, nút đề xuất ẩn ở UI-13-15), kiểm HTTT thuộc tenant, ghi lý do, lấy `alertId`, `severity`, `incidentRef`, `evidenceUrl` từ cảnh báo gốc rồi gọi API-01-089 của PH-01 (thời gian chờ 3 giây, lỗi thì ERR-13-014 và đề xuất chưa gửi, SO thử lại; lũy đẳng theo `alertId` nên thử lại không tạo việc thứ hai; ERR-01-048 coi là đã đáp ứng, ERR-01-005 báo người dùng HTTT không ở trạng thái cho phép tạm ngừng); PH-13 chỉ đề xuất, SO ở PH-01 quyết định bằng thao tác khẩn FR-01-032 (Q13-12, đã chốt 27/11/2026). Kết luận "sự cố thật" gắn `incidentRef` của quy trình ứng cứu (D03-07 §8). `SECURITY.ALERT.PROPOSE_SUSPENSION` được thêm vào bảng hành động phải ghi kiểm toán (đề nghị đồng bộ FR-13-019).

**Báo cáo sự cố (FR-13-055, Đợt sau).** `IncidentReportGenerator` dựng bản nháp từ mẫu và bằng chứng của cảnh báo, đếm ngược 72 giờ từ `detected_at` cho `DLCN_BREACH` và nhắc ở 24, 48, 60 giờ qua `NotificationService`; việc gửi cho cơ quan do chủ quản thực hiện ngoài hệ thống (Q13-10). Cờ `obs.incident-report.enabled` tắt ở MVP.

### 4.21. Xuất log và cảnh báo an ninh sang SIEM, SOC

::: dac-ta
**Mục đích.** Đẩy log an ninh, cảnh báo an ninh và neo kiểm toán sang SIEM hoặc SOC của tỉnh và quốc gia, đã loại dữ liệu cá nhân, trong 5 phút, không mất khi SIEM tạm ngừng.

**Lớp chính.** `SiemTargetService`, `SiemPipelineRenderer`, `SiemEventForwarder`, `SiemHealthProbe`; ngoài Java: Deployment `otel-siem` (2 bản sao ở `dh-obs`).

**Đơn vị chạy.** `dh-platform` (`api`, `jobs`); `otel-siem` ở Z7.

**FR hiện thực.** FR-13-054.

**Giao diện vào.** API-13-061…064; UI-13-17 (tab Mục tiêu SIEM).

**Phụ thuộc ra.** `otel-siem` (syslog RFC 5424 trên TLS hoặc OTLP), danh sách FQDN cho phép ở cổng thoát (SEC-16).

**Dữ liệu.** `siem_target`; hàng đợi đĩa của `otel-siem`.

**Sự kiện.** Tiêu thụ EVT-13-04, 05, 06, 12.

**Lỗi và xử lý.** ERR-13-039 mục tiêu không hợp lệ hoặc không kết nối được; ERR-13-122 SIEM không nhận (hàng đợi đĩa, cảnh báo `WARNING` sau 15 phút); hàng đợi đầy: bỏ sự kiện mức thấp trước, giữ cảnh báo và neo.

**Quan sát.** `dh_siem_sent_total{target,result}`, `dh_siem_queue_bytes{target}`, `dh_siem_delay_seconds{target}`.
:::

Chi tiết thiết kế:

**Tách `otel-siem`.** Bộ xuất SIEM không nằm trong gateway chính (FRS §2.4 ghi "Collector gateway") mà là một Deployment riêng, vì thêm hay đổi mục tiêu SIEM phải cuộn lại cấu hình; tách ra thì cuộn `otel-siem` không chạm tuyến thu thập chính. Gateway chính chuyển bản sao log an ninh sang `otel-siem` bằng OTLP; `SiemEventForwarder` đẩy cảnh báo an ninh, neo, đứt chuỗi, phiên liên tenant (từ sự kiện nội bộ) dưới dạng bản ghi log OTLP có `dh.siem.kind`.

**Thêm mục tiêu (FR-13-054 bước 1 đến 2).** `SiemTargetService` kiểm giao thức (`SYSLOG_TLS` hoặc `OTLP`), lược đồ (`ECS` hoặc `OCSF`), địa chỉ nằm trong danh sách FQDN cho phép của cổng thoát (danh sách sinh từ Git, đọc được qua API nội bộ; chưa có thì ERR-13-039 kèm hướng dẫn thêm `ServiceEntry` qua PR vào kho cấu hình), chứng thư hợp lệ; rồi `SiemPipelineRenderer` dựng pipeline cho tenant ở `otel-siem` và cuộn lại cấu hình. Điểm xuất `purpose = AUTHORITY` (cơ quan chuyên trách, SEC-66) tắt mặc định và chỉ bật bởi PA hoặc TA kèm số hiệu văn bản yêu cầu lưu ở `filter.basisRef`; mọi thay đổi ghi kiểm toán và sẵn sàng bật trong 5 ngày làm việc (BR-13-034).

**Ánh xạ và lọc.** Bộ xử lý `transform` ánh xạ sang trường chuẩn (`event.category`, `event.action`, `user.id`, `source.ip`, `tenant`, `trace_id` với ECS; tương đương với OCSF) và bộ lọc loại trường dữ liệu cá nhân, nội dung Nhạy cảm theo danh sách khóa cho phép (SEC-66); độ trễ tới SIEM ≤ 5 phút (SEC-63). Hàng đợi đĩa bền tối đa `13.siem.queue-max-mb` (1.024 MB); đầy thì bỏ mức thấp trước, và bỏ bản ghi Nghiêm trọng kích hoạt cảnh báo `CRITICAL`. `SiemHealthProbe` gửi sự kiện thử khi bấm "Kiểm tra kết nối" và đo độ trễ ghi nhận mỗi 5 phút. Neo ghi `siem_ack_at` ở bảng `audit_anchor_publish` khi SIEM xác nhận. Tỉnh chưa có SIEM: hồ sơ `siem = builtin` bật bảng điều khiển an ninh (FR-13-040) và luật UC-SEC trên Loki, Alertmanager, tùy chọn Wazuh, kèm khuyến nghị hiển thị ở UI-13-17. Dùng chung nền tảng (`HT-B`): SOC của nhà cung cấp nhận luồng toàn nền tảng, mỗi tỉnh nhận luồng đã lọc theo tenant (D03-07 §7.4).

### 4.22. Khởi tạo, đóng chuỗi tenant, tham số và hạn mức

::: dac-ta
**Mục đích.** Dựng toàn bộ quan sát và chuỗi kiểm toán cho tenant mới một cách lũy đẳng trong saga của PH-20, đóng chuỗi khi tenant ngừng hay sáp nhập, và quản lý tham số `13.*` cùng hạn mức theo tenant với hiệu lực nhanh.

**Lớp chính.** `ObsProvisioner`, `OverridesReconciler`, `CollectorConfigRenderer`, `TenantObsConfigService`, `QuotaService`, `LifecycleCloser`, `SettingsService`, `ParameterGuard`.

**Đơn vị chạy.** `dh-platform`: `api` cho API, `jobs` cho bộ đối soát.

**FR hiện thực.** FR-13-059, 060, 061.

**Giao diện vào.** `TenantObservabilityApi` (trong tiến trình), API-13-072, 073 (REST, scope `obs:tenant-provision`); API-13-070, 071 `GET`, `PATCH /settings`; UI-13-17.

**Phụ thuộc ra.** `AuditChainAdminApi`, OpenBao, API cấp phát topic của PH-10, Grafana, Kubernetes API (ConfigMap overrides), Mimir Ruler.

**Dữ liệu.** `tenant_obs_config` (tham số, hạn mức, `provision_state`), `audit_chain`.

**Sự kiện.** EVT-13-10 khi tham số hay luật đổi; EVT-13-14 khi sắp hết hạn mức.

**Lỗi và xử lý.** ERR-13-042 tham số khác với cấu hình đã có, ERR-13-043 chuỗi đã đóng, ERR-13-014 một bước phụ thuộc lỗi (PH-20 thử lại), ERR-13-040 tham số ngoài miền, ERR-13-041 vượt trần nền tảng, ERR-13-044 thiếu scope, ERR-13-016 tenant tạm ngừng.

**Quan sát.** `dh_obs_provision_total{result}`, `dh_obs_provision_step_seconds{step}`, `dh_obs_settings_changes_total`.
:::

Chi tiết thiết kế:

**Khởi tạo lũy đẳng (FR-13-059).** `ObsProvisioner.provision` nhận `Idempotency-Key` và tham số (`scale` ∈ hồ sơ quy mô). Mỗi bước ghi trạng thái vào `provision_state` của `tenant_obs_config` (sổ bước) nên gọi lại với cùng khóa chạy tiếp từ bước dang dở, gọi với tham số khác trả ERR-13-042.

| Bước | Việc | Đồng bộ |
|---|---|---|
| S1 | `AuditChainAdminApi.provision`: `audit_chain` với `genesis_hash = SHA-256("genesis:" ‖ mã ‖ thời điểm ‖ nonce)`, phân vùng tháng hiện tại và 3 tháng sau, khóa HMAC `dh-{tenant}-audit-hmac` ở OpenBao, tệp `audit/{tenant}/_genesis.json` ghi vào WORM (giữ bằng chứng điểm khởi đầu) | Có |
| S2 | Tạo topic `{tenant}.obs.audit.recorded.v1`, `{tenant}.obs.access.logged.v1` và ACL cho DU nguồn qua cấp phát của PH-10 (ADR-072); đợi trạng thái sẵn sàng tối đa 60 giây | Có |
| S3 | Overrides của Mimir, Loki, Tempo (hạn mức theo `scale`), chính sách dòng ClickHouse, tuyến Collector cho tenant | Cuộn gateway chạy nền |
| S4 | Tổ chức Grafana, nguồn dữ liệu cố định OrgID, ánh xạ nhóm `tenant:{mã}`, đồng bộ bộ dashboard chuẩn (§4.15) | Có |
| S5 | Nhân bản luật chuẩn (§4.16), nạp bộ luật UC-SEC, lịch trực mặc định gán TA, kênh trong ứng dụng, kiểm tra tổng hợp mặc định | Có |
| S6 | Ghi tham số `13.*` mặc định theo `scale`, đặt `provisioned_at` | Có |

: Sổ bước khởi tạo quan sát của tenant

Bước S2 hay S4 lỗi thì trả ERR-13-014 để saga PH-20 thử lại hoặc bù trừ; các bước đã xong được giữ và chạy lại lũy đẳng. Bước S3 vừa ghi ConfigMap vừa cuộn gateway nên dữ liệu của tenant mới tới Collector trong 2 đến 3 phút sau và trong thời gian đó được gán `_unattributed` (không mất, chỉ nền tảng thấy). Nếu phiên bản Collector chọn hỗ trợ đặt OrgID động theo thuộc tính của dữ liệu thì bỏ được việc dựng lại tuyến và cuộn lại (Q13-26). Tenant `PLATFORM` được khởi tạo bằng cùng đường khi dựng nền tảng.

**Overrides và hạn mức.** Nguồn sự thật là bảng `tenant_obs_config`. `OverridesReconciler` sinh ConfigMap `obs-tenant-overrides` (bộ khung nằm trong Git với `ignoreDifferences` trên `.data` để Argo CD không coi là lệch) gồm `max_global_series_per_user = 13.series.max-active`, hạn mức tốc độ nhận log và trace theo `scale`, `retention_period` của Loki (90 ngày; org an ninh 365 ngày) và Tempo (14 ngày); Mimir, Loki, Tempo nạp lại runtime config mỗi 10 giây. Bộ đối soát chạy khi tham số đổi và mỗi 5 phút để tự lành. Hạn mức của tenant không vượt trần của PA (ERR-13-041).

**Tham số `13.*` (FR-13-061).** `SettingsService` kiểm miền và phạm vi sửa của từng khóa (P chỉ PA, T cho TA trong trần của PA; ERR-13-040 khi ngoài miền hoặc thời hạn lưu kiểm toán dưới 3 năm), kiểm `If-Match`, ghi `tenant_obs_config`, ghi `OBS.SETTINGS.UPDATE` kèm giá trị trước và sau (BR-13-006) và phát EVT-13-10. Mỗi bản sao giữ tham số trong bộ nhớ đệm 30 giây và hủy đệm khi nhận EVT-13-10, nên luật, ngưỡng, tham số vận hành có hiệu lực trong 60 giây (NFR-13-030). Tham số tác động tới Collector (`13.trace.success-sample-percent`, `13.trace.slow-percentile`, `13.metrics.scrape-interval-seconds`) có hiệu lực sau khi cuộn gateway, tối đa khoảng 3 phút: đây là sai lệch có chủ ý so với NFR-13-030 và được ghi ở Q13-26. Tenant đang tạm ngừng chỉ đọc (ERR-13-016).

**Đóng chuỗi (FR-13-060, Đợt sau).** `LifecycleCloser.close`: kiểm chuỗi `OPEN` (ERR-13-043 nếu đã đóng); ghi bản ghi `CHAIN.CLOSE` với lý do vào chính chuỗi; ký neo cuối `final = true` như §4.5; đặt `status = CLOSED`, `closed_at`, `closed_reason`, `merged_into`. Chuỗi đóng vẫn tra cứu, kiểm tra toàn vẹn, xuất bằng chứng trong thời hạn lưu; không gộp vật lý chuỗi nguồn vào chuỗi đích (giao diện tenant đích có mục "Lịch sử của tenant nguồn" truy vấn chuỗi đóng). Cờ `obs.chain.close.enabled` tắt ở MVP.

## 5. Biểu đồ tuần tự

Mười sơ đồ dưới đây phủ các FR phức tạp, nhiều thành phần hoặc có sao lưu và khôi phục. Mỗi sơ đồ có một đoạn thuyết minh nêu điều người đọc cần thấy; thông điệp không dùng dấu chấm phẩy.

### 5.1. Ghi một thao tác kiểm toán từ DU tới chuỗi, neo và WORM (FR-13-010, 011, 012, 013)

Luồng chính của đường kiểm toán: từ thao tác của người dùng ở một DU tới bản ghi nằm trong chuỗi, có neo ký và bản sao WORM.

```{.mermaid caption="Ghi một thao tác kiểm toán từ DU tới chuỗi, neo và WORM (FR-13-010, 011, 012, 013)"}
sequenceDiagram
  autonumber
  actor US as Người dùng
  participant DU as DU nguồn dh-data
  participant DB as CSDL của DU
  participant RL as OutboxRelay
  participant KF as Kafka
  participant IN as Bộ tiếp nhận PH-13
  participant CW as ChainWriter
  participant PG as ph13_audit
  participant AN as AnchorService
  participant OB as OpenBao
  participant WM as Kho WORM
  US->>DU: Phát hành phiên bản danh mục
  DU->>DB: BEGIN, đổi trạng thái, INSERT audit_outbox, tăng bộ đếm, COMMIT
  DU-->>US: 200
  RL->>DB: Lấy lô FOR UPDATE SKIP LOCKED
  RL->>KF: Gửi acks=all kèm dh-du, dh-mac
  KF-->>RL: Xác nhận
  RL->>DB: Đặt published_at
  KF->>IN: Lô tối đa 500 bản ghi của t68
  IN->>IN: Kiểm mac, lược đồ, tenant, trùng, quét Nhạy cảm
  IN->>CW: append lô hợp lệ
  CW->>PG: BEGIN, khóa tư vấn t68, đọc head
  CW->>CW: Gán seq, dựng JCS, tính hash
  CW->>PG: INSERT lô, UPDATE head có điều kiện, COMMIT
  CW-->>IN: Đã cam kết
  IN->>KF: Xác nhận offset
  loop Mỗi 5 phút
    CW->>WM: PutObject lô JSONL zstd, COMPLIANCE
    WM-->>CW: ETag khớp, ghi verified_at
  end
  loop Mỗi giờ
    AN->>OB: transit sign dh-audit-sign
    OB-->>AN: Chữ ký
    AN->>PG: INSERT audit_anchor và EVT-13-06
    AN->>WM: PutObject neo
  end
```

Sơ đồ cho thấy ba điểm giữ bản ghi nối tiếp nhau: hộp thư đi của DU (giữ tới khi Kafka xác nhận), Kafka (giữ 7 ngày, offset chỉ tiến sau khi bảng đã cam kết) và bảng chỉ-thêm (rồi tới WORM trong 10 phút). Mất kết nối ở bước nào trước khi cam kết thì Kafka giao lại và bước khử trùng ở bộ tiếp nhận loại bản trùng, nên không có bản ghi nửa chừng hay bản ghi thừa. Việc sao WORM và ký neo chạy sau, không nằm trên đường chờ của người dùng.

### 5.2. Kiểm tra toàn vẹn hằng ngày và xử lý đứt chuỗi (FR-13-014, 015)

Luồng kịch bản nghiêm trọng nhất của phân hệ: kiểm tra phát hiện đứt chuỗi và hệ thống phản ứng mà không tự sửa.

```{.mermaid caption="Kiểm tra toàn vẹn hằng ngày và xử lý đứt chuỗi (FR-13-014, 015)"}
sequenceDiagram
  autonumber
  participant SC as JobRunner lịch đêm
  participant VF as VerificationService
  participant PR as Bản sao đọc pg-core
  participant WM as Kho WORM
  participant BH as BreakHandler
  participant EV as EvidenceCollector
  participant OM as Module observability
  participant AM as Alertmanager
  actor SO as Cán bộ ATTT
  SC->>VF: Kiểm tra DAILY tenant T68
  VF->>PR: Đọc neo và các đoạn của chuỗi trực tuyến
  par Các đoạn song song
    VF->>PR: Đọc bản ghi theo seq trang 10.000
    VF->>VF: Tính lại hash, kiểm seq, kiểm chữ ký neo
  end
  VF->>WM: So lô mẫu 1 phần trăm
  VF->>VF: FAILED tại seq 1.204.331 loại HASH_MISMATCH
  VF->>BH: Thông tin đứt chuỗi
  BH->>PR: Đặt integrity SUSPECT, suspect_from_seq
  BH-)OM: ChainBrokenEvent
  OM->>AM: Cảnh báo an ninh UC-SEC-20 mức Nghiêm trọng
  AM-->>SO: SMS, thư, trong ứng dụng
  BH->>EV: Thu chứng cứ khoảng nghi vấn
  EV->>WM: Sao bảng và WORM vào dh-evidence có Object Lock
  BH->>BH: Mở hồ sơ ứng cứu ở PH-18, phát EVT-13-05
  SO->>OM: Đóng cảnh báo kèm kết luận
  VF->>PR: Lượt kiểm tra mới trên đoạn sau điểm đứt
  VF->>BH: PASSED
  BH->>PR: clearSuspect, integrity OK
```

Sơ đồ cho thấy hệ thống không tự sửa gì: toàn bộ phản ứng là gắn cờ, báo, thu chứng cứ và chờ con người. Chuỗi vẫn nhận bản ghi mới trong lúc nghi vấn để không mất bằng chứng. Cờ chỉ trở lại bình thường khi hai điều kiện cùng đúng: cán bộ ATTT ghi kết luận cho cảnh báo và một lượt kiểm tra mới đạt trên đoạn sau điểm đứt (BR-13-033).

### 5.3. PH-13 và Kafka ngừng, hồi phục và đối chiếu số lượng (FR-13-016, 017)

Luồng chứng minh cam kết không mất bản ghi: PH-13 hoặc Kafka ngừng, hồi phục, rồi đối chiếu số lượng.

```{.mermaid caption="PH-13 và Kafka ngừng, hồi phục và đối chiếu số lượng (FR-13-016, 017)"}
sequenceDiagram
  autonumber
  actor US as Người dùng
  participant DU as DU nguồn
  participant OX as audit_outbox
  participant RL as OutboxRelay
  participant KF as Kafka
  participant IN as Bộ tiếp nhận
  participant PG as ph13_audit
  participant RC as ReconciliationService
  participant MM as Mimir
  US->>DU: Thao tác thường
  DU->>OX: Ghi trong giao dịch, tăng bộ đếm
  DU-->>US: 200
  RL->>KF: Gửi lô
  KF--xRL: Không nhận
  RL->>RL: Thử lại giãn dần 1 giây tới 1 phút
  Note over OX: Tồn đọng tăng, luật audit-outbox-backlog cảnh báo
  alt Thao tác Nhạy cảm không ghi được vết
    US->>DU: Tra cứu dữ liệu Nhạy cảm
    DU->>OX: Ghi hộp thư đi thất bại
    DU-->>US: Từ chối phục vụ
  end
  KF-->>RL: Kafka hồi phục
  RL->>KF: Gửi bù theo thứ tự
  KF->>IN: Giao tồn đọng
  IN->>PG: Ghi tuần tự theo tenant
  RC->>MM: emitted của ngày D theo DU và tenant
  RC->>PG: received của ngày D và bản cách ly
  RC->>RC: diff bằng 0 thì MATCH
  RC->>PG: Lưu audit_reconciliation
```

Sơ đồ nêu hai quy tắc: thao tác thường không bao giờ chờ PH-13 hay Kafka, và thao tác dữ liệu Nhạy cảm là ngoại lệ duy nhất bị từ chối khi không ghi được vết ở nguồn (BR-13-003). Khi hồi phục, tồn đọng được gửi bù tuần tự và đối chiếu số lượng ban đêm chứng minh `diff` bằng 0, nên "không mất bản ghi" được kiểm chứng bằng số, không bằng lời hứa.

### 5.4. Tra cứu kiểm toán có ghi vết fail-closed và tra theo đối tượng (FR-13-020, 023)

Luồng tra cứu nhạy cảm nhất: người tra bị ghi vết trước khi thấy dữ liệu, và số định danh người bị tra không được lưu.

```{.mermaid caption="Tra cứu kiểm toán có ghi vết fail-closed và tra theo đối tượng bị tra cứu (FR-13-020, 023)"}
sequenceDiagram
  autonumber
  actor AU as Kiểm toán viên
  participant BF as BFF
  participant AP as AuditSearchService
  participant GD as SensitiveReadGuard
  participant OB as OpenBao
  participant DW as Hộp thư đi
  participant PR as Bản sao đọc
  AU->>BF: Tra theo số định danh, lý do, căn cứ
  BF->>AP: Chuyển tiếp kèm token người dùng
  AP->>AP: Kiểm quyền, xác thực lại, khoảng, lý do
  AP->>OB: transit hmac dh-T68-audit-hmac
  OB-->>AP: HMAC 64 ký tự thập lục phân
  AP->>AP: Xóa số định danh khỏi bộ nhớ
  AP->>GD: begin AUDIT.QUERY chỉ mang object_key_hmac
  GD->>DW: INSERT trong giao dịch riêng, COMMIT
  alt Không ghi được vết
    GD-->>AP: AuditUnavailableException
    AP-->>AU: 503 ERR-13-014, không trả dữ liệu
  else Ghi vết thành công
    AP->>PR: Đếm tối đa 1.000.001 dòng
    PR-->>AP: n
    AP->>PR: Truy vấn theo object_key_hmac, keyset 200 dòng
    PR-->>AP: Danh sách lượt tra cứu
    AP->>PR: Neo gần nhất, kết quả kiểm tra, integrity
    AP-->>AU: Danh sách kèm chỉ báo toàn vẹn
  end
```

Sơ đồ cho thấy số định danh người điều tra nhập chỉ tồn tại trong bộ nhớ đủ lâu để băm, không vào bản ghi kiểm toán, log hay bất kỳ bảng nào. Ghi vết nằm trước đọc dữ liệu và là điều kiện của đọc: nhánh lỗi dừng trước khi có một dòng dữ liệu nào rời máy chủ.

### 5.5. Xuất bằng chứng kiểm toán ký số (FR-13-024)

Luồng chạy nền tạo gói bằng chứng ký số cho thanh tra, tải xuống có hạn và có ghi vết.

```{.mermaid caption="Xuất bằng chứng kiểm toán ký số (FR-13-024)"}
sequenceDiagram
  autonumber
  actor AU as Kiểm toán viên
  participant AP as ExportService
  participant QU as audit_export
  participant WK as ExportWorker
  participant PR as Bản sao đọc
  participant WM as Kho WORM
  participant OB as OpenBao
  participant GR as Garage bucket tạm
  participant NT as Trung tâm thông báo
  AU->>AP: Xuất phạm vi, lý do, căn cứ, đã xác thực lại
  AP->>AP: Kiểm step-up, phạm vi tối đa 10 triệu bản ghi
  AP->>QU: INSERT REQUESTED và AUDIT.EXPORT.REQUEST
  AP-->>AU: 202 exportId
  WK->>QU: Lấy việc SKIP LOCKED, RUNNING
  loop Theo trang seq
    WK->>PR: Đọc bản ghi trong 12 tháng
    WK->>WM: Đọc lô cũ hơn 12 tháng
    WK->>GR: Ghi ZIP nhiều phần, tính băm khi ghi
  end
  WK->>WK: SegmentVerifier cho dải, ghi verification.json
  WK->>OB: Ký manifest
  OB-->>WK: manifest.sig
  WK->>GR: Ghi manifest, anchors, public-keys, script xác minh
  WK->>OB: Ký băm toàn gói
  alt Không ký được
    WK->>QU: FAILED, xóa tệp tạm, ERR-13-026
  else Đã ký đủ hai chữ ký
    WK->>QU: READY, file_hash, signature, EVT-13-08
    NT-->>AU: Gói sẵn sàng, hiệu lực 7 ngày
    AU->>AP: Tải gói
    AP->>AP: Ghi AUDIT.EXPORT.DOWNLOAD trước, fail-closed
    AP-->>AU: URL ký sẵn hiệu lực 15 phút
  end
```

Sơ đồ nêu rõ thứ tự bảo đảm: gói chỉ sang `READY` sau khi cả hai chữ ký đã có, không bao giờ để lại tệp chưa ký (BR-13-014), và mỗi lượt tải đều bị ghi vết trước khi cấp URL. Gói được ghi thẳng lên kho tạm bằng tải lên nhiều phần nên không phình đĩa pod dù có 10 triệu bản ghi.

### 5.6. Từ Ruler tới người trực, leo thang và đóng (FR-13-044, 045, 046, 047)

Luồng của đường cảnh báo, từ lúc điều kiện thỏa tới lúc người trực xử lý, gồm đường độc lập cho mức Nghiêm trọng và leo thang.

```{.mermaid caption="Từ Ruler tới người trực, leo thang và đóng cảnh báo (FR-13-044, 045, 046, 047)"}
sequenceDiagram
  autonumber
  participant RU as Mimir Ruler
  participant AM as Alertmanager
  participant AW as AlertWebhookHandler
  participant PG as ph13_obs
  participant ND as NotificationDispatcher
  participant P18 as PH-18 NotificationApi
  participant RY as alert-relay
  participant ES as EscalationScheduler
  actor T1 as Người trực cấp 1
  actor T2 as Người trực cấp 2
  RU->>RU: Đánh giá mỗi 30 giây, đủ thời gian duy trì
  RU->>AM: FIRING kèm tenant, rule_code, severity, group_key
  AM->>AM: Gom nhóm, chờ 10 giây
  par Hai receiver
    AM->>AW: Webhook mTLS
  and
    AM->>RY: Webhook CRITICAL
  end
  AW->>PG: Upsert alert FIRING, alert_notification PENDING, outbox EVT-13-01
  AW-->>AM: 200 sau khi cam kết
  ND->>PG: Lấy việc PENDING
  ND->>P18: SMS, thư, trong ứng dụng
  P18-->>T1: Thông báo
  RY-->>T1: SMS qua đường độc lập
  loop Mỗi 30 giây
    ES->>PG: CRITICAL chưa xác nhận quá 15 phút
    ES->>PG: UPDATE level 2 WHERE level 1 AND FIRING
    ES->>ND: Gửi cấp 2, EVT-13-03
    ND-->>T2: Thông báo leo thang
  end
  T1->>AW: Xác nhận cảnh báo
  AW->>PG: ACKNOWLEDGED, dừng leo thang
  RU->>AM: Điều kiện hết, sau keep_firing_for 5 phút
  AM->>AW: Webhook resolved
  AW->>PG: RESOLVED loại AUTO, EVT-13-02
```

Sơ đồ cho thấy hai đường song song cho mức Nghiêm trọng: đường có vòng đời qua `dh-platform` và đường độc lập qua `alert-relay`, nên `dh-platform` hay PH-18 ngừng thì người trực vẫn nhận tin. Leo thang là cập nhật có điều kiện trên cột `escalation_level` nên nhiều bản sao `dh-platform` chạy cùng lúc cũng chỉ gửi một lần, và xác nhận ngay sau đó làm điều kiện cập nhật thất bại.

### 5.7. Chẩn đoán bằng trace_id liên kết ba nguồn khi một nguồn lỗi (FR-13-028, 029)

Luồng chẩn đoán dùng nhiều nhất: từ một mã `trace_id` nhảy sang trace, log, chỉ số và bản ghi kiểm toán, chịu được khi một kho lỗi.

```{.mermaid caption="Chẩn đoán bằng trace_id liên kết ba nguồn khi một nguồn lỗi (FR-13-028, 029)"}
sequenceDiagram
  autonumber
  actor TO as Cán bộ vận hành
  participant CS as CorrelationService
  participant TP as Tempo
  participant LK as Loki
  participant MM as Mimir
  participant AU as Module audit
  TO->>CS: Liên kết trace_id
  CS->>CS: Kiểm định dạng, quyền, đặt OrgID từ token
  par Hạn chót 3 giây mỗi nguồn
    CS->>TP: Trace theo mã
  and
    CS->>LK: Đếm dòng log có trace_id
  and
    CS->>MM: Exemplar theo trace_id
  and
    CS->>AU: Đếm bản ghi kiểm toán chỉ khi có audit-read
  end
  TP-->>CS: Trace còn hoặc đã hết hạn giữ
  LK-->>CS: 42 dòng
  MM--xCS: 503
  AU-->>CS: 3 bản ghi
  CS-->>TO: Tóm tắt, liên kết, mimir unavailable ERR-13-014
  TO->>CS: Mở trace
  CS->>TP: Lấy trace đầy đủ
  CS->>CS: TimeBreakdown, InsightGenerator
  CS-->>TO: Thác nước, phân bổ thời gian, nhận xét
```

Sơ đồ cho thấy liên kết ba nguồn luôn trả được từng phần: một kho lỗi chỉ làm phần đó mang nhãn `unavailable` kèm ERR-13-014. Phần kiểm toán chỉ hiện với người có quyền và vắng mặt hoàn toàn với người khác, nên không lộ việc một `trace_id` có bản ghi kiểm toán hay không.

### 5.8. Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới (FR-13-059)

Luồng PH-20 gọi PH-13 khi tạo tenant: sáu bước lũy đẳng dựng chuỗi kiểm toán và toàn bộ quan sát cho tenant mới.

```{.mermaid caption="Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới (FR-13-059)"}
sequenceDiagram
  autonumber
  participant P20 as PH-20 saga
  participant PV as ObsProvisioner
  participant PG as ph13_obs
  participant AC as AuditChainAdminApi
  participant OB as OpenBao
  participant WM as Kho WORM
  participant P10 as PH-10 cấp phát topic
  participant K8 as Kubernetes API
  participant GF as Grafana
  participant RU as Mimir Ruler
  P20->>PV: provision T68, scale QM-VUA, Idempotency-Key
  PV->>PG: Mở sổ bước
  PV->>AC: S1 provision chuỗi
  AC->>OB: Tạo khóa HMAC dh-T68-audit-hmac
  AC->>PG: audit_chain, genesis_hash, phân vùng 4 tháng
  AC->>WM: Ghi audit/T68/_genesis.json có khóa
  PV->>P10: S2 tạo topic và ACL
  P10-->>PV: Sẵn sàng trong 60 giây
  PV->>K8: S3 ConfigMap overrides, tuyến Collector
  PV->>GF: S4 org, nguồn dữ liệu, dashboard chuẩn
  PV->>RU: S5 luật chuẩn và luật UC-SEC
  PV->>PG: S5 lịch trực, kênh, kiểm tra tổng hợp mặc định
  PV->>PG: S6 tham số 13.* mặc định, provisioned_at
  PV-->>P20: ProvisionReport các bước
  Note over PV,K8: Gateway cuộn lại nền, 2 tới 3 phút dữ liệu mang nhãn không xác định
```

Sơ đồ cho thấy mỗi bước được ghi vào sổ bước trước khi chạy nên gọi lại cùng `Idempotency-Key` tiếp tục từ chỗ dở. Bước ghi `_genesis.json` vào WORM làm điểm khởi đầu của chuỗi trở thành bằng chứng bất biến ngay từ ngày đầu. Việc cuộn gateway chạy nền nên không giữ saga của PH-20.

### 5.9. Phát hiện bất thường từ bản ghi kiểm toán và đề xuất tạm ngừng HTTT (FR-13-052, 053)

Luồng đường an ninh: bản ghi kiểm toán trở thành cảnh báo an ninh, và cán bộ ATTT đóng với kết luận hoặc đề xuất tạm ngừng HTTT.

```{.mermaid caption="Phát hiện bất thường từ bản ghi kiểm toán và đề xuất tạm ngừng HTTT (FR-13-052, 053)"}
sequenceDiagram
  autonumber
  participant EN as DetectionEngine
  participant AQ as AuditDetectionQueryApi
  participant PG as ph13_audit
  participant SA as SecurityAlertService
  participant AM as Alertmanager
  participant SI as otel-siem
  actor SO as Cán bộ ATTT
  participant P01 as PH-01
  EN->>AQ: COUNT_ACTION_BY_ACTOR cho UC-SEC-11 cửa sổ 1 giờ
  AQ->>PG: Truy vấn phân vùng nóng chỉ đọc
  PG-->>AQ: Người X có 27 lần PII.REVEAL
  AQ-->>EN: Dòng kết quả
  EN->>EN: So ngưỡng của tenant, 27 lớn hơn 20
  EN->>SA: Upsert cảnh báo an ninh gom theo luật và chủ thể
  SA->>PG: Bằng chứng tối đa 100 audit_id
  SA->>AM: POST alerts kind security
  AM-->>SO: Thông báo
  SA->>SI: Bản ghi log OTLP
  SA->>SA: Phát EVT-13-04
  SO->>SA: Tiếp nhận cảnh báo
  SO->>SA: Đề xuất tạm ngừng HTTT kèm systemCode, lý do
  SA->>P01: POST API-01-089 đề xuất tạm ngừng (systemCode, alertId, severity, lý do, incidentRef, evidenceUrl)
  SO->>SA: Đóng với kết luận CONFIRMED_INCIDENT
  SA->>PG: CLOSED và SECURITY.ALERT.CLOSE
```

Sơ đồ cho thấy PH-13 chỉ đề xuất, PH-01 quyết định việc tạm ngừng. Bằng chứng gắn vào cảnh báo là danh sách mã bản ghi kiểm toán (tối đa 100), không phải dữ liệu gốc, nên người xem cảnh báo phải mở tra cứu kiểm toán (có lý do và ghi vết) mới thấy chi tiết.

### 5.10. Chốt và lưu trữ phân vùng kiểm toán (FR-13-018)

Luồng vòng đời dữ liệu kiểm toán: chốt phân vùng tháng và chỉ lưu trữ khi bản trên WORM đã được xác minh.

```{.mermaid caption="Chốt và lưu trữ phân vùng kiểm toán (FR-13-018)"}
sequenceDiagram
  autonumber
  participant PM as PartitionManager
  participant PG as ph13_audit
  participant AN as AnchorService
  participant AS as ArchiveService
  participant WM as Kho WORM
  participant OB as OpenBao
  PM->>PG: Ngày 1 lúc 03:00 tạo phân vùng 3 tháng tới
  PM->>PG: Phân vùng tháng trước đủ lô WORM và đối chiếu MATCH
  PM->>AN: Ký neo BOUNDARY cho bản ghi cuối tháng
  PM->>PG: OPEN sang SEALED
  Note over PM,AS: Hằng ngày xét phân vùng SEALED quá 12 tháng
  PM->>AS: preflight phân vùng
  AS->>WM: Liệt kê và đọc mọi lô của dải seq
  AS->>PG: So băm toàn phân vùng với WORM
  alt Thiếu lô hoặc băm lệch hoặc hạn giữ không đủ
    AS-->>PM: Giữ SEALED, ERR-13-125
  else Đủ điều kiện
    AS->>OB: Xin vai trò ph13_archive TTL 15 phút
    AS->>PG: CALL p_archive_partition (tách rồi xóa phân vùng)
    AS->>PG: ARCHIVED, AUDIT.PARTITION.ARCHIVE, EVT-13-11
  end
```

Sơ đồ cho thấy việc xóa dữ liệu khỏi bảng trực tuyến chỉ xảy ra sau khi mọi lô trên WORM đã được đọc và so băm với bản trong bảng, và chỉ bằng một vai trò tạm thời có TTL 15 phút. Neo `BOUNDARY` được ký trước nên chuỗi trực tuyến còn lại luôn có điểm xuất phát có chữ ký sau khi phân vùng cũ rời đi.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph13_audit` và `ph13_obs` có `tenant_id` và `FORCE ROW LEVEL SECURITY` với chính sách `tenant_id = current_setting('app.tenant_id', false)` (D03-03-PH13). `TenantContextFilter` của `dh-platform` đặt `TenantContext` từ token rồi gọi `set_config('app.tenant_id', ?, true)` ở đầu mỗi giao dịch (D03-10 §3); vai trò `ph13_app`, `ph13_verify`, `ph13_obs_app` không có `BYPASSRLS` và không là chủ bảng (SEC-81). Ba chỗ đặc biệt của PH-13:

1. **Bộ tiếp nhận ghi cho nhiều tenant.** Tenant của mỗi lô lấy từ tên topic và được đặt bằng `TenantContext.runAs(tenant)` trước khi mở giao dịch; một lô không bao giờ trộn hai tenant. Công việc nền (neo, sao WORM, kiểm tra, phát hiện, đối chiếu) chạy lặp theo từng tenant trong `runAs`, kể cả tenant `PLATFORM` (luật R7).
2. **Bảng kiểm toán dùng chung cho mọi tenant, phân vùng theo tháng.** Một phân vùng tháng chứa bản ghi của mọi tenant nên `PartitionManager` và `ArchiveService` làm việc ở mức bảng bằng vai trò `ph13_archive` (chỉ DDL, không đọc dòng nào). Hệ quả là trạng thái `SEALED`, `ARCHIVED` áp cho cả phân vùng tháng: phân vùng chỉ lưu trữ khi **mọi** tenant có bản ghi trong tháng đó đã đủ điều kiện, và `13.audit.online-months` của từng tenant (12 đến 24) làm phân vùng được giữ theo giá trị lớn nhất. Đây là lựa chọn đơn giản và an toàn; nếu một tenant đặt 24 tháng mà các tenant khác 12 thì chi phí là dung lượng bảng trực tuyến lớn hơn, được ghi ở rủi ro R-13-07, và có thể chuyển sang phân vùng con theo nhóm tenant sau.
3. **Chuỗi, neo, WORM tách theo tenant ở mọi tầng.** Chuỗi riêng (`genesis_hash` riêng), tiền tố WORM `{tenant}/`, khóa HMAC riêng; chỉ khóa ký neo `dh-audit-sign` là khóa nền tảng chung (Q13-13), có tiền tố tên miền trong tải ký.

| Kho hoặc tài nguyên | Cơ chế cách ly | Kiểm thử |
|---|---|---|
| PostgreSQL `ph13_*` | RLS bắt buộc theo `app.tenant_id`; vai trò không bypass | SEC-81, bộ kiểm tra khi lấy kết nối |
| Kafka | Topic theo tenant `{tenant}.obs.*`, ACL ghi theo KafkaUser của DU, ACL đọc cho nhóm `dh-platform-audit-ingest`; tenant lấy từ tên topic | UC-SEC-09, ca kiểm thử ACL (SEC-87) |
| Mimir, Loki, Tempo | `X-Scope-OrgID` do máy chủ đặt từ token, liên kết đa tenant tắt, hạn mức theo org | Kiểm thử rò rỉ T90 → T91 hằng ngày |
| ClickHouse | Cột `tenant_id`, mẫu truy vấn có tên với tham số ràng buộc, chính sách dòng theo setting | Như trên |
| Grafana | Một org mỗi tenant, nguồn dữ liệu cố định OrgID, người dùng tenant không sửa nguồn | Như trên |
| WORM, bucket chứng cứ | Tiền tố `{tenant}/`; tài khoản ghi chỉ `PutObject` | Kiểm thử đọc chéo tiền tố |
| OpenBao | Chính sách theo đường dẫn; khóa HMAC `dh-{tenant}-audit-hmac` riêng; vai trò CSDL động theo tiến trình | SEC-88 |
| Valkey (đệm, bộ đếm) | Khóa sinh bằng hàm `Keys.of(tenant, ...)`, cấm tạo khóa tay (luật R4 mở rộng) | ArchUnit |
| Bộ đếm, chỉ số tự phát | Nhãn `tenant` từ `TenantContext`, kiểm bởi gateway (§4.11) | NFR-13-020 |

: Cách ly tenant theo từng kho của PH-13

Truy cập liên tenant chỉ qua phiên liên tenant có lý do (FR-00-012, BR-13-018, SEC-85): mọi truy vấn quan sát dùng OrgID của tenant đích ghi `OBS.CROSS_TENANT_ACCESS` vào chuỗi của tenant đích; mọi truy vấn kiểm toán đặt `tenant` của đích và bản ghi `AUDIT.QUERY` vào hai chuỗi. API nội bộ (API-13-089, 090) lấy tenant từ danh tính máy hoặc nhãn do Ruler đóng, không từ thân yêu cầu.

## 7. Bảo mật

Chương này gom các mối đe dọa của PH-13 và biện pháp hiện thực, dẫn mã `SEC-*` đã có ở D03-07. Điểm đặc biệt: PH-13 vừa là hệ thống phải được bảo vệ (nhật ký là bằng chứng pháp lý) vừa là hệ thống bảo vệ các hệ khác (phát hiện).

| Vấn đề | Biện pháp | SEC |
|---|---|---|
| Nội gián hoặc quản trị CSDL sửa, xóa bản ghi kiểm toán | Chuỗi băm theo tenant; trigger chặn sửa xóa; vai trò `INSERT`, `SELECT`; tài khoản động; neo ký hằng giờ ở ba nơi; WORM Object Lock tuân thủ; kiểm tra toàn bộ chuỗi hằng ngày; `TamperProbe` mỗi phút; `pgaudit` | SEC-60, SEC-62, SEC-28, SEC-36 |
| Mất bản ghi kiểm toán | Hộp thư đi có xác nhận, Kafka `acks=all`, offset sau cam kết, đối chiếu số lượng hằng ngày | SEC-60 |
| DU giả danh hay ghi chéo tenant | ACL Kafka, `dh-mac` theo DU, `audit_source_grant`, tenant lấy từ tên topic | SEC-82, SEC-80, SEC-24 |
| Lộ giá trị Nhạy cảm qua log, trace, chỉ số, bản ghi kiểm toán | Che ba lớp (`Redactor`, Collector `redaction`, APISIX chỉ siêu dữ liệu); quét độc lập hằng ngày; cách ly bản ghi vi phạm; che ở phía đọc | SEC-32, SEC-31 |
| Lộ số định danh người bị tra cứu | Chỉ lưu `HMAC-SHA256` theo khóa tenant; số định danh không vào log, bản ghi, bộ nhớ lâu | SEC-34 |
| Lạm dụng quyền xem nhật ký kiểm toán | Lý do bắt buộc, ghi vết trước đọc (fail-closed), xác thực lại phiên, MFA cho vai trò quản trị, thông báo quản trị tỉnh khi liên tenant | SEC-60, SEC-23, SEC-29, SEC-85 |
| Rò rỉ chéo tenant ở kho quan sát | OrgID đặt ở máy chủ, liên kết đa tenant tắt, `ExpressionGuard`, chính sách dòng ClickHouse, kiểm thử rò rỉ hằng ngày | SEC-84, SEC-81, SEC-87 |
| Giả mạo cảnh báo hay webhook Alertmanager | mTLS theo SPIFFE ID, chính sách mạng chỉ cho Alertmanager gọi webhook; API Alertmanager không công bố ra ngoài namespace `dh-obs` | SEC-14, SEC-15 |
| Chèn LogQL, TraceQL, SQL | `SimpleQueryCompiler` thoát giá trị và dùng danh sách trường trắng; mẫu truy vấn có tên; tham số ràng buộc | SEC-43 |
| XSS từ nội dung log, trace hiển thị | Thoát ở giao diện, CSP của BFF, không hiển thị HTML từ log | SEC-44 |
| SSRF qua kênh webhook, đích SIEM | Danh sách FQDN cho phép ở cổng thoát, bộ kiểm SSRF chặn dải nội bộ, chữ ký `webhook-signature` | SEC-16, SEC-47 |
| Lộ hay lạm dụng khóa ký, khóa HMAC | Khóa transit không xuất, xoay 12 tháng, giữ khóa công khai các phiên bản, tiền tố tên miền chống dùng lại chữ ký | SEC-34, SEC-36 |
| Mất toàn vẹn chứng cứ sự cố | Bucket chứng cứ Object Lock, ghi chuỗi bảo quản (ai thu, khi nào, băm) | SEC-75 |
| Kho WORM bị ghi đè hay xóa | Tài khoản ghi không có `DeleteObject` và `PutObjectRetention`; tài khoản gia hạn tách riêng; tách khỏi Garage và kho sao lưu | SEC-62, SEC-70 |
| Hệ giám sát im lặng | Nhịp tim ngoài site, `monitoring-down`, kiểm tra tổng hợp, kênh độc lập | SEC-61, SEC-64 |
| Bí mật kênh thông báo, token Grafana, khóa S3 | OpenBao KV, xoay 90 ngày, chỉ tiến trình cần mới đọc | SEC-33 |
| Dữ liệu ra khỏi lãnh thổ | Kho WORM, SIEM, kho nén đều trong nước | SEC-66, CMP-LAW-16 |

: Bảo mật của PH-13

**Quyền kiểm ở máy chủ.** Lớp `web` dùng `@PreAuthorize` theo quyền hoặc scope máy; giao diện ẩn nút chỉ là tiện ích, không là lớp bảo vệ (luật R3).

| Nhóm API | Quyền hoặc scope |
|---|---|
| Bảng điều khiển, sức khỏe, cảnh báo (xem), thống kê | `PERM-13-dashboard` |
| Tra log, trace, truy cập API, truy vấn đã lưu | `PERM-13-logs` |
| Tra cứu kiểm toán, chi tiết, báo cáo liên tenant, danh sách neo, xem kết quả kiểm tra | `PERM-13-audit-read` |
| Xuất bằng chứng, kiểm tra toàn vẹn theo yêu cầu | `PERM-13-audit-export` (cộng xác thực lại phiên) |
| Luật cảnh báo, runbook, lịch trực, kênh thông báo | `PERM-13-alert-admin` |
| Xác nhận, đánh dấu đã xử lý, tạm ẩn cảnh báo | `PERM-13-alert-ack` |
| Cảnh báo an ninh, luật phát hiện, báo cáo sự cố | `PERM-13-security` (cộng xác thực lại phiên với thao tác nhạy cảm) |
| Tham số `13.*`, SIEM, bộ dashboard, hạn mức | `PERM-13-admin` |
| API máy | `audit:write`, `audit:history-read`, `obs:metrics-read`, `obs:diagnostics-read`, `obs:health-read`, `obs:tenant-provision` |

: Quyền và scope theo nhóm API

Ba quyền `PERM-13-alert-ack`, `PERM-13-security`, `PERM-13-admin` và sáu scope máy là đề nghị của FRS §3.4 chờ D02-08. Tách nhiệm vụ: người có `PERM-13-alert-admin` không có `PERM-13-audit-export`; vai trò kiểm toán chỉ đọc; không vai trò nào có đường ghi vào bảng kiểm toán (BR-13-019).

**Vai trò CSDL và khóa.**

| Vai trò hoặc khóa | Quyền | Cấp |
|---|---|---|
| `ph13_owner` | Chủ bảng; không đăng nhập; chỉ di trú Flyway trong đường ống triển khai, DDL ghi bởi `pgaudit` | Không cấp cho người |
| `ph13_app` | `INSERT`, `SELECT` trên `audit_event`, `audit_anchor`; `INSERT` (theo cột) và `UPDATE` theo cột trên `audit_chain`; `UPDATE` trên các bảng trạng thái | OpenBao động, TTL 1 giờ |
| `ph13_verify` | Chỉ `SELECT`, kết nối tới bản sao đọc | OpenBao động |
| `ph13_archive` | Chỉ `EXECUTE` thủ tục `p_archive_partition` (không quyền bảng) | OpenBao động, TTL 15 phút, chỉ khi `preflight` đạt |
| `ph13_obs_app` | CRUD trên `ph13_obs` | OpenBao động |
| `dh-audit-sign` | ECDSA P-256, ký, không xuất | Transit, xoay 12 tháng |
| `dh-{tenant}-audit-hmac` | `HMAC-SHA256`, không xuất | Transit; DU và `dh-platform` chỉ có `update` trên đường `hmac` |
| `audit-mac/{du}` | Khóa HMAC chữ ký nguồn của DU | KV; DU chỉ đọc khóa của mình |
| `worm-writer`, `worm-retention` | `PutObject` và `GetObject`; `PutObjectRetention` | KV, xoay 90 ngày |

: Vai trò CSDL và khóa của PH-13

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mỗi đối tượng có vòng đời có bảng chuyển trạng thái và chỗ kiểm ở máy chủ; mọi lệnh người dùng mang `If-Match` theo cột `version` (khóa lạc quan, ERR-13-007), lệnh hệ thống dùng thử lại tối đa 3 lần khi xung đột. Trạng thái được kiểm trong aggregate, không ở bộ điều khiển.

| Đối tượng | Từ | Lệnh hoặc sự kiện | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| Alert | (mới) | Luật thỏa đủ `forSeconds` (webhook `firing`) | FIRING | Nhãn `tenant`, `rule_code` hợp lệ |
| Alert | FIRING | acknowledge | ACKNOWLEDGED | `PERM-13-alert-ack`; dừng leo thang |
| Alert | FIRING, ACKNOWLEDGED | silence | SILENCED | Hạn ≤ 7 ngày (Nghiêm trọng ≤ 24 giờ), có lý do |
| Alert | SILENCED | Hết hạn mà webhook `firing` còn | FIRING | `silence_until` đã qua |
| Alert | FIRING, ACKNOWLEDGED, SILENCED | resolve hoặc webhook `resolved` | RESOLVED | Thủ công: nguyên nhân, hành động, kết quả; tự động: `AUTO` |
| SecurityAlert | (mới) | Luật phát hiện thỏa | NEW | Gom theo (luật, chủ thể) trong 1 giờ |
| SecurityAlert | NEW | acknowledge | ACKNOWLEDGED | `PERM-13-security`; ghi `assignee` |
| SecurityAlert | NEW, ACKNOWLEDGED | close | CLOSED | Có `verdict` ∈ ba kết luận (ERR-13-023) |
| AlertRule | (mới) | Tạo kèm runbook | ACTIVE | Runbook đủ năm mục, biểu thức hợp lệ |
| AlertRule | ACTIVE | disable | DISABLED | Luật tenant; đóng cảnh báo mở |
| AlertRule | DISABLED | enable | ACTIVE | Biểu thức còn hợp lệ |
| AlertRule | ACTIVE, DISABLED | retire | RETIRED | Lý do; mã không dùng lại |
| ExportRequest | (mới) | Yêu cầu hợp lệ | REQUESTED | Step-up, lý do, căn cứ, không trùng `scope_hash` |
| ExportRequest | REQUESTED | Worker nhận | RUNNING | `SKIP LOCKED` |
| ExportRequest | REQUESTED | Người yêu cầu hủy | CANCELLED | Chỉ người yêu cầu |
| ExportRequest | RUNNING | Đã ký hai chữ ký | READY | Cả hai chữ ký có |
| ExportRequest | RUNNING | Lỗi, không ký được | FAILED | Xóa tệp tạm |
| ExportRequest | READY | Quá 7 ngày | EXPIRED | `ExportJanitor` |
| AuditPartition | (mới) | Đầu tháng | OPEN | Phân vùng tạo trước 3 tháng |
| AuditPartition | OPEN | Hết tháng, WORM đủ, đối chiếu `MATCH` | SEALED | Mọi tenant có bản ghi trong tháng; neo `BOUNDARY` đã ký |
| AuditPartition | SEALED | Quá thời hạn trực tuyến, `preflight` đạt | ARCHIVED | Mọi lô WORM đủ, băm khớp, hạn giữ đủ (ERR-13-125) |
| AuditChain (`status`) | OPEN | close | CLOSED | `LifecycleCloser`, có neo cuối `final` (ERR-13-043 khi đã đóng) |
| AuditChain (`integrity`) | OK | Kiểm tra `FAILED`, neo lệch, `TamperProbe` | SUSPECT | `BreakHandler`; không tự sửa |
| AuditChain (`integrity`) | SUSPECT | Kết luận của SO và lượt kiểm tra mới đạt | OK | `ChainStatusService.clearSuspect` |
| Verification | (mới) | Yêu cầu hoặc lịch | RUNNING | Một lượt mỗi tenant (ERR-13-032) |
| Verification | RUNNING | Xong | PASSED, FAILED | `first_break_seq` khi `FAILED` |

: Bảng chuyển trạng thái

Cảnh báo `RESOLVED`, `SecurityAlert` `CLOSED`, `ExportRequest` `FAILED`, `EXPIRED`, `CANCELLED`, `AuditPartition` `ARCHIVED` là trạng thái cuối; mọi lệnh ở trạng thái cuối trả ERR-13-020.

### 8.2. Hộp thư đi, tính nhất quán và lũy đẳng

PH-13 có hai loại thao tác cần nhất quán giữa CSDL và bên ngoài, và đều tránh giao dịch phân tán bằng cách ghi trạng thái trước rồi để tiến trình nền hoàn tất lũy đẳng.

| Thao tác | Mô hình nhất quán | Khóa lũy đẳng | Khi lỗi giữa chừng |
|---|---|---|---|
| Bản ghi kiểm toán DU → PH-13 | Hộp thư đi có xác nhận, offset sau cam kết | `id` bản ghi (UUID v7), khử trùng theo `id` | Gửi lại, khử trùng bỏ qua bản trùng |
| Sự kiện EVT-13-* của PH-13 | `outbox` của `dh-platform` ghi cùng giao dịch với đổi trạng thái; Debezium Outbox Router (hồ sơ `QM-VUA`, `QM-LON`) hoặc `OutboxRelay` (hồ sơ `QM-NHO`) | `eventId`; bên nhận khử trùng theo (thực thể, `version`) | Phát bù ≤ 5 phút sau khi Kafka hồi phục |
| Neo | Ký rồi ghi trong một giao dịch, công bố sau | Duy nhất `(tenant_id, anchored_at)` | Ký lại ở lần chạy sau, bản ký thừa không nối vào chuỗi |
| Sao WORM | Ghi bảng `audit_worm_batch` sau khi `HeadObject` đối chiếu `ETag` | Tên đối tượng theo dải `seq` | Ghi lại dưới tên mới khi `ETag` lệch; dải không chồng nhờ kiểm khi chọn lô |
| Webhook cảnh báo | Upsert theo khóa tự nhiên, trả `200` sau cam kết | `(tenant, rule_code, fingerprint)` | Alertmanager gửi lại, upsert không nhân đôi |
| Thông báo | `alert_notification` `PENDING` cùng giao dịch với cảnh báo | `(alert_id, channel, level)` | Dispatcher lấy việc `SKIP LOCKED`, thử lại |
| Leo thang | `UPDATE ... WHERE escalation_level = :l` | `(alert_id, level)` | Một bản sao thắng |
| Xuất bằng chứng | Hàng đợi `audit_export`, cờ trạng thái | `scope_hash` | Việc `RUNNING` quá hạn bị thu hồi và chạy lại từ đầu (tệp tạm xóa) |
| Khởi tạo tenant | Sổ bước trong `tenant_obs_config` | `Idempotency-Key` cộng tham số | Tiếp tục từ bước dở (ERR-13-042 nếu tham số khác) |
| Đẩy luật tới Ruler | Bảng là nguồn sự thật, `RuleReconciler` so băm nhóm | Băm nhóm luật | Tự lành trong 5 phút |
| Sự kiện Modulith giữa module | Sổ sự kiện bền của Spring Modulith | `ChainBrokenEvent.verificationId` | Phát lại khi khởi động lại |

: Nhất quán và lũy đẳng theo thao tác

### 8.3. Thử lại, thời gian chờ, ngắt mạch

Mọi lời gọi ra ngoài dùng Resilience4j (thời gian chờ, thử lại có giãn, ngắt mạch, bulkhead) cấu hình theo bảng. Đường kiểm toán không dùng ngắt mạch ở phía ghi vì mục tiêu là không bỏ bản ghi: thay vào đó giãn dần và dừng xác nhận offset.

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch, ghi chú |
|---|---|---|---|
| Ghi chuỗi (PostgreSQL) | `statement_timeout` 20 giây, chờ khóa 5 giây | Giãn 1 giây tới 1 phút, không giới hạn số lần | Không ngắt; lỗi quá 5 phút cảnh báo `CRITICAL` (ERR-13-106) |
| OpenBao ký neo, ký gói | 2 giây | 3 lần, 200 ms, 400 ms, 800 ms | 50% trên 10 lượt, nửa mở 30 giây; neo làm lại lần sau |
| OpenBao `hmac` (tra theo đối tượng) | 2 giây | 2 lần | ERR-13-014 khi ngắt |
| WORM `PutObject` | 30 giây | Giãn tới 5 phút, giữ lô | Bulkhead 4 luồng mỗi bản sao; quá 4 giờ `CRITICAL` |
| WORM đọc (kiểm tra, xuất) | 60 giây mỗi lô | 2 lần | `wormCheck = UNAVAILABLE`, không hủy lượt |
| Mimir truy vấn | `13.query.timeout-seconds` (30) | 1 lần với lỗi mạng | 50% trên 20 lượt, nửa mở 15 giây; panel báo ERR-13-014 |
| Loki, Tempo truy vấn | 30 giây, 15 giây | 1 lần | Như Mimir; phần khác của màn vẫn trả |
| ClickHouse | 15 giây | 1 lần | Như trên |
| Mimir Ruler API (đẩy luật) | 10 giây | 3 lần | `RuleReconciler` chạy lại sau 5 phút |
| Alertmanager API v2 (silence, alerts) | 5 giây | 3 lần | Cảnh báo `CRITICAL` vẫn có đường trực tiếp |
| PH-18 `NotificationApi` | 5 giây | 30 giây, 2 phút, 10 phút | Chuyển kênh dự phòng, `alert-relay` cho `CRITICAL` (ERR-13-120) |
| Grafana API | 5 giây | 2 lần | ERR-13-014, saga PH-20 thử lại |
| PH-10 cấp phát topic | 5 giây mỗi lời gọi, chờ sẵn sàng 60 giây | 2 lần | ERR-13-014 |
| PH-01 (danh sách HTTT) | 3 giây | 1 lần | Dùng bản sao tối đa 24 giờ |
| SIEM | Theo `otel-siem` | Hàng đợi đĩa 1.024 MB | ERR-13-122 sau 15 phút |

: Thời gian chờ, thử lại, ngắt mạch

### 8.4. Phân loại lỗi chạy nền

Mã ERR-13-101…126 không có mã HTTP; mỗi mã có nơi ghi, người thấy và hành xử tự động. Cột "Ghi ở" luôn gồm chỉ số `dh_*_total{result}` tương ứng ở chương 10.

| Mã | Thành phần | Người thấy | Hành xử |
|---|---|---|---|
| 101, 102, 103, 104, 105 | Bộ tiếp nhận (§4.3) | Nhóm DU nguồn, SO; UI-13-18 | Cách ly hoặc bỏ qua; 103, 104 kèm UC-SEC-09; 105 cảnh báo `CRITICAL` |
| 106 | `ChainWriter` | Vận hành; UI-13-18 | Hủy giao dịch, thử lại giãn dần; quá 5 phút `CRITICAL` |
| 107, 108 | Bộ neo, bộ sao WORM | Vận hành; UI-13-18 | Thử lại; 108 trễ 30 phút `WARNING`, 4 giờ `CRITICAL` |
| 109, 110 | `BreakHandler` | SO, TA (PA nếu `PLATFORM`) | `SUSPECT`, UC-SEC-20, thu chứng cứ, không tự sửa |
| 111 | Đối chiếu | SO, nhóm DU nguồn | `MISMATCH`, EVT-13-09, `CRITICAL` |
| 112 | `PiiScanner` | Nhóm DU nguồn, SO | `WARNING`; tái phạm 3 ngày thì `CRITICAL` |
| 113, 114 | Collector gateway | Vận hành; UI-13-01 | Gán `_unattributed`; bỏ nhãn và đếm |
| 115, 116, 117 | Collector, trace | Vận hành; UI-13-01 | Đệm, bỏ dữ liệu ít quan trọng; cắt trace; đánh `incomplete` |
| 118 | ClickHouse, Kafka | Vận hành; UI-13-01 | Bản ghi chờ ở Kafka tối đa 3 ngày, ghi bù |
| 119 | Ruler, `DetectionEngine` | TA, PA, SO | Cảnh báo `rule-eval-failed`; engine chạy bù |
| 120, 121 | Thông báo, leo thang | PA, TA | Kênh dự phòng; 121 qua kênh độc lập |
| 122 | `otel-siem` | PA, TA; UI-13-17 | Hàng đợi đĩa, `WARNING` sau 15 phút |
| 123 | `CapacityWatcher` | PA, PO | EVT-13-14, đề nghị nâng hạn mức |
| 124 | Kiểm tra tổng hợp | Người trực | EVT-13-13, luật `probe-failed` |
| 125 | `ArchiveService` | PA, TA; UI-13-18 | Giữ `SEALED`, `WARNING` |
| 126 | `ChainWriter` | Vận hành; UI-13-18 | Vẫn ghi, đặt cờ `clock_skew`, báo DU nguồn |

: Phân loại lỗi chạy nền

Lỗi API (ERR-13-001…044) trả RFC 9457 qua `ProblemDetail` với `type`, `title`, `status`, `detail`, `errorCode`, `traceId`; `detail` do máy chủ điền các tham số cụ thể của câu thông báo ở FRS §9.2.

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số `13.*` và nơi áp dụng

Tham số có tiền tố `13.` nằm ở `tenant_obs_config` (FRS §8.3), sửa theo FR-13-061 qua `SettingsService` (§4.22). Bảng sau cho biết thành phần nào đọc tham số nào và hiệu lực ra sao; mặc định và miền giá trị ở FRS §8.3 không lặp lại.

| Khóa | Thành phần dùng | Cách áp dụng | Hiệu lực |
|---|---|---|---|
| `13.metrics.scrape-interval-seconds` | Collector agent | Dựng lại cấu hình `scrape_interval`, cuộn gateway | ≤ 3 phút (Q13-26) |
| `13.trace.decision-wait-seconds`, `13.trace.success-sample-percent`, `13.trace.slow-percentile` | Collector gateway (`tail_sampling`), `SamplingThresholdPublisher` | Dựng lại ConfigMap, cuộn gateway | ≤ 3 phút (Q13-26) |
| `13.series.max-active` | Mimir (overrides), `CapacityWatcher` | `OverridesReconciler` ghi ConfigMap | ≤ 60 giây |
| `13.alert.eval-interval-seconds`, `13.alert.max-rules`, `13.alert.silence-max-days`, `13.alert.escalate-minutes` | `RulePublisher`, `RuleValidator`, `SilenceService`, `EscalationScheduler` | Đệm 30 giây, hủy khi nhận EVT-13-10 | ≤ 60 giây |
| `13.office-hours` | `NotificationService`, `DetectionEngine` | Như trên | ≤ 60 giây |
| `13.slo.data-plane-availability`, `13.slo.gateway-latency-p95-ms` | `StandardRuleCatalog` (biến mẫu của luật chuẩn), `OverviewService` (vạch SLO) | Dựng lại luật rồi `RulePublisher` | ≤ 60 giây |
| `13.probe.interval-seconds` | `SyntheticProbeRunner` | Đệm 30 giây | ≤ 60 giây |
| `13.audit.anchor-interval-minutes`, `13.audit.worm-batch-minutes` | `AnchorScheduler`, `WormBatchWriter` | Đọc ở mỗi lượt chạy | ≤ 60 giây |
| `13.audit.worm-retention-years` | `WormBatchWriter`, `RetentionExtender` | Áp cho lô mới; lô cũ gia hạn bằng lệnh kéo dài | Lô kế tiếp |
| `13.audit.online-months` | `PartitionManager` | Điều kiện lưu trữ (phân vùng chung, §6) | Lần chạy kế |
| `13.audit.verify-cron` | `JobRunner` | Đăng ký lại lịch | ≤ 60 giây |
| `13.audit.query-max-records`, `13.audit.export-max-records` | `AuditSearchService`, `ExportService` | Đệm 30 giây | ≤ 60 giây |
| `13.query.max-concurrent-per-user`, `13.query.timeout-seconds`, `13.live-tail.idle-minutes` | `QueryLimiter`, `LiveTailService` | Đệm 30 giây | ≤ 60 giây |
| `13.export.link-ttl-minutes` | `ExportService` | Đọc khi tạo URL | Tức thì |
| `13.siem.queue-max-mb` | `SiemPipelineRenderer` | Dựng lại pipeline `otel-siem` | ≤ 3 phút |

: Tham số 13.* theo thành phần

### 9.2. Cấu hình kỹ thuật không theo tenant

Các giá trị dưới đây do đội nền tảng đặt trong `application.yml` của `dh-platform` (ConfigMap theo hồ sơ triển khai), không nằm trong tham số `13.*` vì không thuộc quyền tenant. Các giới hạn khoảng thời gian tối đa mỗi lần tra là giả định thiết kế, cơ sở: Loki giữ 90 ngày và truy vấn dài tốn tài nguyên (NFR-13-005), trace giữ 14 ngày, lượt gọi API 12 tháng có view tổng hợp; chỉnh được theo kết quả đo ở tỉnh thí điểm.

```yaml
dh:
  platform:
    audit:
      ingest:
        topic-pattern: '^[a-z0-9]+\.obs\.audit\.recorded\.v1$'     # kèm platform.obs.audit.recorded.v1
        batch-size: 500
        concurrency: 3
        lock-timeout: 5s
        field-max-bytes: 65536                                     # before, after
        scan-exceptions: []                                        # danh sách (du, action) bỏ khỏi quét số định danh
      worm:
        endpoint: https://rgw.dh-s3.svc
        bucket: dh-worm-audit
        object-lock-mode: COMPLIANCE
        max-batch-records: 50000
        evidence-bucket: dh-evidence
      verify:
        workers-per-tenant: 4          # tối đa 8
        max-parallel-tenants: 4
        page-size: 10000
        replica-lag-tolerance: 60s
        worm-full-weekday: SUNDAY
      export:
        parallel-per-replica: 2
        tmp-bucket: dh-audit-export-tmp
        expire-after: 7d
    observability:
      query:
        max-window: { logs: 7d, traces: 14d, access-logs: 31d, metrics: 31d }
        cache-ttl: 15s
        max-expression-length: 4096
        live-tail-lines-per-second: 200
      alert:
        webhook-max-batch: 100
        escalation-poll: 30s
        storm-threshold: 50           # cảnh báo mới trong 5 phút
        storm-window: 5m
      probe:
        jitter: 10s
      pii:
        cron: '0 2 * * *'
        sample-percent: 1
        cccd-province-codes: classpath:pii/province-codes.txt
      siem:
        egress-allowlist-source: configmap/egress-allowlist
```

### 9.3. Cờ tính năng

Cờ dùng OpenFeature (cùng nhà cung cấp với PH-04, PH-05), đánh giá theo tenant. Cờ tắt khẩn cấp (`obs.query.freeform`) không phụ thuộc tenant.

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `obs.query.freeform` | `true` | Cho biểu thức tự do (PromQL, TraceQL) ở API; tự tắt khi kiểm thử rò rỉ thành công (§4.13) |
| `obs.leaktest.prod` | `false` | Chạy kiểm thử rò rỉ ở PROD với tenant tổng hợp T90, T91 (Q13-27) |
| `obs.pii.quarantine` | `false` theo DU | Loại log của DU khỏi kho tra cứu khi tái phạm (§4.12), SO duyệt |
| `obs.siem.authority-export` | `false` | Bật điểm xuất cho cơ quan chuyên trách, kèm số hiệu văn bản (BR-13-034) |
| `obs.incident-report.enabled` | `false` | Mẫu báo cáo sự cố và thông báo vi phạm DLCN (FR-13-055, Đợt sau) |
| `obs.chain.close.enabled` | `false` | Đóng chuỗi khi tenant ngừng, sáp nhập (FR-13-060, Đợt sau) |
| `obs.audit.verify.worm-full-weekly` | `true` | So WORM đủ mỗi Chủ nhật; tắt chỉ khi kho WORM đang bảo trì có biên bản |
| `obs.live-tail.enabled` | `true` | Theo dõi log trực tiếp (FR-13-027) |
| `obs.detect.engine.enabled` | `true` | Engine phát hiện từ bản ghi kiểm toán; tắt chỉ trong điều tra có ghi vết |
| `obs.audit.runtime.spool` | `true` | Đĩa đệm cho `dh-runtime` (§4.2); tắt thì mọi thao tác của runtime đòi Kafka tức thì |

: Cờ tính năng của PH-13

## 10. Quan sát

PH-13 phát dữ liệu quan sát của chính nó qua cùng đường OTLP như mọi DU và không có đường riêng; cảnh báo về PH-13 nằm trong bộ luật chuẩn (`audit-*`, `obs-ingest-dropped`, `probe-failed`) và chỉ nhịp tim ngoài site bảo vệ khi toàn bộ đường quan sát hỏng (§4.19). Bảng dưới liệt kê chỉ số, nhãn và nguồn; nhãn tuân thủ danh sách cho phép ở FRS §4.8 cộng nhóm nhãn kỹ thuật có miền đóng của `du = dh-platform` và `dh-audit` (§4.11).

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `dh_audit_emitted_total`, `dh_audit_emitted_day` | counter, gauge | `du`, `tenant` (cộng `day` cho gauge) | `dh-audit` (bảng bộ đếm) |
| `dh_audit_outbox_pending` | gauge | `du`, `tenant` | `OutboxDrainMonitor` |
| `dh_audit_spool_bytes`, `dh_audit_redacted_total` | gauge, counter | `du` | `DiskSpool`, `Redactor` |
| `dh_audit_ingest_total` | counter | `result` (`ok`, `duplicate`, `quarantine_*`), `tenant` | Bộ tiếp nhận |
| `dh_audit_ingest_duration_seconds`, `dh_audit_chain_write_seconds` | histogram | `tenant` | Bộ tiếp nhận, `ChainWriter` |
| `dh_audit_consumer_lag` | gauge | `tenant` | Bộ tiếp nhận |
| `dh_audit_chain_head_seq`, `dh_audit_chain_lag_seconds` | gauge | `tenant` | `ChainStatusService` |
| `dh_audit_chain_lock_wait_seconds` | histogram | `tenant` | `TenantChainLock` |
| `dh_audit_anchor_age_seconds`, `dh_audit_anchor_total`, `dh_audit_anchor_sign_seconds` | gauge, counter, histogram | `tenant`, `result` | `AnchorService` |
| `dh_audit_worm_lag_seconds`, `dh_audit_worm_batches_total`, `dh_audit_worm_bytes_total` | gauge, counter | `tenant`, `result` | `WormBatchWriter` |
| `dh_audit_verify_duration_seconds`, `dh_audit_verify_result_total`, `dh_audit_verify_last_success_timestamp` | histogram, counter, gauge | `tenant`, `result`, `scope` | `VerificationService` |
| `dh_audit_partition_tuple_changes` | gauge | (không có nhãn) | `TamperProbe` |
| `dh_audit_reconcile_diff` | gauge | `du`, `tenant` | `ReconciliationService` |
| `dh_audit_partition_status`, `dh_audit_partition_archive_total` | gauge, counter | `status`, `result` | `PartitionManager` |
| `dh_audit_query_total`, `dh_audit_query_duration_seconds`, `dh_audit_query_rejected_total` | counter, histogram | `kind`, `result`, `reason` | `AuditSearchService` |
| `dh_audit_export_duration_seconds`, `dh_audit_export_records_total`, `dh_audit_export_total` | histogram, counter | `result` | `ExportWorker` |
| `dh_obs_trace_decision_total` | counter | `decision`, `reason` | Collector gateway |
| `dh_obs_access_dropped_total`, `dh_obs_series_active` | counter, gauge | `tenant` | APISIX, Mimir |
| `dh_obs_pii_findings_total`, `dh_obs_pii_last_scan_timestamp` | counter, gauge | `du`, `tenant` | `PiiScanner` |
| `dh_obs_query_duration_seconds`, `dh_obs_query_rejected_total` | histogram, counter | `backend`, `reason` | `internal.query` |
| `dh_obs_leaktest_result_total` | counter | `result` | `LeakTestRunner` |
| `dh_obs_logsearch_total`, `dh_obs_livetail_active`, `dh_diag_requests_total` | counter, gauge | `result` | Tra log, `DiagnosticsService` |
| `dh_obs_dashboard_duration_seconds`, `dh_obs_dashboard_nodata_total`, `dh_obs_dashboardsync_total` | histogram, counter | `view`, `result` | Bảng điều khiển |
| `dh_probe_success`, `dh_probe_duration_seconds` | gauge, histogram | `tenant`, `probe` | `SyntheticProbeRunner` |
| `dh_alert_rules`, `dh_alert_rule_publish_seconds`, `dh_alert_rule_drift_total` | gauge, histogram, counter | `scope`, `status` | `RulePublisher` |
| `dh_alert_open`, `dh_alert_webhook_total`, `dh_alert_mtta_seconds`, `dh_alert_mttr_seconds`, `dh_alert_eval_failures_total` | gauge, counter, histogram | `severity`, `result`, `tenant` | `AlertService` |
| `dh_alert_notifications_total`, `dh_alert_notify_latency_seconds`, `dh_alert_escalations_total` | counter, histogram | `channel`, `result`, `level` | `NotificationService` |
| `dh_detect_run_duration_seconds`, `dh_detect_alerts_total`, `dh_detect_skipped_total`, `dh_detect_lag_seconds` | histogram, counter, gauge | `rule`, `severity` | `DetectionEngine` |
| `dh_siem_sent_total`, `dh_siem_queue_bytes`, `dh_siem_delay_seconds` | counter, gauge | `target`, `result` | `otel-siem` |
| `dh_obs_monitoring_state`, `dh_obs_store_usage_ratio`, `dh_obs_heartbeat_age_seconds` | gauge | `store` | `MonitoringHealthService` |
| `dh_obs_provision_total`, `dh_obs_provision_step_seconds`, `dh_obs_settings_changes_total` | counter, histogram | `result`, `step` | `ObsProvisioner`, `SettingsService` |
| `dh_job_duration_seconds`, `dh_job_last_success_timestamp` | histogram, gauge | `job` | `JobRunner` |

: Chỉ số do PH-13 và dh-audit phát

Nhãn `rule`, `target`, `store`, `view`, `step` có miền đóng (số luật chuẩn cộng luật phát hiện không quá 60, số mục tiêu SIEM mỗi tenant không quá 5); nhãn `tenant` giới hạn theo số tenant (34) nên số chuỗi của PH-13 ở mức vài nghìn. `trace_id`, `user_id` không bao giờ là nhãn.

**Trace.** Mỗi lô tiếp nhận một span `audit.ingest.batch` (thuộc tính `dh.tenant`, `dh.batch.size`, `dh.batch.result`), con `audit.chain.append`, `audit.anchor.sign`, `audit.verify.segment`, `audit.export.build`, `obs.query` (thuộc tính `dh.backend`, `dh.query.kind`, không ghi biểu thức đầy đủ, chỉ băm). Lời gọi tới kho có span `client` kèm `net.peer.name`. Trace của chính thao tác tra cứu kiểm toán có `dh.audit=true` nên luôn được giữ (§4.11).

**Log.** JSON có `tenant`, `traceId`, `component`, `result`. Tuyệt đối không log: nội dung `before`, `after`, `reason` của bản ghi kiểm toán; số định danh khi tra theo đối tượng; thân yêu cầu tra cứu; nội dung dòng log người dùng tra (chỉ log độ dài và băm điều kiện). Luật R5 và bộ lọc `@Sensitive` bảo vệ; bộ quét hằng ngày (§4.12) cũng quét log của chính `dh-platform`.

**Màn hình sức khỏe.** UI-13-18 đọc `dh_audit_chain_head_seq`, `dh_audit_outbox_pending`, `dh_audit_consumer_lag`, `dh_audit_worm_lag_seconds`, `dh_audit_anchor_age_seconds`, `dh_audit_reconcile_diff`, trạng thái phân vùng và số bản cách ly; số liệu cách ly và đối chiếu lấy từ bảng trong `ph13_audit` chứ không từ chỉ số, vì phải đúng cả khi Mimir ngừng.

## 11. Hiệu năng và vận hành

### 11.1. Định cỡ và chi phí

Điều kiện đo mặc định là `QM-VUA` (200 HTTT, 5 triệu lượt gọi mỗi ngày, cao điểm 300 lượt mỗi giây, khoảng 100.000 bản ghi kiểm toán mỗi ngày mỗi tenant, GĐ-13-01, GĐ-13-02). Số liệu hạ tầng dẫn từ D03-09 §5; số của PH-13 dưới đây là phần thêm vào `dh-platform` và là giả định có cơ sở, cần đo bằng bộ kiểm thử hiệu năng ở §12.

| Hạng mục | Tính toán | Kết quả, giả định |
|---|---|---|
| Ghi chuỗi | Một tenant: 100.000 bản ghi mỗi ngày là 1,2 bản ghi mỗi giây trung bình, cao điểm gấp 10 lần là 12 bản ghi mỗi giây. Một lô 500 bản ghi: tính 500 băm cộng 500 `INSERT` | Giả định 20 đến 40 ms mỗi lô: dư hơn 10.000 bản ghi mỗi giây mỗi tenant; chỉ tiêu toàn nền tảng 1.000 bản ghi mỗi giây (NFR-13-008) là cận trên của khóa tuần tự mỗi tenant, không phải của máy chủ |
| Độ trễ Kafka tới cam kết | Chờ lô 50 ms, ghi 30 ms | p95 dưới 1 giây, mục tiêu p95 ≤ 2 giây |
| Kiểm tra toàn vẹn một tenant | 36,5 triệu bản ghi; giả định 60 µs mỗi bản ghi (đọc, dựng JCS, SHA-256) | Khoảng 2.200 giây một lõi, khoảng 9 phút với 4 luồng: đạt 60 phút của NFR-13-010 (GĐ-13-S1, đo bằng JMH) |
| Kiểm tra hằng ngày toàn nền tảng | 34 tenant, mỗi tenant `QM-VUA` (cận trên): 34 × 38 phút lõi | Khoảng 21 giờ lõi: 4 lõi ở vai trò `jobs` làm xong trong khoảng 5 đến 6 giờ từ 03:00 (Q13-20); hồ sơ `QM-VUA` một tenant chỉ cần vài phút |
| Dung lượng bảng kiểm toán | 36,5 triệu bản ghi, 1,5 KB, một năm | Khoảng 55 GB mỗi năm mỗi tenant (GĐ-13-01), cộng chỉ mục; phần lớn của `pg-core` (D03-01 §4.1) |
| Dung lượng WORM | Nén `zstd` | Khoảng 20 GB mỗi năm `QM-NHO`, 60 GB `QM-VUA` (D03-09 §5) |
| Lượt gọi API | 5 triệu bản ghi mỗi ngày | Khoảng 130 GB nén mỗi tenant sau 12 tháng; ClickHouse 2 × 4 vCPU ở `QM-VUA` (D03-09 §5.3) |
| Thông lượng Collector | 50.000 mẫu, 20.000 dòng log, 5.000 span mỗi giây | Gateway 3 bản sao; `tail_sampling` giữ trace chờ 30 giây, tối đa 500.000 trace (khoảng 1 đến 2 GiB mỗi bản sao) |
| `dh-platform` phần PH-13 | Ghi chuỗi, truy vấn, bộ nền | Cộng khoảng 0,5 vCPU và 1 GiB mỗi bản sao vào định cỡ `dh-platform` `QM-VUA` (2 × 1,5/3 vCPU, D03-09 §5); `QM-LON`, `QM-CHUNG` tách vai trò `ingest`, `api`, `jobs` thành Deployment riêng |

: Định cỡ và chi phí của PH-13

Các con số dựa trên giả định thiết kế dưới đây (cùng cách ghi giả định có cơ sở như GĐ-13-01…08 của FRS), cập nhật bằng cách đo ở tỉnh thí điểm rồi chỉnh tham số, không đổi kiến trúc.

| Mã | Giả định | Cơ sở |
|---|---|---|
| GĐ-13-S1 | Đọc, dựng JCS và tính SHA-256 một bản ghi 1,5 KB mất khoảng 60 µs | JCS khoảng 30 µs, giải mã JDBC khoảng 20 µs, SHA-256 vài µs với tập lệnh phần cứng; chờ đo JMH |
| GĐ-13-S2 | Một lô 500 bản ghi ghi chuỗi mất 20 đến 40 ms | `INSERT` theo lô 10 đến 20 ms cộng 500 băm khoảng 20 ms |
| GĐ-13-S3 | 34 tenant đều ở mức `QM-VUA` là cận trên của tải kiểm tra | NFR-00-060 (≥ 34 tenant) và GĐ-07; thực tế có tenant nhỏ hơn |
| GĐ-13-S4 | Mỗi tenant có hoạt động tạo tối đa 288 đối tượng WORM mỗi ngày | Lô 5 phút, lô rỗng không tạo đối tượng |
| GĐ-13-S5 | Khoảng tối đa mỗi lần tra: log 7 ngày, trace 14 ngày, lượt gọi API và chỉ số 31 ngày | Thời hạn lưu từng kho và độ nặng truy vấn; chỉnh ở §9.2 |

: Giả định thiết kế của PH-13

Ba vai trò chạy từ cùng một ảnh theo biến `dh.role`: `api` (REST, SSE), `ingest` (consumer Kafka, kênh dự phòng) và `jobs` (mọi công việc nền ở §11.2). Hồ sơ `QM-NHO`, `QM-VUA` bật cả ba vai trò trên mỗi bản sao; `QM-LON`, `QM-CHUNG` tách thành ba Deployment để việc kiểm tra toàn vẹn và xuất bằng chứng không tranh CPU với API, và để PH-13 co giãn độc lập với PH-11, 12, 16, 18, 20 cùng DU (đề nghị cho D03-09).

### 11.2. Công việc nền theo lịch

Mọi công việc đi qua `JobRunner`: bọc `TenantContext.runAs`, lấy `JobLock` theo cặp (công việc, tenant) (bảng `job_lock`, nhà cung cấp JDBC; mỗi cặp một bản sao chạy một lần nên nhiều bản sao `jobs` chia nhau các tenant) và đo `dh_job_duration_seconds{job}`. Công việc theo tenant chạy lặp từng tenant và lỗi của một tenant không dừng các tenant khác.

| # | Công việc | Lịch | Ghi chú |
|---|---|---|---|
| 1 | Neo băm (`AnchorScheduler`) | Mỗi phút xét, neo mỗi `13.audit.anchor-interval-minutes` | §4.5 |
| 2 | Sao lô WORM (`WormBatchWriter`) | Mỗi `13.audit.worm-batch-minutes` | §4.6 |
| 3 | Kiểm tra toàn vẹn hằng ngày (`VerificationService`) | `13.audit.verify-cron` (03:00) | Toàn chuỗi trực tuyến, §4.7 |
| 4 | So WORM đủ | Chủ nhật 03:00 | Cờ `obs.audit.verify.worm-full-weekly` |
| 5 | Thăm dò can thiệp (`TamperProbe`) | Mỗi phút | `pg_stat_user_tables`, so đầu chuỗi |
| 6 | Đối chiếu số lượng (`ReconciliationService`) | 01:00 | Ngày hôm trước, §4.8 |
| 7 | Quản lý phân vùng (`PartitionManager`) | Ngày 1 lúc 03:00; xét lưu trữ hằng ngày 03:30 | §4.8 |
| 8 | Dọn gói bằng chứng (`ExportJanitor`) | Mỗi giờ | Hết hạn 7 ngày |
| 9 | Engine phát hiện (`DetectionEngine`) | Mỗi phút | Chạy bù theo bước 5 phút |
| 10 | Leo thang (`EscalationScheduler`) | Mỗi 30 giây | Cập nhật có điều kiện |
| 11 | Bộ gửi thông báo (`NotificationDispatcher`) | Thăm dò mỗi giây | `SKIP LOCKED` |
| 12 | Kiểm tra tổng hợp (`SyntheticProbeRunner`) | `13.probe.interval-seconds` | Luồng ảo, lệch ngẫu nhiên |
| 13 | Quét dữ liệu cá nhân (`PiiScanner`) | 02:00 | §4.12 |
| 14 | Ngưỡng lấy mẫu trace (`SamplingThresholdPublisher`) | 02:00 | Cuộn gateway từng pod |
| 15 | Kho nén log an ninh (`SecurityLogArchiver`) | 04:00 | §4.11 |
| 16 | Kiểm thử rò rỉ (`LeakTestRunner`) | 04:30 | Môi trường thử, cổng phát hành |
| 17 | Đối soát luật và overrides (`RuleReconciler`, `OverridesReconciler`) | Mỗi 5 phút | Tự lành |
| 18 | Tự giám sát (`MonitoringHealthService`, `CapacityWatcher`) | 15 giây; 5 phút | §4.19 |

: Công việc nền theo lịch của PH-13

### 11.3. Vận hành và sổ tay

Sổ tay vận hành (D06-03) gồm các quy trình sau, mỗi quy trình có kiểm tra "xong khi":

- **Chuỗi `SUSPECT`.** Đọc kết quả kiểm tra và bản chứng cứ ở `dh-evidence`, xác định loại lỗi, phối hợp ATTT theo playbook (D03-07 §8), ghi kết luận cho cảnh báo an ninh, chạy lượt kiểm tra mới trên đoạn sau điểm đứt. Không có lệnh sửa chuỗi.
- **Kho WORM ngừng.** Theo dõi `dh_audit_worm_lag_seconds`; bản ghi vẫn ghi vào bảng và neo vẫn có ở bảng; khi kho trở lại, sao bù tuần tự; chưa xong thì không lưu trữ phân vùng (ERR-13-125).
- **Xoay khóa ký `dh-audit-sign`.** Tạo phiên bản mới ở OpenBao, `AnchorService` ghi khóa công khai vào `audit_signing_key` và WORM; neo mới mang `key_version` mới; giữ khóa công khai mọi phiên bản.
- **Nâng thời hạn WORM.** Đặt `13.audit.worm-retention-years`, chạy lệnh gia hạn cho lô còn hạn qua tài khoản `worm-retention`; không bao giờ rút ngắn.
- **Thêm tenant, thêm mục tiêu SIEM.** Qua `ObsProvisioner` và `SiemPipelineRenderer`; kiểm tra cuộn gateway và `otel-siem` xong, dữ liệu không còn nhãn `_unattributed`.
- **Chuyển site DR (ADR-034).** `pg-core` bản sao nâng lên, bucket WORM nằm ở site DR (D03-09 §8), Kafka giữ bản ghi 7 ngày; sau chuyển, đối chiếu số lượng chạy ngay và cho kết quả `MATCH` trước khi coi nhật ký đầy đủ. RPO kiểm toán ≤ 5 phút (lô WORM gần nhất), RTO ≤ 4 giờ theo control plane (NFR-13-012).
- **Dọn rác.** Tác vụ đêm đối soát đối tượng WORM mồ côi, replication slot không dùng, kho tạm hết hạn.
- **Đồng bộ D03-09.** Đề nghị thêm Deployment `otel-siem`, `alert-relay`, định cỡ ba vai trò của `dh-platform` và bộ nhận nhịp tim ở mục "Đề nghị đồng bộ".

### 11.4. Khả năng mở rộng

Thiết kế mở rộng theo hai hướng: tăng tải (nhiều tenant, nhiều bản ghi) mà không đổi kiến trúc, và thêm khả năng mới (kênh, luật, đích SIEM, thuật toán băm) bằng điểm mở rộng có tên. Bảng đầu nêu từng thành phần co giãn thế nào và giới hạn ở đâu; bảng sau nêu điểm mở rộng.

| Thành phần | Cách co giãn | Giới hạn và việc cần làm khi chạm giới hạn |
|---|---|---|
| Bộ tiếp nhận kiểm toán | Thêm bản sao `ingest` tới số phân vùng của các topic tenant; mỗi tenant tuần tự nhờ khóa tư vấn, các tenant song song | Một tenant ghi tối đa khoảng 10.000 bản ghi mỗi giây (GĐ-13-S2); vượt thì tách chuỗi con theo DU nguồn kèm neo gộp (cần ADR, chưa cần ở `QM-VUA`, `QM-LON`) |
| Chuỗi và bảng kiểm toán | Phân vùng tháng; thêm tenant chỉ thêm hàng; bản sao đọc cho truy vấn nặng và kiểm tra | Bảng dùng chung tăng theo tổng số tenant; phân vùng con theo nhóm tenant ở Đợt sau (R-13-07); `DEDICATED_DB` cho tenant cấp độ 4 (SEC-92) |
| Kiểm tra toàn vẹn | Chia theo đoạn neo và theo tenant; thêm bản sao `jobs` vì khóa theo (công việc, tenant) | 34 tenant mức `QM-VUA` cần khoảng 21 giờ lõi mỗi ngày (Q13-20); nhiều hơn thì tăng lõi hoặc kiểm tra theo vòng 2 ngày kèm chấp nhận chậm phát hiện |
| Sao WORM | Song song theo tenant, một lô một đối tượng | Số đối tượng (Q13-23); tăng `13.audit.worm-batch-minutes` |
| Gateway Collector | Thêm bản sao; `loadbalancing` theo `traceID` tự chia | `tail_sampling` giữ trace trong bộ nhớ: tối đa 500.000 trace mỗi bản sao |
| Mimir, Loki, Tempo | Mở rộng theo thành phần (ingester, querier, compactor) và theo hạn mức mỗi org | Số chuỗi mỗi tenant 250.000 mặc định, nâng tới 2.000.000 có phê duyệt của PA (§4.22) |
| ClickHouse | Thêm shard và bản sao; khóa sắp xếp có `tenant_id` đầu tiên | `QM-CHUNG` 3 shard (D03-09 §5); đổi sang phân vùng theo tháng nếu quá 12 tháng trên mỗi tenant |
| Cổng truy vấn, bảng điều khiển | Không trạng thái, thêm bản sao `api`; đệm 15 giây | Giới hạn truy vấn đồng thời mỗi người; quy tắc ghi lại cho truy vấn nặng |
| Công việc nền | Khóa theo (công việc, tenant) nên chia đều theo số bản sao `jobs` | Công việc theo phút (phát hiện, thăm dò) nặng dần theo tenant; tách Deployment `jobs` ở `QM-LON` |
| Alertmanager, `alert-relay` | Cụm Alertmanager 3 bản sao; `alert-relay` không trạng thái | Cấu hình toàn cục định tuyến theo nhãn `tenant`; chuyển Alertmanager đa tenant của Mimir nếu cần cách ly cấu hình thông báo từng tenant (ADR số 014) |

: Co giãn của các thành phần PH-13

| Điểm mở rộng | Cách thêm | Ràng buộc |
|---|---|---|
| Kênh thông báo mới | Hiện thực giao diện `NotificationChannelAdapter` và đăng ký vào `ChannelRegistry`; thêm giá trị `kind` | Không đổi máy trạng thái cảnh báo; bí mật ở OpenBao; qua danh sách FQDN cho phép |
| Luật phát hiện mới | Luật theo chỉ số: thêm tệp luật vào danh mục `UC-SEC`; luật theo bản ghi: thêm truy vấn có tên vào `AuditDetectionQueryApi` kèm ca kiểm thử sinh sự kiện giả (SEC-64) | D03-07 §7.5 là nguồn danh sách luật; ngưỡng và biên tinh chỉnh khai báo cùng luật |
| Đích SIEM, lược đồ mới | Thêm bộ ánh xạ vào `SiemPipelineRenderer` (ví dụ lược đồ OCSF phiên bản mới) | Phải loại dữ liệu cá nhân theo danh sách khóa cho phép |
| Luật chuẩn, bộ dashboard | Thêm tệp vào kho cấu hình; CI kiểm `promtool`, runbook năm mục, `symptom` của luật `CRITICAL` | Mã luật không dùng lại (BR-13-031) |
| Thuật toán băm, định dạng bản ghi | Trường `v` trong bản ghi chuẩn tắc chọn thuật toán; bản ghi cũ giữ phiên bản cũ, bộ kiểm tra chọn theo `v` | Bộ vector cố định cho từng phiên bản; không đổi băm bản ghi đã ghi |
| Nguồn kiểm toán mới | DU chỉ cần dùng `dh-audit`, cấp `audit_source_grant` và khóa `audit-mac/{du}`, tạo topic qua GitOps | Bộ đếm `dh_audit_emitted_*` bắt buộc để đối chiếu |
| Loại dữ liệu quan sát mới | Thêm đường ống ở gateway và nhóm nhãn vào danh sách cho phép | Phải qua `redaction`, nhãn có miền đóng, hạn mức chuỗi |

: Điểm mở rộng của PH-13

## 12. Kiểm thử

Kiểm thử của PH-13 có ba nhóm nặng hơn các phân hệ khác: chứng minh chuỗi băm phát hiện được can thiệp, chứng minh không mất bản ghi khi các thành phần ngừng, và chứng minh cách ly tenant ở mọi kho. Ca kiểm thử chi tiết và mã `TC` ở D05-02-PH13; bảng dưới là chiến lược theo mức.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Invariant các aggregate; `CanonicalJson` và `HashCalculator` với bộ vector cố định 20 bản ghi; `SimpleQueryCompiler` (ca tiêm chuỗi, dấu nháy, dấu huyền); `ExpressionGuard`; `ScheduleValidator` mô phỏng 168 giờ; `SeverityPolicy`; bảng chuyển trạng thái của `Alert`, `SecurityAlert`, `AlertRule`, `ExportRequest`; `TimeBreakdown`; `Redactor` và `SensitiveScanner` trên kho mẫu | JUnit 5, jqwik |
| Thuộc tính | `JCS(đọc từ jsonb(JCS(x))) = JCS(x)`; seq liên tục sau mọi hoán vị lô; khử trùng lũy đẳng; băm tính ở Java trùng băm tính ở script xác minh | jqwik |
| Kiến trúc | Luật R1 đến R8 ở §3.6; cấm log `AuditEntry`; mọi controller có quyền | ArchUnit, Semgrep (CI-3) |
| Tích hợp | PostgreSQL 18 có RLS, trigger, phân vùng, vai trò; Kafka; OpenBao dev (transit `sign`, `hmac`, database engine); MinIO có Object Lock (nhanh) và Ceph RGW trên kind (ban đêm); Mimir, Loki, Tempo, ClickHouse, Alertmanager, Grafana | Testcontainers, Rook trên kind |
| Chuỗi và toàn vẹn | `UPDATE`, `DELETE`, `TRUNCATE` bị trigger chặn; vô hiệu trigger bằng quản trị rồi sửa một bản ghi, đổi `seq`, xóa bản ghi, đổi chữ ký neo, sửa lô WORM thử nghiệm: từng ca phải ra đúng `BreakKind` và thời gian phát hiện (đồng hồ bơm giả) ≤ 24 giờ, ≤ 1 giờ cho đoạn mới | Testcontainers, đồng hồ tiêm |
| Hỗn loạn | Tắt `dh-platform`, Kafka, PostgreSQL, OpenBao, WORM tới 4 giờ trong lúc ghi 1 triệu bản ghi; giết pod, giết broker: 0 mất, đối chiếu `diff = 0` (NFR-13-011) | Chaos Mesh trên kind |
| Hiệu năng | Ghi chuỗi 1.000 bản ghi mỗi giây nhiều tenant; JMH cho `CanonicalJson`, `HashCalculator`, `SegmentVerifier` (xác nhận 60 µs mỗi bản ghi, GĐ-13-S1); kiểm tra 36,5 triệu bản ghi trong 60 phút; ClickHouse 5 triệu lượt mỗi ngày; Collector 50.000 mẫu, 20.000 dòng, 5.000 span mỗi giây; kiểm thử số chuỗi 250.000 | Gatling, JMH, k6 |
| Rò rỉ | T90 đọc T91 qua mọi API, Grafana và truy vấn thô vào Mimir, Loki, Tempo, ClickHouse, PostgreSQL, WORM: mọi lần bị từ chối | `LeakTestRunner`, D05-04 |
| Che dữ liệu | Số định danh giả (canary) bơm vào log, trace, chỉ số và bản ghi kiểm toán: phải bị che hoặc cách ly; bộ quét tìm thấy 0 sau 7 ngày | Bộ canary |
| Phát hiện | Mỗi luật UC-SEC có ca sinh sự kiện giả, đo MTTD ≤ 5 phút cho mức Nghiêm trọng (SEC-64, KPI-15) | Bộ sinh sự kiện |
| Cảnh báo đầu cuối | Ngắt API đích: cảnh báo `CRITICAL` tới người trực ≤ 5 phút, thông báo ≤ 60 giây từ `FIRING`, leo thang đúng 15 phút; 20 pod cùng lỗi gom một thông báo; cảnh báo đang mở không gửi lại | Chaos Mesh, hộp thư và SMS giả |
| Xác minh ngoại tuyến | Chạy `verify.py` trong container sạch với gói mẫu 1 triệu bản ghi: kết quả trùng Java; sửa một byte thì báo sai | Docker |
| Hợp đồng | OpenAPI, AsyncAPI, lược đồ `audit-event.v1` tương thích ngược ở Apicurio | Spectral, oasdiff (CI-5) |
| DR | Diễn tập hằng quý: chuyển site, đối chiếu số lượng `MATCH`, kiểm tra toàn vẹn đạt (ADR-034) | Diễn tập D03-09 |

: Chiến lược kiểm thử PH-13

Bảng sau nối mười tiêu chí chấp nhận cấp phân hệ (FRS chương 14) với bài kiểm thử thiết kế phụ trách, để D05-02-PH13 viết ca không bỏ sót.

| Tiêu chí FRS | Bài kiểm thử chính |
|---|---|
| 1 FR mức M có ca dương, âm; rò rỉ chéo tenant mọi API | Bộ ca theo FR; kiểm thử rò rỉ |
| 2 Đối chiếu 7 ngày `diff = 0`; tắt PH-13 hai giờ không mất | Hỗn loạn; đối chiếu ban đêm |
| 3 MTTD 5 phút, thông báo 60 giây, leo thang 15 phút, p95 chỉ số 30 giây | Cảnh báo đầu cuối |
| 4 Runbook 100%, tạo luật thiếu runbook bị từ chối, gom 20 pod | Đơn vị `RuleValidator`; cảnh báo đầu cuối |
| 5 Chín chặng hiện đủ thác nước; giữ đủ 50 trace lỗi trong 1.000 | Tích hợp Collector và Tempo; thống kê `dh_obs_trace_decision_total` |
| 6 Sửa trực tiếp bị phát hiện, `UPDATE`, `DELETE` bị chặn, WORM từ chối sửa | Chuỗi và toàn vẹn |
| 7 0 giá trị Nhạy cảm sau 7 ngày | Che dữ liệu |
| 8 T90 đọc T91 bị từ chối ở mọi kho | Rò rỉ |
| 9 Tắt `dh-platform` và LGTM 24 giờ, data plane không lỗi | Hỗn loạn mức hạ tầng (D05-04) |
| 10 Xuất bằng chứng 1 triệu bản ghi ≤ 15 phút, xác minh ngoại tuyến đạt | Hiệu năng; xác minh ngoại tuyến |

: Tiêu chí chấp nhận và bài kiểm thử

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Đường kiểm toán và đường quan sát độc lập nên hai nhóm kỹ sư làm song song từ bước 1 và 4. Bước 1 và 2 là điều kiện của mọi phân hệ có kiểm toán nên ưu tiên trước.

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| 1 | Khung module `audit`, thư viện `dh-audit-spring`, bảng, bộ tiếp nhận, `ChainWriter`, API dự phòng, đối chiếu số lượng, tra cứu cơ bản | D03-03-PH13, OpenBao transit, topic của PH-10 |
| 2 | Neo, sao WORM, kiểm tra toàn vẹn, `TamperProbe`, `BreakHandler`, quản lý phân vùng | Ceph RGW có Object Lock (Q13-23), bản sao đọc `pg-core` |
| 3 | Tra theo đối tượng, xuất bằng chứng, lịch sử cho phân hệ khác, truy cập liên tenant, `dh-audit-runtime` | Bước 1, 2; PH-12 (`recordCrossTenant`); PH-14 (Q13-21) |
| 4 | Tuyến thu thập (Collector agent, gateway, Mimir, Loki, Tempo, ClickHouse), che, lấy mẫu đuôi, gắn tenant, chỉ số hạ tầng | D03-09 `dh-obs`, `dh-olap`; PH-03 `kafka-logger` |
| 5 | Cổng truy vấn, tra log, trace, truy cập API, bảng điều khiển UI-13-01…09 | Bước 4; D03-06-PH13 |
| 6 | Luật cảnh báo, bộ luật chuẩn, webhook, thông báo, lịch trực, leo thang, `alert-relay`, `Watchdog` | Bước 4; PH-18 `NotificationApi`; Q13-24 |
| 7 | Phát hiện an ninh, SIEM (`otel-siem`), quét dữ liệu cá nhân, kiểm thử rò rỉ | Bước 1, 4, 6; SIEM tỉnh thí điểm |
| 8 | Khởi tạo tenant, tham số, hạn mức, tích hợp saga PH-20 | Bước 1 đến 7; PH-20 |
| 9 | Đợt sau: báo cáo sự cố (FR-13-055), đóng chuỗi (FR-13-060), chứng thư số công cộng cho gói bằng chứng (Q13-13), phân vùng con theo nhóm tenant | Văn bản hướng dẫn; Q13-10 |

: Lộ trình hiện thực PH-13

### 13.2. Rủi ro

Bảng dưới liệt kê rủi ro kỹ thuật của thiết kế, mức độ và cách giảm thiểu; rủi ro có câu hỏi mở đi kèm thì ghi mã câu hỏi.

| Mã | Rủi ro | Mức | Giảm thiểu |
|---|---|---|---|
| R-13-01 | OpenBao ngừng nên không ký được neo, không băm được khóa tra cứu, không ký được gói | Cao | Neo làm lại, cảnh báo sau 3 giờ; bản ghi vẫn nằm ở bảng và WORM; HA 3 nút (D03-09) |
| R-13-02 | Kiểm tra toàn bộ chuỗi hằng ngày tốn CPU ở `QM-CHUNG` (khoảng 21 giờ lõi mỗi ngày) | Trung bình | Vai trò `jobs` tách, 4 đến 8 lõi, xếp tenant theo hàng đợi; Q13-20 |
| R-13-03 | Đĩa đệm của `dh-runtime` (`emptyDir`) mất khi pod bị xóa lúc Kafka không với tới | Trung bình | Chỉ cho thao tác thường; đối chiếu số lượng phát hiện; Q13-21 |
| R-13-04 | Hàng triệu đối tượng nhỏ trên WORM (3,6 triệu mỗi năm) làm RGW chậm | Trung bình | Lô rỗng không tạo đối tượng; tăng `13.audit.worm-batch-minutes`; Q13-23 |
| R-13-05 | Băm chuẩn tắc lệch giữa Java, SQL và script xác minh (số thập phân, Unicode) | Cao | Chỉ chuỗi, số nguyên ±2^53, boolean trong bản ghi; bộ vector cố định chạy ở cả ba nơi; kiểm thử thuộc tính |
| R-13-06 | Thêm tenant hoặc đổi tham số Collector phải cuộn gateway (dữ liệu `_unattributed` 2 đến 3 phút) | Thấp | Chỉ nền tảng thấy dữ liệu đó; Q13-26 xem xét OrgID động |
| R-13-07 | Phân vùng tháng dùng chung giữ theo `online-months` lớn nhất của các tenant | Thấp | Chấp nhận ở MVP; chuyển phân vùng con theo nhóm tenant ở Đợt sau |
| R-13-08 | Bùng nổ số chuỗi vì DU phát nhãn lạ | Trung bình | Bộ lọc nhãn ở gateway, hạn mức Mimir, cảnh báo 85%, kiểm thử cardinality |
| R-13-09 | Bộ quét Nhạy cảm cách ly nhầm bản ghi hợp lệ, làm mất khả năng tra cứu | Trung bình | Chỉ quét giá trị chuỗi, bỏ `object_id`, danh sách ngoại lệ theo (DU, action), DU gửi lại cùng `id` |
| R-13-10 | Chưa có bộ nhận nhịp tim ngoài site ở `HT-A` thì hỏng toàn bộ giám sát không bị phát hiện | Cao | Chọn trước khi vận hành thật (Q13-24); ghi vào hồ sơ chấp nhận rủi ro của tỉnh nếu chưa có |
| R-13-11 | Cấu hình sai `tenant_federation` làm tenant đọc được tổ chức khác | Cao | Cấu hình khai báo bằng Git, kiểm thử rò rỉ hằng ngày, cờ tắt biểu thức tự do |
| R-13-12 | Hộp thư đi của DU phình khi PH-13 ngừng dài | Trung bình | Cảnh báo ở 1.000 bản ghi và 1 triệu bản ghi; Kafka giữ 7 ngày; bản ghi gửi bù tuần tự |

: Rủi ro

### 13.3. Câu hỏi mở

Các câu hỏi dưới đây phát sinh khi thiết kế (dải Q13-20…29 của tập SDD); câu hỏi của FRS Q13-01…19 vẫn có hiệu lực. Mỗi câu nêu giả định đang dùng.

> **Câu hỏi mở Q13-20:** Kiểm tra toàn vẹn hằng ngày kiểm lại **toàn bộ** chuỗi trực tuyến thay vì chỉ từ neo gần nhất (§4.7) để đạt NFR-13-016. Với 34 tenant mức `QM-VUA` cần khoảng 21 giờ lõi mỗi ngày; cần xác nhận cấp thêm 4 đến 8 lõi cho vai trò `jobs` ở `QM-CHUNG` và đồng ý chỉnh FR-13-014 bước 1. Giả định: chấp nhận, đo lại bằng JMH ở tỉnh thí điểm (GĐ-13-S1).

> **Câu hỏi mở Q13-21:** `dh-runtime` ghi kiểm toán trực tiếp lên Kafka `acks=all`, có đĩa đệm `emptyDir` 1 GB cho thao tác thường và từ chối thao tác Nhạy cảm khi không ghi vết được (đóng Q13-03). PH-14 cần xác nhận cách này đủ cho tra cứu CSDL quốc gia và chấp nhận rủi ro mất bản ghi khi pod bị xóa lúc Kafka không với tới. Giả định: chấp nhận ở MVP.

> **Câu hỏi mở Q13-22:** Thư viện `dh-audit` đặt ở `libs/dh-audit` với tên gói `vn.datahub.common.audit` và hai artifact (`dh-audit-spring`, `dh-audit-runtime`); D04-01 cần chốt tên gói và vị trí. Giả định: như trên, theo mô hình `libs/common-java` hiện có.

> **Câu hỏi mở Q13-23:** Ceph RGW của site DR có hỗ trợ Object Lock chế độ tuân thủ với versioning, tách quyền `PutObject` và `PutObjectRetention` giữa hai tài khoản, và chịu được khoảng 3,6 triệu đối tượng nhỏ mỗi năm cho 34 tenant không. Giả định: có; nếu không, tăng `13.audit.worm-batch-minutes` tới 15 phút (RPO tăng tương ứng).

> **Câu hỏi mở Q13-24:** Sản phẩm và vị trí của bộ nhận nhịp tim ngoài site cho hồ sơ `HT-A` (dịch vụ tự lưu trữ như Healthchecks ở site khác của chủ quản, hay dịch vụ của nhà cung cấp nền tảng). Giả định: `HT-B` dùng bộ nhận của nhà cung cấp nền tảng, `HT-A` đặt ở site DR của tỉnh.

> **Câu hỏi mở Q13-25:** `ExpressionGuard` dùng bộ tách từ tự viết hay sidecar nhỏ dựng từ bộ phân tích cú pháp của Prometheus để phân tích đầy đủ PromQL và TraceQL. Giả định: bộ tách từ tự viết, vì bức tường thật là OrgID; ATTT quyết định khi rà soát thiết kế.

> **Câu hỏi mở Q13-26:** Collector gateway đặt OrgID theo tenant bằng bộ định tuyến tĩnh (thêm tenant hay đổi tham số lấy mẫu phải cuộn lại, hiệu lực ≤ 3 phút, lệch NFR-13-030), hay bằng phiên bản Collector hỗ trợ đặt OrgID động theo thuộc tính (hoặc OpAMP) để đạt ≤ 60 giây. Giả định: bộ định tuyến tĩnh ở MVP.

> **Câu hỏi mở Q13-27:** Có cho tạo hai tenant tổng hợp T90, T91 ở PROD để chạy kiểm thử rò rỉ hằng ngày (cờ `obs.leaktest.prod`), hay chỉ chạy ở môi trường thử và làm cổng phát hành (SEC-87 chỉ nói môi trường thử). Giả định: chỉ môi trường thử ở MVP.

### 13.4. Đề nghị đồng bộ cho tài liệu khác

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu dùng chung và không tạo ADR; bảng dưới là danh sách việc cho các luồng khác. Các đề nghị của FRS §12.4 (quyền, SRS, D03-07 §7.3, D03-10, D03-06-00, D03-05, D00-04) vẫn có hiệu lực và không lặp lại.

| Tài liệu | Đề nghị |
|---|---|
| D03-03-PH13 (CSDL) | Bảng phát sinh ở thiết kế: `audit_quarantine`, `audit_worm_batch`, `audit_anchor_publish` (tách `worm_object`, `siem_ack_at` khỏi `audit_anchor` để bảng neo thuần chỉ-thêm), `audit_signing_key`, `audit_source_grant`, `detect_cursor`, `pii_finding`, `job_lock`; bảng `audit_outbox`, `audit_emit_counter` (16 mảnh) trong schema của mỗi DU do thư viện tạo. Cột mới: `audit_chain.integrity` (`OK`, `SUSPECT`), `suspect_from_seq`, `last_recorded_at`; `audit_event.clock_skew`; `audit_anchor.kind` (`HOURLY`, `BOUNDARY`, `FINAL`); `tenant_obs_config.provision_state`. Ràng buộc: duy nhất `(tenant_id, seq, recorded_at)` vì khóa phân vùng; chỉ mục `(tenant_id, id)` từng phân vùng cho khử trùng, `(tenant_id, source_du, occurred_at)` cho đối chiếu, `(tenant_id, trace_id)`, `(tenant_id, object_key_hmac)`, `(tenant_id, object_type, object_id, recorded_at)`; chỉ mục duy nhất từng phần cho lượt kiểm tra `RUNNING` và yêu cầu xuất theo `scope_hash`. DDL ClickHouse `access_log`, `access_log_rejected`, hai view vật chất hóa |
| D03-04-PH13 (API, AsyncAPI) | Tiêu đề `dh-du`, `dh-kid`, `dh-mac` trong lược đồ `audit-event.v1` và quy tắc ký (§4.2); API-13-089 lấy danh tính DU từ scope; hành động kiểm toán mới: `AUDIT.QUERY.RESULT`, `AUDIT.WORM.EXPIRE`, `OBS.SETTINGS.UPDATE`, `OBS.CROSS_TENANT_ACCESS`, `SECURITY.ALERT.PROPOSE_SUSPENSION`; lời gọi `recordCrossTenant` ghi hai chuỗi |
| D02-03-PH13 (FRS) | FR-13-014 bước 1: lượt `DAILY` kiểm lại toàn bộ chuỗi trực tuyến, tầng gia tăng mỗi lần neo; FR-13-010 bước 2: danh tính DU bằng `dh-mac` kết hợp ACL, vì Kafka không cho người tiêu thụ đọc danh tính người sản xuất; FRS §4.8: thêm nhóm nhãn kỹ thuật có miền đóng (`result`, `decision`, `reason`, `backend`, `channel`, `probe`, `step`, `day`) cho `du = dh-platform` và `dh-audit`; EN-13-02: tách cột công bố; EN-13-21 và FR-13-018: phân vùng chung theo tháng, lưu trữ khi mọi tenant đủ điều kiện; NFR-13-030: ngoại lệ ≤ 3 phút cho tham số tác động Collector; FRS §2.4: bộ xuất SIEM là Deployment `otel-siem`, thêm `alert-relay`; FR-13-043: nguồn luật chuẩn là ConfigMap do Argo CD triển khai; FR-13-019: thêm các hành động ở dòng trên |
| D03-09 (hạ tầng) | Deployment `otel-siem` (2 bản sao) và `alert-relay` (2 bản sao) ở `dh-obs`; ba vai trò của `dh-platform` ở `QM-LON`, `QM-CHUNG` và định cỡ phần PH-13 (§11.1); bản sao đọc `pg-core` cho `ph13_verify`; bucket `dh-evidence` (Ceph RGW Object Lock), `dh-seclog-archive` (Garage, vòng đời 3 năm), `dh-audit-export-tmp` (Garage, vòng đời 7 ngày); topic `{tenant}.obs.audit.recorded.v1` giữ 7 ngày, `{tenant}.obs.access.logged.v1` giữ 3 ngày; bộ nhận nhịp tim ngoài site; ghi rõ lô WORM 5 phút và neo hằng giờ thay cho "lô hằng giờ" ở D03-01 §4.1 và D03-09 §8 |
| D03-07 (ATTT) | SEC-60: tiêu đề `dh-mac` và khóa nguồn `audit-mac/{du}`; §7.2: tiền tố tên miền của chữ ký neo và gói bằng chứng; SEC-34: thêm khóa `audit-mac/{du}` và khóa HMAC theo tenant; SEC-75: bucket chứng cứ ở Ceph RGW (Garage không có Object Lock) |
| D04-01 (quy ước mã) | Tên gói `vn.datahub.common.audit` (Q13-22); quy tắc `AuditEntry` chỉ gồm chuỗi, số nguyên ±2^53, boolean (§3.5); luật R1 đến R8 |
| D04-02 (quy trình kỹ thuật) | CI-3 thêm luật R1 đến R8, Semgrep cấm `UPDATE`, `DELETE` trên `ph13_audit.audit_event`; kho cấu hình luật chạy `promtool check rules` và kiểm runbook năm mục |
| D03-02-PH07, D03-02-PH19 | Bản ghi kiểm toán dùng `OutboxRelay` có xác nhận của `dh-audit` thay cho Debezium (hoặc đo tồn đọng bằng độ trễ replication slot) và bộ đếm `audit_emit_counter` trong giao dịch |
| PH-04, PH-14, PH-12, PH-18, PH-20, PH-03 | PH-04: Kamelet `dh-audit-sink` gọi `KafkaAuditSender`; PH-14: xác nhận Q13-21; PH-12: `PermissionApi`, `StepUpApi`, gọi `recordCrossTenant`; PH-18: `NotificationApi`, gọi `DiagnosticsApi`; PH-20: `TenantObservabilityApi` và sổ bước S1 đến S6; PH-03: `kafka-logger` mọi route |
| ADR (đề xuất, không tạo ở tập này) | Số trống ở dải lõi và ATTT: **ADR số 039** (dải ATTT, hạ tầng) đường ghi kiểm toán (hộp thư đi có xác nhận, chữ ký nguồn `dh-mac`, ghi tuần tự theo tenant bằng khóa tư vấn, kiểm tra toàn bộ chuỗi trực tuyến hằng ngày); **ADR số 014** (dải lõi) một Alertmanager toàn cục định tuyến theo nhãn tenant, Ruler theo OrgID, `alert-relay` độc lập; **ADR số 015** (dải lõi) ClickHouse cho siêu dữ liệu lượt gọi API (đóng Q331, Q13-06) |

: Đề nghị đồng bộ cho tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD và quy chuẩn K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu, vị trí trong kiến trúc, cấu trúc mã hai module và thư viện `dh-audit`, 21 thành phần với bảng đặc tả 10 mục, mười sơ đồ trình tự, đa tenant, bảo mật, máy trạng thái và lỗi, cấu hình, quan sát, hiệu năng, kiểm thử, lộ trình, rủi ro, 8 câu hỏi mở (Q13-20…27), đề nghị đồng bộ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: p_archive_partition thay DETACH CONCURRENTLY, quyền INSERT theo cột của ph13_app, trigger tg_audit_chain_guard và tg_audit_event_covered; chốt câu hỏi mở đợt đồng bộ: Q390 |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | FR-13-053: `SuspensionProposer` kiểm mức HIGH, CRITICAL, lấy `alertId`, `severity`, `incidentRef`, `evidenceUrl` từ cảnh báo gốc và xử lý ERR-01-048, ERR-01-005; cập nhật sơ đồ lời gọi API-01-089 |

