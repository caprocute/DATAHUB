---
ma_tai_lieu: D03-04-PH17
ten: Đặc tả API và sự kiện phân hệ PH-17 Trợ lý AI và quản trị AI
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, kiểm thử viên, tích hợp viên, cán bộ ATTT, hội đồng thẩm định
phan_he: PH-17
mo_ta: Hợp đồng 194 operation OpenAPI 3.1 gồm 187 control plane và 7 data plane, 28 sự kiện AsyncAPI 3.0, quy ước RFC 9457, phân trang, khóa lạc quan, chống trùng và phát trực tuyến SSE của trợ lý AI, kèm bảng mã lỗi, ví dụ JSON và kiểm tra hợp đồng trong CI.
tai_lieu_lien_quan: D02-03-PH17 FRS; D03-02-PH17 SDD; D03-03-PH17 CSDL; D03-06-PH17 Màn hình; D05-02-PH17 Test case
---

# D03-04-PH17 · Đặc tả API và sự kiện Trợ lý AI và quản trị AI

## Tóm tắt cho hội đồng thẩm định

Hợp đồng API của PH-17 gồm hai tệp sinh từ [D02-03-PH17](../../02-yeu-cau/frs/D02-03-PH17-frs-tro-ly-ai.md) §9: [`ph17/openapi-assist.yaml`](ph17/openapi-assist.yaml) (OpenAPI 3.1, 194 operation) và [`ph17/asyncapi-assist.yaml`](ph17/asyncapi-assist.yaml) (AsyncAPI 3.0, 28 kênh). Control plane `/api/assist/v1` (187 operation) phục vụ người dùng qua BFF của cổng; data plane `/assist/v1` (7 operation) chỉ trong cụm cho PH-04 và PH-11, xác thực mTLS với danh tính SPIFFE và scope `assist:infer`.

Năm điểm hội đồng cần lưu ý.

1. **Không có API nào cho trợ lý tự ghi.** Công cụ của trợ lý chỉ đọc; mọi thay đổi do gợi ý là hai bước: `POST /mapping-suggestions` trả đề xuất, người dùng bấm `POST /suggestions/{id}:apply` thì phân hệ chủ ghi bản nháp bằng quyền của người đó (API-17-110, BR-17-056, 057).
2. **Bốn mắt nằm ở hành động `:approve`.** Bật trợ lý, mô hình ngoài, duyệt phiên bản mô hình, duyệt chỉ dẫn hệ thống, duyệt tài liệu tải lên, gỡ tắt khẩn nền tảng đều có hành động duyệt riêng, người duyệt khác người đề nghị (ERR-17-005).
3. **Cổng phát hành là API đọc được.** `GET /release-gates/{subjectType}/{subjectId}` (API-17-154) trả điểm đánh giá, số ca đỏ lọt, số ca đỏ đang hoạt động (cần ≥ 50) và danh sách điều kiện còn thiếu, nên CI và người duyệt cùng thấy một nguồn.
4. **Trả lời phát trực tuyến bằng SSE, đồng thời có bản đầy đủ.** API-17-096 phát `text/event-stream` (độ trễ token đầu p95 ≤ 3 s, NFR-17-002); API-17-095 trả trọn câu trả lời cho khách tích hợp không dùng SSE. Mọi câu trả lời mang cờ `aiGenerated` (FR-17-048).
5. **Không lộ nội dung chưa che.** Hội thoại, tin nhắn, nhật ký chỉ có `content` đã che; xem nhật ký của người khác cần phiếu 60 phút có lý do (API-17-169, 171); sự kiện chỉ mang mã, trạng thái, số đếm (BR-17-022, 073).

: Tóm tắt hợp đồng API PH-17

| Chỉ số | Giá trị |
|---|---|
| Operation | 194 (187 control plane, 7 data plane), 162 đường dẫn |
| Phương thức | 83 `GET`, 86 `POST`, 10 `PUT`, 8 `PATCH`, 6 `DELETE` |
| Có `If-Match` | 51 operation |
| Bắt buộc `Idempotency-Key` | 76 operation |
| Lược đồ thành phần | 246 |
| Sự kiện phát | 28 (EVT-17-01…28) |
| Mã lỗi | 105 (ERR-17-001…087 control plane, 101…118 data plane) |
| Kiểm hợp đồng | `check_contracts.py` sạch, Spectral không lỗi, `kiem_tra_yaml.py` không lỗi |

: Con số chính của hợp đồng API PH-17

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu mô tả hợp đồng bên ngoài của PH-17 ở mức đủ để kỹ sư `dh-assist` và `dh-console` lập trình, tích hợp viên PH-04, PH-11, PH-16 gọi đúng và kiểm thử viên dựng ca kiểm thử hợp đồng. Nguồn chuẩn là hai tệp YAML; tài liệu này không lặp lại từng lược đồ mà dẫn quy ước, danh mục, mã lỗi, sự kiện và đặc tả chi tiết các operation trọng yếu. Chương 3, 4, 6, 9, 12, 13 sinh từ YAML bằng [`gen_md.py`](ph17/tools/gen_md.py) và `build/tools/sinh_dac_ta_api.py`.

Ngoài phạm vi: hợp đồng với nhà cung cấp mô hình (ở APISIX `ai-proxy`, PH-03), API của các phân hệ mà công cụ của trợ lý gọi (PH-02, 04, 07, 10; FRS Q17-11).

### 0.2. Thuật ngữ

| Thuật ngữ | Giải thích |
|---|---|
| Control plane, data plane | Mặt phẳng quản trị cho người dùng qua BFF; mặt phẳng suy luận trong cụm cho DU gọi |
| SSE | Server-Sent Events, `text/event-stream`, phát câu trả lời từng đoạn |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên, ví dụ `:approve` |
| Bốn mắt | Người đề nghị khác người duyệt (ERR-17-005) |
| `aiGenerated` | Cờ nội dung do AI tạo, luôn có ở phản hồi sinh văn bản (FR-17-048) |
| Cổng phát hành | Điều kiện đánh giá, ca đỏ, số ca tối thiểu để duyệt mô hình hoặc chỉ dẫn |
| DU | Đơn vị triển khai; PH-04 và PH-11 gọi data plane bằng danh tính DU |

: Thuật ngữ của tập API PH-17

### 0.3. Tài liệu tham chiếu

| Tài liệu | Nội dung dùng |
|---|---|
| D02-03-PH17 FRS §6, §8.2, §9, Phụ lục A | FR-17-001…062, 49 khóa `17.*`, ERR, EVT, API-17-001…194, enum |
| D03-03-PH17 CSDL | Cột snake_case ứng với trường camelCase; ràng buộc chốt ở CSDL |
| D03-04 khung chung | Quy ước đường dẫn, RFC 9457, phân trang, `Idempotency-Key` |
| D03-07 ATTT; SEC-15, 16, 38, 49 | Xác thực, đường ra mô hình, che dữ liệu, tắt mặc định |
| ADR-042, ADR-170 đến 174 (đề xuất ở FRS Phụ lục B) | Outbox, pgvector, truy hồi lai, công cụ chỉ đọc, cổng phát hành, lập chỉ mục theo sự kiện |

: Tài liệu tham chiếu của tập API PH-17

Căn cứ pháp lý của các quy ước (nhật ký trong nước, che dữ liệu, truy cập có lý do): Luật An ninh mạng 116/2025, Luật Bảo vệ dữ liệu cá nhân 91/2025, Luật Dữ liệu 60/2024, Nghị định 331/2026 và TCVN 14423:2026.

### 0.4. Người đọc

Kỹ sư `dh-assist`, `dh-console`, tích hợp viên PH-04, 11, 16, kiểm thử viên, ATTT; hội đồng đọc Tóm tắt, chương 1, 2 và 10.

### 0.5. Cấu trúc tài liệu

Chương 1 quy ước, 2 xác thực và phân quyền, 3 danh mục endpoint, 4 sự kiện, 5 hợp đồng với phân hệ khác, 6 mã lỗi, 7 kiểm hợp đồng, 8 ánh xạ từ hệ cũ, 9 truy vết FR, 10 đề nghị đồng bộ, 11 câu hỏi mở, 12 ví dụ, 13 đặc tả endpoint trọng yếu.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi operation, trừ khi bảng ở chương 3 hoặc đặc tả ở chương 13 ghi khác.

| Mục | Quy ước |
|---|---|
| Đường gốc | Control plane `/api/assist/v1` qua APISIX (người dùng đi qua BFF của cổng); trong cụm `dh-assist.dh-assist.svc`. Data plane `/assist/v1`, chỉ trong cụm, Deployment riêng (vai CSDL `ph17_infer`), 2 bản sao như `dh-assist` (GĐ-17-04). Đường dẫn ở chương 3 của control plane tính từ gốc, của data plane viết đầy đủ |
| Tenant | Lấy từ token (claim `tenant`), không từ thân, đường dẫn hay tiêu đề; đối tượng của tenant khác trả `404` ERR-17-001, không lộ sự tồn tại; mọi bảng có RLS (D03-03-PH17 §1.2) |
| Hành động | Hậu tố `:{hành-động}` (`:approve`, `:submit`, `:apply`); hành động có thể đổi trạng thái là `POST` |
| Khóa lạc quan | `GET` đối tượng có phiên bản trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động trên đối tượng đó bắt buộc `If-Match`; thiếu trả `428` (mã nền ERR-00-428), lệch trả `409` ERR-17-004. 51 operation có `If-Match` |
| Chống trùng | Mọi `POST` đổi dữ liệu ở control plane (76 operation, trừ các `POST` chỉ đọc như tìm kiếm, xem trước) bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-17-087 (BR-17-087). Tin nhắn thêm `clientMessageId` để chống gửi trùng khi mất kết nối |
| Phân trang | `page` (từ 0), `size` (1…100, mặc định 20), `sort` (tiền tố `-` giảm dần); phản hồi `items`, `page`, `size`, `totalElements`; lọc bằng tham số tên trường, tham số bắt buộc ghi ở OpenAPI |
| Thời gian, số | RFC 3339 có múi giờ (`+07:00`); mã nghiệp vụ chữ hoa `^[A-Z][A-Z0-9_-]{1,47}$` |
| Lỗi | RFC 9457 `application/problem+json`: `type` = `https://datahub.gov.vn/errors/{code}`, `title`, `status`, `code` (`ERR-17-nnn`), `traceId`, `errors[]` theo trường; thông báo tiếng Việt (mặc định) hoặc `en` theo `Accept-Language`; không lộ nội dung hội thoại (mục 6.1) |
| Tác vụ dài | Lập chỉ mục, đánh giá, ca đỏ, đồng bộ tuyến, gói bằng chứng trả `202` kèm đối tượng ở trạng thái `QUEUED`; theo dõi bằng `GET` đối tượng hoặc sự kiện |
| Phát trực tuyến | API-17-096 trả `text/event-stream`: `message.delta` (đoạn văn bản), `message.citation` (trích dẫn), `message.done` (kết thúc, kèm `messageId`), `message.error` (lỗi RFC 9457); khách hủy bằng API-17-097 hoặc đóng kết nối |
| Nội dung AI | Phản hồi sinh văn bản mang `aiGenerated: true`; giao diện hiển thị nhãn "Nội dung do AI tạo" (FR-17-048); không API nào tự ghi thay người dùng |
| Phân loại dữ liệu | Operation đọc hội thoại, nhật ký có `x-dh-classification` (`RESTRICTED`); phản hồi này có `Cache-Control: no-store` |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-assist`, Kafka; `Accept-Language: vi` hoặc `en` |

: Quy ước chung của API PH-17

### 1.1. Hai mặt phẳng

| Mục | Control plane | Data plane |
|---|---|---|
| Đường gốc | `/api/assist/v1` | `/assist/v1` |
| Bên gọi | Cán bộ qua BFF; PH-16 lấy số liệu bằng token dịch vụ (`assist:report`) | PH-04 (bước luồng), PH-11 (bước quy trình) |
| Xác thực | OIDC và PKCE ở BFF (quyền `PERM-17-*`); `client_credentials` cho PH-16 | `client_credentials`, mTLS và danh tính SPIFFE; scope `assist:infer` |
| Operation | 187 (API-17-001…186, 194) | 7 (API-17-187…193) |
| Hiệu năng | Đọc p95 ≤ 500 ms; token đầu tiên p95 ≤ 3 s (NFR-17-002) | Chờ mô hình tối đa `17.model.timeout-seconds` (60 giây, ERR-17-111); không ghi được vết thì từ chối (ERR-17-118) |
| Khi không khả dụng | Giao diện ẩn trợ lý, không ảnh hưởng chức năng khác (SEC-49) | DU gọi nhận `503` và quay về xử lý không AI |

: Hai mặt phẳng của API PH-17

### 1.2. Phiên bản hóa và tương thích

Phiên bản nằm ở đường dẫn (`v1`). Thay đổi tương thích ngược (thêm trường tùy chọn, thêm giá trị enum ở phản hồi, thêm operation) vào `v1`; thay đổi phá vỡ (xóa hay đổi tên trường, đổi kiểu, thêm trường bắt buộc, đổi ngữ nghĩa mã lỗi) sang `v2` chạy song song tối thiểu 6 tháng. Sự kiện đổi phiên bản bằng hậu tố topic `.v2`.

### 1.3. Hạn mức gọi

Hạn mức của người dùng và của DU lấy từ khóa `17.quota.*` (FRS §8.2); vượt hạn mức trả `429` và không gọi mô hình.

| Mặt phẳng, đối tượng | Hạn mức | Khi vượt |
|---|---|---|
| Hỏi đáp, mỗi người dùng | 10 lượt mỗi phút, 200 lượt mỗi ngày (`17.quota.user-turns-per-minute`, `17.quota.user-turns-per-day`) | `429` kèm `Retry-After` |
| Token, mỗi tenant | 2.000.000 token mỗi ngày (`17.quota.tenant-tokens-per-day`, trần 50.000.000) | `429`, phát EVT-17-12 ở 80% và 100% |
| Quản trị (các API còn lại), mỗi người dùng | 300 yêu cầu mỗi phút (giả định theo GĐ-17-04) | `429` kèm `Retry-After` |
| Data plane, mỗi DU | 120 lời gọi mỗi phút (`17.quota.du-calls-per-minute`) | `429` ERR-17-109 |
| Độ dài đầu vào | 4.000 ký tự (`17.input.max-chars`, trần 8.000) | `422` ERR-17-113 |

: Hạn mức gọi của API PH-17

## 2. Xác thực và phân quyền

### 2.1. Quyền người dùng

Mỗi operation ghi quyền `PERM-17-*` ở `x-datahub-permission`; dấu `/` là một trong các quyền đủ để gọi. Hai quyền `PERM-17-use`, `PERM-17-admin` có ở D02-08, tám quyền còn lại là đề nghị mới (FRS Phụ lục B). Trợ lý trả lời trong phạm vi quyền đọc của chính người hỏi: `PERM-17-use` không cho xem thêm gì so với tự dùng cổng (BR-17-035).

<!-- gen:perm:start -->
| Quyền hoặc scope | Số operation | Operation |
|---|---|---|
| `admin` | 28 | 002…014, 018…021, 044, 101, 102, 164…167, 177, 178, 180, 181 |
| `config` | 5 | 163, 180…183 |
| `eval` | 32 | 041, 042, 131…154, 160…162, 184…186 |
| `feedback` | 7 | 156…162 |
| `knowledge` | 28 | 062…089 |
| `log-read` | 15 | 056…058, 123, 168…178 |
| `mTLS DU` | 1 | 193 |
| `model` | 41 | 011, 022…061 |
| `tool` | 11 | 120…130 |
| `use` | 34 | 001, 015…017, 090…100, 103…119, 155, 194 |
| `scope assist:infer` | 6 | 187…192 |
| `scope assist:report` | 1 | 179 |

: Số operation theo quyền chức năng và scope máy
<!-- gen:perm:end -->

### 2.2. Scope máy

| Scope | Dùng bởi | Operation |
|---|---|---|
| `assist:infer` | PH-04, PH-11 (DU gọi) | API-17-187…192 (API-17-193 chỉ cần mTLS DU) |
| `assist:report` | PH-16 | API-17-179 |

: Scope máy của API PH-17

Token dịch vụ lấy bằng `client_credentials` (mTLS hoặc `private_key_jwt`); data plane kiểm DU nào có scope nào theo SPIFFE ID (SEC-15). Lời gọi thiếu mục đích khai thác hoặc mức dữ liệu bị từ chối ERR-17-102.

### 2.3. Tách nhiệm vụ

| Cặp loại trừ | Nơi ép | Mã lỗi |
|---|---|---|
| Người đề nghị khác người duyệt đề nghị chính sách | `:approve` API-17-006, 024 | ERR-17-005 |
| Người duyệt phiên bản mô hình khác người đề nghị | API-17-041 | ERR-17-005 |
| Người duyệt chỉ dẫn hệ thống khác người soạn | API-17-136 | ERR-17-005 |
| Người duyệt tài liệu tải lên khác người tải | API-17-085 | ERR-17-005 |
| Người cấp phiếu nhật ký khác người mở nhật ký (D02-08 §4) | API-17-169, 171 | ERR-17-080 khi chưa có phiếu hợp lệ |

: Tách nhiệm vụ trong API PH-17

### 2.4. Lỗi xác thực

Thiếu hoặc hết hạn token trả `401` (mã nền ERR-00-401); thiếu quyền chức năng trả `403` (ERR-00-403); thiếu `If-Match` trả `428` (ERR-00-428). Ba mã nền này dùng chung toàn nền tảng, không thuộc dải ERR-17.

## 3. Danh mục endpoint

Mỗi bảng liệt kê operation của một nhóm theo FRS §9.4; cột "TC" là mã thành công, "Lỗi riêng" là mã ERR-17 gắn ngoài mã cấu trúc (mục 6.2).

<!-- gen:catalog:start -->
### 3.1. Chính sách

Trạng thái, chính sách theo tenant, đề nghị đổi bốn mắt, năng lực, danh sách trắng nhà cung cấp, hạn mức, điều khoản, tắt khẩn (FR-17-001…006). Nhóm có 25 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-001 | `GET /status` | Trạng thái trợ lý cho người gọi: bật hay tắt, năng lực khả dụng, điều khoản cần xác nhận, lượt còn lại | 001, 002, 005, 022 | use | 200 | 005, 008, 011, 014, 015, 020, 052 |
| API-17-002 | `GET /policy` | Chính sách hiện hành của tenant | 001, 002, 004 | admin | 200 | 005, 008, 011, 014, 015, 018, 019 |
| API-17-003 | `POST /policy/changes` | Đề nghị đổi chính sách cần bốn mắt (`ENABLE`, `EXTERNAL_ON`, `RESUME`, `SENSITIVE_PARAM`) | 001, 003, 006, 059 | admin | 201 | 005, 006, 007, 008, 009, 010, 012, 013, 014, 015, 016, 017, 018, 033, 082, 083, 084 |
| API-17-004 | `GET /policy/changes` | Danh sách đề nghị đổi chính sách | 001 | admin | 200 | 005, 008, 014, 015 |
| API-17-005 | `GET /policy/changes/{changeId}` | Chi tiết đề nghị | 001 | admin | 200 | 005, 008, 014, 015 |
| API-17-006 | `POST /policy/changes/{changeId}:approve` | Duyệt đề nghị (người thứ hai) | 001, 003, 006, 059 | admin | 200 | 005, 006, 007, 008, 009, 010, 012, 013, 014, 015, 016, 017, 018, 033, 082, 083, 084 |
| API-17-007 | `POST /policy/changes/{changeId}:reject` | Từ chối đề nghị, kèm lý do | 001 | admin | 200 | 005, 006, 008, 010, 013, 014, 015, 033 |
| API-17-008 | `POST /policy:disable` | Tắt trợ lý cho tenant | 001 | admin | 200 | 005, 006, 008, 010, 013, 014, 015, 033 |
| API-17-009 | `PUT /policy/capabilities` | Đặt năng lực bật và nhóm vai trò được dùng | 002 | admin | 200 | 004, 010, 011, 015 |
| API-17-010 | `GET /policy/provider-grants` | Liệt kê nhà cung cấp ngoài trong danh sách trắng của tenant | 003 | admin | 200 | 005, 016 |
| API-17-011 | `POST /policy/provider-grants` | Thêm nhà cung cấp vào danh sách trắng (cần đề nghị `EXTERNAL_ON` đã duyệt) | 003 | admin / model | 201 | 005, 013, 016, 017 |
| API-17-012 | `DELETE /policy/provider-grants/{grantId}` | Gỡ nhà cung cấp khỏi danh sách trắng | 003 | admin | 204 | 005, 013, 016, 017 |
| API-17-013 | `GET /policy/quotas` | Xem hạn mức và giới hạn độ dài | 004 | admin | 200 | 018, 019 |
| API-17-014 | `PUT /policy/quotas` | Đặt hạn mức lượt, token, độ dài | 004 | admin | 200 | 018, 019, 021, 022, 023 |
| API-17-015 | `GET /usage/me` | Lượt và hạn mức còn lại của tôi hôm nay | 004, 022 | use | 200 | 008, 018, 019, 020, 052 |
| API-17-016 | `GET /notices/current` | Điều khoản dùng AI hiện hành và trạng thái xác nhận của tôi | 005 | use | 200 | 020 |
| API-17-017 | `POST /notices/current:accept` | Xác nhận điều khoản | 005 | use | 200 | 020, 024 |
| API-17-018 | `GET /notices` | Liệt kê các phiên bản điều khoản | 005 | admin | 200 | 020 |
| API-17-019 | `POST /notices` | Soạn và công bố phiên bản điều khoản mới | 005 | admin | 201 | 020, 024 |
| API-17-020 | `POST /kill-switch:activate` | Tắt khẩn cấp trợ lý của tenant | 006 | admin | 200 | 005, 007, 012 |
| API-17-021 | `GET /kill-switch` | Trạng thái tắt khẩn của tenant và nền tảng | 006 | admin | 200 | 005, 007, 012 |
| API-17-022 | `POST /platform/kill-switch:activate` | PA tắt khẩn toàn nền tảng hoặc một nhóm tenant | 006 | model | 200 | 005, 007, 012 |
| API-17-023 | `POST /platform/kill-switch:release` | PA đề nghị gỡ tắt khẩn nền tảng | 006 | model | 200 | 005, 007, 012 |
| API-17-024 | `POST /platform/kill-switch:approve-release` | PA thứ hai duyệt gỡ | 006 | model | 200 | 005, 007, 012 |
| API-17-025 | `GET /platform/kill-switch` | Trạng thái tắt khẩn nền tảng | 006 | model | 200 | 005, 007, 012 |

: Danh mục API nhóm Chính sách

### 3.2. Cổng mô hình

Nhà cung cấp, cam kết, mô hình, phiên bản, mô hình của tenant, tuyến egress, giới hạn cổng, cầu dao, vết lời gọi, sức khỏe (FR-17-007…014). Nhóm có 36 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-026 | `GET /model-providers` | Liệt kê nhà cung cấp mô hình | 007 | model | 200 | 025, 026, 028, 039 |
| API-17-027 | `POST /model-providers` | Khai báo nhà cung cấp (nội bộ hoặc ngoài) | 007 | model | 201 | 002, 025, 026, 027, 028, 039 |
| API-17-028 | `GET /model-providers/{providerId}` | Chi tiết nhà cung cấp | 007 | model | 200 | 025, 026, 028, 039 |
| API-17-029 | `PATCH /model-providers/{providerId}` | Sửa điểm cuối, vùng lưu dữ liệu, `secret_ref` | 007 | model | 200 | 002, 025, 026, 027, 028, 039 |
| API-17-030 | `POST /model-providers/{providerId}:test-connection` | Kiểm tra kết nối tới nhà cung cấp | 007, 014 | model | 200 | 002, 009, 025, 026, 027, 028, 030, 038, 039 |
| API-17-031 | `POST /model-providers/{providerId}:suspend` | Đình chỉ nhà cung cấp | 007 | model | 200 | 002, 025, 026, 027, 028, 039 |
| API-17-032 | `POST /model-providers/{providerId}/commitments` | Đăng ký cam kết lưu trong nước, không huấn luyện (kèm tệp) | 003, 007 | model | 201 | 002, 005, 013, 016, 017, 025, 026, 027, 028, 039 |
| API-17-033 | `GET /models` | Liệt kê mô hình | 008 | model | 200 | 031 |
| API-17-034 | `POST /models` | Khai báo mô hình | 008 | model | 201 | 002, 003, 006, 031, 040 |
| API-17-035 | `GET /models/{modelId}` | Chi tiết mô hình và các phiên bản | 008 | model | 200 | 031 |
| API-17-036 | `PATCH /models/{modelId}` | Sửa mô tả, năng lực | 008 | model | 200 | 002, 003, 006, 031, 040 |
| API-17-037 | `POST /models/{modelId}/versions` | Thêm phiên bản mô hình ở trạng thái `DRAFT` | 008, 009 | model | 201 | 002, 003, 005, 006, 029, 030, 031, 040, 073 |
| API-17-038 | `GET /model-versions/{versionId}` | Chi tiết phiên bản, kết quả đánh giá, cổng phát hành | 008, 009 | model | 200 | 005, 031 |
| API-17-039 | `PATCH /model-versions/{versionId}` | Sửa giới hạn ngữ cảnh, đơn giá, tham số sinh | 008 | model | 200 | 002, 003, 006, 031, 040 |
| API-17-040 | `POST /model-versions/{versionId}:submit-eval` | Chuyển sang `EVALUATING` và chạy bộ đánh giá, bộ ca đỏ | 009 | model | 202 | 005, 029, 030, 073 |
| API-17-041 | `POST /model-versions/{versionId}:approve` | Duyệt bốn mắt, chuyển `APPROVED` | 009 | model / eval | 200 | 005, 029, 030, 073 |
| API-17-042 | `POST /model-versions/{versionId}:reject` | Từ chối, về `DRAFT`, kèm lý do | 009 | model / eval | 200 | 005, 029, 030, 073 |
| API-17-043 | `POST /model-versions/{versionId}:retire` | Ngừng phiên bản (`RETIRED`) | 009 | model | 200 | 005, 029, 030, 073 |
| API-17-044 | `GET /tenant-models` | Mô hình tenant đã bật và mô hình mặc định | 010 | admin / model | 200 | 031, 032 |
| API-17-045 | `PUT /tenant-models/defaults` | Chọn mô hình mặc định và dự phòng theo loại | 010 | model | 200 | 017, 030, 031, 032, 033, 034, 036 |
| API-17-046 | `POST /tenant-models/{versionId}:enable` | Bật phiên bản đã duyệt cho tenant | 010 | model | 200 | 017, 030, 031, 032, 033, 034, 036 |
| API-17-047 | `POST /tenant-models/{versionId}:disable` | Tắt phiên bản cho tenant | 010 | model | 200 | 017, 030, 031, 032, 033, 034, 036 |
| API-17-048 | `GET /routes` | Liệt kê tuyến mô hình và trạng thái đồng bộ | 010, 011 | model | 200 | 031, 032, 039 |
| API-17-049 | `POST /routes:sync` | Yêu cầu đồng bộ tuyến `ai-proxy` qua PH-03 | 011 | model | 202 | 009, 035, 039 |
| API-17-050 | `GET /routes/sync-runs` | Lịch sử đồng bộ | 011 | model | 200 | 039 |
| API-17-051 | `GET /routes/sync-runs/{runId}` | Chi tiết một lượt đồng bộ | 011 | model | 200 | 039 |
| API-17-052 | `GET /gateway/limits` | Xem giới hạn tần suất của cổng mô hình | 012 | model | 200 |  |
| API-17-053 | `PUT /gateway/limits` | Đặt giới hạn tần suất và ngưỡng cầu dao | 012 | model | 200 | 003, 036, 037, 038 |
| API-17-054 | `GET /gateway/breakers` | Trạng thái cầu dao theo mô hình | 012 | model | 200 |  |
| API-17-055 | `POST /gateway/breakers/{breakerId}:reset` | Đóng cầu dao thủ công | 012 | model | 200 | 003, 036, 037, 038 |
| API-17-056 | `GET /invocations` | Tra vết lời gọi mô hình (không nội dung) | 013 | model / log-read | 200 | 001, 079 |
| API-17-057 | `GET /invocations/{invocationId}` | Chi tiết một lời gọi | 013 | model / log-read | 200 | 001, 079 |
| API-17-058 | `GET /invocations/stats` | Thống kê lời gọi theo mô hình, năng lực, kết quả | 013 | model / log-read | 200 | 001, 079 |
| API-17-059 | `GET /model-health` | Trạng thái sức khỏe các mô hình | 014 | model | 200 |  |
| API-17-060 | `POST /model-health/{versionId}:probe` | Thăm dò ngay | 014 | model | 202 | 009, 030, 038 |
| API-17-061 | `GET /model-health/{versionId}/history` | Lịch sử sức khỏe | 014 | model | 200 |  |

: Danh mục API nhóm Cổng mô hình

### 3.3. Kho tri thức

Nguồn, lập chỉ mục, kiểm mức phân loại, tài liệu, xóa lan truyền, tài liệu tải lên, tình trạng chỉ mục (FR-17-015…021). Nhóm có 28 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-062 | `GET /knowledge/sources` | Liệt kê nguồn tri thức | 015 | knowledge | 200 | 041 |
| API-17-063 | `POST /knowledge/sources` | Khai báo nguồn tri thức | 015 | knowledge | 201 | 041, 042, 048 |
| API-17-064 | `GET /knowledge/sources/{sourceId}` | Chi tiết nguồn | 015, 021 | knowledge | 200 | 001, 041, 079 |
| API-17-065 | `PATCH /knowledge/sources/{sourceId}` | Sửa phạm vi, lịch lập chỉ mục | 015 | knowledge | 200 | 041, 042, 048 |
| API-17-066 | `POST /knowledge/sources/{sourceId}:pause` | Tạm dừng nguồn | 015 | knowledge | 200 | 041, 042, 048 |
| API-17-067 | `POST /knowledge/sources/{sourceId}:resume` | Tiếp tục nguồn | 015 | knowledge | 200 | 041, 042, 048 |
| API-17-068 | `POST /knowledge/sources/{sourceId}:retire` | Ngừng nguồn và xóa đoạn liên quan | 015, 019 | knowledge | 200 | 001, 009, 041, 042, 047, 048 |
| API-17-069 | `POST /knowledge/sources/{sourceId}:reindex` | Lập lại chỉ mục một nguồn | 017 | knowledge | 202 | 006, 009, 044, 048, 049 |
| API-17-070 | `POST /knowledge/sources/{sourceId}:check-class` | Kiểm tra trước mức phân loại của đối tượng trong nguồn | 016 | knowledge | 200 | 009, 043, 049 |
| API-17-071 | `GET /knowledge/classification-skips` | Danh sách đối tượng bị bỏ qua do mức phân loại | 016 | knowledge | 200 | 043, 049 |
| API-17-072 | `GET /knowledge/index-jobs` | Liệt kê lượt lập chỉ mục | 017, 021 | knowledge | 200 | 001, 049, 079 |
| API-17-073 | `GET /knowledge/index-jobs/{jobId}` | Chi tiết lượt lập chỉ mục | 017, 021 | knowledge | 200 | 001, 049, 079 |
| API-17-074 | `POST /knowledge/index-jobs:full-reindex` | Lập lại toàn bộ chỉ mục của tenant | 017 | knowledge | 202 | 006, 009, 044, 048, 049 |
| API-17-075 | `POST /knowledge/index-jobs/{jobId}:cancel` | Hủy lượt đang chạy | 017 | knowledge | 200 | 006, 009, 044, 048, 049 |
| API-17-076 | `GET /knowledge/documents` | Liệt kê tài liệu và số đoạn | 018, 021 | knowledge | 200 | 001, 046, 079 |
| API-17-077 | `GET /knowledge/documents/{documentId}` | Chi tiết tài liệu, các đoạn (không hiện vector) | 018 | knowledge | 200 | 046 |
| API-17-078 | `POST /knowledge/documents/{documentId}:reindex` | Lập lại chỉ mục một tài liệu | 018 | knowledge | 202 | 036, 046, 047 |
| API-17-079 | `DELETE /knowledge/documents/{documentId}` | Xóa tài liệu khỏi chỉ mục | 019 | knowledge | 204 | 001, 009, 047 |
| API-17-080 | `GET /knowledge/deletions` | Nhật ký xóa lan truyền | 019 | knowledge | 200 | 001 |
| API-17-081 | `POST /knowledge/uploads` | Tạo tài liệu tải lên (tệp và mức dữ liệu khai) | 020 | knowledge | 201 | 005, 043, 045, 046 |
| API-17-082 | `GET /knowledge/uploads` | Liệt kê tài liệu tải lên | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-083 | `GET /knowledge/uploads/{uploadId}` | Chi tiết tài liệu tải lên | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-084 | `POST /knowledge/uploads/{uploadId}:submit` | Gửi duyệt | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-085 | `POST /knowledge/uploads/{uploadId}:approve` | Duyệt (người thứ hai) và lập chỉ mục | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-086 | `POST /knowledge/uploads/{uploadId}:reject` | Từ chối, kèm lý do | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-087 | `POST /knowledge/uploads/{uploadId}:retire` | Ngừng và xóa khỏi chỉ mục | 020 | knowledge | 200 | 005, 043, 045, 046 |
| API-17-088 | `GET /knowledge/status` | Tổng hợp số đoạn, độ tươi, lỗi của chỉ mục | 021 | knowledge | 200 | 001, 079 |
| API-17-089 | `GET /knowledge/sources/{sourceId}/health` | Sức khỏe chỉ mục của một nguồn | 021 | knowledge | 200 | 001, 079 |

: Danh mục API nhóm Kho tri thức

### 3.4. Hội thoại và tìm kiếm

Hội thoại, tin nhắn (đầy đủ và phát trực tuyến), tìm dịch vụ, câu hỏi gợi ý, ngữ cảnh màn hình (FR-17-022…029). Nhóm có 14 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-090 | `POST /conversations` | Mở hội thoại, kèm ngữ cảnh màn hình | 022, 029 | use | 201 | 008, 020, 051, 052 |
| API-17-091 | `GET /conversations` | Lịch sử hội thoại của tôi | 027 | use | 200 | 001 |
| API-17-092 | `GET /conversations/{conversationId}` | Chi tiết hội thoại của tôi | 022, 027 | use | 200 | 001, 008, 020, 052 |
| API-17-093 | `DELETE /conversations/{conversationId}` | Xóa một hội thoại khỏi lịch sử của tôi | 027 | use | 204 | 001, 004, 050 |
| API-17-094 | `DELETE /conversations` | Xóa toàn bộ lịch sử của tôi | 027 | use | 204 | 001, 004, 050 |
| API-17-095 | `POST /conversations/{conversationId}/messages` | Gửi câu hỏi, nhận câu trả lời đầy đủ | 023, 024, 025, 030, 036, 044, 045, 048 | use | 200 | 001, 003, 009, 011, 019, 021, 022, 023, 036, 038, 054, 055, 059, 063, 064, 065, 066, 067, 068, 070, 084 |
| API-17-096 | `POST /conversations/{conversationId}/messages:stream` | Gửi câu hỏi, nhận câu trả lời phát trực tuyến (SSE `text/event-stream`) | 023, 026, 048 | use | 200 | 011, 019, 021, 022, 023, 038, 053, 067, 068, 070, 084 |
| API-17-097 | `POST /conversations/{conversationId}/messages/{messageId}:cancel` | Hủy câu trả lời đang phát | 026 | use | 200 | 038, 053, 067 |
| API-17-098 | `GET /conversations/{conversationId}/messages` | Các tin nhắn của hội thoại | 022, 027 | use | 200 | 001, 008, 020, 052 |
| API-17-099 | `POST /search` | Tìm dịch vụ (truy hồi lai, kết quả có trích dẫn, không sinh văn bản) | 023, 024, 025 | use | 200 | 009, 011, 019, 021, 022, 023, 036, 038, 064, 067, 068 |
| API-17-100 | `GET /suggested-questions` | Gợi ý câu hỏi theo màn và vai trò | 028 | use | 200 | 011 |
| API-17-101 | `POST /suggested-questions` | Thêm câu hỏi mẫu | 028 | admin | 201 | 003, 011 |
| API-17-102 | `PUT /suggested-questions/{questionId}` | Sửa, ngừng câu hỏi mẫu | 028 | admin | 200 | 003, 011 |
| API-17-103 | `POST /screen-contexts:resolve` | Kiểm tra ngữ cảnh màn hình, trả năng lực và nút hiển thị | 022, 029 | use | 200 | 008, 020, 051, 052 |

: Danh mục API nhóm Hội thoại và tìm kiếm

### 3.5. Gợi ý ánh xạ

Gợi ý ánh xạ trường và mã, kiểm biểu thức, xem trước, áp dụng, sửa, từ chối (FR-17-030…035). Nhóm có 9 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-104 | `POST /mapping-suggestions` | Gợi ý ánh xạ trường nguồn sang đích (biểu thức JQ đề xuất) | 030, 032, 034 | use | 201 | 001, 011, 021, 022, 023, 054, 055, 056, 059 |
| API-17-105 | `POST /mapping-suggestions:validate-expression` | Kiểm cú pháp và chạy thử biểu thức JQ trên mẫu tổng hợp | 030 | use | 200 | 011, 021, 022, 023, 054, 055, 059 |
| API-17-106 | `POST /code-mapping-suggestions` | Gợi ý ánh xạ mã cục bộ sang danh mục chuẩn | 031, 032, 034 | use | 201 | 001, 006, 054, 056, 058, 059 |
| API-17-107 | `GET /suggestions` | Gợi ý của tôi và trạng thái | 035 | use | 200 | 001 |
| API-17-108 | `GET /suggestions/{suggestionId}` | Chi tiết gợi ý, điểm tin cậy, lý do | 032 | use | 200 | 001 |
| API-17-109 | `GET /suggestions/{suggestionId}/preview` | Xem trước thay đổi sẽ ghi vào bản nháp | 033 | use | 200 | 057, 070 |
| API-17-110 | `POST /suggestions/{suggestionId}:apply` | Áp dụng vào bản nháp bằng quyền người dùng | 033, 035, 048 | use | 200 | 001, 006, 056, 057, 064, 070, 084 |
| API-17-111 | `POST /suggestions/{suggestionId}:record-edit` | Ghi nhận người dùng sửa gợi ý rồi áp dụng | 035 | use | 200 | 001, 006 |
| API-17-112 | `POST /suggestions/{suggestionId}:reject` | Từ chối gợi ý | 035 | use | 200 | 001, 006 |

: Danh mục API nhóm Gợi ý ánh xạ

### 3.6. Giải thích sự cố

Giải thích mã lỗi, vết, bản tin DLQ, danh sách kiểm khắc phục, tóm tắt sự cố, xem trước che log (FR-17-036…041). Nhóm có 7 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-113 | `POST /explanations/error-codes` | Giải thích mã lỗi đang hiển thị | 036 | use | 201 | 001, 003, 011, 021, 022, 023 |
| API-17-114 | `POST /explanations/traces` | Giải thích lỗi theo `trace_id` | 037 | use | 201 | 009, 060, 061, 062 |
| API-17-115 | `POST /explanations/dlq-messages` | Giải thích bản tin DLQ | 038 | use | 201 | 001, 009, 060 |
| API-17-116 | `GET /explanations/{explanationId}` | Lấy lại một lần giải thích | 036, 037, 038, 039, 040 | use | 200 | 001, 011, 060, 061, 062, 067 |
| API-17-117 | `POST /remediation-checklists` | Sinh danh sách kiểm khắc phục | 039 | use | 201 | 001, 021, 067 |
| API-17-118 | `POST /incident-summaries` | Tóm tắt sự cố cho báo cáo | 040 | use | 201 | 060, 062, 067 |
| API-17-119 | `POST /redaction:preview` | Xem trước nội dung log sau khi che | 041 | use | 200 | 009, 062 |

: Danh mục API nhóm Giải thích sự cố

### 3.7. Công cụ và an toàn

Công cụ chỉ đọc, nhật ký gọi công cụ, giới hạn, quy tắc lọc, danh sách trắng liên kết (FR-17-042…047). Nhóm có 11 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-120 | `GET /tools` | Danh mục công cụ và trạng thái bật | 042 | tool | 200 | 001, 063 |
| API-17-121 | `GET /tools/{toolCode}` | Chi tiết công cụ (API đích, scope, giới hạn) | 042 | tool | 200 | 001, 063 |
| API-17-122 | `PUT /tools/{toolCode}/enablement` | Bật hoặc tắt công cụ cho tenant | 042 | tool | 200 | 001, 004, 063 |
| API-17-123 | `GET /tools/calls` | Nhật ký gọi công cụ (đã che) | 043, 047 | tool / log-read | 200 | 060, 069, 070, 082 |
| API-17-124 | `PUT /tools/limits` | Đặt giới hạn lần gọi, thời gian, độ sâu | 047 | tool | 200 | 068, 069, 082 |
| API-17-125 | `GET /guardrails` | Liệt kê quy tắc lọc vào, ra | 044, 045, 046 | tool | 200 | 063, 065, 066, 067 |
| API-17-126 | `POST /guardrails` | Thêm quy tắc lọc | 045, 046 | tool | 201 | 003, 065, 066, 067 |
| API-17-127 | `PATCH /guardrails/{ruleId}` | Sửa, ngừng quy tắc lọc | 045, 046 | tool | 200 | 003, 065, 066, 067 |
| API-17-128 | `POST /guardrails/{ruleId}:test` | Thử quy tắc trên mẫu | 045, 046 | tool | 200 | 003, 065, 066, 067 |
| API-17-129 | `GET /guardrails/link-allowlist` | Danh sách trắng liên kết | 046 | tool | 200 | 067 |
| API-17-130 | `PUT /guardrails/link-allowlist` | Đặt danh sách trắng liên kết | 046 | tool | 200 | 003, 067 |

: Danh mục API nhóm Công cụ và an toàn

### 3.8. Quản trị AI

Chỉ dẫn hệ thống, bộ đánh giá, ca đỏ, cổng phát hành, phản hồi, chất lượng, sổ hệ thống AI, tập ẩn danh (FR-17-049…054, 062). Nhóm có 41 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-131 | `GET /prompt-templates` | Liệt kê mẫu chỉ dẫn hệ thống | 049 | eval | 200 | 005, 071 |
| API-17-132 | `POST /prompt-templates` | Tạo mẫu | 049 | eval | 201 | 005, 071, 072, 073 |
| API-17-133 | `GET /prompt-templates/{templateId}` | Chi tiết mẫu và các phiên bản | 049 | eval | 200 | 005, 071 |
| API-17-134 | `POST /prompt-templates/{templateId}/versions` | Soạn phiên bản mới | 049 | eval | 201 | 005, 071, 072, 073 |
| API-17-135 | `POST /prompt-versions/{versionId}:submit` | Gửi duyệt sau khi đánh giá đạt | 049 | eval | 200 | 005, 071, 072, 073 |
| API-17-136 | `POST /prompt-versions/{versionId}:approve` | Duyệt bốn mắt, kích hoạt | 049 | eval | 200 | 005, 071, 072, 073 |
| API-17-137 | `POST /prompt-versions/{versionId}:reject` | Từ chối, kèm lý do | 049 | eval | 200 | 005, 071, 072, 073 |
| API-17-138 | `POST /prompt-versions/{versionId}:retire` | Ngừng phiên bản | 049 | eval | 200 | 005, 071, 072, 073 |
| API-17-139 | `GET /eval-sets` | Liệt kê bộ đánh giá | 050 | eval | 200 | 074 |
| API-17-140 | `POST /eval-sets` | Tạo bộ đánh giá | 050 | eval | 201 | 072, 074, 076 |
| API-17-141 | `GET /eval-sets/{setId}` | Chi tiết bộ và các ca | 050 | eval | 200 | 074 |
| API-17-142 | `POST /eval-sets/{setId}/cases` | Thêm ca đánh giá | 050 | eval | 201 | 072, 074, 076 |
| API-17-143 | `PATCH /eval-cases/{caseId}` | Sửa ca đánh giá | 050 | eval | 200 | 072, 074, 076 |
| API-17-144 | `DELETE /eval-cases/{caseId}` | Ngừng ca đánh giá | 050 | eval | 204 | 072, 074, 076 |
| API-17-145 | `POST /eval-runs` | Chạy bộ đánh giá cho một đối tượng | 050 | eval | 202 | 072, 074, 076 |
| API-17-146 | `GET /eval-runs` | Liệt kê lượt đánh giá | 050 | eval | 200 | 074 |
| API-17-147 | `GET /eval-runs/{runId}` | Chi tiết lượt đánh giá | 050 | eval | 200 | 074 |
| API-17-148 | `GET /eval-runs/{runId}/results` | Kết quả từng ca | 050 | eval | 200 | 074 |
| API-17-149 | `GET /redteam-cases` | Liệt kê ca đỏ | 051 | eval | 200 | 075 |
| API-17-150 | `POST /redteam-cases` | Thêm ca đỏ | 051 | eval | 201 | 073, 075, 076 |
| API-17-151 | `PATCH /redteam-cases/{caseId}` | Sửa, ngừng ca đỏ | 051 | eval | 200 | 073, 075, 076 |
| API-17-152 | `POST /redteam-runs` | Chạy bộ ca đỏ | 051 | eval | 202 | 073, 075, 076 |
| API-17-153 | `GET /redteam-runs/{runId}` | Kết quả lượt chạy ca đỏ | 051 | eval | 200 | 075 |
| API-17-154 | `GET /release-gates/{subjectType}/{subjectId}` | Trạng thái cổng phát hành của mô hình hoặc prompt | 009, 049, 051 | eval | 200 | 005, 071, 075 |
| API-17-155 | `POST /feedback` | Gửi phản hồi cho một câu trả lời | 052 | use | 201 | 001, 003, 077 |
| API-17-156 | `GET /feedback` | Hàng xử lý phản hồi | 052 | feedback | 200 | 001 |
| API-17-157 | `GET /feedback/{feedbackId}` | Chi tiết phản hồi | 052 | feedback | 200 | 001 |
| API-17-158 | `POST /feedback/{feedbackId}:triage` | Phân loại, giao xử lý | 052 | feedback | 200 | 001, 003, 077 |
| API-17-159 | `POST /feedback/{feedbackId}:resolve` | Đóng phản hồi kèm kết luận | 052 | feedback | 200 | 001, 003, 077 |
| API-17-160 | `POST /feedback/{feedbackId}:promote-to-redteam` | Đưa phản hồi thành ca đỏ ứng viên | 051, 052 | feedback / eval | 200 | 001, 003, 073, 075, 076, 077 |
| API-17-161 | `GET /quality/metrics` | Chỉ số chất lượng theo thời gian | 053 | eval / feedback | 200 | 079, 082 |
| API-17-162 | `GET /quality/alerts` | Cảnh báo suy giảm | 053 | eval / feedback | 200 | 079, 082 |
| API-17-163 | `PUT /quality/thresholds` | Đặt ngưỡng cảnh báo | 053 | config | 200 | 079, 082 |
| API-17-164 | `GET /ai-system-records` | Sổ đăng ký hệ thống AI của tenant | 054 | admin | 200 | 078 |
| API-17-165 | `POST /ai-system-records` | Lập hồ sơ hệ thống AI | 054 | admin | 201 | 004, 078 |
| API-17-166 | `PATCH /ai-system-records/{recordId}` | Cập nhật hồ sơ | 054 | admin | 200 | 004, 078 |
| API-17-167 | `POST /ai-system-records/{recordId}:review` | Ghi nhận rà soát định kỳ | 054 | admin | 200 | 004, 078 |
| API-17-184 | `GET /eval-datasets` | Tập ẩn danh PH-09 đã gắn cho đánh giá | 062 | eval | 200 | 085 |
| API-17-185 | `POST /eval-datasets` | Gắn tập ẩn danh đã phát hành vào bộ đánh giá | 062 | eval | 201 | 003, 085, 086 |
| API-17-186 | `DELETE /eval-datasets/{linkId}` | Gỡ tập khỏi bộ đánh giá và xóa kết quả liên quan | 062 | eval | 204 | 003, 085, 086 |
| API-17-194 | `PUT /feedback/{feedbackId}` | Sửa phản hồi của chính mình trong 10 phút (chốt 27/11/2026) | 052 | use | 200 | 001, 003, 077 |

: Danh mục API nhóm Quản trị AI

### 3.9. Nhật ký và báo cáo

Nhật ký hội thoại đã che, phiếu truy cập, hạn lưu, gói bằng chứng, báo cáo sử dụng, tham số (FR-17-055…059). Nhóm có 16 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-168 | `GET /logs/conversations` | Tìm hội thoại trong nhật ký (siêu dữ liệu, chưa xem nội dung) | 055, 056 | log-read | 200 | 007, 079, 080, 083 |
| API-17-169 | `POST /logs/access-grants` | Khai báo lý do để xem nhật ký, cấp phiếu 60 phút | 056 | log-read | 201 | 007, 010, 079, 080 |
| API-17-170 | `GET /logs/access-grants` | Phiếu truy cập đã cấp | 056 | log-read | 200 | 007, 079, 080 |
| API-17-171 | `GET /logs/conversations/{conversationId}` | Xem nội dung đã che của một hội thoại (cần phiếu) | 056 | log-read | 200 | 007, 079, 080 |
| API-17-172 | `GET /logs/retention` | Hạn lưu và kết quả xóa gần nhất | 055 | log-read | 200 | 083 |
| API-17-173 | `POST /compliance-exports` | Yêu cầu gói bằng chứng tuân thủ | 057 | log-read | 202 | 007, 009, 081 |
| API-17-174 | `GET /compliance-exports` | Liệt kê gói đã tạo | 057 | log-read | 200 | 007, 081 |
| API-17-175 | `GET /compliance-exports/{exportId}` | Trạng thái gói | 057 | log-read | 200 | 007, 081 |
| API-17-176 | `GET /compliance-exports/{exportId}/download` | Tải gói đã ký | 057 | log-read | 200 | 007, 081 |
| API-17-177 | `GET /reports/usage` | Báo cáo sử dụng theo lượt, token, chi phí ước tính | 058 | admin / log-read | 200 | 079 |
| API-17-178 | `GET /reports/usage/export` | Xuất báo cáo sử dụng | 058 | admin / log-read | 202 | 079 |
| API-17-179 | `GET /reports/usage:feed` | Số liệu sử dụng cho PH-16 | 058 | s:assist:report | 200 | 079 |
| API-17-180 | `GET /settings` | Danh sách tham số `17.*` và giá trị hiệu lực | 059 | config / admin | 200 | 018, 082, 083, 084 |
| API-17-181 | `GET /settings/schema` | Khóa, miền, mặc định, trần, sàn | 059 | config / admin | 200 | 018, 082, 083, 084 |
| API-17-182 | `PUT /settings/{key}` | Đặt giá trị tham số | 059 | config | 200 | 009, 013, 018, 082, 083, 084 |
| API-17-183 | `POST /settings/{key}:reset` | Đưa tham số về mặc định | 059 | config | 200 | 009, 013, 018, 082, 083, 084 |

: Danh mục API nhóm Nhật ký và báo cáo

### 3.10. Data plane

Suy luận nội bộ cho PH-04, gợi ý bước quy trình cho PH-11, cấu hình hiệu lực, sẵn sàng; chỉ trong cụm (FR-17-060, 061). Nhóm có 7 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-17-187 | `POST /assist/v1/inference/classify` | Phân loại văn bản cho bước luồng PH-04 | 060 | s:assist:infer | 200 | 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 115, 118 |
| API-17-188 | `POST /assist/v1/inference/extract` | Trích thông tin có cấu trúc từ văn bản cho bước luồng PH-04 | 060 | s:assist:infer | 200 | 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 115, 118 |
| API-17-189 | `GET /assist/v1/inference/tasks` | Danh sách nhiệm vụ hỗ trợ và phiên bản lược đồ | 060 | s:assist:infer | 200 | 101, 102, 103, 104, 105, 106, 107, 113, 115 |
| API-17-190 | `POST /assist/v1/process-suggestions` | Gợi ý cho bước quy trình PH-11 | 061 | s:assist:infer | 201 | 107, 114, 117, 118 |
| API-17-191 | `POST /assist/v1/process-suggestions/{suggestionId}:record-decision` | PH-11 báo quyết định cuối của người | 061 | s:assist:infer | 200 | 107, 114, 117, 118 |
| API-17-192 | `GET /assist/v1/config/effective` | Cấu hình hiệu lực của tenant (bật, năng lực, mô hình) cho DU gọi | 060, 061 | s:assist:infer | 200 | 101, 102, 103, 104, 105, 106, 107, 113, 114, 115, 117 |
| API-17-193 | `GET /assist/v1/health/ready` | Kiểm tra sẵn sàng của data plane | 014, 060 | mTLS DU | 200 | 101, 102, 103, 104, 105, 106, 107, 113, 115 |

: Danh mục API nhóm Data plane
<!-- gen:catalog:end -->

## 4. Danh mục sự kiện

### 4.1. Sự kiện của PH-17

Sự kiện phát qua Kafka theo mẫu outbox (ADR-042, DD-11), phong bì CloudEvents, khóa phân vùng `tenantId`, topic `{tenant}.assist.<tên>.v1`. Dữ liệu sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm: `CHECK` ở `outbox_event` chặn khóa nội dung (D03-03-PH17 §1.5).

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Bên tiêu thụ | Trường dữ liệu |
|---|---|---|---|---|
| EVT-17-01 | `{tenant}.assist.config.changed.v1` | Chính sách, năng lực, hạn mức, tham số `17.*`, danh sách trắng nhà cung cấp, công cụ hoặc bộ lọc đổi | `dh-assist` các bản sao, `dh-console`, PH-13 | `changeKind`, `settingKey`, `changedBy`, `version` |
| EVT-17-02 | `{tenant}.assist.enablement.changed.v1` | Trợ lý được bật hoặc tắt cho tenant | `dh-console` (ẩn hiện nút), PH-03, PH-13 | `state`, `changeId`, `decidedBy`, `capabilities` |
| EVT-17-03 | `{tenant}.assist.kill-switch.changed.v1` | Tắt khẩn được kích hoạt, hoặc gỡ (tenant hoặc nền tảng) | `dh-assist`, PH-03, PH-04, PH-11, PH-13 | `scope`, `active`, `recordId`, `activatedBy`, `releasedBy` |
| EVT-17-04 | `{tenant}.assist.policy-change.decided.v1` | Đề nghị đổi chính sách được duyệt hoặc từ chối | PH-13, Việc của tôi của người đề nghị | `changeId`, `changeType`, `state`, `requestedBy`, `decidedBy` |
| EVT-17-05 | `{tenant}.assist.notice.published.v1` | Phiên bản điều khoản dùng AI mới được công bố | `dh-console` (yêu cầu xác nhận lại), PH-13 | `noticeId`, `versionNo`, `publishedAt` |
| EVT-17-06 | `{tenant}.assist.provider.state-changed.v1` | Nhà cung cấp mô hình đổi trạng thái (kích hoạt, đình chỉ, hết hạn cam kết) | PH-03, PH-13, SO | `providerId`, `providerCode`, `from`, `to` |
| EVT-17-07 | `{tenant}.assist.model-version.state-changed.v1` | Phiên bản mô hình đổi trạng thái (đánh giá, duyệt, ngừng) | PH-13, `dh-console`, SO | `versionId`, `modelId`, `versionNo`, `from`, `to`, `evalRunId`, `redteamRunId` |
| EVT-17-08 | `{tenant}.assist.route.sync-requested.v1` | Cấu hình tuyến egress cần đồng bộ vào APISIX | PH-03 | `runId`, `versionIds`, `requestedBy` |
| EVT-17-09 | `{tenant}.assist.route.sync-completed.v1` | PH-03 báo đã áp hoặc từ chối cấu hình tuyến | `dh-assist`, PH-13 | `runId`, `result`, `snapshotRef`, `errorCode` |
| EVT-17-10 | `{tenant}.assist.model.health-changed.v1` | Mô hình đổi trạng thái sức khỏe (`UP`, `DEGRADED`, `DOWN`) | PH-13, TA, TO | `versionId`, `from`, `to`, `consecutiveFailures` |
| EVT-17-11 | `{tenant}.assist.breaker.state-changed.v1` | Cầu dao mở hoặc đóng lại | PH-13, TO | `routeId`, `versionId`, `breakerState`, `failureCount` |
| EVT-17-12 | `{tenant}.assist.quota.threshold-reached.v1` | Hạn mức tenant chạm 80% hoặc 100% | PH-13, TA | `scopeKind`, `threshold`, `tokensUsed`, `tokensLimit` |
| EVT-17-13 | `{tenant}.assist.source.state-changed.v1` | Nguồn tri thức được khai báo, tạm dừng, ngừng | PH-13, UI-17-08 | `sourceId`, `sourceCode`, `sourceType`, `state` |
| EVT-17-14 | `{tenant}.assist.index.completed.v1` | Lượt lập chỉ mục hoàn tất (kèm số đoạn thêm, xóa, bỏ qua) | PH-13, UI-17-08 | `jobId`, `sourceId`, `chunksAdded`, `chunksDeleted`, `chunksSkipped` |
| EVT-17-15 | `{tenant}.assist.index.failed.v1` | Lượt lập chỉ mục thất bại sau khi thử lại | PH-13, TA, DS | `jobId`, `sourceId`, `attempt`, `errorCode` |
| EVT-17-16 | `{tenant}.assist.index.purged.v1` | Xóa lan truyền đoạn khỏi chỉ mục xong | PH-13, SO | `sourceId`, `documentId`, `reason`, `chunksDeleted` |
| EVT-17-17 | `{tenant}.assist.upload.state-changed.v1` | Tài liệu tải lên gửi duyệt, được duyệt, từ chối, ngừng | Việc của tôi của người duyệt, PH-13 | `documentId`, `from`, `to`, `uploadedBy`, `decidedBy` |
| EVT-17-18 | `{tenant}.assist.suggestion.decided.v1` | Người dùng chấp nhận, sửa hoặc từ chối một gợi ý | PH-13, bộ chỉ số chất lượng FR-17-053 | `suggestionId`, `suggestionKind`, `status`, `userId` |
| EVT-17-19 | `{tenant}.assist.guardrail.violation-detected.v1` | Bộ lọc chặn ca tiêm lệnh, đầu ra lộ bí mật hoặc DLCN | PH-13, SO (cảnh báo) | `guardrailKind`, `ruleCode`, `action`, `category`, `messageId` |
| EVT-17-20 | `{tenant}.assist.prompt.state-changed.v1` | Phiên bản chỉ dẫn hệ thống đổi trạng thái | PH-13, `dh-assist` | `versionId`, `templateId`, `versionNo`, `from`, `to` |
| EVT-17-21 | `{tenant}.assist.eval.run-completed.v1` | Lượt chạy bộ đánh giá hoàn tất | PH-13, người đề nghị | `runId`, `subjectType`, `subjectId`, `status`, `casesTotal`, `casesPassed`, `score` |
| EVT-17-22 | `{tenant}.assist.redteam.run-completed.v1` | Lượt chạy bộ ca đỏ hoàn tất (kèm số ca lọt) | PH-13, SO, cổng phát hành | `runId`, `subjectType`, `subjectId`, `status`, `casesTotal`, `casesLeaked` |
| EVT-17-23 | `{tenant}.assist.feedback.submitted.v1` | Người dùng gửi phản hồi, hoặc phản hồi đổi trạng thái | PH-13, hàng xử lý UI-17-14 | `feedbackId`, `feedbackKind`, `status`, `messageId` |
| EVT-17-24 | `{tenant}.assist.quality.alert-raised.v1` | Chỉ số chất lượng suy giảm vượt ngưỡng | PH-13, TA, SO | `metricCode`, `capability`, `metricValue`, `threshold`, `raisedAt` |
| EVT-17-25 | `{tenant}.assist.log.access-granted.v1` | Phiếu truy cập nhật ký hội thoại được cấp | PH-13 | `grantId`, `grantee`, `scopeKind`, `expiresAt` |
| EVT-17-26 | `{tenant}.assist.export.ready.v1` | Gói bằng chứng tuân thủ hoặc báo cáo xuất xong | Người yêu cầu, PH-13 | `exportId`, `exportKind`, `state`, `sha256`, `expiresAt` |
| EVT-17-27 | `{tenant}.assist.log.purged.v1` | Tác vụ xóa nhật ký hết hạn chạy xong (kèm số hội thoại xóa) | PH-13 | `purgedConversations`, `purgedMessages`, `retentionDays`, `runAt` |
| EVT-17-28 | `{tenant}.assist.process-suggestion.decided.v1` | PH-11 báo người có thẩm quyền đã quyết định về một gợi ý bước quy trình | PH-13, bộ chỉ số chất lượng | `suggestionId`, `decision`, `processRef` |

: Danh mục sự kiện của PH-17
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Phát ít nhất một lần; bên tiêu thụ khử trùng theo `id` của phong bì (bảng `inbox_event`) và xử lý lũy đẳng. Sắp thứ tự theo khóa phân vùng `tenantId` trong một phân vùng; không đảm bảo thứ tự giữa các tenant. Bên tiêu thụ xử lý lỗi theo hướng dẫn vận hành của PH-18. Phiên bản lược đồ nằm ở hậu tố topic.

### 4.3. Sự kiện PH-17 tiêu thụ

PH-17 tiêu thụ sự kiện của PH-02, 03, 04, 07, 09, 10 để lập chỉ mục và xóa lan truyền; danh sách topic ở FRS §9.3b, không lặp lại ở đây. Hợp đồng sự kiện của các phân hệ đó do tài liệu API của phân hệ tương ứng giữ; tên topic PH-02, 04, 07, 10 chưa chốt nên được ghi là giả định ở FRS (Q17-08).

## 5. Hợp đồng với phân hệ khác và bên ngoài

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| PH-03 (APISIX) | Ra | Đồng bộ tuyến `ai-proxy` theo EVT-17-08, nhận kết quả EVT-17-09; mọi lời gọi mô hình ra đi qua tuyến egress tới đích đã khai báo | SEC-16; Q17-10 |
| PH-04 | Vào | API-17-187…189 (phân loại, trích thông tin) bằng DU và scope `assist:infer` | FR-17-060 |
| PH-11 | Vào | API-17-190, 191 (gợi ý bước quy trình, báo quyết định) | FR-17-061; Q17-22 |
| PH-02, 04, 07, 10 | Ra | Công cụ chỉ đọc gọi API đọc bằng token của người hỏi (token exchange, `act` = `dh-assist`) | BR-17-056, 057; Q17-07, 11 |
| PH-09 | Ra, vào | Kiểm mức phân loại khi lập chỉ mục; nhận EVT-09-01, 03, 18 | FR-17-016, 062 |
| PH-12 | Ra | Token exchange RFC 8693; scope `assist:infer` cho mTLS data plane | Q17-07 |
| PH-13 | Ra | Mọi sự kiện kiểm toán `assist.*`; tra nhật ký có lý do (API-17-168…171) | FR-17-013, 055, 056 |
| PH-16 | Vào | API-17-179 (số liệu sử dụng) bằng scope `assist:report` | FR-17-058 |
| PH-18 | Ra | Khóa `17.*` ở DD-14, ERR catalog | FR-17-059; Q17-09 |
| Nhà cung cấp mô hình ngoài | Ra | Chỉ qua tuyến egress APISIX, đích trong danh sách trắng, bí mật ở OpenBao | BR-17-004, 012 |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-17

Mọi mã có ở FRS §9.1; cột "Dùng ở API" nêu operation mà mã này là lỗi riêng, mã cấu trúc (mục 6.2) ghi theo nhóm.

<!-- gen:errors:start -->
| Mã | HTTP | Thông báo | Dùng ở API |
|---|---|---|---|
| ERR-17-001 | 404, 410 | Không tìm thấy {đối tượng} {mã}. | Mọi `GET` bản ghi và hành động theo mã |
| ERR-17-002 | 409 | Mã {mã} đã được dùng. Chọn mã khác. | Thao tác tạo có mã nghiệp vụ |
| ERR-17-003 | 400 | Dữ liệu không hợp lệ: {chi tiết}. | Mọi thao tác có thân |
| ERR-17-004 | 409 | Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới. | Mọi `PUT`, `PATCH`, hành động có `If-Match` |
| ERR-17-005 | 403 | Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này. | Thao tác duyệt, từ chối bốn mắt |
| ERR-17-006 | 409 | Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này. | Mọi hành động chuyển trạng thái |
| ERR-17-007 | 422 | Nhập lý do tối thiểu 20 ký tự. | Thao tác cần lý do |
| ERR-17-008 | 403 | Trợ lý AI chưa được bật cho tỉnh của bạn. | 001…006 … |
| ERR-17-009 | 503 | Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút. | Thao tác gọi dịch vụ ngoài |
| ERR-17-010 | 503 | Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau. | Mọi thao tác ghi |
| ERR-17-011 | 403 | Năng lực {tên} chưa được bật cho vai trò của bạn. | 001, 002, 009, 095, 096, 099 … |
| ERR-17-012 | 403 | Trợ lý AI đang tạm ngừng khẩn cấp. Liên hệ quản trị tỉnh. | 003, 006, 020…023 … |
| ERR-17-013 | 409 | Đang có đề nghị cùng loại chờ duyệt. Xử lý đề nghị đó trước. | 003, 006…008, 011, 012 … |
| ERR-17-014 | 422 | Bật trợ lý cần số quyết định của lãnh đạo tỉnh và lý do. | 001…006 … |
| ERR-17-015 | 422 | Chọn ít nhất một năng lực và một nhóm vai trò. | 001…006 … |
| ERR-17-016 | 422 | Mô hình ngoài chỉ dùng được khi nhà cung cấp có cam kết lưu dữ liệu trong nước và không huấn luyện còn hiệu lực. | 003, 006, 010…012, 032 |
| ERR-17-017 | 409 | Nhà cung cấp {tên} chưa nằm trong danh sách trắng của tỉnh. | 003, 006, 011, 012, 032, 045 … |
| ERR-17-018 | 422 | Giá trị {khóa} vượt trần {n} do nền tảng đặt. | 002, 003, 006, 013…015 … |
| ERR-17-019 | 422 | Câu hỏi dài hơn {n} ký tự. Rút gọn rồi gửi lại. | 002, 013…015, 095, 096 … |
| ERR-17-020 | 403 | Bạn cần xác nhận điều khoản dùng AI trước khi sử dụng trợ lý. | 001, 015…019 … |
| ERR-17-021 | 429 | Bạn đã dùng hết {n} lượt hôm nay. Thử lại sau {thời điểm}. | 014, 095, 096, 099, 104, 105 … |
| ERR-17-022 | 429 | Tỉnh đã dùng hết hạn mức hôm nay. Liên hệ quản trị tỉnh. | 014, 095, 096, 099, 104, 105 … |
| ERR-17-023 | 429 | Bạn gửi quá nhanh. Thử lại sau {n} giây. | 014, 095, 096, 099, 104, 105 … |
| ERR-17-024 | 409 | Điều khoản phiên bản {v} đã công bố, không sửa được. Tạo phiên bản mới. | 017, 019 |
| ERR-17-025 | 422 | Điểm cuối phải là địa chỉ HTTPS theo tên miền trong nước đã khai báo. | 026…031 … |
| ERR-17-026 | 422 | Thiếu hồ sơ cam kết lưu dữ liệu trong nước và không huấn luyện. | 026…031 … |
| ERR-17-027 | 409 | Nhà cung cấp {tên} đang được {n} mô hình sử dụng nên không ngừng được. | 027, 029…032 |
| ERR-17-028 | 422 | Tham chiếu bí mật {tham chiếu} không tồn tại hoặc không đọc được. | 026…031 … |
| ERR-17-029 | 409 | Phiên bản mô hình chưa đạt điều kiện duyệt: {điều kiện}. | 037, 040…043 |
| ERR-17-030 | 409 | Phiên bản mô hình chưa được duyệt nên chưa dùng được. | 030, 037, 040…043 … |
| ERR-17-031 | 422 | Mô hình {tên} không hỗ trợ năng lực {năng lực}. | 033…038 … |
| ERR-17-032 | 422 | Nội dung vượt giới hạn ngữ cảnh {n} token của mô hình. | 044…048 |
| ERR-17-033 | 409 | Chưa có mô hình mặc định loại {loại} được duyệt cho tỉnh. | 003, 006…008, 045, 046 … |
| ERR-17-034 | 409 | Mô hình dự phòng phải cùng loại, đã duyệt, và không chuyển từ mô hình nội bộ sang mô hình ngoài. | 045…047 |
| ERR-17-035 | 503 | Chưa đồng bộ được tuyến mô hình sang cổng API. Thử lại sau. | 049 |
| ERR-17-036 | 503 | Mô hình đang quá tải hoặc tạm ngắt. Thử lại sau ít phút. | 045…047, 053, 055, 078 … |
| ERR-17-037 | 429 | Cổng mô hình đang giới hạn tần suất. Thử lại sau {n} giây. | 053, 055 |
| ERR-17-038 | 504 | Mô hình không phản hồi trong {n} giây. | 030, 053, 055, 060, 095, 096 … |
| ERR-17-039 | 422 | Đích {tên miền} không nằm trong danh sách egress được phép. | 026…031 … |
| ERR-17-040 | 409 | Phiên bản mô hình đã ngừng, không thay đổi được. | 034, 036, 037, 039 |
| ERR-17-041 | 422 | Loại nguồn {loại} không hợp lệ hoặc chưa hỗ trợ. | 062…067 … |
| ERR-17-042 | 409 | Nguồn tri thức {mã} đã được khai báo. | 063, 065…068 |
| ERR-17-043 | 422 | Dữ liệu mức {mức} không được lập chỉ mục. Chỉ nhận dữ liệu Công khai và Nội bộ. | 070, 071, 081…084 … |
| ERR-17-044 | 409 | Đang có lượt lập chỉ mục cho nguồn này. Chờ lượt hiện tại xong. | 069, 074, 075 |
| ERR-17-045 | 422 | Tệp {tên} không đúng định dạng cho phép hoặc vượt {n} MB. | 081…086 … |
| ERR-17-046 | 422 | Tệp có dấu hiệu chứa dữ liệu cá nhân hoặc mã độc nên không được nhận. | 076…078, 081…083 … |
| ERR-17-047 | 409 | Tài liệu đang được lập chỉ mục. Thử lại sau. | 068, 078, 079 |
| ERR-17-048 | 409 | Chưa có mô hình nhúng được duyệt nên chưa lập chỉ mục được. | 063, 065…069 … |
| ERR-17-049 | 422 | Không xác nhận được mức phân loại của {đối tượng} nên bỏ qua lập chỉ mục. | 069…074 … |
| ERR-17-050 | 409 | Hội thoại đã đạt giới hạn {n} lượt. Mở hội thoại mới. | 093, 094 |
| ERR-17-051 | 409 | Bạn đã có {n} hội thoại. Xóa bớt trước khi mở thêm. | 090, 103 |
| ERR-17-052 | 422 | Ngữ cảnh màn hình không hợp lệ. | 001, 015, 090, 092, 098, 103 |
| ERR-17-053 | 409 | Câu trả lời đã hoàn tất hoặc đã bị hủy. | 096, 097 |
| ERR-17-054 | 422 | Chưa đủ lược đồ để gợi ý. Chọn ít nhất một trường nguồn và một trường đích. | 095, 104…106 |
| ERR-17-055 | 422 | Biểu thức {biểu thức} không hợp lệ: {lý do}. | 095, 104, 105 |
| ERR-17-056 | 409 | Gợi ý đã hết hạn hoặc bản nháp đã thay đổi. Tạo gợi ý mới. | 104, 106, 110 |
| ERR-17-057 | 403 | Bạn không có quyền sửa bản nháp này ở {tên phân hệ}. | 109, 110 |
| ERR-17-058 | 422 | Mã {mã} không có trong danh mục chuẩn {danh mục}. | 106 |
| ERR-17-059 | 422 | Dữ liệu mẫu chứa giá trị chưa che. Che dữ liệu rồi gửi lại. | 095, 104…106 |
| ERR-17-060 | 403 | Bạn không có quyền xem dữ liệu này nên trợ lý không giải thích được. | 114…116, 118, 123 |
| ERR-17-061 | 422 | Mã vết {mã} không đúng định dạng. | 114, 116 |
| ERR-17-062 | 422 | Chọn không quá {n} dòng log hoặc khoảng thời gian không quá {m} phút. | 114, 116, 118, 119 |
| ERR-17-063 | 403 | Công cụ {mã} chưa được bật cho tỉnh. | 095, 120…122, 125 |
| ERR-17-064 | 503 | Chưa lấy được quyền truy cập thay mặt bạn. Đăng nhập lại và thử lại. | 095, 099, 110 |
| ERR-17-065 | 422 | Câu hỏi bị từ chối vì có dấu hiệu tiêm lệnh hoặc nội dung không được phép. | 095, 125…128 |
| ERR-17-066 | 422 | Câu hỏi chứa dữ liệu cá nhân nhạy cảm. Bỏ dữ liệu đó rồi hỏi lại. | 095, 125…128 |
| ERR-17-067 | 422 | Câu trả lời bị chặn vì có thể lộ dữ liệu nhạy cảm. | 095…097, 099, 116, 117 … |
| ERR-17-068 | 504 | Lượt hỏi vượt thời gian tối đa {n} giây. Thử lại với câu hỏi ngắn hơn. | 095, 096, 099, 124 |
| ERR-17-069 | 422 | Công cụ vượt giới hạn {n} lần gọi mỗi lượt. | 123, 124 |
| ERR-17-070 | 403 | Trợ lý chỉ đọc. Thao tác ghi phải do bạn xác nhận trên thẻ đề xuất. | 095, 096, 109, 110, 123 |
| ERR-17-071 | 422 | Chỉ dẫn hệ thống chứa nội dung không được phép: {lý do}. | 131…136 … |
| ERR-17-072 | 409 | Chưa đạt cổng phát hành: {lý do}. | 132, 134…138 … |
| ERR-17-073 | 409 | Ca đỏ {mã} chưa bị chặn nên không phát hành được. | 037, 040…043, 132 … |
| ERR-17-074 | 422 | Bộ đánh giá cần tối thiểu {n} ca. | 139…144 … |
| ERR-17-075 | 422 | Bộ ca đỏ cần tối thiểu 50 ca đang hoạt động. | 149…154 … |
| ERR-17-076 | 409 | Đang có lượt đánh giá chạy cho đối tượng này. | 140, 142…145, 150 … |
| ERR-17-077 | 409 | Bạn đã gửi phản hồi cho câu trả lời này. | 155, 158…160, 194 |
| ERR-17-078 | 422 | Hồ sơ hệ thống AI thiếu mục: {mục}. | 164…167 |
| ERR-17-079 | 422 | Chọn khoảng thời gian tối đa {n} ngày. | 056…058, 064, 072, 073 … |
| ERR-17-080 | 403 | Chưa có phiếu truy cập nhật ký còn hiệu lực. Khai báo lý do để xem. | 168…171 |
| ERR-17-081 | 410 | Gói bằng chứng đã hết hạn tải. Tạo lại gói mới. | 173…176 |
| ERR-17-082 | 422 | Giá trị tham số {khóa} nằm ngoài miền {miền}. | 003, 006, 123, 124, 161, 162 … |
| ERR-17-083 | 422 | Thời hạn lưu nhật ký không được thấp hơn 90 ngày. | 003, 006, 168, 172, 180, 181 … |
| ERR-17-084 | 422 | Khóa tham số {khóa} không tồn tại. | 003, 006, 095, 096, 110, 180 … |
| ERR-17-085 | 422 | Tập dữ liệu {mã} chưa phát hành hoặc đã hết hạn ở quyền riêng tư. | 184…186 |
| ERR-17-086 | 409 | Tập dữ liệu {mã} chưa đạt k tối thiểu nên không dùng được. | 185, 186 |
| ERR-17-087 | 409 | Khóa Idempotency-Key đã được dùng với nội dung khác. | Mọi `POST` đổi dữ liệu có `Idempotency-Key` |
| ERR-17-101 | 403 | Dịch vụ gọi chưa có quyền suy luận (assist:infer). | 187…189, 192, 193 |
| ERR-17-102 | 422 | Thiếu mục đích khai thác hoặc mức dữ liệu của yêu cầu. | 187…189, 192, 193 |
| ERR-17-103 | 403 | Trợ lý AI đã tắt cho tenant này. | 187…189, 192, 193 |
| ERR-17-104 | 403 | Tắt khẩn cấp đang có hiệu lực. | 187…189, 192, 193 |
| ERR-17-105 | 422 | Nhiệm vụ {tên} không được hỗ trợ. | 187…189, 192, 193 |
| ERR-17-106 | 422 | Đầu vào không đúng lược đồ của nhiệm vụ: {chi tiết}. | 187…189, 192, 193 |
| ERR-17-107 | 422 | Dữ liệu mức {mức} không được gửi tới mô hình ngoài. | 187…192 … |
| ERR-17-108 | 409 | Chưa có mô hình được duyệt cho nhiệm vụ {tên}. | 187, 188 |
| ERR-17-109 | 429 | Dịch vụ gọi đã vượt hạn mức suy luận. | 187, 188 |
| ERR-17-110 | 503 | Mô hình tạm ngắt do cầu dao. | 187, 188 |
| ERR-17-111 | 504 | Mô hình không phản hồi kịp. | 187, 188 |
| ERR-17-112 | 502 | Mô hình trả kết quả không đúng lược đồ. | 187, 188 |
| ERR-17-113 | 422 | Đầu vào quá dài, tối đa {n} ký tự. | 187…189, 192, 193 |
| ERR-17-114 | 403 | Gợi ý quy trình luôn cần người quyết định; yêu cầu tự quyết bị từ chối. | 190…192 |
| ERR-17-115 | 422 | Đầu vào chứa mẫu dữ liệu cá nhân chưa che. | 187…189, 192, 193 |
| ERR-17-116 | 409 | Tập dữ liệu {mã} không còn hiệu lực. | Theo FR liên quan |
| ERR-17-117 | 404 | Không tìm thấy gợi ý {mã}. | 190…192 |
| ERR-17-118 | 503 | Không ghi được vết lời gọi nên yêu cầu bị từ chối. | 187, 188, 190, 191 |

: Bảng mã lỗi ERR-17
<!-- gen:errors:end -->

### 6.1. Thân lỗi

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-17-065",
  "title": "Câu hỏi bị từ chối vì có dấu hiệu tiêm lệnh hoặc nội dung không được phép.",
  "status": 422,
  "code": "ERR-17-065",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{"field": "content", "message": "Nội dung không được phép"}]
}
```

: Thân lỗi RFC 9457 của PH-17

`title` là thông báo hiển thị của FRS §9.1, `detail` (nếu có) là chi tiết kỹ thuật không chứa nội dung hội thoại, đoạn tri thức hay bí mật. Khi lỗi xảy ra giữa chừng luồng SSE, máy chủ gửi sự kiện `message.error` mang cùng thân rồi đóng luồng.

### 6.2. Quy tắc áp mã cấu trúc

| Mã | Gắn ở |
|---|---|
| ERR-17-001 | Mọi `GET`, hành động có tham số đường dẫn |
| ERR-17-003 | Mọi thao tác có thân |
| ERR-17-004 | Mọi `PUT`, `PATCH`, hành động có `If-Match` |
| ERR-17-005 | Hành động `:approve`, `:approve-release`, `:reject` |
| ERR-17-006 | Mọi hành động đổi trạng thái |
| ERR-17-007 | Thao tác nhận `reason` |
| ERR-17-010 | Mọi thao tác ghi (không ghi được kiểm toán thì từ chối) |
| ERR-17-087 | Mọi `POST` có `Idempotency-Key` |

: Quy tắc áp mã lỗi cấu trúc

## 7. Kiểm tra hợp đồng trong CI

| Kiểm tra | Công cụ | Điều kiện đạt |
|---|---|---|
| Cú pháp, khóa trùng, khóa rỗng | `build/tools/kiem_tra_yaml.py` | 0 lỗi |
| OpenAPI 3.1 và AsyncAPI 3.0 hợp lệ | Spectral 6.17.1 với `build/tools/spectral.yaml`, `--fail-severity=error` | 0 lỗi |
| Hợp đồng PH-17 | [`ph17/tools/check_contracts.py`](ph17/tools/check_contracts.py) | `$ref` đủ đích; mã API đúng 194, không trùng và khớp FRS; ví dụ khớp lược đồ; enum khớp Phụ lục A; đủ 28 kênh đúng địa chỉ; không khóa nội dung hay bí mật ở sự kiện |
| Mã trong tài liệu | `build/tools/kiem_tra_ma.py` | Không trùng mã; cảnh báo `PERM-17-*` còn cho tới khi D02-08 đồng bộ |
| Thay đổi phá vỡ | `oasdiff breaking` với nhánh chính (CI) | Không có thay đổi phá vỡ trong `v1` |
| Cô lập tenant | `TenantIsolationIT` cho mọi API đọc (D05-02-PH17) | 0 truy vấn đọc được dữ liệu tenant khác (NFR-17-007) |

: Kiểm tra hợp đồng của API PH-17

Chạy ngày 26/11/2026: `check_contracts.py` sạch (193 operation, 15 ví dụ OpenAPI, 28 kênh, 246 lược đồ), Spectral 6.17.1 không lỗi (còn cảnh báo kiểu tài liệu của AsyncAPI như thiếu `contact`), `kiem_tra_yaml.py` không lỗi.

## 8. Ánh xạ từ hệ cũ

### 8.1. API của SRS cũ

SRS cũ (`docs/07-srs/SRS-PH-17-ai.md` §5) là cổng AI nền tảng có MLflow và Evidently; mã API cũ không còn hiệu lực (FRS 11.3).

| Nhóm API cũ | API mới | Ghi chú |
|---|---|---|
| Điểm cuối suy luận | API-17-187, 188, 190 (data plane) | Chỉ cho DU gọi; không còn suy luận trực tiếp của người dùng ngoài trợ lý |
| HITL (phiếu duyệt quyết định) | API-17-110, 111, 112 (áp dụng, sửa, từ chối gợi ý) | Người quyết định cuối là người dùng; quyết định của PH-11 báo qua API-17-191 |
| Quản trị mô hình, phiên bản | API-17-026…043 | Bỏ MLflow, Evidently; thêm bốn mắt và cổng phát hành |
| Nhật ký quyết định | API-17-056…058, 168…172 | Đã che, giữ 90 ngày, có phiếu truy cập |
| Định tuyến, ACL mô hình | API-17-044…055 | Thành bật mô hình theo tenant và tuyến egress |

: Ánh xạ API của SRS cũ sang API mới

### 8.2. Hệ Viettel 2021 và CSDL quốc gia

Hệ cũ không có năng lực AI (REQ-17 là năng lực mới) nên không có API cũ cần chuyển đổi.

## 9. Truy vết FR sang API

<!-- gen:fr:start -->
| FR | API | FR | API |
|---|---|---|---|
| FR-17-001 | 001…008 | FR-17-032 | 104, 106, 108 |
| FR-17-002 | 001, 002, 009 | FR-17-033 | 109, 110 |
| FR-17-003 | 003, 006, 010…012, 032 | FR-17-034 | 104, 106 |
| FR-17-004 | 002, 013…015 | FR-17-035 | 107, 110…112 |
| FR-17-005 | 001, 016…019 | FR-17-036 | 095, 113, 116 |
| FR-17-006 | 003, 006, 020…025 | FR-17-037 | 114, 116 |
| FR-17-007 | 026…032 | FR-17-038 | 115, 116 |
| FR-17-008 | 033…039 | FR-17-039 | 116, 117 |
| FR-17-009 | 037, 038, 040…043, 154 | FR-17-040 | 116, 118 |
| FR-17-010 | 044…048 | FR-17-041 | 119 |
| FR-17-011 | 048…051 | FR-17-042 | 120…122 |
| FR-17-012 | 052…055 | FR-17-043 | 123 |
| FR-17-013 | 056…058 | FR-17-044 | 095, 125 |
| FR-17-014 | 030, 059…061, 193 | FR-17-045 | 095, 125…128 |
| FR-17-015 | 062…068 | FR-17-046 | 125…130 |
| FR-17-016 | 070, 071 | FR-17-047 | 123, 124 |
| FR-17-017 | 069, 072…075 | FR-17-048 | 095, 096, 110 |
| FR-17-018 | 076…078 | FR-17-049 | 131…138, 154 |
| FR-17-019 | 068, 079, 080 | FR-17-050 | 139…148 |
| FR-17-020 | 081…087 | FR-17-051 | 149…154, 160 |
| FR-17-021 | 064, 072, 073, 076, 088, 089 | FR-17-052 | 155…160, 194 |
| FR-17-022 | 001, 015, 090, 092, 098, 103 | FR-17-053 | 161…163 |
| FR-17-023 | 095, 096, 099 | FR-17-054 | 164…167 |
| FR-17-024 | 095, 099 | FR-17-055 | 168, 172 |
| FR-17-025 | 095, 099 | FR-17-056 | 168…171 |
| FR-17-026 | 096, 097 | FR-17-057 | 173…176 |
| FR-17-027 | 091…094, 098 | FR-17-058 | 177…179 |
| FR-17-028 | 100…102 | FR-17-059 | 003, 006, 180…183 |
| FR-17-029 | 090, 103 | FR-17-060 | 187…189, 192, 193 |
| FR-17-030 | 095, 104, 105 | FR-17-061 | 190…192 |
| FR-17-031 | 106 | FR-17-062 | 184…186 |

: Truy vết FR-17-001…062 sang API-17
<!-- gen:fr:end -->

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### 10.1. Với FRS

Tập này không sửa FRS; các điểm sau là đề nghị cho chủ tài liệu.

| Số | Nội dung | Đề nghị |
|---|---|---|
| 1 | FRS §9.4 không nêu mã thành công và lược đồ thân của từng operation | Giữ OpenAPI là nguồn cho hai nội dung này; FRS chỉ giữ danh mục (đã hấp thụ FRS 0.2)
| 2 | Quyền ghi "admin, model" ở nhiều dòng §9.4 chưa nói là hợp (một trong hai) hay giao | Tập này hiểu là hợp (một trong hai quyền đủ), ghi bằng dấu `/` ở `x-datahub-permission`; đề nghị FRS nêu rõ (đã có ở FRS 9.4, không cần sửa)
| 3 | API-17-193 ghi quyền "mTLS DU" không có scope | Tập này đặt chỉ mTLS, không scope; đề nghị FRS xác nhận (ghi nhận, giữ nguyên FRS)
| 4 | Enum tại chỗ chưa có ở Phụ lục A (`SourceState`, `SuggestionDecision`, `ExportKind`, `LogScopeKind`, `MetricCode`, `ProtocolKind`, ...) dùng ở lược đồ | Thêm vào Phụ lục A (cùng đề nghị ở D03-03-PH17 §10.1) (đã hấp thụ FRS 0.2)
| 5 | `mapping-suggestions:validate-expression` chạy biểu thức JQ trên mẫu; chưa có FR nêu giới hạn thời gian và bộ nhớ | Đề nghị bổ sung vào FR-17-030 (đã hấp thụ FRS 0.2)

: Đề nghị đồng bộ với FRS

### 10.2. Với tài liệu chung

Người điều phối chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để D00-04 có API-17-001…194, EVT-17-01…28 và Q17-72…75 của tập này. D02-08 bổ sung `PERM-17-*` và scope `assist:report` (FRS Phụ lục B). D03-06-00 ghi nhóm route `/quan-tri/tro-ly-ai/*`. D03-09 ghi data plane `/assist/v1` là Deployment riêng (vai `ph17_infer`).

## 11. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q17-72 | Phát trực tuyến dùng SSE qua APISIX và BFF: giới hạn thời gian giữ kết nối, đệm proxy tắt (`X-Accel-Buffering: no`), kết nối lại bằng `Last-Event-ID` | Giữ kết nối tối đa 90 giây (hơn `17.model.timeout-seconds`); không hỗ trợ nối lại giữa chừng, khách gọi lại bằng `clientMessageId` |
| Q17-73 | Hạn mức 300 yêu cầu mỗi phút cho API quản trị chưa có khóa `17.*` | Giữ giả định ở APISIX; thêm khóa `17.api.rate-user-per-min` nếu FRS cần |
| Q17-74 | `Location` của `202` và `201` trỏ tới đường dẫn control plane; PH-04, PH-11 không gọi được vì ở data plane | Data plane chỉ trả đối tượng, không có `Location` |
| Q17-75 | Có cần API xuất danh mục công cụ và quy tắc lọc dạng tệp cho rà soát ATTT | Chưa; xuất qua gói bằng chứng (API-17-173) |

: Câu hỏi mở của tập API PH-17

## 12. Ví dụ JSON

<!-- gen:examples:start -->
### 12.1. Đề nghị bật trợ lý có số quyết định

Ví dụ cho API-17-003 (`POST /policy/changes`), phản hồi `201`; dữ liệu giả lập.

```http
POST /api/assist/v1/policy/changes
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "changeType": "ENABLE",
  "decisionNumber": "112/QĐ-UBND ngày 20/11/2026",
  "reason": "Triển khai trợ lý tìm dịch vụ cho cán bộ các sở theo kế hoạch đợt 3",
  "capabilities": [
    {
      "capability": "SEARCH",
      "roleGroup": "ALL_READERS",
      "enabled": true
    }
  ]
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "changeType": "ENABLE",
  "state": "PENDING",
  "decisionNumber": "112/QĐ-UBND ngày 20/11/2026",
  "reason": "Triển khai trợ lý tìm dịch vụ cho cán bộ các sở theo kế hoạch đợt 3",
  "requestedBy": "nguyen.van.an",
  "requestedAt": "2026-11-26T09:15:02+07:00"
}
```

### 12.2. Gửi câu hỏi và nhận câu trả lời có trích dẫn

Ví dụ cho API-17-095 (`POST /conversations/{conversationId}/messages`), phản hồi `200`; dữ liệu giả lập.

```http
POST /api/assist/v1/conversations/{conversationId}/messages
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "content": "Dịch vụ nào tra cứu mã số thuế của tổ chức",
  "capability": "SEARCH",
  "clientMessageId": "0190a1b2-0000-7000-8000-000000000001"
}
```

```http
HTTP/1.1 200

{
  "message": {
    "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
    "version": 3,
    "createdAt": "2026-11-20T09:00:00+07:00",
    "createdBy": "nguyen.van.an",
    "updatedAt": "2026-11-26T09:15:02+07:00",
    "updatedBy": "tran.thi.binh",
    "conversationId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
    "seq": 2,
    "role": "ASSISTANT",
    "content": "API tra cứu thuế (xem mô tả). Nội dung do AI tạo, cần kiểm tra lại.",
    "outcome": "ANSWERED",
    "capability": "SEARCH",
    "aiGenerated": true,
    "citations": [
      {
        "rank": 1,
        "chunkId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
        "sourceId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
        "objectRef": "api/tra-cuu-thue/v1",
        "title": "API tra cứu thuế",
        "linkRoute": "/dich-vu/api/tra-cuu-thue?tab=mo-ta",
        "score": 0.8123
      }
    ]
  },
  "aiGenerated": true
}
```

### 12.3. Tìm dịch vụ bằng truy hồi lai

Ví dụ cho API-17-099 (`POST /search`), phản hồi `200`; dữ liệu giả lập.

```http
POST /api/assist/v1/search
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "query": "tra cứu mã số thuế",
  "limit": 5
}
```

```http
HTTP/1.1 200

{
  "results": [
    {
      "objectRef": "api/tra-cuu-thue/v1",
      "title": "API tra cứu thuế",
      "snippet": "API tra cứu thuế của tổ chức, trả mã số thuế và tình trạng hoạt động.",
      "linkRoute": "/dich-vu/api/tra-cuu-thue?tab=mo-ta",
      "score": 0.8123,
      "sourceType": "API_SPEC"
    }
  ],
  "aiGenerated": false
}
```

### 12.4. Gợi ý ánh xạ trường

Ví dụ cho API-17-104 (`POST /mapping-suggestions`), phản hồi `201`; dữ liệu giả lập.

```http
POST /api/assist/v1/mapping-suggestions
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "sourceSchemaRef": "schema/ho-so-nguon/v2",
  "targetSchemaRef": "schema/ho-so-dich/v1",
  "sourceFields": [
    "ho_ten",
    "ngay_sinh"
  ],
  "targetFields": [
    "fullName",
    "dateOfBirth"
  ]
}
```

```http
HTTP/1.1 201

{
  "suggestion": {
    "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
    "version": 3,
    "createdAt": "2026-11-20T09:00:00+07:00",
    "createdBy": "nguyen.van.an",
    "updatedAt": "2026-11-26T09:15:02+07:00",
    "updatedBy": "tran.thi.binh",
    "suggestionKind": "FIELD_MAPPING",
    "status": "PROPOSED",
    "content": {
      "items": 2
    },
    "aiGenerated": true
  },
  "items": [
    {
      "sourceField": "ho_ten",
      "targetField": "fullName",
      "expression": ".ho_ten",
      "confidence": 0.93,
      "reason": "Tên trường và kiểu trùng nghĩa"
    }
  ],
  "aiGenerated": true
}
```

### 12.5. Xin phiếu truy cập nhật ký hội thoại

Ví dụ cho API-17-169 (`POST /logs/access-grants`), phản hồi `201`; dữ liệu giả lập.

```http
POST /api/assist/v1/logs/access-grants
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "reason": "Điều tra khiếu nại về câu trả lời của trợ lý",
  "scopeKind": "CONVERSATION",
  "conversationId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d"
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "grantee": "le.thi.chi",
  "granteeRole": "SO",
  "reason": "Điều tra khiếu nại về câu trả lời của trợ lý",
  "scopeKind": "CONVERSATION",
  "conversationId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
  "grantedAt": "2026-11-26T09:15:02+07:00",
  "expiresAt": "2026-11-26T10:15:02+07:00",
  "state": "ACTIVE"
}
```

### 12.6. Phân loại văn bản qua data plane

Ví dụ cho API-17-187 (`POST /assist/v1/inference/classify`), phản hồi `200`; dữ liệu giả lập.

```http
POST /assist/v1/inference/classify
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "taskCode": "PHAN-LOAI-VAN-BAN",
  "text": "Công văn đề nghị cấp phép xây dựng công trình nhà ở riêng lẻ",
  "labels": [
    "CAP-PHEP",
    "KHIEU-NAI"
  ],
  "purposeCode": "XU-LY-HO-SO",
  "dataClass": "INTERNAL"
}
```

```http
HTTP/1.1 200

{
  "label": "CAP-PHEP",
  "confidence": 0.91,
  "modelVersionId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
  "requestRef": "req-0001",
  "aiGenerated": true
}
```

### 12.7. Gợi ý bước quy trình cho PH-11

Ví dụ cho API-17-190 (`POST /assist/v1/process-suggestions`), phản hồi `201`; dữ liệu giả lập.

```http
POST /assist/v1/process-suggestions
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "stepType": "APPROVAL",
  "processRef": "quy-trinh/cap-phep-xay-dung/v3",
  "context": {
    "soHoSo": "HS-0042"
  },
  "purposeCode": "XU-LY-HO-SO"
}
```

```http
HTTP/1.1 201

{
  "suggestionId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
  "summary": "Hồ sơ đủ thành phần, đề nghị chuyển bước thẩm định.",
  "options": [
    {
      "code": "CHUYEN-THAM-DINH",
      "label": "Chuyển thẩm định",
      "rationale": "Đủ giấy tờ"
    }
  ],
  "requiresHumanDecision": true,
  "modelVersionId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
  "aiGenerated": true
}
```
<!-- gen:examples:end -->

## 13. Đặc tả endpoint trọng yếu

Ba mươi operation trọng yếu (bốn mắt, tắt khẩn, cổng phát hành, hội thoại, gợi ý, nhật ký, data plane) có đặc tả đầy đủ theo khung K-TRINH-BAY; các operation còn lại theo OpenAPI.

<!-- gen:dac-ta:start -->
### 13.1. Chính sách

Trạng thái, chính sách theo tenant, đề nghị đổi bốn mắt, năng lực, danh sách trắng nhà cung cấp, hạn mức, điều khoản, tắt khẩn (FR-17-001…006). Các operation sau có đặc tả đầy đủ.

#### API-17-003 · Đề nghị đổi chính sách cần bốn mắt (`ENABLE`, `EXTERNAL_ON`, `RESUME`, `SENSITIVE_PARAM`)

::: dac-ta
**Mục đích.** Đề nghị đổi chính sách cần bốn mắt (`ENABLE`, `EXTERNAL_ON`, `RESUME`, `SENSITIVE_PARAM`).

**Phương thức, đường dẫn.** `POST /policy/changes`.

**Quyền.** admin.

**FR hiện thực.** FR-17-001, FR-17-003, FR-17-006, FR-17-059.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyChangeInput`; trường bắt buộc: `changeType`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PolicyChange`; trường bắt buộc: `version`, `id`, `changeType`, `state`, `reason`, `requestedBy`, `requestedAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-005, ERR-17-006, ERR-17-007, ERR-17-008, ERR-17-009, ERR-17-010, ERR-17-012, ERR-17-013, ERR-17-014, ERR-17-015, ERR-17-016, ERR-17-017, ERR-17-018, ERR-17-033, ERR-17-082, ERR-17-083, ERR-17-084, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần bốn mắt: người đề nghị khác người duyệt (ERR-17-005); mỗi loại chỉ một đề nghị đang chờ (ERR-17-013). `ENABLE` cần số quyết định và lý do tối thiểu 20 ký tự, phát EVT-17-04 khi được quyết định.
:::

#### API-17-006 · Duyệt đề nghị (người thứ hai)

::: dac-ta
**Mục đích.** Duyệt đề nghị (người thứ hai).

**Phương thức, đường dẫn.** `POST /policy/changes/{changeId}:approve`.

**Quyền.** admin.

**FR hiện thực.** FR-17-001, FR-17-003, FR-17-006, FR-17-059.

**Tham số.** `changeId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PolicyChange`; trường bắt buộc: `version`, `id`, `changeType`, `state`, `reason`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-005, ERR-17-006, ERR-17-007, ERR-17-008, ERR-17-009, ERR-17-010, ERR-17-012, ERR-17-013, ERR-17-014, ERR-17-015, ERR-17-016, ERR-17-017, ERR-17-018, ERR-17-033, ERR-17-082, ERR-17-083, ERR-17-084, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt đề nghị (người thứ hai) Quyền PERM-17-admin; FR-17-001, 003, 006, 059.
:::

#### API-17-008 · Tắt trợ lý cho tenant

::: dac-ta
**Mục đích.** Tắt trợ lý cho tenant.

**Phương thức, đường dẫn.** `POST /policy:disable`.

**Quyền.** admin.

**FR hiện thực.** FR-17-001.

**Tham số.** `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantPolicy`; trường bắt buộc: `version`, `id`, `assistState`, `externalAllowed`, `capabilities`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-004, ERR-17-005, ERR-17-006, ERR-17-007, ERR-17-008, ERR-17-010, ERR-17-013, ERR-17-014, ERR-17-015, ERR-17-033, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tắt ngay, không cần bốn mắt; phát EVT-17-02. Chỉ mục giữ 90 ngày rồi xóa nếu không bật lại (Q17-21).
:::

#### API-17-020 · Tắt khẩn cấp trợ lý của tenant

::: dac-ta
**Mục đích.** Tắt khẩn cấp trợ lý của tenant.

**Phương thức, đường dẫn.** `POST /kill-switch:activate`.

**Quyền.** admin.

**FR hiện thực.** FR-17-006.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `KillSwitchInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `KillSwitchRecord`; trường bắt buộc: `version`, `id`, `scope`, `reason`, `activatedBy`, `activatedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-005, ERR-17-006, ERR-17-007, ERR-17-010, ERR-17-012, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tắt khẩn trong tối đa 60 giây (SEC-49), phát EVT-17-03; gỡ cần đề nghị bốn mắt.
:::

### 13.2. Cổng mô hình

Nhà cung cấp, cam kết, mô hình, phiên bản, mô hình của tenant, tuyến egress, giới hạn cổng, cầu dao, vết lời gọi, sức khỏe (FR-17-007…014). Các operation sau có đặc tả đầy đủ.

#### API-17-041 · Duyệt bốn mắt, chuyển `APPROVED`

::: dac-ta
**Mục đích.** Duyệt bốn mắt, chuyển `APPROVED`.

**Phương thức, đường dẫn.** `POST /model-versions/{versionId}:approve`.

**Quyền.** model / eval.

**FR hiện thực.** FR-17-009.

**Tham số.** `versionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ModelVersion`; trường bắt buộc: `version`, `id`, `modelId`, `versionNo`, `versionLabel`, `upstreamName`, `status`, `contextTokens`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-005, ERR-17-006, ERR-17-010, ERR-17-029, ERR-17-030, ERR-17-073, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bốn mắt; cổng phát hành kiểm tại thời điểm duyệt: đánh giá chuẩn đạt ngưỡng, ca đỏ chặn 100%, bộ ca đỏ có ít nhất 50 ca đang hoạt động (ERR-17-072 đến 075); phát EVT-17-07.
:::

#### API-17-046 · Bật phiên bản đã duyệt cho tenant

::: dac-ta
**Mục đích.** Bật phiên bản đã duyệt cho tenant.

**Phương thức, đường dẫn.** `POST /tenant-models/{versionId}:enable`.

**Quyền.** model.

**FR hiện thực.** FR-17-010.

**Tham số.** `versionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantModel`; trường bắt buộc: `version`, `id`, `versionId`, `modelKind`, `enabled`, `isDefault`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-004, ERR-17-006, ERR-17-010, ERR-17-017, ERR-17-030, ERR-17-031, ERR-17-032, ERR-17-033, ERR-17-034, ERR-17-036, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mô hình ngoài chỉ bật khi tenant cho phép, nhà cung cấp trong danh sách trắng, có cam kết còn hiệu lực và phiên bản đã `APPROVED`.
:::

### 13.3. Kho tri thức

Nguồn, lập chỉ mục, kiểm mức phân loại, tài liệu, xóa lan truyền, tài liệu tải lên, tình trạng chỉ mục (FR-17-015…021). Các operation sau có đặc tả đầy đủ.

#### API-17-068 · Ngừng nguồn và xóa đoạn liên quan

::: dac-ta
**Mục đích.** Ngừng nguồn và xóa đoạn liên quan.

**Phương thức, đường dẫn.** `POST /knowledge/sources/{sourceId}:retire`.

**Quyền.** knowledge.

**FR hiện thực.** FR-17-015, FR-17-019.

**Tham số.** `sourceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `KnowledgeSource`; trường bắt buộc: `version`, `id`, `sourceCode`, `sourceType`, `name`, `sourceState`, `documentCount`, `chunkCount`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-006, ERR-17-007, ERR-17-009, ERR-17-010, ERR-17-041, ERR-17-042, ERR-17-047, ERR-17-048, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngừng nguồn và xóa đoạn liên quan Quyền PERM-17-knowledge; FR-17-015, 019.
:::

#### API-17-079 · Xóa tài liệu khỏi chỉ mục

::: dac-ta
**Mục đích.** Xóa tài liệu khỏi chỉ mục.

**Phương thức, đường dẫn.** `DELETE /knowledge/documents/{documentId}`.

**Quyền.** knowledge.

**FR hiện thực.** FR-17-019.

**Tham số.** `documentId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `410`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-004, ERR-17-009, ERR-17-010, ERR-17-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa đoạn liên quan vật lý trong cùng giao dịch và ghi nhật ký xóa lan truyền; phát EVT-17-16.
:::

#### API-17-085 · Duyệt (người thứ hai) và lập chỉ mục

::: dac-ta
**Mục đích.** Duyệt (người thứ hai) và lập chỉ mục.

**Phương thức, đường dẫn.** `POST /knowledge/uploads/{uploadId}:approve`.

**Quyền.** knowledge.

**FR hiện thực.** FR-17-020.

**Tham số.** `uploadId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UploadDocument`; trường bắt buộc: `version`, `id`, `sourceId`, `title`, `fileId`, `uploadStatus`, `declaredClass`, `uploadedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-005, ERR-17-006, ERR-17-010, ERR-17-043, ERR-17-045, ERR-17-046, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người tải lên; chỉ tài liệu mức `PUBLIC` hoặc `INTERNAL` được lập chỉ mục (BR-17-026, 030).
:::

### 13.4. Hội thoại và tìm kiếm

Hội thoại, tin nhắn (đầy đủ và phát trực tuyến), tìm dịch vụ, câu hỏi gợi ý, ngữ cảnh màn hình (FR-17-022…029). Các operation sau có đặc tả đầy đủ.

#### API-17-090 · Mở hội thoại, kèm ngữ cảnh màn hình

::: dac-ta
**Mục đích.** Mở hội thoại, kèm ngữ cảnh màn hình.

**Phương thức, đường dẫn.** `POST /conversations`.

**Quyền.** use.

**FR hiện thực.** FR-17-022, FR-17-029.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConversationInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Conversation`; trường bắt buộc: `version`, `id`, `userId`, `state`, `messageCount`, `expiresAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-008, ERR-17-010, ERR-17-020, ERR-17-051, ERR-17-052, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mở hội thoại, kèm ngữ cảnh màn hình Quyền PERM-17-use; FR-17-022, 029.
:::

#### API-17-095 · Gửi câu hỏi, nhận câu trả lời đầy đủ

::: dac-ta
**Mục đích.** Gửi câu hỏi, nhận câu trả lời đầy đủ.

**Phương thức, đường dẫn.** `POST /conversations/{conversationId}/messages`.

**Quyền.** use.

**FR hiện thực.** FR-17-023, FR-17-024, FR-17-025, FR-17-030, FR-17-036, FR-17-044, FR-17-045, FR-17-048.

**Tham số.** `conversationId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MessageInput`; trường bắt buộc: `content`, `clientMessageId`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MessageAnswer`; trường bắt buộc: `message`, `aiGenerated`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-009, ERR-17-010, ERR-17-011, ERR-17-019, ERR-17-021, ERR-17-022, ERR-17-023, ERR-17-036, ERR-17-038, ERR-17-054, ERR-17-055, ERR-17-059, ERR-17-063, ERR-17-064, ERR-17-065, ERR-17-066, ERR-17-067, ERR-17-068, ERR-17-070, ERR-17-084, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả câu trả lời đầy đủ trong một phản hồi; nội dung do AI tạo luôn có nhãn `aiGenerated` (FR-17-048). Không có hành động ghi tự động.
:::

#### API-17-096 · Gửi câu hỏi, nhận câu trả lời phát trực tuyến (SSE `text/event-stream`)

::: dac-ta
**Mục đích.** Gửi câu hỏi, nhận câu trả lời phát trực tuyến (SSE `text/event-stream`).

**Phương thức, đường dẫn.** `POST /conversations/{conversationId}/messages:stream`.

**Quyền.** use.

**FR hiện thực.** FR-17-023, FR-17-026, FR-17-048.

**Tham số.** `conversationId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MessageInput`; trường bắt buộc: `content`, `clientMessageId`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SseStream`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-006, ERR-17-010, ERR-17-011, ERR-17-019, ERR-17-021, ERR-17-022, ERR-17-023, ERR-17-038, ERR-17-053, ERR-17-067, ERR-17-068, ERR-17-070, ERR-17-084, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phản hồi `text/event-stream` với các sự kiện `message.delta` (đoạn văn bản), `message.citation` (trích dẫn), `message.done` (kết thúc kèm `messageId`), `message.error` (lỗi RFC 9457). Hủy bằng API-17-097.
:::

#### API-17-099 · Tìm dịch vụ (truy hồi lai, kết quả có trích dẫn, không sinh văn bản)

::: dac-ta
**Mục đích.** Tìm dịch vụ (truy hồi lai, kết quả có trích dẫn, không sinh văn bản).

**Phương thức, đường dẫn.** `POST /search`.

**Quyền.** use.

**FR hiện thực.** FR-17-023, FR-17-024, FR-17-025.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SearchInput`; trường bắt buộc: `query`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchResult`; trường bắt buộc: `results`, `aiGenerated`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `503`, `504`; mã lỗi của thao tác: ERR-17-003, ERR-17-009, ERR-17-010, ERR-17-011, ERR-17-019, ERR-17-021, ERR-17-022, ERR-17-023, ERR-17-036, ERR-17-038, ERR-17-064, ERR-17-067, ERR-17-068 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Truy hồi lai (vector và từ khóa không dấu, RRF), kết quả có trích dẫn, không sinh văn bản; chỉ trả đoạn người gọi có quyền đọc (BR-17-027).
:::

### 13.5. Gợi ý ánh xạ

Gợi ý ánh xạ trường và mã, kiểm biểu thức, xem trước, áp dụng, sửa, từ chối (FR-17-030…035). Các operation sau có đặc tả đầy đủ.

#### API-17-104 · Gợi ý ánh xạ trường nguồn sang đích (biểu thức JQ đề xuất)

::: dac-ta
**Mục đích.** Gợi ý ánh xạ trường nguồn sang đích (biểu thức JQ đề xuất).

**Phương thức, đường dẫn.** `POST /mapping-suggestions`.

**Quyền.** use.

**FR hiện thực.** FR-17-030, FR-17-032, FR-17-034.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MappingSuggestionInput`; trường bắt buộc: `sourceSchemaRef`, `targetSchemaRef`, `sourceFields`, `targetFields`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `MappingSuggestionResult`; trường bắt buộc: `suggestion`, `items`, `aiGenerated`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-010, ERR-17-011, ERR-17-021, ERR-17-022, ERR-17-023, ERR-17-054, ERR-17-055, ERR-17-056, ERR-17-059, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gợi ý ánh xạ trường nguồn sang đích (biểu thức JQ đề xuất) Quyền PERM-17-use; FR-17-030, 032, 034.
:::

#### API-17-110 · Áp dụng vào bản nháp bằng quyền người dùng

::: dac-ta
**Mục đích.** Áp dụng vào bản nháp bằng quyền người dùng.

**Phương thức, đường dẫn.** `POST /suggestions/{suggestionId}:apply`.

**Quyền.** use.

**FR hiện thực.** FR-17-033, FR-17-035, FR-17-048.

**Tham số.** `suggestionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ApplyResult`; trường bắt buộc: `suggestionId`, `applied`, `targetModule`, `draftRef`, `appliedBy`, `appliedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-004, ERR-17-006, ERR-17-010, ERR-17-056, ERR-17-057, ERR-17-064, ERR-17-070, ERR-17-084, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp dụng vào bản nháp bằng quyền của chính người dùng (token exchange); trợ lý không có quyền ghi riêng (BR-17-056, 057).
:::

### 13.6. Giải thích sự cố

Giải thích mã lỗi, vết, bản tin DLQ, danh sách kiểm khắc phục, tóm tắt sự cố, xem trước che log (FR-17-036…041). Các operation sau có đặc tả đầy đủ.

#### API-17-113 · Giải thích mã lỗi đang hiển thị

::: dac-ta
**Mục đích.** Giải thích mã lỗi đang hiển thị.

**Phương thức, đường dẫn.** `POST /explanations/error-codes`.

**Quyền.** use.

**FR hiện thực.** FR-17-036.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ErrorCodeInput`; trường bắt buộc: `errorCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Explanation`; trường bắt buộc: `version`, `id`, `explanationKind`, `summary`, `aiGenerated`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-010, ERR-17-011, ERR-17-021, ERR-17-022, ERR-17-023, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giải thích mã lỗi đang hiển thị Quyền PERM-17-use; FR-17-036.
:::

### 13.7. Công cụ và an toàn

Công cụ chỉ đọc, nhật ký gọi công cụ, giới hạn, quy tắc lọc, danh sách trắng liên kết (FR-17-042…047). Các operation sau có đặc tả đầy đủ.

#### API-17-122 · Bật hoặc tắt công cụ cho tenant

::: dac-ta
**Mục đích.** Bật hoặc tắt công cụ cho tenant.

**Phương thức, đường dẫn.** `PUT /tools/{toolCode}/enablement`.

**Quyền.** tool.

**FR hiện thực.** FR-17-042.

**Tham số.** `toolCode` (path, Code, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ToolEnablementInput`; trường bắt buộc: `enabled`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ToolDefinition`; trường bắt buộc: `version`, `id`, `toolCode`, `name`, `targetModule`, `targetRef`, `scope`, `capabilities`, `readOnly`, `timeoutMs`, `enabled`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-010, ERR-17-063 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bật hoặc tắt công cụ cho tenant Quyền PERM-17-tool; FR-17-042.
:::

#### API-17-126 · Thêm quy tắc lọc

::: dac-ta
**Mục đích.** Thêm quy tắc lọc.

**Phương thức, đường dẫn.** `POST /guardrails`.

**Quyền.** tool.

**FR hiện thực.** FR-17-045, FR-17-046.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GuardrailRuleInput`; trường bắt buộc: `ruleCode`, `guardrailKind`, `action`, `category`, `patternKind`, `pattern`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `GuardrailRule`; trường bắt buộc: `version`, `id`, `ruleCode`, `guardrailKind`, `action`, `category`, `patternKind`, `pattern`, `builtin`, `enabled`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-010, ERR-17-065, ERR-17-066, ERR-17-067, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm quy tắc lọc Quyền PERM-17-tool; FR-17-045, 046.
:::

### 13.8. Quản trị AI

Chỉ dẫn hệ thống, bộ đánh giá, ca đỏ, cổng phát hành, phản hồi, chất lượng, sổ hệ thống AI, tập ẩn danh (FR-17-049…054, 062). Các operation sau có đặc tả đầy đủ.

#### API-17-136 · Duyệt bốn mắt, kích hoạt

::: dac-ta
**Mục đích.** Duyệt bốn mắt, kích hoạt.

**Phương thức, đường dẫn.** `POST /prompt-versions/{versionId}:approve`.

**Quyền.** eval.

**FR hiện thực.** FR-17-049.

**Tham số.** `versionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PromptVersion`; trường bắt buộc: `version`, `id`, `templateId`, `versionNo`, `status`, `content`, `contentHash`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-005, ERR-17-006, ERR-17-010, ERR-17-071, ERR-17-072, ERR-17-073, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bốn mắt kích hoạt chỉ dẫn; một phiên bản `ACTIVE` mỗi mẫu; phát EVT-17-20.
:::

#### API-17-145 · Chạy bộ đánh giá cho một đối tượng

::: dac-ta
**Mục đích.** Chạy bộ đánh giá cho một đối tượng.

**Phương thức, đường dẫn.** `POST /eval-runs`.

**Quyền.** eval.

**FR hiện thực.** FR-17-050.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EvalRunInput`; trường bắt buộc: `evalSetId`, `subjectType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `EvalRun`; trường bắt buộc: `version`, `id`, `runKind`, `subjectType`, `status`, `triggerKind`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-010, ERR-17-072, ERR-17-074, ERR-17-076, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy bộ đánh giá cho một đối tượng Quyền PERM-17-eval; FR-17-050.
:::

#### API-17-152 · Chạy bộ ca đỏ

::: dac-ta
**Mục đích.** Chạy bộ ca đỏ.

**Phương thức, đường dẫn.** `POST /redteam-runs`.

**Quyền.** eval.

**FR hiện thực.** FR-17-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RedteamRunInput`; trường bắt buộc: `subjectType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `EvalRun`; trường bắt buộc: `version`, `id`, `runKind`, `subjectType`, `status`, `triggerKind`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-010, ERR-17-073, ERR-17-075, ERR-17-076, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy bộ ca đỏ Quyền PERM-17-eval; FR-17-051.
:::

#### API-17-154 · Trạng thái cổng phát hành của mô hình hoặc prompt

::: dac-ta
**Mục đích.** Trạng thái cổng phát hành của mô hình hoặc prompt.

**Phương thức, đường dẫn.** `GET /release-gates/{subjectType}/{subjectId}`.

**Quyền.** eval.

**FR hiện thực.** FR-17-009, FR-17-049, FR-17-051.

**Tham số.** `subjectType` (path, string, bắt buộc); `subjectId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReleaseGate`; trường bắt buộc: `subjectType`, `subjectId`, `evalPassed`, `minScore`, `redteamPassed`, `casesLeaked`, `redteamCasesActive`, `minRedteamCases`, `fourEyesReady`, `open`, `blockers`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `422`, `429`; mã lỗi của thao tác: ERR-17-001, ERR-17-005, ERR-17-071, ERR-17-075 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái cổng phát hành của mô hình hoặc prompt Quyền PERM-17-eval; FR-17-009, 049, 051.
:::

#### API-17-155 · Gửi phản hồi cho một câu trả lời

::: dac-ta
**Mục đích.** Gửi phản hồi cho một câu trả lời.

**Phương thức, đường dẫn.** `POST /feedback`.

**Quyền.** use.

**FR hiện thực.** FR-17-052.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FeedbackInput`; trường bắt buộc: `messageId`, `feedbackKind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Feedback`; trường bắt buộc: `version`, `id`, `messageId`, `feedbackKind`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-010, ERR-17-077, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi phản hồi cho một câu trả lời Quyền PERM-17-use; FR-17-052.
:::

### 13.9. Nhật ký và báo cáo

Nhật ký hội thoại đã che, phiếu truy cập, hạn lưu, gói bằng chứng, báo cáo sử dụng, tham số (FR-17-055…059). Các operation sau có đặc tả đầy đủ.

#### API-17-169 · Khai báo lý do để xem nhật ký, cấp phiếu 60 phút

::: dac-ta
**Mục đích.** Khai báo lý do để xem nhật ký, cấp phiếu 60 phút.

**Phương thức, đường dẫn.** `POST /logs/access-grants`.

**Quyền.** log-read.

**FR hiện thực.** FR-17-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LogAccessGrantInput`; trường bắt buộc: `reason`, `scopeKind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LogAccessGrant`; trường bắt buộc: `version`, `id`, `grantee`, `granteeRole`, `reason`, `scopeKind`, `grantedAt`, `expiresAt`, `state`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-007, ERR-17-010, ERR-17-079, ERR-17-080, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ SO, AUDITOR; lý do tối thiểu 20 ký tự; phiếu hiệu lực tối đa 60 phút, khoảng xem tối đa 92 ngày; phát EVT-17-25.
:::

#### API-17-171 · Xem nội dung đã che của một hội thoại (cần phiếu)

::: dac-ta
**Mục đích.** Xem nội dung đã che của một hội thoại (cần phiếu).

**Phương thức, đường dẫn.** `GET /logs/conversations/{conversationId}`.

**Quyền.** log-read.

**FR hiện thực.** FR-17-056.

**Tham số.** `conversationId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LogConversationDetail`; trường bắt buộc: `conversation`, `messages`, `grantId`, `grantExpiresAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `422`, `429`; mã lỗi của thao tác: ERR-17-001, ERR-17-007, ERR-17-079, ERR-17-080 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ xem được khi có phiếu còn hiệu lực; trả nội dung đã che.
:::

#### API-17-173 · Yêu cầu gói bằng chứng tuân thủ

::: dac-ta
**Mục đích.** Yêu cầu gói bằng chứng tuân thủ.

**Phương thức, đường dẫn.** `POST /compliance-exports`.

**Quyền.** log-read.

**FR hiện thực.** FR-17-057.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ComplianceExportInput`; trường bắt buộc: `exportKind`, `periodFrom`, `periodTo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ComplianceExport`; trường bắt buộc: `version`, `id`, `exportKind`, `state`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `410`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-003, ERR-17-007, ERR-17-009, ERR-17-010, ERR-17-081, ERR-17-087 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Yêu cầu gói bằng chứng tuân thủ Quyền PERM-17-log-read; FR-17-057.
:::

#### API-17-182 · Đặt giá trị tham số

::: dac-ta
**Mục đích.** Đặt giá trị tham số.

**Phương thức, đường dẫn.** `PUT /settings/{key}`.

**Quyền.** config.

**FR hiện thực.** FR-17-059.

**Tham số.** `key` (path, SettingKey, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingValueInput`; trường bắt buộc: `value`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingItem`; trường bắt buộc: `key`, `value`, `fourEyes`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-17-001, ERR-17-003, ERR-17-004, ERR-17-009, ERR-17-010, ERR-17-013, ERR-17-018, ERR-17-082, ERR-17-083, ERR-17-084 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị ngoài sàn, trần thì ERR-17-018 hoặc ERR-17-082; hạn lưu nhật ký dưới 90 ngày thì ERR-17-083; khóa nhạy cảm cần đề nghị bốn mắt (`SENSITIVE_PARAM`).
:::

### 13.10. Data plane

Suy luận nội bộ cho PH-04, gợi ý bước quy trình cho PH-11, cấu hình hiệu lực, sẵn sàng; chỉ trong cụm (FR-17-060, 061). Các operation sau có đặc tả đầy đủ.

#### API-17-187 · Phân loại văn bản cho bước luồng PH-04

::: dac-ta
**Mục đích.** Phân loại văn bản cho bước luồng PH-04.

**Phương thức, đường dẫn.** `POST /assist/v1/inference/classify`.

**Quyền.** scope assist:infer.

**FR hiện thực.** FR-17-060.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ClassifyInput`; trường bắt buộc: `taskCode`, `text`, `purposeCode`, `dataClass`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClassifyResult`; trường bắt buộc: `label`, `confidence`, `modelVersionId`, `requestRef`, `aiGenerated`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`, `429`, `502`, `503`, `504`; mã lỗi của thao tác: ERR-17-101, ERR-17-102, ERR-17-103, ERR-17-104, ERR-17-105, ERR-17-106, ERR-17-107, ERR-17-108, ERR-17-109, ERR-17-110, ERR-17-111, ERR-17-112, ERR-17-113, ERR-17-115, ERR-17-118 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Data plane: danh tính DU qua mTLS, scope `assist:infer`; thiếu mục đích hoặc mức dữ liệu thì ERR-17-102; dữ liệu mức cao không gửi tới mô hình ngoài (ERR-17-107).
:::

#### API-17-190 · Gợi ý cho bước quy trình PH-11

::: dac-ta
**Mục đích.** Gợi ý cho bước quy trình PH-11.

**Phương thức, đường dẫn.** `POST /assist/v1/process-suggestions`.

**Quyền.** scope assist:infer.

**FR hiện thực.** FR-17-061.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ProcessSuggestionInput`; trường bắt buộc: `stepType`, `processRef`, `purposeCode`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ProcessSuggestionResult`; trường bắt buộc: `suggestionId`, `summary`, `requiresHumanDecision`, `modelVersionId`, `aiGenerated`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-107, ERR-17-114, ERR-17-117, ERR-17-118 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gợi ý bước quy trình luôn cần người quyết định (ERR-17-114).
:::

#### API-17-191 · PH-11 báo quyết định cuối của người

::: dac-ta
**Mục đích.** PH-11 báo quyết định cuối của người.

**Phương thức, đường dẫn.** `POST /assist/v1/process-suggestions/{suggestionId}:record-decision`.

**Quyền.** scope assist:infer.

**FR hiện thực.** FR-17-061.

**Tham số.** `suggestionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionInput`; trường bắt buộc: `decision`, `decidedBy`, `decidedAt`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProcessSuggestionResult`; trường bắt buộc: `suggestionId`, `summary`, `requiresHumanDecision`, `modelVersionId`, `aiGenerated`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-17-107, ERR-17-114, ERR-17-117, ERR-17-118 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-11 báo quyết định cuối của người Quyền scope assist:infer; FR-17-061.
:::
<!-- gen:dac-ta:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 193 operation OpenAPI 3.1, 28 sự kiện AsyncAPI 3.0, quy ước RFC 9457, SSE, bốn mắt, cổng phát hành; đối chiếu FRS §9.4 đủ mã, sạch Spectral và `check_contracts.py` |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Chốt câu hỏi mở đợt đồng bộ: Q406: thêm API-17-194 (PUT /feedback/{feedbackId}, sửa phản hồi trong 10 phút, If-Match), 194 operation (187 control plane, 7 data plane); sinh lại OpenAPI từ FRS mục 9.4 |

: Lịch sử phiên bản
