---
ma_tai_lieu: D03-04-PH12
ten: Đặc tả API và sự kiện phân hệ PH-12 Định danh và phân quyền
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, thư viện PEP, APISIX, giao diện; ATTT; đơn vị kết nối; hội đồng thẩm định
phan_he: PH-12
mo_ta: Đặc tả 113 endpoint REST và OIDC, 16 sự kiện Kafka và 66 mã lỗi của phân hệ Định danh và phân quyền, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH12 FRS; D02-04-PH12 Use case; D03-02-PH12 SDD; D03-03-PH12 CSDL; D03-07 ATTT; D02-08 Ma trận phân quyền; D04-01 Quy ước mã
---

# D03-04-PH12 · Đặc tả API và sự kiện Định danh và phân quyền

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu này là hợp đồng giao diện của PH-12, phân hệ trả lời "người gọi là ai" (Keycloak) và "người gọi được làm gì" (OPA) cho toàn bộ Datahub. Mọi phân hệ khác, cổng APISIX và các đơn vị kết nối gọi PH-12 qua hợp đồng này; kỹ sư dựa vào đó để viết mã mà không cần hỏi lại, kiểm thử viên dựa vào đó để viết ca kiểm thử hợp đồng.

**Phạm vi.** PH-12 công bố 113 operation (API-12-001…113) ở ba mặt:

- **API quản trị** `/api/iam/v1`: 103 operation cho người dùng, vai trò, nhóm, quyền có thời hạn, rà soát quyền, liên kết định danh ngoài, client của hệ thống thông tin (HTTT), tài khoản dịch vụ, realm, chính sách và gói chính sách, nhật ký, cảnh báo, báo cáo, tham số.
- **API quyết định ủy quyền** `/api/authz/v1`: 3 operation (`decide`, `decide:batch`, `xacml`), hợp đồng trung tâm giữa bên thực thi (PEP) và OPA.
- **Điểm cuối OIDC chuẩn của Keycloak** `/realms/dh-{tenant}/protocol/openid-connect/*`: 7 operation (khám phá, cấp quyền, token, JWKS, đăng xuất, thu hồi token, userinfo), lỗi theo RFC 6749.

Ngoài ra 16 sự kiện Kafka (EVT-12-01…16) và 66 mã lỗi (ERR-12-001…047, 101…125, một số mã chỉ phát sinh ở Keycloak). Hợp đồng máy đọc được:

- [`ph12/openapi-iam.yaml`](ph12/openapi-iam.yaml): OpenAPI 3.1, 136 lược đồ, đã qua `openapi-spec-validator`; các ví dụ trong lược đồ được kiểm khớp bằng [`check_contracts.py`](ph12/tools/check_contracts.py).
- [`ph12/asyncapi-iam.yaml`](ph12/asyncapi-iam.yaml): AsyncAPI 3.0, 16 kênh, đã qua `@asyncapi/parser` 3 không lỗi.

Cả hai sinh từ bảng mã [`ph12/tools/spec.py`](ph12/tools/spec.py) bằng `gen_openapi.py`, `gen_asyncapi.py`; bảng ở chương 3, 4, 6 sinh bằng `gen_md.py`, chương 10 sinh bằng `build/tools/sinh_dac_ta_api.py`, nên các phần không lệch nhau.

**Căn cứ.** Công văn 631/THH-THHT (CMP-LAW-09: đăng nhập một lần OIDC, SAML 2, xác thực nhiều yếu tố, phân quyền XACML), TCVN 14423:2026 và NĐ 331/2026 (CMP-LAW-06, 08: mật khẩu, khóa phiên, vô hiệu tài khoản, nhật ký truy cập), Luật BVDLCN 91/2025 (CMP-LAW-05: hạn chế truy cập, ghi vết). Biện pháp kỹ thuật theo SEC-20…29 của D03-07; quyết định kiến trúc ADR-006 (Keycloak và OPA), ADR-041 (chống trùng), ADR-042 (outbox), ADR-069 (máy trạng thái phiên bản và bốn mắt).

**Những điểm hội đồng cần lưu ý.**

1. **Từ chối là kết quả hợp lệ, lỗi cũng là từ chối.** API quyết định trả `200` kèm `allow=false` và một lý do chuẩn; khi OPA lỗi, quá tải hoặc chưa nạp gói, bên gọi phải xử lý như từ chối (ERR-12-103, 104; BR-12-006).
2. **Không API nào trả mật khẩu, bí mật client hay khóa riêng.** Bí mật chỉ đi vào qua trường `writeOnly` và đi ra qua địa chỉ bọc dùng một lần (`secretHandover`); kiểm tra hợp đồng chặn các trường bí mật ở mọi lược đồ khác.
3. **Máy gọi máy dùng token dịch vụ với bảy scope `iam:*`**, tách khỏi quyền người dùng `PERM-12-*`; mỗi operation ghi rõ điều kiện gọi.
4. **Quyền chính sách đi qua bốn mắt.** Phát hành chính sách cần kiểm thử, chạy khô trên đúng nội dung, người duyệt khác người soạn, mức xác thực 3; quá ngưỡng đổi quyết định cần xác nhận bổ sung (ERR-12-029).
5. **Mọi lệnh đổi trạng thái có `If-Match`, mọi lệnh tạo có `Idempotency-Key`**, cùng quy ước với PH-04, PH-05, PH-19.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation | 113 (API-12-001…113): 103 quản trị, 3 quyết định, 7 OIDC |
| Operation ghi có `If-Match` | 31 |
| Operation tạo có `Idempotency-Key` | 29 |
| Operation đòi xác thực bước lên | 52 (39 mức 2, 13 mức 3) |
| Sự kiện | 16 (EVT-12-01…16): 15 qua outbox, 1 do Keycloak phát |
| Mã lỗi | 66: 47 control plane, 19 runtime |
| Lược đồ OpenAPI | 136 |
| FR có API | 57 trong 62; 5 FR (007, 008, 010, 021, 050) chỉ giao diện hoặc tác vụ nền (mục 3.3) |
| Câu hỏi mở | 5 (Q12-55…59) |

: Con số chính của đặc tả API PH-12

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả giao diện lập trình của PH-12: các endpoint REST ở mặt phẳng điều khiển (`dh-platform`, module `iam`), API quyết định ủy quyền, các điểm cuối OIDC của Keycloak mà PH-12 cấu hình và công bố, sự kiện Kafka và bảng mã lỗi ERR-12. Nguồn chuẩn là hai tệp máy đọc được; bảng danh mục ở chương 3, chương 10 (đặc tả từng endpoint, mỗi endpoint một bảng 10 mục) đều sinh từ OpenAPI.

Tài liệu không đặc tả: (a) API của Keycloak ngoài bảy điểm cuối OIDC kể trên (Admin REST do `dh-platform` gọi nội bộ, SDD mục 4.5); (b) giao diện OPA `POST /v1/data/dh/authz/decision` (hợp đồng đầu vào và đầu ra ở SDD mục 3.4, chương này chỉ dẫn lại); (c) màn hình, ở D03-06-PH12.

### 0.2. Người đọc và cách đọc

Bảng sau chỉ mỗi nhóm người đọc nên đọc những chương nào của tài liệu này.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-platform` (module `iam`), giao diện | Chương 1, 2, 3, 10 |
| Kỹ sư APISIX (PH-03), thư viện PEP, `dh-runtime` | Chương 1, 2, 3.4 (quyết định), 4, 5 |
| Kỹ sư PH-01, PH-15, PH-20 (gọi cấp client, realm) | Chương 2.3, 3.4, 5 |
| Kiểm thử viên | Chương 6, 7, 10 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Bảng sau giải thích các thuật ngữ và chữ viết tắt dùng riêng trong tài liệu API của PH-12; thuật ngữ chung theo D00-01 §2.

| Thuật ngữ | Giải thích |
|---|---|
| PEP, PDP | Điểm thực thi và điểm quyết định chính sách. PEP là APISIX và thư viện PEP trong đơn vị triển khai (DU); PDP là OPA |
| OPA, Rego | Open Policy Agent, bộ đánh giá chính sách; Rego là ngôn ngữ viết chính sách |
| OIDC, PKCE | OpenID Connect; Proof Key for Code Exchange (RFC 7636) bảo vệ luồng Authorization Code |
| BFF | Backend-for-Frontend: máy chủ trung gian giữ token, trình duyệt chỉ giữ cookie phiên |
| `acr`, step-up | Mức xác thực của token (1, 2, 3); xác thực bước lên là yêu cầu người dùng xác thực mạnh hơn hoặc gần hơn trước thao tác nhạy cảm |
| Realm | Không gian định danh riêng của một tenant ở Keycloak, tên `dh-{mã tenant chữ thường}` |
| Danh sách chặn | Danh sách thu hồi truy cập tức thời (`sub`, `client`, `jti` kèm mốc `notBefore`) mà APISIX và DU kéo để từ chối token chưa hết hạn |
| Địa chỉ bọc | Địa chỉ dùng một lần (OpenBao cubbyhole) để đầu mối kỹ thuật nhận bí mật client; phản hồi API không chứa bí mật |
| Chạy khô | Phát lại lưu lượng mẫu qua phiên bản chính sách mới để đo số quyết định đổi trước khi phát hành |
| ETag, `If-Match` | Số phiên bản đối tượng ở tiêu đề phản hồi, và điều kiện ghi lạc quan ở yêu cầu |

: Thuật ngữ và chữ viết tắt

Thuật ngữ chung theo D00-01 §2 và FRS PH-12 §1.4.

### 0.4. Tài liệu tham chiếu

Bảng sau liệt kê các tài liệu mà tài liệu API này dựa vào hoặc cung cấp đầu vào cho, kèm mục đích dùng.

| Tài liệu | Dùng cho |
|---|---|
| [D02-03-PH12 FRS](../../02-yeu-cau/frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) | 62 FR, bảng API §9.4, mã lỗi §9.1, thông báo §9.2, sự kiện §9.3 |
| [D02-04-PH12 Use case](../../02-yeu-cau/use-case/D02-04-PH12-use-case-dinh-danh-phan-quyen.md) | Luồng người dùng gọi API |
| [D03-02-PH12 SDD](../sdd/D03-02-PH12-sdd-dinh-danh-phan-quyen.md) | Giao diện công bố (§3.3), hợp đồng quyết định (§3.4), DTO (§3.5), outbox (§8.2) |
| [D03-03-PH12 CSDL](../csdl/D03-03-PH12-csdl-dinh-danh-phan-quyen.md) | Bảng, cột phía sau mỗi lược đồ |
| [D02-08 Ma trận phân quyền](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md) | Vai trò `ROLE-*`, quyền `PERM-12-*` |
| [D03-07 ATTT](../attt/D03-07-thiet-ke-attt.md) | SEC-20…29 (IAM) |
| [D03-10 Đa tenant](../D03-10-thiet-ke-da-tenant.md) | Mã tenant, tiền tố topic, hạn mức |
| D04-01 | Quy ước API, RFC 9457, chống trùng |

: Tài liệu tham chiếu

### 0.5. Cấu trúc tài liệu

Bảng sau nêu nội dung của từng chương trong tài liệu này để người đọc tìm nhanh phần cần dùng.

| Chương | Nội dung |
|---|---|
| 1 | Quy ước chung: đường gốc, phiên bản, phân trang, khóa lạc quan, chống trùng, lỗi |
| 2 | Xác thực và phân quyền cho người dùng, máy và bên quyết định |
| 3 | Danh mục 113 endpoint, phủ FR, ví dụ yêu cầu và phản hồi |
| 4 | Danh mục 16 sự kiện |
| 5 | Hợp đồng với phân hệ khác và bên ngoài |
| 6 | Bảng mã lỗi ERR-12, thông báo hiển thị |
| 7 | Kiểm tra hợp đồng trong CI |
| 8 | Ánh xạ từ hệ cũ |
| 9 | Câu hỏi mở |
| 10 | Đặc tả từng endpoint (sinh tự động) |
| Đề nghị đồng bộ | Việc ở tài liệu dùng chung và phân hệ khác |

: Cấu trúc tài liệu

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho API quản trị `/api/iam/v1` và API quyết định `/api/authz/v1`. Điểm cuối OIDC của Keycloak theo chuẩn OAuth 2.1 và RFC 6749, chỉ khác ở các điểm nêu trong bảng.

| Mục | Quy ước |
|---|---|
| Đường gốc | API quản trị `/api/iam/v1`; API quyết định `/api/authz/v1`; OIDC `/realms/dh-{tenant}/protocol/openid-connect/`. Người dùng đi qua BFF console của tenant; phân hệ khác, APISIX và DU gọi dịch vụ `dh-platform.dh-control.svc` trong cụm |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2` chạy song song ít nhất 6 tháng (oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1`). Riêng `/api/authz/v1` coi như hợp đồng nền tảng: không đổi cấu trúc `DecisionRequest`, `DecisionResult` trong `v1` |
| Tenant | Lấy từ claim `tenant` của token; không bao giờ từ đường dẫn, thân hay tiêu đề `X-DH-Tenant` khi gọi từ ngoài mesh (SDD §3.4). Ngoại lệ: API-12-080…085 và API-12-045…046 có mã tenant đích trong thân hoặc đường dẫn vì gọi bởi PH-20 ở tenant `PLATFORM` |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:lock`, `:approve`, `:rotate`) theo AIP-136; hành động không đổi trạng thái (`:test`, `:plan`) cũng dùng `POST` |
| Khóa lạc quan | `GET` chi tiết trả `ETag` (đúng bằng cột `version` của bảng); `PATCH`, `PUT`, `DELETE` và hành động đổi trạng thái bắt buộc `If-Match`; lệch trả ERR-12-044 (`412`) kèm `currentVersion` |
| Chống trùng | `POST` tạo hoặc có tác dụng phụ bắt buộc `Idempotency-Key` (16…128 ký tự), bảng `idempotency_key` giữ khóa, băm thân và phản hồi 24 giờ; gọi lại cùng khóa cùng thân trả lại đúng phản hồi cũ; cùng khóa khác thân trả ERR-12-045 (`422`). Lời gọi của saga (PH-01, PH-20) dùng khóa này để tiếp tục tiến trình dở; phản hồi lưu theo khóa của API cấp client không chứa `wrappingToken`, chỉ chứa `handoverId` |
| Phân trang | `page` (từ 1), `size` (10, 20, 50, 100; mặc định 20); phản hồi `page`, `size`, `totalElements`, `totalPages`. Ngoài miền trả ERR-12-003 |
| Sắp xếp, lọc | `sort=truong:asc\|desc`; lọc bằng tham số riêng từng danh sách (ví dụ `state`, `orgCode`, `roleCode`); tìm `q` không phân biệt dấu |
| Lỗi | `application/problem+json` theo RFC 9457: `type` (`https://datahub.gov.vn/errors/ERR-12-nnn`), `title`, `status`, `detail`, `code`, `traceId`; thêm `errors[]` (theo trường), `conflictingRoles` (ERR-12-009), `currentVersion` (ERR-12-044), `retryAfterSeconds` (ERR-12-037, 125). Điểm cuối OIDC trả `error`, `error_description` theo RFC 6749; lỗi do CSDL chốt (trigger ném `SQLSTATE` `P12nn`, CHECK, khóa duy nhất) được ánh xạ sang `ERR-12-nnn` theo D03-03-PH12 mục 3.44 |
| Hành động được phép | Đối tượng trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm (ví dụ không cho nút "Mở khóa" khi tài khoản `ACTIVE`) |
| Truy vết | `traceparent` W3C xuyên BFF, `dh-platform`, Kafka, OPA; `traceId` của lỗi trùng `trace_id` ở PH-13 |
| Truy cập liên tenant | Yêu cầu tới `/api/platform/` có thể mang tiêu đề `X-DH-Grant-Id` (tùy chọn) chứa `grantId` của quyền có thời hạn; chỉ để ghi vết, OPA không tin tiêu đề mà tra quyền theo dữ liệu `data.dh.platform.grants` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` |
| Tiến trình dài | Nhập người dùng, chạy khô, đồng bộ LDAP, xoay bí mật, tạo realm trả `202` kèm `Location` và `Accepted.taskId`; kết quả cuối qua `GET` của tài nguyên hoặc sự kiện |
| Giới hạn tần suất | Thao tác ghi nhạy cảm (nhập, đặt lại yếu tố, xoay bí mật, cấp client) bị giới hạn theo người gọi; vượt trả ERR-12-037 (`429`) kèm `Retry-After`. Cấp token: `12.client.token-rate-limit` mỗi client (ERR-12-125) |
| Bí mật | Không phản hồi nào chứa mật khẩu, bí mật client, khóa riêng, mã bọc ở dạng đọc được; trường nhận bí mật là `writeOnly` và không vào log, sự kiện (BR-12-023) |
| Mã thời gian | RFC 3339 UTC (`2026-11-26T08:30:00Z`); ngày `yyyy-MM-dd` |

: Quy ước chung của API PH-12

Phản hồi lỗi mẫu (ERR-12-009, gán vai trò xung đột tách nhiệm vụ):

```json
{ "type": "https://datahub.gov.vn/errors/ERR-12-009", "title": "Cặp vai trò xung đột tách nhiệm vụ", "status": 409,
  "detail": "Không được giữ cùng lúc INTEGRATION_ENGINEER và INTEGRATION_APPROVER.", "code": "ERR-12-009",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "conflictingRoles": ["INTEGRATION_ENGINEER", "INTEGRATION_APPROVER"] }
```

## 2. Xác thực và phân quyền

PH-12 vừa là nơi cấp định danh vừa là một dịch vụ cần được bảo vệ, nên chương này mô tả hai chiều: cách người và máy chứng minh danh tính khi gọi API của PH-12, và cách PH-12 tự dùng cùng cơ chế ủy quyền mà nó cung cấp cho phần còn lại. Chương theo SEC-21, 24, 25, 26.

### 2.1. Người dùng

Người dùng đăng nhập bằng OIDC Authorization Code với PKCE `S256` qua BFF của `dh-console` (SEC-21); trình duyệt không giữ token. BFF gắn access token (ES256, sống tối đa 5 phút) vào lời gọi `/api/iam/v1`. Quyền gọi là mã `PERM-12-*` suy từ vai trò của người dùng theo ma trận D02-08; ánh xạ vai trò sang quyền nằm ở dữ liệu của OPA, không ở mã của `dh-platform`.

Thao tác ghi cần mức xác thực tối thiểu: **mức 2** (mật khẩu cộng TOTP hoặc WebAuthn) cho 40 operation ghi quản trị; **mức 3** (WebAuthn, `userVerification=required`) cho 13 operation có rủi ro cao (phát hành, thu hồi, quay lui chính sách; tạo, xoay tài khoản dịch vụ; khóa realm, áp lại cấu hình; duyệt quyền có thời hạn; thu hồi client). Token phải có `auth_time` không quá `12.mfa.stepup-minutes` (5 phút). Thiếu một trong hai: `401` ERR-12-120 kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", acr_values="…"`; BFF chuyển người dùng sang xác thực bước lên rồi gọi lại. Mức tối thiểu của từng operation ở khóa `x-datahub-acr` của OpenAPI, và danh sách đã được cán bộ ATTT cùng quản trị nền tảng duyệt, ghi thành bảng ở D02-03-PH12 mục 4.8 (chủ đầu tư chốt 27/11/2026).

### 2.2. Máy gọi máy

HTTT thành viên, phân hệ và DU lấy token bằng `client_credentials`; client được xác thực bằng chứng thư mTLS (RFC 8705, token ràng buộc `cnf.x5t#S256`) hoặc `private_key_jwt` (RFC 7523); bí mật chia sẻ chỉ cho hợp đồng mức thấp (ERR-12-022, SEC-24). API quản trị của PH-12 không mở cho HTTT thành viên: chỉ tài khoản dịch vụ nội bộ có scope `iam:*` gọi được, và mọi lời gọi vẫn qua OPA như mọi quyết định khác.

### 2.3. Scope máy của PH-12

Bảy scope cấp cho tài khoản dịch vụ khi triển khai (FRS §3.3), không cấp cho người hay HTTT:

| Scope | Bên giữ | Operation cho phép |
|---|---|---|
| `iam:client-provision` | PH-01 | API-12-058 (cấp client), 060, 061, 062 (tạm ngừng, tiếp tục, thu hồi), 068 (ghi đè scope) |
| `iam:dev-client` | PH-15 | API-12-063 (cấp client sandbox) |
| `iam:realm-provision` | PH-20 | API-12-045, 046 (chuyển định danh khi sáp nhập), 080 (khởi tạo realm), 084, 085 (tạm ngừng, khôi phục) |
| `iam:revocation-read` | APISIX, DU | API-12-079 (danh sách chặn) |
| `iam:directory-read` | Mọi DU | API-12-014 (danh bạ người dùng) |
| `iam:decide` | Bên gọi quyết định qua API | API-12-086, 087, 088 |
| `iam:policy-data-read` | OPA ở chế độ kéo | Dữ liệu vai trò–quyền của gói (chưa công bố ở bản này, Q12-20 của SDD) |

: Scope máy của PH-12 và operation cho phép

### 2.4. Cách `dh-platform` bảo vệ chính nó

Module `iam` dùng thư viện PEP như mọi DU: chú thích `@RequiresPermission("PERM-12-user-lock")` ứng với khóa `x-datahub-permission` của OpenAPI; PEP hỏi OPA cục bộ và, khi từ chối, đổi quyết định thành `403`, `404` hoặc `401` theo bảng lý do (FRS §9.1). Hai điểm riêng của PH-12:

1. **Không tự thao tác trên chính mình.** Khóa, vô hiệu, đặt lại yếu tố thứ hai, gán, gỡ vai trò đều từ chối khi người gọi trùng đối tượng (ERR-12-013, BR-12-033); người đề nghị không được tự duyệt (ERR-12-008, BR-12-008, BR-12-032).
2. **Quản trị tỉnh cuối cùng được bảo vệ.** Không gỡ vai trò, khóa hay vô hiệu quản trị tỉnh cuối cùng đang hoạt động (ERR-12-046).

API quyết định (`/api/authz/v1`) khác phần còn lại: bên gọi là máy, cần scope `iam:decide`; mọi trường về chủ thể lấy từ token đã xác minh chứ không từ tham số của bên gọi (BR-12-004), và thân `DecisionRequest` ánh xạ trường theo SDD §3.4.

## 3. Danh mục endpoint

Chương liệt kê 113 operation theo nhóm chức năng. Mỗi operation có đúng một mã `API-12-nnn`, khớp bảng API của FRS §9.4 (kiểm bằng `check_contracts.py`). Bảng ở mục 3.2 và 3.3 sinh từ OpenAPI; đặc tả đầy đủ từng endpoint (tham số, thân, phản hồi, lỗi) ở chương 10.

### 3.1. Cách đọc bảng

Cột **Quyền hoặc scope** là điều kiện gọi: `PERM-12-*` cho người dùng, `scope iam:*` cho tài khoản dịch vụ, "hoặc" nghĩa là một trong hai đủ; "Chính chủ tài khoản" và "Người rà soát được giao" là điều kiện theo đối tượng, không phải `PERM`. Cột **Chống trùng** có nghĩa operation bắt buộc `Idempotency-Key`; operation đổi trạng thái hoặc sửa bắt buộc `If-Match` (ghi ở chương 10). **Thành công** là mã HTTP khi thành công; `202` nghĩa là xử lý nền. Đường dẫn của nhóm quyết định ghi đầy đủ `/api/authz/v1/…`; nhóm OIDC ghi đường dẫn đầy đủ tính từ gốc Keycloak; các nhóm còn lại tính từ `/api/iam/v1`.

### 3.2. Bảng endpoint

<!-- gen:endpoints:start -->
**Người dùng và phiên**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-001 | `GET /users` | Danh sách, tìm kiếm, lọc người dùng | 001 | `PERM-12-read` |  | 200 |
| API-12-002 | `GET /users/{userId}` | Chi tiết người dùng | 002, 022 | `PERM-12-read` |  | 200 |
| API-12-003 | `POST /users` | Tạo tài khoản người dùng | 003 | `PERM-12-user-admin` | có | 201 |
| API-12-004 | `PATCH /users/{userId}` | Sửa thông tin, chuyển đơn vị người dùng | 004 | `PERM-12-user-admin` |  | 200 |
| API-12-005 | `POST /users/{userId}:lock` | Khóa tài khoản | 005 | `PERM-12-user-lock` |  | 200 |
| API-12-006 | `POST /users/{userId}:unlock` | Mở khóa tài khoản | 005 | `PERM-12-user-lock` |  | 200 |
| API-12-007 | `POST /users/{userId}:disable` | Vô hiệu tài khoản | 005 | `PERM-12-user-lock` |  | 200 |
| API-12-008 | `POST /users/{userId}:enable` | Kích hoạt lại tài khoản | 005 | `PERM-12-user-lock` |  | 200 |
| API-12-009 | `POST /users/{userId}:resend-activation` | Gửi lại liên kết kích hoạt | 003, 006 | `PERM-12-user-admin` | có | 202 |
| API-12-015 | `POST /users/{userId}:reset-mfa` | Đặt lại yếu tố thứ hai | 024 | `PERM-12-mfa-reset` | có | 200 |
| API-12-016 | `GET /users/{userId}/sessions` | Danh sách phiên của người dùng | 029 | `PERM-12-read` |  | 200 |
| API-12-017 | `POST /users/{userId}:sign-out` | Buộc đăng xuất mọi phiên | 029 | `PERM-12-user-lock` | có | 200 |

: Endpoint nhóm người dùng và phiên

**Nhập người dùng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-010 | `POST /user-imports` | Tải tệp nhập người dùng để kiểm tra | 009 | `PERM-12-user-admin` | có | 202 |
| API-12-011 | `GET /user-imports/{importId}` | Kết quả kiểm tra tệp nhập | 009 | `PERM-12-user-admin` |  | 200 |
| API-12-012 | `POST /user-imports/{importId}:commit` | Ghi nhận tệp nhập, tạo tài khoản | 009 | `PERM-12-user-admin` | có | 202 |

: Endpoint nhóm nhập người dùng

**Vai trò, quyền và gán vai trò**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-013 | `GET /users/{userId}/effective-permissions` | Quyền hiệu lực của người dùng | 016, 046 | `PERM-12-read` |  | 200 |
| API-12-019 | `GET /roles` | Danh mục vai trò | 011 | `PERM-12-read` |  | 200 |
| API-12-020 | `GET /roles/{roleCode}` | Chi tiết vai trò và quyền | 011 | `PERM-12-read` |  | 200 |
| API-12-021 | `GET /permissions` | Danh mục quyền PERM | 011 | `PERM-12-read` |  | 200 |
| API-12-022 | `POST /roles` | Tạo vai trò tùy biến (Đợt 2) | 015 | `PERM-12-user-admin` | có | 201 |
| API-12-023 | `PATCH /roles/{roleCode}` | Sửa vai trò tùy biến (Đợt 2) | 015 | `PERM-12-user-admin` |  | 200 |
| API-12-024 | `POST /roles/{roleCode}:retire` | Ngừng dùng vai trò tùy biến (Đợt 2) | 015 | `PERM-12-user-admin` |  | 200 |
| API-12-025 | `GET /role-assignments` | Danh sách gán vai trò | 012, 016 | `PERM-12-read` |  | 200 |
| API-12-026 | `POST /role-assignments` | Gán vai trò cho người dùng | 012 | `PERM-12-user-admin` | có | 201 |
| API-12-027 | `DELETE /role-assignments/{assignmentId}` | Gỡ vai trò | 012 | `PERM-12-user-admin` |  | 204 |

: Endpoint nhóm vai trò, quyền và gán vai trò

**Tham số và danh bạ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-014 | `GET /directory/users` | Tra danh bạ người dùng (thông tin tối thiểu) | 062 | scope `iam:directory-read` |  | 200 |
| API-12-110 | `GET /settings` | Tham số phân hệ của tenant | 061 | `PERM-12-read` |  | 200 |
| API-12-111 | `PUT /settings` | Sửa tham số phân hệ trong trần | 061 | `PERM-12-admin` |  | 200 |

: Endpoint nhóm tham số và danh bạ

**Thu hồi truy cập**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-018 | `POST /users/{userId}:revoke-access` | Thu hồi truy cập tức thời của người dùng | 040 | `PERM-12-user-lock` | có | 202 |
| API-12-079 | `GET /revocations` | Danh sách chặn truy cập cho APISIX và DU | 040 | scope `iam:revocation-read` |  | 200 |

: Endpoint nhóm thu hồi truy cập

**Tách nhiệm vụ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-028 | `GET /sod-rules` | Danh sách cặp vai trò xung đột | 013 | `PERM-12-read` |  | 200 |
| API-12-029 | `POST /sod-exceptions` | Đề nghị ngoại lệ tách nhiệm vụ | 013 | `PERM-12-sod-exception` | có | 201 |
| API-12-030 | `POST /sod-exceptions/{exceptionId}:decide` | Duyệt hoặc từ chối ngoại lệ tách nhiệm vụ | 013 | `PERM-12-approve` |  | 200 |
| API-12-031 | `POST /sod-exceptions/{exceptionId}:revoke` | Thu hồi ngoại lệ tách nhiệm vụ | 013 | `PERM-12-approve` |  | 200 |

: Endpoint nhóm tách nhiệm vụ

**Nhóm và đơn vị**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-032 | `GET /groups` | Danh sách nhóm, đơn vị tổ chức | 014 | `PERM-12-read` |  | 200 |
| API-12-033 | `POST /groups` | Tạo nhóm | 014 | `PERM-12-user-admin` | có | 201 |
| API-12-034 | `PATCH /groups/{groupId}` | Sửa nhóm | 014 | `PERM-12-user-admin` |  | 200 |
| API-12-035 | `PUT /groups/{groupId}/members` | Đặt danh sách thành viên nhóm | 014 | `PERM-12-user-admin` |  | 200 |

: Endpoint nhóm nhóm và đơn vị

**Quyền có thời hạn**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-036 | `POST /privileged-grants` | Đề nghị quyền có thời hạn | 017 | `PERM-12-jit-request` | có | 201 |
| API-12-037 | `GET /privileged-grants` | Danh sách quyền có thời hạn | 017, 027 | `PERM-12-read` |  | 200 |
| API-12-038 | `POST /privileged-grants/{grantId}:approve` | Duyệt quyền có thời hạn | 017 | `PERM-12-jit-approve` |  | 200 |
| API-12-039 | `POST /privileged-grants/{grantId}:reject` | Từ chối quyền có thời hạn | 017 | `PERM-12-jit-approve` |  | 200 |
| API-12-040 | `POST /privileged-grants/{grantId}:revoke` | Thu hồi quyền có thời hạn | 017 | `PERM-12-jit-approve` hoặc `PERM-12-user-lock` của tenant đích |  | 200 |

: Endpoint nhóm quyền có thời hạn

**Rà soát quyền**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-041 | `POST /recertification-campaigns` | Mở chiến dịch rà soát quyền | 018 | `PERM-12-recert` | có | 201 |
| API-12-042 | `GET /recertification-campaigns/{campaignId}` | Chi tiết chiến dịch rà soát | 018 | `PERM-12-recert` |  | 200 |
| API-12-043 | `POST /recertification-campaigns/{campaignId}/items/{itemId}:decide` | Quyết định giữ hoặc gỡ một quyền | 018 | Người rà soát được giao |  | 200 |
| API-12-044 | `POST /recertification-campaigns/{campaignId}:close` | Đóng chiến dịch rà soát | 018 | `PERM-12-recert` |  | 200 |

: Endpoint nhóm rà soát quyền

**Sáp nhập tenant**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-045 | `POST /tenant-merges/{mergeId}/identity:plan` | Lập kế hoạch chuyển định danh khi sáp nhập | 019 | scope `iam:realm-provision` |  | 200 |
| API-12-046 | `POST /tenant-merges/{mergeId}/identity:execute` | Thực hiện chuyển định danh khi sáp nhập | 019 | scope `iam:realm-provision` | có | 202 |

: Endpoint nhóm sáp nhập tenant

**Liên kết định danh ngoài**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-047 | `GET /ldap-federations` | Danh sách liên kết LDAP, AD | 026 | `PERM-12-read` |  | 200 |
| API-12-048 | `PUT /ldap-federations/{federationCode}` | Khai báo liên kết LDAP, AD | 026 | `PERM-12-admin` |  | 200 |
| API-12-049 | `POST /ldap-federations/{federationCode}:test` | Kiểm tra liên kết LDAP, AD | 026 | `PERM-12-admin` |  | 200 |
| API-12-050 | `POST /ldap-federations/{federationCode}:sync` | Chạy đồng bộ LDAP, AD | 026 | `PERM-12-admin` | có | 202 |
| API-12-051 | `GET /saml-clients` | Danh sách ứng dụng SAML | 025 | `PERM-12-read` |  | 200 |
| API-12-052 | `POST /saml-clients` | Đăng ký ứng dụng SAML | 025 | `PERM-12-admin` | có | 201 |
| API-12-053 | `PATCH /saml-clients/{samlClientCode}` | Sửa ứng dụng SAML | 025 | `PERM-12-admin` |  | 200 |
| API-12-054 | `POST /users/{userId}/vneid-link:confirm` | Xác nhận liên kết VNeID | 028 | Chính chủ tài khoản |  | 200 |
| API-12-055 | `DELETE /users/{userId}/vneid-link` | Gỡ liên kết VNeID | 028 | Chính chủ tài khoản hoặc `PERM-12-user-admin` |  | 204 |

: Endpoint nhóm liên kết định danh ngoài

**Client của HTTT**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-056 | `GET /clients` | Danh sách client của HTTT | 030 | `PERM-12-read` |  | 200 |
| API-12-057 | `GET /clients/{clientId}` | Chi tiết client | 030 | `PERM-12-read` |  | 200 |
| API-12-058 | `POST /clients` | Cấp client cho HTTT thành viên | 030 | scope `iam:client-provision` | có | 201 |
| API-12-059 | `PATCH /clients/{clientId}` | Sửa client | 031 | `PERM-12-client` |  | 200 |
| API-12-060 | `POST /clients/{clientId}:suspend` | Tạm ngừng client | 031 | `PERM-12-user-lock` hoặc scope `iam:client-provision` |  | 200 |
| API-12-061 | `POST /clients/{clientId}:resume` | Tiếp tục client | 031 | `PERM-12-user-lock` hoặc scope `iam:client-provision` |  | 200 |
| API-12-062 | `POST /clients/{clientId}:revoke` | Thu hồi client vĩnh viễn | 031, 040 | `PERM-12-user-lock` hoặc scope `iam:client-provision` |  | 202 |
| API-12-063 | `POST /dev-clients` | Cấp client cho ứng dụng nhà phát triển ở sandbox | 032 | scope `iam:dev-client` | có | 201 |
| API-12-064 | `PUT /clients/{clientId}/credentials/certificate` | Đăng ký chứng thư mTLS của client | 033 | `PERM-12-client` |  | 200 |
| API-12-065 | `PUT /clients/{clientId}/credentials/jwks` | Đăng ký khóa công khai (JWKS) của client | 033 | `PERM-12-client` |  | 200 |
| API-12-066 | `POST /clients/{clientId}/credentials/secret:rotate` | Xoay bí mật client | 034 | `PERM-12-client` | có | 202 |
| API-12-067 | `GET /clients/{clientId}/scopes` | Scope hiện có của client | 036 | `PERM-12-read` |  | 200 |
| API-12-068 | `PUT /clients/{clientId}/scopes` | Ghi đè scope của client theo nguồn đã duyệt | 036 | scope `iam:client-provision` |  | 200 |

: Endpoint nhóm client của httt

**Tài khoản dịch vụ nội bộ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-069 | `GET /service-accounts` | Danh sách tài khoản dịch vụ nội bộ | 037 | `PERM-12-read` |  | 200 |
| API-12-070 | `POST /service-accounts` | Tạo tài khoản dịch vụ nội bộ | 037 | `PERM-12-realm-admin` | có | 202 |
| API-12-071 | `POST /service-accounts/{accountCode}/credentials:rotate` | Xoay thông tin xác thực của tài khoản dịch vụ | 037 | `PERM-12-realm-admin` | có | 202 |

: Endpoint nhóm tài khoản dịch vụ nội bộ

**Điểm cuối OIDC của Keycloak**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-072 | `GET /realms/dh-{tenant}/.well-known/openid-configuration` | Tài liệu khám phá OIDC của realm | 020 | Công khai |  | 200 |
| API-12-073 | `GET /realms/dh-{tenant}/protocol/openid-connect/auth` | Điểm cuối cấp quyền (Authorization Code + PKCE) | 020, 023, 027 | Công khai |  | 302 |
| API-12-074 | `POST /realms/dh-{tenant}/protocol/openid-connect/token` | Điểm cuối token | 020, 023, 027, 035, 038 | Xác thực client (mTLS, private_key_jwt hoặc refresh token) |  | 200 |
| API-12-075 | `GET /realms/dh-{tenant}/protocol/openid-connect/certs` | Công bố JWKS của realm | 039 | Công khai |  | 200 |
| API-12-076 | `POST /realms/dh-{tenant}/protocol/openid-connect/logout` | Đăng xuất | 020 | Phiên đăng nhập (`id_token_hint`) |  | 204 |
| API-12-077 | `POST /realms/dh-{tenant}/protocol/openid-connect/revoke` | Thu hồi token (RFC 7009) | 040 | Xác thực client (mTLS, private_key_jwt hoặc refresh token) |  | 200 |
| API-12-078 | `GET /realms/dh-{tenant}/protocol/openid-connect/userinfo` | Thông tin người dùng theo token | 020 | Bearer token |  | 200 |

: Endpoint nhóm điểm cuối oidc của keycloak

**Realm của tenant**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-080 | `POST /realms` | Khởi tạo realm của tenant từ mẫu | 041 | scope `iam:realm-provision` | có | 202 |
| API-12-081 | `GET /realms/{tenantCode}` | Trạng thái realm của tenant | 042 | `PERM-12-realm-admin` |  | 200 |
| API-12-082 | `GET /realms/{tenantCode}/drift` | Đối chiếu cấu hình realm với mẫu | 042 | `PERM-12-realm-admin` |  | 200 |
| API-12-083 | `POST /realms/{tenantCode}:reconcile` | Áp lại cấu hình mẫu cho realm | 042 | `PERM-12-realm-admin` | có | 202 |
| API-12-084 | `POST /realms/{tenantCode}:suspend` | Tạm ngừng realm | 043 | scope `iam:realm-provision` hoặc `PERM-12-realm-admin` |  | 200 |
| API-12-085 | `POST /realms/{tenantCode}:resume` | Khôi phục realm | 043 | scope `iam:realm-provision` hoặc `PERM-12-realm-admin` |  | 200 |
| API-12-113 | `GET /realms` | Danh sách realm của các tenant, lọc theo lệch cấu hình | 042 | `PERM-12-realm-admin` |  | 200 |

: Endpoint nhóm realm của tenant

**Quyết định ủy quyền**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-086 | `POST /api/authz/v1/decide` | Quyết định ủy quyền một yêu cầu | 044, 045, 046, 047 | scope `iam:decide` |  | 200 |
| API-12-087 | `POST /api/authz/v1/decide:batch` | Quyết định ủy quyền theo lô (tối đa 100) | 049 | scope `iam:decide` |  | 200 |
| API-12-088 | `POST /api/authz/v1/xacml` | Quyết định theo XACML 3.0 JSON profile | 048 | scope `iam:decide` |  | 200 |

: Endpoint nhóm quyết định ủy quyền

**Chính sách và gói**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-089 | `GET /policies` | Danh sách chính sách | 052 | `PERM-12-read` |  | 200 |
| API-12-090 | `GET /policies/{policyCode}` | Chi tiết chính sách | 052 | `PERM-12-read` |  | 200 |
| API-12-091 | `POST /policies` | Tạo chính sách kèm phiên bản đầu | 052 | `PERM-12-policy-edit` | có | 201 |
| API-12-092 | `POST /policies/{policyCode}/versions` | Tạo phiên bản nháp mới | 052 | `PERM-12-policy-edit` | có | 201 |
| API-12-093 | `GET /policies/{policyCode}/versions/{versionNo}` | Chi tiết một phiên bản chính sách | 052 | `PERM-12-read` |  | 200 |
| API-12-094 | `POST /policies/{policyCode}/versions/{versionNo}:test` | Chạy bộ ca kiểm thử | 052 | `PERM-12-policy-edit` |  | 200 |
| API-12-095 | `POST /policies/{policyCode}/versions/{versionNo}:dry-run` | Chạy khô trên lưu lượng thật | 053 | `PERM-12-policy-edit` | có | 202 |
| API-12-096 | `POST /policies/{policyCode}/versions/{versionNo}:submit` | Gửi duyệt phiên bản chính sách | 054 | `PERM-12-policy-edit` | có | 200 |
| API-12-097 | `POST /policies/{policyCode}/versions/{versionNo}:approve` | Duyệt và phát hành phiên bản chính sách | 054 | `PERM-12-policy-approve` |  | 202 |
| API-12-098 | `POST /policies/{policyCode}/versions/{versionNo}:reject` | Từ chối phiên bản chính sách | 054 | `PERM-12-policy-approve` |  | 200 |
| API-12-099 | `POST /policies/{policyCode}/versions/{versionNo}:revoke` | Thu hồi phiên bản đang chạy | 055 | `PERM-12-policy-approve` |  | 202 |
| API-12-100 | `POST /policy-bundles:rollback` | Quay lui về gói chính sách đã từng chạy | 055 | `PERM-12-policy-approve` | có | 202 |
| API-12-101 | `GET /policy-bundles` | Danh sách gói chính sách đã phát hành | 051, 054, 055 | `PERM-12-read` |  | 200 |
| API-12-102 | `POST /policy-data:regenerate` | Sinh lại dữ liệu vai trò–quyền cho OPA | 051 | `PERM-12-policy-edit` hoặc hệ thống | có | 202 |
| API-12-112 | `PUT /policies/{policyCode}/versions/{versionNo}` | Ghi đè nội dung bản nháp của phiên bản chính sách (tự lưu) | 052 | `PERM-12-policy-edit` |  | 200 |

: Endpoint nhóm chính sách và gói

**Nhật ký, cảnh báo, báo cáo**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-12-103 | `GET /decisions` | Tra nhật ký quyết định ủy quyền | 057, 058 | `PERM-12-decision-read` |  | 200 |
| API-12-104 | `GET /decisions/{decisionId}` | Chi tiết một quyết định ủy quyền | 058 | `PERM-12-decision-read` |  | 200 |
| API-12-105 | `GET /security-events` | Tra sự kiện xác thực và quản trị định danh | 056 | `PERM-12-decision-read` |  | 200 |
| API-12-106 | `GET /alerts` | Danh sách cảnh báo an ninh | 059 | `PERM-12-alert` |  | 200 |
| API-12-107 | `POST /alerts/{alertId}:acknowledge` | Xác nhận cảnh báo | 059 | `PERM-12-alert` |  | 200 |
| API-12-108 | `GET /reports/accounts` | Báo cáo tình trạng tài khoản | 060 | `PERM-12-read` |  | 200 |
| API-12-109 | `GET /reports/mfa-coverage` | Báo cáo phủ xác thực hai yếu tố | 060 | `PERM-12-read` |  | 200 |

: Endpoint nhóm nhật ký, cảnh báo, báo cáo
<!-- gen:endpoints:end -->

### 3.3. Phủ chức năng

Mỗi FR của FRS PH-12 có ít nhất một API hoặc được ghi rõ là chỉ giao diện hoặc tác vụ nền.

<!-- gen:coverage:start -->
| FR | Chức năng | API |
|---|---|---|
| FR-12-001 | Liệt kê, tìm kiếm và lọc người dùng | API-12-001 |
| FR-12-002 | Xem chi tiết người dùng | API-12-002 |
| FR-12-003 | Tạo tài khoản người dùng | API-12-003, API-12-009 |
| FR-12-004 | Sửa thông tin và chuyển đơn vị của người dùng | API-12-004 |
| FR-12-005 | Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản | API-12-005, API-12-006, API-12-007, API-12-008 |
| FR-12-006 | Kích hoạt tài khoản lần đầu | API-12-009; Chỉ giao diện: trang kích hoạt của Keycloak (đặt mật khẩu, ERR-12-015, 016); liên kết gửi bằng API-12-003, 009 |
| FR-12-007 | Đặt lại mật khẩu khi quên | Chỉ giao diện: trang đặt lại mật khẩu của Keycloak; phát sinh sự kiện EVT-12-04, 16 |
| FR-12-008 | Tự vô hiệu tài khoản và tạm ngừng client không hoạt động | Tác vụ định kỳ của `dh-platform` (ShedLock); không có API riêng, kết quả qua API-12-001, 056 và EVT-12-02, 07 |
| FR-12-009 | Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ | API-12-010, API-12-011, API-12-012 |
| FR-12-010 | Đồng bộ thuộc tính người dùng từ danh mục đơn vị | Tác vụ đồng bộ danh mục đơn vị (PH-07) theo sự kiện; không có API riêng |
| FR-12-011 | Xem danh mục vai trò chuẩn và quyền | API-12-019, API-12-020, API-12-021 |
| FR-12-012 | Gán và gỡ vai trò cho người dùng | API-12-025, API-12-026, API-12-027 |
| FR-12-013 | Chặn cặp vai trò xung đột và duyệt ngoại lệ có thời hạn | API-12-028, API-12-029, API-12-030, API-12-031 |
| FR-12-014 | Quản lý nhóm và đơn vị tổ chức | API-12-032, API-12-033, API-12-034, API-12-035 |
| FR-12-015 | Tạo vai trò tùy biến của tenant | API-12-022, API-12-023, API-12-024 |
| FR-12-016 | Xem quyền hiệu lực của người dùng | API-12-013, API-12-025 |
| FR-12-017 | Cấp quyền có thời hạn cho vai trò đặc quyền và truy cập liên tenant | API-12-036, API-12-037, API-12-038, API-12-039, API-12-040 |
| FR-12-018 | Rà soát quyền định kỳ | API-12-041, API-12-042, API-12-043, API-12-044 |
| FR-12-019 | Chuyển định danh và vai trò khi sáp nhập tenant | API-12-045, API-12-046 |
| FR-12-020 | Xác thực người dùng theo OIDC Authorization Code và PKCE | API-12-072, API-12-073, API-12-074, API-12-076, API-12-078 |
| FR-12-021 | Chống dò mật khẩu và khóa tài khoản | Cấu hình bảo mật realm của Keycloak; vết ở API-12-105 |
| FR-12-022 | Đăng ký và dùng yếu tố thứ hai TOTP, WebAuthn | API-12-002 |
| FR-12-023 | Xác thực lại bước lên cho thao tác nhạy cảm | API-12-073, API-12-074 |
| FR-12-024 | Đặt lại yếu tố thứ hai khi mất thiết bị | API-12-015 |
| FR-12-025 | Đăng nhập một lần bằng SAML 2 cho ứng dụng cũ | API-12-051, API-12-052, API-12-053 |
| FR-12-026 | Liên kết LDAP, Active Directory của tỉnh | API-12-047, API-12-048, API-12-049, API-12-050 |
| FR-12-027 | Đăng nhập liên tenant cho người dùng thuộc nhiều tenant | API-12-037, API-12-073, API-12-074 |
| FR-12-028 | Liên kết đăng nhập VNeID | API-12-054, API-12-055; Đăng nhập VNeID qua OIDC của Keycloak (Đợt 2, `12.vneid.enabled`) |
| FR-12-029 | Quản lý phiên: xem, buộc đăng xuất, hạn mức phiên | API-12-016, API-12-017 |
| FR-12-030 | Cấp client OAuth cho HTTT thành viên | API-12-056, API-12-057, API-12-058 |
| FR-12-031 | Quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi | API-12-059, API-12-060, API-12-061, API-12-062 |
| FR-12-032 | Cấp client cho ứng dụng nhà phát triển ở sandbox | API-12-063 |
| FR-12-033 | Đăng ký chứng thư mTLS và khóa công khai của client | API-12-064, API-12-065 |
| FR-12-034 | Xoay bí mật client | API-12-066 |
| FR-12-035 | Phát token cho HTTT bằng `client_credentials` | API-12-074; Máy gọi bằng mTLS hoặc `private_key_jwt`; scope máy ở mục 2.3 |
| FR-12-036 | Sinh scope của client từ dữ liệu đã duyệt | API-12-067, API-12-068 |
| FR-12-037 | Tài khoản dịch vụ nội bộ của đơn vị triển khai | API-12-069, API-12-070, API-12-071 |
| FR-12-038 | Vòng đời token: làm mới xoay vòng, phát hiện dùng lại | API-12-074; Cấu hình xoay vòng, phát hiện dùng lại ở realm; vết ở EVT-12-16 |
| FR-12-039 | Công bố JWKS và xoay khóa ký 90 ngày | API-12-075 |
| FR-12-040 | Thu hồi truy cập tức thời và phân phối danh sách chặn | API-12-018, API-12-062, API-12-077, API-12-079 |
| FR-12-041 | Khởi tạo realm của tenant từ mẫu | API-12-080 |
| FR-12-042 | Cấu hình bảo mật realm bằng GitOps, phát hiện lệch | API-12-081, API-12-082, API-12-083, API-12-113 |
| FR-12-043 | Tạm ngừng, khôi phục, chuyển chỉ-đọc realm theo vòng đời tenant | API-12-084, API-12-085 |
| FR-12-044 | Quyết định ủy quyền theo hợp đồng PEP và PDP | API-12-086 |
| FR-12-045 | Quy tắc gốc: từ chối mặc định, từ chối thắng, cách ly tenant | API-12-086 |
| FR-12-046 | Phân quyền ba lớp: vai trò, phạm vi tổ chức, thuộc tính dữ liệu | API-12-013, API-12-086 |
| FR-12-047 | Tính mặt nạ trường và chế độ bảo vệ theo mục đích | API-12-086 |
| FR-12-048 | Bộ chuyển đổi XACML 3.0 | API-12-088 |
| FR-12-049 | Quyết định theo lô | API-12-087 |
| FR-12-050 | Bộ đệm quyết định | Bộ đệm quyết định nằm ở thư viện PEP và plugin `dh-authz`; cấu hình `12.cache.ttl-seconds` ở API-12-110, 111 |
| FR-12-051 | Sinh dữ liệu vai trò–quyền cho OPA từ ma trận D02-08 | API-12-101, API-12-102 |
| FR-12-052 | Soạn và kiểm thử chính sách | API-12-089, API-12-090, API-12-091, API-12-092, API-12-093, API-12-094, API-12-112 |
| FR-12-053 | Chạy khô chính sách trên lưu lượng thật | API-12-095 |
| FR-12-054 | Duyệt bốn mắt và phát hành gói chính sách ký | API-12-096, API-12-097, API-12-098, API-12-101 |
| FR-12-055 | Thu hồi và quay lui chính sách | API-12-099, API-12-100, API-12-101 |
| FR-12-056 | Ghi vết sự kiện xác thực và quản trị định danh | API-12-105 |
| FR-12-057 | Ghi vết quyết định ủy quyền | API-12-103 |
| FR-12-058 | Tra cứu nhật ký quyết định | API-12-103, API-12-104 |
| FR-12-059 | Phát hiện hành vi bất thường và cảnh báo | API-12-106, API-12-107 |
| FR-12-060 | Báo cáo tình trạng tài khoản và xác thực hai yếu tố | API-12-108, API-12-109 |
| FR-12-061 | Tham số phân hệ theo tenant | API-12-110, API-12-111 |
| FR-12-062 | Tra cứu danh bạ người dùng cho phân hệ khác | API-12-014 |

: Phủ chức năng của PH-12 bởi API
<!-- gen:coverage:end -->

### 3.4. Ví dụ yêu cầu và phản hồi

Các ví dụ dùng dữ liệu giả lập (tenant `T68`, miền `sokhcn.gov.vn`). Tiêu đề `traceparent`, `Accept-Language` bỏ qua cho gọn.

**API-12-003 · Tạo tài khoản** (`POST /users`, `Idempotency-Key: 6b0e2c9a-3f1d-4a77-9a52-0d9c1f6e8b14`)

```json
{ "username": "nguyen.vana", "fullName": "Nguyễn Văn A", "email": "vana@sokhcn.gov.vn", "orgCode": "SKHCN", "title": "Chuyên viên",
  "roles": [ { "roleCode": "INTEGRATION_ENGINEER", "scopeType": "ORG", "scopeRef": "SKHCN" } ] }
```

Phản hồi `201`, tiêu đề `Location: /api/iam/v1/users/0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b`, `ETag: "1"`. Không có mật khẩu hay liên kết kích hoạt trong thân; liên kết 24 giờ gửi tới thư điện tử.

```json
{ "userId": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b", "username": "nguyen.vana", "fullName": "Nguyễn Văn A", "email": "vana@sokhcn.gov.vn",
  "orgCode": "SKHCN", "orgName": "Sở Khoa học và Công nghệ", "state": "PENDING_ACTIVATION", "authSource": "LOCAL", "roles": ["INTEGRATION_ENGINEER"],
  "mfaEnabled": false, "lastLoginAt": null, "version": 1, "createdAt": "2026-11-26T08:30:00Z", "createdBy": "tran.thib",
  "allowedActions": ["resend-activation", "disable"], "disabledReasons": { "unlock": "Tài khoản chưa bị khóa." } }
```

**API-12-058 · Cấp client cho HTTT** (`POST /clients`, token dịch vụ `iam:client-provision` của PH-01)

```json
{ "systemCode": "ht-qlvb", "systemName": "Quản lý văn bản Sở KH&CN", "orgCode": "SKHCN", "contractLevel": "INTERNAL", "authMethod": "PRIVATE_KEY_JWT",
  "scopes": [ { "scope": "api:van-ban:read", "source": "API_REGISTRATION", "sourceRef": "REG-2026-0113" } ], "technicalContact": "tran.vanb",
  "publicKeyJwk": { "kty": "EC", "crv": "P-256", "x": "f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU", "y": "x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0", "use": "sig", "alg": "ES256" } }
```

Phản hồi `201`. Hợp đồng dùng khóa công khai nên không có bí mật; với `CLIENT_SECRET`, trường `secretHandover.wrapAddress` là địa chỉ bọc dùng một lần mà đầu mối kỹ thuật mở ở BFF, thân phản hồi không bao giờ có giá trị bí mật.

```json
{ "clientId": "ht-qlvb", "systemCode": "ht-qlvb", "systemName": "Quản lý văn bản Sở KH&CN", "orgCode": "SKHCN", "state": "ENABLED",
  "authMethod": "PRIVATE_KEY_JWT", "contractLevel": "INTERNAL", "credentialReady": true, "scopeCount": 1,
  "scopes": [ { "scope": "api:van-ban:read", "source": "API_REGISTRATION", "sourceRef": "REG-2026-0113" } ],
  "technicalContact": "tran.vanb", "version": 1, "createdAt": "2026-11-26T08:35:10Z", "createdBy": "svc-ph01" }
```

**API-12-018 · Thu hồi truy cập tức thời** (`POST /users/{userId}:revoke-access`)

```json
{ "targetType": "USER", "targetId": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b", "reason": "Nghi lộ thông tin đăng nhập", "scopeOfRevoke": "ALL" }
```

Phản hồi `202`: danh sách chặn đã ghi, đang lan tới các nút cổng (hiệu lực ≤ 60 giây).

```json
{ "revocationId": "7d1f6a52-2b0c-4e9b-8f73-3a9d5c2e1b40", "state": "APPLIED_PARTIAL", "appliedNodes": 1, "totalNodes": 3, "estimatedAppliedAt": "2026-11-26T08:41:00Z" }
```

**API-12-086 · Quyết định ủy quyền** (`POST /api/authz/v1/decide`, token `iam:decide`)

```json
{ "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "tenant": "T68",
  "subject": { "type": "USER", "id": "nguyen.vana", "roles": ["INTEGRATION_ENGINEER"], "scopes": [], "org": "SKHCN", "acr": 2, "authTime": "2026-11-26T08:30:00Z" },
  "resource": { "id": "luong-hosoxd", "type": "flow", "tenant": "T68", "org": "SKHCN", "classification": "INTERNAL", "state": "DRAFT", "createdBy": "nguyen.vana" },
  "action": "publish", "permission": "PERM-04-publish", "context": { "sourceIp": "10.20.30.40", "time": "2026-11-26T09:00:00Z" } }
```

Phản hồi `200`. Vai trò không mang quyền yêu cầu nên từ chối; bên thực thi đổi thành `403`:

```json
{ "allow": false, "reason": "ROLE_MISSING", "matchedPolicy": null, "bundleRevision": "t68-20261126-0007", "fieldMask": {}, "privacyMode": "NONE",
  "obligations": [ { "type": "AUDIT", "params": { "level": "full" } } ], "evaluationTimeMs": 3 }
```

Khi cho phép, `reason` là `MATCHED_POLICY`, `matchedPolicy` là mã chính sách khớp và `fieldMask` nêu trường cần che (`FULL`, `MASKED`, `HIDDEN`); bên thực thi bắt buộc thực hiện mọi `obligations`.

**API-12-079 · Danh sách chặn** (`GET /revocations`, APISIX kéo mỗi 10 giây, `If-None-Match: "412"`, `X-DH-Applied-Version: 412`, `X-DH-Node: apisix-0`)

Không có mục mới: `304`, không thân. Có mục mới: `200`, `ETag: "413"`. Giá trị `version` và `ETag` là số thứ tự toàn cục của bảng `revocation_feed_version`.

```json
{ "version": 413, "generatedAt": "2026-11-26T08:40:50Z",
  "entries": [ { "entryId": "7d1f6a52-2b0c-4e9b-8f73-3a9d5c2e1b40", "kind": "SUB", "subject": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b",
                 "notBefore": "2026-11-26T08:40:30Z", "expiresAt": "2026-11-26T08:46:00Z", "blockAll": false, "reason": "Nghi lộ thông tin đăng nhập" } ] }
```

**API-12-097 · Duyệt chính sách khi đổi quá ngưỡng** (`POST /policies/tenant-default/versions/4:approve`, `If-Match: "9"`)

```json
{ "comment": "Đã xem báo cáo chạy khô, 23% quyết định đổi do bổ sung điều kiện mục đích", "extraConfirm": false }
```

Chạy khô cho thấy 23% quyết định đổi, vượt ngưỡng 20% (`12.policy.dryrun.change-threshold`) nên cần xác nhận bổ sung; phản hồi `409`:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-12-029", "title": "Thiếu xác nhận bổ sung khi chạy khô đổi quá ngưỡng", "status": 409,
  "detail": "Thay đổi này đổi 23% quyết định. Tích xác nhận và nhập ý kiến để tiếp tục.", "code": "ERR-12-029", "traceId": "00f067aa0ba902b700f067aa0ba902b7" }
```

**API-12-074 · Token cho HTTT** (`POST /realms/dh-t68/protocol/openid-connect/token`, `application/x-www-form-urlencoded`, xác thực client bằng mTLS)

```
grant_type=client_credentials&client_id=ht-qlvb&scope=api%3Avan-ban%3Aread
```

```json
{ "access_token": "eyJhbGciOiJFUzI1NiIsImtpZCI6ImRoLXQ2OC0yMDI2MTEifQ.…", "token_type": "Bearer", "expires_in": 300, "scope": "api:van-ban:read" }
```

Client bị tạm ngừng nhận `403` `{"error": "unauthorized_client", "error_description": "Client bị tạm ngừng"}` (ghi nhật ký ERR-12-118); grant `password` bị cấm: `400` `unsupported_grant_type` (ERR-12-122).

**API-12-111 · Tham số ngoài trần** (`PUT /settings`, `If-Match: "7"`)

```json
{ "values": { "12.password.min-length": 12 }, "reason": "Đề nghị nới theo thói quen cũ" }
```

Phản hồi `422`: mật khẩu tối thiểu 14 ký tự là mức bắt buộc của TCVN 14423:2026 (BR-12-038).

```json
{ "type": "https://datahub.gov.vn/errors/ERR-12-043", "title": "Vượt trần tham số hoặc giới hạn số lượng", "status": 422, "code": "ERR-12-043",
  "traceId": "9a3f5c2e1b407d1f6a522b0c4e9b8f73", "errors": [ { "field": "values.12.password.min-length", "rule": "range", "min": 14, "max": 128 } ] }
```

## 4. Danh mục sự kiện

PH-12 phát 16 sự kiện nghiệp vụ lên Kafka để phân hệ khác phản ứng mà không phải gọi lại: PH-13 nhận để ghi kiểm toán, APISIX và DU nhận để xóa bộ đệm và chặn token, bộ ghi chính sách nhận để sinh lại dữ liệu cho OPA. Topic theo `{tenant}.iam.{thực-thể}.{sự-kiện}.v1` chữ thường (D00-04 §4); tenant nền tảng dùng tiền tố `platform`. Lược đồ trong [`asyncapi-iam.yaml`](ph12/asyncapi-iam.yaml), đăng ký ở Apicurio chế độ BACKWARD (ADR-070: chỉ thêm trường tùy chọn trong `v1`).

### 4.1. Bảng sự kiện

<!-- gen:events:start -->
| Mã | Topic | Người phát | Khóa phân vùng | Giữ | Phân vùng | Người nhận |
|---|---|---|---|---|---|---|
| EVT-12-01 | `{tenant}.iam.user.created.v1` | `dh-platform` (outbox) | `userId` | 7 ngày | 3 | PH-13, bản chiếu `ph12_iam` |
| EVT-12-02 | `{tenant}.iam.user.state-changed.v1` | `dh-platform` (outbox) | `userId` | 7 ngày | 3 | PH-13, bản chiếu `ph12_iam` |
| EVT-12-03 | `{tenant}.iam.user.role-changed.v1` | `dh-platform` (outbox) | `userId` | 7 ngày | 3 | Bộ ghi chính sách (FR-12-051), PH-13 |
| EVT-12-04 | `{tenant}.iam.user.credential-changed.v1` | `dh-platform` (outbox) | `userId` | 7 ngày | 3 | PH-13 |
| EVT-12-05 | `{tenant}.iam.access.revoked.v1` | `dh-platform` (outbox) | `tenantCode` | 7 ngày | 3 | DU qua thư viện PEP, PH-13 |
| EVT-12-06 | `{tenant}.iam.client.provisioned.v1` | `dh-platform` (outbox) | `clientId` | 7 ngày | 3 | PH-01, PH-03, PH-13 |
| EVT-12-07 | `{tenant}.iam.client.state-changed.v1` | `dh-platform` (outbox) | `clientId` | 7 ngày | 3 | PH-01, PH-03, PH-13 |
| EVT-12-08 | `{tenant}.iam.client.credential-changed.v1` | `dh-platform` (outbox) | `clientId` hoặc `accountCode` | 7 ngày | 3 | PH-03 (dấu vân tay), bộ ghi chính sách, PH-13 |
| EVT-12-09 | `{tenant}.iam.policy.published.v1` | `dh-platform` (outbox) | `policyCode` | 7 ngày | 3 | DU (xóa bộ đệm), PH-13 |
| EVT-12-10 | `{tenant}.iam.policy.revoked.v1` | `dh-platform` (outbox) | `policyCode` | 7 ngày | 3 | DU, PH-13 |
| EVT-12-11 | `{tenant}.iam.grant.state-changed.v1` | `dh-platform` (outbox) | `grantId` | 7 ngày | 3 | PH-13, thông báo quản trị tỉnh bị truy cập |
| EVT-12-12 | `{tenant}.iam.sod.exception-changed.v1` | `dh-platform` (outbox) | `exceptionId` | 7 ngày | 3 | PH-13 |
| EVT-12-13 | `{tenant}.iam.realm.changed.v1` | `dh-platform` (outbox) | `tenantCode` | 7 ngày | 3 | PH-20, PH-13 |
| EVT-12-14 | `{tenant}.iam.alert.raised.v1` | `dh-platform` (outbox) | `alertId` | 7 ngày | 3 | PH-13, kênh thông báo của SO |
| EVT-12-15 | `{tenant}.iam.recert.completed.v1` | `dh-platform` (outbox) | `tenantCode` | 7 ngày | 3 | PH-13 |
| EVT-12-16 | `{tenant}.iam.auth.event-recorded.v1` | Keycloak (`dh-keycloak-spi`) | `userId` hoặc `clientId` | 3 ngày | 6 | PH-13, bộ phát hiện bất thường |

: Danh mục sự kiện của PH-12
<!-- gen:events:end -->

### 4.2. Định dạng và bảo đảm giao nhận

Mười lăm sự kiện đầu ghi vào bảng `outbox` của `ph12_iam` **cùng giao dịch** với thay đổi trạng thái (ADR-042); Debezium outbox router phát lên Kafka dạng CloudEvents 1.0 chế độ nhị phân (`ce_type = vn.datahub.iam.user.created.v1`, `ce_subject` = mã đối tượng, tiêu đề `dhtenant`). EVT-12-16 do Keycloak phát trực tiếp bằng producer idempotent vì không có giao dịch control plane (SDD §8.2).

| Bảo đảm | Cách hiện thực |
|---|---|
| Giao ít nhất một lần | Outbox và Debezium; người nhận phải lũy đẳng theo `ce_id` |
| Thứ tự theo đối tượng | Khóa phân vùng ở bảng 4.1 (userId, clientId, policyCode…); không bảo đảm thứ tự giữa các đối tượng |
| Bỏ sự kiện cũ | Người nhận bỏ qua sự kiện có `version` thấp hơn trạng thái đang giữ (bản chiếu `ph12_iam`, bộ ghi chính sách) |
| Cách ly tenant | Tên topic và tiêu đề `dhtenant` phải khớp, không khớp chuyển DLQ và phát cảnh báo (D03-10 §3); ACL Kafka theo tiền tố tenant cấp qua GitOps (ADR-072) |
| Không bí mật | Không sự kiện nào mang mật khẩu, bí mật client, khóa riêng, mã bọc; ràng buộc `ck_outbox_no_secret` ở CSDL và kiểm thử canary ở CI |
| Giữ lại | 7 ngày (EVT-12-16: 3 ngày vì khối lượng lớn); bản ghi outbox đã gửi xóa sau 3 ngày |
| Tương thích | BACKWARD; thêm trường tùy chọn trong `v1`, đổi cấu trúc sang `v2` và phát song song 6 tháng |

: Bảo đảm giao nhận của sự kiện PH-12

Hai dữ liệu **không** đi qua các topic trên. Nhật ký quyết định ủy quyền đi theo đường log (plugin `decision_logs` của OPA tới PH-13, FR-12-057) vì khối lượng lớn và lấy mẫu theo mức phân loại. Trạng thái nạp gói của từng OPA (plugin `status`) gửi tới một điểm cuối nội bộ của `dh-platform` để tính tiến độ phát hành, không công bố thành API (Q12-56).

Ví dụ EVT-12-05 (thu hồi truy cập), `ce_subject = T68`, khóa phân vùng `T68`:

```json
{ "tenantId": "T68", "revocationId": "7d1f6a52-2b0c-4e9b-8f73-3a9d5c2e1b40", "kind": "SUB", "subject": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b",
  "notBefore": "2026-11-26T08:40:30Z", "expiresAt": "2026-11-26T08:46:00Z", "blockAll": true, "reason": "Nghi lộ thông tin đăng nhập",
  "actor": { "id": "le.thic", "type": "USER" }, "feedVersion": 413 }
```

`blockAll=true` là cờ tạm: cổng chặn mọi token của chủ thể cho tới khi Keycloak xác nhận đã vô hiệu (SEC-25), tránh khoảng hở khi Keycloak chậm. Ví dụ EVT-12-08 (đổi chứng thư client, không có giá trị bí mật), topic `t68.iam.client.credential-changed.v1`:

```json
{ "tenantId": "T68", "ownerKind": "CLIENT", "ownerId": "ht-qlvb", "change": "CERTIFICATE", "thumbprint": "3f:9a:5c:21:b7:0d:44:e8", "scopesRevision": 3,
  "overlapUntil": null, "actor": { "id": "tran.vanb", "type": "USER" }, "version": 4, "occurredAt": "2026-11-26T09:12:00Z" }
```

PH-03 dùng `thumbprint` để cập nhật dấu vân tay chứng thư mTLS của client ở APISIX mà không phải đọc Keycloak.

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-12 ở giữa nhiều phân hệ: bên được gọi (PH-01, PH-15, PH-20, APISIX, DU) và bên gọi (PH-07, PH-18, Keycloak, OpenBao). Bảng dưới nêu từng cặp, hướng và hợp đồng cụ thể.

### 5.1. Bảng hợp đồng

Bảng sau liệt kê các hợp đồng giữa PH-12 và phân hệ khác hoặc bên ngoài, gồm bên liên quan, hướng gọi, API hoặc sự kiện được dùng và ghi chú.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| PH-01 Kết nạp HTTT | PH-01 → PH-12 | API-12-058 (cấp client), 060, 061, 062, 068 bằng scope `iam:client-provision`; nhận EVT-12-06, 07 | PH-12 trả kết quả đồng bộ (`201`), không dùng callback API-01-087 (Q01-56); đổi trạng thái hoặc đơn vị của tài khoản đầu mối qua EVT-12-02. Saga cấp client dùng `Idempotency-Key` làm khóa tìm lại tiến trình dở; PH-01 mở địa chỉ bọc ở BFF, hiển thị bí mật một lần |
| PH-02, PH-09, PH-10, PH-19 | Nguồn → PH-12 | `ScopeSourcePort.accept` (trong tiến trình) hoặc API-12-068 (REST) đẩy dữ liệu đã duyệt để sinh scope | Chỉ scope có nguồn duyệt mới được ghi (ERR-12-019) |
| PH-03 Cổng API (APISIX) | PH-03 → PH-12; PH-12 → PH-03 | API-12-075 (JWKS), API-12-079 (danh sách chặn kéo mỗi 10 giây), API-12-086 (nếu không dùng OPA cục bộ); nhận EVT-12-08, 09, 10; PH-12 đẩy thu hồi qua API-03-053 bằng scope `gateway:revoke` (đường nhanh); plugin `dh-authz` kéo API-12-079 mỗi 10 giây làm đường bù khi mất đẩy (đã chốt 27/11/2026) | Plugin `dh-authz` ánh xạ trường theo SDD §3.4; báo `X-DH-Applied-Version` để PH-12 hiển thị "đã áp dụng n/m nút" |
| PH-04, PH-05, DU | DU → PH-12 | Thư viện PEP gọi OPA cục bộ; API-12-014 (danh bạ); nhận EVT-12-05, 09, 10 | `dh-runtime` (Quarkus) gọi API-12-086 trong giai đoạn đầu (Q12-26 của SDD) |
| PH-07 Danh mục dùng chung | PH-12 đọc | Danh mục đơn vị (đồng bộ thuộc tính, kiểm `orgCode`) | ERR-12-004 khi đơn vị hết hiệu lực, ERR-12-040 khi PH-07 không khả dụng |
| PH-13 Giám sát và kiểm toán | PH-12 → PH-13 | EVT-12-01…16; nhật ký quyết định theo đường log; bản ghi thay đổi quyền vào chuỗi băm của tenant bị truy cập | Hợp đồng tiếp nhận do PH-13 xác định |
| PH-15 Cổng nhà phát triển | PH-15 → PH-12 | API-12-063 bằng scope `iam:dev-client` | Chỉ ở sandbox; PH-15 thêm độ trễ ngẫu nhiên khi làm mới token |
| PH-18 Vận hành | PH-12 đọc, ghi | Tham số `12.*` qua API-12-110, 111 (kho tham số của PH-18), đệm 60 giây | Ngoài trần: ERR-12-043 |
| PH-20 Quản trị tenant | PH-20 → PH-12 | API-12-080 (tạo realm, ≤ 5 phút), 084, 085 (tạm ngừng, khôi phục), 045, 046 (chuyển định danh khi sáp nhập); nhận EVT-12-13 | PH-20 chờ tối đa 4 phút ở bước `S03_REALM` của saga |
| Keycloak | `dh-platform` → Keycloak | Admin REST với client `dh-platform-iam` (chỉ `realm-user-admin`) và `dh-client-provisioner` (giới hạn thuộc tính `dh_managed`); `keycloak-config-cli` cho realm | Không qua API công bố; lỗi: ERR-12-038 |
| OpenBao | `dh-platform` → OpenBao | Transit (ký gói chính sách), KV, cubbyhole (địa chỉ bọc) | Lỗi: ERR-12-039 |
| OPA | `dh-platform`, PEP → OPA | `POST /v1/data/dh/authz/decision`; nạp gói từ bucket Ceph RGW; plugin `status`, `decision_logs` | Hợp đồng đầu vào, đầu ra ở SDD §3.4 |
| LDAP/AD của tỉnh, VNeID, ứng dụng SAML | Keycloak ↔ bên ngoài | API-12-047…055 cấu hình; xác thực do Keycloak thực hiện | LDAPS cổng 636 qua egress; VNeID Đợt 2 (CMP-LAW-10) |
| HTTT thành viên | HTTT → PH-12 | Điểm cuối token (API-12-074), JWKS (API-12-075) | Không gọi API quản trị |

: Hợp đồng với phân hệ khác và bên ngoài

### 5.2. Trình tự luồng chính: HTTT lấy token và gọi API

Luồng sau nối bốn thành phần của hợp đồng: PH-01 cấp client, HTTT lấy token, APISIX kiểm tra và hỏi OPA, DU thực hiện. Đây là đường đi của mọi lời gọi máy gọi máy qua Datahub.

```{.mermaid caption="Trình tự cấp client, lấy token và quyết định ủy quyền"}
sequenceDiagram
  autonumber
  participant P1 as PH-01
  participant P as dh-platform iam
  participant K as Keycloak
  participant H as HTTT thành viên
  participant G as APISIX và OPA cục bộ
  participant D as DU
  P1->>P: POST /clients với scope đã duyệt (API-12-058)
  P->>K: Tạo client, đăng ký chứng thư hoặc khóa công khai
  P-->>P1: 201 client ENABLED, địa chỉ bọc nếu có bí mật
  P--)G: EVT-12-06, 08 và gói dữ liệu mới (EVT-12-09)
  H->>K: POST /token, client_credentials, mTLS (API-12-074)
  K-->>H: access token ES256, sống 300 giây
  H->>G: Gọi API kèm Bearer token
  G->>G: Kiểm JWKS, danh sách chặn, hỏi OPA theo DecisionRequest
  G->>D: Chuyển tiếp khi allow, kèm fieldMask
  D-->>H: Phản hồi, hoặc 403 kèm reason khi từ chối
```

Hình cho thấy PH-12 không nằm trên đường đi của từng lời gọi dữ liệu: sau khi cấp client và phát gói, APISIX tự kiểm bằng JWKS, danh sách chặn và OPA cục bộ. PH-12 chỉ xuất hiện lại khi cấp token (Keycloak) hoặc khi cần quyết định qua API-12-086.

## 6. Bảng mã lỗi ERR-12

Mã lỗi theo dải của PH-12: 001–099 cho control plane (API quản trị), 101–199 cho runtime (quyết định ủy quyền, xác thực, cấp token). Bảng ở 6.1 và 6.2 sinh từ FRS §9.1 và OpenAPI, cột cuối cho biết operation nào có thể trả mã đó. Thân lỗi RFC 9457 và các trường bổ sung ở chương 1.

<!-- gen:errors:start -->
### 6.1. Lỗi API quản trị (ERR-12-001…047)

Bảng sau là danh sách chuẩn các mã lỗi của API quản trị PH-12 với mã HTTP, ý nghĩa và các API có thể phát sinh lỗi đó; các tập khác lấy mã HTTP và câu thông báo từ đây.

| Mã | HTTP | Ý nghĩa | API phát sinh (API-12-) |
|---|---|---|---|
| ERR-12-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant, tổ chức khác | 64 API (xem OpenAPI) |
| ERR-12-002 | 409 | Mã, tên đăng nhập hoặc thư điện tử đã được dùng | 003, 022, 033, 052, 058, 063 và 3 API khác |
| ERR-12-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường | 76 API (xem OpenAPI) |
| ERR-12-004 | 422 | Đơn vị không tồn tại hoặc hết hiệu lực ở PH-07 | 003, 004, 033 |
| ERR-12-005 | 422 | Thư điện tử ngoài miền công vụ được phép | 003, 004 |
| ERR-12-006 | 409 | Chuyển trạng thái tài khoản không hợp lệ | 005, 006, 007, 008, 009, 012 |
| ERR-12-007 | 403 | Không có quyền | 103 API (xem OpenAPI) |
| ERR-12-008 | 403 | Vi phạm bốn mắt | 030, 038, 039, 097, 098 |
| ERR-12-009 | 409 | Cặp vai trò xung đột tách nhiệm vụ | 026 |
| ERR-12-010 | 422 | Giá trị hoặc thao tác không hợp lệ về nghiệp vụ (vai trò, phạm vi gán, quyền trong vai trò tùy biến, nhóm đơn vị, yếu tố cuối cùng) | 003, 022, 023, 024, 026, 029 và 5 API khác |
| ERR-12-011 | 409 | Vai trò hoặc nhóm còn đang được dùng | 023, 024, 034 |
| ERR-12-012 | 422 | Vòng lặp nhóm | 033, 034 |
| ERR-12-013 | 403 | Không được tự thao tác trên chính mình | 005, 006, 007, 015, 017, 018 và 2 API khác |
| ERR-12-014 | 400 | Thiếu lý do hoặc thông tin xác minh bắt buộc | 26 API (xem OpenAPI) |
| ERR-12-015 | 422 | Mật khẩu không đạt chính sách | Trang đặt mật khẩu của Keycloak (FR-12-006, 007) |
| ERR-12-016 | 410 | Liên kết kích hoạt hoặc đặt lại mật khẩu hết hạn hoặc đã dùng | Trang kích hoạt, đặt lại mật khẩu của Keycloak (FR-12-006, 007) |
| ERR-12-017 | 403 | Cần quản trị cấp trên để đặt lại yếu tố thứ hai | 015 |
| ERR-12-018 | 409 | HTTT đã có client | 058 |
| ERR-12-019 | 422 | Scope không có nguồn duyệt hoặc ngoài loại scope của nguồn | 058, 063, 068, 070 |
| ERR-12-020 | 409 | Client không ở trạng thái cho phép thao tác | 059, 060, 061, 062, 064, 065 và 3 API khác |
| ERR-12-021 | 422 | Chứng thư hoặc khóa công khai không hợp lệ | 058, 064, 065 |
| ERR-12-022 | 422 | Phương thức xác thực không đạt mức hợp đồng hoặc không áp dụng cho client | 058, 059, 064, 065, 066 |
| ERR-12-023 | 409 | Đang trong thời gian chuyển tiếp của lần xoay bí mật | 066 |
| ERR-12-024 | 422 | Chính sách sai cú pháp, biên dịch lỗi hoặc gói không hợp lệ | 091, 092, 094, 095, 102, 112 |
| ERR-12-025 | 409 | Còn ca kiểm thử không đạt hoặc chưa đủ ca dương, ca âm | 094, 096 |
| ERR-12-026 | 409 | Chưa chạy khô trên đúng nội dung hiện tại | 096 |
| ERR-12-027 | 409 | Chuyển trạng thái phiên bản chính sách không hợp lệ, hoặc thu hồi chính sách gốc | 030, 031, 092, 095, 096, 097 và 4 API khác |
| ERR-12-028 | 422 | Chính sách của tenant có luật cho phép hoặc nới quyền | 091, 092, 112 |
| ERR-12-029 | 409 | Thiếu xác nhận bổ sung khi chạy khô đổi quá ngưỡng | 097 |
| ERR-12-030 | 422 | Quyền có thời hạn vượt tối đa hoặc thiếu mã phiếu | 029, 036, 038 |
| ERR-12-031 | 409 | Chiến dịch rà soát đang mở hoặc đã đóng | 041, 043, 044 |
| ERR-12-032 | 422 | Liên kết LDAP, Active Directory không đạt kiểm tra | 048, 049, 050 |
| ERR-12-033 | 422 | Cấu hình SAML không hợp lệ | 052, 053 |
| ERR-12-034 | 409 | Số định danh VNeID đã liên kết với tài khoản khác | 054 |
| ERR-12-035 | 400 | Tệp nhập sai định dạng hoặc quá lớn (413 khi quá lớn) | 010 |
| ERR-12-036 | 422 | Vai trò hệ cũ chưa có ánh xạ | 010, 012 |
| ERR-12-037 | 429 | Vượt tần suất thao tác | 13 API (xem OpenAPI) |
| ERR-12-038 | 503 | Keycloak không khả dụng | 23 API (xem OpenAPI) |
| ERR-12-039 | 503 | OpenBao không khả dụng | 048, 058, 063, 066, 070, 071 và 1 API khác |
| ERR-12-040 | 503 | Phân hệ hoặc dịch vụ phụ thuộc không khả dụng (PH-01, PH-04, PH-07, PH-13, OPA, kho gói, bộ quét mã độc) | 003, 004, 045, 046, 058, 080 và 3 API khác |
| ERR-12-041 | 409 | Realm hoặc tenant không ở trạng thái cho phép thao tác | 045, 046, 070, 080, 082, 083 và 2 API khác |
| ERR-12-042 | 409 | Realm đang được đối chiếu hoặc áp cấu hình | 083, 084, 085 |
| ERR-12-043 | 422 | Vượt trần tham số hoặc giới hạn số lượng | 13 API (xem OpenAPI) |
| ERR-12-044 | 412 | Phiên bản đối tượng đã thay đổi (`If-Match`) | 32 API (xem OpenAPI) |
| ERR-12-045 | 422 | `Idempotency-Key` đã dùng với thân khác | 29 API (xem OpenAPI) |
| ERR-12-046 | 409 | Không thể gỡ hoặc vô hiệu quản trị tỉnh cuối cùng | 005, 007, 027 |
| ERR-12-047 | 422 | Trường do danh bạ LDAP quản lý, chỉ đọc | 004 |

: Mã lỗi control plane của PH-12

### 6.2. Lỗi runtime (ERR-12-101…125)

Các mã dưới đây phát sinh ở API quyết định (`/api/authz/v1`, thân RFC 9457) và ở điểm cuối OIDC của Keycloak (thân RFC 6749, mã chỉ ghi vào nhật ký và hiển thị ở trang của Keycloak).

| Mã | HTTP | Ý nghĩa | Nơi phát sinh |
|---|---|---|---|
| ERR-12-101 | 400 | Yêu cầu quyết định thiếu trường bắt buộc hoặc sai cấu trúc | API-12-086, API-12-087 |
| ERR-12-102 | 401 | Bên gọi quyết định chưa xác thực hoặc thiếu scope `iam:decide` | API-12-086, API-12-087, API-12-088 |
| ERR-12-103 | 500 | Lỗi đánh giá chính sách; bên gọi xử lý như từ chối | API-12-086, API-12-087, API-12-088 |
| ERR-12-104 | 503 | OPA quá tải hoặc chưa nạp gói; bên gọi xử lý như từ chối | API-12-086, API-12-087, API-12-088 |
| ERR-12-111 | 401 | Thông tin đăng nhập hoặc mã xác thực không đúng (`invalid_grant`) | API-12-074 |
| ERR-12-112 | 423 | Tài khoản bị khóa tạm | API-12-074 |
| ERR-12-113 | 403 | Tài khoản bị khóa hẳn hoặc vô hiệu | API-12-074 |
| ERR-12-114 | 400 | `state`, `code_verifier` hoặc `redirect_uri` không khớp, hoặc thiếu PKCE `S256` | API-12-073, API-12-074 |
| ERR-12-115 | 401 | Refresh token đã dùng lại, họ token bị thu hồi (`invalid_grant`) | API-12-074 |
| ERR-12-116 | 401 | Token hết hạn, bị thu hồi hoặc sai đối tượng | API-12-001, API-12-002, API-12-003, API-12-004, API-12-005, API-12-006, API-12-007, API-12-008, API-12-009, API-12-010, API-12-011, API-12-012, API-12-013, API-12-014, API-12-015, API-12-016, API-12-017, API-12-018, API-12-019, API-12-020, API-12-021, API-12-022, API-12-023, API-12-024, API-12-025, API-12-026, API-12-027, API-12-028, API-12-029, API-12-030, API-12-031, API-12-032, API-12-033, API-12-034, API-12-035, API-12-036, API-12-037, API-12-038, API-12-039, API-12-040, API-12-041, API-12-042, API-12-043, API-12-044, API-12-045, API-12-046, API-12-047, API-12-048, API-12-049, API-12-050, API-12-051, API-12-052, API-12-053, API-12-054, API-12-055, API-12-056, API-12-057, API-12-058, API-12-059, API-12-060, API-12-061, API-12-062, API-12-063, API-12-064, API-12-065, API-12-066, API-12-067, API-12-068, API-12-069, API-12-070, API-12-071, API-12-076, API-12-078, API-12-079, API-12-080, API-12-081, API-12-082, API-12-083, API-12-084, API-12-085, API-12-089, API-12-090, API-12-091, API-12-092, API-12-093, API-12-094, API-12-095, API-12-096, API-12-097, API-12-098, API-12-099, API-12-100, API-12-101, API-12-102, API-12-103, API-12-104, API-12-105, API-12-106, API-12-107, API-12-108, API-12-109, API-12-110, API-12-111, API-12-112, API-12-113 |
| ERR-12-117 | 401 | Xác thực client thất bại (`invalid_client`) | API-12-074, API-12-077 |
| ERR-12-118 | 403 | Client bị tạm ngừng hoặc thu hồi (`unauthorized_client`) | API-12-074 |
| ERR-12-119 | 400 | Scope giao rỗng (`invalid_scope`) | API-12-074 |
| ERR-12-120 | 401 | Cần xác thực bước lên (`insufficient_user_authentication`), dùng cho API quản trị của PH-12 chứ không chỉ cho Keycloak | API-12-003, API-12-004, API-12-005, API-12-006, API-12-007, API-12-008, API-12-009, API-12-010, API-12-012, API-12-015, API-12-017, API-12-018, API-12-022, API-12-023, API-12-024, API-12-026, API-12-027, API-12-029, API-12-030, API-12-031, API-12-033, API-12-034, API-12-035, API-12-036, API-12-038, API-12-039, API-12-040, API-12-041, API-12-044, API-12-048, API-12-049, API-12-050, API-12-052, API-12-053, API-12-055, API-12-059, API-12-060, API-12-061, API-12-062, API-12-064, API-12-065, API-12-066, API-12-070, API-12-071, API-12-074, API-12-083, API-12-084, API-12-085, API-12-097, API-12-098, API-12-099, API-12-100, API-12-111, API-12-112 |
| ERR-12-121 | 403 | Tenant tạm ngừng hoặc realm không hoạt động | API-12-073, API-12-074 |
| ERR-12-122 | 400 | Grant hoặc loại phản hồi bị cấm (`unsupported_grant_type`) | API-12-073, API-12-074 |
| ERR-12-123 | 400 | Yêu cầu XACML sai lược đồ (phản hồi `Indeterminate`) | API-12-088 |
| ERR-12-124 | 403 | Không ghi được vết cho tài nguyên mức Nhạy cảm nên từ chối phục vụ | Thư viện PEP và plugin `dh-authz` (AuditGate), không qua API công bố |
| ERR-12-125 | 429 | Vượt tần suất đăng nhập hoặc cấp token | API-12-074 |

: Mã lỗi runtime của PH-12

### 6.3. Thông báo hiển thị theo mã lỗi

Bảng sau lấy nguyên từ FRS §9.2 để hai tài liệu không lệch; nguồn chuẩn của câu hiển thị là D03-06-PH12 §5.2.

| Mã | Câu hiển thị | Vị trí |
|---|---|---|
| ERR-12-002 | "Tên đăng nhập hoặc thư điện tử này đã được dùng. Chọn giá trị khác." Với mã nhóm trùng: "Mã nhóm này đã được dùng. Chọn mã khác." | Dưới trường nhập |
| ERR-12-004 | "Đơn vị {mã} không tồn tại hoặc đã hết hiệu lực." | Dưới trường đơn vị |
| ERR-12-005 | "Thư điện tử phải thuộc miền {danh sách miền} của tỉnh." | Dưới trường thư |
| ERR-12-007 | "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền." | Thông báo nổi hoặc trang PTN-13 |
| ERR-12-008 | "Anh/chị là người đề nghị hoặc người soạn nên không được tự duyệt." | Hộp duyệt |
| ERR-12-009 | "Anh/chị không được giữ cùng lúc {vai trò A} và {vai trò B}: {lý do}. Có thể đề nghị ngoại lệ có thời hạn." | Hộp gán vai trò |
| ERR-12-013 | "Anh/chị không thể tự thực hiện thao tác này với tài khoản của mình." | Hộp xác nhận |
| ERR-12-014 | "Nhập lý do (ít nhất 10 ký tự)." | Dưới ô lý do |
| ERR-12-015 | "Mật khẩu cần ít nhất 14 ký tự, không trùng mật khẩu đã bị lộ và không chứa tên đăng nhập." | Trang đặt mật khẩu của Keycloak |
| ERR-12-016 | "Liên kết đã hết hạn hoặc đã được dùng. Liên hệ quản trị tỉnh để được gửi liên kết mới." | Trang của Keycloak |
| ERR-12-020 | "Danh tính của HTTT đang ở trạng thái {trạng thái}, không thực hiện được thao tác này." | Thông báo nổi |
| ERR-12-022 | "Hợp đồng mức {mức} cần xác thực bằng chứng thư mTLS hoặc khóa công khai, không dùng bí mật chia sẻ." | Dưới trường phương thức |
| ERR-12-023 | "Đang có lần xoay bí mật trong thời gian chuyển tiếp tới {thời điểm}." | Hộp xoay bí mật |
| ERR-12-025 | "Còn {n} ca kiểm thử không đạt hoặc chưa có ca âm." | Khung kiểm thử UI-12-12 |
| ERR-12-026 | "Chưa chạy khô trên đúng nội dung hiện tại." | Nút Gửi duyệt |
| ERR-12-029 | "Thay đổi này đổi {tỷ lệ}% quyết định. Tích xác nhận và nhập ý kiến để tiếp tục." | Hộp duyệt UI-12-13 |
| ERR-12-030 | "Quyền có thời hạn tối đa 4 giờ và phải kèm mã phiếu hỗ trợ." | Biểu mẫu UI-12-08 |
| ERR-12-037 | "Thao tác quá nhiều lần. Thử lại sau {n} phút." | Thông báo nổi |
| ERR-12-038 | "Hệ thống xác thực tạm thời không khả dụng. Thử lại sau ít phút." | Dải cảnh báo đầu trang |
| ERR-12-039 | "Kho bí mật tạm thời không khả dụng; chưa lưu hoặc chưa xoay. Thử lại sau." | Hộp cảnh báo lỗi |
| ERR-12-043 | "Giá trị vượt giới hạn cho phép ({tối thiểu} đến {tối đa})." | Dưới trường tham số |
| ERR-12-044 | "Thông tin này vừa được người khác sửa. Tải lại trang để xem bản mới nhất." | Thông báo nổi |
| ERR-12-046 | "Tỉnh phải còn ít nhất một quản trị tỉnh đang hoạt động." | Hộp xác nhận |
| ERR-12-111 | "Tên đăng nhập hoặc mật khẩu không đúng." | Trang đăng nhập |
| ERR-12-112 | "Tài khoản tạm khóa do đăng nhập sai nhiều lần. Thử lại sau {n} phút." | Trang đăng nhập |
| ERR-12-113 | "Tài khoản đã bị khóa. Liên hệ quản trị tỉnh." | Trang đăng nhập |
| ERR-12-114 | "Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại." | Trang đăng nhập |
| ERR-12-115 | "Phiên đăng nhập đã bị đóng vì lý do an toàn. Vui lòng đăng nhập lại." | Trang đăng nhập |
| ERR-12-116 | "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." | Trang đăng nhập |
| ERR-12-120 | "Cần xác thực lại để thực hiện thao tác này." | Hộp Xác nhận lại danh tính |
| ERR-12-121 | "Tỉnh {tên} đang tạm ngừng hoạt động." | Trang đăng nhập |
| ERR-12-124 | "Hệ thống chưa ghi được vết truy cập nên không phục vụ dữ liệu này. Thử lại sau." | Trang lỗi PTN-13 |
| ERR-12-125 | "Quá nhiều lần thử. Vui lòng đợi {n} phút rồi thử lại." | Trang đăng nhập |

: Thông báo hiển thị theo mã lỗi
<!-- gen:errors:end -->

### 6.4. Lý do từ chối trong phản hồi quyết định

Từ chối là kết quả hợp lệ (`200`, `allow=false`), không phải mã lỗi. `reason` do hệ thống đặt; bên thực thi đổi thành `403`, `404` hoặc `401` như bảng.

| Lý do (`reason`) | Ý nghĩa | HTTP ở bên thực thi |
|---|---|---|
| `NO_MATCHING_POLICY` | Không có luật cho phép nào khớp | 403 hoặc 404 |
| `TENANT_MISMATCH` | Tenant yêu cầu khác tenant tài nguyên, không có quyền có thời hạn hợp lệ | 404 |
| `DATA_CLASSIFIED_SECRET` | Tài nguyên mang nhãn bí mật nhà nước | 403 |
| `PURPOSE_NOT_DECLARED` | Dữ liệu mức Hạn chế trở lên thiếu mục đích khai thác | 403 |
| `SCOPE_MISSING` | Scope của client không có hoặc không còn trong dữ liệu gói | 403 |
| `ROLE_MISSING` | Người dùng không có vai trò mang quyền yêu cầu | 403 |
| `ORG_SCOPE_MISMATCH` | Tài nguyên ngoài phạm vi tổ chức của vai trò | 404 |
| `SELF_APPROVAL` | Người duyệt trùng người tạo hoặc người gửi | 403 |
| `STEPUP_REQUIRED` | Chưa đạt mức xác thực hoặc `auth_time` quá cũ | 401 |
| `CLIENT_SUSPENDED` | Client bị tạm ngừng hoặc thu hồi | 403 |
| `TENANT_SUSPENDED` | Tenant tạm ngừng, hoặc realm chỉ-đọc với thao tác ghi | 403 |
| `GRANT_EXPIRED` | Quyền có thời hạn hoặc gán vai trò đã quá hạn | 403 |
| `AUDIT_UNAVAILABLE` | Không ghi được vết cho tài nguyên mức Nhạy cảm | 403 |
| `POLICY_ERROR` | Lỗi đánh giá, quá thời gian chờ hoặc chưa nạp gói | 403 |

: Lý do từ chối và mã HTTP ở bên thực thi

Lý do `MATCHED_POLICY` đi kèm `allow=true`. Với dữ liệu mức Nhạy cảm, nếu không ghi được vết thì bên thực thi từ chối phục vụ và trả ERR-12-124.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng chỉ có giá trị khi máy kiểm được. Các kiểm dưới đây chạy ở cổng CI-5 (D04-02) mỗi khi `03-thiet-ke/api/ph12/` thay đổi; tệp YAML là sản phẩm sinh nên kiểm cũng bao gồm việc sinh lại không làm đổi tệp.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; ví dụ khớp lược đồ; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`; lệnh ghi có `If-Match` | `check_contracts.py` (`openapi-spec-validator`, `jsonschema`) | CI-5 |
| Mã `API-12-001…113` đủ, khớp phương thức và đường dẫn ở FRS §9.4; mọi `ERR-12-*` của OpenAPI có trong FRS §9.1 | `check_contracts.py` | CI-5 |
| Không trường bí mật ngoài lược đồ chỉ ghi; `writeOnly` ở `bindSecret`, `client_secret` | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0 hợp lệ; `EVT-12-01…16` đủ; topic đúng mẫu `{tenant}.iam.….v1`; payload không trường bí mật | `check_contracts.py` và `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước (hậu tố hành động, `problem+json`, phân trang) | Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Hợp đồng quyết định giữa APISIX, thư viện PEP và API `decide` | Bộ fixture `DecisionRequest` → `DecisionResult` dùng chung, chạy ở cả ba nơi | CI-5, CI-6 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp FRS | `build/tools/kiem_tra_ma.py` | CI-1 |

: Kiểm tra hợp đồng trong CI

Kết quả ngày 26/11/2026: OpenAPI hợp lệ với 113 operation, 9 ví dụ khớp lược đồ; AsyncAPI hợp lệ, 16 kênh, không lỗi (một khuyến nghị nâng phiên bản 3.1 của bộ phân tích, không áp dụng vì cả bộ tài liệu dùng 3.0).

## 8. Ánh xạ từ hệ cũ

PH-12 phủ tám mục `LGC-IAM` của hệ cũ (D00-03 §4.8) và API quyết định của SRS cũ `docs/07-srs/SRS-PH-12-iam.md`. Bảng dưới nối từng chức năng cũ với API mới.

| Hệ cũ | Kết luận | API mới | Ghi chú |
|---|---|---|---|
| LGC-IAM-001 Đăng nhập một lần bằng Keycloak | Giữ nguyên | API-12-072…078 | Realm theo tenant `dh-{tenant}` thay realm chung `lgsp`; đường `/realms/lgsp/protocol/openid-connect/*` đổi theo realm |
| LGC-IAM-002 Tạo realm, client, vai trò, người dùng, gán vai trò | Nâng cấp | API-12-080 (realm), 058 (client), 003 (người dùng), 019…027 (vai trò, gán) | Realm tạo tự động từ mẫu bởi saga của PH-20 |
| LGC-IAM-003 Xác thực hai yếu tố TOTP | Nâng cấp | Luồng của Keycloak; API-12-015 (đặt lại), 002 (xem yếu tố) | Bắt buộc với vai trò quản trị; thêm WebAuthn |
| LGC-IAM-004 Liên kết LDAP, AD | Giữ nguyên | API-12-047…050 | Chỉ LDAPS; bật cần cán bộ ATTT duyệt |
| LGC-IAM-005 Quản lý phiên | Giữ nguyên | API-12-016, 017 | Thêm thu hồi tức thời API-12-018 |
| LGC-IAM-006 Lấy token bằng grant `password` | Thay thế | API-12-073 (Authorization Code + PKCE), API-12-074 (`client_credentials`) | Grant `password` bị cấm: ERR-12-122 |
| LGC-IAM-007 Đăng nhập mạng xã hội | Loại bỏ | Không | Thay bằng VNeID (API-12-054, 055, Đợt 2) |
| LGC-IAM-008 SSO SAML của midPoint | Thay thế | OIDC (API-12-072…078); SAML cho ứng dụng cũ API-12-051…053 | Thống nhất về Keycloak |
| SRS cũ: `POST /api/authz/v1/decide` | Giữ nguyên | API-12-086 | Cấu trúc `DecisionRequest`, `DecisionResult` theo SDD §3.4 |
| SRS cũ: `POST /api/authz/v1/decide/batch` | Đổi đường dẫn | API-12-087 `POST /api/authz/v1/decide:batch` | Đổi theo quy ước hành động AIP-136; tối đa 100 phần tử; bí danh cũ trong giai đoạn song song: Q12-55 |
| SRS cũ: `POST /api/authz/v1/xacml` | Giữ nguyên | API-12-088 | Thêm bộ chuyển đổi XACML 3.0 JSON profile |

: Ánh xạ từ hệ cũ sang API PH-12

## 9. Câu hỏi mở

> **Câu hỏi mở Q12-55:** Đường dẫn quyết định theo lô của hệ cũ là `/api/authz/v1/decide/batch`, tập này đổi thành `/api/authz/v1/decide:batch` theo quy ước hành động. Cần xác nhận có bên nào của hệ cũ hoặc bộ kiểm thử còn gọi đường cũ trong giai đoạn chạy song song (strangler) để giữ bí danh trong 6 tháng, hay chuyển thẳng. Đề xuất: giữ bí danh ở APISIX (viết lại đường dẫn), không thêm operation mới.

> **Câu hỏi mở Q12-56:** Điểm cuối nội bộ nhận trạng thái nạp gói của OPA (plugin `status`) chưa có mã API. Cần PH-03 và ATTT chốt đường dẫn, xác thực (mTLS theo danh tính pod) và quyết định có đưa vào danh mục thành một operation mới (mã kế tiếp của dải) hay giữ ngoài danh mục như một giao diện hạ tầng. Đề xuất: giữ ngoài danh mục, mô tả ở SDD, vì bên gọi duy nhất là OPA.

> **Câu hỏi mở Q12-57:** `GET /decisions` và `GET /security-events` dùng phân trang `page`/`size` theo D00-04 §4, trong khi khối lượng bản ghi lớn (giả định: tỉnh vừa khoảng 5 triệu quyết định lưu mỗi tháng sau lấy mẫu) khiến offset sâu chậm. Cần quyết định có cho hai API này dùng phân trang con trỏ như PH-05 hay giới hạn `page × size` không quá 10.000 và buộc lọc theo `from`, `to`. Đề xuất: giới hạn 10.000 bản ghi và bắt buộc khoảng thời gian không quá 31 ngày.

> **Câu hỏi mở Q12-58:** Khi gói dữ liệu của tenant vượt ngưỡng chế độ đẩy (Q12-20 của SDD), OPA chuyển sang chế độ kéo bằng scope `iam:policy-data-read`, nhưng bản này chưa công bố API tương ứng. Cần xác nhận sau khi đo có cần thêm `GET /policy-data` (một operation mới ở mã kế tiếp của dải, trả gói theo `If-None-Match`) hay chỉ chia dữ liệu theo đơn vị mà vẫn đẩy qua bucket.

> **Câu hỏi Q12-59 (đã chốt 27/11/2026):** Chủ đầu tư chốt 27/11/2026: danh sách mức xác thực bước lên của từng operation (40 operation mức 2, 13 mức 3, khóa `x-datahub-acr`) do cán bộ ATTT cùng quản trị nền tảng duyệt, rồi ghi thành bảng ở D02-03-PH12 mục 4.8 lấy từ `x-datahub-acr` của OpenAPI. *Câu hỏi gốc:* ai duyệt danh sách mức xác thực bước lên trước khi thư viện PEP áp dụng, đặc biệt mức 3 cho thu hồi client và duyệt quyền có thời hạn.

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.

<!-- gen:dac-ta-api:start -->

### Người dùng và phiên

#### API-12-001 · Danh sách, tìm kiếm, lọc người dùng

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm, lọc người dùng.

**Phương thức, đường dẫn.** `GET /users`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-001.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `state` (query, UserState, tùy chọn); `orgCode` (query, string, tùy chọn); `roleCode` (query, string, tùy chọn); `mfa` (query, string, tùy chọn); `authSource` (query, AuthSource, tùy chọn); `inactiveDays` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserPage`; trường bắt buộc: `items`, `page`; tiêu đề `X-DH-Projection-Lag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `facets` kèm số người dùng thuộc nhóm bắt buộc MFA mà chưa có (`mfaRequiredMissing`) và số tài khoản sắp bị vô hiệu vì không dùng (`inactivitySoon`); lọc theo MFA bằng tham số `mfa`. Bản chiếu `ph12_iam` của tenant hiện hành; có thể chậm so với Keycloak, kèm tiêu đề `X-DH-Projection-Lag` (giây). `BLOCKED`, `LOCKED` xếp đầu khi không có `sort`.
:::

#### API-12-002 · Chi tiết người dùng

::: dac-ta
**Mục đích.** Chi tiết người dùng.

**Phương thức, đường dẫn.** `GET /users/{userId}`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-002, FR-12-022.

**Tham số.** `userId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả `factors[]` chỉ gồm loại và nhãn; quyền `PERM-12-read` không xem được bí mật yếu tố xác thực.
:::

#### API-12-003 · Tạo tài khoản người dùng

::: dac-ta
**Mục đích.** Tạo tài khoản người dùng.

**Phương thức, đường dẫn.** `POST /users`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-003.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UserCreate`; trường bắt buộc: `username`, `fullName`, `email`, `orgCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-004, ERR-12-005, ERR-12-007, ERR-12-010, ERR-12-037, ERR-12-038, ERR-12-040, ERR-12-043, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo ở Keycloak (`PENDING_ACTIVATION`) và gửi liên kết kích hoạt hiệu lực 24 giờ; phản hồi không có mật khẩu hay liên kết.
:::

#### API-12-004 · Sửa thông tin, chuyển đơn vị người dùng

::: dac-ta
**Mục đích.** Sửa thông tin, chuyển đơn vị người dùng.

**Phương thức, đường dẫn.** `PATCH /users/{userId}`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-004.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UserUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-004, ERR-12-005, ERR-12-007, ERR-12-038, ERR-12-040, ERR-12-044, ERR-12-047, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đổi đơn vị làm vai trò phạm vi đơn vị cũ hết hiệu lực; phát EVT-12-02.
:::

#### API-12-005 · Khóa tài khoản

::: dac-ta
**Mục đích.** Khóa tài khoản.

**Phương thức, đường dẫn.** `POST /users/{userId}:lock`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-005.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-006, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-044, ERR-12-046, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khóa hẳn (`BLOCKED`), hủy mọi phiên. Không tự khóa chính mình.
:::

#### API-12-006 · Mở khóa tài khoản

::: dac-ta
**Mục đích.** Mở khóa tài khoản.

**Phương thức, đường dẫn.** `POST /users/{userId}:unlock`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-005.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-006, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mở khóa `LOCKED` hoặc `BLOCKED`.
:::

#### API-12-007 · Vô hiệu tài khoản

::: dac-ta
**Mục đích.** Vô hiệu tài khoản.

**Phương thức, đường dẫn.** `POST /users/{userId}:disable`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-005.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-006, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-044, ERR-12-046, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vô hiệu (`DISABLED`), không xóa vật lý (BR-12-035). Quản trị tỉnh cuối cùng không vô hiệu được.
:::

#### API-12-008 · Kích hoạt lại tài khoản

::: dac-ta
**Mục đích.** Kích hoạt lại tài khoản.

**Phương thức, đường dẫn.** `POST /users/{userId}:enable`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-005.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-006, ERR-12-007, ERR-12-014, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kích hoạt lại từ `DISABLED` về `PENDING_ACTIVATION` hoặc `ACTIVE` theo lịch sử kích hoạt.
:::

#### API-12-009 · Gửi lại liên kết kích hoạt

::: dac-ta
**Mục đích.** Gửi lại liên kết kích hoạt.

**Phương thức, đường dẫn.** `POST /users/{userId}:resend-activation`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-003, FR-12-006.

**Tham số.** `userId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-006, ERR-12-007, ERR-12-037, ERR-12-038, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ khi `PENDING_ACTIVATION`; liên kết cũ vô hiệu.
:::

#### API-12-015 · Đặt lại yếu tố thứ hai

::: dac-ta
**Mục đích.** Đặt lại yếu tố thứ hai.

**Phương thức, đường dẫn.** `POST /users/{userId}:reset-mfa`.

**Quyền.** `PERM-12-mfa-reset`.

**FR hiện thực.** FR-12-024.

**Tham số.** `userId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResetMfaRequest`; trường bắt buộc: `reason`, `verificationMethod`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-017, ERR-12-037, ERR-12-038, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quản trị cấp trên đặt lại yếu tố thứ hai; tài khoản quản trị cần SO duyệt (ERR-12-017).
:::

#### API-12-016 · Danh sách phiên của người dùng

::: dac-ta
**Mục đích.** Danh sách phiên của người dùng.

**Phương thức, đường dẫn.** `GET /users/{userId}/sessions`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-029.

**Tham số.** `userId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SessionList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên đang mở của người dùng từ Keycloak.
:::

#### API-12-017 · Buộc đăng xuất mọi phiên

::: dac-ta
**Mục đích.** Buộc đăng xuất mọi phiên.

**Phương thức, đường dẫn.** `POST /users/{userId}:sign-out`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-029.

**Tham số.** `userId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy mọi phiên; token đã cấp còn tối đa 5 phút trừ khi thu hồi tức thời (API-12-018).
:::

### Nhập người dùng

#### API-12-010 · Tải tệp nhập người dùng để kiểm tra

::: dac-ta
**Mục đích.** Tải tệp nhập người dùng để kiểm tra.

**Phương thức, đường dẫn.** `POST /user-imports`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-009.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: object.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `UserImport`; trường bắt buộc: `importId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `413`, `422`, `429`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-035, ERR-12-036, ERR-12-037, ERR-12-043, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Pha 1: kiểm tra toàn bộ tệp, chưa tạo tài khoản; trả báo cáo lỗi theo dòng (tối đa 200 lỗi). Quá 5 MiB trả 413 kèm ERR-12-035.
:::

#### API-12-011 · Kết quả kiểm tra tệp nhập

::: dac-ta
**Mục đích.** Kết quả kiểm tra tệp nhập.

**Phương thức, đường dẫn.** `GET /user-imports/{importId}`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-009.

**Tham số.** `importId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserImport`; trường bắt buộc: `importId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo dõi pha kiểm tra và pha ghi nhận.
:::

#### API-12-012 · Ghi nhận tệp nhập, tạo tài khoản

::: dac-ta
**Mục đích.** Ghi nhận tệp nhập, tạo tài khoản.

**Phương thức, đường dẫn.** `POST /user-imports/{importId}:commit`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-009.

**Tham số.** `importId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UserImportCommit`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-006, ERR-12-007, ERR-12-036, ERR-12-037, ERR-12-038, ERR-12-043, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Pha 2: tạo tài khoản; từng dòng độc lập, dòng lỗi không chặn dòng đúng khi `skipErrorRows=true`.
:::

### Vai trò, quyền và gán vai trò

#### API-12-013 · Quyền hiệu lực của người dùng

::: dac-ta
**Mục đích.** Quyền hiệu lực của người dùng.

**Phương thức, đường dẫn.** `GET /users/{userId}/effective-permissions`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-016, FR-12-046.

**Tham số.** `userId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EffectivePermissions`; trường bắt buộc: `userId`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyền hiệu lực tính từ vai trò, nhóm, quyền có thời hạn, ngoại lệ; giải thích nguồn từng quyền.
:::

#### API-12-019 · Danh mục vai trò

::: dac-ta
**Mục đích.** Danh mục vai trò.

**Phương thức, đường dẫn.** `GET /roles`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-011.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `kind` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RolePage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vai trò chuẩn và vai trò tùy biến của tenant.
:::

#### API-12-020 · Chi tiết vai trò và quyền

::: dac-ta
**Mục đích.** Chi tiết vai trò và quyền.

**Phương thức, đường dẫn.** `GET /roles/{roleCode}`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-011.

**Tham số.** `roleCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Role`; trường bắt buộc: `roleCode`, `name`, `kind`, `permissions`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-021 · Danh mục quyền PERM

::: dac-ta
**Mục đích.** Danh mục quyền PERM.

**Phương thức, đường dẫn.** `GET /permissions`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-011.

**Tham số.** `roleCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PermissionList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ma trận quyền D02-08; sinh từ cùng nguồn với dữ liệu OPA.
:::

#### API-12-022 · Tạo vai trò tùy biến (Đợt 2)

::: dac-ta
**Mục đích.** Tạo vai trò tùy biến (Đợt 2).

**Phương thức, đường dẫn.** `POST /roles`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-015.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoleCreate`; trường bắt buộc: `roleCode`, `name`, `permissions`, `scopeTypes`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Role`; trường bắt buộc: `roleCode`, `name`, `kind`, `permissions`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-043, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2; cần `12.role.custom-enabled`. Vai trò tùy biến không được chứa quyền của vai trò quản trị nền tảng.
:::

#### API-12-023 · Sửa vai trò tùy biến (Đợt 2)

::: dac-ta
**Mục đích.** Sửa vai trò tùy biến (Đợt 2).

**Phương thức, đường dẫn.** `PATCH /roles/{roleCode}`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-015.

**Tham số.** `roleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoleUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Role`; trường bắt buộc: `roleCode`, `name`, `kind`, `permissions`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-011, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2. Vai trò chuẩn không sửa được.
:::

#### API-12-024 · Ngừng dùng vai trò tùy biến (Đợt 2)

::: dac-ta
**Mục đích.** Ngừng dùng vai trò tùy biến (Đợt 2).

**Phương thức, đường dẫn.** `POST /roles/{roleCode}:retire`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-015.

**Tham số.** `roleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Role`; trường bắt buộc: `roleCode`, `name`, `kind`, `permissions`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-011, ERR-12-014, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2. Còn gán thì ERR-12-011.
:::

#### API-12-025 · Danh sách gán vai trò

::: dac-ta
**Mục đích.** Danh sách gán vai trò.

**Phương thức, đường dẫn.** `GET /role-assignments`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-012, FR-12-016.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `userId` (query, string, tùy chọn); `roleCode` (query, string, tùy chọn); `state` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RoleAssignmentPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-026 · Gán vai trò cho người dùng

::: dac-ta
**Mục đích.** Gán vai trò cho người dùng.

**Phương thức, đường dẫn.** `POST /role-assignments`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoleAssignmentCreate`; trường bắt buộc: `userId`, `roleCode`, `scopeType`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RoleAssignment`; trường bắt buộc: `assignmentId`, `userId`, `roleCode`, `scopeType`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-009, ERR-12-010, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chặn cặp xung đột tách nhiệm vụ (ERR-12-009) trừ khi có `sodExceptionId` còn hiệu lực; không tự gán cho mình.
:::

#### API-12-027 · Gỡ vai trò

::: dac-ta
**Mục đích.** Gỡ vai trò.

**Phương thức, đường dẫn.** `DELETE /role-assignments/{assignmentId}`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-012.

**Tham số.** `assignmentId` (path, string, bắt buộc); `reason` (query, string, tùy chọn); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-038, ERR-12-044, ERR-12-046, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ vai trò; yêu cầu `reason` ở tham số truy vấn.
:::

### Tham số và danh bạ

#### API-12-014 · Tra danh bạ người dùng (thông tin tối thiểu)

::: dac-ta
**Mục đích.** Tra danh bạ người dùng (thông tin tối thiểu).

**Phương thức, đường dẫn.** `GET /directory/users`.

**Quyền.** scope `iam:directory-read`.

**FR hiện thực.** FR-12-062.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `orgCode` (query, string, tùy chọn); `state` (query, UserState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DirectoryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-037, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tenant lấy từ token dịch vụ. Chỉ thông tin tối thiểu (BR-12-042).
:::

#### API-12-110 · Tham số phân hệ của tenant

::: dac-ta
**Mục đích.** Tham số phân hệ của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-061.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `values`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-111 · Sửa tham số phân hệ trong trần

::: dac-ta
**Mục đích.** Sửa tham số phân hệ trong trần.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-061.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsUpdate`; trường bắt buộc: `values`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `values`, `version`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-043, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tham số bảo mật của realm được áp bằng GitOps (FR-12-042).
:::

### Thu hồi truy cập

#### API-12-018 · Thu hồi truy cập tức thời của người dùng

::: dac-ta
**Mục đích.** Thu hồi truy cập tức thời của người dùng.

**Phương thức, đường dẫn.** `POST /users/{userId}:revoke-access`.

**Quyền.** `PERM-12-user-lock`.

**FR hiện thực.** FR-12-040.

**Tham số.** `userId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevokeAccessRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `RevocationAccepted`; trường bắt buộc: `revocationId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-013, ERR-12-014, ERR-12-037, ERR-12-038, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vô hiệu, hủy phiên, thu hồi refresh token và ghi mục danh sách chặn; hiệu lực ở cổng ≤ 60 giây.
:::

#### API-12-079 · Danh sách chặn truy cập cho APISIX và DU

::: dac-ta
**Mục đích.** Danh sách chặn truy cập cho APISIX và DU.

**Phương thức, đường dẫn.** `GET /revocations`.

**Quyền.** scope `iam:revocation-read`.

**FR hiện thực.** FR-12-040.

**Tham số.** `If-None-Match` (header, string, tùy chọn); `X-DH-Applied-Version` (header, integer, tùy chọn); `X-DH-Node` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevocationFeed`; trường bắt buộc: `version`, `entries`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** APISIX kéo mỗi 10 giây; báo phiên bản đã áp dụng bằng tiêu đề `X-DH-Applied-Version` và nút bằng `X-DH-Node`. `ETag` là `version`.
:::

### Tách nhiệm vụ

#### API-12-028 · Danh sách cặp vai trò xung đột

::: dac-ta
**Mục đích.** Danh sách cặp vai trò xung đột.

**Phương thức, đường dẫn.** `GET /sod-rules`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-013.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SodRuleList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bảy cặp xung đột ở D02-08 §4.
:::

#### API-12-029 · Đề nghị ngoại lệ tách nhiệm vụ

::: dac-ta
**Mục đích.** Đề nghị ngoại lệ tách nhiệm vụ.

**Phương thức, đường dẫn.** `POST /sod-exceptions`.

**Quyền.** `PERM-12-sod-exception`.

**FR hiện thực.** FR-12-013.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SodExceptionCreate`; trường bắt buộc: `userId`, `roleToAssign`, `roleToRemove`, `expiresAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SodException`; trường bắt buộc: `exceptionId`, `userId`, `state`, `expiresAt`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-014, ERR-12-030, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quản trị tỉnh đề nghị; SO duyệt; tối đa 90 ngày.
:::

#### API-12-030 · Duyệt hoặc từ chối ngoại lệ tách nhiệm vụ

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối ngoại lệ tách nhiệm vụ.

**Phương thức, đường dẫn.** `POST /sod-exceptions/{exceptionId}:decide`.

**Quyền.** `PERM-12-approve`.

**FR hiện thực.** FR-12-013.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SodDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SodException`; trường bắt buộc: `exceptionId`, `userId`, `state`, `expiresAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-008, ERR-12-014, ERR-12-027, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người đề nghị (bốn mắt).
:::

#### API-12-031 · Thu hồi ngoại lệ tách nhiệm vụ

::: dac-ta
**Mục đích.** Thu hồi ngoại lệ tách nhiệm vụ.

**Phương thức, đường dẫn.** `POST /sod-exceptions/{exceptionId}:revoke`.

**Quyền.** `PERM-12-approve`.

**FR hiện thực.** FR-12-013.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SodException`; trường bắt buộc: `exceptionId`, `userId`, `state`, `expiresAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-027, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vai trò đã gán nhờ ngoại lệ bị gỡ.
:::

### Nhóm và đơn vị

#### API-12-032 · Danh sách nhóm, đơn vị tổ chức

::: dac-ta
**Mục đích.** Danh sách nhóm, đơn vị tổ chức.

**Phương thức, đường dẫn.** `GET /groups`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-014.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `kind` (query, string, tùy chọn); `parentGroupId` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GroupPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-033 · Tạo nhóm

::: dac-ta
**Mục đích.** Tạo nhóm.

**Phương thức, đường dẫn.** `POST /groups`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GroupCreate`; trường bắt buộc: `code`, `name`, `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Group`; trường bắt buộc: `groupId`, `code`, `name`, `kind`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-004, ERR-12-007, ERR-12-010, ERR-12-012, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-034 · Sửa nhóm

::: dac-ta
**Mục đích.** Sửa nhóm.

**Phương thức, đường dẫn.** `PATCH /groups/{groupId}`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-014.

**Tham số.** `groupId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GroupUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Group`; trường bắt buộc: `groupId`, `code`, `name`, `kind`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-011, ERR-12-012, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đổi cha không được tạo vòng lặp (ERR-12-012).
:::

#### API-12-035 · Đặt danh sách thành viên nhóm

::: dac-ta
**Mục đích.** Đặt danh sách thành viên nhóm.

**Phương thức, đường dẫn.** `PUT /groups/{groupId}/members`.

**Quyền.** `PERM-12-user-admin`.

**FR hiện thực.** FR-12-014.

**Tham số.** `groupId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GroupMembers`; trường bắt buộc: `userIds`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Group`; trường bắt buộc: `groupId`, `code`, `name`, `kind`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-043, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thay thế toàn bộ danh sách thành viên.
:::

### Quyền có thời hạn

#### API-12-036 · Đề nghị quyền có thời hạn

::: dac-ta
**Mục đích.** Đề nghị quyền có thời hạn.

**Phương thức, đường dẫn.** `POST /privileged-grants`.

**Quyền.** `PERM-12-jit-request`.

**FR hiện thực.** FR-12-017.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PrivilegedGrantCreate`; trường bắt buộc: `type`, `targetTenant`, `roleCode`, `durationMinutes`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PrivilegedGrant`; trường bắt buộc: `grantId`, `type`, `targetTenant`, `roleCode`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-010, ERR-12-030, ERR-12-037, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối đa `12.jit.max-hours`; kèm mã phiếu hỗ trợ. Người đề nghị không được tự duyệt.
:::

#### API-12-037 · Danh sách quyền có thời hạn

::: dac-ta
**Mục đích.** Danh sách quyền có thời hạn.

**Phương thức, đường dẫn.** `GET /privileged-grants`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-017, FR-12-027.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `state` (query, string, tùy chọn); `requesterId` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PrivilegedGrantPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người dùng nền tảng chỉ thấy quyền của mình; quản trị tỉnh thấy quyền vào tenant của mình.
:::

#### API-12-038 · Duyệt quyền có thời hạn

::: dac-ta
**Mục đích.** Duyệt quyền có thời hạn.

**Phương thức, đường dẫn.** `POST /privileged-grants/{grantId}:approve`.

**Quyền.** `PERM-12-jit-approve`.

**FR hiện thực.** FR-12-017.

**Tham số.** `grantId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionComment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PrivilegedGrant`; trường bắt buộc: `grantId`, `type`, `targetTenant`, `roleCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-008, ERR-12-030, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hiệu lực ngay khi duyệt; tự hết hạn.
:::

#### API-12-039 · Từ chối quyền có thời hạn

::: dac-ta
**Mục đích.** Từ chối quyền có thời hạn.

**Phương thức, đường dẫn.** `POST /privileged-grants/{grantId}:reject`.

**Quyền.** `PERM-12-jit-approve`.

**FR hiện thực.** FR-12-017.

**Tham số.** `grantId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PrivilegedGrant`; trường bắt buộc: `grantId`, `type`, `targetTenant`, `roleCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-008, ERR-12-014, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-040 · Thu hồi quyền có thời hạn

::: dac-ta
**Mục đích.** Thu hồi quyền có thời hạn.

**Phương thức, đường dẫn.** `POST /privileged-grants/{grantId}:revoke`.

**Quyền.** `PERM-12-jit-approve` hoặc `PERM-12-user-lock` của tenant đích.

**FR hiện thực.** FR-12-017.

**Tham số.** `grantId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PrivilegedGrant`; trường bắt buộc: `grantId`, `type`, `targetTenant`, `roleCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thu hồi sớm; cắt phiên của người được cấp ở tenant đích.
:::

### Rà soát quyền

#### API-12-041 · Mở chiến dịch rà soát quyền

::: dac-ta
**Mục đích.** Mở chiến dịch rà soát quyền.

**Phương thức, đường dẫn.** `POST /recertification-campaigns`.

**Quyền.** `PERM-12-recert`.

**FR hiện thực.** FR-12-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CampaignCreate`; trường bắt buộc: `scopeType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Campaign`; trường bắt buộc: `campaignId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-031, ERR-12-043, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2.
:::

#### API-12-042 · Chi tiết chiến dịch rà soát

::: dac-ta
**Mục đích.** Chi tiết chiến dịch rà soát.

**Phương thức, đường dẫn.** `GET /recertification-campaigns/{campaignId}`.

**Quyền.** `PERM-12-recert`.

**FR hiện thực.** FR-12-018.

**Tham số.** `campaignId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Campaign`; trường bắt buộc: `campaignId`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-043 · Quyết định giữ hoặc gỡ một quyền

::: dac-ta
**Mục đích.** Quyết định giữ hoặc gỡ một quyền.

**Phương thức, đường dẫn.** `POST /recertification-campaigns/{campaignId}/items/{itemId}:decide`.

**Quyền.** Người rà soát được giao.

**FR hiện thực.** FR-12-018.

**Tham số.** `campaignId` (path, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CampaignItemDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CampaignItem`; trường bắt buộc: `itemId`, `userId`, `roleCode`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-031, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ người rà soát được giao (quản lý trực tiếp) gọi được.
:::

#### API-12-044 · Đóng chiến dịch rà soát

::: dac-ta
**Mục đích.** Đóng chiến dịch rà soát.

**Phương thức, đường dẫn.** `POST /recertification-campaigns/{campaignId}:close`.

**Quyền.** `PERM-12-recert`.

**FR hiện thực.** FR-12-018.

**Tham số.** `campaignId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Campaign`; trường bắt buộc: `campaignId`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-031, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mục chưa trả lời xử lý theo `onTimeout`.
:::

### Sáp nhập tenant

#### API-12-045 · Lập kế hoạch chuyển định danh khi sáp nhập

::: dac-ta
**Mục đích.** Lập kế hoạch chuyển định danh khi sáp nhập.

**Phương thức, đường dẫn.** `POST /tenant-merges/{mergeId}/identity:plan`.

**Quyền.** scope `iam:realm-provision`.

**FR hiện thực.** FR-12-019.

**Tham số.** `mergeId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergeId`, `targetTenant`, `usersToMove`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-040, ERR-12-041, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ tính toán, không đổi dữ liệu.
:::

#### API-12-046 · Thực hiện chuyển định danh khi sáp nhập

::: dac-ta
**Mục đích.** Thực hiện chuyển định danh khi sáp nhập.

**Phương thức, đường dẫn.** `POST /tenant-merges/{mergeId}/identity:execute`.

**Quyền.** scope `iam:realm-provision`.

**FR hiện thực.** FR-12-019.

**Tham số.** `mergeId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MergeExecute`; trường bắt buộc: `planHash`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-038, ERR-12-040, ERR-12-041, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lũy đẳng theo `Idempotency-Key` (khóa tìm lại tiến trình dở).
:::

### Liên kết định danh ngoài

#### API-12-047 · Danh sách liên kết LDAP, AD

::: dac-ta
**Mục đích.** Danh sách liên kết LDAP, AD.

**Phương thức, đường dẫn.** `GET /ldap-federations`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-026.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LdapFederationList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-048 · Khai báo liên kết LDAP, AD

::: dac-ta
**Mục đích.** Khai báo liên kết LDAP, AD.

**Phương thức, đường dẫn.** `PUT /ldap-federations/{federationCode}`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-026.

**Tham số.** `federationCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LdapFederationPut`; trường bắt buộc: `url`, `baseDn`, `bindDn`, `attributeMap`, `mode`, `passwordPolicyAck`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LdapFederation`; trường bắt buộc: `federationCode`, `url`, `mode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-032, ERR-12-039, ERR-12-043, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kích hoạt cần SO duyệt (`PERM-12-approve`). `bindSecret` ghi một chiều vào OpenBao.
:::

#### API-12-049 · Kiểm tra liên kết LDAP, AD

::: dac-ta
**Mục đích.** Kiểm tra liên kết LDAP, AD.

**Phương thức, đường dẫn.** `POST /ldap-federations/{federationCode}:test`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-026.

**Tham số.** `federationCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LdapTestResult`; trường bắt buộc: `status`, `steps`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-032, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết nối LDAPS, bind, tìm mẫu; không ghi dữ liệu.
:::

#### API-12-050 · Chạy đồng bộ LDAP, AD

::: dac-ta
**Mục đích.** Chạy đồng bộ LDAP, AD.

**Phương thức, đường dẫn.** `POST /ldap-federations/{federationCode}:sync`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-026.

**Tham số.** `federationCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`, `429`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-032, ERR-12-037, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-051 · Danh sách ứng dụng SAML

::: dac-ta
**Mục đích.** Danh sách ứng dụng SAML.

**Phương thức, đường dẫn.** `GET /saml-clients`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-025.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SamlClientList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-052 · Đăng ký ứng dụng SAML

::: dac-ta
**Mục đích.** Đăng ký ứng dụng SAML.

**Phương thức, đường dẫn.** `POST /saml-clients`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SamlClientCreate`; trường bắt buộc: `samlClientCode`, `entityId`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SamlClient`; trường bắt buộc: `samlClientCode`, `entityId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-033, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-053 · Sửa ứng dụng SAML

::: dac-ta
**Mục đích.** Sửa ứng dụng SAML.

**Phương thức, đường dẫn.** `PATCH /saml-clients/{samlClientCode}`.

**Quyền.** `PERM-12-admin`.

**FR hiện thực.** FR-12-025.

**Tham số.** `samlClientCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SamlClientUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SamlClient`; trường bắt buộc: `samlClientCode`, `entityId`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-033, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-054 · Xác nhận liên kết VNeID

::: dac-ta
**Mục đích.** Xác nhận liên kết VNeID.

**Phương thức, đường dẫn.** `POST /users/{userId}/vneid-link:confirm`.

**Quyền.** Chính chủ tài khoản.

**FR hiện thực.** FR-12-028.

**Tham số.** `userId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `VneidConfirm`; trường bắt buộc: `linkToken`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UserDetail`; trường bắt buộc: `userId`, `username`, `fullName`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-034, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ chính chủ tài khoản; số định danh đã liên kết tài khoản khác thì ERR-12-034.
:::

#### API-12-055 · Gỡ liên kết VNeID

::: dac-ta
**Mục đích.** Gỡ liên kết VNeID.

**Phương thức, đường dẫn.** `DELETE /users/{userId}/vneid-link`.

**Quyền.** Chính chủ tài khoản hoặc `PERM-12-user-admin`.

**FR hiện thực.** FR-12-028.

**Tham số.** `userId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-010, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chính chủ hoặc quản trị; không gỡ nếu là phương thức đăng nhập duy nhất.
:::

### Client của HTTT

#### API-12-056 · Danh sách client của HTTT

::: dac-ta
**Mục đích.** Danh sách client của HTTT.

**Phương thức, đường dẫn.** `GET /clients`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-030.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `state` (query, string, tùy chọn); `orgCode` (query, string, tùy chọn); `authMethod` (query, AuthMethod, tùy chọn); `contractLevel` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClientPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-057 · Chi tiết client

::: dac-ta
**Mục đích.** Chi tiết client.

**Phương thức, đường dẫn.** `GET /clients/{clientId}`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-030.

**Tham số.** `clientId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không trả bí mật; chỉ dấu vân tay chứng thư và hạn.
:::

#### API-12-058 · Cấp client cho HTTT thành viên

::: dac-ta
**Mục đích.** Cấp client cho HTTT thành viên.

**Phương thức, đường dẫn.** `POST /clients`.

**Quyền.** scope `iam:client-provision`.

**FR hiện thực.** FR-12-030.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ClientProvision`; trường bắt buộc: `systemCode`, `systemName`, `orgCode`, `contractLevel`, `authMethod`, `scopes`, `technicalContact`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-018, ERR-12-019, ERR-12-021, ERR-12-022, ERR-12-037, ERR-12-038, ERR-12-039, ERR-12-040, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Do PH-01 gọi (saga). Bí mật, nếu có, giao qua địa chỉ bọc dùng một lần `secretHandover`.
:::

#### API-12-059 · Sửa client

::: dac-ta
**Mục đích.** Sửa client.

**Phương thức, đường dẫn.** `PATCH /clients/{clientId}`.

**Quyền.** `PERM-12-client`.

**FR hiện thực.** FR-12-031.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ClientUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-020, ERR-12-022, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-060 · Tạm ngừng client

::: dac-ta
**Mục đích.** Tạm ngừng client.

**Phương thức, đường dẫn.** `POST /clients/{clientId}:suspend`.

**Quyền.** `PERM-12-user-lock` hoặc scope `iam:client-provision`.

**FR hiện thực.** FR-12-031.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-020, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Client bị từ chối cấp token ngay, ghi vào danh sách chặn.
:::

#### API-12-061 · Tiếp tục client

::: dac-ta
**Mục đích.** Tiếp tục client.

**Phương thức, đường dẫn.** `POST /clients/{clientId}:resume`.

**Quyền.** `PERM-12-user-lock` hoặc scope `iam:client-provision`.

**FR hiện thực.** FR-12-031.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-020, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-062 · Thu hồi client vĩnh viễn

::: dac-ta
**Mục đích.** Thu hồi client vĩnh viễn.

**Phương thức, đường dẫn.** `POST /clients/{clientId}:revoke`.

**Quyền.** `PERM-12-user-lock` hoặc scope `iam:client-provision`.

**FR hiện thực.** FR-12-031, FR-12-040.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `RevocationAccepted`; trường bắt buộc: `revocationId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-020, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thu hồi vĩnh viễn, mã client không dùng lại.
:::

#### API-12-063 · Cấp client cho ứng dụng nhà phát triển ở sandbox

::: dac-ta
**Mục đích.** Cấp client cho ứng dụng nhà phát triển ở sandbox.

**Phương thức, đường dẫn.** `POST /dev-clients`.

**Quyền.** scope `iam:dev-client`.

**FR hiện thực.** FR-12-032.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DevClientCreate`; trường bắt buộc: `appCode`, `appName`, `ownerUserId`, `authMethod`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-019, ERR-12-037, ERR-12-038, ERR-12-039, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ ở sandbox; hạn tối đa theo cấu hình PH-15.
:::

#### API-12-064 · Đăng ký chứng thư mTLS của client

::: dac-ta
**Mục đích.** Đăng ký chứng thư mTLS của client.

**Phương thức, đường dẫn.** `PUT /clients/{clientId}/credentials/certificate`.

**Quyền.** `PERM-12-client`.

**FR hiện thực.** FR-12-033.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CertificatePut`; trường bắt buộc: `certificatePem`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-020, ERR-12-021, ERR-12-022, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dấu vân tay mới phát qua EVT-12-08 cho PH-03.
:::

#### API-12-065 · Đăng ký khóa công khai (JWKS) của client

::: dac-ta
**Mục đích.** Đăng ký khóa công khai (JWKS) của client.

**Phương thức, đường dẫn.** `PUT /clients/{clientId}/credentials/jwks`.

**Quyền.** `PERM-12-client`.

**FR hiện thực.** FR-12-033.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `JwksPut`; trường bắt buộc: `keys`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Client`; trường bắt buộc: `clientId`, `systemCode`, `state`, `authMethod`, `contractLevel`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-020, ERR-12-021, ERR-12-022, ERR-12-038, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối khóa có thành phần riêng.
:::

#### API-12-066 · Xoay bí mật client

::: dac-ta
**Mục đích.** Xoay bí mật client.

**Phương thức, đường dẫn.** `POST /clients/{clientId}/credentials/secret:rotate`.

**Quyền.** `PERM-12-client`.

**FR hiện thực.** FR-12-034.

**Tham số.** `clientId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SecretRotateRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SecretRotateResult`; trường bắt buộc: `rotationId`, `status`, `secretHandover`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-020, ERR-12-022, ERR-12-023, ERR-12-037, ERR-12-039, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ client `CLIENT_SECRET` ở hợp đồng thấp; bí mật cũ giữ trong thời gian chuyển tiếp.
:::

#### API-12-067 · Scope hiện có của client

::: dac-ta
**Mục đích.** Scope hiện có của client.

**Phương thức, đường dẫn.** `GET /clients/{clientId}/scopes`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-036.

**Tham số.** `clientId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScopeList`; trường bắt buộc: `clientId`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-068 · Ghi đè scope của client theo nguồn đã duyệt

::: dac-ta
**Mục đích.** Ghi đè scope của client theo nguồn đã duyệt.

**Phương thức, đường dẫn.** `PUT /clients/{clientId}/scopes`.

**Quyền.** scope `iam:client-provision`.

**FR hiện thực.** FR-12-036.

**Tham số.** `clientId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ScopeReplace`; trường bắt buộc: `source`, `scopes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScopeList`; trường bắt buộc: `clientId`, `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-019, ERR-12-020, ERR-12-043, ERR-12-044, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ nhận scope có nguồn đã duyệt (PH-02, PH-09, PH-10, PH-19).
:::

### Tài khoản dịch vụ nội bộ

#### API-12-069 · Danh sách tài khoản dịch vụ nội bộ

::: dac-ta
**Mục đích.** Danh sách tài khoản dịch vụ nội bộ.

**Phương thức, đường dẫn.** `GET /service-accounts`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-037.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceAccountList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-070 · Tạo tài khoản dịch vụ nội bộ

::: dac-ta
**Mục đích.** Tạo tài khoản dịch vụ nội bộ.

**Phương thức, đường dẫn.** `POST /service-accounts`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-037.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceAccountCreate`; trường bắt buộc: `accountCode`, `du`, `authMethod`, `scopes`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-019, ERR-12-039, ERR-12-041, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp qua GitOps (`keycloak-config-cli`) sau duyệt.
:::

#### API-12-071 · Xoay thông tin xác thực của tài khoản dịch vụ

::: dac-ta
**Mục đích.** Xoay thông tin xác thực của tài khoản dịch vụ.

**Phương thức, đường dẫn.** `POST /service-accounts/{accountCode}/credentials:rotate`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-037.

**Tham số.** `accountCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-020, ERR-12-039, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

### Điểm cuối OIDC của Keycloak

#### API-12-072 · Tài liệu khám phá OIDC của realm

::: dac-ta
**Mục đích.** Tài liệu khám phá OIDC của realm.

**Phương thức, đường dẫn.** `GET /realms/dh-{tenant}/.well-known/openid-configuration`.

**Quyền.** Công khai.

**FR hiện thực.** FR-12-020.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OidcDiscovery`; trường bắt buộc: `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`.

**Lỗi.** Không.

**Ghi chú.** Chuẩn OpenID Connect Discovery 1.0; Keycloak trả.
:::

#### API-12-073 · Điểm cuối cấp quyền (Authorization Code + PKCE)

::: dac-ta
**Mục đích.** Điểm cuối cấp quyền (Authorization Code + PKCE).

**Phương thức, đường dẫn.** `GET /realms/dh-{tenant}/protocol/openid-connect/auth`.

**Quyền.** Công khai.

**FR hiện thực.** FR-12-020, FR-12-023, FR-12-027.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `302`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `403`; mã lỗi của thao tác: ERR-12-114, ERR-12-121, ERR-12-122 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ `response_type=code` với PKCE `S256`; thiếu PKCE là ERR-12-114. Người dùng đi qua BFF.
:::

#### API-12-074 · Điểm cuối token

::: dac-ta
**Mục đích.** Điểm cuối token.

**Phương thức, đường dẫn.** `POST /realms/dh-{tenant}/protocol/openid-connect/token`.

**Quyền.** Xác thực client (mTLS, private_key_jwt hoặc refresh token).

**FR hiện thực.** FR-12-020, FR-12-023, FR-12-027, FR-12-035, FR-12-038.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** application/x-www-form-urlencoded: `TokenRequest`; trường bắt buộc: `grant_type`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TokenResponse`; trường bắt buộc: `access_token`, `token_type`, `expires_in`.

**Lỗi.** HTTP `400`, `401`, `403`, `423`, `429`; mã lỗi của thao tác: ERR-12-111, ERR-12-112, ERR-12-113, ERR-12-114, ERR-12-115, ERR-12-117, ERR-12-118, ERR-12-119, ERR-12-120, ERR-12-121, ERR-12-122, ERR-12-125 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `grant_type` ∈ `authorization_code`, `client_credentials`, `refresh_token`; mọi grant khác bị cấm (ERR-12-122).
:::

#### API-12-075 · Công bố JWKS của realm

::: dac-ta
**Mục đích.** Công bố JWKS của realm.

**Phương thức, đường dẫn.** `GET /realms/dh-{tenant}/protocol/openid-connect/certs`.

**Quyền.** Công khai.

**FR hiện thực.** FR-12-039.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Jwks`; trường bắt buộc: `keys`.

**Lỗi.** Không.

**Ghi chú.** Khóa ký xoay 90 ngày, giữ khóa cũ trong thời gian chuyển tiếp.
:::

#### API-12-076 · Đăng xuất

::: dac-ta
**Mục đích.** Đăng xuất.

**Phương thức, đường dẫn.** `POST /realms/dh-{tenant}/protocol/openid-connect/logout`.

**Quyền.** Phiên đăng nhập (`id_token_hint`).

**FR hiện thực.** FR-12-020.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** application/x-www-form-urlencoded: `LogoutRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** RP-Initiated Logout.
:::

#### API-12-077 · Thu hồi token (RFC 7009)

::: dac-ta
**Mục đích.** Thu hồi token (RFC 7009).

**Phương thức, đường dẫn.** `POST /realms/dh-{tenant}/protocol/openid-connect/revoke`.

**Quyền.** Xác thực client (mTLS, private_key_jwt hoặc refresh token).

**FR hiện thực.** FR-12-040.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** application/x-www-form-urlencoded: `RevokeTokenRequest`; trường bắt buộc: `token`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-12-117 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** RFC 7009; luôn trả 200 với token hợp lệ hay không để không lộ thông tin.
:::

#### API-12-078 · Thông tin người dùng theo token

::: dac-ta
**Mục đích.** Thông tin người dùng theo token.

**Phương thức, đường dẫn.** `GET /realms/dh-{tenant}/protocol/openid-connect/userinfo`.

**Quyền.** Bearer token.

**FR hiện thực.** FR-12-020.

**Tham số.** `tenant` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Userinfo`; trường bắt buộc: `sub`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`; mã lỗi của thao tác: ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

### Realm của tenant

#### API-12-080 · Khởi tạo realm của tenant từ mẫu

::: dac-ta
**Mục đích.** Khởi tạo realm của tenant từ mẫu.

**Phương thức, đường dẫn.** `POST /realms`.

**Quyền.** scope `iam:realm-provision`.

**FR hiện thực.** FR-12-041.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RealmProvision`; trường bắt buộc: `tenantCode`, `displayName`, `emailDomains`, `adminEmail`, `adminFullName`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-038, ERR-12-039, ERR-12-040, ERR-12-041, ERR-12-043, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-20 gọi ở bước `S03_REALM` của saga; hoàn tất ≤ 5 phút. Lũy đẳng: gọi lại cùng khóa thì tiếp tục từ bước dở.
:::

#### API-12-081 · Trạng thái realm của tenant

::: dac-ta
**Mục đích.** Trạng thái realm của tenant.

**Phương thức, đường dẫn.** `GET /realms/{tenantCode}`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-042.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Realm`; trường bắt buộc: `tenantCode`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-082 · Đối chiếu cấu hình realm với mẫu

::: dac-ta
**Mục đích.** Đối chiếu cấu hình realm với mẫu.

**Phương thức, đường dẫn.** `GET /realms/{tenantCode}/drift`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-042.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RealmDrift`; trường bắt buộc: `tenantCode`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-041, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-083 · Áp lại cấu hình mẫu cho realm

::: dac-ta
**Mục đích.** Áp lại cấu hình mẫu cho realm.

**Phương thức, đường dẫn.** `POST /realms/{tenantCode}:reconcile`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-042.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-038, ERR-12-041, ERR-12-042, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp lại mẫu cấu hình; ghi đè thay đổi lệch.
:::

#### API-12-084 · Tạm ngừng realm

::: dac-ta
**Mục đích.** Tạm ngừng realm.

**Phương thức, đường dẫn.** `POST /realms/{tenantCode}:suspend`.

**Quyền.** scope `iam:realm-provision` hoặc `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-043.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Realm`; trường bắt buộc: `tenantCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-041, ERR-12-042, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ quản trị tỉnh đăng nhập chỉ-đọc; người dùng khác và mọi client bị từ chối.
:::

#### API-12-085 · Khôi phục realm

::: dac-ta
**Mục đích.** Khôi phục realm.

**Phương thức, đường dẫn.** `POST /realms/{tenantCode}:resume`.

**Quyền.** scope `iam:realm-provision` hoặc `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-043.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Realm`; trường bắt buộc: `tenantCode`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-041, ERR-12-042, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-113 · Danh sách realm của các tenant, lọc theo lệch cấu hình

::: dac-ta
**Mục đích.** Danh sách realm của các tenant, lọc theo lệch cấu hình.

**Phương thức, đường dẫn.** `GET /realms`.

**Quyền.** `PERM-12-realm-admin`.

**FR hiện thực.** FR-12-042.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `driftStatus` (query, string, tùy chọn); `state` (query, RealmState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RealmPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách realm cho màn hình Realm của tenant; lọc `driftStatus=DRIFTED` để xem các realm lệch cấu hình so với mẫu. Phân trang chuẩn.
:::

### Quyết định ủy quyền

#### API-12-086 · Quyết định ủy quyền một yêu cầu

::: dac-ta
**Mục đích.** Quyết định ủy quyền một yêu cầu.

**Phương thức, đường dẫn.** `POST /decide`.

**Quyền.** scope `iam:decide`.

**FR hiện thực.** FR-12-044, FR-12-045, FR-12-046, FR-12-047.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DecisionRequest`; trường bắt buộc: `traceId`, `tenant`, `subject`, `resource`, `action`, `permission`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DecisionResult`; trường bắt buộc: `allow`, `reason`.

**Lỗi.** HTTP `400`, `401`, `500`, `503`; mã lỗi của thao tác: ERR-12-101, ERR-12-102, ERR-12-103, ERR-12-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đường đầy đủ `/api/authz/v1/decide`. Mục tiêu p99 ≤ 10 ms ở OPA cục bộ; gọi qua API chỉ cho bên không có OPA cục bộ (Q12-26). Mọi lỗi → bên gọi xử lý như từ chối (BR-12-006).
:::

#### API-12-087 · Quyết định ủy quyền theo lô (tối đa 100)

::: dac-ta
**Mục đích.** Quyết định ủy quyền theo lô (tối đa 100).

**Phương thức, đường dẫn.** `POST /decide:batch`.

**Quyền.** scope `iam:decide`.

**FR hiện thực.** FR-12-049.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DecisionBatchRequest`; trường bắt buộc: `traceId`, `requests`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DecisionBatchResult`; trường bắt buộc: `results`.

**Lỗi.** HTTP `400`, `401`, `500`, `503`; mã lỗi của thao tác: ERR-12-101, ERR-12-102, ERR-12-103, ERR-12-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đường đầy đủ `/api/authz/v1/decide:batch`. Tối đa 100 yêu cầu; kết quả cùng thứ tự.
:::

#### API-12-088 · Quyết định theo XACML 3.0 JSON profile

::: dac-ta
**Mục đích.** Quyết định theo XACML 3.0 JSON profile.

**Phương thức, đường dẫn.** `POST /xacml`.

**Quyền.** scope `iam:decide`.

**FR hiện thực.** FR-12-048.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `XacmlRequest`; trường bắt buộc: `Request`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `XacmlResponse`; trường bắt buộc: `Response`.

**Lỗi.** HTTP `400`, `401`, `500`, `503`; mã lỗi của thao tác: ERR-12-102, ERR-12-103, ERR-12-104, ERR-12-123 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đường đầy đủ `/api/authz/v1/xacml`. Yêu cầu sai lược đồ trả `Indeterminate` kèm `Status`.
:::

### Chính sách và gói

#### API-12-089 · Danh sách chính sách

::: dac-ta
**Mục đích.** Danh sách chính sách.

**Phương thức, đường dẫn.** `GET /policies`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-052.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `scope` (query, PolicyScope, tùy chọn); `tag` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-090 · Chi tiết chính sách

::: dac-ta
**Mục đích.** Chi tiết chính sách.

**Phương thức, đường dẫn.** `GET /policies/{policyCode}`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-052.

**Tham số.** `policyCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Policy`; trường bắt buộc: `policyCode`, `scope`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-091 · Tạo chính sách kèm phiên bản đầu

::: dac-ta
**Mục đích.** Tạo chính sách kèm phiên bản đầu.

**Phương thức, đường dẫn.** `POST /policies`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-052.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyCreate`; trường bắt buộc: `policyCode`, `scope`, `description`, `content`, `tests`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-002, ERR-12-003, ERR-12-007, ERR-12-024, ERR-12-028, ERR-12-043, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối thiểu một ca dương và một ca âm. Chính sách tenant không được có luật cho phép hay nới quyền (ERR-12-028).
:::

#### API-12-092 · Tạo phiên bản nháp mới

::: dac-ta
**Mục đích.** Tạo phiên bản nháp mới.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-052.

**Tham số.** `policyCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyVersionCreate`; trường bắt buộc: `content`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-024, ERR-12-027, ERR-12-028, ERR-12-043, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa nội dung làm mất hiệu lực kết quả kiểm thử và chạy khô đã có.
:::

#### API-12-093 · Chi tiết một phiên bản chính sách

::: dac-ta
**Mục đích.** Chi tiết một phiên bản chính sách.

**Phương thức, đường dẫn.** `GET /policies/{policyCode}/versions/{versionNo}`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-052.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-094 · Chạy bộ ca kiểm thử

::: dac-ta
**Mục đích.** Chạy bộ ca kiểm thử.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:test`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-052.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestRun`; trường bắt buộc: `runId`, `passed`, `failed`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-024, ERR-12-025, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy trong `policy-runner` cô lập, không gọi mạng.
:::

#### API-12-095 · Chạy khô trên lưu lượng thật

::: dac-ta
**Mục đích.** Chạy khô trên lưu lượng thật.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:dry-run`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-053.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DryRunRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `DryRunReport`; trường bắt buộc: `reportId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-024, ERR-12-027, ERR-12-037, ERR-12-040, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát lại lưu lượng mẫu ở cửa sổ `12.policy.dryrun.window-hours`; chạy nền, theo dõi bằng `Location`.
:::

#### API-12-096 · Gửi duyệt phiên bản chính sách

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản chính sách.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:submit`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-054.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionComment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-025, ERR-12-026, ERR-12-027, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần kiểm thử đạt và chạy khô trên đúng băm nội dung hiện tại.
:::

#### API-12-097 · Duyệt và phát hành phiên bản chính sách

::: dac-ta
**Mục đích.** Duyệt và phát hành phiên bản chính sách.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:approve`.

**Quyền.** `PERM-12-policy-approve`.

**FR hiện thực.** FR-12-054.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyApprove`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `503`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-008, ERR-12-027, ERR-12-029, ERR-12-040, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bốn mắt: khác người soạn, người đóng góp, người gửi. Yêu cầu xác thực mức 3 (`acr`=3).
:::

#### API-12-098 · Từ chối phiên bản chính sách

::: dac-ta
**Mục đích.** Từ chối phiên bản chính sách.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:reject`.

**Quyền.** `PERM-12-policy-approve`.

**FR hiện thực.** FR-12-054.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-008, ERR-12-014, ERR-12-027, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-099 · Thu hồi phiên bản đang chạy

::: dac-ta
**Mục đích.** Thu hồi phiên bản đang chạy.

**Phương thức, đường dẫn.** `POST /policies/{policyCode}/versions/{versionNo}:revoke`.

**Quyền.** `PERM-12-policy-approve`.

**FR hiện thực.** FR-12-055.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `BundleRelease`; trường bắt buộc: `revision`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-027, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không thu hồi được chính sách gốc (ERR-12-027).
:::

#### API-12-100 · Quay lui về gói chính sách đã từng chạy

::: dac-ta
**Mục đích.** Quay lui về gói chính sách đã từng chạy.

**Phương thức, đường dẫn.** `POST /policy-bundles:rollback`.

**Quyền.** `PERM-12-policy-approve`.

**FR hiện thực.** FR-12-055.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BundleRollback`; trường bắt buộc: `targetRevision`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `BundleRelease`; trường bắt buộc: `revision`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-027, ERR-12-045, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quay lui về gói đã từng chạy; ký lại và phát hành.
:::

#### API-12-101 · Danh sách gói chính sách đã phát hành

::: dac-ta
**Mục đích.** Danh sách gói chính sách đã phát hành.

**Phương thức, đường dẫn.** `GET /policy-bundles`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-051, FR-12-054, FR-12-055.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `scope` (query, PolicyScope, tùy chọn); `state` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BundleReleasePage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm số nút OPA đã xác nhận nạp.
:::

#### API-12-102 · Sinh lại dữ liệu vai trò–quyền cho OPA

::: dac-ta
**Mục đích.** Sinh lại dữ liệu vai trò–quyền cho OPA.

**Phương thức, đường dẫn.** `POST /policy-data:regenerate`.

**Quyền.** `PERM-12-policy-edit` hoặc hệ thống.

**FR hiện thực.** FR-12-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyDataRegenerate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Accepted`; trường bắt buộc: `taskId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `503`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-024, ERR-12-040, ERR-12-045, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sinh lại `data.dh.roles`, `assignments`… từ ma trận D02-08 và gán vai trò hiện tại.
:::

#### API-12-112 · Ghi đè nội dung bản nháp của phiên bản chính sách (tự lưu)

::: dac-ta
**Mục đích.** Ghi đè nội dung bản nháp của phiên bản chính sách (tự lưu).

**Phương thức, đường dẫn.** `PUT /policies/{policyCode}/versions/{versionNo}`.

**Quyền.** `PERM-12-policy-edit`.

**FR hiện thực.** FR-12-052.

**Tham số.** `policyCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyVersionCreate`; trường bắt buộc: `content`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyVersion`; trường bắt buộc: `policyCode`, `versionNo`, `state`, `contentHash`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-024, ERR-12-027, ERR-12-028, ERR-12-043, ERR-12-044, ERR-12-116, ERR-12-120 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tự lưu bản nháp: chỉ phiên bản `DRAFT` của chính người soạn, kèm `If-Match`; phiên bản đã gửi duyệt hoặc đã phát hành trả ERR-12-027. Mỗi lần ghi đè xóa kết quả kiểm thử và chạy khô đã có (gắn với `contentHash` cũ).
:::

### Nhật ký, cảnh báo, báo cáo

#### API-12-103 · Tra nhật ký quyết định ủy quyền

::: dac-ta
**Mục đích.** Tra nhật ký quyết định ủy quyền.

**Phương thức, đường dẫn.** `GET /decisions`.

**Quyền.** `PERM-12-decision-read`.

**FR hiện thực.** FR-12-057, FR-12-058.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `subjectId` (query, string, tùy chọn); `allow` (query, boolean, tùy chọn); `reason` (query, DecisionReason, tùy chọn); `permission` (query, string, tùy chọn); `resourceId` (query, string, tùy chọn); `classification` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DecisionPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyết định từ chối và mức Hạn chế, Nhạy cảm ghi 100%; mức Công khai, Nội bộ lấy mẫu theo `12.decision.sample-ratio`.
:::

#### API-12-104 · Chi tiết một quyết định ủy quyền

::: dac-ta
**Mục đích.** Chi tiết một quyết định ủy quyền.

**Phương thức, đường dẫn.** `GET /decisions/{decisionId}`.

**Quyền.** `PERM-12-decision-read`.

**FR hiện thực.** FR-12-058.

**Tham số.** `decisionId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DecisionLogEntry`; trường bắt buộc: `decisionId`, `time`, `allow`, `reason`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi lượt xem dữ liệu đã che được ghi vết sang PH-13 (FR-12-057); phản hồi liệt kê `maskedFields`.
:::

#### API-12-105 · Tra sự kiện xác thực và quản trị định danh

::: dac-ta
**Mục đích.** Tra sự kiện xác thực và quản trị định danh.

**Phương thức, đường dẫn.** `GET /security-events`.

**Quyền.** `PERM-12-decision-read`.

**FR hiện thực.** FR-12-056.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `type` (query, string, tùy chọn); `userId` (query, string, tùy chọn); `clientId` (query, string, tùy chọn); `result` (query, string, tùy chọn); `errorCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityEventPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sự kiện xác thực và quản trị định danh (EVT-12-16 và kiểm toán).
:::

#### API-12-106 · Danh sách cảnh báo an ninh

::: dac-ta
**Mục đích.** Danh sách cảnh báo an ninh.

**Phương thức, đường dẫn.** `GET /alerts`.

**Quyền.** `PERM-12-alert`.

**FR hiện thực.** FR-12-059.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `severity` (query, string, tùy chọn); `state` (query, string, tùy chọn); `ruleCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-107 · Xác nhận cảnh báo

::: dac-ta
**Mục đích.** Xác nhận cảnh báo.

**Phương thức, đường dẫn.** `POST /alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-12-alert`.

**FR hiện thực.** FR-12-059.

**Tham số.** `alertId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertAck`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`; trường bắt buộc: `alertId`, `ruleCode`, `severity`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-12-001, ERR-12-003, ERR-12-007, ERR-12-014, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-108 · Báo cáo tình trạng tài khoản

::: dac-ta
**Mục đích.** Báo cáo tình trạng tài khoản.

**Phương thức, đường dẫn.** `GET /reports/accounts`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-060.

**Tham số.** `date` (query, string, tùy chọn); `orgCode` (query, string, tùy chọn); `days` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccountReport`; trường bắt buộc: `date`, `total`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-12-109 · Báo cáo phủ xác thực hai yếu tố

::: dac-ta
**Mục đích.** Báo cáo phủ xác thực hai yếu tố.

**Phương thức, đường dẫn.** `GET /reports/mfa-coverage`.

**Quyền.** `PERM-12-read`.

**FR hiện thực.** FR-12-060.

**Tham số.** `date` (query, string, tùy chọn); `orgCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MfaCoverageReport`; trường bắt buộc: `date`, `coverage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-12-003, ERR-12-007, ERR-12-116 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

<!-- gen:dac-ta-api:end -->

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây ở tài liệu dùng chung hoặc phân hệ khác do luồng khác chịu trách nhiệm; tập này chỉ ghi lại để đợt đồng bộ cuối xử lý.

| Tài liệu | Đề nghị |
|---|---|
| D00-04 §2, §3.2 | PH-12 "đủ tập api 0.1"; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để cập nhật dải API-12 (001…113), EVT-12 (01…16), ERR-12 |
| D02-03-PH12 (FRS) §9.4 | Tách phần ghi chú trong ngoặc khỏi cột đường dẫn: API-12-030 `POST /sod-exceptions/{exceptionId}:decide`; API-12-072…078 bỏ "(Keycloak)" khỏi đường dẫn và ghi vào cột quyền; ghi `X-DH-Applied-Version` và `X-DH-Node` ở API-12-079; ghi ERR-12-120 dùng cho xác thực bước lên của API quản trị, không chỉ của Keycloak |
| D02-03-PH12 (FRS) §9.1 | ERR-12-035 có hai mã HTTP (`400` sai định dạng, `413` quá lớn): ghi cả hai ở cột HTTP; OpenAPI của API-12-010 khai báo cả hai phản hồi |
| D02-03-PH12 (FRS) §4.5, §4.6 | Bổ sung bảng mức xác thực tối thiểu theo operation (Q12-59); OpenAPI dùng đúng các trạng thái của §4.3…4.7 (kể cả `CANCELLED`, `CHANGES_REQUESTED`, `DISCARDED`) |
| D02-08 | Ghi bảy scope máy `iam:*` (FRS §3.3) và nêu rõ chúng không phải `PERM`; 14 quyền `PERM-12-*` còn thiếu theo FRS |
| D03-02-PH12 (SDD) §3.3, §8.2 | Giao diện `RevocationQueryApi` trả `RevocationFeed` có `blockAll`; sự kiện: 15 qua outbox và EVT-12-16 do Keycloak phát; điểm cuối nội bộ trạng thái OPA (Q12-56) |
| D03-06-PH12 (màn hình) | Dùng `allowedActions`, `disabledReasons` của OpenAPI để bật, tắt nút; thông báo ERR-12-120 (xác thực lại), ERR-12-037 (quá tần suất) theo bảng 6.3 |
| PH-03 | Plugin `dh-authz` kéo API-12-079 mỗi 10 giây kèm `X-DH-Applied-Version`, xử lý `blockAll`; dùng bộ fixture quyết định chung (chương 7); bí danh `decide/batch` nếu Q12-55 chọn giữ |
| PH-01, PH-15, PH-20 | PH-01: API-12-058, 060, 061, 062, 068 và nhận địa chỉ bọc; PH-15: API-12-063; PH-20: API-12-080 (chờ 4 phút), 084, 085, 045, 046 kèm scope tương ứng ở chương 2.3 |
| PH-13 | Hợp đồng tiếp nhận EVT-12-01…16 và nhật ký quyết định theo đường log |
| D04-02 (CI-5) | Thêm `gen_md.py` và `check_contracts.py` của `ph12/tools` vào bước kiểm hợp đồng; bộ luật Spectral cho khóa `x-datahub-acr`, `x-datahub-errors` |
| ADR | Không đề xuất ADR mới ở tập này; bốn ADR (a)…(d) của FRS và ba ADR (e)…(g) của SDD vẫn chờ tạo ở dải 014–019 |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-API và K-TRINH-BAY |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: đồng bộ PH-01, PH-03, PH-20 (S03_REALM), tiêu đề X-DH-Grant-Id, facets, remainingSeconds, maskedFields; chốt câu hỏi mở đợt đồng bộ: Q413, Q445, Q446, Q412 |
