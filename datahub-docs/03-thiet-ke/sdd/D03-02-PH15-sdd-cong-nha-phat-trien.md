---
ma_tai_lieu: D03-02-PH15
ten: Thiết kế chi tiết phần mềm phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect và dh-portal, kiến trúc sư, ATTT, vận hành, hội đồng thẩm định
phan_he: PH-15
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Cổng nhà phát triển gồm SPA dh-portal với BFF và module portal của dh-connect, chốt các điểm FRS để ngỏ (vị trí MOCK, forward-auth, token exchange, tìm kiếm), sơ đồ tuần tự, máy trạng thái, bảo mật, quan sát, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH15 FRS; D03-03-PH15 CSDL; D03-04-PH15 API; D03-07 ATTT; D03-10 Đa tenant; D04-01 Quy ước mã
---

# D03-02-PH15 · Thiết kế chi tiết Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 62 FR của [D02-03-PH15](../../02-yeu-cau/frs/D02-03-PH15-frs-cong-nha-phat-trien.md): ứng dụng `dh-portal` (React 19, antd v6, Liquid Glass, kèm BFF Spring Cloud Gateway nhẹ ở Z2) và module `portal` trong DU `dh-connect` (package `vn.datahub.connect.portal`, Z3). PH-15 là lớp trình bày và tự phục vụ, ngoài đường dữ liệu lúc chạy; thiết kế giữ ranh giới đó bằng năm quyết định chính:

1. **Danh mục là bản sao chỉ đọc, hiển thị được quyết định ở một chỗ.** `portal.catalog` kéo từ PH-02 (API-02-081, gia tăng `updatedSince` và `removed[]`, nghe EVT-02-*) và mọi truy vấn đi qua một `VisibilityPolicy` duy nhất, dùng chung cho SQL, chỉ mục tìm kiếm và tải đặc tả. Kết quả tìm kiếm luôn được kiểm tra lại với CSDL trước khi trả (BR-15-002).
2. **Cổng không cầm bí mật của ứng dụng.** Bí mật sandbox sinh ở Keycloak realm `dh-dev` (hoặc sinh ngẫu nhiên cho API key), trả một lần rồi quên; CSDL chỉ giữ tiền tố và băm. Khi thử API, `portal.try` xin token ngắn hạn thu hẹp phạm vi qua token exchange thay vì giữ bí mật (SEC-24, SEC-33).
3. **Sandbox có đường chạy riêng, không chạy trong APISIX.** `portal.mock` là một vai trò triển khai riêng của `dh-connect` (Deployment `portal-sandbox`), vừa sinh phản hồi `MOCK`, vừa chuyển tiếp `BACKEND` có allowlist và ngắt mạch. APISIX chỉ giữ một tuyến tĩnh cộng plugin `forward-auth` gọi API-15-082; PH-15 không đẩy cấu hình gateway (QĐ-15-01, QĐ-15-02).
4. **An toàn khi lỗi.** Thử production và thử API nhạy cảm yêu cầu ghi kiểm toán đồng bộ trước khi gọi; `forward-auth` đóng (từ chối) khi không hỏi được cổng (BR-15-023).
5. **Mọi việc ghi đều lũy đẳng.** `Idempotency-Key` (ADR-041), `If-Match`, outbox cho sự kiện (ADR-042), inbox cho sự kiện đến; thao tác chạm Keycloak đi theo saga có bù trừ và đối soát định kỳ.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| FR hiện thực | 62 (NFR-15-001…022, BR-15-001…034) |
| Module Modulith của `portal` | 10 (kể cả `shared`) |
| Vai trò triển khai của `dh-connect` cho cổng | 3 (`api`, `worker`, `portal-sandbox`) |
| Thành phần mô tả ở chương 4 | 14 (mỗi thành phần có bảng 10 mục) cùng mô hình miền |
| Quyết định thiết kế chốt cho FRS để ngỏ | 16 (QĐ-15-01…16) |
| Sơ đồ tuần tự | 8 |
| Bảng CSDL dự kiến (`ph15_portal`) | 40 (Phụ lục A) |
| Câu hỏi mở của SDD | 10 (Q15-20…29) |

: Con số chính của SDD PH-15

## 1. Giới thiệu

### 1.1. Mục đích, phạm vi và cách đọc

Mục đích của tài liệu là cho kỹ sư đủ thông tin để lập trình, kiểm thử và vận hành cổng mà không phải đoán cơ chế. Tài liệu đi từ vị trí trong kiến trúc và các quyết định chốt cho FRS (chương 2), cấu trúc mã (chương 3), từng thành phần (chương 4), sequence của FR phức tạp (chương 5), tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát và vận hành (chương 6 đến 11). Mã ERR, BR, NFR, EVT, API, UI là của FRS; hợp đồng REST đầy đủ ở D03-04-PH15, bảng CSDL ở D03-03-PH15 (phụ lục A của tài liệu này chỉ chốt tên bảng dự kiến để tập CSDL theo). Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới. Điều gì FRS (Phụ lục A) chốt thì tài liệu này theo; chỗ cần khác ghi ở mục "Đề nghị đồng bộ".

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4 + Modulith cho `dh-connect` |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` |
| ADR-004 | Kafka cho sự kiện EVT-15 và EVT-02 |
| ADR-005, ADR-033 | APISIX, plugin `forward-auth`, WAF Coraza ở lớp biên |
| ADR-006 | Keycloak + OPA |
| ADR-008 | Garage cho ảnh đính kèm, logo |
| ADR-011 | OpenTelemetry và LGTM |
| ADR-012 | OpenBao cho mã truy cập Git, bí mật backend thử |
| ADR-013 | Tách control plane và data plane (cổng ở control plane) |
| ADR-020 | Liquid Glass trên antd v6 |
| ADR-041, ADR-042 | Idempotency, inbox và outbox trong DU |
| ADR-046 | Bốn mắt (dùng lại cách tiếp cận, không dùng bảng của PH-19) |
| ADR số 075 (đề xuất) | Cổng tự xây trên `@datahub/ui`, thay Backstage (ghi ở Đề nghị đồng bộ của FRS) |

: ADR áp dụng cho PH-15

### 1.2. Người đọc và tài liệu tham chiếu

Chọn chương theo vai trò.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` module `portal` | Chương 3, 4, 6, 8, 9, phụ lục A |
| Kỹ sư `dh-portal` (SPA, BFF) | Mục 3.1, 4.15, 7, 9.3 |
| ATTT | Chương 7, mục 4.7 đến 4.10 |
| Vận hành | Chương 9, 10, 11 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc


### 1.3. Thuật ngữ và chữ viết tắt

Thuật ngữ và chữ viết tắt dùng chung với FRS §1.4 và D00-01. Viết tắt thêm: BFF (Backend for Frontend); `forward-auth` (plugin APISIX hỏi một dịch vụ ngoài trước khi chuyển tiếp); token exchange (RFC 8693); CAS (so sánh và đổi); FGAP (phân quyền quản trị mịn của Keycloak). Mỗi thành phần ở chương 4 mở đầu bằng bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế.

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-15 nằm ở control plane (ADR-013): cổng hỏng thì lời gọi API giữa các HTTT vẫn chạy. Phần chạy của cổng gồm SPA tĩnh, BFF và ba vai trò triển khai của `dh-connect`. Cùng một ảnh `dh-connect` được chạy với thuộc tính `dh.role` khác nhau, nên module `portal` không cần DU mới (RB-15-03).

| Thành phần | DU, vai trò | Vùng | Ghi chú |
|---|---|---|---|
| SPA `dh-portal` | `dh-control` (tệp tĩnh) | Z1, Z2 | Phục vụ qua `apisix-ext`, tệp có băm nội dung, SRI (SEC-44) |
| BFF của `dh-portal` | `dh-gateway` (Spring Cloud Gateway nhẹ) | Z2 | 2 bản sao, phiên ở Valkey (SEC-21) |
| Module `portal` vai trò `api` | `dh-connect` | Z3 | REST `/api/portal/v1`, cổng nội bộ 8081 cho `forward-auth` |
| Module `portal` vai trò `worker` | `dh-connect` | Z3 | Đồng bộ danh mục, nhập Git, tác vụ định kỳ, tiêu thụ Kafka, gửi outbox |
| Module `portal.mock` vai trò `portal-sandbox` | `dh-connect` | Z3 | Chạy sandbox `MOCK` và `BACKEND`, không ghi CSDL, chỉ đọc bản sao |
| `pg-core` schema `ph15_portal` | Nền tảng | Z5 | RLS theo `tenant_id`; vai trò CSDL `portal_app`, `portal_sandbox_ro` |
| Valkey | Nền tảng | Z5 | Phiên BFF, bộ đệm, bộ đếm hạn mức, khóa lũy đẳng |
| OpenSearch (tùy chọn) | Nền tảng | Z5 | Chỉ mục `portal-{tenant}-catalog` (SEC-82) |
| Garage | Nền tảng | Z5 | Bucket `{tenant}-portal-content` (ảnh, logo, gói di trú) |
| OpenBao | Nền tảng | Z6 | `kv/dh/{tenant}/portal/*` (mã truy cập Git, bí mật backend thử), khóa `transit` ký xác nhận thử |
| Keycloak | PH-12 | Z6 | Realm `dh-{tenant}` và `dh-dev` |
| APISIX | PH-03 | Z1, Z2 | Tuyến sandbox tĩnh và `forward-auth`; khu quản trị qua `apisix-int` |

: Đơn vị triển khai và vùng mạng của PH-15

Hai đường mạng cần nhớ. Lưu lượng từ `portal-sandbox` ra backend thử đi qua egress gateway có `ServiceEntry` theo FQDN (SEC-16), chính sách mạng chỉ mở cho vai trò này. Khu `/quan-tri-cong` và `/api/portal/v1/admin/**` chỉ có ở `apisix-int` (mạng TSLCD, quản trị); ở `apisix-ext` các đường dẫn đó không có route nên trả `404` đúng BR-15-031.

### 2.2. Sơ đồ thành phần

Sơ đồ nêu các thành phần của PH-15.

```{.mermaid caption="Sơ đồ thành phần PH-15"}
flowchart TB
  subgraph Z12["Z1, Z2"]
    EXT["apisix-ext<br/>route cổng, route sandbox"]
    INT["apisix-int<br/>khu quản trị"]
    SPA["dh-portal SPA"]
    BFF["BFF<br/>phiên, CSP, CSRF"]
  end
  subgraph API["dh-connect · vai trò api"]
    WEB["web<br/>REST và cổng nội bộ"]
    CAT["catalog"]
    CON["content"]
    DEV["dev"]
    DEL["delegate"]
    TRY["try"]
    INS["insight"]
    SUP["support"]
    ADM["admin"]
    SHR["shared<br/>visibility, tenant, audit"]
  end
  subgraph WRK["dh-connect · vai trò worker"]
    SYN["CatalogSync"]
    IDX["SearchIndexer"]
    GIT["GitImporter"]
    JOB["Scheduler<br/>hết hạn, lưu giữ"]
    OUT["OutboxPublisher<br/>EventConsumer"]
  end
  subgraph SBX["dh-connect · vai trò portal-sandbox"]
    MCK["mock<br/>MockResponder, BackendForwarder"]
  end
  PG[("pg-core<br/>ph15_portal")]
  VK[("Valkey")]
  OS[("OpenSearch")]
  GAR[("Garage")]
  OB[("OpenBao")]
  KC["Keycloak<br/>dh-realm, dh-dev"]
  P02["PH-02"]
  P01["PH-01"]
  P13["PH-13"]
  KF[("Kafka")]
  EXT --> SPA
  EXT --> BFF
  INT --> BFF
  BFF --> WEB
  WEB --> CAT & CON & DEV & DEL & TRY & INS & SUP & ADM
  CAT & CON & DEV & TRY & SUP & ADM --> SHR
  CAT & CON & DEV & TRY & SUP & ADM & SYN & GIT --> PG
  CAT --> OS
  IDX --> OS
  CON --> GAR
  GIT --> OB
  DEV --> KC
  TRY --> KC
  DEL --> P02
  DEL --> P01
  SYN --> P02
  INS --> P13
  TRY --> P13
  EXT -->|"forward-auth"| WEB
  EXT --> MCK
  MCK --> PG
  OUT --> KF
  KF --> OUT
  BFF --> VK
  TRY --> VK
  WEB --> VK
```

Sơ đồ cho thấy bốn điều. Một, mọi lưu lượng từ trình duyệt đi qua BFF; trình duyệt không nói trực tiếp với `dh-connect`. Hai, `worker` giữ mọi việc nền (đồng bộ, chỉ mục, Git, hết hạn) để `api` chỉ phục vụ yêu cầu. Ba, `portal-sandbox` đứng ngoài `api`: nó chỉ đọc bản sao đặc tả và hồ sơ sandbox, không ghi CSDL, không có đường tới Keycloak hay PH-13. Bốn, `forward-auth` là mũi tên duy nhất từ gateway vào `api` ngoài đường BFF.

### 2.3. Phụ thuộc với phân hệ và hạ tầng khác

PH-15 đọc từ PH-02, ủy thác cho PH-01, PH-02 và dựa vào PH-12, PH-13 như bảng sau.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| PH-02 | đọc | REST API-02-081 (scope `catalog:portal-read`, `If-None-Match`), API-02-006 (mẫu gọi) | Danh mục, đặc tả đã gộp, mã đã gỡ |
| PH-02 | nghe | Kafka EVT-02-01, 02, 03, 05, 06, 08, 10, 11, 12 (và 09 để cập nhật đăng ký) | Kích hoạt đồng bộ, thông báo thay đổi |
| PH-02 | ủy thác | REST giữ danh tính người dùng (FR-02-046, đăng ký API) | Đăng ký sử dụng, công bố API |
| PH-01 | ủy thác, đọc | REST biểu mẫu kết nạp, định danh production chỉ đọc | FR-15-032, 046 |
| PH-12 | gọi | Keycloak Admin API (client `portal-dev`), token exchange (client `portal-try`) | Tài khoản, client sandbox, token ngắn hạn |
| PH-03 | được gọi | `forward-auth` tới API-15-082 qua mTLS mesh | Kiểm tra ứng dụng, hạn mức |
| PH-13 | gọi, nghe | Ghi kiểm toán qua `dh-audit` (outbox, đồng bộ khi cần), đọc chỉ số `metrics:portal-read` | FR-15-048…050, 060 |
| PH-10 | gọi | REST `/api/event/v1/topics` (chỉ đọc danh mục), định tuyến thông báo | FR-15-007, 051 |
| PH-18 | đọc | `ParameterApi` có đệm 60 giây (`15.*`), nhắc việc | Tham số, "Việc của tôi" |
| Kho Git tài liệu | đọc | HTTPS qua egress (SEC-16) | FR-15-018 |

: Phụ thuộc của module `portal`

Quy tắc chung: PH-15 chỉ đọc và ủy thác, không bao giờ ghi vào trạng thái của PH-01, PH-02 (BR-15-001, BR-15-014). Mọi lời gọi ra dùng WebClient có thời gian chờ, thử lại có giới hạn và ngắt mạch (mục 8.4).

### 2.4. Quyết định thiết kế chốt cho điểm FRS để ngỏ

Bảng dưới chốt các điểm FRS giao cho SDD (Q15-07 và các chi tiết cơ chế) cùng những quyết định mới phát sinh khi thiết kế. Mỗi quyết định ghi phương án chọn, lý do và phương án đã loại; quyết định ảnh hưởng FRS được lặp lại ở "Đề nghị đồng bộ". Không tạo ADR mới.

| Mã | Điểm | Quyết định | Lý do, phương án đã loại |
|---|---|---|---|
| QĐ-15-01 | Vị trí MOCK (Q15-07) | `portal.mock` chạy trong ảnh `dh-connect` ở vai trò riêng `portal-sandbox` (Deployment độc lập, Z3); đảm nhận cả `MOCK` lẫn chuyển tiếp `BACKEND` | Co giãn riêng cho NFR-15-013 (≥ 100 lượt/giây), cách ly lỗi và quyền (chỉ đọc CSDL, egress allowlist riêng). Loại plugin APISIX (Lua, Wasm): khó sinh dữ liệu từ lược đồ JSON 2020-12, khó kiểm thử, gắn vòng đời gateway của PH-03. Loại chạy chung vai trò `api`: tải thử làm chậm API người dùng |
| QĐ-15-02 | Cơ chế `forward-auth` | Một tuyến tĩnh `sandbox-api.{tenant}.datahub.gov.vn/{apiCode}/{version}/**` ở `apisix-ext`: plugin `jwt-auth`/`openid-connect` kiểm chữ ký token, rồi `forward-auth` gọi API-15-082, `allow_degradation: false` (đóng khi lỗi), thời gian chờ 300 ms. Chi tiết ở mục 4.10 | PH-15 không đẩy cấu hình gateway; mọi đặc thù theo API nằm ở dữ liệu API-15-082 trả về chứ không ở cấu hình route. Loại tuyến sinh theo API: buộc PH-15 ghi cấu hình PH-03 |
| QĐ-15-03 | Token exchange (Q15-06) | `portal-try` (client bí mật, realm `dh-dev`) đổi token theo RFC 8693 lấy token của service account `sbx-…`, sống 5 phút, `aud` = nhóm API sandbox, claim `act` = người dùng. Dự phòng nếu Keycloak không đủ: `portal-try` dùng token riêng và đính xác nhận JWS `X-DH-Try-Assertion` ký bằng khóa `transit` (Q15-20) | Giữ không cầm bí mật ứng dụng (BR-15-011). Loại lưu bí mật để tự lấy token: vi phạm RB-15-01 |
| QĐ-15-04 | Tìm kiếm (Q15-11) | OpenSearch riêng của cổng, chỉ mục `portal-{tenant}-catalog-v{n}` kèm bí danh, bộ lọc hiển thị dựng từ `VisibilityPolicy`; mọi kết quả được nạp lại từ CSDL và kiểm hiển thị lần hai; `15.search.engine = PG_FTS` chuyển sang `tsvector` + `unaccent` + `pg_trgm` | Nguyên tắc phòng thủ nhiều lớp cho BR-15-002; PG FTS bảo đảm quy mô nhỏ và hồ sơ air-gapped. Loại dùng chung chỉ mục với PH-02: khác bộ lọc hiển thị |
| QĐ-15-05 | Vai trò triển khai | Ba vai trò `api`, `worker`, `portal-sandbox` từ một ảnh, theo `dh.role` (cùng cách PH-19) | Tách tải nền khỏi tải người dùng; không cần DU mới |
| QĐ-15-06 | BFF và realm | Mỗi tenant hai đăng ký OIDC trong BFF: `tenant-sso` (realm `dh-{tenant}`) và `dev` (realm `dh-dev`); tenant lấy từ tên miền cổng, lưu trong phiên; trang `/dang-nhap` cho chọn. Khu quản trị chỉ phục vụ ở `apisix-int` và bắt buộc MFA (SEC-23) | Khớp SEC-21, BR-15-003, BR-15-031. Loại một đăng ký có `kc_idp_hint`: hai realm khác nhau không liên kết danh tính |
| QĐ-15-07 | Claim `tenant` của `dh-dev` (Q15-02) | Realm `dh-dev` dùng chung; trình xác thực tùy biến của PH-12 chỉ cho đăng nhập khi `tenantGrants` chứa tenant của tên miền, và đặt claim `tenant` bằng tenant đó (Q15-21) | Token nhà thầu luôn thuộc đúng một tenant mỗi phiên, khớp SEC-80 |
| QĐ-15-08 | Mật khẩu nhà thầu | `password` đi một lần từ BFF tới `portal.dev`, được chuyển nguyên cho Keycloak khi tạo người dùng bị vô hiệu, kiểu `SecretString` không vào log, không lưu CSDL. Keycloak áp chính sách SEC-22; lỗi chính sách ánh xạ ERR-15-003 | Giữ đúng FR-15-020; cổng không có kho mật khẩu |
| QĐ-15-09 | Khóa API sandbox | Khóa `dhsk_{tenant}_{base64url(32 byte)}`; lưu `key_prefix` (8 ký tự, có chỉ mục) và `key_hash = HMAC-SHA256(khóa, pepper)`, pepper theo tenant ở OpenBao; so sánh thời gian hằng số | Tra theo tiền tố rồi so băm, không quét bảng; pepper chống dò khi lộ CSDL |
| QĐ-15-10 | Kết xuất tài liệu | Máy chủ phân tích đặc tả thành mô hình thao tác (JSON) lúc đồng bộ; SPA dựng giao diện PTN-14 từ mô hình, không nhúng bộ dựng bên thứ ba có HTML thô | Khớp ADR-020, CSP chặt, NFR-15-003. Loại nhúng Swagger UI, Redoc |
| QĐ-15-11 | Markdown | Máy chủ kiểm bằng cây cú pháp CommonMark (cấm HTML thô, URL lạ) khi lưu; SPA hiển thị bằng bộ dựng không HTML thô và lọc DOMPurify lần hai | Hai lớp (BR-15-013, SEC-44) |
| QĐ-15-12 | Hạn mức | Bộ đếm cửa sổ trượt trong Valkey (script Lua nguyên tử): theo người ở `portal.try`; theo ứng dụng và tenant ở API-15-082 (áp cả lời gọi ngoài cổng) | Một chỗ đếm cho lời gọi ngoài cổng, không đếm trùng (BR-15-025) |
| QĐ-15-13 | Ghi vết lượt thử | Bảng `try_run` phân vùng theo ngày, giữ 30 ngày; kiểm toán PH-13 qua `dh-audit` outbox, riêng production và API `RESTRICTED`, `SENSITIVE` gọi đồng bộ trước khi gọi (BR-15-023) | Đạt NFR-15-016 và an toàn khi lỗi |
| QĐ-15-14 | Đồng bộ danh mục | Inbox theo mã sự kiện, mỗi `apiCode` xử lý tuần tự nhờ khóa tư vấn PostgreSQL, kéo bù theo lịch; đặc tả lấy kèm trong API-02-081 | Đủ NFR-15-004 mà không cần hàng đợi riêng |
| QĐ-15-15 | Lập lịch | Tác vụ định kỳ chạy ở `worker`, khóa bằng bảng `shedlock` trên `pg-core`, bọc `TenantContext.runAs` | Một bản chạy mỗi lượt khi nhiều pod |
| QĐ-15-16 | Ủy thác | Cổng gọi PH-02, PH-01 bằng token của chính người dùng (BFF chuyển tiếp), chỉ lưu `externalId` kèm bộ đệm trạng thái 60 giây chỉ để hiển thị (đọc lại từ PH-02, PH-01 khi mở chi tiết) | BR-15-014: không giữ bản sao quyết định |

: Quyết định thiết kế của PH-15

## 3. Cấu trúc mã nguồn

### 3.1. Ứng dụng `dh-portal` (SPA và BFF)

SPA là ứng dụng React 19 riêng, dùng `@datahub/ui` và token thiết kế của D03-05; không dùng Backstage. BFF là dự án Spring Cloud Gateway nhỏ cùng kho. Tuyến SPA theo bảng route của FRS Phụ lục A.4, đặt trong một tệp khai báo để kiểm thử so khớp.

```text
apps/dh-portal
├── src/
│   ├── routes/                # bảng route (A.4), bảo vệ theo hạng người xem
│   ├── features/
│   │   ├── catalog/           # UI-15-01…04: danh mục, tìm kiếm, chi tiết
│   │   ├── docs/              # UI-15-05: dựng mô hình thao tác (PTN-14), mẫu mã, so sánh
│   │   ├── try/               # UI-15-06: khung thử, hạn mức, lịch sử
│   │   ├── content/           # UI-15-07: hiển thị Markdown đã lọc
│   │   ├── account/           # UI-15-08, 09, 19: đăng ký, hồ sơ, nhóm, thông báo
│   │   ├── apps/              # UI-15-10…14: ứng dụng, xác thực, thống kê
│   │   ├── delegate/          # UI-15-15…17: đăng ký sử dụng, kết nạp, công bố
│   │   ├── support/           # UI-15-20, 28
│   │   └── admin/             # UI-15-21…27: chỉ nạp khi chạy ở apisix-int
│   ├── api/                   # máy khách sinh từ OpenAPI D03-04-PH15, RFC 9457
│   └── security/              # CSRF, Idempotency-Key, SecretOnce (bí mật chỉ trong bộ nhớ)
└── bff/
    ├── config/                # hai ClientRegistration: tenant-sso, dev (mục 4.15)
    ├── filters/               # TenantFromHost, CsrfToken, CspNonce, TokenRelay, RedactLog
    └── routes/                # /bff/*, /api/portal/v1/** (có hoặc không token), tệp tĩnh
```

Quy tắc giao diện (kiểm bằng ESLint và Playwright): không dùng `dangerouslySetInnerHTML`, không `localStorage` hay `sessionStorage` cho token và bí mật (NFR-15-010), chỉ gọi `/api/portal/v1` cùng gốc (`connect-src 'self'`).

### 3.2. Module `portal` trong `dh-connect`

Module `portal` là một nhóm module Spring Modulith dưới `vn.datahub.connect.portal`. FRS gọi tên theo sáu thành phần `portal-catalog`, `-content`, `-dev`, `-try`, `-mock`, `-support`; thiết kế tách thêm `delegate`, `insight`, `admin` để mỗi module có một đầu mối trách nhiệm, vẫn trong cùng DU.

```text
vn.datahub.connect.portal
├── shared/                        # ngoài các module, ai cũng được dùng
│   ├── visibility/                # ViewerClass, VisibilityPolicy, VisibilitySpec
│   ├── tenant/                    # TenantContext, host→tenant
│   ├── problem/                   # ProblemDetail ERR-15-*, bộ ánh xạ lỗi
│   ├── audit/                     # PortalAudit (bọc dh-audit), hành động A.8
│   ├── idempotency/               # IdempotencyFilter, IdempotencyRecord
│   ├── outbox/                    # OutboxWriter, OutboxPublisher, InboxGuard
│   ├── quota/                     # SlidingWindowLimiter (Valkey Lua)
│   └── settings/                  # PortalSettings đọc tham số 15.* (đệm 60 giây)
├── catalog/   { api/ internal/{sync,item,spec,search,sample,diff,topic}/ events/ }
├── content/   { api/ internal/{page,render,attachment,git,migration}/ events/ }
├── dev/       { api/ internal/{account,team,app,credential,keycloak,terms}/ events/ }
├── delegate/  { api/ internal/{subscription,onboarding,publication}/ }
├── try/       { api/ internal/{request,quota,history,collection,authorize,prod}/ events/ }
├── mock/      { api/ internal/{respond,generate,forward,resolve}/ }   # vai trò portal-sandbox
├── insight/   { api/ internal/{stats,logs,notify,inbox}/ events/ }
├── support/   { api/ internal/{ticket,question,feedback}/ events/ }
├── admin/     { api/ internal/{branding,settings,auditview,reconcile}/ }
└── web/       # @RestController theo nhóm API, cổng nội bộ API-15-082 (cổng 8081)
```

### 3.3. Quy tắc phụ thuộc

Ranh giới module được kiểm tự động trong CI theo bảng sau.

| Quy tắc | Kiểm tra | Lý do |
|---|---|---|
| Module chỉ import `api` và `events` của module khác (CC-MOD-02), `shared` ai cũng import | Spring Modulith `verify()`, ArchUnit | Ranh giới module |
| `catalog.api` công bố `CatalogQueryApi` (đọc mục theo `VisibilitySpec`) cho `try`, `content`, `insight`, `mock` | Modulith | `try` cần phiên bản, thao tác, `dataClass` |
| `dev.api` công bố `AppAccessApi` (ứng dụng, thành viên, trạng thái) cho `try`, `insight` | Modulith | Kiểm quyền thử |
| `mock` không phụ thuộc `dev`, `try`, `insight`; chỉ dùng `catalog.api` bản đọc | ArchUnit | Vai trò `portal-sandbox` không có đường tới Keycloak, PH-13 |
| Không lớp nào ngoài `dev.internal.keycloak` import thư viện Keycloak Admin | ArchUnit | Một cửa tới Keycloak, bảo vệ tiền tố `sbx-` |
| Không lớp nào ngoài `shared.outbox` gọi `KafkaTemplate.send` (CC-TX-03) | ArchUnit | Mọi sự kiện qua outbox |
| Entity JPA không ra khỏi `internal` (CC-JAVA-05); DTO ở `api` là `record` | ArchUnit | Ổn định hợp đồng |
| Không `@Query(nativeQuery = true)` ngoài `shared.visibility` và `catalog.internal.search` (đã duyệt, dùng tham số ràng buộc) | Semgrep (SEC-41) | Giữ RLS |
| Mọi `@RestController` có `@PreAuthorize` theo `PERM-15-*` hoặc ghi chú `@Public` được liệt kê | ArchUnit | Không route nào thiếu chính sách |
| Không log kiểu `SecretString`, `SecretOnce`; trường nhận bí mật có chú thích `@Classified` | ArchUnit, kiểm thử canary NFR-15-009 | Bí mật không vào log |

: Quy tắc phụ thuộc và cách kiểm

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền chia theo module; aggregate là đơn vị giữ bất biến và khóa lạc quan `version`. Sơ đồ chỉ nêu aggregate, thuộc tính chính và quan hệ (EN-15-01…18 ở FRS §4.2); cột đầy đủ ở D03-03-PH15.

```{.mermaid caption="Mô hình miền PH-15"}
classDiagram
  class CatalogApi { +apiCode +visibility +dataClass +portalPublished +sourceVersion }
  class ApiVersion { +versionNo +state +specHash }
  class SandboxProfile { +mode +backendUrl +examplePolicy +tryProduction }
  class Page { +pageCode +type +audience +status }
  class PageVersion { +versionNo +status +bodyMd +submittedBy +approvedBy }
  class DevAccount { +userId +source +status }
  class Team { +teamCode }
  class App { +appCode +ownerType +status }
  class Credential { +kind +status +keyPrefix +expiresAt }
  class TryRun { +tryId +env +result +latencyMs }
  class TryProdGrant { +apiCode +status +validUntil }
  class Ticket { +ticketCode +kind +status }
  CatalogApi "1" --> "*" ApiVersion
  ApiVersion "1" --> "0..1" SandboxProfile
  CatalogApi "1" --> "0..1" TryProdGrant
  Page "1" --> "*" PageVersion
  DevAccount "*" --> "*" Team
  Team "1" --> "*" App
  DevAccount "1" --> "*" App
  App "1" --> "*" Credential
  App "1" --> "*" TryRun
  CatalogApi "1" --> "*" Ticket
```

Bất biến chính đặt ở aggregate, không ở dịch vụ: `App` chỉ đổi trạng thái qua `suspend`, `resume`, `archive`, `restore` và từ chối cấp `Credential` khi không `ACTIVE` (BR-15-010); `Credential` không có phương thức đọc bí mật; `PageVersion.approve(actor)` từ chối khi `actor` trùng người soạn, người sửa gần nhất hoặc người gửi (BR-15-012); `TryProdGrant.approve(actor)` từ chối khi trùng người đề xuất (BR-15-021). `CatalogApi` chỉ được ghi bởi `CatalogSync` (BR-15-001).

### 4.2. Đồng bộ danh mục (`catalog.sync`)

::: dac-ta
**Mục đích.** Giữ bản sao danh mục và đặc tả khớp PH-02 trong 30 giây, bù được khi mất sự kiện.

**Lớp chính.** `CatalogEventListener`, `CatalogSyncService`, `Puller02Client`, `SpecIngestor`, `SyncRunRecorder`.

**Đơn vị chạy.** `dh-connect` vai trò `worker`.

**FR hiện thực.** FR-15-001, 013, 061; NFR-15-004, 008.

**Giao diện vào.** Kafka EVT-02-*, lịch `15.sync.interval-seconds`, API-15-131 (đồng bộ lại).

**Phụ thuộc ra.** PH-02 API-02-081, `pg-core`, `SearchIndexer`, Valkey (vô hiệu bộ đệm).

**Dữ liệu.** `catalog_api`, `catalog_api_version`, `catalog_spec`, `sync_run`, `inbox_event`.

**Sự kiện.** EVT-15-14 khi trạng thái đồng bộ đổi (qua outbox).

**Lỗi và xử lý.** PH-02 `5xx`: lùi mũ 5, 30, 120 giây rồi `STALE`; đặc tả hỏng: giữ bản cũ, ghi `ERR-15-009` vào `sync_run`; chưa nạp xong: API đọc trả `ERR-15-008`.

**Quan sát.** `dh_portal_sync_lag_seconds`, `dh_portal_sync_runs_total`.
:::

Thuật toán một lượt: (1) `InboxGuard` ghi mã sự kiện, trùng thì bỏ (ADR-042); (2) lấy khóa tư vấn `pg_advisory_xact_lock(hash(tenant, apiCode))` để xử lý tuần tự từng API; (3) gọi API-02-081 với `updatedSince = lastSuccess - 60 giây`, `If-None-Match`; (4) với mỗi mục có `sourceVersion` lớn hơn bản đang giữ thì ghi đè trong một giao dịch, mục trong `removed[]` đặt `hidden_at`; (5) mỗi phiên bản mới hoặc đổi `contentHash` thì `SpecIngestor` phân tích (mục 4.5) và ghi `catalog_spec`, hỏng thì giữ bản cũ; (6) ghi `search_index_task` và vô hiệu khóa Valkey `cat:item:*` trong cùng giao dịch; (7) cập nhật `sync_run` và mốc `lastSuccess`. Sự kiện chỉ làm tín hiệu nên mỗi sự kiện kích hoạt cùng một lượt kéo theo `apiCode` ảnh hưởng; mất sự kiện được lượt theo lịch bù trong tối đa 5 phút. Lần nạp đầu để trống `updatedSince` và chạy phân trang `size = 100`.

### 4.3. Chính sách hiển thị (`shared.visibility`)

::: dac-ta
**Mục đích.** Một nơi duy nhất quyết định người xem nào thấy mục danh mục, đặc tả, trang nào.

**Lớp chính.** `ViewerClass`, `ViewerResolver`, `VisibilityPolicy`, `VisibilitySpec`, `SearchFilterBuilder`.

**Đơn vị chạy.** `dh-connect` mọi vai trò (thư viện nội bộ), BFF chỉ truyền ngữ cảnh.

**FR hiện thực.** FR-15-002, 005, 008, 009, 017; BR-15-002, 004, 005, 006.

**Giao diện vào.** Gọi hàm từ `catalog`, `content`, `try`, `insight`.

**Phụ thuộc ra.** Không (hàm thuần), `PortalSettings` cho `15.public.enabled`.

**Dữ liệu.** Đọc `catalog_api.visibility`, `data_class`, `portal_published`, trạng thái phiên bản.

**Sự kiện.** Không.

**Lỗi và xử lý.** Ngoài tầm trả `ERR-15-001` (`404`, cùng thân dù không tồn tại hay bị ẩn).

**Quan sát.** `dh_portal_visibility_denied_total{viewer,where}`.
:::

`ViewerResolver` suy ra hạng người xem từ token và tên miền: không token và `15.public.enabled` là `ANONYMOUS`; token realm `dh-{tenant}` cùng tenant là `TENANT_USER`, khác tenant là `OTHER_TENANT_USER`; token `dh-dev` đã duyệt là `DEV_USER`. `VisibilityPolicy.allows(viewer, item)` là hàm thuần theo bảng dưới; `VisibilitySpec` sinh cùng điều kiện thành mệnh đề SQL tham số hóa và thành bộ lọc `bool` của OpenSearch, có kiểm thử tính chất (jqwik) so ba cách cho cùng kết quả.

| Hạng | `visibility` được thấy | `dataClass` | Khác |
|---|---|---|---|
| `ANONYMOUS` | `PUBLIC` | chỉ `PUBLIC` | Chỉ khi `15.public.enabled`; không thấy backend, bên đăng ký, đầu mối cá nhân |
| `DEV_USER` | `PUBLIC`, `TENANT`, `NATIONAL` của tenant được cấp | trừ `SENSITIVE` | Không đăng ký sử dụng, không thử production |
| `TENANT_USER` | `TENANT`, `NATIONAL`, `PUBLIC` | mọi mức | Tài liệu mức nhạy cảm ghi `VIEW_SENSITIVE_DOCS` |
| `OTHER_TENANT_USER` | `NATIONAL`, `PUBLIC` | trừ `SENSITIVE` | Qua danh mục quốc gia |

: Hiển thị theo hạng người xem (khớp BR-15-004, BR-15-005, FRS A.2)

Mục được hiển thị khi `portalPublished = true` và phiên bản ở `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` (có nhãn). Dữ liệu hiển thị cũng được lọc theo hạng khi dựng DTO (`ItemView.forViewer`), nên trường nội bộ không có trong DTO của khách ẩn danh dù lớp trên quên lọc.

### 4.4. Chỉ mục tìm kiếm (`catalog.search`)

::: dac-ta
**Mục đích.** Tìm toàn văn tiếng Việt có dấu và không dấu, gợi ý, lọc theo mặt, luôn đúng hiển thị.

**Lớp chính.** `SearchIndexer`, `SearchService`, `OpenSearchEngine`, `PgFtsEngine`, `AnalyzerConfig` (bộ phân tích tiếng Việt), `ReindexJob`.

**Đơn vị chạy.** Chỉ mục: `worker`; truy vấn: `api`.

**FR hiện thực.** FR-15-005, 004, 007, 008; NFR-15-002, 018.

**Giao diện vào.** API-15-010, 011, 012, 005, 006.

**Phụ thuộc ra.** OpenSearch 2.x hoặc `pg-core` FTS, Valkey.

**Dữ liệu.** Chỉ mục `portal-{tenant}-catalog-v{n}`; cột `search_vector`, bảng `search_index_task`.

**Sự kiện.** Không.

**Lỗi và xử lý.** OpenSearch lỗi: ngắt mạch rồi chuyển `PgFtsEngine` tự động, đặt cờ trong `dh_portal_search_engine`; chỉ mục lệch: `ReindexJob` dựng lại từ bảng rồi đổi bí danh.

**Quan sát.** `dh_portal_search_duration_seconds{engine}`, `dh_portal_search_fallback_total`.
:::

Tài liệu chỉ mục gồm: `apiCode`, tên, mô tả, thẻ, lĩnh vực, chủ quản, văn bản thao tác (`summary`, đường dẫn), trường lọc (`visibility`, `dataClass`, `kind`, `state`, `authKind`, `deprecated`). Bộ phân tích: `vi_text` (tách âm tiết bằng bộ phân tích tiếng Việt, `lowercase`), `vi_folded` (thêm `asciifolding` để gõ không dấu khớp có dấu), `vi_prefix` (edge n-gram cho gợi ý). Truy vấn ghép `multi_match` có trọng số tên 4, mã 3, thẻ 2, mô tả 1 với bộ lọc từ `VisibilitySpec` (SEC-82 theo chỉ mục tenant). Trước khi trả, `SearchService` nạp lại các mục theo mã từ `catalog_api` (qua RLS) và áp `VisibilityPolicy` lần hai: mục rơi ra bị bỏ và đếm vào `dh_portal_visibility_denied_total{where="search"}` (cần bằng 0 ở vận hành bình thường). Chế độ `PG_FTS` dùng `to_tsvector('simple', unaccent(...))` và `pg_trgm` cho gợi ý, chấp nhận kém hơn về xếp hạng. Từ khóa tìm kiếm không ghi vào log ở mức giá trị đầy đủ cho khách ẩn danh (chỉ băm).

### 4.5. Kết xuất tài liệu API (`catalog.spec`, `sample`, `diff`)

::: dac-ta
**Mục đích.** Biến đặc tả OpenAPI 3.1, AsyncAPI 3.0 của PH-02 thành mô hình đọc được, mẫu mã, so sánh phiên bản và changelog.

**Lớp chính.** `SpecParser` (OpenAPI, AsyncAPI), `OperationModel`, `SampleGenerator` (sáu ngôn ngữ), `SpecDiffer`, `ChangelogBuilder`, `SpecDownloader`.

**Đơn vị chạy.** Phân tích: `worker` (lúc đồng bộ); phục vụ: `api`.

**FR hiện thực.** FR-15-009, 010, 011, 012, 013; NFR-15-003.

**Giao diện vào.** API-15-015…021, 016 (tải đặc tả).

**Phụ thuộc ra.** `catalog_spec`, Valkey (bộ đệm mô hình), PH-02 API-02-006 (mẫu gọi chuẩn).

**Dữ liệu.** `catalog_spec` (`model_json`, `content_hash`, `size_bytes`), `catalog_change_notice`.

**Sự kiện.** Không (đọc).

**Lỗi và xử lý.** Đặc tả không phân tích được: `ERR-15-009` (`422`), trang hiện thông báo thay thế; phiên bản `RETIRED`: `ERR-15-038` (`410`); tải đặc tả ghi `DOWNLOAD_SPEC`.

**Quan sát.** `dh_portal_spec_parse_failures_total`, `dh_portal_sample_requests_total{lang}`.
:::

`SpecParser` dùng bộ phân tích OpenAPI 3.1 và AsyncAPI chính thống, đặt giới hạn: kích thước ≤ 10 MB, độ sâu `$ref` ≤ 32, không tải `$ref` ngoài tiến trình (đặc tả đã gộp từ PH-02, SEC-43). Mô hình thao tác gồm đường dẫn, phương thức, tham số, lược đồ thân và phản hồi đã bung, ví dụ, `security`, nhãn `x-datahub-*`; lưu JSON nén, API-15-017 phân trang theo thao tác để dựng 300 thao tác dưới 2 giây (NFR-15-003). `SampleGenerator` sinh mẫu từ mô hình bằng mẫu chuỗi theo ngôn ngữ (`curl`, `java`, `python`, `javascript`, `csharp`, `go`); giá trị bí mật luôn là chỗ giữ `<ACCESS_TOKEN>`, `<API_KEY>`, không bao giờ là giá trị thật (BR-15-011); địa chỉ gọi lấy từ API-02-006 (LGC-APIM-017). `SpecDiffer` so hai mô hình theo thao tác, tham số, lược đồ và phân loại thay đổi `BREAKING`, `NON_BREAKING`; `ChangelogBuilder` ghép với `catalog_change_notice` (từ EVT-02-12) và lộ trình ngừng của phiên bản `DEPRECATED`.

### 4.6. CMS nội dung, nhập Git và di trú (`content`)

::: dac-ta
**Mục đích.** Quản lý trang hướng dẫn, FAQ, thông báo bằng Markdown có duyệt bốn mắt, nhập từ Git và di trú từ portal hệ cũ.

**Lớp chính.** `PageService`, `PageVersion` (aggregate), `MarkdownValidator`, `AttachmentService`, `GitSourceService`, `GitImporter`, `MigrationService`.

**Đơn vị chạy.** `api` (soạn, duyệt, hiển thị); `worker` (Git, di trú).

**FR hiện thực.** FR-15-014…018, 062; BR-15-012, 013.

**Giao diện vào.** API-15-022…040, 135…137.

**Phụ thuộc ra.** Garage, Apache Tika, ClamAV, OpenBao, kho Git, `catalog.api` (liên kết trang với API).

**Dữ liệu.** `content_page`, `content_page_version`, `content_attachment`, `content_git_source`, `content_migration`.

**Sự kiện.** EVT-15-08, EVT-15-09 (qua outbox).

**Lỗi và xử lý.** HTML thô hoặc URL lạ: `ERR-15-021`; tệp xấu: `ERR-15-024`; vi phạm bốn mắt: `ERR-15-023`; Git lỗi: `ERR-15-025`; gói sai: `ERR-15-026`; trang đã sửa: `ERR-15-006`.

**Quan sát.** `dh_portal_content_published_total`, `dh_portal_git_sync_duration_seconds`.
:::

Kiểm tra nội dung (`MarkdownValidator`) duyệt cây CommonMark: cấm nút HTML thô, ảnh có URL ngoài kho, liên kết ngoài `javascript:`/`data:`, thêm `rel="noopener nofollow"` vào liên kết ngoài, kích thước ≤ 200 KB, và trích văn bản thuần để lập chỉ mục. Lưu ở trạng thái `DRAFT`; `submit` đổi `IN_REVIEW` ghi `submitted_by`; `approve` kiểm `approver ∉ {created_by, last_edited_by, submitted_by}` ở aggregate và bằng ràng buộc `CHECK` trong CSDL, đặt `PUBLISHED`, đổi bản đang đăng cũ thành `SUPERSEDED`, ghi outbox EVT-15-08, trong một giao dịch. Ảnh: Tika kiểm kiểu theo nội dung, ClamAV quét, tên do hệ thống sinh, lưu bucket riêng, phục vụ qua `/api/portal/v1/content/attachments/{id}` (SEC-45). Logo ≤ 512 KB.

Nhập Git (`GitImporter`, Đợt 3 theo FRS nhưng thiết kế sẵn): kho chỉ HTTPS thuộc allowlist egress, mã truy cập chỉ đọc ghi một chiều vào OpenBao; thư viện JGit chạy ở `worker` với giới hạn (≤ 50 MB, ≤ 2.000 tệp, không theo symlink, chỉ `.md`, PNG, JPEG, WebP và `portal.yaml`, phân tích YAML bằng `SafeConstructor`); mỗi tệp đổi (so băm) tạo `PageVersion` `DRAFT` kèm `commit`, không bao giờ tự đăng. JGit không chạy hook hay lệnh ngoài (Q15-26). Di trú (`MigrationService`): gói ZIP ≤ 50 MB quét ClamAV, giải nén an toàn (tỉ lệ nén ≤ 100:1, SEC-45), chuyển HTML hoặc AsciiDoc sang Markdown, bỏ tài liệu Swagger gắn API, lập báo cáo xem trước, chỉ ghi `DRAFT` sau `:confirm`.

### 4.7. Tài khoản nhà phát triển (`dev.account`, `dev.keycloak`)

::: dac-ta
**Mục đích.** Vòng đời tài khoản `dh-dev` (đăng ký, xác minh thư, duyệt, khóa, vô hiệu, xóa), hồ sơ, điều khoản, nhóm; tạo tài khoản cho cán bộ SSO lần đầu đăng nhập.

**Lớp chính.** `DevAccountService`, `EmailVerificationService`, `TermsService`, `TeamService`, `KeycloakAdminGateway`, `InactivityJob`, `ErasureService`.

**Đơn vị chạy.** `api`; tác vụ ở `worker`.

**FR hiện thực.** FR-15-019…024, 058, 059; BR-15-028, 029.

**Giao diện vào.** API-15-041…054, 045, 046, 121…125.

**Phụ thuộc ra.** Keycloak Admin API (client `portal-dev`), dịch vụ gửi thư của nền tảng, `pg-core`.

**Dữ liệu.** `dev_account`, `dev_registration`, `dev_terms`, `dev_terms_acceptance`, `dev_team`, `dev_team_member`, `dev_team_invitation`.

**Sự kiện.** EVT-15-06, 07, 13.

**Lỗi và xử lý.** Thư trùng: `ERR-15-012`; mã sai: `ERR-15-013`; khóa: `ERR-15-014`; Keycloak lỗi: `ERR-15-020` rồi saga bù (mục 8.3); chủ duy nhất: `ERR-15-028`.

**Quan sát.** `dh_portal_dev_accounts{state}`, `dh_portal_keycloak_calls_total{op,result}`.
:::

Hai nguồn tài khoản dùng chung bảng `dev_account` (`source = TENANT_SSO` hoặc `DH_DEV`). Cán bộ SSO được tạo `ACTIVE` khi đăng nhập lần đầu (`UserProvisioner` lấy `sub`, thư, họ tên từ token; khóa hay vô hiệu do PH-12). Nhà thầu: đăng ký tạo bản ghi `PENDING_EMAIL`, tạo người dùng vô hiệu ở Keycloak kèm mật khẩu theo QĐ-15-08, gửi thư liên kết xác minh một lần (mã 256 bit, lưu băm, hạn 24 giờ). Xác minh xong sang `PENDING_APPROVAL` và tạo việc cho quản trị ở PH-18; duyệt (`PERM-15-dev-approve`) bật người dùng Keycloak và thêm thuộc tính `tenantGrants`. `InactivityJob` hằng ngày: cảnh báo ở 30 và 40 ngày, `DISABLED` ở 45 ngày (SEC-27); `ErasureService` thu hồi mọi thông tin xác thực, ẩn danh họ tên, thư, tổ chức, điện thoại trong cùng giao dịch rồi xóa người dùng ở Keycloak; ẩn danh tự động sau `15.dev.anonymize-after-months`.

`KeycloakAdminGateway` là cửa duy nhất tới Keycloak. Tài khoản `portal-dev` có quyền quản lý người dùng và client trong realm `dh-dev`, nhưng Keycloak không giới hạn được theo tiền tố tên client, nên cổng áp bảo vệ ở mã: mọi lệnh thay đổi client phải có `clientId` bắt đầu `sbx-{tenant}-` và thuộc tính `dh.managed-by = portal-dev`, nếu không thì từ chối trước khi gọi (SEC-20, SEC-65: bộ so cấu hình realm với Git bỏ qua client mang thuộc tính này).

### 4.8. Ứng dụng, thông tin xác thực và bí mật sandbox (`dev.app`, `dev.credential`)

::: dac-ta
**Mục đích.** Tạo ứng dụng sandbox, cấp, xoay, thu hồi thông tin xác thực, hiện bí mật đúng một lần, hiển thị tham chiếu production.

**Lớp chính.** `AppService`, `App` (aggregate), `CredentialService`, `ClientCredentialsProvisioner`, `ApiKeyProvisioner`, `SecretOnceResponse`, `CredentialExpiryJob`, `ProdCredentialRefReader`.

**Đơn vị chạy.** `api`; hết hạn, đối soát ở `worker`.

**FR hiện thực.** FR-15-025…033; BR-15-009…011, 015.

**Giao diện vào.** API-15-055…068, 126, 127.

**Phụ thuộc ra.** Keycloak (qua `KeycloakAdminGateway`), PH-01 (định danh production chỉ đọc), `pg-core`, Valkey.

**Dữ liệu.** `app`, `app_member`, `app_credential`, `prod_credential_ref`.

**Sự kiện.** EVT-15-01…05, EVT-15-13.

**Lỗi và xử lý.** Vượt số lượng: `ERR-15-015`, `ERR-15-016`; sai trạng thái: `ERR-15-017`, `ERR-15-018`; xem lại bí mật: `ERR-15-019`; Keycloak lỗi: `ERR-15-020`, bản ghi để `PROVISIONING` rồi bù.

**Quan sát.** `dh_portal_cred_issued_total{kind}`, `dh_portal_cred_old_use_total`, `dh_portal_cred_provision_failures_total`.
:::

Cấp `client_credentials` theo ba pha để không để lại client mồ côi. Pha 1 (giao dịch CSDL): kiểm quyền, trạng thái, hạn mức số lượng bằng `SELECT … FOR UPDATE` trên `app`, chèn `app_credential` với `provisioning_state = PROVISIONING` và `Idempotency-Key`. Pha 2 (ngoài giao dịch): `KeycloakAdminGateway.createClient` tạo `sbx-{tenant}-{appCode}-{n}`, bật service account, scope duy nhất `sandbox:call`, token 5 phút, `private_key_jwt` nếu có `jwks` hoặc `client_secret_basic` (chỉ sandbox, SEC-24); bí mật nhận về nằm trong biến `SecretOnce` (không in, không tuần tự hóa). Pha 3 (giao dịch): đặt `ACTIVE`, lưu `client_id`, tiền tố 8 ký tự, ghi outbox EVT-15-03 và kiểm toán `SECRET_ISSUED`. `ApiKeyProvisioner` làm tương tự không cần pha 2: sinh khóa, `key_prefix` và `key_hash` theo QĐ-15-09. Phản hồi mang `Cache-Control: no-store`; BFF không ghi thân phản hồi vào log; yêu cầu lặp với cùng `Idempotency-Key` trả lại bản ghi nhưng không có bí mật (`ERR-15-019`), người dùng phải cấp mới.

Xoay vòng: bản mới `ACTIVE`, bản cũ `ROTATING` với `grace_until = now + graceHours` (≤ 72 giờ); `CredentialExpiryJob` (hằng giờ) chuyển `ROTATING` hết thời gian chuyển tiếp và `ACTIVE` tới `expires_at` sang `EXPIRED`, xóa client Keycloak hoặc băm, nhắc ở 30, 7, 1 ngày. Thu hồi: đặt `REVOKED`, vô hiệu client, ghi outbox EVT-15-05; subscriber nội bộ xóa khóa Valkey của `forward-auth` (mục 4.10) để hiệu lực ≤ 5 giây, tối đa 60 giây theo TTL (NFR-15-007). Lưu trữ ứng dụng thu hồi mọi thông tin xác thực; khôi phục không khôi phục bí mật. Tham chiếu production (`ProdCredentialRefReader`) đọc từ PH-01 theo token người dùng, chỉ cho cán bộ thuộc tổ chức của HTTT, trả `clientId`, phương thức, 16 ký tự đầu dấu vân tay chứng thư, hạn, trạng thái; không có đường nào trả bí mật production (BR-15-015).

### 4.9. Bộ chạy sandbox `MOCK` và `BACKEND` (`mock`)

::: dac-ta
**Mục đích.** Phục vụ mọi lời gọi tới tuyến sandbox: sinh phản hồi từ ví dụ và lược đồ, hoặc chuyển tiếp tới backend thử của chủ dịch vụ.

**Lớp chính.** `SandboxDispatcher`, `MockResponder`, `ExampleSelector`, `SchemaDataGenerator`, `BackendForwarder`, `BackendCircuitBreaker`, `ProfileCache`.

**Đơn vị chạy.** `dh-connect` vai trò `portal-sandbox`.

**FR hiện thực.** FR-15-036, 037, 038; BR-15-016…018.

**Giao diện vào.** HTTP từ APISIX sau `forward-auth` (tiêu đề `X-DH-Sandbox-Mode`, `X-DH-App`, `X-DH-Try-Id`).

**Phụ thuộc ra.** Bản sao `catalog_spec`, `sandbox_profile` (CSDL chỉ đọc), backend thử qua egress, Valkey (bộ đệm hồ sơ, ngắt mạch).

**Dữ liệu.** Chỉ đọc.

**Sự kiện.** Không.

**Lỗi và xử lý.** Thiếu ví dụ và lược đồ: `ERR-15-110`; backend quá hạn: `ERR-15-108`; lỗi hoặc ngắt mạch: `ERR-15-109`; ngoài allowlist: `ERR-15-119`; thiếu cấu hình: `ERR-15-120`; phản hồi quá 1 MB: cắt, `ERR-15-123` dạng cảnh báo.

**Quan sát.** `dh_portal_mock_requests_total{mode,result}`, `dh_portal_backend_circuit_state`.
:::

`SandboxDispatcher` đọc `X-DH-Sandbox-Mode` do APISIX chèn từ phản hồi `forward-auth` (APISIX xóa mọi `X-DH-*` do client gửi, SEC-80), tải hồ sơ và thao tác từ `ProfileCache` (Valkey, TTL 60 giây, khóa theo tenant), rồi chọn nhánh. Nhánh `MOCK`: kiểm tra lại yêu cầu theo đặc tả (sai trả `400` RFC 9457 như hệ thật); chọn mã trạng thái là `2xx` đầu tiên hoặc giá trị `X-DH-Mock-Status` có trong đặc tả; chọn ví dụ `FIRST` hoặc `RANDOM` với hạt giống là băm yêu cầu để lặp lại được; thiếu ví dụ thì `SchemaDataGenerator` sinh từ lược đồ (kiểu, `enum`, `format`, `minimum`, `pattern` đơn giản, độ sâu ≤ 6); chờ `mockLatencyMs`; trả kèm `X-DH-Sandbox: mock`. Dữ liệu sinh theo dải giả của PII-15 (căn cước bắt đầu `000`, điện thoại `0900000xxx`, thư `@example.gov.vn`), để mẫu không chạm bộ luật chặn (SEC-38).

Nhánh `BACKEND`: kiểm `backendUrl` còn trong allowlist egress ngay lúc gọi (không tin kiểm lúc lưu), phân giải DNS rồi từ chối địa chỉ nội bộ, link-local, loopback (chống SSRF, SEC-16, SEC-43); chuyển tiếp qua WebClient không theo chuyển hướng với `X-DH-Sandbox: backend`, `X-DH-App`, `X-DH-Try-Id`, `traceparent`, bỏ tiêu đề người dùng không được phép; thời gian chờ `15.try.timeout-seconds`; đọc phản hồi tối đa 1 MB; ngắt mạch theo `(tenant, apiCode)` khi 5 lỗi trong 30 giây thì mở 60 giây. Quét PII-15 ở thân gửi đi đã làm ở `portal.try` (mục 4.10) vì vai trò này không có đường tới PH-13; bộ chạy chỉ đặt lại kiểm tra nhẹ cho lời gọi ngoài cổng (chặn khớp PII-15-01…06 trong thân JSON ≤ 256 KB, trả `ERR-15-106`).

### 4.10. Proxy thử API và `forward-auth` (`try`)

::: dac-ta
**Mục đích.** Nhận yêu cầu thử từ khung thử, áp mọi kiểm tra an toàn, gọi tuyến sandbox hoặc production bằng token ngắn hạn và trả kết quả đã che; trả lời `forward-auth` cho APISIX.

**Lớp chính.** `TryRequestService`, `RequestValidator`, `PiiScanner`, `TokenExchangeClient`, `GatewayClient`, `ResponseRedactor`, `SandboxAuthorizer`, `TryRunRecorder`, `TryProdService`, `CollectionService`.

**Đơn vị chạy.** `api` (cả cổng 8080 và cổng nội bộ 8081).

**FR hiện thực.** FR-15-034, 035, 038…043; BR-15-016, 019…026.

**Giao diện vào.** API-15-069…086, API-15-082 (cổng 8081, chỉ nhận danh tính SPIFFE của APISIX).

**Phụ thuộc ra.** Keycloak (token exchange), APISIX tuyến sandbox và production, PH-13 (kiểm toán đồng bộ), PH-02 (đăng ký ACTIVE), Valkey (hạn mức, bộ đệm), OpenBao (`transit`).

**Dữ liệu.** `sandbox_profile`, `try_run`, `try_collection`, `try_prod_grant`.

**Sự kiện.** EVT-15-10, EVT-15-11.

**Lỗi và xử lý.** `ERR-15-101…123` theo FRS; kiểm toán lỗi: `ERR-15-115`, từ chối thử; Keycloak lỗi: `ERR-15-117`; gateway lỗi: `ERR-15-111`.

**Quan sát.** `dh_portal_try_total{env,mode,result}`, `dh_portal_try_throttled_total{scope}`, `dh_portal_authorize_duration_seconds`.
:::

Thứ tự kiểm tra của `TryRequestService` cố định để lỗi trả về dự đoán được: (1) thành viên ứng dụng và điều khoản; (2) ứng dụng `ACTIVE`, phiên bản cho thử; (3) khớp đặc tả, cỡ thân, tiêu đề cấm (`Authorization`, `Cookie`, `Host`); (4) hạn mức theo người; (5) `PiiScanner` quét thân và tham số theo PII-15-01…06 (chặn ở `BACKEND`, cảnh báo ở `MOCK`; giá trị khớp không bao giờ được lưu hay ghi log, chỉ ghi mã luật và đường dẫn trường); (6) với production thêm các điều kiện của FR-15-043 và ghi kiểm toán đồng bộ; (7) xin token; (8) gọi gateway; (9) che phản hồi theo SEC-32 và cắt 1 MB; (10) ghi `try_run` và EVT-15-11. Thân yêu cầu và phản hồi không vào `try_run`, chỉ lưu băm, kích thước, trạng thái, độ trễ, `traceId` (BR-15-024); bộ sưu tập chỉ lưu yêu cầu mẫu ≤ 16 KB đã loại tiêu đề xác thực.

**Cơ chế `forward-auth` (API-15-082).** APISIX gọi `POST /internal/v1/sandbox/authorize` kèm tiêu đề gốc `X-Forwarded-Method`, `X-Forwarded-Uri`, `X-Forwarded-Host`, `Authorization` hoặc `X-API-Key`, `X-DH-Try-Id`. `SandboxAuthorizer` làm theo thứ tự: (1) suy `tenant` từ host, `apiCode` và `versionNo` từ đường dẫn; (2) xác định thông tin xác thực: với token, đọc `azp` (client `sbx-…`) hoặc xác nhận `portal-try`, tra `app_credential` theo `client_id`; với khóa, tra `key_prefix` rồi so `key_hash`; (3) kiểm `app_credential.status ∈ {ACTIVE, ROTATING}` và `app.status = ACTIVE` (chủ tài khoản không `LOCKED`); (4) kiểm phiên bản có sandbox khác `OFF` và thao tác có trong đặc tả; (5) đếm hạn mức ứng dụng và tenant (QĐ-15-12); (6) trả `200` kèm tiêu đề `X-DH-App`, `X-DH-Tenant`, `X-DH-Sandbox-Mode`, `X-DH-Profile-Ver`, `X-RateLimit-*`, hoặc `401`, `403`, `429`, `404` với mã ERR. Kết quả (3) và (4) được đệm trong Valkey 60 giây theo `(tenant, credId)` và bị xóa chủ động khi nhận EVT-15-02, EVT-15-05 qua kênh pub/sub nội bộ. Mục tiêu p99 ≤ 25 ms khi trúng đệm; lỗi hoặc quá 300 ms thì APISIX từ chối (`allow_degradation: false`) và trả `ERR-15-111`.

Token của `portal-try`: `TokenExchangeClient` đổi token theo QĐ-15-03, đệm 4 phút theo `(appCode, userId)` trong bộ nhớ tiến trình (không Valkey, để token không nằm ngoài tiến trình). Với production, token có `aud` nhóm API thật, scope `api:{apiCode}:{planCode}`, 5 phút, `act` là người dùng, và không được đệm. `TryProdService` quản máy trạng thái `OFF`, `PENDING`, `ENABLED`, `EXPIRED` (mục 8.1); tác vụ hằng giờ chuyển `EXPIRED` và phát EVT-15-10.

### 4.11. Thống kê, nhật ký ứng dụng và thông báo (`insight`)

::: dac-ta
**Mục đích.** Cho nhà phát triển thấy số liệu, nhật ký đã che của ứng dụng mình, nhận thông báo thay đổi API và thông báo cá nhân.

**Lớp chính.** `DashboardService`, `AppStatsService`, `AppLogService`, `NoticeFanout`, `WatchService`, `InboxService`, `CredentialReminderJob`.

**Đơn vị chạy.** `api`; fanout, nhắc ở `worker`.

**FR hiện thực.** FR-15-048…052; BR-15-027.

**Giao diện vào.** API-15-097…106; Kafka EVT-02-12, EVT-15-05.

**Phụ thuộc ra.** PH-13 (scope `metrics:portal-read`, nhật ký theo `app_code`), PH-10 và dịch vụ thư của nền tảng, Valkey.

**Dữ liệu.** `notification_subscription`, `inbox_message`, `catalog_change_notice`.

**Sự kiện.** Không (tiêu thụ EVT-02-12).

**Lỗi và xử lý.** PH-13 lỗi: `ERR-15-039`, ô thống kê hiện "chưa tải được"; không có nhãn `app_code`: hạ về số liệu theo `try_run` (Q15-18).

**Quan sát.** `dh_portal_insight_ph13_duration_seconds`, `dh_portal_notice_fanout_total{channel}`.
:::

`AppStatsService` kiểm thành viên rồi truy vấn PH-13 với bộ lọc `app_code` cố định ở máy chủ (người dùng không chọn được nhãn khác), độ phân giải theo khoảng `24h`, `7d`, `30d`; kết quả đệm 60 giây theo `(appCode, khoảng)`. `AppLogService` chỉ trả trường đã che (đường dẫn, trạng thái, độ trễ, `traceId`, không thân) và chỉ trong 30 ngày. `NoticeFanout` nhận EVT-02-12 qua inbox, tra `notification_subscription` theo `apiCode` rồi ghi `inbox_message`; loại bắt buộc (BR-15-027) bỏ qua tùy chọn tắt, loại thông tin theo kênh `IN_APP`, `EMAIL`; thư chỉ chứa liên kết (FR-00-062). Thông báo giữ 90 ngày.

### 4.12. Ủy thác đăng ký sử dụng, kết nạp, công bố (`delegate`)

::: dac-ta
**Mục đích.** Cho cán bộ đầu mối gửi đăng ký sử dụng API, hồ sơ kết nạp HTTT và đề nghị công bố API từ cổng, theo dõi kết quả, không tự quyết.

**Lớp chính.** `SubscriptionDelegate`, `OnboardingDelegate`, `PublicationDelegate`, `Ph02Client`, `Ph01Client`, `DelegationRef`.

**Đơn vị chạy.** `api`.

**FR hiện thực.** FR-15-044…047; BR-15-014.

**Giao diện vào.** API-15-087…096.

**Phụ thuộc ra.** PH-02 (FR-02-046 và đăng ký API), PH-01 (biểu mẫu F-01), PH-18 (việc).

**Dữ liệu.** `delegation_ref` (loại, `external_id`, người gửi, bộ đệm trạng thái 60 giây).

**Sự kiện.** Không phát; nghe EVT-02-09, EVT-02-10, EVT-02-11 để làm mới bộ đệm.

**Lỗi và xử lý.** Không phải đầu mối: `ERR-15-032`; PH-02 lỗi: `ERR-15-030`; PH-01 lỗi: `ERR-15-031`; tài khoản `dh-dev`: `ERR-15-005`.

**Quan sát.** `dh_portal_delegate_total{kind,result}`, `dh_portal_delegate_duration_seconds{target}`.
:::

Mỗi lời gọi mang `Authorization` của chính người dùng (BFF chuyển tiếp) để PH-02, PH-01 tự kiểm quyền và ghi kiểm toán theo người thật; cổng thêm `Idempotency-Key` do `delegate` sinh từ khóa của yêu cầu gốc. `DelegationRef` chỉ lưu con trỏ, không lưu quyết định: trạng thái hiển thị luôn lấy lại từ nguồn (đệm 60 giây). Nếu PH-02 trả lỗi sau khi nhận, lời gọi lặp với cùng khóa không tạo bản ghi thứ hai ở PH-02 (lũy đẳng của FR-02-046). Kiểm tra "cán bộ đầu mối có HTTT `ACTIVE`" làm bằng truy vấn PH-01, không bằng bản sao ở cổng. Ghi kiểm toán `SUBMIT_SUBSCRIPTION`, `SUBMIT_ONBOARDING`, `SUBMIT_PUBLICATION`.

### 4.13. Hỗ trợ và phản hồi (`support`)

::: dac-ta
**Mục đích.** Chuyển câu hỏi, báo lỗi tài liệu, yêu cầu hỗ trợ tới chủ dịch vụ, theo dõi hạn phản hồi.

**Lớp chính.** `TicketService`, `QuestionService`, `FeedbackService`, `TicketSlaJob`, `SupportRouter`.

**Đơn vị chạy.** `api`; nhắc hạn ở `worker`.

**FR hiện thực.** FR-15-053, 054, 055; BR-15-030.

**Giao diện vào.** API-15-107…115.

**Phụ thuộc ra.** `catalog.api` (đầu mối của dịch vụ), `insight.api` (thông báo), PH-10 (EVT-15-12).

**Dữ liệu.** `support_ticket`, `support_message`, `support_feedback`.

**Sự kiện.** EVT-15-12.

**Lỗi và xử lý.** Gửi quá nhiều: `ERR-15-037`; phiếu đã đóng: `ERR-15-029`; ngoài tầm: `ERR-15-001`.

**Quan sát.** `dh_portal_ticket_open{kind}`, `dh_portal_ticket_overdue_total`.
:::

Nội dung hỏi đáp và phiếu là văn bản thuần (≤ 2.000 và 4.000 ký tự), hiển thị thoát ký tự, không Markdown. `SupportRouter` chọn người nhận theo đầu mối chủ dịch vụ ở bản sao danh mục (không lộ đầu mối cá nhân cho khách ẩn danh). `TicketSlaJob` mỗi giờ nhắc phiếu quá `15.support.sla-hours` và báo quản trị. Giới hạn gửi bằng `SlidingWindowLimiter` (10 phiếu mỗi giờ, giả định). Không tích hợp ITSM ở Đợt 2 (Q15-15).

### 4.14. Quản trị cổng (`admin`)

::: dac-ta
**Mục đích.** Cấu hình nhận diện và tham số, xem nhật ký truy cập và thử, chạy đồng bộ lại, đối soát với PH-02.

**Lớp chính.** `BrandingService`, `SettingsService`, `AuditViewService`, `UsageReportService`, `ReconcileService`.

**Đơn vị chạy.** `api` (chỉ route ở `apisix-int`); đối soát ở `worker`.

**FR hiện thực.** FR-15-056, 057, 060, 061; BR-15-031, 032.

**Giao diện vào.** API-15-116…120, 128…134.

**Phụ thuộc ra.** PH-18 (tham số `15.*`), PH-13 (nhật ký, báo cáo), PH-02, Garage.

**Dữ liệu.** `portal_setting`, `sync_run`, `reconciliation_report`.

**Sự kiện.** EVT-15-14.

**Lỗi và xử lý.** Tham số ngoài miền: `ERR-15-034`; nhận diện sai: `ERR-15-033`; đang chạy: `ERR-15-035`; ngoài mạng quản trị: `ERR-15-036`; PH-13 lỗi: `ERR-15-039`.

**Quan sát.** `dh_portal_admin_changes_total{kind}`, `dh_portal_reconcile_diff_total`.
:::

Nhận diện chỉ gồm tên, logo, liên kết, chân trang, lời chào (BR-15-032): máy chủ từ chối mọi khóa khác và SPA không nạp màu, phông, token từ cấu hình. Tham số `15.*` ghi vào PH-18 qua `ParameterApi` (cổng không có kho tham số riêng, `portal_setting` chỉ giữ nhận diện và hạn mức riêng từng ứng dụng); kiểm miền ở máy chủ trước khi ghi. Đối soát so hàng `catalog_api` với API-02-081 đầy đủ, báo mục lệch (thừa, thiếu, `sourceVersion` khác) và chỉ sửa khi người dùng bấm "Đồng bộ lại". Quyền `PERM-15-audit-read` giữ nhật ký ở chế độ đọc; xuất nhật ký ghi `EXPORT_AUDIT` và chạy bất đồng bộ.

### 4.15. SPA `dh-portal` và BFF

::: dac-ta
**Mục đích.** Phục vụ giao diện, giữ phiên và token ở máy chủ, đặt tiêu đề bảo mật, chuyển yêu cầu tới `dh-connect` qua APISIX.

**Lớp chính.** `TenantFromHostFilter`, `OidcLoginController` (hai đăng ký), `SessionStore` (Valkey), `TokenRelayFilter`, `CsrfFilter`, `CspNonceFilter`, `RedactingLogFilter`.

**Đơn vị chạy.** `dh-gateway` (BFF, Z2), `dh-control` (SPA tĩnh).

**FR hiện thực.** FR-15-019, 021, 008; NFR-15-001, 010, 011, 014, 018.

**Giao diện vào.** Đường dẫn giao diện (A.4), `/bff/dang-nhap`, `/bff/dang-xuat`, `/api/portal/v1/**`.

**Phụ thuộc ra.** Keycloak (OIDC Code + PKCE `S256`), Valkey, APISIX.

**Dữ liệu.** Phiên trong Valkey, không CSDL.

**Sự kiện.** Không.

**Lỗi và xử lý.** Phiên hết hạn: `ERR-15-004`, SPA điều hướng đăng nhập giữ lại đường dẫn; Keycloak lỗi: trang công khai vẫn phục vụ (NFR-15-008).

**Quan sát.** `dh_portal_bff_sessions`, `dh_portal_bff_login_failures_total{realm}`, `dh_portal_csp_reports_total`.
:::

Phiên BFF: nhàn rỗi 15 phút (cấu hình 5 đến 15), tối đa 10 giờ, tối đa 3 phiên mỗi người (quản trị 1) (SEC-29); cookie `__Host-dh-sid` (`Secure`, `HttpOnly`, `SameSite=Strict`); CSRF bằng tiêu đề `X-DH-CSRF` đồng bộ với phiên và kiểm `Origin` (SEC-44). BFF tự làm mới access token trước khi hết hạn (5 phút, SEC-25), refresh token xoay vòng, phát hiện dùng lại thì hủy phiên. Đường `/api/portal/v1/public/**` không đính token; tenant do APISIX đặt `X-DH-Tenant` từ tên miền (SEC-80). Khách ẩn danh được phục vụ cả khi Keycloak hỏng (trang công khai chỉ cần `portal-api`, Valkey). Thêm hai điều kiện cho khu quản trị: chỉ phục vụ khi yêu cầu đến từ `apisix-int`, và token phải có `amr` chứa yếu tố thứ hai (WebAuthn cho TA, CA, SEC-23), nếu không thì BFF chuyển sang step-up.

## 5. Biểu đồ tuần tự

Tám luồng dưới đây là các FR có nhiều thành phần, giao dịch hoặc điểm an toàn. Thông điệp không dùng dấu chấm phẩy theo quy ước Mermaid của bộ tài liệu.

### 5.1. Đồng bộ danh mục từ sự kiện và kéo bù (FR-15-001, 005, 013)

Luồng này giữ bản sao danh mục khớp PH-02.

```{.mermaid caption="Đồng bộ danh mục từ sự kiện và kéo bù"}
sequenceDiagram
  autonumber
  participant K as Kafka
  participant W as portal worker
  participant P as PH-02
  participant D as pg-core
  participant S as OpenSearch
  participant V as Valkey
  K->>W: EVT-02-05 version.published
  W->>D: InboxGuard ghi mã sự kiện (trùng thì bỏ)
  W->>D: khóa tư vấn theo apiCode
  W->>P: GET API-02-081 updatedSince, If-None-Match
  P-->>W: items, removed, ETag
  W->>D: ghi đè catalog_api nếu sourceVersion mới hơn
  W->>W: SpecIngestor phân tích đặc tả, hash khác thì ghi catalog_spec
  W->>D: search_index_task và outbox EVT-15-14 nếu trạng thái đổi
  W->>V: xóa khóa cat:item và cat:spec
  W->>S: SearchIndexer áp tác vụ, đổi tài liệu theo visibility
  Note over W,P: Mất sự kiện thì lượt theo lịch 15.sync.interval-seconds bù tối đa 5 phút
```

Bước 3 bảo đảm hai sự kiện cùng API không chạy song song; bước 5 chỉ ghi khi `sourceVersion` mới hơn nên sự kiện muộn hoặc trùng không làm lùi dữ liệu; chỉ mục cập nhật bằng tác vụ nên OpenSearch chết không làm hỏng đồng bộ.

### 5.2. Tự đăng ký tài khoản dh-dev và duyệt (FR-15-020, 058)

Luồng này tạo tài khoản nhà thầu qua hai cổng chặn.

```{.mermaid caption="Tự đăng ký tài khoản dh-dev và duyệt"}
sequenceDiagram
  autonumber
  actor N as Nhà thầu
  participant B as BFF
  participant A as portal api
  participant K as Keycloak dh-dev
  participant M as Dịch vụ thư
  actor T as Quản trị cổng
  N->>B: POST developer-registrations kèm mật khẩu
  B->>A: chuyển tiếp, Idempotency-Key
  A->>A: kiểm thư, tần suất IP, điều khoản
  A->>K: tạo người dùng vô hiệu kèm mật khẩu
  K-->>A: userId hoặc lỗi chính sách mật khẩu
  A->>A: dev_account PENDING_EMAIL, lưu băm mã xác minh
  A->>M: thư chứa liên kết xác minh 24 giờ
  A-->>N: 202 registrationId
  N->>A: POST verify-email kèm mã
  A->>A: PENDING_APPROVAL, outbox EVT-15-06, việc cho quản trị
  T->>A: POST dev-accounts approve
  A->>A: kiểm PERM-15-dev-approve và trạng thái
  A->>K: bật người dùng, đặt tenantGrants
  A->>A: ACTIVE, outbox EVT-15-07, kiểm toán
```

Mật khẩu chỉ tồn tại trong bộ nhớ từ bước 2 đến 5 (kiểu `SecretString`). Nếu Keycloak lỗi ở bước 4, không có bản ghi nào được tạo; nếu bước 6 lỗi sau khi Keycloak đã tạo người dùng, tác vụ đối soát (mục 8.3) xóa người dùng mồ côi chưa có `dev_account` sau 1 giờ.

### 5.3. Cấp thông tin xác thực sandbox và hiện bí mật một lần (FR-15-027, 029)

Luồng này cấp client sandbox mà cổng không giữ bí mật.

```{.mermaid caption="Cấp client_credentials sandbox và hiện bí mật một lần"}
sequenceDiagram
  autonumber
  actor D as Nhà phát triển
  participant B as BFF
  participant A as portal api
  participant G as KeycloakAdminGateway
  participant K as Keycloak dh-dev
  participant X as Outbox
  D->>B: POST apps appCode credentials
  B->>A: chuyển tiếp, Idempotency-Key
  A->>A: giao dịch 1 khóa app, kiểm số lượng, PROVISIONING
  A->>G: createClient sbx-t68-appCode-n
  G->>G: kiểm tiền tố sbx và thuộc tính managed-by
  G->>K: tạo client, service account, scope sandbox:call
  K-->>G: clientId, secret
  G-->>A: SecretOnce
  A->>A: giao dịch 2 ACTIVE, lưu tiền tố 8 ký tự
  A->>X: EVT-15-03 và kiểm toán SECRET_ISSUED
  A-->>B: 201 kèm bí mật, Cache-Control no-store
  B-->>D: hộp thoại bí mật, không đóng tới khi xác nhận đã lưu
```

Bí mật đi một chiều từ Keycloak tới trình duyệt qua bộ nhớ, không vào CSDL, Valkey, log hay outbox (NFR-15-009). Pod chết giữa bước 4 và 8 để lại bản ghi `PROVISIONING`; tác vụ đối soát xóa client không có bản ghi `ACTIVE` sau 15 phút và đánh dấu bản ghi `FAILED`.

### 5.4. Thu hồi thông tin xác thực và hiệu lực ở `forward-auth` (FR-15-031, 039)

Luồng này cho thấy thu hồi có hiệu lực nhanh ở cổng thử.

```{.mermaid caption="Thu hồi thông tin xác thực và hiệu lực ở forward-auth"}
sequenceDiagram
  autonumber
  actor D as Nhà phát triển
  participant A as portal api
  participant K as Keycloak dh-dev
  participant X as Kafka
  participant V as Valkey
  participant G as APISIX
  D->>A: POST credentials revoke
  A->>A: REVOKED trong giao dịch, outbox EVT-15-05
  A->>K: vô hiệu client
  A-->>D: 200
  X->>A: EVT-15-05 qua OutboxPublisher
  A->>V: xóa khóa auth tenant credId và publish kênh invalidate
  G->>A: forward-auth lượt kế tiếp
  A->>A: không có đệm, đọc app_credential REVOKED
  A-->>G: 403 ERR-15-018
```

Hiệu lực chặn lượt mới đạt ≤ 5 giây khi Kafka khỏe, và không quá TTL đệm 60 giây khi Kafka chậm (NFR-15-007). Token đã cấp còn sống tối đa 5 phút; nếu cần chặn tức thì cho ứng dụng bị khóa, `forward-auth` kiểm trạng thái ứng dụng chứ không chỉ chữ ký token.

### 5.5. Thử API trên sandbox chế độ MOCK (FR-15-035, 036, 039)

Luồng này là đường chính của chức năng thử API.

```{.mermaid caption="Thử API sandbox chế độ MOCK qua forward-auth"}
sequenceDiagram
  autonumber
  actor D as Nhà phát triển
  participant B as BFF
  participant T as portal try
  participant K as Keycloak dh-dev
  participant G as APISIX sandbox
  participant M as portal-sandbox
  participant A as PH-13
  D->>B: POST try requests
  B->>T: chuyển tiếp, Idempotency-Key
  T->>T: kiểm quyền, đặc tả, hạn mức người, PiiScanner
  T->>K: token exchange cho ứng dụng
  K-->>T: token 5 phút
  T->>G: gọi tuyến sandbox, X-DH-Try-Id
  G->>T: forward-auth cổng 8081
  T-->>G: 200 mode MOCK, X-DH-App, hạn mức còn lại
  G->>M: chuyển lời gọi kèm tiêu đề tin cậy
  M->>M: chọn mã, ví dụ, sinh từ lược đồ
  M-->>G: phản hồi, X-DH-Sandbox mock
  G-->>T: phản hồi
  T->>T: che SEC-32, cắt 1 MB
  T->>A: kiểm toán qua outbox hoặc đồng bộ
  T-->>B: tryId, trạng thái, độ trễ, thân đã che
```

Hai lần đi qua `portal try` (bước 3 và 7) là chủ ý: lần đầu là kiểm tra của khung thử, lần sau dùng chung cho cả lời gọi `curl` ngoài cổng. Hạn mức người đếm ở bước 3, ứng dụng và tenant ở bước 8 nên không đếm trùng.

### 5.6. Thử API trên production (FR-15-042, 043)

Luồng này có thêm bốn mắt và ghi kiểm toán đồng bộ.

```{.mermaid caption="Bật và thử API trên production"}
sequenceDiagram
  autonumber
  actor SV as Chủ dịch vụ
  actor CA as Người duyệt
  actor D as Cán bộ phát triển
  participant T as portal try
  participant P as PH-02
  participant A as PH-13
  participant K as Keycloak dh-realm
  participant G as APISIX production
  SV->>T: PUT try-production apiCode lý do, thời hạn
  T->>T: kiểm 15.try.prod-enabled, dataClass, PENDING
  CA->>T: POST approve
  T->>T: kiểm khác người đề xuất, ENABLED, outbox EVT-15-10
  D->>T: POST try requests environment PRODUCTION
  T->>T: ENABLED còn hạn, GET HEAD, dataClass
  T->>P: đăng ký sử dụng ACTIVE của HTTT người dùng
  P-->>T: có, phạm vi api apiCode planCode
  T->>A: ghi kiểm toán đồng bộ
  A-->>T: xác nhận ghi
  T->>K: token exchange 5 phút, aud và scope của đăng ký, act
  T->>G: gọi như một HTTT bình thường
  G-->>T: phản hồi
  T-->>D: kết quả đã che, không lưu thân
```

Nếu bước 8 không có xác nhận trong 2 giây, luồng dừng với `ERR-15-115` và không có lời gọi nào tới production (BR-15-023). Đăng ký sử dụng đọc từ PH-02 mỗi lần (đệm ≤ 30 giây).

### 5.7. Soạn, gửi duyệt và đăng trang nội dung (FR-15-014, 015)

Luồng này là đường duy nhất để nội dung được đăng.

```{.mermaid caption="Soạn, gửi duyệt và đăng trang nội dung"}
sequenceDiagram
  autonumber
  actor E as Biên tập viên
  actor R as Người duyệt
  participant C as portal content
  participant G as Garage
  participant X as Outbox
  participant I as SearchIndexer
  E->>C: PUT content pages pageCode, If-Match
  C->>C: MarkdownValidator duyệt cây cú pháp
  C->>G: lưu ảnh đã quét nếu có
  C->>C: PageVersion DRAFT
  E->>C: POST submit
  C->>C: IN_REVIEW, ghi submitted_by
  R->>C: POST approve
  C->>C: kiểm khác người soạn, người sửa, người gửi
  C->>C: PUBLISHED, bản cũ SUPERSEDED
  C->>X: EVT-15-08 và kiểm toán
  X->>I: tác vụ chỉ mục trang
  C-->>R: 200
```

Bốn mắt kiểm ở aggregate và bằng `CHECK` ở CSDL nên ghi trực tiếp vào bảng cũng không qua được; bản đang đăng vẫn hiển thị cho tới khi bản mới được duyệt.

### 5.8. Gửi đăng ký sử dụng API ủy thác cho PH-02 (FR-15-044, 045)

Luồng này cho thấy cổng chỉ ủy thác, không quyết định.

```{.mermaid caption="Gửi đăng ký sử dụng API ủy thác cho PH-02"}
sequenceDiagram
  autonumber
  actor O as Cán bộ đầu mối
  participant B as BFF
  participant D as portal delegate
  participant P1 as PH-01
  participant P2 as PH-02
  O->>B: POST subscriptions
  B->>D: chuyển tiếp kèm token người dùng
  D->>P1: HTTT của người dùng có ACTIVE không
  P1-->>D: có
  D->>P2: POST đăng ký sử dụng, Idempotency-Key, token người dùng
  P2-->>D: 201 subscriptionId, PENDING_APPROVAL
  D->>D: lưu delegation_ref, kiểm toán SUBMIT_SUBSCRIPTION
  D-->>O: 201 trạng thái từ PH-02
  P2-->>D: EVT-02-10 sau khi duyệt
  D->>D: làm mới bộ đệm trạng thái, thông báo hộp thư
```

Cổng không giữ quyết định: nếu PH-02 chậm hoặc lỗi, người dùng nhận `ERR-15-030` và có thể gửi lại cùng `Idempotency-Key` an toàn. Trạng thái luôn được đọc lại từ PH-02 khi mở chi tiết.

## 6. Đa tenant trong mã nguồn

Mọi bảng `ph15_portal` có `tenant_id` và `FORCE ROW LEVEL SECURITY` (D03-03-PH15). Tenant được xác định một lần ở biên rồi đi theo `TenantContext`, không đọc từ đường dẫn, query hay thân yêu cầu (D03-10 §6):

- **Người dùng đăng nhập:** claim `tenant` của token đã xác minh. Token `dh-dev` mang đúng tenant của tên miền (QĐ-15-07).
- **Khách ẩn danh:** APISIX đặt `X-DH-Tenant` từ tên miền cổng và xóa tiêu đề cùng tên do client gửi; `portal api` chỉ tin tiêu đề này khi đến từ danh tính SPIFFE của APISIX (SEC-80).
- **`forward-auth` và `portal-sandbox`:** tenant suy từ host `sandbox-api.{tenant}…` do APISIX chuyển, đối chiếu lại với `tenant` của `app_credential`; không khớp thì `404`.
- **Tác vụ nền:** mọi job bọc `TenantContext.runAs(tenant, …)`; vòng lặp qua tenant lấy danh sách từ PH-20.

`TenantContextFilter` đặt `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch; vai trò CSDL `portal_app`, `portal_sandbox_ro` không có `BYPASSRLS` (SEC-81). Khóa Valkey, tên chỉ mục OpenSearch, đường dẫn Garage, đường dẫn OpenBao, tên topic đều dựng bằng hàm tạo tên có tenant của thư viện chung (SEC-82). Realm dùng chung `dh-dev` là ngoại lệ có kiểm soát: người dùng thuộc nhiều tenant nhưng mỗi phiên một tenant, và ứng dụng chỉ tạo ở tenant của phiên. Tìm không thấy đối tượng của tenant khác luôn trả `404` (ERR-15-001), ca kiểm thử rò rỉ chéo tenant bắt buộc cho mỗi API (SEC-87). Nhận diện cổng và tham số `15.*` theo tenant; bảng ánh xạ tên miền cổng tới tenant do PH-20 giữ (giả định).

## 7. Bảo mật

Cổng là bề mặt tiếp xúc Internet của Datahub nên bảo mật đặt lên hàng đầu: phần lớn rủi ro (lộ bí mật, XSS, SSRF, lạm dụng sandbox, rò rỉ chéo tenant) đã có biện pháp ở D03-07; bảng dưới gắn biện pháp vào chỗ hiện thực.

| Vấn đề | Biện pháp trong thiết kế | SEC |
|---|---|---|
| Token ở trình duyệt | BFF giữ token, cookie `__Host-dh-sid`, Playwright kiểm 0 token | SEC-21, SEC-29 |
| XSS, nội dung tải lên | CSP có nonce, Markdown qua kiểm AST rồi DOMPurify, ảnh Tika và ClamAV, cấm SVG | SEC-44, SEC-45 |
| Lộ bí mật sandbox | `SecretOnce`, `no-store`, không lưu, canary `DH-CANARY-…` trong CI | SEC-24, SEC-32, SEC-33 |
| Khóa và client máy | `client_credentials` sống 5 phút, bí mật ≥ 256 bit, ≤ 180 ngày; khóa API băm HMAC | SEC-24, SEC-25 |
| Phạm vi quản trị Keycloak | `portal-dev` chỉ realm `dh-dev`, bảo vệ tiền tố `sbx-` ở mã, GitOps so cấu hình | SEC-20, SEC-65 |
| Vòng đời tài khoản | Xác minh thư, duyệt, vô hiệu 45 ngày, kích hoạt lại qua duyệt | SEC-27, SEC-22 |
| Ủy quyền | `@PreAuthorize` theo `PERM-15-*` và kiểm thành viên ứng dụng ở dịch vụ; OPA cho quyết định theo tổ chức (chủ dịch vụ ○) | SEC-26 |
| SSRF qua `backendUrl`, Git | Allowlist egress kiểm lại lúc gọi, chặn dải nội bộ, không theo chuyển hướng, đọc có giới hạn | SEC-16, SEC-43 |
| Lạm dụng sandbox, DoS | `limit-req` theo IP với đường công khai, hạn mức Valkey theo người, ứng dụng, tenant | SEC-10, SEC-86 |
| Dữ liệu cá nhân ở sandbox | PII-15 chặn và cảnh báo, dải giả, không lưu giá trị khớp | SEC-38 |
| Rò rỉ chéo tenant | RLS, `404`, kiểm thử tự động, khóa theo tenant | SEC-80, SEC-81, SEC-82, SEC-87 |
| Kiểm toán và an toàn khi lỗi | `dh-audit` đồng bộ cho production và API nhạy cảm; hành động `PORTAL_*` A.8 | SEC-60, SEC-62 |
| Khu quản trị | Chỉ `apisix-int`, MFA, phiên 1 | SEC-19, SEC-23 |
| Dữ liệu cá nhân nhà thầu | Tối thiểu, ẩn danh khi xóa, tự động sau 24 tháng | SEC-39 |
| Chống phát lại, giả mạo `forward-auth` | mTLS mesh, `AuthorizationPolicy` chỉ cho SPIFFE của APISIX, `X-DH-*` bị xóa ở biên | SEC-15 |

: Biện pháp ATTT theo vấn đề

Kiểm tra quyền thực hiện ở máy chủ, giao diện chỉ ẩn nút cho tiện. Bảng dưới là quyền theo module để `@PreAuthorize` và kiểm thử quyền soi theo.

| Module | Thao tác | Quyền và điều kiện đối tượng |
|---|---|---|
| `catalog`, `content` (đọc) | xem | Hạng người xem (mục 4.3), `PERM-02-read` cho người đăng nhập |
| `content` (ghi) | soạn, nhập Git | `PERM-15-content-write`; chủ dịch vụ chỉ trang gắn API của mình |
| `content` (duyệt) | duyệt, đăng, gỡ | `PERM-15-content-publish` và khác người soạn, sửa, gửi |
| `dev` | tạo, xoay, thu hồi, xem tham chiếu production | `PERM-15-app` và là thành viên với vai trò đủ (`OWNER`, `DEVELOPER`; `VIEWER` chỉ đọc) |
| `try` | thử | `PERM-15-try`, ứng dụng `ACTIVE`, điều khoản hiện hành; production thêm đăng ký ACTIVE và tổ chức |
| `try` (production) | đề xuất, duyệt, tắt | `PERM-15-portal-admin`, chủ dịch vụ cho API của mình; duyệt khác người đề xuất |
| `support` | xử lý phiếu | `PERM-15-support`, đối tượng thuộc tổ chức |
| `admin` | duyệt, khóa tài khoản, ứng dụng | `PERM-15-dev-approve` |
| `admin` | nhật ký, báo cáo | `PERM-15-audit-read` |
| `admin` | nhận diện, tham số, đồng bộ, đối soát, di trú | `PERM-15-portal-admin` |

: Quyền theo module (kiểm ở máy chủ)

Tài khoản máy: `portal` gọi PH-02, PH-13, PH-01 bằng token dịch vụ với scope `catalog:portal-read`, `metrics:portal-read`; APISIX gọi API-15-082 bằng mTLS. Năm quyền mới (`PERM-15-content-write`, `-content-publish`, `-support`, `-dev-approve`, `-audit-read`) và hai scope máy đã được ghi ở "Đề nghị đồng bộ" của FRS; SDD dùng theo đúng FRS.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mỗi máy trạng thái ở FRS §4.3 đến §4.6 và Phụ lục A.3 có bảng dưới; cột cuối là chỗ kiểm ở máy chủ (aggregate, sau đó ràng buộc `CHECK` hoặc khóa duy nhất ở CSDL).

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| App | (mới) | create | ACTIVE | Điều khoản, `15.app.max-per-user`, `15.app.max-per-team`, `appCode` chưa dùng |
| App | ACTIVE | suspend (`PERM-15-dev-approve`) | SUSPENDED | Lý do; thu hẹp cache forward-auth |
| App | SUSPENDED | resume | ACTIVE | `PERM-15-dev-approve` |
| App | ACTIVE, SUSPENDED | archive, hệ thống 180 ngày | ARCHIVED | Thu hồi mọi thông tin xác thực trong cùng giao dịch |
| App | ARCHIVED | restore | ACTIVE | Trong 30 ngày, chỉ chủ; không khôi phục bí mật |
| Credential | (mới) | issue | ACTIVE | App `ACTIVE`, `15.cred.max-per-app` |
| Credential | ACTIVE | rotate | ROTATING (bản mới ACTIVE) | `graceHours` ≤ 72 |
| Credential | ROTATING | hết `grace_until` | EXPIRED | Tác vụ hằng giờ |
| Credential | ACTIVE, ROTATING | revoke, archive app | REVOKED | Vai trò `OWNER`, `DEVELOPER` hoặc SO, TA |
| Credential | ACTIVE | tới `expires_at` | EXPIRED | Tác vụ hằng giờ |
| PageVersion | DRAFT | submit | IN_REVIEW | `PERM-15-content-write`, kiểm hợp lệ nội dung |
| PageVersion | IN_REVIEW | withdraw | DRAFT | Chỉ người gửi |
| PageVersion | IN_REVIEW | reject | REJECTED | `PERM-15-content-publish`, ý kiến |
| PageVersion | IN_REVIEW | approve | PUBLISHED | Bốn mắt, `CHECK approver <> created_by AND <> submitted_by` |
| PageVersion | PUBLISHED | (bản mới đăng) | SUPERSEDED | Cùng giao dịch với `approve` |
| Page | PUBLISHED | unpublish | UNPUBLISHED | `PERM-15-content-publish` |
| DevAccount | (mới) | register | PENDING_EMAIL | `15.dev.signup-enabled`, thư chưa dùng |
| DevAccount | PENDING_EMAIL | verify, quá 24 giờ | PENDING_APPROVAL, EXPIRED | Mã băm khớp, còn hạn |
| DevAccount | PENDING_APPROVAL | approve, reject | ACTIVE, REJECTED | `PERM-15-dev-approve`; bật người dùng Keycloak |
| DevAccount | ACTIVE | lock, unlock | LOCKED, ACTIVE | `PERM-15-dev-approve`; thu hồi phiên |
| DevAccount | ACTIVE | 45 ngày không hoạt động | DISABLED | Tác vụ hằng ngày (SEC-27) |
| DevAccount | DISABLED | yêu cầu kích hoạt | PENDING_APPROVAL | Phải duyệt lại |
| DevAccount | ACTIVE | request-erasure | ERASED | Xác nhận mật khẩu và cụm từ |
| TryProd | OFF | propose | PENDING | `15.try.prod-enabled`, `dataClass` ∈ {PUBLIC, INTERNAL}, `validDays` ≤ `15.try.prod-max-days` |
| TryProd | PENDING | approve, reject | ENABLED, OFF | Khác người đề xuất |
| TryProd | ENABLED | disable, hết hạn | OFF, EXPIRED | Một người có quyền đủ tắt |
| Ticket | OPEN | trả lời | ANSWERED | `PERM-15-support` |
| Ticket | ANSWERED | resolve, người gửi mở lại | RESOLVED, OPEN | |
| Ticket | RESOLVED | đóng, quá hạn | CLOSED | Hệ thống sau 7 ngày |
| Sync | IDLE | bắt đầu | RUNNING | Khóa tư vấn, `ERR-15-035` nếu đang chạy |
| Sync | RUNNING | xong, lỗi | IDLE, FAILED | |
| Sync | IDLE, FAILED | quá `15.sync.stale-seconds` | STALE | Hiện banner |

: Bảng chuyển trạng thái (khớp FRS §4.3 đến §4.6, A.3)

Mỗi aggregate có cột `version` làm khóa lạc quan; lệnh từ API mang `If-Match` (sai: `ERR-15-006`), lệnh hệ thống (hết hạn, vô hiệu) thử lại tối đa 3 lần khi xung đột rồi để lượt sau. Lệnh sai trạng thái trả `ERR-15-017`, `ERR-15-018` hoặc `ERR-15-022` theo đối tượng.

### 8.2. Outbox, inbox và lũy đẳng

**Outbox (ADR-042, CC-TX-03).** Sự kiện EVT-15-01…14 và bản ghi kiểm toán ghi vào bảng `outbox_event` cùng giao dịch với thay đổi trạng thái. `OutboxPublisher` (ở `worker`, bộ quét lô 200 ms, hoặc Debezium Outbox Router khi tenant lớn) đẩy lên Kafka với khóa phân vùng `appCode`, `pageCode` hay `apiCode`, mẫu chủ đề `{tenant}.portal.{thực-thể}.{sự-kiện}.v1`, lược đồ Avro BACKWARD ở Apicurio. Sự kiện không mang bí mật hay thân yêu cầu. Kafka ngừng không làm dừng nghiệp vụ; phát bù khi hồi phục.

**Inbox.** Sự kiện EVT-02-* vào `inbox_event` (khóa duy nhất `(tenant, event_id)`); `InboxGuard` chèn rồi xử lý trong cùng giao dịch, lặp thì bỏ. Xử lý lũy đẳng theo `sourceVersion`: sự kiện cũ hơn trạng thái đang giữ bị bỏ.

**Idempotency (ADR-041, BR-15-034).** Mọi API ghi cần `Idempotency-Key`; `IdempotencyFilter` giữ khóa `(tenant, user, method, path, key)` trong Valkey 24 giờ (`IN_PROGRESS` hoặc phản hồi đã lưu) và ghi `idempotency_record` cùng giao dịch với bản ghi nghiệp vụ. Cùng khóa khác nội dung chuẩn hóa: `ERR-15-003` (`400`); đang xử lý: `409`. Với cấp bí mật, phản hồi lưu không chứa bí mật nên lặp lại trả bản ghi và `ERR-15-019`. Xóa là xóa mềm (`deleted_at`).

### 8.3. Giao dịch với Keycloak: saga và đối soát

Hai thao tác chạm Keycloak (tạo người dùng, tạo client) không nằm được trong giao dịch CSDL, nên thiết kế dùng bản ghi trung gian (`PROVISIONING`) và đối soát thay vì giao dịch phân tán.

| Tình huống | Tác động | Xử lý |
|---|---|---|
| CSDL xong pha 1, Keycloak lỗi | Bản ghi `PROVISIONING`, không client | Trả `ERR-15-020`, bản ghi chuyển `FAILED` sau 15 phút, không tính vào hạn mức |
| Keycloak tạo xong, pod chết trước pha 3 | Client mồ côi | `ReconcileKeycloakJob` mỗi 15 phút liệt kê client `sbx-*` của tenant, xóa client không có bản ghi `ACTIVE` quá 15 phút |
| CSDL `REVOKED` nhưng Keycloak chưa vô hiệu | Client còn hiệu lực | `forward-auth` đã chặn theo CSDL; job đối soát vô hiệu client, thử lại lùi mũ |
| Người dùng Keycloak không có `dev_account` | Mồ côi | Xóa sau 1 giờ |
| `dev_account` `ERASED` nhưng người dùng còn | Dữ liệu cá nhân còn | Job xóa lặp tới khi xong, cảnh báo nếu > 24 giờ |

: Các tình huống lỗi ở saga Keycloak

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng dưới chốt giá trị mặc định cho từng lời gọi ra.

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch và dự phòng |
|---|---|---|---|
| PH-02 API-02-081 | 10 giây | 3 lần lùi mũ 5, 30, 120 giây (lượt đồng bộ) | Mở sau 5 lỗi liên tiếp, 60 giây; giữ bản sao, `STALE` |
| Keycloak Admin API | 5 giây | 2 lần 200, 400 ms (chỉ lệnh lũy đẳng) | 50% trên 10 lượt, nửa mở 30 giây; `ERR-15-020` |
| Keycloak token exchange | 3 giây | 1 lần | `ERR-15-117`; không đệm token production |
| PH-13 kiểm toán đồng bộ | 2 giây | Không | Production và API `RESTRICTED`, `SENSITIVE`: từ chối `ERR-15-115`; sandbox thường: ghi qua outbox |
| PH-13 đọc số liệu | 5 giây | 1 lần | `ERR-15-039`, ô thống kê "chưa tải được" |
| PH-02, PH-01 ủy thác | 8 giây | Chỉ khi cùng `Idempotency-Key` | `ERR-15-030`, `ERR-15-031` |
| Backend thử | `15.try.timeout-seconds` | Không | 5 lỗi trong 30 giây thì mở 60 giây (BR-15-018) |
| Gateway sandbox từ `portal-try` | 20 giây | Không | `ERR-15-111` |
| `forward-auth` từ APISIX | 300 ms | Không | `allow_degradation: false` |
| OpenSearch | 2 giây | 1 lần | Chuyển `PG_FTS`, nửa mở 30 giây |
| Kho Git, Garage, OpenBao | 15, 5, 2 giây | 2 lần | `ERR-15-025`, `ERR-15-024` |

: Thời gian chờ, thử lại, ngắt mạch

Nguyên tắc chung: chỉ thử lại lệnh lũy đẳng; lệnh đọc dùng `Retry-After` khi nhận `429` của PH-02; mọi lời gọi ra đều có chỉ số theo `target` và lan truyền `traceparent`. Lỗi hạ tầng không bao giờ lộ chi tiết nội bộ cho người dùng: ánh xạ ERR-15 rồi RFC 9457 kèm `traceId`.

### 8.5. Tác vụ nền

Các tác vụ định kỳ chạy ở `worker` như bảng sau.

| Tác vụ | Chu kỳ | Việc | FR |
|---|---|---|---|
| `CatalogPullJob` | `15.sync.interval-seconds` | Kéo bù danh mục | 001 |
| `OutboxPublisher` | 200 ms | Phát outbox | Mọi FR phát sự kiện |
| `CredentialExpiryJob` | 1 giờ | Hết hạn, kết thúc chuyển tiếp, nhắc 30, 7, 1 ngày | 030, 031 |
| `InactivityJob` | Hằng ngày | Cảnh báo, vô hiệu 45 ngày, ẩn danh 24 tháng | 024 |
| `AppArchiveJob` | Hằng ngày | Lưu trữ app 180 ngày không dùng, xóa sau 30 ngày | 026 |
| `TryProdExpiryJob` | 1 giờ | Hết hạn thử production | 042 |
| `RetentionJob` | Hằng ngày | Bỏ phân vùng `try_run` quá `15.try.history-days`, thông báo 90 ngày | NFR-15-016 |
| `ReconcileKeycloakJob` | 15 phút | Đối soát client, người dùng mồ côi | 027, 020 |
| `GitSyncJob` | `15.git.sync-interval-minutes` | Đồng bộ nguồn Git | 018 |
| `TicketSlaJob` | 1 giờ | Nhắc phiếu quá hạn | 055 |
| `ReindexJob` | Theo yêu cầu, hằng tuần kiểm lệch | Dựng lại chỉ mục, đổi bí danh | 005 |

: Tác vụ nền (chạy ở `worker`, khóa `shedlock`)

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số và cờ

Tham số `15.*` ở FRS §8.2 do PH-18 giữ, đọc qua `ParameterApi` có đệm 60 giây; thay đổi có hiệu lực không cần khởi động lại, tham số vượt trần nền tảng bị từ chối ở máy chủ (`ERR-15-034`). Cờ tính năng dùng OpenFeature (cùng nhà cung cấp với các phân hệ khác), tắt theo mặc định trừ khi ghi khác.

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `portal.search.opensearch` | `true` nếu có cụm | Tương đương `15.search.engine`; tắt thì dùng `PG_FTS` |
| `portal.try.production` | `false` | Bật chức năng thử production (đi cùng `15.try.prod-enabled`) |
| `portal.git-import` | `false` | Bật nhập Git (Đợt 3) |
| `portal.i18n.en` | `false` | Nhãn tiếng Anh (Đợt 3, Q15-14) |
| `portal.legacy-migration` | `true` | Mở di trú nội dung trong giai đoạn thay dần |
| `portal.sandbox.dedicated` | `true` | `false` cho hồ sơ nhỏ: chạy `portal-sandbox` chung pod `api` (QM-NHO) |

: Cờ tính năng của PH-15

Cấu hình triển khai (biến, không chứa bí mật): `dh.role`, địa chỉ PH-02, Keycloak, OpenSearch, Valkey (`valkey.cluster`, `key-prefix` qua hàm tạo tên), cổng quản lý riêng 9090 cho `health`, `prometheus`; bí mật đọc trực tiếp từ OpenBao bằng Spring Cloud Vault, không biến môi trường (SEC-33). Tuyến APISIX (do PH-03 quản) và client Keycloak `portal-bff`, `portal-dev`, `portal-try` là phụ thuộc cấu hình, ghi trong yêu cầu cho PH-03, PH-12.

### 9.2. Bộ đệm Valkey

Mọi khóa dựng bằng hàm tạo tên `Keys.of(tenant, "domain", …)` (SEC-82). Valkey chỉ là bộ đệm và bộ đếm: mất dữ liệu không làm sai nghiệp vụ (ngoại trừ bộ đếm hạn mức, mất thì đếm lại từ 0 và ghi cảnh báo).

| Nhóm khóa | Nội dung | TTL | Vô hiệu |
|---|---|---|---|
| `bff:sess:{sid}` | Phiên, token mã hóa (BFF) | Nhàn rỗi 15 phút, tối đa 10 giờ | Đăng xuất, khóa tài khoản, back-channel logout |
| `cat:item:{apiCode}:{viewer}` | Chi tiết dịch vụ theo hạng | 5 phút | Đồng bộ ghi (bước 7 của 5.1) |
| `cat:spec:{apiCode}:{ver}` | Mô hình thao tác | 30 phút | Đổi `content_hash` |
| `cat:list:{hash}` | Trang danh sách công khai | 60 giây | Đồng bộ ghi; chịu tải 300 lượt/giây (NFR-15-018) |
| `auth:cred:{credId}` | Kết quả `forward-auth` (app, trạng thái) | 60 giây | EVT-15-02, 05 qua kênh `portal:invalidate` |
| `rl:user:{userId}`, `rl:app:{appCode}`, `rl:tenant` | Cửa sổ trượt hạn mức (Lua) | Theo cửa sổ | Không |
| `rl:ip:{ip}` | Giới hạn khách ẩn danh | 60 giây | Không |
| `idem:{hash}` | Lũy đẳng | 24 giờ | Không |
| `sbx:profile:{apiCode}:{ver}` | Hồ sơ cho `portal-sandbox` | 60 giây | Đổi hồ sơ |
| `sbx:cb:{apiCode}` | Trạng thái ngắt mạch backend | 60 giây | Tự hết |
| `param:15` | Tham số `15.*` | 60 giây | PH-18 |
| `ph13:stats:{appCode}:{khoảng}` | Số liệu thống kê | 60 giây | Không |

: Khóa Valkey của PH-15

Khi Valkey mất: phiên BFF mất nên người dùng đăng nhập lại; `forward-auth` đọc thẳng CSDL (chậm hơn nhưng đúng) và hạn mức tạm tính cục bộ theo pod (nới hơn, có cảnh báo, giống hành vi `limit-count` ở D03-01); trang công khai phục vụ từ CSDL và bộ đệm bộ nhớ ngắn.

## 10. Quan sát

OpenTelemetry (ADR-011): log JSON qua thư viện che dữ liệu, chỉ số Prometheus, vết OTLP về Tempo; mọi tín hiệu mang nhãn `tenant` (SEC-84). `traceparent` đi từ BFF qua `portal api`, `portal-sandbox` tới backend thử; `tryId` là thuộc tính của vết.

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `dh_portal_sync_lag_seconds` | gauge | `tenant` | `CatalogSyncService` (cảnh báo > 900 giây) |
| `dh_portal_sync_runs_total` | counter | `tenant`, `kind`, `result` | `SyncRunRecorder` |
| `dh_portal_try_total` | counter | `tenant`, `env`, `mode`, `result` | `TryRequestService` |
| `dh_portal_try_throttled_total` | counter | `tenant`, `scope` (`user`, `app`, `tenant`, `ip`) | `SlidingWindowLimiter` |
| `dh_portal_authorize_duration_seconds` | histogram | `tenant`, `result` | `SandboxAuthorizer` (p99 ≤ 25 ms) |
| `dh_portal_cred_issued_total` | counter | `tenant`, `kind` | `CredentialService` |
| `dh_portal_cred_old_use_total` | counter | `tenant`, `appCode` | `SandboxAuthorizer` (bản `ROTATING`) |
| `dh_portal_visibility_denied_total` | counter | `tenant`, `viewer`, `where` | `VisibilityPolicy` |
| `dh_portal_search_duration_seconds` | histogram | `tenant`, `engine` | `SearchService` |
| `dh_portal_mock_requests_total` | counter | `tenant`, `mode`, `result` | `SandboxDispatcher` |
| `dh_portal_backend_circuit_state` | gauge (0 đóng, 1 mở) | `tenant`, `apiCode` | `BackendCircuitBreaker` |
| `dh_portal_keycloak_calls_total` | counter | `tenant`, `op`, `result` | `KeycloakAdminGateway` |
| `dh_portal_outbox_pending` | gauge | `tenant` | `OutboxPublisher` |
| `dh_portal_ticket_overdue_total` | counter | `tenant` | `TicketSlaJob` |
| `dh_portal_csp_reports_total` | counter | `tenant`, `directive` | BFF |

: Chỉ số của PH-15

Nhãn `appCode` chỉ dùng cho `dh_portal_cred_old_use_total` với giới hạn 2.000 giá trị mỗi tenant (NFR-15-012), các chỉ số còn lại không dùng nhãn cardinality cao; số liệu theo ứng dụng cho người dùng đọc từ PH-13 (Q15-18, Q15-24). Cảnh báo: lag > 900 giây, `visibility_denied_total{where="search"}` tăng, `outbox_pending` > 1.000 trong 5 phút, tỉ lệ `ERR-15-115` > 1%, `authorize_duration` p99 > 100 ms, ngắt mạch Keycloak mở. Vết: span `portal.try`, `portal.authorize`, `portal.sandbox.respond`, `portal.sync`; không ghi thân, tiêu đề xác thực, giá trị khớp PII.

## 11. Hiệu năng và vận hành

Chương này nêu định cỡ giả định, cách mở rộng và việc vận hành cần chuẩn bị.

- **Định cỡ** (GĐ-15-01, hồ sơ tỉnh vừa): `api` 3 bản sao 1 vCPU, 1,5 GiB; `worker` 2 bản sao 0,5 vCPU, 1 GiB; `portal-sandbox` 3 bản sao 1 vCPU, 1 GiB (giả định theo mục tiêu 100 lượt/giây ở NFR-15-013 và 20 ms mỗi lượt `MOCK`); BFF 2 bản sao 0,5 vCPU. Chỉ số hồ sơ nhỏ `QM-NHO` gộp vai trò theo cờ `portal.sandbox.dedicated`.
- **Mở rộng:** `api` và `portal-sandbox` không giữ trạng thái, co giãn theo CPU và độ trễ; `worker` giữ một khóa mỗi tác vụ nên thêm bản sao chỉ tăng độ sẵn sàng; OpenSearch một chỉ mục nhỏ một phân đoạn mỗi tenant (500 API, 3.000 phiên bản).
- **Đường nóng:** trang công khai và danh mục đọc từ Valkey (300 lượt/giây, NFR-15-018); `forward-auth` trúng đệm là một lượt Valkey cộng một bộ đếm Lua; truy vấn danh mục có chỉ mục `(tenant_id, visibility, state)`; danh sách luôn phân trang `co` ≤ 100.
- **Lưu giữ:** `try_run` phân vùng ngày, bỏ phân vùng sau 30 ngày; kiểm toán chuyển PH-13 (12 tháng, WORM 5 năm); phiên bản trang giữ vĩnh viễn.
- **Sẵn sàng và phục hồi:** `TPH-1`, 99,5% mỗi tháng (NFR-15-008); PH-02 hỏng phục vụ bản sao ≥ 24 giờ; PH-12 hỏng thì trang công khai và đọc tài liệu vẫn chạy nhưng không đăng nhập, không thử; DR theo ADR-034 (RTO control plane ≤ 4 giờ). Sao lưu CSDL theo CNPG (ADR-035), chỉ mục dựng lại từ CSDL.
- **Vận hành:** sổ tay D06-03 gồm: đồng bộ lại danh mục, dựng lại chỉ mục, xử lý client Keycloak mồ côi, xoay pepper khóa API, thu hồi hàng loạt thông tin xác thực khi sự cố (SEC-72).

## 12. Kiểm thử

Chiến lược kiểm thử theo ADR-038, tập trung vào hiển thị, bí mật và cách ly tenant.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Bất biến aggregate (bốn mắt, hạn mức, trạng thái), `VisibilityPolicy` theo bảng hạng, `SampleGenerator`, `SpecDiffer`, `MarkdownValidator` với bộ OWASP, `SchemaDataGenerator`, `PiiScanner` | JUnit 5, jqwik (ba cách hiển thị cho cùng kết quả) |
| Kiến trúc | Luật mục 3.3 | Spring Modulith, ArchUnit |
| Tích hợp | PostgreSQL với RLS, Valkey, OpenSearch, Keycloak, OpenBao, Garage, ClamAV | Testcontainers |
| Hợp đồng | PH-02 (API-02-081, EVT-02), Keycloak, API-15 từ OpenAPI | WireMock, Pact, Spectral, oasdiff (CI-5) |
| Bảo mật | Canary bí mật, rò rỉ chéo tenant, SSRF `backendUrl`, XSS Markdown, `forward-auth` giả mạo, token ở trình duyệt | D05-02-PH15, ZAP, Playwright |
| Chịu tải | 100 lượt/giây sandbox, 300 lượt/giây trang công khai, độ trễ đồng bộ | k6 |
| Hỗn loạn | Giết pod giữa pha cấp credential, Kafka chậm, Valkey mất, PH-13 chậm | Chaos Mesh |
| Khói mẫu mã | Sáu ngôn ngữ chạy với `portal-sandbox` | CI ban đêm |

: Kiểm thử


## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Cổng thuộc Đợt 2 (W4). Bước 1 đến 3 là đường găng vì phụ thuộc PH-02, PH-12.

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| 1 | Khung `portal`, `shared`, BFF và SPA khung, đồng bộ danh mục, hiển thị, tìm kiếm `PG_FTS` | PH-02 API-02-081, PH-12 realm |
| 2 | Hiển thị tài liệu, mẫu mã, hướng dẫn và CMS bốn mắt | Bước 1 |
| 3 | Tài khoản `dh-dev`, ứng dụng, thông tin xác thực | Client `portal-dev`, Keycloak |
| 4 | `portal-sandbox` (`MOCK`, `BACKEND`), `forward-auth`, thử sandbox, hạn mức | PH-03 tuyến, QĐ-15-02, 03 |
| 5 | Ủy thác, thống kê, thông báo, hỗ trợ, quản trị, di trú Gravitee | PH-01, PH-13 |
| 6 | Thử production, OpenSearch | PH-13 ghi đồng bộ, ATTT duyệt |
| 7 | Đợt 3: nhập Git, xuất Postman, đánh giá trang, tiếng Anh | |

: Lộ trình hiện thực

### 13.2. Rủi ro

Rủi ro chính và cách giảm thiểu như sau.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Keycloak không đủ token exchange cho `portal-try` | Cao | Dự phòng xác nhận JWS ký bằng `transit` (Q15-20) |
| Lệch hiển thị giữa SQL, chỉ mục, DTO | Cao | `VisibilitySpec` một nguồn, kiểm tra lại sau tìm kiếm, kiểm thử tính chất |
| Lạm dụng sandbox, backend thử quá tải | Trung bình | Hạn mức nhiều tầng, ngắt mạch, backend riêng thử |
| Client Keycloak mồ côi | Trung bình | `PROVISIONING`, đối soát 15 phút |
| `forward-auth` thành điểm nghẽn hoặc điểm lỗi | Trung bình | Đệm 60 giây, p99 ≤ 25 ms, nhiều bản sao, từ chối an toàn |
| Chất lượng đặc tả PH-02 kém (thiếu ví dụ) | Trung bình | Cảnh báo khi chủ dịch vụ bật `MOCK` (ERR-15-110 dạng cảnh báo) |
| Phụ thuộc bộ phân tích tiếng Việt cho OpenSearch | Thấp | `PG_FTS` làm dự phòng (Q15-22) |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q15-20:** Keycloak 26 của PH-12 có hỗ trợ đổi token (RFC 8693) kiểu "service account của client khác" không, hay phải dùng phương án dự phòng xác nhận JWS `X-DH-Try-Assertion` ký bằng khóa `transit`? Ngầm định: có token exchange chuẩn, dự phòng chưa hiện thực.

> **Câu hỏi mở Q15-21:** PH-12 có làm được trình xác thực tùy biến cho realm `dh-dev` kiểm `tenantGrants` theo tên miền và đặt claim `tenant` mỗi phiên (QĐ-15-07) không? Ngầm định: có.

> **Câu hỏi mở Q15-22:** Bộ phân tích tiếng Việt cho OpenSearch lấy từ plugin nào, có dùng được ở hồ sơ air-gapped (ADR-036) không? Ngầm định: plugin mã nguồn mở đóng gói trong ảnh; nếu không thì `PG_FTS`.

> **Câu hỏi mở Q15-23:** Vai trò `portal-sandbox` tách Deployment riêng hay gộp vào `api` ở hồ sơ nhỏ? Ngầm định: tách ở hồ sơ vừa, lớn; gộp bằng `portal.sandbox.dedicated=false` ở `QM-NHO`.

> **Câu hỏi mở Q15-24:** PH-13 có chịu được nhãn `app_code` (tối đa 2.000 giá trị mỗi tenant, nhân số API) cho số liệu theo ứng dụng không, hay cổng đọc nhật ký rồi tự tổng hợp? Ngầm định: PH-13 gắn nhãn (liên quan Q15-18).

> **Câu hỏi mở Q15-25:** PH-13 cung cấp API ghi kiểm toán đồng bộ với độ trễ p95 và độ sẵn sàng nào để thử production có thể từ chối an toàn mà không gây từ chối oan? Ngầm định: p95 ≤ 200 ms, ghi theo hợp đồng xác nhận (ack) của outbox đồng bộ.

> **Câu hỏi mở Q15-26:** Nhập Git bằng JGit chạy trong `worker` hay phải tách Job Kubernetes cách ly (SEC-54)? Ngầm định: trong `worker` với giới hạn ở mục 4.6, ATTT xác nhận.

> **Câu hỏi mở Q15-27:** Khi ẩn danh tài khoản `dh-dev`, các bản ghi kiểm toán ở PH-13 giữ `userId` hay chỉ bản băm (cân bằng giữa truy vết và Luật BVDLCN)? Ngầm định: `userId` không định danh được sau khi ẩn danh, giữ 12 tháng trực tuyến.

> **Câu hỏi mở Q15-28:** Có đăng ký mẫu khóa `dhsk_` với dịch vụ quét bí mật của nền tảng mã nguồn (GitHub, GitLab) và với gitleaks nội bộ (SEC-41) để phát hiện khóa lộ không? Ngầm định: có, thêm luật gitleaks.

> **Câu hỏi mở Q15-29:** Thư xác minh và nhắc hạn gửi qua kênh thư của nền tảng nào (PH-10, PH-18 hay SMTP riêng của tỉnh) và tên miền gửi do ai cấp? Ngầm định: kênh thư chung của PH-18.

## Phụ lục A. Bảng CSDL dự kiến của schema `ph15_portal`

Bảng sau chốt tên bảng để tập CSDL (D03-03-PH15) theo; cột đầy đủ, kiểu, DDL ở tập đó. Mọi bảng có `id`, `tenant_id`, `created_*`, `updated_*`, `version`, RLS theo `tenant_id` (ADR-003); ngoại lệ nêu ở cột ghi chú. Thực thể EN-15-nn theo FRS §4.2.

| Module | Bảng | EN-15 | Khóa duy nhất, chỉ mục chính | Ghi chú |
|---|---|---|---|---|
| catalog | `catalog_api` | 01 | `(tenant_id, api_code)`; `(tenant_id, visibility, state)` | `source_version`, `hidden_at`, `search_vector` |
| catalog | `catalog_api_version` | 01 | `(api_id, version_no)` | Trạng thái, `spec_hash` |
| catalog | `catalog_spec` | 02 | `(version_id, spec_kind)` | `model_json` nén, `content_hash` |
| catalog | `catalog_topic` | 01 | `(tenant_id, topic_code)` | Dịch vụ sự kiện (FR-15-007) |
| catalog | `catalog_change_notice` | 14 | `(tenant_id, notice_id)` | Từ EVT-02-12 |
| catalog | `sandbox_profile` | 03 | `(version_id)` | `mode`, `backend_url`, `example_policy`, `try_production`; bí mật tiêu đề ở OpenBao |
| catalog | `search_index_task` | — | `(status, created_at)` | Hàng đợi chỉ mục |
| catalog | `sync_run` | 18 | `(tenant_id, started_at)` | Cũng cho đối soát |
| catalog | `reconciliation_report` | 18 | `(tenant_id, created_at)` | Chi tiết lệch dạng `jsonb` |
| content | `content_page` | 04 | `(tenant_id, page_code)` | `audience`, `type`, `lang`, `api_code` |
| content | `content_page_version` | 05 | `(page_id, version_no)` | `body_md` ≤ 200 KB, `CHECK` bốn mắt |
| content | `content_attachment` | 04 | `(tenant_id, object_key)` | Đối tượng ở Garage, băm |
| content | `content_git_source` | 04 | `(tenant_id, repo_url, path)` | Mã truy cập ở OpenBao |
| content | `content_migration` | 04 | `(tenant_id, migration_id)` | Báo cáo xem trước |
| dev | `dev_account` | 06 | `(tenant_id, lower(email))`; `(user_id)` | `source`, `status`; ẩn danh tại chỗ |
| dev | `dev_registration` | 06 | `(registration_id)` | Băm mã xác minh, hạn 24 giờ |
| dev | `dev_terms` | 16 | `(tenant_id, terms_version)` | Nội dung và hiệu lực |
| dev | `dev_terms_acceptance` | 16 | `(user_id, terms_version)` | Thời điểm chấp nhận |
| dev | `dev_team`, `dev_team_member` | 07 | `(tenant_id, team_code)`; `(team_id, user_id)` | Vai trò nhóm |
| dev | `dev_team_invitation` | 07 | `(team_id, invitee)` | `PENDING`, hạn |
| dev | `app` | 08 | `(tenant_id, app_code)` (không dùng lại) | `owner_type`, `quota_override` |
| dev | `app_member` | 08 | `(app_id, user_id)` | `OWNER`, `DEVELOPER`, `VIEWER` |
| dev | `app_credential` | 09 | `(client_id)`; `(key_prefix)` | `provisioning_state`, `key_hash`, không có cột bí mật |
| dev | `prod_credential_ref` | 10 | `(tenant_id, system_code, client_id)` | Bản sao đọc từ PH-01, TTL |
| try | `try_run` | 11 | `(tryId)`; `(app_id, created_at)` | Phân vùng ngày, giữ 30 ngày, không thân |
| try | `try_collection`, `try_collection_item` | 12 | `(user_id, name)` | ≤ 50 bộ, ≤ 100 yêu cầu |
| try | `try_prod_grant` | 13 | `(tenant_id, api_code)` | `status`, `valid_until`, `allow_write` |
| insight | `notification_subscription` | 14 | `(user_id, api_code, channel)` | |
| insight | `inbox_message` | 14 | `(user_id, created_at)` | Giữ 90 ngày |
| delegate | `delegation_ref` | — | `(kind, external_id)` | Chỉ con trỏ và bộ đệm trạng thái |
| support | `support_ticket` | 15 | `(tenant_id, ticket_code)` | `HT-{năm}-{số}` |
| support | `support_message` | 15 | `(ticket_id, seq)` | Văn bản thuần |
| support | `support_feedback` | 15 | `(tenant_id, page_or_api, user_id)` | Đánh giá trang |
| admin | `portal_setting` | 17 | `(tenant_id)` | Nhận diện; tham số `15.*` ở PH-18 |
| shared | `outbox_event` | — | `(status, created_at)` | Sự kiện và kiểm toán |
| shared | `inbox_event` | — | `(tenant_id, event_id)` | Sự kiện EVT-02 đã xử lý |
| shared | `idempotency_record` | — | `(tenant_id, user_id, method, path, key)` | 24 giờ |
| shared | `shedlock` | — | `(name)` | Không `tenant_id`, khóa tác vụ |

: Bảng CSDL dự kiến của PH-15

Phân vùng và lưu giữ: `try_run` theo ngày (bỏ phân vùng sau `15.try.history-days`), `inbox_message` theo tháng, `outbox_event` dọn sau 7 ngày đã phát. Trường tiêu đề liên quan DLCN của nhà thầu (`dev_account.email`, `full_name`, `phone`) mã hóa trường theo ADR-032 nếu D03-03 phân loại là nhạy cảm; tìm theo thư dùng HMAC tìm kiếm (SEC-88).

## Đề nghị đồng bộ

Các đề nghị dưới đây không sửa tài liệu ngoài tập PH-15; chủ tài liệu liên quan quyết định.

| Tài liệu | Đề nghị | Lý do |
|---|---|---|
| D02-03-PH15 FRS §2.4, FR-15-037 | Ghi rõ `portal.mock` chạy ở vai trò `portal-sandbox`, đảm nhận cả `MOCK` lẫn chuyển tiếp `BACKEND` (APISIX chỉ giữ tuyến tĩnh), chốt Q15-07 theo QĐ-15-01 | Khớp thiết kế; FR-15-037 hiện viết APISIX chuyển tiếp |
| D02-03-PH15 FR-15-039 | Ghi hạn mức người đếm ở `portal.try`, hạn mức ứng dụng và tenant đếm ở API-15-082 (QĐ-15-12) | Không đếm trùng, áp cho lời gọi ngoài cổng |
| D02-03-PH15 FR-15-035, 043 | Mô tả token exchange theo QĐ-15-03 và dự phòng xác nhận JWS | Q15-06 mới là câu hỏi, SDD cần phương án |
| D02-03-PH15 §2.4 | Thêm module `delegate`, `insight`, `admin` bên cạnh sáu thành phần đã nêu | Khớp cấu trúc mã mục 3.2 |
| D03-04-PH15 (API) | API-15-082 thêm tiêu đề phản hồi `X-DH-Sandbox-Mode`, `X-DH-Profile-Ver`, `X-DH-App`, `X-DH-Tenant`, `X-RateLimit-*`; cổng nội bộ 8081 | Hợp đồng `forward-auth` (mục 4.10) |
| D03-03-PH15 (CSDL) | Dùng tên bảng ở Phụ lục A; thêm `provisioning_state` ở `app_credential`, `key_prefix`, `key_hash` | Khớp saga cấp thông tin xác thực |
| ADR (dải 075 đến 079) | Đề xuất ADR số 075 cổng tự xây trên `@datahub/ui`; có thể thêm ADR số 076 "Sandbox chạy ở vai trò riêng, `forward-auth` đóng khi lỗi" | Quyết định kiến trúc QĐ-15-01, 02 |
| D03-01 SAD §4.1 | Thêm vai trò triển khai `portal-sandbox` và `worker` của `dh-connect` cho PH-15; tuyến `apisix-int` cho khu quản trị | QĐ-15-05, QĐ-15-06 |
| PH-03 | Tuyến tĩnh sandbox kèm `forward-auth` (`allow_degradation: false`, 300 ms), `jwt-auth`, mẫu route; `apisix-int` có `/quan-tri-cong` | QĐ-15-02, BR-15-031 |
| PH-12 | Client `portal-bff`, `portal-dev`, `portal-try`; trình xác thực `tenantGrants` cho `dh-dev` (Q15-21); token exchange (Q15-20) | QĐ-15-03, QĐ-15-07 |
| PH-13 | Ghi kiểm toán đồng bộ cho cổng (Q15-25); nhãn `app_code` (Q15-24) | BR-15-023, FR-15-049 |

: Đề nghị đồng bộ của SDD PH-15

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD: 14 thành phần, 8 sơ đồ tuần tự, 16 quyết định thiết kế, bảng CSDL dự kiến, câu hỏi mở Q15-20…29 |
