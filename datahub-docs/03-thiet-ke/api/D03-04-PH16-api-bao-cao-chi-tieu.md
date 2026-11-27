---
ma_tai_lieu: D03-04-PH16
ten: Đặc tả API và sự kiện phân hệ PH-16 Báo cáo chỉ tiêu và sổ kiến trúc
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kỹ sư tích hợp PH-01, PH-02, PH-14, PH-17, kiểm thử viên, hội đồng thẩm định
phan_he: PH-16
mo_ta: Hợp đồng REST gồm 130 operation gốc /api/kpi/v1 và 14 sự kiện phát, 18 sự kiện tiêu thụ của PH-16 Báo cáo chỉ tiêu và sổ kiến trúc, kèm quy ước, quyền, scope máy, mã lỗi RFC 9457, thông báo hiển thị, kiểm tra hợp đồng và đề nghị đồng bộ.
tai_lieu_lien_quan: D02-03-PH16 FRS; D03-03-PH16 CSDL; D03-04-PH08; D03-04-PH14; D03-04-PH02; D05-02-PH16 Test case
---

# D03-04-PH16 · Đặc tả API và sự kiện Báo cáo chỉ tiêu và sổ kiến trúc

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của PH-16 Báo cáo chỉ tiêu và sổ kiến trúc: nơi lãnh đạo UBND và các sở biết chuyển đổi số về kết nối, chia sẻ dữ liệu của tỉnh đang ở đâu so với mục tiêu, số liệu lấy từ đâu và ai đã xác nhận. PH-16 tính tự động các chỉ số đo KPI-01…18 của BRD cùng sáu chỉ tiêu bổ sung từ số liệu mà các phân hệ khác đã tổng hợp, lập báo cáo tháng, quý, năm, giữ sổ kiến trúc tối thiểu và gửi báo cáo, sổ kiến trúc lên hệ quốc gia qua PH-14. PH-16 công bố **130 operation REST** gốc `/api/kpi/v1` (module `kpi` và `arch` của `dh-platform`), **14 sự kiện** `EVT-16-01…14` và nhận 18 sự kiện của PH-01, 02, 04, 05, 07, 08, 10, 14, 19. Mã API-16-001…130 giữ đúng phương thức, đường dẫn và FR của FRS 9.4.

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph16/openapi-kpi.yaml`](ph16/openapi-kpi.yaml): OpenAPI 3.1, mỗi operation có ví dụ yêu cầu (khi có thân) và phản hồi; các ví dụ khớp lược đồ theo [`check_contracts.py`](ph16/tools/check_contracts.py); `openapi-spec-validator` và Spectral (`build/tools/spectral.yaml`) không có lỗi.
- [`ph16/asyncapi-kpi.yaml`](ph16/asyncapi-kpi.yaml): AsyncAPI 3.0, 32 kênh (14 phát, 18 nhận), 32 ví dụ khớp payload; Spectral không có lỗi.

Năm nguyên tắc hợp đồng:

1. **PH-16 không tự sinh dữ liệu thô.** Số liệu vào bằng sự kiện Kafka, kéo API chỉ số theo lịch (`PULL_API`), đẩy qua `POST /ingest/observations` (scope `kpi.ingest`) hoặc nhập tay kèm bằng chứng; mỗi giá trị chỉ tiêu truy được về quan sát và phiên bản công thức (API-16-054).
2. **Công thức, ngưỡng, mục tiêu, mẫu gói quốc gia là cấu hình có phiên bản** và qua duyệt bốn mắt (ERR-16-005); khung chỉ số quốc gia chưa ban hành nên mọi con số nằm ở dữ liệu, không ở mã.
3. **Thiếu nguồn vẫn ra số phần đã có, gắn nhãn `PARTIAL`, không bịa số;** báo cáo chính thức bị chặn khi thiếu chỉ tiêu bắt buộc (ERR-16-029).
4. **Báo cáo đã công bố bất biến** (PDF ký số, mã băm, kho WORM 10 năm); sửa bằng phiên bản đính chính (API-16-075), không có API sửa trực tiếp (ERR-16-032).
5. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động có `If-Match`;** PH-16 không gọi thẳng hệ quốc gia, gói đi qua PH-14 và biên nhận trả về qua `/internal`.

Căn cứ: FRS D02-03-PH16 §3.2, §9 và Phụ lục A; CSDL D03-03-PH16 (schema `ph16_kpi`). Mọi tên miền, dữ liệu trong ví dụ là giả lập, tenant T68, kỳ `M-2026-10`, `Q-2026-Q3`, `Y-2026`.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả mặt giao tiếp của PH-16 đủ để kỹ sư `dh-platform` hiện thực, kỹ sư PH-01, PH-02, PH-14, PH-17 và phân hệ nguồn tích hợp, kiểm thử viên viết ca kiểm thử hợp đồng.

### 0.2. Phạm vi

Gồm API REST của module `kpi` (chỉ tiêu, nguồn, kỳ, báo cáo, gửi quốc gia) và `arch` (sổ kiến trúc, tuân thủ), sự kiện Kafka phát và nhận, quyền, scope, mã lỗi. Không gồm giám sát thời gian thực, cảnh báo vận hành, kiểm toán tập trung (PH-13); danh mục API, SLA (PH-02); điểm chất lượng (PH-08); danh mục dùng chung (PH-07); kết nối, ký, gửi tới nền tảng quốc gia (PH-14); hộp việc, lịch job (PH-18); trợ lý hỏi đáp số liệu (PH-17, chỉ đọc qua `kpi.read`).

### 0.3. Người đọc

Kỹ sư `dh-platform` đọc chương 1, 2, 11; kỹ sư PH-14, PH-17 và phân hệ nguồn đọc 3.1, 3.2, 4, 5; kiểm thử viên đọc 6, 7, 10; hội đồng thẩm định đọc tóm tắt, chương 2 và Phụ lục A.

### 0.4. Thuật ngữ và chữ viết tắt

Bảng giải thích các thuật ngữ riêng của tập này.

| Thuật ngữ | Giải thích |
|---|---|
| Chỉ tiêu (`indicatorCode`) | Một số đo chuyển đổi số có mã, nhóm, loại, đơn vị; công thức, mục tiêu, ngưỡng nằm ở phiên bản định nghĩa |
| Nhóm chỉ tiêu (`groupCode`) | Một trong năm nhóm `KET_NOI`, `CHIA_SE`, `DU_LIEU`, `VAN_HANH`, `KIEN_TRUC` |
| Quan sát (`observation`) | Số liệu đã tổng hợp từ phân hệ nguồn, mang `metricCode` dạng `ph{nn}.{đối-tượng}.{chỉ-số}`, kỳ và `idempotencyRef` |
| Kỳ (`periodCode`) | `M-2026-10` (tháng), `Q-2026-Q3` (quý), `Y-2026` (năm); chốt thì không tính lại nếu không mở lại có lý do |
| Lần tổng hợp (`runId`) | Một lượt tính giá trị chỉ tiêu của kỳ; kết quả `SUCCEEDED`, `PARTIAL` hoặc `FAILED` |
| CEL | Common Expression Language, ngôn ngữ biểu thức của công thức chỉ tiêu, ví dụ `obs("ph01.httt.connected") / obs("ph01.httt.total") * 100` |
| `PARTIAL` | Giá trị hoặc lần tổng hợp thiếu một phần nguồn; có số phần đã có, kèm cờ `MISSING_SOURCE`, `STALE_SOURCE`, `MANUAL_PENDING`, `FORMULA_ERROR` |
| Sổ kiến trúc | Danh sách thành phần (`HTTT`, `API`, `FLOW`, `TOPIC`, `ADAPTER`, `PLATFORM_SERVICE`, `NATIONAL_LINK`), phiên bản, phụ thuộc, mức tuân thủ |
| WORM | Lưu một lần, không sửa, không xóa (Object Lock của Ceph RGW) |
| TA, TO, SO, DS, AU, VW, PA, PO, PU | Vai trò theo D02-08: TA quản trị tỉnh, TO cán bộ tổng hợp, SO an ninh thông tin, DS cán bộ dữ liệu, AU kiểm toán, VW lãnh đạo xem, PA quản trị nền tảng, PO vận hành nền tảng, PU kiểm toán nền tảng |

: Thuật ngữ và chữ viết tắt của tập API PH-16

### 0.5. Tài liệu tham chiếu

FRS D02-03-PH16 (nguồn chuẩn mã FR, ERR, EVT, PERM, enum, danh mục API), CSDL D03-03-PH16 (tên cột, camelCase ở API), D02-08 (ma trận quyền), D03-04-PH08 (EVT-08-14, API-08-122), D03-04-PH02, D03-04-PH01 (bên phát sự kiện), D03-04-PH14 (kênh gửi quốc gia), `docs/07-srs/SRS-PH-16-nas-kpi.md` (mục M5, API cũ).

### 0.6. Cấu trúc tài liệu

Chương 1, 2: quy ước và quyền; 3, 4, 5: endpoint, sự kiện, hợp đồng với phân hệ khác; 6, 7: mã lỗi và kiểm tra; 8, 9: hệ cũ và câu hỏi mở; 10: truy vết FR; 11: đặc tả từng endpoint; Phụ lục A: đề nghị đồng bộ.

## 1. Quy ước chung

Quy ước áp dụng cho mọi operation. Cột "Khóa" ở chương 3: `I` là bắt buộc `Idempotency-Key`, `M` là bắt buộc `If-Match`.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/kpi/v1`: BFF console của tenant, trong cụm `dh-platform.dh-platform.svc`, cổng API cho máy gọi. `/api/kpi/v1/internal/*` (API-16-124) chỉ trong mạng nội bộ cho PH-14. `/ingest/*` dành cho tài khoản máy, `/feed/*` và `/cards` cho `kpi.read` |
| Phiên bản | `v1`; thay đổi phá vỡ sang `v2`, chạy song song tối thiểu 6 tháng; oasdiff ở CI chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ phiên hoặc thông tin xác thực máy (claim `tenant`), không từ thân hay đường dẫn; đối tượng của tenant khác trả `404` ERR-16-001. Chỉ tiêu mẫu `COMMON` do PA quản lý ở tenant `COMMON` |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập (`:approve`, `:close`, `:adopt-common`) |
| Khóa lạc quan | `GET` trả `ETag: W/"{n}"`; `PUT`, `PATCH` và hành động trên tài nguyên có `If-Match`; lệch trả `409` ERR-16-004, thiếu trả `428` ERR-00-428. Hành động không đổi trạng thái tài nguyên (thử nguồn, xem trước, nhận biên nhận, chạy bất đồng bộ) không có `If-Match` |
| Chống trùng | `POST` tạo hoặc chạy bất đồng bộ bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân `409` ERR-16-058. Quan sát qua `kpi.ingest` còn khử trùng theo `idempotencyRef` của từng phần tử (ERR-16-103) |
| Phân trang | `page` (từ 0), `size` (1…200, mặc định 20; Q16-55); phản hồi `items`, `page`, `size`, `totalElements`. Mọi danh sách có hai tham số này nên chương 11 không lặp lại |
| Lỗi | RFC 9457 `application/problem+json`, `type = https://datahub.gov.vn/errors/{code}`, `code`, `traceId`, `errors[]` theo trường |
| Mã lỗi chung | Mọi operation có thể trả `401`, `403` (ERR-00-401, ERR-00-403), ERR-16-001 (không thấy), ERR-16-003 (sai lược đồ), ERR-16-004 (`If-Match` lệch), ERR-16-006 (sai trạng thái), ERR-16-057 (tham số danh sách sai), ERR-16-058 (`Idempotency-Key` dùng lại với thân khác); lệnh có `M` thiếu `If-Match` trả `428`. Chương 11 chỉ nêu mã riêng của từng operation |
| Tham số đường dẫn | Các `{…}` trong đường dẫn, kiểu chuỗi theo mẫu mã hoặc UUID, bắt buộc; chương 11 không lặp lại |
| Tác vụ dài | Tổng hợp, xuất, đối chiếu, gửi quốc gia trả `202` kèm tài nguyên ở trạng thái `QUEUED` hoặc `SENDING`; theo dõi bằng `GET` và sự kiện EVT-16-05, 12, 13 |
| Thân lô | `POST /ingest/observations` và `/ingest/arch-components` nhận tối đa 500 phần tử; `202` khi mọi phần tử được nhận, `207` khi có phần tử lỗi (chỉ API-16-030) |
| Tệp | Tải lên bằng `multipart/form-data` (bằng chứng, XLSX nhập) tối đa `16.manual.max-file-mb` (20 MB); tải xuống trả tệp trực tiếp, liên kết hết hạn sau `16.export.link-hours` (410 ERR-16-035) |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-platform`, Kafka; `Accept-Language: vi` (mặc định) hoặc `en` |
| Thời gian, số | Thời điểm ISO 8601 có múi giờ; kỳ theo mẫu `periodCode`; giá trị chỉ tiêu là số thập phân, `displayValue` đã làm tròn theo `decimals` |

: Quy ước chung của API PH-16

## 2. Xác thực và phân quyền

Người dùng vào qua BFF console bằng OIDC và PKCE (phiên không ra trình duyệt), quyền `PERM-16-*`. Máy gọi máy dùng OAuth 2.1 `client_credentials` kèm mTLS, scope `kpi.read`, `kpi.ingest`, `arch.register`. PH-14 vào `/internal` qua mTLS mesh, chỉ `apisix-int`.

### 2.1. Quyền người dùng

Quyền theo FRS 3.2 (D02-08 hiện có `PERM-16-read`, `PERM-16-admin`; mười hai quyền còn lại là đề nghị, Phụ lục A); cột "Quyền" ở chương 3 và `x-datahub-permission` là nguồn chi tiết; "a hoặc b" là có một trong hai.

| Quyền | Vai trò | Operation tiêu biểu |
|---|---|---|
| `PERM-16-read` | PA, TA, TO, SO, DS, AU, VW, PO, PU | Mọi `GET` chỉ tiêu, kỳ, giá trị, báo cáo đã công bố, bảng điều khiển, sổ kiến trúc, mẫu gói, gói quốc gia (001, 003, 021, 046, 053, 064, 090, 094, 119…) |
| `PERM-16-admin` | TA; PA (ở tenant `COMMON`) | Chỉ tiêu, phiên bản, nhóm, mẫu báo cáo, bộ tiêu chí (002, 005, 007…009, 011, 014…018, 020, 060, 062, 063, 103, 104) |
| `PERM-16-approve` | TA | Duyệt, công bố, đính chính, rút (012, 013, 072…076); hàng đợi duyệt (078) |
| `PERM-16-source` | TA, TO | Đăng ký, sửa, thử, tạm dừng, kéo nguồn; nhật ký tiếp nhận, xử lý lại (022, 024…029, 042, 044, 045) |
| `PERM-16-manual` | TO, SO, DS | Nhập, đính kèm, gửi, xác nhận số liệu tay (032, 034…041) |
| `PERM-16-run` | TA; TO (không chốt, không mở lại); PO (chỉ hủy) | Tạo kỳ, chạy, hủy, tính lại, chốt, mở lại (047, 050, 052, 055, 057, 058) |
| `PERM-16-report` | TA, TO | Lập, sửa, giải trình, làm mới, xem trước, gửi duyệt báo cáo (065, 067…071) |
| `PERM-16-export` | TA, TO; AU (chỉ báo cáo đã công bố) | Xuất, tải, phân phối (079…085) |
| `PERM-16-arch` | TA, TO; PA (ở `COMMON`) | Khai báo, sửa thành phần, phiên bản, phụ thuộc, vòng đời, đối chiếu (095, 097…100, 111, 113) |
| `PERM-16-arch-assess` | TA, SO | Đánh giá tuân thủ, xác nhận, miễn trừ (105…110) |
| `PERM-16-national` | TA | Mẫu gói, lập, gửi, gửi lại, đối soát quốc gia (115, 117, 118, 121, 122, 125) |
| `PERM-16-compare` | PA, PU | So sánh liên tenant ẩn danh (092) |
| `PERM-16-config` | TA; PA (đặt trần) | Tham số `16.*` (128), tình trạng lưu giữ (130) |
| `PERM-16-audit-read` | TA, AU, PU | Nhật ký kiểm toán PH-16 (129), tình trạng lưu giữ (130) |

: Quyền người dùng

Quy tắc vượt quyền chức năng, máy chủ kiểm theo từng yêu cầu:

- **Bốn mắt**: người duyệt khác người soạn, gửi; người xác nhận số liệu tay khác người nhập; người xác nhận đánh giá tuân thủ khác người lập; kể cả khi có đủ quyền (ERR-16-005). Tenant cần ít nhất hai người giữ `PERM-16-approve`.
- **Chỉ tiêu mẫu**: sửa trực tiếp chỉ tiêu `COMMON` ở tenant trả ERR-16-014; tenant kế thừa rồi tùy biến phiên bản của mình.
- **Phạm vi dữ liệu**: tenant khác hoặc đối tượng không được xem trả ERR-16-037; người giữ `PERM-16-manual` chỉ xác nhận số liệu của chỉ tiêu được giao (`confirmerRoles`).
- **Chốt kỳ**: chỉ TA chốt, mở lại; TO chạy và tính lại nhưng không chốt.

### 2.2. Scope máy

Scope cấp ở Keycloak khi đăng ký client; PH-16 gọi đi bằng `dq.read` (PH-08), `catalog:metrics-read` (PH-02) và các scope đọc chỉ số của PH-01, 05, 07, 13, 19, 20 (đề nghị đồng bộ).

| Scope | Cấp cho | Operation | Ghi chú |
|---|---|---|---|
| `kpi.read` | PH-17, cổng thông tin tỉnh, HTTT được cấp | 086, 087, 089 | Đọc giá trị chỉ tiêu, báo cáo đã công bố, thẻ chỉ tiêu; mặc định chỉ kỳ đã chốt (`onlyOfficial = true`) |
| `kpi.ingest` | Phân hệ đẩy quan sát (PH-05, PH-19, PH-20 khi không phát sự kiện) | 030 | Chỉ chỉ số ở hợp đồng của nguồn tương ứng (ERR-16-102) |
| `arch.register` | PH-01, PH-02, PH-04, PH-10, CI/GitOps | 101 | Tự đăng ký thành phần kiến trúc |
| `kpi.national-receipt` | PH-14 (`dh-integration`) | 124 | Biên nhận gói quốc gia; chỉ `/internal` (FRS 3.3) |

: Scope máy

## 3. Danh mục endpoint

Danh mục sinh từ [`ph16/tools/spec.py`](ph16/tools/spec.py) bằng `gen_md.py`, cùng nguồn với OpenAPI. Cột "FR" bỏ tiền tố `FR-16-`; "HTTP" là mã thành công; "read hoặc kpi.read" là người dùng có quyền đó hoặc máy có scope đó; "scope kpi.ingest" là chỉ máy.

<!-- gen:endpoints:start -->
| Mã | Phương thức, đường dẫn | Quyền (PERM-16-) | FR | Khóa | HTTP |
|---|---|---|---|---|---|
| API-16-001 | `GET /indicators` | read | 001, 008 | - | 200 |
| API-16-002 | `POST /indicators` | admin | 002 | I | 201 |
| API-16-003 | `GET /indicators/{indicatorCode}` | read | 001, 006, 039 | - | 200 |
| API-16-004 | `GET /indicators/{indicatorCode}/versions` | read | 006 | - | 200 |
| API-16-005 | `POST /indicators/{indicatorCode}/versions` | admin | 002 | I | 201 |
| API-16-006 | `GET /indicators/{indicatorCode}/versions/{version}` | read | 006 | - | 200 |
| API-16-007 | `PATCH /indicators/{indicatorCode}/versions/{version}` | admin | 003, 004 | M | 200 |
| API-16-008 | `POST /indicators/{indicatorCode}/versions/{version}:validate` | admin | 003 | M | 200 |
| API-16-009 | `POST /indicators/{indicatorCode}/versions/{version}:dry-run` | admin | 003 | M | 200 |
| API-16-010 | `GET /metrics` | read | 003, 009 | - | 200 |
| API-16-011 | `POST /indicators/{indicatorCode}/versions/{version}:submit` | admin | 005 | M | 200 |
| API-16-012 | `POST /indicators/{indicatorCode}/versions/{version}:approve` | approve | 005 | M | 200 |
| API-16-013 | `POST /indicators/{indicatorCode}/versions/{version}:request-changes` | approve | 005 | M | 200 |
| API-16-014 | `POST /indicators/{indicatorCode}/versions/{version}:withdraw` | admin | 005 | M | 200 |
| API-16-015 | `POST /indicators/{indicatorCode}:retire` | admin | 006 | M | 200 |
| API-16-016 | `GET /groups` | read | 007 | - | 200 |
| API-16-017 | `PUT /groups` | admin | 007 | M | 200 |
| API-16-018 | `POST /indicators:adopt-common` | admin | 008 | I | 201 |
| API-16-019 | `GET /common-updates` | read | 008 | - | 200 |
| API-16-020 | `POST /common-updates/{indicatorCode}:decide` | admin | 008 | - | 200 |
| API-16-021 | `GET /sources` | read | 009, 013 | - | 200 |
| API-16-022 | `POST /sources` | source | 009 | I | 201 |
| API-16-023 | `GET /sources/{sourceCode}` | read | 009, 013 | - | 200 |
| API-16-024 | `PATCH /sources/{sourceCode}` | source | 009 | M | 200 |
| API-16-025 | `POST /sources/{sourceCode}:test` | source | 009 | - | 200 |
| API-16-026 | `POST /sources/{sourceCode}:pause` | source | 013 | M | 200 |
| API-16-027 | `POST /sources/{sourceCode}:resume` | source | 013 | M | 200 |
| API-16-028 | `POST /sources/{sourceCode}:retire` | source | 009 | M | 200 |
| API-16-029 | `POST /sources/{sourceCode}:pull` | source | 011 | I | 202 |
| API-16-030 | `POST /ingest/observations` | `kpi.ingest` | 012 | I | 202,207 |
| API-16-031 | `GET /manual-values` | read | 014, 015 | - | 200 |
| API-16-032 | `POST /manual-values` | manual | 014 | I | 201 |
| API-16-033 | `GET /manual-values/{manualId}` | read | 014, 015 | - | 200 |
| API-16-034 | `PATCH /manual-values/{manualId}` | manual | 014 | M | 200 |
| API-16-035 | `POST /manual-values/{manualId}/evidence` | manual | 014 | I | 201 |
| API-16-036 | `GET /manual-values/template` | manual | 014 | - | 200 |
| API-16-037 | `POST /manual-values:import` | manual | 014 | I | 200 |
| API-16-038 | `POST /manual-values/imports/{importId}:commit` | manual | 014 | - | 200 |
| API-16-039 | `POST /manual-values/{manualId}:submit` | manual | 014 | M | 200 |
| API-16-040 | `POST /manual-values/{manualId}:accept` | manual | 015 | M | 200 |
| API-16-041 | `POST /manual-values/{manualId}:reject` | manual | 015 | M | 200 |
| API-16-042 | `GET /sources/{sourceCode}/ingest-logs` | source | 010, 011, 016 | - | 200 |
| API-16-043 | `GET /observations` | read | 010, 016, 039 | - | 200 |
| API-16-044 | `GET /rejected-observations` | source | 010, 016 | - | 200 |
| API-16-045 | `POST /rejected-observations:reprocess` | source | 016 | - | 200 |
| API-16-046 | `GET /periods` | read | 017 | - | 200 |
| API-16-047 | `POST /periods` | run | 017 | I | 201 |
| API-16-048 | `GET /periods/{periodCode}` | read | 017, 020 | - | 200 |
| API-16-049 | `GET /runs` | read | 018, 042 | - | 200 |
| API-16-050 | `POST /periods/{periodCode}/runs` | run | 018 | I | 202 |
| API-16-051 | `GET /runs/{runId}` | read | 018, 020 | - | 200 |
| API-16-052 | `POST /runs/{runId}:cancel` | run | 018 | - | 200 |
| API-16-053 | `GET /runs/{runId}/values` | read | 019, 020, 021 | - | 200 |
| API-16-054 | `GET /values/{valueId}/lineage` | read | 019, 039 | - | 200 |
| API-16-055 | `POST /periods/{periodCode}:recompute` | run | 023 | I | 202 |
| API-16-056 | `GET /periods/{periodCode}/status-changes` | read | 021 | - | 200 |
| API-16-057 | `POST /periods/{periodCode}:close` | run | 024 | M | 200 |
| API-16-058 | `POST /periods/{periodCode}:reopen` | run | 024 | M | 200 |
| API-16-059 | `GET /report-templates` | read | 025 | - | 200 |
| API-16-060 | `POST /report-templates` | admin | 025 | I | 201 |
| API-16-061 | `GET /report-templates/{templateCode}` | read | 025 | - | 200 |
| API-16-062 | `PATCH /report-templates/{templateCode}` | admin | 025 | M | 200 |
| API-16-063 | `POST /report-templates/{templateCode}:preview` | admin | 025 | - | 200 |
| API-16-064 | `GET /reports` | read | 031 | - | 200 |
| API-16-065 | `POST /reports` | report | 026, 032 | I | 201 |
| API-16-066 | `GET /reports/{reportCode}` | read | 027, 031 | - | 200 |
| API-16-067 | `PATCH /reports/{reportCode}` | report | 027 | M | 200 |
| API-16-068 | `PUT /reports/{reportCode}/explanations/{indicatorCode}` | report | 027 | M | 200 |
| API-16-069 | `POST /reports/{reportCode}:refresh` | report | 023, 026 | I+M | 202 |
| API-16-070 | `GET /reports/{reportCode}/preview` | report | 026 | - | 200 |
| API-16-071 | `POST /reports/{reportCode}:submit` | report | 028 | M | 200 |
| API-16-072 | `POST /reports/{reportCode}:approve` | approve | 028 | M | 200 |
| API-16-073 | `POST /reports/{reportCode}:request-changes` | approve | 028 | M | 200 |
| API-16-074 | `POST /reports/{reportCode}:publish` | approve | 029 | M | 200 |
| API-16-075 | `POST /reports/{reportCode}:correct` | approve | 030 | I+M | 201 |
| API-16-076 | `POST /reports/{reportCode}:withdraw` | approve | 030 | M | 200 |
| API-16-077 | `GET /reports/{reportCode}/versions` | read | 031 | - | 200 |
| API-16-078 | `GET /review-queue` | approve hoặc manual | 005, 015, 028 | - | 200 |
| API-16-079 | `POST /exports` | export | 033, 049 | I | 202 |
| API-16-080 | `GET /exports/{exportId}` | export | 033, 049 | - | 200 |
| API-16-081 | `GET /exports/{exportId}/file` | export | 033, 049 | - | 200 |
| API-16-082 | `GET /distributions` | export | 034 | - | 200 |
| API-16-083 | `POST /distributions` | export | 034 | I | 201 |
| API-16-084 | `PATCH /distributions/{distributionCode}` | export | 034 | M | 200 |
| API-16-085 | `GET /distributions/{distributionCode}/deliveries` | export | 034 | - | 200 |
| API-16-086 | `GET /feed/indicator-values` | `kpi.read` | 035 | - | 200 |
| API-16-087 | `GET /feed/reports` | `kpi.read` | 035 | - | 200 |
| API-16-088 | `GET /reports/{reportCode}/evidence` | read | 036 | - | 200 |
| API-16-089 | `GET /cards` | read hoặc `kpi.read` | 037 | - | 200 |
| API-16-090 | `GET /dashboard` | read | 022, 038, 040 | - | 200 |
| API-16-091 | `GET /indicators/{indicatorCode}/series` | read | 039, 040 | - | 200 |
| API-16-092 | `GET /cross-tenant/comparison` | compare | 041 | - | 200 |
| API-16-093 | `GET /ops/overview` | read | 042 | - | 200 |
| API-16-094 | `GET /arch/components` | read | 043 | - | 200 |
| API-16-095 | `POST /arch/components` | arch | 045 | I | 201 |
| API-16-096 | `GET /arch/components/{componentCode}` | read | 043, 045, 046 | - | 200 |
| API-16-097 | `PATCH /arch/components/{componentCode}` | arch | 045 | M | 200 |
| API-16-098 | `POST /arch/components/{componentCode}/versions` | arch | 045 | I | 201 |
| API-16-099 | `PUT /arch/components/{componentCode}/dependencies` | arch | 045 | M | 200 |
| API-16-100 | `POST /arch/components/{componentCode}:change-lifecycle` | arch | 045 | M | 200 |
| API-16-101 | `POST /ingest/arch-components` | `arch.register` | 044 | I | 202 |
| API-16-102 | `GET /compliance/criteria-sets` | read | 047 | - | 200 |
| API-16-103 | `POST /compliance/criteria-sets` | admin | 047 | I | 201 |
| API-16-104 | `POST /compliance/criteria-sets/{version}:activate` | admin | 047 | M | 200 |
| API-16-105 | `POST /arch/components/{componentCode}/assessments` | arch-assess | 047 | I | 201 |
| API-16-106 | `PATCH /arch/assessments/{assessmentId}` | arch-assess | 047 | M | 200 |
| API-16-107 | `POST /arch/assessments/{assessmentId}:submit` | arch-assess | 047 | M | 200 |
| API-16-108 | `POST /arch/assessments/{assessmentId}:confirm` | arch-assess | 047 | M | 200 |
| API-16-109 | `POST /arch/assessments/{assessmentId}:reject` | arch-assess | 047 | M | 200 |
| API-16-110 | `POST /arch/components/{componentCode}/waivers` | arch-assess | 047 | I | 201 |
| API-16-111 | `POST /arch/reconciliations` | arch | 048 | I | 202 |
| API-16-112 | `GET /arch/reconciliations/{reconId}` | read | 048 | - | 200 |
| API-16-113 | `POST /arch/reconciliations/{reconId}/items/{itemId}:resolve` | arch | 048 | - | 200 |
| API-16-114 | `GET /national/templates` | read | 050 | - | 200 |
| API-16-115 | `POST /national/templates` | national hoặc admin | 050 | I | 201 |
| API-16-116 | `GET /national/templates/{templateCode}` | read | 050 | - | 200 |
| API-16-117 | `POST /national/templates/{templateCode}/versions/{version}:activate` | national hoặc admin | 050 | M | 200 |
| API-16-118 | `POST /national/submissions` | national | 051, 052 | I | 201 |
| API-16-119 | `GET /national/submissions` | read | 053 | - | 200 |
| API-16-120 | `GET /national/submissions/{submissionId}` | read | 051, 052, 053 | - | 200 |
| API-16-121 | `POST /national/submissions/{submissionId}:send` | national | 051, 052 | M | 202 |
| API-16-122 | `POST /national/submissions/{submissionId}:retry` | national | 053 | M | 202 |
| API-16-123 | `GET /national/submissions/{submissionId}/logs` | read | 053 | - | 200 |
| API-16-124 | `POST /internal/national/receipts` | `kpi.national-receipt` | 053 | - | 204 |
| API-16-125 | `POST /national/reconciliations` | national | 054 | I | 202 |
| API-16-126 | `GET /national/reconciliations/{reconId}` | read | 054 | - | 200 |
| API-16-127 | `GET /settings` | read | 055 | - | 200 |
| API-16-128 | `PATCH /settings` | config | 055 | M | 200 |
| API-16-129 | `GET /audit-events` | audit-read | 056 | - | 200 |
| API-16-130 | `GET /retention/status` | config hoặc audit-read | 057 | - | 200 |

: Danh mục endpoint PH-16
<!-- gen:endpoints:end -->

### 3.1. Trình tự thu thập số liệu và tổng hợp kỳ

Số liệu đi vào PH-16 theo bốn đường; tổng hợp chạy theo lịch (mặc định 01:30 hằng ngày cho kỳ chưa chốt) hoặc theo yêu cầu.

```{.mermaid caption="Trình tự thu thập, tổng hợp và chốt kỳ"}
sequenceDiagram
  participant S as Phân hệ nguồn
  participant K as Kafka
  participant I as kpi-ingest
  participant TO as TO qua BFF
  participant A as kpi-api
  participant C as kpi-compute
  participant P as PH-13 PH-18
  S-)K: EVT-08-14, EVT-19-07 và các sự kiện nguồn
  K-)I: Bản tin, khử trùng theo id
  I->>I: Chuẩn hóa thành quan sát, kiểm hợp đồng chỉ số
  S->>A: POST /ingest/observations scope kpi.ingest
  A-->>S: 202 hoặc 207 kèm results
  TO->>A: POST /manual-values rồi :submit
  TO->>A: POST /periods/{kỳ}/runs Idempotency-Key
  A-->>TO: 202 runId QUEUED
  C->>C: Tính theo phiên bản công thức ACTIVE, gắn PARTIAL khi thiếu nguồn
  C->>P: EVT-16-05 kỳ tính xong, EVT-16-06 khi chỉ tiêu chệch
  TO->>A: POST /periods/{kỳ}:close TA chốt kỳ
```

Hình cho thấy bên nguồn chỉ giao số đã tổng hợp qua sự kiện hoặc API đẩy; việc tính nằm ở `kpi-compute` và không chặn bên nguồn; kỳ chỉ chốt sau khi tổng hợp xong và TA xác nhận phần `PARTIAL`.

### 3.2. Trình tự lập, duyệt, công bố và gửi quốc gia

Báo cáo chính thức đi qua duyệt bốn mắt, ký số rồi lưu WORM; gửi quốc gia là bước sau và đi qua PH-14.

```{.mermaid caption="Trình tự lập, duyệt, công bố và gửi báo cáo quốc gia"}
sequenceDiagram
  participant TO as TO lập báo cáo
  participant A as kpi-api
  participant TA as TA duyệt
  participant R as Dịch vụ ký và WORM
  participant N as PH-14
  TO->>A: POST /reports rồi PUT giải trình, :submit
  A-->>TO: 200 IN_REVIEW, phát EVT-16-07
  TA->>A: POST /reports/{mã}:approve If-Match
  A-->>TA: 200 APPROVED, người duyệt khác người lập
  TA->>A: POST /reports/{mã}:publish If-Match
  A->>R: Chụp bất biến, dựng PDF, ký số, ghi WORM
  A-->>TA: 200 PUBLISHED contentHash, EVT-16-08
  TA->>A: POST /national/submissions rồi :send
  A->>N: Gói theo mẫu cấu hình, outbox
  N-->>A: POST /internal/national/receipts biên nhận
  A-->>TA: ACKNOWLEDGED, EVT-16-12
```

Hình cho thấy ba điểm: ký số lỗi không làm mất duyệt (báo cáo vẫn `APPROVED`, ERR-16-031); công bố chỉ hoàn tất khi đã ghi WORM; PH-16 không gọi hệ quốc gia, mọi trao đổi đi qua PH-14 và biên nhận làm bằng chứng nộp.

### 3.3. Ví dụ luồng chính

Dữ liệu giả lập, tenant T68, rút gọn trường tùy chọn; ví dụ đầy đủ của mọi operation nằm ở OpenAPI.

<!-- gen:flows:start -->
**API-16-030 · Đẩy quan sát vào qua kpi.ingest**

```http
POST /api/kpi/v1/ingest/observations
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{
 "sourceCode": "ph08-dq-kpi",
 "observations": [{"metricCode": "ph08.dq.score", "value": 92.5, "periodStart": "2026-10-01", "periodEnd": "2026-10-31", "idempotencyRef": "snap-2026-10-31-T68"}]
}
```

```http
HTTP/1.1 202

{"accepted": 1, "duplicate": 0, "rejected": 0, "results": [{"index": 0, "status": "ACCEPTED"}]}
```

**API-16-009 · Thử tính công thức trên kỳ trước**

```http
POST /api/kpi/v1/indicators/httt-ket-noi-ty-le/versions/3:dry-run
If-Match: W/"3"

{"dryRunPeriods": ["M-2026-08"]}
```

```http
HTTP/1.1 200

{
 "results": [{"periodCode": "M-2026-08", "completeness": "COMPLETE", "value": 78.5, "missingMetrics": [], "elapsedMs": 12}],
 "dryRunHash": "d41d8cd98f00b204"
}
```

**API-16-074 · Công bố báo cáo chính thức**

```http
POST /api/kpi/v1/reports/bc-thang-2026-10:publish
If-Match: W/"3"

{"publishNote": "Công bố báo cáo tháng 10."}
```

```http
HTTP/1.1 200

{
 "reportCode": "bc-thang-2026-10",
 "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC",
 "state": "PUBLISHED",
 "latestVersion": 1,
 "periodCode": "M-2026-10",
 "rangeFrom": "2026-05-01"
}
```

**API-16-118 · Lập gói báo cáo gửi quốc gia**

```http
POST /api/kpi/v1/national/submissions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{
 "submissionType": "KPI_REPORT",
 "reportCode": "bc-thang-2026-10",
 "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu",
 "mode": "FULL",
 "componentTypes": ["HTTT"]
}
```

```http
HTTP/1.1 201

{
 "submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "submissionType": "KPI_REPORT",
 "state": "PENDING",
 "reportCode": "bc-thang-2026-10",
 "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu",
 "mode": "FULL"
}
```
<!-- gen:flows:end -->

## 4. Danh mục sự kiện

### 4.1. Sự kiện PH-16 phát và nhận

Sự kiện ghi vào `ph16_kpi.outbox_event` cùng giao dịch nghiệp vụ (ADR-042), Debezium Outbox Event Router đưa lên Kafka theo topic `{tenant}.kpi.{thực-thể}.{sự-kiện}.v1` (FRS 9.3; ví dụ `t68.kpi.report.published.v1`). CloudEvents 1.0 dạng cấu trúc, `type = vn.datahub.kpi.{thực-thể}.{sự-kiện}.v1`, `source = dh-platform/kpi/{tenant}`; mọi kênh có trong [`asyncapi-kpi.yaml`](ph16/asyncapi-kpi.yaml). Sự kiện chỉ mang mã, trạng thái, số tổng hợp, không mang nội dung báo cáo hay bằng chứng.

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Payload `data` | Bên nhận |
|---|---|---|---|---|---|
| EVT-16-01 | `{tenant}.kpi.indicator.activated.v1` | Phiên bản định nghĩa `ACTIVE` | `indicatorCode` | `IndicatorActivatedData` | PH-13, PH-17 |
| EVT-16-02 | `{tenant}.kpi.indicator.retired.v1` | Chỉ tiêu ngừng, thay thế | `indicatorCode` | `IndicatorRetiredData` | PH-13, PH-17 |
| EVT-16-03 | `{tenant}.kpi.source.state-changed.v1` | Nguồn `ACTIVE`, `STALE`, `FAILED`, `PAUSED`, `RETIRED` | `sourceCode` | `SourceStateChangedData` | PH-13, PH-18 |
| EVT-16-04 | `{tenant}.kpi.manual-value.decided.v1` | Số liệu tay `ACCEPTED` hoặc `REJECTED` | `indicatorCode` | `ManualValueDecidedData` | PH-18 |
| EVT-16-05 | `{tenant}.kpi.period.computed.v1` | Lần tổng hợp kết thúc (kèm `completeness`, `flags`) | `periodCode` | `PeriodComputedData` | PH-13, PH-18 |
| EVT-16-06 | `{tenant}.kpi.indicator.status-changed.v1` | Chỉ tiêu chuyển `AT_RISK`, `OFF_TRACK` hoặc về `ON_TRACK` | `indicatorCode` | `IndicatorStatusChangedData` | PH-13 (thông báo lãnh đạo) |
| EVT-16-07 | `{tenant}.kpi.report.submitted.v1` | Báo cáo gửi duyệt | `reportCode` | `ReportSubmittedData` | PH-18 |
| EVT-16-08 | `{tenant}.kpi.report.published.v1` | Báo cáo `PUBLISHED` | `reportCode` | `ReportPublishedData` | PH-13, PH-17, `kpi-export` (phân phối) |
| EVT-16-09 | `{tenant}.kpi.report.state-changed.v1` | `CHANGES_REQUESTED`, `SUPERSEDED`, `WITHDRAWN` | `reportCode` | `ReportStateChangedData` | PH-13, PH-18 |
| EVT-16-10 | `{tenant}.kpi.arch-component.changed.v1` | Thành phần tạo, đổi vòng đời, phiên bản, `opsStatus` | `componentCode` | `ArchComponentChangedData` | PH-13, PH-15 |
| EVT-16-11 | `{tenant}.kpi.arch-compliance.assessed.v1` | Đánh giá `CONFIRMED`, miễn trừ, hết hạn miễn trừ | `componentCode` | `ArchComplianceAssessedData` | PH-13 |
| EVT-16-12 | `{tenant}.kpi.national-submission.state-changed.v1` | Gói quốc gia đổi trạng thái | `submissionId` | `NationalSubmissionStateChangedData` | PH-13, PH-14 |
| EVT-16-13 | `{tenant}.kpi.export.completed.v1` | Xuất xong hoặc lỗi | `exportId` | `ExportCompletedData` | Người yêu cầu (qua PH-13) |
| EVT-16-14 | `{tenant}.kpi.period.state-changed.v1` | Kỳ `CLOSED` (số chính thức sẵn sàng) hoặc `REOPENED` (số có thể đổi) | `periodCode` | `PeriodStateChangedData` | PH-13, PH-17, PH-18 |

: Sự kiện PH-16 phát ra

| Mã | Topic | Hành động của PH-16 | Payload `data` |
|---|---|---|---|
| EVT-01-03 | `{tenant}.connect.system.state-changed.v1` | Quan sát `ph01.httt.*` từ ảnh chụp giờ (KPI-01, 05); tự đăng ký thành phần `HTTT` | `SystemStateChangedIn` |
| EVT-02-05 | `{tenant}.catalog.version.published.v1` | Quan sát số API công bố (`api-cong-bo`); đăng ký thành phần `API` | `CatalogVersionPublishedIn` |
| EVT-02-06 | `{tenant}.catalog.version.state-changed.v1` | Cập nhật vòng đời thành phần `API` | `CatalogVersionStateChangedIn` |
| EVT-02-13 | `{tenant}.catalog.sla.period-closed.v1` | Quan sát tỷ lệ API đạt SLA (`api-dat-sla-ty-le`) | `SlaPeriodClosedIn` |
| EVT-04-01 | `{tenant}.integration.flow.created.v1` | Đăng ký thành phần `FLOW`; mốc đầu của thời gian xây luồng (KPI-06) | `FlowEventIn` |
| EVT-04-07 | `{tenant}.integration.deployment.status-changed.v1` | Mốc cuối của thời gian xây luồng khi triển khai xong (KPI-06); cập nhật vòng đời `FLOW` | `DeploymentStatusChangedIn` |
| EVT-04-09 | `{tenant}.integration.flow.retired.v1` | Chuyển thành phần `FLOW` sang `RETIRED` | `FlowEventIn` |
| EVT-05-08 | `{tenant}.adapter.adapter.state-changed.v1` | Cập nhật vòng đời thành phần `ADAPTER` | `AdapterStateChangedIn` |
| EVT-07-05 | `{tenant}.rdm.catalog.published.v1` | Quan sát số danh mục quản lý tập trung (KPI-10) | `RdmCatalogPublishedIn` |
| EVT-07-09 | `{tenant}.rdm.sync.completed.v1` | Quan sát độ trễ đồng bộ danh mục quốc gia (KPI-11) | `RdmSyncCompletedIn` |
| EVT-08-14 | `{tenant}.dq.kpi.published.v1` | Quan sát `diem-chat-luong-du-lieu`; khử trùng theo `snapshotId` | `DqKpiPublishedIn` |
| EVT-10-01 | `{tenant}.event.topic.activated.v1` | Đăng ký thành phần `TOPIC`; quan sát số topic | `TopicEventIn` |
| EVT-10-04 | `{tenant}.event.topic.retired.v1` | Chuyển thành phần `TOPIC` sang `RETIRED` | `TopicEventIn` |
| EVT-10-06 | `{tenant}.event.publication.activated.v1` | Quan sát số publication | `PublicationActivatedIn` |
| EVT-14-01 | `{tenant}.national.platform.changed.v1` | Cập nhật thành phần `NATIONAL_LINK` | `NationalPlatformChangedIn` |
| EVT-14-11 | `{tenant}.national.transaction.recorded.v1` | Quan sát giao dịch quốc gia | `NationalTransactionRecordedIn` |
| EVT-14-12 | `{tenant}.national.sync.run-finished.v1` | Quan sát độ trễ đồng bộ danh mục quốc gia (KPI-11) | `NationalSyncRunFinishedIn` |
| EVT-19-07 | `{tenant}.payment.transaction.succeeded.v1` | Quan sát `giao-dich-thanh-toan-truc-tuyen` (lọc `isTest = true`) | `PaymentTransactionSucceededIn` |

: Sự kiện PH-16 tiêu thụ
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Các quy tắc sau áp dụng cho cả 14 sự kiện phát.

- **Không nội dung báo cáo, không bằng chứng**: chỉ mã đối tượng, trạng thái, số tổng hợp; EVT-16-08 mang `contentHash` để bên nhận kiểm bản tải về.
- **Thứ tự và khử trùng**: khóa phân vùng ở cột "Khóa"; phát ít nhất một lần, bên nhận khử trùng theo `id` và xử lý lũy đẳng; PH-16 khử trùng sự kiện nhận ở `ph16_kpi.inbox_event` rồi mới chuẩn hóa thành quan sát; quan sát khử trùng tiếp theo `idempotencyRef` (mã sự kiện hoặc `snapshotId`).
- **Sự kiện nhận không đúng lược đồ** ghi ERR-16-105 ở nhật ký tiếp nhận (API-16-042), không chặn các bản tin sau; thiếu bản tin được đọc bù qua API chỉ số của bên phát (API-16-029).
- **Đăng ký topic**: 14 topic đăng ký ở PH-10 theo FR-10-067; PH-13, PH-17, PH-18, PH-15, PH-14 là bên nhận chính.
- **Tương thích**: chỉ thêm trường tùy chọn trong `v1` (BACKWARD); lưu giữ topic 7 ngày, 3 phân vùng (giả định).
- **Dạng bản tin nhận**: PH-16 đọc `data` của dạng cấu trúc hoặc thân của dạng nhị phân (tiêu đề `ce_*`) tùy hợp đồng của bên phát; payload mục "tiêu thụ" chỉ khai trường PH-16 dùng và cho phép trường thừa.

## 5. Hợp đồng với phân hệ khác và bên ngoài

Bảng nêu hợp đồng PH-16 gọi các phân hệ phụ thuộc và hợp đồng họ gọi PH-16. PH-16 không gọi thẳng NDXP, NDOP hay dịch vụ NGSP; hệ quốc gia nhận báo cáo chưa có đặc tả (Q16-02, Q16-03).

| Phân hệ | Chiều | Hợp đồng |
|---|---|---|
| PH-01, PH-05, PH-07, PH-13, PH-19, PH-20 | PH-16 gọi | Kéo API chỉ số theo kỳ (`PULL_API`, scope đọc chỉ số của từng bên); mỗi nguồn khai `endpoint`, `scope`, `cron`, ánh xạ vào `metricCode` (Q16-59) |
| PH-02 | PH-16 gọi | API-02-079 (lượt khai thác), API-02-097 (API đạt SLA) với scope `catalog:metrics-read`; nhận EVT-02-05, 06, 13 |
| PH-08 | PH-16 gọi | Đọc bù API-08-122 (scope `dq.read`); nhận EVT-08-14, khử trùng theo `snapshotId`, lược đồ `kpiSchemaVersion` |
| PH-01, PH-02, PH-04, PH-10, CI/GitOps | Gọi PH-16 | `POST /ingest/arch-components` (API-16-101, scope `arch.register`) và sự kiện EVT-01-03, 02-05, 02-06, 04-01, 04-07, 04-09, 05-08, 10-01, 10-04, 14-01 để tự đăng ký thành phần |
| Phân hệ nguồn không phát sự kiện | Gọi PH-16 | `POST /ingest/observations` (API-16-030, scope `kpi.ingest`) |
| PH-14 | Hai chiều | PH-16 ghi gói vào outbox, PH-14 gửi tới nền tảng quốc gia; PH-14 trả biên nhận vào API-16-124 (scope `kpi.national-receipt`) và EVT-14-11, 12 |
| PH-17, cổng tỉnh, HTTT được cấp | Gọi PH-16 | API-16-086, 087, 089 (scope `kpi.read`); EVT-16-01, 02, 08 |
| PH-13 | Nhận sự kiện và kiểm toán | EVT-16-01…13; PH-16 ghi nhật ký kiểm toán sang PH-13, đọc lại ở API-16-129; thông báo qua kênh PH-13 (phân phối, EVT-16-13) |
| PH-18 | Nhận sự kiện | EVT-16-03, 04, 05, 07, 09 thành việc trong "Việc của tôi" |
| PH-15 | Nhận sự kiện | EVT-16-10 hiển thị trạng thái kiến trúc trên trang API |

: Hợp đồng với phân hệ khác

## 6. Bảng mã lỗi ERR-16 và thông báo hiển thị

PH-16 dùng dải ERR-16-001…099 cho control plane (57 mã) và ERR-16-101…199 cho thu thập, tính toán, gửi (25 mã); mã 101…104 trả cho bên gọi máy, các mã còn lại hiển thị cho vận hành ở UI-16-06, UI-16-09, UI-16-17 và PH-13. Bảng dưới ghép FRS 9.1 (mã, HTTP, ý nghĩa; HTTP trống là mã không trả cho người gọi, chỉ ghi ở nhật ký hoặc thông báo vận hành) với câu chuẩn của FRS 9.2 mà tập màn hình D03-06-PH16 dùng đúng; `{…}` là biến điền lúc chạy. Cột "Vị trí" là nơi người dùng hoặc người vận hành thấy câu. Lỗi `401`, `403` do thiếu quyền chức năng và `428` dùng mã nền ERR-00-401, ERR-00-403, ERR-00-428.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | Câu hiển thị | Vị trí |
|---|---|---|---|---|
| ERR-16-001 | 404 | Không tìm thấy đối tượng hoặc thuộc tenant khác | "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." | Trang lỗi, thông báo nổi |
| ERR-16-002 | 409 | Mã đã tồn tại (chỉ tiêu, nguồn, báo cáo, mẫu, thành phần) | "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." | Dưới trường mã |
| ERR-16-003 | 400 | Dữ liệu sai lược đồ, sai mẫu mã, tổ hợp thuộc tính không hợp lệ | "{Trường} chưa hợp lệ: {yêu cầu}." | Dưới trường lỗi |
| ERR-16-004 | 409 | Xung đột phiên bản (`If-Match` không khớp `ETag`) | "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi." | Hộp thoại |
| ERR-16-005 | 403 | Vi phạm bốn mắt (người lập, nhập, soạn tự duyệt, xác nhận, công bố) | "Anh/chị là người {vai} nên không được {thao tác}." | Thanh hành động duyệt |
| ERR-16-006 | 409 | Trạng thái hiện tại không cho thao tác | "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." | Thông báo nổi |
| ERR-16-007 | 422 | Thiếu lý do, ý kiến hoặc ngắn hơn mức tối thiểu | "Nhập {nội dung} (tối thiểu {n} ký tự)." | Dưới ô lý do |
| ERR-16-008 | 422 | Công thức CEL sai cú pháp hoặc sai kiểu | "Công thức chưa đúng ở vị trí {dòng}:{cột}: {mô tả}." | Trình soạn công thức |
| ERR-16-009 | 422 | Biến quan sát chưa có nguồn đăng ký | "Biến {metricCode} chưa có nguồn số liệu nào. Đăng ký nguồn trước khi dùng." | Trình soạn công thức |
| ERR-16-010 | 422 | Ngưỡng không đơn điệu theo chiều tốt hoặc mục tiêu ngoài miền | "Ngưỡng chưa hợp lệ: với chiều {chiều}, mốc xanh phải {lớn hơn hoặc nhỏ hơn} mốc vàng." | Tab mục tiêu và ngưỡng |
| ERR-16-011 | 422 | Chưa thử tính phiên bản sau lần sửa cuối | "Thử tính phiên bản sau lần sửa cuối trước khi gửi duyệt." | Hộp thoại gửi duyệt |
| ERR-16-012 | 422 | Tổng trọng số nhóm khác 100 | "Tổng trọng số năm nhóm đang là {tổng}. Điều chỉnh cho bằng 100." | Tab nhóm và trọng số |
| ERR-16-013 | 409 | Chỉ tiêu đang dùng trong báo cáo chờ duyệt | "Chỉ tiêu {mã} đang có trong {n} báo cáo chờ duyệt. Hoàn tất các báo cáo này trước khi ngừng." | Hộp thoại ngừng |
| ERR-16-014 | 403 | Sửa trực tiếp chỉ tiêu mẫu `COMMON` ở tenant | "Chỉ tiêu mẫu dùng chung không sửa trực tiếp được. Tạo phiên bản tùy biến của tỉnh." | Thông báo nổi |
| ERR-16-015 | 422 | Cấu hình nguồn thiếu hoặc sai theo loại | "Nguồn loại {loại} cần {trường}. Bổ sung trước khi lưu." | Biểu mẫu nguồn |
| ERR-16-016 | 422 | Thử nguồn thất bại | "Không đọc được dữ liệu từ nguồn {mã}: {lý do}. Kiểm tra quyền và cấu hình." | Biểu mẫu nguồn |
| ERR-16-017 | 409 | Nguồn là nguồn duy nhất của chỉ tiêu đang hiệu lực | "Nguồn {mã} là nguồn duy nhất của {n} chỉ tiêu đang hiệu lực." | Hộp thoại ngừng nguồn |
| ERR-16-018 | 422 | Thiếu bằng chứng cho số liệu tay | "Số liệu tay cần ít nhất một bằng chứng (tệp hoặc số văn bản)." | Biểu mẫu nhập tay |
| ERR-16-019 | 422 | Giá trị nhập tay ngoài miền của chỉ tiêu | "Giá trị {giá trị} nằm ngoài miền cho phép của chỉ tiêu ({miền})." | Dưới ô giá trị |
| ERR-16-020 | 422 | Tệp nhập sai mẫu hoặc vượt giới hạn dòng | "Tệp không đúng mẫu nhập số liệu hoặc vượt 2.000 dòng. Tải mẫu mới nhất." | Bước tải tệp |
| ERR-16-021 | 409 | Đã có số liệu tay `ACCEPTED` cho chỉ tiêu và kỳ | "Kỳ {kỳ} đã có số được xác nhận cho chỉ tiêu này. Tạo bản đính chính." | Biểu mẫu nhập tay |
| ERR-16-022 | 409 | Kỳ đã chốt | "Kỳ {kỳ} đã chốt. Mở lại kỳ nếu cần sửa hoặc tính lại." | Thông báo nổi |
| ERR-16-023 | 409 | Kỳ đang có lần tổng hợp chạy | "Kỳ {kỳ} đang được tổng hợp (bắt đầu {thời điểm}). Chờ lần này xong." | Thông báo nổi |
| ERR-16-024 | 422 | Mã kỳ sai mẫu, trùng hoặc ở tương lai | "Kỳ {mã} không hợp lệ hoặc đã có. Mã kỳ có dạng M-2026-10, Q-2026-Q3, Y-2026." | Hộp thoại tạo kỳ |
| ERR-16-025 | 422 | Kỳ chưa đủ điều kiện chốt | "Chưa chốt được kỳ {kỳ}: {lý do}." | Hộp thoại chốt kỳ |
| ERR-16-026 | 409 | Mở lại kỳ khi còn báo cáo đang duyệt | "Kỳ {kỳ} có báo cáo đang duyệt. Trả báo cáo về nháp trước khi mở lại kỳ." | Hộp thoại mở lại |
| ERR-16-027 | 422 | Mẫu báo cáo không hợp lệ | "Mẫu chưa hợp lệ: {phần} {lý do}." | Trình soạn mẫu |
| ERR-16-028 | 422 | Kỳ chưa có kết quả tổng hợp hoặc chưa chốt khi cần | "Kỳ {kỳ} chưa có kết quả tổng hợp hoặc chưa chốt. Hoàn tất trước khi lập hoặc gửi báo cáo." | Hộp thoại lập báo cáo |
| ERR-16-029 | 422 | Báo cáo chính thức thiếu số của chỉ tiêu bắt buộc | "Chỉ tiêu bắt buộc {danh sách} chưa có số liệu. Báo cáo chính thức chưa gửi duyệt được." | Hộp thoại gửi duyệt |
| ERR-16-030 | 422 | Thiếu giải trình chỉ tiêu chệch hoặc thiếu số | "Còn {n} chỉ tiêu chệch hoặc thiếu số chưa có giải trình." | Hộp thoại gửi duyệt |
| ERR-16-031 | 503 | Dịch vụ ký số không sẵn sàng | "Dịch vụ ký số đang gián đoạn. Báo cáo vẫn ở trạng thái Đã duyệt, thử công bố lại sau." | Thanh hành động công bố |
| ERR-16-032 | 409 | Sửa báo cáo đã công bố | "Báo cáo đã công bố không sửa được. Dùng chức năng đính chính." | Thông báo nổi |
| ERR-16-033 | 422 | Khoảng báo cáo đột xuất không hợp lệ | "Khoảng báo cáo từ {từ} đến {đến} không hợp lệ hoặc vượt 24 tháng." | Biểu mẫu báo cáo đột xuất |
| ERR-16-034 | 422 | Dữ liệu xuất hoặc sơ đồ vượt giới hạn | "Dữ liệu vượt giới hạn {n} {đơn vị}. Thu hẹp bộ lọc hoặc phạm vi." | Hộp thoại xuất |
| ERR-16-035 | 410 | Liên kết tải hết hạn | "Liên kết tải đã hết hạn. Tạo lại yêu cầu xuất." | Trang tải |
| ERR-16-036 | 422 | Người nhận phân phối không hợp lệ | "Người nhận {địa chỉ} không hợp lệ hoặc không thuộc miền thư công vụ." | Biểu mẫu phân phối |
| ERR-16-037 | 403 | Phạm vi dữ liệu không cho phép (tenant khác, đối tượng không được xem) | "Anh/chị hoặc ứng dụng không được truy cập {đối tượng} này." | Thông báo nổi; trả cho bên gọi máy |
| ERR-16-038 | 422 | Không đủ số tenant tối thiểu để so sánh | "Cần ít nhất {n} tỉnh có số chính thức để so sánh." | UI-16-18 |
| ERR-16-039 | 422 | Thành phần kiến trúc thiếu trường hoặc loại không hợp lệ | "Thành phần {mã} thiếu trường {trường} hoặc loại không hợp lệ." | Biểu mẫu thành phần; trả cho bên gọi máy |
| ERR-16-040 | 409 | Sửa trường do phân hệ nguồn quản lý | "Trường {trường} do {phân hệ} cập nhật tự động, không sửa tay được." | Biểu mẫu thành phần |
| ERR-16-041 | 422 | Phụ thuộc vòng hoặc tới thành phần đã ngừng | "Phụ thuộc tới {mã} tạo vòng hoặc thành phần đó đã ngừng." | Tab phụ thuộc |
| ERR-16-042 | 422 | Chuyển vòng đời không hợp lệ | "Không chuyển được sang {trạng thái}: còn {n} thành phần đang hoạt động phụ thuộc." | Hộp thoại vòng đời |
| ERR-16-043 | 422 | Đánh giá thiếu kết quả tiêu chí bắt buộc hoặc ghi chú | "Còn {n} tiêu chí bắt buộc chưa có kết quả hoặc tiêu chí không đạt chưa có ghi chú." | Ngăn kéo đánh giá |
| ERR-16-044 | 422 | Miễn trừ vượt hạn tối đa | "Miễn trừ tối đa {n} ngày." | Ngăn kéo đánh giá |
| ERR-16-045 | 422 | Bộ tiêu chí không hợp lệ | "Bộ tiêu chí chưa hợp lệ: {lý do}." | Trình soạn bộ tiêu chí |
| ERR-16-046 | 409 | Gửi quốc gia đang tắt | "Chức năng gửi quốc gia chưa được bật cho tỉnh." | UI-16-17 |
| ERR-16-047 | 422 | Mẫu gói quốc gia không hợp lệ hoặc không có phiên bản hiệu lực | "Mẫu gói {mã} phiên bản {n} chưa hợp lệ: {lý do}." | UI-16-17 tab mẫu gói |
| ERR-16-048 | 422 | Gói không đạt lược đồ mẫu | "Gói chưa đạt mẫu {mã}: {trường} {lý do}." | Bản xem trước gói |
| ERR-16-049 | 409 | Gói trùng với lần nộp trước | "{Nội dung} đã được nộp ngày {ngày} (mã biên nhận {biên nhận}) và chưa thay đổi." | Bản xem trước gói |
| ERR-16-050 | 409 | Gửi lại không cho phép | "Gói {mã} đang ở trạng thái {trạng thái} hoặc đã gửi lại tối đa {n} lần." | UI-16-17 |
| ERR-16-051 | 422 | Tham số ngoài miền hoặc vượt trần | "Giá trị {giá trị} của {khóa} nằm ngoài miền cho phép ({miền})." | UI-16-19 |
| ERR-16-052 | 422 | Đối tượng nguồn của gói chưa công bố | "Chỉ gửi được báo cáo đã công bố." | Hộp thoại gửi quốc gia |
| ERR-16-053 | 400 | Tệp bằng chứng sai loại hoặc quá cỡ | "Tệp {tên} không được nhận: chỉ PDF, ảnh, XLSX, DOCX tối đa {n} MB." | Vùng tải tệp |
| ERR-16-054 | 422 | Chỉ tiêu thay thế không hợp lệ | "Chỉ tiêu thay thế {mã} phải đang hiệu lực và cùng loại giá trị." | Hộp thoại ngừng |
| ERR-16-055 | 409 | Cập nhật mẫu xung đột với tùy biến của tenant | "Trường {trường} đã được tỉnh tùy biến và mẫu cũng thay đổi. Chọn giữ bản nào." | Hộp thoại cập nhật mẫu |
| ERR-16-056 | 409 | Đã có lần đối chiếu, đối soát đang chạy | "Đã có lần {việc} đang chạy. Chờ lần này xong." | Thông báo nổi |
| ERR-16-057 | 400 | Tham số lọc, phân trang ngoài miền hoặc tổ hợp tham số không hợp lệ | "Tham số {trường} không hợp lệ: {lý do}." | Thanh lọc |
| ERR-16-058 | 409 | `Idempotency-Key` dùng lại với nội dung khác trong 24 giờ | "Khóa chống trùng {khóa} đã dùng cho yêu cầu khác nội dung trong 24 giờ. Tạo khóa mới rồi gửi lại." | Trả bên gọi; thông báo nổi |
| ERR-16-059 | 403 | Người xác nhận không thuộc vai trò được giao của chỉ tiêu (`confirmerRoles`) | "Anh/chị không thuộc vai trò được giao xác nhận {đối tượng} này." | Thanh hành động xác nhận |
| ERR-16-060 | 400 | Khoảng thời gian tra cứu, đọc bù vượt mức tối đa | "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần." | Thanh lọc, hộp thoại đọc bù |
| ERR-16-061 | 422 | Báo cáo chính thức thiếu số ký hiệu hoặc nơi nhận | "Báo cáo chính thức cần số ký hiệu và nơi nhận trước khi gửi duyệt." | Hộp thoại gửi duyệt |
| ERR-16-101 | 400 | Quan sát sai lược đồ hoặc lệch tenant | "Quan sát thứ {i} sai lược đồ: {trường}." | Trả bên gọi máy; UI-16-06 |
| ERR-16-102 | 403 | Chỉ số ngoài hợp đồng của nguồn | "Chỉ số {metricCode} không thuộc hợp đồng của nguồn {mã}." | Trả bên gọi máy; UI-16-06 |
| ERR-16-103 | 409 | Cùng `idempotencyRef` khác giá trị | "Quan sát {idempotencyRef} đã có với giá trị khác. Cần kiểm tra ở phân hệ nguồn." | Trả bên gọi máy; UI-16-06 |
| ERR-16-104 | 422 | Quan sát thuộc kỳ đã chốt, lưu làm số trễ | "Quan sát thuộc kỳ {kỳ} đã chốt, được lưu làm số liệu trễ và không tính." | Trả bên gọi máy; UI-16-06 |
| ERR-16-105 | - | Bản tin sự kiện không đúng lược đồ | "Bản tin không đúng lược đồ {schemaRef}: {chi tiết}." | UI-16-06, PH-13 |
| ERR-16-106 | - | Kéo API chỉ số lỗi (hết thời gian, `5xx`) | "Kéo số từ {mã} lỗi lần {n}: {mã HTTP hoặc lý do}." | UI-16-06, PH-13 |
| ERR-16-107 | - | Nguồn quá hạn, chuyển `STALE` | "Nguồn {mã} không có số mới từ {thời điểm}." | UI-16-05, thông báo PH-13 |
| ERR-16-108 | - | Nguồn lỗi liên tiếp, chuyển `FAILED` | "Nguồn {mã} lỗi {n} lần liên tiếp, đã chuyển trạng thái Lỗi." | UI-16-05, thông báo PH-13 |
| ERR-16-109 | - | Công thức lỗi khi tính (`FORMULA_ERROR`) | "Chỉ tiêu {mã}: công thức lỗi khi tính ({lý do}). Giá trị để trống." | UI-16-09 |
| ERR-16-110 | - | Lần tổng hợp quá thời gian | "Lần tổng hợp vượt {n} phút và đã dừng. Kết quả lần trước được giữ." | UI-16-09, PH-13 |
| ERR-16-111 | - | Thiếu nguồn cho chỉ tiêu (`MISSING_SOURCE`, `STALE_SOURCE`) | "Thiếu số liệu từ {nguồn} cho kỳ {kỳ}." | UI-16-09, thẻ chỉ tiêu |
| ERR-16-112 | - | Số liệu tay chờ xác nhận (`MANUAL_PENDING`) | "Chỉ tiêu {mã} chờ xác nhận số liệu tay." | UI-16-09, thẻ chỉ tiêu |
| ERR-16-113 | - | Dựng PDF báo cáo lỗi | "Không dựng được tệp báo cáo: {lý do}." | UI-16-12 |
| ERR-16-114 | - | Lưu WORM lỗi | "Không lưu được bản công bố vào kho lưu trữ. Báo cáo chưa được công bố." | UI-16-12, PH-13 |
| ERR-16-115 | - | Việc xuất lỗi | "Xuất {tên} không thành công: {lý do}." | Thông báo người yêu cầu |
| ERR-16-116 | - | Gửi phân phối lỗi | "Gửi tới {người nhận} không thành công." | UI-16-13 lịch sử gửi |
| ERR-16-117 | - | Hệ quốc gia từ chối gói | "Hệ quốc gia từ chối gói: {mã lý do} {mô tả}." | UI-16-17 |
| ERR-16-118 | - | Lỗi kênh PH-14, sẽ gửi lại | "Gửi qua PH-14 không thành công, sẽ thử lại lần {n}." | UI-16-17, PH-13 |
| ERR-16-119 | - | Sự kiện tự đăng ký kiến trúc thiếu trường hoặc tham chiếu | "Không đăng ký được thành phần từ sự kiện {mã}: {lý do}." | UI-16-14 tab lệch |
| ERR-16-120 | - | Sổ kiến trúc lệch với phân hệ nguồn | "{n} thành phần lệch với {phân hệ}." | UI-16-14 tab lệch |
| ERR-16-121 | - | Mất tin trạng thái vận hành, đặt `UNKNOWN` | "Chưa nhận trạng thái vận hành của {mã} từ {thời điểm}." | UI-16-15 |
| ERR-16-122 | - | Dọn dữ liệu theo hạn lỗi | "Lần dọn dữ liệu ngày {ngày} lỗi: {lý do}." | UI-16-19, PH-13 |
| ERR-16-123 | - | Tồn đọng chuyển kiểm toán sang PH-13 | "Kiểm toán PH-16 tồn {n} bản ghi chưa chuyển." | PH-13 |
| ERR-16-124 | - | Mã băm bản lưu hoặc biên nhận không khớp | "Bản lưu hoặc biên nhận của {mã} không khớp mã băm đã ghi. Đã báo cán bộ an toàn thông tin." | UI-16-10, UI-16-17, PH-13 |
| ERR-16-125 | - | Ghi phân vùng quan sát lỗi (phân vùng chưa tạo) | "Không ghi được quan sát kỳ {kỳ}: phân vùng chưa sẵn sàng." | PH-13 |

: Mã lỗi ERR-16 và thông báo hiển thị
<!-- gen:errors:end -->

### 6.1. Thân lỗi

Thân lỗi mang `code` và `errors[]` theo trường; ví dụ cho ERR-16-012 (tổng trọng số nhóm sai):

```json
{ "type": "https://datahub.gov.vn/errors/ERR-16-012", "title": "Tổng trọng số nhóm khác 100", "status": 422,
  "code": "ERR-16-012", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{"field": "groups", "message": "Tổng trọng số năm nhóm đang là 95. Điều chỉnh cho bằng 100."}] }
```

Lý do hoặc ý kiến ngắn hơn số ký tự quy định (20 hoặc 50) luôn trả ERR-16-007 (`422`), không trả ERR-16-003: máy chủ kiểm độ dài ở lớp nghiệp vụ trước khi kiểm lược đồ, nên `minLength` trong OpenAPI chỉ để sinh mã máy khách và không phải nguồn của mã lỗi. ERR-16-003 (`400`) dành cho sai kiểu, thiếu trường hoặc giá trị ngoài miền.

Ví dụ cho lô quan sát một phần thành công (API-16-030, `207`): mỗi phần tử có `status` và `code`, thân phản hồi không phải RFC 9457.

```json
{ "accepted": 1, "duplicate": 0, "rejected": 1,
  "results": [ {"index": 0, "status": "ACCEPTED"},
               {"index": 1, "status": "REJECTED", "code": "ERR-16-102"} ] }
```

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng sinh từ một nguồn (`tools/spec.py`, enum đọc thẳng từ Phụ lục A của FRS, mã API, phương thức, đường dẫn và FR đọc từ FRS 9.4) nên khó lệch FRS; các lớp kiểm chạy ở CI (CI-5, `.github/workflows/datahub-docs-dac-ta.yml`).

| Công cụ | Kiểm gì |
|---|---|
| [`check_contracts.py`](ph16/tools/check_contracts.py) | OpenAPI 3.1 hợp lệ; mọi ví dụ khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `-fr`, `-permission`, `-errors`; lệnh sửa, hành động có `If-Match` (trừ `noifm`), lệnh tạo có `Idempotency-Key`; mã lỗi có ở FRS 9.1 và có mã HTTP trong `responses`; không trường bí mật; AsyncAPI 3.0 đủ 13 + 18 kênh, kênh tiêu thụ trùng topic với bên phát |
| [`doi_chieu_frs.py`](ph16/tools/doi_chieu_frs.py) | Đối chiếu đường dẫn, phương thức, FR của 130 mã FRS 9.4; mã ERR, EVT, PERM; liệt kê trường và enum chỉ có ở API (Phụ lục A) |
| `kiem_tra_yaml.py`, Spectral (`build/tools/spectral.yaml`) | Khóa trùng, mô tả có dấu phẩy chưa đặt nháy; lỗi cấu trúc OpenAPI 3.1, AsyncAPI 3.0, `$ref` hỏng, ví dụ trái lược đồ |
| `oasdiff`, `gitleaks` | oasdiff chặn thay đổi phá vỡ trong `v1`; gitleaks bảo đảm ví dụ không chứa chuỗi giống bí mật (PH-16 không có bí mật, thông tin xác thực quốc gia nằm ở PH-14 và OpenBao) |

: Kiểm tra hợp đồng trong CI

## 8. Ánh xạ từ hệ cũ

Hệ cũ (Viettel 2021) không có chức năng báo cáo chỉ tiêu (FRS 2.6), nên không có API cũ để ánh xạ. SRS cũ của repo (`docs/07-srs/SRS-PH-16-nas-kpi.md`, mục M5) có bộ API gốc `/api/v1/arch-kpi` dựa trên Backstage (ADR-006 cũ, đã bỏ); các API chính được gom vào hợp đồng mới như sau.

| API của SRS cũ | API mới |
|---|---|
| `GET /components`, `POST /components`, `PATCH /components/{code}` (Registry) | API-16-094, 095, 096, 097 (sổ kiến trúc tự xây trên PostgreSQL) |
| `GET /components/{code}/versions` | API-16-096 (trường `versions[]`), API-16-098 thêm phiên bản |
| `POST /hooks/f02-published` | API-16-101 `POST /ingest/arch-components` và sự kiện EVT-02-05 |
| `POST /nas/sync`, `GET /nas/sync/logs` | API-16-118 và 121 (gói `ARCH_REGISTRY` gửi qua PH-14), API-16-123 (nhật ký nộp) |
| `GET/PUT /kpi/configs/{id}` | API-16-003, 007 (phiên bản định nghĩa chỉ tiêu có duyệt bốn mắt) |
| `POST /kpi/aggregate` | API-16-050 `POST /periods/{periodCode}/runs` |
| `GET /kpi/snapshots/{periodId}` | API-16-048, 053 (kỳ và giá trị chỉ tiêu), API-16-090 (bảng điều khiển) |
| `POST /kpi/snapshots/{id}/approve` | API-16-057 chốt kỳ, API-16-072 và 074 duyệt, công bố báo cáo |
| `POST /kpi/export` | API-16-079 `POST /exports` |
| `POST /feeds/dq`, `/feeds/catalog`, `/feeds/rdm` | Sự kiện EVT-08-14, EVT-02-05, 02-13, EVT-07-05 và nguồn `PULL_API`; phân hệ không phát sự kiện dùng API-16-030 |
| `GET /reconciliation` | API-16-125 và 126 (đối soát quốc gia), API-16-111 và 112 (đối chiếu sổ) |

: Ánh xạ API của SRS cũ sang API mới

## 9. Câu hỏi mở

Các câu hỏi dưới chưa có câu trả lời; tập này dùng phương án ở cột "Tạm dùng" để không chặn thiết kế. Q16-01…19 ở FRS, Q16-20…54 ở các tập SDD, màn hình, kiểm thử, ca sử dụng và CSDL.

| Mã | Câu hỏi | Tạm dùng |
|---|---|---|
| Q16-55 | Giới hạn `size`: FRS FR-16-001 cho tối đa 200, các tập API khác dùng 100 | 200 cho mọi danh sách, mặc định 20; hạ về 100 nếu hội đồng chọn thống nhất |
| Q16-56 | Đã trả lời ở FRS 0.2: ERR-16-058 (409) | Đóng |
| Q16-57 | Đã trả lời ở FRS 0.2 mục 3.3: scope `kpi.national-receipt` cộng mTLS, chỉ `apisix-int` | Đóng |
| Q16-58 | Tệp bằng chứng và tệp nhập XLSX đi qua BFF (`multipart`) hay URL ký trước tới Ceph RGW (`kpi-evidence`) khi tệp lớn | `multipart` qua BFF tới 20 MB; URL ký trước nếu `16.manual.max-file-mb` được nâng |
| Q16-59 | API chỉ số của phân hệ nguồn (PH-01, 05, 07, 13, 19, 20) chưa có hợp đồng thống nhất; PH-16 chuẩn hóa phía nhận hay yêu cầu hợp đồng chung | Mỗi nguồn khai `endpoint`, `scope`, `cron`, `contract.metricCodes`; PH-16 ánh xạ vào `metricCode`, chờ hợp đồng chung ở D03-04 của từng phân hệ |

: Câu hỏi mở của tập API PH-16

## 10. Truy vết FR → API

Mỗi FR của PH-16 có ít nhất một API hoặc ghi rõ lý do không có. Bảng dưới sinh từ OpenAPI; FR chỉ có giao diện hoặc do hệ thống thực hiện được ghi bằng lời.

<!-- gen:fr:start -->
| FR | Tên | API (API-16-) |
|---|---|---|
| FR-16-001 | Liệt kê, tìm, lọc bộ chỉ tiêu theo nhóm, trạng thái, cách đo | 001, 003 |
| FR-16-002 | Tạo chỉ tiêu và phiên bản định nghĩa nháp | 002, 005 |
| FR-16-003 | Soạn công thức CEL, biến quan sát, thử tính trên dữ liệu kỳ trước | 007, 008, 009, 010 |
| FR-16-004 | Đặt mục tiêu, ngưỡng ba mức, chiều tốt, đơn vị, làm tròn | 007 |
| FR-16-005 | Gửi duyệt và duyệt bốn mắt phiên bản định nghĩa | 011, 012, 013, 014, 078 |
| FR-16-006 | Ngừng, thay thế chỉ tiêu; lịch sử phiên bản, so sánh | 003, 004, 006, 015 |
| FR-16-007 | Quản lý nhóm chỉ tiêu và trọng số điểm nhóm | 016, 017 |
| FR-16-008 | Kế thừa bộ chỉ tiêu mẫu `COMMON`, nhận cập nhật mẫu | 001, 018, 019, 020 |
| FR-16-009 | Đăng ký nguồn (EVENT, PULL_API, PUSH_API, MANUAL) và hợp đồng chỉ số | 010, 021, 022, 023, 024, 025, 028 |
| FR-16-010 | Tiếp nhận quan sát từ sự kiện Kafka, idempotent, chuẩn hóa | 042, 043, 044 |
| FR-16-011 | Kéo API chỉ số của phân hệ theo lịch, đọc bù khi lỡ sự kiện | 029, 042 |
| FR-16-012 | Nhận quan sát qua API `kpi.ingest` | 030 |
| FR-16-013 | Theo dõi độ tươi, chuyển STALE, FAILED, cảnh báo | 021, 023, 026, 027 |
| FR-16-014 | Nhập số liệu tay kèm bằng chứng (biểu mẫu và tệp XLSX có xem trước) | 031, 032, 033, 034, 035, 036, 037, 038, 039 |
| FR-16-015 | Xác nhận hoặc từ chối số liệu tay (bốn mắt) | 031, 033, 040, 041, 078 |
| FR-16-016 | Tra nhật ký tiếp nhận, quan sát bị loại, xử lý lại | 042, 043, 044, 045 |
| FR-16-017 | Quản lý lịch kỳ báo cáo theo tháng, quý, năm | 046, 047, 048 |
| FR-16-018 | Chạy tổng hợp theo lịch hoặc thủ công | 049, 050, 051, 052 |
| FR-16-019 | Tính giá trị chỉ tiêu theo phiên bản công thức có hiệu lực, lưu dòng truy nguồn | 053, 054 |
| FR-16-020 | Đánh giá độ đầy đủ, gắn PARTIAL, cờ thiếu nguồn | 048, 051, 053 |
| FR-16-021 | Đánh giá trạng thái so mục tiêu, ngưỡng; phát cảnh báo chệch | 053, 056 |
| FR-16-022 | Tính điểm nhóm, xu hướng, chênh lệch so kỳ trước, cùng kỳ năm trước | 090 |
| FR-16-023 | Tính lại khi có số liệu trễ hoặc đổi công thức (kỳ chưa chốt) | 055, 069 |
| FR-16-024 | Chốt kỳ, mở lại kỳ có lý do | 057, 058 |
| FR-16-025 | Quản lý mẫu báo cáo (phần, biểu đồ, định dạng) | 059, 060, 061, 062, 063 |
| FR-16-026 | Lập bản nháp báo cáo từ kỳ đã tính | 065, 069, 070 |
| FR-16-027 | Viết thuyết minh, giải trình chỉ tiêu chệch | 066, 067, 068 |
| FR-16-028 | Gửi duyệt, yêu cầu sửa, duyệt bốn mắt | 071, 072, 073, 078 |
| FR-16-029 | Công bố báo cáo chính thức: chụp bất biến, ký số, lưu WORM | 074 |
| FR-16-030 | Đính chính báo cáo đã công bố bằng phiên bản mới; rút báo cáo | 075, 076 |
| FR-16-031 | Liệt kê, tìm, xem báo cáo và lịch sử phiên bản | 064, 066, 077 |
| FR-16-032 | Báo cáo đột xuất theo khoảng thời gian, tập chỉ tiêu tự chọn | 065 |
| FR-16-033 | Xuất báo cáo, bảng chỉ tiêu ra PDF, XLSX, CSV, JSON | 079, 080, 081 |
| FR-16-034 | Danh sách phân phối và lịch gửi theo kỳ qua kênh thông báo PH-13 | 082, 083, 084, 085 |
| FR-16-035 | API đọc chỉ tiêu, báo cáo cho hệ khác (`kpi.read`) | 086, 087 |
| FR-16-036 | Tải bằng chứng công bố (tệp ký, mã băm, nhật ký) | 088 |
| FR-16-037 | Cung cấp thẻ chỉ tiêu cho trang Tổng quan `/tong-quan` | 089 |
| FR-16-038 | Bảng điều khiển tổng quan năm nhóm cho lãnh đạo | 090 |
| FR-16-039 | Chi tiết chỉ tiêu: chuỗi thời gian, mục tiêu, nguồn, truy tới quan sát | 003, 043, 054, 091 |
| FR-16-040 | Lọc theo kỳ, nhóm, trạng thái; so sánh hai kỳ | 090, 091 |
| FR-16-041 | So sánh liên tenant ẩn danh cho quản trị nền tảng | 092 |
| FR-16-042 | Theo dõi tình trạng thu thập, tính toán (vận hành) | 049, 093 |
| FR-16-043 | Liệt kê, tìm thành phần kiến trúc theo loại, vòng đời, tuân thủ | 094, 096 |
| FR-16-044 | Tự đăng ký, cập nhật thành phần từ sự kiện phân hệ nguồn | 101 |
| FR-16-045 | Khai báo, sửa thành phần thủ công; phiên bản, phụ thuộc | 095, 096, 097, 098, 099, 100 |
| FR-16-046 | Cập nhật trạng thái vận hành từ PH-13 | 096 |
| FR-16-047 | Đánh giá tuân thủ theo bộ tiêu chí, xác nhận, miễn trừ có hạn | 102, 103, 104, 105, 106, 107, 108, 109, 110 |
| FR-16-048 | Đối chiếu sổ kiến trúc với phân hệ nguồn, phát hiện lệch, mồ côi | 111, 112, 113 |
| FR-16-049 | Xuất sổ kiến trúc, sơ đồ phụ thuộc | 079, 080, 081 |
| FR-16-050 | Quản lý mẫu gói quốc gia có phiên bản (cấu hình ngoài) | 114, 115, 116, 117 |
| FR-16-051 | Lập và gửi gói báo cáo chỉ tiêu qua PH-14 | 118, 120, 121 |
| FR-16-052 | Gửi sổ kiến trúc (thành phần, phiên bản, trạng thái, tuân thủ) qua PH-14 | 118, 120, 121 |
| FR-16-053 | Nhật ký nộp làm bằng chứng, biên nhận, gửi lại khi lỗi | 119, 120, 122, 123, 124 |
| FR-16-054 | Đối soát sổ kiến trúc, gói đã nộp và chỉ tiêu | 125, 126 |
| FR-16-055 | Tham số phân hệ theo tenant | 127, 128 |
| FR-16-056 | Nhật ký kiểm toán thao tác PH-16 (ghi sang PH-13), tra cứu | 129 |
| FR-16-057 | Lưu giữ, xóa dữ liệu theo hạn; giữ báo cáo công bố 10 năm | 130 |
| FR-16-058 | Chỉ số vận hành của chính PH-16 cho PH-13 | Chỉ số Prometheus ở `/actuator/prometheus`, ngoài `/api/kpi/v1` |

: Truy vết FR-16 sang API
<!-- gen:fr:end -->

## 11. Đặc tả từng endpoint

Chương này sinh từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py` (qua `tools/gen_md.py`); sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng 10 mục; để tập không quá 240 KB, bảng bỏ các thông tin lặp ở chương 1 và 3: `page`, `size`, tham số đường dẫn, `If-Match` và các mã lỗi chung ERR-16-001, 003, 004, 006, 057; ví dụ HTTP của mọi endpoint nằm ở OpenAPI, tập này in ví dụ cho các endpoint tạo, chạy, công bố trước.

<!-- gen:dac-ta-api:start -->
### Bộ chỉ tiêu

#### API-16-001 · Danh sách chỉ tiêu

::: dac-ta
**Mục đích.** Danh sách chỉ tiêu.

**Phương thức, đường dẫn.** `GET /indicators`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-001, FR-16-008.

**Tham số.** `scope` (query, IndicatorScope, tùy chọn); `q` (query, string, tùy chọn); `groupCode` (query, GroupCode, tùy chọn); `state` (query, IndicatorState, tùy chọn); `measurement` (query, Measurement, tùy chọn); `mandatory` (query, boolean, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/indicators
```

```http
HTTP/1.1 200 OK

{"items": [{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ HTTT kết nối nền tảng",
   "groupCode": "KET_NOI", "kind": "RATIO", "direction": "HIGHER_BETTER"}], "page": 0,
 "size": 20, "totalElements": 1,
 "facets": {"byGroup": {"KET_NOI": 5, "CHIA_SE": 7}, "byState": {"ACTIVE": 22, "DRAFT": 2},
  "byMeasurement": {"AUTO": 18, "MANUAL": 4, "MIXED": 2}}, "hasCommonUpdate": false}
```

#### API-16-002 · Tạo chỉ tiêu và phiên bản nháp đầu tiên

::: dac-ta
**Mục đích.** Tạo chỉ tiêu và phiên bản nháp đầu tiên.

**Phương thức, đường dẫn.** `POST /indicators`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-002.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IndicatorCreate`; trường bắt buộc: `indicatorCode`, `name`, `groupCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Indicator`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-16-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo chỉ tiêu `scope = TENANT` và phiên bản 1 `DRAFT` chưa có công thức. `BOOLEAN` chỉ đi với `TARGET_RANGE` và `LAST`; `RATIO` có đơn vị `%` (ERR-16-003).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"indicatorCode": "api-dat-sla-ty-le", "name": "Tỷ lệ API đạt SLA", "groupCode": "CHIA_SE",
 "kind": "RATIO", "direction": "HIGHER_BETTER", "measurement": "AUTO", "unit": "%"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/indicators/ma-moi

{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ HTTT kết nối nền tảng",
 "groupCode": "KET_NOI", "kind": "RATIO", "direction": "HIGHER_BETTER",
 "measurement": "AUTO", "unit": "%"}
```

#### API-16-003 · Chi tiết chỉ tiêu

::: dac-ta
**Mục đích.** Chi tiết chỉ tiêu.

**Phương thức, đường dẫn.** `GET /indicators/{indicatorCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-001, FR-16-006, FR-16-039.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Indicator`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/indicators/{indicatorCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ HTTT kết nối nền tảng",
 "groupCode": "KET_NOI", "kind": "RATIO", "direction": "HIGHER_BETTER",
 "measurement": "AUTO", "unit": "%"}
```

#### API-16-004 · Danh sách phiên bản định nghĩa

::: dac-ta
**Mục đích.** Danh sách phiên bản định nghĩa.

**Phương thức, đường dẫn.** `GET /indicators/{indicatorCode}/versions`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-006.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersionPage`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/indicators/{indicatorCode}/versions
```

```http
HTTP/1.1 200 OK

{"items": [{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
   "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
   "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}]}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-005 · Mở phiên bản định nghĩa mới

::: dac-ta
**Mục đích.** Mở phiên bản định nghĩa mới.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-002.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VersionCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IndicatorVersion`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"baseVersion": 2, "changeNote": "Đổi mục tiêu năm 2027."}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/indicators/ma-moi

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-006 · Chi tiết phiên bản, so sánh với phiên bản khác

::: dac-ta
**Mục đích.** Chi tiết phiên bản, so sánh với phiên bản khác.

**Phương thức, đường dẫn.** `GET /indicators/{indicatorCode}/versions/{version}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-006.

**Tham số.** `compareTo` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/indicators/{indicatorCode}/versions/{version}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-007 · Sửa công thức, mục tiêu, ngưỡng của phiên bản nháp

::: dac-ta
**Mục đích.** Sửa công thức, mục tiêu, ngưỡng của phiên bản nháp.

**Phương thức, đường dẫn.** `PATCH /indicators/{indicatorCode}/versions/{version}`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-003, FR-16-004.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `VersionPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-008, ERR-16-009, ERR-16-010, ERR-16-014 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ sửa được phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`. Sửa chỉ tiêu mẫu `COMMON` trực tiếp trả ERR-16-014. Sửa công thức làm mất kết quả thử tính cũ (ERR-16-011 khi gửi duyệt).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/indicators/{indicatorCode}/versions/{version}

{"formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "target": {"target": 90, "baseline": 40, "targetDate": "2027-12-31", "targetMode": "ABSOLUTE"},
 "thresholds": {"greenFrom": 90, "amberFrom": 70, "range": {"low": 0, "high": 0, "tolerance": 0}},
 "direction": "HIGHER_BETTER", "unit": "%", "decimals": 1}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-008 · Kiểm cú pháp công thức

::: dac-ta
**Mục đích.** Kiểm cú pháp công thức.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:validate`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-003.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidateResult`.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-008, ERR-16-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm cú pháp CEL, kiểu và biến đã có nguồn; không tính giá trị. Sai cú pháp trả ERR-16-008 kèm `line`, `column`; biến chưa có nguồn trả ERR-16-009.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:validate
```

```http
HTTP/1.1 200 OK

{"valid": true, "referencedMetrics": ["ph01.httt.connected"], "warnings": []}
```

#### API-16-009 · Thử tính trên dữ liệu kỳ trước

::: dac-ta
**Mục đích.** Thử tính trên dữ liệu kỳ trước.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:dry-run`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-003.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DryRunRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DryRunResult`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-008, ERR-16-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đồng bộ, tính trên quan sát và số liệu tay đã có của 1…6 kỳ đã qua; không ghi giá trị chỉ tiêu. Kết quả gắn `dryRunHash` của nội dung hiện tại.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:dry-run

{"dryRunPeriods": ["M-2026-08"]}
```

```http
HTTP/1.1 200 OK

{"results": [{"periodCode": "M-2026-08", "completeness": "COMPLETE", "value": 78.5,
   "missingMetrics": [], "elapsedMs": 12}], "dryRunHash": "d41d8cd98f00b204"}
```

#### API-16-010 · Danh sách biến quan sát có thể dùng

::: dac-ta
**Mục đích.** Danh sách biến quan sát có thể dùng.

**Phương thức, đường dẫn.** `GET /metrics`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-003, FR-16-009.

**Tham số.** `q` (query, string, tùy chọn); `sourceCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MetricPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/metrics
```

```http
HTTP/1.1 200 OK

{"items": [{"metricCode": "ph08.dq.score", "sourceCode": "ph08-dq-kpi", "unit": "điểm",
   "periodType": "MONTH", "lastObservedAt": "2026-11-26T08:00:00+07:00"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-011 · Gửi duyệt phiên bản định nghĩa

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản định nghĩa.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:submit`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-005.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `VersionSubmit`; trường bắt buộc: `changeNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007, ERR-16-011 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phải có kết quả thử tính của đúng nội dung hiện tại (ERR-16-011); người gửi không được tự duyệt (ERR-16-005 ở API-16-012).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:submit

{"changeNote": "Nâng mục tiêu 2027 lên 90% theo kế hoạch của tỉnh.",
 "effectiveFrom": "2026-12-01"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "PENDING_APPROVAL",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-012 · Duyệt phiên bản định nghĩa

::: dac-ta
**Mục đích.** Duyệt phiên bản định nghĩa.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:approve`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-005.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người soạn, gửi (bốn mắt, ERR-16-005). Duyệt xong phiên bản `ACTIVE`, phiên bản cũ chuyển `SUPERSEDED`; phát EVT-16-01.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "ACTIVE",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-013 · Yêu cầu sửa phiên bản định nghĩa

::: dac-ta
**Mục đích.** Yêu cầu sửa phiên bản định nghĩa.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:request-changes`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-005.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-005, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:request-changes

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "CHANGES_REQUESTED",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-014 · Rút phiên bản khỏi hàng chờ duyệt

::: dac-ta
**Mục đích.** Rút phiên bản khỏi hàng chờ duyệt.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}/versions/{version}:withdraw`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-005.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IndicatorVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}/versions/{version}:withdraw

{"reason": "Nguồn đã ngừng cung cấp theo công văn số 123 ngày 10/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}],
 "dryRunHash": "d41d8cd98f00b204", "direction": "HIGHER_BETTER"}
```

#### API-16-015 · Ngừng, thay thế chỉ tiêu

::: dac-ta
**Mục đích.** Ngừng, thay thế chỉ tiêu.

**Phương thức, đường dẫn.** `POST /indicators/{indicatorCode}:retire`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-006.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IndicatorRetire`; trường bắt buộc: `reason`, `effectivePeriod`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Indicator`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007, ERR-16-013, ERR-16-054 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ tiêu đang có trong báo cáo chờ duyệt trả ERR-16-013; `replacedBy` phải đang hiệu lực, cùng loại giá trị (ERR-16-054). Phát EVT-16-02.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators/{indicatorCode}:retire

{"reason": "Thay bằng chỉ tiêu đo theo khung mới của Bộ.", "effectivePeriod": "M-2027-01",
 "replacedBy": "httt-ket-noi-ty-le-v2"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ HTTT kết nối nền tảng",
 "groupCode": "KET_NOI", "kind": "RATIO", "direction": "HIGHER_BETTER",
 "measurement": "AUTO", "unit": "%"}
```

#### API-16-016 · Danh sách nhóm chỉ tiêu và trọng số

::: dac-ta
**Mục đích.** Danh sách nhóm chỉ tiêu và trọng số.

**Phương thức, đường dẫn.** `GET /groups`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-007.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GroupSet`; tiêu đề `ETag`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/groups
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"groups": [{"groupCode": "KET_NOI", "displayName": "Kết nối, tích hợp", "weight": 20, "order": 1}],
 "effectiveFrom": "2026-12-01"}
```

#### API-16-017 · Đặt nhóm chỉ tiêu và trọng số

::: dac-ta
**Mục đích.** Đặt nhóm chỉ tiêu và trọng số.

**Phương thức, đường dẫn.** `PUT /groups`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `GroupSet`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GroupSet`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-012 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gồm đủ năm nhóm cố định; tổng `weight` phải bằng 100 (ERR-16-012). Trọng số mới có hiệu lực từ `effectiveFrom` cho kỳ chưa chốt.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/kpi/v1/groups

{"groups": [{"groupCode": "KET_NOI", "displayName": "Kết nối, tích hợp", "weight": 20, "order": 1}],
 "effectiveFrom": "2026-12-01"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"groups": [{"groupCode": "KET_NOI", "displayName": "Kết nối, tích hợp", "weight": 20, "order": 1}],
 "effectiveFrom": "2026-12-01"}
```

#### API-16-018 · Kế thừa chỉ tiêu mẫu COMMON

::: dac-ta
**Mục đích.** Kế thừa chỉ tiêu mẫu COMMON.

**Phương thức, đường dẫn.** `POST /indicators:adopt-common`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AdoptRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AdoptResult`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-16-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sao chỉ tiêu mẫu `COMMON` sang tenant ở `DRAFT`; chỉ tiêu đã có bị bỏ qua và nêu ở `skipped`. Để trống `indicatorCodes` là kế thừa toàn bộ bộ mẫu.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/indicators:adopt-common
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"indicatorCodes": ["httt-ket-noi-ty-le"]}
```

```http
HTTP/1.1 201 Created

{"adopted": ["httt-ket-noi-ty-le"], "skipped": []}
```

#### API-16-019 · Danh sách cập nhật mẫu chờ quyết định

::: dac-ta
**Mục đích.** Danh sách cập nhật mẫu chờ quyết định.

**Phương thức, đường dẫn.** `GET /common-updates`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-008.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CommonUpdatePage`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/common-updates
```

```http
HTTP/1.1 200 OK

{"items": [{"indicatorCode": "httt-ket-noi-ty-le", "templateVersion": 3, "derivedVersion": 2,
   "changedFields": ["formula"], "conflictFields": ["target.target"]}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-020 · Chấp nhận hoặc bỏ qua cập nhật mẫu

::: dac-ta
**Mục đích.** Chấp nhận hoặc bỏ qua cập nhật mẫu.

**Phương thức, đường dẫn.** `POST /common-updates/{indicatorCode}:decide`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-008.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommonDecisionBody`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CommonDecisionResult`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `ACCEPT` tạo phiên bản nháp mới từ mẫu; trường tenant đã tùy biến mà mẫu cũng đổi thì trả ERR-16-055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/common-updates/{indicatorCode}:decide

{"decision": "ACCEPT", "comment": "Nhận bản cập nhật, giữ mục tiêu riêng của tỉnh."}
```

```http
HTTP/1.1 200 OK

{"indicatorCode": "httt-ket-noi-ty-le", "newDraftVersion": 3, "dismissed": false}
```

### Nguồn số liệu

#### API-16-021 · Danh sách nguồn số liệu

::: dac-ta
**Mục đích.** Danh sách nguồn số liệu.

**Phương thức, đường dẫn.** `GET /sources`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-009, FR-16-013.

**Tham số.** `q` (query, string, tùy chọn); `state` (query, SourceState, tùy chọn); `sourceType` (query, SourceType, tùy chọn); `providerModule` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SourcePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/sources
```

```http
HTTP/1.1 200 OK

{"items": [{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "ACTIVE",
   "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-022 · Đăng ký nguồn số liệu

::: dac-ta
**Mục đích.** Đăng ký nguồn số liệu.

**Phương thức, đường dẫn.** `POST /sources`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-009.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SourceCreate`; trường bắt buộc: `sourceCode`, `sourceType`, `contract`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `DataSource`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-002, ERR-16-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"sourceCode": "ph02-catalog-stats", "sourceType": "PULL_API",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Thống kê danh mục API PH-02",
 "providerModule": "PH-02", "topic": "t68.dq.kpi.published.v1",
 "schemaRef": "dq-kpi@kpiSchemaVersion=1"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/sources/ma-moi

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "ACTIVE",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-023 · Chi tiết nguồn số liệu, độ tươi

::: dac-ta
**Mục đích.** Chi tiết nguồn số liệu, độ tươi.

**Phương thức, đường dẫn.** `GET /sources/{sourceCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-009, FR-16-013.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataSource`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/sources/{sourceCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "ACTIVE",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-024 · Sửa nguồn số liệu

::: dac-ta
**Mục đích.** Sửa nguồn số liệu.

**Phương thức, đường dẫn.** `PATCH /sources/{sourceCode}`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-009.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SourcePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataSource`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-015, ERR-16-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/sources/{sourceCode}

{"name": "Thống kê danh mục API PH-02", "cron": "0 0 3 * * ?",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "priority": 3, "staleAfterHours": 30,
 "description": "Cập nhật mô tả"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "ACTIVE",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-025 · Thử đọc nguồn

::: dac-ta
**Mục đích.** Thử đọc nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:test`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-009.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SourceTestResult`.

**Lỗi.** HTTP `404`, `422`; mã lỗi của thao tác: ERR-16-015, ERR-16-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thử đọc một lượt, không ghi quan sát. Cấu hình thiếu trường theo loại trả ERR-16-015; không đọc được trả ERR-16-016.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources/{sourceCode}:test
```

```http
HTTP/1.1 200 OK

{"ok": true, "elapsedMs": 180, "sampleMetrics": ["ph02.api.published"],
 "message": "Đọc được 3 chỉ số."}
```

#### API-16-026 · Tạm dừng nguồn

::: dac-ta
**Mục đích.** Tạm dừng nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:pause`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-013.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SourcePause`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataSource`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn `PAUSED` không bị chuyển `STALE`, `FAILED`; chỉ tiêu dùng nguồn này ghi `MISSING_SOURCE` khi tổng hợp.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources/{sourceCode}:pause

{"reason": "PH-08 bảo trì lược đồ KPI đến hết ngày 28/11.",
 "until": "2026-11-26T08:00:00+07:00"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "PAUSED",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-027 · Tiếp tục nguồn

::: dac-ta
**Mục đích.** Tiếp tục nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:resume`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-013.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataSource`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources/{sourceCode}:resume
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "ACTIVE",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-028 · Ngừng nguồn

::: dac-ta
**Mục đích.** Ngừng nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:retire`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-009.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataSource`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007, ERR-16-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn là nguồn duy nhất của chỉ tiêu đang hiệu lực thì trả ERR-16-017.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources/{sourceCode}:retire

{"reason": "Nguồn đã ngừng cung cấp theo công văn số 123 ngày 10/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sourceCode": "ph08-dq-kpi", "sourceType": "EVENT", "state": "RETIRED",
 "contract": {"metricCodes": ["ph08.dq.score"]}, "name": "Điểm chất lượng dữ liệu PH-08",
 "providerModule": "PH-08", "topic": "t68.dq.kpi.published.v1"}
```

#### API-16-029 · Kéo số liệu ngay hoặc đọc bù

::: dac-ta
**Mục đích.** Kéo số liệu ngay hoặc đọc bù.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:pull`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-011.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PullRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `IngestTask`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không thân: kéo ngay. Có `from`, `to` (tối đa 12 tháng): đọc bù. Chỉ với nguồn `PULL_API`; kết quả xem ở API-16-042.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/sources/{sourceCode}:pull
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"from": "2026-10-01", "to": "2026-10-31", "reason": "Đọc bù do mất sự kiện tháng 10."}
```

```http
HTTP/1.1 202 Accepted

{"ingestLogId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "sourceCode": "ph08-dq-kpi",
 "state": "QUEUED", "requestedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-030 · Nhận quan sát qua API đẩy

::: dac-ta
**Mục đích.** Nhận quan sát qua API đẩy.

**Phương thức, đường dẫn.** `POST /ingest/observations`.

**Quyền.** scope `kpi.ingest`.

**FR hiện thực.** FR-16-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ObservationBatch`; trường bắt buộc: `sourceCode`, `observations`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `IngestBatchResult`; `207`, `IngestBatchResult`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-101, ERR-16-102, ERR-16-103, ERR-16-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `kpi.ingest`, 1…500 quan sát mỗi lô. `202` khi mọi phần tử được nhận, `207` khi có phần tử lỗi (ERR-16-101…104 ở `results[].code`). Cùng `idempotencyRef` khác giá trị trả ERR-16-103; thuộc kỳ đã chốt thì lưu làm số trễ (ERR-16-104).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/ingest/observations
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"sourceCode": "ph08-dq-kpi",
 "observations": [{"metricCode": "ph08.dq.score", "value": 92.5, "periodStart": "2026-10-01",
   "periodEnd": "2026-10-31", "idempotencyRef": "snap-2026-10-31-T68"}]}
```

```http
HTTP/1.1 202 Accepted

{"accepted": 1, "duplicate": 0, "rejected": 0,
 "results": [{"index": 0, "status": "ACCEPTED"}]}
```

#### API-16-042 · Nhật ký tiếp nhận của nguồn

::: dac-ta
**Mục đích.** Nhật ký tiếp nhận của nguồn.

**Phương thức, đường dẫn.** `GET /sources/{sourceCode}/ingest-logs`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-010, FR-16-011, FR-16-016.

**Tham số.** `result` (query, IngestOutcome, tùy chọn); `metricCode` (query, string, tùy chọn); `periodCode` (query, string, tùy chọn); `code` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IngestLogPage`.

**Lỗi.** HTTP `400`, `404`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký theo lô, theo sự kiện và theo lần kéo; không chứa nội dung quan sát nhạy cảm.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/sources/{sourceCode}/ingest-logs
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "sourceCode": "ph08-dq-kpi",
   "result": "ACCEPTED", "receivedAt": "2026-11-26T08:00:00+07:00", "channel": "EVENT"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-043 · Danh sách quan sát

::: dac-ta
**Mục đích.** Danh sách quan sát.

**Phương thức, đường dẫn.** `GET /observations`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-010, FR-16-016, FR-16-039.

**Tham số.** `sourceCode` (query, string, tùy chọn); `metricCode` (query, string, tùy chọn); `periodCode` (query, string, tùy chọn); `late` (query, boolean, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ObservationPage`.

**Lỗi.** HTTP `400`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/observations
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "sourceCode": "ph08-dq-kpi",
   "metricCode": "ph08.dq.score", "value": 92.5, "periodStart": "2026-10-01"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-044 · Danh sách quan sát bị loại

::: dac-ta
**Mục đích.** Danh sách quan sát bị loại.

**Phương thức, đường dẫn.** `GET /rejected-observations`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-010, FR-16-016.

**Tham số.** `sourceCode` (query, string, tùy chọn); `metricCode` (query, string, tùy chọn); `periodCode` (query, string, tùy chọn); `code` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RejectedObservationPage`.

**Lỗi.** HTTP `400`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/rejected-observations
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "sourceCode": "ph08-dq-kpi",
   "code": "ERR-16-102", "result": "REJECTED", "receivedAt": "2026-11-26T08:00:00+07:00"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-045 · Xử lý lại quan sát bị loại

::: dac-ta
**Mục đích.** Xử lý lại quan sát bị loại.

**Phương thức, đường dẫn.** `POST /rejected-observations:reprocess`.

**Quyền.** `PERM-16-source`.

**FR hiện thực.** FR-16-016.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReprocessRequest`; trường bắt buộc: `ids`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReprocessResult`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `409` Xung đột.

**Ghi chú.** Chỉ quan sát bị loại do lỗi sửa được (ví dụ thiếu hợp đồng chỉ số); xử lý lại tối đa 500 mỗi lần.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/rejected-observations:reprocess

{"ids": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"],
 "reason": "Đã bổ sung chỉ số vào hợp đồng nguồn."}
```

```http
HTTP/1.1 200 OK

{"reprocessed": 1, "stillRejected": []}
```

### Số liệu nhập tay

#### API-16-031 · Danh sách số liệu nhập tay

::: dac-ta
**Mục đích.** Danh sách số liệu nhập tay.

**Phương thức, đường dẫn.** `GET /manual-values`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-014, FR-16-015.

**Tham số.** `indicatorCode` (query, string, tùy chọn); `periodCode` (query, string, tùy chọn); `state` (query, ManualState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValuePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/manual-values
```

```http
HTTP/1.1 200 OK

{"items": [{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
   "periodCode": "M-2026-10", "value": 1,
   "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành."}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-032 · Tạo số liệu nhập tay

::: dac-ta
**Mục đích.** Tạo số liệu nhập tay.

**Phương thức, đường dẫn.** `POST /manual-values`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ManualCreate`; trường bắt buộc: `indicatorCode`, `periodCode`, `value`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ManualValue`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-019, ERR-16-021, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bắt buộc bằng chứng khi `16.manual.evidence-required = true` (ERR-16-018 khi gửi xác nhận); giá trị ngoài miền trả ERR-16-019; kỳ đã chốt trả ERR-16-022.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"indicatorCode": "ho-so-cap-do-phe-duyet", "periodCode": "Q-2026-Q3", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.",
 "dimensions": {"don-vi": "so-tttt"},
 "evidence": [{"docNumber": "123/QĐ-UBND", "docDate": "2026-09-15"}]}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/manual-values/ma-moi

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", "state": "DRAFT",
 "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-033 · Chi tiết số liệu nhập tay

::: dac-ta
**Mục đích.** Chi tiết số liệu nhập tay.

**Phương thức, đường dẫn.** `GET /manual-values/{manualId}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-014, FR-16-015.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValue`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/manual-values/{manualId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", "state": "DRAFT",
 "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-034 · Sửa số liệu nhập tay nháp

::: dac-ta
**Mục đích.** Sửa số liệu nhập tay nháp.

**Phương thức, đường dẫn.** `PATCH /manual-values/{manualId}`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ManualUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-019, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/manual-values/{manualId}

{"value": 1, "dimensions": {"don-vi": "so-tttt"},
 "method": "Bổ sung phương pháp thu số liệu theo mẫu.",
 "evidence": [{"docNumber": "123/QĐ-UBND", "docDate": "2026-09-15"}]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", "state": "DRAFT",
 "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-035 · Đính kèm bằng chứng

::: dac-ta
**Mục đích.** Đính kèm bằng chứng.

**Phương thức, đường dẫn.** `POST /manual-values/{manualId}/evidence`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `ManualEvidenceUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ManualValue`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-053, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `multipart/form-data`; PDF, PNG, JPG, XLSX, DOCX tối đa `16.manual.max-file-mb` (ERR-16-053). Chỉ khi số liệu `DRAFT`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values/{manualId}/evidence
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1
Content-Type: multipart/form-data; boundary=ranh-gioi

--ranh-gioi
Content-Disposition: form-data; name="file"

(nội dung tệp)
--ranh-gioi
Content-Disposition: form-data; name="docNumber"

123/QĐ-UBND
--ranh-gioi
Content-Disposition: form-data; name="docDate"

2026-09-15
--ranh-gioi
Content-Disposition: form-data; name="description"

Quyết định phê duyệt
--ranh-gioi--
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/manual-values/ma-moi

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", "state": "DRAFT",
 "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-036 · Tải tệp mẫu nhập số liệu

::: dac-ta
**Mục đích.** Tải tệp mẫu nhập số liệu.

**Phương thức, đường dẫn.** `GET /manual-values/template`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** `periodCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Trả tệp XLSX mẫu mới nhất của các chỉ tiêu `MANUAL`, `MIXED`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/manual-values/template
```

```http
HTTP/1.1 200 OK
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet

(nội dung tệp)
```

#### API-16-037 · Tải tệp nhập số liệu lên xem trước

::: dac-ta
**Mục đích.** Tải tệp nhập số liệu lên xem trước.

**Phương thức, đường dẫn.** `POST /manual-values:import`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `ManualImportUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ManualImport`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-020, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `multipart/form-data`, tối đa 2.000 dòng và 10 MB; sai mẫu trả ERR-16-020. Chưa ghi số liệu: trả bản xem trước theo dòng.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values:import
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1
Content-Type: multipart/form-data; boundary=ranh-gioi

--ranh-gioi
Content-Disposition: form-data; name="file"

(nội dung tệp)
--ranh-gioi--
```

```http
HTTP/1.1 200 OK

{"importId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "rows": [{"row": 2, "status": "VALID", "errors": [], "indicatorCode": "ho-so-cap-do-phe-duyet",
   "periodCode": "Q-2026-Q3"}], "fileName": "nhap-so-lieu-q3.xlsx", "validCount": 1,
 "invalidCount": 0, "expiresAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-038 · Chốt nhập tệp đã xem trước

::: dac-ta
**Mục đích.** Chốt nhập tệp đã xem trước.

**Phương thức, đường dẫn.** `POST /manual-values/imports/{importId}:commit`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualImport`.

**Lỗi.** HTTP `404`, `409`; mã lỗi của thao tác: ERR-16-021, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi các dòng `VALID` thành số liệu `DRAFT`; dòng `INVALID` bị bỏ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values/imports/{importId}:commit
```

```http
HTTP/1.1 200 OK

{"importId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "rows": [{"row": 2, "status": "VALID", "errors": [], "indicatorCode": "ho-so-cap-do-phe-duyet",
   "periodCode": "Q-2026-Q3"}], "fileName": "nhap-so-lieu-q3.xlsx", "validCount": 1,
 "invalidCount": 0, "expiresAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-039 · Gửi số liệu nhập tay chờ xác nhận

::: dac-ta
**Mục đích.** Gửi số liệu nhập tay chờ xác nhận.

**Phương thức, đường dẫn.** `POST /manual-values/{manualId}:submit`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-014.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValue`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-018, ERR-16-019, ERR-16-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values/{manualId}:submit
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.",
 "state": "SUBMITTED", "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-040 · Xác nhận số liệu nhập tay

::: dac-ta
**Mục đích.** Xác nhận số liệu nhập tay.

**Phương thức, đường dẫn.** `POST /manual-values/{manualId}:accept`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-015.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-005, ERR-16-059, ERR-16-021 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người xác nhận khác người nhập (ERR-16-005) và thuộc `confirmerRoles` của chỉ tiêu (ERR-16-059); đã có số liệu `ACCEPTED` cho chỉ tiêu và kỳ trả ERR-16-021. Phát EVT-16-04.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values/{manualId}:accept

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.",
 "state": "ACCEPTED", "dimensions": {"don-vi": "so-tttt"}}
```

#### API-16-041 · Từ chối số liệu nhập tay

::: dac-ta
**Mục đích.** Từ chối số liệu nhập tay.

**Phương thức, đường dẫn.** `POST /manual-values/{manualId}:reject`.

**Quyền.** `PERM-16-manual`.

**FR hiện thực.** FR-16-015.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ManualValue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-005, ERR-16-059, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người từ chối thuộc `confirmerRoles` của chỉ tiêu (ERR-16-059); lý do từ 20 ký tự (ERR-16-007). Phát EVT-16-04.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/manual-values/{manualId}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"manualId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "periodCode": "M-2026-10", "value": 1,
 "method": "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.",
 "state": "REJECTED", "dimensions": {"don-vi": "so-tttt"}}
```

### Kỳ báo cáo và tổng hợp

#### API-16-046 · Danh sách kỳ báo cáo

::: dac-ta
**Mục đích.** Danh sách kỳ báo cáo.

**Phương thức, đường dẫn.** `GET /periods`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-017.

**Tham số.** `periodType` (query, PeriodType, tùy chọn); `state` (query, PeriodState, tùy chọn); `year` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PeriodPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/periods
```

```http
HTTP/1.1 200 OK

{"items": [{"periodCode": "M-2026-10", "periodType": "MONTH", "startDate": "2026-10-01",
   "endDate": "2026-10-31", "state": "COMPUTED"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-047 · Tạo kỳ báo cáo

::: dac-ta
**Mục đích.** Tạo kỳ báo cáo.

**Phương thức, đường dẫn.** `POST /periods`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-017.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PeriodCreate`; trường bắt buộc: `periodCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ReportingPeriod`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/periods
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"periodCode": "Q-2026-Q3", "reason": "Kỳ quý cho báo cáo gửi Bộ."}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/periods/ma-moi

{"periodCode": "M-2026-10", "periodType": "MONTH", "startDate": "2026-10-01",
 "endDate": "2026-10-31", "state": "COMPUTED", "closeDueDate": "2026-11-05",
 "lastRun": {"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
  "finishedAt": "2026-11-26T08:00:00+07:00", "completeness": 0.96}}
```

#### API-16-048 · Chi tiết kỳ báo cáo

::: dac-ta
**Mục đích.** Chi tiết kỳ báo cáo.

**Phương thức, đường dẫn.** `GET /periods/{periodCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-017, FR-16-020.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportingPeriod`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/periods/{periodCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"periodCode": "M-2026-10", "periodType": "MONTH", "startDate": "2026-10-01",
 "endDate": "2026-10-31", "state": "COMPUTED", "closeDueDate": "2026-11-05",
 "lastRun": {"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
  "finishedAt": "2026-11-26T08:00:00+07:00", "completeness": 0.96}}
```

#### API-16-049 · Danh sách lần tổng hợp

::: dac-ta
**Mục đích.** Danh sách lần tổng hợp.

**Phương thức, đường dẫn.** `GET /runs`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-018, FR-16-042.

**Tham số.** `periodCode` (query, string, tùy chọn); `state` (query, RunState, tùy chọn); `trigger` (query, RunTrigger, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RunPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/runs
```

```http
HTTP/1.1 200 OK

{"items": [{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
   "trigger": "MANUAL", "state": "SUCCEEDED", "requestedBy": "nguyen.thi.lan"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-050 · Chạy tổng hợp kỳ

::: dac-ta
**Mục đích.** Chạy tổng hợp kỳ.

**Phương thức, đường dẫn.** `POST /periods/{periodCode}/runs`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RunCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Run`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-022, ERR-16-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `trigger` chỉ nhận `MANUAL`; `SCHEDULE`, `LATE_DATA` do hệ thống đặt, `RECOMPUTE` qua API-16-055. Mỗi kỳ một lần chạy tại một thời điểm (ERR-16-023); kỳ `CLOSED` trả ERR-16-022. Lần chạy bắt đầu ở `QUEUED`, theo dõi ở API-16-051; phát EVT-16-05 khi xong.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/periods/{periodCode}/runs
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"trigger": "MANUAL", "indicatorCodes": ["mttd"],
 "reason": "Chạy lại sau khi PH-13 bổ sung chỉ số sự cố."}
```

```http
HTTP/1.1 202 Accepted

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
 "trigger": "MANUAL", "state": "QUEUED", "requestedBy": "nguyen.thi.lan",
 "reason": "Chạy lại sau khi PH-19 đẩy số trễ.", "startedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-051 · Chi tiết lần tổng hợp

::: dac-ta
**Mục đích.** Chi tiết lần tổng hợp.

**Phương thức, đường dẫn.** `GET /runs/{runId}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-018, FR-16-020.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Run`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/runs/{runId}
```

```http
HTTP/1.1 200 OK

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
 "trigger": "MANUAL", "state": "SUCCEEDED", "requestedBy": "nguyen.thi.lan",
 "reason": "Chạy lại sau khi PH-19 đẩy số trễ.", "startedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-052 · Hủy lần tổng hợp

::: dac-ta
**Mục đích.** Hủy lần tổng hợp.

**Phương thức, đường dẫn.** `POST /runs/{runId}:cancel`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-018.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Run`.

**Lỗi.** HTTP `400`, `404`, `422`; mã lỗi của thao tác: ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ hủy lần `QUEUED` hoặc `RUNNING`; PO được hủy lần treo của mọi tenant. Kết quả lần trước được giữ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/runs/{runId}:cancel

{"reason": "Nguồn đã ngừng cung cấp theo công văn số 123 ngày 10/11/2026."}
```

```http
HTTP/1.1 200 OK

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
 "trigger": "MANUAL", "state": "CANCELLED", "requestedBy": "nguyen.thi.lan",
 "reason": "Chạy lại sau khi PH-19 đẩy số trễ.", "startedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-053 · Giá trị chỉ tiêu của lần tổng hợp

::: dac-ta
**Mục đích.** Giá trị chỉ tiêu của lần tổng hợp.

**Phương thức, đường dẫn.** `GET /runs/{runId}/values`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-019, FR-16-020, FR-16-021.

**Tham số.** `indicatorCode` (query, string, tùy chọn); `groupCode` (query, GroupCode, tùy chọn); `status` (query, ValueStatus, tùy chọn); `completeness` (query, Completeness, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValuePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/runs/{runId}/values
```

```http
HTTP/1.1 200 OK

{"items": [{"valueId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
   "periodCode": "M-2026-10", "versionUsed": 2, "status": "AT_RISK"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-054 · Dòng truy nguồn của giá trị

::: dac-ta
**Mục đích.** Dòng truy nguồn của giá trị.

**Phương thức, đường dẫn.** `GET /values/{valueId}/lineage`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-019, FR-16-039.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Lineage`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Truy từng giá trị về quan sát, số liệu tay và phiên bản công thức đã dùng.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/values/{valueId}/lineage
```

```http
HTTP/1.1 200 OK

{"valueId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
 "versionUsed": 2,
 "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
 "inputs": [{"variable": "tong", "sourceKind": "OBSERVATION", "value": 200,
   "metricCode": "ph01.httt.total", "observationId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}]}
```

#### API-16-055 · Tính lại kỳ chưa chốt

::: dac-ta
**Mục đích.** Tính lại kỳ chưa chốt.

**Phương thức, đường dẫn.** `POST /periods/{periodCode}:recompute`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-023.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RecomputeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Run`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007, ERR-16-022, ERR-16-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ cho kỳ chưa chốt (ERR-16-022); gom yêu cầu trong cửa sổ `16.late-data.debounce-minutes`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/periods/{periodCode}:recompute
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reason": "Đổi công thức chỉ tiêu api-dat-sla-ty-le đã duyệt ngày 25/11.",
 "indicatorCodes": ["api-dat-sla-ty-le"]}
```

```http
HTTP/1.1 202 Accepted

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
 "trigger": "MANUAL", "state": "QUEUED", "requestedBy": "nguyen.thi.lan",
 "reason": "Chạy lại sau khi PH-19 đẩy số trễ.", "startedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-056 · Lịch sử đổi trạng thái chỉ tiêu trong kỳ

::: dac-ta
**Mục đích.** Lịch sử đổi trạng thái chỉ tiêu trong kỳ.

**Phương thức, đường dẫn.** `GET /periods/{periodCode}/status-changes`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-021.

**Tham số.** `indicatorCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatusChangePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/periods/{periodCode}/status-changes
```

```http
HTTP/1.1 200 OK

{"items": [{"indicatorCode": "httt-ket-noi-ty-le", "periodCode": "M-2026-10", "to": "AT_RISK",
   "at": "2026-11-26T08:00:00+07:00", "from": "ON_TRACK"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-16-057 · Chốt kỳ

::: dac-ta
**Mục đích.** Chốt kỳ.

**Phương thức, đường dẫn.** `POST /periods/{periodCode}:close`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-024.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `PeriodClose`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportingPeriod`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-025 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Còn chỉ tiêu `PARTIAL` thì cần `confirmPartial = true`, chỉ tiêu bắt buộc thiếu số thì ERR-16-025. Chỉ TA chốt.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/periods/{periodCode}:close

{"confirmPartial": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"periodCode": "M-2026-10", "periodType": "MONTH", "startDate": "2026-10-01",
 "endDate": "2026-10-31", "state": "CLOSED", "closeDueDate": "2026-11-05",
 "lastRun": {"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
  "finishedAt": "2026-11-26T08:00:00+07:00", "completeness": 0.96}}
```

#### API-16-058 · Mở lại kỳ đã chốt

::: dac-ta
**Mục đích.** Mở lại kỳ đã chốt.

**Phương thức, đường dẫn.** `POST /periods/{periodCode}:reopen`.

**Quyền.** `PERM-16-run`.

**FR hiện thực.** FR-16-024.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `PeriodReopen`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportingPeriod`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007, ERR-16-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ TA; kỳ còn báo cáo đang duyệt trả ERR-16-026. Lý do từ 50 ký tự (ERR-16-007).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/periods/{periodCode}:reopen

{"reason": "Phát hiện số liệu trễ của PH-19 ảnh hưởng chỉ tiêu bắt buộc, cần tính lại trước khi công bố.",
 "indicatorCodes": ["doi-soat-tu-dong-khop"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"periodCode": "M-2026-10", "periodType": "MONTH", "startDate": "2026-10-01",
 "endDate": "2026-10-31", "state": "REOPENED", "closeDueDate": "2026-11-05",
 "lastRun": {"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
  "finishedAt": "2026-11-26T08:00:00+07:00", "completeness": 0.96}}
```

### Mẫu báo cáo

#### API-16-059 · Danh sách mẫu báo cáo

::: dac-ta
**Mục đích.** Danh sách mẫu báo cáo.

**Phương thức, đường dẫn.** `GET /report-templates`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-025.

**Tham số.** `reportType` (query, ReportType, tùy chọn); `state` (query, TemplateState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplatePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/report-templates
```

```http
HTTP/1.1 200 OK

{"items": [{"templateCode": "bao-cao-thang-mau", "name": "Báo cáo chỉ tiêu tháng",
   "reportType": "PERIODIC",
   "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
     "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"]}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-060 · Tạo mẫu báo cáo

::: dac-ta
**Mục đích.** Tạo mẫu báo cáo.

**Phương thức, đường dẫn.** `POST /report-templates`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateCreate`; trường bắt buộc: `templateCode`, `name`, `reportType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ReportTemplate`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-002, ERR-16-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/report-templates
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"templateCode": "bao-cao-thang-mau", "name": "Báo cáo chỉ tiêu tháng",
 "reportType": "PERIODIC",
 "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
   "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"],
 "periodTypes": ["MONTH"],
 "letterhead": {"issuer": "UBND tỉnh T68", "formNo": "BM-KPI-01", "recipients": "Bộ Khoa học và Công nghệ"}}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/report-templates/ma-moi

{"templateCode": "bao-cao-thang-mau", "name": "Báo cáo chỉ tiêu tháng",
 "reportType": "PERIODIC",
 "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
   "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"],
 "state": "ACTIVE", "version": 1}
```

#### API-16-061 · Chi tiết mẫu báo cáo

::: dac-ta
**Mục đích.** Chi tiết mẫu báo cáo.

**Phương thức, đường dẫn.** `GET /report-templates/{templateCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-025.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportTemplate`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/report-templates/{templateCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"templateCode": "bao-cao-thang-mau", "name": "Báo cáo chỉ tiêu tháng",
 "reportType": "PERIODIC",
 "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
   "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"],
 "state": "ACTIVE", "version": 1}
```

#### API-16-062 · Sửa mẫu báo cáo

::: dac-ta
**Mục đích.** Sửa mẫu báo cáo.

**Phương thức, đường dẫn.** `PATCH /report-templates/{templateCode}`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-025.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `TemplatePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportTemplate`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/report-templates/{templateCode}

{"name": "Báo cáo chỉ tiêu tháng",
 "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
   "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"],
 "letterhead": {"issuer": "UBND tỉnh T68", "formNo": "BM-KPI-01", "recipients": "Bộ Khoa học và Công nghệ"}}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"templateCode": "bao-cao-thang-mau", "name": "Báo cáo chỉ tiêu tháng",
 "reportType": "PERIODIC",
 "sections": [{"type": "INDICATOR_TABLE", "sectionId": "s1", "title": "Chỉ tiêu nhóm Kết nối",
   "indicatorCodes": ["httt-ket-noi-ty-le"], "groupCode": "KET_NOI"}], "formats": ["PDF"],
 "state": "ACTIVE", "version": 1}
```

#### API-16-063 · Xem trước mẫu báo cáo

::: dac-ta
**Mục đích.** Xem trước mẫu báo cáo.

**Phương thức, đường dẫn.** `POST /report-templates/{templateCode}:preview`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-025.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `TemplatePreviewRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplatePreview`.

**Lỗi.** HTTP `400`, `404`, `422`; mã lỗi của thao tác: ERR-16-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả liên kết PDF tạm hết hạn sau 1 giờ; không tạo báo cáo.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/report-templates/{templateCode}:preview

{"periodCode": "M-2026-10"}
```

```http
HTTP/1.1 200 OK

{"templateCode": "bao-cao-thang-mau",
 "previewUrl": "https://console.t68.datahub.example.vn/tai/0193b1d4",
 "expiresAt": "2026-11-26T08:00:00+07:00"}
```

### Báo cáo

#### API-16-064 · Danh sách báo cáo

::: dac-ta
**Mục đích.** Danh sách báo cáo.

**Phương thức, đường dẫn.** `GET /reports`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-031.

**Tham số.** `q` (query, string, tùy chọn); `reportType` (query, ReportType, tùy chọn); `periodCode` (query, string, tùy chọn); `state` (query, ReportState, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/reports
```

```http
HTTP/1.1 200 OK

{"items": [{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
   "reportType": "PERIODIC", "state": "PUBLISHED", "latestVersion": 1}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-065 · Lập bản nháp báo cáo

::: dac-ta
**Mục đích.** Lập bản nháp báo cáo.

**Phương thức, đường dẫn.** `POST /reports`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-026, FR-16-032.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReportCreate`; trường bắt buộc: `reportCode`, `reportType`, `title`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Report`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-002, ERR-16-028, ERR-16-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `PERIODIC` và `NATIONAL` cần kỳ đã tính và chốt khi báo cáo chính thức (ERR-16-028); `AD_HOC` dùng `from`, `to` tối đa 24 tháng (ERR-16-033) và `indicatorCodes` 1…50. Trả danh sách `requiredExplanations`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reportCode": "bc-thang-2026-10", "reportType": "PERIODIC",
 "title": "Báo cáo chỉ tiêu tháng 10/2026", "templateCode": "bao-cao-thang-mau",
 "periodCode": "M-2026-10", "from": "2026-05-01", "to": "2026-10-31"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/reports/ma-moi

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "DRAFT", "latestVersion": 1, "periodCode": "M-2026-10",
 "rangeFrom": "2026-05-01"}
```

#### API-16-066 · Chi tiết báo cáo

::: dac-ta
**Mục đích.** Chi tiết báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-027, FR-16-031.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/reports/{reportCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "DRAFT", "latestVersion": 1, "periodCode": "M-2026-10",
 "rangeFrom": "2026-05-01"}
```

#### API-16-067 · Sửa tiêu đề, thuyết minh báo cáo nháp

::: dac-ta
**Mục đích.** Sửa tiêu đề, thuyết minh báo cáo nháp.

**Phương thức, đường dẫn.** `PATCH /reports/{reportCode}`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-027.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReportPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/reports/{reportCode}

{"title": "Báo cáo chỉ tiêu tháng 10/2026",
 "sections": [{"sectionId": "s1", "content": "Trong tháng 10, số HTTT kết nối tăng 6 hệ thống."}],
 "documentNumber": "125/BC-STTTT", "recipientsNote": "UBND tỉnh; Bộ KH&CN."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "DRAFT", "latestVersion": 1, "periodCode": "M-2026-10",
 "rangeFrom": "2026-05-01"}
```

#### API-16-068 · Lưu giải trình chỉ tiêu chệch

::: dac-ta
**Mục đích.** Lưu giải trình chỉ tiêu chệch.

**Phương thức, đường dẫn.** `PUT /reports/{reportCode}/explanations/{indicatorCode}`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-027.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ExplanationPut`; trường bắt buộc: `cause`, `action`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExplanationResult`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giải trình cho chỉ tiêu `AT_RISK`, `OFF_TRACK` hoặc thiếu số; báo cáo đã công bố trả ERR-16-032.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/kpi/v1/reports/{reportCode}/explanations/{indicatorCode}

{"cause": "Hai HTTT chưa hoàn tất nâng cấp giao thức kết nối.",
 "action": "Hoàn tất nâng cấp trước ngày 15/12.", "dueDate": "2026-12-15"}
```

```http
HTTP/1.1 200 OK

{"explanation": {"indicatorCode": "httt-ket-noi-ty-le",
  "cause": "Hai HTTT chưa hoàn tất nâng cấp giao thức kết nối.",
  "action": "Hoàn tất nâng cấp trước ngày 15/12.", "dueDate": "2026-12-15"},
 "missingExplanations": []}
```

#### API-16-069 · Làm mới số liệu của bản nháp

::: dac-ta
**Mục đích.** Làm mới số liệu của bản nháp.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:refresh`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-023, FR-16-026.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RefreshRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Run`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-022, ERR-16-023, ERR-16-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nạp lại số liệu của lần tổng hợp mới nhất vào bản nháp; có thể tạo lần tổng hợp mới (`202`).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:refresh
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reason": "Làm mới sau khi tính lại kỳ."}
```

```http
HTTP/1.1 202 Accepted

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
 "trigger": "MANUAL", "state": "QUEUED", "requestedBy": "nguyen.thi.lan",
 "reason": "Chạy lại sau khi PH-19 đẩy số trễ.", "startedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-070 · Xem trước báo cáo

::: dac-ta
**Mục đích.** Xem trước báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}/preview`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-026.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportPreview`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/reports/{reportCode}/preview
```

```http
HTTP/1.1 200 OK

{"reportCode": "bc-thang-2026-10", "version": 1,
 "previewUrl": "https://console.t68.datahub.example.vn/tai/0193b1d4",
 "expiresAt": "2026-11-26T08:00:00+07:00", "provisional": true, "missingExplanations": []}
```

#### API-16-071 · Gửi duyệt báo cáo

::: dac-ta
**Mục đích.** Gửi duyệt báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:submit`.

**Quyền.** `PERM-16-report`.

**FR hiện thực.** FR-16-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SubmitNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-029, ERR-16-030, ERR-16-061 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thiếu số chỉ tiêu bắt buộc trả ERR-16-029; còn chỉ tiêu chệch chưa giải trình trả ERR-16-030; báo cáo chính thức thiếu `documentNumber` hoặc `recipientsNote` trả ERR-16-061. Phát EVT-16-07.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:submit

{"note": "Gửi duyệt báo cáo tháng 10."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "IN_REVIEW", "latestVersion": 1,
 "periodCode": "M-2026-10", "rangeFrom": "2026-05-01"}
```

#### API-16-072 · Duyệt báo cáo

::: dac-ta
**Mục đích.** Duyệt báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:approve`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người lập, gửi (bốn mắt, ERR-16-005; `16.report.four-eyes` chỉ ảnh hưởng báo cáo `AD_HOC`).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "APPROVED", "latestVersion": 1,
 "periodCode": "M-2026-10", "rangeFrom": "2026-05-01"}
```

#### API-16-073 · Yêu cầu sửa báo cáo

::: dac-ta
**Mục đích.** Yêu cầu sửa báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:request-changes`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-005, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Báo cáo `IN_REVIEW` (yêu cầu sửa) hoặc `APPROVED` chưa công bố (trả về soạn) chuyển `CHANGES_REQUESTED`; lý do từ 20 ký tự. Người lập sửa rồi gửi lại. Phát EVT-16-09.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:request-changes

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "CHANGES_REQUESTED", "latestVersion": 1,
 "periodCode": "M-2026-10", "rangeFrom": "2026-05-01"}
```

#### API-16-074 · Công bố báo cáo chính thức

::: dac-ta
**Mục đích.** Công bố báo cáo chính thức.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:publish`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-029.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `PublishRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-16-005, ERR-16-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chụp bất biến, dựng PDF, ký số, lưu WORM rồi mới chuyển `PUBLISHED`. Ký số lỗi trả ERR-16-031 (báo cáo vẫn `APPROVED`). Phát EVT-16-08.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:publish

{"publishNote": "Công bố báo cáo tháng 10."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "PUBLISHED", "latestVersion": 1,
 "periodCode": "M-2026-10", "rangeFrom": "2026-05-01"}
```

#### API-16-075 · Đính chính báo cáo đã công bố

::: dac-ta
**Mục đích.** Đính chính báo cáo đã công bố.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:correct`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-030.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CorrectRequest`; trường bắt buộc: `reason`, `correctionNote`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Report`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo phiên bản mới `DRAFT` mang `correctionNote`; bản cũ chuyển `SUPERSEDED` khi bản mới được công bố.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:correct
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reason": "Sửa số liệu chỉ tiêu mttd do PH-13 hiệu chỉnh lại số sự cố tháng 10.",
 "correctionNote": "Bản này thay thế bản 1: sửa chỉ tiêu mttd từ 42 phút còn 38 phút."}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/reports/ma-moi

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "DRAFT", "latestVersion": 1, "periodCode": "M-2026-10",
 "rangeFrom": "2026-05-01"}
```

#### API-16-076 · Rút báo cáo đã công bố

::: dac-ta
**Mục đích.** Rút báo cáo đã công bố.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:withdraw`.

**Quyền.** `PERM-16-approve`.

**FR hiện thực.** FR-16-030.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `Reason50Body`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Báo cáo chuyển `WITHDRAWN`, vẫn tra được; phát EVT-16-09.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/reports/{reportCode}:withdraw

{"reason": "Phát hiện sai số liệu ở chỉ tiêu bắt buộc sau khi công bố, cần rút để đính chính theo quy trình."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "bc-thang-2026-10", "title": "Báo cáo chỉ tiêu tháng 10/2026",
 "reportType": "PERIODIC", "state": "WITHDRAWN", "latestVersion": 1,
 "periodCode": "M-2026-10", "rangeFrom": "2026-05-01"}
```

#### API-16-077 · Lịch sử phiên bản báo cáo

::: dac-ta
**Mục đích.** Lịch sử phiên bản báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}/versions`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-031.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportVersionPage`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/reports/{reportCode}/versions
```

```http
HTTP/1.1 200 OK

{"items": [{"version": 1, "state": "PUBLISHED", "runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "preparedBy": "nguyen.thi.lan", "publishedAt": "2026-11-26T08:00:00+07:00"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-078 · Hàng đợi chờ duyệt, chờ xác nhận

::: dac-ta
**Mục đích.** Hàng đợi chờ duyệt, chờ xác nhận.

**Phương thức, đường dẫn.** `GET /review-queue`.

**Quyền.** `PERM-16-approve hoặc PERM-16-manual`.

**FR hiện thực.** FR-16-005, FR-16-015, FR-16-028.

**Tham số.** `itemType` (query, ReviewItemType, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewQueuePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Việc của người dùng: định nghĩa chờ duyệt, số liệu tay chờ xác nhận, báo cáo chờ duyệt, loại trừ việc do chính người dùng gửi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/review-queue
```

```http
HTTP/1.1 200 OK

{"items": [{"itemType": "REPORT", "ref": "bc-thang-2026-10",
   "title": "Báo cáo chỉ tiêu tháng 10/2026", "submittedBy": "nguyen.thi.lan",
   "submittedAt": "2026-11-26T08:00:00+07:00"}], "page": 0, "size": 20, "totalElements": 1,
 "facets": {"INDICATOR_VERSION": 2, "MANUAL_VALUE": 5, "REPORT": 1}}
```

#### API-16-088 · Bằng chứng công bố báo cáo

::: dac-ta
**Mục đích.** Bằng chứng công bố báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}/evidence`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-036.

**Tham số.** `version` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublishEvidence`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Trả kết quả kiểm lại mã băm và chữ ký; không khớp ghi ERR-16-124 và báo SO.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/reports/{reportCode}/evidence
```

```http
HTTP/1.1 200 OK

{"reportCode": "bc-thang-2026-10", "version": 1, "verified": true,
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
 "signature": {"signer": "tran.van.nam", "signedAt": "2026-11-26T08:00:00+07:00",
  "certificateSerial": "5F3A9C01", "format": "PAdES-B-LT"},
 "downloadUrl": "https://console.t68.datahub.example.vn/tai/0193b1d4",
 "expiresAt": "2026-11-26T08:00:00+07:00"}
```

### Xuất và phân phối

#### API-16-079 · Yêu cầu xuất tệp

::: dac-ta
**Mục đích.** Yêu cầu xuất tệp.

**Phương thức, đường dẫn.** `POST /exports`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-033, FR-16-049.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportCreate`; trường bắt buộc: `subject`, `subjectRef`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportJob`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-034, ERR-16-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ; vượt `16.export.max-rows` trả ERR-16-034. Người yêu cầu nhận EVT-16-13. AU chỉ xuất báo cáo đã công bố và nhật ký.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/exports
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"subject": "REPORT",
 "subjectRef": {"reportCode": "bc-thang-2026-10", "version": 1, "periodCode": "M-2026-10",
  "filter": {"groupCode": "KET_NOI"}, "rootComponent": "httt-qlvb"}, "format": "PDF"}
```

```http
HTTP/1.1 202 Accepted

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "subject": "REPORT", "format": "PDF",
 "state": "QUEUED", "requestedBy": "nguyen.thi.lan", "rowCount": 24,
 "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"}
```

#### API-16-080 · Trạng thái việc xuất

::: dac-ta
**Mục đích.** Trạng thái việc xuất.

**Phương thức, đường dẫn.** `GET /exports/{exportId}`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-033, FR-16-049.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportJob`.

**Lỗi.** HTTP `404`, `410`; mã lỗi của thao tác: ERR-16-035, ERR-16-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/exports/{exportId}
```

```http
HTTP/1.1 200 OK

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "subject": "REPORT", "format": "PDF",
 "state": "SUCCEEDED", "requestedBy": "nguyen.thi.lan", "rowCount": 24,
 "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"}
```

#### API-16-081 · Tải tệp đã xuất

::: dac-ta
**Mục đích.** Tải tệp đã xuất.

**Phương thức, đường dẫn.** `GET /exports/{exportId}/file`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-033, FR-16-049.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** HTTP `404`, `410`; mã lỗi của thao tác: ERR-16-035, ERR-16-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Liên kết hết hạn sau `16.export.link-hours` trả `410` ERR-16-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/exports/{exportId}/file
```

```http
HTTP/1.1 200 OK
Content-Type: application/octet-stream

(nội dung tệp)
```

#### API-16-082 · Danh sách phân phối

::: dac-ta
**Mục đích.** Danh sách phân phối.

**Phương thức, đường dẫn.** `GET /distributions`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-034.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DistributionPage`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/distributions
```

```http
HTTP/1.1 200 OK

{"items": [{"distributionCode": "lanh-dao-tinh", "name": "Lãnh đạo UBND tỉnh",
   "recipients": [{"type": "EMAIL", "ref": "lanh-dao@t68.gov.vn"}], "active": true,
   "reportTypes": ["PERIODIC"]}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-083 · Tạo danh sách phân phối

::: dac-ta
**Mục đích.** Tạo danh sách phân phối.

**Phương thức, đường dẫn.** `POST /distributions`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-034.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DistributionCreate`; trường bắt buộc: `distributionCode`, `name`, `recipients`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Distribution`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/distributions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"distributionCode": "lanh-dao-tinh", "name": "Lãnh đạo UBND tỉnh",
 "recipients": [{"type": "EMAIL", "ref": "lanh-dao@t68.gov.vn"}],
 "reportTypes": ["PERIODIC"], "periodTypes": ["MONTH"], "attach": "LINK", "active": true}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/distributions/ma-moi

{"distributionCode": "lanh-dao-tinh", "name": "Lãnh đạo UBND tỉnh",
 "recipients": [{"type": "EMAIL", "ref": "lanh-dao@t68.gov.vn"}], "active": true,
 "reportTypes": ["PERIODIC"], "periodTypes": ["MONTH"], "attach": "LINK"}
```

#### API-16-084 · Sửa danh sách phân phối

::: dac-ta
**Mục đích.** Sửa danh sách phân phối.

**Phương thức, đường dẫn.** `PATCH /distributions/{distributionCode}`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-034.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DistributionPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Distribution`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/distributions/{distributionCode}

{"name": "Lãnh đạo UBND tỉnh", "reportTypes": ["PERIODIC"], "periodTypes": ["MONTH"],
 "recipients": [{"type": "EMAIL", "ref": "lanh-dao@t68.gov.vn"}], "attach": "PDF",
 "active": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"distributionCode": "lanh-dao-tinh", "name": "Lãnh đạo UBND tỉnh",
 "recipients": [{"type": "EMAIL", "ref": "lanh-dao@t68.gov.vn"}], "active": true,
 "reportTypes": ["PERIODIC"], "periodTypes": ["MONTH"], "attach": "LINK"}
```

#### API-16-085 · Lịch sử gửi của danh sách phân phối

::: dac-ta
**Mục đích.** Lịch sử gửi của danh sách phân phối.

**Phương thức, đường dẫn.** `GET /distributions/{distributionCode}/deliveries`.

**Quyền.** `PERM-16-export`.

**FR hiện thực.** FR-16-034.

**Tham số.** `state` (query, DeliveryState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DeliveryPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/distributions/{distributionCode}/deliveries
```

```http
HTTP/1.1 200 OK

{"items": [{"reportCode": "bc-thang-2026-10", "recipient": "lanh-dao@t68.gov.vn", "state": "SENT",
   "version": 1, "attempt": 1}], "page": 0, "size": 20, "totalElements": 1}
```

### Cung cấp số liệu

#### API-16-086 · Đọc giá trị chỉ tiêu cho hệ khác

::: dac-ta
**Mục đích.** Đọc giá trị chỉ tiêu cho hệ khác.

**Phương thức, đường dẫn.** `GET /feed/indicator-values`.

**Quyền.** scope `kpi.read`.

**FR hiện thực.** FR-16-035.

**Tham số.** `periodCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `indicatorCodes` (query, array, tùy chọn); `groupCode` (query, GroupCode, tùy chọn); `onlyOfficial` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeedValuePage`.

**Lỗi.** HTTP `400`; mã lỗi của thao tác: ERR-16-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ scope `kpi.read`. `onlyOfficial` mặc định `true` (kỳ đã chốt); `false` kèm `provisional`. `Cache-Control: max-age=300`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/feed/indicator-values
```

```http
HTTP/1.1 200 OK

{"items": [{"indicatorCode": "httt-ket-noi-ty-le", "periodCode": "M-2026-10", "status": "AT_RISK",
   "completeness": "COMPLETE", "provisional": false}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-16-087 · Đọc báo cáo đã công bố cho hệ khác

::: dac-ta
**Mục đích.** Đọc báo cáo đã công bố cho hệ khác.

**Phương thức, đường dẫn.** `GET /feed/reports`.

**Quyền.** scope `kpi.read`.

**FR hiện thực.** FR-16-035.

**Tham số.** `periodCode` (query, string, tùy chọn); `reportType` (query, ReportType, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeedReportPage`.

**Lỗi.** HTTP `400`; mã lỗi của thao tác: ERR-16-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ scope `kpi.read`, chỉ báo cáo `PUBLISHED`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/feed/reports
```

```http
HTTP/1.1 200 OK

{"items": [{"reportCode": "bc-thang-2026-10", "reportType": "PERIODIC", "version": 1,
   "publishedAt": "2026-11-26T08:00:00+07:00", "title": "Báo cáo chỉ tiêu tháng 10/2026"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-089 · Thẻ chỉ tiêu cho trang Tổng quan

::: dac-ta
**Mục đích.** Thẻ chỉ tiêu cho trang Tổng quan.

**Phương thức, đường dẫn.** `GET /cards`.

**Quyền.** `PERM-16-read hoặc scope `kpi.read``.

**FR hiện thực.** FR-16-037.

**Tham số.** `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CardSet`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Người dùng cần `PERM-16-read`, hệ khác cần scope `kpi.read`; số liệu theo kỳ đã chốt gần nhất, có số tạm thì `provisional`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/cards
```

```http
HTTP/1.1 200 OK

{"cards": [{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ HTTT kết nối nền tảng",
   "displayValue": "82,5", "status": "AT_RISK", "periodCode": "M-2026-10"}]}
```

### Bảng điều khiển

#### API-16-090 · Bảng điều khiển năm nhóm

::: dac-ta
**Mục đích.** Bảng điều khiển năm nhóm.

**Phương thức, đường dẫn.** `GET /dashboard`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-022, FR-16-038, FR-16-040.

**Tham số.** `periodCode` (query, string, tùy chọn); `compareTo` (query, string, tùy chọn); `view` (query, DashboardView, tùy chọn); `groupCode` (query, GroupCode, tùy chọn); `status` (query, ValueStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dashboard`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** `view = OFFICIAL` chỉ kỳ đã chốt, `LATEST` gồm số tạm; có `compareTo` thì thêm `comparison`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/dashboard
```

```http
HTTP/1.1 200 OK

{"periodCode": "M-2026-10", "view": "LATEST",
 "groups": [{"groupCode": "KET_NOI", "weight": 20, "score": 82.5, "coverage": 0.96, "delta": 2.1}],
 "statusCounts": {"ON_TRACK": 12, "AT_RISK": 6, "OFF_TRACK": 2, "NO_DATA": 4},
 "provisional": true, "overallScore": 76.4,
 "attention": [{"indicatorCode": "httt-ket-noi-ty-le", "name": "Tỷ lệ API đạt SLA", "status": "OFF_TRACK",
   "displayValue": "71,0", "targetDisplay": "90"}]}
```

#### API-16-091 · Chuỗi thời gian của chỉ tiêu

::: dac-ta
**Mục đích.** Chuỗi thời gian của chỉ tiêu.

**Phương thức, đường dẫn.** `GET /indicators/{indicatorCode}/series`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-039, FR-16-040.

**Tham số.** `periodType` (query, PeriodType, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `compareTo` (query, string, tùy chọn); `lineage` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Series`.

**Lỗi.** HTTP `400`, `404`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/indicators/{indicatorCode}/series
```

```http
HTTP/1.1 200 OK

{"indicatorCode": "httt-ket-noi-ty-le",
 "series": [{"periodCode": "M-2026-10", "value": 82.5, "status": "AT_RISK", "completeness": "COMPLETE",
   "version": 2}],
 "definition": {"indicatorCode": "httt-ket-noi-ty-le", "version": 3, "state": "DRAFT",
  "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
  "variables": [{"alias": "tong", "metricCode": "ph01.httt.total"}]}, "targetLine": 90,
 "lineage": [{"valueId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "indicatorCode": "httt-ket-noi-ty-le",
   "versionUsed": 2,
   "formula": "obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100",
   "inputs": [{"variable": "tong", "sourceKind": "OBSERVATION", "value": 200,
     "metricCode": "ph01.httt.total",
     "observationId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}]}]}
```

#### API-16-092 · So sánh liên tenant ẩn danh

::: dac-ta
**Mục đích.** So sánh liên tenant ẩn danh.

**Phương thức, đường dẫn.** `GET /cross-tenant/comparison`.

**Quyền.** `PERM-16-compare`.

**FR hiện thực.** FR-16-041.

**Tham số.** `indicatorCode` (query, string, bắt buộc); `periodCode` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Comparison`.

**Lỗi.** HTTP `400`, `422`; mã lỗi của thao tác: ERR-16-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ chỉ tiêu mẫu `COMMON`; dưới `16.compare.min-tenants` trả ERR-16-038. Tên tỉnh được thay bằng bí danh.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/cross-tenant/comparison?indicatorCode=httt-ket-noi-ty-le&periodCode=M-2026-10
```

```http
HTTP/1.1 200 OK

{"indicatorCode": "httt-ket-noi-ty-le", "periodCode": "M-2026-10",
 "distribution": {"min": 40, "p25": 55, "median": 68, "p75": 80, "max": 92},
 "tenants": [{"alias": "Tỉnh A", "value": 68, "status": "AT_RISK"}], "tenantCount": 5,
 "rank": 2, "peerCount": 4}
```

#### API-16-093 · Tình trạng thu thập, tính toán

::: dac-ta
**Mục đích.** Tình trạng thu thập, tính toán.

**Phương thức, đường dẫn.** `GET /ops/overview`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-042.

**Tham số.** `tenantId` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OpsOverview`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/ops/overview
```

```http
HTTP/1.1 200 OK

{"sources": {"ACTIVE": 20, "STALE": 1, "FAILED": 0, "PAUSED": 1},
 "runs": [{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "periodCode": "M-2026-10",
   "trigger": "MANUAL", "state": "SUCCEEDED", "requestedBy": "nguyen.thi.lan"}],
 "outboxLagSeconds": 2, "exports": {"running": 0, "failed24h": 0},
 "national": {"pending": 0, "failed": 0, "lastAcknowledgedAt": "2026-11-26T08:00:00+07:00"}}
```

### Sổ kiến trúc

#### API-16-094 · Danh sách thành phần kiến trúc

::: dac-ta
**Mục đích.** Danh sách thành phần kiến trúc.

**Phương thức, đường dẫn.** `GET /arch/components`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-043.

**Tham số.** `q` (query, string, tùy chọn); `componentType` (query, ComponentType, tùy chọn); `lifecycle` (query, Lifecycle, tùy chọn); `opsStatus` (query, OpsStatus, tùy chọn); `complianceLevel` (query, ComplianceLevel, tùy chọn); `origin` (query, Origin, tùy chọn); `ownerOrgId` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ArchComponentPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/arch/components
```

```http
HTTP/1.1 200 OK

{"items": [{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
   "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP"}], "page": 0,
 "size": 20, "totalElements": 1,
 "facets": {"byGroup": {"KET_NOI": 5, "CHIA_SE": 7}, "byState": {"ACTIVE": 22, "DRAFT": 2},
  "byMeasurement": {"AUTO": 18, "MANUAL": 4, "MIXED": 2}}}
```

#### API-16-095 · Khai báo thành phần kiến trúc

::: dac-ta
**Mục đích.** Khai báo thành phần kiến trúc.

**Phương thức, đường dẫn.** `POST /arch/components`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-045.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ComponentCreate`; trường bắt buộc: `componentCode`, `name`, `componentType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ArchComponent`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-002, ERR-16-039, ERR-16-041 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/components
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "ownerOrgId": "org-vp-ubnd",
 "description": "Phục vụ văn bản điện tử liên thông", "externalRef": "000.00.68.H01"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/arch/ma-moi

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP", "origin": "MANUAL",
 "complianceLevel": "PARTIAL"}
```

#### API-16-096 · Chi tiết thành phần kiến trúc

::: dac-ta
**Mục đích.** Chi tiết thành phần kiến trúc.

**Phương thức, đường dẫn.** `GET /arch/components/{componentCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-043, FR-16-045, FR-16-046.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ArchComponent`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/arch/components/{componentCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP", "origin": "MANUAL",
 "complianceLevel": "PARTIAL"}
```

#### API-16-097 · Sửa thành phần kiến trúc

::: dac-ta
**Mục đích.** Sửa thành phần kiến trúc.

**Phương thức, đường dẫn.** `PATCH /arch/components/{componentCode}`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ComponentPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ArchComponent`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/arch/components/{componentCode}

{"name": "Hệ thống quản lý văn bản tỉnh", "ownerOrgId": "org-vp-ubnd",
 "description": "Phục vụ văn bản điện tử liên thông", "externalRef": "000.00.68.H01"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP", "origin": "MANUAL",
 "complianceLevel": "PARTIAL"}
```

#### API-16-098 · Thêm phiên bản thành phần

::: dac-ta
**Mục đích.** Thêm phiên bản thành phần.

**Phương thức, đường dẫn.** `POST /arch/components/{componentCode}/versions`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-045.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ComponentVersionAdd`; trường bắt buộc: `version`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ArchComponent`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-16-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/components/{componentCode}/versions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"version": "2.4.0", "releasedOn": "2026-11-20",
 "specRef": "https://git.t68.example.vn/specs/qlvb",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
 "changeNote": "Thêm chức năng ký số."}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/arch/ma-moi

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP", "origin": "MANUAL",
 "complianceLevel": "PARTIAL"}
```

#### API-16-099 · Đặt phụ thuộc của thành phần

::: dac-ta
**Mục đích.** Đặt phụ thuộc của thành phần.

**Phương thức, đường dẫn.** `PUT /arch/components/{componentCode}/dependencies`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DependenciesPut`; trường bắt buộc: `dependsOn`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ComponentDependencies`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-041 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/kpi/v1/arch/components/{componentCode}/dependencies

{"dependsOn": [{"componentCode": "httt-qlvb", "dependencyType": "CALLS", "kind": "MANUAL"}]}
```

```http
HTTP/1.1 200 OK

{"componentCode": "httt-qlvb",
 "dependencies": [{"componentCode": "httt-qlvb", "dependencyType": "CALLS", "kind": "MANUAL"}]}
```

#### API-16-100 · Chuyển vòng đời thành phần

::: dac-ta
**Mục đích.** Chuyển vòng đời thành phần.

**Phương thức, đường dẫn.** `POST /arch/components/{componentCode}:change-lifecycle`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `LifecycleChange`; trường bắt buộc: `lifecycle`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ArchComponent`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/components/{componentCode}:change-lifecycle

{"lifecycle": "DEPRECATED", "reason": "Chuyển sang hệ thống mới từ 01/2027."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"componentCode": "httt-qlvb", "name": "Hệ thống quản lý văn bản tỉnh",
 "componentType": "HTTT", "lifecycle": "ACTIVE", "opsStatus": "UP", "origin": "MANUAL",
 "complianceLevel": "PARTIAL"}
```

#### API-16-101 · Tự đăng ký thành phần qua API

::: dac-ta
**Mục đích.** Tự đăng ký thành phần qua API.

**Phương thức, đường dẫn.** `POST /ingest/arch-components`.

**Quyền.** scope `arch.register`.

**FR hiện thực.** FR-16-044.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ArchIngestBatch`; trường bắt buộc: `components`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ArchIngestResult`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `arch.register`. `202` kèm kết quả từng thành phần; thiếu trường hoặc sai loại trả ERR-16-039 ở `results[].code`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/ingest/arch-components
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"components": [{"componentCode": "httt-qlvb", "componentType": "API", "name": "API tra cứu hộ tịch",
   "version": "1.4.0", "lifecycle": "ACTIVE"}]}
```

```http
HTTP/1.1 202 Accepted

{"results": [{"componentCode": "api-tra-cuu-ho-tich", "status": "CREATED"}]}
```

### Tuân thủ kiến trúc

#### API-16-102 · Danh sách bộ tiêu chí tuân thủ

::: dac-ta
**Mục đích.** Danh sách bộ tiêu chí tuân thủ.

**Phương thức, đường dẫn.** `GET /compliance/criteria-sets`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-047.

**Tham số.** `state` (query, CriteriaSetState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CriteriaSetPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/compliance/criteria-sets
```

```http
HTTP/1.1 200 OK

{"items": [{"version": 2, "state": "ACTIVE",
   "criteria": [{"criterionCode": "KT-ATTT-01", "name": "Có hồ sơ cấp độ an toàn thông tin",
     "description": "Theo Khung KT CPĐT 3.0", "appliesTo": ["HTTT"], "mandatory": true}],
   "name": "Bộ tiêu chí theo Khung KT CPĐT 3.0", "activatedAt": "2026-11-26T08:00:00+07:00"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-103 · Tạo phiên bản bộ tiêu chí

::: dac-ta
**Mục đích.** Tạo phiên bản bộ tiêu chí.

**Phương thức, đường dẫn.** `POST /compliance/criteria-sets`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CriteriaSetCreate`; trường bắt buộc: `criteria`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CriteriaSet`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-045 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/compliance/criteria-sets
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"criteria": [{"criterionCode": "KT-ATTT-01", "name": "Có hồ sơ cấp độ an toàn thông tin",
   "description": "Theo Khung KT CPĐT 3.0", "appliesTo": ["HTTT"], "mandatory": true}],
 "name": "Bộ tiêu chí theo Khung KT CPĐT 3.0"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/compliance/ma-moi

{"version": 2, "state": "ACTIVE",
 "criteria": [{"criterionCode": "KT-ATTT-01", "name": "Có hồ sơ cấp độ an toàn thông tin",
   "description": "Theo Khung KT CPĐT 3.0", "appliesTo": ["HTTT"], "mandatory": true}],
 "name": "Bộ tiêu chí theo Khung KT CPĐT 3.0", "activatedAt": "2026-11-26T08:00:00+07:00",
 "createdAt": "2026-11-26T08:00:00+07:00", "createdBy": "nguyen.thi.lan"}
```

#### API-16-104 · Kích hoạt phiên bản bộ tiêu chí

::: dac-ta
**Mục đích.** Kích hoạt phiên bản bộ tiêu chí.

**Phương thức, đường dẫn.** `POST /compliance/criteria-sets/{version}:activate`.

**Quyền.** `PERM-16-admin`.

**FR hiện thực.** FR-16-047.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CriteriaSet`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-045 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên bản đang `ACTIVE` chuyển `SUPERSEDED`; đánh giá đã xác nhận giữ phiên bản tiêu chí cũ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/compliance/criteria-sets/{version}:activate
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"version": 2, "state": "ACTIVE",
 "criteria": [{"criterionCode": "KT-ATTT-01", "name": "Có hồ sơ cấp độ an toàn thông tin",
   "description": "Theo Khung KT CPĐT 3.0", "appliesTo": ["HTTT"], "mandatory": true}],
 "name": "Bộ tiêu chí theo Khung KT CPĐT 3.0", "activatedAt": "2026-11-26T08:00:00+07:00",
 "createdAt": "2026-11-26T08:00:00+07:00", "createdBy": "nguyen.thi.lan"}
```

#### API-16-105 · Lập đánh giá tuân thủ

::: dac-ta
**Mục đích.** Lập đánh giá tuân thủ.

**Phương thức, đường dẫn.** `POST /arch/components/{componentCode}/assessments`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AssessmentCreate`; trường bắt buộc: `criteriaSetVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Assessment`; tiêu đề `ETag`, `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/components/{componentCode}/assessments
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"criteriaSetVersion": 2, "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/arch/ma-moi

{"assessmentId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "criteriaSetVersion": 2, "state": "DRAFT",
 "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL", "confirmedLevel": "PARTIAL"}
```

#### API-16-106 · Sửa đánh giá nháp

::: dac-ta
**Mục đích.** Sửa đánh giá nháp.

**Phương thức, đường dẫn.** `PATCH /arch/assessments/{assessmentId}`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AssessmentPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Assessment`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/arch/assessments/{assessmentId}

{"results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "COMPLIANT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assessmentId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "criteriaSetVersion": 2, "state": "DRAFT",
 "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL", "confirmedLevel": "PARTIAL"}
```

#### API-16-107 · Gửi đánh giá chờ xác nhận

::: dac-ta
**Mục đích.** Gửi đánh giá chờ xác nhận.

**Phương thức, đường dẫn.** `POST /arch/assessments/{assessmentId}:submit`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Assessment`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/assessments/{assessmentId}:submit
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assessmentId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "criteriaSetVersion": 2, "state": "SUBMITTED",
 "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL", "confirmedLevel": "PARTIAL"}
```

#### API-16-108 · Xác nhận đánh giá

::: dac-ta
**Mục đích.** Xác nhận đánh giá.

**Phương thức, đường dẫn.** `POST /arch/assessments/{assessmentId}:confirm`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Assessment`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-005, ERR-16-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người xác nhận khác người lập (ERR-16-005). Mức tuân thủ của thành phần đổi; phát EVT-16-11.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/assessments/{assessmentId}:confirm

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assessmentId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "criteriaSetVersion": 2, "state": "CONFIRMED",
 "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL", "confirmedLevel": "PARTIAL"}
```

#### API-16-109 · Từ chối đánh giá

::: dac-ta
**Mục đích.** Từ chối đánh giá.

**Phương thức, đường dẫn.** `POST /arch/assessments/{assessmentId}:reject`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Assessment`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-005, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/assessments/{assessmentId}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assessmentId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "criteriaSetVersion": 2, "state": "REJECTED",
 "results": [{"criterionCode": "KT-ATTT-01", "result": "PASS",
   "evidence": "Quyết định cấp độ 3 số 123/QĐ-UBND", "note": "Đạt."}],
 "proposedLevel": "PARTIAL", "confirmedLevel": "PARTIAL"}
```

#### API-16-110 · Cấp miễn trừ có hạn

::: dac-ta
**Mục đích.** Cấp miễn trừ có hạn.

**Phương thức, đường dẫn.** `POST /arch/components/{componentCode}/waivers`.

**Quyền.** `PERM-16-arch-assess`.

**FR hiện thực.** FR-16-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WaiverCreate`; trường bắt buộc: `reason`, `until`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Waiver`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-044, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn tối đa `16.compliance.waiver-max-days` (ERR-16-044); hết hạn thì thành phần trở lại mức trước, phát EVT-16-11.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/components/{componentCode}/waivers
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reason": "Hệ thống sẽ ngừng ngày 30/06/2027, không nâng cấp để đạt tiêu chí này.",
 "until": "2027-03-31", "criterionCode": "KT-ATTT-01",
 "planNote": "Chuyển sang hệ thống mới trước hạn."}
```

```http
HTTP/1.1 201 Created

{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "componentCode": "httt-qlvb",
 "reason": "Hệ thống sẽ ngừng ngày 30/06/2027.", "until": "2027-03-31", "state": "ACTIVE",
 "criterionCode": "KT-ATTT-01", "planNote": "Chuyển sang hệ thống mới trước hạn."}
```

#### API-16-111 · Đối chiếu sổ kiến trúc với phân hệ nguồn

::: dac-ta
**Mục đích.** Đối chiếu sổ kiến trúc với phân hệ nguồn.

**Phương thức, đường dẫn.** `POST /arch/reconciliations`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-048.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Reconciliation`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-16-056 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ; đang có lần đối chiếu chạy trả ERR-16-056.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/reconciliations
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"componentTypes": ["HTTT"]}
```

```http
HTTP/1.1 202 Accepted

{"reconId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "RUNNING",
 "items": [{"itemId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "kind": "MISSING",
   "componentCode": "httt-qlvb", "resolution": "OPEN",
   "sourceRef": "ph02:api-tra-cuu-ho-tich"}], "itemCount": 1,
 "requestedAt": "2026-11-26T08:00:00+07:00", "finishedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-112 · Kết quả đối chiếu sổ kiến trúc

::: dac-ta
**Mục đích.** Kết quả đối chiếu sổ kiến trúc.

**Phương thức, đường dẫn.** `GET /arch/reconciliations/{reconId}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-048.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Reconciliation`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/arch/reconciliations/{reconId}
```

```http
HTTP/1.1 200 OK

{"reconId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
 "items": [{"itemId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "kind": "MISSING",
   "componentCode": "httt-qlvb", "resolution": "OPEN",
   "sourceRef": "ph02:api-tra-cuu-ho-tich"}], "itemCount": 1,
 "requestedAt": "2026-11-26T08:00:00+07:00", "finishedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-113 · Xử lý một mục lệch

::: dac-ta
**Mục đích.** Xử lý một mục lệch.

**Phương thức, đường dẫn.** `POST /arch/reconciliations/{reconId}/items/{itemId}:resolve`.

**Quyền.** `PERM-16-arch`.

**FR hiện thực.** FR-16-048.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReconResolve`; trường bắt buộc: `resolution`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Reconciliation`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/arch/reconciliations/{reconId}/items/{itemId}:resolve

{"resolution": "REGISTERED", "reason": "Nhận thành phần vào sổ theo dữ liệu của PH-02."}
```

```http
HTTP/1.1 200 OK

{"reconId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "state": "SUCCEEDED",
 "items": [{"itemId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "kind": "MISSING",
   "componentCode": "httt-qlvb", "resolution": "OPEN",
   "sourceRef": "ph02:api-tra-cuu-ho-tich"}], "itemCount": 1,
 "requestedAt": "2026-11-26T08:00:00+07:00", "finishedAt": "2026-11-26T08:00:00+07:00"}
```

### Gửi quốc gia

#### API-16-114 · Danh sách mẫu gói quốc gia

::: dac-ta
**Mục đích.** Danh sách mẫu gói quốc gia.

**Phương thức, đường dẫn.** `GET /national/templates`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-050.

**Tham số.** `submissionType` (query, SubmissionType, tùy chọn); `state` (query, NationalTemplateState, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalTemplatePage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/templates
```

```http
HTTP/1.1 200 OK

{"items": [{"templateCode": "goi-bao-cao-chi-tieu", "submissionType": "KPI_REPORT", "version": 1,
   "state": "ACTIVE", "schema": {"type": "object"}}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-16-115 · Tạo phiên bản mẫu gói quốc gia

::: dac-ta
**Mục đích.** Tạo phiên bản mẫu gói quốc gia.

**Phương thức, đường dẫn.** `POST /national/templates`.

**Quyền.** `PERM-16-national hoặc PERM-16-admin`.

**FR hiện thực.** FR-16-050.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NationalTemplateCreate`; trường bắt buộc: `templateCode`, `submissionType`, `schema`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `NationalTemplate`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/templates
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"templateCode": "goi-bao-cao-chi-tieu", "submissionType": "KPI_REPORT",
 "schema": {"type": "object"}, "mapping": {"httt-ket-noi-ty-le": "chiSo01"},
 "channelRef": "ndop-bao-cao", "version": 2, "effectiveFrom": "2026-12-01"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/national/ma-moi

{"templateCode": "goi-bao-cao-chi-tieu", "submissionType": "KPI_REPORT", "version": 1,
 "state": "ACTIVE", "schema": {"type": "object"},
 "mapping": {"httt-ket-noi-ty-le": "chiSo01"}, "channelRef": "ndop-bao-cao"}
```

#### API-16-116 · Chi tiết mẫu gói quốc gia

::: dac-ta
**Mục đích.** Chi tiết mẫu gói quốc gia.

**Phương thức, đường dẫn.** `GET /national/templates/{templateCode}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-050.

**Tham số.** `version` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalTemplate`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/templates/{templateCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"templateCode": "goi-bao-cao-chi-tieu", "submissionType": "KPI_REPORT", "version": 1,
 "state": "ACTIVE", "schema": {"type": "object"},
 "mapping": {"httt-ket-noi-ty-le": "chiSo01"}, "channelRef": "ndop-bao-cao"}
```

#### API-16-117 · Kích hoạt phiên bản mẫu gói

::: dac-ta
**Mục đích.** Kích hoạt phiên bản mẫu gói.

**Phương thức, đường dẫn.** `POST /national/templates/{templateCode}/versions/{version}:activate`.

**Quyền.** `PERM-16-national hoặc PERM-16-admin`.

**FR hiện thực.** FR-16-050.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalTemplate`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mẫu phải đạt lược đồ và kiểm thử (ERR-16-047); phiên bản `ACTIVE` cũ chuyển `SUPERSEDED`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/templates/{templateCode}/versions/{version}:activate
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"templateCode": "goi-bao-cao-chi-tieu", "submissionType": "KPI_REPORT", "version": 1,
 "state": "ACTIVE", "schema": {"type": "object"},
 "mapping": {"httt-ket-noi-ty-le": "chiSo01"}, "channelRef": "ndop-bao-cao"}
```

#### API-16-118 · Lập gói quốc gia

::: dac-ta
**Mục đích.** Lập gói quốc gia.

**Phương thức, đường dẫn.** `POST /national/submissions`.

**Quyền.** `PERM-16-national`.

**FR hiện thực.** FR-16-051, FR-16-052.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmissionCreate`; trường bắt buộc: `submissionType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Submission`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-046, ERR-16-048, ERR-16-049, ERR-16-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gói chưa đạt lược đồ mẫu trả ERR-16-048; nội dung trùng lần nộp trước trả ERR-16-049; chỉ gói của báo cáo `PUBLISHED` (ERR-16-052). Trả bản xem trước.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/submissions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"submissionType": "KPI_REPORT", "reportCode": "bc-thang-2026-10", "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu", "mode": "FULL", "componentTypes": ["HTTT"]}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/kpi/v1/national/ma-moi

{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "submissionType": "KPI_REPORT",
 "state": "PENDING", "reportCode": "bc-thang-2026-10", "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu", "mode": "FULL"}
```

#### API-16-119 · Danh sách gói quốc gia

::: dac-ta
**Mục đích.** Danh sách gói quốc gia.

**Phương thức, đường dẫn.** `GET /national/submissions`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-053.

**Tham số.** `submissionType` (query, SubmissionType, tùy chọn); `state` (query, SubmissionState, tùy chọn); `reportCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubmissionPage`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/submissions
```

```http
HTTP/1.1 200 OK

{"items": [{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "submissionType": "KPI_REPORT",
   "state": "PENDING", "reportCode": "bc-thang-2026-10", "version": 1}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-16-120 · Chi tiết gói quốc gia

::: dac-ta
**Mục đích.** Chi tiết gói quốc gia.

**Phương thức, đường dẫn.** `GET /national/submissions/{submissionId}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-051, FR-16-052, FR-16-053.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Submission`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/submissions/{submissionId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "submissionType": "KPI_REPORT",
 "state": "PENDING", "reportCode": "bc-thang-2026-10", "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu", "mode": "FULL"}
```

#### API-16-121 · Gửi gói quốc gia

::: dac-ta
**Mục đích.** Gửi gói quốc gia.

**Phương thức, đường dẫn.** `POST /national/submissions/{submissionId}:send`.

**Quyền.** `PERM-16-national`.

**FR hiện thực.** FR-16-051, FR-16-052.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Submission`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`; mã lỗi của thao tác: ERR-16-046 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi qua PH-14; phát EVT-16-12. Lỗi kênh được thử lại tối đa `16.national.retry-max` lần.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/submissions/{submissionId}:send
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "submissionType": "KPI_REPORT",
 "state": "SENDING", "reportCode": "bc-thang-2026-10", "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu", "mode": "FULL"}
```

#### API-16-122 · Gửi lại gói quốc gia

::: dac-ta
**Mục đích.** Gửi lại gói quốc gia.

**Phương thức, đường dẫn.** `POST /national/submissions/{submissionId}:retry`.

**Quyền.** `PERM-16-national`.

**FR hiện thực.** FR-16-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Submission`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-16-050, ERR-16-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ gói `FAILED` hoặc `REJECTED` còn lượt gửi lại (ERR-16-050).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/submissions/{submissionId}:retry

{"reason": "Nguồn đã ngừng cung cấp theo công văn số 123 ngày 10/11/2026."}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "submissionType": "KPI_REPORT",
 "state": "SENDING", "reportCode": "bc-thang-2026-10", "version": 1,
 "templateCode": "goi-bao-cao-chi-tieu", "mode": "FULL"}
```

#### API-16-123 · Nhật ký nộp của gói

::: dac-ta
**Mục đích.** Nhật ký nộp của gói.

**Phương thức, đường dẫn.** `GET /national/submissions/{submissionId}/logs`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-053.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubmissionLogPage`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/submissions/{submissionId}/logs
```

```http
HTTP/1.1 200 OK

{"items": [{"at": "2026-11-26T08:00:00+07:00", "event": "SENDING", "channelMessageId": "msg-0001",
   "status": "SENDING", "code": "ERR-16-118"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-16-124 · Nhận biên nhận từ PH-14

::: dac-ta
**Mục đích.** Nhận biên nhận từ PH-14.

**Phương thức, đường dẫn.** `POST /internal/national/receipts`.

**Quyền.** scope `kpi.national-receipt`.

**FR hiện thực.** FR-16-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReceiptIn`; trường bắt buộc: `submissionId`, `channelMessageId`, `status`.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Chỉ qua `/internal` trong mạng nội bộ, scope `kpi.national-receipt` của PH-14. Mã băm không khớp ghi ERR-16-124. Biên nhận trùng `channelMessageId` của cùng gói là lũy đẳng: trả `204`, không ghi thêm dòng nhật ký.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/internal/national/receipts

{"submissionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "channelMessageId": "msg-0001",
 "status": "ACKNOWLEDGED", "receiptNo": "BN-2026-001234",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
 "rejectCode": "E102", "rejectMessage": "Thiếu trường chiSo03."}
```

```http
HTTP/1.1 204 No Content
```

#### API-16-125 · Đối soát sổ kiến trúc, gói đã nộp, chỉ tiêu

::: dac-ta
**Mục đích.** Đối soát sổ kiến trúc, gói đã nộp, chỉ tiêu.

**Phương thức, đường dẫn.** `POST /national/reconciliations`.

**Quyền.** `PERM-16-national`.

**FR hiện thực.** FR-16-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NationalReconRequest`; trường bắt buộc: `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `NationalRecon`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-16-056 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ; đang có lần đối soát chạy trả ERR-16-056.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/kpi/v1/national/reconciliations
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"scope": "ALL", "asOf": "2026-11-26T08:00:00+07:00"}
```

```http
HTTP/1.1 202 Accepted

{"reconId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "scope": "ALL", "state": "QUEUED",
 "items": [{"kind": "SUBMISSION_MISMATCH", "ref": "bc-thang-2026-10", "expected": "82,5",
   "actual": "82,0", "suggestion": "Gửi lại gói."}],
 "requestedAt": "2026-11-26T08:00:00+07:00"}
```

#### API-16-126 · Kết quả đối soát quốc gia

::: dac-ta
**Mục đích.** Kết quả đối soát quốc gia.

**Phương thức, đường dẫn.** `GET /national/reconciliations/{reconId}`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-054.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalRecon`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/national/reconciliations/{reconId}
```

```http
HTTP/1.1 200 OK

{"reconId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "scope": "ALL", "state": "SUCCEEDED",
 "items": [{"kind": "SUBMISSION_MISMATCH", "ref": "bc-thang-2026-10", "expected": "82,5",
   "actual": "82,0", "suggestion": "Gửi lại gói."}],
 "requestedAt": "2026-11-26T08:00:00+07:00"}
```

### Quản trị

#### API-16-127 · Đọc tham số 16.*

::: dac-ta
**Mục đích.** Đọc tham số 16.*.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-16-read`.

**FR hiện thực.** FR-16-055.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; tiêu đề `ETag`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/settings
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"settings": [{"key": "16.source.stale-hours", "value": 26, "default": 26, "ceiling": 168,
   "scope": "TENANT"}]}
```

#### API-16-128 · Sửa tham số 16.*

::: dac-ta
**Mục đích.** Sửa tham số 16.*.

**Phương thức, đường dẫn.** `PATCH /settings`.

**Quyền.** `PERM-16-config`.

**FR hiện thực.** FR-16-055.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SettingsPatch`; trường bắt buộc: `settings`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-16-051 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị ngoài miền hoặc vượt trần của PA trả ERR-16-051.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/kpi/v1/settings

{"settings": [{"key": "16.source.stale-hours", "value": 30}]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"settings": [{"key": "16.source.stale-hours", "value": 26, "default": 26, "ceiling": 168,
   "scope": "TENANT"}]}
```

#### API-16-129 · Nhật ký kiểm toán PH-16

::: dac-ta
**Mục đích.** Nhật ký kiểm toán PH-16.

**Phương thức, đường dẫn.** `GET /audit-events`.

**Quyền.** `PERM-16-audit-read`.

**FR hiện thực.** FR-16-056.

**Tham số.** `actor` (query, string, tùy chọn); `action` (query, string, tùy chọn); `objectType` (query, string, tùy chọn); `objectRef` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditPage`.

**Lỗi.** HTTP `400`; mã lỗi của thao tác: ERR-16-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc từ kho kiểm toán PH-13; khoảng thời gian tối đa 12 tháng mỗi lần (ERR-16-057).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/audit-events
```

```http
HTTP/1.1 200 OK

{"items": [{"at": "2026-11-26T08:00:00+07:00", "actor": "nguyen.thi.lan", "action": "REPORT_PUBLISH",
   "objectType": "report", "objectRef": "bc-thang-2026-10"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-16-130 · Tình trạng lưu giữ, dọn dữ liệu

::: dac-ta
**Mục đích.** Tình trạng lưu giữ, dọn dữ liệu.

**Phương thức, đường dẫn.** `GET /retention/status`.

**Quyền.** `PERM-16-config hoặc PERM-16-audit-read`.

**FR hiện thực.** FR-16-057.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RetentionStatus`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/kpi/v1/retention/status
```

```http
HTTP/1.1 200 OK

{"partitions": [{"name": "kpi_observation_2026_10", "rowCount": 184000, "rangeFrom": "2026-10-01",
   "rangeTo": "2026-11-01"}], "lastPurgeAt": "2026-11-26T08:00:00+07:00",
 "nextPurgeAt": "2026-11-26T08:00:00+07:00", "bytesFreed": 0}
```
<!-- gen:dac-ta-api:end -->

## Phụ lục A. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu khác; các điểm dưới cần chủ tài liệu hấp thụ ở đợt đồng bộ cuối. Dòng ghi "Đã hấp thụ" đã được FRS 0.2 hoặc CSDL 0.2 nhận ở đợt đồng bộ 26/11/2026.

| Tài liệu | Đề nghị |
|---|---|
| FRS D02-03-PH16 Phụ lục A | Thêm giá trị liệt kê cục bộ của API: `ReviewItemType` (`INDICATOR_VERSION`, `MANUAL_VALUE`, `REPORT`, API-16-078); `DashboardView` (`OFFICIAL`, `LATEST`, API-16-090); `ArchIngestStatus` (`CREATED`, `UPDATED`, `UNCHANGED`, `REJECTED`, API-16-101); `NationalReconScope` (`ARCH`, `KPI`, `ALL`, API-16-125); `RecipientType` (`USER`, `GROUP`, `EMAIL`, FR-16-034); `ReceiptStatus` (`ACKNOWLEDGED`, `REJECTED`, `FAILED`, API-16-124); giá trị `change` của EVT-16-10 (`CREATED`, `LIFECYCLE_CHANGED`, `VERSION_ADDED`, `OPS_STATUS_CHANGED`); giá trị `kind` của EVT-16-11 (`CONFIRMED`, `WAIVER_GRANTED`, `WAIVER_EXPIRED`). Đã hấp thụ (FRS 0.2) |
| FRS D02-03-PH16 mục 3.3, 9.4 | Scope máy `kpi.national-receipt` cho API-16-124 (Q16-57); API-16-008 và 009 yêu cầu `If-Match` để `dryRunHash` khớp nội dung vừa kiểm; API-16-050 chỉ nhận `trigger = MANUAL` (`SCHEDULE`, `LATE_DATA` do hệ thống, `RECOMPUTE` qua API-16-055); API-16-036 trả tệp XLSX, API-16-081 trả tệp trực tiếp; API-16-030 trả `207` khi có phần tử lỗi. Đã hấp thụ (FRS 0.2) |
| FRS D02-03-PH16 mục 9.1 | Cấp ERR-16-058 cho `Idempotency-Key` dùng lại với thân khác (Q16-56). Đã hấp thụ (FRS 0.2), tập này dùng ERR-16-058 |
| D02-08 §3.2, §4 | Mười hai quyền `PERM-16-approve`, `source`, `manual`, `run`, `report`, `export`, `arch`, `arch-assess`, `national`, `compare`, `config`, `audit-read` và mở rộng vai trò theo FRS 3.2; thêm scope máy `kpi.read`, `kpi.ingest`, `arch.register`, `kpi.national-receipt` |
| CSDL D03-03-PH16 | Tên logic API khác cột: `groupCode` là `group_code`; `version` là `version_no`; `formula` là `formula_cel`; `target.target` là `target_value`; `thresholds` (`greenFrom`, `amberFrom`, `range`) ánh xạ bảng `kpi_indicator_threshold` (`level`, `lower_bound`, `upper_bound`); `trigger` là `run_trigger`; `completeness` của lần tổng hợp là tỷ lệ 0…1; `sections` của mẫu là JSON `sections`; `reportTypes`, `periodTypes` của phân phối là `report_type`, `period_type` (đề nghị bảng nhận mảng); `until` của miễn trừ là `valid_to`; `evidence.sha256` là `content_hash`; `settings[].key` là `param_code`; `comment` là `decision_comment`; nhật ký kiểm toán API-16-129 đọc từ kho kiểm toán PH-13, không có bảng riêng. Đã hấp thụ (CSDL 0.2 mục 8.5) |
| D03-04-PH14, D02-03-PH14 | Loại nền tảng quốc gia mới cho gói báo cáo chỉ tiêu và sổ kiến trúc; PH-14 nhận gói từ outbox PH-16 kèm `contentHash`, trả biên nhận vào API-16-124 (`ReceiptIn`) hoặc sự kiện; giữ thông tin xác thực quốc gia ở OpenBao |
| D03-04-PH01, PH02, PH04, PH05, PH07, PH19, PH13, PH20 | Cung cấp API chỉ số theo kỳ (scope đọc chỉ số cấp cho PH-16) và xác nhận trường các sự kiện EVT-01-03, 02-05, 02-06, 02-13, 04-01, 04-07, 04-09, 05-08, 07-05, 07-09, 14-01, 14-11, 14-12, 19-07 mà PH-16 đọc (Q16-59); PH-19 lọc `isTest`; PH-13 và PH-20 cấp mã sự kiện, API chỉ số |
| D03-04-PH08 | Xác nhận `snapshotId` và `kpiSchemaVersion` ở EVT-08-14 (payload `KpiPublishedData` hiện không liệt kê `snapshotId`); API-08-122 giữ làm đường đọc bù với scope `dq.read` |
| D03-04-PH10 | Đăng ký 14 topic `{tenant}.kpi.*` (thêm EVT-16-14 `{tenant}.kpi.period.state-changed.v1`) theo FR-10-067; khóa phân vùng ở bảng chương 4 |
| D03-04-PH15 | Tiêu thụ EVT-16-10 hiển thị trạng thái kiến trúc; sổ kiến trúc PH-16 là nguồn duy nhất, bỏ Backstage (ADR 095 đề xuất) |
| D03-04 khung lỗi chung | Cấp ERR-00-401, ERR-00-403, ERR-00-428 mà PH-16 dẫn |

: Đề nghị đồng bộ với tài liệu khác

Trường chỉ có ở API (kết quả tính, gộp hoặc tham chiếu, không có cột DDL hay trường FRS tương ứng):

<!-- gen:api-only:start -->
Trường: `accepted`, `activeDefinition`, `adapterCode`, `amount`, `apiCode`, `baseVersion`, `breaking`, `byGroup`, `byMeasurement`, `byState`, `catalogCode`, `changedFields`, `channelCode`, `check`, `conflictFields`, `consecutiveBreaches`, `correctionOf`, `deploymentId`, `derivedVersion`, `domainScores`, `duplicate`, `durationMs`, `environment`, `evidenceId`, `explanation`, `failed`, `failed24h`, `flowCode`, `flowId`, `formNo`, `fromCache`, `fromStatus`, `hasBreaking`, `healthStatus`, `inputs`, `issuer`, `itemType`, `lastAcknowledgedAt`, `major`, `median`, `newerRunId`, `noData`, `official`, `ok`, `ownedByMe`, `p25`, `p75`, `paidAt`, `partnerCode`, `passed`, `pending`, `periodState`, `platformCode`, `previewUrl`, `previousLevel`, `projectCode`, `publicationCode`, `publishedVersion`, `publisherCode`, `referencedMetrics`, `requestedAt`, `retiredAt`, `running`, `sampleMetrics`, `securityLevel`, `serviceCode`, `stage`, `stages`, `staleSources`, `submitChecks`, `sunsetAt`, `supersededVersion`, `systemCode`, `targetDisplay`, `templateVersion`, `tenantScore`, `toState`, `toStatus`, `topicKind`, `topicName`, `transactionCode`, `transactionId`, `valid`, `variable`, `visibility`, `warnings`, `workspaceCode`, `yoy`.

Giá trị liệt kê: không có, mọi giá trị đều ở FRS Phụ lục A.
<!-- gen:api-only:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Nhóm PH-16 | Bản đầu: 130 operation theo FRS 9.4 (API-16-001…130), 13 sự kiện phát, 18 sự kiện tiêu thụ, bảng mã lỗi và thông báo theo FRS 9.1 và 9.2, 5 câu hỏi mở Q16-55…59, phụ lục đề nghị đồng bộ |
| 0.2 | 2026-11-26 | Nhóm PH-16 | Đồng bộ với FRS 0.2, CSDL 0.2: EVT-16-14 `PeriodStateChangedData`; ERR-16-058 cho `Idempotency-Key`, ERR-16-059 ở API-16-040, 041, ERR-16-060 ở API-16-029 và lệnh đọc có `from`, `to`, ERR-16-061 ở API-16-071; API-16-073 nhận báo cáo `APPROVED`; `documentNumber`, `recipientsNote` của báo cáo; `dependencyType` của phụ thuộc; enum lấy từ Phụ lục A FRS thay cho giá trị cục bộ (kênh quan sát, truy nguồn, miễn trừ, đối chiếu sổ, nhật ký nộp); đóng Q16-56, Q16-57 |
| 0.3 | 2026-11-27 | Nhóm PH-16 | Đồng bộ chéo cuối: ADR 095, mẫu type RFC 9457 theo QĐ-6, trường mới của Run, Dashboard, Comparison, Report, sinh lại từ OpenAPI |
