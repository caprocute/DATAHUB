---
ma_tai_lieu: D03-04-PH18
ten: Đặc tả API và sự kiện phân hệ PH-18 Vận hành và xử lý lỗi
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, kiểm thử viên, tích hợp viên, cán bộ vận hành, cán bộ ATTT, hội đồng thẩm định
phan_he: PH-18
mo_ta: Hợp đồng 188 operation OpenAPI 3.1 gồm API người dùng và API nội bộ, 42 kênh AsyncAPI 3.0 gồm 29 sự kiện phát và 13 kênh tiêu thụ, quy ước RFC 9457, phân trang, khóa lạc quan, chống trùng và bốn mắt của kho tham số, DLQ hợp nhất, phát lại, thông báo, việc của tôi, lịch, sự cố, sao lưu, di trú, kèm bảng mã lỗi và kiểm tra hợp đồng trong CI.
tai_lieu_lien_quan: D02-03-PH18 FRS; D03-02-PH18 SDD; D03-03-PH18 CSDL; D03-06-PH18 Màn hình; D05-02-PH18 Test case
---

# D03-04-PH18 · Đặc tả API và sự kiện Vận hành và xử lý lỗi

## Tóm tắt cho hội đồng thẩm định

Hợp đồng API của PH-18 gồm hai tệp sinh từ [D02-03-PH18](../../02-yeu-cau/frs/D02-03-PH18-frs-van-hanh.md) §9: [`ph18/openapi-ops.yaml`](ph18/openapi-ops.yaml) (OpenAPI 3.1, 188 operation API-18-001…188) và [`ph18/asyncapi-ops.yaml`](ph18/asyncapi-ops.yaml) (AsyncAPI 3.0, 29 sự kiện EVT-18-01…29 và 13 kênh tiêu thụ). API người dùng `/api/ops/v1` phục vụ cán bộ qua BFF của cổng; API nội bộ `/ops/internal/v1` chỉ trong cụm cho các phân hệ khác, xác thực mTLS với danh tính SPIFFE và scope `ops:*`.

Năm điểm hội đồng cần lưu ý.

1. **PH-18 là dịch vụ dùng chung của mọi phân hệ.** Kho tham số (ParameterApi), gửi thông báo (NotificationApi), "Việc của tôi" (TaskInboxApi) và lịch ngày làm việc (WorkingCalendarApi) là API nội bộ mà các phân hệ khác gọi thay vì tự làm; hợp đồng của bốn API này ở chương 6.
2. **Bốn mắt nằm ở hành động `:approve`.** Đổi tham số ★, áp gói tham số có khóa ★, bản sửa payload có dữ liệu Hạn chế, lượt phát lại vượt `18.dlq.replay.approval-threshold` (mặc định 500 mục), phiên bản mẫu thông báo, khôi phục tenant, chạy di trú thật và cắt chuyển nhóm dịch vụ đều có hành động duyệt riêng; người duyệt khác người đề nghị (ERR-18-005). Hủy, tạm dừng, quay lui không cần bốn mắt vì làm giảm rủi ro.
3. **Payload DLQ không đi qua API danh sách.** Danh sách, xuất CSV, sự kiện và API cho PH-17 chỉ mang siêu dữ liệu; xem payload cần quyền `PERM-18-dlq-payload` và lý do, trả phiếu xem 15 phút (API-18-047), ghi kiểm toán PH-13.
4. **Phát lại đi qua lối vào của nguồn và lũy đẳng.** PH-18 không tự gửi bản tin tới hệ đích; nó phát EVT-18-09 hoặc gọi cổng HTTP của nguồn kèm khóa lũy đẳng `dlqId:revision`, nguồn báo kết quả về API-18-076. DLQ tầng sự kiện của PH-10 hiển thị chung nhưng phát lại bằng API-10-064.
5. **Không có bí mật trong hợp đồng.** Thông tin kết nối hệ cũ, khóa ký gói tham số, thông tin máy chủ thư đều là tham chiếu OpenBao `kv/dh/{tenant}/...`; sự kiện chỉ mang mã, trạng thái, số đếm, không mang payload hay giá trị tham số bảo mật.

: Tóm tắt hợp đồng API PH-18

<!-- gen:stats:start -->
| Chỉ số | Giá trị |
|---|---|
| Operation | 188 (161 API người dùng `/api/ops/v1`, 27 API nội bộ `/ops/internal/v1`), 166 đường dẫn |
| Phương thức | 77 `GET`, 94 `POST`, 8 `PUT`, 7 `PATCH`, 2 `DELETE` |
| Có `If-Match` | 54 operation |
| `Idempotency-Key` | 83 bắt buộc, 6 tùy chọn (lũy đẳng theo khóa tự nhiên) |
| Duyệt bốn mắt (ERR-18-005) | 13 operation |
| Lược đồ thành phần | 322 |
| Kênh AsyncAPI | 42 (29 sự kiện phát EVT-18-01…29, 13 kênh tiêu thụ) |
| Mã lỗi | 96 (ERR-18-001…072 trả qua HTTP, ERR-18-101…124 của worker); 401, 403, 428 dùng ERR-00 |

: Con số chính của hợp đồng API PH-18
<!-- gen:stats:end -->

## 0. Giới thiệu

Chương này nêu mục đích, thuật ngữ, tài liệu tham chiếu, người đọc và cấu trúc của tập đặc tả API PH-18.

### 0.1. Mục đích và phạm vi

Tài liệu mô tả hợp đồng bên ngoài của PH-18 ở mức đủ để kỹ sư `dh-platform` (mô-đun `ops`) và `dh-console` lập trình, tích hợp viên của PH-01 đến PH-20 gọi đúng ParameterApi, NotificationApi, TaskInboxApi, WorkingCalendarApi và kiểm thử viên dựng ca kiểm thử hợp đồng. Nguồn chuẩn là hai tệp YAML; tài liệu này không lặp lại từng lược đồ mà dẫn quy ước, danh mục, sơ đồ trình tự, mã lỗi, sự kiện và đặc tả từng operation. Các chương 4, 5.1, 5.3, 7, 10 và 14 sinh từ YAML bằng [`gen_md.py`](ph18/tools/gen_md.py) và `build/tools/sinh_dac_ta_api.py`.

Ngoài phạm vi: API của tác vụ `dh-migrate` gọi sang phân hệ đích (scope `ops:migration-import`, do tài liệu API của phân hệ đích giữ), API đọc chẩn đoán của PH-13 (API-13-069) và API DLQ tầng sự kiện của PH-10 (API-10-060…065); PH-18 chỉ là bên gọi của các API này.

### 0.2. Thuật ngữ

Bảng dưới đây giải thích các thuật ngữ dùng xuyên suốt tài liệu.

| Thuật ngữ | Giải thích |
|---|---|
| API người dùng, API nội bộ | `/api/ops/v1` cho cán bộ qua BFF; `/ops/internal/v1` trong cụm cho phân hệ khác |
| DLQ | Hàng đợi bản tin lỗi hợp nhất của các nguồn (PH-04 runtime và nguồn khác), topic `{tenant}.ops.dlq.v1` |
| Nguồn DLQ, cổng phát lại | Phân hệ ghi DLQ và cách nhận lại bản tin: `KAFKA_TOPIC`, `HTTP_PORT`, `EVENT_LAYER`, `NONE` |
| Lượt phát lại | Tập mục DLQ chốt tại thời điểm tạo, chạy theo tốc độ giới hạn, vượt ngưỡng cần bốn mắt |
| Khóa ★ | Tham số bảo mật, đổi cần bốn mắt khi `approvalOwner` là PH-18 |
| Giá trị hiệu lực | Giá trị tenant ghi đè nếu có, không thì mặc định của lược đồ, luôn bị kẹp bởi trần nền tảng |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên, ví dụ `:approve`, `:replay` |
| Bốn mắt | Người đề nghị khác người duyệt (ERR-18-005), việc duyệt hiện trong "Việc của tôi" |
| Tác vụ nặng của tenant | Khôi phục, xuất, di trú thật, chuyển sáp nhập; mỗi tenant chỉ một tác vụ nặng chạy cùng lúc (BR-18-039) |

: Thuật ngữ của tập API PH-18

### 0.3. Tài liệu tham chiếu

Bảng dưới đây liệt kê tài liệu mà hợp đồng dựa vào và phần được dùng.

| Tài liệu | Nội dung dùng |
|---|---|
| D02-03-PH18 FRS §3, §4, §6, §8, §9 | Vai trò, quyền, scope, hợp đồng ngữ cảnh DLQ (bảng 4.1b), thực thể EN-18-01…55, FR-18-001…072, khóa `18.*`, ERR, EVT, API-18-001…188 |
| D03-03-PH18 CSDL, `csdl/ph18/ddl/ph18_ops.sql` | Cột snake_case ứng với trường camelCase; FRS thắng khi lệch (mục 11.1) |
| D03-04 khung chung | Quy ước đường dẫn, RFC 9457, phân trang, `Idempotency-Key`, mã nền ERR-00 |
| D03-04-PH04, PH10, PH13, PH20 | Header DLQ của runtime, API DLQ tầng sự kiện, API chẩn đoán, sự kiện vòng đời tenant |
| D02-08 Ma trận phân quyền | Mười một quyền `PERM-18-*` và scope máy |
| ADR-046, ADR-180 đến 184 | Bốn mắt, kho tham số tập trung, DLQ hợp nhất, phát lại qua lối vào của nguồn, khung di trú, thông báo outbox |

: Tài liệu tham chiếu của tập API PH-18

Căn cứ pháp lý của các quy ước (kiểm toán thao tác vận hành, che dữ liệu cá nhân, truy cập payload có lý do, lưu trữ trong nước): Luật An ninh mạng 116/2025, Luật Bảo vệ dữ liệu cá nhân 91/2025, Luật Dữ liệu 60/2024 và Nghị định 331/2026.

### 0.4. Người đọc

Kỹ sư `dh-platform` và `dh-console`, tích hợp viên của mọi phân hệ gọi API nội bộ, kiểm thử viên, cán bộ vận hành và ATTT; hội đồng đọc Tóm tắt, chương 1, 2, 3 và 11.

### 0.5. Cấu trúc tài liệu

Chương 1 quy ước, 2 xác thực và phân quyền, 3 sơ đồ trình tự các luồng chính, 4 danh mục endpoint, 5 sự kiện, 6 hợp đồng với phân hệ khác, 7 mã lỗi, 8 kiểm tra hợp đồng, 9 ánh xạ từ hệ cũ, 10 truy vết FR, 11 đề nghị đồng bộ, 12 câu hỏi mở, 13 ghi chú về ví dụ, 14 đặc tả từng endpoint.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi operation, trừ khi bảng ở chương 4 hoặc đặc tả ở chương 14 ghi khác.

| Mục | Quy ước |
|---|---|
| Đường gốc | API người dùng `/api/ops/v1` qua APISIX và BFF; API nội bộ `/ops/internal/v1` chỉ trong cụm tại `dh-platform.dh-platform.svc:8443`. Đường dẫn ở OpenAPI viết đầy đủ; bảng ở chương 4 bỏ tiền tố `/api/ops/v1` của API người dùng |
| Tenant | API người dùng lấy tenant từ token (claim `tenant`), không từ thân hay đường dẫn; API nội bộ có `{tenant}` ở đường dẫn khi bên gọi phục vụ nhiều tenant và phải khớp danh tính DU. Đối tượng của tenant khác trả `404` ERR-18-001, không lộ sự tồn tại; mọi bảng có RLS |
| Hành động | Hậu tố `:{hành-động}` (`:approve`, `:submit`, `:replay`, `:transition`); hành động có thể đổi trạng thái là `POST` |
| Khóa lạc quan | `GET` đối tượng có phiên bản trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động chuyển trạng thái bắt buộc `If-Match`; thiếu trả `428` (ERR-00-428), lệch trả `412` ERR-18-004 theo FRS §9.1 |
| Chống trùng | Mọi `POST` đổi dữ liệu nhận `Idempotency-Key` (chuỗi 8…64 ký tự), giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-18-009. Một số API nội bộ lũy đẳng theo khóa tự nhiên (`sourceRef`, `dlqId:revision`) nên khóa là tùy chọn |
| Phân trang | `page` (từ 0), `size` (1…100, mặc định 20), `sort` (tiền tố `-` giảm dần); phản hồi `items`, `page`, `size`, `totalElements`; danh sách DLQ thêm khối `facets`, "Việc của tôi" thêm `summary`, thông báo thêm `unreadCount` |
| Thời gian, số | RFC 3339 có múi giờ (`+07:00`); ngày `YYYY-MM-DD`; giờ yên lặng `HH:mm`; mã nghiệp vụ chữ hoa |
| Lỗi | RFC 9457 `application/problem+json`: `type` = `https://datahub.gov.vn/errors/{code}`, `title`, `status`, `code` (`ERR-18-nnn`), `traceId`, `errors[]` theo trường; thông báo tiếng Việt (mặc định) hoặc `en` theo `Accept-Language` (mục 7.1) |
| Tác vụ dài | Đối soát, xuất gói, khôi phục, xuất tenant, chuyển sáp nhập, chạy di trú, dựng báo cáo trả `202` kèm đối tượng ở trạng thái đầu; theo dõi bằng `GET` đối tượng hoặc sự kiện |
| Kết quả từng phần | Thao tác hàng loạt (API-18-036, 051, 078) trả `207` kèm kết quả theo từng mục; chẩn đoán khi PH-13 không trả đủ trả `206` (API-18-046) |
| Kiểm toán | Mọi thao tác ghi ghi kiểm toán PH-13 trước hiệu lực; PH-13 không ghi được trả `503` ERR-18-008 (BR-18-046) |
| Chế độ chỉ đọc | Khi PH-18 ở chế độ chỉ đọc (FR-18-072), thao tác ghi nhóm tham số trả `503` ERR-18-071; API đọc lô của DU vẫn phục vụ từ ảnh chụp |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-platform`, Kafka; `Accept-Language: vi` hoặc `en` |

: Quy ước chung của API PH-18

### 1.1. Hai mặt API

Hai mặt API khác nhau về bên gọi, xác thực và cách lỗi được xử lý; bảng dưới đây so sánh.

| Mục | API người dùng | API nội bộ |
|---|---|---|
| Đường gốc | `/api/ops/v1` | `/ops/internal/v1` |
| Bên gọi | Cán bộ qua BFF của cổng; PH-20 gọi `merge-transfers` bằng token dịch vụ (`ops:merge-transfer`) | Mọi DU qua thư viện `dh-ops-client`; máy chủ thư, SMS gateway; CronJob sao lưu; bộ so sánh bóng |
| Xác thực | OIDC và PKCE ở BFF (quyền `PERM-18-*`) | `client_credentials`, mTLS và danh tính SPIFFE; một trong 14 scope `ops:*` |
| Operation | 161 | 27 |
| Hiệu năng | Đọc p95 ≤ 500 ms, ghi p95 ≤ 1 s | Đọc lô tham số p95 ≤ 50 ms (có bộ đệm phía DU), gửi thông báo bất đồng bộ p95 ≤ 200 ms |
| Khi PH-18 không khả dụng | Màn vận hành báo lỗi, không ảnh hưởng chức năng nghiệp vụ | DU dùng giá trị trong bộ đệm `dh-ops-client`; DLQ dồn trong Kafka, không mất; thông báo nằm ở outbox của bên gọi |

: Hai mặt API của PH-18

### 1.2. Phiên bản hóa và tương thích

Phiên bản nằm ở đường dẫn (`v1`). Thay đổi tương thích ngược (thêm trường tùy chọn, thêm giá trị enum ở phản hồi, thêm operation) vào `v1`; thay đổi phá vỡ (xóa hay đổi tên trường, đổi kiểu, thêm trường bắt buộc, đổi ngữ nghĩa mã lỗi) sang `v2` chạy song song tối thiểu 6 tháng. API nội bộ được giữ tương thích chặt hơn vì mọi DU phụ thuộc: chỉ thêm, không bỏ trong một phiên bản `dh-ops-client`. Sự kiện đổi phiên bản bằng hậu tố topic `.v2`.

### 1.3. Hạn mức gọi

Vượt hạn mức trả `429` ERR-18-010 kèm `Retry-After`; mã này gắn ở mọi operation. Các con số dưới đây là giả định thiết kế, chưa có khóa `18.*` riêng (Q18-56).

| Mặt API, đối tượng | Hạn mức | Khi vượt |
|---|---|---|
| API người dùng, mỗi người dùng | 300 yêu cầu mỗi phút | `429` kèm `Retry-After` |
| Xuất CSV DLQ (API-18-042), mỗi người dùng | 5 lệnh mỗi giờ, tối đa 50.000 dòng | `429` |
| Đọc lô tham số (API-18-028), mỗi DU | 1.200 yêu cầu mỗi phút; DU đọc qua bộ đệm và `ETag` nên tải thật thấp hơn nhiều | `429`, DU dùng bộ đệm |
| Gửi thông báo (API-18-091), mỗi DU | 600 yêu cầu mỗi phút | `429`, bên gọi giữ ở outbox và thử lại |
| Ghi DLQ qua API (API-18-035, 036), mỗi DU | 300 yêu cầu mỗi phút, lô tới 500 mục | `429`, nguồn chuyển sang ghi topic |

: Hạn mức gọi của API PH-18

## 2. Xác thực và phân quyền

Chương này nêu quyền chức năng của người dùng, scope của tài khoản máy, các cặp tách nhiệm vụ và lỗi xác thực dùng chung.

### 2.1. Quyền người dùng

Mỗi operation ghi quyền `PERM-18-*` ở `x-datahub-permission`; dấu `/` là một trong các quyền đủ để gọi. Mười một quyền đều có ở D02-08 (FRS §3.2). Bảng sinh dưới đây đếm số operation theo quyền và scope.

<!-- gen:perm:start -->
| Quyền hoặc scope | Số operation | Operation |
|---|---|---|
| `PERM-18-admin` | 11 | 017…019, 021, 023, 032, 033, 059, 155, 179, 187 |
| `PERM-18-approve` | 16 | 008…011, 055, 056, 070, 071, 088, 089, 142, 143, 146, 167, 168, 175 |
| `PERM-18-backup` | 15 | 133, 134, 136, 138…141, 144, 145, 147…149, 151, 152, 154 |
| `PERM-18-calendar` | 5 | 114, 115, 119…121 |
| `PERM-18-config` | 9 | 006…009, 012, 015, 022, 025, 026 |
| `PERM-18-dlq` | 27 | 037…040, 042, 044, 046, 048…052, 063…069, 072…075, 077…080 |
| `PERM-18-dlq-payload` | 3 | 047, 053, 054 |
| `PERM-18-incident` | 7 | 124, 126…131 |
| `PERM-18-migration` | 22 | 156…166, 169…175, 182…185 |
| `PERM-18-read` | 27 | 001…005, 013, 014, 016, 020, 024, 031, 041, 043, 045 … |
| `PERM-18-template` | 13 | 082…087, 090, 099…101, 103…105 |
| `Đăng nhập (mọi vai trò)` | 7 | 095…098, 111, 112, 181 |
| `scope ops:backup-report` | 2 | 135, 137 |
| `scope ops:calendar-read` | 3 | 116, 117, 122 |
| `scope ops:dlq-read` | 3 | 060…062 |
| `scope ops:dlq-write` | 3 | 034…036 |
| `scope ops:incident-write` | 1 | 132 |
| `scope ops:merge-transfer` | 2 | 150, 153 |
| `scope ops:notify` | 5 | 091…094, 106 |
| `scope ops:param-read` | 2 | 028, 029 |
| `scope ops:param-register` | 1 | 027 |
| `scope ops:param-write` | 1 | 030 |
| `scope ops:replay-callback` | 2 | 076, 188 |
| `scope ops:shadow-ingest` | 1 | 176 |
| `scope ops:task` | 3 | 107, 109, 110 |

: Số operation theo quyền chức năng và scope máy
<!-- gen:perm:end -->

### 2.2. Scope máy

Token dịch vụ lấy bằng `client_credentials` có mTLS; API nội bộ kiểm DU nào có scope nào theo SPIFFE ID. Scope `ops:backup-report`, `ops:merge-transfer`, `ops:shadow-ingest` là đề nghị mới so với brief chung (FRS §12.4).

| Scope | Dùng bởi | Operation |
|---|---|---|
| `ops:param-read` | Mọi DU | API-18-028, 029 |
| `ops:param-register` | Mọi DU (phân hệ chủ không gian tên) | API-18-027 |
| `ops:param-write` | PH-20 | API-18-030 |
| `ops:dlq-write` | PH-01, PH-06, PH-08, PH-19, `dh-runtime` | API-18-034…036 |
| `ops:dlq-read` | PH-17, PH-13 (token đổi từ người dùng, RFC 8693) | API-18-060…062 |
| `ops:replay-callback` | Phân hệ nguồn DLQ | API-18-076 |
| `ops:notify` | Mọi DU gửi thông báo, máy chủ thư, SMS gateway | API-18-091…094, 106 |
| `ops:task` | PH-01, 02, 04, 11, 15, 16 và DU khác | API-18-107, 109, 110 |
| `ops:calendar-read` | PH-01, 02, 04, 08 | API-18-116, 117, 122 |
| `ops:incident-write` | PH-13, PH-09 | API-18-132 |
| `ops:backup-report` | Tác vụ thu thập, CronJob kiểm tra khôi phục | API-18-135, 137 |
| `ops:merge-transfer` | PH-20 | API-18-150, 153 |
| `ops:shadow-ingest` | Bộ so sánh bóng | API-18-176 |
| `ops:migration-import` | Phân hệ đích | Không có operation ở PH-18; `dh-migrate` dùng scope này khi gọi API nhập của phân hệ đích |

: Scope máy của API PH-18

### 2.3. Tách nhiệm vụ

Người đề nghị không được là người duyệt; máy chủ so `createdBy` của đối tượng với người gọi `:approve` và trả `403` ERR-18-005 khi trùng. Việc duyệt được tạo trong "Việc của tôi" với `fourEyes = true` nên ẩn với người đề nghị.

| Cặp loại trừ | Nơi ép | Mã lỗi |
|---|---|---|
| Người đề nghị đổi tham số ★ và người duyệt | API-18-010, 011 (đề nghị sinh từ API-18-006, 015, 019) | ERR-18-005 |
| Người tạo bản sửa payload có dữ liệu Hạn chế và người duyệt | API-18-055, 056 | ERR-18-005 |
| Người tạo lượt phát lại vượt ngưỡng và người duyệt | API-18-070, 071 | ERR-18-005 |
| Người soạn phiên bản mẫu thông báo và người duyệt | API-18-088, 089 | ERR-18-005 |
| Người tạo yêu cầu khôi phục tenant (TA) và người duyệt (PA) | API-18-142, 143 | ERR-18-005 |
| Người tạo lần chạy di trú thật và người duyệt | API-18-167, 168 | ERR-18-005 |
| Người đề nghị cắt chuyển nhóm dịch vụ và người xác nhận | API-18-175 | ERR-18-005 |
| AU giữ `PERM-18-read` nhưng không giữ `PERM-18-dlq` hay `PERM-18-approve` | Gán vai trò ở PH-12 | ERR-00-403 |

: Tách nhiệm vụ trong API PH-18

### 2.4. Lỗi xác thực

Thiếu hoặc hết hạn token trả `401` (mã nền ERR-00-401); thiếu quyền chức năng hoặc scope trả `403` (ERR-00-403); thiếu `If-Match` trả `428` (ERR-00-428). Ba mã nền này dùng chung toàn nền tảng, không thuộc dải ERR-18. Mục DLQ mà IE hoặc DS không được giao (thuộc tính ABAC của PH-12) trả `404` ERR-18-001 thay cho `403` để không lộ sự tồn tại.

## 3. Kiến trúc và sơ đồ trình tự luồng chính

Chương này trình bày sáu luồng chính đi qua nhiều operation và nhiều phân hệ. Mỗi sơ đồ dùng mã API-18 và EVT-18 của chương 4 và 5; chi tiết lỗi của từng bước ở chương 14.

### 3.1. Tiếp nhận, phân loại và phát lại DLQ

Nguồn ghi bản tin lỗi vào topic DLQ chung kèm header ngữ cảnh; PH-18 ghi chỉ mục, người vận hành phân loại rồi tạo lượt phát lại. Lượt vượt ngưỡng cần người thứ hai duyệt; nguồn nhận lại bản tin qua lối vào của mình và báo kết quả.

```{.mermaid caption="Trình tự tiếp nhận, phân loại và phát lại DLQ có bốn mắt"}
sequenceDiagram
  participant N as Nguồn PH-04 runtime
  participant K as Kafka
  participant O as dh-platform ops
  participant U as Người vận hành
  participant D as Người duyệt
  N->>K: Ghi bản tin lỗi kèm header dh-dlq vào topic ops.dlq.v1
  K->>O: Tiêu thụ lô, kiểm ngữ cảnh, ghi chỉ mục NEW hoặc POISON
  O->>K: Phát EVT-18-05 gộp theo phút
  U->>O: GET dlq/messages lọc theo nguồn và mã lỗi (API-18-041)
  U->>O: POST triage gán lớp lỗi và ưu tiên (API-18-049)
  U->>O: POST replay-jobs theo bộ lọc (API-18-065)
  U->>O: POST submit với If-Match (API-18-069)
  O-->>U: 200 PENDING_APPROVAL vì vượt ngưỡng 500 mục
  O->>D: Tạo việc duyệt trong Việc của tôi
  D->>O: POST approve (API-18-070)
  O->>K: Phát EVT-18-09 cho từng mục theo tốc độ giới hạn
  K->>N: Nguồn nhận lại bản tin qua lối vào của luồng
  N->>O: POST replay-results với khóa dlqId và revision (API-18-076)
  O->>K: Phát EVT-18-07 và EVT-18-10 khi lượt kết thúc
```

Hình cho thấy PH-18 không gửi thẳng tới hệ đích: phát lại luôn đi qua lối vào của nguồn nên kiểm lược đồ, chuyển đổi và kiểm toán của luồng được chạy lại. Lượt dưới ngưỡng bỏ qua hai bước duyệt và chạy ngay sau `:submit`.

### 3.2. Đổi tham số bảo mật ★ và làm mới bộ đệm

Người quản trị tỉnh ghi giá trị một khóa ★; PH-18 tạo đề nghị chờ duyệt thay vì ghi ngay. Khi người thứ hai duyệt, giá trị thành hiệu lực và mọi DU làm mới bộ đệm theo sự kiện.

```{.mermaid caption="Trình tự đổi tham số bảo mật qua bốn mắt và làm mới bộ đệm DU"}
sequenceDiagram
  participant A as Quản trị tỉnh
  participant O as dh-platform ops
  participant B as Người duyệt
  participant K as Kafka
  participant C as DU qua dh-ops-client
  A->>O: GET params theo khóa, nhận ETag (API-18-005)
  A->>O: PUT params với If-Match và lý do (API-18-006)
  O-->>A: 202 kèm đề nghị PENDING
  O->>K: Phát EVT-18-02 tạo việc duyệt
  B->>O: POST param-change-requests approve (API-18-010)
  O->>K: Phát EVT-18-01 khóa và phiên bản mới, không mang giá trị bảo mật
  K->>C: DU xóa mục đệm của khóa
  C->>O: POST params batch-get với If-None-Match (API-18-028)
  O-->>C: 200 giá trị hiệu lực mới hoặc 304
```

Hình cho thấy sự kiện EVT-18-01 chỉ báo khóa và phiên bản; DU đọc lại giá trị qua API nội bộ nên giá trị khóa bảo mật không nằm trên Kafka. Khóa không ★ đi thẳng từ `PUT` sang EVT-18-01 và trả `200`.

### 3.3. Gửi thông báo qua NotificationApi

Phân hệ nghiệp vụ gửi thông báo theo mã mẫu và tham chiếu người nhận; PH-18 phân giải người nhận, áp tùy chọn và giờ yên lặng, dựng mẫu và gửi qua kênh. Thư trả lại cứng đưa địa chỉ vào danh sách chặn.

```{.mermaid caption="Trình tự gửi thông báo bất đồng bộ và xử lý thư trả lại"}
sequenceDiagram
  participant P as Phân hệ gọi
  participant O as dh-platform ops
  participant I as PH-12 và PH-01
  participant M as Máy chủ thư hoặc SMS gateway
  participant K as Kafka
  P->>O: POST notifications với mã mẫu và recipientRef (API-18-091)
  O-->>P: 202 kèm messageId
  O->>I: Phân giải người, vai trò, đầu mối HTTT
  O->>O: Áp tùy chọn, giờ yên lặng, danh sách chặn, dựng mẫu ACTIVE
  O->>M: Gửi qua kênh EMAIL, SMS hoặc IN_APP
  M->>O: POST notifications bounces báo trả lại cứng (API-18-106)
  O->>K: Phát EVT-18-12 và thêm địa chỉ vào danh sách chặn
  P->>O: GET notifications theo messageId (API-18-093)
  O-->>P: 200 trạng thái theo từng người nhận đã che
```

Hình cho thấy bên gọi không biết địa chỉ thật của người nhận; trạng thái trả về chỉ có địa chỉ đã che. Chế độ đồng bộ API-18-092 chỉ dùng cho thư mang liên kết, chờ máy chủ thư nhận trong `18.notify.sync.timeout-ms` (mặc định 3.000 ms) rồi trả `200` hoặc `503` ERR-18-044.

### 3.4. Khôi phục tenant có bốn mắt

Quản trị tỉnh tạo yêu cầu khôi phục tenant về một thời điểm; quản trị nền tảng duyệt thì PH-18 tạo Job `dh-tenant-restore` chạy tám bước. Bước 5 đến 8 lỗi thì quay lui từ bản trích trước khi thay.

```{.mermaid caption="Trình tự khôi phục tenant tám bước có duyệt và quay lui"}
sequenceDiagram
  participant T as Quản trị tỉnh
  participant O as dh-platform ops
  participant P as Quản trị nền tảng
  participant J as Job dh-tenant-restore
  participant K as Kafka
  T->>O: POST tenant-restores với thời điểm đích và phạm vi (API-18-138)
  T->>O: POST submit với If-Match (API-18-141)
  O->>K: Phát EVT-18-21 PENDING_APPROVAL
  P->>O: POST approve (API-18-142)
  O->>J: Tạo Job, khóa tác vụ nặng của tenant
  J->>O: Báo từng bước, số dòng thay thế theo bảng
  T->>O: GET steps theo dõi tám bước (API-18-145)
  J->>O: Bước 8 xong
  O->>K: Phát EVT-18-22 để mọi DU xóa bộ đệm và đồng bộ lại
```

Hình cho thấy tenant chỉ chạy một tác vụ nặng tại một thời điểm (BR-18-039): yêu cầu khác trả `409` ERR-18-006 cho tới khi Job kết thúc. Khi bước 5 đến 8 lỗi, người vận hành gọi `:rollback` (API-18-146) mà không cần bốn mắt.

### 3.5. Di trú thật, chạy song song và cắt chuyển

Kế hoạch di trú ở `READY` mới tạo được lần chạy; lần chạy thật cần người thứ hai duyệt. Sau khi nạp xong, nhóm dịch vụ chạy song song, bộ so sánh bóng gửi cặp phản hồi đã băm, rồi người vận hành cắt chuyển và quay lui được trong cửa sổ cho phép.

```{.mermaid caption="Trình tự chạy di trú thật, so sánh bóng và cắt chuyển có quay lui"}
sequenceDiagram
  participant U as Người vận hành
  participant O as dh-platform ops
  participant B as Người duyệt
  participant M as dh-migrate
  participant S as Bộ so sánh bóng
  participant K as Kafka
  U->>O: POST migration-runs loại REAL (API-18-164)
  B->>O: POST migration-runs approve (API-18-167)
  O->>M: Chạy theo thứ tự phụ thuộc, gọi API nhập của phân hệ đích
  M->>O: Báo số bản ghi, bản ghi lỗi, tổng kiểm tra
  O->>K: Phát EVT-18-25 và EVT-18-26 khi cần cấp lại thông tin xác thực
  S->>O: POST shadow-samples cặp phản hồi đã băm (API-18-176)
  U->>O: GET parallel-groups xem tỷ lệ khớp (API-18-174)
  U->>O: POST transition sang CUT_OVER với If-Match (API-18-175)
  O->>K: Phát EVT-18-27 để PH-03 đổi tuyến và PH-10 tắt cầu nối
  U->>O: POST transition ROLLED_BACK trong cửa sổ quay lui
```

Hình cho thấy nhóm chỉ sang `SHADOW_OK` khi tỷ lệ khớp đạt `18.migration.parallel.match-threshold-percent`, và từ `CUT_OVER` chỉ quay lui được trong `18.migration.rollback-window-minutes`; ngoài cửa sổ trả `409` ERR-18-006.

### 3.6. Chuyển dữ liệu sáp nhập tenant cho PH-20

Khi sáp nhập tenant, PH-20 yêu cầu PH-18 chuyển dữ liệu vận hành của từng phân hệ từ tenant nguồn sang tenant đích. PH-18 chạy Job ở chế độ trích và nạp, báo tiến độ qua sự kiện và qua API đọc.

```{.mermaid caption="Trình tự chuyển dữ liệu sáp nhập do PH-20 điều phối"}
sequenceDiagram
  participant P as PH-20
  participant K as Kafka
  participant O as dh-platform ops
  participant J as Job dh-tenant-export
  participant A as Quản trị nền tảng
  K->>O: Tiêu thụ platform.tenant.merge-started.v1
  P->>O: POST merge-transfers với mergePlanId và phân hệ (API-18-150)
  O-->>P: 202 kèm transferId ở QUEUED
  O->>J: Trích dữ liệu tenant nguồn, nạp vào tenant đích
  J->>O: Báo số bản ghi và lỗi theo bảng
  O->>K: Phát EVT-18-24 theo từng chuyển đổi trạng thái
  O->>P: POST merge-plans participants report báo tiến độ của phân hệ
  A->>O: GET merge-transfers theo mergePlanId (API-18-151)
  O-->>A: 200 tiến độ của mọi chuyển trong kế hoạch
```

Hình cho thấy PH-20 theo dõi bằng EVT-18-24, còn quản trị nền tảng xem tiến độ bằng API-18-151, 152 (`PERM-18-backup`); PH-20 muốn dừng thì gọi `:cancel` (API-18-153). Hai operation của PH-20 (API-18-150, 153) dùng scope `ops:merge-transfer`, lũy đẳng theo `mergePlanId` cùng phân hệ nên không cần `If-Match`.

## 4. Danh mục endpoint

Mỗi bảng liệt kê operation của một nhóm theo FRS §9.4. Cột "Idem." cho biết `Idempotency-Key` là bắt buộc hay tùy chọn, "TC" là mã thành công, "Lỗi riêng" là mã ERR-18 gắn ngoài mã cấu trúc (mục 7.2). Đường dẫn của API người dùng bỏ tiền tố `/api/ops/v1`.

<!-- gen:catalog:start -->
### 4.1. Tham số và cờ tính năng

Không gian tên và lược đồ khóa, giá trị theo tenant có kiểm miền và trần, đề nghị bốn mắt cho khóa ★, phiên bản, gói tham số, cờ tính năng, egress, API nội bộ `ParameterApi` (FR-18-001…011). Nhóm có 30 operation (API-18-001…030).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-001 | `GET /param-namespaces` | Danh sách không gian tên tham số đã đăng ký, PH chủ sở hữu, số khóa, nhóm hiển thị | 001, 007 | read |  | 200 |  |
| API-18-002 | `GET /param-definitions` | Lược đồ khóa theo `ns`, `nhom`, cờ ★, mức `PLATFORM`/`TENANT`; dùng dựng màn tham số chung | 001, 007 | read |  | 200 |  |
| API-18-003 | `GET /param-definitions/{key}` | Lược đồ một khóa: kiểu, mặc định, miền, trần, `approvalOwner`, mô tả | 001, 005 | read |  | 200 | 011 |
| API-18-004 | `GET /params` | Giá trị hiệu lực của tenant theo `ns`, `nhom`, kèm nguồn giá trị (mặc định, tenant, trần) | 002, 007, 069 | read |  | 200 |  |
| API-18-005 | `GET /params/{key}` | Giá trị hiệu lực của một khóa kèm `ETag` và phiên bản | 002, 007 | read |  | 200 | 011 |
| API-18-006 | `PUT /params/{key}` | Ghi giá trị theo tenant có `If-Match`, lý do; khóa ★ tạo đề nghị chờ duyệt | 003, 004, 069 | config |  | 200, 202 | 011, 012, 013, 014, 015, 018, 019 |
| API-18-007 | `POST /params:validate` | Kiểm kiểu, miền, trần của một hoặc nhiều giá trị mà không ghi | 003, 007 | config |  | 200 | 011, 012, 013, 014, 015 |
| API-18-008 | `GET /param-change-requests` | Danh sách đề nghị đổi tham số ★ theo trạng thái | 004 | config / approve |  | 200 |  |
| API-18-009 | `GET /param-change-requests/{requestId}` | Chi tiết đề nghị: giá trị trước, sau, lý do, người đề nghị | 004 | config / approve |  | 200 |  |
| API-18-010 | `POST /param-change-requests/{requestId}:approve` | Duyệt đề nghị (người thứ hai), giá trị thành `ACTIVE` | 004 | approve | có | 200 | 013, 019 |
| API-18-011 | `POST /param-change-requests/{requestId}:reject` | Từ chối đề nghị kèm lý do | 004 | approve | có | 200 |  |
| API-18-012 | `POST /param-change-requests/{requestId}:withdraw` | Người đề nghị rút đề nghị chưa duyệt | 004 | config | có | 200 |  |
| API-18-013 | `GET /params/{key}/versions` | Lịch sử phiên bản giá trị của khóa theo tenant | 005 | read |  | 200 | 011 |
| API-18-014 | `GET /params/{key}/versions:compare` | So sánh hai phiên bản (`from`, `to`) hoặc so với mặc định | 005 | read |  | 200 | 011 |
| API-18-015 | `POST /params/{key}/versions/{versionNo}:restore` | Khôi phục giá trị của phiên bản cũ thành phiên bản mới | 005 | config | có | 200 | 011, 023 |
| API-18-016 | `GET /param-changes` | Nhật ký đổi tham số của tenant theo thời gian, không gian tên, người đổi | 005, 006, 070 | read |  | 200 |  |
| API-18-017 | `POST /param-bundles:export` | Xuất gói tham số của tenant theo không gian tên, có chữ ký và tổng kiểm tra | 008 | admin | có | 201 | 013, 020 |
| API-18-018 | `POST /param-bundles:import` | Nạp gói và chạy so khớp với lược đồ đích (`dryRun` mặc định `true`) | 008 | admin | có | 200 | 013, 020 |
| API-18-019 | `POST /param-bundles/{bundleId}:apply` | Áp gói đã so khớp; khóa ★ trong gói tạo đề nghị chờ duyệt | 008 | admin | có | 200 | 013, 020 |
| API-18-020 | `GET /feature-flags` | Danh sách cờ tính năng `ff.*`, chủ sở hữu, ngày gỡ, giá trị theo tenant | 009 | read |  | 200 |  |
| API-18-021 | `POST /feature-flags` | Khai báo cờ tính năng mới có chủ sở hữu, ngày gỡ dự kiến | 009 | admin | có | 201 | 021 |
| API-18-022 | `PATCH /feature-flags/{flagKey}` | Bật, tắt cờ cho tenant hoặc đổi ngày gỡ (`If-Match`) | 009 | config |  | 200 | 021 |
| API-18-023 | `POST /feature-flags/{flagKey}:retire` | Gỡ cờ sau khi mã đã bỏ nhánh cờ | 009 | admin | có | 200 |  |
| API-18-024 | `GET /egress-allowlist` | Danh sách đích egress cho phép của tenant theo mục đích | 010 | read |  | 200 |  |
| API-18-025 | `POST /egress-allowlist` | Thêm đích egress (FQDN, cổng, mục đích, hạn dùng) | 010 | config | có | 201 | 013, 022 |
| API-18-026 | `DELETE /egress-allowlist/{entryId}` | Gỡ đích egress kèm lý do | 010 | config |  | 204 |  |
| API-18-027 | `PUT /ops/internal/v1/param-namespaces/{ns}/schema` | PH chủ đăng ký hoặc cập nhật lược đồ khóa của không gian tên khi khởi động | 001 | scope ops:param-register |  | 200 | 016, 017 |
| API-18-028 | `POST /ops/internal/v1/params:batch-get` | Đọc lô giá trị hiệu lực của nhiều khóa, cờ, egress cho một tenant; hỗ trợ `If-None-Match` | 002, 009, 010 | scope ops:param-read |  | 200, 304 |  |
| API-18-029 | `GET /ops/internal/v1/params/{tenant}/{ns}` | Ảnh chụp toàn bộ không gian tên của tenant kèm `ETag` để làm bộ đệm | 002 | scope ops:param-read |  | 200, 304 |  |
| API-18-030 | `POST /ops/internal/v1/tenants/{tenant}/params:seed-defaults` | PH-20 ghi mặc định khi khởi tạo tenant, chỉ thêm khóa chưa có | 011 | scope ops:param-write | có | 200 |  |

: Danh mục API nhóm Tham số và cờ tính năng

### 4.2. Tiếp nhận DLQ

Nguồn DLQ và cổng phát lại, ghi DLQ qua API cho phân hệ khác, đối soát chỉ mục với Kafka, liên thông DLQ tầng sự kiện của PH-10 (FR-18-012…018). Nhóm có 10 operation (API-18-031…040).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-031 | `GET /dlq-sources` | Danh sách nguồn DLQ đã đăng ký, kiểu cổng phát lại, trạng thái | 012 | read |  | 200 |  |
| API-18-032 | `POST /dlq-sources` | Khai báo nguồn DLQ thủ công (nguồn không tự đăng ký) | 012 | admin | có | 201 |  |
| API-18-033 | `PATCH /dlq-sources/{sourceCode}` | Sửa cổng phát lại, tạm ngừng hoặc bật lại nguồn (`If-Match`) | 012 | admin |  | 200 |  |
| API-18-034 | `POST /ops/internal/v1/dlq-sources:register` | Nguồn tự đăng ký hoặc cập nhật cổng phát lại khi khởi động | 012 | scope ops:dlq-write | có | 200 | 017 |
| API-18-035 | `POST /ops/internal/v1/dlq/messages` | PH khác ghi một mục DLQ kèm ngữ cảnh chuẩn (PH-01, PH-06, PH-08, PH-19) | 014, 015, 016 | scope ops:dlq-write | có | 201 | 024, 025, 026 |
| API-18-036 | `POST /ops/internal/v1/dlq/messages:batch` | Ghi lô tới 500 mục DLQ, kết quả theo từng mục | 014, 015, 016 | scope ops:dlq-write | có | 207 | 024, 025, 026 |
| API-18-037 | `GET /dlq/reconciliation` | Kết quả đối soát chỉ mục và Kafka gần nhất theo phân vùng | 018 | dlq |  | 200 |  |
| API-18-038 | `POST /dlq/reconciliation:run` | Chạy đối soát ngay ngoài lịch | 018 | dlq | có | 202 |  |
| API-18-039 | `GET /dlq/event-dead-letters` | Siêu dữ liệu DLQ tầng sự kiện của PH-10 hiển thị chung (gọi API-10-060) | 017 | dlq |  | 200 | 035 |
| API-18-040 | `POST /dlq/event-dead-letters/{entryRef}:request-replay` | Đề nghị PH-10 phát lại mục DLQ tầng sự kiện (gọi API-10-064) | 017 | dlq | có | 202 | 035 |

: Danh mục API nhóm Tiếp nhận DLQ

### 4.3. Phân loại và xử lý DLQ

Danh sách có `facets`, nhóm dấu hiệu lỗi, chi tiết và chẩn đoán từ PH-13, xem payload có lý do, phân loại, gán, bản sửa payload, sổ tay mã lỗi, API đọc cho PH-17 và PH-13 (FR-18-019…026). Nhóm có 23 operation (API-18-041…063).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-041 | `GET /dlq/messages` | Danh sách mục DLQ: lọc, tìm, sắp xếp, phân trang, khối `facets` (siêu dữ liệu, thao tác cần `PERM-18-dlq`) | 019, 023 | read |  | 200 |  |
| API-18-042 | `GET /dlq/messages:export` | Xuất danh sách đang lọc ra CSV (chỉ siêu dữ liệu, tối đa 50.000 dòng) | 019 | dlq |  | 200 |  |
| API-18-043 | `GET /dlq/groups` | Nhóm mục DLQ theo dấu hiệu lỗi, số mục, tuổi, nguồn | 020 | read |  | 200 |  |
| API-18-044 | `POST /dlq/groups/{groupId}:assign` | Gán người xử lý, ưu tiên cho cả nhóm | 020, 023 | dlq | có | 200 |  |
| API-18-045 | `GET /dlq/messages/{dlqId}` | Chi tiết mục: ngữ cảnh, phân loại, lịch sử trạng thái, bản sửa, lượt phát lại (không payload) | 021 | read |  | 200 |  |
| API-18-046 | `GET /dlq/messages/{dlqId}/diagnostics` | Ngữ cảnh chẩn đoán từ PH-13 (API-13-069), trả một phần khi PH-13 vắng | 021 | dlq |  | 200, 206 |  |
| API-18-047 | `POST /dlq/messages/{dlqId}/payload:reveal` | Mở xem payload có lý do, trả phiếu xem 15 phút và nội dung đã che trường mã hóa | 022 | dlq-payload | có | 200 | 027 |
| API-18-048 | `GET /dlq/messages/{dlqId}/payload/skeleton` | Khung cấu trúc payload không có giá trị (tên trường, kiểu) | 022, 026 | dlq |  | 200 |  |
| API-18-049 | `POST /dlq/messages/{dlqId}:triage` | Gán lớp lỗi, ưu tiên, ghi chú; `NEW` sang `TRIAGED` | 023 | dlq | có | 200 |  |
| API-18-050 | `POST /dlq/messages/{dlqId}:assign` | Gán hoặc nhận người xử lý | 023 | dlq | có | 200 |  |
| API-18-051 | `POST /dlq/messages:bulk-triage` | Phân loại, gán hàng loạt theo danh sách tới 1.000 mục | 023 | dlq | có | 207 |  |
| API-18-052 | `GET /dlq/messages/{dlqId}/revisions` | Danh sách bản sửa payload và trạng thái duyệt | 024 | dlq |  | 200 |  |
| API-18-053 | `POST /dlq/messages/{dlqId}/revisions` | Tạo bản sửa payload (nội dung mới, lý do), kiểm lược đồ | 024 | dlq-payload | có | 201 | 029, 030 |
| API-18-054 | `GET /dlq/messages/{dlqId}/revisions/{revisionNo}/diff` | Khác biệt giữa bản gốc và bản sửa, trường nhạy cảm che | 024 | dlq-payload |  | 200 |  |
| API-18-055 | `POST /dlq/messages/{dlqId}/revisions/{revisionNo}:approve` | Duyệt bản sửa có dữ liệu Hạn chế (người thứ hai) | 024 | approve | có | 200 |  |
| API-18-056 | `POST /dlq/messages/{dlqId}/revisions/{revisionNo}:reject` | Từ chối bản sửa kèm lý do | 024 | approve | có | 200 |  |
| API-18-057 | `GET /error-guides` | Sổ tay xử lý theo mã lỗi: tìm theo mã, PH, lớp lỗi | 025 | read |  | 200 |  |
| API-18-058 | `GET /error-guides/{errCode}` | Hướng dẫn của một mã lỗi: nguyên nhân, bước xử lý, có phát lại được không | 025, 021 | read |  | 200 |  |
| API-18-059 | `PUT /error-guides/{errCode}` | Soạn, sửa hướng dẫn của một mã (`If-Match`), phát EVT-18-11 | 025 | admin |  | 200 |  |
| API-18-060 | `GET /ops/internal/v1/dlq/messages` | PH-17, PH-13 đọc danh sách siêu dữ liệu DLQ bằng token đổi từ người dùng | 026 | scope ops:dlq-read |  | 200 |  |
| API-18-061 | `GET /ops/internal/v1/dlq/messages/{dlqId}` | PH-17 đọc siêu dữ liệu một mục; payload chỉ khi người dùng có `PERM-18-dlq-payload` | 026 | scope ops:dlq-read |  | 200 |  |
| API-18-062 | `GET /ops/internal/v1/error-guides:feed` | Nguồn tri thức sổ tay ERR cho PH-17 lập chỉ mục, theo `updatedSince` | 025, 026 | scope ops:dlq-read |  | 200 |  |
| API-18-063 | `GET /dlq/messages/{dlqId}/audit` | Nhật ký thao tác trên một mục DLQ | 023, 070 | dlq |  | 200 |  |

: Danh mục API nhóm Phân loại và xử lý DLQ

### 4.4. Phát lại, bỏ qua và lưu giữ

Phát lại một mục, lượt phát lại loạt có bốn mắt, điều khiển tốc độ, kết quả lũy đẳng, bỏ qua, mở lại, lưu giữ, thống kê (FR-18-027…034). Nhóm có 19 operation (API-18-064…081, 188).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-064 | `POST /dlq/messages/{dlqId}:replay` | Phát lại một mục (bản gốc hoặc bản sửa đã duyệt) | 027, 030 | dlq | có | 202 | 027, 028, 031, 033 |
| API-18-065 | `POST /replay-jobs` | Tạo lượt phát lại loạt theo bộ lọc hoặc danh sách (`DRAFT`) | 028 | dlq | có | 201 | 032, 036 |
| API-18-066 | `GET /replay-jobs` | Danh sách lượt phát lại, tiến độ, trạng thái | 028, 029 | dlq |  | 200 |  |
| API-18-067 | `GET /replay-jobs/{jobId}` | Chi tiết lượt: tổng, thành công, thất bại, tốc độ, người duyệt | 028, 029, 030 | dlq |  | 200 |  |
| API-18-068 | `GET /replay-jobs/{jobId}/items` | Kết quả từng mục trong lượt | 028, 030 | dlq |  | 200 |  |
| API-18-069 | `POST /replay-jobs/{jobId}:submit` | Gửi lượt; dưới ngưỡng chạy ngay, trên ngưỡng chuyển chờ duyệt | 028 | dlq | có | 200 | 032, 036 |
| API-18-070 | `POST /replay-jobs/{jobId}:approve` | Duyệt lượt loạt lớn (người thứ hai) | 028 | approve | có | 200 |  |
| API-18-071 | `POST /replay-jobs/{jobId}:reject` | Từ chối lượt kèm lý do | 028 | approve | có | 200 |  |
| API-18-072 | `POST /replay-jobs/{jobId}:pause` | Tạm dừng lượt đang chạy | 029 | dlq | có | 200 |  |
| API-18-073 | `POST /replay-jobs/{jobId}:resume` | Tiếp tục lượt đã tạm dừng | 029 | dlq | có | 200 |  |
| API-18-074 | `POST /replay-jobs/{jobId}:cancel` | Hủy lượt, mục chưa chạy trở về `TRIAGED` | 029 | dlq | có | 200 |  |
| API-18-075 | `PATCH /replay-jobs/{jobId}` | Đổi tốc độ phát lại của lượt (`If-Match`) | 029 | dlq |  | 200 | 037 |
| API-18-076 | `POST /ops/internal/v1/replay-results` | Nguồn báo kết quả phát lại theo khóa lũy đẳng `dlqId:revision` | 030 | scope ops:replay-callback | tùy chọn | 200 | 038 |
| API-18-077 | `POST /dlq/messages/{dlqId}:discard` | Bỏ qua một mục kèm lý do ≥ 10 ký tự | 031 | dlq | có | 200 |  |
| API-18-078 | `POST /dlq/messages:bulk-discard` | Bỏ qua hàng loạt tới 1.000 mục kèm một lý do chung | 031 | dlq | có | 207 |  |
| API-18-079 | `POST /dlq/messages/{dlqId}:reopen` | Mở lại mục đã bỏ qua trong hạn lưu giữ | 032 | dlq | có | 200 | 034 |
| API-18-080 | `GET /dlq/retention` | Số mục sắp hết hạn, lần dọn gần nhất, dung lượng Garage của DLQ | 033 | dlq |  | 200 |  |
| API-18-081 | `GET /dlq/stats` | Thống kê DLQ theo nguồn, luồng, lớp lỗi, trạng thái, tuổi, xu hướng theo `khoang` | 034, 071 | read |  | 200 |  |
| API-18-188 | `GET /ops/internal/v1/replay-payloads/{dlqId}/{revision}` | Nguồn có cổng `KAFKA_TOPIC` lấy nội dung cần phát lại theo `payloadRef` của EVT-18-09 (bản gốc khi `revision = 0`) | 027, 028 | scope ops:replay-callback |  | 200 | 038 |

: Danh mục API nhóm Phát lại, bỏ qua và lưu giữ

### 4.5. Thông báo

Mẫu thông báo có phiên bản và kiểm trường cấm, `NotificationApi` bất đồng bộ và đồng bộ, người nhận, tùy chọn nhận, quy tắc theo sự kiện, nhật ký gửi, thư trả lại, danh sách chặn (FR-18-035…041). Nhóm có 25 operation (API-18-082…106).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-082 | `GET /notification-templates` | Danh sách mẫu thông báo theo kênh, PH, trạng thái | 035 | template |  | 200 |  |
| API-18-083 | `POST /notification-templates` | Tạo mẫu mới (mã, kênh, PH chủ, biến khai báo) | 035 | template | có | 201 |  |
| API-18-084 | `GET /notification-templates/{templateCode}` | Chi tiết mẫu và các phiên bản | 035 | template |  | 200 |  |
| API-18-085 | `POST /notification-templates/{templateCode}/versions` | Tạo phiên bản nháp nội dung mẫu | 035 | template | có | 201 | 039, 040 |
| API-18-086 | `POST /notification-templates/{templateCode}/versions/{versionNo}:preview` | Dựng thử với dữ liệu mẫu, chạy kiểm trường cấm | 035 | template |  | 200 | 039, 040 |
| API-18-087 | `POST /notification-templates/{templateCode}/versions/{versionNo}:submit` | Gửi duyệt phiên bản (`DRAFT` sang `IN_REVIEW`) | 035 | template | có | 200 | 039, 040 |
| API-18-088 | `POST /notification-templates/{templateCode}/versions/{versionNo}:approve` | Duyệt phiên bản thành `ACTIVE` (người thứ hai) | 035 | approve | có | 200 |  |
| API-18-089 | `POST /notification-templates/{templateCode}/versions/{versionNo}:reject` | Trả phiên bản về `DRAFT` kèm lý do | 035 | approve | có | 200 |  |
| API-18-090 | `POST /notification-templates/{templateCode}:retire` | Ngừng mẫu (`RETIRED`) | 035 | template | có | 200 |  |
| API-18-091 | `POST /ops/internal/v1/notifications` | Gửi thông báo bất đồng bộ (outbox), lũy đẳng theo `Idempotency-Key` | 036, 037, 038 | scope ops:notify | có | 202 | 039, 041, 042 |
| API-18-092 | `POST /ops/internal/v1/notifications:send-sync` | Gửi thư mang liên kết ở chế độ đồng bộ, chờ máy chủ thư nhận | 036, 037 | scope ops:notify | có | 200 | 039, 041, 042, 044 |
| API-18-093 | `GET /ops/internal/v1/notifications/{messageId}` | Trạng thái một thông báo đã gửi cho bên gọi | 036, 041 | scope ops:notify |  | 200 |  |
| API-18-094 | `POST /ops/internal/v1/recipients:resolve` | Phân giải `recipientRef` thành danh sách người nhận (không trả địa chỉ cho bên gọi) | 037 | scope ops:notify |  | 200 | 042 |
| API-18-095 | `GET /me/notification-preferences` | Tùy chọn nhận thông báo của người dùng theo loại, kênh, giờ yên lặng | 038 | đăng nhập |  | 200 |  |
| API-18-096 | `PUT /me/notification-preferences` | Lưu tùy chọn nhận thông báo (`If-Match`) | 038 | đăng nhập |  | 200 | 046 |
| API-18-097 | `GET /me/notifications` | Thông báo trong ứng dụng của người dùng, số chưa đọc | 036, 038 | đăng nhập |  | 200 |  |
| API-18-098 | `POST /me/notifications/{notificationId}:read` | Đánh dấu đã đọc một hoặc tất cả thông báo | 036 | đăng nhập | tùy chọn | 200 |  |
| API-18-099 | `GET /notification-rules` | Quy tắc sự kiện sang mẫu và người nhận | 039 | template |  | 200 |  |
| API-18-100 | `POST /notification-rules` | Tạo quy tắc (sự kiện, điều kiện, mẫu, người nhận, mức) | 039 | template | có | 201 | 041, 045 |
| API-18-101 | `PATCH /notification-rules/{ruleId}` | Sửa, bật, tắt quy tắc (`If-Match`) | 039 | template |  | 200 | 041, 045 |
| API-18-102 | `GET /notification-deliveries` | Nhật ký gửi theo người nhận đã che, kênh, trạng thái, nguồn | 040, 041 | read |  | 200 |  |
| API-18-103 | `POST /notification-deliveries/{deliveryId}:resend` | Gửi lại một thông báo `FAILED` hoặc `BOUNCED` sau khi sửa đầu mối | 040, 041 | template | có | 202 | 043 |
| API-18-104 | `GET /suppressions` | Danh sách chặn do thư trả lại cứng hoặc người dùng hủy nhận | 040 | template |  | 200 |  |
| API-18-105 | `DELETE /suppressions/{suppressionId}` | Gỡ địa chỉ khỏi danh sách chặn kèm lý do | 040 | template |  | 204 |  |
| API-18-106 | `POST /ops/internal/v1/notifications/bounces` | Máy chủ thư hoặc SMS gateway báo thư trả lại, báo nhận | 040 | scope ops:notify | tùy chọn | 202 |  |

: Danh mục API nhóm Thông báo

### 4.6. Việc của tôi và lịch

`TaskInboxApi` (loại việc, tạo, đóng việc lũy đẳng, Việc của tôi), `WorkingCalendarApi` (lịch năm, tính hạn), cửa sổ bảo trì và đóng băng (FR-18-042…046). Nhóm có 17 operation (API-18-107…122, 181).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-107 | `POST /ops/internal/v1/task-types` | PH đăng ký loại việc (mã, tên, quyền xem, hạn mặc định, liên kết màn) | 042 | scope ops:task | có | 200 | 017 |
| API-18-108 | `GET /task-types` | Danh sách loại việc đã đăng ký theo PH | 042 | read |  | 200 |  |
| API-18-109 | `PUT /ops/internal/v1/tasks/{sourceRef}` | Tạo hoặc cập nhật việc lũy đẳng theo `sourceRef` | 043 | scope ops:task |  | 200 | 047, 048 |
| API-18-110 | `POST /ops/internal/v1/tasks/{sourceRef}:close` | Đóng việc (`DONE`, `CANCELLED`) lũy đẳng | 043 | scope ops:task | có | 200 | 048 |
| API-18-111 | `GET /me/tasks` | Việc của tôi: lọc theo loại, hạn, trạng thái; `?summary=true` cho thẻ trang chủ | 044 | đăng nhập |  | 200 |  |
| API-18-112 | `GET /me/tasks/{taskId}` | Chi tiết việc và liên kết sang màn của PH nguồn | 044 | đăng nhập |  | 200 |  |
| API-18-113 | `GET /calendars` | Lịch năm của tenant: ngày nghỉ cuối tuần, ngày lễ, ngày làm bù | 045 | read |  | 200 |  |
| API-18-114 | `PUT /calendars/{year}` | Ghi lịch năm của tenant (`If-Match`) | 045 | calendar |  | 200 | 049 |
| API-18-115 | `POST /calendars/{year}/holidays` | Thêm ngày lễ hoặc ngày làm bù | 045 | calendar | có | 201 | 049 |
| API-18-116 | `GET /ops/internal/v1/calendar/{tenant}:working-days` | Số ngày làm việc, danh sách ngày làm việc trong khoảng | 045 | scope ops:calendar-read |  | 200 |  |
| API-18-117 | `POST /ops/internal/v1/calendar/{tenant}:add-working-days` | Tính hạn: mốc cộng n ngày làm việc | 045 | scope ops:calendar-read |  | 200 |  |
| API-18-118 | `GET /maintenance-windows` | Cửa sổ bảo trì và đóng băng theo môi trường, thời gian | 046 | read |  | 200 |  |
| API-18-119 | `POST /maintenance-windows` | Tạo cửa sổ bảo trì hoặc đóng băng | 046 | calendar | có | 201 | 050 |
| API-18-120 | `PATCH /maintenance-windows/{windowId}` | Sửa cửa sổ chưa bắt đầu (`If-Match`) | 046 | calendar |  | 200 | 050 |
| API-18-121 | `POST /maintenance-windows/{windowId}:cancel` | Hủy cửa sổ kèm lý do | 046 | calendar | có | 200 |  |
| API-18-122 | `GET /ops/internal/v1/freeze-status/{tenant}` | Trạng thái đóng băng, bảo trì hiện hành theo môi trường cho PH-02, PH-04 | 046 | scope ops:calendar-read |  | 200 |  |
| API-18-181 | `POST /me/tasks/{taskId}:claim` | Nhận việc: chuyển `IN_PROGRESS`, ghi người nhận, báo người cùng nhận (EVT-18-14) | 044 | đăng nhập | có | 200 | 048 |

: Danh mục API nhóm Việc của tôi và lịch

### 4.7. Sự cố vận hành

Hồ sơ sự cố từ sự kiện hoặc tạo tay, vòng đời, mốc thời gian, liên kết, chuyển PH-09, đóng có nguyên nhân và bài học (FR-18-047…051). Nhóm có 10 operation (API-18-123…132).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-123 | `GET /incidents` | Danh sách sự cố vận hành theo mức, trạng thái, người xử lý | 047, 048 | read |  | 200 |  |
| API-18-124 | `POST /incidents` | Tạo sự cố thủ công | 048 | incident | có | 201 |  |
| API-18-125 | `GET /incidents/{incidentCode}` | Chi tiết sự cố, mốc thời gian, liên kết | 048, 049 | read |  | 200 |  |
| API-18-126 | `PATCH /incidents/{incidentCode}` | Đổi mức độ, người xử lý, tóm tắt (`If-Match`) | 048 | incident |  | 200 |  |
| API-18-127 | `POST /incidents/{incidentCode}:transition` | Chuyển trạng thái sự cố theo vòng đời | 048, 051 | incident | có | 200 |  |
| API-18-128 | `POST /incidents/{incidentCode}/timeline` | Thêm mốc thời gian, ghi chú, hành động | 049 | incident | có | 201 |  |
| API-18-129 | `POST /incidents/{incidentCode}/links` | Liên kết mục DLQ, nhóm lỗi, cảnh báo, lượt phát lại, sao lưu | 049 | incident | có | 201 |  |
| API-18-130 | `POST /incidents/{incidentCode}:escalate-privacy` | Chuyển sự cố có DLCN sang PH-09 (`INCIDENT_PH18`) | 050 | incident | có | 200 | 053, 054 |
| API-18-131 | `POST /incidents/{incidentCode}:close` | Đóng sự cố với nguyên nhân gốc, bài học, việc khắc phục | 051 | incident | có | 200 | 052 |
| API-18-132 | `POST /ops/internal/v1/incidents` | PH-13, PH-09 mở hoặc cập nhật sự cố theo `sourceRef` lũy đẳng | 047 | scope ops:incident-write | có | 200, 201 |  |

: Danh mục API nhóm Sự cố vận hành

### 4.8. Sao lưu, khôi phục và sáp nhập

Bảng sao lưu, kiểm tra khôi phục, khôi phục tenant tám bước có bốn mắt, xuất tenant, chuyển dữ liệu khi sáp nhập (PH-20), ghi nhận diễn tập DR (FR-18-052…058). Nhóm có 23 operation (API-18-133…155).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-133 | `GET /backup/objects` | Bảng đối tượng sao lưu, lần chạy gần nhất, độ tươi, kiểm tra khôi phục | 052 | backup |  | 200 | 055 |
| API-18-134 | `GET /backup/runs` | Lịch sử bản sao lưu theo đối tượng, kết quả, dung lượng | 052 | backup |  | 200 | 055 |
| API-18-135 | `POST /ops/internal/v1/backup/runs` | Tác vụ thu thập hoặc CronJob báo một bản sao lưu | 052 | scope ops:backup-report | tùy chọn | 202 |  |
| API-18-136 | `GET /backup/verifications` | Kết quả kiểm tra khôi phục tự động theo đối tượng | 053 | backup |  | 200 |  |
| API-18-137 | `POST /ops/internal/v1/backup/verifications` | CronJob kiểm tra khôi phục báo kết quả | 053 | scope ops:backup-report | tùy chọn | 202 |  |
| API-18-138 | `POST /tenant-restores` | Tạo yêu cầu khôi phục tenant (thời điểm đích, phạm vi) ở `DRAFT` | 054 | backup | có | 201 | 056, 057, 058 |
| API-18-139 | `GET /tenant-restores` | Danh sách yêu cầu khôi phục | 054, 055 | backup |  | 200 |  |
| API-18-140 | `GET /tenant-restores/{requestId}` | Chi tiết yêu cầu, ước tính, bước đang chạy | 054, 055 | backup |  | 200 |  |
| API-18-141 | `POST /tenant-restores/{requestId}:submit` | Gửi duyệt yêu cầu | 054 | backup | có | 200 | 056, 057, 058 |
| API-18-142 | `POST /tenant-restores/{requestId}:approve` | PA duyệt, tạo Job `dh-tenant-restore` | 055 | approve | có | 200 |  |
| API-18-143 | `POST /tenant-restores/{requestId}:reject` | Từ chối kèm lý do | 055 | approve | có | 200 |  |
| API-18-144 | `POST /tenant-restores/{requestId}:cancel` | Hủy yêu cầu chưa chạy | 054 | backup | có | 200 |  |
| API-18-145 | `GET /tenant-restores/{requestId}/steps` | Tám bước, thời gian, số dòng thay thế theo bảng | 055 | backup |  | 200 |  |
| API-18-146 | `POST /tenant-restores/{requestId}:rollback` | Quay lui khi bước 5 đến 8 lỗi (từ bản trích trước khi thay) | 055 | approve | có | 202 |  |
| API-18-147 | `POST /tenant-exports` | Tạo lệnh xuất dữ liệu tenant (bàn giao, chuyển ô) | 056 | backup | có | 201 | 057, 059 |
| API-18-148 | `GET /tenant-exports/{exportId}` | Chi tiết lệnh xuất, kích thước, tổng kiểm tra | 056 | backup |  | 200 |  |
| API-18-149 | `POST /tenant-exports/{exportId}:download-link` | Cấp liên kết tải có hạn 24 giờ, ghi kiểm toán | 056 | backup | có | 200 |  |
| API-18-150 | `POST /merge-transfers` | PH-20 yêu cầu chuyển dữ liệu một phân hệ khi sáp nhập tenant (`mergePlanId`, `module`, `dryRun`) | 057 | scope ops:merge-transfer | có | 202 | 060, 061 |
| API-18-151 | `GET /merge-transfers` | Danh sách chuyển sáp nhập theo `mergePlanId` | 057 | backup |  | 200 |  |
| API-18-152 | `GET /merge-transfers/{transferId}` | Tiến độ, số bản ghi, lỗi của một chuyển | 057 | backup |  | 200 |  |
| API-18-153 | `POST /merge-transfers/{transferId}:cancel` | PH-20 hủy chuyển chưa xong | 057 | scope ops:merge-transfer | có | 200 |  |
| API-18-154 | `GET /dr-drills` | Danh sách diễn tập DR, PITR toàn cụm đã ghi nhận | 058 | backup |  | 200 |  |
| API-18-155 | `POST /dr-drills` | Ghi nhận diễn tập: loại, thời điểm, RTO, RPO đo được, biên bản | 058 | admin | có | 201 |  |

: Danh mục API nhóm Sao lưu, khôi phục và sáp nhập

### 4.9. Di trú và chạy song song

Nguồn hệ cũ chỉ đọc, kế hoạch di trú, chạy thử và chạy thật có bốn mắt, bản ghi lỗi, đối chiếu, cấp lại thông tin xác thực, chạy song song, mẫu so sánh bóng, cắt chuyển và quay lui (FR-18-059…068). Nhóm có 25 operation (API-18-156…176, 182, 183, 184, 185).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-156 | `GET /legacy-sources` | Danh sách nguồn hệ cũ và trạng thái kết nối | 059 | migration |  | 200 |  |
| API-18-157 | `POST /legacy-sources` | Khai báo nguồn hệ cũ (JDBC chỉ đọc, tham chiếu OpenBao) | 059 | migration | có | 201 | 062, 070 |
| API-18-158 | `POST /legacy-sources/{sourceCode}:test-connection` | Thử kết nối, kiểm quyền chỉ đọc, đếm bảng | 059 | migration | có | 200 | 062 |
| API-18-159 | `GET /migration-plans` | Danh sách kế hoạch di trú | 060 | migration |  | 200 |  |
| API-18-160 | `POST /migration-plans` | Tạo kế hoạch di trú cho nguồn | 060 | migration | có | 201 |  |
| API-18-161 | `GET /migration-plans/{planCode}` | Chi tiết kế hoạch, thứ tự đối tượng, lần chạy | 060 | migration |  | 200 |  |
| API-18-162 | `PUT /migration-plans/{planCode}/items` | Ghi danh sách loại đối tượng, bộ chuyển, PH đích, thứ tự (`If-Match`) | 060 | migration |  | 200 | 063 |
| API-18-163 | `POST /migration-plans/{planCode}:mark-ready` | Kiểm thứ tự phụ thuộc, chuyển `READY` | 060 | migration | có | 200 | 063 |
| API-18-164 | `POST /migration-runs` | Tạo lần chạy `DRY_RUN` hoặc `REAL`, hoặc chạy lại bản ghi lỗi | 061, 062, 063 | migration | có | 202 | 036, 051, 057, 064, 065 |
| API-18-165 | `GET /migration-runs` | Danh sách lần chạy theo kế hoạch | 061, 062 | migration |  | 200 |  |
| API-18-166 | `GET /migration-runs/{runId}` | Tiến độ, số bản ghi theo đối tượng, trạng thái | 061, 062 | migration |  | 200 |  |
| API-18-167 | `POST /migration-runs/{runId}:approve` | Duyệt chạy thật (người thứ hai) | 062 | approve | có | 200 | 051, 064 |
| API-18-168 | `POST /migration-runs/{runId}:reject` | Từ chối chạy thật kèm lý do | 062 | approve | có | 200 |  |
| API-18-169 | `POST /migration-runs/{runId}:cancel` | Hủy lần chạy, dừng sau lô hiện hành | 061, 062 | migration | có | 200 |  |
| API-18-170 | `GET /migration-runs/{runId}/errors` | Danh sách bản ghi lỗi, lý do, xuất CSV | 063 | migration |  | 200 |  |
| API-18-171 | `GET /migration-runs/{runId}/reconciliation` | Báo cáo đối chiếu số lượng, tổng kiểm tra; tải PDF, CSV | 064 | migration |  | 200 |  |
| API-18-172 | `GET /credential-reissues` | Danh sách thông tin xác thực cần cấp lại theo HTTT, trạng thái | 065 | migration |  | 200 |  |
| API-18-173 | `GET /parallel-groups` | Nhóm dịch vụ chạy song song, trạng thái cầu nối, tỷ lệ khớp | 066, 067 | migration |  | 200 |  |
| API-18-174 | `GET /parallel-groups/{groupCode}` | Chi tiết nhóm, mẫu so sánh lệch, danh sách kiểm tra cắt chuyển, sổ cắt chuyển | 066, 067, 068 | migration |  | 200 |  |
| API-18-175 | `POST /parallel-groups/{groupCode}:transition` | Cắt chuyển theo `action`: `REQUEST` đề nghị cắt chuyển một phần hoặc toàn phần, `APPROVE`, `REJECT` (bốn mắt, `PERM-18-approve`), `ROLLBACK` quay lui (`PERM-18-migration`) | 068 | migration / approve | có | 200 | 051, 066, 067, 068 |
| API-18-176 | `POST /ops/internal/v1/shadow-samples` | Bộ so sánh nhận cặp phản hồi cũ và mới đã băm | 067 | scope ops:shadow-ingest | tùy chọn | 202 |  |
| API-18-182 | `PATCH /migration-runs/{runId}/errors` | Đánh dấu cách xử lý một hoặc nhiều bản ghi lỗi (`FIXED_AT_SOURCE`, `RULE_ADDED`, `WONT_MIGRATE` kèm lý do) | 063 | migration |  | 200 | 036 |
| API-18-183 | `POST /credential-reissues/{markerId}:waive` | Đánh dấu thông tin xác thực không cần cấp lại (`WAIVED`) kèm lý do | 065 | migration | có | 200 |  |
| API-18-184 | `PUT /parallel-groups/{groupCode}/normalization-rules` | Thay bộ quy tắc chuẩn hóa so sánh của nhóm; mẫu trong cửa sổ được tính lại | 067 | migration |  | 200 |  |
| API-18-185 | `POST /parallel-groups/{groupCode}/checklist/{itemCode}:confirm` | Xác nhận một mục kiểm tay của danh sách cắt chuyển kèm bằng chứng | 068 | migration | có | 200 | 067 |

: Danh mục API nhóm Di trú và chạy song song

### 4.10. Quản trị và báo cáo

Nhật ký thao tác vận hành, báo cáo định kỳ, sức khỏe phân hệ và chế độ suy giảm (FR-18-069…072). Nhóm có 6 operation (API-18-177…180, 186, 187).

| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |
|---|---|---|---|---|---|---|---|
| API-18-177 | `GET /audit-log` | Nhật ký thao tác vận hành của PH-18 (chỉ đọc, từ PH-13) | 070 | read |  | 200 |  |
| API-18-178 | `GET /reports` | Danh sách báo cáo vận hành định kỳ | 071 | read |  | 200 |  |
| API-18-179 | `POST /reports:generate` | Dựng báo cáo vận hành cho kỳ chọn | 071 | admin | có | 202 | 072 |
| API-18-180 | `GET /health` | Sức khỏe các mô-đun PH-18, chế độ suy giảm, độ trễ tiêu thụ | 072 | read |  | 200 |  |
| API-18-186 | `GET /inbox-failures` | Danh sách sự kiện inbox `FAILED` theo mô-đun, lỗi cuối, số lần thử | 072 | read |  | 200 |  |
| API-18-187 | `POST /degraded-mode` | Bật, tắt chế độ chỉ đọc kèm lý do; là API ghi duy nhất không bị chặn bởi chế độ chỉ đọc | 072 | admin | có | 200 |  |

: Danh mục API nhóm Quản trị và báo cáo
<!-- gen:catalog:end -->

## 5. Sự kiện

Chương này liệt kê sự kiện PH-18 phát, quy tắc chung của sự kiện và các kênh PH-18 tiêu thụ. Mọi sự kiện dùng phong bì CloudEvents 1.0, phát qua outbox và Debezium (ADR-042).

### 5.1. Sự kiện PH-18 phát

Bảng sinh dưới đây liệt kê 29 sự kiện theo FRS §9.3, kèm khóa phân vùng, trường dữ liệu và bên nhận.

<!-- gen:events:start -->
| Mã | Topic | Khóa | Trường dữ liệu | Bên nhận |
|---|---|---|---|---|
| EVT-18-01 | `{tenant}.ops.param.changed.v1` | `ns` | `ns`, `key`, `version`, `scope`, `changeType`, `changedBy`, `secure` | Mọi DU dùng `dh-ops-client` (làm mới đệm), PH-13 |
| EVT-18-02 | `{tenant}.ops.param.approval-requested.v1` | `requestId` | `requestId`, `key`, `requestedBy`, `approvalOwner` | PH-18 (Việc của tôi), PH-13 |
| EVT-18-03 | `{tenant}.ops.feature-flag.changed.v1` | `flagKey` | `flagKey`, `enabled`, `owner`, `retireBy` | Mọi DU, `dh-console` |
| EVT-18-04 | `{tenant}.ops.egress.changed.v1` | `tenantId` | `entryId`, `host`, `port`, `purpose`, `action`, `expiresAt` | PH-13 (cập nhật egress), `dh-platform`, `dh-runtime` |
| EVT-18-05 | `{tenant}.ops.dlq.received.v1` | `sourceCode` | `sourceCode`, `count`, `poisonCount`, `windowStart` | PH-13 (bảng điều khiển), `dh-console` |
| EVT-18-06 | `{tenant}.ops.dlq.poison-detected.v1` | `sourceCode` | `dlqId`, `sourceCode`, `missingFields`, `errorCode` | PH-13, chủ nguồn |
| EVT-18-07 | `{tenant}.ops.dlq.state-changed.v1` | `dlqId` | `dlqId`, `from`, `to`, `reasonCode`, `actor` | PH-13, PH-17 (đọc ngữ cảnh) |
| EVT-18-08 | `{tenant}.ops.dlq.threshold-crossed.v1` | `sourceCode` | `sourceCode`, `type`, `value`, `threshold` | PH-13 (luật cảnh báo, lịch trực) |
| EVT-18-09 | `{tenant}.ops.replay.requested.v1` | `sourceCode` | `dlqId`, `revision`, `idempotencyKey`, `jobId`, `payloadRef`, `sourceCode`, `flow` | Nguồn có cổng `KAFKA_TOPIC` (PH-04, PH-05, PH-06, PH-07, PH-08) |
| EVT-18-10 | `{tenant}.ops.replay-job.state-changed.v1` | `jobId` | `jobId`, `from`, `to`, `total`, `succeeded`, `failed` | PH-13, `dh-console` |
| EVT-18-11 | `{tenant}.ops.error-guide.changed.v1` | `errorCode` | `errorCode`, `version`, `owner` | PH-17 (lập chỉ mục tri thức) |
| EVT-18-12 | `{tenant}.ops.notification.bounced.v1` | `recipientRef` | `recipientRef`, `bounceType`, `suppressed`, `channel` | PH-12 (đánh dấu liên hệ), PH-01 (đầu mối HTTT), PH-13 |
| EVT-18-13 | `{tenant}.ops.notification.failed.v1` | `notificationId` | `notificationId`, `templateCode`, `channel`, `errorCode`, `callerPh` | Phân hệ gọi, PH-13 |
| EVT-18-14 | `{tenant}.ops.task.state-changed.v1` | `taskId` | `taskId`, `type`, `sourceRef`, `from`, `to`, `assignee` | `dh-console` (đếm việc), PH-16 |
| EVT-18-15 | `{tenant}.ops.calendar.changed.v1` | `year` | `year`, `calendarScope`, `version` | PH-01, PH-02, PH-09, PH-12, PH-16 (tính hạn) |
| EVT-18-16 | `{tenant}.ops.maintenance-window.changed.v1` | `windowId` | `windowId`, `kind`, `envs`, `start`, `end`, `state` | PH-02, PH-04, PH-10, PH-15, PH-20, `dh-console` |
| EVT-18-17 | `{tenant}.ops.incident.opened.v1` | `incidentId` | `incidentId`, `severity`, `sourceRef`, `hasPersonalData` | PH-13 (lịch trực), PH-09 (khi `hasPersonalData`) |
| EVT-18-18 | `{tenant}.ops.incident.state-changed.v1` | `incidentId` | `incidentId`, `from`, `to`, `severity` | PH-13, PH-16 |
| EVT-18-19 | `{tenant}.ops.backup.failed.v1` | `objectRef` | `objectRef`, `tool`, `lastSuccessAt`, `reason` | PH-13 (cảnh báo) |
| EVT-18-20 | `{tenant}.ops.restore-verification.completed.v1` | `objectRef` | `objectRef`, `result`, `rowCountDiff`, `durationSec` | PH-13, PH-16 |
| EVT-18-21 | `{tenant}.ops.tenant-restore.state-changed.v1` | `restoreId` | `restoreId`, `step`, `from`, `to`, `pointInTime` | PH-13, PH-20 |
| EVT-18-22 | `{tenant}.ops.tenant.restored.v1` | `tenantId` | `restoreId`, `pointInTime`, `scope`, `modules`, `completedAt` | Mọi DU (xóa bộ đệm, đồng bộ lại), PH-10, PH-20 |
| EVT-18-23 | `{tenant}.ops.tenant-export.completed.v1` | `exportId` | `exportId`, `result`, `sizeBytes`, `manifestSha256` | PH-20 (sáp nhập, ngừng tenant), PH-13 |
| EVT-18-24 | `{tenant}.ops.merge-transfer.state-changed.v1` | `mergePlanId` | `mergePlanId`, `module`, `from`, `to`, `rows`, `dryRun` | PH-20, PH-13 |
| EVT-18-25 | `{tenant}.ops.migration.run-completed.v1` | `runId` | `runId`, `planCode`, `mode`, `result`, `read`, `written`, `rejected` | PH-13, PH-16, phân hệ đích |
| EVT-18-26 | `{tenant}.ops.migration.credential-reissue-required.v1` | `systemCode` | `systemCode`, `credentialType`, `count`, `runId` | PH-01, PH-03 (tạo việc cấp lại) |
| EVT-18-27 | `{tenant}.ops.cutover.state-changed.v1` | `groupCode` | `groupCode`, `from`, `to`, `routes`, `rollbackUntil`, `trafficPercent` | PH-03 (APISIX), PH-10, PH-13 |
| EVT-18-28 | `{tenant}.ops.report.published.v1` | `period` | `period`, `reportId`, `metrics` | PH-16 (nguồn chỉ tiêu vận hành) |
| EVT-18-29 | `{tenant}.ops.health.changed.v1` | `component` | `component`, `from`, `to`, `readOnly` | PH-13, `dh-console` (dải cảnh báo) |

: Sự kiện PH-18 phát (AsyncAPI `send`)
<!-- gen:events:end -->

### 5.2. Quy tắc chung của sự kiện

Phát ít nhất một lần; bên tiêu thụ khử trùng theo `id` của phong bì (bảng `inbox_event`) và xử lý lũy đẳng. Sắp thứ tự theo khóa phân vùng trong một phân vùng; không đảm bảo thứ tự giữa các khóa. Phong bì có `specversion` `1.0`, `source` `/dh-platform/ops`, `type` bằng tên topic bỏ tiền tố tenant, `tenantid`, `time`, `traceparent`. Dữ liệu chỉ mang mã, trạng thái, số đếm và tham chiếu; không mang payload DLQ, giá trị tham số bảo mật, nội dung thông báo hay địa chỉ người nhận. Riêng EVT-18-08 có trường `value` là số đo ngưỡng, không phải giá trị tham số. Bên tiêu thụ lỗi xử lý theo DLQ của chính PH-18.

### 5.3. Kênh PH-18 tiêu thụ

PH-18 tiêu thụ topic DLQ chung (không mang mã EVT, FRS §9.3) và sự kiện của PH-10, PH-13, PH-20. Hợp đồng chi tiết của các sự kiện ngoài do tài liệu API của phân hệ phát giữ; AsyncAPI của PH-18 chỉ khai báo kênh và các trường PH-18 đọc.

<!-- gen:consume:start -->
| Topic | Bên phát | PH-18 dùng để |
|---|---|---|
| `{tenant}.ops.dlq.v1` | Mọi nguồn (PH-04 runtime và nguồn khác) | Topic DLQ hạ tầng: nguồn ghi bản tin lỗi kèm header ngữ cảnh, PH-18 là bên tiêu thụ duy nhất (FR-18-013) |
| `{tenant}.event.delivery.dead-lettered.v1` | PH-10 | EVT-10-11: có mục DLQ tầng sự kiện mới (gộp 1 phút); PH-18 hiển thị chung (FR-18-017) |
| `{tenant}.event.replay.completed.v1` | PH-10 | EVT-10-12: lượt phát lại của PH-10 kết thúc; cập nhật kết quả đề nghị (FR-18-030) |
| `{tenant}.event.migration.cut-over.v1` | PH-10 | EVT-10-15: ánh xạ di trú chuyển hẳn hoặc quay lui (FR-18-066) |
| `{tenant}.event.bridge.state-changed.v1` | PH-10 | EVT-10-16: cầu nối di trú đổi trạng thái (FR-18-066) |
| `{tenant}.obs.security-alert.raised.v1` | PH-13 | EVT-13-04: cảnh báo an ninh, mở sự cố (FR-18-047) |
| `{tenant}.obs.audit.chain-broken.v1` | PH-13 | EVT-13-05: đứt chuỗi kiểm toán, mở sự cố (FR-18-047) |
| `platform.tenant.created.v1` | PH-20 | PH-20: tenant được tạo; ghi tham số mặc định, lịch mặc định, mẫu thông báo mặc định (FR-18-011, 045) |
| `platform.tenant.status-changed.v1` | PH-20 | PH-20: tenant đổi trạng thái; dừng tác vụ nền khi `SUSPENDED`, điều kiện khôi phục (FR-18-036, 055, 072) |
| `platform.tenant.merge-started.v1` | PH-20 | PH-20: bắt đầu sáp nhập; khóa tác vụ nặng khác của hai tenant (FR-18-057) |
| `platform.tenant.export-ready.v1` | PH-20 | PH-20: gói xuất sẵn sàng khi ngừng tenant; đối chiếu với gói của PH-18 (FR-18-056) |
| `platform.release.published.v1` | PH-20 | PH-20: phát hành mới; thông báo và tạo cửa sổ bảo trì (FR-18-036, 046) |
| `platform.tenant.upgrade-changed.v1` | PH-20 | PH-20: lịch nâng cấp tenant đổi; cập nhật cửa sổ bảo trì (FR-18-046) |

: Kênh PH-18 tiêu thụ (AsyncAPI `receive`)
<!-- gen:consume:end -->

## 6. Hợp đồng với phân hệ khác và bên ngoài

Chương này nêu hợp đồng hai chiều giữa PH-18 và các phân hệ khác; bảng tổng hợp trước, các hợp đồng có nhiều ràng buộc được nêu chi tiết ở mục con.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| PH-04 runtime và nguồn khác | Vào | Topic `{tenant}.ops.dlq.v1` kèm header ngữ cảnh (mục 6.1); API-18-034…036; nhận phát lại qua EVT-18-09 hoặc cổng HTTP; báo kết quả API-18-076 | FR-18-012…016, 029, 030 |
| PH-10 | Ra, vào | Gọi API-10-060…065 cho DLQ tầng sự kiện (mục 6.2); tiêu thụ EVT-10-11, 12, 15, 16 | FR-18-017, 066 |
| PH-13 | Ra, vào | Gọi API-13-069 (mục 6.3); ghi kiểm toán mọi thao tác; tiêu thụ EVT-13-04, 05; PH-13 gọi API-18-060, 132 | FR-18-025, 047 |
| PH-20 | Ra, vào | API-18-030, 150, 153; tiêu thụ sự kiện vòng đời tenant (mục 6.4) | FR-18-011, 057 |
| Mọi phân hệ | Vào | ParameterApi, NotificationApi, TaskInboxApi, WorkingCalendarApi (mục 6.5) | Nhóm A, E, F, G |
| PH-17 | Vào | Đọc siêu dữ liệu DLQ và sổ tay ERR (API-18-060…062, scope `ops:dlq-read`), nhận EVT-18-07, 11 | FR-18-026 |
| PH-09 | Ra, vào | Tra mức phân loại trường khi sửa payload; nhận sự cố có DLCN (API-18-130); mở sự cố qua API-18-132 | FR-18-022, 050 |
| PH-12, PH-01 | Ra | Phân giải người, vai trò (PH-12) và đầu mối HTTT (PH-01, scope `onboarding:internal-read`) cho thông báo | FR-18-037 |
| PH-03 | Ra | EVT-18-04 (egress), EVT-18-27 (đổi tuyến khi cắt chuyển) | FR-18-010, 068 |
| Máy chủ thư, SMS gateway (IF-09) | Ra, vào | Spring Mail, SMS gateway; báo trả lại qua API-18-106 (scope `ops:notify`); thông tin kết nối ở `kv/dh/{tenant}/ops/mail` | FR-18-040 |
| OpenBao, Garage, CNPG, Velero | Ra | Tham chiếu bí mật, payload lớn ở bucket `dh-{tenant}-ops`, trạng thái sao lưu | FR-18-016, 052 |

: Hợp đồng với phân hệ khác và bên ngoài

### 6.1. PH-04 và nguồn DLQ

Mọi nguồn ghi DLQ bằng topic hoặc API phải gửi đủ ngữ cảnh theo FRS bảng 4.1b; thiếu header bắt buộc thì mục thành `POISON` và PH-18 phát EVT-18-06. Topic có 6 phân vùng, giữ 7 ngày, khóa bản ghi `dh-source-ph:dh-flow`.

| Header (topic) | Trường (API-18-035) | Bắt buộc | Ý nghĩa |
|---|---|---|---|
| `dh-tenant` | `tenant` | Có | Mã tenant, phải khớp tiền tố topic (lệch: ERR-18-103) |
| `dh-source-ph` | `sourcePh` | Có | Phân hệ nguồn, ví dụ `PH-04` |
| `dh-dlq-reason` | `reason` | Có | Lý do ngắn, ví dụ `TARGET_UNAVAILABLE` |
| `dh-dlq-error-code` | `errorCode` | Có | Mã ERR của nguồn, ví dụ `ERR-04-101` |
| `dh-dlq-stage` | `stage` | Có | Bước lỗi trong luồng |
| `dh-dlq-attempts` | `attempts` | Có | Số lần nguồn đã thử |
| `dh-flow` | `flow` | Có với nguồn `KAFKA_TOPIC` | Mã luồng để phát lại đúng lối vào |
| `dh-version` | `version` | Có với nguồn `KAFKA_TOPIC` | Phiên bản luồng lúc lỗi |
| `traceparent` | `traceId` | Nên có | Lấy chẩn đoán PH-13 |
| `dh-message-id` | `messageId` | Nên có | Khử trùng; thiếu thì dùng băm SHA-256 của payload |

: Header ngữ cảnh DLQ mà nguồn phải gửi

D03-04-PH04 hiện ghi mã lỗi ở header `dh-error-code` (BR-04-008), lệch với `dh-dlq-error-code` của FRS. Tập này theo FRS; đề nghị đồng bộ ở mục 11.2.

### 6.2. PH-10 và DLQ tầng sự kiện

DLQ tầng sự kiện do PH-10 giữ; PH-18 hiển thị chung trên màn DLQ nhưng không sao chép dữ liệu. PH-18 gọi PH-10 bằng token dịch vụ, scope `event:dlq-read` và `event:replay`.

| API PH-18 | Gọi sang PH-10 | Ghi chú |
|---|---|---|
| API-18-039 (danh sách) | API-10-060 `GET /dlq-entries`, API-10-061 `GET /dlq-entries/{dlqEntryId}` | Chỉ siêu dữ liệu; PH-10 không sẵn sàng thì trả phần của PH-18 kèm cờ thiếu nguồn |
| API-18-040 (đề nghị phát lại) | API-10-064 `POST /replays` với `dlqEntryIds[]` | Bốn mắt theo `PERM-10-approve` ở PH-10; theo dõi bằng API-10-063 và EVT-10-12 |
| Không có | API-10-062 `POST /dlq-entries:discard`, API-10-065 hủy lượt | Thao tác ở màn của PH-10; PH-18 dẫn liên kết |

: Hợp đồng PH-18 với API DLQ của PH-10

### 6.3. PH-13 và chẩn đoán

API-18-046 gọi API-13-069 `GET /diagnostics/{traceId}` với cửa sổ 5 phút quanh thời điểm lỗi, scope `obs:diagnostics-read`, timeout `18.dlq.diagnostics.timeout-ms` (mặc định 3.000 ms). PH-13 trả trace, tối đa 200 dòng log đã che và chỉ số; quá thời gian hoặc thiếu phần nào thì API-18-046 trả `206` kèm danh sách phần thiếu thay vì lỗi. PH-18 ghi kiểm toán mọi thao tác vận hành vào PH-13 trước hiệu lực; PH-13 không ghi được thì từ chối thao tác (ERR-18-008).

### 6.4. PH-20 và vòng đời tenant

PH-18 tiêu thụ sáu sự kiện của PH-20 và cung cấp ba operation cho PH-20; bảng dưới đây ghi phản ứng của PH-18.

| Sự kiện hoặc API | PH-18 làm gì |
|---|---|
| `platform.tenant.created.v1` | Ghi mặc định tham số cho tenant mới (tương đương API-18-030), tạo lịch năm từ lịch `COMMON` |
| `platform.tenant.status-changed.v1` | Tenant ngừng thì dừng gửi thông báo, giữ DLQ ở chế độ chỉ đọc |
| `platform.tenant.merge-started.v1` | Chuẩn bị chuyển sáp nhập; chờ PH-20 gọi API-18-150 cho từng phân hệ |
| `platform.tenant.export-ready.v1` | Cập nhật lệnh xuất tenant liên quan (API-18-148) |
| `platform.release.published.v1`, `platform.tenant.upgrade-changed.v1` | Đối chiếu cửa sổ bảo trì và trạng thái đóng băng (API-18-122) |
| API-18-030 `POST /ops/internal/v1/tenants/{tenant}/params:seed-defaults` | PH-20 ghi mặc định khi khởi tạo tenant, chỉ khóa chưa có giá trị |
| API-18-150, 153 `merge-transfers` | PH-20 yêu cầu và hủy chuyển dữ liệu sáp nhập; tiến độ báo qua EVT-18-24, quản trị nền tảng xem bằng API-18-151, 152 |
| `POST /internal/tenant/v1/merge-plans/{id}/participants/{module}:report` của PH-20 | PH-18 gọi để báo tiến độ, số bản ghi và kết quả của từng phân hệ trong kế hoạch sáp nhập |

: Hợp đồng PH-18 với PH-20

### 6.5. Bốn API dùng chung cho mọi phân hệ

Bốn API dưới đây là lý do mọi phân hệ phụ thuộc PH-18; thư viện `dh-ops-client` bọc chúng kèm bộ đệm, thử lại và ngắt mạch.

| API dùng chung | Operation | Hợp đồng chính |
|---|---|---|
| ParameterApi | API-18-027…029 | Phân hệ chủ đăng ký lược đồ không gian tên của mình (`PUT`, lũy đẳng, `If-Match` khi cập nhật); DU đọc lô theo khóa, cờ, egress với `If-None-Match`, nhận `304` khi chưa đổi; làm mới theo EVT-18-01, 03, 04 |
| NotificationApi | API-18-091…094 | Gửi theo `templateCode`, `recipientRef`, biến của mẫu, mức (`NORMAL`, `URGENT`); bất đồng bộ trả `202` kèm `messageId`; đồng bộ chỉ thư một người nhận; phân giải người nhận không trả địa chỉ thật |
| TaskInboxApi | API-18-107, 109, 110 | Đăng ký loại việc; tạo hoặc cập nhật việc lũy đẳng theo `sourceRef` và `sourceVersion` tăng dần; đóng việc `DONE` hoặc `CANCELLED`; `fourEyes` ẩn việc với người tạo đối tượng |
| WorkingCalendarApi | API-18-116, 117, 122 | Đếm ngày làm việc trong khoảng, cộng n ngày làm việc từ một mốc theo lịch của tenant; trạng thái đóng băng, bảo trì hiện hành |

: Bốn API dùng chung của PH-18

## 7. Bảng mã lỗi ERR-18

Bảng sinh dưới đây gồm mọi mã ERR-18 của FRS §9.1 cùng thông báo hiển thị. Mã ERR-18-001…072 trả qua HTTP; ERR-18-101…124 là lỗi của worker (tiêu thụ DLQ, phát lại, gửi thông báo, sao lưu, di trú), không trả qua HTTP mà ghi vào trạng thái đối tượng, nhật ký và chỉ số.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | Thông báo | Dùng ở API |
|---|---|---|---|---|
| ERR-18-001 | 404 | Không tìm thấy đối tượng | "Không tìm thấy {đối tượng} {mã}." | Mọi operation có tham số đường dẫn |
| ERR-18-002 | 409 | Mã đã tồn tại | "Mã {mã} đã được dùng. Chọn mã khác." | Theo FR liên quan |
| ERR-18-003 | 400 | Dữ liệu vào không hợp lệ | "Dữ liệu không hợp lệ: {chi tiết}." | Mọi thao tác có thân hoặc bộ lọc |
| ERR-18-004 | 412 | ETag lệch, dữ liệu đã đổi | "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu." | Mọi operation có `If-Match` |
| ERR-18-005 | 403 | Người duyệt trùng người đề nghị | "Bạn là người tạo {đối tượng} này nên không được duyệt." | Duyệt, từ chối bốn mắt |
| ERR-18-006 | 409 | Trạng thái không cho phép thao tác | "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}." | Mọi hành động chuyển trạng thái |
| ERR-18-007 | 422 | Thiếu lý do hoặc lý do quá ngắn | "Nhập lý do {thao tác} (ít nhất {n} ký tự)." | Thao tác nhận lý do bắt buộc |
| ERR-18-008 | 503 | Không ghi được kiểm toán PH-13 | "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau." | Mọi thao tác ghi |
| ERR-18-009 | 409 | Idempotency-Key dùng lại với thân khác | "Yêu cầu trùng khóa với một yêu cầu khác nội dung." | Mọi `POST` có `Idempotency-Key` |
| ERR-18-010 | 429 | Vượt giới hạn tần suất | "Quá nhiều yêu cầu. Thử lại sau {giây} giây." | Mọi operation |
| ERR-18-011 | 404 | Khóa tham số chưa đăng ký | "Khóa {khóa} chưa được đăng ký." | 003, 005…007, 013…015 |
| ERR-18-012 | 422 | Sai kiểu giá trị | "Giá trị của {khóa} phải có kiểu {kiểu}." | 006, 007 |
| ERR-18-013 | 422 | Giá trị ngoài miền | "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}." | 006, 007, 010, 017…019, 025 |
| ERR-18-014 | 422 | Giá trị vượt trần nền tảng | "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng." | 006, 007 |
| ERR-18-015 | 403 | Khóa mức PLATFORM | "Tham số {khóa} do quản trị nền tảng đặt, tỉnh chỉ xem được." | 006, 007 |
| ERR-18-016 | 409 | Lược đồ khóa xung đột | "Lược đồ mới của {ns} xung đột với giá trị đang dùng ở {số} tenant. Xem danh sách trong chi tiết." | 027 |
| ERR-18-017 | 403 | Đối tượng đăng ký không thuộc phân hệ gọi | "Phân hệ không sở hữu {đối tượng} {mã}." | 027, 034, 107 |
| ERR-18-018 | 409 | Đã có đề nghị chờ duyệt | "Tham số {khóa} đang có đề nghị chờ duyệt của {người}. Chờ duyệt xong hoặc rút đề nghị." | 006 |
| ERR-18-019 | 409 | Khóa do phân hệ khác giữ duyệt | "Tham số {khóa} được duyệt tại {phân hệ}. Mở màn {phân hệ} để đề nghị thay đổi." | 006, 010 |
| ERR-18-020 | 422 | Gói tham số không hợp lệ | "Gói tham số không hợp lệ hoặc đã bị sửa: {chi tiết}." | 017…019 |
| ERR-18-021 | 422 | Cờ thiếu chủ sở hữu hoặc ngày gỡ | "Cờ tính năng cần chủ sở hữu và ngày gỡ dự kiến trong vòng 365 ngày." | 021, 022 |
| ERR-18-022 | 422 | Đích egress không hợp lệ | "Đích {đích} không được phép: chỉ chấp nhận tên miền công khai qua HTTPS." | 025 |
| ERR-18-023 | 409 | Phiên bản cũ không hợp lệ với lược đồ hiện hành | "Phiên bản {số} không còn hợp lệ với lược đồ hiện hành của {khóa}: {lý do}." | 015 |
| ERR-18-024 | 422 | Thiếu ngữ cảnh bắt buộc khi ghi DLQ | "Thiếu trường ngữ cảnh bắt buộc: {trường}." | 035, 036 |
| ERR-18-025 | 413 | Payload vượt giới hạn | "Nội dung bản tin vượt {MB} MB. Lưu nội dung ở nguồn và gửi tham chiếu." | 035, 036 |
| ERR-18-026 | 403 | Nguồn chưa đăng ký hoặc tạm ngừng | "Nguồn {mã} chưa được đăng ký hoặc đang tạm ngừng ghi DLQ." | 035, 036 |
| ERR-18-027 | 409 | Payload đã xóa do hết hạn | "Nội dung bản tin đã bị xóa do hết hạn lưu giữ. Chỉ còn thông tin mô tả." | 047, 064 |
| ERR-18-028 | 409 | Mục POISON không phát lại được | "Bản tin thiếu ngữ cảnh nên không phát lại được. Sửa nội dung hoặc bỏ qua." | 064 |
| ERR-18-029 | 422 | Bản sửa sai lược đồ | "Nội dung sửa không đúng lược đồ {lược đồ}: {chi tiết}." | 053 |
| ERR-18-030 | 409 | Đã có bản sửa chờ duyệt | "Mục đã có bản sửa số {n} chờ duyệt. Chờ duyệt xong trước khi sửa tiếp." | 053 |
| ERR-18-031 | 409 | Mục đang trong lượt khác | "Mục đang được phát lại trong lượt {mã}." | 064 |
| ERR-18-032 | 422 | Vượt số mục tối đa một lượt | "Lượt có {n} mục, vượt giới hạn {tối đa}. Thu hẹp bộ lọc hoặc chia thành nhiều lượt." | 065, 069 |
| ERR-18-033 | 409 | Nguồn không có cổng phát lại | "Nguồn {mã} chưa có cổng phát lại hoặc đang tạm ngừng." | 064 |
| ERR-18-034 | 409 | Mục hết hạn, không mở lại được | "Mục đã hết hạn lưu giữ nên không thể mở lại." | 079 |
| ERR-18-035 | 503 | PH-10 không phản hồi | "Chưa lấy được dữ liệu từ phân hệ sự kiện. Thử lại sau." | 039, 040 |
| ERR-18-036 | 422 | Không có mục phù hợp | "Không có mục nào phù hợp để {thao tác}." | 065, 069, 164, 182 |
| ERR-18-037 | 422 | Tốc độ vượt trần | "Tốc độ {n} mục mỗi giây vượt giới hạn {trần} của nguồn {mã}." | 075 |
| ERR-18-038 | 403 | Callback không khớp nguồn | "Danh tính gọi không khớp nguồn của mục." | 076, 188 |
| ERR-18-039 | 422 | Mẫu chứa trường cấm | "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm." | 085…087, 091, 092 |
| ERR-18-040 | 422 | Cú pháp mẫu lỗi hoặc biến chưa khai báo | "Mẫu có lỗi tại dòng {dòng}: {chi tiết}." | 085…087 |
| ERR-18-041 | 409 | Không có mẫu ACTIVE | "Mẫu {mã} chưa có phiên bản đang dùng." | 091, 092, 100, 101 |
| ERR-18-042 | 422 | Không phân giải được người nhận | "Không xác định được người nhận {mã}." | 091, 092, 094 |
| ERR-18-043 | 409 | Người nhận bị chặn | "Người nhận đang trong danh sách chặn." | 103 |
| ERR-18-044 | 503 | Thư, SMS không sẵn sàng (gửi đồng bộ) | "Kênh gửi đang gián đoạn. Thử lại sau." | 092 |
| ERR-18-045 | 422 | Sự kiện chưa đăng ký tiêu thụ | "Sự kiện {sự kiện} chưa được phân hệ vận hành tiêu thụ nên không tạo được quy tắc." | 100, 101 |
| ERR-18-046 | 422 | Không tắt được nhóm bắt buộc | "Không tắt được nhóm thông báo {nhóm} vì là thông báo bắt buộc." | 096 |
| ERR-18-047 | 422 | Loại việc chưa đăng ký | "Loại việc {loại} chưa được đăng ký." | 109 |
| ERR-18-048 | 409 | Việc đã đóng | "Việc {mã} đã đóng." | 109, 110, 181 |
| ERR-18-049 | 422 | Lịch không hợp lệ | "Lịch năm {năm} không hợp lệ: {chi tiết}." | 114, 115 |
| ERR-18-050 | 409 | Cửa sổ chồng lấn | "Cửa sổ {loại} chồng với cửa sổ {mã} từ {bắt đầu} đến {kết thúc}." | 119, 120 |
| ERR-18-051 | 409 | Đang trong cửa sổ đóng băng | "Đang trong thời gian đóng băng thay đổi {cửa sổ} nên chưa chạy thật được." | 164, 167, 175 |
| ERR-18-052 | 422 | Đóng sự cố thiếu nguyên nhân, bài học | "Đóng sự cố cần nêu nguyên nhân gốc và bài học (mỗi phần ít nhất 30 ký tự)." | 131 |
| ERR-18-053 | 422 | Chuyển PH-09 thiếu thông tin | "Cần nêu loại dữ liệu cá nhân, số người ước tính và thời điểm phát hiện." | 130 |
| ERR-18-054 | 503 | PH-09 không nhận sự cố | "Chưa chuyển được sang phân hệ quyền riêng tư. Hệ thống sẽ thử lại mỗi 5 phút; báo ngay cán bộ ATTT nếu quá 1 giờ." | 130 |
| ERR-18-055 | 503 | Không thu được trạng thái sao lưu | "Chưa thu được trạng thái sao lưu từ {công cụ}." | 133, 134 |
| ERR-18-056 | 422 | Thời điểm ngoài cửa sổ PITR | "Thời điểm {thời điểm} nằm ngoài cửa sổ khôi phục 30 ngày." | 138, 141 |
| ERR-18-057 | 409 | Tenant đang có tác vụ nặng khác | "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục." | 138, 141, 147, 164 |
| ERR-18-058 | 422 | Phạm vi khôi phục không hợp lệ | "Phạm vi khôi phục không hợp lệ: {chi tiết}." | 138, 141 |
| ERR-18-059 | 409 | Trạng thái tenant không phù hợp | "Tỉnh đang ở trạng thái {trạng thái}, chưa xuất được với mục đích {mục đích}." | 147 |
| ERR-18-060 | 422 | Yêu cầu sáp nhập không hợp lệ | "Yêu cầu chuyển sáp nhập không hợp lệ: {lý do}." | 150 |
| ERR-18-061 | 409 | Trùng mergePlanId và module với nội dung khác | "Đã có yêu cầu chuyển dữ liệu {phân hệ} cho kế hoạch {mã} với nội dung khác." | 150 |
| ERR-18-062 | 422 | Nguồn di trú không kết nối được hoặc không chỉ đọc | "Nguồn {mã} không kết nối được hoặc tài khoản không phải chỉ đọc: {chi tiết}." | 157, 158 |
| ERR-18-063 | 422 | Phụ thuộc vòng trong kế hoạch | "Kế hoạch có phụ thuộc vòng hoặc thiếu đối tượng tiền đề: {danh sách}." | 162, 163 |
| ERR-18-064 | 409 | Cần chạy thử gần đây | "Cần một lần chạy thử thành công trong {ngày} ngày gần nhất trước khi chạy thật." | 164, 167 |
| ERR-18-065 | 409 | Kế hoạch chưa READY | "Kế hoạch {mã} chưa ở trạng thái sẵn sàng." | 164 |
| ERR-18-066 | 422 | Tỷ lệ khớp chưa đạt | "Tỷ lệ khớp {tỷ lệ} thấp hơn ngưỡng {ngưỡng}." | 175 |
| ERR-18-067 | 409 | Danh sách kiểm tra chưa đạt | "Chưa cắt chuyển được nhóm {nhóm}: còn {n} mục kiểm tra chưa đạt." | 175, 185 |
| ERR-18-068 | 409 | Quá cửa sổ quay lui | "Đã quá {phút} phút kể từ khi cắt chuyển nên không quay lui tự động được." | 175 |
| ERR-18-069 | 503 | Phân hệ đích không nhận lô | "Phân hệ {ph} không nhận dữ liệu. Lần chạy tạm dừng và tự thử lại sau {phút} phút." | Theo FR liên quan |
| ERR-18-070 | 422 | Thông tin kết nối không phải tham chiếu kho bí mật | "Thông tin kết nối phải là tham chiếu kho bí mật, không nhập mật khẩu trực tiếp." | 157 |
| ERR-18-071 | 503 | Chế độ chỉ đọc | "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được." | Mọi thao tác ghi nhóm tham số |
| ERR-18-072 | 422 | Kỳ báo cáo không hợp lệ | "Kỳ báo cáo {kỳ} không hợp lệ hoặc chưa kết thúc." | 179 |
| ERR-18-101 | Không (worker) | Không giải mã được bản tin | "Không đọc được nội dung bản tin; lưu dạng nhị phân." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-102 | Không (worker) | Thiếu header ngữ cảnh | "Thiếu thông tin ngữ cảnh: {trường}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-103 | Không (worker) | Tenant trong header lệch topic | "Tenant của bản tin không khớp topic." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-104 | Không (worker) | Garage lỗi hoặc tổng kiểm tra lệch | "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-105 | Không (worker) | Trùng dlqKey | "Bản tin trùng mục đang mở; đã tăng số lần gặp." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-106 | Không (worker) | PH-13 quá thời gian khi lấy chẩn đoán | "Chưa lấy được ngữ cảnh chẩn đoán." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-107 | Không (worker) | Cổng nguồn từ chối phát lại | "Nguồn từ chối phát lại: {lý do}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-108 | Không (worker) | Cổng nguồn quá thời gian | "Nguồn không phản hồi; mục sẽ được thử lại." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-109 | Không (worker) | Kết quả phát lại quá hạn | "Chưa nhận kết quả phát lại sau {n} phút." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-110 | Không (worker) | Máy chủ thư lỗi | "Gửi thư chưa thành công; đang thử lại." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-111 | Không (worker) | SMS gateway lỗi | "Gửi SMS chưa thành công; đang thử lại." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-112 | Không (worker) | Thư trả lại | "Thư bị trả lại ({loại})." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-113 | Không (worker) | Người nhận bị chặn | "Không gửi vì người nhận trong danh sách chặn." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-114 | Không (worker) | Bước khôi phục lỗi | "Bước {n} lỗi: {lý do}. Đang quay lui." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-115 | Không (worker) | Đối chiếu số dòng sau khôi phục lệch | "Số dòng sau khôi phục lệch ở {bảng}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-116 | Không (worker) | Xuất tenant lỗi | "Xuất dữ liệu chưa thành công: {lý do}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-117 | Không (worker) | Đọc nguồn di trú lỗi | "Đọc nguồn {mã} lỗi." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-118 | Không (worker) | Bộ chuyển đổi lỗi bản ghi | "Bản ghi {khóa} không chuyển đổi được: {lý do}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-119 | Không (worker) | Phân hệ đích từ chối bản ghi | "Phân hệ đích từ chối bản ghi {khóa}: {mã lỗi}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-120 | Không (worker) | Tổng kiểm tra di trú lệch | "Tổng kiểm tra của {đối tượng} lệch." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-121 | Không (worker) | Mẫu chạy bóng lệch | "Kết quả hệ mới khác hệ cũ ở {tuyến}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-122 | Không (worker) | Thu trạng thái sao lưu lỗi | "Chưa thu được trạng thái của {đối tượng}." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-123 | Không (worker) | Báo tiến độ về PH-20 lỗi | "Chưa báo được tiến độ sáp nhập; đang thử lại." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |
| ERR-18-124 | Không (worker) | Inbox hoặc outbox xử lý thất bại | "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." | Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}` |

: Bảng mã lỗi ERR-18 và thông báo hiển thị
<!-- gen:errors:end -->

### 7.1. Thân lỗi

Thân lỗi theo RFC 9457; ví dụ dưới đây là lượt phát lại vượt số mục tối đa.

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-18-032",
  "title": "Lượt có 12500 mục, vượt giới hạn 10000. Thu hẹp bộ lọc hoặc chia thành nhiều lượt.",
  "status": 422,
  "code": "ERR-18-032",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{"field": "filter", "message": "Vượt 18.dlq.replay.batch-max"}]
}
```

: Thân lỗi RFC 9457 của PH-18

`title` là thông báo hiển thị của FRS §9.1 đã thay tham số, `detail` (nếu có) là chi tiết kỹ thuật không chứa payload, giá trị tham số bảo mật, địa chỉ người nhận hay tham chiếu bí mật.

### 7.2. Quy tắc áp mã cấu trúc

Các mã cấu trúc dưới đây được gắn theo quy tắc, không liệt kê ở cột "Lỗi riêng" của chương 4.

| Mã | Gắn ở |
|---|---|
| ERR-18-001 | Mọi operation có tham số đường dẫn |
| ERR-18-003 | Mọi thao tác có thân hoặc bộ lọc |
| ERR-18-004 | Mọi operation có `If-Match` |
| ERR-18-005 | Hành động `:approve`, `:reject` của bốn mắt và API-18-175 |
| ERR-18-006 | Mọi hành động chuyển trạng thái |
| ERR-18-007 | Thao tác nhận lý do bắt buộc (bỏ qua, xem payload, từ chối, gỡ egress, gỡ chặn) |
| ERR-18-008 | Mọi thao tác ghi (không ghi được kiểm toán thì từ chối) |
| ERR-18-009 | Mọi `POST` có `Idempotency-Key` |
| ERR-18-010 | Mọi operation |
| ERR-18-071 | Mọi thao tác ghi nhóm tham số |

: Quy tắc áp mã lỗi cấu trúc

### 7.3. Nơi hiển thị thông báo

Thông báo ở cột "Thông báo" là câu `title` của thân lỗi. `dh-console` hiển thị nguyên câu cho người dùng; lỗi trường (`errors[]`) hiện dưới ô nhập tương ứng; ERR-18-004 kèm nút "Tải lại"; ERR-18-005 hiện ở hộp duyệt; ERR-18-008, 071 hiện ở dải cảnh báo đầu màn. Mã của worker hiện trên màn chi tiết đối tượng (mục DLQ, lượt phát lại, lần gửi, lần chạy di trú) và trong sổ tay ERR (API-18-058).

## 8. Kiểm tra hợp đồng trong CI

Chương này nêu các kiểm tra chạy trong CI cho hai tệp YAML và tài liệu, cùng kết quả lần chạy gần nhất.

| Kiểm tra | Công cụ | Điều kiện đạt |
|---|---|---|
| Cú pháp, khóa trùng, khóa rỗng | `build/tools/kiem_tra_yaml.py` | 0 lỗi |
| OpenAPI 3.1 và AsyncAPI 3.0 hợp lệ | Spectral 6 với `build/tools/spectral.yaml` | 0 lỗi |
| Hợp đồng PH-18 | [`ph18/tools/check_contracts.py`](ph18/tools/check_contracts.py) | `$ref` đủ đích; đủ 188 mã API, đúng phương thức và đường dẫn của FRS; mã lỗi có trong FRS, không gắn mã worker vào HTTP, có phản hồi ứng với mã HTTP; mọi `POST` khai báo chống trùng; ví dụ thân và tham số khớp lược đồ; đủ 29 kênh EVT đúng địa chỉ; sự kiện không có khóa nội dung hay bí mật |
| Mã trong tài liệu | `build/tools/kiem_tra_ma.py` | Không có lỗi mới |
| Rò rỉ bí mật | `gitleaks detect --no-git` trên `ph18/` và tệp này | 0 phát hiện |
| Thay đổi phá vỡ | `oasdiff breaking` với nhánh chính | Không có thay đổi phá vỡ trong `v1` |
| Cô lập tenant | `TenantIsolationIT` cho mọi API đọc (D05-02-PH18) | 0 truy vấn đọc được dữ liệu tenant khác |

: Kiểm tra hợp đồng của API PH-18

Chạy lại ngày 27/11/2026 cho bản 0.2: `check_contracts.py` sạch (188 operation, 284 ví dụ OpenAPI, 42 kênh, 322 lược đồ); `kiem_tra_yaml.py` 0 lỗi; gitleaks 0 phát hiện. Spectral chạy ở bản 0.1 (0 lỗi, còn cảnh báo kiểu tài liệu của AsyncAPI); môi trường của lượt đồng bộ 0.2 không có Spectral nên CI chạy lại bước này.

## 9. Ánh xạ từ hệ cũ

SRS cũ (`docs/07-srs/SRS-PH-18-ops.md`) chỉ có phần DLQ (tiếp nhận, phân loại, phát lại, bỏ qua, cảnh báo) với topic `lgsp.dlq.*` và không có danh sách API; mã FR cũ không còn hiệu lực. Bảng dưới đây ánh xạ nhóm chức năng cũ sang API mới.

| Nhóm cũ | API mới | Ghi chú |
|---|---|---|
| Tiếp nhận DLQ, topic `lgsp.dlq.*` | Topic `{tenant}.ops.dlq.v1`, API-18-031…038 | Một topic chung theo tenant, nguồn phân biệt bằng header (Q18-01 của FRS) |
| Phân loại, lọc, gán ưu tiên | API-18-041…051 | Thêm nhóm theo dấu hiệu lỗi, xuất CSV chỉ siêu dữ liệu |
| Liên kết sang trace giám sát | API-18-046 | Qua API-13-069, trả `206` khi thiếu phần |
| Phát lại đơn lẻ, hàng loạt, idempotent | API-18-064…076 | Thêm bản sửa payload có bốn mắt, lượt có ngưỡng duyệt và tốc độ |
| Bỏ qua, mở lại, ghi vết | API-18-063, 077…079 | Lý do ≥ 10 ký tự, kiểm toán PH-13 |
| Thống kê, cảnh báo ngưỡng | API-18-080, 081; EVT-18-06, 08 | Cảnh báo do PH-13 tạo từ sự kiện |
| Không có ở SRS cũ | API-18-001…030, 082…188 | Kho tham số, thông báo, việc, lịch, sự cố, sao lưu, di trú là năng lực mới |

: Ánh xạ nhóm chức năng SRS cũ sang API mới

Hệ Bus, Hub, APIM cũ không có API vận hành cần giữ tương thích; dữ liệu của chúng được chuyển bằng khung di trú (API-18-156…176).

## 10. Truy vết FR sang API

Bảng sinh dưới đây ánh xạ mỗi FR-18 sang các API-18 hiện thực nó; FR chỉ chạy nền (tiêu thụ, tác vụ lịch) không có API riêng.

<!-- gen:fr:start -->
| FR | API | FR | API |
|---|---|---|---|
| FR-18-001 | 001…003, 027 | FR-18-037 | 091, 092, 094 |
| FR-18-002 | 004, 005, 028, 029 | FR-18-038 | 091, 095…097 |
| FR-18-003 | 006, 007 | FR-18-039 | 099…101 |
| FR-18-004 | 006, 008…012 | FR-18-040 | 102…106 |
| FR-18-005 | 003, 013…016 | FR-18-041 | 093, 102, 103 |
| FR-18-006 | 016 | FR-18-042 | 107, 108 |
| FR-18-007 | 001, 002, 004, 005, 007 | FR-18-043 | 109, 110 |
| FR-18-008 | 017…019 | FR-18-044 | 111, 112, 181 |
| FR-18-009 | 020…023, 028 | FR-18-045 | 113…117 |
| FR-18-010 | 024…026, 028 | FR-18-046 | 118…122 |
| FR-18-011 | 030 | FR-18-047 | 123, 132 |
| FR-18-012 | 031…034 | FR-18-048 | 123…127 |
| FR-18-013 | Chạy nền, không có API riêng | FR-18-049 | 125, 128, 129 |
| FR-18-014 | 035, 036 | FR-18-050 | 130 |
| FR-18-015 | 035, 036 | FR-18-051 | 127, 131 |
| FR-18-016 | 035, 036 | FR-18-052 | 133…135 |
| FR-18-017 | 039, 040 | FR-18-053 | 136, 137 |
| FR-18-018 | 037, 038 | FR-18-054 | 138…141, 144 |
| FR-18-019 | 041, 042 | FR-18-055 | 139, 140, 142, 143, 145, 146 |
| FR-18-020 | 043, 044 | FR-18-056 | 147…149 |
| FR-18-021 | 045, 046, 058 | FR-18-057 | 150…153 |
| FR-18-022 | 047, 048 | FR-18-058 | 154, 155 |
| FR-18-023 | 041, 044, 049…051, 063 | FR-18-059 | 156…158 |
| FR-18-024 | 052…056 | FR-18-060 | 159…163 |
| FR-18-025 | 057…059, 062 | FR-18-061 | 164…166, 169 |
| FR-18-026 | 048, 060…062 | FR-18-062 | 164…169 |
| FR-18-027 | 064, 188 | FR-18-063 | 164, 170, 182 |
| FR-18-028 | 065…071, 188 | FR-18-064 | 171 |
| FR-18-029 | 066, 067, 072…075 | FR-18-065 | 172, 183 |
| FR-18-030 | 064, 067, 068, 076 | FR-18-066 | 173, 174 |
| FR-18-031 | 077, 078 | FR-18-067 | 173, 174, 176, 184 |
| FR-18-032 | 079 | FR-18-068 | 174, 175, 185 |
| FR-18-033 | 080 | FR-18-069 | 004, 006 |
| FR-18-034 | 081 | FR-18-070 | 016, 063, 177 |
| FR-18-035 | 082…090 | FR-18-071 | 081, 178, 179 |
| FR-18-036 | 091…093, 097, 098 | FR-18-072 | 180, 186, 187 |

: Truy vết FR-18-001…072 sang API-18
<!-- gen:fr:end -->

## 11. Đề nghị đồng bộ

Tập này không sửa FRS, CSDL hay tài liệu của phân hệ khác; các điểm dưới đây là đề nghị cho chủ tài liệu.

### 11.1. Với FRS và CSDL

Khi FRS và DDL lệch nhau, tập này theo FRS; bảng dưới đây liệt kê chỗ lệch giữa các tập của PH-18. Cả mười bốn mục là đồng bộ nội bộ và đã xử lý ở bản 0.2 (FRS 0.2, CSDL 0.2, tập này); cột cuối ghi cách hấp thụ.

| Số | Nội dung | Đề nghị |
|---|---|---|
| 1 | Tham số lọc ở FRS §6 dùng tên giao diện tiếng Việt (`nguon`, `luong`, `ma-loi`, `nhom`, `khoang`); OpenAPI dùng camelCase tiếng Anh (`sourceCode`, `flow`, `errorCode`, `group`, `interval`, `groupBy`) | FRS ghi tên tham số API theo OpenAPI, giữ tên tiếng Việt cho nhãn màn hình (Q18-55). Đã hấp thụ ở 0.2: giữ tên camelCase của OpenAPI cho tham số API, FRS giữ tên tiếng Việt cho tham số URL của màn hình (FRS §10.3); `dh-console` ánh xạ hai bộ tên |
| 2 | Lược đồ khóa: FRS dùng `type`, `default`, `secure`, `group`; DDL dùng `value_type`, `default_value`, `security_flag` | DDL đổi tên cột theo FRS, hoặc FRS chọn `valueType`, `defaultValue` (Q18-59). Đã hấp thụ ở 0.2: CSDL đổi `security_flag` thành `secure`, giữ `value_type`, `default_value`, `display_group` vì từ khóa SQL, ghi ánh xạ ở chú thích cột; enum kiểu theo `ParamType` |
| 3 | Cổng phát lại: FRS `KAFKA_TOPIC`, `HTTP_PORT`, `EVENT_LAYER`, `NONE`; DDL `replay_port` có `PH04_RUNTIME` | DDL theo enum FRS. Đã hấp thụ ở 0.2: CSDL cột `replay_mode` theo enum FRS |
| 4 | Cờ tính năng: FRS `retireBy`, `ownerPh`; DDL `removal_date`, `owner` | DDL theo FRS. Đã hấp thụ ở 0.2: CSDL `retire_by`, `owner_ph`, `owner_user` |
| 5 | Sổ tay ERR: FRS `causes`, `steps`, `replayable` (`YES`, `AFTER_FIX`, `NO`); DDL `symptom`, `cause`, `resolution`, `recommended_action` | DDL theo FRS. Đã hấp thụ ở 0.2: CSDL `causes`, `steps`, `replayable`, `default_class`, `links` |
| 6 | Lượt phát lại: FRS `ratePerSecond`; DDL `rate_per_minute` | DDL theo FRS. Đã hấp thụ ở 0.2: CSDL `rate_per_second` |
| 7 | Sự cố: FRS `hasPersonalData` và danh mục loại sự cố; DDL `involves_personal_data` và danh mục khác | DDL theo FRS. Đã hấp thụ ở 0.2: CSDL `has_personal_data`, `category` theo `IncidentCategory` |
| 8 | Bản ghi lỗi di trú: FRS `RULE_ADDED`, `WONT_MIGRATE`; DDL `FIXED_BY_RULE`, `ACCEPTED_SKIP` | DDL theo FRS. Đã hấp thụ ở 0.2: CSDL `RULE_ADDED`, `WONT_MIGRATE`; API-18-182 ghi trạng thái này |
| 9 | Loại thông tin xác thực, phương pháp kiểm tra khôi phục, loại diễn tập DR, mục đích egress và xuất tenant, môi trường (thêm `TEST`) lệch giữa FRS và DDL | DDL theo enum FRS (lược đồ `CredentialKind`, `DrillKind`, `ExportPurpose`, `Environment` ở OpenAPI). Đã hấp thụ ở 0.2: CSDL theo `CredentialKind`, `VerifyMethod`, `DrillKind`, `EgressPurpose`, `ExportPurpose`; cửa sổ bảo trì nhận `TEST` |
| 10 | `targetPh` dạng `PH-nn`; CHECK của DDL thiếu PH-04 và PH-07 | DDL bổ sung. Đã hấp thụ ở 0.2: CSDL dùng mã `PH-nn` ở mọi cột phân hệ, CHECK có PH-04, PH-07 |
| 11 | Từ chối chạy di trú thật (API-18-168) đưa lần chạy về `CANCELLED` vì sơ đồ trạng thái FRS không có `REJECTED` | FRS xác nhận hoặc thêm trạng thái (Q18-58). Đã hấp thụ ở 0.2: FRS §4.6 không có `REJECTED` cho lần chạy, giữ `CANCELLED` kèm lý do từ chối (Q18-58 đóng theo đề xuất tạm) |
| 12 | API-18-150, 153 thuộc API người dùng `/api/ops/v1` nhưng chỉ PH-20 gọi bằng scope `ops:merge-transfer` | Giữ đường dẫn theo FRS; cân nhắc chuyển sang `/ops/internal/v1` ở bản sau. Giữ ở 0.2: FRS ghi rõ PH-20 gọi qua APISIX bằng token dịch vụ; chuyển sang `/ops/internal/v1` để bản sau cùng PH-20 (mục 11.2) |
| 13 | ERR-18-010 (vượt tần suất) chỉ gắn ở vài API trong FRS; tập này gắn ở mọi operation vì APISIX áp hạn mức chung | FRS ghi ERR-18-010 là mã cấu trúc. Đã hấp thụ ở 0.2: tập này gắn ERR-18-010 ở mọi operation; FRS §9.1 coi 001…010 là mã cấu trúc |
| 14 | Ví dụ của API-18-003 và 027 bị bỏ vì Spectral hiểu đối tượng có `type` và `default` là lược đồ | Xem Q18-59. Giữ ở 0.2: vẫn bỏ ví dụ của API-18-003, 027 (Q18-59) |

: Đề nghị đồng bộ với FRS và CSDL

Bản 0.2 thêm tám operation theo đề nghị nội bộ của các tập khác của PH-18 (FRS 0.2 §12.5). Bảng dưới ghi nguồn đề nghị và mã đã cấp.

| Mã | Operation | Nguồn đề nghị |
|---|---|---|
| API-18-181 | `POST /me/tasks/{taskId}:claim` | UC ĐN-UC-03, MH B5 |
| API-18-182 | `PATCH /migration-runs/{runId}/errors` | UC ĐN-UC-04, MH B1 |
| API-18-183 | `POST /credential-reissues/{markerId}:waive` | UC ĐN-UC-05, MH B2 |
| API-18-184 | `PUT /parallel-groups/{groupCode}/normalization-rules` | UC ĐN-UC-06, MH B3 |
| API-18-185 | `POST /parallel-groups/{groupCode}/checklist/{itemCode}:confirm` | MH B4 |
| API-18-186 | `GET /inbox-failures` | MH B6 |
| API-18-187 | `POST /degraded-mode` | UC ĐN-UC-11, MH B7 |
| API-18-188 | `GET /ops/internal/v1/replay-payloads/{dlqId}/{revision}` | SDD §13.5 điểm 8 |

: Operation thêm ở bản 0.2

Cùng đợt, API-18-041, 043, 045 nhận `PERM-18-read` (MH LC-05), API-18-175 nhận thân `action` với quyền theo từng giá trị (UC ĐN-UC-08), ERR-18-071 gắn mọi API ghi của người dùng trừ API-18-187 (UC ĐN-UC-02), `ReplayItemStatus` thêm `SKIPPED` (TC ĐN-TC-08) và API-18-035 ghi rõ đường API từ chối ERR-18-024 thay vì tạo mục `POISON` (BR-18-013).

### 11.2. Với tài liệu chung và phân hệ khác

Người điều phối chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để D00-04 có API-18-001…188, EVT-18-01…29 và Q18-55…59 của tập này. Các đề nghị còn lại như sau.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 | Xác nhận 14 scope `ops:*`, trong đó `ops:backup-report`, `ops:merge-transfer`, `ops:shadow-ingest` là mới; ghi các cặp loại trừ của mục 2.3 vào §4 |
| D03-06-00 | Ghi nhóm route `/van-hanh/*` của `dh-console` ứng với các nhóm API ở chương 4 |
| CC-CAMEL-05 | Chốt topic DLQ chung `{tenant}.ops.dlq.v1` thay cho tên riêng theo luồng (Q18-01 của FRS) |
| D03-04-PH04 | Đổi header `dh-error-code` thành `dh-dlq-error-code` và bổ sung `dh-dlq-reason`, `dh-dlq-stage`, `dh-dlq-attempts` theo mục 6.1 |
| D03-04-PH10 | Xác nhận PH-18 gọi API-10-060, 061, 064 bằng scope `event:dlq-read`, `event:replay` và nhận EVT-10-11, 12, 15, 16 |
| D03-04-PH20 | Ghi PH-20 gọi API-18-030, 150, 153 và nhận EVT-18-21…24; xác nhận tên sáu topic `platform.*` mà PH-18 tiêu thụ |

: Đề nghị đồng bộ với tài liệu chung và phân hệ khác

## 12. Câu hỏi mở

Các câu hỏi dưới đây cần chủ tài liệu hoặc kiến trúc trả lời; đề xuất tạm là phương án tập này đang áp dụng.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q18-55 | Tham số truy vấn theo tên camelCase tiếng Anh hay theo tên giao diện của FRS §6 | Giữ camelCase tiếng Anh như các phân hệ khác; `dh-console` ánh xạ sang nhãn tiếng Việt |
| Q18-56 | Hạn mức gọi của `/api/ops/v1` và API nội bộ chưa có khóa `18.*` | Giữ giả định ở mục 1.3 tại APISIX; thêm khóa `18.api.rate-user-per-min` và `18.api.rate-du-per-min` nếu FRS cần |
| Q18-57 | `Location` của phản hồi `201`, `202` ở API nội bộ trỏ tới đường dẫn nào khi đối tượng chỉ đọc được ở API người dùng | API nội bộ trả `Location` tới đường dẫn nội bộ nếu có (API-18-093), không thì chỉ trả đối tượng |
| Q18-58 | Từ chối chạy di trú thật nên là trạng thái `REJECTED` riêng hay `CANCELLED` kèm lý do | Đã chốt ở FRS 0.2 §4.5: `CANCELLED` kèm `rejectReason` |
| Q18-59 | Lược đồ khóa tham số có trường `type` và `default` khiến Spectral hiểu nhầm ví dụ là lược đồ | Giữ tên theo FRS, bỏ ví dụ ở API-18-003, 027; nếu đổi tên thì dùng `valueType`, `defaultValue` khớp DDL |

: Câu hỏi mở của tập API PH-18

## 13. Ghi chú về ví dụ

Ví dụ yêu cầu và phản hồi ở chương 14 sinh từ lược đồ OpenAPI bằng [`examples18.py`](ph18/tools/examples18.py) theo tên trường, rồi được `check_contracts.py` kiểm khớp lược đồ. Dữ liệu ví dụ dùng tenant `T68`; tenant kiểm thử dùng `T90`…`T99`. Mã định danh là UUID sinh ổn định từ tên, băm SHA-256 là chuỗi mẫu có entropy thấp, khóa chống trùng có dạng `dh-2026-11-27-0001`, mọi bí mật chỉ xuất hiện dưới dạng tham chiếu OpenBao `kv/dh/T68/...`.

Hai operation không có ví dụ vì giới hạn của Spectral (Q18-59). Ví dụ lược đồ khóa của API-18-003 được ghi tay dưới đây.

```json
{
  "key": "18.dlq.replay.approval-threshold",
  "ns": "18.",
  "type": "INT",
  "default": 500,
  "domain": {"min": 1, "max": 10000},
  "level": "TENANT",
  "secure": false,
  "approvalOwner": "PH-18",
  "group": "Phát lại",
  "label": "Ngưỡng duyệt bốn mắt của lượt phát lại",
  "schemaVersion": 1,
  "id": "5f0c2a9e-3b1d-4c6e-9a2f-7d8e1b4c6a01",
  "version": 3
}
```

: Ví dụ lược đồ khóa tham số của API-18-003

## 14. Đặc tả từng endpoint

Mỗi operation có một khối đặc tả sinh bằng `build/tools/sinh_dac_ta_api.py --vi-du` từ OpenAPI, theo khung K-TRINH-BAY; nội dung không sửa tay.

<!-- gen:dac-ta:start -->
### 14.1. Tham số và cờ tính năng

Không gian tên và lược đồ khóa, giá trị theo tenant có kiểm miền và trần, đề nghị bốn mắt cho khóa ★, phiên bản, gói tham số, cờ tính năng, egress, API nội bộ `ParameterApi` (FR-18-001…011). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-001 · Danh sách không gian tên tham số đã đăng ký, PH chủ sở hữu, số khóa, nhóm hiển thị

::: dac-ta
**Mục đích.** Danh sách không gian tên tham số đã đăng ký, PH chủ sở hữu, số khóa, nhóm hiển thị.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-namespaces`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-001, FR-18-007.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamNamespacePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách không gian tên tham số đã đăng ký, PH chủ sở hữu, số khóa, nhóm hiển thị. Quyền PERM-18-read; FR-18-001, 007.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-namespaces
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "ns": "18.",
   "ownerPh": "PH-04", "title": "Vận hành và xử lý lỗi", "schemaVersion": 7,
   "status": "ACTIVE", "keyCount": 61}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-002 · Lược đồ khóa theo `ns`, `nhom`, cờ ★, mức `PLATFORM`/`TENANT`; dùng dựng màn tham số chung

::: dac-ta
**Mục đích.** Lược đồ khóa theo `ns`, `nhom`, cờ ★, mức `PLATFORM`/`TENANT`; dùng dựng màn tham số chung.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-definitions`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-001, FR-18-007.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ns` (query, string, tùy chọn); `group` (query, string, tùy chọn); `secure` (query, boolean, tùy chọn); `level` (query, ParamLevel, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamDefinitionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lược đồ khóa theo `ns`, `nhom`, cờ ★, mức `PLATFORM`/`TENANT`; dùng dựng màn tham số chung. Quyền PERM-18-read; FR-18-001, 007.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-definitions
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "key": "18.dlq.replay.batch-max", "ns": "18.", "type": "INT", "level": "TENANT",
   "secure": true, "approvalOwner": "PH-04", "group": "Phát lại",
   "label": "Số mục tối đa một lượt phát lại", "schemaVersion": 7}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-003 · Lược đồ một khóa: kiểu, mặc định, miền, trần, `approvalOwner`, mô tả

::: dac-ta
**Mục đích.** Lược đồ một khóa: kiểu, mặc định, miền, trần, `approvalOwner`, mô tả.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-definitions/{key}`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-001, FR-18-005.

**Tham số.** `key` (path, ParamKey, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamDefinition`; trường bắt buộc: `version`, `id`, `key`, `ns`, `type`, `level`, `secure`, `approvalOwner`, `group`, `label`, `schemaVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010, ERR-18-011 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lược đồ một khóa: kiểu, mặc định, miền, trần, `approvalOwner`, mô tả. Quyền PERM-18-read; FR-18-001, 005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-definitions/18.dlq.replay.batch-max
```

```http
HTTP/1.1 200 OK
ETag: W/"3"
```

#### API-18-004 · Giá trị hiệu lực của tenant theo `ns`, `nhom`, kèm nguồn giá trị (mặc định, tenant, trần)

::: dac-ta
**Mục đích.** Giá trị hiệu lực của tenant theo `ns`, `nhom`, kèm nguồn giá trị (mặc định, tenant, trần).

**Phương thức, đường dẫn.** `GET /api/ops/v1/params`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-002, FR-18-007, FR-18-069.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ns` (query, string, tùy chọn); `group` (query, string, tùy chọn); `q` (query, string, tùy chọn); `changedOnly` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamValuePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị hiệu lực của tenant theo `ns`, `nhom`, kèm nguồn giá trị (mặc định, tenant, trần). Quyền PERM-18-read; FR-18-002, 007, 069.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/params
```

```http
HTTP/1.1 200 OK

{"items": [{"key": "18.dlq.replay.batch-max", "ns": "18.", "version": 3, "source": "DEFAULT",
   "level": "TENANT", "secure": true, "status": "ACTIVE"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-005 · Giá trị hiệu lực của một khóa kèm `ETag` và phiên bản

::: dac-ta
**Mục đích.** Giá trị hiệu lực của một khóa kèm `ETag` và phiên bản.

**Phương thức, đường dẫn.** `GET /api/ops/v1/params/{key}`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-002, FR-18-007.

**Tham số.** `key` (path, ParamKey, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamValue`; trường bắt buộc: `key`, `ns`, `version`, `source`, `level`, `secure`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010, ERR-18-011 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị hiệu lực của một khóa kèm `ETag` và phiên bản. Quyền PERM-18-read; FR-18-002, 007.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/params/18.dlq.replay.batch-max
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"key": "18.dlq.replay.batch-max", "ns": "18.", "value": 10000, "version": 3,
 "source": "DEFAULT", "level": "TENANT", "secure": true, "status": "ACTIVE",
 "pendingRequestId": "0190a1b2-c3d4-7e5f-8a6b-687db7107b46",
 "effectiveFrom": "2026-11-27T09:15:02+07:00", "updatedAt": "2026-11-27T09:15:02+07:00",
 "updatedBy": "tran.thi.binh"}
```

#### API-18-006 · Ghi giá trị theo tenant có `If-Match`, lý do; khóa ★ tạo đề nghị chờ duyệt

::: dac-ta
**Mục đích.** Ghi giá trị theo tenant có `If-Match`, lý do; khóa ★ tạo đề nghị chờ duyệt.

**Phương thức, đường dẫn.** `PUT /api/ops/v1/params/{key}`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-003, FR-18-004, FR-18-069.

**Tham số.** `key` (path, ParamKey, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ParamValueInput`; trường bắt buộc: `value`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamValue`; trường bắt buộc: `key`, `ns`, `version`, `source`, `level`, `secure`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ParamChangeRequest`; trường bắt buộc: `version`, `id`, `key`, `reason`, `status`, `requestedBy`, `requestedAt`, `approvalOwner`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-007, ERR-18-008, ERR-18-010, ERR-18-011, ERR-18-012, ERR-18-013, ERR-18-014, ERR-18-015, ERR-18-018, ERR-18-019, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi giá trị theo tenant: kiểm kiểu (ERR-18-012), miền (ERR-18-013), trần nền tảng (ERR-18-014), mức `PLATFORM` (ERR-18-015), lý do tối thiểu `18.param.reason-min-length`. Khóa thường trả `200` và phát EVT-18-01; khóa ★ có `approvalOwner = PH-18` trả `202` kèm đề nghị và phát EVT-18-02; khóa do phân hệ khác giữ duyệt trả ERR-18-019. Khóa `18.degraded.read-only` không ghi qua API này (ERR-18-003), chỉ đổi qua API-18-187.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/params/18.dlq.replay.batch-max
If-Match: W/"3"

{"value": 10000, "reason": "Tăng giới hạn để xử lý tồn đọng sau sự cố mạng ngày 26/11"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"key": "18.dlq.replay.batch-max", "ns": "18.", "value": 10000, "version": 5,
 "source": "TENANT", "level": "TENANT", "secure": false, "status": "ACTIVE",
 "effectiveFrom": "2026-11-27T09:15:02+07:00", "updatedAt": "2026-11-27T09:15:02+07:00",
 "updatedBy": "nguyen.van.an"}
```

#### API-18-007 · Kiểm kiểu, miền, trần của một hoặc nhiều giá trị mà không ghi

::: dac-ta
**Mục đích.** Kiểm kiểu, miền, trần của một hoặc nhiều giá trị mà không ghi.

**Phương thức, đường dẫn.** `POST /api/ops/v1/params:validate`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-003, FR-18-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ParamValidateInput`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamValidateResult`; trường bắt buộc: `valid`, `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-010, ERR-18-011, ERR-18-012, ERR-18-013, ERR-18-014, ERR-18-015, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm kiểu, miền, trần của một hoặc nhiều giá trị mà không ghi. Quyền PERM-18-config; FR-18-003, 007.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/params:validate

{"items": [{"key": "18.dlq.replay.batch-max", "value": 10000}]}
```

```http
HTTP/1.1 200 OK

{"valid": true, "results": [{"key": "18.dlq.replay.batch-max", "valid": true}]}
```

#### API-18-008 · Danh sách đề nghị đổi tham số ★ theo trạng thái

::: dac-ta
**Mục đích.** Danh sách đề nghị đổi tham số ★ theo trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-change-requests`.

**Quyền.** `PERM-18-config / PERM-18-approve`.

**FR hiện thực.** FR-18-004.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, ChangeRequestStatus, tùy chọn); `key` (query, ParamKey, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamChangeRequestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách đề nghị đổi tham số ★ theo trạng thái. Quyền PERM-18-config / PERM-18-approve; FR-18-004.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-change-requests
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "key": "18.dlq.replay.batch-max",
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an",
   "requestedAt": "2026-11-27T09:15:02+07:00", "approvalOwner": "PH-04"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-009 · Chi tiết đề nghị: giá trị trước, sau, lý do, người đề nghị

::: dac-ta
**Mục đích.** Chi tiết đề nghị: giá trị trước, sau, lý do, người đề nghị.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-change-requests/{requestId}`.

**Quyền.** `PERM-18-config / PERM-18-approve`.

**FR hiện thực.** FR-18-004.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamChangeRequest`; trường bắt buộc: `version`, `id`, `key`, `reason`, `status`, `requestedBy`, `requestedAt`, `approvalOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết đề nghị: giá trị trước, sau, lý do, người đề nghị. Quyền PERM-18-config / PERM-18-approve; FR-18-004.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-change-requests/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "key": "18.dlq.replay.batch-max", "proposedValue": 10000, "currentValue": 5000,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an",
 "requestedAt": "2026-11-27T09:15:02+07:00", "decidedBy": "le.thi.chi",
 "decidedAt": "2026-11-27T09:15:02+07:00",
 "comment": "Đã đối chiếu với quy trình vận hành của tỉnh",
 "expiresAt": "2026-11-27T09:15:02+07:00", "approvalOwner": "PH-04"}
```

#### API-18-010 · Duyệt đề nghị (người thứ hai), giá trị thành `ACTIVE`

::: dac-ta
**Mục đích.** Duyệt đề nghị (người thứ hai), giá trị thành `ACTIVE`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-change-requests/{requestId}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-004.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamValueVersion`; trường bắt buộc: `version`, `id`, `key`, `versionNo`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-013, ERR-18-019, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bốn mắt: người duyệt khác người đề nghị (ERR-18-005); giá trị thành `ACTIVE`, phiên bản cũ `SUPERSEDED`, phát EVT-18-01.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-change-requests/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "key": "18.dlq.replay.batch-max", "versionNo": 4, "value": 10000, "previousValue": 5000,
 "status": "ACTIVE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "changeRequestId": "0190a1b2-c3d4-7e5f-8a6b-9f00f1810a63", "rollbackOfVersionNo": 12,
 "effectiveFrom": "2026-11-27T09:15:02+07:00", "supersededAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-011 · Từ chối đề nghị kèm lý do

::: dac-ta
**Mục đích.** Từ chối đề nghị kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-change-requests/{requestId}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-004.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamChangeRequest`; trường bắt buộc: `version`, `id`, `key`, `reason`, `status`, `requestedBy`, `requestedAt`, `approvalOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối đề nghị kèm lý do. Quyền PERM-18-approve; FR-18-004.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-change-requests/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "key": "18.dlq.replay.batch-max", "proposedValue": 10000, "currentValue": 5000,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an",
 "requestedAt": "2026-11-27T09:15:02+07:00", "decidedBy": "le.thi.chi",
 "decidedAt": "2026-11-27T09:15:02+07:00",
 "comment": "Đã đối chiếu với quy trình vận hành của tỉnh",
 "expiresAt": "2026-11-27T09:15:02+07:00", "approvalOwner": "PH-04"}
```

#### API-18-012 · Người đề nghị rút đề nghị chưa duyệt

::: dac-ta
**Mục đích.** Người đề nghị rút đề nghị chưa duyệt.

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-change-requests/{requestId}:withdraw`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-004.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamChangeRequest`; trường bắt buộc: `version`, `id`, `key`, `reason`, `status`, `requestedBy`, `requestedAt`, `approvalOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người đề nghị rút đề nghị chưa duyệt. Quyền PERM-18-config; FR-18-004.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-change-requests/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:withdraw
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "key": "18.dlq.replay.batch-max", "proposedValue": 10000, "currentValue": 5000,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an",
 "requestedAt": "2026-11-27T09:15:02+07:00", "decidedBy": "le.thi.chi",
 "decidedAt": "2026-11-27T09:15:02+07:00",
 "comment": "Đã đối chiếu với quy trình vận hành của tỉnh",
 "expiresAt": "2026-11-27T09:15:02+07:00", "approvalOwner": "PH-04"}
```

#### API-18-013 · Lịch sử phiên bản giá trị của khóa theo tenant

::: dac-ta
**Mục đích.** Lịch sử phiên bản giá trị của khóa theo tenant.

**Phương thức, đường dẫn.** `GET /api/ops/v1/params/{key}/versions`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-005.

**Tham số.** `key` (path, ParamKey, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, ParamVersionStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamValueVersionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010, ERR-18-011 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử phiên bản giá trị của khóa theo tenant. Quyền PERM-18-read; FR-18-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/params/18.dlq.replay.batch-max/versions
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "key": "18.dlq.replay.batch-max", "versionNo": 4, "status": "ACTIVE"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-014 · So sánh hai phiên bản (`from`, `to`) hoặc so với mặc định

::: dac-ta
**Mục đích.** So sánh hai phiên bản (`from`, `to`) hoặc so với mặc định.

**Phương thức, đường dẫn.** `GET /api/ops/v1/params/{key}/versions:compare`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-005.

**Tham số.** `key` (path, ParamKey, bắt buộc); `from` (query, integer, bắt buộc); `to` (query, integer, tùy chọn); `compareToDefault` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamVersionCompare`; trường bắt buộc: `key`, `from`, `compareToDefault`, `diff`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010, ERR-18-011 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** So sánh hai phiên bản (`from`, `to`) hoặc so với mặc định. Quyền PERM-18-read; FR-18-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/params/18.dlq.replay.batch-max/versions:compare?from=3
```

```http
HTTP/1.1 200 OK

{"key": "18.dlq.replay.batch-max", "from": 12, "to": 12, "compareToDefault": false,
 "diff": [{"path": "$.trangThai", "op": "ADD"}]}
```

#### API-18-015 · Khôi phục giá trị của phiên bản cũ thành phiên bản mới

::: dac-ta
**Mục đích.** Khôi phục giá trị của phiên bản cũ thành phiên bản mới.

**Phương thức, đường dẫn.** `POST /api/ops/v1/params/{key}/versions/{versionNo}:restore`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-005.

**Tham số.** `key` (path, ParamKey, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamValue`; trường bắt buộc: `key`, `ns`, `version`, `source`, `level`, `secure`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-011, ERR-18-023, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khôi phục giá trị của phiên bản cũ thành phiên bản mới. Quyền PERM-18-config; FR-18-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/params/18.dlq.replay.batch-max/versions/4:restore
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"key": "18.dlq.replay.batch-max", "ns": "18.", "value": 10000, "version": 3,
 "source": "DEFAULT", "level": "TENANT", "secure": true, "status": "ACTIVE",
 "pendingRequestId": "0190a1b2-c3d4-7e5f-8a6b-687db7107b46",
 "effectiveFrom": "2026-11-27T09:15:02+07:00", "updatedAt": "2026-11-27T09:15:02+07:00",
 "updatedBy": "tran.thi.binh"}
```

#### API-18-016 · Nhật ký đổi tham số của tenant theo thời gian, không gian tên, người đổi

::: dac-ta
**Mục đích.** Nhật ký đổi tham số của tenant theo thời gian, không gian tên, người đổi.

**Phương thức, đường dẫn.** `GET /api/ops/v1/param-changes`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-005, FR-18-006, FR-18-070.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ns` (query, string, tùy chọn); `key` (query, ParamKey, tùy chọn); `changedBy` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamChangePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký đổi tham số của tenant theo thời gian, không gian tên, người đổi. Quyền PERM-18-read; FR-18-005, 006, 070.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/param-changes
```

```http
HTTP/1.1 200 OK

{"items": [{"key": "18.dlq.replay.batch-max", "ns": "18.", "versionNo": 4,
   "changeType": "VALUE_CHANGED", "source": "UI", "changedBy": "nguyen.van.an",
   "changedAt": "2026-11-27T09:15:02+07:00"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-017 · Xuất gói tham số của tenant theo không gian tên, có chữ ký và tổng kiểm tra

::: dac-ta
**Mục đích.** Xuất gói tham số của tenant theo không gian tên, có chữ ký và tổng kiểm tra.

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-bundles:export`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BundleExportInput`; trường bắt buộc: `namespaces`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ParamBundle`; trường bắt buộc: `version`, `id`, `bundleCode`, `direction`, `namespaces`, `itemCount`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-013, ERR-18-020, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất gói tham số của tenant theo không gian tên, có chữ ký và tổng kiểm tra. Quyền PERM-18-admin; FR-18-008.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-bundles:export
Idempotency-Key: dh-2026-11-27-0001

{"namespaces": ["18."], "includeDefaults": false}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/param-bundles:export/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "bundleCode": "PB-2026-0004", "direction": "EXPORT", "namespaces": ["18."],
 "includeDefaults": false, "targetTenant": "T68", "itemCount": 12,
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "status": "DRAFT",
 "diff": [{"key": "18.dlq.replay.batch-max", "change": "ADD", "secure": true}],
 "applied": 12, "pendingApproval": 12,
 "downloadUrl": "https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11",
 "expiresAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-018 · Nạp gói và chạy so khớp với lược đồ đích (`dryRun` mặc định `true`)

::: dac-ta
**Mục đích.** Nạp gói và chạy so khớp với lược đồ đích (`dryRun` mặc định `true`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-bundles:import`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BundleImportInput`; trường bắt buộc: `bundle`, `sha256`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamBundle`; trường bắt buộc: `version`, `id`, `bundleCode`, `direction`, `namespaces`, `itemCount`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-013, ERR-18-020, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nạp gói và chạy so khớp với lược đồ đích (`dryRun` mặc định `true`). Quyền PERM-18-admin; FR-18-008.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-bundles:import
Idempotency-Key: dh-2026-11-27-0001

{"bundle": {"format": "dh-param-bundle/1", "namespaces": ["18."], "items": 61},
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "targetTenant": "T68", "dryRun": true}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "bundleCode": "PB-2026-0004", "direction": "EXPORT", "namespaces": ["18."],
 "includeDefaults": false, "targetTenant": "T68", "itemCount": 12,
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "status": "DRAFT",
 "diff": [{"key": "18.dlq.replay.batch-max", "change": "ADD", "secure": true}],
 "applied": 12, "pendingApproval": 12,
 "downloadUrl": "https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11",
 "expiresAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-019 · Áp gói đã so khớp; khóa ★ trong gói tạo đề nghị chờ duyệt

::: dac-ta
**Mục đích.** Áp gói đã so khớp; khóa ★ trong gói tạo đề nghị chờ duyệt.

**Phương thức, đường dẫn.** `POST /api/ops/v1/param-bundles/{bundleId}:apply`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-008.

**Tham số.** `bundleId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParamBundle`; trường bắt buộc: `version`, `id`, `bundleCode`, `direction`, `namespaces`, `itemCount`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-013, ERR-18-020, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp gói đã so khớp; khóa ★ trong gói tạo đề nghị chờ duyệt. Quyền PERM-18-admin; FR-18-008.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/param-bundles/0190a1b2-c3d4-7e5f-8a6b-25cdd2af32ad:apply
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "bundleCode": "PB-2026-0004", "direction": "EXPORT", "namespaces": ["18."],
 "includeDefaults": false, "targetTenant": "T68", "itemCount": 12,
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "status": "DRAFT",
 "diff": [{"key": "18.dlq.replay.batch-max", "change": "ADD", "secure": true}],
 "applied": 12, "pendingApproval": 12,
 "downloadUrl": "https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11",
 "expiresAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-020 · Danh sách cờ tính năng `ff.*`, chủ sở hữu, ngày gỡ, giá trị theo tenant

::: dac-ta
**Mục đích.** Danh sách cờ tính năng `ff.*`, chủ sở hữu, ngày gỡ, giá trị theo tenant.

**Phương thức, đường dẫn.** `GET /api/ops/v1/feature-flags`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-009.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn); `status` (query, string, tùy chọn); `retireBefore` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeatureFlagPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách cờ tính năng `ff.*`, chủ sở hữu, ngày gỡ, giá trị theo tenant. Quyền PERM-18-read; FR-18-009.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/feature-flags
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "flagKey": "ff.ph04.moi",
   "description": "Mô tả ngắn phục vụ vận hành tỉnh", "ownerPh": "PH-04",
   "ownerUser": "pham.van.duc", "retireBy": "2027-03-31", "level": "TENANT",
   "defaultValue": true, "enabled": true, "status": "ACTIVE"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-021 · Khai báo cờ tính năng mới có chủ sở hữu, ngày gỡ dự kiến

::: dac-ta
**Mục đích.** Khai báo cờ tính năng mới có chủ sở hữu, ngày gỡ dự kiến.

**Phương thức, đường dẫn.** `POST /api/ops/v1/feature-flags`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-009.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FeatureFlagInput`; trường bắt buộc: `flagKey`, `description`, `ownerPh`, `ownerUser`, `retireBy`, `level`, `defaultValue`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `FeatureFlag`; trường bắt buộc: `version`, `id`, `flagKey`, `description`, `ownerPh`, `ownerUser`, `retireBy`, `level`, `defaultValue`, `enabled`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-021, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khai báo cờ tính năng mới có chủ sở hữu, ngày gỡ dự kiến. Quyền PERM-18-admin; FR-18-009.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/feature-flags
Idempotency-Key: dh-2026-11-27-0001

{"flagKey": "ff.ph04.moi", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "ownerPh": "PH-04", "ownerUser": "pham.van.duc", "retireBy": "2027-03-31",
 "level": "TENANT", "defaultValue": true}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/feature-flags/ff.ph04.moi
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "flagKey": "ff.ph04.moi", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "ownerPh": "PH-04", "ownerUser": "pham.van.duc", "retireBy": "2027-03-31",
 "level": "TENANT", "defaultValue": true, "enabled": true, "status": "ACTIVE",
 "retiredAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-022 · Bật, tắt cờ cho tenant hoặc đổi ngày gỡ (`If-Match`)

::: dac-ta
**Mục đích.** Bật, tắt cờ cho tenant hoặc đổi ngày gỡ (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/feature-flags/{flagKey}`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-009.

**Tham số.** `flagKey` (path, FlagKey, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FeatureFlagPatch`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeatureFlag`; trường bắt buộc: `version`, `id`, `flagKey`, `description`, `ownerPh`, `ownerUser`, `retireBy`, `level`, `defaultValue`, `enabled`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-007, ERR-18-008, ERR-18-010, ERR-18-021, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bật, tắt cờ cho tenant hoặc đổi ngày gỡ (`If-Match`). Quyền PERM-18-config; FR-18-009.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/feature-flags/ff.ph04.moi
If-Match: W/"3"

{"enabled": true, "retireBy": "2027-03-31",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "flagKey": "ff.ph04.moi", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "ownerPh": "PH-04", "ownerUser": "pham.van.duc", "retireBy": "2027-03-31",
 "level": "TENANT", "defaultValue": true, "enabled": true, "status": "ACTIVE",
 "retiredAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-023 · Gỡ cờ sau khi mã đã bỏ nhánh cờ

::: dac-ta
**Mục đích.** Gỡ cờ sau khi mã đã bỏ nhánh cờ.

**Phương thức, đường dẫn.** `POST /api/ops/v1/feature-flags/{flagKey}:retire`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-009.

**Tham số.** `flagKey` (path, FlagKey, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `FeatureFlag`; trường bắt buộc: `version`, `id`, `flagKey`, `description`, `ownerPh`, `ownerUser`, `retireBy`, `level`, `defaultValue`, `enabled`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ cờ sau khi mã đã bỏ nhánh cờ. Quyền PERM-18-admin; FR-18-009.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/feature-flags/ff.ph04.moi:retire
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "flagKey": "ff.ph04.moi", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "ownerPh": "PH-04", "ownerUser": "pham.van.duc", "retireBy": "2027-03-31",
 "level": "TENANT", "defaultValue": true, "enabled": true, "status": "ACTIVE",
 "retiredAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-024 · Danh sách đích egress cho phép của tenant theo mục đích

::: dac-ta
**Mục đích.** Danh sách đích egress cho phép của tenant theo mục đích.

**Phương thức, đường dẫn.** `GET /api/ops/v1/egress-allowlist`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-010.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `purpose` (query, EgressPurpose, tùy chọn); `usedBy` (query, ModuleCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EgressEntryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách đích egress cho phép của tenant theo mục đích. Quyền PERM-18-read; FR-18-010.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/egress-allowlist
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "host": "webhook.so-tttt.t68.gov.vn", "port": 443, "purpose": "WEBHOOK",
   "usedBy": "PH-04", "enabled": true}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-025 · Thêm đích egress (FQDN, cổng, mục đích, hạn dùng)

::: dac-ta
**Mục đích.** Thêm đích egress (FQDN, cổng, mục đích, hạn dùng).

**Phương thức, đường dẫn.** `POST /api/ops/v1/egress-allowlist`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-010.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EgressInput`; trường bắt buộc: `host`, `purpose`, `usedBy`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `EgressEntry`; trường bắt buộc: `version`, `id`, `host`, `port`, `purpose`, `usedBy`, `enabled`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-013, ERR-18-022, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm đích egress (FQDN, cổng, mục đích, hạn dùng). Quyền PERM-18-config; FR-18-010.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/egress-allowlist
Idempotency-Key: dh-2026-11-27-0001

{"host": "webhook.so-tttt.t68.gov.vn", "port": 443, "purpose": "WEBHOOK",
 "usedBy": "PH-04", "expiresAt": "2027-11-27",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/egress-allowlist/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "host": "webhook.so-tttt.t68.gov.vn", "port": 443, "purpose": "WEBHOOK",
 "usedBy": "PH-04", "expiresAt": "2027-11-27",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "enabled": true}
```

#### API-18-026 · Gỡ đích egress kèm lý do

::: dac-ta
**Mục đích.** Gỡ đích egress kèm lý do.

**Phương thức, đường dẫn.** `DELETE /api/ops/v1/egress-allowlist/{entryId}`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-18-010.

**Tham số.** `entryId` (path, string, bắt buộc); `reason` (query, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ đích egress kèm lý do. Quyền PERM-18-config; FR-18-010.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/ops/v1/egress-allowlist/0190a1b2-c3d4-7e5f-8a6b-fb8bd9038ff1?reason=Đích không còn dùng
If-Match: W/"3"
```

```http
HTTP/1.1 204 No Content
```

#### API-18-027 · PH chủ đăng ký hoặc cập nhật lược đồ khóa của không gian tên khi khởi động

::: dac-ta
**Mục đích.** PH chủ đăng ký hoặc cập nhật lược đồ khóa của không gian tên khi khởi động.

**Phương thức, đường dẫn.** `PUT /ops/internal/v1/param-namespaces/{ns}/schema`.

**Quyền.** scope ops:param-register; mTLS SPIFFE.

**FR hiện thực.** FR-18-001.

**Tham số.** `ns` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `NamespaceSchemaInput`; trường bắt buộc: `ownerPh`, `title`, `schemaVersion`, `definitions`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NamespaceRegistration`; trường bắt buộc: `ns`, `schemaVersion`, `added`, `changed`, `deprecated`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-010, ERR-18-016, ERR-18-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH chủ đăng ký lược đồ khi khởi động; lũy đẳng theo `schemaVersion`. Không gian tên không thuộc phân hệ gọi: ERR-18-017; lược đồ mới xung đột giá trị đang dùng: ERR-18-016.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /ops/internal/v1/param-namespaces/18./schema
```

```http
HTTP/1.1 200 OK
```

#### API-18-028 · Đọc lô giá trị hiệu lực của nhiều khóa, cờ, egress cho một tenant; hỗ trợ `If-None-Match`

::: dac-ta
**Mục đích.** Đọc lô giá trị hiệu lực của nhiều khóa, cờ, egress cho một tenant; hỗ trợ `If-None-Match`.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/params:batch-get`.

**Quyền.** scope ops:param-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-002, FR-18-009, FR-18-010.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ParamBatchGetInput`; trường bắt buộc: `tenant`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamBatchResult`; trường bắt buộc: `tenant`, `values`, `unknown`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc lô cho `dh-ops-client` (bộ đệm Caffeine ≤ 60 giây, BR-18-006); gửi `If-None-Match` để nhận `304` khi không đổi (NFR-18-004).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/params:batch-get

{"tenant": "T68", "keys": ["18.dlq.replay.batch-max"], "ns": "18.",
 "flags": ["ff.ph04.moi"], "includeEgress": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"t68-18-42"

{"tenant": "T68",
 "values": [{"key": "18.dlq.replay.batch-max", "version": 3, "source": "DEFAULT"}],
 "unknown": [], "flags": [{"flagKey": "ff.ph04.moi", "enabled": true}],
 "egress": [{"host": "webhook.so-tttt.t68.gov.vn", "port": 443, "purpose": "WEBHOOK"}]}
```

#### API-18-029 · Ảnh chụp toàn bộ không gian tên của tenant kèm `ETag` để làm bộ đệm

::: dac-ta
**Mục đích.** Ảnh chụp toàn bộ không gian tên của tenant kèm `ETag` để làm bộ đệm.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/params/{tenant}/{ns}`.

**Quyền.** scope ops:param-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-002.

**Tham số.** `tenant` (path, TenantCode, bắt buộc); `ns` (path, string, bắt buộc); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParamSnapshot`; trường bắt buộc: `tenant`, `ns`, `schemaVersion`, `generatedAt`, `values`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ảnh chụp toàn bộ không gian tên của tenant kèm `ETag` để làm bộ đệm. Quyền scope ops:param-read; mTLS SPIFFE; FR-18-002.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/params/T68/18.
```

```http
HTTP/1.1 200 OK
ETag: W/"t68-18-42"

{"tenant": "T68", "ns": "18.", "schemaVersion": 7,
 "generatedAt": "2026-11-27T09:15:02+07:00",
 "values": [{"key": "18.dlq.replay.batch-max", "version": 3, "source": "DEFAULT"}]}
```

#### API-18-030 · PH-20 ghi mặc định khi khởi tạo tenant, chỉ thêm khóa chưa có

::: dac-ta
**Mục đích.** PH-20 ghi mặc định khi khởi tạo tenant, chỉ thêm khóa chưa có.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/tenants/{tenant}/params:seed-defaults`.

**Quyền.** scope ops:param-write; mTLS SPIFFE.

**FR hiện thực.** FR-18-011.

**Tham số.** `tenant` (path, TenantCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SeedDefaultsInput`; trường bắt buộc: `profile`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SeedResult`; trường bắt buộc: `tenant`, `profile`, `added`, `kept`, `namespaces`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-20 gọi khi nhận `platform.tenant.created.v1` hoặc khi khởi tạo; chỉ thêm khóa chưa có, không ghi đè giá trị tenant đã đặt (FR-18-011).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/tenants/T68/params:seed-defaults
Idempotency-Key: dh-2026-11-27-0001

{"profile": "QM-VUA", "namespaces": ["18."]}
```

```http
HTTP/1.1 200 OK

{"tenant": "T68", "profile": "QM-VUA", "added": 12, "kept": 12, "namespaces": ["18."]}
```

### 14.2. Tiếp nhận DLQ

Nguồn DLQ và cổng phát lại, ghi DLQ qua API cho phân hệ khác, đối soát chỉ mục với Kafka, liên thông DLQ tầng sự kiện của PH-10 (FR-18-012…018). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-031 · Danh sách nguồn DLQ đã đăng ký, kiểu cổng phát lại, trạng thái

::: dac-ta
**Mục đích.** Danh sách nguồn DLQ đã đăng ký, kiểu cổng phát lại, trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq-sources`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-012.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `sourcePh` (query, ModuleCode, tùy chọn); `replayMode` (query, ReplayMode, tùy chọn); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqSourcePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách nguồn DLQ đã đăng ký, kiểu cổng phát lại, trạng thái. Quyền PERM-18-read; FR-18-012.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq-sources
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "sourceCode": "ph04-runtime",
   "sourcePh": "PH-04", "ingestChannel": "KAFKA", "replayMode": "KAFKA_TOPIC",
   "maxRatePerSecond": 50, "supportsRevision": true, "status": "ACTIVE"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-032 · Khai báo nguồn DLQ thủ công (nguồn không tự đăng ký)

::: dac-ta
**Mục đích.** Khai báo nguồn DLQ thủ công (nguồn không tự đăng ký).

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq-sources`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DlqSourceInput`; trường bắt buộc: `sourceCode`, `sourcePh`, `ingestChannel`, `replayMode`, `maxRatePerSecond`, `supportsRevision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `DlqSource`; trường bắt buộc: `version`, `id`, `sourceCode`, `sourcePh`, `ingestChannel`, `replayMode`, `maxRatePerSecond`, `supportsRevision`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khai báo nguồn DLQ thủ công (nguồn không tự đăng ký). Quyền PERM-18-admin; FR-18-012.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq-sources
Idempotency-Key: dh-2026-11-27-0001

{"sourceCode": "ph04-runtime", "sourcePh": "PH-04", "ingestChannel": "KAFKA",
 "replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "description": "Mô tả ngắn phục vụ vận hành tỉnh"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/dlq-sources/ph19-inbox
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "sourceCode": "ph04-runtime", "sourcePh": "PH-04", "ingestChannel": "KAFKA",
 "replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "status": "ACTIVE", "description": "Mô tả ngắn phục vụ vận hành tỉnh"}
```

#### API-18-033 · Sửa cổng phát lại, tạm ngừng hoặc bật lại nguồn (`If-Match`)

::: dac-ta
**Mục đích.** Sửa cổng phát lại, tạm ngừng hoặc bật lại nguồn (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/dlq-sources/{sourceCode}`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-012.

**Tham số.** `sourceCode` (path, SourceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DlqSourcePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqSource`; trường bắt buộc: `version`, `id`, `sourceCode`, `sourcePh`, `ingestChannel`, `replayMode`, `maxRatePerSecond`, `supportsRevision`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa cổng phát lại, tạm ngừng hoặc bật lại nguồn (`If-Match`). Quyền PERM-18-admin; FR-18-012.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/dlq-sources/ph04-runtime
If-Match: W/"3"

{"replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "status": "ACTIVE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "sourceCode": "ph04-runtime", "sourcePh": "PH-04", "ingestChannel": "KAFKA",
 "replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "status": "ACTIVE", "description": "Mô tả ngắn phục vụ vận hành tỉnh"}
```

#### API-18-034 · Nguồn tự đăng ký hoặc cập nhật cổng phát lại khi khởi động

::: dac-ta
**Mục đích.** Nguồn tự đăng ký hoặc cập nhật cổng phát lại khi khởi động.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/dlq-sources:register`.

**Quyền.** scope ops:dlq-write; mTLS SPIFFE.

**FR hiện thực.** FR-18-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DlqSourceInput`; trường bắt buộc: `sourceCode`, `sourcePh`, `ingestChannel`, `replayMode`, `maxRatePerSecond`, `supportsRevision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqSource`; trường bắt buộc: `version`, `id`, `sourceCode`, `sourcePh`, `ingestChannel`, `replayMode`, `maxRatePerSecond`, `supportsRevision`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn tự đăng ký hoặc cập nhật cổng phát lại khi khởi động. Quyền scope ops:dlq-write; mTLS SPIFFE; FR-18-012.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/dlq-sources:register
Idempotency-Key: dh-2026-11-27-0001

{"sourceCode": "ph04-runtime", "sourcePh": "PH-04", "ingestChannel": "KAFKA",
 "replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "description": "Mô tả ngắn phục vụ vận hành tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "sourceCode": "ph04-runtime", "sourcePh": "PH-04", "ingestChannel": "KAFKA",
 "replayMode": "KAFKA_TOPIC", "replayTarget": "t68.integration.replay.v1",
 "maxRatePerSecond": 50, "supportsRevision": true, "owners": ["nhom-van-hanh-t68"],
 "status": "ACTIVE", "description": "Mô tả ngắn phục vụ vận hành tỉnh"}
```

#### API-18-035 · PH khác ghi một mục DLQ kèm ngữ cảnh chuẩn (PH-01, PH-06, PH-08, PH-19)

::: dac-ta
**Mục đích.** PH khác ghi một mục DLQ kèm ngữ cảnh chuẩn (PH-01, PH-06, PH-08, PH-19).

**Phương thức, đường dẫn.** `POST /ops/internal/v1/dlq/messages`.

**Quyền.** scope ops:dlq-write; mTLS SPIFFE.

**FR hiện thực.** FR-18-014, FR-18-015, FR-18-016.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DlqMessageInput`; trường bắt buộc: `tenant`, `sourceCode`, `sourcePh`, `messageId`, `reason`, `errorCode`, `stage`, `attempts`, `contentType`, `payload`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `DlqIngestResult`; trường bắt buộc: `dlqId`, `status`, `duplicate`, `occurrences`, `storage`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `413`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-024, ERR-18-025, ERR-18-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi một mục DLQ theo hợp đồng ngữ cảnh chuẩn (FRS bảng 4.1b). Thiếu trường bắt buộc: từ chối `422` với ERR-18-024, mục không được ghi (BR-18-013; đường topic mới ghi `POISON`); payload > `18.dlq.payload.inline-max-kb` lưu ở Garage, > `18.dlq.payload.max-mb` trả ERR-18-025; khử trùng theo `dlqKey` (trùng trả `duplicate = true`).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/dlq/messages
Idempotency-Key: dh-2026-11-27-0001

{"tenant": "T68", "sourceCode": "ph19-inbox", "sourcePh": "PH-19",
 "messageId": "pay-cb-2026-0091", "reason": "TARGET_UNAVAILABLE",
 "errorCode": "ERR-19-104", "stage": "xu-ly-callback", "attempts": 5,
 "errorClass": "TRANSIENT", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "contentType": "application/json",
 "payload": {"maGiaoDich": "GD-2026-000045", "trangThai": "THANH_CONG"}}
```

```http
HTTP/1.1 201 Created
Location: /ops/internal/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "status": "NEW", "duplicate": false,
 "occurrences": 1, "storage": "INLINE"}
```

#### API-18-036 · Ghi lô tới 500 mục DLQ, kết quả theo từng mục

::: dac-ta
**Mục đích.** Ghi lô tới 500 mục DLQ, kết quả theo từng mục.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/dlq/messages:batch`.

**Quyền.** scope ops:dlq-write; mTLS SPIFFE.

**FR hiện thực.** FR-18-014, FR-18-015, FR-18-016.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DlqBatchInput`; trường bắt buộc: `items`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `207`, `DlqBatchResult`; trường bắt buộc: `accepted`, `rejected`, `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `413`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-024, ERR-18-025, ERR-18-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi lô tới 500 mục; phản hồi `207` với kết quả từng mục theo `index`, không hủy cả lô khi một mục lỗi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/dlq/messages:batch
Idempotency-Key: dh-2026-11-27-0001

{"items": [{"tenant": "T68", "sourceCode": "ph04-runtime", "sourcePh": "PH-04",
   "messageId": "msg-2026-000123", "reason": "TARGET_UNAVAILABLE",
   "errorCode": "ERR-04-101", "stage": "goi-he-dich", "attempts": 3,
   "contentType": "application/json",
   "payload": {"soHoSo": "HS-2026-000123", "trangThai": "DA_TIEP_NHAN"}}]}
```

```http
HTTP/1.1 207

{"accepted": 12, "rejected": 12, "results": [{"index": 0, "httpStatus": 201}]}
```

#### API-18-037 · Kết quả đối soát chỉ mục và Kafka gần nhất theo phân vùng

::: dac-ta
**Mục đích.** Kết quả đối soát chỉ mục và Kafka gần nhất theo phân vùng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/reconciliation`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-018.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqReconciliation`; trường bắt buộc: `runId`, `status`, `from`, `to`, `startedAt`, `missingTotal`, `extraTotal`, `partitions`.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả đối soát chỉ mục và Kafka gần nhất theo phân vùng. Quyền PERM-18-dlq; FR-18-018.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/reconciliation
```

```http
HTTP/1.1 200 OK

{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "status": "COMPLETED",
 "from": "2026-11-26T00:00:00+07:00", "to": "2026-11-27T00:00:00+07:00",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "missingTotal": 12, "extraTotal": 12,
 "partitions": [{"partition": 12, "firstOffset": 12, "lastOffset": 12, "indexed": 12, "missing": 12,
   "extra": 12}]}
```

#### API-18-038 · Chạy đối soát ngay ngoài lịch

::: dac-ta
**Mục đích.** Chạy đối soát ngay ngoài lịch.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/reconciliation:run`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `DlqReconciliation`; trường bắt buộc: `runId`, `status`, `from`, `to`, `startedAt`, `missingTotal`, `extraTotal`, `partitions`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy đối soát ngay ngoài lịch. Quyền PERM-18-dlq; FR-18-018.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/reconciliation:run
Idempotency-Key: dh-2026-11-27-0001

{"from": "2026-11-26T00:00:00+07:00", "to": "2026-11-27T00:00:00+07:00"}
```

```http
HTTP/1.1 202 Accepted

{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "status": "COMPLETED",
 "from": "2026-11-26T00:00:00+07:00", "to": "2026-11-27T00:00:00+07:00",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "missingTotal": 12, "extraTotal": 12,
 "partitions": [{"partition": 12, "firstOffset": 12, "lastOffset": 12, "indexed": 12, "missing": 12,
   "extra": 12}]}
```

#### API-18-039 · Siêu dữ liệu DLQ tầng sự kiện của PH-10 hiển thị chung (gọi API-10-060)

::: dac-ta
**Mục đích.** Siêu dữ liệu DLQ tầng sự kiện của PH-10 hiển thị chung (gọi API-10-060).

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/event-dead-letters`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-017.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `subscriptionCode` (query, string, tùy chọn); `topic` (query, string, tùy chọn); `errorCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EventDeadLetterPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-010, ERR-18-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Siêu dữ liệu DLQ tầng sự kiện của PH-10 hiển thị chung (gọi API-10-060). Quyền PERM-18-dlq; FR-18-017.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/event-dead-letters
```

```http
HTTP/1.1 200 OK

{"items": [{"entryRef": "ENTRY-77", "subscriptionCode": "sub-ho-tich",
   "topic": "t68.civil.birth.registered.v1", "attempts": 3,
   "firstFailedAt": "2026-11-27T09:15:02+07:00", "status": "OPEN"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-040 · Đề nghị PH-10 phát lại mục DLQ tầng sự kiện (gọi API-10-064)

::: dac-ta
**Mục đích.** Đề nghị PH-10 phát lại mục DLQ tầng sự kiện (gọi API-10-064).

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/event-dead-letters/{entryRef}:request-replay`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-017.

**Tham số.** `entryRef` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `EventReplayRequest`; trường bắt buộc: `entryRef`, `replayCode`, `status`, `requestedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-035, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-18 không tự phát lại mục tầng sự kiện; gọi API-10-064 với scope `event:replay`, PH-10 duyệt theo quy tắc của mình (ADR-181, Q18-03).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/event-dead-letters/ENTRY-77:request-replay
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 202 Accepted

{"entryRef": "ENTRY-77", "replayCode": "RP-0091", "status": "REQUESTED",
 "requestedAt": "2026-11-27T09:15:02+07:00"}
```

### 14.3. Phân loại và xử lý DLQ

Danh sách có `facets`, nhóm dấu hiệu lỗi, chi tiết và chẩn đoán từ PH-13, xem payload có lý do, phân loại, gán, bản sửa payload, sổ tay mã lỗi, API đọc cho PH-17 và PH-13 (FR-18-019…026). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-041 · Danh sách mục DLQ: lọc, tìm, sắp xếp, phân trang, khối `facets` (siêu dữ liệu, thao tác cần `PERM-18-dlq`)

::: dac-ta
**Mục đích.** Danh sách mục DLQ: lọc, tìm, sắp xếp, phân trang, khối `facets` (siêu dữ liệu, thao tác cần `PERM-18-dlq`).

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-019, FR-18-023.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `sourceCode` (query, array, tùy chọn); `flow` (query, string, tùy chọn); `errorCode` (query, ErrorCode, tùy chọn); `errorClass` (query, ErrorClass, tùy chọn); `status` (query, DlqStatus, tùy chọn); `age` (query, string, tùy chọn); `assignee` (query, string, tùy chọn); `priority` (query, Priority, tùy chọn); `groupId` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqMessagePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách có khối `facets` (đếm theo nguồn, lớp lỗi, trạng thái, mã lỗi) cho bộ lọc UI-18-01; p95 ≤ 1,5 s cho trang 50 dòng (NFR-18-003). Không trả payload.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
   "sourcePh": "PH-04", "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE",
   "errorCode": "ERR-04-101", "errorClass": "TRANSIENT", "attempts": 3, "occurrences": 4,
   "status": "TRIAGED", "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
   "storage": "INLINE", "currentRevisionNo": 1}], "page": 0, "size": 20,
 "totalElements": 1, "facets": {"bySource": [{"value": "ph04-runtime", "count": 37}],
  "byErrorClass": [{"value": "ph04-runtime", "count": 37}],
  "byStatus": [{"value": "ph04-runtime", "count": 37}],
  "byErrorCode": [{"value": "ph04-runtime", "count": 37}]}}
```

#### API-18-042 · Xuất danh sách đang lọc ra CSV (chỉ siêu dữ liệu, tối đa 50.000 dòng)

::: dac-ta
**Mục đích.** Xuất danh sách đang lọc ra CSV (chỉ siêu dữ liệu, tối đa 50.000 dòng).

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages:export`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-019.

**Tham số.** `sourceCode` (query, array, tùy chọn); `flow` (query, string, tùy chọn); `errorCode` (query, ErrorCode, tùy chọn); `errorClass` (query, ErrorClass, tùy chọn); `status` (query, DlqStatus, tùy chọn); `age` (query, string, tùy chọn); `assignee` (query, string, tùy chọn); `priority` (query, Priority, tùy chọn); `groupId` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CsvFile`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất danh sách đang lọc ra CSV (chỉ siêu dữ liệu, tối đa 50.000 dòng). Quyền PERM-18-dlq; FR-18-019.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages:export
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

dlqId,sourceCode,errorCode,errorClass,status,receivedAt
0190a1b2-c3d4-7e5f-8a6b-3431d1c97214,ph04-runtime,ERR-04-101,TRANSIENT,TRIAGED,2026-11-27T09:15:02+07:00
```

#### API-18-043 · Nhóm mục DLQ theo dấu hiệu lỗi, số mục, tuổi, nguồn

::: dac-ta
**Mục đích.** Nhóm mục DLQ theo dấu hiệu lỗi, số mục, tuổi, nguồn.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/groups`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-020.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `sourceCode` (query, SourceCode, tùy chọn); `errorClass` (query, ErrorClass, tùy chọn); `windowHours` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqGroupPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhóm mục DLQ theo dấu hiệu lỗi, số mục, tuổi, nguồn. Quyền PERM-18-read; FR-18-020.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/groups
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "signature": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "sourceCode": "ph04-runtime", "errorCode": "ERR-04-101", "errorClass": "TRANSIENT",
   "firstSeenAt": "2026-11-27T09:15:02+07:00", "lastSeenAt": "2026-11-27T09:15:02+07:00",
   "openCount": 12, "totalCount": 12}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-044 · Gán người xử lý, ưu tiên cho cả nhóm

::: dac-ta
**Mục đích.** Gán người xử lý, ưu tiên cho cả nhóm.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/groups/{groupId}:assign`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-020, FR-18-023.

**Tham số.** `groupId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GroupAssignInput`; trường bắt buộc: `assignee`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqGroup`; trường bắt buộc: `version`, `id`, `signature`, `sourceCode`, `errorCode`, `errorClass`, `firstSeenAt`, `lastSeenAt`, `openCount`, `totalCount`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gán người xử lý, ưu tiên cho cả nhóm. Quyền PERM-18-dlq; FR-18-020, 023.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/groups/0190a1b2-c3d4-7e5f-8a6b-47db2588331b:assign
Idempotency-Key: dh-2026-11-27-0001

{"assignee": "tran.thi.binh", "priority": "P2", "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "signature": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "sourceCode": "ph04-runtime", "flow": "hs-mot-cua-dong-bo", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "sampleMessage": "Hệ đích trả 503",
 "firstSeenAt": "2026-11-27T09:15:02+07:00", "lastSeenAt": "2026-11-27T09:15:02+07:00",
 "openCount": 12, "totalCount": 12, "assignee": "tran.thi.binh", "priority": "P2"}
```

#### API-18-045 · Chi tiết mục: ngữ cảnh, phân loại, lịch sử trạng thái, bản sửa, lượt phát lại (không payload)

::: dac-ta
**Mục đích.** Chi tiết mục: ngữ cảnh, phân loại, lịch sử trạng thái, bản sửa, lượt phát lại (không payload).

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-021.

**Tham số.** `dlqId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqMessageDetail`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`, `history`, `revisions`, `replays`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết mục: ngữ cảnh, phân loại, lịch sử trạng thái, bản sửa, lượt phát lại (không payload). Quyền PERM-18-read; FR-18-021.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1,
 "contextHeaders": {"dh-flow": "hs-mot-cua-dong-bo", "dh-dlq-stage": "goi-he-dich"},
 "schemaRef": "schema/ho-so-mot-cua/v3", "originTopic": "giá trị mẫu",
 "originPartition": 12, "originOffset": 12, "discardReasonCode": "HANDLED_AT_SOURCE",
 "discardReason": "giá trị mẫu", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "history": [{"action": "INGEST", "actor": "tran.thi.binh", "actorKind": "USER",
   "occurredAt": "2026-11-27T09:15:02+07:00"}],
 "revisions": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
   "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "storage": "INLINE",
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "containsRestricted": false, "status": "APPROVED"}],
 "replays": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revision": 1,
   "idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1", "status": "PENDING"}],
 "guide": {"errCode": "ERR-04-101", "title": "Hệ đích không phản hồi", "replayable": "YES"}}
```

#### API-18-046 · Ngữ cảnh chẩn đoán từ PH-13 (API-13-069), trả một phần khi PH-13 vắng

::: dac-ta
**Mục đích.** Ngữ cảnh chẩn đoán từ PH-13 (API-13-069), trả một phần khi PH-13 vắng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}/diagnostics`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-021.

**Tham số.** `dlqId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqDiagnostics`; trường bắt buộc: `partial`, `window`, `spans`, `logs`, `metrics`; `206`, `DlqDiagnostics`; trường bắt buộc: `partial`, `window`, `spans`, `logs`, `metrics`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gọi API-13-069 của PH-13 trong `18.dlq.diagnostics.timeout-ms` (3.000 ms); PH-13 vắng hoặc chậm thì trả `206` với phần đã có (fail-soft).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/diagnostics
```

```http
HTTP/1.1 200 OK

{"traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "partial": false,
 "unavailableReason": "PH-13 quá thời gian", "window": "PT5M",
 "spans": [{"service": "dh-runtime", "operation": "POST /ho-so",
   "startedAt": "2026-11-27T02:00:00+07:00", "durationMs": 12, "status": "OK"}],
 "logs": [{"at": "2026-11-27T09:15:02+07:00", "level": "ERROR", "service": "dh-runtime",
   "message": "Gọi hệ đích quá thời gian 30 giây"}],
 "metrics": [{"name": "dh_ops_dlq_depth", "value": 37, "at": "2026-11-27T09:15:02+07:00"}]}
```

#### API-18-047 · Mở xem payload có lý do, trả phiếu xem 15 phút và nội dung đã che trường mã hóa

::: dac-ta
**Mục đích.** Mở xem payload có lý do, trả phiếu xem 15 phút và nội dung đã che trường mã hóa.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}/payload:reveal`.

**Quyền.** `PERM-18-dlq-payload`.

**FR hiện thực.** FR-18-022.

**Tham số.** `dlqId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PayloadRevealInput`; trường bắt buộc: `reason`, `purpose`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PayloadReveal`; trường bắt buộc: `dlqId`, `revision`, `contentType`, `maskedFields`, `revealExpiresAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-027, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần `PERM-18-dlq-payload` và lý do ≥ 10 ký tự; trả nội dung trong phiếu xem 15 phút, trường đã mã hóa vẫn che; ghi kiểm toán PH-13 trước khi trả (ERR-18-008).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/payload:reveal
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "purpose": "DIAGNOSE", "revision": 1}
```

```http
HTTP/1.1 200 OK

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revision": 1,
 "content": {"soHoSo": "HS-2026-000123", "trangThai": "DA_TIEP_NHAN"},
 "contentType": "application/json", "maskedFields": ["$.congDan.soDinhDanh"],
 "revealExpiresAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-048 · Khung cấu trúc payload không có giá trị (tên trường, kiểu)

::: dac-ta
**Mục đích.** Khung cấu trúc payload không có giá trị (tên trường, kiểu).

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}/payload/skeleton`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-022, FR-18-026.

**Tham số.** `dlqId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PayloadSkeleton`; trường bắt buộc: `dlqId`, `contentType`, `fields`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khung cấu trúc payload không có giá trị (tên trường, kiểu). Quyền PERM-18-dlq; FR-18-022, 026.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/payload/skeleton
```

```http
HTTP/1.1 200 OK

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "contentType": "application/json",
 "fields": [{"path": "$.trangThai", "type": "STRING", "encrypted": false}]}
```

#### API-18-049 · Gán lớp lỗi, ưu tiên, ghi chú; `NEW` sang `TRIAGED`

::: dac-ta
**Mục đích.** Gán lớp lỗi, ưu tiên, ghi chú; `NEW` sang `TRIAGED`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}:triage`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-023.

**Tham số.** `dlqId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TriageInput`; trường bắt buộc: `errorClass`, `priority`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqMessage`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gán lớp lỗi, ưu tiên, ghi chú; `NEW` sang `TRIAGED`. Quyền PERM-18-dlq; FR-18-023.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:triage
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"errorClass": "TRANSIENT", "priority": "P2", "assignee": "tran.thi.binh",
 "note": "Đã liên hệ chủ quản HTTT", "notifyOwner": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1}
```

#### API-18-050 · Gán hoặc nhận người xử lý

::: dac-ta
**Mục đích.** Gán hoặc nhận người xử lý.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}:assign`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-023.

**Tham số.** `dlqId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AssignInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqMessage`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gán hoặc nhận người xử lý. Quyền PERM-18-dlq; FR-18-023.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:assign
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"assignee": "tran.thi.binh", "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1}
```

#### API-18-051 · Phân loại, gán hàng loạt theo danh sách tới 1.000 mục

::: dac-ta
**Mục đích.** Phân loại, gán hàng loạt theo danh sách tới 1.000 mục.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages:bulk-triage`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-023.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BulkTriageInput`; trường bắt buộc: `dlqIds`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `207`, `BulkResult`; trường bắt buộc: `requested`, `succeeded`, `failed`, `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân loại, gán hàng loạt theo danh sách tới 1.000 mục. Quyền PERM-18-dlq; FR-18-023.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages:bulk-triage
Idempotency-Key: dh-2026-11-27-0001

{"dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "errorClass": "TRANSIENT",
 "priority": "P2", "assignee": "tran.thi.binh", "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 207

{"requested": 12, "succeeded": 1180, "failed": 12,
 "results": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "httpStatus": 201}]}
```

#### API-18-052 · Danh sách bản sửa payload và trạng thái duyệt

::: dac-ta
**Mục đích.** Danh sách bản sửa payload và trạng thái duyệt.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}/revisions`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-024.

**Tham số.** `dlqId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, RevisionStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqRevisionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách bản sửa payload và trạng thái duyệt. Quyền PERM-18-dlq; FR-18-024.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
   "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "storage": "INLINE",
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "containsRestricted": false, "status": "APPROVED"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-053 · Tạo bản sửa payload (nội dung mới, lý do), kiểm lược đồ

::: dac-ta
**Mục đích.** Tạo bản sửa payload (nội dung mới, lý do), kiểm lược đồ.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}/revisions`.

**Quyền.** `PERM-18-dlq-payload`.

**FR hiện thực.** FR-18-024.

**Tham số.** `dlqId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevisionInput`; trường bắt buộc: `content`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `DlqRevision`; trường bắt buộc: `version`, `id`, `dlqId`, `revisionNo`, `payloadSha256`, `storage`, `reason`, `containsRestricted`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-029, ERR-18-030, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo bản sửa, không sửa bản gốc (ADR-181). Bản sửa có trường mức Hạn chế hoặc Nhạy cảm chờ duyệt bốn mắt (API-18-055); bản sửa thường `APPROVED` ngay.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions
Idempotency-Key: dh-2026-11-27-0001

{"content": {"soHoSo": "HS-2026-000123", "trangThai": "DA_TIEP_NHAN"},
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "schemaRef": "schema/ho-so-mot-cua/v3"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
 "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "storage": "INLINE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "schemaRef": "schema/ho-so-mot-cua/v3", "containsRestricted": false, "status": "APPROVED",
 "diff": [{"path": "$.trangThai", "op": "ADD"}], "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-054 · Khác biệt giữa bản gốc và bản sửa, trường nhạy cảm che

::: dac-ta
**Mục đích.** Khác biệt giữa bản gốc và bản sửa, trường nhạy cảm che.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}/revisions/{revisionNo}/diff`.

**Quyền.** `PERM-18-dlq-payload`.

**FR hiện thực.** FR-18-024.

**Tham số.** `dlqId` (path, string, bắt buộc); `revisionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevisionDiff`; trường bắt buộc: `dlqId`, `revisionNo`, `diff`, `maskedPaths`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khác biệt giữa bản gốc và bản sửa, trường nhạy cảm che. Quyền PERM-18-dlq-payload; FR-18-024.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions/1/diff
```

```http
HTTP/1.1 200 OK

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
 "diff": [{"path": "$.trangThai", "op": "ADD"}], "maskedPaths": ["$.congDan.soDinhDanh"]}
```

#### API-18-055 · Duyệt bản sửa có dữ liệu Hạn chế (người thứ hai)

::: dac-ta
**Mục đích.** Duyệt bản sửa có dữ liệu Hạn chế (người thứ hai).

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}/revisions/{revisionNo}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-024.

**Tham số.** `dlqId` (path, string, bắt buộc); `revisionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqRevision`; trường bắt buộc: `version`, `id`, `dlqId`, `revisionNo`, `payloadSha256`, `storage`, `reason`, `containsRestricted`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bản sửa có dữ liệu Hạn chế (người thứ hai). Quyền PERM-18-approve; FR-18-024.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions/1:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
 "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "storage": "INLINE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "schemaRef": "schema/ho-so-mot-cua/v3", "containsRestricted": false, "status": "APPROVED",
 "diff": [{"path": "$.trangThai", "op": "ADD"}], "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-056 · Từ chối bản sửa kèm lý do

::: dac-ta
**Mục đích.** Từ chối bản sửa kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}/revisions/{revisionNo}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-024.

**Tham số.** `dlqId` (path, string, bắt buộc); `revisionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqRevision`; trường bắt buộc: `version`, `id`, `dlqId`, `revisionNo`, `payloadSha256`, `storage`, `reason`, `containsRestricted`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối bản sửa kèm lý do. Quyền PERM-18-approve; FR-18-024.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/revisions/1:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
 "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "storage": "INLINE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "schemaRef": "schema/ho-so-mot-cua/v3", "containsRestricted": false, "status": "APPROVED",
 "diff": [{"path": "$.trangThai", "op": "ADD"}], "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-057 · Sổ tay xử lý theo mã lỗi: tìm theo mã, PH, lớp lỗi

::: dac-ta
**Mục đích.** Sổ tay xử lý theo mã lỗi: tìm theo mã, PH, lớp lỗi.

**Phương thức, đường dẫn.** `GET /api/ops/v1/error-guides`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-025.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `q` (query, string, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn); `errorClass` (query, ErrorClass, tùy chọn); `replayable` (query, Replayable, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ErrorGuidePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sổ tay xử lý theo mã lỗi: tìm theo mã, PH, lớp lỗi. Quyền PERM-18-read; FR-18-025.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/error-guides
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "errCode": "ERR-04-101",
   "ownerPh": "PH-04", "locale": "vi", "title": "Hệ đích không phản hồi",
   "causes": ["Hệ đích quá tải hoặc đang bảo trì"],
   "steps": ["Kiểm tra trạng thái hệ đích", "Phát lại khi hệ đích phục hồi"],
   "replayable": "YES", "status": "DRAFT"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-058 · Hướng dẫn của một mã lỗi: nguyên nhân, bước xử lý, có phát lại được không

::: dac-ta
**Mục đích.** Hướng dẫn của một mã lỗi: nguyên nhân, bước xử lý, có phát lại được không.

**Phương thức, đường dẫn.** `GET /api/ops/v1/error-guides/{errCode}`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-025, FR-18-021.

**Tham số.** `errCode` (path, ErrorCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ErrorGuide`; trường bắt buộc: `version`, `id`, `errCode`, `ownerPh`, `locale`, `title`, `causes`, `steps`, `replayable`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hướng dẫn của một mã lỗi: nguyên nhân, bước xử lý, có phát lại được không. Quyền PERM-18-read; FR-18-025, 021.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/error-guides/ERR-04-101
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "errCode": "ERR-04-101", "ownerPh": "PH-04", "locale": "vi",
 "title": "Hệ đích không phản hồi", "causes": ["Hệ đích quá tải hoặc đang bảo trì"],
 "steps": ["Kiểm tra trạng thái hệ đích", "Phát lại khi hệ đích phục hồi"],
 "replayable": "YES", "defaultClass": "TRANSIENT",
 "links": ["/van-hanh/dlq?ma-loi=ERR-04-101"], "status": "DRAFT",
 "publishedAt": "2026-11-27T09:15:02+07:00", "publishedBy": "le.thi.chi"}
```

#### API-18-059 · Soạn, sửa hướng dẫn của một mã (`If-Match`), phát EVT-18-11

::: dac-ta
**Mục đích.** Soạn, sửa hướng dẫn của một mã (`If-Match`), phát EVT-18-11.

**Phương thức, đường dẫn.** `PUT /api/ops/v1/error-guides/{errCode}`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-025.

**Tham số.** `errCode` (path, ErrorCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ErrorGuideInput`; trường bắt buộc: `title`, `causes`, `steps`, `replayable`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ErrorGuide`; trường bắt buộc: `version`, `id`, `errCode`, `ownerPh`, `locale`, `title`, `causes`, `steps`, `replayable`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Soạn, sửa hướng dẫn của một mã (`If-Match`), phát EVT-18-11. Quyền PERM-18-admin; FR-18-025.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/error-guides/ERR-04-101
If-Match: W/"3"

{"title": "Hệ đích không phản hồi", "causes": ["Hệ đích quá tải hoặc đang bảo trì"],
 "steps": ["Kiểm tra trạng thái hệ đích", "Phát lại khi hệ đích phục hồi"],
 "replayable": "YES", "defaultClass": "TRANSIENT",
 "links": ["/van-hanh/dlq?ma-loi=ERR-04-101"], "locale": "vi", "status": "DRAFT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "errCode": "ERR-04-101", "ownerPh": "PH-04", "locale": "vi",
 "title": "Hệ đích không phản hồi", "causes": ["Hệ đích quá tải hoặc đang bảo trì"],
 "steps": ["Kiểm tra trạng thái hệ đích", "Phát lại khi hệ đích phục hồi"],
 "replayable": "YES", "defaultClass": "TRANSIENT",
 "links": ["/van-hanh/dlq?ma-loi=ERR-04-101"], "status": "DRAFT",
 "publishedAt": "2026-11-27T09:15:02+07:00", "publishedBy": "le.thi.chi"}
```

#### API-18-060 · PH-17, PH-13 đọc danh sách siêu dữ liệu DLQ bằng token đổi từ người dùng

::: dac-ta
**Mục đích.** PH-17, PH-13 đọc danh sách siêu dữ liệu DLQ bằng token đổi từ người dùng.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/dlq/messages`.

**Quyền.** scope ops:dlq-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-026.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `sourceCode` (query, array, tùy chọn); `flow` (query, string, tùy chọn); `errorCode` (query, ErrorCode, tùy chọn); `errorClass` (query, ErrorClass, tùy chọn); `status` (query, DlqStatus, tùy chọn); `age` (query, string, tùy chọn); `assignee` (query, string, tùy chọn); `priority` (query, Priority, tùy chọn); `groupId` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqMessagePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-17, PH-13 đọc danh sách siêu dữ liệu DLQ bằng token đổi từ người dùng. Quyền scope ops:dlq-read; mTLS SPIFFE; FR-18-026.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/dlq/messages
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
   "sourcePh": "PH-04", "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE",
   "errorCode": "ERR-04-101", "errorClass": "TRANSIENT", "attempts": 3, "occurrences": 4,
   "status": "TRIAGED", "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
   "storage": "INLINE", "currentRevisionNo": 1}], "page": 0, "size": 20,
 "totalElements": 1, "facets": {"bySource": [{"value": "ph04-runtime", "count": 37}],
  "byErrorClass": [{"value": "ph04-runtime", "count": 37}],
  "byStatus": [{"value": "ph04-runtime", "count": 37}],
  "byErrorCode": [{"value": "ph04-runtime", "count": 37}]}}
```

#### API-18-061 · PH-17 đọc siêu dữ liệu một mục; payload chỉ khi người dùng có `PERM-18-dlq-payload`

::: dac-ta
**Mục đích.** PH-17 đọc siêu dữ liệu một mục; payload chỉ khi người dùng có `PERM-18-dlq-payload`.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/dlq/messages/{dlqId}`.

**Quyền.** scope ops:dlq-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-026.

**Tham số.** `dlqId` (path, string, bắt buộc); `includePayload` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqMessageDetail`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`, `history`, `revisions`, `replays`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-17 đọc siêu dữ liệu một mục; payload chỉ khi người dùng có `PERM-18-dlq-payload`. Quyền scope ops:dlq-read; mTLS SPIFFE; FR-18-026.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1,
 "contextHeaders": {"dh-flow": "hs-mot-cua-dong-bo", "dh-dlq-stage": "goi-he-dich"},
 "schemaRef": "schema/ho-so-mot-cua/v3", "originTopic": "giá trị mẫu",
 "originPartition": 12, "originOffset": 12, "discardReasonCode": "HANDLED_AT_SOURCE",
 "discardReason": "giá trị mẫu", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "history": [{"action": "INGEST", "actor": "tran.thi.binh", "actorKind": "USER",
   "occurredAt": "2026-11-27T09:15:02+07:00"}],
 "revisions": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revisionNo": 1,
   "payloadSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "storage": "INLINE",
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "containsRestricted": false, "status": "APPROVED"}],
 "replays": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revision": 1,
   "idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1", "status": "PENDING"}],
 "guide": {"errCode": "ERR-04-101", "title": "Hệ đích không phản hồi", "replayable": "YES"}}
```

#### API-18-062 · Nguồn tri thức sổ tay ERR cho PH-17 lập chỉ mục, theo `updatedSince`

::: dac-ta
**Mục đích.** Nguồn tri thức sổ tay ERR cho PH-17 lập chỉ mục, theo `updatedSince`.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/error-guides:feed`.

**Quyền.** scope ops:dlq-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-025, FR-18-026.

**Tham số.** `updatedSince` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ErrorGuideFeed`; trường bắt buộc: `items`, `nextUpdatedSince`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn tri thức sổ tay ERR cho PH-17 lập chỉ mục, theo `updatedSince`. Quyền scope ops:dlq-read; mTLS SPIFFE; FR-18-025, 026.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/error-guides:feed?updatedSince=2026-11-20T00:00:00+07:00
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "errCode": "ERR-04-101",
   "ownerPh": "PH-04", "locale": "vi", "title": "Hệ đích không phản hồi",
   "causes": ["Hệ đích quá tải hoặc đang bảo trì"],
   "steps": ["Kiểm tra trạng thái hệ đích", "Phát lại khi hệ đích phục hồi"],
   "replayable": "YES", "status": "DRAFT"}], "nextUpdatedSince": "2026-11-27T09:15:02+07:00"}
```

#### API-18-063 · Nhật ký thao tác trên một mục DLQ

::: dac-ta
**Mục đích.** Nhật ký thao tác trên một mục DLQ.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/messages/{dlqId}/audit`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-023, FR-18-070.

**Tham số.** `dlqId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `action` (query, DlqAuditAction, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqAuditEntryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký thao tác trên một mục DLQ. Quyền PERM-18-dlq; FR-18-023, 070.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/audit
```

```http
HTTP/1.1 200 OK

{"items": [{"action": "INGEST", "actor": "tran.thi.binh", "actorKind": "USER",
   "occurredAt": "2026-11-27T09:15:02+07:00"}], "page": 0, "size": 20, "totalElements": 1}
```

### 14.4. Phát lại, bỏ qua và lưu giữ

Phát lại một mục, lượt phát lại loạt có bốn mắt, điều khiển tốc độ, kết quả lũy đẳng, bỏ qua, mở lại, lưu giữ, thống kê (FR-18-027…034). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-064 · Phát lại một mục (bản gốc hoặc bản sửa đã duyệt)

::: dac-ta
**Mục đích.** Phát lại một mục (bản gốc hoặc bản sửa đã duyệt).

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}:replay`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-027, FR-18-030.

**Tham số.** `dlqId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReplayInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReplayAccepted`; trường bắt buộc: `dlqId`, `status`, `idempotencyKey`, `revision`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-027, ERR-18-028, ERR-18-031, ERR-18-033, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát lại qua lối vào của nguồn (ADR-182), khóa lũy đẳng `dlqId:revision`; mục `POISON` trả ERR-18-028, mục đang trong lượt khác ERR-18-031, nguồn không có cổng ERR-18-033.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:replay
Idempotency-Key: dh-2026-11-27-0001

{"revision": 1, "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 202 Accepted

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "status": "TRIAGED",
 "idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1", "revision": 1}
```

#### API-18-065 · Tạo lượt phát lại loạt theo bộ lọc hoặc danh sách (`DRAFT`)

::: dac-ta
**Mục đích.** Tạo lượt phát lại loạt theo bộ lọc hoặc danh sách (`DRAFT`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-028.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReplayJobInput`; trường bắt buộc: `useRevision`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-032, ERR-18-036, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lượt `DRAFT` theo bộ lọc hoặc danh sách (≤ `18.dlq.replay.batch-max`); trả `excluded[]` cho mục không phát lại được. Gửi bằng API-18-069.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs
Idempotency-Key: dh-2026-11-27-0001

{"filter": {"sourceCode": ["ph04-runtime"], "errorCode": ["ERR-04-101"],
  "status": ["TRIAGED", "REPLAY_FAILED"]}, "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10,
 "reason": "Hệ đích đã phục hồi lúc 08:30, phát lại tồn đọng theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-066 · Danh sách lượt phát lại, tiến độ, trạng thái

::: dac-ta
**Mục đích.** Danh sách lượt phát lại, tiến độ, trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/replay-jobs`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-028, FR-18-029.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, ReplayJobStatus, tùy chọn); `requestedBy` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplayJobPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách lượt phát lại, tiến độ, trạng thái. Quyền PERM-18-dlq; FR-18-028, 029.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/replay-jobs
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "jobCode": "RJ-2026-0031",
   "mode": "BATCH_FILTER", "useRevision": "LATEST_APPROVED", "ratePerSecond": 10,
   "stopOnFailurePercent": 20,
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "total": 1240, "succeeded": 1180, "failed": 12, "skipped": 48, "approvalRequired": true,
   "status": "APPROVED", "requestedBy": "nguyen.van.an"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-067 · Chi tiết lượt: tổng, thành công, thất bại, tốc độ, người duyệt

::: dac-ta
**Mục đích.** Chi tiết lượt: tổng, thành công, thất bại, tốc độ, người duyệt.

**Phương thức, đường dẫn.** `GET /api/ops/v1/replay-jobs/{jobId}`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-028, FR-18-029, FR-18-030.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết lượt: tổng, thành công, thất bại, tốc độ, người duyệt. Quyền PERM-18-dlq; FR-18-028, 029, 030.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-068 · Kết quả từng mục trong lượt

::: dac-ta
**Mục đích.** Kết quả từng mục trong lượt.

**Phương thức, đường dẫn.** `GET /api/ops/v1/replay-jobs/{jobId}/items`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-028, FR-18-030.

**Tham số.** `jobId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, ReplayItemStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplayItemPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả từng mục trong lượt. Quyền PERM-18-dlq; FR-18-028, 030.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee/items
```

```http
HTTP/1.1 200 OK

{"items": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revision": 1,
   "idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1", "status": "PENDING"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-069 · Gửi lượt; dưới ngưỡng chạy ngay, trên ngưỡng chuyển chờ duyệt

::: dac-ta
**Mục đích.** Gửi lượt; dưới ngưỡng chạy ngay, trên ngưỡng chuyển chờ duyệt.

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:submit`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-028.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-032, ERR-18-036, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Số mục ≤ `18.dlq.replay.approval-threshold` (500) thì `APPROVED` và chạy ngay; lớn hơn thì `PENDING_APPROVAL`, tạo việc duyệt trong Việc của tôi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:submit
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-070 · Duyệt lượt loạt lớn (người thứ hai)

::: dac-ta
**Mục đích.** Duyệt lượt loạt lớn (người thứ hai).

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-028.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt lượt loạt lớn (người thứ hai). Quyền PERM-18-approve; FR-18-028.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-071 · Từ chối lượt kèm lý do

::: dac-ta
**Mục đích.** Từ chối lượt kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-028.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối lượt kèm lý do. Quyền PERM-18-approve; FR-18-028.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-072 · Tạm dừng lượt đang chạy

::: dac-ta
**Mục đích.** Tạm dừng lượt đang chạy.

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:pause`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-029.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạm dừng lượt đang chạy. Quyền PERM-18-dlq; FR-18-029.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:pause
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-073 · Tiếp tục lượt đã tạm dừng

::: dac-ta
**Mục đích.** Tiếp tục lượt đã tạm dừng.

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:resume`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-029.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiếp tục lượt đã tạm dừng. Quyền PERM-18-dlq; FR-18-029.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:resume
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-074 · Hủy lượt, mục chưa chạy trở về `TRIAGED`

::: dac-ta
**Mục đích.** Hủy lượt, mục chưa chạy trở về `TRIAGED`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/replay-jobs/{jobId}:cancel`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-029.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy lượt, mục chưa chạy trở về `TRIAGED`. Quyền PERM-18-dlq; FR-18-029.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee:cancel
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-075 · Đổi tốc độ phát lại của lượt (`If-Match`)

::: dac-ta
**Mục đích.** Đổi tốc độ phát lại của lượt (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/replay-jobs/{jobId}`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-029.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReplayJobPatch`; trường bắt buộc: `ratePerSecond`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplayJob`; trường bắt buộc: `version`, `id`, `jobCode`, `mode`, `useRevision`, `ratePerSecond`, `stopOnFailurePercent`, `reason`, `total`, `succeeded`, `failed`, `skipped`, `approvalRequired`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-037, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đổi tốc độ phát lại của lượt (`If-Match`). Quyền PERM-18-dlq; FR-18-029.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/replay-jobs/0190a1b2-c3d4-7e5f-8a6b-7143244908ee
If-Match: W/"3"

{"ratePerSecond": 10}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "jobCode": "RJ-2026-0031", "mode": "BATCH_FILTER", "filter": {},
 "dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "useRevision": "LATEST_APPROVED",
 "ratePerSecond": 10, "stopOnFailurePercent": 20,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "total": 1240,
 "succeeded": 1180, "failed": 12, "skipped": 48,
 "excluded": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "reasonCode": "POISON"}],
 "approvalRequired": true, "status": "APPROVED", "requestedBy": "nguyen.van.an",
 "approvedBy": "le.thi.chi", "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "pausedAt": "2026-11-27T09:15:02+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-076 · Nguồn báo kết quả phát lại theo khóa lũy đẳng `dlqId:revision`

::: dac-ta
**Mục đích.** Nguồn báo kết quả phát lại theo khóa lũy đẳng `dlqId:revision`.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/replay-results`.

**Quyền.** scope ops:replay-callback; mTLS SPIFFE.

**FR hiện thực.** FR-18-030.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ReplayResultInput`; trường bắt buộc: `idempotencyKey`, `result`, `processedAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReplayResultAck`; trường bắt buộc: `dlqId`, `status`, `duplicate`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn báo kết quả theo `idempotencyKey`; lặp lại cùng khóa trả `duplicate = true`, không đổi trạng thái lần hai. Danh tính gọi phải khớp nguồn của mục (ERR-18-038).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/replay-results

{"idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1", "result": "SUCCEEDED",
 "errorCode": "ERR-04-101", "message": "Đã xử lý",
 "processedAt": "2026-11-27T09:15:02+07:00"}
```

```http
HTTP/1.1 200 OK

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "status": "TRIAGED", "duplicate": false}
```

#### API-18-077 · Bỏ qua một mục kèm lý do ≥ 10 ký tự

::: dac-ta
**Mục đích.** Bỏ qua một mục kèm lý do ≥ 10 ký tự.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}:discard`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-031.

**Tham số.** `dlqId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DiscardInput`; trường bắt buộc: `reasonCode`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqMessage`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bỏ qua một mục kèm lý do ≥ 10 ký tự. Quyền PERM-18-dlq; FR-18-031.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:discard
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reasonCode": "HANDLED_AT_SOURCE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1}
```

#### API-18-078 · Bỏ qua hàng loạt tới 1.000 mục kèm một lý do chung

::: dac-ta
**Mục đích.** Bỏ qua hàng loạt tới 1.000 mục kèm một lý do chung.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages:bulk-discard`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-031.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BulkDiscardInput`; trường bắt buộc: `dlqIds`, `reasonCode`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `207`, `BulkResult`; trường bắt buộc: `requested`, `succeeded`, `failed`, `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bỏ qua hàng loạt tới 1.000 mục kèm một lý do chung. Quyền PERM-18-dlq; FR-18-031.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages:bulk-discard
Idempotency-Key: dh-2026-11-27-0001

{"dlqIds": ["0190a1b2-c3d4-7e5f-8a6b-43dff69ecc2d"], "reasonCode": "HANDLED_AT_SOURCE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 207

{"requested": 12, "succeeded": 1180, "failed": 12,
 "results": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "httpStatus": 201}]}
```

#### API-18-079 · Mở lại mục đã bỏ qua trong hạn lưu giữ

::: dac-ta
**Mục đích.** Mở lại mục đã bỏ qua trong hạn lưu giữ.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dlq/messages/{dlqId}:reopen`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-032.

**Tham số.** `dlqId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DlqMessage`; trường bắt buộc: `version`, `id`, `dlqKey`, `sourceCode`, `sourcePh`, `stage`, `reason`, `errorCode`, `errorClass`, `attempts`, `occurrences`, `status`, `receivedAt`, `ageMinutes`, `storage`, `currentRevisionNo`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-034, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mở lại mục đã bỏ qua trong hạn lưu giữ. Quyền PERM-18-dlq; FR-18-032.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dlq/messages/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:reopen
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "dlqKey": "ph04-runtime:hs-mot-cua-dong-bo:msg-0123", "sourceCode": "ph04-runtime",
 "sourcePh": "PH-04", "flow": "hs-mot-cua-dong-bo", "flowVersion": "3",
 "stage": "goi-he-dich", "reason": "TARGET_UNAVAILABLE", "errorCode": "ERR-04-101",
 "errorClass": "TRANSIENT", "errorMessage": "Hệ đích trả 503 sau 3 lần thử", "attempts": 3,
 "occurrences": 4, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "messageId": "msg-2026-000123", "status": "TRIAGED", "priority": "P2",
 "groupId": "0190a1b2-c3d4-7e5f-8a6b-47db2588331b", "assignee": "tran.thi.binh",
 "missingFields": ["dh-flow"], "firstFailedAt": "2026-11-27T09:15:02+07:00",
 "receivedAt": "2026-11-27T09:15:02+07:00", "ageMinutes": 95,
 "retentionUntil": "2026-11-27T09:15:02+07:00", "storage": "INLINE",
 "payloadSizeBytes": 12, "contentType": "application/json", "currentRevisionNo": 1}
```

#### API-18-080 · Số mục sắp hết hạn, lần dọn gần nhất, dung lượng Garage của DLQ

::: dac-ta
**Mục đích.** Số mục sắp hết hạn, lần dọn gần nhất, dung lượng Garage của DLQ.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/retention`.

**Quyền.** `PERM-18-dlq`.

**FR hiện thực.** FR-18-033.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqRetention`; trường bắt buộc: `expiring7Days`, `expiring30Days`, `garageBytes`, `garageObjects`, `closedRetentionDays`, `openMaxDays`.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Số mục sắp hết hạn, lần dọn gần nhất, dung lượng Garage của DLQ. Quyền PERM-18-dlq; FR-18-033.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/retention
```

```http
HTTP/1.1 200 OK

{"expiring7Days": 12, "expiring30Days": 12, "lastPurgeAt": "2026-11-27T09:15:02+07:00",
 "lastPurgeCount": 12, "garageBytes": 12, "garageObjects": 12, "closedRetentionDays": 12,
 "openMaxDays": 12}
```

#### API-18-081 · Thống kê DLQ theo nguồn, luồng, lớp lỗi, trạng thái, tuổi, xu hướng theo `khoang`

::: dac-ta
**Mục đích.** Thống kê DLQ theo nguồn, luồng, lớp lỗi, trạng thái, tuổi, xu hướng theo `khoang`.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dlq/stats`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-034, FR-18-071.

**Tham số.** `interval` (query, string, tùy chọn); `sourceCode` (query, SourceCode, tùy chọn); `groupBy` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DlqStats`; trường bắt buộc: `interval`, `from`, `to`, `totals`, `groups`, `trend`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thống kê DLQ theo nguồn, luồng, lớp lỗi, trạng thái, tuổi, xu hướng theo `khoang`. Quyền PERM-18-read; FR-18-034, 071.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dlq/stats
```

```http
HTTP/1.1 200 OK

{"interval": "24h", "from": "2026-11-26T00:00:00+07:00", "to": "2026-11-27T00:00:00+07:00",
 "totals": {"open": 12, "newCount": 12, "poison": 12, "replayFailed": 12, "resolved": 12,
  "discarded": 12}, "groups": [{"value": "ph04-runtime", "count": 37}],
 "trend": [{"at": "2026-11-27T09:15:02+07:00", "received": 12, "resolved": 12, "discarded": 12}]}
```

#### API-18-188 · Nguồn có cổng `KAFKA_TOPIC` lấy nội dung cần phát lại theo `payloadRef` của EVT-18-09 (bản gốc khi `revision = 0`)

::: dac-ta
**Mục đích.** Nguồn có cổng `KAFKA_TOPIC` lấy nội dung cần phát lại theo `payloadRef` của EVT-18-09 (bản gốc khi `revision = 0`).

**Phương thức, đường dẫn.** `GET /ops/internal/v1/replay-payloads/{dlqId}/{revision}`.

**Quyền.** scope ops:replay-callback; mTLS SPIFFE.

**FR hiện thực.** FR-18-027, FR-18-028.

**Tham số.** `dlqId` (path, string, bắt buộc); `revision` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplayPayload`; trường bắt buộc: `dlqId`, `revision`, `idempotencyKey`, `contentType`, `sizeBytes`, `sha256`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010, ERR-18-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nguồn có cổng `KAFKA_TOPIC` lấy nội dung cần phát lại theo `payloadRef` của EVT-18-09: `revision = 0` là bản gốc, lớn hơn là bản sửa đã duyệt. Danh tính gọi phải khớp nguồn của mục (ERR-18-038); payload lớn trả `downloadUrl` Garage có hạn thay cho `payload`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/replay-payloads/0190a1b2-c3d4-7e5f-8a6b-3431d1c97214/1
```

```http
HTTP/1.1 200 OK

{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "revision": 1,
 "idempotencyKey": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214:1",
 "contentType": "application/json", "sizeBytes": 12,
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "payload": {"soHoSo": "HS-2026-000123", "trangThai": "DA_TIEP_NHAN"},
 "downloadUrl": "https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11",
 "expiresAt": "2026-11-27T09:15:02+07:00"}
```

### 14.5. Thông báo

Mẫu thông báo có phiên bản và kiểm trường cấm, `NotificationApi` bất đồng bộ và đồng bộ, người nhận, tùy chọn nhận, quy tắc theo sự kiện, nhật ký gửi, thư trả lại, danh sách chặn (FR-18-035…041). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-082 · Danh sách mẫu thông báo theo kênh, PH, trạng thái

::: dac-ta
**Mục đích.** Danh sách mẫu thông báo theo kênh, PH, trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/notification-templates`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `channel` (query, Channel, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn); `status` (query, string, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationTemplatePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách mẫu thông báo theo kênh, PH, trạng thái. Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/notification-templates
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "templateCode": "ph01.ho-so.da-duyet", "channel": "EMAIL", "ownerPh": "PH-04",
   "title": "Hồ sơ kết nạp đã được duyệt", "category": "TASK", "mandatory": true,
   "urgent": false, "variables": [{"name": "maHoSo", "classification": "INTERNAL"}],
   "status": "ACTIVE"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-083 · Tạo mẫu mới (mã, kênh, PH chủ, biến khai báo)

::: dac-ta
**Mục đích.** Tạo mẫu mới (mã, kênh, PH chủ, biến khai báo).

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateInput`; trường bắt buộc: `templateCode`, `channel`, `ownerPh`, `title`, `category`, `variables`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `NotificationTemplate`; trường bắt buộc: `version`, `id`, `templateCode`, `channel`, `ownerPh`, `title`, `category`, `mandatory`, `urgent`, `variables`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo mẫu mới (mã, kênh, PH chủ, biến khai báo). Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates
Idempotency-Key: dh-2026-11-27-0001

{"templateCode": "ph01.ho-so.da-duyet", "channel": "EMAIL", "ownerPh": "PH-04",
 "title": "Hồ sơ kết nạp đã được duyệt", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "category": "TASK", "mandatory": true, "urgent": false,
 "variables": [{"name": "maHoSo", "classification": "INTERNAL"}]}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/notification-templates/ph01.ho-so.da-duyet
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "channel": "EMAIL", "ownerPh": "PH-04",
 "title": "Hồ sơ kết nạp đã được duyệt", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "category": "TASK", "mandatory": true, "urgent": false,
 "variables": [{"name": "maHoSo", "classification": "INTERNAL"}], "status": "ACTIVE",
 "activeVersionNo": 2, "retiredAt": "2026-11-27T09:15:02+07:00",
 "versions": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
   "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
   "status": "DRAFT"}]}
```

#### API-18-084 · Chi tiết mẫu và các phiên bản

::: dac-ta
**Mục đích.** Chi tiết mẫu và các phiên bản.

**Phương thức, đường dẫn.** `GET /api/ops/v1/notification-templates/{templateCode}`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationTemplate`; trường bắt buộc: `version`, `id`, `templateCode`, `channel`, `ownerPh`, `title`, `category`, `mandatory`, `urgent`, `variables`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết mẫu và các phiên bản. Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/notification-templates/ph01.ho-so.da-duyet
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "channel": "EMAIL", "ownerPh": "PH-04",
 "title": "Hồ sơ kết nạp đã được duyệt", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "category": "TASK", "mandatory": true, "urgent": false,
 "variables": [{"name": "maHoSo", "classification": "INTERNAL"}], "status": "ACTIVE",
 "activeVersionNo": 2, "retiredAt": "2026-11-27T09:15:02+07:00",
 "versions": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
   "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
   "status": "DRAFT"}]}
```

#### API-18-085 · Tạo phiên bản nháp nội dung mẫu

::: dac-ta
**Mục đích.** Tạo phiên bản nháp nội dung mẫu.

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}/versions`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateVersionInput`; trường bắt buộc: `locale`, `body`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TemplateVersion`; trường bắt buộc: `version`, `id`, `templateCode`, `versionNo`, `locale`, `body`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-039, ERR-18-040, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo phiên bản nháp nội dung mẫu. Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions
Idempotency-Key: dh-2026-11-27-0001

{"locale": "vi", "subject": "Hồ sơ {{maHoSo}} đã được duyệt",
 "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}."}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions/2
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
 "subject": "Hồ sơ {{maHoSo}} đã được duyệt",
 "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
 "status": "DRAFT",
 "fieldCheck": {"passed": true, "violations": [{"variable": "soDinhDanh", "classification": "INTERNAL"}],
  "syntaxErrors": [{"line": 4, "message": "Thẻ chưa đóng"}]},
 "submittedAt": "2026-11-27T09:15:02+07:00", "reviewedBy": "le.thi.chi",
 "reviewedAt": "2026-11-27T09:15:02+07:00", "activatedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-086 · Dựng thử với dữ liệu mẫu, chạy kiểm trường cấm

::: dac-ta
**Mục đích.** Dựng thử với dữ liệu mẫu, chạy kiểm trường cấm.

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}/versions/{versionNo}:preview`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `PreviewInput`; trường bắt buộc: `sampleData`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplatePreview`; trường bắt buộc: `renderedBody`, `fieldCheck`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010, ERR-18-039, ERR-18-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dựng thử với dữ liệu mẫu, chạy kiểm trường cấm. Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions/4:preview

{"sampleData": {"maHoSo": "HS-0042", "lienKet": "/ket-noi/ho-so/HS-0042"}}
```

```http
HTTP/1.1 200 OK

{"renderedSubject": "Hồ sơ HS-0042 đã được duyệt",
 "renderedBody": "Hồ sơ HS-0042 đã được duyệt. Xem chi tiết tại /ket-noi/ho-so/HS-0042.",
 "fieldCheck": {"passed": true, "violations": [{"variable": "soDinhDanh", "classification": "INTERNAL"}],
  "syntaxErrors": [{"line": 4, "message": "Thẻ chưa đóng"}]}}
```

#### API-18-087 · Gửi duyệt phiên bản (`DRAFT` sang `IN_REVIEW`)

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản (`DRAFT` sang `IN_REVIEW`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}/versions/{versionNo}:submit`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `version`, `id`, `templateCode`, `versionNo`, `locale`, `body`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-039, ERR-18-040, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi duyệt phiên bản (`DRAFT` sang `IN_REVIEW`). Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions/4:submit
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
 "subject": "Hồ sơ {{maHoSo}} đã được duyệt",
 "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
 "status": "DRAFT",
 "fieldCheck": {"passed": true, "violations": [{"variable": "soDinhDanh", "classification": "INTERNAL"}],
  "syntaxErrors": [{"line": 4, "message": "Thẻ chưa đóng"}]},
 "submittedAt": "2026-11-27T09:15:02+07:00", "reviewedBy": "le.thi.chi",
 "reviewedAt": "2026-11-27T09:15:02+07:00", "activatedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-088 · Duyệt phiên bản thành `ACTIVE` (người thứ hai)

::: dac-ta
**Mục đích.** Duyệt phiên bản thành `ACTIVE` (người thứ hai).

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}/versions/{versionNo}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `version`, `id`, `templateCode`, `versionNo`, `locale`, `body`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt phiên bản thành `ACTIVE` (người thứ hai). Quyền PERM-18-approve; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions/4:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
 "subject": "Hồ sơ {{maHoSo}} đã được duyệt",
 "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
 "status": "DRAFT",
 "fieldCheck": {"passed": true, "violations": [{"variable": "soDinhDanh", "classification": "INTERNAL"}],
  "syntaxErrors": [{"line": 4, "message": "Thẻ chưa đóng"}]},
 "submittedAt": "2026-11-27T09:15:02+07:00", "reviewedBy": "le.thi.chi",
 "reviewedAt": "2026-11-27T09:15:02+07:00", "activatedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-089 · Trả phiên bản về `DRAFT` kèm lý do

::: dac-ta
**Mục đích.** Trả phiên bản về `DRAFT` kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}/versions/{versionNo}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `version`, `id`, `templateCode`, `versionNo`, `locale`, `body`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả phiên bản về `DRAFT` kèm lý do. Quyền PERM-18-approve; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet/versions/4:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
 "subject": "Hồ sơ {{maHoSo}} đã được duyệt",
 "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
 "status": "DRAFT",
 "fieldCheck": {"passed": true, "violations": [{"variable": "soDinhDanh", "classification": "INTERNAL"}],
  "syntaxErrors": [{"line": 4, "message": "Thẻ chưa đóng"}]},
 "submittedAt": "2026-11-27T09:15:02+07:00", "reviewedBy": "le.thi.chi",
 "reviewedAt": "2026-11-27T09:15:02+07:00", "activatedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng"}
```

#### API-18-090 · Ngừng mẫu (`RETIRED`)

::: dac-ta
**Mục đích.** Ngừng mẫu (`RETIRED`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-templates/{templateCode}:retire`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-035.

**Tham số.** `templateCode` (path, TemplateCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `NotificationTemplate`; trường bắt buộc: `version`, `id`, `templateCode`, `channel`, `ownerPh`, `title`, `category`, `mandatory`, `urgent`, `variables`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngừng mẫu (`RETIRED`). Quyền PERM-18-template; FR-18-035.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-templates/ph01.ho-so.da-duyet:retire
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "templateCode": "ph01.ho-so.da-duyet", "channel": "EMAIL", "ownerPh": "PH-04",
 "title": "Hồ sơ kết nạp đã được duyệt", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "category": "TASK", "mandatory": true, "urgent": false,
 "variables": [{"name": "maHoSo", "classification": "INTERNAL"}], "status": "ACTIVE",
 "activeVersionNo": 2, "retiredAt": "2026-11-27T09:15:02+07:00",
 "versions": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "templateCode": "ph01.ho-so.da-duyet", "versionNo": 4, "locale": "vi",
   "body": "Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.",
   "status": "DRAFT"}]}
```

#### API-18-091 · Gửi thông báo bất đồng bộ (outbox), lũy đẳng theo `Idempotency-Key`

::: dac-ta
**Mục đích.** Gửi thông báo bất đồng bộ (outbox), lũy đẳng theo `Idempotency-Key`.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/notifications`.

**Quyền.** scope ops:notify; mTLS SPIFFE.

**FR hiện thực.** FR-18-036, FR-18-037, FR-18-038.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationInput`; trường bắt buộc: `type`, `recipients`, `variables`, `sourceRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `NotificationAccepted`; trường bắt buộc: `messageId`, `status`, `duplicate`, `recipients`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-039, ERR-18-041, ERR-18-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi bất đồng bộ qua outbox, lũy đẳng theo `Idempotency-Key` và bên gọi; mẫu dùng biến mức Hạn chế hoặc Nhạy cảm bị chặn (ERR-18-039, FR-00-062). Phân hệ gọi không gửi địa chỉ; PH-18 tự phân giải `recipientRef`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/notifications
Idempotency-Key: dh-2026-11-27-0001

{"type": "ph01.ho-so.da-duyet",
 "recipients": [{"kind": "SYSTEM_CONTACT", "ref": "HTTT-QLVB:CHU_QUAN"}],
 "variables": {"maHoSo": "HS-0042", "lienKet": "/ket-noi/ho-so/HS-0042"},
 "priority": "NORMAL", "sourceRef": "onboarding:HS-0042"}
```

```http
HTTP/1.1 202 Accepted

{"messageId": "0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424", "status": "QUEUED",
 "duplicate": false, "recipients": 2}
```

#### API-18-092 · Gửi thư mang liên kết ở chế độ đồng bộ, chờ máy chủ thư nhận

::: dac-ta
**Mục đích.** Gửi thư mang liên kết ở chế độ đồng bộ, chờ máy chủ thư nhận.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/notifications:send-sync`.

**Quyền.** scope ops:notify; mTLS SPIFFE.

**FR hiện thực.** FR-18-036, FR-18-037.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationInput`; trường bắt buộc: `type`, `recipients`, `variables`, `sourceRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `NotificationSyncResult`; trường bắt buộc: `messageId`, `status`, `deliveries`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-039, ERR-18-041, ERR-18-042, ERR-18-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi thư mang liên kết ở chế độ đồng bộ (Q01-52): chờ máy chủ thư nhận trong `18.notify.sync.timeout-ms`; kênh gián đoạn trả ERR-18-044.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/notifications:send-sync
Idempotency-Key: dh-2026-11-27-0001

{"type": "ph01.ho-so.da-duyet", "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}],
 "variables": {"maHoSo": "HS-0042", "lienKet": "/ket-noi/ho-so/HS-0042"},
 "channels": ["EMAIL"], "priority": "NORMAL", "sourceRef": "onboarding:HS-0042",
 "expiresAt": "2026-11-27T09:15:02+07:00"}
```

```http
HTTP/1.1 200 OK

{"messageId": "0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424", "status": "SENT",
 "deliveries": [{"channel": "EMAIL", "status": "SENT"}]}
```

#### API-18-093 · Trạng thái một thông báo đã gửi cho bên gọi

::: dac-ta
**Mục đích.** Trạng thái một thông báo đã gửi cho bên gọi.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/notifications/{messageId}`.

**Quyền.** scope ops:notify; mTLS SPIFFE.

**FR hiện thực.** FR-18-036, FR-18-041.

**Tham số.** `messageId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationStatus`; trường bắt buộc: `messageId`, `type`, `status`, `requestedAt`, `deliveries`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái một thông báo đã gửi cho bên gọi. Quyền scope ops:notify; mTLS SPIFFE; FR-18-036, 041.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/notifications/0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424
```

```http
HTTP/1.1 200 OK

{"messageId": "0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424", "type": "ph01.ho-so.da-duyet",
 "status": "SENT", "requestedAt": "2026-11-27T09:15:02+07:00",
 "deliveries": [{"channel": "EMAIL", "status": "SENT"}]}
```

#### API-18-094 · Phân giải `recipientRef` thành danh sách người nhận (không trả địa chỉ cho bên gọi)

::: dac-ta
**Mục đích.** Phân giải `recipientRef` thành danh sách người nhận (không trả địa chỉ cho bên gọi).

**Phương thức, đường dẫn.** `POST /ops/internal/v1/recipients:resolve`.

**Quyền.** scope ops:notify; mTLS SPIFFE.

**FR hiện thực.** FR-18-037.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RecipientResolveInput`; trường bắt buộc: `recipients`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RecipientResolveResult`; trường bắt buộc: `counts`, `unresolved`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010, ERR-18-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân giải `recipientRef` thành danh sách người nhận (không trả địa chỉ cho bên gọi). Quyền scope ops:notify; mTLS SPIFFE; FR-18-037.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/recipients:resolve

{"recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "channels": ["EMAIL"]}
```

```http
HTTP/1.1 200 OK

{"counts": {"users": 12, "email": 12, "sms": 12, "inApp": 12, "suppressed": 12},
 "unresolved": []}
```

#### API-18-095 · Tùy chọn nhận thông báo của người dùng theo loại, kênh, giờ yên lặng

::: dac-ta
**Mục đích.** Tùy chọn nhận thông báo của người dùng theo loại, kênh, giờ yên lặng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/me/notification-preferences`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-038.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationPreferences`; trường bắt buộc: `userId`, `version`, `prefs`, `quietHours`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tùy chọn nhận thông báo của người dùng theo loại, kênh, giờ yên lặng. Quyền Đăng nhập (mọi vai trò); FR-18-038.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/me/notification-preferences
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"userId": "tran.thi.binh", "version": 3,
 "prefs": [{"typeGroup": "TASK", "channel": "EMAIL", "enabled": true, "mandatory": true}],
 "quietHours": "22:00-06:00"}
```

#### API-18-096 · Lưu tùy chọn nhận thông báo (`If-Match`)

::: dac-ta
**Mục đích.** Lưu tùy chọn nhận thông báo (`If-Match`).

**Phương thức, đường dẫn.** `PUT /api/ops/v1/me/notification-preferences`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-038.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationPreferencesInput`; trường bắt buộc: `prefs`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationPreferences`; trường bắt buộc: `userId`, `version`, `prefs`, `quietHours`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-046, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lưu tùy chọn nhận thông báo (`If-Match`). Quyền Đăng nhập (mọi vai trò); FR-18-038.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/me/notification-preferences
If-Match: W/"3"

{"prefs": [{"typeGroup": "TASK", "channel": "EMAIL", "enabled": true}],
 "quietHours": "22:00-06:00"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"userId": "tran.thi.binh", "version": 3,
 "prefs": [{"typeGroup": "TASK", "channel": "EMAIL", "enabled": true, "mandatory": true}],
 "quietHours": "22:00-06:00"}
```

#### API-18-097 · Thông báo trong ứng dụng của người dùng, số chưa đọc

::: dac-ta
**Mục đích.** Thông báo trong ứng dụng của người dùng, số chưa đọc.

**Phương thức, đường dẫn.** `GET /api/ops/v1/me/notifications`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-036, FR-18-038.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `unreadOnly` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MeNotificationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thông báo trong ứng dụng của người dùng, số chưa đọc. Quyền Đăng nhập (mọi vai trò); FR-18-036, 038.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/me/notifications
```

```http
HTTP/1.1 200 OK

{"items": [{"notificationId": "0190a1b2-c3d4-7e5f-8a6b-76690295a435",
   "title": "Bạn có hồ sơ kết nạp chờ duyệt", "typeGroup": "TASK", "priority": "NORMAL",
   "createdAt": "2026-11-27T09:15:02+07:00"}], "page": 0, "size": 20, "totalElements": 1,
 "unreadCount": 3}
```

#### API-18-098 · Đánh dấu đã đọc một hoặc tất cả thông báo

::: dac-ta
**Mục đích.** Đánh dấu đã đọc một hoặc tất cả thông báo.

**Phương thức, đường dẫn.** `POST /api/ops/v1/me/notifications/{notificationId}:read`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-036.

**Tham số.** `notificationId` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReadResult`; trường bắt buộc: `updated`, `unreadCount`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đánh dấu đã đọc một hoặc tất cả thông báo. Quyền Đăng nhập (mọi vai trò); FR-18-036.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/me/notifications/all:read
```

```http
HTTP/1.1 200 OK

{"updated": 12, "unreadCount": 3}
```

#### API-18-099 · Quy tắc sự kiện sang mẫu và người nhận

::: dac-ta
**Mục đích.** Quy tắc sự kiện sang mẫu và người nhận.

**Phương thức, đường dẫn.** `GET /api/ops/v1/notification-rules`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-039.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `eventType` (query, string, tùy chọn); `templateCode` (query, TemplateCode, tùy chọn); `enabled` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationRulePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quy tắc sự kiện sang mẫu và người nhận. Quyền PERM-18-template; FR-18-039.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/notification-rules
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "ruleCode": "qt-ho-so-duyet",
   "eventType": "integration.version.submitted.v1", "templateCode": "ph01.ho-so.da-duyet",
   "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "priority": "NORMAL",
   "createTask": true, "enabled": true}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-100 · Tạo quy tắc (sự kiện, điều kiện, mẫu, người nhận, mức)

::: dac-ta
**Mục đích.** Tạo quy tắc (sự kiện, điều kiện, mẫu, người nhận, mức).

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-rules`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-039.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationRuleInput`; trường bắt buộc: `ruleCode`, `eventType`, `templateCode`, `recipients`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `NotificationRule`; trường bắt buộc: `version`, `id`, `ruleCode`, `eventType`, `templateCode`, `recipients`, `priority`, `createTask`, `enabled`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-041, ERR-18-045, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo quy tắc (sự kiện, điều kiện, mẫu, người nhận, mức). Quyền PERM-18-template; FR-18-039.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-rules
Idempotency-Key: dh-2026-11-27-0001

{"ruleCode": "qt-ho-so-duyet", "eventType": "integration.version.submitted.v1",
 "condition": "data.decision == 'REJECTED'", "templateCode": "ph01.ho-so.da-duyet",
 "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "priority": "NORMAL",
 "createTask": true, "taskType": "ph01.approve-onboarding", "enabled": true}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/notification-rules/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "ruleCode": "qt-ho-so-duyet", "eventType": "integration.version.submitted.v1",
 "condition": "data.decision == 'REJECTED'", "templateCode": "ph01.ho-so.da-duyet",
 "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "priority": "NORMAL",
 "createTask": true, "taskType": "ph01.approve-onboarding", "enabled": true}
```

#### API-18-101 · Sửa, bật, tắt quy tắc (`If-Match`)

::: dac-ta
**Mục đích.** Sửa, bật, tắt quy tắc (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/notification-rules/{ruleId}`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-039.

**Tham số.** `ruleId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationRulePatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationRule`; trường bắt buộc: `version`, `id`, `ruleCode`, `eventType`, `templateCode`, `recipients`, `priority`, `createTask`, `enabled`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-041, ERR-18-045, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa, bật, tắt quy tắc (`If-Match`). Quyền PERM-18-template; FR-18-039.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/notification-rules/0190a1b2-c3d4-7e5f-8a6b-d518fb001991
If-Match: W/"3"

{"condition": "data.decision == 'REJECTED'", "templateCode": "ph01.ho-so.da-duyet",
 "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "priority": "NORMAL",
 "createTask": true, "taskType": "ph01.approve-onboarding", "enabled": true}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "ruleCode": "qt-ho-so-duyet", "eventType": "integration.version.submitted.v1",
 "condition": "data.decision == 'REJECTED'", "templateCode": "ph01.ho-so.da-duyet",
 "recipients": [{"kind": "USER", "ref": "tran.thi.binh"}], "priority": "NORMAL",
 "createTask": true, "taskType": "ph01.approve-onboarding", "enabled": true}
```

#### API-18-102 · Nhật ký gửi theo người nhận đã che, kênh, trạng thái, nguồn

::: dac-ta
**Mục đích.** Nhật ký gửi theo người nhận đã che, kênh, trạng thái, nguồn.

**Phương thức, đường dẫn.** `GET /api/ops/v1/notification-deliveries`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-040, FR-18-041.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `type` (query, TemplateCode, tùy chọn); `channel` (query, Channel, tùy chọn); `status` (query, DeliveryStatus, tùy chọn); `recipientUser` (query, string, tùy chọn); `callerPh` (query, ModuleCode, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationDeliveryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký gửi theo người nhận đã che, kênh, trạng thái, nguồn. Quyền PERM-18-read; FR-18-040, 041.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/notification-deliveries
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288",
   "messageId": "0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424", "type": "ph01.ho-so.da-duyet",
   "channel": "EMAIL", "recipientMasked": "ng***@t68.gov.vn", "status": "SENT",
   "attempts": 3, "callerPh": "PH-04", "queuedAt": "2026-11-27T09:15:02+07:00"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-103 · Gửi lại một thông báo `FAILED` hoặc `BOUNCED` sau khi sửa đầu mối

::: dac-ta
**Mục đích.** Gửi lại một thông báo `FAILED` hoặc `BOUNCED` sau khi sửa đầu mối.

**Phương thức, đường dẫn.** `POST /api/ops/v1/notification-deliveries/{deliveryId}:resend`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-040, FR-18-041.

**Tham số.** `deliveryId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `NotificationDelivery`; trường bắt buộc: `id`, `messageId`, `type`, `channel`, `recipientMasked`, `status`, `attempts`, `callerPh`, `queuedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-043, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi lại một thông báo `FAILED` hoặc `BOUNCED` sau khi sửa đầu mối. Quyền PERM-18-template; FR-18-040, 041.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/notification-deliveries/0190a1b2-c3d4-7e5f-8a6b-3317ac4eddf5:resend
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 202 Accepted

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288",
 "messageId": "0190a1b2-c3d4-7e5f-8a6b-009bc6ca5424", "type": "ph01.ho-so.da-duyet",
 "channel": "EMAIL", "recipientMasked": "ng***@t68.gov.vn",
 "recipientUser": "tran.thi.binh", "status": "SENT", "attempts": 3,
 "providerMessageId": "smtp-7f3a91", "lastErrorCode": "ERR-18-110",
 "suppressedReason": "giá trị mẫu", "callerPh": "PH-04", "sourceRef": "onboarding:HS-0042",
 "queuedAt": "2026-11-27T09:15:02+07:00", "sentAt": "2026-11-27T09:15:02+07:00",
 "deliveredAt": "2026-11-27T09:15:02+07:00", "bouncedAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-104 · Danh sách chặn do thư trả lại cứng hoặc người dùng hủy nhận

::: dac-ta
**Mục đích.** Danh sách chặn do thư trả lại cứng hoặc người dùng hủy nhận.

**Phương thức, đường dẫn.** `GET /api/ops/v1/suppressions`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-040.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `channel` (query, string, tùy chọn); `reason` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SuppressionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách chặn do thư trả lại cứng hoặc người dùng hủy nhận. Quyền PERM-18-template; FR-18-040.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/suppressions
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "channel": "EMAIL",
   "addressMasked": "ng***@t68.gov.vn", "reason": "HARD_BOUNCE", "bounceCount": 12}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-105 · Gỡ địa chỉ khỏi danh sách chặn kèm lý do

::: dac-ta
**Mục đích.** Gỡ địa chỉ khỏi danh sách chặn kèm lý do.

**Phương thức, đường dẫn.** `DELETE /api/ops/v1/suppressions/{suppressionId}`.

**Quyền.** `PERM-18-template`.

**FR hiện thực.** FR-18-040.

**Tham số.** `suppressionId` (path, string, bắt buộc); `reason` (query, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ địa chỉ khỏi danh sách chặn kèm lý do. Quyền PERM-18-template; FR-18-040.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/ops/v1/suppressions/0190a1b2-c3d4-7e5f-8a6b-b04f7c73bbf6?reason=Đích không còn dùng
If-Match: W/"3"
```

```http
HTTP/1.1 204 No Content
```

#### API-18-106 · Máy chủ thư hoặc SMS gateway báo thư trả lại, báo nhận

::: dac-ta
**Mục đích.** Máy chủ thư hoặc SMS gateway báo thư trả lại, báo nhận.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/notifications/bounces`.

**Quyền.** scope ops:notify; mTLS SPIFFE.

**FR hiện thực.** FR-18-040.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `BounceInput`; trường bắt buộc: `messageRef`, `bounceType`, `occurredAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `BounceAck`; trường bắt buộc: `status`, `suppressed`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Máy chủ thư hoặc SMS gateway báo thư trả lại, báo nhận. Quyền scope ops:notify; mTLS SPIFFE; FR-18-040.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/notifications/bounces

{"messageRef": "smtp-7f3a91", "bounceType": "HARD", "smtpCode": "550",
 "occurredAt": "2026-11-27T09:15:02+07:00"}
```

```http
HTTP/1.1 202 Accepted

{"deliveryId": "0190a1b2-c3d4-7e5f-8a6b-3317ac4eddf5", "status": "SENT", "suppressed": false}
```

### 14.6. Việc của tôi và lịch

`TaskInboxApi` (loại việc, tạo, đóng việc lũy đẳng, Việc của tôi), `WorkingCalendarApi` (lịch năm, tính hạn), cửa sổ bảo trì và đóng băng (FR-18-042…046). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-107 · PH đăng ký loại việc (mã, tên, quyền xem, hạn mặc định, liên kết màn)

::: dac-ta
**Mục đích.** PH đăng ký loại việc (mã, tên, quyền xem, hạn mặc định, liên kết màn).

**Phương thức, đường dẫn.** `POST /ops/internal/v1/task-types`.

**Quyền.** scope ops:task; mTLS SPIFFE.

**FR hiện thực.** FR-18-042.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskTypeInput`; trường bắt buộc: `taskType`, `title`, `viewPermission`, `linkTemplate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TaskType`; trường bắt buộc: `version`, `id`, `taskType`, `ownerPh`, `title`, `viewPermission`, `linkTemplate`, `fourEyes`, `enabled`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH đăng ký loại việc (mã, tên, quyền xem, hạn mặc định, liên kết màn). Quyền scope ops:task; mTLS SPIFFE; FR-18-042.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/task-types
Idempotency-Key: dh-2026-11-27-0001

{"taskType": "ph01.approve-onboarding", "title": "Duyệt hồ sơ kết nạp HTTT",
 "viewPermission": "PERM-01-review", "defaultDueWorkingDays": 2,
 "linkTemplate": "/ket-noi/ho-so/{ref}", "fourEyes": true}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "taskType": "ph01.approve-onboarding", "ownerPh": "PH-04",
 "title": "Duyệt hồ sơ kết nạp HTTT", "viewPermission": "PERM-01-review",
 "defaultDueWorkingDays": 2, "linkTemplate": "/ket-noi/ho-so/{ref}", "fourEyes": true,
 "enabled": true}
```

#### API-18-108 · Danh sách loại việc đã đăng ký theo PH

::: dac-ta
**Mục đích.** Danh sách loại việc đã đăng ký theo PH.

**Phương thức, đường dẫn.** `GET /api/ops/v1/task-types`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-042.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TaskTypePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách loại việc đã đăng ký theo PH. Quyền PERM-18-read; FR-18-042.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/task-types
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "taskType": "ph01.approve-onboarding", "ownerPh": "PH-04",
   "title": "Duyệt hồ sơ kết nạp HTTT", "viewPermission": "PERM-01-review",
   "linkTemplate": "/ket-noi/ho-so/{ref}", "fourEyes": true, "enabled": true}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-109 · Tạo hoặc cập nhật việc lũy đẳng theo `sourceRef`

::: dac-ta
**Mục đích.** Tạo hoặc cập nhật việc lũy đẳng theo `sourceRef`.

**Phương thức, đường dẫn.** `PUT /ops/internal/v1/tasks/{sourceRef}`.

**Quyền.** scope ops:task; mTLS SPIFFE.

**FR hiện thực.** FR-18-043.

**Tham số.** `sourceRef` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskUpsertInput`; trường bắt buộc: `taskType`, `assignees`, `summary`, `sourceVersion`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TaskItem`; trường bắt buộc: `version`, `id`, `taskType`, `sourceRef`, `ownerPh`, `summary`, `assignees`, `status`, `priority`, `overdue`, `sourceVersion`, `link`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-010, ERR-18-047, ERR-18-048 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo hoặc cập nhật việc lũy đẳng theo `sourceRef` và `sourceVersion` tăng dần; bản cũ hơn bị bỏ qua. `summary` không chứa dữ liệu Hạn chế.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /ops/internal/v1/tasks/onboarding:HS-0042

{"taskType": "ph01.approve-onboarding",
 "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}],
 "excludeUsers": ["nguyen.van.an"], "dueAt": "2026-11-27T09:15:02+07:00",
 "dueWorkingDays": 12, "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
 "sourceVersion": 3, "priority": "NORMAL"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "taskType": "ph01.approve-onboarding", "sourceRef": "onboarding:HS-0042",
 "ownerPh": "PH-04", "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
 "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}], "status": "OPEN",
 "priority": "NORMAL", "dueAt": "2026-11-27T09:15:02+07:00", "overdue": false,
 "claimedBy": "tran.thi.binh", "sourceVersion": 3, "closedAt": "2026-11-27T09:15:02+07:00",
 "outcome": "DONE", "link": "/ket-noi/ho-so/HS-0042"}
```

#### API-18-110 · Đóng việc (`DONE`, `CANCELLED`) lũy đẳng

::: dac-ta
**Mục đích.** Đóng việc (`DONE`, `CANCELLED`) lũy đẳng.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/tasks/{sourceRef}:close`.

**Quyền.** scope ops:task; mTLS SPIFFE.

**FR hiện thực.** FR-18-043.

**Tham số.** `sourceRef` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TaskCloseInput`; trường bắt buộc: `outcome`, `sourceVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TaskItem`; trường bắt buộc: `version`, `id`, `taskType`, `sourceRef`, `ownerPh`, `summary`, `assignees`, `status`, `priority`, `overdue`, `sourceVersion`, `link`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-048 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đóng việc (`DONE`, `CANCELLED`) lũy đẳng. Quyền scope ops:task; mTLS SPIFFE; FR-18-043.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/tasks/onboarding:HS-0042:close
Idempotency-Key: dh-2026-11-27-0001

{"outcome": "DONE", "sourceVersion": 3, "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "taskType": "ph01.approve-onboarding", "sourceRef": "onboarding:HS-0042",
 "ownerPh": "PH-04", "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
 "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}], "status": "OPEN",
 "priority": "NORMAL", "dueAt": "2026-11-27T09:15:02+07:00", "overdue": false,
 "claimedBy": "tran.thi.binh", "sourceVersion": 3, "closedAt": "2026-11-27T09:15:02+07:00",
 "outcome": "DONE", "link": "/ket-noi/ho-so/HS-0042"}
```

#### API-18-111 · Việc của tôi: lọc theo loại, hạn, trạng thái; `?summary=true` cho thẻ trang chủ

::: dac-ta
**Mục đích.** Việc của tôi: lọc theo loại, hạn, trạng thái; `?summary=true` cho thẻ trang chủ.

**Phương thức, đường dẫn.** `GET /api/ops/v1/me/tasks`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-044.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `taskType` (query, TaskTypeCode, tùy chọn); `ownerPh` (query, ModuleCode, tùy chọn); `due` (query, string, tùy chọn); `status` (query, TaskStatus, tùy chọn); `summary` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MyTaskPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Việc của tôi: lọc theo loại, hạn, trạng thái; `?summary=true` cho thẻ trang chủ. Quyền Đăng nhập (mọi vai trò); FR-18-044.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/me/tasks
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "taskType": "ph01.approve-onboarding", "sourceRef": "onboarding:HS-0042",
   "ownerPh": "PH-04", "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
   "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}], "status": "OPEN",
   "priority": "NORMAL", "overdue": false, "sourceVersion": 3,
   "link": "/ket-noi/ho-so/HS-0042"}], "page": 0, "size": 20, "totalElements": 1,
 "summary": {"open": 12, "overdue": 12, "dueToday": 12,
  "byType": [{"value": "ph04-runtime", "count": 37}]}}
```

#### API-18-112 · Chi tiết việc và liên kết sang màn của PH nguồn

::: dac-ta
**Mục đích.** Chi tiết việc và liên kết sang màn của PH nguồn.

**Phương thức, đường dẫn.** `GET /api/ops/v1/me/tasks/{taskId}`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-044.

**Tham số.** `taskId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TaskItem`; trường bắt buộc: `version`, `id`, `taskType`, `sourceRef`, `ownerPh`, `summary`, `assignees`, `status`, `priority`, `overdue`, `sourceVersion`, `link`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết việc và liên kết sang màn của PH nguồn. Quyền Đăng nhập (mọi vai trò); FR-18-044.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/me/tasks/0190a1b2-c3d4-7e5f-8a6b-52fc4097b1a9
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "taskType": "ph01.approve-onboarding", "sourceRef": "onboarding:HS-0042",
 "ownerPh": "PH-04", "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
 "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}], "status": "OPEN",
 "priority": "NORMAL", "dueAt": "2026-11-27T09:15:02+07:00", "overdue": false,
 "claimedBy": "tran.thi.binh", "sourceVersion": 3, "closedAt": "2026-11-27T09:15:02+07:00",
 "outcome": "DONE", "link": "/ket-noi/ho-so/HS-0042"}
```

#### API-18-113 · Lịch năm của tenant: ngày nghỉ cuối tuần, ngày lễ, ngày làm bù

::: dac-ta
**Mục đích.** Lịch năm của tenant: ngày nghỉ cuối tuần, ngày lễ, ngày làm bù.

**Phương thức, đường dẫn.** `GET /api/ops/v1/calendars`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-045.

**Tham số.** `year` (query, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkCalendar`; trường bắt buộc: `version`, `id`, `year`, `calendarScope`, `timezone`, `weekendDays`, `holidays`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch năm của tenant: ngày nghỉ cuối tuần, ngày lễ, ngày làm bù. Quyền PERM-18-read; FR-18-045.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/calendars?year=2026
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh", "year": 2026,
 "calendarScope": "COMMON", "timezone": "Asia/Ho_Chi_Minh", "weekendDays": ["SAT", "SUN"],
 "holidays": [{"date": "2027-01-01", "name": "Tết Dương lịch", "kind": "HOLIDAY"}]}
```

#### API-18-114 · Ghi lịch năm của tenant (`If-Match`)

::: dac-ta
**Mục đích.** Ghi lịch năm của tenant (`If-Match`).

**Phương thức, đường dẫn.** `PUT /api/ops/v1/calendars/{year}`.

**Quyền.** `PERM-18-calendar`.

**FR hiện thực.** FR-18-045.

**Tham số.** `year` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WorkCalendarInput`; trường bắt buộc: `weekendDays`, `holidays`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkCalendar`; trường bắt buộc: `version`, `id`, `year`, `calendarScope`, `timezone`, `weekendDays`, `holidays`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-049, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi lịch năm của tenant (`If-Match`). Quyền PERM-18-calendar; FR-18-045.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/calendars/2026
If-Match: W/"3"

{"weekendDays": ["SAT", "SUN"],
 "holidays": [{"date": "2027-01-01", "name": "Tết Dương lịch", "kind": "HOLIDAY"}],
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh", "year": 2026,
 "calendarScope": "COMMON", "timezone": "Asia/Ho_Chi_Minh", "weekendDays": ["SAT", "SUN"],
 "holidays": [{"date": "2027-01-01", "name": "Tết Dương lịch", "kind": "HOLIDAY"}]}
```

#### API-18-115 · Thêm ngày lễ hoặc ngày làm bù

::: dac-ta
**Mục đích.** Thêm ngày lễ hoặc ngày làm bù.

**Phương thức, đường dẫn.** `POST /api/ops/v1/calendars/{year}/holidays`.

**Quyền.** `PERM-18-calendar`.

**FR hiện thực.** FR-18-045.

**Tham số.** `year` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CalendarHolidayInput`; trường bắt buộc: `date`, `name`, `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CalendarHoliday`; trường bắt buộc: `date`, `name`, `kind`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-049, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm ngày lễ hoặc ngày làm bù. Quyền PERM-18-calendar; FR-18-045.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/calendars/2026/holidays
Idempotency-Key: dh-2026-11-27-0001

{"date": "2027-01-01", "name": "Tết Dương lịch", "kind": "HOLIDAY",
 "legalBasis": "Bộ luật Lao động 2019, Điều 112"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/calendars/2026/holidays/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288

{"date": "2027-01-01", "name": "Tết Dương lịch", "kind": "HOLIDAY",
 "legalBasis": "Bộ luật Lao động 2019, Điều 112"}
```

#### API-18-116 · Số ngày làm việc, danh sách ngày làm việc trong khoảng

::: dac-ta
**Mục đích.** Số ngày làm việc, danh sách ngày làm việc trong khoảng.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/calendar/{tenant}:working-days`.

**Quyền.** scope ops:calendar-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-045.

**Tham số.** `tenant` (path, TenantCode, bắt buộc); `from` (query, string, bắt buộc); `to` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkingDaysResult`; trường bắt buộc: `tenant`, `from`, `to`, `count`, `days`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Số ngày làm việc, danh sách ngày làm việc trong khoảng. Quyền scope ops:calendar-read; mTLS SPIFFE; FR-18-045.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/calendar/T68:working-days?from=2026-11-01&to=2026-11-30
```

```http
HTTP/1.1 200 OK

{"tenant": "T68", "from": "2026-11-01", "to": "2026-11-30", "count": 37,
 "days": ["2026-12-01", "2026-12-02"]}
```

#### API-18-117 · Tính hạn: mốc cộng n ngày làm việc

::: dac-ta
**Mục đích.** Tính hạn: mốc cộng n ngày làm việc.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/calendar/{tenant}:add-working-days`.

**Quyền.** scope ops:calendar-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-045.

**Tham số.** `tenant` (path, TenantCode, bắt buộc).

**Thân yêu cầu.** application/json: `AddWorkingDaysInput`; trường bắt buộc: `from`, `workingDays`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AddWorkingDaysResult`; trường bắt buộc: `from`, `workingDays`, `dueAt`, `skippedDates`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tính hạn theo lịch của tenant (ngày nghỉ cuối tuần, ngày lễ, ngày làm bù); trả `skippedDates[]` để giải thích.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/calendar/T68:add-working-days

{"from": "2026-11-26T00:00:00+07:00", "workingDays": 5}
```

```http
HTTP/1.1 200 OK

{"from": "2026-11-26T00:00:00+07:00", "workingDays": 5,
 "dueAt": "2026-11-27T09:15:02+07:00", "skippedDates": ["2026-12-05", "2026-12-06"]}
```

#### API-18-118 · Cửa sổ bảo trì và đóng băng theo môi trường, thời gian

::: dac-ta
**Mục đích.** Cửa sổ bảo trì và đóng băng theo môi trường, thời gian.

**Phương thức, đường dẫn.** `GET /api/ops/v1/maintenance-windows`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-046.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `kind` (query, string, tùy chọn); `environment` (query, Environment, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MaintenanceWindowPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cửa sổ bảo trì và đóng băng theo môi trường, thời gian. Quyền PERM-18-read; FR-18-046.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/maintenance-windows
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "windowCode": "MW-2026-0012",
   "kind": "MAINTENANCE", "scope": "PLATFORM", "environments": ["PROD"],
   "startsAt": "2026-12-06T22:00:00+07:00", "endsAt": "2026-12-07T02:00:00+07:00",
   "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
   "notify": true, "state": "PLANNED"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-119 · Tạo cửa sổ bảo trì hoặc đóng băng

::: dac-ta
**Mục đích.** Tạo cửa sổ bảo trì hoặc đóng băng.

**Phương thức, đường dẫn.** `POST /api/ops/v1/maintenance-windows`.

**Quyền.** `PERM-18-calendar`.

**FR hiện thực.** FR-18-046.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MaintenanceWindowInput`; trường bắt buộc: `kind`, `scope`, `startsAt`, `endsAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `MaintenanceWindow`; trường bắt buộc: `version`, `id`, `windowCode`, `kind`, `scope`, `environments`, `startsAt`, `endsAt`, `reason`, `notify`, `state`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-050, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo cửa sổ bảo trì hoặc đóng băng. Quyền PERM-18-calendar; FR-18-046.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/maintenance-windows
Idempotency-Key: dh-2026-11-27-0001

{"kind": "MAINTENANCE", "scope": "PLATFORM", "environments": ["PROD"],
 "startsAt": "2026-12-06T22:00:00+07:00", "endsAt": "2026-12-07T02:00:00+07:00",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "notify": true,
 "exemptions": ["VA_ATTT_KHAN"]}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/maintenance-windows/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "windowCode": "MW-2026-0012", "kind": "MAINTENANCE", "scope": "PLATFORM",
 "environments": ["PROD"], "startsAt": "2026-12-06T22:00:00+07:00",
 "endsAt": "2026-12-07T02:00:00+07:00",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "notify": true,
 "exemptions": ["VA_ATTT_KHAN"], "state": "PLANNED", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-120 · Sửa cửa sổ chưa bắt đầu (`If-Match`)

::: dac-ta
**Mục đích.** Sửa cửa sổ chưa bắt đầu (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/maintenance-windows/{windowId}`.

**Quyền.** `PERM-18-calendar`.

**FR hiện thực.** FR-18-046.

**Tham số.** `windowId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MaintenanceWindowPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MaintenanceWindow`; trường bắt buộc: `version`, `id`, `windowCode`, `kind`, `scope`, `environments`, `startsAt`, `endsAt`, `reason`, `notify`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-050, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa cửa sổ chưa bắt đầu (`If-Match`). Quyền PERM-18-calendar; FR-18-046.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/maintenance-windows/0190a1b2-c3d4-7e5f-8a6b-1ef6110d9a62
If-Match: W/"3"

{"environments": ["PROD"], "startsAt": "2026-12-06T22:00:00+07:00",
 "endsAt": "2026-12-07T02:00:00+07:00",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "notify": true,
 "exemptions": ["VA_ATTT_KHAN"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "windowCode": "MW-2026-0012", "kind": "MAINTENANCE", "scope": "PLATFORM",
 "environments": ["PROD"], "startsAt": "2026-12-06T22:00:00+07:00",
 "endsAt": "2026-12-07T02:00:00+07:00",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "notify": true,
 "exemptions": ["VA_ATTT_KHAN"], "state": "PLANNED", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-121 · Hủy cửa sổ kèm lý do

::: dac-ta
**Mục đích.** Hủy cửa sổ kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/maintenance-windows/{windowId}:cancel`.

**Quyền.** `PERM-18-calendar`.

**FR hiện thực.** FR-18-046.

**Tham số.** `windowId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MaintenanceWindow`; trường bắt buộc: `version`, `id`, `windowCode`, `kind`, `scope`, `environments`, `startsAt`, `endsAt`, `reason`, `notify`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy cửa sổ kèm lý do. Quyền PERM-18-calendar; FR-18-046.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/maintenance-windows/0190a1b2-c3d4-7e5f-8a6b-1ef6110d9a62:cancel
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "windowCode": "MW-2026-0012", "kind": "MAINTENANCE", "scope": "PLATFORM",
 "environments": ["PROD"], "startsAt": "2026-12-06T22:00:00+07:00",
 "endsAt": "2026-12-07T02:00:00+07:00",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118", "notify": true,
 "exemptions": ["VA_ATTT_KHAN"], "state": "PLANNED", "cancelReason": "Hệ đích chưa phục hồi"}
```

#### API-18-122 · Trạng thái đóng băng, bảo trì hiện hành theo môi trường cho PH-02, PH-04

::: dac-ta
**Mục đích.** Trạng thái đóng băng, bảo trì hiện hành theo môi trường cho PH-02, PH-04.

**Phương thức, đường dẫn.** `GET /ops/internal/v1/freeze-status/{tenant}`.

**Quyền.** scope ops:calendar-read; mTLS SPIFFE.

**FR hiện thực.** FR-18-046.

**Tham số.** `tenant` (path, TenantCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FreezeStatus`; trường bắt buộc: `tenant`, `evaluatedAt`, `frozen`, `active`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-02, PH-04 đọc trước khi phát hành lên môi trường thật; PH-18 vắng thì bên gọi coi là không đóng băng và ghi cảnh báo (BR-18 về suy giảm).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /ops/internal/v1/freeze-status/T68
```

```http
HTTP/1.1 200 OK

{"tenant": "T68", "evaluatedAt": "2026-11-27T09:15:02+07:00", "frozen": false,
 "active": [{"windowCode": "MW-2026-0012", "kind": "MAINTENANCE", "environments": ["PROD"],
   "startsAt": "2026-12-06T22:00:00+07:00", "endsAt": "2026-12-07T02:00:00+07:00"}]}
```

#### API-18-181 · Nhận việc: chuyển `IN_PROGRESS`, ghi người nhận, báo người cùng nhận (EVT-18-14)

::: dac-ta
**Mục đích.** Nhận việc: chuyển `IN_PROGRESS`, ghi người nhận, báo người cùng nhận (EVT-18-14).

**Phương thức, đường dẫn.** `POST /api/ops/v1/me/tasks/{taskId}:claim`.

**Quyền.** Đăng nhập (mọi vai trò).

**FR hiện thực.** FR-18-044.

**Tham số.** `taskId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TaskItem`; trường bắt buộc: `version`, `id`, `taskType`, `sourceRef`, `ownerPh`, `summary`, `assignees`, `status`, `priority`, `overdue`, `sourceVersion`, `link`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-048, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người nhận việc báo người cùng nhận: việc `OPEN` chuyển `IN_PROGRESS`, ghi người nhận, phát EVT-18-14; việc đã đóng trả ERR-18-048; gọi lại khi đã nhận trả `200` không đổi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/me/tasks/0190a1b2-c3d4-7e5f-8a6b-52fc4097b1a9:claim
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "taskType": "ph01.approve-onboarding", "sourceRef": "onboarding:HS-0042",
 "ownerPh": "PH-04", "summary": "Duyệt hồ sơ kết nạp HTTT quản lý văn bản",
 "assignees": [{"kind": "USER", "ref": "tran.thi.binh"}], "status": "OPEN",
 "priority": "NORMAL", "dueAt": "2026-11-27T09:15:02+07:00", "overdue": false,
 "claimedBy": "tran.thi.binh", "sourceVersion": 3, "closedAt": "2026-11-27T09:15:02+07:00",
 "outcome": "DONE", "link": "/ket-noi/ho-so/HS-0042"}
```

### 14.7. Sự cố vận hành

Hồ sơ sự cố từ sự kiện hoặc tạo tay, vòng đời, mốc thời gian, liên kết, chuyển PH-09, đóng có nguyên nhân và bài học (FR-18-047…051). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-123 · Danh sách sự cố vận hành theo mức, trạng thái, người xử lý

::: dac-ta
**Mục đích.** Danh sách sự cố vận hành theo mức, trạng thái, người xử lý.

**Phương thức, đường dẫn.** `GET /api/ops/v1/incidents`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-047, FR-18-048.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `status` (query, IncidentStatus, tùy chọn); `assignee` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IncidentPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách sự cố vận hành theo mức, trạng thái, người xử lý. Quyền PERM-18-read; FR-18-047, 048.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/incidents
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
   "severity": "SEV2", "category": "AVAILABILITY", "origin": "EVENT",
   "status": "INVESTIGATING", "detectedAt": "2026-11-27T09:15:02+07:00"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-124 · Tạo sự cố thủ công

::: dac-ta
**Mục đích.** Tạo sự cố thủ công.

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-048.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentInput`; trường bắt buộc: `title`, `description`, `severity`, `category`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo sự cố thủ công. Quyền PERM-18-incident; FR-18-048.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents
Idempotency-Key: dh-2026-11-27-0001

{"title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "assignee": "tran.thi.binh", "hasPersonalData": false,
 "affectedSystems": ["HTTT-QLVB"], "detectedAt": "2026-11-27T09:15:02+07:00"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/incidents/SC-2026-0007
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "origin": "EVENT", "sourceRef": "onboarding:HS-0042",
 "sourceType": "ALERT", "status": "INVESTIGATING", "assignee": "tran.thi.binh",
 "hasPersonalData": false, "affectedSystems": ["HTTT-QLVB"],
 "detectedAt": "2026-11-27T09:15:02+07:00", "acknowledgedAt": "2026-11-27T09:15:02+07:00",
 "mitigatedAt": "2026-11-27T09:15:02+07:00", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "closedAt": "2026-11-27T09:15:02+07:00", "privacyCaseRef": "VP-2026-0005",
 "rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}]}
```

#### API-18-125 · Chi tiết sự cố, mốc thời gian, liên kết

::: dac-ta
**Mục đích.** Chi tiết sự cố, mốc thời gian, liên kết.

**Phương thức, đường dẫn.** `GET /api/ops/v1/incidents/{incidentCode}`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-048, FR-18-049.

**Tham số.** `incidentCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IncidentDetail`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`, `timeline`, `links`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết sự cố, mốc thời gian, liên kết. Quyền PERM-18-read; FR-18-048, 049.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/incidents/SC-2026-0007
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "origin": "EVENT", "sourceRef": "onboarding:HS-0042",
 "sourceType": "ALERT", "status": "INVESTIGATING", "assignee": "tran.thi.binh",
 "hasPersonalData": false, "affectedSystems": ["HTTT-QLVB"],
 "detectedAt": "2026-11-27T09:15:02+07:00", "acknowledgedAt": "2026-11-27T09:15:02+07:00",
 "mitigatedAt": "2026-11-27T09:15:02+07:00", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "closedAt": "2026-11-27T09:15:02+07:00", "privacyCaseRef": "VP-2026-0005",
 "rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}],
 "timeline": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "kind": "NOTE",
   "content": "Đã tạm dừng luồng để chặn lỗi lan rộng",
   "occurredAt": "2026-11-27T09:15:02+07:00", "actor": "tran.thi.binh"}],
 "links": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "targetType": "DLQ_MESSAGE",
   "targetRef": "giá trị mẫu"}]}
```

#### API-18-126 · Đổi mức độ, người xử lý, tóm tắt (`If-Match`)

::: dac-ta
**Mục đích.** Đổi mức độ, người xử lý, tóm tắt (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/incidents/{incidentCode}`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-048.

**Tham số.** `incidentCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentPatch`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đổi mức độ, người xử lý, tóm tắt (`If-Match`). Quyền PERM-18-incident; FR-18-048.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/incidents/SC-2026-0007
If-Match: W/"3"

{"title": "Tiêu đề ngắn", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "severity": "SEV2", "assignee": "tran.thi.binh", "hasPersonalData": false,
 "affectedSystems": ["HTTT-QLVB"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "origin": "EVENT", "sourceRef": "onboarding:HS-0042",
 "sourceType": "ALERT", "status": "INVESTIGATING", "assignee": "tran.thi.binh",
 "hasPersonalData": false, "affectedSystems": ["HTTT-QLVB"],
 "detectedAt": "2026-11-27T09:15:02+07:00", "acknowledgedAt": "2026-11-27T09:15:02+07:00",
 "mitigatedAt": "2026-11-27T09:15:02+07:00", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "closedAt": "2026-11-27T09:15:02+07:00", "privacyCaseRef": "VP-2026-0005",
 "rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}]}
```

#### API-18-127 · Chuyển trạng thái sự cố theo vòng đời

::: dac-ta
**Mục đích.** Chuyển trạng thái sự cố theo vòng đời.

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents/{incidentCode}:transition`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-048, FR-18-051.

**Tham số.** `incidentCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentTransitionInput`; trường bắt buộc: `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển trạng thái sự cố theo vòng đời. Quyền PERM-18-incident; FR-18-048, 051.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents/SC-2026-0007:transition
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"to": "INVESTIGATING", "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "origin": "EVENT", "sourceRef": "onboarding:HS-0042",
 "sourceType": "ALERT", "status": "INVESTIGATING", "assignee": "tran.thi.binh",
 "hasPersonalData": false, "affectedSystems": ["HTTT-QLVB"],
 "detectedAt": "2026-11-27T09:15:02+07:00", "acknowledgedAt": "2026-11-27T09:15:02+07:00",
 "mitigatedAt": "2026-11-27T09:15:02+07:00", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "closedAt": "2026-11-27T09:15:02+07:00", "privacyCaseRef": "VP-2026-0005",
 "rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}]}
```

#### API-18-128 · Thêm mốc thời gian, ghi chú, hành động

::: dac-ta
**Mục đích.** Thêm mốc thời gian, ghi chú, hành động.

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents/{incidentCode}/timeline`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-049.

**Tham số.** `incidentCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TimelineInput`; trường bắt buộc: `kind`, `content`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IncidentTimelineEntry`; trường bắt buộc: `id`, `kind`, `content`, `occurredAt`, `actor`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm mốc thời gian, ghi chú, hành động. Quyền PERM-18-incident; FR-18-049.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents/SC-2026-0007/timeline
Idempotency-Key: dh-2026-11-27-0001

{"kind": "NOTE", "content": "Đã tạm dừng luồng để chặn lỗi lan rộng",
 "occurredAt": "2026-11-27T09:15:02+07:00"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/incidents/SC-2026-0007/timeline/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "kind": "NOTE",
 "content": "Đã tạm dừng luồng để chặn lỗi lan rộng",
 "occurredAt": "2026-11-27T09:15:02+07:00", "actor": "tran.thi.binh",
 "from": "INVESTIGATING", "to": "INVESTIGATING"}
```

#### API-18-129 · Liên kết mục DLQ, nhóm lỗi, cảnh báo, lượt phát lại, sao lưu

::: dac-ta
**Mục đích.** Liên kết mục DLQ, nhóm lỗi, cảnh báo, lượt phát lại, sao lưu.

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents/{incidentCode}/links`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-049.

**Tham số.** `incidentCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentLinkInput`; trường bắt buộc: `targetType`, `targetRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IncidentLink`; trường bắt buộc: `id`, `targetType`, `targetRef`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Liên kết mục DLQ, nhóm lỗi, cảnh báo, lượt phát lại, sao lưu. Quyền PERM-18-incident; FR-18-049.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents/SC-2026-0007/links
Idempotency-Key: dh-2026-11-27-0001

{"targetType": "DLQ_MESSAGE", "targetRef": "giá trị mẫu", "note": "Đã liên hệ chủ quản HTTT"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/incidents/SC-2026-0007/links/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "targetType": "DLQ_MESSAGE",
 "targetRef": "giá trị mẫu", "note": "Đã liên hệ chủ quản HTTT"}
```

#### API-18-130 · Chuyển sự cố có DLCN sang PH-09 (`INCIDENT_PH18`)

::: dac-ta
**Mục đích.** Chuyển sự cố có DLCN sang PH-09 (`INCIDENT_PH18`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents/{incidentCode}:escalate-privacy`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-050.

**Tham số.** `incidentCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EscalatePrivacyInput`; trường bắt buộc: `dataCategories`, `estimatedSubjects`, `discoveredAt`, `summary`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `EscalationResult`; trường bắt buộc: `incidentCode`, `privacyCaseRef`, `escalatedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-053, ERR-18-054, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển hồ sơ sang PH-09 (`INCIDENT_PH18`); PH-09 giữ đồng hồ 72 giờ. PH-09 không nhận thì thử lại mỗi 5 phút (ERR-18-054).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents/SC-2026-0007:escalate-privacy
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"dataCategories": ["Họ tên", "Số định danh cá nhân"], "estimatedSubjects": 120,
 "discoveredAt": "2026-11-27T09:15:02+07:00",
 "summary": "Tệp xuất danh sách hồ sơ bị gửi nhầm địa chỉ"}
```

```http
HTTP/1.1 200 OK

{"incidentCode": "SC-2026-0007", "privacyCaseRef": "VP-2026-0005",
 "escalatedAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-131 · Đóng sự cố với nguyên nhân gốc, bài học, việc khắc phục

::: dac-ta
**Mục đích.** Đóng sự cố với nguyên nhân gốc, bài học, việc khắc phục.

**Phương thức, đường dẫn.** `POST /api/ops/v1/incidents/{incidentCode}:close`.

**Quyền.** `PERM-18-incident`.

**FR hiện thực.** FR-18-051.

**Tham số.** `incidentCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentCloseInput`; trường bắt buộc: `rootCause`, `lessonsLearned`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-052, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đóng sự cố với nguyên nhân gốc, bài học, việc khắc phục. Quyền PERM-18-incident; FR-18-051.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/incidents/SC-2026-0007:close
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "incidentCode": "SC-2026-0007", "title": "Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "severity": "SEV2",
 "category": "AVAILABILITY", "origin": "EVENT", "sourceRef": "onboarding:HS-0042",
 "sourceType": "ALERT", "status": "INVESTIGATING", "assignee": "tran.thi.binh",
 "hasPersonalData": false, "affectedSystems": ["HTTT-QLVB"],
 "detectedAt": "2026-11-27T09:15:02+07:00", "acknowledgedAt": "2026-11-27T09:15:02+07:00",
 "mitigatedAt": "2026-11-27T09:15:02+07:00", "resolvedAt": "2026-11-27T09:15:02+07:00",
 "closedAt": "2026-11-27T09:15:02+07:00", "privacyCaseRef": "VP-2026-0005",
 "rootCause": "Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10",
 "lessonsLearned": "Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích",
 "actions": [{"title": "Bổ sung cảnh báo chứng thư sắp hết hạn", "owner": "pham.van.duc"}]}
```

#### API-18-132 · PH-13, PH-09 mở hoặc cập nhật sự cố theo `sourceRef` lũy đẳng

::: dac-ta
**Mục đích.** PH-13, PH-09 mở hoặc cập nhật sự cố theo `sourceRef` lũy đẳng.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/incidents`.

**Quyền.** scope ops:incident-write; mTLS SPIFFE.

**FR hiện thực.** FR-18-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentReportInput`; trường bắt buộc: `tenant`, `sourceRef`, `sourceType`, `severity`, `title`, `occurredAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; `201` đã tạo, `Incident`; trường bắt buộc: `version`, `id`, `incidentCode`, `title`, `severity`, `category`, `origin`, `status`, `detectedAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-13, PH-09 mở hoặc cập nhật sự cố theo `sourceRef` lũy đẳng. Quyền scope ops:incident-write; mTLS SPIFFE; FR-18-047.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/incidents
Idempotency-Key: dh-2026-11-27-0001

{"tenant": "T68", "sourceRef": "onboarding:HS-0042", "sourceType": "ALERT",
 "severity": "SEV2", "title": "Độ sâu DLQ nguồn ph04-runtime vượt ngưỡng",
 "occurredAt": "2026-11-27T09:15:02+07:00",
 "links": [{"targetType": "DLQ_MESSAGE", "targetRef": "giá trị mẫu"}]}
```

```http
HTTP/1.1 200 OK
```

### 14.8. Sao lưu, khôi phục và sáp nhập

Bảng sao lưu, kiểm tra khôi phục, khôi phục tenant tám bước có bốn mắt, xuất tenant, chuyển dữ liệu khi sáp nhập (PH-20), ghi nhận diễn tập DR (FR-18-052…058). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-133 · Bảng đối tượng sao lưu, lần chạy gần nhất, độ tươi, kiểm tra khôi phục

::: dac-ta
**Mục đích.** Bảng đối tượng sao lưu, lần chạy gần nhất, độ tươi, kiểm tra khôi phục.

**Phương thức, đường dẫn.** `GET /api/ops/v1/backup/objects`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-052.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `tool` (query, BackupTool, tùy chọn); `freshness` (query, Freshness, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BackupObjectPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-010, ERR-18-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bảng đối tượng sao lưu, lần chạy gần nhất, độ tươi, kiểm tra khôi phục. Quyền PERM-18-backup; FR-18-052.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/backup/objects
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "objectCode": "pg-core-base",
   "name": "Sao lưu cơ sở cụm pg-core", "objectKind": "POSTGRES_BASE",
   "tool": "CNPG_BARMAN", "freshness": "FRESH", "enabled": true}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-134 · Lịch sử bản sao lưu theo đối tượng, kết quả, dung lượng

::: dac-ta
**Mục đích.** Lịch sử bản sao lưu theo đối tượng, kết quả, dung lượng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/backup/runs`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-052.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `objectCode` (query, string, tùy chọn); `result` (query, BackupResult, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BackupRunPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-010, ERR-18-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử bản sao lưu theo đối tượng, kết quả, dung lượng. Quyền PERM-18-backup; FR-18-052.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/backup/runs
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "objectCode": "pg-core-base",
   "tool": "CNPG_BARMAN", "startedAt": "2026-11-27T02:00:00+07:00", "result": "SUCCEEDED",
   "collectedAt": "2026-11-27T09:15:02+07:00"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-135 · Tác vụ thu thập hoặc CronJob báo một bản sao lưu

::: dac-ta
**Mục đích.** Tác vụ thu thập hoặc CronJob báo một bản sao lưu.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/backup/runs`.

**Quyền.** scope ops:backup-report; mTLS SPIFFE.

**FR hiện thực.** FR-18-052.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `BackupRunReport`; trường bắt buộc: `objectCode`, `tool`, `startedAt`, `result`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `BackupRunAck`; trường bắt buộc: `runId`, `objectCode`, `freshness`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tác vụ thu thập hoặc CronJob báo một bản sao lưu. Quyền scope ops:backup-report; mTLS SPIFFE; FR-18-052.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/backup/runs

{"objectCode": "pg-core-base", "tool": "CNPG_BARMAN",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "result": "SUCCEEDED", "sizeBytes": 12,
 "location": "garage://dh-backup/pg-core/2026-11-27", "tenant": "T68",
 "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

```http
HTTP/1.1 202 Accepted

{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "objectCode": "pg-core-base",
 "freshness": "FRESH"}
```

#### API-18-136 · Kết quả kiểm tra khôi phục tự động theo đối tượng

::: dac-ta
**Mục đích.** Kết quả kiểm tra khôi phục tự động theo đối tượng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/backup/verifications`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-053.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `objectCode` (query, string, tùy chọn); `result` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RestoreVerificationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả kiểm tra khôi phục tự động theo đối tượng. Quyền PERM-18-backup; FR-18-053.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/backup/verifications
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "objectCode": "pg-core-base",
   "method": "RESTORE_LATEST", "result": "PASSED", "verifiedAt": "2026-11-27T09:15:02+07:00"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-137 · CronJob kiểm tra khôi phục báo kết quả

::: dac-ta
**Mục đích.** CronJob kiểm tra khôi phục báo kết quả.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/backup/verifications`.

**Quyền.** scope ops:backup-report; mTLS SPIFFE.

**FR hiện thực.** FR-18-053.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `VerificationReport`; trường bắt buộc: `objectCode`, `method`, `result`, `verifiedAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `VerificationAck`; trường bắt buộc: `verificationId`, `objectCode`, `result`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** CronJob kiểm tra khôi phục báo kết quả. Quyền scope ops:backup-report; mTLS SPIFFE; FR-18-053.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/backup/verifications

{"objectCode": "pg-core-base", "method": "RESTORE_LATEST", "result": "PASSED",
 "metrics": {}, "evidenceRef": "garage://dh-t68-ops/bien-ban/DT-2026-0001.pdf",
 "verifiedAt": "2026-11-27T09:15:02+07:00", "tenant": "T68"}
```

```http
HTTP/1.1 202 Accepted

{"verificationId": "0190a1b2-c3d4-7e5f-8a6b-f3da70b1f8b7", "objectCode": "pg-core-base",
 "result": "PASSED"}
```

#### API-18-138 · Tạo yêu cầu khôi phục tenant (thời điểm đích, phạm vi) ở `DRAFT`

::: dac-ta
**Mục đích.** Tạo yêu cầu khôi phục tenant (thời điểm đích, phạm vi) ở `DRAFT`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantRestoreInput`; trường bắt buộc: `targetTime`, `scope`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-056, ERR-18-057, ERR-18-058, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo yêu cầu khôi phục tenant (thời điểm đích, phạm vi) ở `DRAFT`. Quyền PERM-18-backup; FR-18-054.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores
Idempotency-Key: dh-2026-11-27-0001

{"targetTime": "2026-11-26T08:00:00+07:00", "scope": "FULL_TENANT",
 "modules": ["ph01_onboarding"], "includeObjects": true, "includeIdentity": false,
 "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-139 · Danh sách yêu cầu khôi phục

::: dac-ta
**Mục đích.** Danh sách yêu cầu khôi phục.

**Phương thức, đường dẫn.** `GET /api/ops/v1/tenant-restores`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-054, FR-18-055.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, RestoreStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantRestorePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách yêu cầu khôi phục. Quyền PERM-18-backup; FR-18-054, 055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/tenant-restores
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "requestNo": "KP-2026-0002",
   "targetTime": "2026-11-26T08:00:00+07:00", "scope": "FULL_TENANT",
   "includeObjects": true, "includeIdentity": false, "includeSecrets": false,
   "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
   "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-140 · Chi tiết yêu cầu, ước tính, bước đang chạy

::: dac-ta
**Mục đích.** Chi tiết yêu cầu, ước tính, bước đang chạy.

**Phương thức, đường dẫn.** `GET /api/ops/v1/tenant-restores/{requestId}`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-054, FR-18-055.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết yêu cầu, ước tính, bước đang chạy. Quyền PERM-18-backup; FR-18-054, 055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-141 · Gửi duyệt yêu cầu

::: dac-ta
**Mục đích.** Gửi duyệt yêu cầu.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores/{requestId}:submit`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-054.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-056, ERR-18-057, ERR-18-058, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi duyệt yêu cầu. Quyền PERM-18-backup; FR-18-054.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:submit
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-142 · PA duyệt, tạo Job `dh-tenant-restore`

::: dac-ta
**Mục đích.** PA duyệt, tạo Job `dh-tenant-restore`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores/{requestId}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-055.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RestoreApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PA duyệt (người thứ hai, ERR-18-005), tạo Job `dh-tenant-restore` trong `dh-batch`; tenant chuyển `SUSPENDED` trong khi chạy tám bước (RBK-04).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh", "maintenanceNotice": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-143 · Từ chối kèm lý do

::: dac-ta
**Mục đích.** Từ chối kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores/{requestId}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-055.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối kèm lý do. Quyền PERM-18-approve; FR-18-055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-144 · Hủy yêu cầu chưa chạy

::: dac-ta
**Mục đích.** Hủy yêu cầu chưa chạy.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores/{requestId}:cancel`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-054.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy yêu cầu chưa chạy. Quyền PERM-18-backup; FR-18-054.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:cancel
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-145 · Tám bước, thời gian, số dòng thay thế theo bảng

::: dac-ta
**Mục đích.** Tám bước, thời gian, số dòng thay thế theo bảng.

**Phương thức, đường dẫn.** `GET /api/ops/v1/tenant-restores/{requestId}/steps`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-055.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantRestoreStepList`; trường bắt buộc: `requestNo`, `items`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tám bước, thời gian, số dòng thay thế theo bảng. Quyền PERM-18-backup; FR-18-055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4/steps
```

```http
HTTP/1.1 200 OK

{"requestNo": "KP-2026-0002",
 "items": [{"stepNo": 1, "stepCode": "SUSPEND_TENANT", "status": "PENDING"}]}
```

#### API-18-146 · Quay lui khi bước 5 đến 8 lỗi (từ bản trích trước khi thay)

::: dac-ta
**Mục đích.** Quay lui khi bước 5 đến 8 lỗi (từ bản trích trước khi thay).

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-restores/{requestId}:rollback`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-055.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantRestore`; trường bắt buộc: `version`, `id`, `requestNo`, `targetTime`, `scope`, `includeObjects`, `includeIdentity`, `includeSecrets`, `reason`, `status`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quay lui khi bước 5 đến 8 lỗi (từ bản trích trước khi thay). Quyền PERM-18-approve; FR-18-055.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-restores/0190a1b2-c3d4-7e5f-8a6b-510ff634fce4:rollback
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "requestNo": "KP-2026-0002", "targetTime": "2026-11-26T08:00:00+07:00",
 "scope": "FULL_TENANT", "modules": ["ph01_onboarding"], "includeObjects": true,
 "includeIdentity": false, "includeSecrets": false,
 "reason": "Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026",
 "status": "PENDING_APPROVAL", "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "estimate": {"sizeGb": 38.5, "durationMinutes": 12, "tables": 12}, "currentStep": 12,
 "jobName": "dh-tenant-restore-t68-0002", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rowsReplaced": 12}
```

#### API-18-147 · Tạo lệnh xuất dữ liệu tenant (bàn giao, chuyển ô)

::: dac-ta
**Mục đích.** Tạo lệnh xuất dữ liệu tenant (bàn giao, chuyển ô).

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-exports`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantExportInput`; trường bắt buộc: `purpose`, `format`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TenantExport`; trường bắt buộc: `version`, `id`, `exportCode`, `purpose`, `includeObjects`, `format`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-057, ERR-18-059, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo lệnh xuất dữ liệu tenant (bàn giao, chuyển ô). Quyền PERM-18-backup; FR-18-056.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-exports
Idempotency-Key: dh-2026-11-27-0001

{"purpose": "HANDOVER", "includeObjects": true, "format": "PG_COPY",
 "recipientRef": {"kind": "USER", "ref": "tran.thi.binh"},
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/tenant-exports/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "exportCode": "XT-2026-0003", "purpose": "HANDOVER", "includeObjects": true,
 "format": "PG_COPY", "recipientRef": {"kind": "USER", "ref": "tran.thi.binh"},
 "status": "RUNNING", "sizeBytes": 12,
 "manifestSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "expiresAt": "2026-11-27T09:15:02+07:00", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

#### API-18-148 · Chi tiết lệnh xuất, kích thước, tổng kiểm tra

::: dac-ta
**Mục đích.** Chi tiết lệnh xuất, kích thước, tổng kiểm tra.

**Phương thức, đường dẫn.** `GET /api/ops/v1/tenant-exports/{exportId}`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-056.

**Tham số.** `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantExport`; trường bắt buộc: `version`, `id`, `exportCode`, `purpose`, `includeObjects`, `format`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết lệnh xuất, kích thước, tổng kiểm tra. Quyền PERM-18-backup; FR-18-056.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/tenant-exports/0190a1b2-c3d4-7e5f-8a6b-013b012140e3
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "exportCode": "XT-2026-0003", "purpose": "HANDOVER", "includeObjects": true,
 "format": "PG_COPY", "recipientRef": {"kind": "USER", "ref": "tran.thi.binh"},
 "status": "RUNNING", "sizeBytes": 12,
 "manifestSha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "expiresAt": "2026-11-27T09:15:02+07:00", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

#### API-18-149 · Cấp liên kết tải có hạn 24 giờ, ghi kiểm toán

::: dac-ta
**Mục đích.** Cấp liên kết tải có hạn 24 giờ, ghi kiểm toán.

**Phương thức, đường dẫn.** `POST /api/ops/v1/tenant-exports/{exportId}:download-link`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-056.

**Tham số.** `exportId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `DownloadLink`; trường bắt buộc: `url`, `expiresAt`, `sha256`, `sizeBytes`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cấp liên kết tải có hạn 24 giờ, ghi kiểm toán. Quyền PERM-18-backup; FR-18-056.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/tenant-exports/0190a1b2-c3d4-7e5f-8a6b-013b012140e3:download-link
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK

{"url": "https://ops.t68.datahub.example.vn/tai-ve/XT-2026-0003",
 "expiresAt": "2026-11-27T09:15:02+07:00",
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "sizeBytes": 12}
```

#### API-18-150 · PH-20 yêu cầu chuyển dữ liệu một phân hệ khi sáp nhập tenant (`mergePlanId`, `module`, `dryRun`)

::: dac-ta
**Mục đích.** PH-20 yêu cầu chuyển dữ liệu một phân hệ khi sáp nhập tenant (`mergePlanId`, `module`, `dryRun`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/merge-transfers`.

**Quyền.** scope ops:merge-transfer.

**FR hiện thực.** FR-18-057.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MergeTransferInput`; trường bắt buộc: `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergeTransfer`; trường bắt buộc: `version`, `id`, `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-060, ERR-18-061 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-20 gọi khi điều phối sáp nhập (hợp đồng 27/11). Chạy `dh-tenant-export` và nạp cho `module`, giữ `id` gốc và `origin_tenant_id`; báo tiến độ về `POST /internal/tenant/v1/merge-plans/{id}/participants/{module}:report` của PH-20. Trùng `mergePlanId` và `module` với thân khác: ERR-18-061.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/merge-transfers
Idempotency-Key: dh-2026-11-27-0001

{"mergePlanId": "0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60", "module": "ph01_onboarding",
 "sourceTenant": "T67", "targetTenant": "T68",
 "mappingRef": "ph20/merge-plans/MP-0003/mappings/ph01", "dryRun": true}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "mergePlanId": "0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60", "module": "ph01_onboarding",
 "sourceTenant": "T68", "targetTenant": "T68",
 "mappingRef": "ph20/merge-plans/MP-0003/mappings/ph01", "dryRun": true,
 "status": "RUNNING", "progressPercent": 42.5, "rowsRead": 12, "rowsLoaded": 12,
 "rowsConflicted": 12, "rowsFailed": 12, "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "lastReportedAt": "2026-11-27T09:15:02+07:00",
 "reportStatus": "PENDING", "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

#### API-18-151 · Danh sách chuyển sáp nhập theo `mergePlanId`

::: dac-ta
**Mục đích.** Danh sách chuyển sáp nhập theo `mergePlanId`.

**Phương thức, đường dẫn.** `GET /api/ops/v1/merge-transfers`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-057.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `mergePlanId` (query, string, bắt buộc); `module` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergeTransferPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách chuyển sáp nhập theo `mergePlanId`. Quyền PERM-18-backup; FR-18-057.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/merge-transfers?mergePlanId=0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "mergePlanId": "0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60", "module": "ph01_onboarding",
   "sourceTenant": "T68", "targetTenant": "T68",
   "mappingRef": "ph20/merge-plans/MP-0003/mappings/ph01", "dryRun": true,
   "status": "RUNNING"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-152 · Tiến độ, số bản ghi, lỗi của một chuyển

::: dac-ta
**Mục đích.** Tiến độ, số bản ghi, lỗi của một chuyển.

**Phương thức, đường dẫn.** `GET /api/ops/v1/merge-transfers/{transferId}`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-057.

**Tham số.** `transferId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergeTransfer`; trường bắt buộc: `version`, `id`, `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiến độ, số bản ghi, lỗi của một chuyển. Quyền PERM-18-backup; FR-18-057.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/merge-transfers/0190a1b2-c3d4-7e5f-8a6b-54694150980a
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "mergePlanId": "0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60", "module": "ph01_onboarding",
 "sourceTenant": "T68", "targetTenant": "T68",
 "mappingRef": "ph20/merge-plans/MP-0003/mappings/ph01", "dryRun": true,
 "status": "RUNNING", "progressPercent": 42.5, "rowsRead": 12, "rowsLoaded": 12,
 "rowsConflicted": 12, "rowsFailed": 12, "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "lastReportedAt": "2026-11-27T09:15:02+07:00",
 "reportStatus": "PENDING", "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

#### API-18-153 · PH-20 hủy chuyển chưa xong

::: dac-ta
**Mục đích.** PH-20 hủy chuyển chưa xong.

**Phương thức, đường dẫn.** `POST /api/ops/v1/merge-transfers/{transferId}:cancel`.

**Quyền.** scope ops:merge-transfer.

**FR hiện thực.** FR-18-057.

**Tham số.** `transferId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergeTransfer`; trường bắt buộc: `version`, `id`, `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-20 hủy chuyển chưa xong. Quyền scope ops:merge-transfer; FR-18-057.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/merge-transfers/0190a1b2-c3d4-7e5f-8a6b-54694150980a:cancel
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "mergePlanId": "0190a1b2-c3d4-7e5f-8a6b-4438ed8a0b60", "module": "ph01_onboarding",
 "sourceTenant": "T68", "targetTenant": "T68",
 "mappingRef": "ph20/merge-plans/MP-0003/mappings/ph01", "dryRun": true,
 "status": "RUNNING", "progressPercent": 42.5, "rowsRead": 12, "rowsLoaded": 12,
 "rowsConflicted": 12, "rowsFailed": 12, "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "lastReportedAt": "2026-11-27T09:15:02+07:00",
 "reportStatus": "PENDING", "errorMessage": "Hệ đích trả 503 sau 3 lần thử"}
```

#### API-18-154 · Danh sách diễn tập DR, PITR toàn cụm đã ghi nhận

::: dac-ta
**Mục đích.** Danh sách diễn tập DR, PITR toàn cụm đã ghi nhận.

**Phương thức, đường dẫn.** `GET /api/ops/v1/dr-drills`.

**Quyền.** `PERM-18-backup`.

**FR hiện thực.** FR-18-058.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `kind` (query, DrillKind, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DrDrillPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách diễn tập DR, PITR toàn cụm đã ghi nhận. Quyền PERM-18-backup; FR-18-058.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/dr-drills
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "drillCode": "DT-2026-0001",
   "kind": "DR_SWITCHOVER", "startedAt": "2026-11-27T02:00:00+07:00",
   "finishedAt": "2026-11-27T02:40:00+07:00", "result": "PASSED",
   "recordedBy": "nguyen.van.an"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-155 · Ghi nhận diễn tập: loại, thời điểm, RTO, RPO đo được, biên bản

::: dac-ta
**Mục đích.** Ghi nhận diễn tập: loại, thời điểm, RTO, RPO đo được, biên bản.

**Phương thức, đường dẫn.** `POST /api/ops/v1/dr-drills`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-058.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DrDrillInput`; trường bắt buộc: `kind`, `startedAt`, `finishedAt`, `result`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `DrDrill`; trường bắt buộc: `version`, `id`, `drillCode`, `kind`, `startedAt`, `finishedAt`, `result`, `recordedBy`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi nhận diễn tập: loại, thời điểm, RTO, RPO đo được, biên bản. Quyền PERM-18-admin; FR-18-058.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/dr-drills
Idempotency-Key: dh-2026-11-27-0001

{"kind": "DR_SWITCHOVER", "startedAt": "2026-11-27T02:00:00+07:00",
 "finishedAt": "2026-11-27T02:40:00+07:00", "rtoMeasuredMinutes": 12,
 "rpoMeasuredSeconds": 12, "result": "PASSED", "issues": ["Chuyển DNS lâu hơn dự kiến"],
 "evidenceRef": "garage://dh-t68-ops/bien-ban/DT-2026-0001.pdf"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/dr-drills/0190a1b2-c3d4-7e5f-8a6b-b80bb7740288
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "drillCode": "DT-2026-0001", "kind": "DR_SWITCHOVER",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "rtoMeasuredMinutes": 12, "rpoMeasuredSeconds": 12, "result": "PASSED",
 "issues": ["Chuyển DNS lâu hơn dự kiến"],
 "evidenceRef": "garage://dh-t68-ops/bien-ban/DT-2026-0001.pdf",
 "recordedBy": "nguyen.van.an"}
```

### 14.9. Di trú và chạy song song

Nguồn hệ cũ chỉ đọc, kế hoạch di trú, chạy thử và chạy thật có bốn mắt, bản ghi lỗi, đối chiếu, cấp lại thông tin xác thực, chạy song song, mẫu so sánh bóng, cắt chuyển và quay lui (FR-18-059…068). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-156 · Danh sách nguồn hệ cũ và trạng thái kết nối

::: dac-ta
**Mục đích.** Danh sách nguồn hệ cũ và trạng thái kết nối.

**Phương thức, đường dẫn.** `GET /api/ops/v1/legacy-sources`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-059.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `legacySystem` (query, LegacySystem, tùy chọn); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacySourcePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách nguồn hệ cũ và trạng thái kết nối. Quyền PERM-18-migration; FR-18-059.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/legacy-sources
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "sourceCode": "esb-bus-cu",
   "name": "Bus tích hợp cũ", "legacySystem": "BUS",
   "jdbcUrl": "jdbc:postgresql://bus-cu.t68.local:5432/esb",
   "credentialRef": "kv/dh/t68/legacy/esb-bus", "schemas": ["esb"], "status": "DRAFT",
   "readOnlyVerified": true}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-157 · Khai báo nguồn hệ cũ (JDBC chỉ đọc, tham chiếu OpenBao)

::: dac-ta
**Mục đích.** Khai báo nguồn hệ cũ (JDBC chỉ đọc, tham chiếu OpenBao).

**Phương thức, đường dẫn.** `POST /api/ops/v1/legacy-sources`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-059.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegacySourceInput`; trường bắt buộc: `sourceCode`, `name`, `legacySystem`, `jdbcUrl`, `credentialRef`, `schemas`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LegacySource`; trường bắt buộc: `version`, `id`, `sourceCode`, `name`, `legacySystem`, `jdbcUrl`, `credentialRef`, `schemas`, `status`, `readOnlyVerified`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-062, ERR-18-070, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khai báo nguồn hệ cũ (JDBC chỉ đọc, tham chiếu OpenBao). Quyền PERM-18-migration; FR-18-059.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/legacy-sources
Idempotency-Key: dh-2026-11-27-0001

{"sourceCode": "esb-bus-cu", "name": "Bus tích hợp cũ", "legacySystem": "BUS",
 "jdbcUrl": "jdbc:postgresql://bus-cu.t68.local:5432/esb",
 "credentialRef": "kv/dh/t68/legacy/esb-bus", "schemas": ["esb"],
 "networkZone": "VUNG-HE-CU"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/legacy-sources/esb-bus-cu
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "sourceCode": "esb-bus-cu", "name": "Bus tích hợp cũ", "legacySystem": "BUS",
 "jdbcUrl": "jdbc:postgresql://bus-cu.t68.local:5432/esb",
 "credentialRef": "kv/dh/t68/legacy/esb-bus", "schemas": ["esb"],
 "networkZone": "VUNG-HE-CU", "status": "DRAFT", "readOnlyVerified": true,
 "verifiedAt": "2026-11-27T09:15:02+07:00", "tables": 12, "estimatedRows": 12}
```

#### API-18-158 · Thử kết nối, kiểm quyền chỉ đọc, đếm bảng

::: dac-ta
**Mục đích.** Thử kết nối, kiểm quyền chỉ đọc, đếm bảng.

**Phương thức, đường dẫn.** `POST /api/ops/v1/legacy-sources/{sourceCode}:test-connection`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-059.

**Tham số.** `sourceCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ConnectionTestResult`; trường bắt buộc: `ok`, `readOnly`, `tables`, `estimatedRows`, `checkedAt`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-062, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thử kết nối, kiểm quyền chỉ đọc, đếm bảng. Quyền PERM-18-migration; FR-18-059.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/legacy-sources/esb-bus-cu:test-connection
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK

{"ok": true, "readOnly": true, "tables": 12, "estimatedRows": 12, "latencyMs": 12,
 "errorCode": "ERR-04-101", "checkedAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-159 · Danh sách kế hoạch di trú

::: dac-ta
**Mục đích.** Danh sách kế hoạch di trú.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-plans`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-060.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `sourceCode` (query, string, tùy chọn); `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationPlanPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách kế hoạch di trú. Quyền PERM-18-migration; FR-18-060.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-plans
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "planCode": "DT-BUS-01",
   "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1", "status": "DRAFT",
   "itemCount": 12}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-160 · Tạo kế hoạch di trú cho nguồn

::: dac-ta
**Mục đích.** Tạo kế hoạch di trú cho nguồn.

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-plans`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-060.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationPlanInput`; trường bắt buộc: `planCode`, `sourceCode`, `title`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `MigrationPlan`; trường bắt buộc: `version`, `id`, `planCode`, `sourceCode`, `title`, `status`, `itemCount`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo kế hoạch di trú cho nguồn. Quyền PERM-18-migration; FR-18-060.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-plans
Idempotency-Key: dh-2026-11-27-0001

{"planCode": "DT-BUS-01", "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "targetCutoverDate": "2027-03-01"}
```

```http
HTTP/1.1 201 Created
Location: /api/ops/v1/migration-plans/DT-BUS-01
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "status": "DRAFT",
 "readyAt": "2026-11-27T09:15:02+07:00", "readyBy": "nguyen.van.an",
 "targetCutoverDate": "2027-03-01", "itemCount": 12}
```

#### API-18-161 · Chi tiết kế hoạch, thứ tự đối tượng, lần chạy

::: dac-ta
**Mục đích.** Chi tiết kế hoạch, thứ tự đối tượng, lần chạy.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-plans/{planCode}`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-060.

**Tham số.** `planCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationPlanDetail`; trường bắt buộc: `version`, `id`, `planCode`, `sourceCode`, `title`, `status`, `itemCount`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết kế hoạch, thứ tự đối tượng, lần chạy. Quyền PERM-18-migration; FR-18-060.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-plans/DT-BUS-01
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "status": "DRAFT",
 "readyAt": "2026-11-27T09:15:02+07:00", "readyBy": "nguyen.van.an",
 "targetCutoverDate": "2027-03-01", "itemCount": 12,
 "items": [{"objectType": "FLOW", "converter": "bus-flow-xml-v1", "targetPh": "PH-04", "order": 1,
   "enabled": true}], "computedOrder": ["FLOW"],
 "runs": [{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "runNo": 2, "mode": "DRY_RUN",
   "status": "QUEUED"}]}
```

#### API-18-162 · Ghi danh sách loại đối tượng, bộ chuyển, PH đích, thứ tự (`If-Match`)

::: dac-ta
**Mục đích.** Ghi danh sách loại đối tượng, bộ chuyển, PH đích, thứ tự (`If-Match`).

**Phương thức, đường dẫn.** `PUT /api/ops/v1/migration-plans/{planCode}/items`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-060.

**Tham số.** `planCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationPlanItemsInput`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationPlanDetail`; trường bắt buộc: `version`, `id`, `planCode`, `sourceCode`, `title`, `status`, `itemCount`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-063, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi danh sách loại đối tượng, bộ chuyển, PH đích, thứ tự (`If-Match`). Quyền PERM-18-migration; FR-18-060.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/migration-plans/DT-BUS-01/items
If-Match: W/"3"

{"items": [{"objectType": "FLOW", "converter": "bus-flow-xml-v1", "targetPh": "PH-04", "order": 1}]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "status": "DRAFT",
 "readyAt": "2026-11-27T09:15:02+07:00", "readyBy": "nguyen.van.an",
 "targetCutoverDate": "2027-03-01", "itemCount": 12,
 "items": [{"objectType": "FLOW", "converter": "bus-flow-xml-v1", "targetPh": "PH-04", "order": 1,
   "enabled": true}], "computedOrder": ["FLOW"],
 "runs": [{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "runNo": 2, "mode": "DRY_RUN",
   "status": "QUEUED"}]}
```

#### API-18-163 · Kiểm thứ tự phụ thuộc, chuyển `READY`

::: dac-ta
**Mục đích.** Kiểm thứ tự phụ thuộc, chuyển `READY`.

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-plans/{planCode}:mark-ready`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-060.

**Tham số.** `planCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MigrationPlanDetail`; trường bắt buộc: `version`, `id`, `planCode`, `sourceCode`, `title`, `status`, `itemCount`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-063, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm thứ tự phụ thuộc, chuyển `READY`. Quyền PERM-18-migration; FR-18-060.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-plans/DT-BUS-01:mark-ready
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "sourceCode": "esb-bus-cu", "title": "Di trú Bus cũ đợt 1",
 "description": "Mô tả ngắn phục vụ vận hành tỉnh", "status": "DRAFT",
 "readyAt": "2026-11-27T09:15:02+07:00", "readyBy": "nguyen.van.an",
 "targetCutoverDate": "2027-03-01", "itemCount": 12,
 "items": [{"objectType": "FLOW", "converter": "bus-flow-xml-v1", "targetPh": "PH-04", "order": 1,
   "enabled": true}], "computedOrder": ["FLOW"],
 "runs": [{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "runNo": 2, "mode": "DRY_RUN",
   "status": "QUEUED"}]}
```

#### API-18-164 · Tạo lần chạy `DRY_RUN` hoặc `REAL`, hoặc chạy lại bản ghi lỗi

::: dac-ta
**Mục đích.** Tạo lần chạy `DRY_RUN` hoặc `REAL`, hoặc chạy lại bản ghi lỗi.

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-runs`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-061, FR-18-062, FR-18-063.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationRunInput`; trường bắt buộc: `planCode`, `mode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MigrationRun`; trường bắt buộc: `version`, `id`, `planCode`, `runNo`, `mode`, `status`, `requestedBy`, `read`, `written`, `rejected`, `skipped`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-036, ERR-18-051, ERR-18-057, ERR-18-064, ERR-18-065, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lần chạy `DRY_RUN` vào hàng đợi ngay; `REAL` cần lần chạy thử thành công trong `18.migration.dry-run-valid-days` (ERR-18-064), ở `PENDING_APPROVAL` chờ API-18-167. `retryOf` và `errorIds[]` chạy lại bản ghi lỗi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-runs
Idempotency-Key: dh-2026-11-27-0001

{"planCode": "DT-BUS-01", "mode": "DRY_RUN", "items": ["FLOW"], "sampleLimit": 12,
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365",
 "errorIds": ["0190a1b2-c3d4-7e5f-8a6b-ec7a7ff9dcd8"],
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED",
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365", "sampleLimit": 12,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "read": 12, "written": 12, "rejected": 12, "skipped": 48,
 "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
   "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}
```

#### API-18-165 · Danh sách lần chạy theo kế hoạch

::: dac-ta
**Mục đích.** Danh sách lần chạy theo kế hoạch.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-runs`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-061, FR-18-062.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `planCode` (query, string, bắt buộc); `mode` (query, RunMode, tùy chọn); `status` (query, MigrationRunStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationRunPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách lần chạy theo kế hoạch. Quyền PERM-18-migration; FR-18-061, 062.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-runs?planCode=DT-BUS-01
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "planCode": "DT-BUS-01",
   "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED", "requestedBy": "nguyen.van.an",
   "read": 12, "written": 12, "rejected": 12, "skipped": 48,
   "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
     "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-166 · Tiến độ, số bản ghi theo đối tượng, trạng thái

::: dac-ta
**Mục đích.** Tiến độ, số bản ghi theo đối tượng, trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-runs/{runId}`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-061, FR-18-062.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationRun`; trường bắt buộc: `version`, `id`, `planCode`, `runNo`, `mode`, `status`, `requestedBy`, `read`, `written`, `rejected`, `skipped`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiến độ, số bản ghi theo đối tượng, trạng thái. Quyền PERM-18-migration; FR-18-061, 062.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED",
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365", "sampleLimit": 12,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "read": 12, "written": 12, "rejected": 12, "skipped": 48,
 "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
   "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}
```

#### API-18-167 · Duyệt chạy thật (người thứ hai)

::: dac-ta
**Mục đích.** Duyệt chạy thật (người thứ hai).

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-runs/{runId}:approve`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-062.

**Tham số.** `runId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MigrationRun`; trường bắt buộc: `version`, `id`, `planCode`, `runNo`, `mode`, `status`, `requestedBy`, `read`, `written`, `rejected`, `skipped`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-051, ERR-18-064, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt chạy thật (người thứ hai); không chạy được trong cửa sổ đóng băng (ERR-18-051).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1:approve
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED",
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365", "sampleLimit": 12,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "read": 12, "written": 12, "rejected": 12, "skipped": 48,
 "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
   "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}
```

#### API-18-168 · Từ chối chạy thật kèm lý do

::: dac-ta
**Mục đích.** Từ chối chạy thật kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-runs/{runId}:reject`.

**Quyền.** `PERM-18-approve`.

**FR hiện thực.** FR-18-062.

**Tham số.** `runId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectInput`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MigrationRun`; trường bắt buộc: `version`, `id`, `planCode`, `runNo`, `mode`, `status`, `requestedBy`, `read`, `written`, `rejected`, `skipped`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối chạy thật kèm lý do. Quyền PERM-18-approve; FR-18-062.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1:reject
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED",
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365", "sampleLimit": 12,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "read": 12, "written": 12, "rejected": 12, "skipped": 48,
 "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
   "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}
```

#### API-18-169 · Hủy lần chạy, dừng sau lô hiện hành

::: dac-ta
**Mục đích.** Hủy lần chạy, dừng sau lô hiện hành.

**Phương thức, đường dẫn.** `POST /api/ops/v1/migration-runs/{runId}:cancel`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-061, FR-18-062.

**Tham số.** `runId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CancelInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MigrationRun`; trường bắt buộc: `version`, `id`, `planCode`, `runNo`, `mode`, `status`, `requestedBy`, `read`, `written`, `rejected`, `skipped`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy lần chạy, dừng sau lô hiện hành. Quyền PERM-18-migration; FR-18-061, 062.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1:cancel
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "planCode": "DT-BUS-01", "runNo": 2, "mode": "DRY_RUN", "status": "QUEUED",
 "basedOnDryRun": "0190a1b2-c3d4-7e5f-8a6b-2ad636164a69",
 "retryOf": "0190a1b2-c3d4-7e5f-8a6b-c769cb458365", "sampleLimit": 12,
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "requestedBy": "nguyen.van.an", "approvedBy": "le.thi.chi",
 "approvedAt": "2026-11-27T09:15:02+07:00",
 "rejectComment": "Bộ lọc quá rộng, cần thu hẹp theo luồng",
 "startedAt": "2026-11-27T02:00:00+07:00", "finishedAt": "2026-11-27T02:40:00+07:00",
 "read": 12, "written": 12, "rejected": 12, "skipped": 48,
 "items": [{"objectType": "FLOW", "targetPh": "PH-04", "status": "RUNNING", "read": 12,
   "converted": 12, "written": 12, "rejected": 12, "skipped": 48}]}
```

#### API-18-170 · Danh sách bản ghi lỗi, lý do, xuất CSV

::: dac-ta
**Mục đích.** Danh sách bản ghi lỗi, lý do, xuất CSV.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-runs/{runId}/errors`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-063.

**Tham số.** `runId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `objectType` (query, ObjectType, tùy chọn); `reasonCode` (query, string, tùy chọn); `status` (query, MigrationErrorStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationErrorRecordPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách bản ghi lỗi, lý do, xuất CSV. Quyền PERM-18-migration; FR-18-063.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1/errors
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
   "runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "objectType": "FLOW",
   "sourceRecordRef": "dm_don_vi:H68.12", "reasonCode": "MISSING_PARENT",
   "message": "Thiếu đơn vị cha của mã H68.12", "status": "OPEN"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-171 · Báo cáo đối chiếu số lượng, tổng kiểm tra; tải PDF, CSV

::: dac-ta
**Mục đích.** Báo cáo đối chiếu số lượng, tổng kiểm tra; tải PDF, CSV.

**Phương thức, đường dẫn.** `GET /api/ops/v1/migration-runs/{runId}/reconciliation`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-064.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MigrationReconciliationReport`; trường bắt buộc: `runId`, `planCode`, `matched`, `computedAt`, `items`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Báo cáo đối chiếu số lượng, tổng kiểm tra; tải PDF, CSV. Quyền PERM-18-migration; FR-18-064.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1/reconciliation
```

```http
HTTP/1.1 200 OK

{"runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "planCode": "DT-BUS-01", "matched": true,
 "computedAt": "2026-11-27T09:15:02+07:00",
 "items": [{"objectType": "FLOW", "sourceCount": 12, "targetCount": 12, "missing": 12, "extra": 12,
   "mismatched": 12, "checksumAlgo": "SHA256", "matched": true}],
 "downloadPdf": "/api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-000000000011/reconciliation?format=pdf",
 "downloadCsv": "/api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-000000000011/reconciliation?format=csv"}
```

#### API-18-172 · Danh sách thông tin xác thực cần cấp lại theo HTTT, trạng thái

::: dac-ta
**Mục đích.** Danh sách thông tin xác thực cần cấp lại theo HTTT, trạng thái.

**Phương thức, đường dẫn.** `GET /api/ops/v1/credential-reissues`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-065.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `systemCode` (query, string, tùy chọn); `status` (query, string, tùy chọn); `credentialKind` (query, CredentialKind, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialReissuePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách thông tin xác thực cần cấp lại theo HTTT, trạng thái. Quyền PERM-18-migration; FR-18-065.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/credential-reissues
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "systemCode": "HTTT-QLVB",
   "applicationRef": "app-qlvb", "credentialKind": "OAUTH_CLIENT", "targetPh": "PH-04",
   "runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "status": "PENDING"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-18-173 · Nhóm dịch vụ chạy song song, trạng thái cầu nối, tỷ lệ khớp

::: dac-ta
**Mục đích.** Nhóm dịch vụ chạy song song, trạng thái cầu nối, tỷ lệ khớp.

**Phương thức, đường dẫn.** `GET /api/ops/v1/parallel-groups`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-066, FR-18-067.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `status` (query, CutoverStatus, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParallelGroupPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhóm dịch vụ chạy song song, trạng thái cầu nối, tỷ lệ khớp. Quyền PERM-18-migration; FR-18-066, 067.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/parallel-groups
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "groupCode": "NHOM-HO-TICH",
   "title": "Nhóm dịch vụ tra cứu hộ tịch", "routes": ["/api/ho-tich/v1/khai-sinh"],
   "status": "SHADOW_OK", "mirrorPercent": 5, "matchThresholdPercent": 99.5,
   "samplesTotal": 12, "samplesMatched": 12}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-174 · Chi tiết nhóm, mẫu so sánh lệch, danh sách kiểm tra cắt chuyển, sổ cắt chuyển

::: dac-ta
**Mục đích.** Chi tiết nhóm, mẫu so sánh lệch, danh sách kiểm tra cắt chuyển, sổ cắt chuyển.

**Phương thức, đường dẫn.** `GET /api/ops/v1/parallel-groups/{groupCode}`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-066, FR-18-067, FR-18-068.

**Tham số.** `groupCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParallelGroupDetail`; trường bắt buộc: `version`, `id`, `groupCode`, `title`, `routes`, `status`, `mirrorPercent`, `matchThresholdPercent`, `samplesTotal`, `samplesMatched`, `mismatchSamples`, `checklist`, `log`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-18-001, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết nhóm, mẫu so sánh lệch, danh sách kiểm tra cắt chuyển, sổ cắt chuyển. Quyền PERM-18-migration; FR-18-066, 067, 068.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/parallel-groups/NHOM-HO-TICH
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "groupCode": "NHOM-HO-TICH", "title": "Nhóm dịch vụ tra cứu hộ tịch",
 "planCode": "DT-BUS-01", "routes": ["/api/ho-tich/v1/khai-sinh"], "status": "SHADOW_OK",
 "mirrorPercent": 5, "matchThresholdPercent": 99.5, "matchRate": 99.6, "samplesTotal": 12,
 "samplesMatched": 12, "bridgeState": "NONE", "trafficPercent": 20,
 "cutoverAt": "2026-11-27T09:15:02+07:00", "rollbackUntil": "2026-11-27T09:15:02+07:00",
 "rolledBackAt": "2026-11-27T09:15:02+07:00",
 "mismatchSamples": [{"sampledAt": "2026-11-27T09:15:02+07:00", "route": "/api/ho-tich/v1/khai-sinh",
   "legacyStatus": 200, "datahubStatus": 200, "matched": true}],
 "checklist": [{"itemCode": "DLQ_EMPTY", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
   "checkKind": "AUTO", "status": "PENDING"}],
 "log": [{"action": "PARTIAL_CUTOVER", "actor": "tran.thi.binh",
   "occurredAt": "2026-11-27T09:15:02+07:00"}]}
```

#### API-18-175 · Cắt chuyển theo `action`: `REQUEST` đề nghị cắt chuyển một phần hoặc toàn phần, `APPROVE`, `REJECT` (bốn mắt, `PERM-18-approve`), `ROLLBACK` quay lui (`PERM-18-migration`)

::: dac-ta
**Mục đích.** Cắt chuyển theo `action`: `REQUEST` đề nghị cắt chuyển một phần hoặc toàn phần, `APPROVE`, `REJECT` (bốn mắt, `PERM-18-approve`), `ROLLBACK` quay lui (`PERM-18-migration`).

**Phương thức, đường dẫn.** `POST /api/ops/v1/parallel-groups/{groupCode}:transition`.

**Quyền.** `PERM-18-migration / PERM-18-approve`.

**FR hiện thực.** FR-18-068.

**Tham số.** `groupCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CutoverTransitionInput`; trường bắt buộc: `action`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ParallelGroup`; trường bắt buộc: `version`, `id`, `groupCode`, `title`, `routes`, `status`, `mirrorPercent`, `matchThresholdPercent`, `samplesTotal`, `samplesMatched`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-005, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-051, ERR-18-066, ERR-18-067, ERR-18-068, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thân `action` quyết định thao tác và quyền: `REQUEST` (đề nghị cắt chuyển một phần hoặc toàn phần theo `target`, `PERM-18-migration`), `APPROVE`, `REJECT` (bốn mắt, `PERM-18-approve`, người duyệt khác người đề nghị ERR-18-005), `ROLLBACK` (quay lui trong `18.migration.rollback-window-minutes`, ERR-18-068, không cần duyệt). Kiểm danh sách cắt chuyển (ERR-18-067) và tỷ lệ khớp (ERR-18-066); phát EVT-18-27 để PH-03 đổi tuyến APISIX.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/parallel-groups/NHOM-HO-TICH:transition
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"action": "REQUEST", "target": "PARTIAL_CUTOVER", "trafficPercent": 20,
 "reason": "Đạt ngưỡng khớp 7 ngày, cắt chuyển 20% theo kế hoạch tuần 49"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "groupCode": "NHOM-HO-TICH", "title": "Nhóm dịch vụ tra cứu hộ tịch",
 "planCode": "DT-BUS-01", "routes": ["/api/ho-tich/v1/khai-sinh"], "status": "SHADOW_OK",
 "mirrorPercent": 5, "matchThresholdPercent": 99.5, "matchRate": 99.6, "samplesTotal": 12,
 "samplesMatched": 12, "bridgeState": "NONE", "trafficPercent": 20,
 "cutoverAt": "2026-11-27T09:15:02+07:00", "rollbackUntil": "2026-11-27T09:15:02+07:00",
 "rolledBackAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-176 · Bộ so sánh nhận cặp phản hồi cũ và mới đã băm

::: dac-ta
**Mục đích.** Bộ so sánh nhận cặp phản hồi cũ và mới đã băm.

**Phương thức, đường dẫn.** `POST /ops/internal/v1/shadow-samples`.

**Quyền.** scope ops:shadow-ingest; mTLS SPIFFE.

**FR hiện thực.** FR-18-067.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ShadowSampleBatch`; trường bắt buộc: `items`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ShadowAck`; trường bắt buộc: `accepted`, `matched`, `groupMatchRate`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bộ so sánh gửi cặp băm của phản hồi đã chuẩn hóa, không gửi thân phản hồi hay dữ liệu cá nhân (Q18-14).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /ops/internal/v1/shadow-samples

{"items": [{"groupCode": "NHOM-HO-TICH",
   "requestHash": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "route": "/api/ho-tich/v1/khai-sinh", "legacyStatus": 200, "datahubStatus": 200,
   "legacyBodyHash": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "datahubBodyHash": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
   "sampledAt": "2026-11-27T09:15:02+07:00"}]}
```

```http
HTTP/1.1 202 Accepted

{"accepted": 12, "matched": 12, "groupMatchRate": 99.7}
```

#### API-18-182 · Đánh dấu cách xử lý một hoặc nhiều bản ghi lỗi (`FIXED_AT_SOURCE`, `RULE_ADDED`, `WONT_MIGRATE` kèm lý do)

::: dac-ta
**Mục đích.** Đánh dấu cách xử lý một hoặc nhiều bản ghi lỗi (`FIXED_AT_SOURCE`, `RULE_ADDED`, `WONT_MIGRATE` kèm lý do).

**Phương thức, đường dẫn.** `PATCH /api/ops/v1/migration-runs/{runId}/errors`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-063.

**Tham số.** `runId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MigrationErrorFixInput`; trường bắt buộc: `errorIds`, `status`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BulkResult`; trường bắt buộc: `requested`, `succeeded`, `failed`, `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-008, ERR-18-010, ERR-18-036, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đánh dấu cách xử lý cho tối đa 1.000 bản ghi lỗi của lần chạy; `WONT_MIGRATE` cần `reason` ≥ 10 ký tự (ERR-18-007) và được đưa vào báo cáo đối chiếu như chênh lệch đã giải trình. Phản hồi kết quả từng bản ghi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1/errors
If-Match: W/"3"

{"errorIds": ["0190a1b2-c3d4-7e5f-8a6b-ec7a7ff9dcd8"], "status": "FIXED_AT_SOURCE",
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118",
 "ruleRef": "giá trị mẫu"}
```

```http
HTTP/1.1 200 OK

{"requested": 12, "succeeded": 1180, "failed": 12,
 "results": [{"dlqId": "0190a1b2-c3d4-7e5f-8a6b-3431d1c97214", "httpStatus": 201}]}
```

#### API-18-183 · Đánh dấu thông tin xác thực không cần cấp lại (`WAIVED`) kèm lý do

::: dac-ta
**Mục đích.** Đánh dấu thông tin xác thực không cần cấp lại (`WAIVED`) kèm lý do.

**Phương thức, đường dẫn.** `POST /api/ops/v1/credential-reissues/{markerId}:waive`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-065.

**Tham số.** `markerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `CredentialReissue`; trường bắt buộc: `version`, `id`, `systemCode`, `applicationRef`, `credentialKind`, `targetPh`, `runId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dấu `PENDING` hoặc `NOTIFIED` chuyển `WAIVED` kèm lý do; dấu đã `REISSUED` trả ERR-18-006. Mục danh sách cắt chuyển `CREDENTIALS_REISSUED` tính `WAIVED` như đã đạt.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/credential-reissues/0190a1b2-c3d4-7e5f-8a6b-7f5f22681984:waive
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "systemCode": "HTTT-QLVB", "applicationRef": "app-qlvb", "credentialKind": "OAUTH_CLIENT",
 "targetPh": "PH-04", "runId": "0190a1b2-c3d4-7e5f-8a6b-45f9669b01c1", "status": "PENDING",
 "notifiedAt": "2026-11-27T09:15:02+07:00", "reissuedAt": "2026-11-27T09:15:02+07:00",
 "waivedReason": "HTTT đã ngừng"}
```

#### API-18-184 · Thay bộ quy tắc chuẩn hóa so sánh của nhóm; mẫu trong cửa sổ được tính lại

::: dac-ta
**Mục đích.** Thay bộ quy tắc chuẩn hóa so sánh của nhóm; mẫu trong cửa sổ được tính lại.

**Phương thức, đường dẫn.** `PUT /api/ops/v1/parallel-groups/{groupCode}/normalization-rules`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-067.

**Tham số.** `groupCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NormalizationRulesInput`; trường bắt buộc: `rules`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NormalizationRuleSet`; trường bắt buộc: `version`, `id`, `groupCode`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-007, ERR-18-008, ERR-18-010, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thay toàn bộ bộ quy tắc chuẩn hóa của nhóm (`If-Match`, lý do); bộ so sánh nhận quy tắc mới, mẫu trong cửa sổ 7 ngày được tính lại và tỷ lệ khớp cập nhật.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/ops/v1/parallel-groups/NHOM-HO-TICH/normalization-rules
If-Match: W/"3"

{"rules": [{"kind": "IGNORE_FIELD", "path": "$.trangThai"}],
 "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "groupCode": "NHOM-HO-TICH", "rules": [{"kind": "IGNORE_FIELD", "path": "$.trangThai"}],
 "recomputedSamples": 12, "matchRate": 99.6}
```

#### API-18-185 · Xác nhận một mục kiểm tay của danh sách cắt chuyển kèm bằng chứng

::: dac-ta
**Mục đích.** Xác nhận một mục kiểm tay của danh sách cắt chuyển kèm bằng chứng.

**Phương thức, đường dẫn.** `POST /api/ops/v1/parallel-groups/{groupCode}/checklist/{itemCode}:confirm`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-18-068.

**Tham số.** `groupCode` (path, string, bắt buộc); `itemCode` (path, ChecklistItemCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ChecklistConfirmInput`; trường bắt buộc: `evidence`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `CutoverChecklistItem`; trường bắt buộc: `itemCode`, `description`, `checkKind`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-18-001, ERR-18-003, ERR-18-004, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-067, ERR-18-071 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xác nhận mục kiểm tay (`checkKind = MANUAL`) kèm bằng chứng; mục tự động trả ERR-18-006; mục chuyển `PASSED`, ghi người xác nhận vào sổ cắt chuyển.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/parallel-groups/NHOM-HO-TICH/checklist/STAKEHOLDER_SIGNOFF:confirm
If-Match: W/"3"
Idempotency-Key: dh-2026-11-27-0001

{"evidence": "Biên bản họp ngày 25/11/2026",
 "comment": "Đã đối chiếu với quy trình vận hành của tỉnh"}
```

```http
HTTP/1.1 200 OK

{"itemCode": "DLQ_EMPTY", "description": "Mô tả ngắn phục vụ vận hành tỉnh",
 "checkKind": "AUTO", "status": "PENDING", "evidence": "Biên bản họp ngày 25/11/2026",
 "checkedBy": "le.thi.chi", "checkedAt": "2026-11-27T09:15:02+07:00"}
```

### 14.10. Quản trị và báo cáo

Nhật ký thao tác vận hành, báo cáo định kỳ, sức khỏe phân hệ và chế độ suy giảm (FR-18-069…072). Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.

#### API-18-177 · Nhật ký thao tác vận hành của PH-18 (chỉ đọc, từ PH-13)

::: dac-ta
**Mục đích.** Nhật ký thao tác vận hành của PH-18 (chỉ đọc, từ PH-13).

**Phương thức, đường dẫn.** `GET /api/ops/v1/audit-log`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-070.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `action` (query, string, tùy chọn); `objectType` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `from` (query, string, bắt buộc); `to` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditEntryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký thao tác vận hành của PH-18 (chỉ đọc, từ PH-13). Quyền PERM-18-read; FR-18-070.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/audit-log?from=2026-11-26T00:00:00+07:00&to=2026-11-27T00:00:00+07:00
```

```http
HTTP/1.1 200 OK

{"items": [{"auditId": "0190a1b2-c3d4-7e5f-8a6b-e820648f49d6",
   "occurredAt": "2026-11-27T09:15:02+07:00", "actor": "tran.thi.binh",
   "action": "PARAM_VALUE_CHANGED", "objectType": "param_value",
   "objectId": "18.dlq.replay.batch-max", "outcome": "SUCCESS"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-18-178 · Danh sách báo cáo vận hành định kỳ

::: dac-ta
**Mục đích.** Danh sách báo cáo vận hành định kỳ.

**Phương thức, đường dẫn.** `GET /api/ops/v1/reports`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-071.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `period` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OpsReportPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách báo cáo vận hành định kỳ. Quyền PERM-18-read; FR-18-071.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/reports
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "reportCode": "BC-2026-11",
   "period": "MONTH", "from": "2026-11-01", "to": "2026-11-30", "status": "RUNNING"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-179 · Dựng báo cáo vận hành cho kỳ chọn

::: dac-ta
**Mục đích.** Dựng báo cáo vận hành cho kỳ chọn.

**Phương thức, đường dẫn.** `POST /api/ops/v1/reports:generate`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-071.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReportGenerateInput`; trường bắt buộc: `period`, `from`, `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OpsReport`; trường bắt buộc: `version`, `id`, `reportCode`, `period`, `from`, `to`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-006, ERR-18-008, ERR-18-009, ERR-18-010, ERR-18-071, ERR-18-072 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dựng báo cáo vận hành cho kỳ chọn. Quyền PERM-18-admin; FR-18-071.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/reports:generate
Idempotency-Key: dh-2026-11-27-0001

{"period": "MONTH", "from": "2026-11-01", "to": "2026-11-30"}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3,
 "createdAt": "2026-11-27T09:15:02+07:00", "createdBy": "nguyen.van.an",
 "updatedAt": "2026-11-27T09:15:02+07:00", "updatedBy": "tran.thi.binh",
 "reportCode": "BC-2026-11", "period": "MONTH", "from": "2026-11-01", "to": "2026-11-30",
 "status": "RUNNING", "metrics": {"dlqOpen": 37, "backupFreshPercent": 100},
 "sha256": "e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442e3b0c442",
 "generatedAt": "2026-11-27T09:15:02+07:00",
 "downloadUrl": "https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11"}
```

#### API-18-180 · Sức khỏe các mô-đun PH-18, chế độ suy giảm, độ trễ tiêu thụ

::: dac-ta
**Mục đích.** Sức khỏe các mô-đun PH-18, chế độ suy giảm, độ trễ tiêu thụ.

**Phương thức, đường dẫn.** `GET /api/ops/v1/health`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-072.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Health`; trường bắt buộc: `status`, `readOnly`, `components`, `checkedAt`.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái từng thành phần (tiếp nhận DLQ, outbox, gửi thông báo, worker), độ trễ tiêu thụ, cờ chỉ đọc `18.degraded.read-only`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/health
```

```http
HTTP/1.1 200 OK

{"status": "UP", "readOnly": true, "readOnlyReason": "Bảo trì cụm pg-core",
 "components": [{"component": "dlq-ingest", "status": "UP"}],
 "checkedAt": "2026-11-27T09:15:02+07:00"}
```

#### API-18-186 · Danh sách sự kiện inbox `FAILED` theo mô-đun, lỗi cuối, số lần thử

::: dac-ta
**Mục đích.** Danh sách sự kiện inbox `FAILED` theo mô-đun, lỗi cuối, số lần thử.

**Phương thức, đường dẫn.** `GET /api/ops/v1/inbox-failures`.

**Quyền.** `PERM-18-read`.

**FR hiện thực.** FR-18-072.

**Tham số.** `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `module` (query, string, tùy chọn); `consumer` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboxFailurePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-18-003, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sự kiện inbox `FAILED` theo mô-đun để người vận hành biết sự kiện nào chưa xử lý được (FR-18-072 bước 4); chỉ siêu dữ liệu, không nội dung sự kiện.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/ops/v1/inbox-failures
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0190a1b2-c3d4-7e5f-8a6b-b80bb7740288", "version": 3, "module": "ph01_onboarding",
   "consumer": "giá trị mẫu", "eventId": "giá trị mẫu", "sourceTopic": "giá trị mẫu",
   "attempts": 3, "lastError": "giá trị mẫu", "lastAttemptAt": "2026-11-27T09:15:02+07:00",
   "receivedAt": "2026-11-27T09:15:02+07:00"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-18-187 · Bật, tắt chế độ chỉ đọc kèm lý do; là API ghi duy nhất không bị chặn bởi chế độ chỉ đọc

::: dac-ta
**Mục đích.** Bật, tắt chế độ chỉ đọc kèm lý do; là API ghi duy nhất không bị chặn bởi chế độ chỉ đọc.

**Phương thức, đường dẫn.** `POST /api/ops/v1/degraded-mode`.

**Quyền.** `PERM-18-admin`.

**FR hiện thực.** FR-18-072.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DegradedModeInput`; trường bắt buộc: `readOnly`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Health`; trường bắt buộc: `status`, `readOnly`, `components`, `checkedAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-18-003, ERR-18-007, ERR-18-008, ERR-18-009, ERR-18-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PA bật hoặc tắt chế độ chỉ đọc kèm lý do; là API ghi duy nhất không bị chặn bởi chế độ chỉ đọc (ERR-18-071 không áp dụng). Ghi khóa `18.degraded.read-only`, phát EVT-18-29, ghi kiểm toán.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/ops/v1/degraded-mode
Idempotency-Key: dh-2026-11-27-0001

{"readOnly": true, "reason": "Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118"}
```

```http
HTTP/1.1 200 OK

{"status": "UP", "readOnly": true, "readOnlyReason": "Bảo trì cụm pg-core",
 "components": [{"component": "dlq-ingest", "status": "UP"}],
 "checkedAt": "2026-11-27T09:15:02+07:00"}
```
<!-- gen:dac-ta:end -->

## Lịch sử phiên bản

Bảng dưới đây ghi các phiên bản của tài liệu.

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ nội bộ PH-18 theo FRS 0.2: thêm API-18-181…188, `PERM-18-read` cho API-18-041, 043, 045, thân `action` của API-18-175, ERR-18-071 ở mọi API ghi, `SKIPPED` ở mục phát lại, câu thông báo chung của §9.1; đánh dấu mục 11.1 đã hấp thụ; `check_contracts.py` sạch 188 operation |
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 180 operation OpenAPI 3.1, 29 sự kiện và 13 kênh tiêu thụ AsyncAPI 3.0, quy ước RFC 9457, bốn mắt, DLQ hợp nhất, bốn API dùng chung; đối chiếu FRS §9.4 đủ mã, sạch Spectral và `check_contracts.py` |

: Lịch sử phiên bản
