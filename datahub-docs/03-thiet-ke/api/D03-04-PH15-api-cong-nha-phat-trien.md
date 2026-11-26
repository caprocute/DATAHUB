---
ma_tai_lieu: D03-04-PH15
ten: Đặc tả API và sự kiện phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect (module portal), dh-portal và BFF; đơn vị kết nối HTTT; ATTT; hội đồng thẩm định
phan_he: PH-15
mo_ta: Hợp đồng giao tiếp của PH-15 gồm 142 operation REST của module portal, một cổng nội bộ forward-auth cho gateway sandbox, 14 sự kiện EVT-15 và 10 sự kiện EVT-02 do cổng tiêu thụ, bảng mã lỗi ERR-15, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm.
tai_lieu_lien_quan: D02-03-PH15 FRS; D03-02-PH15 SDD; D03-03-PH15 CSDL; D03-06-PH15 Màn hình; D05-02-PH15 Test case
---

# D03-04-PH15 · Đặc tả API và sự kiện Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của PH-15 Cổng nhà phát triển, lớp trình bày và tự phục vụ đặt trên danh mục của PH-02. Phần máy chủ là module `portal` của `dh-connect`; giao diện `dh-portal` và BFF (Backend for Frontend, lớp trung gian giữ phiên đăng nhập) gọi nó qua một đường gốc duy nhất `/api/portal/v1`. PH-15 công bố **142 operation REST** (API-15-001…142, đúng bảng FRS §9.3 bản 0.2), chia theo mặt giao tiếp:

- **89 operation cho người dùng đăng nhập**: danh mục, tài liệu, nội dung, tài khoản, ứng dụng và thông tin xác thực sandbox, hồ sơ sandbox của dịch vụ, đăng ký và điểm vào nghiệp vụ, theo dõi, hỗ trợ.
- **8 operation ẩn danh**: 6 dưới `/public` cho cổng công khai (khi tenant bật) và 2 cho tự đăng ký tài khoản `dh-dev`.
- **11 operation thử API** dưới `/try`.
- **28 operation quản trị** (thử production, hỗ trợ, nhận diện, tham số, tài khoản dh-dev, kiểm toán, đồng bộ, di trú), chỉ từ mạng quản trị.
- **1 cổng nội bộ** `POST /internal/v1/sandbox/authorize` (API-15-082) cho plugin `forward-auth` của APISIX, chỉ nhận danh tính SPIFFE trong mesh.

Sự kiện gồm **EVT-15-01…14** do PH-15 phát qua outbox lên Kafka theo CloudEvents 1.0, và **10 sự kiện EVT-02** của PH-02 mà cổng tiêu thụ để giữ bản sao danh mục và thông báo thay đổi. Mã lỗi **ERR-15-001…040** (control plane) và **101…123** (sandbox, thử API) theo RFC 9457.

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm bằng [`ph15/tools/check_contracts.py`](ph15/tools/check_contracts.py):

- [`ph15/openapi-portal.yaml`](ph15/openapi-portal.yaml): OpenAPI 3.1, 214 lược đồ, mỗi operation có ví dụ yêu cầu (khi có thân) và ví dụ phản hồi; 191 ví dụ khớp lược đồ; mỗi mã ERR-15 có một ví dụ lỗi.
- [`ph15/asyncapi-portal.yaml`](ph15/asyncapi-portal.yaml): AsyncAPI 3.0, 24 kênh (14 phát, 10 nhận), 24 thông điệp, 48 ví dụ khớp payload và tiêu đề.

Bốn nguyên tắc hợp đồng:

1. **Cổng không cầm bí mật.** Bí mật sandbox chỉ xuất hiện đúng một lần, trong phản hồi cấp hoặc xoay (`CredentialIssued`, `readOnly`); không API hay sự kiện nào khác mang bí mật, và không API nào trả bí mật production (BR-15-015).
2. **Ủy thác, không quyết định.** Đăng ký sử dụng, kết nạp HTTT, công bố API đi qua PH-02 và PH-01 bằng danh tính người dùng; cổng không tự duyệt (BR-15-014).
3. **An toàn khi lỗi.** Thử production và thử API nhạy cảm từ chối khi không ghi được kiểm toán (ERR-15-115); `forward-auth` đóng khi không hỏi được cổng (ERR-15-111).
4. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động có `If-Match`** (BR-15-034), giống PH-04, PH-05, PH-10.

Căn cứ: FRS D02-03-PH15 §9 và Phụ lục A; SDD D03-02-PH15 §4.8…4.10, QĐ-15-02, QĐ-15-03. Dữ liệu ví dụ là giả lập, tenant T68.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả hợp đồng giao tiếp của PH-15: REST của module `portal` ở `/api/portal/v1`, cổng nội bộ `forward-auth`, sự kiện EVT-15 và các EVT-02 cổng tiêu thụ, mã lỗi ERR-15. Phạm vi không gồm lược đồ CSDL (D03-03-PH15), màn hình (D03-06-PH15) hay API của PH-02, PH-01, PH-12, PH-13 mà cổng chỉ gọi.

### 0.2. Người đọc, thuật ngữ và tài liệu tham chiếu

Người đọc: kỹ sư `portal`, `dh-portal`, BFF; kiểm thử viên; ATTT; hội đồng thẩm định (đọc Tóm tắt và §1…§6). Thuật ngữ theo FRS §1.4; thêm: BFF (lớp trung gian giữ phiên của giao diện), `forward-auth` (plugin APISIX hỏi dịch vụ ngoài trước khi chuyển tiếp), outbox và inbox (bảng giao nhận sự kiện lũy đẳng). Tham chiếu: FRS D02-03-PH15 (§9, Phụ lục A), SDD D03-02-PH15, D03-06-00 §4.17, ADR-041 (lũy đẳng), D02-08 (quyền).

### 0.3. Cấu trúc tài liệu

§1 quy ước, §2 xác thực, §3 bảng endpoint, §4 sự kiện, §5 hợp đồng ngoài, §6 mã lỗi, §7 kiểm tra CI, §8 hệ cũ, §9 câu hỏi mở, §10 đề nghị đồng bộ, §11 đặc tả từng endpoint (sinh từ OpenAPI).

## 1. Quy ước chung

Mục này chốt quy ước dùng cho mọi operation để đặc tả từng endpoint ở chương cuối không phải lặp lại. 

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/portal/v1` qua BFF của `dh-portal` (`developer.{tenant}.datahub…`); trong cụm `dh-connect-portal.dh-connect.svc:8080`. Cổng nội bộ `/internal/v1` ở cổng 8081, không qua BFF |
| Nhóm đường dẫn | `/public/...` ẩn danh; `/try/...` thử API; `/admin/...` quản trị; còn lại cần đăng nhập |
| Phiên bản | `v1` trong đường dẫn; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng; oasdiff chặn thay đổi phá vỡ trong `v1` |
| Tenant | Suy từ tên miền cổng và phiên, không bao giờ từ tham số hay thân; đối tượng của tenant khác trả `404` như không tồn tại (BR-15-034) |
| Hạng người xem | `ANONYMOUS`, `TENANT_USER`, `DEV_USER`, `OTHER_TENANT_USER` suy từ phiên BFF (Phụ lục A.2 của FRS); quyết định mức hiển thị `TENANT`, `NATIONAL`, `PUBLIC` mà mọi API danh mục áp dụng |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:submit`, `:approve`, `:rotate`, `:archive`) theo AIP-136 |
| Khóa lạc quan | `GET` đối tượng trả `ETag`; `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái bắt buộc `If-Match`, lệch trả `412` (ERR-15-006). Cột M ở §3 cho biết operation nào nhận |
| Chống trùng | `POST` tạo và hành động có tác dụng phụ nhận `Idempotency-Key` (UUID), lưu 24 giờ; cùng khóa trả lại kết quả cũ, riêng cấp thông tin xác thực trả bản ghi không có bí mật (ERR-15-019). Cột I ở §3 |
| Phân trang, lọc | `trang` (từ 1), `co` (10, 20, 50, 100; mặc định 20), `sap-xep` (`-` đầu là giảm dần); lọc `q`, `linh-vuc`, `chu-quan`, `xac-thuc`, `loai`, `trang-thai`, `da-ngung`, `tu`, `den`, `khoang` (Phụ lục A.4). Phản hồi danh sách: `items`, `page`, `size`, `totalElements` |
| Lỗi | `application/problem+json` (RFC 9457): `type = https://datahub.gov.vn/errors/{code}`, `title`, `status`, `code = ERR-15-nnn`, `detail`, `traceId`, `errors[]` (`field`, `message`, `rule`); `429` kèm `Retry-After` |
| Bộ đệm | Trang ẩn danh `Cache-Control: public, max-age=300` và `ETag`, hỗ trợ `If-None-Match` và `304`; phản hồi có bí mật `Cache-Control: no-store` |

: Quy ước chung của API PH-15

#### 1.1. Ba mặt giao tiếp và đường mạng

Cổng có ba người gọi: trình duyệt qua BFF, plugin `forward-auth` của APISIX, và các phân hệ khác ở hướng ngược lại (PH-15 gọi họ). Bảng dưới cho biết mỗi mặt đi qua đâu và xác thực bằng gì.

| Mặt | Bên gọi | Đường vào | Xác thực | Operation |
|---|---|---|---|---|
| Người dùng đăng nhập | `dh-portal` qua BFF | `apisix-ext` hoặc `apisix-int` → BFF (Z2) → `portal` (Z3) | OIDC + PKCE ở BFF; trình duyệt chỉ giữ cookie phiên, token không ra trình duyệt (SEC-21) | 103 (92 thường và 11 thử API) |
| Ẩn danh | Khách | Như trên, chỉ khi tham số công khai của tenant bật (riêng đăng ký `dh-dev` luôn mở nếu tenant cho phép) | Không; giới hạn tần suất theo IP (ERR-15-007, ERR-15-037); API-15-138 kiểm chữ ký đường dẫn thay phiên | 10 |
| Quản trị | Người có quyền quản trị | Chỉ `apisix-int` (mạng quản trị) | OIDC + PKCE; ngoài mạng quản trị trả ERR-15-036 | 28 |
| Nội bộ gateway | APISIX `forward-auth` | Trực tiếp tới cổng 8081 trong mesh | mTLS SPIFFE của APISIX; không token | 1 |

: Ba mặt giao tiếp và đường mạng

Tổng 103 + 10 + 28 + 1 = 142. Cột "Quyền" ở §3 phân loại chính xác từng operation.

### 1.2. Sơ đồ trình tự thử API qua forward-auth

Luồng thử API là chỗ ba thành phần cùng gọi nhau nên đặt ở đây để người đọc hiểu API-15-072 và API-15-082 đi cùng nhau.

```{.mermaid caption="Thử API sandbox: portal gọi gateway, gateway hỏi lại cổng"}
sequenceDiagram
  participant B as BFF dh-portal
  participant P as portal (API-15-072)
  participant K as Keycloak dh-dev
  participant G as APISIX sandbox
  participant A as portal (API-15-082)
  participant S as portal-sandbox
  B->>P: POST /try/requests (cookie phiên, Idempotency-Key)
  P->>P: kiểm quyền, điều khoản, đặc tả, hạn mức, PII
  P->>K: token exchange, aud sandbox, 5 phút
  P->>G: gọi tuyến sandbox, X-DH-Try-Id, traceparent
  G->>A: forward-auth, X-Forwarded-*, token
  A-->>G: 200 và X-DH-App, X-DH-Sandbox-Mode, X-RateLimit-*
  G->>S: chuyển tiếp yêu cầu
  S-->>P: phản hồi MOCK hoặc BACKEND
  P-->>B: 200, tryId, status, body đã che, warnings
```

Hình cho thấy cổng không giữ bí mật ứng dụng mà xin token ngắn hạn; gateway tự hỏi lại API-15-082 để áp hạn mức và kiểm ứng dụng còn hiệu lực, nên lời gọi ngoài cổng (`curl` với thông tin xác thực) cũng qua cùng bộ đếm. Mọi lỗi của `forward-auth` đóng yêu cầu và trả ERR-15-111.

## 2. Xác thực và phân quyền

PH-15 có hai kiểu người gọi: con người đi qua BFF và máy trong mesh.

### 2.1. Quyền người dùng

Quyền kiểm ở API, không ở giao diện; giao diện chỉ ẩn nút. Quyền `PERM-15-*` ánh xạ từ vai trò Keycloak theo D02-08; "Đăng nhập" nghĩa là chỉ cần phiên hợp lệ, phạm vi dữ liệu do chính sách hiển thị quyết định.

| Quyền | Vai trò điển hình | Operation (số API-15) |
|---|---|---|
| Ẩn danh | Khách (khi tenant bật công khai) | 001, 003, 004, 010, 034, 035, 045, 046, 138, 139 và các mục `/public` |
| Đăng nhập | Mọi người dùng | danh mục, tài liệu, trang, hồ sơ, điều khoản, theo dõi, hộp thông báo, hỏi đáp, phiếu hỗ trợ của chính mình |
| `PERM-15-app` | `ROLE-DEVELOPER` (●) | 049…068, 098…100, 141 (theo vai trò `OWNER`, `DEVELOPER`, `VIEWER` trên ứng dụng, BR-15-009) |
| `PERM-15-try` | `ROLE-DEVELOPER` (●) | 071…081 |
| `PERM-15-content-write` | TA, CA, SV (○) | 022…025, 026, 030…033, 038…040, 142; SV (○) còn dùng quyền này cho 069, 070, 084 theo FRS 0.2 |
| `PERM-15-content-publish` | TA, CA | 027, 028, 029 (khác người soạn, người gửi: ERR-15-023) |
| `PERM-15-support` | TA, CA, SV (○) | 114, 115 |
| `PERM-15-dev-approve` | TA, SO, PA | 121…127 |
| `PERM-15-audit-read` | TA, SO, AU, PA | 128…130 |
| `PERM-15-portal-admin` | TA, CA | 009, 069, 070, 083…086, 116…120, 131…137 (đầu mối SV ○ vào 069, 070, 084 qua `PERM-15-content-write`, theo đối tượng) |
| `PERM-02-subscribe`, `PERM-02-create`, `PERM-01-submit` | OR, SV, đầu mối (○) | 087…096: cổng kiểm lại, PH-02 và PH-01 quyết định cuối (BR-15-014) |

: Quyền người dùng theo operation

Ba lớp kiểm quyền cùng chạy: vai trò theo `PERM`, vai trò trên đối tượng (thành viên ứng dụng, chủ nhóm, đầu mối tổ chức) và mức hiển thị theo hạng người xem. Đối tượng ngoài tầm trả `404` (ERR-15-001), chỉ thiếu quyền mới trả `403` (ERR-15-005).

### 2.2. Danh tính máy và scope

Chỉ một operation nhận danh tính máy; các scope còn lại là scope cổng dùng khi gọi phân hệ khác.

| Mục | Giá trị | Ý nghĩa |
|---|---|---|
| Người gọi API-15-082 | SPIFFE của APISIX, mTLS mesh | Chỉ APISIX gọi; thời gian chờ 300 ms, `allow_degradation: false` (QĐ-15-02) |
| `catalog:portal-read` | PH-15 gọi PH-02 | Đọc danh mục gia tăng (API-02-081) |
| `metrics:portal-read` | PH-15 gọi PH-13 | Đọc chỉ số, nhật ký cho API-15-097…100, 128, 129 |
| `sandbox:call` | Client `sbx-{tenant}-{appCode}-{n}` | Scope duy nhất của thông tin xác thực sandbox; token sống 5 phút |

: Danh tính máy và scope của PH-15

## 3. Danh mục endpoint

Mỗi operation có một mã `API-15-nnn` duy nhất, đúng phương thức, đường dẫn và FR theo bảng FRS §9.3 (script đối chiếu từng dòng). Mọi đường dẫn có tiền tố `/api/portal/v1`, trừ API-15-082 có tiền tố `/internal/v1`. Đặc tả đầy đủ từng endpoint (tham số, thân, phản hồi, lỗi) ở chương cuối; ví dụ yêu cầu và phản hồi nằm trong `openapi-portal.yaml`.

### 3.1. Bảng endpoint

<!-- gen:endpoints:start -->

| Mã | Operation | FR | Quyền | I | M |
|---|---|---|---|---|---|
| API-15-001 | `GET /public/home` | 003 | Ẩn danh |  |  |
| API-15-002 | `GET /home` | 003 | Đăng nhập |  |  |
| API-15-003 | `GET /public/catalog/apis` | 002, 008 | Ẩn danh |  |  |
| API-15-004 | `GET /public/catalog/apis/{apiCode}` | 002, 008 | Ẩn danh |  |  |
| API-15-005 | `GET /catalog/apis` | 002, 004 | Đăng nhập |  |  |
| API-15-006 | `GET /catalog/facets` | 004 | Đăng nhập |  |  |
| API-15-007 | `GET /catalog/apis/{apiCode}` | 002, 006 | Đăng nhập |  |  |
| API-15-008 | `GET /catalog/apis/{apiCode}/usage` | 006 | Đăng nhập |  |  |
| API-15-009 | `GET /catalog/sync-status` | 001 | portal-admin |  |  |
| API-15-010 | `GET /public/search` | 005, 008 | Ẩn danh |  |  |
| API-15-011 | `GET /search` | 005 | Đăng nhập |  |  |
| API-15-012 | `GET /search/suggest` | 005 | Đăng nhập |  |  |
| API-15-013 | `GET /catalog/topics` | 007 | Đăng nhập |  |  |
| API-15-014 | `GET /catalog/topics/{topicCode}` | 007 | Đăng nhập |  |  |
| API-15-015 | `GET /catalog/apis/{apiCode}/versions` | 011 | Đăng nhập |  |  |
| API-15-016 | `GET /catalog/apis/{apiCode}/versions/{versionNo}/spec` | 009, 011 | Đăng nhập |  |  |
| API-15-017 | `GET /catalog/apis/{apiCode}/versions/{versionNo}/operations` | 009 | Đăng nhập |  |  |
| API-15-018 | `GET /catalog/topics/{topicCode}/events` | 010 | Đăng nhập |  |  |
| API-15-019 | `GET /catalog/apis/{apiCode}/samples` | 012 | Đăng nhập |  |  |
| API-15-020 | `GET /catalog/apis/{apiCode}/diff` | 011 | Đăng nhập |  |  |
| API-15-021 | `GET /catalog/apis/{apiCode}/changelog` | 013 | Đăng nhập |  |  |
| API-15-022 | `GET /content/pages` | 014 | content-write |  |  |
| API-15-023 | `POST /content/pages` | 014 | content-write | x |  |
| API-15-024 | `GET /content/pages/{pageCode}` | 014 | content-write |  |  |
| API-15-025 | `PUT /content/pages/{pageCode}` | 014 | content-write |  | x |
| API-15-026 | `POST /content/pages/{pageCode}:submit` | 015 | content-write | x | x |
| API-15-027 | `POST /content/pages/{pageCode}:approve` | 015 | content-publish | x | x |
| API-15-028 | `POST /content/pages/{pageCode}:reject` | 015 | content-publish | x | x |
| API-15-029 | `POST /content/pages/{pageCode}:unpublish` | 016 | content-publish | x | x |
| API-15-030 | `GET /content/pages/{pageCode}/versions` | 016 | content-write |  |  |
| API-15-031 | `GET /content/pages/{pageCode}/versions/{versionNo}` | 016 | content-write |  |  |
| API-15-032 | `POST /content/pages/{pageCode}/versions/{versionNo}:restore` | 016 | content-write | x | x |
| API-15-033 | `POST /content/attachments` | 014, 017 | content-write | x |  |
| API-15-034 | `GET /public/pages` | 017 | Ẩn danh |  |  |
| API-15-035 | `GET /public/pages/{pageCode}` | 017 | Ẩn danh |  |  |
| API-15-036 | `GET /pages` | 017 | Đăng nhập |  |  |
| API-15-037 | `GET /pages/{pageCode}` | 017 | Đăng nhập |  |  |
| API-15-038 | `GET /content/git-sources` | 018 | content-write |  |  |
| API-15-039 | `POST /content/git-sources` | 018 | content-write | x |  |
| API-15-040 | `POST /content/git-sources/{sourceId}:sync` | 018 | content-write | x |  |
| API-15-041 | `GET /me` | 021 | Đăng nhập |  |  |
| API-15-042 | `PUT /me` | 021 | Đăng nhập |  | x |
| API-15-043 | `GET /me/sessions` | 021 | Đăng nhập |  |  |
| API-15-044 | `DELETE /me/sessions/{sessionId}` | 021 | Đăng nhập |  |  |
| API-15-045 | `POST /developer-registrations` | 020 | Ẩn danh | x |  |
| API-15-046 | `POST /developer-registrations:verify-email` | 020 | Ẩn danh | x |  |
| API-15-047 | `GET /terms/current` | 023 | Đăng nhập |  |  |
| API-15-048 | `POST /terms/acceptances` | 023 | Đăng nhập | x |  |
| API-15-049 | `GET /teams` | 022 | app |  |  |
| API-15-050 | `POST /teams` | 022 | app | x |  |
| API-15-051 | `POST /teams/{teamCode}/invitations` | 022 | app | x |  |
| API-15-052 | `POST /me/invitations/{invitationId}:respond` | 022 | Đăng nhập | x |  |
| API-15-053 | `DELETE /teams/{teamCode}/members/{userId}` | 022 | app |  |  |
| API-15-054 | `POST /me:request-erasure` | 024 | Đăng nhập | x |  |
| API-15-055 | `GET /apps` | 025 | app |  |  |
| API-15-056 | `POST /apps` | 025 | app | x |  |
| API-15-057 | `GET /apps/{appCode}` | 025 | app |  |  |
| API-15-058 | `PATCH /apps/{appCode}` | 026 | app |  | x |
| API-15-059 | `POST /apps/{appCode}:archive` | 026 | app | x | x |
| API-15-060 | `POST /apps/{appCode}:restore` | 026 | app | x | x |
| API-15-061 | `GET /apps/{appCode}/credentials` | 027 | app |  |  |
| API-15-062 | `POST /apps/{appCode}/credentials` | 027, 028, 029 | app | x |  |
| API-15-063 | `POST /apps/{appCode}/credentials/{credentialId}:rotate` | 030 | app | x | x |
| API-15-064 | `POST /apps/{appCode}/credentials/{credentialId}:revoke` | 031 | app | x | x |
| API-15-065 | `GET /apps/{appCode}/prod-credentials` | 032 | app |  |  |
| API-15-066 | `GET /apps/{appCode}/members` | 033 | app |  |  |
| API-15-067 | `PUT /apps/{appCode}/members/{userId}` | 033 | app |  | x |
| API-15-068 | `DELETE /apps/{appCode}/members/{userId}` | 033 | app |  |  |
| API-15-069 | `GET /catalog/apis/{apiCode}/sandbox` | 034 | portal-admin hoặc content-write (SV ○ theo đối tượng) |  |  |
| API-15-070 | `PUT /catalog/apis/{apiCode}/sandbox` | 034 | portal-admin hoặc content-write (SV ○ theo đối tượng) |  | x |
| API-15-071 | `POST /try/requests:validate` | 038 | try |  | x |
| API-15-072 | `POST /try/requests` | 035, 036, 037, 043 | try | x |  |
| API-15-073 | `GET /try/requests/{tryId}` | 035 | try |  |  |
| API-15-074 | `GET /try/quota` | 039 | try |  |  |
| API-15-075 | `GET /try/history` | 040 | try |  |  |
| API-15-076 | `DELETE /try/history` | 040 | try |  |  |
| API-15-077 | `GET /try/collections` | 040 | try |  |  |
| API-15-078 | `POST /try/collections` | 040 | try | x |  |
| API-15-079 | `PUT /try/collections/{collectionId}` | 040 | try |  | x |
| API-15-080 | `DELETE /try/collections/{collectionId}` | 040 | try |  | x |
| API-15-081 | `GET /try/collections/{collectionId}/export` | 041 | try |  |  |
| API-15-082 | `POST /internal/v1/sandbox/authorize` | 035, 039 | mTLS mesh |  |  |
| API-15-083 | `GET /admin/try-production` | 042 | portal-admin |  |  |
| API-15-084 | `PUT /admin/try-production/{apiCode}` | 042 | portal-admin hoặc content-write (SV ○ theo đối tượng) |  | x |
| API-15-085 | `POST /admin/try-production/{apiCode}:approve` | 042 | portal-admin | x | x |
| API-15-086 | `POST /admin/try-production/{apiCode}:disable` | 042 | portal-admin | x | x |
| API-15-087 | `POST /subscriptions` | 044 | PERM-02-subscribe | x |  |
| API-15-088 | `GET /subscriptions` | 045 | PERM-02-subscribe |  |  |
| API-15-089 | `GET /subscriptions/{subscriptionId}` | 045 | PERM-02-subscribe |  |  |
| API-15-090 | `POST /subscriptions/{subscriptionId}:cancel` | 045 | PERM-02-subscribe | x |  |
| API-15-091 | `POST /onboarding/applications` | 046 | PERM-01-submit | x |  |
| API-15-092 | `GET /onboarding/applications` | 046 | PERM-01-submit |  |  |
| API-15-093 | `GET /onboarding/applications/{applicationId}` | 046 | PERM-01-submit |  |  |
| API-15-094 | `POST /publications` | 047 | PERM-02-create | x |  |
| API-15-095 | `GET /publications` | 047 | PERM-02-create |  |  |
| API-15-096 | `GET /publications/{publicationId}` | 047 | PERM-02-create |  |  |
| API-15-097 | `GET /dashboard` | 048 | Đăng nhập |  |  |
| API-15-098 | `GET /apps/{appCode}/stats` | 049 | app |  |  |
| API-15-099 | `GET /apps/{appCode}/logs` | 050 | app |  |  |
| API-15-100 | `GET /apps/{appCode}/logs/{logId}` | 050 | app |  |  |
| API-15-101 | `GET /notification-subscriptions` | 051 | Đăng nhập |  |  |
| API-15-102 | `PUT /notification-subscriptions/{apiCode}` | 051 | Đăng nhập |  | x |
| API-15-103 | `DELETE /notification-subscriptions/{apiCode}` | 051 | Đăng nhập |  |  |
| API-15-104 | `GET /inbox` | 052 | Đăng nhập |  |  |
| API-15-105 | `POST /inbox/{messageId}:read` | 052 | Đăng nhập |  |  |
| API-15-106 | `POST /inbox:read-all` | 052 | Đăng nhập |  |  |
| API-15-107 | `GET /catalog/apis/{apiCode}/questions` | 053 | Đăng nhập |  |  |
| API-15-108 | `POST /catalog/apis/{apiCode}/questions` | 053 | Đăng nhập | x |  |
| API-15-109 | `POST /feedback` | 053 | Đăng nhập | x |  |
| API-15-110 | `POST /support/tickets` | 054 | Đăng nhập | x |  |
| API-15-111 | `GET /support/tickets` | 054 | Đăng nhập |  |  |
| API-15-112 | `GET /support/tickets/{ticketCode}` | 054 | Đăng nhập |  |  |
| API-15-113 | `POST /support/tickets/{ticketCode}/messages` | 054 | Đăng nhập | x |  |
| API-15-114 | `GET /admin/support/tickets` | 055 | support |  |  |
| API-15-115 | `POST /admin/support/tickets/{ticketCode}:transition` | 055 | support | x | x |
| API-15-116 | `GET /admin/branding` | 056 | portal-admin |  |  |
| API-15-117 | `PUT /admin/branding` | 056 | portal-admin |  | x |
| API-15-118 | `POST /admin/branding/logo` | 056 | portal-admin | x |  |
| API-15-119 | `GET /admin/settings` | 057 | portal-admin |  |  |
| API-15-120 | `PUT /admin/settings` | 057 | portal-admin |  | x |
| API-15-121 | `GET /admin/dev-accounts` | 058 | dev-approve |  |  |
| API-15-122 | `POST /admin/dev-accounts/{userId}:approve` | 058 | dev-approve | x | x |
| API-15-123 | `POST /admin/dev-accounts/{userId}:reject` | 058 | dev-approve | x | x |
| API-15-124 | `POST /admin/dev-accounts/{userId}:lock` | 059 | dev-approve | x | x |
| API-15-125 | `POST /admin/dev-accounts/{userId}:unlock` | 059 | dev-approve | x | x |
| API-15-126 | `POST /admin/apps/{appCode}:suspend` | 059 | dev-approve | x | x |
| API-15-127 | `POST /admin/apps/{appCode}:resume` | 059 | dev-approve | x | x |
| API-15-128 | `GET /admin/audit` | 060 | audit-read |  |  |
| API-15-129 | `GET /admin/usage-report` | 060 | audit-read |  |  |
| API-15-130 | `POST /admin/audit:export` | 060 | audit-read | x |  |
| API-15-131 | `POST /admin/sync:run` | 061 | portal-admin | x |  |
| API-15-132 | `GET /admin/sync/runs` | 061 | portal-admin |  |  |
| API-15-133 | `POST /admin/reconciliations` | 061 | portal-admin | x |  |
| API-15-134 | `GET /admin/reconciliations/latest` | 061 | portal-admin |  |  |
| API-15-135 | `POST /admin/migrations` | 062 | portal-admin | x |  |
| API-15-136 | `GET /admin/migrations/{migrationId}` | 062 | portal-admin |  |  |
| API-15-137 | `POST /admin/migrations/{migrationId}:confirm` | 062 | portal-admin | x |  |
| API-15-138 | `GET /content/attachments/{attachmentId}` | 014, 017 | Ẩn danh |  |  |
| API-15-139 | `GET /public/branding` | 003, 056 | Ẩn danh |  |  |
| API-15-140 | `GET /inbox/unread-count` | 052 | Đăng nhập |  |  |
| API-15-141 | `GET /apps:check-code` | 025 | app |  |  |
| API-15-142 | `GET /content/pages/{pageCode}/diff` | 016 | content-write |  |  |

: Danh mục endpoint API-15 (FR: số FR-15-; Quyền: bỏ tiền tố `PERM-15-`; I: nhận `Idempotency-Key`; M: nhận `If-Match`; mã thành công ở chương 11)

<!-- gen:endpoints:end -->

### 3.2. Truy vết FR sang API

Mỗi FR của PH-15 có ít nhất một API hoặc được ghi rõ ngoại lệ dưới đây.

<!-- gen:cover:start -->

Bảng §3.1 có cột FR; đối chiếu ngược cho thấy 61 trên 62 FR của FRS có ít nhất một API trong cột đó (script `check_contracts.py` kiểm mã, phương thức, đường dẫn, FR của từng dòng). Ngoại lệ: FR-15-019 (đăng nhập SSO realm tenant) không có operation REST riêng vì thực hiện ở BFF và Keycloak (OIDC Code + PKCE, `/bff/dang-nhap`); hồ sơ sau đăng nhập đọc qua API-15-041. FR-15-002 (áp mức hiển thị theo người xem) đã có ở cột FR của API-15-003, 004, 005, 007 từ FRS 0.2.

<!-- gen:cover:end -->

### 3.3. Ví dụ tiêu biểu

Một ví dụ minh họa; toàn bộ 191 ví dụ ở `openapi-portal.yaml`.

Cấp thông tin xác thực (API-15-062: `POST /apps/app-tra-cuu-ho-tich/credentials`, `Idempotency-Key`, thân `{kind: CLIENT_CREDENTIALS, label, ttlDays: 90}`) trả bí mật đúng một lần:

```json
{ "credentialId": "7c1d9a42-5b3e-4f60-8d17-2a9c0e5f6b31", "kind": "CLIENT_CREDENTIALS", "status": "ACTIVE",
  "prefix": "q8Zk3mPa", "clientId": "sbx-t68-app-tra-cuu-ho-tich-1", "clientSecret": "sbxs_9mXqT2vLw8Rk5HfA3yNcD7bZ",
  "tokenUrl": "https://sso.datahub.example.vn/realms/dh-dev/protocol/openid-connect/token",
  "expiresAt": "2027-02-24T02:00:00Z", "createdAt": "2026-11-26T02:00:00Z" }
```

Ví dụ thử API (API-15-072), phản hồi MOCK và lỗi ERR-15-103 có `Retry-After`, nằm ở `openapi-portal.yaml`.

## 4. Danh mục sự kiện

PH-15 phát mười bốn sự kiện nghiệp vụ và tiêu thụ mười sự kiện của PH-02. Sự kiện phát ghi vào `ph15_portal.outbox_event` cùng giao dịch nghiệp vụ, Debezium đưa lên Kafka; sự kiện nhận đi qua bảng inbox để xử lý lũy đẳng theo `ce_id`. Hợp đồng máy đọc được ở `ph15/asyncapi-portal.yaml`.

### 4.1. Sự kiện của PH-15 (EVT-15-01…14) và sự kiện PH-02 được tiêu thụ

Chủ đề phát theo mẫu `{tenant}.portal.{thực-thể}.{sự-kiện}.v1`. Khóa phân cùng một đối tượng vào cùng phân vùng để giữ thứ tự theo đối tượng. Mọi sự kiện mang thêm `tenantId` và `occurredAt`; không sự kiện nào mang bí mật, thân yêu cầu hay thân phản hồi.

<!-- gen:evt:start -->

| Mã | Chủ đề | Khóa | FR phát | Bên nhận | Nội dung chính |
|---|---|---|---|---|---|
| EVT-15-01 | `{tenant}.portal.app.created.v1` | `appCode` | 025 | PH-13 | `appCode`, `ownerType`, `ownerId` |
| EVT-15-02 | `{tenant}.portal.app.state-changed.v1` | `appCode` | 026, 059 | PH-13, PH-03 | `appCode`, `from`, `to` |
| EVT-15-03 | `{tenant}.portal.credential.issued.v1` | `appCode` | 027, 028 | PH-13 | `appCode`, `credentialId`, `kind`, `expiresAt` |
| EVT-15-04 | `{tenant}.portal.credential.rotated.v1` | `appCode` | 030 | PH-13 | `appCode`, `credentialId`, `newCredentialId`, `graceUntil` |
| EVT-15-05 | `{tenant}.portal.credential.revoked.v1` | `appCode` | 031 | PH-03, PH-13 | `appCode`, `credentialId`, `reason` |
| EVT-15-06 | `{tenant}.portal.devaccount.registered.v1` | `userId` | 020 | PH-13 | `userId`, `organization` |
| EVT-15-07 | `{tenant}.portal.devaccount.state-changed.v1` | `userId` | 024, 058, 059 | PH-13 | `userId`, `from`, `to` |
| EVT-15-08 | `{tenant}.portal.content.published.v1` | `pageCode` | 015 | PH-13 | `pageCode`, `versionNo`, `audience` |
| EVT-15-09 | `{tenant}.portal.content.unpublished.v1` | `pageCode` | 016 | PH-13 | `pageCode`, `versionNo` |
| EVT-15-10 | `{tenant}.portal.try.production-state-changed.v1` | `apiCode` | 042 | PH-13 | `apiCode`, `from`, `to` |
| EVT-15-11 | `{tenant}.portal.try.executed.v1` | `appCode` | 035, 043 | PH-13 | `tryId`, `env`, `apiCode`, `result`, `latencyMs` |
| EVT-15-12 | `{tenant}.portal.support.ticket-opened.v1` | `ticketCode` | 053, 054, 055 | PH-13, PH-10 | `ticketCode`, `kind`, `status` |
| EVT-15-13 | `{tenant}.portal.team.member-changed.v1` | `userId` | 022, 033 | PH-13 | `userId`, `role`, `change` |
| EVT-15-14 | `{tenant}.portal.sync.state-changed.v1` | `tenantId` | 001, 061 | PH-13 | `from`, `to`, `lagSeconds` |

: Sự kiện EVT-15 do PH-15 phát (FR: số FR-15-)

| Mã | Chủ đề | Dùng cho | Hành vi của cổng |
|---|---|---|---|
| EVT-02-01 | `{tenant}.catalog.api.registered.v1` | FR-15-001 | API được đăng ký; kích hoạt kéo gia tăng. |
| EVT-02-02 | `{tenant}.catalog.api.updated.v1` | FR-15-001, 002 | Đổi thông tin, phân loại, mức hiển thị, chủ quản, SLA; `visibility` hoặc `portalPublished` đổi thì cổng cập nhật chỉ mục ngay. |
| EVT-02-03 | `{tenant}.catalog.api.deleted.v1` | FR-15-001 | API bị xóa mềm; cổng gỡ khỏi bản sao và chỉ mục. |
| EVT-02-05 | `{tenant}.catalog.version.published.v1` | FR-15-001, 013 | Phiên bản sang `PUBLISHED`; cổng nạp đặc tả. |
| EVT-02-06 | `{tenant}.catalog.version.state-changed.v1` | FR-15-001, 013 | Tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn; cổng hiện banner `DEPRECATED`. |
| EVT-02-08 | `{tenant}.catalog.plan.state-changed.v1` | FR-15-001, 006 | Gói đổi trạng thái hoặc khai báo; cổng cập nhật danh sách gói. |
| EVT-02-09 | `{tenant}.catalog.subscription.requested.v1` | FR-15-045 | Đăng ký chờ duyệt; cổng chỉ làm mới bộ đệm đăng ký của người dùng, không phát lại (BR-15-014). |
| EVT-02-10 | `{tenant}.catalog.subscription.activated.v1` | FR-15-043, 045 | Đăng ký được cấp phạm vi; cổng làm mới điều kiện thử production. |
| EVT-02-11 | `{tenant}.catalog.subscription.state-changed.v1` | FR-15-043, 045 | Từ chối, tạm ngừng, thu hồi, hủy, hết hạn; cổng thu hồi quyền thử production nếu cần. |
| EVT-02-12 | `{tenant}.catalog.change.notice-issued.v1` | FR-15-013, 051, 052 | Thông báo thay đổi đã phát; cổng tra người theo dõi rồi ghi hộp thông báo. |

: Sự kiện EVT-02 do PH-02 phát mà PH-15 tiêu thụ

<!-- gen:evt:end -->

### 4.2. Quy ước sự kiện

Bảng dưới gom quy ước chung của mọi sự kiện PH-15 để bên nhận hiện thực một lần.

| Mục | Quy ước |
|---|---|
| Định dạng | CloudEvents 1.0 nhị phân (`ce_*` trong tiêu đề Kafka), `ce_type = vn.datahub.portal.{thực-thể}.{sự-kiện}`, thân `application/json`; lược đồ Avro ở Apicurio |
| Tương thích | `BACKWARD`; chỉ thêm trường tùy chọn trong `v1`; bên nhận bỏ qua trường lạ |
| Lưu giữ, phân vùng | 7 ngày, 3 phân vùng, 3 bản sao (giả định theo PH-10, Q15-58) |
| Giao đúng một lần ở mức ứng dụng | Outbox cộng inbox theo `ce_id`; bên nhận bỏ qua `ce_id` đã xử lý |
| Hiệu lực chặn | EVT-15-02 và EVT-15-05 làm `forward-auth` xóa bộ đệm Valkey qua kênh pub/sub nội bộ, hiệu lực ≤ 5 giây, tối đa 60 giây theo TTL (NFR-15-007) |
| Không phát lại EVT-02-09 | Cổng chỉ làm mới bộ đệm đăng ký của người dùng (BR-15-014) |

: Quy ước sự kiện của PH-15

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-15 không có hợp đồng NDXP, NDOP hay PayGov. Quan hệ với phân hệ khác gồm cổng gọi họ (ủy thác, đọc) và họ gọi cổng (chỉ APISIX).

| Phân hệ, hệ thống | Hướng | Giao diện | Dùng cho |
|---|---|---|---|
| PH-02 | Cổng gọi | API-02-081 (`catalog:portal-read`, gia tăng `updatedSince`, `removed[]`); API-02-006 (đường dẫn sử dụng); FR-02-046 (gửi đăng ký sử dụng); đăng ký API (F-02) | Bản sao danh mục (API-15-003…021), ủy thác API-15-087…090, 094…096 |
| PH-02 | Cổng nhận | EVT-02-01, 02, 03, 05, 06, 08, 09, 10, 11, 12 | Làm mới danh mục, thông báo thay đổi, điều kiện thử production |
| PH-01 | Cổng gọi | Lược đồ biểu mẫu kết nạp (F-01); tra cứu định danh production chỉ đọc | API-15-065, 091…093 |
| PH-12 | Cổng gọi | Keycloak Admin API (client `portal-dev`, giới hạn); token exchange (client `portal-try`, RFC 8693); OPA | Tài khoản `dh-dev`, client sandbox (API-15-045…062), token thử (API-15-072) |
| PH-13 | Cổng gọi | Chỉ số, nhật ký theo `app_code` (`metrics:portal-read`); ghi kiểm toán đồng bộ | API-15-097…100, 128…130; an toàn khi lỗi ERR-15-115 |
| PH-03 | Họ gọi | `forward-auth` tới API-15-082 qua mTLS mesh | Kiểm ứng dụng, hạn mức ở tuyến sandbox |
| PH-10 | Cổng nhận, phát | Topic của PH-10 hiển thị ở API-15-013, 014, 018; nhận EVT-15-12 | Dịch vụ sự kiện và phiếu hỗ trợ cho chủ topic |
| PH-18 | Cổng gọi | Tham số `15.*` và danh sách egress cho backend thử | API-15-070, 119, 120 |
| Kho Git, ClamAV, OpenBao | Cổng gọi | HTTPS thuộc allowlist egress; quét tệp; lưu mã truy cập một chiều | API-15-033, 038…040, 135 |

: Hợp đồng của PH-15 với phân hệ khác và bên ngoài


## 6. Bảng mã lỗi ERR-15

Mọi lỗi trả `application/problem+json` với `code` là mã dưới đây. `001…040` thuộc control plane (cổng, nội dung, ứng dụng, tài khoản); `101…123` thuộc sandbox và thử API. Mã, HTTP và ý nghĩa khớp FRS §9.1; câu thông báo hiển thị cho người dùng cuối nằm ở FRS §9.1 và được tập màn hình D03-06-PH15 dùng lại, `{…}` điền lúc chạy.

### 6.1. Control plane và sandbox

<!-- gen:err:start -->

| Mã | HTTP | Ý nghĩa |
|---|---|---|
| ERR-15-001 | 404 | Không tìm thấy hoặc ngoài tầm nhìn |
| ERR-15-002 | 409 | Mã đã được dùng |
| ERR-15-003 | 400 | Dữ liệu gửi lên không hợp lệ |
| ERR-15-004 | 401 | Chưa đăng nhập hoặc phiên hết hạn |
| ERR-15-005 | 403 | Không đủ quyền |
| ERR-15-006 | 412 | Xung đột phiên bản sửa (`If-Match`) |
| ERR-15-007 | 429 | Quá tần suất thao tác |
| ERR-15-008 | 503 | Danh mục chưa sẵn sàng |
| ERR-15-009 | 422 | Đặc tả không đọc được |
| ERR-15-010 | 409 | Chưa chấp nhận điều khoản hiện hành |
| ERR-15-011 | 422 | Tài khoản chưa xác minh hoặc chưa duyệt |
| ERR-15-012 | 409 | Thư điện tử trùng |
| ERR-15-013 | 400 | Mã xác minh sai hoặc hết hạn |
| ERR-15-014 | 403 | Tài khoản bị khóa |
| ERR-15-015 | 422 | Vượt số ứng dụng |
| ERR-15-016 | 422 | Vượt số thông tin xác thực |
| ERR-15-017 | 409 | Ứng dụng sai trạng thái |
| ERR-15-018 | 409 | Thông tin xác thực sai trạng thái |
| ERR-15-019 | 410 | Bí mật đã hiển thị |
| ERR-15-020 | 503 | Dịch vụ định danh (Keycloak) lỗi |
| ERR-15-021 | 422 | Nội dung không hợp lệ |
| ERR-15-022 | 409 | Trang nội dung hoặc tài khoản sai trạng thái |
| ERR-15-023 | 403 | Vi phạm bốn mắt |
| ERR-15-024 | 422 | Tệp đính kèm không hợp lệ |
| ERR-15-025 | 502 | Kho Git lỗi |
| ERR-15-026 | 422 | Cấu trúc kho Git hoặc gói di trú sai |
| ERR-15-027 | 409 | Đã là thành viên hoặc đã có lời mời |
| ERR-15-028 | 422 | Chủ sở hữu duy nhất |
| ERR-15-029 | 409 | Phiếu đã đóng |
| ERR-15-030 | 502 | PH-02 lỗi |
| ERR-15-031 | 502 | PH-01 lỗi |
| ERR-15-032 | 422 | Không phải đầu mối hoặc chưa có HTTT hoạt động |
| ERR-15-033 | 422 | Nhận diện không hợp lệ |
| ERR-15-034 | 422 | Tham số ngoài miền |
| ERR-15-035 | 409 | Đồng bộ hoặc di trú đang chạy |
| ERR-15-036 | 403 | Khu quản trị chỉ từ mạng quản trị |
| ERR-15-037 | 429 | Gửi quá nhiều (phiếu, hỏi đáp, đăng ký) |
| ERR-15-038 | 410 | Phiên bản đã ngừng |
| ERR-15-039 | 502 | PH-13 lỗi |
| ERR-15-040 | 422 | Dịch vụ không đủ điều kiện |

: Mã lỗi ERR-15 Control plane

| Mã | HTTP | Ý nghĩa |
|---|---|---|
| ERR-15-101 | 422 | Dịch vụ chưa bật sandbox |
| ERR-15-102 | 403 | Ứng dụng không đủ điều kiện thử |
| ERR-15-103 | 429 | Vượt hạn mức theo người |
| ERR-15-104 | 429 | Vượt hạn mức theo ứng dụng |
| ERR-15-105 | 413 | Thân yêu cầu quá lớn |
| ERR-15-106 | 422 | Dữ liệu cá nhân thật |
| ERR-15-107 | 422 | Không khớp đặc tả |
| ERR-15-108 | 504 | Backend thử quá hạn |
| ERR-15-109 | 502 | Backend thử lỗi |
| ERR-15-110 | 422 | Không sinh được phản hồi MOCK |
| ERR-15-111 | 503 | Gateway sandbox không sẵn sàng |
| ERR-15-112 | 403 | Chưa bật thử production |
| ERR-15-113 | 403 | Không có đăng ký sử dụng ACTIVE |
| ERR-15-114 | 403 | Dữ liệu nhạy cảm |
| ERR-15-115 | 503 | Kiểm toán lỗi nên từ chối thử |
| ERR-15-116 | 422 | Phương thức bị chặn |
| ERR-15-117 | 502 | Token exchange lỗi |
| ERR-15-118 | 429 | Vượt hạn mức production |
| ERR-15-119 | 422 | Địa chỉ ngoài allowlist |
| ERR-15-120 | 409 | Thiếu cấu hình theo chế độ |
| ERR-15-121 | 422 | Tiêu đề bị cấm |
| ERR-15-122 | 403 | Phiên bản không cho thử |
| ERR-15-123 | 413 | Phản hồi vượt cỡ |

: Mã lỗi ERR-15 Sandbox, thử API và data plane

<!-- gen:err:end -->

### 6.2. Trường mở rộng của phản hồi lỗi

Ngoài `code`, `title`, `status`, `detail`, `traceId`, phản hồi có thể mang `errors[]` (`field`, `message`, `rule`) ở `400` và `422`, không bao giờ chứa giá trị dữ liệu cá nhân (ERR-15-106 chỉ nêu tên trường); `retryAfterSeconds` và tiêu đề `Retry-After` ở `429`, `503` (ERR-15-007, 037, 103, 104, 118). Lỗi chung `ERR-15-004` (401), `ERR-15-005` (403) và `ERR-15-036` (khu quản trị) có thể xảy ra ở mọi operation đăng nhập, có quyền hoặc quản trị tương ứng nên không lặp trong `x-datahub-errors`.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng được kiểm tự động để tệp YAML, bảng trong tài liệu này và FRS không lệch nhau. Mọi tệp YAML và bảng ở §3, §4, §6 đều sinh từ một nguồn (`tools/gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`), không sửa tay.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; mọi ví dụ yêu cầu, phản hồi, lỗi khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; mã, phương thức, đường dẫn, FR của 142 operation trùng FRS §9.3; mọi ERR-15 của FRS có trong tệp; lệnh tạo có `Idempotency-Key`; không trường bí mật ngoài `CredentialIssued`, `GitSourceInput` | [`check_contracts.py`](ph15/tools/check_contracts.py) (`openapi-spec-validator`, `jsonschema` 2020-12) | CI-5 |
| AsyncAPI 3.0: đủ EVT-15-01…14 và EVT-02 tiêu thụ; kênh, thông điệp tham chiếu đúng; ví dụ khớp payload và tiêu đề | `check_contracts.py` | CI-5 |
| Lint quy ước | `@redocly/cli lint`; Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại ba script sinh rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp tài liệu gốc | `build/tools/kiem_tra_ma.py` | CI-1 |

: Các kiểm tra hợp đồng chạy trong CI

Kết quả chạy ngày 26/11/2026 (sau FRS 0.2): OpenAPI hợp lệ, 142 operation, 142 mã API, 195 ví dụ khớp; AsyncAPI 24 kênh, 24 thông điệp, 48 ví dụ khớp; không lỗi. Lệnh chạy lại:

```bash
cd datahub-docs/03-thiet-ke/api/ph15
python3 tools/gen_openapi.py && python3 tools/gen_asyncapi.py
python3 tools/check_contracts.py
cd ../../.. && python3 03-thiet-ke/api/ph15/tools/gen_md.py
python3 build/tools/sinh_dac_ta_api.py 03-thiet-ke/api/ph15/openapi-portal.yaml 03-thiet-ke/api/D03-04-PH15-api-cong-nha-phat-trien.md
```

## 8. Ánh xạ từ hệ cũ

Hệ cũ có Gravitee Portal (LGC-APIM-006, 007, 017 và phần nhà phát triển của 022) và đặc tả SRS cũ chọn Backstage. PH-15 thay bằng cổng tự xây; bảng dưới cho biết chức năng cũ nay ở API nào. Dòng "SRS cũ FR-15-0xx" ánh xạ sang FR mới ở FRS §11.2.

| Hệ cũ | Chức năng cũ | API mới | Ghi chú |
|---|---|---|---|
| LGC-APIM-006 | Publish, unpublish API lên portal | API-15-003…008 (đọc); cờ `portalPublished` do PH-02 giữ | Cổng chỉ hiển thị, không công bố |
| LGC-APIM-007 | Make Public | API-15-001, 003, 004, 010, 034, 035 | Ba mức `TENANT`, `NATIONAL`, `PUBLIC`; ẩn danh dưới `/public` |
| LGC-APIM-017 | Xem đường dẫn sử dụng API | API-15-008 | Lấy từ API-02-006 |
| LGC-APIM-022 (nhà phát triển) | Log request của Application | API-15-098, 099, 100 | Che dữ liệu, 30 ngày |
| SRS cũ FR-15-001, 002, 005, 006 | Đồng bộ, lọc, làm mới, chi tiết | API-15-005…009 | Nguồn PH-02 |
| SRS cũ FR-15-003, 004 | Hiển thị Swagger, theo phiên bản | API-15-015…021 | OpenAPI 3.1, AsyncAPI 3.0 |
| SRS cũ FR-15-007 | Sandbox thử API | API-15-069…081 | MOCK, BACKEND, thử production hạn chế |
| SRS cũ FR-15-008 | Cấp credential | API-15-055…068 | Client `dh-dev`, bí mật một lần |
| SRS cũ FR-15-009, 010 | TechDocs, soạn tài liệu | API-15-022…040 | Markdown có duyệt bốn mắt, nhập Git |
| SRS cũ FR-15-011 | Tìm kiếm | API-15-010…012 | Tiếng Việt không dấu, gợi ý |
| SRS cũ FR-15-012, 013 | Đăng ký sử dụng, công bố | API-15-087…096 | Ủy thác PH-02, PH-01 |
| SRS cũ FR-15-014 | Tài khoản nhà phát triển | API-15-041…054, 121…125 | Xác minh thư, duyệt, vô hiệu 45 ngày |
| SRS cũ FR-15-015, 016 | Kiểm toán, thống kê | API-15-097…100, 128…130 | Theo ứng dụng |

: Ánh xạ từ hệ cũ sang API-15

Hệ cũ không có hợp đồng REST công bố ngoài Gravitee nên không có tương thích ngược cần giữ; di trú nội dung đi qua API-15-135…137.

## 9. Câu hỏi mở

Mỗi câu nêu phương án ngầm định tập này đang dùng để không chặn việc hiện thực.

> **Câu hỏi mở Q15-55:** Người tự đăng ký `dh-dev` cần đọc điều khoản trước khi có tài khoản, nhưng API-15-047 chỉ cho người đã đăng nhập (FRS FR-15-023). Có cho API-15-047 đọc ẩn danh, hay hiển thị điều khoản qua trang nội dung công khai loại `TERMS`? Ngầm định: dùng trang `TERMS` công khai (API-15-035) và gửi `termsAccepted` trong thân API-15-045.

> **Câu hỏi mở Q15-56:** `Idempotency-Key` lưu 24 giờ (giả định theo PH-10) có đủ cho API-15-062 và 063 không, khi lặp lại yêu cầu sau 24 giờ sẽ tạo thông tin xác thực mới? Ngầm định: 24 giờ; quá hạn thì coi là yêu cầu mới, người dùng thấy bản ghi mới ở danh sách.

> **Câu hỏi mở Q15-57:** Plugin `forward-auth` của APISIX (PH-03) chỉ đọc mã trạng thái và tiêu đề `X-DH-*` của phản hồi API-15-082, hay đọc cả thân? Ngầm định: tiêu đề là hợp đồng, thân `AuthorizeDecision` chỉ để chẩn đoán; PH-03 xác nhận thời gian chờ 300 ms và `allow_degradation: false`.

> **Câu hỏi mở Q15-58:** PH-13 và PH-10 có tiêu thụ được chủ đề `{tenant}.portal.*` với 3 phân vùng, lưu giữ 7 ngày không? Ngầm định: có; số phân vùng và lưu giữ là giả định theo mức của PH-10.

> **Câu hỏi mở Q15-59:** Tên trường của EVT-02-02, 06, 09, 10, 11, 12 (`changedFields`, `to`, `sunsetAt`, `noticeId`, `mandatory`, `subscriptionId`) do PH-02 chốt ở D03-04-PH02; PH-02 có giữ đúng tập con mà `asyncapi-portal.yaml` dùng không? Ngầm định: có; cổng đọc theo kiểu bỏ qua trường lạ và kéo bù qua API-02-081 khi thiếu trường.

## 10. Đề nghị đồng bộ

Tập này chỉ sửa tệp PH-15. FRS PH-15 bản 0.2 đã hấp thụ các đề nghị gửi FRS (FRS mục 15.3); hợp đồng nay khớp FRS 0.2.

| Tài liệu | Đề nghị | Lý do | Tình trạng |
|---|---|---|---|
| FRS PH-15 §9.3 | Ghi rõ API-15-082 có đường dẫn gốc `/internal/v1/sandbox/authorize` (cổng 8081), không có tiền tố `/api/portal/v1` | Khớp SDD §4.10 | Đã hấp thụ ở FRS 0.2 |
| FRS PH-15 §9.3 | Thêm hai operation: `GET /content/attachments/{attachmentId}` và `GET /public/branding`; mã API-15-138 và 139 | Thiếu API đọc ảnh, logo | Đã hấp thụ: API-15-138, 139 |
| FRS PH-15 §9.3 | Thêm FR-15-002 vào cột FR của API-15-003, 004, 005, 007 cùng quyết định Q15-55 | Truy vết đủ FR | Đã hấp thụ; Q15-55 còn mở |
| FRS PH-15 FR-15-035, ERR-15-123 | Cảnh báo trong `warnings[]` hay `413` | FR và bảng lệch | Đã hấp thụ: gần ngưỡng `warnings[]`, vượt cứng `413` kèm `bodyTruncated` |
| FRS PH-15 FR-15-034, FR-15-042 | Quyền của đầu mối SV (○) với API-15-069, 070, 084 | FRS ghi "SV (○), TA" nhưng chỉ có một PERM | Đã hấp thụ: `portal-admin` (TA, CA) hoặc `content-write` (SV ○); hợp đồng đã đổi |
| FRS PH-15 Phụ lục A | Hấp thụ các trường chỉ có ở API: `viewerClass`, `termsUpToDate`, `retryAfterSeconds`, `partial[]`, `appCode` của API-15-074, `bodyTruncated`, `result`, `change` | Tránh trường ngoài | Đã hấp thụ: FRS A.9, §9.2 |
| FRS PH-15 §9.2 | EVT-15-04 thêm `appCode`; EVT-15-05 liệt kê `reason`; EVT-15-13 thêm `change` | Khóa phân vùng, lý do | Đã hấp thụ ở FRS 0.2 |
| Tập màn hình D03-06-PH15 Phụ lục B | Ba API: `GET /inbox/unread-count`, `GET /apps:check-code`, `GET /content/pages/{pageCode}/diff` | Giao diện nhẹ và đúng hơn | Đã chấp nhận: API-15-140, 141, 142 |
| D02-08 | Năm quyền `PERM-15-content-write`, `content-publish`, `support`, `dev-approve`, `audit-read`; scope `metrics:portal-read`, `sandbox:call` | Tập này dùng | Năm quyền đã có ở D02-08; hai scope máy còn chờ D02-08 |
| D03-04-PH02, D03-04-PH10 | PH-02 chốt tên trường EVT-02 (Q15-59), xác nhận API-02-081, 006; PH-10 chấp nhận chủ đề `{tenant}.portal.support.ticket-opened.v1` (Q15-58) | Khớp hợp đồng | Còn chờ |

: Đề nghị đồng bộ của tập API PH-15

## 11. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.

<!-- gen:dac-ta-api:start -->

### Trang chủ, danh mục, tìm kiếm

#### API-15-001 · Trang chủ cổng cho khách ẩn danh

::: dac-ta
**Mục đích.** Trang chủ cổng cho khách ẩn danh.

**Phương thức, đường dẫn.** `GET /public/home`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-003.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HomeView`; trường bắt buộc: `portalName`, `featured`, `announcements`; `304` không đổi.

**Lỗi.** HTTP `429`, `503`; mã lỗi của thao tác: ERR-15-008, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả nội dung `PUBLIC`; `Cache-Control: public, max-age=300`; tắt khi tham số công khai của tenant tắt (FR-15-057).
:::

#### API-15-002 · Trang chủ cổng cho người dùng đã đăng nhập

::: dac-ta
**Mục đích.** Trang chủ cổng cho người dùng đã đăng nhập.

**Phương thức, đường dẫn.** `GET /home`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-003.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HomeView`; trường bắt buộc: `portalName`, `featured`, `announcements`.

**Lỗi.** HTTP `401`, `503`; mã lỗi của thao tác: ERR-15-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm `myWork` (ứng dụng, lượt thử, thông báo chưa đọc, thông tin xác thực sắp hết hạn).
:::

#### API-15-003 · Danh mục dịch vụ công khai

::: dac-ta
**Mục đích.** Danh mục dịch vụ công khai.

**Phương thức, đường dẫn.** `GET /public/catalog/apis`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-002, FR-15-008.

**Tham số.** `q` (query, string, tùy chọn); `linh-vuc` (query, string, tùy chọn); `chu-quan` (query, string, tùy chọn); `xac-thuc` (query, AuthKind, tùy chọn); `loai` (query, string, tùy chọn); `trang-thai` (query, string, tùy chọn); `da-ngung` (query, boolean, tùy chọn); `sap-xep` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; `304` không đổi.

**Lỗi.** HTTP `400`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ mục `visibility=PUBLIC`; dữ liệu rút gọn; hỗ trợ `If-None-Match` và `304`.
:::

#### API-15-004 · Chi tiết dịch vụ công khai

::: dac-ta
**Mục đích.** Chi tiết dịch vụ công khai.

**Phương thức, đường dẫn.** `GET /public/catalog/apis/{apiCode}`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-002, FR-15-008.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemDetail`; trường bắt buộc: `apiCode`, `name`, `kind`, `description`, `ownerOrg`, `dataClass`, `visibility`, `versions`, `syncedAt`; `304` không đổi.

**Lỗi.** HTTP `404`, `410`, `429`; mã lỗi của thao tác: ERR-15-001, ERR-15-038, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mục ngoài tầm nhìn trả `404` như không tồn tại (BR-15-002).
:::

#### API-15-005 · Duyệt, lọc, sắp xếp danh mục dịch vụ

::: dac-ta
**Mục đích.** Duyệt, lọc, sắp xếp danh mục dịch vụ.

**Phương thức, đường dẫn.** `GET /catalog/apis`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-002, FR-15-004.

**Tham số.** `q` (query, string, tùy chọn); `linh-vuc` (query, string, tùy chọn); `chu-quan` (query, string, tùy chọn); `xac-thuc` (query, AuthKind, tùy chọn); `loai` (query, string, tùy chọn); `trang-thai` (query, string, tùy chọn); `da-ngung` (query, boolean, tùy chọn); `sap-xep` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `503`; mã lỗi của thao tác: ERR-15-003, ERR-15-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp mức hiển thị theo hạng người xem (`TENANT`, `NATIONAL`, `PUBLIC`); `facets` ở API-15-006.
:::

#### API-15-006 · Giá trị bộ lọc (facets) của danh mục

::: dac-ta
**Mục đích.** Giá trị bộ lọc (facets) của danh mục.

**Phương thức, đường dẫn.** `GET /catalog/facets`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-004.

**Tham số.** `q` (query, string, tùy chọn); `linh-vuc` (query, string, tùy chọn); `chu-quan` (query, string, tùy chọn); `xac-thuc` (query, AuthKind, tùy chọn); `loai` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogFacets`; trường bắt buộc: `facets`.

**Lỗi.** HTTP `400`, `401`, `503`; mã lỗi của thao tác: ERR-15-003, ERR-15-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-007 · Chi tiết dịch vụ: phiên bản, gói, SLA

::: dac-ta
**Mục đích.** Chi tiết dịch vụ: phiên bản, gói, SLA.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-002, FR-15-006.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemDetail`; trường bắt buộc: `apiCode`, `name`, `kind`, `description`, `ownerOrg`, `dataClass`, `visibility`, `versions`, `syncedAt`.

**Lỗi.** HTTP `401`, `404`, `410`, `503`; mã lỗi của thao tác: ERR-15-001, ERR-15-038, ERR-15-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngoài tầm nhìn: `404`.
:::

#### API-15-008 · Đường dẫn sử dụng của dịch vụ

::: dac-ta
**Mục đích.** Đường dẫn sử dụng của dịch vụ.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/usage`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-006.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageInfo`; trường bắt buộc: `baseUrl`, `scopes`.

**Lỗi.** HTTP `401`, `404`, `410`; mã lỗi của thao tác: ERR-15-001, ERR-15-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Địa chỉ gọi, địa chỉ lấy token, scope, mẫu (LGC-APIM-017); lấy từ API-02-006 của PH-02.
:::

#### API-15-009 · Trạng thái đồng bộ danh mục

::: dac-ta
**Mục đích.** Trạng thái đồng bộ danh mục.

**Phương thức, đường dẫn.** `GET /catalog/sync-status`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-001.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncStatus`; trường bắt buộc: `state`, `lagSeconds`, `itemCount`.

**Lỗi.** HTTP `401`, `403`, `422`, `503`; mã lỗi của thao tác: ERR-15-008, ERR-15-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái `IDLE`, `RUNNING`, `FAILED`, `STALE` và độ trễ so với PH-02.
:::

#### API-15-010 · Tìm kiếm toàn văn công khai

::: dac-ta
**Mục đích.** Tìm kiếm toàn văn công khai.

**Phương thức, đường dẫn.** `GET /public/search`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-005, FR-15-008.

**Tham số.** `q` (query, string, bắt buộc); `loai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchResultPage`; trường bắt buộc: `results`, `page`, `size`, `totalElements`; `304` không đổi.

**Lỗi.** HTTP `400`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả mục công khai; kết quả được kiểm lại hiển thị lần hai (BR-15-002).
:::

#### API-15-011 · Tìm kiếm toàn văn theo quyền xem

::: dac-ta
**Mục đích.** Tìm kiếm toàn văn theo quyền xem.

**Phương thức, đường dẫn.** `GET /search`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-005.

**Tham số.** `q` (query, string, bắt buộc); `loai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchResultPage`; trường bắt buộc: `results`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** OpenSearch, dự phòng PostgreSQL FTS với `unaccent` (QĐ-15-04).
:::

#### API-15-012 · Gợi ý tìm kiếm

::: dac-ta
**Mục đích.** Gợi ý tìm kiếm.

**Phương thức, đường dẫn.** `GET /search/suggest`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-005.

**Tham số.** `q` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Suggestions`; trường bắt buộc: `suggestions`.

**Lỗi.** HTTP `400`, `401`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối đa 10 gợi ý; chịu bộ lọc hiển thị như tìm kiếm.
:::

#### API-15-013 · Danh sách dịch vụ sự kiện (topic)

::: dac-ta
**Mục đích.** Danh sách dịch vụ sự kiện (topic).

**Phương thức, đường dẫn.** `GET /catalog/topics`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-007.

**Tham số.** `q` (query, string, tùy chọn); `linh-vuc` (query, string, tùy chọn); `chu-quan` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TopicPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Topic của PH-10 theo mức hiển thị; không có dữ liệu sự kiện.
:::

#### API-15-014 · Chi tiết dịch vụ sự kiện

::: dac-ta
**Mục đích.** Chi tiết dịch vụ sự kiện.

**Phương thức, đường dẫn.** `GET /catalog/topics/{topicCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-007.

**Tham số.** `topicCode` (path, TopicCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TopicDetail`; trường bắt buộc: `topicName`, `description`, `dataClass`, `visibility`.

**Lỗi.** HTTP `401`, `404`, `422`; mã lỗi của thao tác: ERR-15-001, ERR-15-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-139 · Nhận diện công khai của cổng

::: dac-ta
**Mục đích.** Nhận diện công khai của cổng.

**Phương thức, đường dẫn.** `GET /public/branding`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-003, FR-15-056.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublicBranding`; trường bắt buộc: `portalName`; `304` không đổi.

**Lỗi.** Không.

**Ghi chú.** Chỉ trả các khóa nhận diện (BR-15-032); `Cache-Control: public, max-age=300`; logo phục vụ qua đường tĩnh của BFF.
:::

### Tài liệu API

#### API-15-015 · Danh sách phiên bản API

::: dac-ta
**Mục đích.** Danh sách phiên bản API.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/versions`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-011.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gồm phiên bản `DEPRECATED` kèm `sunsetAt`.
:::

#### API-15-016 · Tải đặc tả của một phiên bản

::: dac-ta
**Mục đích.** Tải đặc tả của một phiên bản.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/versions/{versionNo}/spec`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-009, FR-15-011.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, SemVer, bắt buộc); `format` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SpecDocument`; trường bắt buộc: `kind`, `versionNo`, `hash`, `content`; tiêu đề `Content-Disposition`.

**Lỗi.** HTTP `400`, `401`, `404`, `410`, `422`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-009, ERR-15-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `format=yaml` trả `application/yaml`; ghi kiểm toán `DOWNLOAD_SPEC`.
:::

#### API-15-017 · Các thao tác của đặc tả OpenAPI

::: dac-ta
**Mục đích.** Các thao tác của đặc tả OpenAPI.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/versions/{versionNo}/operations`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-009.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, SemVer, bắt buộc); `thao-tac` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OperationPage`; trường bắt buộc: `items`, `hash`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `410`, `422`; mã lỗi của thao tác: ERR-15-009, ERR-15-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân trang theo thao tác để dựng 300 thao tác dưới 2 giây (NFR-15-003).
:::

#### API-15-018 · Kênh, thông điệp của dịch vụ sự kiện (AsyncAPI)

::: dac-ta
**Mục đích.** Kênh, thông điệp của dịch vụ sự kiện (AsyncAPI).

**Phương thức, đường dẫn.** `GET /catalog/topics/{topicCode}/events`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-010.

**Tham số.** `topicCode` (path, TopicCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TopicEvents`; trường bắt buộc: `topicName`, `channels`.

**Lỗi.** HTTP `401`, `404`, `422`; mã lỗi của thao tác: ERR-15-001, ERR-15-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-019 · Mẫu mã gọi API

::: dac-ta
**Mục đích.** Mẫu mã gọi API.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/samples`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-012.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `operationId` (query, string, bắt buộc); `lang` (query, string, tùy chọn); `env` (query, TryEnv, tùy chọn); `authKind` (query, AuthKind, tùy chọn); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SampleList`; trường bắt buộc: `samples`.

**Lỗi.** HTTP `400`, `401`, `404`; mã lỗi của thao tác: ERR-15-001, ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bí mật luôn là chỗ giữ `<ACCESS_TOKEN>`, `<API_KEY>` (BR-15-011).
:::

#### API-15-020 · So sánh hai phiên bản API

::: dac-ta
**Mục đích.** So sánh hai phiên bản API.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/diff`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-011.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `base` (query, SemVer, bắt buộc); `target` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SpecDiff`; trường bắt buộc: `base`, `target`, `added`, `removed`, `changed`.

**Lỗi.** HTTP `400`, `401`, `404`, `410`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân loại thay đổi phá vỡ và không phá vỡ (`breaking`).
:::

#### API-15-021 · Changelog và lộ trình ngừng dùng

::: dac-ta
**Mục đích.** Changelog và lộ trình ngừng dùng.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/changelog`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-013.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Changelog`; trường bắt buộc: `timeline`.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghép từ EVT-02-12 và lộ trình của phiên bản `DEPRECATED`.
:::

### Nội dung và hướng dẫn

#### API-15-022 · Danh sách trang nội dung (soạn thảo)

::: dac-ta
**Mục đích.** Danh sách trang nội dung (soạn thảo).

**Phương thức, đường dẫn.** `GET /content/pages`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-014.

**Tham số.** `q` (query, string, tùy chọn); `loai` (query, string, tùy chọn); `trang-thai` (query, string, tùy chọn); `lang` (query, Lang, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn); `sap-xep` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageList`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-023 · Tạo trang nội dung Markdown

::: dac-ta
**Mục đích.** Tạo trang nội dung Markdown.

**Phương thức, đường dẫn.** `POST /content/pages`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageInput`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `audience`, `markdown`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-15-002, ERR-15-003, ERR-15-021, ERR-15-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Markdown qua bộ lọc (BR-15-013); trang ≤ 200 KB; trả `ETag`.
:::

#### API-15-024 · Chi tiết trang nội dung (soạn thảo)

::: dac-ta
**Mục đích.** Chi tiết trang nội dung (soạn thảo).

**Phương thức, đường dẫn.** `GET /content/pages/{pageCode}`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-014.

**Tham số.** `pageCode` (path, PageCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-025 · Sửa trang nội dung

::: dac-ta
**Mục đích.** Sửa trang nội dung.

**Phương thức, đường dẫn.** `PUT /content/pages/{pageCode}`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-014.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageEdit`; trường bắt buộc: `markdown`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-021, ERR-15-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa trang đang đăng tạo phiên bản nháp mới; bản đang đăng vẫn hiển thị.
:::

#### API-15-026 · Gửi duyệt trang nội dung

::: dac-ta
**Mục đích.** Gửi duyệt trang nội dung.

**Phương thức, đường dẫn.** `POST /content/pages/{pageCode}:submit`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-015.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageSubmit`; trường bắt buộc: `versionNo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi `submittedBy` để kiểm bốn mắt (BR-15-012).
:::

#### API-15-027 · Duyệt và đăng trang

::: dac-ta
**Mục đích.** Duyệt và đăng trang.

**Phương thức, đường dẫn.** `POST /content/pages/{pageCode}:approve`.

**Quyền.** `PERM-15-content-publish`.

**FR hiện thực.** FR-15-015.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageDecision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-023, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người soạn, người sửa và người gửi; phát EVT-15-08.
:::

#### API-15-028 · Từ chối duyệt trang

::: dac-ta
**Mục đích.** Từ chối duyệt trang.

**Phương thức, đường dẫn.** `POST /content/pages/{pageCode}:reject`.

**Quyền.** `PERM-15-content-publish`.

**FR hiện thực.** FR-15-015.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageDecision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-023, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `comment` bắt buộc khi từ chối.
:::

#### API-15-029 · Gỡ đăng trang

::: dac-ta
**Mục đích.** Gỡ đăng trang.

**Phương thức, đường dẫn.** `POST /content/pages/{pageCode}:unpublish`.

**Quyền.** `PERM-15-content-publish`.

**FR hiện thực.** FR-15-016.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PageUnpublish`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát EVT-15-09.
:::

#### API-15-030 · Danh sách phiên bản của trang

::: dac-ta
**Mục đích.** Danh sách phiên bản của trang.

**Phương thức, đường dẫn.** `GET /content/pages/{pageCode}/versions`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-016.

**Tham số.** `pageCode` (path, PageCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageVersionList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-031 · Chi tiết một phiên bản trang

::: dac-ta
**Mục đích.** Chi tiết một phiên bản trang.

**Phương thức, đường dẫn.** `GET /content/pages/{pageCode}/versions/{versionNo}`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-016.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageVersion`; trường bắt buộc: `versionNo`, `status`, `createdBy`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-032 · Khôi phục phiên bản trang thành bản nháp

::: dac-ta
**Mục đích.** Khôi phục phiên bản trang thành bản nháp.

**Phương thức, đường dẫn.** `POST /content/pages/{pageCode}/versions/{versionNo}:restore`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-016.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PageDetail`; trường bắt buộc: `pageCode`, `type`, `lang`, `title`, `status`, `audience`, `currentVersion`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo phiên bản `DRAFT` mới từ nội dung phiên bản cũ; không đăng tự động.
:::

#### API-15-033 · Tải ảnh đính kèm cho trang

::: dac-ta
**Mục đích.** Tải ảnh đính kèm cho trang.

**Phương thức, đường dẫn.** `POST /content/attachments`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-014, FR-15-017.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `AttachmentUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AttachmentUploaded`; trường bắt buộc: `attachmentId`, `url`, `contentType`, `size`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PNG, JPEG, WebP ≤ 5 MB, không SVG; quét ClamAV, kiểm kiểu theo nội dung (SEC-45).
:::

#### API-15-034 · Danh sách trang công khai

::: dac-ta
**Mục đích.** Danh sách trang công khai.

**Phương thức, đường dẫn.** `GET /public/pages`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-017.

**Tham số.** `q` (query, string, tùy chọn); `loai` (query, string, tùy chọn); `lang` (query, Lang, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageList`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; `304` không đổi.

**Lỗi.** HTTP `400`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trang `audience=PUBLIC`, trạng thái `PUBLISHED`.
:::

#### API-15-035 · Xem trang công khai

::: dac-ta
**Mục đích.** Xem trang công khai.

**Phương thức, đường dẫn.** `GET /public/pages/{pageCode}`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-017.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `lang` (query, Lang, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublicPage`; trường bắt buộc: `pageCode`, `title`, `html`, `versionNo`, `updatedAt`; `304` không đổi.

**Lỗi.** HTTP `404`, `429`; mã lỗi của thao tác: ERR-15-001, ERR-15-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả HTML đã làm sạch kèm mục lục.
:::

#### API-15-036 · Danh sách trang theo quyền xem

::: dac-ta
**Mục đích.** Danh sách trang theo quyền xem.

**Phương thức, đường dẫn.** `GET /pages`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-017.

**Tham số.** `q` (query, string, tùy chọn); `loai` (query, string, tùy chọn); `lang` (query, Lang, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageList`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gồm trang `LOGGED_IN`, và `TENANT` nếu cùng tenant.
:::

#### API-15-037 · Xem trang theo quyền xem

::: dac-ta
**Mục đích.** Xem trang theo quyền xem.

**Phương thức, đường dẫn.** `GET /pages/{pageCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-017.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `lang` (query, Lang, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublicPage`; trường bắt buộc: `pageCode`, `title`, `html`, `versionNo`, `updatedAt`.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-038 · Danh sách nguồn Git nhập nội dung

::: dac-ta
**Mục đích.** Danh sách nguồn Git nhập nội dung.

**Phương thức, đường dẫn.** `GET /content/git-sources`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-018.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GitSourceList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-025 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-039 · Khai báo nguồn Git

::: dac-ta
**Mục đích.** Khai báo nguồn Git.

**Phương thức, đường dẫn.** `POST /content/git-sources`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GitSourceInput`; trường bắt buộc: `repoUrl`, `branch`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `GitSource`; trường bắt buộc: `sourceId`, `repoUrl`, `branch`, `path`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-025, ERR-15-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ HTTPS thuộc allowlist egress; mã truy cập ghi một chiều vào OpenBao.
:::

#### API-15-040 · Đồng bộ nội dung từ kho Git

::: dac-ta
**Mục đích.** Đồng bộ nội dung từ kho Git.

**Phương thức, đường dẫn.** `POST /content/git-sources/{sourceId}:sync`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-018.

**Tham số.** `sourceId` (path, Uuid, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `RunAccepted`; trường bắt buộc: `runId`, `state`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-025, ERR-15-026, ERR-15-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo `DRAFT` cho tệp đổi, không bao giờ tự đăng (BR-15-012).
:::

#### API-15-138 · Đọc ảnh đính kèm của trang

::: dac-ta
**Mục đích.** Đọc ảnh đính kèm của trang.

**Phương thức, đường dẫn.** `GET /content/attachments/{attachmentId}`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-014, FR-15-017.

**Tham số.** `attachmentId` (path, Uuid, bắt buộc); `sig` (query, string, bắt buộc); `exp` (query, string, bắt buộc); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; `304` không đổi.

**Lỗi.** HTTP `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chữ ký `sig` còn hạn 15 phút thay cho phiên (FR-15-017); trả ảnh với `Content-Type` đúng và `X-Content-Type-Options: nosniff`; chữ ký sai hoặc hết hạn trả `404`.
:::

#### API-15-142 · So sánh hai phiên bản của trang

::: dac-ta
**Mục đích.** So sánh hai phiên bản của trang.

**Phương thức, đường dẫn.** `GET /content/pages/{pageCode}/diff`.

**Quyền.** `PERM-15-content-write`.

**FR hiện thực.** FR-15-016.

**Tham số.** `pageCode` (path, PageCode, bắt buộc); `base` (query, integer, bắt buộc); `to` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PageDiff`; trường bắt buộc: `pageCode`, `base`, `to`, `added`, `removed`, `hunks`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001, ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** So sánh phía máy chủ theo dòng Markdown nguồn; không trả HTML (FR-15-016).
:::

### Tài khoản nhà phát triển

#### API-15-041 · Hồ sơ người dùng hiện tại

::: dac-ta
**Mục đích.** Hồ sơ người dùng hiện tại.

**Phương thức, đường dẫn.** `GET /me`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-021.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Me`; trường bắt buộc: `userId`, `source`, `fullName`, `status`, `viewerClass`, `tenant`, `termsUpToDate`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi của thao tác: ERR-15-011, ERR-15-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm `viewerClass` và `termsUpToDate`.
:::

#### API-15-042 · Sửa hồ sơ cá nhân

::: dac-ta
**Mục đích.** Sửa hồ sơ cá nhân.

**Phương thức, đường dẫn.** `PUT /me`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-021.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MeUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Me`; trường bắt buộc: `userId`, `source`, `fullName`, `status`, `viewerClass`, `tenant`, `termsUpToDate`.

**Lỗi.** HTTP `400`, `401`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-043 · Danh sách phiên đăng nhập

::: dac-ta
**Mục đích.** Danh sách phiên đăng nhập.

**Phương thức, đường dẫn.** `GET /me/sessions`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-021.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SessionList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-15-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-044 · Đăng xuất một phiên

::: dac-ta
**Mục đích.** Đăng xuất một phiên.

**Phương thức, đường dẫn.** `DELETE /me/sessions/{sessionId}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-021.

**Tham số.** `sessionId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-045 · Tự đăng ký tài khoản dh-dev

::: dac-ta
**Mục đích.** Tự đăng ký tài khoản dh-dev.

**Phương thức, đường dẫn.** `POST /developer-registrations`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-020.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DevRegistrationInput`; trường bắt buộc: `email`, `fullName`, `orgName`, `contractNo`, `sponsorOrg`, `termsVersion`, `termsAccepted`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `RegistrationAccepted`; trường bắt buộc: `registrationId`, `status`.

**Lỗi.** HTTP `400`, `409`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-012, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không có mật khẩu trong thân: người dùng đặt ở Keycloak sau khi xác minh thư; có xác minh chống tự động.
:::

#### API-15-046 · Xác minh thư điện tử đăng ký

::: dac-ta
**Mục đích.** Xác minh thư điện tử đăng ký.

**Phương thức, đường dẫn.** `POST /developer-registrations:verify-email`.

**Quyền.** Ẩn danh (khách chưa đăng nhập).

**FR hiện thực.** FR-15-020.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VerifyEmailInput`; trường bắt buộc: `registrationId`, `code`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `RegistrationState`; trường bắt buộc: `registrationId`, `status`.

**Lỗi.** HTTP `400`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-013, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trong 24 giờ; thành công chuyển `PENDING_APPROVAL`; phát EVT-15-06.
:::

#### API-15-047 · Điều khoản sử dụng hiện hành

::: dac-ta
**Mục đích.** Điều khoản sử dụng hiện hành.

**Phương thức, đường dẫn.** `GET /terms/current`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-023.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Terms`; trường bắt buộc: `termsVersion`, `effectiveFrom`, `title`, `html`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-15-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-048 · Chấp nhận điều khoản sử dụng

::: dac-ta
**Mục đích.** Chấp nhận điều khoản sử dụng.

**Phương thức, đường dẫn.** `POST /terms/acceptances`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-023.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TermsAcceptInput`; trường bắt buộc: `termsVersion`, `accepted`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TermsAcceptance`; trường bắt buộc: `termsVersion`, `acceptedAt`.

**Lỗi.** HTTP `400`, `401`, `409`; mã lỗi của thao tác: ERR-15-003, ERR-15-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-049 · Danh sách nhóm phát triển

::: dac-ta
**Mục đích.** Danh sách nhóm phát triển.

**Phương thức, đường dẫn.** `GET /teams`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-022.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TeamList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-15-004, ERR-15-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-050 · Tạo nhóm phát triển

::: dac-ta
**Mục đích.** Tạo nhóm phát triển.

**Phương thức, đường dẫn.** `POST /teams`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-022.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TeamInput`; trường bắt buộc: `teamCode`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Team`; trường bắt buộc: `teamCode`, `name`, `members`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-15-002, ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người tạo là `OWNER` đầu tiên.
:::

#### API-15-051 · Mời thành viên vào nhóm

::: dac-ta
**Mục đích.** Mời thành viên vào nhóm.

**Phương thức, đường dẫn.** `POST /teams/{teamCode}/invitations`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-022.

**Tham số.** `teamCode` (path, TeamCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InvitationInput`; trường bắt buộc: `email`, `role`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Invitation`; trường bắt buộc: `invitationId`, `teamCode`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-15-003, ERR-15-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ `OWNER` của nhóm; lời mời hết hạn sau 7 ngày (giả định).
:::

#### API-15-052 · Phản hồi lời mời vào nhóm

::: dac-ta
**Mục đích.** Phản hồi lời mời vào nhóm.

**Phương thức, đường dẫn.** `POST /me/invitations/{invitationId}:respond`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-022.

**Tham số.** `invitationId` (path, Uuid, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InvitationRespond`; trường bắt buộc: `accept`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Invitation`; trường bắt buộc: `invitationId`, `teamCode`, `status`.

**Lỗi.** HTTP `401`, `404`, `409`; mã lỗi của thao tác: ERR-15-001, ERR-15-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-053 · Gỡ thành viên khỏi nhóm

::: dac-ta
**Mục đích.** Gỡ thành viên khỏi nhóm.

**Phương thức, đường dẫn.** `DELETE /teams/{teamCode}/members/{userId}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-022.

**Tham số.** `teamCode` (path, TeamCode, bắt buộc); `userId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-15-001, ERR-15-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không gỡ được chủ sở hữu duy nhất (ERR-15-028).
:::

#### API-15-054 · Yêu cầu xóa tài khoản

::: dac-ta
**Mục đích.** Yêu cầu xóa tài khoản.

**Phương thức, đường dẫn.** `POST /me:request-erasure`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-024.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ErasureInput`; trường bắt buộc: `confirmPhrase`, `reauthProof`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ErasureAccepted`; trường bắt buộc: `userId`, `status`.

**Lỗi.** HTTP `400`, `401`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa bằng ẩn danh hóa (BR-15-029); yêu cầu xác thực lại.
:::

### Ứng dụng và thông tin xác thực

#### API-15-055 · Danh sách ứng dụng của tôi

::: dac-ta
**Mục đích.** Danh sách ứng dụng của tôi.

**Phương thức, đường dẫn.** `GET /apps`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-025.

**Tham số.** `q` (query, string, tùy chọn); `trang-thai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-056 · Tạo ứng dụng sandbox

::: dac-ta
**Mục đích.** Tạo ứng dụng sandbox.

**Phương thức, đường dẫn.** `POST /apps`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AppInput`; trường bắt buộc: `appCode`, `name`, `ownerType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-15-002, ERR-15-003, ERR-15-010, ERR-15-015, ERR-15-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả `Location`, `ETag`; chủ `TEAM` cần là thành viên nhóm.
:::

#### API-15-057 · Chi tiết ứng dụng

::: dac-ta
**Mục đích.** Chi tiết ứng dụng.

**Phương thức, đường dẫn.** `GET /apps/{appCode}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-025.

**Tham số.** `appCode` (path, AppCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-058 · Sửa ứng dụng

::: dac-ta
**Mục đích.** Sửa ứng dụng.

**Phương thức, đường dẫn.** `PATCH /apps/{appCode}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-026.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AppPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `appCode` bất biến (BR-15-007).
:::

#### API-15-059 · Lưu trữ ứng dụng

::: dac-ta
**Mục đích.** Lưu trữ ứng dụng.

**Phương thức, đường dẫn.** `POST /apps/{appCode}:archive`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-026.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-006, ERR-15-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thu hồi mọi thông tin xác thực; khôi phục được trong 30 ngày; phát EVT-15-02, EVT-15-05.
:::

#### API-15-060 · Khôi phục ứng dụng đã lưu trữ

::: dac-ta
**Mục đích.** Khôi phục ứng dụng đã lưu trữ.

**Phương thức, đường dẫn.** `POST /apps/{appCode}:restore`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-026.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-15-015, ERR-15-017, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không khôi phục bí mật; người dùng cấp mới.
:::

#### API-15-061 · Danh sách thông tin xác thực của ứng dụng

::: dac-ta
**Mục đích.** Danh sách thông tin xác thực của ứng dụng.

**Phương thức, đường dẫn.** `GET /apps/{appCode}/credentials`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-027.

**Tham số.** `appCode` (path, AppCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không có bí mật, chỉ tiền tố.
:::

#### API-15-062 · Cấp thông tin xác thực sandbox (client_credentials hoặc API key)

::: dac-ta
**Mục đích.** Cấp thông tin xác thực sandbox (client_credentials hoặc API key).

**Phương thức, đường dẫn.** `POST /apps/{appCode}/credentials`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-027, FR-15-028, FR-15-029.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CredentialIssueInput`; trường bắt buộc: `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CredentialIssued`; trường bắt buộc: `credentialId`, `kind`, `status`, `prefix`, `expiresAt`, `createdAt`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `410`, `422`, `503`; mã lỗi của thao tác: ERR-15-003, ERR-15-016, ERR-15-017, ERR-15-019, ERR-15-020 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `Cache-Control: no-store`; bí mật hiện đúng một lần (FR-15-029); `Idempotency-Key` lặp trả bản ghi không có bí mật (ERR-15-019).
:::

#### API-15-063 · Xoay vòng thông tin xác thực

::: dac-ta
**Mục đích.** Xoay vòng thông tin xác thực.

**Phương thức, đường dẫn.** `POST /apps/{appCode}/credentials/{credentialId}:rotate`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-030.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `credentialId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RotateInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RotateResult`; trường bắt buộc: `current`, `previous`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `503`; mã lỗi của thao tác: ERR-15-003, ERR-15-016, ERR-15-018, ERR-15-020, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản cũ `ROTATING` tối đa 72 giờ; bản mới trả bí mật một lần.
:::

#### API-15-064 · Thu hồi thông tin xác thực

::: dac-ta
**Mục đích.** Thu hồi thông tin xác thực.

**Phương thức, đường dẫn.** `POST /apps/{appCode}/credentials/{credentialId}:revoke`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-031.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `credentialId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevokeInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Credential`; trường bắt buộc: `credentialId`, `kind`, `status`, `expiresAt`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-15-018, ERR-15-020, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hiệu lực ≤ 5 giây ở `forward-auth` (NFR-15-007); phát EVT-15-05.
:::

#### API-15-065 · Tham chiếu thông tin xác thực production của ứng dụng

::: dac-ta
**Mục đích.** Tham chiếu thông tin xác thực production của ứng dụng.

**Phương thức, đường dẫn.** `GET /apps/{appCode}/prod-credentials`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-032.

**Tham số.** `appCode` (path, AppCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProdCredentialRefList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đọc từ PH-01, không bao giờ có bí mật (BR-15-015).
:::

#### API-15-066 · Danh sách thành viên ứng dụng

::: dac-ta
**Mục đích.** Danh sách thành viên ứng dụng.

**Phương thức, đường dẫn.** `GET /apps/{appCode}/members`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-033.

**Tham số.** `appCode` (path, AppCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MemberList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-067 · Giao hoặc đổi vai trò thành viên ứng dụng

::: dac-ta
**Mục đích.** Giao hoặc đổi vai trò thành viên ứng dụng.

**Phương thức, đường dẫn.** `PUT /apps/{appCode}/members/{userId}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-033.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `userId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MemberInput`; trường bắt buộc: `role`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Member`; trường bắt buộc: `userId`, `role`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-027, ERR-15-028, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ `OWNER` của ứng dụng; phát EVT-15-13.
:::

#### API-15-068 · Gỡ thành viên khỏi ứng dụng

::: dac-ta
**Mục đích.** Gỡ thành viên khỏi ứng dụng.

**Phương thức, đường dẫn.** `DELETE /apps/{appCode}/members/{userId}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-033.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `userId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-15-001, ERR-15-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-141 · Kiểm tra mã ứng dụng đã dùng chưa

::: dac-ta
**Mục đích.** Kiểm tra mã ứng dụng đã dùng chưa.

**Phương thức, đường dẫn.** `GET /apps:check-code`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-025.

**Tham số.** `appCode` (query, AppCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppCodeCheck`; trường bắt buộc: `appCode`, `available`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ báo gợi ý khi gõ; kiểm tra cuối vẫn ở API-15-056 (ERR-15-002), kể cả mã của ứng dụng đã lưu trữ.
:::

### Sandbox và thử API

#### API-15-069 · Xem hồ sơ sandbox của dịch vụ

::: dac-ta
**Mục đích.** Xem hồ sơ sandbox của dịch vụ.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/sandbox`.

**Quyền.** `PERM-15-portal-admin hoặc PERM-15-content-write (SV ○ theo đối tượng)`.

**FR hiện thực.** FR-15-034.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `phien-ban` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SandboxProfile`; trường bắt buộc: `apiCode`, `versionNo`, `mode`, `examplePolicy`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Do TA hoặc đầu mối SV của tổ chức chủ dịch vụ (○) xem và khai báo.
:::

#### API-15-070 · Khai báo hồ sơ sandbox của dịch vụ

::: dac-ta
**Mục đích.** Khai báo hồ sơ sandbox của dịch vụ.

**Phương thức, đường dẫn.** `PUT /catalog/apis/{apiCode}/sandbox`.

**Quyền.** `PERM-15-portal-admin hoặc PERM-15-content-write (SV ○ theo đối tượng)`.

**FR hiện thực.** FR-15-034.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SandboxProfileInput`; trường bắt buộc: `versionNo`, `mode`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SandboxProfile`; trường bắt buộc: `apiCode`, `versionNo`, `mode`, `examplePolicy`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-040, ERR-15-110, ERR-15-119, ERR-15-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm backend thử theo allowlist egress, HTTPS (BR-15-018).
:::

#### API-15-071 · Kiểm tra yêu cầu thử trước khi gửi

::: dac-ta
**Mục đích.** Kiểm tra yêu cầu thử trước khi gửi.

**Phương thức, đường dẫn.** `POST /try/requests:validate`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-038.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TryRequestInput`; trường bắt buộc: `appCode`, `apiCode`, `versionNo`, `operationId`, `environment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TryValidation`; trường bắt buộc: `valid`, `violations`, `warnings`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `413`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-105, ERR-15-106, ERR-15-107, ERR-15-121, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không gọi hệ thống nào; trả cảnh báo dữ liệu cá nhân giống thật (PII-15).
:::

#### API-15-072 · Thử API (sandbox hoặc production)

::: dac-ta
**Mục đích.** Thử API (sandbox hoặc production).

**Phương thức, đường dẫn.** `POST /try/requests`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-035, FR-15-036, FR-15-037, FR-15-043.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TryRequestInput`; trường bắt buộc: `appCode`, `apiCode`, `versionNo`, `operationId`, `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TryResponse`; trường bắt buộc: `tryId`, `environment`, `mode`, `result`, `status`, `latencyMs`, `headers`, `warnings`.

**Lỗi.** HTTP `401`, `403`, `409`, `413`, `422`, `429`, `502`, `503`, `504`; mã lỗi của thao tác: ERR-15-010, ERR-15-102, ERR-15-103, ERR-15-104, ERR-15-105, ERR-15-106, ERR-15-107, ERR-15-108, ERR-15-109, ERR-15-110, ERR-15-111, ERR-15-112, ERR-15-113, ERR-15-114, ERR-15-115, ERR-15-116, ERR-15-117, ERR-15-118, ERR-15-119, ERR-15-120, ERR-15-121, ERR-15-122, ERR-15-123 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thứ tự kiểm tra cố định (SDD §4.10); production chỉ `GET`, `HEAD`, `dataClass` `PUBLIC` hoặc `INTERNAL`, ghi kiểm toán đồng bộ trước khi gọi (BR-15-023); thân không vào lịch sử (BR-15-024).
:::

#### API-15-073 · Xem một lượt thử

::: dac-ta
**Mục đích.** Xem một lượt thử.

**Phương thức, đường dẫn.** `GET /try/requests/{tryId}`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-035.

**Tham số.** `tryId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TryRecord`; trường bắt buộc: `tryId`, `appCode`, `apiCode`, `operationId`, `environment`, `result`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ siêu dữ liệu, không có thân.
:::

#### API-15-074 · Hạn mức thử còn lại

::: dac-ta
**Mục đích.** Hạn mức thử còn lại.

**Phương thức, đường dẫn.** `GET /try/quota`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-039.

**Tham số.** `appCode` (query, AppCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TryQuota`; trường bắt buộc: `perUserPerMinute`, `perAppPerDay`, `maxBodyKb`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-15-004, ERR-15-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-075 · Lịch sử thử của tôi

::: dac-ta
**Mục đích.** Lịch sử thử của tôi.

**Phương thức, đường dẫn.** `GET /try/history`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn); `ung-dung` (query, AppCode, tùy chọn); `ket-qua` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TryRecordPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-076 · Xóa lịch sử thử của tôi

::: dac-ta
**Mục đích.** Xóa lịch sử thử của tôi.

**Phương thức, đường dẫn.** `DELETE /try/history`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryDeleted`; trường bắt buộc: `deleted`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa mềm.
:::

#### API-15-077 · Danh sách bộ sưu tập yêu cầu

::: dac-ta
**Mục đích.** Danh sách bộ sưu tập yêu cầu.

**Phương thức, đường dẫn.** `GET /try/collections`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CollectionList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-15-004, ERR-15-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-078 · Tạo bộ sưu tập yêu cầu

::: dac-ta
**Mục đích.** Tạo bộ sưu tập yêu cầu.

**Phương thức, đường dẫn.** `POST /try/collections`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CollectionInput`; trường bắt buộc: `name`, `requests`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Collection`; trường bắt buộc: `collectionId`, `name`, `requests`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** ≤ 50 bộ, mỗi bộ ≤ 100 yêu cầu, mỗi yêu cầu ≤ 16 KB.
:::

#### API-15-079 · Sửa bộ sưu tập yêu cầu

::: dac-ta
**Mục đích.** Sửa bộ sưu tập yêu cầu.

**Phương thức, đường dẫn.** `PUT /try/collections/{collectionId}`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** `collectionId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CollectionInput`; trường bắt buộc: `name`, `requests`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Collection`; trường bắt buộc: `collectionId`, `name`, `requests`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-080 · Xóa bộ sưu tập yêu cầu

::: dac-ta
**Mục đích.** Xóa bộ sưu tập yêu cầu.

**Phương thức, đường dẫn.** `DELETE /try/collections/{collectionId}`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-040.

**Tham số.** `collectionId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-081 · Xuất bộ sưu tập (Postman, Bruno, HTTP)

::: dac-ta
**Mục đích.** Xuất bộ sưu tập (Postman, Bruno, HTTP).

**Phương thức, đường dẫn.** `GET /try/collections/{collectionId}/export`.

**Quyền.** `PERM-15-try`.

**FR hiện thực.** FR-15-041.

**Tham số.** `collectionId` (path, Uuid, bắt buộc); `format` (query, string, bắt buộc); `apiCode` (query, ApiCode, tùy chọn); `versionNo` (query, SemVer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportFile`; trường bắt buộc: `format`, `fileName`, `content`; tiêu đề `Content-Disposition`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001, ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không chứa bí mật; tiêu đề xác thực là chỗ giữ.
:::

### Nội bộ gateway sandbox

#### API-15-082 · forward-auth: kiểm tra ứng dụng và hạn mức của lời gọi sandbox

::: dac-ta
**Mục đích.** forward-auth: kiểm tra ứng dụng và hạn mức của lời gọi sandbox.

**Phương thức, đường dẫn.** `POST /internal/v1/sandbox/authorize`.

**Quyền.** Danh tính dịch vụ APISIX (SPIFFE, mTLS mesh).

**FR hiện thực.** FR-15-035, FR-15-039.

**Tham số.** `X-Forwarded-Method` (header, string, bắt buộc); `X-Forwarded-Uri` (header, string, bắt buộc); `X-Forwarded-Host` (header, string, bắt buộc); `X-DH-Try-Id` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuthorizeDecision`; trường bắt buộc: `allowed`, `tenant`, `appCode`, `mode`; tiêu đề `X-DH-App`, `X-DH-Tenant`, `X-DH-Sandbox-Mode`, `X-DH-Profile-Ver`, `X-RateLimit-Remaining`.

**Lỗi.** HTTP `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-15-001, ERR-15-101, ERR-15-102, ERR-15-103, ERR-15-104, ERR-15-111, ERR-15-122 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ APISIX gọi, danh tính SPIFFE, cổng 8081; thời gian chờ 300 ms, `allow_degradation: false`; trả `X-DH-App`, `X-DH-Tenant`, `X-DH-Sandbox-Mode`, `X-DH-Profile-Ver`, `X-RateLimit-*`.
:::

### Thử production (quản trị)

#### API-15-083 · Danh sách trạng thái thử production theo dịch vụ

::: dac-ta
**Mục đích.** Danh sách trạng thái thử production theo dịch vụ.

**Phương thức, đường dẫn.** `GET /admin/try-production`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-042.

**Tham số.** `trang-thai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TryProdPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-084 · Đề xuất bật thử production cho dịch vụ

::: dac-ta
**Mục đích.** Đề xuất bật thử production cho dịch vụ.

**Phương thức, đường dẫn.** `PUT /admin/try-production/{apiCode}`.

**Quyền.** `PERM-15-portal-admin hoặc PERM-15-content-write (SV ○ theo đối tượng)`.

**FR hiện thực.** FR-15-042.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TryProdInput`; trường bắt buộc: `validDays`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TryProdItem`; trường bắt buộc: `apiCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-023, ERR-15-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chờ người khác duyệt (BR-15-021); `validDays` ≤ `15.try.prod-max-days`.
:::

#### API-15-085 · Duyệt bật thử production

::: dac-ta
**Mục đích.** Duyệt bật thử production.

**Phương thức, đường dẫn.** `POST /admin/try-production/{apiCode}:approve`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-042.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TryProdDecision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TryProdItem`; trường bắt buộc: `apiCode`, `state`.

**Lỗi.** HTTP `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-15-006, ERR-15-023, ERR-15-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người đề xuất; phát EVT-15-10.
:::

#### API-15-086 · Tắt thử production

::: dac-ta
**Mục đích.** Tắt thử production.

**Phương thức, đường dẫn.** `POST /admin/try-production/{apiCode}:disable`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-042.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TryProdDisable`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TryProdItem`; trường bắt buộc: `apiCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ cần một người có quyền; hiệu lực ngay.
:::

### Đăng ký và điểm vào nghiệp vụ

#### API-15-087 · Gửi đăng ký sử dụng API production

::: dac-ta
**Mục đích.** Gửi đăng ký sử dụng API production.

**Phương thức, đường dẫn.** `POST /subscriptions`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-15-044.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionInput`; trường bắt buộc: `apiCode`, `versionNo`, `planCode`, `systemCode`, `purpose`, `expectedDailyCalls`, `legalBasis`, `termsAccepted`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `status`, `submittedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-030, ERR-15-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ủy thác PH-02 (FR-02-046) theo danh tính người dùng; cổng không tự duyệt (BR-15-014).
:::

#### API-15-088 · Danh sách đăng ký sử dụng của tổ chức

::: dac-ta
**Mục đích.** Danh sách đăng ký sử dụng của tổ chức.

**Phương thức, đường dẫn.** `GET /subscriptions`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-15-045.

**Tham số.** `trang-thai` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn); `he-thong` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriptionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc từ PH-02.
:::

#### API-15-089 · Chi tiết và dòng thời gian đăng ký sử dụng

::: dac-ta
**Mục đích.** Chi tiết và dòng thời gian đăng ký sử dụng.

**Phương thức, đường dẫn.** `GET /subscriptions/{subscriptionId}`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-15-045.

**Tham số.** `subscriptionId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriptionDetail`; trường bắt buộc: `subscriptionId`, `apiCode`, `status`, `timeline`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-090 · Hủy đăng ký sử dụng

::: dac-ta
**Mục đích.** Hủy đăng ký sử dụng.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:cancel`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-15-045.

**Tham số.** `subscriptionId` (path, Uuid, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionCancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `status`, `submittedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ủy thác PH-02; chỉ khi đăng ký còn hủy được theo PH-02.
:::

#### API-15-091 · Gửi hồ sơ kết nạp HTTT (F-01)

::: dac-ta
**Mục đích.** Gửi hồ sơ kết nạp HTTT (F-01).

**Phương thức, đường dẫn.** `POST /onboarding/applications`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-15-046.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OnboardingInput`; trường bắt buộc: `orgCode`, `systemName`, `contactName`, `contactEmail`, `securityLevel`, `purpose`, `legalBasis`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Onboarding`; trường bắt buộc: `applicationId`, `status`, `submittedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-031, ERR-15-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ủy thác PH-01; lược đồ biểu mẫu nạp từ PH-01.
:::

#### API-15-092 · Danh sách hồ sơ kết nạp của tôi

::: dac-ta
**Mục đích.** Danh sách hồ sơ kết nạp của tôi.

**Phương thức, đường dẫn.** `GET /onboarding/applications`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-15-046.

**Tham số.** `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OnboardingPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-093 · Chi tiết hồ sơ kết nạp

::: dac-ta
**Mục đích.** Chi tiết hồ sơ kết nạp.

**Phương thức, đường dẫn.** `GET /onboarding/applications/{applicationId}`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-15-046.

**Tham số.** `applicationId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Onboarding`; trường bắt buộc: `applicationId`, `status`, `submittedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-094 · Gửi công bố API (F-02)

::: dac-ta
**Mục đích.** Gửi công bố API (F-02).

**Phương thức, đường dẫn.** `POST /publications`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-15-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PublicationInput`; trường bắt buộc: `systemCode`, `dataClass`, `description`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Publication`; trường bắt buộc: `publicationId`, `status`, `lintResults`.

**Lỗi.** HTTP `400`, `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ủy thác PH-02 đăng ký API; trả kết quả lint đặc tả.
:::

#### API-15-095 · Danh sách công bố API của tôi

::: dac-ta
**Mục đích.** Danh sách công bố API của tôi.

**Phương thức, đường dẫn.** `GET /publications`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-15-047.

**Tham số.** `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublicationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-096 · Chi tiết công bố API

::: dac-ta
**Mục đích.** Chi tiết công bố API.

**Phương thức, đường dẫn.** `GET /publications/{publicationId}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-15-047.

**Tham số.** `publicationId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Publication`; trường bắt buộc: `publicationId`, `status`, `lintResults`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-030 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

### Theo dõi của nhà phát triển

#### API-15-097 · Bảng điều khiển cá nhân

::: dac-ta
**Mục đích.** Bảng điều khiển cá nhân.

**Phương thức, đường dẫn.** `GET /dashboard`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-048.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dashboard`; trường bắt buộc: `cards`, `generatedAt`.

**Lỗi.** HTTP `401`, `502`; mã lỗi của thao tác: ERR-15-030, ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thẻ lỗi một phần trả `partial[]` thay vì hỏng cả trang.
:::

#### API-15-098 · Thống kê lượt gọi và lỗi của ứng dụng

::: dac-ta
**Mục đích.** Thống kê lượt gọi và lỗi của ứng dụng.

**Phương thức, đường dẫn.** `GET /apps/{appCode}/stats`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-049.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `khoang` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppStats`; trường bắt buộc: `range`, `series`, `totals`, `byApi`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc PH-13 (`metrics:portal-read`); bộ lọc `app_code` cố định ở máy chủ.
:::

#### API-15-099 · Nhật ký gọi của ứng dụng (đã che dữ liệu)

::: dac-ta
**Mục đích.** Nhật ký gọi của ứng dụng (đã che dữ liệu).

**Phương thức, đường dẫn.** `GET /apps/{appCode}/logs`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-050.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn); `trang-thai` (query, string, tùy chọn); `trace` (query, TraceId, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppLogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không có thân, chỉ giữ 30 ngày (BR-15-024).
:::

#### API-15-100 · Chi tiết một bản ghi nhật ký gọi

::: dac-ta
**Mục đích.** Chi tiết một bản ghi nhật ký gọi.

**Phương thức, đường dẫn.** `GET /apps/{appCode}/logs/{logId}`.

**Quyền.** `PERM-15-app`.

**FR hiện thực.** FR-15-050.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `logId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AppLog`; trường bắt buộc: `logId`, `time`, `apiCode`, `method`, `path`, `status`, `latencyMs`.

**Lỗi.** HTTP `401`, `403`, `404`, `502`; mã lỗi của thao tác: ERR-15-001, ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-101 · Danh sách theo dõi thông báo thay đổi API

::: dac-ta
**Mục đích.** Danh sách theo dõi thông báo thay đổi API.

**Phương thức, đường dẫn.** `GET /notification-subscriptions`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-051.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotifSubList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-15-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-102 · Đăng ký hoặc sửa theo dõi thông báo của một API

::: dac-ta
**Mục đích.** Đăng ký hoặc sửa theo dõi thông báo của một API.

**Phương thức, đường dẫn.** `PUT /notification-subscriptions/{apiCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-051.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotifSubInput`; trường bắt buộc: `channels`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotifSub`; trường bắt buộc: `apiCode`, `channels`.

**Lỗi.** HTTP `400`, `401`, `404`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Loại bắt buộc (BR-15-027) không tắt được.
:::

#### API-15-103 · Bỏ theo dõi thông báo của một API

::: dac-ta
**Mục đích.** Bỏ theo dõi thông báo của một API.

**Phương thức, đường dẫn.** `DELETE /notification-subscriptions/{apiCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-051.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-104 · Hộp thông báo

::: dac-ta
**Mục đích.** Hộp thông báo.

**Phương thức, đường dẫn.** `GET /inbox`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-052.

**Tham số.** `loai` (query, string, tùy chọn); `da-doc` (query, boolean, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboxPage`; trường bắt buộc: `items`, `unreadCount`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giữ 90 ngày.
:::

#### API-15-105 · Đánh dấu một thông báo đã đọc

::: dac-ta
**Mục đích.** Đánh dấu một thông báo đã đọc.

**Phương thức, đường dẫn.** `POST /inbox/{messageId}:read`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-052.

**Tham số.** `messageId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboxMessage`; trường bắt buộc: `messageId`, `kind`, `title`, `read`, `createdAt`.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-106 · Đánh dấu tất cả thông báo đã đọc

::: dac-ta
**Mục đích.** Đánh dấu tất cả thông báo đã đọc.

**Phương thức, đường dẫn.** `POST /inbox:read-all`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-052.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReadAllResult`; trường bắt buộc: `updated`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-15-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-140 · Số thông báo chưa đọc

::: dac-ta
**Mục đích.** Số thông báo chưa đọc.

**Phương thức, đường dẫn.** `GET /inbox/unread-count`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-052.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UnreadCount`; trường bắt buộc: `unread`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-15-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhẹ hơn API-15-104 cho chuông thông báo; giao diện hỏi định kỳ 60 giây (FR-15-052).
:::

### Hỗ trợ và phản hồi

#### API-15-107 · Danh sách hỏi đáp của một API

::: dac-ta
**Mục đích.** Danh sách hỏi đáp của một API.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}/questions`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-053.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuestionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `404`; mã lỗi của thao tác: ERR-15-001, ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-108 · Gửi câu hỏi hoặc báo lỗi tài liệu của một API

::: dac-ta
**Mục đích.** Gửi câu hỏi hoặc báo lỗi tài liệu của một API.

**Phương thức, đường dẫn.** `POST /catalog/apis/{apiCode}/questions`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-053.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `QuestionInput`; trường bắt buộc: `subject`, `body`, `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Question`; trường bắt buộc: `questionId`, `apiCode`, `subject`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `404`, `429`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Văn bản thuần ≤ 2.000 ký tự; chuyển đầu mối chủ dịch vụ.
:::

#### API-15-109 · Gửi đánh giá trang hoặc phản hồi

::: dac-ta
**Mục đích.** Gửi đánh giá trang hoặc phản hồi.

**Phương thức, đường dẫn.** `POST /feedback`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FeedbackInput`; trường bắt buộc: `targetType`, `targetCode`, `rating`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `FeedbackAck`; trường bắt buộc: `feedbackId`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `429`; mã lỗi của thao tác: ERR-15-003, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-110 · Tạo phiếu hỗ trợ

::: dac-ta
**Mục đích.** Tạo phiếu hỗ trợ.

**Phương thức, đường dẫn.** `POST /support/tickets`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TicketInput`; trường bắt buộc: `kind`, `subject`, `body`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Ticket`; trường bắt buộc: `ticketCode`, `kind`, `status`, `subject`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `404`, `429`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiếu ≤ 4.000 ký tự; phát EVT-15-12.
:::

#### API-15-111 · Danh sách phiếu hỗ trợ của tôi

::: dac-ta
**Mục đích.** Danh sách phiếu hỗ trợ của tôi.

**Phương thức, đường dẫn.** `GET /support/tickets`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-054.

**Tham số.** `trang-thai` (query, string, tùy chọn); `loai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TicketPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-112 · Chi tiết phiếu hỗ trợ

::: dac-ta
**Mục đích.** Chi tiết phiếu hỗ trợ.

**Phương thức, đường dẫn.** `GET /support/tickets/{ticketCode}`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-054.

**Tham số.** `ticketCode` (path, TicketCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TicketDetail`; trường bắt buộc: `ticketCode`, `kind`, `status`, `subject`, `messages`.

**Lỗi.** HTTP `401`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tin nhắn nội bộ của người xử lý bị ẩn với người gửi.
:::

#### API-15-113 · Nhắn thêm vào phiếu hỗ trợ

::: dac-ta
**Mục đích.** Nhắn thêm vào phiếu hỗ trợ.

**Phương thức, đường dẫn.** `POST /support/tickets/{ticketCode}/messages`.

**Quyền.** Người dùng đã đăng nhập.

**FR hiện thực.** FR-15-054.

**Tham số.** `ticketCode` (path, TicketCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TicketMessageInput`; trường bắt buộc: `body`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TicketMessage`; trường bắt buộc: `messageId`, `author`, `body`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `404`, `409`, `429`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-029, ERR-15-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiếu `CLOSED` trả `409` (ERR-15-029).
:::

#### API-15-114 · Danh sách phiếu hỗ trợ cần xử lý

::: dac-ta
**Mục đích.** Danh sách phiếu hỗ trợ cần xử lý.

**Phương thức, đường dẫn.** `GET /admin/support/tickets`.

**Quyền.** `PERM-15-support`.

**FR hiện thực.** FR-15-055.

**Tham số.** `trang-thai` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TicketPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** SV (○) chỉ thấy phiếu của API tổ chức mình.
:::

#### API-15-115 · Chuyển trạng thái, trả lời phiếu hỗ trợ

::: dac-ta
**Mục đích.** Chuyển trạng thái, trả lời phiếu hỗ trợ.

**Phương thức, đường dẫn.** `POST /admin/support/tickets/{ticketCode}:transition`.

**Quyền.** `PERM-15-support`.

**FR hiện thực.** FR-15-055.

**Tham số.** `ticketCode` (path, TicketCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TicketTransition`; trường bắt buộc: `status`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Ticket`; trường bắt buộc: `ticketCode`, `kind`, `status`, `subject`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-15-001, ERR-15-003, ERR-15-029, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả lời hiện cho người gửi; ghi chú nội bộ thì không.
:::

### Quản trị cổng

#### API-15-116 · Xem cấu hình nhận diện cổng

::: dac-ta
**Mục đích.** Xem cấu hình nhận diện cổng.

**Phương thức, đường dẫn.** `GET /admin/branding`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-056.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Branding`; trường bắt buộc: `portalName`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-15-004, ERR-15-005, ERR-15-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-117 · Sửa cấu hình nhận diện cổng

::: dac-ta
**Mục đích.** Sửa cấu hình nhận diện cổng.

**Phương thức, đường dẫn.** `PUT /admin/branding`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-056.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BrandingInput`; trường bắt buộc: `portalName`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Branding`; trường bắt buộc: `portalName`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi kiểm toán `CHANGE_SETTING`.
:::

#### API-15-118 · Tải logo cổng

::: dac-ta
**Mục đích.** Tải logo cổng.

**Phương thức, đường dẫn.** `POST /admin/branding/logo`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `LogoUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LogoUploaded`; trường bắt buộc: `logoUrl`, `size`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi của thao tác: ERR-15-024, ERR-15-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PNG hoặc WebP ≤ 512 KB, từ 128 px.
:::

#### API-15-119 · Xem tham số cổng

::: dac-ta
**Mục đích.** Xem tham số cổng.

**Phương thức, đường dẫn.** `GET /admin/settings`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-057.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-15-004, ERR-15-005, ERR-15-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-120 · Sửa tham số cổng

::: dac-ta
**Mục đích.** Sửa tham số cổng.

**Phương thức, đường dẫn.** `PUT /admin/settings`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-057.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsInput`; trường bắt buộc: `items`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-15-003, ERR-15-006, ERR-15-034 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không vượt trần do PA đặt; ghi kiểm toán `CHANGE_SETTING`.
:::

#### API-15-121 · Danh sách tài khoản dh-dev

::: dac-ta
**Mục đích.** Danh sách tài khoản dh-dev.

**Phương thức, đường dẫn.** `GET /admin/dev-accounts`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-058.

**Tham số.** `q` (query, string, tùy chọn); `trang-thai` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DevAccountPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-122 · Duyệt tài khoản dh-dev

::: dac-ta
**Mục đích.** Duyệt tài khoản dh-dev.

**Phương thức, đường dẫn.** `POST /admin/dev-accounts/{userId}:approve`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-058.

**Tham số.** `userId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DevAccount`; trường bắt buộc: `userId`, `email`, `fullName`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-15-003, ERR-15-020, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cấp `tenantGrants`; tạo người dùng ở realm `dh-dev`; phát EVT-15-07.
:::

#### API-15-123 · Từ chối tài khoản dh-dev

::: dac-ta
**Mục đích.** Từ chối tài khoản dh-dev.

**Phương thức, đường dẫn.** `POST /admin/dev-accounts/{userId}:reject`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-058.

**Tham số.** `userId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DevAccount`; trường bắt buộc: `userId`, `email`, `fullName`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-124 · Khóa tài khoản dh-dev

::: dac-ta
**Mục đích.** Khóa tài khoản dh-dev.

**Phương thức, đường dẫn.** `POST /admin/dev-accounts/{userId}:lock`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-059.

**Tham số.** `userId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LockInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DevAccount`; trường bắt buộc: `userId`, `email`, `fullName`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi kiểm toán `LOCK_ACCOUNT`; phiên bị thu hồi.
:::

#### API-15-125 · Mở khóa tài khoản dh-dev

::: dac-ta
**Mục đích.** Mở khóa tài khoản dh-dev.

**Phương thức, đường dẫn.** `POST /admin/dev-accounts/{userId}:unlock`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-059.

**Tham số.** `userId` (path, Uuid, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UnlockInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DevAccount`; trường bắt buộc: `userId`, `email`, `fullName`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi kiểm toán `UNLOCK_ACCOUNT`.
:::

#### API-15-126 · Tạm khóa ứng dụng sandbox

::: dac-ta
**Mục đích.** Tạm khóa ứng dụng sandbox.

**Phương thức, đường dẫn.** `POST /admin/apps/{appCode}:suspend`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-059.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LockInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-017, ERR-15-022, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ứng dụng không thử được, không cấp thông tin xác thực mới; phát EVT-15-02.
:::

#### API-15-127 · Mở khóa ứng dụng sandbox

::: dac-ta
**Mục đích.** Mở khóa ứng dụng sandbox.

**Phương thức, đường dẫn.** `POST /admin/apps/{appCode}:resume`.

**Quyền.** `PERM-15-dev-approve`.

**FR hiện thực.** FR-15-059.

**Tham số.** `appCode` (path, AppCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UnlockInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AppDetail`; trường bắt buộc: `appCode`, `name`, `ownerType`, `status`, `createdAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`; mã lỗi của thao tác: ERR-15-003, ERR-15-017, ERR-15-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-128 · Nhật ký truy cập và thử API của cổng

::: dac-ta
**Mục đích.** Nhật ký truy cập và thử API của cổng.

**Phương thức, đường dẫn.** `GET /admin/audit`.

**Quyền.** `PERM-15-audit-read`.

**FR hiện thực.** FR-15-060.

**Tham số.** `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `hanh-dong` (query, string, tùy chọn); `nguoi-dung` (query, string, tùy chọn); `api` (query, ApiCode, tùy chọn); `ung-dung` (query, AppCode, tùy chọn); `ket-qua` (query, string, tùy chọn); `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc PH-13; việc xem cũng ghi `VIEW_AUDIT`.
:::

#### API-15-129 · Báo cáo sử dụng cổng

::: dac-ta
**Mục đích.** Báo cáo sử dụng cổng.

**Phương thức, đường dẫn.** `GET /admin/usage-report`.

**Quyền.** `PERM-15-audit-read`.

**FR hiện thực.** FR-15-060.

**Tham số.** `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageReport`; trường bắt buộc: `from`, `to`, `summary`.

**Lỗi.** HTTP `400`, `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-130 · Xuất nhật ký kiểm toán của cổng

::: dac-ta
**Mục đích.** Xuất nhật ký kiểm toán của cổng.

**Phương thức, đường dẫn.** `POST /admin/audit:export`.

**Quyền.** `PERM-15-audit-read`.

**FR hiện thực.** FR-15-060.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AuditExportInput`; trường bắt buộc: `format`, `from`, `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportAccepted`; trường bắt buộc: `exportId`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất nền; ghi `EXPORT_AUDIT`.
:::

#### API-15-131 · Chạy đồng bộ danh mục với PH-02

::: dac-ta
**Mục đích.** Chạy đồng bộ danh mục với PH-02.

**Phương thức, đường dẫn.** `POST /admin/sync:run`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-061.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncRunInput`; trường bắt buộc: `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; trường bắt buộc: `runId`, `kind`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `502`; mã lỗi của thao tác: ERR-15-003, ERR-15-030, ERR-15-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Một lần chạy tại một thời điểm (ERR-15-035).
:::

#### API-15-132 · Lịch sử các lần đồng bộ

::: dac-ta
**Mục đích.** Lịch sử các lần đồng bộ.

**Phương thức, đường dẫn.** `GET /admin/sync/runs`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-061.

**Tham số.** `trang` (query, integer, tùy chọn); `co` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRunPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-15-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-133 · Chạy đối soát danh mục với PH-02

::: dac-ta
**Mục đích.** Chạy đối soát danh mục với PH-02.

**Phương thức, đường dẫn.** `POST /admin/reconciliations`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-061.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileInput`; trường bắt buộc: `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReconcileReport`; trường bắt buộc: `runId`, `state`.

**Lỗi.** HTTP `401`, `403`, `409`, `502`; mã lỗi của thao tác: ERR-15-030, ERR-15-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `fix=true` sửa bản sao theo PH-02; không bao giờ sửa PH-02.
:::

#### API-15-134 · Báo cáo đối soát gần nhất

::: dac-ta
**Mục đích.** Báo cáo đối soát gần nhất.

**Phương thức, đường dẫn.** `GET /admin/reconciliations/latest`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-061.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReconcileReport`; trường bắt buộc: `runId`, `state`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-135 · Tải gói di trú nội dung portal hệ cũ

::: dac-ta
**Mục đích.** Tải gói di trú nội dung portal hệ cũ.

**Phương thức, đường dẫn.** `POST /admin/migrations`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-062.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `MigrationUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Migration`; trường bắt buộc: `migrationId`, `state`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-15-024, ERR-15-026, ERR-15-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** ZIP ≤ 50 MB, quét ClamAV, giải nén an toàn; chỉ lập báo cáo xem trước.
:::

#### API-15-136 · Xem tiến độ và báo cáo xem trước di trú

::: dac-ta
**Mục đích.** Xem tiến độ và báo cáo xem trước di trú.

**Phương thức, đường dẫn.** `GET /admin/migrations/{migrationId}`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-062.

**Tham số.** `migrationId` (path, Uuid, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Migration`; trường bắt buộc: `migrationId`, `state`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-15-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-15-137 · Xác nhận áp dụng gói di trú

::: dac-ta
**Mục đích.** Xác nhận áp dụng gói di trú.

**Phương thức, đường dẫn.** `POST /admin/migrations/{migrationId}:confirm`.

**Quyền.** `PERM-15-portal-admin`.

**FR hiện thực.** FR-15-062.

**Tham số.** `migrationId` (path, Uuid, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationConfirm`; trường bắt buộc: `confirm`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Migration`; trường bắt buộc: `migrationId`, `state`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-15-022, ERR-15-026, ERR-15-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ ghi `DRAFT` sau xác nhận (BR-15-012).
:::

<!-- gen:dac-ta-api:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Nhóm PH-15 | Bản đầu: 137 operation, EVT-15-01…14 và 10 EVT-02 tiêu thụ, ERR-15, OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm |
| 0.2 | 2026-11-26 | Nhóm PH-15 | Đồng bộ FRS 0.2: thêm API-15-138…142 (142 operation); quyền theo đối tượng của API-15-069, 070, 084; mục 10 ghi đề nghị đã hấp thụ; sinh lại và kiểm |
