---
ma_tai_lieu: D03-04-PH11
ten: Đặc tả API và sự kiện phân hệ PH-11 Quy trình liên thông
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư tích hợp, kỹ sư dh-platform, kiểm thử viên, hội đồng thẩm định
phan_he: PH-11
mo_ta: Hợp đồng REST và sự kiện của PH-11 Quy trình liên thông (BPM) gồm 137 operation và 21 sự kiện EVT-11, kèm quy ước chung, quyền, scope máy, sơ đồ trình tự bốn luồng chính, mã lỗi RFC 9457, kiểm tra hợp đồng, câu hỏi mở và đề nghị đồng bộ FRS.
tai_lieu_lien_quan: D02-03-PH11 FRS; D03-02-PH11 SDD; D03-03-PH11 CSDL; D03-06-PH11 Giao diện; D05-02-PH11 Test case
---

# D03-04-PH11 · Đặc tả API và sự kiện Quy trình liên thông

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của phân hệ PH-11 Quy trình liên thông (BPM): nơi điều phối quy trình nghiệp vụ nhiều bước giữa nhiều cơ quan, chạy trên Flowable nhúng trong `dh-platform`. Ví dụ xuyên suốt là quy trình `LT_KHAI_SINH` (đăng ký khai sinh, đăng ký thường trú, cấp thẻ BHYT cho trẻ dưới 6 tuổi) mà Cổng DVC tỉnh khởi tạo bằng một lời gọi API. PH-11 công bố **137 operation REST** gốc `/api/bpm/v1` (mã `API-11-001…137`, giữ đúng mã, phương thức, đường dẫn của FRS §9.4) và **21 sự kiện** `EVT-11-01…21` trên Kafka, trong đó có lệnh gửi PH-04 thực thi service task và kết quả PH-04 trả về.

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph11/openapi-bpm.yaml`](ph11/openapi-bpm.yaml): OpenAPI 3.1, 241 lược đồ, 16 nhóm; mỗi operation có ví dụ yêu cầu (khi có thân) và ví dụ phản hồi; 226 ví dụ khớp lược đồ theo [`check_contracts.py`](ph11/tools/check_contracts.py); `@redocly/cli lint` và `openapi-spec-validator` không báo lỗi hay cảnh báo.
- [`ph11/asyncapi-bpm.yaml`](ph11/asyncapi-bpm.yaml): AsyncAPI 3.0, 21 kênh, 21 operation, 21 thông điệp CloudEvents, 21 ví dụ khớp payload.

Năm nguyên tắc hợp đồng:

1. **Enum và tên trường lấy theo Phụ lục A của FRS.** Enum trong OpenAPI được đọc thẳng từ FRS khi sinh; [`doi_chieu_frs.py`](ph11/tools/doi_chieu_frs.py) đối chiếu thêm đường dẫn, mã lỗi, sự kiện, quyền. Trường và enum chỉ có ở API được liệt kê ở Phụ lục A của tập này để FRS hấp thụ.
2. **Khởi tạo phiên idempotent.** `POST /instances` bắt buộc `Idempotency-Key`; gửi lại cùng `businessKey` và cùng nội dung không tạo phiên thứ hai (`200` kèm phiên cũ), khác nội dung trả ERR-11-018.
3. **Service task chạy bất đồng bộ qua Kafka** (ADR 112): PH-11 không gọi HTTT trực tiếp, chỉ phát lệnh `service.requested` qua outbox và chờ kết quả `service.completed`, `service.failed` của PH-04, tương quan theo `commandId`.
4. **Kênh DVC chỉ thấy tiến độ rút gọn.** `GET /progress/{businessKey}` (scope `bpm.progress.read`) trả bước có tên công khai và trạng thái công khai, không biến, không tên cán bộ, không lỗi kỹ thuật; hồ sơ không thuộc client trả như không tồn tại.
5. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động trên tài nguyên có `If-Match`;** thao tác rủi ro (phát hành mô hình, sửa biến phiên, di trú, bỏ qua bước bù trừ) qua duyệt bốn mắt.

Căn cứ: FRS D02-03-PH11 §3.2, §8.2, §9 và Phụ lục A; CSDL D03-03-PH11 (schema `ph11_bpm`). Mọi tên miền, dữ liệu trong ví dụ là giả lập, tenant T68.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả mặt giao tiếp của PH-11 ở mức đủ để kỹ sư `dh-platform` hiện thực, kỹ sư của Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19 tích hợp, kỹ sư PH-04 hiện thực bên nhận lệnh service task, và kiểm thử viên viết ca kiểm thử hợp đồng. Phạm vi gồm REST `/api/bpm/v1` và sự kiện `{tenant}.bpm.*`; không gồm API của engine Flowable (không mở ra ngoài) và màn hình (D03-06-PH11).

### 0.2. Thuật ngữ và tài liệu tham chiếu

Bảng giải thích thuật ngữ và các tài liệu tập này dựa vào.

| Thuật ngữ, tài liệu | Giải thích |
|---|---|
| Phiên (`instanceId`) | Một lần chạy mô hình quy trình cho một hồ sơ; `businessKey` là mã hồ sơ, duy nhất trong (tenant, `processKey`) khi chưa kết thúc |
| Việc (`taskId`) | Bước do cán bộ xử lý (user task); hiện trong hộp "Việc của tôi" (FR-00-070) |
| Service task, ý định (`intentCode`) | Bước tự động; ý định nghiệp vụ ánh xạ sang luồng PH-04, PH-11 chỉ gửi lệnh, không gọi HTTT |
| Saga | Chuỗi bước bù trừ khi một bước lỗi hoặc phiên bị hủy; nhật ký riêng, không dùng giao dịch hai pha |
| `commandId` | Mã lệnh service task, khóa chống trùng và tương quan kết quả |
| Bốn mắt | Người duyệt khác người đề nghị, kiểm theo từng yêu cầu (FR-00-071, ADR-046) |
| D02-03-PH11 FRS | Nguồn chuẩn cho FR, ERR, EVT, PERM, enum (Phụ lục A) |
| D03-03-PH11 CSDL | Bảng, ràng buộc, mã hóa; tên trường JSON camelCase tương ứng cột snake_case |
| `docs/07-srs/SRS-PH-11-bpm.md` | SRS cũ trong repo, API cũ ở mục 8 |

: Thuật ngữ và tài liệu tham chiếu của tập API PH-11

### 0.3. Người đọc

Kỹ sư tích hợp, kỹ sư `dh-platform`, kỹ sư PH-04, kiểm thử viên và hội đồng thẩm định.

### 0.4. Cấu trúc tài liệu

Chương 1, 2 quy ước và quyền; 3 danh mục endpoint và sơ đồ trình tự bốn luồng chính; 4, 5 sự kiện và hợp đồng ngoài phân hệ; 6 mã lỗi; 7 kiểm tra hợp đồng; 8, 9 ánh xạ từ hệ cũ và truy vết FR; 10 câu hỏi mở; 11 đặc tả từng endpoint; Phụ lục A đề nghị đồng bộ FRS.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi operation, trừ khi bảng endpoint ở chương 3 ghi khác.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/bpm/v1`: BFF console của tenant cho người dùng; trong cụm `dh-platform.dh-platform.svc`; Cổng DVC, HTTT, PH-01, PH-07, PH-19 qua cổng API (PH-03) bằng token máy |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song tối thiểu 6 tháng; oasdiff ở CI chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ token (claim `tenant`), không bao giờ từ thân hay đường dẫn; đối tượng của tenant khác trả `404` ERR-11-001, không lộ sự tồn tại |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập (`:submit`, `:approve`, `:complete`, `:bulk-reassign`) |
| Khóa lạc quan | `GET` trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động trên tài nguyên có phiên bản bắt buộc `If-Match`; lệch trả `409` ERR-11-004, thiếu trả `428` ERR-00-428. Miễn: hành động chạy lại được hoặc không có tài nguyên cha có phiên bản (cột If-Match ở mục 3) |
| Chống trùng | `POST` tạo, khởi tạo, hoàn thành việc, xuất, giao lại hàng loạt bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ; cùng khóa cùng thân trả lại đúng phản hồi lần đầu, khác thân trả `409` ERR-11-051 |
| Phân trang | `page` (từ 0), `size` (1…100, mặc định 20); phản hồi `items`, `page`, `size`, `totalElements` |
| Lỗi | RFC 9457 `application/problem+json`, `type = https://datahub.example.vn/errors/{code}`, `code`, `traceId`, `errors[]` theo trường; thông báo người dùng theo FRS 9.2 (mục 6) |
| Tác vụ dài | Di trú, giao lại hàng loạt, xuất báo cáo, dựng gói bằng chứng, bù trừ trả `202` kèm `jobId`, `exportId`, `sagaId`, `planId`; theo dõi bằng `GET` hoặc sự kiện |
| Hạn mức | Khởi tạo phiên vượt `11.instance.startRatePerClient` (mặc định 50 lượt/s mỗi client) trả `429` ERR-11-041 kèm `Retry-After` |
| Che dữ liệu | Biến phân loại `SENSITIVE` mã hóa ở CSDL và che ở mọi phản hồi; xem đầy đủ cần `PERM-09-unmask`, `unmask=true` và `X-Unmask-Reason` (≥ 20 ký tự), có ghi nhật ký truy cập. Sự kiện không mang giá trị biến |
| Giờ, hạn | Giờ ISO 8601 có múi `+07:00` (`Asia/Ho_Chi_Minh`); hạn xử lý `Due` = `{value, unit}` với `unit` theo ngày làm việc hoặc ngày lịch (ADR 114) |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên BFF, `dh-platform`, Kafka; `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` |

: Quy ước chung của API PH-11

### 1.1. Mặt giao tiếp và đường mạng

PH-11 có ba mặt giao tiếp, khác nhau ở bên gọi và cách xác thực.

| Mặt | Bên gọi | Xác thực | Operation |
|---|---|---|---|
| Người dùng | Console qua BFF (trình thiết kế bpmn-js, hộp việc, giám sát) | OIDC và PKCE ở BFF, token không ra trình duyệt; quyền `PERM-11-*` | Toàn bộ trừ API chỉ có scope |
| Máy, công khai trong TTDL | Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19, PH-13 | `client_credentials` và mTLS hoặc `private_key_jwt`; scope `bpm.*` (mục 2.2); client phải nằm trong `allowedStarters` của mô hình | 049, 051, 052, 056…058, 069, 072, 089, 104 |
| Kafka | PH-04, PH-10, PH-03, kênh thông báo | mTLS, ACL theo tiền tố tenant; scope `bpm.service.worker` cho PH-04 | Chương 4 |

: Mặt giao tiếp và đường mạng

## 2. Xác thực và phân quyền

### 2.1. Quyền người dùng

Quyền theo FRS §3.2 (PH-11 không tạo vai trò mới; tám quyền mới đề nghị đồng bộ vào D02-08, xem FRS Phụ lục B). Bảng sinh từ OpenAPI; cột "Quyền" ở mục 3 và `x-datahub-permission` là nguồn chi tiết.

<!-- gen:perms:start -->
| Quyền | Ý nghĩa | Vai trò (FRS 3.2) | Operation (API-11-) |
|---|---|---|---|
| `PERM-11-read` | Xem mô hình, phiên, việc, bảng điều khiển trong phạm vi | PA ○, PO ○, TA, TO, IE, IA, AU, VW, CB ○ | 001, 002, 007, 009, 015, 019, 024, 028, 029, 031, 034, 038, 039, 041, 044, 046, 050…055, 070, 073, 083, 086, 090, 093…097, 102, 107…110, 114, 116, 118, 126, 128, 129 |
| `PERM-11-model` | Tạo, thiết kế, cấu hình, chạy thử, gửi duyệt mô hình và tài nguyên | PA ○, TA, IE | 003…005, 008, 010…014, 016, 017, 025…027, 030, 032, 033, 035…037, 040, 042, 043, 045, 047, 048, 136 |
| `PERM-11-publish` | Duyệt, từ chối phát hành; ngừng dùng, thu hồi phiên bản | TA, IA | 006, 018…023, 131 |
| `PERM-11-task` | Xử lý việc được giao | TA, TO, IE, IA, CB | 072…081, 083…088, 124, 125 |
| `PERM-11-instance` | Khởi tạo thủ công, tạm dừng, tiếp tục, hủy phiên | TA, TO | 049, 056…058, 127 |
| `PERM-11-instance-admin` | Đề nghị, duyệt sửa biến, chuyển bước, di trú phiên | TA | 059…068 |
| `PERM-11-task-admin` | Phân công lại, giao lại hàng loạt | TA, TO | 078, 080…082 |
| `PERM-11-compensate` | Kích hoạt bù trừ, xử lý bước Saga, sự cố engine, gửi lại lệnh | PO ○, TA, TO | 071, 098…101, 103, 111…113, 132, 133 |
| `PERM-11-config` | Lịch làm việc, tham số, lưu giữ, quy tắc cảnh báo | PA, TA | 091, 092, 115, 117, 119, 120, 134, 135 |
| `PERM-11-audit-read` | Lịch sử bước đầy đủ, nhật ký kiểm toán, xuất bằng chứng | TA, AU | 105, 106, 121…123, 130, 137 |

: Quyền người dùng của PH-11
<!-- gen:perms:end -->

Quy tắc vượt quyền chức năng, máy chủ kiểm:

- **Bốn mắt** (BR-11-016, ADR-046): người duyệt khác người đề nghị, kể cả người có cả `model` và `publish` (ERR-11-005); áp cho phát hành mô hình (020), ngừng dùng, thu hồi (022, 023), mẫu `COMMON` (043), sửa biến, chuyển bước (059, 061), di trú (066), bỏ qua bước bù trừ (101). Kiểm theo từng yêu cầu, không theo vai trò.
- **Phạm vi dữ liệu**: Cán bộ xử lý (CB) chỉ xem phiên có việc của mình hoặc của đơn vị mình (ERR-11-034); PO chỉ xem và thử lại sự cố engine khi có lý do, không xem biến.
- **Xem đầy đủ `SENSITIVE`**: cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason`; không có thì giá trị luôn che, kể cả với TA (BR-11-014).
- **Mẫu `COMMON`**: chỉ PA sửa (ERR-11-036).

### 2.2. Scope máy

Bên gọi là máy dùng scope `bpm.*` cấp ở Keycloak khi đăng ký client; mỗi client còn phải nằm trong danh sách `allowedStarters` của mô hình mới khởi tạo được (ERR-11-020).

<!-- gen:scopes:start -->
| Scope | Cấp cho | Operation (API-11-) | Ghi chú |
|---|---|---|---|
| `bpm.instance.start` | Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19 | 049, 056…058, 069, 089 | Hoặc quyền người dùng ở mục 2.1 |
| `bpm.instance.read` | Như trên, PH-13 | 051, 052 | Hoặc quyền người dùng ở mục 2.1 |
| `bpm.task.read` | HTTT một cửa có hộp việc riêng | 072 | Hoặc quyền người dùng ở mục 2.1 |
| `bpm.progress.read` | Cổng DVC qua PH-03 | 104 | Chỉ scope, không có quyền người dùng |
| `bpm.service.worker` | PH-04 | - | Chỉ qua Kafka (EVT-11-17, 18, 19), không có REST |

: Scope máy của PH-11
<!-- gen:scopes:end -->

### 2.3. Lỗi xác thực và che dữ liệu

`401`, `403` do thiếu quyền chức năng và `428` thiếu `If-Match` dùng mã nền tảng `ERR-00-401`, `ERR-00-403`, `ERR-00-428` trong `code` của thân lỗi, không cấp mã ERR-11 riêng. `403` do phạm vi dữ liệu hoặc bốn mắt giữ mã ERR-11 (005, 020, 022, 034, 036). Mọi operation trả `401` và `403`. API tiến độ (104) không bao giờ phân biệt "không tồn tại" với "không được phép": cả hai trả `404` ERR-11-035 để không lộ sự tồn tại của hồ sơ.

## 3. Danh mục endpoint

Mỗi operation một mã `API-11-nnn`, giữ đúng mã, phương thức, đường dẫn của FRS §9.4; không có dòng gộp nên không phải tách mã. Bảng dưới sinh từ OpenAPI theo nhóm; cột "Idem." là bắt buộc `Idempotency-Key`, "If-Match" là bắt buộc khóa lạc quan. Cột "Quyền, scope" viết tắt bỏ tiền tố `PERM-11-`; "hoặc" nghĩa là một trong hai là đủ, "và" nghĩa là cần cả hai.

<!-- gen:endpoints:start -->
**Mô hình quy trình**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-001 | `GET /models` | read | 001 | - | - | 200 |
| API-11-002 | `GET /models/{processKey}` | read | 001 | - | - | 200 |
| API-11-003 | `POST /models` | model | 002 | Có | - | 201 |
| API-11-004 | `POST /models:import` | model | 002, 010 | Có | - | 201 |
| API-11-005 | `PATCH /models/{processKey}` | model | 002 | - | Có | 200 |
| API-11-006 | `POST /models/{processKey}:archive` | publish | 009 | - | Có | 200 |

: Danh mục endpoint · Mô hình quy trình

**Phiên bản và thiết kế**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-007 | `GET /models/{processKey}/versions` | read | 006 | - | - | 200 |
| API-11-008 | `POST /models/{processKey}/versions` | model | 006 | Có | - | 201 |
| API-11-009 | `GET /models/{processKey}/versions/{version}` | read | 003, 006 | - | - | 200 |
| API-11-010 | `PUT /models/{processKey}/versions/{version}/bpmn` | model | 003 | - | Có | 200 |
| API-11-011 | `PUT /models/{processKey}/versions/{version}/elements/{elementId}` | model | 004 | - | Có | 200 |
| API-11-012 | `POST /models/{processKey}/versions/{version}:lock` | model | 003 | - | - | 200 |
| API-11-013 | `POST /models/{processKey}/versions/{version}:unlock` | model | 003 | - | - | 200 |
| API-11-014 | `POST /models/{processKey}/versions/{version}:validate` | model | 005 | - | - | 200 |
| API-11-015 | `GET /models/{processKey}/versions/{version}/diff` | read | 006 | - | - | 200 |
| API-11-024 | `GET /models/{processKey}/versions/{version}/export` | read | 010 | - | - | 200 |
| API-11-028 | `GET /element-catalog` | read | 003 | - | - | 200 |
| API-11-136 | `POST /models/{processKey}/versions/{version}:request-lock` | model | 003 | - | - | 200 |

: Danh mục endpoint · Phiên bản và thiết kế

**Duyệt phát hành**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-016 | `POST /models/{processKey}/versions/{version}:submit` | model | 007 | Có | Có | 202 |
| API-11-017 | `POST /models/{processKey}/versions/{version}:withdraw` | model | 007 | - | Có | 200 |
| API-11-018 | `GET /publish-requests` | publish | 008 | - | - | 200 |
| API-11-019 | `GET /publish-requests/{id}` | publish hoặc read | 008 | - | - | 200 |
| API-11-020 | `POST /publish-requests/{id}:approve` | publish | 008, 014 | - | Có | 200 |
| API-11-021 | `POST /publish-requests/{id}:reject` | publish | 008 | - | Có | 200 |
| API-11-022 | `POST /models/{processKey}/versions/{version}:deprecate` | publish | 009 | - | Có | 200 |
| API-11-023 | `POST /models/{processKey}/versions/{version}:retire` | publish | 009 | - | Có | 200 |
| API-11-131 | `POST /models/{processKey}/versions/{version}:restore` | publish | 009 | Có | Có | 202 |

: Danh mục endpoint · Duyệt phát hành

**Chạy thử**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-025 | `POST /models/{processKey}/versions/{version}/test-runs` | model | 011 | Có | - | 201 |
| API-11-026 | `GET /test-runs/{id}` | model | 011 | - | - | 200 |
| API-11-027 | `POST /test-runs/{id}:step` | model | 011 | - | - | 200 |

: Danh mục endpoint · Chạy thử

**Biểu mẫu, ý định, bù trừ**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-029 | `GET /forms` | read | 012 | - | - | 200 |
| API-11-030 | `POST /forms` | model | 012 | Có | - | 201 |
| API-11-031 | `GET /forms/{formKey}` | read | 012 | - | - | 200 |
| API-11-032 | `PUT /forms/{formKey}/versions/{version}` | model | 012 | - | Có | 200 |
| API-11-033 | `POST /forms/{formKey}/versions/{version}:publish` | model | 012 | - | Có | 200 |
| API-11-034 | `GET /intents` | read | 013 | - | - | 200 |
| API-11-035 | `POST /intents` | model | 013 | Có | - | 201 |
| API-11-036 | `PUT /intents/{intentCode}` | model | 013 | - | Có | 200 |
| API-11-037 | `POST /intents/{intentCode}:deprecate` | model | 013 | - | Có | 200 |
| API-11-038 | `GET /intents/{intentCode}/bindings` | read | 013 | - | - | 200 |
| API-11-039 | `GET /compensations` | read | 014 | - | - | 200 |
| API-11-040 | `PUT /models/{processKey}/versions/{version}/compensations` | model | 014 | - | Có | 200 |

: Danh mục endpoint · Biểu mẫu, ý định, bù trừ

**Mẫu, biến, bảng quyết định**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-041 | `GET /templates` | read | 015 | - | - | 200 |
| API-11-042 | `POST /templates` | model | 015 | Có | - | 201 |
| API-11-043 | `POST /templates/{templateCode}:publish` | model | 015 | - | Có | 200 |
| API-11-044 | `GET /models/{processKey}/versions/{version}/variables` | read | 016 | - | - | 200 |
| API-11-045 | `PUT /models/{processKey}/versions/{version}/variables` | model | 016 | - | Có | 200 |
| API-11-046 | `GET /decision-tables` | read | 017 | - | - | 200 |
| API-11-047 | `PUT /decision-tables/{code}` | model | 017 | - | Có | 200 |
| API-11-048 | `POST /decision-tables/{code}:evaluate` | model | 017 | - | - | 200 |

: Danh mục endpoint · Mẫu, biến, bảng quyết định

**Khởi tạo và tra cứu phiên**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-049 | `POST /instances` | instance hoặc bpm.instance.start | 018, 020 | Có | - | 201,200 |
| API-11-050 | `GET /instances` | read | 021 | - | - | 200 |
| API-11-051 | `GET /instances/{instanceId}` | read hoặc bpm.instance.read | 022 | - | - | 200 |
| API-11-052 | `GET /instances:by-key` | read hoặc bpm.instance.read | 018, 022 | - | - | 200 |
| API-11-053 | `GET /instances/{instanceId}/timeline` | read | 022 | - | - | 200 |
| API-11-054 | `GET /instances/{instanceId}/diagram` | read | 022 | - | - | 200 |
| API-11-055 | `GET /instances/{instanceId}/variables` | read | 022 | - | - | 200 |
| API-11-126 | `GET /event-start-bindings` | read | 019 | - | - | 200 |
| API-11-127 | `GET /models/{processKey}/start-form` | instance | 020 | - | - | 200 |
| API-11-128 | `POST /instances:export` | read | 021 | Có | - | 202 |

: Danh mục endpoint · Khởi tạo và tra cứu phiên

**Điều khiển phiên**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-056 | `POST /instances/{instanceId}:suspend` | instance hoặc bpm.instance.start | 023 | - | Có | 200 |
| API-11-057 | `POST /instances/{instanceId}:resume` | instance hoặc bpm.instance.start | 023 | - | Có | 200 |
| API-11-058 | `POST /instances/{instanceId}:cancel` | instance hoặc bpm.instance.start | 024 | - | Có | 200,202 |
| API-11-059 | `POST /instances/{instanceId}/changes` | instance-admin | 025, 027 | Có | - | 202 |
| API-11-060 | `GET /instance-changes/{id}` | instance-admin | 025, 027 | - | - | 200 |
| API-11-061 | `POST /instance-changes/{id}:approve` | instance-admin | 025, 027 | - | Có | 200 |
| API-11-062 | `POST /instance-changes/{id}:reject` | instance-admin | 025, 027 | - | Có | 200 |
| API-11-063 | `POST /migration-plans` | instance-admin | 026 | Có | - | 201 |
| API-11-064 | `POST /migration-plans/{id}:validate` | instance-admin | 026 | - | - | 200 |
| API-11-065 | `POST /migration-plans/{id}:submit` | instance-admin | 026 | - | Có | 200 |
| API-11-066 | `POST /migration-plans/{id}:approve` | instance-admin | 026 | - | Có | 202 |
| API-11-067 | `POST /migration-plans/{id}:reject` | instance-admin | 026 | - | Có | 200 |
| API-11-068 | `GET /migration-plans/{id}` | instance-admin | 026 | - | - | 200 |

: Danh mục endpoint · Điều khiển phiên

**Service task và thông điệp**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-069 | `POST /messages` | bpm.instance.start | 030 | Có | - | 202 |
| API-11-070 | `GET /instances/{instanceId}/service-calls` | read | 022, 028, 029 | - | - | 200 |
| API-11-071 | `POST /service-calls/{commandId}:resend` | compensate | 028 | Có | - | 202 |
| API-11-089 | `POST /instances/{instanceId}:supplement-received` | bpm.instance.start | 044, 049 | Có | - | 202 |

: Danh mục endpoint · Service task và thông điệp

**Việc của người dùng**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-072 | `GET /tasks` | task hoặc bpm.task.read | 034, 035 | - | - | 200 |
| API-11-073 | `GET /tasks/{taskId}` | task hoặc read | 037 | - | - | 200 |
| API-11-074 | `POST /tasks/{taskId}:claim` | task | 036 | - | Có | 200 |
| API-11-075 | `POST /tasks/{taskId}:unclaim` | task | 036 | - | Có | 200 |
| API-11-076 | `POST /tasks/{taskId}:complete` | task | 038 | Có | Có | 200 |
| API-11-077 | `PUT /tasks/{taskId}/draft` | task | 039 | - | Có | 200 |
| API-11-078 | `POST /tasks/{taskId}:transfer` | task hoặc task-admin | 040 | - | Có | 200 |
| API-11-083 | `GET /tasks/{taskId}/comments` | task hoặc read | 043 | - | - | 200 |
| API-11-084 | `POST /tasks/{taskId}/comments` | task | 043 | Có | - | 201 |
| API-11-085 | `POST /tasks/{taskId}/attachments` | task | 043 | Có | - | 201 |
| API-11-086 | `GET /tasks/{taskId}/attachments/{attachmentId}` | task hoặc read | 043 | - | - | 200 |
| API-11-087 | `POST /tasks/{taskId}:return` | task | 044 | - | Có | 200 |
| API-11-088 | `POST /tasks/{taskId}:request-supplement` | task | 044 | - | Có | 200 |
| API-11-124 | `POST /tasks/{taskId}/ai-suggestions` | task và PERM-17-use | 066 | - | - | 200 |
| API-11-125 | `GET /inbox-items` | task | 035 | - | - | 200 |

: Danh mục endpoint · Việc của người dùng

**Ủy quyền và phân công**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-079 | `GET /delegations` | task | 041 | - | - | 200 |
| API-11-080 | `POST /delegations` | task hoặc task-admin | 041 | Có | - | 201 |
| API-11-081 | `POST /delegations/{id}:revoke` | task hoặc task-admin | 041 | - | Có | 200 |
| API-11-082 | `POST /tasks:bulk-reassign` | task-admin | 042 | Có | - | 202 |

: Danh mục endpoint · Ủy quyền và phân công

**Lịch làm việc và hạn**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-090 | `GET /calendars` | read | 045 | - | - | 200 |
| API-11-091 | `PUT /calendars/{year}` | config | 045 | - | Có | 200 |
| API-11-092 | `POST /calendars/{year}:import` | config | 045 | - | Có | 200 |
| API-11-093 | `POST /calendars:compute-due` | read | 046 | - | - | 200 |
| API-11-094 | `GET /reports/due` | read | 050 | - | - | 200 |
| API-11-095 | `POST /reports/due:export` | read | 050 | Có | - | 202 |

: Danh mục endpoint · Lịch làm việc và hạn

**Saga và bù trừ**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-096 | `GET /sagas` | read | 052 | - | - | 200 |
| API-11-097 | `GET /sagas/{sagaId}` | read | 052 | - | - | 200 |
| API-11-098 | `POST /instances/{instanceId}:compensate` | compensate | 051 | Có | - | 202 |
| API-11-099 | `POST /sagas/{sagaId}/steps/{stepId}:retry` | compensate | 053 | - | - | 200 |
| API-11-100 | `POST /sagas/{sagaId}/steps/{stepId}:resolve-manual` | compensate | 053 | - | - | 200 |
| API-11-101 | `POST /sagas/{sagaId}/steps/{stepId}:skip` | compensate | 053 | - | - | 200 |
| API-11-102 | `GET /reconciliations` | read | 054 | - | - | 200 |
| API-11-103 | `POST /reconciliations` | compensate | 054 | Có | - | 202 |
| API-11-129 | `POST /sagas:export` | read | 052 | Có | - | 202 |
| API-11-132 | `POST /sagas/{sagaId}/steps/{stepId}:approve-skip` | compensate | 053 | - | - | 200 |
| API-11-133 | `POST /sagas/{sagaId}/steps/{stepId}:reject-skip` | compensate | 053 | - | - | 200 |

: Danh mục endpoint · Saga và bù trừ

**Tiến độ và lịch sử**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-104 | `GET /progress/{businessKey}` | bpm.progress.read | 055 | - | - | 200 |
| API-11-105 | `GET /instances/{instanceId}/history` | audit-read | 057 | - | - | 200 |
| API-11-106 | `POST /instances/{instanceId}/history:export` | audit-read | 057 | Có | - | 202 |
| API-11-123 | `GET /audit-logs` | audit-read | 065 | - | - | 200 |
| API-11-130 | `POST /audit-logs:export` | audit-read | 065 | Có | - | 202 |

: Danh mục endpoint · Tiến độ và lịch sử

**Giám sát và sự cố**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-107 | `GET /monitoring/summary` | read | 058 | - | - | 200 |
| API-11-108 | `GET /monitoring/bottlenecks` | read | 059 | - | - | 200 |
| API-11-109 | `GET /incidents` | read | 060 | - | - | 200 |
| API-11-110 | `GET /incidents/{incidentId}` | read | 060 | - | - | 200 |
| API-11-111 | `POST /incidents/{incidentId}:retry` | compensate | 060 | - | - | 200 |
| API-11-112 | `POST /incidents/{incidentId}:ignore` | compensate | 060 | - | - | 200 |
| API-11-113 | `POST /incidents:bulk-retry` | compensate | 060 | Có | - | 200 |
| API-11-114 | `GET /alert-rules` | read | 061 | - | - | 200 |
| API-11-115 | `PUT /alert-rules` | config | 061 | - | Có | 200 |

: Danh mục endpoint · Giám sát và sự cố

**Cấu hình và tuân thủ**

| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |
|---|---|---|---|---|---|---|
| API-11-116 | `GET /settings` | read | 062 | - | - | 200 |
| API-11-117 | `PUT /settings` | config | 062 | - | Có | 200 |
| API-11-118 | `GET /retention-policy` | read | 063 | - | - | 200 |
| API-11-119 | `PUT /retention-policy` | config | 063 | - | Có | 200 |
| API-11-120 | `POST /legal-holds` | config | 063 | Có | - | 201 |
| API-11-121 | `POST /compliance/sample-runs` | audit-read | 064 | Có | - | 202 |
| API-11-122 | `GET /compliance/evidence-packs/{id}` | audit-read | 064 | - | - | 200 |
| API-11-134 | `GET /legal-holds` | config | 063 | - | - | 200 |
| API-11-135 | `POST /legal-holds/{holdId}:release` | config | 063 | - | Có | 200 |
| API-11-137 | `GET /compliance/sample-runs` | audit-read | 064 | - | - | 200 |

: Danh mục endpoint · Cấu hình và tuân thủ
<!-- gen:endpoints:end -->

### 3.1. Sơ đồ trình tự các luồng chính

Bốn luồng dưới đây là phần dễ sai nhất của hợp đồng: khởi tạo phiên không được tạo trùng, service task không gọi HTTT trực tiếp, hoàn thành việc phải đi tiếp phiên trong một giao dịch, và tiến độ cho công dân không được lộ dữ liệu.

**Khởi tạo phiên idempotent (API-11-049).** Cổng DVC tỉnh gửi mã hồ sơ làm `businessKey`; nếu lời gọi bị hết thời gian chờ và gửi lại, PH-11 trả đúng phiên cũ.

```{.mermaid caption="Trình tự khởi tạo phiên idempotent từ Cổng DVC"}
sequenceDiagram
  participant DVC as Cổng DVC
  participant GW as PH-03 cổng API
  participant API as bpm-api
  participant DB as ph11_bpm
  participant FL as Flowable
  participant OB as Outbox
  DVC->>GW: POST /instances, Idempotency-Key, token bpm.instance.start
  GW->>API: Chuyển lượt gọi, traceparent
  API->>API: Kiểm scope, allowedStarters (ERR-11-020), hạn mức (ERR-11-041)
  API->>DB: Tìm phiên chưa kết thúc theo processKey và businessKey
  alt Đã có phiên cùng dữ liệu
    DB-->>API: Phiên cũ
    API-->>DVC: 200 phiên cũ
  else Đã có phiên khác dữ liệu
    API-->>DVC: 409 ERR-11-018
  else Chưa có phiên
    API->>API: Chọn phiên bản PUBLISHED, kiểm biến (ERR-11-017, 019)
    API->>FL: startProcessInstanceByKeyAndTenantId (một giao dịch)
    API->>DB: Ghi instance_index, due_tracking
    API->>OB: Ghi EVT-11-03 cùng giao dịch
    API-->>DVC: 201 instanceId, progressUrl, Location
  end
```

Người đọc cần thấy: kiểm trùng nằm trước khi chạm engine, và phiên, hạn, sự kiện cùng cam kết trong một giao dịch nên không có phiên nửa vời khi lỗi.

**Service task qua Kafka (ADR 112).** Engine không gọi HTTT: nó ghi lệnh vào outbox, PH-04 thực thi luồng và trả kết quả bằng sự kiện.

```{.mermaid caption="Trình tự service task bất đồng bộ qua Kafka"}
sequenceDiagram
  participant FL as Flowable
  participant B as bpm-service
  participant OB as Outbox
  participant K as Kafka
  participant P4 as PH-04
  FL->>B: Đến service task, intentCode
  B->>B: Tạo service_call, commandId, timeoutAt
  B->>OB: Ghi EVT-11-17 service.requested
  OB->>K: Đẩy lệnh (thử lại, ERR-11-101 khi hết lượt)
  K->>P4: Lệnh theo intentCode
  P4->>P4: Chạy luồng, chống trùng theo commandId
  alt Thành công
    P4->>K: EVT-11-18 service.completed
  else Lỗi
    P4->>K: EVT-11-19 service.failed, errorKind
  end
  K->>B: Kết quả, khử trùng theo commandId
  B->>FL: Hoàn thành bước hoặc ném lỗi nghiệp vụ
  B->>OB: EVT-11-04 tiến độ
```

Người đọc cần thấy: `commandId` đi suốt từ lệnh tới kết quả; lỗi `BUSINESS` kích hoạt bù trừ (Saga), lỗi `TECHNICAL` thử lại rồi mở sự cố (ERR-11-106); quá hạn chờ ghi ERR-11-102 và cho phép gửi lại bằng API-11-071.

**Hoàn thành việc (API-11-076).** Cán bộ bấm quyết định; hệ thống kiểm người nhận, biểu mẫu, tách nhiệm vụ rồi cho phiên đi tiếp.

```{.mermaid caption="Trình tự hoàn thành việc của cán bộ"}
sequenceDiagram
  actor CB as Cán bộ
  participant UI as Console
  participant API as bpm-api
  participant DB as ph11_bpm
  participant FL as Flowable
  participant OB as Outbox
  CB->>UI: Chọn quyết định, nhập ý kiến
  UI->>API: POST /tasks/{taskId}:complete, If-Match, Idempotency-Key
  API->>API: Kiểm người nhận (ERR-11-022), tách nhiệm vụ (ERR-11-005)
  API->>API: Kiểm data theo JSON Schema (ERR-11-023), ý kiến (ERR-11-007)
  API->>FL: taskService.complete với decision
  API->>DB: Ghi biến (SENSITIVE mã hóa), xóa nháp, đóng hạn việc
  API->>OB: EVT-11-10, EVT-11-04
  API-->>UI: 200 status COMPLETED, nextTasks
  UI-->>CB: Mở việc kế tiếp nếu giao cho chính người này
```

Người đọc cần thấy: toàn bộ chuỗi ghi chạy trong một giao dịch; `If-Match` chặn hai người cùng hoàn thành một việc.

**Tra tiến độ hồ sơ cho Cổng DVC (API-11-104).** Công dân tra hồ sơ trên Cổng DVC; PH-11 chỉ trả tiến độ rút gọn.

```{.mermaid caption="Trình tự tra tiến độ hồ sơ từ Cổng DVC"}
sequenceDiagram
  actor CD as Công dân
  participant DVC as Cổng DVC
  participant GW as PH-03 cổng API
  participant P as bpm-progress
  participant C as Valkey
  participant DB as ph11_bpm
  CD->>DVC: Tra hồ sơ HS-T68-2026-000142
  DVC->>GW: GET /progress/{businessKey}, token bpm.progress.read
  GW->>P: Chuyển lượt gọi
  P->>P: Kiểm quan hệ client với hồ sơ (ERR-11-035)
  P->>C: Đọc đệm 30 giây
  alt Trượt đệm
    P->>DB: Đọc instance_index, bước công khai
    P->>C: Ghi đệm
  end
  P->>DB: Ghi nhật ký truy cập
  P-->>DVC: 200 steps công khai, displayStatus, dueAt
  DVC-->>CD: Hiện từng bước theo ngôn ngữ dễ hiểu
```

Người đọc cần thấy: phản hồi chỉ chứa bước có `publicName`, không biến, không tên cán bộ; mỗi lượt tra đều được ghi nhật ký truy cập.

## 4. Danh mục sự kiện

21 sự kiện đăng ký ở PH-10, định dạng CloudEvents 1.0 dạng cấu trúc, đi qua outbox (ADR-042). `EVT-11-17` là lệnh tới PH-04; `EVT-11-18`, `EVT-11-19` do PH-04 phát, PH-11 tiêu thụ (mã do PH-11 định nghĩa để hợp đồng một chỗ). Schema đầy đủ ở [`ph11/asyncapi-bpm.yaml`](ph11/asyncapi-bpm.yaml).

### 4.1. Sự kiện của PH-11 (EVT-11-01…21)

<!-- gen:events:start -->
| Mã | Topic | Khóa | Payload `data` | Hướng | Bên nhận |
|---|---|---|---|---|---|
| EVT-11-01 | `{tenant}.bpm.model.published.v1` | `processKey` | `ModelPublishedData` | PH-11 phát | PH-13, PH-10 |
| EVT-11-02 | `{tenant}.bpm.model.retired.v1` | `processKey` | `ModelRetiredData` | PH-11 phát | PH-13 |
| EVT-11-03 | `{tenant}.bpm.instance.started.v1` | `businessKey` | `InstanceStartedData` | PH-11 phát | DVC, HTTT một cửa, PH-13 |
| EVT-11-04 | `{tenant}.bpm.instance.step.completed.v1` | `businessKey` | `StepCompletedData` | PH-11 phát | DVC (tiến độ), HTTT một cửa |
| EVT-11-05 | `{tenant}.bpm.instance.completed.v1` | `businessKey` | `InstanceCompletedData` | PH-11 phát | DVC, PH-01, PH-07, PH-19 |
| EVT-11-06 | `{tenant}.bpm.instance.cancelled.v1` | `businessKey` | `InstanceCancelledData` | PH-11 phát | DVC, phân hệ khởi tạo |
| EVT-11-07 | `{tenant}.bpm.instance.suspended.v1` | `businessKey` | `InstanceSuspendedData` | PH-11 phát | HTTT một cửa |
| EVT-11-08 | `{tenant}.bpm.task.created.v1` | `businessKey` | `TaskCreatedData` | PH-11 phát | Hộp việc, HTTT một cửa |
| EVT-11-09 | `{tenant}.bpm.task.assigned.v1` | `businessKey` | `TaskAssignedData` | PH-11 phát | Hộp việc |
| EVT-11-10 | `{tenant}.bpm.task.completed.v1` | `businessKey` | `TaskCompletedData` | PH-11 phát | Hộp việc, PH-13 |
| EVT-11-11 | `{tenant}.bpm.task.due-soon.v1` | `businessKey` | `TaskDueSoonData` | PH-11 phát | Thông báo |
| EVT-11-12 | `{tenant}.bpm.task.overdue.v1` | `businessKey` | `TaskOverdueData` | PH-11 phát | PH-13, thông báo |
| EVT-11-13 | `{tenant}.bpm.saga.compensation.started.v1` | `businessKey` | `SagaStartedData` | PH-11 phát | PH-13 |
| EVT-11-14 | `{tenant}.bpm.saga.compensation.completed.v1` | `businessKey` | `SagaCompletedData` | PH-11 phát | PH-13, DVC |
| EVT-11-15 | `{tenant}.bpm.saga.compensation.failed.v1` | `businessKey` | `SagaFailedData` | PH-11 phát | PH-13 (P1) |
| EVT-11-16 | `{tenant}.bpm.incident.opened.v1` | `businessKey` | `IncidentOpenedData` | PH-11 phát | PH-13 |
| EVT-11-17 | `{tenant}.bpm.service.requested.v1` | `businessKey` | `ServiceRequestedData` | PH-11 phát | PH-04 |
| EVT-11-18 | `{tenant}.bpm.service.completed.v1` | `businessKey` | `ServiceCompletedData` | PH-04 phát, PH-11 nhận | PH-11 (do PH-04 phát) |
| EVT-11-19 | `{tenant}.bpm.service.failed.v1` | `businessKey` | `ServiceFailedData` | PH-04 phát, PH-11 nhận | PH-11 (do PH-04 phát) |
| EVT-11-20 | `{tenant}.bpm.notification.requested.v1` | `businessKey` | `NotificationRequestedData` | PH-11 phát | Kênh thông báo, PH-03 |
| EVT-11-21 | `{tenant}.bpm.audit.recorded.v1` | `objectId` | `AuditRecordedData` | PH-11 phát | PH-13 |

: Sự kiện của PH-11
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Các quy tắc sau áp dụng cho cả 21 sự kiện.

- **Không giá trị biến**: payload chỉ chứa mã, tên bước, trạng thái; `payload` của lệnh `service.requested` là tham chiếu tới nội dung lưu ở kho đối tượng, không nhúng dữ liệu cá nhân; `params` của `notification.requested` không chứa DLCN.
- **Thứ tự và khử trùng**: khóa phân vùng ở cột "Khóa" (`businessKey` giữ thứ tự theo hồ sơ; `processKey` cho sự kiện mô hình); phát ít nhất một lần, bên nhận khử trùng theo `id` (inbox) và theo `commandId` với kết quả service task; trùng ghi ERR-11-104 và bỏ qua.
- **Lệnh và kết quả**: lệnh có `timeoutAt`; quá hạn chờ ghi ERR-11-102 và mở sự cố; kết quả không tương quan được thì ghi ERR-11-103 và đưa vào hàng đợi xử lý tay.
- **Đăng ký topic**: 20 topic `{tenant}.bpm.*` đăng ký ở PH-10; Cổng DVC chọn nhận tiến độ bằng EVT-11-04 hay chỉ gọi API (Q11-05 của FRS).
- **Tương thích**: chỉ thêm trường tùy chọn trong `v1` (BACKWARD, ADR-070); lưu giữ topic 7 ngày, 3 phân vùng (giả định theo mức của PH-05).

## 5. Hợp đồng với phân hệ khác và bên ngoài

Bảng liệt kê từng bên tương tác với PH-11, hướng gọi và hợp đồng.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| Cổng DVC tỉnh, HTTT một cửa | Bên ngoài → PH-11 | API-11-049, 051, 052, 069, 089 (scope `bpm.instance.start`, `.read`); API-11-104 (scope `bpm.progress.read`); EVT-11-03…06 | Khởi tạo phiên, báo bổ sung hồ sơ, tra tiến độ; nhận kết quả qua `callbackTopic` hoặc EVT-11-05, 06 |
| PH-01, PH-07, PH-19 | Phân hệ → PH-11 | API-11-049 (khởi tạo `DUYET_KET_NAP_HTTT`); nghe EVT-11-05, 06 | Luồng duyệt nhiều cấp chuyển sang PH-11 (Q11-08 của FRS) |
| PH-04 | PH-11 ↔ PH-04 | EVT-11-17 (lệnh), EVT-11-18, 19 (kết quả); danh mục luồng khi kiểm tra tĩnh (ERR-11-012) | Chống trùng theo `commandId`; PH-11 không gọi HTTT trực tiếp (ADR 112) |
| PH-10 | PH-11 ↔ PH-10 | 20 topic `{tenant}.bpm.*`; API-11-126 liệt kê liên kết sự kiện khởi tạo | Khởi tạo phiên từ sự kiện (FR-11-019), thông điệp tương quan |
| PH-03 | PH-03 → PH-11, PH-11 → PH-03 | Chuyển lượt gọi từ kênh ngoài; EVT-11-20 (thông báo) | Kênh thông báo dùng chung (Q11-07 của FRS) |
| PH-12 | PH-11 → PH-12 | Người dùng, nhóm, đơn vị cho phân công; quyền `PERM-11-*`, scope `bpm.*` | Giải ứng viên không ra: nhóm dự phòng `11.task.fallbackGroup` (ERR-11-113) |
| PH-13 | PH-11 → PH-13 | EVT-11-01, 02, 03, 05, 10, 12, 13…16; chỉ số OTLP; API-11-105, 123 | Giám sát, kiểm toán |
| PH-17 | PH-11 → PH-17 | API-11-124 (gợi ý xử lý việc) | Mức C; quá `11.ai.timeoutSeconds` trả gợi ý rỗng |
| Hộp "Việc của tôi" (PH-00) | PH-00 → PH-11 | API-11-125 (nhà cung cấp việc cho FR-00-070) | Không có giá trị biến |
| PH-09 | PH-11 → PH-09 | `PERM-09-unmask`, phân loại dữ liệu biến | Che biến theo phân loại |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-11

Dải 001…099 trả cho người gọi API; dải 101…199 là lỗi runtime (engine, service task, Saga) ghi nhật ký, hiện cho người vận hành ở màn giám sát và không trả qua API. Cột "Thông báo hiển thị" lấy từ FRS 9.2, `{…}` thay bằng giá trị thật.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | Thông báo hiển thị | API phát sinh (API-11-) |
|---|---|---|---|---|
| ERR-11-001 | 404, 410 | Không tìm thấy đối tượng hoặc thuộc tenant khác; `410` khi đã hết lưu giữ | Không tìm thấy {đối tượng} {mã}. | 88 API |
| ERR-11-002 | 409 | Mã đã tồn tại (mô hình, biểu mẫu, ý định, mẫu) | Mã {mã} đã được dùng. Chọn mã khác. | 8 API |
| ERR-11-003 | 400 | Dữ liệu, tham số không hợp lệ theo lược đồ | Theo FR | 109 API |
| ERR-11-004 | 409 | `ETag` lệch, đối tượng đã bị thay đổi | Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới. | 48 API |
| ERR-11-005 | 403 | Vi phạm bốn mắt hoặc tách nhiệm vụ | Anh/chị là người đề nghị hoặc đã xử lý bước trước nên không được duyệt bước này. | 17 API |
| ERR-11-006 | 409 | Trạng thái không cho thao tác | {Đối tượng} đang ở trạng thái {trạng thái}, không thể {thao tác}. | 30 API |
| ERR-11-007 | 422 | Thiếu ý kiến, lý do, ghi chú bắt buộc | Nhập {ý kiến, lý do, ghi chú} (tối thiểu {n} ký tự). | 21 API |
| ERR-11-008 | 400 | BPMN XML sai chuẩn | Sơ đồ không đúng chuẩn BPMN 2.0 tại dòng {dòng}: {mô tả}. | 8 API |
| ERR-11-009 | 413 | Tệp hoặc XML vượt cỡ | Tệp vượt {n} KB. | 8 API |
| ERR-11-010 | 422 | Kiểm tra tĩnh còn lỗi `ERROR` | Mô hình còn {n} lỗi phải sửa. Xem ngăn Kết quả kiểm tra. | 7 API |
| ERR-11-011 | 422 | Ý định không tồn tại, ngừng dùng hoặc thiếu | Ý định {intentCode} không tồn tại hoặc đã ngừng dùng. | 004, 011, 024 |
| ERR-11-012 | 422 | Luồng PH-04 chưa phát hành hoặc chưa kiểm được | Luồng {flowCode} chưa được phát hành ở môi trường {env}. | 014, 034, 035, 036, 037, 038 |
| ERR-11-013 | 422 | Bước rủi ro thiếu bù trừ | Bước {tên} ghi dữ liệu ở cơ quan khác nhưng chưa có cách bù trừ. | 014, 016 |
| ERR-11-014 | 422 | Biểu mẫu chưa phát hành | Biểu mẫu {formKey} chưa được phát hành. | 011 |
| ERR-11-015 | 422 | Biến chưa khai báo hoặc phân loại, mã hóa sai | Biến {tên} chưa khai báo hoặc phải mã hóa. | 011, 032, 044, 045 |
| ERR-11-016 | 409 | Bản nháp đang bị người khác khóa soạn thảo | {người} đang sửa bản nháp này từ {giờ}. Bạn đang ở chế độ chỉ xem. | 009, 010, 012, 013, 028, 136 |
| ERR-11-017 | 422 | Mô hình không có phiên bản `PUBLISHED` | Quy trình {processKey} chưa có phiên bản đang phát hành. | 049, 052 |
| ERR-11-018 | 409 | Hồ sơ đã có phiên với dữ liệu khác | Hồ sơ {businessKey} đã có phiên đang xử lý. | 049, 052, 127 |
| ERR-11-019 | 422 | Biến vào thiếu hoặc sai kiểu | Theo FR | 049, 052, 069, 127 |
| ERR-11-020 | 403 | Client hoặc kênh không được phép khởi tạo mô hình | Quy trình {tên} không cho khởi tạo từ kênh này. | 049, 052, 127 |
| ERR-11-021 | 409 | Việc đã có người nhận | Việc đã được {người} nhận lúc {giờ}. | 074, 075 |
| ERR-11-022 | 403 | Người dùng không phải người nhận, ứng viên của việc | Anh/chị không được giao việc này. | 073, 074, 075, 076 |
| ERR-11-023 | 422 | Dữ liệu biểu mẫu không đạt JSON Schema | Theo FR | 076, 077 |
| ERR-11-024 | 422 | Người nhận chuyển, chỉ định không hợp lệ | Không chuyển được cho {người}: {lý do}. | 016, 017, 078 |
| ERR-11-025 | 422 | Ủy quyền không hợp lệ | Ủy quyền không hợp lệ: {lý do}. | 079, 080, 081 |
| ERR-11-026 | 422 | Bước trả về không được phép | Không trả về được bước {tên}. Chỉ trả về: {danh sách}. | 087, 088, 089 |
| ERR-11-027 | 413, 422 | Tệp không an toàn, sai loại hoặc quá cỡ | Tệp {tên} không được chấp nhận: {lý do}. | 004, 024, 083, 084, 085, 086 |
| ERR-11-028 | 422 | Lịch làm việc không hợp lệ | Lịch không hợp lệ: {lý do}. | 090, 091, 092 |
| ERR-11-029 | 422 | Tham số, ngưỡng ngoài miền hoặc vượt trần | {key} phải trong khoảng {min}…{max}. | 114, 115, 116, 117 |
| ERR-11-030 | 409 | Phiên đang bù trừ | Phiên đang bù trừ, chờ Saga kết thúc. | 7 API |
| ERR-11-031 | 422 | Kế hoạch di trú còn bước chưa ánh xạ | Còn {n} bước chưa ánh xạ sang phiên bản mới. | 063, 064, 065, 066, 067, 068 |
| ERR-11-032 | 422 | Bước đích chuyển bước không hợp lệ | Không chuyển được tới bước {tên}: {lý do}. | 059, 060, 061, 062 |
| ERR-11-033 | 422 | Biến không được sửa | Biến {tên} không được sửa sau khi khởi tạo. | 059, 060, 061, 062 |
| ERR-11-034 | 403 | Ngoài phạm vi dữ liệu | Anh/chị không có quyền xem hồ sơ này. | 051, 052, 053, 054, 055, 070 |
| ERR-11-035 | 404 | Tiến độ: không có hồ sơ hoặc client không được phép (không lộ tồn tại) | Theo FR | 104 |
| ERR-11-036 | 403 | Sửa mẫu `COMMON` khi không phải PA | Mẫu dùng chung chỉ quản trị nền tảng được sửa. | 041, 042, 043 |
| ERR-11-037 | 409 | Còn phiên chạy hoặc còn tham chiếu, không thu hồi được | Còn {n} hồ sơ đang xử lý trên phiên bản này. | 006, 022, 023, 131 |
| ERR-11-038 | 422 | Ngừng phiên bản phát hành duy nhất khi chưa xác nhận | Đây là phiên bản duy nhất đang phát hành. Xác nhận để tiếp tục. | 006, 022, 023, 131 |
| ERR-11-039 | 422 | Khoảng thời gian vượt giới hạn: 366 ngày cho báo cáo, xuất, nhật ký; 12 tháng cho thống kê tuân thủ | Khoảng thời gian tối đa {n} {ngày, tháng}. | 9 API |
| ERR-11-040 | 422 | Bảng quyết định không hợp lệ | Dòng {a} và {b} cùng khớp một trường hợp. | 046, 047, 048 |
| ERR-11-041 | 429 | Vượt hạn mức khởi tạo | Vượt số lượt cho phép. Thử lại sau {n} giây. | 049, 052 |
| ERR-11-042 | 422 | Chạy thử thiếu kết quả giả lập | Chưa có kết quả giả lập cho bước {tên}. | 025, 026, 027 |
| ERR-11-043 | 422 | Dự phòng (chưa dùng) | Theo FR | Dự phòng, chưa có API |
| ERR-11-044 | 422 | Bù trừ trỏ chính bước xuôi hoặc ý định không hợp lệ | Hành động bù trừ phải khác hành động của bước {tên}. | 020, 039, 040 |
| ERR-11-045 | 422 | Dự phòng (gộp vào kiểm tra tĩnh `CALL_CYCLE`) | Theo FR | Dự phòng, chưa có API |
| ERR-11-046 | 503, 422 | Engine, CSDL không sẵn sàng hoặc engine từ chối triển khai | Dịch vụ quy trình tạm thời không sẵn sàng. Thử lại sau. | 018, 019, 020, 021, 049, 052 |
| ERR-11-047 | 409 | Hồ sơ đang giữ pháp lý | Hồ sơ {businessKey} đang được giữ theo yêu cầu pháp lý. | 118, 119, 120, 134, 135 |
| ERR-11-048 | 422 | Dự phòng (chưa dùng) | Theo FR | Dự phòng, chưa có API |
| ERR-11-049 | 404 | Không có phiên chờ thông điệp hoặc chờ bổ sung | Hồ sơ {businessKey} hiện không chờ {thông điệp, bổ sung}. | 069, 089 |
| ERR-11-050 | 422 | Vượt số việc tối đa mỗi lần giao lại | Mỗi lần giao lại tối đa {n} việc. | 082 |
| ERR-11-051 | 409 | `Idempotency-Key` dùng lại với nội dung khác | Khóa Idempotency-Key này đã dùng cho yêu cầu khác. Tạo khóa mới. | 049, 052 |
| ERR-11-101 | - | Không đẩy được lệnh service task lên Kafka | Không gửi được lệnh {intentCode} của hồ sơ {businessKey} sau {n} lần. | Không trả cho người gọi |
| ERR-11-102 | - | Chờ kết quả service task quá hạn | Lệnh {intentCode} của hồ sơ {businessKey} chưa có kết quả sau {n} giờ. | Không trả cho người gọi |
| ERR-11-103 | - | Kết quả không tương quan được | Kết quả của lệnh {commandId} không khớp phiên nào, đã chuyển hàng đợi lỗi. | Không trả cho người gọi |
| ERR-11-104 | - | Kết quả, thông điệp trùng (bỏ qua, chỉ đếm) | Theo FR | Không trả cho người gọi |
| ERR-11-105 | - | Lỗi nghiệp vụ từ PH-04 | Cơ quan {cơ quan} trả lỗi nghiệp vụ {mã}: {mô tả}. | Không trả cho người gọi |
| ERR-11-106 | - | Lỗi kỹ thuật PH-04 đã hết lượt thử | Lệnh {intentCode} lỗi kỹ thuật sau {n} lần thử: {mô tả}. | Không trả cho người gọi |
| ERR-11-107 | - | Job engine hết lượt thử | Theo FR | Không trả cho người gọi |
| ERR-11-108 | - | Hẹn giờ không chạy được | Hẹn giờ của bước {tên} (hồ sơ {businessKey}) không chạy được: {mô tả}. | Không trả cho người gọi |
| ERR-11-109 | - | Hết thời gian chờ thông điệp | Hồ sơ {businessKey} hết thời gian chờ thông điệp {tên}. | Không trả cho người gọi |
| ERR-11-110 | - | Hành động bù trừ thất bại | Theo FR | Không trả cho người gọi |
| ERR-11-111 | - | Không ghi được nhật ký Saga | Theo FR | Không trả cho người gọi |
| ERR-11-112 | - | Bước không có bù trừ khi Saga chạy, chuyển thủ công | Bước {tên} chưa có bù trừ, đã chuyển xử lý thủ công. | Không trả cho người gọi |
| ERR-11-113 | - | Không có ứng viên hợp lệ cho việc | Theo FR | Không trả cho người gọi |
| ERR-11-114 | - | Không đăng ký được việc vào hộp "Việc của tôi" | Theo FR | Không trả cho người gọi |
| ERR-11-115 | - | Phiên tắc quá ngưỡng | Theo FR | Không trả cho người gọi |
| ERR-11-116 | - | Thiếu lịch làm việc của năm | Theo FR | Không trả cho người gọi |
| ERR-11-117 | - | Outbox sự kiện tồn đọng | Có {n} sự kiện chưa gửi lên Kafka quá {m} phút. | Không trả cho người gọi |
| ERR-11-118 | - | Quy trình con không có phiên bản phát hành | Quy trình con {processKey} chưa có phiên bản đang phát hành. | Không trả cho người gọi |
| ERR-11-119 | - | Di trú một phiên thất bại | Theo FR | Không trả cho người gọi |
| ERR-11-120 | - | Sự kiện khởi tạo không hợp lệ | Sự kiện khởi tạo {mã sự kiện} không hợp lệ: {mô tả}. | Không trả cho người gọi |
| ERR-11-121 | - | Đối soát phát hiện bù trừ chưa có hiệu lực | Theo FR | Không trả cho người gọi |
| ERR-11-122 | - | Dọn lịch sử lỗi | Theo FR | Không trả cho người gọi |
| ERR-11-123 | - | Gửi thông báo thất bại | Theo FR | Không trả cho người gọi |
| ERR-11-124 | - | Gợi ý AI quá thời gian | Theo FR | Không trả cho người gọi |
| ERR-11-125 | - | Hết hạn bổ sung hồ sơ mà chưa nhận bổ sung | Hồ sơ {businessKey} quá {n} ngày chưa được bổ sung; đã mở sự cố. | Không trả cho người gọi |

: Mã lỗi ERR-11
<!-- gen:errors:end -->

### 6.1. Thân lỗi

Lược đồ `Problem`: `type`, `title`, `status`, `detail`, `instance`, `code`, `traceId`, `errors[]` (`field`, `message`). `title`, `detail` theo `Accept-Language`; thông báo hiển thị cho người dùng theo FRS 9.2; mã `ERR-11-003`, `019`, `023` hiển thị theo từng trường ở `errors[]`.

```json
{ "type": "https://datahub.example.vn/errors/ERR-11-019", "title": "Biến vào thiếu hoặc sai kiểu", "status": 422,
  "code": "ERR-11-019", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{ "field": "variables.maXa", "message": "Thiếu biến bắt buộc." }] }
```

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng được kiểm tự động ở CI để OpenAPI, AsyncAPI, FRS và tài liệu không lệch nhau.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; mọi ví dụ khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; lệnh ghi có `If-Match`, lệnh tạo có `Idempotency-Key`; mã ERR có ở FRS và mã HTTP của nó có trong responses; API tiến độ không có trường biến hay tên cán bộ | [`check_contracts.py`](ph11/tools/check_contracts.py); `openapi-spec-validator`; `jsonschema` 2020-12 | CI-5 |
| AsyncAPI 3.0: kênh, operation, thông điệp tham chiếu đúng; ví dụ khớp payload; đủ 21 topic đúng FRS | `check_contracts.py`; `@asyncapi/cli validate` | CI-5 |
| Lint quy ước (không lỗi, không cảnh báo); thay đổi phá vỡ trong `v1` | `npx @redocly/cli@1 lint openapi-bpm.yaml`; oasdiff `breaking` | CI-5 |
| Enum, trường, ERR, EVT, PERM, đường dẫn API-11-001…137 và FR của từng dòng khớp FRS | [`doi_chieu_frs.py`](ph11/tools/doi_chieu_frs.py) | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`, `sinh_dac_ta_api.py`, rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp tài liệu gốc | `build/tools/kiem_tra_ma.py` | CI-1 |

: Các kiểm tra hợp đồng chạy trong CI

Kết quả chạy ngày 26/11/2026 trên máy viết tài liệu: `check_contracts.py` báo OpenAPI hợp lệ, 137 operation, 137 mã, 226 ví dụ khớp; AsyncAPI 21 kênh, 21 operation, 21 thông điệp, 21 ví dụ khớp; 0 lỗi. `doi_chieu_frs.py` báo 137 mã FRS §9.4 khớp phương thức, đường dẫn, FR; không có ERR, EVT, PERM lệch; 0 enum mới. Redocly lint không có lỗi hay cảnh báo.

```bash
cd datahub-docs/03-thiet-ke/api/ph11
python3 tools/gen_openapi.py && python3 tools/gen_asyncapi.py && python3 tools/gen_md.py --write
python3 tools/check_contracts.py && python3 tools/doi_chieu_frs.py
python3 ../../../build/tools/sinh_dac_ta_api.py openapi-bpm.yaml ../D03-04-PH11-api-quy-trinh.md
```

## 8. Ánh xạ từ hệ cũ

SRS cũ (`docs/07-srs/SRS-PH-11-bpm.md` mục 5.4) có ba API; tập này thay bằng một gốc `/api/bpm/v1`, bỏ tiền tố `/api/v1/bpm` và `/service-tasks/…/fail`.

| API cũ | API mới | Chuyển đổi |
|---|---|---|
| `POST /api/v1/bpm/instances` | API-11-049 `POST /instances` | Thêm `Idempotency-Key`, `businessKey` là mã hồ sơ, kiểm `allowedStarters` và hạn mức |
| `POST /api/v1/bpm/service-tasks/{executionId}/fail` | EVT-11-19 `service.failed` (PH-04 phát), API-11-098 và 099 (bù trừ thủ công, thử lại bước) | Không còn API đồng bộ để báo lỗi service task: PH-04 trả kết quả qua Kafka, tương quan theo `commandId` (ADR 112) |
| `GET /api/v1/bpm/instances/{id}/progress` | API-11-104 `GET /progress/{businessKey}` | Tra theo mã hồ sơ, scope `bpm.progress.read`, che DLCN, đệm 30 giây |

: Ánh xạ API của SRS cũ sang API mới

Hệ Viettel 2021 không có API điều phối quy trình liên thông để ánh xạ; LGC-NGSP-002 (tra trạng thái hồ sơ) được đáp ứng bởi API-11-104.

## 9. Truy vết FR → API

Mỗi FR của FRS có ít nhất một API hoặc ghi rõ hệ thống tự chạy, phát sự kiện, không có API.

<!-- gen:fr:start -->
| FR | Tên | API (API-11-) |
|---|---|---|
| FR-11-001 | Liệt kê, tìm kiếm mô hình quy trình | 001, 002 |
| FR-11-002 | Tạo mô hình quy trình | 003, 004, 005 |
| FR-11-003 | Thiết kế sơ đồ BPMN 2.0 trên trình thiết kế | 009, 010, 012, 013, 028, 136 |
| FR-11-004 | Cấu hình thuộc tính bước | 011 |
| FR-11-005 | Kiểm tra tĩnh mô hình | 014 |
| FR-11-006 | Quản lý phiên bản nháp, so sánh hai phiên bản | 007, 008, 009, 015 |
| FR-11-007 | Gửi duyệt phát hành mô hình | 016, 017 |
| FR-11-008 | Duyệt hoặc từ chối phát hành, triển khai lên engine | 018, 019, 020, 021 |
| FR-11-009 | Ngừng dùng, thu hồi phiên bản | 006, 022, 023, 131 |
| FR-11-010 | Nhập, xuất tệp BPMN 2.0 XML và gói quy trình | 004, 024 |
| FR-11-011 | Chạy thử mô hình với service task giả lập | 025, 026, 027 |
| FR-11-012 | Quản lý biểu mẫu việc người dùng | 029, 030, 031, 032, 033 |
| FR-11-013 | Đăng ký ý định nghiệp vụ và ánh xạ sang luồng PH-04 | 034, 035, 036, 037, 038 |
| FR-11-014 | Đăng ký hành động bù trừ theo bước | 020, 039, 040 |
| FR-11-015 | Quản lý mẫu quy trình dùng chung | 041, 042, 043 |
| FR-11-016 | Khai báo biến quy trình và phân loại dữ liệu | 044, 045 |
| FR-11-017 | Bảng quyết định DMN đơn giản cho rẽ nhánh | 046, 047, 048 |
| FR-11-018 | Khởi tạo phiên qua API | 049, 052 |
| FR-11-019 | Khởi tạo phiên từ sự kiện PH-10 | 126 |
| FR-11-020 | Khởi tạo phiên thủ công trên giao diện | 049, 127 |
| FR-11-021 | Liệt kê, tìm kiếm phiên | 050, 128 |
| FR-11-022 | Xem chi tiết phiên | 051, 052, 053, 054, 055, 070 |
| FR-11-023 | Tạm dừng, tiếp tục phiên | 056, 057 |
| FR-11-024 | Hủy phiên kèm bù trừ tùy chọn | 058 |
| FR-11-025 | Sửa biến phiên có kiểm soát | 059, 060, 061, 062 |
| FR-11-026 | Di trú phiên sang phiên bản mô hình mới | 063, 064, 065, 066, 067, 068 |
| FR-11-027 | Chuyển phiên tới bước khác | 059, 060, 061, 062 |
| FR-11-028 | Gửi lệnh thực thi service task tới PH-04 | 070, 071 |
| FR-11-029 | Nhận kết quả, lỗi service task và tương quan | 070 |
| FR-11-030 | Chờ thông điệp, sự kiện | 069 |
| FR-11-031 | Hẹn giờ khởi tạo, trung gian, biên | Hệ thống: hẹn giờ chạy trong engine (EVT-11-11, 12) |
| FR-11-032 | Gửi thông báo từ quy trình | Hệ thống: gửi thông báo qua EVT-11-20 |
| FR-11-033 | Gọi quy trình con | Hệ thống: quy trình con chạy trong engine, cấu hình ở API-11-011 |
| FR-11-034 | Tạo việc và phân công | 072 |
| FR-11-035 | Đăng ký việc vào hộp "Việc của tôi" | 072, 125 |
| FR-11-036 | Nhận việc, trả lại việc | 074, 075 |
| FR-11-037 | Xem chi tiết việc và hồ sơ liên quan | 073 |
| FR-11-038 | Hoàn thành việc với biểu mẫu, ý kiến, quyết định | 076 |
| FR-11-039 | Lưu nháp kết quả việc | 077 |
| FR-11-040 | Chuyển việc cho người khác | 078 |
| FR-11-041 | Ủy quyền khi vắng mặt | 079, 080, 081 |
| FR-11-042 | Phân công lại hàng loạt | 082 |
| FR-11-043 | Đính kèm tệp, trao đổi ý kiến trên việc | 083, 084, 085, 086 |
| FR-11-044 | Trả về bước trước, yêu cầu bổ sung hồ sơ | 087, 088, 089 |
| FR-11-045 | Quản lý lịch làm việc theo tenant | 090, 091, 092 |
| FR-11-046 | Tính hạn xử lý theo ngày làm việc cho phiên và việc | 093 |
| FR-11-047 | Nhắc hạn trước hạn | Hệ thống: quét hạn theo `11.due.scanMinutes`, phát EVT-11-11 |
| FR-11-048 | Xử lý quá hạn, leo thang | Hệ thống: leo thang theo cấu hình bước, phát EVT-11-12 |
| FR-11-049 | Tạm dừng tính hạn khi chờ bổ sung | 089 |
| FR-11-050 | Báo cáo đúng hạn, trễ hạn | 094, 095 |
| FR-11-051 | Điều phối bù trừ khi lỗi bước | 098 |
| FR-11-052 | Theo dõi nhật ký Saga | 096, 097, 129 |
| FR-11-053 | Xử lý bù trừ thất bại | 099, 100, 101, 132, 133 |
| FR-11-054 | Đối soát bù trừ định kỳ | 102, 103 |
| FR-11-055 | Cung cấp tiến độ hồ sơ cho kênh DVC | 104 |
| FR-11-056 | Phát sự kiện tiến độ | Hệ thống: phát EVT-11-04 qua outbox (mục 4) |
| FR-11-057 | Tra lịch sử bước phục vụ kiểm toán | 105, 106 |
| FR-11-058 | Bảng điều khiển giám sát quy trình | 107 |
| FR-11-059 | Phát hiện tắc nghẽn bước | 108 |
| FR-11-060 | Quản lý sự cố engine và thử lại | 109, 110, 111, 112, 113 |
| FR-11-061 | Chỉ số và cảnh báo vận hành | 114, 115 |
| FR-11-062 | Cấu hình tham số `11.*` theo tenant | 116, 117 |
| FR-11-063 | Lưu giữ, dọn lịch sử phiên | 118, 119, 120, 134, 135 |
| FR-11-064 | Xuất bằng chứng tuân thủ BPMN 2.0 | 121, 122, 137 |
| FR-11-065 | Xem nhật ký kiểm toán phân hệ | 123, 130 |
| FR-11-066 | Gợi ý xử lý việc bằng AI | 124 |

: Truy vết FR-11 sang API
<!-- gen:fr:end -->

## 10. Câu hỏi mở

Các câu hỏi dưới đây chưa có quyết định; cột đề xuất là giả định tạm dùng.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q11-55 | `Idempotency-Key` dùng lại với nội dung khác trả mã lỗi nào | Đã chốt ở FRS 0.2: ERR-11-051 (409) |
| Q11-56 | Hạn mức khởi tạo `11.instance.startRatePerClient` tính ở cổng PH-03 hay ở `dh-platform`; có trả tiêu đề `RateLimit-*` ngoài `Retry-After` không | Tính ở `dh-platform` theo client, trả cả hai tiêu đề |
| Q11-57 | `unmask=true` và `X-Unmask-Reason` ở `GET /instances/{id}/variables` có đủ an toàn, hay chuyển sang `POST …:reveal` có thân | Giữ `GET` với tiêu đề cho lý do; chuyển `POST` nếu ATTT yêu cầu |
| Q11-58 | Bốn mắt cho bỏ qua bước bù trừ (API-11-101) và mẫu `COMMON` (API-11-043): cách truyền người duyệt | Đã chốt ở FRS 0.2: không truyền người duyệt; người khác gọi API duyệt (API-11-132, 133), trùng người là ERR-11-005 |
| Q11-59 | Tải gói bằng chứng, xuất báo cáo: liên kết ký có hạn hay luồng trực tiếp; gói chưa dựng xong trả mã nào | Liên kết ký có hạn 15 phút; chưa xong trả `409` ERR-11-006 (đã chốt ở FRS 0.2, FR-11-064) |

: Câu hỏi mở của tập API PH-11

## 11. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả; dòng vắng (thân yêu cầu, chống trùng, ghi chú) nghĩa là Không; mọi phản hồi đối tượng có tiêu đề `ETag`; ví dụ yêu cầu và phản hồi nằm trong OpenAPI để tập không vượt giới hạn cỡ.

<!-- gen:dac-ta-api:start -->

### Mô hình quy trình

#### API-11-001 · Danh sách, tìm kiếm mô hình

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm mô hình.

**Phương thức, đường dẫn.** `GET /models`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-001.

**Tham số.** `q` (query, string, tùy chọn); `group` (query, string, tùy chọn); `status` (query, VersionStatus, tùy chọn); `archived` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `ModelPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.
:::

#### API-11-002 · Chi tiết mô hình

::: dac-ta
**Mục đích.** Chi tiết mô hình.

**Phương thức, đường dẫn.** `GET /models/{processKey}`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-001.

**Tham số.** `processKey` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `ModelDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi: ERR-11-003, ERR-11-001.
:::

#### API-11-003 · Tạo mô hình

::: dac-ta
**Mục đích.** Tạo mô hình.

**Phương thức, đường dẫn.** `POST /models`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-002.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ModelCreate`; trường bắt buộc: `processKey`, `name`, `group`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `ModelCreated`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006.
:::

#### API-11-004 · Nhập mô hình từ tệp BPMN

::: dac-ta
**Mục đích.** Nhập mô hình từ tệp BPMN.

**Phương thức, đường dẫn.** `POST /models:import`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-002, FR-11-010.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `ModelImportRequest`; trường bắt buộc: `file`, `processKey`, `name`, `group`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `ModelImported`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `413`, `422`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006, ERR-11-008, ERR-11-009, ERR-11-011, ERR-11-027.

**Ghi chú.** Tệp BPMN 2.0 XML hoặc gói; phần tử ngoài bảng 6.2-a bị gỡ và nêu trong `report`. Quá `11.model.maxXmlKb`: ERR-11-009.
:::

#### API-11-005 · Sửa thuộc tính mô hình

::: dac-ta
**Mục đích.** Sửa thuộc tính mô hình.

**Phương thức, đường dẫn.** `PATCH /models/{processKey}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-002.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ModelUpdate`.

**Phản hồi thành công.** `200`, `ModelDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006, ERR-11-004, ERR-11-001.
:::

#### API-11-006 · Lưu trữ mô hình

::: dac-ta
**Mục đích.** Lưu trữ mô hình.

**Phương thức, đường dẫn.** `POST /models/{processKey}:archive`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-009.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `ModelDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-037, ERR-11-038, ERR-11-003, ERR-11-004, ERR-11-001.
:::

### Phiên bản và thiết kế

#### API-11-007 · Danh sách phiên bản mô hình

::: dac-ta
**Mục đích.** Danh sách phiên bản mô hình.

**Phương thức, đường dẫn.** `GET /models/{processKey}/versions`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-006.

**Tham số.** `processKey` (path, string, bắt buộc); `status` (query, VersionStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `VersionPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-001, ERR-11-006, ERR-11-003.
:::

#### API-11-008 · Tạo phiên bản nháp

::: dac-ta
**Mục đích.** Tạo phiên bản nháp.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-006.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `processKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `VersionCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `VersionDetail`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-001, ERR-11-006, ERR-11-003.
:::

#### API-11-009 · Chi tiết phiên bản và BPMN XML

::: dac-ta
**Mục đích.** Chi tiết phiên bản và BPMN XML.

**Phương thức, đường dẫn.** `GET /models/{processKey}/versions/{version}`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-003, FR-11-006.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Phản hồi thành công.** `200`, `VersionDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016, ERR-11-001, ERR-11-006.
:::

#### API-11-010 · Lưu sơ đồ BPMN của bản nháp

::: dac-ta
**Mục đích.** Lưu sơ đồ BPMN của bản nháp.

**Phương thức, đường dẫn.** `PUT /models/{processKey}/versions/{version}/bpmn`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-003.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `BpmnPut`; trường bắt buộc: `bpmnXml`.

**Phản hồi thành công.** `200`, `BpmnSaved`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `428`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016, ERR-11-003, ERR-11-001.

**Ghi chú.** `If-Match` theo `ETag` của phiên bản; chỉ người giữ khóa soạn thảo được lưu (ERR-11-016). Giao diện tự lưu mỗi `11.designer.autosaveSeconds` giây (30). Mỗi lần lưu chạy kiểm tra tĩnh nhanh.
:::

#### API-11-011 · Cấu hình thuộc tính một phần tử

::: dac-ta
**Mục đích.** Cấu hình thuộc tính một phần tử.

**Phương thức, đường dẫn.** `PUT /models/{processKey}/versions/{version}/elements/{elementId}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-004.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `elementId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ElementConfig`; trường bắt buộc: `stepType`.

**Phản hồi thành công.** `200`, `ElementSaved`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-011, ERR-11-014, ERR-11-015, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-012 · Khóa soạn thảo bản nháp

::: dac-ta
**Mục đích.** Khóa soạn thảo bản nháp.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:lock`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-003.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Phản hồi thành công.** `200`, `LockResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016, ERR-11-001.

**Ghi chú.** Khóa hết hạn sau `11.designer.lockMinutes` phút không thao tác; người khác khóa trả ERR-11-016 kèm tên người giữ.
:::

#### API-11-013 · Mở khóa soạn thảo bản nháp

::: dac-ta
**Mục đích.** Mở khóa soạn thảo bản nháp.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:unlock`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-003.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Phản hồi thành công.** `200`, `LockResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016, ERR-11-001.
:::

#### API-11-014 · Kiểm tra tĩnh phiên bản

::: dac-ta
**Mục đích.** Kiểm tra tĩnh phiên bản.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:validate`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-005.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `ValidateRequest`.

**Phản hồi thành công.** `200`, `ValidationReport`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi: ERR-11-012, ERR-11-010, ERR-11-013, ERR-11-003, ERR-11-001.

**Ghi chú.** `QUICK` chỉ phần tử đổi; `FULL` kiểm thêm ánh xạ ý định sang luồng PH-04 trên `targetEnvironment` và bù trừ. Có lỗi `ERROR` thì `blocking = true`.
:::

#### API-11-015 · So sánh hai phiên bản

::: dac-ta
**Mục đích.** So sánh hai phiên bản.

**Phương thức, đường dẫn.** `GET /models/{processKey}/versions/{version}/diff`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-006.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `with` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `VersionDiff`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi: ERR-11-001, ERR-11-006.
:::

#### API-11-024 · Xuất tệp BPMN hoặc gói quy trình

::: dac-ta
**Mục đích.** Xuất tệp BPMN hoặc gói quy trình.

**Phương thức, đường dẫn.** `GET /models/{processKey}/versions/{version}/export`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-010.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `format` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, string.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `413`, `422`; mã lỗi: ERR-11-008, ERR-11-009, ERR-11-011, ERR-11-027, ERR-11-001.

**Ghi chú.** `format` là `bpmn` (mặc định) hoặc `package`; trả `Content-Disposition` kèm tên tệp.
:::

#### API-11-028 · Danh mục phần tử BPMN hỗ trợ

::: dac-ta
**Mục đích.** Danh mục phần tử BPMN hỗ trợ.

**Phương thức, đường dẫn.** `GET /element-catalog`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-003.

**Tham số.** Không.

**Phản hồi thành công.** `200`, `ElementCatalog`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `413`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016.
:::

#### API-11-136 · Yêu cầu quyền sửa bản nháp

::: dac-ta
**Mục đích.** Yêu cầu quyền sửa bản nháp.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:request-lock`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-003.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `LockRequestBody`.

**Phản hồi thành công.** `200`, `LockRequestResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`; mã lỗi: ERR-11-004, ERR-11-008, ERR-11-009, ERR-11-016, ERR-11-003, ERR-11-001.

**Ghi chú.** Gửi thông báo (EVT-11-20) cho người giữ khóa; không tự nhả khóa. Người giữ khóa là chính người gọi: ERR-11-006.
:::

### Duyệt phát hành

#### API-11-016 · Gửi duyệt phát hành

::: dac-ta
**Mục đích.** Gửi duyệt phát hành.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:submit`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-007.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `PublishSubmit`; trường bắt buộc: `releaseNote`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `PublishRequestAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-010, ERR-11-024, ERR-11-013, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Chuyển phiên bản sang `IN_REVIEW`, tạo việc duyệt `PUBLISH_REVIEW`; kiểm tra tĩnh `FULL` phải không còn lỗi `ERROR` (ERR-11-010).
:::

#### API-11-017 · Rút lại đề nghị phát hành

::: dac-ta
**Mục đích.** Rút lại đề nghị phát hành.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:withdraw`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-007.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `200`, `PublishRequest`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-010, ERR-11-024, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-018 · Danh sách đề nghị phát hành

::: dac-ta
**Mục đích.** Danh sách đề nghị phát hành.

**Phương thức, đường dẫn.** `GET /publish-requests`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-008.

**Tham số.** `status` (query, PublishRequestStatus, tùy chọn); `processKey` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `PublishRequestPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi: ERR-11-004, ERR-11-005, ERR-11-007, ERR-11-046, ERR-11-003.
:::

#### API-11-019 · Chi tiết đề nghị phát hành

::: dac-ta
**Mục đích.** Chi tiết đề nghị phát hành.

**Phương thức, đường dẫn.** `GET /publish-requests/{id}`.

**Quyền.** `PERM-11-publish hoặc PERM-11-read`.

**FR hiện thực.** FR-11-008.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `PublishRequest`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi: ERR-11-004, ERR-11-005, ERR-11-007, ERR-11-046, ERR-11-001.
:::

#### API-11-020 · Duyệt phát hành và triển khai

::: dac-ta
**Mục đích.** Duyệt phát hành và triển khai.

**Phương thức, đường dẫn.** `POST /publish-requests/{id}:approve`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-008, FR-11-014.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `PublishApprove`.

**Phản hồi thành công.** `200`, `PublishDecisionResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `503`; mã lỗi: ERR-11-004, ERR-11-005, ERR-11-007, ERR-11-046, ERR-11-044, ERR-11-010, ERR-11-003, ERR-11-001.

**Ghi chú.** Bốn mắt: người duyệt khác người gửi (ERR-11-005). Hệ thống triển khai lên engine Flowable; lỗi triển khai đưa đề nghị về `DEPLOY_FAILED` (ERR-11-046). `waiverDecisions[]` quyết định từng miễn bù trừ `NONE_APPROVED` của đề nghị; đề nghị `RESTORE` (API-11-131) duyệt cũng qua operation này, không triển khai lại.
:::

#### API-11-021 · Từ chối phát hành

::: dac-ta
**Mục đích.** Từ chối phát hành.

**Phương thức, đường dẫn.** `POST /publish-requests/{id}:reject`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-008.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `PublishDecisionResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `503`; mã lỗi: ERR-11-004, ERR-11-005, ERR-11-007, ERR-11-046, ERR-11-003, ERR-11-001.
:::

#### API-11-022 · Ngừng dùng phiên bản

::: dac-ta
**Mục đích.** Ngừng dùng phiên bản.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:deprecate`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-009.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `DeprecateBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `VersionStatusResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-037, ERR-11-038, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** `DEPRECATED`: không khởi tạo phiên mới, phiên đang chạy chạy tiếp. Phiên bản `PUBLISHED` duy nhất cần `confirmSolePublished = true` (ERR-11-038).
:::

#### API-11-023 · Thu hồi phiên bản

::: dac-ta
**Mục đích.** Thu hồi phiên bản.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:retire`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-009.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `DeprecateBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `VersionStatusResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-037, ERR-11-038, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** `RETIRED`: còn phiên chạy hoặc tham chiếu thì ERR-11-037; cần bốn mắt.
:::

#### API-11-131 · Đề nghị khôi phục phiên bản ngừng dùng

::: dac-ta
**Mục đích.** Đề nghị khôi phục phiên bản ngừng dùng.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}:restore`.

**Quyền.** `PERM-11-publish`.

**FR hiện thực.** FR-11-009.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `PublishRequestAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-037, ERR-11-038, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Chỉ bản `DEPRECATED` khi mô hình không còn bản `PUBLISHED` (ERR-11-006). Tạo đề nghị `kind = RESTORE`; người khác duyệt bằng API-11-020 (ERR-11-005), bản về `PUBLISHED`, không triển khai lại.
:::

### Chạy thử

#### API-11-025 · Tạo phiên chạy thử

::: dac-ta
**Mục đích.** Tạo phiên chạy thử.

**Phương thức, đường dẫn.** `POST /models/{processKey}/versions/{version}/test-runs`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-011.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `TestRunCreate`; trường bắt buộc: `scenario`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `TestRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`; mã lỗi: ERR-11-001, ERR-11-010, ERR-11-042, ERR-11-003.
:::

#### API-11-026 · Chi tiết phiên chạy thử

::: dac-ta
**Mục đích.** Chi tiết phiên chạy thử.

**Phương thức, đường dẫn.** `GET /test-runs/{id}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-011.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `TestRun`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `422`; mã lỗi: ERR-11-001, ERR-11-010, ERR-11-042.
:::

#### API-11-027 · Chạy bước tiếp của phiên chạy thử

::: dac-ta
**Mục đích.** Chạy bước tiếp của phiên chạy thử.

**Phương thức, đường dẫn.** `POST /test-runs/{id}:step`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-011.

**Tham số.** `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TestStepBody`.

**Phản hồi thành công.** `200`, `TestRun`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `410`, `422`; mã lỗi: ERR-11-001, ERR-11-010, ERR-11-042, ERR-11-003.
:::

### Biểu mẫu, ý định, bù trừ

#### API-11-029 · Danh sách biểu mẫu

::: dac-ta
**Mục đích.** Danh sách biểu mẫu.

**Phương thức, đường dẫn.** `GET /forms`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-012.

**Tham số.** `status` (query, ResourceStatus, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `FormPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006.
:::

#### API-11-030 · Tạo biểu mẫu

::: dac-ta
**Mục đích.** Tạo biểu mẫu.

**Phương thức, đường dẫn.** `POST /forms`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FormCreate`; trường bắt buộc: `formKey`, `name`, `schema`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `FormDetail`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006.
:::

#### API-11-031 · Chi tiết biểu mẫu

::: dac-ta
**Mục đích.** Chi tiết biểu mẫu.

**Phương thức, đường dẫn.** `GET /forms/{formKey}`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-012.

**Tham số.** `formKey` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `FormDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006, ERR-11-001.
:::

#### API-11-032 · Lưu phiên bản biểu mẫu

::: dac-ta
**Mục đích.** Lưu phiên bản biểu mẫu.

**Phương thức, đường dẫn.** `PUT /forms/{formKey}/versions/{version}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-012.

**Tham số.** `If-Match` (header, string, bắt buộc); `formKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `FormVersionPut`; trường bắt buộc: `schema`.

**Phản hồi thành công.** `200`, `FormVersion`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006, ERR-11-015, ERR-11-004, ERR-11-001.
:::

#### API-11-033 · Phát hành phiên bản biểu mẫu

::: dac-ta
**Mục đích.** Phát hành phiên bản biểu mẫu.

**Phương thức, đường dẫn.** `POST /forms/{formKey}/versions/{version}:publish`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-012.

**Tham số.** `If-Match` (header, string, bắt buộc); `formKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Phản hồi thành công.** `200`, `FormVersion`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-002, ERR-11-003, ERR-11-006, ERR-11-004, ERR-11-001.
:::

#### API-11-034 · Danh sách ý định nghiệp vụ

::: dac-ta
**Mục đích.** Danh sách ý định nghiệp vụ.

**Phương thức, đường dẫn.** `GET /intents`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-013.

**Tham số.** `status` (query, ResourceStatus, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `IntentPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-003, ERR-11-012.
:::

#### API-11-035 · Đăng ký ý định nghiệp vụ

::: dac-ta
**Mục đích.** Đăng ký ý định nghiệp vụ.

**Phương thức, đường dẫn.** `POST /intents`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-013.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IntentUpsert`; trường bắt buộc: `intentCode`, `name`, `writesExternal`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `Intent`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-003, ERR-11-012.
:::

#### API-11-036 · Sửa ý định và ánh xạ luồng

::: dac-ta
**Mục đích.** Sửa ý định và ánh xạ luồng.

**Phương thức, đường dẫn.** `PUT /intents/{intentCode}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-013.

**Tham số.** `If-Match` (header, string, bắt buộc); `intentCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `IntentUpsert`; trường bắt buộc: `intentCode`, `name`, `writesExternal`.

**Phản hồi thành công.** `200`, `Intent`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-003, ERR-11-012, ERR-11-004, ERR-11-001.
:::

#### API-11-037 · Ngừng dùng ý định

::: dac-ta
**Mục đích.** Ngừng dùng ý định.

**Phương thức, đường dẫn.** `POST /intents/{intentCode}:deprecate`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-013.

**Tham số.** `If-Match` (header, string, bắt buộc); `intentCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `Intent`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-003, ERR-11-012, ERR-11-004, ERR-11-001.
:::

#### API-11-038 · Ánh xạ ý định sang luồng PH-04

::: dac-ta
**Mục đích.** Ánh xạ ý định sang luồng PH-04.

**Phương thức, đường dẫn.** `GET /intents/{intentCode}/bindings`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-013.

**Tham số.** `intentCode` (path, string, bắt buộc); `environment` (query, Environment, tùy chọn).

**Phản hồi thành công.** `200`, `IntentBindingList`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi: ERR-11-003, ERR-11-012, ERR-11-001.
:::

#### API-11-039 · Danh sách hành động bù trừ

::: dac-ta
**Mục đích.** Danh sách hành động bù trừ.

**Phương thức, đường dẫn.** `GET /compensations`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-014.

**Tham số.** `processKey` (query, string, tùy chọn); `version` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `CompensationList`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi: ERR-11-007, ERR-11-044.
:::

#### API-11-040 · Lưu hành động bù trừ của phiên bản

::: dac-ta
**Mục đích.** Lưu hành động bù trừ của phiên bản.

**Phương thức, đường dẫn.** `PUT /models/{processKey}/versions/{version}/compensations`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-014.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CompensationPut`; trường bắt buộc: `items`.

**Phản hồi thành công.** `200`, `CompensationList`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-044, ERR-11-003, ERR-11-004, ERR-11-001.
:::

### Mẫu, biến, bảng quyết định

#### API-11-041 · Danh sách mẫu quy trình

::: dac-ta
**Mục đích.** Danh sách mẫu quy trình.

**Phương thức, đường dẫn.** `GET /templates`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-015.

**Tham số.** `status` (query, ResourceStatus, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `TemplatePage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-005, ERR-11-036, ERR-11-003.
:::

#### API-11-042 · Tạo mẫu quy trình

::: dac-ta
**Mục đích.** Tạo mẫu quy trình.

**Phương thức, đường dẫn.** `POST /templates`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-015.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateCreate`; trường bắt buộc: `templateCode`, `name`, `sourceXml`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `Template`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-005, ERR-11-036, ERR-11-003.
:::

#### API-11-043 · Phát hành mẫu quy trình

::: dac-ta
**Mục đích.** Phát hành mẫu quy trình.

**Phương thức, đường dẫn.** `POST /templates/{templateCode}:publish`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-015.

**Tham số.** `If-Match` (header, string, bắt buộc); `templateCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `200`, `Template`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-005, ERR-11-036, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Bốn mắt: người phát hành khác người soạn mẫu; mẫu `COMMON` chỉ PA sửa (ERR-11-036). Ghi chú quyền theo FRS 9.4: người khác.
:::

#### API-11-044 · Danh sách biến của phiên bản

::: dac-ta
**Mục đích.** Danh sách biến của phiên bản.

**Phương thức, đường dẫn.** `GET /models/{processKey}/versions/{version}/variables`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-016.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Phản hồi thành công.** `200`, `VariableList`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi: ERR-11-003, ERR-11-015, ERR-11-001.
:::

#### API-11-045 · Lưu biến của phiên bản

::: dac-ta
**Mục đích.** Lưu biến của phiên bản.

**Phương thức, đường dẫn.** `PUT /models/{processKey}/versions/{version}/variables`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-016.

**Tham số.** `If-Match` (header, string, bắt buộc); `processKey` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `VariablePut`; trường bắt buộc: `variables`.

**Phản hồi thành công.** `200`, `VariableList`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-003, ERR-11-015, ERR-11-004, ERR-11-001.
:::

#### API-11-046 · Danh sách bảng quyết định

::: dac-ta
**Mục đích.** Danh sách bảng quyết định.

**Phương thức, đường dẫn.** `GET /decision-tables`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-017.

**Tham số.** `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `DecisionTablePage`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-040, ERR-11-003.
:::

#### API-11-047 · Lưu bảng quyết định

::: dac-ta
**Mục đích.** Lưu bảng quyết định.

**Phương thức, đường dẫn.** `PUT /decision-tables/{code}`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-017.

**Tham số.** `If-Match` (header, string, bắt buộc); `code` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionTablePut`; trường bắt buộc: `name`, `hitPolicy`, `inputs`, `outputs`, `rules`.

**Phản hồi thành công.** `200`, `DecisionTable`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-040, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-048 · Thử bảng quyết định

::: dac-ta
**Mục đích.** Thử bảng quyết định.

**Phương thức, đường dẫn.** `POST /decision-tables/{code}:evaluate`.

**Quyền.** `PERM-11-model`.

**FR hiện thực.** FR-11-017.

**Tham số.** `code` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionEvalRequest`; trường bắt buộc: `inputs`.

**Phản hồi thành công.** `200`, `DecisionEvalResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi: ERR-11-040, ERR-11-003, ERR-11-001.
:::

### Khởi tạo và tra cứu phiên

#### API-11-049 · Khởi tạo phiên

::: dac-ta
**Mục đích.** Khởi tạo phiên.

**Phương thức, đường dẫn.** `POST /instances`.

**Quyền.** `PERM-11-instance hoặc scope bpm.instance.start`.

**FR hiện thực.** FR-11-018, FR-11-020.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InstanceStart`; trường bắt buộc: `processKey`, `businessKey`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `InstanceStarted`; tiêu đề `Location`; `200`, `InstanceStarted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi: ERR-11-017, ERR-11-018, ERR-11-019, ERR-11-020, ERR-11-041, ERR-11-046, ERR-11-051, ERR-11-003.

**Ghi chú.** Gửi lại cùng `businessKey` và cùng nội dung trả `200` kèm phiên cũ; khác nội dung trả ERR-11-018. `Idempotency-Key` dùng lại trong 24 giờ trả đúng phản hồi lần đầu. Biến `SENSITIVE` được mã hóa, không ghi vào nhật ký.
:::

#### API-11-050 · Danh sách, tìm kiếm phiên

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm phiên.

**Phương thức, đường dẫn.** `GET /instances`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-021.

**Tham số.** `processKey` (query, string, tùy chọn); `businessKey` (query, string, tùy chọn); `status` (query, InstanceStatus, tùy chọn); `waitState` (query, WaitState, tùy chọn); `dueStatus` (query, DueStatus, tùy chọn); `startChannel` (query, StartChannel, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `hasIncident` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `InstancePage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.
:::

#### API-11-051 · Chi tiết phiên

::: dac-ta
**Mục đích.** Chi tiết phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}`.

**Quyền.** `PERM-11-read hoặc scope bpm.instance.read`.

**FR hiện thực.** FR-11-022.

**Tham số.** `instanceId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `InstanceDetail`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`; mã lỗi: ERR-11-001, ERR-11-034.

**Ghi chú.** Biến không có trong phản hồi; lấy qua API-11-055. Cán bộ xử lý chỉ xem phiên có việc của mình hoặc đơn vị mình (ERR-11-034).
:::

#### API-11-052 · Tra phiên theo mã hồ sơ

::: dac-ta
**Mục đích.** Tra phiên theo mã hồ sơ.

**Phương thức, đường dẫn.** `GET /instances:by-key`.

**Quyền.** `PERM-11-read hoặc scope bpm.instance.read`.

**FR hiện thực.** FR-11-018, FR-11-022.

**Tham số.** `processKey` (query, string, bắt buộc); `businessKey` (query, string, bắt buộc).

**Phản hồi thành công.** `200`, `InstanceDetail`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi: ERR-11-017, ERR-11-018, ERR-11-019, ERR-11-020, ERR-11-041, ERR-11-046, ERR-11-051, ERR-11-001, ERR-11-034.

**Ghi chú.** Dùng khi hệ gọi chỉ giữ `businessKey` (mã hồ sơ). Client chỉ thấy phiên do mình khởi tạo (scope `bpm.instance.read`).
:::

#### API-11-053 · Dòng thời gian bước của phiên

::: dac-ta
**Mục đích.** Dòng thời gian bước của phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}/timeline`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-022.

**Tham số.** `instanceId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `Timeline`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi: ERR-11-001, ERR-11-034, ERR-11-003.
:::

#### API-11-054 · Sơ đồ tiến độ của phiên

::: dac-ta
**Mục đích.** Sơ đồ tiến độ của phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}/diagram`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-022.

**Tham số.** `instanceId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `Diagram`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi: ERR-11-001, ERR-11-034.
:::

#### API-11-055 · Biến của phiên

::: dac-ta
**Mục đích.** Biến của phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}/variables`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-022.

**Tham số.** `instanceId` (path, string, bắt buộc); `unmask` (query, boolean, tùy chọn); `X-Unmask-Reason` (header, string, tùy chọn).

**Phản hồi thành công.** `200`, `VariableValues`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi: ERR-11-001, ERR-11-034.

**Ghi chú.** Giá trị biến `SENSITIVE` luôn che; xem đầy đủ cần `PERM-09-unmask`, `unmask=true` và tiêu đề `X-Unmask-Reason`, có ghi nhật ký truy cập; giao diện che lại sau `11.task.unmaskSeconds` giây (60). Ghi chú quyền theo FRS 9.4: + `PERM-09-unmask`.
:::

#### API-11-126 · Danh sách liên kết sự kiện khởi tạo

::: dac-ta
**Mục đích.** Danh sách liên kết sự kiện khởi tạo.

**Phương thức, đường dẫn.** `GET /event-start-bindings`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-019.

**Tham số.** `processKey` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `EventStartBindingPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.

**Ghi chú.** Liên kết sự kiện PH-10 đang bật; sửa ở PH-10, PH-11 chỉ đọc.
:::

#### API-11-127 · Biểu mẫu khởi tạo thủ công

::: dac-ta
**Mục đích.** Biểu mẫu khởi tạo thủ công.

**Phương thức, đường dẫn.** `GET /models/{processKey}/start-form`.

**Quyền.** `PERM-11-instance`.

**FR hiện thực.** FR-11-020.

**Tham số.** `processKey` (path, string, bắt buộc); `version` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `StartForm`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-018, ERR-11-020, ERR-11-019, ERR-11-001.

**Ghi chú.** Dùng cho khởi tạo thủ công trên giao diện (FR-11-020); client máy dùng API-11-049.
:::

#### API-11-128 · Xuất danh sách phiên ra CSV

::: dac-ta
**Mục đích.** Xuất danh sách phiên ra CSV.

**Phương thức, đường dẫn.** `POST /instances:export`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-021.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InstanceExportRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ExportAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-003, ERR-11-039.

**Ghi chú.** Bộ lọc như API-11-050, tối đa 50.000 dòng; tạo tác vụ nền (`202`), tải qua liên kết có hạn. Khoảng thời gian quá 366 ngày: ERR-11-039.
:::

### Điều khiển phiên

#### API-11-056 · Tạm dừng phiên

::: dac-ta
**Mục đích.** Tạm dừng phiên.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}:suspend`.

**Quyền.** `PERM-11-instance hoặc scope bpm.instance.start`.

**FR hiện thực.** FR-11-023.

**Tham số.** `If-Match` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SuspendBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `InstanceStateResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-006, ERR-11-030, ERR-11-007, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** `pauseDue = true` chỉ khi lý do pháp lý (`LEGAL_SUSPENSION`) và tạm dừng đồng hồ hạn. Phiên đang bù trừ: ERR-11-030.
:::

#### API-11-057 · Tiếp tục phiên

::: dac-ta
**Mục đích.** Tiếp tục phiên.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}:resume`.

**Quyền.** `PERM-11-instance hoặc scope bpm.instance.start`.

**FR hiện thực.** FR-11-023.

**Tham số.** `If-Match` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `InstanceStateResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-006, ERR-11-030, ERR-11-007, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-058 · Hủy phiên

::: dac-ta
**Mục đích.** Hủy phiên.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}:cancel`.

**Quyền.** `PERM-11-instance hoặc scope bpm.instance.start`.

**FR hiện thực.** FR-11-024.

**Tham số.** `If-Match` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `InstanceCancelResult`; `202`, `InstanceCancelResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-006, ERR-11-007, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** `compensate = AUTO` chạy Saga theo bù trừ đã đăng ký: `202` kèm `sagaId`; `NONE` hủy ngay `200`. Hồ sơ giữ pháp lý: ERR-11-047.
:::

#### API-11-059 · Đề nghị sửa biến hoặc chuyển bước

::: dac-ta
**Mục đích.** Đề nghị sửa biến hoặc chuyển bước.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}/changes`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-025, FR-11-027.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `InstanceChangeCreate`; trường bắt buộc: `type`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `InstanceChangeAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-005, ERR-11-033, ERR-11-030, ERR-11-032, ERR-11-003, ERR-11-001.

**Ghi chú.** Bốn mắt: người đề nghị khác người duyệt (API-11-061). `type = VARIABLE_UPDATE` chỉ biến có `editableBy`; `MOVE_TOKEN` cần `targetElementId` hợp lệ (ERR-11-032, 033).
:::

#### API-11-060 · Chi tiết đề nghị thay đổi phiên

::: dac-ta
**Mục đích.** Chi tiết đề nghị thay đổi phiên.

**Phương thức, đường dẫn.** `GET /instance-changes/{id}`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-025, FR-11-027.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `InstanceChange`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-005, ERR-11-033, ERR-11-030, ERR-11-032, ERR-11-001.
:::

#### API-11-061 · Duyệt đề nghị thay đổi phiên

::: dac-ta
**Mục đích.** Duyệt đề nghị thay đổi phiên.

**Phương thức, đường dẫn.** `POST /instance-changes/{id}:approve`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-025, FR-11-027.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `200`, `InstanceChange`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-005, ERR-11-033, ERR-11-030, ERR-11-032, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Bốn mắt (ERR-11-005): người duyệt khác người đề nghị; duyệt xong thay đổi được áp ngay và ghi kiểm toán.
:::

#### API-11-062 · Từ chối đề nghị thay đổi phiên

::: dac-ta
**Mục đích.** Từ chối đề nghị thay đổi phiên.

**Phương thức, đường dẫn.** `POST /instance-changes/{id}:reject`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-025, FR-11-027.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `InstanceChange`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-005, ERR-11-033, ERR-11-030, ERR-11-032, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-063 · Tạo kế hoạch di trú

::: dac-ta
**Mục đích.** Tạo kế hoạch di trú.

**Phương thức, đường dẫn.** `POST /migration-plans`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationPlanCreate`; trường bắt buộc: `processKey`, `fromVersion`, `toVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `MigrationPlan`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-031, ERR-11-003.
:::

#### API-11-064 · Kiểm tra kế hoạch di trú

::: dac-ta
**Mục đích.** Kiểm tra kế hoạch di trú.

**Phương thức, đường dẫn.** `POST /migration-plans/{id}:validate`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `MigrationPlan`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi: ERR-11-031, ERR-11-001.

**Ghi chú.** Kiểm tra mọi bước đang chờ đã ánh xạ sang phiên bản đích (ERR-11-031); không đổi dữ liệu phiên.
:::

#### API-11-065 · Gửi duyệt kế hoạch di trú

::: dac-ta
**Mục đích.** Gửi duyệt kế hoạch di trú.

**Phương thức, đường dẫn.** `POST /migration-plans/{id}:submit`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `200`, `MigrationPlan`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-031, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-066 · Duyệt và chạy di trú

::: dac-ta
**Mục đích.** Duyệt và chạy di trú.

**Phương thức, đường dẫn.** `POST /migration-plans/{id}:approve`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `202`, `MigrationPlan`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-031, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Bốn mắt; di trú theo lô `11.migration.batchSize` phiên, bất đồng bộ (`202`); phiên lỗi ghi sự cố ERR-11-119.
:::

#### API-11-067 · Từ chối kế hoạch di trú

::: dac-ta
**Mục đích.** Từ chối kế hoạch di trú.

**Phương thức, đường dẫn.** `POST /migration-plans/{id}:reject`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `MigrationPlan`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-031, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-068 · Chi tiết kế hoạch di trú

::: dac-ta
**Mục đích.** Chi tiết kế hoạch di trú.

**Phương thức, đường dẫn.** `GET /migration-plans/{id}`.

**Quyền.** `PERM-11-instance-admin`.

**FR hiện thực.** FR-11-026.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `MigrationPlan`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi: ERR-11-031, ERR-11-001.
:::

### Service task và thông điệp

#### API-11-069 · Gửi thông điệp tương quan vào phiên

::: dac-ta
**Mục đích.** Gửi thông điệp tương quan vào phiên.

**Phương thức, đường dẫn.** `POST /messages`.

**Quyền.** scope bpm.instance.start.

**FR hiện thực.** FR-11-030.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MessageCorrelate`; trường bắt buộc: `messageName`, `businessKey`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `MessageResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-049, ERR-11-019, ERR-11-003.

**Ghi chú.** Tương quan theo (`messageName`, `businessKey`). Thông điệp đến sớm được đệm `11.message.bufferMinutes` phút; không có phiên chờ: ERR-11-049.
:::

#### API-11-070 · Danh sách lệnh service task của phiên

::: dac-ta
**Mục đích.** Danh sách lệnh service task của phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}/service-calls`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-022, FR-11-028, FR-11-029.

**Tham số.** `instanceId` (path, string, bắt buộc); `status` (query, ServiceCallStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `ServiceCallPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-001, ERR-11-034, ERR-11-006, ERR-11-003.
:::

#### API-11-071 · Gửi lại lệnh service task

::: dac-ta
**Mục đích.** Gửi lại lệnh service task.

**Phương thức, đường dẫn.** `POST /service-calls/{commandId}:resend`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-028.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `commandId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResendBody`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ResendAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-006, ERR-11-003, ERR-11-001.

**Ghi chú.** Chỉ cho lệnh `FAILED` hoặc `TIMED_OUT`; dùng lại `commandId` cũ để PH-04 chống trùng, tăng `attempt`.
:::

#### API-11-089 · Báo hồ sơ đã bổ sung

::: dac-ta
**Mục đích.** Báo hồ sơ đã bổ sung.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}:supplement-received`.

**Quyền.** scope bpm.instance.start.

**FR hiện thực.** FR-11-044, FR-11-049.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SupplementReceived`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `SupplementAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-007, ERR-11-026, ERR-11-049, ERR-11-003, ERR-11-001.

**Ghi chú.** Gỡ trạng thái `WAITING_SUPPLEMENT`, tiếp tục đồng hồ hạn (hoặc tính lại theo `11.supplement.resetDue`); phiên không chờ bổ sung: ERR-11-049.
:::

### Việc của người dùng

#### API-11-072 · Danh sách việc

::: dac-ta
**Mục đích.** Danh sách việc.

**Phương thức, đường dẫn.** `GET /tasks`.

**Quyền.** `PERM-11-task hoặc scope bpm.task.read`.

**FR hiện thực.** FR-11-034, FR-11-035.

**Tham số.** `view` (query, string, tùy chọn); `status` (query, TaskStatus, tùy chọn); `kind` (query, TaskKind, tùy chọn); `processKey` (query, string, tùy chọn); `dueStatus` (query, DueStatus, tùy chọn); `assignee` (query, string, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `TaskPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.

**Ghi chú.** `view`: `mine` (của tôi), `candidate` (nhóm, đơn vị của tôi), `unit`, `all` (chỉ `PERM-11-task-admin`). Scope `bpm.task.read` đọc việc của đơn vị, không có biến `SENSITIVE`.
:::

#### API-11-073 · Chi tiết việc

::: dac-ta
**Mục đích.** Chi tiết việc.

**Phương thức, đường dẫn.** `GET /tasks/{taskId}`.

**Quyền.** `PERM-11-task hoặc PERM-11-read`.

**FR hiện thực.** FR-11-037.

**Tham số.** `taskId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `TaskDetail`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi: ERR-11-022, ERR-11-001.
:::

#### API-11-074 · Nhận việc

::: dac-ta
**Mục đích.** Nhận việc.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:claim`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-036.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `TaskAssignResult`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-021, ERR-11-022, ERR-11-004, ERR-11-001.

**Ghi chú.** Nhận việc nguyên tử: người đến sau gặp ERR-11-021 kèm tên người nhận và giờ nhận.
:::

#### API-11-075 · Trả lại việc

::: dac-ta
**Mục đích.** Trả lại việc.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:unclaim`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-036.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `TaskAssignResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-021, ERR-11-022, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-076 · Hoàn thành việc

::: dac-ta
**Mục đích.** Hoàn thành việc.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:complete`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-038.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskComplete`; trường bắt buộc: `decision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200`, `TaskCompleted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-007, ERR-11-022, ERR-11-023, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** `decision` thuộc `decisions` của biểu mẫu; `comment` từ 20 ký tự khi `REJECT`, `RETURN`, `REQUEST_SUPPLEMENT` (ERR-11-007). Việc duyệt kiểm tách nhiệm vụ `separateFrom` (ERR-11-005).
:::

#### API-11-077 · Lưu nháp kết quả việc

::: dac-ta
**Mục đích.** Lưu nháp kết quả việc.

**Phương thức, đường dẫn.** `PUT /tasks/{taskId}/draft`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-039.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskDraft`; trường bắt buộc: `data`.

**Phản hồi thành công.** `200`, `DraftSaved`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-004, ERR-11-023, ERR-11-003, ERR-11-001.

**Ghi chú.** Nháp không kiểm bắt buộc; trường `SENSITIVE` được mã hóa. Giao diện lưu sau `11.task.draftDebounceSeconds` giây (5) kể từ lần sửa cuối.
:::

#### API-11-078 · Chuyển việc cho người khác

::: dac-ta
**Mục đích.** Chuyển việc cho người khác.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:transfer`.

**Quyền.** `PERM-11-task hoặc PERM-11-task-admin`.

**FR hiện thực.** FR-11-040.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TransferBody`; trường bắt buộc: `toUser`, `reason`.

**Phản hồi thành công.** `200`, `TaskAssignResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-024, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Người chuyển phải còn ở nhóm ứng viên hoặc có quyền `PERM-11-task-admin` (ERR-11-024).
:::

#### API-11-083 · Danh sách ý kiến trên việc

::: dac-ta
**Mục đích.** Danh sách ý kiến trên việc.

**Phương thức, đường dẫn.** `GET /tasks/{taskId}/comments`.

**Quyền.** `PERM-11-task hoặc PERM-11-read`.

**FR hiện thực.** FR-11-043.

**Tham số.** `taskId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `CommentPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `413`, `422`; mã lỗi: ERR-11-027, ERR-11-003, ERR-11-001.
:::

#### API-11-084 · Thêm ý kiến trên việc

::: dac-ta
**Mục đích.** Thêm ý kiến trên việc.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}/comments`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-043.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentCreate`; trường bắt buộc: `text`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `TaskComment`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422`; mã lỗi: ERR-11-027, ERR-11-003, ERR-11-001.
:::

#### API-11-085 · Đính kèm tệp vào việc

::: dac-ta
**Mục đích.** Đính kèm tệp vào việc.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}/attachments`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-043.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `AttachmentUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `TaskAttachment`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422`; mã lỗi: ERR-11-027, ERR-11-003, ERR-11-001.

**Ghi chú.** Quá `11.task.attachmentMaxMb` MB hoặc sai loại: ERR-11-027; tệp được quét mã độc trước khi nhận (`scanStatus`).
:::

#### API-11-086 · Tải tệp đính kèm

::: dac-ta
**Mục đích.** Tải tệp đính kèm.

**Phương thức, đường dẫn.** `GET /tasks/{taskId}/attachments/{attachmentId}`.

**Quyền.** `PERM-11-task hoặc PERM-11-read`.

**FR hiện thực.** FR-11-043.

**Tham số.** `taskId` (path, string, bắt buộc); `attachmentId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, string.

**Lỗi.** HTTP `401`, `403`, `404`, `413`, `422`; mã lỗi: ERR-11-027, ERR-11-001.

**Ghi chú.** Tải qua liên kết có hạn; tệp mang phân loại dữ liệu của lúc tải lên.
:::

#### API-11-087 · Trả về bước trước

::: dac-ta
**Mục đích.** Trả về bước trước.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:return`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-044.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskReturnBody`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `TaskReturned`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-026, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-088 · Yêu cầu bổ sung hồ sơ

::: dac-ta
**Mục đích.** Yêu cầu bổ sung hồ sơ.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}:request-supplement`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-044.

**Tham số.** `If-Match` (header, string, bắt buộc); `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SupplementRequest`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `SupplementRequested`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-007, ERR-11-026, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-124 · Gợi ý xử lý việc bằng AI

::: dac-ta
**Mục đích.** Gợi ý xử lý việc bằng AI.

**Phương thức, đường dẫn.** `POST /tasks/{taskId}/ai-suggestions`.

**Quyền.** `PERM-11-task và PERM-17-use`.

**FR hiện thực.** FR-11-066.

**Tham số.** `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AiSuggestRequest`.

**Phản hồi thành công.** `200`, `AiSuggestions`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi: ERR-11-003, ERR-11-001.

**Ghi chú.** Chỉ gợi ý, cán bộ quyết định; quá `11.ai.timeoutSeconds` giây trả `200` với `suggestions` rỗng (ERR-11-124 chỉ ghi nhật ký). Ghi nhận `ai_assisted` khi hoàn thành việc.
:::

#### API-11-125 · Hộp việc cho Việc của tôi

::: dac-ta
**Mục đích.** Hộp việc cho Việc của tôi.

**Phương thức, đường dẫn.** `GET /inbox-items`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-035.

**Tham số.** `updatedSince` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `InboxItemPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.

**Ghi chú.** Nhà cung cấp việc cho hộp "Việc của tôi" (FR-00-070): chỉ tiêu đề, hạn, đường dẫn; không có giá trị biến.
:::

### Ủy quyền và phân công

#### API-11-079 · Danh sách ủy quyền

::: dac-ta
**Mục đích.** Danh sách ủy quyền.

**Phương thức, đường dẫn.** `GET /delegations`.

**Quyền.** `PERM-11-task`.

**FR hiện thực.** FR-11-041.

**Tham số.** `status` (query, DelegationStatus, tùy chọn); `user` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `DelegationPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-025, ERR-11-003.
:::

#### API-11-080 · Tạo ủy quyền

::: dac-ta
**Mục đích.** Tạo ủy quyền.

**Phương thức, đường dẫn.** `POST /delegations`.

**Quyền.** `PERM-11-task hoặc PERM-11-task-admin`.

**FR hiện thực.** FR-11-041.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DelegationCreate`; trường bắt buộc: `toUser`, `validFrom`, `validTo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `Delegation`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-025, ERR-11-003.
:::

#### API-11-081 · Thu hồi ủy quyền

::: dac-ta
**Mục đích.** Thu hồi ủy quyền.

**Phương thức, đường dẫn.** `POST /delegations/{id}:revoke`.

**Quyền.** `PERM-11-task hoặc PERM-11-task-admin`.

**FR hiện thực.** FR-11-041.

**Tham số.** `If-Match` (header, string, bắt buộc); `id` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `Delegation`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-025, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-082 · Phân công lại hàng loạt

::: dac-ta
**Mục đích.** Phân công lại hàng loạt.

**Phương thức, đường dẫn.** `POST /tasks:bulk-reassign`.

**Quyền.** `PERM-11-task-admin`.

**FR hiện thực.** FR-11-042.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BulkReassign`; trường bắt buộc: `taskIds`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `BulkReassignResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-050, ERR-11-003.

**Ghi chú.** Tối đa `11.task.bulkMax` việc mỗi lần (ERR-11-050); việc không giao lại được nằm ở `skipped`.
:::

### Lịch làm việc và hạn

#### API-11-090 · Xem lịch làm việc

::: dac-ta
**Mục đích.** Xem lịch làm việc.

**Phương thức, đường dẫn.** `GET /calendars`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-045.

**Tham số.** `year` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `CalendarList`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi: ERR-11-028.
:::

#### API-11-091 · Lưu lịch làm việc theo năm

::: dac-ta
**Mục đích.** Lưu lịch làm việc theo năm.

**Phương thức, đường dẫn.** `PUT /calendars/{year}`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-045.

**Tham số.** `If-Match` (header, string, bắt buộc); `year` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CalendarYearPut`; trường bắt buộc: `workDays`, `workHours`.

**Phản hồi thành công.** `200`, `CalendarSaved`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-028, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Sửa lịch năm đã qua hạn tính lại hạn các phiên đang chạy; kết quả nêu `recalculatedDues`.
:::

#### API-11-092 · Nhập lịch làm việc từ tệp

::: dac-ta
**Mục đích.** Nhập lịch làm việc từ tệp.

**Phương thức, đường dẫn.** `POST /calendars/{year}:import`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-045.

**Tham số.** `If-Match` (header, string, bắt buộc); `year` (path, integer, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `CalendarImport`; trường bắt buộc: `file`.

**Phản hồi thành công.** `200`, `CalendarSaved`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi: ERR-11-028, ERR-11-003, ERR-11-004, ERR-11-001.
:::

#### API-11-093 · Tính thử hạn xử lý

::: dac-ta
**Mục đích.** Tính thử hạn xử lý.

**Phương thức, đường dẫn.** `POST /calendars:compute-due`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-046.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DueComputeRequest`; trường bắt buộc: `startAt`, `amount`, `unit`.

**Phản hồi thành công.** `200`, `DueComputed`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.

**Ghi chú.** Tính thử theo lịch tenant, không ghi dữ liệu; `explain[]` nêu ngày bị bỏ qua. Lịch thiếu năm: ERR-11-028.
:::

#### API-11-094 · Báo cáo đúng hạn, trễ hạn

::: dac-ta
**Mục đích.** Báo cáo đúng hạn, trễ hạn.

**Phương thức, đường dẫn.** `GET /reports/due`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-050.

**Tham số.** `groupBy` (query, string, tùy chọn); `processKey` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, `DueReport`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-039, ERR-11-003.
:::

#### API-11-095 · Xuất báo cáo hạn

::: dac-ta
**Mục đích.** Xuất báo cáo hạn.

**Phương thức, đường dẫn.** `POST /reports/due:export`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-050.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DueExportRequest`; trường bắt buộc: `from`, `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ExportAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-039, ERR-11-003.

**Ghi chú.** Khoảng thời gian tối đa theo FRS 8.1 (ERR-11-039); kết quả tải qua liên kết có hạn.
:::

### Saga và bù trừ

#### API-11-096 · Danh sách Saga

::: dac-ta
**Mục đích.** Danh sách Saga.

**Phương thức, đường dẫn.** `GET /sagas`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-052.

**Tham số.** `status` (query, SagaStatus, tùy chọn); `processKey` (query, string, tùy chọn); `businessKey` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `SagaPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.
:::

#### API-11-097 · Chi tiết Saga

::: dac-ta
**Mục đích.** Chi tiết Saga.

**Phương thức, đường dẫn.** `GET /sagas/{sagaId}`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-052.

**Tham số.** `sagaId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `SagaDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi: ERR-11-003, ERR-11-001.
:::

#### API-11-098 · Kích hoạt bù trừ thủ công

::: dac-ta
**Mục đích.** Kích hoạt bù trừ thủ công.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}:compensate`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CompensateRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `SagaAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-006, ERR-11-030, ERR-11-003, ERR-11-001.

**Ghi chú.** Chỉ khi phiên `RUNNING` hoặc `SUSPENDED` (ERR-11-006); trả ERR-11-030 nếu Saga đang chạy.
:::

#### API-11-099 · Thử lại bước bù trừ

::: dac-ta
**Mục đích.** Thử lại bước bù trừ.

**Phương thức, đường dẫn.** `POST /sagas/{sagaId}/steps/{stepId}:retry`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-053.

**Tham số.** `sagaId` (path, string, bắt buộc); `stepId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `SagaStepResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-003, ERR-11-001.

**Ghi chú.** `RETRY`: gửi lại lệnh bù trừ; bước `RUNNING`.
:::

#### API-11-100 · Xác nhận đã xử lý thủ công bước bù trừ

::: dac-ta
**Mục đích.** Xác nhận đã xử lý thủ công bước bù trừ.

**Phương thức, đường dẫn.** `POST /sagas/{sagaId}/steps/{stepId}:resolve-manual`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-053.

**Tham số.** `sagaId` (path, string, bắt buộc); `stepId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ManualResolveBody`; trường bắt buộc: `reason`, `evidence`.

**Phản hồi thành công.** `200`, `SagaStepResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-003, ERR-11-001.

**Ghi chú.** `RESOLVE_MANUAL`: bắt buộc `evidence[]` (tệp theo quy tắc FR-11-043, ERR-11-027); bước thành `DONE`.
:::

#### API-11-101 · Đề nghị bỏ qua bước bù trừ

::: dac-ta
**Mục đích.** Đề nghị bỏ qua bước bù trừ.

**Phương thức, đường dẫn.** `POST /sagas/{sagaId}/steps/{stepId}:skip`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-053.

**Tham số.** `sagaId` (path, string, bắt buộc); `stepId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SkipBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `SkipRequested`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-007, ERR-11-003, ERR-11-001.

**Ghi chú.** Chỉ là đề nghị: bước vẫn `MANUAL`, tạo việc `MANUAL_COMPENSATION` cho TA khác; không truyền người duyệt. Người duyệt dùng API-11-132 hoặc 133; người đề nghị không tự duyệt (ERR-11-005). Ghi kiểm toán, cảnh báo P1 nếu bước ghi dữ liệu ngoài.
:::

#### API-11-102 · Danh sách lượt đối soát bù trừ

::: dac-ta
**Mục đích.** Danh sách lượt đối soát bù trừ.

**Phương thức, đường dẫn.** `GET /reconciliations`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-054.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `ReconciliationPage`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.
:::

#### API-11-103 · Chạy đối soát bù trừ

::: dac-ta
**Mục đích.** Chạy đối soát bù trừ.

**Phương thức, đường dẫn.** `POST /reconciliations`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `Reconciliation`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-003.
:::

#### API-11-129 · Xuất danh sách Saga ra CSV

::: dac-ta
**Mục đích.** Xuất danh sách Saga ra CSV.

**Phương thức, đường dẫn.** `POST /sagas:export`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-052.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SagaExportRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ExportAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-003, ERR-11-039.

**Ghi chú.** Bộ lọc như API-11-096, tối đa 50.000 dòng; tác vụ nền, tệp CSV có checksum.
:::

#### API-11-132 · Duyệt bỏ qua bước bù trừ

::: dac-ta
**Mục đích.** Duyệt bỏ qua bước bù trừ.

**Phương thức, đường dẫn.** `POST /sagas/{sagaId}/steps/{stepId}:approve-skip`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-053.

**Tham số.** `sagaId` (path, string, bắt buộc); `stepId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Phản hồi thành công.** `200`, `SagaStepResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-003, ERR-11-001.

**Ghi chú.** Người duyệt khác người đề nghị (ERR-11-005); bước `MANUAL` thành `SKIPPED`, ghi kiểm toán; hết bước thủ công thì Saga kết thúc theo FR-11-051. Ghi chú quyền theo FRS 9.4: người khác đề nghị.
:::

#### API-11-133 · Từ chối bỏ qua bước bù trừ

::: dac-ta
**Mục đích.** Từ chối bỏ qua bước bù trừ.

**Phương thức, đường dẫn.** `POST /sagas/{sagaId}/steps/{stepId}:reject-skip`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-053.

**Tham số.** `sagaId` (path, string, bắt buộc); `stepId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Phản hồi thành công.** `200`, `SagaStepResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-005, ERR-11-006, ERR-11-003, ERR-11-001.

**Ghi chú.** Từ chối bỏ qua: bước về `MANUAL`; `comment` từ 20 ký tự (ERR-11-007); người đề nghị không tự từ chối (ERR-11-005). Ghi chú quyền theo FRS 9.4: người khác đề nghị.
:::

### Tiến độ và lịch sử

#### API-11-104 · Tiến độ hồ sơ cho kênh DVC

::: dac-ta
**Mục đích.** Tiến độ hồ sơ cho kênh DVC.

**Phương thức, đường dẫn.** `GET /progress/{businessKey}`.

**Quyền.** scope bpm.progress.read.

**FR hiện thực.** FR-11-055.

**Tham số.** `businessKey` (path, string, bắt buộc); `processKey` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, `Progress`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi: ERR-11-035.

**Ghi chú.** Chỉ tiến độ rút gọn: bước có `publicName`, trạng thái công khai, thông điệp theo mẫu; không biến, không tên cán bộ, không lỗi kỹ thuật. Đệm 30 giây (`Cache-Control: max-age=30`). Không có quan hệ client với hồ sơ trả như không tồn tại (ERR-11-035).
:::

#### API-11-105 · Lịch sử bước đầy đủ của phiên

::: dac-ta
**Mục đích.** Lịch sử bước đầy đủ của phiên.

**Phương thức, đường dẫn.** `GET /instances/{instanceId}/history`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-057.

**Tham số.** `instanceId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `HistoryPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `410`; mã lỗi: ERR-11-001, ERR-11-003.

**Ghi chú.** Lịch sử đầy đủ gồm người, quyết định, ý kiến; mỗi lượt đọc ghi nhật ký truy cập.
:::

#### API-11-106 · Xuất lịch sử bước

::: dac-ta
**Mục đích.** Xuất lịch sử bước.

**Phương thức, đường dẫn.** `POST /instances/{instanceId}/history:export`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-057.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `instanceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `HistoryExportRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ExportAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`; mã lỗi: ERR-11-001, ERR-11-003.
:::

#### API-11-123 · Nhật ký kiểm toán phân hệ

::: dac-ta
**Mục đích.** Nhật ký kiểm toán phân hệ.

**Phương thức, đường dẫn.** `GET /audit-logs`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-065.

**Tham số.** `actor` (query, string, tùy chọn); `action` (query, string, tùy chọn); `objectType` (query, string, tùy chọn); `objectId` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `AuditLogPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-003, ERR-11-039.
:::

#### API-11-130 · Xuất nhật ký kiểm toán ra CSV

::: dac-ta
**Mục đích.** Xuất nhật ký kiểm toán ra CSV.

**Phương thức, đường dẫn.** `POST /audit-logs:export`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-065.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AuditLogExportRequest`; trường bắt buộc: `from`, `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `ExportAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-003, ERR-11-039.

**Ghi chú.** Khoảng thời gian tối đa 366 ngày (ERR-11-039); không có giá trị `SENSITIVE`; tác vụ nền.
:::

### Giám sát và sự cố

#### API-11-107 · Bảng điều khiển giám sát

::: dac-ta
**Mục đích.** Bảng điều khiển giám sát.

**Phương thức, đường dẫn.** `GET /monitoring/summary`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-058.

**Tham số.** `processKey` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, `MonitoringSummary`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi: ERR-11-003.
:::

#### API-11-108 · Bước tắc nghẽn

::: dac-ta
**Mục đích.** Bước tắc nghẽn.

**Phương thức, đường dẫn.** `GET /monitoring/bottlenecks`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-059.

**Tham số.** `processKey` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, `BottleneckList`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền hoặc ngoài phạm vi.
:::

#### API-11-109 · Danh sách sự cố engine

::: dac-ta
**Mục đích.** Danh sách sự cố engine.

**Phương thức, đường dẫn.** `GET /incidents`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-060.

**Tham số.** `type` (query, IncidentType, tùy chọn); `status` (query, IncidentStatus, tùy chọn); `processKey` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `IncidentPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-006, ERR-11-003.
:::

#### API-11-110 · Chi tiết sự cố

::: dac-ta
**Mục đích.** Chi tiết sự cố.

**Phương thức, đường dẫn.** `GET /incidents/{incidentId}`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-060.

**Tham số.** `incidentId` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, `Incident`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi: ERR-11-006, ERR-11-001.
:::

#### API-11-111 · Thử lại sự cố

::: dac-ta
**Mục đích.** Thử lại sự cố.

**Phương thức, đường dẫn.** `POST /incidents/{incidentId}:retry`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-060.

**Tham số.** `incidentId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `Incident`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi: ERR-11-006, ERR-11-003, ERR-11-001.
:::

#### API-11-112 · Bỏ qua sự cố

::: dac-ta
**Mục đích.** Bỏ qua sự cố.

**Phương thức, đường dẫn.** `POST /incidents/{incidentId}:ignore`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-060.

**Tham số.** `incidentId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `Incident`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-006, ERR-11-007, ERR-11-003, ERR-11-001.
:::

#### API-11-113 · Thử lại sự cố hàng loạt

::: dac-ta
**Mục đích.** Thử lại sự cố hàng loạt.

**Phương thức, đường dẫn.** `POST /incidents:bulk-retry`.

**Quyền.** `PERM-11-compensate`.

**FR hiện thực.** FR-11-060.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BulkRetryRequest`; trường bắt buộc: `incidentIds`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200`, `BulkRetryResult`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-006, ERR-11-003.

**Ghi chú.** Tối đa 100 sự cố mỗi lần; mỗi sự cố xử lý riêng, kết quả ở `results[]`.
:::

#### API-11-114 · Xem quy tắc cảnh báo

::: dac-ta
**Mục đích.** Xem quy tắc cảnh báo.

**Phương thức, đường dẫn.** `GET /alert-rules`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-061.

**Tham số.** Không.

**Phản hồi thành công.** `200`, `AlertRuleList`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi: ERR-11-029.
:::

#### API-11-115 · Lưu quy tắc cảnh báo

::: dac-ta
**Mục đích.** Lưu quy tắc cảnh báo.

**Phương thức, đường dẫn.** `PUT /alert-rules`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-061.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertRulePut`; trường bắt buộc: `items`.

**Phản hồi thành công.** `200`, `AlertRuleList`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `428`; mã lỗi: ERR-11-029, ERR-11-003, ERR-11-004.

**Ghi chú.** Thay toàn bộ danh sách quy tắc; ngoài miền: ERR-11-029.
:::

### Cấu hình và tuân thủ

#### API-11-116 · Xem tham số tenant

::: dac-ta
**Mục đích.** Xem tham số tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-062.

**Tham số.** `prefix` (query, string, tùy chọn).

**Phản hồi thành công.** `200`, `SettingsDoc`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi: ERR-11-029.
:::

#### API-11-117 · Lưu tham số tenant

::: dac-ta
**Mục đích.** Lưu tham số tenant.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-062.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsPut`; trường bắt buộc: `settings`.

**Phản hồi thành công.** `200`, `SettingsDoc`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `428`; mã lỗi: ERR-11-029, ERR-11-003, ERR-11-004.

**Ghi chú.** Mỗi khóa theo miền ở FRS 8.2; ngoài miền hoặc vượt trần `COMMON` trả ERR-11-029.
:::

#### API-11-118 · Xem chính sách lưu giữ

::: dac-ta
**Mục đích.** Xem chính sách lưu giữ.

**Phương thức, đường dẫn.** `GET /retention-policy`.

**Quyền.** `PERM-11-read`.

**FR hiện thực.** FR-11-063.

**Tham số.** Không.

**Phản hồi thành công.** `200`, `RetentionPolicy`.

**Lỗi.** HTTP `401`, `403`, `409`; mã lỗi: ERR-11-047.
:::

#### API-11-119 · Sửa chính sách lưu giữ

::: dac-ta
**Mục đích.** Sửa chính sách lưu giữ.

**Phương thức, đường dẫn.** `PUT /retention-policy`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-063.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RetentionPut`.

**Phản hồi thành công.** `200`, `RetentionPolicy`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `428`; mã lỗi: ERR-11-047, ERR-11-003, ERR-11-004.

**Ghi chú.** Giá trị ngoài miền: ERR-11-029. Đang giữ pháp lý không bị dọn (ERR-11-047).
:::

#### API-11-120 · Đặt giữ pháp lý cho hồ sơ

::: dac-ta
**Mục đích.** Đặt giữ pháp lý cho hồ sơ.

**Phương thức, đường dẫn.** `POST /legal-holds`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-063.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegalHoldCreate`; trường bắt buộc: `businessKey`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201`, `LegalHold`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-047, ERR-11-003.

**Ghi chú.** Hồ sơ giữ pháp lý không bị dọn lịch sử cho tới khi gỡ giữ.
:::

#### API-11-121 · Chạy mẫu bằng chứng tuân thủ

::: dac-ta
**Mục đích.** Chạy mẫu bằng chứng tuân thủ.

**Phương thức, đường dẫn.** `POST /compliance/sample-runs`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-064.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SampleRunRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202`, `EvidencePackAccepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi: ERR-11-039, ERR-11-003.
:::

#### API-11-122 · Tải gói bằng chứng tuân thủ

::: dac-ta
**Mục đích.** Tải gói bằng chứng tuân thủ.

**Phương thức, đường dẫn.** `GET /compliance/evidence-packs/{id}`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-064.

**Tham số.** `id` (path, string, bắt buộc).

**Phản hồi thành công.** `200`, string.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi: ERR-11-039, ERR-11-006, ERR-11-001.

**Ghi chú.** Gói ZIP gồm BPMN, lịch sử mẫu, kết quả kiểm tra; liên kết ký có hạn.
:::

#### API-11-134 · Danh sách giữ pháp lý

::: dac-ta
**Mục đích.** Danh sách giữ pháp lý.

**Phương thức, đường dẫn.** `GET /legal-holds`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-063.

**Tham số.** `businessKey` (query, string, tùy chọn); `released` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `LegalHoldPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi: ERR-11-047, ERR-11-003.

**Ghi chú.** Danh sách giữ pháp lý của tenant; `released = true` gồm cả bản đã gỡ.
:::

#### API-11-135 · Gỡ giữ pháp lý

::: dac-ta
**Mục đích.** Gỡ giữ pháp lý.

**Phương thức, đường dẫn.** `POST /legal-holds/{holdId}:release`.

**Quyền.** `PERM-11-config`.

**FR hiện thực.** FR-11-063.

**Tham số.** `If-Match` (header, string, bắt buộc); `holdId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Phản hồi thành công.** `200`, `LegalHold`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi: ERR-11-047, ERR-11-003, ERR-11-004, ERR-11-001.

**Ghi chú.** Gỡ kèm lý do; từ lúc gỡ, phiên lại thuộc lịch dọn dẹp lưu giữ.
:::

#### API-11-137 · Danh sách lần chạy mẫu tuân thủ

::: dac-ta
**Mục đích.** Danh sách lần chạy mẫu tuân thủ.

**Phương thức, đường dẫn.** `GET /compliance/sample-runs`.

**Quyền.** `PERM-11-audit-read`.

**FR hiện thực.** FR-11-064.

**Tham số.** `environment` (query, Environment, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Phản hồi thành công.** `200`, `SampleRunPage`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi: ERR-11-039, ERR-11-003.

**Ghi chú.** Danh sách lần chạy mẫu `MAU_TUAN_THU_BPMN`; tải gói qua API-11-122.
:::

<!-- gen:dac-ta-api:end -->

## Phụ lục A. Đề nghị đồng bộ FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

FRS D02-03-PH11 bản 0.2 (Phụ lục C) đã hấp thụ các đề nghị của bản 0.1; tập này theo FRS 0.2. Còn lại là tên trường mà OpenAPI, AsyncAPI là nguồn (FRS không liệt kê trường, Phụ lục C).

### A.1. Trường chỉ có ở API

Hai nhóm sau đã hoặc không cần hấp thụ.

- **Đã hấp thụ ở FRS 0.2**: enum nội tuyến (`ValidateMode`, `CancelCompensate`, `PublishKind`, `AssignVia`, `SuspendState`, `NotifyAudience`, `ReconcileStatus`, `InstanceOutcome`); mã `ERR-11-051` thay chỗ tạm dùng ERR-11-006; `processKey` của API-11-104; bảng `test_run`, `instance_change` (EN-11-26, 27, CSDL 0.2).
- **Tên trường** (OpenAPI là nguồn, không cần FRS thêm): <!-- gen:newfields:start -->
`amount`, `appliedAt`, `bpmnXml`, `calendarYear`, `changeSummary`, `commentId`, `createdBy`, `decidedAt`, `decidedBy`, `durationMs`, `enabled`, `errorCount`, `eventType`, `expiresAt`, `exportId`, `fileName`, `finishedAt`, `flowPublished`, `flowVersion`, `forwardElementId`, `fromUser`, `handledBy`, `holdUntil`, `includeComments`, `inheritedFrom`, `lastCleanup`, `lastError`, `lastReceivedAt`, `legalRef`, `link`, `lockOwner`, `locked`, `mapping`, `masked`, `matchedRules`, `notified`, `openTasks`, `openedAt`, `ownerOrgCode`, `properties`, `releaseReason`, `releasedAt`, `releasedBy`, `requestedAt`, `requestedBy`, `resolvedAt`, `resolvedBy`, `responseCode`, `retriesDone`, `scanStatus`, `seq`, `sizeBytes`, `sourceXml`, `startAt`, `stepType`, `supplementDays`, `supplementDueAt`, `targetElementId`, `testRetentionDays`, `timeoutMinutes`, `timerExpression`, `timezone`, `toGroup`, `toUser`, `unmappedElements`, `unsupported`, `validFrom`, `validTo`, `waiverApprovedBy`, `warningCount`, `workDays`
<!-- gen:newfields:end -->

### A.2. Đề nghị khác

Bốn điểm của bản 0.1 còn nêu trong bảng, kèm tình trạng.

| Số | Nội dung | Tình trạng |
|---|---|---|
| 1 | API-11-058 trả `200` hoặc `202`; API-11-049 trả `201` hoặc `200` | Đã ghi ở FRS (FR-11-024, 018); OpenAPI ghi cả hai |
| 2 | API-11-122 khi gói chưa dựng xong | Đã hấp thụ: `409` ERR-11-006 (FR-11-064) |
| 3 | Người duyệt của API-11-043, 101 | Đã hấp thụ: không truyền; người khác gọi API duyệt |
| 4 | ADR 112 làm căn cứ chương 3.1 và 4 | Chỉ đề xuất trong tài liệu, chưa tạo tệp ADR |

: Đề nghị đồng bộ khác cho FRS

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-API và K-TRINH-BAY: 127 operation đúng mã FRS 9.4, 20 sự kiện, bốn sơ đồ trình tự, OpenAPI và AsyncAPI sinh từ một nguồn, công cụ đối chiếu FRS |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Theo FRS 0.2: thêm API-11-128…137 (xuất CSV nền, khôi phục phiên bản, duyệt, từ chối bỏ qua bước bù trừ, giữ pháp lý, yêu cầu quyền sửa, lần chạy mẫu), EVT-11-21; ERR-11-051, 125; API-11-020 có `waiverDecisions[]`, API-11-101 thành đề nghị; enum nội tuyến thành enum Phụ lục A; rút gọn chương đặc tả; Phụ lục A đánh dấu đã hấp thụ |
