---
ma_tai_lieu: D03-02-PH02
ten: Thiết kế chi tiết phần mềm phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, kiến trúc sư, ATTT, vận hành, hội đồng thẩm định
phan_he: PH-02
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Danh mục dịch vụ gồm thành phần, cấu trúc mã, trình tự các luồng công bố, cấp quyền, đồng bộ quốc gia, máy trạng thái, xử lý lỗi, cấu hình, khả năng mở rộng và bảo mật, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH02 FRS; D02-04-PH02 Use case; D03-03-PH02 CSDL; D03-04-PH02 API; D03-06-PH02 Màn hình; D03-07 ATTT; D03-09 Hạ tầng; D03-10 Đa tenant; D04-01 Quy ước mã
---

# D03-02-PH02 · Thiết kế chi tiết Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 62 FR của [D02-03-PH02](../../02-yeu-cau/frs/D02-03-PH02-frs-danh-muc-dich-vu.md) và 38 use case của [D02-04-PH02](../../02-yeu-cau/use-case/D02-04-PH02-use-case-danh-muc-dich-vu.md). PH-02 là nơi giữ **hợp đồng** giữa bên cung cấp và bên khai thác dữ liệu: mỗi dịch vụ chia sẻ dữ liệu là một API có đặc tả OpenAPI 3.1, đi qua kiểm tra, duyệt bốn mắt rồi mới ra cổng. Thiết kế dựa trên năm quyết định:

1. **Phiên bản là đơn vị vòng đời, và mọi chuyển trạng thái đi qua một bảng duy nhất ở máy chủ.** Ba máy trạng thái (phiên bản API, gói, đăng ký) được khai báo thành danh sách bất biến trong mã, dùng chung cho dịch vụ, giao diện (danh sách hành động khả dụng) và kiểm thử (ADR-058, ADR-069). Giao diện ẩn nút chỉ là tiện ích, không là lớp bảo vệ.
2. **Công bố là một saga có điểm dừng an toàn.** Phiên bản chỉ sang `PUBLISHED` sau khi APISIX xác nhận đã nạp đúng số phiên bản cấu hình (`sourceVersion`); thiếu xác nhận thì giữ `PENDING` và thử lại. PH-02 chỉ đưa dữ liệu công bố cho PH-03, không nằm trên đường xử lý lượt gọi, nên `dh-connect` ngừng thì API đang chạy vẫn phục vụ (ADR-013, NFR-02-008).
3. **Đặc tả là dữ liệu không tin cậy.** Mọi đặc tả đi qua bộ phân tích có giới hạn (kích thước, độ sâu, alias), bộ tải URL chặn SSRF, bộ quét bí mật và dữ liệu cá nhân thật; nội dung lưu bất biến theo băm SHA-256 ở kho đối tượng. Quét lỗi thì chặn, không bao giờ cho qua (SEC-16, SEC-43, SEC-45).
4. **Quyền gọi API sinh từ dữ liệu đã duyệt, không có đường cấp tay.** Đăng ký sử dụng đã duyệt kích hoạt một saga hai nhánh: gắn phạm vi `api:{mã API}:{mã gói}` ở PH-12 và thêm consumer ở PH-03; chỉ khi cả hai xác nhận mới `GRANTED`. Kiểu xác thực tối thiểu theo mức phân loại dữ liệu được kiểm ở chính bảng chính sách của gói (SEC-24, BR-02-016).
5. **Nghĩa vụ công bố không phụ thuộc trí nhớ của con người.** Đồng bộ danh mục lên Nền tảng quốc gia và thông báo thay đổi bắt buộc đi qua hộp gửi (outbox) cùng giao dịch với thay đổi gốc, có hàng đợi bền, thử lại lùi dần và cảnh báo quá hạn (ADR-042, ADR-057).

Phân hệ là module `catalog` của `dh-connect` (Spring Boot 4, Spring Modulith, gói `vn.datahub.connect.catalog`), cùng đơn vị triển khai với PH-01, PH-03 (phần đồng bộ cấu hình) và PH-15 (phần máy chủ). Thiết kế **không tạo ADR mới**; hai đề xuất ADR (phiên bản là đơn vị vòng đời; tìm kiếm danh mục PostgreSQL mặc định, OpenSearch tùy chọn) ghi ở mục "Đề nghị đồng bộ".

| Chỉ số | Giá trị |
|---|---|
| FR hiện thực | 62 (M: 50, S: 11, C: 1), MVP 58, Đợt 2 bốn FR |
| Thành phần ở chương 4 | 14 thành phần, mỗi thành phần một bảng đặc tả 10 mục |
| Biểu đồ tuần tự | 8 luồng chính ở chương 5 |
| Máy trạng thái | 3 (phiên bản API, gói, đăng ký) cộng 2 máy phụ (đồng bộ quốc gia, cấp phạm vi) |
| API, sự kiện, lỗi | 98 API-02, 16 EVT-02, 45 ERR-02 (định nghĩa ở FRS và D03-04-PH02) |
| Cờ tính năng, tham số | 7 cờ kỹ thuật, 28 tham số `02.*` |
| Câu hỏi mở | 10 (Q02-20…Q02-29) |

: Con số chính của thiết kế PH-02

## 1. Giới thiệu

### 1.1. Mục đích, phạm vi và cách đọc

Tài liệu mô tả cách hiện thực PH-02 trong `dh-connect` đủ để kỹ sư lập trình và kiểm thử viên viết ca mà không phải đoán: module nào giữ việc gì, luồng nào đi qua những lớp nào, trạng thái nào được phép chuyển, lỗi nào được thử lại.

Tài liệu đi từ vị trí trong kiến trúc (chương 2), cấu trúc mã (chương 3), từng thành phần (chương 4), sơ đồ tuần tự của các FR phức tạp (chương 5) tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát, hiệu năng và kiểm thử. Mã `BR`, `NFR`, `ERR`, `EVT` là của FRS; mã `API` đầy đủ ở D03-04-PH02; bảng cột, chỉ mục, RLS ở D03-03-PH02 (tên bảng dùng ở đây là tên dự kiến, chốt ở tập CSDL). Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới.

PH-02 không thực thi lượt gọi, không cấp định danh máy, không hiển thị tài liệu cho nhà phát triển, không thiết kế luồng (FRS §1.2). Thiết kế chỉ nói về điểm giao tiếp với các phân hệ đó.

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4 + Modulith cho `dh-connect`; ranh giới module kiểm bằng `ApplicationModules.verify()` |
| ADR-003 | PostgreSQL, RLS theo `tenant_id`, `FORCE ROW LEVEL SECURITY` |
| ADR-004 | Kafka cho sự kiện `EVT-02-*` |
| ADR-005 | APISIX standalone: ảnh chụp cấu hình có chữ ký, không gọi Admin API trên đường xử lý lượt gọi |
| ADR-006 | Keycloak (phạm vi, client) và OPA (quyết định quyền, chính sách theo phạm vi) |
| ADR-008 | Garage lưu đặc tả, tệp xuất, gói nhập hệ cũ |
| ADR-013 | Tách control plane và data plane; chỉ tiêu NFR-02-008 |
| ADR-033 | Lớp biên APISIX + Coraza: nơi thực thi route đã công bố |
| ADR-042 | Hộp gửi trong DU: sự kiện ghi cùng giao dịch, phát bù khi Kafka ngừng |
| ADR-046 | Mẫu duyệt bốn mắt, so sánh theo định danh người dùng chứ không theo vai trò |
| ADR-057 | Đồng bộ quốc gia qua PH-14; PH-14 giữ giao thức, chứng thư, giới hạn tần suất |
| ADR-058, ADR-069 | Máy trạng thái nội bộ thay cho Flowable cho luồng duyệt ngắn; bốn mắt chốt ở máy chủ |
| ADR-061 | Catalog khớp phiên bản runtime: PH-02 sinh khung route theo khung chín chặng của PH-04 |

: ADR áp dụng cho PH-02

### 1.2. Người đọc, thuật ngữ, tài liệu tham chiếu và cấu trúc

Bảng dưới nêu từng nhóm người đọc cần đọc chương nào; thuật ngữ và tài liệu tham chiếu ở hai đoạn sau bảng.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` | Chương 3, 4, 6, 8, 9 |
| Kỹ sư PH-03, PH-04, PH-12, PH-14 | Mục 2.3, 3.2, 4.9, 4.10, 4.11, 4.15, chương 5, mục 8.3 |
| ATTT | Mục 4.3, 4.4, 4.9, chương 7 |
| Kiểm thử viên | Chương 5, mục 8.1, 8.6, chương 12 |
| Vận hành | Chương 10, 11, mục 8.4 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 13 |

: Người đọc và phần cần đọc

Thuật ngữ và chữ viết tắt dùng chung với [D02-03-PH02](../../02-yeu-cau/frs/D02-03-PH02-frs-danh-muc-dich-vu.md) §1.4 và D00-01. Hai thuật ngữ riêng của thiết kế: **ảnh chụp cấu hình** (configuration snapshot) là bộ route, upstream, consumer đầy đủ có số phiên bản tăng dần và chữ ký mà PH-03 ghi cho APISIX; **`sourceVersion`** là số phiên bản tăng dần theo (tenant, môi trường) của dữ liệu công bố do PH-02 giữ, tăng mỗi lần có thay đổi ảnh hưởng gateway. Mỗi thành phần ở chương 4 mở đầu bằng một bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế.

Tài liệu tham chiếu: D02-03-PH02 (FRS), D02-04-PH02 (use case), D02-08 (quyền `PERM-02-*`), D03-01 §4 (đơn vị triển khai), D03-07 (SEC), D03-09 §6.1 (ảnh chụp cấu hình APISIX), D03-10 (đa tenant), D04-01 (quy ước mã), D04-02 (cổng CI).

### 1.3. Danh sách thành phần

Bảng dưới liệt kê 14 thành phần của chương 4 cùng gói con, nhóm FR và nơi chạy. Số mục là số mục của tài liệu này.

| Mục | Thành phần | Gói con (`internal.*`) | FR chính | Đơn vị chạy |
|---|---|---|---|---|
| 4.2 | Tra cứu danh mục và tìm kiếm | `query`, `search` | 001…009 | `dh-connect` `api` |
| 4.3 | Đăng ký API và nạp đặc tả | `intake` | 010…015 | `api` |
| 4.4 | Bộ kiểm tra đặc tả | `lint` | 016…021 | `api` hoặc `lint-worker` |
| 4.5 | Backend, đường dẫn, khung route | `backend`, `route` | 022…026 | `api`, `worker` |
| 4.6 | Gói sử dụng | `plan` | 027…033 | `api` |
| 4.7 | Vòng đời, duyệt, tạm ngừng, ngừng dùng | `lifecycle` | 034…041, 045 | `api`, `worker` |
| 4.8 | So sánh phiên bản, phân tích tác động | `diff` | 042…044 | `api`, `worker` |
| 4.9 | Đăng ký sử dụng và cấp phạm vi | `subscription`, `grant` | 046…052 | `api`, `worker` |
| 4.10 | Dữ liệu công bố cho gateway, đối soát | `gatewaysync` | 036, 059, 060 | `api`, `worker` |
| 4.11 | Đồng bộ danh mục quốc gia | `nationalsync` | 053, 054 | `worker` |
| 4.12 | SLA, thông báo, thống kê | `quality`, `notice` | 055…058 | `worker`, `api` |
| 4.13 | Di trú từ APIM cũ | `legacy` | 061 | `worker` |
| 4.14 | Tham số, luật, phân loại | `settings`, `taxonomy` | 008, 021, 062 | `api` |
| 4.15 | Bộ nối với phân hệ ngoài | `adapter` | 009, 013, 026, 048, 053, 056 | `api`, `worker` |

: Danh sách thành phần của PH-02

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-02 là phân hệ của mặt phẳng điều khiển. Một ảnh container của `dh-connect` chạy ở ba vai trò (Spring profile): `api` nhận yêu cầu người dùng và dịch vụ, `worker` chạy tác vụ nền (công bố, cấp quyền, đồng bộ, SLA, đối soát), `lint-worker` (tùy chọn) chỉ chạy kiểm tra đặc tả. Vai trò `worker` lấy việc bằng `FOR UPDATE SKIP LOCKED`, nên nhiều bản sao chạy song song không trùng việc.

| Thành phần | DU | Vùng | Ghi chú |
|---|---|---|---|
| Module `catalog` (REST, nghiệp vụ, tác vụ nền) | `dh-connect` | Z3 | Chung DU với `onboarding` (PH-01), `gateway` (PH-03), `portal` (PH-15); khác module Modulith |
| Bộ kiểm tra đặc tả cô lập | `dh-connect` vai trò `lint-worker` | Z3 | Chỉ bật ở `QM-LON`, `QM-CHUNG` (mục 4.4), cùng ảnh, khác profile |
| `pg-core` schema `ph02_catalog` | Nền tảng | Z5 | Cụm CNPG chung control plane; RLS theo `tenant_id` |
| Garage bucket `dh-{tenant}-catalog` | Nền tảng | Z5 | Tiền tố `specs/`, `exports/`, `legacy/`; khóa truy cập theo tenant (SEC-82) |
| Kafka topic `{tenant}.catalog.*` | Nền tảng | Z5 | EVT-02-01…16, lược đồ ở Apicurio, chế độ BACKWARD |
| APISIX standalone | `apisix` | Z2 | Không thuộc PH-02: nhận ảnh chụp cấu hình từ PH-03 |
| Valkey | Nền tảng | Z5 | Chỉ đếm hạn mức kiểm tra mỗi người; mất Valkey thì dùng bộ đếm cục bộ |

: Đơn vị triển khai và vùng mạng

Lưu lượng ra Internet chỉ có một đường: bộ tải đặc tả từ URL (FR-02-011, 012), đi qua egress gateway với danh sách FQDN của tenant (SEC-16). Lưu lượng tới PH-14 và Nền tảng quốc gia do PH-14 đảm nhận, PH-02 không có chứng thư hay khóa quốc gia. Định cỡ `dh-connect` ở D03-09 §5.3 (hai bản sao 1 vCPU ở `QM-VUA`); phần PH-02 ước tính ở mục 11.

### 2.2. Sơ đồ thành phần

Hình dưới cho thấy các module của PH-02 trong `dh-connect` và hướng gọi giữa chúng; phần thuyết minh sau hình nêu những ranh giới cần giữ.

```{.mermaid caption="Sơ đồ thành phần của PH-02 trong dh-connect"}
flowchart TB
  subgraph DC["dh-connect · module catalog"]
    WEB["web<br/>REST /api/catalog/v1<br/>và /internal"]
    QRY["query, search<br/>CatalogQueryService"]
    INT["intake<br/>SpecIngestService"]
    LNT["lint<br/>SpecLinter, SecretScanner"]
    BKD["backend, route<br/>BackendService"]
    PLN["plan<br/>PlanService"]
    LCY["lifecycle<br/>VersionLifecycle, ReviewService"]
    DIF["diff<br/>DiffEngine"]
    SUB["subscription, grant<br/>GrantOrchestrator"]
    GWS["gatewaysync<br/>PublishedConfigAssembler"]
    NAT["nationalsync<br/>NationalSyncService"]
    QLT["quality, notice<br/>SlaEvaluator, NoticeService"]
    LEG["legacy<br/>LegacyApimImporter"]
    ADP["adapter<br/>cổng ra ngoài (SPI)"]
    OBX["events<br/>Outbox"]
    WEB --> QRY & INT & BKD & PLN & LCY & SUB & NAT & LEG & DIF
    INT --> LNT
    LCY --> LNT & DIF & GWS & PLN & BKD
    SUB --> GWS
    LCY & SUB & NAT & QLT --> OBX
    LCY & SUB & NAT & QLT & GWS & BKD --> ADP
  end
  subgraph DCO["dh-connect · module khác cùng DU"]
    ONB["onboarding PH-01"]
    GW["gateway PH-03"]
    POR["portal PH-15"]
  end
  PG[("pg-core<br/>ph02_catalog")]
  GA[("Garage<br/>dh-t68-catalog")]
  KF[("Kafka")]
  AP["APISIX Z2"]
  P12["PH-12<br/>Keycloak, OPA"]
  P14["PH-14"]
  P04["PH-04"]
  P13["PH-13"]
  P18["PH-18"]
  DC --> PG
  INT & LEG & QRY --> GA
  OBX --> KF
  ADP -->|"in-process"| ONB
  ADP -->|"SPI GatewayApplyPort"| GW
  GW -->|"đọc PublishedConfigApi"| GWS
  GW -->|"ảnh chụp có chữ ký"| AP
  ADP -->|"REST, token dịch vụ"| P12 & P14 & P04 & P13 & P18
  POR -->|"đọc CatalogQueryApi"| QRY
  KF -->|"EVT-04-*, EVT-10-*, EVT-01-*"| LCY
```

Sơ đồ cho thấy ba đường. Đường quản lý: giao diện gọi REST ở lớp `web`, các dịch vụ ghi `ph02_catalog`, sự kiện đi qua outbox lên Kafka. Đường công bố: `lifecycle` yêu cầu `gateway` (PH-03) qua cổng `GatewayApplyPort`, `gateway` đọc dữ liệu công bố từ `PublishedConfigApi` rồi ghi ảnh chụp cho APISIX; PH-02 không có mũi tên nào gọi tới APISIX. Đường ra ngoài: mọi cuộc gọi tới phân hệ khác đi qua gói `adapter` bằng giao diện (port), nên có thể thay bản cài đặt khi hồ sơ triển khai tách DU hoặc khi PH-14 chốt đặc tả.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng dưới liệt kê từng bên gọi hoặc được gọi, hướng gọi và cách trao đổi, để kỹ sư biết giao diện nào phải giữ ổn định.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| Module `onboarding` (PH-01) cùng DU | PH-02 đọc | `SystemDirectoryApi` (Modulith, trong tiến trình) | HTTT `ACTIVE`, đơn vị chủ quản, đầu mối kỹ thuật, định danh máy (FR-02-004, 046, 048) |
| Module `onboarding` | PH-01 → PH-02 | Sự kiện PH-01 (tạm ngừng, thu hồi HTTT, cấp xong định danh máy) | FR-02-051, 048 |
| Module `gateway` (PH-03) cùng DU | PH-02 → PH-03 | Cổng `catalog.spi.GatewayApplyPort` do `gateway` cài đặt | Yêu cầu nạp cấu hình, hỏi trạng thái đối soát (FR-02-036, 048, 060) |
| Module `gateway` | PH-03 → PH-02 | `catalog.api.PublishedConfigApi` (phạm vi `catalog:gateway-read`), `GatewayAckApi` (phạm vi `catalog:gateway-ack`) (API-02-080, 082) | Lấy dữ liệu công bố, xác nhận đã nạp |
| Module `portal` (PH-15) cùng DU | PH-15 → PH-02 | `catalog.api.CatalogQueryApi` (API-02-081) và EVT-02-* | Hiển thị danh mục, đặc tả đã gộp |
| PH-04 | hai chiều | REST `/api/integration/v1` và EVT-04-02, 04, 07 | Sinh khung luồng, đọc đặc tả luồng, nhận sự kiện phát hành luồng (FR-02-013, 026) |
| PH-05 | PH-02 đọc | REST `/api/adapter/v1` (API-05-031, 089) | Kiểm tra kết nối cho backend `SYSTEM` (FR-02-022) |
| PH-10 | PH-02 đọc | REST `/api/event/v1/topics` và EVT-10-01, 03, 04 | Dịch vụ sự kiện (FR-02-009) |
| PH-12 | PH-02 gọi | REST, token dịch vụ | Gắn, gỡ phạm vi `api:*` ở client Keycloak, cập nhật chính sách OPA (FR-02-048) |
| PH-13 | PH-02 đọc | Truy vấn Mimir theo tenant (`X-Scope-OrgID`) | SLA thực tế, sức khỏe backend, thống kê (FR-02-025, 056, 058) |
| PH-14 | PH-02 gọi | REST nội bộ, `Idempotency-Key` | Gửi, rút danh mục quốc gia (FR-02-053) |
| PH-18 | PH-02 đọc, gửi | `ParameterApi` có đệm 60 giây; `TaskInboxApi`, `NotificationApi` | Tham số `02.*`, việc duyệt, thông báo |
| PH-16 | PH-16 đọc | `catalog:metrics-read` (FR-02-059) | Chỉ số tuân thủ |
| DD-12 (quét mã độc) | PH-02 gọi | ClamAV qua cổng chung | Tệp đặc tả, gói nhập (SEC-45) |

: Phụ thuộc với module và phân hệ khác

Luật Modulith: `catalog` chỉ import gói `api` và `events` của module khác; module khác chỉ import `catalog.api`, `catalog.events` và `catalog.spi`. Chiều phụ thuộc giữa `catalog` và `gateway` đi một hướng: `gateway` import `catalog`, còn `catalog` không import `gateway`; việc "gọi ngược" được thực hiện bằng cổng `GatewayApplyPort` do `catalog` định nghĩa và `gateway` cài đặt (đảo ngược phụ thuộc), nên đồ thị module không có chu trình. `ApplicationModules.verify()` và bộ luật ArchUnit kiểm ở CI-2.

### 2.4. Hiện trạng mã và đường chuyển

Bảng dưới so sánh mã hiện có trong repo với thiết kế mới và nêu khoảng cách phải lấp, làm căn cứ chia việc.

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| `apps/control`, module `vn.lgsp.control.catalog` (306 dòng): bảng `ph02.api_service` 11 cột lưu `openapi_yaml` dạng `TEXT`; `CatalogService.publish` đặt `PUBLISHED` ngay | Module `vn.datahub.connect.catalog`, schema `ph02_catalog`, vòng đời có duyệt, đặc tả ở Garage | GAP-02-01: chuyển sang `dh-connect`, di trú dữ liệu bằng changeset, xóa module cũ khi PH-02 mới chạy |
| `ApisixRouteWriter` ghi tệp YAML vào `deploy/apisix/routes`, cho CORS `*`, `limit-count` cố định 100 mỗi 60 giây, mọi phương thức | Dữ liệu công bố trả qua `PublishedConfigApi`; PH-03 dựng ảnh chụp có chữ ký; route theo từng thao tác trong đặc tả | GAP-02-02: bỏ ghi tệp, phần thực thi thuộc PH-03 (SEC-43) |
| Route `/api/v1/catalog/*`, không quyền, không tenant | `/api/catalog/v1/*`, `PERM-02-*`, RLS | GAP-02-03 |
| Không kiểm tra đặc tả, không quét bí mật, không so sánh phiên bản | Bộ kiểm tra hai lớp, quét bí mật, `DiffEngine` | GAP-02-04 |
| Không có gói sử dụng, đăng ký sử dụng; khóa API là cơ chế chính ở hệ Gravitee cũ | Gói, đăng ký, phạm vi tự sinh; nhập hệ cũ ở trạng thái `SUSPENDED` | GAP-02-05 (FR-02-061, BR-02-036) |

: Hiện trạng mã và đường chuyển

### 2.5. Quyết định thiết kế chính và phương án đã loại

Bảng dưới ghi các quyết định thiết kế quan trọng của PH-02 cùng phương án đã cân nhắc và lý do loại, để người đến sau không phải tranh luận lại.

| Vấn đề | Chọn | Phương án loại và lý do |
|---|---|---|
| Duyệt công bố | Máy trạng thái trong mã, bảng `review_request`, bốn mắt ở máy chủ (ADR-058, ADR-069) | Flowable: nặng cho duyệt một bước, trạng thái nằm hai nơi |
| Cách đưa cấu hình xuống cổng | `catalog` giữ dữ liệu nguồn, PH-03 kéo qua `PublishedConfigApi` và xác nhận qua `GatewayAckApi` | Gọi Admin API APISIX từ PH-02: APISIX chạy standalone, PH-02 không được nằm trên đường dữ liệu (D03-09 §6.1) |
| Xác nhận công bố | `sourceVersion` tăng dần, APISIX báo số phiên bản đã nạp | Chờ cố định N giây: không biết cổng đã nạp thật hay chưa |
| Kiểm tra đặc tả lớp 2 | Bộ luật Java trên cây đã phân tích, luật khai báo ở bảng `lint_rule` | Spectral (Node): thêm môi trường chạy và bề mặt tấn công vào DU; Spectral vẫn dùng ở CI-5 cho đặc tả của chính Datahub (Q02-20) |
| Tìm kiếm toàn văn | PostgreSQL `tsvector` + `unaccent` mặc định, giao diện `SearchEngine` cho OpenSearch | OpenSearch cho mọi hồ sơ: thêm cụm có trạng thái cho tỉnh nhỏ (D03-01 §6, Q02-02) |
| Cấp phạm vi | Saga hai nhánh, có `grantStatus` | Cấp tay: vi phạm BR-02-025 |
| Gửi danh mục quốc gia | Hàng đợi bền `national_sync_record` + `NationalCatalogPort` | Gọi đồng bộ trong giao dịch người dùng: PH-14 chậm làm hỏng công bố |

: Quyết định thiết kế chính của PH-02

## 3. Cấu trúc mã nguồn

### 3.1. Module `catalog` trong `dh-connect`

Khối dưới là cây gói mã của module `catalog`; mỗi gói con tương ứng một thành phần ở chương 4.

```text
vn.datahub.connect.catalog
├── api/                    # công bố cho module khác: CatalogQueryApi, PublishedConfigApi, GatewayAckApi, DTO
├── spi/                    # cổng ra do catalog định nghĩa, bên khác cài đặt: GatewayApplyPort, ScopeGrantPort,
│                           #   NationalCatalogPort, MetricsReadPort, SearchEngine, LintRule
├── web/                    # @RestController /api/catalog/v1 và /api/catalog/v1/internal; ProblemDetail ERR-02-*
├── internal/
│   ├── domain/             # nhân dùng chung: TenantId, ApiCode, Environment, StateMachine<S,C>, ReviewPolicy,
│   │                       #   AuthPolicyMatrix, VersionNumber (so sánh MAJOR.MINOR.PATCH)
│   ├── query/              # CatalogQueryService, VisibilityFilter (BR-02-039), EtagSupport
│   ├── search/             # PgSearchEngine (tsvector + unaccent), SearchDocumentWriter
│   ├── intake/             # ApiRegistrationService, SpecIngestService, SafeFetcher, SpecNormalizer, SwaggerConverter, SpecStore
│   ├── lint/               # SpecLinter, Layer1Validator, ConventionRules (LINT-02-*), SecretScanner (SCAN-02-*), DuplicateDetector
│   ├── backend/            # BackendService, TargetPolicy (BR-02-023), HealthReader
│   ├── route/              # ContextPathService, RouteSkeletonService (gọi PH-04)
│   ├── plan/               # PlanService, PlanStateMachine, PlanCompatibilityChecker (BR-02-017)
│   ├── lifecycle/          # ApiVersionService, VersionStateMachine, ReviewService, PublishCoordinator,
│   │                       #   DeprecationService, SuspensionService, TransferService
│   ├── diff/               # DiffEngine, ChangeClassifier, ImpactAnalyzer
│   ├── subscription/       # SubscriptionService, SubscriptionStateMachine, RenewalScheduler
│   ├── grant/              # GrantOrchestrator, ScopeCalculator
│   ├── gatewaysync/        # PublishedConfigAssembler, ConfigEpoch, ConfigChangeLog, DriftReconciler
│   ├── nationalsync/       # NationalSyncService, PayloadBuilder, SyncDispatcher, OverdueWatcher
│   ├── quality/            # SlaService, SlaEvaluator, UsageStatsService
│   ├── notice/             # NoticeService, RecipientResolver
│   ├── legacy/             # LegacyApimImporter, ApimExportParser, ImportReportBuilder
│   ├── settings/           # CatalogSettings (đọc 02.* qua ParameterApi, đệm 60 giây), FeatureFlags
│   ├── taxonomy/           # CategoryService, TagService
│   ├── adapter/            # bản cài đặt REST của các cổng ra: Ph12ScopeClient, Ph14NationalClient, Ph04FlowClient,
│   │                       #   Ph05ConnectionClient, Ph10TopicClient, MimirMetricsClient, Ph18NoticeClient
│   └── persistence/        # Repository (JdbcClient), OutboxWriter, IdempotencyStore, RLS filter
└── events/                 # record EVT-02-01…16, OutboxPublisher
```

Gói `internal.domain` không import Spring, JDBC hay Jackson, để kiểm thử đơn vị nhanh và để ArchUnit chặn nhiễm chéo. Các gói con còn lại gọi nhau theo một chiều: `web` → dịch vụ nghiệp vụ → `domain`, `persistence`, `adapter`. Hai gói `lifecycle` và `subscription` là nơi duy nhất ghi cột `status` của phiên bản và đăng ký; mọi nơi khác (ví dụ `legacy`, `nationalsync`) muốn đổi trạng thái phải gọi qua dịch vụ của hai gói này.

### 3.2. Giao diện công bố và cổng ra

Các giao diện Java dưới đây là điểm giao tiếp giữa `catalog` và module khác trong `dh-connect` (PH-03, PH-15); chỉ các giao diện này được phép gọi từ ngoài module.

```java
package vn.datahub.connect.catalog.api;

public interface PublishedConfigApi {
  /** FR-02-059, API-02-080, phạm vi catalog:gateway-read (chỉ đọc). Trả null khi ifNoneMatch khớp sourceVersion hiện tại (HTTP 304). */
  PublishedConfig snapshot(TenantId tenant, Environment env, String ifNoneMatch);
  /** Thay đổi sau một sourceVersion, đọc từ config_change_log. Quá cũ thì trả gap = true, PH-03 lấy toàn bộ.
   *  API-02-080 trả luồng ndjson, mỗi lượt tối đa limit bản ghi (mặc định 500) kèm con trỏ configVersion (Q02-56). */
  ConfigDelta changesSince(TenantId tenant, Environment env, long sourceVersion, int limit);
}

public interface GatewayAckApi {
  /** FR-02-036, API-02-082, phạm vi catalog:gateway-ack (ghi, tách khỏi gateway-read). Lũy đẳng theo (tenant, env, configVersion). */
  void onApplied(TenantId tenant, Environment env, long configVersion, long sourceVersion, String configHash);
  void onApplyFailed(TenantId tenant, Environment env, long sourceVersion, String reason);
}

public interface CatalogQueryApi {
  /** FR-02-001, 004, API-02-081. Lọc theo mức hiển thị của người gọi (BR-02-039). */
  Page<ApiSummary> list(TenantId tenant, CatalogFilter filter, PageRequest page);
  ApiDetail get(TenantId tenant, String apiCode);
  /** FR-02-006, 026. Đặc tả đã gộp tham chiếu của một phiên bản. */
  MergedSpec mergedSpec(TenantId tenant, String apiCode, String versionNo);
}
```

```java
package vn.datahub.connect.catalog.spi;

public interface GatewayApplyPort {
  ApplyTicket requestApply(TenantId tenant, Environment env, long sourceVersion);      // không chặn
  ApplyStatus status(TenantId tenant, ApplyTicket ticket);                              // QUEUED, APPLIED, FAILED
  GatewayState describe(TenantId tenant, Environment env);                              // FR-02-060: số phiên bản, băm, route mỗi pod
  void rebuild(TenantId tenant, Environment env);                                       // đẩy lại ảnh chụp
}

public interface ScopeGrantPort {
  GrantResult attach(TenantId tenant, String clientId, Set<String> scopes, String idempotencyKey);
  GrantResult detach(TenantId tenant, String clientId, Set<String> scopes, String idempotencyKey);
}

public interface NationalCatalogPort {
  SyncResult upsert(NationalServicePayload payload, String idempotencyKey);             // idempotencyKey = payloadHash
  SyncResult withdraw(String nationalRef, String idempotencyKey);
}

public interface MetricsReadPort {
  PeriodMetrics apiPeriod(TenantId tenant, String apiCode, int major, YearMonth period);
  List<BackendHealth> backendHealth(TenantId tenant, String apiCode, String versionNo);
}

public interface SearchEngine {
  SearchResult search(TenantId tenant, SearchQuery query, VisibilityScope scope);
  void index(TenantId tenant, SearchDocument doc);
  void remove(TenantId tenant, String apiCode);
}

public interface LintRule {
  String id();                                    // LINT-02-nn
  Layer layer();                                  // STANDARD, CONVENTION, SECRET
  Severity defaultSeverity();
  List<Finding> check(SpecContext ctx);           // thuần, không I/O, không đọc đồng hồ
}
```

Các cổng `GatewayApplyPort`, `ScopeGrantPort`, `NationalCatalogPort`, `MetricsReadPort` có bản cài đặt thật (REST, trong tiến trình) và bản giả cho kiểm thử, chọn bằng cấu hình; `SearchEngine` có hai bản cài đặt (PostgreSQL, OpenSearch) chọn theo tham số `02.search.engine`. `LintRule` là điểm mở rộng của bộ kiểm tra (mục 9.3).

### 3.3. DTO chính

Các kiểu dữ liệu dưới đây là hình dạng dữ liệu đi qua giao diện công bố và giữa các lớp; tên trường khớp OpenAPI ở D03-04-PH02.

```java
public record RegisterApiRequest(
    @Pattern(regexp = "^[a-z][a-z0-9-]{2,62}$") String apiCode,
    @NotBlank @Size(min = 3, max = 255) String name,
    @NotBlank @Size(min = 20, max = 4000) String description,        // BR-02-002: mô tả tổng thể bắt buộc
    @NotBlank String systemCode,                                       // HTTT cung cấp, ACTIVE ở PH-01 (ERR-02-004)
    @NotNull DataClass dataClass,
    @NotNull Visibility visibility,
    boolean stateSecret,                                               // true bị từ chối (BR-02-007, ERR-02-016)
    String categoryCode, @Size(max = 10) List<String> tags,
    @Pattern(regexp = "^/[a-z0-9-]+(/[a-z0-9-]+)*$") String groupPath) {}

public record SpecSource(@NotNull SpecOrigin source,                   // UPLOAD, PASTE, URL
    byte[] content, @Size(max = 2048) String url, boolean autoRefresh) {}

public record PlanSpec(
    @Pattern(regexp = "^[a-z][a-z0-9-]{1,40}$") String planCode,
    @NotBlank String name, @NotNull AuthType authType,
    boolean autoApprove, Set<String> allowedSystemGroups,
    @Valid RateLimits limits,                                          // theo giây, theo giờ, theo ngày
    Set<@Pattern(regexp = "^[A-Z]+ /.*$") String> allowedOperations,   // "GET /ho-so/{id}"
    @Min(0) long unitPriceVnd) {}                                      // chỉ là thông tin (BR-02-040)

public record SubmitForReviewRequest(@NotBlank String versionNo, Set<String> acknowledgedFindingIds,
    @Size(max = 2000) String note) {}

public record SubscribeRequest(@NotBlank String apiCode, @NotBlank String versionNo, @NotBlank String planCode,
    @NotBlank String systemCode, @NotBlank @Size(min = 20, max = 2000) String purpose,
    @NotNull @Valid ExpectedVolume expectedVolume, String legalBasis) {}   // legalBasis bắt buộc nếu mức ≥ Hạn chế (BR-02-012)

public record Finding(String ruleId, Layer layer, Severity severity, String location, String message,
    String hint, String maskedTail, FindingStatus status) {}           // maskedTail chỉ 4 ký tự cuối, không bao giờ cả chuỗi khớp
```

`Finding` không có trường chứa chuỗi khớp đầy đủ: bộ quét bí mật chỉ trả vị trí, mã mẫu và bốn ký tự cuối đã che (FR-02-018, NFR-02-012). `SpecSource.content` bị đánh dấu `@Sensitive`; bộ lọc log của thư viện chung thay nội dung bằng `***` nếu đối tượng bị log nhầm (SEC-32).

### 3.4. Quy tắc phụ thuộc và kiểm tra tự động

Bảng dưới nêu các quy tắc phụ thuộc giữa gói mã và công cụ kiểm từng quy tắc trong CI.

| Quy tắc | Công cụ | Cổng |
|---|---|---|
| `catalog` chỉ import `api`, `events` của module khác; không import `gateway.internal`, `onboarding.internal` | `ApplicationModules.verify()` | CI-2 |
| Không có chu trình giữa `catalog`, `gateway`, `onboarding`, `portal` | Modulith | CI-2 |
| `internal.domain` không phụ thuộc Spring, JDBC, Jackson | ArchUnit | CI-2 |
| Chỉ `lifecycle`, `subscription`, `plan` ghi cột `status` (cấm câu `UPDATE ... SET status` ngoài ba gói này) | ArchUnit + Semgrep luật Datahub | CI-2, CI-7 |
| `web` không gọi `persistence` trực tiếp | ArchUnit | CI-2 |
| Mọi `@RestController` có `@PreAuthorize` theo `PERM-02-*` | ArchUnit | CI-2 |
| Không đọc tenant từ tham số hay thân yêu cầu | Semgrep (SEC-80) | CI-7 |
| Không log `SpecSource`, `Finding.message` có chuỗi khớp, `SecretPayload` | ArchUnit, kiểm thử canary NFR-02-012 | CI-2, CI-3 |
| Mọi API mới có ca kiểm thử rò rỉ chéo tenant | Kiểm thử meta độ phủ (SEC-87) | CI-3 |
| Đặc tả OpenAPI của chính PH-02 đạt luật Datahub, không phá vỡ `v1` | Spectral, oasdiff | CI-5 |

: Quy tắc phụ thuộc và kiểm tra tự động

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền chia thành bảy gốc tập hợp (aggregate root). Phiên bản API là gốc của vòng đời, không phải API: API chỉ giữ thông tin nhận diện và phân loại, còn đặc tả, backend, SLA, gói và trạng thái nằm ở phiên bản (FRS §4.3).

```{.mermaid caption="Mô hình miền PH-02"}
classDiagram
  class Api {
    apiCode
    ownerOrgCode
    systemCode
    dataClass
    visibility
    origin
    flowRef
    basePath
    deletedAt
  }
  class ApiVersion {
    versionNo
    major
    status
    successorVersionId
    sunsetAt
    breaking
    publishedAt
    lastTestDeploy
    version
  }
  class ApiSpec {
    sha256
    sizeBytes
    source
    objectKey
  }
  class Finding {
    layer
    severity
    ruleId
    location
    status
  }
  class Backend {
    backendCode
    kind
    targetRef
    weight
    timeoutMs
    status
  }
  class Plan {
    planCode
    status
    authType
    autoApprove
    limits
  }
  class Subscription {
    systemCode
    status
    grantStatus
    expiresAt
  }
  class SlaCommitment {
    latencyP99Ms
    availability
    hourlyLimit
    effectiveFrom
  }
  class SlaPeriod {
    period
    actual
    met
    status
  }
  class ReviewRequest {
    kind
    subjectRef
    requestedBy
    decision
  }
  class NationalSyncRecord {
    status
    payloadHash
    nationalRef
  }
  Api "1" o-- "1..*" ApiVersion
  ApiVersion "1" *-- "1" ApiSpec
  ApiSpec "1" o-- "0..*" Finding
  ApiVersion "1" *-- "1..*" Backend
  ApiVersion "1" o-- "1..*" Plan
  Plan "1" o-- "0..*" Subscription
  ApiVersion "1" *-- "0..*" SlaCommitment
  ApiVersion "1" o-- "0..*" SlaPeriod
  ApiVersion "1" o-- "0..*" ReviewRequest
  ApiVersion "1" o-- "0..*" NationalSyncRecord
```

Hình cho thấy bốn phần phụ thuộc chặt vào phiên bản (đặc tả, backend, cam kết SLA, và qua đó kết quả kiểm tra) và ba đối tượng có vòng đời riêng gắn với phiên bản: gói, đăng ký (thuộc gói) và yêu cầu duyệt. Gói và đăng ký là gốc tập hợp riêng vì có máy trạng thái riêng và bị nhiều người thao tác đồng thời.

| Gốc tập hợp | Gồm | Khóa đồng thời | Ghi chú |
|---|---|---|---|
| `Api` | `Category`, thẻ | `version` (khóa lạc quan), `If-Match` | Đổi phân loại dữ liệu kích hoạt kiểm tra lại mọi gói (BR-02-016) |
| `ApiVersion` | `ApiSpec` hiện hành, `Backend`, `SlaCommitment`, `lastTestDeploy` | `version`; `SELECT … FOR UPDATE` khi đổi trạng thái | Đặc tả mới là dòng mới, `current_spec_id` đổi khi còn `DRAFT` |
| `Plan` | điều kiện, hạn mức, đường dẫn cho phép | `version` | Đếm đăng ký hiệu lực khi đóng gói dưới khóa của phiên bản |
| `Subscription` | trạng thái cấp quyền (`grantStatus`), lịch rà soát | `version` | Ràng buộc duy nhất một đăng ký hiệu lực mỗi (HTTT, phiên bản) |
| `ReviewRequest` | các quyết định (`review_decision`) | `version`; một yêu cầu `OPEN` mỗi đối tượng | Gom đủ chữ ký cho API `SENSITIVE` (CA và TA) |
| `NationalSyncRecord` | lần gửi, phản hồi | `version`; khóa duy nhất `(version_id, payload_hash)` | Hàng đợi bền |
| `ChangeNotice` | danh sách người nhận, kênh | `version` | Phát bất đồng bộ |

: Gốc tập hợp và khóa đồng thời

Các bất biến (invariant) dưới đây được giữ ở miền và có ràng buộc ở CSDL làm chốt chặn; kiểm thử đơn vị nhắm vào cột "Miền", kiểm thử tích hợp (Testcontainers PostgreSQL) nhắm vào cột "CSDL".

| Bất biến | BR | Miền | CSDL (ràng buộc) |
|---|---|---|---|
| Mã API, mã gói, số hiệu phiên bản bất biến và không dùng lại, kể cả đối tượng đã xóa | BR-02-021 | `CodeRegistry.reserve` | Bảng `code_registry(tenant_id, kind, code)` khóa duy nhất, chỉ thêm, không xóa |
| Context-path duy nhất, đúng quy ước, không xung đột tiền tố, giữ chỗ 12 tháng sau `RETIRED` | BR-02-022 | `ContextPathService` dưới `pg_advisory_xact_lock` theo tenant | `context_path_reservation` khóa duy nhất `(tenant_id, path)`, cột `released_after` |
| Một đăng ký hiệu lực mỗi (HTTT, phiên bản) | BR-02-027 | `SubscriptionService.submit` | Chỉ mục duy nhất từng phần `WHERE status IN ('PENDING','ACTIVE','SUSPENDED')` |
| Không `RETIRED` khi còn đăng ký hiệu lực; không nhận đăng ký khi phiên bản không `PUBLISHED` | BR-02-006, 011 | `RETIRED` giữ `FOR UPDATE` dòng phiên bản, đăng ký giữ `FOR SHARE` cùng dòng: hai việc tuần tự | Không (kiểm ở miền, có kiểm thử đua) |
| Phiên bản sang `PENDING` cần ≥ 1 backend `ACTIVE` tổng trọng số > 0 và ≥ 1 gói | BR-02-024 | `VersionStateMachine` bảo vệ chuyển `submit` | Không |
| Đặc tả bất biến từ `PENDING`; bản `PUBLISHED` không bao giờ sửa | BR-02-014 | `ApiSpec` chỉ thêm dòng; `current_spec_id` chỉ đổi ở `DRAFT` | `api_spec` không cấp quyền `UPDATE`, `DELETE` cho vai trò ứng dụng |
| Kiểu xác thực tối thiểu theo mức phân loại | BR-02-016 | `AuthPolicyMatrix.check(dataClass, authType)` | Cột chắn `plan.min_auth_rank` so với `api.data_class_rank`, kiểm lại bằng tác vụ đêm |
| Mức hiển thị phù hợp mức phân loại; nâng lên `NATIONAL`, `PUBLIC` cần CA duyệt | BR-02-037 | `Api.changeVisibility` | `CHECK` giữa `visibility` và `data_class` |
| Bốn mắt: người duyệt khác người gửi, khác người sửa gần nhất; SV không giữ vai trò CA | BR-02-008 | `ReviewPolicy.assertIndependent` so theo định danh người dùng | Bảng `version_contributor`; `CHECK (decided_by <> requested_by)` |
| Mọi chuyển trạng thái có lý do (trừ tạo mới) và ghi kiểm toán trước, sau | BR-02-028 | `StateMachine.fire` bắt buộc `reason` | Cột `reason NOT NULL` ở bảng lịch sử trạng thái |
| `DRAFT`, `PENDING` chỉ hiển thị cho chủ quản, TA, CA, PA | BR-02-039 | `VisibilityFilter` thêm điều kiện vào mọi truy vấn đọc danh mục | Không (RLS chỉ cách ly tenant); có ca kiểm thử rò rỉ trạng thái theo vai trò |

: Bất biến của miền

### 4.2. Tra cứu danh mục và tìm kiếm

::: dac-ta
**Mục đích.** Trả danh mục API theo vai trò và mức hiển thị, tìm kiếm toàn văn tiếng Việt không phân biệt dấu, cung cấp danh mục cho máy (HTTT khai thác, PH-15) và cho tải đặc tả đã công bố.

**Lớp chính.** `CatalogQueryService`, `VisibilityFilter`, `PgSearchEngine`, `SearchDocumentWriter`, `EtagSupport`, `TopicCatalogMerger`.

**Đơn vị chạy.** `dh-connect` vai trò `api`.

**FR hiện thực.** FR-02-001…009; NFR-02-001, 002.

**Giao diện vào.** API-02-001…013, 090, 091; `CatalogQueryApi` cho PH-15.

**Phụ thuộc ra.** Garage (đọc đặc tả); PH-10 qua `Ph10TopicClient` (FR-02-009); PH-01 qua `SystemDirectoryApi` (tên HTTT, đơn vị).

**Dữ liệu.** `api`, `api_version`, `api_operation`, `api_search_doc`, `category`, `api_tag`.

**Sự kiện.** Phát EVT-02-02 khi đổi phân loại, thẻ (`changedFields`); tiêu thụ EVT-10-01, 03, 04 để làm mới bộ đệm dịch vụ sự kiện.

**Lỗi và xử lý.** Đối tượng tenant khác hoặc không đủ quyền xem: ERR-02-001 (`404` cùng thân, BR-02-033); tham số lọc sai: ERR-02-003; Garage không khả dụng: đọc metadata vẫn được, đặc tả trả ERR-02-034; PH-10 không khả dụng: dịch vụ sự kiện hiển thị bản đệm kèm cờ `stale`.

**Quan sát.** `catalog_query_duration_seconds{op}`, `catalog_search_duration_seconds{engine}`, `catalog_apis_total{status}`.
:::

Chi tiết thiết kế:

`VisibilityFilter` dựng điều kiện SQL từ ngữ cảnh người gọi (vai trò, mã đơn vị, loại token) và nối vào mọi truy vấn đọc danh mục; không có truy vấn đọc nào đi đường khác. Quy tắc: phiên bản `DRAFT`, `PENDING` chỉ chủ quản, TA, CA, PA thấy (BR-02-039); người khác chỉ thấy phiên bản từ `PUBLISHED` trở đi; phiên bản `RETIRED` mặc định bị ẩn khỏi danh sách, hiện khi lọc theo trạng thái. Token máy với scope `catalog:read` thấy API `TENANT`, `NATIONAL`, `PUBLIC` đã công bố của tenant mình, không thấy gì của tenant khác (RLS cộng `404`).

Tìm kiếm mặc định dùng PostgreSQL. Cấu hình tìm kiếm `vn_unaccent` sao chép từ `simple` rồi thêm `unaccent` trước `simple` cho các loại từ `word`, `hword`, `hword_part`, nên "ho so dat dai" khớp "Hồ sơ đất đai". `api_search_doc` giữ một dòng mỗi API với cột `tsv` gồm bốn trọng số: tên và `apiCode` (A), mô tả (B), thẻ và phân loại (C), `summary` của các thao tác (D). Truy vấn dùng `websearch_to_tsquery`, xếp hạng `ts_rank_cd`, cộng khớp tiền tố `apiCode` bằng chỉ mục `pg_trgm`; chỉ mục GIN trên `tsv`. `SearchDocumentWriter` cập nhật dòng này trong cùng giao dịch với thay đổi (người dùng sửa xong thấy ngay), nên không cần chờ bộ chỉ mục. Bản OpenSearch (`02.search.engine = OPENSEARCH`) lập chỉ mục bất đồng bộ từ outbox vào alias `catalog-{tenant}`, độ trễ vài giây, dùng bộ phân tích tiếng Việt; chọn giữa hai bản theo Q02-02 và Q02-21.

Bộ đệm HTTP: mỗi danh sách và chi tiết trả `ETag` yếu tính từ `max(version)` của các dòng liên quan cộng băm phạm vi quyền của người gọi; `If-None-Match` khớp thì trả `304` không dựng thân (NFR-02-001). `Cache-Control: private, max-age=0, must-revalidate`, tránh bộ đệm dùng chung lẫn bản của vai trò khác. Danh mục cho máy (FR-02-004) hỗ trợ `updatedSince` để PH-15 kéo gia tăng. Dịch vụ sự kiện (FR-02-009, Đợt 2) lấy từ PH-10, đệm 60 giây theo tenant, gộp vào danh sách với `kind = EVENT`; mọi thao tác đăng ký, duyệt, vòng đời của dịch vụ này ở PH-10 (BR-02-038).

### 4.3. Đăng ký API và nạp đặc tả

::: dac-ta
**Mục đích.** Tiếp nhận API mới (biểu mẫu, tệp, dán, URL, luồng PH-04), đưa đặc tả vào phiên bản một cách an toàn và giữ nó bất biến sau khi nộp.

**Lớp chính.** `ApiRegistrationService`, `SpecIngestService`, `SafeFetcher`, `SafeSpecParser`, `SwaggerConverter`, `RefBundler`, `SpecStore`, `SpecRefreshJob`, `FlowRegistrationService`, `ContractGuard`.

**Đơn vị chạy.** `api` (nạp), `worker` (làm mới URL, nhận sự kiện luồng).

**FR hiện thực.** FR-02-010…015; NFR-02-011, 012.

**Giao diện vào.** API-02-014…019, 007 (đặc tả đã gộp); EVT-04-02, 04, 07 từ PH-04.

**Phụ thuộc ra.** Garage; ClamAV (DD-12); egress gateway (URL); PH-01 (HTTT `ACTIVE`); PH-04 (đặc tả sinh từ luồng).

**Dữ liệu.** `api`, `api_version`, `api_spec`, `api_operation`, `code_registry`, `context_path_reservation`, `inbox_event`.

**Sự kiện.** EVT-02-01 (đăng ký), EVT-02-02 (sửa), EVT-02-07 (đặc tả nguồn đổi).

**Lỗi và xử lý.** ERR-02-002 (mã đã dùng), 004 (HTTT không `ACTIVE`), 005 (cú pháp), 009 (quá cỡ), 010 (URL không cho phép), 016 (bí mật nhà nước), 034 (Garage hoặc ClamAV ngừng thì từ chối nhận tệp), 038 (đang `PENDING`); không bao giờ nhận đặc tả khi chưa quét.

**Quan sát.** `catalog_spec_ingest_total{source,result}`, `catalog_spec_ingest_bytes`, `catalog_spec_url_fetch_blocked_total{reason}`.
:::

Chi tiết thiết kế:

`ApiRegistrationService.register` chạy trong một giao dịch: giữ chỗ mã ở `code_registry` (khóa duy nhất, lỗi thì ERR-02-002), kiểm HTTT cung cấp `ACTIVE` qua `SystemDirectoryApi` (ERR-02-004) và đơn vị chủ quản phải là đơn vị của HTTT đó (BR-02-032), từ chối `stateSecret = true` (ERR-02-016), tạo `Api` và phiên bản `DRAFT 1.0.0`, ghi EVT-02-01 vào outbox. Nạp đặc tả đi qua đường ống có thứ tự cố định, mỗi chặng có thể dừng:

| Chặng | Việc | Giới hạn | Lỗi |
|---|---|---|---|
| 1. `SizeGate` | Đếm byte khi đọc luồng, ngắt tại giới hạn, không tin `Content-Length` | `02.spec.max-size-mib` (10 MiB mặc định) | ERR-02-009 |
| 2. `TypeSniffer` | Tika xác định theo nội dung; chỉ YAML, JSON (SEC-45) | Từ chối `.zip`, XML, nhị phân | ERR-02-005 |
| 3. Quét mã độc | Gửi luồng tới ClamAV (DD-12); lỗi quét coi như không đạt | Hết thời gian 20 giây | ERR-02-034 |
| 4. `SafeFetcher` (chỉ URL) | Xem đoạn dưới | 15 giây, 3 lần chuyển hướng | ERR-02-010 |
| 5. `SafeSpecParser` | YAML (SnakeYAML Engine) và JSON với giới hạn alias, độ sâu, số điểm mã; từ chối thẻ tùy biến `!!`; không giải `$ref` ngoài ra Internet | Alias ≤ 50, độ sâu ≤ 50, ≤ 5.000 thao tác (NFR-02-011) | ERR-02-005 kèm dòng, cột |
| 6. `SwaggerConverter` | Swagger 2.0 và OpenAPI 3.0 sang 3.1 (`nullable` thành kiểu mảng, `exclusiveMinimum` số, `example` sang `examples`); ghi `x-datahub-converted-from`; liệt kê điểm không chuyển được | Không | Cảnh báo, không lỗi |
| 7. `RefBundler` | Gộp tham chiếu ngoài hợp lệ vào một tài liệu; tham chiếu ngoài chỉ qua `SafeFetcher` | ≤ 20 tài liệu, tổng ≤ giới hạn kích thước | ERR-02-010 |
| 8. `SpecStore` | Chuẩn hóa JSON, tính SHA-256, ghi Garage khóa `specs/{apiCode}/{sha256}.json` (ghi theo nội dung nên lặp lại vô hại) | Không | ERR-02-034 |
| 9. Ghi CSDL | Một giao dịch: dòng `api_spec` mới, `current_spec_id`, thay `api_operation` của phiên bản `DRAFT`, cập nhật `api_search_doc` | Phiên bản phải `DRAFT` | ERR-02-038 nếu `PENDING` |
| 10. Kiểm tra không lưu | Gọi `SpecLinter.preview` (mục 4.4) và trả kết quả ngay | ≤ 5 giây với 5.000 dòng | Theo mục 4.4 |

: Đường ống nạp đặc tả

`SafeFetcher` là chặn duy nhất cho mọi lần PH-02 tự tải nội dung từ địa chỉ do người dùng đưa vào. Nó chỉ nhận `https`; tự phân giải DNS rồi từ chối nếu bất kỳ địa chỉ nào thuộc dải riêng RFC 1918, loopback, link-local (gồm `169.254.169.254`), CGNAT `100.64.0.0/10`, ULA `fc00::/7`, multicast hoặc `0.0.0.0/8`; sau đó **kết nối thẳng tới địa chỉ đã kiểm** (ghim IP, giữ `Host` và SNI gốc) để chống đổi bản ghi DNS giữa lúc kiểm và lúc nối (DNS rebinding); mỗi lần chuyển hướng kiểm lại từ đầu; đích phải có trong danh sách FQDN egress của tenant (SEC-16). Lớp mạng (Cilium `toFQDNs`, SEC-14) là chốt chặn thứ hai: ngay cả khi mã sai, pod `dh-connect` không ra được đích ngoài danh sách. Phản hồi bị cắt tại giới hạn kích thước và bị loại nếu `Content-Type` không phải YAML, JSON.

Đặc tả đã ghi ở Garage không bao giờ bị ghi đè (khóa theo băm). Nếu giao dịch CSDL ở chặng 9 hỏng sau khi chặng 8 xong, đối tượng mồ côi vô hại; tác vụ hằng tuần liệt kê khóa `specs/` không có dòng `api_spec` và cũ hơn 24 giờ rồi xóa. Làm mới từ URL (FR-02-012): `SpecRefreshJob` chạy mỗi giờ theo từng tenant, chọn phiên bản có `autoRefresh` tới hạn theo `02.spec.url-refresh-hours`, tải qua `SafeFetcher`, so SHA-256; khác thì phiên bản `DRAFT` được đề xuất đặc tả mới (người dùng bấm áp dụng), phiên bản đã `PUBLISHED` không bao giờ bị đổi mà chỉ phát EVT-02-07 để nhắc chủ dịch vụ tạo phiên bản mới.

API sinh từ luồng (FR-02-013): `FlowRegistrationService` đọc sự kiện từ Kafka qua bảng `inbox_event` (khóa `eventId`, nên sự kiện phát lại không tạo trùng), tra `flowRef`, tạo hoặc cập nhật API `origin = FLOW`, đọc đặc tả OpenAPI do PH-04 sinh qua `Ph04FlowClient`, chạy kiểm tra, tạo phiên bản `DRAFT` có backend `FLOW`. `ContractGuard` là điểm duy nhất quyết định trường nào sửa được: với `origin = FLOW`, đường dẫn và lược đồ khóa (BR-02-030); với phiên bản `PUBLISHED`, chỉ mô tả, SLA, thẻ (Q02-03); với `PENDING`, không trường nào (ERR-02-038).

### 4.4. Bộ kiểm tra đặc tả

::: dac-ta
**Mục đích.** Kiểm tra đặc tả hai lớp (chuẩn OpenAPI 3.1 và quy ước nền tảng), quét bí mật và dữ liệu cá nhân thật, phát hiện API trùng chức năng; luôn chạy trong giới hạn thời gian và bộ nhớ, tách khỏi luồng xử lý yêu cầu.

**Lớp chính.** `SpecLinter`, `LintExecutor`, `Layer1Validator`, `ConventionRuleSet` (bản cài đặt `LintRule` cho LINT-02-01…15), `SecretScanner` (SCAN-02-01…09), `DuplicateDetector`, `FindingStore`, `SubmissionGate` (dùng chung với mục 4.7).

**Đơn vị chạy.** `api` (hồ sơ `QM-NHO`, `QM-VUA`); `lint-worker` (hồ sơ `QM-LON`, `QM-CHUNG`).

**FR hiện thực.** FR-02-016…021; NFR-02-003, 011, 012.

**Giao diện vào.** API-02-020…025, 092 (chấp nhận cảnh báo), 093, 094 (đề nghị và xác nhận "không phải bí mật"); gọi từ `SpecIngestService`, `SubmissionGate`, `LegacyApimImporter`, `FlowRegistrationService`.

**Phụ thuộc ra.** Garage (đọc đặc tả); OpenBao transit (khóa HMAC theo tenant cho dấu vân tay phát hiện); PH-18 (tham số).

**Dữ liệu.** `lint_finding`, `lint_rule`, `lint_rule_override`, `api_version.minhash`.

**Sự kiện.** Không; cảnh báo bí mật qua trung tâm thông báo (FR-00-060) cho SV và SO.

**Lỗi và xử lý.** ERR-02-006 (lớp 1), 007 (lớp 2), 008 (bí mật), 034 (bộ quét lỗi thì chặn, không cho qua), 035 (đang kiểm tra cùng phiên bản), 036 (vượt `02.lint.max-per-hour` hoặc hàng đợi đầy), 041 (chấp nhận cảnh báo thiếu lý do).

**Quan sát.** `catalog_spec_validation_total{result,mode}`, `catalog_lint_duration_seconds{layer}`, `catalog_lint_queue_depth`, `catalog_secret_findings_total{rule}`.
:::

Chi tiết thiết kế:

`SpecLinter.run(spec, mode)` có hai chế độ: `PREVIEW` (FR-02-019, không ghi gì, dùng cho bước xem trước và cho nhà thầu chạy từ CI bằng token người dùng, GĐ-02-07) và `PERSIST` (ghi kết quả cho phiên bản). Đặc tả được phân tích **một lần** thành `SpecContext` bất biến: cây Jackson, danh sách thao tác, chỉ mục đường dẫn, bộ duyệt mọi giá trị chuỗi kèm con trỏ JSON; các luật chỉ đọc `SpecContext`, thuần, không I/O. Lớp 1 dùng bộ phân tích OpenAPI (swagger-parser v3) cộng kiểm lược đồ JSON Schema 2020-12 của OpenAPI 3.1, phát hiện `$ref` không giải được, `operationId` trùng, kiểu sai. Lớp 2 chạy 15 luật LINT-02-01…15 song song trên cùng `SpecContext`, mỗi luật có thời hạn 2 giây; luật quá hạn hoặc ném ngoại lệ bị bỏ qua và ghi nhật ký, cảnh báo TA (FRS FR-02-017), nhưng bộ luật không nạp được thì ERR-02-034.

`LintExecutor` bảo vệ DU khỏi đặc tả độc hại. Một semaphore giới hạn số lần kiểm tra đồng thời (mặc định 2 cho pod heap 1,2 GiB, vì cây của đặc tả 10 MiB có thể chiếm 100…150 MiB), hàng đợi tối đa 20, quá thì ERR-02-036; mỗi lần có hạn 20 giây, các vòng lặp duyệt cây kiểm `ctx.checkDeadline()` định kỳ để dừng hợp tác. Hết hạn thì trả ERR-02-034 (kết quả không tin cậy nên không cho qua, cùng nguyên tắc của FR-02-018). Ở `QM-LON` và `QM-CHUNG`, `RemoteLintRunner` chuyển việc sang Deployment `lint-worker` (cùng ảnh, profile khác, không có quyền ghi CSDL, chỉ đọc Garage qua URL ký sẵn); pod `api` khi đó không bao giờ giữ cây đặc tả lớn. Hai bản `InProcessLintRunner` và `RemoteLintRunner` cùng giao diện `LintRunner`. Hạn mức `02.lint.max-per-hour` mỗi người được đếm bằng Valkey (khóa dựng bằng hàm tạo tên có tenant, hết hạn sau 1 giờ); Valkey không truy cập được thì dùng bộ đếm cục bộ của từng pod, chấp nhận sai số vì đây chỉ là rào chống lạm dụng, còn rào bảo vệ tài nguyên là semaphore và hàng đợi ở trên.

`SecretScanner` quét giá trị chuỗi ở `example`, `examples`, `default`, `enum`, `description`, `servers`, `x-*` và mọi trường có tên chứa `key`, `token`, `secret`, `password`. Mọi mẫu chạy bằng RE2/J (thời gian tuyến tính) để một đặc tả không gây ReDoS. Mẫu cấu trúc: PEM; JWT ba đoạn base64url có đoạn đầu giải được thành JSON có `alg`; tiền tố khóa phổ biến; tiêu đề `Authorization` dài hơn 20 ký tự; `scheme://user:pass@`; số 12 chữ số có cấu trúc CCCD hợp lệ (mã tỉnh trong danh mục, chữ số giới tính và thế kỷ hợp lệ); số điện thoại di động đúng đầu số; thư điện tử ngoài miền giữ chỗ. Với chuỗi dài từ 20 ký tự ở trường nhạy cảm, tính entropy Shannon, nghi ngờ khi vượt 4,0 bit mỗi ký tự. Danh sách giữ chỗ hợp lệ (`{token}`, `<API_KEY>`, `***`, `xxxx`, miền `example.com`, `example.gov.vn`, `*.example`) lấy từ bảng cấu hình, chờ ATTT duyệt (Q02-11).

Nguyên tắc cứng: **chuỗi khớp không bao giờ rời `SecretScanner`**. Bộ quét trả `Finding` với vị trí, mã mẫu và bốn ký tự cuối đã che; thông điệp ngoại lệ, log, vết, sự kiện không chứa giá trị. Để "Đánh dấu không phải bí mật" (SO xác nhận) chỉ áp cho đúng giá trị đó mà không phải lưu giá trị, dấu vân tay phát hiện là `HMAC-SHA256(khóa tenant, giá trị)` cộng mã mẫu và con trỏ JSON; lần quét sau cùng vân tay thì giữ `ACKNOWLEDGED`, vân tay mới thì mở lại `OPEN`. Kiểm thử canary NFR-02-012 gieo giá trị `DH-CANARY-…` vào đặc tả rồi tìm trong log, vết, kết quả, sự kiện, CSDL: phải không thấy.

Kết quả lưu ở `lint_finding` theo `(version_id, rule_id, fingerprint)`: lần chạy mới đánh `RESOLVED` các phát hiện không còn, giữ `ACKNOWLEDGED` của luật cho phép chấp nhận. Luật `ERROR` ở cột "Điều chỉnh ở tenant = Không" (LINT-02-01, 03, 04, 07, 08, 09, 11, 13, 14) không cho hạ mức và không cho chấp nhận; `lint_rule_override` chỉ ghi được cho luật có `adjustable = true` (FR-02-021, ERR-02-040 khi vượt giới hạn).

`DuplicateDetector` (FR-02-020) tính điểm giống nhau trong tenant: 0,5 × Jaccard của tập `(phương thức, mẫu đường dẫn)` đã chuẩn hóa (tên tham số đường dẫn thành `{}`), 0,3 × Jaccard của tập tên trường phản hồi, 0,2 × độ giống cosin của từ khóa tên và mô tả đã bỏ dấu. Để rẻ ở 2.000 API, mỗi phiên bản có chữ ký MinHash 128 giá trị lưu ở `api_version.minhash`; so sánh vét cạn 2.000 × 128 số nguyên chưa tới 10 ms, rồi tính chính xác cho năm ứng viên cao nhất. Ngưỡng `02.duplicate.threshold` (0,8); kết quả chỉ là gợi ý cho người duyệt, không chặn.

### 4.5. Backend, đường dẫn và khung route

::: dac-ta
**Mục đích.** Khai báo đích phía sau gateway của từng phiên bản (HTTT qua kết nối PH-05 hoặc luồng PH-04), cân bằng tải, kiểm tra sức khỏe, giữ context-path duy nhất, và sinh khung luồng ở PH-04 từ đặc tả.

**Lớp chính.** `BackendService`, `TargetPolicy`, `HealthReader`, `ContextPathService`, `RouteSkeletonService`, `AsyncOperationRunner`.

**Đơn vị chạy.** `api`; `worker` cho thao tác khung route bất đồng bộ.

**FR hiện thực.** FR-02-022…026; NFR-02-005, 008.

**Giao diện vào.** API-02-026…032, API-02-007 (PH-04 đọc đặc tả), API-02-095 (tra tiến độ tác vụ do `AsyncOperationRunner` chạy).

**Phụ thuộc ra.** PH-05 (kiểm tra kết nối), PH-04 (tạo luồng từ đặc tả), PH-13 (sức khỏe), PH-01 (HTTT).

**Dữ liệu.** `backend`, `context_path_reservation`, `async_operation`, `pending_command`.

**Sự kiện.** EVT-02-02 (đổi backend, `changedFields = backends`); tiêu thụ EVT-04-07 (luồng phát hành, backend `PLACEHOLDER` thành `ACTIVE`).

**Lỗi và xử lý.** ERR-02-019 (context-path), 020 (backend không hợp lệ), 021 (thiếu backend hoặc gói), 023 (tham số không hợp lý), 034 (PH-04, PH-05 ngừng thì xếp hàng), 040 (vượt `02.backend.max-per-version`). Backend của phiên bản `PUBLISHED` không sửa trực tiếp: `BackendService.change` tạo yêu cầu duyệt loại `BACKEND_CHANGE` (FR-02-035) và trả `202`; khi duyệt xong, đường công bố có xác nhận ở mục 4.10 nạp lại cấu hình rồi mới ghi backend mới.

**Quan sát.** `catalog_backend_health{state}`, `catalog_route_skeleton_total{result}`, `catalog_contextpath_conflict_total`.
:::

Chi tiết thiết kế:

Backend không có trường URL tự do. `Backend.kind = SYSTEM` mang `targetRef = {connectionCode, basePath}` trỏ tới kết nối loại HTTP đã được duyệt ở PH-05 và được cấp cho tenant; `kind = FLOW` mang `{flowCode, environment}` của luồng PH-04 cùng tenant. Cách này làm cho BR-02-023 (đích nằm trong danh sách cho phép, TLS ≥ 1.2, không địa chỉ nội bộ) đúng **theo cấu trúc**: kiểm tra địa chỉ do PH-05 làm lúc duyệt kết nối (SEC-16), PH-02 chỉ xác minh kết nối còn hiệu lực và đúng loại, và từ chối tên máy chủ chứa địa chỉ IP, `localhost`, hậu tố nội bộ làm lớp phòng thủ thứ hai. Việc cho phép "cấp kết nối cho API của PH-02" ở PH-05 là điều kiện cần (ghi ở "Đề nghị đồng bộ"). `TargetPolicy` còn kiểm trọng số 0…100 và tổng lớn hơn 0 (BR-02-024), `timeoutMs` ≤ `02.backend.max-timeout-ms`, thử lại chỉ cho phương thức an toàn hoặc thao tác khai `x-dh-idempotent: true`, số backend ≤ `02.backend.max-per-version`.

Cấu hình cân bằng tải và kiểm tra sức khỏe lưu thành dữ liệu (kiểu `roundrobin` có trọng số; kiểm tra chủ động theo đường dẫn, chu kỳ, ngưỡng lần đạt và lần hỏng; ngưỡng ngắt thụ động) và đi tới gateway qua dữ liệu công bố (mục 4.10); PH-03 mới là nơi dịch sang cấu hình APISIX. `HealthReader` đọc trạng thái thật từ `MetricsReadPort.backendHealth`, đệm 30 giây, trả `UP`, `DEGRADED`, `DOWN` hoặc `UNKNOWN` (FR-02-025).

`ContextPathService` sinh đường dẫn mặc định `/{nhóm}/{apiCode}/v{major}`, kiểm mẫu, và kiểm xung đột (trùng hoặc là tiền tố của đường dẫn khác) dưới `pg_advisory_xact_lock(hashtext(tenant || ':ctx'))` để hai người đăng ký cùng lúc không cùng thắng; khóa duy nhất ở `context_path_reservation` là chốt chặn. Đường dẫn bất biến sau `PUBLISHED`; khi phiên bản `RETIRED`, dòng giữ chỗ có `released_after = retired_at + 12 tháng` (BR-02-022). Bí danh `legacyPath` của API nhập từ hệ cũ có bảng riêng, được công bố song song cho giai đoạn chạy song song và có `Deprecation` ngay từ đầu.

`RouteSkeletonService` (FR-02-026) chạy bất đồng bộ qua `AsyncOperationRunner` (bảng `async_operation`, tiến độ theo FR-00-054): kiểm quyền của người dùng ở không gian làm việc PH-04 (ERR-02-014), gọi `Ph04FlowClient.createFromSpec(workspaceCode, flowCode, apiRef)`; PH-04 tự đọc đặc tả đã gộp qua API-02-007 bằng scope `catalog:flow-sync`, sinh `rest` DSL với khung chín chặng (BR-02-010); PH-02 ghi backend `FLOW` ở trạng thái `PLACEHOLDER` (chưa tính là `ACTIVE`). Khi nhận EVT-04-07 của luồng, `FlowEventHandler` chuyển backend sang `ACTIVE`. PH-04 ngừng thì lệnh nằm ở `pending_command` và được thử lại lùi dần; vòng đời API vẫn tiếp tục được nhưng chưa gửi duyệt được (ERR-02-021).

### 4.6. Gói sử dụng

::: dac-ta
**Mục đích.** Quản lý gói sử dụng (Plan) của phiên bản: kiểu xác thực ràng buộc theo mức phân loại, hạn mức, đường dẫn được phép, điều kiện đăng ký, vòng đời bốn trạng thái.

**Lớp chính.** `PlanService`, `PlanStateMachine`, `AuthPolicyMatrix`, `PlanCompatibilityChecker`, `PlanCloner`.

**Đơn vị chạy.** `api`.

**FR hiện thực.** FR-02-027…033; BR-02-016…019.

**Giao diện vào.** API-02-033…041, 096 (danh sách gói toàn tenant, truy vấn có phân trang trên `plan` nối `api_version`).

**Phụ thuộc ra.** `ReviewService` (duyệt công bố gói), `PublishCoordinator` (đưa gói ra gateway), PH-01 (nhóm HTTT được phép).

**Dữ liệu.** `plan`, `plan_operation_scope`, `review_request`.

**Sự kiện.** EVT-02-08 (gói đổi trạng thái hoặc khai báo).

**Lỗi và xử lý.** ERR-02-022 (xác thực yếu hơn mức phân loại), 023 (hạn mức không hợp lý), 024 (đóng gói còn đăng ký), 011 (sửa gói `PUBLISHED` theo hướng không tương thích), 013 (bốn mắt), 037 (thao tác không có trong đặc tả), 040 (vượt `02.plan.max-per-version`).

**Quan sát.** `catalog_plans_total{status,auth}`, `catalog_plan_auth_violation_blocked_total`.
:::

Chi tiết thiết kế:

`AuthPolicyMatrix` là hàm thuần trong `internal.domain`, tra bảng dưới cho cặp (mức phân loại, kiểu xác thực); gói `PUBLISHED` là bất biến theo hướng không hạ (BR-02-017) nên ma trận chỉ cần chạy khi tạo, sửa gói `STAGING`, khi đổi mức phân loại của API và khi nhập hệ cũ. Khi API đổi `dataClass` lên mức cao hơn, `PlanService.recheckAll` đánh dấu mọi gói không còn hợp lệ là "Cần nâng xác thực" và chặn gửi duyệt cho tới khi sửa, thay vì tự đổi.

| Mức phân loại | Kiểu xác thực cho phép | Ghi chú |
|---|---|---|
| `PUBLIC` | `KEYLESS` (chỉ khi mức hiển thị `PUBLIC`), `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` | `KEYLESS` bắt buộc đi kèm giới hạn theo IP và WAF mặc định ở PH-03 (SEC-10, SEC-11, Q02-12) |
| `INTERNAL` | `API_KEY`, `OAUTH2_SECRET`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` | `OAUTH2_SECRET` theo giai đoạn chuyển đổi, bí mật ≥ 256 bit, hết hạn ≤ 180 ngày (SEC-24, thực thi ở PH-01) |
| `RESTRICTED` | `OAUTH2_PKJWT`, `OAUTH2_MTLS` | Cấm `client_secret` (SEC-24) |
| `SENSITIVE` | `OAUTH2_MTLS` | Token ràng buộc chứng thư `cnf.x5t#S256` |

: Ma trận mức phân loại và kiểu xác thực của gói

`PlanCompatibilityChecker.compare(cũ, mới)` quyết định sửa gói `PUBLISHED` có được không: hạn mức mỗi chiều không giảm, tập thao tác cho phép chỉ rộng ra, kiểu xác thực không đổi, nhóm HTTT được phép chỉ rộng ra thì tương thích; mọi thay đổi khác trả ERR-02-011 kèm gợi ý "tạo gói mới rồi ngừng khuyến nghị gói cũ". `PlanStateMachine` giữ bốn trạng thái `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED` (mục 8.1); công bố gói của phiên bản đã `PUBLISHED` đi qua `ReviewService` (bốn mắt) rồi `PublishCoordinator` vì gói mới tạo thêm một nhóm consumer ở gateway; gói đi cùng lần công bố phiên bản thì chuyển `PUBLISHED` cùng giao dịch xác nhận. Đóng gói (FR-02-032) đếm đăng ký hiệu lực dưới khóa dòng phiên bản để không lọt đăng ký mới trong lúc đếm (mục 4.1). Sao chép gói sang phiên bản mới (FR-02-033) tạo gói `STAGING` cùng mã, bỏ đăng ký, để quy tắc "gói đang có đăng ký phải có gói cùng mã ở phiên bản thay thế" (BR-02-035) kiểm được bằng mã gói.

### 4.7. Vòng đời, duyệt, tạm ngừng và ngừng dùng

::: dac-ta
**Mục đích.** Điều phối vòng đời của phiên bản API: gửi duyệt với kiểm tra điều kiện, duyệt bốn mắt, công bố, tạm ngừng khẩn, ngừng khuyến nghị có lộ trình, ngừng hẳn, xóa mềm, đặt mức hiển thị, chuyển chủ quản và tạo phiên bản mới.

**Lớp chính.** `ApiVersionService`, `VersionStateMachine`, `SubmissionGate`, `ReviewService`, `ReviewPolicy`, `SuspensionService`, `DeprecationService`, `RetireWatcher`, `VisibilityService`, `TransferService`, `ReviewOverdueWatcher`.

**Đơn vị chạy.** `api` (lệnh người dùng), `worker` (hạn tạm ngừng, nhắc, ngừng hẳn, quá hạn duyệt).

**FR hiện thực.** FR-02-034…042, 045; NFR-02-005, 015.

**Giao diện vào.** API-02-042…057, 098 (chi tiết yêu cầu duyệt: điều kiện lấy từ `SubmissionGate`, lịch sử từ `review_decision`).

**Phụ thuộc ra.** `SpecLinter`, `DiffEngine`, `PublishCoordinator`, `NoticeService`, `NationalSyncService`, PH-18 (hộp việc, lịch ngày làm việc), PH-01.

**Dữ liệu.** `api_version`, `version_state_history`, `version_contributor`, `review_request`, `review_decision`, `deprecation_reminder`.

**Sự kiện.** EVT-02-04, 05, 06, 16 và EVT-02-02, EVT-02-03.

**Lỗi và xử lý.** ERR-02-011, 012 (kèm danh sách điều kiện thiếu), 013 (bốn mắt), 015 (băm đặc tả lệch), 017 (phá vỡ giữ số chính), 018, 030 (còn người dùng), 031, 032, 033, 038, 039 (đóng băng thay đổi), 041, 043.

**Quan sát.** `catalog_review_pending_age_seconds`, `catalog_publish_duration_seconds`, `catalog_deprecated_in_use_total`, `catalog_version_transitions_total{from,to}`.
:::

Chi tiết thiết kế:

`VersionStateMachine` là danh sách bất biến các bộ năm (từ, lệnh, điều kiện bảo vệ, hành động, đến), khai báo một lần và là nguồn duy nhất cho dịch vụ, cho danh sách hành động khả dụng trả kèm mỗi phiên bản ở giao diện, và cho kiểm thử bảng chuyển (mục 8.1). Mọi chuyển trạng thái chạy dưới `SELECT … FOR UPDATE` dòng phiên bản, kiểm `If-Match`, bắt buộc lý do, ghi `version_state_history` (trước, sau, người, lý do) và một dòng outbox trong cùng giao dịch. Không có đường `UPDATE status` nào khác (luật ArchUnit ở mục 3.4).

`SubmissionGate.evaluate(version)` trả danh sách điều kiện, mỗi điều kiện có mã, đạt hay chưa, liên kết tới mục cần sửa; dùng cho cả lệnh gửi duyệt (ERR-02-012 liệt kê điều kiện thiếu) và để chạy lại ngay trước khi duyệt. Các điều kiện: không còn phát hiện `ERROR` chưa xử lý ở lớp 1, lớp 2, bí mật; không có thay đổi phá vỡ khi giữ số chính (ERR-02-017); có backend `ACTIVE` và gói; có cam kết SLA; đã triển khai thử TEST thành công cho đúng băm đặc tả và băm cấu hình (`lastTestDeploy`) khi `02.submit.require-test-deploy = true`; context-path đã giữ chỗ; HTTT cung cấp còn `ACTIVE` (bản sao PH-01 không cũ quá 24 giờ, `SystemDirectoryApi` trả `stale`); API gần giống đã được người gửi xem (FR-02-020). Gửi duyệt khóa nội dung: phiên bản sang `PENDING`, `ContractGuard` từ chối mọi sửa (ERR-02-038), và `ReviewService.open` tạo `review_request` kèm việc ở "Việc của tôi" (EVT-02-04).

`ReviewService.decide` xử lý duyệt: nạp `version_contributor` (người tạo, người sửa đặc tả, người sửa gói, người gửi duyệt), `ReviewPolicy.assertIndependent` so **theo định danh người dùng**, không theo vai trò (ADR-046) và từ chối ERR-02-013; API `SENSITIVE` cần hai quyết định `APPROVE` từ hai người khác nhau mang `PERM-02-publish` ở mức CA và TA (BR-02-008). Chạy lại `SubmissionGate` và so băm đặc tả với băm lúc gửi (lệch thì ERR-02-015, đưa về `DRAFT`). Quyết định `APPROVE` cuối cùng **không** đổi trạng thái sang `PUBLISHED`; nó đặt cờ `approved_at` và đăng ký công việc công bố cho `PublishCoordinator` (mục 4.10), vì `PUBLISHED` chỉ đúng khi cổng đã nhận cấu hình. Từ chối thì về `DRAFT` kèm ý kiến, thông báo người gửi.

Tạm ngừng (FR-02-037) áp dụng nguyên tắc "hạn chế thì áp ngay": `SuspensionService` đặt `SUSPENDED` và bump `sourceVersion` trong một giao dịch, trả về ngay; việc gỡ route ở gateway theo sau qua `PublishCoordinator` và được theo dõi bằng trạng thái `gatewayState` (`APPLYING`, `SYNCED`, `FAILED`) hiển thị ở UI-02-02. Tiếp tục thì ngược lại, chờ xác nhận mới đặt `PUBLISHED`. `SuspensionWatcher` chạy hằng ngày: nhắc ở ngày `02.suspend.max-days − 3`, tới hạn thì tạo yêu cầu quyết định "tiếp tục hoặc ngừng khuyến nghị" và cảnh báo; không tự đổi trạng thái (BR-02-034). Tạm ngừng do SO vì an ninh chỉ SO hoặc TA tiếp tục được.

`DeprecationService` (FR-02-038): kiểm có phiên bản kế nhiệm `PUBLISHED` hoặc xác nhận ngừng hẳn dịch vụ (BR-02-005, ERR-02-032); `sunsetAt` không sớm hơn `now + 02.deprecation.min-days` (ERR-02-031), ngoại lệ khi có `urgentReason` và TA đồng ý trong yêu cầu duyệt; mở `review_request` loại `DEPRECATE`; sau duyệt đặt `DEPRECATED`, đưa gói sang `DEPRECATED`, ghi `deprecation_reminder` cho các mốc `02.deprecation.reminders` (90, 30, 7 ngày), phát thông báo bắt buộc (BR-02-029) và bump `sourceVersion` để gateway thêm tiêu đề `Deprecation`, `Sunset` (RFC 9745, RFC 8594) vào mọi phản hồi. `RetireWatcher` hằng ngày xét phiên bản `DEPRECATED` quá `sunsetAt`: còn đăng ký hiệu lực thì **không** tự `RETIRED`, tăng `catalog_deprecated_in_use_total`, cảnh báo SV, CA, TA; không còn thì mở yêu cầu duyệt loại `RETIRE` (FR-02-039). Hạ mức hiển thị (FR-02-041) có hiệu lực ngay và rút bản ghi quốc gia; nâng lên `NATIONAL`, `PUBLIC` đi qua duyệt của CA (BR-02-037). Chuyển chủ quản (FR-02-045) chỉ TA, ghi số và ngày văn bản (Q02-07), phát EVT-02-02.

Phiên bản mới (FR-02-042): `ApiVersionService.create` tạo phiên bản `DRAFT` từ phiên bản nguồn, sao chép backend, đặc tả, SLA làm khởi điểm, sao chép gói thành `STAGING` cùng mã; số hiệu phải lớn hơn mọi số đã dùng (ERR-02-018); khác số chính thì chạy song song ở đường dẫn riêng, cùng số chính thì khi công bố sẽ thay phiên bản đang chạy theo BR-02-035. Đóng băng thay đổi môi trường thật (ERR-02-039) đọc từ PH-18 trước mọi lệnh ảnh hưởng PROD.

### 4.8. So sánh phiên bản và phân tích tác động

::: dac-ta
**Mục đích.** Cho chủ dịch vụ và người duyệt thấy hai phiên bản khác nhau ở đâu, thay đổi nào làm hỏng bên khai thác hiện có, và bên nào bị ảnh hưởng.

**Lớp chính.** `DiffEngine`, `SchemaDiff`, `ChangeClassifier`, `VersionAdvisor`, `ImpactAnalyzer`, `DiffResultCache`.

**Đơn vị chạy.** `api` (đặc tả nhỏ), `worker` (đặc tả lớn, bất đồng bộ).

**FR hiện thực.** FR-02-043, 044; BR-02-003.

**Giao diện vào.** API-02-042…057 (nhóm vòng đời, phiên bản), dùng trong `SubmissionGate`.

**Phụ thuộc ra.** Garage (đặc tả đã gộp), PH-13 (thao tác nào được gọi), PH-01 (đầu mối bên bị ảnh hưởng).

**Dữ liệu.** `diff_result` (khóa `(from_sha256, to_sha256)`), `subscription`, `plan`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-02-001 (thiếu phiên bản), 006 (đặc tả chưa đạt lớp 1), 035 (đang so sánh cùng cặp); đặc tả quá lớn thì chạy nền với tiến độ (FR-00-054).

**Quan sát.** `catalog_diff_duration_seconds`, `catalog_diff_changes_total{class}`, `catalog_diff_cache_hit_total`.
:::

Chi tiết thiết kế:

`DiffEngine` so sánh theo cấu trúc chứ không so văn bản. Hai đặc tả đã gộp tham chiếu được chuẩn hóa: bỏ `description`, `example`, `x-*` khỏi so sánh; tên tham số đường dẫn coi như tương đương (`/ho-so/{id}` và `/ho-so/{maHoSo}`); thao tác định danh bằng `(phương thức, mẫu đường dẫn)`; tham số bằng `(vị trí, tên)`; phản hồi bằng mã trạng thái. `SchemaDiff` đệ quy qua lược đồ với tập `(refTừ, refĐến)` đã thăm để không lặp vô hạn ở tham chiếu vòng; độ sâu ≤ 50; kết quả quá 5.000 thay đổi thì tóm tắt phần còn lại. Hệ quả của bảng phân loại ở FR-02-043 (xóa đường dẫn, xóa hoặc đổi kiểu trường phản hồi, thêm trường bắt buộc vào yêu cầu là `BREAKING`; thêm thao tác, thêm trường tùy chọn là `COMPATIBLE`; `oneOf`, `anyOf`, thu hẹp `enum` khó xác định là `UNCERTAIN`) được cài vào `ChangeClassifier` dưới dạng bảng luật có thứ tự, mỗi luật có mã nội bộ và ca kiểm thử riêng; thay đổi `UNCERTAIN` bắt người dùng xác nhận tay trước khi gửi duyệt.

`VersionAdvisor` đề xuất số hiệu tiếp theo (`MAJOR` khi `breaking`, `MINOR` khi thêm tương thích, `PATCH` khi chỉ sửa mô tả, ví dụ) và đặt `versionViolation = true` khi có `BREAKING` mà số chính không tăng; cờ này chặn ở `SubmissionGate` (ERR-02-017). Vì hai đặc tả bất biến, kết quả lưu ở `diff_result` theo cặp băm là bộ đệm vĩnh viễn đúng: lần xem lại hay người duyệt mở sau chỉ đọc bảng. Đặc tả mỗi bên ≤ 1 MiB so sánh đồng bộ (NFR-02-004: ≤ 3 giây với 5.000 dòng); lớn hơn chạy nền, khóa tư vấn theo băm cặp để cùng cặp chỉ chạy một lần (ERR-02-035). Kiểm thử đối chiếu dùng thư viện `openapi-diff` làm nguồn so khớp thứ hai trong CI (không dùng khi chạy thật): hai bên lệch nhau ở thay đổi `BREAKING` thì ca kiểm thử đỏ để người viết luật xem lại.

`ImpactAnalyzer` ghép danh sách thay đổi với đăng ký hiệu lực của phiên bản nguồn và lượng gọi theo thao tác của 30 ngày gần nhất (`MetricsReadPort.operationUsage`), nên một HTTT chỉ gọi thao tác không đổi không bị liệt kê là bị ảnh hưởng. Danh sách bên bị ảnh hưởng chỉ hiện cho SV của API đó, CA và TA, không bao giờ hiện cho bên khai thác khác (bảo vệ thông tin ai đang dùng gì). Kết quả nuôi màn hình UI-02-05, UI-02-13 và danh sách người nhận của thông báo (mục 4.12).

### 4.9. Đăng ký sử dụng và cấp phạm vi

::: dac-ta
**Mục đích.** Nhận đăng ký sử dụng của HTTT, duyệt hoặc tự duyệt theo chính sách, rồi biến đăng ký đã duyệt thành quyền gọi thật (phạm vi ở PH-12, consumer ở gateway) mà không ai cấp tay; thu hồi, tạm ngừng, gia hạn và rà soát định kỳ.

**Lớp chính.** `SubscriptionService`, `SubscriptionStateMachine`, `SubscriptionApprovalPolicy`, `ScopeCalculator`, `GrantOrchestrator`, `GrantJanitor`, `RenewalScheduler`, `SystemEventHandler`.

**Đơn vị chạy.** `api` (gửi, duyệt, thu hồi), `worker` (cấp quyền, gia hạn, xử lý sự kiện PH-01).

**FR hiện thực.** FR-02-046…052; NFR-02-005; BR-02-011, 012, 025…027, 036.

**Giao diện vào.** API-02-058…068.

**Phụ thuộc ra.** PH-01 (`SystemDirectoryApi`: HTTT, định danh máy), PH-12 (`ScopeGrantPort`), PH-03 qua `PublishCoordinator`, PH-18 (việc, thông báo).

**Dữ liệu.** `subscription`, `grant_job`, `subscription_state_history`, `review_request`.

**Sự kiện.** EVT-02-09 (chờ duyệt), EVT-02-10 (đã cấp phạm vi), EVT-02-11 (từ chối, tạm ngừng, thu hồi, hủy, hết hạn); tiêu thụ sự kiện tạm ngừng, thu hồi HTTT và cấp định danh máy của PH-01.

**Lỗi và xử lý.** ERR-02-025 (gói, phiên bản không nhận đăng ký), 026 (HTTT khai thác không hợp lệ), 027 (đã có đăng ký hiệu lực), 028 (không thuộc đối tượng gói), 029 (thiếu mục đích, khối lượng, căn cứ), 013, 022 (xác thực không phù hợp), 033, 034 (PH-12, PH-03 ngừng thì thử lại).

**Quan sát.** `catalog_subscriptions_total{status}`, `catalog_grant_duration_seconds`, `catalog_grant_failed_total{step}`, `catalog_grant_awaiting_credential`, `catalog_grant_detach_pending`.
:::

Chi tiết thiết kế:

`SubscriptionService.submit` chạy trong một giao dịch: khóa dòng phiên bản bằng `FOR SHARE` (để việc ngừng hẳn phiên bản không chen vào giữa, mục 4.1), kiểm phiên bản và gói đều `PUBLISHED` (ERR-02-025), HTTT khai thác `ACTIVE` ở PH-01 và thuộc tổ chức của người gửi (ERR-02-026), thuộc nhóm được phép của gói (ERR-02-028), chưa có đăng ký hiệu lực (chỉ mục duy nhất từng phần, ERR-02-027), có mục đích, khối lượng, và căn cứ pháp lý khi dữ liệu cá nhân hoặc từ mức Hạn chế (ERR-02-029, BR-02-012). Tự duyệt chỉ khi `plan.autoApprove` và mức phân loại không vượt `02.subscription.auto-approve.max-class`; khi đó đăng ký vào `ACTIVE` ngay trong giao dịch với người thực hiện `SYSTEM`. Còn lại tạo `review_request` loại `SUBSCRIBE`; `SubscriptionApprovalPolicy` quyết định ai duyệt được: SV của đơn vị chủ quản API hoặc CA với dữ liệu dưới mức Hạn chế, CA hoặc TA với từ Hạn chế trở lên (BR-02-026).

Phạm vi do `ScopeCalculator` tính: `api:{apiCode}:{planCode}` và, nếu đăng ký giới hạn thao tác, thêm `api:{apiCode}:{planCode}:{operationId}`; tối đa 50 phạm vi mỗi đăng ký (Q02-24). `GrantOrchestrator` là một saga lưu bền ở `grant_job`, mỗi bước có khóa lũy đẳng `grant:{subscriptionId}:{bước}` nên chạy lại bao nhiêu lần cũng không nhân đôi hiệu ứng:

| Bước | Việc | Thành công | Thất bại tạm thời | Ghi chú |
|---|---|---|---|---|
| 1. `CREDENTIAL_CHECK` | Hỏi PH-01 định danh máy của HTTT phù hợp kiểu xác thực của gói (client, thêm chứng thư với `OAUTH2_MTLS`) | Sang bước 2 | ERR-02-034, thử lại | Chưa có: `grantStatus = AWAITING_CREDENTIAL`, tạo việc cho OR, **không phải lỗi**; tiếp tục khi nhận sự kiện PH-01 |
| 2. `SCOPE_ATTACH` | `ScopeGrantPort.attach(clientId, scopes)` ở PH-12; PH-12 cập nhật client Keycloak và chính sách OPA | Sang bước 3 | ERR-02-034, thử lại | Gói `KEYLESS`: bỏ bước này |
| 3. `GATEWAY_APPLY` | Bump `sourceVersion` (consumer vào nhóm của gói), `PublishCoordinator` chờ APISIX xác nhận nạp | Sang bước 4 | ERR-02-033, thử lại | Gói `API_KEY`: khóa do PH-01 cấp, PH-03 giữ băm |
| 4. `GRANTED` | Đặt `grantStatus = GRANTED`, `grantedAt`, thông báo HTTT khai thác kèm đường dẫn | Xong | Không | Mục tiêu p95 ≤ 30 giây từ lúc duyệt (NFR-02-005) |

: Các bước cấp phạm vi

Thử lại lùi dần tối đa 5 lần trong 15 phút; hết lần thì `grantStatus = FAILED`, cảnh báo TO, và phần đã gắn thành công **không bị gỡ** cho tới khi có quyết định (tránh trạng thái nửa vời khó theo dõi) mà được đánh dấu `cleanup_mark`; `GrantJanitor` dọn khi TO chọn "Cấp lại" thành công hoặc "Hủy cấp". PH-12 đứng trước PH-03 có chủ ý: nếu chỉ một nhánh xong thì lời gọi vẫn bị từ chối (`403`), không có trạng thái nào cho gọi nhầm. Thu hồi, tạm ngừng theo nguyên tắc "hạn chế thì áp ngay": đăng ký đặt `REVOKED` hoặc `SUSPENDED` tức thì cùng lần bump `sourceVersion` gỡ consumer; việc gỡ phạm vi ở PH-12 theo sau bằng thử lại bền (`catalog_grant_detach_pending` cảnh báo khi tồn quá 15 phút); mục tiêu lượt gọi kế tiếp bị chặn trong 30 giây (tiêu chí chấp nhận 5 của FRS).

`SystemEventHandler` xử lý sự kiện của PH-01 qua `inbox_event`: HTTT bị tạm ngừng thì mọi đăng ký `ACTIVE` của HTTT đó sang `SUSPENDED` (lý do `SYSTEM_SUSPENDED`); bị thu hồi thì sang `REVOKED`; cấp xong định danh máy thì đánh thức các `grant_job` đang `AWAITING_CREDENTIAL`. Đăng ký nhập từ hệ cũ ở `SUSPENDED` với lý do `MIGRATED_AWAITING_CREDENTIAL` (BR-02-036) không tự kích hoạt khi định danh xuất hiện: SV hoặc CA bấm xác nhận một lần rồi `GrantOrchestrator` chạy, để quyết định từ hệ cũ được xác nhận lại trên hệ mới. `RenewalScheduler` (FR-02-052, Đợt 2) hằng ngày tạo việc nhắc OR và SV khi đăng ký còn 30 ngày tới `expiresAt` hoặc tới chu kỳ `02.subscription.review-months`; tới hạn không gia hạn thì `EXPIRED` và đi đường thu hồi.

### 4.10. Dữ liệu công bố cho gateway, công bố có xác nhận và đối soát

::: dac-ta
**Mục đích.** Là điểm duy nhất biến trạng thái đã duyệt thành dữ liệu cho PH-03, theo dõi việc APISIX đã nạp đúng số phiên bản, hoàn tất các chuyển trạng thái chờ xác nhận, và phát hiện cấu hình gateway lệch khỏi dữ liệu công bố.

**Lớp chính.** `PublishedConfigAssembler`, `ConfigEpoch`, `ConfigChangeLog`, `PublishCoordinator`, `PublishJobWorker`, `ServiceCallerFilter`, `DriftReconciler`.

**Đơn vị chạy.** `api` (giao diện nội bộ), `worker` (công bố, đối soát).

**FR hiện thực.** FR-02-036, 059, 060; NFR-02-005, 008, 020.

**Giao diện vào.** API-02-080…084, 095 (tiến độ đối soát); `PublishedConfigApi`, `GatewayAckApi`.

**Phụ thuộc ra.** Cổng `GatewayApplyPort` do module `gateway` (PH-03) cài đặt.

**Dữ liệu.** `config_epoch`, `config_change_log`, `publish_job`, `gateway_drift`.

**Sự kiện.** EVT-02-05, 06, 08 (khi `publish_job` hoàn tất), EVT-02-15 (lệch cấu hình).

**Lỗi và xử lý.** ERR-02-033 (cổng không nhận trong hạn: giữ trạng thái, thử lại), 019 (xung đột context-path phát sinh sau duyệt), 015 (băm lệch), 035 (đang đối soát), 014 (sai danh tính dịch vụ); `503` kèm `Retry-After` khi bảo trì.

**Quan sát.** `catalog_publish_duration_seconds`, `catalog_publish_jobs{status}`, `catalog_gateway_drift_total{kind}`, `catalog_gateway_config_lag_seconds`.
:::

Chi tiết thiết kế:

`ConfigEpoch` là bộ đếm `source_version` theo (tenant, môi trường). Mọi giao dịch làm đổi dữ liệu mà gateway cần biết (duyệt công bố, tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn, công bố hoặc đóng gói, cấp hoặc thu hồi consumer, sửa backend, đổi SLA có công bố) gọi `ConfigEpoch.bump` ở **câu lệnh cuối** của giao dịch (`UPDATE … SET source_version = source_version + 1 RETURNING`), đồng thời ghi một dòng `config_change_log`. Đặt ở cuối để khóa dòng bộ đếm, vốn tuần tự hóa mọi giao dịch cùng môi trường, chỉ bị giữ trong khoảng cuối cùng của giao dịch. Nhịp thay đổi cấu hình là vài lần mỗi phút (GĐ-02-01), nên điểm tuần tự này không là nút thắt; tải thay đổi thật sẽ đo ở bước 3 lộ trình.

`PublishedConfigAssembler.assemble(tenant, env)` đọc trong một giao dịch chỉ đọc mức `REPEATABLE READ` để cặp (`source_version`, dữ liệu) nhất quán. Mô hình trả về gồm, cho mỗi phiên bản đủ điều kiện: `apiCode`, `versionNo`, `major`, trạng thái và cờ `routeEnabled`, context-path (và bí danh hệ cũ), mức phân loại, danh sách thao tác (`operationId`, phương thức, mẫu đường dẫn, phạm vi cần có, con trỏ tới lược đồ trong đặc tả đã gộp để PH-03 sinh lược đồ kiểm tra yêu cầu, SEC-43), backend kèm trọng số và kiểm tra sức khỏe, gói kèm hạn mức và nhóm consumer (`clientId`, phạm vi, hạn mức riêng), và thông tin ngừng khuyến nghị (`sunsetAt`, kế nhiệm). Phiên bản `PUBLISHED`, `DEPRECATED` có `routeEnabled = true`; `SUSPENDED` xuất hiện với `routeEnabled = false` để PH-03 gỡ route; phiên bản `PENDING` đã duyệt và đang chờ công bố được đưa vào với cờ `activating = true`; môi trường TEST, STAGING thêm phiên bản `DRAFT` đang thử. Mỗi route mang `contentHash` (băm chuẩn của phần dữ liệu PH-02 cung cấp cho route đó); PH-03 đóng dấu băm này vào route đã sinh, nhờ vậy đối soát so **băm nguồn** với **băm nguồn** mà không phải hiểu cú pháp APISIX, còn việc kiểm tra cấu hình APISIX đã bị sửa tay hay chưa thuộc SEC-65.

Giao diện nội bộ (FR-02-059) trả `ETag` là `sourceVersion` và `304` khi chưa đổi. PH-03 thường gọi `changesSince(sourceVersion)` sau khi nhận sự kiện; `config_change_log` giữ 30 ngày, hỏi quá cũ thì phản hồi `gap = true` để PH-03 lấy toàn bộ (dòng JSON phân tách bằng xuống dòng, dạng luồng để không dựng cả cấu hình trong bộ nhớ; hồ sơ `QM-VUA` khoảng 10.000 route, trần `QM-CHUNG` khoảng 70.000). Gọi định kỳ 5 phút bù cho sự kiện bị mất. `ServiceCallerFilter` xác thực danh tính SPIFFE của người gọi (SEC-15) rồi ánh xạ sang scope: `gateway` → `catalog:gateway-read`, `portal` → `catalog:portal-read`, PH-04 → `catalog:flow-sync`, PH-13 và PH-16 → `catalog:metrics-read`; sai thì ERR-02-014, ghi nhật ký an ninh.

`PublishCoordinator` thi hành nguyên tắc chính của PH-02: **kích hoạt thì chờ xác nhận mới ghi, hạn chế thì ghi ngay rồi xác nhận sau**. Cách này bảo đảm trạng thái "đang gọi được" trong CSDL không bao giờ nói dối, còn trạng thái "đã bị chặn" áp dụng ngay cả khi cổng chậm.

| Chuyển trạng thái | Chính sách | Hoàn tất khi |
|---|---|---|
| Công bố phiên bản (`PENDING` → `PUBLISHED`) | Chờ xác nhận rồi ghi | APISIX báo `sourceVersion` ≥ mục tiêu |
| Tiếp tục phiên bản (`SUSPENDED` → `PUBLISHED`) | Chờ xác nhận rồi ghi | như trên |
| Công bố gói đang có phiên bản `PUBLISHED` | Chờ xác nhận rồi ghi | như trên |
| Cấp phạm vi (`GRANTED`) | Chờ xác nhận rồi ghi | như trên, sau bước PH-12 |
| Tạm ngừng phiên bản, đăng ký | Ghi ngay, xác nhận sau | `gatewayState = SYNCED` |
| Ngừng khuyến nghị, ngừng hẳn, đóng gói | Ghi ngay, xác nhận sau | như trên |
| Thu hồi đăng ký, hạ mức hiển thị | Ghi ngay, xác nhận sau | như trên |

: Chính sách xác nhận theo loại chuyển trạng thái

`publish_job` (`subject_kind`, `subject_id`, `transition`, `target_source_version`, `status`, `attempts`, `next_attempt_at`, `ticket`) được tạo trong cùng giao dịch với quyết định. `PublishJobWorker` lấy việc đến hạn bằng `FOR UPDATE SKIP LOCKED`, gọi `GatewayApplyPort.requestApply(env, target)` (lũy đẳng theo `(env, sourceVersion)`), rồi chờ xác nhận bằng hai đường: nhận `GatewayAckApi.onApplied` hoặc hỏi `status(ticket)` mỗi 2 giây tới 30 giây. Nhiều việc cùng môi trường dùng chung một xác nhận miễn `ack.sourceVersion ≥ target` của từng việc (gom nhóm tự nhiên khi đợt duyệt dồn dập). Trước khi hoàn tất loại "chờ xác nhận rồi ghi", `describe(env)` được gọi một lần để xác nhận route của đúng phiên bản có mặt ở ảnh chụp đã nạp (kiểm tra tối thiểu, tránh tin mù quáng vào một con số). Hết 30 giây chưa có xác nhận thì việc về `FAILED_RETRY` với lùi dần 30 giây, 1, 2, 4, 8 phút (5 lần trong khoảng 15 phút); hết lần thì `FAILED`, cảnh báo TO, phiên bản **giữ nguyên `PENDING`** (ERR-02-033). TO bấm "Thử lại công bố" (API-02-047) đặt lại `attempts`.

`DriftReconciler` (FR-02-060, Đợt 2) chạy mỗi 5 phút cho từng tenant và môi trường có gateway, dưới `pg_try_advisory_lock` để không chạy chồng (ERR-02-035). Nó gọi `describe(env)` để lấy số phiên bản cấu hình và băm của từng pod APISIX cùng danh sách route kèm `contentHash`, so với giá trị mong đợi từ `PublishedConfigAssembler`, rồi phân loại `MISSING_ROUTE`, `EXTRA_ROUTE`, `UPSTREAM_MISMATCH`, `CONSUMER_MISMATCH`, `VERSION_BEHIND` (pod chậm hơn mong đợi quá 60 giây). Khi `02.reconcile.auto-repair = true`, bốn loại đầu trừ `EXTRA_ROUTE` được sửa bằng `GatewayApplyPort.rebuild(env)`; route thừa **không** tự gỡ mà cảnh báo SO vì có thể là tấn công hoặc sửa tay. Phát hiện lệch ≤ 10 phút (NFR-02-020).

### 4.11. Đồng bộ danh mục quốc gia

::: dac-ta
**Mục đích.** Bảo đảm mọi API mức `NATIONAL`, `PUBLIC` có mặt trong danh mục dịch vụ chia sẻ của Nền tảng quốc gia, tự động khi công bố hay thay đổi và định kỳ hằng ngày, có hàng đợi bền và cảnh báo quá hạn.

**Lớp chính.** `NationalSyncService`, `NationalEligibility`, `PayloadBuilder`, `SyncDispatcher`, `SyncScheduler`, `OverdueWatcher`.

**Đơn vị chạy.** `worker`; hàng đợi ghi từ `api` trong giao dịch gốc.

**FR hiện thực.** FR-02-053, 054; BR-02-009, 037; NFR-02-014.

**Giao diện vào.** API-02-069…072; sự kiện nội bộ từ `lifecycle`.

**Phụ thuộc ra.** Cổng `NationalCatalogPort` (cài đặt `Ph14NationalClient`).

**Dữ liệu.** `national_sync_record`, `national_sync_run`.

**Sự kiện.** EVT-02-14 mỗi lần đổi trạng thái đồng bộ.

**Lỗi và xử lý.** ERR-02-034 (PH-14 ngừng: bản ghi `FAILED`, thử lại, không chặn vòng đời), ERR-02-044 (chưa đủ điều kiện), ERR-02-035 (đang đồng bộ cùng API); nền tảng quốc gia từ chối thì `REJECTED` kèm lý do.

**Quan sát.** `catalog_national_sync_status{status}`, `catalog_national_sync_overdue_total`, `catalog_national_sync_duration_seconds`.
:::

Chi tiết thiết kế:

`NationalSyncService.enqueue(versionId, action)` được gọi **trong cùng giao dịch** với sự kiện gốc (công bố, đổi trạng thái, sửa mô tả, mức hiển thị, chủ quản, xóa), nên không có khoảng hở để mất lệnh khi PH-14 hay Kafka ngừng (ADR-042). `NationalEligibility` là hàm thuần áp BR-02-009 và BR-02-037: mức hiển thị `NATIONAL` hoặc `PUBLIC`, `dataClass` khác `SENSITIVE`, trạng thái thuộc `PUBLISHED`, `DEPRECATED`, `SUSPENDED` cho `UPSERT`, và `RETIRED`, đã xóa, hạ mức cho `WITHDRAW`. `PayloadBuilder` dựng gói từ một `NationalServicePayload` bất biến chỉ gồm các trường được liệt kê (mã dịch vụ, tên, mô tả, đơn vị chủ quản, loại dữ liệu, mức phân loại, địa chỉ gọi công khai, liên kết đặc tả, phạm vi cần có, SLA cam kết, trạng thái, phiên bản, đầu mối); **không có đường nào đưa backend, địa chỉ nội bộ, danh sách bên đăng ký hay dữ liệu cá nhân vào gói**, vì kiểu dữ liệu không có chỗ chứa chúng và một kiểm thử phản xạ chặn việc thêm trường mà chưa có phê duyệt ATTT. Băm chuẩn của gói là `payloadHash`; ràng buộc duy nhất `(version_id, payload_hash)` làm cho xếp hàng lặp lại vô hại.

`SyncDispatcher` lấy tối đa `02.sync.batch-size` bản ghi `QUEUED` hoặc `FAILED` đến hạn bằng `FOR UPDATE SKIP LOCKED`, bỏ qua bản ghi của phiên bản đang còn bản ghi cũ hơn chưa kết thúc để giữ thứ tự `UPSERT` rồi `WITHDRAW`, đánh `SENT`, gọi `NationalCatalogPort.upsert(payload, payloadHash)` hoặc `withdraw(nationalRef, …)` với `Idempotency-Key` bằng `payloadHash`. Xác nhận thì `ACKED` kèm `nationalRef`; từ chối thì `REJECTED` kèm mã và lý do, thông báo SV và TO, không tự gửi lại khi nội dung không đổi; lỗi tạm thời thì `FAILED` với lùi dần 1, 5, 15, 60 phút rồi mỗi 6 giờ. `SyncScheduler` chạy theo `02.sync.cron` (múi giờ `Asia/Ho_Chi_Minh`): đối chiếu mọi phiên bản đủ điều kiện, xếp hàng những phiên bản có băm hiện tại khác băm lần `ACKED` gần nhất. `OverdueWatcher` mỗi giờ đếm phiên bản đủ điều kiện từ quá `02.sync.overdue-days` ngày mà chưa `ACKED`, đặt chỉ số `catalog_national_sync_overdue_total` và phát cảnh báo tuân thủ (BR-02-009). Khi `02.sync.enabled = false` hoặc PH-14 chưa cấu hình (`NationalCatalogPort` trả `NOT_CONFIGURED`), bản ghi giữ `QUEUED`, giao diện hiện "Chờ kết nối Nền tảng quốc gia" và **không tính quá hạn**. Giao thức, mã dịch vụ quốc gia, cách rút danh mục còn chờ đặc tả chính thức (Q02-08, GĐ-02-04): toàn bộ phần phụ thuộc đó nằm sau `NationalCatalogPort` và ánh xạ ở PH-14, nên khi đặc tả chốt chỉ phải đổi `PayloadBuilder` và bản cài đặt cổng.

### 4.12. SLA, thông báo thay đổi và thống kê

::: dac-ta
**Mục đích.** Ghi cam kết chất lượng của phiên bản, đối chiếu hằng tháng với số đo thực tế để kết luận đạt hay không (không kết luận khi thiếu dữ liệu), phát thông báo bắt buộc cho bên khai thác và cung cấp thống kê sử dụng.

**Lớp chính.** `SlaService`, `SlaEvaluator`, `SlaPeriodCloser`, `NoticeService`, `RecipientResolver`, `NoticeTemplates`, `UsageStatsService`.

**Đơn vị chạy.** `worker` (chốt kỳ, gửi thông báo, làm mới thống kê), `api` (khai báo, đọc).

**FR hiện thực.** FR-02-055…058; BR-02-013, 029, 031.

**Giao diện vào.** API-02-073…079, 097 (tổng hợp SLA toàn tenant từ `sla_period`).

**Phụ thuộc ra.** `MetricsReadPort` (PH-13), PH-18 (`NotificationApi`, lịch), PH-16 (qua giao diện nội bộ).

**Dữ liệu.** `sla_commitment`, `sla_maintenance_window`, `sla_period`, `change_notice`, `change_notice_recipient`, `usage_daily`.

**Sự kiện.** EVT-02-12 (thông báo đã phát), EVT-02-13 (chốt kỳ SLA).

**Lỗi và xử lý.** ERR-02-034 (PH-13 ngừng khi chốt kỳ: kỳ giữ `PENDING`, thử lại mỗi giờ tới 24 giờ, danh mục hiện kỳ gần nhất kèm thời điểm), ERR-02-036 (vượt `02.notice.announcement-max-per-day`), ERR-02-003.

**Quan sát.** `catalog_sla_compliance_ratio`, `catalog_sla_period_pending`, `catalog_notice_delivery_seconds{channel}`, `catalog_notice_failed_total{channel}`.
:::

Chi tiết thiết kế:

`sla_commitment` chỉ thêm dòng, không sửa: mỗi lần khai báo là một dòng có `effective_from`. Cam kết kém đi (hạ độ trễ, hạ sẵn sàng, rút giờ phục vụ) chỉ có hiệu lực sau `02.sla.worsen-notice-days` ngày kể từ lúc phát thông báo bắt buộc (BR-02-029); cam kết tốt lên có hiệu lực ngay. `SlaEvaluator` chạy mùng 1 hằng tháng lúc 02:00 (giờ Việt Nam) và thử lại mỗi giờ khi có kỳ `PENDING`. Với mỗi phiên bản có cam kết trùng kỳ, `MetricsReadPort.apiPeriod` trả: độ trễ p99 ở gateway, tổng lượt gọi, số lượt lỗi do hệ thống (`5xx`, hết thời gian chờ, backend không đáp ứng, **không** tính `4xx` và `429` của bên gọi theo đề xuất Q02-13), số ngày có dữ liệu, lượt cao nhất mỗi giờ. Bộ đánh giá trừ ra các khoảng `SUSPENDED` do quyết định quản lý (đọc từ `version_state_history`), cửa sổ bảo trì đã khai và ngoài giờ phục vụ; tính tỷ lệ sẵn sàng bằng `1 − lượt lỗi hệ thống / tổng lượt gọi` trong phần thời gian còn lại; `met = true` khi cả ba chỉ tiêu (p99, sẵn sàng, đỉnh theo giờ) đạt. Kỳ có dưới `02.sla.min-days-data` ngày dữ liệu hoặc dưới `02.sla.min-calls` lượt gọi được kết luận `INSUFFICIENT`, hiển thị "Chưa đủ dữ liệu", **không** tính vào chuỗi không đạt (BR-02-031). Từ `02.sla.breach-periods` kỳ `BREACHED` liên tiếp thì cảnh báo SV, CA, TA kèm gợi ý hành động; mỗi lần chốt phát EVT-02-13 và chuyển số liệu cho PH-16. TA có thể "Chốt lại kỳ" khi PH-13 bổ sung dữ liệu trễ: tính lại, ghi `recalculatedAt`, không xóa kết quả cũ (`sla_period` giữ phiên bản kết quả).

`NoticeService.issue(kind, versionId, mandatory)` phục vụ các loại thông báo bắt buộc của BR-02-029. `RecipientResolver` lấy đăng ký hiệu lực của phiên bản, với mỗi HTTT khai thác ghép đầu mối của đơn vị (OR) và đầu mối kỹ thuật ở bản sao PH-01, khử trùng lặp theo người nhận; mỗi người nhận một dòng `change_notice_recipient` kèm khóa lũy đẳng `{noticeId}:{recipient}:{channel}` khi gọi PH-18, nên gửi lại sau sự cố không tạo thư trùng. Kênh trong ứng dụng phải tới 100% bên liên quan trong 15 phút, thư điện tử trong 1 giờ (NFR-02-015); trạng thái `SENT`, `DELIVERED`, `FAILED` cập nhật từ PH-18. Bên nhận không tắt được loại bắt buộc. Nội dung đi qua `NoticeTemplates` (mẫu tiếng Việt có phiên bản), mọi giá trị chèn được thoát ký tự và cắt độ dài để một mô tả độc hại không thành nội dung thư. Thông báo tay của SV giới hạn `02.notice.announcement-max-per-day` mỗi API mỗi ngày (ERR-02-036). Bên nhận chỉ thấy thông tin của chính mình: thông báo không bao giờ liệt kê các bên khai thác khác.

`UsageStatsService` (FR-02-058, Đợt 2) kéo số liệu theo ngày từ PH-13 vào `usage_daily` (phiên bản, ngày, thao tác, HTTT khai thác, số lượt, số lỗi, p95), làm mới mỗi giờ cho ngày hiện tại. SV, CA, TA của API thấy chi tiết theo HTTT; VW thấy tổng hợp không có tên bên khai thác. Dữ liệu không chứa nội dung bản tin.

### 4.13. Di trú từ APIM cũ

::: dac-ta
**Mục đích.** Nhập API, gói, đăng ký từ hệ quản lý API cũ thành bản nháp có đặc tả bổ sung, có xem trước, nhập từng API trọn vẹn hoặc không, không nhập khóa hay bí mật, kèm báo cáo đối chiếu.

**Lớp chính.** `LegacyApimImporter`, `ApimExportParser`, `ImportPlanner`, `ImportCommitter`, `ImportReportBuilder`, `LegacyIdMap`.

**Đơn vị chạy.** `api` (tải lên, xem trước), `worker` (ghi).

**FR hiện thực.** FR-02-061; BR-02-015, 016, 036; LGC-APIM-001…021 (phần được di trú).

**Giao diện vào.** API-02-085…087.

**Phụ thuộc ra.** ClamAV, Garage (`legacy/`), `SpecIngestService`, `SecretScanner`, `PlanService`, `SubscriptionService`, PH-01 (`applicationMap`).

**Dữ liệu.** `import_session`, `legacy_id_map`, `api` (`origin = LEGACY`, `legacy_id`), `subscription` (lý do `MIGRATED_AWAITING_CREDENTIAL`).

**Sự kiện.** EVT-02-01 cho mỗi API nhập.

**Lỗi và xử lý.** ERR-02-045 (định dạng), 009 (quá 50 MiB), 002 (mã trùng, API đó bỏ qua), 004 (HTTT trong `applicationMap` không `ACTIVE`), 035 (đang có lần nhập).

**Quan sát.** `catalog_legacy_import_total{result}`, `catalog_legacy_import_secret_removed_total`.
:::

Chi tiết thiết kế:

Gói xuất của hệ cũ được xử lý như đầu vào không tin cậy: quét mã độc, giới hạn 50 MiB, nếu là ZIP thì theo SEC-45 (≤ 1.000 mục, ≤ 200 MB sau giải nén, tỉ lệ nén ≤ 100:1, không đường dẫn tuyệt đối hay `..`). `ApimExportParser` đọc kiểu luồng (Jackson streaming) nên không giữ cả gói trong bộ nhớ. `ImportPlanner` lập kế hoạch ánh xạ và lưu vào `import_session` (kế hoạch ở Garage `legacy/`, hạn 24 giờ): API thành `origin = LEGACY`, `DRAFT`, mã đề xuất theo quy ước, đặc tả Swagger (nếu có) qua `SpecIngestService`, nếu không thì đặc tả khung ở trạng thái "Cần bổ sung" nên không gửi duyệt được; backend cũ thành backend `SYSTEM` chưa có kết nối PH-05 (địa chỉ cũ giữ làm gợi ý văn bản, đã che thông tin xác thực nếu có, để kỹ sư tạo kết nối ở PH-05), chưa tính `ACTIVE` (BR-02-023); gói bốn trạng thái cũ sang bốn trạng thái mới, kiểu xác thực qua `AuthPolicyMatrix` và gói vi phạm được **đánh dấu** "Cần nâng xác thực" thay vì chặn nhập; đăng ký theo `applicationMap` thành đăng ký `SUSPENDED`. Mọi chuỗi giống khóa trong gói đều qua `SecretScanner` và bị loại, báo trong báo cáo; trường khóa API của hệ cũ không bao giờ được đọc vào mô hình.

`ImportCommitter` ghi mỗi API trong một giao dịch riêng (toàn bộ API đó hoặc không gì), lũy đẳng theo `legacy_id` (khóa duy nhất `(tenant_id, legacy_id)`), nên nhập lại không nhân đôi và một API lỗi không kéo cả đợt. `ImportReportBuilder` đếm API, gói, đăng ký ở nguồn và đã nhập, liệt kê phần chưa nhập kèm lý do, và tính `checksum` là SHA-256 của danh sách `(legacyId, kết quả)` đã sắp xếp để hai lần nhập cùng dữ liệu cho cùng tổng kiểm tra (FR-00-092). Cờ `catalog.legacy-import.enabled` mặc định bật trong giai đoạn strangler.

### 4.14. Tham số, bộ luật và phân loại

::: dac-ta
**Mục đích.** Cung cấp tham số `02.*` theo tenant có kiểm miền giá trị và trần nền tảng, quản lý bộ luật kiểm tra (mức hiệu lực theo tenant) và cây phân loại, thẻ của API.

**Lớp chính.** `CatalogSettings`, `SettingsAdminService`, `SettingsDefaults`, `FeatureFlags`, `RuleAdminService`, `CategoryService`, `TagService`.

**Đơn vị chạy.** `api`.

**FR hiện thực.** FR-02-008, 021, 062.

**Giao diện vào.** API-02-008…013, 023…025, 088, 089.

**Phụ thuộc ra.** PH-18 `ParameterApi`; OpenFeature.

**Dữ liệu.** `category`, `api_tag`, `lint_rule`, `lint_rule_override`; tham số lưu ở PH-18.

**Sự kiện.** EVT-02-02 khi đổi phân loại của API.

**Lỗi và xử lý.** ERR-02-040 (vượt trần), 003 (ngoài miền), 002 (mã nhóm trùng), 014; PH-18 ngừng thì dùng giá trị đã đệm, chưa có thì mặc định biên dịch sẵn.

**Quan sát.** `catalog_settings_stale_seconds`, `catalog_settings_changed_total{key}`.
:::

Chi tiết thiết kế:

`CatalogSettings` đọc `02.*` qua `ParameterApi` với bộ đệm Caffeine 60 giây (`refreshAfterWrite`), trả giá trị có kiểu (`Duration`, `int`, `Set<Integer>`). Ghi tham số đi qua `SettingsAdminService`: kiểm miền ở bảng FRS §8.2 và trần nền tảng của D03-10 rồi mới gọi PH-18; vượt thì ERR-02-040. `SettingsDefaults` là bản mặc định biên dịch sẵn dùng khi PH-18 chưa trả lời lần nào; một kiểm thử đọc bảng tham số của FRS (được sao thành tệp tài nguyên khi build) và so với `SettingsDefaults` để hai nơi không lệch nhau. Luật kiểm tra: `RuleAdminService` chỉ ghi `lint_rule_override` cho luật `adjustable = true`, ghi kiểm toán giá trị trước, sau; mẫu quét bí mật chỉ đọc (UI-02-15). Phân loại: `CategoryService` quản lý cây bằng `parent_id` và đường dẫn vật hóa (`path`), mã nhóm bất biến và không dùng lại (BR-02-021); gộp nhóm dời API sang nhóm đích trong một giao dịch và ghi EVT-02-02 cho mỗi API đổi.

### 4.15. Bộ nối với phân hệ ngoài

::: dac-ta
**Mục đích.** Gom mọi cuộc gọi ra ngoài `catalog` vào một gói có giao diện (port), có thời gian chờ, thử lại, ngắt mạch, danh tính dịch vụ và bản giả cho kiểm thử, để lỗi của phân hệ khác không lan vào miền.

**Lớp chính.** `Ph12ScopeClient`, `Ph14NationalClient`, `Ph04FlowClient`, `Ph05ConnectionClient`, `Ph10TopicClient`, `MimirMetricsClient`, `Ph18NoticeClient`, `ServiceTokenProvider`, `ResilienceConfig`.

**Đơn vị chạy.** `api`, `worker`.

**FR hiện thực.** FR-02-009, 013, 022, 026, 048, 053, 055, 056, 057.

**Giao diện vào.** Các cổng ở `catalog.spi` và `SystemDirectoryApi` (PH-01, trong tiến trình).

**Phụ thuộc ra.** PH-04, PH-05, PH-10, PH-12, PH-13, PH-14, PH-18 (chi tiết ở bảng dưới).

**Dữ liệu.** `pending_command` (lệnh chờ thử lại), `inbox_event`.

**Sự kiện.** Không phát; tiêu thụ EVT-04-02, 04, 07, EVT-10-01, 03, 04 và sự kiện PH-01.

**Lỗi và xử lý.** Mọi lỗi phụ thuộc ánh xạ thành ERR-02-034 hoặc ERR-02-033 (cổng); không rò thân lỗi của phía kia ra người dùng.

**Quan sát.** `catalog_adapter_calls_total{target,result}`, `catalog_adapter_duration_seconds{target}`, `catalog_adapter_circuit_state{target}`.
:::

Chi tiết thiết kế:

| Cổng | Bản cài đặt | Giao thức | Chờ, thử lại | Khi không khả dụng |
|---|---|---|---|---|
| `ScopeGrantPort` | `Ph12ScopeClient` | REST nội bộ PH-12, `Idempotency-Key` | 3 giây, 3 lần | Saga cấp quyền thử lại (mục 4.9); không cấp lỏng |
| `NationalCatalogPort` | `Ph14NationalClient` | REST nội bộ PH-14, `Idempotency-Key = payloadHash` | 10 giây, không thử lại trong lời gọi (hàng đợi lo) | Bản ghi `FAILED`, lùi dần (mục 4.11) |
| `GatewayApplyPort` | Bean của module `gateway` | Trong tiến trình | 30 giây chờ xác nhận | Giữ `PENDING`, thử lại (mục 4.10) |
| `FlowDirectoryPort` | `Ph04FlowClient` | REST `/api/integration/v1` | 5 giây, 2 lần | Xếp lệnh vào `pending_command`; không sinh được khung |
| `ConnectionVerifyPort` | `Ph05ConnectionClient` | REST `/api/adapter/v1` | 3 giây, 2 lần | Không chọn được kết nối mới; backend đã khai báo không đổi |
| `TopicDirectoryPort` | `Ph10TopicClient` | REST `/api/event/v1/topics` | 3 giây, 2 lần | Bản đệm 60 giây, cờ `stale` |
| `MetricsReadPort` | `MimirMetricsClient` | PromQL qua Mimir, `X-Scope-OrgID = tenant` (SEC-84) | 10 giây, 2 lần | Số liệu gần nhất đã đệm; kỳ SLA chờ chốt |
| `NotificationPort`, `TaskInboxApi` | `Ph18NoticeClient` | REST PH-18 | 3 giây, 3 lần, khóa lũy đẳng | Việc duyệt vẫn mở ở UI-02-10; thông báo vào hàng đợi |
| `SystemDirectoryApi` | Module `onboarding` | Trong tiến trình | Không | Dùng bản sao đệm; quá 24 giờ chặn đăng ký và công bố mới (FRS §12.1) |

: Cổng ra, bản cài đặt và cách xử lý khi phụ thuộc không khả dụng

`ServiceTokenProvider` lấy token dịch vụ bằng `client_credentials` với `private_key_jwt` của tài khoản `dh-connect-catalog` (SEC-24), đệm tới gần hết hạn (token sống 5 phút, SEC-25); mọi cuộc gọi đi qua mesh mTLS (SEC-15) và mang `traceparent`. `ResilienceConfig` dùng Resilience4j: ngắt mạch theo cửa sổ trượt 20 lượt, mở khi lỗi ≥ 50%, nửa mở sau 30 giây; ngăn cách bằng `Bulkhead` riêng cho từng cổng để PH-14 chậm không chiếm hết luồng của PH-12. Ánh xạ lỗi tập trung ở một `AdapterExceptionTranslator`: mọi lỗi mạng, `5xx`, ngắt mạch thành ERR-02-034; lỗi nghiệp vụ có nghĩa từ phía kia (ví dụ PH-12 báo client không tồn tại) thành lỗi miền riêng; thân lỗi của phía kia chỉ vào log đã che, không vào phản hồi. Mỗi cổng có hợp đồng kiểm thử hai chiều (nhà cung cấp và tiêu thụ) ở CI-5 để thay đổi `v1` của phía kia không làm hỏng PH-02 âm thầm.

## 5. Biểu đồ tuần tự

Chương này vẽ tám luồng có từ ba thành phần trở lên hoặc có duyệt bốn mắt. Thông điệp không dùng dấu chấm phẩy để Mermaid hiển thị đúng. Mỗi hình có một đoạn nói điều người đọc cần thấy.

### 5.1. Gửi duyệt, duyệt bốn mắt và công bố (FR-02-034, 035, 036)

Hình dưới là tuần tự gửi duyệt, duyệt bốn mắt rồi công bố, cho thấy quyết định duyệt và việc chờ gateway xác nhận là hai giao dịch khác nhau; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Gửi duyệt, duyệt bốn mắt và công bố API ra gateway"}
sequenceDiagram
  autonumber
  actor SV as Chủ dịch vụ
  actor CA as Người duyệt
  participant C as catalog api
  participant W as catalog worker
  participant DB as pg-core
  participant GW as gateway PH-03
  participant AP as APISIX
  participant K as Kafka
  SV->>C: POST versions/1.0.0:submit
  C->>C: SubmissionGate đánh giá lint, backend, gói, SLA, thử TEST
  C->>DB: PENDING, review_request OPEN, outbox EVT-02-04
  C-->>SV: 202 chờ duyệt
  CA->>C: POST reviews/{id}:approve
  C->>C: ReviewPolicy so định danh, chạy lại gate, so băm đặc tả
  C->>DB: decision APPROVE, publish_job QUEUED, bump sourceVersion N+1
  C-->>CA: 202 đang đẩy cấu hình
  W->>DB: lấy publish_job SKIP LOCKED
  W->>GW: requestApply PROD N+1
  GW->>C: PublishedConfigApi.snapshot
  C-->>GW: dữ liệu công bố sourceVersion N+1
  GW->>AP: ảnh chụp có chữ ký qua bucket Garage
  AP-->>GW: đã nạp configVersion
  GW->>C: GatewayAckApi.onApplied N+1
  alt Quá 30 giây không có xác nhận
    W->>DB: FAILED_RETRY, giữ PENDING, hẹn lại
  else Có xác nhận
    C->>C: describe PROD xác nhận route của phiên bản
    C->>DB: PUBLISHED, gói PUBLISHED, outbox EVT-02-05, national_sync QUEUED
    DB-->>K: EVT-02-05 qua hộp gửi
    C-->>SV: thông báo đã công bố
  end
```

Điều cần thấy ở hình: quyết định duyệt (bước 7) và việc đổi sang `PUBLISHED` (bước 18) là hai giao dịch khác nhau, ở giữa là việc chờ APISIX. Trong khoảng đó phiên bản vẫn `PENDING` và nội dung vẫn bị khóa; nếu cổng không xác nhận, mọi thứ dừng ở trạng thái an toàn và được thử lại. Bước 2 và bước 6 cho thấy hai lớp chặn: `SubmissionGate` ở lúc gửi, rồi chạy lại ở lúc duyệt, vì giữa hai lúc có thể một điều kiện đã đổi (HTTT cung cấp bị tạm ngừng, bản sao PH-01 quá cũ). Phiên bản cùng số chính thay phiên bản đang chạy cũng đi đường này; khi hoàn tất, cùng giao dịch chuyển đăng ký `ACTIVE` sang gói cùng mã và đưa phiên bản cũ sang `RETIRED` với lý do `SUPERSEDED` (BR-02-035).

### 5.2. Nạp đặc tả từ URL và kiểm tra không lưu (FR-02-011, 016…019)

Hình dưới là tuần tự nạp đặc tả từ URL qua bộ tải an toàn và kiểm tra không lưu; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Nạp đặc tả từ URL qua bộ tải an toàn và kiểm tra không lưu"}
sequenceDiagram
  autonumber
  actor SV as Chủ dịch vụ
  participant C as catalog api
  participant SF as SafeFetcher
  participant X as Máy chủ đặc tả
  participant AV as ClamAV DD-12
  participant GA as Garage
  participant L as SpecLinter
  participant DB as pg-core
  SV->>C: PUT versions/1.0.0/spec source=URL
  C->>SF: fetch url
  SF->>SF: https, phân giải DNS, kiểm dải riêng, ghim IP, kiểm FQDN egress
  alt Địa chỉ không được phép
    SF-->>C: bị chặn
    C-->>SV: 422 ERR-02-010
  else Hợp lệ
    SF->>X: GET qua egress gateway, chờ 15 giây
    X-->>SF: 200 YAML
    SF-->>C: luồng byte đã cắt theo giới hạn
    C->>AV: quét luồng
    AV-->>C: sạch
    C->>C: phân tích an toàn, chuyển 3.0 sang 3.1, gộp tham chiếu
    C->>GA: PUT specs/apiCode/sha256.json
    C->>DB: api_spec mới, current_spec_id, api_operation
    C->>L: preview
    L->>L: lớp 1, lớp 2, quét bí mật
    L-->>C: findings đã che
    C-->>SV: 200 thao tác, lỗi, cảnh báo
  end
```

Hình nhấn mạnh thứ tự: mọi kiểm tra rẻ và an toàn nhất đứng trước (địa chỉ, kích thước, mã độc), phân tích đặt sau mã độc, và đặc tả chỉ vào Garage khi đã qua phân tích; ghi Garage theo băm nên giao dịch CSDL hỏng ở bước 13 không để lại dữ liệu sai. Kết quả kiểm tra trả cho người dùng chỉ có vị trí, mã luật, bốn ký tự cuối đã che, không có chuỗi khớp.

### 5.3. Duyệt đăng ký sử dụng và cấp phạm vi (FR-02-047, 048)

Hình dưới là tuần tự duyệt đăng ký sử dụng và cấp phạm vi qua PH-12 và PH-03; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Duyệt đăng ký sử dụng và cấp phạm vi qua PH-12 và PH-03"}
sequenceDiagram
  autonumber
  actor CA as Người duyệt
  actor OR as Đầu mối HTTT khai thác
  participant C as catalog api
  participant W as catalog worker
  participant DB as pg-core
  participant P1 as onboarding PH-01
  participant P12 as PH-12
  participant GW as gateway PH-03
  CA->>C: POST subscriptions/{id}:approve
  C->>C: SubscriptionApprovalPolicy và bốn mắt
  C->>DB: ACTIVE, grant_job NEW
  C-->>CA: 200
  W->>DB: lấy grant_job
  W->>P1: định danh máy của HTTT
  alt Chưa có định danh máy
    W->>DB: grantStatus AWAITING_CREDENTIAL
    W-->>OR: việc xin cấp định danh ở Hệ thống thành viên
    P1-->>W: sự kiện đã cấp định danh
  end
  W->>P12: attach scope api:tra-cuu-ho-tich:chuan
  P12-->>W: đã gắn vào client và chính sách OPA
  W->>DB: thêm consumer, bump sourceVersion
  W->>GW: requestApply PROD
  GW-->>C: onApplied
  C->>DB: GRANTED, outbox EVT-02-10
  C-->>OR: đã cấp quyền, kèm đường dẫn gọi
```

Hình cho thấy hai điểm. Thứ nhất, thiếu định danh máy không phải lỗi mà là một trạng thái chờ có chủ (đầu mối của HTTT nhận việc), saga tự chạy tiếp khi PH-01 báo đã cấp. Thứ hai, PH-12 đứng trước PH-03: nếu hỏng giữa chừng, bên gọi vẫn chỉ nhận `403` chứ không bao giờ được gọi nhầm; phần đã gắn không bị gỡ cho tới khi có quyết định (mục 4.9).

### 5.4. Ngừng khuyến nghị có lộ trình và ngừng hẳn (FR-02-038, 039, 057)

Hình dưới là tuần tự ngừng khuyến nghị có lộ trình, nhắc theo mốc và ngừng hẳn; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Ngừng khuyến nghị có lộ trình, nhắc theo mốc và ngừng hẳn"}
sequenceDiagram
  autonumber
  actor SV as Chủ dịch vụ
  actor CA as Người duyệt
  participant C as catalog api
  participant W as catalog worker
  participant N as NoticeService
  participant P18 as PH-18
  participant GW as gateway PH-03
  participant DB as pg-core
  SV->>C: POST versions/1.0.0:deprecate kế nhiệm 2.0.0, hạn sunsetAt
  C->>C: kế nhiệm PUBLISHED, hạn không ngắn hơn 180 ngày
  C->>DB: review_request DEPRECATE OPEN
  CA->>C: approve
  C->>DB: DEPRECATED, gói DEPRECATED, deprecation_reminder 90 30 7, bump sourceVersion
  C->>N: issue DEPRECATION bắt buộc
  N->>P18: thông báo trong ứng dụng và thư cho từng bên
  W->>GW: requestApply thêm tiêu đề Deprecation và Sunset
  loop Mốc 90, 30, 7 ngày
    W->>N: nhắc các bên còn đăng ký
  end
  W->>DB: tới sunsetAt, đếm đăng ký hiệu lực
  alt Còn đăng ký PENDING, ACTIVE, SUSPENDED
    W->>N: cảnh báo SV, CA, TA, giữ DEPRECATED
  else Không còn
    W->>C: mở review_request RETIRE
    CA->>C: approve
    C->>DB: RETIRED, giữ chỗ context-path 12 tháng, national_sync WITHDRAW
    C->>W: gỡ route qua PublishCoordinator
  end
```

Hình thể hiện BR-02-006: tới hạn mà còn người dùng thì hệ thống chỉ cảnh báo, không bao giờ tự ngừng hẳn. Việc thêm tiêu đề `Deprecation`, `Sunset` thuộc loại "ghi ngay rồi xác nhận sau" vì API vẫn phục vụ; ngừng hẳn cũng thuộc loại này nhưng chỉ xảy ra sau khi một người thứ hai duyệt.

### 5.5. Đồng bộ danh mục lên Nền tảng quốc gia (FR-02-053, 054)

Hình dưới là tuần tự đồng bộ danh mục lên Nền tảng quốc gia qua hàng đợi bền và PH-14; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Đồng bộ danh mục quốc gia qua hàng đợi bền và PH-14"}
sequenceDiagram
  autonumber
  participant C as catalog api
  participant DB as pg-core
  participant D as SyncDispatcher
  participant P14 as PH-14
  participant NQ as Nền tảng quốc gia
  participant K as Kafka
  participant O as OverdueWatcher
  actor TO as Vận hành
  C->>DB: công bố và national_sync_record QUEUED cùng giao dịch
  D->>DB: lấy lô tối đa 50 bản ghi SKIP LOCKED, đặt SENT
  D->>P14: upsert payload, Idempotency-Key là payloadHash
  P14->>NQ: gửi theo giao thức quốc gia
  alt Xác nhận
    NQ-->>P14: nationalRef
    P14-->>D: ACK
    D->>DB: ACKED, nationalRef
  else Từ chối
    NQ-->>P14: mã và lý do
    P14-->>D: REJECTED
    D->>DB: REJECTED, rejectReason
    D-->>TO: thông báo kèm lý do
  else Lỗi tạm thời
    P14-->>D: 503 hoặc quá thời gian
    D->>DB: FAILED, next_attempt lùi dần 1, 5, 15, 60 phút
  end
  D->>K: EVT-02-14 qua hộp gửi
  O->>DB: mỗi giờ đếm phiên bản đủ điều kiện quá 7 ngày chưa ACKED
  O-->>TO: cảnh báo tuân thủ nếu có
```

Hình cho thấy mọi thứ quanh PH-14 đều đứng sau một hàng đợi: PH-14 ngừng chỉ làm bản ghi nằm lại `FAILED` và đếm giờ quá hạn, không bao giờ làm hỏng việc công bố. Idempotency-Key là băm nội dung nên gửi lại sau mất kết nối không tạo mục trùng ở phía quốc gia.

### 5.6. Tự đăng ký API từ luồng PH-04 và sinh khung route (FR-02-013, 026)

Hình dưới là tuần tự tự đăng ký API từ luồng REST của PH-04 và sinh khung route; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Sinh khung route cho PH-04 và tự đăng ký API từ luồng REST"}
sequenceDiagram
  autonumber
  actor SV as Chủ dịch vụ
  actor IE as Kỹ sư tích hợp
  participant C as catalog
  participant P4 as PH-04
  participant K as Kafka
  participant DB as pg-core
  SV->>C: POST versions/1.0.0/route-skeleton workspace, flowCode
  C->>P4: createFromSpec apiRef, origin API_SPEC
  P4->>C: GET spec đã gộp bằng scope catalog:flow-sync
  C-->>P4: đặc tả
  P4-->>C: 202 flowCode, designerUrl, pendingFill
  C->>DB: backend FLOW PLACEHOLDER
  IE->>P4: hoàn thiện logic, duyệt, phát hành luồng
  P4->>K: EVT-04-07 luồng phát hành
  K->>C: sự kiện qua inbox_event
  C->>DB: backend ACTIVE
  C-->>SV: luồng đã phát hành, gửi duyệt được
  Note over P4,C: Chiều ngược lại, luồng REST tự có API
  P4->>K: EVT-04-02 luồng có rest DSL đã duyệt
  K->>C: restOperations
  C->>P4: GET đặc tả OpenAPI sinh từ luồng
  C->>C: lint, tạo API origin FLOW và phiên bản DRAFT
  C-->>SV: việc hoàn thiện mô tả, gói, gửi duyệt
```

Hình cho thấy hai chiều giữa PH-02 và PH-04 đều đi qua dữ liệu bền (`inbox_event`, `pending_command`) nên hai phía không cần cùng chạy một lúc; ở chiều sinh khung, backend `FLOW` chỉ tính là `ACTIVE` khi luồng đã phát hành, nên không thể gửi duyệt một API chưa có chỗ chạy thật.

### 5.7. Đối soát cấu hình công bố với gateway (FR-02-060)

Hình dưới là tuần tự đối soát định kỳ cấu hình gateway với dữ liệu công bố; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Đối soát định kỳ cấu hình gateway với dữ liệu công bố"}
sequenceDiagram
  autonumber
  participant R as DriftReconciler
  participant C as PublishedConfigAssembler
  participant GW as gateway PH-03
  participant DB as pg-core
  participant K as Kafka
  actor TO as Vận hành
  actor SO as Cán bộ ATTT
  R->>R: pg_try_advisory_lock theo tenant và môi trường
  R->>C: cấu hình mong đợi, sourceVersion, contentHash từng route
  R->>GW: describe PROD
  GW-->>R: số phiên bản và băm từng pod, danh sách route kèm băm nguồn
  R->>R: phân loại MISSING_ROUTE, EXTRA_ROUTE, UPSTREAM_MISMATCH, CONSUMER_MISMATCH, VERSION_BEHIND
  alt Có lệch
    R->>DB: gateway_drift
    R->>K: EVT-02-15
    R-->>TO: cảnh báo kèm chi tiết ở UI-02-17
    opt auto-repair bật và không phải EXTRA_ROUTE
      R->>GW: rebuild PROD
    end
    opt Có EXTRA_ROUTE
      R-->>SO: cảnh báo, không tự gỡ
    end
  else Khớp
    R->>DB: inSync true, cập nhật chỉ số
  end
```

Hình cho thấy chỉ `EXTRA_ROUTE` không bao giờ được tự sửa, vì một route mà PH-02 không công bố có thể là dấu hiệu tấn công hoặc sửa tay; quyết định thuộc cán bộ ATTT (SEC-65).

### 5.8. Chốt kỳ tuân thủ SLA (FR-02-056)

Hình dưới là tuần tự chốt kỳ tuân thủ SLA hằng tháng và cảnh báo nhiều kỳ không đạt; phần thuyết minh sau hình nêu điều cần thấy.

```{.mermaid caption="Chốt kỳ tuân thủ SLA hằng tháng và cảnh báo nhiều kỳ không đạt"}
sequenceDiagram
  autonumber
  participant S as SlaEvaluator
  participant DB as pg-core
  participant M as PH-13 Mimir
  participant N as NoticeService
  participant K as Kafka
  S->>DB: phiên bản có cam kết trùng kỳ
  loop Mỗi phiên bản
    S->>M: apiPeriod p99, lượt gọi, lượt lỗi hệ thống, ngày có dữ liệu
    alt PH-13 không khả dụng
      S->>DB: kỳ PENDING, hẹn thử lại sau 1 giờ
    else Có số liệu
      S->>S: trừ khoảng tạm ngừng, bảo trì, ngoài giờ phục vụ
      alt Dưới 7 ngày dữ liệu hoặc dưới 1.000 lượt
        S->>DB: INSUFFICIENT, không tính chuỗi không đạt
      else Đủ dữ liệu
        S->>S: so ba chỉ tiêu với cam kết hiệu lực trong kỳ
        S->>DB: sla_period met hoặc BREACHED, số kỳ liên tiếp
        opt Từ 3 kỳ BREACHED liên tiếp
          S->>N: cảnh báo SV, CA, TA kèm gợi ý hành động
        end
      end
    end
    S->>K: EVT-02-13
  end
```

Hình nhấn mạnh quy tắc không kết luận khi thiếu dữ liệu (BR-02-013, BR-02-031): kỳ `INSUFFICIENT` không làm đứt hay kéo dài chuỗi không đạt, và PH-13 ngừng thì kỳ chờ chốt chứ không bị coi là đạt.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph02_catalog` có `tenant_id NOT NULL` và `FORCE ROW LEVEL SECURITY`; vai trò CSDL của ứng dụng không phải chủ bảng và không có `BYPASSRLS` (SEC-81, D03-07). `TenantContextFilter` của `dh-connect` đọc tenant từ token đã xác thực, đặt vào `TenantContext` và chạy `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch (D03-10 §3); bộ kiểm tra khi lấy kết nối từ pool từ chối kết nối có biến rỗng, và DU không khởi động nếu phát hiện vai trò có `BYPASSRLS`. API nội bộ lấy tenant từ token dịch vụ, không từ tham số hay thân yêu cầu; tiêu đề `X-DH-Tenant` chỉ được tin khi đến từ APISIX qua mesh với đúng SPIFFE ID (SEC-80).

| Tầng | Cách cách ly trong PH-02 | Kiểm chứng |
|---|---|---|
| PostgreSQL | RLS theo `tenant_id`; khóa duy nhất luôn có `tenant_id` đứng đầu (mã API, mã gói, `legacy_id`), nên một tenant không suy ra được mã của tenant khác từ lỗi trùng | CI-3: kiểm tra RLS sau migration, kiểm thử rò rỉ chéo tenant |
| Kafka | Topic `{tenant}.catalog.*`; tiêu đề `dhtenant`; consumer so tên topic với tiêu đề, lệch thì chuyển DLQ và cảnh báo an ninh | Kiểm thử ACL âm tính (SEC-82) |
| Garage | Bucket `dh-{tenant}-catalog`, khóa truy cập theo tenant; mọi khóa đối tượng dựng bằng `ObjectKeys.of(tenant, …)`, không ghép chuỗi tay | Kiểm thử đọc chéo bucket |
| Valkey | Khóa dựng bằng hàm tạo tên có tenant | Luật Semgrep |
| Mimir | Mọi truy vấn gắn `X-Scope-OrgID = tenant` (SEC-84) | Kiểm thử truy vấn chéo |
| OpenSearch (tùy chọn) | Alias `catalog-{tenant}`, người dùng dịch vụ chỉ có quyền trên alias của tenant | Kiểm thử |
| Tác vụ nền | Mỗi lượt chạy bọc trong `TenantContext.runAs(tenant, …)`; không có tác vụ "không tenant" | ArchUnit chặn `@Scheduled` không qua `TenantScopedJob` |

: Cách ly tenant theo tầng của PH-02

Bảng `lint_rule` (định nghĩa luật và mô tả) và danh sách mẫu giữ chỗ mặc định thuộc tenant `COMMON`, tenant tỉnh chỉ đọc; chính sách RLS của hai bảng này cho đọc `tenant_id IN (current, 'COMMON')` và chỉ cho ghi `current`. `lint_rule_override` luôn của tenant. Đối tượng của tenant khác, hoặc đối tượng không đủ quyền xem, trả `404` cùng thân với "không tồn tại" (BR-02-033, ERR-02-001): để không lộ sự tồn tại qua thời gian đáp, các dịch vụ không có đường kiểm tra "tồn tại" riêng trước đường kiểm tra quyền, chỉ một truy vấn đã lọc theo RLS và `VisibilityFilter`.

Hạn mức theo tenant (NFR-02-010: 2.000 API, 50 phiên bản mỗi API, 20.000 đăng ký, 5.000 thao tác mỗi đặc tả; trần `02.*` của nền tảng) được `QuotaGuard` kiểm lúc tạo, vượt thì ERR-02-040. Tenant `SUSPENDED` (D03-10 §5.1) làm mọi API ghi của PH-02 trả `ERR-20-001` và giao diện chỉ đọc; tác vụ nền bỏ qua tenant đó trừ việc đưa trạng thái bị hạn chế (tạm ngừng, thu hồi) xuống gateway. Tenant `MERGING`: chuyển dữ liệu sang tenant đích thuộc quy trình của PH-20; PH-02 cung cấp lệnh xuất và nhập theo gói của chính nó (xử lý trùng mã API giữa hai tenant ở Q02-28). Truy cập liên tenant của vai trò nền tảng đi qua nhóm `/api/platform/` với lý do, mã phiếu, quyền có thời hạn và ghi vào chuỗi kiểm toán của tenant bị truy cập (SEC-85); PH-02 không có API riêng cho việc này.

## 7. Bảo mật

Bảng dưới nêu từng vấn đề bảo mật của PH-02, biện pháp hiện thực trong mã và mã `SEC-*` tương ứng ở D03-07.

| Vấn đề | Biện pháp | SEC |
|---|---|---|
| Tự duyệt, tự công bố, lách duyệt bốn mắt | `ReviewPolicy` so theo định danh người dùng ở máy chủ, thêm `CHECK` ở CSDL; SV và CA loại trừ nhau; API `SENSITIVE` cần hai người; không có đường `UPDATE status` ngoài máy trạng thái | SEC-07, ADR-046 |
| Truy cập chéo tenant | Tenant từ token, RLS bắt buộc, `404` cùng thân, kiểm thử rò rỉ cho mọi API | SEC-80, SEC-81, SEC-87 |
| Quyền sai hoặc thiếu | `@PreAuthorize` theo `PERM-02-*` qua thư viện PEP gọi OPA cục bộ, `default allow := false`, quyết định có `input.tenant == resource.tenant` | SEC-26 |
| SSRF qua URL đặc tả, tham chiếu ngoài, backend | `SafeFetcher` (chỉ `https`, chặn dải riêng và siêu dữ liệu cloud, ghim IP, kiểm lại mỗi lần chuyển hướng, FQDN egress); backend chỉ là kết nối PH-05 hoặc luồng PH-04 | SEC-16, SEC-14 |
| Đặc tả độc hại (bom alias, lồng sâu, ReDoS, tệp độc hại) | Giới hạn kích thước, alias, độ sâu; RE2/J; Tika kiểm kiểu; ClamAV; tên đối tượng do hệ thống sinh, không thực thi; lỗi quét thì chặn | SEC-43, SEC-45 |
| Lọt bí mật hoặc dữ liệu cá nhân thật qua đặc tả công khai | `SecretScanner` chặn gửi duyệt, duyệt, công bố; chuỗi khớp không rời bộ quét; canary kiểm thử; che log, vết | SEC-32, NFR-02-012 |
| Cấp xác thực yếu cho dữ liệu nhạy cảm | `AuthPolicyMatrix` ở tạo gói, ở đăng ký sử dụng và ở tác vụ đêm; mức Hạn chế trở lên không có `client_secret` | SEC-24 |
| Cấp quyền ngoài quy trình | Phạm vi `api:*` chỉ sinh từ đăng ký đã duyệt; PH-02 không có API cấp tay; rà soát đăng ký định kỳ | SEC-24, SEC-26, SEC-27 |
| Route ngoài hợp đồng, cấu hình gateway bị sửa tay | Chỉ route khai trong đặc tả đã duyệt; đối soát 5 phút, `EXTRA_ROUTE` cảnh báo SO | SEC-43, SEC-65 |
| Gọi giả danh vào giao diện nội bộ | Danh tính SPIFFE, scope theo người gọi, mTLS strict | SEC-15 |
| Dữ liệu kiểm toán bị sửa hoặc thiếu | `dh-audit` ghi trong cùng giao dịch (outbox), chuỗi băm và WORM do PH-13 | SEC-60, SEC-62 |
| Lộ thông tin qua thông báo lỗi | RFC 9457, không stack trace, không tên phiên bản; thân lỗi phía kia chỉ vào log đã che | SEC-43 |
| Tiêm công thức khi xuất Excel, CSV danh sách | Ô bắt đầu bằng `=`, `+`, `-`, `@`, tab, CR được thêm dấu nháy đơn | SEC-45 |
| Mã HTML, script nhúng trong mô tả API rồi hiển thị ở cổng nhà phát triển | Mô tả lưu nguyên văn, khi xuất cho PH-15 và giao diện qua `MarkdownSanitizer` (tập thẻ cho phép), PH-15 và `dh-console` thêm chính sách CSP | SEC-44 |
| Lạm dụng gói `KEYLESS` công khai | Giới hạn theo IP và WAF mặc định ở PH-03 | SEC-10, SEC-11 |
| Sự cố nghi bị chiếm quyền | SO tạm ngừng khẩn API, đăng ký ngay (không cần duyệt), có lý do, kiểm toán | SEC-72 |

: Bảo mật

Quyền kiểm ở máy chủ, ở ba lớp: `@PreAuthorize` ở `web` (có quyền `PERM` hay không), kiểm đối tượng ở dịch vụ (đúng tổ chức, đúng mức hiển thị) và kiểm trạng thái, bốn mắt ở máy trạng thái. Giao diện ẩn nút chỉ là tiện ích.

| Quyền | Thao tác | Điều kiện đối tượng kiểm ở dịch vụ |
|---|---|---|
| `PERM-02-read` | Tra cứu, tải đặc tả, xem SLA, thống kê | `VisibilityFilter` theo mức hiển thị và trạng thái |
| `PERM-02-create` | Đăng ký, sửa API, backend, gói, SLA; tạo phiên bản; xóa mềm | SV ○: `caller.orgCode = api.ownerOrgCode` (BR-02-032) |
| `PERM-02-submit` | Gửi duyệt, đề nghị ngừng khuyến nghị, ngừng hẳn | Như trên, cộng `SubmissionGate` |
| `PERM-02-publish` | Duyệt, từ chối, công bố API, gói; duyệt ngừng dùng, nâng mức hiển thị | `ReviewPolicy` (khác người gửi, người sửa; `SENSITIVE` cần CA và TA khác nhau) |
| `PERM-02-subscribe` | Gửi, hủy đăng ký | OR ○: HTTT khai thác thuộc tổ chức của người gửi (ERR-02-026) |
| `PERM-02-approve-subscription` | Duyệt, từ chối, thu hồi đăng ký | SV ○ chỉ dưới mức Hạn chế (BR-02-026) |
| `PERM-02-operate` | Tạm ngừng, tiếp tục, chạy, thử lại đồng bộ quốc gia, đối soát | Tạm ngừng do SO vì an ninh chỉ SO hoặc TA tiếp tục (BR-02-034) |
| Quyền quản trị phân hệ (đề nghị `admin`) | Tham số, bộ luật, phân loại, chuyển chủ quản, di trú | PA, TA |

: Quyền và nơi kiểm ở máy chủ

Cho tới khi D02-08 bổ sung động từ `admin` cho PH-02 (mục "Đề nghị đồng bộ"), mã dùng hằng `PERM_02_ADMIN` ánh xạ tạm sang vai trò `ROLE-TENANT_ADMIN` và `ROLE-PLATFORM_ADMIN`; khi D02-08 chốt, chỉ đổi hằng này, không đổi nơi kiểm.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Cột "Kiểm ở máy chủ" liệt kê điều kiện bảo vệ do máy trạng thái thi hành; mọi dòng đều cần `reason` (BR-02-028) trừ tạo mới.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| ApiVersion | (mới) | register, create version | DRAFT | Mã chưa dùng, HTTT `ACTIVE`, không bí mật nhà nước |
| ApiVersion | DRAFT | submit | PENDING | `SubmissionGate` đạt; ERR-02-012 liệt kê điều kiện thiếu |
| ApiVersion | PENDING | withdraw, reject | DRAFT | Người gửi rút, hoặc CA từ chối kèm ý kiến |
| ApiVersion | PENDING | approve (quyết định cuối) | PENDING, `activating` | Bốn mắt; chạy lại gate; băm đặc tả khớp; chưa sang `PUBLISHED` |
| ApiVersion | PENDING | (hệ thống, có xác nhận cổng) | PUBLISHED | `ack.sourceVersion ≥ mục tiêu` và route có mặt |
| ApiVersion | PUBLISHED | suspend | SUSPENDED | `PERM-02-operate`, lý do, loại sự cố |
| ApiVersion | SUSPENDED | resume | PUBLISHED | Người đã tạm ngừng hoặc TA; SO an ninh chỉ SO, TA; chờ xác nhận cổng |
| ApiVersion | PUBLISHED, SUSPENDED | deprecate | DEPRECATED | Có kế nhiệm `PUBLISHED` hoặc xác nhận ngừng hẳn; hạn ≥ `02.deprecation.min-days`; duyệt bốn mắt |
| ApiVersion | DEPRECATED | retire | RETIRED | Không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` (BR-02-006); duyệt bốn mắt |
| ApiVersion | DRAFT | discard | RETIRED | Người có `PERM-02-create` của tổ chức |
| ApiVersion | PUBLISHED | supersede (hệ thống) | RETIRED | Phiên bản cùng số chính mới đã `PUBLISHED`, đăng ký đã chuyển sang gói cùng mã (BR-02-035); lý do `SUPERSEDED` |
| Plan | STAGING | publish | PUBLISHED | Phiên bản `PUBLISHED` hoặc cùng đợt; CA duyệt; chờ xác nhận cổng |
| Plan | PUBLISHED | deprecate | DEPRECATED | CA duyệt; chặn đăng ký mới |
| Plan | DEPRECATED | close | CLOSED | Không còn đăng ký đang hiệu lực (BR-02-019) |
| Plan | STAGING | cancel | CLOSED | Chưa công bố |
| Subscription | (mới) | submit | PENDING hoặc ACTIVE | Tự duyệt theo BR-02-026, hoặc chờ duyệt |
| Subscription | PENDING | approve, reject, cancel | ACTIVE, REJECTED, CANCELLED | Chính sách duyệt; lý do khi từ chối |
| Subscription | ACTIVE | suspend, resume | SUSPENDED, ACTIVE | `PERM-02-operate` hoặc sự kiện PH-01 |
| Subscription | ACTIVE, SUSPENDED | revoke | REVOKED | `PERM-02-approve-subscription` hoặc sự kiện PH-01 |
| Subscription | ACTIVE | cancel, expire | CANCELLED, EXPIRED | HTTT hủy; quá hạn rà soát chưa gia hạn |
| GrantJob | NEW | (worker) | AWAITING_CREDENTIAL, GRANTED, FAILED | Theo bảng ở mục 4.9 |
| PublishJob | QUEUED | (worker) | REQUESTED, CONFIRMED, FAILED_RETRY, FAILED | Theo mục 4.10 |
| ReviewRequest | OPEN | approve, reject, withdraw | APPROVED, REJECTED, WITHDRAWN | Mỗi người một quyết định; một yêu cầu `OPEN` mỗi đối tượng |
| NationalSyncRecord | QUEUED | (worker) | SENT | Không có bản ghi cũ hơn của cùng phiên bản chưa xong |
| NationalSyncRecord | SENT | (phản hồi) | ACKED, REJECTED, FAILED | Theo phản hồi PH-14 |
| NationalSyncRecord | FAILED | (đến hạn) | SENT | Lịch lùi dần |

: Bảng chuyển trạng thái

Hai điểm cần ghi nhận so với FRS §4.3: sơ đồ trạng thái phiên bản ở FRS ban đầu chưa có cạnh `PUBLISHED → RETIRED` do thay thế cùng số chính (đã bổ sung vào FRS §4.3 ở lượt rà soát, kèm ghi chú trạng thái trung gian `activating`); và `approve` không đưa thẳng sang `PUBLISHED` (mục 4.10). Mỗi gốc tập hợp có cột `version` làm khóa lạc quan: lệnh từ API mang `If-Match` (không khớp: ERR-02-015, `412`); lệnh của hệ thống (hết hạn, nhắc, đối soát) thử lại tối đa 3 lần khi xung đột.

### 8.2. Hộp gửi và sự kiện

Sự kiện EVT-02-01…16 được ghi vào bảng `outbox_event` trong cùng giao dịch với thay đổi gốc (ADR-042); `OutboxPublisher` (bộ đọc Debezium outbox router của `pg-core`, hoặc bộ quét 500 ms nếu hồ sơ chưa có Debezium) đẩy lên Kafka kèm tiêu đề CloudEvents (`dhtenant`, `id`, `type`, `time`). Lược đồ ở Apicurio, chế độ BACKWARD (NFR-02-018); sự kiện không chứa dữ liệu cá nhân hay nội dung đặc tả, chỉ mã định danh và trường thay đổi. Bên tiêu thụ trong PH-02 (sự kiện của PH-01, PH-04, PH-10) ghi `inbox_event(event_id)` trước khi xử lý để sự kiện phát lại không tạo hiệu ứng thứ hai.

| Sự kiện | Phát từ | Khóa phân vùng |
|---|---|---|
| EVT-02-01, 02, 03 | `ApiRegistrationService`, `TaxonomyService`, `TransferService`, `VisibilityService`, xóa mềm | `apiCode` |
| EVT-02-04, 05, 06, 16 | `ReviewService`, `PublishCoordinator`, `SuspensionService`, `DeprecationService`, `ReviewOverdueWatcher` | `apiCode` |
| EVT-02-07 | `SpecRefreshJob` | `apiCode` |
| EVT-02-08 | `PlanService`, `PublishCoordinator` | `apiCode` |
| EVT-02-09, 10, 11 | `SubscriptionService`, `GrantOrchestrator` | `apiCode` (cùng API giữ thứ tự) |
| EVT-02-12 | `NoticeService` | `apiCode` |
| EVT-02-13 | `SlaPeriodCloser` | `apiCode` |
| EVT-02-14 | `SyncDispatcher` | `apiCode` |
| EVT-02-15 | `DriftReconciler` | `environment` |

: Sự kiện, nơi phát và khóa phân vùng

Khóa phân vùng theo `apiCode` làm sự kiện của một API đến theo thứ tự, nên PH-03 và PH-15 áp dụng được đúng thứ tự "công bố trước, ngừng dùng sau". Bên tiêu thụ lũy đẳng theo `(apiCode, versionNo, sourceVersion)`. Khi Kafka ngừng, sự kiện tồn trong `outbox_event` và được phát bù sau khi phục hồi; cảnh báo khi dòng cũ nhất chưa phát quá 5 phút. Các tiêu thụ quan trọng (PH-03) không phụ thuộc Kafka mà còn gọi định kỳ 5 phút (mục 4.10), nên mất sự kiện không làm lệch cổng.

### 8.3. Thử lại, thời gian chờ và tác vụ nền

Thời gian chờ, thử lại, ngắt mạch của cuộc gọi ra ngoài ở bảng mục 4.15. Việc bền (lưu ở CSDL) có chính sách thử lại riêng:

| Việc | Lùi dần | Tối đa | Khi hết lần |
|---|---|---|---|
| `publish_job` | 30 giây, 1, 2, 4, 8 phút | 5 lần, khoảng 15 phút | `FAILED`, cảnh báo TO, phiên bản giữ `PENDING`; "Thử lại công bố" đặt lại |
| `grant_job` (mỗi bước) | 5 lần trong 15 phút | 5 | `FAILED`, cảnh báo TO, giữ phần đã gắn, `cleanup_mark` |
| Gỡ phạm vi sau thu hồi | 1, 5, 15 phút rồi mỗi giờ | Đến khi xong | Cảnh báo khi tồn quá 15 phút |
| `national_sync_record` | 1, 5, 15, 60 phút rồi mỗi 6 giờ | Không giới hạn | Cảnh báo tuân thủ sau `02.sync.overdue-days` |
| `pending_command` (PH-04) | 1, 5, 15 phút, 1 giờ | Trong 24 giờ | Báo SV, huỷ lệnh |
| Kỳ SLA `PENDING` | Mỗi giờ | 24 giờ | Danh mục giữ kỳ gần nhất kèm thời điểm |
| Gửi thông báo | 1, 5, 15 phút | 3 | `FAILED` hiển thị ở UI-02-13 |

: Thử lại của các việc bền

Các tác vụ định kỳ chạy bằng `TenantScopedJob`: mỗi (tác vụ, tenant) có một dòng `job_lease(job_name, tenant_id, leased_until, owner)` lấy bằng `FOR UPDATE SKIP LOCKED`, nên nhiều bản sao `worker` không chạy trùng và bản sao chết thì hết hạn thuê tự được bản khác nhận (mọi bước lũy đẳng nên chạy lại an toàn).

| Tác vụ | Chu kỳ (giờ Việt Nam) | Ghi chú |
|---|---|---|
| `OutboxPublisher` | 500 ms | Khi không có Debezium |
| `PublishJobWorker`, `GrantJobWorker`, `SyncDispatcher` | 1 giây, lấy việc đến hạn | Lô ≤ `02.sync.batch-size` với đồng bộ |
| `DriftReconciler` | 5 phút | Đợt 2 (FR-02-060) |
| `SpecRefreshJob` | Mỗi giờ | Theo `02.spec.url-refresh-hours` |
| `ReviewOverdueWatcher`, `OverdueWatcher` | Mỗi giờ | Nhắc sau `02.review.reminder-days`, quá hạn sau `02.review.overdue-days` ngày làm việc |
| `SuspensionWatcher`, `RetireWatcher` | Hằng ngày 01:00, 01:30 | Không tự đổi trạng thái khi còn người dùng |
| `SyncScheduler` | Theo `02.sync.cron` | Mặc định 02:00 |
| `RenewalScheduler` | Hằng ngày 02:30 | Đợt 2 (FR-02-052) |
| Nhắc ngừng khuyến nghị | Hằng ngày 08:00 | Mốc 90, 30, 7 ngày |
| `SlaEvaluator` | Mùng 1 hằng tháng 02:00, thử lại mỗi giờ | |
| `OrphanSweeper` | Chủ nhật 03:00 | Đối tượng Garage `specs/` mồ côi quá 24 giờ |
| Dọn `config_change_log`, `diff_result`, `lint_finding`, `inbox_event` | Hằng ngày 03:30 | Giữ 30 ngày, 30 ngày, 1 năm (NFR-02-017), 14 ngày |

: Tác vụ nền

### 8.4. Saga công bố, cấp quyền và ma trận sự cố

Hai saga lớn (công bố, cấp phạm vi) không nằm trong một giao dịch phân tán; tính nhất quán được giữ bằng trạng thái bền, bước lũy đẳng và nguyên tắc "kích hoạt chờ xác nhận, hạn chế ghi ngay" (mục 4.10). Bảng dưới cho từng điểm hỏng: hệ thống ở trạng thái nào và hồi phục ra sao.

| Điểm hỏng | Trạng thái để lại | Hồi phục |
|---|---|---|
| Cổng không xác nhận trong 30 giây | Phiên bản `PENDING`, `publish_job FAILED_RETRY` | Thử lại 5 lần; hết lần thì cảnh báo TO, "Thử lại công bố" |
| Tiến trình `worker` chết giữa `requestApply` và xác nhận | `publish_job REQUESTED`, thuê hết hạn | Bản sao khác nhận, `requestApply` lũy đẳng theo `(env, sourceVersion)` nên không đẩy hai lần |
| Hai người duyệt cùng lúc | Một quyết định thắng nhờ `version` của `review_request` | Người sau nhận ERR-02-011 hoặc ERR-02-015 |
| Xung đột context-path xuất hiện sau duyệt | Phiên bản giữ `PENDING` | ERR-02-019, báo TA; TA đổi đường dẫn rồi thử lại |
| PH-12 hỏng khi cấp quyền | `grant_job` thử lại, sau 5 lần `FAILED` | Phần đã gắn giữ nguyên, đánh `cleanup_mark`; TO "Cấp lại" hoặc "Hủy cấp" |
| PH-01 chưa có định danh máy | `AWAITING_CREDENTIAL` (không phải lỗi) | Tiếp tục khi nhận sự kiện PH-01 |
| Thu hồi: gateway đã gỡ, PH-12 chưa gỡ phạm vi | Đăng ký `REVOKED`, `catalog_grant_detach_pending` | Gỡ lặp tới khi xong; lượt gọi đã bị chặn ở gateway |
| `dh-connect` ngừng hoàn toàn | Cấu hình ở gateway không đổi | API đang chạy tiếp tục phục vụ ≥ 24 giờ (NFR-02-008); khi bật lại `DriftReconciler` đối soát |
| Giao dịch CSDL lỗi sau khi ghi Garage | Đối tượng mồ côi | `OrphanSweeper` dọn |
| Kafka ngừng | Sự kiện nằm ở `outbox_event` | Phát bù, cảnh báo khi cũ hơn 5 phút |
| PH-14 ngừng | `national_sync_record FAILED` | Lùi dần; cảnh báo tuân thủ sau 7 ngày |
| Sự kiện PH-04, PH-01 đến hai lần | `inbox_event` đã có `event_id` | Bỏ qua lần thứ hai |

: Ma trận điểm hỏng và hồi phục

### 8.5. Lũy đẳng và đồng thời

Lệnh POST thay đổi trạng thái (gửi duyệt, duyệt, công bố, tạm ngừng, gửi đăng ký, cấp lại, đồng bộ ngay, nhập hệ cũ) nhận `Idempotency-Key`; `IdempotencyStore` ghi `(tenant_id, principal, key)` duy nhất kèm băm yêu cầu và phản hồi trong 24 giờ ở cùng giao dịch với tác dụng. Cùng khóa, cùng thân thì trả lại phản hồi cũ; cùng khóa khác thân thì ERR-02-042 (`422`). Tần suất lệnh thấp nên chỉ dùng PostgreSQL, không cần tầng Valkey như PH-19 (ADR-041).

| Cơ chế | Dùng ở | Mục đích |
|---|---|---|
| `SELECT … FOR UPDATE` dòng phiên bản | Mọi chuyển trạng thái phiên bản; ngừng hẳn | Tuần tự hóa lệnh trên cùng phiên bản |
| `SELECT … FOR SHARE` dòng phiên bản | Gửi đăng ký sử dụng | Không lọt đăng ký khi phiên bản đang ngừng hẳn |
| `pg_advisory_xact_lock(hashtext(tenant ‖ ':ctx'))` | Giữ chỗ context-path | Hai người đăng ký cùng lúc không cùng thắng |
| `pg_try_advisory_lock` theo (tenant, môi trường) | `DriftReconciler`, đồng bộ cùng API, so sánh cùng cặp | Chống chạy chồng, trả ERR-02-035 |
| `FOR UPDATE SKIP LOCKED` | Mọi việc bền | Nhiều `worker` không trùng việc |
| `version` + `If-Match` | Mọi PUT, PATCH, lệnh | ERR-02-015 khi đối tượng đã đổi |
| Bump `config_epoch` ở câu lệnh cuối giao dịch | Mọi thay đổi ảnh hưởng gateway | Tuần tự hóa ngắn, không giữ khóa lâu |

: Cơ chế lũy đẳng và đồng thời

### 8.6. Ánh xạ lỗi

Lỗi miền là các ngoại lệ có kiểu; `CatalogProblemAdvice` (`@RestControllerAdvice`) chuyển thành `ProblemDetail` theo RFC 9457 với `code = ERR-02-nnn`, `traceId`, và `errors[]` theo trường khi cần; không bao giờ có stack trace. Định nghĩa đầy đủ ở D03-04-PH02 §6.

| Ngoại lệ | ERR-02 | HTTP |
|---|---|---|
| `NotFoundException` (gồm tenant khác, không đủ quyền xem) | 001 | 404 |
| `DuplicateCodeException` | 002 | 409 |
| `ValidationException` | 003 | 400 |
| `SpecSyntaxException`, `SpecStandardException`, `SpecConventionException`, `SecretFoundException` | 005, 006, 007, 008 | 422 |
| `SpecTooLargeException` | 009 | 413 |
| `IllegalTransitionException` | 011 | 409 |
| `PreconditionUnmetException` (kèm danh sách điều kiện) | 012 | 409 |
| `FourEyesViolationException`, `AccessDeniedException` | 013, 014 | 403 |
| `StaleObjectException` | 015 | 412 |
| `GatewayNotAppliedException`, `DependencyUnavailableException` | 033, 034 | 503 |
| `RateLimitedException` | 036 | 429 |
| `ChangeFreezeException` | 039 | 423 |
| `IdempotencyConflictException` | 042 | 422 |

: Ánh xạ ngoại lệ miền sang mã lỗi

## 9. Cấu hình, cờ tính năng và khả năng mở rộng

### 9.1. Cấu hình

Tham số nghiệp vụ `02.*` (28 khóa) do tenant chỉnh trong miền cho phép, lưu ở PH-18, đệm 60 giây, định nghĩa đầy đủ ở FRS §8.2 và không lặp lại ở đây. Phần dưới là cấu hình kỹ thuật theo hồ sơ triển khai (`dh.catalog.*`, đặt trong kho cấu hình theo tenant, ADR-068, không dành cho người dùng cuối).

| Khóa | Mặc định | Ý nghĩa |
|---|---|---|
| `dh.catalog.lint.permits` | 2 | Số lần kiểm tra đặc tả đồng thời mỗi pod (theo heap) |
| `dh.catalog.lint.queue-size` | 20 | Hàng đợi tối đa, quá thì ERR-02-036 |
| `dh.catalog.lint.deadline` | 20 s | Hạn mỗi lần kiểm tra |
| `dh.catalog.lint.rule-timeout` | 2 s | Hạn mỗi luật |
| `dh.catalog.publish.ack-timeout` | 30 s | Thời gian chờ APISIX xác nhận |
| `dh.catalog.publish.max-attempts` | 5 | Số lần thử lại công bố |
| `dh.catalog.grant.max-scopes` | 50 | Số phạm vi tối đa mỗi đăng ký (Q02-24) |
| `dh.catalog.outbox.poll-interval` | 500 ms | Chu kỳ quét hộp gửi khi không có Debezium |
| `dh.catalog.config.change-log-retention` | 30 ngày | Thời gian giữ `config_change_log` |
| `dh.catalog.reconcile.interval` | 5 phút | Chu kỳ đối soát |
| `dh.catalog.worker.tenant-parallelism` | 4 | Số tenant xử lý song song mỗi `worker` |
| `dh.catalog.diff.sync-max-bytes` | 1 MiB | Trên mức này so sánh chạy nền |
| `dh.catalog.search.cache-ttl` | 60 s | Bộ đệm danh sách dịch vụ sự kiện |

: Cấu hình kỹ thuật dh.catalog

### 9.2. Cờ tính năng

Cờ dùng OpenFeature, cùng nhà cung cấp với PH-04, đánh giá theo tenant:

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `catalog.event-service.enabled` | `false` | Hiển thị dịch vụ sự kiện trong danh mục (FR-02-009, Đợt 2) |
| `catalog.renewal.enabled` | `false` | Gia hạn, rà soát định kỳ đăng ký (FR-02-052, Đợt 2) |
| `catalog.usage-stats.enabled` | `false` | Thống kê sử dụng (FR-02-058, Đợt 2) |
| `catalog.reconcile.enabled` | `false` | Đối soát cấu hình gateway (FR-02-060, Đợt 2) |
| `catalog.legacy-import.enabled` | `true` | Nhập từ APIM cũ trong giai đoạn strangler |
| `catalog.lint.remote` | `false` | Chạy kiểm tra đặc tả ở `lint-worker` (QM-LON, QM-CHUNG) |
| `catalog.national-sync.dispatch` | `true` | Công tắc ngắt khẩn: `false` thì vẫn xếp hàng nhưng không gửi |

: Cờ tính năng theo tenant

Cờ chỉ bật hay tắt **chức năng**; không cờ nào được phép hạ một biện pháp bảo mật (quét bí mật, bốn mắt, ma trận xác thực luôn bật), và kiểm thử cấu hình ở CI chặn việc thêm cờ như vậy.

### 9.3. Khả năng mở rộng

Mở rộng theo chiều ngang: `api` không giữ trạng thái người dùng nên thêm bản sao tùy ý; `worker` chia việc bằng `SKIP LOCKED` và thuê tác vụ nên thêm bản sao là thêm thông lượng; `lint-worker` mở rộng độc lập với `api`. Điểm hẹp duy nhất theo thiết kế là bộ đếm `config_epoch` của mỗi (tenant, môi trường), chỉ giữ ở cuối giao dịch (mục 4.10).

| Điểm mở rộng | Cách thêm | Chạm tới |
|---|---|---|
| Luật kiểm tra mới | Cài đặt `LintRule`, đăng ký bean, thêm dòng `lint_rule` ở migration kèm mô tả, hướng dẫn, ca kiểm thử | Không chạm lõi `SpecLinter` |
| Mẫu quét bí mật mới | Thêm mẫu RE2/J vào `SecretScanner` kèm ca dương, âm và duyệt ATTT (Q02-11) | Chỉ bộ quét |
| Kiểu xác thực mới | Thêm giá trị `AuthType`, dòng ở `AuthPolicyMatrix`, ánh xạ ở PH-12 và PH-03 | Gói, đăng ký, cấp phạm vi; cần đồng bộ ba phân hệ |
| Công cụ tìm kiếm khác | Cài đặt `SearchEngine` | Chỉ `search` |
| Kênh đồng bộ danh mục khác (ngoài quốc gia) | Cài đặt `NationalCatalogPort` mới cùng `PayloadBuilder` khác | `nationalsync` |
| Kênh thông báo mới (webhook cho bên khai thác) | Cài đặt kênh trong `NoticeService`, ký HMAC theo SEC-47 | `notice` (chưa trong phạm vi MVP) |
| Môi trường mới (ngoài TEST, STAGING, PROD) | Thêm giá trị `Environment` và dòng `config_epoch` | `gatewaysync` |
| Định dạng đặc tả mới (AsyncAPI cho dịch vụ sự kiện) | Thêm bộ đọc ở `intake`, `LintRule` riêng; phiên bản có `spec_kind` | Cần quyết định ở PH-10 |

: Điểm mở rộng của PH-02

Bảng dưới gợi ý cách điều chỉnh theo hồ sơ quy mô (GĐ-07). Số bản sao là **giả định** dựa trên bảng định cỡ `dh-connect` của D03-09 §5.3 và tải thấp của phân hệ (vài chục thay đổi mỗi ngày); đo lại ở hồ sơ tải D05-01.

| Hạng mục | `QM-NHO` | `QM-VUA` | `QM-LON` | `QM-CHUNG` |
|---|---|---|---|---|
| Bản sao `dh-connect` (D03-09) | 2 | 2 | 3 | 4 |
| Vai trò `worker` | Cùng pod `api` | Cùng pod `api` | 1 Deployment riêng | 2 Deployment riêng |
| Kiểm tra đặc tả | Trong tiến trình | Trong tiến trình | `lint-worker` | `lint-worker` |
| Tìm kiếm | PostgreSQL | PostgreSQL | PostgreSQL hoặc OpenSearch | OpenSearch (Q02-21) |
| Phân vùng bảng lớn theo tháng | Không | Không | `config_change_log`, `version_state_history` | Thêm `usage_daily`, `lint_finding` |
| Số tenant xử lý song song mỗi `worker` | 4 | 4 | 8 | 16 |

: Điều chỉnh theo hồ sơ quy mô

## 10. Quan sát

Chỉ số dùng tiền tố `catalog_` đúng như NFR-02-019 đã chốt; OpenTelemetry Collector gắn nhãn `tenant` cho mọi chỉ số (SEC-84), nên bảng dưới không lặp nhãn này. Nhãn `apiCode` chỉ có ở hai chỉ số theo từng API (`catalog_sla_compliance_ratio`, `catalog_backend_health`) để số chuỗi thời gian không vượt khoảng 2.000 mỗi tenant (trần NFR-02-010).

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `catalog_apis_total` | gauge | `status` | `CatalogQueryService` |
| `catalog_spec_validation_total` | counter | `result` (`ok`, `warning`, `error`, `secret`, `timeout`), `mode` (`preview`, `persist`) | `SpecLinter` |
| `catalog_lint_duration_seconds` | histogram | `layer` | `LintExecutor` |
| `catalog_lint_queue_depth` | gauge | không | `LintExecutor` |
| `catalog_secret_findings_total` | counter | `rule` (SCAN-02-nn) | `SecretScanner` |
| `catalog_spec_ingest_total` | counter | `source`, `result` | `SpecIngestService` |
| `catalog_spec_url_fetch_blocked_total` | counter | `reason` (`scheme`, `private_ip`, `egress`, `redirect`, `size`) | `SafeFetcher` |
| `catalog_publish_duration_seconds` | histogram | `env` (từ quyết định duyệt cuối tới `PUBLISHED`) | `PublishCoordinator` |
| `catalog_publish_jobs` | gauge | `status` | `PublishJobWorker` |
| `catalog_review_pending_age_seconds` | gauge | `kind` (tuổi lớn nhất của yêu cầu đang mở) | `ReviewOverdueWatcher` |
| `catalog_version_transitions_total` | counter | `from`, `to` | `VersionStateMachine` |
| `catalog_deprecated_in_use_total` | gauge | không (số phiên bản `DEPRECATED` còn đăng ký hiệu lực) | `RetireWatcher` |
| `catalog_grant_duration_seconds` | histogram | không (từ duyệt tới `GRANTED`) | `GrantOrchestrator` |
| `catalog_grant_failed_total` | counter | `step` | `GrantOrchestrator` |
| `catalog_grant_awaiting_credential`, `catalog_grant_detach_pending` | gauge | không | `GrantOrchestrator` |
| `catalog_gateway_drift_total` | counter | `kind` | `DriftReconciler` |
| `catalog_gateway_config_lag_seconds` | gauge | `env` | `DriftReconciler` |
| `catalog_national_sync_status` | gauge | `status` | `SyncDispatcher` |
| `catalog_national_sync_overdue_total` | gauge (tên theo NFR-02-019, là số hiện có) | không | `OverdueWatcher` |
| `catalog_sla_compliance_ratio` | gauge | `apiCode` (tỷ lệ kỳ đạt 12 tháng) | `SlaEvaluator` |
| `catalog_sla_period_pending` | gauge | không | `SlaPeriodCloser` |
| `catalog_backend_health` | gauge | `apiCode`, `state` | `HealthReader` |
| `catalog_notice_delivery_seconds` | histogram | `channel` | `NoticeService` |
| `catalog_adapter_calls_total`, `catalog_adapter_duration_seconds`, `catalog_adapter_circuit_state` | counter, histogram, gauge | `target`, `result` | `adapter` |
| `catalog_outbox_oldest_age_seconds` | gauge | không | `OutboxPublisher` |
| `catalog_query_duration_seconds`, `catalog_search_duration_seconds` | histogram | `op`, `engine` | `query`, `search` |

: Chỉ số quan sát của PH-02

Luật cảnh báo đặt ở PH-13 (NFR-02-019); phần dưới là bộ luật PH-02 đề nghị:

| Cảnh báo | Điều kiện | Mức | Người nhận |
|---|---|---|---|
| Đồng bộ quốc gia quá hạn | `catalog_national_sync_overdue_total > 0` | Cao | TA, TO |
| `DEPRECATED` sắp hết hạn mà còn bên dùng | `catalog_deprecated_in_use_total > 0` và `sunsetAt` còn ≤ 30 ngày | Trung bình | SV, CA, TA |
| Chờ duyệt quá hạn | `catalog_review_pending_age_seconds` quá 5 ngày làm việc | Trung bình | CA, TA |
| Công bố hoặc cấp quyền thất bại | `catalog_publish_jobs{status="FAILED"} > 0` hoặc `catalog_grant_failed_total` tăng | Cao | TO |
| Gateway lệch cấu hình | `catalog_gateway_drift_total` tăng; riêng `EXTRA_ROUTE` là Nghiêm trọng | Cao, Nghiêm trọng | TO, SO |
| Hộp gửi tồn | `catalog_outbox_oldest_age_seconds > 300` | Cao | Vận hành |
| Hàng đợi kiểm tra đầy | `catalog_lint_queue_depth > 15` trong 5 phút | Trung bình | Vận hành |
| Gỡ phạm vi tồn | `catalog_grant_detach_pending > 0` quá 15 phút | Cao | TO, SO |
| Chặn URL đặc tả tăng đột biến | `catalog_spec_url_fetch_blocked_total` tăng gấp 5 lần nền trong 10 phút | Trung bình | SO |

: Luật cảnh báo đề nghị

Log là JSON một dòng với `tenant`, `apiCode`, `versionNo`, `traceId`, `actor` (mã định danh, không tên), `event`; **không** có nội dung đặc tả, chuỗi khớp của bộ quét, `SpecSource`, thân yêu cầu hay token; thư viện log chung che theo `@Classified` và mẫu (SEC-32). Vết dùng OpenTelemetry: span `catalog.publish`, `catalog.grant`, `catalog.lint`, `catalog.ingest.fetch`, `catalog.sync.dispatch`, thuộc tính `dh.api`, `dh.version`, `dh.env`, `dh.sourceVersion`; `traceparent` đi theo tiêu đề của dòng outbox nên vết nối được qua Kafka sang PH-03, PH-15. Lấy mẫu 100% cho công bố và cấp quyền (nhịp thấp), 10% cho đường đọc. Kiểm toán không đi qua log mà qua `dh-audit` (SEC-60): mỗi chuyển trạng thái ghi người thực hiện, đối tượng, giá trị trước, sau, lý do, kết quả; riêng kết quả quét bí mật ghi số phát hiện theo mẫu và người xác nhận "không phải bí mật", không ghi giá trị (FR-02-018).

## 11. Hiệu năng và vận hành

Định cỡ ở hồ sơ tỉnh vừa theo GĐ-02-01: 180 API, 400 phiên bản, 360 gói, 640 đăng ký; trần thiết kế 2.000 API, 20.000 đăng ký. Với 400 phiên bản trung bình 25 thao tác, `api_operation` có khoảng 10.000 dòng; kết quả kiểm tra và lịch sử trạng thái vài chục nghìn dòng; schema `ph02_catalog` dự kiến dưới 1 GiB ở tỉnh vừa và khoảng 10 GiB ở trần (**giả định**, kích thước trung bình dòng 1 KiB, chưa tính chỉ mục). Đặc tả nằm ở Garage: 400 phiên bản × khoảng 300 KiB trung bình (**giả định**) là khoảng 120 MiB, vĩnh viễn (NFR-02-017), rất nhỏ so với hạn mức kho đối tượng 500 GB mỗi tenant (D03-10 §5.3). CPU trung bình của phần PH-02 ước 0,3 vCPU; đỉnh là một lần kiểm tra đặc tả 10 MiB chiếm khoảng 1 vCPU trong tối đa 20 giây, nên số lần kiểm tra đồng thời bị giới hạn (mục 4.4) thay vì cấp thêm CPU cho mọi pod.

| NFR | Cách thiết kế đáp ứng | Cách đo |
|---|---|---|
| NFR-02-001 (tra cứu p95 ≤ 300 ms) | Chỉ mục `(tenant_id, status, updated_at)` và `(tenant_id, api_code)`, nạp chi tiết bằng một truy vấn gom (không N+1), `ETag` và `304`, đếm tổng trên chỉ mục phủ | Gatling, 2.000 API, 200 người dùng đồng thời |
| NFR-02-002 (tìm kiếm p95 ≤ 500 ms) | GIN trên `tsv`, `pg_trgm` cho tiền tố mã, `ts_rank_cd` giới hạn 200 kết quả đầu | Gatling, 10.000 phiên bản (Q02-21) |
| NFR-02-003 (kiểm tra ≤ 5 giây, 20 giây) | Phân tích một lần, luật chạy song song trên cây bất biến, RE2/J, giới hạn đồng thời | JMH cho từng luật, Gatling đường đầy đủ |
| NFR-02-004 (so sánh ≤ 3 giây) | Chuẩn hóa một lần, `SchemaDiff` đệ quy có nhớ, `diff_result` làm bộ đệm theo cặp băm | JMH, hai đặc tả 5.000 dòng |
| NFR-02-005 (hiệu lực ≤ 30 giây) | Ngân sách ở bảng dưới; gom nhóm xác nhận; saga không chờ thăm dò chậm | Đo `catalog_publish_duration_seconds` và `catalog_grant_duration_seconds` |
| NFR-02-006 (đọc ≤ 300 ms, ghi ≤ 600 ms) | Giao dịch ghi ngắn, việc nặng chuyển bất đồng bộ, khóa chỉ ở cuối | Gatling |
| NFR-02-007, 008, 009 (sẵn sàng, cách ly, khôi phục) | Hai bản sao `api` có PDB, `worker` thuê tác vụ, PH-03 không gọi PH-02 trên đường lượt gọi; CNPG và DR hai site | Hỗn loạn CX-01, diễn tập DR |
| NFR-02-010, 011 (quy mô, độ phức tạp đặc tả) | `QuotaGuard`, giới hạn bộ phân tích | Kiểm thử đặc tả độc hại |
| NFR-02-012 (không lọt bí mật) | Mục 4.4, canary | Bộ kiểm thử rò rỉ D05-02-PH02 |
| NFR-02-014, 015 (đồng bộ ≤ 15 phút, thông báo ≤ 15 phút) | Hàng đợi bền, bộ gửi quét 1 giây, thông báo qua outbox | Đo từ lúc sự kiện phát ra |
| NFR-02-020 (phát hiện lệch ≤ 10 phút) | Đối soát 5 phút | Tiêm lệch có chủ đích |

: Cách thiết kế đáp ứng các yêu cầu phi chức năng chính

Ngân sách thời gian cho NFR-02-005 (giả định, đo lại khi PH-03 có bản chạy được): ghi quyết định và xếp việc 0,1 giây; `PublishJobWorker` lấy việc 1 giây; lắp dữ liệu công bố 2 giây; PH-03 dựng và ghi ảnh chụp 3 giây; lan truyền tới APISIX 10 giây (D03-09 §6.1); APISIX nạp và xác nhận 3 giây; hoàn tất và ghi 1 giây: tổng khoảng 20 giây, còn dư 10 giây cho p95.

Vận hành (sổ tay ở D06-03) gồm các tình huống riêng của PH-02:

1. **Công bố kẹt `PENDING`**: xem `publish_job` (trạng thái, lần thử, lỗi), trạng thái xác nhận của PH-03, sau đó "Thử lại công bố".
2. **Cấp quyền `FAILED`**: kiểm tra từng bước ở `grant_job`, "Cấp lại" hoặc "Hủy cấp"; dọn phần `cleanup_mark`.
3. **Lệch cấu hình**: đọc `gateway_drift`; `EXTRA_ROUTE` chuyển SO điều tra trước khi gỡ.
4. **Đồng bộ quốc gia `REJECTED` hoặc `FAILED` kéo dài**: xem lý do, sửa thông tin API, "Gửi lại" (`force`); kịch bản PH-14 chặn 8 ngày kiểm cảnh báo tuân thủ.
5. **Khóa HMAC của dấu vân tay phát hiện được xoay**: mọi phát hiện `ACKNOWLEDGED` mở lại `OPEN` để SO xác nhận lại; lên lịch ngoài giờ cao điểm.
6. **Khôi phục sau DR (`EpochGuard`)**: khôi phục từ bản sao lưu có thể làm `source_version` thấp hơn số gateway đã nạp (RPO ≤ 15 phút). Khi khởi động, `EpochGuard` hỏi `describe(env)` lấy số phiên bản lớn nhất APISIX đang giữ; nếu số của PH-02 thấp hơn thì nhảy lên `max + 1` và gọi `rebuild`, để gateway không từ chối ảnh chụp có số thấp hơn (Q02-23).
7. **Nâng cấp lược đồ**: changeset Liquibase, kiểm bằng Squawk (CI-2), không khóa bảng dài; thay đổi luật kiểm tra không ảnh hưởng phiên bản đã `PUBLISHED`, chỉ áp cho `DRAFT` ở lần kiểm tra kế tiếp.

Lưu giữ theo NFR-02-017: đặc tả, phiên bản, đăng ký, lịch sử vòng đời, cam kết SLA giữ vĩnh viễn (không có tác vụ xóa); `sla_period` 3 năm; `national_sync_record` 5 năm; `change_notice` 2 năm; `lint_finding` 1 năm; kiểm toán 12 tháng trực tuyến và WORM 5 năm do PH-13. Bảng lớn theo thời gian được phân vùng theo tháng ở hồ sơ lớn (mục 9.3) để xóa bằng cách bỏ phân vùng. Sao lưu `ph02_catalog` theo CNPG và Velero (ADR-035), bucket Garage sao chép cùng chính sách của kho đối tượng (ADR-008); mục tiêu RPO ≤ 15 phút, RTO ≤ 4 giờ (NFR-02-009).

## 12. Kiểm thử

Bảng dưới nêu các mức kiểm thử áp dụng cho mã của PH-02 và công cụ; ca kiểm thử chi tiết ở D05-02-PH02.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Máy trạng thái: mọi cặp (trạng thái, lệnh) không có ở bảng 8.1 bị từ chối; `ReviewPolicy` mọi hoán vị người gửi, người sửa, người duyệt; `AuthPolicyMatrix` 4 mức × 5 kiểu; `ChangeClassifier` mỗi luật một ca dương, một ca âm; `SecretScanner` bộ 50 mẫu chuẩn (≥ 95%) và bộ mẫu không phải bí mật (tỷ lệ báo nhầm đo được); `SafeFetcher` phân loại địa chỉ (IPv4, IPv6, IPv4 ánh xạ, dạng thập phân, bát phân, thập lục phân); `ScopeCalculator`; `PlanCompatibilityChecker` | JUnit 5; jqwik cho tính chất (so sánh một đặc tả với chính nó cho kết quả rỗng, chuẩn hóa lũy đẳng, thêm rồi xóa trường đối xứng) |
| Kiến trúc | Luật Modulith, chu trình module, chỉ ba gói ghi `status`, `internal.domain` sạch, `@PreAuthorize` mọi controller, cấm log đối tượng nhạy cảm | ArchUnit, `ApplicationModules.verify()`, Semgrep (CI-2, CI-7) |
| Tích hợp | PostgreSQL 18 với RLS, chỉ mục duy nhất từng phần, khóa tư vấn, `SKIP LOCKED` nhiều `worker`; Kafka; Garage; ClamAV (tệp EICAR); Keycloak (phạm vi); WireMock thay PH-12, PH-14, PH-04, PH-13, PH-18; `gateway` giả cài `GatewayApplyPort` | Testcontainers (CI-3) |
| Đua và đồng thời | Gửi đăng ký đua với ngừng hẳn; hai người duyệt cùng lúc; hai `worker` cùng nhận một `publish_job`; hai người đăng ký cùng context-path | Testcontainers, nhiều luồng |
| Hợp đồng | OpenAPI của PH-02 (luật Datahub, không phá vỡ `v1`); AsyncAPI sự kiện (BACKWARD); hợp đồng hai chiều với PH-03, PH-12, PH-14, PH-04, PH-18 | Spectral, oasdiff, Apicurio, Pact (CI-5) |
| Bảo mật | Rò rỉ chéo tenant mọi API (kỳ vọng `404`); canary bí mật `DH-CANARY-…` ở log, vết, kết quả, sự kiện, CSDL; bộ SSRF (siêu dữ liệu cloud, chuyển hướng vào mạng nội bộ, đổi bản ghi DNS bằng bộ phân giải giả); bộ đặc tả độc hại (bom alias, lồng 10.000 cấp, 20 MiB, ZIP bomb, mẫu ReDoS); bốn mắt; ma trận xác thực | D05-02-PH02, D05-04, ZAP, Schemathesis |
| Hỗn loạn | Tắt `dh-connect` khi đang công bố (CX-01); chặn PH-14 8 ngày; kill `worker` giữa saga; Garage ngừng; Kafka ngừng; DR làm lùi `source_version` | D05-01, Chaos Mesh |
| Hiệu năng | Tra cứu, tìm kiếm, kiểm tra đặc tả, công bố đến gọi được | Gatling hoặc k6, JMH |
| Giao diện | 17 màn UI-02-*, WCAG 2.2 AA | Playwright, axe (CI-9) |
| Chấp nhận | 12 tiêu chí cấp phân hệ ở FRS §14 | D05-02-PH02 |

: Chiến lược kiểm thử

Các tiêu chí chấp nhận của FRS §14 được đặt vào mức kiểm thử như sau: tiêu chí 1 (ca dương, âm mỗi FR mức M, rò rỉ chéo tenant) ở mức đơn vị, tích hợp và bảo mật; 2 (rò rỉ bí mật) ở mức bảo mật; 3 (vòng đời 5 API thật) và 4, 6 (ngừng khuyến nghị, thay thế cùng số chính) ở mức tích hợp với `gateway` giả rồi kiểm lại ở môi trường thử có APISIX thật; 5 (cấp phạm vi, thu hồi trong 30 giây) ở mức hiệu năng và hỗn loạn; 7 (đồng bộ quốc gia, chặn 8 ngày) ở mức tích hợp với PH-14 mô phỏng; 8 (tắt `dh-connect` 24 giờ) ở mức hỗn loạn CX-01; 9 (NFR) ở mức hiệu năng; 10 (nhập hệ cũ) ở mức tích hợp với gói xuất mẫu; 11, 12 ở mức chấp nhận. Ca kiểm thử chi tiết có mã `TC-02-nnn` thuộc D05-02-PH02, không đánh số ở tài liệu này.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Bảng dưới chia việc hiện thực thành các bước theo thứ tự phụ thuộc, kèm FR chính của từng bước.

| Bước | Nội dung | FR chính | Phụ thuộc |
|---|---|---|---|
| 1 | Khung module `catalog`: miền, `StateMachine`, outbox, RLS, `CodeRegistry`; đăng ký API, nạp đặc tả (`SafeFetcher`, bộ phân tích an toàn), danh mục và tìm kiếm PostgreSQL; di trú `ph02.api_service`, gỡ module cũ ở `apps/control` | 001…008, 010…015 | `pg-core`, Garage, ClamAV, PH-01 `SystemDirectoryApi` |
| 2 | Bộ kiểm tra: lớp 1, 15 luật lớp 2, quét bí mật, phát hiện trùng; `LintExecutor`; quản lý luật | 016…021 | Bước 1 |
| 3 | Backend, gói, ma trận xác thực, khung route; vòng đời, duyệt bốn mắt, `PublishedConfigApi`, `PublishCoordinator` với module `gateway`; so sánh phiên bản | 022…045, 059, 036 | PH-03 (module `gateway`), PH-04, PH-05, Bước 2 |
| 4 | Đăng ký sử dụng, `GrantOrchestrator`, thu hồi, tạm ngừng; sự kiện PH-01 | 046…051 | PH-12, PH-01 định danh máy, Bước 3 |
| 5 | Đồng bộ quốc gia, SLA, thông báo; quan sát và cảnh báo | 053…057 | PH-14, PH-13, PH-18, Bước 3 |
| 6 | Di trú APIM cũ, tham số, nhập hệ cũ; chạy song song (strangler) | 061, 062 | Bước 1…4 |
| 7 | Đợt 2: dịch vụ sự kiện, gia hạn và rà soát, thống kê, đối soát gateway | 009, 052, 058, 060 | PH-10, Bước 4, 5 |

: Lộ trình hiện thực

Bước 3 là đường găng vì phụ thuộc PH-03 chưa có tài liệu; để không chặn, bước 1 và 2 làm cùng một bản `GatewayApplyPort` giả (nạp ngay, xác nhận ngay) và một harness mô phỏng APISIX standalone để chạy trọn vòng đời trong CI.

### 13.2. Rủi ro

Bảng dưới liệt kê rủi ro kỹ thuật của PH-02, mức độ và cách giảm thiểu đã thiết kế.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| PH-03 chậm hoặc hợp đồng xác nhận nạp khác thiết kế (Q02-22) | Cao | Cổng `GatewayApplyPort` giả, harness APISIX; thống nhất hợp đồng sớm ở đồng bộ PH-03 |
| Đặc tả giao thức quốc gia chưa có (Q02-08) | Cao | Mọi thứ sau `NationalCatalogPort` và `PayloadBuilder`; hàng đợi giữ bản ghi |
| Bộ quét bí mật báo nhầm nhiều làm chủ dịch vụ nản | Trung bình | Luồng "không phải bí mật" do SO xác nhận, đo tỷ lệ báo nhầm, bộ mẫu giữ chỗ được ATTT duyệt (Q02-11) |
| 70% đặc tả đầu tiên có lỗi lớp 2 (GĐ-02-03) | Trung bình | Mẫu đặc tả, quy ước (FR-02-015), xem trước khi gõ, cảnh báo thay vì lỗi cho luật cho phép hạ mức |
| Số phạm vi trong token quá lớn với HTTT có nhiều đăng ký (Q02-24) | Trung bình | Trần 50 phạm vi mỗi đăng ký, gom theo API; phương án dùng dữ liệu OPA thay cho phạm vi |
| Lùi `source_version` sau DR | Trung bình | `EpochGuard` nhảy tiến và dựng lại (mục 11); kiểm thử hỗn loạn |
| Đặc tả độc hại làm hết bộ nhớ pod `api` | Trung bình | Giới hạn đồng thời và hạn thời gian, `lint-worker` cô lập ở hồ sơ lớn, kiểm thử bộ đặc tả độc hại |
| PH-05 không cho "cấp kết nối cho API" (đề nghị ở FRS) | Trung bình | Phương án dự phòng: backend `SYSTEM` chỉ qua luồng PH-04; ghi vào Q02-06 |
| Tìm kiếm PostgreSQL không đạt p95 ở hồ sơ lớn | Thấp | `SearchEngine` thay được bằng OpenSearch, đã có giao diện (Q02-21) |
| Điểm tuần tự ở `config_epoch` khi nhiều thay đổi dồn | Thấp | Chỉ giữ ở cuối giao dịch; đo ở bước 3; nếu cần thì bump theo lô |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q02-20:** Kiểm tra lớp 2 bằng bộ luật Java trong DU (đề xuất của tài liệu này) hay bằng Spectral chạy trong `lint-worker`. Java tránh thêm môi trường Node và bề mặt tấn công; Spectral có hệ luật cộng đồng sẵn. Cần thử nghiệm với 15 luật LINT-02 trên 20 đặc tả thật (thời gian, độ chính xác, bộ nhớ) trước khi chốt ở bước 2.

> **Câu hỏi mở Q02-21:** Chốt công cụ tìm kiếm (nối tiếp Q02-02). Đề xuất: PostgreSQL mặc định; chuyển OpenSearch khi đo thật ở 10.000 phiên bản có p95 > 500 ms hoặc khi tenant có hơn 5.000 API. Cần số đo với cấu hình `unaccent` và `pg_trgm` ở hồ sơ `QM-LON`.

> **Câu hỏi mở Q02-22:** Hợp đồng xác nhận "đã nạp" với PH-03: APISIX có nhiều pod, ảnh chụp tới từng pod ở các thời điểm khác nhau. Đề xuất: PH-02 coi là đã nạp khi quá bán số pod sẵn sàng xác nhận `configVersion ≥ mục tiêu` và pod còn lại bị `DriftReconciler` bắt ở trạng thái `VERSION_BEHIND` nếu chậm quá 60 giây. Cần PH-03 xác nhận cách báo và cách tính số pod.

> **Câu hỏi mở Q02-23:** Sau khôi phục DR có thể có `source_version` thấp hơn số gateway đã nạp. Đề xuất `EpochGuard` nhảy tiến lên `max + 1` và dựng lại; cần PH-03 xác nhận gateway chấp nhận số phiên bản nhảy vọt và từ chối số thấp hơn, và cung cấp `describe` trả số lớn nhất.

> **Câu hỏi mở Q02-24:** Phạm vi `api:{mã API}:{mã gói}` tạo một phạm vi cho mỗi đăng ký; HTTT dùng nhiều API (trung bình 8, có thể hàng chục) làm token tăng kích thước, nhất là khi giới hạn theo thao tác. Đề xuất trần 50 phạm vi mỗi đăng ký (`dh.catalog.grant.max-scopes`); nếu token vượt 4 KiB thì chuyển sang kiểm theo dữ liệu đăng ký ở OPA thay cho phạm vi trong token. Cần PH-12 xác nhận giới hạn kích thước và khả năng.

> **Câu hỏi mở Q02-25:** Đặc tả lưu vĩnh viễn ở Garage (BR-02-014). Có bật khóa đối tượng (Object Lock chế độ quản trị) cho tiền tố `specs/` để chống xóa nhầm không, và có nén (zstd) không. Đề xuất: bật khóa quản trị, không nén ở bản 0.1 vì tổng nhỏ (khoảng 120 MiB mỗi tỉnh vừa); cần xác nhận với nhóm hạ tầng về hỗ trợ ở Garage (ADR-008).

> **Câu hỏi mở Q02-26:** Công thức điểm trùng chức năng (0,5 · đường dẫn, 0,3 · trường phản hồi, 0,2 · từ khóa, ngưỡng 0,8) là giả định chưa hiệu chỉnh. Cần chạy trên 50 đặc tả thật đầu tiên để chỉnh trọng số, ngưỡng, và đo tỷ lệ gợi ý sai trước khi dùng làm cảnh báo cho người duyệt.

> **Câu hỏi mở Q02-27:** PH-02 cần từ PH-18 ba hợp đồng chưa có: lịch ngày làm việc của tenant (để tính nhắc sau 3 ngày, quá hạn sau 5 ngày), kênh thư điện tử và thông báo trong ứng dụng có khóa lũy đẳng (NFR-02-015), và cờ đóng băng thay đổi môi trường thật (ERR-02-039). Đề xuất khi chưa có lịch: tính thứ Hai đến thứ Sáu, trừ ngày lễ của tham số `18.calendar`.

> **Câu hỏi mở Q02-28:** Khi hai tenant sáp nhập (REQ-20, Q02-07), mã API và context-path của hai bên có thể trùng. Đề xuất: PH-02 xuất, nhập theo gói của chính nó, và khi trùng thì bắt buộc đổi mã ở tenant nguồn kèm bí danh cho `legacyPath`; cần PH-20 chốt quy trình trước khi viết lệnh xuất, nhập.

> **Câu hỏi mở Q02-29:** Hồ sơ cách ly mạng (HT-A air-gapped, ADR-036) không có đường ra Internet: nạp đặc tả từ URL chỉ dùng được với máy chủ nội bộ trong danh sách FQDN, và ClamAV, bộ luật quét cần cập nhật ngoại tuyến. Đề xuất mặc định tắt nguồn `URL` ở hồ sơ này và cho TA bật từng FQDN; cần ATTT và hạ tầng xác nhận.

## Đề nghị đồng bộ

Các việc dưới đây nằm ngoài quyền sửa của tập này (tài liệu dùng chung hoặc phân hệ khác); chuyển cho luồng hoặc đợt đồng bộ phụ trách. Các đề nghị với FRS §4.3 (cạnh `PUBLISHED → RETIRED`, `activating`) và với tập màn hình (`gatewayState`, `grantStatus`, tiến độ tác vụ) đã được thực hiện ở lượt rà soát chéo nên không còn ở bảng này.

| Tài liệu | Đề nghị |
|---|---|
| D03-03-PH02 (CSDL) | Chốt các bảng dự kiến ở SDD: `api`, `api_version`, `api_spec`, `api_operation`, `api_search_doc`, `lint_finding`, `lint_rule`, `lint_rule_override`, `backend`, `plan`, `plan_operation_scope`, `subscription`, `grant_job`, `review_request`, `review_decision`, `version_contributor`, `version_state_history`, `subscription_state_history`, `deprecation_reminder`, `sla_commitment`, `sla_maintenance_window`, `sla_period`, `usage_daily`, `change_notice`, `change_notice_recipient`, `national_sync_record`, `national_sync_run`, `config_epoch`, `config_change_log`, `publish_job`, `gateway_drift`, `diff_result`, `code_registry`, `context_path_reservation`, `category`, `api_tag`, `import_session`, `legacy_id_map`, `async_operation`, `pending_command`, `inbox_event`, `outbox_event`, `idempotency_record`, `job_lease`; chỉ mục duy nhất từng phần cho BR-02-027; `CHECK` giữa `visibility` và `data_class`; vai trò ứng dụng không có `UPDATE`, `DELETE` trên `api_spec` |
| D03-09 §5.3, §4.2 | Thêm dòng định cỡ `lint-worker` cho `QM-LON`, `QM-CHUNG` (đề xuất 1 vCPU, 2 GiB mỗi bản, 2 bản); ghi bucket Garage `dh-{tenant}-catalog` và dung lượng ước tính; ghi `dh-connect` có ba vai trò `api`, `worker`, `lint-worker` |
| D03-09 §6.1, ADR-005 | Thêm hợp đồng xác nhận nạp giữa PH-02 và PH-03 (Q02-22, Q02-23): `describe(env)` trả số phiên bản cấu hình từng pod và băm nguồn từng route; chấp nhận số phiên bản nhảy vọt |
| PH-03 (khi viết) | Module `gateway` cài `GatewayApplyPort` (`requestApply`, `status`, `describe`, `rebuild`), đóng dấu `contentHash` của PH-02 vào route đã sinh, gọi `GatewayAckApi`; quy ước đặt tên route `{apiCode}:v{major}:{operationId}` để PH-13 gom số đo theo API |
| PH-12 (khi viết) | API gắn, gỡ phạm vi `api:*` lũy đẳng theo `Idempotency-Key`; giới hạn kích thước token (Q02-24) |
| PH-13 (khi viết) | Truy vấn cho `MetricsReadPort`: p99 theo (API, kỳ), số lượt theo nhóm mã trạng thái, ngày có dữ liệu, lượt cao nhất mỗi giờ, sử dụng theo thao tác và theo bên khai thác; quy tắc ghi tổng hợp theo ngày từ chỉ số `apisix_http_*` |
| PH-14 (khi viết) | `NationalCatalogPort`: `upsert`, `withdraw` lũy đẳng theo khóa, kết quả `NOT_CONFIGURED`; cách báo từ chối kèm lý do |
| PH-18 (khi viết) | Lịch ngày làm việc, `NotificationApi` kênh trong ứng dụng và thư điện tử có khóa lũy đẳng, cờ đóng băng thay đổi, lưu `02.*` (Q02-27) |
| PH-01 (khi viết) | `SystemDirectoryApi`: HTTT `ACTIVE`, đơn vị chủ quản, đầu mối kỹ thuật, định danh máy theo kiểu xác thực; sự kiện cấp xong định danh máy và tạm ngừng, thu hồi HTTT |
| PH-04 FRS | `createFromSpec` lũy đẳng theo `apiRef`; sự kiện EVT-04-02, 04, 07 mang `restOperations[]`; đọc đặc tả sinh từ luồng qua API nội bộ |
| PH-05 FRS | Cho phép cấp kết nối cho API của PH-02 (cùng đề nghị ở FRS PH-02) |
| D04-01 | Bổ sung quy ước: dùng RE2/J cho mọi biểu thức chính quy chạy trên dữ liệu không tin cậy; mẫu `TenantScopedJob` với `job_lease`; mẫu "kích hoạt chờ xác nhận, hạn chế ghi ngay" |
| D05-01 | Thêm ca hỗn loạn "kill `worker` giữa saga công bố", "DR làm lùi `source_version`", "tắt `dh-connect` khi đang công bố", "PH-14 chặn 8 ngày" |
| D03-07 | Ghi nơi hiện thực: SEC-16 (`SafeFetcher`), SEC-45 (đường ống nạp đặc tả), SEC-07 (`ReviewPolicy`), SEC-24 (`AuthPolicyMatrix`), SEC-43 (chỉ route khai trong đặc tả đã duyệt) |
| Đề xuất ADR | Chưa tạo ADR trong tập này. Đề nghị cấp dải ADR cho PH-02 (ví dụ 050…059 "và khác") cho bốn quyết định: (1) phiên bản là đơn vị vòng đời, gói thuộc phiên bản (nối tiếp FRS); (2) tìm kiếm danh mục PostgreSQL mặc định, OpenSearch tùy chọn (Q02-02, Q02-21); (3) công bố có xác nhận từ cổng: kích hoạt chờ xác nhận mới ghi, hạn chế ghi ngay; (4) cô lập kiểm tra đặc tả: giới hạn đồng thời, RE2/J, `lint-worker` ở hồ sơ lớn |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD và quy chuẩn K-TRINH-BAY: vị trí trong kiến trúc, cấu trúc mã `vn.datahub.connect.catalog`, 14 thành phần với bảng đặc tả 10 mục, 8 biểu đồ tuần tự, bảng chuyển trạng thái, xử lý lỗi và saga, cấu hình, khả năng mở rộng, bảo mật theo SEC, 10 câu hỏi mở |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: số API 98; phạm vi `catalog:gateway-read` và `catalog:gateway-ack`; luồng ndjson của API-02-080; sửa backend sau công bố qua `BACKEND_CHANGE`; ghi giao diện vào của API-02-092…098; Giới thiệu theo khuôn; câu mở các mục; bỏ các đề nghị đồng bộ đã thực hiện |
