---
ma_tai_lieu: D03-04-PH02
ten: Đặc tả API và sự kiện phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, giao diện; kỹ sư PH-03, PH-04, PH-15; ATTT; kiểm thử viên; hội đồng thẩm định
phan_he: PH-02
mo_ta: Đặc tả 98 endpoint REST, 16 sự kiện Kafka và 45 mã lỗi của phân hệ Danh mục dịch vụ, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH02 FRS; D02-04-PH02 Use case; D03-02-PH02 SDD; D03-03-PH02 CSDL; D03-06-PH02 Màn hình; D05-02-PH02 Test case; D04-01 Quy ước mã
---

# D03-04-PH02 · Đặc tả API và sự kiện Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-02 là nơi giữ hợp đồng giữa bên cung cấp và bên khai thác dữ liệu trên Datahub. Tài liệu này đặc tả giao diện lập trình của phân hệ: 98 operation REST dưới `/api/catalog/v1` (91 operation theo bản FRS đầu cộng bảy operation bổ sung API-02-092…098, đã ghi vào FRS §9.4 ở lượt rà soát, xem mục 3.4) và 16 sự kiện Kafka `EVT-02-01…16`. Hợp đồng máy đọc được gồm hai tệp:

- [`ph02/openapi-catalog.yaml`](ph02/openapi-catalog.yaml): OpenAPI 3.1, 141 lược đồ, đã qua `openapi-spec-validator`; 26 ví dụ đã kiểm khớp lược đồ bằng [`check_contracts.py`](ph02/tools/check_contracts.py).
- [`ph02/asyncapi-catalog.yaml`](ph02/asyncapi-catalog.yaml): AsyncAPI 3.0, 22 kênh (16 phát, 6 nhận), đã qua `@asyncapi/parser` 3 không lỗi.

Cả hai sinh từ bảng mã [`ph02/tools/spec.py`](ph02/tools/spec.py) và [`schemas.py`](ph02/tools/schemas.py) bằng `gen_openapi.py`, `gen_asyncapi.py`; bảng ở chương 3, 4, 6 sinh bằng `gen_md.py`; chương 10 sinh từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`. Nhờ vậy ba nơi không lệch nhau.

**Phạm vi.** API chia mười bốn nhóm: danh mục và tra cứu; phân loại, thẻ, dịch vụ sự kiện; đăng ký API và nạp đặc tả; kiểm tra đặc tả và bộ luật; backend, đường dẫn, khung route; gói sử dụng; vòng đời, duyệt, phiên bản; đăng ký sử dụng; đồng bộ quốc gia; SLA, thông báo, thống kê; giao diện nội bộ cho PH-03, PH-04, PH-15; đối soát cấu hình; di trú từ APIM cũ; tham số. Thêm một nhóm tác vụ bất đồng bộ dùng chung. Phủ đủ 62 FR-02 (bảng truy vết ở §3.3), trừ khi FR chỉ có giao diện.

**Căn cứ pháp lý.** Giao diện này hiện thực nghĩa vụ công bố, công khai, đăng ký danh mục dịch vụ chia sẻ dữ liệu (CMP-LAW-03, CMP-LAW-19: NĐ 278/2025), phân loại và chia sẻ dữ liệu (CMP-LAW-01, CMP-LAW-02), chức năng quản lý dịch vụ của LGSP (CMP-LAW-09), xác thực máy–máy và nhật ký (CMP-LAW-06, CMP-LAW-08), khai báo mục đích khai thác dữ liệu cá nhân (CMP-LAW-05).

**Những điểm hội đồng cần lưu ý.**

1. **Không đường tắt vào gateway.** Chỉ có một đường đưa API ra gateway: đặc tả đạt ba lớp kiểm tra → gửi duyệt (API-02-042) → người thứ hai duyệt (API-02-045) → công bố có xác nhận từ cổng (API-02-047, API-02-082). Không operation nào công bố bằng một lệnh của một người; bốn mắt kiểm ở máy chủ.
2. **Không operation nào trả khóa, bí mật hay giá trị cá nhân thật.** Phát hiện lớp `SECRET` chỉ trả `maskedTail` (bốn ký tự cuối đã che); kiểm tra hợp đồng chặn lược đồ có trường `password`, `secret`, `privateKey`, `clientSecret`, `apiKey`.
3. **Quyền truy cập của HTTT khai thác không cấp bằng tay.** Phạm vi `api:{apiCode}:{planCode}` chỉ sinh từ đăng ký đã duyệt (API-02-045, API-02-048); API chỉ nhận yêu cầu, không có operation "gán quyền".
4. **Ngừng dùng không bao giờ tự động khi còn bên dùng.** API-02-050, API-02-051 chỉ tạo đề nghị; còn đăng ký hiệu lực thì ERR-02-030 (409).
5. **Giao diện nội bộ tách khỏi quyền người dùng.** PH-03, PH-04, PH-15, PH-13, PH-16 gọi `/internal/*` và API đọc bằng token dịch vụ với phạm vi riêng (`catalog:gateway-read`, `catalog:gateway-ack`, `catalog:portal-read`, `catalog:flow-sync`, `catalog:metrics-read`), không dùng `PERM-02-*`.
6. **Sự cố PH-02 không làm gián đoạn API đang chạy.** Cấu hình đã nằm ở gateway; PH-02 chỉ phát dữ liệu công bố qua API-02-080 và nhận xác nhận qua API-02-082 (NFR-02-008).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation REST | 98 (API-02-001…098; 001…091 theo bản FRS đầu, 092…098 bổ sung ở mục 3.4) |
| Phương thức | GET 38, POST 41, PUT 7, PATCH 5, DELETE 4 |
| Operation có `Idempotency-Key` | 33 (mọi lệnh tạo, gửi duyệt, duyệt, công bố và đổi trạng thái; trừ lệnh kiểm tra, xem trước, tải lên và ba lệnh xử lý phát hiện) |
| Operation có `If-Match` | 36 (mọi PUT, PATCH, DELETE và lệnh đổi trạng thái trên đối tượng đã có) |
| Sự kiện | 16 phát (EVT-02-01…16), 6 nhận (EVT-04-02, 04, 07; EVT-10-01, 03, 04) |
| Mã lỗi | 45 (ERR-02-001…045), toàn bộ ở dải 001–099 (control plane) |
| Lược đồ OpenAPI | 141 |
| Câu hỏi mở | 5 (Q02-55…59) |

: Con số chính của tập API PH-02

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả giao diện lập trình của PH-02: các endpoint REST ở mặt phẳng điều khiển và nội bộ, các sự kiện Kafka, hợp đồng với phân hệ khác và bên ngoài, bảng mã lỗi ERR-02. Nguồn chuẩn là hai tệp máy đọc được [`openapi-catalog.yaml`](ph02/openapi-catalog.yaml) và [`asyncapi-catalog.yaml`](ph02/asyncapi-catalog.yaml); bảng danh mục ở chương 3 và đặc tả từng endpoint ở chương 10 (mỗi endpoint một bảng 10 mục) đều sinh từ OpenAPI.

Ngoài phạm vi: lời gọi lúc chạy qua gateway (lỗi, giới hạn tần suất, xác thực lúc chạy) thuộc PH-03; kết nối giao thức tới Nền tảng quốc gia thuộc PH-14; trình bày cho nhà phát triển thuộc PH-15; cấu hình tham số `02.*` lưu ở PH-18.

### 0.2. Người đọc

Bảng dưới nêu từng nhóm người đọc cần đọc phần nào của tập API.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect`, giao diện | Chương 1, 2, 3, 10 |
| Kỹ sư PH-03, PH-04, PH-15 | Chương 3.2, 4, 5, API-02-007, 017, 080, 081, 082 ở chương 10 |
| Kiểm thử viên | Chương 6, 7, 10 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ nghiệp vụ dùng chung với [D02-03-PH02](../../02-yeu-cau/frs/D02-03-PH02-frs-danh-muc-dich-vu.md) §1.4 và D00-01. Các từ riêng của tài liệu này:

| Từ | Nghĩa |
|---|---|
| Operation | Một cặp phương thức và đường dẫn, mang một mã `API-02-nnn` |
| Hành động | Hậu tố `:{động-từ}` trên tài nguyên cho thao tác không thuộc CRUD (AIP-136), ví dụ `:submit`, `:approve` |
| `ETag` | Số phiên bản đối tượng (cột `version`), dùng cho `If-Match` |
| Yêu cầu duyệt | Việc chờ người có quyền xử lý (`review_request`), tám loại `ReviewKind` |
| Tác vụ bất đồng bộ | Việc chạy nền có `operationId`, tra bằng API-02-095 |
| `configEpoch` | Số phiên bản nguồn cấu hình tăng dần của tenant; PH-03 và người nhận sự kiện dùng để lũy đẳng |
| Gateway | APISIX do PH-03 vận hành (ADR-005) |

: Thuật ngữ riêng của tập API

### 0.4. Tài liệu tham chiếu

D02-03-PH02 (FRS: FR, ERR, EVT, danh mục API đã chốt ở §9), D02-04-PH02 (use case), D03-02-PH02 (SDD: thành phần, cổng ra, ánh xạ lỗi §8.6), D03-03-PH02 (CSDL: schema `ph02_catalog`), D03-06-PH02 (màn hình), D02-08 (quyền PERM-02), D03-07 (SEC), D04-01 (quy ước API, RFC 9457), ADR-005, 013, 041, 042, 046, 057, 070.

### 0.5. Cấu trúc tài liệu

Chương 1 quy ước chung; 2 xác thực và phân quyền; 3 danh mục endpoint, ví dụ, sơ đồ trình tự và truy vết FR; 4 sự kiện; 5 hợp đồng với phân hệ khác; 6 mã lỗi; 7 kiểm tra hợp đồng trong CI; 8 ánh xạ từ hệ cũ; 9 câu hỏi mở; 10 đặc tả từng endpoint (sinh tự động); cuối cùng là Đề nghị đồng bộ và lịch sử phiên bản.

## 1. Quy ước chung

Chương này gom các quy ước áp cho mọi operation để các chương sau không lặp lại. Quy ước kế thừa D04-01 và cùng cách làm với PH-04, PH-05, PH-19, nên giao diện và công cụ phía máy khách dùng chung được.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/catalog/v1`; người dùng qua BFF console của tenant; PH-03, PH-04, PH-15 qua dịch vụ trong cụm `dh-connect.dh-control.svc`; API nội bộ dưới `/api/catalog/v1/internal` |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng (NFR-00-055); oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1`; trong `v1` chỉ thêm trường tùy chọn (NFR-02-018) |
| Tenant | Lấy từ claim `tenant` của token, không bao giờ từ đường dẫn hay thân; đối tượng tenant khác trả ERR-02-001 (404, cùng thân với "không tồn tại") |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:submit`, `:approve`, `:publish`, `:suspend`); hành động trên tập: `plans:copy-from`, `context-paths:check` |
| Khóa lạc quan | `GET` trả `ETag`; `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái bắt buộc `If-Match`; lệch trả ERR-02-015 (412) |
| Chống trùng | `POST` tạo và lệnh đổi trạng thái bắt buộc `Idempotency-Key` (16…128 ký tự, giữ 24 giờ theo `(tenant, người gọi, khóa)`); cùng khóa cùng thân trả lại phản hồi cũ, cùng khóa khác thân trả ERR-02-042 (422) |
| Phân trang | `page` (từ 1), `size` (mặc định 20, tối đa 100, quá thì ERR-02-003); phản hồi `items`, `page`, `size`, `totalElements`; danh mục cho máy hỗ trợ thêm `updatedSince` và `removed[]` |
| Sắp xếp, lọc | `sort=trường:asc\|desc`; lọc theo tham số lặp phân tách dấu phẩy (`status=PUBLISHED,DEPRECATED`); tìm `q` không dấu |
| Lỗi | RFC 9457 `application/problem+json`; `code = ERR-02-nnn`, `traceId` (32 ký tự hex); thêm `errors[]` (theo trường), `missing[]` (ERR-02-012), `findings[]` (ERR-02-006, 007, 008), `usages[]` (ERR-02-024, 030), `retryAfterSeconds` |
| Hành động được phép | Đối tượng trả `allowedActions[]` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm (FR-00-053) |
| Truy vết | `traceparent` W3C xuyên BFF → `dh-connect` → PH-03, Kafka |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail`, `hint` |
| Tác vụ dài | API-02-016, 032, 069, 084 trả 202 kèm `operationId` và tiêu đề `Location` trỏ API-02-095; kết quả giữ 7 ngày |
| Thời gian | `date-time` UTC (`2026-11-26T03:15:00Z`); giao diện đổi sang giờ Việt Nam |
| Mã nghiệp vụ | `apiCode` `^[a-z][a-z0-9-]{2,62}$`, `versionNo` `MAJOR.MINOR.PATCH`, `planCode` `^[a-z][a-z0-9-]{1,31}$`, mã HTTT và đơn vị theo T-CODE; mã đã dùng không dùng lại kể cả sau khi xóa (ERR-02-002) |

: Quy ước chung

Giới hạn tần suất ở biên (giả định, cơ sở: tải nền của tỉnh vừa 200 người dùng, GĐ-04, NFR-02-001):

| Bên gọi | Giới hạn | Khi vượt |
|---|---|---|
| Người dùng console, đọc | 600 yêu cầu mỗi phút mỗi người | 429 `Retry-After`, ERR-02-036 |
| Người dùng console, ghi | 120 yêu cầu mỗi phút mỗi người | như trên |
| API-02-022 (kiểm tra không lưu) | 60 lần mỗi giờ mỗi người (tham số `02.lint.max-per-hour`) | ERR-02-036 kèm `retryAfterSeconds` |
| API-02-015 nguồn `URL` | 20 lần mỗi giờ mỗi người | ERR-02-036 |
| API-02-076 (thông báo tay) | 3 thông báo mỗi API mỗi ngày (`02.notice.announcement-max-per-day`) | ERR-02-036 |
| HTTT khai thác, `GET /catalog/apis` | 60 yêu cầu mỗi phút mỗi client (bộ đệm `max-age=300` làm giảm tải) | 429 |
| PH-03, PH-15 | 120 yêu cầu mỗi phút mỗi client | 429 |

: Giới hạn tần suất

## 2. Xác thực và phân quyền

PH-02 có ba loại bên gọi: người dùng console (người của đơn vị chủ quản, người duyệt, vận hành, ATTT), hệ thống thành viên khai thác danh mục, và các phân hệ khác của Datahub. Mỗi loại dùng một luồng OAuth riêng; quyền được kiểm ở máy chủ cho từng operation, không chỉ ở giao diện.

| Bên gọi | Luồng OAuth | Kiểm quyền |
|---|---|---|
| Người dùng console | OIDC Authorization Code + PKCE qua BFF (token không ra trình duyệt) | `PERM-02-*` (D02-08) theo vai trò PA, TA, TO, SO, IE, SV, CA, OR, VW, AU; đối tượng của tổ chức mình kiểm theo `ownerOrgCode` (ký hiệu ○ ở FRS §3.2); bốn mắt kiểm ở máy chủ |
| HTTT khai thác | `client_credentials` + `private_key_jwt` hoặc mTLS, phạm vi `catalog:read` | API-02-004, 005, 007 (đọc danh mục và tải đặc tả trong phạm vi mức hiển thị) |
| PH-03 (cổng API) | `client_credentials` + mTLS mesh; `catalog:gateway-read`, `catalog:gateway-ack` | API-02-080, 082 |
| PH-15 (cổng nhà phát triển) | `client_credentials` + mTLS mesh; `catalog:portal-read` | API-02-081 |
| PH-04 (lõi tích hợp) | Gọi trong tiến trình khi cùng DU, khi tách DU dùng `client_credentials` + mTLS, `catalog:flow-sync` | API-02-017, 007 |
| PH-13, PH-16 | `client_credentials`, `catalog:metrics-read` | API-02-079, API-02-097 |

: Xác thực và phân quyền theo bên gọi

Bảng quyền theo operation nằm ở cột "Quyền" của §3. Các quy tắc vượt quyền chức năng:

- **Bốn mắt.** Người gửi duyệt, người sửa gần nhất đặc tả hoặc gói, và người duyệt là ba người khác nhau với API, gói, đăng ký từ mức `RESTRICTED` (BR-02-008, BR-02-026; ADR-046). Vi phạm trả ERR-02-013 (403). API `SENSITIVE` cần hai quyết định duyệt khác người (`requiredApprovals = 2`).
- **Tách vai trò.** SV và CA là cặp loại trừ (D02-08 §4): chủ dịch vụ không tự duyệt công bố.
- **Phạm vi theo tổ chức.** SV (○) và OR (○) chỉ thao tác trên API hoặc HTTT của tổ chức mình; ngoài phạm vi trả ERR-02-001 hoặc ERR-02-014 tùy việc người gọi có được xem đối tượng hay không (BR-02-039).
- **Tạm ngừng khẩn.** SO có `PERM-02-operate` chỉ để tạm ngừng API (API-02-048) và đăng ký (API-02-061) khi có sự cố, kèm `securityHold`; không dùng cho công bố hay sửa nội dung. Chỉ SO được tiếp tục khi do SO ngừng với `securityHold` (BR-02-034).
- **Phạm vi truy cập của HTTT khai thác.** `api:{apiCode}:{planCode}` do PH-02 yêu cầu PH-12 gắn khi đăng ký chuyển `ACTIVE` và gỡ khi rời `ACTIVE`; dữ liệu từ `RESTRICTED` bắt buộc `OAUTH2_PKJWT` hoặc `OAUTH2_MTLS` (ERR-02-022).
- **Quyền quản trị phân hệ.** Các operation tham số, bộ phân loại, bộ luật, chuyển chủ quản, di trú dùng quyền quản trị phân hệ (động từ `admin` của họ quyền PH-02), quyền đề nghị bổ sung vào D02-08 (FRS §3.2); cho tới khi D02-08 cập nhật, máy chủ ánh xạ tạm sang vai trò PA, TA.
- **Lớp dữ liệu.** Dữ liệu thuộc bí mật nhà nước không được công bố (ERR-02-016); đặc tả không bao giờ bị ghi vào log hay sự kiện (NFR-02-012).

## 3. Danh mục endpoint

Chương này liệt kê toàn bộ operation của PH-02, ví dụ các lời gọi quan trọng, hai luồng điển hình giữa nhiều operation và bảng truy vết từ FR sang API. Mỗi operation một mã `API-02-nnn`, không dùng chung mã cho hai operation. Cột FR là số FR-02; đường dẫn tính từ `/api/catalog/v1`; chi tiết tham số, lược đồ và mô tả lỗi theo từng operation ở OpenAPI và chương 10. Operation thuộc Đợt 2 ghi "(Đợt 2)" ở cột Nội dung.

<!-- gen:endpoints:start -->
**Danh mục và tra cứu**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-001 | `GET /apis` | Danh sách API trong danh mục | 001 | `PERM-02-read` |  | 200 |
| API-02-002 | `GET /apis/{apiCode}` | Chi tiết một API | 002 | `PERM-02-read` |  | 200 |
| API-02-003 | `GET /search/apis` | Tìm kiếm toàn văn danh mục | 003 | `PERM-02-read` |  | 200 |
| API-02-004 | `GET /catalog/apis` | Danh mục cho HTTT khai thác và cổng nhà phát triển | 004 | `PERM-02-read`; hoặc token máy `catalog:read` |  | 200/304 |
| API-02-005 | `GET /catalog/apis/{apiCode}` | Một API trong danh mục cho HTTT khai thác | 004 | `PERM-02-read`; hoặc token máy `catalog:read` |  | 200/304 |
| API-02-006 | `GET /apis/{apiCode}/versions/{versionNo}/usage-guide` | Đường dẫn sử dụng và mẫu gọi API | 005 | `PERM-02-read` |  | 200 |
| API-02-007 | `GET /apis/{apiCode}/versions/{versionNo}/spec` | Tải đặc tả OpenAPI đã công bố | 006, 059 | `PERM-02-read`; hoặc token máy `catalog:read, catalog:flow-sync` |  | 200 |
| API-02-090 | `GET /apis/{apiCode}/versions` | Danh sách phiên bản của API | 002 | `PERM-02-read` |  | 200 |
| API-02-091 | `GET /apis/{apiCode}/history` | Lịch sử thay đổi và vòng đời của API | 002 | `PERM-02-read` |  | 200 |

: Danh mục endpoint · Danh mục và tra cứu

**Phân loại, thẻ, dịch vụ sự kiện**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-008 | `PUT /apis/{apiCode}/classification` | Đặt phân loại, thẻ và mức phân loại dữ liệu của API | 007 | `PERM-02-create` |  | 200 |
| API-02-009 | `GET /categories` | Cây phân loại và thẻ | 008 | `PERM-02-read` |  | 200 |
| API-02-010 | `POST /categories` | Thêm nhóm phân loại | 008 | Quyền quản trị phân hệ (đề nghị, động từ admin) | có | 201 |
| API-02-011 | `PATCH /categories/{categoryCode}` | Sửa, đổi tên, di chuyển nhóm phân loại | 008 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |
| API-02-012 | `DELETE /categories/{categoryCode}` | Xóa nhóm, chuyển API sang nhóm đích | 008 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 204/200 |
| API-02-013 | `GET /event-services` | Dịch vụ sự kiện (topic PH-10) trong danh mục (Đợt 2) | 009 | `PERM-02-read` |  | 200 |

: Danh mục endpoint · Phân loại, thẻ, dịch vụ sự kiện

**Đăng ký API và nạp đặc tả**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-014 | `POST /apis` | Đăng ký API mới (kèm phiên bản đầu `DRAFT`) | 010 | `PERM-02-create` | có | 201 |
| API-02-015 | `POST /spec-uploads` | Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL | 011 | `PERM-02-create` |  | 200 |
| API-02-016 | `POST /apis/{apiCode}/versions/{versionNo}/spec:resync` | Đồng bộ lại đặc tả từ URL nguồn | 012 | `PERM-02-create` | có | 202 |
| API-02-018 | `PATCH /apis/{apiCode}` | Sửa thông tin API, context-path và thay đặc tả khi còn bản nháp | 014, 024 | `PERM-02-create` |  | 200 |
| API-02-019 | `GET /spec-templates/openapi` | Tải mẫu đặc tả OpenAPI theo quy ước nền tảng | 015 | `PERM-02-read` |  | 200 |

: Danh mục endpoint · Đăng ký API và nạp đặc tả

**Kiểm tra đặc tả và bộ luật**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-020 | `GET /apis/{apiCode}/versions/{versionNo}/lint-results` | Kết quả kiểm tra đặc tả của phiên bản | 016, 017, 018 | `PERM-02-read` |  | 200 |
| API-02-021 | `POST /apis/{apiCode}/versions/{versionNo}/lint-runs` | Chạy lại kiểm tra đặc tả (có lưu kết quả) | 016, 017, 018 | `PERM-02-create` |  | 200 |
| API-02-022 | `POST /spec-lint` | Kiểm tra đặc tả không lưu (xem trước khi gõ) | 019 | `PERM-02-create` |  | 200 |
| API-02-023 | `GET /apis/{apiCode}/versions/{versionNo}/duplicates` | Phát hiện API trùng chức năng | 020 | `PERM-02-read` |  | 200 |
| API-02-024 | `GET /lint-rules` | Bộ luật kiểm tra hiệu lực của tenant | 021 | `PERM-02-read` |  | 200 |
| API-02-025 | `PUT /lint-rules` | Điều chỉnh mức hoặc bật tắt luật quy ước của tenant | 021 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |
| API-02-092 | `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:acknowledge` | Chấp nhận cảnh báo quy ước kèm lý do | 017 | `PERM-02-create` |  | 200 |
| API-02-093 | `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:dispute-secret` | Đề nghị đánh dấu không phải bí mật | 018 | `PERM-02-create` |  | 200 |
| API-02-094 | `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:confirm-dispute` | Cán bộ ATTT xác nhận hoặc bác đề nghị không phải bí mật | 018 | `PERM-02-operate` |  | 200 |

: Danh mục endpoint · Kiểm tra đặc tả và bộ luật

**Backend, đường dẫn, khung route**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-026 | `GET /apis/{apiCode}/versions/{versionNo}/backends` | Danh sách backend của phiên bản | 022 | `PERM-02-read` |  | 200 |
| API-02-027 | `POST /apis/{apiCode}/versions/{versionNo}/backends` | Khai báo backend | 022 | `PERM-02-create` | có | 201/202 |
| API-02-028 | `PATCH /apis/{apiCode}/versions/{versionNo}/backends/{backendCode}` | Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe | 023 | `PERM-02-create` |  | 200/202 |
| API-02-029 | `DELETE /apis/{apiCode}/versions/{versionNo}/backends/{backendCode}` | Xóa backend | 022 | `PERM-02-create` |  | 204/202 |
| API-02-030 | `GET /context-paths:check` | Kiểm tra context-path có trùng hoặc xung đột | 024 | `PERM-02-read` |  | 200 |
| API-02-031 | `GET /apis/{apiCode}/versions/{versionNo}/backends/health` | Sức khỏe backend | 025 | `PERM-02-read` |  | 200 |
| API-02-032 | `POST /apis/{apiCode}/versions/{versionNo}/flow-skeleton` | Sinh khung route cho PH-04 từ đặc tả | 026 | `PERM-02-create` | có | 202 |

: Danh mục endpoint · Backend, đường dẫn, khung route

**Gói sử dụng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-033 | `GET /apis/{apiCode}/versions/{versionNo}/plans` | Danh sách gói của phiên bản | 027 | `PERM-02-read` |  | 200 |
| API-02-034 | `POST /apis/{apiCode}/versions/{versionNo}/plans` | Tạo gói sử dụng | 027 | `PERM-02-create` | có | 201 |
| API-02-035 | `PATCH /apis/{apiCode}/versions/{versionNo}/plans/{planCode}` | Sửa thông tin và điều kiện truy cập của gói | 027 | `PERM-02-create` |  | 200 |
| API-02-036 | `PUT /apis/{apiCode}/versions/{versionNo}/plans/{planCode}/access-policy` | Kiểu xác thực, hạn mức và đường dẫn cho phép của gói | 028, 029 | `PERM-02-create` |  | 200 |
| API-02-037 | `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit` | Gửi duyệt công bố gói | 030 | `PERM-02-submit` | có | 202 |
| API-02-038 | `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit-deprecate` | Đề nghị ngừng khuyến nghị gói | 031 | `PERM-02-submit` | có | 202 |
| API-02-039 | `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit-close` | Đề nghị đóng gói | 032 | `PERM-02-submit` | có | 202 |
| API-02-040 | `POST /apis/{apiCode}/versions/{versionNo}/plans:copy-from` | Sao chép gói từ phiên bản trước sang phiên bản này | 033 | `PERM-02-create` | có | 201 |
| API-02-096 | `GET /plans` | Danh sách gói sử dụng toàn tenant | 027, 031 | `PERM-02-read` |  | 200 |
| API-02-041 | `DELETE /apis/{apiCode}/versions/{versionNo}/plans/{planCode}` | Hủy gói nháp (xóa mềm) | 032 | `PERM-02-create` |  | 204 |

: Danh mục endpoint · Gói sử dụng

**Vòng đời, duyệt, phiên bản**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-042 | `POST /apis/{apiCode}/versions/{versionNo}:submit` | Gửi duyệt công bố phiên bản | 034 | `PERM-02-submit` | có | 202 |
| API-02-043 | `POST /apis/{apiCode}/versions/{versionNo}:withdraw` | Rút lại yêu cầu duyệt | 034 | `PERM-02-submit` | có | 200 |
| API-02-044 | `GET /review-requests` | Danh sách yêu cầu duyệt (Việc của tôi) | 030, 031, 035, 038, 039, 047 | `PERM-02-read` |  | 200 |
| API-02-098 | `GET /review-requests/{reviewRequestId}` | Chi tiết một yêu cầu duyệt kèm điều kiện và lịch sử | 035, 047 | `PERM-02-read` |  | 200 |
| API-02-045 | `POST /review-requests/{reviewRequestId}:approve` | Duyệt yêu cầu (công bố, gói, ngừng dùng, đăng ký) | 030, 035, 047 | `PERM-02-publish` hoặc `PERM-02-approve-subscription` | có | 200 |
| API-02-046 | `POST /review-requests/{reviewRequestId}:reject` | Từ chối yêu cầu duyệt | 035, 047 | `PERM-02-publish` hoặc `PERM-02-approve-subscription` | có | 200 |
| API-02-047 | `POST /apis/{apiCode}/versions/{versionNo}:publish` | Công bố phiên bản ra gateway và danh mục | 036 | `PERM-02-create` hoặc `PERM-02-operate` | có | 200/202 |
| API-02-048 | `POST /apis/{apiCode}/versions/{versionNo}:suspend` | Tạm ngừng phiên bản | 037 | `PERM-02-operate` | có | 200 |
| API-02-049 | `POST /apis/{apiCode}/versions/{versionNo}:resume` | Tiếp tục phiên bản | 037 | `PERM-02-operate` | có | 200 |
| API-02-050 | `POST /apis/{apiCode}/versions/{versionNo}:propose-deprecate` | Đề nghị ngừng khuyến nghị có lộ trình | 038 | `PERM-02-submit` | có | 202 |
| API-02-051 | `POST /apis/{apiCode}/versions/{versionNo}:propose-retire` | Đề nghị ngừng hẳn hoặc hủy bản nháp | 039 | `PERM-02-submit` hoặc `PERM-02-create` | có | 202/200 |
| API-02-052 | `DELETE /apis/{apiCode}` | Xóa API (xóa mềm) | 040 | `PERM-02-create` |  | 204 |
| API-02-053 | `PUT /apis/{apiCode}/visibility` | Đặt mức hiển thị, công bố hoặc gỡ khỏi cổng nhà phát triển | 041 | `PERM-02-create` hoặc `PERM-02-submit` |  | 200/202 |
| API-02-054 | `POST /apis/{apiCode}/versions` | Tạo phiên bản mới | 042 | `PERM-02-create` | có | 201 |
| API-02-055 | `GET /apis/{apiCode}/version-diff` | So sánh hai phiên bản và phân loại thay đổi phá vỡ | 043 | `PERM-02-read` |  | 200 |
| API-02-056 | `GET /apis/{apiCode}/versions/{versionNo}/impact` | Phân tích tác động tới bên khai thác | 044 | `PERM-02-read` |  | 200 |
| API-02-057 | `PUT /apis/{apiCode}/owner` | Chuyển chủ quản API | 045 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |

: Danh mục endpoint · Vòng đời, duyệt, phiên bản

**Đăng ký sử dụng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-058 | `POST /subscriptions` | Gửi đăng ký sử dụng API cho HTTT | 046 | `PERM-02-subscribe` | có | 201 |
| API-02-059 | `GET /subscriptions` | Danh sách đăng ký sử dụng theo API hoặc theo HTTT | 049, 050 | `PERM-02-read` |  | 200 |
| API-02-060 | `GET /subscriber-systems` | HTTT mà người gọi được đăng ký hoặc xem | 049, 050 | `PERM-02-read` |  | 200 |
| API-02-061 | `POST /subscriptions/{subscriptionId}:suspend` | Tạm ngừng đăng ký | 051 | `PERM-02-operate` | có | 200 |
| API-02-062 | `POST /subscriptions/{subscriptionId}:resume` | Tiếp tục đăng ký | 051 | `PERM-02-operate` | có | 200 |
| API-02-063 | `POST /subscriptions/{subscriptionId}:revoke` | Thu hồi đăng ký | 051 | `PERM-02-approve-subscription` | có | 200 |
| API-02-064 | `POST /subscriptions/{subscriptionId}:cancel` | Hủy đăng ký | 051 | `PERM-02-subscribe` | có | 200 |
| API-02-065 | `POST /subscriptions/{subscriptionId}:renew` | Gia hạn đăng ký (Đợt 2) | 052 | `PERM-02-subscribe` | có | 200/202 |
| API-02-066 | `POST /subscriptions/{subscriptionId}:confirm-review` | Xác nhận rà soát định kỳ đăng ký (Đợt 2) | 052 | `PERM-02-approve-subscription` | có | 200 |
| API-02-067 | `GET /subscriptions/{subscriptionId}/grant` | Trạng thái cấp phạm vi của đăng ký | 048 | `PERM-02-read` |  | 200 |
| API-02-068 | `POST /subscriptions/{subscriptionId}:regrant` | Cấp lại phạm vi | 048 | `PERM-02-operate` | có | 202 |

: Danh mục endpoint · Đăng ký sử dụng

**Đồng bộ quốc gia**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-069 | `POST /national-sync/runs` | Đồng bộ danh mục lên Nền tảng quốc gia ngay | 053 | `PERM-02-operate` | có | 202 |
| API-02-070 | `GET /national-sync/summary` | Thẻ tổng trạng thái đồng bộ quốc gia | 054 | `PERM-02-read` |  | 200 |
| API-02-071 | `POST /national-sync/records/{syncId}:resend` | Gửi lại một bản ghi đồng bộ | 053, 054 | `PERM-02-operate` | có | 202 |
| API-02-072 | `GET /national-sync/records` | Danh sách bản ghi đồng bộ quốc gia | 054 | `PERM-02-read` |  | 200 |

: Danh mục endpoint · Đồng bộ quốc gia

**SLA, thông báo, thống kê**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-073 | `PUT /apis/{apiCode}/versions/{versionNo}/sla` | Khai báo cam kết chất lượng dịch vụ (SLA) | 055 | `PERM-02-create` |  | 200 |
| API-02-074 | `GET /apis/{apiCode}/versions/{versionNo}/sla` | Cam kết SLA hiện hành và đang chờ hiệu lực | 055, 056 | `PERM-02-read` |  | 200 |
| API-02-075 | `GET /apis/{apiCode}/versions/{versionNo}/sla/periods` | Đối chiếu SLA thực tế theo kỳ | 056 | `PERM-02-read` |  | 200 |
| API-02-097 | `GET /sla/summary` | Tổng hợp tuân thủ SLA toàn tenant | 056 | `PERM-02-read`; hoặc token máy `catalog:metrics-read` |  | 200 |
| API-02-076 | `POST /apis/{apiCode}/change-notices` | Gửi thông báo thay đổi cho bên khai thác | 057 | `PERM-02-create` | có | 202 |
| API-02-077 | `GET /change-notices` | Lịch sử thông báo thay đổi và bên nhận | 057 | `PERM-02-read` |  | 200 |
| API-02-078 | `GET /apis/{apiCode}/versions/{versionNo}/usage-stats` | Thống kê sử dụng theo phiên bản (Đợt 2) | 058 | `PERM-02-read` |  | 200 |
| API-02-079 | `GET /usage-stats/summary` | Thống kê cấp tenant (Đợt 2) | 058 | `PERM-02-read`; hoặc token máy `catalog:metrics-read` |  | 200 |

: Danh mục endpoint · SLA, thông báo, thống kê

**Nội bộ cho PH-03, PH-04, PH-15**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-017 | `PUT /internal/flow-apis/{flowCode}` | PH-04 tự đăng ký hoặc cập nhật API từ luồng REST | 013 | Token dịch vụ `catalog:flow-sync` |  | 200 |
| API-02-080 | `GET /internal/gateway/published-config` | Dữ liệu công bố cho PH-03 | 059 | Token dịch vụ `catalog:gateway-read` |  | 200/304 |
| API-02-081 | `GET /internal/portal/catalog` | Danh mục cho PH-15 | 004, 059 | Token dịch vụ `catalog:portal-read` |  | 200/304 |
| API-02-082 | `POST /internal/gateway/apply-acks` | PH-03 xác nhận đã nạp cấu hình | 036, 059 | Token dịch vụ `catalog:gateway-ack` |  | 204 |

: Danh mục endpoint · Nội bộ cho PH-03, PH-04, PH-15

**Đối soát cấu hình**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-083 | `GET /gateway-reconciliations/latest` | Kết quả đối soát cấu hình công bố với gateway gần nhất (Đợt 2) | 060 | `PERM-02-operate` |  | 200 |
| API-02-084 | `POST /gateway-reconciliations` | Chạy đối soát tay và đẩy lại cấu hình lệch (Đợt 2) | 060 | `PERM-02-operate` | có | 202 |

: Danh mục endpoint · Đối soát cấu hình

**Di trú từ APIM cũ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-085 | `POST /legacy-imports` | Phân tích gói APIM cũ và xem trước | 061 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |
| API-02-086 | `POST /legacy-imports/{importId}:commit` | Xác nhận nhập API, gói, đăng ký từ APIM cũ | 061 | Quyền quản trị phân hệ (đề nghị, động từ admin) | có | 201 |
| API-02-087 | `GET /legacy-imports/{importId}/report` | Báo cáo đối chiếu sau nhập | 061 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |

: Danh mục endpoint · Di trú từ APIM cũ

**Tham số**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-088 | `GET /settings` | Tham số `02.*` của tenant | 062 | `PERM-02-read` |  | 200 |
| API-02-089 | `PATCH /settings` | Sửa tham số `02.*` (ghi qua PH-18) | 062 | Quyền quản trị phân hệ (đề nghị, động từ admin) |  | 200 |

: Danh mục endpoint · Tham số

**Tác vụ bất đồng bộ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-02-095 | `GET /operations/{operationId}` | Tiến độ và kết quả tác vụ bất đồng bộ | 012, 026, 053, 060 | `PERM-02-read` |  | 200 |

: Danh mục endpoint · Tác vụ bất đồng bộ
<!-- gen:endpoints:end -->

### 3.1. Ví dụ yêu cầu và phản hồi

Các ví dụ dưới đây dùng tenant T68 (Lâm Đồng, giả lập), tên miền `.example.vn`, dữ liệu giả. Mỗi ví dụ yêu cầu của API có thân đều đã được kiểm khớp lược đồ trong `check_contracts.py`.

**API-02-015 · Nạp đặc tả bằng cách dán nội dung** (bước 2 của trình hướng dẫn UI-02-03). Yêu cầu:

```http
POST /api/catalog/v1/spec-uploads
Content-Type: application/json
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{ "source": "PASTE", "content": "openapi: 3.1.0\ninfo: { title: Tra cứu hộ tịch, version: 1.0.0 }\npaths: {}" }
```

Phản hồi `200`: đặc tả đã phân tích, gộp tham chiếu, lưu vào kho đối tượng và chạy ba lớp kiểm tra.

```json
{ "specId": "0192d3a1-6f10-7a00-8a11-0a1b2c3d4e5f", "sha256": "9f2c…e41b", "sizeBytes": 18342, "openapiVersion": "3.1.0", "operationCount": 7,
  "converted": false, "lintSummary": { "errors": 0, "warnings": 2, "infos": 1 }, "expiresAt": "2026-11-27T03:15:00Z" }
```

Khi đặc tả có giá trị giống khóa, phản hồi `422` (ERR-02-008) chỉ nêu vị trí và đuôi đã che, không nêu giá trị:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-02-008", "title": "Đặc tả chứa bí mật hoặc dữ liệu cá nhân thật", "status": 422, "code": "ERR-02-008",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "findings": [{ "ruleId": "SCAN-02-03", "severity": "ERROR", "location": "#/components/examples/token/value", "message": "Giá trị giống token truy cập, đuôi ****a91f" }] }
```

**API-02-014 · Đăng ký API mới.** Yêu cầu (`Idempotency-Key` bắt buộc), phản hồi `201` kèm `Location: /api/catalog/v1/apis/tra-cuu-ho-tich` và `ETag: "1"`:

```json
{ "apiCode": "tra-cuu-ho-tich", "name": "Tra cứu thông tin hộ tịch", "providerSystemCode": "HT-HOTICH", "ownerOrgCode": "SO-TUPHAP",
  "dataClass": "RESTRICTED", "visibility": "TENANT", "categoryCode": "ho-tich", "tags": ["khai-sinh", "tra-cuu"],
  "contextPath": "/ho-tich/tra-cuu-ho-tich/v1", "specId": "0192d3a1-6f10-7a00-8a11-0a1b2c3d4e5f" }
```

```json
{ "apiCode": "tra-cuu-ho-tich", "name": "Tra cứu thông tin hộ tịch", "dataClass": "RESTRICTED", "visibility": "TENANT", "origin": "OPENAPI",
  "latestVersionNo": "1.0.0", "latestVersionStatus": "DRAFT", "activeSubscriptions": 0, "attention": false,
  "selectedVersion": { "versionNo": "1.0.0", "major": 1, "status": "DRAFT", "apiCode": "tra-cuu-ho-tich", "contextPath": "/ho-tich/tra-cuu-ho-tich/v1",
    "lintSummary": { "errors": 0, "warnings": 2, "infos": 1 }, "allowedActions": ["edit", "test-deploy", "submit", "retire-draft"] } }
```

**API-02-036 · Kiểu xác thực, hạn mức, đường dẫn cho phép của gói.** Yêu cầu `PUT` kèm `If-Match`; dữ liệu `RESTRICTED` bắt buộc xác thực mạnh:

```json
{ "authType": "OAUTH2_PKJWT", "quota": { "perSecond": 20, "dailyCalls": 50000 },
  "operationScopes": [{ "operationId": "getBirthCertificate", "scope": "api:tra-cuu-ho-tich:co-ban" }] }
```

Chọn `API_KEY` cho dữ liệu `RESTRICTED` trả `422` (ERR-02-022):

```json
{ "type": "https://datahub.gov.vn/errors/ERR-02-022", "title": "Kiểu xác thực không phù hợp mức phân loại dữ liệu", "status": 422, "code": "ERR-02-022",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "errors": [{ "path": "/authType", "rule": "MIN_AUTH_FOR_DATA_CLASS", "message": "Dữ liệu mức RESTRICTED yêu cầu OAUTH2_PKJWT hoặc OAUTH2_MTLS." }] }
```

**API-02-042 · Gửi duyệt công bố phiên bản.** Yêu cầu có `Idempotency-Key` và `If-Match`; phản hồi `202`:

```json
{ "reviewRequestId": "0192d3a1-8a10-7b22-8c4d-2e3f4a5b6c7d", "kind": "VERSION_PUBLISH", "status": "PENDING" }
```

Chưa đủ điều kiện (thiếu gói, backend, hoặc chưa thử TEST) trả `409` (ERR-02-012) kèm danh sách điều kiện còn thiếu:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-02-012", "title": "Chưa đủ điều kiện để chuyển trạng thái", "status": 409, "code": "ERR-02-012",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "missing": ["NO_ACTIVE_BACKEND", "NO_PLAN", "TEST_DEPLOY_REQUIRED"] }
```

**API-02-045 · Duyệt đăng ký sử dụng kèm điều kiện.** Yêu cầu với `If-Match` là `etag` của yêu cầu duyệt trong danh sách API-02-044:

```json
{ "comment": "Đúng mục đích, giảm hạn mức theo thực tế.", "conditions": { "approvedDailyCalls": 2000, "expiresAt": "2027-11-26T00:00:00Z" } }
```

Người gửi hoặc người sửa gần nhất tự duyệt bị `403` (ERR-02-013):

```json
{ "type": "https://datahub.gov.vn/errors/ERR-02-013", "title": "Vi phạm nguyên tắc bốn mắt", "status": 403, "code": "ERR-02-013",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "detail": "Người duyệt trùng vai trò người sửa gần nhất." }
```

**API-02-047 · Công bố lên môi trường thật.** Yêu cầu `{ "environment": "PROD", "reviewRequestId": "0192d3a1-8a10-7b22-8c4d-2e3f4a5b6c7d" }`. Gateway xác nhận kịp trong 30 giây thì `200`; chưa kịp thì `202` và phiên bản giữ trạng thái cũ cho tới khi API-02-082 báo xong:

```json
{ "status": "PUBLISHED", "gatewayState": "SYNCED", "publishedAt": "2026-11-26T03:15:21Z", "gatewayConfigVersion": 4182,
  "publishedUrl": "https://api.t68.example.vn/ho-tich/tra-cuu-ho-tich/v1" }
```

**API-02-050 · Đề nghị ngừng khuyến nghị.** Hạn chuyển đổi ngắn hơn `02.deprecation.min-days` (180 ngày) trả `422` (ERR-02-031) kèm hạn tối thiểu:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-02-031", "title": "Hạn chuyển đổi ngắn hơn tối thiểu", "status": 422, "code": "ERR-02-031",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "errors": [{ "path": "/sunsetAt", "rule": "MIN_DAYS", "message": "Hạn chuyển đổi tối thiểu 180 ngày. Chọn ngày muộn hơn 25/05/2027." }] }
```

**API-02-055 · So sánh hai phiên bản** (`GET /apis/ho-so-dat-dai/version-diff?from=1.2.0&to=2.0.0`), phản hồi `200`:

```json
{ "from": "1.2.0", "to": "2.0.0", "breaking": true, "versionViolation": false, "suggestedVersion": "2.0.0", "uncertainCount": 1,
  "changes": [{ "class": "BREAKING", "kind": "RESPONSE_FIELD_REMOVED", "location": "#/paths/~1thua-dat~1{id}/get/responses/200", "description": "Bỏ trường `soTo`.", "impact": "3 bên đăng ký gọi thao tác này" }] }
```

**API-02-058 · Gửi đăng ký sử dụng.** Gói có `autoApprove = false` hoặc dữ liệu từ `RESTRICTED` thì `201` với `status = PENDING`; gói tự duyệt và dữ liệu thấp thì `ACTIVE` ngay. Phản hồi:

```json
{ "subscriptionId": "0192d3a1-a000-7d33-9e44-4f5a6b7c8d9e", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "systemCode": "HT-MOTCUA",
  "status": "PENDING", "grantStatus": "PENDING", "reviewRequestId": "0192d3a1-a001-7d33-9e44-4f5a6b7c8d9f", "expectedVolume": { "dailyCalls": 3000 } }
```

**API-02-080 · Dữ liệu công bố cho PH-03** (`GET /internal/gateway/published-config?environment=PROD&sinceConfigVersion=4100`, `Accept: application/x-ndjson`). Mỗi dòng một đối tượng; dòng đầu là đầu bản:

```json
{"environment":"PROD","configVersion":4182,"sourceVersion":9317,"gap":false,"configHash":"d1…77"}
{"apiCode":"tra-cuu-ho-tich","versionNo":"1.0.0","status":"PUBLISHED","contextPath":"/ho-tich/tra-cuu-ho-tich/v1","backends":[{"backendCode":"ho-tich-a","kind":"SYSTEM","weight":100,"status":"ACTIVE"}],"plans":[{"planCode":"co-ban","status":"PUBLISHED","authType":"OAUTH2_PKJWT"}],"operations":[{"operationId":"getBirthCertificate","method":"GET","path":"/giay-khai-sinh/{soDinhDanh}"}]}
{"subscriptionId":"0192d3a1-a000-7d33-9e44-4f5a6b7c8d9e","systemCode":"HT-MOTCUA","clientId":"dh-sub-ht-motcua","apiCode":"tra-cuu-ho-tich","planCode":"co-ban","scopes":["api:tra-cuu-ho-tich:co-ban"]}
```

**API-02-082 · PH-03 xác nhận đã nạp.** Yêu cầu (phản hồi `204`):

```json
{ "environment": "PROD", "configVersion": 4182, "sourceVersion": 9317, "configHash": "d1…77", "result": "APPLIED" }
```

### 3.2. Luồng điển hình giữa các operation

Hai sơ đồ dưới đây cho thấy thứ tự gọi các operation ở hai luồng quan trọng nhất: đưa một API ra gateway và cho một HTTT được khai thác. Cả hai đều có người thứ hai duyệt và đều chờ xác nhận từ gateway trước khi ghi trạng thái cuối.

```{.mermaid caption="Gửi duyệt, duyệt bốn mắt và công bố phiên bản"}
sequenceDiagram
  participant SV as Chủ dịch vụ
  participant C as dh-connect
  participant CA as Người duyệt
  participant G as PH-03 cổng API
  SV->>C: POST versions/1.0.0:submit
  C-->>SV: 202 reviewRequestId, phiên bản PENDING
  CA->>C: GET review-requests
  CA->>C: POST review-requests/id:approve
  C->>C: Kiểm bốn mắt và băm đặc tả
  C-->>CA: 200 duyệt ghi nhận
  G->>C: GET internal/gateway/published-config
  C-->>G: 200 ndjson dữ liệu công bố
  G->>G: Sinh ảnh chụp, đẩy xuống APISIX
  G->>C: POST internal/gateway/apply-acks APPLIED
  C-->>G: 204
  C->>C: Phiên bản PUBLISHED, phát EVT-02-05
```

Thuyết minh: ở bước duyệt, hệ thống chưa đổi sang `PUBLISHED`. Phiên bản chỉ sang `PUBLISHED` sau khi PH-03 xác nhận đã nạp (API-02-082); không có xác nhận trong 30 giây thì `POST :publish` trả `202`, tác vụ nền thử lại tối đa 5 lần trong 15 phút và người vận hành có thể thử lại bằng API-02-047.

```{.mermaid caption="Đăng ký sử dụng, duyệt và cấp phạm vi"}
sequenceDiagram
  participant OR as Đầu mối tổ chức
  participant C as dh-connect
  participant SV as Chủ dịch vụ hoặc người duyệt
  participant IAM as PH-12
  participant G as PH-03 cổng API
  OR->>C: POST subscriptions
  C-->>OR: 201 PENDING, reviewRequestId
  SV->>C: POST review-requests/id:approve kèm conditions
  C->>IAM: Gắn phạm vi api:apiCode:planCode cho client
  IAM-->>C: Đã gắn
  C->>C: Đăng ký ACTIVE, grantStatus GRANTED, phát EVT-02-10
  G->>C: GET internal/gateway/published-config
  C-->>G: consumer và phạm vi mới
  OR->>C: GET subscriptions/id/grant
  C-->>OR: 200 GRANTED
```

Thuyết minh: PH-02 không cấp quyền trực tiếp mà yêu cầu PH-12 gắn phạm vi lũy đẳng; khi PH-12 lỗi, đăng ký vẫn `ACTIVE` nhưng `grantStatus = FAILED` hoặc `AWAITING_CREDENTIAL` và người vận hành chạy lại bằng API-02-068.

### 3.3. Truy vết FR → API

Bảng sinh từ trường FR của từng operation trong OpenAPI; FR không có API chỉ có giao diện hoặc chạy nền.

<!-- gen:fr-api:start -->
| FR | API |
|---|---|
| FR-02-001 | API-02-001 |
| FR-02-002 | API-02-002, API-02-090, API-02-091 |
| FR-02-003 | API-02-003 |
| FR-02-004 | API-02-004, API-02-005, API-02-081 |
| FR-02-005 | API-02-006 |
| FR-02-006 | API-02-007 |
| FR-02-007 | API-02-008 |
| FR-02-008 | API-02-009, API-02-010, API-02-011, API-02-012 |
| FR-02-009 | API-02-013 |
| FR-02-010 | API-02-014 |
| FR-02-011 | API-02-015 |
| FR-02-012 | API-02-016, API-02-095 |
| FR-02-013 | API-02-017 |
| FR-02-014 | API-02-018 |
| FR-02-015 | API-02-019 |
| FR-02-016 | API-02-020, API-02-021 |
| FR-02-017 | API-02-020, API-02-021, API-02-092 |
| FR-02-018 | API-02-020, API-02-021, API-02-093, API-02-094 |
| FR-02-019 | API-02-022 |
| FR-02-020 | API-02-023 |
| FR-02-021 | API-02-024, API-02-025 |
| FR-02-022 | API-02-026, API-02-027, API-02-029 |
| FR-02-023 | API-02-028 |
| FR-02-024 | API-02-018, API-02-030 |
| FR-02-025 | API-02-031 |
| FR-02-026 | API-02-032, API-02-095 |
| FR-02-027 | API-02-033, API-02-034, API-02-035, API-02-096 |
| FR-02-028 | API-02-036 |
| FR-02-029 | API-02-036 |
| FR-02-030 | API-02-037, API-02-044, API-02-045 |
| FR-02-031 | API-02-038, API-02-044, API-02-096 |
| FR-02-032 | API-02-039, API-02-041 |
| FR-02-033 | API-02-040 |
| FR-02-034 | API-02-042, API-02-043 |
| FR-02-035 | API-02-044, API-02-045, API-02-046, API-02-098 |
| FR-02-036 | API-02-047, API-02-082 |
| FR-02-037 | API-02-048, API-02-049 |
| FR-02-038 | API-02-044, API-02-050 |
| FR-02-039 | API-02-044, API-02-051 |
| FR-02-040 | API-02-052 |
| FR-02-041 | API-02-053 |
| FR-02-042 | API-02-054 |
| FR-02-043 | API-02-055 |
| FR-02-044 | API-02-056 |
| FR-02-045 | API-02-057 |
| FR-02-046 | API-02-058 |
| FR-02-047 | API-02-044, API-02-045, API-02-046, API-02-098 |
| FR-02-048 | API-02-067, API-02-068 |
| FR-02-049 | API-02-059, API-02-060 |
| FR-02-050 | API-02-059, API-02-060 |
| FR-02-051 | API-02-061, API-02-062, API-02-063, API-02-064 |
| FR-02-052 | API-02-065, API-02-066 |
| FR-02-053 | API-02-069, API-02-071, API-02-095 |
| FR-02-054 | API-02-070, API-02-071, API-02-072 |
| FR-02-055 | API-02-073, API-02-074 |
| FR-02-056 | API-02-074, API-02-075, API-02-097 |
| FR-02-057 | API-02-076, API-02-077 |
| FR-02-058 | API-02-078, API-02-079 |
| FR-02-059 | API-02-007, API-02-080, API-02-081, API-02-082 |
| FR-02-060 | API-02-083, API-02-084, API-02-095 |
| FR-02-061 | API-02-085, API-02-086, API-02-087 |
| FR-02-062 | API-02-088, API-02-089 |

: Truy vết FR → API
<!-- gen:fr-api:end -->

### 3.4. Operation bổ sung ngoài danh mục FRS và tên các operation FRS chỉ liệt kê mã

Bản FRS đầu liệt kê API-02-001…091. Khi viết tập này, bốn khoảng trống ở luồng đã mô tả của FRS và use case làm phát sinh bốn operation (092…095); lượt rà soát chéo thêm ba operation (096…098) mà tập màn hình cần nhưng chưa có (Phụ lục B-3, B-4, B-6 của D03-06-PH02). Mã nối tiếp sau 091 để không đổi mã đã dùng ở các tập khác. Cả bảy operation đã được ghi vào FRS §9.4, bảng truy vết FR → API và use case.

| Mã | Operation | Lý do bổ sung | FR |
|---|---|---|---|
| API-02-092 | `POST …/lint-findings/{findingId}:acknowledge` | FR-02-017 luồng thay thế "Chấp nhận cảnh báo" kèm lý do không có API ở FRS | 017 |
| API-02-093 | `POST …/lint-findings/{findingId}:dispute-secret` | FR-02-018 "Đánh dấu không phải bí mật" do chủ dịch vụ đề nghị | 018 |
| API-02-094 | `POST …/lint-findings/{findingId}:confirm-dispute` | FR-02-018 bước xác nhận của SO (`PERM-02-operate`), tách khỏi người đề nghị | 018 |
| API-02-095 | `GET /operations/{operationId}` | FR-02-012, 026, 053, 060 trả `operationId` (FR-00-054) nhưng không có API tra tiến độ | 012, 026, 053, 060 |
| API-02-096 | `GET /plans` | UI-02-06 cần danh sách gói toàn tenant lọc theo API, trạng thái, kiểu xác thực; API-02-033 chỉ trả gói của một phiên bản | 027, 031 |
| API-02-097 | `GET /sla/summary` | UI-02-11 cần tổng hợp tuân thủ SLA toàn tenant theo kỳ và nhóm, API-02-079 chỉ thống kê lượt gọi (Đợt 2) | 056 |
| API-02-098 | `GET /review-requests/{reviewRequestId}` | UI-02-10 cần chi tiết một yêu cầu duyệt kèm điều kiện và lịch sử, API-02-044 chỉ trả danh sách | 035, 047 |

: Operation bổ sung ngoài FRS §9.4

FRS đề nghị ghi tên và mục đích của ba operation mà FRS chỉ liệt kê mã (UC-02-30, UC-02-01):

| Mã | Tên và mục đích |
|---|---|
| API-02-072 | `GET /national-sync/records`: danh sách bản ghi đồng bộ quốc gia, lọc theo trạng thái, API, hành động; nguồn dữ liệu của bảng ở UI-02-12 và của chỉ báo "đồng bộ quá hạn" ở UI-02-01 |
| API-02-090 | `GET /apis/{apiCode}/versions`: danh sách phiên bản của một API cho tab Phiên bản ở UI-02-02 |
| API-02-091 | `GET /apis/{apiCode}/history`: lịch sử thay đổi và vòng đời của API cho tab Lịch sử ở UI-02-02 |

: Tên và mục đích của API-02-072, 090, 091

### 3.5. Operation hợp lệ theo trạng thái

Máy chủ từ chối operation không hợp lệ ở trạng thái hiện tại bằng ERR-02-011 (409); `allowedActions[]` trong phản hồi cho giao diện biết trước. Ba bảng dưới tóm tắt máy trạng thái của FRS §4.3 đến §4.5 theo góc nhìn operation, là cơ sở để kiểm thử viên sinh ca âm.

| Operation | `DRAFT` | `PENDING` | `PUBLISHED` | `SUSPENDED` | `DEPRECATED` | `RETIRED` |
|---|---|---|---|---|---|---|
| Sửa đặc tả, context-path, backend, gói (API-02-018, 027, 028, 029, 035, 036) | Có | ERR-02-038 | Chỉ mô tả, thẻ, đầu mối, SLA; backend qua `BACKEND_CHANGE` | Như `PUBLISHED` | Không | Không |
| Gửi duyệt (API-02-042) | Có | ERR-02-011 | ERR-02-011 | ERR-02-011 | ERR-02-011 | ERR-02-011 |
| Rút lại (API-02-043) | ERR-02-011 | Có | ERR-02-011 | ERR-02-011 | ERR-02-011 | ERR-02-011 |
| Công bố `TEST`, `STAGING` (API-02-047) | Có | Không | Không | Không | Không | Không |
| Công bố `PROD` (API-02-047) | Không | Sau duyệt | Không | Không | Không | Không |
| Tạm ngừng (API-02-048) | Không | Không | Có | Không | Không | Không |
| Tiếp tục (API-02-049) | Không | Không | Không | Có | Không | Không |
| Đề nghị ngừng khuyến nghị (API-02-050) | Không | Không | Có | Có | Không | Không |
| Đề nghị ngừng hẳn hoặc hủy nháp (API-02-051) | Hủy ngay | Không | Không | Không | Có, nếu hết hạn và không còn đăng ký | Không |
| Đăng ký sử dụng mới (API-02-058) | ERR-02-025 | ERR-02-025 | Có | ERR-02-025 | ERR-02-025 | ERR-02-025 |
| Xóa API (API-02-052) | Có, khi mọi phiên bản `DRAFT` hoặc `RETIRED` | Không | ERR-02-030 | ERR-02-030 | ERR-02-030 | Có |

: Operation hợp lệ theo trạng thái phiên bản

| Operation | `STAGING` | `PUBLISHED` | `DEPRECATED` | `CLOSED` |
|---|---|---|---|---|
| Sửa thông tin, chính sách truy cập (API-02-035, 036) | Có | Chỉ theo hướng tương thích (BR-02-017) | Không | Không |
| Gửi duyệt công bố (API-02-037) | Có | Không | Không | Không |
| Đề nghị ngừng khuyến nghị (API-02-038) | Không | Có | Không | Không |
| Đề nghị đóng (API-02-039) | Không | Không | Có, nếu không còn đăng ký hiệu lực (ERR-02-024) | Không |
| Hủy gói nháp (API-02-041) | Có, nếu chưa từng công bố | Không | Không | Không |

: Operation hợp lệ theo trạng thái gói

| Operation | `PENDING` | `ACTIVE` | `SUSPENDED` | Trạng thái cuối |
|---|---|---|---|---|
| Duyệt, từ chối (API-02-045, 046) | Có | Không | Không | Không |
| Tạm ngừng (API-02-061) | Không | Có | Không | Không |
| Tiếp tục (API-02-062) | Không | Không | Có | Không |
| Thu hồi (API-02-063) | Không | Có | Có | Không |
| Hủy (API-02-064) | Có | Có | Không | Không |
| Gia hạn, xác nhận rà soát (API-02-065, 066) | Không | Có | Không | Không |
| Cấp lại phạm vi (API-02-068) | Không | Có, khi `grantStatus` khác `GRANTED` | Không | Không |

: Operation hợp lệ theo trạng thái đăng ký

## 4. Danh mục sự kiện

PH-02 phát 16 sự kiện cho phân hệ khác và nhận sáu sự kiện từ PH-04, PH-10. Sự kiện là kênh báo thay đổi, không phải nguồn dữ liệu duy nhất: PH-03 luôn có thể dựng lại trạng thái từ API-02-080, PH-15 từ API-02-081. Tên topic theo `{tenant}.catalog.{thực-thể}.{sự-kiện}.v1`, chữ thường (D00-04 §4). Lược đồ nằm ở [`asyncapi-catalog.yaml`](ph02/asyncapi-catalog.yaml) và đăng ký ở Apicurio chế độ BACKWARD (NFR-02-018, ADR-070).

<!-- gen:events:start -->
| Mã | Topic | Người phát | Khóa | Giữ | Người nhận | FR |
|---|---|---|---|---|---|---|
| EVT-02-01 | `{tenant}.catalog.api.registered.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-13, PH-15 | 10, 13, 61 |
| EVT-02-02 | `{tenant}.catalog.api.updated.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-15, PH-13 | 07, 08, 14, 22, 23, 26, 41, 42, 45, 55, 61 |
| EVT-02-03 | `{tenant}.catalog.api.deleted.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-15, PH-13, PH-14 | 40 |
| EVT-02-04 | `{tenant}.catalog.version.submitted.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-18, PH-13 | 34 |
| EVT-02-05 | `{tenant}.catalog.version.published.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-15, PH-13, PH-16 | 36 |
| EVT-02-06 | `{tenant}.catalog.version.state-changed.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-15, PH-13, PH-18 | 36, 37, 38, 39 |
| EVT-02-07 | `{tenant}.catalog.version.spec-source-changed.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-18 | 12 |
| EVT-02-08 | `{tenant}.catalog.plan.state-changed.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-15 | 27, 29, 30, 31, 32, 33 |
| EVT-02-09 | `{tenant}.catalog.subscription.requested.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-18 | 46 |
| EVT-02-10 | `{tenant}.catalog.subscription.activated.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-13, PH-15 | 47, 48 |
| EVT-02-11 | `{tenant}.catalog.subscription.state-changed.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-03, PH-12, PH-13 | 47, 51, 52 |
| EVT-02-12 | `{tenant}.catalog.change.notice-issued.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-15, PH-18 | 31, 36, 37, 38, 39, 55, 57 |
| EVT-02-13 | `{tenant}.catalog.sla.period-closed.v1` | `dh-connect` (outbox) | `apiCode` | 30 ngày | PH-13, PH-16 | 56 |
| EVT-02-14 | `{tenant}.catalog.national-sync.state-changed.v1` | `dh-connect` (outbox) | `apiCode` | 7 ngày | PH-13 | 53, 54 |
| EVT-02-15 | `{tenant}.catalog.gateway.drift-detected.v1` | `dh-connect` (outbox) | `environment` | 7 ngày | PH-13, PH-18 | 60 |
| EVT-02-16 | `{tenant}.catalog.review.overdue.v1` | `dh-connect` (outbox) | `reviewRequestId` | 7 ngày | PH-18 | 35, 47 |

: Danh mục sự kiện phát ra
<!-- gen:events:end -->

### 4.1. Quy ước phát và nhận

Bảng dưới nêu các quy ước chung cho mọi sự kiện của PH-02: định dạng, khóa phân vùng, bảo đảm giao và xử lý trùng.

| Mục | Quy ước |
|---|---|
| Cách phát | Ghi vào `ph02_catalog.outbox_event` cùng giao dịch với thay đổi dữ liệu; Debezium đưa lên Kafka, không bao giờ gọi Kafka trong giao dịch nghiệp vụ (cùng cách ADR-042) |
| Định dạng | CloudEvents 1.0 chế độ nhị phân: `ce_type = vn.datahub.catalog.{thực-thể}.{sự-kiện}.v1`, `ce_subject` = mã API hoặc mã yêu cầu, `ce_id` = `eventId`, `traceparent` |
| Khóa phân vùng | `apiCode` (EVT-02-01…14), `environment` (EVT-02-15), `reviewRequestId` (EVT-02-16); mọi sự kiện của một API vào cùng phân vùng nên người nhận thấy đúng thứ tự |
| Phân vùng, nhân bản, giữ | 3 phân vùng, 3 bản sao; giữ 7 ngày, riêng EVT-02-13 giữ 30 ngày (kỳ SLA hằng tháng) |
| Lũy đẳng | Người nhận bỏ qua `eventId` đã xử lý; sự kiện ảnh hưởng gateway (EVT-02-02, 05, 06, 08, 10, 11) mang `configEpoch`, người nhận bỏ qua số nhỏ hơn số đang giữ |
| Nội dung | Không có đặc tả, khóa, bí mật, giá trị cá nhân; chỉ mã, trạng thái, `changedFields`, số phiên bản (ràng buộc `ck_outbox_event_no_secret` ở D03-03-PH02, kiểm thử canary NFR-02-012) |
| Tương thích | Chỉ thêm trường tùy chọn trong `v1`; đổi kiểu hay bỏ trường sang `v2`, phát song song hai topic ≥ 6 tháng |
| Thứ tự giữa topic | Không bảo đảm; người nhận cần đồng bộ trạng thái đầy đủ dùng API đọc (API-02-080, 081) thay vì ghép sự kiện |
| Lỗi tiêu thụ | Người nhận thử lại lùi dần tối đa 5 lần rồi chuyển vào hàng chết của chính mình theo quy ước phân hệ đó; PH-02 không giữ hàng chết hộ người khác |

: Quy ước phát và nhận sự kiện

Ví dụ EVT-02-06 (phiên bản `1.2.0` của `ho-so-dat-dai` sang `DEPRECATED`, kèm `configEpoch` cho PH-03):

```json
{ "tenantId": "T68", "eventId": "0192d3a1-9b00-7c11-8d22-3e4f5a6b7c8d", "occurredAt": "2026-11-26T03:15:00Z", "apiCode": "ho-so-dat-dai", "versionNo": "1.2.0",
  "from": "PUBLISHED", "to": "DEPRECATED", "reason": "DEPRECATE", "sunsetAt": "2027-06-30T00:00:00Z", "successorVersionNo": "2.0.0", "securityHold": false, "configEpoch": 9420 }
```

### 4.2. Sự kiện PH-02 nhận

Bảng dưới liệt kê các sự kiện của phân hệ khác mà PH-02 tiêu thụ và việc PH-02 làm khi nhận.

| Mã | Topic | Phát bởi | Việc PH-02 làm | FR |
|---|---|---|---|---|
| EVT-04-02 | `{tenant}.integration.flow.updated.v1` | PH-04 | Đồng bộ nhãn, chủ quản của API sinh từ luồng | 013 |
| EVT-04-04 | `{tenant}.integration.version.approved.v1` | PH-04 | Cập nhật khung route và đặc tả sinh từ luồng, tạo hoặc cập nhật API `DRAFT` | 013 |
| EVT-04-07 | `{tenant}.integration.deployment.status-changed.v1` | PH-04 | Luồng bật hoặc tắt: cập nhật `flowSyncStatus`, cảnh báo nếu API đã công bố sinh từ luồng đã tắt | 013 |
| EVT-10-01 | `{tenant}.event.topic.activated.v1` | PH-10 | Làm mới bộ đệm dịch vụ sự kiện | 009 |
| EVT-10-03 | `{tenant}.event.topic.deprecated.v1` | PH-10 | Hiện nhãn "ngừng khuyến nghị" kèm kế nhiệm | 009 |
| EVT-10-04 | `{tenant}.event.topic.retired.v1` | PH-10 | Hiện nhãn "đã ngừng ở PH-10" | 009 |

: Sự kiện PH-02 nhận

PH-02 cũng nhận sự kiện tạm ngừng, thu hồi HTTT của PH-01 (FR-02-051) và sự kiện đổi tham số `02.*` của PH-18; mã theo D03-04-PH01, D03-04-PH18 khi hai tập đó được viết, nên chưa nằm trong AsyncAPI này.

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-02 là phân hệ nằm giữa PH-01 (HTTT), PH-03 (gateway), PH-12 (định danh), PH-14 (kết nối quốc gia) và PH-15 (cổng nhà phát triển). Bảng dưới nêu từng hợp đồng, hướng gọi và cách xử lý khi bên kia không khả dụng, theo cổng ra ở D03-02-PH02 §3.2.

| Bên | Hướng | Hợp đồng | Khi bên kia lỗi |
|---|---|---|---|
| PH-01 | PH-02 đọc | `SystemDirectoryApi`: HTTT `ACTIVE`, đơn vị chủ quản, đầu mối kỹ thuật, kiểu định danh máy; sự kiện tạm ngừng, thu hồi HTTT | Thao tác cần HTTT trả ERR-02-034; đọc danh mục vẫn được |
| PH-03 | PH-03 → PH-02 | API-02-080 (dữ liệu công bố, ndjson, `ETag`, `sinceConfigVersion`), API-02-082 (xác nhận nạp) | PH-03 tự giữ cấu hình đã nạp; PH-02 thử lại công bố 5 lần trong 15 phút |
| PH-03 | PH-02 → PH-03 | `GatewayApplyPort.requestApply`, `status`, `describe`, `rebuild` (đối soát, đẩy lại) | Phiên bản không đổi trạng thái, ERR-02-033; không chặn đọc |
| PH-03 | PH-02 nghe | EVT-03-01 (ảnh chụp đã phát), EVT-03-03 (route đổi trạng thái), EVT-03-07 (sắp chạm hạn mức), EVT-03-12 (ảnh chụp bị từ chối, kèm danh sách lỗi) để đối soát trạng thái áp dụng và báo người phát hành | Thiếu sự kiện thì đối soát định kỳ bằng `GatewayApplyPort.status` bù lại |
| PH-04 | PH-04 → PH-02 | API-02-017 (đăng ký API từ luồng), API-02-007 (đọc đặc tả đã gộp), EVT-04-02, 04, 07 | Luồng chạy bình thường; API `flowSyncStatus = ERROR` |
| PH-04 | PH-02 → PH-04 | `Ph04FlowClient.createFromSpec(workspaceCode, flowCode, apiRef)` cho API-02-032; lũy đẳng theo `apiRef` | ERR-02-034; tác vụ bất đồng bộ `FAILED` |
| PH-05 | PH-02 đọc | Danh sách kết nối cho backend loại `SYSTEM` (kiểm `connectionCode` khi khai backend) | ERR-02-020 khi kết nối không hợp lệ; ERR-02-034 khi PH-05 lỗi |
| PH-10 | PH-02 đọc | `GET /api/event/v1/topics` và EVT-10-01, 03, 04 cho API-02-013 | Trả bộ đệm cũ kèm `stale = true` |
| PH-12 | PH-02 → PH-12 | `ScopeGrantPort.attach`, `detach` (gắn, gỡ phạm vi `api:{apiCode}:{planCode}` lên client, lũy đẳng theo `Idempotency-Key`) | Đăng ký `ACTIVE` nhưng `grantStatus = FAILED`; chạy lại bằng API-02-068 |
| PH-13 | PH-02 đọc | `MetricsReadPort`: p99 theo kỳ, số lượt theo nhóm mã trạng thái, ngày có dữ liệu, sức khỏe backend | Kỳ SLA `INSUFFICIENT_DATA`, thống kê trả ERR-02-034 |
| PH-13 | PH-02 → PH-13 | Kiểm toán qua outbox; EVT-02-01…16 | Outbox giữ tới khi gửi được |
| PH-14 | PH-02 → PH-14 | `NationalCatalogPort.upsert`, `withdraw` lũy đẳng theo `payloadHash`; kết quả `ACKED`, `REJECTED` kèm lý do, `NOT_CONFIGURED` | Bản ghi `FAILED`, thử lại; không chặn vòng đời; cảnh báo sau `02.sync.overdue-days` (ADR-057) |
| PH-15 | PH-15 → PH-02 | API-02-081 (danh mục `portalPublished`), EVT-02-01, 02, 03, 05, 06, 08, 10, 12 | PH-15 giữ bản đã tải |
| PH-16 | PH-16 → PH-02 | API-02-079 và EVT-02-05, 13 (chỉ số tuân thủ) | Không ảnh hưởng PH-02 |
| PH-18 | PH-02 ↔ PH-18 | Tham số `02.*` (bộ đệm 60 giây), trạng thái đóng băng qua API-18-122 (`freeze-status`, scope `ops:calendar-read`; PH-02 không giữ cửa sổ đóng băng riêng), `NotificationApi` (kênh trong ứng dụng, thư điện tử, khóa lũy đẳng), lịch ngày làm việc, việc trong "Việc của tôi" | Dùng giá trị mặc định đã đệm; thông báo xếp hàng thử lại |
| Nền tảng quốc gia | Qua PH-14 | PH-02 không gọi trực tiếp; mọi trao đổi đi qua PH-14 | Như dòng PH-14 |
| HTTT khai thác | HTTT → PH-02 | API-02-004, 005, 007 với `catalog:read` | 429 khi vượt giới hạn |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-02

PH-02 là phân hệ mặt phẳng điều khiển nên toàn bộ 45 mã nằm ở dải 001–099; lỗi lúc chạy của lời gọi qua gateway thuộc PH-03 và không có mã ERR-02-1xx. Ý nghĩa và mã HTTP theo FRS §9.1 (nguồn chuẩn, đã chốt); cột "API phát sinh" sinh từ OpenAPI (operation nêu mã trong danh sách lỗi riêng). Năm mã có ở hầu hết operation (ERR-02-001, 003, 014, 015, 042) ghi "Chung". Câu thông báo người dùng nhìn thấy theo từng mã ở FRS §9.2 và D03-06-PH02 §5.2.

### 6.1. Danh sách mã lỗi

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | API phát sinh (API-02-) |
|---|---|---|---|
| ERR-02-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác | Chung (mọi API có tham số đường dẫn) |
| ERR-02-002 | 409 | Mã hoặc số hiệu đã tồn tại (kể cả đối tượng đã xóa hoặc ngừng) | 010, 011, 014, 027, 034, 054, 086 |
| ERR-02-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường | Chung (mọi API có thân hoặc tham số truy vấn) |
| ERR-02-004 | 422 | HTTT hoặc đơn vị không tồn tại hoặc không `ACTIVE` ở PH-01 | 014, 017, 057 |
| ERR-02-005 | 422 | Đặc tả không phân tích được hoặc sai cú pháp | 015, 018, 022 |
| ERR-02-006 | 422 | Đặc tả không đạt lớp 1 (chuẩn OpenAPI) | 042 |
| ERR-02-007 | 422 | Đặc tả còn lỗi nghiêm trọng lớp 2 (quy ước nền tảng) | 042 |
| ERR-02-008 | 422 | Đặc tả chứa bí mật hoặc dữ liệu cá nhân thật | 015, 042 |
| ERR-02-009 | 413 | Đặc tả hoặc tệp vượt kích thước tối đa | 015, 022, 085 |
| ERR-02-010 | 422 | Không tải được đặc tả từ URL (địa chỉ không được phép, không tới được, quá thời gian) | 015, 016 |
| ERR-02-011 | 409 | Chuyển trạng thái hoặc thao tác không hợp lệ ở trạng thái hiện tại | 016, 027, 029, 034, 037, 038, 039, 040 và 24 API khác |
| ERR-02-012 | 409 | Chưa đủ điều kiện để chuyển trạng thái, kèm danh sách điều kiện còn thiếu | 029, 037, 042, 045, 047 |
| ERR-02-013 | 403 | Vi phạm nguyên tắc bốn mắt | 045, 046, 094 |
| ERR-02-014 | 403 | Không có quyền | Chung |
| ERR-02-015 | 412 | Đối tượng đã thay đổi (`If-Match` không khớp) | Chung (mọi lệnh có `If-Match`) |
| ERR-02-016 | 422 | Dữ liệu thuộc bí mật nhà nước, không được công bố | 008, 014, 053 |
| ERR-02-017 | 409 | Có thay đổi phá vỡ tương thích nhưng giữ số phiên bản chính | 042 |
| ERR-02-018 | 422 | Số hiệu phiên bản không hợp lệ hoặc không tăng | 042, 054 |
| ERR-02-019 | 422 | Context-path trùng, xung đột hoặc sai quy ước | 014, 018, 054 |
| ERR-02-020 | 422 | Backend không hợp lệ (đích ngoài danh sách cho phép, TLS thấp, địa chỉ cấm, kết nối hoặc luồng không hợp lệ) | 027, 028, 032 |
| ERR-02-021 | 422 | Phiên bản chưa có backend `ACTIVE` hoặc chưa có gói | 037, 042 |
| ERR-02-022 | 422 | Kiểu xác thực không phù hợp mức phân loại dữ liệu | 036, 040 |
| ERR-02-023 | 422 | Hạn mức hoặc khai báo gói không hợp lý | 036 |
| ERR-02-024 | 409 | Gói còn đăng ký đang hiệu lực, không đóng hoặc xóa được | 039, 041 |
| ERR-02-025 | 409 | Gói hoặc phiên bản không nhận đăng ký mới | 058 |
| ERR-02-026 | 422 | HTTT khai thác không tồn tại, không `ACTIVE` hoặc không thuộc tổ chức của người gửi | 058 |
| ERR-02-027 | 409 | HTTT đã có đăng ký hiệu lực cho phiên bản này | 058 |
| ERR-02-028 | 422 | HTTT không thuộc đối tượng được dùng gói | 058 |
| ERR-02-029 | 422 | Thiếu mục đích, khối lượng dự kiến hoặc căn cứ pháp lý | 058, 065 |
| ERR-02-030 | 409 | Còn đăng ký hoặc phiên bản đang phục vụ, không ngừng hẳn hoặc xóa được | 051, 052 |
| ERR-02-031 | 422 | Hạn chuyển đổi ngắn hơn tối thiểu | 038, 050 |
| ERR-02-032 | 422 | Thiếu phiên bản kế nhiệm khi ngừng khuyến nghị | 038, 050 |
| ERR-02-033 | 503 | Cổng API (PH-03) hoặc APISIX không nhận cấu hình trong thời hạn | 045, 047, 048, 049, 061, 062, 084 |
| ERR-02-034 | 503 | Dịch vụ phụ thuộc không khả dụng (PH-01, PH-04, PH-10, PH-12, PH-13, PH-14, PH-18, kho đối tượng) | 013, 015, 021, 031, 032, 045, 047, 068 và 5 API khác |
| ERR-02-035 | 409 | Đang có lần kiểm tra, đồng bộ hoặc đối soát chạy cho cùng đối tượng | 016, 021, 032, 055, 069, 071, 084 |
| ERR-02-036 | 429 | Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép | 015, 016, 021, 022, 076 |
| ERR-02-037 | 422 | Thao tác hoặc đường dẫn không có trong đặc tả | 032, 036 |
| ERR-02-038 | 409 | Phiên bản đang chờ duyệt hoặc đã khóa, không sửa được | 016, 018, 027, 028, 029, 034, 035, 036 và 2 API khác |
| ERR-02-039 | 423 | Đang đóng băng thay đổi môi trường thật | 028, 047 |
| ERR-02-040 | 422 | Vượt trần tham số của tenant | 010, 027, 034, 040, 054, 089 |
| ERR-02-041 | 400 | Thiếu lý do bắt buộc | 025, 045, 046, 048, 061, 063, 073, 089 và 3 API khác |
| ERR-02-042 | 422 | `Idempotency-Key` đã dùng với thân khác | Chung (mọi `POST` có `Idempotency-Key`) |
| ERR-02-043 | 422 | Mức hiển thị không phù hợp mức phân loại dữ liệu | 014, 053 |
| ERR-02-044 | 409 | API chưa đủ điều kiện đồng bộ quốc gia | 069, 071 |
| ERR-02-045 | 400 | Gói nhập từ APIM cũ sai định dạng | 085, 086 |

: Mã lỗi ERR-02
<!-- gen:errors:end -->

### 6.2. Thân phản hồi và trường bổ sung

Mọi lỗi dùng `application/problem+json` với `type = https://datahub.gov.vn/errors/ERR-02-nnn`, `title` (nghĩa của mã), `status`, `code`, `traceId`, `detail` (câu cụ thể theo ngữ cảnh, đã che bí mật) và các trường dưới đây khi có.

| Mã | Trường bổ sung | Ví dụ `detail` hoặc nội dung |
|---|---|---|
| ERR-02-003 | `errors[]` (`path`, `rule`, `message`) | "Trường `contextPath` phải khớp `^/[a-z0-9/-]{3,120}$`." |
| ERR-02-006, 007 | `findings[]` (`ruleId`, `severity`, `location`, `message`) | "Đặc tả còn 3 lỗi theo quy ước nền tảng." Phát hiện đầy đủ lấy bằng API-02-020 |
| ERR-02-008 | `findings[]` chỉ `ruleId`, `location`, `message` (đuôi đã che) | Không bao giờ lặp lại giá trị bí mật hay giá trị cá nhân |
| ERR-02-010 | — | Nêu lý do chung (địa chỉ không được phép, không tới được, quá thời gian); không nêu địa chỉ IP nội bộ phân giải được |
| ERR-02-012 | `missing[]` (mã điều kiện: `NO_ACTIVE_BACKEND`, `NO_PLAN`, `SPEC_NOT_VALID`, `TEST_DEPLOY_REQUIRED`, `BREAKING_WITHOUT_MAJOR`, `OPEN_REVIEW_EXISTS`) | "Chưa đủ điều kiện: chưa có backend hoạt động, chưa có gói." |
| ERR-02-013 | — | Nêu vai trò bị trùng (người gửi hoặc người sửa gần nhất), không nêu dữ liệu cá nhân |
| ERR-02-017 | `errors[]` kèm `suggestedVersion` | "Có 3 thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại." |
| ERR-02-024, 030 | `usages[]` (`kind`, `ref`) | "Còn 5 đăng ký đang dùng gói này." |
| ERR-02-031 | `errors[]` kèm hạn tối thiểu | "Hạn chuyển đổi tối thiểu 180 ngày." |
| ERR-02-033, 034 | `retryAfterSeconds` | "Cổng API chưa nhận cấu hình, hệ thống đang thử lại." |
| ERR-02-036 | `retryAfterSeconds`, tiêu đề `Retry-After` | "Đã thực hiện quá số lần cho phép. Thử lại sau 12 phút." |
| ERR-02-039 | `errors[]` kèm thời điểm kết thúc đóng băng | "Đang trong khoảng đóng băng thay đổi môi trường thật tới 03/12/2026 07:00." |
| ERR-02-040 | `errors[]` kèm `limit` | "Vượt trần 10 backend mỗi phiên bản (`02.backend.max-per-version`)." |

: Thân phản hồi và trường bổ sung của mã lỗi

### 6.3. Ánh xạ ngoại lệ miền sang mã lỗi

`CatalogProblemAdvice` chuyển ngoại lệ có kiểu thành `ProblemDetail`; bảng ánh xạ đầy đủ ở D03-02-PH02 §8.6. Quy tắc riêng của giao diện công khai:

- Đối tượng thuộc tenant khác và đối tượng người gọi không được xem trả cùng thân ERR-02-001 (404), cùng độ dài thân và thời gian xấp xỉ, để không lộ sự tồn tại (NFR-02-013, SEC-87).
- Phiên bản nháp của đơn vị khác bị ẩn khỏi danh sách và trả ERR-02-001 khi gọi trực tiếp, không bao giờ 403 (BR-02-039).
- Mọi lệnh đổi trạng thái kiểm theo thứ tự: tenant và quyền (ERR-02-014) → tồn tại (ERR-02-001) → `If-Match` (ERR-02-015) → trạng thái (ERR-02-011) → điều kiện (ERR-02-012) → bốn mắt (ERR-02-013) → dịch vụ phụ thuộc (ERR-02-033, 034).
- Không thông điệp nào lặp lại nội dung đặc tả, khóa hay chuỗi kết nối; bộ lọc che áp lên `detail` trước khi trả.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng chỉ có giá trị khi máy kiểm được. Bảng dưới là các kiểm tra chạy ở cổng CI-5 (D04-02); kết quả ngày 26/11/2026 ghi ở cuối chương.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; mọi ví dụ khớp lược đồ; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`; không `default` response; `operationId` duy nhất | `check_contracts.py` (`openapi-spec-validator`, `jsonschema`) | CI-5 |
| Lệnh ghi (`PUT`, `PATCH`, `DELETE`) có `If-Match`; `POST` tạo và đổi trạng thái có `Idempotency-Key` | `check_contracts.py` | CI-5 |
| Không lược đồ nào có trường bí mật (`password`, `secret`, `privateKey`, `clientSecret`, `apiKey`) | `check_contracts.py` | CI-5 |
| Đủ API-02-001…098 của FRS; mọi mã ERR-02 dùng ở OpenAPI có ở FRS §9.1 và ở §6 tài liệu này | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0 hợp lệ; đủ EVT-02-01…16; payload ví dụ khớp lược đồ | `@asyncapi/parser` 3, `check_contracts.py` | CI-5 |
| Lint quy ước (tên đường dẫn, hậu tố hành động, phân trang, lỗi RFC 9457) | Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`, `sinh_dac_ta_api.py` rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp FRS, SDD, CSDL | `build/tools/kiem_tra_ma.py` | CI-1 |
| Hợp đồng chạy thật với bản cài đặt | Kiểm thử hợp đồng (Schemathesis hoặc tương đương) từ OpenAPI, chạy ở môi trường thử | CI-6 |

: Kiểm tra hợp đồng trong CI

Kết quả ngày 26/11/2026: OpenAPI hợp lệ (98 operation, 145 lược đồ), 26 ví dụ khớp; AsyncAPI hợp lệ (`@asyncapi/parser` 3.x: 0 lỗi, 0 cảnh báo ngoài gợi ý nâng phiên bản AsyncAPI), 16 payload ví dụ khớp. Spectral, oasdiff và kiểm thử hợp đồng chạy thật chưa cấu hình vì chưa có bộ luật dự án và bản cài đặt (D04-02).

## 8. Ánh xạ từ hệ cũ

PH-02 thay ba nguồn: mô-đun `catalog` của `apps/control` trong repo (306 dòng, route `/api/v1/catalog/*`), SRS cũ `docs/07-srs/SRS-PH-02-api-catalog.md` (định nghĩa đường dẫn `/api/v1/catalog`, `/api/v1/services`, `/api/admin/v1/services`) và chức năng quản lý API của APIM cũ (`LGC-APIM`). Mọi đường dẫn cũ gộp về một tiền tố `/api/catalog/v1`. Đường dẫn cũ của repo (`GET`, `POST /api/v1/catalog/services`, `POST …/{id}/publish`) không phân quyền, không tenant, không qua duyệt; gỡ cùng mô-đun cũ khi PH-02 mới chạy (D03-02-PH02 §2.4, GAP-02-01, 03).

### 8.1. Đường dẫn trong SRS cũ → API mới

Bảng dưới ánh xạ từng đường dẫn của SRS cũ sang operation mới, để các bên đang gọi hợp đồng cũ biết chuyển sang đâu.

| Đường dẫn cũ | API mới | Ghi chú |
|---|---|---|
| `GET /api/v1/catalog/services` | API-02-004 (cho máy), API-02-001 (cho console) | Tách hai đối tượng đọc; thêm mức hiển thị |
| `GET /api/v1/catalog/services/{code}` | API-02-005, API-02-002 | Mã `code` thành `apiCode` |
| `GET /api/v1/catalog/services/{code}/openapi` | API-02-007 | Có `resolved`, `ETag` |
| `GET /api/v1/catalog/services/{code}/versions` | API-02-090 | |
| `GET /api/v1/catalog/services/{code}/sla` | API-02-074, API-02-075 | SLA cam kết và thực tế theo kỳ |
| `GET /api/v1/catalog/search?q=` | API-02-003 | `GET /search/apis` |
| `POST /api/v1/services` | API-02-015, API-02-014 | Hai bước: nạp đặc tả rồi đăng ký |
| `POST /api/v1/services/{code}/versions` | API-02-054 | |
| `POST /api/v1/services/validate-spec` | API-02-022 | Không lưu; hỗ trợ SARIF |
| `GET /api/v1/services/{code}/versions/{v}/diff` | API-02-055 | `GET /apis/{apiCode}/version-diff?from&to` |
| `POST /api/v1/services/{code}/versions/{v}/submit` | API-02-042 | Có `Idempotency-Key`, `If-Match` |
| `POST /api/v1/services/{code}/deprecate` | API-02-050 | Đề nghị, không tự ngừng |
| `POST`, `DELETE /api/v1/services/{code}/subscribe` | API-02-058, API-02-064 | Đăng ký là tài nguyên `/subscriptions` |
| `GET /api/v1/services/{code}/subscribers` | API-02-059 | `?apiCode=` |
| `GET /api/v1/services/{code}/usage` | API-02-078 | Đợt 2 |
| `GET /api/admin/v1/services/pending` | API-02-044 | Hợp vào "Việc của tôi" |
| `POST /api/admin/v1/services/{code}/versions/{v}/approve`, `reject` | API-02-045, API-02-046 | Duyệt theo yêu cầu duyệt, không theo tên phiên bản |
| `POST /api/admin/v1/services/{code}/suspend` | API-02-048 | Tạm ngừng khẩn, `securityHold` |
| `POST /api/admin/v1/services/sync-ministry` | API-02-069 | Đồng bộ qua PH-14 |
| `GET /api/admin/v1/services/sync-status` | API-02-070, API-02-072 | |
| `GET /api/admin/v1/services/sla-compliance` | API-02-075, API-02-079 | |
| `GET /api/admin/v1/services/duplicates` | API-02-023 | Theo phiên bản |

: Đường dẫn trong SRS cũ chuyển sang API mới

### 8.2. Chức năng APIM cũ → API mới

Bảng dưới ánh xạ từng chức năng của APIM cũ sang operation mới và kết luận giữ, nâng cấp hay thay thế đã chốt ở FRS.

| Mã cũ | Chức năng | API mới | Kết luận ở FRS |
|---|---|---|---|
| LGC-APIM-001 | Danh sách API | 001, 002, 003, 004, 005 | Giữ nguyên |
| LGC-APIM-002 | Tạo API từ đầu | 014, 018, 027, 030 | Nâng cấp |
| LGC-APIM-003 | Tạo API bằng Swagger | 015, 016, 020, 021, 022 | Nâng cấp |
| LGC-APIM-004 | Lưu nháp, tạo và triển khai | 042, 047 (TEST, STAGING, PROD) | Nâng cấp |
| LGC-APIM-005 | Start, Stop API | 048, 049 | Giữ nguyên |
| LGC-APIM-006 | Publish, Unpublish lên portal | 053, 047 | Giữ nguyên |
| LGC-APIM-008 | Xóa API | 051, 052 | Nâng cấp |
| LGC-APIM-009 | Gói bốn trạng thái | 033…041 | Giữ nguyên |
| LGC-APIM-010 | Gói, bước Define | 034, 035 | Giữ nguyên |
| LGC-APIM-011 | Gói, bước Secure | 036 | Nâng cấp |
| LGC-APIM-016 | Subscription theo API | 059, 058, 045, 046, 061…064 | Giữ nguyên |
| LGC-APIM-017 | Đường dẫn sử dụng API | 006 | Giữ nguyên |
| LGC-APIM-018 | Endpoint backend | 026…029, 031 | Giữ nguyên |
| LGC-APIM-021 | Subscription theo Application | 059, 060 | Giữ nguyên |
| LGC-BUS-028 | REST API của agent Bus | 017 | Thay thế |
| (nhập dữ liệu APIM cũ) | Di trú API, gói, đăng ký | 085, 086, 087 | Mới (FR-02-061) |

: Chức năng APIM cũ chuyển sang API mới

## 9. Câu hỏi mở

Các câu hỏi dưới đây chưa chốt được khi viết tập API; mỗi câu kèm đề xuất tạm để việc hiện thực không bị chặn.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q02-55 | Bảy operation bổ sung API-02-092…098 (ngoài 91 operation của bản FRS đầu): có chấp nhận nối mã sau 091 hay gộp vào operation sẵn có | Giữ nối mã (không đổi mã đã dùng). Đã ghi vào FRS §9.4, use case, màn hình và test case ở lượt rà soát; còn SDD §4 (giao diện công bố) ghi tên ở đề nghị đồng bộ. Phương án gộp làm thân `ReasonRequest` đa nghĩa, khó kiểm thử nên không chọn |
| Q02-56 | API-02-080 trả toàn bộ dữ liệu công bố của tenant khi `gap = true` hoặc lần đầu; tỉnh QM-LON (2.000 API, 20.000 đăng ký, NFR-02-010) ước khoảng 15 MiB ndjson (giả định: 5 KiB mỗi API, 0,5 KiB mỗi consumer) | Luồng ndjson, `limit = 500` bản ghi mỗi lượt kèm con trỏ `configVersion`, nén gzip; PH-03 chốt kích thước lô khi viết D03-04-PH03 |
| Q02-57 | `Cache-Control: private, max-age=300` ở API-02-004 làm HTTT khai thác vẫn thấy API đã `SUSPENDED` tới 5 phút | Giảm còn `max-age=60` cho mục không `PUBLISHED`, giữ 300 cho mục `PUBLISHED`; kết hợp `ETag` để `304` rẻ. Cần PH-15 xác nhận chu kỳ nạp |
| Q02-58 | API-02-007 cho HTTT có `catalog:read` tải đặc tả mọi API trong phạm vi mức hiển thị; đặc tả mức `RESTRICTED`, `SENSITIVE` mô tả cấu trúc dữ liệu nhạy cảm | Đặc tả mức `PUBLIC`, `INTERNAL` tải tự do trong tenant; mức `RESTRICTED` trở lên chỉ tải khi có đăng ký `ACTIVE` hoặc người gọi thuộc tổ chức chủ quản. Cần ATTT xác nhận |
| Q02-59 | API cần hai quyết định duyệt (API `SENSITIVE`, `requiredApprovals = 2`) mà `If-Match` của API-02-045 dùng `etag` của yêu cầu duyệt: quyết định đầu làm `etag` đổi, người duyệt thứ hai phải tải lại | Chấp nhận, vì danh sách API-02-044 trả `etag` mới; giao diện tự tải lại và báo "đã có một quyết định, cần quyết định của anh/chị". Không bỏ `If-Match` ở lệnh duyệt |
| Q02-60 | Màn UI-02-01, 08, 12 cần xuất danh sách ra CSV hoặc Excel (Phụ lục B-2 của D03-06-PH02); FR-00-030 quy định xuất chung nhưng chưa có hợp đồng API cho PH-02: dùng `Accept: text/csv` trên API-02-001, 059, 072 hay một operation xuất riêng | Dùng `Accept: text/csv` cùng bộ lọc với danh sách, trả `Content-Disposition`, không chứa bí mật và áp đúng quyền xem; chưa thêm operation. Cần PH-18 xác nhận cơ chế xuất tệp lớn (bất đồng bộ qua `operationId`). Cho tới khi chốt, nút "Xuất" ở màn hình dùng đề xuất tạm này |

: Câu hỏi mở của tập API PH-02




## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI (hoặc `tools/spec.py`) rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục: mục đích, phương thức và đường dẫn, quyền, FR hiện thực, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú. Endpoint xếp theo nhóm như chương 3.

<!-- gen:dac-ta-api:start -->

### Danh mục và tra cứu

#### API-02-001 · Danh sách API trong danh mục

::: dac-ta
**Mục đích.** Danh sách API trong danh mục.

**Phương thức, đường dẫn.** `GET /apis`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-001.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, string, tùy chọn); `dataClass` (query, string, tùy chọn); `visibility` (query, string, tùy chọn); `origin` (query, string, tùy chọn); `categoryCode` (query, CategoryCode, tùy chọn); `tag` (query, string, tùy chọn); `providerSystemCode` (query, SystemCode, tùy chọn); `ownerOrgCode` (query, OrgCode, tùy chọn); `attention` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Mặc định ẩn phiên bản `RETIRED`; chỉ trả API người gọi được xem (BR-02-039). `facets` đếm theo trạng thái, loại dữ liệu, phân loại.
:::

#### API-02-002 · Chi tiết một API

::: dac-ta
**Mục đích.** Chi tiết một API.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-002.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (query, VersionNo, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Trả `ETag`; `allowedActions[]` cho giao diện bật tắt nút đúng như máy chủ sẽ kiểm. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-003 · Tìm kiếm toàn văn danh mục

::: dac-ta
**Mục đích.** Tìm kiếm toàn văn danh mục.

**Phương thức, đường dẫn.** `GET /search/apis`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-003.

**Tham số.** `q` (query, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `dataClass` (query, string, tùy chọn); `visibility` (query, string, tùy chọn); `categoryCode` (query, CategoryCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Tìm trên tên, mô tả, thẻ, tên thao tác; không dấu. Khi công cụ tìm kiếm ngoài lỗi, trả `degraded = true` và kết quả từ PostgreSQL. Mã lỗi riêng: ERR-02-003.
:::

#### API-02-004 · Danh mục cho HTTT khai thác và cổng nhà phát triển

::: dac-ta
**Mục đích.** Danh mục cho HTTT khai thác và cổng nhà phát triển.

**Phương thức, đường dẫn.** `GET /catalog/apis`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-004.

**Tham số.** `updatedSince` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `categoryCode` (query, CategoryCode, tùy chọn); `q` (query, string, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Lọc theo mức hiển thị của người gọi (BR-02-039); `Cache-Control: private, max-age=300`, `public` chỉ với tập `PUBLIC`. Hỗ trợ `If-None-Match`.
:::

#### API-02-005 · Một API trong danh mục cho HTTT khai thác

::: dac-ta
**Mục đích.** Một API trong danh mục cho HTTT khai thác.

**Phương thức, đường dẫn.** `GET /catalog/apis/{apiCode}`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-004.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogApi`; trường bắt buộc: `apiCode`, `name`, `dataClass`, `visibility`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Cùng quy tắc hiển thị với API-02-004; API ngoài mức hiển thị của người gọi trả ERR-02-001. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-006 · Đường dẫn sử dụng và mẫu gọi API

::: dac-ta
**Mục đích.** Đường dẫn sử dụng và mẫu gọi API.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/usage-guide`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-005.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageGuide`; trường bắt buộc: `baseUrl`, `contextPath`, `operations`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Địa chỉ gateway ghép context-path, thao tác, `tokenUrl`, phạm vi và mẫu `curl`, `javascript`, `java` (giả lập, không chứa khóa thật). Mã lỗi riêng: ERR-02-001.
:::

#### API-02-007 · Tải đặc tả OpenAPI đã công bố

::: dac-ta
**Mục đích.** Tải đặc tả OpenAPI đã công bố.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/spec`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-006, FR-02-059.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `resolved` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Đặc tả đã gộp tham chiếu ngoài khi `resolved=true` (mặc định). Chỉ phiên bản đã công bố hoặc người gọi có quyền xem bản nháp. Trả `ETag`, `Content-Disposition`. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-090 · Danh sách phiên bản của API

::: dac-ta
**Mục đích.** Danh sách phiên bản của API.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-002.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionList`; trường bắt buộc: `items`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Tab Phiên bản của UI-02-02: số hiệu, trạng thái, `sunsetAt`, phiên bản kế nhiệm, số đăng ký `ACTIVE`, cờ thay đổi phá vỡ. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-091 · Lịch sử thay đổi và vòng đời của API

::: dac-ta
**Mục đích.** Lịch sử thay đổi và vòng đời của API.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/history`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-002.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `kind` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Tab Lịch sử của UI-02-02: chuyển trạng thái, duyệt, sửa, đổi chủ quản; lấy từ nhật ký kiểm toán đã che dữ liệu nhạy cảm. Mã lỗi riêng: ERR-02-001.
:::

### Đăng ký API và nạp đặc tả

#### API-02-014 · Đăng ký API mới (kèm phiên bản đầu `DRAFT`)

::: dac-ta
**Mục đích.** Đăng ký API mới (kèm phiên bản đầu `DRAFT`).

**Phương thức, đường dẫn.** `POST /apis`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-010.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApiCreate`; trường bắt buộc: `apiCode`, `name`, `providerSystemCode`, `dataClass`, `contextPath`, `specId`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ApiDetail`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Nhận `specId` từ API-02-015. Tạo API và phiên bản `1.0.0` ở `DRAFT`, `origin = OPENAPI`. Phát EVT-02-01. Trả `Location`, `ETag`. Mã lỗi riêng: ERR-02-002, ERR-02-003, ERR-02-004, ERR-02-016, ERR-02-019, ERR-02-043.
:::

#### API-02-015 · Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL

::: dac-ta
**Mục đích.** Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL.

**Phương thức, đường dẫn.** `POST /spec-uploads`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-011.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SpecUpload`; trường bắt buộc: `source`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SpecInfo`; trường bắt buộc: `specId`, `sha256`, `sizeBytes`, `openapiVersion`, `operationCount`, `lintSummary`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `413` Đặc tả hoặc tệp vượt kích thước tối đa (ERR-02-009); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `429` Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Phân tích một lần, gộp tham chiếu ngoại tuyến, tính `sha256`, lưu vào kho đối tượng, chạy ba lớp kiểm tra và trả tóm tắt. Nguồn URL qua `SafeFetcher` (SEC-16). Mã lỗi riêng: ERR-02-003, ERR-02-005, ERR-02-008, ERR-02-009, ERR-02-010, ERR-02-034, ERR-02-036.
:::

#### API-02-016 · Đồng bộ lại đặc tả từ URL nguồn

::: dac-ta
**Mục đích.** Đồng bộ lại đặc tả từ URL nguồn.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/spec:resync`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-012.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OperationAccepted`; trường bắt buộc: `operationId`, `status`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `429` Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`).

**Ghi chú.** Chỉ phiên bản có `source = URL`. Kết quả (`unchanged` hoặc `changed` kèm `diffSummary`) lấy bằng API-02-095. Thay đổi phát EVT-02-07. Mã lỗi riêng: ERR-02-010, ERR-02-011, ERR-02-035, ERR-02-036, ERR-02-038.
:::

#### API-02-018 · Sửa thông tin API, context-path và thay đặc tả khi còn bản nháp

::: dac-ta
**Mục đích.** Sửa thông tin API, context-path và thay đặc tả khi còn bản nháp.

**Phương thức, đường dẫn.** `PATCH /apis/{apiCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-014, FR-02-024.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApiUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Thay đặc tả hoặc context-path chỉ khi phiên bản `DRAFT`; phiên bản `PUBLISHED` chỉ sửa mô tả, thẻ, đầu mối, SLA. Lưu `contextPath` ở đây sau khi kiểm bằng API-02-030. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-005, ERR-02-015, ERR-02-019, ERR-02-038.
:::

#### API-02-019 · Tải mẫu đặc tả OpenAPI theo quy ước nền tảng

::: dac-ta
**Mục đích.** Tải mẫu đặc tả OpenAPI theo quy ước nền tảng.

**Phương thức, đường dẫn.** `GET /spec-templates/openapi`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-015.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Tệp mẫu có đủ các mục quy ước lớp 2 (LINT-02-nn), dữ liệu giả lập.
:::

### Vòng đời, duyệt, phiên bản

#### API-02-042 · Gửi duyệt công bố phiên bản

::: dac-ta
**Mục đích.** Gửi duyệt công bố phiên bản.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:submit`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-034.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmitRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Kiểm tra điều kiện: đặc tả đạt ba lớp, có backend `ACTIVE`, có gói, đã thử TEST nếu `02.submit.require-test-deploy`, không có thay đổi phá vỡ khi giữ số chính. Phiên bản sang `PENDING`, phát EVT-02-04. Mã lỗi riêng: ERR-02-001, ERR-02-006, ERR-02-007, ERR-02-008, ERR-02-011, ERR-02-012, ERR-02-015, ERR-02-017, ERR-02-018, ERR-02-021, ERR-02-038.
:::

#### API-02-043 · Rút lại yêu cầu duyệt

::: dac-ta
**Mục đích.** Rút lại yêu cầu duyệt.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:withdraw`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-034.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Chỉ khi chưa ai quyết định; phiên bản về `DRAFT`, yêu cầu duyệt chuyển `WITHDRAWN`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015.
:::

#### API-02-044 · Danh sách yêu cầu duyệt (Việc của tôi)

::: dac-ta
**Mục đích.** Danh sách yêu cầu duyệt (Việc của tôi).

**Phương thức, đường dẫn.** `GET /review-requests`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-030, FR-02-031, FR-02-035, FR-02-038, FR-02-039, FR-02-047.

**Tham số.** `kind` (query, ReviewKind, tùy chọn); `status` (query, string, tùy chọn); `mine` (query, boolean, tùy chọn); `apiCode` (query, ApiCode, tùy chọn); `overdue` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Chỉ trả yêu cầu người gọi được xem; `canDecide` cho biết người gọi có được quyết định không (loại trừ người gửi, người sửa gần nhất). Mỗi mục có `etag`. Mã lỗi riêng: ERR-02-003.
:::

#### API-02-045 · Duyệt yêu cầu (công bố, gói, ngừng dùng, đăng ký)

::: dac-ta
**Mục đích.** Duyệt yêu cầu (công bố, gói, ngừng dùng, đăng ký).

**Phương thức, đường dẫn.** `POST /review-requests/{reviewRequestId}:approve`.

**Quyền.** `PERM-02-publish hoặc PERM-02-approve-subscription`.

**FR hiện thực.** FR-02-030, FR-02-035, FR-02-047.

**Tham số.** `reviewRequestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReviewDecision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReviewRequest`; trường bắt buộc: `reviewRequestId`, `kind`, `status`, `requestedAt`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Quyền theo loại: `PERM-02-publish` cho phiên bản, gói, mức hiển thị; `PERM-02-approve-subscription` cho đăng ký. Bốn mắt kiểm ở máy chủ (BR-02-008, BR-02-026). Với đăng ký có thể kèm `conditions` (`approvedDailyCalls`, `expiresAt`). Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-012, ERR-02-013, ERR-02-015, ERR-02-033, ERR-02-034, ERR-02-041.
:::

#### API-02-046 · Từ chối yêu cầu duyệt

::: dac-ta
**Mục đích.** Từ chối yêu cầu duyệt.

**Phương thức, đường dẫn.** `POST /review-requests/{reviewRequestId}:reject`.

**Quyền.** `PERM-02-publish hoặc PERM-02-approve-subscription`.

**FR hiện thực.** FR-02-035, FR-02-047.

**Tham số.** `reviewRequestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReviewDecision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReviewRequest`; trường bắt buộc: `reviewRequestId`, `kind`, `status`, `requestedAt`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Bắt buộc `comment`; phiên bản `PENDING` về `DRAFT`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-013, ERR-02-015, ERR-02-041.
:::

#### API-02-047 · Công bố phiên bản ra gateway và danh mục

::: dac-ta
**Mục đích.** Công bố phiên bản ra gateway và danh mục.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:publish`.

**Quyền.** `PERM-02-create hoặc PERM-02-operate`.

**FR hiện thực.** FR-02-036.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PublishRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PublishResult`; trường bắt buộc: `status`, `gatewayState`; `202` đã nhận, xử lý bất đồng bộ, `PublishResult`; trường bắt buộc: `status`, `gatewayState`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `423` Đang đóng băng thay đổi môi trường thật (ERR-02-039); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** `environment = TEST` hoặc `STAGING` do SV, TA thử (`PERM-02-create`); `PROD` chỉ sau duyệt, người gọi là hệ thống hoặc TO thử lại (`PERM-02-operate`, kèm `reviewRequestId`). Trả `202` khi gateway chưa xác nhận trong 30 giây; phiên bản giữ trạng thái cũ cho tới khi có xác nhận (saga công bố). Phát EVT-02-05. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-012, ERR-02-015, ERR-02-033, ERR-02-034, ERR-02-038, ERR-02-039.
:::

#### API-02-048 · Tạm ngừng phiên bản

::: dac-ta
**Mục đích.** Tạm ngừng phiên bản.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:suspend`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-037.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SuspendRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Không cần duyệt (BR-02-034); đặt `suspendDeadline` = hiện tại + `02.suspend.max-days`. Phát EVT-02-06, EVT-02-12. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-033, ERR-02-041.
:::

#### API-02-049 · Tiếp tục phiên bản

::: dac-ta
**Mục đích.** Tiếp tục phiên bản.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:resume`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-037.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Do SO tạm ngừng vì an ninh thì chỉ SO được tiếp tục (BR-02-034). Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-014, ERR-02-015, ERR-02-033.
:::

#### API-02-050 · Đề nghị ngừng khuyến nghị có lộ trình

::: dac-ta
**Mục đích.** Đề nghị ngừng khuyến nghị có lộ trình.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:propose-deprecate`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-038.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DeprecateRequest`; trường bắt buộc: `sunsetAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Hạn chuyển đổi tối thiểu `02.deprecation.min-days` (180 ngày). Tạo yêu cầu duyệt `VERSION_DEPRECATE`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-031, ERR-02-032.
:::

#### API-02-051 · Đề nghị ngừng hẳn hoặc hủy bản nháp

::: dac-ta
**Mục đích.** Đề nghị ngừng hẳn hoặc hủy bản nháp.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}:propose-retire`.

**Quyền.** `PERM-02-submit hoặc PERM-02-create`.

**FR hiện thực.** FR-02-039.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`; `200` thành công, `VersionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Phiên bản `DRAFT`: hủy ngay, trả `200` (quyền `PERM-02-create`). Phiên bản khác: tạo yêu cầu duyệt `VERSION_RETIRE`; còn đăng ký hiệu lực thì ERR-02-030, không bao giờ tự ngừng hẳn. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-030.
:::

#### API-02-052 · Xóa API (xóa mềm)

::: dac-ta
**Mục đích.** Xóa API (xóa mềm).

**Phương thức, đường dẫn.** `DELETE /apis/{apiCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-040.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Chỉ khi mọi phiên bản `DRAFT` hoặc `RETIRED` và không còn đăng ký. Giữ chỗ mã vĩnh viễn. Phát EVT-02-03. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-030.
:::

#### API-02-053 · Đặt mức hiển thị, công bố hoặc gỡ khỏi cổng nhà phát triển

::: dac-ta
**Mục đích.** Đặt mức hiển thị, công bố hoặc gỡ khỏi cổng nhà phát triển.

**Phương thức, đường dẫn.** `PUT /apis/{apiCode}/visibility`.

**Quyền.** `PERM-02-create hoặc PERM-02-submit`.

**FR hiện thực.** FR-02-041.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VisibilityUpdate`; trường bắt buộc: `visibility`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiDetail`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Hạ mức hoặc gỡ cổng: `200` ngay. Nâng mức: tạo yêu cầu duyệt `VISIBILITY_RAISE` và trả `202` (cần `PERM-02-submit`). Mức `PUBLIC` chỉ với dữ liệu `PUBLIC`. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-016, ERR-02-043.
:::

#### API-02-054 · Tạo phiên bản mới

::: dac-ta
**Mục đích.** Tạo phiên bản mới.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-042.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VersionCreate`; trường bắt buộc: `versionNo`, `baseVersionNo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `VersionDetail`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Sao chép đặc tả, backend, gói từ `baseVersionNo`; sinh context-path theo số chính mới. Phát EVT-02-02 (`changedFields = versions`). Mã lỗi riêng: ERR-02-001, ERR-02-002, ERR-02-003, ERR-02-011, ERR-02-018, ERR-02-019, ERR-02-040.
:::

#### API-02-055 · So sánh hai phiên bản và phân loại thay đổi phá vỡ

::: dac-ta
**Mục đích.** So sánh hai phiên bản và phân loại thay đổi phá vỡ.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/version-diff`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-043.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `from` (query, VersionNo, bắt buộc); `to` (query, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDiff`; trường bắt buộc: `from`, `to`, `breaking`, `versionViolation`, `changes`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044.

**Ghi chú.** So theo cấu trúc hai đặc tả đã gộp; `breaking`, `versionViolation` (ERR-02-017 khi gửi duyệt), `suggestedVersion`, `uncertainCount`. p95 ≤ 3 giây (NFR-02-004). Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-035.
:::

#### API-02-056 · Phân tích tác động tới bên khai thác

::: dac-ta
**Mục đích.** Phân tích tác động tới bên khai thác.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/impact`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-044.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `againstVersionNo` (query, VersionNo, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImpactAnalysis`; trường bắt buộc: `summary`, `affected`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Chi tiết bên đăng ký chỉ cho SV của tổ chức chủ quản, CA, TA; người khác thấy số tổng. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-057 · Chuyển chủ quản API

::: dac-ta
**Mục đích.** Chuyển chủ quản API.

**Phương thức, đường dẫn.** `PUT /apis/{apiCode}/owner`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-045.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OwnerTransfer`; trường bắt buộc: `ownerOrgCode`, `providerSystemCode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Đổi `ownerOrgCode`, `providerSystemCode`; trả danh sách việc cần rà soát. Phát EVT-02-02. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-004, ERR-02-015.
:::

#### API-02-098 · Chi tiết một yêu cầu duyệt kèm điều kiện và lịch sử

::: dac-ta
**Mục đích.** Chi tiết một yêu cầu duyệt kèm điều kiện và lịch sử.

**Phương thức, đường dẫn.** `GET /review-requests/{reviewRequestId}`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-035, FR-02-047.

**Tham số.** `reviewRequestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewRequestDetail`; trường bắt buộc: `request`, `conditions`, `history`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** `conditions[]` là các điều kiện của loại yêu cầu và trạng thái đạt (cùng nguồn với ERR-02-012 `missing[]`); `history[]` gồm gửi, hỏi thêm, trả lời, quyết định. Trả `ETag` để dùng cho `If-Match` ở API-02-045, 046. Dùng cho UI-02-10. Mã lỗi riêng: ERR-02-001.
:::

### Phân loại, thẻ, dịch vụ sự kiện

#### API-02-008 · Đặt phân loại, thẻ và mức phân loại dữ liệu của API

::: dac-ta
**Mục đích.** Đặt phân loại, thẻ và mức phân loại dữ liệu của API.

**Phương thức, đường dẫn.** `PUT /apis/{apiCode}/classification`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-007.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ClassificationUpdate`; trường bắt buộc: `categoryCode`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApiDetail`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Phát EVT-02-02 (`changedFields = category, tags, dataClass`). Dữ liệu bí mật nhà nước bị chặn (ERR-02-016). Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-016.
:::

#### API-02-009 · Cây phân loại và thẻ

::: dac-ta
**Mục đích.** Cây phân loại và thẻ.

**Phương thức, đường dẫn.** `GET /categories`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-008.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CategoryTree`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Cây tối đa ba cấp kèm số API mỗi nhóm; thẻ tự do kèm số lần dùng.
:::

#### API-02-010 · Thêm nhóm phân loại

::: dac-ta
**Mục đích.** Thêm nhóm phân loại.

**Phương thức, đường dẫn.** `POST /categories`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CategoryCreate`; trường bắt buộc: `categoryCode`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Category`; trường bắt buộc: `categoryCode`, `name`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Mã lỗi riêng: ERR-02-002, ERR-02-003, ERR-02-040.
:::

#### API-02-011 · Sửa, đổi tên, di chuyển nhóm phân loại

::: dac-ta
**Mục đích.** Sửa, đổi tên, di chuyển nhóm phân loại.

**Phương thức, đường dẫn.** `PATCH /categories/{categoryCode}`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-008.

**Tham số.** `categoryCode` (path, CategoryCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CategoryUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Category`; trường bắt buộc: `categoryCode`, `name`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Đổi tên, đổi cha, đổi thứ tự không đổi `apiCode` hay context-path đã công bố. Mã lỗi riêng: ERR-02-001, ERR-02-002, ERR-02-003, ERR-02-015.
:::

#### API-02-012 · Xóa nhóm, chuyển API sang nhóm đích

::: dac-ta
**Mục đích.** Xóa nhóm, chuyển API sang nhóm đích.

**Phương thức, đường dẫn.** `DELETE /categories/{categoryCode}`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-008.

**Tham số.** `categoryCode` (path, CategoryCode, bắt buộc); `moveTo` (query, CategoryCode, tùy chọn); `dryRun` (query, boolean, tùy chọn); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; `200` thành công, `CategoryImpact`; trường bắt buộc: `affectedApis`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** `dryRun=true` trả `200` kèm số API bị ảnh hưởng, không ghi gì. Nhóm còn API bắt buộc có `moveTo`. Phát EVT-02-02 cho từng API đổi nhóm. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015.
:::

#### API-02-013 · Dịch vụ sự kiện (topic PH-10) trong danh mục

::: dac-ta
**Mục đích.** Dịch vụ sự kiện (topic PH-10) trong danh mục.

**Phương thức, đường dẫn.** `GET /event-services`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-009.

**Tham số.** `status` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EventServicePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Đọc từ PH-10 qua `GET /api/event/v1/topics` (`Ph10TopicClient`), bộ đệm làm mới theo EVT-10-01, 03, 04; PH-10 không khả dụng thì trả bộ đệm cũ kèm `stale = true`. Mã lỗi riêng: ERR-02-034.
:::

### Nội bộ cho PH-03, PH-04, PH-15

#### API-02-017 · PH-04 tự đăng ký hoặc cập nhật API từ luồng REST

::: dac-ta
**Mục đích.** PH-04 tự đăng ký hoặc cập nhật API từ luồng REST.

**Phương thức, đường dẫn.** `PUT /internal/flow-apis/{flowCode}`.

**Quyền.** Token dịch vụ, phạm vi catalog:flow-sync.

**FR hiện thực.** FR-02-013.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** application/json: `FlowApiUpsert`; trường bắt buộc: `workspaceCode`, `name`, `restOperations`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowApiResult`; trường bắt buộc: `apiCode`, `versionNo`, `flowSyncStatus`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Lũy đẳng theo `flowCode`. Tạo hoặc cập nhật API và phiên bản `DRAFT` với `origin = FLOW`; thiếu HTTT sở hữu thì `flowSyncStatus = PENDING_OWNER`. Phát EVT-02-01 hoặc EVT-02-02. Mã lỗi riêng: ERR-02-003, ERR-02-004.
:::

#### API-02-080 · Dữ liệu công bố cho PH-03

::: dac-ta
**Mục đích.** Dữ liệu công bố cho PH-03.

**Phương thức, đường dẫn.** `GET /internal/gateway/published-config`.

**Quyền.** Token dịch vụ, phạm vi catalog:gateway-read.

**FR hiện thực.** FR-02-059.

**Tham số.** `environment` (query, Environment, tùy chọn); `sinceConfigVersion` (query, integer, tùy chọn); `limit` (query, integer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublishedConfig`; trường bắt buộc: `environment`, `configVersion`, `sourceVersion`, `gap`, `apis`, `consumers`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** `Accept: application/x-ndjson` trả luồng dòng JSON. Có `sinceConfigVersion` thì trả thay đổi sau số đó; quá cũ trả `gap = true` để PH-03 lấy toàn bộ. Trả `ETag`, `X-DH-Source-Version`. Không chứa bí mật; consumer chỉ mang định danh và phạm vi.
:::

#### API-02-081 · Danh mục cho PH-15

::: dac-ta
**Mục đích.** Danh mục cho PH-15.

**Phương thức, đường dẫn.** `GET /internal/portal/catalog`.

**Quyền.** Token dịch vụ, phạm vi catalog:portal-read.

**FR hiện thực.** FR-02-004, FR-02-059.

**Tham số.** `updatedSince` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PortalCatalogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; `304` không đổi.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Chỉ mục có `portalPublished`; kèm `removed[]` là mã đã gỡ từ `updatedSince`, tệp đặc tả đã gộp tham chiếu. Phiên bản `SUSPENDED` vẫn nằm trong `versions[]` với `status = SUSPENDED` để cổng hiện nhãn tạm ngừng (Q15-19); cờ `portalPublished` được giữ nguyên.
:::

#### API-02-082 · PH-03 xác nhận đã nạp cấu hình

::: dac-ta
**Mục đích.** PH-03 xác nhận đã nạp cấu hình.

**Phương thức, đường dẫn.** `POST /internal/gateway/apply-acks`.

**Quyền.** Token dịch vụ, phạm vi catalog:gateway-ack.

**FR hiện thực.** FR-02-036, FR-02-059.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ApplyAck`; trường bắt buộc: `environment`, `sourceVersion`, `result`.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Lũy đẳng theo `(environment, configVersion)`; `result = FAILED` kèm `reason`. Chấp nhận số phiên bản nhảy vọt; báo lệch thì gọi lại API-02-080. Mã lỗi riêng: ERR-02-003.
:::

### Kiểm tra đặc tả và bộ luật

#### API-02-020 · Kết quả kiểm tra đặc tả của phiên bản

::: dac-ta
**Mục đích.** Kết quả kiểm tra đặc tả của phiên bản.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/lint-results`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-016, FR-02-017, FR-02-018.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `layer` (query, Layer, tùy chọn); `severity` (query, Severity, tùy chọn); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LintResult`; trường bắt buộc: `valid`, `summary`, `findings`, `checkedAt`, `specSha256`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Ba lớp `STANDARD`, `CONVENTION`, `SECRET`; phát hiện lớp `SECRET` chỉ che đuôi (`maskedTail`), không bao giờ trả giá trị đầy đủ. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-021 · Chạy lại kiểm tra đặc tả (có lưu kết quả)

::: dac-ta
**Mục đích.** Chạy lại kiểm tra đặc tả (có lưu kết quả).

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/lint-runs`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-016, FR-02-017, FR-02-018.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LintResult`; trường bắt buộc: `valid`, `summary`, `findings`, `checkedAt`, `specSha256`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `429` Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Đồng bộ, p95 ≤ 5 giây với đặc tả 5.000 dòng (NFR-02-003); quá giới hạn `02.lint.max-per-hour` trả ERR-02-036. Mã lỗi riêng: ERR-02-001, ERR-02-034, ERR-02-035, ERR-02-036.
:::

#### API-02-022 · Kiểm tra đặc tả không lưu (xem trước khi gõ)

::: dac-ta
**Mục đích.** Kiểm tra đặc tả không lưu (xem trước khi gõ).

**Phương thức, đường dẫn.** `POST /spec-lint`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-019.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `LintPreviewRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LintPreviewResult`; trường bắt buộc: `valid`, `canContinue`, `summary`, `findings`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `413` Đặc tả hoặc tệp vượt kích thước tối đa (ERR-02-009); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `429` Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`).

**Ghi chú.** Không ghi gì vào CSDL, không lưu nội dung. `Accept: application/sarif+json` trả SARIF 2.1.0 cho công cụ CI của nhà thầu. Giới hạn 60 lần mỗi giờ mỗi người. Mã lỗi riêng: ERR-02-003, ERR-02-005, ERR-02-009, ERR-02-036.
:::

#### API-02-023 · Phát hiện API trùng chức năng

::: dac-ta
**Mục đích.** Phát hiện API trùng chức năng.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/duplicates`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-020.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DuplicateList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Điểm tương đồng theo thao tác và lược đồ; ngưỡng `02.duplicate.threshold`. Chỉ gợi ý, không chặn gửi duyệt. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-024 · Bộ luật kiểm tra hiệu lực của tenant

::: dac-ta
**Mục đích.** Bộ luật kiểm tra hiệu lực của tenant.

**Phương thức, đường dẫn.** `GET /lint-rules`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-021.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `rulesetVersion`, `rules`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Mặc định nền tảng cộng điều chỉnh của tenant; mẫu quét bí mật chỉ đọc.
:::

#### API-02-025 · Điều chỉnh mức hoặc bật tắt luật quy ước của tenant

::: dac-ta
**Mục đích.** Điều chỉnh mức hoặc bật tắt luật quy ước của tenant.

**Phương thức, đường dẫn.** `PUT /lint-rules`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-021.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetUpdate`; trường bắt buộc: `reason`, `overrides`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `rulesetVersion`, `rules`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Tăng `rulesetVersion`; không hạ luật mức `ERROR` mặc định của nền tảng xuống dưới `WARNING`. Ghi kiểm toán luật, mức cũ, mức mới, lý do. Mã lỗi riêng: ERR-02-003, ERR-02-015, ERR-02-041.
:::

#### API-02-092 · Chấp nhận cảnh báo quy ước kèm lý do

::: dac-ta
**Mục đích.** Chấp nhận cảnh báo quy ước kèm lý do.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:acknowledge`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-017.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `findingId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Finding`; trường bắt buộc: `findingId`, `layer`, `severity`, `ruleId`, `location`, `message`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Luật mức `ERROR` không cho chấp nhận (ERR-02-011). Người duyệt thấy lý do ở UI-02-10. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-041.
:::

#### API-02-093 · Đề nghị đánh dấu không phải bí mật

::: dac-ta
**Mục đích.** Đề nghị đánh dấu không phải bí mật.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:dispute-secret`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-018.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `findingId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Finding`; trường bắt buộc: `findingId`, `layer`, `severity`, `ruleId`, `location`, `message`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044.

**Ghi chú.** Phát hiện giữ `OPEN` và đặt `disputeRequested = true`; vẫn chặn gửi duyệt cho tới khi SO xác nhận ở API-02-094. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-041.
:::

#### API-02-094 · Cán bộ ATTT xác nhận hoặc bác đề nghị không phải bí mật

::: dac-ta
**Mục đích.** Cán bộ ATTT xác nhận hoặc bác đề nghị không phải bí mật.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/lint-findings/{findingId}:confirm-dispute`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-018.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `findingId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DisputeDecision`; trường bắt buộc: `decision`, `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Finding`; trường bắt buộc: `findingId`, `layer`, `severity`, `ruleId`, `location`, `message`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044.

**Ghi chú.** Chỉ SO; người đề nghị không được tự xác nhận (ERR-02-013). Xác nhận thì phát hiện chuyển `ACKNOWLEDGED` cho đúng giá trị đó. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-013, ERR-02-041.
:::

### Backend, đường dẫn, khung route

#### API-02-026 · Danh sách backend của phiên bản

::: dac-ta
**Mục đích.** Danh sách backend của phiên bản.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/backends`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-022.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BackendList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Mã lỗi riêng: ERR-02-001.
:::

#### API-02-027 · Khai báo backend

::: dac-ta
**Mục đích.** Khai báo backend.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/backends`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-022.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BackendCreate`; trường bắt buộc: `backendCode`, `target`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Backend`; trường bắt buộc: `backendCode`, `kind`, `target`, `weight`, `status`; tiêu đề `Location`, `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Đích phải thuộc danh sách cho phép (kết nối PH-05 hoặc luồng PH-04); TLS ≥ 1.2; chặn địa chỉ nội bộ cấm. Trọng số mặc định 100; đánh dấu `configDirty`. Phiên bản `PUBLISHED`: tạo yêu cầu duyệt `BACKEND_CHANGE`, trả `202`. Mã lỗi riêng: ERR-02-002, ERR-02-003, ERR-02-011, ERR-02-020, ERR-02-038, ERR-02-040.
:::

#### API-02-028 · Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe

::: dac-ta
**Mục đích.** Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe.

**Phương thức, đường dẫn.** `PATCH /apis/{apiCode}/versions/{versionNo}/backends/{backendCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-023.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `backendCode` (path, BackendCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BackendUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Backend`; trường bắt buộc: `backendCode`, `kind`, `target`, `weight`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `423` Đang đóng băng thay đổi môi trường thật (ERR-02-039).

**Ghi chú.** `readTimeoutMs` không vượt `02.backend.max-timeout-ms`. Phiên bản `PUBLISHED`: tạo yêu cầu duyệt `BACKEND_CHANGE` và trả `202` (UC-02-11 A4); sau duyệt phát EVT-02-02 (`changedFields = backends`) và đẩy cấu hình qua saga công bố. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-020, ERR-02-038, ERR-02-039.
:::

#### API-02-029 · Xóa backend

::: dac-ta
**Mục đích.** Xóa backend.

**Phương thức, đường dẫn.** `DELETE /apis/{apiCode}/versions/{versionNo}/backends/{backendCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-022.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `backendCode` (path, BackendCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Không xóa được backend `ACTIVE` cuối cùng của phiên bản đã công bố (ERR-02-012). Phiên bản `PUBLISHED`: tạo yêu cầu duyệt `BACKEND_CHANGE`, trả `202`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-012, ERR-02-015, ERR-02-038.
:::

#### API-02-030 · Kiểm tra context-path có trùng hoặc xung đột

::: dac-ta
**Mục đích.** Kiểm tra context-path có trùng hoặc xung đột.

**Phương thức, đường dẫn.** `GET /context-paths:check`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-024.

**Tham số.** `contextPath` (query, string, bắt buộc); `apiCode` (query, ApiCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ContextPathCheck`; trường bắt buộc: `contextPath`, `available`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Chỉ kiểm tra, không giữ chỗ; giữ chỗ khi lưu bằng API-02-018 hoặc đăng ký bằng API-02-014 (khóa tư vấn theo tenant). Mã lỗi riêng: ERR-02-003.
:::

#### API-02-031 · Sức khỏe backend

::: dac-ta
**Mục đích.** Sức khỏe backend.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/backends/health`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-025.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BackendHealthReport`; trường bắt buộc: `overall`, `asOf`, `backends`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Ghép trạng thái từ PH-03 và PH-13 với cấu hình; PH-13 chậm thì `asOf` cũ và `overall = UNKNOWN`. Mã lỗi riêng: ERR-02-001, ERR-02-034.
:::

#### API-02-032 · Sinh khung route cho PH-04 từ đặc tả

::: dac-ta
**Mục đích.** Sinh khung route cho PH-04 từ đặc tả.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/flow-skeleton`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-026.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SkeletonRequest`; trường bắt buộc: `workspaceCode`, `flowCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OperationAccepted`; trường bắt buộc: `operationId`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Người gọi phải có quyền ở không gian làm việc PH-04. Kết quả (`flowCode`, `designerUrl`, `generatedRoutes`, `pendingFill`) lấy bằng API-02-095. Mã lỗi riêng: ERR-02-003, ERR-02-014, ERR-02-020, ERR-02-034, ERR-02-035, ERR-02-037.
:::

### Gói sử dụng

#### API-02-033 · Danh sách gói của phiên bản

::: dac-ta
**Mục đích.** Danh sách gói của phiên bản.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/plans`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-027.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlanList`; trường bắt buộc: `items`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Mã lỗi riêng: ERR-02-001.
:::

#### API-02-034 · Tạo gói sử dụng

::: dac-ta
**Mục đích.** Tạo gói sử dụng.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/plans`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-027.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlanCreate`; trường bắt buộc: `planCode`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Plan`; trường bắt buộc: `planCode`, `name`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Gói ở `STAGING`; chưa có kiểu xác thực và hạn mức cho tới API-02-036. Phát EVT-02-08. Mã lỗi riêng: ERR-02-002, ERR-02-003, ERR-02-011, ERR-02-038, ERR-02-040.
:::

#### API-02-035 · Sửa thông tin và điều kiện truy cập của gói

::: dac-ta
**Mục đích.** Sửa thông tin và điều kiện truy cập của gói.

**Phương thức, đường dẫn.** `PATCH /apis/{apiCode}/versions/{versionNo}/plans/{planCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-027.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlanUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Plan`; trường bắt buộc: `planCode`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Gói `PUBLISHED` chỉ sửa theo hướng tương thích (BR-02-017). Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-038.
:::

#### API-02-036 · Kiểu xác thực, hạn mức và đường dẫn cho phép của gói

::: dac-ta
**Mục đích.** Kiểu xác thực, hạn mức và đường dẫn cho phép của gói.

**Phương thức, đường dẫn.** `PUT /apis/{apiCode}/versions/{versionNo}/plans/{planCode}/access-policy`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-028, FR-02-029.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AccessPolicy`; trường bắt buộc: `authType`, `quota`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Plan`; trường bắt buộc: `planCode`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Kiểu xác thực tối thiểu theo `dataClass` (ERR-02-022); thao tác phải có trong đặc tả (ERR-02-037). Gói đã `PUBLISHED` phát EVT-02-08. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-022, ERR-02-023, ERR-02-037, ERR-02-038.
:::

#### API-02-037 · Gửi duyệt công bố gói

::: dac-ta
**Mục đích.** Gửi duyệt công bố gói.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-030.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmitRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Tạo yêu cầu duyệt `PLAN_PUBLISH`; duyệt bằng API-02-045 (bốn mắt). Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-012, ERR-02-015, ERR-02-021.
:::

#### API-02-038 · Đề nghị ngừng khuyến nghị gói

::: dac-ta
**Mục đích.** Đề nghị ngừng khuyến nghị gói.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit-deprecate`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-031.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlanDeprecateRequest`; trường bắt buộc: `sunsetAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Tạo yêu cầu duyệt `PLAN_DEPRECATE`; khi duyệt phát EVT-02-08 và thông báo EVT-02-12. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-031, ERR-02-032.
:::

#### API-02-039 · Đề nghị đóng gói

::: dac-ta
**Mục đích.** Đề nghị đóng gói.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/plans/{planCode}:submit-close`.

**Quyền.** `PERM-02-submit`.

**FR hiện thực.** FR-02-032.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Chỉ gói `DEPRECATED` không còn đăng ký hiệu lực; còn đăng ký trả ERR-02-024 kèm danh sách. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-024.
:::

#### API-02-040 · Sao chép gói từ phiên bản trước sang phiên bản này

::: dac-ta
**Mục đích.** Sao chép gói từ phiên bản trước sang phiên bản này.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/versions/{versionNo}/plans:copy-from`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-033.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlanCopyRequest`; trường bắt buộc: `fromVersionNo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PlanCopyResult`; trường bắt buộc: `plans`, `warnings`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Kiểm tra lại ràng buộc xác thực theo `dataClass` hiện hành; trả `warnings[]` theo từng gói. Gói mới ở `STAGING`. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-011, ERR-02-022, ERR-02-040.
:::

#### API-02-041 · Hủy gói nháp (xóa mềm)

::: dac-ta
**Mục đích.** Hủy gói nháp (xóa mềm).

**Phương thức, đường dẫn.** `DELETE /apis/{apiCode}/versions/{versionNo}/plans/{planCode}`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-032.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `planCode` (path, PlanCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Chỉ gói `STAGING` chưa từng công bố; giữ chỗ mã vĩnh viễn, không cần duyệt. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-024.
:::

#### API-02-096 · Danh sách gói sử dụng toàn tenant

::: dac-ta
**Mục đích.** Danh sách gói sử dụng toàn tenant.

**Phương thức, đường dẫn.** `GET /plans`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-027, FR-02-031.

**Tham số.** `apiCode` (query, ApiCode, tùy chọn); `status` (query, string, tùy chọn); `authType` (query, AuthType, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlanPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Mỗi dòng là một gói kèm API, phiên bản và `versionStatus`; `counts` đếm theo trạng thái gói. Chỉ trả gói của API người gọi được xem (BR-02-039). Dùng cho UI-02-06. Mã lỗi riêng: ERR-02-003.
:::

### Đăng ký sử dụng

#### API-02-058 · Gửi đăng ký sử dụng API cho HTTT

::: dac-ta
**Mục đích.** Gửi đăng ký sử dụng API cho HTTT.

**Phương thức, đường dẫn.** `POST /subscriptions`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-02-046.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionCreate`; trường bắt buộc: `apiCode`, `versionNo`, `planCode`, `systemCode`, `purpose`, `expectedVolume`, `acceptedTerms`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Gói có `autoApprove` và dữ liệu ≤ `02.subscription.auto-approve.max-class` thì `ACTIVE` ngay, ngược lại `PENDING` kèm `reviewRequestId`. Phát EVT-02-09. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-025, ERR-02-026, ERR-02-027, ERR-02-028, ERR-02-029.
:::

#### API-02-059 · Danh sách đăng ký sử dụng theo API hoặc theo HTTT

::: dac-ta
**Mục đích.** Danh sách đăng ký sử dụng theo API hoặc theo HTTT.

**Phương thức, đường dẫn.** `GET /subscriptions`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-049, FR-02-050.

**Tham số.** `apiCode` (query, ApiCode, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `status` (query, string, tùy chọn); `planCode` (query, PlanCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriptionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Phải có `apiCode` hoặc `systemCode`. Mặc định ẩn trạng thái cuối. Người không đủ quyền chi tiết chỉ thấy số tổng. Mã lỗi riêng: ERR-02-003.
:::

#### API-02-060 · HTTT mà người gọi được đăng ký hoặc xem

::: dac-ta
**Mục đích.** HTTT mà người gọi được đăng ký hoặc xem.

**Phương thức, đường dẫn.** `GET /subscriber-systems`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-049, FR-02-050.

**Tham số.** `scope` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriberSystemList`; trường bắt buộc: `items`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Tập HTTT thuộc tổ chức của người gọi; OR chỉ thấy HTTT của tổ chức mình.
:::

#### API-02-061 · Tạm ngừng đăng ký

::: dac-ta
**Mục đích.** Tạm ngừng đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:suspend`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-051.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Gỡ consumer khỏi gateway, giữ đăng ký và phạm vi; sang `SUSPENDED` khi gateway áp dụng. Phát EVT-02-11. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-033, ERR-02-041.
:::

#### API-02-062 · Tiếp tục đăng ký

::: dac-ta
**Mục đích.** Tiếp tục đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:resume`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-051.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Do SO tạm ngừng vì an ninh thì chỉ SO tiếp tục (BR-02-034). Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-014, ERR-02-015, ERR-02-033.
:::

#### API-02-063 · Thu hồi đăng ký

::: dac-ta
**Mục đích.** Thu hồi đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:revoke`.

**Quyền.** `PERM-02-approve-subscription`.

**FR hiện thực.** FR-02-051.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Gỡ consumer và yêu cầu PH-12 gỡ phạm vi khỏi client; trạng thái cuối `REVOKED`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-041.
:::

#### API-02-064 · Hủy đăng ký

::: dac-ta
**Mục đích.** Hủy đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:cancel`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-02-051.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** OR hủy đăng ký của HTTT tổ chức mình; `PENDING` hoặc `ACTIVE` sang `CANCELLED`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015.
:::

#### API-02-065 · Gia hạn đăng ký

::: dac-ta
**Mục đích.** Gia hạn đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:renew`.

**Quyền.** `PERM-02-subscribe`.

**FR hiện thực.** FR-02-052.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RenewRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ReviewAccepted`; trường bắt buộc: `reviewRequestId`, `kind`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).

**Ghi chú.** Dữ liệu từ `RESTRICTED` trở lên: `202` chờ SV, CA xác nhận bằng API-02-066. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-011, ERR-02-015, ERR-02-029.
:::

#### API-02-066 · Xác nhận rà soát định kỳ đăng ký

::: dac-ta
**Mục đích.** Xác nhận rà soát định kỳ đăng ký.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:confirm-review`.

**Quyền.** `PERM-02-approve-subscription`.

**FR hiện thực.** FR-02-052.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `apiCode`, `versionNo`, `planCode`, `systemCode`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Gia hạn `expiresAt` thêm một chu kỳ `02.subscription.review-months`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015.
:::

#### API-02-067 · Trạng thái cấp phạm vi của đăng ký

::: dac-ta
**Mục đích.** Trạng thái cấp phạm vi của đăng ký.

**Phương thức, đường dẫn.** `GET /subscriptions/{subscriptionId}/grant`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-048.

**Tham số.** `subscriptionId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GrantState`; trường bắt buộc: `subscriptionId`, `grantStatus`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** `grantStatus`: `PENDING`, `GRANTED`, `AWAITING_CREDENTIAL`, `FAILED`; kèm `scopes[]` và `failures[]`. Mã lỗi riêng: ERR-02-001.
:::

#### API-02-068 · Cấp lại phạm vi

::: dac-ta
**Mục đích.** Cấp lại phạm vi.

**Phương thức, đường dẫn.** `POST /subscriptions/{subscriptionId}:regrant`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-048.

**Tham số.** `subscriptionId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `GrantState`; trường bắt buộc: `subscriptionId`, `grantStatus`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Chạy lại từ bước gắn phạm vi ở PH-12; lũy đẳng theo `Idempotency-Key`. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-034.
:::

### Đồng bộ quốc gia

#### API-02-069 · Đồng bộ danh mục lên Nền tảng quốc gia ngay

::: dac-ta
**Mục đích.** Đồng bộ danh mục lên Nền tảng quốc gia ngay.

**Phương thức, đường dẫn.** `POST /national-sync/runs`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncRunRequest`; trường bắt buộc: `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRunAccepted`; trường bắt buộc: `syncRunId`, `operationId`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** `scope = ALL_PENDING` hoặc danh sách API. PH-14 chưa cấu hình thì bản ghi `NOT_CONFIGURED`, không lỗi. Phát EVT-02-14. Mã lỗi riêng: ERR-02-003, ERR-02-034, ERR-02-035, ERR-02-044.
:::

#### API-02-070 · Thẻ tổng trạng thái đồng bộ quốc gia

::: dac-ta
**Mục đích.** Thẻ tổng trạng thái đồng bộ quốc gia.

**Phương thức, đường dẫn.** `GET /national-sync/summary`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-054.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncSummary`; trường bắt buộc: `acked`, `queued`, `failed`, `rejected`, `overdue`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** `acked`, `queued`, `failed`, `rejected`, `overdue`, `lastSuccessAt`; cảnh báo tuân thủ khi quá `02.sync.overdue-days`.
:::

#### API-02-071 · Gửi lại một bản ghi đồng bộ

::: dac-ta
**Mục đích.** Gửi lại một bản ghi đồng bộ.

**Phương thức, đường dẫn.** `POST /national-sync/records/{syncId}:resend`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-053, FR-02-054.

**Tham số.** `syncId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRecord`; trường bắt buộc: `syncId`, `apiCode`, `action`, `status`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Tạo bản ghi `QUEUED` mới cho cùng API; bản cũ giữ làm lịch sử. Mã lỗi riêng: ERR-02-001, ERR-02-011, ERR-02-015, ERR-02-035, ERR-02-044.
:::

#### API-02-072 · Danh sách bản ghi đồng bộ quốc gia

::: dac-ta
**Mục đích.** Danh sách bản ghi đồng bộ quốc gia.

**Phương thức, đường dẫn.** `GET /national-sync/records`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-054.

**Tham số.** `status` (query, string, tùy chọn); `apiCode` (query, ApiCode, tùy chọn); `action` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRecordPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Mỗi bản ghi có `status`, `attempts`, `reason` (lý do từ chối của Nền tảng quốc gia), `nationalRef`. SV chỉ thấy API của tổ chức mình.
:::

### SLA, thông báo, thống kê

#### API-02-073 · Khai báo cam kết chất lượng dịch vụ (SLA)

::: dac-ta
**Mục đích.** Khai báo cam kết chất lượng dịch vụ (SLA).

**Phương thức, đường dẫn.** `PUT /apis/{apiCode}/versions/{versionNo}/sla`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-055.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SlaUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SlaCommitment`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).

**Ghi chú.** Cam kết kém đi có hiệu lực sau `02.sla.worsen-notice-days` và gửi thông báo bắt buộc `SLA_WORSENED`; phát EVT-02-02, EVT-02-12. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-015, ERR-02-041.
:::

#### API-02-074 · Cam kết SLA hiện hành và đang chờ hiệu lực

::: dac-ta
**Mục đích.** Cam kết SLA hiện hành và đang chờ hiệu lực.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/sla`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-055, FR-02-056.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SlaCommitment`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Mã lỗi riêng: ERR-02-001.
:::

#### API-02-075 · Đối chiếu SLA thực tế theo kỳ

::: dac-ta
**Mục đích.** Đối chiếu SLA thực tế theo kỳ.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/sla/periods`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-056.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `months` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SlaPeriods`; trường bắt buộc: `periods`, `asOf`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** `met` chỉ kết luận khi đủ `02.sla.min-days-data` ngày và `02.sla.min-calls` lượt; thiếu thì `status = INSUFFICIENT_DATA`. Mã lỗi riêng: ERR-02-001, ERR-02-003.
:::

#### API-02-076 · Gửi thông báo thay đổi cho bên khai thác

::: dac-ta
**Mục đích.** Gửi thông báo thay đổi cho bên khai thác.

**Phương thức, đường dẫn.** `POST /apis/{apiCode}/change-notices`.

**Quyền.** `PERM-02-create`.

**FR hiện thực.** FR-02-057.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NoticeCreate`; trường bắt buộc: `kind`, `title`, `body`, `audience`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `NoticeAccepted`; trường bắt buộc: `noticeId`, `recipients`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `429` Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`).

**Ghi chú.** Tối đa `02.notice.announcement-max-per-day` thông báo tay mỗi API mỗi ngày. Phát EVT-02-12. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-036.
:::

#### API-02-077 · Lịch sử thông báo thay đổi và bên nhận

::: dac-ta
**Mục đích.** Lịch sử thông báo thay đổi và bên nhận.

**Phương thức, đường dẫn.** `GET /change-notices`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-057.

**Tham số.** `apiCode` (query, ApiCode, tùy chọn); `kind` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `expand` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NoticePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** `expand=recipients` thêm danh sách bên nhận kèm trạng thái theo kênh.
:::

#### API-02-078 · Thống kê sử dụng theo phiên bản

::: dac-ta
**Mục đích.** Thống kê sử dụng theo phiên bản.

**Phương thức, đường dẫn.** `GET /apis/{apiCode}/versions/{versionNo}/usage-stats`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-058.

**Tham số.** `apiCode` (path, ApiCode, bắt buộc); `versionNo` (path, VersionNo, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `granularity` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageSeries`; trường bắt buộc: `series`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Chuỗi thời gian từ PH-13; chi tiết theo bên khai thác chỉ cho SV của tổ chức chủ quản, CA, TA. Mã lỗi riêng: ERR-02-001, ERR-02-003, ERR-02-034.
:::

#### API-02-079 · Thống kê cấp tenant

::: dac-ta
**Mục đích.** Thống kê cấp tenant.

**Phương thức, đường dẫn.** `GET /usage-stats/summary`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-058.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageSummary`; trường bắt buộc: `apisByStatus`, `totalCalls`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Số API theo trạng thái, tổng lượt gọi, API dùng nhiều nhất, tỷ lệ API đạt SLA; PH-16 đọc bằng token dịch vụ.
:::

#### API-02-097 · Tổng hợp tuân thủ SLA toàn tenant

::: dac-ta
**Mục đích.** Tổng hợp tuân thủ SLA toàn tenant.

**Phương thức, đường dẫn.** `GET /sla/summary`.

**Quyền.** `PERM-02-read`; hoặc token máy `catalog:metrics-read`.

**FR hiện thực.** FR-02-056.

**Tham số.** `months` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SlaSummary`; trường bắt buộc: `asOf`, `period`, `apisWithCommitment`, `breachedApis`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Kỳ gần nhất có đủ dữ liệu: số API có cam kết, tỷ lệ đạt, số API không đạt, API không đạt liên tiếp từ `02.sla.breach-periods` kỳ, nhóm theo mức phân loại. Dữ liệu thực tế lấy từ PH-13. Dùng cho UI-02-11. Mã lỗi riêng: ERR-02-003, ERR-02-034.
:::

### Đối soát cấu hình

#### API-02-083 · Kết quả đối soát cấu hình công bố với gateway gần nhất

::: dac-ta
**Mục đích.** Kết quả đối soát cấu hình công bố với gateway gần nhất.

**Phương thức, đường dẫn.** `GET /gateway-reconciliations/latest`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-060.

**Tham số.** `environment` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DriftReport`; trường bắt buộc: `environment`, `inSync`, `drifts`, `checkedAt`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Đối soát tự động mỗi 5 phút; `drifts[]` gồm `kind` (`MISSING`, `EXTRA`, `STALE`), `apiCode`, `versionNo`.
:::

#### API-02-084 · Chạy đối soát tay và đẩy lại cấu hình lệch

::: dac-ta
**Mục đích.** Chạy đối soát tay và đẩy lại cấu hình lệch.

**Phương thức, đường dẫn.** `POST /gateway-reconciliations`.

**Quyền.** `PERM-02-operate`.

**FR hiện thực.** FR-02-060.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OperationAccepted`; trường bắt buộc: `operationId`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044; `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** `repair = true` đẩy lại cấu hình, không bao giờ tự gỡ route thừa. Phát EVT-02-15 khi có lệch. Mã lỗi riêng: ERR-02-003, ERR-02-033, ERR-02-034, ERR-02-035.
:::

### Di trú từ APIM cũ

#### API-02-085 · Phân tích gói APIM cũ và xem trước

::: dac-ta
**Mục đích.** Phân tích gói APIM cũ và xem trước.

**Phương thức, đường dẫn.** `POST /legacy-imports`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-061.

**Tham số.** Không.

**Thân yêu cầu.** multipart/form-data: `LegacyImportUpload`; trường bắt buộc: `package`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportPreview`; trường bắt buộc: `importId`, `counts`, `items`, `issues`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `413` Đặc tả hoặc tệp vượt kích thước tối đa (ERR-02-009).

**Ghi chú.** Chỉ xem trước (tuân thủ FR-00-032), không ghi dữ liệu; kèm đề xuất ánh xạ mã và danh sách vấn đề phải xử lý. Mã lỗi riêng: ERR-02-003, ERR-02-009, ERR-02-045.
:::

#### API-02-086 · Xác nhận nhập API, gói, đăng ký từ APIM cũ

::: dac-ta
**Mục đích.** Xác nhận nhập API, gói, đăng ký từ APIM cũ.

**Phương thức, đường dẫn.** `POST /legacy-imports/{importId}:commit`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-061.

**Tham số.** `importId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ImportCommit`; trường bắt buộc: `acceptIssues`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ImportCommitResult`; trường bắt buộc: `importId`, `created`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001); `409` Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044.

**Ghi chú.** Ghi tất cả hoặc không cho từng API; nhập `LEGACY`, phát EVT-02-01 cho từng API tạo. Mã lỗi riêng: ERR-02-001, ERR-02-002, ERR-02-003, ERR-02-011, ERR-02-045.
:::

#### API-02-087 · Báo cáo đối chiếu sau nhập

::: dac-ta
**Mục đích.** Báo cáo đối chiếu sau nhập.

**Phương thức, đường dẫn.** `GET /legacy-imports/{importId}/report`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-061.

**Tham số.** `importId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportReport`; trường bắt buộc: `importId`, `source`, `imported`, `skipped`, `checksum`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Số API, gói, đăng ký ở nguồn và đã nhập, mục bỏ qua kèm lý do, tổng kiểm tra `checksum`. Mã lỗi riêng: ERR-02-001.
:::

### Tham số

#### API-02-088 · Tham số `02.*` của tenant

::: dac-ta
**Mục đích.** Tham số `02.*` của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-062.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).

**Ghi chú.** Mặc định, miền, giá trị hiệu lực, ý nghĩa (D02-03-PH02 §8.2).
:::

#### API-02-089 · Sửa tham số `02.*` (ghi qua PH-18)

::: dac-ta
**Mục đích.** Sửa tham số `02.*` (ghi qua PH-18).

**Phương thức, đường dẫn.** `PATCH /settings`.

**Quyền.** Quyền quản trị phân hệ (đề nghị, động từ admin).

**FR hiện thực.** FR-02-062.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingPatch`; trường bắt buộc: `values`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041); `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `412` Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015); `422` Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có); `503` Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.

**Ghi chú.** Hiệu lực trong 60 giây nhờ bộ đệm; trả `effectiveAt` và tác động ước tính. Tham số liên quan bảo mật sinh thông báo cho SO. Mã lỗi riêng: ERR-02-003, ERR-02-015, ERR-02-034, ERR-02-040, ERR-02-041.
:::

### Tác vụ bất đồng bộ

#### API-02-095 · Tiến độ và kết quả tác vụ bất đồng bộ

::: dac-ta
**Mục đích.** Tiến độ và kết quả tác vụ bất đồng bộ.

**Phương thức, đường dẫn.** `GET /operations/{operationId}`.

**Quyền.** `PERM-02-read`.

**FR hiện thực.** FR-02-012, FR-02-026, FR-02-053, FR-02-060.

**Tham số.** `operationId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OperationStatus`; trường bắt buộc: `operationId`, `kind`, `status`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn (ERR-02-014); `403` Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013); `404` Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).

**Ghi chú.** Dùng cho API-02-016, 032, 069, 084; chỉ người khởi tạo, TA, TO xem được. Kết quả giữ 7 ngày. Mã lỗi riêng: ERR-02-001.
:::

<!-- gen:dac-ta-api:end -->

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây nằm ngoài quyền sửa của tập này (tài liệu dùng chung hoặc tập khác của phân hệ); chuyển cho luồng hoặc đợt đồng bộ phụ trách.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 | Thêm quyền quản trị phân hệ với động từ `admin` của họ quyền PH-02 (đề nghị từ FRS §3.2) cho PA, TA; ghi rằng `PERM-02-create / update` được dùng cho xóa mềm API và gói |
| D03-03-PH02 (CSDL) | Xem Q02-61 của D03-03-PH02: `review_request.kind` và `status` lệch FRS và API, `lint_finding` thiếu cột đề nghị "không phải bí mật" (API-02-093, 094), `async_operation.kind` thiếu loại cho API-02-069, 084; ghi nơi lưu bộ đệm dịch vụ sự kiện (FR-02-009) vì chưa có bảng riêng |
| D05-02-PH02 (test case) | Đã có ca cho API-02-096, 097, 098 và EVT-02-16 ở lượt rà soát. Còn lại: sinh ca kiểm thử hợp đồng từ OpenAPI (mỗi operation một ca dương, một ca mỗi mã lỗi riêng) và ca "cùng khóa khác thân" cho mọi `POST` có `Idempotency-Key`, thực hiện bằng Schemathesis và Pact ở CI-5 (D04-02), không viết tay từng ca |
| D04-01 | Bổ sung quy ước hành động trên tập (`plans:copy-from`, `context-paths:check`) và phản hồi nhiều kiểu nội dung (`application/yaml`, `application/x-ndjson`, `application/sarif+json`); bộ luật Spectral dự án |
| D03-04-PH03 (khi viết) | Hợp đồng nhận API-02-080 (ndjson, `sinceConfigVersion`, `gap`) và gọi API-02-082 (`catalog:gateway-ack`); quy ước tên route `{apiCode}:v{major}:{operationId}` |
| D03-04-PH01, PH12, PH14, PH15, PH18 (khi viết) | PH-01: sự kiện tạm ngừng, thu hồi HTTT; PH-12: gắn, gỡ phạm vi `api:*` lũy đẳng; PH-14: `NationalCatalogPort`; PH-15: dùng API-02-081 và EVT-02-*; PH-18: tham số `02.*`, `NotificationApi` |
| Đề xuất ADR | Không tạo ADR trong tập này. Đề xuất (xem cùng đề xuất ở D03-02-PH02) ghi nhận quyết định "công bố có xác nhận từ cổng, hạn chế ghi ngay" làm ADR trong dải PH-07 và khác (050…059): `:publish` trả 202 khi chưa có xác nhận, trạng thái cuối chỉ ghi sau API-02-082 |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-API và quy chuẩn K-TRINH-BAY: 95 operation REST, 16 sự kiện phát và 6 sự kiện nhận, 45 mã lỗi, sơ đồ trình tự, ánh xạ hệ cũ, 5 câu hỏi mở |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: thêm API-02-096 (danh sách gói), 097 (tổng hợp SLA), 098 (chi tiết yêu cầu duyệt), nâng lên 98 operation; `Finding` có `line`, `column`; `OperationStatus` thêm `CANCELLED` và nêu loại tác vụ; thêm Q02-60, cập nhật Q02-55; sinh lại OpenAPI và các khối bảng |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: PH-02 nghe EVT-03, API-18-122 đóng băng, API-02-081 giữ SUSPENDED, API-02-097 thêm catalog:metrics-read |
