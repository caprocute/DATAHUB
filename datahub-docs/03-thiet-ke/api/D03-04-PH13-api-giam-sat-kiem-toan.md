---
ma_tai_lieu: D03-04-PH13
ten: Đặc tả API và sự kiện phân hệ PH-13 Giám sát và kiểm toán
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, giao diện, PH-16, PH-18, PH-20, kiểm thử viên, ATTT, hội đồng thẩm định
phan_he: PH-13
mo_ta: Đặc tả 90 endpoint REST ở ba nhóm quan sát, kiểm toán, vòng đời tenant, 14 sự kiện Kafka và 44 mã lỗi API của phân hệ Giám sát và kiểm toán, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm tra.
tai_lieu_lien_quan: D02-03-PH13 FRS; D02-04-PH13 Use case; D03-02-PH13 SDD; D03-03-PH13 CSDL; D03-07 ATTT; D04-01 Quy ước mã
---

# D03-04-PH13 · Đặc tả API và sự kiện Giám sát và kiểm toán

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chốt giao diện lập trình của PH-13 để người dùng, phân hệ khác và đơn vị triển khai (DU) làm việc với phân hệ giám sát và kiểm toán mà không phải đọc mã nguồn. PH-13 công bố 90 operation REST (API-13-001…090) ở ba đường gốc: `/api/observability/v1` (bảng điều khiển, log, trace, cảnh báo, an ninh, SIEM; 71 operation và một webhook nội bộ), `/api/audit/v1` (tra cứu, xác minh toàn vẹn, xuất bằng chứng; 16 operation) và `/api/platform/v1` (vòng đời tenant do PH-20 gọi; 2 operation). Phân hệ phát 14 sự kiện Kafka (EVT-13-01…14) và nhận hai topic vào (bản ghi kiểm toán, siêu dữ liệu lượt gọi API).

**Phạm vi.** Hợp đồng máy đọc được nằm ở hai tệp, và mọi bảng trong tài liệu này sinh từ chúng nên không lệch nhau:

- [`ph13/openapi-giam-sat-kiem-toan.yaml`](ph13/openapi-giam-sat-kiem-toan.yaml): OpenAPI 3.1, 129 lược đồ, đã qua `openapi-spec-validator`; 31 ví dụ đã kiểm khớp lược đồ bằng [`check_contracts.py`](ph13/tools/check_contracts.py).
- [`ph13/asyncapi-giam-sat-kiem-toan.yaml`](ph13/asyncapi-giam-sat-kiem-toan.yaml): AsyncAPI 3.0, 16 kênh (14 phát, 2 vào), đã qua `@asyncapi/parser` 3 không lỗi.

**Căn cứ.** FRS D02-03-PH13 §9.4 (danh mục API đã cấp mã), SDD D03-02-PH13 (thành phần và luồng), CSDL D03-03-PH13, D03-07 (SEC-60…67, SEC-85, SEC-87), NFR-00-027, NFR-00-028, NFR-00-062 và RFC 9457 cho thân lỗi.

**Những điểm hội đồng cần lưu ý.**

1. **Không có đường ghi, sửa, xóa bản ghi kiểm toán cho người dùng.** Mọi API ở `/api/audit/v1` dành cho người dùng chỉ đọc, xác minh hoặc xuất; đường ghi duy nhất là API-13-089 dành cho DU, dùng khi Kafka không với tới, lấy danh tính DU và tenant từ token chứ không từ thân yêu cầu. Kiểm tra hợp đồng chặn mọi `PUT`, `PATCH`, `DELETE` trên `/records`.
2. **Tra cứu nhạy cảm đòi lý do và xác thực lại phiên.** Tra nhật ký kiểm toán (API-13-074), xuất bằng chứng (API-13-082), kiểm tra toàn vẹn theo yêu cầu (API-13-077) và tinh chỉnh luật phát hiện (API-13-055) bắt buộc `reason` 10…500 ký tự và xác thực lại phiên; mỗi lượt tra tự ghi một bản ghi kiểm toán, và truy cập tenant khác chỉ qua phiên liên tenant có lý do (ERR-13-036).
3. **Không API nào trả bí mật.** Khóa ký webhook của kênh thông báo và chứng thư client của SIEM chỉ đi vào qua trường `writeOnly`, lưu ở OpenBao; kiểm tra hợp đồng chặn trường bí mật ngoài các lược đồ chỉ ghi.
4. **API cho phân hệ khác dùng token dịch vụ với scope riêng** (`obs:metrics-read` cho PH-16, `obs:diagnostics-read` cho PH-18, `obs:tenant-provision` cho PH-20, `audit:write` và `audit:history-read` cho DU), tách khỏi quyền người dùng `PERM-13-*`.
5. **Giữ nguyên đề xuất mã của FRS.** 90 mã API khớp bảng FRS §9.4; không thêm, không bỏ. Năm điểm còn mở hoặc lệch giữa các tài liệu được nêu ở mục 9 (Q13-55…59).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation REST | 90 (API-13-001…090) |
| Lược đồ OpenAPI | 129 |
| Sự kiện phát, topic vào | 14 (EVT-13-01…14), 2 |
| Mã lỗi API (control plane) | 44 (ERR-13-001…044), cộng 26 mã chạy nền (ERR-13-101…126) |
| Quyền người dùng, scope máy | 8 `PERM-13-*`, 6 scope |
| Câu hỏi mở | 5 (Q13-55…59) |

: Con số chính của tập API PH-13

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả giao diện lập trình của PH-13 gồm: 90 endpoint REST, các sự kiện Kafka, hợp đồng với phân hệ khác và bên ngoài, bảng mã lỗi ERR-13. Nguồn chuẩn là hai tệp máy đọc được; bảng danh mục ở chương 3, chương 4, chương 6 và chương 10 (đặc tả từng endpoint, mỗi endpoint một bảng 10 mục) đều sinh từ chúng.

### 0.2. Phạm vi

Tài liệu chỉ nói về giao diện của PH-13. Cách thực hiện bên trong (bộ ghi chuỗi, bộ neo, bộ phát hiện) ở D03-02-PH13; bảng dữ liệu ở D03-03-PH13; bố cục màn hình ở D03-06-PH13. Cổng API công bố cho HTTT thành viên là việc của PH-03; HTTT thành viên không gọi API này.

### 0.3. Người đọc

Mỗi nhóm người đọc cần một phần khác nhau của tài liệu; bảng dưới chỉ ra phần nào để không phải đọc toàn bộ.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-platform`, giao diện | Chương 1, 2, 3, 10 |
| Kỹ sư PH-16, PH-18, PH-20, DU nguồn | Chương 4, 5, và các endpoint dịch vụ ở chương 10 |
| Kiểm thử viên | Chương 6, 7, 10 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc

### 0.4. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung với [D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) §1.4 và D00-01. Các từ cần nhớ khi đọc tài liệu này:

| Thuật ngữ | Nghĩa |
|---|---|
| BFF | Lớp trung gian giữa trình duyệt và API; giữ token, trình duyệt không cầm token |
| Step-up | Yêu cầu người dùng xác thực lại phiên trước thao tác nhạy cảm (ERR-13-028) |
| Phiên liên tenant | Phiên có thời hạn và lý do, cho người dùng nền tảng truy cập dữ liệu tenant khác (FR-00-012) |
| Neo | Bản tóm tắt `{tenant, seq cuối, hash cuối}` ký bằng khóa OpenBao mỗi giờ |
| SSE | Server-Sent Events, luồng một chiều từ máy chủ tới trình duyệt |
| `allowedActions` | Danh sách hành động người gọi làm được ngay, để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm |

: Thuật ngữ dùng trong tài liệu API

### 0.5. Tài liệu tham chiếu

D02-03-PH13 (FRS), D02-04-PH13 (use case), D03-02-PH13 (SDD), D03-03-PH13 (CSDL), D03-06-PH13 (màn hình), D03-07 (SEC), D02-08 (quyền), D04-01 (quy ước API và mã), RFC 9457 (Problem Details), RFC 9470 (step-up), CloudEvents 1.0.

### 0.6. Cấu trúc tài liệu

Tài liệu gồm mười một chương theo thứ tự người dùng tài liệu cần tra, từ quy ước chung tới đặc tả từng endpoint.

| Chương | Nội dung |
|---|---|
| 1 | Quy ước chung: đường gốc, phiên bản, phân trang, lỗi, lý do, step-up |
| 2 | Xác thực và phân quyền theo bên gọi |
| 3 | Danh mục 90 endpoint và ví dụ yêu cầu, phản hồi |
| 4 | Danh mục sự kiện (14 phát, 2 vào) và hai sơ đồ trình tự |
| 5 | Hợp đồng với phân hệ khác và bên ngoài |
| 6 | Bảng mã lỗi ERR-13 |
| 7 | Kiểm tra hợp đồng trong CI |
| 8 | Ánh xạ từ hệ cũ và đề xuất SRS cũ |
| 9 | Câu hỏi mở |
| 10 | Đặc tả từng endpoint (sinh từ OpenAPI) |
| 11 | Đề nghị đồng bộ cho tài liệu khác |

: Cấu trúc chương của D03-04-PH13

## 1. Quy ước chung

Quy ước dưới đây áp cho cả ba nhóm đường gốc để người dùng giao diện và kỹ sư tích hợp gặp cùng một hành vi ở mọi API của PH-13. Quy ước theo D00-04 §4 và theo cách của PH-05, PH-19; chỗ khác biệt là phân trang (mục dưới) và các quy tắc về lý do, step-up, phiên liên tenant.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/observability/v1`, `/api/audit/v1`, `/api/platform/v1`; người dùng qua BFF console của tenant, PH-16, PH-18, PH-20, DU nguồn và Alertmanager qua dịch vụ trong cụm `dh-platform.dh-control.svc` |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng (oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1`) |
| Tenant | Lấy từ token (`tenant` claim), không bao giờ từ đường dẫn hay thân. Ngoại lệ có kiểm soát: người dùng nền tảng có phiên liên tenant đặt `targetTenant`; thiếu phiên trả ERR-13-036; tài khoản máy chỉ chạm tenant được cấp (ERR-13-044) |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:acknowledge`, `:resolve`, `:silence`, `:close`, `:test`, `:sync`) theo AIP-136; truy vấn có thân dùng `:search`, `:query` |
| Khóa lạc quan | `GET` trả `ETag`; `PATCH` và hành động đổi trạng thái bắt buộc `If-Match`; lệch trả ERR-13-007 (412). Thao tác chạy thử (`:test`), đồng bộ (`:sync`) và xóa truy vấn đã lưu không cần `If-Match`; `ETag` đúng bằng cột `version` của bảng; lỗi do CSDL chốt (`CHECK`, trigger) được ánh xạ sang ERR-13 theo D03-03-PH13 mục 4.4, và enum, độ dài, mẫu của DTO khớp `CHECK` ở chương 3 của tài liệu đó |
| Chống trùng | `POST` tạo mới bắt buộc `Idempotency-Key` (16…128 ký tự, lưu 24 giờ); cùng khóa khác nội dung trả ERR-13-037 (409). API-13-089 lũy đẳng theo `id` bản ghi nên không dùng khóa này |
| Phân trang danh sách | `page` (từ 1), `size` (mặc định 50, tối đa 200; vượt trả ERR-13-038); phản hồi `page` gồm `page`, `size`, `total`, `hasMore`; sắp xếp `sort=trường:asc\|desc` |
| Phân trang tra cứu lớn | Tra log, nhật ký truy cập API, nhật ký kiểm toán dùng con trỏ: `cursor`, `size`; phản hồi `page.next`, `page.hasMore`. Không trả tổng chính xác; kiểm toán trả `totalEstimate` (Q13-55) |
| Khoảng thời gian | Mọi lệnh tra log, trace, nhật ký truy cập API, kiểm toán bắt buộc `from`, `to` (ISO 8601 có múi giờ); thiếu hoặc `from` ≥ `to` trả ERR-13-004. Khoảng tối đa mỗi lần: log 7 ngày, nhật ký truy cập API 31 ngày, kiểm toán 31 ngày, thống kê theo endpoint 31 ngày (vượt trả ERR-13-005); kiểm toán quá 12 tháng trực tuyến trả ERR-13-029 |
| Giới hạn truy vấn | Mỗi người tối đa 5 truy vấn log, trace, kiểm toán đồng thời (ERR-13-011, 429, kèm `retryAfterSeconds`); mỗi truy vấn tối đa 30 giây (ERR-13-015, 504); cú pháp sai trả ERR-13-006 kèm vị trí. Các giới hạn là tham số `13.query.*` (FRS §8.3) |
| Lý do | Thao tác nhạy cảm bắt buộc `reason` 10…500 ký tự: tra kiểm toán (ERR-13-012), xuất bằng chứng, kiểm tra toàn vẹn theo yêu cầu, tinh chỉnh luật phát hiện, đổi tham số, đóng chuỗi (ERR-13-008) |
| Xác thực lại phiên | Thao tác nhạy cảm cần phiên được xác thực lại gần đây; thiếu trả ERR-13-028 (403) kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication"` theo RFC 9470 (Q13-57) |
| Lỗi | RFC 9457 `application/problem+json`, `code` = `ERR-13-nnn`, `traceId`; thêm `errors` (theo trường), `retryAfterSeconds`, `currentEtag`, `maxDays`, `recordCount` |
| Hành động được phép | Cảnh báo, cảnh báo an ninh, luật cảnh báo, yêu cầu xuất trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút (D03-06-PH13 §2) |
| Truy vết | `traceparent` W3C xuyên BFF → `dh-platform` → Kafka; phản hồi lỗi có `traceId` để người dùng sao chép (FR-00-080) |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` |
| Tiến trình dài | Đồng bộ dashboard, kiểm tra toàn vẹn theo yêu cầu, xuất bằng chứng trả 202 kèm `Location`; trạng thái đọc lại bằng `GET`, kết quả có sự kiện EVT-13-07, EVT-13-08 |
| Tải tệp | Gói bằng chứng `application/zip`, kèm `Content-Disposition` và `X-Evidence-Signature`; mỗi lượt tải ghi kiểm toán |
| Luồng SSE | `GET /logs:tail` trả `text/event-stream`, sự kiện `log`, `heartbeat` mỗi 15 giây, `closed`; tự đóng sau `13.live-tail.idle-minutes` (Q13-59) |
| Tenant tạm ngừng | Tenant ở trạng thái tạm ngừng chỉ đọc: mọi lệnh ghi cấu hình trả ERR-13-016 (423); ghi kiểm toán, tra cứu và xuất vẫn chạy |

: Quy ước chung của API PH-13

Thời gian trong thân dùng UTC có hậu tố `Z` hoặc độ lệch múi giờ; giao diện hiển thị theo `Asia/Ho_Chi_Minh` đến mili giây. Tên trường JSON dùng `camelCase`, giá trị liệt kê dùng chữ hoa với dấu gạch dưới. Mọi tên miền, mã tenant (`T68`) và dữ liệu trong ví dụ là giả lập.

## 2. Xác thực và phân quyền

PH-13 có ba loại bên gọi, mỗi loại một cách xác thực. Người dùng luôn qua BFF để token không ra trình duyệt; máy gọi máy dùng token dịch vụ có scope hẹp; Alertmanager dùng chứng thư client.

| Bên gọi | Luồng | Kiểm quyền |
|---|---|---|
| Người dùng console (PA, PO, TA, TO, SO, IE, IA, SV, VW, AU) | OIDC Authorization Code + PKCE qua BFF | `PERM-13-*` (D02-08) theo vai trò; OPA kiểm ở máy chủ |
| PH-16 (Báo cáo chỉ tiêu) | `client_credentials` + mTLS | Scope `obs:metrics-read`: API-13-067, 068 |
| PH-18 (Vận hành, xử lý lỗi) | `client_credentials` + mTLS | Scope `obs:diagnostics-read`: API-13-069 |
| PH-20 (Quản trị tenant) | Gọi trong tiến trình qua `TenantObservabilityApi` khi cùng DU; khi tách DU dùng `client_credentials` + mTLS | Scope `obs:tenant-provision`: API-13-072, 073 |
| DU nguồn (`dh-integration`, `dh-data`, `dh-connect`, `dh-payment`, `dh-assist`, `dh-runtime`) | `client_credentials` + `private_key_jwt` | Scope `audit:write`: API-13-089; BFF của DU dùng `audit:history-read`: API-13-076 |
| Phân hệ khác cần sức khỏe thành phần | `client_credentials` | Scope `obs:health-read`: API-13-002 |
| Alertmanager | mTLS, kiểm SPIFFE ID (SEC-15) | API-13-090; không kiểm quyền người dùng |

: Xác thực theo bên gọi

Quyền người dùng theo operation nằm ở cột "Quyền" của chương 3. Bảng sau gom số operation theo từng quyền để đối chiếu với ma trận D02-08 và FRS §3.2.

<!-- gen:perm-matrix:start -->
| Quyền hoặc scope | Số API | Mã API-13- |
|---|---|---|
| `PERM-13-dashboard` | 20 | 001, 002, 003, 004, 005, 006 … 031, 052, 053 |
| `PERM-13-alert-admin` | 12 | 036, 038, 039, 040, 041, 043, 044, 046, 047, 049, 050, 051 |
| `PERM-13-logs` | 11 | 019, 020, 021, 022, 023, 024, 025, 026, 027, 028, 029 |
| `PERM-13-audit-read` | 10 | 074, 075, 078, 079, 080, 081, 085, 086, 087, 088 |
| `PERM-13-security` | 9 | 054, 055, 056, 057, 058, 059, 060, 065, 066 |
| `PERM-13-admin` | 8 | 017, 018, 061, 062, 063, 064, 070, 071 |
| `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` | 5 | 035, 037, 042, 045, 048 |
| `PERM-13-audit-export` | 4 | 077, 082, 083, 084 |
| `PERM-13-alert-ack` | 3 | 032, 033, 034 |
| scope `obs:metrics-read` | 2 | 067, 068 |
| scope `obs:tenant-provision` | 2 | 072, 073 |
| scope `obs:diagnostics-read` | 1 | 069 |
| scope `audit:history-read` | 1 | 076 |
| scope `audit:write` | 1 | 089 |
| mTLS Alertmanager | 1 | 090 |

: Số operation theo quyền hoặc scope
<!-- gen:perm-matrix:end -->

Các quy tắc vượt quyền chức năng:

- **Tách nhiệm vụ.** Người có `PERM-13-alert-admin` (PA, PO, TA, TO) không có `PERM-13-audit-export`, nên không tự xuất bằng chứng về chính mình; AU chỉ có quyền đọc, xác minh, xuất. Không vai trò người nào có đường ghi vào bảng kiểm toán.
- **Chủ dịch vụ (SV)** chỉ thấy chỉ số của API và HTTT thuộc tổ chức mình ở API-13-009, 010; máy chủ lọc theo tổ chức của người gọi.
- **Người xem, lãnh đạo (VW)** chỉ có `PERM-13-dashboard`: không xem log, không xem kiểm toán.
- **Số bản ghi kiểm toán trong API-13-024** (liên kết theo `trace_id`) chỉ hiện khi người gọi có `PERM-13-audit-read`; thiếu quyền thì trường là `null`, không phải lỗi.
- **Tra kiểm toán và xuất bằng chứng** yêu cầu thêm lý do và step-up; hai thao tác này tự ghi `AUDIT.QUERY`, `AUDIT.EXPORT` vào chuỗi của tenant (FR-13-019), và khi qua phiên liên tenant ghi vào cả hai chuỗi.
- **API-13-089 và API-13-090 không có người dùng**: danh tính lấy từ chứng thư hoặc token máy; `tenant` lấy từ token (API-13-089) hoặc từ nhãn do Ruler đóng (API-13-090), không từ thân.

## 3. Danh mục endpoint

Mỗi operation một mã `API-13-nnn`, không dùng chung mã cho hai operation. Mã và thứ tự khớp FRS §9.4. Cột FR là số FR-13; tham số, lược đồ và mô tả lỗi theo từng operation ở OpenAPI và ở chương 10. Đường dẫn trong bảng tính từ tiền tố của nhóm ghi ở tiêu đề từng bảng.

<!-- gen:endpoints:start -->
**Bảng điều khiển** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-001 | `GET /overview` | Tổng quan nền tảng của tenant | 031 | `PERM-13-dashboard` |  | 200 |
| API-13-002 | `GET /components` | Sức khỏe các thành phần nền tảng | 031, 058 | `PERM-13-dashboard` hoặc scope `obs:health-read` |  | 200 |
| API-13-003 | `GET /deployments` | Danh sách đơn vị triển khai và tài nguyên | 032 | `PERM-13-dashboard` |  | 200 |
| API-13-004 | `GET /deployments/{deploymentCode}` | Chi tiết đơn vị triển khai | 032 | `PERM-13-dashboard` |  | 200 |
| API-13-005 | `GET /flows` | Bảng điều khiển các luồng | 033 | `PERM-13-dashboard` |  | 200 |
| API-13-006 | `GET /flows/{flowCode}/metrics` | Chỉ số một luồng | 033 | `PERM-13-dashboard` |  | 200 |
| API-13-007 | `GET /flows/{flowCode}/routes/{routeId}/metrics` | Chỉ số một route của luồng | 033 | `PERM-13-dashboard` |  | 200 |
| API-13-008 | `GET /endpoints/stats` | Thống kê theo endpoint | 034 | `PERM-13-dashboard` |  | 200 |
| API-13-009 | `GET /apis/stats` | Thống kê theo API | 035 | `PERM-13-dashboard` |  | 200 |
| API-13-010 | `GET /systems/{systemCode}/stats` | Thống kê theo HTTT | 035 | `PERM-13-dashboard` |  | 200 |
| API-13-011 | `GET /gateways` | Danh sách nút gateway | 036 | `PERM-13-dashboard` |  | 200 |
| API-13-012 | `GET /gateways/{nodeId}` | Chi tiết nút gateway | 036 | `PERM-13-dashboard` |  | 200 |
| API-13-013 | `GET /gateways/{nodeId}/resources` | Tài nguyên của nút gateway | 037 | `PERM-13-dashboard` |  | 200 |
| API-13-014 | `GET /kafka/cluster` | Bảng điều khiển cụm Kafka | 038 | `PERM-13-dashboard` |  | 200 |
| API-13-015 | `GET /dashboards/business` | Bảng điều khiển hoạt động nghiệp vụ | 039 | `PERM-13-dashboard` |  | 200 |
| API-13-016 | `GET /dashboards/security` | Bảng điều khiển an ninh | 040 | `PERM-13-dashboard` |  | 200 |
| API-13-017 | `GET /dashboard-sets` | Danh sách bộ dashboard chuẩn và trạng thái đồng bộ | 041 | `PERM-13-admin` |  | 200 |
| API-13-018 | `POST /dashboard-sets/{setCode}:sync` | Đồng bộ bộ dashboard sang Grafana của tenant | 041 | `PERM-13-admin` |  | 202 |

: Danh mục endpoint · Bảng điều khiển

**Log, trace, nhật ký truy cập API** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-019 | `POST /logs:search` | Tra log tập trung | 026 | `PERM-13-logs` |  | 200 |
| API-13-020 | `GET /logs/{logId}/context` | Ngữ cảnh quanh một dòng log | 027 | `PERM-13-logs` |  | 200 |
| API-13-021 | `GET /logs:tail` | Theo dõi log trực tiếp (SSE) | 027 | `PERM-13-logs` |  | 200 |
| API-13-022 | `GET /traces` | Tìm trace theo điều kiện | 028 | `PERM-13-logs` |  | 200 |
| API-13-023 | `GET /traces/{traceId}` | Chi tiết trace và biểu đồ thác nước | 028 | `PERM-13-logs` |  | 200 |
| API-13-024 | `GET /correlations/{traceId}` | Liên kết chỉ số, trace, log, kiểm toán theo trace_id | 029 | `PERM-13-logs` |  | 200 |
| API-13-025 | `POST /access-logs:search` | Tra nhật ký truy cập API | 030 | `PERM-13-logs` |  | 200 |
| API-13-026 | `GET /access-logs/{recordId}` | Chi tiết một lượt gọi API | 030 | `PERM-13-logs` |  | 200 |
| API-13-027 | `GET /saved-queries` | Truy vấn đã lưu của tôi và được chia sẻ | 026 | `PERM-13-logs` |  | 200 |
| API-13-028 | `POST /saved-queries` | Lưu một truy vấn | 026 | `PERM-13-logs` | có | 201 |
| API-13-029 | `DELETE /saved-queries/{queryId}` | Xóa truy vấn đã lưu | 026 | `PERM-13-logs` |  | 204 |

: Danh mục endpoint · Log, trace, nhật ký truy cập API

**Cảnh báo** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-030 | `GET /alerts` | Danh sách cảnh báo | 045, 046, 047 | `PERM-13-dashboard` |  | 200 |
| API-13-031 | `GET /alerts/{alertId}` | Chi tiết cảnh báo | 047 | `PERM-13-dashboard` |  | 200 |
| API-13-032 | `POST /alerts/{alertId}:acknowledge` | Xác nhận cảnh báo | 047 | `PERM-13-alert-ack` |  | 200 |
| API-13-033 | `POST /alerts/{alertId}:resolve` | Đánh dấu đã xử lý | 047 | `PERM-13-alert-ack` |  | 200 |
| API-13-034 | `POST /alerts/{alertId}:silence` | Tạm ẩn cảnh báo | 047 | `PERM-13-alert-ack` |  | 200 |
| API-13-052 | `GET /alert-stats` | Thống kê hiệu quả cảnh báo | 050 | `PERM-13-dashboard` |  | 200 |
| API-13-053 | `GET /monitoring-health` | Sức khỏe của chính hệ thống giám sát | 049 | `PERM-13-dashboard` |  | 200 |

: Danh mục endpoint · Cảnh báo

**Luật cảnh báo và runbook** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-035 | `GET /alert-rules` | Danh sách luật cảnh báo | 042, 043 | `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` |  | 200 |
| API-13-036 | `POST /alert-rules` | Tạo luật cảnh báo kèm runbook | 042 | `PERM-13-alert-admin` | có | 201 |
| API-13-037 | `GET /alert-rules/{ruleCode}` | Chi tiết luật cảnh báo | 042, 043 | `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` |  | 200 |
| API-13-038 | `PATCH /alert-rules/{ruleCode}` | Sửa luật cảnh báo | 042 | `PERM-13-alert-admin` |  | 200 |
| API-13-039 | `POST /alert-rules/{ruleCode}:test` | Chạy thử luật trên dữ liệu 24 giờ gần nhất | 042 | `PERM-13-alert-admin` |  | 200 |
| API-13-040 | `POST /alert-rules/{ruleCode}:disable` | Tắt luật cảnh báo | 042 | `PERM-13-alert-admin` |  | 200 |
| API-13-041 | `POST /alert-rules/{ruleCode}:enable` | Bật lại luật cảnh báo | 042 | `PERM-13-alert-admin` |  | 200 |
| API-13-042 | `GET /runbooks` | Danh sách runbook | 042 | `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` |  | 200 |
| API-13-043 | `POST /runbooks` | Tạo runbook | 042 | `PERM-13-alert-admin` | có | 201 |
| API-13-044 | `PATCH /runbooks/{runbookCode}` | Sửa runbook | 042 | `PERM-13-alert-admin` |  | 200 |

: Danh mục endpoint · Luật cảnh báo và runbook

**Lịch trực và kênh thông báo** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-045 | `GET /oncall-schedules` | Danh sách lịch trực | 048 | `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` |  | 200 |
| API-13-046 | `POST /oncall-schedules` | Tạo lịch trực | 048 | `PERM-13-alert-admin` | có | 201 |
| API-13-047 | `PATCH /oncall-schedules/{scheduleCode}` | Sửa lịch trực | 048 | `PERM-13-alert-admin` |  | 200 |
| API-13-048 | `GET /notification-channels` | Danh sách kênh thông báo | 048 | `PERM-13-alert-admin` hoặc `PERM-13-alert-ack` |  | 200 |
| API-13-049 | `POST /notification-channels` | Tạo kênh thông báo | 048 | `PERM-13-alert-admin` | có | 201 |
| API-13-050 | `PATCH /notification-channels/{channelCode}` | Sửa kênh thông báo | 048 | `PERM-13-alert-admin` |  | 200 |
| API-13-051 | `POST /notification-channels/{channelCode}:test` | Gửi thử qua kênh thông báo | 048 | `PERM-13-alert-admin` |  | 200 |

: Danh mục endpoint · Lịch trực và kênh thông báo

**An ninh, SIEM và báo cáo sự cố** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-054 | `GET /detection-rules` | Danh sách luật phát hiện UC-SEC | 051 | `PERM-13-security` |  | 200 |
| API-13-055 | `PATCH /detection-rules/{ruleCode}` | Tinh chỉnh ngưỡng luật phát hiện | 051 | `PERM-13-security` |  | 200 |
| API-13-056 | `GET /security-alerts` | Danh sách cảnh báo an ninh | 052, 053 | `PERM-13-security` |  | 200 |
| API-13-057 | `GET /security-alerts/{alertId}` | Chi tiết cảnh báo an ninh | 053 | `PERM-13-security` |  | 200 |
| API-13-058 | `POST /security-alerts/{alertId}:acknowledge` | Tiếp nhận cảnh báo an ninh | 053 | `PERM-13-security` |  | 200 |
| API-13-059 | `POST /security-alerts/{alertId}:close` | Đóng cảnh báo an ninh kèm kết luận | 053 | `PERM-13-security` |  | 200 |
| API-13-060 | `POST /security-alerts/{alertId}:propose-suspension` | Đề xuất tạm ngừng HTTT | 053 | `PERM-13-security` |  | 200 |
| API-13-061 | `GET /siem-targets` | Danh sách mục tiêu SIEM | 054 | `PERM-13-admin` |  | 200 |
| API-13-062 | `POST /siem-targets` | Tạo mục tiêu SIEM | 054 | `PERM-13-admin` | có | 201 |
| API-13-063 | `PATCH /siem-targets/{targetCode}` | Sửa mục tiêu SIEM | 054 | `PERM-13-admin` |  | 200 |
| API-13-064 | `POST /siem-targets/{targetCode}:test` | Gửi thử tới mục tiêu SIEM | 054 | `PERM-13-admin` |  | 200 |
| API-13-065 | `POST /incident-reports:generate` | Sinh báo cáo sự cố từ cảnh báo an ninh | 055 | `PERM-13-security` | có | 201 |
| API-13-066 | `GET /incident-reports/{reportId}` | Chi tiết báo cáo sự cố | 055 | `PERM-13-security` |  | 200 |

: Danh mục endpoint · An ninh, SIEM và báo cáo sự cố

**Dịch vụ cho phân hệ khác** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-067 | `POST /metrics:query` | Truy vấn số liệu tổng hợp cho PH-16 | 056 | scope `obs:metrics-read` |  | 200 |
| API-13-068 | `GET /metrics/summary` | Tóm tắt số liệu theo kỳ cho PH-16 | 056 | scope `obs:metrics-read` |  | 200 |
| API-13-069 | `GET /diagnostics/{traceId}` | Ngữ cảnh chẩn đoán theo trace_id cho PH-18 | 057 | scope `obs:diagnostics-read` |  | 200 |

: Danh mục endpoint · Dịch vụ cho phân hệ khác

**Tham số quan sát** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-070 | `GET /settings` | Tham số quan sát 13.* của tenant | 008, 061 | `PERM-13-admin` |  | 200 |
| API-13-071 | `PATCH /settings` | Sửa tham số, hạn mức, kiểm tra tổng hợp | 008, 061 | `PERM-13-admin` |  | 200 |

: Danh mục endpoint · Tham số quan sát

**Vòng đời tenant** (`/api/platform/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-072 | `POST /tenants/{tenantCode}/observability:provision` | Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới | 059 | scope `obs:tenant-provision` | có | 200 |
| API-13-073 | `POST /tenants/{tenantCode}/audit-chain:close` | Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập | 060 | scope `obs:tenant-provision` | có | 200 |

: Danh mục endpoint · Vòng đời tenant

**Tra cứu nhật ký kiểm toán** (`/api/audit/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-074 | `POST /records:search` | Tra cứu nhật ký kiểm toán | 020, 023 | `PERM-13-audit-read` |  | 200 |
| API-13-075 | `GET /records/{auditId}` | Chi tiết bản ghi kiểm toán và xác minh băm | 021 | `PERM-13-audit-read` |  | 200 |
| API-13-076 | `GET /objects/{objectType}/{objectId}/history` | Lịch sử theo đối tượng cho tab Lịch sử | 022 | scope `audit:history-read` |  | 200 |
| API-13-085 | `GET /cross-tenant-access` | Báo cáo truy cập liên tenant | 025 | `PERM-13-audit-read` |  | 200 |

: Danh mục endpoint · Tra cứu nhật ký kiểm toán

**Toàn vẹn, neo và đối chiếu** (`/api/audit/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-077 | `POST /verifications` | Yêu cầu kiểm tra toàn vẹn chuỗi theo yêu cầu | 014 | `PERM-13-audit-export` | có | 202 |
| API-13-078 | `GET /verifications` | Danh sách lượt kiểm tra toàn vẹn | 014 | `PERM-13-audit-read` |  | 200 |
| API-13-079 | `GET /verifications/{verificationId}` | Kết quả một lượt kiểm tra toàn vẹn | 014, 015 | `PERM-13-audit-read` |  | 200 |
| API-13-080 | `GET /anchors` | Danh sách neo băm | 012, 021 | `PERM-13-audit-read` |  | 200 |
| API-13-081 | `GET /anchors/{anchorId}` | Chi tiết neo băm | 012 | `PERM-13-audit-read` |  | 200 |
| API-13-086 | `GET /reconciliations` | Kết quả đối chiếu số bản ghi theo DU | 017 | `PERM-13-audit-read` |  | 200 |
| API-13-087 | `GET /chain-status` | Trạng thái chuỗi kiểm toán của tenant | 011, 013, 016 | `PERM-13-audit-read` |  | 200 |
| API-13-088 | `GET /partitions` | Danh sách phân vùng kiểm toán | 018 | `PERM-13-audit-read` |  | 200 |

: Danh mục endpoint · Toàn vẹn, neo và đối chiếu

**Xuất bằng chứng** (`/api/audit/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-082 | `POST /exports` | Yêu cầu xuất bằng chứng kiểm toán ký số | 024 | `PERM-13-audit-export` | có | 202 |
| API-13-083 | `GET /exports/{exportId}` | Trạng thái yêu cầu xuất bằng chứng | 024 | `PERM-13-audit-export` |  | 200 |
| API-13-084 | `GET /exports/{exportId}/download` | Tải gói bằng chứng | 024 | `PERM-13-audit-export` |  | 200 |

: Danh mục endpoint · Xuất bằng chứng

**Nội bộ (DU nguồn)** (`/api/audit/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-089 | `POST /internal/records:batch` | Ghi lô bản ghi kiểm toán dự phòng | 010, 016 | scope `audit:write` |  | 202 |

: Danh mục endpoint · Nội bộ (DU nguồn)

**Nội bộ (Alertmanager)** (`/api/observability/v1`)

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-13-090 | `POST /internal/alertmanager:webhook` | Nhận cảnh báo từ Alertmanager | 044 | mTLS Alertmanager |  | 200 |

: Danh mục endpoint · Nội bộ (Alertmanager)
<!-- gen:endpoints:end -->

### 3.1. Ví dụ yêu cầu và phản hồi

Ví dụ dưới là giả lập, tenant T68. Các thân yêu cầu cũng nằm trong `examples` của lược đồ ở OpenAPI và được kiểm khớp lược đồ ở CI.

**API-13-074 Tra cứu nhật ký kiểm toán** (cần lý do và phiên vừa xác thực lại)

```http
POST /api/audit/v1/records:search?size=50
Content-Type: application/json

{"from": "2026-11-01T00:00:00Z", "to": "2026-11-26T00:00:00Z",
 "reason": "Kiểm tra thao tác công bố danh mục theo đề nghị thanh tra số 15/TTr",
 "action": "CATALOG.PUBLISH", "outcome": "SUCCESS"}
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0192f3a4-7b1c-7d2e-9a10-5c3e8f1b2a44", "tenantId": "T68", "seq": 1204551,
  "occurredAt": "2026-11-26T03:15:00Z", "recordedAt": "2026-11-26T03:15:01Z", "actorType": "USER",
  "actorId": "u-an.nv", "actorName": "Nguyễn Văn An", "action": "CATALOG.PUBLISH", "objectType": "catalog",
  "objectId": "DM_GIOI_TINH", "outcome": "SUCCESS", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "sourceDu": "dh-data", "prevHash": "…64 ký tự…", "hash": "…64 ký tự…"}],
 "page": {"next": "eyJzZXEiOjEyMDQ1NTF9", "hasMore": true}, "totalEstimate": 37, "queryId": "0192f3b0-3333-7000-8000-000000000003"}
```

Thiếu `reason` trả ERR-13-012 (422); chưa xác thực lại phiên trả ERR-13-028 (403); khoảng quá 31 ngày trả ERR-13-005 (422, kèm `maxDays: 31`); quá 1.000.000 bản ghi ước lượng trả ERR-13-013 (422, kèm `recordCount`).

**API-13-082 Yêu cầu xuất bằng chứng** (chạy nền)

```http
POST /api/audit/v1/exports
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10
Content-Type: application/json

{"from": "2026-10-01T00:00:00Z", "to": "2026-10-31T23:59:59Z", "filter": {"action": "PII.REVEAL"},
 "reason": "Cung cấp bằng chứng cho đoàn thanh tra Sở TT&TT", "basis": "INSPECTION", "basisRef": "QĐ-TT-0456"}
```

```http
HTTP/1.1 202 Accepted
Location: /api/audit/v1/exports/0192f3b0-1111-7000-8000-000000000001

{"exportId": "0192f3b0-1111-7000-8000-000000000001", "status": "REQUESTED", "requestedBy": "u-tran.tt",
 "requestedAt": "2026-11-26T03:10:00Z", "allowedActions": []}
```

Khi gói sẵn sàng, `GET /exports/{exportId}` trả `status: READY` kèm `recordCount`, `fileHash`, `signature`, `expiresAt` (7 ngày) và API-13-084 tải được trong thời hạn liên kết `13.export.link-ttl-minutes`.

**API-13-033 Đánh dấu cảnh báo đã xử lý**

```http
POST /api/observability/v1/alerts/0192f3b0-2222-7000-8000-000000000002:resolve
If-Match: W/"3"
Content-Type: application/json

{"cause": "Chứng thư mTLS của HTTT QLVB hết hạn", "measure": "Gia hạn chứng thư ở PH-01, tải lại cấu hình route", "outcome": "FIXED"}
```

```http
HTTP/1.1 200 OK
ETag: W/"4"

{"alertId": "0192f3b0-2222-7000-8000-000000000002", "ruleCode": "api-loi-5xx-qlvb", "severity": "CRITICAL",
 "status": "RESOLVED", "resolution": "MANUAL", "startedAt": "2026-11-26T03:10:00Z", "endedAt": "2026-11-26T03:42:00Z",
 "allowedActions": []}
```

Thiếu `cause` hoặc `measure` trả ERR-13-022 (422); cảnh báo đã `RESOLVED` trả ERR-13-020 (409) kèm `disabledReasons` ở lần đọc kế tiếp.

**API-13-019 Tra log tập trung**

```http
POST /api/observability/v1/logs:search?size=100
Content-Type: application/json

{"query": "{du=\"dh-integration\"} |= \"ERR-04-101\"", "from": "2026-11-26T01:00:00Z", "to": "2026-11-26T02:00:00Z",
 "limit": 200, "direction": "BACKWARD", "level": "ERROR"}
```

```http
HTTP/1.1 200 OK

{"lines": [{"id": "loki-1795663200000-8812", "ts": "2026-11-26T01:57:12.431Z", "level": "ERROR", "du": "dh-integration",
  "service": "flow-runner", "message": "Luồng ho-so-cu-tru gọi API đích quá thời gian chờ",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}],
 "stats": {"matched": 1, "scannedBytes": 3145728, "durationMs": 412}, "truncated": false, "page": {"next": null, "hasMore": false}}
```

**API-13-089 Ghi lô bản ghi kiểm toán dự phòng** (DU gọi khi Kafka không với tới)

```http
POST /api/audit/v1/internal/records:batch
Authorization: Bearer <token dịch vụ, scope audit:write>
Content-Type: application/json

{"records": [{"id": "0192f3a4-7b1c-7d2e-9a10-5c3e8f1b2a44", "occurredAt": "2026-11-26T03:15:00Z", "actorType": "USER",
  "actorId": "u-an.nv", "actorName": "Nguyễn Văn An", "action": "CATALOG.PUBLISH", "objectType": "catalog",
  "objectId": "DM_GIOI_TINH", "outcome": "SUCCESS", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}]}
```

```http
HTTP/1.1 202 Accepted

{"accepted": 1, "duplicate": 0, "quarantined": []}
```

Phản hồi 202 chỉ sau khi lô đã cam kết vào chuỗi (không hứa hẹn bất đồng bộ). Bản ghi trùng `id` đếm vào `duplicate`; bản ghi lỗi (thiếu trường, chứa giá trị Nhạy cảm chưa che, đồng hồ lệch) vào `quarantined` kèm mã ERR-13-101, 105, 126.

**Phản hồi lỗi** (RFC 9457)

```json
{"type": "https://datahub.gov.vn/errors/ERR-13-005", "title": "Khoảng thời gian vượt giới hạn", "status": 422,
 "code": "ERR-13-005", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "detail": "Khoảng thời gian tối đa cho loại dữ liệu này là 31 ngày mỗi lần tra. Hãy thu hẹp khoảng.", "maxDays": 31}
```

## 4. Danh mục sự kiện

PH-13 phát 14 sự kiện (EVT-13-01…14) và nhận hai topic vào không đánh mã EVT-13. Topic theo `{tenant}.obs.{thực-thể}.{sự-kiện}.v1` chữ thường (D00-04 §4); tenant `PLATFORM` dùng tiền tố `platform`. Lược đồ ở [`asyncapi-giam-sat-kiem-toan.yaml`](ph13/asyncapi-giam-sat-kiem-toan.yaml), đăng ký ở Apicurio chế độ BACKWARD. Cột "Giữ" của sự kiện an ninh và kiểm toán dài hơn mặc định 7 ngày vì bộ xuất SIEM có thể ngừng và cần đọc lại (giả định, cơ sở: hàng đợi đĩa của bộ xuất giữ tối đa 1.024 MB theo `13.siem.queue-max-mb`, tương đương vài ngày ở mức bản ghi giả định).

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Giữ | Người nhận |
|---|---|---|---|---|---|
| EVT-13-01 | `{tenant}.obs.alert.fired.v1` | Cảnh báo sang `FIRING` (FR-13-044). | `alertId` | 7 ngày | PH-18, trung tâm thông báo |
| EVT-13-02 | `{tenant}.obs.alert.resolved.v1` | Cảnh báo sang `RESOLVED`, tự động hoặc thủ công (FR-13-044, 047). | `alertId` | 7 ngày | PH-18, trung tâm thông báo |
| EVT-13-03 | `{tenant}.obs.alert.escalated.v1` | Cảnh báo leo thang lên cấp mới hoặc hết cấp (FR-13-046). | `alertId` | 7 ngày | PH-18 |
| EVT-13-04 | `{tenant}.obs.security-alert.raised.v1` | Cảnh báo an ninh phát hiện, hoặc đề xuất tạm ngừng HTTT (FR-13-052, 053). | `alertId` | 30 ngày | PH-01 (đề xuất), PH-18, bộ xuất SIEM |
| EVT-13-05 | `{tenant}.obs.audit.chain-broken.v1` | Phát hiện đứt chuỗi kiểm toán hoặc neo không khớp (FR-13-015). | `tenantId` | 30 ngày | PH-18, bộ xuất SIEM |
| EVT-13-06 | `{tenant}.obs.audit.anchor-created.v1` | Neo băm mới được ký (FR-13-012). | `anchorId` | 7 ngày | Bộ xuất SIEM |
| EVT-13-07 | `{tenant}.obs.audit.verification-completed.v1` | Kiểm tra toàn vẹn xong (FR-13-014). | `verificationId` | 7 ngày | PH-18, UI-13-14 |
| EVT-13-08 | `{tenant}.obs.audit.export-ready.v1` | Gói bằng chứng sẵn sàng tải (FR-13-024). | `exportId` | 7 ngày | Trung tâm thông báo của người yêu cầu |
| EVT-13-09 | `{tenant}.obs.audit.reconciliation-mismatch.v1` | Đối chiếu số bản ghi theo DU lệch (FR-13-017). | `duCode` | 7 ngày | PH-18, DU nguồn |
| EVT-13-10 | `{tenant}.obs.rule.changed.v1` | Luật cảnh báo, luật phát hiện, luật chuẩn hoặc tham số đổi (FR-13-042, 043, 051, 061). | `ruleCode` | 7 ngày | Module `observability` (nạp Ruler), PH-18 |
| EVT-13-11 | `{tenant}.obs.audit.partition-archived.v1` | Phân vùng kiểm toán được lưu trữ (FR-13-018). | `month` | 7 ngày | PH-18 |
| EVT-13-12 | `{tenant}.obs.audit.cross-tenant-access.v1` | Mở phiên truy cập liên tenant (FR-13-025). Phát vào tenant bị truy cập. | `sessionId` | 30 ngày | Trung tâm thông báo của quản trị tỉnh bị truy cập, bộ xuất SIEM |
| EVT-13-13 | `{tenant}.obs.probe.failed.v1` | Kiểm tra tổng hợp thất bại liên tiếp (FR-13-008). | `probeCode` | 7 ngày | PH-18 |
| EVT-13-14 | `{tenant}.obs.capacity.warning.v1` | Số chuỗi hoặc dung lượng kho đạt 85% (FR-13-007, 061). | `resource` | 7 ngày | PH-20, PH-18 |
| Vào | `{tenant}.obs.audit.recorded.v1` | Bản ghi kiểm toán từ `dh-audit` của mọi DU (FR-13-010). Tenant `PLATFORM` dùng `platform.obs.audit.recorded.v1`. | `id` (UUID v7) | 7 ngày | PH-13 (người phát: `dh-audit` của DU nguồn) |
| Vào | `{tenant}.obs.access.logged.v1` | Siêu dữ liệu lượt gọi từ plugin `kafka-logger` của APISIX (FR-13-006). | `route` | 3 ngày | PH-13 (người phát: APISIX (PH-03)) |

: Danh mục sự kiện của PH-13
<!-- gen:events:end -->

Sự kiện phát đi theo bốn quy tắc:

1. **Ghi qua hộp thư đi (outbox).** Sự kiện ghi vào bảng `outbox` của `dh-platform` cùng giao dịch với thay đổi trạng thái, Debezium đưa lên Kafka, dạng CloudEvents 1.0 chế độ nhị phân (`ce_type = vn.datahub.obs.alert.fired.v1`, `ce_subject` = khóa phân vùng). Không mất sự kiện khi tiến trình dừng giữa chừng.
2. **Không mang bằng chứng.** Sự kiện chỉ chứa mã, mức độ và thời điểm; người nhận đọc chi tiết qua API bằng quyền của mình. Không sự kiện nào chứa giá trị Nhạy cảm, bằng chứng kiểm toán hay bí mật.
3. **Người nhận lũy đẳng.** Cùng `ce_id` đến hai lần thì xử lý một lần; sự kiện đổi trạng thái (EVT-13-01, 02, 03) mang thời điểm để bỏ bản cũ đến muộn.
4. **Chỉ thêm, không đổi.** Trong `v1` chỉ được thêm trường tùy chọn; đổi nghĩa hoặc xóa trường sang `v2`, chạy song song.

Hai topic vào không có mã EVT-13 vì PH-13 là bên nhận:

| Topic vào | Người phát | Tiêu đề bắt buộc | Xử lý ở PH-13 |
|---|---|---|---|
| `{tenant}.obs.audit.recorded.v1` | `dh-audit` của DU nguồn | `dh-du`, `dh-kid`, `dh-mac` (HMAC-SHA256 của khóa nguồn DU trên `tenant ‖ id ‖ SHA-256(payload)`) | Kiểm chữ ký và `audit_source_grant`, kiểm lược đồ `audit-event.v1`, gán `seq`, `prev_hash`, `hash`, cam kết rồi mới xác nhận offset (FR-13-010, 011). Bản lỗi vào bảng cách ly với ERR-13-101…105, 126 |
| `{tenant}.obs.access.logged.v1` | APISIX, plugin `kafka-logger` | Không | ClickHouse đọc bằng bảng động cơ Kafka, chỉ nhận dòng có `tenant_id` khớp tiền tố topic; dòng khác vào bảng từ chối và đếm (ERR-13-104) (FR-13-006) |

: Hai topic vào của PH-13

Ví dụ EVT-13-01 (thân sự kiện, sau khi bỏ tiêu đề CloudEvents):

```json
{"tenantId": "T68", "alertId": "0192f3b0-2222-7000-8000-000000000002", "ruleCode": "api-loi-5xx-qlvb",
 "name": "Tỷ lệ lỗi 5xx của API QLVB vượt 2%", "severity": "CRITICAL", "summary": "Tỷ lệ lỗi 5xx của API QLVB 3,4%",
 "labels": {"system": "QLVB"}, "groupKey": "system=QLVB", "runbookCode": "rb-api-loi-5xx", "startedAt": "2026-11-26T03:10:00Z"}
```

Sơ đồ dưới cho thấy đường đi của một cảnh báo từ Alertmanager tới người trực qua API-13-090 và EVT-13-01: Alertmanager chỉ gọi webhook, PH-13 là nơi ghi cảnh báo và phát sự kiện, nên không mất cảnh báo khi PH-13 tạm không ghi được (Alertmanager gửi lại).

```{.mermaid caption="Đường đi của cảnh báo qua API-13-090 và EVT-13-01"}
sequenceDiagram
  autonumber
  participant AM as Alertmanager
  participant OBS as module observability
  participant DB as ph13_obs
  participant KF as Kafka
  participant RL as alert-relay
  participant ON as Người trực
  AM->>OBS: POST internal alertmanager webhook, mTLS
  OBS->>OBS: Kiểm SPIFFE ID và nhãn tenant do Ruler đóng
  OBS->>DB: Tạo hoặc cập nhật alert theo tenant, rule_code, fingerprint, ghi outbox
  DB-->>OBS: Cam kết
  OBS-->>AM: 200, hoặc 503 để Alertmanager gửi lại
  DB->>KF: Debezium đưa EVT-13-01 lên topic
  KF->>RL: EVT-13-01
  RL->>ON: Gửi thư, SMS qua PH-18, webhook theo lịch trực
```

Gói bằng chứng chạy nền theo đường khác: người dùng gọi API-13-082, một tiến trình nền trích bản ghi, tính chuỗi băm, đóng gói, ký số bằng khóa ở OpenBao rồi phát EVT-13-08; sơ đồ cho thấy không bước nào để lại tệp chưa ký (BR-13-014).

```{.mermaid caption="Xuất bằng chứng kiểm toán: API-13-082, 083, 084 và EVT-13-08"}
sequenceDiagram
  autonumber
  participant AU as Kiểm toán viên
  participant API as module audit
  participant DB as ph13_audit
  participant JOB as Bộ xuất nền
  participant OB as OpenBao
  participant S3 as Bucket tạm 7 ngày
  AU->>API: POST exports, lý do, căn cứ, phiên đã xác thực lại
  API->>DB: Tạo audit_export REQUESTED, ghi AUDIT.EXPORT
  API-->>AU: 202, Location exports id
  JOB->>DB: Nhận việc, chuyển RUNNING, đọc bản ghi trong phạm vi
  JOB->>OB: Ký tệp bằng khóa chứng thư Datahub
  OB-->>JOB: Chữ ký hoặc lỗi
  JOB->>S3: Ghi gói đã ký, hết hạn sau 7 ngày
  JOB->>DB: Chuyển READY, phát EVT-13-08
  AU->>API: GET exports id download
  API-->>AU: 200 application zip, X-Evidence-Signature, ghi kiểm toán lượt tải
```

Sơ đồ cho thấy việc xuất bằng chứng trả `202` ngay và chạy nền: bộ xuất ký tệp bằng khóa của OpenBao, ghi vào kho tạm bảy ngày, rồi phát sự kiện khi sẵn sàng; mọi lượt tải đều được ghi kiểm toán.

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-13 vừa là bên cung cấp (số liệu, sức khỏe, lịch sử, ngữ cảnh chẩn đoán) vừa là bên tiêu thụ (bản ghi kiểm toán, siêu dữ liệu lượt gọi, sự kiện đổi trạng thái). Bảng dưới liệt kê từng hợp đồng để người viết tập của phân hệ kia dùng đúng mã.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| DU nguồn | DU → PH-13 | Topic `audit.recorded` (chữ ký `dh-mac`); dự phòng API-13-089 (scope `audit:write`) | Bộ đếm `dh_audit_emitted_total` để đối chiếu hằng ngày (FR-13-017); DU không có quyền ghi vào bảng |
| DU nguồn | PH-13 → DU | EVT-13-09 (đối chiếu lệch); API-13-076 cho tab Lịch sử (DU gọi, tự kiểm quyền `read` của đối tượng trước) | Tab Lịch sử của màn chi tiết thuộc phân hệ chủ, không phải màn của PH-13 (FR-13-022) |
| PH-01 | PH-13 → PH-01 | EVT-13-04 (đề xuất tạm ngừng HTTT) | PH-13 chỉ đề xuất; quyết định tạm ngừng ở PH-01 |
| PH-03 (APISIX) | APISIX → PH-13 | Topic `access.logged`; route công bố `/api/observability/v1` và `/api/audit/v1` cho BFF | `/api/platform/v1` và `/internal/*` chỉ ở `apisix-int`, không ra biên |
| PH-04, PH-05, PH-10, PH-19 | Nguồn chỉ số, log, trace | Chỉ số theo nhãn chuẩn (FRS §4.8), OTLP; PH-05 phát EVT-05-06, 10, 11, 14; PH-10 cấp topic và ACL cho `{tenant}.obs.*` | PH-13 đọc chỉ số trục sự kiện bằng scope `event:metrics-read` của PH-10 (FR-10-059) |
| PH-12 | PH-13 → PH-12 | `PermissionApi` (kiểm `PERM-13-*`), `StepUpApi` (xác thực lại phiên), `recordCrossTenant` (ghi hai chuỗi) | Quyết định từ chối và đăng nhập của PH-12 là nguồn kiểm toán và an ninh |
| PH-16 | PH-16 → PH-13 | API-13-067, 068 (scope `obs:metrics-read`) | Số liệu tổng hợp, không dữ liệu thô của người dùng |
| PH-18 | PH-18 → PH-13 | API-13-069 (scope `obs:diagnostics-read`) | Ngữ cảnh chẩn đoán theo `trace_id` |
| PH-18 | PH-13 → PH-18 | `NotificationApi` (IF-09): gửi thư, SMS hộ PH-13; EVT-13-01, 03, 05, 07, 09, 11, 13, 14 | Webhook trực tiếp từ Alertmanager là đường dự phòng khi PH-18 không khả dụng |
| PH-20 | PH-20 → PH-13 | API-13-072 (khởi tạo), API-13-073 (đóng chuỗi); trong cùng DU gọi `TenantObservabilityApi` | Sáu bước S1…S6; lũy đẳng theo tenant |
| PH-20 | PH-13 → PH-20 | EVT-13-14 (đạt 85% hạn mức) | Cho quản trị tenant nâng hạn mức |
| Alertmanager | Alertmanager → PH-13 | API-13-090 (webhook v4, mTLS) | Một Alertmanager toàn cục định tuyến theo nhãn tenant |
| SIEM, SOC của tỉnh hoặc quốc gia | PH-13 → SIEM | IF-08: Syslog TLS hoặc OTLP; lược đồ ECS hoặc OCSF; sự kiện EVT-13-04, 05, 06, 12 qua bộ xuất | Đã lọc dữ liệu cá nhân; hàng đợi đĩa khi SIEM không nhận (ERR-13-122) |
| Kho WORM (Ceph RGW) | PH-13 → WORM | Lô bản ghi và neo, Object Lock; không qua API này | Bucket `dh-evidence`; sao lô mỗi 5 phút (FR-13-013) |
| OpenBao | PH-13 ↔ OpenBao | Ký neo, HMAC theo khóa tenant, tài khoản cơ sở dữ liệu động; bí mật kênh và SIEM | Không qua API này; lỗi trả ERR-13-107 (nền) hoặc ERR-13-014, 026 (API) |
| Grafana | PH-13 → Grafana | Đồng bộ bộ dashboard bằng API-13-018 vào org của tenant | Người dùng vào Grafana qua Keycloak OIDC, không qua API này |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-13

Ý nghĩa và mã HTTP theo FRS §9.2; cột "API phát sinh" sinh từ OpenAPI (khóa `x-datahub-errors` của từng operation). Mã áp cho hầu hết API (ERR-13-001, 003, 007, 009, 010, 016, 036, 037, 038) ghi số lượng thay vì liệt kê. Dải 001–099 cho control plane, 101–199 cho xử lý chạy nền; câu hiển thị cho người dùng ở FRS §9.2 và D03-06-PH13, không lặp lại ở đây.

<!-- gen:errors:start -->
### 6.1. Lỗi API điều khiển (ERR-13-001…044)

Bảng dưới là 44 mã người gọi API có thể nhận; cột cuối cho biết operation nào phát sinh để kiểm thử viên viết ca lỗi đủ.

| Mã | HTTP | Ý nghĩa | API phát sinh (API-13-) |
|---|---|---|---|
| ERR-13-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác | 42 API (chung) |
| ERR-13-002 | 409 | Mã đã tồn tại, kể cả đối tượng đã ngừng dùng | 028, 036, 043, 046, 049, 062 |
| ERR-13-003 | 400 | Dữ liệu yêu cầu không hợp lệ (mẫu mã, giá trị ngoài miền, thiếu trường) | 67 API (chung) |
| ERR-13-004 | 400 | Thiếu hoặc sai khoảng thời gian | 019, 020, 022, 025, 067, 068, 074, 082 |
| ERR-13-005 | 422 | Khoảng thời gian vượt giới hạn mỗi lần tra | 019, 022, 025, 067, 074 |
| ERR-13-006 | 400 | Cú pháp truy vấn sai | 019, 020, 021, 022, 025, 028, 039, 067 |
| ERR-13-007 | 412 | Sai phiên bản (`If-Match`) | 15 API (chung) |
| ERR-13-008 | 400 | Thiếu lý do cho thao tác bắt buộc lý do | 040, 055, 060, 065, 077, 082 |
| ERR-13-009 | 403 | Thiếu quyền | 82 API (chung) |
| ERR-13-010 | 401 | Chưa xác thực hoặc phiên hết hạn | 89 API (chung) |
| ERR-13-011 | 429 | Quá nhiều truy vấn đồng thời | 019, 020, 021, 022, 023, 025, 067, 074 |
| ERR-13-012 | 422 | Thiếu lý do truy vấn kiểm toán | 074, 082 |
| ERR-13-013 | 422 | Phạm vi truy vấn hoặc xuất quá rộng | 074, 082 |
| ERR-13-014 | 503 | Phụ thuộc không khả dụng (Mimir, Loki, Tempo, ClickHouse, OpenBao, WORM, Alertmanager, PH-01…) | 36 API (chung) |
| ERR-13-015 | 504 | Truy vấn quá thời gian chờ | 019, 020, 022, 023, 025, 039, 067, 074 |
| ERR-13-016 | 423 | Tenant đang tạm ngừng, chỉ đọc | 24 API (chung) |
| ERR-13-017 | 422 | Luật thiếu runbook hoặc runbook thiếu mục | 036, 038, 043, 044 |
| ERR-13-018 | 422 | Biểu thức luật không hợp lệ | 036, 038, 039 |
| ERR-13-019 | 403 | Sửa hoặc tắt luật chuẩn của nền tảng | 038, 040, 041 |
| ERR-13-020 | 409 | Cảnh báo ở trạng thái không áp dụng được thao tác | 032, 033, 034, 058, 059, 060 |
| ERR-13-021 | 422 | Tạm ẩn thiếu hoặc vượt thời hạn, thiếu lý do | 034 |
| ERR-13-022 | 422 | Đóng cảnh báo thiếu nguyên nhân, hành động | 033 |
| ERR-13-023 | 422 | Đóng cảnh báo an ninh thiếu kết luận | 059 |
| ERR-13-024 | 422 | Ngưỡng luật an ninh ngoài biên hoặc luật không được tắt | 055 |
| ERR-13-025 | 409 | Có yêu cầu xuất bằng chứng cùng phạm vi đang chạy | 082 |
| ERR-13-026 | 503 | Không ký số được tệp bằng chứng | 084 |
| ERR-13-027 | 410 | Tệp bằng chứng đã hết hạn tải | 084 |
| ERR-13-028 | 403 | Cần xác thực lại phiên | 055, 060, 074, 077, 082, 084 |
| ERR-13-029 | 422 | Khoảng thời gian ngoài thời hạn lưu trực tuyến | 074, 082 |
| ERR-13-030 | 404 | Không tìm thấy trace ở cả ba nguồn | 023, 024, 069 |
| ERR-13-031 | 422 | Số định danh tra cứu sai định dạng | 074 |
| ERR-13-032 | 409 | Đang có lượt kiểm tra toàn vẹn của tenant | 077 |
| ERR-13-033 | 422 | Kiểm tra kênh thông báo thất bại | 049, 050, 051 |
| ERR-13-034 | 422 | Lịch trực hở khoảng, chồng ca hoặc nhóm Nghiêm trọng thiếu đường độc lập | 046, 047 |
| ERR-13-035 | 422 | Bộ dashboard không hợp lệ | 018 |
| ERR-13-036 | 403 | Truy cập tenant khác không có phiên liên tenant | 35 API (chung) |
| ERR-13-037 | 409 | `Idempotency-Key` trùng khác nội dung | 028, 036, 043, 046, 049, 062, 065, 072, 073, 077, 082 |
| ERR-13-038 | 400 | `size` > 200 hoặc tham số ngoài miền | 22 API (chung) |
| ERR-13-039 | 422 | Mục tiêu SIEM không hợp lệ hoặc không kết nối được | 062, 063, 064 |
| ERR-13-040 | 422 | Tham số `13.*` ngoài miền, thời hạn lưu dưới 3 năm | 071 |
| ERR-13-041 | 422 | Hạn mức vượt trần của nền tảng | 071 |
| ERR-13-042 | 409 | Tenant đã có cấu hình quan sát với tham số khác | 072 |
| ERR-13-043 | 409 | Chuỗi kiểm toán đã đóng | 073, 089 |
| ERR-13-044 | 403 | Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu scope | 067, 068, 069, 072, 073, 076, 089 |

: Mã lỗi ERR-13-001…044 và API phát sinh

### 6.2. Lỗi chạy nền (ERR-13-101…126)

Không trả qua API; kết quả ghi ở chỉ số, nhật ký, bảng cách ly hoặc cảnh báo cho người vận hành. Câu hiển thị ở FRS §9.2.

| Mã | Ý nghĩa | Nơi người vận hành thấy |
|---|---|---|
| ERR-13-101 | Bản ghi kiểm toán thiếu trường bắt buộc, đã cách ly | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |
| ERR-13-102 | Bản ghi kiểm toán trùng `id`, bỏ qua | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |
| ERR-13-103 | DU không được phép ghi kiểm toán cho tenant | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |
| ERR-13-104 | `tenant_id` của bản ghi không khớp topic | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |
| ERR-13-105 | Bản ghi chứa giá trị Nhạy cảm chưa che, đã cách ly | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |
| ERR-13-106 | Không ghi được vào bảng kiểm toán | Chỉ số `dh_audit_*`, cảnh báo `WARNING`, UI-13-13 |
| ERR-13-107 | Không ký được neo tại OpenBao | Chỉ số `dh_audit_*`, cảnh báo `WARNING`, UI-13-13 |
| ERR-13-108 | Không sao được lô sang kho WORM | Chỉ số `dh_audit_*`, cảnh báo `WARNING`, UI-13-13 |
| ERR-13-109 | Đứt chuỗi kiểm toán | Cảnh báo Nghiêm trọng, EVT-13-05, UI-13-14 |
| ERR-13-110 | Neo không khớp bản WORM hoặc SIEM | Cảnh báo Nghiêm trọng, EVT-13-05, UI-13-14 |
| ERR-13-111 | Đối chiếu số lượng lệch | Cảnh báo, EVT-13-09, UI-13-14 |
| ERR-13-112 | Log chứa mẫu dữ liệu cá nhân | Kết quả quét, cảnh báo an ninh, UI-13-17 |
| ERR-13-113 | Dữ liệu quan sát thiếu nhãn tenant | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-114 | Nhãn ngoài danh sách hoặc vượt hạn mức chuỗi, đã bỏ | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-115 | Bộ thu thập quá tải, đang đệm và bỏ dữ liệu ít quan trọng | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-116 | Trace quá dài, đã cắt | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-117 | Trace chưa đủ span | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-118 | Kho lượt gọi API không ghi được | Chỉ số của bộ thu thập, UI-13-01, UI-13-17 |
| ERR-13-119 | Luật đánh giá lỗi | Cảnh báo về chính hệ thống giám sát, UI-13-01 |
| ERR-13-120 | Gửi thông báo qua kênh thất bại | Cảnh báo về chính hệ thống giám sát, UI-13-01 |
| ERR-13-121 | Leo thang hết cấp mà chưa ai xác nhận | Cảnh báo về chính hệ thống giám sát, UI-13-01 |
| ERR-13-122 | SIEM không nhận dữ liệu | Cảnh báo về chính hệ thống giám sát, UI-13-01 |
| ERR-13-123 | Kho đạt ngưỡng dung lượng 85% | EVT-13-13, EVT-13-14, UI-13-01 |
| ERR-13-124 | Kiểm tra tổng hợp thất bại liên tiếp | EVT-13-13, EVT-13-14, UI-13-01 |
| ERR-13-125 | Phân vùng chưa lưu trữ được vì chưa xác minh đủ ở WORM | Cảnh báo `WARNING`, UI-13-14 |
| ERR-13-126 | Đồng hồ DU lệch quá 2 giây về tương lai | Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn |

: Mã lỗi chạy nền ERR-13-101…126
<!-- gen:errors:end -->

### 6.3. Thông điệp và trường bổ sung

Thân lỗi ngoài năm trường bắt buộc (`type`, `title`, `status`, `code`, `traceId`) có thể mang trường bổ sung giúp giao diện hiển thị đúng và giúp bên gọi tự xử lý.

| Mã | Trường bổ sung | Ví dụ `detail` |
|---|---|---|
| ERR-13-003 | `errors[]` (`path`, `rule`, `message`) | "Trường `severity` phải là một trong CRITICAL, WARNING, INFO." |
| ERR-13-005 | `maxDays` | "Khoảng thời gian tối đa cho loại dữ liệu này là 7 ngày mỗi lần tra." |
| ERR-13-006 | `errors[]` có `path` là vị trí ký tự | "Cú pháp truy vấn chưa đúng ở vị trí 18: thiếu dấu đóng ngoặc." |
| ERR-13-007 | `currentEtag` | "Dữ liệu đã được người khác sửa." |
| ERR-13-011 | `retryAfterSeconds` | "Bạn đang chạy quá nhiều truy vấn cùng lúc. Chờ 5 giây rồi thử lại." |
| ERR-13-013 | `recordCount` | "Phạm vi truy vấn quá rộng (2.350.000 bản ghi)." |
| ERR-13-018 | `errors[]` | "Biểu thức luật không hợp lệ: nhãn `trace_id` không được dùng làm nhãn chỉ số." |
| ERR-13-020 | Không | "Cảnh báo đã ở trạng thái RESOLVED, thao tác này không còn áp dụng." |
| ERR-13-021 | `maxDays` | "Tạm ẩn tối đa 7 ngày (24 giờ với cảnh báo Nghiêm trọng)." |
| ERR-13-034 | `errors[]` (khoảng hở, ca chồng) | "Thứ Bảy 00:00–07:30 chưa có người nhận." |
| ERR-13-036 | Không | Không nêu tên tenant đích nếu người gọi chưa có quyền biết |
| ERR-13-044 | Không | Không nêu scope còn thiếu, chỉ ghi vào nhật ký ATTT |

: Thông điệp và trường bổ sung của lỗi

Không thông điệp nào lặp lại giá trị Nhạy cảm, bí mật hay nội dung biểu thức truy vấn của người dùng; bộ lọc che ở `ProblemDetailsFactory` áp lên `detail` trước khi trả. Với tra cứu kiểm toán, thông điệp lỗi không nêu số định danh người tra theo `objectKey`.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng được kiểm ở CI-5 (D04-02) cùng với mã. Ba lớp kiểm: tệp hợp lệ về mặt kỹ thuật, tệp đúng quy ước PH-13, và tệp không lệch FRS.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; `PATCH` có `If-Match`; `POST` tạo có `Idempotency-Key` | [`check_contracts.py`](ph13/tools/check_contracts.py) (`openapi-spec-validator`, `jsonschema`) | CI-5 |
| Không có `PUT`, `PATCH`, `DELETE` trên `/records`; đủ 90 mã API-13-001…090 | `check_contracts.py` | CI-5 |
| Trường bí mật (`secret`, `clientKey`) chỉ ở lược đồ chỉ ghi và có `writeOnly` | `check_contracts.py` | CI-5 |
| Mọi `ERR-13-nnn` ở OpenAPI có trong FRS §9.2; đủ EVT-13-01…14, địa chỉ topic theo quy ước | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0 hợp lệ | `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước | Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp FRS, không trùng | `build/tools/kiem_tra_ma.py` | CI-1 |
| Lược đồ `audit-event.v1` tương thích ngược | Apicurio BACKWARD | CI-5 |

: Kiểm tra hợp đồng trong CI

Kết quả ngày 26/11/2026: OpenAPI hợp lệ, 90 operation, 31 ví dụ khớp lược đồ, 44 mã ERR-13 dùng đều có trong FRS; AsyncAPI hợp lệ, 16 kênh, 3 ví dụ khớp; `@asyncapi/parser` báo 0 lỗi và một thông tin khuyến nghị nâng lên 3.1.0, giữ 3.0.0 theo khuôn của PH-05, PH-19.

Ngoài kiểm hợp đồng, kiểm thử tích hợp của PH-13 có các ca bám theo hợp đồng này: không đường nào ghi vào chuỗi ngoài `ChainWriter` (Semgrep cấm `UPDATE`, `DELETE` trên `ph13_audit.audit_event`), bộ kiểm thử rò rỉ giữa tenant (SEC-87) gọi từng API đọc bằng token của tenant khác và phải nhận 404 hoặc ERR-13-036.

## 8. Ánh xạ từ hệ cũ và mã đang chạy

Hệ cũ không có API giám sát riêng: Bus xem qua JMX và Jolokia, APIM xem qua màn quản trị. SRS cũ của repo (`docs/07-srs/SRS-PH-13-observability.md` §5) có đề xuất điểm cuối ở `/api/v1/observability` và `/api/v1/audit`; chưa chạy ở mã hiện tại, chỉ còn giá trị lịch sử. Bảng dưới nối hai nguồn đó với API mới.

| Hệ cũ hoặc đề xuất SRS cũ | API mới | Ghi chú |
|---|---|---|
| Bus: JMX, Jolokia xem route, endpoint (LGC-BUS-030) | API-13-006, 007 (chỉ số luồng, route) | OpenTelemetry và Micrometer, không mở JMX |
| Bus: tổng quan agent, dữ liệu từng agent (LGC-BUS-014, 015, 016, 017) | API-13-001, 003, 004 | "Agent" thành đơn vị triển khai của `dh-runtime` |
| Bus: thống kê theo endpoint (LGC-BUS-027) | API-13-008 | Giới hạn 31 ngày mỗi lần |
| Bus: quản trị log agent (LGC-BUS-029), logging routing (LGC-BUS-038) | API-13-019, 020, 021, 022, 023 | Log tập trung thay log theo agent |
| Hub: biểu đồ CPU, bộ nhớ theo giây (LGC-HUB-005, 006) | API-13-013, 014 | Theo chu kỳ thu 15 giây, không theo giây |
| APIM: danh sách, chi tiết, giám sát gateway (LGC-APIM-023; 024, 025) | API-13-011, 012, 013 | Chỉ số APISIX, không JVM |
| APIM: log mọi request, dashboard hoạt động, audit (LGC-APIM-022; 026, 027) | API-13-025, 026 · API-13-001, 009, 010 · API-13-074…088 | Siêu dữ liệu, che dữ liệu; kiểm toán có chuỗi băm |
| PayGov: nhật ký giao dịch (LGC-PAY-021) | API-13-025 (siêu dữ liệu), màn nghiệp vụ ở PH-19 | PH-19 giữ màn nghiệp vụ |
| SRS cũ `GET /observability/metrics/query` | API-13-067 (`POST /metrics:query`) | Truy vấn có thân; dành cho PH-16, không cho người dùng |
| SRS cũ `GET /observability/logs/query` | API-13-019 (`POST /logs:search`) | Có thân để chứa bộ lọc dài và lý do |
| SRS cũ `GET /observability/traces/{traceId}`, `/traces/search` | API-13-023, 022 | Thêm trạng thái trace chưa đủ span |
| SRS cũ `GET /observability/correlate/{traceId}` | API-13-024 | Thêm exemplar chỉ số |
| SRS cũ `GET /observability/service-health` | API-13-002 | Thêm lọc theo lớp và scope máy |
| SRS cũ `POST /audit/query`, `GET /audit/records/{auditId}` | API-13-074, 075 | Thêm lý do, step-up, `objectKey` |
| SRS cũ `POST /audit/verify`, `GET /audit/anchors` | API-13-077…081 | Tách yêu cầu, danh sách, chi tiết; kết quả có vị trí đứt đầu tiên |
| SRS cũ `POST /audit/export`, `GET /audit/export/{id}` | API-13-082, 083, 084 | Bất đồng bộ, hạn tải 7 ngày, ký số |
| SRS cũ `GET /observability/alerts`, `POST …/alerts/{id}/ack` | API-13-030, 032 | Thêm `resolve`, `silence`, luật, lịch trực, kênh |
| Kafka `lgsp.audit` (SRS cũ) | Topic `{tenant}.obs.audit.recorded.v1` | Theo tenant; chữ ký nguồn `dh-mac` |

: Ánh xạ từ hệ cũ và đề xuất SRS cũ

## 9. Câu hỏi mở

Mã `Q13-55…59` theo dải tập API (D00-04 §3.1). Mỗi câu có đề xuất tạm để tập không bị chặn.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q13-55 | FRS §6.1 giới hạn tra kiểm toán 31 ngày mỗi lần, còn NFR-13-009 đo khoảng 12 tháng p95 ≤ 10 giây. Một lần tra có được vượt 31 ngày không | Giữ 31 ngày mỗi lần ở API (ERR-13-005); khoảng dài hơn dùng xuất bằng chứng (API-13-082). Kiểm thử NFR-13-009 chạy bằng nhiều lượt 31 ngày nối nhau. `totalEstimate` lấy từ thống kê phân vùng, không `COUNT` chính xác trên 36,5 triệu bản ghi |
| Q13-56 | Có công bố API-13-067, 068, 069 cho PH-16, PH-18 qua APISIX không, hay chỉ gọi trong cụm | Không công bố; gọi trong cụm, mTLS lưới dịch vụ (giống Q05-61). Khi PH-16 hoặc PH-18 tách hạ tầng mới tính lại |
| Q13-57 | Cách truyền yêu cầu xác thực lại (step-up) từ máy chủ qua BFF tới giao diện | Dùng RFC 9470: ERR-13-028 trả 403 kèm `WWW-Authenticate` có `acr_values`; PH-12 chốt giá trị `acr` và thời hạn "vừa xác thực" (giả định 10 phút) |
| Q13-58 | Phiên liên tenant truyền thế nào: tham số `targetTenant` hay tiêu đề mang mã quyền có thời hạn | Kết hợp tham số và tiêu đề: yêu cầu mang tiêu đề `X-DH-Grant-Id` chứa `grantId` của quyền có thời hạn do PH-12 cấp (API-12-038…040; OPA tra quyền theo dữ liệu, không tin tiêu đề), API nhận `targetTenant` và so khớp với tenant đích của quyền đó; lệch trả ERR-13-036 |
| Q13-59 | SSE của API-13-021 qua BFF và APISIX gặp giới hạn thời gian nhàn rỗi của proxy | Gửi `heartbeat` mỗi 15 giây (giả định, nhỏ hơn mức 60 giây thường gặp); đo ở kiểm thử tải; giao diện đóng luồng khi tab ẩn và mở lại khi hiện |

: Câu hỏi mở của tập API PH-13

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục. Đường dẫn ghi đầy đủ gồm tiền tố nhóm; với operation có `x-datahub-errors`, mục "Lỗi" liệt kê mã HTTP và mã `ERR-13-nnn` của thao tác, ý nghĩa ở chương 6.

<!-- gen:dac-ta-api:start -->

### Bảng điều khiển

#### API-13-001 · Tổng quan nền tảng của tenant

::: dac-ta
**Mục đích.** Tổng quan nền tảng của tenant.

**Phương thức, đường dẫn.** `GET /api/observability/v1/overview`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-031.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Overview`; trường bắt buộc: `tiles`, `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sáu thẻ chỉ số, 5 cảnh báo mới, biểu đồ lượt gọi và độ trễ so vạch SLO.
:::

#### API-13-002 · Sức khỏe các thành phần nền tảng

::: dac-ta
**Mục đích.** Sức khỏe các thành phần nền tảng.

**Phương thức, đường dẫn.** `GET /api/observability/v1/components`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-031, FR-13-058.

**Tham số.** `layer` (query, string, tùy chọn); `status` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ComponentList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cũng nhận token dịch vụ scope `obs:health-read` cho phân hệ khác (FR-13-058).
:::

#### API-13-003 · Danh sách đơn vị triển khai và tài nguyên

::: dac-ta
**Mục đích.** Danh sách đơn vị triển khai và tài nguyên.

**Phương thức, đường dẫn.** `GET /api/observability/v1/deployments`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-032.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `q` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DeploymentPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-004 · Chi tiết đơn vị triển khai

::: dac-ta
**Mục đích.** Chi tiết đơn vị triển khai.

**Phương thức, đường dẫn.** `GET /api/observability/v1/deployments/{deploymentCode}`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-032.

**Tham số.** `deploymentCode` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-005 · Bảng điều khiển các luồng

::: dac-ta
**Mục đích.** Bảng điều khiển các luồng.

**Phương thức, đường dẫn.** `GET /api/observability/v1/flows`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-033.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `q` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-006 · Chỉ số một luồng

::: dac-ta
**Mục đích.** Chỉ số một luồng.

**Phương thức, đường dẫn.** `GET /api/observability/v1/flows/{flowCode}/metrics`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-033.

**Tham số.** `flowCode` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-007 · Chỉ số một route của luồng

::: dac-ta
**Mục đích.** Chỉ số một route của luồng.

**Phương thức, đường dẫn.** `GET /api/observability/v1/flows/{flowCode}/routes/{routeId}/metrics`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-033.

**Tham số.** `flowCode` (path, string, bắt buộc); `routeId` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-008 · Thống kê theo endpoint

::: dac-ta
**Mục đích.** Thống kê theo endpoint.

**Phương thức, đường dẫn.** `GET /api/observability/v1/endpoints/stats`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-034.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `api` (query, string, tùy chọn); `system` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatTable`; trường bắt buộc: `columns`, `rows`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giới hạn 31 ngày mỗi lần (ERR-13-005).
:::

#### API-13-009 · Thống kê theo API

::: dac-ta
**Mục đích.** Thống kê theo API.

**Phương thức, đường dẫn.** `GET /api/observability/v1/apis/stats`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-035.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `api` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatTable`; trường bắt buộc: `columns`, `rows`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chủ dịch vụ (SV) chỉ thấy API thuộc tổ chức mình.
:::

#### API-13-010 · Thống kê theo HTTT

::: dac-ta
**Mục đích.** Thống kê theo HTTT.

**Phương thức, đường dẫn.** `GET /api/observability/v1/systems/{systemCode}/stats`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-035.

**Tham số.** `systemCode` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chủ dịch vụ (SV) chỉ thấy HTTT thuộc tổ chức mình.
:::

#### API-13-011 · Danh sách nút gateway

::: dac-ta
**Mục đích.** Danh sách nút gateway.

**Phương thức, đường dẫn.** `GET /api/observability/v1/gateways`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-036.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `status` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GatewayPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-012 · Chi tiết nút gateway

::: dac-ta
**Mục đích.** Chi tiết nút gateway.

**Phương thức, đường dẫn.** `GET /api/observability/v1/gateways/{nodeId}`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-036.

**Tham số.** `nodeId` (path, string, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Gateway`; trường bắt buộc: `nodeId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-013 · Tài nguyên của nút gateway

::: dac-ta
**Mục đích.** Tài nguyên của nút gateway.

**Phương thức, đường dẫn.** `GET /api/observability/v1/gateways/{nodeId}/resources`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-037.

**Tham số.** `nodeId` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-014 · Bảng điều khiển cụm Kafka

::: dac-ta
**Mục đích.** Bảng điều khiển cụm Kafka.

**Phương thức, đường dẫn.** `GET /api/observability/v1/kafka/cluster`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-038.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Số liệu cụm từ Strimzi và PH-10; tenant chỉ thấy chủ đề `{tenant}.*`.
:::

#### API-13-015 · Bảng điều khiển hoạt động nghiệp vụ

::: dac-ta
**Mục đích.** Bảng điều khiển hoạt động nghiệp vụ.

**Phương thức, đường dẫn.** `GET /api/observability/v1/dashboards/business`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-039.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-016 · Bảng điều khiển an ninh

::: dac-ta
**Mục đích.** Bảng điều khiển an ninh.

**Phương thức, đường dẫn.** `GET /api/observability/v1/dashboards/security`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-040.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PanelSet`; trường bắt buộc: `panels`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ số an ninh tổng hợp; chi tiết cảnh báo ở API-13-056.
:::

#### API-13-017 · Danh sách bộ dashboard chuẩn và trạng thái đồng bộ

::: dac-ta
**Mục đích.** Danh sách bộ dashboard chuẩn và trạng thái đồng bộ.

**Phương thức, đường dẫn.** `GET /api/observability/v1/dashboard-sets`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-041.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DashboardSetList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-009, ERR-13-010, ERR-13-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-018 · Đồng bộ bộ dashboard sang Grafana của tenant

::: dac-ta
**Mục đích.** Đồng bộ bộ dashboard sang Grafana của tenant.

**Phương thức, đường dẫn.** `POST /api/observability/v1/dashboard-sets/{setCode}:sync`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-041.

**Tham số.** `setCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DashboardSyncRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `DashboardSetSync`; trường bắt buộc: `setCode`, `syncId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `423`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-016, ERR-13-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy nền; kết quả đọc lại bằng API-13-017.
:::

### Log, trace, nhật ký truy cập API

#### API-13-019 · Tra log tập trung

::: dac-ta
**Mục đích.** Tra log tập trung.

**Phương thức, đường dẫn.** `POST /api/observability/v1/logs:search`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-026.

**Tham số.** `cursor` (query, string, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** application/json: `LogSearchRequest`; trường bắt buộc: `from`, `to`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LogSearchResult`; trường bắt buộc: `lines`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-005, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giới hạn khoảng thời gian và số truy vấn đồng thời theo `13.query.*`.
:::

#### API-13-020 · Ngữ cảnh quanh một dòng log

::: dac-ta
**Mục đích.** Ngữ cảnh quanh một dòng log.

**Phương thức, đường dẫn.** `GET /api/observability/v1/logs/{logId}/context`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-027.

**Tham số.** `logId` (path, string, bắt buộc); `before` (query, integer, tùy chọn); `after` (query, integer, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LogContext`; trường bắt buộc: `anchor`, `before`, `after`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-004, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả các dòng trước và sau cùng nguồn, cùng `trace_id` nếu có.
:::

#### API-13-021 · Theo dõi log trực tiếp (SSE)

::: dac-ta
**Mục đích.** Theo dõi log trực tiếp (SSE).

**Phương thức, đường dẫn.** `GET /api/observability/v1/logs:tail`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-027.

**Tham số.** `query` (query, string, tùy chọn); `du` (query, string, tùy chọn); `service` (query, string, tùy chọn); `level` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LogTailEvent`; trường bắt buộc: `event`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luồng `text/event-stream`; tự tắt sau `13.live-tail.idle-minutes` không hoạt động.
:::

#### API-13-022 · Tìm trace theo điều kiện

::: dac-ta
**Mục đích.** Tìm trace theo điều kiện.

**Phương thức, đường dẫn.** `GET /api/observability/v1/traces`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-028.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `service` (query, string, tùy chọn); `minDurationMs` (query, integer, tùy chọn); `status` (query, string, tùy chọn); `flow` (query, string, tùy chọn); `system` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TracePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-005, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-023 · Chi tiết trace và biểu đồ thác nước

::: dac-ta
**Mục đích.** Chi tiết trace và biểu đồ thác nước.

**Phương thức, đường dẫn.** `GET /api/observability/v1/traces/{traceId}`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-028.

**Tham số.** `traceId` (path, TraceId, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Trace`; trường bắt buộc: `traceId`, `spans`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-030, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trace chỉ giữ 14 ngày (ERR-13-030).
:::

#### API-13-024 · Liên kết chỉ số, trace, log, kiểm toán theo trace_id

::: dac-ta
**Mục đích.** Liên kết chỉ số, trace, log, kiểm toán theo trace_id.

**Phương thức, đường dẫn.** `GET /api/observability/v1/correlations/{traceId}`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-029.

**Tham số.** `traceId` (path, TraceId, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Correlation`; trường bắt buộc: `traceId`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-030, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Số bản ghi kiểm toán chỉ hiện khi người gọi có `PERM-13-audit-read`.
:::

#### API-13-025 · Tra nhật ký truy cập API

::: dac-ta
**Mục đích.** Tra nhật ký truy cập API.

**Phương thức, đường dẫn.** `POST /api/observability/v1/access-logs:search`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-030.

**Tham số.** `cursor` (query, string, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** application/json: `AccessLogSearchRequest`; trường bắt buộc: `from`, `to`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessLogPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-005, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Siêu dữ liệu lượt gọi từ ClickHouse; không có thân, không có chuỗi truy vấn.
:::

#### API-13-026 · Chi tiết một lượt gọi API

::: dac-ta
**Mục đích.** Chi tiết một lượt gọi API.

**Phương thức, đường dẫn.** `GET /api/observability/v1/access-logs/{recordId}`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-030.

**Tham số.** `recordId` (path, string, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessRecord`; trường bắt buộc: `recordId`, `ts`, `route`, `method`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-027 · Truy vấn đã lưu của tôi và được chia sẻ

::: dac-ta
**Mục đích.** Truy vấn đã lưu của tôi và được chia sẻ.

**Phương thức, đường dẫn.** `GET /api/observability/v1/saved-queries`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-026.

**Tham số.** `kind` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SavedQueryList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-028 · Lưu một truy vấn

::: dac-ta
**Mục đích.** Lưu một truy vấn.

**Phương thức, đường dẫn.** `POST /api/observability/v1/saved-queries`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-026.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SavedQueryCreate`; trường bắt buộc: `kind`, `name`, `query`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SavedQuery`; trường bắt buộc: `queryId`, `kind`, `name`, `query`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-029 · Xóa truy vấn đã lưu

::: dac-ta
**Mục đích.** Xóa truy vấn đã lưu.

**Phương thức, đường dẫn.** `DELETE /api/observability/v1/saved-queries/{queryId}`.

**Quyền.** `PERM-13-logs`.

**FR hiện thực.** FR-13-026.

**Tham số.** `queryId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ chủ sở hữu xóa được; không dùng `If-Match` vì xóa cứng.
:::

### Cảnh báo

#### API-13-030 · Danh sách cảnh báo

::: dac-ta
**Mục đích.** Danh sách cảnh báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/alerts`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-045, FR-13-046, FR-13-047.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `status` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `ruleCode` (query, string, tùy chọn); `groupKey` (query, string, tùy chọn); `q` (query, string, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách đã gom nhóm theo `groupKey` khi `groupBy=group`.
:::

#### API-13-031 · Chi tiết cảnh báo

::: dac-ta
**Mục đích.** Chi tiết cảnh báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/alerts/{alertId}`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-047.

**Tham số.** `alertId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm lịch sử xử lý, lượt gửi thông báo, runbook của luật.
:::

#### API-13-032 · Xác nhận cảnh báo

::: dac-ta
**Mục đích.** Xác nhận cảnh báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-13-alert-ack`.

**FR hiện thực.** FR-13-047.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AckRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dừng leo thang.
:::

#### API-13-033 · Đánh dấu đã xử lý

::: dac-ta
**Mục đích.** Đánh dấu đã xử lý.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alerts/{alertId}:resolve`.

**Quyền.** `PERM-13-alert-ack`.

**FR hiện thực.** FR-13-047.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResolveRequest`; trường bắt buộc: `cause`, `measure`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020, ERR-13-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bắt buộc ghi nguyên nhân và hành động.
:::

#### API-13-034 · Tạm ẩn cảnh báo

::: dac-ta
**Mục đích.** Tạm ẩn cảnh báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alerts/{alertId}:silence`.

**Quyền.** `PERM-13-alert-ack`.

**FR hiện thực.** FR-13-047.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SilenceRequest`; trường bắt buộc: `until`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020, ERR-13-021 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối đa `13.alert.silence-max-days`; mức Nghiêm trọng tối đa 24 giờ.
:::

#### API-13-052 · Thống kê hiệu quả cảnh báo

::: dac-ta
**Mục đích.** Thống kê hiệu quả cảnh báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/alert-stats`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-050.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertStats`; trường bắt buộc: `totals`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tỷ lệ cảnh báo giả, MTTA, MTTR theo luật và mức.
:::

#### API-13-053 · Sức khỏe của chính hệ thống giám sát

::: dac-ta
**Mục đích.** Sức khỏe của chính hệ thống giám sát.

**Phương thức, đường dẫn.** `GET /api/observability/v1/monitoring-health`.

**Quyền.** `PERM-13-dashboard`.

**FR hiện thực.** FR-13-049.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MonitoringHealth`; trường bắt buộc: `status`, `components`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-009, ERR-13-010, ERR-13-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gồm Watchdog, nhịp tim ngoài site, độ trễ thu thập.
:::

### Luật cảnh báo và runbook

#### API-13-035 · Danh sách luật cảnh báo

::: dac-ta
**Mục đích.** Danh sách luật cảnh báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/alert-rules`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-042, FR-13-043.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `scope` (query, string, tùy chọn); `status` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRulePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `scope=PLATFORM` là luật chuẩn của nền tảng.
:::

#### API-13-036 · Tạo luật cảnh báo kèm runbook

::: dac-ta
**Mục đích.** Tạo luật cảnh báo kèm runbook.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alert-rules`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertRuleCreate`; trường bắt buộc: `ruleCode`, `name`, `expr`, `language`, `severity`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AlertRule`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-017, ERR-13-018, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luật phải có runbook đủ năm mục (BR-13-008).
:::

#### API-13-037 · Chi tiết luật cảnh báo

::: dac-ta
**Mục đích.** Chi tiết luật cảnh báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/alert-rules/{ruleCode}`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-042, FR-13-043.

**Tham số.** `ruleCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRule`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-038 · Sửa luật cảnh báo

::: dac-ta
**Mục đích.** Sửa luật cảnh báo.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/alert-rules/{ruleCode}`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `ruleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertRulePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRule`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-017, ERR-13-018, ERR-13-019 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luật chuẩn của nền tảng không sửa được (ERR-13-019).
:::

#### API-13-039 · Chạy thử luật trên dữ liệu 24 giờ gần nhất

::: dac-ta
**Mục đích.** Chạy thử luật trên dữ liệu 24 giờ gần nhất.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alert-rules/{ruleCode}:test`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `ruleCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertRuleTestRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRuleTestResult`; trường bắt buộc: `wouldFire`, `firings`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `503`, `504`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-006, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-015, ERR-13-018 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không tạo cảnh báo thật.
:::

#### API-13-040 · Tắt luật cảnh báo

::: dac-ta
**Mục đích.** Tắt luật cảnh báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alert-rules/{ruleCode}:disable`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `ruleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRule`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-019 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cảnh báo đang mở của luật được đóng tự động.
:::

#### API-13-041 · Bật lại luật cảnh báo

::: dac-ta
**Mục đích.** Bật lại luật cảnh báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/alert-rules/{ruleCode}:enable`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `ruleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRule`.

**Lỗi.** HTTP `401`, `403`, `404`, `412`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-019 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-042 · Danh sách runbook

::: dac-ta
**Mục đích.** Danh sách runbook.

**Phương thức, đường dẫn.** `GET /api/observability/v1/runbooks`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-042.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RunbookPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-043 · Tạo runbook

::: dac-ta
**Mục đích.** Tạo runbook.

**Phương thức, đường dẫn.** `POST /api/observability/v1/runbooks`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RunbookCreate`; trường bắt buộc: `runbookCode`, `title`, `meaning`, `firstChecks`, `commonCauses`, `remediation`, `escalationWhen`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Runbook`; trường bắt buộc: `runbookCode`, `title`, `meaning`, `firstChecks`, `commonCauses`, `remediation`, `escalationWhen`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-017, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đủ năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên.
:::

#### API-13-044 · Sửa runbook

::: dac-ta
**Mục đích.** Sửa runbook.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/runbooks/{runbookCode}`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-042.

**Tham số.** `runbookCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RunbookPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Runbook`; trường bắt buộc: `runbookCode`, `title`, `meaning`, `firstChecks`, `commonCauses`, `remediation`, `escalationWhen`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

### Lịch trực và kênh thông báo

#### API-13-045 · Danh sách lịch trực

::: dac-ta
**Mục đích.** Danh sách lịch trực.

**Phương thức, đường dẫn.** `GET /api/observability/v1/oncall-schedules`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-048.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OncallSchedulePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-046 · Tạo lịch trực

::: dac-ta
**Mục đích.** Tạo lịch trực.

**Phương thức, đường dẫn.** `POST /api/observability/v1/oncall-schedules`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-048.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OncallScheduleCreate`; trường bắt buộc: `scheduleCode`, `group`, `rotation`, `escalationOrder`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `OncallSchedule`; trường bắt buộc: `scheduleCode`, `group`, `rotation`, `escalationOrder`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-034, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm hở khoảng, chồng ca, hai kênh độc lập cho nhóm Nghiêm trọng.
:::

#### API-13-047 · Sửa lịch trực

::: dac-ta
**Mục đích.** Sửa lịch trực.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/oncall-schedules/{scheduleCode}`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-048.

**Tham số.** `scheduleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OncallSchedulePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OncallSchedule`; trường bắt buộc: `scheduleCode`, `group`, `rotation`, `escalationOrder`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-034 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-048 · Danh sách kênh thông báo

::: dac-ta
**Mục đích.** Danh sách kênh thông báo.

**Phương thức, đường dẫn.** `GET /api/observability/v1/notification-channels`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-048.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `kind` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationChannelPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không trả bí mật của kênh; chỉ tham chiếu OpenBao.
:::

#### API-13-049 · Tạo kênh thông báo

::: dac-ta
**Mục đích.** Tạo kênh thông báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/notification-channels`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-048.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationChannelCreate`; trường bắt buộc: `channelCode`, `kind`, `target`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `NotificationChannel`; trường bắt buộc: `channelCode`, `kind`, `target`, `enabled`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-033, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bí mật webhook ghi một chiều (`writeOnly`), lưu ở OpenBao.
:::

#### API-13-050 · Sửa kênh thông báo

::: dac-ta
**Mục đích.** Sửa kênh thông báo.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/notification-channels/{channelCode}`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-048.

**Tham số.** `channelCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationChannelPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationChannel`; trường bắt buộc: `channelCode`, `kind`, `target`, `enabled`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-051 · Gửi thử qua kênh thông báo

::: dac-ta
**Mục đích.** Gửi thử qua kênh thông báo.

**Phương thức, đường dẫn.** `POST /api/observability/v1/notification-channels/{channelCode}:test`.

**Quyền.** `PERM-13-alert-admin`.

**FR hiện thực.** FR-13-048.

**Tham số.** `channelCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChannelTestResult`; trường bắt buộc: `ok`, `testedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi một thông báo thử; kết quả thật, không giả lập.
:::

### An ninh, SIEM và báo cáo sự cố

#### API-13-054 · Danh sách luật phát hiện UC-SEC

::: dac-ta
**Mục đích.** Danh sách luật phát hiện UC-SEC.

**Phương thức, đường dẫn.** `GET /api/observability/v1/detection-rules`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-051.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `enabled` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DetectionRulePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-055 · Tinh chỉnh ngưỡng luật phát hiện

::: dac-ta
**Mục đích.** Tinh chỉnh ngưỡng luật phát hiện.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/detection-rules/{ruleCode}`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-051.

**Tham số.** `ruleCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DetectionRulePatch`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DetectionRule`; trường bắt buộc: `ruleCode`, `name`, `threshold`, `severity`, `enabled`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-024, ERR-13-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần lý do và xác thực lại phiên (step-up).
:::

#### API-13-056 · Danh sách cảnh báo an ninh

::: dac-ta
**Mục đích.** Danh sách cảnh báo an ninh.

**Phương thức, đường dẫn.** `GET /api/observability/v1/security-alerts`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-052, FR-13-053.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `status` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `ruleCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlertPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-057 · Chi tiết cảnh báo an ninh

::: dac-ta
**Mục đích.** Chi tiết cảnh báo an ninh.

**Phương thức, đường dẫn.** `GET /api/observability/v1/security-alerts/{alertId}`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-053.

**Tham số.** `alertId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlert`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bằng chứng đã che giá trị Nhạy cảm.
:::

#### API-13-058 · Tiếp nhận cảnh báo an ninh

::: dac-ta
**Mục đích.** Tiếp nhận cảnh báo an ninh.

**Phương thức, đường dẫn.** `POST /api/observability/v1/security-alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-053.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AckRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-059 · Đóng cảnh báo an ninh kèm kết luận

::: dac-ta
**Mục đích.** Đóng cảnh báo an ninh kèm kết luận.

**Phương thức, đường dẫn.** `POST /api/observability/v1/security-alerts/{alertId}:close`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-053.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SecurityCloseRequest`; trường bắt buộc: `verdict`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020, ERR-13-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ba kết luận: sự cố thật, báo nhầm, chấp nhận rủi ro (BR-13-024).
:::

#### API-13-060 · Đề xuất tạm ngừng HTTT

::: dac-ta
**Mục đích.** Đề xuất tạm ngừng HTTT.

**Phương thức, đường dẫn.** `POST /api/observability/v1/security-alerts/{alertId}:propose-suspension`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-053.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProposeSuspensionRequest`; trường bắt buộc: `systemCode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-020, ERR-13-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đề xuất; quyết định ở PH-01 (EVT-13-04).
:::

#### API-13-061 · Danh sách mục tiêu SIEM

::: dac-ta
**Mục đích.** Danh sách mục tiêu SIEM.

**Phương thức, đường dẫn.** `GET /api/observability/v1/siem-targets`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-054.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SiemTargetPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-062 · Tạo mục tiêu SIEM

::: dac-ta
**Mục đích.** Tạo mục tiêu SIEM.

**Phương thức, đường dẫn.** `POST /api/observability/v1/siem-targets`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SiemTargetCreate`; trường bắt buộc: `targetCode`, `protocol`, `endpoint`, `schema`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SiemTarget`; trường bắt buộc: `targetCode`, `protocol`, `endpoint`, `schema`, `enabled`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `423`; mã lỗi của thao tác: ERR-13-002, ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-037, ERR-13-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bí mật hoặc chứng thư client ghi một chiều (`writeOnly`).
:::

#### API-13-063 · Sửa mục tiêu SIEM

::: dac-ta
**Mục đích.** Sửa mục tiêu SIEM.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/siem-targets/{targetCode}`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-054.

**Tham số.** `targetCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SiemTargetPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SiemTarget`; trường bắt buộc: `targetCode`, `protocol`, `endpoint`, `schema`, `enabled`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-064 · Gửi thử tới mục tiêu SIEM

::: dac-ta
**Mục đích.** Gửi thử tới mục tiêu SIEM.

**Phương thức, đường dẫn.** `POST /api/observability/v1/siem-targets/{targetCode}:test`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-054.

**Tham số.** `targetCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChannelTestResult`; trường bắt buộc: `ok`, `testedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-065 · Sinh báo cáo sự cố từ cảnh báo an ninh

::: dac-ta
**Mục đích.** Sinh báo cáo sự cố từ cảnh báo an ninh.

**Phương thức, đường dẫn.** `POST /api/observability/v1/incident-reports:generate`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-055.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentReportRequest`; trường bắt buộc: `kind`, `alertIds`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IncidentReport`; trường bắt buộc: `reportId`, `kind`, `status`, `content`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `423`; mã lỗi của thao tác: ERR-13-003, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mẫu theo SEC-74; báo cáo vi phạm dữ liệu cá nhân theo NĐ 356/2025.
:::

#### API-13-066 · Chi tiết báo cáo sự cố

::: dac-ta
**Mục đích.** Chi tiết báo cáo sự cố.

**Phương thức, đường dẫn.** `GET /api/observability/v1/incident-reports/{reportId}`.

**Quyền.** `PERM-13-security`.

**FR hiện thực.** FR-13-055.

**Tham số.** `reportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IncidentReport`; trường bắt buộc: `reportId`, `kind`, `status`, `content`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `Accept: application/pdf` để tải bản in.
:::

### Dịch vụ cho phân hệ khác

#### API-13-067 · Truy vấn số liệu tổng hợp cho PH-16

::: dac-ta
**Mục đích.** Truy vấn số liệu tổng hợp cho PH-16.

**Phương thức, đường dẫn.** `POST /api/observability/v1/metrics:query`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-056.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MetricsQueryRequest`; trường bắt buộc: `metric`, `from`, `to`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MetricsQueryResult`; trường bắt buộc: `metric`, `series`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-005, ERR-13-006, ERR-13-010, ERR-13-011, ERR-13-014, ERR-13-015, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `obs:metrics-read`. Chỉ số đã gom, không có dữ liệu thô của người dùng.
:::

#### API-13-068 · Tóm tắt số liệu theo kỳ cho PH-16

::: dac-ta
**Mục đích.** Tóm tắt số liệu theo kỳ cho PH-16.

**Phương thức, đường dẫn.** `GET /api/observability/v1/metrics/summary`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-056.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MetricsSummary`; trường bắt buộc: `period`, `totals`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-010, ERR-13-014, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `obs:metrics-read`.
:::

#### API-13-069 · Ngữ cảnh chẩn đoán theo trace_id cho PH-18

::: dac-ta
**Mục đích.** Ngữ cảnh chẩn đoán theo trace_id cho PH-18.

**Phương thức, đường dẫn.** `GET /api/observability/v1/diagnostics/{traceId}`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-057.

**Tham số.** `traceId` (path, TraceId, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Diagnostics`; trường bắt buộc: `traceId`, `found`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-010, ERR-13-014, ERR-13-030, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `obs:diagnostics-read`. Log lỗi đã che; không trả thân thông điệp nghiệp vụ.
:::

### Tham số quan sát

#### API-13-070 · Tham số quan sát 13.* của tenant

::: dac-ta
**Mục đích.** Tham số quan sát 13.* của tenant.

**Phương thức, đường dẫn.** `GET /api/observability/v1/settings`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-008, FR-13-061.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `params`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm miền, mặc định và phạm vi sửa của từng khóa.
:::

#### API-13-071 · Sửa tham số, hạn mức, kiểm tra tổng hợp

::: dac-ta
**Mục đích.** Sửa tham số, hạn mức, kiểm tra tổng hợp.

**Phương thức, đường dẫn.** `PATCH /api/observability/v1/settings`.

**Quyền.** `PERM-13-admin`.

**FR hiện thực.** FR-13-008, FR-13-061.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsPatch`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `params`, `version`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`, `423`; mã lỗi của thao tác: ERR-13-003, ERR-13-007, ERR-13-009, ERR-13-010, ERR-13-016, ERR-13-040, ERR-13-041 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có hiệu lực trong 60 giây (NFR-13-030); ghi kiểm toán `OBS.SETTINGS.UPDATE`.
:::

### Vòng đời tenant

#### API-13-072 · Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới

::: dac-ta
**Mục đích.** Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/observability:provision`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-059.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProvisionRequest`; trường bắt buộc: `sizing`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ProvisionResult`; trường bắt buộc: `tenantCode`, `state`, `steps`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-010, ERR-13-014, ERR-13-037, ERR-13-042, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `obs:tenant-provision`. Lũy đẳng theo `Idempotency-Key` và tenant; sáu bước S1…S6 ghi vào sổ bước.
:::

#### API-13-073 · Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập

::: dac-ta
**Mục đích.** Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/audit-chain:close`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-060.

**Tham số.** `tenantCode` (path, TenantCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CloseChainRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `CloseChainResult`; trường bắt buộc: `tenantCode`, `status`, `headSeq`, `headHash`, `finalAnchorId`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-010, ERR-13-014, ERR-13-037, ERR-13-043, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `obs:tenant-provision`. Neo cuối `FINAL`; không nhận thêm bản ghi (ERR-13-043).
:::

### Tra cứu nhật ký kiểm toán

#### API-13-074 · Tra cứu nhật ký kiểm toán

::: dac-ta
**Mục đích.** Tra cứu nhật ký kiểm toán.

**Phương thức, đường dẫn.** `POST /api/audit/v1/records:search`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-020, FR-13-023.

**Tham số.** `cursor` (query, string, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** application/json: `AuditSearchRequest`; trường bắt buộc: `from`, `to`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditRecordPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-005, ERR-13-009, ERR-13-010, ERR-13-011, ERR-13-012, ERR-13-013, ERR-13-014, ERR-13-015, ERR-13-028, ERR-13-029, ERR-13-031, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi lượt tra ghi `AUDIT.QUERY` (FR-13-019); cần lý do và xác thực lại phiên.
:::

#### API-13-075 · Chi tiết bản ghi kiểm toán và xác minh băm

::: dac-ta
**Mục đích.** Chi tiết bản ghi kiểm toán và xác minh băm.

**Phương thức, đường dẫn.** `GET /api/audit/v1/records/{auditId}`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-021.

**Tham số.** `auditId` (path, string, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditRecordDetail`; trường bắt buộc: `record`, `verification`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-014, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả kèm kết quả tính lại băm và neo bao phủ bản ghi.
:::

#### API-13-076 · Lịch sử theo đối tượng cho tab Lịch sử

::: dac-ta
**Mục đích.** Lịch sử theo đối tượng cho tab Lịch sử.

**Phương thức, đường dẫn.** `GET /api/audit/v1/objects/{objectType}/{objectId}/history`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-022.

**Tham số.** `objectType` (path, string, bắt buộc); `objectId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ObjectHistoryPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-003, ERR-13-010, ERR-13-014, ERR-13-038, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `audit:history-read`. DU gọi tự kiểm tra quyền `read` của đối tượng trước khi gọi.
:::

#### API-13-085 · Báo cáo truy cập liên tenant

::: dac-ta
**Mục đích.** Báo cáo truy cập liên tenant.

**Phương thức, đường dẫn.** `GET /api/audit/v1/cross-tenant-access`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-025.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `actorId` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CrossTenantAccessPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quản trị tỉnh thấy mọi phiên vào tenant của mình.
:::

### Toàn vẹn, neo và đối chiếu

#### API-13-077 · Yêu cầu kiểm tra toàn vẹn chuỗi theo yêu cầu

::: dac-ta
**Mục đích.** Yêu cầu kiểm tra toàn vẹn chuỗi theo yêu cầu.

**Phương thức, đường dẫn.** `POST /api/audit/v1/verifications`.

**Quyền.** `PERM-13-audit-export`.

**FR hiện thực.** FR-13-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VerificationRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Verification`; trường bắt buộc: `verificationId`, `scope`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-13-003, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-028, ERR-13-032, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc từ bản sao chỉ-đọc; kết quả bằng EVT-13-07.
:::

#### API-13-078 · Danh sách lượt kiểm tra toàn vẹn

::: dac-ta
**Mục đích.** Danh sách lượt kiểm tra toàn vẹn.

**Phương thức, đường dẫn.** `GET /api/audit/v1/verifications`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-014.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `status` (query, string, tùy chọn); `scope` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VerificationPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-079 · Kết quả một lượt kiểm tra toàn vẹn

::: dac-ta
**Mục đích.** Kết quả một lượt kiểm tra toàn vẹn.

**Phương thức, đường dẫn.** `GET /api/audit/v1/verifications/{verificationId}`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-014, FR-13-015.

**Tham số.** `verificationId` (path, string, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Verification`; trường bắt buộc: `verificationId`, `scope`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nếu đứt chuỗi, trả vị trí `firstBreakSeq` và mã ERR-13-109 hoặc ERR-13-110.
:::

#### API-13-080 · Danh sách neo băm

::: dac-ta
**Mục đích.** Danh sách neo băm.

**Phương thức, đường dẫn.** `GET /api/audit/v1/anchors`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-012, FR-13-021.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AnchorPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-081 · Chi tiết neo băm

::: dac-ta
**Mục đích.** Chi tiết neo băm.

**Phương thức, đường dẫn.** `GET /api/audit/v1/anchors/{anchorId}`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-012.

**Tham số.** `anchorId` (path, string, bắt buộc); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Anchor`; trường bắt buộc: `anchorId`, `kind`, `seqLast`, `hashLast`, `anchoredAt`, `signature`, `keyVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm chữ ký, phiên bản khóa, đối tượng WORM và xác nhận SIEM.
:::

#### API-13-086 · Kết quả đối chiếu số bản ghi theo DU

::: dac-ta
**Mục đích.** Kết quả đối chiếu số bản ghi theo DU.

**Phương thức, đường dẫn.** `GET /api/audit/v1/reconciliations`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-017.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `du` (query, string, tùy chọn); `status` (query, string, tùy chọn); `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReconciliationPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-13-003, ERR-13-009, ERR-13-010, ERR-13-036, ERR-13-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-087 · Trạng thái chuỗi kiểm toán của tenant

::: dac-ta
**Mục đích.** Trạng thái chuỗi kiểm toán của tenant.

**Phương thức, đường dẫn.** `GET /api/audit/v1/chain-status`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-011, FR-13-013, FR-13-016.

**Tham số.** `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChainStatus`; trường bắt buộc: `tenantId`, `status`, `integrity`, `headSeq`, `headHash`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gồm đầu chuỗi, neo gần nhất, lô WORM chờ sao, số bản ghi đệm.
:::

#### API-13-088 · Danh sách phân vùng kiểm toán

::: dac-ta
**Mục đích.** Danh sách phân vùng kiểm toán.

**Phương thức, đường dẫn.** `GET /api/audit/v1/partitions`.

**Quyền.** `PERM-13-audit-read`.

**FR hiện thực.** FR-13-018.

**Tham số.** `targetTenant` (query, TenantCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartitionList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-13-009, ERR-13-010, ERR-13-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

### Xuất bằng chứng

#### API-13-082 · Yêu cầu xuất bằng chứng kiểm toán ký số

::: dac-ta
**Mục đích.** Yêu cầu xuất bằng chứng kiểm toán ký số.

**Phương thức, đường dẫn.** `POST /api/audit/v1/exports`.

**Quyền.** `PERM-13-audit-export`.

**FR hiện thực.** FR-13-024.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportRequest`; trường bắt buộc: `from`, `to`, `reason`, `basis`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Export`; trường bắt buộc: `exportId`, `status`, `requestedAt`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-13-003, ERR-13-004, ERR-13-008, ERR-13-009, ERR-13-010, ERR-13-012, ERR-13-013, ERR-13-025, ERR-13-028, ERR-13-029, ERR-13-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy nền; không tạo tệp chưa ký (BR-13-014).
:::

#### API-13-083 · Trạng thái yêu cầu xuất bằng chứng

::: dac-ta
**Mục đích.** Trạng thái yêu cầu xuất bằng chứng.

**Phương thức, đường dẫn.** `GET /api/audit/v1/exports/{exportId}`.

**Quyền.** `PERM-13-audit-export`.

**FR hiện thực.** FR-13-024.

**Tham số.** `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Export`; trường bắt buộc: `exportId`, `status`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

#### API-13-084 · Tải gói bằng chứng

::: dac-ta
**Mục đích.** Tải gói bằng chứng.

**Phương thức, đường dẫn.** `GET /api/audit/v1/exports/{exportId}/download`.

**Quyền.** `PERM-13-audit-export`.

**FR hiện thực.** FR-13-024.

**Tham số.** `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `Content-Disposition`, `X-Evidence-Signature`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `503`; mã lỗi của thao tác: ERR-13-001, ERR-13-009, ERR-13-010, ERR-13-026, ERR-13-027, ERR-13-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Liên kết hiệu lực `13.export.link-ttl-minutes`; mỗi lượt tải ghi kiểm toán.
:::

### Nội bộ (DU nguồn)

#### API-13-089 · Ghi lô bản ghi kiểm toán dự phòng

::: dac-ta
**Mục đích.** Ghi lô bản ghi kiểm toán dự phòng.

**Phương thức, đường dẫn.** `POST /api/audit/v1/internal/records:batch`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-010, FR-13-016.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AuditBatchRequest`; trường bắt buộc: `records`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `AuditBatchResult`; trường bắt buộc: `accepted`, `duplicate`, `quarantined`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-13-003, ERR-13-010, ERR-13-043, ERR-13-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Token dịch vụ, scope `audit:write`. Kênh dự phòng khi Kafka không với tới; danh tính DU lấy từ token, tenant từ token.
:::

### Nội bộ (Alertmanager)

#### API-13-090 · Nhận cảnh báo từ Alertmanager

::: dac-ta
**Mục đích.** Nhận cảnh báo từ Alertmanager.

**Phương thức, đường dẫn.** `POST /api/observability/v1/internal/alertmanager:webhook`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-13-044.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AlertmanagerWebhook`; trường bắt buộc: `version`, `status`, `alerts`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công.

**Lỗi.** HTTP `400`, `503`; mã lỗi của thao tác: ERR-13-003, ERR-13-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ Alertmanager gọi, xác thực mTLS. Webhook v4, lô tối đa 100 cảnh báo; lũy đẳng theo `(tenant, rule_code, fingerprint)`; lỗi cơ sở dữ liệu trả 503 để Alertmanager gửi lại.
:::

<!-- gen:dac-ta-api:end -->

## 11. Đề nghị đồng bộ

Tập này không sửa tài liệu dùng chung và không tạo ADR; bảng dưới là việc cho các luồng khác. Các đề nghị về quyền và scope (D02-08) đã ở FRS §3.4 và không lặp lại.

| Tài liệu | Đề nghị |
|---|---|
| D02-03-PH13 (FRS) | §9.4 đã khớp 90 mã; bổ sung ghi chú: API-13-084 có thể trả ERR-13-026 (503) khi không kiểm lại được chữ ký trước khi phát tệp; API-13-077 cần `PERM-13-audit-export` (đúng ma trận §3.2) nên giao diện UI-13-14 ẩn nút "Kiểm tra ngay" với AU không có quyền xuất; thêm `allowedActions` vào danh sách phản hồi của cảnh báo, cảnh báo an ninh, luật, yêu cầu xuất |
| D03-06-PH13 (màn hình) | Dùng `allowedActions`, `disabledReasons` để bật, tắt nút; câu thông báo lấy từ FRS §9.2; tab Lịch sử của phân hệ chủ gọi API-13-076 qua BFF của DU chứ không từ trình duyệt; luồng SSE của UI-13-07 xử lý `closed` với `reason` `IDLE`, `LIMIT`, `QUOTA` |
| D03-04-PH03 (Cổng API) | Công bố `/api/observability/v1` và `/api/audit/v1` cho BFF console; giữ `/api/platform/v1` và mọi `/internal/*` chỉ ở `apisix-int`; plugin `kafka-logger` ghi `{tenant}.obs.access.logged.v1` theo lược đồ `AccessLogged` ở AsyncAPI PH-13; không cắt `traceparent` |
| D03-04-PH12 (nếu có) | `StepUpApi` trả thời điểm xác thực gần nhất và `acr`; claim `xt_session` cho phiên liên tenant (Q13-57, Q13-58); `PermissionApi` kiểm `PERM-13-*` theo bảng chương 3 |
| D03-04-PH16, D03-04-PH18, D03-04-PH20 | Dùng đúng scope và đường dẫn: PH-16 API-13-067, 068; PH-18 API-13-069 và `NotificationApi` (IF-09); PH-20 API-13-072, 073 (hoặc `TenantObservabilityApi` khi cùng DU); thân và lược đồ tham chiếu OpenAPI PH-13 |
| D03-04-PH10 (Sự kiện) | Cấp topic `{tenant}.obs.*` và ACL cho DU nguồn qua ADR-072: `audit.recorded` giữ 7 ngày 6 phân vùng khóa `id`; `access.logged` giữ 3 ngày 6 phân vùng khóa `route`; EVT-13-04, 05, 12 giữ 30 ngày (giả định ở mục 4) |
| D03-09 (hạ tầng) | Địa chỉ dịch vụ trong cụm `dh-platform.dh-control.svc:8080` cho ba nhóm API; mTLS giữa Alertmanager và `dh-platform` cho API-13-090 (SPIFFE ID, SEC-15) |
| D04-01 (quy ước mã) | Luật Spectral kiểm khóa `x-datahub-errors` và `x-datahub-permission` (bốn dạng: `permission`, `anyOf`, `serviceScope`, `mtls`) ở CI-5 |
| D00-04 (sổ tra cứu) | Dải đã dùng của PH-13 sau tập này: `API-13-001…090`, `EVT-13-01…14`, `ERR-13-001…126`, câu hỏi `Q13-55…59`; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` ở đợt đồng bộ cuối |
| ADR | Không đề xuất ADR mới ở tập này; các đề xuất ADR 014, 015, 039 của SDD §13.4 vẫn có hiệu lực |

: Đề nghị đồng bộ cho tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-API và quy chuẩn K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu, quy ước chung, xác thực, danh mục 90 endpoint, 14 sự kiện và hai topic vào, hợp đồng với phân hệ khác, bảng mã lỗi, kiểm tra hợp đồng, ánh xạ hệ cũ, 5 câu hỏi mở (Q13-55…59), chương đặc tả từng endpoint sinh từ OpenAPI, đề nghị đồng bộ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: tiêu đề X-DH-Grant-Id thay claim xt_session, ETag và ánh xạ lỗi CSDL, sessionId, spansTotal, quarantineCount |
